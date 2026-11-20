// 0.43.3.2 item 2 tests: a long keycap label (for example "STEAL FROM [MASTER]", the lock level joined by
// hzT19OneLine) is shown whole on the full hover card and on the compact pill. Run: node tests/prompt_label_width_test.js
// Root cause pinned here: the row label fields (lp / lh) were built 160 units wide and hzT19Buttons never widened
// them, so any label past 160 units was cut at the field edge (no "...") on every locked container whose verb plus
// level is long, owned (STEAL FROM) or not. The fix widens the field (HZ_T19_LBLW) on the row draw; the font size is
// unchanged. Runs the production hzT19Buttons / hzT19Label / hzT19OneLine / hzT19RowFace (types stripped) on a host
// whose text fields clip at their width like the game's, plus one mutant (the widening removed) that must fail.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const AS0 = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

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
	const defs = f.params.split(",").map((p) => p.trim()).filter((p) => /=/.test(p)).map((p) => {
		const n = p.split(":")[0].trim(); const v = p.split("=")[1].trim(); return "if(" + n + " === undefined) " + n + " = " + v + ";";
	}).join("\n");
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/([\w.\]\)]+) as (?:Array|MovieClip|Object)/g, "$1")
		.replace(/([\w.]+) is Array/g, "Array.isArray($1)")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/\b(HZ_T19_\w+|HZ_ACCENT)\b/g, "this.$1");
	return new Function(...params, defs + "\n" + body);
}
global.TextField = (t) => t;
global.int = (v) => v | 0;
global.uint = (v) => v >>> 0;

const CW = 9;   // test font: units per character at size 13 (the shape matters, not the number)
function tf(name, w, fs, ls) {
	const t = { name, width: w, x: 0, y: 0, visible: false, _t: "", fs, ls, shownText: "" };
	Object.defineProperty(t, "text", { get() { return this._t; }, set(v) { this._t = String(v); } });
	return t;
}
// what the player sees: the characters that fit inside the field (a non-wrapping field cuts at its edge)
function visibleText(t) {
	const per = CW * t.fs / 13 + t.ls;
	const n = Math.max(0, Math.floor((t.width - 2) / per));
	return t._t.length <= n ? t._t : t._t.substr(0, n);
}
function makeHost(src) {
	const slots = [];
	for (let i = 0; i < 4; i++) slots.push({ kp: tf("kp", 60, 12, 0), lp: tf("lp", 160, 13, 1.6), hh: tf("hh", 60, 11, 1.2), kh: tf("kh", 60, 12, 0), lh: tf("lh", 160, 13, 1.6) });
	const h = {
		HZ_ACCENT: 0x6FD3FF, hzT19Btn: slots, fsLog: [],
		hzDarkText() { return false; }, hzIconCol(c) { return c; }, hzMix(a) { return a; }, hzPanelFill() { return 0; },
		hzT19Key() { return "E"; }, hzT19VanLbl() { return ""; }, hzT19Xl(s) { return s; },
		hzT19U() { return 1; }, hzSnapU(v) { return Math.round(v); }, hzChipSzOn(fs) { return fs; }, hzT19KeyOv() { return null; },
		hzTxtObj(t) { return { tf: t }; }, hzApplyFmt() { },
		hzT19FaceFs(t, fs) { t.fs = fs; this.fsLog.push(fs); },
		// textWidth of a non-wrapping field: the text width, never past the field (what the screenshot pill shows)
		hzTW(t) { const per = CW * t.fs / 13 + t.ls; return Math.min(t._t.length * per, Math.max(0, t.width - 2)); },
		hzKeycap() { }, hzTxtTint() { }, hzTxtTopU() { }, hzCapTop() { return 0; },
		hzFitText(t, full, maxW) {
			t.text = full;
			if (this.hzTW(t) <= maxW - 4 || full.length < 2) return;
			let n = full.length; while (n > 1) { t.text = full.substr(0, n) + "..."; if (this.hzTW(t) <= maxW - 4) return; n--; }
		},
	};
	const m = /private static const HZ_T19_LBLW:Number = (\d+);/.exec(src);
	if (m) h.HZ_T19_LBLW = Number(m[1]);
	for (const n of ["hzT19Buttons", "hzT19Label", "hzT19OneLine", "hzT19Trim", "hzT19RowFace", "hzT19PillCap", "hzT19CapH"]) h[n] = toJs(src, n).bind(h);
	return h;
}
const btn = (press, extra) => Object.assign({ iType: 0, bVisible: true, bEnabled: true, bPressAndRelease: true, bPressAndHold: false, sTextPressAndRelease: press }, extra || {});
// the row as the player sees it: every visible label's visible characters
function seen(h) { return h.hzT19Btn.filter((s) => s.lp.visible).map((s) => visibleText(s.lp)); }
function draw(src, aButtons, maxW, lineFs, stealing) {
	const h = makeHost(src);
	const a = { aButtons, bStealing: !!stealing };
	const w0 = h.hzT19Buttons(null, a, {}, 0, 0, 0xFFFFFF, maxW || 0, lineFs || 0);
	const w1 = h.hzT19Buttons({}, a, {}, 0, 0, 0xFFFFFF, maxW || 0, lineFs || 0);
	return { h, w0, w1, seen: seen(h) };
}

