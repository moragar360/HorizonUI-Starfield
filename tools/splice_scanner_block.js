// Purpose: splice actionscript/scanner/hzs_block.as into both MonocleMenu hosts.
// __HZS_LRG__ becomes false (standard) or true (lrg). Hosts keep CRLF.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const ROOT = path.join(__dirname, "..");
const BLOCK = fs.readFileSync(path.join(ROOT, "actionscript", "scanner", "hzs_block.as"), "utf8").replace(/\r\n/g, "\n");
const START = "      // ===================== Horizon UI Scanner (monoclemenu) =====================";
const END = "      // =================== end shared settings reader ===================";
const hosts = [
	["actionscript/imp/simp_monoclemenu/MonocleMenu.as", "false"],
	["actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as", "true"],
];
if (!BLOCK.includes(START) || !BLOCK.includes(END)) {
	console.error("scanner block markers missing");
	process.exit(1);
}
const inner = BLOCK.slice(BLOCK.indexOf(START), BLOCK.indexOf(END) + END.length);
for (const [rel, lrg] of hosts) {
	const p = path.join(ROOT, rel);
	let text = fs.readFileSync(p, "utf8");
	const nl = text.indexOf("\r\n") >= 0 ? "\r\n" : "\n";
	const src = text.replace(/\r\n/g, "\n");
	const a = src.indexOf(START);
	const b = src.indexOf(END);
	if (a < 0 || b < 0 || b <= a) {
		console.error("host markers missing: " + rel);
		process.exit(1);
	}
	const spliced = src.slice(0, a) + inner.replace(/__HZS_LRG__/g, lrg) + src.slice(b + END.length);
	fs.writeFileSync(p, spliced.replace(/\n/g, nl));
	console.log("spliced " + rel + " (HZS_LRG=" + lrg + ")");
}
