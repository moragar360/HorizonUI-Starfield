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
	expect(/this\.selectedIndex = 12/.test(pick) && /this\.hzqExtCmdSend\(op,slot,extra\)/.test(pick),
		"assign/use for 13-24 goes through hzqExtCmd, with selectedIndex parked at FS_NONE");
	expect(!/FavoritesMenu_AssignQuickkey/.test(qm) && !/dispatchEvent/.test(qm),
		"Horizon extra-slot path never sends FavoritesMenu_AssignQuickkey");
	const conf = fnText(qm, "hzqExtConfirm").body;
	expect(/hzqExtSel < 13/.test(conf) && /hzqExtPick\(this\.hzqExtSel,true\)/.test(conf),
		"hzqExtConfirm only fires when an extra slot is highlighted");
	expect(/if\(this\.hzqExtConfirm\(\)\) return;/.test(pimp) && /if\(this\.hzqExtConfirm\(\)\) return;/.test(pimpL),
		"SelectItem in both movies returns after hzqExtConfirm (never AssignQuickkey index 12)");
	expect(/hzqExtUser\(param1,param2\)/.test(pimp) && /hzqExtArrow\(param1\)/.test(pimp)
		&& /Keyboard\.ENTER && this\.hzqExtConfirm/.test(pimp),
		"ProcessUserEvent / arrows / ENTER are hooked so hover+Enter and D-pad reach 13-24");
	expect(/hzqExtUser\(param1,param2\)/.test(hooks) && /hzqE8/.test(hooks),
		"apply_fav_hooks.py plants the extra-slot confirm hooks on a fresh vanilla export");
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
	expect(/selectedIndex\) < 12 && this\.hzqExtSel != 0/.test(fnText(qm, "hzqSel").body),
		"a vanilla 1-12 selection clears the extra-slot highlight");
	expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout/.test(codeOnly(qm.slice(qm.indexOf("0.43.5 Extended Mode")))),
		"assign path adds no enterFrame / timer");
}

// ---- B. selection outline sits fully inside the 58 px panel ----
{
	const card = fnText(qm, "hzqCard").body;
	const drw = fnText(qm, "hzqExtDraw").body;
	expect(/drawRoundRect\(r\.x \+ 3,r\.y \+ 3,r\.width - 6,r\.height - 6,14,14\)/.test(card)
		&& /lineStyle\(2,acc,1,true,"none"\)/.test(card),
		"slots 1-12: 2 px selection stroke is inset 3 px (inside Catcher), scale none");
	expect(/drawRoundRect\(-26,-26,52,52,14,14\)/.test(drw) && /drawRect\(-33,-33,66,66\)/.test(drw),
		"slots 13-24: matching inset stroke plus an invisible pad so Scaleform does not clip the line");
	expect(/drawRect\(r\.x - 4,r\.y - 4,r\.width \+ 8,r\.height \+ 8\)/.test(card),
		"slots 1-12: the same invisible pad expands sprite bounds");
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

console.log("quickmenu_assign_keys_test " + (failed ? "FAILED" : "passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
