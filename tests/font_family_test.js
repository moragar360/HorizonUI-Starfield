// Purpose: F11 STYLE Font family picker. FontFace 0/1/2/3 stay; [Style] Font=
// picks Exo2 / Saira / Orbitron / Titillium when FontFace is 1. Aliases are
// fontconfig maps, not a second SWF load. Pins section 13 (no new poll / timer /
// UI-thread font I/O). Run: node tests/font_family_test.js
// Author: Moragar. Last modified: 2026-11-28.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function rd(rel) {
	return fs.readFileSync(path.join(root, rel), "utf8").replace(/\r\n/g, "\n");
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

const as = rd("actionscript/horizon_block.as");
const insert = rd("actionscript/hz51_insert.as");
const draw = rd("actionscript/hz51_draw.as");
const ini = rd("Interface/HorizonUI/HorizonUI.default.ini");
const hzc = rd("actionscript/comms/hzc_block.as");
const hzd = rd("actionscript/comms/hzd_block.as");
const hzs = rd("actionscript/scanner/hzs_block.as");
const hzq = rd("actionscript/favorites/hzq_main.as");
const fomod = rd("fomod/ModuleConfig.xml");
const cfg = rd("Interface/HorizonUI/fonts/fontconfig_horizon_families.txt");
const en = JSON.parse(rd("Data/SFSE/Plugins/HorizonUI/Localization/en.json"));

expect(/HZ_FONT_FAM_IDS:Array = \["Exo2","Saira","Orbitron","Titillium"\]/.test(as),
	"Font family ids are Exo2 / Saira / Orbitron / Titillium");
expect(/HZ_FONT_FAM_NAMES:Array = \["EXO 2","SAIRA","ORBITRON","TITILLIUM WEB"\]/.test(as),
	"Font family labels keep the SIL names");
expect(/HZ_FONT_IDS:Array = \[1,2,0,3\]/.test(as),
	"FontFace 0/1/2/3 stay (game / Horizon family / Roboto / game semibold)");
expect(/public var hzFontFam:String = "Exo2"/.test(as), "HUD default family is Exo2");
expect(/Font=Exo2/.test(ini), "default.ini [Style] Font=Exo2");
expect(/"k":"Font","l":"FONT FAMILY","t":"l","vals":HZ_FONT_FAM_IDS/.test(insert)
	&& /"k":"Font","l":"FONT FAMILY","t":"l","vals":HZ_FONT_FAM_IDS/.test(as),
	"F11 STYLE has FONT FAMILY after FONT, spliced into the HUD");

const fam = fnText(as, "hzFontFamNorm").body;
expect(/saira/.test(fam) && /orbitron/.test(fam) && /titillium/.test(fam) && /return "Exo2"/.test(fam),
	"unknown Font= tokens keep Exo 2");
const base = fnText(as, "hzFontHorizonBase").body;
expect(/\$Horizon_Font_Saira/.test(base) && /\$Horizon_Font_Orbitron/.test(base)
	&& /\$Horizon_Font_Titillium/.test(base) && /return "\$Horizon_Font"/.test(base),
	"FontFace 1 aliases are $Horizon_Font plus Saira / Orbitron / Titillium");
const name = fnText(as, "hzFontName").body;
expect(/hzFontHorizonBase/.test(name) && /base != "\$Horizon_Font" && this\.hzFontProbe\("\$Horizon_Font"\)/.test(name),
	"a missing family falls back to Exo 2 then the game font");
expect(/hzFontFace == 3/.test(name) && /hzFontFace != 1 && this\.hzFontFace != 2/.test(name),
	"FontFace 0/2/3 do not use Font=");

const rows = fnText(as, "hz30FontRows").body;
expect(/r0\.k == "Font"/.test(rows) && /!pack \|\| fv != 1/.test(rows),
	"FONT FAMILY is disabled unless the pack is present and FontFace is 1");
expect(/hzFontCovered\(id\)/.test(rows) && /r0\.vals = ids/.test(rows),
	"FONT FAMILY hides families the active language cannot cover");
expect(/Not available for this language/.test(rows) && !/SetPend\.Font\s*=/.test(rows),
	"an uncovered Font= keeps the INI value and shows a short note");
expect(/function hzFontFamLive/.test(as) && /return "Exo2"/.test(fnText(as, "hzFontFamLive").body),
	"uncovered Font= renders with Exo 2");
