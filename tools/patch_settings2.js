// Purpose: splice Settings 2.0 helpers into horizon_block.as (Node port).
// Author: Moragar. Last modified: 2026-11-26.
"use strict";
const fs = require("fs");
const path = require("path");
const ROOT = path.join(__dirname, "..");
const HUD = path.join(ROOT, "actionscript", "horizon_block.as");
const INSERT = fs.readFileSync(path.join(ROOT, "actionscript", "hz51_insert.as"), "utf8").replace(/\r\n/g, "\n");
const DRAW = fs.readFileSync(path.join(ROOT, "actionscript", "hz51_draw.as"), "utf8").replace(/\r\n/g, "\n");
let text = fs.readFileSync(HUD, "utf8").replace(/\r\n/g, "\n");

function once(oldS, newS, label) {
	const n = text.split(oldS).length - 1;
	if (n !== 1) {
		console.error(label + ": expected 1 match, found " + n);
		console.error(JSON.stringify(oldS.slice(0, 180)));
		process.exit(1);
	}
	text = text.replace(oldS, newS);
}
function replaceFn(sig, newBody, label) {
	const i = text.indexOf(sig);
	if (i < 0) { console.error(label + ": signature not found"); process.exit(1); }
	const brace = text.indexOf("{", i);
	let depth = 0;
	for (let j = brace; j < text.length; j++) {
		const ch = text[j];
		if (ch === "{") depth++;
		else if (ch === "}") {
			depth--;
			if (depth === 0) {
				text = text.slice(0, i) + newBody + text.slice(j + 1);
				return;
			}
		}
	}
	console.error(label + ": unbalanced");
	process.exit(1);
}

once(
	'      private static const HZ_SET_W:Number = 1000;\n      private static const HZ_SET_H:Number = 660;\n      private static const HZ_SET_TABS:Array = ["CARDS","STYLE","TEXT","EFFECTS","RULES","COMPASS","CONTROLS","SCANNER","COMMS"];   // v0.30: 7 SCANNER, 8 COMMS (optional modules)',
	'      private var HZ_SET_W:Number = 1260;\n      private var HZ_SET_H:Number = 726;\n      private static const HZ_SET_TABS:Array = ["CARDS","APPEARANCE","SCANNER","COMMS","SYSTEM"];   // Settings 2.0',
	"tabs"
);
once(
	"      private static const HZ_SET_TOP:Number = 112;      // list viewport top",
	"      private static const HZ_SET_TOP:Number = 90;      // body top (head 52 + tabs 38)",
	"top"
);
once(
	"         if(this.hzAccentHex >= 0) { a.push(uint(this.hzAccentHex)); }\n         return a;",
	"         a.push(this.hzAccentHex >= 0 ? uint(this.hzAccentHex) : HZ_ACCENT);\n         return a;",
	"acc pal"
);
once(
	'         if(this.hzAccentHex >= 0) { a.push("CUSTOM"); }\n         return a;',
	'         a.push("CUSTOM");\n         return a;',
	"acc names"
);
once(
	"         if(this.hzCardHex >= 0) { a.push(uint(this.hzCardHex)); }\n         return a;",
	"         a.push(this.hzCardHex >= 0 ? uint(this.hzCardHex) : uint(HZ_CARDCOLS[0]));\n         return a;",
	"card pal"
);
once(
	'         if(this.hzCardHex >= 0) { a.push("CUSTOM"); }\n         return a;',
	'         a.push("CUSTOM");\n         return a;',
	"card names"
);

const marker = "      private function hzSetRows(tab:int) : Array";
if (!text.includes(marker)) { console.error("hzSetRows marker missing"); process.exit(1); }
if (!text.includes("function hz51Rows")) {
	text = text.replace(marker, INSERT + "\n" + DRAW + "\n\n" + marker);
}

replaceFn(marker, `      private function hzSetRows(tab:int) : Array
      {
         this.hzSetPage = this.hz51PageClamp(tab);
         return this.hz51Rows(tab, this.hzSetPage);
      }
`, "hzSetRows");
replaceFn("      private function hzSetDraw() : void", `      private function hzSetDraw() : void
      {
         this.hz51Draw();
      }
`, "hzSetDraw");

