// Horizon quick menu (0.43.3.0 batch f). Run: node tests/quickmenu_test.js
// Runs the production hzq* helpers from actionscript/favorites/hzq_main.as and hzq37_reader.as (types stripped) on a
// small host, and reads the sources, and checks:
//  1. no Q keying: no key code, no keyboard listener; every key text comes from ControlMapData vMappedEvents;
//  2. mouse: every Horizon display object is mouseEnabled = mouseChildren = false; the slots keep the game's hit area;
//  3. edge-only: no enterFrame, timer, getTimer or tree search; a redraw only from the ini read, font.marker,
//     FavoritesData, selection, assign and ControlMapData hooks;
//  4. the switch: QuickMenuHorizon=0 builds and draws nothing; hzqRestore puts every vanilla piece back;
//  5. [Style] parsing and the theme functions follow the HUD (accent, custom hex, card color, text tone);
//  6. the INI key: default.ini, HZ_SET_DEF, the HUD reader / writer / live apply, the CARDS row;
//  7. the file lists: the generated classes carry the block and the hooks, CRLF, lrg differs only in HZQ_LRG.
// Author: Moragar. Last modified: 2026-11-18 (batch f).
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
		.replace(/ as Array/g, "");
	return new Function(...params, b);
}
global.int = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)) | 0; };
global.uint = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (Math.floor(n) >>> 0); };
global.PlatformUtils = { PLATFORM_PC_KB_MOUSE: 0 };

const consts = {};
for (const m of src.matchAll(/private static const (HZQ_\w+|hzq37_\w+):\w+ = (.*);/g)) {
	let v = m[2].replace(/__HZQ_LRG__/, "false").replace(/String\.fromCharCode\(0xFEFF\)/, '"\\uFEFF"');
	consts[m[1]] = eval("(" + v + ")");
}
const FNS = ["hzq37Ws", "hzq37Trim", "hzq37Lines", "hzq37Hdr", "hzq37Alias", "hzq37KV", "hzqOnIni", "hzqParse", "hzqHex", "hzqPct",
	"hzqCardPal", "hzqAccPal", "hzqAccent", "hzqCardFill", "hzqLum", "hzqLight", "hzqDarkText", "hzqMix", "hzqIconCol", "hzqTextAccent",
	"hzqMainCol", "hzqKey", "hzqCtl", "hzqHideArt", "hzqHideInfoVan", "hzqRestore", "hzqFail", "hzqData", "hzqSel", "hzqSlot", "hzqOpen"];
function clip(name, kids) {
	return { name: name, visible: true, alpha: 1, kids: kids || [], get numChildren() { return this.kids.length; }, getChildAt(i) { return this.kids[i]; },
		transform: { colorTransform: null } };
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
	h.ItemInfo_mc = { ItemNameBg_mc: clip("a"), ItemName_mc: clip("b"), AmmoType_mc: clip("c"), AmmoAmount_mc: clip("d"), DamageTypeHolder_mc: clip("e") };
	for (let i = 0; i < 12; i++) h["Entry_" + i] = Object.assign(clip("Entry_" + i, [clip("instance1"), clip("Icon_mc"), clip("Catcher_mc"), clip("Quickkey_tf"), clip("SlotInfoSpacer_mc"), clip("hzqCard")]),
		{ Icon_mc: null, Quickkey_tf: null });
	for (let i = 0; i < 12; i++) { const e = h["Entry_" + i]; e.Icon_mc = e.kids[1]; e.Quickkey_tf = e.kids[3]; e.Catcher_mc = e.kids[2]; }
	return h;
}

// ---- 1. no Q keying ----
const code = codeOnly(main);
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
expect((code.match(/new TextField\(\)/g) || []).length === 3 && /t\.mouseEnabled = false;/.test(fnText(main, "hzqTf").body), "every Horizon text field (hzqTf) has mouseEnabled = false (the other two are font probes, never added)");
expect(!/hitArea|Catcher_mc\.mouse|buttonMode|MouseEvent/.test(code), "the slots keep the game's hit area and mouse handling");
// ---- 3. edge-only ----
expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout|getTimer|getChildByName/.test(code + codeOnly(reader)), "no enterFrame, timer, getTimer or name search");
const listeners = code.match(/addEventListener\([^)]*\)/g) || [];
expect(listeners.length === 3 && listeners.every((l) => /hzqFont(Ok|Err)Ev/.test(l)), "the only listeners are the one-shot font.marker loader's (plus the reader's file loader)");
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
	for (let i = 0; i < 12; i++) { const e = r["Entry_" + i]; ok = ok && e.kids[0].visible && e.Quickkey_tf.alpha === 1 && e.Icon_mc.transform.colorTransform === r.hzqCtN && r.hzqCards[i].s.visible === false; }
	ok = ok && ["ItemNameBg_mc", "ItemName_mc", "AmmoType_mc", "AmmoAmount_mc", "DamageTypeHolder_mc"].every((k) => r.ItemInfo_mc[k].alpha === 1);
	expect(ok, "an error (or off) puts every vanilla piece back: art visible, key text alpha 1, icon tint identity, info rows alpha 1, Horizon layers hidden");
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
expect(/\nVehicleExitY=0\n; Quick menu[^\n]*\nQuickMenuHorizon=1\n\n\[Effects\]/.test(ini), "default.ini [Cards Extra]: QuickMenuHorizon=1, where the writer puts it");
expect(/"VehicleExitY":0,"QuickMenuHorizon":1,/.test(hud), "HZ_SET_DEF: QuickMenuHorizon 1 (DEFAULTS = on)");
{
	const h = { hzQmOn: true, hzB: (o) => (o ? "1" : "0") };
	for (const n of ["hzQmIni", "hzQmSetCur", "hzQmSetLive", "hzQmIniLines"]) h[n] = toJs(hud, n);
	expect(h.hzQmIni("quickmenuhorizon", false) === true && h.hzQmOn === false && h.hzQmIni("vehicleexitpill", true) === false, "HUD reader: quickmenuhorizon (any section, like the rest)");
	const o = {}; h.hzQmSetCur(o);
	expect(o.QuickMenuHorizon === false, "current values (settings save and presets)");
	h.hzQmSetLive({ QuickMenuHorizon: 1 });
	expect(h.hzQmOn === true, "live apply");
	const a = []; h.hzQmIniLines(a, { QuickMenuHorizon: false });
	expect(a.length === 2 && a[0].charAt(0) === ";" && a[1] === "QuickMenuHorizon=0", "writer lines");
	expect(/this\.hzQmIni\(k,bv\)/.test(fnText(hud, "hz26Ini").body) && /hzQmSetCur\(o\)/.test(fnText(hud, "hz26SetCur").body) && /hzQmSetLive\(p\)/.test(fnText(hud, "hz26SetLive").body) && /this\.hzVehIniLines\(a,p\);[^\n]*\n\s*this\.hzQmIniLines\(a,p\);/.test(fnText(hud, "hz26IniLines").body), "wired into the [Cards Extra] reader, current values, live apply and writer");
	expect(/\{"k":"QuickMenuHorizon","l":"HORIZON STYLE","t":"b","h":"QUICK MENU"/.test(hud), "F11 > CARDS > QUICK MENU > HORIZON STYLE");
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
