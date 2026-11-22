// 0.43.6 round 3 step E2: the per-frame leftovers after E. Each rewritten body runs against its body at f422a80 on the
// same random input sequences and must give the same result:
//   hz35CmpTick (global Compact follow): an int of form bits instead of a signature string every frame
//   hzT19PaintHold (hover hold fill): the last holds as fields instead of a string per hover frame
//   hz26Center / hz26TickFx: one shared Point, the arc list kept in place, empty layers not cleared again
//   hz36HideTick: the name lookup only when the cached clip left its parent
//   hz27CharRuleOk: the clock is read only by the event rules; hzOnFrame reads the clock once for its three readers
// Run: node tests/round3_e2_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { root, stripComments, readAs, fnText, mkFn, baseHost, expect, finish } = require("./lib/r3");
const { readBase } = require("./lib/git_base");

const as = readAs();
const BASE = "f422a80";
const b = readBase(root, BASE);
if (b.src == null) { if (b.skip) { console.log("SKIP " + b.why); process.exit(0); } console.error("FAIL base " + BASE + ": " + b.why); process.exit(1); }
const old = stripComments(b.src);

let seed = 777;
const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
const CARDS = JSON.parse((as.match(/HZ34_CARDS:Array = (\[[^;]*\]);/) || [0, "[]"])[1]);

// ---- hz35CmpTick ----
{
	const mk = (src, isNew) => {
		const h = baseHost({ HZ34_CARDS: CARDS, hzCompact: false, cm: {}, hzCmpBody19: null, hzPlanPill: null, hzPpName: null, hzEq19: null, hzEqCount: null, HorizonCompactQuest_mc: null,
			hz35CmpWait: 0, hz36CmpTries: 0, forces: [], frame: 0, okSeq: null,
			hz34C(card) { return !!this.cm[card]; } });
		if (isNew) { h.hz35CmpSigN = -1; h.hz36CmpLast = -1; h.hz35CmpBits = mkFn(h, [], fnText(src, "hz35CmpBits").body); }
		else { h.hz35CmpSigS = ""; h.hz36CmpLast = ""; h.hz35CmpSig = mkFn(h, [], fnText(src, "hz35CmpSig").body); }
		h.hz35CmpForce = function () { this.forces.push(this.frame); return this.okSeq[this.frame]; };
		h.tick = mkFn(h, [], fnText(src, "hz35CmpTick").body);
		return h;
	};
	const A = mk(old, false), B = mk(as, true);
	const ok = []; for (let i = 0; i < 6000; i++) ok.push(rnd() < 0.7);
	A.okSeq = ok; B.okSeq = ok;
	const flip = (h, k, v) => { if (k === "G") h.hzCompact = v; else if (k === "c") h.hzCmpBody19 = v ? {} : null; else if (k === "p") { h.hzPlanPill = v ? {} : null; h.hzPpName = v ? {} : null; } else if (k === "e") { h.hzEq19 = v ? {} : null; h.hzEqCount = v ? {} : null; } else if (k === "q") h.HorizonCompactQuest_mc = v ? {} : null; else h.cm[k] = v; };
	const keys = ["G", "c", "p", "e", "q"].concat(CARDS.map((c) => c[0]));
	for (let f = 0; f < 6000; f++) {
		A.frame = B.frame = f;
		if (rnd() < 0.05) { const k = keys[Math.floor(rnd() * keys.length)], v = rnd() < 0.5; flip(A, k, v); flip(B, k, v); }
		A.tick(); B.tick();
	}
	expect(A.forces.length > 50 && A.forces.join() === B.forces.join(), "hz35CmpTick: the force-apply runs on exactly the same frames (" + A.forces.length + " applies over 6000 frames)");
	expect(A.hz36CmpTries === B.hz36CmpTries && A.hz35CmpWait === B.hz35CmpWait, "hz35CmpTick: same retry state at the end");
	expect(CARDS.filter((c) => c[1]).length <= 26, "hz35CmpBits: every compact-capable card has a bit");
	expect(!/String|\+ ?"|" ?\+/.test(fnText(as, "hz35CmpBits").body + fnText(as, "hz35CmpTick").body) && fnText(as, "hz35CmpSig") == null, "hz35CmpTick: no string is built any more");
}

