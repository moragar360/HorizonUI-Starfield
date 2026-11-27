// F11 > CARDS layout (0.43.3.2): one section per card. Run: node tests/f11_cards_layout_test.js
// Runs the production hz34CardRows / hz34Sz / hz34Cmp / hz42ScRows (types stripped) on a small host and checks:
//  1. the section headers and their order (GENERAL ... NOTIFICATIONS, SCOPE only with the module);
//  2. the row set: every key, label, type, options, ids, range and note is the same as before the reorder
//     (compared with 0c56d1f, the recovered 7ae6add, through git; a source zip without git checks the pinned key list only), and the
//     defaults tables (HZ_SET_DEF, HZ31_DEF, the [Cards] writer) are unchanged;
//  3. a card's SIZE and extras are indented (sub) under its main toggle; COMPACT STRIPS: SIZE is in GENERAL and
//     XP TOAST: SIZE in NOTIFICATIONS next to MISSION TOAST;
//  4. headers are never rows: every row has a key and a control, a header rides on the row below it, and the list
//     geometry (selection follow / scroll) counts its 24 px, so keyboard / gamepad lands on real rows;
//  5. SCOPE rows only with the Scope module; MISSION TOAST + SIZE locked (grayed, off, GLOBAL) without Comms;
//     QUICK MENU > HORIZON STYLE locked (grayed, off) without the Quick Menu module, same install-note pattern;
//  6. batch e: the help text under the rows moved into each row's (i) popup (r.inote, shown first by hz35InfoOf), so
//     the list is just rows; a disabled row keeps its reason under it (it has no (i));
//  7. batch j: the ACTIVE BUFFS section and its rows are gone (the base compare leaves them out of the old list,
//     and HZ_SET_DEF drops exactly the Active Buffs defaults).
// Author: Moragar. Last modified: 2026-11-19 (batch k).
"use strict";

const fs = require("fs");
const path = require("path");
const gitBase = require("./lib/git_base.js");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const BASE = process.env.HZ_BASE || "0c56d1f8fd98929c86a7ca3b53dcbb2e247ddf31";   // batch k: the recovered 7ae6add (tree 28c1c49f)
const baseRes = gitBase.readBase(root, BASE);
const baseAs = baseRes.src;

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
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => {
		const nm = p.split(":")[0].trim();
		const dv = p.indexOf("=") >= 0 ? p.slice(p.indexOf("=") + 1).trim() : null;
		return dv != null ? nm + " = " + dv : nm;
	});
	const b = f.body.replace(/var (\w+):[\w*]+/g, "let $1").replace(/catch\((\w+):\w+\)/g, "catch($1)");
	return new Function(...params, b);
}
function rowsOf(src, mods) {
	const h = { hz30Mod: mods || {} };
	for (const n of ["hz34CardRows", "hz34Sz", "hz34Cmp", "hz42ScRows"]) h[n] = toJs(src, n);
	return h.hz34CardRows();
}
const list = (rows) => rows.filter((r) => !r.pill);
const defLine2 = (src) => (src.match(/private static const HZ_SET_DEF:Object = .*/) || [""])[0];
const strip = (r) => { const o = Object.assign({}, r); delete o.h; delete o.sub; delete o.n13; if (o.inote !== undefined) { o.note = o.inote; delete o.inote; } return JSON.stringify(o); };

