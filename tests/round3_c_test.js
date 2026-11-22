// 0.43.6 round 3 step C: build only what is shown. Card by card:
//   C1 Equipment: the style-1 card (hzBuildEqNew, hidden since v0.27) leaves the HUD once the v0.19 card is built;
//      its clip / reserve fields stay as detached data holders for hzE19Sync, and the weapon class still redraws the
//      visible icon.
// Run: node tests/round3_c_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { readAs, fnText, bind, baseHost, expect, finish } = require("./lib/r3");
const as = readAs();

function node(name, extra) {
	const n = Object.assign({ name: name, parent: null, kids: [], filters: ["glow"], visible: true, alpha: 1, x: 0, y: 0, text: "",
		graphics: { n: 0, clear() { this.n++; }, lineStyle() {} },
		get numChildren() { return this.kids.length; },
		addChild(c) { if (c.parent) c.parent.removeChild(c); c.parent = this; this.kids.push(c); return c; },
		removeChild(c) { const i = this.kids.indexOf(c); if (i >= 0) { this.kids.splice(i, 1); c.parent = null; } return c; },
		getChildAt(i) { return this.kids[i]; } }, extra || {});
	return n;
}
function eqHost(extra) {
	const ammo = node("HorizonAmmo_mc");
	const p = ammo.addChild(node("hzEqNew"));
	const h = baseHost(Object.assign({
		HorizonAmmo_mc: ammo, hzEqNew: p, hzEq19: ammo.addChild(node("hzEq19")),
		hzEqBody: p.addChild(node("hzEqBody")), hzEqWIcon: p.addChild(node("wicon")), hzEqAmmoIcon: p.addChild(node("aicon")),
		hzEqWeap: p.addChild(node("weap", { __tf: true })), hzEqType: p.addChild(node("type", { __tf: true })),
		hzEqCount: p.addChild(node("count", { __tf: true, text: "--" })), hzEqReserve: p.addChild(node("res", { __tf: true })),
		hzTexts: [], hzTextTf: [3], hzEqShedOn: false,
	}, extra || {}));
	h.hzTexts = [{ tf: h.hzEqWeap }, { tf: { other: 1 } }, { tf: h.hzEqType }, { tf: h.hzEqCount, tint: 0xF2B45F }, { tf: h.hzEqReserve }];
	bind(h, as, "hz55Under"); bind(h, as, "hz55Purge"); bind(h, as, "hzEqShedNew");
	return h;
}

