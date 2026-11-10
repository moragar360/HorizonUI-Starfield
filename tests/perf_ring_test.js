// Option B (private diagnostic build) tests: per-callback timers, the per-frame memory
// sample, the 2048-slot AS event ring, and the parts build (chained section marks, S events,
// counters, hzPerfParts). Production functions are extracted from
// horizon_block.as and executed. PerfDiag=0 must call the original handler unchanged.
// Run: node tests/perf_ring_test.js
// Author: Moragar. Last modified: 2026-11-09.
"use strict";

const fs = require("fs");
const path = require("path");

function readText(p) {
	return fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

const root = path.join(__dirname, "..");
const as = readText(path.join(root, "actionscript", "horizon_block.as"));
const main = readText(path.join(root, "src", "main.cpp"));
const perfH = readText(path.join(root, "src", "hz_perf.h"));

let failed = 0;
function expect(cond, msg) {
	if (cond) {
		console.log("ok  " + msg);
		return;
	}
	failed++;
	console.error("FAIL " + msg);
}

function funcBody(src, name) {
	const key = "function " + name + "(";
	const i = src.indexOf(key);
	if (i < 0) return "";
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") {
			depth--;
			if (depth === 0) return src.slice(brace, p + 1);
		}
	}
	return "";
}

function funcParams(src, name) {
	const key = "function " + name + "(";
	const i = src.indexOf(key);
	if (i < 0) return [];
	const close = src.indexOf(")", i);
	return src.slice(i + key.length, close).split(",").map(function (p) {
		p = p.trim();
		if (!p) return "";
		return p.split(":")[0].trim();
	}).filter(Boolean);
}

