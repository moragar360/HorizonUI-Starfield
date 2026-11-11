// v0.44 r9d tests: the whole-group BottomLeftGroup hide while the hand scanner is open with a watch on (hz49).
// Run: node tests/scan_grp_test.js
// Proves, against the production AS in horizon_block.as:
//  1. the scan open edge hides BLG through the very hz44GrpTick path WatchStyle 0 uses (alpha 0, mouse flags off), in the
//     edge's own handler, without asking for a per-piece list rebuild (no tree walk);
//  2. while scanning, the frame ticks, HudModeData and HUDOpacityData keep it hidden; nothing under the group is written;
//  3. the close edge releases only on the next frame tick, with the game's alpha and mouse flags back, and no rebuild;
//  4. the gates: HZ49_SCAN_GRP modes (shipped 2 since r9d2: HideWatchWhileScanning only), moved / home, HideWatchWhileScanning with and without the Scanner module, style 0,
//     ARRANGE, latch, BlgGroupHide=0, hide-all, the enemy-cue rule;
//  5. a group re-created while hidden (menu teardown / recreate), the style-0 path unchanged, and the wiring is edge-only;
//  6. r9e (Bot 3 N-1 / N-2): an INI reload while scanning ends in the right hide state (the production hz37OnApplyTxt and
//     hzOnIni: hz49Sync once hzOnIni has read the keys), hide-all (the production hzToggleAll) re-syncs, and both are
//     no-ops when unchanged; hzOnIni itself stays byte-identical to r9d2 (a grouphide right-side function).
// r9d2 (user picks, 2026-11-11 10:08 AM): "Moved watch: hide only when Hide Watch While Scanning is on" and "Home watch,
// option off: keep showing the vanilla watch during scans" -> the hiding cases below run with HideWatchWhileScanning=1 (HW).
// Author: Moragar. Last modified: 2026-11-11.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) i = src.indexOf("public function " + name + "(");
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
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
function bindAll(h, names) {
	const wrap = new Proxy(h, { get(t, k) { return k in t ? t[k] : undefined; }, has(t, k) { return k in t; } });
	for (const n of names) {
		const f = fnText(as, n);
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}
function asConst(name) {
	const m = as.match(new RegExp("private static const " + name + ":(?:int|Boolean)\\s*=\\s*([^;]+);"));
	if (!m) throw new Error("missing const " + name);
	return m[1].trim() === "true" ? true : m[1].trim() === "false" ? false : Number(m[1]);
}

// ---- display model ----
let uid = 0;
function Clip(name, kids) {
	const c = { key: ++uid, name: name, visible: true, alpha: 1, x: 0, y: 0, scaleX: 1, scaleY: 1, mouseEnabled: true, mouseChildren: true, parent: null, kids: kids ? [] : null, gets: 0 };
	if (kids) {
		Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; } });
		c.getChildAt = function(i) { return this.kids[i]; };
		c.getChildByName = function(n) { this.gets++; for (const k of this.kids) if (k && k.name === n) return k; return null; };
	}
	return c;
}
function add(p, c) { c.parent = p; p.kids.push(c); return c; }
function remove(c) { const p = c.parent; p.kids.splice(p.kids.indexOf(c), 1); c.parent = null; }

const BLG_KIDS = ["DayCycleBase_mc", "OffPlanet_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "WatchOutline_mc", "WatchPointerOutline_mc",
	"O2CO2_mc", "EnvAlertText", "BioAlertText", "LocationAlertText", "EnemyDetectionAnim_mc", "BioCondition_mc", "EnvCondition_mc", "instance23", "instance1645"];
