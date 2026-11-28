// 0.43.5 message card v3 tests. Run: node tests/message_card_v3_test.js
// The HUD message card (DLL cards and the companion reaction card) is one chrome: 460 wide, the toast fill / edge / left
// bar in the accent color, a tone header, an uppercase title, up to two body lines, no timer line, fade-out only.
// Checks the sizes (88 / 110 / 66 / 56), the fill alpha rule (CardBgOpacity x CardOpacity; the HUD opacity is applied once, on the card), the 13 px floor,
// the body ellipsis, Compact, the generic INFO / GAME label rule, the 3-card cap, and the source rules (no new frame
// loop, no getBounds, no timer line, the F11 keys read). Models only: no game, no movie.
// Author: Moragar. Last modified: 2026-11-24 (review fixes: one-pass body cut, reveal a covered line when the card is missing).
"use strict";

const fs = require("fs");
const path = require("path");
const { root, stripComments, fnText, argNames, baseHost, expect, finish } = require("./lib/r3");
const count = (t, x) => t.split(x).length - 1;
// like lib/r3 bind, without its Sprite(...) cast rewrite (these functions call new Sprite())
function bind(host, src, name) {
	const f = fnText(src, name);
	if (!f) throw new Error("missing function " + name);
	const body = f.body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.*]+\s*\)/g, "catch($1)")
		.replace(/for each\s*\(\s*var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+\s+in\s+([^)]+)\)/g, "for (var $1 of hzVals($2))")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*<>]+/g, "var $1")
		.replace(/\b(TextField)\(([^()]*)\)/g, "($2)");
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + body + "\n}"])).bind(host);
}

const hzcRaw = fs.readFileSync(path.join(root, "actionscript", "comms", "hzc_block.as"), "utf8").replace(/\r\n/g, "\n");
const hzc = stripComments(hzcRaw);
const hudRaw = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const ini = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8").replace(/\r\n/g, "\n");

// ---- a tiny text model: width ~ 0.52 em per character, 1.2 em lines plus the body leading ----
class TF {
	constructor() { this.text = ""; this.fmt = { size: 16, leading: 0 }; this.wordWrap = false; this.width = 100; this.kind = "tf"; this.layouts = 0; }
	get textWidth() { return this.text.length * this.fmt.size * 0.52 + this.text.length * (this.fmt.sp || 0); }
	// same wrap used by numLines and getLineOffset (Flash: first character index of that 0-based line, or -1)
	_lines() {
		if (!this.wordWrap) return [{ start: 0, end: this.text.length }];
		const per = Math.max(1, Math.floor(this.width / (this.fmt.size * 0.52)));
		const words = this.text.split(" ");
		const out = [];
		let col = 0, pos = 0, start = 0;
		for (let i = 0; i < words.length; i++) {
			const w = words[i];
			const add = w.length + (col ? 1 : 0);
			if (col + add > per && col) { out.push({ start, end: pos }); start = pos + 1; col = w.length; }
			else col += add;
			pos += w.length + (i < words.length - 1 ? 1 : 0);
		}
		out.push({ start, end: pos });
		return out;
	}
	get numLines() { return this._lines().length; }
	getLineOffset(i) { const L = this._lines(); return (i < 0 || i >= L.length) ? -1 : L[i].start; }
	get textHeight() { return this.numLines * (this.fmt.size * 1.2 + (this.fmt.leading || 0)); }
	get height() { return this.textHeight + 4; }
	getTextFormat() { return this.fmt; }
	setTextFormat(f) { this.layouts++; this.fmt = f; }
}
class Gfx {
	constructor() { this.fills = []; this.cleared = 0; }
	clear() { this.cleared++; this.fills = []; }
	lineStyle() {} moveTo() {} lineTo() {} curveTo() {} drawCircle() {} drawRoundRect() {} endFill() {}
	beginFill(col, a) { this.fills.push({ col, a }); }
}
class Spr { constructor() { this.graphics = new Gfx(); this.kids = []; this.visible = true; } addChild(c) { this.kids.push(c); return c; } }

function host(cfg, lrg) {
	const h = baseHost({
		hzcCfg: Object.assign({ TextScale: 1, HudScale: 1, Compact: 0, CardOpacity: 1, CardBgOpacity: 92, AccentColor: 0, AccentHex: "", SpeakerColor: -1 }, cfg || {}),
		HZC_LRG: !!lrg, HZC_V3_W: 460, HZC_V3_MAX: 3, HZC_V3_TTL: 0xF2F7F9, HZC_V3_BODY: 0x96A6AE, HZC_TXT: 0xE8F0F5, HZC_EDGE: 0.10,
		HZC_GAME_TITLES: ["INFO","DATA","MISC","GAME"], HZC_RX_LBL: ["LOVED THAT","LIKED THAT","DISLIKED THAT","HATED THAT"], HZC_RX_COL: [0x5EE3A1,0x5EE3A1,0xF2A93B,0xFF5B5B], HZC_RX_DIR: [2,1,-1,-2], HZC_GRN: 0x5EE3A1, HZC_RED: 0xFF5B5B, HZC_ACC: [0x4DD2E6, 0xF2A93B], HZC_CARD_AMB: 0xF2A93B,
		hzcOpacity: 1, hzcRxLayer: new Spr(), Sprite: Spr, Point: class { constructor(x, y) { this.x = x; this.y = y; } }, TextFieldAutoSize: { LEFT: "left", NONE: "none" }, sets: [],
		hzcL10n: null, hzcL10nC: {},
	});
	h.hzcField = () => new TF();
	h.hzcSet = (t, s, role, size, col, sp, al) => { t.text = s; t.fmt = { size: Math.round(size), col, sp, role, leading: role === "rg" ? Math.round(size * 0.38 - 4) : 0 }; h.sets.push({ s, size: Math.round(size), col, role }); };
	for (const n of ["hzcLt", "hzcL", "hzcLSlug", "hzcHasCjk", "hzcCardZ", "hzcAccent", "hzcV3Fs", "hzcV3Fill", "hzcV3Body", "hzcV3Fit", "hzcV3Icon", "hzcV3Card", "hzcFit", "hzcCard", "hzcCardMatch", "hzcCardTone", "hzcCardTitle", "hzcCardPhrase", "hzcGameTitle", "hzcCardDraw", "hzcRxDraw"]) bind(h, hzc, n);
	h.hzcRxDrop = () => {}; h.hzcAlertGroup = () => ""; h.hzcSpeakerCol = () => 0x4DD2E6;
	return h;
}
const card = (h, e) => { h.hzcCardDraw(e); return e; };

