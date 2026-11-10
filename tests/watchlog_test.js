// watchlog (private diag) tests. Run: node tests/watchlog_test.js
// Proves, against the production AS in horizon_block.as:
//  1. off by default and gated: hzWlOn needs PerfDiag and WatchLog; every hook in a hot path is one hzWlOn test;
//     with it off the hide tick and both hide helpers leave the same state as the cff13c5 bodies (git show), and with
//     it on they still make the same writes (the logger never changes hiding);
//  2. change-only logging: a new object is logged once, an unchanged one never, a visible, alpha, parent-chain or
//     identity change once; the state right before each Horizon hide write is logged once per distinct state, with
//     repeats counted and the op recorded as the object's last op;
//  3. the rebuild diff, the bounded queue and flush, the window line, the hover timing and the mode hotkey;
//  4. the pause switch only skips the 90-frame re-walk, and only while diag and WatchLog are on.
// Author: Moragar. Last modified: 2026-11-10.
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const AS_PATH = path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(AS_PATH, "utf8").replace(/\r\n/g, "\n");
let base = null;   // cff13c5 source, for the off-path equivalence (skipped when git or the commit is not there)
try { base = cp.execFileSync("git", ["show", "cff13c5:actionscript/horizon_block.as"], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { base = null; }

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
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
function toJs(body) {
	return body
		.replace(/for each\s*\(\s*var\s+(\w+)\s*:\s*[\w.*]+\s+in\s+/g, "for (var $1 of ")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*\*\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
function bind(host, src, name) {
	const f = fnText(src, name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}
function constArr(name) {
	const m = as.match(new RegExp("static const " + name + ":Array = (\\[[\\s\\S]*?\\]);"));
	if (!m) throw new Error("const " + name);
	return JSON.parse(m[1]);
}
function constNum(name) {
	const m = as.match(new RegExp("static const " + name + ":(?:int|Number) = ([\\d.]+);"));
	if (!m) throw new Error("const " + name);
	return Number(m[1]);
}
function rng(seed) { let s = seed >>> 0; return function() { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }

// ---- display model (visible, alpha, parent, stage, children) ----
let uid = 0;
function Clip(name, kids) {
	const c = { key: ++uid, name: name, visible: true, alpha: 1, parent: null, kids: kids ? [] : null, x: 0, y: 0, scaleX: 1, scaleY: 1, w: 10, h: 10 };
	c.getBounds = function(t) { return { x: this.x, y: this.y, width: this.w, height: this.h }; };
	c.toString = function() { return this.cls || (this.kids ? "[object MovieClip]" : "[object Shape]"); };
	Object.defineProperty(c, "stage", { get: function() { let q = this; while (q.parent) q = q.parent; return q.__root ? q : null; } });
	if (kids) {
		Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; } });
		c.getChildAt = function(i) { return this.kids[i]; };
		c.getChildByName = function(n) { for (const k of this.kids) if (k && k.name === n) return k; return null; };
		c.getChildIndex = function(d) { const i = this.kids.indexOf(d); if (i < 0) throw new Error("not a child"); return i; };
	}
	return c;
}
function add(p, c) { c.parent = p; p.kids.push(c); return c; }
function remove(c) { const p = c.parent; p.kids.splice(p.kids.indexOf(c), 1); c.parent = null; }

const WL_FUNCS = ["hzWlApply", "hzWlPsAdd", "hzWlModeName", "hzWlPush", "hzWlIdOf", "hzWlChain", "hzWlPack", "hzWlDesc", "hzWlSeen", "hzWlPre", "hzWlRbDiff",
	"hzWlBlgDiff", "hzWlBlgFrame", "hzWlCtxTick", "hzWlHover", "hzWlTick", "hzWlWinReset", "hzWlWin", "hzWlFlush", "hzWlKey", "hzWlNatSet"];

function makeHost(opts) {
	opts = opts || {};
	const hud = Clip("root", true);
	hud.__root = true;
	const h = {
		int: function(n) { n = Number(n); return isNaN(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)); },
		now: 1000, hzFrameN: 0, hzPerfOn: opts.perf !== false, hzWatchLogIni: opts.wl !== false,
		hzPsN: new Array(245).fill(0), hzPbN: new Array(33).fill(0), hzHideCache: null, hzBlg: null,
		hzInShip: false, hzInCombat: false, hzGroupVisible: true, hzUserHidden: false, drawn: false, f11: false,
		HorizonTarget_mc: null, hzTg19: null,
		HZWL_GROUPS: constArr("HZWL_GROUPS"), HZWL_SRC: constArr("HZWL_SRC"), HZWL_OPS: constArr("HZWL_OPS"), HZWL_PARTS: constArr("HZWL_PARTS"),
		HZWL_QMAX: constNum("HZWL_QMAX"), HZWL_IDMAX: constNum("HZWL_IDMAX"),
		hzWlOn: false, hzWlMode: 0, hzWlQ: null, hzWlQN: 0, hzWlDrop: 0, hzWlObj: null, hzWlObjId: null, hzWlNext: 0, hzWlIdFull: 0,
		hzWlSt: null, hzWlPreSt: null, hzWlPreRep: null, hzWlOpC: null, hzWlOpT: null, hzWlSlotObj: null, hzWlSlotId: null,
		hzWlChP: null, hzWlChV: 0, hzWlF: 0, hzWlCtx: -1, hzWlNat: 0, hzWlNatSeen: -1, hz44Hid: false, hz44N: 0, hzPcSigB: 0, hzWlScan: false, hzWlBlgN: -1, hzWlBlgRef: null, hzWlBlgPrev: null, hzWlBlgLbl: null,
		hzWlTgT: 0, hzWlTgN: 0, hzWlCardOn: false, hzWlCardT: 0, hzWlW0: 0, hzWlPs0: null, hzWlPb0: null, hzWlPsMax: null, hzWlPbMax: null,
		hzWlRbMs: null, hzWlW: null, hzWlCostN: 0, hzWlCostSum: 0, hzWlCostMax: 0, hzWlSkip: 0, hzWlDisMax: 0, hzWlRbNow: false,
		hud: hud
	};
	h.hzPerfNow = function() { return h.now; };
	h.hzWeaponOut = function() { return h.drawn; };
	h.hzSettingsOpen = function() { return h.f11; };
	h.getChildByName = function(n) { return hud.getChildByName(n); };
	for (const f of WL_FUNCS) bind(h, as, f);
	// "this" in the AS is the HUD root for the parent-chain stop and getChildByName
	const wrap = new Proxy(h, { get(t, k) { return k in t ? t[k] : undefined; }, has(t, k) { return k in t; } });
	for (const f of WL_FUNCS) {
		const ft = fnText(as, f);
		h[f] = Function.apply(null, argNames(ft.sig).concat(["with(this){\n" + toJs(ft.body).replace(/q != this\b/g, "q != this.hud") + "\n}"])).bind(wrap);
	}
	h.hzWlApply();
	return h;
}
function log(h) { return h.hzWlQ ? h.hzWlQ.slice(0, h.hzWlQN) : []; }
function flushLines(h) { const s = h.hzWlFlush(); return s ? s.split("\n").slice(1) : []; }

// ---- 1. gate and zero cost when off ----
{
	const a = makeHost({ perf: true, wl: false }), b = makeHost({ perf: false, wl: true }), c = makeHost();
	expect(!a.hzWlOn && !b.hzWlOn && c.hzWlOn, "gate: on only with PerfDiag and WatchLog both on");
	expect(a.hzWlQ === null && b.hzWlQ === null, "gate: no storage is made while off");
	c.hzWlKey(); expect(c.hzWlMode === 1, "hotkey: switches to the paused rebuild");
	c.hzWatchLogIni = false; c.hzWlApply();
	expect(!c.hzWlOn && c.hzWlMode === 0, "gate: turning WatchLog off ends the pause (the pause never outlives the gate)");
	a.hzWlKey(); expect(a.hzWlMode === 0, "hotkey: ignored while off");
	expect(/private var hzWatchLogIni:Boolean = false;/.test(as) && /private var hzWlOn:Boolean = false;/.test(as) && /private var hzWlMode:int = 0;/.test(as), "defaults: WatchLog off, logger off, mode baseline");
	expect(/case "watchlog": this\.hzWatchLogIni = bv; this\.hzPerfApply\(\); break;/.test(as), "INI: [Debug] WatchLog read like PerfDiag (hzPerfApply recomputes the gate)");
	const dflt = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8");
	expect(!/watchlog/i.test(dflt), "production default INI has no WatchLog key");
}
// Every watchlog line outside the watchlog block is behind hzWlOn.
{
	const b0 = as.indexOf("// ===================== watchlog (private diag) =====================");
	const b1 = as.indexOf("// ===================== end watchlog =====================");
	const outside = (as.slice(0, b0) + as.slice(b1)).split("\n").filter((l) => /hzWl|hzWatchLog/.test(l));
	const unguarded = outside.filter((l) => !/hzWlOn/.test(l) && !/case "watchlog"/.test(l) && !/this\.hzWlApply\(\);/.test(l) && !/var wlOld|var wlWhy/.test(l) && !/^\s*\/\//.test(l));
	expect(unguarded.length === 0, "hooks: every watchlog use outside its block tests hzWlOn first (" + outside.length + " lines)" + (unguarded.length ? " -- " + unguarded[0].trim() : ""));
	const hot = ["hz36HideTick", "hz43StHide", "hz43StHideV", "hzPsAdd", "hzPbEnd", "hzPbExit", "hzOnTgAct"];
	for (const f of hot) {
		const body = fnText(as, f).body;
		const lines = body.split("\n").filter((l) => /hzWl/.test(l));
		expect(lines.length >= 1 && lines.every((l) => /if\(this\.hzWlOn( |\))/.test(l)), "hot path " + f + ": " + lines.length + " watchlog line(s), each starts with if(this.hzWlOn");
	}
	const of = fnText(as, "hzOnFrame").body;
	expect(of.indexOf("if(this.hzHideCache == null || (this.hzFrameN % 90 == 1 && !(this.hzWlOn && this.hzWlMode == 1)) || this.hz36HideStale)") >= 0,
		"pause: only the 90-frame term is gated; hzWlOn is read only on those frames (&& short-circuit)");
	expect(of.indexOf("else if(this.hzWlOn && this.hzWlMode == 1 && this.hzFrameN % 90 == 1) { this.hzWlSkip++; }") >= 0, "pause: skipped re-walks are counted, behind hzWlOn");
	expect(/hzWlOn = on;[\s\S]*if\(!on\) \{ this\.hzWlMode = 0; \}/.test(fnText(as, "hzWlApply").body), "pause: the mode resets when the gate closes");
	expect(fnText(as, "hzPbExit").body.indexOf("this.hzPbEnd(1,t0);\n         if(this.hzWlOn)") >= 0, "cost: the exit tick runs after the exit total is booked (exitTotal stays comparable)");
}
// cff13c5 equivalence of the hide writes, off and on.
if (base) {
	const TICK = ["hz36HideTick", "hz43StHide", "hz43StHideV"];
	const mk = (src, wl) => {
		const h = makeHost({ wl: wl });
		h.hzPcStHide = 0; h.hzPcWcSkip = 0; h.hz36HideStale = false; h.noted = [];
		h.hz43VanWatchClip = function(d) { return !!(d && d.name && d.name.indexOf("Watch") === 0); };
		h.hz43VanNoteAdd = function(d) { h.noted.push(d.key); };
		for (const f of TICK) bind(h, src, f);
		return h;
	};
	let bad = "";
	for (const wl of [false, true]) {
		for (let seed = 1; seed <= 30 && !bad; seed++) {
			const r = rng(seed);
			const build = () => {
				const top = Clip("root", true); top.__root = true;
				const blg = add(top, Clip("BottomLeftGroup_mc", true));
				const names = ["WatchOutline_mc", "O2CO2_mc", "Temperature_mc", "WatchIconsWidget_mc", "HealthBar_mc"];
				const cache = names.map((n) => { const d = add(blg, Clip(n)); return { p: blg, n: n, d: d }; });
				return { top, blg, cache, names };
			};
			const A = build(), B = build();
			const ha = mk(base, false), hb = mk(as, wl);
			ha.hzHideCache = A.cache; hb.hzHideCache = B.cache;
			for (let f = 0; f < 60; f++) {
				const q = r(), i = Math.floor(r() * 5), v = r() < 0.5, al = Math.round(r() * 100) / 100;
				for (const S of [A, B]) {
					const d = S.blg.getChildByName(S.names[i]);
					if (q < 0.4 && d) { d.visible = v; d.alpha = al; }
					else if (q < 0.5 && d) { remove(d); add(S.blg, Clip(S.names[i])); }
				}
				ha.hz36HideTick(); hb.hz36HideTick();
				const pick = Math.floor(r() * 5);
				ha.hz43StHide(A.blg.kids[pick] || null); hb.hz43StHide(B.blg.kids[pick] || null);
				const sa = A.blg.kids.map((k) => k.name + k.visible + k.alpha).join("|"), sb = B.blg.kids.map((k) => k.name + k.visible + k.alpha).join("|");
				if (sa !== sb || ha.hz36HideStale !== hb.hz36HideStale || ha.hzPcStHide !== hb.hzPcStHide || ha.hzPcWcSkip !== hb.hzPcWcSkip) { bad = "wl=" + wl + " seed " + seed + " frame " + f; break; }
			}
		}
	}
	expect(!bad, "hide writes: hz36HideTick / hz43StHide / hz43StHideV give the cff13c5 state frame by frame, with the logger off and on" + (bad ? " -- " + bad : ""));
} else {
	console.log("skip cff13c5 equivalence (git show cff13c5 not available here)");
}

// ---- 2. change-only object logging ----
{
	const h = makeHost();
	const blg = add(h.hud, Clip("BottomLeftGroup_mc", true));
	const ring = add(blg, Clip("instance12"));
	const wo = add(blg, Clip("WatchOutline_mc"));
	h.hzBlg = blg;
	h.hzWlTick();
	let L = flushLines(h);
	const newB = L.filter((l) => /^wl o .*src=b .*new=1/.test(l));
	expect(newB.length === 2 && L.some((l) => /^wl o .*src=g .*n=BottomLeftGroup_mc/.test(l)), "first tick: each watched object is logged once as new (group and both BLG children)");
	expect(L.some((l) => /^wl ctx /.test(l)) && L.some((l) => /^wl blgN .*n=2 was=-1 add=2 rm=0/.test(l)) && L.some((l) => /^wl blg root .*n=BottomLeftGroup_mc/.test(l)),
		"first tick: context, BLG root and BLG child count logged");
	h.now += 16; h.hzWlTick();
	expect(flushLines(h).length === 0, "unchanged tick: nothing logged");
	ring.alpha = 0.4; h.now += 16; h.hzWlTick();
	expect(flushLines(h).length === 0, "alpha tween step (1 -> 0.4, still > 0): not logged (flag change only)");
	ring.alpha = 0; h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.length === 1 && /n=instance12 .* v=1 on=1 a=0 /.test(L[0]) && / new=0 /.test(L[0]), "alpha reaches 0 on the same object: one line, same id, new=0");
	ring.alpha = 0.3; h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.length === 1 && / a=30 /.test(L[0]), "alpha leaves 0: one line with the exact alpha");
	blg.visible = false; h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.filter((l) => / pv=0 /.test(l)).length === 2 && L.some((l) => /n=BottomLeftGroup_mc .* v=0 /.test(l)), "parent hidden: the group and each child log once (pv=0 on the children)");
	blg.visible = true;
	remove(ring); const ring2 = add(blg, Clip("instance12"));
	h.now += 16; h.hzWlTick();
	L = flushLines(h);
	const ids = L.filter((l) => /n=instance12/.test(l)).map((l) => Number(l.match(/ id=(\d+)/)[1]));
	expect(ids.length >= 1 && L.some((l) => /n=instance12 .*/.test(l) && / new=1 /.test(l)), "same name, new instance: logged as a new id (identity, not name)");
	expect(ring2 !== ring, "model sanity");
	// pre-hide: once per distinct state, repeats counted, op recorded
	wo.visible = true; h.hzWlPre(wo, 1); wo.visible = false;
	wo.visible = true; h.hzWlPre(wo, 1); wo.visible = false;
	L = flushLines(h);
	expect(L.length === 1 && /^wl pre .*op=tick .*n=WatchOutline_mc .* v=1 /.test(L[0]), "pre-hide: the state the write undoes is logged once");
	expect(h.hzWlW[3] === 2 && h.hzWlW[4] === 1, "pre-hide: the repeat is counted, not logged");
	wo.alpha = 0.5; h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.length === 1 && /last=tick@\d+/.test(L[0]), "a later change shows Horizon's last hide op on that object, with its time");
}

