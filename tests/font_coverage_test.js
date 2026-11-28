// Purpose: glyph coverage of bundled OFL faces vs shipped JSON + AS chrome.
// The committed build-time table (font_cover.json and HZ_FONT_COVER) must match
// a fresh compute from the cmaps. Every offered font/language pair must have
// zero missing glyphs after Orbitron punctuation substitution. Polish Orbitron
// stays hidden. CJK stays the game FontLib (Option A). Run:
//   node tests/font_coverage_test.js
// Author: Moragar. Last modified: 2026-11-28.
"use strict";
const fs = require("fs");
const path = require("path");
const cover = require("./lib/font_cover");
const root = path.join(__dirname, "..");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

const data = cover.compute(root);
const tablePath = path.join(root, "Interface", "HorizonUI", "fonts", "font_cover.json");
expect(fs.existsSync(tablePath), "font_cover.json is committed");
const table = JSON.parse(fs.readFileSync(tablePath, "utf8"));

expect(JSON.stringify(table.cover) === JSON.stringify((() => {
	const o = {};
	for (const code of data.langs) o[code] = data.cover[code];
	return o;
})()), "font_cover.json matches a fresh cmap+JSON compute");

function asCoverOf(rel) {
	const src = fs.readFileSync(path.join(root, rel), "utf8").replace(/\r\n/g, "\n");
	const m = src.match(/private static const HZ_FONT_COVER:Object = (\{[^;]+\});/);
	expect(!!m, rel + " has HZ_FONT_COVER");
	return m ? JSON.parse(m[1]) : {};
}
const wantBits = {};
for (const code of data.langs) wantBits[code] = data.cover[code].bits;
const asFiles = [
	"actionscript/horizon_block.as",
	"actionscript/comms/hzc_block.as",
	"actionscript/comms/hzd_block.as",
	"actionscript/scanner/hzs_block.as",
	"actionscript/favorites/hzq_main.as"
];
for (const rel of asFiles) {
	expect(JSON.stringify(asCoverOf(rel)) === JSON.stringify(wantBits),
		path.basename(rel) + " HZ_FONT_COVER matches the table");
}

console.log("\nFont sizes (source TTF, pack SWF is separate):");
let total = 0;
for (const [name] of cover.FAMILIES) {
	total += data.sizes[name] || 0;
	console.log("  " + name + "  " + ((data.sizes[name] || 0) / 1024).toFixed(1) + " KiB");
}
console.log("  total  " + (total / 1024).toFixed(1) + " KiB");

console.log("\nCoverage table (offered after Orbitron punctuation sub):");
for (const code of data.langs) {
	const c = data.cover[code];
	const hide = c.hide.length ? "  hide=" + c.hide.join(",") : "";
	console.log("  " + code + "  " + c.offer.join(",") + hide);
}

for (const code of ["en", "de", "fr", "es", "es-mx", "pl"]) {
	const miss = data.rows[0][code].miss;
	expect(miss.length === 0,
		"Exo 2 covers every non-CJK codepoint in " + code + ".json"
			+ (miss.length ? " (" + cover.show(miss) + ")" : ""));
}

expect(data.locCp["zh-cn"].cjk.size > 0, "zh-cn.json has CJK codepoints");
for (const [name] of cover.FAMILIES) {
	expect(cover.missingAfter(data.cmap[name], data.locCp["zh-cn"].cjk, null).length === data.locCp["zh-cn"].cjk.size,
		name + " does not claim CJK (Option A: game FontLib)");
}

expect(data.cover.pl.hide.indexOf("Orbitron") >= 0, "Polish does not offer Orbitron");
expect(data.cover.pl.offer.indexOf("Exo2") >= 0, "Polish offers Exo 2");
for (const code of ["en", "de", "fr", "es", "es-mx"]) {
	expect(data.cover[code].offer.indexOf("Orbitron") >= 0,
		code + " offers Orbitron after punctuation substitution");
}

const orbSub = data.orbSub;
expect(orbSub[0x00B7] === 0x2022 || orbSub[0x00B7] === 0x002D, "Orbitron substitutes middot");
expect(orbSub[0x201E] === 0x0022 && orbSub[0x00AB] === 0x0022 && orbSub[0x00BB] === 0x0022,
	"Orbitron substitutes „ « » with ASCII quotes");

for (const code of data.langs) {
	for (const fam of data.cover[code].offer) {
		const row = data.rows.find((r) => r.name === fam);
		const miss = row[code].miss;
		expect(miss.length === 0,
			"offered " + fam + "/" + code + " has zero leftover glyphs after substitution"
				+ (miss.length ? " (" + cover.show(miss) + ")" : ""));
	}
}

const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8");
expect(/function hzFontCovered/.test(as) && /HZ_FONT_COVER\[lang\]/.test(as),
	"HUD uses the build-time table, not a runtime cmap");
expect(!/parseCmap|readUInt16BE|font_cover\.json/.test(as),
	"HUD never parses a TTF or loads font_cover.json");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log("\n" + passed + " passed");
