// Settings 2.0 round h: live mute, control-only hits, rounded section
// panels, preset save-as-new-name dropdown, module switches, banner gap,
// representative Live Preview. Search fixes stay. No per-frame work.
// Run: node tests/settings2_round_h_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const as = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const insert = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const draw = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");
const cpp = fs.readFileSync(path.join(__dirname, "..", "src", "main.cpp"), "utf8").replace(/\r\n/g, "\n");

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

const mute = fnText(as, "hz51Mute").body;
expect(!/r\.dis = false/.test(mute) && /chip == "unavail"/.test(mute),
	"1: mute never assigns r.dis = false (builder locks and unavail chips survive)");
expect(/!locked && mute/.test(mute),
	"1: mute only sets dis=true when the parent is off");
expect(/CompassMarkers/.test(mute) && /ShowFollowers/.test(mute) && /FollowerColor/.test(mute),
	"1: MARKERS is the parent of FOLLOWERS / MARKER COLOR / the other compass marker rows");
expect(/CharacterShowSeconds/.test(mute) && /PerfDiag/.test(mute) && /QuickMenuHorizon/.test(mute),
	"1: the same enable refresh covers Character seconds, Perf, and Quick Menu children");
expect(insert.indexOf('{"k":"DlgMarkers","l":"QUESTION / ADVANCE MARKERS","t":"b","dis":true,"dv":false}') >= 0
	&& insert.indexOf('{"k":"MissionToastSound","l":"GAME QUEST SOUND","t":"b","dis":true,"dv":true}') >= 0,
	"1: DlgMarkers and MissionToastSound are builder-locked");
expect(insert.indexOf('{"k":"_diagoff","l":"LEAVE THESE OFF","t":"x","btn":"KEEP OFF","h":"NOTE","dis":true,"dv":true}') >= 0
	&& insert.indexOf('{"k":"_dirinst","l":"INSTALLED, ENABLED, AND VISIBLE","t":"x","btn":"—","h":"STATUS DIRECTORY","dis":true,"dv":true}') >= 0,
	"1: KEEP OFF and STATUS DIRECTORY are builder-locked");

function copyRow(r) { return Object.assign({}, r); }
function builderRows() {
	return [
		{ k: "ShowCompass", t: "b", h: "COMPASS" },
		{ k: "CompassMarkers", t: "b", sub: true },
		{ k: "ShowFollowers", t: "b", sub: true, l: "FOLLOWERS" },
		{ k: "FollowerColor", t: "a", sub: true, l: "MARKER COLOR" },
		{ k: "ShowLocations", t: "b", sub: true },
		{ k: "DlgMarkers", t: "b", dis: true, dv: false, l: "QUESTION / ADVANCE MARKERS" },
		{ k: "MissionToastSound", t: "b", dis: true, dv: true, l: "GAME QUEST SOUND" },
		{ k: "_diagoff", t: "x", dis: true, dv: true, btn: "KEEP OFF", l: "LEAVE THESE OFF" },
		{ k: "_dirinst", t: "x", dis: true, dv: true, h: "STATUS DIRECTORY", l: "INSTALLED, ENABLED, AND VISIBLE" }
	];
}
function fakeMute(pend, src) {
	const rows = (src || builderRows()).map(copyRow);
	const on = (k) => {
		const v = pend[k];
		if (v === undefined) return true;
		if (v === true || v === false) return Boolean(v);
		return Number(v) >= 0.5;
	};
	let parentOn = true, markersOn = true;
	for (const r of rows) {
		const k = String(r.k);
		const locked = r.chip == "unavail";
		if (r.h) { parentOn = true; markersOn = true; }
		let muteFlag = Boolean(r.sub) && !parentOn;
		if (k == "ShowFollowers" || k == "FollowerColor" || k == "ShowLocations") {
			if (!markersOn) muteFlag = true;
		}
		if (k == "FollowerColor" && !on("ShowFollowers")) muteFlag = true;
		if (r.t == "b" && k.indexOf("Show") == 0 && k != "ShowFollowers" && k != "ShowLocations") parentOn = on(k);
		if (k == "CompassMarkers") markersOn = parentOn && on("CompassMarkers");
		if (!locked && muteFlag) r.dis = true;
	}
	return rows;
}
function byK(rows, k) { return rows.find((r) => r.k === k); }
const off = fakeMute({ ShowCompass: true, CompassMarkers: false, ShowFollowers: true });
expect(off[1].dis !== true && off[2].dis === true && off[3].dis === true && off[4].dis === true,
	"1: turning MARKERS off greys FOLLOWERS, MARKER COLOR, and Locations live");
const onAgain = fakeMute({ ShowCompass: true, CompassMarkers: true, ShowFollowers: true });
expect(onAgain[2].dis !== true && onAgain[3].dis !== true && onAgain[4].dis !== true,
	"1: turning MARKERS back on re-enables those rows without reopening F11");
