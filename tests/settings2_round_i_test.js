// Settings 2.0 round i: live SAVE→write→scan→push→dropdown, and
// per-setting Live Preview (old F11 planet/character renderers).
// Run: node tests/settings2_round_i_test.js
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
function cppFn(src, sig) {
	const i = src.indexOf(sig);
	if (i < 0) throw new Error("missing " + sig);
	const b = src.indexOf("{", i);
	let d = 0;
	for (let p = b; p < src.length; p++) {
		if (src[p] === "{") d++;
		else if (src[p] === "}") { d--; if (d === 0) return src.slice(b + 1, p); }
	}
	throw new Error("unbalanced " + sig);
}

// ---- 1. Live SAVE path (not the parser-only Night Ops host test) ----
const work = cppFn(cpp, "void FilesPollWork()");
const doAct = work.indexOf("DoAction");
const reply = work.indexOf("g_fileReplyReady.store(true)");
const scan1 = work.indexOf("FilesScanPresets");
expect(doAct >= 0 && scan1 >= 0 && reply >= 0, "1: FilesPollWork still writes, scans, and replies");
expect(doAct < scan1 && scan1 < reply,
	"1: the job writes (DoAction), then rescans, then publishes the save-done reply");
expect(work.indexOf("g_fileStateWant.store(true)") < scan1,
	"1: the rescan is flagged after the write in the same job tick");

const push = cppFn(cpp, "std::uint64_t PushFileState()");
expect(/return 0;/.test(push) && /return ok \? gen : 0/.test(push),
	"1: PushFileState returns 0 when the invoke did not happen, so gen is not marked pushed");
expect(/gen = g_fileStateGen\.load/.test(push),
	"1: the returned gen is the one copied with the state string");

const poll = cppFn(cpp, "void PollFileAction()");
expect(poll.indexOf("PushFileState") >= 0 && poll.indexOf("PushFileState") < poll.indexOf("hzFileActionDone"),
	"1: save-done pushes the post-write list before the HUD redraws");
expect(/save\|/.test(poll) && /delete\|/.test(poll),
	"1: that same-tick push is the SAVE / REMOVE path, while F11 is already open");

