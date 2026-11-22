// Crosshair card foe bar tests (0.43.3.0 fix). Run: node tests/target_foebar_test.js
// Bug: after a kill, looting the corpse (foe card -> container list card) showed the dead enemy's red health bar
// across the top of the loot card, under the title, until a save reload. The bar is its own sprite (hzT19BarG);
// hzT19Content set hzT19BarOn = false without clearing it, so the caller's "else if(this.hzT19BarOn)" clear never ran.
// Runs the production caller block of hzT19Tick (content redraw + bar paint), the head of hzT19Content, the real
// hzT19PaintFoeBars, hzT19ResetPay and hzT19FadeOut on a graphics model.
// Author: Moragar. Last modified: 2026-11-14.
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
	const i = src.indexOf("private function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(i, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function toJs(body) {
	return body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.*]+\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
const mkFn = (host, args, body) => Function.apply(null, args.concat(["with(this){\n" + toJs(body) + "\n}"])).bind(host);

// the caller: hzT19Tick from the content-signature check through the foe bar paint
const tick = fnText(as, "hzT19Tick").body;
const c0 = tick.indexOf("         if(sig != this.hzT19Sig)");
const c1 = tick.indexOf("\n", tick.indexOf("else if(this.hzT19BarOn)", c0));
if (c0 < 0 || c1 < 0) throw new Error("caller block not found");
const CALLER = tick.slice(c0, c1);
// the head of hzT19Content (everything before it draws a card kind)
const content = fnText(as, "hzT19Content").body;
const HEAD = content.slice(0, content.indexOf("         var dk:Boolean = this.hzDarkText();"));

function G() { this.shapes = 0; this.clears = 0; this.draws = 0; }
G.prototype.clear = function () { this.shapes = 0; this.clears++; };
G.prototype.beginFill = function () {}; G.prototype.endFill = function () {};
G.prototype.drawRoundRect = function () { this.shapes++; this.draws++; };
function makeHost() {
	const h = {
		int: (v) => Number(v) | 0, HZ_RED: 0xff0000, hzPerfOn: false, hzPerfN: null,
		hzT19G: { graphics: new G() }, hzT19Kov: null, hzT19BarG: { visible: false, graphics: new G() },
		hzT19BarOn: false, hzT19BarSig: "", hzT19HoldSig: "", hzT19Sig: "", hzT19SigMine: "", hzT19ActCached: "", hzT19ItemsCached: "",
		hzT19BarY: 0, hzT19BarW: 0, hzTgHpV: 0.6, hzTgGhost: 0, hzCardOpacity: 1, hzContOpacity: 0.9, hz38DrawOk: false, hz38DrawErr: 0,
		HorizonTarget_mc: { visible: true, alpha: 1 }, hzTg19: { visible: true }, hzT19A: 1, contents: 0,
		hzDarkText() { return false; }, hzIconCol(c) { return c; },
	};
	for (const n of ["hzT19PaintFoeBars", "hzT19ResetPay", "hzT19FadeOut"]) { const f = fnText(as, n); h[n] = mkFn(h, [], f.body); }
	h.hzSameN = mkFn(h, ["a", "b"], fnText(as, "hzSameN").body);   // 0.43.6: the foe bars compare fields (round 3 E)
	const head = mkFn(h, ["kind", "a", "aw", "sel", "start"], HEAD);
	h.hzT19Content = function (kind, a, aw, sel, start) {
		h.contents++;
		head(kind, a, aw, sel, start);
		if (kind === "foe") { h.hzT19BarY = 40; h.hzT19BarW = 260; h.hzT19BarOn = true; }   // as the foe branch does
	};
	const caller = mkFn(h, ["kind", "sig", "show", "a", "aw", "sel", "start"], CALLER);
	h.frame = (kind, name) => { h.HorizonTarget_mc.visible = true; h.hzTg19.visible = true; h.hzT19A = 1; caller(kind, kind + "|" + (name || ""), true, {}, {}, 0, 0); };
	return h;
}
const bar = (h) => h.hzT19BarG.visible && h.hzT19BarG.graphics.shapes > 0;

