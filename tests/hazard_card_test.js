// Hazard Status card tests (0.43.3.0). Run: node tests/hazard_card_test.js
// Runs the production AS functions (types stripped) on a small host and checks the source:
//  the card plumbing (own clip, ARRANGE key, scale / compact, F11 CARDS rows, INI keys, scanner hide, style apply),
//  red / green / hidden, bug (b) (green after the hazard effect left the list, ended by the vanilla green message's
//  own AnimationFinished), diff-and-skip, the default spot under the planet card, the vanilla EnvAlertText hide,
//  and no sound / timer / frame / search code in the card.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const ini = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8").replace(/\r\n/g, "\n");

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
const count = (s, sub) => s.split(sub).length - 1;
function toJs(name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/([\w.]+) as (?:Array|MovieClip)/g, "$1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/([^.\w])addChild\(/g, "$1this.addChild(")
		.replace(/\bHZ_HS_(\w+)/g, "this.HZ_HS_$1");
	return new Function(...params, body);
}

const B0 = "      // ===================== Hazard Status card (0.43.3.0; was the hs1 chip under the planet card) =====================\n";
const B1 = "      // ===================== end Hazard Status card =====================\n";
const i0 = as.indexOf(B0), i1 = as.indexOf(B1);
expect(i0 > 0 && i1 > i0 && count(as, B0) === 1 && count(as, B1) === 1, "one Hazard Status card section");
const sec = as.slice(i0, i1 + B1.length);
const code = sec.replace(/\/\/.*$/gm, "");
const CONST = {};
{ const re = /private static const (HZ_HS_\w+):\w+ = ([^;]+);/g; let m; while ((m = re.exec(sec))) CONST[m[1]] = /^"/.test(m[2]) ? JSON.parse(m[2]) : Number(m[2]); }
expect(CONST.HZ_HS_RED === 0xC33B29 && CONST.HZ_HS_GRN === 0x379B2C, "the two colors are the vanilla watch red / green");
expect(CONST.HZ_HS_FIN === "AnimationFinished" && CONST.HZ_HS_LOUT === "FadeOutEnvAlert_Positive" && CONST.HZ_HS_LIN === "FadeInEnvAlert_Positive", "bug (b): the vanilla BottomLeftGroup event and labels");

// ---- source rules: edge-only, sound untouched ----
expect(!/Timer|setTimeout|setInterval|ENTER_FRAME|enterFrame|getTimer|hzFindByName|hzFrameN/.test(code), "no timer / frame / tree search code in the card");
expect(!/PlayMenuSound|PlayAlertSound|PlaySound|\.play\(/.test(code), "no sound code in the card (the vanilla alert sound stays the only one)");
expect(count(code, "addEventListener(") === 1 && /addEventListener\(HZ_HS_FIN,this\.hzHsOnFin,false,1,true\)/.test(code), "one listener: the BottomLeftGroup's AnimationFinished, priority 1, weak");
expect(count(code, "Subscribe(") === 1, "one data subscription (EnvironmentAlertsData)");

// ---- plumbing ----
const lay = /HZ_LAY_KEYS:Array = \[([^\]]*)\]/.exec(as)[1].split(",").map((s) => JSON.parse(s));
const layN = /HZ_LAY_NAMES:Array = \[([^\]]*)\]/.exec(as)[1].split(",").map((s) => JSON.parse(s));
expect(lay.length === layN.length && layN[lay.indexOf("Hazard")] === "HAZARD STATUS", "ARRANGE key Hazard = HAZARD STATUS");
expect(/\["Watch",false\],\["Hazard",true\]\];/.test(as), "HZ34_CARDS: Hazard has its own scale and compact form");
expect(/"HazardScale":-1,"HazardCompact":-1,/.test(as), "HZ_SET_DEF: HazardScale / HazardCompact = -1 (GLOBAL)");
expect(/\nHazardScale=-1\n/.test(ini) && /\nHazardCompact=-1\n/.test(ini) && /\nHazardX=-1\nHazardY=-1\n/.test(ini) && /\nHazardStatus=1\n/.test(ini), "default.ini: HazardStatus=1, HazardScale / HazardCompact / HazardX / HazardY = -1");
expect(/case "Hazard": return \[this\.HorizonHazard_mc\]\.filter\(this\.hzNotNull\);/.test(as) && /case "Hazard": ok = this\.hzHsOn; break;/.test(as), "ARRANGE: hzLayClips / hzArrList know the card");
expect(/this\.HorizonXp_mc,this\.HorizonHazard_mc\]\)/.test(fnText(as, "hzArrShowAll").body) && /hzHsSync\(\)/.test(fnText(as, "hzArrShowAll").body), "ARRANGE shows the card (with its preview)");
expect(/\[this\.HorizonHazard_mc,"Hazard"\]\]/.test(fnText(as, "hzApplyScale").body), "hzApplyScale sets the card's own size");
expect(/"HorizonHazard_mc"\]/.test(/HZ40_CARDS:Array = \[[^\]]*\]/.exec(as)[0]), "the scanner hide (HZ40_CARDS) covers the card");
expect(/hzHsRestyle\(\)/.test(fnText(as, "hzV19Redraw").body), "style apply (hzV19Redraw) redraws the card");
const rows = fnText(as, "hz34CardRows").body;
expect(/\{"k":"HazardStatus","l":"HAZARD STATUS CARD","t":"b"[^}]*\},this\.hz34Sz\("Hazard"\),this\.hz34Cmp\("Hazard"\),/.test(rows), "F11 CARDS: HAZARD STATUS CARD with SIZE and COMPACT FORM");
expect(count(as, '"k":"HazardStatus"') === 1, "the HazardStatus row is in one tab only");
const rv = fnText(as, "hzRefreshVisibility").body;
expect(/this\.hzHsCard\(cardBase\); this\.hzHsSync\(\); if\(this\.HorizonHazard_mc && !this\.hzArrange\) \{ this\.hzShow\(this\.HorizonHazard_mc,this\.hzHsShown\); \}/.test(rv), "the visibility refresh gives the card its base and show target (restores a scanner force-hide)");
expect(!/hzHsCard/.test(fnText(as, "hzShow").body), "hzShow no longer ties the card to the planet card's fade");
expect(/hzHsSync\(\)/.test(fnText(as, "hzPpLayout").body) && !/hzHsPos/.test(as), "a planet card width change re-checks the card (diff-and-skip)");

