// 0.43.3.2 item 1 tests: the HORIZON DIGITAL / HORIZON ANALOG watch (WatchStyle 3 / 4) no longer writes its
// transform and visibility every frame. Run: node tests/watch_frame_writes_test.js
// Runs the production hz43Place and hz43Frame (types stripped) on a host that counts display writes, and checks:
//  steady frames write nothing; a scale change (F11 size) writes once; a scale set by someone else (hzApplyScale) is
//  put back on the next frame like before; the face stays visible; the clock face redraw gate (hz43Dirty) is unchanged
//  (minute / heading / gauge edges only, no seconds). Mutants (the old every-frame writes) must fail.
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
// a display object whose scale is stored as a float (like Scaleform) and whose writes are counted
function clip() {
	const c = { w: 0, vw: 0, _sx: 1, _sy: 1, _v: false };
	Object.defineProperty(c, "scaleX", { get() { return this._sx; }, set(v) { this.w++; this._sx = Math.fround(v); } });
	Object.defineProperty(c, "scaleY", { get() { return this._sy; }, set(v) { this.w++; this._sy = Math.fround(v); } });
	Object.defineProperty(c, "visible", { get() { return this._v; }, set(v) { this.vw++; this._v = v; } });
	return c;
}
function makeHost(src) {
	const h = {
		hz43Watch: clip(), sc: 1.07, saved: false, hz43WasSaved: false, hz43Ps: NaN, hz43Ax: -1, home: 0,
		hz43PlSc: NaN, hz43PlRbX: NaN, hz43PlRbY: NaN,
		hz43ScanHid: false, hz43ScanSt: -1, hzWatchStyle: 3, hzUserHidden: false, hzGroupVisible: true, hzArrange: false, hz43TintOn: false, dirty: 0, draws: 0, cmps: 0,
		hz43Locals() { return true; }, hz34S() { return this.sc; }, hzLayHas() { return this.saved; },
		hz43ApplyHome() { this.home++; }, hz43ApplySaved() { }, hz43LayStamp() { },
		hz43ScanHideSync() { }, hz43VanPlace() { }, hz43Tint() { }, hz43Build() { }, hz43VanHorizon() { },
		hz43Dirty() { return this.dirty; }, hz43Draw() { this.draws++; }, hz43DrawCmp() { this.cmps++; },
	};
	h.hz43Place = toJs(src, "hz43Place").bind(h);
	h.hz43Frame = toJs(src, "hz43Frame").bind(h);
	if (/function hz43Want\(/.test(src)) h.hz43Want = toJs(src, "hz43Want").bind(h);
	return h;
}
function behave(src, log) {
	const bad = [];
	const chk = (c, m) => { if (log) expect(c, m); if (!c) bad.push(m); };
	try {
		const h = makeHost(src);
		h.hz43Frame();
		chk(h.hz43Watch.scaleX === Math.fround(1.07) && h.hz43Watch.visible === true, "first frame: the face gets its scale and shows");
		const w0 = h.hz43Watch.w, v0 = h.hz43Watch.vw;
		for (let i = 0; i < 600; i++) h.hz43Frame();
		chk(h.hz43Watch.w === w0, "600 steady frames: no scale write (was 2 per frame)");
		chk(h.hz43Watch.vw === v0, "600 steady frames: no visible write (was 1 per frame)");
		chk(h.hz43Watch.visible === true && h.draws === 0 && h.cmps === 0, "the face stays shown; nothing redrawn while nothing changed");
		h.sc = 1.2; h.hz43Frame();
		chk(h.hz43Watch.scaleX === Math.fround(1.2) && h.hz43Watch.w === w0 + 2, "an F11 size change: one write of each axis");
		h.hz43Frame();
		chk(h.hz43Watch.w === w0 + 2, "then steady again");
		h.hz43Watch.scaleX = 1; const w1 = h.hz43Watch.w;
		h.hz43Frame();
		chk(h.hz43Watch.scaleX === Math.fround(1.2) && h.hz43Watch.w === w1 + 2, "scale changed elsewhere: put back on the next frame (as before)");
		h.hz43Watch.visible = false; const v1 = h.hz43Watch.vw;
		h.hz43Frame();
		chk(h.hz43Watch.visible === true && h.hz43Watch.vw === v1 + 1, "hidden elsewhere: shown again on the next frame (as before)");
		h.dirty = 1; h.hz43Frame(); h.dirty = 2; h.hz43Frame(); h.dirty = 0;
		chk(h.cmps === 1 && h.draws === 1, "heading edge redraws the compass layer, a face edge the face (unchanged)");
		h.hzWatchStyle = 1; h.hz43Frame();
		chk(h.hz43Watch.visible === false, "another style: the face hides (unchanged)");
		h.hzWatchStyle = 4; h.hz43Frame();
		chk(h.hz43Watch.visible === true, "HORIZON ANALOG: shown again");
		h.home = 0; for (let i = 0; i < 10; i++) h.hz43Frame();
		chk(h.home === 10, "the placement check itself still runs (its own gates decide; not changed here)");
	} catch (e) { bad.push("threw: " + e.message); if (log) expect(false, "threw: " + e.message); }
	return bad;
}
expect(behave(AS0, true).length === 0, "all watch write checks pass on the production source");

// ---- source: the redraw gate is minute / heading / gauge based, no seconds, no own frame listener ----
const dirty = fnText(AS0, "hz43Dirty").body;
expect(/this\.hz43M != this\.hz43LastM/.test(dirty) && /this\.hz43PcM != this\.hz43LastPcM/.test(dirty) && !/getSeconds|hz43S\b|Sec/.test(dirty), "hz43Dirty: the clock redraws on a game or PC minute change; no seconds anywhere in the gate");
expect(/head != this\.hz43LastHead/.test(dirty) && /if\(!hch\) \{ return 0; \}/.test(dirty), "hz43Dirty: a steady frame returns 0 (no draw)");
const pc = fnText(AS0, "hz43PcSample").body;
expect(/\(this\.hzFrameN - this\.hz43PcFr\) < 60/.test(pc), "PC clock: one Date read per 60 frames at most (unchanged)");
const wsec = AS0.slice(AS0.indexOf("private function hz43Read("), AS0.indexOf("private function hz43CardAt("));
expect(!/addEventListener|ENTER_FRAME|Timer|cacheAsBitmap|getSeconds/.test(wsec), "watch face code: no listener, timer, cacheAsBitmap or seconds");
const place = fnText(AS0, "hz43Place").body;
expect((place.match(/scaleX = /g) || []).length === 1 && /if\(sc != this\.hz43PlSc \|\| w43\.scaleX != this\.hz43PlRbX \|\| w43\.scaleY != this\.hz43PlRbY\)/.test(place), "hz43Place: the only scale write is behind the change check");
expect(/if\(!this\.hz43Watch\.visible\) \{ this\.hz43Watch\.visible = true; \}/.test(fnText(AS0, "hz43Frame").body), "hz43Frame: shows the face only when it is hidden");

// ---- mutants: the old every-frame writes ----
function mutate(name, from, to) {
	if (AS0.indexOf(from) < 0) { expect(false, "mutant " + name + ": anchor not found"); return; }
	const bad = behave(AS0.replace(from, to), false);
	expect(bad.length > 0 && !/^threw/.test(bad[0]), "mutant " + name + " is caught (" + (bad[0] || "-") + ")");
}
mutate("scale every frame", "if(sc != this.hz43PlSc || w43.scaleX != this.hz43PlRbX || w43.scaleY != this.hz43PlRbY)", "if(true)");
mutate("visible every frame", "if(!this.hz43Watch.visible) { this.hz43Watch.visible = true; }", "this.hz43Watch.visible = true;");
mutate("no read-back (external scale missed)", "|| w43.scaleX != this.hz43PlRbX || w43.scaleY != this.hz43PlRbY)", ")");

console.log("watch frame writes: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