const SENT = ["sentinel-list"];
function host(o) {
	const hud = Clip("root", true);
	const blg = add(hud, Clip("BottomLeftGroup_mc", true));
	for (const n of BLG_KIDS) add(blg, Clip(n));
	blg.alpha = 0.85;   // the game's HUD opacity
	const cfg = { HideWatchWhileScanning: (o && o.HW) ? 1 : 0 };
	const h = Object.assign({
		isNaN: isNaN, Math: Math, Number: Number, Boolean: Boolean, String: String, Error: Error, int: (n) => Math.trunc(Number(n) || 0),
		hud: hud, blg: blg, cfg: cfg,
		HZ44_ALLOW_UNREPLACED: true, HZ44_BY_ALPHA: true, HZ49_SCAN_GRP: asConst("HZ49_SCAN_GRP"), HZ49_NEED_ENEMY: asConst("HZ49_NEED_ENEMY"),
		hz44GrpIni: true, hz44Hid: false, hz44Ref: null, hz44Skip: null, hz44N: 0, hz44GameA: 1, hz44OpSub: false, hz44GameME: true, hz44GameMC: true, hz45EnvSub: true,
		hz49Grp: false, hz49Held: false, hz49N: 0, hz49Tries: 0, hzHideTries: 7,
		hzWlOn: false, hzWatchStyle: 1, hzHideVanillaWatch: false, hzUserHidden: false, hzShowAfflictions: true, hzShowPlanet: true, hzHazardAlert: true,
		hzStealthOn: true, hzEnemyBarOn: true, hzEdgePulse: true, hzGroupVisible: true, hzHideCache: SENT, HorizonAffl_mc: {}, hzCompact: false, hzRuleAffl: 6, hzRulePlanet: 0,
		HorizonStealth_mc: {}, HorizonEnemy_mc: {}, HorizonEdge_mc: {}, hzBlg: blg,
		hz40Scan: false, hz40Latch: false, hzArrange: false, hz30Mod: { scanner: 1 }, hz43FoMoved: false, hz43VanWrote: false,
		hz45SM: 0, n45: 0, nWant: 0, nRoot: 0, subs: 0,
		BSUIDataManager: { Subscribe: function() { h.subs++; } }
	}, o || {});
	h.getChildByName = function(n) { h.nRoot++; return hud.getChildByName(n); };
	h.hzPerfNow = function() { return 0; };
	h.hzPillOn = function() { return true; };
	h.hz45Sync = function() { h.n45++; };
	h.hz40Cfg = function() { return cfg; };
	h.hzWlPush = function() { };
	bindAll(h, ["hz44GrpWant", "hz44GrpTick", "hz44MouseBack", "hz44OnOpacity", "hz41B", "hz49Want", "hz49Sync"]);
	const want = h.hz49Want;
	h.hz49Want = function() { h.nWant++; return want(); };
	return h;
}
function kids(h) { return h.blg.kids.map((k) => [k.name, k.visible, k.alpha, k.x, k.y, k.scaleX].join(":")).join("|"); }
function open(h) { h.hz40Scan = true; h.hz49Sync(); }     // what hz40SetScan's edge does through hz43ScanHideSync
function close(h) { h.hz40Scan = false; h.hz49Sync(); }
function frame(h, n) { for (let i = 0; i < (n || 1); i++) { h.hz44GrpTick(true); h.hz44GrpTick(false); } }

expect(asConst("HZ49_SCAN_GRP") === 2 && asConst("HZ49_NEED_ENEMY") === true, "shipped switch: HZ49_SCAN_GRP = 2 (HideWatchWhileScanning=1 only, home or moved; r9d2), enemy-cue rule on");

