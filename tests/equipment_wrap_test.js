// Equipment card name wrap tests (0.43.3.0). Run: node tests/equipment_wrap_test.js
// Runs the production hzE19Sync / hzE19Tick / hzQWrapTo on a TextField model with word wrap. A long weapon name
// always wraps to a 2nd line at the same font size on the standard card (the card grows by one line); it is
// measured again only on a name, width (compact form) or format (font / scale / style) change; an ammo update or
// a frame measures nothing; the old timed expand (hzEqExpandUntil) no longer drives the card.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const as = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
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
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.*]+\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function bind(host, name) {
	const f = fnText(as, name);
	const m = f.sig.match(/\(([^)]*)\)/);
	const args = m && m[1].trim() ? m[1].split(",").map((a) => a.trim().split(":")[0].trim()) : [];
	host[name] = Function.apply(null, args.concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}
const constOf = (n) => { const m = as.match(new RegExp("static const " + n + ":(?:int|Number) = ([\\d.]+);")); if (!m) throw new Error(n); return Number(m[1]); };

const COST = { lines: 0, sets: 0 };
function TF(size) { this._t = ""; this.size = size; this.wordWrap = false; this.multiline = false; this.width = 100; this.x = 0; this.y = 0; this.visible = true; this.filters = []; }
Object.defineProperty(TF.prototype, "text", { get() { return this._t; }, set(v) { COST.sets++; this._t = String(v); } });
TF.prototype.cw = function () { return 0.6 * this.size; };
Object.defineProperty(TF.prototype, "numLines", {
	get() {
		COST.lines++;
		if (!this.wordWrap) return 1;
		const max = this.width - 4;
		let n = 1, cur = 0;
		for (const w of this._t.split(" ")) {
			const ww = w.length * this.cw();
			const add = cur === 0 ? ww : cur + this.cw() + ww;
			if (add > max && cur > 0) { n++; cur = ww; } else cur = add;
		}
		return n;
	}
});
const gfx = () => ({ clear() {}, lineStyle() {}, beginFill() {}, drawRoundRect() {}, endFill() {} });
function makeHost() {
	const mk = (fs) => { const t = new TF(fs); t._o = { tf: t, fs, fmtN: 0 }; return t; };
	const h = {
		int: (v) => Number(v) | 0, HZ_E19_W: constOf("HZ_E19_W"), HZ_E19_TX: constOf("HZ_E19_TX"), HZ_RED: 0xff0000, HZ_AMB: 0xffaa00,
		hzEq19: { visible: true }, HorizonAmmo_mc: {}, hzTextScale: 1, hzArrange: false, hzFrameN: 1000, hzEqExpandUntil: 0,
		hzEqFullName: "", hzEqHasAmmo: true, hzEqPct: false, hzEqLow: false, hzEqClip: 30, hzEqPulse: 0, hzTextShadow: false,
		hzE19Cm: false, hzE19Exp: false, hzE19Wd: 400, hzE19H: 92, hzE19T: 92, hzLaidOut: true, hz28GX: 0, hz30CntL: 0,
		cmp: false, syncs: 0, fmts: 0, sz: null,
		hz34C(k) { return k === "Equipment" && this.cmp; },
		hzTxtObj(tf) { return tf ? tf._o : null; },
		hzApplyFmt(o) { o.fmtN = (o.fmtN | 0) + 1; this.fmts++; },
		hzTW(tf) { return tf.text.length * tf.cw(); },
		hzUC(s) { return String(s).toUpperCase(); },
		hzTxtTop(tf, y) { tf.y = y; }, hzTxtTint() {}, hzIconCol(c) { return c; }, hzTyFilters() { return []; }, hzDarkText() { return false; },
		hz26EqRow() { return null; }, hzE19Draw() {},
		hzSetSz(c, w, hh) { this.sz = { w, h: hh }; },
		hzFontText(s) { return s; },
	};
	h.hzE19Name = mk(14); h.hzE19Name.x = 134; h.hzE19Name.width = 252;
	h.hzE19Cnt = mk(24); h.hzE19Res = mk(13); h.hzE19Type = mk(10); h.hzE19RelT = mk(9);
	h.hzEqCount = mk(24); h.hzEqCount.text = "30"; h.hzEqReserve = mk(13); h.hzEqReserve.text = "/ 120";
	h.hzE19Cart = { y: 0, visible: true }; h.hzE19Chip = { x: 0, y: 0, visible: false, graphics: gfx() }; h.hzAmmoType = { text: "7.77MM CASELESS" };
	for (const n of ["hzE19Sync", "hzE19Tick", "hzQWrapTo", "hzFitText"]) bind(h, n);
	const real = h.hzE19Sync; h.hzE19Sync = function () { h.syncs++; return real(); };
	return h;
}
const LONG = "Advanced Magshear of the Eternal Void";
const HUGE = "Calibrated Superior Advanced Magshear of the Eternal Void and the Burning Constellation Forever";

