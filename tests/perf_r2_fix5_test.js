// perf round 2 Fix 5 tests: the hover card (hzT19Tick) re-reads the prompt only on an edge.
// Run: node tests/perf_r2_fix5_test.js   (HZ_AS=<file> runs it against another horizon_block.as; HZ_BASE=<rev> picks the old bodies)
// Before: every tick read the 4 button clips about 24 times, the 12 key / label texts, walked the whole vanilla prompt
// tree to re-hide it, and built a new Rectangle and two Points for the visible screen rect.
// Proves, by running the production AS (types stripped) next to the base bodies:
//  1. hzT19BtnClip: inside a tick it returns exactly what the plain read returns, for random button swaps;
//  2. hide: over random frames (vanilla timelines resetting alpha, pieces swapped in place, children added / removed,
//     button clips swapped, hzTgHidden restored, ObjectRing changes, hover edges) hz38HideVanilla leaves every piece with
//     the same alpha / visible and the same hzTgHidden entries as the old walk, while walking far less;
//  3. labels: the 12 reads equal the old per-frame reads whenever the game changes a label within 2 frames of new prompt
//     data, a uMode / show / controller change or a clip swap; a change with no edge is the stated risk (counted);
//  4. edges: hzT19Edge is due on the edge frame and the 2 after it; a skipped tick, hzVehPad, aw and uMode changes
//     and hzOnTgAct payload changes are edges;
//  5. hzVis: the same rect as the old body for random visible rects and transforms, one shared object while unchanged;
//  6. static: no timer, listener or search in the new functions; the loot card red bar code is untouched.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const BASE = process.env.HZ_BASE || "ff4c33f";
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");
const gitBase = require("./lib/git_base.js");
const baseRes = gitBase.readBase(root, BASE);   // S-1b: SKIP only without a repository or in a shallow clone
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
		.replace(/([\w.\[\]]+) is DisplayObjectContainer\b/g, "isCont($1)")
		.replace(/([\w.\[\]]+) is TextField\b/g, "isText($1)")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "")
		.replace(/p != this\b/g, "p != this.__top");
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

// ---- display model: named children are reachable as properties (timeline instance vars follow the placed instance) ----
let uid = 0;
function Clip(name, cont) {
	const c = { key: ++uid, name: name, visible: true, alpha: 1, parent: null, kids: cont ? [] : null, isText: false, text: "" };
	if (cont) {
		Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; } });
		c.getChildAt = function(i) { return this.kids[i]; };
	}
	return c;
}
function add(p, c, at) {
	c.parent = p;
	if (at === undefined) p.kids.push(c); else p.kids.splice(at, 0, c);
	if (!Object.getOwnPropertyDescriptor(p, c.name)) Object.defineProperty(p, c.name, { configurable: true, get: function() { return this.kids.find((k) => k.name === c.name) || null; } });
	return c;
}
function removeAt(p, i) { const c = p.kids.splice(i, 1)[0]; c.parent = null; return c; }

// button: Label_mc.LabelInstance_mc.Label_tf, HoldLabel_mc..., PCButton_mc.ButtonInstance_mc.PCButton_tf, ConsoleButton_mc..., HoldMeter_mc, art
function Button(name, r) {
	const b = Clip(name, true);
	const lm = add(b, Clip("Label_mc", true)), li = add(lm, Clip("LabelInstance_mc", true)), lt = add(li, Clip("Label_tf")); lt.isText = true; lt.text = "Take";
	const hm = add(b, Clip("HoldLabel_mc", true)), hi = add(hm, Clip("LabelInstance_mc", true)), ht = add(hi, Clip("Label_tf")); ht.isText = true; ht.text = "Hold";
	const pc = add(b, Clip("PCButton_mc", true)), pi = add(pc, Clip("ButtonInstance_mc", true)), pt = add(pi, Clip("PCButton_tf")); pt.isText = true; pt.text = "e";
	const cb = add(b, Clip("ConsoleButton_mc", true)); add(cb, Clip("ButtonInstance_mc", true)).visible = false;
	add(b, Clip("HoldMeter_mc"));
	if (r() < 0.5) add(b, Clip("Bg_mc"));
	return b;
}
function buildWidget(seed) {
	const r = rng(seed);
	const top = Clip("top", true);
	const rw = add(top, Clip("RolloverWidget_mc", true));
	add(rw, Clip("Reticle_mc", true));
	add(rw, Clip("lead0")); add(rw, Clip("lead1"));
	const hd = add(rw, Clip("RolloverActivationHolder_mc", true));
	const aw = add(hd, Clip("RolloverActivation_mc", true));
	add(aw, Clip("Header_mc", true)); add(aw, Clip("ContainerList_mc", true));
	const bars = add(aw, Clip("ButtonBars_mc", true));
	const tb = add(bars, Clip("TopButtonBar_mc", true)), bb = add(bars, Clip("BottomButtonBar_mc", true));
	add(tb, Button("Button1_mc", r)); add(tb, Button("Button2_mc", r)); add(bb, Button("Button1_mc", r)); add(bb, Button("Button2_mc", r));
	const n = 2 + Math.floor(r() * 4);
	for (let i = 0; i < n; i++) { const c = add(aw, Clip("art" + i, r() < 0.4)); if (c.kids) add(c, Clip("deep" + i)); }
	if (r() < 0.5) add(hd, Clip("holderArt"));
	return { top, rw, hd, aw, bars, tb, bb };
}
function allNodes(c, out) { out.push(c); if (c.kids) for (const k of c.kids) allNodes(k, out); return out; }

