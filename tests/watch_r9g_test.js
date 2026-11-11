// v0.44 r9g tests: the scan ghost on a moved vanilla watch, the condition icon rows, and the env alert lines.
// Run: node tests/watch_r9g_test.js   (HZ_AS=<file> runs it against another horizon_block.as, used by the mutants)
// Proves, by running the production AS functions (hz43FoOnAdd, hz45*, hz46Inherit, hz47Sync, hz48*, hz50*) on a model:
//  1. ghost: a raw shape the timeline swaps in at the same depth (no ADDED, same child count) is placed by the sweep the
//     next art ADDED runs, the shapes after it keep the written place (no double move), and the group's own
//     AnimationFinished event places one that nothing else reached; home / unchanged states do no sweep;
//  2. (a) BioConditionBase_mc / EnvConditionBase_mc hide (visible only) on a moved style 1 / 2 watch and come back home;
//  3. (c) the env alert lines and the planet-info bar land on the moved watch in their hold, at any offset and scale;
//     other art (ring, ticks) keeps the r9b record;
//  4. static: edge-only wiring, no search, timer, per-frame call or allocation; the listener pair lives together.
// Author: Moragar. Last modified: 2026-11-11.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");

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
function codeOnly(body) { return body.replace(/\/\/[^\n]*/g, ""); }
function toJs(body) {
	return body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
function constOf(name) {
	const m = as.match(new RegExp("private static const " + name + ":(\\w+)\\s*=\\s*([^;]+);"));
	if (!m) throw new Error("missing const " + name);
	return JSON.parse(m[2].trim());
}
const FNS = ["hz43FoOnAdd", "hz45Art", "hz45Mode", "hz45Put", "hz45Prune", "hz45Sync", "hz46Tick", "hz46TickPut", "hz46Inherit", "hz46TxtScanHide",
	"hz47Sync", "hz48Inv", "hz48ArtRec", "hz48ArtPut", "hz48KPut", "hz48Move", "hz50Sweep", "hz50OnFin", "hz50Line"];
function bindAll(h) {
	const wrap = new Proxy(h, { get(t, k) { return k in t ? t[k] : undefined; }, has(t, k) { return k in t; } });
	for (const n of FNS) {
		let f; try { f = fnText(as, n); } catch (e) { continue; }
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}

// ---- display model (GFx-like: a Shape is not a container; a timeline swap keeps the old piece's matrix) ----
let uid = 0;
function piece(name, x, y, m, kids) {
	const c = { key: ++uid, name: name, visible: true, alpha: 1, x: x, y: y, scaleX: 1, scaleY: 1, parent: null };
	const mm = Object.assign({ a: 1, b: 0, c: 0, d: 1 }, m || {});
	Object.defineProperty(c, "transform", { get: function() { return { matrix: { a: mm.a, b: mm.b, c: mm.c, d: mm.d, tx: c.x, ty: c.y } }; } });
	c.mm = mm;
	if (kids) {
		c.kids = kids.map((k) => ({ name: "", x: k[0], y: k[1], scaleX: 1, scaleY: 1, parent: c }));
		Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; } });
		c.getChildAt = function(i) { return this.kids[i]; };
	}
	return c;
}
function blg() {
	const b = { name: "BottomLeftGroup_mc", kids: [], gets: 0, at: 0, added: [], fin: [] };
	Object.defineProperty(b, "numChildren", { get: function() { return this.kids.length; } });
	b.getChildAt = function(i) { this.at++; return this.kids[i]; };
	b.getChildByName = function(n) { this.gets++; return this.kids.find((k) => k.name === n) || null; };
	b.addEventListener = function(t, f, cap, pri, weak) { (t === "added" ? this.added : this.fin).push({ f: f, pri: pri, weak: weak }); };
	b.removeEventListener = function(t, f) { const L = t === "added" ? "added" : "fin"; this[L] = this[L].filter((l) => l.f !== f); };
	return b;
}
function put(b, c, at) { c.parent = b; if (at === undefined) b.kids.push(c); else { const old = b.kids[at]; if (old) old.parent = null; b.kids[at] = c; } return c; }
function host(style) {
	const h = {
		hzBlg: blg(), hzWatchStyle: style, hz43ScanHid: false, hz44Hid: false, hz43FoMoved: false, hz43FoDx: 0, hz43FoDy: 0, hz43FoSc: 1,
		hz43FoLsn: null, hz43VanN: 1, hz43VanOX: [0], hz43VanOY: [0], hz43VanUXA: [1], hz43VanUYA: [1], hz43VanGot: [0], hz43VanD: [null],
		hz45D: [], hz45HX: [], hz45HY: [], hz45SX: [], hz45SY: [], hz45SM: -1, hz45SDx: 0, hz45SDy: 0, hz45SSc: 1, hz45SB: null, hz45SN: -1,
		hz47D: [null, null, null, null, null], hz47On: false, hz47B: null, hz27BioMine: null, hz43ScanMk: [], hzWlOn: false,
		Event: { ADDED: "added" }, int: (n) => n | 0, isNaN: isNaN, NaN: NaN,
		HZ43_VAN_FOLLOW: constOf("HZ43_VAN_FOLLOW"), HZ46_TXT: constOf("HZ46_TXT"), HZ47_NAMES: constOf("HZ47_NAMES"), HZ48_ART: constOf("HZ48_ART"),
		HZ48_AK: constOf("HZ48_AK"), HZ50_FIN: (as.match(/private static const HZ50_FIN:String = "([^"]+)";/) || [])[1],
		hz43FollowApply: function() {}, puts: 0
	};
	["hz48AN", "hz48AI", "hz48AD", "hz48AX", "hz48AY", "hz48ASX", "hz48ASY", "hz48AWX", "hz48AWY", "hz48AWF", "hz48WX", "hz48WY", "hz48WS"].forEach((f) => { h[f] = []; });
	bindAll(h);
	const p = h.hz45Put; h.hz45Put = function(d, m) { h.puts++; return p(d, m); };
	return h;
}
function move(h, dx, dy, sc) { h.hz43FoDx = dx; h.hz43FoDy = dy; h.hz43FoSc = sc; h.hz43FoMoved = !(dx === 0 && dy === 0 && sc === 1); h.hz45Sync(); }
function added(h, c) { h.hzBlg.added.slice().forEach((l) => l.f({ target: c })); }
function finished(h, target) { h.hzBlg.fin.slice().forEach((l) => l.f({ target: target === undefined ? h.hzBlg : target })); }
const near = (a, b) => Math.abs(a - b) < 0.01;
// where a container's child k is drawn in the group: T + M * child
const gx = (c, k) => c.x + c.mm.a * c.kids[k].x + c.mm.c * c.kids[k].y;
const gy = (c, k) => c.y + c.mm.b * c.kids[k].x + c.mm.d * c.kids[k].y;

