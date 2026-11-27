// Language dropdown: Exo 2 only, no tofu, no $MAIN_Font on the list.
// Native name when Exo 2 can draw it; English name (parenthetical) otherwise.
// Ten Steam stems once; alias files do not add a second Latinoamérica row.
// Run: node tests/l10n_dropdown_test.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.join(__dirname, "..");
const insert = fs.readFileSync(path.join(root, "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const draw = fs.readFileSync(path.join(root, "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const en = JSON.parse(fs.readFileSync(path.join(root, "Data", "SFSE", "Plugins", "HorizonUI", "Localization", "en.json"), "utf8"));

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
		const n = p.split(":")[0].trim();
		const v = p.split("=")[1].trim();
		return "if(" + n + " === undefined) " + n + " = " + v + ";";
	}).join("\n");
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (var $1 of ")
		.replace(/var (\w+):[\w*]+/g, "var $1")
		.replace(/([\w.\]\)]+) as (?:Array|MovieClip|Object|DisplayObject|DisplayObjectContainer|TextField|Sprite)\b/g, "$1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)");
	return new Function(...params, defs + "\n" + body);
}

const host = {
	hzL10n: null,
	hzL10nFiles: ["en", "de", "fr", "it", "es", "es-mx", "ja", "pl", "pt-br", "zh-cn"],
	hzL(key, fb) {
		if (this.hzL10n && this.hzL10n[key] != null && String(this.hzL10n[key]).length > 0) return String(this.hzL10n[key]);
		const parts = String(key).split(".");
		let cur = en;
		for (const p of parts) {
			if (cur == null || typeof cur !== "object") { cur = undefined; break; }
			cur = cur[p];
		}
		if (typeof cur === "string" && cur.length > 0) return cur;
		return fb != null ? fb : key;
	}
};
host.hzExo2Can = toJs(insert, "hzExo2Can").bind(host);
host.hz51Exo2Text = toJs(insert, "hz51Exo2Text").bind(host);
host.hz51Exo2Arr = toJs(insert, "hz51Exo2Arr").bind(host);
host.hz51LangCode = toJs(insert, "hz51LangCode").bind(host);
host.hz51LangName = toJs(insert, "hz51LangName").bind(host);
host.hz51LangOpts = toJs(insert, "hz51LangOpts").bind(host);

expect(host.hzExo2Can("Deutsch (German)") && host.hzExo2Can("Español (Spanish)") && host.hzExo2Can("Français (French)"),
	"Exo 2 can draw German / Spanish / French native names");
expect(host.hzExo2Can("Polski") && host.hzExo2Can("Português (Brasil)") && host.hzExo2Can("Italiano (Italian)"),
	"Exo 2 can draw Polish / Portuguese / Italian");
expect(!host.hzExo2Can("日本語 (Japanese)") && !host.hzExo2Can("简体中文 (Simplified Chinese)"),
	"Exo 2 cannot draw Japanese or Simplified Chinese native names");
expect(!host.hzExo2Can("한국어 (Korean)") && !host.hzExo2Can("ไทย (Thai)") && !host.hzExo2Can("Русский (Russian)"),
	"Exo 2 cannot draw Hangul / Thai / Cyrillic (generic, not a ja/zh-cn flag)");

expect(host.hz51Exo2Text("日本語 (Japanese)", "Japanese") === "Japanese",
	"CJK native + English in parens becomes the English name");
expect(host.hz51Exo2Text("简体中文 (Simplified Chinese)", "X") === "Simplified Chinese",
	"Chinese native + English in parens becomes the English name");
expect(host.hz51Exo2Text("한국어 (Korean)", "Korean") === "Korean",
	"a future Hangul stem uses the parenthetical English name");
expect(host.hz51Exo2Text("ไทย (Thai)", "Thai") === "Thai",
	"a future Thai stem uses the parenthetical English name");
expect(host.hz51Exo2Text("Deutsch (German)", "German") === "Deutsch (German)",
	"Latin native names stay native + English");
expect(host.hz51Exo2Text("简体中文", "Simplified Chinese") === "Simplified Chinese",
	"CJK with no parenthetical uses the English fallback");

const exoFn = fnText(insert, "hzExo2Can").body;
expect(!/\bja\b/.test(exoFn) && !/zh-cn/.test(exoFn) && !/japanese/i.test(exoFn),
	"hzExo2Can is a glyph/script check, not a ja/zh-cn stem list");
expect(!/\$MAIN_Font/.test(fnText(insert, "hz51LangName").body)
	&& !/\$MAIN_Font/.test(fnText(insert, "hz51Exo2Text").body)
	&& !/\$MAIN_Font/.test(fnText(draw, "hz51DrawDrop").body),
	"Language dropdown path never selects $MAIN_Font");
