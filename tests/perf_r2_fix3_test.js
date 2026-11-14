// perf round 2 Fix 3 tests: the hide-list missing-name retry is capped.
// Run: node tests/perf_r2_fix3_test.js   (HZ_AS=<file> runs it against another horizon_block.as)
// Before: one listed name that never exists (HideVanillaBoost lists a boost meter anim clip that the HUD never places)
// kept hzHideMiss true, so hzOnFrame did a full tree walk every 90 frames for the whole session.
// Proves, by running the production gate lines of hzOnFrame (the rbEdge term, the rebuild condition, rbRetry and the
// hzHideMissN update) on a small frame model:
//  0. the cap is per name (review nit): a name that goes missing during the retries gets its own 6;
//  1. a permanently missing name gives the first walk plus 6 retries, then no walk at all (e4d7b75: one per 90 frames);
//  2. a name that shows up during the retries is still picked up, and the retries then stop;
//  3. a real edge (BLG child count change, stale ref) still walks at once and resets the count, so a late name gets
//     6 fresh retries after each real edge;
//  4. static: hzOnFrame keeps exactly one 90-frame term, adds no timer, listener or search, and the count lives in a
//     plain int field.
// Author: Moragar. Last modified: 2026-11-14.
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
	const i = src.indexOf("private function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return src.slice(brace + 1, p); }
	}
	throw new Error("unbalanced " + name);
}
const body = fnText(as, "hzOnFrame");
const code = body.replace(/\/\/[^\n]*/g, "");
function line(re, what) {
	const m = code.match(re);
	if (!m) throw new Error("hzOnFrame: missing " + what);
	return m[0].trim();
}
const L_EDGE = line(/var rbEdge:Boolean = [^\n]*;/, "rbEdge");
const L_IF = line(/if\(this\.hzHideCache == null \|\| [^\n]*\)/, "rebuild condition");
const L_RETRY = line(/var rbRetry:Boolean = [^\n]*;/, "rbRetry");
const L_MISSN = line(/this\.hzHideMissN = [^\n]*;/, "hzHideMissN update");
const js = (s) => s.replace(/var (\w+):\w+/g, "var $1").replace(/this\./g, "self.");

