// env alert Phase 0 probe (private diag) tests. Run: node tests/env_p0_test.js
// Proves, against the production AS in horizon_block.as:
//  1. off by default: [Debug] EnvAlertLog is the only switch, it is not in the default INI, the [Debug] writer or any
//     preset, and with it off hzOnEnvEffects does one Boolean test before its own (unchanged) body;
//  2. the key is read (section-aware, last line wins) only on INI load / F11 reload, outside hzOnIni, and the
//     EnvironmentAlertsData listener is added from there, once, and only when the key is on;
//  3. both log paths return at their first test unless EnvAlertLog, PerfDiag and WatchLog are all on;
//  4. event-driven only: no frame listener, timer or display-list walk in the probe;
//  5. taking out the probe section and its two hook lines gives the a360b89 source byte for byte (skipped when git
//     or the commit is not there).
// Author: Moragar. Last modified: 2026-11-11.
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const ini = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8");
let base = null;
try { base = cp.execFileSync("git", ["show", "a360b89:actionscript/horizon_block.as"], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { base = null; }

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnBody(name) {
	const i = as.indexOf("private function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = as.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < as.length; p++) {
		if (as[p] === "{") depth++;
		else if (as[p] === "}") { depth--; if (depth === 0) return as.slice(brace + 1, p); }
	}
	throw new Error("unbalanced " + name);
}
function count(s, sub) { return s.split(sub).length - 1; }

const B0 = "      // ===================== env alert Phase 0 probe (private diag, default off) =====================\n";
const B1 = "      // ===================== end env alert Phase 0 probe =====================\n\n";
const HOOK = "         if(this.hzEnvP0Ini) { try { this.hzEnvP0Fx(e.data); } catch(eP0:Error) { } }   // private diag (env alert Phase 0); off = this one test\n";
const CASE = "         if(txt != null) { try { this.hzEnvP0ParseIni(txt); } catch(errP0:Error) { } }   // private diag (env alert Phase 0): [Debug] EnvAlertLog\n";
const i0 = as.indexOf(B0), i1 = as.indexOf(B1);
expect(i0 > 0 && i1 > i0 && count(as, B0) === 1 && count(as, B1) === 1, "one probe section");
const sec = as.slice(i0, i1 + B1.length);

// 1. off by default
expect(/private var hzEnvP0Ini:Boolean = false;/.test(sec), "hzEnvP0Ini defaults to false");
expect(count(as, "this.hzEnvP0Ini = ") === 2 && count(fnBody("hzEnvP0ParseIni"), "this.hzEnvP0Ini = ") === 2, "hzEnvP0Ini is set only by hzEnvP0ParseIni");
expect(count(as, CASE) === 1 && fnBody("hz37OnApplyTxt").indexOf(CASE) >= 0 && count(as, "this.hzEnvP0ParseIni(") === 1, "hzEnvP0ParseIni runs only from the INI apply callback");
expect(fnBody("hzOnIni").toLowerCase().indexOf("envalertlog") < 0 && fnBody("hzOnIni").indexOf("hzEnvP0") < 0, "hzOnIni is untouched");
expect(count(as.toLowerCase(), "envalertlog") === count(CASE.toLowerCase(), "envalertlog") + count(sec.toLowerCase(), "envalertlog"), "no other envalertlog use (writer, presets, F11)");
expect(!/envalertlog/i.test(ini), "default INI has no EnvAlertLog line");
const envBody = fnBody("hzOnEnvEffects");
expect(envBody.startsWith("\n" + HOOK), "hzOnEnvEffects starts with the one-test hook");
expect(count(as, "hzEnvP0Fx(") === 2, "hzEnvP0Fx is called only from the hook");

// 2. listener
expect(count(as, "\"EnvironmentAlertsData\"") === 1, "EnvironmentAlertsData is subscribed in one place");
const sub = fnBody("hzEnvP0Sub");
expect(/^\s*if\(!this\.hzEnvP0Ini \|\| this\.hzEnvP0Subbed\) \{ return; \}/.test(sub) && sub.indexOf("\"EnvironmentAlertsData\"") > 0, "hzEnvP0Sub adds the listener once, only with the key on");
expect(count(as, "this.hzEnvP0Sub()") === 1 && fnBody("hzEnvP0ParseIni").indexOf("this.hzEnvP0Sub()") > 0, "hzEnvP0Sub is called only from hzEnvP0ParseIni");
// run the production parser (types stripped) on sample INI texts
{
	const hdr = (ln) => { const t = ln.replace(/^[\s\uFEFF]+|\s+$/g, ""); if (t.length < 3 || t.charAt(0) !== "[") return null; const e = t.indexOf("]"); if (e < 2) return null; return t.substring(1, e).trim().toLowerCase(); };
	let js = fnBody("hzEnvP0ParseIni").replace(/for each\(var (\w+):\w+ in /g, "for (let $1 of ").replace(/var (\w+):\w+/g, "let $1");
	const run = (txt) => { const h = { hzEnvP0Ini: null, subs: 0, hz30Hdr: hdr, hzEnvP0Sub() { this.subs++; } }; new Function("txt", js).call(h, txt); return h; };
	const a = run("[Debug]\nDebug=0\n"), b = run("[Debug]\nEnvAlertLog=1\n"), c = run("[Debug]\nEnvAlertLog=1\n[Debug]\n EnvAlertLog = 0 ; off\n");
	const d = run("[Effects]\nEnvAlertLog=1\n"), f = run("[debug]\r\nenvalertlog = true\r\n");
	expect(a.hzEnvP0Ini === false && a.subs === 0, "parser: no key = off, no listener call");
	expect(b.hzEnvP0Ini === true && b.subs === 1 && f.hzEnvP0Ini === true, "parser: EnvAlertLog=1 / true under [Debug] = on");
	expect(c.hzEnvP0Ini === false, "parser: the last line wins (user.ini after default.ini)");
	expect(d.hzEnvP0Ini === false, "parser: the key counts only under [Debug]");
}

// 3. gates
expect(/^\s*return this\.hzEnvP0Ini && this\.hzWlOn && this\.hzWlQ != null;\s*$/.test(fnBody("hzEnvP0Ready")), "ready needs EnvAlertLog, the watchlog switch and its queue");
expect(/^\s*if\(!this\.hzEnvP0Ready\(\) \|\| d == null\) \{ return; \}/.test(fnBody("hzEnvP0Fx")), "effects logger returns at its first test");
expect(/^\s*if\(!this\.hzEnvP0Ready\(\) \|\| e == null \|\| e\.data == null\) \{ return; \}/.test(fnBody("hzEnvP0OnAlerts")), "alerts logger returns at its first test");
expect(!/hzWlQ\[|hzWlQN\s*[+=]/.test(sec), "lines go only through hzWlPush (bounded queue)");

// 4. event-driven only
for (const bad of ["enterFrame", "ENTER_FRAME", "setInterval", "setTimeout", "Timer", "addEventListener", "getChildAt", "numChildren", "getChildByName"]) {
	expect(sec.indexOf(bad) < 0 && HOOK.indexOf(bad) < 0, "probe has no " + bad);
}

// 5. off path equals the base
if (base == null) console.log("skip base equality (git or a360b89 not available)");
else expect(as.replace(sec, "").replace(HOOK, "").replace(CASE, "") === base, "probe removed = a360b89 source (three hunks only)");

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("all passed");