function behave(src, log) {
	const bad = [];
	const chk = (c, m) => { if (log) expect(c, m); if (!c) bad.push(m); };
	try {
		const STEAL = "Steal From\n[Master]";
		const full = draw(src, [btn(STEAL)], 0, 0, true);
		chk(full.seen[0] === "STEAL FROM [MASTER]", "full card, owned locked safe: the whole label incl. the lock level (" + full.seen[0] + ")");
		const pill = draw(src, [btn(STEAL)], 0, 14, true);
		chk(pill.seen[0] === "STEAL FROM [MASTER]", "compact pill, owned locked safe: the whole label (" + pill.seen[0] + ")");
		chk(pill.w0 === pill.w1 && pill.w0 > 160, "the measured row width (the pill / card size) covers the whole label");
		chk(pill.h.fsLog.every((f) => f === 14), "compact pill: the label keeps the pill line size 14 (no shrinking)");
		chk(full.h.fsLog.filter((f) => f === 13).length > 0 && full.h.fsLog.every((f) => f >= 11), "full card: the label keeps its size 13 (no shrinking)");
		const un = draw(src, [btn("Unlock\n[Advanced]")], 0, 14, false);
		chk(un.seen[0] === "UNLOCK [ADVANCED]", "not owned: UNLOCK [ADVANCED] whole too (same path, not owner-specific)");
		const two = draw(src, [btn(STEAL), btn("Transfer", { iType: 1 })], 0, 0, true);
		chk(two.seen.join("|") === "STEAL FROM [MASTER]|TRANSFER", "two buttons: both whole");
		const lim = draw(src, [btn(STEAL)], 150, 0, true);
		chk(lim.seen.length === 1 && /\.\.\.$/.test(lim.seen[0]), "a row with a width limit still fits with \"...\" (the existing fit)");
		const short = draw(src, [btn("Open")], 0, 14, false);
		chk(short.seen[0] === "OPEN", "a short label is unchanged");
	} catch (e) { bad.push("threw: " + e.message); if (log) expect(false, "threw: " + e.message); }
	return bad;
}

// ---- production ----
expect(behave(AS0, true).length === 0, "all label width checks pass on the production source");

// ---- source rules ----
const body = fnText(AS0, "hzT19Buttons").body;
expect((body.match(/HZ_T19_LBLW/g) || []).length === 2 && /if\(lt\.width != HZ_T19_LBLW\) \{ lt\.width = HZ_T19_LBLW; \}/.test(body), "hzT19Buttons sets the label field width only when it differs (row draws / measures only)");
expect(/private static const HZ_T19_LBLW:Number = (\d+);/.test(AS0) && Number(/HZ_T19_LBLW:Number = (\d+)/.exec(AS0)[1]) >= 400, "HZ_T19_LBLW is wide enough for a long verb plus a lock level");
expect((AS0.match(/HZ_T19_LBLW/g) || []).length === 3, "HZ_T19_LBLW is used nowhere else");
expect(!/addEventListener|Timer|ENTER_FRAME|getTimer|hzFindByName/.test(body), "hzT19Buttons: no listener, timer or search");
expect(/this\.hzT\(p,"",0,0,160,13,"sb","main",1\.6\)/.test(AS0), "the fields are still built as before (the width is set on the row draw)");

// ---- mutant ----
{
	const from = "if(lt.width != HZ_T19_LBLW) { lt.width = HZ_T19_LBLW; }";
	const bad = AS0.indexOf(from) >= 0 ? behave(AS0.replace(from, ""), false) : ["anchor"];
	expect(bad.length > 0 && bad[0] !== "anchor" && /STEAL FROM/.test(bad[0]), "mutant without the widening is caught: " + (bad[0] || "-"));
}

console.log("prompt label width: " + passed + " ok, " + (failed ? failed + " FAILED" : "all passed"));
process.exit(failed ? 1 : 0);
