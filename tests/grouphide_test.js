// v0.44 fix package tests (whole-group BottomLeftGroup hide, per-frame allocation and redundant-work cuts).
// Run: node tests/grouphide_test.js
// Proves, against the production AS in horizon_block.as (and, for equivalence, the 2511842 bodies via git show):
//  1. group hide: only in the replaced config; hides BLG by visible only; F11 flips apply on the next frame both ways;
//     a release gives back vanilla's own visible (hzGroupVisible), never a forced true; children are never touched,
//     so pieces vanilla hid stay hidden; a release never happens outside the frame tick; zero lookups when not wanted;
//  2. rebuild: with the group hidden the list drops exactly the BLG names, and the walk skips BLG with the same result
//     for every other name (when no other listed name lives under BLG, which the vanilla sources show);
//  3. H1 / H2 / H5 / glow / det / bio / enemy: same writes, same decisions as before, fewer allocations or calls.
// Author: Moragar. Last modified: 2026-11-10.
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
let base = null;   // 2511842 (watchlog commit) source: the before-bodies
try { base = cp.execFileSync("git", ["show", "2511842:actionscript/horizon_block.as"], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { base = null; }

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
		.replace(/([\w.\[\]]+) is DisplayObjectContainer/g, "isCont($1)")
		.replace(/([\w.\[\]]+) is TextField/g, "isText($1)")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
function bindAll(h, src, names, thisFix) {
	const wrap = new Proxy(h, { get(t, k) { return k in t ? t[k] : undefined; }, has(t, k) { return k in t; } });
	for (const n of names) {
		const f = fnText(src, n);
		let js = toJs(f.body);
		if (thisFix) js = thisFix(js);
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + js + "\n}"])).bind(wrap);
	}
	return h;
}
function rng(seed) { let s = seed >>> 0; return function() { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }

// ---- display model ----
let uid = 0;
function Clip(name, kids) {
	const c = { key: ++uid, name: name, visible: true, alpha: 1, parent: null, kids: kids ? [] : null, gets: 0 };
	Object.defineProperty(c, "stage", { get: function() { let q = this; while (q.parent) q = q.parent; return q.__root ? q : null; } });
	if (kids) {
		Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; } });
		c.getChildAt = function(i) { return this.kids[i]; };
		c.getChildByName = function(n) { this.gets++; for (const k of this.kids) if (k && k.name === n) return k; return null; };
	}
	return c;
}
function add(p, c) { c.parent = p; p.kids.push(c); return c; }
function remove(c) { const p = c.parent; p.kids.splice(p.kids.indexOf(c), 1); c.parent = null; }
const common = { isCont: (d) => !!(d && d.kids), isText: (d) => !!(d && d.isText), int: (n) => { n = Number(n); return isNaN(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)); },
	DisplayObject: (d) => d, DisplayObjectContainer: (d) => d, Number: Number, String: String, Math: Math, Boolean: Boolean };

// ---- 1. group hide ----
const BLG_KIDS = ["DayCycleBase_mc", "OffPlanet_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "WatchOutline_mc", "WatchPointerOutline_mc",
	"WatchIconsWidget_mc", "MissionIconsWidget_mc", "EnemyIconsWidget_mc", "EnvAlertText", "BioAlertText", "LocationAlertText", "EnemyDetectionAnim_mc", "instance12"];