expect(/function hzFontText/.test(as) && /hzFontFamLive\(\) != "Orbitron"/.test(fnText(as, "hzFontText").body),
	"punctuation substitution runs only when Orbitron is the live family");
expect(/t\.text = this\.hzFontText\(txt\)/.test(fnText(as, "hzT").body)
	&& /full = this\.hzFontText\(full\)/.test(fnText(as, "hzFitText").body)
	&& /t\.text = this\.hzFontText\(txt\)/.test(fnText(as, "hzWT").body),
	"Orbitron substitution is at set-text time (hzT / hzWT / hzFitText)");
expect(/hzCmpCenter\.text = HZ_CARD\[idx\] \+ " " \+ this\.hzMid/.test(as),
	"compass ticks use a cached hzMid, not hzFontText");
{
	const i = as.indexOf("this.hzCmpCenter.text = HZ_CARD");
	expect(i >= 0 && as.slice(i, i + 160).indexOf("hzFontText") < 0,
		"compass heading assign does not walk the string");
}
expect(/private var hzMid:String/.test(as) && /private function hzDot\(d:Sprite, col:uint\)/.test(as),
	"middot cache is hzMid; status-dot painter stays hzDot");
expect(!/this\.hzDot\s*=/.test(as), "painter slot is never assigned a string");
expect(/function hzFontApply/.test(as) && /hzFontApply\(\)/.test(fnText(insert, "hzSetL10n").body),
	"language apply refreshes the live family and hzMid once");
expect(/HZ_FONT_COVER:Object/.test(as) && /HZ_ORB_FROM:Array/.test(as),
	"HUD carries the generated coverage table");
expect(/function hzcFontFamLive/.test(hzc) && /function hzdFontFamLive/.test(hzd)
	&& /function hzsFontFamLive/.test(hzs) && /function hzqFontFamLive/.test(hzq),
	"modules live-resolve Font= from the same table");
expect(/k == "used"/.test(fnText(hzc, "hzcSetL10n").body) && /k == "used"/.test(fnText(hzd, "hzdSetL10n").body),
	"comms and dialogue store used so coverage can hide Orbitron for Polish");

expect(/case "font": this\.hzFontFam = this\.hzFontFamNorm\(v\); this\.hzFontApply\(\); break;/.test(as),
	"INI reader stores Font=");
expect(/"Font":this\.hzFontFam/.test(fnText(as, "hzSetCurrent").body),
	"OK writes Font from hzFontFam");
expect(/p\.Font != undefined/.test(fnText(as, "hzSetLive").body),
	"live apply stores Font (no file I/O)");
expect(/Font=" \+ this\.hzFontFamNorm/.test(fnText(as, "hzBuildIniText").body),
	"F11 save writes Font=");
expect(/"Font":"Exo2"/.test(as), "HZ_SET_DEF Font=Exo2");

expect(/String\(r\.k\) == "Font"/.test(fnText(insert, "hz51LocOne").body),
	"FONT FAMILY option names stay Exo 2 / Saira / Orbitron / Titillium Web (not slugged)");
expect(/case "Font": return "Horizon font family when FONT is Exo 2/.test(fnText(insert, "hz51Help").body),
	"Setting Details for Font exist");
expect(/k == "FontFace" \|\| k == "Font" \|\| k == "TextScale"/.test(fnText(draw, "hz51PvKind").body),
	"Font family is a theme / typography live preview");

expect(/function hzcFontHorizonBase/.test(hzc) && /HZC_STR[\s\S]*"Font":1/.test(hzc),
	"comms reads [Style] Font=");
expect(/function hzdFontHorizonBase/.test(hzd) && /HZD_STR[\s\S]*"Font":1/.test(hzd),
	"dialogue reads [Style] Font=");
expect(/function hzsFontHorizonBase/.test(hzs) && /k == "font"/.test(hzs),
	"scanner reads [Style] Font=");
expect(/function hzqFontHorizonBase/.test(hzq) && /k == "font"/.test(hzq),
	"quick menu reads [Style] Font=");

