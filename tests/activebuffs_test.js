// Active Buffs removal regression (0.43.3.0, batch j). Run: node tests/activebuffs_test.js
// The Active Buffs card of the 0.43.3.1 / 0.43.3.2 test builds is removed. This test checks, on the production source:
//  1. nothing of the card is left: no hzAb* code, no HorizonBuffs_mc, no PlayerStatusData subscription, no ARRANGE key,
//     no F11 > CARDS / RULES row, no (i) popup text, no defaults (HZ_SET_DEF, HorizonUI.default.ini), no C++ key;
//  2. the Hazard Status card and the Afflictions card (injuries and hazards, PersonalEffectsData feed) are still wired:
//     build, subscription, feed handler, visibility, ARRANGE, INI keys, the 30-frame hold slot;
//  3. leftover [ActiveBuffs] / Buffs* keys in an existing user.ini or preset are ignored: the production INI key chain
//     (hzOnIni switch, hz30IniPos, hz34Ini, hz26Ini, hz27Ini, hz30Ini, hzIniLayoutKey; types stripped) runs them with
//     no throw, no match and no state write, while the same chain still applies Hazard / Afflictions keys;
//  4. edge-only: no ENTER_FRAME listener, Timer or interval was added.
// The C++ side (save / preset apply with leftover keys) is covered by tests/preset_list_test.cpp.
// Author: Moragar. Last modified: 2026-11-19 (batch j).
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
const hasFn = (name) => new RegExp("(?:private|public) function " + name + "\\(").test(as);
const count = (s, sub) => s.split(sub).length - 1;
const code = as.replace(/\/\/[^\n]*/g, "");   // comments out: the removal note may name what was removed
const arrOf = (name) => JSON.parse(new RegExp("private static const " + name + ":Array = (\\[[^;]*\\]);").exec(as)[1]);

// ---- 1. the card is gone ----
{
	expect(!/hzAb\w*|HZ_AB_\w*|HorizonBuffs_mc/.test(code), "no hzAb* function, field or call, no HZ_AB_* constant, no HorizonBuffs_mc");
	expect(!/PlayerStatusData/.test(code), "no PlayerStatusData subscription or handler (the card's only feed)");
	expect(!/"Buffs"|BuffsRule|hzRuleBuffs|"ActiveBuffs"|BuffsShow|BuffsTimers|BuffsHideEmpty|BuffsMax|BuffsPermanent|BuffsCompact|BuffsScale/.test(code), "no Active Buffs key anywhere in the code");
	const lk = arrOf("HZ_LAY_KEYS"), ln = arrOf("HZ_LAY_NAMES");
	expect(lk.indexOf("Buffs") < 0 && ln.indexOf("ACTIVE BUFFS") < 0 && lk.length === ln.length, "ARRANGE CARDS: no Buffs key or ACTIVE BUFFS name (" + lk.length + " keys, " + ln.length + " names)");
	expect(lk.indexOf("Hazard") >= 0 && lk.indexOf("Afflictions") >= 0 && ln.indexOf("HAZARD STATUS") >= 0, "ARRANGE CARDS keeps Hazard and Afflictions");
	const c34 = /private static const HZ34_CARDS:Array = (\[[^;]*\]);/.exec(as)[1];
	expect(c34.indexOf("Buffs") < 0 && c34.indexOf('["Hazard",true]') >= 0 && c34.indexOf('["Afflictions",false]') >= 0, "[Cards] size / form list: no Buffs, Hazard and Afflictions kept");
	const c40 = /private static const HZ40_CARDS:Array = (\[[^;]*\]);/.exec(as)[1];
	expect(c40.indexOf("Buffs") < 0 && c40.indexOf("HorizonAffl_mc") >= 0, "the card list for the global hide: no Buffs card, Afflictions kept");
	const rules = fnText(as, "hzSetRows").body;
	expect(rules.indexOf("BuffsRule") < 0 && rules.indexOf("ACTIVE BUFFS") < 0 && rules.indexOf('"AfflictionsRule"') >= 0, "F11 > RULES: no ACTIVE BUFFS row, AFFLICTIONS row kept");
	const cards = fnText(as, "hz34CardRows").body;
	expect(!/Buffs|BUFFS/.test(cards) && cards.indexOf('"HazardStatus"') >= 0 && cards.indexOf('"ShowAfflictions"') >= 0, "F11 > CARDS: no ACTIVE BUFFS section or row, HAZARD STATUS and AFFLICTIONS kept");
	const info = /private static const HZ35_INFO:Object = (\{[\s\S]*?\});\n/.exec(as)[1];
	expect(!/Buffs|BUFFS|Active Buffs/i.test(info.replace(/buffs are|buff and|a buff/gi, "")), "F11 (i) popups: no Active Buffs text");
	expect(fnText(as, "hzLayClips").body.indexOf("Buffs") < 0 && fnText(as, "hzArrList").body.indexOf("Buffs") < 0 && fnText(as, "hzArrShowAll").body.indexOf("Buffs") < 0, "ARRANGE: no Buffs clip, list entry or show-all entry");
	const sd = JSON.parse(/HZ_SET_DEF:Object = (\{[^;]*\});/.exec(as)[1]);
	expect(Object.keys(sd).every((k) => !/Buffs/.test(k)) && sd.HazardStatus === 1 && sd.ShowAfflictions === 1 && sd.AfflictionsRule === 6, "HZ_SET_DEF (presets / F11 DEFAULTS): no Active Buffs default; HazardStatus 1, ShowAfflictions 1, AfflictionsRule 6 kept");
	expect(!/\[ActiveBuffs\]|Buffs[A-Za-z]*=|ActiveBuffs=|Active Buffs/i.test(ini), "HorizonUI.default.ini: no [ActiveBuffs] section, Buffs* key or Active Buffs comment");
	expect(/^\[Effects\]$/m.test(ini) && /^HazardStatus=1$/m.test(ini) && /^ShowAfflictions=1$/m.test(ini) && /^HazardScale=-1$/m.test(ini) && /^AfflictionsScale=-1$/m.test(ini), "HorizonUI.default.ini keeps HazardStatus, ShowAfflictions, HazardScale and AfflictionsScale");
	const dbg = fnText(as, "hz26DbgText").body;
	expect(dbg.indexOf('"ActiveBuffs"') < 0 && dbg.indexOf('"PersonalEffectsData"') >= 0, "debug log key list: no ActiveBuffs, PersonalEffectsData kept");
	let srcHit = [];
	const srcDir = path.join(root, "src");
	if (fs.existsSync(srcDir)) for (const f of fs.readdirSync(srcDir)) {
		const p = path.join(srcDir, f);
		if (fs.statSync(p).isFile() && /Buffs|ActiveBuffs/.test(fs.readFileSync(p, "utf8"))) srcHit.push(f);
	}
	expect(srcHit.length === 0, "C++ (src/): no Active Buffs key" + (srcHit.length ? ": " + srcHit.join(",") : ""));
}

