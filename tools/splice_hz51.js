// Purpose: splice hz51_insert.as + hz51_draw.as into the live horizon_block.as
// after Settings 2.0 is already patched. Does not re-run the one-shot replacements.
// Author: Moragar. Last modified: 2026-11-26.
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
	'if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + 40; }'
);
if (!text.includes('id == "findx"')) {
	text = text.replace(
		'else if(id == "findbox") { this.hzSetFindOn = true; this.hzSetFocus = 2; dirty = true; }',
		'else if(id == "findx") { this.hz51FindClose(); dirty = true; }\n            else if(id == "findbox") { this.hzSetFindOn = true; this.hzSetFocus = 2; dirty = true; }'
	);
}
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
if (!text.includes("function hz51Stroke") || !text.includes("function hz51HeadSlots") || !text.includes("hzSetOver") || !text.includes("function hz51HitAt") || !text.includes("function hz51Disk")) {
	console.error("splice missing new helpers");
	process.exit(1);
}
fs.writeFileSync(HUD, text);
console.log("spliced", HUD, "chars", text.length);