function gHost() {
	const hud = Clip("root", true); hud.__root = true;
	const blg = add(hud, Clip("BottomLeftGroup_mc", true));
	for (const n of BLG_KIDS) add(blg, Clip(n));
	const h = Object.assign({}, common, {
		hud: hud, blg: blg, hz44GrpIni: true, hz44Hid: false, hz44Ref: null, hz44Skip: null, hz44N: 0, hzWlOn: false,
		hzWatchStyle: 0, hzHideVanillaWatch: true, hzUserHidden: false, hzShowAfflictions: true, hzShowPlanet: true, hzHazardAlert: true,
		hzStealthOn: true, hzEnemyBarOn: true, hzEdgePulse: true, hzGroupVisible: true, hzHideCache: [], now: 0
	});
	h.getChildByName = function(n) { return hud.getChildByName(n); };
	h.hzPerfNow = function() { return h.now; };
	return bindAll(h, as, ["hz44GrpWant", "hz44GrpTick"]);
}
// what hz43SyncHide does with a WatchStyle change (vanilla styles 1 / 2 turn the vanilla watch hide off)
function setStyle(h, st) { h.hzWatchStyle = st; h.hzHideVanillaWatch = !(st === 1 || st === 2); }
// the game's HudModeData handler: BLG.visible = bVisible; hzGroupVisible = BLG.visible; hzRefreshVisibility() (-> hz44GrpTick(false))
function hudMode(h, vis) { h.blg.visible = vis; h.hzGroupVisible = h.blg.visible; h.hz44GrpTick(false); }
function kidsState(h) { return h.blg.kids.map((k) => k.name + ":" + k.visible + ":" + k.alpha).join("|"); }
{
	const h = gHost();
	h.blg.getChildByName("OffPlanet_mc").visible = false;   // vanilla's own write (W3: on a planet)
	const before = kidsState(h);
	h.hz44GrpTick(true);
	expect(h.blg.visible === false && h.hz44Hid && h.hzHideCache === null && h.hz44N === 1, "eligible config: one frame tick hides the whole group (visible only) and asks for a rebuild");
	expect(h.blg.alpha === 1 && kidsState(h) === before, "group hide: alpha and every child left as vanilla set them");
	hudMode(h, true);
	expect(h.blg.visible === false, "game HudModeData re-shows the group: re-hidden in the same handler (hzRefreshVisibility hook)");
	// F11: WatchStyle -> VANILLA (1) mid-session
	setStyle(h, 1);
	h.hz44GrpTick(false);
	expect(h.blg.visible === false && h.hz44Hid, "F11 -> VANILLA: no release outside the frame tick (the per-piece list is applied in the same frame as the release)");
	h.hzHideCache = [];
	h.hz44GrpTick(true);
	expect(h.blg.visible === true && !h.hz44Hid && h.hzHideCache === null, "F11 -> VANILLA: next frame the group is back with vanilla's visible, and the per-piece list is rebuilt");
	expect(h.blg.getChildByName("OffPlanet_mc").visible === false && kidsState(h) === before, "after the restore, a piece vanilla itself hid stays hidden; nothing else changed");
	// F11 back to OFF (0)
	setStyle(h, 0);
	h.hz44GrpTick(true);
	expect(h.blg.visible === false && h.hz44Hid, "F11 -> OFF again: next frame the group is hidden again (live, both ways)");
	// the game hides the HUD (menu): vanilla says false while we hold the hide; release must keep false
	hudMode(h, false);
	setStyle(h, 2);
	h.hz44GrpTick(true);
	expect(h.blg.visible === false && !h.hz44Hid, "release while the game has the group hidden (menu / photo mode): stays hidden, not forced true");
	hudMode(h, true);
	expect(h.blg.visible === true, "the game's next HudModeData shows it as vanilla would (no hide applies in VANILLA)");
	// HideVanillaWatch off on its own (style unchanged at 0 is impossible through F11, but a direct flip must also release)
	setStyle(h, 0); h.hz44GrpTick(true);
	h.hzHideVanillaWatch = false; h.hz44GrpTick(true);
	expect(h.blg.visible === true && !h.hz44Hid, "HideVanillaWatch off: the whole group comes back");
}
{
	// every gate, one at a time: not wanted -> no hide, no lookups
	const gates = [["hz44GrpIni", false, "BlgGroupHide=0 (rollback)"], ["hzWatchStyle", 3, "WatchStyle 3 (vanilla mission/enemy markers kept)"], ["hzWatchStyle", 4, "WatchStyle 4"],
		["hzWatchStyle", 1, "WatchStyle 1"], ["hzUserHidden", true, "player hid Horizon"], ["hzShowAfflictions", false, "AFFLICTIONS card off (vanilla bio alert)"],
		["hzShowPlanet", false, "PLANET card off (vanilla env / landing alerts)"], ["hzHazardAlert", false, "HAZARD ALERT off (vanilla env alert)"]];
	for (const [k, v, label] of gates) {
		const h = gHost();
		h[k] = v;
		const g0 = h.hud.gets;
		h.hz44GrpTick(true); h.hz44GrpTick(false);
		expect(h.blg.visible === true && !h.hz44Hid && h.hud.gets === g0, "not eligible: " + label + " -> per-piece path, group untouched, zero lookups");
	}
	const h = gHost();
	h.hzStealthOn = h.hzEnemyBarOn = h.hzEdgePulse = false;
	h.hz44GrpTick(true);
	expect(h.blg.visible === true && !h.hz44Hid, "not eligible: STEALTH, ENEMY BAR and EDGE PULSE all off (vanilla enemy ring)");
	h.hzEdgePulse = true; h.hz44GrpTick(true);
	expect(h.blg.visible === false && h.hz44Hid, "one enemy cue on is enough (same rule as hz31DetHide)");
}
{
	// cost and identity: one lookup to find the group, then none; a new group instance is found and the old one restored
	const h = gHost();
	h.hz44GrpTick(true);
	const g1 = h.hud.gets;
	for (let f = 0; f < 200; f++) { h.hz44GrpTick(true); h.hz44GrpTick(false); }
	expect(g1 === 1 && h.hud.gets === 1, "steady state: 400 checks, no lookup after the first (cached ref, parent check only)");
	const old = h.blg;
	remove(old);
	const nb = add(h.hud, Clip("BottomLeftGroup_mc", true));
	h.blg = nb;
	h.hz44GrpTick(true);
	expect(nb.visible === false && h.hz44Ref === nb && old.visible === true && h.hud.gets === 2, "group replaced (HUD rebuild): one re-find, the new group hidden, the detached one given vanilla's value back");
}
{
	// random F11 sequence vs a reference rule: visible at render == (wanted ? false : vanilla)
	const r = rng(44);
	const h = gHost();
	let bad = "";
	for (let f = 0; f < 4000 && !bad; f++) {
		const q = r();
		if (q < 0.05) setStyle(h, Math.floor(r() * 5));
		else if (q < 0.08) h.hzShowAfflictions = r() < 0.5;
		else if (q < 0.10) h.hzUserHidden = r() < 0.3;
		else if (q < 0.14) hudMode(h, r() < 0.7);
		h.hz44GrpTick(true);
		h.hz44GrpTick(false);   // exit frame
		const want = h.hz44GrpWant();
		const exp = want ? false : h.hzGroupVisible;
		if (h.blg.visible !== exp) bad = "frame " + f;
	}
	expect(!bad, "4000 random frames (F11 style, cards, hide-all, game HUD modes): at render the group is hidden exactly when wanted, else vanilla's value" + (bad ? " -- " + bad : ""));
}
{
	// wiring
	const of = fnText(as, "hzOnFrame").body;
	const iSync = of.indexOf("this.hz43SyncHide();"), iG = of.indexOf("this.hz44GrpTick(true);"), iRb = of.indexOf("if(this.hzHideCache == null ||");
	expect(iSync >= 0 && iSync < iG && iG < iRb, "frame order: style sync, then the group check, then the hide-list rebuild (a release is followed by the per-piece list in the same frame)");
	expect(of.indexOf("if(this.hzHideVanillaWatch && !this.hz44Hid)") >= 0, "the per-frame BLG child loop does not run while the group is hidden");
	expect(fnText(as, "hzRefreshVisibility").body.indexOf("this.hz44GrpTick(false);") >= 0 && fnText(as, "hz27OnExit").body.indexOf("this.hz44GrpTick(false);") >= 0,
		"re-hide right after the game's HudModeData write and at exit frame (after the timeline and the HUD's own motion)");
	expect(/case "blggrouphide": this\.hz44GrpIni = bv; break;/.test(as) && /private var hz44GrpIni:Boolean = true;/.test(as), "INI: BlgGroupHide, on unless set to 0 (rollback)");
	const dflt = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8");
	expect(!/blggrouphide/i.test(dflt), "production default INI unchanged (no new key)");
	expect(fnText(as, "hz44GrpTick").body.indexOf(".alpha") < 0, "the group hide never writes alpha");
}

