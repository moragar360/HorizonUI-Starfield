// Pins: HUD dynamic values are never overwritten by a localized label.
// Player name, planet name, quest title, credits, level stay game data.
// hzL / hzLt run on card build, language change, or state-change sync — not ticks.
// Run: node tests/l10n_hud_dynamic_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const as = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const insert = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");

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

const apply = fnText(insert, "hzL10nApplyHud").body;
expect(!/hz26ChName/.test(apply), "language apply does not stamp CHARACTER onto the player-name field");
expect(!/hz26ChCr/.test(apply) && !/hz26ChLv/.test(apply) && !/hz26ChMV/.test(apply),
	"language apply does not stamp credits, level, or mass value");
expect(!/hzPpName/.test(apply) && !/hzQ19T/.test(apply) && !/hzTgName/.test(apply),
	"language apply does not stamp planet, quest, or target names");
expect(!/hzL10nTf\(this\.hz26ChML/.test(apply) && !/hzL10nTf\(this\.hz26PowL/.test(apply),
	"language apply does not blindly stamp MASS / POWER (those fields also hold OVERWEIGHT / READY)");
expect(/hz26CharSync/.test(apply), "language apply re-runs character sync so the live name and MASS/OVERWEIGHT return");
expect(/hzE19Sync/.test(apply), "language apply re-runs equipment sync so RELOAD / POWER / READY return");

const build = fnText(as, "hz26BuildChar").body;
expect(/hz26ChName = this\.hzT\(f,"Character"/.test(build),
	"character card builds a name placeholder, not a localized CHARACTER label");
expect(!/hzLt\("CHARACTER"\)/.test(build), "character card build does not look up CHARACTER as the title");

const sync = fnText(as, "hz26CharSync").body;
expect(/hz26Name/.test(sync) && /hzFitText\(this\.hz26ChName,this\.hzUC\(nm\)/.test(sync),
	"character sync writes the player name (or arrange sample) into the title field");
expect(!/hzLt\(nm\)/.test(sync) && !/hzLt\("CHARACTER"\)/.test(sync),
	"character sync never looks up the player name");
expect(/hzLt\("OVERWEIGHT"\)/.test(sync) && /hzLt\("MASS"\)/.test(sync),
	"MASS / OVERWEIGHT are static labels looked up on the state-change sync");

const pow = fnText(as, "hz26EqRow").body;
expect(/hzLt\("READY"\)/.test(pow) && /hzLt\("POWER"\)/.test(pow),
	"POWER / READY are looked up when the extras row is laid out, not per frame");

const rel = fnText(as, "hzE19Sync").body;
expect(/hzLt\("RELOAD"\)/.test(rel), "RELOAD is looked up on equipment sync");

const planet = fnText(as, "hzPpLayout").body;
expect(/hzFitText\(this\.hzPpName/.test(planet) || /hzPpBodyName/.test(planet),
	"planet layout still writes the game body name");
expect(/hzL\("hud\.hud_label\.local_game","LOCAL\/GAME"\)/.test(planet), "LOCAL/GAME is a static HUD label on layout");
expect(!/hzLt\(this\.hzPpBodyName/.test(planet), "planet name is not passed through hzLt");
expect(/hzLt\(this\.hzPpStatus\)/.test(planet), "planet SAFE / hazard word is looked up at layout, not stored translated");
expect(/hzLt\("AIR"\)/.test(planet), "AIR prefix is looked up at layout");
expect(/hzLt\("IN SHIP"\)/.test(planet) && /hzLt\("STATION"\)/.test(planet) && /hzLt\("IN SPACE"\)/.test(planet),
	"off-surface planet status words are looked up");
expect(/hz43SetTx\(this\.hz43LocL,this\.hzL\("hud\.hud_label\.local_game","LOCAL\/GAME"\)\)/.test(as)
	&& /hz43SetTx\(this\.hz43RealL,this\.hzL\("hud\.hud_label\.pc_real","PC\/REAL"\)\)/.test(as),
	"watch clock labels use hud.hud_label when the face is written");
expect(/hzL10nTf\(this\.hzPpLocL, "LOCAL\/GAME", "hud\.hud_label\.local_game"\)/.test(apply)
	&& /hzL10nTf\(this\.hzPpRealL, "PC\/REAL", "hud\.hud_label\.pc_real"\)/.test(apply)
	&& /hzL10nTf\(this\.hz43LocL, "LOCAL\/GAME", "hud\.hud_label\.local_game"\)/.test(apply)
	&& /hzL10nTf\(this\.hz43RealL, "PC\/REAL", "hud\.hud_label\.pc_real"\)/.test(apply),
	"language apply stamps planet/watch clocks from hud.hud_label, not settings.ui");
expect(/hzPpLayout\(\)/.test(apply), "language apply re-lays the planet card so SAFE / AIR / clocks refresh");
expect(/hzT19Sig = ""/.test(apply), "language apply invalidates the target-pill signature so TRADE restamps");
expect(/if\(!this\.hzShowTarget\)/.test(apply) && /hzT19Off\(\)/.test(apply),
	"language apply restores vanilla when Hover is off (does not leave the circle and leader line)");

const t19 = fnText(as, "hzT19Label").body;
expect(/hzT19VanLbl/.test(t19) && /hzLt\(s\)/.test(t19),
	"no-$ prompt verbs try the vanilla label first, then hzLt (TRADE)");
expect(!/this\.hzLt\(/.test(fnText(as, "hzTickVitals").body) && !/this\.hzL\(/.test(fnText(as, "hzTickVitals").body),
	"vitals tick still does no lookup");

expect(/"settings\.ui\."/.test(fnText(insert, "hzLt").body)
	&& fnText(insert, "hzLt").body.indexOf('"settings.ui."') < fnText(insert, "hzLt").body.indexOf('"hud.hud_label."'),
	"Settings hzLt still prefers settings.ui over hud.hud_label");
expect(!/hzLt\("LOCAL\/GAME"\)/.test(planet) && !/hzLt\("PC\/REAL"\)/.test(planet),
	"planet layout does not use hzLt for clock labels");
expect((as.match(/hzLt\("LOCAL\/GAME"\)/g) || []).length === 0
	&& (as.match(/hzLt\("PC\/REAL"\)/g) || []).length === 0,
	"HUD clock labels no longer call hzLt for LOCAL/GAME or PC/REAL");

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
function slug(s) {
	let o = "", prev = false;
	for (let i = 0; i < s.length && o.length < 48; i++) {
		const code = s.charCodeAt(i);
		const ok = (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
		if (ok) { o += s.charAt(i).toLowerCase(); prev = false; }
		else if (o.length && !prev) { o += "_"; prev = true; }
	}
	if (o.endsWith("_")) o = o.slice(0, -1);
	return o;
}
function hzLt(table, en) {
	const sl = slug(en);
	const pfx = ["settings.ui.", "settings.chrome.", "settings.language.", "settings.tabs.",
		"hud.hud_label.", "hud.option.", "hud.help.", "hud."];
	for (const p of pfx) {
		if (table[p + sl]) return table[p + sl];
	}
	return en;
}
const locDir = path.join(__dirname, "..", "Data", "SFSE", "Plugins", "HorizonUI", "Localization");
const de = {};
flatten(JSON.parse(fs.readFileSync(path.join(locDir, "de.json"), "utf8")), "", de);
expect(de["settings.ui.local_game"] === "ORT/SPIEL" && de["settings.ui.pc_real"] === "PC/ECHT",
	"Settings German LOCAL/GAME and PC/REAL strings are unchanged");
expect(de["hud.hud_label.local_game"] === "LOKAL/SPIEL" && de["hud.hud_label.pc_real"] === "PC/ECHTZEIT",
	"HUD German clock labels are LOKAL/SPIEL and PC/ECHTZEIT");
expect(hzLt(de, "LOCAL/GAME") === "ORT/SPIEL" && hzLt(de, "PC/REAL") === "PC/ECHT",
	"hzLt still resolves those English labels to the Settings strings");
expect(de["hud.hud_label.local_game"] !== de["settings.ui.local_game"]
	&& de["hud.hud_label.pc_real"] !== de["settings.ui.pc_real"],
	"HUD clock keys differ from Settings so the explicit hud.hud_label lookup is required");
const pl = {};
flatten(JSON.parse(fs.readFileSync(path.join(locDir, "pl.json"), "utf8")), "", pl);
expect(pl["settings.ui.local_game"] === "LOKAL/GRA" && pl["settings.ui.pc_real"] === "PC/REALNY",
	"Settings Polish LOCAL/GAME and PC/REAL strings are short HUD labels");
expect(pl["hud.hud_label.local_game"] === "LOK./GRA" && pl["hud.hud_label.pc_real"] === "PC/CZAS",
	"HUD Polish clock labels are LOK./GRA and PC/CZAS");
expect(pl["hud.hud_label.local_game"] !== pl["settings.ui.local_game"]
	&& pl["hud.hud_label.pc_real"] !== pl["settings.ui.pc_real"],
	"Polish HUD clock keys differ from Settings so the explicit hud.hud_label lookup is required");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log(passed + " passed");
