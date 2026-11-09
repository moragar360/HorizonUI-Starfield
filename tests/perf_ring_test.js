// Option B (private diagnostic build) tests: per-callback timers, the per-frame memory
// sample, and the 256-slot AS event ring. Production functions are extracted from
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
	"hzPbFreq", "hzPbJet", "hzPbXh", "hzPbAct", "hzPbItems", "hzPbEnemy", "hzPbEn26", "hzPbRoll", "hzPerfRing"];
const WRAPS = [["hzPbFrame", "hzOnFrame"], ["hzPbExit", "hz27OnExit"], ["hzPbCompass", "hzOnCompass"], ["hzPbFreq", "hzOnPlayerFrequent"],
	["hzPbJet", "hzOnJetpack"], ["hzPbXh", "hzOnCrosshair"], ["hzPbAct", "hzOnTgAct"], ["hzPbItems", "hzOnTgItems"],
	["hzPbEnemy", "hzOnTgEnemy"], ["hzPbEn26", "hz26OnEnemy"], ["hzPbRoll", "hzOnTgRoll"]];

function load(sys) {
	const self = {
		hzPerfOn: true, hzPbN: null, hzRgTy: null, hzRgT0: null, hzRgT1: null, hzRgV: null, hzRgC: null,
		hzRgW: 0, hzRgOpC: -1, hzRgOpQ: -1, hzMemUnsup: false, hzMemN: 0, hzMemLast: 0, hzMemMin: 0, hzMemMax: 0,
		hzMemDrops: 0, hzMemDropKB: 0, hzPerfClockFb: false, now: 1000, calls: [],
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
		self[name] = eval("(function(self, System){ return function(" + funcParams(as, name).join(",") + "){ " + inner + " }; })")(self, System);
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
	expect(p.hzPbN.length === 33 && p.hzRgTy.length === 256 && p.hzRgC.length === 256, "storage preallocated once (11 probes)");
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
	for (let i = 0; i < 300; i++) { q.now += 100; q.hzRgPush(1, q.now, 0); }
	const s = q.hzPerfRing();
	expect(s.indexOf("ring now=" + q.now + " n=256 lost=45 memUnsupported=0 timerUnsupported=0|") === 0, "ring header after wrap");
	const slots = s.split("|")[1].split(";").filter(Boolean);
	expect(slots.length === 256 && slots[0] === "1," + (q.now - 255 * 100) + "," + (q.now - 255 * 100) + ",0,1", "oldest kept slot first");
	const tyRef = q.hzRgTy;
	q.hzPbClear();
	expect(q.hzRgW === 0 && q.hzPbN.every((v) => v === 0) && q.hzMemDrops === 0 && q.hzRgTy === tyRef, "clear resets without reallocating");
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
expect(funcBody(as, "hzQSync").indexOf("if(this.hzPerfOn) { this.hzRgPush(4,") >= 0, "hzQSync records Q behind PerfDiag");
expect(funcBody(as, "hzOnTgAct").indexOf("if(this.hzPerfOn) { this.hzRgPush(1,") >= 0, "target change records T behind PerfDiag");
expect(as.indexOf("import flash.system.System") < 0, "injected block has no System import (host gate)");
for (const name of ["hzPbEnd", "hzRgPush", "hzMemTick", "hzPbFrame", "hzPbExit", "hzPbCompass", "hzPbFreq", "hzPbJet", "hzPbXh", "hzPbAct",
	"hzPbItems", "hzPbEnemy", "hzPbEn26", "hzPbRoll"]) {
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
