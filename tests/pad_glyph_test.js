// 0.43.3.1 item 2 tests: the hover / prompt keycaps show the controller button the game bound (a remap included).
// Run: node tests/pad_glyph_test.js   (HZ_AS=<file> runs it against another horizon_block.as)
// Vanilla source: MinimalButton.UpdateButtonText fills ConsoleButton_mc.ButtonInstance_mc.ConsoleButton_tf with the
// GlobalFunc.NameToTextMap glyph of the bound button (ButtonKeyHelper.GetButtonNameForEvent over the control map).
// Proves, by running the production AS (types stripped):
//  1. every Xbox / PlayStation face, shoulder, trigger, stick and menu glyph maps to its keycap text;
//  2. a remap (Activate on Y: slot 0 shows the Y glyph) shows Y, on 1 to 4 buttons;
//  3. an unknown or empty glyph, a missing ConsoleButton_tf, and the keyboard keep the old result exactly;
//  4. two-glyph joins ("/" and " + ") map both; anything longer is unknown;
//  5. static: hzT19PadKey has no loop, listener, timer or search; hzT19Key is still called only where it was.
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
function bind(host, name) {
	const f = fnText(as, name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}
function constObj(name) {
	const i = as.indexOf("private static const " + name + ":Object = {");
	if (i < 0) throw new Error("missing " + name);
	const b = as.indexOf("{", i), e = as.indexOf("};", b);
	return Function("return " + as.slice(b, e + 1) + ";")();
}

// vanilla GlobalFunc.NameToTextMap (the controller part), copied from the game script
const N2T = {
	Xenon_A: "A", Xenon_B: "B", Xenon_X: "C", Xenon_Y: "D", Xenon_Select: "E", Xenon_LS: "F", Xenon_L1: "G", Xenon_L3: "H",
	Xenon_L2: "I", Xenon_L2R2: "J", Xenon_RS: "K", Xenon_R1: "L", Xenon_R3: "M", Xenon_R2: "N", Xenon_Start: "O", Xenon_L1R1: "1",
	Xenon_R2_Alt: "X", Xenon_L2_Alt: "Y",
	PSN_A: "a", PSN_Y: "b", PSN_X: "c", PSN_B: "d", PSN_Select: "z", PSN_L3: "f", PSN_L1: "g", PSN_L1R1: "h", PSN_LS: "i",
	PSN_L2: "j", PSN_L2R2: "k", PSN_R3: "l", PSN_R1: "m", PSN_RS: "n", PSN_R2: "o", PSN_Start: "p", PSN_R2_Alt: "x", PSN_L2_Alt: "y",
	Left: "T", Right: "U", Down: "V", Up: "W", DPad_LR: "q", DPad_UD: "r", DPad_All: "s", DPad_Left: "t", DPad_Right: "u", DPad_Down: "v", DPad_Up: "w"
};
const WANT = {
	Xenon_A: "A", Xenon_B: "B", Xenon_X: "X", Xenon_Y: "Y", Xenon_Select: "VIEW", Xenon_Start: "MENU", Xenon_L1: "LB", Xenon_R1: "RB",
	Xenon_L2: "LT", Xenon_R2: "RT", Xenon_L2_Alt: "LT", Xenon_R2_Alt: "RT", Xenon_LS: "LS", Xenon_L3: "LS", Xenon_RS: "RS", Xenon_R3: "RS",
	Xenon_L1R1: "LB+RB", Xenon_L2R2: "LT+RT",
	PSN_A: "A", PSN_B: "B", PSN_X: "X", PSN_Y: "Y", PSN_Select: "VIEW", PSN_Start: "MENU", PSN_L1: "LB", PSN_R1: "RB", PSN_L2: "LT",
	PSN_R2: "RT", PSN_L2_Alt: "LT", PSN_R2_Alt: "RT", PSN_LS: "LS", PSN_L3: "LS", PSN_RS: "RS", PSN_R3: "RS", PSN_L1R1: "LB+RB", PSN_L2R2: "LT+RT",
	Left: "LEFT", Right: "RIGHT", Down: "DOWN", Up: "UP", DPad_Left: "LEFT", DPad_Right: "RIGHT", DPad_Down: "DOWN", DPad_Up: "UP",
	DPad_LR: "D-PAD", DPad_UD: "D-PAD", DPad_All: "D-PAD"
};

const H = { HZ_T19_PADK: constObj("HZ_T19_PADK") };
H.hzT19Trim = function(s) { if (s === undefined || s === null) return ""; return String(s).trim(); };
let clips = [null, null, null, null];
H.hzT19BtnClip = function(aw, t) { return clips[t] || null; };
bind(H, "hzT19PadKey");
bind(H, "hzT19Key");

function Btn(pad, glyph, pcKey, noTf) {
	const ci = { visible: pad };
	if (!noTf) ci.ConsoleButton_tf = { text: glyph };
	return { PCButton_mc: { ButtonInstance_mc: { visible: !pad, PCButton_tf: { text: pcKey } } }, ConsoleButton_mc: { ButtonInstance_mc: ci } };
}
// the old body (591d340), for the unchanged cases
function oldKey(b, t) {
	let k = "", pad = false;
	try { const pc = b.PCButton_mc.ButtonInstance_mc; if (pc && pc.visible) k = String(pc.PCButton_tf.text).trim(); } catch (e) { }
	try { const cb = b.ConsoleButton_mc.ButtonInstance_mc; if (cb && cb.visible) pad = true; } catch (e) { }
	if (k.length == 0 || pad) k = t >= 0 && t < 4 ? ["A", "X", "Y", "B"][t] : "?";
	if (k.length > 8) k = k.substr(0, 8);
	return k.toUpperCase();
}

// 1. every glyph
let bad = [];
for (const n of Object.keys(WANT)) {
	clips = [Btn(true, N2T[n], "e"), null, null, null];
	const got = H.hzT19Key(null, 0);
	if (got !== WANT[n]) bad.push(n + "=" + got);
}
expect(bad.length === 0, "every controller glyph maps to its keycap text (" + Object.keys(WANT).length + " names)" + (bad.length ? ": " + bad.join(",") : ""));
expect(Object.keys(N2T).every((n) => WANT[n] !== undefined), "the test covers every controller glyph of the vanilla map");

// 2. remaps on 1 to 4 buttons
for (let count = 1; count <= 4; count++) {
	const slotsGlyph = ["D", "C", "A", "B"];   // Activate on Y, the X slot on X, Y slot on A (jump), B unchanged
	clips = [0, 1, 2, 3].map((t) => (t < count ? Btn(true, slotsGlyph[t], "e") : null));
	const keys = [0, 1, 2, 3].slice(0, count).map((t) => H.hzT19Key(null, t));
	expect(keys.join(",") === ["Y", "X", "A", "B"].slice(0, count).join(","), "remap shows the bound buttons with " + count + " prompt button(s): " + keys.join(","));
}

// 3. unchanged cases
const cases = [];
for (let t = 0; t < 4; t++) {
	cases.push([Btn(true, "", "e"), t], [Btn(true, "?", "e"), t], [Btn(true, "Z", "e"), t], [Btn(true, "AB", "e"), t], [Btn(true, null, "e"), t]);
	cases.push([Btn(true, "A", "e", true), t], [Btn(false, "D", "e"), t], [Btn(false, "D", ""), t], [Btn(false, "", "Left Shift Key"), t], [null, t]);
}
let diff = 0;
for (const [b, t] of cases) { clips = [b, b, b, b]; if (H.hzT19Key(null, t) !== oldKey(b, t)) diff++; }
expect(diff === 0, "unknown / empty glyph, no ConsoleButton_tf, keyboard and a missing clip keep the old key exactly (" + cases.length + " cases)");

// 4. joins
expect(H.hzT19PadKey("A/D") === "A/Y" && H.hzT19PadKey("G + L") === "LB+RB" && H.hzT19PadKey("A/Z") === "" && H.hzT19PadKey("A/D/C") === "" && H.hzT19PadKey("A-D") === "" && H.hzT19PadKey(undefined) === "", "two-glyph joins map both glyphs; longer or unknown joins are unknown");

// 5. static
const pk = fnText(as, "hzT19PadKey").body.replace(/\/\/[^\n]*/g, "");
expect(!/\b(for|while)\b|addEventListener|Timer|setTimeout|getChildByName|hzFindByName|new /.test(pk), "hzT19PadKey has no loop, listener, timer, search or allocation");
const calls = (as.match(/this\.hzT19Key\(/g) || []).length;
expect(calls === 2, "hzT19Key is called from the same 2 places as before (label edge read and the row draw): " + calls);
expect(/^[\x00-\x7f]*$/.test(fnText(as, "hzT19PadKey").body + fnText(as, "hzT19Key").body), "plain ASCII");

console.log((failed ? "FAILED " : "PASSED ") + passed + " ok, " + failed + " FAIL");
process.exit(failed ? 1 : 0);