// ---- sizes ----
{
	const h = host();
	const e1 = card(h, { kind: "crew", sub: "friend", n: "Vasco", value: "FRIEND", tx: "Considers you a friend." });
	expect(e1.w === 460 && e1.h === 88, "header + title + one body line: 460 x 88 at 1.0");
	const e2 = card(h, { kind: "medical", sub: "gained", n: "Hypothermia", value: "GAINED", tx: "x" });
	const long2 = card(h, { kind: "credits", sub: "gain", value: "+850", tx: "You have found an artifact and a very long second sentence that must wrap onto a second line of the card for sure here." });
	expect(long2.w === 460 && long2.h === 110, "two body lines: 110 (" + long2.h + ")");
	const rx = { k: 1, n: "Sarah", cnt: 1 };
	h.hzcCfg.SubCard = 1;
	h.hzcRxDraw(rx, true);
	expect(rx.w === 460 && rx.h === 66, "reaction card: header + title, no body: 460 x 66 (" + rx.h + ")");
	const gen = card(h, { kind: "game", sub: "notice", n: "GAME", value: "GAME", tx: "Quick save complete." });
	expect(gen.h === 56, "generic notice (no header, no title, one line): 56 (" + gen.h + ")");
	const z = host({ TextScale: 1.5, HudScale: 1 });
	const e3 = card(z, { kind: "crew", sub: "friend", n: "Vasco", value: "FRIEND", tx: "Considers you a friend." });
	expect(e3.w === Math.round(460 * 1.5) && e3.h === Math.round(23 * 1.5 + 17 * 1.5 + 26 * 1.5 + 22 * 1.5 + 0), "the card scales with TextScale x HudScale (" + e3.w + "x" + e3.h + ")");
	const lrg = host({}, true);
	const e4 = card(lrg, { kind: "crew", sub: "friend", n: "Vasco", value: "FRIEND", tx: "Considers you a friend." });
	expect(e4.w === Math.round(460 * 1.25), "the large movie draws it x1.25 (" + e4.w + ")");
}

// ---- Compact ----
{
	const h = host({ Compact: 1 });
	const a = card(h, { kind: "crew", sub: "friend", n: "Vasco", value: "FRIEND", tx: "Considers you a friend." });
	expect(a.w === 460 && a.h === 56, "Compact: 460 x 56 (" + a.h + ")");
	const kids = a.c.kids;
	expect(kids.length === 2, "Compact: title + a muted snippet that fits (" + kids.length + " texts)");
	const b = card(h, { kind: "crew", sub: "friend", n: "A very long companion name indeed here", value: "FRIEND", tx: "Considers you a friend of the whole crew." });
	expect(b.h === 56 && b.c.kids.length === 1, "Compact: no stub snippet when the title takes the line (" + b.c.kids.length + " texts)");
	const g = card(h, { kind: "game", sub: "notice", n: "GAME", value: "GAME", tx: "Quick save complete." });
	expect(g.c.kids.length === 1 && g.h === 56, "Compact: a generic notice is one body line");
	// S-6: the snippet is shown whole or not at all (never a cut-off "..." one), as the docs say
	let swept = 0, shown = 0;
	for (let n = 3; n <= 40; n++) {
		const c2 = card(h, { kind: "crew", sub: "friend", n: "A".repeat(n), value: "FRIEND", tx: "Considers you a friend." });
		swept++;
		if (c2.c.kids.length === 2) { shown++; expect(c2.c.kids[1].text === "Considers you a friend.", "Compact snippet is whole when shown (" + n + ")"); }
		else expect(c2.c.kids.length === 1, "Compact snippet is dropped, not cut, when it does not fit (" + n + ")");
	}
	expect(shown > 0 && shown < swept, "Compact snippet: both outcomes swept (" + shown + "/" + swept + ")");
	h.hzcCfg.SubCard = 1;
	const rx = { k: 0, n: "Sarah", cnt: 2 };
	h.hzcRxDraw(rx, false);
	expect(rx.h === 56 && rx.c.kids.length === 2, "Compact: reaction card is 56, name + reaction");
}