// ---- 1. the ghost ----
function ghost(style, withAdd, withFin, env) {
	const h = host(style);
	const ring = put(h.hzBlg, piece("instance1285", 111, 110.6, null, [[0, 0]]));
	move(h, -40, 20, 1);
	const at = h.hzBlg.kids.length;
	const p1287 = put(h.hzBlg, piece("instance1287", 0, 0, null, [[5, 5]]));   // frame 186: MovieClip art, ADDED fires
	added(h, p1287);
	const s = {};
	s[187] = put(h.hzBlg, piece("instance1501", p1287.x, p1287.y), at);        // 187: a raw shape swapped in, no ADDED, matrix kept
	if (env) h.hz45Sync();                                                      // a LocalEnvironmentData dispatch (rare while scanning)
	s[188] = put(h.hzBlg, piece("instance1502", s[187].x, s[187].y), at);
	s[189] = put(h.hzBlg, piece("instance1503", s[188].x, s[188].y), at);
	if (withAdd) { const p1292 = put(h.hzBlg, piece("instance1504", 110.2, 50.15, null, [[0, 0]])); added(h, p1292); }   // 190: Symbol 1292 (layer 36)
	s[190] = put(h.hzBlg, piece("instance1505", s[189].x, s[189].y), at);
	s[191] = put(h.hzBlg, piece("instance1506", s[190].x, s[190].y), at);
	s[192] = put(h.hzBlg, piece("instance1507", s[191].x, s[191].y), at);      // held 192 - 231: what shows for the whole scan
	if (withFin) finished(h);                                                   // 227: stop(); dispatchEvent(ANIMATION_FINISHED)
	return { h: h, s: s, ring: ring };
}
for (const st of [1, 2]) {
	const g = ghost(st, true, true);
	expect(near(g.s[192].x, -40) && near(g.s[192].y, 20), "r9g ghost (style " + st + "): the held band shape stands on the moved watch, not at home");
	const k = g.h.hz45D.indexOf(g.s[192]);
	expect(k >= 0 && g.h.hz45HX[k] === 0 && g.h.hz45HY[k] === 0, "r9g ghost (style " + st + "): its record keeps the native place (hz46Inherit; no 2x / 3x move)");
	expect(g.ring.x === 111 && near(gx(g.ring, 0), 71) && near(gy(g.ring, 0), 130.6), "r9g ghost (style " + st + "): the ring keeps the r9b child move (instance never written)");
	const n = ghost(st, true, false);
	expect(near(n.s[192].x, -40) && near(n.s[192].y, 20), "r9g ghost (style " + st + "): the 190 ADDED sweep alone already carries the band (the later swaps keep the written place)");
	const f = ghost(st, false, true);
	expect(near(f.s[192].x, -40) && near(f.s[192].y, 20), "r9g ghost (style " + st + "): with no art ADDED after the swap, AnimationFinished places it");
	const o = ghost(st, false, false);
	expect(o.s[192].x === 0 && o.s[192].y === 0, "r9g ghost (style " + st + "): the model reproduces the bug when no edge runs after the swap (band left at home)");
	const e = ghost(st, false, false, true);
	expect(near(e.s[192].x, -40) && near(e.s[192].y, 20), "r9g ghost (style " + st + "): a LocalEnvironmentData sync after the swap still sweeps once (the ADDED sweep does not use up the count change)");
}
{
	const g = ghost(1, true, true);
	expect(g.h.hzBlg.fin.length === 1 && g.h.hzBlg.fin[0].weak === true && g.h.hzBlg.fin[0].pri === -1 && g.h.hzBlg.added.length === 1, "r9g: one weak AnimationFinished listener (after the game's own) next to the one ADDED listener");
	const x0 = g.s[192].x; g.s[192].x = 0; finished(g.h, { name: "child" });
	expect(g.s[192].x === 0, "r9g: an AnimationFinished from another target is ignored");
	g.s[192].x = x0;
	move(g.h, 0, 0, 1);
	expect(g.h.hzBlg.fin.length === 0 && g.h.hzBlg.added.length === 0 && g.s[192].x === 0, "r9g: home again = both listeners removed, the band back at its native place");
	const z = host(1); const zr = put(z.hzBlg, piece("instance1285", 111, 110.6, null, [[0, 0]])); z.hz45Sync();
	const p0 = z.puts; const a0 = z.hzBlg.at; z.hz43FoOnAdd({ target: zr });
	expect(z.puts === p0 && z.hzBlg.at === a0, "r9g: an ADDED at home (mode 0) does no put and no sweep");
	const q = ghost(1, true, true); q.h.hz45Sync(); const pq = q.h.puts; const aq = q.h.hzBlg.at;
	for (let i = 0; i < 20; i++) q.h.hz45Sync();
	expect(q.h.puts === pq && q.h.hzBlg.at === aq, "r9g zero stutter: after the one follow-up sweep, 20 repeat syncs with no change do no sweep");
	const s0 = host(0); s0.hz45Sync(); const sr = put(s0.hzBlg, piece("instance1601", 0, 0)); s0.hz43FoOnAdd({ target: sr });
	expect(sr.visible === false, "r9g style 0: art is still hidden on its ADDED (mode 1 sweep)");
	const t3 = host(3); t3.hz45Sync(); const tr = put(t3.hzBlg, piece("instance1602", 0, 0)); t3.hz43FoOnAdd({ target: tr });
	expect(tr.visible === false, "r9g style 3: art hidden as before");
}