// ---- C1 Equipment ----
{
	const h = eqHost();
	const body = h.hzEqBody, wi = h.hzEqWIcon, ai = h.hzEqAmmoIcon, count = h.hzEqCount, res = h.hzEqReserve;
	h.hzEqShedNew();
	expect(h.hzEqShedOn && h.hzEqNew.parent === null && h.HorizonAmmo_mc.kids.length === 1 && h.HorizonAmmo_mc.kids[0] === h.hzEq19, "C1: the hidden style-1 card leaves the Equipment card; the v0.19 card stays");
	expect(body.parent === null && wi.parent === null && ai.parent === null && body.graphics.n === 1 && wi.graphics.n === 1 && ai.graphics.n === 1 && wi.filters === null, "C1: panel, weapon art (glow filter too) and cartridge art are emptied and dropped");
	expect(h.hzEqBody === null && h.hzEqWIcon === null && h.hzEqAmmoIcon === null && h.hzEqWeap === null && h.hzEqType === null, "C1: references to the dropped parts are cleared");
	expect(h.hzEqCount === count && h.hzEqReserve === res && h.hzEqNew.kids.length === 2, "C1: the clip and reserve fields stay as data holders");
	expect(h.hzTexts.length === 3 && h.hzTexts.some((e) => e.tf === count && e.tint === 0xF2B45F) && h.hzTexts.some((e) => e.tf === res) && h.hzTexts.some((e) => e.tf.other), "C1: only the name and type registry entries are removed; the clip tint (read by hzE19Sync) stays");
	expect(Array.isArray(h.hzTextTf) && h.hzTextTf.length === 0, "C1: the hzTxtObj index is dropped");
	const n = h.hzTexts.length; h.hzEqShedNew();
	expect(h.hzTexts.length === n, "C1: runs once");
}
{
	const h = eqHost({ hzEq19: null });
	h.hzEqShedNew();
	expect(!h.hzEqShedOn && h.hzEqNew.parent === h.HorizonAmmo_mc && h.hzTexts.length === 5 && h.hzEqWIcon, "C1: without the v0.19 card nothing is torn down");
}
{
	// hzEqLayout after the shed: only the expanded state hzEqTick compares is kept
	const h = eqHost();
	bind(h, as, "hzEqLayout");
	h.hzEqShedNew();
	Object.assign(h, { hzArrange: false, hzFrameN: 100, hzEqExpandUntil: 150, hzEqExpanded: false });
	h.hzEqLayout();
	expect(h.hzEqExpanded === true, "C1: hzEqLayout keeps the expanded state (a swap's 3 s window)");
	h.hzFrameN = 200; h.hzEqLayout();
	expect(h.hzEqExpanded === false, "C1: and clears it after the window, so hzEqTick does not call it every frame");
	h.hzArrange = true; h.hzEqLayout();
	expect(h.hzEqExpanded === true, "C1: ARRANGE still counts as expanded");
}
{
	// the weapon class still reaches the visible icon
	const mk = (shed, wicon) => {
		let e19 = 0;
		const h = baseHost({ hzEqShedOn: shed, hzEqWIcon: wicon, hzEqKind: "rifle", hzE19DrawIcon: () => { e19++; },
			hzTxtMain: () => 0xFFFFFF, hzDarkText: () => false, hzWeapPath: () => {}, GlowFilter: function () {} });
		bind(h, as, "hzEqDrawWeapIcon");
		return { h, n: () => e19 };
	};
	const a = mk(true, null); a.h.hzEqDrawWeapIcon("pistol");
	expect(a.h.hzEqKind === "pistol" && a.n() === 1, "C1: after the shed a weapon swap still sets the class and redraws the visible icon");
	const b = mk(false, null); b.h.hzEqDrawWeapIcon("pistol");
	expect(b.h.hzEqKind === "rifle" && b.n() === 0, "C1: before the build (no art, no shed) it returns as before");
	const w = node("wicon"); const c = mk(false, w); c.h.hzEqDrawWeapIcon("laser");
	expect(c.h.hzEqKind === "laser" && c.n() === 1 && w.graphics.n === 1 && Array.isArray(w.filters) && w.filters.length === 1, "C1: without the shed the hidden art is drawn as before");
}
{
	// hzEqSync after the shed: clip / reserve text and tint are still written, then copied by hzE19Sync
	const h = eqHost();
	bind(h, as, "hzEqLayout"); bind(h, as, "hzEqSync");
	h.hzEqShedNew();
	let e19 = 0, tints = [];
	Object.assign(h, { hzWeapName: "Grendel", hzInvWeapName: "", hzEqFullName: "Grendel", hzEqKind: "rifle", hzEqHasAmmo: true, hzEqPct: false,
		hzEqClip: 5, hzEqTot: 40, hzMagCap: 30, hzMagMax: 30, hzArrange: false, hzFrameN: 0, hzEqExpandUntil: 0, hzEqLow: false, hzEqLastClip: 0,
		HZ_RED: 0xFF0000, hzEqKindOf: () => "rifle", hzEqDrawWeapIcon: () => {}, hzTxtTint: (tf, c) => tints.push([tf.name, c]),
		hzMix: () => 1, hzLight: () => false, hzE19Sync: () => { e19++; } });
	h.hzEqSync();
	expect(h.hzEqCount.text === "5" && h.hzEqReserve.text === "/ 35" && h.hzEqLow === true && e19 === 1, "C1: ammo updates still fill the clip / reserve holders and the low state, then sync the visible card");
	expect(tints.length === 2 && tints[0][0] === "count" && tints[0][1] === 0xF2B45F, "C1: the low-ammo tint is still set on the clip holder");
}
{
	const b = fnText(as, "hzBuild").body;
	const iS = b.indexOf("this.hz55ShedOld();"), iE = b.indexOf("this.hzEqShedNew();"), iF = b.indexOf("addEventListener(Event.ENTER_FRAME");
	expect(iS >= 0 && iE > iS && iF > iE, "C1: runs once at build, after the classic shed and before the frame handler");
	expect(/if\(this\.hzEqNew\) \{ this\.hzEqNew\.visible = false; \}/.test(fnText(as, "hzEqApplyStyle").body), "C1: the style-1 card was hidden on every path (nothing visible is removed)");
	const e19 = fnText(as, "hzE19Sync").body;
	expect(!/hzEqWeap|hzEqType|hzEqAmmoIcon|hzEqWIcon|hzEqBody\b/.test(e19), "C1: the visible card reads none of the dropped parts");
}
finish("round3 C");