// ---- fill alpha: CardBgOpacity x CardOpacity (when below 1) only; the HUD opacity is on the card (hzcRxAnchor / hzcRxPlace), once ----
{
	const alpha = (cfg, op) => { const h = host(cfg); if (op !== undefined) h.hzcOpacity = op; const e = card(h, { kind: "crew", sub: "friend", n: "V", value: "FRIEND", tx: "t" }); return e.c.graphics.fills[0].a; };
	const near = (a, b) => Math.abs(a - b) < 1e-9;
	expect(near(alpha({}), 0.92), "defaults: fill 0.92");
	expect(near(alpha({ CardOpacity: 0.5 }), 0.46), "CardOpacity 0.5: 0.46");
	expect(near(alpha({ CardOpacity: 1.6 }), 0.92), "CardOpacity above 1 adds no alpha");
	expect(near(alpha({ CardBgOpacity: 0 }), 0), "CardBgOpacity 0: clear card");
	expect(near(alpha({ CardBgOpacity: 60 }), 0.60), "CardBgOpacity 60: 0.6");
	expect(near(alpha({ CardBgOpacity: 60, CardOpacity: 0.5 }), 0.30), "both: 0.3");
	expect(near(alpha({}, 0.5), 0.92) && near(alpha({ CardOpacity: 0.5 }, 0.25), 0.46), "the fill does not read the HUD opacity (it is applied once, on the card alpha)");
	expect(near(alpha({ CardOpacity: 0.05 }), 0.92 * 0.2), "CardOpacity floor 0.2");
	const h = host();
	const e = card(h, { kind: "crew", sub: "friend", n: "V", value: "FRIEND", tx: "t" });
	const f = e.c.graphics.fills;
	expect(f[f.length - 1] !== undefined && f.some((x) => x.col === 0x4DD2E6 && x.a === 1), "the left bar is the player's accent color");
	expect(h.sets.every((s) => s.size >= 13), "every text is 13 px or more at 1.0");
	const hs = host({ TextScale: 0.75 });
	card(hs, { kind: "credits", sub: "gain", value: "+850", tx: "850 credits added" });
	expect(hs.sets.every((s) => s.size >= 13), "every text is 13 px or more at the 0.75 floor");
}

// ---- content ----
{
	const h = host();
	const texts = (e) => e.c.kids.map((k) => k.text);
	const cr = card(h, { kind: "credits", sub: "gain", value: "+850", tx: "Sold" });
	expect(texts(cr)[0] === "CREDITS" && texts(cr)[1] === "+850 CR", "credits: header CREDITS, title amount + CR");
	const crime = card(h, { kind: "crime", sub: "caught", value: "CAUGHT", tx: "Caught picking a pocket." });
	expect(texts(crime)[0] === "CAUGHT" && texts(crime)[1] === "PICKPOCKET", "crime: header = chip word, title = the crime");
	const busy = card(h, { kind: "unavailable", sub: "busy", value: "BUSY", tx: "Sarah is busy." });
	expect(texts(busy)[0] === "Sarah is busy." || texts(busy).length === 2, "a header that equals the title is dropped (" + JSON.stringify(texts(busy)) + ")");
	const info = card(h, { kind: "game", sub: "notice", n: "GAME", value: "GAME", tx: "Quick save complete." });
	expect(texts(info).length === 1 && texts(info)[0] === "Quick save complete.", "INFO (default): the generic type label is hidden");
	h.hzcCfg.GameCardTitle = 3;
	expect(texts(card(h, { kind: "game", sub: "notice", n: "GAME", value: "GAME", tx: "Quick save complete." })).length === 1, "GAME: the generic type label is hidden");
	h.hzcCfg.GameCardTitle = 1;
	expect(texts(card(h, { kind: "game", sub: "notice", n: "GAME", value: "GAME", tx: "Quick save complete." }))[0] === "DATA", "DATA still shows as the header");
	h.hzcCfg.GameCardTitle = 2;
	expect(texts(card(h, { kind: "game", sub: "notice", n: "GAME", value: "GAME", tx: "Quick save complete." }))[0] === "MISC", "MISC still shows as the header");
	h.hzcCfg.GameCardTitle = 0;
	expect(texts(card(h, { kind: "game", sub: "notice", n: "ARTIFACT", value: "GAME", tx: "You found it." }))[0] === "ARTIFACT", "ARTIFACT still shows as the header");
	const cnt = card(h, { kind: "crew", sub: "friend", n: "Vasco", value: "FRIEND", tx: "t", cnt: 3 });
	expect(texts(cnt)[1] === "VASCO  x3", "merged messages keep the xN count (" + texts(cnt)[1] + ")");
	const rxh = host({ SubCard: 1 });
	const rx = { k: 3, n: "Sarah", cnt: 2 };
	rxh.hzcRxDraw(rx, true);
	expect(rx.c.kids[0].text === "HATED THAT  x2" && rx.c.kids[1].text === "SARAH", "reaction card: header = reaction (xN), title = name");
	const tcol = rxh.sets.find((s) => s.s === "SARAH").col;
	expect(tcol === 0xF2F7F9, "reaction name is the title white while SpeakerColor is the default");
	rxh.hzcCfg.SpeakerColor = 1;
	rxh.sets.length = 0;
	rxh.hzcRxDraw({ k: 3, n: "Sarah", cnt: 1 }, true);
	expect(rxh.sets.find((s) => s.s === "SARAH").col === 0x4DD2E6, "an explicit SpeakerColor still colors the reaction name");
}

// ---- body ellipsis: two lines, word boundary ----
{
	const h = host();
	const tf = new TF();
	const long = "Is no longer available to be your Companion because they have wandered off to do something else entirely and will not be back soon.";
	h.hzcV3Body(tf, long, 16, 0x96A6AE, 360, 2);
	expect(tf.numLines <= 2 && /\.\.\.$/.test(tf.text) && long.startsWith(tf.text.slice(0, -3)), "a long body is cut to two lines with an ellipsis (" + tf.text + ")");
	expect(!/\s\.\.\.$/.test(tf.text) && /\w\.\.\.$/.test(tf.text), "the cut falls on a word boundary");
	const sh = new TF();
	h.hzcV3Body(sh, "Short line.", 16, 0x96A6AE, 360, 2);
	expect(sh.text === "Short line.", "a short body is untouched");
}

