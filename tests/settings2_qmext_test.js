// Settings 2.0: CARDS > QUICK MENU empty-slots / panel opacity / slot scale
// (QuickMenuExtEmptySlots, QuickMenuExtPanelOpacity, QuickMenuExtSlotScale).
// Same key names, ranges and clamping as wip/0.43.5-quickmenu-fix so a later merge is clean.
// Run: node tests/settings2_qmext_test.js
// Author: Moragar. Last modified: 2026-11-26.
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
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
	const b = f.body
		.replace(/var (\w+):[\w.*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/int\(/g, "(");
	return new Function(...params, b);
}

const as = rd("actionscript/horizon_block.as");
const insert = rd("actionscript/hz51_insert.as");
const ini = rd("Interface/HorizonUI/HorizonUI.default.ini");
const preset = rd("preset/HorizonUI.moragars-choice.ini");
const quick = fnText(as, "hz51Quick").body;
const mute = fnText(as, "hz51Mute").body;
const help = fnText(as, "hz51Help").body;
const idx = fnText(as, "hz51IndexBuild").body;

expect(/"k":"QuickMenuExtEmptySlots","l":"EMPTY SLOTS","t":"r","opts":\["SHOW","HIDE"\],"ids":\[1,0\]/.test(quick),
	"Settings 2.0 EMPTY SLOTS is SHOW/HIDE (ids 1/0)");
expect(/"k":"QuickMenuExtPanelOpacity","l":"PANEL OPACITY","t":"n","mn":0,"mx":100,"st":1,"pct":1/.test(quick),
	"Settings 2.0 PANEL OPACITY is 0-100 step 1 percent");
expect(/"k":"QuickMenuExtSlotScale","l":"SLOT SCALE","t":"n","mn":0.7,"mx":1.4,"st":0.05/.test(quick),
	"Settings 2.0 SLOT SCALE is 0.7-1.4 step 0.05");
expect(quick.indexOf("QuickMenuExtEmptySlots") < quick.indexOf("_qmkeys")
	&& quick.indexOf("QuickMenuExtendedLayout") < quick.indexOf("QuickMenuExtEmptySlots"),
	"the three rows sit with the other Extended rows, before EXTENDED SLOT KEYS");
expect(insert.indexOf("QuickMenuExtEmptySlots") >= 0 && insert.indexOf("QuickMenuExtPanelOpacity") >= 0
	&& insert.indexOf("QuickMenuExtSlotScale") >= 0,
	"layout source of truth hz51_insert.as carries the three keys");

expect(/QuickMenuExtEmptySlots/.test(mute) && /QuickMenuExtPanelOpacity/.test(mute)
	&& /QuickMenuExtSlotScale/.test(mute) && /_qmkeys/.test(mute),
	"the three rows lock with the other Extended rows when Extended Mode is off");

expect(help.indexOf("SHOW = unused extras appear as empty squares with a faint plus") >= 0
	&& help.indexOf("HIDE = leave them off until assigned") >= 0
	&& help.indexOf("inventory assign still shows empties") >= 0,
	"EMPTY SLOTS help matches the player wording");
expect(help.indexOf("How solid the extra window is") >= 0
	&& help.indexOf("does not change other HUD cards") >= 0
	&& help.indexOf("Applies the next time you open the Quick Menu") >= 0,
	"PANEL OPACITY help matches the player wording");
expect(help.indexOf("Extra slot size compared with slots 1-12") >= 0
	&& help.indexOf("1.0 is the same size") >= 0,
	"SLOT SCALE help matches the player wording");
expect(!/\bini\b/i.test(help) && !/g_ini/i.test(help), "Quick Menu extra help has no ini keys");
expect(/String\(row\.k\)/.test(idx), "search haystack includes the setting key (the three extras are indexed with the other Quick Menu rows)");

expect(/QuickMenuExtEmptySlots=1/.test(ini) && /QuickMenuExtPanelOpacity=92/.test(ini)
	&& /QuickMenuExtSlotScale=1/.test(ini)
	&& ini.indexOf("QuickMenuExtEmptySlots=1") < ini.indexOf("QuickMenuKey13=")
	&& ini.indexOf("[Cards Extra]") < ini.indexOf("QuickMenuExtEmptySlots=1"),
	"default.ini [Cards Extra] has the three keys at SHOW / 92 / 1.0, before slot keys");
expect(/"QuickMenuExtEmptySlots":1/.test(as) && /"QuickMenuExtPanelOpacity":92/.test(as)
	&& /"QuickMenuExtSlotScale":1/.test(as),
	"HZ_SET_DEF defaults match the shipped INI");
expect(/\[Cards Extra\]/.test(preset) && /QuickMenuExtEmptySlots=1/.test(preset)
	&& /QuickMenuExtPanelOpacity=92/.test(preset) && /QuickMenuExtSlotScale=1/.test(preset),
	"Moragar's Choice ships the three keys at the same defaults");

const host = {
	hzQmOn: true, hzQmExt: false, hzQmCount: 24, hzQmPerRow: 6, hzQmLayout: 0,
	hzQmEmpty: 1, hzQmPanelA: 92, hzQmSlotSc: 1,
	hzQmKeys: ["", "", "", "", "", "", "", "", "", "", "", ""],
	hzB: (o) => (o ? "1" : "0")
};
for (const n of ["hzQmIniVal", "hzQmSetCur", "hzQmSetLive", "hzQmIniLines", "hzQmKeyAt", "hzQmClampEmpty",
	"hzQmClampPanelA", "hzQmClampScale", "hzPctOr"]) {
	host[n] = toJs(as, n).bind(host);
}
expect(host.hzQmClampEmpty(0) === 0 && host.hzQmClampEmpty(0.4) === 0 && host.hzQmClampEmpty(1) === 1,
	"empty-slots clamp is 0/1 at 0.5");
expect(host.hzQmClampPanelA(-4) === 0 && host.hzQmClampPanelA(140) === 100 && host.hzQmClampPanelA(Number("x")) === 92,
	"panel opacity clamp is 0-100, NaN -> 92");
expect(host.hzQmClampScale(0.2) === 0.7 && host.hzQmClampScale(2) === 1.4 && host.hzQmClampScale(Number("x")) === 1,
	"slot scale clamp is 0.7-1.4, NaN -> 1");
expect(host.hzQmIniVal("quickmenuextemptyslots", "hide") === true && host.hzQmEmpty === 0, "INI hide sets empty extras off");
expect(host.hzQmIniVal("quickmenuextemptyslots", "1") === true && host.hzQmEmpty === 1, "INI 1 sets empty extras on");
expect(host.hzQmIniVal("quickmenuextpanelopacity", "80") === true && host.hzQmPanelA === 80, "INI panel opacity 80");
expect(host.hzQmIniVal("quickmenuextslotscale", "1.25") === true && host.hzQmSlotSc === 1.25, "INI slot scale 1.25");
host.hzQmSetLive({ QuickMenuExtEmptySlots: 0, QuickMenuExtPanelOpacity: 200, QuickMenuExtSlotScale: 0.1 });
expect(host.hzQmEmpty === 0 && host.hzQmPanelA === 100 && host.hzQmSlotSc === 0.7,
	"live apply clamps the three extras the same way as the INI reader");
const cur = {};
host.hzQmSetCur(cur);
expect(cur.QuickMenuExtEmptySlots === 0 && cur.QuickMenuExtPanelOpacity === 100 && cur.QuickMenuExtSlotScale === 0.7,
	"current values expose the three extras for save and presets");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
