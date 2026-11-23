// 0.43.6 round 4: the Comms movies do no settings file read on gameplay events once the DLL pushes saves.
// Why: Scaleform here has no task manager, so a URLLoader load runs inside the movie's Advance, and
// BSScaleformFileOpener blocks on the game's resource system until the file is in memory. Each settings read is three
// sequential loads (default, user, state ini); in the Comms-on capture the stalls come in trains of 1-3, 2-5 frames
// apart, matching that. The Comms-off capture had none.
// Checks, in every shipped copy, by running the real functions on small models:
//  1. hzc (hzc_block.as, both HUDMessagesMenu.as): a scanner open (FireForget event or the DLL scan push) no longer
//     re-reads with the DLL announce; it still re-reads for an older DLL or before any settings landed; the scan state,
//     its frame tick, alphas and toast run as before; every gameplay-event read site is gated the same way;
//  2. hzd (hzd_block.as, both DialogueMenu.as): one re-read per conversation instead of one per dialogue update;
//     a closing update or a new showing re-arms it; a failed read still retries; the 1 s throttle and the
//     "nothing read yet" guard stay;
//  3. DLL (src/main.cpp): CommsRxPoll returns on an empty HUD-message batch before the dialogue check, the
//     Messages_mc reads and the phrase-table copy;
//  4. the copies of each changed function are the same text.
// Run: node tests/round4_comms_io_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const fs = require("fs");
const path = require("path");
const { root, stripComments, fnText, mkFn, argNames, baseHost, expect, finish } = require("./lib/r3");