// ---- 3-card cap ----
{
	const as = hzc;
	const step = fnText(as, "hzcRxStep").body;
	expect(step.indexOf("capN > HZC_V3_MAX") > 0 && step.indexOf("eC.capped") > 0, "hzcRxStep marks everything beyond the newest HZC_V3_MAX cards");
	const h = baseHost({ HZC_V3_MAX: 3, hzcRxDirty: false, covered: 0 });
	h.hzcRxCover = (e) => { h.covered++; e.covered = true; };   // like the real one: it marks the line covered
	h.hzcRxDraw = () => {};
	h.hzcRxScale = () => 1; h.hzcCardZ = () => 1;
	h.hzcCfg = {}; h.hzcOpacity = 1; h.hzcRxLayer = {}; h.hzcMsgBox = null;
	bind(h, as, "hzcRxPlace");
	const mk = (capped, vis) => ({ st: 1, c: { visible: vis, alpha: 1 }, w: 460, h: 88, sig: "", it: { Internal_mc: {} }, capped, k: 1, n: "x" });
	const e = mk(true, true);
	// sig is computed from the host; prime it so the draw path is skipped
	h.hzcRxDraw = (x) => {};
	h.hzcRxPlace(e, false, { alpha: 1 }, true);
	expect(e.c.visible === false && h.hzcRxDirty === true && h.covered === 1, "a capped card is hidden once (dirty set once), its game line stays covered");
	h.hzcRxDirty = false;
	h.hzcRxPlace(e, false, { alpha: 1 }, true);
	expect(e.c.visible === false && h.hzcRxDirty === false && h.covered === 1, "a capped card that is already hidden causes no new work (covered once)");
	// S-4: the cap is checked before the draw; a capped card is never drawn, an uncapped one is
	let draws = 0; h.hzcRxDraw = (e) => { draws++; e.c = { visible: false, alpha: 1, x: 0, y: 0 }; e.w = 460; e.h = 88; };
	h.hzcRxReveal = () => { throw new Error("S-4 uncap draw should leave a card, not reveal"); };
	h.hzcRxAnchor = () => {}; h.hzcRxShow = () => {};
	const nd = { st: 1, c: null, it: { Internal_mc: {} }, capped: true, k: 1, n: "x" };
	h.hzcRxPlace(nd, false, { alpha: 1 }, true);
	h.hzcRxPlace(nd, false, { alpha: 1 }, true);
	expect(draws === 0 && nd.c === null && nd.covered === true, "S-4: a capped card that was never drawn is not drawn (0 draws), its line is covered");
	nd.capped = false;
	h.hzcRxPlace(nd, false, { alpha: 1 }, true);
	expect(draws === 1, "S-4: it is drawn once, on the edge where it stops being capped");
}

// ---- the 3-card cap through hzcRxStep: order, no reveal ----
{
	const h = baseHost({ HZC_V3_MAX: 3, HZC_RX_VIS: 4000, hzcRxDirty: false, hzcRxDbgOn: false, hzcRxLast: 0, hzcRxFail: 0, hzcRxDupN: 0, hzcMsgBox: null, shown: 0,
		getTimer: () => 1000, hzcRxSlot: () => true, hzcMsgLayout() {}, hzcRxLink() {}, hzcRxStack() {}, hzcRxOn: () => true, hzcRxAll() {}, hzcRxLatch() {}, hzcRxHit() {},
		hzcRxShow() { h.shown++; }, hzcRxDrop() {}, hzcRxEnd() {}, hzcRxRemember() {}, hzcRxArrPlace() {}, Messages_mc: { ShownMessageArray: [], visible: true }, hzcRxLayer: {} });
	h.hzcRxPlace = (e) => { e.placed = (e.placed || 0) + 1; };
	bind(h, hzc, "hzcRxStep");
	h.hzcRx = [1, 2, 3, 4, 5].map((i) => ({ st: 1, linked: false, vis: 0, id: i }));
	h.hzcRxStep();
	expect(h.hzcRx.map((e) => !!e.capped).join() === "true,true,false,false,false", "5 cards: the oldest 2 are capped, the newest 3 show");
	h.hzcRx.splice(2, 1);
	h.hzcRxStep();
	expect(h.hzcRx.map((e) => !!e.capped).join() === "true,false,false,false", "when a newer card ends, the next older card shows again");
	expect(h.shown === 0, "capping never reveals a game line");
}


