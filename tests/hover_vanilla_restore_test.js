// Hover + Container off must restore the game's stock prompt the same frame, without a save/reload.
// Round 2: forcing holder/activation to alpha 1 left a white unstyled bar with empty key boxes (KeepHold had
// set unused Button1_mc visible=true without a snapshot, and restore only wrote alpha, not visible). Horizon
// snapshots alpha+visible before every write (HideA, Hide, KeepHold) and restores both.
// Round 3 (qmfix_0435n in game): only the leader line came back. Vanilla holder rollOn / Header AnimIn
// still had Header / glyphs at alpha 0 when HideA first ran, so restore wrote 0. HideA now stores 1 for
// that case (the shown state). Restore applies orig only (no second hidden-list write). When the feature
// is off the tick never touches those clips.
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
	expect(/this\.hzT19Off\(\)/.test(gb) && !/\.alpha = 1/.test(gb) && !/RolloverActivation/.test(gb), "GiveBackVanilla: hide Horizon's card and restore snapshots; it does not force holder/activation to alpha 1");
	expect(!/hzT19HidePromptTree|hzT19HideA|hz38HideVanilla|for each/.test(gb), "GiveBackVanilla does not walk the hide list");
	expect(!/ENTER_FRAME|getTimer|addEventListener/.test(gb), "GiveBackVanilla adds no per-frame work");
	const tick = fnText(SRC, "hzT19Tick").body;
	expect(!/hz38GiveBackVanilla/.test(tick), "the per-frame hover tick never calls GiveBackVanilla");
	expect((SRC.match(/this\.hz38GiveBackVanilla\(\)/g) || []).length === 2, "GiveBackVanilla runs on the two ShowTarget falling edges only");
	expect(/if\(this\.hzShowTarget && !bv\) \{ this\.hz38GiveBackVanilla\(\); \}/.test(SRC), "F11 live toggle: falling edge restores vanilla this frame");
	expect(/if\(this\.hzShowTarget && !wantTg\) \{ this\.hz38GiveBackVanilla\(\); \}/.test(SRC), "settings apply: falling edge restores vanilla this frame");
	expect(/if\(!this\.hzShowTarget\)/.test(tick) && tick.indexOf("if(!this.hzShowTarget)") < tick.indexOf("hzT19BtnSync"), "when the feature is off the tick returns before any vanilla prompt clip read or hide");
	const van = fnText(SRC, "hz38Vanilla").body;
	expect(/hd\.alpha < 0\.05/.test(van) && /hd\.alpha = 1/.test(van), "while Horizon still owns the prompt, a captured 0 alpha is forced to 1");
	expect(!/hz38GiveBackVanilla/.test(van), "the per-frame vanilla rule does not double as the off-edge restore");
}