// ---- 2. rebuild list and walk ----
{
	const of = fnText(as, "hzOnFrame").body;
	const BLG_NAMES = ["MissionIconsWidget_mc", "EnemyIconsWidget_mc", "WatchOutline_mc", "DayCycleBase_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc",
		"O2CO2_mc", "O2CO2thin_mc", "BioCondition_mc", "BioConditionBase_mc", "EnvCondition_mc", "EnvConditionBase_mc", "BioAlertBG_mc", "WatchIconsWidget_mc", "WatchPointerOutline_mc"];
	// run the list-building part of the rebuild for each config, with grp on and off
	const i0 = of.indexOf("names = [];"), i1 = of.indexOf("this.hz44Skip = grp");
	const listJs = toJs(of.slice(i0, i1)).replace("var grp = this.hz44Hid;", "var grp = G;");
	const mk = Function("G", "with(this){ var names; " + listJs + " return names; }");
	let ok = true;
	for (const st of [0, 1, 2, 3, 4]) for (const flags of [0, 1, 2, 3, 4, 5, 6, 7]) {
		const h = { hzWatchStyle: st, hzHideVanillaWatch: !(st === 1 || st === 2), hzHideVanillaCompass: true, hzHideVanillaBoost: !!(flags & 1), hzHideVanillaAmmo: !!(flags & 2), hzHideVanillaHealth: !!(flags & 4), hzHideCache: [], hz36HideStale: false };
		const a = mk.call(h, false), b = mk.call(h, true);
		const expB = a.filter((n) => BLG_NAMES.indexOf(n) < 0);
		if (JSON.stringify(b) !== JSON.stringify(expB)) ok = false;
	}
	expect(ok, "grp list = today's list minus exactly the BLG children's names, same order (40 configs)");
	// the BLG names are BottomLeftGroup's own vars (vanilla class), the remaining names are not
	expect(BLG_NAMES.every((n) => as.indexOf('"' + n + '"') >= 0), "BLG name set matches the names the rebuild pushes");
}
{
	// walk: skipping BLG gives the same first match for every non-BLG name when none of them lives under BLG
	const h = Object.assign({}, common, { hzPerfOn: false, hz44Skip: null, HorizonCard_mc: null, HorizonVitals_mc: null, HorizonEnv_mc: null, HorizonCompass_mc: null, HorizonAffl_mc: null,
		HorizonAmmo_mc: null, HorizonQuest_mc: null, HorizonCompact_mc: null, HorizonCompactQuest_mc: null, HorizonSettings_mc: null });
	bindAll(h, as, ["hz36Walk"]);
	const r = rng(7);
	const other = ["HealthBar_mc", "EquippedWeaponAmmo_mc", "JetpackMeterWrapper_mc", "Health_mc", "VerticalDivider_mc"];
	let same = true, diffWhenInside = 0, nodesSaved = 0;
	for (let t = 0; t < 300; t++) {
		const hud = Clip("root", true);
		const blg = add(hud, Clip("BottomLeftGroup_mc", true));
		const grow = (p, d, names) => { const n = 1 + Math.floor(r() * 4); for (let i = 0; i < n; i++) { const c = add(p, Clip(r() < 0.3 ? names[Math.floor(r() * names.length)] : "x" + i, d < 4 && r() < 0.5)); if (c.kids) grow(c, d + 1, names); } };
		grow(blg, 1, ["WatchOutline_mc", "Grav_mc", "instance3"]);
		for (let i = 0; i < 3; i++) { const c = add(hud, Clip("g" + i, true)); grow(c, 1, other); }
		const inside = t % 10 === 0;   // control: put a listed name under BLG
		if (inside) add(blg, Clip(other[0]));
		let n0 = 0, n1 = 0;
		const cnt = (s) => { const w = h.hz36Walk; let k = 0; h.hzPerfOn = true; h.hzPcFind = 0; const wd = new Array(other.length); w(hud, 0, other.slice(), wd, other.length); k = h.hzPcFind; h.hzPerfOn = false; return { wd: wd, k: k }; };
		h.hz44Skip = null; const a = cnt(); h.hz44Skip = blg; const b = cnt(); h.hz44Skip = null;
		const eq = a.wd.every((d, i) => d === b.wd[i]);
		if (inside) { if (!eq) diffWhenInside++; } else { if (!eq) same = false; nodesSaved += a.k - b.k; }
	}
	expect(same, "walk with BLG skipped: same node for every non-BLG name in 270 random HUD trees (no listed name under BLG)");
	expect(diffWhenInside > 0, "control: a listed name placed under BLG is detected as a difference (the assumption is real, and is backed by the vanilla class lists)");
	expect(nodesSaved > 0, "walk with BLG skipped visits fewer containers (" + nodesSaved + " fewer over the 270 trees)");
}

