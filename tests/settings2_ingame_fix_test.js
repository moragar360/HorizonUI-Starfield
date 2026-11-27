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
expect(/hz51Disk/.test(fnText(as, "hz51InfoIcon").body) && /hz34Ring/.test(fnText(as, "hz51InfoIcon").body) && !/hz51Stroke/.test(fnText(as, "hz51InfoIcon").body),
	"(i) is a 16-gon disc plus hz34Ring, not hz51Stroke's square bars");
expect(/hz51T\(b,"i"/.test(fnText(as, "hz51InfoIcon").body) && /"center"/.test(fnText(as, "hz51InfoIcon").body),
	"(i) letter is a centered TextField, not a subpixel rect");
expect(/Math\.PI \* 2/.test(fnText(as, "hz51Disk").body) && /n:int = 16/.test(fnText(as, "hz51Disk").body),
	"disc uses 16 lineTo segments so 1080p and 1440p stay round");

expect(/function hz51HitAt/.test(as) && /id == "dropout"/.test(fnText(as, "hzSettingsMouse").body),
	"open dropdowns own the click; a miss closes the list instead of hitting the row below");
expect(/indexOf\("dopt"\) == 0/.test(fnText(as, "hz51HitAt").body) && /hzSetDropMenu/.test(fnText(as, "hz51HitAt").body),
	"dopt hits win over SIZE sliders; the menu rect swallows padding clicks");
expect(/h\":HZ51_DROP_ITEM\}/.test(fnText(as, "hz51DrawDrop").body) || /h\":HZ51_DROP_ITEM\)/.test(fnText(as, "hz51DrawDrop").body) || /h\":HZ51_DROP_ITEM/.test(fnText(as, "hz51DrawDrop").body),
	"option hit rects use the full 24px row so scroll and upward lists have no gap");
{
	const hitFn = new Function("mx", "my", fnText(as, "hz51HitAt").body.replace(/var (\w+):[\w.*]+/g, "let $1").replace(/Number\(/g, "(").replace(/String\(/g, "String("));
	const bar = { id: "bar3", x: 700, y: 200, w: 160, h: 48 };
	const row = { id: "row4", x: 268, y: 200, w: 760, h: 48 };
	const dopt = { id: "dopt2", x: 700, y: 210, w: 148, h: 24 };
	const dropHost = { hzSetDrop: 1, hzSetHits: [row, bar, dopt], hzSetDropMenu: { x: 700, y: 180, w: 148, h: 120 } };
	const picked = hitFn.call(dropHost, 740, 220);
	expect(picked && picked.id === "dopt2", "a click on option 2 hits dopt even when a SIZE bar sits under it: " + (picked && picked.id));
	const miss = hitFn.call(dropHost, 100, 400);
	expect(miss && miss.id === "dropout", "a click outside an open menu is dropout, not the sidebar or a row");
	const closed = hitFn.call({ hzSetDrop: -1, hzSetHits: [row, bar], hzSetDropMenu: null }, 740, 220);
	expect(closed && closed.id === "bar3", "with the menu closed, reverse walk still prefers the slider over its row");
}

expect(constN("HZ51_SEC") === 36 && /HZ_SET_TOP \+ 64/.test(fnText(as, "hz51ListBox").body),
	"page title has 64px before the list; section headers keep a 36px gap before the first row");
expect(/firstSec \? 2 : 10/.test(fnText(as, "hz51DrawList").body),
	"section titles add extra space before the first setting row on every page");

expect(/function hz51AddCard/.test(as) && /function hz51Fallback/.test(as),
	"STATUS / COMBAT / INTERACTION append per card and fall back to the old catalog if a builder throws");
expect(/COLUMN","ROW","ICONS ONLY/.test(fnText(as, "hz51Cards").body) && /VANILLA","HORIZON DOT/.test(fnText(as, "hz51Cards").body),
	"AfflictionLayout and CrosshairStyle use inline option lists so a missing name table cannot empty the page");

expect(/hz51FbLog\("eRows"/.test(fnText(as, "hz51Rows").body) && /hz51FbLog\("eFb"/.test(fnText(as, "hz51Rows").body),
	"eRows and eFb log once through hz51FbLog (page id + error)");
expect(/hz51FbLog\("eAdd"/.test(fnText(as, "hz51AddCard").body),
	"eAdd logs the section id and error");
expect(/hz51FbLog\("ePick"/.test(fnText(as, "hz51Fallback").body),
	"ePick logs the page id and error");
expect(/hz51FbLog\("eSc"/.test(fnText(as, "hz51Cards").body) && /hz51FbLog\("eSc"/.test(fnText(as, "hz51Fallback").body),
	"eSc logs from the combat builder and from the fallback Scope append");
expect(/if\(this\.hzWlOn\) \{ this\.hzWlPush\(line\); \}/.test(fnText(as, "hz51FbLog").body) && /page=/.test(fnText(as, "hz51FbLog").body) && /err=/.test(fnText(as, "hz51FbLog").body),
	"the fallback log line goes to HorizonUI.log via hzWlPush (watchlog gate) with page and error");
expect(/hz51FbSeen\[key\] === true/.test(fnText(as, "hz51FbLog").body) && /hz51FbSeen = null/.test(fnText(as, "hzToggleSettings").body),
	"each catch logs once per F11 open, not per draw; open clears the seen map");
expect(/SETTINGS FALLBACK/.test(fnText(as, "hzDbgShow").body) && /hz51FbDbg/.test(fnText(as, "hzDbgShow").body) && /hzDebug/.test(fnText(as, "hz51FbLog").body),
	"Debug Overlay shows the fallback line when diagnostics are on");
expect(/hz51RuleRow\("VitalsRule"/.test(fnText(as, "hz51Fallback").body) && /hz51RuleRow\("JetpackRule"/.test(fnText(as, "hz51Fallback").body) && /hz51RuleRow\("AfflictionsRule"/.test(fnText(as, "hz51Fallback").body),
	"fallback STATUS keeps SHOW WHEN (VitalsRule, JetpackRule, AfflictionsRule)");
{
	const logBody = asJs(fnText(as, "hz51FbLog").body);
	const logFn = new Function("tag", "page", "err", logBody);
	const host = { hz51FbSeen: null, hz51FbDbg: "", hzDebug: true, hzWlOn: true, dbgN: 0, pushed: [], hzWlPush(s) { this.pushed.push(s); }, hzDbgShow() { this.dbgN++; } };
	logFn.call(host, "eRows", "sta", { message: "null opts" });
	logFn.call(host, "eRows", "sta", { message: "null opts" });
	logFn.call(host, "ePick", "sta", { message: "catalog" });
	expect(host.pushed.length === 2 && host.pushed[0].indexOf("eRows") >= 0 && host.pushed[0].indexOf("page=sta") >= 0 && host.pushed[0].indexOf("null opts") >= 0,
		"first catch logs page and message: " + host.pushed[0]);
	expect(host.dbgN === 2 && host.hz51FbDbg.indexOf("eRows") >= 0 && host.hz51FbDbg.indexOf("ePick") >= 0,
		"Debug Overlay is refreshed once per distinct catch, not on the repeat");
	const fbBody = fnText(as, "hz51Fallback").body.replace(/var (\w+):[\w.*]+/g, "let $1").replace(/catch\((\w+):\w+\)/g, "catch($1)").replace(/ as Array/g, "").replace(/\bint\(/g, "(");
	const fbFn = new Function("tab", "id", "const HZ_RULE_NAMES = ['ALWAYS','COMBAT ONLY','HIDE IN SHIP','WEAPON DRAWN ONLY','IN USE / NOT FULL','WHEN NOT FULL (HP/O2)','ONLY WHEN AFFLICTED','ON XP / LEVEL / CREDITS','WHEN OVERWEIGHT','XP / LEVEL OR OVERWEIGHT'];\n" + fbBody);
	const fbHost = {
		pushed: [],
		hz51FbLog(tag, page, err) { this.pushed.push(tag + ":" + page); },
		hz34CardRows() { throw new Error("catalog"); },
		hz51Pick() { return []; },
		hz51ByKey(rows) { const m = {}; for (const r of rows) if (r && r.k) m[r.k] = r; return m; },
		hz51RuleRow(key, ids) { return { k: key, l: "SHOW WHEN", t: "q", ids: ids || [], opts: ["ALWAYS"] }; },
		hz42ScRows() { }
	};
	const staFb = fbFn.call(fbHost, 0, "sta") || [];
	const ks = staFb.map((r) => String(r.k));
	expect(ks.indexOf("VitalsRule") >= 0 && ks.indexOf("JetpackRule") >= 0 && ks.indexOf("AfflictionsRule") >= 0,
		"fallback STATUS rows include the three SHOW WHEN rules when the catalog throws");
	expect(fbHost.pushed.indexOf("ePick:sta") >= 0, "catalog throw logs ePick for STATUS");
}
expect(/HZ51_WIN_W/.test(fnText(as, "hz51Fit").body) && constN("HZ51_WIN_W") === 1260 && /HZ_SET_H:Number = 726/.test(as),
	"final window cap is 1260 x 726");
expect(insert.indexOf("HZ51_WIN_W") >= 0 && draw.indexOf("hz51FindClose") >= 0, "source of truth is still hz51_insert.as / hz51_draw.as");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
