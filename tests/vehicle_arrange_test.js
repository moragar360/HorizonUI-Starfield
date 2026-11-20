// Vehicle exit pill in ARRANGE CARDS (0.43.3.2 batch e). Run: node tests/vehicle_arrange_test.js
// Runs the production hzVeh* helpers and hz42VehPlace (types stripped) on a small host and checks:
//  1. default offsets 0 / 0 place the pill exactly where 0.43.3.2 d placed it (centered on the game's prompt);
//  2. an offset moves it (X + = right, Y + = up), clamped; drag -> offsets -> same spot round trip;
//  3. the settings plumbing: INI reader, current values, live apply, writer lines, HZ_SET_DEF and default.ini (0 / 0);
//  4. ARRANGE: the list entry, store, CANCEL restore, SAVE keep, RESET to 0 / 0, hand-back to the vehicle tick;
//  5. edge-only: the per-frame tick gains one Boolean test; the new code has no timer, listener, enterFrame or tree search.
// Author: Moragar. Last modified: 2026-11-18 (batch e).
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
class Point { constructor(x, y) { this.x = x; this.y = y; } }
class Rectangle { constructor(x, y, w, h) { this.x = x; this.y = y; this.width = w; this.height = h; } get right() { return this.x + this.width; } get bottom() { return this.y + this.height; } }
global.Point = Point; global.Rectangle = Rectangle;
global.int = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)) | 0; };

const FNS = ["hzVehCX", "hzVehCY", "hzVehHome", "hzVehArrSync", "hzVehPut", "hzVehFromPx", "hzVehIni", "hzVehSetCur", "hzVehSetLive", "hzVehIniLines", "hz42VehPlace"];
function host(btnRect) {
	const h = {
		HZ_VEH_KEY: "VehicleExit",
		hzVehX: 0, hzVehY: 0, hzVehHX: NaN, hzVehHY: NaN, hzVehArr: false, hzVehKs: "", hzVehKf: "", hzVehSig: "x",
		hzVehW: 120, hzVehH: 42, hzVehOn: true, hzArrange: false, hz41SA: false, hzSetPend: null, hzArr_mc: null,
		hzVehPx: null, draws: [], kids: [],
		hzVis() { return new Rectangle(0, 0, 1920, 1080); },
		hz42VehBtn() { return btnRect ? { getBounds: () => btnRect } : null; },
		hz42VehDraw(k, f, p, d) { this.draws.push([k, f, p, d]); },
		addChild(c) { c.parent = this; this.kids.push(c); },
		globalToLocal(p) { return p; },
	};
	for (const n of FNS) h[n] = toJs(n);
	return h;
}
global.Sprite = class { constructor() { this.x = 0; this.y = 0; this.visible = true; this.parent = null; } };
const sprite = () => new global.Sprite();