// ---- 3. H1: hzTgHidden alpha index ----
if (base) {
	const FN = ["hzT19HideA", "hzTgHide", "hzTgRestore", "hzT19ShowReticle"];
	function mkH(src) { const h = Object.assign({}, common, { hzTgHidden: [], hzTgHidA: [] }); return bindAll(h, src, FN); }
	const r = rng(11);
	let bad = "";
	for (let t = 0; t < 200 && !bad; t++) {
		const objs = []; for (let i = 0; i < 12; i++) objs.push([Clip("o" + i), Clip("o" + i)]);
		const rwA = Clip("rw", true), rwB = Clip("rw", true);
		for (let i = 0; i < 4; i++) { add(rwA, objs[i][0]); add(rwB, objs[i][1]); }
		const A = mkH(base), B = mkH(as);
		for (let s = 0; s < 80; s++) {
			const q = r(), i = Math.floor(r() * 12);
			if (q < 0.45) { A.hzT19HideA(objs[i][0]); B.hzT19HideA(objs[i][1]); }
			else if (q < 0.65) { A.hzTgHide(objs[i][0]); B.hzTgHide(objs[i][1]); }
			else if (q < 0.75) { A.hzT19ShowReticle(rwA); B.hzT19ShowReticle(rwB); }
			else if (q < 0.8) { A.hzTgRestore(); B.hzTgRestore(); }
			else { const v = r() < 0.5, a = Math.round(r() * 4) / 4; objs[i][0].visible = objs[i][1].visible = v; objs[i][0].alpha = objs[i][1].alpha = a; }
			const sa = objs.map((o) => o[0].visible + ":" + o[0].alpha).join("|") + "#" + A.hzTgHidden.map((o) => o.d.name + o.v + o.a).join(",");
			const sb = objs.map((o) => o[1].visible + ":" + o[1].alpha).join("|") + "#" + B.hzTgHidden.map((o) => o.d.name + o.v + o.a).join(",");
			const idx = B.hzTgHidA.length === B.hzTgHidden.length && B.hzTgHidden.every((o, k) => (o.a !== undefined ? o.d : null) === B.hzTgHidA[k]);
			if (sa !== sb || !idx) { bad = "seed " + t + " step " + s + (idx ? "" : " (index out of step)"); break; }
		}
	}
	expect(!bad, "H1: 200 x 80 random hide / hide-visible / reticle-restore / restore steps: same states and hidden list as 2511842, index always in step" + (bad ? " -- " + bad : ""));
	// a desynced index falls back to the original scan (still correct)
	const B = mkH(as); const o = Clip("z"); B.hzT19HideA(o); B.hzTgHidA.length = 0; o.alpha = 1; B.hzT19HideA(o);
	expect(o.alpha === 0 && B.hzTgHidden.length === 1, "H1: an index out of step falls back to the old linear scan (same result)");
} else console.log("skip H1 equivalence (git show 2511842 not available)");

