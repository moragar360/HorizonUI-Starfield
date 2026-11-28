// Scanner for Horizon UI player-facing strings. Run: node tools/scan_l10n_strings.js
// Writes docs/localization/STRING_INVENTORY.csv. The checker is tests/l10n_check_test.js.
// Writes docs/localization/STRING_INVENTORY.csv (utf8, no BOM).
// Skips duplicate ActionScript copies (imp/, HUDMenu_1*.as, hz51_insert.as
// which is already spliced into horizon_block.as).
// Author: Moragar. Last modified: 2026-11-27.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const outDir = path.join(root, "docs", "localization");
const outCsv = path.join(outDir, "STRING_INVENTORY.csv");

const CANON_AS = [
	"actionscript/horizon_block.as",
	"actionscript/scanner/hzs_block.as",
	"actionscript/comms/hzc_block.as",
	"actionscript/comms/hzd_block.as",
	"actionscript/favorites/hzq_main.as",
	"actionscript/scope/hzp_main.as",
];

const SKIP_AS_DIR = /(^|[\\/])(imp|himp1|himp1\.07)([\\/]|$)/i;
const SKIP_AS_FILE = /HUDMenu_1|hz51_insert\.as$/i;

function csvEscape(s) {
	s = String(s == null ? "" : s).replace(/\r\n/g, "\n").replace(/\r/g, "\n");
	if (/[",\n]/.test(s)) return '"' + s.replace(/"/g, '""') + '"';
	return s;
}

function slug(s, max) {
	let t = String(s)
		.replace(/\$/g, "")
		.replace(/[^A-Za-z0-9]+/g, "_")
		.replace(/^_+|_+$/g, "")
		.toLowerCase();
	if (!t) t = "str";
	if (t.length > (max || 48)) t = t.slice(0, max || 48).replace(/_+$/, "");
	return t;
}

function moduleOf(rel) {
	rel = rel.replace(/\\/g, "/");
	if (rel.indexOf("horizon_block") >= 0) return "hud";
	if (rel.indexOf("scanner") >= 0 || rel.indexOf("hzs_") >= 0) return "scanner";
	if (rel.indexOf("hzc_") >= 0) return "comms";
	if (rel.indexOf("hzd_") >= 0) return "dialogue";
	if (rel.indexOf("favorites") >= 0 || rel.indexOf("hzq_") >= 0) return "quickmenu";
	if (rel.indexOf("scope") >= 0 || rel.indexOf("hzp_") >= 0) return "scope";
	if (rel.indexOf("fomod") >= 0) return "fomod";
	if (rel.indexOf(".ini") >= 0) return "ini";
	if (rel.indexOf("src/") === 0 || rel.indexOf("src\\") === 0) return "dll";
	return "other";
}

function keyFor(mod, kind, text, extra) {
	const prefix = {
		hud: "hud",
		scanner: "scan",
		comms: "comms",
		dialogue: "dlg",
		quickmenu: "qm",
		scope: "scope",
		fomod: "fomod",
		ini: "ini",
		dll: "dll",
		other: "ui",
	}[mod] || "ui";
	if (kind === "native_token") return "KEEP_NATIVE:" + text;
	if (kind === "font_name") return "KEEP_FONT:" + text;
	if (extra && extra.key) return prefix + "." + extra.key;
	return prefix + "." + kind + "." + slug(text);
}

function looksCodey(s) {
	if (!s) return true;
	if (s.length <= 1) return true;
	if (/^[_$A-Za-z][_$A-Za-z0-9]*$/.test(s) && s.length <= 3) return true;
	if (/^(true|false|null|undefined|NaN|this|function|return|void|int|uint|Number|String|Boolean|Array|Object|Sprite|TextField|MovieClip)$/.test(s)) return true;
	if (/^[0-9.#xX+\-*/%]+$/.test(s)) return true;
	if (/^(hz|HZ|g_|k)[A-Za-z0-9_]+$/.test(s)) return true;
	if (/^[a-z]+[A-Z][A-Za-z0-9]*$/.test(s) && s.length < 28 && !/ /.test(s)) return true; // camelCase id
	if (/^[A-Za-z]+_[A-Za-z0-9_]+$/.test(s) && s === s.replace(/[a-z]/g, "") ? false : /_/.test(s) && !/ /.test(s) && s.length < 40 && /^[A-Za-z]/.test(s) && /[a-z]/.test(s)) {
		// ShowJetpack-style INI keys: skip unless they have spaces
		if (!/ /.test(s) && /^[A-Z][a-z]+[A-Z]/.test(s)) return true;
	}
	if (/^#[0-9A-Fa-f]{3,8}$/.test(s)) return true;
	if (/^\.[a-zA-Z]/.test(s)) return true;
	if (/\.(as|ini|swf|gfx|txt|json|xml|dll)$/i.test(s)) return true;
	if (/\\/.test(s) && s.indexOf(" ") < 0) return true;
	if (/^(id|k|t|l|h|s|g|btn|opts|note|inote|sub|dis|chip|pal|names|hex|mn|mx|st|pct|n13|swk|row|tab)$/.test(s)) return true;
	return false;
}

function isNativeToken(s) {
	return /^\$\$?[A-Za-z][A-Za-z0-9_ ]*$/.test(s) || /^\$[A-Za-z]/.test(s);
}

function isFontName(s) {
	return /^\$?(Horizon_Font|MAIN_Font|NB_|Controller_Buttons|Horizon_NoSuchFace)/.test(s);
}

function isPlayerFacing(s) {
	if (!s || looksCodey(s)) return false;
	if (isFontName(s)) return true;
	if (isNativeToken(s)) return true;
	if (/[a-zA-Z]/.test(s) && / /.test(s) && s.length >= 4) return true;
	if (/^[A-Z0-9][A-Z0-9 /+\-&':.]{2,}$/.test(s) && /[A-Z]{2,}/.test(s)) return true; // HEALTH, CARDS, 12 H
	if (/^[A-Z][a-z].*[.!?]$/.test(s) && s.length >= 12) return true;
	if (/^(OK|ON|OFF|YES|NO|SAVE|LOAD|APPLY|CANCEL|RESET|ARRANGE|OPEN|SHOW|HIDE|NEXT|BACK|EXIT|EMPTY|SLOT)$/.test(s)) return true;
	return false;
}

const rows = [];
const seen = new Set();

function add(file, line, text, context, kind, extra) {
	if (text == null) return;
	text = String(text).replace(/\s+/g, " ").trim();
	if (!text) return;
	if (text.length > 400) text = text.slice(0, 397) + "...";
	const mod = moduleOf(file);
	const key = keyFor(mod, kind, text, extra);
	const sig = file + "|" + line + "|" + text;
	if (seen.has(sig)) return;
	seen.add(sig);
	rows.push({
		file: file.replace(/\\/g, "/"),
		line: String(line),
		string: text,
		context: context || kind,
		suggested_key: key,
		module: mod,
		kind: kind,
	});
}

function walkAs(rel) {
	const abs = path.join(root, rel);
	if (!fs.existsSync(abs)) return;
	const src = fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n");
	const lines = src.split("\n");
	for (let i = 0; i < lines.length; i++) {
		const ln = i + 1;
		const line = lines[i];
		const trimmed = line.trim();
		if (trimmed.indexOf("//") === 0) continue;

		// Catalog labels / section headers / sidebar copy / option arrays.
		const fieldRe = /\b(l|h|g|s|btn|note|inote)\s*:\s*"((?:\\.|[^"\\])*)"/g;
		let m;
		while ((m = fieldRe.exec(line))) {
			const fld = m[1];
			const val = m[2].replace(/\\n/g, "\n").replace(/\\"/g, '"');
			if (!isPlayerFacing(val) && fld !== "l" && fld !== "btn") continue;
			if (looksCodey(val) && fld !== "l") continue;
			const kind = fld === "l" ? "catalog_label" : fld === "h" || fld === "g" ? "section_header" : fld === "btn" ? "button" : fld === "s" ? "sidebar_blurb" : "help";
			const keyHint = fld === "l" ? (line.match(/\bk\s*:\s*"([^"]+)"/) || [])[1] : null;
			add(rel, ln, val, "AS " + fld + " field", kind, keyHint ? { key: "set." + keyHint } : null);
		}

		const opts = line.match(/\bopts\s*:\s*\[([^\]]+)\]/);
		if (opts) {
			const optRe = /"((?:\\.|[^"\\])*)"/g;
			let om;
			while ((om = optRe.exec(opts[1]))) {
				const val = om[1];
				if (isPlayerFacing(val) || /^[A-Z0-9][A-Z0-9 +\-/]{1,}$/.test(val)) {
					add(rel, ln, val, "dropdown / enum option", "option");
				}
			}
		}

		// return "help..." in hz51Help / hz51Line / similar.
		const ret = line.match(/\breturn\s+"((?:\\.|[^"\\])*)"\s*;/);
		if (ret) {
			const val = ret[1].replace(/\\n/g, " ").replace(/\\"/g, '"');
			if (val.length >= 8 && /[a-zA-Z]/.test(val) && !looksCodey(val)) {
				add(rel, ln, val, "return string (help or label)", "help");
			}
		}

		// Array literals of display names.
		const arr = line.match(/HZ_[A-Z0-9_]+(?:NAMES|TABS|CARD)\s*(?::Array)?\s*=\s*\[([^\]]+)\]/);
		if (arr) {
			const optRe = /"((?:\\.|[^"\\])*)"/g;
			let om;
			while ((om = optRe.exec(arr[1]))) {
				add(rel, ln, om[1], "name table " + (line.match(/HZ_[A-Z0-9_]+/) || ["table"])[0], "option");
			}
		}

		// Quoted strings assigned or passed to text helpers.
		if (/\.(text|htmlText)\s*=/.test(line) || /\bhz(T|51T|qSet|qUC|cSet|sT|HdrCase|UC)\s*\(/.test(line) || /hzqUC\s*\(/.test(line)) {
			const qRe = /"((?:\\.|[^"\\])*)"/g;
			let qm;
			while ((qm = qRe.exec(line))) {
				const val = qm[1];
				if (isFontName(val)) { add(rel, ln, val, "font face (not a UI string)", "font_name"); continue; }
				if (isNativeToken(val)) { add(rel, ln, val, "native Scaleform $ token — keep game translation", "native_token"); continue; }
				if (isPlayerFacing(val)) add(rel, ln, val, "text assign / draw helper", "hud_label");
			}
		}

		// Standalone ALL-CAPS literals in string concat for HUD copy.
		const capRe = /"([A-Z][A-Z0-9][A-Z0-9 +\-\/]{1,40})"/g;
		let cm;
		while ((cm = capRe.exec(line))) {
			const val = cm[1];
			if (looksCodey(val)) continue;
			if (/^(ENTER_FRAME|COMPLETE|IO_ERROR)$/.test(val)) continue;
			if (isPlayerFacing(val)) add(rel, ln, val, "caps literal", "hud_label");
		}

		// $ tokens anywhere (keep native).
		const tokRe = /"(\${1,2}[A-Za-z][A-Za-z0-9_ ]*)"/g;
		let tm;
		while ((tm = tokRe.exec(line))) {
			if (isFontName(tm[1])) add(rel, ln, tm[1], "font face", "font_name");
			else add(rel, ln, tm[1], "native $ token — do not replace", "native_token");
		}
	}
}

