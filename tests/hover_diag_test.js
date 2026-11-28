// 0.43.4 item 1 tests: the private [Debug] HoverDiag switch (hover card stutter diagnostics).
// Run: node tests/hover_diag_test.js
// Proves: off by default and absent from the shipped default.ini, installer and README; parsed section-aware with the
// last line winning; stripped from saved presets; when off the content edge and the hide walk make zero extra calls
// (no timer read, no log push, no HoverDiag helper) and the keycap layout passes stay 2 (FULL) / 3 (COMPACT); each bit
// does its one job (1 bypass, 2 FULL, 4 COMPACT, 8 skip the full-size measure, 16 walk on the edge frame only,
// 32 edge timing to the watchlog queue). Runs the production functions (types stripped) on recording hosts.
// Author: Moragar. Last modified: 2026-11-20.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const SRC = fs.readFileSync(process.env.HZ_HOVER_SRC || path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const METRIC = { lsMissing: false };
let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src); if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1; let depth = 0;
	for (let p = brace; p < src.length; p++) { if (src[p] === "{") depth++; else if (src[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: src.slice(brace + 1, p) }; } }
	throw new Error("unbalanced " + name);
}
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const defs = f.params.split(",").map((p) => p.trim()).filter((p) => /=/.test(p)).map((p) => { const n = p.split(":")[0].trim(); const v = p.split("=")[1].trim(); return "if(" + n + " === undefined) " + n + " = " + v + ";"; }).join("\n");
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (var $1 of ")
		.replace(/var (\w+):[\w*]+/g, "var $1")
		.replace(/([\w.\]\)]+) as (?:Array|MovieClip|Object|DisplayObject|DisplayObjectContainer|TextField|Sprite)\b/g, "$1")
		.replace(/([\w.]+) is Array/g, "Array.isArray($1)")
		.replace(/(\w+) is TextField/g, "($1 && $1.isTf)")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/(^|[^.\w])(HZ\w*)\b/g, "$1this.$2");
	return new Function(...params, defs + "\n" + body);
}
global.TextField = (t) => t; global.DisplayObject = (t) => t;
global.int = (v) => v | 0; global.uint = (v) => v >>> 0;
const CW = 9;
function charW(t) { return CW * t.fs / 13; }
function lineW(t, s) { return s.length * charW(t) + Math.max(0, s.length - 1) * t.ls; }
function wrapLines(t, s) {
	const parts = String(s).split(/\r\n|\r|\n/);
	if (!t.wordWrap) return parts;
	const out = [];
	for (const p of parts) {
		const words = p.split(" "); let cur = "";
		for (const w of words) { const c = cur.length ? cur + " " + w : w; if (cur.length && lineW(t, c) > t.width - 4) { out.push(cur); cur = w; } else cur = c; }
		out.push(cur);
	}
	return out;
}
function mkTf(name, w, fsz, ls) {
	const t = { isTf: true, name, width: w, height: fsz + 16, x: 0, y: 0, visible: false, _t: "", fs: fsz, ls, wordWrap: false, multiline: false };
	Object.defineProperty(t, "text", { get() { return this._t; }, set(v) { this._t = String(v); } });
	Object.defineProperty(t, "numLines", { get() { return wrapLines(this, this._t).length; } });
	Object.defineProperty(t, "textWidth", { get() { return Math.max(0, ...wrapLines(this, this._t).map((l) => lineW(this, l))); } });
	t.getLineMetrics = () => ({ ascent: t.fs * 0.8, descent: t.fs * 0.25, leading: 2 });
	t.getTextFormat = () => ({ size: t.fs, letterSpacing: t.ls });
	return t;
}
// visible ink of a field: clipped at its width and at its height
function ink(t) {
	if (!t.visible || t._t.length === 0) return null;
	const lines = wrapLines(t, t._t);
	const lh = t.fs * 1.25;
	const shown = Math.max(1, Math.min(lines.length, Math.floor((t.height - 4) / lh) || 1));
	const w = Math.min(Math.max(...lines.slice(0, shown).map((l) => lineW(t, l))), t.width - 4);
	return { n: t.name + ":" + t._t, x: t.x + 2, y: t.y + 2 + t.fs * 0.15, w, h: shown * lh - t.fs * 0.3 };
}
function makeHost(src) {
	const recs = [];
	const g = { calls: [] };
	for (const m of ["clear", "beginFill", "endFill", "lineStyle", "drawRect", "drawCircle", "moveTo", "lineTo", "drawRoundRect"]) g[m] = function () { this.calls.push([m, ...arguments]); };
	const slots = [];
	for (let i = 0; i < 4; i++) slots.push({ kp: mkTf("kp", 60, 12, 0), lp: mkTf("lp", 160, 13, 1.6), hh: mkTf("hh", 60, 11, 1.2), kh: mkTf("kh", 60, 12, 0), lh: mkTf("lh", 160, 13, 1.6) });
	const objs = new Map();
	const h = {
		recs, g, fsLog: [], btnCalls: 0,
		HZ_ACCENT: 0x6FD3FF, HZ_RED: 0xFF5B5B, HZ_AMB: 0xF2A93B, HZ_GREEN: 0x5EE3A1,
		HZ38_PR_PAD: 20, HZ38_PR_MINW: 310, HZ38_PR_MAXW: 480, HZ_T19_NMLINES: 3, HZ_T19_LBLW: 480,
		hzT19Btn: slots, hzNameHover: 0, hzTextScale: 1, hzT19BarOn: false, hzT19BarG: null, hzT19Kov: null,
		hzT19G: { graphics: g }, hzT19Rows: [], hzT19Cmp: [], hzTg19: { numChildren: 0 },
		hzT19Name: mkTf("name", 300, 16, 2), hzT19Meta: mkTf("meta", 180, 13, 0.5), hzT19Ch1: mkTf("ch1", 140, 10, 1.4), hzT19Ch2: mkTf("ch2", 140, 10, 1.4), hzT19Ch3: mkTf("ch3", 140, 10, 1.4),
		hzT19HdrR: mkTf("hdrR", 140, 12, 1.4), hzT19Foot: mkTf("foot", 200, 12, 0.3), hzT19FootR: mkTf("footR", 180, 12, 0.5),
		hzDarkText() { return false; }, hzIconCol(c) { return c; }, hzMix(a) { return a; }, hzPanelFill() { return 0; }, hzLight() { return false; },
		hzT19PaintFoeBars() { }, hzT19Key() { return "E"; }, hzT19VanLbl() { return ""; }, hzT19Xl(s) { return s; }, hzLt(s) { return s; }, hzUC(s) { return String(s).toUpperCase(); },
		hzT19U() { return 1; }, hzSnapU(v) { return Math.round(v); }, hzChipSzOn(f) { return f; }, hzT19KeyOv() { return null; },
		hzTxtObj(t) { if (!objs.has(t)) objs.set(t, { tf: t, fs: t.fs, size: t.fs, ls: t.ls }); return objs.get(t); },
		hzApplyFmt(o) { if (o && o.tf) { o.tf.fs = Number(o.fs); const nl = o.lines > 1 ? o.lines : 1; o.tf.height = (o.tf.fs + 5) * nl + 6; } },
		hzT19FaceFs(t, f) { const o = this.hzTxtObj(t); if (o.fs == f && o.size == f) return; o.fs = f; o.size = f; t.fs = f; this.fsLog.push(f); },
		hzTW(t) { return METRIC.lsMissing ? Math.max(0, ...wrapLines(t, t._t).map((l) => l.length * charW(t))) : t.textWidth; },
		hzKeycap(gg, x, y, w, hh) { recs.push({ n: "cap", x, y, w, h: hh }); },
		hzTxtTint() { }, hzTxtTopU(t, top) { t.y = Math.round(top); }, hzTxtTop(t, top) { t.y = Math.round(top); }, hzCapTop(t, cy) { return cy - 2 - t.fs * 0.8 + 0.36 * t.fs; },
		hzPanel(gg, w, hh) { recs.push({ n: "panel", x: 0, y: 0, w, h: hh }); }, hzT19Tile(gg, cx, cy, c, rad) { rad = rad || 23; recs.push({ n: "tile", x: cx - rad, y: cy - rad, w: 2 * rad, h: 2 * rad }); },
		hzFitText(t, full, maxW) { t.text = full; if (this.hzTW(t) <= maxW - 4 || full.length < 2) return; let n = full.length; while (n > 1) { t.text = full.substr(0, n) + "..."; if (this.hzTW(t) <= maxW - 4) return; n--; } },
		hzT19CapH() { return Math.max(24, 12 + 10); }, hzT19PillCap(lf) { return Math.max(22, lf + 8); },
	};
	const want = ["hzT19Content", "hzT19PromptPill", "hzT19Buttons", "hzT19Label", "hzT19OneLine", "hzT19Trim", "hzT19RowFace", "hzT19WrapN", "hzT19LineAdv", "hz38PromptW", "hz38PromptY"];
	for (const n of want) { try { h[n] = toJs(src, n).bind(h); } catch (e) { if (!/missing/.test(e.message)) throw e; } }
	// optional helpers a newer source may add
	for (const n of (src.match(/private function (hzT19Row\w*|hzT19Full\w*|hzT19Steal\w*|hzT19Pill\w*|hzT19Lbl\w*)\(/g) || []).map((s) => s.replace(/private function |\(/g, ""))) { if (!h[n] || n === "hzT19PillCap") { if (n !== "hzT19PillCap") h[n] = toJs(src, n).bind(h); } }
	const fb = h.hzT19Buttons; h.hzT19Buttons = function () { this.btnCalls++; return fb.apply(this, arguments); };
	for (const m of (src.match(/private static const (HZ_T19_\w+|HZ38_\w+):(?:Number|int) = ([\d.]+);/g) || [])) { const mm = /const (\w+):\w+ = ([\d.]+)/.exec(m); h[mm[1]] = Number(mm[2]); }
	return h;
}
function layout(src, opts) {
	const h = makeHost(src);
	h.hzNameHover = opts.full ? 1 : 0;
	const a = { sHeaderText: opts.header, bStealing: !!opts.steal, aButtons: opts.buttons, uMode: 4 };
	h.hzT19Content("prompt", a, {}, -1, 0);
	const all = h.recs.slice();
	const fields = [h.hzT19Name];
	for (const s of h.hzT19Btn) fields.push(s.kp, s.lp, s.hh, s.kh, s.lh);
	for (const t of fields) { const r = ink(t); if (r) all.push(r); }
	return { h, W: h.hzT19W, H: h.hzT19H, rects: all };
}
function overlaps(L) {
	const bad = [];
	const panel = L.rects.find((r) => r.n === "panel");
	const items = L.rects.filter((r) => r.n !== "panel" && r.n !== "tile");
	for (const r of items) {
		if (r.x < -0.5 || r.y < -0.5 || r.x + r.w > panel.w + 0.5 || r.y + r.h > panel.h + 0.5) bad.push("outside card: " + r.n + " [" + [r.x, r.y, r.w, r.h].map(Math.round) + "] card " + Math.round(panel.w) + "x" + Math.round(panel.h));
	}
	for (let i = 0; i < items.length; i++) for (let j = i + 1; j < items.length; j++) {
		const p = items[i], q = items[j];
		if (p.n === "cap" && /^k[ph]:/.test(q.n) || q.n === "cap" && /^k[ph]:/.test(p.n)) continue;   // the key glyph sits inside its cap
		const ox = Math.min(p.x + p.w, q.x + q.w) - Math.max(p.x, q.x), oy = Math.min(p.y + p.h, q.y + q.h) - Math.max(p.y, q.y);
		if (ox > 0.5 && oy > 0.5) bad.push("overlap: " + p.n + " / " + q.n);
	}
	return bad;
}


const has = (n) => new RegExp("private function " + n + "\\(").test(SRC);
expect(["hzHvdParseIni", "hzHvdSet", "hzHvdContent", "hzHvdLog", "hzT19SkipSet"].every(has), "the HoverDiag helpers exist");

// ---- 1. not shipped ----
for (const f of ["Interface/HorizonUI/HorizonUI.default.ini", "README.md", "fomod/ModuleConfig.xml", "fomod/info.xml"]) {
	const t = fs.readFileSync(path.join(root, f), "utf8");
	expect(!/hoverdiag/i.test(t), f + " does not mention HoverDiag");
}
expect(/private var hzHvd:int = 0;/.test(SRC) && /private var hzHvdOn:Boolean = false;/.test(SRC) && /private var hzHvdT:Boolean = false;/.test(SRC) && /private var hzT19WalkSkip:int = 0;/.test(SRC) && /private var hzT19SkipC:Boolean = false;/.test(SRC), "every HoverDiag state starts off");

// ---- 2. parse, set, preset strip ----
function parseHost() {
	const hh = { hzHvd: 0, hzHvdOn: false, hzHvdT: false, hzT19WalkSkip: 0, hzT19SkipC: false, hzT19Sig: "X", hzPerfOn: false, hzPerfMode: 0, sets: 0 };
	hh.hz30Hdr = function (ln) { const m = /^\s*\[([^\]]+)\]/.exec(ln); return m ? m[1].trim().toLowerCase() : null; };
	for (const n of ["hzHvdParseIni", "hzHvdSet", "hzT19SkipSet", "hzPerfSkipHover", "hzEnvP0NoKey"]) hh[n] = toJs(SRC, n).bind(hh);
	const s0 = hh.hzHvdSet; hh.hzHvdSet = function (v) { this.sets++; return s0(v); };
	return hh;
}
{
	const cases = [
		["", 0], ["[Debug]\nPerfDiag=1\n", 0], ["[Debug]\nHoverDiag=1\n", 1], ["[Debug]\r\nHoverDiag = 33 ; note\r\n", 33],
		["[HUD]\nHoverDiag=4\n", 0], ["[Debug]\nHoverDiag=4\n[Debug]\nHoverDiag=2\n", 2], ["[Debug]\nHoverDiag=abc\n", 0], ["[Debug]\nHoverDiag=64\n", 0], ["[Debug]\n;HoverDiag=8\n", 0],
	];
	for (const [txt, want] of cases) { const hh = parseHost(); hh.hzHvdParseIni(txt); expect(hh.hzHvd === want && hh.hzHvdOn === (want !== 0), "parse " + JSON.stringify(txt) + " -> " + want); }
	const hh = parseHost();
	hh.hzHvdParseIni("[Debug]\nHoverDiag=49\n");
	expect(hh.hzHvdOn && hh.hzHvdT && hh.hzT19WalkSkip === 2 && hh.hzT19SkipC && hh.hzT19Sig === "", "49 = 1 + 16 + 32: bypass, edge-frame walk, timing; the card redraws");
	hh.hzT19Sig = "Y"; hh.hzHvdParseIni("[Debug]\nHoverDiag=49\n");
	expect(hh.hzT19Sig === "Y", "the same value again changes nothing");
	hh.hzHvdParseIni("[Debug]\nPerfDiag=0\n");
	expect(hh.hzHvd === 0 && !hh.hzHvdOn && !hh.hzHvdT && hh.hzT19WalkSkip === 0 && !hh.hzT19SkipC, "the key removed: all off again");
	hh.hzPerfOn = true; hh.hzPerfMode = 1; hh.hzT19SkipSet();
	expect(hh.hzT19SkipC === true, "PerfMode 1 still bypasses through the cached flag");
	hh.hzPerfMode = 0; hh.hzT19SkipSet();
	expect(hh.hzT19SkipC === false, "PerfMode 0 clears it");
	const pre = "[HUD]\nNameHover=1\n[Debug]\nHoverDiag=32\nEnvAlertLog=1\nPerfDiag=1\n[Comms]\nHoverDiag=9\n";
	const out = hh.hzEnvP0NoKey(pre);
	expect(out === "[HUD]\nNameHover=1\n[Debug]\nPerfDiag=1\n[Comms]\nHoverDiag=9\n", "a saved preset drops [Debug] HoverDiag and EnvAlertLog only");
	expect(hh.hzEnvP0NoKey("[HUD]\nNameHover=1\n") === "[HUD]\nNameHover=1\n", "a preset without either key is the same string");
	expect(/hzHvdParseIni\(txt\)/.test(fnText(SRC, "hz37OnApplyTxt").body), "read with EnvAlertLog on INI load and every F11 reload (hz37OnApplyTxt)");
}

// ---- 3. off path: zero extra calls ----
const watch = ["hzPerfNow", "hzWlPush", "hzHvdContent", "hzHvdLog", "hzHvdSet", "hzHvdParseIni", "hzT19SkipSet", "hzPerfSkipHover"];
function wrapCount(hh) {
	hh.extra = {};
	for (const n of watch) { const f = hh[n] || (() => 0); hh[n] = function () { hh.extra[n] = (hh.extra[n] || 0) + 1; return f.apply(this, arguments); }; }
}
const btn = (t, p, extra) => Object.assign({ iType: t, bVisible: true, bEnabled: true, bPressAndRelease: true, bPressAndHold: false, sTextPressAndRelease: p }, extra || {});
const prompt = { header: "First Aid", steal: true, buttons: [btn(0, "Steal From\n[Master]"), btn(1, "Transfer")] };
function draw(nameHover, hv) {
	const hh = makeHost(SRC);
	hh.hzNameHover = nameHover;
	wrapCount(hh);
	hh.hzT19Content("prompt", { sHeaderText: prompt.header, bStealing: true, aButtons: prompt.buttons, uMode: 4 }, {}, -1, 0, hv);
	return hh;
}
for (const nh of [1, 0]) {
	const hh = draw(nh, undefined);
	expect(Object.keys(hh.extra).length === 0, (nh ? "FULL" : "COMPACT") + " off: the content draw calls no timer, log or HoverDiag helper (" + JSON.stringify(hh.extra) + ")");
	expect(hh.btnCalls === (nh ? 2 : 3), (nh ? "FULL" : "COMPACT") + " off: keycap layout passes " + hh.btnCalls + " (unchanged)");
}
{
	// the content edge in hzT19Tick: one cached Boolean, and the plain call when off
	const tick = fnText(SRC, "hzT19Tick").body;
	expect(tick.indexOf("if(this.hzHvdOn) { this.hzHvdContent(kind,show ? a : null,aw,sel,start); }") >= 0 && tick.indexOf("else { this.hzT19Content(kind,show ? a : null,aw,sel,start); }") >= 0, "content edge: one cached Boolean, then the unchanged call");
	expect(tick.indexOf("if(this.hzT19SkipC)") >= 0 && tick.indexOf("hzPerfSkipHover()") < 0, "per frame: the bypass is a cached Boolean (was a call to hzPerfSkipHover)");
	const callers = (SRC.match(/this\.hzPerfSkipHover\(\)/g) || []).length;
	expect(callers === 1 && /this\.hzPerfSkipHover\(\)/.test(fnText(SRC, "hzT19SkipSet").body), "hzPerfSkipHover runs only from hzT19SkipSet (an edge)");
	expect(/this\.hzT19SkipSet\(\);/.test(fnText(SRC, "hzPerfApply").body), "PerfDiag / PerfMode changes refresh the cached flag (hzPerfApply)");
}
// the hide walk with HoverDiag off and on, on a recording host
function walkHost(hvdT) {
	const calls = {};
	const base = {
		hzHvdT: hvdT, hzHvd: hvdT ? 32 : 0, hzNameHover: 0, hzWlOn: true, hzFrameN: 7, hzT19EdgeN: 2, hzObjRing: 2, hzT19HcBtn: null, nowV: 100,
		hzT19HcOk() { return false; }, hzT19HoldBtns() { return [null, null, null, null]; }, hzT19OnHoldPathA() { return false; },
		hzPerfNow() { this.nowV += 2; return this.nowV; },
	};
	const hh = new Proxy(base, { get(t, p) { if (p in t) { const v = t[p]; if (typeof v === "function" && /^hz/.test(String(p))) return function () { calls[p] = (calls[p] || 0) + 1; return v.apply(hh, arguments); }; return v; } if (/^hz/.test(String(p))) return function () { calls[p] = (calls[p] || 0) + 1; }; return undefined; }, set(t, p, v) { t[p] = v; return true; } });
	base.hzHvdLog = toJs(SRC, "hzHvdLog");
	base.hzWlPush = function (s) { (base.lines = base.lines || []).push(s); };
	const fn = toJs(SRC, "hz38HideVanilla");
	fn.call(hh, { RolloverActivationHolder_mc: null }, { isAw: true }, "prompt");
	return { calls, base };
}
{
	const off = walkHost(false);
	expect(!off.calls.hzPerfNow && !off.calls.hzHvdLog && !off.calls.hzWlPush && off.calls.hzT19HidePromptTree === 1, "hide walk off: the walk runs, with no timer read and no log (" + JSON.stringify(off.calls) + ")");
	const on = walkHost(true);
	expect(on.calls.hzPerfNow === 2 && on.calls.hzHvdLog === 1 && on.base.lines && /^HVD b t=\d+ f=7 ms=2 kind=prompt size=COMPACT bits=32 edgeN=2$/.test(on.base.lines[0]), "hide walk with 32: one timed line (" + (on.base.lines || []).join(" | ") + ")");
}

// ---- 4. each bit ----
{
	const f2 = draw(0, 2);
	expect(f2.hzT19H > 100 && f2.btnCalls === 2 && Object.keys(f2.extra).length === 0, "2 forces FULL over NameHover=0 (H " + f2.hzT19H + ", passes " + f2.btnCalls + ")");
	const f4 = draw(1, 4);
	expect(f4.hzT19H < 100 && f4.btnCalls === 3, "4 forces COMPACT over NameHover=1 (H " + f4.hzT19H + ", passes " + f4.btnCalls + ")");
	const f6 = draw(0, 6);
	expect(f6.hzT19H > 100, "2 wins over 4");
	const p0 = draw(0, undefined), p8 = draw(0, 8);
	expect(p8.btnCalls === 2 && p8.hzT19W === p0.hzT19W && p8.hzT19H === p0.hzT19H, "8 skips the full-size pass; the pill is the same size (" + p8.hzT19W + "x" + p8.hzT19H + ")");
	const n8 = draw(0, 8); const noBtn = makeHost(SRC); noBtn.hzT19Content("prompt", { sHeaderText: "Door", aButtons: [], uMode: 4 }, {}, -1, 0, 8);
	expect(noBtn.hzT19W > 0 && noBtn.btnCalls === 1, "8 with no buttons still draws (the pill measure finds none)");
	expect(draw(1, 8).btnCalls === 2, "8 leaves the FULL card alone");
	// 16: walk frames per edge
	function edges(walkSkip) {
		const hh = { hzFrameN: 0, hzT19EdgeN: 3, hzT19EdAw: null, hzT19EdShow: false, hzT19EdM: 0, hzVehPad: false, hzT19EdPad: false, hzT19EdF: -5, hzT19EdDecF: -1, hzT19WalkSkip: walkSkip, hzT19LblDue: false, hzT19HcDue: false };
		const fn = toJs(SRC, "hzT19Edge").bind(hh);
		const aw = {}; let walk = 0, lbl = 0;
		for (let f = 1; f <= 6; f++) { hh.hzFrameN = f; fn(aw, true, 4, false); if (hh.hzT19HcDue) walk++; if (hh.hzT19LblDue) lbl++; }
		return { walk, lbl };
	}
	const e0 = edges(0), e16 = edges(2);
	expect(e0.walk === 3 && e0.lbl === 3, "off: the hide walk and the label re-read run on the edge frame and the 2 after it");
	expect(e16.walk === 1 && e16.lbl === 3, "16: the hide walk runs on the edge frame only; the label re-read keeps 3 frames");
	// 32: content timing
	const hh = makeHost(SRC);
	hh.hzHvd = 32; hh.hzHvdT = true; hh.hzWlOn = true; hh.hzFrameN = 3; hh.nowV = 10; hh.lines = [];
	hh.hzPerfNow = function () { this.nowV += 5; return this.nowV; };
	hh.hzWlPush = function (s) { this.lines.push(s); };
	hh.hzHvdLog = toJs(SRC, "hzHvdLog").bind(hh);
	toJs(SRC, "hzHvdContent").call(hh, "prompt", { sHeaderText: "First Aid", aButtons: prompt.buttons, uMode: 4 }, {}, -1, 0);
	expect(hh.lines.length === 1 && /^HVD a t=15 f=3 ms=5 kind=prompt size=COMPACT bits=32$/.test(hh.lines[0]), "32: one content line per edge (" + hh.lines[0] + ")");
	hh.lines = []; hh.hzWlOn = false;
	toJs(SRC, "hzHvdContent").call(hh, "prompt", { sHeaderText: "First Aid", aButtons: prompt.buttons, uMode: 4 }, {}, -1, 0);
	expect(hh.lines.length === 0, "32 without the watchlog: nothing queued");
	hh.hzHvdT = false; hh.hzHvd = 4; const n0 = hh.nowV;
	toJs(SRC, "hzHvdContent").call(hh, "prompt", { sHeaderText: "First Aid", aButtons: prompt.buttons, uMode: 4 }, {}, -1, 0);
	expect(hh.nowV === n0, "without 32: no timer read");
	// 1: bypass on the cached flag
	const tick = fnText(SRC, "hzT19Tick").body;
	const i1 = tick.indexOf("if(this.hzT19SkipC)");
	expect(i1 > 0 && /this\.hzT19Off\(\);/.test(tick.slice(i1, i1 + 400)) && /return;/.test(tick.slice(i1, i1 + 450)), "1: the tick hands the prompt back to the game (hzT19Off) and returns");
	const ps = parseHost(); ps.hzHvdParseIni("[Debug]\nHoverDiag=1\n");
	expect(ps.hzT19SkipC === true && ps.hzHvdOn === true, "1 sets the cached bypass");
}
// no timer, listener or per-frame work in the new helpers
{
	const all = ["hzHvdParseIni", "hzHvdSet", "hzHvdContent", "hzHvdLog", "hzT19SkipSet"].map((n) => fnText(SRC, n).body).join("\n");
	expect(!/addEventListener|ENTER_FRAME|new Timer|setTimeout|setInterval|getBounds/.test(all), "the HoverDiag helpers add no timer, listener or bounds read");
}
console.log("hover diag: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