// ---- 1. default spot unchanged ----
{
	const h = host(new Rectangle(1500, 900, 60, 30));
	h.hzVehPx = sprite();
	const ok = h.hz42VehPlace({ getBounds: () => new Rectangle(1500, 900, 60, 30) });
	expect(ok && h.hzVehPx.x === Math.round(1530 - 60) && h.hzVehPx.y === Math.round(915 - 21), "0 / 0: the pill is centered on the game's prompt, the same spot as before (" + h.hzVehPx.x + ", " + h.hzVehPx.y + ")");
	expect(h.hzVehHX === 1530 && h.hzVehHY === 915, "placing records the game's prompt center (the ARRANGE home)");
	// the d formula, verbatim
	expect(/hzVehPx\.x = Math\.round\(this\.hzVehHX \+ this\.hzVehX - this\.hzVehW \/ 2\)/.test(as) && /hzVehPx\.y = Math\.round\(this\.hzVehHY - this\.hzVehY - this\.hzVehH \/ 2\)/.test(as), "in a vehicle the offset is only added to the old center formula");
}
// ---- 2. offsets, clamp, round trip ----
{
	const h = host(new Rectangle(1500, 900, 60, 30));
	h.hzVehPx = sprite();
	h.hzVehX = 100; h.hzVehY = 50;
	h.hz42VehPlace({ getBounds: () => new Rectangle(1500, 900, 60, 30) });
	expect(h.hzVehPx.x === 1570 && h.hzVehPx.y === 844, "X + = right, Y + = up");
	expect(h.hzVehCX(5000) === 1000 && h.hzVehCX(-5000) === -1000 && h.hzVehCY(5000) === 600 && h.hzVehCY("x") === 0 && h.hzVehCX(12.6) === 13, "offsets clamp to -1000..1000 / -600..600, whole units, junk = 0");
	h.hzArrange = true;
	h.hzVehArrSync();
	const c = h.hzVehPx;
	c.x += 37; c.y -= 22;
	h.hzVehFromPx(c);
	expect(h.hzVehX === 137 && h.hzVehY === 72, "drag: pill center -> offsets from the game's prompt (" + h.hzVehX + ", " + h.hzVehY + ")");
	h.hzArrange = false; h.hzVehArrSync();
	h.hz42VehPlace({ getBounds: () => new Rectangle(1500, 900, 60, 30) });
	expect(h.hzVehPx.x === 1607 && h.hzVehPx.y === 822, "in a vehicle the pill lands where it was dropped in ARRANGE");
}
// ---- 3. settings plumbing ----
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
	const sd = JSON.parse(/HZ_SET_DEF:Object = (\{[^;]*\});/.exec(as)[1]);
	expect(sd.VehicleExitX === 0 && sd.VehicleExitY === 0 && sd.VehicleExitPill === 1, "HZ_SET_DEF: 0 / 0 (DEFAULTS = the game's spot)");
	expect(/\nEquipmentExtras=1\n; Vehicle exit pill spot[^\n]*\nVehicleExitX=0\nVehicleExitY=0\n\n\[Effects\]/.test(ini), "default.ini [Cards Extra]: VehicleExitX=0 / VehicleExitY=0, where the writer puts them");
	expect(/this\.hzVehIni\(k,nv\)/.test(fnText(as, "hz26Ini").body) && /this\.hzVehSetCur\(o\)/.test(fnText(as, "hz26SetCur").body) && /this\.hzVehSetLive\(p\)/.test(fnText(as, "hz26SetLive").body) && /a\.push\("EquipmentExtras=[^\n]*\n\s*this\.hzVehIniLines\(a,p\);/.test(fnText(as, "hz26IniLines").body), "reader, current, live and writer are hooked into the [Cards Extra] chain");
}
// ---- 4. ARRANGE ----
{
	const h = host(new Rectangle(1500, 900, 60, 30));
	h.hzArrange = true; h.hzVehKs = "R";
	h.hzArr_mc = { parent: null }; h.hzArr_mc.parent = h;
	h.hzVehArrSync();
	expect(h.hzVehArr && h.hzVehPx && h.hzVehPx.visible && h.draws.length === 1 && h.draws[0][0] === "R" && h.draws[0][2] === 0, "ARRANGE: the pill shows idle with the last key seen, drawn once");
	expect(h.hzVehPx.x === 1470 && h.hzVehPx.y === 894, "ARRANGE: no vehicle visit yet -> home from the game's button bounds");
	h.hzVehArrSync();
	expect(h.draws.length === 1, "redraws of the ARRANGE screen only move it (no redraw)");
	const k2 = h.kids.length; expect(h.kids[k2 - 1] === h.hzArr_mc, "the ARRANGE layer stays on top of the pill");
	h.hzSetPend = {};
	h.hzVehPut(11, 22);
	expect(h.hzSetPend.VehicleExitX === 11 && h.hzSetPend.VehicleExitY === 22, "a move also goes into the pending F11 values (SAVE writes it)");
	h.hzArrange = false; h.hzVehArrSync();
	expect(!h.hzVehArr && !h.hzVehPx.visible && h.hzVehSig === "", "leaving ARRANGE hands the pill back to the vehicle tick (signature cleared: it redraws in a vehicle)");
	const h2 = host(null); h2.hzArrange = true; h2.hzVehOn = false; h2.hzVehArrSync();
	expect(!h2.hzVehArr && h2.hzVehPx === null, "VehicleExitPill=0: no ARRANGE entry");
	const h3 = host(null); h3.hzArrange = true; h3.hzVehArrSync();
	expect(h3.hzVehPx.x === 1920 - 220 - 60 && h3.hzVehPx.y === 1080 - 150 - 21, "no button: lower-right fallback home");

	const list = fnText(as, "hzArrList").body, enter = fnText(as, "hzArrEnter").body, exit = fnText(as, "hzArrExit").body;
	const reset = fnText(as, "hzArrReset").body, store = fnText(as, "hzArrStore").body, draw = fnText(as, "hzArrDraw").body;
	expect(/"k":HZ_VEH_KEY,"n":"VEHICLE EXIT PILL","c":this\.hzVehPx/.test(list) && /this\.hzVehArr && this\.hzVehPx != null/.test(list), "hzArrList: VEHICLE EXIT PILL entry while the pill is the proxy");
	expect(/this\.hzVehOrig = \{"x":this\.hzVehX,"y":this\.hzVehY\}/.test(enter) && /this\.hzVehArrSync\(\)/.test(enter), "hzArrEnter: keeps the offsets for CANCEL, shows the pill");
	const saveIdx = exit.indexOf("if(save)"), elseIdx = exit.indexOf("else", saveIdx);
	expect(exit.indexOf("this.hzVehOrig = null;", saveIdx) < elseIdx && /this\.hzVehPut\(this\.hzVehOrig\.x,this\.hzVehOrig\.y\)/.test(exit.slice(elseIdx)) && /this\.hzVehArrSync\(\)/.test(exit), "hzArrExit: SAVE keeps, CANCEL restores, then hands the pill back");
	expect(/this\.hzVehPut\(0,0\)/.test(reset), "hzArrReset: back to the game's spot");
	expect(/if\(k == HZ_VEH_KEY\) \{ try \{ this\.hzVehFromPx\(c\);/.test(store), "hzArrStore: offsets, not a [Layout] anchor");
	expect(/this\.hzVehArrSync\(\)/.test(draw), "hzArrDraw: the pill at its stored spot");
}
// ---- 5. edge-only ----
{
	const tick = fnText(as, "hz42VehTick").body;
	expect(/^\s*if\(this\.hzVehArr\) \{ return; \}/.test(tick), "per frame: one Boolean test (ARRANGE owns the pill)");
	let bad = [];
	for (const n of FNS.filter((n) => n !== "hz42VehPlace")) {
		const b = codeOnly(fnText(as, n).body);
		if (/setTimeout|setInterval|Timer|addEventListener|ENTER_FRAME|enterFrame|getChildByName|numChildren|while\(|for\s*\(/.test(b)) bad.push(n);
	}
	expect(bad.length === 0, "no timer, listener, enterFrame, loop or tree search in the new code" + (bad.length ? " (" + bad.join(", ") + ")" : ""));
	const callers = (as.match(/this\.hzVehArrSync\(\)/g) || []).length;
	expect(callers === 4 + 0 && (as.match(/this\.hzVehArrSync\(\);/g) || []).length >= 4, "hzVehArrSync is called from ARRANGE enter / draw / exit and hzVehPut only (" + callers + ")");
}

console.log(failed ? "vehicle_arrange_test FAILED (" + passed + " ok, " + failed + " FAIL)" : "vehicle_arrange_test passed (" + passed + " ok)");
process.exit(failed ? 1 : 0);
