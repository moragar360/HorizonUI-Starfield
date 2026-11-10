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
		hzStealthOn: true, hzEnemyBarOn: true, hzEdgePulse: true, hzGroupVisible: true, hzHideCache: [], now: 0,
		HZ44_ALLOW_UNREPLACED: true, HorizonAffl_mc: {}, hzCompact: false, hzRuleAffl: 6, hzRulePlanet: 0, hzPlanPill: {},
		HorizonStealth_mc: {}, HorizonEnemy_mc: {}, HorizonEdge_mc: {}, hzBlg: null,
		HZ27_BIO_NAMES: ["BioAlertText", "BioCondition_mc", "BioAlertBG_mc"], hz27BioMine: [null, null, null], hz27BioHid: false, hz31DetHid: false, hz31DetC: null, hz31DetA: 1
	});
	h.getChildByName = function(n) { return hud.getChildByName(n); };
	h.hzPerfNow = function() { return h.now; };
	return bindAll(h, as, ["hz44GrpWant", "hz44GrpTick", "hzPillOn", "hz27BioHide", "hz31DetHide"]);
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
		h.hz44GrpTick(true);
		const g0 = h.hud.gets;
		for (let f = 0; f < 50; f++) { h.hz44GrpTick(true); h.hz44GrpTick(false); }
		expect(h.blg.visible === true && !h.hz44Hid && g0 === 1 && h.hud.gets === g0 && h.hzBlg === h.blg, "not eligible: " + label + " -> per-piece path, group untouched; one lookup fills hzBlg (S1), then none");
	}
	const h = gHost();
	h.hzStealthOn = h.hzEnemyBarOn = h.hzEdgePulse = false;
	h.hz44GrpTick(true);
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
	// MF1 gating matrix (r2): every term against an independent reference rule, over all combinations of the card terms
	const ref = (c) => c.allow && c.ini && c.style === 0 && !c.hidden
		&& c.affl && c.afflCard && !c.compact && (c.rAffl === 0 || c.rAffl === 6)
		&& c.planet && c.haz && c.rPlanet === 0 && c.pill
		&& ((c.st && c.stCard) || (c.en && c.enCard) || (c.ep && c.epCard));
	const r = rng(441);
	let n = 0, bad = "", eligible = 0;
	const seen = {};
	for (let t = 0; t < 6000 && !bad; t++) {
		const b = () => r() < 0.85;
		const c = { allow: r() < 0.9, ini: b(), style: [0, 0, 0, 1, 2, 3, 4][Math.floor(r() * 7)], hidden: r() < 0.1, affl: b(), afflCard: b(), compact: r() < 0.2,
			rAffl: [0, 6, 6, 1, 2, 3, 4, 5][Math.floor(r() * 8)], planet: b(), haz: b(), rPlanet: [0, 0, 0, 1, 2, 3, 4, 5, 6][Math.floor(r() * 9)], pill: b(),
			st: r() < 0.5, stCard: b(), en: r() < 0.5, enCard: b(), ep: r() < 0.5, epCard: b() };
		const h = gHost();
		h.HZ44_ALLOW_UNREPLACED = c.allow; h.hz44GrpIni = c.ini; setStyle(h, c.style); h.hzUserHidden = c.hidden;
		h.hzShowAfflictions = c.affl; h.HorizonAffl_mc = c.afflCard ? {} : null; h.hzCompact = c.compact; h.hzRuleAffl = c.rAffl;
		h.hzShowPlanet = c.planet; h.hzHazardAlert = c.haz; h.hzRulePlanet = c.rPlanet; h.hzPlanPill = c.pill ? {} : null;
		h.hzStealthOn = c.st; h.HorizonStealth_mc = c.stCard ? {} : null; h.hzEnemyBarOn = c.en; h.HorizonEnemy_mc = c.enCard ? {} : null; h.hzEdgePulse = c.ep; h.HorizonEdge_mc = c.epCard ? {} : null;
		h.hz44GrpTick(true); h.hz44GrpTick(false);
		const w = ref(c);
		if (h.hz44GrpWant() !== w || h.blg.visible !== !w) bad = JSON.stringify(c);
		if (w) eligible++;
		n++;
	}
	expect(!bad && eligible > 50 && n - eligible > 50, "MF1 matrix: 6000 random configs, the group is hidden exactly when the reference rule says so (" + eligible + " eligible)" + (bad ? " -- " + bad : ""));
	const one = (label, set, want) => { const h = gHost(); set(h); h.hz44GrpTick(true); expect(h.hz44Hid === want && h.blg.visible === !want, (want ? "eligible: " : "not eligible: ") + label); };
	for (const rp of [1, 2, 3, 4, 5, 6]) one("PlanetRule " + rp + " (the planet card is not always on screen)", (h) => { h.hzRulePlanet = rp; }, false);
	one("no planet pill (the classic card hzPlanOld, which holds the HAZARD ALERT outline, is always hidden by hzFrameApply)", (h) => { h.hzPlanPill = null; }, false);
	one("Compact on (the AFFLICTIONS card shows only in the full layout)", (h) => { h.hzCompact = true; }, false);
	for (const ra of [1, 2, 3, 4, 5]) one("AfflictionsRule " + ra + " (the card can be off while an affliction arrives)", (h) => { h.hzRuleAffl = ra; }, false);
	one("AfflictionsRule 0 (always)", (h) => { h.hzRuleAffl = 0; }, true);
	one("AfflictionsRule 6 (when afflicted, the default)", (h) => { h.hzRuleAffl = 6; }, true);
	one("only EDGE PULSE on, its clip not built", (h) => { h.hzStealthOn = h.hzEnemyBarOn = false; h.HorizonEdge_mc = null; }, false);
	one("only ENEMY BAR on, built", (h) => { h.hzStealthOn = h.hzEdgePulse = false; }, true);
	one("HZ44_ALLOW_UNREPLACED false (the safe answer: never group-hide while the landing / positive env alerts have no Horizon version)", (h) => { h.HZ44_ALLOW_UNREPLACED = false; }, false);
	expect(/private static const HZ44_ALLOW_UNREPLACED:Boolean = true;/.test(as), "flag default: true (user 2026-11-10 10:11: hide them for now)");
	// HideVanillaWatch off / WatchStyle 1 or 2 releases the group (Director's open question), and so does a style write before the sync
	for (const st of [1, 2]) {
		const h = gHost(); h.hz44GrpTick(true);
		h.hzWatchStyle = st; h.hz44GrpTick(true);
		expect(h.blg.visible === true && !h.hz44Hid, "WatchStyle " + st + " written by F11 (before hz43SyncHide runs): the group is released next frame tick");
		const h2 = gHost(); h2.hz44GrpTick(true);
		h2.hzHideVanillaWatch = false; h2.hz44GrpTick(true);
		expect(h2.blg.visible === true && !h2.hz44Hid, "HideVanillaWatch off on its own: the group is released");
	}
}
{
	// Bot 3 S1: grouped from frame 1, then AFFLICTIONS off: the per-piece hides have hzBlg in that same frame
	const h = gHost();
	h.blg.getChildByName("EnemyDetectionAnim_mc").alpha = 1;
	h.hz44GrpTick(true);
	expect(h.hz44Hid && h.hzBlg === h.blg, "S1: grouped from the first frame, hzBlg is set by the group check (same root child hzFindByName finds)");
	h.hzShowAfflictions = false;
	h.hz44GrpTick(true);   // release (frame tick)
	const of = fnText(as, "hzOnFrame").body;
	const loopRuns = of.indexOf("if(this.hzHideVanillaWatch && !this.hz44Hid)") >= 0 && h.hzHideVanillaWatch && !h.hz44Hid && h.hzBlg != null;
	h.hz27BioHide(); h.hz31DetHide();   // exit frame of the same frame
	expect(!h.hz44Hid && h.blg.visible === true && loopRuns && h.blg.getChildByName("EnemyDetectionAnim_mc").alpha === 0,
		"S1: release frame: the BLG child loop has its ref, and the enemy ring is hidden in the same frame (no 30-frame wait)");
}
{
	// user 10:11: Original Vanilla Watch (and HideVanillaWatch off) shows the vanilla bio alert and enemy ring; live both ways
	const h = gHost();
	h.hzBlg = h.blg;
	const bio = h.blg.getChildByName("BioAlertText");
	const bg = add(h.blg, Clip("BioAlertBG_mc")), cond = add(h.blg, Clip("BioCondition_mc"));
	const det = h.blg.getChildByName("EnemyDetectionAnim_mc");
	bg.visible = false;          // the game's own value (not ours)
	det.alpha = 0.8;             // the game's own value
	const tick = () => { h.hz27BioHide(); h.hz31DetHide(); };
	setStyle(h, 0); tick();
	expect(bio.visible === false && cond.visible === false && det.alpha === 0, "OFF: bio alert and enemy ring hidden (unchanged)");
	setStyle(h, 1); tick();
	expect(bio.visible === true && cond.visible === true && bg.visible === false && det.alpha === 0.8,
		"F11 -> VANILLA: next tick the bio alert, its icon and the enemy ring are back with the game's own values (a piece the game had hidden stays hidden, alpha 0.8 not forced 1)");
	for (let f = 0; f < 20; f++) tick();
	expect(bio.visible === true && det.alpha === 0.8, "VANILLA: stays shown (no per-frame re-hide)");
	setStyle(h, 0); tick();
	expect(bio.visible === false && det.alpha === 0, "F11 -> OFF again: hidden again next tick (live, both ways)");
	h.hzWatchStyle = 2; tick();   // F11 wrote the style; hz43SyncHide has not run yet
	expect(bio.visible === true && det.alpha === 0.8, "VANILLA+HORIZON written before the style sync: shown the same tick");
	setStyle(h, 0); tick();
	h.hzHideVanillaWatch = false; tick();
	expect(bio.visible === true && det.alpha === 0.8, "HideVanillaWatch off: shown");
	// a timeline-replaced instance while hidden keeps the game's own value on release
	setStyle(h, 0); tick();
	remove(bio); const bio2 = add(h.blg, Clip("BioAlertText")); bio2.visible = true;
	remove(det); const det2 = add(h.blg, Clip("EnemyDetectionAnim_mc")); det2.alpha = 0.5;
	tick();
	expect(bio2.visible === false && det2.alpha === 0, "a new instance from the timeline is hidden too");
	setStyle(h, 1); tick();
	expect(bio2.visible === true && det2.alpha === 0.5, "release: the new instances get their own values back");
	// AFFLICTIONS off in OFF mode: today's rule (only BioAlertText comes back; the watch hide owns the others)
	setStyle(h, 0); cond.visible = true; tick();
	h.hzShowAfflictions = false; tick();
	expect(bio2.visible === true && cond.visible === false, "OFF + AFFLICTIONS off: the bio alert comes back, BioCondition_mc stays with the watch hide (unchanged)");
}
{
	// r3 (Director, 10:38): the scan-time LocationAlertText hide also shows in Original Vanilla Watch; game value kept; live both ways
	const mkLoc = () => {
		const blg = Clip("BottomLeftGroup_mc", true);
		const loc = add(blg, Clip("LocationAlertText"));
		const h = Object.assign({}, common, { hzBlg: blg, hz41LocBlg: null, hz41LocHid: false, hz41LocC: null, hz41LocV: true, hzFrameN: 1, scan: true,
			hzWatchStyle: 0, hzHideVanillaWatch: true });
		h.hz41LocWant = function() { return h.scan; };
		h.hzFindByName = function() { return blg; };
		bindAll(h, as, ["hz41LocHide"]);
		h.blg = blg; h.loc = loc; return h;
	};
	const h = mkLoc();
	h.hz41LocHide();
	expect(h.loc.visible === false && h.hz41LocHid, "OFF, scanning: LocationAlertText hidden (unchanged)");
	setStyle(h, 1); h.hz41LocHide();
	expect(h.loc.visible === true && !h.hz41LocHid, "F11 -> VANILLA mid-scan: LocationAlertText back next tick with the game's value");
	for (let f = 0; f < 10; f++) h.hz41LocHide();
	expect(h.loc.visible === true, "VANILLA: stays shown during the scan");
	setStyle(h, 0); h.hz41LocHide();
	expect(h.loc.visible === false && h.hz41LocHid, "F11 -> OFF mid-scan: hidden again (live, both ways)");
	setStyle(h, 0); h.scan = false; h.hz41LocHide(); h.scan = true;
	h.loc.visible = false;   // the game's own value at the next session start (e.g. no alert on screen)
	h.hz41LocHide(); setStyle(h, 2); h.hz41LocHide();
	expect(h.loc.visible === false, "release in VANILLA+HORIZON restores the game's own value (false here), not a forced true");
	const h2 = mkLoc(); h2.hzWatchStyle = 1; h2.hz41LocHide();
	expect(h2.loc.visible === true && !h2.hz41LocHid, "WatchStyle 1 written before the style sync: never hidden");
	const h3 = mkLoc(); h3.hzHideVanillaWatch = false; h3.hz41LocHide();
	expect(h3.loc.visible === true, "HideVanillaWatch off: never hidden");
	let calls = 0; const h4 = mkLoc(); setStyle(h4, 1); h4.hz41LocWant = function() { calls++; return true; }; bindAll(h4, as, ["hz41LocHide"]);
	h4.hz41LocHide(); h4.hz41LocHide();
	expect(calls === 2, "VANILLA: the scan session state machine (hz41LocWant) still runs every tick, so a switch back mid-scan is exact");
}
{
	// VANILLA hides nothing in BottomLeftGroup_mc: every BLG child keeps the game's own visible / alpha through every BLG hide path
	for (const st of [1, 2]) {
		const h = gHost();
		h.hzBlg = h.blg;
		for (const n of ["BioCondition_mc", "BioAlertBG_mc", "BioConditionBase_mc", "EnvCondition_mc", "O2CO2_mc"]) add(h.blg, Clip(n));
		const r = rng(77 + st);
		for (const k of h.blg.kids) { k.visible = r() < 0.8; k.alpha = r() < 0.7 ? 1 : Math.round(r() * 100) / 100; }
		h.blg.visible = true;
		const snap = () => h.blg.visible + "#" + h.blg.alpha + "#" + h.blg.kids.map((k) => k.name + ":" + k.visible + ":" + k.alpha).join("|");
		const before = snap();
		Object.assign(h, { hz41LocBlg: null, hz41LocHid: false, hz41LocC: null, hz41LocV: true, hzFrameN: 1 });
		h.hz41LocWant = function() { return true; };   // scanning
		h.hzFindByName = function() { return h.blg; };
		bindAll(h, as, ["hz41LocHide"]);
		setStyle(h, st);
		for (let f = 0; f < 50; f++) { h.hz44GrpTick(true); h.hz27BioHide(); h.hz31DetHide(); h.hz41LocHide(); h.hz44GrpTick(false); }
		const of = fnText(as, "hzOnFrame").body;
		const listJs = toJs(of.slice(of.indexOf("names = [];"), of.indexOf("this.hz44Skip = grp"))).replace("var grp = this.hz44Hid;", "var grp = false;");
		const lst = Function("with(this){ var names; " + listJs + " return names; }").call({ hzWatchStyle: st, hzHideVanillaWatch: false, hzHideVanillaCompass: true, hzHideVanillaBoost: true, hzHideVanillaAmmo: true, hzHideVanillaHealth: true, hzHideCache: [], hz36HideStale: false });
		const blgInList = lst.filter((n) => h.blg.kids.some((k) => k.name === n));
		expect(snap() === before && blgInList.length === 0 && of.indexOf("if(this.hzHideVanillaWatch && !this.hz44Hid)") >= 0,
			"WatchStyle " + st + ": 50 ticks of the group check, bio, ring and scan-location hides (scanning) and the rebuild list leave every BottomLeftGroup_mc child at the game's own visible / alpha; the per-piece BLG loop is off");
	}
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
		const h = Object.assign({}, common, { hzBlg: blg, hzStealthOn: true, hzEnemyBarOn: false, hzEdgePulse: false, hzUserHidden: false, hz31DetHid: false,
			hzHideVanillaWatch: true, hzWatchStyle: 0, hz31DetC: null, hz31DetA: 1 });
		bindAll(h, src, ["hz31DetHide"]); h.c = c; h.w = () => w; return h; };
	if (base) {
		const A = mk(base), B = mk(as); const r = rng(2); let bad = "";
		for (let f = 0; f < 2000 && !bad; f++) {
			const q = r();
			if (q < 0.05) A.hzStealthOn = B.hzStealthOn = !A.hzStealthOn;
			if (q > 0.97) A.hzUserHidden = B.hzUserHidden = !A.hzUserHidden;
			if (q > 0.5 && q < 0.53 && A.hz31DetHid) { A.c.alpha = B.c.alpha = r(); }   // a write while hidden (vanilla itself never writes this alpha)
			A.hz31DetHide(); B.hz31DetHide();
			if (A.c.alpha !== B.c.alpha) bad = "frame " + f;
		}
		expect(!bad, "det ring (WatchStyle 0): same alpha as 2511842 after every exit-frame call (2000 frames incl. writes while hidden)");
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

// ---- 7. right-side guard (user, via Bot 3: "ok to calrify though not the stuff on the right side with the weapon") ----
// The VANILLA rule is limited to BottomLeftGroup_mc's children. The right-side weapon / ammo / health / jetpack hiding must be
// exactly as in 56d4098, in every watch style.
{
	let b56 = null;
	try { b56 = cp.execFileSync("git", ["show", "56d4098:actionscript/horizon_block.as"], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { b56 = null; }
	if (b56) {
		const names = (src) => { const out = []; const re = /(?:private|public) function (\w+)\(/g; let m; while ((m = re.exec(src))) out.push(m[1]); return out; };
		const RIGHT = /RightMeters|BottomRightGroup|EquippedWeapon|HealthBar|"Health_mc"|VerticalDivider_mc|Jetpack|EnemyHealthHolder_mc|StealthMeter_mc|hzHideVanillaAmmo|hzHideVanillaHealth|hzHideVanillaBoost/;
		// the scope check compares 56d4098 with the r2 code commit 32af5f3, so a later stack (E1) on top does not count as r2
		let r2src = as;
		try { r2src = cp.execFileSync("git", ["show", "32af5f3:actionscript/horizon_block.as"], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { r2src = as; }
		const all56 = names(b56), allNow = names(r2src);
		const changed = [], rightFns = [];
		let rightSame = true;
		for (const n of all56) {
			let x, y;
			let z;
			try { x = fnText(b56, n).body; y = fnText(r2src, n).body; z = fnText(as, n).body; } catch (e) { changed.push(n + "(missing)"); continue; }
			if (x !== y) changed.push(n);
			if (RIGHT.test(x)) { rightFns.push(n); if (x !== y || x !== z) rightSame = false; }
		}
		const added = allNow.filter((n) => all56.indexOf(n) < 0);
		const allowed = ["hz44GrpWant", "hz44GrpTick", "hz27BioHide", "hz31DetHide", "hzWlFlush", "hz38HideVanilla"];
		expect(rightSame && rightFns.length >= 5 && rightFns.indexOf("hzOnFrame") >= 0,
			"right side: all " + rightFns.length + " functions that touch the weapon / ammo / health / jetpack / RightMeters hides are byte-identical to 56d4098 (in 32af5f3 and in this tree)");
		expect(changed.every((n) => allowed.indexOf(n) >= 0) && added.length === 0,
			"r2 changes only the BottomLeftGroup functions (and the watchlog flush / H2 clear): " + changed.join(", ") + (added.length ? " added: " + added.join(",") : ""));
		expect(changed.filter((n) => n !== "hzWlFlush" && n !== "hz38HideVanilla").every((n) => !RIGHT.test(fnText(r2src, n).body.replace(/^\s*\/\/.*$/gm, ""))),
			"none of the changed BottomLeftGroup functions reads or writes a right-side piece");
		// behavior: the rebuild list's right-side names in VANILLA (1, 2) and the other styles, 56d4098 vs now
		const listOf = (src, st, flags) => {
			const of = fnText(src, "hzOnFrame").body;
			const i0 = of.indexOf("names = [];"), i1 = of.indexOf("this.hz44Skip = grp");
			const js = toJs(of.slice(i0, i1)).replace("var grp = this.hz44Hid;", "var grp = false;");
			const h = { hzWatchStyle: st, hzHideVanillaWatch: !(st === 1 || st === 2), hzHideVanillaCompass: true, hzHideVanillaBoost: !!(flags & 1), hzHideVanillaAmmo: !!(flags & 2), hzHideVanillaHealth: !!(flags & 4), hzHideCache: [], hz36HideStale: false };
			return Function("with(this){ var names; " + js + " return names; }").call(h);
		};
		let same = true;
		for (const st of [1, 2, 0, 3, 4]) for (let f = 0; f < 8; f++) if (JSON.stringify(listOf(b56, st, f)) !== JSON.stringify(listOf(as, st, f))) same = false;
		expect(same, "right side, behavior: the hide list for VANILLA and every other style, 8 ammo / health / boost combinations each, equals 56d4098's");
	} else console.log("skip right-side guard (git show 56d4098 not available)");
}

// ---- r4 N-1 (Bot 3 r3): the hazard has a Horizon status even where the pill line has no hazard word ----
// The group hide counts the PLANET pill's status line for EnvAlertText. Off-surface (IN SHIP / STATION / IN SPACE) and in
// a narrow PlanetCompact strip that line has no hazard word; the AFFLICTIONS card (required in full by the gate) shows it
// as an env chip. Behavior: hzAfSetEnv -> hzAfSync puts an env chip on the card whatever the location kind or Compact.
{
	let bad = "";
	for (const kind of ["surface", "ship", "station", "space"]) for (const compact of [false, true]) for (const pc of [false, true]) {
		let laid = null;
		const h = Object.assign({}, common, { hzPpKind: kind, hzCompact: compact, hzPlanetCompact: pc, hzAfEnv: [], hzAfPers: [], hzAfSeen: {}, hzAfSoak: 0, hzFrameN: 7, hzAfflCount: 0,
			hz27PersSafe: () => [], hz26OwInAffl: () => false, hzRefreshVisibility: () => {}, hzAfLayoutChips: (a) => { laid = a; } });
		bindAll(h, as, ["hzAfSetEnv", "hzAfSync", "hzPretty", "hzAfKind", "hzAfSortFn", "hzV19"]);
		h.hzAfSetEnv([{ sEffectIcon: "HazardEffect_Radiation" }, { sEffectIcon: "HazardEffect_RestoreSoak" }], 0.4);
		const env = (laid || []).filter((o) => o.env);
		if (env.length !== 1 || h.hzAfflCount < 1) bad = kind + " compact=" + compact + " planetCompact=" + pc + " env=" + env.length;
	}
	expect(!bad, "N-1: an env hazard gives an env chip on the AFFLICTIONS card in every location kind (surface / ship / station / space), with or without Compact flags" + (bad ? " -- " + bad : ""));
	const sync = fnText(as, "hzAfSync").body, setE = fnText(as, "hzAfSetEnv").body;
	expect(!/hzPpKind|hzCompact|hzPlanetCompact/.test(sync + setE), "N-1: the env chip path does not read the location kind or any Compact flag");
	expect(/this\.hzAfSetEnv\(a,soak\);\s*$/.test(fnText(as, "hzOnEnvEffects").body) && !/return/.test(fnText(as, "hzOnEnvEffects").body), "N-1: every environment-effects update (hzOnEnvEffects) ends in hzAfSetEnv, with no early return");
}

// ---- r4 N-3 (Bot 3 r3): the hold-path ancestor set is cleared at the end of each hz38HideVanilla call (N4 fix) ----
// hzT19HoldBtns refills one shared array, so a set left over from an earlier call would answer for the old buttons when
// that same array reaches hzT19OnHoldPathA outside hz38HideVanilla.
{
	const FN = ["hz38HideVanilla", "hzT19HidePromptTree", "hzT19OnHoldPath", "hzT19OnHoldPathA", "hzT19AncFill", "hzT19IsHoldBtn", "hzT19HideA", "hzT19HideBtnArt", "hzT19HoldMeterName"];
	const fix = (js) => js.replace(/p != this\b/g, "p != this.__top");
	const r = rng(4403); let bad = "", nullBad = 0;
	for (let t = 0; t < 200 && !bad; t++) {
		const seed = Math.floor(r() * 1e9);
		const build = (rr) => { const top = Clip("top", true); top.__root = false; const all = [];
			const grow = (p, d) => { const n = 1 + Math.floor(rr() * 4); for (let i = 0; i < n; i++) { const c = add(p, Clip(rr() < 0.15 ? "HoldMeter_mc" : "c" + d + i, d < 4 && rr() < 0.55)); all.push(c); if (c.kids) grow(c, d + 1); } };
			grow(top, 0); return { top: top, all: all }; };
		const shared = new Array(4);
		const mk = () => { const h = Object.assign({}, common, { hzTgHidden: [], hzTgHidA: [], hzT19Anc: [], hzT19AncB: null, hzObjRing: 2, __top: null,
			hzT19KeepHold: () => {}, hzT19HideReticle: () => {}, hzT19ShowReticle: () => {} }); bindAll(h, as, FN, fix); return h; };
		const B = mk();
		// call 1: the game's prompt with one set of hold buttons
		const X = build(rng(seed)); const p1 = rng(seed + 1);
		for (let k = 0; k < 4; k++) shared[k] = X.all[Math.floor(p1() * X.all.length)];
		B.hzT19HoldBtns = () => shared;
		B.hz38HideVanilla({ RolloverActivationHolder_mc: null }, X.top, "item");
		if (B.hzT19AncB !== null) nullBad++;
		// later, outside hz38HideVanilla: the same shared array now holds other buttons of another tree
		const Y = build(rng(seed + 2)), Z = build(rng(seed + 2)); const p2 = rng(seed + 3);
		const pick = []; for (let k = 0; k < 4; k++) pick.push(Math.floor(p2() * Y.all.length));
		for (let k = 0; k < 4; k++) shared[k] = Y.all[pick[k]];
		B.hzT19HidePromptTree(Y.top, shared);
		const C = mk(); const fresh = pick.map((k) => Z.all[k]);
		C.hzT19HidePromptTree(Z.top, fresh);
		const sy = Y.all.map((c) => c.visible + ":" + c.alpha).join("|"), sz = Z.all.map((c) => c.visible + ":" + c.alpha).join("|");
		if (sy !== sz) bad = "tree " + t;
	}
	expect(nullBad === 0, "N-3: hzT19AncB is null after every hz38HideVanilla call");
	expect(!bad, "N-3: 200 random trees: a later prompt walk with the reused button array (outside hz38HideVanilla) makes the same writes as a fresh host, so no stale ancestor set is used" + (bad ? " -- " + bad : ""));
}

if (failed) { console.error(failed + " FAILED"); process.exit(1); }
console.log("grouphide tests passed");
