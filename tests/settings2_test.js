// Settings 2.0 F11 rebuild. Run: node tests/settings2_test.js
// Pins the five-tab IA, grouped sidebar, Diagnostics player help (from live overlay /
// timing / dump paths), header compact + search, and live apply of Debug / Perf*.
// Author: Moragar. Last modified: 2026-11-26.
"use strict";
const fs = require("fs");
const path = require("path");
const as = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

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

expect(/HZ_SET_TABS:Array = \["CARDS","APPEARANCE","SCANNER","COMMS","SYSTEM"\]/.test(as), "five tabs: CARDS APPEARANCE SCANNER COMMS SYSTEM");
expect(/HZ_SET_W:Number = 1000/.test(as), "window width stays 1000");
expect(/function hzSetDraw\(\) : void\s*\{\s*this\.hz51Draw\(\);\s*\}/.test(as), "hzSetDraw is the Settings 2.0 shell");
expect(/function hzSetRows\(tab:int\) : Array\s*\{\s*this\.hzSetPage = this\.hz51PageClamp\(tab\);\s*return this\.hz51Rows\(tab, this\.hzSetPage\);\s*\}/.test(as), "hzSetRows dispatches to the new catalog");

const finish = fnText(as, "hz51Finish").body;
expect(!/COMPACT MODE \(STRIPS\)/.test(finish) && /header, not as a list row/.test(finish), "Compact Mode is header-only, not a list pill");
expect(/r\.note = this\.hz51Line/.test(finish) && /r\.inote = help/.test(finish), "every row keeps a help line and Setting Details");

const side = fnText(as, "hz51Side").body;
expect(/HUD CARDS/.test(side) && /MENUS & ALERTS/.test(side) && /QUICK MENU \/ FAVORITES MENU/.test(side), "CARDS uses the grouped sidebar");
expect(/NOTIFICATIONS/.test(side) && /XP toast/.test(side), "Notifications is XP toast only");
expect(/DIAGNOSTICS/.test(side) && /Debug overlay/.test(side), "SYSTEM sidebar has Diagnostics");

const line = fnText(as, "hz51Line").body;
expect(line.indexOf("Shows extra on-screen info about the scanner and compass to help track down a problem.") >= 0, "Debug Overlay help line: what it does, what you see, when");
expect(line.indexOf("Measures how long the HUD takes to update and saves it so a problem can be found.") >= 0, "Advanced Performance Timing help line");
expect(line.indexOf("Switches which HUD test runs. Ordinary play uses Baseline.") >= 0, "Perf Mode help line");
expect(line.indexOf("Saves one performance report the next time you apply settings.") >= 0, "Arm Perf Dump help line");
expect(!/\bini\b/i.test(line) && !/g_ini/i.test(line) && !/LoadIni/.test(line), "help lines have no ini keys or native jargon");

const help = fnText(as, "hz51Help").body;
expect(help.indexOf("Shows extra yellow text on the HUD about the crosshair") >= 0 && help.indexOf("Compass icons also get small numbers") >= 0, "Debug Overlay details match the live overlay");
expect(help.indexOf("You will not see a new panel on screen") >= 0, "Advanced Performance Timing details: timings are stored, not a new panel");
expect(help.indexOf("Baseline is ordinary play") >= 0 && help.indexOf("Hover Skip") >= 0, "Perf Mode details name Baseline and the other tests");
expect(help.indexOf("Nothing is saved until you apply settings") >= 0 && help.indexOf("Needs Advanced Performance Timing") >= 0, "Arm Perf Dump details: apply to save, needs timing on");
expect(!/\bini\b/i.test(help) && !/g_iniDebug/.test(help) && !/LoadIni/.test(help) && !/hzPerfOn/.test(help), "Setting Details have no ini keys or developer jargon");

const sys = fnText(as, "hz51System").body;
expect(/DEBUG OVERLAY/.test(sys) && /ADVANCED PERFORMANCE TIMING/.test(sys) && /PERF MODE/.test(sys) && /ARM PERF DUMP/.test(sys), "System > Diagnostics lists all four options");
expect(/LEAVE THESE OFF/.test(sys), "Diagnostics keeps the leave-these-off note");

const live = fnText(as, "hzSetLive").body;
expect(/p\.Debug != undefined/.test(live) && /hzDbgShow\(\)/.test(live), "Debug Overlay applies live (yellow overlay) without waiting for a restart");
expect(/p\.PerfDiag/.test(live) && /hzPerfApply\(\)/.test(live), "Advanced Performance Timing / Perf Mode / Arm Perf Dump apply through hzPerfApply");
expect(/p\.CharacterShowSeconds/.test(fnText(as, "hz27SetLive").body), "Show for (seconds) is live");

const cur = fnText(as, "hzSetCurrent").body;
expect(/cur\.Debug = this\.hzDebug/.test(cur) && /cur\.PerfDump = this\.hzPerfDumpIni/.test(cur), "OK writes Diagnostics so native dump can arm on apply");

const open = fnText(as, "hzToggleSettings").body;
expect(/hz51IndexBuild/.test(open), "search index is built when F11 opens");
const close = fnText(as, "hzSetClose").body;
expect(/hzSetIdx = null/.test(close), "search index is dropped when F11 closes");
expect(/hz51Key/.test(fnText(as, "hzSettingsKey").body), "slash search is handled only while the window is open");

const draw = fnText(as, "hz51Draw").body;
expect(/hz51DrawHead/.test(draw) && /hz51DrawSide/.test(draw) && /hz51DrawFooter/.test(draw) && /hz51DrawCompact/.test(fnText(as, "hz51DrawHead").body) && /hz51DrawSearchBox/.test(fnText(as, "hz51DrawHead").body), "shell draws compact, search, grouped sidebar, dual footer");
expect(/hz51DrawHead/.test(draw), "Arrange Cards sits in the header, not on System");
expect(/SETTING DETAILS/.test(fnText(as, "hz51DrawRight").body), "right column has Setting Details");
expect(/KEYBOARD/.test(fnText(as, "hz51DrawFooter").body) && /CONTROLLER/.test(fnText(as, "hz51DrawFooter").body), "dual footer hints");

const cards = fnText(as, "hz51Cards").body;
expect(/CharacterShowSeconds/.test(cards) && /SHOW FOR \(SECONDS\)/.test(cards), "Character card has Show for (seconds)");
expect(/CrosshairRule/.test(cards) && /ALWAYS/.test(cards), "Crosshair Show when default Always is in the combat page");
expect(/XpToast/.test(cards) && !/MissionToast/.test(cards), "Notifications is XP toast; Mission Toasts live on Comms");

expect(/function hz34CardRows/.test(as), "old hz34CardRows stays as the CARDS data source");
expect(/function hz40ScanRows/.test(as) && /function hz31CommsRows/.test(as) && /function hz37Rows/.test(as), "scanner, comms, and preset row builders stay");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
