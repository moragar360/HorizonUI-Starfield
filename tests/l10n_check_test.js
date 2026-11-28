// Horizon localization checker: missing / duplicate / obsolete keys, and
// placeholder parity. Run from the repo root: node tests/l10n_check_test.js
// de.json, zh-cn.json, es.json, es-mx.json, fr.json, and pl.json are required. Other
// Steam stems (it, ja, pt-br) may be absent: that is English fallback, not a failure.
// Fixtures that must fail write under test_scratch, never the system temp folder.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const locDir = path.join(root, "Data", "SFSE", "Plugins", "HorizonUI", "Localization");
const langs = ["en", "de", "fr", "es", "es-mx", "it", "ja", "pl", "pt-br", "zh-cn"];
const PLACEHOLDER = /\{[A-Za-z0-9_]+\}/g;

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

function flatten(obj, prefix, out) {
	if (obj == null || typeof obj !== "object" || Array.isArray(obj)) {
		if (prefix) out[prefix] = obj;
		return;
	}
	for (const k of Object.keys(obj)) {
		if (k === "_meta" || k === "_comment") continue;
		const p = prefix ? prefix + "." + k : k;
		flatten(obj[k], p, out);
	}
}

function loadLang(dir, code) {
	const p = path.join(dir, code + ".json");
	if (!fs.existsSync(p)) return null;
	return JSON.parse(fs.readFileSync(p, "utf8"));
}

function uniqueKeys(flat) {
	const seen = Object.create(null);
	let dups = 0;
	for (const k of Object.keys(flat)) {
		if (seen[k]) dups++;
		seen[k] = true;
	}
	return dups;
}

function checkPair(enFlat, other, code) {
	const flat = {};
	flatten(other, "", flat);
	const enKeys = Object.keys(enFlat);
	const missing = enKeys.filter((k) => flat[k] == null || String(flat[k]).length === 0);
	const extra = Object.keys(flat).filter((k) => enFlat[k] == null);
	let phBad = 0;
	for (const k of enKeys) {
		if (flat[k] == null) continue;
		const a = (String(enFlat[k]).match(PLACEHOLDER) || []).slice().sort().join();
		const b = (String(flat[k]).match(PLACEHOLDER) || []).slice().sort().join();
		if (a !== b) phBad++;
	}
	return { missing, extra, phBad };
}

expect(fs.existsSync(path.join(root, "tools", "scan_l10n_strings.js")), "tools/scan_l10n_strings.js is committed");
expect(fs.existsSync(path.join(locDir, "en.json")), "shipped Localization/en.json is present");
expect(fs.existsSync(path.join(locDir, "zh-cn.json")), "shipped Localization/zh-cn.json is present");
expect(fs.existsSync(path.join(locDir, "de.json")), "shipped Localization/de.json is present");
expect(fs.existsSync(path.join(locDir, "es.json")), "shipped Localization/es.json is present");
expect(fs.existsSync(path.join(locDir, "es-mx.json")), "shipped Localization/es-mx.json is present");
expect(fs.existsSync(path.join(locDir, "fr.json")), "shipped Localization/fr.json is present");
expect(fs.existsSync(path.join(locDir, "pl.json")), "shipped Localization/pl.json is present");
expect(!fs.existsSync(path.join(locDir, "ko.json")), "Korean is not a shipped table");

const en = loadLang(locDir, "en");
expect(!!en, "English table parses");
if (!en) {
	console.error("\nno English table; remaining checks skipped");
	process.exit(1);
}
const enFlat = {};
flatten(en, "", enFlat);
const enKeys = Object.keys(enFlat);
expect(enKeys.length > 0, "English table has keys (" + enKeys.length + ")");
expect(uniqueKeys(enFlat) === 0, "no duplicate flattened keys in English");
expect(enFlat["hud.health"] === "HEALTH", "hud.health is HEALTH");
expect(enFlat["settings.tabs.cards"] === "CARDS", "settings.tabs.cards is CARDS");
expect(String(enFlat["settings.language.auto"] || "").indexOf("Auto") >= 0, "settings.language.auto names Auto");
expect(enFlat["settings.language.de"] === "Deutsch (German)", "German dropdown label is native plus English");
expect(enFlat["settings.language.es-mx"] && String(enFlat["settings.language.es-mx"]).indexOf("Latinoam") >= 0,
	"Latin American Spanish has its own stem");
