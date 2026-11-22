// 0.43.6 round 3 step C: build only what is shown. Card by card:
//   C1 Equipment: the style-1 card (hzBuildEqNew, hidden since v0.27) leaves the HUD once the v0.19 card is built;
//      its clip / reserve fields stay as detached data holders for hzE19Sync, and the weapon class still redraws the
//      visible icon.
//   C2 Character: the compact strip is built the first time the card is drawn in compact form; the default full card
//      never builds it. Same parts, order and styles as before (old-vs-new build compared below).
// Run: node tests/round3_c_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { readAs, stripComments, fnText, bind, mkFn, baseHost, expect, finish } = require("./lib/r3");
const { execSync } = require("child_process");
const as = readAs();
const asOld = stripComments(execSync("git show 0566589:actionscript/horizon_block.as", { cwd: __dirname + "/..", encoding: "utf8", maxBuffer: 1 << 26 }).replace(/\r\n/g, "\n"));

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
// ---- C2 Character ----
function charHost(src) {
	let id = 0;
	const log = [];
	const h = baseHost({ HZ_CH_W: 360, HZ_CH_H: 150, HZ_AMB: 0xF2A93B, HorizonChar_mc: null, hz26ChS: null, hz26ChsSp: null, hzTexts: [], syncs: 0, top: [] });
	h.mkSprite = function () { return node("sp" + (id++)); };
	const bindS = (name) => { h[name] = mkFn(h, [], fnText(src, name).body.replace(/new Sprite\(\)/g, "mkSprite()")); };
	h.hzT = function (p, txt, x, y, w, fs, face, tone, ls, align, col) { const t = p.addChild(node("tf" + (id++), { __tf: true, text: txt })); log.push([p === h.hz26ChS ? "S" : (p === h.hz26ChF ? "F" : "?"), txt, x, y, w, fs, face, tone, ls, align, col].join("|")); return t; };
	h.hzHdr19 = () => {}; h.hzSetSz = () => {}; h.addChild = (c) => { h.top.push(c); };
	h.hz26CharSync = () => { h.syncs++; };
	bindS("hz26BuildChar");
	if (src === as) bindS("hz26BuildCharS");
	h.log = log;
	return h;
}
{
	const o = charHost(asOld); o.hz26BuildChar();
	const n = charHost(as); n.hz26BuildChar();
	const c = n.HorizonChar_mc;
	expect(n.hz26ChS === null && c.kids.length === 1 && c.kids[0] === n.hz26ChF && n.syncs === 1 && n.top[0] === c && c.visible === false, "C2: the load-time build makes only the full card");
	expect(n.log.length === 8 && n.log.every((l) => l[0] === "F") && o.log.filter((l) => l[0] === "F").join("\n") === n.log.join("\n"), "C2: the full card's eight text fields are made exactly as before");
	n.hz26BuildCharS();
	const s = n.hz26ChS;
	expect(c.kids.length === 2 && c.kids[1] === s && s.visible === false && s.kids.length === 7 && s.kids[0] === n.hz26ChSG && s.kids[2] === n.hz26ChsXpBar, "C2: the strip is the card's last child, hidden, same seven parts in the same order");
	expect(o.log.filter((l) => l[0] === "S").join("\n") === n.log.filter((l) => l[0] === "S").join("\n") && n.log.length === 13, "C2: its five text fields have the same text, position, size, face, tone, spacing and color as before");
	const k = s.kids.length; n.hz26BuildCharS();
	expect(n.hz26ChS === s && s.kids.length === k && c.kids.length === 2, "C2: built once; later form switches reuse it");
}
{
	const sync = fnText(as, "hz26CharSync").body;
	const iB = sync.indexOf("this.hz26BuildCharS();"), iV = sync.indexOf("this.hz26ChF.visible = !cm;"), iS = sync.indexOf("if(!cm)");
	expect(iB > 0 && iV > iB && iS > iV && /if\(cm && !this\.hz26ChS\) \{ try \{ this\.hz26BuildCharS\(\);/.test(sync), "C2: the sync builds the strip on the first compact draw, before the form is chosen");
	expect(/if\(cm && \(!this\.hz26ChS \|\| !this\.hz26ChsSp\)\) \{ cm = false; \}/.test(sync) && /if\(this\.hz26ChS\) \{ this\.hz26ChS\.visible = cm; \}/.test(sync), "C2: a strip that failed to build leaves the full card; the strip's visibility is guarded");
	expect(sync.slice(0, iS).replace(/hz26ChS\b|hz26ChsSp/g, "") .indexOf("hz26Chs") < 0, "C2: no strip part is read before the compact branch");
	expect(/this\.hz26ChsXpBar && this\.hz26ChS && this\.hz26ChS\.visible/.test(fnText(as, "hz26CharBarsOnly").body), "C2: the XP ghost fade checks the strip exists");
	const tick = as.slice(as.indexOf("var chC:Boolean = Boolean(this.hz34C(\"Character\"));"), as.indexOf("var chC:Boolean = Boolean(this.hz34C(\"Character\"));") + 600);
	expect(/chC !== this\.hz26ChC[\s\S]*this\.hz26CharSync\(\)/.test(tick), "C2: a compact form change (F11 or global COMPACT) runs the sync, which builds the strip");
	const users = [];
	const re = /(?:private|public) function (\w+)\(/g; let m; const idx = [];
	while ((m = re.exec(as))) idx.push([m.index, m[1]]);
	idx.forEach((e, i) => { const seg = as.slice(e[0], i + 1 < idx.length ? idx[i + 1][0] : as.length); if (/hz26Chs\w|hz26ChS\b|hz26ChSG/.test(seg)) users.push(e[1]); });
	expect(users.filter((u) => u !== "hzT19Content").sort().join(",") === "hz26BuildCharS,hz26CharBarsOnly,hz26CharSync", "C2: only the builder, the sync and the bar fade touch the strip (" + users.join(",") + ")");
}
finish("round3 C");
