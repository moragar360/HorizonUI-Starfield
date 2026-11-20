// Hazard Status card green hold tests (0.43.3.2). Run: node tests/hazard_hold_test.js
// Runs the production hzHsFx, hzHsOnAlerts, hzHsSync and hzHsHoldTick (types stripped) on a small host:
//  a hazard that leaves the effects list (or a restore that ends) shows GREEN for HZ_HS_HOLD_MS, then hides;
//  the hold ends only on the existing 30-frame hzPpClock slot; a hazard listed again during the hold is red at once;
//  a negative alert ends the hold; red -> green keeps the card shown (no new show, no sound code anywhere in the card).
// Mutants (source edits) must each fail the behavior checks, so the checks really pin the fix.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const AS0 = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

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
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/([\w.]+) as (?:Array|MovieClip)/g, "$1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/\bHZ_HS_(\w+)/g, "this.HZ_HS_$1");
	return new Function(...params, body);
}
function consts(src) {
	const c = {};
	const re = /private static const (HZ_HS_\w+):\w+ = ([^;]+);/g; let m;
	while ((m = re.exec(src))) c[m[1]] = /^"/.test(m[2]) ? JSON.parse(m[2]) : Number(m[2]);
	return c;
}
function fields(src) {
	const f = {};
	const re = /private var (hzHsSk\w+|hzHsHoldT):(\w+) = ([^;]+);/g; let m;
	while ((m = re.exec(src))) f[m[1]] = m[3] === "NaN" ? NaN : m[3] === "false" ? false : m[3] === "true" ? true : Number(m[3]);
	return f;
}
function makeHost(src) {
	const h = Object.assign({
		hzHsOn: true, hzHsCardOn: true, hzArrange: false, hz43EnvLang: "en", HorizonHazard_mc: {}, hzEnvP0Ini: false,
		hzHsSeq: 0, hzHsCat: 0, hzHsCatSeq: 0, hzHsWord: "HAZARD", hzHsAlSeq: 0, hzHsAlPos: false, hzHsAlTxt: "", hzHsGrn: false,
		hzHsSt: -1, hzHsSrc: -1, hzHsSrcTxt: null, hzHsW: -1, hzHsCm: -1, hzHsShown: false, draws: 0, shows: [], syncs: 0, now: 5000, nowReads: 0,
		hz26Now() { this.nowReads++; return this.now; },
		hzHsWant() { return this.hzHsOn && this.hzHsCardOn && this.HorizonHazard_mc != null; },
		hzHsMaxW() { return 300; }, hzHsCmp() { return 0; }, hzHsBlgSub() { },
		hzHsDraw() { this.draws++; this.hzHsCm = this.hzHsCmp(); }, hzShow(c, on) { this.shows.push(on); }, hzHsVan() { },
	}, consts(src), fields(src));
	h.hzHsFx = toJs(src, "hzHsFx").bind(h);
	h.hzHsOnAlerts = toJs(src, "hzHsOnAlerts").bind(h);
	const sync = toJs(src, "hzHsSync").bind(h);
	h.hzHsSync = function () { h.syncs++; sync(); };
	h.hzHsHoldTick = toJs(src, "hzHsHoldTick").bind(h);
	// the existing 30-frame slot: the production hzPpClock line that reaches the hold tick (the rest of hzPpClock is not run)
	const clk = fnText(src, "hzPpClock").body.split("\n").filter((l) => /hzHsHold/.test(l)).join("\n").replace(/catch\((\w+):\w+\)/g, "catch($1)");
	h.slot = new Function(clk).bind(h);
	return h;
}
const RED = 1, GRN = 2;
const hz = (h, word) => h.hzHsFx([{ sEffectIcon: "HazardEffect_Thermal" }], 1, word || "THERMAL", 0.5);
const restore = (h) => h.hzHsFx([{ sEffectIcon: "HazardEffect_RestoreSoak" }], 0, "HAZARD", 0.5);
const none = (h) => h.hzHsFx([], 0, "HAZARD", NaN);
const alert = (h, pos, txt) => h.hzHsOnAlerts({ data: { aEnvironmentAlerts: [{ bIsPositive: pos, sAlertText: txt }] } });
const wait = (h, ms) => { h.now += ms; h.slot(); };

