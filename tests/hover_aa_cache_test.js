// 0.43.4 hover fix test: Horizon-created text must not use "Anti-alias for readability" (antiAliasType "advanced").
// Run: node tests/hover_aa_cache_test.js
// Why: Scaleform keeps one glyph-cache entry per glyph per pixel size for readability text, and Horizon draws its
// text in three faces at many scaled sizes. That fills the fixed dynamic glyph cache, so new text on a hover edge
// forces a re-rasterize of visible glyphs (a 65-75 ms stall with the GPU idle). Animation AA ("normal") keeps one
// entry per glyph. See BOT2_HOVER_ROOTCAUSE.md.
// Proves: no antiAliasType "advanced" in horizon_block.as or the compiled Horizon blocks (comms, scanner, scope,
// favorites); the three Horizon text builders still set antiAliasType explicitly, to "normal".
// HZ_HOVER_SRC overrides the horizon_block.as path (mutation checks).
// Author: Moragar. Last modified: 2026-11-21.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const MAIN = process.env.HZ_HOVER_SRC || path.join(root, "actionscript", "horizon_block.as");
const BLOCKS = [
	"actionscript/comms/hzc_block.as",
	"actionscript/comms/hzd_block.as",
	"actionscript/scanner/hzs_block.as",
	"actionscript/scope/hzp_main.as",
	"actionscript/scope/hzp37_reader.as",
	"actionscript/favorites/hzq_main.as",
	"actionscript/favorites/hzq37_reader.as",
];
let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function read(p) { return fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n"); }
function advancedLines(src) {
	const hits = [];
	src.split("\n").forEach((l, i) => { if (/antiAliasType\s*=\s*["']advanced["']/.test(l)) hits.push(i + 1); });
	return hits;
}
const SRC = read(MAIN);
{
	const hits = advancedLines(SRC);
	expect(hits.length === 0, "horizon_block.as: no antiAliasType \"advanced\"" + (hits.length ? " (lines " + hits.join(", ") + ")" : ""));
	const normal = (SRC.match(/antiAliasType\s*=\s*"normal"/g) || []).length;
	expect(normal === 3, "horizon_block.as: the three Horizon text builders set antiAliasType \"normal\" (found " + normal + ")");
}
for (const rel of BLOCKS) {
	const p = path.join(root, rel);
	if (!fs.existsSync(p)) { expect(true, rel + ": not present, skipped"); continue; }
	const hits = advancedLines(read(p));
	expect(hits.length === 0, rel + ": no antiAliasType \"advanced\"" + (hits.length ? " (lines " + hits.join(", ") + ")" : ""));
}
console.log("hover aa cache: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