{
	const h = makeHost(); h.hzEqFullName = "Grendel"; h.hzE19Sync();
	expect(h.hzE19Name.text === "GRENDEL" && !(h.hzE19Name._o.lines > 1) && h.hzE19H === 92 && h.sz.h === 92, "a short name: one line, today's 92 height");
}
{
	const h = makeHost(); h.hzEqFullName = LONG; h.hzE19Sync();
	const n = h.hzE19Name;
	expect(n.wordWrap && n._o.lines === 2 && n.text === LONG.toUpperCase(), "a long name wraps to a 2nd line with the full text (no ellipsis), with no swap timer running");
	expect(n._o.fs === 14 && n.width === 252, "same font size (14) and today's field width");
	expect(h.hzE19H === 92 + 20 && h.sz.h === 112 && h.hzLaidOut === false, "the card grows by one line (92 -> 112) and asks for a layout");
	expect(h.hzE19Cnt.y === 35 + 20 && h.hzE19Cart.y === 53 + 20, "the ammo row moves down under the 2nd line");
}
{
	const h = makeHost(); h.hzEqFullName = HUGE; h.hzE19Sync();
	expect(h.hzE19Name._o.lines === 2 && /\.\.\.$/.test(h.hzE19Name.text) && h.hzE19Name.numLines === 2, "a name too long for 2 lines: 2 lines, '...' on the 2nd only");
}
{
	const h = makeHost(); h.cmp = true; h.hzEqFullName = LONG; h.hzEqHasAmmo = false; h.hzE19Sync();
	expect(!h.hzE19Name.wordWrap && !(h.hzE19Name._o.lines > 1) && /\.\.\.$/.test(h.hzE19Name.text) && h.hzE19Name.width === 300 - 126 - 14, "compact form: one line with '...' at the compact width");
	h.cmp = false; h.hzE19Tick();
	expect(h.hzE19Name.wordWrap && h.hzE19Name._o.lines === 2 && h.hzE19Name.width === 252, "compact off (style edge): the tick resyncs once and the name wraps again");
}
{
	const h = makeHost(); h.hzEqFullName = LONG; h.hzE19Sync();
	let c0 = COST.lines, s0 = COST.sets;
	for (let i = 0; i < 100; i++) { h.hzEqCount.text = String(30 - (i % 30)); h.hzEqClip = 30 - (i % 30); h.hzE19Sync(); }
	expect(COST.lines === c0, "100 ammo updates: the name is never measured again");
	const nameSets = (() => { let k = 0; const t = h.hzE19Name; const d = Object.getOwnPropertyDescriptor(TF.prototype, "text"); Object.defineProperty(t, "text", { get: d.get, set(v) { k++; d.set.call(this, v); }, configurable: true }); for (let i = 0; i < 50; i++) h.hzE19Sync(); return k; })();
	expect(nameSets === 0, "and the name text is never rewritten");
	c0 = COST.lines; h.hzEqFullName = "Coachman"; h.hzE19Sync();
	expect(COST.lines > c0 && h.hzE19H === 92, "a weapon swap measures once (the card shrinks back)");
	c0 = COST.lines; h.hzEqFullName = LONG; h.hzE19Sync(); const c1 = COST.lines; h.hzE19Name._o.fmtN++; h.hzE19Sync();
	expect(c1 > c0 && COST.lines > c1, "a format change (font / text scale / style) measures again");
	h.syncs = 0; c0 = COST.lines;
	for (let f = 0; f < 200; f++) { h.hzFrameN++; h.hzEqExpandUntil = f === 10 ? h.hzFrameN + 90 : h.hzEqExpandUntil; h.hzArrange = f > 150; h.hzE19Tick(); }
	expect(h.syncs === 0 && COST.lines === c0, "200 frames (a swap window and ARRANGE included): the tick never resyncs or measures");
}
{
	const tick = fnText(as, "hzE19Tick").body, sync = fnText(as, "hzE19Sync").body;
	expect(!/hzEqExpandUntil|hzFrameN/.test(tick) && !/hzEqExpandUntil|hzFrameN/.test(sync), "the card no longer reads the timed expand (hzEqExpandUntil / hzFrameN)");
	expect(/this\.hzQWrapTo\(this\.hzE19Name,full,/.test(sync) && !/numLines/.test(sync), "the name goes through the memoized wrap (no direct numLines read)");
	expect(!/Timer|setTimeout|setInterval|ENTER_FRAME|addEventListener/.test(sync + tick), "no timer / frame / listener code");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("equipment wrap: " + passed + " ok, all passed");
