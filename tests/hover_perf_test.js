// Semantic tests for 0.43.1.0 hover fingerprints: production functions extracted
// from horizon_block.as and executed. In-place mutation of each drawn field must
// bust the cache. Unchanged payloads must not. Run: node tests/hover_perf_test.js
"use strict";

const fs = require("fs");
const path = require("path");

function readText(p) {
	return fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

const root = path.join(__dirname, "..");
const as = readText(path.join(root, "actionscript", "horizon_block.as"));
const scan = readText(path.join(root, "actionscript", "scanner", "hzs_block.as"));
const ini = readText(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"));
const perfH = readText(path.join(root, "src", "hz_perf.h"));
const main = readText(path.join(root, "src", "main.cpp"));

let failed = 0;
function expect(cond, msg) {
	if (cond) {
		console.log("ok  " + msg);
		return;
	}
	failed++;
	console.error("FAIL " + msg);
}

function funcBody(src, name) {
	const key = "function " + name + "(";
	const i = src.indexOf(key);
	if (i < 0) return "";
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") {
			depth--;
			if (depth === 0) return src.slice(brace, p + 1);
		}
	}
	return "";
}

function funcParams(src, name) {
	const key = "function " + name + "(";
	const i = src.indexOf(key);
	if (i < 0) return [];
	const close = src.indexOf(")", i);
	return src.slice(i + key.length, close).split(",").map(function (p) {
		p = p.trim();
		if (!p) return "";
		return p.split(":")[0].replace(/\.\.\./g, "").trim();
	}).filter(Boolean);
}

function as3toJs(body) {
	let s = body;
	s = s.replace(/for each\s*\(\s*var\s+(\w+)(?:\s*:\s*[\w\.\*]+)?\s+in\s+([^)]+)\)/g, "for (const $1 of ($2)||[])");
	s = s.replace(/([\w.]+)\s+is Array/g, "Array.isArray($1)");
	s = s.replace(/\s+as Array/g, "");
	s = s.replace(/\bvar\s+(\w+)\s*:\s*[\w\.\*]+\s*/g, "var $1 ");
	s = s.replace(/\bint\(/g, "(");
	s = s.replace(/\bthis\./g, "self.");
	return s;
}

function loadPay() {
	const names = ["hzT19Tok", "hzT19B", "hzT19ItemPay", "hzT19ActPay", "hzT19ItemsPay", "hzT19ResetPay"];
	const self = {};
	for (const name of names) {
		const body = funcBody(as, name);
		if (!body) throw new Error("missing " + name);
		const params = funcParams(as, name);
		const inner = as3toJs(body).replace(/^\{\s*/, "").replace(/\s*\}$/, "");
		self[name] = eval("(function(self){ return function(" + params.join(",") + "){ " + inner + " }; })")(self);
	}
	return self;
}

const pay = loadPay();

function sampleAct(over) {
	const a = {
		bShowRolloverActivation: true,
		uMode: 2,
		sHeaderText: "Crate",
		bStealing: false,
		bContraband: false,
		uRarity: 1,
		iSingleItemValue: 40,
		fSingleItemWeight: 1.5,
		uWeightPrecision: 1,
		bShouldCompareItems: true,
		ItemData: {
			sName: "Cutter",
			uCount: 1,
			uRarity: 1,
			uValue: 40,
			fWeight: 1.5,
			uWeightPrecision: 1,
			iFilterFlag: 2,
			WeaponInfo: { fRateOfFire: 10, fRange: 20, fAccuracy: 0.5 },
			ArmorInfo: null,
			aElementalStats: [{ fValue: 8 }]
		},
		CompareItemData: {
			sName: "Old Cutter",
			uCount: 1,
			uRarity: 0,
			uValue: 20,
			fWeight: 2,
			uWeightPrecision: 1,
			iFilterFlag: 2,
			WeaponInfo: { fRateOfFire: 8, fRange: 18, fAccuracy: 0.4 },
			ArmorInfo: null,
			aElementalStats: [{ fValue: 6 }]
		},
		aButtons: [
			{
				iType: 0,
				bVisible: true,
				bEnabled: true,
				bPressAndRelease: true,
				bPressAndHold: true,
				sTextPressAndRelease: "TAKE",
				sTextHold: "TAKE ALL"
			}
		]
	};
	if (over) Object.assign(a, over);
	return a;
}