// the behavior checks; returns the list of failed check names (empty = all good) so mutants can reuse them
function behave(src, log) {
	const bad = [];
	const chk = (c, m) => { if (log) expect(c, m); if (!c) bad.push(m); };
	let h;
	try { h = makeHost(src); } catch (e) { return ["host: " + e.message]; }
	const HOLD = h.HZ_HS_HOLD_MS;
	try {
		hz(h);
		chk(h.hzHsSt === RED && h.hzHsShown, "a listed hazard: red, shown");
		const shows0 = h.shows.length;
		none(h);
		chk(h.hzHsSt === GRN && h.hzHsShown, "the hazard left the list: GREEN (not removed at once)");
		chk(h.hzHsSrc === 3, "green hold text: SUIT PROTECTION RESTORING (no alert text yet)");
		chk(h.shows.length === shows0, "red -> green keeps the card shown: no new show (no re-show fade)");
		wait(h, HOLD - 600);
		chk(h.hzHsSt === GRN, "before the hold ends: still green");
		const s0 = h.syncs;
		wait(h, 600);
		chk(h.hzHsSt === 0 && !h.hzHsShown, "the hold ended on the existing slot: hidden");
		chk(h.syncs === s0 + 1, "the end is one hzHsSync");
		const s1 = h.syncs, r1 = h.nowReads;
		wait(h, 10000); wait(h, 500);
		chk(h.syncs === s1 && h.nowReads === r1, "no hold: the slot does nothing (no clock read, no sync)");
		// a hazard listed again during the hold: red at once, the hold is gone
		const k = makeHost(src);
		hz(k); none(k); wait(k, 1000);
		chk(k.hzHsSt === GRN, "(setup) in the hold");
		hz(k, "CORROSIVE");
		chk(k.hzHsSt === RED && k.hzHsShown && k.hzHsWord === "CORROSIVE", "a hazard listed again during the hold: red at once");
		const ks = k.syncs;
		wait(k, HOLD); wait(k, HOLD);
		chk(k.hzHsSt === RED && k.syncs === ks, "the old hold end does not hide or touch the red card");
		none(k);
		chk(k.hzHsSt === GRN, "that hazard leaves too: a new green hold");
		wait(k, HOLD);
		chk(k.hzHsSt === 0, "then hidden");
		// restore listed (cat 1) is green; when it ends the hold keeps green a little longer
		const r = makeHost(src);
		hz(r); restore(r);
		chk(r.hzHsSt === GRN, "suit protection restoring listed: green");
		none(r);
		chk(r.hzHsSt === GRN, "the restore ended: green hold");
		wait(r, HOLD);
		chk(r.hzHsSt === 0, "the restore hold ended: hidden");
		// a negative alert ends the hold
		const q = makeHost(src);
		hz(q); none(q);
		alert(q, false, "Suit Protection Depleted");
		chk(q.hzHsSt === 0 && q.hzHsHoldT < 0, "a negative alert during the hold ends it");
		// a positive alert during the hold: its own text, still green
		const p = makeHost(src);
		hz(p); none(p); alert(p, true, "Suit Protection Reg.");
		chk(p.hzHsSt === GRN && p.hzHsSrc === 1, "a positive alert during the hold: green with the alert text");
		// card off during the hold: hidden; the hold still ends on time
		const o = makeHost(src);
		hz(o); none(o); o.hzHsCardOn = false; o.hzHsSync();
		chk(o.hzHsSt === 0, "card base off: hidden");
		o.hzHsCardOn = true; o.hzHsSync();
		chk(o.hzHsSt === GRN, "card base back inside the hold: green");
		wait(o, HOLD);
		chk(o.hzHsSt === 0 && o.hzHsHoldT < 0, "and the hold still ends");
		// nothing was ever listed: the hold never arms
		const z = makeHost(src);
		none(z);
		chk(z.hzHsSt === 0 && z.hzHsHoldT < 0, "empty list with nothing before it: hidden, no hold");
	} catch (e) { bad.push("threw: " + e.message); if (log) expect(false, "threw: " + e.message); }
	return bad;
}

// ---- production ----
expect(behave(AS0, true).length === 0, "all hold behavior checks pass on the production source");

