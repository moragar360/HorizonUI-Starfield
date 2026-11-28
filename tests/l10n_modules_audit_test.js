// Purpose: Comms, Dialogue, Scanner, and Message Log Horizon chrome goes
// through hzL/hzLt (or the module *Lt) at build / language change only.
// Game dialogue lines, NPC names, and $ scanner tokens stay native.
// Run from the repo root: node tests/l10n_modules_audit_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const { fnText } = require("./lib/r3.js");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

function rd(rel) {
	return fs.readFileSync(path.join(root, rel), "utf8").replace(/\r\n/g, "\n");
}

const hzc = rd("actionscript/comms/hzc_block.as");
const hzd = rd("actionscript/comms/hzd_block.as");
const hzs = rd("actionscript/scanner/hzs_block.as");
const hud = rd("actionscript/horizon_block.as");
const cpp = rd("src/main.cpp");

expect(/function hzcSetL10n/.test(hzc) && /function hzcLt\(/.test(hzc), "HUDMessagesMenu has hzcSetL10n / hzcLt");
expect(/function hzdSetL10n/.test(hzd) && /function hzdLt\(/.test(hzd), "DialogueMenu has hzdSetL10n / hzdLt");
expect(/function hzsSetL10n/.test(hzs) && /function hzsLt\(/.test(hzs), "MonocleMenu has hzsSetL10n / hzsLt");
expect(/private var hzsL:Sprite/.test(hzs) && /function hzsLk\(/.test(hzs) && !/function hzsL\(/.test(hzs),
	"scanner lookup is hzsLk; hzsL stays the layer Sprite (same-name ABC CTDs on open)");

expect(hzc.indexOf('this.hzcLt("SPEAKING")') >= 0, "speaker card SPEAKING is Horizon chrome through hzcLt");
expect(hzc.indexOf('this.hzcLt(String(HZC_TST_HEAD[st]))') >= 0, "mission toast heads go through hzcLt at toast build");
expect(hzc.indexOf('this.hzcLt(String(HZC_RX_LBL[k]))') >= 0 || hzc.indexOf('this.hzcLt(String(HZC_RX_LBL[e.k]))') >= 0,
	"reaction labels go through hzcLt at card draw");
expect(hzc.indexOf('who.toUpperCase()') >= 0 && !/hzcLt\(who/.test(hzc),
	"speaker names stay native (uppercased, not looked up)");
expect(hzc.indexOf("CurrentSubtitleData") >= 0, "subtitle body still comes from game CurrentSubtitleData");

expect(hzd.indexOf('this.hzdLt("RESPOND")') >= 0, "RESPOND fallback is Horizon chrome through hzdLt");
expect(hzd.indexOf('this.hzdLt("PERSUADE")') >= 0 && hzd.indexOf('this.hzdLt("SAID")') >= 0,
	"PERSUADE / SAID chips go through hzdLt");
expect(hzd.indexOf('this.hzdLt("QUICK PICK")') >= 0 && hzd.indexOf('this.hzdLt("SPEAKING")') >= 0,
	"QUICK PICK / SPEAKING go through hzdLt");
expect(hzd.indexOf("sChoiceText") >= 0 && !/hzdLt\(label/.test(hzd) && !/hzdLt\(.*sChoiceText/.test(hzd),
	"dialogue option lines stay native (sChoiceText, not hzdLt)");
expect(/w\.toUpperCase\(\)/.test(hzd) && !/hzdLt\(w\)/.test(hzd),
	"NPC speaker names stay native");

expect(/var loc:String = \(s == null \|\| s.length < 2\) \? String\(s\) : this.hzsLt\(s\)/.test(hzs),
	"hzsCs looks up Horizon chrome once (memo) then cases it");
expect(hzs.indexOf("function hzsTr") >= 0 && hzs.indexOf("GlobalFunc.SetText") >= 0,
	"scanner still resolves $ keys through hzsTr / the game table");
expect(hzs.indexOf("function hzsGs") >= 0, "game marker names still go through hzsGs, not hzsLt");
expect(hzs.indexOf('this.hzsCs("Landing zone")') >= 0 && hzs.indexOf('this.hzsCs("Companion")') >= 0,
	"scanner Horizon subs (Landing zone / Companion) go through hzsCs");

const tick = fnText(hzs, "hzsTick");
expect(tick && tick.body.indexOf("hzsLt(") < 0 && tick.body.indexOf("hzsLk(") < 0,
	"hzsTick does not call hzsLk/hzsLt directly (memo lives in hzsCs)");
const toast = fnText(hzc, "hzcToastFrame");
expect(toast && toast.body.indexOf("hzcLt(") < 0 && toast.body.indexOf("hzcL(") < 0,
	"toast ENTER_FRAME does not look up strings");
const rxFrame = fnText(hzc, "hzcRxFrame");
expect(rxFrame && rxFrame.body.indexOf("hzcLt(") < 0,
	"reaction ENTER_FRAME does not look up strings");

expect(hud.indexOf('this.hzLt("HORIZON UI · MESSAGE LOG")') >= 0, "message log title goes through hzLt");
expect(hud.indexOf("this.hzLt(String(HZ_ML_CHIPS[i]))") >= 0, "message log chips go through hzLt");
expect(hud.indexOf('this.hzLt("ALL TIME")') >= 0 && hud.indexOf('this.hzLt("MESSAGE LOG SETTINGS")') >= 0,
	"message log ALL TIME / settings header go through hzLt");
expect(/hzMsglogKindLab/.test(hud) && hud.indexOf("sel.title") >= 0,
	"message bodies / titles stay the stored log text, not re-slugged");

expect(/PushL10nModules/.test(cpp) && /hzcSetL10n/.test(cpp) && /hzdSetL10n/.test(cpp) && /hzsSetL10n/.test(cpp),
	"DLL pushes hzc/hzd/hzs SetL10n on language apply");
expect(/PushL10nForMenu/.test(cpp), "DLL pushes module l10n when Dialogue / Scanner / HUDMessages open");
expect(!/new Timer/.test(cpp.match(/void PushL10nModules[\s\S]*?\n\t\}/)[0]),
	"PushL10nModules has no timer");

const hosts = [
	["actionscript/imp/imp/scripts/HUDMessagesMenu.as", hzc, "__HZC_LRG__", "false"],
	["actionscript/imp/imp-Lrg/scripts/HUDMessagesMenu.as", hzc, "__HZC_LRG__", "true"],
	["actionscript/imp/dimp/scripts/DialogueMenu.as", hzd, "__HZD_LRG__", "false"],
	["actionscript/imp/dimp-Lrg/scripts/DialogueMenu.as", hzd, "__HZD_LRG__", "true"],
	["actionscript/imp/simp_monoclemenu/MonocleMenu.as", hzs, "__HZS_LRG__", "false"],
	["actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as", hzs, "__HZS_LRG__", "true"]
];
for (const [rel, blk, tok, val] of hosts) {
	const host = rd(rel);
	const want = blk.replace(tok, val).replace(/\s+$/, "");
	expect(host.indexOf(want) >= 0, path.basename(path.dirname(rel)) + "/" + path.basename(rel) + " carries the block unchanged");
}

function flatten(obj, prefix, out) {
	if (obj == null || typeof obj !== "object" || Array.isArray(obj)) {
		if (prefix) out[prefix] = obj;
		return;
	}
	for (const k of Object.keys(obj)) {
		if (k === "_meta" || k === "_comment") continue;
		flatten(obj[k], prefix ? prefix + "." + k : k, out);
	}
}
const loc = path.join(root, "Data", "SFSE", "Plugins", "HorizonUI", "Localization");
const need = [
	"comms.hud_label.speaking",
	"comms.hud_label.loved_that",
	"comms.hud_label.mission_updated",
	"dlg.hud_label.said",
	"dlg.hud_label.persuade",
	"dlg.hud_label.respond",
	"dlg.hud_label.of",
	"scan.hud_label.unknown_signal",
	"scan.hud_label.landing_zone",
	"settings.ui.horizon_ui_message_log",
	"hud.hud_label.all_time",
	"settings.ui.all"
];
for (const code of ["en", "de", "es", "es-mx", "zh-cn", "fr"]) {
	const j = JSON.parse(fs.readFileSync(path.join(loc, code + ".json"), "utf8"));
	const flat = {};
	flatten(j, "", flat);
	for (const k of need) {
		expect(flat[k] != null && String(flat[k]).length > 0, code + ".json has " + k);
	}
}

console.log("l10n_modules_audit_test: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