// ---- host ----
const FNS = ["hzHsSub", "hzHsBuild", "hzHsCmp", "hzHsFx", "hzHsOnAlerts", "hzHsBlgSub", "hzHsOnFin", "hzHsWant", "hzHsSync", "hzHsMaxW", "hzHsCard", "hzHsRestyle", "hzHsDraw", "hzHsLayout", "hzHsReserve", "hzHsVan", "hz26LayoutDefaults"];
let SUBS = [];
global.BSUIDataManager = { Subscribe(n, cb) { SUBS.push(n); } };
global.Point = function (x, y) { this.x = x; this.y = y; };
global.Extensions = { visibleRect: { left: 0, top: 0, right: 1920, bottom: 1080, width: 1920, height: 1080 } };
global.globalToLocal = (p) => p;
let LOG = null;
global.int = (v) => v | 0;
global.Sprite = function () { return clip("sprite", LOG); };
function gfx(log) { return { clear() { log.push("clear"); }, beginFill(c, a) { log.push("fill:" + c.toString(16)); }, drawRoundRect() { log.push("rect"); }, drawCircle() { log.push("dot"); }, endFill() { log.push("end"); } }; }
function clip(name, log) {
	const c = { name, x: 0, y: 0, scaleX: 1, scaleY: 1, kids: [], log: log || [], _v: true, L: [] };
	Object.defineProperty(c, "visible", { get() { return this._v; }, set(v) { this.log.push(name + ".visible=" + v); this._v = v; } });
	c.graphics = gfx(c.log);
	c.addChild = (k) => { c.kids.push(k); k.parent = c; };
	c.getChildByName = (n) => { c.log.push("lookup:" + n); return c.kids.find((k) => k.name === n) || null; };
	c.adds = 0;
	c.addEventListener = (t, f, cap, pri, weak) => { c.adds++; c.L.push({ t, f, cap, pri, weak }); };
	c.removeEventListener = (t, f) => { c.L = c.L.filter((l) => !(l.t === t && l.f === f)); };
	return c;
}
function makeHost(opt) {
	opt = opt || {};
	const log = [];
	LOG = log;
	const h = Object.assign({
		hzHsOn: true, hzShowPlanet: true, hzUserHidden: false, hzArrange: false, hzPpH: 84, hzPpW: 330, hzMargin: 40, hzFades: [], hz43EnvLang: "en",
		hz43ScanHid: false, hz43ScanMk: [], hzEnvP0Ini: false, hzLay: {}, hzBlg: null, log, kids: [], cmp: false, sc: { Hazard: 1, Planet: 1 },
		HorizonHazard_mc: null, hzHsG: null, hzHsTf: null, hzHsLb: null, hzHsSubbed: false, hzHsSeq: 0, hzHsCat: 0, hzHsCatSeq: 0, hzHsWord: "HAZARD", hzHsAlSeq: 0,
		hzHsAlPos: false, hzHsAlTxt: "", hzHsGrn: false, hzHsBlgL: null, hzHsSt: -1, hzHsSrc: -1, hzHsSrcTxt: null, hzHsW: -1, hzHsCm: -1, hzHsH: 46, hzHsShown: false,
		hzHsVanD: null, hzHsCardOn: true, hzWatchStyle: 0, hzLaidOut: true, shows: [], sz: null,
		hzT(p, txt, x, y, w, fs, face, tone) { const t = { text: txt, width: w, x, y, tone, _v: true }; Object.defineProperty(t, "visible", { get() { return this._v; }, set(v) { this._v = v; } }); p.addChild(t); return t; },
		hzUC(s) { return s.toUpperCase(); },
		hzFitText(tf, full) { log.push("text:" + full); tf.text = full; }, hzTW(tf) { return tf.text.length * 8; }, hzTxtTop(tf, y) { tf.y = y; },
		hzIconCol(c) { return c; },
		hzPanel(g, w, h, r, tint, edge) { log.push("panel:" + w + "x" + h + ":" + (edge >>> 0).toString(16)); },
		hzSetSz(c, w, h) { this.sz = { w, h }; },
		hzShow(c, on) { this.shows.push(on); log.push("show:" + on); },
		hzLayHas(k) { return this.hzLay[k] != null; },
		hzPlace(c, x, y) { c.x = x; c.y = y; }, hz34S(k) { return this.sc[k] || 1; }, hz34C(k) { return this.cmp; }, hzPillOn() { return true; },
		hzEnvP0OnAlerts() { this.p0 = (this.p0 || 0) + 1; },
		addChild(k) { this.kids.push(k); k.parent = this; },
		getChildByName(n) { log.push("rootlookup:" + n); return this.kids.find((k) => k.name === n) || null; },
	}, CONST, opt);
	h.HorizonEnv_mc = clip("HorizonEnv_mc", log);
	h.HorizonEnv_mc.y = 40; h.HorizonEnv_mc.x = 40;
	h.HorizonChar_mc = clip("HorizonChar_mc", log);
	h.HorizonEnemy_mc = null; h.HorizonStealth_mc = null; h.HorizonXp_mc = null;
	for (const n of FNS) h[n] = toJs(n).bind(h);
	return h;
}
const FX = (...icons) => [icons.map((s) => ({ sEffectIcon: s })), icons.filter((s) => s !== "HazardEffect_RestoreSoak").length];
const fx = (h, list, word) => { const [a, n] = FX(...list); h.hzHsFx(a, n, word || "HAZARD"); };
const alert = (h, pos, txt) => h.hzHsOnAlerts({ data: { aEnvironmentAlerts: [{ bIsPositive: pos, sAlertText: txt, sEffectIcon: pos ? "HazardEffect_RestoreSoak" : "x" }] } });
const panel = (h) => { const f = h.log.filter((l) => /^panel:/.test(l)); return f.length ? f[f.length - 1] : null; };
const col = (h) => { const p = panel(h); return p ? p.split(":")[2] : null; };
const shown = (h) => h.hzHsSt > 0 && h.hzHsShown;
const text = (h) => h.hzHsTf.text;
const mkBlg = (h) => { const b = clip("BottomLeftGroup_mc", h.log); b.currentLabel = ""; h.kids.push(b); return b; };
const fin = (h, b, label, target) => { b.currentLabel = label; for (const l of b.L.slice()) if (l.t === "AnimationFinished") l.f({ target: target || b }); };