expect(/cjk \? "\$MAIN_Font"/.test(fnText(as, "hzWT").body) || /cjk \? "\$MAIN_Font"/.test(fnText(as, "hzApplyFmt19").body),
	"translated HUD text still uses $MAIN_Font when the string is CJK");

expect(host.hz51LangName("ja") === "Japanese" && host.hz51LangName("jp") === "Japanese",
	"Japanese dropdown entry is the English name in Exo 2");
expect(host.hz51LangName("zh-cn") === "Simplified Chinese" && host.hz51LangName("zhhans") === "Simplified Chinese",
	"Simplified Chinese dropdown entry is the English name in Exo 2");
expect(host.hz51LangName("de") === "Deutsch (German)" && host.hz51LangName("es") === "Español (Spanish)",
	"German and Spain Spanish keep native + English");
expect(host.hz51LangName("es-mx") === "Español (Latinoamérica)" && host.hz51LangName("es-419") === "Español (Latinoamérica)",
	"Latin American Spanish is the short native label");
expect(host.hz51LangName("pt-br") === "Português (Brasil)",
	"Brazilian Portuguese is the short native label");
expect(!String(host.hz51LangName("es-mx")).includes("...") && host.hz51LangName("es-mx").length <= 28,
	"Latinoamérica label is short enough to fit");
expect(!String(host.hz51LangName("pt-br")).includes("...") && host.hz51LangName("pt-br").length <= 24,
	"Brasil label is short enough to fit");

host.hzL10n = {
	"settings.language.ja": "日本語 (Japanese)",
	"settings.language.zh-cn": "简体中文 (Simplified Chinese)",
	"settings.language.de": "Deutsch (German)"
};
expect(host.hz51LangName("ja") === "Japanese" && host.hz51LangName("zh-cn") === "Simplified Chinese",
	"when ja/zh-cn overlay supplies native CJK names the dropdown still shows English in Exo 2");
expect(host.hz51LangName("de") === "Deutsch (German)",
	"an overlay that stays in Exo 2 keeps the native name");
host.hzL10n = null;

const steam = ["en", "de", "fr", "it", "es", "es-mx", "ja", "pl", "pt-br", "zh-cn"];
expect(host.hz51LangCode("es-419") === "es-mx" && host.hz51LangCode("esmx") === "es-mx" && host.hz51LangCode("latam") === "es-mx",
	"alias stems MapCode to es-mx");
host.hzL10nFiles = steam.concat(["es-419", "esmx", "latam"]);
const opts = host.hz51LangOpts();
expect(opts.vals[0] === "auto" && opts.vals.length === 11,
	"Auto plus the ten Steam languages; alias files do not add a row");
const mxHits = opts.vals.filter((v) => v === "es-mx").length;
const nameHits = opts.names.filter((n) => String(n).indexOf("Latinoam") >= 0).length;
expect(mxHits === 1 && nameHits === 1, "Español (Latinoamérica) appears once");
const uniq = new Set(opts.names);
expect(uniq.size === opts.names.length, "every dropdown label is unique");
expect(opts.names.indexOf("Japanese") >= 0 && opts.names.indexOf("Simplified Chinese") >= 0,
	"list items for ja / zh-cn are the English names");

const locOne = fnText(insert, "hz51LocOne").body;
expect(/k\) == "Language"/.test(locOne) && /hz51Exo2Arr/.test(locOne),
	"Language row names are Exo-2 filtered and not re-slugged into CJK");
expect(/var dlab:String = this\.hz51Exo2Text\(String\(opts\[oi\]\)\)/.test(draw),
	"open-list option text goes through hz51Exo2Text");
expect(/txt = this\.hz51Exo2Text\(txt\)/.test(draw) && /var maxTw:Number = this\.hzTW\(ct\)/.test(draw),
	"closed chip and list width follow the longest Exo-2 label, not only the selected English row");

const langs = en.settings.language;
expect(langs.ja === "Japanese" && langs["zh-cn"] === "Simplified Chinese",
	"en.json ships English-only ja / zh-cn dropdown labels");
expect(langs["es-mx"] === "Español (Latinoamérica)" && langs["pt-br"] === "Português (Brasil)",
	"en.json ships the shortened Latin American and Brazil labels");
expect(!String(langs.ja).includes("日本語") && !String(langs["zh-cn"]).includes("简体"),
	"en.json Language dropdown labels have no CJK");

if (failed) { console.error("\n" + failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