// ---- 4. H2: hold-path ancestors once per call ----
if (base) {
	const FN = ["hzT19HidePromptTree", "hzT19OnHoldPath", "hzT19IsHoldBtn", "hzT19HideA", "hzT19HideBtnArt", "hzT19HoldMeterName"];
	const FN2 = FN.concat(["hzT19OnHoldPathA", "hzT19AncFill"]);
	const r = rng(5);
	let bad = "", calls0 = 0, calls1 = 0;
	for (let t = 0; t < 300 && !bad; t++) {
		const build = (rr) => { const top = Clip("top", true); top.__root = false; const all = [];
			const grow = (p, d) => { const n = 1 + Math.floor(rr() * 4); for (let i = 0; i < n; i++) { const c = add(p, Clip(rr() < 0.15 ? "HoldMeter_mc" : "c" + d + i, d < 4 && rr() < 0.55)); all.push(c); if (c.kids) grow(c, d + 1); } };
			grow(top, 0); return { top: top, all: all }; };
		const seed = Math.floor(r() * 1e9);
		const X = build(rng(seed)), Y = build(rng(seed));
		const pick = rng(seed + 1); const bi = []; for (let k = 0; k < 4; k++) bi.push(Math.floor(pick() * X.all.length));
		const bx = bi.map((k) => X.all[k]), by = bi.map((k) => Y.all[k]);
		if (pick() < 0.2) { bx[3] = null; by[3] = null; }
		const A = Object.assign({}, common, { hzTgHidden: [], hzTgHidA: [] }); bindAll(A, base, FN, (js) => js.replace(/p != this\b/g, "p != this.__top"));
		const B = Object.assign({}, common, { hzTgHidden: [], hzTgHidA: [], hzT19Anc: [], hzT19AncB: null }); bindAll(B, as, FN2, (js) => js.replace(/p != this\b/g, "p != this.__top"));
		A.__top = null; B.__top = null;
		const oa = A.hzT19OnHoldPath, ob = B.hzT19OnHoldPath;
		A.hzT19OnHoldPath = function() { calls0++; return oa.apply(null, arguments); };
		B.hzT19OnHoldPath = function() { calls1++; return ob.apply(null, arguments); };
		A.hzT19HidePromptTree(X.top, bx);
		B.hzT19AncFill(by); B.hzT19HidePromptTree(Y.top, by);
		const sa = X.all.map((c) => c.visible + ":" + c.alpha).join("|"), sb = Y.all.map((c) => c.visible + ":" + c.alpha).join("|");
		if (sa !== sb) bad = "tree " + t;
	}
	expect(!bad, "H2: 300 random prompt trees with 4 hold buttons: hz38HideVanilla's tree walk makes the same alpha writes as 2511842" + (bad ? " -- " + bad : ""));
	expect(calls1 === 0 && calls0 > 0, "H2: per-node parent-chain walks " + calls0 + " -> " + calls1 + " (one ancestor list per call)");
	const hv = fnText(as, "hz38HideVanilla").body;
	expect(hv.indexOf("this.hzT19AncFill(buttons);") >= 0 && hv.indexOf("this.hzT19AncFill(buttons);") < hv.indexOf("hzT19HidePromptTree"), "H2: the ancestor list is filled at the start of each hz38HideVanilla call, before the walk");
} else console.log("skip H2 equivalence");