{
	const snap = fnText(SRC, "hzTgSnap").body;
	expect(/hzTgOrigD\.indexOf\(d\)/.test(snap) && /hideA && a < 0\.05/.test(snap) && /\.push\(\{"d":d,"v":d\.visible,"a":a\}\)/.test(snap), "hzTgSnap records alpha and visible once per clip; HideA of a 0 stores 1");
	expect(/hideA:Boolean = false/.test(fnText(SRC, "hzTgSnap").params), "hzTgSnap hideA defaults false so KeepHold / Hide keep the real visible flag");
	expect(!/ENTER_FRAME|getTimer|addEventListener/.test(snap), "hzTgSnap adds no per-frame work");
	const hideA = fnText(SRC, "hzT19HideA").body;
	expect(hideA.indexOf("this.hzTgSnap(d, true)") >= 0 && hideA.indexOf("this.hzTgSnap(d, true)") < hideA.indexOf("d.alpha = 0"), "HideA snapshots as prompt art before it writes alpha");
	expect(/d\.alpha < 0\.05 \? 1 : d\.alpha/.test(hideA), "HideA's hide-walk entry also stores 1 when the clip was already 0");
	const hide = fnText(SRC, "hzTgHide").body;
	expect(hide.indexOf("this.hzTgSnap(d)") >= 0 && hide.indexOf("this.hzTgSnap(d)") < hide.indexOf("d.visible = false"), "Hide snapshots before it writes visible");
	const kh = fnText(SRC, "hzT19KeepHold").body;
	expect(/this\.hzTgSnap\(d\)/.test(kh) && /this\.hzTgSnap\(p\)/.test(kh) && kh.indexOf("this.hzTgSnap(d)") < kh.indexOf("d.visible = true"), "KeepHold snapshots the button and each parent before visible/alpha writes");
	const rest = fnText(SRC, "hzTgRestore").body;
	expect(/dd\.alpha = Number\(s\.a\)/.test(rest) && /dd\.visible = Boolean\(s\.v\)/.test(rest) && /s\.d as DisplayObject/.test(rest), "restore writes both snapshotted properties (alpha and visible)");
	expect(/if\(hadOrig\)/.test(rest) && /else[\s\S]*this\.hzTgHidden/.test(rest), "restore applies orig and does not replay the hide-walk list over it");
	expect(/hzT19HcValid = false/.test(rest), "restore invalidates the hide-walk cache so the next off frame cannot re-zero art");
	for (const n of ["hzT19HideA", "hzT19KeepHold", "hzTgHide"]) {
		const b = fnText(SRC, n).body;
		expect(!/textColor|setTextFormat|defaultTextFormat|colorTransform|gotoAndStop|gotoAndPlay|filters\s*=/.test(b), n + " only writes alpha/visible on vanilla prompt clips");
	}
}

function clip(name, vis, a, parent) {
	return { name: name, visible: vis, alpha: a, parent: parent || null };
}

function makeHost() {
	const hud = { name: "hud" };
	const holder = clip("holder", true, 1, hud);
	const header = clip("headerBg", true, 1, holder);   // dark name-bar fill
	const used = clip("Button2_mc", true, 1, holder);    // TALK
	const unused = clip("Button1_mc", false, 1, holder); // empty key box if KeepHold sticks
	const glyph = clip("PCButton_mc", true, 1, used);    // the E / A glyph inside TALK
	const h = {
		RolloverWidget_mc: { RolloverActivationHolder_mc: holder, RolloverActivation_mc: holder },
		hzTgHidden: [],
		hzTgHidA: [],
		hzTgOrig: [],
		hzTgOrigD: [],
		hzT19HcRec: false,
		HorizonTarget_mc: { visible: true },
		hzTg19: { visible: true },
		hzT19ActCached: "x", hzT19ItemsCached: "y", hzT19Sig: "z", hzT19BarSig: "b", hzT19HoldSig: "h",
		hzT19BarOn: false, hzT19BarG: null,
		hzT19HcValid: true, hzT19HcDue: false, hz38VanShown: false,
		hzShowTarget: true,
		hzT19BtnClip: function(_aw, t) { return t === 0 ? used : (t === 1 ? unused : null); },
	};
	for (const n of ["hzTgSnap", "hzTgRestore", "hzT19HideA", "hzT19KeepHold", "hzT19ResetPay", "hzT19Off", "hz38GiveBackVanilla"]) h[n] = toJs(SRC, n).bind(h);
	return { h, holder, header, used, unused, glyph };
}

