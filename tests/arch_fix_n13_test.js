// arch-fixes follow-up tests: N-1 (torn-down watch refs are parked, so the styles 3/4 full passes go back to steady)
// and N-3 (a stealth-sourced "in combat" can't stick when the stealth feed goes quiet).
// Run: node tests/arch_fix_n13_test.js   (HZ_AS=<file> runs it against another horizon_block.as, used by the mutants)
// Runs the production AS functions (types stripped) on a small host. Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const asPath = process.env.HZ_AS || path.join(__dirname, "..", "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(");
	const m = re.exec(src);
	if (!m) throw new Error("missing function " + name);
	const brace = src.indexOf("{", m.index);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(m.index, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function codeOnly(body) { return body.replace(/\/\/[^\n]*/g, ""); }
function toJs(body) {
	return body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*(?:Error|\*)\s*\)\s*\{/g, "catch($1) {")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
const constOf = (n) => Number((as.match(new RegExp(n + ":int = (\\d+)")) || [])[1]);
const G = { HZ43_HID_MAX: 40, HZ_COMBAT_QUIET: constOf("HZ_COMBAT_QUIET"), HZ_HCT_INTERACT: 7, HZ_HCT_COMMAND: 8,
	Number: Number, Boolean: Boolean, Array: Array, int: (v) => Math.trunc(Number(v)) | 0 };
function bind(h, names) {
	const wrap = new Proxy(h, { get(t, k) { if (k in t) return t[k]; if (k in G) return G[k]; return undefined; }, has(t, k) { return typeof k === "string" && (k in t || k in G); } });
	for (const n of names) {
		const f = fnText(as, n);
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}
function clip(name, extra) { return Object.assign({ name: name, visible: false, stage: {}, parent: null }, extra || {}); }
function box(name, kids) {
	const c = clip(name, { visible: true });
	c.kids = kids || [];
	for (const k of c.kids) k.parent = c;
	Object.defineProperty(c, "numChildren", { get() { return this.kids.length; } });
	return c;
}
function chrHost(hidA, blg) {
	const a = new Array(40).fill(null);
	hidA.forEach((d, i) => { a[i] = d; });
	const h = { hzBlg: blg, hzWatchStyle: 3, hz43ChrForce: 0, hz43ChrKidsA: blg.numChildren, hz43ChrStA: 3, hz43ChrKidsB: blg.numChildren, hz43ChrStB: 3,
		hz43HidA: a, hz43HidN: hidA.length, hz43HidP: null, hz43HidPN: 0, hz43ChrW: [], hz43ChrWN: 0, hz43ChrShow: [], hz43ChrShowN: 0,
		hz43ChrBox: [], hz43ChrBoxK: [], hz43ChrBoxN: 0, hz43EnvGot: 0 };
	h.hz43VanWatchClip = (d) => d != null;
	h.hz43VanGameVis = () => false;
	h.hz43VanEnvWant = () => true;
	return bind(h, ["hz43ChrPrune", "hz43ChrStale", "hz43ChrNeedA", "hz43ChrNeedB", "hz43VanRestoreHid"]);
}

// ---- N-1: park torn-down refs at a full pass ----
{
	const a = clip("WatchOutline_mc"), b = clip("O2CO2_mc"), c = clip("DayCycleBase_mc");
	const blg = box("BottomLeftGroup_mc", [a, b, c]);
	const h = chrHost([a, b, null, c], blg);
	b.stage = null; b.parent = null; c.stage = null;
	expect(h.hz43ChrNeedA() === true && h.hz43ChrNeedB() === true, "a torn-down noted ref is an edge (the full pass runs once)");
	h.hz43ChrPrune();
	expect(h.hz43HidN === 1 && h.hz43HidA[0] === a, "the full pass keeps live refs in order and drops the torn-down and null ones from the scan list");
	expect(h.hz43HidA.slice(1).every((x) => x === null), "the freed tail of the scan list is cleared (no stale refs kept)");
	expect(h.hz43HidPN === 2 && h.hz43HidP[0] === b && h.hz43HidP[1] === c, "torn-down refs are parked for the restore");
	let steady = 0;
	for (let f = 0; f < 50; f++) if (!h.hz43ChrNeedA() && !h.hz43ChrNeedB()) steady++;
	expect(steady === 50, "after one full pass the next 50 frames run no full pass (was: every frame until a style change)");
	h.hz43HidA[1] = b; h.hz43HidN = 2;   // noted again while still torn down
	h.hz43ChrPrune();
	expect(h.hz43HidN === 1 && h.hz43HidPN === 2, "a ref already parked is not parked twice and still leaves the scan list");
	h.hz43ChrForce = 0;
	h.hz43VanRestoreHid();
	expect(a.visible && b.visible && c.visible, "the restore (style change / Horizon off) undoes the hide on live and parked refs alike");
	expect(h.hz43HidPN === 0 && h.hz43HidN === 0 && h.hz43HidP.every((x) => x === null), "the restore empties both lists");
	expect((h.hz43ChrForce & 7) === 7, "the restore still forces both passes once");
}
{
	const a = clip("WatchOutline_mc", { stage: null });
	const blg = box("BottomLeftGroup_mc", [a]);
	blg.stage = null;
	const h = chrHost([a], blg);
	h.hz43ChrPrune();
	expect(h.hz43HidN === 1 && h.hz43HidPN === 0, "while the BLG itself is off stage nothing is parked (every ref reads stage null)");
}
{
	const a = clip("WatchOutline_mc", { stage: null });
	const blg = box("BottomLeftGroup_mc", [a]);
	const h = chrHost([a], blg);
	h.hz43HidP = new Array(40).fill(0).map((_, i) => clip("p" + i)); h.hz43HidPN = 40;
	h.hz43ChrPrune();
	expect(h.hz43HidN === 1 && h.hz43HidA[0] === a && h.hz43HidPN === 40, "a full parked list keeps the ref in the scan list (old cost, never a lost restore)");
}
{
	const h = chrHost([], box("BottomLeftGroup_mc", []));
	let threw = false;
	try { h.hz43ChrPrune(); h.hz43VanRestoreHid(); } catch (e) { threw = true; }
	expect(!threw && h.hz43HidP === null, "empty lists: no throw, and no parked array is allocated");
}
{
	const fr = fnText(as, "hzOnFrame").body;
	const ia = fr.indexOf("this.hz43ChrNeedA())");
	const pa = fr.indexOf("this.hz43ChrPrune();", ia);
	expect(ia >= 0 && pa > ia && pa < fr.indexOf("var bi:int", ia), "pass A parks at the start of its full pass, inside the NeedA edge");
	const hv = fnText(as, "hz43VanHorizon").body;
	const ib = hv.indexOf("this.hz43ChrNeedB())");
	const pb = hv.indexOf("this.hz43ChrPrune();", ib);
	expect(ib >= 0 && pb > ib && pb < hv.indexOf("this.hz43ChrRec = true;", ib), "pass B parks at the start of its full pass, inside the NeedB edge");
	expect((as.match(/this\.hz43ChrPrune\(\)/g) || []).length === 2, "hz43ChrPrune is called from the two full passes only");
	const pr = codeOnly(fnText(as, "hz43ChrPrune").body);
	expect(!/addEventListener|Timer|setInterval|ENTER_FRAME|hzFindByName|getChild/.test(pr) && (pr.match(/new /g) || []).length === 1 && /if\(this\.hz43HidP == null\)/.test(pr), "hz43ChrPrune: no search, timer or listener; one guarded allocation");
}

// ---- N-3: combat can't stick on a quiet stealth feed ----
function cHost() {
	const h = { hzInCombat: false, hzCombatPd: false, hzCombatSt: false, hzCombatSn: false, hzCombatQuiet: 0, hzT19Sig: "x", refresh: 0, hz26St: null, hz26Log: () => {} };
	h.hzRefreshVisibility = () => { h.refresh++; };
	return bind(h, ["hzOnPlayerData", "hzOnStealthCombat", "hz26OnStealth", "hz36SetCombat"]);
}
const ev = (d) => ({ data: d });
expect(G.HZ_COMBAT_QUIET === 2, "HZ_COMBAT_QUIET is 2 PlayerData updates");
{
	const h = cHost();
	h.hz26OnStealth(ev({ bSneaking: true, bIsInCombat: true }));
	expect(h.hzInCombat && h.refresh === 1, "stealth combat edge: combat on");
	h.hzOnPlayerData(ev({ bIsInCombat: false }));
	expect(h.hzInCombat && h.refresh === 1, "one PlayerData 'not in combat' after the stealth edge does not clear it");
	h.hzOnPlayerData(ev({ bIsInCombat: false }));
	expect(!h.hzInCombat && h.refresh === 2 && h.hzCombatSt === false, "a second one with no stealth update between clears it (stealth went quiet)");
	h.hzOnPlayerData(ev({ bIsInCombat: false }));
	expect(!h.hzInCombat && h.refresh === 2, "later PlayerData repeats change nothing");
	h.hz26OnStealth(ev({ bSneaking: true, bIsInCombat: true }));
	expect(h.hzInCombat && h.refresh === 3, "a live stealth feed saying combat again turns it back on (the stealth source was reset)");
}
{
	const h = cHost();
	h.hz26OnStealth(ev({ bSneaking: true, bIsInCombat: true }));
	for (let i = 0; i < 10; i++) { h.hzOnPlayerData(ev({ bIsInCombat: false })); h.hz26OnStealth(ev({ bSneaking: true, fPercent: i })); }
	expect(h.hzInCombat && h.refresh === 1, "while the stealth feed keeps updating, PlayerData repeats do not clear its combat");
}
{
	const h = cHost();
	h.hz26OnStealth(ev({ bSneaking: true, bIsInCombat: true }));
	h.hz26OnStealth(ev({ bSneaking: false, bIsInCombat: true }));
	expect(!h.hzInCombat && h.refresh === 2 && h.hzCombatSt === false, "sneak-exit edge: the stealth source drops out and combat falls back to PlayerData (off)");
	h.hz26OnStealth(ev({ bSneaking: false, bIsInCombat: true }));
	expect(h.hzInCombat && h.refresh === 3, "a stealth feed that keeps updating after sneak exit still counts");
}
{
	const h = cHost();
	h.hzOnPlayerData(ev({ bIsInCombat: true }));
	h.hz26OnStealth(ev({ bSneaking: true, bIsInCombat: true }));
	const r = h.refresh;
	h.hz26OnStealth(ev({ bSneaking: false, bIsInCombat: false }));
	expect(h.hzInCombat && h.refresh === r, "sneak-exit edge with PlayerData in combat: combat stays on, no refresh");
}
{
	const h = cHost();
	h.hz26OnStealth(ev({ bIsInCombat: true }));
	h.hz26OnStealth(ev({ bIsInCombat: true, fPercent: 3 }));
	expect(h.hzInCombat && h.hzCombatSn === false, "no bSneaking field: no sneak edge, the flag works as before");
	h.hz26OnStealth(ev({ bSneaking: false }));
	expect(h.hzInCombat, "first bSneaking false without a prior true is not an exit edge");
}
{
	let clean = true;
	for (const n of ["hzOnPlayerData", "hzOnStealthCombat"]) {
		if (/addEventListener|Timer|setInterval|ENTER_FRAME|hzFindByName|getTimer|Date|hz26Now|new /.test(codeOnly(fnText(as, n).body))) clean = false;
	}
	expect(clean, "N-3 handlers: no timer, clock, listener, search or allocation");
	const sc = as.slice(as.indexOf("private function hz36SetCombat") - 400, as.indexOf("private function hz36SetCombat"));
	expect(sc.indexOf("the source the game's own detection meter uses") < 0 && sc.indexOf("HUDStealthData") >= 0, "hz36SetCombat's comment credits both providers (N-7)");
}

console.log("\n" + passed + " ok, " + failed + " failed");
process.exit(failed ? 1 : 0);