const settings = cppFn(cpp, "void PollSettings(");
expect(/if \(pushed\)/.test(settings) && /g_f11PushedGen\.store\(pushed/.test(settings),
	"1: PollSettings only marks a generation pushed after a successful Invoke");
expect(!/g_f11PushedGen\.store\(gen,/.test(settings),
	"1: PollSettings no longer stores the unread gen when PushFileState returns early");
expect(/hzSetIsOpen/.test(fnText(as, "hzSetFileState").body),
	"1: the movie still redraws the open F11 window when the list arrives");

const save = fnText(as, "hz37SaveSubmit").body;
expect(/hz37RememberPreset/.test(save) && /hz37SelId = "u:" \+ this\.hz37Slug\(nm\) \+ "\.ini"/.test(save),
	"1: SAVE with a new name inserts the row into hz37Ps this draw, then sets the file id");
expect(/hz37Ps\.push/.test(fnText(as, "hz37RememberPreset").body),
	"1: a name that was not on the last scan is appended, not waiting for the roundtrip");
expect(/local != null/.test(fnText(as, "hz37ParseState").body),
	"1: a stale scan that is missing the new file keeps the local row so the dropdown does not drop it");
expect(/r\.t == "p"/.test(fnText(as, "hz51DropOpts").body) && /hz51PresetNames/.test(fnText(as, "hz51DropOpts").body),
	"1: an already-built / already-open dropdown reads hz37Ps live, not a cached opts array");
expect(/hz37Sel/.test(fnText(as, "hz51OpenDrop").body) && /r\.t == "p"/.test(fnText(as, "hz51OpenDrop").body),
	"1: opening the pill after SAVE highlights the new selection");

function parseState(s, keepId, prior) {
	const lines = String(s).replace(/\r/g, "").split("\n");
	const ps = [];
	for (let i = 1; i < lines.length; i++) {
		const p = String(lines[i]).split("|");
		if (p.length >= 6 && String(p[0]).length > 2 && String(p[2]).length > 0) {
			ps.push({ id: String(p[0]), u: String(p[1]) == "1", n: String(p[2]) });
		}
	}
	let local = null;
	if (prior && prior.ps) {
		for (const row of prior.ps) {
			if (String(row.id).toLowerCase() == String(keepId).toLowerCase() && row.u) { local = row; break; }
		}
	}
	let sel = 0, found = false;
	for (let i = 0; i < ps.length; i++) {
		if (String(ps[i].id).toLowerCase() == String(keepId).toLowerCase()) { sel = i; found = true; }
	}
	if (!found && local && String(keepId).length > 2) { ps.push(local); sel = ps.length - 1; }
	return { ps, sel, names: ps.map((p) => p.n), selId: ps.length ? ps[sel].id : "" };
}
function remember(hud, id, nm) {
	const ps = hud.ps.map((p) => Object.assign({}, p));
	const i = ps.findIndex((p) => String(p.id).toLowerCase() == id.toLowerCase());
	if (i >= 0) { ps[i].n = nm; ps[i].u = true; return { ps, sel: i, names: ps.map((p) => p.n), selId: id }; }
	ps.push({ id, u: true, n: nm });
	return { ps, sel: ps.length - 1, names: ps.map((p) => p.n), selId: id };
}
const openScan =
	"v=0.43.5.0|bak=1|undo=0|user=1|def=1|skip=0|last=\n" +
	"s:shipped.ini|0|Default|Horizon|0.43.5.0|Built-in\n" +
	"u:last_session.ini|1|Last Session|Player|0.43.5.0|Saved in game";
const afterWrite =
	"v=0.43.5.0|bak=1|undo=0|user=1|def=1|skip=0|last=\n" +
	"s:shipped.ini|0|Default|Horizon|0.43.5.0|Built-in\n" +
	"u:last_session.ini|1|Last Session|Player|0.43.5.0|Saved in game\n" +
	"u:night_ops.ini|1|Night Ops|Player|0.43.5.0|Saved in game";

let hud = parseState(openScan, "u:last_session.ini");
expect(hud.names.indexOf("Last Session") >= 0 && hud.names.indexOf("Night Ops") < 0,
	"1: open scan (last session) fills the dropdown before SAVE");
hud = remember(hud, "u:night_ops.ini", "Night Ops");
expect(hud.names.indexOf("Night Ops") >= 0 && hud.ps[hud.sel].n == "Night Ops",
	"1: SAVE click inserts Night Ops into hz37Ps while F11 is still open");
const namesAfterSave = hud.names.slice();
expect(namesAfterSave.indexOf("Night Ops") >= 0,
	"1: hz51PresetNames would list Night Ops on the next draw, before the DLL reply");
const after = parseState(afterWrite, "u:night_ops.ini", hud);
expect(after.names.indexOf("Night Ops") >= 0 && after.ps[after.sel].n == "Night Ops",
	"1: the post-write scan pushed to the movie keeps Night Ops selected");
const stale = parseState(openScan, "u:night_ops.ini", hud);
expect(stale.names.indexOf("Night Ops") >= 0,
	"1: if a rescan runs before the write is visible, the local SAVE row is kept");

const savePreset = cpp.slice(cpp.indexOf("inline Result SavePreset"), cpp.indexOf("inline Result HidePreset"));
expect(/userPresets/.test(savePreset) && /WriteAtomic\(file, text\)/.test(savePreset),
	"1: SAVE writes Data/Interface/HorizonUI/presets/user/<slug>.ini through WriteAtomic");

// ---- 2. Per-setting Live Preview ----
const kind = fnText(as, "hz51PvKind").body;
const paint = fnText(as, "hz51PvPaint").body;
expect(/hz51PvKind/.test(paint) && /kind == "planet"/.test(paint) && /kind == "character"/.test(paint),
	"2: Live Preview dispatches on the selected row, not the page group");
expect(/hzPpDrawIcon/.test(fnText(as, "hz51PvPlanet").body),
	"2: planet rows reuse the live planet-card disc renderer");
expect(/hz26Name/.test(fnText(as, "hz51PvCharacter").body) && /LV /.test(fnText(as, "hz51PvCharacter").body),
	"2: character rows reuse the live character name / LV / XP card");
expect(/SpeakerCard/.test(fnText(as, "hz51PvSubtitle").body) && /ANDREJA/.test(fnText(as, "hz51PvSubtitle").body),
	"2: Speaker name on vs off and Speaker card on vs off change the mini subtitle");
expect(/hz51PvText/.test(paint) && /hz51HelpOf/.test(fnText(as, "hz51PvText").body),
	"2: a setting with no HUD picture shows its Setting Details text, not a generic card");
expect(!/ENTER_FRAME/.test(paint) && !/setInterval/.test(paint) && !/addEventListener/.test(paint),
	"2: Live Preview has no per-frame work");
expect(/hzSetPend/.test(paint) || /hzSetPend/.test(fnText(as, "hz51PvPlanet").body),
	"2: CANCEL reverts because paint reads pending values");
expect(/hzSetPv\.visible = false/.test(fnText(as, "hz51Draw").body),
	"2: the old 226x300 planet clone stays hidden (mini is drawn in the preview box)");
expect(!/hzSetPvDraw/.test(fnText(as, "hz51DrawRight").body),
	"2: Setting Details does not parent the overflowing old preview");

function pvKind(k) {
	if (!k) return "text";
	if (k.indexOf("_goto") == 0 || k == "_arrange" || k == "_empty" || k == "_diagoff" || k == "_dirinst" || k == "_cmpok" || k.indexOf("_own") == 0 || k.indexOf("_hz31") == 0 || k.indexOf("_modban") == 0) return "text";
	if (k.indexOf("_hz37") == 0) return (k == "_hz37pick" || k == "_hz37save") ? "preset" : "text";
	if (k.indexOf("_mod_") == 0) return "module";
	if (k.indexOf("_ml") == 0 || k == "_msglog" || k == "Record" || k == "Persist" || k == "HistorySize" || k == "SettingsKey" || k == "Language" || k == "_l10nGame" || k == "StartupIntro" || k == "Debug" || k.indexOf("Perf") == 0) return "text";
	if (k.indexOf("_hz40") == 0 || k.indexOf("_hz41") == 0 || k == "_hz42scrst" || k == "_qmclear" || k == "_qmkeys") return "text";
	if (k == "SubAutoPause" || k == "DlgAutoPause" || k == "DlgInputDelay" || k == "DlgRolloverSound" || k == "DlgMarkers" || k == "MissionToastSound" || k == "DlgHoverScroll" || k == "DlgWheel" || k == "DlgNumberKeys" || k == "DlgSelectHint" || k == "DlgQuickPickHint") return "text";
	if (k == "ShowPlanet" || k.indexOf("Planet") == 0 || k == "HazardAlert" || k == "TimeDisplay" || k == "ClockFormat" || k == "TempUnit") return "planet";
	if (k == "ShowCharacter" || k.indexOf("Character") == 0) return "character";
	if (k.indexOf("Watch") == 0) return "watch";
	if (k == "ShowVitals" || k.indexOf("Vitals") == 0 || k == "AutoCenterVitals" || k == "RegenSliver" || k == "SmoothBars" || k == "EdgePulse") return "vitals";
	if (k == "ShowJetpack" || k.indexOf("Jetpack") == 0) return "jetpack";
	if (k == "ShowAfflictions" || k.indexOf("Afflict") == 0) return "affliction";
	if (k.indexOf("Hazard") == 0) return "hazard";
	if (k == "ShowAmmo" || k.indexOf("Equipment") == 0 || k == "AmmoRule" || k == "EquipmentExtras") return "equipment";
	if (k.indexOf("Enemy") == 0) return "enemy";
	if (k.indexOf("Stealth") == 0) return "stealth";
	if (k.indexOf("Crosshair") == 0 || k == "HitMarkers" || k == "DamageNumbers" || k == "DirectionRing" || k.indexOf("Scope") == 0) return "crosshair";
	if (k == "ShowCompass" || k.indexOf("Compass") == 0 || k == "CompassMarkers" || k == "ShowFollowers" || k == "FollowerColor" || k == "ShowLocations" || k == "ShowShip" || k == "ShowEnemies" || k == "ShowPlayerMarker") return "compass";
	if (k == "ShowQuests" || k.indexOf("Quests") == 0) return "quests";
	if (k == "ShowTarget" || k == "NameHover" || k == "HoverScale" || k == "TargetAnchor" || k == "TargetShowValue" || k == "ContainerScale" || k == "ContainerOpacity" || k == "ObjectRing") return "target";
	if (k == "VehicleExitPill") return "vehicle";
	if (k.indexOf("QuickMenu") == 0) return "qm";
	if (k.indexOf("XpToast") == 0) return "xp";
	if (k.indexOf("MissionToast") == 0 || k == "ReactionCard" || k == "GameCardTitle") return "toast";
	if (k == "ShowSpeaker" || k == "SpeakerCard" || k == "SpkColIdx") return "speaker";
	if (k == "Subtitles" || k.indexOf("Sub") == 0 || k == "TxtColIdx" || k == "KeepInDialogue" || k == "FixedInDialogue") return "subtitle";
	if (k == "Dialogue" || k.indexOf("Dlg") == 0) return "dialogue";
	if (k.indexOf("Scan") == 0 || (k.indexOf("Hide") == 0 && k.indexOf("Scan") > 0) || k == "DimTraitPopupDuringBioscan" || k == "TraitPopupDim" || k == "HideQuestPopupsWhileScanning" || k == "HideMainHudWhileScanning" || k == "HideWatchWhileScanning") return "scanner";
	if (k == "AccentColor" || k == "AccentHex" || k == "CardColor" || k == "CardHex" || k == "CardOpacity" || k == "CardBgOpacity" || k == "CardShadow" || k == "FontFace" || k == "TextScale" || k == "TextTone" || k == "HeaderStyle" || k == "TextShadow" || k == "HudScale" || k == "Margin" || k == "ScreenHeight" || k == "FadeCards" || k == "CombatDim" || k == "DimOpacity" || k == "SettingsOpacity" || k == "CompactScale" || k == "Compact") return "theme";
	return "card";
}
const spots = [
	["ShowPlanet", "planet"], ["ShowCharacter", "character"], ["ShowSpeaker", "speaker"],
	["SpeakerCard", "speaker"], ["Subtitles", "subtitle"], ["Dialogue", "dialogue"],
	["AfflictionLayout", "affliction"], ["CrosshairStyle", "crosshair"], ["SettingsKey", "text"],
	["Language", "text"], ["_l10nGame", "text"],
	["Record", "text"], ["_hz37apply", "text"], ["_hz37pick", "preset"], ["AccentColor", "theme"],
	["ScanShowSignals", "scanner"], ["QuickMenuHorizon", "qm"], ["WatchStyle", "watch"]
];
for (const [k, want] of spots) {
	expect(pvKind(k) === want, "2: " + k + " preview kind is " + want);
	if (want === "text") {
		const needle = k.indexOf("_hz37") == 0 ? "_hz37" : k;
		expect(kind.indexOf('"' + needle + '"') >= 0 || kind.indexOf(needle) >= 0, "2: hz51PvKind lists " + k);
	}
}

expect(!/ENTER_FRAME/.test(insert) && !/setInterval/.test(draw),
	"section 13: insert/draw add no per-frame timers");
expect(/hzSetIsOpen/.test(fnText(as, "hzSetFileState").body),
	"section 13: preset push still runs only while F11 is open");
expect(!/addEventListener\(\s*"enterFrame"/i.test(as),
	"section 13: HUD adds no ENTER_FRAME listener");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log("\n" + passed + " passed");