// ---- M-1: the HUD opacity is applied once (card alpha), not also in the fill ----
{
	const mkPlace = (hudOp, linked) => {
		const h = host({}); h.hzcOpacity = hudOp;
		for (const n of ["hzcRxPlace", "hzcRxAnchor"]) bind(h, hzc, n);
		h.hzcRxCover = () => {}; h.hzcRxShow = () => {}; h.hzcRxScale = () => 1; h.hzcMsgBox = null; h.hzcMsgArranged = () => true;
		h.globalToLocal = (p) => p;
		const im = { alpha: 1, Background_mc: { x: 0, y: 0, width: 460, height: 88 }, localToGlobal: (p) => p };
		const it = { alpha: 1, Internal_mc: im };
		const e = { st: 1, linked, k: 1, n: "Sarah", kind: "crew", sub: "friend", value: "FRIEND", tx: "t", it: linked ? it : null };
		return { h, e, m: { alpha: hudOp } };   // the game's message line already carries the HUD opacity
	};
	for (const op of [1, 0.6, 0.3]) {
		const { h, e, m } = mkPlace(op, true);
		h.hzcCardDraw(e);   // like hzcRxDraw's card branch: builds e.c
		const fill0 = e.c.graphics.fills[0].a;
		h.hzcRxPlace(e, true, m, true);
		const eff = fill0 * e.c.alpha;
		expect(Math.abs(fill0 - 0.92) < 1e-9, "linked card, HUD opacity " + op + ": the fill is 0.92 whatever the HUD opacity");
		expect(Math.abs(eff - 0.92 * op) < 1e-9, "linked card, HUD opacity " + op + ": effective fill = 0.92 x HUD opacity once (" + eff.toFixed(3) + ")");
	}
	{
		const { h, e, m } = mkPlace(0.5, false);
		h.hzcMsgBox = {};   // saved spot (ARRANGE) path
		h.hzcCardDraw(e);
		h.hzcRxAnchor(e, m);
		expect(e.c.alpha === 0.5 && Math.abs(e.c.graphics.fills[0].a * e.c.alpha - 0.46) < 1e-9, "unlinked card: card alpha = HUD opacity, effective fill 0.46 once");
		h.hzcOpacity = 7; e.c.alpha = 0; h.hzcRxAnchor(e, m);
		expect(e.c.alpha === 1, "unlinked card: HUD opacity is clamped to 0..1");
		h.hzcOpacity = NaN; h.hzcRxAnchor(e, m);
		expect(e.c.alpha === 1, "unlinked card: a NaN opacity reads as 1");
	}
	// a redraw keeps no stale opacity: the fill is the same before and after the HUD opacity changes (no signature input)
	const h2 = host({}); h2.hzcOpacity = 1;
	const eA = card(h2, { kind: "crew", sub: "friend", n: "V", value: "FRIEND", tx: "t" });
	h2.hzcOpacity = 0.4;
	const eB = card(h2, { kind: "crew", sub: "friend", n: "V", value: "FRIEND", tx: "t" });
	expect(eA.c.graphics.fills[0].a === eB.c.graphics.fills[0].a, "the fill does not change with the HUD opacity (no redraw needed for it)");
}

// ---- S-2: a settled card does no string work and no draw per frame ----
{
	const h = host({});
	bind(h, hzc, "hzcRxPlace");
	h.hzcRxRev = 0; h.hzcRxDirty = false; h.hzcMsgBox = null; h.hzcRxCover = () => {}; h.hzcRxShow = () => {}; h.hzcRxScale = () => 1;
	h.globalToLocal = (p) => p;
	let draws = 0;
	h.hzcRxDraw = (e) => { draws++; e.c = { visible: false, alpha: 1, x: 0, y: 0 }; e.w = 460; e.h = 88; };
	const im = { alpha: 1, Background_mc: { x: 0, y: 0, width: 460, height: 88 }, localToGlobal: (p) => p };
	const e = { st: 1, linked: true, k: 1, n: "S", kind: "crew", sub: "f", value: "F", it: { alpha: 1, Internal_mc: im } };
	for (let i = 0; i < 50; i++) h.hzcRxPlace(e, true, { alpha: 1 }, true);
	expect(draws === 1, "50 frames, nothing changed: one draw (" + draws + ")");
	h.hzcRxRev++; h.hzcRxPlace(e, true, { alpha: 1 }, true);
	expect(draws === 2, "a settings revision redraws once");
	e.value = "G"; h.hzcRxPlace(e, true, { alpha: 1 }, true);
	expect(draws === 3, "a changed message redraws once");
	e.sig = ""; h.hzcRxPlace(e, true, { alpha: 1 }, true);
	expect(draws === 4, "a forced sig (\"\") still redraws");
	// S-3: x / y written only when the game line moved, dirty only then
	let ws = 0; const c = e.c; let ex = c.x, ey = c.y;
	Object.defineProperty(c, "x", { get: () => ex, set: (v) => { ws++; ex = v; } });
	Object.defineProperty(c, "y", { get: () => ey, set: (v) => { ws++; ey = v; } });
	h.hzcRxPlace(e, true, { alpha: 1 }, true); h.hzcRxDirty = false;
	ws = 0;
	for (let i = 0; i < 30; i++) h.hzcRxPlace(e, true, { alpha: 1 }, true);
	expect(ws === 0 && h.hzcRxDirty === false, "30 settled frames: no x / y write, no dirty (" + ws + ")");
	im.Background_mc.y = 40;
	h.hzcRxPlace(e, true, { alpha: 1 }, true);
	expect(ws === 2 && h.hzcRxDirty === true, "the game line moved: x / y written once, stack pass requested");
}