function walkIni(rel) {
	const abs = path.join(root, rel);
	if (!fs.existsSync(abs)) return;
	const lines = fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n").split("\n");
	let section = "";
	for (let i = 0; i < lines.length; i++) {
		const ln = i + 1;
		const line = lines[i].trim();
		const sec = line.match(/^\[([^\]]+)\]/);
		if (sec) { section = sec[1]; continue; }
		if (line.charAt(0) !== ";") continue;
		const text = line.replace(/^;+\s*/, "");
		if (text.length < 12) continue;
		if (/^v0\.\d/.test(text) && text.length < 40) continue;
		add(rel, ln, text, "INI comment [" + (section || "top") + "] — player-facing help for people who edit the file", "ini_help", {
			key: "ini." + slug(section + "_" + text.slice(0, 24)),
		});
	}
}

function walkXml(rel) {
	const abs = path.join(root, rel);
	if (!fs.existsSync(abs)) return;
	const src = fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n");
	const lines = src.split("\n");
	for (let i = 0; i < lines.length; i++) {
		const ln = i + 1;
		const line = lines[i];
		const tags = [
			["moduleName", "fomod installer title"],
			["Name", "fomod name"],
			["Author", "fomod author (do not translate)"],
			["Description", "fomod description"],
			["installStep name", "fomod step"],
			["group name", "fomod group"],
			["plugin name", "fomod plugin"],
		];
		for (const [tag, ctx] of tags) {
			const re = new RegExp(tag.replace(" ", "\\s+") + '(?:="([^"]+)")?>([^<]*)<', "i");
			const m = line.match(re) || line.match(new RegExp(tag + '="([^"]+)"'));
			if (!m) continue;
			const val = (m[2] || m[1] || "").trim();
			if (!val) continue;
			if (tag === "Author") { add(rel, ln, val, ctx, "do_not_translate", { key: "KEEP_AUTHOR" }); continue; }
			if (val.length < 3) continue;
			add(rel, ln, val, ctx, "fomod");
		}
		const desc = line.match(/<description>([\s\S]*)<\/description>/i);
		if (desc) add(rel, ln, desc[1].trim(), "fomod plugin description", "fomod");
	}
	// multiline descriptions
	const block = /<description>([\s\S]*?)<\/description>/gi;
	let bm;
	while ((bm = block.exec(src))) {
		const before = src.slice(0, bm.index);
		const ln = before.split("\n").length;
		const val = bm[1].replace(/\s+/g, " ").trim();
		if (val.length >= 8) add(rel, ln, val, "fomod plugin description", "fomod");
	}
}

