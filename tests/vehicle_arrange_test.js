// Vehicle exit pill in ARRANGE CARDS and in a vehicle (0.43.3.2 batch e, fixed in batch k). Run: node tests/vehicle_arrange_test.js
// Runs the production hzVeh* helpers and hz42VehTick (types stripped) on a small host and checks:
//  1. batch k home: a fixed bottom-right spot from the visible area only (right - HZ_VEH_HR, bottom - HZ_VEH_HB), the
//     same in ARRANGE on foot and in a vehicle, on 16:9 and ultrawide views, never in the left half;
//  2. batch k regression: a bogus bottom-left getBounds of the game's button (x about 20) or a hidden / Off-frame
//     HUDVehicle_mc never moves the pill (on foot or in a vehicle), and the button is never measured;
//  3. arrange on foot before any vehicle visit, save, restart, enter a vehicle: the pill is at the exact arranged
//     spot, with zero jump over many frames; dragging and redrawing in ARRANGE never snaps back; RESET = home;
//     offsets clamp and the pill stays inside the visible area;
//  4. the settings plumbing: INI reader, current values, live apply, writer lines, HZ_SET_DEF and default.ini (0 / 0);
//  5. ARRANGE: the list entry, store, CANCEL restore, SAVE keep, RESET to 0 / 0, hand-back to the vehicle tick;
//  6. edge-only: no getBounds / localToGlobal on the game's button anywhere in the pill code, the per-frame tick only
//     compares numbers and places on an edge; no timer, listener, enterFrame or tree search.
// The same file run against the a78d8ec source fails sections 1 - 3 and 6 (the mutation check for batch k).
// Author: Moragar. Last modified: 2026-11-19 (batch k).
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const ini = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src);
	if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1;
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
const hasFn = (name) => new RegExp("(?:private|public) function " + name + "\\(").test(as);
const codeOnly = (s) => s.replace(/\/\/.*$/gm, "");
function toJs(name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
	const b = f.body
		.replace(/var (\w+):[\w*.]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/([^.\w"])HZ_(\w+)\b/g, "$1this.HZ_$2")
		.replace(/([^.\w])addChild\(/g, "$1this.addChild(");
	return new Function(...params, b);
}
const constOf = (name, dflt) => { const m = new RegExp("private static const " + name + ":Number = ([\\d.]+);").exec(as); return m ? Number(m[1]) : dflt; };
class Point { constructor(x, y) { this.x = x; this.y = y; } }
class Rectangle { constructor(x, y, w, h) { this.x = x; this.y = y; this.width = w; this.height = h; } get left() { return this.x; } get top() { return this.y; } get right() { return this.x + this.width; } get bottom() { return this.y + this.height; } }
global.Point = Point; global.Rectangle = Rectangle;
global.int = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)) | 0; };
global.Sprite = class { constructor() { this.x = 0; this.y = 0; this.visible = true; this.parent = null; } };
global.uint = (v) => Number(v) >>> 0;
const sprite = () => new global.Sprite();

const HR = constOf("HZ_VEH_HR", NaN), HB = constOf("HZ_VEH_HB", NaN);
const W = 120, H = 42;   // the pill size the draw stub reports
// every pill function that exists in this source (the a78d8ec source has hz42VehPlace and no hzVehSpot / hzVehPlace)
const FNS = ["hzVehCX", "hzVehCY", "hzVehHome", "hzVehArrSync", "hzVehPut", "hzVehFromPx", "hzVehIni", "hzVehSetCur", "hzVehSetLive", "hzVehIniLines",
	"hz42VehTick", "hz42VehPlace", "hzVehSpot", "hzVehPlace"].filter(hasFn);
// the game's button: bounds as given (the bogus bottom-left box by default), Visible = shown, getBounds / localToGlobal counted
function button(opt) {
	const o = Object.assign({ rect: new Rectangle(20, 1000, 60, 30), visible: true, stage: {} }, opt || {});
	const b = { Visible: o.visible, stage: o.stage, width: o.rect.width, height: o.rect.height, measured: 0,
		getBounds() { this.measured++; return o.rect; },
		localToGlobal(p) { this.measured++; return new Point(o.rect.x + p.x, o.rect.y + p.y); } };
	return b;
}
function host(btn, vis) {
	const vr = vis || new Rectangle(0, 0, 1920, 1080);
	const h = {
		HZ_VEH_KEY: "VehicleExit", HZ_VEH_HR: HR, HZ_VEH_HB: HB, HZ_ACCENT: 0x37c8e6,
		hzVehX: 0, hzVehY: 0, hzVehHX: NaN, hzVehHY: NaN, hzVehArr: false, hzVehKs: "", hzVehKf: "", hzVehSig: "x",
		hzVehW: 0, hzVehH: 42, hzVehOn: true, hzVehIn: -1, hzVehFail: 0, hzArrange: false, hz41SA: false, hzSetPend: null, hzArr_mc: null,
		hzVehPx: null, hzVehPlX: NaN, hzVehPlY: NaN, hzVehPlW: NaN, hzVehPlH: NaN, hzVehPlR: null, hzVisR: null,
		hzTextScale: 1, hzFontFace: 1, hzHeaderStyle: 0, hzCardOpacity: 1,
		draws: [], kids: [], places: 0, btn: btn,
		hzVis() { this.hzVisR = vr; return vr; },
		hz42VehBtn() { return this.btn; },
		hz42VehShown() { return true; },
		hz42VehProg() { return 0; },
		hz42VehKey() { return ["E", ""]; },
		hz42VehHideVan() { },
		hz42VehFront() { },
		hz42VehDraw(k, f, p, d) { this.draws.push([k, f, p, d]); this.hzVehW = W; this.hzVehH = H; },
		addChild(c) { c.parent = this; this.kids.push(c); },
		globalToLocal(p) { return p; },
	};
	for (const n of FNS) h[n] = toJs(n);
	for (const n of ["hz42VehPlace", "hzVehPlace"]) if (h[n]) { const f = h[n]; h[n] = function (...a) { this.places++; return f.apply(this, a); }; }
	return h;
}
const center = (h) => [h.hzVehPx.x + Math.round(h.hzVehW / 2), h.hzVehPx.y + Math.round(h.hzVehH / 2)];
const inVehicle = (h, frames) => { h.hzVehIn = 1; for (let i = 0; i < (frames || 1); i++) h.hz42VehTick(); };

// ---- 1. the home: a fixed bottom-right spot from the visible area ----
{
	expect(HR === 420 && HB === 76, "HZ_VEH_HR / HZ_VEH_HB are the batch k home (420 from the right, 76 from the bottom)");
	const h = host(button());
	h.hzVehW = W; h.hzVehH = H;
	const hp = h.hzVehHome();
	expect(hp.x === 1500 && hp.y === 1004, "1920 x 1080: home center (1500, 1004), where in-game screenshots show the game's prompt and the 0 / 0 pill (" + hp.x + ", " + hp.y + ")");
	expect(h.btn.measured === 0, "the home never measures the game's button");
	const uw = host(button(), new Rectangle(-320, 0, 2560, 1080));
	const hu = uw.hzVehHome();
	expect(hu.x === 2240 - 420 && hu.y === 1004 && uw.btn.measured === 0, "ultrawide visible area (-320 .. 2240): home follows the visible right edge (" + hu.x + ", " + hu.y + ")");
	const fb = host(null); const hf = fb.hzVehHome();
	expect(hf.x === 1500 && hf.y === 1004, "no game button at all: the same home (it does not depend on the button)");
}
// ---- 2. regression: a bogus bottom-left getBounds or a hidden / Off-frame HUDVehicle_mc never pulls the pill ----
{
	// on foot, ARRANGE, the button on its Off frame (hidden, bounds near x = 20 at the bottom left)
	const h = host(button({ visible: false }));
	h.hzArrange = true;
	h.hzVehArrSync();
	const [cx, cy] = center(h);
	expect(cx === 1500 && cy === 1004, "ARRANGE on foot (HUDVehicle_mc Off, bogus bounds x = 20): the pill is at the home, not the bottom left (" + cx + ", " + cy + ")");
	expect(h.hzVehPx.x > 960, "ARRANGE on foot: the pill is in the right half");
	expect(h.btn.measured === 0, "ARRANGE on foot: the game's button is never measured (" + h.btn.measured + ")");
	// in a vehicle with the bogus bounds
	const v = host(button());
	inVehicle(v, 5);
	const [vx, vy] = center(v);
	expect(v.hzVehPx.visible && vx === 1500 && vy === 1004, "in a vehicle with bogus bottom-left bounds: the pill is at the home (" + vx + ", " + vy + ")");
	expect(v.btn.measured === 0, "in a vehicle: the game's button is never measured (" + v.btn.measured + " calls over 5 frames)");
	// a hidden HUDVehicle_mc in a vehicle: the pill hides, and comes back at the same spot
	v.btn.Visible = false; v.hz42VehTick();
	expect(!v.hzVehPx.visible, "HUDVehicle_mc hidden: the pill hides");
	v.btn.Visible = true; v.hz42VehTick();
	expect(v.hzVehPx.visible && center(v)[0] === 1500 && center(v)[1] === 1004, "shown again: the same spot");
}
// ---- 3. arrange on foot, save, restart, enter a vehicle: the exact spot, zero jump ----
{
	const a = host(button({ visible: false }));
	a.hzArrange = true; a.hzSetPend = {};
	a.hzVehArrSync();
	const c = a.hzVehPx;
	c.x -= 263; c.y -= 118;   // drag up and left
	const want = [c.x, c.y];
	a.hzVehFromPx(c);
	expect(a.hzVehPx.x === want[0] && a.hzVehPx.y === want[1], "drag in ARRANGE: the pill stays where it was dropped (" + a.hzVehPx.x + ", " + a.hzVehPx.y + ")");
	let snap = false;
	for (let i = 0; i < 5; i++) { a.hzVehArrSync(); if (a.hzVehPx.x !== want[0] || a.hzVehPx.y !== want[1]) snap = true; }
	expect(!snap, "ARRANGE redraws (hzArrDraw -> hzVehArrSync) never snap it back");
	for (const [dx, dy] of [[1, 0], [0, -1], [17, 9], [-40, 33]]) {   // nudges and more drags, each a round trip
		c.x += dx; c.y += dy; const w2 = [c.x, c.y]; a.hzVehFromPx(c);
		if (a.hzVehPx.x !== w2[0] || a.hzVehPx.y !== w2[1]) snap = true;
		want[0] = w2[0]; want[1] = w2[1];
	}
	expect(!snap, "every nudge / drag round trip (pill -> offsets -> pill) is exact to the unit");
	expect(a.hzSetPend.VehicleExitX === a.hzVehX && a.hzSetPend.VehicleExitY === a.hzVehY, "SAVE gets the offsets (" + a.hzVehX + ", " + a.hzVehY + ")");
	a.hzArrange = false; a.hzVehArrSync();
	// save, restart (a new HUD), load the saved values, enter a vehicle with the bogus bounds
	const o = {}; a.hzVehSetCur(o);
	const lines = []; a.hzVehIniLines(lines, {});
	const v = host(button());
	for (const ln of lines.slice(1)) { const [k, val] = ln.split("="); v.hzVehIni(k.toLowerCase(), Number(val)); }
	expect(v.hzVehX === o.VehicleExitX && v.hzVehY === o.VehicleExitY, "the saved INI lines load back");
	inVehicle(v, 1);
	expect(v.hzVehPx.x === want[0] && v.hzVehPx.y === want[1], "in a vehicle after the restart: the exact arranged spot (" + v.hzVehPx.x + ", " + v.hzVehPx.y + " vs " + want.join(", ") + ")");
	let jump = false;
	for (let i = 0; i < 120; i++) {
		v.btn = button({ rect: new Rectangle(20 + (i % 7) * 200, 1000 - (i % 5) * 150, 60, 30) });   // the bounds change every frame
		v.hz42VehTick();
		if (v.hzVehPx.x !== want[0] || v.hzVehPx.y !== want[1]) jump = true;
	}
	expect(!jump, "120 frames in the vehicle with bounds that change every frame: zero jump");
	// the same HUD session: ARRANGE again while in the vehicle and back
	v.hzArrange = true; v.hzVehArrSync();
	expect(v.hzVehPx.x === want[0] && v.hzVehPx.y === want[1], "ARRANGE opened in the vehicle: the same spot");
	v.hzArrange = false; v.hzVehArrSync(); v.hz42VehTick();
	expect(v.hzVehPx.x === want[0] && v.hzVehPx.y === want[1], "ARRANGE closed, back in the vehicle tick: the same spot");
	// RESET = home, in ARRANGE and in the vehicle
	v.hzArrange = true; v.hzVehPut(0, 0);
	expect(center(v)[0] === 1500 && center(v)[1] === 1004, "RESET (0 / 0): the home");
	v.hzArrange = false; v.hzVehArrSync(); v.hz42VehTick();
	expect(center(v)[0] === 1500 && center(v)[1] === 1004, "RESET, then in the vehicle: the home");
	// clamps: offsets and the visible area
	const k = host(button());
	expect(k.hzVehCX(5000) === 1000 && k.hzVehCX(-5000) === -1000 && k.hzVehCY(5000) === 600 && k.hzVehCY("x") === 0 && k.hzVehCX(12.6) === 13, "offsets clamp to -1000..1000 / -600..600, whole units, junk = 0");
	k.hzVehX = 1000; k.hzVehY = -600; inVehicle(k, 1);
	expect(k.hzVehPx.x + W <= 1920 && k.hzVehPx.y + H <= 1080 && k.hzVehPx.x === 1920 - W && k.hzVehPx.y === 1080 - H, "a far offset keeps the whole pill inside the visible area (" + k.hzVehPx.x + ", " + k.hzVehPx.y + ")");
	const k2 = host(button()); k2.hzVehX = -1000; k2.hzVehY = 600; inVehicle(k2, 1);
	expect(k2.hzVehPx.x >= 0 && k2.hzVehPx.y >= 0, "a far left / up offset also keeps it inside the visible area (" + k2.hzVehPx.x + ", " + k2.hzVehPx.y + ")");
	expect(/X \+ = right/.test(lines[0]) && k.hzVehX === 1000, "X + = right, Y + = up (writer comment, offsets)");
	const r = host(button()); r.hzVehX = 100; r.hzVehY = 50; inVehicle(r, 1);
	expect(center(r)[0] === 1600 && center(r)[1] === 954, "an offset (100, 50) moves the center right 100 and up 50");
}
// ---- 4. settings plumbing ----
{
	const h = host(null);
	expect(h.hzVehIni("vehicleexitx", 40) && h.hzVehIni("vehicleexity", -30) && h.hzVehX === 40 && h.hzVehY === -30 && !h.hzVehIni("vehicleexitpill", 1), "INI reader: VehicleExitX / VehicleExitY (any section, like the rest of the HUD parser)");
	const o = {}; h.hzVehSetCur(o);
	expect(o.VehicleExitX === 40 && o.VehicleExitY === -30, "current values (settings save and presets)");
	h.hzVehSetLive({ VehicleExitX: 7, VehicleExitY: 8 });
	expect(h.hzVehX === 7 && h.hzVehY === 8, "live apply (F11 APPLY, preset load, DEFAULTS)");
	h.hzVehSetLive({});
	expect(h.hzVehX === 7 && h.hzVehY === 8, "a preset without the keys keeps the current spot");
	const a = []; h.hzVehIniLines(a, {});
	expect(a.length === 3 && a[1] === "VehicleExitX=7" && a[2] === "VehicleExitY=8" && a[0].charAt(0) === ";", "writer lines");
	expect(a[0].indexOf("default bottom-right spot") > 0 && a[0].indexOf("game's prompt") < 0, "writer comment: offset from the default bottom-right spot");
	const sd = JSON.parse(/HZ_SET_DEF:Object = (\{[^;]*\});/.exec(as)[1]);
	expect(sd.VehicleExitX === 0 && sd.VehicleExitY === 0 && sd.VehicleExitPill === 1, "HZ_SET_DEF: 0 / 0 (DEFAULTS = the default spot)");
	expect(/\nEquipmentExtras=1\n; Vehicle exit pill spot[^\n]*\nVehicleExitX=0\nVehicleExitY=0\n; Quick menu[^\n]*\nQuickMenuHorizon=1\n(?:(?:; [^\n]*|QuickMenu[A-Za-z0-9]+=[^\n]*)\n)*\n\[Effects\]/.test(ini), "default.ini [Cards Extra]: VehicleExitX=0 / VehicleExitY=0, where the writer puts them");
	expect(ini.indexOf("; Vehicle exit pill spot (ARRANGE CARDS): offset from the default bottom-right spot in HUD units (X + = right, Y + = up); 0 / 0 = the default spot\n") >= 0, "default.ini comment matches the writer");
	expect(/this\.hzVehIni\(k,nv\)/.test(fnText(as, "hz26Ini").body) && /this\.hzVehSetCur\(o\)/.test(fnText(as, "hz26SetCur").body) && /this\.hzVehSetLive\(p\)/.test(fnText(as, "hz26SetLive").body) && /a\.push\("EquipmentExtras=[^\n]*\n\s*this\.hzVehIniLines\(a,p\)/.test(as), "the hz26 settings chain reads, writes and applies the offsets");
}
// ---- 5. ARRANGE ----
{
	const h = host(button({ visible: false }));
	h.hzArrange = true; h.hzVehKs = "R";
	h.hzArr_mc = { parent: null }; h.hzArr_mc.parent = h;
	h.hzVehArrSync();
	expect(h.hzVehArr && h.hzVehPx && h.hzVehPx.visible && h.draws.length === 1 && h.draws[0][0] === "R" && h.draws[0][2] === 0, "ARRANGE: the pill shows idle with the last key seen, drawn once");
	h.hzVehArrSync();
	expect(h.draws.length === 1, "redraws of the ARRANGE screen only place it (no redraw)");
	const k2 = h.kids.length; expect(h.kids[k2 - 1] === h.hzArr_mc, "the ARRANGE layer stays on top of the pill");
	h.hzSetPend = {};
	h.hzVehPut(11, 22);
	expect(h.hzSetPend.VehicleExitX === 11 && h.hzSetPend.VehicleExitY === 22, "a move also goes into the pending F11 values (SAVE writes it)");
	h.hzArrange = false; h.hzVehArrSync();
	expect(!h.hzVehArr && !h.hzVehPx.visible && h.hzVehSig === "", "leaving ARRANGE hands the pill back to the vehicle tick (signature cleared: it redraws in a vehicle)");
	const h2 = host(null); h2.hzArrange = true; h2.hzVehOn = false; h2.hzVehArrSync();
	expect(!h2.hzVehArr && h2.hzVehPx === null, "VehicleExitPill=0: no ARRANGE entry");

	const list = fnText(as, "hzArrList").body, enter = fnText(as, "hzArrEnter").body, exit = fnText(as, "hzArrExit").body;
	const reset = fnText(as, "hzArrReset").body, store = fnText(as, "hzArrStore").body, draw = fnText(as, "hzArrDraw").body;
	expect(/"k":HZ_VEH_KEY,"n":this\.hzLt\("VEHICLE EXIT PILL"\),"c":this\.hzVehPx/.test(list) && /this\.hzVehArr && this\.hzVehPx != null/.test(list), "hzArrList: VEHICLE EXIT PILL entry while the pill is the proxy");
	expect(/this\.hzVehOrig = \{"x":this\.hzVehX,"y":this\.hzVehY\}/.test(enter) && /this\.hzVehArrSync\(\)/.test(enter), "hzArrEnter: keeps the offsets for CANCEL, shows the pill");
	const saveIdx = exit.indexOf("if(save)"), elseIdx = exit.indexOf("else", saveIdx);
	expect(exit.indexOf("this.hzVehOrig = null;", saveIdx) < elseIdx && /this\.hzVehPut\(this\.hzVehOrig\.x,this\.hzVehOrig\.y\)/.test(exit.slice(elseIdx)) && /this\.hzVehArrSync\(\)/.test(exit), "hzArrExit: SAVE keeps, CANCEL restores, then hands the pill back");
	expect(/this\.hzVehPut\(0,0\)/.test(reset), "hzArrReset: back to the default spot");
	expect(/if\(k == HZ_VEH_KEY\) \{ try \{ this\.hzVehFromPx\(c\);/.test(store), "hzArrStore: offsets, not a [Layout] anchor");
	expect(/this\.hzVehArrSync\(\)/.test(draw), "hzArrDraw: the pill at its stored spot");
}
// ---- 6. edge-only, no measuring ----
{
	const i0 = as.indexOf("private function hz42VehOnData("), i1 = as.indexOf("private function hzQmIni(");
	const pill = codeOnly(as.slice(i0, i1));
	expect(i0 > 0 && i1 > i0 && !/getBounds|localToGlobal|getRect/.test(pill), "no getBounds / getRect / localToGlobal anywhere in the pill code");
	const tick = codeOnly(fnText(as, "hz42VehTick").body);
	expect(/^\s*if\(this\.hzVehArr\) \{ return; \}/.test(fnText(as, "hz42VehTick").body), "per frame: one Boolean test first (ARRANGE owns the pill)");
	expect(!/getBounds|localToGlobal|hz42VehPlace\(|b\.width|b\.height/.test(tick), "hz42VehTick measures nothing (no getBounds, no button size)");
	expect(/if\(!this\.hzVehPx\.visible \|\| this\.hzVehPlR !== this\.hzVisR \|\| this\.hzVehPlX != this\.hzVehX \|\| this\.hzVehPlY != this\.hzVehY \|\| this\.hzVehPlW != this\.hzVehW \|\| this\.hzVehPlH != this\.hzVehH\) \{ this\.hzVehPlace\(\); \}/.test(tick), "hz42VehTick places only on an edge (number and reference compares)");
	const v = host(button()); inVehicle(v, 1); const p1 = v.places; inVehicle(v, 60);
	expect(p1 === 1 && v.places === 1, "60 more frames in the vehicle: no further placement (" + p1 + " then " + v.places + ")");
	v.hzVehX = 5; v.hz42VehTick();
	expect(v.places === 2, "a new offset (F11 APPLY / preset) is an edge: placed once more");
	v.btn.Visible = false; v.hz42VehTick(); v.btn.Visible = true; v.hz42VehTick();
	expect(v.places === 3, "hidden and shown again is an edge: placed once more");
	let bad = [];
	for (const n of ["hzVehCX", "hzVehCY", "hzVehHome", "hzVehSpot", "hzVehPlace", "hzVehArrSync", "hzVehPut", "hzVehFromPx", "hzVehIni", "hzVehSetCur", "hzVehSetLive", "hzVehIniLines"]) {
		if (!hasFn(n)) { bad.push(n + "(missing)"); continue; }
		const b = codeOnly(fnText(as, n).body);
		if (/setTimeout|setInterval|Timer|addEventListener|ENTER_FRAME|enterFrame|getChildByName|numChildren|while\(|for\s*\(/.test(b)) bad.push(n);
	}
	expect(bad.length === 0, "no timer, listener, enterFrame, loop or tree search in the pill helpers" + (bad.length ? " (" + bad.join(", ") + ")" : ""));
	const callers = (as.match(/this\.hzVehArrSync\(\)/g) || []).length;
	expect(callers === 4, "hzVehArrSync is called from ARRANGE enter / draw / exit and hzVehPut only (" + callers + ")");
	expect((as.match(/this\.hzVehPlace\(\)/g) || []).length === 2, "hzVehPlace has two callers: the vehicle tick (on an edge) and hzVehArrSync");
}

console.log(failed ? "vehicle_arrange_test FAILED (" + passed + " ok, " + failed + " FAIL)" : "vehicle_arrange_test passed (" + passed + " ok)");
process.exit(failed ? 1 : 0);
