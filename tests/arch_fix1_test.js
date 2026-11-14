// arch-fixes Fix 1 tests: custom watch styles 3/4 and the vanilla hide passes do their work on edges only.
// Run: node tests/arch_fix1_test.js   (HZ_AS=<file> runs it against another horizon_block.as, used by the mutants)
// Proves, by running the production AS functions (types stripped) on a small display model:
//  1. hz43ChrNeedA / hz43ChrNeedB: a steady frame needs no full chrome pass; every edge (style, child count, a hidden
//     ref shown again or torn down, a walked container's count, the force bits, a full list) does; pass B re-asserts
//     the kept markers it recorded, as the old every-frame pass did;
//  2. hz43VanRingMid: one search on the first call, none on steady calls, the same owned Point, a new center when the
//     outline or its holders move, a re-search when the ref is torn down;
//  3. hz43VanWrite: an unchanged 0 marker offset is not written again;
//  4. hz43Dirty / hz43Frame: a heading-only change redraws only the compass layer; other changes redraw the face;
//     the 1/1000-day stamp alone redraws nothing;
//  5. hz43Compass: the card letters it shows / hides equal the ad08bda code for every heading (bit mask, no Array);
//  6. hz43CardMoved: steady frames read no display bounds when the card has a declared size;
//  7. hz43VanDump: diagnostics off (WatchLog off) returns before any search or string;
//  8. static: the hide-list re-walk and the BLG pass have no periodic term (only the missing-name retry), and the
//     fix adds no timer, enterFrame listener, setInterval or per-frame search.
// Author: Moragar. Last modified: 2026-11-13.
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");
let baseAs = null;
try { baseAs = cp.execFileSync("git", ["show", "ad08bda:actionscript/horizon_block.as"], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { baseAs = null; }

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
function codeOnly(body) { return body.replace(/\/\/[^\n]*/g, ""); }
function toJs(body) {
	return body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*(?:Error|\*)\s*\)\s*\{/g, "catch($1) {")
		.replace(/for each\s*\(\s*var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+\s+in\s+/g, "for (var $1 of ")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
const GLOBALS = {
	int: (v) => Math.trunc(Number(v)) | 0, uint: (v) => Number(v) >>> 0, Number: Number, String: String, Boolean: Boolean, Math: Math, isNaN: isNaN,
	TextField: (x) => x, DisplayObjectContainer: (x) => x, Sprite: (x) => x, Point: function () { this.x = 0; this.y = 0; }, HZ43_HID_MAX: 40, HZ43_VAN_FACE: 221, HZ43_R: 132,
};
function bind(h, names, src) {
	const s = src || as;
	const wrap = new Proxy(h, { get(t, k) { if (k in t) return t[k]; if (k in GLOBALS) return GLOBALS[k]; return undefined; }, has(t, k) { return typeof k === "string" && (k in t || k in GLOBALS); } });
	for (const n of names) {
		const f = fnText(s, n);
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}
function clip(name, extra) { return Object.assign({ name: name, visible: true, stage: {}, x: 0, y: 0, scaleX: 1, scaleY: 1, parent: null }, extra || {}); }
function box(name, kids) {
	const c = clip(name);
	c.kids = kids || [];
	for (const k of c.kids) k.parent = c;
	Object.defineProperty(c, "numChildren", { get() { return this.kids.length; } });
	c.getChildAt = function (i) { return this.kids[i]; };
	return c;
}

// ---- 1. chrome pass edges ----
{
	const a = clip("WatchOutline_mc", { visible: false }), b = clip("O2CO2_mc", { visible: false }), w = clip("DayCycleBase_mc", { visible: false });
	const mk = clip("MissionIconsWidget_mc"), holder = box("Holder", [mk, clip("Ring")]);
	const blg = box("BottomLeftGroup_mc", [a, b, w, holder]);
	const h = bind({ hzBlg: blg, hzWatchStyle: 3, hz43ChrForce: 0, hz43ChrKidsA: 4, hz43ChrStA: 3, hz43ChrKidsB: 4, hz43ChrStB: 3,
		hz43HidA: [a, b], hz43HidN: 2, hz43ChrW: [w], hz43ChrWN: 1, hz43ChrShow: [mk, holder], hz43ChrShowN: 2, hz43ChrBox: [holder], hz43ChrBoxK: [2], hz43ChrBoxN: 1 },
		["hz43ChrStale", "hz43ChrNeedA", "hz43ChrNeedB"]);
	expect(h.hz43ChrNeedA() === false && h.hz43ChrNeedB() === false, "steady frame: neither chrome pass runs");
	mk.visible = false; holder.visible = false;
	expect(h.hz43ChrNeedB() === false && mk.visible && holder.visible, "steady frame: pass B re-asserts the recorded kept markers (the old every-frame write) without a full pass");
	a.visible = true;
	expect(h.hz43ChrNeedA() === true && h.hz43ChrNeedB() === true, "a hidden ref shown again by the timeline is an edge for both passes");
	a.visible = false; w.visible = true;
	expect(h.hz43ChrNeedA() === true, "a game-hidden watch child shown later is an edge for pass A");
	w.visible = false; b.stage = null;
	expect(h.hz43ChrNeedA() === true && h.hz43ChrNeedB() === true, "a torn-down ref (stage null) is an edge: no ref survives a menu teardown");
	b.stage = {};
	blg.kids.push(clip("instance99"));
	expect(h.hz43ChrNeedA() === true && h.hz43ChrNeedB() === true, "a BLG child count change is an edge");
	blg.kids.pop();
	holder.kids.push(clip("instance100"));
	expect(h.hz43ChrNeedA() === false && h.hz43ChrNeedB() === true, "a walked container's child count change is an edge for pass B");
	holder.kids.pop();
	h.hzWatchStyle = 4;
	expect(h.hz43ChrNeedA() === true && h.hz43ChrNeedB() === true, "a style change is an edge");
	h.hzWatchStyle = 3; h.hz43ChrForce = 1;
	expect(h.hz43ChrNeedA() === true && h.hz43ChrNeedB() === false, "force bit 1 runs pass A only");
	h.hz43ChrForce = 2;
	expect(h.hz43ChrNeedA() === false && h.hz43ChrNeedB() === true, "force bit 2 runs pass B only");
	h.hz43ChrForce = 0; h.hz43HidN = 40;
	expect(h.hz43ChrNeedA() === true && h.hz43ChrNeedB() === true, "a full note list falls back to the old every-frame pass");
}

// ---- 1b. keep / box recording only while a full pass records ----
{
	const h = bind({ hz43ChrRec: false, hz43ChrShow: null, hz43ChrShowN: 0, hz43ChrBox: null, hz43ChrBoxK: null, hz43ChrBoxN: 0 }, ["hz43ChrKeep", "hz43ChrBoxAdd"]);
	const d = clip("x", { visible: false });
	h.hz43ChrKeep(d);
	expect(d.visible === true && h.hz43ChrShowN === 0, "keep write outside a full pass: same visible write, nothing recorded");
	h.hz43ChrRec = true;
	h.hz43ChrKeep(d); h.hz43ChrKeep(d);
	const c = box("c", [clip("1"), clip("2")]);
	h.hz43ChrBoxAdd(c); h.hz43ChrBoxAdd(c);
	expect(h.hz43ChrShowN === 1 && h.hz43ChrBoxN === 1 && h.hz43ChrBoxK[0] === 2, "inside a full pass: each ref recorded once, the container with its count");
}

// ---- 2. ring center ----
{
	let finds = 0, l2g = 0;
	const par = box("BottomLeftGroup_mc", []);
	const ol = clip("WatchOutline_mc", { x: 10, y: 20 });
	par.kids.push(ol); ol.parent = par;
	par.localToGlobal = (p) => { l2g++; return { x: p.x + par.x, y: p.y + par.y }; };
	const h = bind({ hzBlg: par, hz43VanP: { x: 0, y: 0 }, hz43RmD: null, hz43RmKids: -2, hz43RmOk: false, hz43ChrForce: 0, hz43RmP: null,
		hz43RmX: NaN, hz43RmY: NaN, hz43RmPx: NaN, hz43RmPy: NaN, hz43RmPs: NaN, hz43RmBx: NaN, hz43RmBy: NaN, hz43RmBs: NaN,
		hzFindByName: (c, n) => { finds++; return n === "WatchOutline_mc" ? ol : null; }, globalToLocal: (g) => ({ x: g.x, y: g.y }) },
		["hz43VanRingMid"]);
	const p1 = h.hz43VanRingMid();
	let same = true;
	for (let i = 0; i < 100; i++) if (h.hz43VanRingMid() !== p1) same = false;
	expect(finds === 1 && l2g === 1 && same && p1.x === 10 + 110.5 && p1.y === 20 + 110.5, "ring center: one search and one transform, then 100 steady calls return the same owned Point");
	ol.x = 30;
	const p2 = h.hz43VanRingMid();
	expect(p2 === p1 && p2.x === 30 + 110.5 && l2g === 2 && finds === 1, "the outline moved: center recomputed, no search");
	par.x = 5;
	h.hz43VanRingMid();
	expect(l2g === 3 && p1.x === 35 + 110.5, "the BLG moved: center recomputed");
	// the outline inside a holder clip of the BLG: the holder moving alone is an edge too
	const hold = box("Holder", [ol]);
	hold.localToGlobal = (p) => { l2g++; return { x: p.x + hold.x + par.x, y: p.y + hold.y + par.y }; };
	h.hz43ChrForce = 4; h.hz43VanRingMid();
	const n0 = l2g;
	hold.x = 7;
	h.hz43VanRingMid();
	expect(l2g === n0 + 1 && p1.x === 30 + 7 + 5 + 110.5, "the outline's holder moved: center recomputed");
	const f0 = finds;
	ol.stage = null;
	h.hz43VanRingMid();
	expect(finds === f0 + 1, "a torn-down outline is searched again (no cached ref across a teardown)");
	ol.stage = {};
	h.hz43ChrForce = 4;
	h.hz43VanRingMid();
	h.hz43VanRingMid();
	expect(finds === f0 + 2 && (h.hz43ChrForce & 4) === 0, "a chrome edge re-resolves the outline once");
}

// ---- 3. offset-0 marker write ----
{
	let writes = 0;
	const d = { name: "MissionIconsWidget_mc" };
	let xv = 0;
	Object.defineProperty(d, "x", { get() { return xv; }, set(v) { writes++; xv = v; } });
	d.y = 0;
	const h = bind({ hz43VanCap: 1, hz43VanWdx: NaN, hz43VanWdy: NaN, hz43VanWsc: NaN, hz43VanWmk: -1, hz43MarkMoved: false, hz43VanWrote: false,
		hz43VanN: 1, hz43VanGot: [1], hz43VanNm: ["MissionIconsWidget_mc"], hz43VanUXA: [1], hz43VanUYA: [1], hz43VanX: [50], hz43VanY: [60], hz43VanOX: [0], hz43VanOY: [0],
		hz43VanSX: [1], hz43VanSY: [1], hz43FoDx: 0, hz43FoDy: 0, hz43FoSc: 1,
		hz43VanClip: () => d, hz43VanMarkName: (n) => n === "MissionIconsWidget_mc", hz43VanHasAncestorUnit: () => false, hz48UnitKids: () => false,
		hz43FollowApply: () => {}, hz48UnitPut: () => {}, hz43VanDump: () => {} }, ["hz43VanWrite"]);
	h.hz43VanWrite(0, 0, 1, true);
	const w1 = writes;
	for (let i = 0; i < 50; i++) h.hz43VanWrite(0, 0, 1, true);
	expect(w1 === 1 && writes === 1, "an unchanged 0 marker offset is written once, not on the next 50 calls");
	h.hz43VanWrite(12, 0, 1, true);
	expect(writes === 2 && xv === 62, "a changed marker offset is written");
}

// ---- 4. dirty levels ----
{
	const st = { hz43Force: false, hzWatchStyle: 3, hz43LastMode: 3, hz43H: 1, hz43LastH: 1, hz43M: 2, hz43LastM: 2, hz43Ut: 0, hz43LastUt: 0, hz43Ok: 1, hz43LastOk: 1,
		hz43DayB: 5, hz43LastDay: 5, hz43LastHead: 10, hzCmpDeg: 10, hz26O2F: 0.5, hz26Co2F: 0.2, hz43LastO2: 50, hz43LastCo2: 20, hz43PcH: 3, hz43LastPcH: 3, hz43PcM: 4, hz43LastPcM: 4,
		hzEnvTempC: 20, hz43LastTemp: 20, hzTempUnit: 0, hz43LastUnit: 0, hzClockFmt: 0, hz43LastClk: 0, HZ_ACCENT: 7, hz43LastAcc: 7, hz43LastAtt: 0, hzPpBodyName: "Jemison", hz43LastBody: "Jemison",
		hz43Att: 0, hz43Body: "Jemison", hz43Read: () => {}, hz43PcSample: () => {}, hz43AttCode: () => 0, hzFmtClock: () => "" };
	const h = bind(st, ["hz43Dirty"]);
	expect(h.hz43Dirty() === 0, "nothing changed: no draw");
	h.hzCmpDeg = 11;
	expect(h.hz43Dirty() === 1 && h.hz43Dirty() === 0, "heading-only change: compass layer only, once");
	h.hz43DayB = 6;
	expect(h.hz43Dirty() === 0, "the 1/1000-day stamp alone does not redraw (nothing on the face draws it)");
	h.hz43M = 3;
	expect(h.hz43Dirty() === 2, "a minute change redraws the face");
	h.hz43M = 4; h.hzCmpDeg = 40;
	expect(h.hz43Dirty() === 2 && h.hz43LastHead === 40, "heading and another change together: full redraw, heading recorded");
	const fr = fnText(as, "hz43Frame").body;
	expect(/var dk:int = this\.hz43Dirty\(\);\s*if\(dk == 2\) \{ this\.hz43Draw\(this\.hzWatchStyle\); \}\s*else if\(dk == 1\) \{ this\.hz43DrawCmp\(\); \}/.test(fr), "hz43Frame: 2 = hz43Draw, 1 = hz43DrawCmp only");
	const dc = codeOnly(fnText(as, "hz43DrawCmp").body);
	expect(dc.indexOf("this.hz43CmpS.graphics") >= 0 && dc.indexOf("hz43Face.graphics") < 0 && dc.indexOf("hz43TopS") < 0, "hz43DrawCmp clears and draws only the compass layer");
	const dr = codeOnly(fnText(as, "hz43Draw").body);
	expect(dr.indexOf(".text = ") < 0 && (dr.match(/hz43SetTx\(/g) || []).length === 9, "hz43Draw writes every face text through hz43SetTx (only on change)");
	const fl = codeOnly(fnText(as, "hz43FaceLayers").body);
	expect(/if\(this\.hz43CmpS != null && this\.hz43CmpS\.parent == this\.hz43Face\) \{ return; \}/.test(fl) && fl.indexOf("addChildAt(this.hz43CmpS,0)") >= 0 && fl.indexOf("addChildAt(this.hz43TopS,1)") >= 0,
		"layers made once, compass under the hands layer, both under the face texts");
}

// ---- 5. compass letters equal the base code ----
if (baseAs) {
	const mkCards = () => { const a = []; for (let i = 0; i < 8; i++) a.push({ x: 0, y: 0, visible: i % 2 === 0 }); return a; };
	const g = { beginFill() {}, endFill() {}, moveTo() {}, lineTo() {}, lineStyle() {} };
	let same = true, firstBad = -1;
	for (let deg = 0; deg < 360; deg += 1) {
		for (const seed of [0, 1]) {
			const ca = mkCards(), cb = mkCards();
			if (seed) { for (const c of ca) c.visible = true; for (const c of cb) c.visible = true; }
			const hn = bind({ hzCmpDeg: deg + 0.3, hz43Cards: ca, HZ_ACCENT: 1 }, ["hz43Compass", "hz43Diamond"]);
			const ho = bind({ hzCmpDeg: deg + 0.3, hz43Cards: cb, HZ_ACCENT: 1 }, ["hz43Compass", "hz43Diamond"], baseAs);
			hn.hz43Compass(g); ho.hz43Compass(g);
			if (JSON.stringify(ca) !== JSON.stringify(cb)) { same = false; if (firstBad < 0) firstBad = deg; }
		}
	}
	expect(same, "compass letters (place and visibility) equal ad08bda for 720 headings / start states" + (firstBad >= 0 ? " first diff " + firstBad : ""));
	const cb = codeOnly(fnText(as, "hz43Compass").body);
	expect(cb.indexOf("[]") < 0 && cb.indexOf("new Array") < 0 && cb.indexOf("indexOf") < 0, "hz43Compass allocates no Array");
} else console.log("skip compass equality (git show ad08bda not available)");

// ---- 6. card size reads ----
{
	let reads = 0;
	const card = { visible: true, alpha: 1, x: 5, y: 6, scaleX: 1, scaleY: 1 };
	Object.defineProperty(card, "width", { get() { reads++; return 100; } });
	Object.defineProperty(card, "height", { get() { reads++; return 50; } });
	const sz = [{ c: card, w: 100, h: 50 }];
	const h = bind({ HorizonChar_mc: card, HorizonVitals_mc: null, HorizonCard_mc: null, HorizonCompact_mc: null, hzSz: sz, hz43CsO: null, hz43CsL: -1,
		hz43Cx: [NaN, NaN, NaN, NaN], hz43Cy: [NaN, NaN, NaN, NaN], hz43Cw: [NaN, NaN, NaN, NaN], hz43Chh: [NaN, NaN, NaN, NaN], hz43Cv: [0, 0, 0, 0] },
		["hz43CardMoved", "hz43CardSzO", "hz43CardAt"]);
	const m1 = h.hz43CardMoved(0);
	let any = false;
	for (let i = 0; i < 60; i++) if (h.hz43CardMoved(0)) any = true;
	expect(m1 && !any && reads === 0, "a card with a declared size: first call is a change, 60 steady calls read no bounds");
	sz[0].h = 70;
	expect(h.hz43CardMoved(0) === true, "its declared size changed: the Home-avoid pass runs");
	const other = { visible: true, alpha: 1, x: 1, y: 1, scaleX: 1, scaleY: 1 };
	Object.defineProperty(other, "width", { get() { reads++; return 10; } });
	Object.defineProperty(other, "height", { get() { reads++; return 10; } });
	h.HorizonCompact_mc = other;
	h.hz43CardMoved(3);
	expect(reads === 2, "a card with no declared size keeps the old bounds read");
}

// ---- 7. diagnostics default-off ----
{
	let finds = 0;
	const h = bind({ hzWlOn: false, hzBlg: box("b", []), hz43DumpSig: "", hzFindByName: () => { finds++; return null; } }, ["hz43VanDump"]);
	let threw = false;
	try { h.hz43VanDump("horizon"); } catch (e) { threw = true; }
	expect(!threw && finds === 0 && h.hz43DumpSig === "", "hz43VanDump with WatchLog off: no search, no signature string");
}

// ---- 8. static: no periodic re-walk, no new timer / listener / per-frame search ----
{
	const of = codeOnly(fnText(as, "hzOnFrame").body);
	expect(/var rbEdge:Boolean = rbKids != this\.hzHideKids \|\| \(this\.hzHideMiss && this\.hzFrameN % 90 == 1\);/.test(of), "re-walk edge: BLG child count change, or the old retry only while a listed name is missing");
	expect((of.match(/% 90/g) || []).length === 1, "hzOnFrame has no other 90-frame term");
	expect(/if\(this\.hzBlg && this\.hz43ChrNeedA\(\)\)/.test(of), "the BLG child pass runs behind its edge gate");
	const vh = codeOnly(fnText(as, "hz43VanHorizon").body);
	expect(/if\(this\.hz43ChrNeedB\(\)\)\s*\{[^}]*try \{ this\.hz43VanChrome\(true\); \} finally \{ this\.hz43ChrRec = false; \}/.test(vh) && (vh.match(/hz43VanChrome\(/g) || []).length === 1,
		"hz43VanHorizon: the by-name chrome pass runs behind its edge gate only");
	const newFns = ["hz43ChrStale", "hz43ChrNeedA", "hz43ChrNeedB", "hz43ChrKeep", "hz43ChrBoxAdd", "hz43ChrWAdd", "hzHideMissing", "hz43SetTx", "hz43FaceLayers", "hz43DrawCmp", "hz43CardSzO"];
	let clean = true;
	for (const n of newFns) {
		const b = codeOnly(fnText(as, n).body);
		if (/addEventListener|setInterval|setTimeout|new Timer|ENTER_FRAME|EXIT_FRAME|hzFindByName|getChildByName/.test(b)) { clean = false; console.error("  in " + n); }
	}
	expect(clean, "the new helpers add no listener, timer, interval or display search");
	const rm = codeOnly(fnText(as, "hz43VanRingMid").body);
	expect((rm.match(/hzFindByName/g) || []).length === 1 && /\(this\.hz43ChrForce & 4\) != 0/.test(rm) && (rm.match(/new Point/g) || []).length === 1 && /if\(this\.hz43RmP == null\)/.test(rm),
		"ring center: the one search sits behind its edge; the one Point is made once");
	const wr = codeOnly(fnText(as, "hz43VanWrite").body);
	expect(wr.indexOf("(marks && (this.hz43MarkMoved || (dx == 0 && dy == 0)))") >= 0, "hz43VanWrite: unchanged 0 marker offset returns early");
	expect(/if\(!this\.hzWlOn\) \{ return; \}/.test(fnText(as, "hz43VanDump").body.split("\n").slice(0, 3).join("\n")), "hz43VanDump: first line is the WatchLog gate");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("arch fix 1: " + passed + " ok, all passed");
