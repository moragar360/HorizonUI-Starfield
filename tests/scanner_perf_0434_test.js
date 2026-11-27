// 0.43.4 scanner performance tests (hzs_block.as and both MonocleMenu.as copies).
//  1. the block is spliced unchanged into both scanner hosts, and every hzs member the block uses is declared
//  2. text pool (hzsT / hzsTPBegin / hzsTPEnd): a reused field draws exactly like a new one, no field is made
//     when nothing changed, child order = call order, unused slots dropped; fuzzed against the 3ee48a4 hzsT
//  3. "..." shortening (hzsTrunc): the same text as the 3ee48a4 one-character loop on a corpus and width models
//  4. world markers: move-only frames make no text field and redraw no slot (sprites move). Compass and reticle /
//     range / tag still match the 3ee48a4 bodies. Undiscovered markers use a brighter POI tone and a dark backing
//     (look change vs 3ee48a4; identity is not required for that path).
//  5. the 6-frame poll skips the event-only planet / bioscan cards; events and the frequent env data still redraw them
//  6. settings: the open frame no longer reads the files again right after the start read
//  7. Social card (review M-1): a bounty with a key prompt draws as in 3ee48a4 on an empty card and on a card that
//     already had fields (the key is measured on a throwaway sprite, never added to and removed from the card)
// Old bodies come from git (tests/lib/git_base.js: SKIP in a source zip without git, HZ_REQUIRE_GIT=1 makes it a FAIL).
// Author: Moragar. Last modified: 2026-11-27.
"use strict";

