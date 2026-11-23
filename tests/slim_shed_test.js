// 0.43.5 slim: proves the classic-card teardown (hz55ShedOld), the shed guards in hzMeter / hzDrawVitBg, the
// change-only fade writes in hzTickFades and the shared strings in hzOnPlayerFrequent / hzOnJetpack keep every visible
// result of the 0.43.4 bodies (read through git show from BASE), and that a card toggled off and on again comes back
// exactly as it was. The production AS bodies run in a small display model (parent links, children, graphics, alpha in
// 1/256 steps, y in 1/20 px like the player).
// Run: node tests/slim_shed_test.js   (HZ_BASE=<rev> to pick the reference, default aacade5)
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const fs = require("fs");
const path = require("path");
const gitBase = require("./lib/git_base.js");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const BASE = process.env.HZ_BASE || "aacade5";
const baseRes = gitBase.readBase(root, BASE);
const base = baseRes.src;

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) return null;
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
		.replace(/(\w+) is DisplayObjectContainer\b/g, "__isDoc($1)")
		.replace(/(\w+) is Sprite\b/g, "__isSp($1)")
		.replace(/\b(DisplayObjectContainer|Sprite|TextField)\((?=[\w.\[\]]+\))/g, "(")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.*]+\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].split("=")[0].trim());
}
function bind(host, src, name) {
	const f = fnText(src, name);
	if (!f) throw new Error("missing function " + name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}

// ---- display model ----
let uid = 0;
const WRITES = { n: 0 };
function Gfx() { this.ops = 0; this.clears = 0; }
Gfx.prototype.clear = function() { this.ops = 0; this.clears++; };
for (const k of ["beginFill", "drawRect", "drawRoundRect", "drawCircle", "endFill", "lineStyle", "moveTo", "lineTo"]) Gfx.prototype[k] = function() { this.ops++; };
function Node(kind) {
	this._id = ++uid; this.kind = kind; this.parent = null; this.children = []; this.graphics = new Gfx();
	this._vis = true; this._a = 1; this._y = 0; this.x = 0; this.name = ""; this._text = "";
}
Object.defineProperty(Node.prototype, "visible", { get() { return this._vis; }, set(v) { WRITES.n++; this._vis = !!v; } });
Object.defineProperty(Node.prototype, "alpha", { get() { return this._a; }, set(v) { WRITES.n++; this._a = Math.round(Math.max(0, Math.min(1, v)) * 256) / 256; } });
Object.defineProperty(Node.prototype, "y", { get() { return this._y; }, set(v) { WRITES.n++; this._y = Math.round(v * 20) / 20; } });
Object.defineProperty(Node.prototype, "text", { get() { return this._text; }, set(v) { WRITES.n++; this._text = String(v); } });
Object.defineProperty(Node.prototype, "numChildren", { get() { return this.children.length; } });
Node.prototype.addChild = function(c) { if (c.parent) c.parent.removeChild(c); c.parent = this; this.children.push(c); return c; };
Node.prototype.removeChild = function(c) { const i = this.children.indexOf(c); if (i < 0) throw new Error("not a child"); this.children.splice(i, 1); c.parent = null; return c; };
Node.prototype.removeChildAt = function(i) { const c = this.children[i]; if (!c) throw new Error("range"); this.children.splice(i, 1); c.parent = null; return c; };
Node.prototype.getChildAt = function(i) { return this.children[i]; };
const sp = () => new Node("sp");
const tf = () => new Node("tf");
function under(d, r) { while (d) { if (d === r) return true; d = d.parent; } return false; }

const SHED_FNS = ["hz55ShedOld", "hz55Under", "hz55Purge", "hz55Unlink", "hzTxtObj", "hzMeter", "hzMeterDraw", "hzDot", "hzDrawVitBg", "hzDrawMag"];
expect(SHED_FNS.every((n) => fnText(as, n) != null), "source: the shed functions and the guarded helpers exist");

// a HUD with every classic wrapper and its v0.19 sibling, the way hzWrap / hzBuild leave them
function makeHud(opts) {
	opts = opts || {};
	const h = {
		int: (n) => Number(n) | 0, uint: (n) => Number(n) >>> 0, Math: Math,
		__isDoc: (d) => d instanceof Node && d.kind === "sp", __isSp: (d) => d instanceof Node && d.kind === "sp",
		HZ_W: 300, HZ_RED: 1, HZ_GREEN: 2, HZ_YELLOW: 3, HZ_ACCENT: 4,
		hzPerfOn: false, hzPcTxHit: 0, hzPcTxMiss: 0, hzSmoothBars: false,
		hzTexts: [], hzTextTf: [], hzIcons: [], hzTiles: [], hzCardBodies: [], hzBars: [],
		hz55Shed: false, hz55Bars: [], hz55Stat: null,
		hzMagCap: 30, hzMagMax: 30, hzMagClip: 10, hzMagBar: true, hzEqDrawTicks() {},
		hzCHpBar: null, hzVnHpBar: null, stage: sp()
	};
	for (const n of SHED_FNS) bind(h, as, n);
	const reg = (o, p) => { p.addChild(o); return o; };
	const addText = (p) => { const t = reg(tf(), p); h.hzTexts.push({ tf: t, size: 12 }); return t; };
	const addIcon = (p) => { const s = reg(sp(), p); s.graphics.beginFill(); h.hzIcons.push({ s: s, k: "x", c: 1 }); return s; };
	const addTile = (p) => { const s = reg(sp(), p); s.graphics.drawRect(); h.hzTiles.push({ s: s, w: 1, h: 1 }); return s; };
	const addBody = (p) => { const s = reg(sp(), p); s.graphics.drawRect(); h.hzCardBodies.push({ s: s, w: 1, h: 1, k: "card" }); return s; };
	const addBar = (p) => { const s = reg(sp(), p); h.hzMeter(s, 100, 1, 4); return s; };
	h.CARDS = {}; h.OLD = {}; h.NEW = {};
	const pairs = [["Env", "hzPlanOld", "hzPlanPill"], ["Vit", "hzVitOld", "hzVitNew"], ["Jet", "hzJetOld", "hzJetNew"], ["Cmp", "hzCmpOld", "hzCmpNew"],
		["Q", "hzQOld", "hzQNew"], ["CQ", "hzCQOld", "hzCQNew"], ["Af", "hzAfOld", "hzAfNew"], ["Tg", "hzTgOld", "hzTg19"]];
	for (const [k, oldF, newF] of pairs) {
		const card = h.stage.addChild(sp());
		const old = card.addChild(sp());
		addBody(old); addTile(old); addIcon(old); addText(old); addText(old);
		const deep = old.addChild(sp()); addText(deep); addIcon(deep);
		const nw = card.addChild(sp());
		addBody(nw); addTile(nw); addIcon(nw); addText(nw);
		h[oldF] = old; h[newF] = nw; h.CARDS[k] = card; h.OLD[k] = old; h.NEW[k] = nw;
	}
	if (opts.missing) h[opts.missing] = null;
	h.hzEqOld = sp(); addBody(h.hzEqOld); h.hzAmmoCount = addText(h.hzEqOld); h.hzMagSp = h.hzEqOld.addChild(sp());
	h.hzVitHp = addText(h.hzVitOld); h.hzVitHpBar = addBar(h.hzVitOld); h.hzVitBg = h.hzVitOld.addChild(sp());
	h.hzJetBar = addBar(h.hzJetOld); h.hzEnvSoak = addBar(h.hzPlanOld);
	h.hzDotJet = h.hzJetOld.addChild(sp()); h.hzDotVit = h.hzVitOld.addChild(sp()); h.hzDotPlan = h.hzPlanOld.addChild(sp());
	h.hzDotAff = h.hzAfOld.addChild(sp()); h.hzDotAmmo = h.hzEqOld.addChild(sp());
	h.hzVnHpBar = addBar(h.NEW.Vit); h.hzVnHp = addText(h.NEW.Vit);
	return h;
}

// ---- teardown ----
{
	const h = makeHud();
	const nT = h.hzTexts.length, nI = h.hzIcons.length, nB = h.hzBars.length;
	const oldTexts = h.hzTexts.filter((o) => Object.values(h.OLD).some((r) => under(o.tf, r)) || under(o.tf, h.hzEqOld)).map((o) => o.tf);
	const newTexts = h.hzTexts.filter((o) => oldTexts.indexOf(o.tf) < 0).map((o) => o.tf);
	const newKids = {}; for (const k in h.NEW) newKids[k] = h.NEW[k].children.slice();
	const oldNodes = []; const walk = (d) => { oldNodes.push(d); d.children.forEach(walk); };
	Object.values(h.OLD).forEach(walk); walk(h.hzEqOld);
	h.hzTxtObj(newTexts[0]); h.hzTxtObj(oldTexts[0]);   // fill the index before the shed, as the running HUD has
	const keptVitHp = h.hzVitHp, keptAmmo = h.hzAmmoCount;
	h.hz55ShedOld();
	expect(h.hz55Shed === true, "shed: hz55Shed is set");
	expect(h.hzTexts.length === nT - oldTexts.length && newTexts.every((t) => h.hzTexts.some((o) => o.tf === t)), "shed: every classic text left hzTexts (" + oldTexts.length + "), every v0.19 text stayed (" + newTexts.length + ")");
	expect(oldTexts.every((t) => h.hzTxtObj(t) === null) && newTexts.every((t) => { const o = h.hzTxtObj(t); return o && o.tf === t; }), "shed: hzTxtObj misses every classic text and finds every v0.19 text after the index reset");
	expect(h.hzIcons.every((o) => !oldNodes.includes(o.s)) && h.hzIcons.length === nI - h.hz55Stat.i && h.hz55Stat.i > 0, "shed: classic icons left hzIcons, v0.19 icons stayed");
	expect(h.hzTiles.every((o) => !oldNodes.includes(o.s)) && h.hzTiles.length === 8, "shed: classic tiles left hzTiles (8 v0.19 tiles stay)");
	expect(h.hzCardBodies.every((o) => !oldNodes.includes(o.s)) && h.hzCardBodies.length === 8, "shed: classic bodies left hzCardBodies (8 v0.19 bodies stay)");
	expect(h.hzBars.length === nB - 3 && h.hz55Bars.length === 3 && h.hzBars.some((o) => o.b === h.hzVnHpBar), "shed: the 3 classic bars left hzBars, the v0.19 bar stayed");
	expect(oldNodes.every((d) => d.parent === null && d.children.length === 0), "shed: every classic node (" + oldNodes.length + ") is unlinked from its parent and holds no children");
	expect(oldNodes.filter((d) => d.kind === "sp").every((d) => d.graphics.ops === 0 && d.graphics.clears > 0), "shed: every classic sprite's vector graphics were cleared");
	expect(Object.keys(h.NEW).every((k) => h.NEW[k].parent === h.CARDS[k] && h.NEW[k].children.length === newKids[k].length && h.NEW[k].children.every((c, i) => c === newKids[k][i])), "shed: every v0.19 form keeps its card, its children and their order");
	expect(Object.values(h.CARDS).every((c) => c.parent === h.stage && c.children.length === 1), "shed: every card stays on stage with only its v0.19 form");
	expect(["hzPlanOld", "hzVitOld", "hzJetOld", "hzCmpOld", "hzQOld", "hzCQOld", "hzAfOld", "hzTgOld", "hzEqOld", "hzDotJet", "hzDotVit", "hzDotPlan", "hzDotAff", "hzDotAmmo", "hzMagSp"].every((f) => h[f] === null), "shed: the wrapper, dot and magazine fields are null (their users return on null)");
	expect(h.hzVitHp === keptVitHp && h.hzAmmoCount === keptAmmo, "shed: text fields other code reads (hzVitHp, hzAmmoCount) are kept, detached");
	keptAmmo.text = "5 / 10"; expect(keptAmmo.text === "5 / 10", "shed: a kept detached field still reads back its text (hzCAmmo copies hzAmmoCount.text)");
	const st = JSON.stringify(h.hz55Stat); const nT2 = h.hzTexts.length;
	h.hz55ShedOld();
	expect(JSON.stringify(h.hz55Stat) === st && h.hzTexts.length === nT2, "shed: a second call does nothing");
	// guards after the shed
	const nB2 = h.hzBars.length;
	h.hzMeter(keptVitHp && h.hz55Bars[0], 100, 0.5, 1);
	expect(h.hzBars.length === nB2, "hzMeter: a torn-down classic bar is not re-registered (no glide redraw on a detached sprite)");
	h.hzMeter(h.hzVnHpBar, 100, 0.5, 1);
	const vb = h.hzBars.find((o) => o.b === h.hzVnHpBar);
	expect(vb && vb.t === 0.5 && h.hzVnHpBar.graphics.ops > 0, "hzMeter: a v0.19 bar still updates and draws");
	h.hzMeter(null, 100, 0.5, 1);
	expect(h.hzBars.length === nB2, "hzMeter: a null bar is ignored");
	const bgOps = h.hzVitBg.graphics.clears; h.hzDrawVitBg(0.7);
	expect(h.hzVitBg.graphics.clears === bgOps && h.hzVitBg.graphics.ops === 0, "hzDrawVitBg: no redraw of the classic low-health outline after the shed");
	h.hzDot(h.hzDotJet, 1); h.hzDrawMag();
	expect(true, "hzDot / hzDrawMag: return on the nulled classic dot and magazine sprite");
}
// a failed v0.19 builder keeps the classic fallback
for (const miss of ["hzTg19", "hzVitNew", "hzPlanPill"]) {
	const h = makeHud({ missing: miss });
	const n = h.hzTexts.length;
	h.hz55ShedOld();
	expect(!h.hz55Shed && h.hzTexts.length === n && h.hzVitOld && h.hzVitOld.parent, "shed: with " + miss + " missing nothing is torn down (the classic form stays the fallback)");
}

// ---- hzBuild order and the registry rule ----
{
	const b = fnText(as, "hzBuild").body;
	const iC = b.indexOf("this.hzBuildCompact();"), iS = b.indexOf("this.hz55ShedOld();"), iF = b.indexOf("addEventListener(Event.ENTER_FRAME");
	expect(iC >= 0 && iS > iC && iF > iS, "hzBuild: hz55ShedOld runs once, after every builder (hzBuildCompact makes hzCQOld) and before the frame handler");
	const sb = fnText(as, "hz55ShedOld").body;
	expect(sb.indexOf("this.hzTextTf = [];") >= 0 && sb.indexOf("this.hzTextTf = [];") < sb.indexOf("hz55Purge(this.hzTexts"), "hz55ShedOld: drops the hzTxtObj index before it removes text entries");
	const rm = as.split("\n").filter((l) => /hz55Purge\(this\.hzTexts/.test(l));
	expect(rm.length === 2, "source: hz55ShedOld and hzEqShedNew (0.43.6 round 3 C) are the only places that remove hzTexts entries");
	const eb = fnText(as, "hzEqShedNew").body;
	expect(eb.indexOf("this.hzTextTf = [];") >= 0 && eb.indexOf("this.hzTextTf = [];") < eb.indexOf("hz55Purge(this.hzTexts") && eb.lastIndexOf("this.hzTextTf = [];") > eb.indexOf("hz55Purge(this.hzTexts"), "hzEqShedNew: drops the hzTxtObj index before and after it removes text entries");
}

// ---- hzTickFades: change-only writes, same results; a card toggled off and on comes back the same ----
function makeFadeHost(src) {
	const h = { hzV19: () => true, hzCombatDim: true, hzInCombat: false, hzLowHealth: false, hzDimAlpha: 0.6, hzFades: [], hzFadeCards: true, hzLaidOut: true, hzLayEver: true, Math: Math };
	bind(h, src, "hzTickFades"); bind(h, src, "hzShow");
	return h;
}
function rng(seed) { let s = seed >>> 0; return () => { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
if (base) {
	const r = rng(55);
	let same = true, firstBad = "", wOld = 0, wNew = 0;
	for (let run = 0; run < 40 && same; run++) {
		const A = makeFadeHost(base), B = makeFadeHost(as);
		const ca = [], cb = [];
		for (let i = 0; i < 4; i++) { const a = sp(), b = sp(); a.y = b.y = 100 + i * 50; ca.push(a); cb.push(b); A.hzShow(a, true); B.hzShow(b, true); }
		for (let f = 0; f < 300 && same; f++) {
			if (r() < 0.04) { const i = Math.floor(r() * 4), on = r() < 0.5; A.hzShow(ca[i], on); B.hzShow(cb[i], on); }
			if (r() < 0.02) { const v = r() < 0.5; A.hzInCombat = B.hzInCombat = v; }
			if (r() < 0.01) { const i = Math.floor(r() * 4); ca[i].alpha = 0; cb[i].alpha = 0; }            // a force-hide by other code
			if (r() < 0.01) { const i = Math.floor(r() * 4); ca[i].visible = false; cb[i].visible = false; }
			if (r() < 0.01) { A.hzLaidOut = B.hzLaidOut = r() < 0.8; }
			let w0 = WRITES.n; A.hzTickFades(); wOld += WRITES.n - w0;
			w0 = WRITES.n; B.hzTickFades(); wNew += WRITES.n - w0;
			for (let i = 0; i < 4; i++) {
				if (ca[i].visible !== cb[i].visible || ca[i].alpha !== cb[i].alpha || ca[i].y !== cb[i].y) { same = false; firstBad = "run " + run + " frame " + f + " card " + i; break; }
			}
		}
	}
	expect(same, "hzTickFades: visible, alpha and y match the " + BASE + " body on every frame of 40 random runs (toggles, combat dim, force-hides, relayouts)" + (same ? "" : " (first difference: " + firstBad + ")"));
	expect(wNew < wOld / 3, "hzTickFades: display writes " + wNew + " vs " + wOld + " in the " + BASE + " body (settled cards cost none)");
	// settled cards: no writes at all
	const B = makeFadeHost(as); const c = sp(); c.y = 200; B.hzShow(c, true);
	for (let f = 0; f < 200; f++) B.hzTickFades();
	const w0 = WRITES.n; for (let f = 0; f < 60; f++) B.hzTickFades();
	expect(WRITES.n === w0, "hzTickFades: a settled card gets no display writes over 60 frames");
	// toggle off and on again restores the card exactly
	const st0 = [c.visible, c.alpha, c.y];
	B.hzShow(c, false); for (let f = 0; f < 120; f++) B.hzTickFades();
	const off = [c.visible, c.alpha];
	B.hzShow(c, true); for (let f = 0; f < 200; f++) B.hzTickFades();
	expect(off[0] === false && off[1] < 0.02, "toggle: a card turned off fades out and is hidden");
	expect(c.visible === st0[0] && c.alpha === st0[1] && c.y === st0[2], "toggle: turned on again it is back with the same visible, alpha and y (" + st0.join(", ") + ")");
} else {
	gitBase.report(baseRes, BASE, "hzTickFades", expect);
}

// ---- hzOnPlayerFrequent / hzOnJetpack: same v0.19 and compact texts, classic writes skipped after the shed ----
function makeVitHost(src, shed) {
	const h = { Math: Math, int: (n) => Number(n) | 0, uint: (n) => Number(n) >>> 0, HZ_W: 300, HZ_VN_W: 330, HZ_RED: 1, HZ_GREEN: 2, HZ_YELLOW: 3, HZ_ACCENT: 4, HZ_O2_BLUE: 5,
		hz36HideTick() {}, hzFixFonts() {}, hz26WarnCol: (f, c) => (f < 0.35 ? 9 : c), hzTxtTint() {}, hz26VnWarn() {}, hzRefreshVisibility() {}, hzDrawVitBg() {}, hzDot() {},
		hzJetTrack() {}, meters: [], hzRuleVitals: 0, hzShowHealth: true, hzShowOxygen: true,
		hz55Shed: shed, hz55JetPct: -1, hz55JetS: "", hz55HpR: -1, hz55MhpR: -1, hz55HpS: "", hz55O2R: -1, hz55O2S: "" };
	h.hzMeter = (b, w, f, c) => { h.meters.push([b.name, w, f, c]); };
	for (const n of ["hzVitHp", "hzVitO2", "hzVitHpLbl", "hzVitO2Lbl", "hzVnHp", "hzVnO2", "hzCHp", "hzCO2", "hzJetPct", "hzCJet"]) { h[n] = tf(); h[n].name = n; }
	for (const n of ["hzVitHpBar", "hzVitO2Bar", "hzVnHpBar", "hzVnO2Bar", "hzCHpBar", "hzCO2Bar", "hzJetBar", "hzCJetBar"]) { h[n] = sp(); h[n].name = n; }
	h.hzDotJet = null; h.hzDotVit = null;
	bind(h, src, "hzOnPlayerFrequent"); bind(h, src, "hzOnJetpack");
	return h;
}
if (base) {
	const r = rng(7);
	const A = makeVitHost(base, false), B = makeVitHost(as, false), C = makeVitHost(as, true);
	const NEWF = ["hzVnHp", "hzVnO2", "hzCHp", "hzCO2", "hzCJet"];
	let same = true, classicSame = true, bad = "", hp = 300, o2 = 100;
	const cTxt0 = ["hzVitHp", "hzVitO2", "hzJetPct"].map((n) => C[n].text);
	let w = [0, 0];
	for (let i = 0; i < 2000 && same; i++) {
		if (r() < 0.5) { hp = Math.max(0, Math.min(400, hp + (r() - 0.5) * 6)); o2 = Math.max(0, Math.min(100, o2 + (r() - 0.5) * 0.7)); }
		const d = { fHealth: hp, fMaxHealth: r() < 0.01 ? 0 : 400, fOxygen: o2, fMaxO2CO2: 100 };
		const j = { fJetpackCharge: r() < 0.1 ? -1 : r() };
		for (const H of [A, B, C]) { H.meters = []; }
		let w0 = WRITES.n; A.hzOnPlayerFrequent({ data: d }); A.hzOnJetpack({ data: j }); w[0] += WRITES.n - w0;
		w0 = WRITES.n; B.hzOnPlayerFrequent({ data: d }); B.hzOnJetpack({ data: j }); w[1] += WRITES.n - w0;
		C.hzOnPlayerFrequent({ data: d }); C.hzOnJetpack({ data: j });
		for (const n of NEWF) if (A[n].text !== B[n].text || A[n].text !== C[n].text) { same = false; bad = n + " at " + i; }
		for (const n of ["hzVitHp", "hzVitO2", "hzJetPct"]) if (A[n].text !== B[n].text) { classicSame = false; bad = n + " at " + i; }
		if (JSON.stringify(A.meters) !== JSON.stringify(B.meters)) { same = false; bad = "meters at " + i; }
		const vm = A.meters.filter((m) => !/^hz(VitHp|VitO2|Jet)Bar$/.test(m[0]));
		if (JSON.stringify(vm) !== JSON.stringify(C.meters)) { same = false; bad = "shed meters at " + i; }
	}
	expect(same, "vitals / jetpack: every v0.19 and compact text and meter call matches the " + BASE + " body over 2000 updates, with and without the shed" + (same ? "" : " (" + bad + ")"));
	expect(classicSame, "vitals / jetpack: before a shed the classic texts still match " + BASE);
	expect(["hzVitHp", "hzVitO2", "hzJetPct"].every((n, k) => C[n].text === cTxt0[k]), "vitals / jetpack: after the shed the classic texts are not written");
	// a compact strip built after the first update (hzBuildCompact runs after the subscriptions) gets the current text
	for (const H of [A, B]) { H.hzCJet = tf(); H.hzCJet.text = "--"; H.hzCHp = tf(); H.hzCHp.text = "--"; H.hzCO2 = tf(); H.hzCO2.text = "--"; }
	const dj = { fJetpackCharge: 0.5 }, dd = { fHealth: hp, fMaxHealth: 400, fOxygen: o2, fMaxO2CO2: 100 };
	for (const H of [A, B]) { H.hzOnJetpack({ data: dj }); H.hzOnPlayerFrequent({ data: dd }); }
	A.hzOnJetpack({ data: { fJetpackCharge: 0.5 } });
	const lateSame = ["hzCJet", "hzCHp", "hzCO2"].every((n) => A[n].text === B[n].text && B[n].text !== "--");
	for (const H of [A, B]) { H.hzCJet = tf(); H.hzCJet.text = "--"; H.hzOnJetpack({ data: dj }); }
	expect(lateSame && A.hzCJet.text === B.hzCJet.text && B.hzCJet.text === "50%", "vitals / jetpack: a strip made after the first update shows the current value even when the value did not change");
	expect(w[1] < w[0], "vitals / jetpack: text writes " + w[1] + " vs " + w[0] + " in the " + BASE + " body (unchanged strings are not rewritten)");
}

if (failed) { console.error(failed + " FAILED"); process.exit(1); }
console.log("slim_shed_test passed");