function walkCpp(rel) {
	const abs = path.join(root, rel);
	if (!fs.existsSync(abs)) return;
	const src = fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n");
	const lines = src.split("\n");
	for (let i = 0; i < lines.length; i++) {
		const ln = i + 1;
		const line = lines[i];
		if (line.trim().indexOf("//") === 0) continue;
		if (/REX::(INFO|WARN|DEBUG|ERROR)/.test(line)) continue; // log only
		// Card titles / values pushed to ActionScript.
		const qRe = /"((?:\\.|[^"\\])*)"/g;
		let m;
		while ((m = qRe.exec(line))) {
			const val = m[1];
			if (/^(LIKED|LOVED|DISLIKED|HATED|BUSY|CALMED|CREDITS|GAINED|CURED|ITEM|GAME|DATA|MISC)$/.test(val)) {
				add(rel, ln, val, "DLL card title / kind pushed to the movie", "dll_card", { key: "card." + val.toLowerCase() });
			}
			if (/ that\.$/.test(val) || /busy\.$/.test(val) || /respond\.$/.test(val) || /parents\.$/.test(val)) {
				add(rel, ln, val, "English GMST fallback phrase (matcher, not drawn as Horizon copy)", "gmst_fallback", { key: "KEEP_GMST_FALLBACK" });
			}
		}
	}
}