const hosts = [
	["actionscript/imp/imp/scripts/HUDMessagesMenu.as", "hzcFontHorizonBase"],
	["actionscript/imp/imp-Lrg/scripts/HUDMessagesMenu.as", "hzcFontHorizonBase"],
	["actionscript/imp/dimp/scripts/DialogueMenu.as", "hzdFontHorizonBase"],
	["actionscript/imp/dimp-Lrg/scripts/DialogueMenu.as", "hzdFontHorizonBase"],
	["actionscript/imp/simp_monoclemenu/MonocleMenu.as", "hzsFontHorizonBase"],
	["actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as", "hzsFontHorizonBase"],
	["actionscript/favorites/imp/pimp_favoritesmenu/FavoritesMenu.as", "hzqFontHorizonBase"],
	["actionscript/favorites/imp/pimp_favoritesmenu_lrg/FavoritesMenu.as", "hzqFontHorizonBase"]
];
for (const [rel, fn] of hosts) {
	expect(rd(rel).indexOf("function " + fn) >= 0, path.basename(path.dirname(rel)) + "/" + path.basename(rel) + " carries " + fn);
}

expect(/\$Horizon_Font_Saira/.test(cfg) && /\$Horizon_Font_Orbitron/.test(cfg)
	&& /\$Horizon_Font_Titillium/.test(cfg),
	"pack-time fontconfig maps the extra family aliases");
expect(/Do not load extra/.test(cfg) && /FontLibs at runtime/.test(cfg),
	"fontconfig note: no runtime FontLib load");
expect(/Saira, Orbitron, and Titillium Web/.test(fomod),
	"FOMOD Font plugin lists Saira / Orbitron / Titillium Web");

const ofl = [
	"Interface/HorizonUI/fonts/exo2/OFL.txt",
	"Interface/HorizonUI/fonts/saira/OFL.txt",
	"Interface/HorizonUI/fonts/orbitron/OFL.txt",
	"Interface/HorizonUI/fonts/titilliumweb/OFL.txt"
];
for (const rel of ofl) {
	expect(fs.existsSync(path.join(root, rel)), rel + " is the SIL OFL");
}
expect(fs.existsSync(path.join(root, "Interface/HorizonUI/fonts/saira/Saira-Variable.ttf")),
	"Saira TTF is bundled");
expect(fs.existsSync(path.join(root, "Interface/HorizonUI/fonts/orbitron/Orbitron-Variable.ttf")),
	"Orbitron TTF is bundled");
expect(fs.existsSync(path.join(root, "Interface/HorizonUI/fonts/titilliumweb/TitilliumWeb-Regular.ttf")),
	"Titillium Web Regular TTF is bundled");
expect(fs.existsSync(path.join(root, "Interface/HorizonUI/fonts/exo2/Exo2-Variable.ttf")),
	"Exo 2 TTF is bundled");

expect(en.settings && en.settings.ui && en.settings.ui.font_family === "FONT FAMILY",
	"en.json has settings.ui.font_family");
expect(en.settings.ui.not_available_for_this_language === "Not available for this language.",
	"en.json has the uncovered-family note");
expect(en.settings.details.Font && en.settings.line.Font,
	"en.json has settings.details.Font and settings.line.Font");

const pick = fnText(as, "hzFontHorizonBase").body + fnText(as, "hzFontFamNorm").body
	+ fnText(as, "hzFontFamLive").body + fnText(as, "hzFontCovered").body
	+ fnText(as, "hzFontText").body + fnText(as, "hzFontApply").body
	+ fnText(as, "hzSetLive").body + fnText(as, "hz30FontRows").body;
expect(!/new Timer/.test(pick) && !/setInterval/.test(pick) && !/URLLoader/.test(pick)
	&& !/addEventListener/.test(pick) && !/ENTER_FRAME/.test(pick),
	"section 13: Font= switch is an alias, not a new timer or FontLib load");
expect(!/parseCmap|readUInt16BE|readFile/.test(pick),
	"section 13: coverage is a const table, no UI-thread font I/O");
expect(/hzFrameN % 300 == 150/.test(as) && /hzFontRetry < 6/.test(as),
	"section 13: late font registration still uses the existing 6-try probe, no extra timer");
expect(!/ENTER_FRAME/.test(insert) && !/setInterval/.test(draw) && !/new Timer/.test(insert),
	"section 13: insert/draw add no per-frame timers for the Font row");
expect(/o\.twFam === this\.hzFontFam/.test(fnText(as, "hzTW").body),
	"section 13: hzTW cache misses when Font= changes (no per-tick remap)");
expect(/this\.hzFontFam !== this\.hzQsFam/.test(fnText(as, "hzQsSame").body),
	"section 13: quest change-only misses when Font= changes");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log("\n" + passed + " passed");