// ---- 2. Hazard Status and Afflictions are still wired ----
{
	const build = fnText(as, "hzBuildEnv").body;
	expect(/try \{ this\.hzHsBuild\(\); \}/.test(build), "the Hazard Status card is still built on mount");
	expect(count(code, 'BSUIDataManager.Subscribe("PersonalEffectsData",this.hzOnPersonalEffects);') === 1, "the Afflictions feed: one PersonalEffectsData subscription, to hzOnPersonalEffects");
	const pe = fnText(as, "hzOnPersonalEffects").body;
	expect(/this\.hzJoinEffects\(e\.data\.aPersonalEffects as Array,true\)/.test(pe) && /this\.hzEnvAff\.text = t;/.test(pe) && /this\.hzAfSetPers\(e\.data\.aPersonalEffects as Array\);/.test(pe), "hzOnPersonalEffects still joins the effects text and feeds the Afflictions card (hzAfSetPers)");
	expect(pe.split("\n").filter((l) => l.trim().length && l.trim() !== "{" && l.trim() !== "}").length === 5 && pe.indexOf("hzAb") < 0, "hzOnPersonalEffects is the five-line Afflictions handler (fonts, log, join, text, hzAfSetPers), nothing else");
	const vis = fnText(as, "hzRefreshVisibility").body;
	expect(/hzHs/.test(vis) && /HorizonAffl_mc/.test(vis), "visibility still drives the Hazard Status and Afflictions cards");
	const clk = fnText(as, "hzPpClock").body;
	expect(/if\(this\.hzHsHoldT >= 0\) \{ try \{ this\.hzHsHoldTick\(\); \}/.test(clk) && clk.indexOf("hzAb") < 0, "the 30-frame slot hzPpClock keeps the Hazard Status hold end, no Active Buffs countdown");
	expect(/try \{ this\.hzHsLayout\(\); \}/.test(fnText(as, "hz26LayoutAfter").body), "the Hazard Status layout still runs after the main layout");
	expect(/case "hazardstatus": this\.hzHsOn = bv;/.test(fnText(as, "hz26Ini").body), "[Effects] HazardStatus is still read");
	for (const f of ["hzHsBuild", "hzHsLayout", "hzHsHoldTick", "hzAfSetPers"]) expect(hasFn(f), f + " is present");
	expect(fnText(as, "hzLayClips").body.indexOf('case "Hazard"') >= 0 && fnText(as, "hzLayClips").body.indexOf('case "Afflictions"') >= 0, "ARRANGE still moves the Hazard and Afflictions cards");
}

// ---- 3. leftover keys are ignored by the production INI key chain ----
global.int = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)) | 0; };
const STATIC = ["HZ_LAY_KEYS", "HZ34_CARDS", "HZ_FOL_PAL"];
function toJs(name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
	let b = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)");
	for (const k of STATIC) b = b.replace(new RegExp("([^.\\w\"])" + k + "\\b", "g"), "$1this." + k);
	return new Function(...params, b);
}
function host() {
	const writes = [];
	const calls = [];
	const base = {
		HZ_LAY_KEYS: arrOf("HZ_LAY_KEYS"),
		HZ34_CARDS: JSON.parse(/private static const HZ34_CARDS:Array = (\[[^;]*\]);/.exec(as)[1]),
		HZ_FOL_PAL: [0, 1, 2, 3],
		hzLay: {}, hz34Sc: {}, hz34Cm: {},
		hz34ScClamp: (n) => (isNaN(n) || n < 0 ? -1 : Math.max(0.6, Math.min(1.6, n))),
		hz34CmClamp: (n) => (isNaN(n) ? -1 : Math.max(-1, Math.min(1, int(n)))),
	};
	for (const n of ["hz30IniPos", "hz34Ini", "hz26Ini", "hz27Ini", "hz30Ini", "hzIniLayoutKey", "hzVehIni", "hzQmIni"]) base[n] = toJs(n);
	const known = new Set(Object.keys(base));
	const h = new Proxy(base, {
		get(t, k) {
			if (k in t) return t[k];
			if (typeof k === "string" && /^hz/.test(k) && hasFn(k)) return (...a) => { calls.push(k); return undefined; };
			return undefined;
		},
		set(t, k, v) { writes.push(String(k)); t[k] = v; return true; },
	});
	return { h, writes, calls, base };
}
// the hzOnIni switch labels (a leftover key must not match one; then it goes to the default chain)
const onIni = fnText(as, "hzOnIni").body;
const labels = new Set((onIni.match(/case "([a-z0-9]+)":/g) || []).map((s) => s.slice(6, -2)));
function applyKey(hx, k, v) {
	// the hzOnIni per-line path (types stripped): positional value, the switch, then the default chain
	const bv = v === "1" || v.toLowerCase() === "true";
	const nv = Number(v === "" ? NaN : v);
	if (isNaN(nv) && hx.h.hz30IniPos(k, v)) return "pos";
	if (labels.has(k)) return "switch";
	if (hx.h.hz34Ini(k, nv)) return "hz34";
	if (hx.h.hz26Ini(k, bv, nv)) return "hz26";
	hx.h.hzIniLayoutKey(k, nv);
	return "layout";
}
function snap(b) { return JSON.stringify({ lay: b.hzLay, sc: b.hz34Sc, cm: b.hz34Cm }); }
{
	expect(/default: if\(!this\.hz34Ini\(k,nv\) && !this\.hz26Ini\(k,bv,nv\)\) \{ this\.hzIniLayoutKey\(k,nv\); \} break;/.test(onIni) && /if\(isNaN\(nv\) && this\.hz30IniPos\(k,v\)\) \{ continue; \}/.test(onIni), "hzOnIni: positional value, then the switch, then hz34Ini / hz26Ini / hzIniLayoutKey (the chain this test runs)");
	const leftovers = [
		"[ActiveBuffs]", "ActiveBuffs=1", "ActiveBuffs=0", "BuffsShow=1", "BuffsMax=9", "BuffsMax=abc", "BuffsTimers=0", "BuffsPermanent=1", "BuffsHideEmpty=0", "BuffsRule=2",
		"[Cards]", "BuffsScale=1.2", "BuffsScale=-1", "BuffsCompact=1", "BuffsCompact=-1",
		"[Layout]", "BuffsX=L120", "BuffsY=B-300", "BuffsX=-1", "BuffsY=-1", "BuffsX=0.25", "BuffsY=0.75", "BuffsX=R-50", "BuffsY=C0", "BuffsX=", "BuffsY=garbage",
	];
	let bad = [], thrown = [];
	const hx = host();
	const before = snap(hx.base);
	for (const ln of leftovers) {
		if (/^\[/.test(ln)) continue;
		const eq = ln.indexOf("=");
		const k = ln.substr(0, eq).replace(/\s/g, "").toLowerCase(), v = ln.substr(eq + 1).trim();
		let r;
		try { r = applyKey(hx, k, v); } catch (e) { thrown.push(ln + ": " + e.message); continue; }
		if (r !== "layout") bad.push(ln + " -> " + r);
	}
	expect(thrown.length === 0, "leftover keys: no throw in the production chain" + (thrown.length ? ": " + thrown.join("; ") : ""));
	expect(bad.length === 0, "leftover keys: none is taken by the switch, hz30IniPos, hz34Ini or hz26Ini (all fall through)" + (bad.length ? ": " + bad.join("; ") : ""));
	expect(hx.writes.length === 0 && snap(hx.base) === before, "leftover keys: no state write (no layout spot, no card size / form, no flag)" + (hx.writes.length ? ": " + hx.writes.join(",") : ""));
	expect(hx.calls.length === 0, "leftover keys: no other HUD function is reached" + (hx.calls.length ? ": " + hx.calls.join(",") : ""));
	// positive control: the same chain still applies the Hazard / Afflictions keys next to the leftovers
	const hy = host();
	applyKey(hy, "hazardx", "L120"); applyKey(hy, "afflictionsy", "B-300"); applyKey(hy, "hazardscale", "1.2"); applyKey(hy, "hazardcompact", "1"); applyKey(hy, "afflictionsscale", "0.8");
	applyKey(hy, "buffsx", "L120"); applyKey(hy, "buffsscale", "1.2"); applyKey(hy, "buffsrule", "2");
	const hs = applyKey(hy, "hazardstatus", "0");
	expect(hy.base.hzLay.Hazard && hy.base.hzLay.Hazard.ax === "L" && hy.base.hzLay.Hazard.dx === 120 && hy.base.hzLay.Afflictions && hy.base.hzLay.Afflictions.ay === "B" && hy.base.hzLay.Afflictions.dy === -300, "control: [Layout] HazardX / AfflictionsY still apply (edge spots)");
	expect(hy.base.hz34Sc.Hazard === 1.2 && hy.base.hz34Cm.Hazard === 1 && hy.base.hz34Sc.Afflictions === 0.8, "control: [Cards] HazardScale / HazardCompact / AfflictionsScale still apply");
	expect(hs === "hz26" && hy.base.hzHsOn === false, "control: [Effects] HazardStatus=0 still applies");
	expect(!("Buffs" in hy.base.hzLay) && !("Buffs" in hy.base.hz34Sc) && Object.keys(hy.base.hzLay).sort().join(",") === "Afflictions,Hazard", "control: the leftovers mixed in change nothing next to them");
	// the section-aware parsers only read their own sections
	expect(/if\(sec != "comms"\) \{ continue; \}/.test(fnText(as, "hz31ParseIni").body) && /if\(sec != "scanner"\) \{ continue; \}/.test(fnText(as, "hz40ParseIni").body), "hz31ParseIni / hz40ParseIni read only [Comms] / [Scanner], so an [ActiveBuffs] section is never read there");
	// the writer: F11 never writes a Buffs key again
	const w = fnText(as, "hz26IniLines").body + fnText(as, "hz34IniLines").body;
	expect(!/Buffs|ActiveBuffs/.test(w), "the INI writer (hz26IniLines, hz34IniLines) writes no Active Buffs key");
}

// ---- 4. edge-only ----
{
	expect(count(code, "ENTER_FRAME") === 1 && /addEventListener\(Event\.ENTER_FRAME,this\.hzPbFrame\);/.test(code), "one ENTER_FRAME listener in the whole file, the existing hzPbFrame (none added)");
	expect(!/new Timer\(|setInterval\(|setTimeout\(/.test(code), "no Timer, setInterval or setTimeout");
	const fr = fnText(as, "hzOnFrame").body;
	expect(fr.indexOf("hzAb") < 0 && fr.indexOf("Buffs") < 0, "hzOnFrame has no Active Buffs work");
}

console.log((failed ? "activebuffs_test FAILED" : "activebuffs_test passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