// build
{
	const h = makeHost(); h.hzHsBuild();
	const c = h.HorizonHazard_mc;
	expect(c && c.name === "HorizonHazard_mc" && c.parent === h && h.kids.indexOf(c) >= 0 && c.parent !== h.HorizonEnv_mc, "the card is its own top-level clip (no longer a child of the planet card)");
	expect(!c.visible && h.hzHsLb.tone === "acc" && h.hzHsTf.tone === "main", "built hidden; label in the accent tone, status in the main text tone (style-following hzT texts)");
	h.hzHsBuild();
	expect(h.kids.filter((k) => k.name === "HorizonHazard_mc").length === 1, "built once");
}
// red / green (kept from hs1)
{
	const h = makeHost(); h.hzHsBuild();
	fx(h, ["HazardEffect_Radiation"], "RADIATION");
	expect(shown(h) && col(h) === "c33b29" && text(h) === "RADIATION HAZARD", "red: a hazard listed = red RADIATION HAZARD (state color on the edge)");
	alert(h, false, "Radiation Exposure");
	expect(col(h) === "c33b29" && text(h) === "RADIATION EXPOSURE", "red: the game's alert text is the card text");
	expect(h.log.filter((l) => /^fill:/.test(l)).slice(-2).every((l) => l === "fill:c33b29"), "red: strip and dot in the state color");
	const g = makeHost(); g.hzHsBuild();
	fx(g, ["HazardEffect_RestoreSoak"]);
	expect(shown(g) && col(g) === "379b2c" && text(g) === "SUIT PROTECTION RESTORING", "green: only RestoreSoak listed, the Horizon words");
	alert(g, false, "Extreme Heat");
	expect(col(g) === "c33b29" && text(g) === "EXTREME HEAT", "a newer negative alert turns it red");
	const j = makeHost({ hz43EnvLang: "ja" }); j.hzHsBuild();
	fx(j, ["HazardEffect_Thermal"], "THERMAL"); alert(j, false, "X");
	expect(text(j) === "THERMAL HAZARD", "ja / zhhans: the Horizon word only");
}
// bug (b): green after the hazard effect left the list
{
	// order 1: the effects update drops the hazard, then the positive alert arrives
	const h = makeHost(); h.hzHsBuild(); const b = mkBlg(h);
	fx(h, ["HazardEffect_Thermal"], "THERMAL"); alert(h, false, "Extreme Heat");
	expect(shown(h) && col(h) === "c33b29", "b: red while the hazard is listed");
	fx(h, []);
	expect(!shown(h) && h.shows[h.shows.length - 1] === false, "b: hazard gone, no positive alert yet: hidden");
	alert(h, true, "Suit Protection Reg.");
	expect(shown(h) && col(h) === "379b2c" && text(h) === "SUIT PROTECTION REG.", "b (root cause): a positive alert with no effect listed shows green (hs1 stayed hidden: hzHsCat == 0)");
	expect(b.L.length === 1 && b.L[0].pri === 1 && b.L[0].weak === true && b.L[0].cap === false, "b: the AnimationFinished listener is on the BottomLeftGroup, priority 1, weak");
	fin(h, b, "FadeInEnvAlert_Positive");
	expect(shown(h) && col(h) === "379b2c", "b: the green message's fade-in end keeps green");
	fin(h, b, "FadeOutEnvAlert");
	fin(h, b, "FadeInPlanetInfo");
	expect(shown(h), "b: other animation ends (red fade-out, planet info) do not end green");
	const kid = clip("EnvAlertText", h.log);
	fin(h, b, "FadeOutEnvAlert_Positive", kid);
	expect(shown(h), "b: an event from a child of the group is ignored");
	const n0 = h.log.length;
	fin(h, b, "FadeOutEnvAlert_Positive");
	expect(!shown(h) && !h.hzHsGrn && h.shows[h.shows.length - 1] === false, "b: the vanilla green message ended (FadeOutEnvAlert_Positive): hidden, no timer");
	fin(h, b, "FadeOutEnvAlert_Positive");
	expect(h.log.slice(n0).filter((l) => /^show:|^panel:/.test(l)).length === 1, "b: a repeated end is a no-op");
	// order 2: the positive alert arrives while the hazard is still listed, then the effects update drops it
	const g = makeHost(); g.hzHsBuild(); const gb = mkBlg(g);
	fx(g, ["HazardEffect_Radiation"], "RADIATION");
	alert(g, true, "Suit Protection Reg.");
	expect(shown(g) && col(g) === "379b2c", "b: positive alert newer than the hazard: green");
	fx(g, []);
	expect(shown(g) && col(g) === "379b2c", "b (root cause): the later effects update with nothing listed keeps green (hs1 hid it at once)");
	fin(g, gb, "FadeOutEnvAlert_Positive");
	expect(!shown(g), "b: green ends with the vanilla green message");
	// a new hazard ends the hold
	const k = makeHost(); k.hzHsBuild(); mkBlg(k);
	alert(k, true, "Suit Protection Reg.");
	expect(shown(k) && col(k) === "379b2c", "b: a positive alert alone shows green");
	fx(k, ["HazardEffect_Corrosive"], "CORROSIVE");
	expect(col(k) === "c33b29" && !k.hzHsGrn, "b: a new hazard effect turns it red and ends the hold");
	fx(k, []);
	expect(!shown(k), "b: that hazard gone with no new positive alert: hidden (no stale green)");
	// a negative alert ends the hold; a queued positive message re-arms on its fade-in end
	const q = makeHost(); q.hzHsBuild(); const qb = mkBlg(q);
	alert(q, true, "Suit Protection Reg.");
	alert(q, false, "Suit Protection Depleted");
	expect(!q.hzHsGrn && !shown(q), "b: a newer negative alert with nothing listed ends green");
	fin(q, qb, "FadeInEnvAlert_Positive");
	expect(q.hzHsGrn && shown(q) && col(q) === "379b2c", "b: a queued green message fading in on the watch re-arms green");
	fx(q, ["HazardEffect_Thermal"], "THERMAL"); fin(q, qb, "FadeInEnvAlert_Positive");
	expect(!q.hzHsGrn && col(q) === "c33b29", "b: while a hazard is listed a green fade-in does not re-arm");
	// one listener, one lookup per positive alert
	const r = makeHost(); r.hzHsBuild(); const rb = mkBlg(r);
	alert(r, false, "x");
	expect(rb.L.length === 0 && r.log.every((l) => l !== "rootlookup:BottomLeftGroup_mc"), "b: a negative alert never looks up the group");
	alert(r, true, "a"); alert(r, true, "b"); alert(r, true, "c");
	expect(rb.L.length === 1 && rb.adds === 1 && r.log.filter((l) => l === "rootlookup:BottomLeftGroup_mc").length === 3, "b: one listener whatever the alert count (one getChildByName per positive alert)");
	const nb = clip("BottomLeftGroup_mc", r.log); nb.currentLabel = ""; r.kids.splice(r.kids.indexOf(rb), 1); r.kids.push(nb);
	alert(r, true, "d");
	expect(rb.L.length === 0 && nb.L.length === 1, "b: a new group instance moves the listener");
	const z = makeHost(); z.hzHsBuild();
	alert(z, true, "Suit Protection Reg.");
	expect(shown(z) && z.hzHsBlgL === null, "b: no group found: green still shows (ends on the next negative alert or hazard)");
}
// hidden + skip
{
	const h = makeHost(); h.hzHsBuild();
	fx(h, []);
	expect(!shown(h), "hidden: nothing listed");
	fx(h, ["HazardEffect_Airborne"], "AIRBORNE");
	const n0 = h.log.length;
	for (let i = 0; i < 50; i++) fx(h, ["HazardEffect_Airborne"], "AIRBORNE");
	expect(h.log.length === n0, "skip-unchanged: 50 equal updates make no display write");
	alert(h, false, "Toxic Air"); const n1 = h.log.length;
	alert(h, false, "Toxic Air");
	expect(h.log.length === n1, "skip-unchanged: an equal alert makes no display write");
	const sync = fnText(as, "hzHsSync").body;
	const skip = sync.slice(0, sync.indexOf("{ return; }"));
	expect(!/new |\[\]|\{\}|\+ "|" \+|concat|split|join|toUpperCase|hzUC/.test(skip), "skip path: no allocation before the early return");
	h.hzHsRestyle();
	expect(h.log.length > n1 && h.log.filter((l) => /^panel:/.test(l)).length >= 2, "style apply redraws once");
}
// forms
{
	const h = makeHost(); h.hzHsBuild(); fx(h, ["HazardEffect_Thermal"], "THERMAL");
	expect(/x46:/.test(panel(h)) && h.hzHsLb.visible && h.sz.h === 46, "standard: label + status, 46 units");
	h.cmp = true; h.hzLaidOut = true; h.hzHsSync();
	expect(/x28:/.test(panel(h)) && !h.hzHsLb.visible && h.sz.h === 28 && h.hzLaidOut === false, "compact: one line, 28 units (the old chip height); a height change asks for a layout");
	alert(h, false, "Extreme Heat Exposure Above Safe Limits Detected");
	expect(h.sz.w > 200 && h.sz.w <= 330, "a long text widens the card up to the planet card's width");
	h.hzPpW = 200; h.hzHsSync();
	expect(h.sz.w <= 200, "the card is never wider than the planet card");
	const w = makeHost(); w.hzHsBuild(); w.hzHsWord = "X"; fx(w, ["HazardEffect_Thermal"], "THERMAL");
	expect(w.sz.w >= 160 && w.sz.w <= 330, "width fits the text (160 - planet width)");
}
// ARRANGE preview, show base, off
{
	const h = makeHost(); h.hzHsBuild();
	h.hzArrange = true; h.hzHsSync();
	expect(shown(h) && h.hzHsSrc === 4 && text(h) === "RADIATION HAZARD", "ARRANGE: a red preview so the card can be moved");
	h.hzArrange = false; h.hzHsSync();
	expect(!shown(h), "ARRANGE closed with no hazard: hidden");
	fx(h, ["HazardEffect_Thermal"], "THERMAL");
	h.hzHsCard(false);
	expect(!shown(h) && h.shows[h.shows.length - 1] === false, "the card's base off (hide-all / scanner / HUD hidden): hidden");
	h.hzHsCard(true);
	expect(shown(h), "base back: shown");
	h.hzHsOn = false; h.hzHsSync();
	expect(!shown(h), "HazardStatus=0: hidden");
	const p = makeHost({ hzShowPlanet: false }); p.hzHsBuild(); fx(p, ["HazardEffect_Thermal"], "THERMAL");
	expect(shown(p), "the card no longer needs the planet card (own toggle)");
}
// layout
{
	const h = makeHost(); h.hzHsBuild(); fx(h, ["HazardEffect_Thermal"], "THERMAL");
	h.hzFades.push({ c: h.HorizonEnv_mc, base: 40 });
	h.hzHsLayout();
	expect(h.HorizonHazard_mc.x === 40 && h.HorizonHazard_mc.y === 40 + 84 + 6, "default spot: under the planet card, 6 units gap (where the chip sat)");
	h.HorizonEnv_mc.scaleY = 1.2; h.sc.Hazard = 1.2; h.hzHsLayout();
	expect(Math.abs(h.HorizonHazard_mc.y - (40 + 84 * 1.2 + 6 * 1.2)) < 1e-9, "default spot follows the planet card's and its own size");
	h.hzFades[0].base = 1000; h.HorizonEnv_mc.scaleY = 1; h.sc.Hazard = 1; h.hzHsLayout();
	expect(h.HorizonHazard_mc.y === 1000 - 6 - 46, "near the bottom edge: above the planet card");
	h.hzLay.Hazard = { x: 0, y: 0 }; h.HorizonHazard_mc.y = 555; h.hzHsLayout();
	expect(h.HorizonHazard_mc.y === 555, "placed in ARRANGE: the layout keeps its spot");
	const r = makeHost(); r.hzHsBuild();
	expect(r.hzHsReserve() === 6 + 46, "the Character card makes room for the card at its default spot");
	r.cmp = true;
	expect(r.hzHsReserve() === 6 + 28, "compact: less room");
	r.hzLay.Hazard = {};
	expect(r.hzHsReserve() === 0, "card placed: no room kept");
	r.hzLay = { Planet: {} };
	expect(r.hzHsReserve() === 0, "planet placed: no room kept");
	r.hzLay = {}; r.hzHsOn = false;
	expect(r.hzHsReserve() === 0, "HazardStatus=0: no room kept");
	r.hzHsOn = true; r.cmp = false; r.sc.Hazard = 1.5; r.sc.Planet = 0.75;
	expect(Math.abs(r.hzHsReserve() - 52 * 1.5 / 0.75) < 1e-9, "the room is in planet-card units (the caller multiplies by the planet factor)");
}
// vanilla text (style 0 only)
{
	const h = makeHost(); h.hzHsBuild();
	h.hzBlg = clip("BottomLeftGroup_mc", h.log); const t = clip("EnvAlertText", h.log); h.hzBlg.addChild(t);
	fx(h, ["HazardEffect_Corrosive"], "CORROSIVE"); alert(h, false, "Corrosive");
	expect(!t.visible && h.hzHsVanD === t, "style 0, card shown: the vanilla EnvAlertText is hidden (no duplicate text)");
	h.hzHsOn = false; h.hzHsLayout();
	expect(t.visible && h.hzHsVanD === null, "off: the vanilla text comes back");
	h.hzHsOn = true; h.hzHsLayout();
	expect(!t.visible, "on again: hidden again");
	h.hzArrange = true; h.hzHsSync();
	expect(t.visible, "ARRANGE preview: the vanilla text is given back");
	h.hzArrange = false; h.hzHsSync();
	const s = makeHost({ hzWatchStyle: 3 }); s.hzHsBuild();
	s.hzBlg = clip("BottomLeftGroup_mc", s.log); const t2 = clip("EnvAlertText", s.log); s.hzBlg.addChild(t2);
	fx(s, ["HazardEffect_Thermal"], "THERMAL"); alert(s, false, "Heat");
	expect(t2.visible && s.log.every((l) => !/EnvAlertText\.visible/.test(l)), "watch styles 1 - 4: the vanilla text is never touched");
	const p = makeHost({ hzEnvP0Ini: true }); p.hzHsBuild(); alert(p, false, "x");
	expect(p.p0 === 1, "the shared listener forwards to the probe when EnvAlertLog is on");
	SUBS = []; p.hzHsSub(); p.hzHsSub();
	expect(SUBS.length === 1 && SUBS[0] === "EnvironmentAlertsData", "one EnvironmentAlertsData subscription");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("hazard card: " + passed + " ok, all passed");
