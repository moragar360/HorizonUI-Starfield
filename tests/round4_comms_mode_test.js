// 0.43.6 round 4: the Comms movie no longer re-reads its settings on every HudModeData event once the DLL has
// announced its settings-saved push (hzcIniSaved). Before, each HUD mode event started a read of the default, user
// and state INI files and a 25 KB merge in the HUD messages movie, which the DLL push already covers for every write.
// Checks, in all three copies (hzc_block.as and both HUDMessagesMenu.as hosts), by running the real hzcOnMode:
// an older DLL (no announce) still re-reads on every mode event; with the announce there is no re-read; with the
// announce but no settings landed yet the old retry stays; the rest of the handler (dialogue clear, scan safety clear,
// layer visibility, layout, toast) runs as before; hzcIniSaved and the start-up read still re-read; no new timer,
// listener or frame work is added; the three copies of hzcOnMode are the same text.
// Run: node tests/round4_comms_mode_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const fs = require("fs");
const path = require("path");
const { root, stripComments, fnText, mkFn, argNames, baseHost, expect, finish } = require("./lib/r3");

const FILES = [path.join(root, "actionscript", "comms", "hzc_block.as"),
	path.join(root, "actionscript", "imp", "imp", "scripts", "HUDMessagesMenu.as"),
	path.join(root, "actionscript", "imp", "imp-Lrg", "scripts", "HUDMessagesMenu.as")];
const TAGS = ["hzc_block", "HUDMessagesMenu", "HUDMessagesMenu_lrg"];
const HUDUtils = { FLOATING_QUEST_MARKERS: 0, ENEMY_HEALTH_METER: 1, QUEST_UPDATES: 2, HIT_AND_KILL_INDICATORS: 3, CENTER_GROUP: 4,
	QUICK_CONTAINER: 5, BOTTOM_LEFT_GROUP: 6, BOTTOM_CENTER_GROUP_ADJUST_VERTICALLY: 7, TOP_CENTER_GROUP: 8, BOTTOM_CENTER_GROUP: 9,
	RIGHT_METERS: 10, LOCATION: 11, XP_GROUP: 12, SOCIAL_COMMAND_ICONS: 13, MESSAGES: 14, LEVEL_UP_PROMPT: 15,
	XP_GROUP_ADJUST_VERTICALLY: 16, MODE_COUNT: 17 };
function ev(dlg, group, quick) {
	const a = [];
	for (let i = 0; i < HUDUtils.MODE_COUNT; i++) a.push({ bVisible: true });
	a[HUDUtils.BOTTOM_CENTER_GROUP_ADJUST_VERTICALLY].bVisible = dlg;
	a[HUDUtils.BOTTOM_CENTER_GROUP].bVisible = group;
	a[HUDUtils.QUICK_CONTAINER].bVisible = quick;
	return { data: { ModeVisibilityA: a } };
}

const bodies = [];
FILES.forEach((file, fi) => {
	const tag = TAGS[fi];
	const raw = fs.readFileSync(file, "utf8").replace(/\r\n/g, "\n");
	const src = stripComments(raw);
	const f = fnText(src, "hzcOnMode");
	expect(f != null, tag + ": hzcOnMode exists");
	bodies.push(f.body.replace(/\s+/g, " ").trim());
	function mk(o) {
		const h = baseHost(Object.assign({
			HUDUtils: HUDUtils, Boolean: Boolean,
			hzcInDlg: false, hzcGroupVis: true, hzcScan: false, hzcDllOn: false, hzcShown: false, hzcLine: "x",
			hzcIniPush: false, hzcIniState: 1, hzcLayer: { visible: true },
			reloads: 0, layouts: 0, toasts: 0, hides: 0, alphas: 0,
			hzcReload() { this.reloads++; }, hzcLayout() { this.layouts++; }, hzcToastVis() { this.toasts++; },
			hzcHideCards() { this.hides++; }, hzcRefreshAlphas() { this.alphas++; }, hzcDllFresh() { return false; },
		}, o || {}));
		h.hzcOnMode = mkFn(h, argNames(f.sig), f.body);
		return h;
	}
	// an older DLL that never announced hzcIniSaved: every mode event re-reads, as before
	{
		const h = mk({ hzcIniPush: false, hzcIniState: 1 });
		for (let i = 0; i < 5; i++) h.hzcOnMode(ev(false, true, i % 2 == 0));
		expect(h.reloads === 5 && h.toasts === 5, tag + ": without the DLL announce each HUD mode event still re-reads (older DLL keeps working)");
	}
	// the current DLL announced: no re-read on mode events (its push re-reads after every write)
	{
		const h = mk({ hzcIniPush: true, hzcIniState: 1 });
		for (let i = 0; i < 40; i++) h.hzcOnMode(ev(false, true, i % 2 == 0));
		expect(h.reloads === 0 && h.toasts === 40, tag + ": with the DLL announce, 40 mode events start no settings read and still update the toast");
	}
	// announced, but no settings text landed yet: the old mode-event retry stays
	{
		const h = mk({ hzcIniPush: true, hzcIniState: 0 });
		h.hzcOnMode(ev(false, true, true));
		expect(h.reloads === 1, tag + ": with no settings landed yet a mode event still retries the read");
	}
	// the rest of the handler is unchanged: dialogue exit clears the line, the group hide sets the layer, layout runs
	{
		const h = mk({ hzcIniPush: true, hzcInDlg: true, hzcShown: true });
		h.hzcOnMode(ev(false, false, true));
		expect(h.hzcLine === "" && h.hides === 1 && h.hzcLayer.visible === false && h.layouts === 1 && h.hzcGroupVis === false,
			tag + ": leaving dialogue clears the line and hides the cards; the group flag drives the layer; layout runs when shown");
		const s = mk({ hzcIniPush: true, hzcScan: true, hzcGroupVis: true });
		s.hzcOnMode(ev(false, false, true));
		expect(s.hzcScan === false && s.alphas === 1 && s.toasts === 2, tag + ": the HUD group going away still ends the scan state");
		const b = mk({ hzcIniPush: true });
		b.hzcOnMode({ data: { ModeVisibilityA: [] } });
		expect(b.reloads === 0 && b.toasts === 0, tag + ": a short mode array is still ignored");
	}
	// the other read paths are untouched
	{
		const saved = fnText(src, "hzcIniSaved");
		expect(saved && /else \{ this\.hzcReload\(\); \}/.test(saved.body), tag + ": hzcIniSaved (the DLL push) still re-reads once per save");
		expect((src.match(/this\.hzcReload\(\);/g) || []).length === 7, tag + ": every other re-read site is kept (start-up, poll, push, scanner open)");
		expect(/private function hzcOnPoll\(e:TimerEvent\) : void \{ this\.hzcReload\(\); \}/.test(src), tag + ": the older-DLL 5 s poll is kept");
		const mb = f.body;
		expect(mb.indexOf("addEventListener") < 0 && mb.indexOf("new ") < 0 && mb.indexOf("Timer") < 0, tag + ": hzcOnMode adds no listener, allocation or timer");
	}
});
expect(bodies[0] === bodies[1] && bodies[1] === bodies[2], "the three copies of hzcOnMode are the same text");
finish("round4_comms_mode_test");