// The production per-name counter (hzHideMissCount / hzHideMissReset), AS -> JS.
function asFn(name) {
	const i = as.indexOf("private function " + name + "(");
	const sig = as.slice(i, as.indexOf(")", i) + 1);
	const params = sig.slice(sig.indexOf("(") + 1, -1).split(",").map((x) => x.trim().split(":")[0]).filter(Boolean);
	const src = fnText(as, name).replace(/var (\w+):\w+/g, "var $1").replace(/this\./g, "self.")
		.replace(/int\.MAX_VALUE/g, "2147483647").replace(/\bint\(/g, "Math.trunc(").replace(/String\(/g, "String(");
	return new Function("self", ...params, src);
}
const missCount = asFn("hzHideMissCount"), missReset = asFn("hzHideMissReset");

// One frame of the model: the production lines, with the walk replaced by "which listed names are there now".
const step0 = eval("(function(self, rbKids, names, cacheNow, log){\n" +
	js(L_EDGE) + "\n" + js(L_IF) + " {\n" + js(L_RETRY) + "\n" +
	"self.hzHideKids = rbKids; self.hzHideCache = cacheNow; self.hz36HideStale = false; log.walks++; log.at.push(self.hzFrameN);\n" +
	"self.hzHideMiss = names.some(function(n){ return !cacheNow.some(function(o){ return o.n == n; }); });\n" + js(L_MISSN) + "\n}\n})");
function step(self, rbKids, present, log, names) {
	names = names || ["JetpackMeterAnim_mc"];
	const have = typeof present === "boolean" ? (present ? names : []) : present;
	return step0(self, rbKids, names, have.map((n) => ({ n })), log);
}

function fresh() {
	const self = { hzFrameN: 0, hzHideCache: null, hzHideKids: -2, hzHideMiss: false, hzHideMissN: 0, hzHideMissC: null, hz36HideStale: false, hzWlOn: false, hzWlMode: 0 };
	self.hzHideMissCount = (n, c, r) => missCount(self, n, c, r);
	self.hzHideMissReset = () => missReset(self);
	return self;
}
function run(frames, kidsAt, presentAt, staleAt, names) {
	const self = fresh(), log = { walks: 0, at: [] };
	for (let f = 1; f <= frames; f++) {
		self.hzFrameN = f;
		if (staleAt && staleAt(f)) self.hz36HideStale = true;
		step(self, kidsAt(f), presentAt(f), log, names);
	}
	return { self, log };
}

// ---- 1. a name that never exists ----
{
	const r = run(20000, () => 27, () => false);
	expect(r.log.walks === 7, "never-found name: first walk + 6 retries, then none (walks=" + r.log.walks + " in 20000 frames)");
	expect(r.log.at.slice(1).every((f) => f % 90 === 1), "the retries keep the old 90-frame spacing: " + r.log.at.join(","));
	expect(r.log.at[r.log.at.length - 1] <= 6 * 90 + 1, "the last retry is by frame " + (6 * 90 + 1) + " (about 4 s at 140 fps, 9 s at 60 fps)");
	expect(r.self.hzHideMiss === true && r.self.hzHideMissN === 6, "the miss is remembered (hzHideMiss stays true; count at the cap)");
	// the e4d7b75 rule on the same model: one walk every 90 frames all session
	const old = Math.floor((20000 - 1) / 90) + 1;
	expect(old > 200, "contrast: the e4d7b75 rule would walk " + old + " times in the same 20000 frames");
}

// ---- 2. a late name found during the retries ----
{
	const r = run(5000, () => 27, (f) => f >= 200);
	expect(r.log.walks === 4 && r.log.at[3] === 271, "a name that appears at frame 200 is found on the next retry (frame 271): " + r.log.at.join(","));
	expect(r.self.hzHideMiss === false && r.self.hzHideMissN === 0, "found: no miss, count back to 0, no more retries");
}

// ---- 3. real edges still walk and reset the count ----
{
	const r = run(20000, (f) => (f >= 5000 ? 28 : 27), () => false);
	expect(r.log.at.indexOf(5000) >= 0, "a BLG child count change walks on that frame even after the cap");
	expect(r.log.walks === 14, "the child count edge gives 6 fresh retries (1 + 6, then 1 + 6): walks=" + r.log.walks);
	const s = run(20000, () => 27, () => false, (f) => f === 9000);
	expect(s.log.at.indexOf(9000) >= 0 && s.log.walks === 14, "a stale-ref edge walks at once and resets the count too: walks=" + s.log.walks);
	const late = run(20000, (f) => (f >= 5000 ? 28 : 27), (f) => f >= 5100);
	expect(late.log.walks === 10 && late.log.at[9] === 5131 && late.self.hzHideMiss === false, "a name that appears after a real edge is found on the second fresh retry, frame 5131 (walks=" + late.log.walks + ")");
	// watchlog mode 1 (test switch) still skips the edge walk exactly as before
	const self = fresh(), log = { walks: 0, at: [] };
	self.hzFrameN = 1; step(self, 27, false, log);
	self.hzWlOn = true; self.hzWlMode = 1;
	for (let f = 2; f < 2000; f++) { self.hzFrameN = f; step(self, 27, false, log); }
	expect(log.walks === 1, "watchlog mode 1 still skips the retry walks");
}

// ---- 3b. the cap is per name (review nit) ----
{
	// two listed names: A never exists; B is there until frame 300, then gone (no child count change)
	const r = run(20000, () => 27, (f) => (f < 300 ? ["B"] : []), null, ["A", "B"]);
	// A: first walk + retries at 91, 181, 271 (B still found), then B goes missing at the 361 retry: B starts its own 6
	expect(r.log.walks === 1 + 3 + 6 && r.log.at[r.log.at.length - 1] === 361 + 5 * 90, "a second name that goes missing during the retries gets its own 6 retries (walks=" + r.log.walks + ": " + r.log.at.join(",") + ")");
	expect(r.self.hzHideMissC.A >= 6 && r.self.hzHideMissC.B === 6 && r.self.hzHideMissN === 6, "per-name counts: A " + r.self.hzHideMissC.A + ", B " + r.self.hzHideMissC.B + "; the retry stops once every missing name is at 6");
	// one name only: same walks as the global cap
	const g = run(20000, () => 27, () => false, null, ["A", "B"]);
	expect(g.log.walks === 7, "two names that never exist: still first walk + 6 retries (walks=" + g.log.walks + ")");
	const f = run(5000, () => 27, (fr) => (fr >= 200 ? ["A", "B"] : ["B"]), null, ["A", "B"]);
	expect(f.log.walks === 4 && f.self.hzHideMissN === 0 && f.self.hzHideMissC === null, "found: count map released, no more retries (walks=" + f.log.walks + ")");
}

// ---- 4. static ----
{
	expect((code.match(/% 90/g) || []).length === 1, "hzOnFrame keeps exactly one 90-frame term");
	expect(/this\.hzHideMiss && this\.hzHideMissN < 6 && this\.hzFrameN % 90 == 1/.test(L_EDGE), "the cap sits inside the retry term only (child count edge unchanged)");
	expect(/this\.hzHideMiss \? this\.hzHideMissCount\(names,this\.hzHideCache,rbRetry\) : this\.hzHideMissReset\(\)/.test(L_MISSN), "count: per name, +1 on a retry that still misses it, 0 on any real edge or a full find");
	expect(!/hzFindByName|hz36HideFind|getChildByName|addEventListener/.test(fnText(as, "hzHideMissCount")), "the per-name count does no search of its own (cache and name list only)");
	expect(/private var hzHideMissN:int = 0;/.test(as), "hzHideMissN is a plain int field");
	expect(!/addEventListener|setInterval|setTimeout|new Timer/.test(L_EDGE + L_IF + L_RETRY + L_MISSN), "no timer or listener in the gate");
	expect(!/hzFindByName|hz36HideFind/.test(L_EDGE + L_RETRY + L_MISSN), "no search outside the existing rebuild");
	expect(/"JetpackMeterWrapper_mc","JetpackMeterAnim_mc"/.test(code), "the hide list itself is unchanged (no name dropped; the cap makes a missing one harmless)");
}

console.log((failed ? failed + " FAILED" : "all passed") + " (" + passed + " ok)");
process.exit(failed ? 1 : 0);
