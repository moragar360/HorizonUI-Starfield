// perf round 2 Fix 4 tests: the styles 1/2 vanilla watch show sweep runs on an edge only.
// Run: node tests/perf_r2_fix4_test.js   (HZ_AS=<file> runs it against another horizon_block.as)
// Before: in styles 1/2 the show sweep (hz43VanRestoreHid + hz43VanBlgChrome(false), a walk of every BLG child with the
// name / cap / ring checks) ran in hz43SyncHide, again in hz43VanPlace, and again in every exitFrame (about 4.7 times per
// frame). Now hz43ShowSweep runs it only when hz43ShowNeed says so, and hz43VanLate places the watch at most once per frame.
// Proves, by running the production AS (types stripped) next to the ff4c33f bodies on twin display models:
//  1. over random frames (native timeline writes to any clip, between the calls too; LocalEnvironmentData changes; BLG
//     children added / removed / torn down; style switches 1 / 2 / 3 with the style 3 hide pass; force edges), the new
//     calls leave exactly the same visible state as the old every-call sweep after every call, and run far fewer passes;
//  2. hz43ShowNeed: steady = no pass; each edge (force bit 8, style, BLG ref, child count, noted refs, full record) and
//     each stale recorded piece (hidden, torn down, a payload clip off its formula) = a pass; the check reads no name;
//  3. a throw inside the sweep leaves bit 8 set, so the next call sweeps again (no partial record is trusted);
//  4. hz43VanSame: same frame + same inputs = skip; a new frame, an Arrange drag of the watch, a scale, saved-layout or
//     resolve-counter change = place;
//  5. static: no timer, listener, frame-modulo term or search in the new functions; hz43VanRestoreHid keeps |= 7 (no bit 8,
//     or every sweep would force the next); the edges that re-run Fix 1's passes also set bit 8.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");
const gitBase = require("./lib/git_base.js");
const baseRes = gitBase.readBase(root, "ff4c33f");   // S-1b: SKIP only without a repository or in a shallow clone
let baseAs = baseRes.src;

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const i = src.indexOf("private function " + name + "(");
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
		.replace(/(\w+) is DisplayObjectContainer\b/g, "__isDoc($1)")
		.replace(/\bDisplayObjectContainer\(/g, "(")
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
	const m = as.match(new RegExp("static const " + name + ":Array = (\\[[^\\]]*\\]);"));
	if (!m) throw new Error("const " + name);
	return JSON.parse(m[1]);
}
function constOf(name) {
	const m = as.match(new RegExp("static const " + name + ":(?:int|Number) = ([\\d.]+);"));
	if (!m) throw new Error("const " + name);
	return Number(m[1]);
}
function rng(seed) { let s = seed >>> 0; return function() { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
function codeOnly(body) { return body.replace(/\/\/[^\n]*/g, ""); }

// ---- display model ----
let uid = 0;
const STAGE = {};
function Clip(name, leaf) {
	return { _id: ++uid, name: name, visible: true, alpha: 1, x: 0, y: 0, scaleX: 1, scaleY: 1, parent: null, stage: STAGE, kids: leaf ? null : [],
		transform: { colorTransform: { alphaMultiplier: 1, alphaOffset: 0 } } };
}
function add(p, c) { c.parent = p; p.kids.push(c); return c; }
function makeDoc(c) {
	if (!c.kids) return c;
	if (!Object.getOwnPropertyDescriptor(c, "numChildren")) {
		Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; }, configurable: true });
		c.getChildAt = function(i) {
			if (this.__throwAt === i) { this.__throwAt = -1; throw new RangeError("model throw"); }
			return this.kids[i];
		};
		c.getChildByName = function(n) { for (const k of this.kids) if (k.name === n) return k; return null; };
		c.getChildIndex = function(d) { const i = this.kids.indexOf(d); if (i < 0) throw new Error("not a child"); return i; };
	}
	for (const k of c.kids) makeDoc(k);
	return c;
}
function __isDoc(x) { return !!(x && x.kids); }
function fill(p, n, r, tag) { let cur = p; for (let m = 0; m < n; m++) { const c = add(cur, Clip(tag + "_" + m)); cur = (m % 3 === 2) ? p : c; if (r() < 0.3) add(c, Clip("shape" + m, true)); } }
const PAYLOAD = ["DayCycleBase_mc", "locationNameBase_mc", "OffPlanet_mc", "Autopilot_mc"];
function buildTop(seed) {
	const r = rng(seed);
	const blg = Clip("BottomLeftGroup_mc");
	fill(add(blg, Clip("WatchOutline_mc")), 8, r, "ol");
	add(blg, Clip("instance540", true));
	fill(add(blg, Clip("WatchPointerOutline_mc")), 4, r, "ptr");
	fill(add(blg, Clip("WatchIconsWidget_mc")), 4, r, "wi");
	fill(add(blg, Clip("MissionIconsWidget_mc")), 4, r, "mi");
	fill(add(blg, Clip("O2CO2_mc")), 4, r, "o2");
	for (const n of ["DayCycleBase_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc", "Autopilot_mc"]) fill(add(blg, Clip(n)), 3, r, n);
	fill(add(blg, Clip("EnvConditionBase_mc")), 3, r, "ecb");
	add(blg, Clip("EnvAlertText", true));
	fill(add(blg, Clip("EnemyDetectionAnim_mc")), 3, r, "eda");
	const holder = add(blg, Clip("WatchMarkHolder_mc"));
	fill(holder, 4, r, "hold");
	add(holder.kids[0], Clip("EnemyIconsWidget_mc"));
	const top = Clip("root");
	add(top, blg);
	return makeDoc(top);
}
function walkAll(c, p, out) { out.push(p); if (c.kids) c.kids.forEach((k, i) => walkAll(k, p.concat([i]), out)); return out; }
function at(t, p) { let c = t; for (const i of p) c = c.kids[i]; return c; }
function snap(top, h) {
	const out = [];
	// review N-4: positions too (the sweeps must never move a piece; x / y / scale as the old pass leaves them)
	(function walk(c, p) { out.push(p + c.name + "=" + (c.visible ? 1 : 0) + "@" + c.x + "," + c.y + "," + c.scaleX + "," + c.scaleY); if (c.kids) c.kids.forEach((k, i) => walk(k, p + i + "/")); })(top, "");
	out.push("hidN=" + h.hz43HidN);
	return out.join("\n");
}
function firstDiff(a, b) { const x = a.split("\n"), y = b.split("\n"); for (let i = 0; i < Math.max(x.length, y.length); i++) if (x[i] !== y[i]) return x[i] + "  vs  " + y[i]; return "?"; }