const rd = (p) => stripComments(fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n"));
const HZC = [["hzc_block", "comms/hzc_block.as"], ["HUDMessagesMenu", "imp/imp/scripts/HUDMessagesMenu.as"], ["HUDMessagesMenu_lrg", "imp/imp-Lrg/scripts/HUDMessagesMenu.as"]];
const HZD = [["hzd_block", "comms/hzd_block.as"], ["DialogueMenu", "imp/dimp/scripts/DialogueMenu.as"], ["DialogueMenu_lrg", "imp/dimp-Lrg/scripts/DialogueMenu.as"]];
const norm = (s) => s.replace(/\s+/g, " ").trim();

// ---- 1. hzc ----
const ffBodies = [], dsBodies = [];
HZC.forEach(([tag, rel]) => {
	const src = rd(path.join(root, "actionscript", rel));
	const ff = fnText(src, "hzcOnFF"), ds = fnText(src, "hzcDllScan");
	ffBodies.push(norm(ff.body)); dsBodies.push(norm(ds.body));
	function mk(o) {
		const h = baseHost(Object.assign({
			GlobalFunc: { HasFireForgetEvent: (d, n) => !!(d && d.aEvents && d.aEvents.some((e) => e.sEventName === n)) },
			Event: { ENTER_FRAME: "enterFrame" }, getTimer: () => 1000,
			hzcIniPush: true, hzcIniState: 1, hzcScan: false, hzcScanShip: false, hzcScanTick: false, hzcDllOn: false, hzcFFClosed: false,
			hzcScanT0: 0, hzcScanLast: 0, hzcDllT: 0,
			reloads: 0, alphas: 0, toasts: 0, listeners: 0,
			hzcReload() { this.reloads++; }, hzcRefreshAlphas() { this.alphas++; }, hzcToastVis() { this.toasts++; },
			hzcDllFresh() { return true; }, hzcScanFrame() {}, addEventListener() { this.listeners++; },
		}, o || {}));
		h.hzcOnFF = mkFn(h, argNames(ff.sig), ff.body);
		h.hzcDllScan = mkFn(h, argNames(ds.sig), ds.body);
		return h;
	}
	const open = { data: { aEvents: [{ sEventName: "MonocleMenu_Opened" }] } };
	{
		const h = mk();
		h.hzcOnFF(open);
		expect(h.reloads === 0 && h.hzcScan === true && h.hzcScanTick === true && h.listeners === 1 && h.alphas === 1 && h.toasts === 1,
			tag + ": with the DLL announce, a scanner open (FireForget) reads no file and still enters the scan state");
		const g = mk();
		g.hzcDllScan(true);
		expect(g.reloads === 0 && g.hzcScan === true && g.hzcScanTick === true && g.alphas === 1, tag + ": the DLL scan push enters the scan state with no file read");
	}
	{
		const h = mk({ hzcIniPush: false });
		h.hzcOnFF(open);
		const g = mk({ hzcIniPush: true, hzcIniState: 0 });
		g.hzcDllScan(true);
		expect(h.reloads === 1 && g.reloads === 1, tag + ": an older DLL, or no settings landed yet, still re-reads on a scanner open");
	}
	{
		const h = mk();
		h.hzcOnFF({ data: { aEvents: [{ sEventName: "Inventory_MouseInspect" }] } });
		expect(h.reloads === 0 && h.alphas === 0 && h.toasts === 0, tag + ": any other FireForget event still returns at once");
	}
	// every hzcReload site outside start-up / the older-DLL poll / the DLL save push is gated on the announce
	{
		const lines = src.split("\n").filter((l) => l.indexOf("this.hzcReload();") >= 0);
		const gated = lines.filter((l) => l.indexOf("if(!this.hzcIniPush || this.hzcIniState == 0) { this.hzcReload(); }") >= 0).length;
		expect(lines.length === 7 && gated === 3, tag + ": 7 read sites, the 3 gameplay-event ones (HUD mode, both scanner opens) gated");
		const ctor = fnText(src, "hzcOnPoll"), saved = fnText(src, "hzcIniSaved");
		expect(ctor && /this\.hzcReload\(\)/.test(ctor.body) && saved && /this\.hzcReload\(\)/.test(saved.body), tag + ": the older-DLL poll and the DLL save push still read");
	}
});
expect(ffBodies.every((b) => b === ffBodies[0]) && dsBodies.every((b) => b === dsBodies[0]), "hzcOnFF and hzcDllScan are the same text in all three copies");

// ---- 2. hzd ----
const rlBodies = [], duBodies = [];
HZD.forEach(([tag, rel]) => {
	const src = rd(path.join(root, "actionscript", rel));
	const rl = fnText(src, "hzdReload");
	expect(rl != null, tag + ": hzdReload exists");
	rlBodies.push(norm(rl.body));
	const du = (() => { const i = src.indexOf("override protected function onDataUpdate("); const b = src.indexOf("{", i); let d = 0; for (let p = b; p < src.length; p++) { if (src[p] === "{") d++; else if (src[p] === "}") { d--; if (d === 0) return src.slice(b + 1, p); } } return ""; })();
	duBodies.push(norm(du));
	let clock = 0;
	function mk(o) {
		const h = baseHost(Object.assign({ hzdIni: 1, hzdTalkRead: false, hzdReloadT: -100000, reads: 0, getTimer: () => clock,
			hzdIniLoad() { this.reads++; } }, o || {}));
		h.hzdReload = mkFn(h, argNames(rl.sig), rl.body);
		return h;
	}
	{
		const h = mk();
		for (let i = 0; i < 40; i++) { clock = 5000 + i * 1500; h.hzdReload(); }
		expect(h.reads === 1 && h.hzdTalkRead === true, tag + ": 40 dialogue updates over a minute read the settings once (was once per update, 1 s throttle)");
		h.hzdTalkRead = false; clock += 1500; h.hzdReload();
		expect(h.reads === 2, tag + ": the next conversation (re-armed) reads once more");
	}
	{
		const h = mk({ hzdIni: 2, hzdTalkRead: true });
		clock = 100000; h.hzdReload(); clock += 1500; h.hzdReload();
		expect(h.reads === 2, tag + ": a failed read (state 2) still retries, throttled");
		const z = mk({ hzdIni: 0 });
		clock += 5000; z.hzdReload();
		expect(z.reads === 0, tag + ": nothing is read while the first read is still in flight");
		const t = mk();
		clock = 200000; t.hzdReloadT = clock - 500; t.hzdReload();
		expect(t.reads === 0, tag + ": the 1 s throttle stays");
	}
	expect(/if\(param1\.data\.bClosingMenu\) \{ this\.hzdTalkRead = false;/.test(du) && du.indexOf("this.hzdReload();") >= 0, tag + ": a closing update re-arms the read for the next conversation");
	const st = fnText(src, "hzdOnStage");
	expect(st && /this\.hzdTalkRead = false;/.test(st.body), tag + ": a new showing of the menu re-arms the read");
	expect(/private var hzdTalkRead:Boolean = false;/.test(src), tag + ": hzdTalkRead starts false (the first update of a conversation reads once)");
});
expect(rlBodies.every((b) => b === rlBodies[0]) && duBodies.every((b) => b === duBodies[0]), "hzdReload and onDataUpdate are the same text in all three copies");

// ---- 3. DLL ----
{
	const cpp = fs.readFileSync(path.join(root, "src", "main.cpp"), "utf8").replace(/\r\n/g, "\n");
	const i = cpp.indexOf("\tvoid CommsRxPoll(ULONGLONG a_now)");
	const b = cpp.indexOf("{", i); let d = 0, body = "";
	for (let p = b; p < cpp.length; p++) { if (cpp[p] === "{") d++; else if (cpp[p] === "}") { d--; if (d === 0) { body = cpp.slice(b, p + 1); break; } } }
	const sw = body.indexOf("batch.swap(g_rxQ);"), er = body.indexOf("if (batch.empty()) return;");
	expect(sw > 0 && er > sw, "DLL: CommsRxPoll returns on an empty batch right after taking it");
	expect(er < body.indexOf("IsMenuOpen(\"DialogueMenu\")") && er < body.indexOf("HzRxMessagesVisible(ui)") && er < body.indexOf("MsgPhrasesSnap()"),
		"DLL: the empty-batch return comes before the dialogue check, the Messages_mc reads and the phrase-table copy");
	expect(body.indexOf("hzcCardPush") > 0 && body.indexOf("hzmsg::Match(n.text, phrases)") > er, "DLL: a queued message is still matched and pushed as before");
}

finish("round4_comms_io_test");