// ---- hzT19PaintHold ----
function G() { this.clears = 0; this.draws = []; }
G.prototype.clear = function () { this.clears++; this.draws.push("C"); };
G.prototype.beginFill = function (c, a) { this.draws.push("f" + c); };
G.prototype.endFill = function () {};
G.prototype.drawRect = function (x, y, w, hh) { this.draws.push([x, y, w, hh].join(",")); };
{
	const mk = (src) => {
		const h = baseHost({ hzPerfOn: false, hzPerfN: null, hzT19HoldSig: "", hzT19HoldDr: null, hzT19HoldK: null, hzT19HoldKN: 0, hzT19HoldG: { visible: false, graphics: new G() }, hzT19Btn: [], fr: {},
			hzT19BtnClip(aw, t) { return t; }, hzT19HoldFrac(t) { return this.fr[t] == null ? -1 : this.fr[t]; } });
		h.paint = mkFn(h, ["aw"], fnText(src, "hzT19PaintHold").body);
		return h;
	};
	const A = mk(old), B = mk(as);
	const XS = [0, 30, 30.5, NaN, undefined, 60, -0];
	const slotsA = [0, 1, 2, 3].map((t) => ({ holdOn: true, holdT: t, holdX: t * 30, holdY: 5, holdW: 20, holdH: 3, holdC: 0xffffff }));
	const slotsB = slotsA.map((s) => Object.assign({}, s));
	A.hzT19Btn = slotsA; B.hzT19Btn = slotsB;
	let same = true, at = -1;
	for (let i = 0; i < 6000; i++) {
		const r = rnd();
		if (r < 0.04) { A.hzT19HoldSig = ""; B.hzT19HoldSig = ""; }          // the old reset sites
		else if (r < 0.05) { A.hzT19HoldSig = "x"; B.hzT19HoldSig = "x"; }   // a forced repaint (tests)
		const t = Math.floor(rnd() * 4), v = [-1, 0, 0.01, 0.3, 0.301, 0.305, 0.5, 1][Math.floor(rnd() * 8)];
		A.fr[t] = v; B.fr[t] = v;
		if (rnd() < 0.1) { const s = Math.floor(rnd() * 4), x = XS[Math.floor(rnd() * XS.length)]; slotsA[s].holdX = x; slotsB[s].holdX = x; }
		if (rnd() < 0.05) { const s = Math.floor(rnd() * 4), on = rnd() < 0.6; slotsA[s].holdOn = on; slotsB[s].holdOn = on; }
		A.paint({}); B.paint({});
		if (A.hzT19HoldG.graphics.draws.join("|") !== B.hzT19HoldG.graphics.draws.join("|") || A.hzT19HoldG.visible !== B.hzT19HoldG.visible) { same = false; at = i; break; }
	}
	expect(same && A.hzT19HoldG.graphics.clears > 200, "hold fill: 6000 random frames (resets, NaN / undefined / -0 x, holds on and off) paint exactly as before (" + A.hzT19HoldG.graphics.clears + " repaints" + (same ? "" : ", first difference at " + at) + ")");
	expect(B.hzT19HoldDr.length === 0 && B.hzT19HoldK.every((x) => typeof x !== "object" || x == null), "hold fill: no clip references kept between calls");
	expect(!/sig \+=|var sig:String/.test(fnText(as, "hzT19PaintHold").body), "hold fill: no string built per call");
}

