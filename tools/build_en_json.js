// Purpose: build Data/SFSE/Plugins/HorizonUI/Localization/en.json from
// docs/localization/en.template.json plus unique inventory keys.
// Skips native $ tokens, fonts, FOMOD, INI comments, and GMST fallbacks.
// Run from the repo root: node tools/build_en_json.js
// Author: Moragar. Last modified: 2026-11-27.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const templatePath = path.join(root, "docs", "localization", "en.template.json");
const csvPath = path.join(root, "docs", "localization", "STRING_INVENTORY.csv");
const outPath = path.join(root, "Data", "SFSE", "Plugins", "HorizonUI", "Localization", "en.json");

const KEEP_KIND = {
	native_token: 1,
	font_name: 1,
	fomod: 1,
	ini_help: 1,
	gmst_fallback: 1,
	do_not_translate: 1,
};
const KEEP_PREFIX = /^(KEEP_NATIVE|KEEP_FONT|KEEP_AUTHOR|KEEP_GMST)/;

function parseCsv(text) {
	const rows = [];
	let i = 0;
	const n = text.length;
	function cell() {
		if (text[i] === '"') {
			i++;
			let s = "";
			while (i < n) {
				if (text[i] === '"' && text[i + 1] === '"') { s += '"'; i += 2; continue; }
				if (text[i] === '"') { i++; break; }
				s += text[i++];
			}
			if (text[i] === ",") i++;
			else if (text[i] === "\r") i++;
			return s;
		}
		let s = "";
		while (i < n && text[i] !== "," && text[i] !== "\n" && text[i] !== "\r") s += text[i++];
		if (text[i] === ",") i++;
		return s;
	}
	const header = [];
	while (i < n && text[i] !== "\n" && text[i] !== "\r") header.push(cell());
	if (text[i] === "\r") i++;
	if (text[i] === "\n") i++;
	while (i < n) {
		if (text[i] === "\n" || text[i] === "\r") { i++; continue; }
		const obj = {};
		for (let h = 0; h < header.length; h++) obj[header[h]] = cell();
		rows.push(obj);
		if (text[i] === "\r") i++;
		if (text[i] === "\n") i++;
	}
	return rows;
}

function setPath(obj, dotted, value) {
	const parts = String(dotted).split(".").filter(Boolean);
	if (parts.length === 0) return;
	let cur = obj;
	for (let i = 0; i < parts.length - 1; i++) {
		const p = parts[i];
		if (cur[p] == null || typeof cur[p] !== "object" || Array.isArray(cur[p])) cur[p] = {};
		cur = cur[p];
	}
	const leaf = parts[parts.length - 1];
	if (cur[leaf] == null) cur[leaf] = value;
}

const en = JSON.parse(fs.readFileSync(templatePath, "utf8"));
en._meta = en._meta || {};
en._meta.schema = 1;
en._meta.language = "en";
en._meta.languageName = "English";
en._meta.notes = "American English source. Translators copy this file, keep every key, and replace only the string values. Placeholders look like {0} {1} {name}. Keep them. Do not wrap Horizon-owned strings in $ tokens.";

const rows = parseCsv(fs.readFileSync(csvPath, "utf8"));
const seen = Object.create(null);
let added = 0;
for (const r of rows) {
	const kind = r.kind || "";
	if (KEEP_KIND[kind]) continue;
	let key = String(r.suggested_key || "");
	if (!key || KEEP_PREFIX.test(key)) continue;
	if (key.indexOf("fomod.") === 0 || key.indexOf("ini.") === 0) continue;
	const text = String(r.string || "").trim();
	if (!text || text.length > 240) continue;
	if (seen[key]) continue;
	seen[key] = true;
	setPath(en, key, text);
	added++;
}

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(en, null, 2) + "\n", "utf8");
console.log("wrote " + path.relative(root, outPath).replace(/\\/g, "/") + " inventory keys " + added);