const FUNCS = ["hzFindByName", "hz43VanSkip", "hz43VanMarkName", "hz43VanInstName", "hz43VanCapClip", "hz43VanRingProof", "hz43VanRingClip",
	"hz43VanNamed", "hz43VanRootOf", "hz43VanWatchClip", "hz43StHide", "hz43VanNote", "hz43VanNoteAdd", "hz43VanRestoreHid", "hz43VanShowClip", "hz43VanGameVis",
	"hz43VanEnvWant", "hz43VanInfoName", "hz43VanHoldsMark", "hz43VanBlgChrome", "hz43VanChrome", "hz43ChrKeep", "hz43ChrBoxAdd", "hz43VanOutline", "hz43OlBegin", "hz43OlEnd",
	"hz43IsMark", "hz43FindMark", "hz43SyncHide"];
const SHOW = ["hz43ShowSweep", "hz43ShowNeed", "hz43ShowStale", "hz43ShowAdd"];
function makeHost(kind, top, style) {
	const h = {
		int: function(n) { return n | 0; }, trace: function() {}, __isDoc: __isDoc, isNaN: isNaN,
		hzPerfOn: false, hzPcFind: 0, hzPcStHide: 0, hzPcHoldN: 0, hzPcOlHit: 0, hzPcOlMiss: 0, hzPcWcSkip: 0, hzWlOn: false,
		hz43OlDepth: 0, hz43OlHave: false, hz43OlRef: null, hz43OlBlg: null, hz43ChrRec: false,
		hzBlg: top.kids[0], hzWatchStyle: style, hzHideVanillaWatch: style !== 1 && style !== 2, hzHideCache: [], hz43HideStyle: style,
		hz43VanShown: 1, hz43VanTries: 0, hz43ScanHid: false, hz43ScanSt: -1, hzDebug: false, hz26Dbg: {},
		hz43VanRing: null, hz43HidA: null, hz43HidN: 0, hz43HidP: null, hz43HidPN: 0, hz43VanN: 0, hz43VanD: [],
		hz43ChrForce: 15, hz43ChrShow: null, hz43ChrShowN: 0, hz43ChrBox: null, hz43ChrBoxK: null, hz43ChrBoxN: 0,
		hz43ShowL: null, hz43ShowNm: null, hz43ShowLN: 0, hz43ShowBlg: null, hz43ShowKids: -2, hz43ShowSt: -1,
		hz43EnvGot: 1, hz43EnvLocal: false, hz43EnvCruise: false, hz43EnvLang: "en",
		HZ43_VAN_N: constArr("HZ43_VAN_N"), HZ43_VAN_MARK: constArr("HZ43_VAN_MARK"), HZ43_VAN_INFO: constArr("HZ43_VAN_INFO"),
		HZ43_VAN_A: constArr("HZ43_VAN_A"), HZ43_HID_MAX: constOf("HZ43_HID_MAX"), HZ43_VAN_FACE: constOf("HZ43_VAN_FACE"),
		hz43VanDump: function() {}, hz45Sync: function() {},
		passes: 0
	};
	const src = kind === "old" ? baseAs : as;
	for (const f of FUNCS) bind(h, src, f);
	if (kind === "new") for (const f of SHOW) bind(h, as, f);
	const blg = h.hz43VanBlgChrome;
	h.hz43VanBlgChrome = function(hide) { if (!hide) this.passes++; return blg(hide); };
	// hz43ShowVanilla's relevant effect here (its search and dump are not modeled): the same two calls in both trees
	h.hz43ShowVanilla = function() { this.hz43VanRestoreHid(); this.hz43VanBlgChrome(false); return true; };
	return h;
}
// The calls of one frame. Old (ff4c33f): sync sweep, place sweep (hz43VanChrome(false)), and the place sweep on every exit.
// New: the same call sites; on the exits hz43VanLate took the hz43VanSame branch (hz43ShowSweep). Style 3: the hide pass.
function frameCalls(h, kind, exits) {
	const calls = [];
	if (h.hzWatchStyle === 3) { calls.push(() => h.hz43VanChrome(true)); return calls; }
	calls.push(() => h.hz43SyncHide());
	calls.push(() => h.hz43VanChrome(false));
	for (let i = 0; i < exits; i++) calls.push(kind === "new" ? () => h.hz43ShowSweep() : () => h.hz43VanChrome(false));
	return calls;
}

