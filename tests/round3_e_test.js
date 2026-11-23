// 0.43.6 round 3 step E: an allocation-free steady path. The per-frame / per-hover change checks that built a signature
// string now compare fields, and the per-frame lists are reused. Each rewritten body is run against its pre-0.43.6 body
// (git c6a3e0b) on the same random input sequences, including the old "" reset sites, and must make exactly the same
// draws. Source pins check that no string signature or new list is built on those paths any more.
// Run: node tests/round3_e_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { root, stripComments, readAs, fnText, mkFn, baseHost, expect, finish } = require("./lib/r3");
const { readBase } = require("./lib/git_base");

const as = readAs();
const BASE = "c6a3e0b";
const b = readBase(root, BASE);
if (b.src == null) { if (b.skip) { console.log("SKIP " + b.why); process.exit(0); } console.error("FAIL base " + BASE + ": " + b.why); process.exit(1); }
const old = stripComments(b.src);

let seed = 12345;
const rnd = () => { seed = (seed * 1103515245 + 12345) & 0x7fffffff; return seed / 0x7fffffff; };
// one value per step, shared by both hosts (a pick inside each host's step would draw two different values)
let stepVal = 0;
const pick = (a) => a[Math.floor(stepVal * a.length)];

// ---- foe bars ----
function G() { this.clears = 0; this.draws = []; }
G.prototype.clear = function () { this.clears++; };
G.prototype.beginFill = function (c, a) { this.draws.push("f" + c + "/" + a); };
G.prototype.endFill = function () {};
G.prototype.drawRoundRect = function (x, y, w, h) { this.draws.push([x, y, w, h].join(",")); };
function foeHost(src) {
	const h = baseHost({ HZ_RED: 0xff0000, hzPerfOn: false, hzPerfN: null, hzT19BarG: { visible: false, graphics: new G() }, hzT19BarSig: "",
		hzT19BarOn: false, hzT19BarW: 260, hzT19BarY: 40, hzTgHpV: 1, hzTgGhost: 0, hzDarkText() { return false; }, hzIconCol(c) { return c; } });
	h.hzSameN = mkFn(h, ["a", "b"], fnText(as, "hzSameN").body);
	h.paint = mkFn(h, [], fnText(src, "hzT19PaintFoeBars").body);
	return h;
}
{
	const A = foeHost(old), B = foeHost(as);
	let same = true;
	for (let i = 0; i < 4000; i++) {
		const r = rnd(); stepVal = rnd();
		const step = (h) => {
			if (r < 0.05) h.hzT19BarSig = "";
			else if (r < 0.15) h.hzT19BarOn = !h.hzT19BarOn;
			else if (r < 0.2) h.hzT19BarW = pick([260, 230, NaN, 0]);
			else if (r < 0.25) h.hzT19BarY = pick([40, 52, NaN]);
			else if (r < 0.5) h.hzTgHpV = pick([1, 0.5, 0.501, 0.2, 0, -1, NaN]);
			else if (r < 0.6) h.hzTgGhost = pick([0, 0.7, 0.701]);
			h.paint();
		};
		step(A); step(B);
		if (A.hzT19BarG.graphics.clears !== B.hzT19BarG.graphics.clears || A.hzT19BarG.graphics.draws.join("|") !== B.hzT19BarG.graphics.draws.join("|") || A.hzT19BarG.visible !== B.hzT19BarG.visible) { same = false; break; }
	}
	expect(same && A.hzT19BarG.graphics.clears > 50, "foe bars: 4000 random frames paint exactly as the old signature (" + A.hzT19BarG.graphics.clears + " repaints)");
	const nb = foeHost(as); nb.hzT19BarOn = true; nb.paint(); const c0 = nb.hzT19BarG.graphics.clears;
	for (let i = 0; i < 100; i++) nb.paint();
	expect(nb.hzT19BarG.graphics.clears === c0, "foe bars: 100 steady frames, no repaint");
	nb.hzT19BarSig = ""; nb.paint();
	expect(nb.hzT19BarG.graphics.clears === c0 + 1, "foe bars: the old reset (BarSig = \"\") still forces one repaint");
}
expect(!/var sig:String/.test(fnText(as, "hzT19PaintFoeBars").body), "foe bars: no signature string is built");

