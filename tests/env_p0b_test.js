// env alert Phase 0 probe, r2 behavior tests. Run: node tests/env_p0b_test.js
// Runs the production AS of the probe (types stripped, nothing else changed) against scripted dispatches and proves:
//  S-2. change-only logging: one fx line per list / flag / alert-time change, per soak step of 0.02 or more and per
//       landing on exactly 0 or 1; every other dispatch only counts (skip=), and why=list / why=soak are right;
//  S-1. the skip path builds nothing: it returns before the first array, push, join, String() or line text, and a
//       skipped dispatch never calls the line builders;
//  N-4. turning the key off and on starts a new run: counters and caches reset, a new start line, and the first
//       dispatch after it is logged even when nothing changed;
//  N-3. a user preset text never carries [Debug] EnvAlertLog, and every other line and line break stays as it was.
// Author: Moragar. Last modified: 2026-11-11.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fn(name) {
	const i = as.indexOf("private function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = as.indexOf("{", i);
	const sig = as.slice(i, brace);
	let depth = 0;
	for (let p = brace; p < as.length; p++) {
		if (as[p] === "{") depth++;
		else if (as[p] === "}") { depth--; if (depth === 0) return { sig, body: as.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
// AS3 -> JS for the probe's own subset: typed var / params, for each, "as Array", typed catch
function toJs(name) {
	const f = fn(name);
	const params = f.sig.slice(f.sig.indexOf("(") + 1, f.sig.lastIndexOf(")")).split(",").map((p) => p.trim().split(":")[0]).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/([\w.]+) as Array/g, "(Array.isArray($1) ? $1 : null)")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)");
	return new Function(...params, body);
}
const FNS = ["hzEnvP0ParseIni", "hzEnvP0Sub", "hzEnvP0Ready", "hzEnvP0Out", "hzEnvP0Q", "hzEnvP0Head", "hzEnvP0Fx", "hzEnvP0OnAlerts", "hzEnvP0NoKey"];
const hdr = (ln) => { const t = ln.replace(/^[\s\uFEFF]+|\s+$/g, ""); if (t.length < 3 || t.charAt(0) !== "[") return null; const e = t.indexOf("]"); if (e < 2) return null; return t.substring(1, e).trim().toLowerCase(); };
function makeHost() {
	const h = {
		hzWlOn: true, hzWlQ: [], hzFrameN: 100, hzPpKind: "planet", hzPpBodyName: "Testbody", clock: 1000, subs: [], calls: {},
		hzWlPush(s) { this.hzWlQ.push(s); },
		hzPerfNow() { return this.clock; },
		hzKeys(o) { return Object.keys(o).sort().join(", "); },
		hz30Hdr: hdr,
	};
	// field defaults straight from the AS declarations
	const re = /private var (hzEnvP0\w+):[\w*]+ = ([^;]+);/g;
	let m;
	while ((m = re.exec(as))) h[m[1]] = m[2] === "NaN" ? NaN : JSON.parse(m[2]);
	for (const n of FNS) {
		const f = toJs(n);
		h[n] = function (...a) { h.calls[n] = (h.calls[n] || 0) + 1; return f.apply(h, a); };
	}
	h.BSUIDataManager = null;
	return h;
}
// hzEnvP0Sub uses the global BSUIDataManager
let SUBS = 0;
global.BSUIDataManager = { Subscribe(n, cb) { SUBS++; } };

const fx = (h) => h.hzWlQ.filter((l) => /^ENVP0 fx /.test(l));
const field = (l, k) => { const m = new RegExp(" " + k + "=(\\S+)").exec(l); return m ? m[1] : null; };
const D = (soak, icons, extra) => Object.assign({ fSoakDamagePct: soak, bShouldPlayAlertAtFullSoak: false, uAlertTimeMS: 3000, uEnvIconPulseMinMS: 400, uEnvIconPulseMaxMS: 1200, aEnvironmentEffects: icons.map((s) => ({ sEffectIcon: s, uiHandle: 7 })) }, extra || {});

// ---- S-2: change-only logging ----
{
	const h = makeHost();
	h.hzEnvP0ParseIni("[Debug]\nEnvAlertLog=1\n");
	const A = ["HazardEffect_Radiation"];
	const AR = ["HazardEffect_Radiation", "HazardEffect_RestoreSoak"];
	const BR = ["HazardEffect_Thermal", "HazardEffect_RestoreSoak"];
	const steps = [
		[D(0.5, A), "list"],     // 1 first dispatch
		[D(0.5, A), null],       // 2 same
		[D(0.51, A), null],      // 3 +0.01
		[D(0.519, A), null],     // 4 +0.019 from the logged 0.5
		[D(0.53, A), "soak"],    // 5 +0.03
		[D(1, A), "soak"],       // 6 lands on 1
		[D(1, A), null],         // 7 same
		[D(0.99, A), null],      // 8 -0.01
		[D(0.99, AR), "list"],   // 9 RestoreSoak added
		[D(0.99, BR), "list"],   // 10 same count, other icon
		[D(0.985, BR), null],    // 11 small
		[D(0.01, BR), "soak"],   // 12 big step
		[D(0, BR), "soak"],      // 13 lands on 0 (step 0.01)
		[D(0, BR), null],        // 14 same
		[D(0, BR, { uAlertTimeMS: 5000 }), "list"],               // 15 alert time
		[D(0, BR, { uAlertTimeMS: 5000, bShouldPlayAlertAtFullSoak: true }), "list"],   // 16 flag
		[D(0, BR, { uAlertTimeMS: 5000, bShouldPlayAlertAtFullSoak: true, uEnvIconPulseMaxMS: 900 }), "list"],   // 17 pulse
		[D(0, [], { uAlertTimeMS: 5000, bShouldPlayAlertAtFullSoak: true, uEnvIconPulseMaxMS: 900 }), "list"],   // 18 empty list
		[D(0, [], { uAlertTimeMS: 5000, bShouldPlayAlertAtFullSoak: true, uEnvIconPulseMaxMS: 900 }), null],     // 19 same
	];
	const got = [];
	let prev = 0, multi = 0;
	for (const [d, why] of steps) {
		h.clock += 16; h.hzFrameN++;
		h.hzEnvP0Fx(d);
		const now = fx(h).length;
		got.push(now > prev ? field(fx(h)[now - 1], "why") : null);
		if (now - prev > 1) multi++;
		prev = now;
	}
	expect(multi === 0, "at most one fx line per dispatch");
	const want = steps.map((s) => s[1]);
	expect(JSON.stringify(got) === JSON.stringify(want), "change-only: lines exactly at list / flag / time changes, steps >= 0.02 and landings on 0 / 1, why=list / why=soak right (" + got.map((g) => g || "-").join(" ") + ")");
	const L = fx(h);
	expect(L.map((l) => field(l, "skip")).join(",") === "0,3,0,2,0,1,0,1,0,0,0", "skip= counts the dispatches since the previous line (" + L.map((l) => field(l, "skip")).join(",") + ")");
	expect(field(L[0], "restore") === "0" && field(L[3], "restore") === "1" && field(L[4], "restore") === "1", "restore=1 exactly while HazardEffect_RestoreSoak is listed");
	expect(field(L[2], "soak") === "1.0000" && field(L[6], "soak") === "0.0000" && field(L[0], "raw") === "\"0.5\"", "soak= and raw= carry the value");
	expect(L.length === 11 && field(L[10], "n") === "0" && /icons=\[\]/.test(L[10]), "empty list logged as n=0 icons=[]");
	expect(field(L[0], "dt") === "-" && field(L[1], "dt") === String(16 * 4), "dt= is the time since the previous line");
	expect(h.hzWlQ.filter((l) => /^ENVP0 keys fx /.test(l)).length === 1 && h.hzWlQ.filter((l) => /^ENVP0 start /.test(l)).length === 1, "keys and start lines once per run");
	const h2 = makeHost(); h2.hzEnvP0ParseIni("[Debug]\nEnvAlertLog=1\n");
	h2.hzEnvP0Fx({ fSoakDamagePct: 0.3, uAlertTimeMS: 1 }); h2.hzEnvP0Fx({ fSoakDamagePct: 0.3, uAlertTimeMS: 1 });
	expect(fx(h2).length === 1 && field(fx(h2)[0], "n") === "noarray" && field(fx(h2)[0], "skip") === "0", "no effect array: logged once as n=noarray, then skipped");
	h2.hzEnvP0Fx({ fSoakDamagePct: NaN, uAlertTimeMS: 1 });
	expect(fx(h2).length === 2 && field(fx(h2)[1], "soak") === "NaN", "soak turning NaN is logged once");
}

// ---- S-1: the skip path builds nothing ----
{
	const body = fn("hzEnvP0Fx").body;
	const skipAt = body.indexOf("{ this.hzEnvP0Skip++; return; }");
	const head = body.slice(0, skipAt);
	expect(skipAt > 0 && !/\[\]|\.push\(|\.join\(|String\(|hzEnvP0Head|hzEnvP0Q|hzKeys|toFixed|new |"/.test(head), "skip return comes before any array, push, join, String(), string literal or line builder");
	const h = makeHost(); h.hzEnvP0ParseIni("[Debug]\nEnvAlertLog=1\n");
	const d = D(0.4, ["HazardEffect_Radiation", "HazardEffect_Toxic"]);
	h.hzEnvP0Fx(d);
	const before = Object.assign({}, h.calls), icons = h.hzEnvP0Icons;
	for (let k = 0; k < 50; k++) h.hzEnvP0Fx(D(0.4 + (k % 3) * 0.005, ["HazardEffect_Radiation", "HazardEffect_Toxic"]));
	expect(h.calls.hzEnvP0Head === before.hzEnvP0Head && h.calls.hzEnvP0Q === before.hzEnvP0Q && h.calls.hzEnvP0Out === before.hzEnvP0Out, "50 unchanged dispatches call no line builder and write nothing");
	expect(h.hzEnvP0Icons === icons && h.hzEnvP0Skip === 50, "the cache is not rebuilt on a skip; skip counts them");
}

// ---- N-4: a new run after off -> on ----
{
	const h = makeHost();
	const subs0 = SUBS;
	h.hzEnvP0ParseIni("[Debug]\nEnvAlertLog=1\n");
	h.hzEnvP0Fx(D(0.5, ["HazardEffect_Radiation"]));
	h.hzEnvP0Fx(D(0.5, ["HazardEffect_Radiation"]));
	h.hzEnvP0ParseIni("[Debug]\nEnvAlertLog=1\n");   // F11 Apply with the key still on: no reset
	h.hzEnvP0Fx(D(0.5, ["HazardEffect_Radiation"]));
	expect(fx(h).length === 1 && h.hzEnvP0Skip === 2 && h.hzEnvP0Runs === 1, "reload with the key still on keeps the run");
	h.hzEnvP0ParseIni("[Debug]\nEnvAlertLog=0\n");
	h.hzEnvP0Fx(D(0.9, ["HazardEffect_Thermal"]));
	expect(fx(h).length === 1, "key off: nothing logged");
	h.hzEnvP0ParseIni("[Debug]\nEnvAlertLog=1\n");
	expect(h.hzEnvP0Seq === 0 && h.hzEnvP0Skip === 0 && h.hzEnvP0Have === false && h.hzEnvP0KeysFx === 0 && h.hzEnvP0KeysAl === 0 && isNaN(h.hzEnvP0Soak) && h.hzEnvP0Icons === null && h.hzEnvP0Runs === 2, "off -> on resets counters and caches");
	h.hzEnvP0Fx(D(0.5, ["HazardEffect_Radiation"]));   // same as the last logged values of run 1
	const starts = h.hzWlQ.filter((l) => /^ENVP0 start /.test(l));
	expect(fx(h).length === 2 && starts.length === 2 && field(starts[1], "run") === "2" && / #1 /.test(fx(h)[1]) && h.hzWlQ.filter((l) => /^ENVP0 keys fx /.test(l)).length === 2, "the first dispatch of the new run is logged with a new start line, #1 and a keys line");
	expect(SUBS - subs0 === 1, "the alerts listener is still added only once per session");
}

// ---- N-3: user presets never carry the key ----
{
	const h = makeHost();
	const txt = "[Effects]\r\nEnvAlertLog=1\r\nHazardStatus=1\r\n[Debug]\r\n; diag\r\nDebug=0\r\nEnvAlertLog=1\r\n envalertlog = 0 ; x\r\nWatchLog=1\r\n[Style]\r\nTempUnit=1";
	const out = h.hzEnvP0NoKey(txt);
	expect(out === "[Effects]\r\nEnvAlertLog=1\r\nHazardStatus=1\r\n[Debug]\r\n; diag\r\nDebug=0\r\nWatchLog=1\r\n[Style]\r\nTempUnit=1", "only [Debug] EnvAlertLog lines are dropped; other sections, comments, keys and CRLF stay");
	const plain = "[Debug]\r\nDebug=1\r\nWatchLog=1\r\n";
	expect(h.hzEnvP0NoKey(plain) === plain && h.hzEnvP0NoKey(null) === null && h.hzEnvP0NoKey("") === "", "text without the key is returned unchanged");
	const ft = fn("hz37FullText").body;
	expect(/return this\.hzEnvP0NoKey\(this\.hz30Merge\(this\.hz30IniRaw,this\.hzBuildIniText\(p\)\)\);/.test(ft), "the user-preset text goes through hzEnvP0NoKey");
	const uses = as.split("\n").filter((l) => /this\.hzEnvP0NoKey\(/.test(l));
	expect(uses.length === 1 && as.split("hz37FullText()").length - 1 === 2 && /full = this\.hz37FullText\(\)/.test(fn("hz37SaveSubmit").body), "hzEnvP0NoKey is used only by the preset save text (hz37FullText has one caller, the preset save)");
	const nk = fn("hzEnvP0NoKey").body;
	expect(!/enterFrame|ENTER_FRAME|setInterval|setTimeout|Timer|addEventListener|getChildAt|numChildren/.test(nk), "preset filter is event-only");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("all passed");