const ORDER = ["GENERAL", "VITALS", "JETPACK", "EQUIPMENT", "COMPASS", "QUEST TRACKER", "PLANET", "HAZARD STATUS", "CHARACTER", "WATCH", "AFFLICTIONS", "ENEMY HEALTH", "STEALTH", "VEHICLE", "HOVER + CONTAINER", "QUICK MENU", "NOTIFICATIONS"];   // 0.43.3.0 batch f: QUICK MENU
const KEYS = ["Compact", "CompactScale", "ShowVitals", "VitalsScale", "VitalsLayout", "VitalsBars", "ShowJetpack", "JetpackScale", "ShowAmmo", "EquipmentScale", "EquipmentCompact", "EquipmentExtras",
	"ShowCompass", "CompassScale", "CompassCompact", "ShowQuests", "QuestsScale", "QuestsCompact", "QuestsWidth", "QuestsMaxHeight", "QuestsWrap", "ShowPlanet", "PlanetScale", "PlanetCompact", "PlanetDetails",
	"HazardStatus", "HazardScale", "HazardCompact", "ShowCharacter", "CharacterScale", "CharacterCompact", "WatchStyle", "WatchScale", "ShowAfflictions", "AfflictionsScale",
	"EnemyBar", "EnemyScale", "StealthMeter", "StealthScale", "VehicleExitPill",
	"ShowTarget", "NameHover", "HoverScale", "ContainerScale", "QuickMenuHorizon", "QuickMenuExtended", "QuickMenuSlotCount", "QuickMenuSlotsPerRow", "QuickMenuExtendedLayout", "QuickMenuExtEmptySlots", "QuickMenuExtPanelOpacity", "QuickMenuExtSlotScale", "QuickMenuKey13", "QuickMenuKey14", "QuickMenuKey15", "QuickMenuKey16", "QuickMenuKey17", "QuickMenuKey18", "QuickMenuKey19", "QuickMenuKey20", "QuickMenuKey21", "QuickMenuKey22", "QuickMenuKey23", "QuickMenuKey24", "XpToastScale", "MissionToast", "MissionToastScale"];
const MAIN = ["CompactScale", "ShowVitals", "ShowJetpack", "ShowAmmo", "ShowCompass", "ShowQuests", "ShowPlanet", "HazardStatus", "ShowCharacter", "WatchStyle", "ShowAfflictions", "EnemyBar", "StealthMeter", "VehicleExitPill", "ShowTarget", "QuickMenuHorizon", "QuickMenuExtended", "XpToastScale", "MissionToast", "ScopeHoldBreathChip"];

