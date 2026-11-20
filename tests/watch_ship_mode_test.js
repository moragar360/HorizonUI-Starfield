// 0.43.3.2 item 4 tests: the HORIZON DIGITAL / HORIZON ANALOG watch (WatchStyle 3 / 4) hides in ship HUD mode.
// Run: node tests/watch_ship_mode_test.js
// The game hides its bottom-left group (the vanilla watch) in ship HUD mode through HudModeData; the HUD host stores
// that in hzGroupVisible and calls hzRefreshVisibility (the existing edge). The Horizon face now follows it.
// Runs the production hz43Want, hz43Frame and hz43VanLate (types stripped) on a host and checks: shown on foot;
// hidden (one write) when the group hides; no per-frame writes while hidden; the exit-frame pass does not move the
// markers while hidden; shown again on exit; ARRANGE keeps it; HUD hide (hzUserHidden) unchanged. Mutants must fail.
// Author: Moragar. Last modified: 2026-11-18.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const AS0 = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

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
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)");
	return new Function(...params, body);
}
function clip() {
	const c = { vw: 0, _v: false };
	Object.defineProperty(c, "visible", { get() { return this._v; }, set(v) { this.vw++; this._v = v; } });
	return c;
}
function makeHost(src) {
	const h = {
		hz43Watch: clip(), hz43ScanHid: false, hz43ScanSt: -1, hzWatchStyle: 3, hzUserHidden: false,
		hzGroupVisible: true, hzArrange: false, hz43TintOn: false, places: 0, horizons: 0, draws: 0,
		hz43ScanHideSync() { }, hz43VanPlace() { this.places++; }, hz43Tint() { }, hz43Build() { }, hz43Place() { },
		hz43VanHorizon() { this.horizons++; }, hz43Dirty() { return 0; }, hz43Draw() { this.draws++; }, hz43DrawCmp() { },
		hz43VanSame() { return false; }, hz43ShowSweep() { },
	};
	h.hz43Want = toJs(src, "hz43Want").bind(h);
	h.hz43Frame = toJs(src, "hz43Frame").bind(h);
	h.hz43VanLate = toJs(src, "hz43VanLate").bind(h);
	return h;
}
// one game frame: enterFrame then the 2-3 exitFrames
function frame(h) { h.hz43Frame(); h.hz43VanLate(); h.hz43VanLate(); }
function behave(src, log) {
	const bad = [];
	const chk = (c, m) => { if (log) expect(c, m); if (!c) bad.push(m); };
	try {
		const h = makeHost(src);
		frame(h);
		chk(h.hz43Watch.visible === true, "on foot: the face shows");
		h.hzGroupVisible = false;   // HudModeData: ship HUD mode hides the bottom-left group
		frame(h);
		chk(h.hz43Watch.visible === false, "ship HUD mode: the face hides");
		const vw = h.hz43Watch.vw, hz = h.horizons, pl = h.places;
		for (let i = 0; i < 300; i++) frame(h);
		chk(h.hz43Watch.vw === vw, "300 frames in ship mode: no visible write");
		chk(h.horizons === hz, "in ship mode the markers are not moved onto the face (enter or exit frame)");
		chk(h.places - pl === 300, "in ship mode hz43VanPlace keeps the markers home (once per frame, as with the HUD hidden)");
		h.hzGroupVisible = true;   // leaving the ship HUD
		frame(h);
		chk(h.hz43Watch.visible === true && h.horizons > hz, "ship HUD mode exit: the face shows again and the markers follow it");
		h.hzGroupVisible = false; h.hzArrange = true; frame(h);
		chk(h.hz43Watch.visible === true, "ARRANGE keeps the face for placing");
		h.hzArrange = false; h.hzGroupVisible = true; h.hzUserHidden = true; frame(h);
		chk(h.hz43Watch.visible === false, "HUD hide (hzUserHidden) still hides it");
		h.hzUserHidden = false; h.hzWatchStyle = 1; frame(h);
		chk(h.hz43Watch.visible === false, "vanilla styles never show the Horizon face");
		const h2 = makeHost(src); h2.hzWatchStyle = 4; h2.hzGroupVisible = false; frame(h2);
		chk(h2.hz43Watch.visible === false && h2.horizons === 0, "HORIZON ANALOG: hidden the same way");
	} catch (e) {
		chk(false, "threw " + e.message);
	}
	return bad;
}

behave(AS0, true);

// source pins: the edge that feeds hzGroupVisible is in both HUD hosts the build splices into
for (const f of ["HUDMenu_1.as", "HUDMenu_1.07.as"]) {
	const t = fs.readFileSync(path.join(root, "actionscript", f), "utf8");
	expect(/BSUIDataManager\.Subscribe\("HudModeData"[\s\S]{0,1600}hzGroupVisible = BottomLeftGroup_mc\.visible; hzRefreshVisibility\(\);/.test(t),
		f + ": HudModeData sets hzGroupVisible from the game's BottomLeftGroup and refreshes (the existing edge)");
}
expect(/var show:Boolean = this\.hz43Want\(\);/.test(fnText(AS0, "hz43Frame").body), "hz43Frame decides with hz43Want");

const mutants = [
	["the old show (ignores the HUD mode)", (s) => s.replace("&& !this.hzUserHidden && (this.hzGroupVisible || this.hzArrange);", "&& !this.hzUserHidden;")],
	["exit frame moves markers while hidden", (s) => s.replace("if(this.hzGroupVisible || this.hzArrange) { this.hz43VanHorizon(); }", "this.hz43VanHorizon();")],
	["hidden write every frame", (s) => s.replace("if(this.hz43Watch && this.hz43Watch.visible) { this.hz43Watch.visible = false; }", "if(this.hz43Watch) { this.hz43Watch.visible = false; }")],
	["ARRANGE dropped", (s) => s.replace("(this.hzGroupVisible || this.hzArrange);", "this.hzGroupVisible;")],
];
for (const [name, fn] of mutants) {
	const m = fn(AS0);
	if (m === AS0) { expect(false, "mutant " + name + " applies"); continue; }
	const bad = behave(m, false);
	expect(bad.length > 0, "mutant " + name + " is caught" + (bad.length ? " (" + bad[0] + ")" : ""));
}

console.log("watch ship mode: " + passed + " ok" + (failed ? ", " + failed + " FAILED" : ", all passed"));
process.exit(failed ? 1 : 0);