for (const rel of CANON_AS) walkAs(rel);

// Other AS files that are not duplicates of the spliced HUD.
function walkDir(dir, pred) {
	const abs = path.join(root, dir);
	if (!fs.existsSync(abs)) return;
	for (const name of fs.readdirSync(abs)) {
		const p = path.join(abs, name);
		const rel = path.relative(root, p);
		const st = fs.statSync(p);
		if (st.isDirectory()) {
			if (SKIP_AS_DIR.test(rel)) continue;
			walkDir(rel, pred);
		} else if (pred(rel)) {
			walkAs(rel);
		}
	}
}
walkDir("actionscript", (rel) => {
	if (!/\.as$/i.test(rel)) return false;
	if (SKIP_AS_DIR.test(rel) || SKIP_AS_FILE.test(rel)) return false;
	const norm = rel.replace(/\\/g, "/");
	if (CANON_AS.indexOf(norm) >= 0) return false;
	return true;
});

// Decompiled vanilla twins (imp/, HUDMenu_1*) are not Horizon-owned copy, but they
// carry Starfield $ tokens that must stay native. Inventory those tokens only.
function walkNativeTokens(rel) {
	const abs = path.join(root, rel);
	if (!fs.existsSync(abs)) return;
	const src = fs.readFileSync(abs, "utf8").replace(/\r\n/g, "\n");
	const lines = src.split("\n");
	for (let i = 0; i < lines.length; i++) {
		const tokRe = /"(\${1,2}[A-Za-z][A-Za-z0-9_ ]*)"/g;
		let tm;
		while ((tm = tokRe.exec(lines[i]))) {
			if (isFontName(tm[1])) add(rel, i + 1, tm[1], "font face in vanilla twin (not Horizon copy)", "font_name");
			else add(rel, i + 1, tm[1], "native $ token in vanilla twin — keep game translation", "native_token");
		}
	}
}
function walkNativeDir(dir) {
	const abs = path.join(root, dir);
	if (!fs.existsSync(abs)) return;
	for (const name of fs.readdirSync(abs)) {
		const p = path.join(abs, name);
		const rel = path.relative(root, p);
		if (fs.statSync(p).isDirectory()) walkNativeDir(rel);
		else if (/\.as$/i.test(rel)) walkNativeTokens(rel);
	}
}
walkNativeDir("actionscript");

walkIni("Interface/HorizonUI/HorizonUI.default.ini");
walkIni("preset/HorizonUI.moragars-choice.ini");
walkXml("fomod/info.xml");
walkXml("fomod/ModuleConfig.xml");

walkDir("src", (rel) => /\.(cpp|h|hpp)$/i.test(rel));

rows.sort((a, b) => {
	if (a.file !== b.file) return a.file < b.file ? -1 : 1;
	return Number(a.line) - Number(b.line);
});

fs.mkdirSync(outDir, { recursive: true });
const header = ["file", "line", "string", "context", "suggested_key", "module", "kind"];
const body = [header.join(",")].concat(rows.map((r) => header.map((h) => csvEscape(r[h])).join(",")));
fs.writeFileSync(outCsv, body.join("\n") + "\n", "utf8");

const byKind = {};
const byMod = {};
for (const r of rows) {
	byKind[r.kind] = (byKind[r.kind] || 0) + 1;
	byMod[r.module] = (byMod[r.module] || 0) + 1;
}
console.log("wrote " + outCsv);
console.log("rows " + rows.length);
console.log("by kind " + JSON.stringify(byKind));
console.log("by module " + JSON.stringify(byMod));