expect(enFlat["settings.language.pt-br"] && String(enFlat["settings.language.pt-br"]).indexOf("Brasil") >= 0,
	"Portuguese Brazil uses pt-br");
expect(enFlat["settings.language.ko"] === undefined, "Korean is not in the English table");
expect(!JSON.stringify(en).includes("$HEALTH"), "Horizon-owned strings are not wrapped in $ tokens");

for (const code of langs) {
	if (code === "en") continue;
	const table = loadLang(locDir, code);
	const required = code === "de" || code === "zh-cn" || code === "es" || code === "es-mx" || code === "fr" || code === "pl";
	if (!required && !table) {
		expect(true, code + ": optional until a translator ships it (missing is English fallback)");
		continue;
	}
	if (required && !table) {
		expect(false, code + ": shipped overlay is required");
		continue;
	}
	const r = checkPair(enFlat, table, code);
	expect(r.missing.length === 0, code + ": no missing keys" + (r.missing.length ? " (" + r.missing.slice(0, 8).join(", ") + ")" : ""));
	expect(r.extra.length === 0, code + ": no obsolete keys" + (r.extra.length ? " (" + r.extra.slice(0, 8).join(", ") + ")" : ""));
	expect(r.phBad === 0, code + ": placeholders match English");
}

function exo2Can(s) {
	for (let i = 0; i < s.length;) {
		const cp = s.codePointAt(i);
		const ok = cp <= 0x024F
			|| (cp >= 0x0300 && cp <= 0x036F)
			|| (cp >= 0x1E00 && cp <= 0x1EFF)
			|| (cp >= 0x2000 && cp <= 0x206F)
			|| (cp >= 0x20A0 && cp <= 0x20CF);
		if (!ok) return false;
		i += cp > 0xFFFF ? 2 : 1;
	}
	return true;
}

const frPath = path.join(locDir, "fr.json");
const frBuf = fs.readFileSync(frPath);
expect(!(frBuf.length >= 3 && frBuf[0] === 0xEF && frBuf[1] === 0xBB && frBuf[2] === 0xBF),
	"fr.json is UTF-8 with no BOM");
let frJsonOk = false;
let frObj = null;
try {
	frObj = JSON.parse(frBuf.toString("utf8"));
	frJsonOk = true;
} catch (e) {
	frJsonOk = false;
}
expect(frJsonOk, "fr.json is valid UTF-8 JSON");
const frFlat = {};
if (frObj) flatten(frObj, "", frFlat);
let frGlyphBad = 0;
for (const k of Object.keys(frFlat)) {
	if (!exo2Can(String(frFlat[k]))) frGlyphBad++;
}
expect(frGlyphBad === 0, "fr.json Exo 2 glyph check (Latin / French diacritics)");
expect(frObj && frObj._meta && frObj._meta.language === "fr" && frObj._meta.languageName === "Français",
	"fr.json _meta language is Français");
expect(frFlat["settings.language.fr"] === "FRANÇAIS",
	"Language dropdown shows Français natively (FRANÇAIS)");
expect(frFlat["hud.health"] === "SANTÉ", "fr.json hud.health is SANTÉ");
expect(exo2Can("Français") && exo2Can("FRANÇAIS") && exo2Can("àâäéèêëîïôùûüÿçœæÀÂÄÉÈÊËÎÏÔÙÛÜŸÇŒÆ"),
	"Exo 2 can draw Français and French diacritics");

const plPath = path.join(locDir, "pl.json");
const plBuf = fs.readFileSync(plPath);
expect(!(plBuf.length >= 3 && plBuf[0] === 0xEF && plBuf[1] === 0xBB && plBuf[2] === 0xBF),
	"pl.json is UTF-8 with no BOM");