// 0.43.3.0 batch j: the Active Buffs rows of the base (0.43.3.1 / 0.43.3.2 test builds) that were removed
const GONE = ["ActiveBuffs", "BuffsScale", "BuffsShow", "BuffsCompact", "BuffsMax", "BuffsTimers", "BuffsPermanent", "BuffsHideEmpty"];
const GONE_DEF = ',"ActiveBuffs":1,"BuffsShow":0,"BuffsMax":6,"BuffsTimers":1,"BuffsPermanent":0,"BuffsHideEmpty":1,"BuffsRule":0,"BuffsScale":-1,"BuffsCompact":0';
const comms = { comms: 1 };
const all = { comms: 1, scope: 1, quickmenu: 1 };   // 0.43.4: + quickmenu so HORIZON STYLE stays unlocked here
const now = rowsOf(as, comms);
// ---- 1. headers ----
expect(JSON.stringify(list(now).filter((r) => r.h).map((r) => r.h)) === JSON.stringify(ORDER), "section headers in order: " + list(now).filter((r) => r.h).map((r) => r.h).join(", "));
const withScope = rowsOf(as, all);
expect(JSON.stringify(list(withScope).filter((r) => r.h).map((r) => r.h)) === JSON.stringify(ORDER.concat(["SCOPE"])), "SCOPE is the last section when the module is installed");
// ---- 2. row set ----
expect(JSON.stringify(now.map((r) => r.k)) === JSON.stringify(KEYS), "the row keys, in the new order (" + now.length + " rows incl. the COMPACT MODE pill)");
expect(now[0].k === "Compact" && now[0].pill === true && now.filter((r) => r.pill).length === 1, "COMPACT MODE stays the header pill");
if (baseAs) {
	for (const mods of [{}, comms, all]) {
		// 0.43.3.0 batch f: QUICK MENU > HORIZON STYLE is the one new row; every other row is compared
		// 0.43.3.0 batch j: the base's Active Buffs rows are left out (they were removed); every other row still matches
		const QMNEW = ["QuickMenuHorizon","QuickMenuExtended","QuickMenuSlotCount","QuickMenuSlotsPerRow","QuickMenuExtendedLayout","QuickMenuExtEmptySlots","QuickMenuExtPanelOpacity","QuickMenuExtSlotScale","QuickMenuKey13","QuickMenuKey14","QuickMenuKey15","QuickMenuKey16","QuickMenuKey17","QuickMenuKey18","QuickMenuKey19","QuickMenuKey20","QuickMenuKey21","QuickMenuKey22","QuickMenuKey23","QuickMenuKey24"];
		const b = rowsOf(baseAs, mods).filter((r) => GONE.indexOf(r.k) < 0), n = rowsOf(as, mods).filter((r) => QMNEW.indexOf(r.k) < 0);
		const bm = {}; b.forEach((r) => { bm[r.k] = strip(r); });
		const nm = {}; n.forEach((r) => { nm[r.k] = strip(r); });
		const same = b.length === n.length && Object.keys(bm).length === Object.keys(nm).length && Object.keys(bm).every((k) => bm[k] === nm[k]);
		expect(same, "vs " + BASE + " (" + JSON.stringify(mods) + "): the same " + b.length + " rows with the same key, label, control, options, range, note and lock (only the order, headers and indent change)");
	}
	const defLine = (src, re) => (src.match(re) || [""])[0];
	// 0.43.3.2 batch e: the only HZ_SET_DEF change since the base is the two vehicle exit pill offsets (0 / 0 = the game's spot)
	const QMDEF = '"QuickMenuHorizon":1,"QuickMenuExtended":0,"QuickMenuSlotCount":24,"QuickMenuSlotsPerRow":6,"QuickMenuExtendedLayout":0,"QuickMenuKey13":"","QuickMenuKey14":"","QuickMenuKey15":"","QuickMenuKey16":"","QuickMenuKey17":"","QuickMenuKey18":"","QuickMenuKey19":"","QuickMenuKey20":"","QuickMenuKey21":"","QuickMenuKey22":"","QuickMenuKey23":"","QuickMenuKey24":"","QuickMenuExtEmptySlots":1,"QuickMenuExtPanelOpacity":92,"QuickMenuExtSlotScale":1,';
	const defNow = defLine(as, /private static const HZ_SET_DEF:Object = .*/).replace('"VehicleExitX":0,"VehicleExitY":0,' + QMDEF, "").replace(',"CharacterShowSeconds":8,"Debug":0,"PerfDiag":0,"PerfMode":0,"PerfDump":0', "");
	const defBase = defLine(baseAs, /private static const HZ_SET_DEF:Object = .*/).replace(GONE_DEF, "");
	expect(defNow === defBase && defLine(as, /private static const HZ31_DEF:Object = .*/) === defLine(baseAs, /private static const HZ31_DEF:Object = .*/), "defaults tables (HZ_SET_DEF, HZ31_DEF) unchanged except the Quick Menu keys (schema stays 0.43.3.0)");
	expect(fnText(as, "hz34IniLines").body === fnText(baseAs, "hz34IniLines").body && fnText(as, "hz34Ini").body === fnText(baseAs, "hz34Ini").body && fnText(as, "hz34SetCur").body === fnText(baseAs, "hz34SetCur").body, "the [Cards] reader, writer and current values unchanged (saved settings and presets behave as before)");
} else {
	gitBase.report(baseRes, BASE, "old-vs-new row and default checks", expect);
}
// ---- 7. batch j: Active Buffs is gone from F11 > CARDS (with and without the modules) ----
{
	let hit = [];
	for (const mods of [{}, comms, all]) for (const r of rowsOf(as, mods)) {
		if (/Buffs/.test(String(r.k)) || /BUFFS/.test(String(r.h || "") + String(r.l || ""))) hit.push(r.k);
	}
	expect(hit.length === 0, "batch j: no ACTIVE BUFFS section or Buffs row in F11 > CARDS" + (hit.length ? ": " + hit.join(",") : ""));
	expect(defLine2(as).indexOf("Buffs") < 0 && defLine2(as).indexOf("HazardStatus") > 0, "batch j: HZ_SET_DEF has no Active Buffs default and keeps HazardStatus");
}
// ---- 3. indent and moves ----
let cur = null, bad = [];
for (const r of list(withScope)) {
	if (r.h) cur = r.h;
	const isMain = MAIN.indexOf(r.k) >= 0;
	if (isMain === Boolean(r.sub)) bad.push(r.k);
}
expect(bad.length === 0, "main toggles are flush, every SIZE / extra is indented under its card" + (bad.length ? ": " + bad.join(",") : ""));
const secOf = (k) => { let s = null; for (const r of list(withScope)) { if (r.h) s = r.h; if (r.k === k) return s; } return null; };
expect(secOf("CompactScale") === "GENERAL" && secOf("XpToastScale") === "NOTIFICATIONS" && secOf("MissionToast") === "NOTIFICATIONS" && secOf("MissionToastScale") === "NOTIFICATIONS", "COMPACT STRIPS: SIZE in GENERAL; XP TOAST: SIZE with MISSION TOAST in NOTIFICATIONS");
expect(secOf("WatchScale") === "WATCH" && secOf("XpToastScale") !== "WATCH", "XP TOAST: SIZE left the WATCH rows");
expect(secOf("PlanetDetails") === "PLANET" && secOf("EquipmentExtras") === "EQUIPMENT" && secOf("HazardStatus") === "HAZARD STATUS", "extras under their cards");
// ---- 4. headers are not rows ----
expect(now.every((r) => typeof r.k === "string" && r.k.length > 0 && typeof r.t === "string"), "every row has a key and a control (no header-only row to land on)");
const rh = fnText(as, "hzSetRowH").body;
expect(/\(r\.h \? HZ51_SEC : 0\) \+ HZ51_ROW/.test(rh), "row geometry counts the section header with the row, so selection follow and scrolling keep the header with its row");
{
	// selection follow over the real geometry: moving down through every row keeps the selected row inside the view
	const h = { hzSetRow: 0, hzSetScroll: 0, hzSetMaxScroll: 0, HZ_SET_H: 1020, HZ_SET_TOP: 108, HZ51_FOOT: 54, HZ51_ROW: 58, HZ51_SEC: 32, hz34BanH() { return 40; }, hzSetNoteH(r) { return r.note ? 20 : 0; }, hz51QmGridH() { return 210; } };
	const k = /HZ_SET_TOP:Number = (\d+)/.exec(as); if (k) h.HZ_SET_TOP = Number(k[1]);
	const kh = /HZ_SET_H:Number = (\d+)/.exec(as); if (kh) h.HZ_SET_H = Number(kh[1]);
	const kf = /HZ51_FOOT:Number = (\d+)/.exec(as); if (kf) h.HZ51_FOOT = Number(kf[1]);
	const kr = /HZ51_ROW:Number = (\d+)/.exec(as); if (kr) h.HZ51_ROW = Number(kr[1]);
	const ks = /HZ51_SEC:Number = (\d+)/.exec(as); if (ks) h.HZ51_SEC = Number(ks[1]);
	const rhBody = fnText(as, "hzSetRowH").body.replace(/var (\w+):[\w*]+/g, "let $1").replace(/([^.\w])HZ51_(ROW|SEC)\b/g, "$1this.HZ51_$2");
	h.hzSetRowH = new Function("r", rhBody);
	const fol = fnText(as, "hzSetFollow");
	h.hzSetFollow = new Function(fol.params.split(":")[0], fol.body.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ").replace(/var (\w+):[\w*]+/g, "let $1").replace(/([^.\w])HZ_SET_(H|TOP)\b/g, "$1this.HZ_SET_$2").replace(/([^.\w])HZ51_(FOOT|ROW|SEC)\b/g, "$1this.HZ51_$2"));
	const L = list(withScope);
	// same leftover as hzSetFollow (list chrome under the tabs), not the old 64px mockup header
	const avail = h.HZ_SET_H - h.HZ51_FOOT - h.HZ_SET_TOP - 52;
	let ok = true;
	for (let i = 1; i < withScope.length; i++) {
		h.hzSetRow = i; h.hzSetFollow(withScope);
		const li = L.indexOf(withScope[i]);
		let y = 0; for (let j = h.hzSetScroll; j <= li; j++) y += h.hzSetRowH(L[j]);
		const rh = h.hzSetRowH(L[li]);
		// a row taller than the pane (key grid) is in view when it is scrolled to the top
		if (li < h.hzSetScroll || (y > avail && !(rh > avail && li === h.hzSetScroll))) { ok = false; break; }
	}
	expect(ok, "down through all " + (withScope.length - 1) + " list rows: the selected row (with its header) is always fully in view");
}
// ---- 6. help text in the (i) popup (batch e) ----
{
	const shown = [], moved = [];
	for (const mods of [{}, comms, all]) for (const r of rowsOf(as, mods)) {
		if (r.note && !r.dis) shown.push(r.k);
		if (r.inote) moved.push(r.k);
		if (r.dis && r.note && !r.n13) shown.push(r.k + "(dis without n13)");
	}
	expect(shown.length === 0, "no enabled CARDS row draws help text under it" + (shown.length ? ": " + shown.join(",") : ""));
	const m = rowsOf(as, all);
	const byK = {}; m.forEach((r) => { byK[r.k] = r; });
	expect(byK.VitalsLayout.inote && byK.QuestsWrap.inote && byK.VehicleExitPill.inote && byK.ScopeHoldBreathChip.inote && byK.CompactScale.inote, "the help text rides on the row as inote (VITALS LAYOUT, TEXT WRAP, VEHICLE EXIT PILL, SCOPE, COMPACT STRIPS: SIZE ...)");
	const off = rowsOf(as, {});
	const mts = off.filter((r) => r.k === "MissionToastScale")[0];
	expect(mts.dis && mts.note && mts.n13 && !mts.inote, "a disabled row (MISSION TOAST SIZE without Comms) keeps its reason under it");
	const infoRe = /private static const HZ35_INFO:Object = (\{[\s\S]*?\});\n/;
	const INFO = Function("return " + infoRe.exec(as)[1])();
	const h = { HZ35_INFO: INFO };
	const mk = (n) => { const f = fnText(as, n); return new Function(f.params.split(":")[0], f.body.replace(/var (\w+):[\w*]+/g, "let $1").replace(/([^.\w"])HZ35_INFO\b/g, "$1this.HZ35_INFO")); };
	h.hz35InfoBase = mk("hz35InfoBase"); h.hz35InfoOf = mk("hz35InfoOf");
	const veh = h.hz35InfoOf(byK.VehicleExitPill);
	expect(veh.indexOf(byK.VehicleExitPill.inote) === 0 && veh.indexOf(INFO.VehicleExitPill) > 0, "the popup leads with the moved text, then the longer info");
	const qw = h.hz35InfoOf(byK.QuestsWidth);
	expect(typeof qw === "string" && qw.indexOf("Font size is unchanged") === 0, "a row without its own info still gets an (i) with its moved text");
	let missing = [];
	for (const r of m) if (!r.pill && !r.dis && r.inote && !h.hz35InfoOf(r)) missing.push(r.k);
	expect(missing.length === 0, "every moved text has a popup");
	expect(h.hz35InfoOf({ k: "ShowVitals", t: "b" }) === h.hz35InfoBase({ k: "ShowVitals", t: "b" }) && h.hz35InfoOf({ k: "x", pill: true }) === null, "other tabs' rows (no inote) get the same popup as before");
	expect(/if\(rows\[ni\]\.dis\) \{ rows\[ni\]\.n13 = true; \}/.test(fnText(as, "hz34CardRows").body), "only the CARDS rows change (hz34CardRows)");
}
// ---- 5. Scope and Comms ----
const noScope = rowsOf(as, comms);
expect(!noScope.some((r) => /^Scope|_hz42scrst/.test(r.k)) && rowsOf(as, all).filter((r) => /^Scope|_hz42scrst/.test(r.k)).length === 3, "SCOPE rows only with the Scope module (omitted, not disabled)");
const noComms = rowsOf(as, {});
const mt = noComms.find((r) => r.k === "MissionToast"), ms = noComms.find((r) => r.k === "MissionToastScale");
expect(mt.dis === true && mt.dv === false && ms.dis === true && ms.dv === -1 && ms.note === "Comms module not installed. Install it from the Horizon UI installer.", "without Comms: MISSION TOAST and SIZE locked (off, GLOBAL) with the install note");
const mt2 = now.find((r) => r.k === "MissionToast"), ms2 = now.find((r) => r.k === "MissionToastScale");
expect(!mt2.dis && !ms2.dis && ms2.inote === "Same switch as COMMS > MISSION TOAST. Move it in ARRANGE CARDS" && ms2.note === undefined, "with Comms: unlocked, same text as before (now in its (i) popup)");
// 0.43.4: QUICK MENU > HORIZON STYLE locks when quickmenu.marker is absent (same pattern as MISSION TOAST / Comms)
const qmOff = now.find((r) => r.k === "QuickMenuHorizon");
expect(qmOff && qmOff.dis === true && qmOff.dv === false && qmOff.note === "Quick Menu module not installed. Install it from the Horizon UI installer." && qmOff.n13 === true && !qmOff.inote && qmOff.h === "QUICK MENU" && qmOff.l === "HORIZON STYLE", "without Quick Menu: HORIZON STYLE locked (off) with the install note under the row, no (i) popup");
const qmOn = withScope.find((r) => r.k === "QuickMenuHorizon");
expect(qmOn && !qmOn.dis && qmOn.inote === "The game's quick menu (favorites cross) as Horizon cards. Off = the game's look." && qmOn.note === undefined && !qmOn.n13, "with Quick Menu: unlocked, the usual help text in its (i) popup");
{
	// S-3: the lock only grays the row; it must not clear hzQmOn or the pending setting
	const h = { hz30Mod: { comms: 1 }, hzQmOn: true, hzSetPend: { QuickMenuHorizon: 1 } };
	for (const n of ["hz34CardRows", "hz34Sz", "hz34Cmp", "hz42ScRows"]) h[n] = toJs(as, n);
	const qm = h.hz34CardRows().find((r) => r.k === "QuickMenuHorizon");
	expect(qm && qm.dis === true && qm.dv === false && h.hzQmOn === true && h.hzSetPend.QuickMenuHorizon === 1 && !/this\.hzQmOn\s*=/.test(fnText(as, "hz34CardRows").body) && !/hzSetPend\.\w+\s*=(?!=)/.test(fnText(as, "hz34CardRows").body), "the lock leaves the saved QuickMenuHorizon value alone (hzQmOn and hzSetPend are not written)");
}
{
	const h = { hz30Mod: { comms: 1, quickmenu: 1 }, hzQmOn: true, hzQmExt: true, hzQmConflict: false, hzSetPend: { QuickMenuHorizon: false, QuickMenuExtended: true } };
	for (const n of ["hz34CardRows", "hz34Sz", "hz34Cmp", "hz42ScRows"]) h[n] = toJs(as, n);
	const off = h.hz34CardRows();
	const extOff = off.find((r) => r.k === "QuickMenuExtended");
	expect(!off.find((r) => r.k === "QuickMenuHorizon").dis && extOff.dis === true && extOff.dv === false && h.hzSetPend.QuickMenuExtended === true && h.hzQmExt === true, "pending HORIZON STYLE off greys Extended rows at once and does not write the saved Extended value");
	h.hzSetPend.QuickMenuHorizon = true;
	const on = h.hz34CardRows();
	expect(!on.find((r) => r.k === "QuickMenuExtended").dis && h.hzSetPend.QuickMenuExtended === true && h.hzQmExt === true, "pending HORIZON STYLE on unlocks Extended rows without writing the saved Extended value");
}
expect(!/addEventListener|ENTER_FRAME|setInterval|setTimeout|new Timer/.test(fnText(as, "hz34CardRows").body), "menu rows only: no timer or listener");

console.log("f11_cards_layout_test " + (failed ? "FAILED" : "passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