// ---- 2. (a) the condition icon rows ----
function icons(h) {
	return ["BioCondition_mc", "EnvCondition_mc", "BioAlertBG_mc", "BioConditionBase_mc", "EnvConditionBase_mc"].map((n) => { const c = put(h.hzBlg, piece(n, 110, 110)); c.alpha = 0.5; return c; });
}
for (const st of [1, 2]) {
	const h = host(st); const ic = icons(h);
	move(h, -40, 20, 1);
	expect(ic.every((c) => c.visible === false && c.alpha === 0.5) && h.hz47D.every((d, i) => d === ic[i]), "r9g (a) style " + st + ": moved = both condition icon rows hidden with the alert icons, visible only, recorded");
	move(h, 0, 0, 1);
	expect(ic.every((c) => c.visible === true) && h.hz47D.every((d) => d === null), "r9g (a) style " + st + ": home = shown again");
	const r = host(st); const ir = icons(r); move(r, -40, 20, 1);
	const e2 = put(r.hzBlg, piece("EnvConditionBase_mc", 109.85, 110.35), r.hzBlg.kids.indexOf(ir[4])); added(r, e2);
	expect(e2.visible === false && r.hz47D[4] === e2, "r9g (a) style " + st + ": a new EnvConditionBase_mc instance is hidden on its ADDED event");
}
for (const st of [0, 3, 4]) { const h = host(st); const ic = icons(h); move(h, -40, 20, 1); expect(ic.every((c) => c.visible === true), "r9g (a) style " + st + ": not touched (Digital / style 0 keep their own rules)"); }
{ const h = host(1); const ic = icons(h); h.hz43ScanHid = true; h.hz45Sync(); expect(ic.every((c) => c.visible === true), "r9g (a): the hold alone (watch home) does not hide them"); }

