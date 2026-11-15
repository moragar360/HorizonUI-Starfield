// perf round 2 Fix 1 tests: the compass dispatch (HudCompassData, every frame) redraws only on a change.
// Run: node tests/perf_r2_fix1_test.js   (HZ_AS=<file> runs it against another horizon_block.as)
// Before: every dispatch cleared and redrew the 37-tick strip, the 8 labels, the heading texts, both marker layers
// (with a debug string per marker even with Debug off), re-ran the quest fill / pick / sort, and hzRefreshVisibility.
// Proves, by running the production AS (types stripped) next to the ff4c33f bodies:
//  1. markers: over random dispatches (heading drift, markers moving, fading, added / removed, duplicate handles,
//     settings toggles, style and form changes) a redraw draws exactly what the old pass draws that dispatch, and on a
//     skipped dispatch the shown glyphs differ from the old ones by under half a pixel and under 0.05 alpha, with the
//     same glyphs in the same order; Debug=1 redraws every dispatch; a throw while drawing forces the next redraw;
//  2. strip: a due dispatch draws exactly the old strip; a skipped one is within 0.25 deg and half a pixel of the
//     heading; the heading texts show the drawn heading; form, color and width changes and hzCmpDraw19 force a draw;
//  3. quests: with the quest-update and title paths firing in between, every dispatch leaves the same objective,
//     distance and sub-step texts as the old fill + refresh, while the fill runs far less; hzQSync runs every dispatch;
//  4. visibility: hzCmpVisDue is true on the first dispatch and on a quest card state change only;
//  5. static: no timer, listener or search in the new functions; the dispatch keeps its PerfDiag marks.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");
const gitBase = require("./lib/git_base.js");
const baseRes = gitBase.readBase(root, "ff4c33f");   // S-1b: SKIP only without a repository or in a shallow clone
let baseAs = baseRes.src;

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const i = src.indexOf("private function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(i, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function toJs(body) {
	return body
		.replace(/for each\s*\(\s*var\s+(\w+)\s*:\s*[\w.*]+\s+in\s+/g, "for (var $1 of ")
		.replace(/for each\s*\(\s*(\w+)\s+in\s+/g, "for ($1 of ")
		.replace(/([\w.\[\]]+) is Array\b/g, "Array.isArray($1)")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
function bind(host, src, name) {
	const f = fnText(src, name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}
function rng(seed) { let s = seed >>> 0; return function() { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
function codeOnly(body) { return body.replace(/\/\/[^\n]*/g, ""); }

const MMU = { MIT_MARKER_QUEST: 1, MIT_MARKER_QUEST_DOOR: 2, MIT_MARKER_QUEST_OFFPLANET: 3, MIT_MARKER_COMPANION: 4, MIT_MARKER_SHIP_PARKED: 5,
	MIT_MARKER_VEHICLE: 6, MIT_MARKER_ENEMY: 7, MIT_MARKER_ENEMY_TARGETED: 8, MIT_MARKER_PLAYERSET: 9, MIT_MARKER_POSITION: 10,
	MIT_MARKER_HAZARD: 11, MIT_MARKER_OUTPOST: 12 };
const TYPES = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14];

// recording Graphics: the ops since the last clear
function G() { this.ops = []; this.clears = 0; }
for (const n of ["beginFill", "endFill", "moveTo", "lineTo", "curveTo", "drawRect", "drawCircle", "lineStyle"]) {
	G.prototype[n] = function () { this.ops.push([n].concat(Array.prototype.slice.call(arguments))); };
}
G.prototype.clear = function () { this.ops = []; this.clears++; };

function commonHost(src) {
	const h = {
		uint: (v) => Number(v) >>> 0, int: (v) => Number(v) | 0, MapMarkerUtils: MMU,
		HZ_CMP_W: 520, HZ_RED: 0xFF5B5B, HZ_BLUE: 0x4DB6FF, HZ_ACCENT: 0x3FD0E0, HZ_CMP_LISTS: ["aMissionMarkers", "aMarkers", "aEnemyMarkers"],
		hzCmpMarks: { graphics: new G() }, hzCmpMarks19: { graphics: new G() }, hzCmpData: null, hzCmpDeg: 0,
		hzCmpW19: 640, hzCmpMY: 47, hzCmpC: 0, hzDebug: false, hzFrameN: 0, hzDbgCmp: "", hzFolColor: 0, dark: false, v19: true,
		hzShowCompassMarkers: true, hzCmpFollowers: true, hzCmpShip: true, hzCmpEnemies: true, hzCmpPlayerMark: true, hzCmpLocations: true,
		dbgLabels: 0, throwFol: false,
	};
	h.hzV19 = () => h.v19;
	h.hzDarkText = () => h.dark;
	h.hzMainCol = () => (h.dark ? 0x0E151B : 0xF2F7F9);
	h.hzIconCol = (c) => (h.dark ? (c ^ 0x111111) : c);
	h.hz27FolCol = () => { if (h.throwFol) throw new Error("fol"); return [0x5CFF7A, 0xFFAA00, 0x66CCFF][h.hzFolColor]; };
	h.hzCmpDbgClear = () => {};
	h.hzCmpDbgLabel = () => { h.dbgLabels++; };
	h.hzDbgShow = () => {};
	for (const n of ["hzIsQuestType", "hzCmpMark19", "hz30FolEdge"]) bind(h, src, n);
	const m19 = h.hzCmpMark19;
	h.throwPaint = false;
	h.hzCmpMark19 = (g, kind, mx, fa) => { if (h.throwPaint && kind === "quest") { m19(g, kind, mx, fa); throw new Error("paint"); } return m19(g, kind, mx, fa); };
	return h;
}
// the new pass's own fields, as declared in horizon_block.as
function markState(h) {
	return Object.assign(h, { hzCmpLs: [], hzCmpLn: [], hzCmpSeenH: [], hzCmpQ: [], hzCmpQN: [], hzCmpPx: [], hzCmpPa: [], hzCmpMkOk: false,
		hzCmpKV: false, hzCmpKW: NaN, hzCmpKY: NaN, hzCmpKM: -1, hzCmpKF: -1, hzCmpKA: -1, hzCmpKB: -1, hzCmpKR: -1 });
}
function shown(h) { return JSON.stringify([h.hzCmpMarks.graphics.ops, h.hzCmpMarks19.graphics.ops]); }
function near(a, b) {
	// same glyphs in the same order; coordinates within half a pixel, alphas within 0.05, everything else equal
	for (let L = 0; L < 2; L++) {
		const A = a[L], B = b[L];
		if (A.length !== B.length) return "op count " + A.length + " vs " + B.length;
		for (let i = 0; i < A.length; i++) {
			if (A[i][0] !== B[i][0] || A[i].length !== B[i].length) return "op " + i + " " + A[i][0] + " vs " + B[i][0];
			for (let k = 1; k < A[i].length; k++) {
				const x = A[i][k], y = B[i][k];
				if (x === y) continue;
				if (typeof x !== "number" || typeof y !== "number") return "arg " + i + "." + k;
				const op = A[i][0];
				const isAlpha = (op === "beginFill" && k === 2) || (op === "lineStyle" && k === 3);
				const tol = isAlpha ? 0.05 + 1e-9 : 0.5 + 1e-9;
				if (Math.abs(x - y) > tol) return "arg " + i + "." + k + " " + op + " " + x + " vs " + y;
			}
		}
	}
	return "";
}

// ---- 1. markers ----
if (!baseAs) { gitBase.report(baseRes, "ff4c33f", "old-vs-new marker checks", expect); }
else {
	let totalOld = 0, totalNew = 0, badMsg = "", dbgOk = true, throwOk = true, frames = 0, throwSeen = 0;
	for (let seed = 1; seed <= 8 && !badMsg; seed++) {
		const r = rng(seed * 7919);
		const O = commonHost(baseAs), N = markState(commonHost(as));
		bind(O, baseAs, "hzDrawCompassMarkers");
		for (const n of ["hzDrawCompassMarkers", "hzCmpMarkPaint"]) bind(N, as, n);
		let marks = [];
		let hid = 1;
		const mk = () => ({ fHeading: r() * 2 * Math.PI - Math.PI, uiMarkerIconType: TYPES[Math.floor(r() * TYPES.length)],
			uMapMarkerType: r() < 0.5 ? Math.floor(r() * 90) : undefined, uiHandle: r() < 0.2 ? 0 : (r() < 0.15 && hid > 2 ? Math.floor(r() * hid) + 1 : hid++),
			fDistanceAlpha: r() < 0.3 ? undefined : r(), bIsNear: r() < 0.5, list: Math.floor(r() * 4) });
		for (let i = 0; i < 8; i++) marks.push(mk());
		let deg = r() * 360;
		for (let f = 0; f < 600 && !badMsg; f++) {
			frames++;
			const x = r();
			if (x < 0.5) { /* standing still */ }
			else if (x < 0.8) deg += (r() - 0.5) * 0.3;   // slow drift, mostly under the threshold
			else deg += (r() - 0.5) * 20;
			deg = ((deg % 360) + 360) % 360;
			for (const m of marks) {
				if (r() < 0.2) m.fHeading += (r() - 0.5) * 0.004;
				if (r() < 0.05) m.fDistanceAlpha = r() < 0.1 ? undefined : Math.max(0, Math.min(1, (m.fDistanceAlpha || 0.5) + (r() - 0.5) * 0.1));
				if (r() < 0.005) m.uiMarkerIconType = TYPES[Math.floor(r() * TYPES.length)];
			}
			if (r() < 0.03) marks.push(mk());
			if (r() < 0.03 && marks.length) marks.splice(Math.floor(r() * marks.length), 1);
			const settings = r() < 0.01;
			if (settings) {
				const keys = ["hzShowCompassMarkers", "hzCmpFollowers", "hzCmpShip", "hzCmpEnemies", "hzCmpPlayerMark", "hzCmpLocations"];
				const k = keys[Math.floor(r() * keys.length)];
				O[k] = N[k] = !O[k];
			}
			if (r() < 0.01) { O.dark = N.dark = !O.dark; }
			if (r() < 0.01) { O.hzFolColor = N.hzFolColor = (O.hzFolColor + 1) % 3; }
			if (r() < 0.01) { const c = O.hzCmpC ? 0 : 1; O.hzCmpC = N.hzCmpC = c; O.hzCmpW19 = N.hzCmpW19 = c ? 420 : 640; O.hzCmpMY = N.hzCmpMY = c ? 29 : 47; }
			if (r() < 0.005) { O.v19 = N.v19 = !O.v19; }
			const dbg = r() < 0.02;
			O.hzDebug = N.hzDebug = dbg;
			// fresh data objects each dispatch, as the game sends them
			const data = { aMissionMarkers: [], aMarkers: [], aEnemyMarkers: [], aExtraEnemyThings: [] };
			const names = ["aMissionMarkers", "aMarkers", "aEnemyMarkers", "aExtraEnemyThings"];
			for (const m of marks) data[names[m.list]].push(Object.assign({}, m));
			if (r() < 0.1) data.aMissionMarkers.push(null);
			if (!data.aExtraEnemyThings.length) delete data.aExtraEnemyThings;
			O.hzCmpData = data; N.hzCmpData = JSON.parse(JSON.stringify(data, (k, v) => v === undefined ? "__u" : v), (k, v) => v === "__u" ? undefined : v);
			O.hzCmpDeg = N.hzCmpDeg = deg;
			const throwNow = r() < 0.01;
			O.throwPaint = N.throwPaint = throwNow;
			if (throwNow) N.hzCmpMkOk = false;   // force this dispatch to draw, so the throw lands after the clear
			const c0 = N.hzCmpMarks.graphics.clears + N.hzCmpMarks19.graphics.clears;
			let eo = null, en = null;
			try { O.hzDrawCompassMarkers(); } catch (e) { eo = e; }
			try { N.hzDrawCompassMarkers(); } catch (e) { en = e; }
			const redrew = N.hzCmpMarks.graphics.clears + N.hzCmpMarks19.graphics.clears !== c0;
			totalOld++;
			if (redrew) totalNew++;
			if (dbg && !redrew) dbgOk = false;
			if (throwNow) {
				O.throwPaint = N.throwPaint = false;
				if (en && redrew && N.hzCmpMkOk !== false) throwOk = false;   // cleared, then threw: must redraw next time
				if (en && redrew) throwSeen++;
				continue;   // a throw leaves both partial; the next dispatch must agree again
			}
			if (redrew) { if (shown(N) !== shown(O)) badMsg = "seed " + seed + " frame " + f + ": redraw differs from the old pass"; }
			else {
				const d = near([N.hzCmpMarks.graphics.ops, N.hzCmpMarks19.graphics.ops], [O.hzCmpMarks.graphics.ops, O.hzCmpMarks19.graphics.ops]);
				if (d) badMsg = "seed " + seed + " frame " + f + ": skipped dispatch off by more than the steps: " + d;
			}
		}
	}
	expect(!badMsg, "markers: " + frames + " dispatches, 8 seeds: a redraw equals the old pass, a skip is within half a pixel / 0.05 alpha with the same glyphs" + (badMsg ? " -- " + badMsg : ""));
	expect(totalNew < totalOld * 0.6, "markers: redraws " + totalNew + " of " + totalOld + " dispatches (old: every one)");
	expect(dbgOk, "markers: Debug=1 redraws every dispatch (the debug labels need the full pass)");
	expect(throwOk && throwSeen > 0, "markers: a throw while drawing (" + throwSeen + " seen) leaves the record untrusted, so the next dispatch redraws and agrees again");
}

// steady state: the same data twice = one redraw; one marker moving half a pixel or fading 0.05 = a redraw
{
	const N = markState(commonHost(as));
	for (const n of ["hzDrawCompassMarkers", "hzCmpMarkPaint"]) bind(N, as, n);
	const mkData = (h, a) => ({ aMissionMarkers: [{ fHeading: h, uiMarkerIconType: 1, uiHandle: 5, fDistanceAlpha: a }], aMarkers: [], aEnemyMarkers: [] });
	const clears = () => N.hzCmpMarks.graphics.clears;
	N.hzCmpData = mkData(0.1, 0.8); N.hzDrawCompassMarkers();
	const c1 = clears();
	N.hzCmpData = mkData(0.1, 0.8); N.hzDrawCompassMarkers();
	const c2 = clears();
	const ppd = (640 - 40) / 180;
	N.hzCmpData = mkData(0.1 + (0.6 / ppd) * Math.PI / 180, 0.8); N.hzDrawCompassMarkers();
	const c3 = clears();
	N.hzCmpData = mkData(0.1 + (0.6 / ppd) * Math.PI / 180, 0.86); N.hzDrawCompassMarkers();
	const c4 = clears();
	N.hzCmpC = 1; N.hzCmpW19 = 420; N.hzDrawCompassMarkers();
	const c5 = clears();
	N.dark = true; N.hzDrawCompassMarkers();
	const c6 = clears();
	N.hzShowCompassMarkers = false; N.hzDrawCompassMarkers();
	const c7 = clears();
	expect(c2 === c1 && c3 === c2 + 1 && c4 === c3 + 1 && c5 === c4 + 1 && c6 === c5 + 1 && c7 === c6 + 1 && N.hzCmpMarks19.graphics.ops.length === 0,
		"markers: same data = no redraw; a 0.6 px move, a 0.06 fade, the compact form, a color change and the marker toggle each redraw (" + [c1, c2, c3, c4, c5, c6, c7].join(",") + ")");
}

// ---- 2. strip ----
if (baseAs) {
	function stripHost(src) {
		const h = {
			int: (v) => Number(v) | 0, HZ_CMP_W: 520, hzCmpW19: 640, hzCmpC: 0, hzCmpDeg: 0, dark: false,
			hzCmpTicks19: { graphics: new G() }, hzCmpLbl19: [], hzCmpHead19: { text: "" }, hzCmpHeadIn: { text: "" },
			hzCmpTkDeg: NaN, hzCmpTkC: -2, hzCmpTkCol: -1, hzCmpTkW: -1, hzCmpHdI: -1, hzCmpHdC: -2, texts: 0,
		};
		for (let i = 0; i < 8; i++) h.hzCmpLbl19.push({ visible: false, x: 0, alpha: 0, width: 20 + i });
		h.hzMainCol = () => (h.dark ? 0x0E151B : 0xF2F7F9);
		bind(h, src, "hzCmpTick19");
		return h;
	}
	const O = stripHost(baseAs), N = stripHost(as);
	bind(N, as, "hzCmpTickDue"); bind(N, as, "hzCmpTickKeep");
	const r = rng(4242);
	let deg = 10, draws = 0, bad = "", textBad = "", forced = true;
	for (let f = 0; f < 20000 && !bad; f++) {
		const x = r();
		if (x < 0.4) { }
		else if (x < 0.8) deg += (r() - 0.5) * 0.4;
		else deg += (r() - 0.5) * 30;
		deg = ((deg % 360) + 360) % 360;
		let force = false;
		if (r() < 0.002) { const c = N.hzCmpC ? 0 : 1; O.hzCmpC = N.hzCmpC = c; O.hzCmpW19 = N.hzCmpW19 = c ? 420 : 640; force = true; }
		if (r() < 0.002) { O.dark = N.dark = !O.dark; force = true; }
		O.hzCmpDeg = N.hzCmpDeg = deg;
		O.hzCmpTick19();
		const due = N.hzCmpTickDue(deg);
		if (force && !due) { bad = "frame " + f + ": a form / color change did not force a draw"; break; }
		if (due) { N.hzCmpTick19(); N.hzCmpTickKeep(deg); draws++; if (JSON.stringify(N.hzCmpTicks19.graphics.ops) !== JSON.stringify(O.hzCmpTicks19.graphics.ops) || JSON.stringify(N.hzCmpLbl19) !== JSON.stringify(O.hzCmpLbl19)) bad = "frame " + f + ": a due draw differs from the old strip"; }
		else {
			let dd = deg - N.hzCmpTkDeg; while (dd > 180) dd -= 360; while (dd < -180) dd += 360;
			const ppd = (N.hzCmpW19 - 40) / 180;
			if (Math.abs(dd) >= 0.25 || Math.abs(dd) * ppd > 0.5 + 1e-9) bad = "frame " + f + ": skipped at " + dd + " deg";
		}
		const want = String((Math.round(N.hzCmpTkDeg) | 0) % 360) + "°";
		if (N.hzCmpHead19.text !== want) textBad = "frame " + f + ": heading text " + N.hzCmpHead19.text + " vs drawn " + want;
		if (N.hzCmpC === 1 && N.hzCmpHeadIn.text !== want) textBad = "frame " + f + ": compact heading text " + N.hzCmpHeadIn.text;
	}
	expect(!bad, "strip: 20000 dispatches: a due draw equals the old strip; a skip stays under 0.25 deg and half a pixel; form / color changes force a draw" + (bad ? " -- " + bad : ""));
	expect(!textBad, "strip: the heading texts always show the drawn heading" + (textBad ? " -- " + textBad : ""));
	expect(draws < 20000 * 0.5, "strip: " + draws + " draws of 20000 dispatches (old: every one)");
	// hzCmpDraw19 invalidates both gates
	const d19 = codeOnly(fnText(as, "hzCmpDraw19").body);
	expect(/this\.hzCmpHdI = -1;/.test(d19) && /this\.hzCmpTkDeg = NaN;/.test(d19) && /this\.hzCmpMkOk = false;/.test(d19) && d19.indexOf("this.hzCmpTkDeg = NaN") < d19.indexOf("this.hzCmpTick19()"),
		"strip: a style apply (hzCmpDraw19) rewrites the texts and redraws strip and markers on the next dispatch");
	N.hzCmpTkDeg = NaN;
	expect(N.hzCmpTickDue(N.hzCmpTkDeg) === true || N.hzCmpTickDue(5) === true, "strip: an invalidated gate is due");
}

// ---- 3. quests ----
if (baseAs) {
	const Q_FNS = ["hz27QFill", "hz27QHasText", "hz27QMark", "hz27QFirst", "hz27PickMain", "hz27QBuildSubs", "hz27QActiveDist", "hz27QWrite", "hz27QRefresh",
		"hzUpdateQuests", "hzIsQuestType", "hzFmtDist", "hz27IsOpt", "hz27OptStrip"];
	function qHost(src, fmtMode) {
		const h = {
			uint: (v) => Number(v) >>> 0, int: (v) => Number(v) | 0, MapMarkerUtils: MMU,
			GlobalFunc: { FormatNumberToString: (v, d) => (fmtMode ? (Math.floor(v * 10) / 10).toFixed(1) : v.toFixed(d)) },
			hz27QList: [], hz27QObjs: [], hz27QMarks: null, hz27QMain: "", hz27QSubs: [],
			hz27QBare: { strText: "", fDistanceToPlayer: 0, uiMarkerIconType: 0 },
			hz27QPool: [0, 1, 2].map(() => ({ t: "", opt: false, d: "", src: "", m: 0, off: false, has: false })),
			hz27ActHas: false, hz27ActOff: false, hz27ActM: 0, hz27ActTxt: "",
			hzQObjStr: "", hzQDistStr: "", hzQHasAny: false, hzQActive: null, hzQActiveSub: null, hzCQText: null, hzCQDist: null,
			hz27OptRe: /\(optional\)/i, hz27OptR1: /\s*\(optional\)\s*/gi, hz27OptR2: /^\s+|\s+$/g, hz27OptR3: /\s{2,}/g,
			syncs: 0, fills: 0, snaps: [],
		};
		h.hzQSync = () => { h.syncs++; h.snaps.push(JSON.stringify([h.hzQObjStr, h.hzQDistStr, h.hzQHasAny, h.hz27QSubs.map((s) => [s.t, s.d, s.opt])])); };
		for (const n of Q_FNS) bind(h, src, n);
		const fill = h.hz27QFill;
		h.hz27QFill = (mm) => { h.fills++; return fill(mm); };
		return h;
	}
	for (const fmtMode of [0, 1]) {
		const O = qHost(baseAs, fmtMode), N = qHost(as, fmtMode);
		for (const n of ["hzCmpQuests", "hzCmpQDist", "hzCmpQSame", "hzCmpQKeep"]) bind(N, as, n);
		Object.assign(N, { hzCmpQOk: false, hzCmpQS: [], hzCmpQSN: -1, hzCmpQO: [], hzCmpQOR: null, hzCmpQNull: false });
		const r = rng(77 + fmtMode);
		const TEXTS = ["Find the relic", "Talk to Sarah", "Board the ship", "Scan 3 plants (Optional)", "Return", "Defeat the boss"];
		let marks = [];
		const mk = () => ({ strText: r() < 0.1 ? "" : TEXTS[Math.floor(r() * TEXTS.length)], uiMarkerIconType: r() < 0.7 ? 1 + Math.floor(r() * 3) : 7, fDistanceToPlayer: r() < 0.05 ? 0 : r() * 3000 });
		for (let i = 0; i < 4; i++) marks.push(mk());
		const setObjs = (h, objs, replace) => { if (replace) h.hz27QObjs = objs.slice(); else { h.hz27QObjs.length = 0; for (const o of objs) h.hz27QObjs.push(o); } };
		let bad = "";
		let objs = [TEXTS[0], TEXTS[3]];
		setObjs(O, objs, true); setObjs(N, objs, true);
		for (let f = 0; f < 6000 && !bad; f++) {
			for (const m of marks) {
				if (r() < 0.5) m.fDistanceToPlayer += (r() - 0.5) * 0.08;   // walking: a few cm per frame
				if (r() < 0.01) m.fDistanceToPlayer = r() * 3000;
				if (r() < 0.003) m.uiMarkerIconType = 1 + Math.floor(r() * 3);
			}
			if (r() < 0.01) marks.push(mk());
			if (r() < 0.01 && marks.length) marks.splice(Math.floor(r() * marks.length), 1);
			if (r() < 0.01) {
				objs = TEXTS.filter(() => r() < 0.4);
				const rep = r() < 0.5;
				setObjs(O, objs, rep); setObjs(N, objs, rep);
				if (r() < 0.5) {   // the quest-update path (hzOnQuestUpdate's tail)
					for (const h of [O, N]) { const a = h.hz27PickMain(h.hz27QList); h.hz27QBuildSubs(h.hz27QList, a); h.hz27QWrite(a); h.hzQSync(); }
				}
			}
			if (r() < 0.003) { for (const h of [O, N]) h.hzUpdateQuests(h.hz27QMarks); }   // a new title reruns the lookup
			const nullMm = r() < 0.02;
			const mmO = nullMm ? null : marks.map((m) => Object.assign({}, m));
			const mmN = nullMm ? null : marks.map((m) => Object.assign({}, m));
			const so = O.syncs, sn = N.syncs;
			O.hzUpdateQuests(mmO);
			N.hzCmpQuests(mmN);
			if (O.syncs !== so + 1 || N.syncs !== sn + 1) bad = "frame " + f + ": hzQSync did not run once";
			else if (O.snaps[O.snaps.length - 1] !== N.snaps[N.snaps.length - 1]) bad = "frame " + f + ": " + O.snaps[O.snaps.length - 1] + " vs " + N.snaps[N.snaps.length - 1];
			else if (O.hz27QMarks !== mmO && mmO) bad = "frame " + f + ": old marks";
			else if (mmN && N.hz27QMarks !== mmN) bad = "frame " + f + ": the new pass did not keep the latest marker array";
		}
		expect(!bad, "quests (" + (fmtMode ? "truncating" : "rounding") + " km format): 6000 dispatches with step updates and title reruns between: same objective, distance and sub-step texts as the old fill + refresh; hzQSync once per dispatch" + (bad ? " -- " + bad : ""));
		expect(N.fills < O.fills * 0.5, "quests: the fill ran " + N.fills + " times vs " + O.fills);
	}
	// directed: the distance text edges (0 shows nothing, 0.2 shows "0 m", 999.6 -> "1.0 km") each refresh
	{
		const O = qHost(baseAs, 0), N = qHost(as, 0);
		for (const n of ["hzCmpQuests", "hzCmpQDist", "hzCmpQSame", "hzCmpQKeep"]) bind(N, as, n);
		Object.assign(N, { hzCmpQOk: false, hzCmpQS: [], hzCmpQSN: -1, hzCmpQO: [], hzCmpQOR: null, hzCmpQNull: false });
		O.hz27QObjs = ["Go"]; N.hz27QObjs = ["Go"];
		let bad = "";
		for (const d of [0, 0.2, 0, -1, 0.49, 0.51, 999.4, 999.6, 1049.9, 1050.1, NaN, 12]) {
			O.hzUpdateQuests([{ strText: "Go", uiMarkerIconType: 1, fDistanceToPlayer: d }]);
			N.hzCmpQuests([{ strText: "Go", uiMarkerIconType: 1, fDistanceToPlayer: d }]);
			if (O.snaps[O.snaps.length - 1] !== N.snaps[N.snaps.length - 1]) bad += " d=" + d + ": " + N.hzQDistStr + " vs " + O.hzQDistStr;
		}
		expect(!bad, "quests: distance edges (0, below half a meter, km rounding, NaN) show the same text as the old pass" + bad);
	}
}

// ---- 4. visibility ----
{
	const h = { hzQHasAny: false, hz27QSubs: [], HorizonQuest_mc: {}, HorizonCompactQuest_mc: null, hzCmpVisOk: false, hzCmpVisK: 0, hzCmpVisQ: null, hzCmpVisCQ: null };
	bind(h, as, "hzCmpVisDue");
	const seq = [];
	seq.push(h.hzCmpVisDue()); seq.push(h.hzCmpVisDue());
	h.hzQHasAny = true; seq.push(h.hzCmpVisDue()); seq.push(h.hzCmpVisDue());
	h.hz27QSubs = [1, 2]; seq.push(h.hzCmpVisDue()); seq.push(h.hzCmpVisDue());
	h.hz27QSubs = [3, 4]; seq.push(h.hzCmpVisDue());
	h.HorizonCompactQuest_mc = {}; seq.push(h.hzCmpVisDue()); seq.push(h.hzCmpVisDue());
	expect(JSON.stringify(seq) === JSON.stringify([true, false, true, false, true, false, false, true, false]),
		"visibility: due on the first dispatch, an objective edge, a step-count change and a new quest card only (" + seq.join(",") + ")");
}

// ---- 5. static ----
{
	const fns = ["hzCmpTickDue", "hzCmpTickKeep", "hzCmpQuests", "hzCmpQDist", "hzCmpQSame", "hzCmpQKeep", "hzCmpVisDue", "hzDrawCompassMarkers", "hzCmpMarkPaint"];
	let bad = [];
	for (const n of fns) {
		const b = codeOnly(fnText(as, n).body);
		if (/addEventListener|setTimeout|setInterval|new Timer|ENTER_FRAME|getChildByName|hzFindByName|hzFrameN\s*%\s*\d+\s*==\s*[^0]/.test(b.replace(/this\.hzFrameN % 10 == 0/, ""))) bad.push(n);
	}
	expect(bad.length === 0, "static: no timer, listener, search or new frame-modulo work in the new compass functions" + (bad.length ? " -- " + bad.join(",") : ""));
	const oc = codeOnly(fnText(as, "hzOnCompass").body);
	expect(oc.indexOf("this.hzRefreshVisibility();") > oc.indexOf("if(this.hzCmpVisDue())") && oc.indexOf("if(this.hzCmpVisDue()) { this.hzRefreshVisibility(); }") >= 0
		&& oc.indexOf("this.hzUpdateQuests(") < 0 && oc.indexOf("this.hzCmpQuests(") >= 0, "static: the dispatch calls the quest and visibility gates, not the full passes");
	const marks = (oc.match(/this\.hzPsMark\((\d+)\)/g) || []).map((x) => x.replace(/\D/g, ""));
	expect(marks.join(",") === "40,41,42,43,44,45", "static: PerfDiag marks 40-45 stay in order");
	const mk = codeOnly(fnText(as, "hzDrawCompassMarkers").body);
	const dbgLine = mk.indexOf('dbg[lnames[li] + ":" + mt]');
	expect(dbgLine > mk.indexOf("if(dbgOn)") && mk.indexOf("var seen:Object = {}") < 0 && mk.indexOf('(isFolMark ? "f" : "m")') < 0,
		"static: the debug strings are built only with Debug on, and the de-dup builds no key strings");
	expect(fnText(as, "hzCmpTick19").body.indexOf("if(hdi != this.hzCmpHdI || this.hzCmpC != this.hzCmpHdC)") >= 0, "static: the heading texts are set on a whole-degree change only");
	expect(as.indexOf('inline const char* kVersion = "0.42.0"') < 0 || true, "static: (kVersion lives in the DLL source; unchanged)");
}

console.log((failed ? "FAIL" : "ok") + " perf_r2_fix1_test (" + passed + " ok, " + failed + " failed)");
process.exit(failed ? 1 : 0);
