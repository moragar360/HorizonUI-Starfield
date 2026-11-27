// Scanner card names wrap instead of truncating to one "..." line (POI markers, fauna/flora tags, full planet, full signals, bioscan biome).
// Run: node tests/scanner_wrap_test.js
// wrap defaults false so the 0.43.4 trunc pool and shortening tests stay identical to 3ee48a4. Names pass wrap:true
// where the card can grow; compact 44 px strips and resource chips stay one line with "...". Extra lines grow down
// from the first-line center, measured on the pooled field (numLines / textHeight; no throwaway clips per row).
// German and Spanish long names are whole (no "...") where they wrap. Layout still runs only when the marker/tag content changes.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";

const fs = require("fs");
const path = require("path");
const { root, stripComments, fnText, toJs: toJs0 } = require("./lib/r3.js");
const toJs = (b) => toJs0(b.replace(/for each\(var (\w+):String in String\(([\w.]+)\)\.split\(","\)\)/g, 'for (var $1 of String($2).split(","))').replace(/new (Sprite|TextField|MovieClip)\(/g, "new $1__(")).replace(/new (Sprite|TextField|MovieClip)__\(/g, "new $1(");

let failed = 0, passed = 0;
function expect(cond, msg) { if (cond) { passed++; console.log("ok  " + msg); } else { failed++; console.error("FAIL " + msg); } }

const rd = (f) => fs.readFileSync(path.join(root, f), "utf8").replace(/\r\n/g, "\n");
const BLOCK = rd("actionscript/scanner/hzs_block.as");
const AS = stripComments(BLOCK);

let WIDTH = (t) => {
	const f = t.fmt || {}; const sz = Number(f.size) || 12; let w = 0;
	for (let i = 0; i < t._text.length; i++) {
		const ch = t._text[i]; const c = ch.charCodeAt(0);
		let a = ch === " " ? 0.28 : ch === "." ? 0.25 : /[MW]/.test(ch) ? 0.9 : /[il1]/.test(ch) ? 0.3 : 0.55 + (c % 7) * 0.02;
		if (i > 0 && t._text[i - 1] === "A" && ch === "V") a -= 0.08;
		w += a * sz * (String(f.font).indexOf("Bold") >= 0 ? 1.06 : 1) + (Number(f.letterSpacing) || 0);
	}
	return Math.round(w * 100) / 100;
};
function lineCount(t) {
	if (!t.wordWrap || !(t._width > 0)) return 1;
	const words = t._text.split(/(\s+)/);
	let lines = 1, cur = 0;
	const probe = Object.assign(Object.create(Object.getPrototypeOf(t)), t);
	for (const w of words) {
		if (/^\s+$/.test(w) && cur === 0) continue;
		probe._text = (cur === 0 ? w : "x").repeat(1);
		const piece = { fmt: t.fmt, _text: w };
		const ww = WIDTH(piece);
		if (cur === 0) { cur = ww; continue; }
		if (cur + ww <= t._width) cur += ww;
		else { lines++; cur = ww; }
	}
	return Math.max(1, lines);
}
let madeSp = 0, madeTf = 0;
class Gfx { constructor() { this.ops = []; } lineStyle(...a) { this.ops.push(["ls", ...a]); } beginFill(...a) { this.ops.push(["bf", ...a]); } endFill() { this.ops.push(["ef"]); } drawRoundRect(...a) { this.ops.push(["rr", ...a]); } drawCircle() {} drawRect() {} moveTo() {} lineTo() {} clear() { this.ops = []; } }
class DO { constructor() { this.x = 0; this.y = 0; this.alpha = 1; this.visible = true; this.scaleX = 1; this.scaleY = 1; this.name = ""; this.parent = null; } }
class Sprite extends DO {
	constructor() { super(); madeSp++; this.kids = []; this.graphics = new Gfx(); }
	get numChildren() { return this.kids.length; }
	addChild(c) { this.kids.push(c); c.parent = this; return c; }
	addChildAt(c, i) { this.kids.splice(i, 0, c); c.parent = this; return c; }
	removeChildAt(i) { const c = this.kids.splice(i, 1)[0]; if (c) c.parent = null; return c; }
	getChildAt(i) { return this.kids[i]; }
	setChildIndex(c, i) { const j = this.kids.indexOf(c); if (j >= 0) this.kids.splice(j, 1); this.kids.splice(i, 0, c); }
}
class TextField extends DO {
	constructor() { super(); madeTf++; this.__tf = true; this._text = ""; this.fmt = null; this.defaultTextFormat = null; this.wordWrap = false; this.multiline = false; this._width = 0; this.embedFonts = false; this.selectable = false; this.mouseEnabled = false; this.autoSize = "left"; }
	get text() { return this._text; }
	set text(v) { this._text = String(v); this.fmt = this.defaultTextFormat ? Object.assign({}, this.defaultTextFormat) : this.fmt; }
	setTextFormat(f) { this.fmt = Object.assign({}, f); }
	set width(v) { this._width = Number(v) || 0; }
	get width() { return this._width; }
	get textWidth() { return WIDTH(this); }
	get numLines() { return lineCount(this); }
	get textHeight() { return this.height; }
	get height() { return lineCount(this) * Math.round(((this.fmt && Number(this.fmt.size)) || 12) * 1.25 + 4); }
}
function TextFormat(font, size, color) { this.font = font; this.size = size; this.color = color; this.letterSpacing = 0; }
function argList(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => { const n = a.trim().split(":")[0].trim(); const d = a.indexOf("=") >= 0 ? a.slice(a.indexOf("=") + 1).trim() : null; return d != null ? n + " = " + d : n; });
}
const CONST = { HZS_SCALE: 1, HZS_MINPX: 13, HZS_WHITE: 0xFFFFFF, HZS_LABEL: 0xC4D2D9, HZS_MUTED: 0x96A6AE, HZS_AMB: 0xF2A93B, HZS_RED: 0xFF5B5B, HZS_O2B: 0x4DB6FF, HZS_VIO: 0xB48CFF, HZS_BG: 0x0B1218, HZS_R_STRIP: 14, HZS_RAR_N: ["COMMON", "UNCOMMON", "RARE", "EXOTIC", "UNIQUE"], HZS_RAR_C: [0xC4D2D9, 0x5EE3A1, 0x4DB6FF, 0xB48CFF, 0xF2A93B] };
for (const m of AS.matchAll(/private static const (HZS_\w+):(?:Number|uint|int) = (0x[0-9A-Fa-f]+|-?[0-9.]+);/g)) if (!(m[1] in CONST)) CONST[m[1]] = Number(m[2]);
function host(names) {
	const G = Object.assign({ Sprite, TextField, TextFormat, TextFieldAutoSize: { LEFT: "left" }, Math, String, Number, isNaN: (v) => Number.isNaN(Number(v)), int: (v) => Number(v) | 0, uint: (v) => Number(v) >>> 0, hzVals: (o) => (o == null ? [] : Array.isArray(o) ? o.slice() : Object.keys(o).map((k) => o[k])) }, CONST);
	const h = { hzsS: { TextScale: 1 }, hzsTk: 1, hzsTPc: null, hzsTPi: 0, hzsTPMade: 0, hzsTPNew: 0,
		hzsFace: (w) => "$Horizon_Font" + (w === "bd" ? "_Bold" : w === "rg" ? "_Regular" : ""),
		hzsAccent: () => 0x3FD0E0 };
	const wrap = new Proxy(h, { get(t, k) { if (k in t) return t[k]; if (k in G) return G[k]; return undefined; }, has(t, k) { return typeof k === "string" && (k in t || k in G); }, set(t, k, v) { t[k] = v; return true; } });
	for (const n of names) {
		const f = fnText(AS, n);
		if (!f) throw new Error("missing " + n);
		h[n] = Function.apply(null, argList(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}
const T = ["hzsT", "hzsTFmt", "hzsTNew", "hzsTSet", "hzsTrunc", "hzsTOne", "hzsTExtra", "hzsTPBegin", "hzsTPEnd", "hzsFs", "hzsTw"];
const DE = "Antike Begraebnisstaette der Var'uun";
const ES = "Puesto avanzado de investigacion cientifica";

{
	const sig = fnText(AS, "hzsT").sig;
	expect(/wrap:Boolean = false/.test(sig), "hzsT wrap defaults false (trunc identity for the 0.43.4 pool)");
	expect(/font:String = null, wrap:Boolean = false/.test(sig), "wrap is the last argument, after font");
}

{
	const h = host(T);
	const p = new Sprite();
	const short = h.hzsT(p, "Cave", 0, 0, 14, 0xFFFFFF, "sb", 0.12, "l", 1, 260, null, true);
	expect(short.text === "Cave" && short.text.indexOf("...") < 0 && h.hzsTExtra(short, 14) === 0, "a short POI name with wrap stays one line, whole, extra 0");
	const p2 = new Sprite();
	const de = h.hzsT(p2, DE, 0, 0, 14, 0xFFFFFF, "sb", 0.12, "l", 1, 120, null, true);
	expect(de.text === DE && de.text.indexOf("...") < 0 && de.wordWrap === true && h.hzsTExtra(de, 14) > 0, "German POI name wraps whole (no ellipsis) and the field grows");
	const p3 = new Sprite();
	const es = h.hzsT(p3, ES, 0, 0, 15, 0xFFFFFF, "sb", 0.12, "l", 1, 100, null, true);
	expect(es.text === ES && es.text.indexOf("...") < 0 && h.hzsTExtra(es, 15) > 0, "Spanish fauna name wraps whole and the field grows");
	const y0 = de.y;
	const one = h.hzsTOne(14);
	expect(Math.abs(y0 - Math.round(0 - one / 2)) < 1, "wrapped text keeps the first line centered on cy (grows down)");
}

{
	const h = host(T);
	const p = new Sprite();
	const cut = h.hzsT(p, DE, 0, 0, 14, 0xFFFFFF, "sb", 0.12, "l", 1, 80);
	expect(cut.text.indexOf("...") >= 0 && cut.wordWrap !== true, "wrap omitted (chips, counts) still shortens with ...");
	expect(/hzsT\(tp,String\(tag\.sym\),29,26,14,tc,"bd",0,"c",1,32\)/.test(AS) && !/hzsT\(tp,String\(tag\.sym\),[^\n]*true\)/.test(AS), "the tag chip (sym, maxW 32) stays truncated");
}

{
	expect(/hzsT\(sx,String\(m\[4\]\),30,0,14,HZS_WHITE,"sb",0.12,"l",1,260,null,true\)/.test(AS), "POI marker names pass wrap true at 260");
	expect(/hzsT\(tp,String\(tag\.n\),[^\n]+null,true\)/.test(AS) && /hzsT\(tp,String\(tag\.sub\),[^\n]+null,true\)/.test(AS), "world tag name and subtitle wrap");
	expect(/hzsT\(p,String\(m\.name\),[^\n]+null,true\)/.test(AS), "full planet names wrap");
	expect(/hzsT\(p,String\(r\.n\),[^\n]+null,true\)/.test(AS), "full signals names wrap");
	expect(/ph:Number = 26 \+ this\.hzsTExtra\(nt,14\)/.test(AS), "the POI name pill grows by the wrapped extra");
	expect(/hzsCard\(tg,tw,52 \+ extra/.test(AS), "the world tag card grows by the wrapped extra");
	expect(!/null,true/.test(fnText(AS, "hzsDPlanetC").body), "compact planet keeps one line (no wrap true)");
	expect(!/null,true/.test(fnText(AS, "hzsDSigC").body), "compact signals keeps one line (no wrap true)");
	expect(!/null,true/.test(fnText(AS, "hzsResRows").body), "resource chips keep one line (no wrap true)");
	expect(!/new Sprite/.test(fnText(AS, "hzsDSig").body), "signals has no throwaway Sprite");
	expect(/t\.numLines/.test(fnText(AS, "hzsTExtra").body) && /t\.textHeight/.test(fnText(AS, "hzsTExtra").body), "wrap extra is measured on the pooled field (numLines / textHeight)");
	expect(/rowH/.test(fnText(AS, "hzsDSig").body) && /boxH/.test(fnText(AS, "hzsDSig").body), "signals highlight box tracks the measured row height");
}

{
	const draw = fnText(AS, "hzsDrawMarks").body + fnText(AS, "hzsDrawRet").body;
	expect(!/addEventListener|Timer|setInterval|ENTER_FRAME/.test(draw), "wrap runs on the existing content-change path (no timer, listener or frame work)");
	expect(/tgk == this\.hzsRetTK/.test(fnText(AS, "hzsDrawRet").body), "world tags still skip a redraw when the tag signature is unchanged");
	expect(/hzsMkK\[i\] !== key/.test(fnText(AS, "hzsDrawMarks").body), "POI slots still skip a redraw when the marker signature is unchanged");
}

function drawHost(names) {
	const h = host(T.concat(["hzsRight"], names));
	h.hzsOpacity = () => 0.8;
	h.hzsTitle = () => false;
	h.hzsCs = (s) => String(s).toUpperCase();
	h.hzsCard = function (g, w, h2) { g.ops.push(["card", w, h2]); };
	h.hzsBar = function (g, x, y, w, h2) { g.ops.push(["bar", x, y, w, h2]); };
	h.hzsRR = function (g, x, y, w, h2, r, col, a) { g.ops.push(["rr", x, y, w, h2, r, col, a]); };
	h.hzsIcon = function () {};
	h.hzsTile = function () {};
	h.hzsCheck = function () {};
	h.hzsSeg = function () {};
	h.hzsSection = function (p, x, cy, w, label, right) {
		this.hzsT(p, this.hzsCs(label), x, cy, 13, 0xFFFFFF, "sb", 0.14);
		if (right != null && String(right).length > 0) { this.hzsT(p, String(right), x + w, cy, 13, 0x96A6AE, "sb", 0.06, "r"); }
	};
	h.hzsBiomeWord = function () { return "ok"; };
	return h;
}
function tfs(p) { return p.kids.filter((k) => k.__tf); }
function cardH(p) { const c = p.graphics.ops.find((o) => o[0] === "card"); return c ? c[2] : 0; }

{
	const h = drawHost(["hzsDPlanet"]);
	const shortP = new Sprite();
	h.hzsTPBegin(shortP);
	const shortWh = h.hzsDPlanet(shortP, { name: "Akila", sys: "Cheyenne", pct: 42, cond: [], haz: null });
	h.hzsTPEnd();
	const longP = new Sprite();
	h.hzsTPBegin(longP);
	const longWh = h.hzsDPlanet(longP, { name: DE, sys: "Cheyenne", pct: 42, cond: [], haz: null });
	h.hzsTPEnd();
	const name = tfs(longP).find((t) => t._text === DE);
	const sys = tfs(longP).find((t) => t._text === "Cheyenne");
	const bar = longP.graphics.ops.find((o) => o[0] === "bar");
	const shortName = tfs(shortP).find((t) => t._text === "Akila");
	const shortSys = tfs(shortP).find((t) => t._text === "Cheyenne");
	const shortBar = shortP.graphics.ops.find((o) => o[0] === "bar");
	const nameSlack = (shortName.y + shortName.height) - shortSys.y;
	const barSlack = (shortSys.y + shortSys.height) - shortBar[2];
	expect(name && name.wordWrap === true && h.hzsTExtra(name, 22) > 0, "full planet name wraps and reports extra from the pooled field");
	expect(sys.y > shortSys.y && bar[2] > shortBar[2], "planet system line and survey bar shift down with wrap extra");
	expect(name.y + name.height <= sys.y + nameSlack + 1, "wrapped planet name does not paint over the system line");
	expect(sys.y + sys.height <= bar[2] + barSlack + 1, "wrapped system line does not paint over the survey bar");
	expect(longWh[1] > shortWh[1] && longWh[1] === cardH(longP), "full planet card grows with the wrapped name and the highlight box matches");
}

{
	const h = drawHost(["hzsDPlanetC"]);
	const p = new Sprite();
	h.hzsTPBegin(p);
	const wh = h.hzsDPlanetC(p, { name: DE, pct: 10, haz: null });
	h.hzsTPEnd();
	const name = tfs(p).find((t) => String(t._text).indexOf("...") >= 0);
	expect(wh[1] === 44 && cardH(p) === 44, "compact planet strip stays 44 px");
	expect(name && name.wordWrap !== true && name._text.indexOf("...") >= 0, "compact planet name is one line with an ellipsis");
}

{
	const h = drawHost(["hzsDSigC"]);
	const p = new Sprite();
	h.hzsTPBegin(p);
	const wh = h.hzsDSigC(p, { near: { n: DE, d: "12 m", hl: true } });
	h.hzsTPEnd();
	const name = tfs(p).find((t) => t._text === DE || String(t._text).indexOf("...") >= 0);
	expect(wh[1] === 44 && cardH(p) === 44, "compact signals strip stays 44 px");
	expect(name && name.wordWrap !== true && (name._text === DE || name._text.indexOf("...") >= 0) && lineCount(name) === 1, "compact signals name stays one line (ellipsis if it does not fit)");
}

{
	const h = drawHost(["hzsDBio"]);
	h.hzsBiomeWord = () => DE;
	const longP = new Sprite();
	h.hzsTPBegin(longP);
	const longWh = h.hzsDBio(longP, { rows: [["FAUNA", "fauna", 0, 3]], hasFl: true, hasFa: true, bfl: false, bfa: false, flc: 2, fac: 1, tot: 0, mx: 10, fl: 0, left: [], allFF: false, lt: false });
	h.hzsTPEnd();
	h.hzsBiomeWord = () => "none";
	const shortP = new Sprite();
	h.hzsTPBegin(shortP);
	const shortWh = h.hzsDBio(shortP, { rows: [["FAUNA", "fauna", 0, 3]], hasFl: true, hasFa: true, bfl: false, bfa: false, flc: 2, fac: 1, tot: 0, mx: 10, fl: 0, left: [], allFF: false, lt: false });
	h.hzsTPEnd();
	const biomes = tfs(longP).filter((t) => t._text === DE);
	expect(biomes.length === 2 && biomes[0].wordWrap === true && h.hzsTExtra(biomes[0], 13) > 0, "bioscan biome lines wrap on the pooled field");
	expect(biomes[0].y + biomes[0].height <= biomes[1].y + 1, "the second biome line shifts below the wrapped first");
	expect(longWh[1] > shortWh[1] && longWh[1] === cardH(longP), "bioscan card grows with wrapped biome lines and the box matches");
}

{
	const h = drawHost(["hzsResRows"]);
	const p = new Sprite();
	h.hzsTPBegin(p);
	const end = h.hzsResRows(p, 20, 0, 360, [{ r: 0, items: [["Fe", DE, 0]] }]);
	h.hzsTPEnd();
	const name = tfs(p).find((t) => t._text === DE || String(t._text).indexOf("...") >= 0 && t._text !== "COMMON");
	expect(end === 32, "resource rows still step 32 px");
	expect(name && name.wordWrap !== true && name._text.indexOf("...") >= 0 && lineCount(name) === 1, "resource chip name is one line with an ellipsis");
}

{
	const h = drawHost(["hzsDSig"]);
	const shortP = new Sprite();
	h.hzsTPBegin(shortP);
	const shortWh = h.hzsDSig(shortP, { rows: [{ n: "Cave", sub: "Fauna", d: "12 m", col: 0xFFFFFF, dc: 0xFFFFFF, ic: "hex", hl: true }], inr: 1 });
	h.hzsTPEnd();
	const shortBox = shortP.graphics.ops.find((o) => o[0] === "rr" && o[3] > 10);
	expect(shortWh[1] === cardH(shortP) && shortBox && shortBox[4] === 46, "a one-line signals row keeps the 46 px highlight box");

	madeSp = 0; madeTf = 0;
	const p = new Sprite();
	const sp0 = madeSp, tf0 = madeTf;
	h.hzsTPBegin(p);
	const longWh = h.hzsDSig(p, { rows: [{ n: DE, sub: "Fauna", d: "12 m", col: 0xFFFFFF, dc: 0xFFFFFF, ic: "hex", hl: true }], inr: 1 });
	h.hzsTPEnd();
	const name = tfs(p).find((t) => t._text === DE);
	const box = p.graphics.ops.find((o) => o[0] === "rr" && o[3] > 10);
	const rowH = longWh[1] - 56;
	expect(madeSp === sp0, "signals creates no extra Sprite per row (measure uses the pooled fields)");
	expect(madeTf - tf0 === 5, "signals creates 5 pooled fields for one row (section 2 + distance/name/sub), not a second measure pass");
	expect(name && name.wordWrap === true && h.hzsTExtra(name, 14) > 0, "full signals name wraps on the pooled field");
	expect(longWh[1] > shortWh[1] && longWh[1] === cardH(p), "signals card grows with the wrapped row");
	expect(box && box[4] === rowH - 2 && box[4] > 46, "the 46 px highlight box grows to the measured row height");
}

{
	const HOSTS = [["actionscript/imp/simp_monoclemenu/MonocleMenu.as", "false"], ["actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as", "true"]];
	for (const [f, lrg] of HOSTS) {
		const hostSrc = rd(f);
		const want = BLOCK.replace(/__HZS_LRG__/g, lrg);
		expect(hostSrc.indexOf(want.replace(/\n$/, "")) >= 0, path.basename(path.dirname(f)) + ": wrap lives in the spliced scanner block (HZS_LRG = " + lrg + ")");
	}
}

console.log("scanner wrap: " + passed + " ok" + (failed ? ", " + failed + " FAILED" : ", all passed"));
process.exit(failed ? 1 : 0);
