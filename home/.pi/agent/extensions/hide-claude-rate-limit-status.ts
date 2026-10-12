import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const CLAUDE_RATE_LIMIT_STATUS_KEY = "claude-rate-limit";

/** Removes pi-claude-cli's machine-readable rate limit payload from Pi's default footer. */
function clearClaudeRateLimitFooterStatus(ctx: ExtensionContext): void {
  ctx.ui.setStatus(CLAUDE_RATE_LIMIT_STATUS_KEY, undefined);
}

export default function hideClaudeRateLimitStatus(pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => clearClaudeRateLimitFooterStatus(ctx));
  pi.on("message_start", (_event, ctx) => clearClaudeRateLimitFooterStatus(ctx));
  pi.on("agent_end", (_event, ctx) => clearClaudeRateLimitFooterStatus(ctx));
  pi.on("model_select", (_event, ctx) => clearClaudeRateLimitFooterStatus(ctx));
}
