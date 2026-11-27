// Settings 2.0 mockup-exact F11 shell (window, rows, search, dropdowns, hints).
// Run: node tests/settings2_layout_test.js
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
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => {
		const nm = p.split(":")[0].trim();
		const dv = p.indexOf("=") >= 0 ? p.slice(p.indexOf("=") + 1).trim() : null;
		return dv != null ? nm + " = " + dv : nm;
	});
	const b = f.body.replace(/var (\w+):[\w.*]+/g, "let $1").replace(/catch\((\w+):\w+\)/g, "catch($1)");
	return new Function(...params, b);
}
function constN(name) {
	const m = new RegExp("const " + name + ":Number = ([0-9.]+)").exec(as);
	return m ? Number(m[1]) : NaN;
}

// Compact shell: mockup colors/style, 10% over the old 1000x660 F11 clip so the HUD stays visible.
const mock = {
	winW: 1260, winH: 726, side: 248, prev: 196, row: 48, head: 52, tabs: 38,
	footRow: 46, findW: 176, findH: 30, ddH: 28, pvcH: 120, divA: 0.08, boxA: 0.18,
	selA: 0.10, shA: 0.28, winEA: 0.28, titlePx: 12, helpPx: 11
};
expect(constN("HZ51_ROW") === mock.row, "row height " + mock.row + " / implemented " + constN("HZ51_ROW"));
expect(constN("HZ51_SIDE_W") === mock.side, "sidebar width " + mock.side + " / implemented " + constN("HZ51_SIDE_W"));
expect(constN("HZ51_PREV_W") === mock.prev, "preview width " + mock.prev + " / implemented " + constN("HZ51_PREV_W"));
expect(constN("HZ51_HEAD") === mock.head && constN("HZ51_TABS") === mock.tabs, "header 52 + tabs 38 / implemented " + constN("HZ51_HEAD") + "+" + constN("HZ51_TABS"));
expect(constN("HZ51_FOOT") === mock.footRow, "single hint row " + mock.footRow + " / implemented " + constN("HZ51_FOOT"));
expect(constN("HZ51_FIND_W") === mock.findW && constN("HZ51_FIND_H") === mock.findH, "search box 176x30 / implemented " + constN("HZ51_FIND_W") + "x" + constN("HZ51_FIND_H"));
expect(constN("HZ51_DD_H") === mock.ddH && constN("HZ51_PVC_H") === mock.pvcH, "dropdown 28 and preview card 120 / implemented " + constN("HZ51_DD_H") + " / " + constN("HZ51_PVC_H"));
expect(constN("HZ51_DIV_A") === mock.divA && constN("HZ51_BOX_A") === mock.boxA && constN("HZ51_SEL_A") === mock.selA, "divider 0.08 / box 0.18 / sel 0.10 mockup alphas kept");
expect(/HZ_SET_W:Number = 1260/.test(as) && /HZ_SET_H:Number = 726/.test(as) && /HZ_SET_TOP:Number = 90/.test(as), "window 1260x726, body top 90 (52+38)");
expect(/hz51FillGroup/.test(fnText(as, "hz51DrawList").body) && /HZ51_DIV_A/.test(fnText(as, "hz51DrawList").body), "list sections use a rounded group panel and 8% dividers");
expect(!/lineStyle/.test(fnText(as, "hz51Stroke").body) && /drawRect\(x, y, w, 1\)/.test(fnText(as, "hz51Stroke").body) && !/drawRoundRect/.test(fnText(as, "hz51Stroke").body), "hz51Stroke is four 1px bars inside the box; never lineStyle or even-odd roundRect");
expect(/HZ51_TITLE_PX/.test(fnText(as, "hz51DrawList").body), "row title 12px");
expect(/HZ51_HELP_PX/.test(fnText(as, "hz51DrawList").body), "row help 11px");
expect(/HZ51_SH_PX/.test(fnText(as, "hz51DrawList").body) && /HZ51_SH_A/.test(fnText(as, "hz51DrawList").body), "section header 10px accent + 28% rule");

