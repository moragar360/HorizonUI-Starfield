// 0.43.4 l2 tests: the HUD MESSAGES card in ARRANGE CARDS and in game.
// Run: node tests/messages_standin_test.js   (HZ_HUD_SRC=<file> / HZ_COMMS_SRC=<file> run it on other sources; the
// mutation check: on the 5eae329 sources it must fail.)
// A) Stand-in round trip: the HUD stand-in (hz31PxSize / hz31PxHome / hz30Anchor / hz30PosStr / hz30Resolve) saves
//    HudMessagesX/Y; the Comms movie (hzcMsgLayout / hzcCardZ / hzcAnchor / hzcMsgHome) reads them back. The real
//    box must be the stand-in box: same size (360x56 x TextScale x HudScale, x1.25 in the large movie) and same spot,
//    for every X anchor (L/C/R) and Y anchor (T/C/B), normal and large movies, HudScale 1 and not 1.
// B) Zero bounce: successive messages of different width and line count (short, long, multi-line), for every anchor,
//    both movies and HudScale 1 / 1.25, on both card paths (linked to a game line, and unlinked). The card's anchored
//    edge (the stand-in's edge) stays fixed; the card grows away from it. No bounds reads, and the saved-spot pass runs
//    only on the content / show edge (zero work on steady frames).
// A centered edge is exact to the half unit (an odd size difference cannot split into whole units).
// Runs the production functions (types stripped). Author: Moragar. Last modified: 2026-11-20.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const read = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const HUD = read(process.env.HZ_HUD_SRC || path.join(root, "actionscript", "horizon_block.as"));
const COMMS = read(process.env.HZ_COMMS_SRC || path.join(root, "actionscript", "comms", "hzc_block.as"));
let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src);
	if (!m) return null;
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
	if (!f) return null;
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (var $1 of ")
		.replace(/var (\w+):[\w*]+/g, "var $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/new (Point|Rectangle)\(/g, "new $1(")
		.replace(/(^|[^.\w"])(HZC?_\w*)\b/g, "$1this.$2");
	return new Function(...params, body);
}
global.Number = Number; global.String = String; global.int = (v) => v | 0;
global.Point = class { constructor(x, y) { this.x = x; this.y = y; } };
global.Rectangle = class { constructor(x, y, w, h) { this.x = x; this.y = y; this.width = w; this.height = h; } get right() { return this.x + this.width; } get bottom() { return this.y + this.height; } };
global.getTimer = () => 0;

const VRS = [new Rectangle(0, 0, 1920, 1080), new Rectangle(0, 0, 2560, 1440)];
const MARGIN = 40;
function hudHost(lrg, ts, hs) {
	const h = { hzTextScale: ts, hzHudScale: hs, hzMargin: MARGIN, HZ_SCALE: lrg ? 1.07 : 1, hz31C: {} };
	for (const n of ["hz31PxSize", "hz31MsgZ", "hz31PxHome", "hz30Anchor", "hz30Resolve", "hz30Inset", "hz27Clamp", "hz27LayM", "hz30PosStr"]) { const f = toJs(HUD, n); if (f) h[n] = f.bind(h); }
	h.hz31Cfg = () => h.hz31C; h.hz27CmpTop = () => 28;
	return h;
}
function commsHost(cfg, lrg, vr) {
	const h = { hzcCfg: Object.assign({ TextScale: 1, HudScale: 1, Margin: MARGIN }, cfg), hzcRxLayer: { x: 0, y: 0 }, hzcRxDbgOn: false, hzcMsgHomeLogged: true,
		HZC_LRG: lrg, hzcRx: [], hzcMsgBox: null, hzcRxDirty: false, bounds: 0, arrRuns: 0, Messages_mc: null };
	h.hzcVis = () => new Rectangle(vr.x, vr.y, vr.width, vr.height);
	for (const n of ["hzcMsgArranged", "hzcRxAnchor", "hzcMsgLayout", "hzcMsgHome", "hzcAnchor", "hzcCardZ", "hzcRxPlace", "hzcRxArrPlace", "hzcRxStack"]) { const f = toJs(COMMS, n); if (f) h[n] = f.bind(h); }
	if (h.hzcRxArrPlace) { const ap = h.hzcRxArrPlace; h.hzcRxArrPlace = () => { h.arrRuns++; ap(); }; }
	h.hzcRxScale = () => 1; h.hzcRxCover = () => {}; h.hzcRxReveal = () => {};
	h.hzcRxShow = (e) => { if (e && e.c) e.c.visible = false; };
	h.hzcRxDraw = (e) => { if (!e.c) e.c = { x: 0, y: 0, visible: false, alpha: 0 }; e.w = e.size[0]; e.h = e.size[1]; };
	h.globalToLocal = (p) => new Point(p.x - h.hzcRxLayer.x, p.y - h.hzcRxLayer.y);
	return h;
}
// the tail of hzcRxStep (pinned below): the saved-spot pass on an edge, else the old stack
function stepTail(h) {
	if (h.hzcRxArrPlace && h.hzcMsgBox != null) { if (h.hzcRxDirty) h.hzcRxArrPlace(); }
	else if (h.hzcRxStack) h.hzcRxStack();
}
const msgCol = (h) => ({ alpha: 1, getBounds() { h.bounds++; return new Rectangle(1500, 75, 360, 120); } });
// a game line: right edge and vertical middle as the game draws them (they move a little per line, like the game)
function gameLine(bx, by, bw, bh) {
	const bg = { x: 0, y: 0, width: bw, height: bh };
	const im = { alpha: 1, Background_mc: bg, localToGlobal: (p) => new Point(bx + p.x, by + p.y) };
	return { alpha: 1, Internal_mc: im };
}

const SCALES = [1, 1.25];
const TSS = [1, 1.15];
let combos = 0;
// ---- A) stand-in round trip ----
for (const vr of VRS) for (const lrg of [false, true]) for (const hs of SCALES) for (const ts of TSS) {
	const hud = hudHost(lrg, ts, hs);
	const sz = hud.hz31PxSize("HudMessages");
	const z = Math.min(2.2, Math.max(0.75, ts * hs * (lrg ? 1.25 : 1)));
	expect(sz.x === Math.max(280, Math.round(360 * z)) && sz.y === Math.round(56 * z), `stand-in ${vr.width} lrg=${lrg} hs=${hs} ts=${ts}: ${sz.x}x${sz.y} is the Comms box 360x56 x ${z.toFixed(4)}`);
	const tl = new Point(vr.x, vr.y), br = new Point(vr.right, vr.bottom);
	const home = hud.hz31PxHome("HudMessages", tl, br);
	const xsPos = { L: tl.x + 130, C: Math.round((tl.x + br.x) / 2 - sz.x / 2) + 24, R: br.x - sz.x - 210 };
	const ysPos = { T: tl.y + 70, C: Math.round((tl.y + br.y) / 2 - sz.y / 2) - 18, B: br.y - sz.y - 150 };
	for (const ax of ["L", "C", "R"]) for (const ay of ["T", "C", "B"]) {
		combos++;
		const px = xsPos[ax], py = ysPos[ay];
		const lo = {};
		hud.hz30Anchor("HudMessages", lo, px, py, sz.x, sz.y, tl, br, true, true);
		const xs = hud.hz30PosStr(lo, "x"), ys = hud.hz30PosStr(lo, "y");
		const at0 = hud.hz30Resolve("HudMessages", lo, sz.x, sz.y, tl, br);
		// the stand-in is drawn by hzPlace (whole units at ScreenHeight 1080): that is the spot the player saw
		const at = new Point(Math.round(at0.x), Math.round(at0.y));
		const tag = `${vr.width} lrg=${lrg} hs=${hs} ts=${ts} ${xs}/${ys}`;
		expect(lo.ax === ax && lo.ay === ay && Math.abs(at.x - px) <= 1 && Math.abs(at.y - py) <= 1, `${tag}: the stand-in saves ${ax}${ay} and resolves back to ${px},${py} (${at.x},${at.y})`);
		const h = commsHost({ HudMessagesX: xs, HudMessagesY: ys, TextScale: ts, HudScale: hs }, lrg, vr);
		h.hzcMsgLayout();
		const m = msgCol(h);
		const sx = at.x, sy = at.y;
		// a card the size of the box sits exactly on the stand-in
		const e = { st: 1, it: null, linked: false, k: "", n: "box", size: [sz.x, sz.y], sig: "" };
		h.hzcRx = [e];
		h.hzcRxPlace(e, true, m, true);
		stepTail(h);
		const gx = h.hzcRxLayer.x + e.c.x, gy = h.hzcRxLayer.y + e.c.y;
		expect(gx === sx && gy === sy, `${tag}: the real card (box size) lands on the stand-in: ${gx},${gy} vs ${sx},${sy}`);
		// any card keeps the stand-in's anchored edge
		const e2 = { st: 1, it: null, linked: false, k: "", n: "short", size: [Math.round(sz.x * 0.6), Math.round(sz.y * 0.8)], sig: "" };
		h.hzcRx = [e2];
		h.hzcRxPlace(e2, true, m, true);
		stepTail(h);
		const ex = h.hzcRxLayer.x + e2.c.x, ey = h.hzcRxLayer.y + e2.c.y;
		const okX = ax === "L" ? ex === sx : ax === "R" ? ex + e2.w === sx + sz.x : Math.abs(ex + e2.w / 2 - (sx + sz.x / 2)) <= 0.5;
		const okY = ay === "T" ? ey === sy : ay === "B" ? ey + e2.h === sy + sz.y : Math.abs(ey + e2.h / 2 - (sy + sz.y / 2)) <= 0.5;
		expect(okX && okY, `${tag}: a smaller card keeps the stand-in's ${ax}/${ay} edge (${ex},${ey} ${e2.w}x${e2.h} in ${sx},${sy} ${sz.x}x${sz.y})`);
		expect(h.bounds === 0, `${tag}: no bounds read`);
	}
	// the default spot (0/0, unsaved) is the same home on both sides
	const hc = commsHost({ HudMessagesX: "-1", HudMessagesY: "-1", TextScale: ts, HudScale: hs }, lrg, vr);
	const hh = hc.hzcMsgHome(vr, sz.x, sz.y);
	expect(hh.x === home.x && hh.y === home.y, `${vr.width} lrg=${lrg} hs=${hs} ts=${ts}: same default home ${home.x},${home.y}`);
}

// ---- B) zero bounce across successive messages ----
const MSGS = [["short", 0.55, 1], ["long", 1.0, 1], ["multi-line", 0.92, 2.1], ["short 2", 0.62, 1], ["two lines", 0.8, 1.6], ["long 2", 0.97, 1]];
const SAVED = { L: "L180", C: "C-40", R: "R120", T: "T90", CY: "C30", B: "B140" };
for (const vr of [VRS[0]]) for (const lrg of [false, true]) for (const hs of SCALES) for (const ax of ["L", "C", "R"]) for (const ay of ["T", "C", "B"]) for (const linked of [false, true]) {
	const ts = 1;
	const xs = SAVED[ax], ys = ay === "C" ? SAVED.CY : SAVED[ay];
	const tag = `bounce lrg=${lrg} hs=${hs} ${xs}/${ys} ${linked ? "linked" : "unlinked"}`;
	const hud = hudHost(lrg, ts, hs);
	const sz = hud.hz31PxSize("HudMessages");
	const lo = { ax: ax, dx: Number(xs.slice(1)), ay: ay, dy: Number(ys.slice(1)), nx: true, ny: true };
	const at0 = hud.hz30Resolve("HudMessages", lo, sz.x, sz.y, new Point(vr.x, vr.y), new Point(vr.right, vr.bottom));
	const at = new Point(Math.round(at0.x), Math.round(at0.y));   // hzPlace, ScreenHeight 1080
	const edgeWant = { x: ax === "L" ? at.x : ax === "R" ? at.x + sz.x : at.x + sz.x / 2, y: ay === "T" ? at.y : ay === "B" ? at.y + sz.y : at.y + sz.y / 2 };
	const h = commsHost({ HudMessagesX: xs, HudMessagesY: ys, TextScale: ts, HudScale: hs }, lrg, vr);
	const m = msgCol(h);
	const z = h.hzcCardZ();
	const edges = [];
	let i = 0;
	for (const [name, wf, hf] of MSGS) {
		const w = Math.round(360 * z * wf), hh = Math.round(48 * z * hf);
		// the game's line for this message: its width and height follow the text, its right edge wobbles a little
		const it = linked ? gameLine(1500 + (i % 2) * 6, 90 + (i % 3) * 4, 320 * wf, 40 * hf) : null;
		const e = { st: 1, it: it, linked: linked, k: "", n: name, size: [w, hh], sig: "" };
		h.hzcRx = [e];
		h.hzcMsgLayout();
		h.hzcRxDirty = h.hzcRxDirty || i > 0;   // the previous card ended (hzcRxStep: the card list changed)
		h.hzcRxPlace(e, true, m, true);
		stepTail(h);
		const gx = h.hzcRxLayer.x + e.c.x, gy = h.hzcRxLayer.y + e.c.y;
		edges.push({ name, x: ax === "L" ? gx : ax === "R" ? gx + w : gx + w / 2, y: ay === "T" ? gy : ay === "B" ? gy + hh : gy + hh / 2 });
		// steady frames: no new placement work, nothing moves
		const runs = h.arrRuns, px0 = e.c.x, py0 = e.c.y;
		for (let f = 0; f < 3; f++) { h.hzcMsgLayout(); h.hzcRxPlace(e, true, m, true); stepTail(h); }
		expect(h.arrRuns === runs && e.c.x === px0 && e.c.y === py0, `${tag} ${name}: steady frames run no placement pass and do not move the card`);
		i++;
	}
	const tolX = ax === "C" ? 0.5 : 0, tolY = ay === "C" ? 0.5 : 0;
	const bx = Math.max(...edges.map((q) => Math.abs(q.x - edgeWant.x))), by = Math.max(...edges.map((q) => Math.abs(q.y - edgeWant.y)));
	expect(bx <= tolX, `${tag}: the ${ax} edge stays on the stand-in edge ${edgeWant.x} (bounce ${bx}: ${edges.map((q) => q.x).join(",")})`);
	expect(by <= tolY, `${tag}: the ${ay} edge stays on the stand-in edge ${edgeWant.y} (bounce ${by}: ${edges.map((q) => q.y).join(",")})`);
	expect(h.bounds === 0, `${tag}: no bounds read`);
	combos++;
}

// ---- stacked cards grow away from the anchored edge ----
for (const ay of ["T", "B"]) {
	const vr = VRS[0];
	const h = commsHost({ HudMessagesX: "R40", HudMessagesY: ay + "60" }, false, vr);
	const m = msgCol(h);
	h.hzcMsgLayout();
	const a = { st: 1, it: null, linked: false, k: "", n: "older", size: [300, 48], sig: "" };
	const b = { st: 1, it: null, linked: false, k: "", n: "newer", size: [250, 90], sig: "" };
	h.hzcRx = [a, b];
	h.hzcRxPlace(a, false, m, true); h.hzcRxPlace(b, true, m, true); stepTail(h);
	const box = h.hzcMsgBox || { x: NaN, y: NaN, w: NaN, h: NaN };
	if (ay === "T") expect(a.c.y === box.y && b.c.y === box.y + 48 + 8 && a.c.x + 300 === box.x + box.w && b.c.x + 250 === box.x + box.w, "T anchor: the oldest card holds the top edge, newer cards stack down");
	else expect(b.c.y + 90 === box.y + box.h && a.c.y + 48 + 8 === b.c.y, "B anchor: the newest card holds the bottom edge, older cards stack up");
}

// ---- source pins: edge-only, no bounds read, one comms block ----
const step = fnText(COMMS, "hzcRxStep");
expect(step && /if\(this\.hzcMsgBox != null\) \{ if\(this\.hzcRxDirty\) \{ try \{ this\.hzcRxArrPlace\(\); \}/.test(step.body), "hzcRxStep runs the saved-spot pass only when dirty");
expect(step && /if\(keep\.length != this\.hzcRx\.length\) \{ this\.hzcRxDirty = true; \}/.test(step.body), "a card added or ended is an edge");
const ap = fnText(COMMS, "hzcRxArrPlace");
expect(ap && ap.body.indexOf("getBounds") < 0 && ap.body.indexOf("localToGlobal") < 0, "the saved-spot pass reads no bounds");
const cnt = (s, t) => s.split(t).length - 1;
expect(cnt(COMMS, "getBounds(") === 2 && cnt(COMMS, "ENTER_FRAME") === 6 && cnt(COMMS, "new Timer(") <= 1, "Comms getBounds / ENTER_FRAME / Timer counts unchanged (2 / 6 / 1)");
for (const d of ["imp", "imp-Lrg"]) {
	const f = path.join(root, "actionscript", "imp", d, "scripts", "HUDMessagesMenu.as");
	if (!fs.existsSync(f) || process.env.HZ_COMMS_SRC) continue;
	const blk = COMMS.replace("__HZC_LRG__", d === "imp-Lrg" ? "true" : "false");
	expect(read(f).indexOf(blk) >= 0, d + "/HUDMessagesMenu.as carries the Comms block verbatim");
}
console.log("messages stand-in: " + combos + " combinations, " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