// ---- 1. random frames: same visible state after every call, far fewer passes ----
if (!baseAs) {
	gitBase.report(baseRes, "ff4c33f", "old-vs-new chrome pass checks", expect);
} else {
	let oldPasses = 0, newPasses = 0, calls = 0, throwsSeen = 0;
	for (let seed = 1; seed <= 8; seed++) {
		const r = rng(500 + seed);
		const ta = buildTop(seed), tb = buildTop(seed);
		for (const t of [ta, tb]) { let i = 0; (function pos(c) { i++; c.x = (i * 37) % 211 - 40; c.y = (i * 53) % 97; c.scaleX = c.scaleY = 1 + (i % 3) * 0.05; if (c.kids) c.kids.forEach(pos); })(t); }   // N-4: distinct positions
		let style = 1 + Math.floor(r() * 2);
		const ho = makeHost("old", ta, style), hn = makeHost("new", tb, style);
		let bad = "";
		const flip = () => {
			const all = walkAll(ta, [], []);
			const p = all[2 + Math.floor(r() * (all.length - 2))];
			const v = r() < 0.5;
			at(ta, p).visible = v; at(tb, p).visible = v;
		};
		for (let step = 0; step < 400 && !bad; step++) {
			const q = r();
			if (q < 0.04) {   // style switch (1 / 2 / 3)
				style = 1 + Math.floor(r() * 3);
				for (const h of [ho, hn]) h.hzWatchStyle = style;
			} else if (q < 0.10) {   // LocalEnvironmentData
				const local = r() < 0.5, cruise = r() < 0.5, lang = r() < 0.15 ? "ja" : "en";
				for (const h of [ho, hn]) { h.hz43EnvLocal = local; h.hz43EnvCruise = cruise; h.hz43EnvLang = lang; }
			} else if (q < 0.13) {   // a BLG child added
				const nm = r() < 0.5 ? "instance" + Math.floor(r() * 900) : ["Grav_mc", "Oxygen_mc", "Autopilot_mc", "WatchOutline_mc", "BioAlertText"][Math.floor(r() * 5)];
				const vis = r() < 0.5;
				for (const t of [ta, tb]) { const c = add(t.kids[0], Clip(nm, true)); c.visible = vis; makeDoc(t); }
			} else if (q < 0.15) {   // a BLG child removed (torn down)
				const n = ta.kids[0].kids.length;
				if (n > 4) { const i = Math.floor(r() * n); for (const t of [ta, tb]) { const c = t.kids[0].kids.splice(i, 1)[0]; c.stage = null; c.parent = null; } }
			} else if (q < 0.17) {   // a Fix 1 force edge (rebuild / recapture / scan edge)
				ho.hz43ChrForce |= 15; hn.hz43ChrForce |= 15;
			}
			const nf = Math.floor(r() * 3);
			for (let k = 0; k < nf; k++) flip();
			const exits = 1 + Math.floor(r() * 3);
			const co = frameCalls(ho, "old", exits), cn = frameCalls(hn, "new", exits);
			for (let k = 0; k < co.length && !bad; k++) {
				let throwAt = -1;
				if (r() < 0.01) { throwAt = Math.floor(r() * ta.kids[0].kids.length); ta.kids[0].__throwAt = throwAt; tb.kids[0].__throwAt = throwAt; }
				let eo = null, en = null;
				try { co[k](); } catch (e) { eo = e; }
				try { cn[k](); } catch (e) { en = e; }
				ta.kids[0].__throwAt = -1; tb.kids[0].__throwAt = -1;
				if (eo || en) {
					throwsSeen++;
					ho.hz43OlDepth = 0; ho.hz43OlHave = false; ho.hz43OlRef = null; ho.hz43OlBlg = null;
					hn.hz43OlDepth = 0; hn.hz43OlHave = false; hn.hz43OlRef = null; hn.hz43OlBlg = null;
					// a throw stops the old sweep part-way, and the new one may not run at all (no edge): from here on the
					// next sweeping call must bring both trees to the same state; a mid-throw state itself may differ
					continue;
				}
				calls++;
				const a = snap(ta, ho), b = snap(tb, hn);
				if (a !== b) bad = "seed " + seed + " step " + step + " call " + k + " style " + style + ": " + firstDiff(a, b);
				if (k < co.length - 1 && r() < 0.3) flip();   // the native timeline between the calls (and between exits)
			}
		}
		oldPasses += ho.passes; newPasses += hn.passes;
		expect(!bad, "seed " + seed + ": 400 frames (timeline writes, payload changes, children added / torn down, styles 1 / 2 / 3, force edges, throws): same visible state after every call" + (bad ? " -- " + bad : ""));
	}
	expect(newPasses * 3 < oldPasses, "show passes: " + newPasses + " new vs " + oldPasses + " old over " + calls + " compared calls");
	expect(throwsSeen > 0, "throws covered: " + throwsSeen);
}

