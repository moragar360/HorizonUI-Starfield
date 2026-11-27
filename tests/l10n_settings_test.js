// Settings 2.0 System > Language / Localization page pins.
// Run: node tests/l10n_settings_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const as = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const insert = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const ini = fs.readFileSync(path.join(__dirname, "..", "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8");
const cpp = fs.readFileSync(path.join(__dirname, "..", "src", "main.cpp"), "utf8");

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

expect(/HZ_SET_TABS:Array = \["CARDS","APPEARANCE","SCANNER","COMMS","SYSTEM"\]/.test(as), "five tabs are unchanged");
const side = fnText(as, "hz51Side").body;
expect(/LANGUAGE \/ LOCALIZATION/.test(side), "SYSTEM sidebar has Language / Localization");
expect(/id":"loc"/.test(side) && /Detected language/.test(side), "Language page id is loc with a detected-language blurb");
expect(/CONTROLS & WINDOW/.test(side) && /DIAGNOSTICS/.test(side), "existing SYSTEM pages stay");

const sys = fnText(as, "hz51System").body;
expect(/id == "loc"/.test(sys), "hz51System builds the loc page");
expect(/_l10nGame/.test(sys) && /GAME LANGUAGE/.test(sys) && /dis":true/.test(sys.replace(/\s/g, "")), "detected language is a read-only row");
expect(/"k":"Language"/.test(sys) && /HORIZON LANGUAGE/.test(sys) && /"t":"l"/.test(sys), "override is a list dropdown bound to Language");
expect(/Auto \(game\)/.test(as) && /hz51LangOpts/.test(sys), "dropdown starts with Auto and is filled from the DLL file list");
const locZh = path.join(__dirname, "..", "Data", "SFSE", "Plugins", "HorizonUI", "Localization", "zh-cn.json");
const locDe = path.join(__dirname, "..", "Data", "SFSE", "Plugins", "HorizonUI", "Localization", "de.json");
expect(fs.existsSync(locZh), "shipped zh-cn.json is present so the Language dropdown can list it");
expect(fs.existsSync(locDe), "shipped de.json is present");
const langName = fnText(as, "hz51LangName").body;
expect(/zh-cn/.test(langName) && /zhhans/.test(langName) && /Simplified Chinese/.test(langName),
	"dropdown names zh-cn / zhhans as Simplified Chinese");
expect(/Deutsch \(German\)/.test(langName) && /es-mx/.test(langName) && /Latinoam/.test(langName) && /pt-br/.test(langName),
	"dropdown names German, Latin American Spanish, and Brazilian Portuguese");
expect(!/\bc == "ko"/.test(langName), "Korean is not a first-class Language option");
expect(/hzL10nFiles/.test(fnText(as, "hz51LangOpts").body),
	"dropdown options are the stems the DLL listed at load");
expect(/Detected at start/.test(fnText(as, "hz51Line").body), "GAME LANGUAGE row line is short enough to fit");
expect(/function hz51LocRows/.test(as) || /function hz51LocRows/.test(insert), "Settings rows are localized at catalog finish");

const help = fnText(as, "hz51Help").body;
expect(help.indexOf("Language for Horizon labels") >= 0, "Language Setting Details exist");
expect(help.indexOf("pressing OK reloads the table once") >= 0, "Language help says OK reloads once, not a restart");
expect(help.indexOf("when Horizon started") >= 0, "detected-language details say it is cached at start");
expect(!/\bini\b/i.test(fnText(as, "hz51Line").body.match(/case "Language"[\s\S]*?return "[^"]+"/) || [""])[0], "Language help line has no ini jargon");

expect(/case "language":/.test(as) && /hzLanguage/.test(as), "INI reader stores Language");
expect(/cur\.Language = this\.hzLanguage/.test(fnText(as, "hzSetCurrent").body), "OK writes Language");
expect(/p\.Language/.test(fnText(as, "hzSetLive").body), "live apply stores Language (no file I/O)");
expect(fnText(as, "hzBuildIniText").body.indexOf("[General]") >= 0 && fnText(as, "hzBuildIniText").body.indexOf("Language=") >= 0, "F11 save writes [General] Language=");

expect(/"Language":"auto"/.test(as), "HZ_SET_DEF Language=auto");
expect(/^\[General\]/m.test(ini) && /Language=auto/.test(ini), "default.ini Language=auto");
expect(/SettingsKey=F11/.test(ini) && /ShowJetpack=1/.test(ini) && /FontFace=1/.test(ini), "existing INI keys are kept");

expect(/function hzSetL10n/.test(as) && /function hzL\(/.test(as), "hzSetL10n / hzL exist");
const setL = fnText(as, "hzSetL10n").body;
expect(/hzL10nGame/.test(setL) && /hzL10nFiles/.test(setL), "one payload fills the detected language and the file list");
expect(/URLLoader/.test(setL) === false && /LoadVars/.test(setL) === false, "AS receiver does no file I/O");

expect(/L10nLoad/.test(cpp) && /PushL10n/.test(cpp), "DLL load + latched push");
expect(cpp.indexOf("void Poll()") >= 0, "Poll still exists");
function cppFn(name) {
	const i = cpp.indexOf("void " + name + "()");
	if (i < 0) return "";
	const b = cpp.indexOf("{", i);
	let d = 0;
	for (let p = b; p < cpp.length; p++) {
		if (cpp[p] === "{") d++;
		else if (cpp[p] === "}") { d--; if (d === 0) return cpp.slice(b, p + 1); }
	}
	return "";
}
const poll = cppFn("Poll");
expect(poll.indexOf("PushL10n") < 0 && poll.indexOf("Invoke") < 0, "job-thread Poll does not push l10n");
expect(cppFn("PollScaleform").indexOf("PushL10n") >= 0, "HUD AdvanceFrame pushes l10n once when ready");
expect(cppFn("BuildLogHud").indexOf("PushL10n") < 0, "l10n is not on the 5s movie-build timer");

expect(!/grey/.test(fnText(as, "hz51Help").body) || /grayed/.test(as), "American English spelling on Settings copy");

if (failed) { console.error("\n" + failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