// ---- 1-3: style 1, watch moved, HideWatchWhileScanning on ----
{
	const h = host({ hz43FoMoved: true, hz43VanWrote: true, HW: 1 });
	h.blg.kids[3].visible = false;   // a piece the game / r9b state hid (e.g. W3 OffPlanet), must stay as it is
	const before = kids(h);
	frame(h, 3);
	expect(h.blg.alpha === 0.85 && !h.hz44Hid && h.nWant === 0, "no scan: style 1 moved, frame ticks leave the group alone and never evaluate hz49Want");
	open(h);
	expect(h.hz49Grp && h.hz44Hid && h.hz49Held && h.blg.alpha === 0 && h.blg.mouseEnabled === false && h.blg.mouseChildren === false, "open edge (moved, HideWatch on): the group is hidden at once by the hz44 path (alpha 0, mouse off)");
	expect(h.hzHideCache === SENT, "open edge: the per-piece hide list is kept (no rebuild, no tree walk)");
	expect(h.n45 === 1, "open edge: the hz44 hide edge's own hz45Sync runs once");
	expect(kids(h) === before, "open edge: nothing under the group is written (r9b children, icon state, inverse-matrix pieces untouched)");
	const w0 = h.nWant, r0 = h.nRoot, g0 = h.blg.gets;
	frame(h, 120);
	expect(h.blg.alpha === 0 && h.hz44Hid && h.nWant === w0, "120 frames while scanning: still hidden; hz49Want is never evaluated per frame");
	expect(h.nRoot === r0 && h.blg.gets === g0 && h.n45 === 1 && h.hzHideCache === SENT, "while scanning: no lookups, no hz45Sync, no list rebuild per frame");
	h.blg.alpha = 0.6; h.hz44OnOpacity({ data: { fHUDOpacity: 0.6 } });
	expect(h.blg.alpha === 0 && h.hz44GameA === 0.6, "HUDOpacityData during the scan: re-hidden in the same handler, the new game opacity kept for the release");
	h.blg.visible = true; h.hzGroupVisible = true; h.hz44GrpTick(false);
	expect(h.blg.alpha === 0, "HudModeData during the scan: re-hidden in the same handler");
	expect(kids(h) === before, "after the scan's frames and handlers, every child is as it was");
	close(h);
	expect(!h.hz49Grp && h.hz44Hid && h.blg.alpha === 0, "close edge: hz49Grp clears, but the release waits for the frame tick (the close syncs run first)");
	h.hz44GrpTick(false);
	expect(h.hz44Hid && h.blg.alpha === 0, "close: no release outside the frame tick");
	h.hz44GrpTick(true);
	expect(!h.hz44Hid && !h.hz49Held && h.blg.alpha === 0.6 && h.blg.mouseEnabled === true && h.blg.mouseChildren === true, "next frame tick: released with the game's latest alpha and mouse flags");
	expect(h.hzHideCache === SENT && h.n45 === 2, "release: no list rebuild; the release edge's hz45Sync sweep runs once (listener / art state back)");
	expect(kids(h) === before, "release: every child exactly as before the scan");
	frame(h, 30);
	expect(h.blg.alpha === 0.6 && h.n45 === 2 && !h.hz44Hid, "after the scan: nothing more happens per frame (r9b moved-watch play outside the scanner untouched)");
	open(h); close(h); frame(h, 1); open(h); frame(h, 2); close(h); frame(h, 1);
	expect(h.blg.alpha === 0.6 && !h.hz44Hid && !h.hz49Held && h.hz49N === 6, "repeated open / close: three hide / release pairs, restored each time");
}
// ---- 3b: the every-90-frames list rebuild runs while the scan hide holds (it drops the BLG names under any group hide) ----
{
	const h = host({ hz43FoMoved: true, hzWatchStyle: 3, hzHideVanillaWatch: true, HW: 1 });
	open(h);
	expect(h.hzHideCache === SENT && h.hz49Tries === 7, "style 3 moved: hidden, the list kept, the rebuild count recorded");
	const rebuilt = ["list-without-BLG"]; h.hzHideCache = rebuilt; h.hzHideTries++;   // the periodic rebuild under the hide
	close(h); frame(h, 1);
	expect(!h.hz44Hid && !h.hz49Held && h.hzHideCache === null, "release after a rebuild under the hide: the list is rebuilt once in the release frame (no BLG piece flashes)");
	const h2 = host({ hz43FoMoved: true, hzWatchStyle: 3, hzHideVanillaWatch: true, HW: 1 });
	open(h2); frame(h2, 10); close(h2); frame(h2, 1);
	expect(h2.hzHideCache === SENT, "release with no rebuild under the hide: the list is kept (no walk)");
}
// ---- 4: gates ----
function hidesOn(o, setup) { const h = host(o); if (setup) setup(h); open(h); return h.hz44Hid && h.blg.alpha === 0; }
// shipped mode 2 (r9d2): HideWatchWhileScanning alone decides, at home or moved
expect(!hidesOn({}), "mode 2: style 1 at home, HideWatchWhileScanning off: not hidden (the vanilla watch shows while scanning)");
expect(!hidesOn({ hz43FoMoved: true }) && !hidesOn({ hz43VanWrote: true }), "mode 2: style 1 moved, HideWatchWhileScanning off: not hidden (the watch shows while scanning)");
expect(!hidesOn({ hz43VanWrote: true, hzWatchStyle: 2 }) && !hidesOn({ hz43FoMoved: true, hzWatchStyle: 3 }) && !hidesOn({ hz43FoMoved: true, hzWatchStyle: 4 }), "mode 2: moved in styles 2 / 3 / 4, HideWatchWhileScanning off: not hidden");
expect(hidesOn({ HW: 1 }) && hidesOn({ HW: 1, hzWatchStyle: 2 }), "mode 2: at home with HideWatchWhileScanning=1 (Scanner module): hidden");
expect(hidesOn({ hz43FoMoved: true, HW: 1 }) && hidesOn({ hz43VanWrote: true, HW: 1 }), "mode 2: moved with HideWatchWhileScanning=1: hidden");
expect(hidesOn({ hz43VanWrote: true, hzWatchStyle: 2, HW: 1 }) && hidesOn({ hz43FoMoved: true, hzWatchStyle: 3, HW: 1 }) && hidesOn({ hz43FoMoved: true, hzWatchStyle: 4, HW: 1 }), "mode 2: moved in styles 2 / 3 / 4 with HideWatchWhileScanning=1: hidden");
expect(!hidesOn({ HW: 1, hz30Mod: { scanner: 0 } }) && !hidesOn({ hz43FoMoved: true, HW: 1, hz30Mod: { scanner: 0 } }), "mode 2: HideWatchWhileScanning=1 without the Scanner module does nothing, home or moved (r7 S-5)");
{
	const h = host({ hz43FoMoved: true });
	open(h); frame(h, 30);
	expect(!h.hz49Grp && !h.hz44Hid && h.blg.alpha === 0.85 && h.hz49N === 0, "mode 2: moved, option off: a whole scan leaves the group as the game has it (no scan-hide edge)");
	close(h); frame(h, 1);
	expect(!h.hz44Hid && h.blg.alpha === 0.85 && h.hz49N === 0 && h.hzHideCache === SENT, "mode 2: moved, option off: the close edge does nothing either");
}
expect(!hidesOn({ hz43FoMoved: true, hzWatchStyle: 0, HW: 1 }), "style 0: the scan hide never applies (style 0 has its own hz44 hide)");
expect(!hidesOn({ hz43FoMoved: true, hzArrange: true, HW: 1 }) && !hidesOn({ hz43FoMoved: true, hz40Latch: true, HW: 1 }), "ARRANGE or a latched scan: not hidden");
expect(!hidesOn({ hz43FoMoved: true, hz44GrpIni: false, HW: 1 }) && !hidesOn({ hz43FoMoved: true, hzUserHidden: true, HW: 1 }), "BlgGroupHide=0 or the player's hide-all: not hidden");
expect(!hidesOn({ hz43FoMoved: true, hzStealthOn: false, hzEnemyBarOn: false, hzEdgePulse: false, HW: 1 }), "no Horizon enemy cue: not hidden (the vanilla enemy ring stays, as in the style-0 rule)");
expect(hidesOn({ hz43FoMoved: true, hzStealthOn: false, hzEnemyBarOn: false, HW: 1 }), "one enemy cue (edge pulse) is enough");
expect(!hidesOn({ hz43FoMoved: true, HZ49_SCAN_GRP: 0, HW: 1 }), "HZ49_SCAN_GRP = 0: off (r9c behavior)");
expect(hidesOn({ hz43FoMoved: true, HZ49_SCAN_GRP: 1 }) && hidesOn({ hz43FoMoved: true, HZ49_SCAN_GRP: 1, hz30Mod: { scanner: 0 } }) && !hidesOn({ HZ49_SCAN_GRP: 1 }) && hidesOn({ HZ49_SCAN_GRP: 1, HW: 1 }), "HZ49_SCAN_GRP = 1 (r9d): moved (any option), or home with HideWatchWhileScanning=1");
expect(hidesOn({ HZ49_SCAN_GRP: 3 }), "HZ49_SCAN_GRP = 3: every scan with a watch on");
{
	const h = host({ hz43FoMoved: true, HW: 1 }); open(h);
	h.hzArrange = true; h.hz49Sync(); frame(h, 1);
	expect(!h.hz44Hid && h.blg.alpha === 0.85, "ARRANGE entered during a scan (its edge runs hz43ScanHideSync): released on the next frame tick");
}
{
	const h = host({ hz43FoMoved: true, HW: 1 }); open(h);
	h.hz40Latch = true; h.hz49Sync(); frame(h, 1);
	expect(!h.hz44Hid && h.blg.alpha === 0.85, "hz40Clear safety net (latch): released on the next frame tick");
}
// ---- 5: group re-created while hidden (menu teardown / recreate) ----
{
	const h = host({ hz43FoMoved: true, HW: 1 }); open(h);
	const old = h.blg; remove(old);
	const nb = add(h.hud, Clip("BottomLeftGroup_mc", true)); nb.alpha = 0.85; h.blg = nb;
	frame(h, 1);
	expect(old.alpha === 0.85 && old.mouseEnabled === true && h.hz44Ref === nb && nb.alpha === 0 && h.hz44Hid && h.hz49Held, "group re-created while scan-hidden: the old one gets the game's alpha back, the new one is hidden by the scan hide");
	close(h); frame(h, 1);
	expect(nb.alpha === 0.85 && !h.hz44Hid && !h.hz49Held && h.hzHideCache === SENT, "then closed: the new group released, no rebuild");
}
{
	const h = host({ hz43FoMoved: true, HW: 1 }); open(h);
	const old = h.blg; remove(old); h.hz40Scan = false; h.hz49Grp = false;   // scan ended by the load gap (hz40Frame -> hz40Clear)
	const nb = add(h.hud, Clip("BottomLeftGroup_mc", true)); h.blg = nb;
	h.hz49Sync(); frame(h, 1);
	expect(old.alpha === 0.85 && !h.hz44Hid && !h.hz49Held && nb.alpha === 1, "group re-created after the scan ended: old one restored, no stale scan-hide state");
	h.hzWatchStyle = 0; h.hzHideVanillaWatch = true; frame(h, 1);
	expect(h.hz44Hid && !h.hz49Held && h.hzHideCache === null, "then style 0: its own hide asks for the list rebuild as before (hz49Held reset by the re-find)");
}
// ---- style 0 path unchanged ----
{
	const h = host({ hzWatchStyle: 0, hzHideVanillaWatch: true });
	frame(h, 1);
	expect(h.hz44Hid && h.hzHideCache === null && !h.hz49Held, "style 0: the hide asks for the per-piece list rebuild exactly as r9c");
	h.hzHideCache = SENT; open(h); frame(h, 5); close(h); frame(h, 1);
	expect(h.hz44Hid && h.hzHideCache === SENT && !h.hz49Grp && h.hz49N === 0, "style 0: scanning changes nothing (no scan-hide edge, the hide holds)");
	h.hzWatchStyle = 1; h.hzHideVanillaWatch = false; frame(h, 1);
	expect(!h.hz44Hid && h.hzHideCache === null, "style 0 -> 1: the release asks for the rebuild as before");
}

