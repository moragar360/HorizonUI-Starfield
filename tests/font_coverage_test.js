// Purpose: glyph coverage of bundled OFL faces vs shipped JSON. Exo 2 must
// cover every non-CJK codepoint in en/de/fr/es/es-mx/pl. CJK stays the game
// FontLib (Option A). Saira / Orbitron / Titillium are reported, not required
// to cover CJK. Run: node tests/font_coverage_test.js
// Author: Moragar. Last modified: 2026-11-28.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

function flatten(obj, prefix, out) {
	if (obj == null || typeof obj !== "object" || Array.isArray(obj)) {
		if (prefix) out[prefix] = obj;
		return;
	}
	for (const k of Object.keys(obj)) {
		if (k === "_meta" || k === "_comment") continue;
		flatten(obj[k], prefix ? prefix + "." + k : k, out);
	}
}

function isCjk(cp) {
	return (cp >= 0x2E80 && cp <= 0x9FFF)
		|| (cp >= 0xF900 && cp <= 0xFAFF)
		|| (cp >= 0x20000 && cp <= 0x2FA1F);
}

function codepoints(str) {
	const set = new Set();
	const s = String(str);
	for (let i = 0; i < s.length;) {
		const cp = s.codePointAt(i);
		if (cp > 0x20) set.add(cp);
		i += cp > 0xFFFF ? 2 : 1;
	}
	return set;
}

function parseCmap(buf) {
	if (buf.length < 12) throw new Error("short font");
	const nTables = buf.readUInt16BE(4);
	let cmapOff = -1;
	for (let i = 0; i < nTables; i++) {
		const rec = 12 + i * 16;
		if (rec + 16 > buf.length) break;
		const tag = buf.toString("ascii", rec, rec + 4);
		if (tag === "cmap") {
			cmapOff = buf.readUInt32BE(rec + 8);
			break;
		}
	}
	if (cmapOff < 0) throw new Error("no cmap");
	const num = buf.readUInt16BE(cmapOff + 2);
	const recs = [];
	for (let i = 0; i < num; i++) {
		const rec = cmapOff + 4 + i * 8;
		recs.push({
			plat: buf.readUInt16BE(rec),
			enc: buf.readUInt16BE(rec + 2),
			off: cmapOff + buf.readUInt32BE(rec + 4)
		});
	}
	recs.sort((a, b) => {
		const score = (r) => {
			const fmt = buf.readUInt16BE(r.off);
			let s = 0;
			if (fmt === 12) s += 4;
			if (fmt === 4) s += 2;
			if (r.plat === 0 || r.plat === 3) s += 1;
			return s;
		};
		return score(b) - score(a);
	});
	const set = new Set();
	function addFmt4(off) {
		const segCount = buf.readUInt16BE(off + 6) / 2;
		const endCount = off + 14;
		const startCount = endCount + segCount * 2 + 2;
		const idDelta = startCount + segCount * 2;
		const idRange = idDelta + segCount * 2;
		for (let i = 0; i < segCount; i++) {
			const end = buf.readUInt16BE(endCount + i * 2);
			const start = buf.readUInt16BE(startCount + i * 2);
			const delta = buf.readInt16BE(idDelta + i * 2);
			const rangeOff = buf.readUInt16BE(idRange + i * 2);
			for (let cp = start; cp <= end; cp++) {
				let gid = 0;
				if (rangeOff === 0) gid = (cp + delta) & 0xFFFF;
				else {
					const p = idRange + i * 2 + rangeOff + (cp - start) * 2;
					if (p + 2 <= buf.length) {
						const g = buf.readUInt16BE(p);
						gid = g ? (g + delta) & 0xFFFF : 0;
					}
				}
				if (gid) set.add(cp);
			}
		}
	}
	function addFmt12(off) {
		const nGroups = buf.readUInt32BE(off + 12);
		for (let i = 0; i < nGroups; i++) {
			const g = off + 16 + i * 12;
			const start = buf.readUInt32BE(g);
			const end = buf.readUInt32BE(g + 4);
			const startGlyph = buf.readUInt32BE(g + 8);
			for (let cp = start; cp <= end; cp++) {
				if (startGlyph + (cp - start) !== 0) set.add(cp);
			}
		}
	}
	let parsed = false;
	for (const r of recs) {
		if (r.off + 2 > buf.length) continue;
		const fmt = buf.readUInt16BE(r.off);
		if (fmt === 12) { addFmt12(r.off); parsed = true; break; }
		if (fmt === 4) { addFmt4(r.off); parsed = true; break; }
	}
	if (!parsed) throw new Error("no format 4/12 cmap");
	return set;
}