// ---- 2b. BottomLeftGroup child identity: adds, removes, unnamed shapes, labels ----
{
	const h = makeHost();
	const blg = add(h.hud, Clip("BottomLeftGroup_mc", true));
	blg.currentFrame = 1; blg.currentLabel = "Idle";
	const kids = [];
	for (let i = 0; i < 12; i++) kids.push(add(blg, Clip("Sib" + i)));
	h.hzBlg = blg;
	h.hzWlTick();
	let L = flushLines(h);
	expect(L.filter((l) => /^wl blg add /.test(l)).length === 12 && L.some((l) => /^wl lbl .*lbl=Idle was=null fr=1/.test(l)), "BLG first tick: 12 children listed as added, label logged");
	h.now += 16; h.hzWlTick();
	expect(flushLines(h).length === 0, "BLG unchanged: nothing logged");
	// scan start: the timeline jumps and builds new unnamed instances (a shape and a clip)
	blg.currentFrame = 186; blg.currentLabel = "FadeInPlanetInfo";
	const sh = add(blg, Clip("instance1285")); sh.cls = "[object Shape]"; sh.x = -96; sh.y = -40; sh.w = 192; sh.h = 192; sh.alpha = 0.2;
	const un = add(blg, Clip("")); un.cls = "[object MovieClip]"; un.totalFrames = 52;
	h.now += 16; h.hzWlTick();
	L = flushLines(h);
	const adds = L.filter((l) => /^wl blg add /.test(l));
	expect(adds.length === 2 && /n=instance1285 cls=\[object Shape\] ix=12 b=-96,-40,192,192 v=1 a=20 tf=- pv=1 pa=100 fr=186 lbl=FadeInPlanetInfo ctx=/.test(adds[0])
		&& /n=none cls=\[object MovieClip\] ix=13 .* tf=52 /.test(adds[1]), "BLG add: unnamed shape and clip, with class, bounds, v, alpha, depth, frame and label (" + (adds[0] || "") + ")");
	expect(L.some((l) => /^wl blgN .*n=14 was=12 add=2 rm=0 moved=0 fr=186/.test(l)) && L.some((l) => /^wl lbl .*lbl=FadeInPlanetInfo was=Idle fr=186/.test(l)), "BLG count and label change logged in the same frame");
	expect(L.filter((l) => /^wl o .*src=b .*new=1/.test(l)).length === 2, "new BLG children also enter the change-only object watch");
	// removal, and a same-count identity swap
	remove(sh); h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.some((l) => /^wl blg rm .*n=instance1285 cls=\[object Shape\] wasIx=12 .*parent=none/.test(l)) && L.some((l) => /^wl blgN .*n=13 was=14 add=0 rm=1/.test(l)), "BLG remove: logged with class, old depth, and where it went");
	remove(kids[3]); const k3 = Clip("Sib3"); k3.parent = blg; blg.kids.splice(3, 0, k3);
	h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.some((l) => /^wl blg add .*n=Sib3 .*ix=3 /.test(l)) && L.some((l) => /^wl blg rm .*n=Sib3 /.test(l)) && L.some((l) => /^wl blgN .*n=13 was=13 add=1 rm=1/.test(l)), "BLG same count, new instance: identity check catches it");
	const t = blg.kids[0], u = blg.kids[1]; blg.kids[0] = u; blg.kids[1] = t;
	h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.some((l) => /^wl blgN .*add=0 rm=0 moved=1/.test(l)) && !L.some((l) => /^wl blg (add|rm) /.test(l)), "BLG reorder only: one blgN line with moved=1");
	// a new BLG instance (HUD reload) restarts the list
	const blg2 = add(h.hud, Clip("BottomLeftGroup_mc", true)); add(blg2, Clip("Sib0")); h.hzBlg = blg2;
	h.now += 16; h.hzWlTick();
	L = flushLines(h);
	expect(L.some((l) => /^wl blg root /.test(l)) && L.some((l) => /^wl blgN .*n=1 .*add=1/.test(l)), "BLG instance change: root line, list restarts");
	// per-frame cost shape: unchanged frames allocate nothing in the diff path
	let diffs = 0; const orig = h.hzWlBlgDiff; h.hzWlBlgDiff = function() { diffs++; return orig.apply(h, arguments); };
	for (let f = 0; f < 50; f++) { h.now += 16; h.hzWlTick(); }
	expect(diffs === 0, "BLG unchanged frames: the diff (the only allocation) never runs");
	h.hzWlBlgDiff = orig;
}
{
	const blk = as.slice(as.indexOf("// ===================== watchlog (private diag) ====================="), as.indexOf("// ===================== end watchlog ====================="));
	expect(/var b:DisplayObjectContainer = this\.hzBlg;/.test(blk) && !/getChildByName\("BottomLeftGroup_mc"\)|searchAll|hz36HideFindAll\(/.test(blk.replace(/^\s*\/\/.*$/gm, "")), "BLG check uses Horizon's cached hzBlg ref only (no search)");
}

// ---- 3. rebuild diff, queue bound, window, hover, hotkey ----
{
	const h = makeHost();
	expect(/^wl on t=\d+ f=0 mode=base$/.test(log(h)[0]), "gate: switching on is logged");
	h.hzWlFlush();
	const p = Clip("P", true);
	const a = Clip("A"), b = Clip("B"), b2 = Clip("B");
	const old = [{ p: p, n: "A", d: a }, { p: p, n: "B", d: b }];
	h.hzWlRbDiff(old, [{ p: p, n: "A", d: a }, { p: p, n: "B", d: b }], 1);
	expect(h.hzWlW[0] === 1 && h.hzWlW[1] === 1 && h.hzWlQN === 0, "rebuild diff: same refs are counted as same, not logged");
	h.hzWlRbDiff(old, [{ p: p, n: "A", d: a }, { p: p, n: "B", d: b2 }, { p: p, n: "C", d: Clip("C") }], 1);
	let L = log(h);
	expect(L.length === 1 && /why=p90 n=3 add=C chg=B:\d+>\d+ lost=$/.test(L[0]), "rebuild diff: a changed ref and an added name are logged (" + (L[0] || "") + ")");
	h.hzWlRbDiff(old, [{ p: p, n: "A", d: a }], 2);
	expect(/why=stale .* lost=B$/.test(log(h)[1]), "rebuild diff: a lost name is logged, with why=stale");
	h.hzWlFlush();
	for (let i = 0; i < h.HZWL_QMAX + 5; i++) h.hzWlPush("x" + i);
	expect(h.hzWlQN === h.HZWL_QMAX && h.hzWlDrop === 5, "queue: bounded at " + h.HZWL_QMAX + ", overflow counted");
	const fl = h.hzWlFlush();
	expect(/^wl flush asNow=\d+ n=1024 drop=5\n/.test(fl) && h.hzWlQN === 0 && h.hzWlDrop === 0 && h.hzWlFlush() === "", "flush: one head line, then the entries; empty after");
	// hover timing
	h.HorizonTarget_mc = { visible: false, alpha: 1 }; h.hzTg19 = { visible: true };
	h.now = 5000; h.hzWlTgT = 5000; h.hzWlTgN = 1;
	h.now = 5033; h.hzWlHover(h.now);
	h.HorizonTarget_mc.visible = true; h.now = 5066; h.hzWlHover(h.now);
	h.now = 6000; h.hzWlTgT = 6000; h.hzWlTgN = 2;
	h.HorizonTarget_mc.visible = false; h.now = 6050; h.hzWlHover(h.now);
	h.HorizonTarget_mc.visible = true; h.now = 7000; h.hzWlHover(h.now);
	L = flushLines(h);
	expect(L.length === 3 && /on=1 dtMs=66 /.test(L[0]) && /on=0 dtMs=50 /.test(L[1]) && /on=1 dtMs=noT /.test(L[2]), "hover: appear 66 ms and gone 50 ms after the T event; an edge with no new T is noT");
	h.hzPsN[25] = 3; h.hzPsN[26] = 7; h.hzWlPsMax[5] = 7; h.hzPbN[0] = 10; h.hzPbN[1] = 40;
	const w = h.hzWlWin();
	expect(/^aswin m=base ms=\d+ f=\d+ loop=10,40,0 exit=0,0,0 rb=3 rbSame=1 rbChg=2 rbSkip=0 rbMs= pre=0 preRep=0 newIds=\d+ ids=\d+ idFull=0 hovAppear=1,66,66 hovGone=1,50,50 hovNoT=1 wl=0,0,0 q=0 drop=0 err=0 grp=0,0 sigB=0 parts=hideRebuild=3,7,7$/.test(w), "window line: every field, deltas since the window start (" + w + ")");
	expect(h.hzWlW.every((v) => v === 0) && h.hzWlPs0[25] === 3, "window: counters restart and the parts base moves");
	h.hzWlKey();
	expect(h.hzWlMode === 1 && /^wl mode t=\d+ f=\d+ frameN=\d+ mode=pause$/.test(log(h)[0]), "hotkey: logged with the new mode");
	h.hzWlKey();
	expect(h.hzWlMode === 0 && /mode=base$/.test(log(h)[1]), "hotkey: toggles back to baseline (two modes only)");
	h.hzWlNatSet("5");
	h.hzWlCtxTick(h.now);
	expect(/ nat=5$/.test(log(h)[2]), "context: the native menu mask change is logged");
}

// ---- 4. id table bound ----
{
	const h = makeHost();
	const p = Clip("P", true); p.__root = true;
	const keep = [];
	for (let i = 0; i < h.HZWL_IDMAX; i++) keep.push(add(p, Clip("k" + i)));
	const detachedId = h.hzWlIdOf(keep[0]);
	for (let i = 1; i < h.HZWL_IDMAX; i++) h.hzWlIdOf(keep[i]);
	remove(keep[0]);
	const nid = h.hzWlIdOf(Clip("x"));
	expect(nid === h.HZWL_IDMAX + 1 && h.hzWlObj.length === h.HZWL_IDMAX && h.hzWlObj.indexOf(keep[0]) < 0 && detachedId === 1, "ids: when full, off-stage entries go first; ids are never reused");
	const h2 = makeHost();
	for (let i = 0; i < h2.HZWL_IDMAX; i++) h2.hzWlIdOf(add(p, Clip("z" + i)));
	expect(h2.hzWlIdOf(add(p, Clip("over"))) === 0 && h2.hzWlIdFull === 1, "ids: full of live objects returns 0 (untracked) and counts it");
}

// ---- 5. native pins ----
{
	const main = fs.readFileSync(path.join(root, "src", "main.cpp"), "utf8").replace(/\r\n/g, "\n");
	const wlh = fs.readFileSync(path.join(root, "src", "hz_wl.h"), "utf8");
	expect(/bool HzWlOn\(\)\n\t\{\n\t\treturn HzPerfOn\(\) && g_wlOn\.load\(std::memory_order_relaxed\) != 0;/.test(main), "native gate: HzWlOn needs PerfDiag");
	expect(/g_wlOn\.store\(0, std::memory_order_relaxed\);\n\t\tint dump = 0;/.test(main) && /if \(get\("watchlog", v\)\) g_wlOn\.store\(hzperf::Parse01\(v\)/.test(main), "native gate: reset on every INI load, then [Debug] WatchLog");
	expect(/if \(HzWlOn\(\)\) \{   \/\/ watchlog: the mode hotkey \(Scroll Lock\), edge only\. No Scaleform here\./.test(main), "hotkey: polled on the job thread only when the gate is on, no Scaleform there");
	expect(/PollSettings\(wnd, now\);\n\t\tif \(HzWlOn\(\)\) \{ try \{ WlPoll\(now\); \} catch \(\.\.\.\) \{\} \}/.test(main), "Invokes: only from PollScaleform after the HUD-safe checks (UI path), each through HudInvoke");
	const wlFns = main.slice(main.indexOf("// ---- watchlog (private diag"), main.indexOf("void PollScaleform()"));
	const wlCode = wlFns.split("\n").map((l) => l.replace(/\/\/.*$/, "")).join("\n");
	expect(!/menuObj|static GValue|GValue\s+g_/.test(wlCode), "MUST-FIX: no menuObj and no GFx::Value kept across frames in the watchlog code");
	expect(/if \(g_wlOn\.load\(std::memory_order_relaxed\)\) hzwl::FdhAdd\(g_wlFdh, a_t0, HzQpcFreq\(\)\);/.test(main), "frame histogram: one add per HUD advance, inside HzPerfNoteRoot (PerfDiag already checked)");
	expect(/kWindowMs = 20000/.test(wlh) && /kFlushMs = 5000/.test(wlh), "disk: a window line every 20 s, entry flush every 5 s (never per frame)");
}

if (failed) { console.error(failed + " FAILED"); process.exit(1); }
console.log("all watchlog tests passed");