// ---- 3. (c) the env alert lines and the bar ----
const LINES = [
	{ n: "upper line", m0: { a: 0.64, d: -1 }, p0: [110, 43], m1: { a: 0.9999847412109375, d: -1 }, p1: [109.95, 82.5], kid: [-3, 0] },
	{ n: "lower line", m0: { a: 0.64, d: 1 }, p0: [110, 172.9], m1: { a: 0.9999847412109375, d: 1 }, p1: [109.95, 137.9], kid: [-3, 0] },
	{ n: "bar", m0: { a: 0.7441253662109375, d: 1 }, p0: [111.8, 174.15], m1: { a: 0.802276611328125, d: 1 }, p1: [110.85, 169.15], kid: [0, 0] }
];
for (const L of LINES) for (const [dx, dy, sc] of [[-40, 20, 1], [150, -60, 0.8], [-64.3, 34.85, 1.25]]) {
	const h = host(1); move(h, dx, dy, sc);
	const c = put(h.hzBlg, piece("instance1700", L.p0[0], L.p0[1], L.m0, [L.kid])); added(h, c);   // first key (frame 23 / 185)
	Object.assign(c.mm, L.m1); c.x = L.p1[0]; c.y = L.p1[1];                                        // the timeline reaches the hold
	const ex = L.p1[0] * sc + dx + sc * c.mm.a * L.kid[0], ey = L.p1[1] * sc + dy + sc * c.mm.d * L.kid[1];
	expect(near(gx(c, 0), ex) && near(gy(c, 0), ey) && near(c.kids[0].scaleX, sc), "r9g (c) " + L.n + " at (" + dx + ", " + dy + ", x" + sc + "): in the hold the line lands where the moved watch has it (" + ex.toFixed(2) + ", " + ey.toFixed(2) + ")");
	expect(c.x === L.p1[0] && c.mm.a === L.m1.a, "r9g (c) " + L.n + ": the instance itself is never written (its keys keep playing)");
	move(h, 0, 0, 1);
	expect(c.kids[0].x === L.kid[0] && c.kids[0].y === L.kid[1] && c.kids[0].scaleX === 1, "r9g (c) " + L.n + ": home = the child back at its own place");
}
{
	const h = host(1); move(h, -40, 20, 1);
	const ring = put(h.hzBlg, piece("instance1285", 111, 110.6, null, [[0, 0]])); added(h, ring);
	const tick = put(h.hzBlg, piece("instance23", 87.2, 141.65, { a: 0.000076293945, b: 0.2209, c: -1, d: 0 }, [[0, 0]])); added(h, tick);
	const kr = h.hz45D.indexOf(ring), kt = h.hz45D.indexOf(tick);
	expect(h.hz45HX[kr] === 111 && h.hz45HY[kr] === 110.6 && h.hz48AI[kr * 4] === 1 && h.hz45HX[kt] === 87.2, "r9g (c): the ring and the INFO tick keep the r9b record (not matched as lines)");
	const old = host(1); move(old, -40, 20, 1);
	const L = LINES[0]; const c = put(old.hzBlg, piece("instance1701", L.p0[0], L.p0[1], L.m0, [L.kid])); added(old, c);
	const k = old.hz45D.indexOf(c);
	expect(old.hz45HX[k] === 109.95 && old.hz45HY[k] === 82.5 && near(old.hz48AI[k * 4], 1) && old.hz48AI[k * 4 + 3] === -1, "r9g (c): the upper line's record holds the settled place (109.95, 82.5) and the inverse of (1, -1)");
}