const fonts = [
	["Exo2", "Interface/HorizonUI/fonts/exo2/Exo2-Variable.ttf"],
	["Saira", "Interface/HorizonUI/fonts/saira/Saira-Variable.ttf"],
	["Orbitron", "Interface/HorizonUI/fonts/orbitron/Orbitron-Variable.ttf"],
	["Titillium", "Interface/HorizonUI/fonts/titilliumweb/TitilliumWeb-Regular.ttf"]
];

const locDir = path.join(root, "Data", "SFSE", "Plugins", "HorizonUI", "Localization");
const langs = ["en", "de", "fr", "es", "es-mx", "pl", "zh-cn"];
const locCp = {};
for (const code of langs) {
	const obj = JSON.parse(fs.readFileSync(path.join(locDir, code + ".json"), "utf8"));
	const flat = {};
	flatten(obj, "", flat);
	const all = new Set();
	const latin = new Set();
	const cjk = new Set();
	for (const v of Object.values(flat)) {
		for (const cp of codepoints(v)) {
			all.add(cp);
			if (isCjk(cp)) cjk.add(cp);
			else latin.add(cp);
		}
	}
	locCp[code] = { all, latin, cjk };
}

const cmap = {};
const sizes = {};
for (const [name, rel] of fonts) {
	const p = path.join(root, rel);
	expect(fs.existsSync(p), name + " TTF exists");
	const buf = fs.readFileSync(p);
	sizes[name] = buf.length;
	try {
		cmap[name] = parseCmap(buf);
		expect(cmap[name].size > 100, name + " cmap has glyphs (" + cmap[name].size + ")");
	} catch (e) {
		cmap[name] = new Set();
		expect(false, name + " cmap parse: " + e.message);
	}
}

function missing(face, set) {
	const out = [];
	for (const cp of set) if (!cmap[face].has(cp)) out.push(cp);
	out.sort((a, b) => a - b);
	return out;
}
function show(cps) {
	return cps.slice(0, 12).map((cp) => "U+" + cp.toString(16).toUpperCase().padStart(4, "0")
		+ "(" + String.fromCodePoint(cp) + ")").join(" ");
}

console.log("\nFont sizes (source TTF, pack SWF is separate):");
let total = 0;
for (const [name] of fonts) {
	total += sizes[name] || 0;
	console.log("  " + name + "  " + ((sizes[name] || 0) / 1024).toFixed(1) + " KiB");
}
console.log("  total  " + (total / 1024).toFixed(1) + " KiB");

console.log("\nCoverage vs JSON (non-CJK / CJK missing counts):");
const rows = [];
for (const [name] of fonts) {
	const row = { name };
	for (const code of langs) {
		const missL = missing(name, locCp[code].latin);
		const missC = missing(name, locCp[code].cjk);
		row[code] = { latin: missL.length, cjk: missC.length, missL };
		if (code !== "zh-cn" && missL.length && missL.length <= 16) {
			console.log("  " + name + " " + code + " missing Latin: " + show(missL));
		}
	}
	rows.push(row);
	const cells = langs.map((c) => c + "=" + row[c].latin + "/" + row[c].cjk).join("  ");
	console.log("  " + name + "  " + cells + "  (latin miss / cjk miss)");
}

for (const code of ["en", "de", "fr", "es", "es-mx", "pl"]) {
	const miss = rows[0][code].missL;
	expect(miss.length === 0,
		"Exo 2 covers every non-CJK codepoint in " + code + ".json"
			+ (miss.length ? " (" + show(miss) + ")" : ""));
}

expect(locCp["zh-cn"].cjk.size > 0, "zh-cn.json has CJK codepoints");
for (const [name] of fonts) {
	expect(missing(name, locCp["zh-cn"].cjk).length === locCp["zh-cn"].cjk.size,
		name + " does not claim CJK (Option A: game FontLib)");
}

const orbPl = rows.find((r) => r.name === "Orbitron")["pl"].latin;
expect(orbPl >= 0, "Orbitron vs Polish Latin miss count is recorded (" + orbPl + ")");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log("\n" + passed + " passed");
