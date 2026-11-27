// Hover + Container off must restore the game's stock prompt the same frame, without a save/reload.
// The live toggle used to set the flag and restore captured alphas (often 0, captured while Horizon hid the
// widget). The "force vanilla alpha to 1" path only ran while Horizon still owned the prompt (mine == true).
// Run: node tests/hover_vanilla_restore_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const SRC = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src); if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1; let depth = 0;
	for (let p = brace; p < src.length; p++) { if (src[p] === "{") depth++; else if (src[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: src.slice(brace + 1, p) }; } }
	throw new Error("unbalanced " + name);
}
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const defs = f.params.split(",").map((p) => p.trim()).filter((p) => /=/.test(p)).map((p) => { const n = p.split(":")[0].trim(); const v = p.split("=")[1].trim(); return "if(" + n + " === undefined) " + n + " = " + v + ";"; }).join("\n");
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (var $1 of ")
		.replace(/var (\w+):[\w*]+/g, "var $1")
		.replace(/([\w.\]\)]+) as (?:Array|MovieClip|Object|DisplayObject|DisplayObjectContainer|TextField|Sprite)\b/g, "$1")
		.replace(/([\w.]+) is Array/g, "Array.isArray($1)")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/(^|[^.\w])(HZ\w*)\b/g, "$1this.$2");
	return new Function(...params, defs + "\n" + body);
}

{
	const gb = fnText(SRC, "hz38GiveBackVanilla").body;
	expect(/this\.hzT19Off\(\)/.test(gb) && /hd\.alpha = 1/.test(gb) && /ad\.alpha = 1/.test(gb), "GiveBackVanilla: hide Horizon's card, then force the stock prompt to alpha 1");
	expect(!/hzT19HidePromptTree|hzT19HideA|hz38HideVanilla|for each/.test(gb), "GiveBackVanilla does not walk the hide list");
	expect(!/ENTER_FRAME|getTimer|addEventListener/.test(gb), "GiveBackVanilla adds no per-frame work");
	const tick = fnText(SRC, "hzT19Tick").body;
	expect(!/hz38GiveBackVanilla/.test(tick), "the per-frame hover tick never calls GiveBackVanilla");
	expect((SRC.match(/this\.hz38GiveBackVanilla\(\)/g) || []).length === 2, "GiveBackVanilla runs on the two ShowTarget falling edges only");
	expect(/if\(this\.hzShowTarget && !bv\) \{ this\.hz38GiveBackVanilla\(\); \}/.test(SRC), "F11 live toggle: falling edge restores vanilla this frame");
	expect(/if\(this\.hzShowTarget && !wantTg\) \{ this\.hz38GiveBackVanilla\(\); \}/.test(SRC), "settings apply: falling edge restores vanilla this frame");
	const van = fnText(SRC, "hz38Vanilla").body;
	expect(/hd\.alpha < 0\.05/.test(van) && /hd\.alpha = 1/.test(van), "while Horizon still owns the prompt, a captured 0 alpha is forced to 1");
	expect(!/hz38GiveBackVanilla/.test(van), "the per-frame vanilla rule does not double as the off-edge restore");
}

function makeHost() {
	const holder = { alpha: 0, name: "holder" };
	const act = { alpha: 0, name: "act" };
	const h = {
		RolloverWidget_mc: { RolloverActivationHolder_mc: holder, RolloverActivation_mc: act },
		hzTgHidden: [{ d: holder, a: 0 }, { d: act, a: 0 }],
		hzTgHidA: [0, 0],
		HorizonTarget_mc: { visible: true },
		hzTg19: { visible: true },
		hzT19ActCached: "x", hzT19ItemsCached: "y", hzT19Sig: "z", hzT19BarSig: "b", hzT19HoldSig: "h",
		hzT19BarOn: false, hzT19BarG: null,
		hzT19HcValid: true, hzT19HcDue: false, hz38VanShown: false,
		hzShowTarget: true,
	};
	for (const n of ["hzTgRestore", "hzT19ResetPay", "hzT19Off", "hz38GiveBackVanilla"]) h[n] = toJs(SRC, n).bind(h);
	return { h, holder, act };
}

{
	const { h, holder, act } = makeHost();
	h.hz38GiveBackVanilla();
	expect(holder.alpha === 1 && act.alpha === 1, "stock holder and activation are alpha 1 this frame (captured 0 does not stick)");
	expect(h.hzTgHidden.length === 0, "captured hide list is cleared");
	expect(!h.HorizonTarget_mc.visible && !h.hzTg19.visible, "Horizon's card is off");
	expect(h.hz38VanShown === true, "vanilla is marked shown so the next tick does not hide it again");
	expect(h.hzT19HcValid === false && h.hzT19HcDue === true, "hide cache is invalidated (no stale hide walk)");
	expect(h.hzT19Sig === "", "payload fingerprints reset with the card");
}

{
	const { h, holder, act } = makeHost();
	// the old live-toggle path: restore captured 0, then leave mine false so the force-to-1 path never runs
	h.hzTgRestore();
	expect(holder.alpha === 0 && act.alpha === 0, "the pre-fix restore-only path leaves a captured 0 (the reload bug)");
	h.hz38GiveBackVanilla();
	expect(holder.alpha === 1 && act.alpha === 1, "GiveBackVanilla after that restore still forces alpha 1");
}

console.log("hover vanilla restore: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
