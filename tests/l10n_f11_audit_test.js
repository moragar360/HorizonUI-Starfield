// F11 localization audit: every Setting Details / row line / module body
// is looked up by setting key (settings.details.<k> / settings.line.<k>),
// z-row labels reserve the chip column, row help wraps, and draw chrome uses hzLt.
// Run: node tests/l10n_f11_audit_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const insert = fs.readFileSync(path.join(root, "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const draw = fs.readFileSync(path.join(root, "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");
const locDir = path.join(root, "Data", "SFSE", "Plugins", "HorizonUI", "Localization");

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
function flatten(obj, prefix, out) {
	if (obj == null || typeof obj !== "object" || Array.isArray(obj)) {
		if (prefix) out[prefix] = obj;
		return;
	}
	for (const k of Object.keys(obj)) {
		if (k === "_meta" || k === "_comment") continue;
		flatten(obj[k], prefix ? prefix + "." + k : k, out);
	}
}
function load(code) {
	return JSON.parse(fs.readFileSync(path.join(locDir, code + ".json"), "utf8"));
}

const helpOf = fnText(insert, "hz51HelpOf").body;
expect(/settings\.details\./.test(helpOf) && /hz51HelpKey/.test(helpOf),
	"Setting Details look up settings.details.<k> before slugging English");
expect(/modban/.test(fnText(insert, "hz51HelpKey").body),
	"module banners share settings.details.modban");

const line = fnText(insert, "hz51Line").body;
expect(/settings\.line\./.test(line), "row help lines look up settings.line.<k> first");

const locOne = fnText(insert, "hz51LocOne").body;
expect(!/r\.note = this\.hzLt/.test(locOne) && !/r\.inote = this\.hzLt/.test(locOne),
	"catalog finish does not re-slug note/inote (that expanded CompactScale into the full paragraph)");

const list = fnText(draw, "hz51DrawList").body;
expect(/HZ51_Z_RESERVE/.test(list) && /r\.t == "z"/.test(list),
	"z-rows (COMPACT STRIPS: SIZE and other chip+slider sizes) reserve the chip/slider column");
expect(/wordWrap = true/.test(list) && /multiline = true/.test(list) && !/hzFitText\(ht2/.test(list),
	"row help wraps to fit instead of chopping with an ellipsis");

const z = fnText(as, "hz34ZDraw").body;
expect(/hzLt\(glob \? "GLOBAL" : "CUSTOM"\)/.test(z), "GLOBAL/CUSTOM chip text goes through hzLt");

const drawSrc = draw;
expect(/hzLt\("MODULE"\)/.test(drawSrc) && /hzLt\("ENABLE"\)/.test(drawSrc) && /hzLt\("UNAVAILABLE"\)/.test(drawSrc),
	"module chrome MODULE / ENABLE / UNAVAILABLE is looked up");
expect(/hzLt\("LIVE PREVIEW"\)/.test(drawSrc) && /hzLt\("SETTING DETAILS"\)/.test(drawSrc),
	"LIVE PREVIEW and SETTING DETAILS headers are looked up");
const head = fnText(draw, "hz51DrawHead").body;
expect(/hzLt\("HORIZON UI"\)/.test(head) && /hzLt\("SETTINGS"\)/.test(head),
	"F11 title cluster looks up HORIZON UI and SETTINGS");
expect(/hzTW\(t1\)/.test(head) && /hzTW\(t2\)/.test(head) && !/16 \+ 128/.test(head) && !/pillX = 250/.test(head),
	"F11 header places SETTINGS and the version chip from measured text, not a 90px / x=250 clip");
expect(/hz51HelpOf\(String\(r\.k\)/.test(fnText(draw, "hz51DrawRight").body),
	"Setting Details body is hz51HelpOf (table lookup), not a raw English literal");

function helpCases(src) {
	const keys = [];
	const start = src.indexOf("private function hz51Help(");
	const more = src.indexOf("private function hz51HelpMore(");
	src.slice(start, more).replace(/case "([^"]+)": return "/g, (_, k) => { keys.push(k); return ""; });
	src.slice(more, src.indexOf("private function hz51Finish("))
		.replace(/if\(k == "([^"]+)"\) \{ return "/g, (_, k) => { keys.push(k); return ""; });
	keys.push("modban");
	return keys;
}
const keys = helpCases(insert);
expect(keys.indexOf("ScanHighlightArea") >= 0 && keys.indexOf("ScanReach") >= 0 && keys.indexOf("ScanCompactAll") >= 0,
	"Highlight Area, Scan Reach, and Compact-all have help cases");

