// Info message card title ([Comms] GameCardTitle) tests. Run: node tests/game_title_test.js
// The DLL's generic game notice (src/hz_msg_match.h GameNotice: kind "game", name / value "GAME") is drawn by the Comms
// movie. GameCardTitle picks the word on that card: 0 INFO (default), 1 DATA, 2 MISC, 3 GAME. Checks each choice, the
// default, the F11 / INI / preset plumbing, that ARTIFACT and every other card are unchanged, and that the word is read
// once per card draw (no frame work, no text matching).
// Author: Moragar. Last modified: 2026-11-13.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const hzc = fs.readFileSync(path.join(root, "actionscript", "comms", "hzc_block.as"), "utf8").replace(/\r\n/g, "\n");
const ini = fs.readFileSync(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"), "utf8").replace(/\r\n/g, "\n");
const dll = fs.readFileSync(path.join(root, "src", "hz_msg_match.h"), "utf8");

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
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/\bHZC_GAME_TITLES\b/g, "this.HZC_GAME_TITLES")
		.replace(/\bHZ31_KEYS\b/g, "this.HZ31_KEYS");
	return new Function(...params, body);
}
global.int = (v) => { const n = Number(v); return isNaN(n) ? 0 : n | 0; };

// ---- the DLL constant this keys on (unchanged) ----
expect(/h\.kind = "game";\s*h\.sub = "notice";\s*h\.value = "GAME";\s*h\.name = \(artifact \|\| ContainsFold\(line, "artifact"\)\) \? "ARTIFACT" : "GAME";/.test(dll), "DLL GameNotice: kind game, value GAME, name GAME / ARTIFACT (no DLL change)");