// ---- hz26Center / hz26TickFx ----
function Pt(x, y) { this.x = Number(x); this.y = Number(y); }   // AS3 Point coerces its arguments to Number
function fxHost(src, cg) {
	const lay = () => ({ x: 0, y: 0, scaleX: 1, scaleY: 1, graphics: { ops: [], clear() { this.ops.length = 0; this.n = (this.n || 0) + 1; }, lineStyle() { this.ops.push("ls"); }, moveTo(x, y) { this.ops.push("m" + x.toFixed(3) + "," + y.toFixed(3)); }, lineTo(x, y) { this.ops.push("l" + x.toFixed(3) + "," + y.toFixed(3)); }, beginFill() { this.ops.push("bf"); }, endFill() {}, drawCircle(x, y, r) { this.ops.push("c" + r); } } });
	const h = baseHost({ HorizonFx_mc: { visible: true }, hzArrange: false, HZ_SCALE: 1, hzHudScale: 1, HZ_AMB: 1, HZ_RED: 2, hz26Hit: lay(), hz26Kill: lay(), hz26Ring: lay(),
		hz26Nums: [], hzDmgNumOn: true, hzDirRingOn: true, hzHitMarkOn: true, hz26HitT: -1e9, hz26KillT: -1e9, hz26HitCrit: false, hz26Arcs: [], hz26CtrP: null,
		hz26HitDr: true, hz26KillDr: true, hz26RingDr: true, Point: Pt, HUDMenu: { get CENTER_GROUP_POINT() { if (cg.v === "throw") throw new Error("x"); return cg.v; } },
		hzVis() { return { x: 0, y: 0, width: 1000, height: 600 }; } });
	h.hz26Center = mkFn(h, [], fnText(src, "hz26Center").body);
	h.fx = mkFn(h, ["now", "base"], fnText(src, "hz26TickFx").body);
	return h;
}
{
	const cg = { v: null };
	const A = fxHost(old, cg), B = fxHost(as, cg);
	let okC = true, p0 = null;
	for (const v of [{ x: 900, y: 500 }, { x: NaN, y: 3 }, { x: 0, y: 0 }, "throw", null, { x: 12, y: 0 }, { x: "7", y: "8" }]) {
		cg.v = v; const a = A.hz26Center(), c = B.hz26Center();
		if (!(a.x === c.x || (a.x !== a.x && c.x !== c.x)) || !(a.y === c.y || (a.y !== a.y && c.y !== c.y))) okC = false;
		if (p0 == null) p0 = c; else if (c !== p0) okC = false;
	}
	expect(okC, "hz26Center: the same point for every game value (normal, NaN, zero, missing, a throw, strings), one Point for the session");
	cg.v = { x: 960, y: 540 };
	let same = true, at = -1, arcsRef = B.hz26Arcs;
	for (let f = 0; f < 3000; f++) {
		const now = f * 33;
		const r = rnd();
		if (r < 0.03) { A.hz26HitT = B.hz26HitT = now; A.hz26HitCrit = B.hz26HitCrit = rnd() < 0.5; }
		else if (r < 0.05) { A.hz26KillT = B.hz26KillT = now; }
		else if (r < 0.09) { const arc = { r: Math.floor(rnd() * 360), t: now }; A.hz26Arcs.push(Object.assign({}, arc)); B.hz26Arcs.push(Object.assign({}, arc)); }
		else if (r < 0.1) { const v = rnd() < 0.5; A.hzDirRingOn = B.hzDirRingOn = v; }
		else if (r < 0.11) { const v = rnd() < 0.7; A.hzHitMarkOn = B.hzHitMarkOn = v; }
		const base = rnd() < 0.95;
		A.fx(now, base); B.fx(now, base);
		for (const k of ["hz26Hit", "hz26Kill", "hz26Ring"]) if (A[k].graphics.ops.join() !== B[k].graphics.ops.join() || A[k].x !== B[k].x) { same = false; at = f; }
		if (JSON.stringify(A.hz26Arcs) !== JSON.stringify(B.hz26Arcs)) { same = false; at = f; }
		if (!same) break;
	}
	expect(same, "hz26TickFx: hit, kill and ring layers hold exactly the old drawing on every one of 3000 frames, same arcs" + (same ? "" : " (frame " + at + ")"));
	expect(B.hz26Arcs === arcsRef, "hz26TickFx: the arc list is kept, never replaced");
	expect(B.hz26Ring.graphics.n < A.hz26Ring.graphics.n && B.hz26Hit.graphics.n < A.hz26Hit.graphics.n, "hz26TickFx: idle layers are not cleared every frame (ring " + B.hz26Ring.graphics.n + " vs " + A.hz26Ring.graphics.n + ")");
	expect(!/new Point|\[\]/.test(fnText(as, "hz26TickFx").body) && (fnText(as, "hz26Center").body.match(/new Point/g) || []).length === 1, "no new Point or list per frame");
}

