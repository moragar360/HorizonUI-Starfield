// Purpose: splice hz51_insert.as + hz51_draw.as into the live horizon_block.as
// after Settings 2.0 is already patched. Does not re-run the one-shot replacements.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const ROOT = path.join(__dirname, "..");
const HUD = path.join(ROOT, "actionscript", "horizon_block.as");
const INSERT = fs.readFileSync(path.join(ROOT, "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const DRAW = fs.readFileSync(path.join(ROOT, "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");
let text = fs.readFileSync(HUD, "utf8").replace(/\r\n/g, "\n");
const startMark = "      // ===================== Settings 2.0 (F11 rebuild) =====================";
const endMark = "      private function hzSetRows(tab:int) : Array";
const start = text.indexOf(startMark);
const end = text.indexOf(endMark);
if (start < 0 || end < 0 || end <= start) {
	console.error("splice markers missing");
	process.exit(1);
}
if (!INSERT.startsWith(startMark)) {
	console.error("hz51_insert.as must start with the Settings 2.0 marker");
	process.exit(1);
}
text = text.slice(0, start) + INSERT.replace(/\s+$/, "") + "\n" + DRAW.replace(/^\s+/, "").replace(/\s+$/, "") + "\n\n" + text.slice(end);
text = text.replace(
	/private var HZ_SET_W:Number = \d+;[^\n]*\n      private var HZ_SET_H:Number = \d+;/,
	"private var HZ_SET_W:Number = 1260;   // width cap; height 726. hz51Fit never grows past this so HUD side cards stay visible\n      private var HZ_SET_H:Number = 726;"
);
text = text.replace(
	/private static const HZ_SET_TOP:Number = \d+;      \/\/ body top[^\n]*/,
	"private static const HZ_SET_TOP:Number = 90;      // body top (head 52 + tabs 38)"
);
text = text.replace(/HZ_SET_H - HZ51_FOOT - HZ_SET_TOP - \d+/g, "HZ_SET_H - HZ51_FOOT - HZ_SET_TOP - 64");
text = text.replace(
	'if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + this.hz34BanH(); }',
	'if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + 40 + HZ51_MOD_GAP; }\n         if(r.t == "mb") { return (r.h ? HZ51_SEC : 0) + 88 + HZ51_MOD_GAP; }\n         if(r.t == "mc") { return (r.h ? HZ51_SEC : 0) + 76 + HZ51_MOD_GAP; }'
);
text = text.replace(
	'if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + 40; }\n         if(r.t == "g") { return 48; }',
	'if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + 40 + HZ51_MOD_GAP; }\n         if(r.t == "mb") { return (r.h ? HZ51_SEC : 0) + 88 + HZ51_MOD_GAP; }\n         if(r.t == "mc") { return (r.h ? HZ51_SEC : 0) + 76 + HZ51_MOD_GAP; }\n         if(r.t == "g") { return 48; }'
);
text = text.replace(
	'if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + 40; }\n         if(r.t == "mb") { return (r.h ? HZ51_SEC : 0) + 88; }\n         if(r.t == "mc") { return (r.h ? HZ51_SEC : 0) + 76; }',
	'if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + 40 + HZ51_MOD_GAP; }\n         if(r.t == "mb") { return (r.h ? HZ51_SEC : 0) + 88 + HZ51_MOD_GAP; }\n         if(r.t == "mc") { return (r.h ? HZ51_SEC : 0) + 76 + HZ51_MOD_GAP; }'
);
if (!text.includes('id == "findx"')) {
	text = text.replace(
		'else if(id == "findbox") { this.hzSetFindOn = true; this.hzSetFocus = 2; dirty = true; }',
		'else if(id == "findx") { this.hz51FindClose(); dirty = true; }\n            else if(id == "findbox") { this.hzSetFindOn = true; this.hzSetFocus = 2; dirty = true; }'
	);
}
if (!text.includes('id == "modqh"')) {
	text = text.replace(
		'else if(id == "qmclr") { this.hz37Act({"k":"_qmclear","t":"x"},1); dirty = true; }',
		'else if(id == "modqh") { this.hzSetPend.QuickMenuHorizon = !this.hzSetPend.QuickMenuHorizon; this.hzSetLive(this.hzSetPend); dirty = true; }\n            else if(id == "qmclr") { this.hz37Act({"k":"_qmclear","t":"x"},1); dirty = true; }'
	);
}
if (!text.includes('id.indexOf("tog") == 0')) {
	text = text.replace(
		'else if(id == "qmclr") { this.hz37Act({"k":"_qmclear","t":"x"},1); dirty = true; }',
		'else if(id.indexOf("tog") == 0)\n            {\n               var ti:int = int(id.substr(3));\n               this.hzSetRow = ti;\n               var tr:Object = rows[ti];\n               if(tr != null && tr.t == "mc" && tr.swk != undefined)\n               {\n                  var sk:String = String(tr.swk);\n                  this.hzSetPend[sk] = !this.hz51On(sk);\n                  this.hzSetLive(this.hzSetPend);\n               }\n               else if(tr != null) { this.hzSetChange(tr,1); if(this.hzArrange) { return; } }\n               dirty = true;\n            }\n            else if(id.indexOf("act") == 0)\n            {\n               var ai:int = int(id.substr(3));\n               this.hzSetRow = ai;\n               if(rows[ai] != null) { this.hzSetChange(rows[ai],1); if(this.hzArrange) { return; } }\n               dirty = true;\n            }\n            else if(id == "qmclr") { this.hz37Act({"k":"_qmclear","t":"x"},1); dirty = true; }'
	);
}
text = text.replace(
	'if(rr.t == "r" || rr.t == "q" || rr.t == "l" || rr.t == "a" || rr.t == "c" || rr.t == "p") { this.hz51OpenDrop(ri, rows); }\n               else if(rr.t == "b" || rr.t == "k" || rr.t == "x" || rr.t == "m" || rr.t == "g" || rr.t == "md") { this.hzSetChange(rr,1); if(this.hzArrange) { return; } }\n               else if(rr.t == "z" && !rr.dis) { this.hz34ZToggle(String(rr.k)); }',
	'this.hzSetRow = ri;\n               dirty = true;'
);
text = text.replace(
	"         var hit:Object = null;\n         var hid:String = \"\";\n         for each(var h:Object in this.hzSetHits)\n         {\n            if(mx >= h.x && mx <= h.x + h.w && my >= h.y && my <= h.y + h.h)\n            {\n               hit = h; hid = h.id;\n               if(String(h.id).indexOf(\"bar\") == 0) { break; } // slider wins over its row\n            }\n         }",
	"         var hit:Object = this.hz51HitAt(mx, my);\n         var hid:String = hit != null ? String(hit.id) : \"\";"
);
text = text.replace(
	'var w:Number = this.hzSetBtn(host,hg,R,cy - 14,lab,cf || ed,true,rh && !dim,T,"row" + i,13);',
	'var w:Number = this.hz51Btn(host,hg,R,cy,lab,rh && !dim,T,"row" + i);'
);
if (!/HZ_SET_W:Number = 1260/.test(text) || !/HZ_SET_H:Number = 726/.test(text)) {
	console.error("failed to pin 1260x726");
	process.exit(1);
}
if (!text.includes('id == "dropout"')) {
	text = text.replace(
		'else if(id.indexOf("dopt") == 0) { this.hz51DropPick(rows[this.hzSetDrop], int(id.substr(4))); this.hzSetDrop = -1; this.hzSetFocus = 0; dirty = true; }',
		'else if(id == "dropout") { this.hzSetDrop = -1; this.hzSetFocus = 0; dirty = true; }\n            else if(id == "dropbg") { }\n            else if(id.indexOf("dopt") == 0) { this.hz51DropPick(rows[this.hzSetDrop], int(id.substr(4))); this.hzSetDrop = -1; this.hzSetFocus = 0; dirty = true; }'
	);
}
if (!text.includes("this.hz51FbSeen = null")) {
	text = text.replace(
		"this.hz51Pad = this.hzVehPad == 1;",
		"this.hz51Pad = this.hzVehPad == 1;\n         this.hz51FbSeen = null;\n         this.hz51FbDbg = \"\";"
	);
}
if (!text.includes("SETTINGS FALLBACK")) {
	text = text.replace(
		'this.hzDbgText.text = "CROSSHAIR: " + this.hzDbgCross + "\\n\\nWEAPON: " + this.hzDbgWeap + "\\n\\nCOMPASS (array:type x count): " + this.hzDbgCmp + "\\n\\nENV KEYS:\\n" + this.hzDbgEnv + "\\n\\nV0.26 PROVIDERS:\\n" + this.hz26DbgText();',
		'var fb51:String = this.hz51FbDbg != null && this.hz51FbDbg.length > 0 ? "\\n\\nSETTINGS FALLBACK:\\n" + this.hz51FbDbg : "";\n         this.hzDbgText.text = "CROSSHAIR: " + this.hzDbgCross + "\\n\\nWEAPON: " + this.hzDbgWeap + "\\n\\nCOMPASS (array:type x count): " + this.hzDbgCmp + "\\n\\nENV KEYS:\\n" + this.hzDbgEnv + "\\n\\nV0.26 PROVIDERS:\\n" + this.hz26DbgText() + fb51;'
	);
}
if (!text.includes("function hz51Stroke") || !text.includes("function hz51HeadSlots") || !text.includes("hzSetOver") || !text.includes("function hz51HitAt") || !text.includes("function hz51Disk") || !text.includes("function hz51FbLog") || !text.includes("function hz51PvPaint") || !text.includes("function hz51WrapMod") || !text.includes("function hz51DrawArrangeBtn") || !text.includes("function hz51UnavailChip") || !text.includes("function hz51FillGroup") || !text.includes("function hz51PresetNames") || !text.includes("function hz51PvDialogue") || !text.includes("function hz51PvKind") || !text.includes("function hz51PvPlanet")) {
	console.error("splice missing new helpers");
	process.exit(1);
}
fs.writeFileSync(HUD, text);
console.log("spliced", HUD, "chars", text.length);