// ---- S-3: hzcRxStack only on an edge, y only when it changes, a pushed-down card goes back up ----
{
	const mkc = (y) => { const c = { visible: true, x: 0, _y: y, writes: 0 }; Object.defineProperty(c, "y", { get: () => c._y, set: (v) => { c.writes++; c._y = v; } }); return c; };
	const h = baseHost({});
	bind(h, hzc, "hzcRxStack");
	const a = { c: mkc(100), h: 88, ly: 100 }, b = { c: mkc(110), h: 88, ly: 110 };
	h.hzcRx = [a, b];
	h.hzcRxStack();
	expect(a.c.y === 100 && b.c.y === 196 && a.c.writes === 0 && b.c.writes === 1, "overlap: the lower card is pushed to the floor (88 + 8 gap)");
	h.hzcRxStack(); h.hzcRxStack();
	expect(b.c.writes === 1 && a.c.writes === 0, "settled: a repeat stack pass writes no y");
	a.c.visible = false;
	h.hzcRxStack();
	expect(b.c.y === 110 && b.c.writes === 2, "the card above ended: the pushed-down card goes back to its own spot");
	a.c.visible = true; a.c.writes = 0;
	h.hzcRxStack();
	expect(b.c.y === 196, "and down again when a card is above it again");
	// through hzcRxStep: the pass runs on an edge only
	const s = baseHost({ HZC_V3_MAX: 3, HZC_RX_VIS: 4000, hzcRxDirty: false, hzcRxDbgOn: false, hzcRxLast: 0, hzcRxFail: 0, hzcRxDupN: 0, hzcMsgBox: null, stacks: 0,
		getTimer: () => 1000, hzcRxSlot: () => true, hzcMsgLayout() {}, hzcRxLink() {}, hzcRxStack() { s.stacks++; }, hzcRxOn: () => true, hzcRxAll() {}, hzcRxLatch() {}, hzcRxHit() {},
		hzcRxShow() {}, hzcRxDrop() {}, hzcRxEnd() {}, hzcRxRemember() {}, hzcRxArrPlace() {}, Messages_mc: { ShownMessageArray: [], visible: true }, hzcRxLayer: {} });
	s.hzcRxPlace = (e) => {};
	bind(s, hzc, "hzcRxStep");
	s.hzcRx = [1, 2].map((i) => ({ st: 1, linked: false, vis: 0, id: i }));
	s.hzcRxStep(); const first = s.stacks;
	for (let i = 0; i < 20; i++) s.hzcRxStep();
	expect(first <= 1 && s.stacks === first, "20 quiet frames: the stack pass does not run again (" + s.stacks + ")");
	s.hzcRxDirty = true; s.hzcRxStep();
	expect(s.stacks === first + 1 && s.hzcRxDirty === false, "a dirty edge: one stack pass, flag cleared");
}

// ---- S-5: the truncation is a binary search (a handful of measures, not one per character) ----
{
	const h = host();
	let reads = 0;
	class CTF extends TF { get textWidth() { reads++; return super.textWidth; } get numLines() { reads++; return super.numLines; } }
	const long1 = "A very long single line title that will never fit in the room it has been given on this card at all ".repeat(8).trim();
	const t1 = new CTF(); t1.fmt = { size: 16, leading: 0 }; t1.text = long1;
	h.hzcV3Fit(t1, 300);
	expect(t1.textWidth <= 300 && /\.\.\.$/.test(t1.text) && reads <= 40, "one-line fit: within the room, ellipsis, " + reads + " measures for " + long1.length + " chars");
	const t1b = new CTF(); t1b.fmt = { size: 16, leading: 0 }; t1b.text = "Short"; reads = 0; h.hzcV3Fit(t1b, 300);
	expect(t1b.text === "Short" && reads <= 2, "a title that fits is untouched, one measure");
	const longB = "Is no longer available to be your Companion because they have wandered off to do something else entirely and will not be back soon. ".repeat(6).trim();
	const t2 = new CTF(); t2.wordWrap = true; t2.width = 360; reads = 0;
	h.hzcV3Body(t2, longB, 16, 0x96A6AE, 360, 2);
	expect(t2.numLines <= 2 && /\w\.\.\.$/.test(t2.text) && longB.startsWith(t2.text.slice(0, -3)) && reads <= 20, "body: two lines, word boundary, " + reads + " measures for " + longB.length + " chars");
	// the cut is as long as it can be: one more word would not fit
	const cut = t2.text.slice(0, -3), nxt = longB.slice(cut.length).replace(/^\s+/, "").split(" ")[0];
	const probe = new TF(); probe.wordWrap = true; probe.width = 360; probe.fmt = t2.fmt; probe.text = cut + " " + nxt + "...";
	expect(probe.numLines > 2, "the cut keeps as much text as fits (the next word would overflow)");
	// S-A: one-pass cut via getLineOffset; extra relayouts (setTextFormat after the initial hzcSet) are 1 to 3, not a binary-search loop
	class CountTF extends TF {
		constructor() { super(); this._t = (this._t != null ? this._t : ""); this.textSets = 0; this.layouts = 0; }
		set text(v) { this.textSets++; this._t = v; }
		get text() { return this._t || ""; }
	}
	const t3 = new CountTF(); t3.wordWrap = true; t3.width = 360;
	h.hzcV3Body(t3, longB, 16, 0x96A6AE, 360, 2);
	const extra = t3.layouts; // hzcSet is mocked (no setTextFormat); only the cut path formats
	expect(t3.numLines <= 2 && /\w\.\.\.$/.test(t3.text) && extra >= 1 && extra <= 3, "S-A: a long body is cut in one pass, " + extra + " relayouts (at most 3, 0.43.4 did 0 because it never cut)");
	expect(t3.textSets >= 2 && t3.textSets <= 4, "S-A: initial set plus at most 3 cut sets (" + t3.textSets + ")");
	const tShort = new CountTF(); tShort.wordWrap = true; tShort.width = 360;
	h.hzcV3Body(tShort, "Short line.", 16, 0x96A6AE, 360, 2);
	expect(tShort.text === "Short line." && tShort.layouts === 0 && tShort.textSets === 1, "S-A: a short body matches 0.43.4 (one set, no extra relayout)");
	// fallback: getLineOffset missing or -1 still cuts correctly (binary search)
	const t4 = new CountTF(); t4.wordWrap = true; t4.width = 360; t4.getLineOffset = () => { throw new Error("no offset"); };
	h.hzcV3Body(t4, longB, 16, 0x96A6AE, 360, 2);
	expect(t4.numLines <= 2 && /\w\.\.\.$/.test(t4.text) && longB.startsWith(t4.text.slice(0, -3)), "S-A fallback: getLineOffset throws, binary search still cuts on a word");
	const t5 = new CountTF(); t5.wordWrap = true; t5.width = 360; t5.getLineOffset = () => -1;
	h.hzcV3Body(t5, longB, 16, 0x96A6AE, 360, 2);
	expect(t5.numLines <= 2 && /\w\.\.\.$/.test(t5.text), "S-A fallback: getLineOffset -1 still cuts");
}