let plJsonOk = false;
let plObj = null;
try {
	plObj = JSON.parse(plBuf.toString("utf8"));
	plJsonOk = true;
} catch (e) {
	plJsonOk = false;
}
expect(plJsonOk, "pl.json is valid UTF-8 JSON");
const plFlat = {};
if (plObj) flatten(plObj, "", plFlat);
let plGlyphBad = 0;
for (const k of Object.keys(plFlat)) {
	if (!exo2Can(String(plFlat[k]))) plGlyphBad++;
}
expect(plGlyphBad === 0, "pl.json Exo 2 glyph check (Latin / Polish diacritics)");
expect(plObj && plObj._meta && plObj._meta.language === "pl" && plObj._meta.languageName === "Polski",
	"pl.json _meta language is Polski");
expect(plFlat["settings.language.pl"] === "POLSKI",
	"Language dropdown shows Polski natively (POLSKI)");
expect(plFlat["hud.health"] === "ZDROWIE", "pl.json hud.health is ZDROWIE");
expect(exo2Can("Polski") && exo2Can("POLSKI") && exo2Can("ąćęłńóśźżĄĆĘŁŃÓŚŹŻ"),
	"Exo 2 can draw Polski and Polish diacritics");

const scratch = path.join(root, "test_scratch", "l10n_check_" + process.pid);
fs.mkdirSync(scratch, { recursive: true });
fs.writeFileSync(path.join(scratch, "en.json"), JSON.stringify({
	hud: { health: "HEALTH", oxygen: "OXYGEN {name}" },
	settings: { tabs: { cards: "CARDS" } }
}), "utf8");
fs.writeFileSync(path.join(scratch, "de.json"), JSON.stringify({
	hud: { health: "GESUNDHEIT", extra: "ALT" },
	settings: { tabs: { cards: "KARTEN" } }
}), "utf8");
const fxEn = {};
flatten(loadLang(scratch, "en"), "", fxEn);
const fxDe = checkPair(fxEn, loadLang(scratch, "de"), "de");
expect(fxDe.missing.indexOf("hud.oxygen") >= 0, "checker flags a missing overlay key");
expect(fxDe.extra.indexOf("hud.extra") >= 0, "checker flags an obsolete overlay key");
fs.writeFileSync(path.join(scratch, "fr.json"), JSON.stringify({
	hud: { health: "SANTE", oxygen: "OXYGENE" },
	settings: { tabs: { cards: "CARTES" } }
}), "utf8");
const fxFr = checkPair(fxEn, loadLang(scratch, "fr"), "fr");
expect(fxFr.phBad === 1, "checker flags a placeholder mismatch");

const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8");
expect(as.indexOf("function hzSetL10n") >= 0 && as.indexOf("function hzL(") >= 0, "HUD receiver is present");
{
	const i = as.indexOf("function hzVitTick");
	if (i < 0) {
		expect(true, "no vitals tick helper to pin");
	} else {
		const brace = as.indexOf("{", i);
		let d = 0;
		let body = "";
		for (let p = brace; p < as.length && p < brace + 8000; p++) {
			if (as[p] === "{") d++;
			else if (as[p] === "}") { d--; if (d === 0) { body = as.slice(brace, p + 1); break; } }
		}
		expect(body.indexOf("this.hzL(") < 0 && body.indexOf("hzLt(") < 0, "vitals tick does not look up translations");
	}
}
expect(as.indexOf("function hzLt(") >= 0 && as.indexOf("function hzL10nApplyHud") >= 0, "P1 lookup helpers are on the HUD");
expect(!/HUSD|SCHROPE|rschr/i.test(as.slice(as.indexOf("function hzSetL10n"), as.indexOf("function hzSetL10n") + 1200)), "l10n receiver has no box paths or usernames");

if (failed) {
	console.error("\n" + failed + " failed, " + passed + " passed");
	process.exit(1);
}
console.log("\n" + passed + " passed");
