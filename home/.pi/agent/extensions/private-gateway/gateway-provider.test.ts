import assert from "node:assert/strict";
import { inspect } from "node:util";
import { test } from "node:test";
import { createModels, InMemoryCredentialStore, InMemoryModelsStore, type ClassifierContext } from "@earendil-works/pi-ai";
import { GatewayAccessToken, createGatewayAccessAuth } from "./gateway-auth.ts";
import { HttpGatewayDiscovery } from "./gateway-discovery.ts";
import { HttpGatewayInventory } from "./gateway-inventory.ts";
import { NativeGatewayCatalog } from "./gateway-catalog.ts";
import { GatewayRequestError } from "./gateway-http.ts";
import { buildGatewayProvider } from "./gateway-provider.ts";
import { exampleGatewayProfile, exampleGatewayToken, RecordingGatewayHttp } from "./gateway-test-fixtures.ts";

const profile = exampleGatewayProfile(), token = exampleGatewayToken();
function makeHandle(http: RecordingGatewayHttp, models = profile.models) {
	return buildGatewayProvider({ ...profile, models }, { discovery: new HttpGatewayDiscovery(http), catalog: new NativeGatewayCatalog(new HttpGatewayInventory(http)), now: () => Date.now() });
}

test("tokens cannot leak through JSON, inspection, stringification, or property spreading", () => {
	for (const text of [String(token), JSON.stringify(token), inspect(token), JSON.stringify({ ...token })]) assert.doesNotMatch(text, /test-access-token/);
	const expired = `header.${Buffer.from(JSON.stringify({ exp: 1 })).toString("base64url")}.signature`;
	assert.equal(GatewayAccessToken.parse(expired, Date.now()).ok, false);
});

test("native Pi login persists credentials; expiry never launches an implicit browser refresh", async () => {
	let logins = 0;
	const auth = createGatewayAccessAuth(profile, { now: () => 1_000, remember: () => {}, login: async () => { logins += 1; return { ok: true, value: token }; } });
	assert.ok(auth.oauth);
	const saved = await auth.oauth.login({ signal: new AbortController().signal, prompt: async () => "", notify() {} });
	assert.equal(logins, 1);
	assert.equal(saved.access, token.reveal());
	const oauth = auth.oauth;
	await assert.rejects(() => oauth.refresh(saved, new AbortController().signal), /expired/);
	assert.equal(logins, 1);
});

test("environment-only native auth carries its token into model refresh; cached filters reapply offline", async () => {
	const http = new RecordingGatewayHttp(() => ({ enabled_providers: ["openai"], provider: { openai: { models: { "gpt-4o": {}, "gpt-4o-mini": {} }, whitelist: ["gpt-4o", "gpt-4o-mini"] } } }));
	const stores = { credentials: new InMemoryCredentialStore(), modelsStore: new InMemoryModelsStore(), authContext: { env: async () => token.reveal(), fileExists: async () => false } };
	const configured = { ...profile, tokenEnvironmentVariable: "EXAMPLE_GATEWAY_TOKEN" };
	const create = (filter = {}) => buildGatewayProvider({ ...configured, models: filter }, { discovery: new HttpGatewayDiscovery(http), catalog: new NativeGatewayCatalog(new HttpGatewayInventory(http)), now: () => Date.now() });
	const handle = create();
	const models = createModels(stores); models.setProvider(handle.provider);
	assert.equal((await models.refresh()).errors.size, 0);
	assert.equal(models.getModels(profile.id).length, 2);
	const requestCount = http.requests.length;
	const filtered = create({ include: ["gpt-4o"] });
	const restored = createModels(stores); restored.setProvider(filtered.provider);
	await restored.refresh({ allowNetwork: false });
	assert.equal(http.requests.length, requestCount);
	assert.deepEqual(restored.getModels(profile.id).map((model) => model.id), ["gpt-4o"]);
	filtered.setModelFilter({ include: ["gpt-4o-mini"] });
	assert.deepEqual(restored.getModels(profile.id).map((model) => model.id), ["gpt-4o-mini"]);
	filtered.setModelFilter({ include: [] });
	assert.equal(restored.getModels(profile.id).length, 0);
});

test("failed refresh keeps the previous catalog and independent profiles never deduplicate each other", async () => {
	let unavailable = false;
	const http = new RecordingGatewayHttp(() => unavailable ? new GatewayRequestError("network", "discovery") : { enabled_providers: ["openai"], provider: { openai: { models: { "gpt-4o": {} }, whitelist: ["gpt-4o"] } } });
	const models = createModels({ credentials: new InMemoryCredentialStore(), modelsStore: new InMemoryModelsStore() });
	const handle = makeHandle(http); models.setProvider(handle.provider);
	await models.login(profile.id, "api_key", { prompt: async () => token.reveal(), notify() {} });
	await models.refresh();
	unavailable = true;
	assert.equal((await models.refresh()).errors.size, 1);
	assert.equal(models.getModels(profile.id).length, 1);
	const other = exampleGatewayProfile("another");
	unavailable = false;
	models.setProvider(buildGatewayProvider(other, { discovery: new HttpGatewayDiscovery(http), catalog: new NativeGatewayCatalog(new HttpGatewayInventory(http)), now: () => Date.now() }).provider);
	await models.login(other.id, "api_key", { prompt: async () => "another-profile-token", notify() {} });
	await models.refresh();
	assert.equal(models.getModels(other.id).length, 1);
	assert.equal(models.getModels(profile.id).length, 1);
});