function sampleItems() {
	return [
		{ sName: "Iron", uCount: 2, uRarity: 0, uValue: 5, fWeight: 0.3, bStolen: false, bContraband: false },
		{ sName: "Aid", uCount: 1, uRarity: 2, uValue: 12, fWeight: 0.1, bStolen: false, bContraband: false }
	];
}

function gate() {
	let actC = "";
	let itemsC = "";
	return {
		onAct(a) {
			const p = pay.hzT19ActPay(a);
			const ch = p !== actC;
			actC = p;
			return ch;
		},
		onItems(items) {
			const p = pay.hzT19ItemsPay(items);
			const ch = p !== itemsC;
			itemsC = p;
			return ch;
		},
		reset() {
			pay.hzT19ActCached = actC;
			pay.hzT19ItemsCached = itemsC;
			pay.hzT19Sig = "x";
			pay.hzT19BarSig = "x";
			pay.hzT19HoldSig = "x";
			pay.hzT19ResetPay();
			actC = pay.hzT19ActCached;
			itemsC = pay.hzT19ItemsCached;
		}
	};
}

expect(ini.indexOf("PerfDiag=0") >= 0, "PerfDiag off by default");
expect(ini.indexOf("PerfDump=0") >= 0, "PerfDump off by default");
expect(ini.indexOf("PerfDumpWait=12") >= 0, "PerfDumpWait default 12");
expect(ini.indexOf("PerfSettleMs=2000") >= 0, "PerfSettleMs default 2000");
expect(ini.indexOf("Debug=0") >= 0, "Debug overlay still off");
expect(as.indexOf("hzPerfDiag:Boolean = false") >= 0, "AS diag off by default");
expect(as.indexOf("public function hzPerfReset") >= 0, "AS reset is a public dump-window entry");
expect(as.indexOf("tickMaxHadContent") >= 0 && as.indexOf("tickMaxHadAct") >= 0 && as.indexOf("tickMaxHadItems") >= 0,
	"worst-tick flags exist");
expect(as.indexOf("c2=") >= 0 && as.indexOf("c5=") >= 0 && as.indexOf("c10=") >= 0, "content histogram tokens");
expect(as.indexOf("NOT GAME DATA") >= 0 && as.indexOf("HZ PERF FIXTURE") >= 0, "Mode B fixture is labeled");
expect(ini.indexOf("vanilla rollover can still show") >= 0, "Mode A vanilla-hover limit is documented");
expect(ini.indexOf("Scanner still draws") >= 0, "Mode B scanner-draw limit is documented");
expect(ini.indexOf("can hitch") >= 0 && ini.indexOf("getTimer") >= 0 && ini.indexOf("hz41Now") >= 0,
	"dump hitch, getTimer helpers, and hz41Now splash clock are documented");
expect(ini.indexOf("root maintenance") >= 0 && ini.indexOf("ENTER_FRAME") >= 0, "narrow AdvanceFrame scope is documented");

const g = gate();
const act = sampleAct();
expect(g.onAct(act) === true, "first activation caches");
expect(g.onAct(act) === false, "unchanged activation payload does not rebuild");

const fields = [
	["sHeaderText", "Locker"],
	["uMode", 1],
	["bStealing", true],
	["bContraband", true],
	["uRarity", 3],
	["iSingleItemValue", 99],
	["fSingleItemWeight", 2.25],
	["uWeightPrecision", 2],
	["bShouldCompareItems", false],
	["bShowRolloverActivation", false]
];
for (const [k, v] of fields) {
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o[k] = v;
	expect(gg.onAct(o) === true, "in-place activation " + k + " busts fingerprint");
}

const itemFields = [
	["sName", "Rifle"],
	["uCount", 3],
	["uRarity", 4],
	["uValue", 70],
	["fWeight", 3.2],
	["uWeightPrecision", 3],
	["iFilterFlag", 8]
];
for (const [k, v] of itemFields) {
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.ItemData[k] = v;
	expect(gg.onAct(o) === true, "in-place ItemData " + k + " busts fingerprint");
}