// 1. Window from visibleRect — cap at 1260x726 so HUD cards stay visible
expect(/vw - 80/.test(fnText(as, "hz51Fit").body) && /vh - 80/.test(fnText(as, "hz51Fit").body), "hz51Fit leaves an 80px stage margin so edge HUD cards stay in view");
expect(Math.round(Math.max(1000, Math.min(1260, 1920 - 80))) === 1260 && Math.round(Math.max(560, Math.min(726, 1080 - 80))) === 726, "1080p visibleRect yields 1260x726");
expect(/hz51Fit/.test(fnText(as, "hzSetPlace").body), "hzSetPlace sizes from visibleRect before centering");
expect(!/HorizonSettings_mc\.scaleX/.test(fnText(as, "hzSetPlace").body) && !/HorizonSettings_mc\.scaleY/.test(fnText(as, "hzSetPlace").body), "hzSetPlace does not scale HorizonSettings_mc (old F11 in hudmenu_lrg also left the window at 1.0; HZ_SCALE 1.07 is cards only)");
expect(/hudmenu_lrg 1\.07 scales HUD cards only/.test(as), "comment records that _lrg HZ_SCALE must not be applied to the F11 clip");
expect(/HZ51_SIDE_W \+ 20/.test(fnText(as, "hz51ListBox").body), "list has 20px main padding so labels do not run into the sidebar");
expect(constN("HZ51_SEC") === 36 && /HZ_SET_TOP \+ 64/.test(fnText(as, "hz51ListBox").body),
	"page title has 64px before the list; section headers keep a 36px gap before the first row");
expect(/var shY:Number = y \+ 10/.test(fnText(as, "hz51DrawList").body) && !/firstSec \? 2 : 10/.test(fnText(as, "hz51DrawList").body),
	"every section title, including the first on a page, uses the same 10px gap before the card");
expect(/h\":HZ51_DROP_ITEM/.test(fnText(as, "hz51DrawDrop").body),
	"dropdown option hit rects use the full 24px row (no 2px gap that misses the click)");
expect(/function hz51HitAt/.test(as) && /dropout/.test(fnText(as, "hz51HitAt").body),
	"open dropdowns own hit-testing so a click cannot fall through to the row below");

// 2. Active-device hints (change-driven, no poll)
expect(/hz51Pad = this.hzVehPad == 1/.test(fnText(as, "hzToggleSettings").body), "open seeds the hint row from ControlMap (hzVehPad)");
expect(/hz51Pad = false/.test(fnText(as, "hzSettingsMouse").body), "mouse move >2px switches the hint row to keyboard (same path as hz35Kb)");
expect(/hz51NotePad/.test(fnText(as, "hz51Key").body) && /hzpad/.test(fnText(as, "hz51NotePad").body) && /padx/.test(fnText(as, "hz51NotePad").body), "any gamepad queue (hzpad plus D-pad/A/B/LB/RB/stick) switches the hint row to controller");
expect(/emplace_back\("hzpad"\)/.test(fs.readFileSync(path.join(__dirname, "..", "src", "main.cpp"), "utf8")) && /if\(code == "hzpad"\) \{ return true; \}/.test(fnText(as, "hz51Key").body), "MsglogPadPoll prefixes hzpad; hz51Key sets the hint row and swallows the marker");
expect(!/getTimer|ENTER_FRAME|setInterval/.test(fnText(as, "hz51NotePad").body + fnText(as, "hz51DrawFooter").body), "hint switching adds no polling");
expect(/if\(this\.hz51Pad\)/.test(fnText(as, "hz51DrawFooter").body), "footer draws only the active device row");

