// Hazard Status chip tests. Run: node tests/hazard_status_test.js
// Runs the production AS functions (types stripped) on a small host and checks the source:
//  red / green / hidden states, diff-and-skip (no display write on an unchanged update), on / off, the vanilla
//  EnvAlertText hide (only what this hid is given back; off never touches it), the bottom-edge flip, the Character
//  offset, the setting plumbing (one new key), no sound / timer / frame / search code, and the 0.43.2.0 base equality.
// Author: Moragar. Last modified: 2026-11-13.
"use strict";

const fs = require("fs");
const path = require("path");
const cp = require("child_process");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const ini = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8").replace(/\r\n/g, "\n");
const gitShow = (f) => { try { return cp.execFileSync("git", ["show", "cda2af5:" + f], { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "ignore"] }).replace(/\r\n/g, "\n"); } catch (e) { return null; } };
const base = gitShow("actionscript/horizon_block.as");
const baseIni = gitShow("Interface/HorizonUI/HorizonUI.default.ini");

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
		.replace(/([\w.]+) as Array/g, "(Array.isArray($1) ? $1 : null)")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/\bHZ_HS_(\w+)/g, "this.HZ_HS_$1");
	return new Function(...params, body);
}

const B0 = "      // ===================== Hazard Status chip (0.43.2.0 test) =====================\n";
const B1 = "      // ===================== end Hazard Status chip =====================\n\n";
const i0 = as.indexOf(B0), i1 = as.indexOf(B1);
expect(i0 > 0 && i1 > i0 && count(as, B0) === 1 && count(as, B1) === 1, "one Hazard Status section");
const sec = as.slice(i0, i1 + B1.length);
const code = sec.replace(/\/\/.*$/gm, "");   // the chip code without its comments
const CONST = {};
{ const re = /private static const (HZ_HS_\w+):\w+ = ([^;]+);/g; let m; while ((m = re.exec(sec))) CONST[m[1]] = Number(m[2]); }
expect(CONST.HZ_HS_RED === 0xC33B29 && CONST.HZ_HS_GRN === 0x379B2C, "the two colors are the vanilla watch red / green");
expect(!/0xF2A93B|HZ_AMB|HZ_YELLOW|\bWARN\b|"SAFE"|DANGER/.test(sec), "no amber / yellow, no WARN / SAFE / DANGER in the chip");

