import type { ClassifierApi, ClassifierModel, ProviderClassifier } from "@earendil-works/pi-ai";
import type { SystemOneTransport } from "@earendil-works/pi-ai/api/system-one-shared";

/** Classifier wire APIs supported by gateway routes. */
export type GatewayClassifierApi = "cloudflare-workers-ai-system-one";
export const GATEWAY_WORKERS_AI_CLASSIFIER_API = "cloudflare-workers-ai-system-one" satisfies GatewayClassifierApi;

/**
 * AI Gateway's provider-native Workers AI route. Its `run/{model}` endpoint uses the gateway's
 * account-bound Workers AI binding when the request carries no provider credential, so an
 * Access-authenticated client needs no Cloudflare API token. `/workers-ai/{model}` (without
 * `run/`) instead forwards to the public REST API and fails without one.
 */
export const GATEWAY_WORKERS_AI_RUN_PATH = "/workers-ai";

/** Gateway-verified metadata for a Cloudflare-hosted classifier. */
export interface GatewayClassifierOverlay {
	readonly name: string;
	readonly contextWindow: number;
	/** USD per million input tokens; Clef models do not bill output tokens. */
	readonly inputCostPerMillion: number;
}

/**
 * Cloudflare-hosted Workers AI classifiers whose Pi catalog entries are missing or stale. Entries win
 * over Pi built-ins; a test fails once Pi's catalog matches an entry, so it can be deleted.
 * Source: Workers AI changelog 2026-10-09 (Clef-omni launch, Clef-flash price cut to 24K context).
 * Input stays text-only: Pi's shared System One implementation rejects media inputs.
 */
export const GATEWAY_WORKERS_AI_CLASSIFIER_OVERLAY: Readonly<Record<string, GatewayClassifierOverlay>> = {
	"@cf/cloudflare/clef-flash": { name: "Clef Flash", contextWindow: 24_000, inputCostPerMillion: 0.038 },
	"@cf/cloudflare/clef-omni": { name: "Clef Omni", contextWindow: 64_000, inputCostPerMillion: 0.15 },
};

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function errorMessages(value: unknown): string | undefined {
	if (!Array.isArray(value)) return undefined;
	const messages = value.flatMap((error) => isRecord(error) && typeof error.message === "string" ? [error.message] : []);
	return messages.length ? messages.join("; ") : undefined;
}

const LABEL = "Private gateway Workers AI";

/**
 * Accept the bare System One output the binding returns (`{ model, answers, usage }`), plus the
 * Cloudflare API envelope and third-party run record shapes in case the gateway starts wrapping.
 */
export function gatewayWorkersAiRunOutput(body: unknown): Record<string, unknown> {
	if (!isRecord(body)) throw new Error(`${LABEL} returned an unexpected response`);
	if ("answers" in body) return body;
	if (body.success === false) throw new Error(`${LABEL} error: ${errorMessages(body.errors ?? body.error) ?? "request failed"}`);
	const result = body.result;
	if (isRecord(result)) {
		if ("answers" in result) return result;
		if (result.state === "Completed" && isRecord(result.result)) return result.result;
		if (typeof result.state === "string") throw new Error(`${LABEL} run did not complete (state: ${result.state})`);
	}
	throw new Error(`${LABEL} returned an unexpected response`);
}

/** `POST {baseUrl}/run/{model.id}` with the flat System One body; Clef needs no selector field. */
export const GATEWAY_WORKERS_AI_RUN_TRANSPORT: SystemOneTransport = {
	api: GATEWAY_WORKERS_AI_CLASSIFIER_API,
	label: LABEL,
	url: (model: ClassifierModel<ClassifierApi>) => new URL(`run/${model.id}`, `${model.baseUrl.replace(/\/+$/u, "")}/`),
	payload: (_model, request) => request,
	output: gatewayWorkersAiRunOutput,
};

function nativeClassifier(transport: SystemOneTransport): ProviderClassifier {
	// Same native ESM boundary as the chat APIs; Pi owns answer parsing, bool/noul mapping, usage, and retries.
	const url = new URL("./gateway-native-apis.mjs", import.meta.url).href;
	return {
		async classify(model, context, options) {
			const loaded: typeof import("./gateway-native-apis.mjs") = await import(url);
			return loaded.classifySystemOne(transport, model, context, options);
		},
	};
}

/** Classifier implementations keyed by `model.api`; auth headers come from the provider's Access auth. */
export const GATEWAY_CLASSIFIERS = {
	"cloudflare-workers-ai-system-one": nativeClassifier(GATEWAY_WORKERS_AI_RUN_TRANSPORT),
} satisfies Record<GatewayClassifierApi, ProviderClassifier>;
