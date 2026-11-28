// Purpose: splice hzc / hzd / hzs blocks into both Scaleform twins so the
// hosts stay byte-identical to the source blocks (LRG token replaced).
// CRLF hosts stay CRLF. Run from the repo root after editing a block.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const ROOT = path.join(__dirname, "..");

function splice(hostRel, blockRel, startMark, endMark, token, val) {
	const hostPath = path.join(ROOT, hostRel);
	const blockPath = path.join(ROOT, blockRel);
	let host = fs.readFileSync(hostPath, "utf8");
	const crlf = host.indexOf("\r\n") >= 0;
	host = host.replace(/\r\n/g, "\n");
	let block = fs.readFileSync(blockPath, "utf8").replace(/\r\n/g, "\n");
	block = block.split(token).join(val);
	let start = host.indexOf(startMark);
	const end = host.indexOf(endMark, start);
	if (start < 0 || end < 0) {
		console.error("splice markers missing: " + hostRel);
		process.exit(1);
	}
	while (start > 0 && host.charAt(start - 1) !== "\n") start--;
	const endAt = end + endMark.length;
	host = host.slice(0, start) + block.replace(/\s+$/, "") + host.slice(endAt);
	if (crlf) host = host.replace(/\n/g, "\r\n");
	fs.writeFileSync(hostPath, host);
	console.log("spliced " + hostRel);
}

const HZC_START = "// ===================== Horizon UI Comms (HUD Messages)";
const HZC_END = "// =================== end Horizon UI Comms (HUD Messages) v0.35 ===================";
const HZD_START = "// ===================== Horizon UI Comms (Dialogue)";
const HZD_END = "// =================== end Horizon UI Comms (Dialogue) v0.35 ===================";
const HZS_START = "// ===================== Horizon UI Scanner (monoclemenu) =====================";
const HZS_END = "// =================== end shared settings reader ===================";

splice("actionscript/imp/imp/scripts/HUDMessagesMenu.as", "actionscript/comms/hzc_block.as", HZC_START, HZC_END, "__HZC_LRG__", "false");
splice("actionscript/imp/imp-Lrg/scripts/HUDMessagesMenu.as", "actionscript/comms/hzc_block.as", HZC_START, HZC_END, "__HZC_LRG__", "true");
splice("actionscript/imp/dimp/scripts/DialogueMenu.as", "actionscript/comms/hzd_block.as", HZD_START, HZD_END, "__HZD_LRG__", "false");
splice("actionscript/imp/dimp-Lrg/scripts/DialogueMenu.as", "actionscript/comms/hzd_block.as", HZD_START, HZD_END, "__HZD_LRG__", "true");
splice("actionscript/imp/simp_monoclemenu/MonocleMenu.as", "actionscript/scanner/hzs_block.as", HZS_START, HZS_END, "__HZS_LRG__", "false");
splice("actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as", "actionscript/scanner/hzs_block.as", HZS_START, HZS_END, "__HZS_LRG__", "true");
console.log("module twins spliced");