// ---- 2. hz43ShowNeed edges and the stale check ----
{
	const top = buildTop(77);
	const h = makeHost("new", top, 1);
	h.hz43SyncHide();
	expect(h.passes === 1 && (h.hz43ChrForce & 8) === 0, "first vanilla frame: one pass (force bit 8 and the unset record), bit 8 cleared after it");
	const before = h.passes;
	for (let i = 0; i < 50; i++) { h.hz43SyncHide(); h.hz43VanChrome(false); h.hz43ShowSweep(); }
	expect(h.passes === before, "steady frames: no pass (150 calls)");
	expect(h.hz43ShowLN > 5 && h.hz43ShowNm.slice(0, h.hz43ShowLN).filter((n) => n != null).every((n) => PAYLOAD.indexOf(n) >= 0), "the record holds the shown pieces; only the payload clips keep a name (" + h.hz43ShowLN + " pieces)");
	const blg = top.kids[0];
	const plain = blg.kids.find((c) => c.name === "Grav_mc");
	plain.visible = false;
	expect(h.hz43ShowNeed() === true, "a recorded piece hidden by someone else: stale");
	h.hz43ShowSweep();
	expect(plain.visible === true && h.hz43ShowNeed() === false, "the sweep shows it again (the old per-call write), then steady");
	const op = blg.kids.find((c) => c.name === "OffPlanet_mc");
	h.hz43EnvLocal = true; h.hz43EnvCruise = false;
	expect(h.hz43ShowNeed() === true, "a payload change that flips OffPlanet_mc's formula: stale");
	h.hz43ShowSweep();
	expect(op.visible === true && h.hz43ShowNeed() === false, "OffPlanet_mc follows the formula after the sweep");
	op.visible = false;
	expect(h.hz43ShowNeed() === true, "a payload clip off its formula: stale");
	h.hz43ShowSweep();
	const gone = blg.kids.find((c) => c.name === "Temperature_mc");
	gone.stage = null;
	expect(h.hz43ShowNeed() === true, "a recorded piece torn down (stage null): stale");
	gone.stage = STAGE; h.hz43ShowSweep();
	blg.kids.push(Clip("instance901", true)); makeDoc(top);
	expect(h.hz43ShowNeed() === true, "a BLG child count change: edge");
	h.hz43ShowSweep(); h.hz43ChrForce |= 8;
	expect(h.hz43ShowNeed() === true, "force bit 8: edge"); h.hz43ShowSweep();
	h.hzWatchStyle = 2;
	expect(h.hz43ShowNeed() === true, "style change 1 -> 2: edge"); h.hz43ShowSweep();
	h.hz43HidN = 1; h.hz43HidA = [blg.kids[0]];
	expect(h.hz43ShowNeed() === true, "a noted ref to restore: edge"); h.hz43ShowSweep();
	expect(h.hz43HidN === 0 && h.hz43ShowNeed() === false, "restored: steady again");
	const other = Clip("BottomLeftGroup_mc"); makeDoc(other); h.hzBlg = other;
	expect(h.hz43ShowNeed() === true, "a new BLG ref: edge"); h.hzBlg = blg; h.hz43ShowSweep();
	h.hz43ShowLN = 40;
	expect(h.hz43ShowNeed() === true, "a full record falls back to the old every-call sweep"); h.hz43ShowSweep();
	// the stale walk reads no name (the record keeps the payload names; plain pieces need only visible / stage)
	const stale = codeOnly(fnText(as, "hz43ShowStale").body);
	expect(stale.indexOf(".name") < 0 && stale.indexOf("hzFindByName") < 0 && stale.indexOf("getChildAt") < 0, "hz43ShowStale reads no clip name, does no search and walks no children");
}