// ---- hz36HideTick ----
{
	let looks = 0;
	const p = { kids: [], getChildByName(n) { looks++; return this.kids.find((k) => k.name === n) || null; } };
	const d = { name: "O2CO2_mc", parent: p, visible: true, alpha: 1, stage: {} };
	p.kids.push(d);
	const h = baseHost({ hzHideCache: [{ p: p, n: "O2CO2_mc", d: d }], hz36HideStale: false, hzWlOn: false, hzPerfOn: false, hzPcStHide: 0,
		hz43VanWatchClip() { return false; }, hz43StHideV() {}, hzWlPre() {}, hzWlPost() {}, hz43VanNoteAdd() {} });
	h.tick = mkFn(h, [], fnText(as, "hz36HideTick").body);
	for (let i = 0; i < 10; i++) h.tick();
	expect(looks === 0 && d.visible === false && d.alpha === 0, "hz36HideTick: a clip still in its parent is hidden with no name lookup");
	const d2 = { name: "O2CO2_mc", parent: p, visible: true, alpha: 1, stage: {} };
	p.kids = [d2]; d.parent = null;
	h.tick();
	expect(looks === 1 && h.hzHideCache[0].d === d2 && d2.visible === false && d2.alpha === 0, "hz36HideTick: a replaced clip is found by name and hidden on the same frame");
}

// ---- clock reads ----
{
	let reads = 0;
	const mk = (src, rule) => {
		const h = baseHost({ hzRuleChar: rule, hz27CharEvUntil: 1000, hz26Over: false, hz26Now() { reads++; return 500; }, hzRuleOk(r) { return r === 0; } });
		h.ok = mkFn(h, [], fnText(src, "hz27CharRuleOk").body);
		return h;
	};
	let same = true;
	for (const rule of [0, 1, 6, 7, 8, 9]) for (const over of [false, true]) for (const until of [0, 1000]) {
		const a = mk(old, rule), c = mk(as, rule); a.hz26Over = c.hz26Over = over; a.hz27CharEvUntil = c.hz27CharEvUntil = until;
		if (a.ok() !== c.ok()) same = false;
	}
	expect(same, "hz27CharRuleOk: same answer for every rule, overweight state and event window");
	reads = 0; mk(as, 0).ok(); mk(as, 8).ok();
	expect(reads === 0, "hz27CharRuleOk: the default rule (and the overweight rule) read no clock");
	const of = fnText(as, "hzOnFrame").body;
	expect((of.match(/this\.hz26Now\(\)/g) || []).length === 1 && /this\.hz40Frame\(wall\)/.test(of) && /this\.hz26Tick\(wall\)/.test(of) && /this\.hzAfLoadWatch\(wall\)/.test(of), "hzOnFrame: one clock read, passed to hz40Frame, hz26Tick and hzAfLoadWatch");
	for (const f of ["hz40Frame", "hz26Tick", "hzAfLoadWatch"]) {
		const t = fnText(as, f);
		expect(/now0:Number = NaN/.test(t.sig) && /var now:Number = isNaN\(now0\) \? /.test(t.body), f + ": uses the frame's clock, or reads its own when called without one (as before)");
	}
	expect(/this\.hz26Vis\(base,now\)/.test(fnText(as, "hz26Tick").body) && /isNaN\(now0\) \? this\.hz26Now\(\) : now0/.test(fnText(as, "hz26Vis").body), "hz26Vis: the frame's clock from hz26Tick; other callers read their own");
}
finish("round3 E2");
