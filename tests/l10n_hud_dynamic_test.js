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
expect(/hzLt\("LOCAL\/GAME"\)/.test(planet), "LOCAL/GAME is a static label on layout");
expect(!/hzLt\(this\.hzPpBodyName/.test(planet), "planet name is not passed through hzLt");
expect(/hzLt\(this\.hzPpStatus\)/.test(planet), "planet SAFE / hazard word is looked up at layout, not stored translated");
expect(/hzLt\("AIR"\)/.test(planet), "AIR prefix is looked up at layout");
expect(/hzLt\("IN SHIP"\)/.test(planet) && /hzLt\("STATION"\)/.test(planet) && /hzLt\("IN SPACE"\)/.test(planet),
	"off-surface planet status words are looked up");
expect(/hz43SetTx\(this\.hz43LocL,this\.hzLt\("LOCAL\/GAME"\)\)/.test(as)
	&& /hz43SetTx\(this\.hz43RealL,this\.hzLt\("PC\/REAL"\)\)/.test(as),
	"watch clock labels go through hzLt when the face is written");
expect(/hzPpLayout\(\)/.test(apply), "language apply re-lays the planet card so SAFE / AIR / clocks refresh");

const t19 = fnText(as, "hzT19Label").body;
expect(/hzT19VanLbl/.test(t19) && /hzLt\(s\)/.test(t19),
	"no-$ prompt verbs try the vanilla label first, then hzLt (TRADE)");
expect(!/this\.hzLt\(/.test(fnText(as, "hzTickVitals").body) && !/this\.hzL\(/.test(fnText(as, "hzTickVitals").body),
	"vitals tick still does no lookup");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log(passed + " passed");
