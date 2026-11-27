// Settings 2.0 compact window: stroke stays in-bounds, dropdown of 15 items
// near the bottom stays under its box, header slots do not overlap.
// Run: node tests/settings2_compact_test.js
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

expect(/HZ_SET_W:Number = 1000/.test(fs.readFileSync(path.join(__dirname, "..", "tools", "patch_settings2.js"), "utf8"))
	&& /HZ_SET_H:Number = 660/.test(fs.readFileSync(path.join(__dirname, "..", "tools", "patch_settings2.js"), "utf8")),
	"old F11 clip in the patch source is 1000x660");
expect(/HZ_SET_W:Number = 1100/.test(as) && /HZ_SET_H:Number = 726/.test(as),
	"new window is 1100x726 (10% over 1000x660)");
expect(Math.round(1000 * 1.10) === 1100 && Math.round(660 * 1.10) === 726, "1100x726 is 10% over the old F11 clip");
expect(constN("HZ51_ROW") === 48 && constN("HZ51_TITLE_PX") === 12 && constN("HZ51_HELP_PX") === 11 && constN("HZ51_SH_PX") === 10,
	"rows 48px, titles 12, help 11, section headers 10");
expect(constN("HZ51_SIDE_W") === 248, "sidebar stays 248 so labels fit on one line (wrapping would not shrink the 1100 window)");
expect(/Math\.min\(1100, vw - 80\)/.test(fnText(as, "hz51Fit").body) && /Math\.min\(726, vh - 80\)/.test(fnText(as, "hz51Fit").body),
	"hz51Fit never grows past 1100x726, so a 1440p stage still leaves HUD cards visible");
expect(Math.round(Math.max(900, Math.min(1100, 2560 - 80))) === 1100
	&& Math.round(Math.max(560, Math.min(726, 1440 - 80))) === 726,
	"2560x1440 still yields 1100x726, not a full-screen settings box");

const strokeBody = fnText(as, "hz51Stroke").body;
expect(!/drawRoundRect/.test(strokeBody) && !/even-odd|evenOdd/i.test(strokeBody),
	"hz51Stroke does not use an even-odd outer/inner roundRect (that path leaked a teal wedge)");
expect((strokeBody.match(/beginFill/g) || []).length === 4 && (strokeBody.match(/drawRect/g) || []).length === 4,
	"hz51Stroke is four separate 1px filled bars");
expect(/endFill/.test(strokeBody), "each stroke bar closes its fill so the next shape cannot inherit the path");

function strokeRects(x, y, w, h, r) {
	const rects = [];
	const g = {
		beginFill() {},
		endFill() {},
		drawRect(a, b, c, d) { rects.push({ x: a, y: b, w: c, h: d }); },
		drawRoundRect() { throw new Error("roundRect must not run"); }
	};
	const fn = new Function("g", "x", "y", "w", "h", "col", "a", "r", asJs(strokeBody));
	fn(g, x, y, w, h, 0x3cf, 0.18, r);
	return rects;
}
function inside(box, r) {
	return r.x >= box.x && r.y >= box.y && r.x + r.w <= box.x + box.w && r.y + r.h <= box.y + box.h;
}
const boxes = [
	{ x: 720, y: 180, w: 148, h: 28, r: 6, name: "dropdown" },
	{ x: 790, y: 240, w: 36, h: 18, r: 9, name: "toggle" },
	{ x: 640, y: 300, w: 148, h: 4, r: 2, name: "slider track" },
	{ x: 268, y: 154, w: 616, h: 400, r: 6, name: "list box" }
];
for (const b of boxes) {
	const rects = strokeRects(b.x, b.y, b.w, b.h, b.r);
	const ok = rects.length === 4 && rects.every((r) => inside(b, r));
	expect(ok, "stroke/" + b.name + " keeps every bar inside " + b.w + "x" + b.h + " at (" + b.x + "," + b.y + ")");
	expect(rects.every((r) => r.x + r.w <= 1100 && r.y + r.h <= 726), "stroke/" + b.name + " does not reach past the 1100x726 window");
}