{
	const { h, holder, header, used, unused, glyph } = makeHost();
	h.hzT19HideA(header);
	h.hzT19HideA(glyph);
	h.hzT19KeepHold(null);
	expect(header.alpha === 0 && glyph.alpha === 0, "HideA zeros the name-bar fill and the key glyph");
	expect(unused.visible === true && unused.alpha === 1, "KeepHold forces the unused key box visible (the empty rounded box)");
	expect(used.visible === true, "the used TALK button stays visible for the hold meter");
	expect(h.hzTgOrig.length >= 4, "every modified clip is in the snapshot (header, glyph, used, unused, parents)");
	const origUnused = h.hzTgOrig.filter((o) => o.d === unused)[0];
	const origGlyph = h.hzTgOrig.filter((o) => o.d === glyph)[0];
	const origHeader = h.hzTgOrig.filter((o) => o.d === header)[0];
	expect(origUnused && origUnused.v === false && origUnused.a === 1, "unused key box was snapshotted at visible false before KeepHold");
	expect(origGlyph && origGlyph.a === 1 && origGlyph.v === true, "glyph was snapshotted at alpha 1 before HideA");
	expect(origHeader && origHeader.a === 1 && origHeader.v === true, "name-bar fill was snapshotted at alpha 1 before HideA");
	h.hz38GiveBackVanilla();
	expect(header.alpha === 1 && header.visible === true, "name-bar fill is back (not a plain white unstyled bar)");
	expect(glyph.alpha === 1 && glyph.visible === true, "TALK glyph is back (not an empty rounded key box)");
	expect(unused.visible === false && unused.alpha === 1, "unused key box is hidden again (the two empty boxes on the row below)");
	expect(used.visible === true && used.alpha === 1, "used TALK button is still visible");
	expect(holder.alpha === 1 && holder.visible === true, "holder stays at its snapshotted 1 (not force-written)");
	expect(h.hzTgOrig.length === 0 && h.hzTgHidden.length === 0, "snapshot and hide list are cleared");
	expect(!h.HorizonTarget_mc.visible && !h.hzTg19.visible, "Horizon's card is off");
	expect(h.hz38VanShown === true, "vanilla is marked shown so the next tick does not hide it again");
	expect(h.hzT19HcValid === false && h.hzT19HcDue === true, "hide cache is invalidated (no stale hide walk)");
	expect(h.hzT19Sig === "", "payload fingerprints reset with the card");
}

{
	const { h, unused } = makeHost();
	h.hzT19KeepHold(null);
	h.hzTgHidden = [];
	expect(unused.visible === true, "KeepHold alone shows the unused key box");
	h.hzT19Off();
	expect(unused.visible === false, "Off restores KeepHold snapshots even when the hide list is empty");
}

{
	const { h, holder } = makeHost();
	holder.alpha = 0.4;
	h.hzTgSnap(holder);
	holder.alpha = 1;
	h.hz38GiveBackVanilla();
	expect(holder.alpha === 0.4, "GiveBackVanilla restores the snapshotted holder alpha; it does not force 1");
}

{
	const { h, unused, glyph } = makeHost();
	h.hzT19HideA(glyph);
	h.hzT19KeepHold(null);
	h.hzTgSnap(glyph);
	h.hzTgSnap(unused);
	expect(h.hzTgOrig.filter((o) => o.d === glyph).length === 1 && h.hzTgOrig.filter((o) => o.d === unused).length === 1, "a second snap of the same clip does not replace the original");
}

{
	const { h, header, unused, glyph } = makeHost();
	header.alpha = 0;
	glyph.alpha = 0;
	h.hzT19HideA(header);
	h.hzT19HideA(glyph);
	h.hzT19KeepHold(null);
	const origHeader = h.hzTgOrig.filter((o) => o.d === header)[0];
	const origGlyph = h.hzTgOrig.filter((o) => o.d === glyph)[0];
	expect(origHeader && origHeader.a === 1 && origGlyph && origGlyph.a === 1, "HideA during vanilla rollOn (art still at 0) stores 1, the shown state");
	h.hzTgHidden.push({ d: header, v: true, a: 0 });
	h.hz38GiveBackVanilla();
	expect(header.alpha === 1 && header.visible === true, "name / panel come back (not left at the captured rollOn 0)");
	expect(glyph.alpha === 1 && glyph.visible === true, "TALK / TRADE glyph and label come back");
	expect(unused.visible === false, "unused key box stays hidden");
}

{
	const { h, holder } = makeHost();
	holder.alpha = 0.4;
	h.hzTgSnap(holder);
	holder.alpha = 1;
	h.hz38GiveBackVanilla();
	expect(holder.alpha === 0.4, "KeepHold / generic snap still restores the real captured alpha, not a forced 1");
}

console.log("hover vanilla restore: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