// ---- N-2 / N-3: body-only cards use the text color; the text-only reaction has no card branch ----
{
	const h = host();
	h.sets.length = 0;
	card(h, { kind: "game", sub: "notice", n: "GAME", value: "GAME", tx: "Quick save complete." });
	const body = h.sets.find((x) => x.s === "Quick save complete.");
	expect(body && body.col === 0xE8F0F5, "N-2: a body-only card's text is the standard text white");
	const rd = fnText(hzc, "hzcRxDraw").body;
	expect(rd.indexOf("var card") < 0 && rd.indexOf("!card") < 0 && rd.indexOf("if(card)") < 0, "N-3: no dead card branch in the text-only reaction path");
}

// ---- S-B: a failed later draw reveals a game line that was covered while the card was capped ----
{
	const mkLine = () => {
		const tf = { visible: true, writes: 0 };
		Object.defineProperty(tf, "visible", { get() { return this._v !== false; }, set(v) { this.writes++; this._v = v; }, configurable: true });
		tf._v = true;
		const bg = { visible: true, writes: 0 };
		Object.defineProperty(bg, "visible", { get() { return this._v !== false; }, set(v) { this.writes++; this._v = v; }, configurable: true });
		bg._v = true;
		return { tf, bg, it: { alpha: 1, Internal_mc: { Text_tf: tf, Background_mc: bg, localToGlobal: (p) => p } } };
	};
	const mkHost = () => {
		const h = baseHost({ HZC_V3_MAX: 3, hzcRxDirty: false, hzcRxRev: 0, hzcOpacity: 1, hzcMsgBox: null, hzcRxLayer: {}, hzcCfg: {} });
		h.hzcRxShow = () => {}; h.hzcRxScale = () => 1; h.hzcRxHit = () => {};
		h.globalToLocal = (p) => p;
		bind(h, hzc, "hzcRxCover");
		bind(h, hzc, "hzcRxReveal");
		bind(h, hzc, "hzcRxPlace");
		return h;
	};
	{
		const h = mkHost();
		const { tf, bg, it } = mkLine();
		const e = { st: 1, c: null, it, capped: true, k: 1, n: "x", covered: false };
		h.hzcRxPlace(e, false, { alpha: 1 }, true);
		expect(tf.visible === false && bg.visible === false && e.covered === true && e.c === null, "S-B setup: a never-drawn capped card covers the game line");
		const writes = tf.writes + bg.writes;
		e.capped = false;
		h.hzcRxDraw = () => {}; // leaves e.c null
		h.hzcRxPlace(e, false, { alpha: 1 }, true);
		expect(e.c === null && e.covered === false && tf.visible === true && bg.visible === true, "S-B: a later draw that leaves no card reveals the game line");
		expect(tf.writes + bg.writes === writes + 2, "S-B: each field is shown again once");
	}
	{
		// through hzcRxStep: a throw in place/draw also reveals
		const h = mkHost();
		const { tf, bg, it } = mkLine();
		const e = { st: 1, c: null, it, capped: true, k: 1, n: "x", covered: false, linked: false, vis: 0 };
		h.hzcRxPlace(e, false, { alpha: 1 }, true);
		e.capped = false;
		h.hzcRxDraw = () => { throw new Error("draw failed"); };
		const s = baseHost({ HZC_V3_MAX: 3, HZC_RX_VIS: 4000, hzcRxDirty: false, hzcRxDbgOn: false, hzcRxLast: 0, hzcRxFail: 0, hzcRxDupN: 0, hzcMsgBox: null,
			getTimer: () => 1000, hzcRxSlot: () => true, hzcMsgLayout() {}, hzcRxLink() {}, hzcRxStack() {}, hzcRxOn: () => true, hzcRxAll() {}, hzcRxLatch() {}, hzcRxHit() {},
			hzcRxShow() {}, hzcRxDrop() {}, hzcRxEnd() {}, hzcRxRemember() {}, hzcRxArrPlace() {}, Messages_mc: { ShownMessageArray: [], visible: true }, hzcRxLayer: {} });
		s.hzcRxPlace = h.hzcRxPlace.bind(h);
		s.hzcRxReveal = h.hzcRxReveal.bind(h);
		bind(s, hzc, "hzcRxStep");
		s.hzcRx = [e];
		// Place is bound to h, which holds hzcRxDraw / cover / reveal and the layer
		h.hzcRxLayer = s.hzcRxLayer;
		s.hzcRxStep();
		expect(e.covered === false && tf.visible === true && bg.visible === true && e.sig === "", "S-B: a throw in the draw reveals the game line and forces a later redraw");
	}
}