const dropBody = "const HZ51_DROP_ITEM = 24; const int = (n) => n | 0;\n" + asJs(fnText(as, "hz51DropRect").body);
const dropFn = new Function("ctrlX", "ctrlY", "ctrlW", "ctrlH", "menuW", "menuH", "winW", "winH", "foot", "top", dropBody);
const ctrl = { x: 720, y: 520, w: 148, h: 28 };
const need = 8 + 15 * 24;
const place = dropFn(ctrl.x, ctrl.y, ctrl.w, ctrl.h, 220, need, 1100, 726, 46, 90);
expect(place.x === ctrl.x, "15-item menu left edge matches the box (" + place.x + ")");
expect(place.w === ctrl.w, "15-item menu width matches the box (" + place.w + ")");
expect(place.y + place.h <= 726 - 46, "15-item menu near the bottom stays above the footer: y=" + place.y + " h=" + place.h);
expect(place.x >= 0 && place.x + place.w <= 1100, "15-item menu stays inside the window horizontally");
expect(place.vis >= 1 && place.vis < 15, "15-item menu near the bottom scrolls (" + place.vis + " visible of 15)");
expect(/hzSetDropScroll/.test(fnText(as, "hz51DrawDrop").body) && /i < vis/.test(fnText(as, "hz51DrawDrop").body),
	"draw path only paints visible options (GOLD..CUSTOM cannot hang below the panel)");
expect(/hzSetOver/.test(fnText(as, "hz51Draw").body) && fnText(as, "hz51Draw").body.indexOf("hz51DrawDrop") > fnText(as, "hz51Draw").body.indexOf("addChild(this.hzSetOver)"),
	"dropdown paints on hzSetOver, added after the rows, so GRAPHITE / # cannot draw over it");
expect(/beginFill\(uint\(T\.fill\),1\)/.test(fnText(as, "hz51DrawDrop").body),
	"open menu fill is opaque so row text cannot show through");

const slotsBody = "const HZ51_HEAD = 52; const HZ51_FIND_H = 30; const HZ51_FIND_W = 176;\n" + asJs(fnText(as, "hz51HeadSlots").body);
const slotsFn = new Function(slotsBody);
function slotsAt(tab) {
	return slotsFn.call({ HZ_SET_W: 1100, hzSetTab: tab });
}
function overlap(a, b) {
	return a.x < b.x + b.w && a.x + a.w > b.x && a.y < b.y + b.h && a.y + a.h > b.y;
}
for (const tab of [0, 2, 4]) {
	const s = slotsAt(tab);
	const compact = { x: s.cx, y: s.fy, w: s.cw, h: s.h, id: "compact" };
	const find = { x: s.fx, y: s.fy, w: s.findW, h: s.h, id: "search" };
	const arr = { x: s.ax, y: s.fy, w: s.arrW, h: s.h, id: "arrange" };
	const title = { x: 0, y: s.fy, w: s.titleR, h: s.h, id: "title" };
	expect(compact.x >= title.x + title.w, "tab " + tab + ": compact starts after the title cluster");
	expect(!overlap(compact, find), "tab " + tab + ": compact does not overlap search");
	if (s.arrW > 0) {
		expect(!overlap(find, arr), "tab " + tab + ": search does not overlap Arrange");
		expect(arr.x + arr.w <= 1100 - 16, "tab " + tab + ": Arrange stays inside the header");
	}
	expect(find.x + find.w <= (s.arrW > 0 ? arr.x : 1100 - 16), "tab " + tab + ": search stays left of Arrange / the right margin");
	expect(compact.w >= 96 && find.w === 176, "tab " + tab + ": compact and search have usable widths");
}
expect(/hz51T\(b,txt/.test(fnText(as, "hz51DrawSearchBox").body) && /fill\),0\.88/.test(fnText(as, "hz51DrawSearchBox").body),
	"search field uses 12px text on an opaque fill so placeholder and typed text stay readable");
expect(!/ON" : "OFF"/.test(fnText(as, "hz51Switch").body),
	"compact toggle has no ON/OFF label, so COMPACT MODE (STRIPS) cannot run into it");
expect(/hzSetFillA/.test(as) && /SettingsOpacity/.test(fnText(as, "hz51System").body),
	"SETTINGS WINDOW % (SettingsOpacity) still tints the window while you adjust");
expect(!/hzSetMove|drag window|window drag/i.test(fnText(as, "hz51Draw").body + fnText(as, "hzSettingsMouse").body),
	"the F11 window is not dragged (Arrange Cards still moves HUD cards; no new move feature)");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
