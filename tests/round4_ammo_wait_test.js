// 0.43.6 round 4: the unknown-gun ammo wait (hzAmT0, HZ_AM_WAIT) is checked from the frame tick and on the load edge.
// Before, it was checked only from game events, so on a fresh start (gun in hand, full health and oxygen, nothing
// hovered) the inventory fallback could wait for the first shot, and the ammo type showed "--" until then.
// Checks: hzAmWaitTick against the real hzAmResolve (stubs below it), the two call sites, the event path unchanged,
// and no timer, listener or frame-modulo added.
// Run: node tests/round4_ammo_wait_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { readAs, fnText, mkFn, argNames, baseHost, expect, finish } = require("./lib/r3");

const as = readAs();
const WAIT = Number((as.match(/HZ_AM_WAIT:Number = (\d+);/) || [0, NaN])[1]);
expect(WAIT === 3000, "HZ_AM_WAIT is still 3000 ms");

const tick = fnText(as, "hzAmWaitTick");
expect(tick != null, "hzAmWaitTick exists");
const resolve = fnText(as, "hzAmResolve");

function mk(o) {
	const h = baseHost(Object.assign({
		HZ_AM_WAIT: WAIT, hzAmT0: NaN, hzAmInvOn: false, hzInvItems: null, hzWeapName: "Grendel", hzAmEq: null, hzMagCap: 0,
		hzAmmoDrawn: true, clock: 0, starts: 0, peeks: 0, draws: 0, types: [], known: null, resolveN: 0,
		hz26Now() { return this.clock; },
		hzAmFind() { return this.known; },
		hzSetAmmoType(t) { this.types.push(t); },
		hzAmInvStart() { this.starts++; this.hzAmInvOn = true; this.hzAmT0 = NaN; },
		hzAmInvPeek() { this.peeks++; },
		hzResolveAmmoType() { },
		hzDrawMag() { this.draws++; },
	}, o || {}));
	const r = mkFn(h, argNames(resolve.sig), resolve.body);
	h.hzAmResolve = function () { this.resolveN++; return r(); };
	h.tick = mkFn(h, argNames(tick.sig), tick.body);
	return h;
}

// fresh start: WeaponData arrives, nothing knows the type, so the wait starts at t=1000. No further game events.
{
	const h = mk();
	h.clock = 1000; h.hzAmResolve();
	expect(h.hzAmT0 === 1000 && h.starts === 0, "first resolve starts the 3 s wait, no fallback yet");
	h.resolveN = 0;
	let startAt = -1;
	for (let t = 1000; t <= 6000; t += 16) { h.clock = t; h.tick(t, false); if (h.starts && startAt < 0) startAt = t; }
	expect(startAt >= 4000 && startAt < 4016 + 16, "the frame tick starts the fallback about 3 s later with no event (at " + startAt + ")");
	expect(h.starts === 1, "the fallback starts once");
	expect(h.resolveN === 1, "hzAmResolve ran once from the tick (not every frame while waiting)");
	expect(h.draws === 1, "the magazine is redrawn with it");
	const before = h.resolveN;
	for (let t = 6000; t <= 20000; t += 16) h.tick(t, false);
	expect(h.resolveN === before, "nothing more runs per frame once the fallback owns it");
}

// nothing pending: the tick does nothing (hzOnFrame's inline guard skips the call; the tick's own isNaN returns)
{
	const h = mk();
	for (let t = 0; t < 10000; t += 16) h.tick(t, false);
	expect(h.resolveN === 0 && h.starts === 0 && h.draws === 0, "no wait pending: the tick is a no-op");
}

// load edge with nothing pending: the leading isNaN return keeps it a no-op (no resolve, draw or peek)
{
	const h = mk({ hzAmInvOn: true, hzInvItems: null });
	h.tick(5000, true); h.tick(9000, true);
	expect(h.resolveN === 0 && h.draws === 0 && h.peeks === 0 && h.starts === 0, "a load edge with no wait pending does nothing");
	const lead = tick.body.replace(/\s+/g, " ").trim();
	expect(lead.indexOf("if(isNaN(this.hzAmT0)) { return; }") === 0 || lead.indexOf("if(isNaN(this.hzAmT0)) return;") === 0, "hzAmWaitTick starts with the isNaN(hzAmT0) return");
}

