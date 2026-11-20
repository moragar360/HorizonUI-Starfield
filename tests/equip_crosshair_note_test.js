// 0.43.3.2 item 5 tests: Equipment rule with the game's crosshair turned off.
// Run: node tests/equip_crosshair_note_test.js
// Without a drawn / holstered feed (no DLL calls hzSetWeaponDrawn), "Weapon drawn only" needs the crosshair on
// (HudCrosshairData.bEnabled). With it off the card never shows, so the F11 Equipment rule row carries a note.
// Checks: the note text on the AmmoRule row only; the two rules it names exist and are offered on that row; the
// production hzWeaponOut / hzRuleOk (types stripped): crosshair off -> rule 3 hides, ALWAYS and COMBAT ONLY still
// work; crosshair on with a weapon reticle -> rule 3 shows (Fix 3 unchanged). Mutants must fail.
// Author: Moragar. Last modified: 2026-11-18.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const AS0 = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const NOTE = "Crosshair off? Set this to ALWAYS or COMBAT ONLY.";

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
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	return new Function(...params, f.body.replace(/var (\w+):[\w*]+/g, "let $1"));
}
function rulesRows(src) {
	const m = /return (\[\{"k":"JetpackRule".*?\]);\n/.exec(src);
	if (!m) throw new Error("rules row list not found");
	return JSON.parse(m[1]);
}
function names(src) {
	const m = /HZ_RULE_NAMES:Array = (\[[^\]]*\]);/.exec(src);
	return JSON.parse(m[1]);
}
function behave(src, log) {
	const bad = [];
	const chk = (c, m) => { if (log) expect(c, m); if (!c) bad.push(m); };
	try {
		const rows = rulesRows(src);
		const am = rows.find((r) => r.k === "AmmoRule");
		chk(am && am.note === NOTE, "F11 > RULES > EQUIPMENT carries the note: " + NOTE);
		chk(rows.filter((r) => r.note === NOTE).length === 1, "the note is on that row only");
		const nm = names(src);
		chk(am && am.ids.indexOf(nm.indexOf("ALWAYS")) >= 0 && am.ids.indexOf(nm.indexOf("COMBAT ONLY")) >= 0,
			"ALWAYS and COMBAT ONLY are names of rules the EQUIPMENT row offers");
		const h = { hzPlugActive: false, hzPlugDrawn: false, hzAmmoDrawn: true, hzCrossOn: false, hzWpnRet: true,
			hzInCombat: false, hzInShip: false, hzJetCharge: 1, hzVitHpF: 1, hzVitO2F: 1, hzAfflCount: 0 };
		h.hzWeaponOut = toJs(src, "hzWeaponOut").bind(h);
		h.hzRuleOk = toJs(src, "hzRuleOk").bind(h);
		chk(h.hzRuleOk(3) === false, "crosshair off, gun out: WEAPON DRAWN ONLY hides the card (why the note exists)");
		chk(h.hzRuleOk(0) === true, "crosshair off: ALWAYS shows the card");
		h.hzInCombat = true;
		chk(h.hzRuleOk(1) === true, "crosshair off: COMBAT ONLY shows the card in combat");
		h.hzInCombat = false; h.hzCrossOn = true;
		chk(h.hzRuleOk(3) === true, "crosshair on with a weapon reticle: WEAPON DRAWN ONLY shows the card (Fix 3 unchanged)");
		h.hzWpnRet = false;
		chk(h.hzRuleOk(3) === false, "crosshair on, holstered (no weapon reticle): hidden (Fix 3 unchanged)");
		h.hzPlugActive = true; h.hzPlugDrawn = true; h.hzCrossOn = false;
		chk(h.hzRuleOk(3) === true, "a drawn feed (hzSetWeaponDrawn) would decide even with the crosshair off");
		chk(/^[\x20-\x7e]+$/.test(am ? am.note : ""), "the note is plain ASCII");
	} catch (e) {
		chk(false, "threw " + e.message);
	}
	return bad;
}

behave(AS0, true);

const mutants = [
	["note removed", (s) => s.replace(',"note":"' + NOTE + '"', "")],
	["note on the wrong row", (s) => s.replace(',"note":"' + NOTE + '"', "").replace('"l":"COMPASS","t":"q","ids":[0,1,2]}', '"l":"COMPASS","t":"q","ids":[0,1,2],"note":"' + NOTE + '"}')],
	["Fix 3 path changed", (s) => s.replace("(this.hzAmmoDrawn && this.hzCrossOn && this.hzWpnRet)", "(this.hzAmmoDrawn && this.hzWpnRet)")],
];
for (const [name, fn] of mutants) {
	const m = fn(AS0);
	if (m === AS0) { expect(false, "mutant " + name + " applies"); continue; }
	const bad = behave(m, false);
	expect(bad.length > 0, "mutant " + name + " is caught" + (bad.length ? " (" + bad[0] + ")" : ""));
}

console.log("equipment crosshair note: " + passed + " ok" + (failed ? ", " + failed + " FAILED" : ", all passed"));
process.exit(failed ? 1 : 0);