{
	const h = makeHost();
	h.frame("foe", "Va'ruun Zealot");
	expect(bar(h) && h.hzT19BarOn, "a hostile target: the red bar shows on the foe card");
	h.hzTgHpV = 0.2; h.frame("foe", "Va'ruun Zealot");
	expect(bar(h), "damage: the bar repaints");
	const d0 = h.hzT19BarG.graphics.draws, k0 = h.hzT19BarG.graphics.clears;
	h.hzTgHpV = 0; h.frame("list", "Va'ruun Zealot");
	expect(!h.hzT19BarG.visible && h.hzT19BarG.graphics.shapes === 0 && !h.hzT19BarOn, "the kill turns it into a container (foe -> list): the loot card has no red bar (the bug)");
	expect(h.hzT19BarG.graphics.draws === d0 && h.hzT19BarG.graphics.clears === k0 + 1, "the transition clears the bar once and never paints it");
	const cl = h.hzT19BarG.graphics.clears;
	for (let i = 0; i < 100; i++) h.frame("list", "Va'ruun Zealot");
	h.frame("list", "Va'ruun Zealot|scrolled"); h.frame("list", "Va'ruun Zealot|item taken");
	expect(h.hzT19BarG.graphics.clears === cl && !h.hzT19BarG.visible, "100 steady frames and two list redraws afterwards: the bar sprite is not touched again");
	h.hzTgHpV = 1; h.frame("foe", "Ecliptic Gunner");
	expect(bar(h), "the next hostile target: the bar comes back");
}
{
	const h = makeHost();
	h.frame("foe", "Spacer"); h.frame("prompt", "Talk");
	expect(!h.hzT19BarG.visible && h.hzT19BarG.graphics.shapes === 0, "foe -> prompt card: no stale bar either");
}
{
	const h = makeHost();
	h.frame("foe", "Va'ruun Zealot");
	for (let i = 0; i < 4; i++) h.hzT19FadeOut();
	expect(!h.hzTg19.visible && !h.hzT19BarG.visible && h.hzT19BarG.graphics.shapes === 0 && !h.hzT19BarOn, "crosshair leaves (fade-out end): the foe bar is dropped with the card");
	h.hzTgHpV = 0; h.frame("list", "Va'ruun Zealot");
	expect(!h.hzT19BarG.visible && h.hzT19BarG.graphics.shapes === 0, "then looting the corpse: the loot card starts clean");
	h.hzTgHpV = 0.5; h.frame("foe", "Va'ruun Zealot");
	expect(bar(h), "and a foe after that paints its bar again");
}
{
	const h = makeHost();
	h.frame("foe", "A"); const n = h.hzT19BarG.graphics.clears;
	for (let i = 0; i < 100; i++) h.frame("foe", "A");
	expect(h.hzT19BarG.graphics.clears === n && h.contents === 1, "steady foe frames: one content draw, no bar repaint (signature)");
	h.frame("list", "B"); h.frame("list", "C");
	const n2 = h.hzT19BarG.graphics.clears; h.frame("prompt", "D"); h.frame("list", "E");
	expect(h.hzT19BarG.graphics.clears === n2, "card changes with no bar up do not touch the bar sprite");
}
{
	// a bar left on screen with the flag already off (the pre-fix state: any path that dropped the flag without
	// clearing the sprite) is cleared on the next card change too
	const h = makeHost();
	h.hzT19BarW = 260; h.hzT19BarY = 40; h.hzTgHpV = 0; h.hzT19BarOn = false; h.hzT19BarSig = "0|260|40|0|0";
	h.hzT19BarG.visible = true; h.hzT19BarG.graphics.shapes = 3; h.hzT19Sig = "foe|Va'ruun Zealot";
	h.frame("list", "Va'ruun Zealot");
	expect(!h.hzT19BarG.visible && h.hzT19BarG.graphics.shapes === 0, "a stuck bar (flag off, sprite showing) is cleared on the container-open edge");
}
{
	const h = makeHost(); h.hzT19BarG.visible = false; h.hzT19BarOn = false;
	h.hzT19ResetPay();
	expect(h.hzT19BarG.graphics.clears === 0 && h.hzT19BarSig === "", "reset with no bar up: nothing to clear");
}
{
	const changed = HEAD + fnText(as, "hzT19ResetPay").body;
	expect(!/Timer|setTimeout|setInterval|ENTER_FRAME|addEventListener|getChildByName|hzFindByName/.test(changed), "no timer / frame / listener / search code in the fix");
	expect(/if\(this\.hzT19BarG\) \{ this\.hzT19BarG\.graphics\.clear\(\); this\.hzT19BarG\.visible = false; \}/.test(fnText(as, "hzT19Fixture").body), "the perf fixture path is unchanged");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("target foe bar: " + passed + " ok, all passed");
