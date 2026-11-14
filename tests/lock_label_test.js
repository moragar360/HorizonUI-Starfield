// 0.43.3.1 item 3 tests: the prompt keycap label shows the text after an inner line break (the lock level).
// Run: node tests/lock_label_test.js   (HZ_AS=<file> runs it against another horizon_block.as)
// Vanilla source: HUDRolloverActivationWidget.GetDataForButtonHint passes aButtons[].sTextPressAndRelease / sTextHold
// on as they are (only leading "\n" stripped); Horizon's keycap label is one line, so a part after a break was lost.
// Proves, by running the production AS (types stripped):
//  1. "\r\n", "\r" and "\n" (and runs of them, with spaces around) become exactly one space, on all three label paths
//     (raw text, the rendered vanilla label for a "$" key, the translated "$" key);
//  2. a label with no break is returned unchanged (same string), "" stays "";
//  3. static: hzT19OneLine has no listener, timer or search; it is called only from hzT19Label; plain ASCII.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const i = src.indexOf("private function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(i, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function toJs(body) {
	return body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) {")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
const H = {};
function bind(name) {
	const f = fnText(as, name);
	H[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(H);
}
let van = "", xl = "";
H.hzT19VanLbl = function() { return van; };
H.hzT19Xl = function() { return xl; };
bind("hzT19Trim"); bind("hzT19OneLine"); bind("hzT19Label");

const brk = [
	["Unlock\nAdvanced", "Unlock Advanced"], ["Unlock\r\nAdvanced", "Unlock Advanced"], ["Unlock\rAdvanced", "Unlock Advanced"],
	["Unlock\n(Expert)", "Unlock (Expert)"], ["Unlock \n Master", "Unlock Master"], ["Unlock\n\nNovice", "Unlock Novice"],
	["Unlock\r\n\r\nNovice", "Unlock Novice"], ["\nUnlock\nAdvanced\n", "Unlock Advanced"], ["Unlock\t\nAdvanced", "Unlock Advanced"],
	["Pick\nLock\nExpert", "Pick Lock Expert"], ["Unlock\nAdvanced\r", "Unlock Advanced"]
];
let bad = [];
for (const [i, o] of brk) { const g = H.hzT19Label(null, 0, false, i); if (g !== o) bad.push(JSON.stringify(i) + "->" + JSON.stringify(g)); }
expect(bad.length === 0, "raw text: every break form becomes one space (" + brk.length + " cases)" + (bad.length ? ": " + bad.join(" ") : ""));
bad = [];
for (const [i, o] of brk) { van = i; xl = ""; const g = H.hzT19Label(null, 0, false, "$Unlock"); if (g !== o) bad.push(JSON.stringify(i) + "->" + JSON.stringify(g)); }
expect(bad.length === 0, "rendered vanilla label for a $ key: one line" + (bad.length ? ": " + bad.join(" ") : ""));
bad = [];
for (const [i, o] of brk) { van = ""; xl = i; const g = H.hzT19Label(null, 0, true, "$Unlock"); if (g !== o) bad.push(JSON.stringify(i) + "->" + JSON.stringify(g)); }
expect(bad.length === 0, "translated $ key: one line" + (bad.length ? ": " + bad.join(" ") : ""));

const same = ["Take", "Unlock", "Open  Door", "Talk (Sarah)", "A", "Search"];
van = ""; xl = "";
expect(same.every((s) => H.hzT19Label(null, 0, false, s) === s) && H.hzT19Label(null, 0, false, "") === "" && H.hzT19Label(null, 0, false, null) === "" && H.hzT19OneLine("Take") === "Take", "a label with no break is unchanged; empty and null stay empty");
expect(H.hzT19OneLine(null) === null && H.hzT19OneLine("") === "", "null / empty input to hzT19OneLine are returned as they are");

const ol = fnText(as, "hzT19OneLine").body.replace(/\/\/[^\n]*/g, "");
expect(!/addEventListener|Timer|setTimeout|getChildByName|hzFindByName|new /.test(ol), "hzT19OneLine has no listener, timer, search or new");
const callers = (as.match(/this\.hzT19OneLine\(/g) || []).length;
const lbl = fnText(as, "hzT19Label").body;
expect(callers === 3 && (lbl.match(/this\.hzT19OneLine\(/g) || []).length === 3, "hzT19OneLine is called only from hzT19Label (3 return paths): " + callers);
expect(/^[\x00-\x7f]*$/.test(ol + lbl), "plain ASCII");

console.log((failed ? "FAILED " : "PASSED ") + passed + " ok, " + failed + " FAIL");
process.exit(failed ? 1 : 0);
