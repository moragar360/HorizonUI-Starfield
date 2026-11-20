// F11 > CARDS layout (0.43.3.2): one section per card. Run: node tests/f11_cards_layout_test.js
// Runs the production hz34CardRows / hz34Sz / hz34Cmp / hz42ScRows (types stripped) on a small host and checks:
//  1. the section headers and their order (GENERAL ... NOTIFICATIONS, SCOPE only with the module);
//  2. the row set: every key, label, type, options, ids, range and note is the same as before the reorder
//     (compared with 7ae6add through git; a source zip without git checks the pinned key list only), and the
//     defaults tables (HZ_SET_DEF, HZ31_DEF, the [Cards] writer) are unchanged;
//  3. a card's SIZE and extras are indented (sub) under its main toggle; COMPACT STRIPS: SIZE is in GENERAL and
//     XP TOAST: SIZE in NOTIFICATIONS next to MISSION TOAST;
//  4. headers are never rows: every row has a key and a control, a header rides on the row below it, and the list
//     geometry (selection follow / scroll) counts its 24 px, so keyboard / gamepad lands on real rows;
//  5. SCOPE rows only with the Scope module; MISSION TOAST + SIZE locked (grayed, off, GLOBAL) without Comms.
// Author: Moragar. Last modified: 2026-11-18.
"use strict";

const fs = require("fs");
const path = require("path");
const gitBase = require("./lib/git_base.js");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const BASE = process.env.HZ_BASE || "7ae6add";
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
const strip = (r) => { const o = Object.assign({}, r); delete o.h; delete o.sub; return JSON.stringify(o); };

const ORDER = ["GENERAL", "VITALS", "JETPACK", "EQUIPMENT", "COMPASS", "QUEST TRACKER", "PLANET", "HAZARD STATUS", "CHARACTER", "WATCH", "AFFLICTIONS", "ACTIVE BUFFS", "ENEMY HEALTH", "STEALTH", "VEHICLE", "HOVER + CONTAINER", "NOTIFICATIONS"];
const KEYS = ["Compact", "CompactScale", "ShowVitals", "VitalsScale", "VitalsLayout", "VitalsBars", "ShowJetpack", "JetpackScale", "ShowAmmo", "EquipmentScale", "EquipmentCompact", "EquipmentExtras",
	"ShowCompass", "CompassScale", "CompassCompact", "ShowQuests", "QuestsScale", "QuestsCompact", "QuestsWidth", "QuestsMaxHeight", "QuestsWrap", "ShowPlanet", "PlanetScale", "PlanetCompact", "PlanetDetails",
	"HazardStatus", "HazardScale", "HazardCompact", "ShowCharacter", "CharacterScale", "CharacterCompact", "WatchStyle", "WatchScale", "ShowAfflictions", "AfflictionsScale",
	"ActiveBuffs", "BuffsScale", "BuffsShow", "BuffsCompact", "BuffsMax", "BuffsTimers", "BuffsPermanent", "BuffsHideEmpty", "EnemyBar", "EnemyScale", "StealthMeter", "StealthScale", "VehicleExitPill",
	"ShowTarget", "NameHover", "HoverScale", "ContainerScale", "XpToastScale", "MissionToast", "MissionToastScale"];
const MAIN = ["CompactScale", "ShowVitals", "ShowJetpack", "ShowAmmo", "ShowCompass", "ShowQuests", "ShowPlanet", "HazardStatus", "ShowCharacter", "WatchStyle", "ShowAfflictions", "ActiveBuffs", "EnemyBar", "StealthMeter", "VehicleExitPill", "ShowTarget", "XpToastScale", "MissionToast", "ScopeHoldBreathChip"];

