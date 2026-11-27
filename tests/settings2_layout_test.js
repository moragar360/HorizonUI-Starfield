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

// Mockup cards_status.html / search_jump.html vs implemented constants
const mock = {
	winW: 1848, winH: 1020, side: 268, prev: 292, row: 58, head: 62, tabs: 46,
	footRow: 54, findW: 268, findH: 36, ddH: 34, pvcH: 188, divA: 0.08, boxA: 0.18,
	selA: 0.10, shA: 0.28, winEA: 0.28, titlePx: 13, helpPx: 12
};
expect(constN("HZ51_ROW") === mock.row, "row height mockup " + mock.row + " / implemented " + constN("HZ51_ROW"));
expect(constN("HZ51_SIDE_W") === mock.side, "sidebar width mockup " + mock.side + " / implemented " + constN("HZ51_SIDE_W"));
expect(constN("HZ51_PREV_W") === mock.prev, "preview width mockup " + mock.prev + " / implemented " + constN("HZ51_PREV_W"));
expect(constN("HZ51_HEAD") === mock.head && constN("HZ51_TABS") === mock.tabs, "header 62 + tabs 46 mockup / implemented " + constN("HZ51_HEAD") + "+" + constN("HZ51_TABS"));
expect(constN("HZ51_FOOT") === mock.footRow, "single hint row mockup " + mock.footRow + " / implemented " + constN("HZ51_FOOT"));
expect(constN("HZ51_FIND_W") === mock.findW && constN("HZ51_FIND_H") === mock.findH, "search box mockup 268x36 / implemented " + constN("HZ51_FIND_W") + "x" + constN("HZ51_FIND_H"));
expect(constN("HZ51_DD_H") === mock.ddH && constN("HZ51_PVC_H") === mock.pvcH, "dropdown 34 and preview card 188 mockup / implemented " + constN("HZ51_DD_H") + " / " + constN("HZ51_PVC_H"));
expect(constN("HZ51_DIV_A") === mock.divA && constN("HZ51_BOX_A") === mock.boxA && constN("HZ51_SEL_A") === mock.selA, "divider 0.08 / box 0.18 / sel 0.10 mockup alphas implemented");
expect(/HZ_SET_W:Number = 1848/.test(as) && /HZ_SET_H:Number = 1020/.test(as) && /HZ_SET_TOP:Number = 108/.test(as), "window 1848x1020, body top 108 (62+46)");
expect(/hz51Stroke/.test(fnText(as, "hz51DrawList").body) && /HZ51_DIV_A/.test(fnText(as, "hz51DrawList").body), "list rows use filled-rect box stroke and 8% dividers");
expect(!/lineStyle/.test(fnText(as, "hz51Stroke").body) && /drawRect\(x, y, w, 1\)/.test(fnText(as, "hz51Stroke").body), "hz51Stroke is four 1px filled rects, not lineStyle");
expect(/13,\"bd\"/.test(fnText(as, "hz51DrawList").body), "row title 13px bold (mockup .ln 13px/700)");
expect(/12,\"rg\"/.test(fnText(as, "hz51DrawList").body), "row help 12px (mockup .help 12px/500)");
expect(/11,\"bd\"/.test(fnText(as, "hz51DrawList").body) && /HZ51_SH_A/.test(fnText(as, "hz51DrawList").body), "section header 11px accent + 28% rule (mockup .sh)");

// 1. Window from visibleRect
expect(/vw - 72/.test(fnText(as, "hz51Fit").body) && /vh - 64/.test(fnText(as, "hz51Fit").body), "hz51Fit uses mockup 36px/32px margins (72/64)");
expect(/hz51Fit/.test(fnText(as, "hzSetPlace").body), "hzSetPlace sizes from visibleRect before centering");
expect(/HZ51_SIDE_W \+ 28/.test(fnText(as, "hz51ListBox").body), "list has 28px main padding so labels do not run into the sidebar");

// 2. Active-device hints (change-driven, no poll)
expect(/hz51Pad = this.hzVehPad == 1/.test(fnText(as, "hzToggleSettings").body), "open seeds the hint row from ControlMap (hzVehPad)");
expect(/hz51Pad = false/.test(fnText(as, "hzSettingsMouse").body), "mouse move >2px switches the hint row to keyboard (same path as hz35Kb)");
expect(/hz51NotePad/.test(fnText(as, "hz51Key").body) && /padx/.test(fnText(as, "hz51NotePad").body), "LB/RB and stick (padx/pady/tab) switch the hint row to controller");
expect(!/getTimer|ENTER_FRAME|setInterval/.test(fnText(as, "hz51NotePad").body + fnText(as, "hz51DrawFooter").body), "hint switching adds no polling");
expect(/if\(this\.hz51Pad\)/.test(fnText(as, "hz51DrawFooter").body), "footer draws only the active device row");

// 3. Header search: ch: and bind:, jump across tabs
expect(/bind:/.test(fnText(as, "hz51TypeChar").body) && /ch:/.test(fnText(as, "hz51TypeChar").body), "typed characters come from ch: and bind:");
expect(/hz51TypeChar/.test(fnText(as, "hz51Key").body), "find box consumes bind: letters instead of swallowing them");
expect(/catch\(eIdxP:Error\)/.test(fnText(as, "hz51IndexBuild").body), "search index builds each sidebar page in a try so one miss does not empty the index");
expect(/String\(row\.k\)/.test(fnText(as, "hz51IndexBuild").body), "search haystack includes the setting key");
const typeChar = toJs(as, "hz51TypeChar");
expect(typeChar("ch:v") === "v" && typeChar("bind:V") === "V" && typeChar("ok") === "", "ch:v and bind:V both yield a typed character");

const drop = toJs(as, "hz51DropRect");
const below = drop(800, 400, 148, 34, 220, 120, 1848, 1020, 54, 108);
expect(below.y === 438 && below.x === 728, "dropdown anchors 4px below a 34px control (mockup .ddmenu top:38px): y=" + below.y);
const flip = drop(800, 900, 148, 34, 220, 200, 1848, 1020, 54, 108);
expect(flip.y === 900 - 4 - 200, "dropdown flips above only when it would leave the window: y=" + flip.y);

// 4. Empty STATUS / every sidebar page
expect(/ShowVitals/.test(fnText(as, "hz51Cards").body) && /id == \"sta\"/.test(fnText(as, "hz51Cards").body), "CARDS > STATUS still builds Vitals/Jetpack/Afflictions/Hazard/Warnings");
expect(/_empty/.test(fnText(as, "hz51Rows").body) && /NO SETTINGS IN THIS SECTION/.test(fnText(as, "hz51Rows").body), "a sidebar page that returns no rows still draws a placeholder row");
const side = fnText(as, "hz51Side").body;
const pageIds = [];
side.replace(/\"id\":\"([a-z]+)\"/g, (_, id) => { pageIds.push(id); return ""; });
expect(pageIds.length === 31, "five tabs expose 31 sidebar pages (found " + pageIds.length + ")");
expect(/hz51Cards/.test(fnText(as, "hz51Rows").body) && /hz51Appear/.test(fnText(as, "hz51Rows").body) && /hz51Scan/.test(fnText(as, "hz51Rows").body) && /hz51Comms/.test(fnText(as, "hz51Rows").body) && /hz51System/.test(fnText(as, "hz51Rows").body), "every tab has a row builder");

// 5. Preview inside the panel
expect(!/hzSetPvDraw/.test(fnText(as, "hz51DrawRight").body), "Setting Details column does not call hzSetPvDraw");
expect(/hzSetPv\.visible = false/.test(fnText(as, "hz51Draw").body), "planet-card clone is hidden while F11 is open");
expect((fnText(as, "hz51DrawRight").body.match(/LIVE PREVIEW/g) || []).length === 1, "LIVE PREVIEW is drawn once");
expect(/HZ51_PVC_H/.test(fnText(as, "hz51DrawRight").body) && /SETTING DETAILS/.test(fnText(as, "hz51DrawRight").body), "188px preview card then Setting Details below it");

// 6. Module pills vertically centered on the row
expect(/HZ51_ROW \/ 2/.test(fnText(as, "hz51DrawList").body) && /r\.t == \"md\"/.test(fnText(as, "hz51DrawList").body), "INSTALLED / ENABLED badge is vertically centered on the 58px row");

// 7. Dropdowns drawn last, on top
expect(/hz51DrawDrop/.test(fnText(as, "hz51Draw").body) && fnText(as, "hz51Draw").body.indexOf("hz51DrawDrop") > fnText(as, "hz51Draw").body.indexOf("hz51DrawList"), "dropdown menu is drawn after the list so it sits on top");
expect(/hz51DropRect/.test(fnText(as, "hz51DrawDrop").body) && /hzSetDropBox/.test(fnText(as, "hz51DrawCtrl").body), "open menu uses the control rect, not the list top");

// 8. Filled-rect rows, Exo 2 / accent kept
expect(/hzSetTheme/.test(fnText(as, "hz51Draw").body), "shell still tints from the player's Accent and STYLE");
expect(/hzFontName/.test(as) && /Exo/.test(as), "Exo 2 stays the settings face");
expect(insert.indexOf("HZ51_ROW") >= 0 && draw.indexOf("hz51Stroke") >= 0, "layout source of truth is hz51_insert.as / hz51_draw.as");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