// ---- source rules ----
const C = consts(AS0);
expect(C.HZ_HS_HOLD_MS >= 2000 && C.HZ_HS_HOLD_MS <= 6000, "HZ_HS_HOLD_MS is a short hold (2-6 s): " + C.HZ_HS_HOLD_MS);
expect(fields(AS0).hzHsHoldT === -1, "starts with no hold");
const tick = fnText(AS0, "hzHsHoldTick").body.replace(/\/\/.*$/gm, "");
expect(/^\s*if\(this\.hzHsHoldT < 0\) \{ return; \}/.test(tick), "hzHsHoldTick: first line returns when there is no hold");
const NOPE = /Timer|setTimeout|setInterval|ENTER_FRAME|enterFrame|getTimer|getChildByName|hzFindByName|\bnew\b|\[\]|\{\s*\}|Array\(|PlaySound|PlayAlertSound|PlayMenuSound|\.play\(/;
expect(!NOPE.test(tick.replace(/\{ return; \}/g, "")), "hzHsHoldTick: no timer, frame listener, tree search, allocation or sound");
const clkLines = fnText(AS0, "hzPpClock").body.split("\n").filter((l) => /hzHsHold/.test(l));
expect(clkLines.length === 1 && /if\(this\.hzHsHoldT >= 0\) \{ try \{ this\.hzHsHoldTick\(\); \}/.test(clkLines[0]), "hzPpClock (the existing 30-frame slot) calls the tick only while a hold runs");
expect(/if\(this\.hzFrameN % 30 == 11\) \{ try \{ this\.hzPpClock\(\); \}/.test(AS0), "hzPpClock is still the existing every-30-frames slot");
{
	// the hold end must sit above hzPpClock's planet-clock early return (else it stops while the planet pill is hidden)
	const pl = fnText(AS0, "hzPpClock").body.split("\n");
	const iHold = pl.findIndex((l) => /hzHsHoldTick\(\)/.test(l));
	const iRet = pl.findIndex((l) => /\breturn\b/.test(l));
	expect(iHold >= 0 && iRet > iHold, "hzPpClock: the hold end runs before the planet-clock early return (line " + iHold + " < " + iRet + ")");
	const moved = (() => { const b = pl.slice(); const [x] = b.splice(iHold, 1); b.splice(iRet, 0, x); return b; })();
	const iH2 = moved.findIndex((l) => /hzHsHoldTick\(\)/.test(l)), iR2 = moved.findIndex((l) => /\breturn\b/.test(l));
	expect(!(iH2 >= 0 && iR2 > iH2), "mutant: the hold end moved below the early return is caught by that pin");
}
const callers = AS0.split("\n").filter((l) => /hzHsHoldTick\(\)/.test(l) && !/function hzHsHoldTick/.test(l));
expect(callers.length === 1, "hzHsHoldTick has exactly one caller");
const fxb = fnText(AS0, "hzHsFx").body;
expect((fxb.match(/hz26Now\(\)/g) || []).length === 1 && /if\(cat == 0\) \{ this\.hzHsHoldT = this\.hz26Now\(\) \+ HZ_HS_HOLD_MS; \}/.test(fxb), "hzHsFx reads the clock once, only on the category edge to 0");
expect(!/PlaySound|PlayAlertSound|PlayMenuSound|\.play\(/.test(fxb + fnText(AS0, "hzHsSync").body + fnText(AS0, "hzHsOnAlerts").body), "no sound code in the card paths (the vanilla alert sound stays the only one)");

// ---- mutants ----
function mutate(name, from, to) {
	if (AS0.indexOf(from) < 0) { expect(false, "mutant " + name + ": anchor not found"); return; }
	const src = AS0.replace(from, to);
	const bad = behave(src, false);
	expect(bad.length > 0 && !/^host: /.test(bad[0]), "mutant " + name + " is caught (" + (bad[0] || "-") + ")");
}
mutate("no arm on leave", "if(cat == 0) { this.hzHsHoldT = this.hz26Now() + HZ_HS_HOLD_MS; }", "");
mutate("sync ignores the hold", "else if(this.hzHsGrn || this.hzHsHoldT >= 0) { st = 2; }", "else if(this.hzHsGrn) { st = 2; }");
mutate("a new hazard keeps the hold", "else if(cat == 2) { this.hzHsHoldT = -1; }", "");
mutate("slot never ends the hold", "if(this.hzHsHoldT >= 0) { try { this.hzHsHoldTick(); }", "if(false) { try { this.hzHsHoldTick(); }");
mutate("tick does not clear", "         this.hzHsHoldT = -1;\n         this.hzHsSync();\n      }", "         this.hzHsSync();\n      }");
mutate("tick ends at once", "if(this.hz26Now() < this.hzHsHoldT) { return; }", "");
mutate("negative alert keeps the hold", "if(!this.hzHsAlPos) { this.hzHsHoldT = -1; }", "");
mutate("hold never expires", "if(cat == 0) { this.hzHsHoldT = this.hz26Now() + HZ_HS_HOLD_MS; }", "if(cat == 0) { this.hzHsHoldT = this.hz26Now() + 1e12; }");

console.log("hazard hold: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