// ---- 4. static ----
expect(/this\.hz45Sync\(\);\s*this\.hz45SN = -2;/.test(codeOnly(fnText(as, "hz50Sweep").body)), "r9g: the sweep leaves the count key open for one more sync");
const sw = codeOnly(fnText(as, "hz50Sweep").body) + codeOnly(fnText(as, "hz50OnFin").body) + codeOnly(fnText(as, "hz50Line").body);
expect(!/getChildByName|getChildAt|numChildren|Timer|setTimeout|setInterval|ENTER_FRAME|enterFrame|new |\[\]|\{\}|while|for\s*\(|\.alpha|\.visible/.test(sw), "r9g: hz50Sweep / hz50OnFin / hz50Line hold no search, timer, loop, allocation, alpha or visible write");
const calls = [...as.matchAll(/this\.hz50Sweep\(\)/g)].map((m) => { const pre = as.slice(0, m.index); const f = [...pre.matchAll(/(?:private|public) function (\w+)\(/g)]; return f[f.length - 1][1]; }).sort().join();
expect(calls === "hz43FoOnAdd,hz50OnFin", "r9g: hz50Sweep is called from the ADDED handler and the AnimationFinished handler only");
const add = codeOnly(fnText(as, "hz43FoOnAdd").body);
expect(/if\(m != 0 && this\.hz45Art\(t\)\)\s*\{\s*this\.hz45Put\(t,m\);\s*this\.hz50Sweep\(\);/.test(add.replace(/ as DisplayObject/g, "")), "r9g: the ADDED sweep runs only for art in a non-native mode, after its own put");
const sync = codeOnly(fnText(as, "hz45Sync").body);
expect((sync.match(/addEventListener\(HZ50_FIN,this\.hz50OnFin,false,-1,true\)/g) || []).length === 1 && (sync.match(/removeEventListener\(HZ50_FIN,this\.hz50OnFin\)/g) || []).length === 2, "r9g: hz45Sync adds the AnimationFinished listener where it adds ADDED, and removes it at both ADDED removes");
expect(/HZ50_FIN:String = "AnimationFinished"/.test(as), "r9g: the event name is the group's ANIMATION_FINISHED value");
const rec = codeOnly(fnText(as, "hz48ArtRec").body);
expect(rec.indexOf("this.hz50Line(k,d)") > rec.indexOf("while(n < c.numChildren)") && rec.indexOf("this.hz50Line(k,d)") < rec.indexOf("this.hz48AN[k] = n"), "r9g: hz50Line runs once per new child-moved art record, inside hz48ArtRec");
for (const fn of ["hzOnFrame", "hz27OnExit", "hz43Frame", "hz43VanHorizon", "hz43VanPlace", "hz43VanLate", "hz43SyncHide", "hz27BioHide", "hz40Frame", "hz44GrpTick", "hz44GrpWant"]) {
	let b = ""; try { b = codeOnly(fnText(as, fn).body); } catch (e) { b = ""; }
	expect(b !== "" && !/hz50/.test(b), "r9g: per-frame function " + fn + " holds no hz50 call");
}
expect(constOf("HZ47_NAMES").join() === "BioCondition_mc,EnvCondition_mc,BioAlertBG_mc,BioConditionBase_mc,EnvConditionBase_mc" && /private var hz47D:Array = \[null,null,null,null,null\];/.test(as), "r9g (a): five hz47 pieces and five record slots");
console.log((failed ? "FAILED " : "all ok ") + "watch_r9g_test: " + passed + " ok, " + failed + " FAIL");
process.exit(failed ? 1 : 0);