function as3toJs(body) {
	let s = body;
	s = s.replace(/\bvar\s+(\w+)\s*:\s*[\w\.\*]+\s*/g, "var $1 ");
	s = s.replace(/\bint\(/g, "Math.trunc(");
	s = s.replace(/catch\s*\(\s*(\w+)\s*:\s*[\w\.]+\)/g, "catch($1)");
	s = s.replace(/\bthis\./g, "self.");
	return s;
}

const NAMES = ["hzPbInit", "hzPbClear", "hzPbEnd", "hzRgPush", "hzMemTick", "hzPbFrame", "hzPbExit", "hzPbCompass",
	"hzPbFreq", "hzPbJet", "hzPbXh", "hzPbAct", "hzPbItems", "hzPbEnemy", "hzPbEn26", "hzPbRoll", "hzPerfRing",
	"hzRgPushS", "hzPsStart", "hzPsMark", "hzPsSpan", "hzPsAdd", "hzPsCal", "hzPerfParts"];
const WRAPS = [["hzPbFrame", "hzOnFrame"], ["hzPbExit", "hz27OnExit"], ["hzPbCompass", "hzOnCompass"], ["hzPbFreq", "hzOnPlayerFrequent"],
	["hzPbJet", "hzOnJetpack"], ["hzPbXh", "hzOnCrosshair"], ["hzPbAct", "hzOnTgAct"], ["hzPbItems", "hzOnTgItems"],
	["hzPbEnemy", "hzOnTgEnemy"], ["hzPbEn26", "hz26OnEnemy"], ["hzPbRoll", "hzOnTgRoll"]];

function load(sys) {
	const self = {
		hzPerfOn: true, hzPbN: null, hzRgTy: null, hzRgT0: null, hzRgT1: null, hzRgV: null, hzRgC: null,
		hzRgW: 0, hzRgOpC: -1, hzRgOpQ: -1, hzMemUnsup: false, hzMemN: 0, hzMemLast: 0, hzMemMin: 0, hzMemMax: 0,
		hzMemDrops: 0, hzMemDropKB: 0, hzPerfClockFb: false, now: 1000, calls: [],
		hzPsN: null, hzPsS: null, hzPsT: 0, hzPsF0: 0, hzPsA0: 0, hzPcFind: 0, hzPcHideRb: 0, hzPcBlgCh: 0, hzPcStHide: 0, hzPcFmt: 0,
		hzPerfMode: 0, hzTexts: [1, 2, 3], hzFades: [1], hzHideCache: null, hzBlg: null, hzWatchStyle: 3, hzCrossRule: 1,
		hzXhStyle: 2, hzTextShadow: true, hzCompact: false, hzNameHover: 0, hzFontFace: 1, hzTextScale: 1.1,
		hzHideVanillaWatch: true, hzHideVanillaCompass: false,
		hzPerfNow() { return self.now; },
		hzOnFrame(e) { self.calls.push(["frame", e]); self.now += 3; },
		hz27OnExit(e) { self.calls.push(["exit", e]); self.now += 1; },
		hzOnCompass(e) { self.calls.push(["cmp", e]); self.now += 2; return "rc"; },
		hzOnPlayerFrequent(e) { self.calls.push(["freq", e]); return "rf"; },
		hzOnJetpack(e) { self.calls.push(["jet", e]); return "rj"; },
		hzOnCrosshair(e) { self.calls.push(["xh", e]); return "rx"; },
		hzOnTgAct(e) { self.calls.push(["act", e]); self.now += 4; return "ra"; },
		hzOnTgItems(e) { self.calls.push(["items", e]); self.now += 5; return "ri"; },
		hzOnTgEnemy(e) { self.calls.push(["enemy", e]); self.now += 6; return "re"; },
		hz26OnEnemy(e) { self.calls.push(["en26", e]); self.now += 7; return "r26"; },
		hzOnTgRoll(e) { self.calls.push(["roll", e]); self.now += 8; return "rr"; }
	};
	const System = sys;
	for (const name of NAMES) {
		const body = funcBody(as, name);
		if (!body) throw new Error("missing " + name);
		const inner = as3toJs(body).replace(/^\{\s*/, "").replace(/\s*\}$/, "");
		self[name] = eval("(function(self, System){ return function(" + funcParams(as, name).join(",") + "){ " + inner + "\n}; })")(self, System);
	}
	return self;
}

// PerfDiag=0: one boolean test, then the original handler with the same argument and return value.
{
	const p = load({ totalMemory: 1 << 24 });
	p.hzPerfOn = false;
	const ev = { data: 1 };
	expect(p.hzPbCompass(ev) === "rc" && p.hzPbFreq(ev) === "rf" && p.hzPbJet(ev) === "rj" && p.hzPbXh(ev) === "rx"
		&& p.hzPbAct(ev) === "ra", "off: wrappers return the original handler's value");
	expect(p.hzPbItems(ev) === "ri" && p.hzPbEnemy(ev) === "re" && p.hzPbEn26(ev) === "r26" && p.hzPbRoll(ev) === "rr",
		"off: S2 wrappers (items, enemy, en26, roll) return the original handler's value");
	p.hzPbFrame(ev);
	p.hzPbExit(ev);
	expect(p.calls.length === 11 && p.calls.every((c) => c[1] === ev), "off: every original handler ran once with the same event");
	expect(p.now === 1000 + 3 + 1 + 2 + 4 + 5 + 6 + 7 + 8, "off: no clock reads beyond the handlers themselves");
	expect(p.hzPbN === null && p.hzRgTy === null, "off: no probe storage is created");
}
for (const name of NAMES.filter((n) => n.indexOf("hzPb") === 0 && n !== "hzPbInit" && n !== "hzPbClear" && n !== "hzPbEnd")) {
	const b = funcBody(as, name);
	const first = b.replace(/^\{\s*/, "").split("\n")[0];
	expect(/^if\(!this\.hzPerfOn\) \{ (return )?this\.\w+\(e\); (return; )?\}$/.test(first.trim()), name + ": first line is the single PerfDiag test");
}

// PerfDiag=1: timers, compass runs, memory drops, ring order and wrap.
{
	const p = load({ totalMemory: 64 << 20 });
	p.hzPbInit();
	expect(p.hzPbN.length === 33 && p.hzRgTy.length === 2048 && p.hzRgC.length === 2048, "storage preallocated once (11 probes, 2048 ring slots)");
	expect(p.hzPsN.length === 245 && p.hzPsN.every((v) => v === 0), "parts storage preallocated once (49 ids x 5)");
	expect(p.hzPsS.length === 49 && p.hzPsS.every((v) => v === 0), "S cap counters preallocated once (49 ids)");
	const keep = p.hzRgTy;
	p.hzPbInit();
	expect(p.hzRgTy === keep, "init is idempotent (no second allocation)");
	p.hzPbFrame({});
	expect(p.hzPbN[0] === 1 && p.hzPbN[1] === 3 && p.hzPbN[2] === 3 && p.hzMemN === 1, "loop timer and memory sample");
	p.hzPbExit({});
	p.hzPbAct({});
	expect(p.hzPbN[3] === 1 && p.hzPbN[4] === 1 && p.hzPbN[18] === 1 && p.hzPbN[19] === 4, "exit and act timers");
	expect(p.hzPbItems({}) === "ri" && p.hzPbEnemy({}) === "re" && p.hzPbEn26({}) === "r26" && p.hzPbRoll({}) === "rr",
		"on: S2 wrappers return the original value");
	expect(p.hzPbN[21] === 1 && p.hzPbN[22] === 5 && p.hzPbN[24] === 1 && p.hzPbN[25] === 6 && p.hzPbN[27] === 1 && p.hzPbN[28] === 7
		&& p.hzPbN[30] === 1 && p.hzPbN[31] === 8 && p.hzPbN[32] === 8, "on: items/enemy/en26/roll timers use slots 7-10");
	expect(p.hzRgW === 0, "S2 probes add no ring events");
	p.hzPbCompass({});
	p.now += 10;
	p.hzPbCompass({});
	expect(p.hzRgW === 1 && p.hzRgTy[0] === 2 && p.hzRgC[0] === 2 && p.hzRgV[0] === 2, "compass pushes within 50 ms fold into one C slot");
	p.hzRgPush(4, p.now, 0);
	p.hzPbCompass({});
	expect(p.hzRgW === 2 && p.hzRgC[0] === 3, "an interleaved Q does not break the C run");
	p.hzRgPush(1, p.now, 0);
	p.hzPbCompass({});
	expect(p.hzRgW === 4 && p.hzRgTy[3] === 2, "a T event closes open C/Q runs");
	p.now += 200;
	p.hzPbCompass({});
	expect(p.hzRgW === 5, "a gap over 50 ms starts a new C slot");
	const sys = { totalMemory: 64 << 20 };
	const q = load(sys);
	q.hzPbInit();
	q.hzMemTick();
	sys.totalMemory = (64 << 20) - 100 * 1024;
	q.hzMemTick();
	expect(q.hzMemDrops === 0, "a 100 KB fall is not a drop");
	sys.totalMemory = (64 << 20) - 1024 * 1024;
	q.now = 2000;
	q.hzMemTick();
	expect(q.hzMemDrops === 1 && q.hzRgTy[0] === 3 && q.hzRgV[0] === 924 && q.hzRgT0[0] === 2000, "a fall over 256 KB is an M event in KB");
	for (let i = 0; i < 2092; i++) { q.now += 100; q.hzRgPush(1, q.now, 0); }
	const s = q.hzPerfRing();
	expect(s.indexOf("ring now=" + q.now + " n=2048 lost=45 memUnsupported=0 timerUnsupported=0|") === 0, "ring header after wrap (2048 slots)");
	const slots = s.split("|")[1].split(";").filter(Boolean);
	expect(slots.length === 2048 && slots[0] === "1," + (q.now - 2047 * 100) + "," + (q.now - 2047 * 100) + ",0,1", "oldest kept slot first");
	const tyRef = q.hzRgTy;
	q.hzPbClear();
	q.hzPsN[7] = 5; q.hzPsS[3] = 40; q.hzPcFind = 9; q.hzPcFmt = 4; q.hzPcBlgCh = 3; q.hzPcStHide = 2; q.hzPcHideRb = 1; q.hzPsT = 77;
	const psRef = q.hzPsN;
	const ssRef = q.hzPsS;
	q.hzPbClear();
	expect(q.hzRgW === 0 && q.hzPbN.every((v) => v === 0) && q.hzMemDrops === 0 && q.hzRgTy === tyRef, "clear resets without reallocating");
	expect(q.hzPsN === psRef && q.hzPsN.every((v) => v === 0) && q.hzPcFind === 0 && q.hzPcFmt === 0 && q.hzPcBlgCh === 0
		&& q.hzPcStHide === 0 && q.hzPcHideRb === 0 && q.hzPsT === 0, "clear resets parts and counters without reallocating");
	expect(q.hzPsS === ssRef && q.hzPsS.every((v) => v === 0), "clear resets the S cap counters without reallocating");
	q.hzPerfOn = false;
	expect(q.hzPerfRing() === "ring diag=0", "ring is empty when PerfDiag is off");
}

// Missing System import or a 0 reading: memUnsupported=1, sticky, no throw.
{
	const p = load(undefined);
	p.hzPbInit();
	let threw = false;
	try { p.hzMemTick(); } catch (e) { threw = true; }
	expect(!threw && p.hzMemUnsup === true, "unresolved System sets memUnsupported");
	const z = load({ totalMemory: 0 });
	z.hzPbInit();
	z.hzMemTick();
	expect(z.hzMemUnsup === true && z.hzPerfRing().indexOf("memUnsupported=1") > 0, "zero totalMemory sets memUnsupported");
}

// S1: a missing getTimer import is sticky; later calls neither throw nor allocate a Date.
{
	const body = funcBody(as, "hzPerfNow");
	const inner = as3toJs(body).replace(/^\{\s*/, "").replace(/\s*\}$/, "");
	let dates = 0;
	const FakeDate = function () { dates++; this.getTime = function () { return 123456; }; };
	const self = { hz41NowFn: null, hzPerfClockFb: false };
	const fn = eval("(function(self, Date){ return function(){ " + inner + " }; })")(self, FakeDate);
	let threw = false;
	let v1 = null;
	let v2 = null;
	try { v1 = fn(); v2 = fn(); fn(); fn(); } catch (e) { threw = true; }
	expect(!threw && self.hzPerfClockFb === true, "S1: unresolved getTimer sets the sticky flag without throwing");
	expect(v1 === 123456 && dates === 1 && v2 === 0, "S1: one Date fallback on the first failure, then 0 with no Date");
	const first = inner.trim().split("\n").map((s) => s.trim()).filter((s) => s.indexOf("self.hzPerfClockFb") >= 0)[0] || "";
	expect(first === "if(self.hzPerfClockFb) { return 0; }   // Option B S1: sticky, no throw, no Date per call", "S1: sticky check comes before any try");
	const p = load({ totalMemory: 1 << 24 });
	p.hzPbInit();
	p.hzPerfClockFb = true;
	expect(p.hzPerfRing().indexOf(" timerUnsupported=1|") > 0, "S1: ring header reports timerUnsupported=1");
	expect(funcBody(as, "hzPerfSnapshot").indexOf('" timerUnsupported=" + (this.hzPerfClockFb ? 1 : 0)') >= 0, "S1: snapshot reports timerUnsupported");
	expect(funcBody(as, "hzPerfEnd").indexOf("if(dt < 0) { dt = 0; }") >= 0, "S1: the one Date-to-0 step cannot add a negative tick");
}

// ---- Parts build: section probes, S events, counters, hzPerfParts ----
const PS_PROBE_FNS = new Set(["hzPerfNow", "hzPsStart", "hzPsMark", "hzPsSpan", "hzPsAdd", "hzPsCal", "hzRgPush", "hzRgPushS",
	"hzPbEnd", "hzMemTick", "hzPerfBegin", "hzPerfEnd"]);
const PS_REAL = ["hzOnFrame", "hz26Tick", "hz27OnExit", "hzOnCompass", "hzQSync", "hzPbFrame", "hzPbExit", "hzPbCompass", "hzPbEnd",
	"hzRgPush", "hzRgPushS", "hzPsStart", "hzPsMark", "hzPsSpan", "hzPsAdd", "hzPsCal", "hzPbInit", "hzMemTick", "hzPerfRing", "hzPerfParts"];
const PS_CONST = { HZ_W: 1920, HZ_CMP_W: 520, HZ_CARD: ["N", "NE", "E", "SE", "S", "SW", "W", "NW"], HZ_Q19_W: 400, HZ_CQ19_W: 300, HZ_ACCENT: 0xffffff };

function asToJs2(body) {
	let s = as3toJs(body);
	s = s.replace(/for each\(var (\w+) in /g, "for (var $1 of ");
	s = s.replace(/ as (Array|DisplayObjectContainer|DisplayObject)\b/g, "");
	return s;
}

// A scripted HUD: every hz* method that is not one of PS_REAL is a stub that logs its name and costs
// 1 ms (or slow[name] ms). The clock only moves inside stubs, so section sums are exact.
function psHud(on, slow) {
	const trace = [];
	const marks = [];
	const clock = { now: 5000 };
	const kids = [{ name: "A_mc", visible: true }, { name: "Bio_mc", visible: true }, { name: "C_mc", visible: false }];
	const st = {
		hzPerfOn: on, hzPerfMode: 0, hzPerfClockFb: false, hzPbN: null, hzRgTy: null, hzRgT0: null, hzRgT1: null, hzRgV: null, hzRgC: null,
		hzRgW: 0, hzRgOpC: -1, hzRgOpQ: -1, hzMemUnsup: false, hzMemN: 0, hzMemLast: 0, hzMemMin: 0, hzMemMax: 0, hzMemDrops: 0, hzMemDropKB: 0,
		hzPsN: null, hzPsS: null, hzPsT: 0, hzPsF0: 0, hzPsA0: 0, hzPcFind: 0, hzPcHideRb: 0, hzPcBlgCh: 0, hzPcStHide: 0, hzPcFmt: 0, hzPerfN: null,
		hzFrameN: 0, hzHideCache: null, hz36HideStale: false, hzHideTries: 0, hzHideVanillaBoost: true, hzHideVanillaCompass: true,
		hzWatchStyle: 0, hzHideVanillaWatch: true, hzHideVanillaAmmo: true, hzHideVanillaHealth: true,
		hzBlg: { numChildren: 3, getChildAt(i) { return kids[i]; } }, hzLaidOut: false, hzLayEver: true, hz30ModT0: 0, hzFontFace: 0,
		hzFontRetry: 6, hzPlanAlertOn: false, hzLowHealth: false, hz40Hide: true, hzSplashDead: false,
		hz26Built: true, hzGroupVisible: true, hzUserHidden: false, hz26St: null, hz26En: null, hz26EnT: 0, hz26XpGA: 0, hzArrange: false,
		hz26ChSig: "", hzCardColor: 0, hzTextScale: 1, hzDebug: false, HorizonEnemy_mc: null, HorizonStealth_mc: null,
		hzCmpLabels: [], hzCmpCenter: {}, HorizonQuest_mc: {}, hzCmpDeg: 0, hzCmpData: null,
		hzQName: "Q", hzQObjStr: "", hzQDistStr: "", hzQ19T: null, hzCQ19T: null,
		hzTexts: [], hzFades: [], hzCrossRule: 0, hzXhStyle: 1, hzTextShadow: false, hzCompact: false, hzNameHover: 0
	};
	for (let i = 0; i < 8; i++) st.hzCmpLabels.push({ textWidth: 10 });
	const self = new Proxy(st, {
		get(t, k) {
			if (k in t) return t[k];
			if (typeof k === "string" && /^hz/.test(k)) {
				return function () { trace.push(k); clock.now += (slow && slow[k]) || 1; return undefined; };
			}
			return undefined;
		}
	});
	st.hzPerfNow = function () { trace.push("hzPerfNow"); return clock.now; };
	const sys = { totalMemory: 1 << 24 };
	for (const name of PS_REAL) {
		const body = funcBody(as, name);
		if (!body) throw new Error("missing " + name);
		const inner = asToJs2(body).replace(/^\{\s*/, "").replace(/\s*\}$/, "");
		const params = funcParams(as, name).join(",");
		const real = eval("(function(self, System, HZ_W, HZ_CMP_W, HZ_CARD, HZ_Q19_W, HZ_CQ19_W, HZ_ACCENT){ return function(" + params + "){ " + inner + "\n}; })")(
			self, sys, PS_CONST.HZ_W, PS_CONST.HZ_CMP_W, PS_CONST.HZ_CARD, PS_CONST.HZ_Q19_W, PS_CONST.HZ_CQ19_W, PS_CONST.HZ_ACCENT);
		st[name] = function () {
			trace.push(name);
			if (name === "hzPsMark") marks.push(arguments[0]);
			if (name === "hzPsSpan") marks.push(arguments[0]);
			return real.apply(null, arguments);
		};
	}
	return { st, trace, marks, clock };
}
function psDrive(h) {
	for (let f = 0; f < 16; f++) h.st.hzPbFrame({});
	h.st.hzPbExit({});
	h.st.hzPbCompass({ data: { fDirection: 1.0, aMissionMarkers: [] } });
	h.st.hzQSync();
}

// PerfDiag=0: no clock read, no probe call, no storage, no counter; same calls in the same order as with PerfDiag=1.
{
	const off = psHud(false, null);
	psDrive(off);
	const offProbe = off.trace.filter((n) => PS_PROBE_FNS.has(n));
	expect(offProbe.length === 0, "parts off: no clock read and no probe call in frame, hz26, exit, compass or hzQSync");
	expect(off.st.hzPsN === null && off.st.hzRgTy === null && off.st.hzPcBlgCh === 0 && off.st.hzPcHideRb === 0,
		"parts off: no probe storage and no counter writes");
	const on = psHud(true, { hz43Frame: 4 });
	on.st.hzPbInit();
	psDrive(on);
	const onCalls = on.trace.filter((n) => !PS_PROBE_FNS.has(n) && n !== "hzPbInit");
	expect(onCalls.length === off.trace.length && onCalls.every((n, i) => n === off.trace[i]),
		"parts on: the HUD calls are the same and in the same order as with PerfDiag=0 (" + off.trace.length + " calls)");
	const frame = [];
	for (let k = 0; k <= 19; k++) frame.push(k);
	for (let k = 26; k <= 33; k++) frame.push(k);
	frame.push(20, 21, 22, 23, 24, 25);
	const want = [];
	for (let f = 0; f < 16; f++) want.push(...frame);
	want.push(34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46);
	expect(on.marks.length === want.length && on.marks.every((k, i) => k === want[i]),
		"parts on: section ids fire in source order (frame 0-25 with hz26 parts 26-33 inside 20, exit 34-39, compass 40-45, qSync 46)");
	const ps = on.st.hzPsN;
	let frameSum = 0;
	for (let k = 0; k <= 25; k++) frameSum += ps[k * 5 + 1];
	expect(frameSum === on.st.hzPbN[1], "parts on: frame sections 0-25 add up to the loop total exactly (" + frameSum + " ms)");
	let h26Sum = 0;
	for (let k = 26; k <= 33; k++) h26Sum += ps[k * 5 + 1];
	expect(h26Sum <= ps[20 * 5 + 1] && ps[20 * 5] === 16, "parts on: hz26 parts sit inside the h26 span");
	let exitSum = 0;
	for (let k = 34; k <= 39; k++) exitSum += ps[k * 5 + 1];
	expect(exitSum === on.st.hzPbN[4] && ps[34 * 5] === 1, "parts on: exit parts add up to the exit total");
	let cmpSum = 0;
	for (let k = 40; k <= 45; k++) cmpSum += ps[k * 5 + 1];
	expect(cmpSum === on.st.hzPbN[7], "parts on: compass parts add up to the compass total");
	expect(ps[46 * 5] === 1 && ps[25 * 5] === 16 && ps[25 * 5 + 1] === 0, "parts on: qSync span and one calibration sample per frame");
	expect(on.st.hzPcHideRb === 1 && on.st.hzPcBlgCh === 48, "parts on: hide rebuild and BottomLeftGroup child counters");
	expect(ps[16 * 5] === 16 && ps[16 * 5 + 1] === 64 && ps[16 * 5 + 2] === 4, "parts on: h43 n, sumMs, maxMs");
	const ring = on.st.hzPerfRing();
	const sl = ring.split("|")[1].split(";").filter(Boolean);
	const sH43 = sl.filter((x) => /^5,/.test(x) && /,4,16$/.test(x)).length;
	const sLoop = sl.filter((x) => /^5,/.test(x) && /,47$/.test(x)).length;
	expect(sH43 === 16 && sLoop === 16, "parts on: a 4 ms section and each slow loop total are S events");
	expect(sl.filter((x) => /^5,/.test(x) && /,48$/.test(x)).length === 0, "parts on: a 6 ms exit total is under the 8 ms bar");
}

// Thresholds: section 3 ms, loop total 15 ms, exit total 8 ms. Compass totals stay C events.
{
	const p = load({ totalMemory: 1 << 24 });
	p.hzPbInit();
	p.hzPsAdd(5, 100, 102);
	expect(p.hzRgW === 0 && p.hzPsN[25] === 1 && p.hzPsN[26] === 2, "a 2 ms section is counted, not an S event");
	p.hzPsAdd(5, 200, 203);
	expect(p.hzRgW === 1 && p.hzRgTy[0] === 5 && p.hzRgV[0] === 3 && p.hzRgC[0] === 5 && p.hzRgT0[0] === 200, "a 3 ms section is an S event with its id");
	p.hzPsAdd(6, 300, 299);
	expect(p.hzPsN[31] === 0 && p.hzRgW === 1, "a negative section clamps to 0");
	p.now = 1000;
	p.hzPbEnd(0, 986);
	expect(p.hzRgW === 1, "loop total 14 ms: no S");
	p.hzPbEnd(0, 985);
	expect(p.hzRgW === 2 && p.hzRgC[1] === 47 && p.hzRgV[1] === 15, "loop total 15 ms: S part 47");
	p.hzPbEnd(1, 993);
	expect(p.hzRgW === 2, "exit total 7 ms: no S");
	p.hzPbEnd(1, 992);
	expect(p.hzRgW === 3 && p.hzRgC[2] === 48 && p.hzRgV[2] === 8, "exit total 8 ms: S part 48");
	p.hzPbEnd(2, 940);
	expect(p.hzRgW === 4 && p.hzRgTy[3] === 2 && p.hzRgV[3] === 60, "a slow compass push stays a C event");
	p.hzPsAdd(41, 960, 965);
	p.now = 1010;
	p.hzPbEnd(2, 980);
	expect(p.hzRgW === 5 && p.hzRgC[3] === 2, "an S event does not close an open C run");
	p.hzPsStart(2000);
	p.hzPcFind = 7; p.hzPcFmt = 2; p.now = 2001;
	p.hzPsMark(8);
	expect(p.hzPsN[43] === 7 && p.hzPsN[44] === 2 && p.hzPsT === 2001, "a chained mark books finds and fmts since the last mark");
	p.now = 2010;
	p.hzPsSpan(46, 2008, false);
	expect(p.hzPsT === 2001 && p.hzPsN[231] === 2, "a non-chained span leaves the running clock alone");
	p.hzPsSpan(20, 2001, true);
	expect(p.hzPsT === 2010 && p.hzPsN[101] === 9, "a chained span moves the running clock");
}

// Ring overflow with S events: 2048 kept, the rest counted as lost.
{
	const p = load({ totalMemory: 1 << 24 });
	p.hzPbInit();
	for (let i = 0; i < 2100; i++) {
		if (i % 41 === 0) p.hzRgPushS(10 + i, 3, i % 47);
		else p.hzRgPush(1, 10 + i, 0);
	}
	const s = p.hzPerfRing();
	expect(s.indexOf(" n=2048 lost=52 ") > 0, "ring overflow with S events keeps 2048 and counts 52 lost");
	const sl = s.split("|")[1].split(";").filter(Boolean);
	expect(sl.length === 2048 && sl[0] === "1,62,62,0,1" && sl[2039] === "5,2101,2101,3," + (2091 % 47) && sl[2047] === "1,2109,2109,0,1",
		"S slots are ty,t0,t1,v,id in time order with the other events");
	// The joined string equals the old per-slot concatenation.
	let old = s.split("|")[0] + "|";
	for (let i = p.hzRgW - 2048; i < p.hzRgW; i++) {
		const j = i % 2048;
		old += Math.trunc(p.hzRgTy[j]) + "," + Math.round(p.hzRgT0[j]) + "," + Math.round(p.hzRgT1[j]) + "," + Math.round(p.hzRgV[j]) + "," + Math.trunc(p.hzRgC[j]) + ";";
	}
	expect(s === old, "Array join gives the same ring string as per-slot concatenation");
	expect(funcBody(as, "hzPerfRing").indexOf("a.join(\"\")") > 0 && funcBody(as, "hzPerfRing").indexOf("s +=") < 0, "S2: ring string is joined once, no growing +=");
}

// S1: S events are capped at 32 per id per window; the parts line keeps the full count and the dropped count.
{
	const p = load({ totalMemory: 1 << 24 });
	p.hzPbInit();
	for (let i = 0; i < 40; i++) p.hzRgPushS(100 + i, 5, 0);
	expect(p.hzRgW === 32 && p.hzPsS[0] === 40, "S cap: 40 slow samples of one id write 32 slots and count 40");
	p.hzRgPushS(200, 5, 34);
	expect(p.hzRgW === 33 && p.hzRgC[32] === 34, "S cap is per id: another id still gets a slot");
	p.now = 1000;
	for (let i = 0; i < 35; i++) p.hzPbEnd(0, 980);
	expect(p.hzRgW === 65 && p.hzPsS[47] === 35, "S cap applies to loopTotal too");
	const s = p.hzPerfParts();
	expect(s.indexOf(" veh=0,0,0,0,0,40,8 ") > 0 && s.indexOf(" xBio=0,0,0,0,0,1,0 ") > 0, "parts line: slow and sDrop columns");
	expect(s.indexOf(" | sCap=32 loopTotal=35,3 exitTotal=0,0 | find=") > 0, "parts line: the two totals' slow and sDrop");
	const ring = p.hzPerfRing().split("|")[1].split(";").filter(Boolean);
	expect(ring[0] === "5,100,100,5,0", "S id 0 (veh) is written with id 0");
	p.hzPbClear();
	p.hzRgPushS(300, 5, 0);
	expect(p.hzRgW === 1 && p.hzPsS[0] === 1, "the cap restarts each window (hzPbClear)");
	// Worst case: 49 ids at 2048 x 32 capped slots cannot exceed the ring; the cap bounds S at 49 x 32 = 1568 slots.
	const q = load({ totalMemory: 1 << 24 });
	q.hzPbInit();
	for (let r = 0; r < 100; r++) for (let id = 0; id < 49; id++) q.hzRgPushS(r, 3, id);
	expect(q.hzRgW === 49 * 32, "S flood from every id stops at 1568 slots, under 2048");
}

// hzPerfParts: one line, ids match the native names, counters, lists and the settings echo.
{
	const p = load({ totalMemory: 1 << 24 });
	p.hzPerfOn = false;
	expect(p.hzPerfParts() === "parts diag=0", "parts line is empty when PerfDiag is off");
	p.hzPerfOn = true;
	p.hzPbInit();
	p.hzPsN[0] = 3; p.hzPsN[1] = 4; p.hzPsN[2] = 2; p.hzPsN[3] = 1; p.hzPsN[4] = 5;
	p.hzPcFind = 11; p.hzPcBlgCh = 22; p.hzPcFmt = 33;
	const s = p.hzPerfParts();
	expect(s.indexOf("parts diag=1 mode=0 loopN=0 exitN=0 cmpN=0 cols=n,sumMs,maxMs,finds,fmts,slow,sDrop veh=3,4,2,1,5,0,0 h40=0,0,0,0,0,0,0") === 0, "parts line head and first ids");
	expect(s.indexOf(" | find=11 hideRb=0 blgCh=22 stHide=0 fmtCalls=33 | texts=3 fades=1 hideCache=-1 blgN=-1 | ") > 0, "parts counters and list sizes");
	expect(s.indexOf("WatchStyle=3 CrosshairRule=1 CrosshairStyle=2 TextShadow=1 Compact=0 NameHover=0 FontFace=1 TextScale=1.1 HideVanillaWatch=1 HideVanillaCompass=0 timerUnsupported=0") > 0,
		"parts settings echo");
	const kPartsMax = Number((perfH.match(/kPartsMax = (\d+);/) || [0, 0])[1]);
	expect(kPartsMax === 8192 && s.length < kPartsMax, "parts line fits kPartsMax (" + s.length + " chars)");
	const asNames = (s.match(/ (\w+)=\d+,\d+,\d+,\d+,\d+,\d+,\d+/g) || []).map((x) => x.trim().split("=")[0]);
	const m = perfH.match(/static const char\* const k\[kPartCount\] = \{([\s\S]*?)\};/);
	const nat = m ? m[1].match(/"(\w+)"/g).map((x) => x.replace(/"/g, "")) : [];
	expect(asNames.length === 47 && nat.length === 49 && asNames.every((n, i) => n === nat[i]) && nat[47] === "loopTotal" && nat[48] === "exitTotal",
		"AS part ids match hzperf::PartName (47 parts + 2 totals)");
	// S2 worst case: every column and counter at int max, long settings.
	for (let i = 0; i < 245; i++) p.hzPsN[i] = 2147483647;
	for (let i = 0; i < 49; i++) p.hzPsS[i] = 2147483647;
	p.hzPbN[0] = p.hzPbN[3] = p.hzPbN[6] = 2147483647;
	p.hzPcFind = p.hzPcHideRb = p.hzPcBlgCh = p.hzPcStHide = p.hzPcFmt = 2147483647;
	p.hzPerfMode = 7; p.hzTexts = new Array(99999); p.hzFades = new Array(99999); p.hzHideCache = new Array(99999); p.hzBlg = { numChildren: 99999 };
	p.hzWatchStyle = 2147483647; p.hzCrossRule = 2147483647; p.hzXhStyle = 2147483647; p.hzNameHover = 2147483647; p.hzFontFace = 2147483647;
	p.hzTextScale = 1.2345678901234567; p.hzPerfClockFb = true;
	const w = p.hzPerfParts();
	expect(w.length < kPartsMax * 0.75, "S2: worst-case parts line is " + w.length + " chars, well under kPartsMax " + kPartsMax);
	const kRingAsMax = Number((perfH.match(/kRingAsMax = (\d+);/) || [0, 0])[1]);
	const r = load({ totalMemory: 1 << 24 });
	r.hzPbInit();
	r.now = 999999999;
	for (let i = 0; i < 2048; i++) { r.hzRgTy[i] = 2; r.hzRgT0[i] = 999999999; r.hzRgT1[i] = 999999999; r.hzRgV[i] = 9999999; r.hzRgC[i] = 99; }
	r.hzRgW = 2147483647 - (2147483647 % 2048);
	r.hzMemUnsup = true; r.hzPerfClockFb = true;
	const rw = r.hzPerfRing();
	expect(kRingAsMax === 98304 && rw.length < kRingAsMax * 0.8, "S2: worst-case ring string is " + rw.length + " chars, well under kRingAsMax " + kRingAsMax);
}

// PerfDiag=0 identity, by source: every parts line is one PerfDiag test (or a plain local) and nothing else.
{
	const allowed = [
		/^if\(this\.hzPerfOn\) \{ this\.hzPsMark\(\d+\); \}$/,
		/^if\(this\.hzPerfOn\) \{ this\.hzPsSpan\(\d+,\w+,(true|false)\); \}$/,
		/^if\(this\.hzPerfOn\) \{ this\.hzPsCal\(\); this\.hzPsMark\(25\); \}$/,
		/^var p26:Number = this\.hzPerfOn \? this\.hzPsT : 0;$/,
		/^var tQs:Number = 0;$/,
		/^if\(this\.hzPerfOn\) \{ tQs = this\.hzPerfNow\(\); this\.hzRgPush\(4,tQs,0\); \}$/,
		/^if\(this\.hzPerfOn\) \{ this\.hzPc(HideRb|Find|Fmt|StHide|QsSkip|QsRun)\+\+; \}$/,
		/^if\(this\.hzPerfOn\) \{ this\.hzPcBlgCh \+= bi; \}$/
	];
	let lines = 0;
	let bad = 0;
	for (const name of ["hzOnFrame", "hz26Tick", "hz27OnExit", "hzOnCompass", "hzQSync", "hzFindByName", "hzApplyFmt", "hz43StHide"]) {
		for (let l of funcBody(as, name).split("\n")) {
			l = l.trim().replace(/\s+\/\/.*$/, "");
			if (!/hzPs|hzPc|\bp26\b|\btQs\b/.test(l)) continue;
			lines++;
			if (!allowed.some((r) => r.test(l))) { bad++; console.error("  unexpected parts line in " + name + ": " + l); }
		}
	}
	expect(lines === 58 && bad === 0, "parts source lines are single PerfDiag tests only (" + lines + " lines)");
	for (const pair of [["hzFindByName", "hzPcFind"], ["hzApplyFmt", "hzPcFmt"], ["hz43StHide", "hzPcStHide"]]) {
		const b = funcBody(as, pair[0]);
		expect(b.split("this." + pair[1] + "++").length === 2, pair[0] + ": one counter, behind PerfDiag");
	}
	expect(funcBody(as, "hzPsCal").replace(/\s/g, "") === "{}", "calibration probe is empty");
	expect(main.indexOf("HudInvoke(\"hzPerfRing\"") < main.indexOf("HudInvoke(\"hzPerfParts\"")
		&& main.indexOf("HudInvoke(\"hzPerfParts\"") < main.indexOf("HudInvoke(\"hzPerfSnapshot\""),
		"native reads hzPerfParts after the ring and before the snapshot resets it");
}

// Wiring and house rules.
expect(as.indexOf('addEventListener(Event.ENTER_FRAME,this.hzPbFrame)') >= 0 && as.indexOf('addEventListener("exitFrame",this.hzPbExit)') >= 0,
	"frame and exit listeners go through the probes");
expect(as.indexOf('"HudCompassData",this.hzPbCompass') >= 0 && as.indexOf('"PlayerFrequentData",this.hzPbFreq') >= 0
	&& as.indexOf('"HudJetpackData",this.hzPbJet') >= 0 && as.indexOf('"HudCrosshairData",this.hzPbXh') >= 0
	&& as.indexOf('"HUDRolloverActivationData",this.hzPbAct') >= 0, "callbacks go through the probes");
expect(as.indexOf('"HUDRolloverData",this.hzPbRoll') >= 0 && as.indexOf('"HudEnemyData",this.hzPbEnemy') >= 0
	&& as.indexOf('"HUDRolloverItemData",this.hzPbItems') >= 0 && as.indexOf('"HudEnemyData",this.hzPbEn26') >= 0,
	"S2: rollover, enemy, items and hz26 enemy go through the probes");
for (const w of WRAPS) {
	const re = new RegExp("Subscribe\\([^)]*this\\." + w[1] + "\\)|addEventListener\\([^)]*this\\." + w[1] + "\\)");
	expect(!re.test(as), w[1] + " is no longer registered directly");
}
expect(funcBody(as, "hzQSync").indexOf("if(this.hzPerfOn) { tQs = this.hzPerfNow(); this.hzRgPush(4,tQs,0); }") >= 0, "hzQSync records Q behind PerfDiag");
expect(funcBody(as, "hzOnTgAct").indexOf("if(this.hzPerfOn) { this.hzRgPush(1,") >= 0, "target change records T behind PerfDiag");
expect(as.indexOf("import flash.system.System") < 0, "injected block has no System import (host gate)");
for (const name of ["hzPbEnd", "hzRgPush", "hzMemTick", "hzPbFrame", "hzPbExit", "hzPbCompass", "hzPbFreq", "hzPbJet", "hzPbXh", "hzPbAct",
	"hzPbItems", "hzPbEnemy", "hzPbEn26", "hzPbRoll", "hzRgPushS", "hzPsStart", "hzPsMark", "hzPsSpan", "hzPsAdd", "hzPsCal"]) {
	const b = funcBody(as, name);
	expect(!/new |\[\]|\{\}|"|\+ "/.test(b.replace(/^\{/, "").replace(/\}$/, "").replace(/catch\(\w+:Error\) \{ m = -1; \}/, "")),
		name + ": no allocation or string in the probe");
}
expect(funcBody(as, "hzPerfSnapshot").indexOf("loop") >= 0 && funcBody(as, "hzPerfSnapshot").indexOf("memUnsupported=") >= 0,
	"snapshot carries probe and memory summary fields");
expect(main.indexOf("HudInvoke(\"hzPerfRing\"") >= 0 && main.indexOf("hzperf::ParseAsRing") >= 0 && main.indexOf("hzperf::FormatRingEv") >= 0,
	"native merges the AS ring");

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("ok perf_ring_test");
