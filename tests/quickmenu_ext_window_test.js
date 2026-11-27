// 0.43.5 extra-slots window: occupied counter, empty-slot hide, panel opacity / slot scale INI.
// Source pins + HUD / movie round-trip. Run: node tests/quickmenu_ext_window_test.js
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

const qm = rd("actionscript/favorites/hzq_main.as");
const hud = rd("actionscript/horizon_block.as");
const ini = rd("Interface/HorizonUI/HorizonUI.default.ini");
const reader = rd("actionscript/favorites/hzq37_reader.as");
const src = qm + reader;

const consts = {};
for (const m of src.matchAll(/private static const (HZQ_\w+|hzq37_\w+):\w+ = (.*);/g)) {
	let v = m[2].replace(/__HZQ_LRG__/, "false").replace(/String\.fromCharCode\(0xFEFF\)/, '"\\uFEFF"');
	consts[m[1]] = eval("(" + v + ")");
}

expect(consts.HZQ_BOX === 58 && consts.HZQ_EXT_BOX === 58 && consts.HZQ_EXT_GAP === 14 && consts.HZQ_EXT_PITCH === 72,
	"vanilla 1-12 metrics: 58 box, extras match at scale 1.0 (gap 14, pitch 72)");
expect(/HZQ_ICPAD:Number = 4/.test(qm) && /hzqKeycap\(g,-hb \+ 5,-hb \+ 5/.test(qm)
	&& /drawRoundRect\(-hb,-hb,box,box,16,16\)/.test(fnText(qm, "hzqExtSlotArt").body),
	"extra slots reuse vanilla radius 8, keychip +5,+5, icon pad 4");

expect(/LoadImageFixtureFromUIData\(img,"FavoritesIconBuffer"\)/.test(qm) && /function hzqExtTintIcon/.test(qm)
	&& /this\.hzqCtW/.test(fnText(qm, "hzqApplyIconTint").body),
	"real LoadImageFixtureFromUIData icons and ac1eaf6 weapon accent tint are kept");

expect(/EXTENDED FAVORITES/.test(qm) && /0x161A20/.test(fnText(qm, "hzqExtFrameDraw").body)
	&& /hzqFilledBorder\(g,fx,fy,fw,fh,1,10,0x3A4450\)/.test(fnText(qm, "hzqExtFrameDraw").body)
	&& /drawRoundRect\(fx \+ 6,fy \+ 12,4,sh,4,4\)/.test(fnText(qm, "hzqExtFrameDraw").body)
	&& !/hzqFilledBorder\(g,fx,fy,fw,fh,2,10,this\.hzqAccent/.test(fnText(qm, "hzqExtFrameDraw").body),
	"panel: dark fill, 1 px gray filled border, left accent strip, no outer accent ring");

{
	const drw = fnText(qm, "hzqExtDraw").body;
	expect(/this\.hzqSet\(o\.p,"\+",18,this\.hzqDimCol\(\),"rg",0,false\)/.test(drw) && /o\.p\.alpha = 0\.28/.test(drw),
		"empty extras draw a faint centered plus (reused TextField, not a new clip)");
	expect(/hideE:Boolean = empty && !this\.hzqExtShowEmpty\(\) && !this\.hzqExtAssigning\(\)/.test(drw)
		&& /o\.s\.visible = !hideE/.test(drw),
		"HIDE leaves empty extras undrawn; assign mode still shows them");
	expect(/this\.hzqExtOccupied\(\)/.test(fnText(qm, "hzqExtFrameDraw").body)
		&& /hzqExtPad2\(occ\) \+ " \/ " \+ this\.hzqExtPad2\(extN\)/.test(fnText(qm, "hzqExtFrameDraw").body)
		&& /String\(occ\)/.test(fnText(qm, "hzqExtFrameDraw").body)
		&& /this\.hzqExtFrameDraw\(this\.hzqExtLastBox\)/.test(drw),
		"occupied counter NN / 12 is change-driven (frame key includes occ; redraw after assign/clear)");
}

expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout/.test(qm.slice(qm.indexOf("0.43.5 Extended Mode"))),
	"perf: extra window adds no enterFrame or timer");

{
	const h = Object.assign({}, consts, { hzqS: null });
	h.hzq37Lines = toJs(src, "hzq37Lines");
	h.hzq37Hdr = toJs(src, "hzq37Hdr");
	h.hzq37Alias = toJs(src, "hzq37Alias");
	h.hzq37KV = toJs(src, "hzq37KV");
	h.hzq37Ws = toJs(src, "hzq37Ws");
	h.hzq37Trim = toJs(src, "hzq37Trim");
	h.hzqHex = toJs(src, "hzqHex");
	h.hzqPct = toJs(src, "hzqPct");
	h.hzqParse = toJs(src, "hzqParse");
	const d = h.hzqParse("");
	expect(d.ExtEmptyShow === true && d.ExtPanelOpacity === 92 && d.ExtSlotScale === 1,
		"movie parse defaults: empty extras shown, panel 92, scale 1.0");
	const st = h.hzqParse("[Cards Extra]\nQuickMenuExtEmptySlots=0\nQuickMenuExtPanelOpacity=150\nQuickMenuExtSlotScale=0.2\n");
	expect(st.ExtEmptyShow === false && st.ExtPanelOpacity === 100 && st.ExtSlotScale === 0.7,
		"movie parse clamps hide / opacity 100 / scale 0.7");
	const hi = h.hzqParse("[Cards Extra]\nQuickMenuExtEmptySlots=1\nQuickMenuExtPanelOpacity=-4\nQuickMenuExtSlotScale=9\n");
	expect(hi.ExtEmptyShow === true && hi.ExtPanelOpacity === 0 && hi.ExtSlotScale === 1.4,
		"movie parse clamps show / opacity 0 / scale 1.4");
	h.hzqS = st;
	h.HZQ_BOX = 58;
	h.HZQ_EXT_GAP = 14;
	h.hzqExtSc = toJs(src, "hzqExtSc");
	h.hzqExtBoxN = toJs(src, "hzqExtBoxN");
	h.hzqExtPitchN = toJs(src, "hzqExtPitchN");
	h.hzqExtPanelA = toJs(src, "hzqExtPanelA");
	expect(h.hzqExtBoxN() === Math.round(58 * 0.7) && h.hzqExtPitchN() === h.hzqExtBoxN() + Math.max(8, Math.round(14 * 0.7)),
		"Slot Scale 0.7 shrinks extra box and pitch from vanilla 58 / 72");
	h.hzqS = { ExtSlotScale: 1, ExtPanelOpacity: 92 };
	expect(h.hzqExtBoxN() === 58 && h.hzqExtPitchN() === 72 && h.hzqExtPanelA() === 0.92,
		"Slot Scale 1.0 is vanilla 58 / 72; panel opacity 92 is 0.92 fill");
}

{
	const h = Object.assign({}, consts, { hzqS: { SlotCount: 24, Extended: true }, hzqExtData: {} });
	h.hzqExtOn = function () { return true; };
	h.hzqExtCount = toJs(src, "hzqExtCount");
	h.hzqExtOccupied = toJs(src, "hzqExtOccupied");
	h.hzqExtPad2 = toJs(src, "hzqExtPad2");
	expect(h.hzqExtOccupied() === 0 && h.hzqExtPad2(2) + " / " + h.hzqExtPad2(12) === "02 / 12",
		"empty extras: occupied 0, counter formats 02 / 12");
	h.hzqExtData["13"] = { name: "Grendel", empty: false };
	h.hzqExtData["18"] = { name: "Med Pack", empty: false };
	h.hzqExtData["14"] = { name: "", empty: true };
	expect(h.hzqExtOccupied() === 2, "occupied counter counts assigned extras only (change-driven on assign/clear)");
	h.hzqExtData["13"] = { name: "", empty: true };
	expect(h.hzqExtOccupied() === 1, "clearing a slot drops the occupied count");
}

{
	const h = {
		hzQmOn: true, hzQmExt: false, hzQmCount: 24, hzQmPerRow: 6, hzQmLayout: 0,
		hzQmEmpty: 1, hzQmPanelA: 92, hzQmSlotSc: 1,
		hzQmKeys: ["", "", "", "", "", "", "", "", "", "", "", ""],
		hzB: (o) => (o ? "1" : "0")
	};
	h.hzPctOr = toJs(hud, "hzPctOr");
	for (const n of ["hzQmIniVal", "hzQmSetCur", "hzQmSetLive", "hzQmIniLines", "hzQmClampEmpty", "hzQmClampPanelA", "hzQmClampScale", "hzQmKeyAt", "hzQmClampCount", "hzQmClampRow"]) h[n] = toJs(hud, n);
	expect(h.hzQmIniVal("quickmenuextemptyslots", "0") === true && h.hzQmEmpty === 0, "HUD reads QuickMenuExtEmptySlots=0 as hide");
	expect(h.hzQmIniVal("quickmenuextpanelopacity", "150") === true && h.hzQmPanelA === 100, "HUD clamps panel opacity to 100");
	expect(h.hzQmIniVal("quickmenuextslotscale", "0.2") === true && h.hzQmSlotSc === 0.7, "HUD clamps slot scale to 0.7");
	h.hzQmSetLive({ QuickMenuExtEmptySlots: 1, QuickMenuExtPanelOpacity: -8, QuickMenuExtSlotScale: 9 });
	expect(h.hzQmEmpty === 1 && h.hzQmPanelA === 0 && h.hzQmSlotSc === 1.4, "HUD live apply clamps empty/opacity/scale (no restart)");
	const o = {}; h.hzQmSetCur(o);
	expect(o.QuickMenuExtEmptySlots === 1 && o.QuickMenuExtPanelOpacity === 0 && o.QuickMenuExtSlotScale === 1.4, "current values include the three extra-window keys");
	const a = []; h.hzQmIniLines(a, { QuickMenuExtEmptySlots: 0, QuickMenuExtPanelOpacity: 50, QuickMenuExtSlotScale: 1 });
	expect(a.indexOf("QuickMenuExtEmptySlots=0") >= 0 && a.indexOf("QuickMenuExtPanelOpacity=50") >= 0 && a.indexOf("QuickMenuExtSlotScale=1") >= 0,
		"writer round-trips the three extra-window keys");
	expect(/QuickMenuExtEmptySlots=1/.test(ini) && /QuickMenuExtPanelOpacity=92/.test(ini) && /QuickMenuExtSlotScale=1/.test(ini),
		"default.ini ships Show / 92 / 1.0");
	expect(/"k":"QuickMenuExtEmptySlots","l":"EMPTY SLOTS"/.test(hud)
		&& /"k":"QuickMenuExtPanelOpacity","l":"PANEL OPACITY"/.test(hud)
		&& /"k":"QuickMenuExtSlotScale","l":"SLOT SCALE"/.test(hud),
		"F11 > CARDS > QUICK MENU has EMPTY SLOTS, PANEL OPACITY, SLOT SCALE");
}

{
	const nav = fnText(qm, "hzqExtNav").body;
	expect(/function hzqExtNavVis/.test(qm) && /function hzqExtNavFirst/.test(qm) && /function hzqExtNavStep/.test(qm)
		&& /hzqExtNavFirst/.test(nav) && /hzqExtNavStep/.test(nav) && /hzqExtNavVis/.test(nav),
		"hide-empty arrows use visitable helpers from hzqExtNav only");
	expect(!/hzqExtNavVis|hzqExtNavFirst|hzqExtNavStep/.test(fnText(qm, "hzqExtDraw").body),
		"draw does not scan visitable slots (no per-frame nav work)");
	expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout/.test(
		fnText(qm, "hzqExtNavVis").body + fnText(qm, "hzqExtNavFirst").body
		+ fnText(qm, "hzqExtNavStep").body + nav),
		"nav skip helpers add no enterFrame or timer");

	function occ(name) { return { name: name, empty: false }; }
	function navHost(opt) {
		const h = {
			hzqOn: true,
			hzqS: {
				Extended: true,
				SlotCount: 24,
				SlotsPerRow: opt.per != null ? opt.per : 6,
				ExtLayout: opt.bars ? 1 : 0,
				ExtEmptyShow: opt.showEmpty === true
			},
			hzqExtData: opt.data || {},
			AssignedItem: opt.assigned || null,
			SelectQuickslot_mc: opt.overlay || { visible: false },
			hzqExtSel: opt.sel != null ? opt.sel : 0,
			selectedIndex: opt.idx != null ? opt.idx : 11,
			picked: [],
			drew: 0
		};
		h.hzqExtOn = function () { return true; };
		h.hzqExtPick = function (slot) { this.picked.push(slot); this.hzqExtSel = slot; };
		h.hzqExtDraw = function () { this.drew++; };
		for (const n of ["hzqExtCount", "hzqExtPer", "hzqExtShowEmpty", "hzqExtAssigning",
			"hzqExtNavVis", "hzqExtNavFirst", "hzqExtNavStep", "hzqExtNav"]) {
			h[n] = toJs(src, n);
		}
		return h;
	}

	const hide16 = navHost({ data: { "16": occ("Grendel") } });
	expect(hide16.hzqExtNavFirst() === 16 && hide16.hzqExtNavVis(13) === false && hide16.hzqExtNavVis(16) === true,
		"Hide: first visitable extra is the first occupied slot, not hidden 13");
	expect(hide16.hzqExtNav(0, 1) === true && hide16.picked.join(",") === "16" && hide16.hzqExtSel === 16,
		"Hide: Down from the T lands on the first occupied extra");

	const hideNone = navHost({});
	expect(hideNone.hzqExtNavFirst() === 0 && hideNone.hzqExtNav(0, 1) === true
		&& hideNone.picked.length === 0 && hideNone.hzqExtSel === 0,
		"Hide: Down from the T stays on the T when no extra is occupied");

	const hideRow = navHost({ data: { "16": occ("Grendel"), "18": occ("Med Pack") }, sel: 16 });
	expect(hideRow.hzqExtNavStep(16, 1, 0) === 18 && hideRow.hzqExtNavStep(18, 1, 0) === 16
		&& hideRow.hzqExtNavStep(16, -1, 0) === 18,
		"Hide: Left/Right in a row skip hidden empties and wrap to the next occupied");
	expect(hideRow.hzqExtNav(1, 0) === true && hideRow.picked.join(",") === "18",
		"Hide: Right from 16 picks 18");

	const hideCol = navHost({ data: { "16": occ("Grendel"), "22": occ("Sidestar") }, sel: 16 });
	expect(hideCol.hzqExtNavStep(16, 0, 1) === 22 && hideCol.hzqExtNavStep(22, 0, -1) === 16,
		"Hide: Up/Down in a column skip hidden empties");
	expect(hideCol.hzqExtNav(0, 1) === true && hideCol.picked.join(",") === "22",
		"Hide: Down from 16 picks 22");

	const hideStay = navHost({ data: { "16": occ("Grendel") }, sel: 16 });
	expect(hideStay.hzqExtNavStep(16, 1, 0) === 16 && hideStay.hzqExtNavStep(16, 0, 1) === 0,
		"Hide: only occupied in row/column stays (Right wraps to self; Down has nowhere)");
	expect(hideStay.hzqExtNav(1, 0) === true && hideStay.picked.length === 0 && hideStay.hzqExtSel === 16,
		"Hide: Right on the only occupied extra does not move the ring");

	const hideUp = navHost({ data: { "22": occ("Sidestar") }, sel: 22 });
	expect(hideUp.hzqExtNavStep(22, 0, -1) === -1, "Hide: Up past hidden 16 leaves the extra grid");
	expect(hideUp.hzqExtNav(0, -1) === true && hideUp.hzqExtSel === 0 && hideUp.selectedIndex === 11 && hideUp.drew === 1,
		"Hide: Up from 22 with 16 hidden returns to the T");

	const show = navHost({ showEmpty: true });
	expect(show.hzqExtNavFirst() === 13 && show.hzqExtNavVis(13) === true,
		"Show: every extra is visitable, first is 13");
	expect(show.hzqExtNav(0, 1) === true && show.picked.join(",") === "13",
		"Show: Down from the T still lands on slot 13");

	const assign = navHost({ assigned: { sName: "Med Pack" } });
	expect(assign.hzqExtAssigning() === true && assign.hzqExtNavFirst() === 13 && assign.hzqExtNavVis(14) === true,
		"assign: empties stay visitable while AssignedItem is set");
	expect(assign.hzqExtNav(0, 1) === true && assign.picked.join(",") === "13",
		"assign: Down from the T still lands on slot 13");

	const overlay = navHost({ overlay: { visible: true } });
	expect(overlay.hzqExtAssigning() === true && overlay.hzqExtNavFirst() === 13,
		"assign overlay: visible SelectQuickslot_mc keeps empties visitable");

	const barsSkip = navHost({ bars: true, data: { "19": occ("Grendel") }, idx: 6 });
	expect(barsSkip.hzqExtNav(0, 1) === true && barsSkip.picked.join(",") === "19",
		"BARS Hide: Down from the last vanilla column skips hidden 13 onto occupied 19");
	const barsStay = navHost({ bars: true, data: { "15": occ("Med Pack") }, idx: 6 });
	expect(barsStay.hzqExtNav(0, 1) === true && barsStay.picked.length === 0 && barsStay.hzqExtSel === 0,
		"BARS Hide: Down stays when that column has no occupied extra");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log(passed + " ok, quickmenu_ext_window_test ok");
