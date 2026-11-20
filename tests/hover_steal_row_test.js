// 0.43.4 item 2 tests: the steal / lock-difficulty keycap label (for example "STEAL FROM [MASTER]") never overlaps
// another keycap or label, on BOTH hover card sizes: the FULL card ([HUD] NameHover=1) and the COMPACT pill (0).
// Run: node tests/hover_steal_row_test.js   (HZ_HOVER_SRC=<file> runs it on another horizon_block.as, the
// mutation check: on the 0.43.3.2 source it must fail.)
// Runs the production hzT19Content / hzT19PromptPill / hzT19Buttons / hzT19LblLong (types stripped) on a host whose
// text fields clip at their width and height, under two text metrics: exact, and "lsMissing" (the measured width
// leaves letterSpacing out while the painted text keeps it, the mechanism that lets a long label paint past the
// width the row reserved for it). The fix puts a long label on its own keycap row at the same font size; rows and
// card height grow. Author: Moragar. Last modified: 2026-11-20.
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
		hzT19PaintFoeBars() { }, hzT19Key() { return "E"; }, hzT19VanLbl() { return ""; }, hzT19Xl(s) { return s; }, hzUC(s) { return String(s).toUpperCase(); },
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

const btn = (t, p, extra) => Object.assign({ iType: t, bVisible: true, bEnabled: true, bPressAndRelease: true, bPressAndHold: false, sTextPressAndRelease: p }, extra || {});
const cases = {
	steal_only: { header: "First Aid", steal: true, buttons: [btn(0, "Steal From\n[Master]")] },
	steal_transfer: { header: "First Aid", steal: true, buttons: [btn(0, "Steal From\n[Master]"), btn(1, "Transfer")] },
	transfer_steal: { header: "First Aid", steal: true, buttons: [btn(1, "Transfer"), btn(0, "Steal From\n[Master]")] },
	steal_hold: { header: "First Aid", steal: true, buttons: [btn(0, "Steal From\n[Master]", { bPressAndHold: true, sTextHold: "Unlock\n[Master]" })] },
	lock_open: { header: "Storage Locker", steal: false, buttons: [btn(0, "Unlock\n[Advanced]"), btn(1, "Open")] },
	three: { header: "Medical Supplies Cabinet", steal: true, buttons: [btn(0, "Steal From\n[Master]"), btn(1, "Transfer"), btn(2, "Unlock\n[Master]")] },
	long_name: { header: "Akila City Security Evidence Locker Storage", steal: true, buttons: [btn(0, "Steal From\n[Master]"), btn(1, "Transfer")] },
};
const plain = { header: "First Aid", steal: false, buttons: [btn(0, "Take"), btn(1, "Transfer")] };
for (const lsMissing of [false, true]) {
	METRIC.lsMissing = lsMissing;
	const mt = lsMissing ? "lsMissing" : "exact";
	for (const full of [true, false]) {
		const size = full ? "FULL" : "COMPACT";
		const one = layout(SRC, Object.assign({ full }, plain));
		for (const k of Object.keys(cases)) {
			const L = layout(SRC, Object.assign({ full }, cases[k]));
			const bad = overlaps(L);
			expect(bad.length === 0, size + " " + k + " (" + mt + "): no overlap, all inside the card" + (bad.length ? " -- " + bad.join("; ") : ""));
			const labels = [];
			for (const s of L.h.hzT19Btn) for (const t of [s.lp, s.lh]) if (t.visible && t._t.length) labels.push(t);
			const whole = labels.every((t) => !/\.\.\.$/.test(t._t) && lineW(t, t._t) <= t.width - 4);
			expect(labels.length > 0 && whole, size + " " + k + " (" + mt + "): every label whole (not cut, no ...)");
			const wantFs = full ? 13 : 14;
			expect(labels.every((t) => t.fs === wantFs), size + " " + k + " (" + mt + "): label font size unchanged (" + wantFs + ")");
			if (cases[k].buttons.length > 1 || cases[k].buttons[0].bPressAndHold) expect(L.H > one.H, size + " " + k + " (" + mt + "): the card grows for the extra row (" + Math.round(one.H) + " -> " + Math.round(L.H) + ")");
		}
		expect(one.h.hzT19RowsN === 1, size + " short labels: one keycap row, layout unchanged");
	}
}
METRIC.lsMissing = false;
// the plain one-row card keeps its 0.43.3.2 height
expect(layout(SRC, Object.assign({ full: true }, plain)).H === layout(SRC, Object.assign({ full: true }, plain)).h.hzT19H, "FULL plain card height is the stored hzT19H");
// every draw and the measure ask for the own-row layout
const content = fnText(SRC, "hzT19Content").body + fnText(SRC, "hzT19PromptPill").body;
const calls = content.split("\n").filter((l) => /this\.hzT19Buttons\(/.test(l));
expect(calls.length >= 7 && calls.every((l) => /this\.hzT19Buttons\([^;]*,true\)/.test(l.replace(/\s/g, ""))), "all " + calls.length + " hzT19Buttons calls of the hover card pass ownRow");
expect(!/hzT19CapH\(\)/.test(fnText(SRC, "hzT19Content").body), "card heights use the measured rows (hzT19RowsH), not one cap height");
console.log("hover steal row: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