const HIDE_FN = ["hz38HideVanilla", "hzT19HoldBtns", "hzT19AncFill", "hzT19HidePromptTree", "hzT19HideBtnArt", "hzT19IsHoldBtn", "hzT19OnHoldPath", "hzT19OnHoldPathA",
	"hzT19HoldMeterName", "hzT19HideA", "hzT19KeepHold", "hzT19HideReticle", "hzT19ShowReticle", "hzT19BtnClip", "hzTgRestore"];
const NEW_FN = ["hzT19BtnRaw", "hzT19BtnSync", "hzT19Edge", "hzT19HcOk", "hzT19HcApply", "hzT19HcBox", "hzT19LblKeep", "hzT19LblUse"];
function host(src, W, isNew) {
	const h = {
		isCont: (d) => !!(d && d.kids), isText: (d) => !!(d && d.isText), int: (n) => (Number(n) | 0), uint: (n) => Number(n) >>> 0,
		DisplayObject: (d) => d, DisplayObjectContainer: (d) => d, Number: Number, String: String, Math: Math, Boolean: Boolean, Array: Array,
		__top: null, RolloverWidget_mc: W.rw, hzTgHidden: [], hzTgHidA: [], hzT19Anc: [], hzT19AncB: null, hzT19HoldB: null, hzObjRing: 0,
		hzFrameN: 1, hzVehPad: 0, walks: 0
	};
	if (isNew) Object.assign(h, { hzT19Bc: null, hzT19BcAw: null, hzT19BcF: -1, hzT19EdAw: null, hzT19EdShow: false, hzT19EdM: -2, hzT19EdPad: -2, hzT19EdF: -10, hzT19EdDecF: -10,
		hzT19EdgeN: 3, hzT19WalkSkip: 0, hzT19LblDue: true, hzT19LblC: null, hzT19HcDue: true, hzT19HcRec: false, hzT19HcValid: false, hzT19HcAw: null, hzT19HcHd: null, hzT19HcArr: null,
		hzT19HcLen: -1, hzT19HcBtn: null, hzT19HcD: [], hzT19HcP: [], hzT19HcDN: 0, hzT19HcB: [], hzT19HcBK: [], hzT19HcBP: [], hzT19HcBN: 0 });
	for (const f of HIDE_FN) bind(h, src, f);
	if (isNew) for (const f of NEW_FN) bind(h, src, f);
	const walk = h.hzT19HidePromptTree;
	h.hzT19HidePromptTree = function(box, b) { if (box === W.hd) h.walks++; return walk(box, b); };   // one count per hz38HideVanilla walk (the holder pass)
	return h;
}
function stateOf(W, h) {
	return allNodes(W.top, []).map((c) => c.key + ":" + c.visible + ":" + c.alpha).join("|") + "#" +
		h.hzTgHidden.map((o) => o.d.key + "/" + o.v + "/" + o.a).sort().join(",");
}
function twin(seed) { const save = uid; const A = buildWidget(seed); const keysA = allNodes(A.top, []).map((c) => c.key); uid = save; const B = buildWidget(seed); uid = Math.max(uid, keysA[keysA.length - 1]); return [A, B]; }
// the same mutation on both trees (pieces addressed by path)
function pathOf(c) { const p = []; while (c.parent) { p.unshift(c.parent.kids.indexOf(c)); c = c.parent; } return p; }
function at(W, p) { let c = W.top; for (const i of p) c = c.kids[i]; return c; }

