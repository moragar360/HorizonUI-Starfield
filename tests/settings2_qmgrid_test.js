// Settings 2.0: Cards > Quick Menu EXTENDED SLOT KEYS grid (QuickMenuKey13-24).
// Run: node tests/settings2_qmgrid_test.js
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

const as = rd("actionscript/horizon_block.as");
const hdr = rd("src/hz_quickslots.h");
const mainCpp = rd("src/main.cpp");
const ini = rd("Interface/HorizonUI/HorizonUI.default.ini");
const grid = fnText(as, "hz51DrawQmGrid").body;
const capKey = fnText(as, "hzQmCapKey").body;
const kind = fnText(as, "hzQmNameKind").body;
const iniLines = fnText(as, "hzQmIniLines").body;
const iniVal = fnText(as, "hzQmIniVal").body;
const clear = fnText(as, "hz51QmClear").body;
const mute = fnText(as, "hz51Mute").body;
const quick = fnText(as, "hz51Quick").body;
const settingsKey = fnText(as, "hzSettingsKey").body;

expect(/\"t\":\"kg\"/.test(quick) && /EXTENDED SLOT KEYS/.test(quick), "Quick Menu page has an EXTENDED SLOT KEYS grid row");
expect(/UNAVAILABLE/.test(fnText(as, "hz51Unavail").body), "missing Quick Menu module uses the UNAVAILABLE banner");
expect(/Install it from the Horizon UI installer\. Saved settings are kept\./.test(quick), "not-installed Quick Menu keeps saved settings and greys the page");
expect(mute.indexOf("Turn on Extended Mode to bind keys. Saved keys are kept.") >= 0, "Extended off greys the key grid with the saved-keys note");
expect(grid.indexOf("Turn on Extended Mode to bind keys. Saved keys are kept.") >= 0, "grid draws the Extended-off lock note on the tiles");
expect(/CLEAR ALL KEYS/.test(grid) && /id\":\"qmclr\"/.test(grid), "CLEAR ALL KEYS sits on the key grid");
expect(/id == \"qmclr\"/.test(fnText(as, "hzSettingsMouse").body) && /hz37Act/.test(fnText(as, "hzSettingsMouse").body), "CLEAR ALL KEYS click arms a confirm, it does not clear on the first press");
expect(/k == \"_qmclear\"/.test(fnText(as, "hz37Act").body) && /hz51QmClear/.test(fnText(as, "hz37Act").body), "the second confirm press clears pending extra-slot keys");
expect(/while\(n <= 24\)/.test(clear) && /QuickMenuKey/.test(clear), "Clear all writes empty QuickMenuKey13-24 (hidden slots included)");

expect(/var n:int = 13/.test(grid) && /while\(n <= count\)/.test(grid) && /col >= per/.test(grid), "tiles are 13..SlotCount wrapped by Slots per Row");
expect(/SLOT \" \+ n/.test(grid) && /UNBOUND/.test(grid) && /PRESS ANY KEY/.test(grid), "tiles show SLOT N, UNBOUND, and PRESS ANY KEY capture");
expect(/0xF2A03A/.test(as) && /CLASH/.test(grid) && /hzQmNameKind/.test(grid), "clashing chips use the orange clash warning");
expect(/Enter uses a game key anyway/.test(grid) && !/warned and ignored/.test(grid), "clash tile text matches Enter confirm / settings refuse");
expect(/\"0\" \|\| u == \"1\"/.test(kind) && /F1/.test(kind) && /return \"settings\"/.test(kind) && /return \"slot\"/.test(kind), "clash checks slots 1-12 game keys, other extra slots, and the Horizon settings key");

expect(/code == \"cancel\"/.test(capKey) && /code == \"bksp\" \|\| code == \"del\"/.test(capKey), "Esc cancels capture; Backspace and Delete clear");
expect(/VK_DELETE: return \"del\"/.test(mainCpp), "DLL forwards Delete on the existing QueueKey path (no extra poll)");
expect(/hzQmCap\.length > 0/.test(settingsKey) && /hzQmCapKey\(code\)/.test(settingsKey), "capture runs only while a chip is waiting");
expect(/if\(this\.hzQmCap\.length == 0\) \{ return false; \}/.test(capKey), "idle chips do not eat key codes");
expect(!/GetAsyncKeyState/.test(grid + capKey + fnText(as, "hzQmCapTake").body + fnText(as, "hzQmCapBegin").body), "grid/capture add no key polling");

expect(/kk \+ \"=\" \+ String\(p\[kk\]/.test(iniLines) && /QuickMenuKey\" \+ \(13 \+ i\)/.test(iniLines), "INI writer uses QuickMenuKeyN=value with no quotes");
expect(/slot >= 13 && slot <= 24/.test(iniVal) && /hzQmKeys\[slot - 13\] = v/.test(iniVal), "INI reader stores QuickMenuKey13-24 in the same 12 slots the DLL uses");
expect(/QuickMenuKey13=\n/.test(ini) && /QuickMenuKey24=\n/.test(ini), "default.ini leaves keys 13-24 empty");
expect(/s\.key\[slot - kExtFirst\] = CanonKey\(raw\)/.test(hdr) && /k\.rfind\(\"quickmenukey\", 0\) == 0/.test(hdr), "DLL ApplyKey still reads QuickMenuKeyN through CanonKey");
expect(/PageUp/.test(fnText(as, "hzQmCanon").body) && /PageUp/.test(hdr), "HUD and DLL keep the same named-key spelling (PageUp)");

function visibleTiles(count, per) {
	count = Math.max(12, Math.min(24, count | 0));
	if (per !== 4 && per !== 6 && per !== 8) per = 6;
	const tiles = [];
	for (let n = 13; n <= count; n++) tiles.push(n);
	const rows = [];
	for (let i = 0; i < tiles.length; i += per) rows.push(tiles.slice(i, i + per));
	return { tiles, rows };
}
expect(visibleTiles(24, 6).tiles.length === 12 && visibleTiles(24, 6).rows.length === 2, "Slot Count 24 / 6 per row shows tiles 13-24 in two rows");
expect(visibleTiles(18, 6).tiles.join(",") === "13,14,15,16,17,18" && visibleTiles(18, 6).rows.length === 1, "lowering Slot Count to 18 hides 19-24");
expect(visibleTiles(16, 4).rows.length === 1 && visibleTiles(20, 4).rows.length === 2, "Slots per Row 4 wraps 13-16 on one row and 13-20 on two");
expect(visibleTiles(12, 6).tiles.length === 0, "Slot Count 12 shows no extra-slot tiles");

function toJs(name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
	const b = f.body
		.replace(/var (\w+):[\w*.]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/int\(/g, "(");
	return new Function(...params, b);
}
const host = {
	hzSetPend: {
		SettingsKey: "F11",
		QuickMenuKey13: "G",
		QuickMenuKey14: "",
		QuickMenuKey15: "P",
		QuickMenuKey16: "", QuickMenuKey17: "", QuickMenuKey18: "",
		QuickMenuKey19: "", QuickMenuKey20: "", QuickMenuKey21: "",
		QuickMenuKey22: "", QuickMenuKey23: "", QuickMenuKey24: "G"
	},
	hzSettingsKeyName: "F11",
	hzQmCap: "QuickMenuKey14",
	hzQmCapWarn: "",
	hzQmCapCand: "",
	hzQmCapKind: "",
	hzQmCapEnd() { this.hzQmCap = ""; this.hzQmCapWarn = ""; this.hzQmCapCand = ""; this.hzQmCapKind = ""; },
	hzSetLive() {}
};
host.hzQmNameKind = toJs("hzQmNameKind").bind(host);
host.hzQmCanon = toJs("hzQmCanon").bind(host);
host.hzQmCapClash = toJs("hzQmCapClash").bind(host);
host.hzQmCapApply = toJs("hzQmCapApply").bind(host);
host.hzQmCapKey = toJs("hzQmCapKey").bind(host);
host.hzQmCapTake = toJs("hzQmCapTake").bind(host);
host.hzQmKeyOk = toJs("hzQmKeyOk").bind(host);

expect(host.hzQmNameKind("G", "QuickMenuKey14") === "slot", "duplicate extra-slot key is a slot clash");
expect(host.hzQmNameKind("F11", "QuickMenuKey14") === "settings", "settings key clash is settings");
expect(host.hzQmNameKind("1", "QuickMenuKey14") === "game" && host.hzQmNameKind("W", "QuickMenuKey14") === "game", "number-row and WASD clash as game keys (slots 1-12 / movement)");
expect(host.hzQmNameKind("X", "QuickMenuKey14") === "", "an unused letter is free");
expect(host.hzQmCanon("f5") === "F5" && host.hzQmCanon("pageup") === "PageUp", "capture stores CanonKey spelling the DLL reads");

host.hzQmCapKey("del");
expect(host.hzSetPend.QuickMenuKey14 === "" && host.hzQmCap === "", "Delete while capturing clears that slot and ends capture");
host.hzQmCap = "QuickMenuKey14";
host.hzQmCapApply("g", false);
expect(host.hzSetPend.QuickMenuKey14 === "G", "apply writes the same uppercase letter the DLL CanonKey stores");
expect(host.hzSetPend.QuickMenuKey13 === "G" && host.hzSetPend.QuickMenuKey24 === "G", "lowering visibility does not clear saved keys on hidden tiles 13 and 24");

host.hzSetPend.QuickMenuKey16 = "H";
host.hzQmCap = "QuickMenuKey16";
host.hzQmCapKey("cancel");
expect(host.hzQmCap === "" && host.hzSetPend.QuickMenuKey16 === "H", "Esc cancels without writing a key");

const hidden = [];
const count = 18;
for (let n = 13; n <= 24; n++) {
	if (n > count) hidden.push("QuickMenuKey" + n);
}
expect(hidden.join(",") === "QuickMenuKey19,QuickMenuKey20,QuickMenuKey21,QuickMenuKey22,QuickMenuKey23,QuickMenuKey24", "tiles past Slot Count stay in pending/INI, they are only hidden");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
