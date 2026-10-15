import { anthropicMessagesApi } from "@earendil-works/pi-ai/api/anthropic-messages.lazy";
import { googleGenerativeAIApi } from "@earendil-works/pi-ai/api/google-generative-ai.lazy";
import { openAIResponsesApi } from "@earendil-works/pi-ai/api/openai-responses.lazy";
import { openAICompletionsApi } from "@earendil-works/pi-ai/api/openai-completions.lazy";

/** Pi-owned System One request/answer mapping; gateway classifiers supply only a transport. */
export { classifySystemOne } from "@earendil-works/pi-ai/api/system-one-shared";

/**
 * Native ESM boundary: public Pi exports must resolve without jiti's root-prefix aliases.
 * @satisfies {Record<import("./gateway-api.ts").GatewayApi, import("@earendil-works/pi-ai").ProviderStreams>}
 */
export const NATIVE_GATEWAY_APIS = {
	"anthropic-messages": anthropicMessagesApi(),
	"google-generative-ai": googleGenerativeAIApi(),
	"openai-responses": openAIResponsesApi(),
	"openai-completions": openAICompletionsApi(),
};
