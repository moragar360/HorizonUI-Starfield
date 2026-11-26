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
			&& /KeepPendingForAssigned/.test(assign),
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

// ---- B. selection outline sits fully inside the 58 px panel ----
{
	const ring = fnText(qm, "hzqRingDraw").body;
	expect(/drawRoundRect\(x - 26,y - 26,52,52,14,14\)/.test(ring) && /lineStyle\(2,acc,1,true,"none"\)/.test(ring),
		"accent hover/focus stroke is a 2 px overlay ring (menu-level, 52 px, scale none)");
	expect(/function hzqUnclip/.test(qm) && /gotoAndStop\("Unselected"\)/.test(fnText(qm, "hzqCard").body),
		"vanilla Selected-frame outline is not used; Entry/Catcher mask and scrollRect are cleared");
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
	expect(/function hzqExtHideVan/.test(qm) && /d\.name != "hzqCard"/.test(fnText(qm, "hzqExtHideVan").body)
		&& /Quickkey_tf/.test(fnText(qm, "hzqExtHideVan").body)
		&& /hzqExtHideVan\(s\)/.test(make) && /hzqExtHideVan\(o\.s/.test(fnText(qm, "hzqExtDraw").body),
		"Entry_13-24 hide vanilla outline / icon frame / key label; only the Horizon card stays visible");
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
		isAssigningItem() { return true; }, hzqExtFormId() { return 0; }, hzqExtHex() { return ""; },
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
		&& /s\.tabChildren = false/.test(make) && /drawRect\(-29,-29,58,58\)/.test(make),
		"G: extra clips are 58 px hits, not in the Tab cycle, no FavoritesEntry Catcher");
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
		&& /hzqExtFetch\(\)/.test(pick) && /hzqExtCmdSend\("ready"/.test(qm),
		"G: inventory assign snapshots FormID at open, writes the store, refreshes the payload");
	expect(/this\.hzqExtCmdSend\(op,slot,extra\)/.test(pick),
		"G: picking slot 13 or 18 sends assign with that slot (persists via SetSlot + payload fetch)");
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

console.log("quickmenu_assign_keys_test " + (failed ? "FAILED" : "passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