// ---- 1. hzT19BtnClip in a tick = the plain read ----
{
	const r = rng(51);
	const W = buildWidget(5);
	const h = host(as, W, true);
	let bad = 0, calls = 0;
	for (let f = 2; f < 400; f++) {
		h.hzFrameN = f;
		if (r() < 0.1) { const bar = r() < 0.5 ? W.tb : W.bb; const i = Math.floor(r() * 2); const old = removeAt(bar, i); add(bar, Button(old.name, r), i); }
		if (r() < 0.03) { const i = W.bars.kids.indexOf(W.tb); const old = removeAt(W.bars, i); const nb = add(W.bars, Clip("TopButtonBar_mc", true), i); add(nb, Button("Button1_mc", r)); add(nb, Button("Button2_mc", r)); W.tb = nb; }
		const rb = h.hzT19BtnSync(W.aw);
		for (let t = 0; t < 4; t++) { calls++; if (h.hzT19BtnClip(W.aw, t) !== h.hzT19BtnRaw(W.aw, t)) bad++; }
		if (rb !== true && rb !== false) bad++;
	}
	expect(bad === 0, "hzT19BtnClip after hzT19BtnSync returns the plain read in every tick (" + calls + " calls, swaps of buttons and a whole bar)");
	const other = buildWidget(6);
	expect(h.hzT19BtnClip(other.aw, 0) === h.hzT19BtnRaw(other.aw, 0) && h.hzT19BtnClip(W.aw, 7) === null, "another aw, or an out-of-range type, takes the plain read");
	h.hzFrameN++;
	{   // a later frame before this frame's sync: the plain read, not last frame's clip
		const old = removeAt(W.tb, 1); const nb = add(W.tb, Button(old.name, r), 1);
		expect(h.hzT19BtnClip(W.aw, 0) === nb && h.hzT19BtnClip(W.aw, 0) === h.hzT19BtnRaw(W.aw, 0), "a new frame before hzT19BtnSync: hzT19BtnClip takes the plain read (the cache is for this frame only)");
	}
	h.hzT19BtnSync(W.aw); h.hzFrameN++;
	const keep = h.hzT19Bc[0];
	expect(h.hzT19BtnSync(W.aw) === false && h.hzT19Bc[0] === keep, "no swap: no rebuild edge");
}

