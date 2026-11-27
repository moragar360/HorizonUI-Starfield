// 0.43.5 Quick Menu: inventory assign to slots 13-24, unclipped selection, F11 capture-any-key
// with a conflict warning, and QmFlushStore backoff-before-Pending. Source-read pins.
// Run: node tests/quickmenu_assign_keys_test.js
// Author: Moragar.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.resolve(__dirname, "..");
const rd = (p) => fs.readFileSync(path.join(root, p), "utf8").replace(/\r\n/g, "\n");

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

const qm = rd("actionscript/favorites/hzq_main.as");
const hud = rd("actionscript/horizon_block.as");
const game = rd("src/hz_quickslots_game.h");
const mainCpp = rd("src/main.cpp");
const hooks = rd("tools/apply_fav_hooks.py");
const pimp = rd("actionscript/favorites/imp/pimp_favoritesmenu/FavoritesMenu.as");
const pimpL = rd("actionscript/favorites/imp/pimp_favoritesmenu_lrg/FavoritesMenu.as");

// ---- A. inventory assign: extra slots are Horizon clips, never vanilla index >= 12 ----
{
	const pick = fnText(qm, "hzqExtPick").body;
	expect(/this\.hzqLastExt = slot/.test(pick) && /this\.selectedIndex = 12/.test(pick)
		&& !/this\.selectedIndex = slot/.test(pick) && /this\.hzqExtCmdSend\(op,slot,extra\)/.test(pick),
		"assign/use for 13-24 goes through hzqExtCmd; selectedIndex stays FS_NONE (12), never 13-24");
	expect(!/FavoritesMenu_AssignQuickkey/.test(qm),
		"Horizon extra-slot path never sends FavoritesMenu_AssignQuickkey");
	{
		const make = fnText(qm, "hzqExtMake").body;
		expect(/name = "Entry_" \+ slot/.test(make) && /new MovieClip\(\)/.test(make)
			&& !/new FavoritesEntry/.test(make) && /s\.buttonMode = false/.test(make)
			&& /s\.tabEnabled = false/.test(make) && /hzqExtMouse/.test(qm) && /hzqE9/.test(hooks) && /hzqE9/.test(pimp),
			"extra slots are plain Entry_13-24 MovieClips (no FavoritesEntry hitArea, not in the Tab cycle)");
	}
	const conf = fnText(qm, "hzqExtConfirm").body;
	expect(/slot < 13/.test(conf) && /hzqExtPick\(slot,true\)/.test(conf),
		"hzqExtConfirm only fires when an extra slot is highlighted");
	expect(/if\(this\.hzqExtConfirm\(\)\) return;/.test(pimp) && /if\(this\.hzqExtConfirm\(\)\) return;/.test(pimpL),
		"SelectItem in both movies returns after hzqExtConfirm (never AssignQuickkey index 12)");
	function selectGuard(as, label) {
		const m = /function SelectItem\(\)[\s\S]*?hzqExtConfirm\(\)\) return;[\s\S]*?if\(int\(this\.selectedIndex\) >= 12\) return;[\s\S]*?AssignQuickkey[\s\S]*?\n      \}/.exec(as);
		expect(!!m, label + ": SelectItem returns on selectedIndex >= 12 after hzqExtConfirm, before AssignQuickkey");
	}
	selectGuard(pimp, "pimp");
	selectGuard(pimpL, "pimp_lrg");
	expect(/if\(int\(this\.selectedIndex\) >= 12\) return;/.test(hooks),
		"apply_fav_hooks.py plants the selectedIndex >= 12 SelectItem guard");
	expect(/param1 != "Cancel" && param1 != "Quickkeys" && param1 != "YButton" && this\.hzqExtUser/.test(pimp)
		&& /param1 != "Cancel" && param1 != "Quickkeys" && param1 != "YButton" && this\.hzqExtUser/.test(pimpL)
		&& /hzqExtArrow\(param1\)/.test(pimp)
		&& /Keyboard\.ENTER && this\.hzqExtConfirm/.test(pimp),
		"ProcessUserEvent never swallows Cancel/Quickkeys/YButton; arrows / ENTER still reach 13-24");
	expect(/hzqExtUser\(param1,param2\)/.test(hooks) && /hzqE8/.test(hooks) && /hzqE9/.test(hooks),
		"apply_fav_hooks.py plants the extra-slot confirm and mouseover hooks on a fresh vanilla export");
	{
		const assign = game.slice(game.indexOf("std::string QmAssign("), game.indexOf("std::string QmHandleCmd("));
		expect(/QmReadFavAssigned\(/.test(assign) && /QmReadLiveInv\(/.test(assign)
			&& !/QmSnapAssign\(\)/.test(assign) && /g_qmPendingHandle\.load/.test(assign)
			&& /KeepPendingForAssigned/.test(assign) && /ex\.handle/.test(assign)
			&& /GetDataForEntry/.test(game) && /IsUInt\(\)/.test(game),
			"DLL assign uses this-open pending, then AssignedItem, then extra, then NamesMatch-gated live inventory");
	}
	const nav = fnText(qm, "hzqExtNav").body;
	expect(/idx >= 9 && idx <= 11/.test(nav) && /hzqExtPick\(13,false\)/.test(nav),
		"CROSS+BARS: Down from the T (slots 10-12) lands on slot 13");
	expect(/nextB >= 12 && nextB < n/.test(nav),
		"BARS: Down from the last vanilla row continues onto 13-N in the same grid");
	const raise = fnText(qm, "hzqExtRaise").body;
	expect(/setChildIndex\(this\.hzqExtHold/.test(raise) && /SelectQuickslot_mc\.mouseEnabled = false/.test(raise),
		"extra clips sit above the assign overlay and that overlay does not steal mouse hits");
	expect(/this\.hzqExtRaise\(\)/.test(fnText(qm, "hzqExtPlace").body)
		&& /this\.hzqExtRaise\(\)/.test(fnText(qm, "hzqAssign").body),
		"raise runs on layout and when assign mode starts (overlay appears after open)");
	expect(/idx < 12 && this\.hzqExtSel != 0/.test(fnText(qm, "hzqSel").body),
		"a vanilla 1-12 selection clears the extra-slot highlight");
	expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout/.test(codeOnly(qm.slice(qm.indexOf("0.43.5 Extended Mode")))),
		"assign path adds no enterFrame / timer");
}

// ---- B. selection outline is a filled border (GFx clips stroke-only on +x) ----
{
	const ring = fnText(qm, "hzqRingDraw").body;
	const acc = fnText(qm, "hzqAccentRing").body;
	const border = fnText(qm, "hzqFilledBorder").body;
	expect(/this\.hzqAccentRing\(g,x,y,box\)/.test(ring) && /HZQ_EXT_BOX/.test(ring)
		&& !/lineStyle\(2,acc/.test(ring) && !/drawRect\(x - 40/.test(ring),
		"overlay ring calls hzqAccentRing (filled), vanilla box or HZQ_EXT_BOX, no stroke-only lineStyle");
	expect(/this\.hzqFilledBorder\(g,x - box \* 0\.5,y - box \* 0\.5,box,box,2,8/.test(acc)
		&& /g\.beginFill\(col,1\); g\.drawRect/.test(border) && /this\.hzqKeyCorner/.test(border)
		&& /g\.lineStyle\(\);/.test(border) && !/lineStyle\(2,/.test(border),
		"accent ring is the same filled-edge construction as hzqKeycap (all four sides, no lineStyle stroke)");
	expect(/this\.hzqAccentRing\(g,r\.x \+ r\.width \/ 2,r\.y \+ r\.height \/ 2,r\.width\)/.test(fnText(qm, "hzqCard").body),
		"vanilla 1-12 selected cards draw the filled ring on the card as well as the overlay");
	expect(/gotoAndStop\("Unselected"\)/.test(fnText(qm, "hzqCard").body),
		"vanilla Selected-frame outline is not used (FME uses that filled timeline art; Horizon hides it)");
	expect(/this\.addChild\(s\)/.test(fnText(qm, "hzqRingEnsure").body) && /mouseEnabled = false/.test(fnText(qm, "hzqRingEnsure").body),
		"the overlay ring is a child of the menu and does not steal hits");
}

// ---- C. F11 capture-any-key + Horizon warning, never a silent double-bind ----
{
	expect(/HZ_QM_KEYS/.test(hud) === false, "the preset F1-F12 cycle list is gone");
	expect(/hzQmCapBegin/.test(fnText(hud, "hzSetChange").body) && /PRESS A KEY/.test(hud),
		"type k starts a capture prompt (PRESS A KEY), it does not scroll a list");
	expect(/hzQmCap\.length > 0/.test(fnText(hud, "hzSettingsKey").body),
		"capture runs on the existing hzSettingsKey / QueueKey path (F11 open only)");
	expect(/code == "cancel"/.test(fnText(hud, "hzQmCapKey").body) && /code == "bksp"/.test(fnText(hud, "hzQmCapKey").body),
		"ESC / cancel aborts capture; BACKSPACE clears the binding");
	expect(/hz37DrawWarn/.test(hud) && /already SLOT/.test(fnText(hud, "hzQmCapClash").body)
		&& /HORIZON SETTINGS/.test(fnText(hud, "hzQmCapClash").body)
		&& /game or Horizon default/.test(fnText(hud, "hzQmCapClash").body),
		"a used key shows the Horizon amber warning (icon + word) and names the clash");
	expect(/hzQmCapKind == "slot"/.test(fnText(hud, "hzQmCapKey").body)
		&& /hzQmCapKind != "settings"/.test(fnText(hud, "hzQmCapKey").body),
		"ENTER confirms a slot steal or a warned game default; it never silently overwrites, and it will not steal F11");
	expect(/QuickMenuKey13=\n/.test(rd("Interface/HorizonUI/HorizonUI.default.ini"))
		&& /QuickMenuKey24=\n/.test(rd("Interface/HorizonUI/HorizonUI.default.ini")),
		"default.ini still leaves keys 13-24 empty");
	expect(/VkToBind/.test(mainCpp) && /bind:/.test(mainCpp) && /g_swallow/.test(mainCpp),
		"DLL forwards bindable names on the existing swallowed F11 raw-input path (no new poll)");
	expect(!/GetAsyncKeyState/.test(fnText(hud, "hzQmCapKey").body + fnText(hud, "hzQmCapTake").body),
		"HUD capture is event-driven (queued codes), not a per-frame key poll");
}

// ---- D. Pending() is not copied during write backoff ----
{
	const flush = game.slice(game.indexOf("void QmFlushStore()"), game.indexOf("if (g_qmLoadReq.load"));
	const nowAt = flush.indexOf("const auto now = GetTickCount64()");
	const gateAt = flush.indexOf("if (now >= s_nextTry || ignoreBackoffUntilGen != 0)");
	const pendAt = flush.indexOf("g_qmParked.Pending()");
	expect(nowAt >= 0 && gateAt > nowAt && pendAt > gateAt,
		"QmFlushStore checks the write-backoff clock before copying parked stores");
}

// ---- E. F11 bind: must not end preset naming; off-row click ends PRESS A KEY ----
{
	const keyFn = fnText(hud, "hzSettingsKey").body;
	const capAt = keyFn.indexOf("hzQmCap.length > 0");
	const bindAt = keyFn.indexOf('code.indexOf("bind:") == 0');
	const hz37At = keyFn.indexOf("this.hz37Key(code)");
	expect(capAt >= 0 && bindAt > capAt && bindAt < hz37At,
		"hzSettingsKey ignores bind: after capture and before hz37Key (preset naming keeps ch:a)");
	function toJs(name) {
		const f = fnText(hud, name);
		const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
		const b = f.body
			.replace(/var (\w+):[\w*.]+/g, "let $1")
			.replace(/catch\((\w+):\w+\)/g, "catch($1)")
			.replace(/int\(/g, "(");
		return new Function(...params, b);
	}
	const host = {
		hzSetIsOpen: true, hzQmCap: "", hzPopLayers: null, hzArrange: false, hz35Kb: false,
		hz37Edit: "", hz37Cf: "", hzSetTab: 0, hzSetRow: 0, hzSetScroll: 0,
		hzSetDraw() {}, hzSetRows() { return [{ k: "_hz37save" }, { k: "QuickMenuHorizon" }]; },
		hz42NmOk(ch) { return /[a-zA-Z0-9]/.test(ch); },
		hzQmCapKey() {}, hzPopKey() {}, hzArrKey() {}, hz30RowStep() {}, hzSetChange() {},
		hzQmCapEnd() { this.hzQmCap = ""; }
	};
	host.hz37Key = toJs("hz37Key").bind(host);
	host.hzSettingsKey = toJs("hzSettingsKey").bind(host);
	host.hz37Press = toJs("hz37Press").bind(host);
	host.hz37Edit = "";
	host.hzSettingsKey("ch:a");
	host.hzSettingsKey("bind:A");
	expect(host.hz37Edit === "a", "ch:a then bind:A leaves the preset name as a");
	host.hzQmCap = "QuickMenuKey13";
	host.hz37Press("row1", [{ k: "QuickMenuKey13" }, { k: "QuickMenuHorizon" }]);
	expect(host.hzQmCap === "", "a click on another F11 row ends PRESS A KEY capture");
	host.hzQmCap = "QuickMenuKey13";
	host.hz37Press("row0", [{ k: "QuickMenuKey13" }, { k: "QuickMenuHorizon" }]);
	expect(host.hzQmCap === "QuickMenuKey13", "a click on the capturing row leaves PRESS A KEY armed");
}

// ---- F. one confirm per click/Enter; restore clears the extra selection without GetEntryClip ----
{
	const make = fnText(qm, "hzqExtMake").body;
	expect(!/MouseEvent\.MOUSE_DOWN/.test(make) && /MouseEvent\.CLICK,this\.hzqExtClick/.test(make)
		&& /MouseEvent\.ROLL_OVER,this\.hzqExtOver/.test(make),
		"extra-slot MOUSE_DOWN is gone; CLICK confirms, ROLL_OVER highlights");
	const pick = fnText(qm, "hzqExtPick").body;
	const conf = fnText(qm, "hzqExtConfirm").body;
	const open = fnText(qm, "hzqOpen").body;
	expect(/if\(this\.hzqExtDone\) \{ return; \}/.test(pick) && /this\.hzqExtDone = true/.test(pick),
		"hzqExtPick sends assign/use once; a second confirm is a no-op");
	expect(/if\(this\.hzqExtDone\) \{ return true; \}/.test(conf),
		"hzqExtConfirm after success still swallows Enter/SelectItem");
	expect(/this\.hzqExtDone = false/.test(open) && open.indexOf("hzqExtDone") < open.indexOf("hzqOpened"),
		"hzqOpen clears the one-shot confirm flag at the start of every open");
	expect(/this\._SelectedIndex = FS_NONE/.test(fnText(qm, "hzqExtRestore").body),
		"hzqExtRestore sets _SelectedIndex = FS_NONE directly (no GetEntryClip on a removed Entry_13-24)");
	expect(/function hzqExtHideVan/.test(qm) && /d\.name != "hzqCard" && d\.name != "Icon_mc"/.test(fnText(qm, "hzqExtHideVan").body)
		&& /Quickkey_tf/.test(fnText(qm, "hzqExtHideVan").body)
		&& /hzqExtHideVan\(s\)/.test(make) && /hzqExtHideVan\(o\.s/.test(fnText(qm, "hzqExtDraw").body),
		"Entry_13-24 hide leftover vanilla art; Icon_mc (vanilla fixture) and the Horizon card stay visible");
	function toJsPick() {
		const f = fnText(qm, "hzqExtPick");
		const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
		const b = f.body
			.replace(/var (\w+):[\w*.]+/g, "let $1")
			.replace(/catch\((\w+):\w+\)/g, "catch($1)")
			.replace(/int\(/g, "(")
			.replace(/uint\(/g, "(")
			.replace(/String\(/g, "String(");
		return new Function(...params, b);
	}
	const h = {
		hzqExtDone: false, hzqExtSel: 0, hzqExtData: {}, selectedIndex: 12, AssignedItem: { sName: "Med Pack" },
		hzqExtPad() {}, hzqInfoSet() {}, hzqExtDraw() {}, hzqRingDraw() {}, hzqExtFetch() {},
		isAssigningItem() { return true; }, hzqExtFormId() { return 0; }, hzqExtHandle() { return 0; }, hzqExtHex() { return ""; },
		hzqExtIconExtra() { return ""; },
		SelectQuickslot_mc: { visible: true },
		StartClosingMenu() { this.closed = (this.closed || 0) + 1; },
		sends: [],
		hzqExtCmdSend(op, slot, extra) { this.sends.push(op + ":" + slot); return "ok"; }
	};
	const pickFn = toJsPick().bind(h);
	pickFn(13, true);
	pickFn(13, true);
	expect(h.sends.length === 1 && h.sends[0] === "assign:13" && h.closed === 1 && h.hzqExtDone === true,
		"two hzqExtPick(13,true) send one assign and close once");
	h.hzqExtDone = false;
	h.hzqExtPick = pickFn;
	const confFn = (function () {
		const f = fnText(qm, "hzqExtConfirm");
		const b = f.body
			.replace(/var (\w+):[\w*.]+/g, "let $1")
			.replace(/catch\((\w+):\w+\)/g, "catch($1)")
			.replace(/int\(/g, "(");
		return new Function(b);
	})().bind(h);
	h.hzqExtOn = function () { return true; };
	h.hzqExtSel = 13;
	h.selectedIndex = 12;
	h.sends = [];
	h.closed = 0;
	expect(confFn() === true && h.sends.length === 1, "first Enter/Accept confirm sends once");
	expect(confFn() === true && h.sends.length === 1, "second Enter/Accept confirm is swallowed");
	h.hzqExtDone = false;
	h.sends = [];
	h.closed = 0;
	h.hzqExtSel = 0;
	h.selectedIndex = 0;
	expect(confFn() === false && h.sends.length === 0, "hzqExtConfirm leaves vanilla slot 0 to SelectItem");
	h.hzqExtSel = 11;
	h.selectedIndex = 11;
	expect(confFn() === false && h.sends.length === 0, "hzqExtConfirm leaves vanilla slot 11 to SelectItem");
}

// ---- G. 0435d regressions: vanilla 0-11, Tab/Escape close, inventory assign 13 and 18 persist ----
{
	const make = fnText(qm, "hzqExtMake").body;
	const hold = fnText(qm, "hzqExtEnsureClips").body;
	const user = fnText(qm, "hzqExtUser").body;
	const conf = fnText(qm, "hzqExtConfirm").body;
	const pick = fnText(qm, "hzqExtPick").body;
	expect(/s\.buttonMode = false/.test(make) && /s\.tabEnabled = false/.test(make)
		&& /s\.tabChildren = false/.test(make) && /drawRect\(-HZQ_EXT_BOX \* 0\.5,-HZQ_EXT_BOX \* 0\.5,HZQ_EXT_BOX,HZQ_EXT_BOX\)/.test(make),
		"G: extra clips are 72 px hits, not in the Tab cycle, no FavoritesEntry Catcher");
	expect(/hzqExtHold\.mouseEnabled = false/.test(hold) && /hzqExtHold\.tabEnabled = false/.test(hold)
		&& /add\.tabEnabled = false/.test(hold),
		"G: hold overlay and ADD tile do not steal Tab / do not cover Entry_0-11");
	expect(/s\.tabEnabled = false/.test(fnText(qm, "hzqRingEnsure").body),
		"G: overlay ring is out of the Tab cycle");
	expect(/u == "CANCEL"/.test(user) && /u == "QUICKKEYS"/.test(user) && /return false/.test(user),
		"G: hzqExtUser returns false for Cancel / Quickkeys so Tab reaches StartClosingMenu");
	expect(/case "Cancel":/.test(pimp) && /case "Quickkeys":/.test(pimp) && /this\.StartClosingMenu\(\)/.test(pimp)
		&& /case "Cancel":/.test(pimpL) && /this\.StartClosingMenu\(\)/.test(pimpL),
		"G: ProcessUserEvent still closes on Cancel / Quickkeys / YButton in both movies");
	expect(/slot < 13/.test(conf) && /return false/.test(conf),
		"G: hzqExtConfirm is a no-op for slots 0-11 (click / Enter / assign / use stay vanilla)");
	expect(!/this\.selectedIndex = slot/.test(pick) && /this\.selectedIndex = 12/.test(pick),
		"G: extra highlight writes FS_NONE, never selectedIndex 13-24");
	expect(/FavoritesMenu_AssignQuickkey/.test(pimp) && /uQuickkeyIndex":this\.selectedIndex/.test(pimp)
		&& /if\(int\(this\.selectedIndex\) >= 12\) return;/.test(pimp),
		"G: vanilla SelectItem still AssignQuickkey / UseQuickkey for index 0-11");
	function toJsUser() {
		const f = fnText(qm, "hzqExtUser");
		const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
		const b = f.body
			.replace(/var (\w+):[\w*.]+/g, "let $1")
			.replace(/catch\((\w+):\w+\)/g, "catch($1)");
		return new Function(...params, b);
	}
	const uh = {
		hzqExtOn() { return true; },
		confirms: 0, navs: 0,
		hzqExtConfirm() { this.confirms++; return true; },
		hzqExtNav() { this.navs++; return true; }
	};
	const userFn = toJsUser().bind(uh);
	expect(userFn("Cancel", false) === false && uh.confirms === 0 && uh.navs === 0,
		"G: Tab/Cancel is not intercepted from an extra-slot highlight");
	expect(userFn("Quickkeys", false) === false && userFn("YButton", false) === false
		&& userFn("Back", false) === false && userFn("Pause", false) === false,
		"G: Quickkeys / YButton / Back / Pause still close (not intercepted)");
	expect(userFn("Cancel", true) === false, "G: Cancel key-down is ignored (vanilla still sees the up)");
	uh.hzqExtSel = 13;
	expect(userFn("Activate", false) === true && uh.confirms === 1, "G: Activate still confirms an extra slot");
	expect(userFn("Left", false) === false && userFn("Up", false) === false && uh.navs === 0
		&& /hzqExtNav/.test(fnText(qm, "hzqExtArrow").body) && !/hzqExtNav/.test(user),
		"G: mapped Up/Down/Left/Right do not nav (keyboard arrows in hzqExtArrow only)");
	const keyName = fnText(qm, "hzqExtKeyName").body;
	expect(!/code == 9/.test(keyName) && !/code == 27/.test(keyName) && /return "";/.test(keyName),
		"G: stage KEY_UP map does not treat Tab (9) or Escape (27) as a slot key");
	expect(/QmSnapAssign\(\)/.test(game) && /QmClearPending\(\)/.test(game)
		&& /g_qmPendingHandle\.store\(s\.handle/.test(game) && /SetSlot\(g_qmStore, a\)/.test(game)
		&& /if \(!s\.handle && !s\.form && s\.name\.empty\(\)\) return;/.test(game)
		&& /GetDataForEntry/.test(game) && /hzqs::GfxU32/.test(game)
		&& /hzqExtFetch\(\)/.test(pick) && /hzqExtCmdSend\("ready"/.test(qm),
		"G: inventory assign snapshots uint FormID/handle at open, writes the store, refreshes the payload");
	expect(/this\.hzqExtCmdSend\(op,slot,extra\)/.test(pick) && /hzqExtHandle/.test(pick)
		&& /SelectQuickslot_mc != null && this\.SelectQuickslot_mc\.visible/.test(pick),
		"G: picking slot 13 or 18 sends assign with that slot (overlay-visible is assign, not use)");
	const sel = fnText(qm, "hzqSel").body;
	expect(/if\(this\.hzqExtSel < 13\)\s*\{\s*this\.hzqInfObj = this\.selectedEntry/.test(sel)
		&& (sel.match(/if\(this\.hzqExtSel < 13\)/g) || []).length >= 2,
		"G: hzqSel does not write the FS_NONE dummy into hzqInfObj while an extra slot is highlighted");
}

// ---- H. pending snapshot lifetime: A then B, ordinary open, Tab close ----
{
	const onFav = game.slice(game.indexOf("void QmOnFavoritesMovie("), game.indexOf("void QmOnFavoritesMovie(") + 1200);
	const poll = game.slice(game.indexOf("void PollFavorites("), game.indexOf("void QmOnFavoritesMovie("));
	const assign = game.slice(game.indexOf("std::string QmAssign("), game.indexOf("std::string QmHandleCmd("));
	const hud = game.slice(game.indexOf("void QmHudTick("), game.indexOf("void QmHudTick(") + 1600);
	expect(onFav.indexOf("QmClearPending();") < onFav.indexOf("g_favRoot")
		&& onFav.indexOf("QmClearPending();") < onFav.indexOf("QmSnapAssign"),
		"H: every FavoritesMenu open clears pending before a new snapshot (A then B saves B)");
	expect(/QmClearPending\(\);/.test(poll) && poll.indexOf("QmClearPending();") < poll.indexOf("QmBindExtCmd")
		&& /!ui \|\| !ui->IsMenuOpen\(QmFavName\(\)\)/.test(poll),
		"H: PollFavorites clears pending when FavoritesMenu is not open (Tab / vanilla close)");
	expect(/QmClearPending\(\);/.test(hud) && /!ui->IsMenuOpen\(QmFavName\(\)\)/.test(hud),
		"H: HUD tick also clears pending when the menu has closed");
	expect(!/QmSnapAssign\(\)/.test(assign),
		"H: QmAssign does not snapshot at click (ordinary open must not pick up a leftover item)");
	expect(/KeepPendingForAssigned\(pendingName, assigned\.name\)/.test(assign)
		&& /inline bool KeepPendingForAssigned\(/.test(rd("src/hz_quickslots.h")),
		"H: pending IDs are dropped when AssignedItem names a different item");
	expect(/case "Cancel":/.test(pimp) && /this\.StartClosingMenu\(\)/.test(pimp),
		"H: Tab/Cancel still closes; pending clear is on the close edge, not in SelectItem 0-11");
}

// ---- I. inventory-open assign actually commits; last-column ring stays inside the T ----
{
	const pick = fnText(qm, "hzqExtPick").body;
	expect(/SelectQuickslot_mc\.visible/.test(pick) && /op:String = assign \? "assign" : "use"/.test(pick)
		&& /hzqExtHandle\(this\.AssignedItem\)/.test(pick) && /"h" \+ hid\.toString\(10\)/.test(pick),
		"I: overlay-visible extra click is assign (not use) and sends hHANDLE with the item");
	function pickOp(overlay, assigned) {
		let assign = false;
		try { assign = assigned != null && String(assigned.sName != null ? assigned.sName : "").length > 0; } catch (eA) { assign = false; }
		try { if (!assign && overlay != null && overlay.visible) assign = true; } catch (eOv) {}
		return assign ? "assign" : "use";
	}
	expect(pickOp({ visible: true }, { sName: "Med Pack" }) === "assign",
		"I: inventory assign mode (AssignedItem + overlay) is assign");
	expect(pickOp({ visible: true }, { sName: "" }) === "assign",
		"I: overlay visible still assigns when sName is empty (native ItemToBeAssigned delay)");
	expect(pickOp({ visible: false }, null) === "use",
		"I: ordinary Q-open extra click is still use");
	expect(/QmGfxSlotArg/.test(game) && /IsUInt\(\)/.test(game) && /GetDataForEntry/.test(game)
		&& !/ClearSlot\(g_qmStore/.test(game.slice(game.indexOf("std::string QmAssign("), game.indexOf("std::string QmHandleCmd("))),
		"I: uint/int Scaleform IDs are read; assign commits SetSlot and does not ClearSlot on a miss");
	const bld = fnText(qm, "hzqExtBuildClips").body;
	const pitch = 86, per = 6, cx = 0, tRight = 268.8, tLeft = -267.75, tTop = -267.65, tBottom = 268.75;
	const take = 6, col = 5;
	const pad = 14, title = 22, extBox = 72, half = extBox / 2;
	const y0x = tBottom + 12 + pad + title + extBox / 2;
	const x = cx - (take - 1) * pitch / 2 + col * pitch;
	const y = y0x;
	expect(/HZQ_EXT_PITCH/.test(bld) && /y0x:Number = box\.b \+ 12 \+ HZQ_FRAME_PAD \+ HZQ_FRAME_TITLE \+ HZQ_EXT_BOX \* 0\.5/.test(bld),
		"I: extra row sits under the T, below the EXTENDED frame title");
	const visL = -960, visR = 960, visT = -540, visB = 540;
	expect(x + half <= visR && x - half >= visL && y - half >= visT && y + half <= visB,
		"I: last-column 72 px extra card (and filled ring) stays inside the visible area");
	expect(0 + 29 <= tRight && 0 - 29 >= tLeft,
		"I: the selected top T card (center, screenshot) sits inside the T AABB, so a T-width scrollRect cannot cut its right edge");
	const x8 = cx - (8 - 1) * pitch / 2 + 7 * pitch;
	expect(x8 + half > tRight && x8 + half <= visR,
		"I: an 8-per-row extra last column sticks out of the T AABB but stays in the visible area");
	expect(/function hzqAccentRing/.test(qm) && /function hzqFilledBorder/.test(qm)
		&& /this\.hzqAccentRing\(g,x,y,box\)/.test(fnText(qm, "hzqRingDraw").body),
		"I: ring is a filled border on the overlay, same size as the card");
	expect(/function hzqInfoPlace/.test(qm) && /Extensions\.visibleRect/.test(fnText(qm, "hzqInfoPlace").body)
		&& /vr\.right,vr\.top/.test(fnText(qm, "hzqInfoPlace").body)
		&& /vr\.right,vr\.bottom/.test(fnText(qm, "hzqInfoPlace").body)
		&& /\(tr\.y \+ br\.y\) \* 0\.5 - H \* 0\.5/.test(fnText(qm, "hzqInfoPlace").body)
		&& !/HZQ_EQ_RESERVE/.test(fnText(qm, "hzqInfoPlace").body)
		&& /this\.hzqSprite\(this, -1\)/.test(fnText(qm, "hzqBuild").body),
		"I: info panel is a menu child, placed at visibleRect center-right (right inset, vertically centered)");
	expect(/EXTENDED QUICK \/ FAVORITE SLOTS/.test(qm) && /function hzqExtFrameDraw/.test(qm),
		"I: extra grid has a Horizon framed box titled EXTENDED QUICK / FAVORITE SLOTS");
	{
		const frame = fnText(qm, "hzqExtFrameDraw").body;
		const setb = fnText(qm, "hzqSet").body;
		const face = fnText(qm, "hzqFace").body;
		expect(/this\.hzqSet\(this\.hzqExtFrameT,this\.hzqUC\("EXTENDED QUICK \/ FAVORITE SLOTS"\),13,this\.hzqTextAccent\(\),"bd",0\.14,true\)/.test(frame)
			&& /this\.hzqFace\(w\)/.test(setb) && /t\.embedFonts = true/.test(setb)
			&& /\$Horizon_Font/.test(face) && !/new TextFormat\(\s*["']/.test(frame)
			&& !/_sans|Arial|Times|Courier|Exo 2|Exo2/.test(frame),
			"I: EXTENDED QUICK title uses hzqSet -> hzqFace (embedded Horizon face), not a hardcoded/system font");
		expect(/this\.hzqSet\(o\.k,klab,13,/.test(fnText(qm, "hzqExtDraw").body)
			&& /this\.hzqSet\(nt,/.test(fnText(qm, "hzqInfo").body)
			&& /this\.hzqSet\(lt,this\.hzqUC\(String\(rows\[j\]\[0\]\)\),13,/.test(fnText(qm, "hzqInfo").body),
			"I: extra key chips and the info panel text use the same hzqSet / hzqFace path");
		expect(/this\.hzqFace\("bd"\)/.test(frame)
			&& /this\.hzqExtFontTouch\(\)/.test(fnText(qm, "hzqRedraw").body)
			&& /this\.hzqExtFrameDraw\(this\.hzqExtLastBox\)/.test(fnText(qm, "hzqRedraw").body)
			&& /this\.hzqExtSlots\[i\]\.cKey = null/.test(fnText(qm, "hzqExtFontTouch").body),
			"I: after font.marker, redraw retitles the extra frame and re-sets extra key chips through hzqFace");
		expect(/this\.hzqSet\(this\.hzqExtFrameT,this\.hzqUC\("EXTENDED QUICK \/ FAVORITE SLOTS"\)/.test(pimp)
			&& /this\.hzqSet\(this\.hzqExtFrameT,this\.hzqUC\("EXTENDED QUICK \/ FAVORITE SLOTS"\)/.test(pimpL)
			&& /t\.embedFonts = true/.test(fnText(pimp, "hzqSet").body)
			&& /t\.embedFonts = true/.test(fnText(pimpL, "hzqSet").body),
			"I: both movies apply the shared Horizon font helper to the extra frame title");
	}
	expect(/new ImageFixture\(\)/.test(fnText(qm, "hzqExtMake").body)
		&& /LoadImageFixtureFromUIData\(img,"FavoritesIconBuffer"\)/.test(fnText(qm, "hzqExtLoadIcon").body)
		&& !/o\.n/.test(fnText(qm, "hzqExtDraw").body)
		&& !/empty \? "EMPTY"/.test(fnText(qm, "hzqExtDraw").body),
		"I: extra cards show vanilla Icon_mc + key chip, no item name, no EMPTY text");
	const loadBody = fnText(qm, "hzqExtLoadIcon").body;
	expect(loadBody.indexOf("ic.onLoadAttemptComplete = this.hzqExtIcCb[ei]") < loadBody.indexOf("ic.LoadImageFixtureFromUIData")
		&& /this\.hzqExtIconBound\(ic\)/.test(loadBody)
		&& /HZQ_ICBOUND/.test(fnText(qm, "hzqExtIconBound").body)
		&& !/clipWidth|clipHeight/.test(loadBody),
		"I: extra LoadIcon matches vanilla: BoundClip 60x60, hook before Load, no clipWidth/clipHeight (those distort)");
	const fitBody = fnText(qm, "hzqExtFitIcon").body;
	expect(fitBody.indexOf("ic.scaleX = b.sx;") < fitBody.indexOf("this.hzqIcB(ic,e)")
		&& /Math\.min\(1,Math\.min\(aw \/ nb\.width,ah \/ nb\.height\)\)/.test(fitBody)
		&& /Number\(o\.kb\) > 0/.test(fitBody),
		"I: extra icon fit resets to identity, then scales after the loaded bounds, below the key chip");
	expect(/function hzqExtIcDone/.test(qm) && /function hzqExtIc13/.test(qm) && /function hzqExtIc24/.test(qm)
		&& /this\.hzqExtIcCb = \[this\.hzqExtIc13/.test(fnText(qm, "hzqBuild").body),
		"I: extra icon-load edge is the same per-slot callback pattern as vanilla 1-12");
	expect(/function hzqExtFitIcon/.test(pimp) && /function hzqExtIconBound/.test(pimp)
		&& /function hzqExtFitIcon/.test(pimpL) && /function hzqExtIconBound/.test(pimpL)
		&& /function hzqInfoPlace/.test(pimp) && /function hzqInfoPlace/.test(pimpL),
		"I: extra icon fit and center-right info are in both movies");
	const infoW = 380, infoH = 120, m = 16;
	function infoAt(visR, visT, visB) {
		return { x: visR - m - infoW, y: (visT + visB) * 0.5 - infoH * 0.5, w: infoW, h: infoH };
	}
	function overlaps(a, bx, by, bw, bh) {
		return a.x < bx + bw && a.x + a.w > bx && a.y < by + bh && a.y + a.h > by;
	}
	const inf1080 = infoAt(960, -540, 540);
	const inf1440 = infoAt(1280, -720, 720);
	const infUw = infoAt(1720, -720, 720);
	const slotR = x + half, slotB = y + half, slotL = x - half, slotT = y - half;
	expect(!overlaps(inf1080, slotL, slotT, slotR - slotL, slotB - slotT)
		&& !overlaps(inf1440, slotL, slotT, slotR - slotL, slotB - slotT)
		&& !overlaps(infUw, slotL, slotT, slotR - slotL, slotB - slotT),
		"I: center-right info panel does not overlap the last extra slot at 1920x1080, 2560x1440, or ultrawide");
	expect(!overlaps(inf1080, tLeft, tTop, tRight - tLeft, tBottom - tTop)
		&& !overlaps(inf1440, tLeft, tTop, tRight - tLeft, tBottom - tTop)
		&& !overlaps(infUw, tLeft, tTop, tRight - tLeft, tBottom - tTop),
		"I: center-right info panel does not overlap the vanilla T at 1920x1080, 2560x1440, or ultrawide");
	expect(!overlaps(inf1080, 960 - 280, 540 - 84, 280, 84)
		&& !overlaps(inf1440, 1280 - 280, 720 - 84, 280, 84)
		&& !overlaps(infUw, 1720 - 280, 720 - 84, 280, 84),
		"I: center-right info panel does not overlap the HUD equipment card on the right edge");
}

// ---- J. weapon icons use the HUD equipment-card accent ColorTransform ----
{
	const eq = fnText(hud, "hzE19PlaceIcons").body;
	const tints = fnText(qm, "hzqTints").body;
	const apply = fnText(qm, "hzqApplyIconTint").body;
	const isW = fnText(qm, "hzqIsWeapon").body;
	expect(/ColorTransform\(0,0,0,1,\(col >> 16\) & 0xFF,\(col >> 8\) & 0xFF,col & 0xFF,0\)/.test(eq)
		&& /this\.hzIconCol\(this\.hzEqLow \? HZ_AMB : HZ_ACCENT\)/.test(eq),
		"J: equipment card tints the weapon symbol with hzIconCol(accent) and ColorTransform(0,0,0,1,r,g,b,0)");
	expect(/this\.hzqIconCol\(this\.hzqAccent\(\)\)/.test(tints)
		&& /this\.hzqCtW\.redMultiplier = 0/.test(tints)
		&& /this\.hzqCtW\.redOffset = \(a >> 16\) & 0xFF/.test(tints)
		&& /this\.hzqCtW\.greenOffset = \(a >> 8\) & 0xFF/.test(tints)
		&& /this\.hzqCtW\.blueOffset = a & 0xFF/.test(tints)
		&& /this\.hzqCtW\.alphaMultiplier = 1/.test(tints)
		&& /this\.hzqCtW\.alphaOffset = 0/.test(tints)
		&& !/HZ_AMB|hzEqLow/.test(tints),
		"J: Quick Menu hzqCtW is that same add-RGB transform; color source is hzqIconCol(hzqAccent()), no ammo-amber");
	expect(/function hzqIconCol/.test(qm) && codeOnly(fnText(qm, "hzqIconCol").body).replace(/\s+/g, "")
		=== codeOnly(fnText(hud, "hzIconCol").body).replace(/this\.hz/g, "this.hzq").replace(/\s+/g, ""),
		"J: hzqIconCol is the HUD hzIconCol helper (light-card contrast)");
	expect(/this\.hzqApplyIconTint\(ic,this\.hzqIsWeapon\(it\),empty,sel,it\)/.test(fnText(qm, "hzqCard").body)
		&& /this\.hzqApplyIconTint\(fe\["Icon_mc"\]/.test(fnText(qm, "hzqIcDone").body),
		"J: slots 1-12 tint on card draw and after the icon-load callback");
	expect(/if\(weap\) \{ ic\.transform\.colorTransform = this\.hzqCtW; return; \}/.test(apply)
		&& /FT_SYMBOL/.test(apply) && /this\.hzqCtA/.test(apply) && /this\.hzqCtN/.test(apply),
		"J: weapons always get hzqCtW; other symbols keep selected-accent; non-weapon pictures stay identity");
	expect(/it\.bIsPower == true/.test(isW) && /it\.bIsEquippable == true/.test(isW)
		&& /aElementalStats/.test(isW) && /sAmmoName/.test(isW),
		"J: a favorite is a weapon when it is equippable (or has ammo/damage) and not a power");
	function toJsIsW() {
		const b = fnText(qm, "hzqIsWeapon").body
			.replace(/var (\w+):[\w*.]+/g, "let $1")
			.replace(/catch\((\w+):\w+\)/g, "catch($1)");
		return new Function("it", b);
	}
	const isWeapon = toJsIsW();
	expect(isWeapon({ sName: "Grendel", bIsEquippable: true, sAmmoName: "7.77mm" }) === true, "J: an equippable gun is a weapon");
	expect(isWeapon({ sName: "Tanto", bIsEquippable: true }) === true, "J: melee (equippable, no ammo) is a weapon");
	expect(isWeapon({ sName: "Med Pack", bIsEquippable: false, uCount: 4 }) === false, "J: aid is not a weapon");
	expect(isWeapon({ sName: "Personal Atmosphere", bIsPower: true, bIsEquippable: true }) === false, "J: a power is not a weapon");
	expect(isWeapon({ sName: "Razorback", aElementalStats: [{ iElementalType: 0, fValue: 12 }] }) === true,
		"J: damage stats still count as a weapon if the equippable flag is missing");
	const extW = fnText(qm, "hzqExtIsWeapon").body;
	expect(/d\.weap === true/.test(extW) && /kind == "power"/.test(extW) && /kind == "essence"/.test(extW)
		&& /this\.hzqIsWeapon\(this\.hzqExtIconSrc\(d\)\)/.test(extW),
		"J: extras use the DLL weap flag (TESObjectWEAP), then the same 1-12 helper");
	expect(/this\.hzqExtTintIcon\(o,d,empty,sel\)/.test(fnText(qm, "hzqExtDraw").body)
		&& fnText(qm, "hzqExtDraw").body.indexOf("this.hzqExtTintIcon")
			> fnText(qm, "hzqExtDraw").body.indexOf("o.cKey = key")
		&& /this\.hzqExtTintIcon/.test(fnText(qm, "hzqExtIcDone").body)
		&& /this\.hzqExtTintIcon/.test(fnText(qm, "hzqExtLoadIcon").body)
		&& /this\.hzqApplyIconTint\(o\.ic/.test(fnText(qm, "hzqExtTintIcon").body),
		"J: extras re-tint on every draw (accent change, no reload) and after the load callback");
	expect(/form->Is\(RE::FormType::kWEAP\)/.test(game) && /weap\[i - hzqs::kExtFirst\]/.test(game)
		&& /f\.length > 9 && String\(f\[9\]\) == "1"/.test(fnText(qm, "hzqExtApply").body),
		"J: ready payload field 9 is 1 when LookupByID is TESObjectWEAP; assign/use extra is unchanged");
	expect(!/QmAssign/.test(fnText(qm, "hzqTints").body) && !/hzqExtCmdSend/.test(fnText(qm, "hzqApplyIconTint").body)
		&& !/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout/.test(codeOnly(tints + apply + fnText(qm, "hzqExtTintIcon").body)),
		"J: tint is change-driven (redraw / load); no poll, no assign/key-equip change");
	expect(/function hzqApplyIconTint/.test(pimp) && /function hzqApplyIconTint/.test(pimpL)
		&& /hzqCtW/.test(pimp) && /hzqCtW/.test(pimpL),
		"J: both movies carry the equipment-card weapon tint");
}

console.log("quickmenu_assign_keys_test " + (failed ? "FAILED" : "passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
