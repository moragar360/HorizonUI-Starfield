// Horizon quick menu (0.43.3.0 batches f and i). Run: node tests/quickmenu_test.js
// Runs the production hzq* helpers from actionscript/favorites/hzq_main.as and hzq37_reader.as (types stripped) on a
// small host, and reads the sources, and checks:
//  1. no Q keying: no key code, no keyboard listener; every key text comes from ControlMapData vMappedEvents;
//  2. mouse: every Horizon display object is mouseEnabled = mouseChildren = false; the slots keep the game's hit area;
//  3. edge-only: no enterFrame, timer, getTimer or tree search; a redraw only from the ini read, font.marker,
//     FavoritesData, selection, assign and ControlMapData hooks;
//  4. the switch: QuickMenuHorizon=0 builds and draws nothing; hzqRestore puts every vanilla piece back;
//  5. [Style] parsing and the theme functions follow the HUD (accent, custom hex, card color, text tone);
//  6. the INI key: default.ini, HZ_SET_DEF, the HUD reader / writer / live apply, the CARDS row;
//  7. the file lists: the generated classes carry the block and the hooks, CRLF, lrg differs only in HZQ_LRG;
//  8. batch i: one box for all 12 slots (vanilla geometry, both scales), the icon fit (aspect kept, never larger,
//     reset to the game's transform first, so it never compounds; nothing loaded = the game's transform), the
//     icon-load edge (the game's handler first), the restore (transform and the game's tint), and the controller
//     close hint (mapped Cancel -> glyph or keycap text, unknown = no badge, never a "$" token).
// Author: Moragar. Last modified: 2026-11-19 (batch i).
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const rd = (rel) => fs.readFileSync(path.join(root, rel), "utf8").replace(/\r\n/g, "\n");
const main = rd("actionscript/favorites/hzq_main.as");
const reader = rd("actionscript/favorites/hzq37_reader.as");
const src = main + reader;
const hud = rd("actionscript/horizon_block.as");
const ini = rd("Interface/HorizonUI/HorizonUI.default.ini");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(s, name) {
	const re = new RegExp("(?:private|public|protected) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(s);
	if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1;
	let depth = 0;
	for (let p = brace; p < s.length; p++) {
		if (s[p] === "{") depth++;
		else if (s[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: s.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
const codeOnly = (s) => s.replace(/\/\/.*$/gm, "");
function toJs(s, name) {
	const f = fnText(s, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
	const b = f.body
		.replace(/for each\(var (\w+):[\w*.]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*.]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/([^.\w"])(HZQ_\w+|hzq37_\w+)\b/g, "$1this.$2")
		.replace(/ as (Array|FavoritesEntry)\b/g, "");
	return new Function(...params, b);
}
global.int = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)) | 0; };
global.uint = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (Math.floor(n) >>> 0); };
global.PlatformUtils = { PLATFORM_PC_KB_MOUSE: 0 };
// a few entries of the vanilla GlobalFunc.NameToTextMap (favoritesmenu.swf / _lrg, game 1.16.244)
global.GlobalFunc = { NameToTextMap: { Xenon_A: "A", Xenon_B: "B", Xenon_Start: "O", PSN_B: "d", PSN_A: "a", DPad_Up: "w", _Question: "R", PCUp: "\u2191" } };

const consts = {};
for (const m of src.matchAll(/private static const (HZQ_\w+|hzq37_\w+):\w+ = (.*);/g)) {
	let v = m[2].replace(/__HZQ_LRG__/, "false").replace(/String\.fromCharCode\(0xFEFF\)/, '"\\uFEFF"');
	consts[m[1]] = eval("(" + v + ")");
}
const FNS = ["hzq37Ws", "hzq37Trim", "hzq37Lines", "hzq37Hdr", "hzq37Alias", "hzq37KV", "hzqOnIni", "hzqParse", "hzqHex", "hzqPct",
	"hzqCardPal", "hzqAccPal", "hzqAccent", "hzqCardFill", "hzqLum", "hzqLight", "hzqDarkText", "hzqMix", "hzqIconCol", "hzqTextAccent",
	"hzqMainCol", "hzqKey", "hzqCtl", "hzqHideArt", "hzqHideInfoVan", "hzqRestore", "hzqFail", "hzqData", "hzqSel", "hzqSlot", "hzqOpen",
	"hzqRaw", "hzqPadKey", "hzqFit", "hzqIcB", "hzqFitAll", "hzqIcRestore", "hzqIcDone", "hzqIcHook", "hzqAssign"];
function clip(name, kids) {
	return { name: name, visible: true, alpha: 1, kids: kids || [], get numChildren() { return this.kids.length; }, getChildAt(i) { return this.kids[i]; },
		transform: { colorTransform: null }, scaleX: 1, scaleY: 1, x: 0, y: 0 };
}
function host(iniText) {
	const h = Object.assign({}, consts, { hzqOn: false, hzqOpened: false, hzqErr: false, hzqS: null, hzqKeys: {}, hzqKb: true, hzqCards: null,
		hzqHdr: null, hzqInf: null, hzqInfObj: null, hzqInfSel: false, hzqCtA: {}, hzqCtM: {}, hzqCtN: { id: 1 }, calls: [], FavoritesInfoA: [], selectedIndex: 0, selectedEntry: { sName: "A" } });
	for (const n of FNS) h[n] = toJs(src, n);
	h.hzq37IniRead = function (cb) { this.calls.push("read"); cb.call(this, iniText); };
	h.hzqBuild = function () { this.calls.push("build"); this.hzqCards = []; for (let i = 0; i < 12; i++) this.hzqCards.push({ s: { visible: true } }); };
	h.hzqRedraw = function () { this.calls.push("redraw"); };
	h.hzqCard = function (i) { this.calls.push("card" + i); };
	h.hzqInfo = function () { this.calls.push("info"); };
	h.hzqFontBegin = function () { this.calls.push("font"); };
	h.hzqGlyphOk = function () { return false; };
	h.hzqInfoSet = function () { this.calls.push("infoset"); };
	// 0.43.5 Extended Mode helpers: off (the default), so the 0.43.3 flow under test is unchanged. Checked in 3b.
	h.hzqExtGot = false;
	h.hzqExtOn = function () { return false; };
	for (const n of ["hzqExtPrepare", "hzqExtDraw", "hzqExtFetch", "hzqExtRestore", "hzqExtListen", "hzqExtPlace", "hzqExtPad", "hzqExtRaise", "hzqRingDraw", "hzqUnclip"]) h[n] = function () {};
	h.ItemInfo_mc = { ItemNameBg_mc: clip("a"), ItemName_mc: clip("b"), AmmoType_mc: clip("c"), AmmoAmount_mc: clip("d"), DamageTypeHolder_mc: clip("e") };
	for (let i = 0; i < 12; i++) h["Entry_" + i] = Object.assign(clip("Entry_" + i, [clip("instance1"), clip("Icon_mc"), clip("Catcher_mc"), clip("Quickkey_tf"), clip("SlotInfoSpacer_mc"), clip("hzqCard")]),
		{ Icon_mc: null, Quickkey_tf: null });
	for (let i = 0; i < 12; i++) { const e = h["Entry_" + i]; e.Icon_mc = e.kids[1]; e.Quickkey_tf = e.kids[3]; e.Catcher_mc = e.kids[2]; }
	return h;
}

// ---- 1. no Q keying ----
// 0.43.5: the Extended Mode section (slots 13-24, off by default) is its own opt-in block at the end of the file with
// its own clips, mouse and key handling; these 0.43.3 invariants cover everything before it. It is checked below.
const EXT_MARK = "// ---------- 0.43.5 Extended Mode";
const extAt = main.indexOf(EXT_MARK);
const code = codeOnly(extAt >= 0 ? main.slice(0, extAt) : main);
const extCode = extAt >= 0 ? codeOnly(main.slice(extAt)) : "";
expect(!/keyCode|Keyboard\.|KeyboardEvent|KEY_DOWN|KEY_UP|"Q"|'Q'|\b81\b/.test(code), "the Horizon block has no key code, no keyboard listener and no Q");
expect(!/"Quickkeys"/.test(code), "the Horizon block does not use the quick-menu open / close event");
expect((code.match(/this\.hzqKeys\[/g) || []).length === 1 && /var k:\* = this\.hzqKeys\[ev\];/.test(code), "key text has one source: the ControlMapData table (hzqKey)");
{
	const h = host("");
	h.hzqCtl({ uiController: 0, vMappedEvents: [{ strUserEventName: "Quickkey1", strButtonName: "1" }, { strUserEventName: "Cancel", strButtonName: "Tab" }, { strUserEventName: "Quickkey1", strButtonName: "X" }] });
	expect(h.hzqKb === true && h.hzqKey("Quickkey1") === "1" && h.hzqKey("Cancel") === "TAB" && h.hzqKey("Quickkey2") === "", "bound keys come from vMappedEvents (first entry wins, upper case, unbound = no badge)");
	h.hzqCtl({ uiController: 1, vMappedEvents: [{ strUserEventName: "Quickkey1", strButtonName: "$Pad" }] });
	expect(h.hzqKb === false && h.hzqKey("Quickkey1") === "", "a controller turns the keyboard flag off; a $ glyph name is not shown as text");
	expect(h.calls.indexOf("redraw") < 0, "a ControlMapData change before the ini read does not draw");
	h.hzqOn = true; h.hzqCtl({ uiController: 0 });
	expect(h.calls.filter((c) => c === "redraw").length === 1, "a ControlMapData change while on redraws once");
}
// ---- 2. mouse ----
expect((code.match(/new Sprite\(\)/g) || []).length === 1 && /s\.mouseEnabled = false;\n\s*s\.mouseChildren = false;/.test(fnText(main, "hzqSprite").body), "every Horizon sprite comes from hzqSprite, which turns mouse input off");
expect((code.match(/new TextField\(\)/g) || []).length === 5 && /t\.mouseEnabled = false;/.test(fnText(main, "hzqTf").body)
	&& (fnText(main, "hzqProbe").body.match(/new TextField\(\)/g) || []).length === 2 && (fnText(main, "hzqGlyphOk").body.match(/new TextField\(\)/g) || []).length === 2
	&& !/addChild/.test(fnText(main, "hzqProbe").body + fnText(main, "hzqGlyphOk").body), "every Horizon text field (hzqTf) has mouseEnabled = false (the other four are font / glyph probes, never added)");
expect(!/hitArea|Catcher_mc\.mouse|buttonMode|MouseEvent/.test(code), "the slots keep the game's hit area and mouse handling");
// ---- 3. edge-only ----
expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout|getTimer|getChildByName/.test(code + codeOnly(reader)), "no enterFrame, timer, getTimer or name search");
const listeners = code.match(/addEventListener\([^)]*\)/g) || [];
expect(listeners.length === 3 && listeners.every((l) => /hzqFont(Ok|Err)Ev/.test(l)), "the only listeners are the one-shot font.marker loader's (plus the reader's file loader)");
// ---- 3b. Extended Mode block (0.43.5): opt-in, edge-only, its listeners are its own ----
{
	expect(extAt > 0 && /if\(!this\.hzqExtOn\(\)\) \{ this\.hzqExtRestore\(\); return; \}/.test(fnText(main, "hzqExtPrepare").body), "Extended Mode off: hzqExtPrepare puts the 12-slot look back and adds nothing");
	const extL = extCode.match(/addEventListener\([^)]*\)/g) || [];
	const keyL = extL.filter((l) => /KeyboardEvent/.test(l));
	expect(keyL.length === 1 && /KEY_UP,this\.hzqExtKey,false,0,true/.test(keyL[0]) && /removeEventListener\(KeyboardEvent\.KEY_UP,this\.hzqExtKey\)/.test(extCode), "Extended Mode: one weak KEY_UP listener on the stage, removed when it turns off");
	expect(extL.filter((l) => /MouseEvent/.test(l)).length === 3 && extL.length === 4, "Extended Mode: mouse listeners only on its own slot and ADD SLOT clips");
	expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout|getTimer|getChildByName/.test(extCode), "Extended Mode: no enterFrame, timer or name search");
	// performance standards: clips built once and reused, change-driven draw
	const ens = fnText(main, "hzqExtEnsureClips").body, bld = fnText(main, "hzqExtBuildClips").body, drw = fnText(main, "hzqExtDraw").body;
	expect(/if\(this\.hzqExtPool == null\)/.test(ens) && /if\(this\.hzqExtAdd == null\)/.test(ens) && !/new Sprite|removeChild|addEventListener/.test(bld) && (extCode.match(/new Sprite\(\)/g) || []).length === 3, "Extended Mode: hold, 12 slot clips and ADD tile are built once per open; a layout change only moves / shows / hides them");
	expect(/o\.cSel !== sel \|\| o\.cEmpty !== empty/.test(drw) && /o\.cLabel !== label/.test(drw) && /!this\.hzqExtAddDrawn/.test(drw), "Extended Mode: a slot is redrawn only when its selection, empty state, label or key changed; the ADD tile art is drawn once");
	expect(/public var hzqExtCmd:Function = null;/.test(main) && /public function hzqExtKick\(\)/.test(main), "Extended Mode: declared hzqExtCmd slot (sealed class) and the DLL kick");
}
const redrawCallers = FNS.concat(["hzqFontOkEv"]).filter((n) => { try { return /this\.hzqRedraw\(\)/.test(fnText(main, n).body); } catch (e) { return false; } });
expect(JSON.stringify(redrawCallers.sort()) === JSON.stringify(["hzqCtl", "hzqFontOkEv", "hzqOnIni"]), "a full redraw only after the ini read, font.marker or a ControlMapData change: " + redrawCallers.join(","));
expect(/for\(var|while\(i < n\)/.test(fnText(main, "hzqHideArt").body) && /Math\.min\(e\.numChildren,10\)/.test(fnText(main, "hzqHideArt").body), "the vanilla-art pass looks at the slot's direct children only (at most 10, no recursion)");
{
	const h = host("");
	h.hzqData(); h.hzqSel();
	expect(h.calls.length === 0, "off: FavoritesData and selection hooks draw nothing");
	h.hzqOn = true; h.hzqData();
	expect(h.calls.filter((c) => /^card/.test(c)).length === 12 && h.calls.indexOf("info") < 0, "FavoritesData redraws the 12 slot cards");
	h.calls = []; h.hzqSel();
	expect(h.calls.length === 13 && h.calls[12] === "info" && h.hzqInfSel === true, "selection redraws the slot cards and the info card");
}
// ---- 4. the switch ----
{
	const h = host("[Cards Extra]\nQuickMenuHorizon=0\n[Style]\nAccentColor=2\n");
	h.hzqOpen(); h.hzqOpen();
	expect(h.calls.join(",") === "read" && h.hzqOn === false && h.hzqCards === null, "QuickMenuHorizon=0: one ini read per open, nothing built, nothing drawn");
	const all = [];
	for (let i = 0; i < 12; i++) for (const k of h["Entry_" + i].kids) all.push(k.visible && k.alpha === 1);
	expect(all.every(Boolean) && h.ItemInfo_mc.ItemName_mc.alpha === 1, "QuickMenuHorizon=0: no vanilla piece hidden");
	const on = host("[Cards Extra]\nQuickMenuHorizon=1\n");
	on.hzqOpen();
	expect(on.calls.join(",") === "read,font,build,redraw" && on.hzqOn === true, "QuickMenuHorizon=1: read, font.marker, build once, one redraw");
	const dflt = host(null);
	dflt.hzqOpen();
	expect(dflt.hzqOn === true, "no settings file: on (the default)");
	// restore
	const r = host("");
	r.hzqCards = []; for (let i = 0; i < 12; i++) r.hzqCards.push({ s: { visible: true } });
	r.hzqHdr = { visible: true }; r.hzqInf = { visible: true }; r.hzqOn = true;
	for (let i = 0; i < 12; i++) { r.hzqHideArt(r["Entry_" + i], true); r["Entry_" + i].Icon_mc.transform.colorTransform = { tint: 1 }; }
	r.hzqHideInfoVan(true);
	expect(r.Entry_3.kids[0].visible === false && r.Entry_3.Quickkey_tf.alpha === 0 && r.Entry_3.Icon_mc.visible === true && r.ItemInfo_mc.AmmoType_mc.alpha === 0, "on: the tier art and the vanilla info rows are hidden, the icon and hit area stay");
	r.hzqFail();
	let ok = r.hzqOn === false && r.hzqErr === true && r.hzqHdr.visible === false && r.hzqInf.visible === false;
	r.hzqCtU = { u: 1 }; r.hzqCtS = { s: 1 };
	for (let i = 0; i < 12; i++) { const e = r["Entry_" + i]; ok = ok && e.kids[0].visible && e.Quickkey_tf.alpha === 1 && e.Icon_mc.transform.colorTransform === r.hzqCtN && r.hzqCards[i].s.visible === false; }
	expect(ok === false, "(the restore test runs with the game's captured tints, not identity)");
	ok = r.hzqOn === false && r.hzqErr === true && r.hzqHdr.visible === false && r.hzqInf.visible === false;
	r.hzqRestore();
	for (let i = 0; i < 12; i++) { const e = r["Entry_" + i]; ok = ok && e.kids[0].visible && e.Quickkey_tf.alpha === 1 && e.Icon_mc.transform.colorTransform === (i === 0 ? r.hzqCtS : r.hzqCtU) && r.hzqCards[i].s.visible === false; }
	ok = ok && ["ItemNameBg_mc", "ItemName_mc", "AmmoType_mc", "AmmoAmount_mc", "DamageTypeHolder_mc"].every((k) => r.ItemInfo_mc[k].alpha === 1);
	expect(ok, "an error (or off) puts every vanilla piece back: art visible, key text alpha 1, the game's icon tint (selected / unselected), info rows alpha 1, Horizon layers hidden");
}
// ---- 5. [Style] and theme ----
{
	const h = host("");
	const st = h.hzqParse("[Style]\nAccentColor=13\nAccentHex=#FF8800\nCardColor=8\nCardOpacity=9\nTextTone=0\nFontFace=2\nTextScale=0.1\nHeaderStyle=1\nTextShadow=1\n[Cards Extra]\nQuickMenuHorizon=1\n");
	h.hzqS = st;
	expect(st.AccentColor === 13 && st.AccentHex === 0xFF8800 && h.hzqAccent() === 0xFF8800, "AccentColor 13 + AccentHex = the custom accent (HUD palette rule)");
	expect(st.CardOpacity === 1.6 && st.TextScale === 0.8 && st.FontFace === 2 && st.HeaderStyle === 1 && st.TextShadow === true, "ranges clamp like the HUD reader");
	expect(h.hzqCardFill() === 0xF2F4F6 && h.hzqLight() === true && h.hzqDarkText() === true && h.hzqMainCol() === 0x0E151B, "CardColor 8 (white): light card, dark text");
	h.hzqS = h.hzqParse("");
	expect(h.hzqAccent() === 0x3FD0E0 && h.hzqCardFill() === 0x0B1218 && h.hzqMainCol() === 0xF2F7F9 && h.hzqS.FontFace === 1, "defaults: cyan on slate, light text, Horizon font");
	expect(h.hzqParse("[Style]\nAccentColor=99\n").AccentColor === 13 && h.hzqParse("[Style]\nAccentHex=zzzzzz\n").AccentHex === -1, "bad values are clamped or ignored");
	for (const fn of ["hzCardPal", "hzAccPal", "hzLum", "hzMix", "hzKeyCorner"]) {
		const a = codeOnly(fnText(hud, fn).body).replace(/\bhz/g, "hzq").replace(/HZ_/g, "HZQ_").replace(/\s+/g, "");
		const b = codeOnly(fnText(main, fn.replace(/^hz/, "hzq")).body).replace(/\s+/g, "");
		expect(a === b || fn === "hzCardPal" || fn === "hzAccPal", fn + ": the quick menu copy matches the HUD function");
	}
}
// ---- 6. the INI key ----
expect(/\nVehicleExitY=0\n; Quick menu[^\n]*\nQuickMenuHorizon=1\n(?:(?:; [^\n]*|QuickMenu[A-Za-z0-9]+=[^\n]*)\n)*\n\[Effects\]/.test(ini), "default.ini [Cards Extra]: QuickMenuHorizon=1, where the writer puts it (0.43.5 Extended keys follow it)");
expect(/"VehicleExitY":0,"QuickMenuHorizon":1,/.test(hud), "HZ_SET_DEF: QuickMenuHorizon 1 (DEFAULTS = on)");
{
	const h = { hzQmOn: true, hzQmExt: false, hzQmCount: 24, hzQmPerRow: 6, hzQmLayout: 0, hzQmKeys: ["", "", "", "", "", "", "", "", "", "", "", ""], hzB: (o) => (o ? "1" : "0") };
	for (const n of ["hzQmIni", "hzQmSetCur", "hzQmSetLive", "hzQmIniLines", "hzQmKeyAt", "hzQmClampCount", "hzQmClampRow"]) h[n] = toJs(hud, n);
	expect(h.hzQmIni("quickmenuhorizon", false) === true && h.hzQmOn === false && h.hzQmIni("vehicleexitpill", true) === false, "HUD reader: quickmenuhorizon (any section, like the rest)");
	const o = {}; h.hzQmSetCur(o);
	expect(o.QuickMenuHorizon === false, "current values (settings save and presets)");
	h.hzQmSetLive({ QuickMenuHorizon: 1 });
	expect(h.hzQmOn === true, "live apply");
	const a = []; h.hzQmIniLines(a, { QuickMenuHorizon: false });
	expect(a.length === 23 && a[0].charAt(0) === ";" && a[1] === "QuickMenuHorizon=0" && a[3] === "QuickMenuExtended=0" && a[5] === "QuickMenuSlotCount=24" && a[7] === "QuickMenuSlotsPerRow=6" && a[9] === "QuickMenuExtendedLayout=0" && a[11] === "QuickMenuKey13=" && a[22] === "QuickMenuKey24=" && a.join("\n") === ini.slice(ini.indexOf("; Quick menu (the game"), ini.indexOf("QuickMenuKey24=") + 15).replace("QuickMenuHorizon=1", "QuickMenuHorizon=0"), "writer lines (0.43.5: Extended Mode off, 24 slots, 6 per row, CROSS + BARS, no keys)");
	expect(/this\.hzQmIni\(k,bv\)/.test(fnText(hud, "hz26Ini").body) && /hzQmSetCur\(o\)/.test(fnText(hud, "hz26SetCur").body) && /hzQmSetLive\(p\)/.test(fnText(hud, "hz26SetLive").body) && /this\.hzVehIniLines\(a,p\);[^\n]*\n\s*this\.hzQmIniLines\(a,p\);/.test(fnText(hud, "hz26IniLines").body), "wired into the [Cards Extra] reader, current values, live apply and writer");
	expect(/\{"k":"QuickMenuHorizon","l":"HORIZON STYLE","t":"b","h":"QUICK MENU"/.test(hud), "F11 > CARDS > QUICK MENU > HORIZON STYLE");
}

// ---- 8. batch i: one box, icon fit, controller close hint ----
// Vanilla geometry, measured from favoritesmenu.swf and favoritesmenu_lrg.swf (FFDec swf2xml, identical at both scales):
// slot i = [Entry_i x, Entry_i y, Catcher_mc bounds in the entry: x0, y0, x1, y1]. Center disc = the CenterClip_mc
// "Quick" backdrop hole, radius 54.
const VAN = [[-195.75, 0, -72, -37.5, -8, 37.5], [-120.8, 0, -72, -37.5, -8, 37.5], [-40.05, 0, -80, -37.5, -16, 37.5], [40, 0, 17, -37.5, 81, 37.5],
	[120.8, 0, 9, -37.5, 73, 37.5], [195.8, 0, 9, -37.5, 73, 37.5], [0, -195.65, -37.5, -72, 37.5, -8], [0, -120.65, -37.5, -72, 37.5, -8],
	[0, -39.95, -38, -80, 37, -16], [0, 40.05, -37.5, 17, 37.5, 81], [0, 120.65, -37.5, 9, 37.5, 73], [0, 195.75, -37.5, 9, 37.5, 73]];
const DISC_R = 54;
{
	const B = consts.HZQ_BOX;
	const bl = fnText(main, "hzqBuild").body;
	expect(B === 58 && /r = new Rectangle\(cr\.x \+ cr\.width \/ 2 - HZQ_BOX \/ 2,cr\.y \+ cr\.height \/ 2 - HZQ_BOX \/ 2,HZQ_BOX,HZQ_BOX\);/.test(bl)
		&& /var cr:Rectangle = c != null \? c\.getBounds\(e\) : e\.getBounds\(e\);/.test(bl) && !/hzqTrim|HZQ_INNER/.test(code), "one box for all 12 slots: HZQ_BOX x HZQ_BOX (58), centered on the slot's Catcher_mc");
	expect(consts.HZQ_INF_W === 380, "HZQ_INF_W unchanged (380)");
	const box = VAN.map((v) => { const cx = v[0] + (v[2] + v[4]) / 2, cy = v[1] + (v[3] + v[5]) / 2; return [cx - B / 2, cy - B / 2, cx + B / 2, cy + B / 2]; });
	let minGap = 1e9, minDisc = 1e9, inCatcher = true;
	for (let i = 0; i < 12; i++) {
		const b = box[i], v = VAN[i];
		const nx = Math.max(b[0], Math.min(0, b[2])), ny = Math.max(b[1], Math.min(0, b[3]));
		minDisc = Math.min(minDisc, Math.hypot(nx, ny) - DISC_R);
		const horiz = v[1] === 0;
		const cw = v[4] - v[2], ch = v[5] - v[3];
		inCatcher = inCatcher && (horiz ? B <= cw && B <= ch : B <= ch && B <= cw);
		for (let j = i + 1; j < 12; j++) {
			const o = box[j];
			const gx = Math.max(o[0] - b[2], b[0] - o[2]), gy = Math.max(o[1] - b[3], b[1] - o[3]);
			minGap = Math.min(minGap, Math.max(gx, gy));
		}
	}
	expect(minGap >= 14.5 && minDisc >= 4.9 && inCatcher, "vanilla geometry, both scales: all 12 boxes clear each other (min gap " + minGap.toFixed(2) + ") and the center disc (min " + minDisc.toFixed(2) + "), inside each slot's catcher");
	expect(/s\.mouseEnabled = false;\n\s*s\.mouseChildren = false;/.test(fnText(main, "hzqSprite").body) && !/Catcher_mc\.(mouse|hitArea)|hitArea/.test(code), "mouse stays on Catcher_mc; Horizon panels stay mouse-off");
}
// a fake ImageFixture: content rect (local) under Icon_mc, so getBounds follows Icon_mc's scale and position
function fixture(base, lw, lh) {
	const ic = Object.assign(clip("Icon_mc"), { scaleX: base.sx, scaleY: base.sy, x: base.x, y: base.y, transform: { colorTransform: null } });
	ic.content = lw > 0 ? { lx: -lw / 2, ly: -lh / 2, lw: lw, lh: lh } : null;
	const inst = { parent: {}, visible: true, getBounds() { const c = ic.content; return { x: ic.x + c.lx * ic.scaleX, y: ic.y + c.ly * ic.scaleY, width: c.lw * ic.scaleX, height: c.lh * ic.scaleY }; } };
	Object.defineProperty(ic, "imageInstance", { get() { return ic.content ? inst : null; } });
	Object.defineProperty(ic, "symbolInstance", { get() { return null; } });
	return ic;
}
function fitHost() {
	const h = host("");
	h.hzqOn = true;
	h.hzqCards = [];
	for (let i = 0; i < 12; i++) {
		const v = VAN[i], B = consts.HZQ_BOX;
		const cx = (v[2] + v[4]) / 2, cy = (v[3] + v[5]) / 2;
		const e = h["Entry_" + i];
		const base = { sx: 0.75, sy: 0.75, x: v[1] === 0 ? (cx > 0 ? 40 : -40) : 0, y: v[1] === 0 ? 0 : (cy > 0 ? 40 : -40) };
		e.Icon_mc = fixture(base, 0, 0);
		e.kids[1] = e.Icon_mc;
		h.hzqCards.push({ s: { visible: true }, r: { x: cx - B / 2, y: cy - B / 2, width: B, height: B }, ib: base, kb: 0 });
	}
	return h;
}
const near = (a, b) => Math.abs(a - b) < 1e-6;
{
	const h = fitHost();
	const e = h.Entry_3, ic = e.Icon_mc, c = h.hzqCards[3], r = c.r, base = c.ib;
	ic.content = { lx: -60, ly: -15, lw: 120, lh: 30 };           // a wide weapon picture, 90 x 22.5 at the game's 0.75
	c.kb = 5 + 16;                                                  // keyboard: a 16-high key badge at the top left (below the box top)
	h.hzqFit(3);
	const nb = ic.imageInstance.getBounds(e);
	const P = consts.HZQ_ICPAD, top = r.y + c.kb + 2;
	const aw = r.width - 2 * P, ah = r.y + r.height - P - top;
	const k = Math.min(1, aw / 90, ah / 22.5);
	expect(near(ic.scaleX, 0.75 * k) && near(ic.scaleY, 0.75 * k) && near(ic.scaleX / ic.scaleY, base.sx / base.sy), "aspect fit: scale = base x min(1, room w / w, room h / h), the same on both axes (k = " + k.toFixed(4) + ")");
	expect(nb.x >= r.x + P - 1e-6 && nb.x + nb.width <= r.x + r.width - P + 1e-6 && nb.y >= top - 1e-6 && nb.y + nb.height <= r.y + r.height - P + 1e-6, "the fitted icon sits inside the padded box, below the key badge");
	expect(near(nb.x + nb.width / 2, r.x + r.width / 2) && near(nb.y + nb.height / 2, top + ah / 2), "the fitted icon is centered in its room");
	const snap = JSON.stringify([ic.scaleX, ic.scaleY, ic.x, ic.y]);
	for (let n = 0; n < 6; n++) { h.hzqFit(3); h.selectedIndex = n % 2 ? 3 : 0; h.hzqFitAll(); }
	expect(JSON.stringify([ic.scaleX, ic.scaleY, ic.x, ic.y]) === snap, "no compounding: redraws, selection and assign refits give the same transform");
	ic.content = { lx: -10, ly: -10, lw: 20, lh: 20 };            // a new, small icon in the same slot
	h.hzqFit(3);
	expect(near(ic.scaleX, 0.75) && near(ic.scaleY, 0.75), "a small icon is never enlarged (k capped at 1); the new icon is measured from the game's transform");
	ic.content = { lx: -60, ly: -15, lw: 120, lh: 30 };
	h.hzqFit(3);
	expect(JSON.stringify([ic.scaleX, ic.scaleY, ic.x, ic.y]) === snap, "back to the first icon: the same fit as before (reset to base first)");
	c.kb = 0; h.hzqFit(3);
	const nb2 = ic.imageInstance.getBounds(e);
	expect(near(nb2.y + nb2.height / 2, r.y + r.height / 2) && nb2.width <= r.width - 2 * P + 1e-6, "controller (no key badge): the icon uses the whole padded box, centered");
	ic.content = null; ic.scaleX = 9; ic.x = 999;
	h.hzqFit(3);
	expect(ic.scaleX === base.sx && ic.scaleY === base.sy && ic.x === base.x && ic.y === base.y, "nothing loaded (no picture, no symbol): the game's transform");
	ic.content = { lx: 0, ly: 0, lw: 0, lh: 0 }; ic.scaleX = 9;
	h.hzqFit(3);
	expect(ic.scaleX === base.sx && ic.x === base.x, "zero-size bounds: the game's transform");
	ic.content = { lx: -60, ly: -15, lw: 120, lh: 30 }; ic.visible = false; ic.scaleX = 9;
	h.hzqFit(3);
	expect(ic.scaleX === base.sx && ic.x === base.x, "a hidden icon (empty slot): the game's transform");
	ic.visible = true;
	// all 12 slots, both arms: every fitted icon inside its own box
	let all = true;
	for (let i = 0; i < 12; i++) {
		const f = h["Entry_" + i].Icon_mc; f.content = { lx: -40, ly: -40, lw: 80, lh: 80 };
		const ci = h.hzqCards[i]; ci.kb = 21;
		h.hzqFit(i);
		const b = f.imageInstance.getBounds(h["Entry_" + i]);
		all = all && b.x >= ci.r.x && b.x + b.width <= ci.r.x + ci.r.width && b.y >= ci.r.y + ci.kb && b.y + b.height <= ci.r.y + ci.r.height && near(f.scaleX, f.scaleY);
	}
	expect(all, "all 12 slots: the icon fits inside the slot's box, below the badge, aspect kept");
	// restore: the game's transform and tint
	h.hzqCtU = { u: 1 }; h.hzqCtS = { s: 1 }; h.selectedIndex = 3;
	h.hzqHdr = { visible: true }; h.hzqInf = { visible: true };
	h.hzqFail();
	let rs = true;
	for (let i = 0; i < 12; i++) { const f = h["Entry_" + i].Icon_mc, b = h.hzqCards[i].ib; rs = rs && f.scaleX === b.sx && f.scaleY === b.sy && f.x === b.x && f.y === b.y && f.transform.colorTransform === (i === 3 ? h.hzqCtS : h.hzqCtU); }
	expect(rs, "restore (error or QuickMenuHorizon=0 after a build): every Icon_mc gets back its x, y, scaleX, scaleY and the game's tint");
	h.selectedIndex = 5; h.hzqSel();
	expect(h.Entry_5.Icon_mc.transform.colorTransform === h.hzqCtS && h.Entry_3.Icon_mc.transform.colorTransform === h.hzqCtU, "after an error, a selection change gives the game's tint to the new selection");
}
{
	// the icon-load edge
	const h = fitHost();
	const seen = [];
	h.hzqIcCb = []; for (let i = 0; i < 12; i++) h.hzqIcCb.push("cb" + i);
	h.Entry_4.onIconLoadAttemptComplete = function () { seen.push("game"); };
	const fit = h.hzqFit; h.hzqFit = function (i) { seen.push("fit" + i); };
	h.hzqIcDone(4);
	expect(seen.join(",") === "game,fit4", "icon loaded: the game's handler first, then that slot's fit");
	h.hzqOn = false; seen.length = 0; h.hzqIcDone(4);
	expect(seen.join(",") === "game", "off: only the game's handler");
	h.hzqFit = fit;
	const ic = { onLoadAttemptComplete: null }; h.hzqIcHook(7, ic);
	expect(ic.onLoadAttemptComplete === "cb7", "hzqIcHook hands Icon_mc the slot's own handler");
	const cardBody = fnText(main, "hzqCard").body;
	expect(/this\.hzqIcHook\(i,ic\);\n\s*this\.hzqFit\(i\);/.test(cardBody), "every slot draw (FavoritesData, selection, ini read, font, ControlMapData) re-hooks and refits the icon");
	const ics = []; for (let i = 0; i < 12; i++) { ics.push("this.hzqIc" + i); expect(new RegExp("private function hzqIc" + i + "\\(\\) : void \\{ this\\.hzqIcDone\\(" + i + "\\); \\}").test(main), "hzqIc" + i + " -> hzqIcDone(" + i + ")"); }
	expect(fnText(main, "hzqBuild").body.indexOf("this.hzqIcCb = [" + ics.join(",") + "];") >= 0, "hzqIcCb holds the 12 handlers in slot order");
	const fitCallers = ["hzqCard", "hzqIcDone", "hzqFitAll", "hzqAssign", "hzqSel", "hzqData", "hzqCtl", "hzqRedraw", "hzqOnIni", "hzqFontOkEv", "hzqHeader", "hzqRestore"].filter((n) => /this\.hzqFit\(/.test(fnText(main, n).body));
	expect(JSON.stringify(fitCallers) === JSON.stringify(["hzqCard", "hzqIcDone", "hzqFitAll"]), "hzqFit runs only from a slot draw, the icon-load edge and hzqFitAll: " + fitCallers.join(","));
	expect(/this\.hzqFitAll\(\)/.test(fnText(main, "hzqAssign").body), "assign mode refits the icons");
	const ab = fitHost(); ab.hzqFitAll = function () { this.calls.push("fitall"); }; ab.hzqAssign();
	expect(ab.calls.join(",") === "infoset,fitall", "hzqAssign: info card, then the icon fit");
	const fb = fnText(main, "hzqFit").body;
	expect(fb.indexOf("ic.scaleX = b.sx;") < fb.indexOf("this.hzqIcB(ic,e)") && fb.indexOf("ic.x = b.x;") < fb.indexOf("this.hzqIcB(ic,e)"), "hzqFit resets Icon_mc to the captured base before it measures");
	const bb = fnText(main, "hzqBuild").body;
	expect(/ib = \{"sx":ic\.scaleX,"sy":ic\.scaleY,"x":ic\.x,"y":ic\.y\};/.test(bb) && bb.indexOf("ib = {") < bb.indexOf("this.hzqSprite(e,0)"), "the base transform is captured in hzqBuild, before any Horizon change to the slot");
	expect(!/getChildByName|BoundClip_mc\.(width|getBounds)/.test(codeOnly(fnText(main, "hzqIcB").body)) && /ic\.imageInstance/.test(fnText(main, "hzqIcB").body) && /ic\.symbolInstance/.test(fnText(main, "hzqIcB").body), "the fit measures the loaded picture / symbol, not the fixed sizer");
}
{
	// controller close hint
	const h = host("");
	h.hzqCtl({ uiController: 1, vMappedEvents: [{ strUserEventName: "Cancel", strButtonName: "Xenon_B" }] });
	expect(h.hzqKb === false && JSON.stringify(h.hzqPadKey("Cancel")) === '["B",""]', "controller: mapped Cancel Xenon_B -> keycap B (no glyph face)");
	h.hzqGlyphOk = function (c) { return c === "B"; };
	expect(JSON.stringify(h.hzqPadKey("Cancel")) === '["B","$Controller_Buttons"]', "controller: the glyph character in $Controller_Buttons when that face draws it");
	h.hzqGlyphOk = function () { return false; };
	const tryName = (n) => { h.hzqCtl({ uiController: 1, vMappedEvents: [{ strUserEventName: "Cancel", strButtonName: n }] }); return h.hzqPadKey("Cancel"); };
	expect(tryName("PSN_B")[0] === "B" && tryName("Xenon_A")[0] === "A" && tryName("DPad_Up")[0] === "UP", "PlayStation and other buttons map through the HUD table (PSN_B -> B, like the HUD)");
	let noDollar = true;
	for (const n of ["$Cancel", "$B", "Foo", "", "?", "_Question", "PCUp", "constructor", "toString", "$"]) { const r = tryName(n); noDollar = noDollar && r[0] === "" && r[1] === ""; }
	expect(noDollar, "unknown, $ tokens, PC names and prototype names: no badge (never raw text)");
	h.hzqCtl({ uiController: 1, vMappedEvents: [] });
	expect(JSON.stringify(h.hzqPadKey("Cancel")) === '["",""]', "unbound Cancel: no badge");
	const hb = fnText(main, "hzqHeader").body;
	expect(/if\(this\.hzqKb\) \{ kt = this\.hzqKey\("Cancel"\); \}\n\s*else \{ var pk:Array = this\.hzqPadKey\("Cancel"\);/.test(hb), "header: keyboard = the bound key text, controller = the mapped Cancel (hzqPadKey)");
	expect(!/"B"|Xenon_B/.test(codeOnly(hb + fnText(main, "hzqPadKey").body)), "no hardcoded B in the header path");
	const cb = fnText(main, "hzqCard").body;
	expect(/var kt:String = this\.hzqKb \? this\.hzqKey\("Quickkey" \+ \(i \+ 1\)\) : "";/.test(cb), "slot badges stay keyboard and mouse only");
	expect(/override protected function OnPlatformChanged\(param1:Object\) : void\n\s*\{\n\s*super\.OnPlatformChanged\(param1\);\n\s*try \{ if\(this\.hzqOn\) \{ this\.hzqHeader\(\); \} \}/.test(main), "OnPlatformChanged(param1:Object) (BSDisplayObject signature): super first, then the header");
	expect(/override protected function OnControlMapChanged\(param1:Object\) : void\n\s*\{\n\s*super\.OnControlMapChanged\(param1\);/.test(main), "OnControlMapChanged: super first (the game's handler), then hzqCtl");
	const pk = codeOnly(fnText(main, "hzqPadKey").body);
	expect(/raw\.charAt\(0\) == "\$"/.test(pk) && /gs\.charAt\(0\) == "\$"/.test(pk) && /hasOwnProperty\(raw\)/.test(pk) && /HZQ_PADK\.hasOwnProperty\(gs\)/.test(pk), "hzqPadKey: $ names and unknown names / glyphs are rejected before anything is shown");
	expect((code.match(/this\.hzqKeys\[/g) || []).length === 1 && /this\.hzqRaw\(ev\)/.test(fnText(main, "hzqKey").body) && /this\.hzqRaw\(ev\)/.test(fnText(main, "hzqPadKey").body), "both key paths read the one ControlMapData table (hzqRaw)");
}
// ---- 7. files ----
for (const lrg of [false, true]) {
	const rel = "actionscript/favorites/imp/pimp_favoritesmenu" + (lrg ? "_lrg" : "") + "/FavoritesMenu.as";
	const raw = fs.readFileSync(path.join(root, rel), "utf8");
	const t = raw.replace(/\r\n/g, "\n");
	expect(raw.indexOf("\r\n") >= 0 && raw.replace(/\r\n/g, "").indexOf("\n") < 0, rel + " is CRLF (the FFDec export)");
	expect(t.indexOf(main.replace("__HZQ_LRG__", lrg ? "true" : "false")) >= 0 && t.indexOf(reader) >= 0, rel + " carries hzq_main.as + hzq37_reader.as verbatim");
	for (const hk of ["this.hzqOpen();", "this.hzqData();", "this.hzqAssign();", "this.hzqSel();"]) expect(t.split(hk).length === 2, rel + " " + hk + " hook exactly once");
	expect(/public class FavoritesMenu extends IMenu/.test(t) && /GlobalFunc\.CloseMenu\("FavoritesMenu"\)/.test(t), rel + " keeps the vanilla class and close path");
}
{
	const a = rd("actionscript/favorites/imp/pimp_favoritesmenu/FavoritesMenu.as").split("\n"), b = rd("actionscript/favorites/imp/pimp_favoritesmenu_lrg/FavoritesMenu.as").split("\n");
	const d = a.map((l, i) => (l !== b[i] ? l.trim() : null)).filter(Boolean);
	expect(a.length === b.length && d.length === 1 && d[0] === "private static const HZQ_LRG:Boolean = false;", "the two scales differ only in HZQ_LRG");
}
expect(fs.existsSync(path.join(root, "tools", "apply_fav_hooks.py")) && fs.existsSync(path.join(root, "tools", "build_favorites.sh")), "build tools are in the repo");
expect(!/\brm\b|unlink|rmtree|remove\(/.test(fs.readFileSync(path.join(root, "tools", "apply_fav_hooks.py"), "utf8") + fs.readFileSync(path.join(root, "tools", "build_favorites.sh"), "utf8")), "the build tools never delete");

console.log(passed + " ok, " + failed + " failed");
if (failed) { console.error("quickmenu_test FAILED"); process.exit(1); }
console.log("quickmenu_test: all passed");