// ---- 5. H5: signature built only when an input changed ----
{
	const h = Object.assign({}, common, { hzT19RawP: null, hzT19RawPN: -1 });
	bindAll(h, as, ["hzT19RawDiff", "hzT19RawKeep", "hzT19Tok", "hzT19B"]);
	h.HZ_T19_RAWN = 45;
	const r = rng(3);
	const vals = [null, "", "a", "E", "2:ab", 0, 1, 1.125, 0.5, NaN, true, false];
	const N = 42;
	const raw = new Array(N).fill(0).map(() => vals[Math.floor(r() * vals.length)]);
	const sigOf = (x) => x.map((v) => (typeof v === "boolean" ? h.hzT19B(v) : h.hzT19Tok(v))).join("");
	let oldSig = "", newSig = "", mine = null, builds = 0, bad = "";
	for (let f = 0; f < 20000 && !bad; f++) {
		const q = r();
		if (q < 0.03) raw[Math.floor(r() * N)] = vals[Math.floor(r() * vals.length)];
		if (q > 0.995) { oldSig = ""; newSig = ""; }   // an external reset (settings change, draw error)
		if (q > 0.99 && q <= 0.995) { oldSig = "FIXTURE"; newSig = "FIXTURE"; }
		// old: always build, redraw when it differs
		const s0 = sigOf(raw); const redraw0 = s0 !== oldSig; if (redraw0) oldSig = s0;
		// new: production decision
		let s1 = newSig;
		if (newSig !== mine || h.hzT19RawDiff(raw, N)) { s1 = sigOf(raw); mine = s1; h.hzT19RawKeep(raw, N); builds++; }
		const redraw1 = s1 !== newSig; if (redraw1) { newSig = s1; mine = s1; }
		if (redraw0 !== redraw1 || oldSig !== newSig) bad = "frame " + f;
	}
	expect(!bad, "H5: 20000 frames of random input changes, NaN, booleans and external resets: the same redraw decision every frame" + (bad ? " -- " + bad : ""));
	// build count without NaN inputs (a NaN input forces a build every frame, by design)
	{
		const h2 = Object.assign({}, common, { hzT19RawP: null, hzT19RawPN: -1 }); bindAll(h2, as, ["hzT19RawDiff", "hzT19RawKeep"]); h2.HZ_T19_RAWN = 45;
		const v2 = vals.filter((v) => v === v); const raw2 = new Array(N).fill(0).map(() => v2[Math.floor(r() * v2.length)]);
		let b2 = 0, mine2 = null, sig2 = "";
		for (let f = 0; f < 20000; f++) { if (r() < 0.03) raw2[Math.floor(r() * N)] = v2[Math.floor(r() * v2.length)]; if (sig2 !== mine2 || h2.hzT19RawDiff(raw2, N)) { b2++; h2.hzT19RawKeep(raw2, N); mine2 = sig2 = "s" + b2; } }
		expect(b2 < 20000 * 0.1, "H5: signature strings built " + b2 + " of 20000 frames when ~3% of frames change an input (was 20000)");
	}
	expect(builds > 0, "H5: NaN inputs (never equal to themselves) force a build every frame they are present: " + builds + " of 20000, never a skipped one");
	const t = fnText(as, "hzT19Tick").body;
	const sigNew = t.slice(t.indexOf("            sig = ") + 18, t.indexOf(";", t.indexOf("            sig = ")));
	const sigOld = base ? (function() { const tb = fnText(base, "hzT19Tick").body; const k = tb.indexOf("var sig:String = ") + 17; return tb.slice(k, tb.indexOf(";", k)); })() : sigNew;
	expect(sigNew === sigOld, "H5: the signature expression is the same text as 2511842 (same tokens, same order)");
	const fill = t.slice(t.indexOf("var rn:int = 0;"), t.indexOf("var sig:String = this.hzT19Sig;"));
	const need = ["kind", "m", "sel", "start", "this.hzT19Ver", "this.hzT19ActCached", "this.hzT19ItemsCached", "this.hzTgEnName", "this.hzTgRank", "this.hzTgLeg", "this.hzTextScale", "this.hzCardColor",
		"this.hzContOpacity", "HZ_ACCENT", "this.hzTextTone", "this.hzTgShowValue", "this.hzFontFace", "show", "this.hzTgScale", "this.hz30Hover", "this.hzScrH", "this.hzNameHover", "int(this.hzCardBgOpacity)",
		"int(this.hzCardShadow)", "this.hzTextShadow", "this.hzHeaderStyle", "stealSig"];
	const missing = need.filter((v) => fill.indexOf("rw0[rn++] = " + v + ";") < 0);
	expect(missing.length === 0 && (sigOld.match(/this\.hzT19(Tok|B)\(/g) || []).length === need.length - 2 + 0, "H5: every signature input is a raw input (" + need.length + " + 12 keys + 3 fonts)" + (missing.length ? " missing " + missing.join(",") : ""));
	expect(/rw0\[rn\+\+\] = this\.hzT19Key\(aw,kk\); rw0\[rn\+\+\] = this\.hzT19VanLbl\(aw,kk,false\); rw0\[rn\+\+\] = this\.hzT19VanLbl\(aw,kk,true\);/.test(fill)
		&& /keys \+= this\.hzT19Tok\(rw0\[kk\]\)/.test(t) && /this\.hzT19Tok\(rw0\[12\]\) \+ this\.hzT19Tok\(rw0\[13\]\) \+ this\.hzT19Tok\(rw0\[14\]\)/.test(t),
		"H5: keys (slots 0-11) and font names (12-14) keep the old read order and token order");
}

// ---- 6. ammo-low glow, det alpha, bio list, enemy subscription ----
{
	let glowNew = 0, getN = 0;
	function GlowFilter(c, a, bx, by, st, q) { glowNew++; this.color = c; this.alpha = a; this.blurX = bx; this.blurY = by; this.strength = st; this.quality = q; }
	function DropShadowFilter() { this.k = "ds"; }
	const mkE = (src) => {
		const cnt = { _f: [], set filters(v) { this._f = v.map((x) => Object.assign({}, x)); }, get filters() { getN++; return this._f.slice(); } };
		const h = Object.assign({}, common, { GlowFilter: GlowFilter, hzEq19: { visible: true }, hzE19Cnt: cnt, hzEqLow: false, hzEqPulse: 0, hzTextShadow: true, dark: false,
			hzE19Exp: false, hzE19Cm: false, hzArrange: false, hzFrameN: 0, hzEqExpandUntil: 0, hzE19Glow: null, hzE19GlowA: null, hzE19GlowK: -1, HZ_AMB: 0xFFAA00 });
		h.hz34C = () => false; h.hzE19Sync = () => {}; h.hzIconCol = (c) => c ^ (h.dark ? 0xFFFFFF : 0); h.hzDarkText = () => h.dark;
		h.hz35Shadow = (d) => (!h.hzTextShadow ? [] : [d ? { k: "dsL" } : { k: "dsD" }]);
		h.hzTyFilters = () => h.hz35Shadow(h.hzDarkText());
		return bindAll(h, src, ["hzE19Tick"]);
	};
	if (base) {
		const A = mkE(base), B = mkE(as);
		const r = rng(9);
		let bad = "", g0 = 0, g1 = 0;
		for (let f = 0; f < 3000 && !bad; f++) {
			const q = r();
			if (q < 0.02) { A.hzEqLow = B.hzEqLow = !A.hzEqLow; }
			if (q > 0.99) { A.hzTextShadow = B.hzTextShadow = !A.hzTextShadow; }
			if (q > 0.98 && q <= 0.99) { A.dark = B.dark = !A.dark; }
			A.hzEqPulse = B.hzEqPulse = f * 0.25;
			glowNew = 0; A.hzE19Tick(); g0 += glowNew; glowNew = 0; B.hzE19Tick(); g1 += glowNew;
			if (JSON.stringify(A.hzE19Cnt._f) !== JSON.stringify(B.hzE19Cnt._f)) bad = "frame " + f;
		}
		expect(!bad, "ammo-low glow: 3000 frames (low on/off, text shadow, dark text): the applied filter list is the same as 2511842 every frame" + (bad ? " -- " + bad : ""));
		expect(g1 === 1 && g0 > 100, "ammo-low glow: GlowFilter objects made " + g0 + " -> " + g1);
	}
	expect(fnText(as, "hzE19Tick").body.indexOf("this.hzE19Cnt.filters.length > (this.hzTextShadow ? 1 : 0)") >= 0 && /if\(!this\.hzTextShadow\) \{ return \[\]; \}\s*if\(dark\) \{ return \[new DropShadowFilter/.test(fnText(as, "hz35Shadow").body),
		"not-low check: hzTyFilters().length is (TextShadow ? 1 : 0) by hz35Shadow's definition, so no filter is built for the comparison");
}
{
	// det: same alpha at render, writes only on change
	const mk = (src) => { const blg = Clip("BLG", true); const c = add(blg, Clip("EnemyDetectionAnim_mc")); let w = 0; let a = 1;
		Object.defineProperty(c, "alpha", { get: () => a, set: (v) => { w++; a = v; } });
		const h = Object.assign({}, common, { hzBlg: blg, hzStealthOn: true, hzEnemyBarOn: false, hzEdgePulse: false, hzUserHidden: false, hz31DetHid: false });
		bindAll(h, src, ["hz31DetHide"]); h.c = c; h.w = () => w; return h; };
	if (base) {
		const A = mk(base), B = mk(as); const r = rng(2); let bad = "";
		for (let f = 0; f < 2000 && !bad; f++) {
			const q = r();
			if (q < 0.05) A.hzStealthOn = B.hzStealthOn = !A.hzStealthOn;
			if (q > 0.97) A.hzUserHidden = B.hzUserHidden = !A.hzUserHidden;
			if (q > 0.5 && q < 0.53) { A.c.alpha = B.c.alpha = r(); }   // the timeline moved it
			A.hz31DetHide(); B.hz31DetHide();
			if (A.c.alpha !== B.c.alpha) bad = "frame " + f;
		}
		expect(!bad, "det ring: same alpha as 2511842 after every exit-frame call (2000 frames incl. timeline writes)");
		expect(B.w() < A.w(), "det ring: alpha writes " + A.w() + " -> " + B.w() + " (writes only when the value differs; the rest were timeline moves or toggles)");
	}
}
{
	if (base) {
		const m = fnText(base, "hz27BioHide").body.match(/for each\(var n:String in (\[[^\]]*\])\)/);
		const c = as.match(/static const HZ27_BIO_NAMES:Array = (\[[^\]]*\]);/);
		expect(m && c && m[1] === c[1] && fnText(as, "hz27BioHide").body.indexOf("in HZ27_BIO_NAMES") >= 0, "bio: the per-frame literal array is now one static const with the same names in the same order");
	}
	const subs = as.match(/Subscribe\("HudEnemyData",this\.\w+\)/g) || [];
	expect(subs.length === 2 && subs.indexOf('Subscribe("HudEnemyData",this.hzPbEnemyBoth)') >= 0 && subs.indexOf('Subscribe("HudEnemyData",this.hzPbEnemy)') >= 0 && subs.indexOf('Subscribe("HudEnemyData",this.hzPbEn26)') < 0,
		"enemy: one subscription (hzPbEnemyBoth) plus the fallback that runs only if it did not happen");
	const ctor = as.slice(as.indexOf("this.hzBuildTarget();"), as.indexOf("try { this.hz40Init(); }"));
	expect(!/HudEnemyData/.test(ctor.slice(0, ctor.indexOf("try { this.hz26Build(); }"))) && fnText(as, "hzBuildTarget").body.indexOf('Subscribe("HudEnemyData"') < 0,
		"enemy: no HudEnemyData subscribe between the old two sites, so the two listeners were adjacent and the merged one keeps every other listener's order");
	const b26 = fnText(as, "hz26Build").body;
	expect(/Subscribe\("HudEnemyData",this\.hzPbEnemyBoth\); this\.hz44EnSub = true;/.test(b26) && /if\(!this\.hz44EnSub\) \{ try \{ BSUIDataManager\.Subscribe\("HudEnemyData",this\.hzPbEnemy\);/.test(as),
		"enemy: subscribed in hz26Build; if that did not happen the target card subscribes on its own (no update lost)");
	// order and throw model
	const seq = [];
	const h = Object.assign({}, common, { hzPbEnemy: (e) => { seq.push("tg:" + e); if (e === 3) throw new Error("x"); }, hzPbEn26: (e) => { seq.push("26:" + e); } });
	bindAll(h, as, ["hzPbEnemyBoth"]);
	let threw = 0;
	for (let e = 1; e <= 4; e++) { try { h.hzPbEnemyBoth(e); } catch (x) { threw++; } }
	expect(seq.join(",") === "tg:1,26:1,tg:2,26:2,tg:3,26:3,tg:4,26:4" && threw === 1, "enemy: every update reaches both handlers, target card first; a throw in the first still runs the second and is rethrown");
}

if (failed) { console.error(failed + " FAILED"); process.exit(1); }
console.log("grouphide tests passed");