const comms = { comms: 1 };
const all = { comms: 1, scope: 1 };
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
		const b = rowsOf(baseAs, mods), n = rowsOf(as, mods);
		const bm = {}; b.forEach((r) => { bm[r.k] = strip(r); });
		const nm = {}; n.forEach((r) => { nm[r.k] = strip(r); });
		const same = b.length === n.length && Object.keys(bm).length === Object.keys(nm).length && Object.keys(bm).every((k) => bm[k] === nm[k]);
		expect(same, "vs " + BASE + " (" + JSON.stringify(mods) + "): the same " + b.length + " rows with the same key, label, control, options, range, note and lock (only the order, headers and indent change)");
	}
	const defLine = (src, re) => (src.match(re) || [""])[0];
	expect(defLine(as, /private static const HZ_SET_DEF:Object = .*/) === defLine(baseAs, /private static const HZ_SET_DEF:Object = .*/) && defLine(as, /private static const HZ31_DEF:Object = .*/) === defLine(baseAs, /private static const HZ31_DEF:Object = .*/), "defaults tables (HZ_SET_DEF, HZ31_DEF) unchanged");
	expect(fnText(as, "hz34IniLines").body === fnText(baseAs, "hz34IniLines").body && fnText(as, "hz34Ini").body === fnText(baseAs, "hz34Ini").body && fnText(as, "hz34SetCur").body === fnText(baseAs, "hz34SetCur").body, "the [Cards] reader, writer and current values unchanged (saved settings and presets behave as before)");
} else {
	gitBase.report(baseRes, BASE, "old-vs-new row and default checks", expect);
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
expect(/\(r\.h \? 24 : 0\) \+ 32/.test(rh), "row geometry counts a header's 24 px, so selection follow and scrolling keep the header with its row");
{
	// selection follow over the real geometry: moving down through every row keeps the selected row inside the view
	const h = { hzSetRow: 0, hzSetScroll: 0, hzSetMaxScroll: 0, HZ_SET_H: 660, HZ_SET_TOP: 112, hz34BanH() { return 40; }, hzSetNoteH(r) { return r.note ? 20 : 0; } };
	const k = /HZ_SET_TOP:Number = (\d+)/.exec(as); if (k) h.HZ_SET_TOP = Number(k[1]);
	const kh = /HZ_SET_H:Number = (\d+)/.exec(as); if (kh) h.HZ_SET_H = Number(kh[1]);
	h.hzSetRowH = toJs(as, "hzSetRowH");
	const fol = fnText(as, "hzSetFollow");
	h.hzSetFollow = new Function(fol.params.split(":")[0], fol.body.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ").replace(/var (\w+):[\w*]+/g, "let $1").replace(/([^.\w])HZ_SET_(H|TOP)\b/g, "$1this.HZ_SET_$2"));
	const L = list(withScope);
	const avail = h.HZ_SET_H - 64 - h.HZ_SET_TOP;
	let ok = true;
	for (let i = 1; i < withScope.length; i++) {
		h.hzSetRow = i; h.hzSetFollow(withScope);
		const li = L.indexOf(withScope[i]);
		let y = 0; for (let j = h.hzSetScroll; j <= li; j++) y += h.hzSetRowH(L[j]);
		if (li < h.hzSetScroll || y > avail) { ok = false; break; }
	}
	expect(ok, "down through all " + (withScope.length - 1) + " list rows: the selected row (with its header) is always fully in view");
}
// ---- 5. Scope and Comms ----
const noScope = rowsOf(as, comms);
expect(!noScope.some((r) => /^Scope|_hz42scrst/.test(r.k)) && rowsOf(as, all).filter((r) => /^Scope|_hz42scrst/.test(r.k)).length === 3, "SCOPE rows only with the Scope module (omitted, not disabled)");
const noComms = rowsOf(as, {});
const mt = noComms.find((r) => r.k === "MissionToast"), ms = noComms.find((r) => r.k === "MissionToastScale");
expect(mt.dis === true && mt.dv === false && ms.dis === true && ms.dv === -1 && ms.note === "Comms module not installed. Install it from the Horizon UI installer.", "without Comms: MISSION TOAST and SIZE locked (off, GLOBAL) with the install note");
const mt2 = now.find((r) => r.k === "MissionToast"), ms2 = now.find((r) => r.k === "MissionToastScale");
expect(!mt2.dis && !ms2.dis && ms2.note === "Same switch as COMMS > MISSION TOAST. Move it in ARRANGE CARDS", "with Comms: unlocked, same note as before");
expect(!/addEventListener|ENTER_FRAME|setInterval|setTimeout|new Timer/.test(fnText(as, "hz34CardRows").body), "menu rows only: no timer or listener");

console.log("f11_cards_layout_test " + (failed ? "FAILED" : "passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
