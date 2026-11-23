// FOMOD: Quick Menu (Favorites) is an optional module, not part of Core.
// Checks fomod/ModuleConfig.xml and fomod/info.xml:
//  1. both files are well-formed XML;
//  2. requiredInstallFiles installs only 00 Core, and does not name favoritesmenu;
//  3. the Optional Modules step has a Recommended plugin "Quick Menu (Favorites)" that
//     installs the folder "05 Quick Menu" and is always ticked by default (no CouldBeUsable
//     pattern: a leftover Horizon favoritesmenu.swf must not silently untick it on upgrade);
//  4. the compatibility note and info.xml no longer say the quick menu is part of Core;
//  5. quickmenu.marker ships in the repo, HZ30_MODS probes it, and F11 locks HORIZON STYLE
//     when it is absent (same install-note pattern as Comms).
// Run: node tests/fomod_quickmenu_optional_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const fs = require("fs");
const path = require("path");
const { root, expect, finish } = require("./lib/r3");

function wellFormed(xml, label) {
	// Minimal tag-stack check (comments, PI, DOCTYPE, self-closing tags, quoted attributes).
	let s = xml.replace(/<\?[\s\S]*?\?>/g, "").replace(/<!--[\s\S]*?-->/g, "").replace(/<!DOCTYPE[\s\S]*?>/gi, "");
	const stack = [];
	const re = /<(\/)?([A-Za-z_][\w:.-]*)\b([^>]*?)(\/)?>/g;
	let m, last = 0;
	while ((m = re.exec(s))) {
		const between = s.slice(last, m.index);
		if (/[<>]/.test(between)) return label + " has a stray < or > outside tags";
		last = m.index + m[0].length;
		const close = !!m[1], name = m[2], self = !!m[4];
		const attrs = m[3] || "";
		if ((attrs.match(/"/g) || []).length % 2 !== 0) return label + " has an unclosed attribute quote on <" + name + ">";
		if (close) {
			if (self) return label + " has an invalid </" + name + "/> tag";
			if (!stack.length) return label + " has a closing </" + name + "> with no open tag";
			const open = stack.pop();
			if (open !== name) return label + " closes <" + open + "> with </" + name + ">";
		} else if (!self) {
			stack.push(name);
		}
	}
	if (last < s.length && /[<>]/.test(s.slice(last))) return label + " has a stray < or > after the last tag";
	if (stack.length) return label + " is missing a closing tag for <" + stack.join(">, <") + ">";
	return null;
}

const cfgPath = path.join(root, "fomod", "ModuleConfig.xml");
const infoPath = path.join(root, "fomod", "info.xml");
const cfg = fs.readFileSync(cfgPath, "utf8").replace(/\r\n/g, "\n");
const info = fs.readFileSync(infoPath, "utf8").replace(/\r\n/g, "\n");

const wfCfg = wellFormed(cfg, "ModuleConfig.xml");
const wfInfo = wellFormed(info, "info.xml");
expect(wfCfg === null, "ModuleConfig.xml is well-formed" + (wfCfg ? " (" + wfCfg + ")" : ""));
expect(wfInfo === null, "info.xml is well-formed" + (wfInfo ? " (" + wfInfo + ")" : ""));

const req = /<requiredInstallFiles>([\s\S]*?)<\/requiredInstallFiles>/.exec(cfg);
expect(!!req, "ModuleConfig.xml has requiredInstallFiles");
const reqBody = req ? req[1] : "";
expect(/<folder\s+source="00 Core"/.test(reqBody), "requiredInstallFiles still installs 00 Core");
expect(!/favoritesmenu/i.test(reqBody), "requiredInstallFiles does not name favoritesmenu");
const reqSources = [...reqBody.matchAll(/<(?:folder|file)\s+[^>]*\bsource="([^"]+)"/g)].map((x) => x[1]);
expect(JSON.stringify(reqSources) === JSON.stringify(["00 Core"]), "requiredInstallFiles sources are only 00 Core (got " + JSON.stringify(reqSources) + ")");

const opt = /<installStep name="Optional Modules">([\s\S]*?)<\/installStep>/.exec(cfg);
expect(!!opt, "Optional Modules install step exists");
const optBody = opt ? opt[1] : "";
const pluginRe = /<plugin name="Quick Menu \(Favorites\)">([\s\S]*?)<\/plugin>/;
const plug = pluginRe.exec(optBody);
expect(!!plug, "Optional Modules has the plugin Quick Menu (Favorites)");
const plugBody = plug ? plug[1] : "";
expect(/<folder\s+source="05 Quick Menu"\s+destination=""\s+priority="0"\s*\/>/.test(plugBody), "Quick Menu (Favorites) installs the folder 05 Quick Menu");
expect(/<typeDescriptor>\s*<type\s+name="Recommended"\s*\/>\s*<\/typeDescriptor>/.test(plugBody) && !/dependencyType|CouldBeUsable|fileDependency/.test(plugBody), "Quick Menu (Favorites) is plain Recommended (always ticked; no CouldBeUsable pattern)");
expect(/untick this to keep the game's quick menu or another mod's/i.test(plugBody), "the plugin description says to untick it to keep the game's or another mod's quick menu");
expect(/HORIZON STYLE appears locked/.test(plugBody), "the plugin description says the F11 row appears locked when the module is not installed");

expect(!/quick menu \(Core\)/i.test(cfg), "ModuleConfig.xml no longer calls the quick menu part of Core");
expect(/optional Quick Menu \(Favorites\) module replaces Interface\\favoritesmenu\.swf/i.test(cfg), "the compatibility note points at the optional Quick Menu (Favorites) module");

expect(!/Core also replaces the quick menu/i.test(info), "info.xml no longer says Core replaces the quick menu");
expect(/optional Quick Menu \(Favorites\) module replaces the quick menu/i.test(info), "info.xml describes Quick Menu (Favorites) as optional");
expect(/Untick it to keep the game's quick menu or another mod's/i.test(info), "info.xml says to untick it to keep the game's or another mod's quick menu");

// The repo does not stage the 00 Core / 05 Quick Menu folders; those exist only in the FOMOD zip.
// This test locks the installer source so a later pack step can move the two movies into 05 Quick Menu
// and copy Interface/HorizonUI/modules/quickmenu.marker into 05 Quick Menu.
expect(!/source="00 Core\/Interface\/favoritesmenu/i.test(cfg), "ModuleConfig.xml does not install favoritesmenu from 00 Core by path");

const marker = path.join(root, "Interface", "HorizonUI", "modules", "quickmenu.marker");
expect(fs.existsSync(marker), "the repo has Interface/HorizonUI/modules/quickmenu.marker");
const markerTxt = fs.readFileSync(marker, "utf8");
expect(/quickmenu/.test(markerTxt) && /The HUD only checks that this file exists/.test(markerTxt), "quickmenu.marker is an existence marker, like font.marker");

const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const mods = /private static const HZ30_MODS:Array = \[([^\]]+)\]/.exec(as);
expect(!!mods && mods[1].indexOf('"quickmenu"') >= 0, "HZ30_MODS includes quickmenu");
expect(/this\.hz30Mod\["quickmenu"\] !== 1/.test(as) && /Quick Menu module not installed\. Install it from the Horizon UI installer\./.test(as), "hz34CardRows locks HORIZON STYLE when quickmenu.marker is absent, with the same install-note wording as Comms");

finish("fomod_quickmenu_optional_test");
