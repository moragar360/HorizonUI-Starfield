// Purpose: generate the committed font-coverage table from OFL cmaps + shipped
// JSON. Writes Interface/HorizonUI/fonts/font_cover.json and splices the AS
// constants between the generated markers. Not a pack build. Run from repo root:
//   node tools/build_font_coverage.js
// Author: Moragar. Last modified: 2026-11-28.
"use strict";

const fs = require("fs");
const path = require("path");
const ROOT = path.join(__dirname, "..");
const cover = require(path.join(ROOT, "tests", "lib", "font_cover.js"));

const START = "// ---- generated font coverage (tools/build_font_coverage.js) ----";
const END = "// ---- end generated font coverage ----";

const data = cover.compute(ROOT);
const orbFrom = Object.keys(data.orbSub).map((k) => Number(k)).sort((a, b) => a - b);
const asCover = {};
for (const code of data.langs) asCover[code] = data.cover[code].bits;

const json = {
	generated_by: "tools/build_font_coverage.js",
	families: data.families,
	bits: data.bits,
	cover: {},
	orb_sub: {},
	chrome: cover.AS_CHROME
};
for (const code of data.langs) {
	const c = data.cover[code];
	json.cover[code] = { bits: c.bits, offer: c.offer, hide: c.hide };
}
for (const from of orbFrom) json.orb_sub[String(from)] = data.orbSub[from];

const jsonPath = path.join(ROOT, "Interface", "HorizonUI", "fonts", "font_cover.json");
fs.writeFileSync(jsonPath, JSON.stringify(json, null, "\t") + "\n");
console.log("wrote " + path.relative(ROOT, jsonPath));

function asEsc(cp) {
	return "\"\\u" + cp.toString(16).toUpperCase().padStart(4, "0") + "\"";
}
const asBlock = [
	"      " + START,
	"      private static const HZ_FONT_COVER:Object = " + JSON.stringify(asCover) + ";",
	"      private static const HZ_ORB_FROM:Array = [" + orbFrom.join(",") + "];",
	"      private static const HZ_ORB_TO:Array = [" + orbFrom.map((c) => asEsc(data.orbSub[c])).join(",") + "];",
	"      " + END
].join("\n");

const targets = [
	{
		rel: "actionscript/horizon_block.as",
		anchor: "private static const HZ_FONT_FAM_NAMES:Array = [\"EXO 2\",\"SAIRA\",\"ORBITRON\",\"TITILLIUM WEB\"];"
	},
	{
		rel: "actionscript/comms/hzc_block.as",
		anchor: "private static const HZC_SEMI:String = \"$NB_Grotesk_Semibold\";"
	},
	{
		rel: "actionscript/comms/hzd_block.as",
		anchor: "private static const HZD_SEMI:String = \"$NB_Grotesk_Semibold\";"
	},
	{
		rel: "actionscript/scanner/hzs_block.as",
		anchor: "private static const HZS_SEMI:String = \"$NB_Grotesk_Semibold\";"
	},
	{
		rel: "actionscript/favorites/hzq_main.as",
		anchor: "private static const HZQ_GLYPH:String = \"$Controller_Buttons\";"
	}
];

function patch(rel, anchor) {
	const p = path.join(ROOT, rel);
	let t = fs.readFileSync(p, "utf8");
	const crlf = t.indexOf("\r\n") >= 0;
	t = t.replace(/\r\n/g, "\n");
	const i0 = t.indexOf(START);
	const i1 = t.indexOf(END);
	if (i0 >= 0 && i1 > i0) {
		const lineStart = t.lastIndexOf("\n", i0) + 1;
		t = t.slice(0, lineStart) + asBlock + t.slice(i1 + END.length);
	} else {
		const a = t.indexOf(anchor);
		if (a < 0) {
			console.error("anchor missing in " + rel);
			process.exit(1);
		}
		const lineEnd = t.indexOf("\n", a);
		t = t.slice(0, lineEnd + 1) + asBlock + "\n" + t.slice(lineEnd + 1);
	}
	if (crlf) t = t.replace(/\n/g, "\r\n");
	fs.writeFileSync(p, t);
	console.log("patched " + rel);
}

for (const t of targets) patch(t.rel, t.anchor);

console.log("\nOffered after Orbitron punctuation sub (non-CJK JSON + AS chrome):");
for (const code of data.langs) {
	const c = data.cover[code];
	const hide = c.hide.length ? " hide=" + c.hide.join(",") : "";
	console.log("  " + code + "  offer=" + c.offer.join(",") + hide + "  bits=" + c.bits);
}
console.log("Orbitron sub: " + orbFrom.map((c) => {
	const to = data.orbSub[c];
	return "U+" + c.toString(16).toUpperCase().padStart(4, "0") + "->" + "U+" + to.toString(16).toUpperCase().padStart(4, "0");
}).join(" "));
for (const row of data.rows) {
	if (row.name !== "Orbitron") continue;
	for (const code of data.langs) {
		if (row[code].n) console.log("  Orbitron leftover " + code + ": " + cover.show(row[code].miss));
	}
}
