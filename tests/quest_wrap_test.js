// Quest log wrap tests (0.43.3.0). Run: node tests/quest_wrap_test.js
// Runs the production AS quest functions (hzQSync and its memo, hz27QLayout, the new wrap helpers) on a TextField
// model with word wrap, and checks the source: QuestsWidth / QuestsMaxHeight / QuestsWrap plumbing, wrapping at the
// same font size, the max-height cap (ellipsis on the last line only), the compact form under the name, and that a
// wrap is measured only on a text / width / cap / format change (a distance tick or a steady frame measures nothing).
// Author: Moragar. Last modified: 2026-11-14 (r2: INI clamp tests).
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
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) i = src.indexOf("public function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
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
		.replace(/(?<!new )\bTextField\(/g, "(")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.*]+\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim());
}
function bind(host, name) {
	const f = fnText(as, name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}
const constOf = (n) => { const m = as.match(new RegExp("static const " + n + ":(?:int|Number) = ([\\d.]+);")); if (!m) throw new Error(n); return Number(m[1]); };

// ---- TextField model: char width = 0.55 * size; word wrap greedy at the field width (2 px gutter) ----
const COST = { lines: 0, sets: 0, tw: 0 };
function TF(size) {
	this._t = ""; this.size = size; this.wordWrap = false; this.multiline = false; this.width = 100; this.height = 20; this.x = 0; this.y = 0; this.visible = true;
}
Object.defineProperty(TF.prototype, "text", { get() { return this._t; }, set(v) { COST.sets++; this._t = String(v); } });
TF.prototype.cw = function () { return 0.55 * this.size; };
Object.defineProperty(TF.prototype, "numLines", {
	get() {
		COST.lines++;
		if (!this.wordWrap) return 1;
		const max = this.width - 4;
		let n = 1, cur = 0;
		for (const w of this._t.split(" ")) {
			const ww = w.length * this.cw();
			const add = cur === 0 ? ww : cur + this.cw() + ww;
			if (add > max && cur > 0) { n++; cur = ww; } else cur = add;
		}
		return n;
	}
});
function makeHost(opt) {
	const h = Object.assign({
		int: (v) => Number(v) | 0,
		HZ_Q19_W: constOf("HZ_Q19_W"), HZ_CQ19_W: constOf("HZ_CQ19_W"), HZ_QS_N: 12, HZ_QS_W: 9,
		HZ_QW_MIN: constOf("HZ_QW_MIN"), HZ_QW_MAX: constOf("HZ_QW_MAX"), HZ_QH_MIN: constOf("HZ_QH_MIN"), HZ_QH_MAX: constOf("HZ_QH_MAX"),
		hzPerfOn: false, hzTextScale: 1, hzHeaderStyle: 0, hzFontFace: 1, hzFont: "F", hz30Mod: { font: 1 }, hzLsMode: 0, hzLaidOut: true,
		hzQName: "", hzQObjStr: "", hzQDistStr: "", hz27QSubs: [], hz27QL: [], hz27QLD: [], hz27QH: 78,
		hzQW: 380, hzQMaxH: 160, hzQWrap: true, hzQPW: 380, hzQDW: 380, hzCQDW: 420, hzCQH: 36, hzCQPW: 420, hzCQOMv: false,
		hzQTopT: 10, hzQTopO: 37, hzQObjB: 54, hzQSubY0: 60, hzQSubN: 0, hzCQTopO: 26,
		hzQsOk: false, hzQsR: null, hzQsName: null, hzQsObj: null, hzQsDist: null, hzQsSubN: -1, hzQsSubD: null, hzQsSubT: null, hzQsSubO: null,
		hzQsHdr: -1, hzQsTs: NaN, hzQsFace: -1, hzQsFont: null, hzQsFMod: null, hzQsLs: -2, hzQsQL: null, hzQsQLD: null, hzQsQLN: -1, hzQsH: NaN, hzQsMc: null,
		hzFontLive: "Exo2", hzQsLive: "Exo2", hzFontText(s) { return s; },
		hzQsW: NaN, hzQsMh: NaN, hzQsWr: null, HorizonQuest_mc: {}, HorizonCompactQuest_mc: {},
		draws: 0, sz: {}, fmts: 0,
		hzTxtObj(tf) { return tf ? tf._o : null; },
		hzApplyFmt(o) { o.fmtN = (o.fmtN | 0) + 1; this.fmts++; o.tf.height = (o.fs + 5) * (o.lines > 1 ? o.lines : 1) + 6; },
		hzTW(tf) { COST.tw++; return tf.text.length * tf.cw(); },
		hzUC(s) { return String(s).toUpperCase(); },
		hzTxtTop(tf, y) { tf.y = y; },
		hzSetSz(c, w, hh) { this.sz[c === this.HorizonQuest_mc ? "q" : "cq"] = { w, h: hh }; },
		hzQDraw19() { this.draws++; },
	}, opt || {});
	const mk = (x, w, fs) => { const t = new TF(fs); t.x = x; t.width = w; t._o = { tf: t, fs, fmtN: 0 }; return t; };
	h.hzQ19T = mk(74, 208, 15); h.hzQ19D = mk(282, 84, 14); h.hzQ19O = mk(74, 292, 13);
	h.hzCQ19T = mk(32, 200, 12); h.hzCQ19O = mk(120, 200, 12); h.hzCQ19D = mk(326, 80, 12);
	for (let i = 0; i < 3; i++) { h.hz27QL.push(mk(74, 292, 13)); h.hz27QLD.push(mk(286, 80, 13)); }
	for (const n of ["hzQSync", "hzQsSame", "hzQsKeep", "hzQsTops", "hzQsField", "hz27QLayout", "hzFitText", "hzQWrapTo", "hzQOneLine", "hzQWrapStd", "hzQWrapCmp", "hzCQW", "hzCQSize", "hzQWClamp", "hzQHClamp"]) bind(h, n);
	return h;
}
const OBJ = "Travel to the Scorpius system, dock with The Eye, and help Matteo and Noel get the remaining artifacts to safety before the Hunter arrives";
const quest = (h, obj, dist) => { h.hzQName = "High Price to Pay"; h.hzQObjStr = obj == null ? OBJ : obj; h.hzQDistStr = dist == null ? "12.6 km" : dist; };

// ---- source / plumbing ----
expect(/private var hzQW:Number = 380;/.test(as) && /private var hzQMaxH:Number = 160;/.test(as) && /private var hzQWrap:Boolean = true;/.test(as), "defaults: width 380 (today's card), max height 160, wrap on");
expect(/"QuestsWidth":380,"QuestsMaxHeight":160,"QuestsWrap":1,/.test(as), "HZ_SET_DEF: the three keys");
expect(/\nQuestsWidth=380\nQuestsMaxHeight=160\nQuestsWrap=1\n/.test(ini), "default.ini: QuestsWidth=380, QuestsMaxHeight=160, QuestsWrap=1");
const rows = fnText(as, "hz34CardRows").body;
expect(/\{"k":"QuestsWidth","l":"WIDTH","t":"n","mn":380,"mx":660,"st":20,"sub":true/.test(rows) && /\{"k":"QuestsMaxHeight","l":"MAX HEIGHT","t":"n","mn":100,"mx":300,"st":10,"sub":true/.test(rows) && /\{"k":"QuestsWrap","l":"TEXT WRAP","t":"b","sub":true/.test(rows), "F11 CARDS > QUEST TRACKER: WIDTH 380 - 660, MAX HEIGHT 100 - 300, TEXT WRAP (mockup)");
expect(rows.indexOf('this.hz34Cmp("Quests"') < rows.indexOf('"QuestsWidth"'), "the rows sit under the quest tracker's STYLE (compact form) row");
expect(/"questswidth"/.test(fnText(as, "hz34Ini").body) && /"questsmaxheight"/.test(fnText(as, "hz34Ini").body) && /"questswrap"/.test(fnText(as, "hz34Ini").body), "INI parser reads the keys");
expect(/o\.QuestsWidth = this\.hzQW;/.test(fnText(as, "hz34SetCur").body) && /QuestsWrap=/.test(fnText(as, "hz34IniLines").body), "F11 current values and the writer");
expect(/right - this\.hzQW \* sQ/.test(fnText(as, "hzLayout").body) && /right - this\.hzCQW\(\) \* sQ/.test(fnText(as, "hzLayout").body), "the default spot (top right) follows the width");
const NEW = ["hzQWrapTo", "hzQOneLine", "hzQWrapStd", "hzQWrapCmp", "hzCQSize"].map((n) => fnText(as, n).body).join("\n");
expect(!/Timer|setTimeout|setInterval|ENTER_FRAME|addEventListener|hzFindByName|getChildByName/.test(NEW), "no timer / frame / listener / search code in the wrap helpers");
expect(fnText(as, "hzQSync").body.indexOf("this.hzQsSame()") < fnText(as, "hzQSync").body.indexOf("hzQWrapStd"), "hzQSync still runs its change-only memo before any wrap");
{
	const h = makeHost();
	expect(h.hzQWClamp(100) === 380 && h.hzQWClamp(999) === 660 && h.hzQWClamp(521.4) === 521 && h.hzQWClamp("") === 380, "QuestsWidth clamps to 380 - 660");
	expect(h.hzQHClamp(10) === 100 && h.hzQHClamp(999) === 300 && h.hzQHClamp(undefined) === 160, "QuestsMaxHeight clamps to 100 - 300 (empty = 160)");
}

// ---- INI / F11 / writer clamps (0.43.3.0 r2, review N-2) ----
{
	const h = makeHost({ HZ34_CARDS: [], hzLaidOut: true });
	bind(h, "hz34Ini");
	const ini = (k, v) => { h.hzLaidOut = true; const r = h.hz34Ini(k, v); return r === true && h.hzLaidOut === false; };
	expect(ini("questsmaxheight", 50) && h.hzQMaxH === 100, "INI QuestsMaxHeight=50 clamps to 100");
	expect(ini("questsmaxheight", 999) && h.hzQMaxH === 300, "INI QuestsMaxHeight=999 clamps to 300");
	expect(ini("questsmaxheight", 250) && h.hzQMaxH === 250, "INI QuestsMaxHeight=250 is kept (inside 100 - 300)");
	expect(ini("questsmaxheight", 187.6) && h.hzQMaxH === 188, "INI QuestsMaxHeight=187.6 rounds to 188");
	expect(ini("questsmaxheight", NaN) && h.hzQMaxH === 160, "INI QuestsMaxHeight empty / not a number = 160");
	expect(ini("questswidth", 100) && h.hzQW === 380, "INI QuestsWidth=100 clamps to 380");
	expect(ini("questswidth", 9999) && h.hzQW === 660, "INI QuestsWidth=9999 clamps to 660");
	expect(ini("questswidth", 521.4) && h.hzQW === 521, "INI QuestsWidth=521.4 rounds to 521");
	expect(ini("questswidth", NaN) && h.hzQW === 380, "INI QuestsWidth not a number = 380");
	expect(ini("questswrap", 0) && h.hzQWrap === false && ini("questswrap", 1) && h.hzQWrap === true && ini("questswrap", NaN) && h.hzQWrap === true, "INI QuestsWrap 0 / 1 / empty");
	// F11 live and the save writer use the same clamps
	const live = fnText(as, "hz34SetLive").body.split("\n").filter((l) => /p\.Quests(Width|MaxHeight) !== undefined/.test(l)).join("\n");
	const runLive = Function.apply(null, ["p", "with(this){ var qd = false;\n" + toJs(live) + "\n return qd; }"]).bind(h);
	h.hzQW = 380; h.hzQMaxH = 160;
	expect(runLive({ QuestsWidth: 5000, QuestsMaxHeight: 5000 }) === true && h.hzQW === 660 && h.hzQMaxH === 300, "F11 live: out-of-range values clamp (660 / 300)");
	expect(runLive({ QuestsWidth: 660, QuestsMaxHeight: 300 }) === false, "F11 live: the same values again = no redraw");
	const wr = fnText(as, "hz34IniLines").body.split("\n").filter((l) => /a\.push\("Quests(Width|MaxHeight)=/.test(l)).join("\n");
	const runWr = Function.apply(null, ["p", "with(this){ var a = [];\n" + toJs(wr) + "\n return a.join(','); }"]).bind(h);
	expect(runWr({ QuestsWidth: 10, QuestsMaxHeight: 9000 }) === "QuestsWidth=380,QuestsMaxHeight=300", "save writer: clamped values are written");
	const rowsN = fnText(as, "hz34CardRows").body;
	const mxOf = (k) => { const m = rowsN.match(new RegExp('\\{"k":"' + k + '"[^}]*"mn":(\\d+),"mx":(\\d+)')); return m ? [Number(m[1]), Number(m[2])] : null; };
	expect(String(mxOf("QuestsMaxHeight")) === String([constOf("HZ_QH_MIN"), constOf("HZ_QH_MAX")]) && String(mxOf("QuestsWidth")) === String([constOf("HZ_QW_MIN"), constOf("HZ_QW_MAX")]), "F11 slider ranges match the INI clamps (100 - 300, 380 - 660)");
}

// ---- standard card ----
{
	const h = makeHost(); quest(h); h.hzQSync();
	const o = h.hzQ19O;
	expect(o.wordWrap && o._o.lines > 1 && o.text === OBJ, "380: the objective wraps onto new lines with the full text (no ellipsis)");
	expect(o._o.fs === 13 && h.hzQ19T._o.fs === 15, "same font size (13 / 15) as the one-line card");
	expect(h.hzQ19T.text === "HIGH PRICE TO PAY" && h.hzQ19T.y === 10 && o.y === 37, "title at 10, objective at 37 (today's tops)");
	const pO = 17;
	expect(h.hz27QH === Math.max(78, 37 + o._o.lines * pO + 12) && h.sz.q.h === h.hz27QH && h.hzLaidOut === false && h.draws >= 1, "the card grows to fit and asks for one layout / redraw");
	const n380 = o._o.lines;
	const w = makeHost({ hzQW: 660 }); quest(w); w.hzQSync();
	expect(w.hzQ19O._o.lines < n380 && w.hzQ19O.width === 660 - 74 - 14 && w.sz.q.w === 660 && w.hzQ19D.x === 660 - 14 - 84, "660: fewer lines, wider fields, the distance column moves");
	const s = makeHost({ hzQMaxH: 100 }); quest(s); s.hzQSync();
	const cap = Math.max(1, Math.floor((100 - 8 - 37) / pO));
	expect(s.hzQ19O._o.lines === cap && /\.\.\.$/.test(s.hzQ19O.text) && s.hzQ19O.numLines <= cap && s.hz27QH <= 100, "max height 100: the objective stops at " + cap + " lines and only its last line ends in ...");
	const sh = makeHost(); quest(sh, "Short objective"); sh.hzQSync();
	expect(sh.hzQ19O._o.lines !== 2 && sh.hz27QH === 78 && sh.hzQ19O.text === "Short objective", "a short objective: one line, the classic 78 height");
	const lt = makeHost(); lt.hzQName = "A Very Long Quest Name That Will Never Fit On One Line Of The Card"; lt.hzQObjStr = "x"; lt.hzQSync();
	expect(lt.hzQ19T._o.lines === 2 && /\.\.\.$/.test(lt.hzQ19T.text) && lt.hzQ19O.y === 10 + 2 * 20 + 7, "a long title wraps to 2 lines at most (ellipsis on the second), the objective moves down");
	const tc = makeHost({ hzQMaxH: 100 }); quest(tc); tc.hzQName = "A Very Long Quest Name That Will Never Fit On One Line Of The Card"; tc.hzQSync();
	expect(tc.hzQ19T._o.lines === 2 && tc.hz27QH === 100 && tc.sz.q.h === 100, "a 2-line title and a long objective at max height 100: the card stops at 100");
	const sb = makeHost({ hzQMaxH: 130 }); quest(sb); sb.hz27QSubs = [{ d: "", t: "Step one" }, { d: "", t: "Step two" }, { d: "", t: "Step three" }]; sb.hzQSync();
	expect(sb.hzQSubN < 3 && sb.hzQSubY0 + sb.hzQSubN * 22 + 8 <= 130 && sb.hz27QH <= 130, "sub-steps that do not fit under the max height are left out");
}
// ---- edge-only: measures only on a change ----
{
	const h = makeHost(); quest(h); h.hzQSync();
	let c0 = COST.lines;
	for (let i = 0; i < 100; i++) h.hzQSync();
	expect(COST.lines === c0, "steady frames: no wrap measure (memo)");
	c0 = COST.lines;
	for (let i = 0; i < 100; i++) { h.hzQDistStr = (12 - i * 0.1).toFixed(1) + " km"; h.hzQSync(); }
	expect(COST.lines === c0, "100 distance ticks: the title and the objective are not re-wrapped (fixed distance column)");
	h.hzQObjStr = OBJ + " now"; h.hzQSync();
	expect(COST.lines > c0, "a new objective text re-wraps");
	c0 = COST.lines; h.hzQSync();
	expect(COST.lines === c0, "then steady again");
	h.hzQ19O._o.fmtN++; h.hzQsOk = false; h.hzQSync();
	expect(COST.lines > c0, "a format change (font / size / style) re-wraps");
	c0 = COST.lines; h.hzQW = 520; h.hzQSync();
	expect(COST.lines > c0 && h.sz.q.w === 520, "a width change re-wraps");
}
// ---- compact ----
{
	const h = makeHost({ hzQW: 520 }); quest(h); h.hzQSync();
	const o = h.hzCQ19O;
	expect(o.x === 32 && o.y === 26 && o.wordWrap && o._o.lines >= 2 && o.text === OBJ, "compact: the objective sits under the name (x 32, top 26) and wraps");
	expect(h.hzCQH === Math.min(Math.max(36, 26 + o._o.lines * 16 + 8), 160) && h.sz.cq.w === 520 && h.sz.cq.h === h.hzCQH, "compact: 520 wide, height = 26 + lines x 16 + 8 (66 for two lines, the mockup)");
	expect(h.hzCQ19T.text === "HIGH PRICE TO PAY" && h.hzCQ19T._o.fs === 12 && o._o.fs === 12, "compact: same 12 px type");
	const d = makeHost(); quest(d); d.hzQSync();
	expect(d.sz.cq.w === 420, "compact at the default width keeps today's 420");
	const n = makeHost(); quest(n, ""); n.hzQSync();
	expect(n.hzCQH === 36 && !n.hzCQ19O.visible, "compact without an objective: today's 36 strip");
}
// ---- wrap off = today's one-line card ----
{
	const h = makeHost(); quest(h); h.hzQSync();
	h.hzQWrap = false; h.hzQSync();
	expect(!h.hzQ19O.wordWrap && !(h.hzQ19O._o.lines > 1) && /\.\.\.$/.test(h.hzQ19O.text) && h.hzQ19O.width === 292, "wrap off: one line with an ellipsis, the classic field width");
	expect(h.hz27QH === 78 && h.hzCQH === 36 && !h.hzCQ19O.wordWrap && h.hzCQ19O.y === 9, "wrap off: classic heights (78 / 36), the compact objective back on the name row");
	h.hzQWrap = true; h.hzQSync();
	expect(h.hzQ19O.wordWrap && h.hzQ19O.text === OBJ, "wrap on again: wraps again");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("quest wrap: " + passed + " ok, all passed");
