// Purpose: build-time glyph coverage of bundled OFL faces vs shipped JSON
// plus a few ActionScript chrome marks (compass middot / degree). Used by
// tools/build_font_coverage.js and tests/font_coverage_test.js. Never loaded
// at HUD runtime. Author: Moragar. Last modified: 2026-11-28.
"use strict";

const fs = require("fs");
const path = require("path");

const FAMILIES = [
	["Exo2", "Interface/HorizonUI/fonts/exo2/Exo2-Variable.ttf"],
	["Saira", "Interface/HorizonUI/fonts/saira/Saira-Variable.ttf"],
	["Orbitron", "Interface/HorizonUI/fonts/orbitron/Orbitron-Variable.ttf"],
	["Titillium", "Interface/HorizonUI/fonts/titilliumweb/TitilliumWeb-Regular.ttf"]
];
const LANGS = ["en", "de", "fr", "es", "es-mx", "pl", "zh-cn"];
const BITS = { Exo2: 1, Saira: 2, Orbitron: 4, Titillium: 8 };
// Compass / F11 / scanner chrome always stamp these, even when JSON does not.
const AS_CHROME = [0x00B7, 0x00B0];
// Orbitron punctuation gaps. First substitute that exists in the cmap wins.
const ORB_SUB_PREF = {
	0x00B7: [0x2022, 0x002D],
	0x201E: [0x0022],
	0x00AB: [0x0022],
	0x00BB: [0x0022]
};

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
	// Same ranges hzHasCjk uses, plus supplementary ideographs. Those glyphs
	// use the game CJK FontLib (Option A), not the OFL Latin faces.
	return (cp >= 0x2E80 && cp <= 0x9FFF)
		|| (cp >= 0xAC00 && cp <= 0xD7AF)
		|| (cp >= 0xF900 && cp <= 0xFAFF)
		|| (cp >= 0xFF00 && cp <= 0xFFEF)
		|| (cp >= 0x20000 && cp <= 0x2FA1F);
}

function parseCmap(buf) {
	if (buf.length < 12) throw new Error("short font");
	const nTables = buf.readUInt16BE(4);
	let cmapOff = -1;
	for (let i = 0; i < nTables; i++) {
		const rec = 12 + i * 16;
		if (rec + 16 > buf.length) break;
		if (buf.toString("ascii", rec, rec + 4) === "cmap") {
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

function show(cps) {
	return cps.slice(0, 16).map((cp) => "U+" + cp.toString(16).toUpperCase().padStart(4, "0")
		+ "(" + String.fromCodePoint(cp) + ")").join(" ");
}

function loadCmaps(root) {
	const cmap = {};
	const sizes = {};
	for (const [name, rel] of FAMILIES) {
		const buf = fs.readFileSync(path.join(root, rel));
		sizes[name] = buf.length;
		cmap[name] = parseCmap(buf);
	}
	return { cmap, sizes };
}

function loadLangLatin(root) {
	const locDir = path.join(root, "Data", "SFSE", "Plugins", "HorizonUI", "Localization");
	const locCp = {};
	for (const code of LANGS) {
		const obj = JSON.parse(fs.readFileSync(path.join(locDir, code + ".json"), "utf8"));
		const flat = {};
		flatten(obj, "", flat);
		const latin = new Set();
		const cjk = new Set();
		for (const v of Object.values(flat)) {
			for (const cp of codepoints(v)) {
				if (isCjk(cp)) cjk.add(cp);
				else latin.add(cp);
			}
		}
		for (const cp of AS_CHROME) latin.add(cp);
		locCp[code] = { latin, cjk };
	}
	return locCp;
}

function pickOrbSub(cmap) {
	const sub = {};
	for (const [fromStr, prefs] of Object.entries(ORB_SUB_PREF)) {
		const from = Number(fromStr);
		for (const to of prefs) {
			if (cmap.has(to)) { sub[from] = to; break; }
		}
	}
	return sub;
}

function applySub(cp, sub) {
	return sub[cp] != null ? sub[cp] : cp;
}

function missingAfter(cmap, set, sub) {
	const out = [];
	for (const cp of set) {
		const use = sub ? applySub(cp, sub) : cp;
		if (!cmap.has(use)) out.push(cp);
	}
	out.sort((a, b) => a - b);
	return out;
}

function compute(root) {
	const { cmap, sizes } = loadCmaps(root);
	const locCp = loadLangLatin(root);
	const orbSub = pickOrbSub(cmap.Orbitron);
	const cover = {};
	const rows = [];
	for (const [name] of FAMILIES) {
		const row = { name };
		for (const code of LANGS) {
			const sub = name === "Orbitron" ? orbSub : null;
			const miss = missingAfter(cmap[name], locCp[code].latin, sub);
			row[code] = { miss, n: miss.length };
		}
		rows.push(row);
	}
	for (const code of LANGS) {
		let bits = 0;
		const offer = [];
		const hide = [];
		for (const [name] of FAMILIES) {
			const n = rows.find((r) => r.name === name)[code].n;
			if (n === 0) { bits |= BITS[name]; offer.push(name); }
			else hide.push(name);
		}
		if ((bits & BITS.Exo2) === 0) {
			// Exo 2 is the INI fallback even if a language has leftover Latin;
			// the coverage test still fails that pair so the table cannot lie.
			bits |= BITS.Exo2;
			if (offer.indexOf("Exo2") < 0) offer.unshift("Exo2");
			const i = hide.indexOf("Exo2");
			if (i >= 0) hide.splice(i, 1);
		}
		cover[code] = { bits, offer, hide };
	}
	return { cmap, sizes, locCp, orbSub, rows, cover, langs: LANGS, families: FAMILIES.map((f) => f[0]), bits: BITS };
}

module.exports = {
	FAMILIES, LANGS, BITS, AS_CHROME, ORB_SUB_PREF,
	flatten, isCjk, parseCmap, codepoints, show,
	loadCmaps, loadLangLatin, pickOrbSub, missingAfter, compute
};
