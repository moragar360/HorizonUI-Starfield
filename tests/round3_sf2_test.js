// 0.43.6 round 3 review SF-2: mutation-strength tests for steps B and C1.
// C1: the low-ammo pulse still drives the visible glow on hzE19Cnt (hzEqTick advances hzEqPulse; hzE19Tick turns it
// into the GlowFilter alpha). A frozen phase, or the pulse alpha written onto hzE19Cnt.alpha, fails here. hzEqCount
// (always hidden, detached) no longer gets alpha writes.
// B: hzSetFree empties only the drawn F11 body; a dropped saved value, hzSetPend or hzSetOrig fails here.
// Run: node tests/round3_sf2_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { readAs, fnText, mkFn, bind, baseHost, expect, finish } = require("./lib/r3");
const as = readAs();

// a stub that records every property write
function watched(base, log, tag) {
	return new Proxy(base, { set(t, k, v) { log.push(tag + "." + String(k)); t[k] = v; return true; } });
}
// ---------- C1 ----------
function eqHost(log) {
	const cnt = watched({ text: "3", filters: [] }, log, "hzE19Cnt");
	const eqCount = watched({ text: "3" }, log, "hzEqCount");
	function GlowFilter(color, alpha) { this.color = color; this.alpha = alpha; }
	const h = baseHost({ hzEqNew: {}, hzArrange: false, hzFrameN: 100, hzEqExpandUntil: 0, hzEqExpanded: false, hzEqLow: true,
		hzEqCount: eqCount, hzEqPulse: 0, hzEq19: { visible: true }, hzE19Cm: false, hzE19Cnt: cnt, hzE19Glow: null, hzE19GlowA: null,
		hzE19GlowK: -1, hzTextShadow: false, HZ_AMB: 0xF2B45F, GlowFilter, Math,
		hz34C: () => false, hzE19Sync: () => { log.push("sync"); }, hzEqLayout: () => {}, hzDarkText: () => false,
		hzIconCol: (c) => c, hzTyFilters: () => [] });
	bind(h, as, "hzEqTick"); bind(h, as, "hzE19Tick");
	return h;
}
{
	const log = [];
	const h = eqHost(log);
	const alphas = [], phases = [];
	for (let i = 0; i < 26; i++) { h.hzEqTick(); phases.push(h.hzEqPulse); alphas.push(h.hzE19Glow ? h.hzE19Glow.alpha : NaN); }
	expect(phases.every((p, i) => Math.abs(p - 0.25 * (i + 1)) < 1e-9), "low ammo: hzEqPulse advances 0.25 per tick");
	const distinct = new Set(alphas.map((a) => a.toFixed(4))).size;
	const lo = Math.min(...alphas), hi = Math.max(...alphas);
	expect(distinct > 10 && lo < 0.4 && hi > 0.75, "the visible glow alpha pulses across ticks (" + lo.toFixed(2) + ".." + hi.toFixed(2) + ", " + distinct + " values)");
	expect(alphas.every((a, i) => Math.abs(a - (0.35 + 0.45 * (0.5 + 0.5 * Math.sin(phases[i])))) < 1e-9), "glow alpha follows the phase (same curve as before)");
	expect(h.hzE19Cnt.filters === h.hzE19GlowA && h.hzE19GlowA[0] === h.hzE19Glow, "the glow filter is applied to the visible count");
	expect(!log.some((w) => w === "hzE19Cnt.alpha"), "the pulse alpha is never written onto hzE19Cnt.alpha");
	expect(!log.some((w) => w === "hzEqCount.alpha"), "the detached hzEqCount gets no alpha writes");
	h.hzEqLow = false; const p = h.hzEqPulse; h.hzEqTick();
	expect(h.hzEqPulse === p, "ammo not low: the phase holds");
	const ib = as.indexOf("hzEqCount.alpha");
	expect(ib < 0, "no hzEqCount.alpha write is left in the source");
}
// ---------- B ----------
function spr(log, tag) {
	return watched({ kids: ["a", "b"], get numChildren() { return this.kids.length; }, removeChildAt(i) { this.kids.splice(i, 1); }, graphics: { clear() {} } }, log, tag);
}
{
	const log = [];
	const pend = { hzCardColor: 0x336699, hzTextScale: 1.2, hzShowAmmo: true, hzStyle: 1 };
	const orig = { hzCardColor: 0x112233, hzTextScale: 1.0, hzShowAmmo: false, hzStyle: 0 };
	const vals = { hzCardColor: 0x112233, hzTextScale: 1.0, hzShowAmmo: false, hzStyle: 0, hzAmmoType: true, hzAmmoMag: true };
	const snap = JSON.stringify({ pend, orig, vals });
	const base = baseHost(Object.assign({ hzSetIsOpen: false, hzSetPend: pend, hzSetOrig: orig, hzSetHits: [1, 2, 3] }, vals));
	base.hzSetBody = spr(log, "hzSetBody"); base.hzSetKeyOv = spr(log, "hzSetKeyOv");
	const h = watched(base, log, "host");
	mkFn(h, [], fnText(as, "hzSetFree").body)();
	const now = { pend: base.hzSetPend, orig: base.hzSetOrig, vals: {} };
	for (const k of Object.keys(vals)) now.vals[k] = base[k];
	expect(base.hzSetPend === pend && base.hzSetOrig === orig, "hzSetFree keeps the hzSetPend / hzSetOrig objects");
	expect(JSON.stringify(now) === snap, "hzSetFree keeps every pending, original and current setting value");
	const hostWrites = log.filter((w) => w.startsWith("host."));
	expect(hostWrites.length === 1 && hostWrites[0] === "host.hzSetHits", "the only field hzSetFree assigns is hzSetHits (" + hostWrites.join(",") + ")");
	expect(base.hzSetBody.kids.length === 0 && base.hzSetHits.length === 0, "and it still empties the body and the hit list");
}
finish("round3 SF-2");