// 3. Header search: append only ch:; swallow bind: (QueueKey emits both for one key)
expect(/ch:/.test(fnText(as, "hz51TypeChar").body) && !/bind:/.test(fnText(as, "hz51TypeChar").body), "typed characters come from ch: only");
expect(/indexOf\("bind:"\) == 0/.test(fnText(as, "hz51Key").body) && /hzSetFindOn/.test(fnText(as, "hz51Key").body), "find and hex swallow bind: without appending");
expect(/catch\(eIdxP:Error\)/.test(fnText(as, "hz51IndexBuild").body), "search index builds each sidebar page in a try so one miss does not empty the index");
expect(/String\(row\.k\)/.test(fnText(as, "hz51IndexBuild").body), "search haystack includes the setting key");
const typeChar = toJs(as, "hz51TypeChar");
expect(typeChar("ch:v") === "v" && typeChar("bind:V") === "" && typeChar("ok") === "", "ch:v yields v; bind:V is not a typed character");
const drawBody = fnText(as, "hz51Draw").body;
expect(/drawRoundRect\(0,12,W,H/.test(drawBody) && !/while\(i < 5\)/.test(drawBody), "window shadow is one 12px-offset fill (mockup 0 12px 48px), not a 5-layer blur");
expect(/HZ51_WIN_R/.test(fnText(as, "hz51Draw").body) && /HZ51_BOX_R/.test(fnText(as, "hz51FillGroup").body), "window and box still use the mockup corner radii on their fills");

const drop = new Function("ctrlX", "ctrlY", "ctrlW", "ctrlH", "menuW", "menuH", "winW", "winH", "foot", "top",
	"const HZ51_DROP_ITEM = 24; const int = (n) => n | 0;\n" + fnText(as, "hz51DropRect").body.replace(/var (\w+):[\w.*]+/g, "let $1"));
const below = drop(800, 400, 148, 28, 148, 120, 1260, 726, 46, 90);
expect(below.x === 800 && below.y === 432 && below.w === 148, "dropdown sits under its box (same x/w, 4px gap): x=" + below.x + " y=" + below.y);
const flip = drop(800, 620, 148, 28, 148, 200, 1260, 726, 46, 90);
expect(flip.y + flip.h <= 620 - 4, "dropdown flips above when it would leave the window: y=" + flip.y + " h=" + flip.h);

// 4. Empty STATUS / every sidebar page
expect(/ShowVitals/.test(fnText(as, "hz51Cards").body) && /id == \"sta\"/.test(fnText(as, "hz51Cards").body), "CARDS > STATUS still builds Vitals/Jetpack/Afflictions/Hazard/Warnings");
expect(/_empty/.test(fnText(as, "hz51Rows").body) && /NO SETTINGS IN THIS SECTION/.test(fnText(as, "hz51Rows").body), "a sidebar page that returns no rows still draws a placeholder row");
const side = fnText(as, "hz51Side").body;
const pageIds = [];
side.replace(/\"id\":\"([a-z]+)\"/g, (_, id) => { pageIds.push(id); return ""; });
expect(pageIds.length === 36, "five tabs expose 36 sidebar pages including Language (found " + pageIds.length + ")");
expect(/hz51Cards/.test(fnText(as, "hz51Rows").body) && /hz51Appear/.test(fnText(as, "hz51Rows").body) && /hz51Scan/.test(fnText(as, "hz51Rows").body) && /hz51Comms/.test(fnText(as, "hz51Rows").body) && /hz51System/.test(fnText(as, "hz51Rows").body), "every tab has a row builder");

// 5. Preview inside the panel
expect(!/hzSetPvDraw/.test(fnText(as, "hz51DrawRight").body), "Setting Details column does not call hzSetPvDraw");
expect(/hzSetPv\.visible = false/.test(fnText(as, "hz51Draw").body), "planet-card clone is hidden while F11 is open");
expect((fnText(as, "hz51DrawRight").body.match(/LIVE PREVIEW/g) || []).length === 1, "LIVE PREVIEW is drawn once");
expect(/HZ51_PVC_H/.test(fnText(as, "hz51DrawRight").body) && /SETTING DETAILS/.test(fnText(as, "hz51DrawRight").body), "preview card then Setting Details below it");

// 6. Module pills vertically centered on the row
expect(/HZ51_ROW \/ 2/.test(fnText(as, "hz51DrawList").body) && /r\.t == \"md\"/.test(fnText(as, "hz51DrawList").body), "INSTALLED / ENABLED badge is vertically centered on the row");

// 7. Dropdowns drawn last, on top
expect(/hz51DrawDrop/.test(fnText(as, "hz51Draw").body) && fnText(as, "hz51Draw").body.indexOf("hz51DrawDrop") > fnText(as, "hz51Draw").body.indexOf("hz51DrawList"), "dropdown menu is drawn after the list so it sits on top");
expect(/hz51DropRect/.test(fnText(as, "hz51DrawDrop").body) && /hzSetDropBox/.test(fnText(as, "hz51DrawCtrl").body), "open menu uses the control rect, not the list top");

// 8. Filled-rect rows, Exo 2 / accent kept
expect(/hzSetTheme/.test(fnText(as, "hz51Draw").body), "shell still tints from the player's Accent and STYLE");
expect(/hzFontName/.test(as) && /Exo/.test(as), "Exo 2 stays the settings face");
expect(insert.indexOf("HZ51_ROW") >= 0 && draw.indexOf("hz51Stroke") >= 0, "layout source of truth is hz51_insert.as / hz51_draw.as");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
