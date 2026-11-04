import { registerHooks } from "node:module";
const repo = new URL("../../", import.meta.url);
const missing = new URL("../pixelfx/", repo).href;
const pinned = "file:///C:/Users/TH/Documents/AI/GameProject/pixelfx/";
registerHooks({resolve(specifier, context, nextResolve) {
  return nextResolve(specifier.startsWith(missing) ? pinned + specifier.slice(missing.length) : specifier, context);
}});
export const bench = await import("../pixelfx-eval-2026-11-03/bench.mjs");