// ---- host ----
const FNS = ["hzHsSub", "hzHsBuild", "hzHsFx", "hzHsOnAlerts", "hzHsWant", "hzHsSync", "hzHsDraw", "hzHsPos", "hzHsLayout", "hzHsReserve", "hzHsVan", "hz26LayoutDefaults", "hz26LayoutAfter"];
let SUBS = [];
global.BSUIDataManager = { Subscribe(n, cb) { SUBS.push(n); } };
global.Point = function (x, y) { this.x = x; this.y = y; };
global.Extensions = { visibleRect: { left: 0, top: 0, right: 1920, bottom: 1080, width: 1920, height: 1080 } };
global.globalToLocal = (p) => p;
let LOG = null;
global.int = (v) => v | 0;
global.Sprite = function () { return clip("sprite", LOG); };
function gfx(log) { return { clear() { log.push("clear"); }, beginFill(c, a) { log.push("fill:" + c.toString(16)); }, drawRoundRect() { log.push("rect"); }, endFill() { log.push("end"); } }; }
function clip(name, log) {
	const c = { name, x: 0, y: 0, scaleX: 1, scaleY: 1, kids: [], log: log || [], _v: true };
	Object.defineProperty(c, "visible", { get() { return this._v; }, set(v) { this.log.push(name + ".visible=" + v); this._v = v; } });
	c.graphics = gfx(c.log);
	c.addChild = (k) => { c.kids.push(k); k.parent = c; };
	c.getChildByName = (n) => { c.log.push("lookup:" + n); return c.kids.find((k) => k.name === n) || null; };
	return c;
}
function makeHost(opt) {
	opt = opt || {};
	const log = [];
	LOG = log;
	const h = Object.assign({
		hzHsOn: true, hzShowPlanet: true, hzUserHidden: false, hzPpH: 84, hzPpW: 330, hzMargin: 40, hzFades: [], hz43EnvLang: "en",
		hz43ScanHid: false, hz43ScanMk: [], hzEnvP0Ini: false, hzLay: {}, hzHeaderStyle: 0, hzBlg: null, log,
		hzHsChip: null, hzHsTf: null, hzHsSubbed: false, hzHsSeq: 0, hzHsCat: 0, hzHsCatSeq: 0, hzHsWord: "HAZARD", hzHsAlSeq: 0,
		hzHsAlPos: false, hzHsAlTxt: "", hzHsSt: -1, hzHsSrc: -1, hzHsSrcTxt: null, hzHsW: -1, hzHsUp: false, hzHsVanD: null,
		hzT(p, txt) { const t = { text: txt, width: 0, x: 0, y: 0 }; p.addChild(t); return t; },
		hzTxtObj() { return {}; }, hzApplyFmt() {}, hzUC(s) { return s.toUpperCase(); },
		hzFitText(tf, full) { log.push("text:" + full); tf.text = full; }, hzTW(tf) { return tf.text.length * 8; },
		hzLayHas(k) { return this.hzLay[k] != null; },
		hzPlace(c, x, y) { c.x = x; c.y = y; }, hz34S() { return 1; }, hz34C() { return false; }, hzPillOn() { return this.hzPlanPill != null; },
		hzEnvP0OnAlerts() { this.p0 = (this.p0 || 0) + 1; },
	}, CONST, opt);
	h.HorizonEnv_mc = clip("HorizonEnv_mc", log);
	h.hzPlanPill = clip("hzPlanPill", log);
	h.HorizonChar_mc = clip("HorizonChar_mc", log);
	h.HorizonEnemy_mc = null; h.HorizonStealth_mc = null; h.HorizonXp_mc = null;
	for (const n of FNS) h[n] = toJs(n).bind(h);
	return h;
}
const FX = (...icons) => [icons.map((s) => ({ sEffectIcon: s })), icons.filter((s) => s !== "HazardEffect_RestoreSoak").length];
const fx = (h, list, word) => { const [a, n] = FX(...list); h.hzHsFx(a, n, word || "HAZARD"); };
const alert = (h, pos, txt) => h.hzHsOnAlerts({ data: { aEnvironmentAlerts: [{ bIsPositive: pos, sAlertText: txt, sEffectIcon: "x" }] } });
const fill = (h) => { const f = h.log.filter((l) => /^fill:/.test(l)); return f.length ? f[f.length - 1].slice(5) : null; };
const chipText = (h) => h.hzHsTf.text;

