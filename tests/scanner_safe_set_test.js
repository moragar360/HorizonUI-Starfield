// 0.43.3.2 item 2 tests: the scanner safe set from the Codex scanner review (S1, S2, S3). Output must stay identical.
// Run: node tests/scanner_safe_set_test.js   (HZS_OLD=<file> compares with another hzs_block.as instead of git show a23b7c4, the recovered 329dbd4)
//  S1: hzsTr is memoized per "$KEY" and hzsMarkName per category, so a discovered marker no longer makes a TextField per
//      frame; the names are the same strings as before for every state / type / category / text case.
//  S2: hzsTick runs the compass check once per frame (hzsDrawAll already ran it on its frames).
//  S3: hzs41CmpAll and hzsCmpMarks are cached until the next compass event (hzsCmpRev) or settings change; the marks
//      string is the same as before after any sequence of compass events and settings changes.
// Runs the production functions (types stripped) next to the 0.43.3.1 bodies taken from the same file's history.
// Also checks the two MonocleMenu.as movie sources carry the same block (HZS_LRG false / true).
// Author: Moragar. Last modified: 2026-11-19 (batch k).
"use strict";

const fs = require("fs");
const path = require("path");
const gitBase = require("./lib/git_base.js");

const root = path.join(__dirname, "..");
const AS = fs.readFileSync(path.join(root, "actionscript", "scanner", "hzs_block.as"), "utf8").replace(/\r\n/g, "\n");

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
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/for\(var (\w+):String in /g, "for (let $1 in ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/([\w.\]\)]+) as (?:Array|Sprite|Object)/g, "$1")
		.replace(/([\w.]+) is Array/g, "Array.isArray($1)")
		.replace(/catch\((\w+):[\w*]+\)/g, "catch($1)")
		.replace(/\b(HZS\w*)\b/g, "this.$1");
	return new Function(...params, body);
}
// ---- game stubs ----
let TF_NEW = 0;
const TR = { "$CatA": "Outpost", "$CatB": "Cave", "$CatC": "", "$Flora": "Flora", "$Fauna": "Fauna" };   // "$CatX": no translation
global.TextField = function () { TF_NEW++; this.text = ""; };
global.GlobalFunc = { SetText(t, s) { t.text = Object.prototype.hasOwnProperty.call(TR, s) ? TR[s] : s; } };
global.uint = (v) => (Number(v) >>> 0);
global.int = (v) => (Number(v) | 0);
global.MapMarkerUtils = {
	LMS_UNKNOWN: 0, MARKER_VEHICLE: 7, MIT_MARKER_QUEST_OFFPLANET: 99, MIT_MARKER_SHIP_PARKED: 10, MIT_MARKER_VEHICLE: 12, MIT_MARKER_COMPANION: 30,
	GetGenericTypeLocString(c) { return ["", "$CatA", "$CatB", "$CatC", "$CatX", "PlainText"][c % 6]; },
};
const HZS41_SHIP_PLAYER_RT = 83;

const FNS = ["hzsTr", "hzsMarkName", "hzs41CmpAll", "hzs41CmpBuild", "hzsCmpMarks", "hzsCmpMarkList", "hzs41MyShip", "hzs41MyVeh", "hzs41IsShip", "hzs41IsPlayerShipT", "hzsIsFol", "hzsOn", "hzsTitle", "hzsCs", "hzsGs", "hzsOnCmp", "hzsLt", "hzsHasCjk", "hzsL", "hzsLSlug"];
function makeHost(src) {
	const h = {
		HZS41_SHIP_PLAYER_RT, hzsC: { ScanTextCase: -1, ScanShowShip: 1 }, hzsS: { HeaderStyle: 0 }, hzsCfgRev: 0, hzsCmpRev: 0, hzsFrame: 0,
		hzsCmp: null, hzsGot: {}, hzsHead: NaN,
		hzsTrC: {}, hzsMNC: {}, hzsMNUnk: null, hzsMNVeh: null, hzsMNRev: -1, hzsMNTi: false, hzsCmkS: null, hzsCmkR: -1, hzsCmkC: -1,
		hzs41CmpF: -1, hzs41CmpS: null, hzs41CmpC: null,
		hzsL10n: null, hzsL10nC: {},
	};
	for (const n of FNS) {
		try { h[n] = toJs(src, n).bind(h); }
		catch (e) {
			if (n !== "hzsOnCmp" && n !== "hzsLt" && n !== "hzsHasCjk" && n !== "hzsL" && n !== "hzsLSlug") throw e;
		}
	}
	if (!h.hzsLt) h.hzsLt = function (s) { return s; };
	if (!h.hzsHasCjk) h.hzsHasCjk = function () { return false; };
	return h;
}
const BASE = "a23b7c4aa7ef195506ad4945e3825620d20d4220";   // the 0.43.3.2 TESTONLY head before this batch (0.43.3.1 scanner bodies): the recovered 329dbd4 (tree e5232d87), batch k
const OLD = (() => {
	if (process.env.HZS_OLD) return fs.readFileSync(process.env.HZS_OLD, "utf8").replace(/\r\n/g, "\n");
	const r = gitBase.readBase(root, BASE, "actionscript/scanner/hzs_block.as");
	gitBase.report(r, BASE, "scanner old-vs-new checks", expect);
	return r.src;
})();

