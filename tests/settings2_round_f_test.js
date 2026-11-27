// Settings 2.0 round: leftover clip, pills, spacing, search, Quick Menu,
// vanilla target, OK/CANCEL, Signals, banners, presets, folders, preview, radius.
// Run: node tests/settings2_round_f_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const as = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const insert = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const draw = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");
const cpp = fs.readFileSync(path.join(__dirname, "..", "src", "main.cpp"), "utf8").replace(/\r\n/g, "\n");
const def = fs.readFileSync(path.join(__dirname, "..", "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8");

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

const vanilla = fnText(as, "hz26Vanilla").body;
expect(/var eq:Boolean = live;/.test(vanilla) && /VerticalDivider2_mc/.test(vanilla),
	"1: vanilla grenade/power clips hide whenever Horizon is live, not only when extras are on");
expect(/hz26EqRowG\.graphics\.clear/.test(fnText(as, "hz26EqRow").body),
	"1: extras row clears its clip when the card is off");

const z = fnText(as, "hz34ZDraw").body;
expect(/hz51T/.test(z) && /HZ51_BTN_H/.test(z) && /drawRoundRect\(cx,py,cw,pillH,6,6\)/.test(z),
	"2: GLOBAL/CUSTOM pills use hz51T at button height with radius 6");
expect(!/drawRoundRect\(cx,cy - 11,cw,22,22,22\)/.test(z),
	"2: size pills are no longer 22px capsules");

expect(/var shY:Number = y \+ 10/.test(fnText(as, "hz51DrawList").body) && !/firstSec \? 2 : 10/.test(fnText(as, "hz51DrawList").body),
	"3: every section, including the first, uses a 10px header-to-card gap");

expect(/function hz51DrawArrangeBtn/.test(as) && /hz51DrawArrangeBtn\(this\.hzSetOver/.test(fnText(as, "hz51Draw").body),
	"4: ARRANGE CARDS is redrawn on the search overlay so it stays visible");
expect(/arrX - 8/.test(fnText(as, "hz51DrawFind").body),
	"4: search results stop before the Arrange button");
expect(/"×"/.test(fnText(as, "hz51DrawSearchBox").body) && /xy - 6/.test(fnText(as, "hz51DrawSearchBox").body),
	"4: search X is centered on the circle");

const quick = fnText(as, "hz51Quick").body;
expect(/QUICK MENU \/ FAVORITES MENU/.test(quick) && /hz51ModRow\("quickmenu"/.test(quick) && /hz51Unavail/.test(quick),
	"5/17/19/20: Quick Menu missing state is a module banner plus locked rows");
expect(/EXTENDED SLOT KEYS/.test(quick) && /QuickMenuExtEmptySlots/.test(quick),
	"19: extras Empty/Opacity/Scale stay on the page so no INI key is dropped");

const t19 = fnText(as, "hzT19Tick").body;
expect(/!this\.hzShowTarget/.test(t19) && /hzT19Off/.test(t19),
	"6: Target Card off restores and hides the Horizon prompt so vanilla is untouched");

const btn = fnText(as, "hzSetBtn").body;
expect(/28 - t\.textHeight/.test(btn),
	"7: OK / CANCEL text is vertically centered on the 28px pill");

const scan = fnText(as, "hz51Scan").body;
expect(/ScanShowSignals/.test(scan) && /ScanMaxSignals/.test(scan) && /ScanShowWorldTags/.test(scan),
	"8: Signals keeps the player-facing keys");
expect(!/ScanNearestUnscanned/.test(scan) && !/ScanWorldMarkers/.test(scan) && !/ScanSignalsCompact/.test(scan) && !/ScanCompassCompact/.test(scan) && !/ScanWorldTagScale/.test(scan),
	"8: Signals hides internal keys from the UI");
expect(/YOUR SHIP AND VEHICLE/.test(scan) && /PLACE NAMES/.test(scan) && /HOW MANY SIGNALS/.test(scan),
	"8: Signals uses plain names");

expect(/AccentHex/.test(fnText(as, "hz51Help").body) && /six digits/.test(fnText(as, "hz51Help").body),
	"9: Accent custom color help is plain language");
expect(!/AccentColor=\d/.test(fnText(as, "hz51Help").body) && !/in the ini/.test(fnText(as, "hz51Help").body),
	"9: Appearance Accent help has no developer INI recipe");

expect(/function hz51HelpMore/.test(as) && /DlgPersuasionMeter/.test(fnText(as, "hz51Help").body),
	"10: Setting Details covers persuasion and remaining keys");

const comms = fnText(as, "hz51Comms").body;
expect(/id == "sub"/.test(comms) && /id == "spk"/.test(comms) && /id == "dly"/.test(comms) && /id == "dlap"/.test(comms) && /id == "prs"/.test(comms) && /id == "inp"/.test(comms) && /id == "cmp"/.test(comms),
	"11/23: Comms sidebar pages are Subtitles, Speaker, Layout, Appearance, Persuasion, Input, Compatibility");
expect(/COMMS MODULE/.test(fnText(as, "hz51ModBanner").body) && /hz51WrapMod\(rows, "comms"/.test(comms),
	"11/20: Comms pages wrap with the module banner");

expect(/kind == "save"/.test(fnText(as, "hzFileActionDone").body) && /g_f11PushedGen/.test(cpp),
	"12: a saved preset refreshes the list while F11 stays open");

expect(/hz37Req = "openfolder"/.test(fnText(as, "hzSetChange").body) && /openfolder/.test(cpp) && /ShellExecuteW/.test(cpp),
	"13: Folder SHOW and old-character logs open the Message Log folder through the DLL");
expect(/OLD CHARACTER LOGS/.test(fnText(as, "hz51Msglog").body),
	"13: old characters is labeled as old character logs");

expect(/Debug=0/.test(def) && /PerfDiag=0/.test(def) && /PerfMode=0/.test(def) && /PerfDump=0/.test(def),
	"14: default.ini Debug / PerfDiag / PerfMode / PerfDump are 0");
expect(!/WatchLog/.test(def),
	"14: WatchLog stays off by having no default.ini key");
expect(/"Debug":0/.test(as) || /Debug":0/.test(as),
	"14: HUD defaults keep Debug off");
expect(/"PerfDiag":0/.test(as) || /PerfDiag":0/.test(as),
	"14: HUD defaults keep PerfDiag off");
expect(/"PerfDump":0/.test(as) || /PerfDump":0/.test(as),
	"14: HUD defaults keep PerfDump off");

expect(/scope is not installed/i.test(fnText(as, "hz51Cards").body) && /hz51ModRow\("scope"/.test(fnText(as, "hz51Cards").body),
	"15: Combat Scope shows the not-installed banner when the module is missing");
expect(/hz30Mod\["scope"\] !== 1/.test(fnText(as, "hz42ScRows").body) && /ScopeHoldBreathChip/.test(fnText(as, "hz51Cards").body),
	"15: the old catalog still omits Scope without the module; Combat adds the locked rows");

expect(/function hz51PvPaint/.test(as) && /hz51PvPaint/.test(fnText(as, "hz51DrawRight").body),
	"16: Live Preview paints from pending values while F11 is open");
expect(!/ENTER_FRAME|setInterval/.test(fnText(as, "hz51PvPaint").body),
	"16: Live Preview adds no per-frame timer");

expect(/function hz51UnavailChip/.test(as) && /chip == "unavail"/.test(fnText(as, "hz51DrawList").body),
	"17/20: locked module rows draw an UNAVAILABLE chip and keep saved values");

expect(/drawRoundRect\(x0,y,boxW,HZ51_ROW,HZ51_BOX_R/.test(fnText(as, "hz51DrawList").body),
	"18: selected rows use the shared card radius");
expect(/hz34Ring\(b,0,0,W,H,HZ51_WIN_R/.test(fnText(as, "hz51Draw").body) && /b.mask = this.hzSetWinMask/.test(fnText(as, "hz51Draw").body),
	"24: the settings window uses a rounded ring and clips its body to that shape");

expect(/"id":"prs","l":"CHOICES & PERSUASION"/.test(fnText(as, "hz51Side").body),
	"21: Comms sidebar has CHOICES & PERSUASION");
expect(/"k":"DlgSaidStyle"/.test(comms) && /"k":"DlgPersuadeStyle"/.test(comms) && /"k":"DlgPersuadeColor"/.test(comms) && /"k":"DlgPersuasionMeter"/.test(comms) && /"k":"DlgMarkers"/.test(comms),
	"21: Choices & Persuasion lists every old F11 persuasion INI key");
expect(/ALREADY-SAID STYLE/.test(comms) && /PERSUASION TAG COLOR/.test(comms) && /PERSUASION METER/.test(comms) && /QUESTION \/ ADVANCE MARKERS/.test(comms),
	"21: persuasion rows keep the old F11 labels");

const mods = fnText(as, "hz51Modules").body;
expect(/STATUS DIRECTORY/.test(mods) && /SHOW WHEN/.test(mods) && /t":"mc"/.test(mods),
	"22: Modules page has the status directory, Show when, and per-module cards");
expect(/CORE HUD/.test(mods) && /QUICK MENU/.test(mods) && /COMMS AND DIALOGUE/.test(mods) && /NOTIFICATIONS/.test(mods),
	"22: module cards cover Core, Font, Quick Menu, Comms, Scanner, Scope, Notifications");
expect(/modqh/.test(fnText(as, "hz51DrawModCard").body) && /QuickMenuHorizon/.test(fnText(as, "hz51Mute").body),
	"22: Quick Menu card has Horizon Style inline; Extended Mode mutes while it is off");

expect(/SubAutoPause/.test(comms) && /DlgAutoPause/.test(comms) && /USE HORIZON/.test(comms) && /PAUSED - CONFLICT/.test(fnText(as, "hz51ModBanner").body),
	"23: Compatibility has auto-pause, Use Horizon, and a paused-conflict banner");
expect(/CHOICES & PERSUASION/.test(fnText(as, "hz51Side").body) && /INPUT & HINTS/.test(fnText(as, "hz51Side").body),
	"23: Comms sidebar lists every approved page");

expect(/hz51DrawArrangeBtn/.test(draw) && /hz51PvPaint/.test(draw) && /hz51WrapMod/.test(insert),
	"source of truth is still hz51_insert.as / hz51_draw.as");

if (failed) {
	console.error(failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log(passed + " passed");