// ---- 3. a throw mid-sweep ----
{
	const top = buildTop(91);
	const h = makeHost("new", top, 2);
	h.hz43SyncHide();
	top.kids[0].kids.find((c) => c.name === "Oxygen_mc").visible = false;
	top.kids[0].__throwAt = 3;
	let threw = false;
	try { h.hz43ShowSweep(); } catch (e) { threw = true; }
	h.hz43OlDepth = 0; h.hz43OlHave = false; h.hz43OlRef = null; h.hz43OlBlg = null;
	expect(threw && (h.hz43ChrForce & 8) !== 0, "a throw inside the sweep leaves force bit 8 set");
	const p = h.passes;
	h.hz43ShowSweep();
	expect(h.passes === p + 1 && (h.hz43ChrForce & 8) === 0 && top.kids[0].kids.find((c) => c.name === "Oxygen_mc").visible, "the next call sweeps the whole BLG again and clears it");
}

// ---- 4. hz43VanSame ----
{
	const h = { hzFrameN: 10, hz43VpF: 10, hz43VpVr: 3, hz43VpSaved: true, hz43VpSc: 1.25, hz43VrTick: 3, hzArrange: false, hzArrDrag: "", hz43VpKids: 5, hzBlg: { numChildren: 5 },
		hzLayHas: function(k) { return k === "Watch" ? this.saved : false; }, saved: true, sc: 1.25, hz43VanSc: function() { return this.sc; } };
	bind(h, as, "hz43VanSame");
	expect(h.hz43VanSame() === true, "same frame, same inputs: the exitFrame place is skipped");
	h.hzFrameN = 11; expect(h.hz43VanSame() === false, "a new frame: place"); h.hzFrameN = 10;
	h.hzArrange = true; h.hzArrDrag = "Watch"; expect(h.hz43VanSame() === false, "an Arrange drag of the watch: place on every call (as before)");
	h.hzArrDrag = "Compass"; expect(h.hz43VanSame() === true, "an Arrange drag of another card: skip"); h.hzArrange = false;
	h.sc = 1.5; expect(h.hz43VanSame() === false, "a scale change: place"); h.sc = 1.25;
	h.saved = false; expect(h.hz43VanSame() === false, "a saved-layout change: place"); h.saved = true;
	h.hz43VrTick = 4; expect(h.hz43VanSame() === false, "a resolve counter change: place"); h.hz43VrTick = 3;
	h.hzBlg.numChildren = 6; expect(h.hz43VanSame() === false, "review N-3: a BLG child added or swapped since the enterFrame place: place again"); h.hzBlg.numChildren = 5;
	h.hzBlg = null; expect(h.hz43VanSame() === false, "review N-3: BLG ref lost since the place: place again"); h.hzBlg = { numChildren: 5 };
	h.hz43VpSc = NaN; expect(h.hz43VanSame() === false, "never placed (NaN scale): place");
	const late = codeOnly(fnText(as, "hz43VanLate").body);
	expect(/\(this\.hzWatchStyle == 1 \|\| this\.hzWatchStyle == 2\) && this\.hz43VanSame\(\)/.test(late) && late.indexOf("this.hz43ShowSweep()") >= 0, "hz43VanLate: styles 1/2 only; the skip branch still runs the cheap check (and the sweep if stale)");
	const place = codeOnly(fnText(as, "hz43VanPlace").body);
	expect(/this\.hz43VpF = this\.hzFrameN;/.test(place) && place.indexOf("this.hz43VpSc = this.hz43VanSc();") >= 0 && place.indexOf("this.hz43VpKids = this.hzBlg != null ? this.hzBlg.numChildren : -1;") >= 0, "hz43VanPlace records the frame and inputs it placed with");
	expect(place.indexOf("this.hz43VanChrome(false);") >= 0 && codeOnly(fnText(as, "hz43VanChrome").body).indexOf("if(!hide) { this.hz43ShowSweep(); return; }") >= 0, "hz43VanPlace still calls hz43VanChrome(false), which goes through the gate");
}