// ---- movie side ----
const TITLES = JSON.parse(/HZC_GAME_TITLES:Array = (\[[^\]]*\]);/.exec(hzc)[1]);
expect(JSON.stringify(TITLES) === '["INFO","DATA","MISC","GAME"]', "choices: INFO / DATA / MISC / GAME");
expect(/private var hzcCfg:Object = \{"ReactionCard":1,"GameCardTitle":0,/.test(hzc), "hzcCfg default GameCardTitle = 0 (INFO)");
function host(cfg) {
	const h = { hzcCfg: cfg, HZC_GAME_TITLES: TITLES, calls: 0 };
	const gt = toJs(hzc, "hzcGameTitle");
	h.hzcGameTitle = function () { h.calls++; return gt.call(h); };
	h.hzcCardTitle = toJs(hzc, "hzcCardTitle").bind(h);
	h.hzcCardTone = () => -1;
	h.hzcCardMatch = toJs(hzc, "hzcCardMatch").bind(h);
	return h;
}
for (let i = 0; i < 4; i++) {
	const h = host({ GameCardTitle: i });
	const m = h.hzcCardMatch("game", "notice", "GAME", "GAME");
	expect(m.title === TITLES[i] && m.value === TITLES[i], "choice " + i + ": title and chip read " + TITLES[i]);
}
{
	const d = host({ ReactionCard: 1 });
	const m = d.hzcCardMatch("game", "notice", "GAME", "GAME");
	expect(m.title === "INFO" && m.value === "INFO", "default (no key): INFO");
	for (const bad of [-1, 4, 99, NaN, "x"]) {
		const b = host({ GameCardTitle: bad }).hzcCardMatch("game", "notice", "GAME", "GAME");
		expect(b.title === "INFO", "out of range " + String(bad) + ": INFO");
	}
	const n = host(null).hzcCardMatch("game", "notice", "GAME", "GAME");
	expect(n.title === "INFO", "no settings yet: INFO");
	const h = host({ GameCardTitle: 1 });
	const art = h.hzcCardMatch("game", "notice", "ARTIFACT", "GAME");
	expect(art.title === "ARTIFACT" && art.value === "DATA", "ARTIFACT keeps its title (the chip follows the choice)");
	const g3 = host({ GameCardTitle: 3 }).hzcCardMatch("game", "notice", "ARTIFACT", "GAME");
	expect(g3.title === "ARTIFACT" && g3.value === "GAME", "GAME choice: ARTIFACT card exactly as before");
	const others = [["crime", "alarm", "", "ALARM"], ["credits", "gain", "", "100"], ["medical", "gained", "Burn", "Burn"], ["crew", "crew", "Sam", "CREW"], ["unavailable", "busy", "", "GAME"]];
	for (const [k, s, nm, v] of others) {
		const a = host({ GameCardTitle: 0 }).hzcCardMatch(k, s, nm, v), b = host({ GameCardTitle: 3 }).hzcCardMatch(k, s, nm, v);
		expect(JSON.stringify(a) === JSON.stringify(b), "kind " + k + ": the card does not depend on GameCardTitle");
	}
	const once = host({ GameCardTitle: 2 });
	once.hzcCardMatch("game", "notice", "GAME", "GAME");
	expect(once.calls === 2, "one card match reads the setting once for the title and once for the chip");
}
{
	const draw = fnText(hzc, "hzcCardDraw").body;
	expect(count(hzc, "this.hzcCardMatch(") === 1 && draw.indexOf("this.hzcCardMatch(kind,sub,name,value)") >= 0, "applied when the card is drawn (hzcCardDraw is the only caller)");
	expect(count(hzc, "this.hzcGameTitle()") === 2 && fnText(hzc, "hzcCardMatch").body.indexOf("this.hzcGameTitle()") > 0 && fnText(hzc, "hzcCardTitle").body.indexOf("this.hzcGameTitle()") > 0, "read only by the card match / title");
	const gt = fnText(hzc, "hzcGameTitle").body;
	for (const bad of ["indexOf", "match(", "search(", "RegExp", "toLowerCase", "addEventListener", "ENTER_FRAME", "Timer"]) expect(gt.indexOf(bad) < 0, "hzcGameTitle has no " + bad);
	const ttl = fnText(hzc, "hzcCardTitle").body;
	expect(ttl.indexOf('if(kind == "game" && n == "GAME") { return this.hzcGameTitle(); }') >= 0, "keys on the DLL's ASCII constant only (no localized text)");
}

// ---- HUD side: F11, INI, presets ----
{
	expect(count(as, '["GameCardTitle","i",0,0,3,"comms"]') === 1, "HZ31_KEYS: [Comms] GameCardTitle, int 0 - 3, default 0");
	expect(/"ReactionCard":1,"GameCardTitle":0,/.test(as), "HZ31_DEF GameCardTitle = 0");
	expect(as.indexOf('{"k":"GameCardTitle","l":"GENERIC NOTICE LABEL","t":"r","opts":["NONE","DATA","MISC"],"ids":[0,1,2]') > 0 && as.indexOf("INFO MESSAGE TITLE") < 0, "F11 COMMS row: GENERIC NOTICE LABEL NONE / DATA / MISC (no stale INFO MESSAGE TITLE)");
	expect(/\n\[Comms\][\s\S]*?\nReactionCard=1\n; label on the info message cards[^\n]*\nGameCardTitle=0\n/.test(ini), "default INI [Comms] GameCardTitle=0");
	expect(count(as.toLowerCase(), "gamecardtitle") === 8 && count(ini.toLowerCase(), "gamecardtitle") === 1, "no other GameCardTitle use (no key collision)");
	expect(/kVersion = "0\.43\.5\.0"/.test(fs.readFileSync(path.join(root, "src", "main.cpp"), "utf8")), "HZF::kVersion is 0.43.5.0 (settings schema; 0.43.5 adds [Scanner] ScanReach)");
	// the production [Comms] writer (F11 save, in-game preset save)
	const keysSrc = /private static const HZ31_KEYS:Array = (\[[\s\S]*?\]\]);/.exec(as)[1];
	const KEYS = JSON.parse(keysSrc);
	const mk = () => {
		const h = { HZ31_KEYS: KEYS, hz30Mod: { comms: 1 }, hz31C: null, hz31Rev: 1, hzArrange: false };
		for (const n of ["hz31Cfg", "hz31Clamp", "hz31Num", "hz31SetLive", "hz31IniLines"]) h[n] = toJs(as, n).bind(h);
		h.hz34ScClamp = (v) => Number(v); h.hz34ScStr = (v) => String(v); h.hz31PxSync = () => {};
		return h;
	};
	for (const [v, want] of [[undefined, "GameCardTitle=0"], [0, "GameCardTitle=0"], [1, "GameCardTitle=1"], [2, "GameCardTitle=2"], [3, "GameCardTitle=3"], [7, "GameCardTitle=3"], [-2, "GameCardTitle=0"]]) {
		const h = mk(); const a = [];
		h.hz31IniLines(a, v === undefined ? {} : { GameCardTitle: v });
		const i = a.indexOf(want);
		expect(i > 0 && a.indexOf("ReactionCard=1") === i - 2 && /^; label on the info message cards/.test(a[i - 1]), "writer / preset save: " + String(v) + " -> " + want);
	}
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("game title: " + passed + " ok, all passed");