// ---- 2. hide: same writes as the old walk ----
const KEEP = /^(RolloverActivation_mc|RolloverActivationHolder_mc|ButtonBars_mc|TopButtonBar_mc|BottomButtonBar_mc|Button[12]_mc)$/;   // the widget skeleton stays (swaps of the buttons are their own case)
if (!baseAs) gitBase.report(baseRes, BASE, "old-vs-new hide walk checks", expect);
else {
	let walksOld = 0, walksNew = 0, frames = 0, worst = "";
	for (let seed = 1; seed <= 30 && !worst; seed++) {
		const [A, B] = twin(seed * 7);
		const O = host(baseAs, A, false), N = host(as, B, true);
		const r = rng(seed);
		for (let f = 2; f < 300 && !worst; f++) {
			O.hzFrameN = N.hzFrameN = f;
			const q = r();
			let edge = false;
			const nodesA = allNodes(A.aw, []).concat(allNodes(A.hd, []));
			const pick = () => pathOf(nodesA[Math.floor(r() * nodesA.length)]);
			if (q < 0.3) { for (let k = 0; k < 3; k++) { const p = pick(); at(A, p).alpha = at(B, p).alpha = 1; } }   // vanilla timelines reset alpha
			else if (q < 0.36) {   // a piece swapped in place (same name, same index, same count)
				const p = pick(); const ca = at(A, p);
				if (ca.parent && !KEEP.test(ca.name)) {
					const pa = ca.parent, pb = at(B, p).parent, i = pa.kids.indexOf(ca);
					removeAt(pa, i); removeAt(pb, i);
					const k0 = ++uid; const na = Clip(ca.name, false), nb = Clip(ca.name, false); na.key = nb.key = k0;
					add(pa, na, i); add(pb, nb, i);
				}
			} else if (q < 0.40) {   // a child added
				const p = pick(); const ca = at(A, p), cb = at(B, p);
				if (ca.kids) { const k0 = ++uid; const na = Clip("new" + k0), nb = Clip("new" + k0); na.key = nb.key = k0; add(ca, na); add(cb, nb); }
			} else if (q < 0.43) {   // a child removed
				const p = pick(); const ca = at(A, p), cb = at(B, p);
				if (ca.kids && ca.kids.length > 0 && ca !== A.bars) { const i = Math.floor(r() * ca.kids.length); if (!KEEP.test(ca.kids[i].name)) { removeAt(ca, i); removeAt(cb, i); } }
			} else if (q < 0.46) {   // a button clip swapped
				const which = r() < 0.5 ? "tb" : "bb", i = Math.floor(r() * 2), s0 = Math.floor(r() * 1e6);
				const oa = removeAt(A[which], i), ob = removeAt(B[which], i);
				const save = uid; const na = Button(oa.name, rng(s0)); const ka = allNodes(na, []).map((c) => c.key); uid = save; const nb = Button(ob.name, rng(s0)); uid = Math.max(uid, ka[ka.length - 1]);
				add(A[which], na, i); add(B[which], nb, i);
			} else if (q < 0.48) { O.hzTgRestore(); N.hzTgRestore(); }
			else if (q < 0.50) { O.hzObjRing = N.hzObjRing = Math.floor(r() * 3); }
			else if (q < 0.53) { edge = true; }
			if (edge) N.hzT19EdgeN = 3;   // hzOnTgAct with new prompt data
			const rb = N.hzT19BtnSync(B.aw);
			N.hzT19Edge(B.aw, true, 0, rb);
			let eo = null, en = null;
			try { O.hz38HideVanilla(A.rw, A.aw, "item"); } catch (e) { eo = e; }
			try { N.hz38HideVanilla(B.rw, B.aw, "item"); } catch (e) { en = e; }
			frames++;
			if (eo || en) { worst = "seed " + seed + " frame " + f + " threw: " + (eo || en); break; }
			const sa = stateOf(A, O), sb = stateOf(B, N);
			if (sa !== sb) worst = "seed " + seed + " frame " + f + " q=" + q.toFixed(3);
		}
		walksOld += O.walks; walksNew += N.walks;
	}
	expect(!worst, "hide: 30 seeds x 300 frames (alpha resets, in-place swaps, adds, removes, button swaps, restores, ObjectRing, edges): same alpha / visible and hzTgHidden as the old walk every frame" + (worst ? " -- " + worst : ""));
	expect(walksNew * 2 < walksOld, "hide: the prompt walk ran " + walksNew + " times vs " + walksOld + " over " + frames + " frames");
	// steady hover: one walk per edge window, then none
	const [A, B] = twin(901);
	const N = host(as, B, true);
	for (let f = 2; f < 200; f++) { N.hzFrameN = f; N.hzT19Edge(B.aw, true, 0, N.hzT19BtnSync(B.aw)); N.hz38HideVanilla(B.rw, B.aw, "item"); if (f % 3 === 0) for (const c of allNodes(B.aw, [])) c.alpha = 1; }
	const pieces = allNodes(B.aw, []).filter((c) => N.hzT19HcD.slice(0, N.hzT19HcDN).indexOf(c) >= 0);
	expect(N.walks === 3 && pieces.every((c) => c.alpha === 0), "steady hover with the timeline resetting alpha every 3rd frame: 3 walks (the edge window), every recorded piece back at alpha 0 (walks=" + N.walks + ")");
	// throw inside the walk: not cached
	const N2 = host(as, B, true);
	N2.hzFrameN = 500; N2.hzT19Edge(B.aw, true, 0, N2.hzT19BtnSync(B.aw));
	const hp = N2.hzT19HoldMeterName; let thr = true;
	N2.hzT19HoldMeterName = function(n) { if (thr) { thr = false; throw new Error("x"); } return hp(n); };
	N2.hz38HideVanilla(B.rw, B.aw, "item");
	expect(N2.hzT19HcValid === false, "a throw inside the walk leaves the record invalid (the next frame walks again)");
	N2.hzT19HoldMeterName = hp;
	// a throw in the holder part of the walk (the second holder read throws)
	const N3 = host(as, B, true);
	N3.hzFrameN = 600; N3.hzT19Edge(B.aw, true, 0, N3.hzT19BtnSync(B.aw));
	let reads = 0;
	const rwT = { get RolloverActivationHolder_mc() { if (++reads === 2) throw new Error("y"); return B.hd; }, Reticle_mc: null, numChildren: 0, getChildAt: () => null };
	N3.hz38HideVanilla(rwT, B.aw, "item");
	expect(reads === 2 && N3.hzT19HcValid === false, "a throw in the holder part of the walk leaves the record invalid too");
	// hzTgHidden restored and refilled to the same length by other hides: the walk runs again
	const N4 = host(as, B, true);
	for (let f = 700; f < 704; f++) { N4.hzFrameN = f; N4.hzT19Edge(B.aw, true, 0, N4.hzT19BtnSync(B.aw)); N4.hz38HideVanilla(B.rw, B.aw, "item"); }
	const len = N4.hzTgHidden.length, w0 = N4.walks;
	N4.hzTgRestore();
	for (let k = 0; k < len; k++) N4.hzTgHidden.push({ d: Clip("other" + k), v: true, a: 1 });
	N4.hzFrameN = 704; N4.hzT19Edge(B.aw, true, 0, N4.hzT19BtnSync(B.aw)); N4.hz38HideVanilla(B.rw, B.aw, "item");
	expect(N4.walks === w0 + 1, "hzTgHidden restored (a new array) then refilled to the same length elsewhere: the walk runs again (its entries are gone)");
}

