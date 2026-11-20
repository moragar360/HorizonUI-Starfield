// Compact name hover pill: a long name wraps to a second and third line (0.43.3.2). Run: node tests/pill_wrap_test.js
// Runs the production hzT19PromptPill / hzT19WrapN / hzT19LineAdv (types stripped) on a small host with a fake
// TextField (8 px per character, greedy word wrap) and checks:
//  1. a name that fits stays one line, the pill keeps its height, no wrap state is set;
//  2. a name that would be cut wraps to two lines at the same font size (never smaller), whole, with no "...";
//     the pill grows by exactly one line and keeps the one-line corner radius;
//  3. a name too long for two lines takes a third (batch e) and the pill grows by one more line; a name too long for
//     three lines ends line three in "..." (never a fourth line);
//  4. the layout runs only on the content edge: hzT19PromptPill is called only from hzT19Content, which is called
//     only behind the content-signature change; no timer, listener, frame term or tree search in the new code;
//     hzT19Content clears the wrap state for every other card kind.
// Author: Moragar. Last modified: 2026-11-18 (batch e).
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

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
const count = (s, sub) => s.split(sub).length - 1;
const codeOnly = (s) => s.replace(/\/\/.*$/gm, "");
function toJs(name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
	let b = f.body
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/([^.\w"])HZ_(\w+)\b/g, "$1this.HZ_$2");
	return new Function(...params, b);
}
global.int = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)) | 0; };

const CW = 8;   // px per character
function mkTf() {
	const t = { _t: "", x: 0, y: 0, width: 100, height: 20, visible: true, wordWrap: false, multiline: false, sets: 0 };
	Object.defineProperty(t, "text", { get() { return this._t; }, set(v) { this._t = String(v); this.sets++; } });
	Object.defineProperty(t, "numLines", { get() {
		if (!this.wordWrap) return 1;
		const words = this._t.split(" ");
		let lines = 1, cur = 0;
		for (const w of words) {
			const ww = w.length * CW;
			if (cur === 0) { cur = ww; continue; }
			if (cur + CW + ww <= this.width - 4) cur += CW + ww; else { lines++; cur = ww; }
		}
		return lines;
	} });
	t.getLineMetrics = () => ({ ascent: 13, descent: 4, leading: 2 });
	return t;
}
function host() {
	const h = {
		HZ_ACCENT: 0x3FD0E0, HZ_RED: 0xFF5B5B, HZ_T19_NMLINES: Number((/HZ_T19_NMLINES:int = (\d+);/.exec(as) || [])[1]), hzTextScale: 1, panels: [], fmts: 0,
		hzT19PillCap() { return 22; },
		hzApplyFmt(o) { this.fmts++; o.tf.height = (o.fs + 4) * (o.lines > 1 ? o.lines : 1) + 6; },
		hzUC(s) { return s; },
		hzTW(tf) { return tf.text.length * CW; },
		hzT19Buttons(g, a, aw, x, y) { return 120; },
		hzPanel(g, W, H, r) { this.panels.push({ W, H, r }); },
		hzT19Tile() {}, hzT19U() { return 1; }, hzSnapU(v) { return Math.round(v); },
		hzCapTop(tf, cy) { return cy - 7; },
		hzTxtTopU(tf, top) { tf.y = top; },
	};
	for (const n of ["hzT19PromptPill", "hzT19WrapN", "hzT19LineAdv", "hzFitText"]) h[n] = toJs(n);
	return h;
}
function pill(name) {
	const h = host();
	const tf = mkTf();
	const o = { tf, fs: 14, size: 14, lines: 1 };
	const r = h.hzT19PromptPill({}, { bStealing: false }, {}, o, tf, name, true, 120);
	return { h, tf, o, r, panel: h.panels[h.panels.length - 1] };
}