// ---- S1: names ----
{
	const h = makeHost(AS);
	const markers = [];
	for (let st = 0; st < 3; st++) for (const ty of [undefined, null, 0, 7, 3]) for (let c = 0; c < 12; c++) markers.push({ uLocationMarkerState: st, uType: ty, uCategory: c });
	const run = (host) => markers.map((m) => host.hzsMarkName(m));
	TF_NEW = 0; const a1 = run(h); const tf1 = TF_NEW;
	TF_NEW = 0; for (let f = 0; f < 60; f++) run(h); const tf60 = TF_NEW;
	expect(tf1 === 6, "S1: first pass: one TextField per distinct $KEY (4) plus one per category whose key is not a $KEY (2): " + tf1);
	const failKeys = 1;   // "$CatX" has no translation: retried each time, as before
	expect(tf60 <= 60 * failKeys * markers.filter((m) => m.uLocationMarkerState !== 0 && m.uType !== 7 && m.uCategory % 6 === 4).length, "S1: 60 frames: TextFields only for the untranslatable key (" + tf60 + ")");
	const translatedOnly = markers.filter((m) => !(m.uLocationMarkerState !== 0 && m.uType !== 7 && m.uCategory % 6 === 4));
	TF_NEW = 0; for (let f = 0; f < 60; f++) translatedOnly.forEach((m) => h.hzsMarkName(m));
	expect(TF_NEW === 0, "S1: 60 frames of markers with known names: 0 new TextFields (was one per discovered marker per frame)");
	if (OLD) {
		const o = makeHost(OLD);
		expect(JSON.stringify(run(o)) === JSON.stringify(a1), "S1: every name equals the 0.43.3.1 result (CAPS)");
		h.hzsC.ScanTextCase = 1; o.hzsC.ScanTextCase = 1;
		expect(JSON.stringify(run(o)) === JSON.stringify(run(h)), "S1: Title case without a settings rev bump: still equal (case is in the cache key)");
		h.hzsC.ScanTextCase = -1; o.hzsC.ScanTextCase = -1; h.hzsS.HeaderStyle = 1; o.hzsS.HeaderStyle = 1; h.hzsCfgRev++; o.hzsCfgRev++;
		expect(JSON.stringify(run(o)) === JSON.stringify(run(h)), "S1: HeaderStyle Title via GLOBAL + settings rev: equal");
		const k = makeHost(AS), ko = makeHost(OLD);
		expect(k.hzsTr("$Flora") === ko.hzsTr("$Flora") && k.hzsTr("$Flora") === "Flora" && k.hzsTr("") === "" && k.hzsTr(null) === "" && k.hzsTr("plain") === ko.hzsTr("plain"), "S1: hzsTr returns what it returned before");
		k.hzsTr("$Fauna"); TF_NEW = 0; for (let i = 0; i < 100; i++) k.hzsTr("$Fauna");
		expect(TF_NEW === 0, "S1: the bioscan type (hzsMTag \"$\" + type) is translated once (cached by the earlier call)");
		TF_NEW = 0; k.hzsTr("constructor"); k.hzsTr("constructor");
		expect(TF_NEW === 2 && k.hzsTr("constructor") === "constructor", "S1: a non-$ string is never memoized (no Object prototype hit)");
	} else { console.log("SKIP S1 old/new equality: no 0.43.3.1 body (no git history)"); }
}
// ---- S3: compass caches ----
{
	const mk = (n, seed) => {
		const a = [], b = [], c = [];
		for (let i = 0; i < n; i++) {
			const r = (seed * 31 + i * 17) % 100;
			a.push({ fHeading: r / 16, uiMarkerIconType: [10, 12, 30, 5, 99][r % 5], uiHandle: (r % 7) + 1, uMapMarkerType: r % 3 ? 83 : 2 });
			b.push({ fHeading: (r + 5) / 16, uiMarkerIconType: [99, 5, 10][r % 3], uiHandle: (r % 5) + 1 });
		}
		c.push({ fHeading: seed / 10, uiMarkerIconType: 10 });
		return { aMarkers: a, aMissionMarkers: b, aEnemyMarkers: [], zExtra: c };
	};
	const h = makeHost(AS);
	const o = OLD ? makeHost(OLD) : null;
	let same = true, builds = 0;
	const realBuild = h.hzs41CmpBuild;
	h.hzs41CmpBuild = function () { builds++; return realBuild(); };
	for (let ev = 0; ev < 40; ev++) {
		const d = mk(3 + (ev % 5), ev);
		for (const host of [h, o]) { if (!host) continue; host.hzsOnCmp({ data: Object.assign({ fDirection: 0.1 * ev }, d) }); }
		if (ev === 20) { h.hzsC.ScanShowShip = 0; h.hzsCfgRev++; if (o) { o.hzsC.ScanShowShip = 0; o.hzsCfgRev++; } }
		for (let f = 0; f < 5; f++) {
			h.hzsFrame++; if (o) o.hzsFrame++;
			const s1 = h.hzsCmpMarks();
			if (o && s1 !== o.hzsCmpMarks()) same = false;
		}
	}
	expect(h.hzsCmpRev === 40, "S3: hzsOnCmp bumps hzsCmpRev once per compass event");
	if (o) expect(same, "S3: the compass marks string equals the 0.43.3.1 result after 40 events x 5 frames and a ScanShowShip change");
	expect(builds <= 40, "S3: the compass list is rebuilt at most once per compass event (" + builds + " for 40 events, 200 frames; was once per frame)");
	const s0 = h.hzsCmpMarks(), b0 = builds; for (let f = 0; f < 100; f++) { h.hzsFrame++; h.hzsCmpMarks(); h.hzs41CmpAll(); }
	expect(builds === b0 && h.hzsCmpMarks() === s0, "S3: 100 steady frames with no compass event: no rebuild, same string");
}
// ---- S2: one compass check per frame ----
{
	const tick = fnText(AS, "hzsTick").body;
	expect((tick.match(/all = true;/g) || []).length === 1 && /var all:Boolean = false;/.test(tick) && /try \{ this\.hzsDrawAll\((ev)?\); all = true; \} catch/.test(tick) && /if\(!all\) \{ try \{ this\.hzsDrawCompassIfMoved\(\); \}/.test(tick), "S2: hzsTick skips its own compass check only after hzsDrawAll completed this frame");
	expect(/this\.hzsDrawCompassIfMoved\(\);/.test(fnText(AS, "hzsDrawAll").body), "S2: hzsDrawAll still runs the compass check");
	// behavior: the production tick on a stub host
	const calls = { all: 0, cmp: 0 };
	global.getTimer = () => 100000;
	const h = {
		hzsTk: 1, hzsFrame: 0, hzsReady: true, hzsT0: 0, hzsL: {}, isMenuClosing: false, hzsAlpha: 1, hzsVr: {}, hzsDirty: false, hzsFlashT: -1e9, hzs41PT: -1e9, hzs41PEnd: 0, ResourceArc_mc: null, hzs41RA: false,
		hzsHideVanilla() { }, hzsUpdVr() { }, hzsPerfSkipDraw() { return false; },
		hzsDrawAll() { calls.all++; this.hzsDrawCompassIfMoved(); }, hzsDrawCompassIfMoved() { calls.cmp++; }, hzsDrawMarks() { }, hzsDrawRet() { }, hzsDrawPanel() { }, hzsPlace() { },
	};
	h.hzsTick = toJs(AS, "hzsTick").bind(h);
	for (let i = 0; i < 60; i++) h.hzsTick(null);
	expect(calls.all === 10 && calls.cmp === 60, "S2: 60 frames: 10 full redraws, exactly one compass check per frame (was 70)");
	h.hzsDrawAll = function () { calls.all++; throw new Error("x"); };
	calls.cmp = 0; h.hzsDirty = true; h.hzsTick(null);
	expect(calls.cmp === 1, "S2: a hzsDrawAll that throws still gets the tick's own compass check (as before)");
}
// ---- the two movie sources carry the block ----
{
	const blk = AS.trimEnd();
	for (const [dir, v] of [["simp_monoclemenu", "false"], ["simp_monoclemenu_lrg", "true"]]) {
		const m = fs.readFileSync(path.join(root, "actionscript", "imp", dir, "MonocleMenu.as"), "utf8").replace(/\r\n/g, "\n");
		expect(m.indexOf(blk.replace("__HZS_LRG__", v)) >= 0, dir + "/MonocleMenu.as carries the same hzs_block (HZS_LRG " + v + ")");
	}
}
// ---- edge-only ----
{
	const sec = ["hzsTr", "hzsMarkName", "hzs41CmpAll", "hzsCmpMarks"].map((n) => fnText(AS, n).body).join("\n");
	expect(!/addEventListener|Timer|getChildByName|ENTER_FRAME/.test(sec), "no listener, timer or tree search in the cached functions");
	expect(/this\.hzsCmpRev\+\+;/.test(fnText(AS, "hzsOnCmp").body), "the compass event handler bumps the rev");
}

console.log("scanner safe set: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