once(
	"         this.hzSetTab = 0;\n         this.hzSetRow = 0;\n         this.hzSetScroll = 0;",
	'         this.hzSetTab = 0;\n         this.hzSetPage = 0;\n         this.hzSetFocus = 0;\n         this.hzSetDrop = -1;\n         this.hzSetFindOn = false;\n         this.hzSetFind = "";\n         this.hzSetHexK = "";\n         this.hzSetGlowK = "";\n         this.hz51Pad = this.hzVehPad == 1;\n         try { this.hz51IndexBuild(); } catch(eIdx:Error) { this.hzSetIdx = []; }\n         this.hzSetRow = 0;\n         this.hzSetScroll = 0;',
	"open"
);
once(
	"         this.HorizonSettings_mc.x = Math.round(cx - HZ_SET_W / 2);\n         this.HorizonSettings_mc.y = Math.round(cy - HZ_SET_H / 2);",
	"         try { this.hz51Fit(); } catch(eFitP:Error) { }\n         this.HorizonSettings_mc.x = Math.round(cx - this.HZ_SET_W / 2);\n         this.HorizonSettings_mc.y = Math.round(cy - this.HZ_SET_H / 2);",
	"place"
);
once(
	'         if(isNaN(this.hz35Mx) || Math.abs(mx - this.hz35Mx) > 2 || Math.abs(my - this.hz35My) > 2) { kb35 = this.hz35Kb; this.hz35Kb = false; this.hz35Mx = mx; this.hz35My = my; }',
	'         if(isNaN(this.hz35Mx) || Math.abs(mx - this.hz35Mx) > 2 || Math.abs(my - this.hz35My) > 2) { kb35 = this.hz35Kb; this.hz35Kb = false; this.hz51Pad = false; this.hz35Mx = mx; this.hz35My = my; }',
	"mouse pad"
);
once(
	"         this.hzSetIsOpen = false;\n         this.hzQmCapEnd();",
	'         this.hzSetIsOpen = false;\n         this.hzSetIdx = null;\n         this.hzSetFindOn = false;\n         this.hzSetDrop = -1;\n         this.hzSetHexK = "";\n         this.hzSetGlowK = "";\n         this.hzQmCapEnd();',
	"close"
);
once(
	'            else if(r.k == "_hz31gocomms") { this.hzSetTab = 8; this.hzSetRow = 0; this.hzSetScroll = 0; return; }\n            else if(r.k == "_hz40goscan") { this.hzSetTab = 7; this.hzSetRow = 0; this.hzSetScroll = 0; return; }',
	'            else if(r.k == "_hz31gocomms") { this.hz51Jump(3, 0, "Dialogue"); return; }\n            else if(r.k == "_hz40goscan") { this.hz51Jump(2, 0, "ScanReach"); return; }',
	"jumps"
);
once(
	"         o.CharacterRule = this.hzRuleChar;\n         o.FollowerColor = this.hzFolColor;\n         o.HoverScale = this.hz30Hover;",
	"         o.CharacterRule = this.hzRuleChar;\n         o.CharacterShowSeconds = this.hz27CharSecs;\n         o.FollowerColor = this.hzFolColor;\n         o.HoverScale = this.hz30Hover;",
	"char cur"
);
once(
	'         if(p.CharacterRule != undefined && !isNaN(Number(p.CharacterRule))) { this.hzRuleChar = this.hzRuleFix("CharacterRule",int(p.CharacterRule)); }',
	'         if(p.CharacterRule != undefined && !isNaN(Number(p.CharacterRule))) { this.hzRuleChar = this.hzRuleFix("CharacterRule",int(p.CharacterRule)); }\n         if(p.CharacterShowSeconds != undefined && !isNaN(Number(p.CharacterShowSeconds))) { this.hz27CharSecs = Math.max(2,Math.min(60,Number(p.CharacterShowSeconds))); }',
	"char live"
);
once(
	"         try { this.hz42ScSetLive(p); } catch(err42l:Error) { }   // v0.42.0 r2: [Scope] (live preview / cancel)\n         this.hzRefreshVisibility();",
	`         try { this.hz42ScSetLive(p); } catch(err42l:Error) { }   // v0.42.0 r2: [Scope] (live preview / cancel)
         if(p.Debug != undefined)
         {
            var ndb:Boolean = p.Debug === true || Number(p.Debug) >= 0.5;
            if(ndb != this.hzDebug) { this.hzDebug = ndb; this.hzDbgShow(); this.hzDbgEnvSub(); }
         }
         if(p.PerfDiag != undefined || p.PerfMode != undefined || p.PerfDump != undefined)
         {
            if(p.PerfDiag != undefined) { this.hzPerfDiag = p.PerfDiag === true || Number(p.PerfDiag) >= 0.5; }
            if(p.PerfMode != undefined && !isNaN(Number(p.PerfMode))) { var npm:int = int(p.PerfMode); this.hzPerfMode = npm < 0 || npm > 7 ? 0 : npm; }
            if(p.PerfDump != undefined) { this.hzPerfDumpIni = p.PerfDump === true || Number(p.PerfDump) >= 0.5; }
            this.hzPerfApply();
         }
         if(p.AccentHex != undefined)
         {
            var ah:int = this.hzParseHex(String(p.AccentHex));
            if(ah >= 0) { this.hzAccentHex = ah; }
         }
         if(p.CardHex != undefined)
         {
            var chx:int = this.hzParseHex(String(p.CardHex));
            if(chx >= 0) { this.hzCardHex = chx; }
         }
         if(p.Record != undefined) { this.hzMlRecord = p.Record === true || Number(p.Record) >= 0.5; }
         if(p.Persist != undefined) { this.hzMlPersist = p.Persist === true || Number(p.Persist) >= 0.5; }
         if(p.HistorySize != undefined && !isNaN(Number(p.HistorySize))) { this.hzMlHistory = int(Math.max(100,Math.min(1000,Math.round(Number(p.HistorySize) / 100) * 100))); }
         this.hzRefreshVisibility();`,
	"live diag"
);
once(
	"         try { this.hz42ScSetCur(cur); } catch(err42c:Error) { }   // v0.42.0 r2: [Scope]\n         return cur;",
	`         try { this.hz42ScSetCur(cur); } catch(err42c:Error) { }   // v0.42.0 r2: [Scope]
         cur.Debug = this.hzDebug;
         cur.PerfDiag = this.hzPerfDiag;
         cur.PerfMode = this.hzPerfMode;
         cur.PerfDump = this.hzPerfDumpIni;
         cur.AccentHex = this.hzAccentHex >= 0 ? this.hzHex(this.hzAccentHex) : "";
         cur.CardHex = this.hzCardHex >= 0 ? this.hzHex(this.hzCardHex) : "";
         cur.Record = this.hzMlRecord;
         cur.Persist = this.hzMlPersist;
         cur.HistorySize = this.hzMlHistory;
         return cur;`,
	"current diag"
);
once(
	`         if(code.indexOf("bind:") == 0) { return; }
         if(this.hz37Key(code)) { this.hzSetDraw(); return; }   // v0.37: preset name entry / pending confirm
         if(code.indexOf("ch:") == 0 || code == "bksp" || code.indexOf("bind:") == 0) { return; }
         var rows:Array = this.hzSetRows(this.hzSetTab);
         switch(code)
         {
            case "up": this.hz30RowStep(rows,-1); break;
            case "down": this.hz30RowStep(rows,1); break;
            case "left": this.hzSetChange(rows[this.hzSetRow],-1); break;
            case "right": this.hzSetChange(rows[this.hzSetRow],1); break;
            case "tabprev": this.hzSetTab = (this.hzSetTab + HZ_SET_TABS.length - 1) % HZ_SET_TABS.length; this.hzSetRow = 0; this.hzSetScroll = 0; break;
            case "tabnext": this.hzSetTab = (this.hzSetTab + 1) % HZ_SET_TABS.length; this.hzSetRow = 0; this.hzSetScroll = 0; break;`,
	`         try { if(this.hz51Key(code)) { this.hzSetDraw(); return; } } catch(e51k:Error) { }
         if(code.indexOf("bind:") == 0) { return; }
         if(this.hz37Key(code)) { this.hzSetDraw(); return; }   // v0.37: preset name entry / pending confirm
         if(code.indexOf("ch:") == 0 || code == "bksp" || code.indexOf("bind:") == 0) { return; }
         var rows:Array = this.hzSetRows(this.hzSetTab);
         switch(code)
         {
            case "up":
               if(this.hzSetFocus == 1)
               {
                  this.hzSetPage = this.hz51PageClamp(this.hzSetTab);
                  this.hzSetPage = (this.hzSetPage + this.hz51Pages(this.hzSetTab).length - 1) % this.hz51Pages(this.hzSetTab).length;
                  this.hzSetRow = 0; this.hzSetScroll = 0;
               }
               else { this.hz30RowStep(rows,-1); }
               break;
            case "down":
               if(this.hzSetFocus == 1)
               {
                  this.hzSetPage = (this.hz51PageClamp(this.hzSetTab) + 1) % this.hz51Pages(this.hzSetTab).length;
                  this.hzSetRow = 0; this.hzSetScroll = 0;
               }
               else { this.hz30RowStep(rows,1); }
               break;
            case "left":
               if(this.hzSetFocus == 0)
               {
                  var lr:Object = rows[this.hzSetRow];
                  if(lr != null && (lr.t == "n" || lr.t == "z" || lr.t == "b")) { this.hzSetChange(lr,-1); }
                  else { this.hzSetFocus = 1; }
               }
               break;
            case "right":
               if(this.hzSetFocus == 1) { this.hzSetFocus = 0; }
               else
               {
                  var rr2:Object = rows[this.hzSetRow];
                  if(rr2 != null && (rr2.t == "n" || rr2.t == "z" || rr2.t == "b")) { this.hzSetChange(rr2,1); }
                  else { this.hz51OpenDrop(this.hzSetRow, rows); }
               }
               break;
            case "tabprev": this.hzSetTab = (this.hzSetTab + HZ_SET_TABS.length - 1) % HZ_SET_TABS.length; this.hzSetPage = 0; this.hzSetRow = 0; this.hzSetScroll = 0; this.hzSetDrop = -1; break;
            case "tabnext": this.hzSetTab = (this.hzSetTab + 1) % HZ_SET_TABS.length; this.hzSetPage = 0; this.hzSetRow = 0; this.hzSetScroll = 0; this.hzSetDrop = -1; break;`,
	"keys"
);
once(
	`            case "ok":
               if(this.hzSetRow >= 0 && this.hzSetRow < rows.length && rows[this.hzSetRow] != null && rows[this.hzSetRow].t == "x")
               {
                  var xk:String = String(rows[this.hzSetRow].k);
                  if(xk == "_msglog" || xk == "_arrange")
                  {
                     this.hzSetChange(rows[this.hzSetRow],1);
                     this.hzSetDraw();
                     return;
                  }
                  return;
               }
               this.hzSetApply();
               return;`,
	`            case "ok":
               if(this.hzSetRow >= 0 && this.hzSetRow < rows.length && rows[this.hzSetRow] != null && rows[this.hzSetRow].t == "x")
               {
                  var xk:String = String(rows[this.hzSetRow].k);
                  if(xk == "_msglog" || xk == "_arrange")
                  {
                     this.hzSetChange(rows[this.hzSetRow],1);
                     this.hzSetDraw();
                     return;
                  }
                  return;
               }
               this.hzSetApply();
               return;`,
	"ok key"
);
once(
	`            if(r.k == "_arrange") { this.hzArrEnter(); return; }
            if(r.k == "_msglog") { this.hzMsglogOpen(); return; }
            if(r.k == "_hz41arrscan") { this.hz41SAEnter(); return; }   // v0.41.0: ARRANGE SCANNER`,
	`            if(r.k == "_arrange") { this.hzArrEnter(); return; }
            if(r.k == "_msglog") { this.hzMsglogOpen(); return; }
            if(r.k == "_qmclear") { this.hz37Act(r,dir); return; }
            if(r.k == "_mlfolder") { try { this.hzMsglogOpenSettings(); } catch(eFold:Error) { } return; }
            if(r.k == "_mlold") { try { this.hzMsglogOpenSettings(); } catch(eOld:Error) { } return; }
            if(r.goT != undefined) { this.hz51Jump(int(r.goT), int(r.goP), String(r.goK)); return; }
            if(r.k == "_hz41arrscan") { this.hz41SAEnter(); return; }   // v0.41.0: ARRANGE SCANNER`,
	"change x"
);
once(
	`            else if(r.k == "_hz42scrst") { this.hzSetPend.ScopeChipX = 0; this.hzSetPend.ScopeChipY = 0; this.hzSetPend.ScopeChipScale = 1; }   // v0.42.0 r2
            else if(r.k == "_hz40rstlay") { this.hz40Reset(true); }
            else if(r.k == "_hz40rstall") { this.hz40Reset(false); }`,
	`            else if(r.k == "_hz42scrst" || r.k == "_hz40rstlay" || r.k == "_hz40rstall") { this.hz37Act(r,dir); return; }`,
	"rst confirm"
);
once(
	`         else if(k == "_hz37bak") { this.hz37Send("restore",k); }
      }`,
	`         else if(k == "_hz37bak") { this.hz37Send("restore",k); }
         else if(k == "_hz40rstlay") { this.hz40Reset(true); }
         else if(k == "_hz40rstall") { this.hz40Reset(false); }
         else if(k == "_hz42scrst") { this.hzSetPend.ScopeChipX = 0; this.hzSetPend.ScopeChipY = 0; this.hzSetPend.ScopeChipScale = 1; }
         else if(k == "_qmclear") { this.hz51QmClear(); }
      }`,
	"hz37 act"
);
once(
	`            if(r != null && rk == this.hz37Cf && (code == "ok" || code == "right" || code == "left")) { this.hz37Act(r,1); return true; }`,
	`            if(r != null && rk == this.hz37Cf && (code == "ok" || code == "right" || code == "left"))
            {
               if(rk.indexOf("_hz37") == 0) { this.hz37Act(r,1); return true; }
               return false;
            }`,
	"hz37 key"
);
once(
	`         var k:String = ri >= 0 && ri < rows.length ? String(rows[ri].k) : "";
         if(k != this.hz37Cf && id.indexOf("inf") != 0) { this.hz37Cf = ""; }`,
	`         var k:String = ri >= 0 && ri < rows.length ? String(rows[ri].k) : "";
         if(id == "qmclr") { k = "_qmclear"; }
         if(k != this.hz37Cf && id.indexOf("inf") != 0) { this.hz37Cf = ""; }`,
	"hz37 press"
);
once(
	`            if(k == "_hz37save") { return "'" + this.hz37Trim(String(this.hz37Edit)) + "' already exists. Press again (or ENTER) to overwrite - ESC cancels"; }
         }`,
	`            if(k == "_hz37save") { return "'" + this.hz37Trim(String(this.hz37Edit)) + "' already exists. Press again (or ENTER) to overwrite - ESC cancels"; }
            if(k == "_hz40rstlay") { return "Puts scanner panel spots, sizes, and compact forms back to their defaults. Press the button again to confirm. Enter does not run this reset."; }
            if(k == "_hz40rstall") { return "Puts every scanner setting back to its default. Press the button again to confirm. Enter does not run this reset."; }
            if(k == "_hz42scrst") { return "Puts the hold-breath chip back at the game's spot and size. Press the button again to confirm. Enter does not run this reset."; }
            if(k == "_qmclear") { return "Clears every extra-slot key. Press Clear all keys again to confirm. Enter does not clear keys."; }
         }`,
	"hz37 note"
);
once(
	`            if(id == "ok") { this.hzSetApply(); return; }
            if(id == "cancel") { this.hzSetCancel(); return; }
            if(id == "arrange") { this.hzArrEnter(); return; }
            if(id == "page0" || id == "page1")`,
	`            if(id == "ok") { this.hzSetApply(); return; }
            if(id == "cancel") { this.hzSetCancel(); return; }
            if(id == "arrange") { this.hzArrEnter(); return; }
            if(id == "arrscan") { this.hz41SAEnter(); return; }
            if(id == "compact") { this.hzSetPend.Compact = !Boolean(this.hzSetPend.Compact); this.hzSetLive(this.hzSetPend); dirty = true; }
            else if(id == "findbox") { this.hzSetFindOn = true; this.hzSetFocus = 2; dirty = true; }
            else if(id.indexOf("side") == 0) { this.hzSetPage = int(id.substr(4)); this.hzSetRow = 0; this.hzSetScroll = 0; this.hzSetFocus = 0; this.hzSetDrop = -1; dirty = true; }
            else if(id.indexOf("fhit") == 0) { var fh:Array = this.hz51FindHits(); var fi:int = int(id.substr(4)); if(fi >= 0 && fi < fh.length) { this.hz51GotoHit(fh[fi]); dirty = true; } }
            else if(id.indexOf("dopt") == 0) { this.hz51DropPick(rows[this.hzSetDrop], int(id.substr(4))); this.hzSetDrop = -1; this.hzSetFocus = 0; dirty = true; }
            else if(id.indexOf("dd") == 0) { this.hzSetRow = int(id.substr(2)); this.hz51OpenDrop(this.hzSetRow, rows); dirty = true; }
            else if(id.indexOf("hex") == 0)
            {
               var hi:int = int(id.substr(3));
               this.hzSetRow = hi;
               var hr:Object = rows[hi];
               if(hr != null && !hr.dis)
               {
                  this.hzSetHexK = String(hr.hex);
                  var curH:String = String(this.hzSetPend[this.hzSetHexK] != undefined ? this.hzSetPend[this.hzSetHexK] : "");
                  this.hzSetHexPrev = this.hzParseHex(curH);
                  this.hzSetHexBuf = curH.indexOf("#") == 0 ? curH.substr(1) : curH;
                  this.hzSetFocus = 4;
               }
               dirty = true;
            }
            else if(id.indexOf("qmk") == 0) { this.hzQmCapBegin("QuickMenuKey" + id.substr(3)); dirty = true; }
            else if(id == "qmclr") { this.hz37Act({"k":"_qmclear","t":"x"},1); dirty = true; }
            else if(id == "page0" || id == "page1")`,
	"mouse"
);
once(
	`            else if(id.indexOf("tab") == 0) { this.hzSetTab = int(id.substr(3)); this.hzSetRow = 0; this.hzSetScroll = 0; dirty = true; }`,
	`            else if(id.indexOf("tab") == 0) { this.hzSetTab = int(id.substr(3)); this.hzSetPage = 0; this.hzSetRow = 0; this.hzSetScroll = 0; this.hzSetDrop = -1; dirty = true; }`,
	"tab mouse"
);
once(
	`               if(rr.t == "b" || rr.t == "a" || rr.t == "c" || rr.t == "k" || rr.t == "r" || rr.t == "q" || rr.t == "x" || rr.t == "m" || rr.t == "p" || rr.t == "g") { this.hzSetChange(rr,1); if(this.hzArrange) { return; } }
               else if(rr.t == "z" && !rr.dis) { this.hz34ZToggle(String(rr.k)); }`,
	`               if(rr.t == "r" || rr.t == "q" || rr.t == "l" || rr.t == "a" || rr.t == "c" || rr.t == "p") { this.hz51OpenDrop(ri, rows); }
               else if(rr.t == "b" || rr.t == "k" || rr.t == "x" || rr.t == "m" || rr.t == "g" || rr.t == "md") { this.hzSetChange(rr,1); if(this.hzArrange) { return; } }
               else if(rr.t == "z" && !rr.dis) { this.hz34ZToggle(String(rr.k)); }`,
	"row click"
);
replaceFn("      private function hzSetRowH(r:Object) : Number", `      private function hzSetRowH(r:Object) : Number
      {
         if(r.t == "m") { return (r.h ? HZ51_SEC : 0) + this.hz34BanH(); }
         if(r.t == "g") { return 48; }
         if(r.t == "w") { return (r.h ? HZ51_SEC : 0) + 44; }
         if(r.t == "kg")
         {
            return (r.h ? HZ51_SEC : 0) + this.hz51QmGridH(r.dis);
         }
         return (r.h ? HZ51_SEC : 0) + HZ51_ROW;
      }
`, "rowh");
once(
	`         var prev:Boolean = this.hzSetTab == 1 || this.hzSetTab == 2;
         var right:Number = HZ_SET_W - 28 - (prev ? 250 : 0);`,
	`         var right:Number = HZ_SET_W - HZ51_PREV_W - HZ51_SIDE_W;`,
	"notew"
);
text = text.split("         var avail:Number = HZ_SET_H - 64 - HZ_SET_TOP;").join("         var avail:Number = HZ_SET_H - HZ51_FOOT - HZ_SET_TOP - 64;");
once(
	'"WatchStyle":0,"CrosshairRule":0};',
	'"WatchStyle":0,"CrosshairRule":0,"CharacterShowSeconds":8,"Debug":0,"PerfDiag":0,"PerfMode":0,"PerfDump":0};',
	"def"
);

fs.writeFileSync(HUD, text, "utf8");
console.log("patched", HUD, "chars", text.length);