// ---- 6: r9e N-1, an INI reload while scanning (the production hz37OnApplyTxt -> hzOnIni) ----
// hz40ParseIni (stubbed) runs the existing early hz43ScanHideSync -> hz49Sync with the OLD values, as in production; the
// keys are then read by hzOnIni's own loop / hz26Ini (both production), and hz37OnApplyTxt's hz49Sync after it must
// settle the state.
function iniHost(o) {
	const h = host(o);
	const NOOP = function() { };
	h.hz31OldFirst = (l) => l;
	h.hz31ParseIni = NOOP;
	h.hz40ParseIni = function() { h.early++; h.hz49Sync(); };
	h.early = 0; h.nRefresh = 0;
	h.hzRefreshVisibility = function() { h.nRefresh++; h.hz44GrpTick(false); };
	h.hzRulesV2 = true; h.hzTgScaleSet = true; h.hzEqKind = "";
	const fns = ["hz37OnApplyTxt", "hzOnIni", "hz26Ini", "hzToggleAll"];
	const wrap = new Proxy(h, { get(t, k) { return k in t ? t[k] : (typeof k === "string" && /^hz/.test(k) ? NOOP : undefined); }, has(t, k) { return k in t; } });
	for (const n of fns) {
		const f = fnText(as, n);
		const body = toJs(f.body).replace(/for each\(var (\w+)(?::\w+)? in /g, "for (var $1 of ");
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + body + "\n}"])).bind(wrap);
	}
	h.reload = function(text) { h.hz37OnApplyTxt(text); };
	return h;
}
{
	const h = iniHost({ hz43FoMoved: true, HW: 1 }); open(h);
	expect(h.hz44Hid && h.blg.alpha === 0, "N-1 setup: scanning, option on, moved: hidden");
	h.reload("[Watch]\nEnemyBar=0\nStealthMeter=0\nEdgePulse=0\n");
	expect(!h.hzEnemyBarOn && !h.hzStealthOn && !h.hzEdgePulse && h.early === 1, "N-1: the reload read the three enemy-cue keys (after the early sync)");
	expect(!h.hz49Grp && h.hz49N === 2, "N-1: reload turns every Horizon enemy cue off mid-scan: the final hz49Sync clears the scan hide (the early one saw the old keys)");
	frame(h, 1);
	expect(!h.hz44Hid && h.blg.alpha === 0.85 && h.hzHideCache === SENT, "N-1: released on the next frame tick with the game's alpha, no list rebuild (the r9c per-piece fallback keeps the alerts and ring)");
}
{
	const h = iniHost({ hz43FoMoved: true, HW: 1, hzWatchStyle: 0 }); open(h);
	expect(!h.hz49Grp && !h.hz44Hid, "N-1 setup: scanning in style 0 (its own hide off here): no scan hide");
	h.reload("WatchStyle=1\n");
	expect(h.hzWatchStyle === 1 && h.hz49Grp && h.hz44Hid && h.blg.alpha === 0 && h.hz49Held, "N-1: reload to style 1 mid-scan with the option on: hidden at once by the final hz49Sync (the early one saw style 0)");
}
{
	const h = iniHost({ hz43FoMoved: true, HW: 1 }); open(h);
	h.reload("BlgGroupHide=0\n");
	expect(!h.hz44GrpIni && !h.hz49Grp, "N-1: reload with BlgGroupHide=0 mid-scan: the scan hide ends");
	frame(h, 1);
	expect(!h.hz44Hid && h.blg.alpha === 0.85, "N-1: BlgGroupHide=0: released on the next frame tick");
}
{
	const h = iniHost({ hz43FoMoved: true, HW: 1 }); open(h);
	const n0 = h.hz49N, n45 = h.n45, w0 = h.nWant;
	h.reload("EnemyBar=1\nShowCompass=1\n");
	expect(h.hz49Grp && h.hz44Hid && h.blg.alpha === 0 && h.hz49N === n0 && h.n45 === n45 && h.hzHideCache === SENT && h.nWant === w0 + 2, "N-1: a reload that changes nothing: hz49Sync is a no-op (one compare each, no edge, no hz45Sync, no list rebuild)");
	const h2 = iniHost({ hz43FoMoved: true, HW: 1 });
	h2.reload("EnemyBar=1\n");
	expect(!h2.hz49Grp && !h2.hz44Hid && h2.hz49N === 0 && h2.blg.alpha === 0.85, "N-1: a reload with the scanner closed: nothing hides");
}
// ---- 6b: r9e N-2, hide-all mid-scan (the production hzToggleAll) ----
{
	const h = iniHost({ hz43FoMoved: true, HW: 1 }); open(h);
	h.hzToggleAll();
	expect(h.hzUserHidden && !h.hz49Grp && h.nRefresh === 1, "N-2: hide-all on mid-scan: hzToggleAll re-syncs (the scan hide clears)");
	frame(h, 1);
	expect(!h.hz44Hid && h.blg.alpha === 0.85 && h.hzHideCache === SENT, "N-2: released on the next frame tick, no list rebuild (vanilla group back, as with hide-all outside a scan)");
	h.hzToggleAll();
	expect(!h.hzUserHidden && h.hz49Grp && h.hz44Hid && h.blg.alpha === 0, "N-2: hide-all off mid-scan: hidden again at once");
	close(h); frame(h, 1);
	expect(!h.hz44Hid && h.blg.alpha === 0.85, "N-2: then the scanner closes: released as usual");
	const n0 = h.hz49N;
	h.hzToggleAll(); h.hzToggleAll(); frame(h, 2);
	expect(h.hz49N === n0 && !h.hz44Hid && h.blg.alpha === 0.85, "N-2: hide-all on / off with the scanner closed: hz49Sync is a no-op");
}

