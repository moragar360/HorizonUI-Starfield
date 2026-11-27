// List-card STEAL chip (container loot card, kind == "list"). Prompt-card tests (hover_steal_row_test.js) do not
// cover this path: the chip sits on the title row next to a fixed 140-wide ITEMS field.
// Run: node tests/hover_steal_list_test.js
// Proves: STEAL never overlaps the title or the ITEMS count; room math uses the 140 slot, not the painted "N ITEMS"
// width; layout runs only from hzT19Content (content-change), not per frame.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const SRC = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
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
function ink(t) {
	if (!t.visible || t._t.length === 0) return null;
	const lines = wrapLines(t, t._t);
	const lh = t.fs * 1.25;
	const shown = Math.max(1, Math.min(lines.length, Math.floor((t.height - 4) / lh) || 1));
	const w = Math.min(Math.max(...lines.slice(0, shown).map((l) => lineW(t, l))), t.width - 4);
	return { n: t.name + ":" + t._t, x: t.x + 2, y: t.y + 2 + t.fs * 0.15, w, h: shown * lh - t.fs * 0.3 };
}
function overlaps(a, b) {
	const ox = Math.min(a.x + a.w, b.x + b.w) - Math.max(a.x, b.x);
	const oy = Math.min(a.y + a.h, b.y + b.h) - Math.max(a.y, b.y);
	return ox > 0.5 && oy > 0.5;
}
function makeHost() {
	const recs = [];
	const g = { calls: [] };
	for (const m of ["clear", "beginFill", "endFill", "lineStyle", "drawRect", "drawCircle", "moveTo", "lineTo", "drawRoundRect"]) g[m] = function () { this.calls.push([m, ...arguments]); };
	const objs = new Map();
	const rows = [];
	for (let i = 0; i < 5; i++) rows.push({ n: mkTf("rn" + i, 200, 13, 0.4), c: mkTf("rc" + i, 40, 12, 0), t: mkTf("rt" + i, 80, 10, 0.4) });
	const slots = [];
	for (let i = 0; i < 4; i++) slots.push({ kp: mkTf("kp", 60, 12, 0), lp: mkTf("lp", 160, 13, 1.6), hh: mkTf("hh", 60, 11, 1.2), kh: mkTf("kh", 60, 12, 0), lh: mkTf("lh", 160, 13, 1.6) });
	const h = {
		recs, g,
		HZ_ACCENT: 0x6FD3FF, HZ_RED: 0xFF5B5B, HZ_AMB: 0xF2A93B, HZ_GREEN: 0x5EE3A1,
		HZ38_PR_PAD: 20, HZ38_PR_MINW: 310, HZ38_PR_MAXW: 480, HZ_T19_NMLINES: 3, HZ_T19_LBLW: 480,
		HZ_RAR: [0xD6DEE4, 0x5EE3A1, 0x4DB6FF, 0xB48CFF, 0xF2A93B],
		hzT19Btn: slots, hzNameHover: 1, hzTextScale: 1, hzT19BarOn: false, hzT19BarG: null, hzT19Kov: null,
		hzT19G: { graphics: g }, hzT19Rows: rows, hzT19Cmp: [], hzTg19: { numChildren: 0 },
		hzT19Name: mkTf("name", 300, 16, 2), hzT19Meta: mkTf("meta", 180, 13, 0.5), hzT19Ch1: mkTf("ch1", 140, 10, 1.4), hzT19Ch2: mkTf("ch2", 140, 10, 1.4), hzT19Ch3: mkTf("ch3", 140, 10, 1.4),
		hzT19HdrR: mkTf("hdrR", 140, 12, 1.4), hzT19Foot: mkTf("foot", 200, 12, 0.3), hzT19FootR: mkTf("footR", 180, 12, 0.5),
		hzTgItems: [], hzTgShowValue: false, hzT19RowsH: 32, hzT19W: 0, hzT19H: 0,
		hzDarkText() { return false; }, hzIconCol(c) { return c; }, hzMix(a) { return a; }, hzPanelFill() { return 0; }, hzLight() { return false; },
		hzT19PaintFoeBars() { }, hzT19Key() { return "E"; }, hzT19VanLbl() { return ""; }, hzT19Xl(s) { return s; }, hzUC(s) { return String(s).toUpperCase(); },
		hzT19U() { return 1; }, hzSnapU(v) { return Math.round(v); }, hzChipSzOn(f) { return f; }, hzT19KeyOv() { return null; },
		hzT19Line() { }, hzAccStripe() { }, hzT19Face() { }, hzRarCol() { return 0xD6DEE4; }, hzMainCol() { return 0xF2F7F9; },
		hzTxtObj(t) { if (!objs.has(t)) objs.set(t, { tf: t, fs: t.fs, size: t.fs, ls: t.ls }); return objs.get(t); },
		hzApplyFmt(o) { if (o && o.tf) { o.tf.fs = Number(o.fs) || o.tf.fs; const nl = o.lines > 1 ? o.lines : 1; o.tf.height = (o.tf.fs + 5) * nl + 6; } },
		hzT19FaceFs(t, f) { const o = this.hzTxtObj(t); o.fs = f; o.size = f; t.fs = f; },
		hzTW(t) { return t.textWidth; },
		hzTxtTint() { }, hzTxtTopU(t, top) { t.y = Math.round(top); }, hzTxtTop(t, top) { t.y = Math.round(top); },
		hzPanel(gg, w, hh) { recs.push({ n: "panel", x: 0, y: 0, w, h: hh }); this.hzT19W = w; this.hzT19H = hh; },
		hzT19Tile() { }, hzFitText(t, full, maxW) { t.text = full; if (this.hzTW(t) <= maxW - 4 || full.length < 2) return; let n = full.length; while (n > 1) { t.text = full.substr(0, n) + "..."; if (this.hzTW(t) <= maxW - 4) return; n--; } },
		hzT19CapH() { return 32; }, hzT19PillCap() { return 22; },
		hzT19Buttons() { return 80; },
	};
	for (const m of (SRC.match(/private static const (HZ_T19_\w+|HZ38_\w+):(?:Number|int) = ([\d.]+);/g) || [])) { const mm = /const (\w+):\w+ = ([\d.]+)/.exec(m); h[mm[1]] = Number(mm[2]); }
	h.hzChip = toJs(SRC, "hzChip").bind(h);
	h.hzT19Content = toJs(SRC, "hzT19Content").bind(h);
	const chip = h.hzChip;
	h.hzChip = function (gg, tf, x, y, txt, col, solid) {
		const w = chip(gg, tf, x, y, txt, col, solid);
		recs.push({ n: "chip:" + txt, x: x, y: y, w: w, h: 15 });
		return w;
	};
	return h;
}
function layout(opts) {
	const h = makeHost();
	h.hzTgItems = opts.items || [{ sName: "Med Pack", uCount: 1, uRarity: 0 }];
	const a = { sHeaderText: opts.header, bStealing: !!opts.steal, aButtons: opts.buttons || [], uMode: 4, bShowRolloverActivation: true };
	h.hzT19Content("list", a, {}, 0, 0);
	return h;
}