// ---- 1. short name ----
const s = pill("IRON");
expect(s.tf.text === "IRON" && !s.tf.wordWrap && s.o.lines === 1, "a name that fits: one line, no wrap state");
const H1 = s.r.H;
expect(H1 === 52 && s.panel.H === 52 && s.panel.r === 26, "one-line pill height 52, corner radius 26");
// ---- 2. long name wraps whole at the same size ----
const longName = "HUNTING STONEWALL TAILWHIP ALPHA";   // 32 chars = 256 px, past the 220 px name cap
const L = pill(longName);
expect(L.tf.wordWrap && L.tf.multiline && L.tf.numLines === 2 && L.o.lines === 3, "a name that would be cut wraps to two lines (the field allows three)");
expect(L.tf.text === longName && L.tf.text.indexOf("...") < 0, "the wrapped name is whole (no ...)");
expect(L.o.fs === 14 && L.o.size === 14, "same font size as one line (never shrunk)");
expect(L.r.H === H1 + 19 && L.panel.H === H1 + 19, "the pill grows by exactly one line (" + L.r.H + " = " + H1 + " + 19)");
expect(L.panel.r === 26, "the corner radius stays the one-line radius");
expect(L.r.W === s.r.W || L.r.W > s.r.W, "the width rule is unchanged (name room capped as before)");
// ---- 3. three lines, then ... ----
const three = "HUNTING STONEWALKER STALKER ALPHA MALE OF THE NORTHERN RIDGE";   // like the in-game case: line two was cut with ...
const T = pill(three);
expect(T.tf.numLines === 3 && T.tf.text === three, "a name too long for two lines is whole on three lines (" + T.tf.text + ")");
expect(T.r.H === H1 + 38 && T.panel.H === H1 + 38 && T.panel.r === 26, "the pill grows by exactly two lines, only because the name needs them");
expect(T.o.fs === 14, "same font size on three lines");
const huge = "VERY LONG NAME OF A CONTAINER THAT GOES ON AND ON AND ON AND ON AND ON AND ON PAST THREE LINES OF TEXT";
const X = pill(huge);
expect(X.tf.numLines === 3 && /\.\.\.$/.test(X.tf.text) && X.tf.text.length < huge.length, "past three lines: line three ends in ... (" + X.tf.text + ")");
expect(X.r.H === H1 + 38, "never more than two extra lines");
expect(/private static const HZ_T19_NMLINES:int = 3;/.test(as), "the line cap is 3");
// ---- 4. edge only ----
const pillSrc = codeOnly(fnText(as, "hzT19PromptPill").body) + codeOnly(fnText(as, "hzT19WrapN").body) + codeOnly(fnText(as, "hzT19LineAdv").body);
expect(!/addEventListener|ENTER_FRAME|enterFrame|setInterval|setTimeout|new Timer|getTimer|hzFrameN|% \d|hzFindByName|getChildByName|getChildAt/.test(pillSrc), "no timer, listener, frame term or tree search in the pill layout");
expect(count(as, "this.hzT19PromptPill(") === 1 && fnText(as, "hzT19Content").body.indexOf("this.hzT19PromptPill(") >= 0, "the pill is laid out only from hzT19Content");
expect(count(as, "this.hzT19WrapN(") === 1 && count(as, "this.hzT19LineAdv(") === 1, "the wrap helpers are called only from the pill");
const tick = fnText(as, "hzT19Tick").body;
const ci = tick.indexOf("this.hzT19Content(");
expect(count(as, "this.hzT19Content(") === 1 && ci > 0 && tick.lastIndexOf("if(sig != this.hzT19Sig)", ci) > 0, "hzT19Content runs only behind the content-signature change (an edge, not per frame)");
const head = fnText(as, "hzT19Content").body;
expect(head.indexOf('o.tone = "main"; o.lines = 1; }') >= 0 && head.indexOf("if(nmTf.wordWrap) { nmTf.wordWrap = false; nmTf.multiline = false; }") >= 0 && head.indexOf("o.lines = 1;") < head.indexOf("this.hzT19PromptPill("), "every redraw clears the wrap state first, so other card kinds stay one line");

console.log("pill_wrap_test " + (failed ? "FAILED" : "passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