test("native OpenAI streaming preserves Access headers, request hooks, and safe origin enforcement", async () => {
	const http = new RecordingGatewayHttp(() => ({ enabled_providers: ["openai"], provider: { openai: { models: { "gpt-4o": {} }, whitelist: ["gpt-4o"] } } }));
	const handle = makeHandle(http);
	const models = createModels({ credentials: new InMemoryCredentialStore(), modelsStore: new InMemoryModelsStore() });
	models.setProvider(handle.provider);
	await models.login(profile.id, "api_key", { prompt: async () => token.reveal(), notify() {} });
	await models.refresh();
	const model = models.getModel(profile.id, "gpt-4o"); assert.ok(model);
	let requests = 0, payloadHooks = 0;
	const wireFetch: typeof fetch = async (_input, init) => {
		requests += 1;
		const headers = new Headers(init?.headers);
		assert.equal(headers.get("cf-access-token"), token.reveal());
		assert.equal(headers.get("authorization"), `Bearer ${token.reveal()}`);
		return new Response('event: response.completed\ndata: {"type":"response.completed","response":{"id":"resp_test","status":"completed","output":[],"usage":{"input_tokens":1,"output_tokens":1,"total_tokens":2}}}\n\n', { headers: { "content-type": "text/event-stream" } });
	};
	const context = { messages: [{ role: "user" as const, content: "Reply", timestamp: 1 }] };
	const result = await models.completeSimple(model, context, { fetch: wireFetch, onPayload: () => { payloadHooks += 1; } });
	assert.notEqual(result.stopReason, "error", result.errorMessage ?? "native stream failed");
	assert.equal(requests, 1); assert.equal(payloadHooks, 1);
	const blocked = await models.completeSimple({ ...model, baseUrl: "https://untrusted.test/openai" }, context, { fetch: wireFetch });
	assert.equal(blocked.stopReason, "error"); assert.equal(requests, 1);
	assert.equal(handle.sanitizeError(`upstream echoed ${token.reveal()}`), "upstream echoed <redacted>");
});

test("classifiers use the Workers AI run route with Access headers, Pi answer mapping, and origin enforcement", async () => {
	const http = new RecordingGatewayHttp(() => ({ enabled_providers: ["cloudflare-workers-ai"], provider: { "cloudflare-workers-ai": { whitelist: [] } } }));
	const handle = makeHandle(http);
	const models = createModels({ credentials: new InMemoryCredentialStore(), modelsStore: new InMemoryModelsStore() });
	models.setProvider(handle.provider);
	await models.login(profile.id, "api_key", { prompt: async () => token.reveal(), notify() {} });
	await models.refresh();
	assert.equal(models.getModels(profile.id).length, 0, "classifiers never appear as chat models");
	const clef = models.getModelOfType("classifier", profile.id, "@cf/cloudflare/clef"); assert.ok(clef);
	const requests: { url: string; body: unknown }[] = [];
	const wireFetch: typeof fetch = async (input, init) => {
		const headers = new Headers(init?.headers);
		assert.equal(headers.get("cf-access-token"), token.reveal());
		requests.push({ url: String(input), body: JSON.parse(String(init?.body)) });
		return Response.json({ model: "clef", answers: {
			urgent: { type: "noul", noul: 0.98 },
			team: { type: "choice", choice: "technical", probabilities: { billing: 0.2, technical: 0.8 }, confidence: 0.6 },
		}, usage: { input_tokens: 10, output_tokens: 0 } });
	};
	const context: ClassifierContext = { state: { message: "Checkout fails for everyone" }, questions: {
		urgent: { type: "bool", instructions: "Urgent?", criteria: { true: "Urgent", false: "Not urgent" } },
		team: { type: "choice", instructions: "Team?", criteria: { billing: "Payments", technical: "Outages" } },
	} };
	const result = await models.classify(clef, context, { fetch: wireFetch });
	assert.equal(result.stopReason, "stop", result.errorMessage ?? "classification failed");
	assert.deepEqual(result.answers.urgent, { type: "bool", probability: 0.98 });
	assert.equal(result.answers.team?.type === "choice" && result.answers.team.choice, "technical");
	assert.equal(result.usage?.input, 10);
	assert.equal(requests[0]?.url, `${profile.inferenceOrigin}/workers-ai/run/@cf/cloudflare/clef`);
	assert.deepEqual(requests[0]?.body, { state: context.state, questions: {
		urgent: { type: "noul", instructions: "Urgent?", criteria: { true: "Urgent", false: "Not urgent" } },
		team: { type: "choice", instructions: "Team?", criteria: { billing: "Payments", technical: "Outages" } },
	} });
	const blocked = await models.classify({ ...clef, baseUrl: "https://untrusted.test/workers-ai" }, context, { fetch: wireFetch });
	assert.equal(blocked.stopReason, "error"); assert.equal(requests.length, 1);
	handle.setModelFilter({ exclude: ["@cf/cloudflare/clef"] });
	assert.equal(models.getModelOfType("classifier", profile.id, "@cf/cloudflare/clef"), undefined);
});

test("gateway run output accepts bare, enveloped, and run-record shapes and reports failures", async () => {
	const { gatewayWorkersAiRunOutput } = await import("./gateway-classifier.ts");
	const output = { answers: {}, usage: {} };
	assert.equal(gatewayWorkersAiRunOutput(output), output);
	assert.equal(gatewayWorkersAiRunOutput({ success: true, result: output }), output);
	assert.equal(gatewayWorkersAiRunOutput({ success: true, result: { state: "Completed", result: output } }), output);
	assert.throws(() => gatewayWorkersAiRunOutput({ success: false, errors: [{ message: "Insufficient balance" }] }), /Insufficient balance/);
	assert.throws(() => gatewayWorkersAiRunOutput({ success: true, result: { state: "Queued" } }), /did not complete/);
	assert.throws(() => gatewayWorkersAiRunOutput("nope"), /unexpected response/);
});