// ---- 3. labels ----
if (baseAs) {
	const snip = (src) => {
		const t = fnText(src, "hzT19Tick").body;
		const i0 = t.indexOf("var rw0:Array = this.hzT19Raw;"), i1 = t.indexOf("var stealSig");
		return toJs(t.slice(i0, i1));
	};
	const mk = (src, isNew, W) => {
		const h = host(src, W, isNew);
		Object.assign(h, { hzT19Raw: null, HZ_T19_RAWN: 64 });
		for (const f of ["hzT19Key", "hzT19VanLbl", "hzT19Trim"]) bind(h, src, f);
		h.read = Function("show", "aw", "with(this){\n" + snip(src) + "\nreturn rw0.slice(0,12).join('|');\n}").bind(h);
		return h;
	};
	const W = buildWidget(77);
	const O = mk(baseAs, false, W), N = mk(as, true, W);
	const r = rng(78);
	let same = 0, stale = 0, other = 0, frames = 0, reads = 0, staleOpen = false;
	let pending = [];   // label writes the game makes 0-2 frames after an edge
	let m = 0;
	const btns = () => [W.tb.Button2_mc, W.tb.Button1_mc, W.bb.Button2_mc, W.bb.Button1_mc];
	for (let f = 2; f < 6000; f++) {
		O.hzFrameN = N.hzFrameN = f;
		const q = r();
		let noEdge = false;
		if (q < 0.03) {   // new prompt data: labels follow within 2 frames
			N.hzT19EdgeN = 3;
			const d = Math.floor(r() * 3), t = Math.floor(r() * 4), txt = "L" + Math.floor(r() * 50);
			pending.push({ f: f + d, run: () => { const b = btns()[t]; if (b) b.Label_mc.LabelInstance_mc.Label_tf.text = txt; } });
		} else if (q < 0.04) {   // controller change: key art swaps
			N.hzVehPad = O.hzVehPad = 1 - N.hzVehPad;
			for (const b of btns()) { b.PCButton_mc.ButtonInstance_mc.visible = N.hzVehPad === 0; b.ConsoleButton_mc.ButtonInstance_mc.visible = N.hzVehPad === 1; }
		} else if (q < 0.05) { m = (m + 1) % 5; const b = btns()[0]; b.HoldLabel_mc.LabelInstance_mc.Label_tf.text = "H" + m; }   // uMode change with a label
		else if (q < 0.055) { const i = Math.floor(r() * 2); const old = removeAt(W.bb, i); const nb = add(W.bb, Button(old.name, r), i); nb.Label_mc.LabelInstance_mc.Label_tf.text = "S" + f; }
		else if (q < 0.057) { const b = btns()[3]; b.Label_mc.LabelInstance_mc.Label_tf.text = "Z" + f; noEdge = true; staleOpen = true; }   // a label change with no edge (stated risk)
		for (const p of pending) if (p.f === f) p.run();
		pending = pending.filter((p) => p.f > f);
		const rb = N.hzT19BtnSync(W.aw);
		N.hzT19Edge(W.aw, true, m, rb);
		if (N.hzT19LblDue || N.hzT19LblC == null) reads++;
		if (N.hzT19LblDue) staleOpen = false;   // an edge re-reads everything
		const a = O.read(true, W.aw), b = N.read(true, W.aw);
		frames++;
		const ta = a.split("|"), tb = b.split("|");
		const diffIdx = ta.map((x, i) => (x === tb[i] ? -1 : i)).filter((i) => i >= 0);
		if (a === b) same++;
		else if (staleOpen && diffIdx.every((i) => i === 10)) stale++;   // only the no-edge label (button 3, plain label), until the next edge
		else other++;
	}
	expect(other === 0, "labels: the 12 reads equal the old per-frame reads on every frame except after a no-edge label change (" + same + " same of " + frames + ", " + stale + " stale-risk frames, " + other + " other)");
	expect(stale > 0 && reads * 4 < frames, "labels: the reads ran on " + reads + " of " + frames + " frames; a label changed with no edge stays stale until the next edge (" + stale + " frames, the stated risk)");
	expect(N.read(false, W.aw) === O.read(false, W.aw), "labels: no prompt shown -> the same 12 nulls");
}