const fs = require("fs");
const path = require("path");
const { root, stripComments, fnText, toJs: toJs0 } = require("./lib/r3.js");
// r3.toJs drops casts like Sprite(x); keep "new Sprite()" / "new TextField()" intact
const toJs = (b) => toJs0(b.replace(/for each\(var (\w+):String in String\(([\w.]+)\)\.split\(","\)\)/g, 'for (var $1 of String($2).split(","))').replace(/new (Sprite|TextField|MovieClip)\(/g, "new $1__(")).replace(/new (Sprite|TextField|MovieClip)__\(/g, "new $1(");
const { readBase, report } = require("./lib/git_base.js");

const BASE = "3ee48a4";
let failed = 0, passed = 0;
function expect(cond, msg) { if (cond) { passed++; console.log("ok  " + msg); } else { failed++; console.error("FAIL " + msg); } }

const rd = (f) => fs.readFileSync(path.join(root, f), "utf8").replace(/\r\n/g, "\n");
const BLOCK = rd("actionscript/scanner/hzs_block.as");
const HOSTS = [["actionscript/imp/simp_monoclemenu/MonocleMenu.as", "false"], ["actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as", "true"]];
const AS = stripComments(BLOCK);
const oldRes = readBase(root, BASE, "actionscript/scanner/hzs_block.as");
report(oldRes, BASE, "scanner block", expect);
const OLD = oldRes.src != null ? stripComments(oldRes.src) : null;

// ---------------------------------------------------------------- 1. splice + declarations
for (const [f, lrg] of HOSTS) {
	const host = rd(f);
	const want = BLOCK.replace(/__HZS_LRG__/g, lrg);
	expect(host.indexOf(want.replace(/\n$/, "")) >= 0, path.basename(path.dirname(f)) + ": the scanner block is spliced unchanged (HZS_LRG = " + lrg + ")");
	expect(fs.readFileSync(path.join(root, f), "utf8").indexOf("\r\n") >= 0, path.basename(path.dirname(f)) + ": the host keeps its CRLF line ends");
	// the movie is made again for every open: the game never sets isMenuClosing back (why the open frame need not re-read)
	expect((host.match(/isMenuClosing\s*=\s*false/g) || []).length === 0 && /private var isMenuClosing:Boolean = false;/.test(host), path.basename(path.dirname(f)) + ": isMenuClosing is only ever set to true (a closed scanner movie is not reused)");
}
{
	const host = stripComments(rd(HOSTS[0][0]));
	const decl = new Set();
	for (const m of host.matchAll(/(?:var|const|function)\s+(hzs\w+)/g)) decl.add(m[1]);
	for (const m of host.matchAll(/function\s+get\s+(\w+)/g)) decl.add(m[1]);
	const used = new Set();
	for (const m of AS.matchAll(/this\.(hzs\w+)/g)) used.add(m[1]);
	const missing = [...used].filter((n) => !decl.has(n));
	expect(missing.length === 0, "every this.hzs* the block uses is declared in the host (" + (missing.join(", ") || "none missing") + ")");
	const bare = [...AS.matchAll(/[^.\w](HZS_\w+)/g)].map((m) => m[1]).filter((n) => !new RegExp("const " + n + "\\b").test(AS));
	expect(bare.length === 0, "every HZS_ constant the block uses is declared (" + ([...new Set(bare)].join(", ") || "none missing") + ")");
}

// ---------------------------------------------------------------- mock display list
let made = 0;
class Gfx {
	constructor() { this.ops = []; this.clears = 0; }
	clear() { this.ops = []; this.clears++; }
	lineStyle(...a) { this.ops.push(["ls", ...a]); }
	beginFill(...a) { this.ops.push(["bf", ...a]); }
	endFill() { this.ops.push(["ef"]); }
	moveTo(x, y) { this.ops.push(["mt", x, y]); }
	lineTo(x, y) { this.ops.push(["lt", x, y]); }
	drawCircle(x, y, r) { this.ops.push(["dc", x, y, r]); }
	drawRoundRect(x, y, w, h, a, b) { this.ops.push(["rr", x, y, w, h, a, b]); }
	drawRect(x, y, w, h) { this.ops.push(["rr", x, y, w, h, 0, 0]); }
}
let nid = 0;
class DO { constructor() { this.x = 0; this.y = 0; this.alpha = 1; this.visible = true; this.scaleX = 1; this.scaleY = 1; this.name = "instance" + (++nid); this.parent = null; this.mouseEnabled = true; this.mouseChildren = true; } }
class Sprite extends DO {
	constructor() { super(); this.kids = []; this.graphics = new Gfx(); }
	get numChildren() { return this.kids.length; }
	addChild(c) { if (c.parent) c.parent.kids.splice(c.parent.kids.indexOf(c), 1); this.kids.push(c); c.parent = this; return c; }
	addChildAt(c, i) { if (i < 0 || i > this.kids.length) throw new RangeError("Error #2006"); if (c.parent) c.parent.kids.splice(c.parent.kids.indexOf(c), 1); this.kids.splice(i, 0, c); c.parent = this; return c; }
	removeChildAt(i) { if (i < 0 || i >= this.kids.length) throw new RangeError("Error #2006"); const c = this.kids.splice(i, 1)[0]; if (c) c.parent = null; return c; }
	getChildAt(i) { if (i < 0 || i >= this.kids.length) throw new RangeError("Error #2006"); return this.kids[i]; }
	removeChild(c) { const i = this.kids.indexOf(c); if (i < 0) throw new Error("Error #2025"); this.kids.splice(i, 1); c.parent = null; return c; }
	setChildIndex(c, i) { const j = this.kids.indexOf(c); if (j < 0) throw new Error("Error #2025"); if (i < 0 || i >= this.kids.length) throw new RangeError("Error #2006"); this.kids.splice(j, 1); this.kids.splice(i, 0, c); }
}
// a width model: per character advance by face weight, size and tracking, plus a small pair kerning (never net negative)
let WIDTH = (t) => {
	const f = t.fmt || {}; const sz = Number(f.size) || 12; let w = 0;
	for (let i = 0; i < t._text.length; i++) {
		const ch = t._text[i]; const c = ch.charCodeAt(0);
		let a = ch === " " ? 0.28 : ch === "." ? 0.25 : /[MW]/.test(ch) ? 0.9 : /[il1]/.test(ch) ? 0.3 : 0.55 + (c % 7) * 0.02;
		if (i > 0 && t._text[i - 1] === "A" && ch === "V") a -= 0.08;
		w += a * sz * (String(f.font).indexOf("Bold") >= 0 ? 1.06 : 1) + (Number(f.letterSpacing) || 0);
	}
	return Math.round(w * 100) / 100;
};
class TextField extends DO {
	constructor() { super(); made++; this.__tf = true; this._text = ""; this.fmt = null; this.defaultTextFormat = null; this.layouts = 0; }
	get text() { return this._text; }
	set text(v) { this._text = String(v); this.fmt = this.defaultTextFormat ? Object.assign({}, this.defaultTextFormat) : null; this.layouts++; }
	setTextFormat(f) { this.fmt = Object.assign({}, f); this.layouts++; }
	get textWidth() { return WIDTH(this); }
	get height() { return Math.round(((this.fmt && Number(this.fmt.size)) || 12) * 1.25 + 4); }
}
function TextFormat(font, size, color) { this.font = font; this.size = size; this.color = color; this.letterSpacing = 0; }
function Point(x, y) { this.x = x; this.y = y; }

// the drawn result of a container: every visible shape and text at its screen spot, in draw order
const R6 = (v) => (typeof v === "number" ? Math.round(v * 1e6) / 1e6 : v);
function flat(d, out, ox, oy, sx, sy) {
	out = out || []; ox = ox || 0; oy = oy || 0; sx = sx || 1; sy = sy || 1;
	if (!d.visible) return out;
	const X = ox + sx * d.x, Y = oy + sy * d.y, SX = sx * d.scaleX, SY = sy * d.scaleY;
	if (d.__tf) { out.push(["t", R6(X), R6(Y), R6(SX), d._text, JSON.stringify(d.fmt), R6(d.alpha)]); return out; }
	for (const op of d.graphics.ops) {
		const o = op.slice();
		if (o[0] === "mt" || o[0] === "lt") { o[1] = X + SX * o[1]; o[2] = Y + SY * o[2]; }
		else if (o[0] === "dc") { o[1] = X + SX * o[1]; o[2] = Y + SY * o[2]; o[3] = SX * o[3]; }
		else if (o[0] === "rr") { o[1] = X + SX * o[1]; o[2] = Y + SY * o[2]; o[3] *= SX; o[4] *= SY; o[5] *= SX; o[6] *= SY; }
		else if (o[0] === "icon") { o[2] = X + SX * o[2]; o[3] = Y + SY * o[3]; o[6] = SX * o[6]; }
		else if (o[0] === "card") { o.push(R6(X), R6(Y), R6(SX)); }
		out.push(o.map(R6));
	}
	for (const k of d.kids) flat(k, out, X, Y, SX, SY);
	return out;
}
const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);

// AS -> JS with default arguments (r3.toJs does the body)
function argList(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => { const n = a.trim().split(":")[0].trim(); const d = a.indexOf("=") >= 0 ? a.slice(a.indexOf("=") + 1).trim() : null; return d != null ? n + " = " + d : n; });
}
const CONST = { HZS_SCALE: 1, HZS_MINPX: 13, HZS_WHITE: 0xFFFFFF, HZS_LABEL: 0xC4D2D9, HZS_MUTED: 0x96A6AE, HZS_AMB: 0xF2A93B, HZS_RED: 0xFF5B5B, HZS_O2B: 0x4DB6FF, HZS_VIO: 0xB48CFF, HZS_BG: 0x0B1218, HZS_R_STRIP: 14, HZS_QST: 0xFFD25E, HZS_REREAD_MS: 3000 };
// the block's own plain number constants (sizes, radii, colors) fill in any the list above does not set
for (const m of AS.matchAll(/private static const (HZS_\w+):(?:Number|uint|int) = (0x[0-9A-Fa-f]+|-?[0-9.]+);/g)) if (!(m[1] in CONST)) CONST[m[1]] = Number(m[2]);
function host(src, names, extra) {
	const G = Object.assign({ Sprite, TextField, TextFormat, Point, TextFieldAutoSize: { LEFT: "left" }, Math, String, Number, isNaN: (v) => Number.isNaN(Number(v)), int: (v) => Number(v) | 0, uint: (v) => Number(v) >>> 0,
		hzVals: (o) => (o == null ? [] : Array.isArray(o) ? o.slice() : Object.keys(o).map((k) => o[k])), isTf: (o) => !!(o && o.__tf), stage: { stageWidth: 1920, stageHeight: 1080 }, getTimer: () => 0 }, CONST);
	const h = Object.assign({ hzsS: { TextScale: 1 }, hzsTk: 1, hzsFontLib: 1, hzsCfgRev: 1, hzsVrRev: 1, hzsTPc: null, hzsTPi: 0, hzsTPMade: 0, hzsTPNew: 0,
		hzsFace: (w) => "$Horizon_Font" + (w === "bd" ? "_Bold" : w === "rg" ? "_Regular" : ""),
		hzsAccent: () => 0x3FD0E0, hzsOpacity: () => 0.8, hzsCs: (s) => String(s).toUpperCase(), hzsPlace() { this.places = (this.places || 0) + 1; },
		hzsIcon: (g, kind, cx, cy, col, k) => { g.ops.push(["icon", kind, cx, cy, col, k === undefined ? 1 : k, 10]); },
		hzsCard: (g, w, h2, r, stripe, ring, ringA) => { g.ops.push(["card", w, h2, r, stripe, ring === undefined ? 0xFFFFFF : ring, ringA === undefined ? 0.1 : ringA]); },
		hzsRR: (g, x, y, w, h2, r, col, a) => { g.ops.push(["rr", x, y, w, h2, r * 2, r * 2], ["fillc", col, a]); },
		hzsSz: {} }, extra || {});
	const wrap = new Proxy(h, { get(t, k) { if (k in t) return t[k]; if (k in G) return G[k]; return undefined; }, has(t, k) { return typeof k === "string" && (k in t || k in G); }, set(t, k, v) { t[k] = v; return true; } });
	for (const n of names) {
		const f = fnText(src, n);
		if (!f) throw new Error("missing " + n);
		h[n] = Function.apply(null, argList(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	h.__w = wrap;
	return h;
}
const NEW_T = ["hzsT", "hzsTFmt", "hzsTNew", "hzsTSet", "hzsTrunc", "hzsTPBegin", "hzsTPEnd", "hzsClr", "hzsFs", "hzsTw", "hzsSer"];
const OLD_T = ["hzsT", "hzsClr", "hzsFs", "hzsTw", "hzsSer"];

// ---------------------------------------------------------------- 2. text pool
{
	const h = host(AS, NEW_T);
	const p = new Sprite();
	const pass = (calls) => { h.hzsTPBegin(p); const r = calls.map((c) => h.hzsT(p, ...c)); h.hzsTPEnd(); return r; };
	const A = [["PLANET", 10, 20, 15, 0xFFFFFF, "sb", 0.08], ["42%", 200, 20, 30, 0xFFFFFF, "bd", 0, "r"], ["a long name that will not fit", 0, 50, 14, 0xC4D2D9, "rg", 0, "l", 1, 120]];
	made = 0; const r1 = pass(A); const m1 = made; const f1 = flat(p);
	made = 0; const r2 = pass(A);
	expect(m1 === 3 && made === 0 && r2.every((t, i) => t === r1[i]) && same(flat(p), f1), "pool: the same pass again makes no text field and draws the same");
	const lay = r2.map((t) => t.layouts);
	pass(A);
	expect(r2.every((t, i) => t.layouts === lay[i]), "pool: an unchanged field is not laid out again (only alpha and position are set)");
	made = 0; const B = A.map((c) => c.slice()); B[1][0] = "43%"; const r3 = pass(B);
	expect(made === 0 && r3[1] === r1[1] && r3[1].text === "43%", "pool: a new text in the same format reuses the field");
	B[0][4] = 0xFF0000; made = 0; const r4 = pass(B);
	expect(made === 1 && r4[0] !== r1[0] && p.getChildAt(0) === r4[0], "pool: a new color replaces the field in its own slot (child order kept)");
	made = 0; pass(B.slice(0, 1));
	expect(made === 0 && p.numChildren === 1, "pool: the slots a pass did not use are dropped");
	h.hzsClr(p);
	expect(p.numChildren === 0 && h.hzsTPc === null, "pool: hzsClr empties the container and closes its pass");
	// a container without an open pass gets new fields, as before
	const q = new Sprite(); h.hzsTPBegin(p); made = 0; h.hzsT(q, "X", 0, 0, 13, 0xFFFFFF); h.hzsT(q, "X", 0, 0, 13, 0xFFFFFF); h.hzsTPEnd();
	expect(made === 2 && q.numChildren === 2, "pool: hzsT on another container than the open pass appends new fields (probes, scratch)");
}
if (OLD) {
	// fuzz: random passes on the new pooled hzsT vs the 3ee48a4 hzsT on a cleared container
	const hn = host(AS, NEW_T), ho = host(OLD, OLD_T);
	const pn = new Sprite(), po = new Sprite();
	let seed = 7; const rnd = (n) => { seed = (seed + 0x6D2B79F5) | 0; let t = Math.imul(seed ^ (seed >>> 15), 1 | seed); t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t; return (((t ^ (t >>> 14)) >>> 0) % n); };   // mulberry32
	const words = ["", "N", "NE", "SCAN RANGE", "Aviator V", "Undiscovered", "12 m", "1.2 km", "AVATAR VAULT OF THE OLD ONES", "  pad  ", "x"];
	let ok = true, mn = 0, mo = 0, prev = null;
	for (let step = 0; step < 400; step++) {
		// mostly a small change of the last pass (a frame), sometimes a new one
		let calls;
		if (step > 0 && rnd(4) !== 0) {
			calls = prev.map((c) => c.slice());
			const j = rnd(calls.length), what = rnd(4);
			if (what === 0) calls[j][0] = words[rnd(words.length)]; else if (what === 1) { calls[j][1] = rnd(300); calls[j][2] = rnd(200); } else if (what === 2) calls[j][8] = [1, 0.5, 0.25][rnd(3)]; else if (calls.length > 1) calls.pop();
		} else calls = [];
		const n = calls.length ? 0 : 1 + rnd(7);
		for (let i = 0; i < n; i++) calls.push([words[rnd(words.length)], rnd(300), rnd(200), [13, 14, 15, 16][rnd(4)], [0xFFFFFF, 0x3FD0E0, 0x96A6AE][rnd(3)], ["sb", "bd", "rg"][rnd(3)], [0, 0.06, 0.12][rnd(3)], ["l", "c", "r"][rnd(3)], [1, 0.5][rnd(2)], [0, 0, 60, 120][rnd(4)]]);
		prev = calls;
		const tk = rnd(8) === 0 ? 0.8 : 1; hn.hzsTk = tk; ho.hzsTk = tk;
		made = 0; hn.hzsTPBegin(pn); for (const c of calls) hn.hzsT(pn, ...c); hn.hzsTPEnd(); mn += made;
		made = 0; ho.hzsClr(po); for (const c of calls) ho.hzsT(po, ...c); mo += made;
		if (!same(flat(pn), flat(po))) { ok = false; console.error("  differs at step " + step); break; }
	}
	expect(ok, "pool fuzz: 400 random passes draw exactly what the 3ee48a4 hzsT drew on a cleared container");
	expect(mn < mo / 2, "pool fuzz: far fewer fields made (" + mn + " vs " + mo + ")");
}

// ---------------------------------------------------------------- 3. "..." shortening
if (OLD) {
	const hn = host(AS, NEW_T), ho = host(OLD, OLD_T);
	const corpus = ["", "A", "AB", "ABC", "Avatar", "ANCIENT BURIAL GROUND OF THE VARUUN", "Undiscovered signal  ", "a b c d e f g h i j", "WWWWWWWWWWWWWWWWWWWW", "iiiiiiiiiiiiiiiiiiiiiiii", "AVAVAVAVAVAVAVAV", "Name   with   spaces", "Ærø Ünïcødé nämé", "x".repeat(80)];
	let ok = true, ln = 0, lo = 0, cases = 0;
	for (const s of corpus) for (const mw of [1, 10, 25, 40, 60, 90, 120, 180, 260, 400]) for (const sz of [13, 15]) for (const tr of [0, 0.12]) {
		const pn = new Sprite(), po = new Sprite();
		const tn = hn.hzsT(pn, s, 0, 0, sz, 0xFFFFFF, "sb", tr, "l", 1, mw), to = ho.hzsT(po, s, 0, 0, sz, 0xFFFFFF, "sb", tr, "l", 1, mw);
		cases++; ln += tn.layouts; lo += to.layouts;
		if (tn.text !== to.text || !same(flat(pn), flat(po))) { ok = false; console.error("  differs: '" + s + "' maxW " + mw + ": '" + tn.text + "' vs '" + to.text + "'"); }
	}
	// boundary: maxW exactly the width of each shortened candidate (the "<=" fits case)
	let bok = true, bcases = 0;
	for (const s of corpus) {
		if (s.length < 4) continue;
		for (let n = 2; n < s.length; n += Math.max(1, s.length >> 3)) {
			const pr = new Sprite(); const pt = ho.hzsT(pr, s.substr(0, n).replace(/\s+$/, "") + "...", 0, 0, 15, 0xFFFFFF, "sb", 0.12);
			const mw = pt.textWidth;
			const pn = new Sprite(), po = new Sprite();
			const tn = hn.hzsT(pn, s, 0, 0, 15, 0xFFFFFF, "sb", 0.12, "l", 1, mw), to = ho.hzsT(po, s, 0, 0, 15, 0xFFFFFF, "sb", 0.12, "l", 1, mw);
			bcases++;
			if (tn.text !== to.text || !same(flat(pn), flat(po))) { bok = false; console.error("  boundary differs: '" + s + "' maxW " + mw + ": '" + tn.text + "' vs '" + to.text + "'"); }
		}
	}
	expect(bok && bcases > 20, "shortening: a candidate exactly maxW wide is kept, as in the old loop (" + bcases + " boundary cases)");
	expect(ok, "shortening: the same text and spot as the one-character loop in all " + cases + " cases");
	expect(ln < lo, "shortening: fewer layouts (" + ln + " vs " + lo + ")");
	expect(/str\.length - 1;\s*\n\s*if\(hi < 2\) \{ return; \}/.test(fnText(AS, "hzsTrunc").body), "shortening: a two-character text is left as it is (the old loop never ran for it)");
}

// ---------------------------------------------------------------- 4. markers, compass, reticle / range / tag vs 3ee48a4
function scanHost(src, isNew, extra) {
	const names = (isNew ? NEW_T : OLD_T).concat(["hzsDrawMarks", "hzsDrawCompassIfMoved", "hzsDrawRet", "hzsCenter", "hzsDist"]).concat(isNew ? ["hzsMkSlot", "hzsMkSame"] : []);
	const P = {}; for (const n of ["Marks", "Tag", "Ret", "Frame", "Compass", "Head"]) P[n] = new Sprite();
	const h = host(src, names, Object.assign({ hzsP: P, hzsC: { ScanUnits: 0 }, hzsOn: () => true, hzsFD: null, hzsL: { globalToLocal: (q) => new Point(q.x, q.y) }, ScanMapMarkerHolder_mc: null,
		hzsVr: { x: 0, y: 0, left: 0, top: 0, right: 1920, bottom: 1080, width: 1920, height: 1080 }, hzsMarkSig: "", hzsCmpSig: "", hzsRetSig: "", hzsHead: 0, hzsGot: { cmp: 1 },
		hzsMarkName: (o) => String(o.n || ""), hzsMarkIcon: (o) => String(o.ic || "hex"), hzs41Own: (o) => String(o.own || ""), hzsCmpOn: () => false, hzsK: () => 1, hzsCmpMarks: () => "", hzsCmpMarkList: () => [],
		hzsMTag: function () { return this.__tag || null; }, CurrentPickRefType: 1, PICK_TYPE_NONE: 0 }, extra || {}));
	return h;
}
function both(fn, steps, label) {
	if (!OLD) return;
	const hn = scanHost(AS, true), ho = scanHost(OLD, false);
	let ok = true, mn = 0, mo = 0, quiet = [];
	steps.forEach((st, i) => {
		for (const h of [hn, ho]) st.set(h);
		made = 0; hn[fn](); const a = made;
		made = 0; ho[fn](); const b = made;
		mn += a; mo += b;
		if (st.quiet) quiet.push([st.name, a]);
		for (const k of Object.keys(hn.hzsP)) if (!same(flat(hn.hzsP[k]), flat(ho.hzsP[k]))) { ok = false; console.error("  " + label + " step " + i + " (" + st.name + "): " + k + " differs"); }
	});
	expect(ok, label + ": the same drawing as 3ee48a4 after each of " + steps.length + " steps");
	expect(mn < mo, label + ": fewer text fields made (" + mn + " vs " + mo + ")");
	for (const [n, a] of quiet) expect(a === 0, label + ": " + n + ": no text field made");
	return hn;
}
{
	const mk = (list) => ({ aScannableMarkers: list });
	const M = (x, y, d, disc, n, ic, own) => ({ fScreenXPct: x, fScreenYPct: y, uRangeM: d, bIsDiscovered: disc, n, ic, own });
	const base = [M(0.3, 0.4, 120, true, "Cave", "cave"), M(0.5, 0.5, 340, false, "", "hex"), M(0.6, 0.45, 80, true, "Outpost", "struct"), M(0.7, 0.6, 900, true, "Ship", "ship", "mine"), M(0.2, 0.3, 1500, true, "Vehicle", "vehicle", "other"), M(0.4, 0.7, 60, true, "Fourth name", "fauna")];
	const moved = (dx, dy) => base.map((o) => Object.assign({}, o, { fScreenXPct: o.fScreenXPct + dx, fScreenYPct: o.fScreenYPct + dy }));
	const steps = [
		{ name: "first draw", set: (h) => { h.hzsFD = mk(base); } },
		{ name: "same frame", quiet: true, set: (h) => { h.hzsFD = mk(base); } },
		{ name: "every marker moved (turning)", quiet: true, set: (h) => { h.hzsFD = mk(moved(0.01, 0.003)); } },
		{ name: "moved again", quiet: true, set: (h) => { h.hzsFD = mk(moved(-0.02, 0.01)); } },
		{ name: "one distance changed (walking)", set: (h) => { const l = moved(-0.02, 0.01); l[1].uRangeM = 335; h.hzsFD = mk(l); } },
		{ name: "one marker discovered", set: (h) => { const l = moved(-0.02, 0.01); l[1].bIsDiscovered = true; l[1].n = "Ruins"; h.hzsFD = mk(l); } },
		{ name: "a marker left the view", set: (h) => { h.hzsFD = mk(base.slice(1)); } },
		{ name: "none in view", set: (h) => { h.hzsFD = mk([]); } },
		{ name: "back", set: (h) => { h.hzsFD = mk(base); } },
		{ name: "only the ship owner changed (mine -> other)", set: (h) => { const l = base.slice(1); l[2] = Object.assign({}, l[2], { own: "other" }); h.hzsFD = mk(l); } },
		{ name: "owner back, vehicle owner cleared", set: (h) => { const l = base.slice(1); l[3] = Object.assign({}, l[3], { own: "" }); h.hzsFD = mk(l); } },
		{ name: "settings change", set: (h) => { h.hzsCfgRev++; } },
		{ name: "markers off", set: (h) => { h.hzsOn = (k) => k !== "ScanWorldMarkers"; } },
		{ name: "markers on", set: (h) => { h.hzsOn = () => true; h.hzsFD = mk(moved(0.03, 0)); } },
	];
	// undiscovered markers changed look (brighter POI + dark backing): do not require a pixel match with 3ee48a4.
	// Still require the 0.43.4 pooling contract: fewer fields than the old rebuild, none on a move-only frame.
	{
		const hn = scanHost(AS, true);
		let mn = 0;
		const quiet = [];
		steps.forEach((st) => { st.set(hn); made = 0; hn.hzsDrawMarks(); mn += made; if (st.quiet) quiet.push([st.name, made]); });
		if (OLD) {
			const ho = scanHost(OLD, false);
			let mo = 0;
			steps.forEach((st) => { st.set(ho); made = 0; ho.hzsDrawMarks(); mo += made; });
			expect(mn < mo, "world markers: fewer text fields made (" + mn + " vs " + mo + ")");
		}
		for (const [n, a] of quiet) expect(a === 0, "world markers: " + n + ": no text field made");
		const slots = hn.hzsMkI.kids; const c0 = slots.map((s) => s.graphics.clears);
		const keepI = hn.hzsMkI, keepT = hn.hzsMkT;
		hn.hzsFD = mk(moved(0.05, 0.02)); hn.hzsDrawMarks();
		expect(slots.every((s, i) => s.graphics.clears === c0[i]), "world markers: a move-only frame redraws no marker (the sprites move)");
		expect(hn.hzsMkI === keepI && hn.hzsMkT === keepT, "world markers: hzsMkI / hzsMkT are reused (not torn down)");
		expect(hn.hzsP.Marks.kids.length === 2 && hn.hzsP.Marks.kids[0] === hn.hzsMkI && hn.hzsP.Marks.kids[1] === hn.hzsMkT, "world markers: the icon layer sits under the text layer");
	}
}
{
	const steps = [];
	steps.push({ name: "first", set: (h) => { h.hzsHead = 10; } });
	for (let i = 1; i <= 60; i++) steps.push({ name: "turn " + i, set: (h) => { h.hzsHead = 10 + i * 1.7; } });
	steps.push({ name: "same heading", quiet: true, set: (h) => { h.hzsHead = 10 + 60 * 1.7; } });
	steps.push({ name: "compact", set: (h) => { h.hzsCmpOn = () => true; h.hzsCfgRev++; } });
	steps.push({ name: "marks", set: (h) => { h.hzsCmpOn = () => false; h.hzsCmpMarkList = () => [[100, "ship"], [140, "quest"]]; h.hzsCmpMarks = () => "100ship,140quest"; h.hzsHead = 120; } });
	steps.push({ name: "compass off", set: (h) => { h.hzsOn = (k) => k !== "ScanShowCompass"; } });
	steps.push({ name: "compass on", set: (h) => { h.hzsOn = () => true; h.hzsHead = 359.6; } });
	both("hzsDrawCompassIfMoved", steps, "compass");
}
{
	const T = (n, d, sub, flg, sym, col) => ({ n, d, sub, flg, sym, col });
	const steps = [
		{ name: "no pick", set: (h) => { h.hzsFD = { iScanDistance: 0 }; h.__tag = null; } },
		{ name: "range", set: (h) => { h.hzsFD = { iScanDistance: 25 }; } },
		{ name: "range 24", set: (h) => { h.hzsFD = { iScanDistance: 24 }; } },
		{ name: "tag", set: (h) => { h.__tag = T("Ashta", "12 m", "Fauna", "TAGGED,DISEASED", "A", 0x5EE3A1); } },
		{ name: "range 23 with tag", set: (h) => { h.hzsFD = { iScanDistance: 23 }; } },
		{ name: "same", quiet: true, set: () => { } },
		{ name: "long tag", set: (h) => { h.__tag = T("A very long creature name that has to be shortened", "1.2 km", "", "", "", 0xF2A93B); } },
		{ name: "tag color", set: (h) => { h.__tag = T("Ashta", "12 m", "Fauna", "", "", 0xFF5B5B); } },
		{ name: "tag gone", set: (h) => { h.__tag = null; } },
		{ name: "screen change", set: (h) => { h.hzsVr = { x: 0, y: 0, left: 0, top: 0, right: 2560, bottom: 1080, width: 2560, height: 1080 }; h.hzsVrRev++; } },
		{ name: "no range", set: (h) => { h.hzsFD = { iScanDistance: 0 }; h.__tag = T("Ruins", "", "", "DEAD", "", 0x96A6AE); } },
		{ name: "font arrived + range", set: (h) => { h.hzsFontLib = 2; h.hzsFace = (w) => "$Horizon_Font_Alt" + w; h.hzsFD = { iScanDistance: 40 }; } },
	];
	both("hzsDrawRet", steps, "reticle, range and tag");
}

// ---------------------------------------------------------------- 7. Social card vs 3ee48a4
if (OLD) {
	const SOC = ["hzsDrawPanel", "hzsDSocial", "hzsSection", "hzsGs", "hzsRight", "hzsDur", "hzsKeycap", "hzsKeyOf"];
	const mkS = (src, isNew) => {
		const P = { Social: new Sprite() };
		return host(src, (isNew ? NEW_T : OLD_T).concat(SOC), { hzsP: P, hzsSig: {}, hzsSz: {}, hzsK: () => 1, hzsTitle: () => false, hzsMSocial: function () { return this.__soc; }, hzsCard: (g, w, h2, r, stripe, ring, ringA) => { g.ops.push(["card", w, h2, r, stripe, ring === undefined ? 0xFFFFFF : ring, ringA === undefined ? 0.1 : ringA]); } });
	};
	const Object_ = (o) => o;
	const keyB = (amt, key, lab) => ({ acc: 0, amt, key, lab, font: null });
	const steps = [
		{ name: "empty card -> bounty with key (no skills)", soc: { rows: [], b: keyB("1500", "R", "Pay") } },
		{ name: "same", soc: { rows: [], b: keyB("1500", "R", "Pay") } },
		{ name: "skills + bounty with key", soc: { rows: [["Persuasion", 40, 0, 1], ["Intimidate", 25, 90, 0]], b: keyB("1500", "R", "Pay") } },
		{ name: "amount changed", soc: { rows: [["Persuasion", 40, 0, 1], ["Intimidate", 25, 90, 0]], b: keyB("2250", "R", "Pay") } },
		{ name: "longer key and label", soc: { rows: [["Persuasion", 45, 30, 1]], b: keyB("2250", "Enter", "Pay bounty") } },
		{ name: "skills only", soc: { rows: [["Persuasion", 45, 30, 1]], b: null } },
		{ name: "bounty without key", soc: { rows: [["Persuasion", 45, 30, 0]], b: keyB("900", "", "") } },
		{ name: "bounty accepted", soc: { rows: [], b: { acc: 1, amt: "900" } } },
		{ name: "person note", soc: { note: "Not in range", rows: [] } },
		{ name: "bounty with key again", soc: { rows: [], b: keyB("1500", "R", "Pay") } },
		{ name: "hidden", soc: null },
		{ name: "after hide: skills + bounty with key", soc: { rows: [["Deception", 10, 0, 1]], b: keyB("300", "E", "Pay") } },
	];
	const hn = mkS(AS, true), ho = mkS(OLD, false);
	let ok = true, err = null;
	for (const st of steps) {
		for (const h of [hn, ho]) h.__soc = st.soc == null ? null : JSON.parse(JSON.stringify(st.soc));
		try { hn.hzsDrawPanel("Social"); } catch (e) { err = e; }
		ho.hzsDrawPanel("Social");
		const P = hn.hzsP.Social, Q = ho.hzsP.Social;
		const a = flat(P), b = flat(Q);
		if (!same(a, b) || P.visible !== Q.visible || !same(hn.hzsSz.Social, ho.hzsSz.Social)) { ok = false; console.error("  Social differs at: " + st.name + " (new " + a.length + " items, old " + b.length + ")"); }
		if (st.soc && P.visible !== true) { ok = false; console.error("  Social card hidden at: " + st.name); }
		const keys = P.kids.filter((t) => t.visible && t._text === (st.soc && st.soc.b ? st.soc.b.key : "\u0000")).length;
		if (st.soc && st.soc.b && st.soc.b.key && keys !== 1) { ok = false; console.error("  Social key shown " + keys + " times at: " + st.name); }
	}
	expect(err === null, "Social: no display list error while drawing (" + (err ? err.message : "none") + ")");
	expect(ok, "Social: a bounty with a key prompt draws as in 3ee48a4 after each of " + steps.length + " steps (empty card, card with fields, after hide)");
}

// ---------------------------------------------------------------- 5. 6-frame poll
{
	const drawn = [];
	const h = host(AS, ["hzsDrawAll"], { hzsDrawPanel: (n) => drawn.push(n), hzsDrawCompassIfMoved() { }, hzsPlace() { }, hzsEnvFRev: 0, hzsEnvFDrawn: -1 });
	expect(/private var hzsEnvFRev:int = 0;/.test(AS) && /private var hzsEnvFDrawn:int = -1;/.test(AS), "poll: the planet card starts as not drawn");
	const run = (ev) => { drawn.length = 0; h.hzsDrawAll(ev); return drawn.join(","); };
	const all = "Planet,Bioscan,Signals,Traits,Social,Mode,Hints", polled = "Signals,Traits,Social,Mode,Hints";
	expect(run(true) === all, "poll: an event walk draws every card");
	expect(run(false) === polled, "poll: the 6-frame poll without events skips planet and bioscan");
	h.hzsEnvFRev++;
	expect(run(false) === "Planet," + polled && run(false) === polled, "poll: new frequent env data (local time) redraws the planet card once");
	expect(run() === all, "poll: hzsDrawAll() without an argument is the full walk (other callers)");
	const tick = fnText(AS, "hzsTick").body;
	expect(/var ev:Boolean = this\.hzsDirty;\s*\n\s*this\.hzsDirty = false;\s*\n\s*try \{ this\.hzsDrawAll\(ev\);/.test(tick), "poll: the tick passes whether an event asked for the walk");
	expect(/this\.hzsEnvFRev\+\+/.test(fnText(AS, "hzsOnEnvF").body), "poll: LocalEnvData_Frequent bumps its revision");
	for (const n of ["hzsOnMD", "hzsOnRD", "hzsOnEnv", "hzsOnFx", "hzsOnLoc", "hzsOnPickApplied"]) expect(/this\.hzsDirty = true/.test(fnText(AS, n).body), "poll: " + n + " still asks for an event walk");
	// every place that drops the drawn signatures also asks for an event walk
	const sigResets = AS.split("\n").filter((l) => /this\.hzsSig = \{\};/.test(l));
	const ok = AS.split("\n").every((l, i, a) => !/this\.hzsSig = \{\};/.test(l) || /this\.hzsDirty = true/.test(l) || /this\.hzsDirty = true/.test(a[i + 1] || ""));
	expect(sigResets.length === 3 && ok, "poll: all three signature resets come with hzsDirty (settings, font, screen)");
	// the bioscan / planet models read only event data (no pick, button bar or marker list)
	for (const n of ["hzsMPlanet", "hzsMBioscan", "hzsHazards", "hzsTraitState", "hzsShowPlanetInfo", "hzsClock"]) {
		const b = fnText(AS, n).body;
		expect(!/hzsFD|hzsPD|hzsPA|hzsCmp\b|hzsCmp\.|CurrentPickRefType|ButtonBar_mc|hzsMarkers|hzs41/.test(b), "poll: " + n + " reads no polled input");
	}
}

// ---------------------------------------------------------------- 6. settings read on open
{
	let reads = 0, now = 0;
	const h = host(AS, ["hzsOnOpened"], { hzsReading: false, hzsReadT: -1, hzsOpenReads: 0, hzsRead() { reads++; } });
	h.__w.getTimer = () => now;
	h.hzsReading = true; h.hzsOnOpened();
	expect(reads === 0, "open: no read while the start read is still running");
	h.hzsReading = false; h.hzsReadT = 100; now = 400; h.hzsOnOpened();
	expect(reads === 0, "open: no second read right after the start read finished");
	now = 100 + 3000; h.hzsOnOpened();
	expect(reads === 1, "open: a movie whose last read is 3 s old reads again (a movie kept across opens)");
	h.hzsReadT = -1; h.hzsOnOpened();
	expect(reads === 2, "open: no read yet at all: it reads");
	expect(/this\.hzsReadT = getTimer\(\);/.test(fnText(AS, "hzsOnIni").body) && /this\.hzsRead\(\);/.test(fnText(AS, "hzsInit").body), "open: the start read still runs and stamps its finish");
}

// ---------------------------------------------------------------- static: pooled containers only get children from hzsT
{
	const fns = [...AS.matchAll(/private function (\w+)\(/g)].map((m) => m[1]);
	const adders = fns.filter((n) => /\.addChild(At)?\(/.test(fnText(AS, n).body));
	expect(same(adders.sort(), ["hzsDrawMarks", "hzsDrawRet", "hzsInit", "hzsMkSlot", "hzsT"].sort()), "pool: only hzsT adds children to panels, the compass, the pill and the tag (" + adders.join(", ") + ")");
	const removers = fns.filter((n) => /\.removeChild(At)?\(/.test(fnText(AS, n).body));
	expect(same(removers.sort(), ["hzsClr", "hzsT", "hzsTPEnd"].sort()), "pool: only hzsT, hzsTPEnd and hzsClr remove children (" + removers.join(", ") + ")");
	const movers = fns.filter((n) => /\.(setChildIndex|swapChildren|swapChildrenAt)\(/.test(fnText(AS, n).body));
	const bio = fnText(AS, "hzsDBio").body; const si = bio.indexOf("p.setChildIndex(ct");
	expect(same(movers, ["hzsDBio"]) && si > 0 && !/hzsT\(|hzsKeycap\(|hzsSection\(/.test(bio.slice(si)), "pool: the one reorder (scan complete chip on top) is the last field of its pass, so it moves nothing");
	expect(!/\.hzsT\(p,String\(b\.key\)/.test(fnText(AS, "hzsDSocial").body) && /var kw:TextField = this\.hzsT\(new Sprite\(\),String\(b\.key\)/.test(fnText(AS, "hzsDSocial").body), "Social: the key prompt is measured on a throwaway sprite, not on the card");
	const dp = fnText(AS, "hzsDrawPanel").body;
	expect(/if\(m == null\) \{ this\.hzsClr\(p\);/.test(dp) && /this\.hzsTPBegin\(p\);/.test(dp) && /this\.hzsTPEnd\(\);\s*\n\s*this\.hzsTk = 1;/.test(dp), "pool: the panels open a text pass after the empty check and close it after drawing");
	expect(!/probe/.test(fnText(AS, "hzsDrawMarks").body) && !/probe/.test(fnText(AS, "hzsDrawRet").body) && !/probe/.test(fnText(AS, "hzsDrawCompassIfMoved").body), "markers, reticle and compass measure their own fields (no probe copies)");
	expect(!/hzsSer\(list\)/.test(fnText(AS, "hzsDrawMarks").body), "world markers: no serialized list string per frame");
	expect(!/GlowFilter/.test(AS) && !/\.filters\s*=/.test(AS), "scanner block adds no GlowFilter / filter array (cheap backing only)");
	expect(!/ScanHlApply/.test(AS), "scanner movie never calls ScanHlApply");
	expect(!/hzsMkI\s*=\s*null/.test(fnText(AS, "hzsTick").body) && !/hzsMkT\s*=\s*null/.test(fnText(AS, "hzsTick").body) && !/ScanHlApply/.test(fnText(AS, "hzsTick").body), "hzsTick does not tear down hzsMkI / hzsMkT or apply highlight INI");
	expect(/HZS_POI/.test(AS) && /0xD7E3E8/.test(BLOCK) && /HZS_POI/.test(fnText(AS, "hzsDrawMarks").body) && /HZS_BG/.test(fnText(AS, "hzsDrawMarks").body), "undiscovered world markers: brighter POI tone and a dark backing, redrawn only when the slot key changes");
	expect(/HZS_POI/.test(fnText(AS, "hzsMSignals").body) && /HZS_BG/.test(fnText(AS, "hzsDSig").body), "Signals rows: undiscovered uses the POI tone and a dark row backing");
}

if (failed) { console.error("scanner perf 0.43.4: " + passed + " ok, " + failed + " FAILED"); process.exit(1); }
console.log("scanner perf 0.43.4: " + passed + " ok, all passed");