// ---- block extraction for the two in-line checks (hz26Tick, hzXhTick) ----
function between(body, startRe, endRe) {
	const s = body.search(startRe);
	if (s < 0) throw new Error("start not found " + startRe);
	const rest = body.slice(s);
	const e = rest.search(endRe);
	if (e < 0) throw new Error("end not found " + endRe);
	return rest.slice(0, e);
}
{
	const newBlk = between(fnText(as, "hz26Tick").body, /var chC:Boolean/, /if\(this\.hzPerfOn\) \{ this\.hzPsMark\(31\); \}/);
	const oldBlk = between(fnText(old, "hz26Tick").body, /var sig:String = this\.hz34C\("Character"\)/, /if\(this\.hzPerfOn\) \{ this\.hzPsMark\(31\); \}/);
	const mk = (blk) => {
		const h = baseHost({ HZ_ACCENT: 0x3fd0e0, hzArrange: false, hzCardColor: 0, hzTextScale: 1, hz26ChSig: "", ch: false, syncs: 0,
			hz26ChC: false, hz26ChA: false, hz26ChCol: -1, hz26ChAcc: 0, hz26ChTs: NaN,
			hz34C() { return this.ch; }, hz26CharSync() { this.syncs++; }, hz26XpSync() {} });
		h.hzSameN = mkFn(h, ["a", "b"], fnText(as, "hzSameN").body);
		h.run = mkFn(h, [], blk);
		return h;
	};
	const A = mk(oldBlk), B = mk(newBlk);
	let same = true;
	for (let i = 0; i < 4000; i++) {
		const r = rnd(); stepVal = rnd();
		const step = (h) => {
			if (r < 0.04) h.hz26ChSig = "";
			else if (r < 0.08) h.ch = !h.ch;
			else if (r < 0.11) h.hzArrange = !h.hzArrange;
			else if (r < 0.14) h.hzCardColor = pick([0, 1, 2, 5]);
			else if (r < 0.17) h.HZ_ACCENT = pick([0x3fd0e0, 0xff8800]);
			else if (r < 0.2) h.hzTextScale = pick([1, 1.1, 0.9, NaN]);
			h.run();
		};
		step(A); step(B);
		if (A.syncs !== B.syncs) { same = false; break; }
	}
	expect(same && A.syncs > 100, "hz26Tick: the character sync runs on exactly the same frames as the old signature (" + A.syncs + ")");
	expect(!/var sig:String/.test(newBlk), "hz26Tick: no signature string per frame");
}
{
	const newBlk = between(fnText(as, "hzXhTick").body, /if\(this\.hzXhSig == "" \|\|/, /this\.hzXh\.visible = true;/);
	const oldBlk = between(fnText(old, "hzXhTick").body, /var sig:String = this\.hzXhStyle/, /this\.hzXh\.visible = true;/);
	const mk = (blk) => {
		const h = baseHost({ HZ_ACCENT: 0x3fd0e0, hzXhStyle: 1, hzXhSig: "", draws: 0, pu: 1, hzXhLs: -1, hzXhLp: NaN, hzXhLa: 0, hzXhDraw() { this.draws++; } });
		h.hzSameN = mkFn(h, ["a", "b"], fnText(as, "hzSameN").body);
		h.run = mkFn(h, ["pu"], blk);
		return h;
	};
	const A = mk(oldBlk), B = mk(newBlk);
	let same = true;
	for (let i = 0; i < 3000; i++) {
		const r = rnd(); stepVal = rnd();
		const step = (h) => {
			if (r < 0.05) h.hzXhSig = "";
			else if (r < 0.1) h.hzXhStyle = pick([0, 1, 2, 3]);
			else if (r < 0.15) h.pu = pick([1, 0.75, 1080 / 1440]);
			else if (r < 0.18) h.HZ_ACCENT = pick([0x3fd0e0, 0xff8800]);
			h.run(h.pu);
		};
		step(A); step(B);
		if (A.draws !== B.draws) { same = false; break; }
	}
	expect(same && A.draws > 50, "hzXhTick: the crosshair glyph redraws on exactly the same frames (" + A.draws + ")");
	expect(/localToGlobal\(HZ_PT0\)/.test(fnText(as, "hzXhTick").body) && !/new Point\(0,0\)/.test(fnText(as, "hzXhTick").body), "hzXhTick: no new Point per frame");
	expect(/private static const HZ_PT0:Point = new Point\(0,0\);/.test(as), "HZ_PT0 is one shared origin");
}

// ---- hold fill: reused list, same draws ----
{
	const mk = (src) => {
		const h = baseHost({ hzPerfOn: false, hzPerfN: null, hzT19HoldSig: "", hzT19HoldDr: null, hzT19HoldG: { visible: false, graphics: new G() }, hzT19Btn: [], fr: {},
			hzT19BtnClip(aw, t) { return t; }, hzT19HoldFrac(t) { return this.fr[t] == null ? -1 : this.fr[t]; } });
		h.paint = mkFn(h, ["aw"], fnText(src, "hzT19PaintHold").body);
		G.prototype.drawRect = function (x, y, w, hh) { this.draws.push([x, y, w, hh].join(",")); };
		return h;
	};
	const A = mk(old), B = mk(as);
	const slots = [0, 1, 2, 3].map((t) => ({ holdOn: t !== 2, holdT: t, holdX: t * 30, holdY: 5, holdW: 20, holdH: 3, holdC: 0xffffff }));
	A.hzT19Btn = slots; B.hzT19Btn = slots;
	let same = true, firstArr = null;
	for (let i = 0; i < 2000; i++) {
		stepVal = rnd(); const t = Math.floor(rnd() * 4), v = pick([-1, 0, 0.01, 0.3, 0.31, 0.5, 1]);
		A.fr[t] = v; B.fr[t] = v;
		A.paint({}); B.paint({});
		if (firstArr == null) firstArr = B.hzT19HoldDr;
		if (A.hzT19HoldG.graphics.draws.join("|") !== B.hzT19HoldG.graphics.draws.join("|") || A.hzT19HoldG.visible !== B.hzT19HoldG.visible) { same = false; break; }
	}
	expect(same && A.hzT19HoldG.graphics.clears > 50, "hold fill: 2000 random frames draw exactly as before (" + A.hzT19HoldG.graphics.clears + " repaints)");
	expect(firstArr != null && B.hzT19HoldDr === firstArr && B.hzT19HoldDr.length === 0, "hold fill: one list for the session, left empty (no clip references kept)");
	B.paint({}); B.paint({});   // steady: the early return path
	expect(B.hzT19HoldDr === firstArr && B.hzT19HoldDr.length === 0, "hold fill: the unchanged-frame return leaves the list empty too");
}

// ---- show reticle: reused list, same restores ----
{
	const mk = (src) => {
		const h = baseHost({ hzT19RetDs: null, hzTgHidden: [], hzTgHidA: [] });
		h.run = mkFn(h, ["rw"], fnText(src, "hzT19ShowReticle").body);
		return h;
	};
	const kids = [0, 1, 2, 3, 4].map((i) => ({ name: "k" + i, alpha: 0, __doc: i === 1, __tf: i === 2 }));
	const rw = { __doc: true, Reticle_mc: { name: "Reticle_mc", alpha: 0 }, numChildren: kids.length, getChildAt(i) { return kids[i]; } };
	const fill = (h) => { h.hzTgHidden = [rw.Reticle_mc, kids[0], kids[1], kids[2], kids[3], { alpha: 0 }].map((d) => ({ d, a: 0.8 })); h.hzTgHidA = h.hzTgHidden.map(() => 1); };
	const A = mk(old), B = mk(as);
	fill(A); A.run(rw); const restoredA = A.hzTgHidden.length;
	kids.forEach((k) => (k.alpha = 0)); rw.Reticle_mc.alpha = 0;
	fill(B); B.run(rw); const restoredB = B.hzTgHidden.length;
	expect(restoredA === restoredB && restoredB === 3, "show reticle: the same clips are given back (" + restoredB + " kept hidden)");
	const arr = B.hzT19RetDs; fill(B); B.run(rw);
	expect(B.hzT19RetDs === arr && arr.length === 0, "show reticle: one list for the session, left empty");
}

finish("round3 E");
