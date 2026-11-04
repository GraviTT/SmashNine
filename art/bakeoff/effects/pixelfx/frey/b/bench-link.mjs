// Resolve the unmodified bench's sibling-checkout URL to the user's read-only pixelfx copy.
import { registerHooks } from "node:module";
const missing = new URL("../../../../../../../pixelfx/", import.meta.url).href;
const pinned = "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/";
registerHooks({
  resolve(specifier, context, nextResolve) {
    return nextResolve(specifier.startsWith(missing) ? pinned + specifier.slice(missing.length) : specifier, context);
  },
});
export const bench = await import("../../../../../../reports/pixelfx-eval-2026-11-03/bench.mjs");