// ---- 4. edges ----
{
	const W = buildWidget(3);
	const h = host(as, W, true);
	const due = [];
	const tick = (f, aw, show, m) => { h.hzFrameN = f; h.hzT19Edge(aw, show, m, aw ? h.hzT19BtnSync(aw) : false); due.push(h.hzT19LblDue && h.hzT19HcDue); };
	for (let f = 1; f <= 10; f++) tick(f, W.aw, true, 0);
	expect(due.join("") === [true, true, true, false, false, false, false, false, false, false].join(""), "first ticks: due on the first frame and the 2 after it, then not");
	due.length = 0; tick(11, W.aw, true, 0); tick(11, W.aw, true, 0);
	expect(!due[0] && !due[1], "a second tick in the same frame is not an edge");
	due.length = 0; tick(12, W.aw, true, 2); tick(13, W.aw, true, 2); tick(14, W.aw, true, 2); tick(15, W.aw, true, 2);
	expect(due.join() === "true,true,true,false", "uMode change: the edge frame and 2 more");
	due.length = 0; h.hzVehPad = 1; tick(16, W.aw, true, 2);
	expect(due[0], "controller type change (hzVehPad): edge");
	for (let f = 17; f < 20; f++) tick(f, W.aw, true, 2);
	due.length = 0; tick(22, W.aw, true, 2);
	expect(due[0], "a skipped tick (frames 20-21): edge");
	for (let f = 23; f < 26; f++) tick(f, W.aw, true, 2);
	due.length = 0; tick(26, W.aw, false, 2);
	expect(due[0], "show off (same uMode): edge");
	for (let f = 27; f < 30; f++) tick(f, W.aw, false, 2);
	due.length = 0; const W2 = buildWidget(4); tick(30, W2.aw, false, -1);
	expect(due[0], "a new widget (aw): edge");
	const act = codeOnly(fnText(as, "hzOnTgAct").body);
	expect(/if\(pay != this\.hzT19ActCached\)\s*\{\s*this\.hzT19ActCached = pay;\s*this\.hzT19EdgeN = 3;/.test(act), "hzOnTgAct: a prompt payload change sets the edge (only a change, not every event)");
}

// ---- 5. hzVis ----
if (baseAs) {
	class Rectangle { constructor(x, y, w, h) { this.x = x; this.y = y; this.width = w; this.height = h; } get left() { return this.x; } get top() { return this.y; } get right() { return this.x + this.width; } get bottom() { return this.y + this.height; } }
	class Point { constructor(x, y) { this.x = x; this.y = y; } }
	const mk = (src) => {
		const h = { Rectangle, Point, isNaN, Extensions: { visibleRect: null }, stage: {}, x: 0, y: 0, scaleX: 1, scaleY: 1, rotation: 0, hzVisR: null, hzVisF: null, hzVisK: null };
		h.globalToLocal = function(p) { return new Point((p.x - h.x) / h.scaleX, (p.y - h.y) / h.scaleY); };
		bind(h, src, "hzVis");
		return h;
	};
	const O = mk(baseAs), N = mk(as);
	const r = rng(9);
	let bad = "", reused = 0, n = 0;
	let last = null;
	for (let i = 0; i < 3000 && !bad; i++) {
		const q = r();
		if (q < 0.05) { const vr = r() < 0.1 ? null : new Rectangle(Math.floor(r() * 50), Math.floor(r() * 50), r() < 0.05 ? 50 : 1800 + Math.floor(r() * 200), 1000); O.Extensions.visibleRect = vr; N.Extensions.visibleRect = vr; }
		else if (q < 0.08) { const s = 0.9 + r() * 0.2; O.scaleX = O.scaleY = N.scaleX = N.scaleY = s; }
		else if (q < 0.10) { const x = Math.floor(r() * 30); O.x = N.x = x; }
		else if (q < 0.11) { const st = r() < 0.2 ? null : {}; O.stage = N.stage = st; }
		else if (q < 0.12 && O.Extensions.visibleRect) { O.Extensions.visibleRect.width += 4; }   // the same object changed in place
		const a = O.hzVis(), b = N.hzVis();
		n++;
		if (JSON.stringify([a.x, a.y, a.width, a.height]) !== JSON.stringify([b.x, b.y, b.width, b.height])) bad = "call " + i;
		if (b === last) reused++;
		last = b;
	}
	expect(!bad, "hzVis: the same rect as the old body over 3000 calls (visible rect, scale, x, stage changes, an in-place width change)" + (bad ? " -- " + bad : ""));
	expect(reused > n * 0.8, "hzVis: one shared object while nothing changed (" + reused + " of " + n + " calls reused)");
	const callers = (as.match(/this\.hzVis\(\)/g) || []).length;
	const writes = as.split("\n").filter((l) => /\b(vr|vis|r|vv|sr)\.(x|y|width|height)\s*[-+*]?=[^=]/.test(l) && /hzVis/.test(l)).length;
	expect(callers > 5 && writes === 0, "hzVis callers (" + callers + ") only read the rect (no field write on a line that calls hzVis)");
}

// ---- 6. static ----
{
	const fns = NEW_FN.concat(["hzT19BtnClip", "hzVis"]);
	const all = fns.map((f) => codeOnly(fnText(as, f).body)).join("\n");
	expect(!/addEventListener|setInterval|setTimeout|new Timer|% \d|hzFindByName|getChildByName/.test(all), "the new functions add no timer, listener, frame-modulo term or search");
	const hv = codeOnly(fnText(as, "hz38HideVanilla").body);
	expect(hv.indexOf("this.hzT19KeepHold(aw);") >= 0 && hv.indexOf("hzT19HideA(aw") < 0 && /\.alpha = 0/.test(codeOnly(fnText(as, "hzT19HcApply").body)) && !/visible = false/.test(codeOnly(fnText(as, "hzT19HcApply").body)),
		"alpha hide only (no visible write, no removal); the hold button stays live; the widget itself is not hidden");
	const tick = codeOnly(fnText(as, "hzT19Tick").body);
	expect(tick.indexOf("rw0[rn++] = this.hzT19Key(aw,kk); rw0[rn++] = this.hzT19VanLbl(aw,kk,false); rw0[rn++] = this.hzT19VanLbl(aw,kk,true);") >= 0 && (tick.match(/this\.hzT19BtnSync\(/g) || []).length === 1, "the tick reads the buttons once (hzT19BtnSync) and keeps the label reads in the same order");
	if (baseAs) {
		// 0.43.3.2: the only allowed change is the pill-name wrap reset (two exact lines, no red bar code)
		const wrapReset = (b) => b.replace('o.tone = "main"; o.lines = 1; }', 'o.tone = "main"; }').replace("\n         if(nmTf.wordWrap) { nmTf.wordWrap = false; nmTf.multiline = false; }   // 0.43.3.2: only a wrapped pill name sets these", "");
		// 0.43.4 item 2: the keycap rows (ownRow, hzT19RowsH) are the only other change; undone here line by line
		const rows043 = [
			["this.hzT19Buttons(null,a,aw,0,0,acol,0,0,true) : 0;\n         var rowsH:Number = bw > 0 ? this.hzT19RowsH : 0;   // 0.43.4: all keycap rows (one per long label)", "this.hzT19Buttons(null,a,aw,0,0,acol) : 0;"],
			["dvY + 8 + rowsH + 18", "dvY + 8 + this.hzT19CapH() + 18"], ["(hasBtn ? rowsH + 10 : 0)", "(hasBtn ? this.hzT19CapH() + 10 : 0)"],
			["bodyEnd + 12 + rowsH + 14", "bodyEnd + 12 + this.hzT19CapH() + 14"], ["fy + 42 + rowsH + 14", "fy + 42 + this.hzT19CapH() + 14"],
			["dvY + 8,HZ_ACCENT,0,0,true)", "dvY + 8,HZ_ACCENT)"], ["by + 24,HZ_RED,0,0,true)", "by + 24,HZ_RED)"], ["bodyEnd + 12,acol,0,0,true)", "bodyEnd + 12,acol)"], ["fy + 42,acol,0,0,true)", "fy + 42,acol)"],
		];
		// 0.43.4 item 1: the private HoverDiag bits (hv) pick the size and may skip the full-size measure
		rows043.unshift(["         var nh:int = hv == 0 ? this.hzNameHover : ((hv & 2) != 0 ? 1 : ((hv & 4) != 0 ? 0 : this.hzNameHover));\n         var bw:Number = a ? (hv != 0 && (hv & 8) != 0 && kind == \"prompt\" && nh != 1 ? 1 : this.hzT19Buttons(null,a,aw,0,0,acol,0,0,true)) : 0;", "         var bw:Number = a ? this.hzT19Buttons(null,a,aw,0,0,acol,0,0,true) : 0;"]);
		rows043.push(["if(kind == \"prompt\" && nh != 1)", "if(kind == \"prompt\" && this.hzNameHover != 1)"]);
		const undo043 = (b) => rows043.reduce((t, r) => t.split(r[0]).join(r[1]), b);
		// list-card STEAL room math (140-wide ITEMS slot, measured chip, clamp). Covered by tests/hover_steal_list_test.js.
		const undoStealList = (b) => {
			const pairs = [
				["            nmTf.x = 14;\n            this.hzTxtTint(nmTf,steal ? HZ_RED : null);\n            this.hzApplyFmt(o);\n            this.hzT19HdrR.visible = true;\n            this.hzT19Face(this.hzT19HdrR,\"sb\");\n            // ITEMS sits in a fixed 140-wide field on the right. Room math must use that slot, not the painted\n            // \"N ITEMS\" width, or STEAL (and a long title) run into the count.\n            var itemsSlot:Number = 140;\n            this.hzT19HdrR.width = itemsSlot;\n            this.hzT19HdrR.text = n + (n == 1 ? \" ITEM\" : \" ITEMS\");\n            this.hzT19HdrR.x = W - 14 - itemsSlot;\n            this.hzTxtTop(this.hzT19HdrR,15);\n            var stw:Number = 0;\n            if(steal)\n            {\n               this.hzT19Ch2.text = \"STEAL\";\n               stw = this.hzTW(this.hzT19Ch2) + 14;\n            }\n            else if(this.hzT19Ch2) { this.hzT19Ch2.visible = false; }\n            var hroom:Number = this.hzT19HdrR.x - 14 - (steal ? stw + 10 : 0);\n            if(hroom < 40) { hroom = 40; }\n            nmTf.width = hroom;\n",
					"            nmTf.x = 14; nmTf.width = W - 28;\n            this.hzTxtTint(nmTf,steal ? HZ_RED : null);\n            this.hzApplyFmt(o);\n            this.hzT19HdrR.visible = true;\n            this.hzT19Face(this.hzT19HdrR,\"sb\");\n            this.hzT19HdrR.width = 140;\n            this.hzT19HdrR.text = n + (n == 1 ? \" ITEM\" : \" ITEMS\");\n            this.hzT19HdrR.x = W - 14 - 140;\n            this.hzTxtTop(this.hzT19HdrR,15);\n            var hroom:Number = W - 28 - this.hzTW(this.hzT19HdrR) - 14;\n            var stw:Number = 0;\n            if(steal) { stw = 60; hroom -= stw; }\n"],
				["               var stx:Number = 14 + this.hzTW(nmTf) + 10;\n               if(stx + stw > this.hzT19HdrR.x - 4) { stx = this.hzT19HdrR.x - stw - 8; }\n               if(stx < 14) { stx = 14; }\n               this.hzChip(g,this.hzT19Ch2,stx,15,\"STEAL\",HZ_RED,true);\n",
					"               var stx:Number = 14 + this.hzTW(nmTf) + 10;\n               this.hzChip(g,this.hzT19Ch2,stx,15,\"STEAL\",HZ_RED,true);\n"],
			];
			return pairs.reduce((t, r) => t.split(r[0]).join(r[1]), b);
		};
		expect(undo043(wrapReset(undoStealList(fnText(as, "hzT19Content").body))) === fnText(baseAs, "hzT19Content").body && fnText(as, "hzT19ResetPay").body === fnText(baseAs, "hzT19ResetPay").body, "the loot card red bar code (hzT19Content, hzT19ResetPay) is unchanged from " + BASE);
		// 0.43.6 round 3 E / E2 rewrote both for allocation (reused draw list, field compare); that behavior is tested in
		// tests/round3_e_test.js, round3_e2_test.js and target_foebar_test.js. Review SF-3: each body must still be
		// exactly the pre-0.43.6 body or exactly the reviewed round 3 body (frozen at R3_BASE), nothing else.
		const R3_BASE = process.env.HZ_R3_BASE || "d8c7a59";
		const r3Res = gitBase.readBase(root, R3_BASE);
		if (r3Res.src == null) {
			expect(r3Res.skip, "round 3 reference " + R3_BASE + " readable (" + r3Res.why + ")");
		} else {
			const r3 = r3Res.src;
			const same = (n) => fnText(as, n).body === fnText(baseAs, n).body || fnText(as, n).body === fnText(r3, n).body;
			expect(same("hzT19PaintHold") && same("hzT19PaintFoeBars"), "the hold fill and foe bars are unchanged (pre-0.43.6, or the reviewed round 3 form at " + R3_BASE + ")");
		}
	}
}

console.log((failed ? failed + " FAILED" : "all passed") + " (" + passed + " ok)");
process.exit(failed ? 1 : 0);
