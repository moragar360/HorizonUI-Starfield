// Settings 2.0 page audit: walk every tab / sidebar page, assert each has
// more than 0 rows, and every old F11 setting key maps to exactly one
// Settings 2.0 row (Compact Mode is header-only; extra-slot keys live on the grid).
// Run: node tests/settings2_page_audit_test.js
// Author: Moragar. Last modified: 2026-11-26.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const oldAs = fs.readFileSync(path.join(root, "actionscript", "imp", "himp1", "scripts", "HUDMenu.as"), "utf8").replace(/\r\n/g, "\n");

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
function asJs(body) {
	return body
		.replace(/var (\w+):[\w.*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/ as Array/g, "")
		.replace(/for each\(var (\w+):[\w.*]+ in /g, "for (const $1 of ")
		.replace(/for each\((\w+) in /g, "for (const $1 of ")
		.replace(/\buint\(/g, "(")
		.replace(/\bint\(/g, "(")
		.replace(/\bNumber\(/g, "Number(")
		.replace(/\bString\(/g, "String(")
		.replace(/\bBoolean\(/g, "Boolean(");
}
function keysOf(src, name) {
	const ks = [];
	fnText(src, name).body.replace(/"k"\s*:\s*"([^"]+)"/g, (_, k) => { ks.push(k); return ""; });
	return ks;
}
function dummyFrom(src, name) {
	const seen = {};
	const out = [];
	for (const k of keysOf(src, name)) {
		if (seen[k]) continue;
		seen[k] = 1;
		out.push({ k, l: k, t: "b" });
	}
	return out;
}

const HZ_RULE_NAMES = ["ALWAYS","COMBAT ONLY","HIDE IN SHIP","WEAPON DRAWN ONLY","IN USE / NOT FULL","WHEN NOT FULL (HP/O2)","ONLY WHEN AFFLICTED","ON XP / LEVEL / CREDITS","WHEN OVERWEIGHT","XP / LEVEL OR OVERWEIGHT"];
const HZ_SET_TABS = ["CARDS","APPEARANCE","SCANNER","COMMS","SYSTEM"];
const HZ_FONT_NAMES = ["EXO 2","ROBOTO","GAME FONT","GAME FONT (SEMIBOLD)"];
const HZ_FONT_IDS = [1,2,0,3];
const HZ_TONE_NAMES = ["AUTO","LIGHT TEXT","DARK TEXT"];
const HZ_HDRSTYLE_NAMES = ["CAPS + SPACED","TITLE CASE"];
const HZ_SET_SCRH = [0,720,900,1080,1200,1440,1600,2160];
const HZ_SET_SCRH_N = ["OFF","720","900","1080","1200","1440","1600","2160"];
const HZ_TIME_NAMES = ["OFF","LOCAL / GAME","PC/REAL","LOCAL / GAME + PC/REAL"];
const HZ_CLOCK_NAMES = ["12 H","24 H"];
const HZ_TEMP_NAMES = ["°C","°F"];
const HZ_FOL_PAL = [0x5CFF7A,0xC6FF4A,0xFFD24A,0xFF6BD6,0xF4F8FA,0x5EE3A1];
const HZ_FOL_NAMES = ["BRIGHT GREEN","LIME","GOLD","PINK","WHITE","MINT"];
const HZ51_PERF_NAMES = ["BASELINE","HOVER SKIP","FIXTURE","FULL PIPELINE","SAME TARGET","RAPID TARGETS","SCANNER","BACKGROUND HUD"];
const HZ_ACCENT = 0x3FD0E0;
const HZ_ACCENTS = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
const HZ_SET_ACCNAMES = ["CYAN","TEAL","AMBER","VIOLET","LIME","WHITE","ROSE","ORANGE","SKY","GOLD","MINT","STEEL","DEEP BLUE"];
const PRELUDE = [
	"const HZ_RULE_NAMES = " + JSON.stringify(HZ_RULE_NAMES),
	"const HZ_SET_TABS = " + JSON.stringify(HZ_SET_TABS),
	"const HZ_FONT_NAMES = " + JSON.stringify(HZ_FONT_NAMES),
	"const HZ_FONT_IDS = " + JSON.stringify(HZ_FONT_IDS),
	"const HZ_TONE_NAMES = " + JSON.stringify(HZ_TONE_NAMES),
	"const HZ_HDRSTYLE_NAMES = " + JSON.stringify(HZ_HDRSTYLE_NAMES),
	"const HZ_SET_SCRH = " + JSON.stringify(HZ_SET_SCRH),
	"const HZ_SET_SCRH_N = " + JSON.stringify(HZ_SET_SCRH_N),
	"const HZ_TIME_NAMES = " + JSON.stringify(HZ_TIME_NAMES),
	"const HZ_CLOCK_NAMES = " + JSON.stringify(HZ_CLOCK_NAMES),
	"const HZ_TEMP_NAMES = " + JSON.stringify(HZ_TEMP_NAMES),
	"const HZ_FOL_PAL = " + JSON.stringify(HZ_FOL_PAL),
	"const HZ_FOL_NAMES = " + JSON.stringify(HZ_FOL_NAMES),
	"const HZ51_PERF_NAMES = " + JSON.stringify(HZ51_PERF_NAMES),
	"const HZ_ACCENT = " + HZ_ACCENT,
	"const HZ_ACCENTS = " + JSON.stringify(HZ_ACCENTS),
	"const HZ_SET_ACCNAMES = " + JSON.stringify(HZ_SET_ACCNAMES)
].join(";\n") + ";\n";

function bind(host, name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => {
		const nm = p.split(":")[0].trim().split("=")[0].trim();
		const dv = p.indexOf("=") >= 0 ? p.slice(p.indexOf("=") + 1).trim() : null;
		return dv != null ? nm + " = " + dv : nm;
	});
	host[name] = new Function(...params, PRELUDE + asJs(f.body));
}

const host = {
	hz30Mod: { scanner: 1, comms: 1, scope: 1, quickmenu: 1 },
	hzQmConflict: false,
	hzQmOn: true,
	hzSetPend: {
		Compact: false, QuickMenuExtended: 1, QuickMenuHorizon: 1,
		HideMainHudWhileScanning: 1, CharacterRule: 7,
		PerfDiag: 1, ShowVitals: 1, ShowJetpack: 1, ShowAfflictions: 1,
		HazardStatus: 1, ShowAmmo: 1, EnemyBar: 1, StealthMeter: 1,
		ShowTarget: 1, ShowCompass: 1, ShowQuests: 1, ShowPlanet: 1,
		ShowCharacter: 1, XpToast: 1, MissionToast: 1, Subtitles: 1,
		Dialogue: 1, Record: 1, Persist: 1, FontFace: 1
	},
	hzSetPage: 0,
	hzSetTab: 0,
	hz31Page: 0,
	hz37Cf: "",
	hz31Val(k) { return k === "SubAutoPause" || k === "DlgAutoPause" ? 1 : 0; },
	hz31On() { return true; },
	hz31SubForeign() { return []; },
	hz31DlgForeign() { return false; },
	hz30FontAvail() { return true; },
	hzMsglogModule() { return 1; },
	hzAccPal() { return [0x33AABB]; },
	hzAccNames() { return ["TEAL"]; },
	hzCardPal() { return [0x111111]; },
	hzCardNames() { return ["GRAPHITE"]; },
	hz37Note(k, n) { return n || ""; },
	hz30FontRows(rows) { return rows; },
	hz34Sz(card) { return { k: card + "Scale", l: "SIZE", t: "z", sub: true }; },
	hz34Cmp(card) { return { k: card + "Compact", l: "COMPACT FORM", t: "r", opts: ["GLOBAL","ON","OFF"], ids: [-1,1,0], sub: true }; },
	hz42ScRows(rows) {
		rows.push({ k: "ScopeHoldBreathChip", l: "SCOPE: HOLD-BREATH CHIP", t: "b", h: "SCOPE" });
		rows.push({ k: "ScopeChipScale", l: "CHIP SIZE", t: "n", sub: true });
		rows.push({ k: "_hz42scrst", l: "CHIP SPOT + SIZE", t: "x", btn: "RESET", sub: true });
	},
	hz34CardRows() { return dummyFrom(as, "hz34CardRows"); },
	hz40ScanRows() { return dummyFrom(as, "hz40ScanRows"); },
	hz40PopupRows() { return dummyFrom(as, "hz40PopupRows"); },
	hz31CommsRows() { return dummyFrom(as, "hz31CommsRows"); },
	hz37Rows() { return dummyFrom(as, "hz37Rows"); }
};

for (const n of [
	"hz51Copy","hz51ByKey","hz51Pick","hz51Help","hz51HelpMore","hz51HelpOf","hz51Line","hz51On","hz51Mute","hz51Finish","hz51FbLog",
	"hz51RuleRow","hz51Card","hz51AddCard","hz51Goto","hz51Unavail","hz51ModRow","hz51WrapMod","hz51ModState","hz51ModBadge",
	"hz51Modules","hz51Msglog","hz51Quick","hz51Fallback","hz51Cards","hz51Appear","hz51Scan","hz51Comms","hz51CommsMap",
	"hz51System","hz51Side","hz51Pages","hz51PageIndex","hz51PageClamp","hz51Rows","hz51Crumb"
]) {
	bind(host, n);
}

const pageRows = [];
const keyMap = {};
for (let tab = 0; tab < 5; tab++) {
	const pages = host.hz51Pages(tab);
	for (let p = 0; p < pages.length; p++) {
		const id = String(pages[p].id);
		const label = HZ_SET_TABS[tab] + " > " + pages[p].l;
		let rows = [];
		let err = null;
		try { rows = host.hz51Rows(tab, p) || []; }
		catch (e) { err = e; rows = []; }
		const real = rows.filter((r) => r && r.k !== "_empty" && !r.pill);
		pageRows.push({ tab, id, label, n: real.length, keys: real.map((r) => String(r.k)), err });
		for (const r of real) {
			const k = String(r.k);
			if (!keyMap[k]) keyMap[k] = [];
			keyMap[k].push(label);
		}
		expect(!err, label + " builder does not throw" + (err ? (": " + err.message) : ""));
		expect(real.length > 0, label + " has more than 0 rows (" + real.length + ")");
	}
}

const sta = pageRows.find((p) => p.id === "sta");
const com = pageRows.find((p) => p.id === "com");
const inter = pageRows.find((p) => p.id === "int");
expect(!!sta && sta.keys.indexOf("ShowVitals") >= 0 && sta.keys.indexOf("ShowJetpack") >= 0 && sta.keys.indexOf("ShowAfflictions") >= 0 && sta.keys.indexOf("HazardStatus") >= 0,
	"STATUS has Vitals / Jetpack / Afflictions / Hazard Status");
expect(!!com && com.keys.indexOf("ShowAmmo") >= 0 && com.keys.indexOf("EnemyBar") >= 0 && com.keys.indexOf("StealthMeter") >= 0 && com.keys.indexOf("CrosshairRule") >= 0 && com.keys.indexOf("ScopeHoldBreathChip") >= 0,
	"COMBAT has Equipment / Enemy Health / Stealth / Crosshair / Scope");
expect(!!inter && inter.keys.indexOf("ShowTarget") >= 0 && inter.keys.indexOf("ContainerScale") >= 0 && inter.keys.indexOf("VehicleExitPill") >= 0,
	"INTERACTION has Target / Container / Vehicle Exit");

const oldKeys = new Set();
function addOld(arr) {
	for (const k of arr) {
		if (!k) continue;
		oldKeys.add(k);
	}
}
addOld(keysOf(oldAs, "hzSetRows"));
addOld(keysOf(as, "hz34CardRows"));
addOld(keysOf(as, "hz40ScanRows"));
addOld(keysOf(as, "hz31CommsRows"));
addOld(keysOf(as, "hz37Rows"));
addOld(keysOf(as, "hz40PopupRows"));
addOld(keysOf(as, "hz42ScRows"));
addOld(keysOf(as, "hz41TopRows"));
function addSzCmp(src, name) {
	fnText(src, name).body.replace(/hz34Sz\("([^"]+)"/g, (_, c) => { oldKeys.add(c + "Scale"); return ""; });
	fnText(src, name).body.replace(/hz34Cmp\("([^"]+)"/g, (_, c) => { oldKeys.add(c + "Compact"); return ""; });
}
addSzCmp(as, "hz34CardRows");
addSzCmp(as, "hz40ScanRows");
addOld(["CardBgOpacity","CardShadow","SettingsOpacity","StartupIntro","Debug","PerfDiag","PerfMode","PerfDump",
	"TempUnit","CharacterShowSeconds","CrosshairRule","Record","Persist","HistorySize","AccentHex","CardHex",
	"NameHover","HoverScale","WatchScale","VitalsLayout","VitalsBars"]);

const headerOnly = new Set(["Compact"]);
const gridKeys = new Set();
for (let n = 13; n <= 24; n++) gridKeys.add("QuickMenuKey" + n);
const skipOld = new Set(["_hz31page","_hz30m_scanner","_hz30m_comms","_arrange",
	"ScanSignalsCompact","ScanCompassCompact","ScanWorldTagScale","ScanNearestUnscanned","ScanWorldMarkers"]);
const missing = [];
const dupes = [];
for (const k of [...oldKeys].sort()) {
	if (headerOnly.has(k) || skipOld.has(k)) continue;
	if (k.indexOf("_hz30p_") === 0) continue;
	if (gridKeys.has(k)) {
		if (!keyMap._qmkeys) missing.push(k + " (grid)");
		continue;
	}
	if (k.charAt(0) === "_") continue;
	const places = keyMap[k] || [];
	if (places.length === 0) missing.push(k);
	if (places.length > 1) dupes.push(k + " @ " + places.join(" | "));
}

expect(missing.length === 0, "every old F11 setting key maps to a Settings 2.0 row" + (missing.length ? (" missing: " + missing.join(", ")) : ""));
expect(dupes.length === 0, "no old F11 key maps to two Settings 2.0 rows" + (dupes.length ? (" dupes: " + dupes.join("; ")) : ""));
expect(keyMap.Compact === undefined, "Compact Mode stays in the header, not a list row");
expect(pageRows.length === 35, "audit walked all 35 sidebar pages (found " + pageRows.length + ")");

console.log("--- page row counts ---");
for (const p of pageRows) {
	console.log(p.n + "\t" + p.label);
}

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