const afterCycle = fakeMute({ ShowCompass: true, CompassMarkers: true, ShowFollowers: true }, builderRows());
expect(byK(afterCycle, "DlgMarkers").dis === true && byK(afterCycle, "MissionToastSound").dis === true
	&& byK(afterCycle, "_diagoff").dis === true && byK(afterCycle, "_dirinst").dis === true,
	"1: DlgMarkers, MissionToastSound, KEEP OFF, and STATUS DIRECTORY stay disabled after a parent toggle cycle");
expect(byK(afterCycle, "ShowFollowers").dis !== true && byK(afterCycle, "FollowerColor").dis !== true,
	"1: FOLLOWERS and MARKER COLOR still unlock live when MARKERS is on");

const mouse = fnText(as, "hzSettingsMouse").body;
expect(/id\.indexOf\("tog"\) == 0/.test(mouse) && /id\.indexOf\("act"\) == 0/.test(mouse),
	"2: toggle and action hits change values");
expect(/id\.indexOf\("row"\) == 0/.test(mouse) && /this\.hzSetRow = ri/.test(mouse),
	"2: a row-body click selects the row");
expect(!/hz51OpenDrop\(ri/.test(mouse),
	"2: a row-body click does not open a dropdown");
expect(!/rr\.t == "b" \|\| rr\.t == "k"/.test(mouse),
	"2: a row-body click does not flip a toggle");
const sw = fnText(as, "hz51Switch").body;
expect(/hitId/.test(sw) && /"tog"/.test(fnText(as, "hz51DrawCtrl").body),
	"2: the switch hit is the track, not the card");
expect(/"act" \+ i/.test(fnText(as, "hz51DrawCtrl").body),
	"2: OPEN / SAVE buttons use act hits, not the row id");
expect(/"id":"dd"/.test(fnText(as, "hz51DrawCtrl").body) && /"id":"bar"/.test(fnText(as, "hz51DrawCtrl").body),
	"2: dropdown and slider keep their own control hits");
expect(/hzSetChange/.test(as),
	"2: keyboard / controller still change the selected row");

const list = fnText(as, "hz51DrawList").body;
expect(/hz51FillGroup/.test(list) && /HZ51_BOX_R/.test(fnText(as, "hz51FillGroup").body),
	"3: each section group sits in a rounded panel");
expect(/hz34Ring/.test(fnText(as, "hz51FillGroup").body) && /HZ51_BOX_A/.test(fnText(as, "hz51FillGroup").body),
	"3: the group uses the thin accent ring, not a square 1px frame");
expect(/drawRoundRect\(x0,y \+ 8,3,HZ51_ROW - 16/.test(list),
	"3: the selected row has the cyan left bar from the Dialogue mock");
expect(/hz34Ring/.test(fnText(as, "hz51DrawCtrl").body) && /HZ51_BOX_R/.test(fnText(as, "hz51DrawCtrl").body),
	"3: dropdowns are rounded pills");
expect(/hz34Ring/.test(fnText(as, "hz51DrawArrangeBtn").body),
	"3: ARRANGE is rounded");
expect(/hz34Ring/.test(fnText(as, "hz51DrawSide").body),
	"3: the sidebar selection is rounded");
expect(/hz34Ring/.test(fnText(as, "hz51DrawRight").body) && /SETTING DETAILS/.test(fnText(as, "hz51DrawRight").body),
	"3: Live Preview and Setting Details sit in rounded boxes");
expect(/hz51DrawList/.test(fnText(as, "hz51Draw").body) && /HZ51_BOX_R/.test(fnText(as, "hz51FillGroup").body),
	"3: every page shares the same list painter, so Typography matches Dialogue");

const drop = fnText(as, "hz51DropOpts").body;
expect(/r\.t == "p"/.test(drop) && /hz51PresetNames/.test(drop),
	"4: the preset dropdown reads names from the last DLL scan");
expect(/hz37Ps/.test(fnText(as, "hz51PresetNames").body),
	"4: preset names come from hz37Ps, not an empty opts array");
expect(/r\.t == "p"/.test(fnText(as, "hz51DropPick").body) && /hz37SelId/.test(fnText(as, "hz51DropPick").body),
	"4: picking a preset updates the selection");
expect(/hz37SelId = "u:" \+ this\.hz37Slug\(nm\) \+ "\.ini"/.test(fnText(as, "hz37SaveSubmit").body),
	"4: save-as-new-name keeps the new file id so parse can select it");
expect(/FilesScanPresets/.test(cpp) && /g_fileStateWant\.store\(true\)/.test(cpp),
	"4: the job thread flags a rescan after save");
expect(/if \(g_fileStateWant\.exchange\(false\)\)\s*FilesScanPresets/.test(cpp),
	"4: the rescan runs in the same job tick as the save, before the next UI push");
expect(/g_f11PushedGen/.test(cpp) && /hzSetIsOpen/.test(fnText(as, "hzSetFileState").body),
	"4: PushFileState still redraws while F11 is open; the window is not reopened");

function parseState(s, keepId) {
	const lines = String(s).replace(/\r/g, "").split("\n");
	const ps = [];
	for (let i = 1; i < lines.length; i++) {
		const p = String(lines[i]).split("|");
		if (p.length >= 6 && String(p[0]).length > 2 && String(p[2]).length > 0) {
			ps.push({ id: String(p[0]), u: String(p[1]) == "1", n: String(p[2]) });
		}
	}
	let sel = 0;
	for (let i = 0; i < ps.length; i++) {
		if (String(ps[i].id).toLowerCase() == String(keepId).toLowerCase()) sel = i;
	}
	return { ps, sel, names: ps.map((p) => p.n) };
}
const saved = parseState(
	"v=0.43.5.0|bak=1|undo=0|user=1|def=1|skip=0|last=\n" +
	"s:shipped.ini|0|Default|Horizon|0.43.5.0|Built-in\n" +
	"u:night_ops.ini|1|Night Ops|Player|0.43.5.0|Saved in game",
	"u:night_ops.ini"
);
expect(saved.names.indexOf("Night Ops") >= 0 && saved.ps[saved.sel].n == "Night Ops",
	"4: save-as-new-name then parse: the dropdown contains Night Ops without reopening");

const mods = fnText(as, "hz51Modules").body;
expect(/swk":"QuickMenuHorizon"/.test(mods) && /swk":"Subtitles"/.test(mods) && /swk":"Dialogue"/.test(mods),
	"5: Quick Menu, Comms, and Comms Dialogue get working Enable switches on existing INI keys");
expect(/"id":"scanner"/.test(mods) && /"id":"scope"/.test(mods) && /"id":"msglog"/.test(mods) && /"id":"font"/.test(mods),
	"5: Scanner, Scope, Notifications, and Font stay on the Modules page");
expect(!/swk":"Scan/.test(mods) && !/swk":"FontFace"/.test(mods) && !/swk":"Record"/.test(mods),
	"5: install-only modules have no fake module-level switch");
const card = fnText(as, "hz51DrawModCard").body;
expect(/"tog" \+ idx/.test(card) && /hzSetHits\.push\(\{"id":"row"/.test(card),
	"5: the module switch hit is on top of the card select hit");
expect(/HZ51_MOD_GAP/.test(fnText(as, "hz51DrawList").body),
	"5/6: module cards and banners add the 10px gap");
expect(/HZ51_MOD_GAP/.test(fnText(as, "hzSetRowH").body),
	"5/6: scroll height includes the banner / card gap so the next row cannot overlap");

expect(/y \+= bh \+ HZ51_MOD_GAP/.test(list),
	"6: every hz51WrapMod banner has space below it before the first row");
expect( /HZ51_MOD_GAP:Number = 10/.test(as),
	"6: the gap is 10px");

const pv = fnText(as, "hz51PvPaint").body;
expect(/hz51PvDialogue/.test(pv) && /hz51PvScanner/.test(pv) && /hz51PvTheme/.test(pv) && /hz51PvCard/.test(pv) && /hz51PvModule/.test(pv),
	"7: Live Preview covers Comms, Scanner, Appearance, Cards, and System");
expect(/ MORE"/.test(fnText(as, "hz51PvDialogue").body) && /Ask about the job/.test(fnText(as, "hz51PvDialogue").body),
	"7: dialogue preview is a mini options card with sample text and the N MORE hint");
expect(/FLORA/.test(fnText(as, "hz51PvScanner").body),
	"7: scanner preview is a sample signal row");
expect(/EXO 2/.test(fnText(as, "hz51PvTheme").body),
	"7: appearance preview shows the current font");
expect(!/ENTER_FRAME/.test(pv) && !/setInterval/.test(pv),
	"7: Live Preview still has no per-frame work");
expect(/hzSetPend/.test(pv) || /hzSetPend/.test(fnText(as, "hz51PvCard").body),
	"7: CANCEL reverts because paint reads pending values");

expect(/function hz51DrawArrangeBtn/.test(as) && /hz51DrawArrangeBtn\(this\.hzSetOver/.test(fnText(as, "hz51Draw").body),
	"8: ARRANGE stays visible during search");
expect(/"×"/.test(fnText(as, "hz51DrawSearchBox").body) && /xy - 6/.test(fnText(as, "hz51DrawSearchBox").body),
	"8: search X stays centered");

expect(!/ENTER_FRAME/.test(insert) && !/setInterval/.test(draw),
	"section 13: insert/draw add no per-frame timers");
expect(/hzSetIsOpen/.test(fnText(as, "hzSetFileState").body),
	"section 13: preset push runs only while F11 is open");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log("\n" + passed + " passed");
