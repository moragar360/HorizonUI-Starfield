// arch-fixes Fix 2 tests: the scanner and Comms movies re-read settings on a real change only.
// Run: node tests/arch_fix2_test.js   (HZS_AS / HZC_AS / HZ_CPP=<file> run it against other sources, used by the mutants)
// Proves, by running the production AS functions (types stripped) on small models, in every shipped copy:
//  1. scanner (hzs_block.as and both MonocleMenu.as): no 2 s re-read in the frame tick; the open hook still re-reads;
//     a changed settings text bumps one int (no serialized config); the draw signatures use that int and the visible
//     rect revision (no config string); hzsSer has no sort; hzsUpdVr converts only when the visible rect changed;
//  2. Comms (hzc_block.as and both HUDMessagesMenu.as): the 5 s timer runs only until the DLL announces hzcIniSaved;
//     hzcIniSaved stops it and re-reads once; a save during an in-flight read reads again (no stale text kept);
//  3. DLL (src/main.cpp): the job thread only bumps a counter after a user.ini write; the Invoke runs in BannerPoll
//     (the HUD messages movie's AdvanceFrame), looks the menu up per call and keeps no menuObj / GFx value;
//  4. the three copies of each changed function are the same text.
// Author: Moragar. Last modified: 2026-11-13.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const rd = (p) => fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n");
const SCAN = [process.env.HZS_AS || path.join(root, "actionscript", "scanner", "hzs_block.as"),
	path.join(root, "actionscript", "imp", "simp_monoclemenu", "MonocleMenu.as"),
	path.join(root, "actionscript", "imp", "simp_monoclemenu_lrg", "MonocleMenu.as")];
const COMMS = [process.env.HZC_AS || path.join(root, "actionscript", "comms", "hzc_block.as"),
	path.join(root, "actionscript", "imp", "imp", "scripts", "HUDMessagesMenu.as"),
	path.join(root, "actionscript", "imp", "imp-Lrg", "scripts", "HUDMessagesMenu.as")];
