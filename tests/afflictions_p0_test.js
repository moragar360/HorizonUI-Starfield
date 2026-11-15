// Afflictions P0 tests for actionscript/horizon_block.as: buff polarity, exact effect matching, and alert clearing.
// Run: node tests/afflictions_p0_test.js
// The production AS bodies (hzAfSetPers, hzAfIsPos, hzAfSync, hzJoinEffects, hz27OnPersAlerts, hz27PersMerge) run
// here as JavaScript. The same scenarios also run on the 591d340 bodies (git show), which must show each old bug.
// Author: Moragar. Last modified: 2026-11-14 (scope pins follow the hazard card commit).
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const BASE = process.env.HZ_AFF_BASE || "591d340";
let base = null;
try { base = cp.execFileSync("git", ["show", BASE + ":actionscript/horizon_block.as"], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { base = null; }

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) i = src.indexOf("public function " + name + "(");
	if (i < 0) return null;
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
		.replace(/for\s*\(\s*var\s+(\w+)\s*:\s*String\s+in\s+/g, "for (var $1 in ")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
function bindAll(h, src, names) {
	const wrap = new Proxy(h, { get(t, k) { return k in t ? t[k] : undefined; }, has(t, k) { return k in t; } });
	for (const n of names) {
		const f = fnText(src, n);
		if (!f) continue;   // the base has no hzAfIsPos
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}
const common = { int: (n) => { n = Number(n); return isNaN(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)); }, Number: Number, String: String, Math: Math, Boolean: Boolean, RegExp: RegExp, Error: Error };
const FN = ["hzAfSetPers", "hzAfIsPos", "hzAfSync", "hzAfSortFn", "hzPretty", "hzSplitCamel", "hzJoinEffects", "hz27OnPersAlerts", "hz27PersMerge", "hz27PersSafe"];

// one host = the card state; clock in ms
function host(src) {
	const h = Object.assign({}, common, {
		clock: 0, laid: null, hzAfEnv: [], hzAfPers: [], hzAfSeen: {}, hzAfSoak: 0, hzFrameN: 1, hzAfflCount: 0, hz27Alerts: [], hzAfNew: {}, hzDebug: false, hz26Dbg: {},
		hz26Now: function() { return this.clock; }, hz26Log: () => {}, hz26OwInAffl: () => false, hzV19: () => true, hzRefreshVisibility: () => {},
		hzAfLayoutChips: function(a) { this.laid = a; }
	});
	bindAll(h, src, FN);
	h.effects = (icons) => { h.hzAfSetPers(icons.map((i) => ({ sEffectIcon: i }))); };
	h.alerts = (list) => { h.hz27OnPersAlerts({ data: { aPersonalAlerts: list.map((x) => ({ sEffectIcon: x[0], sAlertText: x[1], sAlertSubText: x[2] || "" })) } }); };
	h.names = () => (h.laid || []).map((o) => o.name + (o.sub ? "/" + o.sub : ""));
	return h;
}

const F_POS = "PersonalEffect_Food_Positive", F_NEG = "PersonalEffect_Food_Negative";
const W_POS = "PersonalEffect_Water_Positive", W_NEG = "PersonalEffect_Water_Negative";
const SKIN = "PersonalEffect_Skin_Negative";

// ---- (a) buffs are not afflictions ----
{
	const h = host(as);
	h.effects([F_POS, W_POS]);
	const L = h.laid;
	expect(L.length === 2 && L.every((o) => o.pos === true && o.name === "Buff" && o.kind === "buff"), "(a) Fed and Hydrated (_Positive) are buff chips named Buff, kind buff");
	expect(h.hzAfflCount === 0, "(a) buffs alone do not count as afflicted (AfflictionsRule 6 stays hidden)");
	h.effects([F_POS, SKIN]);
	expect(h.hzAfflCount === 1, "(a) one affliction next to a buff counts 1");
	expect(h.laid[0].icon === SKIN && h.laid[1].icon === F_POS, "(a) the affliction sorts before the buff (buffs go to +N MORE first)");
	const neg = h.laid.find((o) => o.icon === SKIN);
	expect(neg.name === "Affliction" && neg.kind === "injury" && neg.pos === false, "(a) a _Negative effect is still a red Affliction chip");
	expect(h.hzJoinEffects([{ sEffectIcon: F_POS }, { sEffectIcon: SKIN }], true) === "Skin", "(a) the classic card text lists afflictions only");
	expect(h.hzJoinEffects([{ sEffectIcon: F_POS }], true) === "None", "(a) classic card text with only a buff reads None");
	h.hzV19 = () => false; h.effects([W_POS]);
	expect(h.hzAfflCount === 0, "(a) classic card: a buff alone does not count");
	h.effects([W_NEG]);
	expect(h.hzAfflCount === 1, "(a) classic card: a debuff counts");
	// draw path: green for buffs, red for afflictions (source of hzAfLayoutChips)
	const lay = fnText(as, "hzAfLayoutChips").body;
	expect(lay.indexOf("(a.pos === true ? HZ_GREEN : HZ_RED)") >= 0 && (lay.match(/a\.pos === true \? HZ_GREEN : HZ_RED/g) || []).length === 2, "(a) buff chips draw icon ring and title in green, afflictions stay red");
	expect(/case "buff":/.test(fnText(as, "hzGlyph").body), "(a) buff chips have their own glyph");
}
{
	const h = host(as);
	for (const [ic, want] of [[F_POS, true], [F_NEG, false], ["PersonalEffect_Food", false], ["_Positive", false], ["X_Positive_2", false], ["PersonalEffect_Food_positive", false], ["", false]]) {
		expect(h.hzAfIsPos(ic) === want, "(a) hzAfIsPos(\"" + ic + "\") = " + want);
	}
}

// ---- (b) exact names: a buff and its debuff never merge ----
{
	const h = host(as);
	h.effects([F_POS, F_NEG, W_POS, W_NEG, F_NEG]);
	const keys = h.laid.map((o) => o.key);
	expect(h.laid.length === 4, "(b) Fed, Malnourished, Hydrated, Dehydrated: four chips (exact icon), the repeated Malnourished once");
	expect(new Set(keys).size === 4 && keys.indexOf("p:" + F_POS) >= 0 && keys.indexOf("p:" + F_NEG) >= 0, "(b) chip keys are the full icon, suffix included");
	expect(h.laid.filter((o) => o.pos).length === 2 && h.laid.filter((o) => !o.pos).length === 2, "(b) polarity is kept per chip");
	// order independence: whichever comes first, both stay
	const h2 = host(as); h2.effects([F_NEG, F_POS]);
	expect(h2.laid.length === 2 && h2.laid[0].icon === F_NEG, "(b) debuff first or buff first, both chips stay and the debuff sorts first");
	// an alert replaces only the chip of its own exact icon, never the buff of the same need
	const h3 = host(as); h3.effects([F_POS, F_NEG]); h3.alerts([[F_NEG, "Hungry"]]);
	expect(h3.names().join("|") === "Hungry/Food|Buff/Food", "(b) a Hungry alert replaces the Malnourished chip only; the Fed buff stays");
}

// ---- (c) clearing on change / removal ----
function alertNames(h) { return h.hz27Alerts.map((a) => a.txt).join("|"); }
{
	// always-active stage effect (needs mod): Hungry stage listed, then eating swaps it for the Satiated buff
	const h = host(as);
	h.effects([F_NEG]); h.alerts([[F_NEG, "Hungry"]]);
	expect(alertNames(h) === "Hungry", "(c) Hungry alert while the Hungry stage is listed");
	h.clock = 200000; h.effects([F_NEG]);
	expect(alertNames(h) === "Hungry", "(c) still listed after 200 s: the alert stays (no 90 s expiry while its effect is active)");
	h.clock = 201000; h.effects([F_POS]);
	expect(alertNames(h) === "", "(c) the stage changes to Satiated (always-active buff): Hungry clears on that update");
	expect(h.names().join("|") === "Buff/Food", "(c) only the buff chip is left");
}
{
	// stage change to a different negative stage icon
	const h = host(as);
	h.effects([F_NEG]); h.alerts([[F_NEG, "Hungry"]]);
	h.clock = 5000; h.effects(["PersonalEffect_FoodStarving_Negative"]);
	expect(alertNames(h) === "", "(c) the effect changes to another stage icon: the old alert clears");
}
{
	// effect goes away entirely (sleep removes Fed; vanilla cure)
	const h = host(as);
	h.effects([SKIN]); h.alerts([[SKIN, "Lacerations"]]);
	h.clock = 1000; h.effects([]);
	expect(alertNames(h) === "" && h.laid.length === 0, "(c) the effect is removed: its alert clears at once");
}
{
	// alert whose effect is never listed while a same-need buff is always listed: expires at 90 s (was kept forever)
	const h = host(as);
	h.effects([F_POS]); h.alerts([[F_NEG, "Hungry"]]);
	h.clock = 89000; h.effects([F_POS]);
	expect(alertNames(h) === "Hungry", "(c) never-listed alert: kept before 90 s");
	h.clock = 91000; h.effects([F_POS]);
	expect(alertNames(h) === "", "(c) never-listed alert: the always-active buff no longer keeps it; it expires after 90 s");
}
{
	// listed later than the alert, then gone
	const h = host(as);
	h.effects([]); h.alerts([[F_NEG, "Hungry"]]);
	h.clock = 2000; h.effects([F_NEG]);
	h.clock = 3000; h.effects([F_NEG, W_NEG]);
	expect(alertNames(h) === "Hungry", "(c) an unrelated change keeps the alert while its effect is listed");
	h.clock = 4000; h.effects([W_NEG]);
	expect(alertNames(h) === "", "(c) listed after the alert arrived, then gone: clears");
}
{
	// a positive alert of the same need still drops its debuff alerts (treated / cured) and is never kept itself
	const h = host(as);
	h.effects([F_NEG]); h.alerts([[F_NEG, "Hungry"], [W_NEG, "Thirsty"]]);
	h.alerts([[F_POS, "Satiated"]]);
	expect(alertNames(h) === "Thirsty", "(c) a _Positive alert drops that need's debuff alerts only, and is not kept");
	// a repeated alert refreshes its time
	h.clock = 80000; h.alerts([[W_NEG, "Thirsty"]]);
	h.clock = 150000; h.effects([F_NEG]);
	expect(alertNames(h) === "Thirsty", "(c) a repeated alert refreshes its 90 s window");
}
{
	// two afflictions sharing one exact icon with different text both stay (no information loss)
	const h = host(as);
	h.effects([SKIN]); h.alerts([[SKIN, "Lacerations"], [SKIN, "Burns"]]);
	expect(alertNames(h) === "Lacerations|Burns", "(c) two alerts on one icon with different text both stay while listed");
}

{
	// incoming alerts match on the exact icon too: the same text under another icon is its own alert
	const h = host(as);
	h.alerts([["PersonalEffect_Food", "Hungry"], [F_NEG, "Hungry"]]);
	expect(h.hz27Alerts.length === 2 && h.hz27Alerts[1].icon === F_NEG, "(b) the same alert text under two different icons stays two alerts (exact icon)");
	h.effects([F_NEG]); h.clock = 1000; h.effects([]);
	expect(alertNames(h) === "Hungry" && h.hz27Alerts[0].icon === "PersonalEffect_Food", "(c) only the alert whose exact effect went away clears");
}
{
	// overweight in the card still counts as afflicted next to a buff
	const h = host(as); h.hz26OwInAffl = () => true;
	h.effects([F_POS]);
	expect(h.hzAfflCount === 1, "(a) Overweight on the card counts as afflicted; the buff does not");
}

// ---- N-1: the buff filter is for the personal list only; the environment text is the old behavior exactly ----
{
	const h = host(as);
	expect(h.hzJoinEffects([{ sEffectIcon: "HazardEffect_Thermal_Positive" }]) === "Thermal", "N-1: env text: HazardEffect_Thermal_Positive alone still reads Thermal (not None)");
	expect(h.hzJoinEffects([{ sEffectIcon: "HazardEffect_Thermal_Positive" }, { sEffectIcon: "HazardEffect_Radiation" }]) === "Thermal, Radiation", "N-1: env text: a _Positive env icon is still listed next to another hazard");
	const pb = fnText(as, "hzOnPersonalEffects").body, eb = fnText(as, "hzOnEnvEffects").body;
	expect(/this\.hzJoinEffects\(e\.data\.aPersonalEffects as Array,true\)/.test(pb), "N-1: the personal effects call asks for the buff filter");
	expect(/this\.hzJoinEffects\(a\)/.test(eb) && !/hzJoinEffects\([^)]*,/.test(eb), "N-1: the environment call passes one argument (filter off)");
	if (base) {
		const o = host(base);
		const pool = ["HazardEffect_Thermal_Positive", "HazardEffect_Thermal_Negative", "HazardEffect_Radiation", "HazardEffect_Airborne", "HazardEffect_Corrosive_Negative", "HazardEffect_RestoreSoak", "HazardEffect_Cold_Positive", "PersonalEffect_Food_Positive", "Hazard_Toxic_Positive", "", "X_Positive"];
		let s0 = 7, bad = "", n = 0;
		const r = () => { s0 = (s0 * 1664525 + 1013904223) >>> 0; return s0 / 4294967296; };
		for (let t = 0; t < 3000 && !bad; t++) {
			const len = Math.floor(r() * 6); const a = [];
			for (let k = 0; k < len; k++) a.push({ sEffectIcon: pool[Math.floor(r() * pool.length)] });
			const x = h.hzJoinEffects(a), y = o.hzJoinEffects(a); n++;
			if (x !== y) bad = JSON.stringify(a) + " new=" + x + " old=" + y;
		}
		expect(!bad, "N-1: env text equals the 591d340 helper on " + n + " random env lists with _Positive icons" + (bad ? " -- " + bad : ""));
		let nb = 0, ob = 0;
		try { h.hzJoinEffects([null]); } catch (e) { nb = 1; }
		try { o.hzJoinEffects([null]); } catch (e) { ob = 1; }
		expect(nb === ob, "N-1: env text handles a null entry the same way as 591d340");
		expect(h.hzJoinEffects(null) === o.hzJoinEffects(null) && h.hzJoinEffects([]) === o.hzJoinEffects([]), "N-1: empty and missing env lists read the same as 591d340");
	}
}

// ---- N-5: tied chips keep one order between updates ----
{
	const h = host(as);
	const mk = () => [{ key: "p:B", sev: 0, seen: 5 }, { key: "p:A", sev: 0, seen: 5 }, { key: "p:C", sev: 0, seen: 5 }, { key: "a:X:Hungry", sev: 3, seen: 5 }, { key: "e:Thermal", sev: 1, seen: 5 }];
	const perms = [[0, 1, 2, 3, 4], [4, 3, 2, 1, 0], [2, 0, 4, 1, 3], [1, 4, 0, 3, 2], [3, 2, 1, 4, 0]];
	const orders = new Set(perms.map((p) => { const b = mk(); return p.map((i) => b[i]).sort(h.hzAfSortFn).map((o) => o.key).join(","); }));
	expect(orders.size === 1 && [...orders][0] === "a:X:Hungry,e:Thermal,p:A,p:B,p:C", "N-5: tied chips sort by key, the same for every input order (" + [...orders].join(" / ") + ")");
	expect(h.hzAfSortFn({ key: "k", sev: 1, seen: 1 }, { key: "k", sev: 1, seen: 1 }) === 0, "N-5: the same key compares equal");
}

// ---- the same scenarios on the old bodies show each bug (the tests can tell old from new) ----
if (base) {
	const o1 = host(base); o1.effects([F_POS]);
	expect(o1.laid.length === 1 && o1.laid[0].name === "Affliction" && o1.laid[0].kind === "injury", "base " + BASE + " shows bug (a): Fed is a red Affliction");
	const o2 = host(base); o2.effects([F_POS, F_NEG]);
	expect(o2.laid.length === 1, "base " + BASE + " shows bug (b): Fed and Malnourished merge into one chip");
	const o3 = host(base); o3.effects([F_NEG]); o3.alerts([[F_NEG, "Hungry"]]); o3.clock = 600000; o3.effects([F_POS]);
	expect(alertNames(o3) === "Hungry", "base " + BASE + " shows bug (c): Hungry never clears while the Satiated buff is listed (10 min)");
} else {
	expect(false, "base " + BASE + " source is readable through git show");
}

// ---- scope: edge-only, Hazard Status interface untouched ----
// The hazard card has its own commit on the combined branch (0.43.3.1 soak green: hzHsFx / hzHsSync and the hzHsFx call
// line in hzOnEnvEffects), so the reference for these lines is that commit when HEAD contains it (found by the field it
// added, so a rebase or cherry-pick still finds it), else BASE. Each afflictions commit is also checked against its own
// parent: the affliction work never changes these lines. The old-bug checks above still run on BASE.
const SCOPE_FNS = ["hzOnEnvEffects", "hzAfSetEnv", "hzHsSync", "hzHsCat", "hz27Tick"];
const hs = (src) => src.split("\n").filter((l) => /hzHs|green hold/i.test(l)).join("\n");
const gitOut = (args) => { try { return cp.execFileSync("git", args, { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }); } catch (e) { return null; } };
const asAt = (rev) => { const t = gitOut(["show", rev + ":actionscript/horizon_block.as"]); return t == null ? null : t.replace(/\r\n/g, "\n"); };
const scopeSame = (x, y) => SCOPE_FNS.every((n) => { const a = fnText(x, n), b = fnText(y, n); return (!a && !b) || (a && b && a.body === b.body); }) && hs(x) === hs(y);
if (base) {
	const hzRev = (gitOut(["log", "-1", "--format=%H", "-S", "hzHsSkGrn", "HEAD", "--", "actionscript/horizon_block.as"]) || "").trim();
	const refName = hzRev ? "the hazard card commit " + hzRev.slice(0, 7) : BASE;
	const ref = hzRev ? asAt(hzRev) : base;
	expect(ref != null, "scope: the reference " + refName + " is readable through git show");
	if (ref != null) {
		for (const n of SCOPE_FNS) {
			const a = fnText(as, n), b = fnText(ref, n);
			if (!a && !b) continue;
			expect(a && b && a.body === b.body, "scope: " + n + " is unchanged from " + refName);
		}
		expect(hs(as) === hs(ref), "scope: every Hazard Status line (hzHs*, green hold) is unchanged from " + refName);
	}
	const affl = (gitOut(["log", "--format=%H", "-i", "--grep=afflictions", BASE + "..HEAD", "--", "actionscript/horizon_block.as"]) || "").split("\n").filter(Boolean);
	expect(affl.length > 0, "scope: the afflictions commits since " + BASE + " are found (" + affl.length + ")");
	for (const c of affl) {
		const x = asAt(c), y = asAt(c + "^");
		expect(x != null && y != null && scopeSame(x, y), "scope: afflictions commit " + c.slice(0, 7) + " leaves hzOnEnvEffects, hzAfSetEnv, hzHsSync, hz27Tick and every hzHs* line as its parent had them");
	}
	const added = as.length - base.length;
	const addedText = (() => { const A = as.split("\n"), B = new Set(base.split("\n")); return A.filter((l) => !B.has(l)).join("\n"); })();
	expect(!/addEventListener|enterFrame|ENTER_FRAME|new Timer|setInterval|setTimeout|getChildByName|getChildAt/.test(addedText), "scope: no new listeners, timers, frame handlers or tree lookups in the added lines (" + added + " chars)");
	expect(!/hzFrameN\s*%/.test(addedText), "scope: no new frame-count polling in the added lines");
}

if (failed) { console.error(failed + " FAILED"); process.exit(1); }
console.log("afflictions_p0_test passed");
