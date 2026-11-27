// Settings 2.0 in-game fail pass: header slots, search close, Status freeze,
// extended key grid, scanner banner, (i) spacing, control alignment, LB/RB.
// Run: node tests/settings2_ingame_fix_test.js
// Author: Moragar. Last modified: 2026-11-26.
"use strict";
const fs = require("fs");
const path = require("path");
const as = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const insert = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const draw = fs.readFileSync(path.join(__dirname, "..", "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src);
	if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1;
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function asJs(body) {
	return body.replace(/var (\w+):[\w.*]+/g, "let $1").replace(/catch\((\w+):\w+\)/g, "catch($1)");
}
function constN(name) {
	const m = new RegExp("const " + name + ":Number = ([0-9.]+)").exec(as);
	return m ? Number(m[1]) : NaN;
}

const slotsBody = "const HZ51_HEAD = 52; const HZ51_FIND_H = 30; const HZ51_FIND_W = 176;\n" + asJs(fnText(as, "hz51HeadSlots").body);
const slotsFn = new Function(slotsBody);
function slotsAt(tab, W) {
	return slotsFn.call({ HZ_SET_W: W, hzSetTab: tab });
}
function overlap(a, b) {
	return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}

// 1. Header: compact, search, Arrange are non-overlapping slots; Arrange x is the midpoint
{
	const s = slotsAt(0, 1260);
	const compact = { x: s.cx, y: s.fy, w: s.cw, h: s.h };
	const find = { x: s.fx, y: s.fy, w: s.findW, h: s.h };
	const arr = { x: s.ax, y: s.fy, w: s.arrW, h: s.h };
	expect(s.cw >= 260 && s.findW === 176 && s.arrW === 132, "header slots: compact >=260, search 176, Arrange 132");
	expect(!overlap(compact, find) && !overlap(find, arr), "header compact / search / Arrange do not overlap at 1260");
	expect(compact.x >= s.titleR, "compact starts after the title cluster");
	expect(/ax \+ aw \/ 2/.test(fnText(as, "hz51DrawCompact").body), "Arrange label is centered on the button, not on its left edge");
	expect(!/hz51T\(b,alab,ax,ay/.test(fnText(as, "hz51DrawCompact").body), "Arrange no longer passes the left edge as a center x");
}

// 2. Search close: Esc/B/RMB (cancel), X hit, leftover query after GotoHit
{
	const key = fnText(as, "hz51Key").body;
	const box = fnText(as, "hz51DrawSearchBox").body;
	const mouse = fnText(as, "hzSettingsMouse").body;
	expect(/function hz51FindClose/.test(as) && /function hz51FindOpen/.test(as), "search close helpers exist");
	expect(/code == "cancel" && this\.hz51FindOpen/.test(key) && /hz51FindClose/.test(key), "Esc / B / RMB (cancel) close search while it is open, including leftover query text");
	expect(/id\":\"findx\"/.test(box) && /id == \"findx\"/.test(mouse) && /hz51FindClose/.test(mouse), "an X in the search box hits findx and closes results");
	expect(/hz51FindClose/.test(fnText(as, "hz51GotoHit").body), "picking a search hit also closes the results dropdown");
	expect(/hzSetFind = ""/.test(fnText(as, "hz51FindClose").body) && /hzSetFindOn = false/.test(fnText(as, "hz51FindClose").body), "close clears the query and the dropdown");
}

// 4. CARDS > STATUS: builder cannot blank the pane; draw cannot freeze F11
{
	const cards = fnText(as, "hz51Cards").body;
	const rows = fnText(as, "hz51Rows").body;
	const list = fnText(as, "hz51DrawList").body;
	const ctrl = fnText(as, "hz51DrawCtrl").body;
	expect(/id == \"sta\"/.test(cards) && /ShowVitals/.test(cards) && /ShowJetpack/.test(cards) && /ShowAfflictions/.test(cards) && /HazardStatus/.test(cards) && /EdgePulse/.test(cards), "STATUS still builds Vitals / Jetpack / Afflictions / Hazard / Warnings");
	expect(/\"k\":\"AfflictionLayout\"/.test(cards) && /\"ids\":\[0,1,2\]/.test(cards), "AfflictionLayout carries ids so the dropdown cannot read .length on null");
	expect(/catch\(eRows:Error\)/.test(rows), "a throw in STATUS (or any sidebar builder) falls through to the placeholder row instead of aborting F11");
	expect(/catch\(eList:Error\)/.test(fnText(as, "hz51Draw").body) && /catch\(eCtrl:Error\)/.test(list), "list draw and each control are try/caught so one bad row cannot leave an empty frozen pane");
	expect(/dropOpts != null && dropOpts.length > 0/.test(ctrl), "dropdowns do not read opts.length when opts is null (the STATUS freeze)");
}

// 5. Extended slot key grid: tiles contain SLOT n / Empty / chip; help does not cover CLEAR ALL
{
	const grid = fnText(as, "hz51DrawQmGrid").body;
	expect(/Click a chip to bind/.test(grid) && /btnX - x0 - 20/.test(grid), "grid hint is one line to the left of CLEAR ALL KEYS");
	expect(!/Click a key chip to bind\. Esc cancels\. Backspace/.test(grid), "the long _qmkeys help is not painted on the grid (Setting Details holds it, so the tooltip is not stacked)");
	expect(/tw < 72/.test(grid) && /HZ51_QM_TH/.test(grid), "tiles have a 72px min width and a taller chip row so Home/End/UNBOUND stay inside the card");
	expect(/id\":\"qmk\" \+ n/.test(grid) && /x\":xx/.test(grid) && /h\":th/.test(grid), "the whole tile is the hit target, not a chip that sits under the next card");
	expect(!/hz35Tip/.test(grid) && !/hz35InfoIcon/.test(grid), "the grid does not draw a second info tooltip over the tiles");
}

// 6. SCANNER > OVERVIEW banner stays in the content column
{
	const list = fnText(as, "hz51DrawList").body;
	expect(/hz51ModBanner/.test(list) && !/hz30ModBanner/.test(list), "Settings 2.0 draws hz51ModBanner, not the old F11 banner at x0=22");
	expect(/x0,boxW/.test(fnText(as, "hz51ModBanner").body) || /x0,y0,w,h/.test(fnText(as, "hz51ModBanner").body), "module banner uses the list-column x and width");
	expect(!/x0:Number = 22/.test(fnText(as, "hz51ModBanner").body), "banner does not hard-code the old F11 left edge");
}

// 8. Toggles, dropdowns, and buttons share right edge R; ON/OFF; 22px buttons
{
	const sw = fnText(as, "hz51Switch").body;
	const ctrl = fnText(as, "hz51DrawCtrl").body;
	expect(constN("HZ51_SW_W") === 42 && constN("HZ51_SW_H") === 22 && constN("HZ51_CTRL_W") === 148, "toggle 42x22, dropdown min 148");
	expect(/R - sw/.test(sw) && /ON" : "OFF"/.test(sw), "switch track ends at R; ON/OFF sits to the left");
	expect(/Math\.max\(HZ51_CTRL_W/.test(ctrl) && /R - cw/.test(ctrl), "dropdowns grow left from the same right edge R as the switch");
	expect(/function hz51Btn/.test(as) && /HZ51_BTN_H/.test(fnText(as, "hz51Btn").body) && constN("HZ51_BTN_H") === 22, "OPEN / RESET / SHOW use a 22px button on 48px rows");
	expect(/hz51Btn\(b,g,R,cy/.test(ctrl), "row action buttons call hz51Btn, not the 28px footer pill");
}

// 9. LB/RB only when the controller is the active device
{
	const tabs = fnText(as, "hz51DrawTabs").body;
	expect(/if\(this\.hz51Pad\) \{ this\.hzSetKey\(b,g,16,ty \+ 2,"LB"/.test(tabs), "LB is drawn only when hz51Pad is set");
	expect(/if\(this\.hz51Pad\) \{ this\.hzSetKey\(b,g,tx \+ 4,ty \+ 2,"RB"/.test(tabs), "RB is drawn only when hz51Pad is set");
	expect(/hz51Pad \? 48 : 16/.test(tabs), "keyboard/mouse tabs start at 16px, not in a reserved LB gutter");
}

expect(constN("HZ51_INFO_R") === 6 && /\+ 14/.test(fnText(as, "hz51DrawList").body) && /hz51InfoIcon/.test(fnText(as, "hz51DrawList").body),
	"(i) is a 12px disc with 14px after the label");
expect(/HZ51_WIN_W/.test(fnText(as, "hz51Fit").body) && constN("HZ51_WIN_W") === 1260 && /HZ_SET_H:Number = 726/.test(as),
	"final window cap is 1260 x 726");
expect(insert.indexOf("HZ51_WIN_W") >= 0 && draw.indexOf("hz51FindClose") >= 0, "source of truth is still hz51_insert.as / hz51_draw.as");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