const en = {}; flatten(load("en"), "", en);
const de = {}; flatten(load("de"), "", de);
const zh = {}; flatten(load("zh-cn"), "", zh);
const es = {}; flatten(load("es"), "", es);
const esmx = {}; flatten(load("es-mx"), "", esmx);
const pl = {}; flatten(load("pl"), "", pl);
function detailsOf(table, k) {
	return table.settings && table.settings.details ? table.settings.details[k] : undefined;
}
const enJ = load("en"), deJ = load("de"), zhJ = load("zh-cn"), esJ = load("es"), mxJ = load("es-mx"), plJ = load("pl");
let missingEn = 0, missingDe = 0, missingZh = 0, missingEs = 0, missingMx = 0, missingPl = 0;
for (const k of keys) {
	if (!detailsOf(enJ, k)) missingEn++;
	if (!detailsOf(deJ, k)) missingDe++;
	if (!detailsOf(zhJ, k)) missingZh++;
	if (!detailsOf(esJ, k)) missingEs++;
	if (!detailsOf(mxJ, k)) missingMx++;
	if (!detailsOf(plJ, k)) missingPl++;
}
expect(missingEn === 0, "en.json has settings.details for every hz51Help case (" + keys.length + ")");
expect(missingDe === 0, "de.json has settings.details for every hz51Help case");
expect(missingZh === 0, "zh-cn.json has settings.details for every hz51Help case");
expect(missingEs === 0, "es.json has settings.details for every hz51Help case");
expect(missingMx === 0, "es-mx.json has settings.details for every hz51Help case");
expect(missingPl === 0, "pl.json has settings.details for every hz51Help case");

expect(en["settings.line.ScanHighlightArea"] && en["settings.line.ScanHighlightArea"].indexOf("How far from the screen center") === 0,
	"English Highlight Area row line is the first sentence");
expect(de["settings.line.ScanHighlightArea"] && de["settings.line.ScanHighlightArea"].indexOf("How far") < 0,
	"German Highlight Area row line is not English");
expect(de["settings.line.ScanReach"] && de["settings.line.ScanReach"].indexOf("Changes how far") < 0,
	"German Scan Reach row line is not English");
expect(de["settings.line.ScanCompactAll"] && /KOMPAKT/.test(de["settings.line.ScanCompactAll"]),
	"German Compact-all subtitle is translated");
expect(de["settings.details.modban"] && de["settings.details.modban"].indexOf("This add-on") < 0,
	"German module details are translated");
expect(zh["settings.details.ScanHighlightArea"] && zh["settings.details.ScanHighlightArea"].indexOf("How far") < 0,
	"zh-cn Highlight Area details are translated");
expect(zh["settings.details.modban"] && zh["settings.details.modban"].indexOf("This add-on") < 0,
	"zh-cn module details are translated");
expect(es["settings.line.ScanHighlightArea"] && es["settings.line.ScanHighlightArea"].indexOf("How far") < 0,
	"Spain Spanish Highlight Area row line is not English");
expect(esmx["settings.line.ScanHighlightArea"] && esmx["settings.line.ScanHighlightArea"].indexOf("How far") < 0,
	"Latin American Spanish Highlight Area row line is not English");
expect(es["settings.details.modban"] && es["settings.details.modban"].indexOf("This add-on") < 0,
	"Spain Spanish module details are translated");
expect(esmx["hud.hud_label.press"] === "PRESIONA" && es["hud.hud_label.press"] === "PULSA",
	"es-mx keeps Latin American wording over Spain");
expect(pl["settings.line.ScanHighlightArea"] && pl["settings.line.ScanHighlightArea"].indexOf("How far") < 0,
	"Polish Highlight Area row line is not English");
expect(pl["settings.line.ScanCompactAll"] && /KOMPAKT/.test(pl["settings.line.ScanCompactAll"]),
	"Polish Compact-all subtitle is translated");