// ---- static: wiring, edge-only, no per-frame / search / timer / allocation ----
const grpWant = codeOnly(fnText(as, "hz44GrpWant").body);
expect(/return this\.hz49Grp \|\| HZ44_ALLOW_UNREPLACED && this\.hz44GrpIni && this\.hzWatchStyle == 0/.test(grpWant), "hz44GrpWant: the only per-frame change is one field read (hz49Grp) in front of the r9c chain");
const tick = codeOnly(fnText(as, "hz44GrpTick").body);
expect(!/hz49Want|hz49Sync/.test(tick), "hz44GrpTick never calls hz49Want / hz49Sync");
expect(/if\(this\.hz49Grp\) \{ this\.hz49Held = true; this\.hz49Tries = this\.hzHideTries; \}\s*else \{ this\.hzHideCache = null; \}/.test(tick) && /if\(this\.hz49Held && this\.hzHideTries == this\.hz49Tries\) \{ this\.hz49Held = false; \}\s*else \{ this\.hz49Held = false; this\.hzHideCache = null; \}/.test(tick), "hz44GrpTick: the scan hide's edges skip the list rebuild unless a periodic rebuild ran under it; the style-0 edges keep it");
expect((as.match(/var grp:Boolean = this\.hz44Hid;   \/\/ BLG hidden as a whole/g) || []).length === 1, "the hide-list function (right side) is unchanged");
const shs = codeOnly(fnText(as, "hz43ScanHideSync").body);
expect(shs.indexOf("this.hz49Sync()") >= 0 && shs.indexOf("this.hz49Sync()") < shs.indexOf("return;"), "hz43ScanHideSync calls hz49Sync before its own early return");
let callers = []; for (const m of as.matchAll(/this\.hz49Sync\(\)/g)) callers.push(m.index);
const at = (i) => { const pre = as.slice(0, i); const m = [...pre.matchAll(/(?:private|public) function (\w+)\(/g)]; return m.length ? m[m.length - 1][1] : ""; };
expect(callers.length === 3 && callers.map(at).sort().join(",") === "hz37OnApplyTxt,hz43ScanHideSync,hzToggleAll", "hz49Sync has exactly three call sites: hz43ScanHideSync, hz37OnApplyTxt (r9e N-1), hzToggleAll (r9e N-2)");
const apply = codeOnly(fnText(as, "hz37OnApplyTxt").body);
expect(apply.indexOf("this.hz49Sync()") > apply.indexOf("this.hzOnIni(null)") && apply.indexOf("this.hzOnIni(null)") > 0, "hz37OnApplyTxt: hz49Sync right after hzOnIni has read BlgGroupHide / WatchStyle / the enemy-cue keys");
expect(codeOnly(fnText(as, "hzOnIni").body).indexOf("hz49") < 0, "hzOnIni (a grouphide right-side function) holds no hz49 call");
const tog = codeOnly(fnText(as, "hzToggleAll").body);
expect(tog.indexOf("this.hz49Sync()") > tog.indexOf("this.hzUserHidden = !this.hzUserHidden") && tog.indexOf("this.hz49Sync()") < tog.indexOf("this.hzRefreshVisibility()") && !/for\s*\(|while|new |getChild/.test(tog), "hzToggleAll: hz49Sync after the flip, before the refresh; no loop, search or allocation");
const setScan = codeOnly(fnText(as, "hz40SetScan").body);
expect(setScan.indexOf("if(!edge) { return; }") >= 0 && setScan.indexOf("hz43ScanHideSync") > setScan.indexOf("if(!edge) { return; }"), "hz40SetScan reaches it only after its edge gate");
expect(codeOnly(fnText(as, "hz40Clear").body).indexOf("this.hz43ScanHideSync()") >= 0, "hz40Clear (the safety nets) reaches it too");
const sync = codeOnly(fnText(as, "hz49Sync").body), want = codeOnly(fnText(as, "hz49Want").body);
const both = sync + want;
expect(!/getChildByName|getChildAt|numChildren|addEventListener|Timer|setTimeout|setInterval|ENTER_FRAME|enterFrame|new |\[\]|\{\}|while|for\s*\(/.test(both), "hz49Want / hz49Sync: no lookup, listener, timer, loop or allocation");
expect(/this\.hz44GrpTick\(false\)/.test(sync) && !/hz44GrpTick\(true\)/.test(sync), "hz49Sync: hides through hz44GrpTick(false) at once; never forces a frame-tick release");
for (const fn of ["hzOnFrame", "hz27OnExit", "hz43Frame", "hz43VanHorizon", "hz43VanPlace", "hz43VanLate", "hz43SyncHide", "hz27BioHide", "hz40Frame", "hz44GrpTick", "hz44GrpWant"]) {
	let b = ""; try { b = codeOnly(fnText(as, fn).body); } catch (e) { b = ""; }
	expect(b !== "" && !/hz49Sync|hz49Want/.test(b), "per-frame function " + fn + " holds no hz49Sync / hz49Want call");
}
console.log((failed ? "FAILED " : "all ok ") + "scan_grp_test: " + passed + " ok, " + failed + " FAIL");
process.exit(failed ? 1 : 0);
