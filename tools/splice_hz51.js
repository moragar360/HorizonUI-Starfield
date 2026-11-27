// Purpose: splice hz51_insert.as + hz51_draw.as into the live horizon_block.as
// after Settings 2.0 is already patched. Does not re-run the one-shot replacements.
// Author: Moragar. Last modified: 2026-11-26.
"use strict";
const fs = require("fs");
const path = require("path");
const ROOT = path.join(__dirname, "..");
const HUD = path.join(ROOT, "actionscript", "horizon_block.as");
const INSERT = fs.readFileSync(path.join(ROOT, "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const DRAW = fs.readFileSync(path.join(ROOT, "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");
let text = fs.readFileSync(HUD, "utf8").replace(/\r\n/g, "\n");
const startMark = "      // ===================== Settings 2.0 (F11 rebuild) =====================";
const endMark = "      private function hzSetRows(tab:int) : Array";
const start = text.indexOf(startMark);
const end = text.indexOf(endMark);
if (start < 0 || end < 0 || end <= start) {
	console.error("splice markers missing");
	process.exit(1);
}
if (!INSERT.startsWith(startMark)) {
	console.error("hz51_insert.as must start with the Settings 2.0 marker");
	process.exit(1);
}
text = text.slice(0, start) + INSERT.replace(/\s+$/, "") + "\n" + DRAW.replace(/^\s+/, "").replace(/\s+$/, "") + "\n\n" + text.slice(end);
text = text.replace(
	/private var HZ_SET_W:Number = \d+;   \/\/ Settings 2\.0[^\n]*\n      private var HZ_SET_H:Number = \d+;/,
	"private var HZ_SET_W:Number = 1100;   // 10% over the old 1000x660 F11 clip; hz51Fit never grows past this\n      private var HZ_SET_H:Number = 726;"
);
text = text.replace(
	/private static const HZ_SET_TOP:Number = \d+;      \/\/ body top[^\n]*/,
	"private static const HZ_SET_TOP:Number = 90;      // body top (head 52 + tabs 38)"
);
text = text.split("HZ_SET_H - HZ51_FOOT - HZ_SET_TOP - 64").join("HZ_SET_H - HZ51_FOOT - HZ_SET_TOP - 52");
if (!/HZ_SET_W:Number = 1100/.test(text) || !/HZ_SET_H:Number = 726/.test(text)) {
	console.error("failed to pin 1100x726");
	process.exit(1);
}
if (!text.includes("function hz51Stroke") || !text.includes("function hz51HeadSlots") || !text.includes("hzSetOver")) {
	console.error("splice missing new helpers");
	process.exit(1);
}
fs.writeFileSync(HUD, text);
console.log("spliced", HUD, "chars", text.length);