expect(pl["settings.details.modban"] && pl["settings.details.modban"].indexOf("This add-on") < 0,
	"Polish module details are translated");
expect(pl["hud.hud_label.press"] === "NACIŚNIJ", "Polish PRESS is NACIŚNIJ");

const f11Draw = (insert + "\n" + draw).replace(/private function hz51Pv[A-Za-z]+\([\s\S]*?(?=\n      private function )/g, "");
const rawHelp = f11Draw.match(/hz51T\(b,"[A-Za-z][^"]{12,}"/g) || [];
const allowed = rawHelp.filter((s) => !/hzLt\(/.test(s) && /[a-z]/.test(s));
expect(allowed.length === 0,
	"F11 chrome does not print a long English sentence without hzLt (" + (allowed[0] || "none") + ")");

function slug(s) {
	let o = "", prev = false;
	for (let i = 0; i < s.length && o.length < 48; i++) {
		const code = s.charCodeAt(i);
		const ok = (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
		if (ok) { o += s.charAt(i).toLowerCase(); prev = false; }
		else if (o.length && !prev) { o += "_"; prev = true; }
	}
	if (o.endsWith("_")) o = o.slice(0, -1);
	return o;
}
function lookup(table, en) {
	const sl = slug(en);
	const pfx = ["settings.ui.", "settings.chrome.", "settings.language.", "settings.tabs.",
		"hud.hud_label.", "hud.option.", "hud.help.", "hud."];
	for (const p of pfx) {
		if (table[p + sl]) return table[p + sl];
	}
	return table["hud.help." + sl] || "";
}
const sideStrs = [];
fnText(insert, "hz51Side").body.replace(/"(?:g|s|l)":"([^"]+)"/g, (_, v) => { sideStrs.push(v); return ""; });
let sideMissEn = 0, sideMissDe = 0;
const sideEnHit = [];
const sideDeHit = [];
for (const s of sideStrs) {
	if (!lookup(en, s)) { sideMissEn++; sideEnHit.push(s); }
	const dv = lookup(de, s);
	if (!dv) { sideMissDe++; sideDeHit.push(s); }
	else if (dv === s && /[a-z\u00b7]/.test(s)) { sideMissDe++; sideDeHit.push(s); }
}
expect(sideMissEn === 0, "en.json has a slug for every F11 sidebar g/s/l (" + (sideEnHit[0] || "ok") + ")");
expect(sideMissDe === 0, "de.json translates every F11 sidebar subtitle and mixed-case header (" + (sideDeHit[0] || "ok") + ")");
expect(lookup(de, "OVERRIDE") && lookup(de, "OVERRIDE") !== "OVERRIDE", "OVERRIDE section header is translated");
expect(en["settings.details._l10nGame"] && de["settings.details._l10nGame"]
	&& de["settings.details._l10nGame"].indexOf("The interface language") < 0,
	"German GAME LANGUAGE details are translated");
expect(en["settings.line.Language"] && de["settings.line.Language"]
	&& de["settings.line.Language"].indexOf("Language for Horizon") < 0,
	"German Horizon Language row help is translated");
expect(/hzLt\(String\(it\.s\)\)/.test(draw) && /hzLt\(String\(grp\.g\)\)/.test(draw),
	"sidebar subtitles and group headers go through hzLt");
expect(de["hud.hud_label.settings"] && de["hud.hud_label.settings"].indexOf("EINSTELL") === 0,
	"German SETTINGS is EINSTELLUNGEN (the string that used to clip before the version chip)");
expect(pl["hud.hud_label.settings"] && pl["hud.hud_label.settings"].length > 8,
	"Polish SETTINGS is a long label the header reflow must fit");
expect(lookup(de, "ARRANGE SCANNER") && lookup(de, "ARRANGE SCANNER") !== "ARRANGE SCANNER",
	"German ARRANGE SCANNER is translated");
expect(lookup(de, "COMPACT MODE (STRIPS)") && lookup(de, "COMPACT MODE (STRIPS)") !== "COMPACT MODE (STRIPS)",
	"German COMPACT MODE (STRIPS) is translated");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log(passed + " passed");
