// Active Buffs card tests (0.43.3.1). Run: node tests/activebuffs_test.js
// Runs the production AS functions (types stripped) on a small host and checks the source:
//  the Status feed parse, buffs / debuffs, permanent entries, max entries, expanded / compact, the countdown on the
//  existing 30-frame slot (text changes only when the shown second changes), rows dropped after about 5 s at 0:00, the degrade path (no aEffectGroups, a feed
//  that stops pushing), hide when empty, INI defaults and back-compat, ARRANGE (keys, lists, save / load of an
//  edge-anchored spot), the rule, the shared card style (same panel path as a reference card), and no timer / frame /
//  tree-search code in the card.
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
const STATIC = ["HZ_AB_W", "HZ_AB_ROWS", "HZ_AB_GROUPS", "HZ_AB_EFFECTS", "HZ_AB_GAP", "HZ_AB_LOW", "HZ_AB_DROP", "HZ_RED", "HZ_AMB", "HZ_ACCENT", "HZ_LAY_KEYS"];
function jsBody(src) {
	let b = src
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/([\w.\]\[]+) as Array\b/g, "(Array.isArray($1) ? $1 : null)")
		.replace(/([\w.\]\[]+) as (?:MovieClip|TextField|Sprite)\b/g, "$1")
		.replace(/\(([\w.]+) is Boolean\)/g, "(typeof $1 === \"boolean\")")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/([^.\w])addChild\(/g, "$1this.addChild(")
		.replace(/new RegExp\(/g, "new RegExp(");
	for (const k of STATIC) b = b.replace(new RegExp("([^.\\w\"])" + k + "\\b", "g"), "$1this." + k);
	return b;
}
function toJs(name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => {
		const nm = p.split(":")[0].trim();
		const dv = p.indexOf("=") >= 0 ? p.slice(p.indexOf("=") + 1).trim() : null;
		return dv != null ? nm + " = " + dv : nm;
	});
	return new Function(...params, jsBody(f.body));
}
global.int = (v) => { const n = Number(v); return isNaN(n) || !isFinite(n) ? 0 : (n < 0 ? Math.ceil(n) : Math.floor(n)) | 0; };
global.uint = (v) => Number(v) >>> 0;
global.Sprite = class { constructor() { this.graphics = mkG(); this.kids = []; this.visible = true; this.scaleX = this.scaleY = 1; } addChild(c) { this.kids.push(c); return c; } };
let subs = [];
global.BSUIDataManager = { Subscribe: (n, f) => { subs.push(n); } };
function mkG() { const calls = []; return { calls, clear() { calls.length = 0; }, beginFill(c, a) { calls.push(["fill", c, +a.toFixed(4)]); }, endFill() { calls.push(["end"]); }, lineStyle(...a) { calls.push(["line"].concat(a.map((x) => typeof x === "number" ? +x.toFixed(4) : x))); }, drawRoundRect(...a) { calls.push(["rr"].concat(a.map((x) => +(+x).toFixed(3)))); }, drawRect(...a) { calls.push(["r"].concat(a)); }, drawCircle(...a) { calls.push(["c"].concat(a)); }, moveTo() {}, lineTo() {} }; }
function mkTf() { const t = { _t: "", sets: 0, visible: true, x: 0, y: 0, width: 0, tint: null }; Object.defineProperty(t, "text", { get() { return this._t; }, set(v) { this._t = String(v); this.sets++; } }); return t; }

// ---- the card section ----
const B0 = "      // ===================== Active Buffs card (0.43.3.1) =====================\n";
const B1 = "      // ===================== end Active Buffs card =====================\n";
const i0 = as.indexOf(B0), i1 = as.indexOf(B1);
expect(i0 > 0 && i1 > i0 && count(as, B0) === 1 && count(as, B1) === 1, "one Active Buffs card section");
const sec = as.slice(i0, i1 + B1.length);
const code = sec.replace(/\/\/.*$/gm, "");
const CONST = {};
{ const re = /private static const (HZ_AB_\w+):\w+ = ([^;]+);/g; let m; while ((m = re.exec(sec))) CONST[m[1]] = Number(m[2]); }
expect(CONST.HZ_AB_ROWS === 12 && CONST.HZ_AB_GAP === 4000 && CONST.HZ_AB_LOW === 60 && CONST.HZ_AB_W === 300 && CONST.HZ_AB_DROP === 5000, "constants: 12 rows max, 4 s gap, amber under 60 s, 300 wide, drop 5 s after 0:00");