{
	const body = fnText(SRC, "hzT19Content").body;
	const list = body.slice(body.indexOf('else if(kind == "list")'));
	expect(/var itemsSlot:Number = 140;/.test(list) && /this\.hzT19HdrR\.width = itemsSlot;/.test(list) && /this\.hzT19HdrR\.x = W - 14 - itemsSlot;/.test(list), "list card: ITEMS sits in a fixed 140-wide field");
	expect(/hroom/.test(list) && /steal \? stw \+ 10/.test(list) && /nmTf\.width = hroom/.test(list), "list card: title room subtracts the measured STEAL chip from the 140 slot, not the painted ITEMS width");
	expect(/stx \+ stw > this\.hzT19HdrR\.x - 4/.test(list), "list card: STEAL is clamped left of the ITEMS slot");
	const tick = fnText(SRC, "hzT19Tick").body;
	expect(/if\(sig != this\.hzT19Sig\)/.test(tick) && tick.indexOf("hzT19Content") > tick.indexOf("if(sig != this.hzT19Sig)"), "list layout runs only on a content-signature change, not every frame");
}

const cases = [
	{ name: "Akila first-aid kit", header: "First Aid", steal: true, items: [{ sName: "Med Pack", uCount: 2, uRarity: 0 }] },
	{ name: "short owned box", header: "Crate", steal: true, items: [{ sName: "Credits", uCount: 1, uRarity: 0 }] },
	{ name: "long title + STEAL", header: "Akila City Security Evidence Locker Storage", steal: true, items: [{ sName: "Digestive Enzyme", uCount: 1, uRarity: 0 }, { sName: "Trauma Pack", uCount: 3, uRarity: 1 }] },
	{ name: "many items (ITEMS field still 140)", header: "Cabinet", steal: true, items: Array.from({ length: 12 }, (_, i) => ({ sName: "Item " + i, uCount: 1, uRarity: 0 })) },
	{ name: "no STEAL", header: "First Aid", steal: false, items: [{ sName: "Med Pack", uCount: 1, uRarity: 0 }] },
];
for (const c of cases) {
	const h = layout(c);
	const title = ink(h.hzT19Name);
	const items = ink(h.hzT19HdrR);
	const chip = h.recs.find((r) => r.n === "chip:STEAL");
	expect(!!title && !!items, c.name + ": title and ITEMS painted");
	expect(h.hzT19HdrR.width === 140, c.name + ": ITEMS field width is 140 (was the painted string)");
	expect(h.hzT19HdrR.x === h.hzT19W - 14 - 140, c.name + ": ITEMS slot starts at W-14-140");
	if (c.steal) {
		expect(!!chip && h.hzT19Ch2.visible && h.hzT19Ch2._t === "STEAL", c.name + ": STEAL chip is on");
		expect(!overlaps(title, chip), c.name + ": STEAL does not overlap the title");
		expect(!overlaps(chip, items), c.name + ": STEAL does not overlap ITEMS");
		expect(!overlaps(title, items), c.name + ": title does not overlap ITEMS");
		expect(chip.x + chip.w <= h.hzT19HdrR.x - 3.5, c.name + ": STEAL stays left of the ITEMS slot");
		expect(title.x + title.w <= chip.x + 0.5, c.name + ": title stays left of STEAL");
	} else {
		expect(!chip && !h.hzT19Ch2.visible, c.name + ": no STEAL chip when not stealing");
		expect(!overlaps(title, items), c.name + ": title does not overlap ITEMS");
	}
}

console.log("hover steal list: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