const cpp = rd(process.env.HZ_CPP || path.join(root, "src", "main.cpp"));

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(");
	const m = re.exec(src);
	if (!m) throw new Error("missing function " + name);
	const brace = src.indexOf("{", m.index);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(m.index, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function codeOnly(body) { return body.replace(/\/\/[^\n]*/g, ""); }
function toJs(body) {
	return body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*(?:Error|\*)\s*\)\s*\{/g, "catch($1) {")
		.replace(/for each\s*\(\s*var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+\s+in\s+/g, "for (var $1 of ")
		.replace(/for\s*\(\s*var\s+([A-Za-z_]\w*)\s*:\s*String\s+in\s+/g, "for (var $1 in ")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "")
		.replace(/\bo is Array\b/g, "Array.isArray(o)");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
function bind(h, src, names, G) {
	const wrap = new Proxy(h, { get(t, k) { if (k in t) return t[k]; if (G && k in G) return G[k]; return undefined; }, has(t, k) { return typeof k === "string" && (k in t || !!(G && k in G)); } });
	for (const n of names) {
		const f = fnText(src, n);
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}

// ---- 1. scanner ----
SCAN.forEach((file, fi) => {
	const tag = ["hzs_block", "MonocleMenu", "MonocleMenu_lrg"][fi];
	const src = rd(file);
	const tick = codeOnly(fnText(src, "hzsTick").body);
	expect(!/hzsRead\(/.test(tick) && tick.indexOf("hzsPollT") < 0 && tick.indexOf("2000") < 0, tag + ": the frame tick never re-reads the settings (no 2 s poll)");
	expect(/this\.hzsRead\(\);/.test(fnText(src, "hzsOnOpened").body) && /this\.hzsRead\(\);/.test(fnText(src, "hzsInit").body), tag + ": settings are still read at start and on every open");
	expect(src.indexOf("hzsCfgSig") < 0 && src.indexOf("hzsVrSig") < 0, tag + ": no config or visible-rect signature string is kept");
	const sites = ["hzsDrawCompassIfMoved", "hzsDrawRet", "hzsDrawMarks"].map((n) => codeOnly(fnText(src, n).body));
	expect(sites.every((b) => b.indexOf("this.hzsCfgRev") >= 0) && sites[0].indexOf("this.hzsVrRev") >= 0 && sites[1].indexOf("this.hzsVrRev") >= 0,
		tag + ": compass, reticle and marker signatures use the config / visible-rect revisions");
	// 0.43.4: the marker layer compares its list field by field; its settings key is the int revision (+ the font state)
	expect((src.match(/\+ "\|" \+ this\.hzsCfgRev/g) || []).length === 3 && /var ck:String = this\.hzsCfgRev \+ "\|" \+ this\.hzsFontLib;/.test(codeOnly(fnText(src, "hzsDrawMarks").body)),
		tag + ": the three signature strings and the marker settings key use the int revision");
	expect(codeOnly(fnText(src, "hzsSer").body).indexOf(".sort(") < 0, tag + ": hzsSer has no sort");
	// hzsOnIni: a changed text bumps the revision once; the same text does not
	{
		let parsed = 0;
		const h = bind({ hzsReading: true, hzs37Got: null, hzsTxt: "", hzsReady: false, hzsCfgRev: 0, hzsSig: null, hzsDirty: false, hzsC: {}, hzsS: {},
			hzsParse: () => { parsed++; }, hzsSer: () => { throw new Error("hzsSer called"); } }, src, ["hzsOnIni"], { HZS_MAX_INI: 65536, String: String, getTimer: () => 0 });   // 0.43.4: hzsOnIni stamps hzsReadT
		h.hzsOnIni("[Scanner]\nA=1");
		h.hzsOnIni("[Scanner]\nA=1");
		const r1 = h.hzsCfgRev;
		h.hzsOnIni("[Scanner]\nA=2");
		expect(r1 === 1 && h.hzsCfgRev === 2 && parsed === 2 && h.hzsDirty === true, tag + ": hzsOnIni bumps the revision only on a changed text, without serializing the config");
	}
	// hzsUpdVr: no conversion on a steady frame
	{
		let g2l = 0;
		const vr = { left: 0, top: 0, right: 1920, bottom: 1080, width: 1920 };
		const G = { Extensions: { get visibleRect() { return vr; } }, Point: function (x, y) { this.x = x; this.y = y; }, Rectangle: function (x, y, w, h) { this.x = x; this.y = y; this.width = w; this.height = h; }, Math: Math, isNaN: isNaN };
		const h = bind({ hzsL: { globalToLocal: (p) => { g2l++; return { x: p.x / 2, y: p.y / 2 }; } }, hzsVr: null, hzsVrIn: null, hzsVrRev: 0, hzsVrL: NaN, hzsVrT: NaN, hzsVrR: NaN, hzsVrB: NaN, hzsSig: null, hzsDirty: false },
			src, ["hzsUpdVr"], G);
		h.hzsUpdVr();
		const c1 = g2l;
		for (let i = 0; i < 60; i++) h.hzsUpdVr();
		expect(c1 === 2 && g2l === 2 && h.hzsVrRev === 1 && h.hzsVr && h.hzsVr.width === 960, tag + ": hzsUpdVr converts once, then 60 steady frames convert nothing");
		vr.right = 1920.4;
		h.hzsUpdVr();
		expect(g2l === 4 && h.hzsVrRev === 1, tag + ": a sub-pixel change converts but does not redraw (same rounded rule as before)");
		vr.right = 2560; vr.width = 2560;
		h.hzsDirty = false;
		h.hzsUpdVr();
		expect(h.hzsVrRev === 2 && h.hzsDirty === true && h.hzsVr.width === 1280, tag + ": a real change bumps the revision and redraws");
	}
	// hzsSer: same content in another key order differs at most (never the same text for different content)
	{
		const h = bind({}, src, ["hzsSer"], { String: String });
		const a = h.hzsSer({ x: 1, y: [1, 2] }), b = h.hzsSer({ x: 1, y: [1, 3] });
		expect(a !== b && a === h.hzsSer({ x: 1, y: [1, 2] }), tag + ": hzsSer still tells different models apart and repeats for the same model");
	}
});

// ---- 2. Comms ----
COMMS.forEach((file, fi) => {
	const tag = ["hzc_block", "HUDMessagesMenu", "HUDMessagesMenu_lrg"][fi];
	const src = rd(file);
	const timers = [];
	function Timer(ms) { this.ms = ms; this.on = false; this.l = 0; timers.push(this); }
	Timer.prototype.start = function () { this.on = true; };
	Timer.prototype.stop = function () { this.on = false; };
	Timer.prototype.addEventListener = function () { this.l++; };
	Timer.prototype.removeEventListener = function () { this.l--; };
	const G = { Timer: Timer, TimerEvent: { TIMER: "timer" }, int: (v) => Math.trunc(Number(v)) | 0 };
	let reads = 0;
	const h = bind({ hzcCfg: { Subtitles: 1, MissionToast: 0 }, hzcPoll: null, hzcIniPush: false, hzcReloadAgain: false, hzcReading: false, hzcFontOk: null, hzcShown: false, hzcRev: null, hzcIniState: 0,
		hzcActive: () => false, hzcHideCards: () => {}, hzcXp: () => {}, hzcRefreshAlphas: () => {}, hzcToastApply: () => {}, hzcRxApply: () => {}, hzcMsgLayout: () => {},
		hzcOnPoll: function () {}, hzc37IniRead: function (cb) { reads++; } }, src, ["hzcApply", "hzcIniSaved", "hzcReload", "hzcOnIniTxt"], G);
	h.hzcApply();
	expect(h.hzcPoll && h.hzcPoll.on && h.hzcPoll.ms === 5000, tag + ": before the DLL announces, the 5 s timer runs as before (an older DLL keeps working)");
	const t = h.hzcPoll;
	h.hzcIniSaved(0);
	expect(h.hzcPoll === null && !t.on && t.l === 0 && h.hzcIniPush === true && reads === 1, tag + ": hzcIniSaved stops and drops the timer and re-reads once");
	h.hzcReading = false;
	h.hzcApply();
	expect(h.hzcPoll === null && timers.length === 1, tag + ": after the announce hzcApply makes no timer");
	h.hzcReading = true;
	h.hzcIniSaved(3);
	expect(reads === 1 && h.hzcReloadAgain === true, tag + ": a save while a read is in flight is remembered");
	h.hzcOnIniTxt("[Comms]\nSubtitles=1");
	expect(reads === 2 && h.hzcReloadAgain === false && h.hzcRev === null, tag + ": the in-flight (maybe stale) text is dropped and read again");
	const sv = codeOnly(fnText(src, "hzcIniSaved").body);
	expect(/^\s*try/.test(sv) && /catch\(e:Error\) \{ \}\s*$/.test(sv), tag + ": hzcIniSaved lets nothing escape into the DLL Invoke");
	expect(/public function hzcIniSaved\(rev:\*\) : void/.test(src), tag + ": hzcIniSaved is public (the DLL Invokes it on the document object)");
});

// ---- 3. DLL ----
{
	const f = (name) => { const mm = new RegExp("\\n\\t(?:void|bool) " + name + "\\(").exec(cpp); const i = mm ? mm.index : -1; if (i < 0) return ""; const b = cpp.indexOf("{", i); let d = 0; for (let p = b; p < cpp.length; p++) { if (cpp[p] === "{") d++; else if (cpp[p] === "}") { d--; if (d === 0) return cpp.slice(b, p + 1); } } return ""; };
	const push = f("IniSavedPushMsg");
	expect(push.length > 0, "DLL: IniSavedPushMsg exists");
	const steady = push.indexOf("if (rev == g_iniSavedSent && root == g_iniSavedRoot) return;");
	expect(steady > 0 && steady < push.indexOf("MenuLive") && steady < push.indexOf("IsMenuOpen"), "DLL: the steady state returns before any menu lookup or Scaleform call");
	expect(/auto msg = MenuLive\(a_ui, "HUDMessagesMenu", "hzcIniSaved"\);/.test(push) && /msg->menuObj\.HasMember\("hzcIniSaved"\)/.test(push) && /msg->menuObj\.Invoke\("hzcIniSaved", nullptr, &arg, 1\)/.test(push),
		"DLL: the menu is looked up per call and asked whether it answers hzcIniSaved first");
	expect(!/static\s+[^;\n]*(GValue|IMenu|Ptr<)/.test(push) && !/^\s*(RE::Scaleform::Ptr|GValue)[^\n;]*g_/m.test(cpp.slice(cpp.indexOf("g_iniSavedSent") - 200, cpp.indexOf("void IniSavedPushMsg"))),
		"DLL: no menuObj / GFx value is stored across calls (only a revision and a root address)");
	expect((cpp.match(/IniSavedPushMsg\(ui\);/g) || []).length === 1 && f("BannerPoll").indexOf("IniSavedPushMsg(ui);") > 0, "DLL: called only from BannerPoll (HUD messages AdvanceFrame, UI thread)");
	const bumps = (cpp.match(/g_iniSavedRev\.fetch_add\(1, std::memory_order_acq_rel\);/g) || []).length;
	const job = f("FilesPollWork");
	expect(bumps === 3 && (job.match(/g_iniSavedRev\.fetch_add/g) || []).length === 3, "DLL: the job thread bumps the counter after each user.ini write (save, preset apply / restore / undo, message log)");
	expect(job.indexOf("Invoke") < 0 && job.indexOf("MenuLive") < 0, "DLL: the job thread never touches Scaleform");
	expect(/kVersion\s*=\s*"0\.43\.3\.0"/.test(cpp), "DLL: HZF::kVersion is 0.43.3.0");
	const sp = f("ScanPushMsg") + f("ScanPushHud");
	expect(sp.indexOf("a_next = a_now + 100;") < 0 && f("ScanPushReady").indexOf("a_next = a_now + 100;") > 0, "DLL: the scan push cadence is unchanged (kept on purpose, see CHANGES)");
}

// ---- 4. the copies match ----
{
	const one = (files, n) => files.map((p) => fnText(rd(p), n).body);
	let same = true;
	for (const n of ["hzsTick", "hzsOnIni", "hzsUpdVr", "hzsSer", "hzsDrawRet", "hzsDrawMarks", "hzsDrawCompassIfMoved"]) { const b = one(SCAN, n); if (b[0] !== b[1] || b[0] !== b[2]) { same = false; console.error("  differs: " + n); } }
	for (const n of ["hzcApply", "hzcIniSaved", "hzcOnIniTxt", "hzcReload"]) { const b = one(COMMS, n); if (b[0] !== b[1] || b[0] !== b[2]) { same = false; console.error("  differs: " + n); } }
	expect(same, "every changed function is the same text in the block and both movie copies");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("arch fix 2: " + passed + " ok, all passed");