{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.ItemData.WeaponInfo.fAccuracy = 0.9;
	expect(gg.onAct(o) === true, "in-place weapon accuracy busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.ItemData.WeaponInfo.fRateOfFire = 40;
	expect(gg.onAct(o) === true, "in-place weapon rate of fire busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.ItemData.WeaponInfo.fRange = 80;
	expect(gg.onAct(o) === true, "in-place weapon range busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.ItemData.WeaponInfo = null;
	expect(gg.onAct(o) === true, "in-place weapon info presence busts fingerprint");
}
{
	const o = sampleAct();
	o.ItemData.ArmorInfo = { fThermalResist: 1, fAirborneResist: 2, fCorrosiveResist: 3, fRadiationResist: 4 };
	const gg = gate();
	gg.onAct(o);
	o.ItemData.ArmorInfo.fThermalResist = 9;
	expect(gg.onAct(o) === true, "in-place armor thermal busts fingerprint");
}
{
	const o = sampleAct();
	o.ItemData.ArmorInfo = { fThermalResist: 1, fAirborneResist: 2, fCorrosiveResist: 3, fRadiationResist: 4 };
	const gg = gate();
	gg.onAct(o);
	o.ItemData.ArmorInfo.fAirborneResist = 8;
	expect(gg.onAct(o) === true, "in-place armor airborne busts fingerprint");
}
{
	const o = sampleAct();
	o.ItemData.ArmorInfo = { fThermalResist: 1, fAirborneResist: 2, fCorrosiveResist: 3, fRadiationResist: 4 };
	const gg = gate();
	gg.onAct(o);
	o.ItemData.ArmorInfo.fCorrosiveResist = 8;
	expect(gg.onAct(o) === true, "in-place armor corrosive busts fingerprint");
}
{
	const o = sampleAct();
	o.ItemData.ArmorInfo = { fThermalResist: 1, fAirborneResist: 2, fCorrosiveResist: 3, fRadiationResist: 4 };
	const gg = gate();
	gg.onAct(o);
	o.ItemData.ArmorInfo.fRadiationResist = 8;
	expect(gg.onAct(o) === true, "in-place armor radiation busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.CompareItemData.fWeight = 9;
	expect(gg.onAct(o) === true, "in-place compare mass busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.CompareItemData.sName = "Better Cutter";
	expect(gg.onAct(o) === true, "in-place compare name busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.CompareItemData.WeaponInfo.fRange = 99;
	expect(gg.onAct(o) === true, "in-place compare weapon range busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.ItemData.aElementalStats[0].fValue = 12;
	expect(gg.onAct(o) === true, "in-place elemental damage busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.ItemData.aElementalStats.push({ fValue: 3 });
	expect(gg.onAct(o) === true, "in-place extra elemental stat busts fingerprint");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.junkNotDrawn = "x";
	o.ItemData.unusedField = 7;
	o.aButtons[0].unusedFlag = true;
	expect(gg.onAct(o) === false, "unused extra properties do not rebuild");
}
{
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.sHeaderText = "Locker";
	expect(gg.onAct(o) === true, "header mutate busts then");
	o.sHeaderText = "Crate";
	expect(gg.onAct(o) === true, "header restore is a new payload");
	expect(gg.onAct(o) === false, "restored unchanged payload does not rebuild");
}

const btnFields = [
	["iType", 2],
	["bVisible", false],
	["bEnabled", false],
	["bPressAndHold", false],
	["bPressAndRelease", false],
	["sTextPressAndRelease", "OPEN"],
	["sTextHold", "HOLD OPEN"]
];
for (const [k, v] of btnFields) {
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.aButtons[0][k] = v;
	expect(gg.onAct(o) === true, "in-place button " + k + " busts fingerprint");
}

expect((() => {
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.bShouldCompareItems = false;
	return gg.onAct(o);
})() === true, "HOLD5 bShouldCompareItems in-place busts (failed on b35bbf86)");
expect((() => {
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.aButtons[0].bPressAndHold = false;
	return gg.onAct(o);
})() === true, "HOLD5 bPressAndHold in-place busts (failed on b35bbf86)");
expect((() => {
	const o = sampleAct();
	const gg = gate();
	gg.onAct(o);
	o.aButtons[0].bPressAndRelease = false;
	return gg.onAct(o);
})() === true, "HOLD5 bPressAndRelease in-place busts (failed on b35bbf86)");

const items = sampleItems();
expect(g.onItems(items) === true, "first list caches");
expect(g.onItems(items) === false, "unchanged list payload does not rebuild");

const listFields = [
	["sName", "Lead"],
	["uCount", 9],
	["uRarity", 1],
	["uValue", 8],
	["fWeight", 1.1],
	["bStolen", true],
	["bContraband", true]
];
for (const [k, v] of listFields) {
	const list = sampleItems();
	const gg = gate();
	gg.onItems(list);
	list[0][k] = v;
	expect(gg.onItems(list) === true, "in-place list " + k + " busts fingerprint");
}
expect((() => {
	const list = sampleItems();
	const gg = gate();
	gg.onItems(list);
	list[0].bStolen = true;
	return gg.onItems(list);
})() === true, "HOLD5 list bStolen in-place busts (failed on b35bbf86)");
expect((() => {
	const list = sampleItems();
	const gg = gate();
	gg.onItems(list);
	list[0].bContraband = true;
	return gg.onItems(list);
})() === true, "HOLD5 list bContraband in-place busts (failed on b35bbf86)");
{
	const list = sampleItems();
	const gg = gate();
	gg.onItems(list);
	list.push({ sName: "Extra", uCount: 1, uRarity: 0, uValue: 1, fWeight: 1, bStolen: false, bContraband: false });
	expect(gg.onItems(list) === true, "in-place list length busts fingerprint");
}
{
	const list = sampleItems();
	const gg = gate();
	gg.onItems(list);
	list[0].uWeightPrecision = 3;
	list[0].iFilterFlag = 2;
	list[0].unused = true;
	expect(gg.onItems(list) === false, "list fields the rows do not draw do not rebuild");
}

{
	const a = sampleAct();
	a.sHeaderText = "foo|bar";
	const b = sampleAct();
	b.sHeaderText = "foo";
	b.ItemData.sName = "bar" + String(b.ItemData.sName);
	expect(pay.hzT19ActPay(a) !== pay.hzT19ActPay(b), "delimiter | in header does not collide with a split payload");
}
{
	const a = sampleAct();
	a.sHeaderText = "3:foo";
	const b = sampleAct();
	b.sHeaderText = "foo";
	expect(pay.hzT19Tok("3:foo") === "5:3:foo", "length prefix of a colon-name");
	expect(pay.hzT19ActPay(a) !== pay.hzT19ActPay(b), "name '3:foo' does not collide with length-prefixed foo");
}
{
	const listA = [{ sName: "a|b", uCount: 1, uRarity: 0, uValue: 1, fWeight: 1, bStolen: false, bContraband: false }];
	const listB = [
		{ sName: "a", uCount: 1, uRarity: 0, uValue: 1, fWeight: 1, bStolen: false, bContraband: false },
		{ sName: "b", uCount: 1, uRarity: 0, uValue: 1, fWeight: 1, bStolen: false, bContraband: false }
	];
	expect(pay.hzT19ItemsPay(listA) !== pay.hzT19ItemsPay(listB), "list name a|b does not collide with two rows");
}
{
	const a = sampleAct();
	a.ItemData.sName = "a:b";
	a.ItemData.uCount = "c";
	const b = sampleAct();
	b.ItemData.sName = "a";
	b.ItemData.uCount = "b:c";
	expect(pay.hzT19ActPay(a) !== pay.hzT19ActPay(b), "colon-split name/count does not collide");
}
expect(pay.hzT19Tok("") === "0:", "empty token is length-prefixed");
expect(pay.hzT19Tok(null) === "0:" && pay.hzT19Tok(undefined) === "0:", "null/undefined tokens are empty");

{
	const gg = gate();
	gg.onAct(sampleAct());
	gg.reset();
	expect(pay.hzT19ActCached === "" && pay.hzT19ItemsCached === "" && pay.hzT19Sig === "", "target-loss reset clears payload caches");
}

const tick = funcBody(as, "hzT19Tick");
expect(tick.indexOf("hzTgGhost * 200") < 0, "ghost fill is not in the content signature");
expect(tick.indexOf("hf * 8") < 0 && tick.indexOf("int(hf*") < 0, "hold fraction is not in the content signature");
expect(tick.indexOf("hzT19Tok(this.hzTextScale)") >= 0 && tick.indexOf("hzT19Tok(this.hzHeaderStyle)") >= 0, "F11 TextScale/HeaderStyle still bust content sig");
expect(tick.indexOf("hzFontName()") >= 0 && tick.indexOf('hzFontName("rg")') >= 0, "resolved font names sit in the content sig");
expect(tick.indexOf("hzT19Tok(this.hzT19Key") >= 0, "live key identity is length-prefixed");
expect(tick.indexOf("kind == \"\"") >= 0 || tick.indexOf('kind == ""') >= 0, "empty kind still fades on target loss");
expect(funcBody(as, "hzT19Off").indexOf("hzT19ResetPay") >= 0, "target off clears fingerprints");
expect(funcBody(as, "hzTW").indexOf("twFn") >= 0 && funcBody(as, "hzTW").indexOf("hzFontName") >= 0, "width cache misses on resolved font");
expect(funcBody(as, "hzOnTgAct").indexOf("hzT19Ver++") < 0 && funcBody(as, "hzOnTgItems").indexOf("hzT19Ver++") < 0, "events do not blindly bump ver");
expect(as.indexOf("if(!this.hzFadeCards)") >= 0 && tick.indexOf("hzFadeCards") < 0, "FadeCards still does not gate hover");
expect(scan.indexOf("hzsPerfSkipDraw") >= 0 && scan.indexOf("hzsFrame % 6") >= 0, "scanner skip + 6-frame walk stay");
expect(funcBody(scan, "hzsPerfSkipDraw").indexOf("hzsPerfMode == 2") < 0, "Mode B does not skip scanner draw");
expect(tick.indexOf("hzPerfSkipHover") >= 0 && tick.indexOf("hz38Vanilla") > tick.indexOf("hzPerfSkipHover"), "Mode A returns before vanilla hide");
expect(perfH.indexOf("std::thr") < 0, "perf header starts no worker");
expect(main.indexOf("QueryPerformanceCounter") >= 0, "native clock is QPC");
expect(as.indexOf("clock=getTimer_ms") >= 0, "AS dump names getTimer");
expect(as.indexOf("clock=hz41Now_ms") < 0, "AS dump does not name Date/hz41Now");
expect(funcBody(as, "hzPerfNow").indexOf("getTimer()") >= 0 && funcBody(as, "hzPerfNow").indexOf("new Date") < 0,
	"hzPerfNow uses getTimer, not Date");
expect(funcBody(as, "hzPerfNow").indexOf("hz41NowFn") >= 0, "injected test clock still wins in hzPerfNow");
expect(funcBody(as, "hz41Now").indexOf("new Date().getTime()") >= 0, "gameplay clock stays Date");
expect(funcBody(as, "hzPerfBegin").indexOf("hz41Now()") < 0 && funcBody(as, "hzPerfEnd").indexOf("hz41Now()") < 0,
	"perf helpers do not call hz41Now");
expect(as.indexOf("import flash.utils.getTimer") < 0, "injected HUD block has no getTimer import");
expect(funcBody(as, "hzPerfSnapshot").indexOf("sName") < 0, "snapshot has no name field");

function loadPerf() {
	const names = ["hzPerfNow", "hzPerfResetN", "hzPerfReset", "hzPerfBegin", "hzPerfEnd", "hzPerfSnapshot"];
	const self = {
		hzPerfOn: true,
		hzPerfMode: 3,
		hzPerfN: null,
		hzPerfT0: null,
		hzPerfTickHadContent: false,
		hzPerfTickHadAct: false,
		hzPerfTickHadItems: false,
		now: 0,
		hz41NowFn: null,
		getTimer() { return self.now; },
		hz41Now() { throw new Error("hz41Now must not run in perf helpers"); }
	};
	for (const name of names) {
		const body = funcBody(as, name);
		if (!body) throw new Error("missing " + name);
		const params = funcParams(as, name);
		const inner = as3toJs(body).replace(/^\{\s*/, "").replace(/\s*\}$/, "").replace(/\bgetTimer\(\)/g, "self.getTimer()");
		self[name] = eval("(function(self){ return function(" + params.join(",") + "){ " + inner + " }; })")(self);
	}
	return self;
}

{
	const p = loadPerf();
	p.hzPerfResetN();
	p.now = 1000;
	p.hzPerfBegin("tick");
	p.hzPerfBegin("content");
	p.now = 1012;
	p.hzPerfEnd("content");
	p.now = 1014;
	p.hzPerfEnd("tick");
	expect(p.hzPerfN.content === 1 && p.hzPerfN.c2 === 1 && p.hzPerfN.c5 === 1 && p.hzPerfN.c10 === 1,
		"12ms content counts c2/c5/c10");
	expect(p.hzPerfN.tickMax === 14 && p.hzPerfN.tickMaxHadContent === 1 && p.hzPerfN.tickMaxHadAct === 0,
		"worst tick latches content flag, not act");
	p.now = 2000;
	p.hzPerfBegin("tick");
	p.hzPerfTickHadAct = true;
	p.hzPerfTickHadItems = true;
	p.now = 2020;
	p.hzPerfEnd("tick");
	expect(p.hzPerfN.tickMax === 20 && p.hzPerfN.tickMaxHadContent === 0 && p.hzPerfN.tickMaxHadAct === 1
		&& p.hzPerfN.tickMaxHadItems === 1, "new tickMax latches act/items for that tick only");
	p.now = 3000;
	p.hzPerfBegin("content");
	p.now = 3003;
	p.hzPerfEnd("content");
	expect(p.hzPerfN.c2 === 2 && p.hzPerfN.c5 === 1 && p.hzPerfN.c10 === 1, "3ms content counts c2 only");
	const snap = p.hzPerfSnapshot();
	expect(snap.indexOf("c2=2") >= 0 && snap.indexOf("c5=1") >= 0 && snap.indexOf("c10=1") >= 0, "snapshot emits c2/c5/c10");
	expect(snap.indexOf("tickMaxHadContent=0") >= 0 && snap.indexOf("tickMaxHadAct=1") >= 0, "snapshot emits worst-tick flags");
	expect(snap.indexOf("clock=getTimer_ms") >= 0, "snapshot names getTimer clock");
	expect(snap.indexOf("sName") < 0 && snap.indexOf("Crate") < 0 && snap.indexOf("sHeader") < 0, "snapshot has no names");
	expect(p.hzPerfN.content === 0 && p.hzPerfN.c2 === 0, "snapshot resets counters");
	p.hzPerfOn = true;
	p.hzPerfReset();
	p.now = 4000;
	p.hzPerfBegin("content");
	p.now = 4001;
	p.hzPerfEnd("content");
	expect(p.hzPerfN.content === 1 && p.hzPerfN.c2 === 0, "reset window starts clean");
}

{
	const p = loadPerf();
	p.hzPerfResetN();
	p.hz41NowFn = function () { return 5000; };
	p.getTimer = function () { throw new Error("injected clock must win"); };
	expect(p.hzPerfNow() === 5000, "injected hz41NowFn wins over getTimer");
	p.hz41NowFn = null;
	p.getTimer = function () { return 7; };
	expect(p.hzPerfNow() === 7, "production hzPerfNow uses getTimer");
}

{
	const p = loadPerf();
	p.hzPerfOn = false;
	p.hzPerfReset();
	expect(p.hzPerfN == null, "reset is a no-op when diag is off");
}

const watchBlockStart = as.indexOf("// =================== 0.43.1.0 watch + center-reticle rule ===================");
const watchBlockEnd = as.indexOf("// =================== end Horizon UI (HUD module) ===================");
const watch = watchBlockStart >= 0 && watchBlockEnd > watchBlockStart ? as.slice(watchBlockStart, watchBlockEnd) : "";
expect(watch.indexOf("getTimer") < 0, "watch block still has no getTimer");

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("ok hover_perf_test");
