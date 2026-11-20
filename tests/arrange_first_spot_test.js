// 0.43.4 item 3 tests: an ARRANGE CARDS card lands exactly on its saved spot the first time it appears, with zero
// settle. Run: node tests/arrange_first_spot_test.js   (HZ_HUD_SRC=<file> / HZ_COMMS_SRC=<file> run it on other
// sources, the mutation check: on the 0.43.3.2 sources it must fail.)
// HUD (horizon_block.as): hzLayout places every placed card from its last known size. A card that had not drawn yet
// came up from the fallback size, so an R / B / C anchored card sat a few units off its saved spot until a later
// relayout (the XP toast and the enemy card never asked for one). The fix: the size-change edge (hzSetSz) re-resolves
// that one card (hzLayNow) with the same rule. Runs the production hzSetSz / hzLayNow / hzLayKeyOf / hz30Resolve /
// hz30Inset / hz27Clamp / hzCW / hzCH / hzPlace (types stripped) for all 13 cards and every anchor.
// Comms (hzc_block.as): a HUD message card with no game line to follow (hzcRxAnchor) started on the live bounds of the
// game's message column; with a saved HudMessagesX/Y it now starts on the stable home, so the layer offset puts it on
// the saved spot, with no bounds read. Author: Moragar. Last modified: 2026-11-20.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const HUD = read(process.env.HZ_HUD_SRC || path.join(root, "actionscript", "horizon_block.as"));
const COMMS = read(process.env.HZ_COMMS_SRC || path.join(root, "actionscript", "comms", "hzc_block.as"));
let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src);
	if (!m) return null;
	const brace = m.index + m[0].length - 1;
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function toJs(src, name) {
	const f = fnText(src, name);
	if (!f) return null;
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (var $1 of ")
		.replace(/var (\w+):[\w*]+/g, "var $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/new (Point|Rectangle)\(/g, "new $1(")
		.replace(/(^|[^.\w"])(HZC?_\w*)\b/g, "$1this.$2");
	return new Function(...params, body);
}
global.Number = Number; global.String = String; global.int = (v) => v | 0;
global.Point = class { constructor(x, y) { this.x = x; this.y = y; } };
global.Rectangle = class { constructor(x, y, w, h) { this.x = x; this.y = y; this.width = w; this.height = h; } get right() { return this.x + this.width; } get bottom() { return this.y + this.height; } };

// ---- HUD cards ----
const CARDS = [["Jetpack", "HorizonCard_mc"], ["Vitals", "HorizonVitals_mc"], ["Planet", "HorizonEnv_mc"], ["Afflictions", "HorizonAffl_mc"], ["Ammo", "HorizonAmmo_mc"],
	["Quests", "HorizonQuest_mc"], ["Quests", "HorizonCompactQuest_mc"], ["Compass", "HorizonCompass_mc"], ["Compact", "HorizonCompact_mc"], ["Character", "HorizonChar_mc"],
	["Enemy", "HorizonEnemy_mc"], ["Stealth", "HorizonStealth_mc"], ["XpToast", "HorizonXp_mc"], ["Hazard", "HorizonHazard_mc"]];
function hudHost() {
	const h = { hzSz: [], hzLay: {}, hzFades: [], hzMargin: 40, hzScrH: 1440, hzHudScale: 1, hzArrDrag: null, hzLaidOut: true, hzLayEver: true, HZ_SCALE: 1, HZ_W: 330, places: 0 };
	for (const [, clip] of CARDS) h[clip] = { name: clip, x: 0, y: 0, scaleX: 1.1, scaleY: 1.1, width: 0, height: 0 };
	h.hz31PxKey = () => null; h.hzV19 = () => true; h.hz27CmpTop = () => 28; h.hz27LayM = () => 40;
	for (const n of ["hzSetSz", "hzLayNow", "hzLayKeyOf", "hz30Resolve", "hz30Inset", "hz27Clamp", "hzCW", "hzCH", "hzPlace", "hz30Anchor"]) { const f = toJs(HUD, n); if (f) h[n] = f.bind(h); }
	const pl = h.hzPlace; h.hzPlace = function (c, x, y) { this.places++; return pl(c, x, y); };
	return h;
}
const TL = new Point(0, 0), BR = new Point(2560, 1440);
// what hzLayout's user-layout loop does for one card (the same expressions)
function layoutOne(h, lk, c) {
	const s = h.HZ_SCALE * h.hzHudScale;
	const cw = h.hzCW(c) > 1 ? h.hzCW(c) : h.HZ_W * s;
	const ch = h.hzCH(c) > 1 ? h.hzCH(c) : 60 * s;
	const p = h.hz30Resolve(lk, h.hzLay[lk], cw, ch, TL, BR);
	h.hzPlace(c, p.x, p.y);
}
const SIZES = { Jetpack: [212, 72], Vitals: [330, 124], Planet: [300, 84], Afflictions: [190, 48], Ammo: [470, 92], Quests: [360, 140], Compass: [520, 40], Compact: [420, 114], Character: [360, 96], Enemy: [380, 74], Stealth: [140, 140], XpToast: [184, 32], Hazard: [260, 44] };
for (const [ax, ay] of [["R", "B"], ["C", "C"], ["R", "T"], ["L", "B"], ["L", "T"]]) {
	for (const [lk, clip] of CARDS) {
		const h = hudHost();
		h.hzLayTL = TL; h.hzLayBR = BR;   // the rect of the last good hzLayout
		h.hzLay[lk] = { nx: true, ny: true, ax, ay, dx: 37, dy: 23 };
		const c = h[clip];
		layoutOne(h, lk, c);   // the first hzLayout: the card has not drawn, so the fallback size
		const [w, hh] = SIZES[lk];
		h.hzSetSz(c, w, hh);   // the first draw: content and size are final (this is the edge)
		const first = [c.x, c.y];
		layoutOne(h, lk, c);   // what any later relayout does
		const settled = [c.x, c.y];
		const ok = first[0] === settled[0] && first[1] === settled[1];
		if (ax !== "L" || ay !== "T") expect(ok, lk + " (" + clip + ") " + ax + "/" + ay + ": first appearance " + first + " = saved spot " + settled + " (zero settle)");
		else expect(ok, lk + " (" + clip + ") L/T: unchanged (no size term)");
	}
}
{
	// an unchanged size is not an edge; ARRANGE drag and no saved layout leave the card alone; before any layout: nothing
	const h = hudHost(); h.hzLayTL = TL; h.hzLayBR = BR;
	h.hzLay.XpToast = { nx: true, ny: true, ax: "R", ay: "B", dx: 0, dy: 0 };
	h.hzSetSz(h.HorizonXp_mc, 184, 32);
	const p0 = h.places; h.hzSetSz(h.HorizonXp_mc, 184, 32);
	expect(h.places === p0, "the same size again: no placement (edge only)");
	h.hzArrDrag = "XpToast"; h.hzSetSz(h.HorizonXp_mc, 200, 32);
	expect(h.places === p0, "the card being dragged in ARRANGE CARDS is left to the drag");
	h.hzArrDrag = null; h.hzSetSz(h.HorizonEnemy_mc, 380, 74);
	expect(h.places === p0, "a card at its default spot (no saved layout) is left to hzLayout");
	const h2 = hudHost(); h2.hzLay.XpToast = { nx: true, ny: true, ax: "R", ay: "B", dx: 0, dy: 0 };
	h2.hzSetSz(h2.HorizonXp_mc, 184, 32);
	expect(h2.places === 0, "before the first good hzLayout nothing is placed (that layout places it)");
	const lay = fnText(HUD, "hzLayout");
	expect(lay && /this\.hzLayTL = tl;/.test(lay.body) && /this\.hzLayBR = br;/.test(lay.body), "hzLayout keeps the rect it used");
	const nowB = fnText(HUD, "hzLayNow");
	expect(nowB && !/getBounds|\.width|\.height|addEventListener|ENTER_FRAME|Timer/.test(nowB.body.replace(/hzCW|hzCH/g, "")), "hzLayNow reads no bounds and adds no listener or timer");
	const keyOf = fnText(HUD, "hzLayKeyOf");
	expect(keyOf && !/Watch|hz31Px|hz43/.test(keyOf.body), "the watch and the Comms stand-ins keep their own placement");
}

// ---- Comms: HUD messages card with no game line ----
function commsHost(cfg, bounds) {
	const h = { hzcCfg: Object.assign({ TextScale: 1, HudScale: 1, Margin: 40 }, cfg), hzcRxLayer: { x: 0, y: 0 }, hzcRxDbgOn: false, hzcMsgHomeLogged: true, HZC_LRG: false, bounds: 0 };
	h.hzcVis = () => new Rectangle(0, 0, 2560, 1440);
	for (const n of ["hzcMsgArranged", "hzcRxAnchor", "hzcMsgLayout", "hzcMsgHome", "hzcAnchor", "hzcCardZ"]) { const f = toJs(COMMS, n); if (f) h[n] = f.bind(h); }
	const m = { getBounds() { h.bounds++; return bounds; } };
	return { h, m };
}
{
	// the game's column sits a few units off the stable home (and moves as lines come and fade)
	const vr = new Rectangle(0, 0, 2560, 1440);
	const W = 360, home = { x: vr.right - W - 40, y: vr.y + 80 };
	const colB = new Rectangle(home.x + 7, home.y - 5, W, 120);
	for (const [xs, ys] of [["R60", "T20"], ["L300", "B200"], ["C0", "C0"], ["R0", "-1"]]) {
		const { h, m } = commsHost({ HudMessagesX: xs, HudMessagesY: ys }, colB);
		h.hzcMsgLayout();
		const e = { c: { x: 0, y: 0, visible: false, alpha: 0 }, w: 300, h: 50 };
		h.hzcRxAnchor(e, m);
		const gx = h.hzcRxLayer.x + e.c.x, gy = h.hzcRxLayer.y + e.c.y;
		const sx = xs === "-1" ? home.x : h.hzcAnchor(xs, "x", W, vr.x, vr.right);
		const sy = ys === "-1" ? home.y : h.hzcAnchor(ys, "y", 56, vr.y, vr.bottom);
		const want = [Math.round(sx + W - e.w), Math.round(sy)];
		expect(gx === want[0] && gy === want[1] && e.c.visible, "HUD message " + xs + "/" + ys + ": first card at " + [gx, gy] + " = saved spot (right edges together) " + want);
		expect(h.bounds === 0, "HUD message " + xs + "/" + ys + ": no bounds read of the game's message column");
	}
	const { h, m } = commsHost({ HudMessagesX: "-1", HudMessagesY: "-1" }, colB);
	h.hzcMsgLayout();
	const e = { c: { x: 0, y: 0, visible: false, alpha: 0 }, w: 300, h: 50 };
	h.hzcRxAnchor(e, m);
	expect(h.hzcRxLayer.x === 0 && e.c.x === Math.round(colB.x + colB.width - e.w) && e.c.y === Math.round(colB.y), "no saved spot: unchanged, the card follows the game's column");
}
console.log("arrange first spot: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