// ---- 5. static ----
{
	const fns = SHOW.concat(["hz43VanSame"]);
	const all = fns.map((f) => codeOnly(fnText(as, f).body)).join("\n");
	expect(!/addEventListener|setInterval|setTimeout|new Timer|% \d|hzFindByName|getChildByName/.test(all), "the new functions add no timer, listener, frame-modulo term or search");
	expect(/this\.hz43ChrForce \|= 7;/.test(codeOnly(fnText(as, "hz43VanRestoreHid").body)) && !/\|= 15/.test(fnText(as, "hz43VanRestoreHid").body), "hz43VanRestoreHid keeps |= 7 (no bit 8)");
	expect((as.match(/this\.hz43ChrForce \|= 15;/g) || []).length === 4 && /this\.hz43ChrForce \|= 11;/.test(codeOnly(fnText(as, "hzOnFrame").body)), "scan edge, both recaptures and the scan hide set bit 8 (|= 15); the hide-list rebuild sets it too (|= 11)");
	expect(/private var hz43ChrForce:int = 15;/.test(as), "bit 8 starts set (the first vanilla frame sweeps)");
	const sync = codeOnly(fnText(as, "hz43SyncHide").body);
	expect(sync.indexOf("this.hz43ShowSweep();") >= 0 && sync.indexOf("hz43VanBlgChrome(false)") < 0, "hz43SyncHide: the per-frame sweep goes through the gate");
	expect(/if\(!hide\) \{ this\.hz43ShowLN = 0; \}/.test(codeOnly(fnText(as, "hz43VanBlgChrome").body)) && /this\.hz43ShowAdd\(d,n\);/.test(fnText(as, "hz43VanBlgChrome").body), "hz43VanBlgChrome(false) records the pieces it shows");
	expect(/d\.alpha/.test(all) === false, "no alpha write (vanilla parts stay alpha-hidden or shown by the game, never removed)");
}

console.log((failed ? failed + " FAILED" : "all passed") + " (" + passed + " ok)");
process.exit(failed ? 1 : 0);