// ---- source rules: edge-only ----
expect(!/new Timer|\bTimer\(|setTimeout|setInterval|ENTER_FRAME|enterFrame|getTimer|hzFindByName|getChildByName|getChildAt|hzFrameN/.test(code), "no timer / frame / tree search code in the card");
expect(count(code, "addEventListener(") === 0, "no listener in the card");
expect(count(code, "Subscribe(") === 1 && /BSUIDataManager\.Subscribe\("PlayerStatusData",this\.hzAbOnStatus\)/.test(code), "one data subscription: PlayerStatusData");
expect(!/PlaySound|PlayMenuSound|\.play\(/.test(code), "no sound code");
const ppc = fnText(as, "hzPpClock").body;
expect(/^\s*try \{ this\.hzAbTick\(\); \} catch/.test(ppc), "countdown: hzAbTick runs first in the existing 30-frame slot hzPpClock (own try)");
expect(/if\(this\.hzFrameN % 30 == 11\) \{ try \{ this\.hzPpClock\(\); \}/.test(fnText(as, "hzOnFrame").body), "the slot is the existing 30-frame hzOnFrame call (unchanged)");
expect(count(as, "this.hzAbTick()") === 1, "hzAbTick has exactly one caller");
expect(/hz34Cm\["Buffs"\] === undefined\) \{ this\.hz34Cm\["Buffs"\] = 0; \}/.test(fnText(as, "hzAbBuild").body), "form defaults to EXPANDED when no BuffsCompact was read");
expect(/try \{ this\.hzAbBuild\(\); \}/.test(as) && count(as, "this.hzAbBuild()") === 1, "the card is built once, next to the Hazard Status card");
expect(/this\.hzAfOnLoad\(\); \}\n\s*if\(this\.hz40HasFF\(ev\.data,"LoadingMenu_Opened"\) \|\| this\.hz40HasFF\(ev\.data,"LoadingMenu_Closed"\)\) \{ try \{ this\.hzAbOnLoad\(\); \}/.test(as), "a load (LoadingMenu open / close) clears the card; the Afflictions load line is unchanged");

// ---- host ----
function host(over) {
	const h = {
		hzAbOn: true, HorizonBuffs_mc: null, hzRuleBuffs: 0, hzAbMode: 0, hzAbMax: 6, hzAbTimers: true, hzAbPerm: false, hzAbHideEmpty: true,
		hzAbG: null, hzAbBarG: null, hzAbHd: null, hzAbCt: null, hzAbSubT: null, hzAbMore: null, hzAbNm: [], hzAbTm: [], hzAbSubbed: false,
		hzAbFeed: 0, hzAbList: [], hzAbSeen: {}, hzAbClk: 0, hzAbWall: -1, hzAbCardOn: false, hzAbShown: false, hzAbSig: null, hzAbRowsD: [], hzAbH: 0, hzAbCm: -1,
		hzArrange: false, hz41SA: false, hzLaidOut: true, hzLay: {}, hz34Cm: {}, hz34Sc: {}, hzCompact: false, hzTexts: [],
		hzCardOpacity: 1, hzCardBgOpacity: 92, hzCardShadow: 12, hzCardColor: 0, hzTextTone: 0, HZ_ACCENT: 0x3FD0E0,
		now: 1000000, nowCalls: 0, shows: [], draws: 0, kids: [],
		addChild(c) { this.kids.push(c); return c; },
		hz26Now() { this.nowCalls++; return this.now; },
		hzShow(c, on) { this.shows.push(on); c.visible = on; },
		hzT(p, txt) { const t = mkTf(); t._t = txt; this.hzTexts.push({ tf: t }); return t; },
		hzFitText(tf, t) { tf.text = t; }, hzUC(s) { return s; }, hzTxtTop(tf, y) { tf.y = y; }, hzTxtTint(tf, c) { tf.tint = c; this.tints = (this.tints || 0) + 1; },
		hzSetSz(c, w, h2) { c.w = w; c.h = h2; }, hzLayHas(k) { return !!this.hzLay[k]; },
		hz34S() { return 1; }, hz34CmClamp(v) { const n = Math.round(Number(v)); return n === 0 || n === 1 ? n : -1; },
		hzCardPal() { return [0x0B1218, 0x16181C, 0x0B1630, 0x0A2226, 0x1E1328, 0x2A1014, 0x3A4652, 0xD5DBE0, 0xF2F4F6]; },
		hzB(o) { return o === true || Number(o) >= 0.5 ? "1" : "0"; },
		hzRuleOk(r) { return r === 0 || (r === 1 && this.combat) || (r === 2 && !this.inShip); },
	};
	for (const k of Object.keys(CONST)) h[k] = CONST[k];
	h.HZ_RED = 0xFF5B5B; h.HZ_AMB = 0xF2A93B;
	h.HZ_LAY_KEYS = JSON.parse("[" + /HZ_LAY_KEYS:Array = \[([^\]]*)\]/.exec(as)[1] + "]");
	for (const n of ["hzAbSub", "hzAbBuild", "hzAbPool", "hzAbCmp", "hzAbOnStatus", "hzAbParse", "hzAbSeenUpd", "hzAbRem", "hzAbSec", "hzAbFmt", "hzAbPick", "hzAbTick", "hzAbDrop", "hzAbTimes", "hzAbTimeCol", "hzAbBars", "hzAbWant", "hzAbSync", "hzAbDraw", "hzAbCard", "hzAbRestyle", "hzAbOnLoad", "hzAbLayout", "hzAbIni", "hzAbRuleFix", "hzAbSetCur", "hzAbSetLive", "hzAbIniLines",
		"hz34C", "hzPanel", "hzPanelA", "hzCardShA", "hzPanelFill", "hzOpExtra", "hzCardFill", "hzLight", "hzLum", "hzMix", "hzIconCol", "hzDarkText", "hzTileDisc", "hzIniLayoutKey", "hz30IniPos", "hz30PosStr"]) h[n] = toJs(n);
	const draw = h.hzAbDraw; h.hzAbDraw = function (...a) { this.draws++; return draw.apply(this, a); };
	Object.assign(h, over || {});
	h.hzAbBuild();
	return h;
}
const ef = (name, o) => Object.assign({ sName: name, bHideName: false, bIsBuff: true, bPermanent: false, fTimeRemaining: 300 }, o || {});
const grp = (icon, effects, o) => Object.assign({ sEffectIcon: icon, bHasAfflictions: false, aEffects: effects }, o || {});
const feed = (h, groups) => h.hzAbOnStatus({ data: groups === undefined ? {} : { aEffectGroups: groups } });
function show(h) { h.hzAbCard(true); h.hzAbSync(); return h; }

// ---- 1. feed parse ----
{
	const h = host();
	expect(subs.length === 1 && subs[0] === "PlayerStatusData", "the card subscribes to PlayerStatusData once at build");
	h.hzAbSub(); expect(subs.length === 1, "a second hzAbSub does not subscribe again");
	expect(h.hzAbParse(null, 0) === null && h.hzAbParse({}, 0) === null && h.hzAbParse({ aEffectGroups: "x" }, 0) === null, "no aEffectGroups array -> null (unknown, not 'no effects')");
	const r = h.hzAbParse({ aEffectGroups: [
		grp("Inj", [ef("Burn", { bIsBuff: false })], { bHasAfflictions: true }),
		grp("Food", [ef("Fed"), ef("Hidden", { bHideName: true }), ef(""), ef("Hydrated", { fTimeRemaining: "abc" })]),
		grp("Chem", [ef("Med-X", { bIsBuff: undefined }), ef("Weak", { bIsBuff: undefined, fTimeRemaining: -5 })], { bIsPositiveEffect: true }),
		grp("Odd", [ef("Mystery", { bIsBuff: undefined })]),
		grp("Perm", [ef("Trait", { bPermanent: true, fTimeRemaining: 99 }), ef("Boolish", { fTimeRemaining: true })]),
		grp("Dup", [ef("Same"), ef("Same")]),
		null, grp("NoEff", null)] }, 5000);
	const names = r.map((e) => e.n);
	expect(names.join(",") === "Fed,Hydrated,Med-X,Weak,Trait,Boolish,Same,Same", "affliction groups, hidden and empty names, unknown polarity and null groups are skipped (feed order kept): " + names.join(","));
	expect(r[0].b === true && r[0].r === 300 && r[0].at === 5000 && r[0].k === "Food|Fed|1#1", "an entry: buff, remaining 300 s, stamped with the clock, key icon|name|polarity#n");
	expect(isNaN(r[1].r), "a non-numeric fTimeRemaining stays unknown (no time)");
	expect(r[2].b === true && r[3].b === true && isNaN(r[3].r), "no bIsBuff: the group's bIsPositiveEffect decides; a negative time is unknown");
	expect(r[4].p === true && isNaN(r[4].r) && isNaN(r[5].r), "permanent entries carry no time; a boolean time is unknown");
	expect(r[6].k !== r[7].k && /#2$/.test(r[7].k), "duplicate entries get distinct keys");
	const big = []; for (let i = 0; i < 40; i++) big.push(grp("G" + i, Array.from({ length: 40 }, (_, j) => ef("E" + j))));
	expect(h.hzAbParse({ aEffectGroups: big }, 0).length === 16 * 24, "the walk is bounded: 16 groups x 24 effects");
}
// ---- 2-4. buff / debuff filter, permanent, max entries ----
{
	const h = show(host());
	feed(h, [grp("A", [ef("B1"), ef("D1", { bIsBuff: false }), ef("B2"), ef("P1", { bPermanent: true }), ef("D2", { bIsBuff: false })])]);
	let pk = h.hzAbPick();
	expect(pk.rows.map((e) => e.n).join(",") === "B1,B2" && pk.total === 2, "BUFFS ONLY: debuffs and (default) permanent entries are left out");
	h.hzAbMode = 1; pk = h.hzAbPick();
	expect(pk.rows.map((e) => e.n).join(",") === "B1,B2,D1,D2", "BUFFS + DEBUFFS: buffs first, then debuffs, feed order inside each");
	h.hzAbPerm = true; pk = h.hzAbPick();
	expect(pk.rows.map((e) => e.n).join(",") === "B1,B2,P1,D1,D2", "SHOW PERMANENT: permanent entries are listed");
	h.hzAbMax = 3; pk = h.hzAbPick();
	expect(pk.rows.length === 3 && pk.more === 2 && pk.total === 5, "MAX ENTRIES 3: three rows, the rest counted as +2 more");
	h.hzAbSig = null; h.hzAbSync();
	expect(h.hzAbMore.text === "+2 more" && h.hzAbMore.visible, "the +N more line is drawn");
	h.hzAbMax = 0; expect(h.hzAbPick().rows.length === 1, "MAX ENTRIES clamps to at least 1");
	h.hzAbMax = 99; expect(h.hzAbPick().rows.length === 5, "MAX ENTRIES is capped at the 12-row pool");
	h.hzAbMode = 1; h.hzAbMax = 6; h.hzAbSig = null; h.hzAbSync();
	expect(h.hzAbSubT.visible && h.hzAbSubT.text === "DEBUFFS" && h.hzAbHd.text === "ACTIVE EFFECTS", "debuffs get their own DEBUFFS section; the title reads ACTIVE EFFECTS");
	expect(h.hzAbNm[3].tint === 0xFF5B5B && h.hzAbNm[0].tint === null, "debuff names are red, buff names use the text tone");
	h.hzAbMode = 0; h.hzAbSig = null; h.hzAbSync();
	expect(!h.hzAbSubT.visible && h.hzAbHd.text === "ACTIVE BUFFS", "buffs only: no DEBUFFS section, title ACTIVE BUFFS");
}
// ---- 5. expanded / compact ----
{
	const h = show(host());
	feed(h, [grp("A", [ef("B1"), ef("B2")])]);
	const hExp = h.hzAbH;
	expect(h.hzAbCm === 0 && h.hz34Cm.Buffs === 0, "default form is EXPANDED (BuffsCompact 0)");
	expect(h.hzAbBarG.graphics.calls.some((c) => c[0] === "rr"), "expanded draws the remaining-time bars");
	h.hz34Cm.Buffs = 1; h.hzAbSync();
	expect(h.hzAbCm === 1 && h.hzAbH < hExp, "COMPACT: one line per effect, shorter card (" + h.hzAbH + " < " + hExp + ")");
	expect(!h.hzAbBarG.graphics.calls.some((c) => c[0] === "rr"), "compact draws no bars");
	h.hz34Cm.Buffs = -1; h.hzCompact = true; h.hzAbSync();
	expect(h.hzAbCm === 1, "GLOBAL follows COMPACT MODE");
	const d0 = h.draws; h.hzAbSync(); h.hzAbSync();
	expect(h.draws === d0, "diff-and-skip: an unchanged state does not redraw");
}
// ---- 6. countdown ----
{
	const h = show(host());
	feed(h, [grp("A", [ef("XP", { fTimeRemaining: 61.4 })])]);
	const tf = h.hzAbTm[0];
	expect(tf.text === "1:01", "the first draw shows the payload's time (rounded like the Status menu): " + tf.text);
	h.hzAbTick(); expect(h.hzAbClk === 0, "the first slot call only takes the wall time");
	let sets = tf.sets, tints = h.tints, bars = h.hzAbBarG.graphics.calls.length;
	h.hzAbBarG.graphics.calls.push(["mark"]);
	h.now += 300; h.hzAbTick();
	expect(tf.sets === sets && tf.text === "1:01" && h.tints === tints && h.hzAbBarG.graphics.calls[bars][0] === "mark", "0.3 s later the shown second is the same: text, color and bar are not touched");
	h.now += 700; h.hzAbTick();
	expect(tf.text === "1:00" && tf.sets === sets + 1, "1 s later the second changed: one text update (1:00)");
	sets = tf.sets; h.now += 1000; h.hzAbTick();
	expect(tf.text === "0:59" && tf.sets === sets + 1 && tf.tint === 0xF2A93B, "under 60 s the time turns amber");
	h.now += 60000; h.hzAbTick();
	expect(tf.text === "0:59", "a slot gap over 4 s (pause, menu, load) is not counted");
	// clock 2 s here; XP (61.4 s) reaches 0 at clock 61.4 s
	for (let i = 0; i < 61; i++) { h.now += 1000; h.hzAbTick(); }
	expect(tf.text === "0:00" && h.hzAbList.length === 1, "a row that runs out shows 0:00 and stays listed for now");
	sets = tf.sets; h.now += 1000; h.hzAbTick();
	expect(tf.sets === sets, "at 0:00 later slots change nothing");
	feed(h, [grp("A", [ef("XP", { fTimeRemaining: 7300 })])]);
	expect(tf.text === "2:01:40", "a new payload resets the row to the game's value (h:mm:ss over an hour)");
	const hr = show(host()); feed(hr, [grp("A", [ef("R", { fTimeRemaining: 61.6 })])]);
	expect(hr.hzAbTm[0].text === "1:02", "the shown second is rounded like the Status menu (61.6 s -> 1:02)");
	const h2 = show(host());
	feed(h2, [grp("A", [ef("P", { bPermanent: true })])]);
	const nc = h2.nowCalls; h2.hzAbTick(); h2.hzAbTick();
	expect(h2.nowCalls === nc && h2.hzAbWall === -1, "nothing timed: the slot returns at once (no clock read)");
	const h3 = show(host({ hzAbPerm: true })); feed(h3, [grp("A", [ef("P", { bPermanent: true }), ef("T", { fTimeRemaining: 10 })])]);
	expect(h3.hzAbTm[0].text === "PERM" && h3.hzAbTm[1].text === "0:10", "permanent rows show PERM, timed rows their time");
	h3.hzAbTimers = false; h3.hzAbSig = null; h3.hzAbSync();
	expect(h3.hzAbTm[0].text === "PERM" && h3.hzAbTm[1].text === "" && !h3.hzAbBarG.graphics.calls.some((c) => c[0] === "rr"), "SHOW TIMERS off: no time and no bar; PERM stays");
	const h4 = show(host()); feed(h4, [grp("A", [ef("U", { fTimeRemaining: undefined })])]);
	expect(h4.hzAbTm[0].text === "", "unknown time: no time shown");
	const h5 = host(); feed(h5, [grp("A", [ef("T", { fTimeRemaining: 30 })])]); h5.hzAbTick(); const s5 = h5.hzAbTm.length ? h5.hzAbTm[0].sets : 0; h5.now += 2000; h5.hzAbTick();
	expect(h5.hzAbClk === 2000 && (!h5.hzAbTm.length || h5.hzAbTm[0].sets === s5), "a hidden card keeps counting but touches no text");
	// bar: since seen
	const h6 = show(host()); feed(h6, [grp("A", [ef("T", { fTimeRemaining: 100 })])]); h6.hzAbTick();
	for (let i = 0; i < 50; i++) { h6.now += 1000; h6.hzAbTick(); }
	feed(h6, [grp("A", [ef("T", { fTimeRemaining: 50 })])]);
	expect(h6.hzAbSeen["A|T|1#1"] === 100, "the bar keeps the longest time seen for the entry (since seen)");
	feed(h6, [grp("A", [ef("T", { fTimeRemaining: 90 })])]);
	expect(h6.hzAbSeen["A|T|1#1"] === 90, "a jump up (refresh) restarts since seen");
}
// ---- 6b. D-1: a timed row leaves about 5 s after it reaches 0:00 (the existing slot only) ----
{
	const tick = (h, ms, step) => { for (let t = 0; t < ms; t += step) { h.now += step; h.hzAbTick(); } };
	const h = show(host());
	feed(h, [grp("A", [ef("XP", { fTimeRemaining: 10 })])]);
	h.hzAbTick(); tick(h, 10000, 500);
	expect(h.hzAbTm[0].text === "0:00" && h.hzAbList.length === 1 && h.hzAbShown, "at 0 s left the row shows 0:00 and is still listed");
	const d0 = h.draws;
	tick(h, 4500, 500);
	expect(h.hzAbList.length === 1 && h.hzAbShown && h.draws === d0, "4.5 s at 0:00: still listed, no redraw");
	tick(h, 1000, 500);
	expect(h.hzAbList.length === 0 && h.hzAbShown === false && h.draws === d0, "5 s at 0:00: the row leaves and the empty card hides (HIDE WHEN EMPTY)");
	feed(h, [grp("A", [ef("XP", { fTimeRemaining: 10 })])]);
	expect(h.hzAbList.length === 1 && h.hzAbShown && h.hzAbTm[0].text === "0:10", "a payload that still lists the effect brings it back (the game's list is the truth)");
	// only expired timed rows leave; the others keep their order; permanent and unknown rows never leave here
	const m = show(host({ hzAbPerm: true, hzAbHideEmpty: false }));
	feed(m, [grp("A", [ef("Short", { fTimeRemaining: 2 }), ef("Perm", { bPermanent: true }), ef("Unk", { fTimeRemaining: undefined }), ef("Long", { fTimeRemaining: 300 })])]);
	m.hzAbTick(); const dm = m.draws; tick(m, 7000, 500);
	expect(m.hzAbList.map((e) => e.n).join(",") === "Perm,Unk,Long" && m.draws === dm + 1, "Short left after 2 s + 5 s with one redraw; Perm, Unk and Long stay in feed order");
	expect(m.hzAbNm[0].text === "Perm" && m.hzAbTm[0].text === "PERM" && m.hzAbTm[1].text === "" && m.hzAbTm[2].text === "4:53", "the redraw shows the remaining rows with their times");
	tick(m, 3600000, 1000);
	expect(m.hzAbList.map((e) => e.n).join(",") === "Perm,Unk" && m.hzAbMore.visible === false, "Long leaves later; permanent and unknown-time rows stay until a payload or a load");
	// a pause / menu gap is not time at 0:00
	const g = show(host());
	feed(g, [grp("A", [ef("T", { fTimeRemaining: 1 })])]); g.hzAbTick(); tick(g, 2000, 500);
	g.now += 60000; g.hzAbTick(); tick(g, 3500, 500);
	expect(g.hzAbList.length === 1, "a slot gap over 4 s (pause, menu) does not count as time at 0:00");
	tick(g, 1000, 500);
	expect(g.hzAbList.length === 0, "real slot time at 0:00 does");
	// a hidden card and SHOW TIMERS off still drop expired rows (the list stays true for the next show)
	const hd = host(); feed(hd, [grp("A", [ef("T", { fTimeRemaining: 1 })])]); hd.hzAbTick(); tick(hd, 6500, 500);
	expect(hd.hzAbList.length === 0, "hidden card: the expired row still leaves the list");
	const to = show(host({ hzAbTimers: false })); feed(to, [grp("A", [ef("T", { fTimeRemaining: 1 }), ef("U", { fTimeRemaining: 900 })])]); to.hzAbTick(); tick(to, 6500, 500);
	expect(to.hzAbList.map((e) => e.n).join(",") === "U", "SHOW TIMERS off: the expired row still leaves");
	// a debuff in BUFFS ONLY (not drawn) also leaves, so "+N more" and the count stay true
	const dbf = show(host({ hzAbMode: 0, hzAbHideEmpty: false })); feed(dbf, [grp("A", [ef("D", { bIsBuff: false, fTimeRemaining: 1 }), ef("B", { fTimeRemaining: 900 })])]); dbf.hzAbTick(); tick(dbf, 6500, 500);
	expect(dbf.hzAbList.map((e) => e.n).join(",") === "B", "a row that is not drawn leaves the list too");
	// source: no new timer, no allocation on the slot path unless a row leaves
	const tk = fnText(as, "hzAbTick").body.replace(/\/\/.*$/gm, ""), dr = fnText(as, "hzAbDrop").body.replace(/\/\/.*$/gm, "");
	const pre = dr.slice(0, dr.indexOf("if(j == n) { return false; }"));
	expect(dr.indexOf("if(j == n) { return false; }") > 0 && !/new |\[\]|\{\}|\.push\(|\.splice\(|\.slice\(|\.concat\(|"/.test(pre) && !/new |\[\]|\{\}|\.push\(|\.splice\(|\.slice\(|\.concat\(|"/.test(tk), "the slot path allocates nothing unless a row leaves (in-place compaction, no splice / slice / push)");
	expect(/this\.hzAbWall = now;\s*if\(this\.hzAbDrop\(\)\) \{ return; \}/.test(tk) && count(as, "this.hzAbDrop()") === 1, "the drop runs only inside hzAbTick, right after the clock moves");
}
// ---- 6c. test gaps from the review's surviving mutants ----
{
	const tick = (h, ms, step) => { for (let t = 0; t < ms; t += step) { h.now += step; h.hzAbTick(); } };
	const a = show(host()); feed(a, [grp("A", [ef("T", { fTimeRemaining: 60 })])]);
	expect(a.hzAbTm[0].text === "1:00" && a.hzAbTm[0].tint === 0x3FD0E0, "exactly 60 s left is not amber yet (amber is under 60 s)");
	a.hzAbTick(); tick(a, 1000, 500);
	expect(a.hzAbTm[0].text === "0:59" && a.hzAbTm[0].tint === 0xF2A93B, "59 s left is amber");
	const d = show(host({ hzAbMode: 1 })); feed(d, [grp("A", [ef("B", { fTimeRemaining: 30 }), ef("D", { bIsBuff: false, fTimeRemaining: 30 })])]);
	expect(d.hzAbTm[0].tint === 0xF2A93B && d.hzAbTm[1].tint === 0xFF5B5B, "a debuff's time is red (a buff under a minute is amber)");
	const u = show(host()); feed(u, [grp("A", [ef("T", { fTimeRemaining: 30 })])]);
	feed(u, [grp("A", [ef("T", { fTimeRemaining: undefined })])]);
	expect(u.hzAbTm[0].text === "", "a row whose time becomes unknown is redrawn without a time (unknown stays unknown)");
	const t = show(host({ hzAbTimers: false })); feed(t, [grp("A", [ef("T", { fTimeRemaining: 30 })])]); t.hzAbTick();
	const tn = t.tints, gc = t.hzAbBarG.graphics.calls.length; t.hzAbBarG.graphics.calls.push(["mark"]);
	tick(t, 3000, 500);
	expect(t.tints === tn && t.hzAbBarG.graphics.calls[gc][0] === "mark", "SHOW TIMERS off: the slot touches no text color and no bar");
	const l = show(host()); feed(l, [grp("A", [ef("T", { fTimeRemaining: 100 })])]);
	l.hzAbTick(); expect(Object.keys(l.hzAbSeen).length === 1 && l.hzAbWall >= 0, "since seen holds the entry; the slot took the wall time");
	l.hzAbOnLoad();
	expect(Object.keys(l.hzAbSeen).length === 0 && l.hzAbWall === -1, "a load also clears since seen and the wall time");
	const af = { x: 40, y: 900 }, placed = [];
	const ly = host({ HorizonAffl_mc: af, hzFades: [], hzPlace(c, x, y) { placed.push([x, y]); } });
	ly.hzAbH = 80; ly.hzAbLayout();
	expect(placed.length === 1 && placed[0][0] === 40 && placed[0][1] === 900 - 10 - 80, "default spot: 10 px above the Afflictions card, left edges aligned");
	const fd = host({ HorizonAffl_mc: af, hzFades: [{ c: af, base: 700 }], hzPlace(c, x, y) { placed.push([x, y]); } });
	fd.hzAbH = 0; fd.hzAbLayout();
	expect(placed[1][1] === 700 - 10 - 60, "while the Afflictions card fades it uses its base spot; no drawn height yet = 60");
	const cg = host(); let syncs = 0; const sy = cg.hzAbSync; cg.hzAbSync = function () { syncs++; return sy.apply(this, arguments); };
	cg.hzAbCard(true); cg.hzAbCard(true); cg.hzAbCard(true);
	expect(syncs === 1, "the show base is edge-gated: the same value again does no work");
}
// ---- 7. degrade ----
{
	const h = show(host({ hzAbHideEmpty: false }));
	expect(h.hzAbMore.text === "No status data yet" && h.hzAbCt.text === "", "before any payload: 'No status data yet', no count (unknown, not zero)");
	feed(h, undefined);
	expect(h.hzAbFeed === 2 && h.hzAbMore.text === "No status data yet", "a payload without aEffectGroups stays unknown");
	feed(h, []);
	expect(h.hzAbFeed === 1 && h.hzAbMore.text === "No active buffs" && h.hzAbCt.text === "0", "an empty list is known: 'No active buffs', count 0");
	feed(h, [grp("A", [ef("T", { fTimeRemaining: 20 })])]); feed(h, undefined);
	expect(h.hzAbFeed === 1 && h.hzAbList.length === 1 && h.hzAbTm[0].text === "0:20", "a later payload without aEffectGroups keeps the last list (no fake clear)");
	h.hzAbTick(); for (let i = 0; i < 5; i++) { h.now += 1000; h.hzAbTick(); }
	expect(h.hzAbTm[0].text === "0:15", "a feed that stops pushing: the last values count down locally");
	h.hzAbOnLoad();
	expect(h.hzAbList.length === 0 && h.hzAbFeed === 0 && h.hzAbMore.text === "No status data yet", "a load drops the old character's list");
}
// ---- 8. hide when empty / show base / rule ----
{
	const h = host();
	h.hzAbCard(true);
	expect(h.hzAbShown === false, "HIDE WHEN EMPTY (default): no rows, no card");
	feed(h, [grp("A", [ef("B")])]);
	expect(h.hzAbShown === true && h.shows[h.shows.length - 1] === true, "a buff shows the card");
	feed(h, [grp("A", [ef("D", { bIsBuff: false })])]);
	expect(h.hzAbShown === false, "only debuffs in BUFFS ONLY: hidden again");
	h.hzAbHideEmpty = false; h.hzAbSync();
	expect(h.hzAbShown === true && h.hzAbMore.text === "No active buffs", "HIDE WHEN EMPTY off: the card stays with 'No active buffs'");
	h.hzAbCard(false);
	expect(h.hzAbShown === false, "show base off (HUD hidden, scanner, rule): hidden");
	h.hzAbCard(true); h.hzAbOn = false; h.hzAbSync();
	expect(h.hzAbShown === false, "ACTIVE BUFFS off: hidden");
	expect(h.hzAbRuleFix(1) === 1 && h.hzAbRuleFix(2) === 2 && h.hzAbRuleFix(0) === 0 && h.hzAbRuleFix(3) === 0 && h.hzAbRuleFix(-1) === 0, "rule values: 0 always, 1 combat only, 2 hide in ship; anything else = 0");
	const rv = fnText(as, "hzRefreshVisibility").body;
	expect(/this\.hzAbCard\(cardBase && this\.hzRuleOk\(this\.hzRuleBuffs\)\); this\.hzAbSync\(\); if\(this\.HorizonBuffs_mc && !this\.hzArrange\) \{ this\.hzShow\(this\.HorizonBuffs_mc,this\.hzAbShown\); \}/.test(rv), "visibility refresh: the cards' base plus [Rules] BuffsRule, show target given again (scanner force-hide restored)");
	expect(/\{"k":"BuffsRule","l":"ACTIVE BUFFS","t":"q","ids":\[0,1,2\]\}/.test(fnText(as, "hzSetRows").body), "F11 RULES has an ACTIVE BUFFS row (always / combat only / hide in ship)");
	const rh = host({ combat: false }); rh.hzRuleBuffs = 1;
	expect(rh.hzRuleOk(rh.hzRuleBuffs) === false, "combat only out of combat: the base is off (host check)");
}
// ---- 9. INI defaults / back-compat ----
{
	const def = (k) => { const m = new RegExp("\\n" + k + "=([^\\n]*)\\n").exec(ini); return m ? m[1] : null; };
	const secOf = (k) => { const at = ini.indexOf("\n" + k + "="); const h = ini.lastIndexOf("\n[", at); return ini.slice(h + 1, ini.indexOf("]", h) + 1); };
	expect(def("ActiveBuffs") === "1" && def("BuffsShow") === "0" && def("BuffsMax") === "6" && def("BuffsTimers") === "1" && def("BuffsPermanent") === "0" && def("BuffsHideEmpty") === "1" && def("BuffsRule") === "0", "default.ini: on, buffs only, 6, timers on, permanent off, hide when empty on, rule 0");
	expect(["ActiveBuffs", "BuffsShow", "BuffsMax", "BuffsTimers", "BuffsPermanent", "BuffsHideEmpty", "BuffsRule"].every((k) => secOf(k) === "[ActiveBuffs]"), "the card keys sit under [ActiveBuffs]");
	expect(def("BuffsScale") === "-1" && def("BuffsCompact") === "0" && secOf("BuffsScale") === "[Cards]" && secOf("BuffsCompact") === "[Cards]", "[Cards] BuffsScale=-1 (GLOBAL), BuffsCompact=0 (EXPANDED)");
	expect(def("BuffsX") === "-1" && def("BuffsY") === "-1" && secOf("BuffsX") === "[Layout]", "[Layout] BuffsX / BuffsY = -1 (default spot)");
	expect(ini.indexOf("\n[Effects]") < ini.indexOf("\n[ActiveBuffs]") && ini.indexOf("\n[ActiveBuffs]") < ini.indexOf("\n[Rules]"), "[ActiveBuffs] sits between [Effects] and [Rules], where the writer puts it");
	const sd = JSON.parse(/HZ_SET_DEF:Object = (\{[^;]*\});/.exec(as)[1]);
	expect(sd.ActiveBuffs === 1 && sd.BuffsShow === 0 && sd.BuffsMax === 6 && sd.BuffsTimers === 1 && sd.BuffsPermanent === 0 && sd.BuffsHideEmpty === 1 && sd.BuffsRule === 0 && sd.BuffsScale === -1 && sd.BuffsCompact === 0, "HZ_SET_DEF (presets / F11 DEFAULTS) matches default.ini");
	const fresh = host();
	expect(fresh.hzAbOn === true && fresh.hzAbMode === 0 && fresh.hzAbMax === 6 && fresh.hzAbTimers === true && fresh.hzAbPerm === false && fresh.hzAbHideEmpty === true && fresh.hzRuleBuffs === 0, "an old INI without the keys: the card starts at the same defaults");
	const h = host();
	const nv = (v) => Number(v), bv = (v) => v === "1" || String(v).toLowerCase() === "true";
	for (const [k, v] of [["activebuffs", "0"], ["buffsshow", "1"], ["buffsmax", "20"], ["buffstimers", "0"], ["buffspermanent", "1"], ["buffshideempty", "0"], ["buffsrule", "2"]]) expect(h.hzAbIni(k, bv(v), nv(v)) === true, "hzAbIni reads " + k);
	expect(h.hzAbIni("hazardstatus", true, 1) === false, "hzAbIni leaves other keys to the chain");
	expect(h.hzAbOn === false && h.hzAbMode === 1 && h.hzAbMax === 12 && !h.hzAbTimers && h.hzAbPerm && !h.hzAbHideEmpty && h.hzRuleBuffs === 2, "parsed values (BuffsMax clamped to 12)");
	h.hzAbIni("buffsshow", false, 7); h.hzAbIni("buffsrule", false, 9); h.hzAbIni("buffsmax", false, NaN);
	expect(h.hzAbMode === 0 && h.hzRuleBuffs === 0 && h.hzAbMax === 12, "bad values: BuffsShow 7 -> 0, BuffsRule 9 -> 0, a non-number BuffsMax keeps the value");
	const cur = {}; h.hzAbSetCur(cur);
	const lines = []; h.hzAbIniLines(lines, cur);
	const txt = lines.join("\n");
	expect(lines[0] === "[ActiveBuffs]" && /\nActiveBuffs=0\n/.test(txt) && /\nBuffsShow=0\n/.test(txt) && /\nBuffsMax=12\n/.test(txt) && /\nBuffsTimers=0\n/.test(txt) && /\nBuffsPermanent=1\n/.test(txt) && /\nBuffsHideEmpty=0\n/.test(txt) && /\nBuffsRule=0\n/.test(txt), "the writer's [ActiveBuffs] block carries every value");
	const h2 = host();
	for (const ln of lines) { const m = /^(\w+)=(.*)$/.exec(ln); if (m) h2.hzAbIni(m[1].toLowerCase(), bv(m[2]), nv(m[2])); }
	const c2 = {}; h2.hzAbSetCur(c2);
	expect(JSON.stringify(c2) === JSON.stringify(cur), "write -> read round-trip keeps every value");
	const h3 = show(host()); h3.hzAbSetLive({ BuffsMax: 2, BuffsShow: 1, ActiveBuffs: true, BuffsRule: 1 });
	expect(h3.hzAbMax === 2 && h3.hzAbMode === 1 && h3.hzRuleBuffs === 1, "F11 live apply (hzAbSetLive)");
	expect(/try \{ this\.hzAbSetCur\(o\); \}/.test(fnText(as, "hz26SetCur").body) && /try \{ this\.hzAbSetLive\(p\); \}/.test(fnText(as, "hz26SetLive").body) && /this\.hzAbIni\(k,bv,nv\)/.test(fnText(as, "hz26Ini").body) && /this\.hzAbIniLines\(a,p\);/.test(fnText(as, "hz26IniLines").body), "read / live / current / write go through the hz26 settings chain");
	const rows = fnText(as, "hz34CardRows").body;
	expect(/\{"k":"ActiveBuffs","l":"ACTIVE BUFFS","t":"b","h":"ACTIVE BUFFS"/.test(rows) && /this\.hz34Sz\("Buffs"\)/.test(rows) && /"k":"BuffsShow".*"opts":\["BUFFS ONLY","BUFFS \+ DEBUFFS"\]/.test(rows) && /"k":"BuffsCompact","l":"STYLE".*"opts":\["EXPANDED","COMPACT","GLOBAL"\],"ids":\[0,1,-1\]/.test(rows) && /"k":"BuffsMax","l":"MAX ENTRIES","t":"n","mn":1,"mx":12,"st":1/.test(rows) && /"k":"BuffsTimers","l":"SHOW TIMERS"/.test(rows) && /"k":"BuffsPermanent","l":"SHOW PERMANENT EFFECTS"/.test(rows) && /"k":"BuffsHideEmpty","l":"HIDE WHEN EMPTY"/.test(rows), "F11 CARDS: the ACTIVE BUFFS section (mockup rows)");
}
// ---- 10. ARRANGE ----
{
	const lay = /HZ_LAY_KEYS:Array = \[([^\]]*)\]/.exec(as)[1].split(",").map((s) => JSON.parse(s));
	const layN = /HZ_LAY_NAMES:Array = \[([^\]]*)\]/.exec(as)[1].split(",").map((s) => JSON.parse(s));
	expect(lay.length === layN.length && layN[lay.indexOf("Buffs")] === "ACTIVE BUFFS" && lay.length === 20, "ARRANGE key Buffs = ACTIVE BUFFS (20 cards)");
	expect(/case "Buffs": return \[this\.HorizonBuffs_mc\]\.filter\(this\.hzNotNull\);/.test(fnText(as, "hzLayClips").body) && /case "Buffs": ok = this\.hzAbOn; break;/.test(fnText(as, "hzArrList").body), "ARRANGE: hzLayClips / hzArrList know the card (drag target while ACTIVE BUFFS is on)");
	const sa = fnText(as, "hzArrShowAll").body;
	expect(/this\.HorizonAffl_mc,this\.HorizonBuffs_mc,/.test(sa) && /try \{ this\.hzAbSync\(\); \}/.test(sa), "ARRANGE shows the card (with its last data or its empty line)");
	expect(/m\.push\(\[this\.HorizonBuffs_mc,"Buffs"\]\);/.test(fnText(as, "hzApplyScale").body), "hzApplyScale sets the card's own size");
	expect(/"HorizonBuffs_mc"/.test(/HZ40_CARDS:Array = \[[^\]]*\]/.exec(as)[0]), "the scanner hide (HZ40_CARDS) covers the card");
	expect(/\["Buffs",true\]/.test(/HZ34_CARDS:Array = \[.*\];/.exec(as)[0]), "HZ34_CARDS: own scale and compact form");
	const h = host(); h.hzArrange = true; h.hzAbSync();
	expect(h.hzAbShown === true && h.hzAbMore.text === "No status data yet", "in ARRANGE the card shows even with no data");
	h.hz41SA = true; h.hzAbSync();
	expect(h.hzAbShown === false, "ARRANGE SCANNER hides it with the other HUD cards");
	// save / load of a dragged spot (edge anchored, the generic [Layout] path)
	const L = host();
	expect(L.hz30IniPos("buffsx", "L120") && L.hz30IniPos("buffsy", "B-300"), "[Layout] BuffsX=L120 / BuffsY=B-300 are read");
	expect(L.hzLay.Buffs && L.hzLay.Buffs.ax === "L" && L.hzLay.Buffs.dx === 120 && L.hzLay.Buffs.ay === "B" && L.hzLay.Buffs.dy === -300, "the spot lands in hzLay.Buffs (edge + offset)");
	expect(L.hz30PosStr(L.hzLay.Buffs, "x") === "L120" && L.hz30PosStr(L.hzLay.Buffs, "y") === "B-300", "and is written back unchanged (save -> load -> save)");
	L.hzIniLayoutKey("buffsx", -1);
	expect(!L.hzLay.Buffs, "BuffsX=-1 goes back to the default spot");
	const wr = fnText(as, "hzBuildIniText").body;
	expect(/for each\(var lk:String in HZ_LAY_KEYS\)\s*\{\s*var lp:Object = this\.hzLay\[lk\];\s*a\.push\(lk \+ "X="/.test(wr), "the [Layout] writer covers every HZ_LAY_KEYS card (Buffs included); presets save that same text");
	expect(/if\(!c \|\| !af \|\| this\.hzLayHas\("Buffs"\)\) \{ return; \}/.test(fnText(as, "hzAbLayout").body) && /try \{ this\.hzAbLayout\(\); \}/.test(fnText(as, "hz26LayoutAfter").body), "a saved spot wins over the default spot above the Afflictions card");
}
// ---- 11. style: the shared card path ----
{
	const draw = fnText(as, "hzAbDraw").body;
	expect(/this\.hzPanel\(g,HZ_AB_W,h,cm == 1 \? 14 : 16\);/.test(draw) && count(draw, "hzPanel(") === 1, "the panel is the shared hzPanel with no tint / edge override (CardColor, CardOpacity, CardBgOpacity, CardShadow, border)");
	expect(!/beginFill\(0x[0-9A-Fa-f]{6},0\.9/.test(draw) && !/hzCardBgOpacity|hzCardOpacity|hzCardShadow/.test(code), "no card-style math of its own");
	expect(/try \{ this\.hzAbRestyle\(\); \}/.test(fnText(as, "hzV19Redraw").body), "style apply (hzV19Redraw) restyles the card, like the Hazard Status card");
	expect(/this\.hzT\(c,"",14,8,180,13,"sb","acc",2\)/.test(fnText(as, "hzAbBuild").body) && /this\.hzTexts\.push\(o\);/.test(fnText(as, "hzT").body), "texts are hzT texts (FontFace, TextTone, TextScale, HeaderStyle via hzApplyTypo; the title in the accent)");
	// the drawn panel equals a reference card's panel (the quest card calls hzPanel(g,w,h,r) the same way) under every style
	const settings = [{}, { hzCardBgOpacity: 40 }, { hzCardBgOpacity: 0 }, { hzCardShadow: 60 }, { hzCardColor: 7 }, { hzCardOpacity: 0.5 }, { hzCardOpacity: 1.5 }, { hzTextTone: 2, hzCardColor: 8 }];
	let same = true, varies = new Set();
	for (const s of settings) {
		const h = show(host(s)); feed(h, [grp("A", [ef("B1"), ef("B2")])]);
		const ab = h.hzAbG.graphics.calls.slice(0, 15);
		const ref = mkG(); h.hzPanel(ref, h.HZ_AB_W, h.hzAbH, 16);
		if (JSON.stringify(ab) !== JSON.stringify(ref.calls.slice(0, 15))) same = false;
		varies.add(JSON.stringify(ab));
	}
	expect(same, "under 8 style settings (background %, 0 %, shadow, card color, opacity below / above 1, light card) the card's panel is drawn exactly like a reference card's");
	expect(varies.size === settings.length, "and each style setting changes the drawn panel (" + varies.size + " distinct)");
	const h = show(host()); feed(h, [grp("A", [ef("B1", { fTimeRemaining: 500 })])]);
	h.HZ_ACCENT = 0xE0603F; h.hzAbRestyle();
	expect(h.hzAbTm[0].tint === 0xE0603F, "a new accent color reaches the time text on restyle");
	const d0 = h.draws; h.hzAbRestyle();
	expect(h.draws === d0 + 1, "restyle redraws once");
	expect(!/"[A-Za-z]*Opacity":/.test(JSON.stringify(/HZ_SET_DEF:Object = (\{[^;]*\});/.exec(as)[1]).replace(/"(CardOpacity|CardBgOpacity|ContainerOpacity|SettingsOpacity|DimOpacity)":/g, "")), "there is no per-card opacity setting for HUD cards (CardOpacity / CardBgOpacity are global), so the card has none either");
}

if (failed) { console.error(failed + " FAILED, " + passed + " ok"); process.exit(1); }
console.log("activebuffs_test passed (" + passed + " ok)");