// NaN clock never passes the wait
{
	const h = mk({ hzAmT0: 0 });
	h.tick(NaN, false);
	expect(h.resolveN === 0, "a NaN frame clock never runs the check");
}

// the type arrives during the wait from an event: the wait clears, and the tick never starts the fallback
{
	const h = mk();
	h.clock = 1000; h.hzAmResolve();
	h.clock = 2000; h.hzAmEq = { n: "Grendel", t: "7.77mm Caseless", c: 30 }; h.hzAmResolve();
	expect(isNaN(h.hzAmT0), "the equipped feed giving type and magazine clears the wait");
	for (let t = 2000; t <= 9000; t += 16) h.tick(t, false);
	expect(h.starts === 0, "the tick never starts the fallback once the type is known");
}

// load edge: a pending wait is resolved at once, even inside the 3 s window
{
	const h = mk({ hzAmT0: 5000 });
	h.clock = 5500; h.tick(5500, true);
	expect(h.resolveN === 1, "the load edge resolves a pending wait");
	// after the fallback owns it and the payload is still missing, the edge peeks again once
	const g = mk({ hzAmT0: 100, hzAmInvOn: true, hzInvItems: null });
	g.clock = 9000; g.tick(9000, false);
	expect(g.peeks === 0, "per frame: no inventory peek while the fallback owns it");
	g.tick(9000, true);
	expect(g.peeks === 1 && g.starts === 0, "load edge: one peek, no second fallback start");
}

// a throw clears the wait instead of retrying every frame
{
	const h = mk({ hzAmT0: 0 });
	h.hzAmResolve = function () { this.resolveN++; throw new Error("x"); };
	h.tick(4000, false); h.tick(4016, false);
	expect(h.resolveN === 1 && isNaN(h.hzAmT0), "a throw clears the wait (one try)");
}

// call sites
{
	const of = fnText(as, "hzOnFrame").body;
	const iW = of.indexOf("this.hzAfLoadWatch(wall)");
	const iT = of.indexOf("this.hzAmWaitTick(wall,false)");
	expect(iW > 0 && iT > iW, "hzOnFrame checks the wait each frame, after the load watch, with the frame clock");
	expect(of.indexOf("if(!isNaN(this.hzAmT0)) { try { this.hzAmWaitTick(wall,false); }") >= 0, "hzOnFrame calls the tick only while a wait is pending (inline isNaN guard)");
	const lw = fnText(as, "hzAfLoadWatch").body;
	expect(lw.indexOf("if(this.hzAfLastWall > 0 && now - this.hzAfLastWall > 4000) { this.hzAmWaitTick(now,true); }") > lw.indexOf("{ this.hzAfArmRelayout(); }") && lw.indexOf("{ this.hzAfArmRelayout(); }") > 0 && lw.indexOf("if(now > 0) { this.hzAfLastWall = now; }") > lw.indexOf("hzAmWaitTick(now,true)"), "the load gap edge checks the wait, after the relayout arm and before the last-wall update");
	const pf = fnText(as, "hzOnPlayerFrequent").body;
	expect(pf.indexOf("if(!isNaN(this.hzAmT0)) { try { this.hzAmResolve(); this.hzDrawMag(); }") >= 0, "the PlayerFrequentData check is unchanged");
	expect(!/addEventListener|ENTER_FRAME|Timer|setTimeout|getChildByName|getChildAt|hzFrameN %|new /.test(tick.body), "hzAmWaitTick adds no timer, listener, walk, frame modulo or allocation");
	expect((as.match(/hzAmWaitTick\(/g) || []).length === 3, "hzAmWaitTick has exactly the two callers");
}

finish("round4_ammo_wait");
