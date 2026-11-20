// 0.43.3.2 item 6 tests: [Scanner] ScanHideBioscanDone (default 0) hides the Bioscan card once the planet is fully
// scanned. Run: node tests/bioscan_hide_done_test.js
// Runs the production hzsMBioscan (types stripped) and checks: off by default and output unchanged when off; on: the
// card stays while anything is left (any row, or a biome flag not set), the scan-complete flash still plays, and the
// card goes (null, like ScanShowBioscan=0) once every row is found and the biome flags agree. Also: the key is in the
// scanner table, the HUD table, the HUD comment table, the F11 SCANNER rows and the default ini (0), and both
// MonocleMenu.as copies carry the same hzsMBioscan. Mutants must fail.
// Author: Moragar. Last modified: 2026-11-18.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const rd = (p) => fs.readFileSync(path.join(root, p), "utf8").replace(/\r\n/g, "\n");
const S0 = rd("actionscript/scanner/hzs_block.as");
const H0 = rd("actionscript/horizon_block.as");
const INI = rd("Interface/HorizonUI/HorizonUI.default.ini");
const MM = [rd("actionscript/imp/simp_monoclemenu/MonocleMenu.as"), rd("actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as")];

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src);
	if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1;
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
let NOW = 100000;
function toJs(src, name) {
	const f = fnText(src, name);
	const body = f.body.replace(/var (\w+):[\w*]+/g, "let $1").replace(/for each\(let (\w+) in ([^)]+)\)/g, "for (let $1 of $2)");
	return new Function("getTimer", "int", body);
}
function host(src, cfg, md, traits) {
	const h = {
		hzsC: Object.assign({ ScanShowBioscan: 1, ScanLeftToFind: 1, ScanCompleteFlash: 1, ScanHideBioscanDone: 0 }, cfg),
		hzsMD: md, hzsFlashT: -100000,
		hzsOn(k) { return int(this.hzsC[k]) === 1; }, hzsShowPlanetInfo() { return true; }, hzsTraitState() { return traits; },
		hzsCs(s) { return s; }, hzsCmpOn() { return false; },
	};
	const f = toJs(src, "hzsMBioscan");
	h.run = () => f.call(h, () => NOW, int);
	return h;
}
function int(v) { return v | 0; }
const DONE = { uFaunaMax: 4, uFaunaCurrent: 4, uFloraMax: 3, uFloraCurrent: 3, uResourcesMax: 2, uResourcesCurrent: 2, bBiomeFloraComplete: true, bBiomeFaunaComplete: true };
function behave(src, log) {
	const bad = [];
	const chk = (c, m) => { if (log) expect(c, m); if (!c) bad.push(m); };
	try {
		const off = S0.replace(/\n\s*\/\/ 0\.43\.3\.2 ScanHideBioscanDone[\s\S]*?\{ return null; \}/, "");
		chk(off !== S0, "the option block is found");
		const base = JSON.stringify(host(off, {}, DONE, [2, 2]).run());
		chk(base !== "null" && JSON.stringify(host(src, {}, DONE, [2, 2]).run()) === base, "option off (default): a fully scanned planet still shows the same card as before");
		chk(host(src, { ScanHideBioscanDone: 1 }, DONE, [2, 2]).run() === null, "option on, planet fully scanned: no card");
		chk(host(src, { ScanHideBioscanDone: 1 }, Object.assign({}, DONE, { uFloraCurrent: 2 }), [2, 2]).run() !== null, "option on, a flora left: the card stays");
		chk(host(src, { ScanHideBioscanDone: 1 }, Object.assign({}, DONE, { uResourcesCurrent: 1 }), [2, 2]).run() !== null, "option on, a resource left: the card stays");
		chk(host(src, { ScanHideBioscanDone: 1 }, DONE, [1, 2]).run() !== null, "option on, a trait unknown: the card stays");
		chk(host(src, { ScanHideBioscanDone: 1 }, Object.assign({}, DONE, { bBiomeFaunaComplete: false }), [2, 2]).run() !== null, "option on, the game's biome fauna flag not set: the card stays");
		chk(host(src, { ScanHideBioscanDone: 1 }, Object.assign({}, DONE, { uFloraMax: 0, uFloraCurrent: 0, bBiomeFloraComplete: false }), [2, 2]).run() === null, "a planet with no flora: the flora flag is not needed");
		const hf = host(src, { ScanHideBioscanDone: 1 }, DONE, [2, 2]); hf.hzsFlashT = NOW - 500;
		chk(hf.run() !== null, "the scan-complete flash still plays on the card first");
		hf.hzsFlashT = NOW - 2000;
		chk(hf.run() === null, "then the card goes");
	} catch (e) {
		chk(false, "threw " + e.message);
	}
	return bad;
}

behave(S0, true);

const KEY = '["ScanHideBioscanDone","b",0,0,1]';
expect(/HZS_KEYS:Array = \[.*\["ScanHideBioscanDone","b",0,0,1\]/.test(S0), "scanner key table: ScanHideBioscanDone, bool, default 0");
expect(/HZ40_SCAN_KEYS:Array = \[.*\["ScanHideBioscanDone","b",0,0,1\]/.test(H0), "HUD key table: the same entry");
expect(/HZ40_SCAN_CM:Object = \{.*"ScanHideBioscanDone":\["1 = no bioscan card once the planet is fully scanned/.test(H0), "HUD ini comment table has it");
expect(/\{"k":"ScanShowBioscan","l":"BIOSCAN","t":"b"\}[^\n]*\n\s*\{"k":"ScanHideBioscanDone","l":"HIDE WHEN FULLY SCANNED","t":"b","sub":true,/.test(H0), "F11 > SCANNER: HIDE WHEN FULLY SCANNED sits under BIOSCAN");
expect(/\nScanHideBioscanDone=0\n/.test(INI), "default ini: ScanHideBioscanDone=0");
const mb = fnText(S0, "hzsMBioscan").body;
expect(MM.every((t) => fnText(t, "hzsMBioscan").body === mb && t.indexOf(KEY) >= 0), "both MonocleMenu.as copies carry the same hzsMBioscan and key");
expect(/^[\x09\x0a\x20-\x7e]*$/.test(mb), "plain ASCII");

const mutants = [
	["ignores the option", (s) => s.replace('&& this.hzsOn("ScanHideBioscanDone") ', "")],
	["ignores the flash", (s) => s.replace("if(fl <= 0 && tot >= mx", "if(tot >= mx")],
	["biome flags ignored", (s) => s.replace("&& (md.bBiomeFloraComplete === true || int(md.uFloraMax) <= 0) && (md.bBiomeFaunaComplete === true || int(md.uFaunaMax) <= 0)", "")],
	["only fauna and flora counted", (s) => s.replace("if(fl <= 0 && tot >= mx", "if(fl <= 0 && int(md.uFaunaCurrent) >= int(md.uFaunaMax) && int(md.uFloraCurrent) >= int(md.uFloraMax)")],
];
for (const [name, fn] of mutants) {
	const m = fn(S0);
	if (m === S0) { expect(false, "mutant " + name + " applies"); continue; }
	const bad = behave(m, false);
	expect(bad.length > 0, "mutant " + name + " is caught" + (bad.length ? " (" + bad[0] + ")" : ""));
}

console.log("bioscan hide when done: " + passed + " ok" + (failed ? ", " + failed + " FAILED" : ", all passed"));
process.exit(failed ? 1 : 0);