// red
{
	const h = makeHost(); h.hzHsBuild();
	expect(h.hzHsChip && h.hzHsChip.parent === h.HorizonEnv_mc && h.hzHsChip.y === 84 + 6, "the chip is a child of the planet card, 6 units under it");
	fx(h, ["HazardEffect_Radiation"], "RADIATION");
	expect(h.hzHsChip.visible && fill(h) === "c33b29" && chipText(h) === "RADIATION HAZARD", "red: a hazard listed, no alert yet = red RADIATION HAZARD");
	alert(h, false, "Radiation Exposure");
	expect(fill(h) === "c33b29" && chipText(h) === "RADIATION EXPOSURE", "red: the game's alert text is the chip text");
}
// green
{
	const h = makeHost(); h.hzHsBuild();
	fx(h, ["HazardEffect_Thermal"], "THERMAL");
	alert(h, true, "Suit Protection Restoring");
	expect(fill(h) === "379b2c" && chipText(h) === "SUIT PROTECTION RESTORING", "green: a positive alert newer than the effects = green with its text");
	fx(h, ["HazardEffect_RestoreSoak"]);
	expect(fill(h) === "379b2c" && h.hzHsChip.visible, "green: only RestoreSoak listed stays green");
	fx(h, []);
	expect(!h.hzHsChip.visible, "green ends when the game drops RestoreSoak (event, no timer)");
	const g = makeHost(); g.hzHsBuild();
	fx(g, ["HazardEffect_RestoreSoak"]);
	expect(fill(g) === "379b2c" && chipText(g) === "SUIT PROTECTION RESTORING", "green without an alert: the Horizon words");
	alert(g, false, "Extreme Heat");
	expect(fill(g) === "c33b29" && chipText(g) === "EXTREME HEAT", "a newer negative alert turns it red");
	fx(g, ["HazardEffect_Thermal"], "THERMAL");
	expect(fill(g) === "c33b29" && chipText(g) === "EXTREME HEAT", "the matching alert text is kept after the effects change");
	const j = makeHost({ hz43EnvLang: "ja" }); j.hzHsBuild();
	fx(j, ["HazardEffect_Thermal"], "THERMAL"); alert(j, false, "X");
	expect(chipText(j) === "THERMAL HAZARD", "ja / zhhans: the Horizon word only");
}
// hidden + skip
{
	const h = makeHost(); h.hzHsBuild();
	fx(h, []);
	expect(!h.hzHsChip.visible, "hidden: nothing listed");
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
	expect(/private function hzHsSync[\s\S]*?if\(st == this\.hzHsSt && src == this\.hzHsSrc && stx == this\.hzHsSrcTxt/.test(sec), "diff key = state, text source, text ref");
}
// on / off + vanilla text
{
	const h = makeHost(); h.hzHsBuild();
	h.hzBlg = clip("BottomLeftGroup_mc", h.log); const t = clip("EnvAlertText", h.log); h.hzBlg.addChild(t);
	fx(h, ["HazardEffect_Corrosive"], "CORROSIVE"); alert(h, false, "Corrosive");
	expect(!t.visible && h.hzHsVanD === t, "on: the vanilla EnvAlertText is hidden (no duplicate text)");
	h.hzHsOn = false; h.hzHsLayout();
	expect(!h.hzHsChip.visible && t.visible && h.hzHsVanD === null, "off: the chip hides and the vanilla text comes back");
	const n0 = h.log.length;
	alert(h, false, "Corrosive"); fx(h, ["HazardEffect_Corrosive"], "CORROSIVE"); h.hzHsLayout(); h.hzHsVan();
	expect(h.log.slice(n0).every((l) => !/EnvAlertText|lookup/.test(l)), "off: alerts / effects / layout never touch the vanilla text");
	h.hzHsOn = true; h.hzHsLayout();
	expect(h.hzHsChip.visible && !t.visible, "on again: chip back, vanilla text hidden");
	t._v = true; h.hzHsVanD = null;   // the game shows it again / a new instance
	h.hz43ScanHid = true; h.hzHsVan(); h.hzHsOn = false; h.hzHsVan();
	expect(!t.visible && h.hz43ScanMk.indexOf(t) >= 0, "off mid-scan: the scan close gives the text back (no flash during the scan)");
	const g = makeHost({ hzHsOn: false }); g.hzHsBuild();
	g.hzBlg = clip("BottomLeftGroup_mc", g.log); const t2 = clip("EnvAlertText", g.log); g.hzBlg.addChild(t2);
	fx(g, ["HazardEffect_Thermal"], "THERMAL"); alert(g, false, "Heat"); g.hzHsLayout();
	expect(t2.visible && !g.hzHsChip.visible && g.log.every((l) => !/EnvAlertText/.test(l)), "HazardStatus=0 from the start: the vanilla text is never touched");
	const u = makeHost(); u.hzHsBuild(); u.hzBlg = clip("BottomLeftGroup_mc", u.log); const t3 = clip("EnvAlertText", u.log); u.hzBlg.addChild(t3);
	u.hzHsVan(); u.hzUserHidden = true; u.hzHsVan();
	expect(t3.visible, "F11 hide-all gives the vanilla text back");
	const p = makeHost({ hzEnvP0Ini: true }); p.hzHsBuild(); alert(p, false, "x");
	expect(p.p0 === 1, "the shared listener forwards to the probe when EnvAlertLog is on");
	SUBS = []; p.hzHsSub(); p.hzHsSub();
	expect(SUBS.length === 1 && SUBS[0] === "EnvironmentAlertsData", "one EnvironmentAlertsData subscription");
}
// layout flip + Character offset
{
	const h = makeHost(); h.hzHsBuild();
	h.HorizonEnv_mc.y = 40; h.hzHsLayout();
	expect(!h.hzHsUp && h.hzHsChip.y === 90, "layout: top of the screen = under the card");
	h.HorizonEnv_mc.y = 1080 - 40 - 84 - 10; h.hzHsLayout();
	expect(h.hzHsUp && h.hzHsChip.y === -(6 + 28), "layout: at the bottom edge the chip flips above the card");
	h.HorizonEnv_mc.y = 40; h.hzFades = [{ c: h.HorizonEnv_mc, base: 1000 }]; h.hzHsLayout();
	expect(h.hzHsUp, "layout: the fade base y counts (not the faded y)");
	const c = makeHost();
	c.hz26LayoutDefaults(40, 40, 960, 20, 1);
	expect(c.HorizonChar_mc.y === 40 + (84 + 10 + 34), "Character: moves down 34 units while HazardStatus is on");
	c.hzHsOn = false; c.hz26LayoutDefaults(40, 40, 960, 20, 1);
	expect(c.HorizonChar_mc.y === 40 + 94, "Character: the 0.43.2.0 spot with HazardStatus off");
	c.hzHsOn = true; c.hzLay = { Planet: { x: 1 } }; c.hz26LayoutDefaults(40, 40, 960, 20, 1);
	expect(c.HorizonChar_mc.y === 40 + 94, "Character: no room kept when the planet card was moved in ARRANGE");
	expect(as.indexOf("top + (eh + 10 + this.hzHsReserve()) * s") > 0, "Character offset is in hz26LayoutDefaults");
}
// event-driven, no sound
{
	for (const bad of ["enterFrame", "ENTER_FRAME", "setInterval", "setTimeout", "Timer", "getTimer", "addEventListener", "getChildAt", "numChildren", "hzFindByName", "PlayMenuSound", "PlaySound", "Sound", "gotoAndPlay", "hzFrameN"]) {
		expect(code.indexOf(bad) < 0, "chip code has no " + bad);
	}
	expect(count(code, "getChildByName") === 1, "one direct getChildByName (the known group, events only)");
	if (base) {
		for (const s of ["PlayMenuSound", "PlaySound", "Sound(", "ENTER_FRAME", "new Timer", "setTimeout", "setInterval"]) expect(count(as, s) === count(base, s), "no new " + s + " anywhere in the HUD block");
	}
	const callers = ["this.hzHsFx(", "this.hzHsLayout()", "this.hzHsBuild()", "this.hzHsSub()"];
	expect(fnText(as, "hzOnEnvEffects").body.indexOf("this.hzHsFx(a,n,word)") > 0 && fnText(as, "hz26LayoutAfter").body.indexOf("this.hzHsLayout()") > 0 && callers.every((c) => count(as, c) >= 1), "callers: effects event, layout, build, subscribe");
	expect(fnText(as, "hzOnFrame").body.indexOf("hzHs") < 0 && fnText(as, "hzTickFades").body.indexOf("hzHs") < 0, "nothing in the frame tick");
}
// settings
{
	const keys = (src) => { const m = /HZ_SET_DEF:Object = (\{[^;]*\});/.exec(src); return Object.keys(JSON.parse(m[1])); };
	const iniKeys = (t) => t.split("\n").filter((l) => /^\w+=/.test(l)).map((l) => l.split("=")[0]);
	if (base) {
		const a = keys(as), b = keys(base);
		expect(JSON.stringify(a.filter((k) => b.indexOf(k) < 0)) === '["HazardStatus"]' && b.every((k) => a.indexOf(k) >= 0), "HZ_SET_DEF: only HazardStatus added");
		expect(JSON.parse(/HZ_SET_DEF:Object = (\{[^;]*\});/.exec(as)[1]).HazardStatus === 1, "HZ_SET_DEF HazardStatus = 1");
	}
	if (baseIni) {
		const a = iniKeys(ini).filter((k) => k !== "GameCardTitle"), b = iniKeys(baseIni);   // GameCardTitle: the separate add-on (tests/game_title_test.js)
		expect(JSON.stringify(a.filter((k) => b.indexOf(k) < 0)) === '["HazardStatus"]' && a.length === b.length + 1, "default INI: only HazardStatus added");
	}
	expect(/\[Effects\][^\[]*\nEdgePulse=1\n; Hazard status chip[^\n]*\nHazardStatus=1\n/.test(ini), "default INI [Effects] HazardStatus=1 after EdgePulse");
	expect(/"HazardAlert":1/.test(as) && count(as, '{"k":"HazardAlert","l":"HAZARD ALERT","t":"b"}') === 1, "HazardAlert unchanged");
	expect(as.indexOf('{"k":"EdgePulse","l":"LOW HEALTH / O2 SCREEN-EDGE PULSE","t":"b","h":"WARNINGS"},{"k":"HazardStatus","l":"HAZARD STATUS","t":"b"') > 0, "F11 EFFECTS > WARNINGS > HAZARD STATUS row");
	expect(fnText(as, "hz26Ini").body.indexOf('case "hazardstatus": this.hzHsOn = bv;') > 0, "INI read: [Effects] HazardStatus");
	expect(fnText(as, "hz26SetCur").body.indexOf("o.HazardStatus = this.hzHsOn;") > 0 && fnText(as, "hz26SetLive").body.indexOf("p.HazardStatus") > 0, "F11 current / live");
	const lines = [];
	toJs("hz26IniLines").call({ hzB: (v) => (v ? "1" : "0"), hzWatchStyle: 0 }, lines, { HazardStatus: true, EdgePulse: true });
	const i = lines.indexOf("HazardStatus=1"), e = lines.indexOf("[Effects]");
	expect(i > e && e >= 0 && lines.indexOf("EdgePulse=1") === i - 2, "writer: [Effects] HazardStatus (presets and user.ini)");
	const lines0 = []; toJs("hz26IniLines").call({ hzB: (v) => (v ? "1" : "0"), hzWatchStyle: 0 }, lines0, { HazardStatus: false });
	expect(lines0.indexOf("HazardStatus=0") > 0, "writer: off is saved as 0");
	const hz = fs.readFileSync(path.join(root, "src", "main.cpp"), "utf8");
	expect(/kVersion\s*=\s*"0\.42\.0"/.test(hz), "HZF::kVersion stays 0.42.0");
}
// base equality: taking out the chip hunks gives the 0.43.2.0 source byte for byte
if (base) {
	let s = as.replace(sec, "");
	const HUNKS = [
		["         try { this.hzHsFx(a,n,word); } catch(eHs:Error) { }   // Hazard Status chip (diff-and-skip)\n", ""],
		["         try { this.hzHsSub(); } catch(eHsS:Error) { }   // Hazard Status: EnvironmentAlertsData (the only listener of it)\n", ""],
		["         try { this.hzHsBuild(); } catch(eHsB:Error) { }   // Hazard Status chip (a child of the planet card)\n", ""],
		["         try { this.hzHsPos(); } catch(eHsP:Error) { }   // Hazard Status chip under / above the card\n", ""],
		["         try { this.hzHsLayout(); } catch(errHs:Error) { }   // Hazard Status: flip at the bottom edge, on / off, the vanilla EnvAlertText\n", ""],
		["         try { this.hzHsVan(); } catch(eHsU:Error) { }   // Hazard Status: hide-all gives the vanilla EnvAlertText back\n", ""],
		["         this.hzHsSub();   // the one EnvironmentAlertsData listener (Hazard Status); it forwards to hzEnvP0OnAlerts\n", "         try { BSUIDataManager.Subscribe(\"EnvironmentAlertsData\",this.hzEnvP0OnAlerts); } catch(eS:Error) { }\n"],
		["(eh + 10 + this.hzHsReserve()) * s); }   // Hazard Status: room for the chip", "(eh + 10) * s); }"],
		[',{"k":"HazardStatus","l":"HAZARD STATUS","t":"b","note":"Red / green chip under the planet card while a hazard hurts you or suit protection restores"}', ""],
		['"HazardStatus":1,', ""],
		['            case "hazardstatus": this.hzHsOn = bv; this.hzLaidOut = false; break;\n', ""],
		["         o.HazardStatus = this.hzHsOn;\n", ""],
		["         if(p.HazardStatus != undefined && this.hzHsOn != Boolean(p.HazardStatus)) { this.hzHsOn = Boolean(p.HazardStatus); this.hzLaidOut = false; }\n", ""],
		['         a.push("; Hazard status chip under the planet card: red while a hazard hurts you, green while suit protection restores");\n         a.push("HazardStatus=" + this.hzB(p.HazardStatus));\n', ""],
	];
	// the separate info message title add-on (tests/game_title_test.js), when it is in this tree
	const ADDON = [
		['["ReactionCard","b",1,0,1,"comms"],["GameCardTitle","i",0,0,3,"comms"],', '["ReactionCard","b",1,0,1,"comms"],'],
		['"ReactionCard":1,"GameCardTitle":0,', '"ReactionCard":1,'],
	];
	for (const [a, b] of ADDON) s = s.replace(a, b);
	s = s.replace(/\n[ ]+"GameCardTitle":"[^\n]*",(?=\n)/g, "").replace(/\n[ ]+\{"k":"GameCardTitle"[^\n]*\},(?=\n)/, "");
	let ok = true;
	for (const [a, b] of HUNKS) { if (count(s, a) !== 1) { ok = false; console.error("hunk count " + count(s, a) + ": " + a.slice(0, 60)); } s = s.replace(a, b); }
	expect(ok && s === base, "chip hunks removed = the 0.43.2.0 source (cda2af5) byte for byte");
} else console.log("skip base equality (git or cda2af5 not available)");

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("hazard status: " + passed + " ok, all passed");