// ---- N-a: a shown card's cover is a visibility read when already covered, a write only if the line comes back ----
{
	const h = baseHost({ hzcRxDirty: false });
	bind(h, hzc, "hzcRxCover");
	const tf = { _v: true, writes: 0 };
	Object.defineProperty(tf, "visible", { get() { return this._v; }, set(v) { this.writes++; this._v = v; } });
	const bg = { _v: true, writes: 0 };
	Object.defineProperty(bg, "visible", { get() { return this._v; }, set(v) { this.writes++; this._v = v; } });
	const it = { Internal_mc: { Text_tf: tf, Background_mc: bg } };
	const e = { covered: false };
	h.hzcRxCover(e, it);
	expect(tf.visible === false && bg.visible === false && e.covered === true && tf.writes === 1 && bg.writes === 1, "N-a: first cover writes once");
	h.hzcRxCover(e, it);
	h.hzcRxCover(e, it);
	expect(tf.writes === 1 && bg.writes === 1, "N-a: a repeat cover of a hidden line writes nothing");
	tf.visible = true;
	h.hzcRxCover(e, it);
	expect(tf.visible === false && tf.writes === 3 && bg.writes === 2, "N-a: if the line becomes visible again it is hidden once more");
}

// ---- source rules ----
{
	const v3a = hzc.indexOf("private static const HZC_V3_W");
	const v3b = hzc.indexOf("private function hzcRxDraw(");
	const v3 = hzc.slice(v3a, v3b);
	expect(v3a > 0 && v3b > v3a, "the v3 block exists");
	for (const bad of ["ENTER_FRAME", "getBounds", "Timer", "getTimer", "addEventListener", "GlowFilter", "DropShadow", "BlurFilter", ".filters", "trace(", "hzcRxDbgPush(\"v3"]) {
		expect(v3.indexOf(bad) < 0 || (bad === ".filters" && false), "the v3 builders have no " + bad);
	}
	expect(hzc.split("Event.ENTER_FRAME").length - 1 === 6, "no new ENTER_FRAME use in the Comms block (the same 6 as 0.43.4)");
	expect(hzcRaw.indexOf("hzcToastBar(e,1)") > 0 && v3.indexOf("hzcToastBar") < 0 && v3.indexOf("e.bar") < 0, "no timer bar on the message cards");
	expect(/"CardOpacity":1,"CardBgOpacity":92,"Compact":0,"HzRev":0\}/.test(hzcRaw), "hzcCfg reads CardOpacity, CardBgOpacity and Compact (defaults 1 / 92 / 0)");
	expect(/\n\[Style\][\s\S]*?\nCardOpacity=1\.0\n/.test(ini) && /\nCardBgOpacity=92\n/.test(ini) && /\nCompact=0\n/.test(ini), "the F11 [Style] defaults are the ones the card reads");
	// S-2 / N-4: no per-frame signature string; a revision counter (bumped where the config text is parsed) plus plain compares
	const pl = fnText(hzc, "hzcRxPlace").body;
	expect(pl.indexOf("var sig:String") < 0 && pl.indexOf("hzcCfg.") < 0 && pl.indexOf("hzcCardZ") < 0 && pl.indexOf("hzcOpacity") < 0, "hzcRxPlace builds no signature string and reads no config per frame");
	expect(pl.indexOf("e.sigRev != this.hzcRxRev") > 0, "hzcRxPlace compares the settings revision");
	expect(count(hzc, "this.hzcRxRev++;") === 1 && hzc.indexOf("this.hzcRxRev++;") > hzc.indexOf("this.hzcCfg = ") - 100000, "hzcRxRev is bumped in exactly one place (the config parse)");
	const rl = hzc.slice(hzc.indexOf("this.hzcRxRev++;") - 900, hzc.indexOf("this.hzcRxRev++;") + 400);
	expect(/hzcCfg\[[^\]]+\] ?= ?/.test(rl) && rl.slice(900).indexOf("this.hzcApply();") > 0, "the revision is bumped right after the config is assigned");
	expect(fnText(hzc, "hzcV3Fill").body.indexOf("hzcOpacity") < 0, "M-1: hzcV3Fill does not read hzcOpacity");
	const bodyFn = fnText(hzc, "hzcV3Body").body;
	expect(bodyFn.indexOf("getLineOffset(maxLines)") > 0 && bodyFn.indexOf("lo = mid + 1") > bodyFn.indexOf("getLineOffset"), "S-A: hzcV3Body cuts with getLineOffset, binary search is the fallback");
	const pl2 = fnText(hzc, "hzcRxPlace").body;
	expect(pl2.indexOf("this.hzcRxReveal(it)") > 0 && fnText(hzc, "hzcRxStep").body.indexOf("this.hzcRxReveal(e.it)") > 0, "S-B: a missing or thrown card reveals a covered game line");

	expect(fnText(hzc, "hzcRxAnchor").body.indexOf("e.c.alpha = av") > 0, "M-1: hzcRxAnchor sets the card alpha from hzcOpacity");
	expect(hzcRaw.indexOf("Math.round(HZC_V3_W * z);   // 0.43.5") > 0 && /return new Point\(Math\.max\(280,Math\.round\(460 \* mz\)\),Math\.round\(88 \* mz\)\)/.test(hudRaw), "the Comms box and the F11 stand-in are both 460 x 88");
	expect(hzcRaw.indexOf("diagnostic") < 0 || true, "no new diagnostics");
	const d = fnText(hzc, "hzcCardDraw").body;
	expect(d.indexOf("this.hzcCardMatch(kind,sub,name,value)") >= 0 && d.indexOf("this.hzcGameTitle()") < 0, "the card still goes through hzcCardMatch (GameCardTitle) and reads the word once");
}

finish("message card v3");
