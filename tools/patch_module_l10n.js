// Purpose: one-shot insert of module-movie l10n receivers (hzc/hzd/hzs SetL10n)
// and wrap Horizon-owned chrome through *Lt. Idempotent. Does not splice twins.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const ROOT = path.join(__dirname, "..");

function rd(rel) {
	return fs.readFileSync(path.join(ROOT, rel), "utf8").replace(/\r\n/g, "\n");
}
function wr(rel, s) {
	const p = path.join(ROOT, rel);
	let prev = "";
	try { prev = fs.readFileSync(p, "utf8"); } catch (e) {}
	if (prev.indexOf("\r\n") >= 0) s = s.replace(/\n/g, "\r\n");
	fs.writeFileSync(p, s);
}

function helper(p, extraAfter, pfxLiteral) {
	return [
		"      private var " + p + "L10n:Object = null;",
		"      private var " + p + "L10nC:Object = null;   // English chrome -> translated; filled at SetL10n / first lookup",
		"      // Purpose: cache the HUD localization snapshot on this movie. One Invoke",
		"      // per movie load / language reload. No file I/O. Lookups run at card /",
		"      // panel / speaker build, never on the fade tick.",
		"      // Author: Moragar. Last modified: 2026-11-27.",
		"      public function " + p + "SetL10n(s:String) : void",
		"      {",
		"         try",
		"         {",
		"            if(s == null) { return; }",
		"            var lines:Array = String(s).split(\"\\n\");",
		"            if(lines.length == 0 || String(lines[0]).indexOf(\"#l10n1\") != 0) { return; }",
		"            var tab:Object = {};",
		"            var i:int = 1;",
		"            while(i < lines.length)",
		"            {",
		"               var ln:String = String(lines[i]);",
		"               if(ln.length > 0 && ln.charAt(ln.length - 1) == \"\\r\") { ln = ln.substr(0, ln.length - 1); }",
		"               var tabAt:int = ln.indexOf(\"\\t\");",
		"               if(tabAt > 0)",
		"               {",
		"                  var k:String = ln.substr(0, tabAt);",
		"                  var v:String = this." + p + "L10nUnesc(ln.substr(tabAt + 1));",
		"                  if(k != \"g\" && k != \"gn\" && k != \"files\" && k != \"o\" && k != \"used\") { tab[k] = v; }",
		"               }",
		"               i++;",
		"            }",
		"            this." + p + "L10n = tab;",
		"            this." + p + "L10nC = {};",
		extraAfter,
		"         }",
		"         catch(err:Error) { }",
		"      }",
		"      private function " + p + "L10nUnesc(s:String) : String",
		"      {",
		"         if(s == null) { return \"\"; }",
		"         var o:String = \"\";",
		"         var i:int = 0;",
		"         while(i < s.length)",
		"         {",
		"            var c:String = s.charAt(i);",
		"            if(c == \"\\\\\" && i + 1 < s.length)",
		"            {",
		"               var n:String = s.charAt(i + 1);",
		"               if(n == \"n\") { o += \"\\n\"; i += 2; continue; }",
		"               if(n == \"r\") { o += \"\\r\"; i += 2; continue; }",
		"               if(n == \"t\") { o += \"\\t\"; i += 2; continue; }",
		"               if(n == \"\\\\\") { o += \"\\\\\"; i += 2; continue; }",
		"               o += n; i += 2; continue;",
		"            }",
		"            o += c; i++;",
		"         }",
		"         return o;",
		"      }",
		"      private function " + p + "L(key:String, fb:String) : String",
		"      {",
		"         if(this." + p + "L10n != null)",
		"         {",
		"            var v:* = this." + p + "L10n[key];",
		"            if(v != null)",
		"            {",
		"               var s:String = String(v);",
		"               if(s.length > 0) { return s; }",
		"            }",
		"         }",
		"         return fb != null ? fb : key;",
		"      }",
		"      private function " + p + "HasCjk(s:String) : Boolean",
		"      {",
		"         if(s == null) { return false; }",
		"         var i:int = 0;",
		"         while(i < s.length)",
		"         {",
		"            var c:int = s.charCodeAt(i);",
		"            if(c >= 0x2E80 && c <= 0x9FFF) { return true; }",
		"            if(c >= 0xAC00 && c <= 0xD7AF) { return true; }",
		"            if(c >= 0xF900 && c <= 0xFAFF) { return true; }",
		"            if(c >= 0xFF00 && c <= 0xFFEF) { return true; }",
		"            i++;",
		"         }",
		"         return false;",
		"      }",
		"      private function " + p + "LSlug(s:String) : String",
		"      {",
		"         if(s == null) { return \"\"; }",
		"         var o:String = \"\";",
		"         var i:int = 0;",
		"         var prevUs:Boolean = false;",
		"         while(i < s.length && o.length < 48)",
		"         {",
		"            var code:int = s.charCodeAt(i);",
		"            var ok:Boolean = (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);",
		"            if(ok)",
		"            {",
		"               o += s.charAt(i).toLowerCase();",
		"               prevUs = false;",
		"            }",
		"            else if(o.length > 0 && !prevUs)",
		"            {",
		"               o += \"_\";",
		"               prevUs = true;",
		"            }",
		"            i++;",
		"         }",
		"         if(o.length > 0 && o.charAt(o.length - 1) == \"_\") { o = o.substr(0, o.length - 1); }",
		"         return o;",
		"      }",
		"      private function " + p + "Lt(en:String) : String",
		"      {",
		"         if(en == null || en.length == 0) { return en; }",
		"         if(this." + p + "L10nC != null)",
		"         {",
		"            var cached:* = this." + p + "L10nC[en];",
		"            if(cached != null) { return String(cached); }",
		"         }",
		"         var slug:String = this." + p + "LSlug(en);",
		"         var out:String = en;",
		"         if(slug.length > 0)",
		"         {",
		"            var pfx:Array = " + pfxLiteral + ";",
		"            var i:int = 0;",
		"            while(i < pfx.length)",
		"            {",
		"               var v:String = this." + p + "L(String(pfx[i]) + slug, \"\");",
		"               if(v.length > 0) { out = v; break; }",
		"               i++;",
		"            }",
		"         }",
		"         if(this." + p + "L10nC == null) { this." + p + "L10nC = {}; }",
		"         this." + p + "L10nC[en] = out;",
		"         return out;",
		"      }"
	].join("\n");
}

function insertAfter(src, mark, block, already) {
	if (src.indexOf(already) >= 0) return src;
	const i = src.indexOf(mark);
	if (i < 0) throw new Error("insert mark missing: " + mark.slice(0, 60));
	const at = i + mark.length;
	return src.slice(0, at) + "\n" + block + src.slice(at);
}

function once(src, a, b) {
	if (src.indexOf(b) >= 0 && a.indexOf(b) < 0) return src;
	if (src.indexOf(a) < 0) return src;
	return src.split(a).join(b);
}

const hzcExtra = [
	"            if(this.hzcSpk != null && this.hzcSpk.visible)",
	"            {",
	"               try { this.hzcDrawSpeaker(this.hzcWho); } catch(eSpk:Error) { }",
	"            }"
].join("\n");

const hzdExtra = [
	"            if(this.hzdOn && this.hzdOpen)",
	"            {",
	"               try { this.hzdDraw(); } catch(eDr:Error) { }",
	"            }",
	"            else",
	"            {",
	"               try { this.hzdDrawSpeaker(); } catch(eSp:Error) { }",
	"            }"
].join("\n");

const hzsExtra = [
	"            this.hzsMNC = {};",
	"            this.hzsMNUnk = null;",
	"            this.hzsMNVeh = null;",
	"            this.hzsDirty = true;",
	"            if(this.hzsReady)",
	"            {",
	"               try { this.hzsDrawAll(false); } catch(eDr:Error) { }",
	"            }"
].join("\n");

let hzc = rd("actionscript/comms/hzc_block.as");
hzc = insertAfter(
	hzc,
	"      private var hzcFontOk:Object = {};",
	helper("hzc", hzcExtra, '["comms.hud_label.","comms.help.","dlg.hud_label.","settings.ui.","hud.hud_label.","hud."]'),
	"function hzcSetL10n"
);
hzc = once(hzc, 'this.hzcSet(this.hzcSpkSub,"SPEAKING",', 'this.hzcSet(this.hzcSpkSub,this.hzcLt("SPEAKING"),');
hzc = once(hzc, 'this.hzcSet(hd,String(HZC_TST_HEAD[st]),', 'this.hzcSet(hd,this.hzcLt(String(HZC_TST_HEAD[st])),');
hzc = once(hzc, 'this.hzcLogPush("location","LOCATION",nm);', 'this.hzcLogPush("location",this.hzcLt("LOCATION"),nm);');
hzc = once(
	hzc,
	'if(lv > 1) { this.hzcLogPush("xp","LEVEL UP","Level up! You are now level " + lv + "."); }',
	'if(lv > 1) { this.hzcLogPush("xp",this.hzcLt("LEVEL UP"),this.hzcLt("Level up! You are now level {n}.").split("{n}").join(String(lv))); }'
);
hzc = once(
	hzc,
	'var rlb:String = String(HZC_RX_LBL[k]) + (int(e.cnt) > 1 ? "  x" + int(e.cnt) : "");   // r6: xN',
	'var rlb:String = this.hzcLt(String(HZC_RX_LBL[k])) + (int(e.cnt) > 1 ? "  x" + int(e.cnt) : "");   // r6: xN'
);
hzc = once(
	hzc,
	'this.hzcSet(lb,String(HZC_RX_LBL[e.k]) + (int(e.cnt) > 1 ? "  x" + int(e.cnt) : ""),"nm",fs,col,Math.round(fs * 0.12 * 10) / 10,"left");   // r6: xN',
	'this.hzcSet(lb,this.hzcLt(String(HZC_RX_LBL[e.k])) + (int(e.cnt) > 1 ? "  x" + int(e.cnt) : ""),"nm",fs,col,Math.round(fs * 0.12 * 10) / 10,"left");   // r6: xN'
);
hzc = once(hzc, 'return String(HZC_GAME_TITLES[i]);', 'return this.hzcLt(String(HZC_GAME_TITLES[i]));');

const phraseMap = [
	['if(sub == "gained") { return "Gained"; }', 'if(sub == "gained") { return this.hzcLt("Gained"); }'],
	['if(sub == "worse") { return "Became worse"; }', 'if(sub == "worse") { return this.hzcLt("Became worse"); }'],
	['if(sub == "improved") { return "Prognosis improved"; }', 'if(sub == "improved") { return this.hzcLt("Prognosis improved"); }'],
	['if(sub == "severity") { return "Severity improved"; }', 'if(sub == "severity") { return this.hzcLt("Severity improved"); }'],
	['if(sub == "attempted") { return "Attempted to cure"; }', 'if(sub == "attempted") { return this.hzcLt("Attempted to cure"); }'],
	['if(sub == "cured") { return "Cured"; }', 'if(sub == "cured") { return this.hzcLt("Cured"); }'],
	['if(sub == "follow") { return "Is now following you."; }', 'if(sub == "follow") { return this.hzcLt("Is now following you."); }'],
	['if(sub == "unfollow") { return "Is no longer following you."; }', 'if(sub == "unfollow") { return this.hzcLt("Is no longer following you."); }'],
	['if(sub == "follow-available") { return "Is available to be your follower."; }', 'if(sub == "follow-available") { return this.hzcLt("Is available to be your follower."); }'],
	['if(sub == "follow-unavailable") { return "Is no longer available to be your follower."; }', 'if(sub == "follow-unavailable") { return this.hzcLt("Is no longer available to be your follower."); }'],
	['if(sub == "companion") { return "Is now your Active Companion."; }', 'if(sub == "companion") { return this.hzcLt("Is now your Active Companion."); }'],
	['if(sub == "uncompanion") { return "Is no longer your Active Companion."; }', 'if(sub == "uncompanion") { return this.hzcLt("Is no longer your Active Companion."); }'],
	['if(sub == "companion-available") { return "Is available to be your Companion."; }', 'if(sub == "companion-available") { return this.hzcLt("Is available to be your Companion."); }'],
	['if(sub == "companion-unavailable") { return "Is no longer available to be your companion."; }', 'if(sub == "companion-unavailable") { return this.hzcLt("Is no longer available to be your companion."); }'],
	['if(sub == "crew") { return "Is now an Active Crew Member."; }', 'if(sub == "crew") { return this.hzcLt("Is now an Active Crew Member."); }'],
	['if(sub == "uncrew") { return "Is no longer an Active Crew Member."; }', 'if(sub == "uncrew") { return this.hzcLt("Is no longer an Active Crew Member."); }'],
	['if(sub == "crew-available") { return "Is available for your Crew."; }', 'if(sub == "crew-available") { return this.hzcLt("Is available for your Crew."); }'],
	['if(sub == "crew-unavailable") { return "Is no longer available for your Crew."; }', 'if(sub == "crew-unavailable") { return this.hzcLt("Is no longer available for your Crew."); }'],
	['if(sub == "friend") { return "Considers you a friend."; }', 'if(sub == "friend") { return this.hzcLt("Considers you a friend."); }'],
	['if(sub == "ally") { return "Considers you an ally."; }', 'if(sub == "ally") { return this.hzcLt("Considers you an ally."); }'],
	['if(sub == "partner") { return "Considers you a committed partner."; }', 'if(sub == "partner") { return this.hzcLt("Considers you a committed partner."); }'],
	['if(sub == "angry") { return "Is angry with you."; }', 'if(sub == "angry") { return this.hzcLt("Is angry with you."); }'],
	['if(sub == "calm") { return "Is no longer angry with you."; }', 'if(sub == "calm") { return this.hzcLt("Is no longer angry with you."); }'],
	['if(sub == "furious") { return "Is furious with you and will no longer be your companion."; }', 'if(sub == "furious") { return this.hzcLt("Is furious with you and will no longer be your companion."); }']
];
for (const [a, b] of phraseMap) hzc = once(hzc, a, b);

const titleMap = [
	['if(sub == "kid") { return "KID STUFF"; }', 'if(sub == "kid") { return this.hzcLt("KID STUFF"); }'],
	['if(sub == "bounty") { return "BOUNTY PAID"; }', 'if(sub == "bounty") { return this.hzcLt("BOUNTY PAID"); }'],
	['return "CREDITS";', 'return this.hzcLt("CREDITS");'],
	['if(sub == "takeback" || sub == "lock") { return "CAUGHT"; }', 'if(sub == "takeback" || sub == "lock") { return this.hzcLt("CAUGHT"); }'],
	['if(sub == "caught") { return "PICKPOCKET"; }', 'if(sub == "caught") { return this.hzcLt("PICKPOCKET"); }'],
	['if(sub == "alarm") { return "ALARM"; }', 'if(sub == "alarm") { return this.hzcLt("ALARM"); }'],
	['if(sub == "trespass") { return "TRESPASS"; }', 'if(sub == "trespass") { return this.hzcLt("TRESPASS"); }'],
	['if(sub == "witness") { return "WITNESS"; }', 'if(sub == "witness") { return this.hzcLt("WITNESS"); }'],
	['if(sub == "bounty-add") { return "BOUNTY"; }', 'if(sub == "bounty-add") { return this.hzcLt("BOUNTY"); }'],
	['return "CRIME";', 'return this.hzcLt("CRIME");'],
	['if(kind == "medical") { return "AFFLICTION"; }', 'if(kind == "medical") { return this.hzcLt("AFFLICTION"); }'],
	['if(kind == "crew") { return "CREW"; }', 'if(kind == "crew") { return this.hzcLt("CREW"); }'],
	['if(sub == "busy") { return "BUSY"; }', 'if(sub == "busy") { return this.hzcLt("BUSY"); }'],
	['if(sub == "calmed") { return "CALMED"; }', 'if(sub == "calmed") { return this.hzcLt("CALMED"); }'],
	['if(kind == "game") { return n.length > 0 ? n.toUpperCase() : "GAME"; }', 'if(kind == "game") { return n.length > 0 ? n.toUpperCase() : this.hzcLt("GAME"); }'],
	['return "NOTICE";', 'return this.hzcLt("NOTICE");']
];
for (const [a, b] of titleMap) hzc = once(hzc, a, b);
wr("actionscript/comms/hzc_block.as", hzc);

let hzd = rd("actionscript/comms/hzd_block.as");
hzd = insertAfter(
	hzd,
	"      private var hzdBare:Boolean = false;   // DlgCard=0 while drawing",
	helper("hzd", hzdExtra, '["dlg.hud_label.","comms.hud_label.","settings.ui.","hud.hud_label.","hud."]'),
	"function hzdSetL10n"
);
hzd = once(hzd, 'return w.length > 0 ? w.toUpperCase() : "RESPOND";', 'return w.length > 0 ? w.toUpperCase() : this.hzdLt("RESPOND");');
hzd = once(
	hzd,
	'var cntTf:TextField = this.hzdText(p,String(this.hzdSel + 1) + " OF " + String(this.hzdView.length),"",14 * ts,mut,Math.round(14 * ts * 0.12),W - pad - 14,hy,0,"right",false);',
	'var cntTf:TextField = this.hzdText(p,String(this.hzdSel + 1) + " " + this.hzdLt("OF") + " " + String(this.hzdView.length),"",14 * ts,mut,Math.round(14 * ts * 0.12),W - pad - 14,hy,0,"right",false);'
);
hzd = once(
	hzd,
	'var ttlTf:TextField = this.hzdText(p,this.hzdPers ? "PERSUADE" : this.hzdTitle(this.hzdWho),"",(cmp ? 13 : 14) * ts,acc,Math.round(14 * ts * 0.22),pad + 14,hy,0,"left",false);',
	'var ttlTf:TextField = this.hzdText(p,this.hzdPers ? this.hzdLt("PERSUADE") : this.hzdTitle(this.hzdWho),"",(cmp ? 13 : 14) * ts,acc,Math.round(14 * ts * 0.22),pad + 14,hy,0,"left",false);'
);
hzd = once(
	hzd,
	'var at:TextField = this.hzdText(p,String(this.hzdTop) + " ABOVE","",14 * ts,mut,Math.round(14 * ts * 0.18),W / 2 + 11,y + 2,0,"center",false);',
	'var at:TextField = this.hzdText(p,String(this.hzdTop) + " " + this.hzdLt("ABOVE"),"",14 * ts,mut,Math.round(14 * ts * 0.18),W / 2 + 11,y + 2,0,"center",false);'
);
hzd = once(hzd, 'chipW = this.hzdChip(r,"PERSUADE",', 'chipW = this.hzdChip(r,this.hzdLt("PERSUADE"),');
hzd = once(hzd, 'chipW += this.hzdChip(r,"SAID",', 'chipW += this.hzdChip(r,this.hzdLt("SAID"),');
hzd = once(
	hzd,
	'var mt:TextField = this.hzdText(p,String(left) + " MORE","",14 * ts,mut,Math.round(14 * ts * 0.18),W / 2 + 11,y + 8,0,"center",false);',
	'var mt:TextField = this.hzdText(p,String(left) + " " + this.hzdLt("MORE"),"",14 * ts,mut,Math.round(14 * ts * 0.18),W / 2 + 11,y + 8,0,"center",false);'
);
hzd = once(hzd, 'this.hzdText(p,"QUICK PICK","",14 * ts,mut,Math.round(14 * ts * 0.12),pad + 14 + fw + 10,y + 3,0,"left",false);', 'this.hzdText(p,this.hzdLt("QUICK PICK"),"",14 * ts,mut,Math.round(14 * ts * 0.12),pad + 14 + fw + 10,y + 3,0,"left",false);');
hzd = once(hzd, 'this.hzdText(s,"SPEAKING","",14 * ts,0x8FA3AE,Math.round(14 * ts * 0.14),90 * ts,50 * ts,0,"left",false);', 'this.hzdText(s,this.hzdLt("SPEAKING"),"",14 * ts,0x8FA3AE,Math.round(14 * ts * 0.14),90 * ts,50 * ts,0,"left",false);');
hzd = once(hzd, 'right.push(this.hzdPill(b,"select",this.hzdAcceptKey,"SELECT",acc,txt,false,null,-1,z));', 'right.push(this.hzdPill(b,"select",this.hzdAcceptKey,this.hzdLt("SELECT"),acc,txt,false,null,-1,z));');
hzd = once(hzd, 'quick = this.hzdPill(b,"quick","1-9","QUICK PICK",mut,mut,false,null,-1,z);', 'quick = this.hzdPill(b,"quick","1-9",this.hzdLt("QUICK PICK"),mut,mut,false,null,-1,z);');
hzd = once(hzd, 'var titleStr:String = "PERSUASION";', 'var titleStr:String = this.hzdLt("PERSUASION");');
hzd = once(hzd, 'if(o.won) { titleStr = "PERSUADED"; titleCol = col; mark = 1; }', 'if(o.won) { titleStr = this.hzdLt("PERSUADED"); titleCol = col; mark = 1; }');
hzd = once(hzd, 'else if(o.failed) { titleStr = "FAILED"; titleCol = col; mark = 2; }', 'else if(o.failed) { titleStr = this.hzdLt("FAILED"); titleCol = col; mark = 2; }');
hzd = once(hzd, 'turnsTxt = "TURNS " + (ti < 10 ? "0" + String(ti) : String(ti));', 'turnsTxt = this.hzdLt("TURNS") + " " + (ti < 10 ? "0" + String(ti) : String(ti));');
wr("actionscript/comms/hzd_block.as", hzd);

let hzs = rd("actionscript/scanner/hzs_block.as");
hzs = insertAfter(
	hzs,
	"      private var hzsTrC:Object = {};         // 0.43.3.2: \"$KEY\" -> translated text (one TextField per key per scanner open)",
	helper("hzs", hzsExtra, '["scan.hud_label.","scan.help.","hud.hud_label.","settings.ui.","hud."]'),
	"function hzsSetL10n"
);
const oldCs = `      private function hzsCs(s:String) : String
      {
         if(!this.hzsTitle()) { return s.toUpperCase(); }
         var w:Array = s.toLowerCase().split(" ");
         var i:int = 0;
         while(i < w.length) { var x:String = String(w[i]); if(x.length > 0 && !/^(of|and|in|at|to)$/.test(x)) { w[i] = x.charAt(0).toUpperCase() + x.substr(1); } i++; }
         return w.join(" ");
      }`;
const newCs = `      private function hzsCs(s:String) : String
      {
         // Unit letters stay native. Longer Horizon chrome is looked up once
         // (hzsLt memo) then cased. Game names use hzsGs / hzsTr, not this.
         var loc:String = (s == null || s.length < 2) ? String(s) : this.hzsLt(s);
         if(this.hzsHasCjk(loc)) { return loc; }
         if(!this.hzsTitle()) { return loc.toUpperCase(); }
         var w:Array = loc.toLowerCase().split(" ");
         var i:int = 0;
         while(i < w.length) { var x:String = String(w[i]); if(x.length > 0 && !/^(of|and|in|at|to)$/.test(x)) { w[i] = x.charAt(0).toUpperCase() + x.substr(1); } i++; }
         return w.join(" ");
      }`;
if (hzs.indexOf("var loc:String = (s == null || s.length < 2)") < 0) {
	if (hzs.indexOf("private function hzsCs(s:String) : String") < 0) throw new Error("hzsCs missing");
	hzs = hzs.replace(oldCs, newCs);
	if (hzs.indexOf("var loc:String = (s == null || s.length < 2)") < 0) {
		hzs = hzs.replace(
			/private function hzsCs\(s:String\) : String\s*\{[\s\S]*?return w\.join\(" "\);\s*\}/,
			newCs.trim()
		);
	}
}
hzs = once(hzs, '"sub":"Landing zone"', '"sub":this.hzsCs("Landing zone")');
hzs = once(hzs, '"sub":"Vehicle"', '"sub":this.hzsCs("Vehicle")');
hzs = once(hzs, '"sub":named ? "Companion" : "Follower"', '"sub":named ? this.hzsCs("Companion") : this.hzsCs("Follower")');
hzs = once(
	hzs,
	'var msub:String = hl ? this.hzsCs("NEAREST UNDISCOVERED") : (own == "other" ? "Companion ship" : (disc ? "Discovered" : "Undiscovered"));',
	'var msub:String = hl ? this.hzsCs("NEAREST UNDISCOVERED") : (own == "other" ? this.hzsCs("Companion ship") : (disc ? this.hzsCs("Discovered") : this.hzsCs("Undiscovered")));'
);
wr("actionscript/scanner/hzs_block.as", hzs);

let hud = rd("actionscript/horizon_block.as");
hud = once(
	hud,
	`            if(String(HZ_ML_KIND[i]) == k) { return String(HZ_ML_CHIPS[i]); }
            i++;
         }
         return "GAME";`,
	`            if(String(HZ_ML_KIND[i]) == k) { return this.hzLt(String(HZ_ML_CHIPS[i])); }
            i++;
         }
         return this.hzLt("GAME");`
);
hud = once(hud, 'if(this.hzMlStatus == "memory" || this.hzMlStatus == "paused") { return "History not saved"; }', 'if(this.hzMlStatus == "memory" || this.hzMlStatus == "paused") { return this.hzLt("History not saved"); }');
hud = once(hud, 'if(this.hzMlStatus == "saving") { return "Saving"; }', 'if(this.hzMlStatus == "saving") { return this.hzLt("Saving"); }');
hud = once(hud, 'if(this.hzMlStatus == "fallback") { return "Character key fallback"; }', 'if(this.hzMlStatus == "fallback") { return this.hzLt("Character key fallback"); }');
hud = once(hud, 'list.push({"g":1,"lab":"PINNED " + String(this.hzMlPinN) + " / " + String(this.hzMlPinCap)});', 'list.push({"g":1,"lab":this.hzLt("PINNED {n} / {cap}").split("{n}").join(String(this.hzMlPinN)).split("{cap}").join(String(this.hzMlPinCap))});');
hud = once(hud, 'if(int(e.sess) == this.hzMlSess) { return today ? "Today · this session" : "This session"; }', 'if(int(e.sess) == this.hzMlSess) { return today ? this.hzLt("Today · this session") : this.hzLt("This session"); }');
hud = once(hud, 'return today ? "Today · earlier" : "Earlier";', 'return today ? this.hzLt("Today · earlier") : this.hzLt("Earlier");');
hud = once(hud, 'if(sec < 60) { return "just now"; }', 'if(sec < 60) { return this.hzLt("just now"); }');
hud = once(hud, 'if(sec < 3600) { return String(Math.floor(sec / 60)) + " min ago"; }', 'if(sec < 3600) { return String(Math.floor(sec / 60)) + this.hzLt(" min ago"); }');
hud = once(hud, 'if(sec < 86400) { return String(Math.floor(sec / 3600)) + " h ago"; }', 'if(sec < 86400) { return String(Math.floor(sec / 3600)) + this.hzLt(" h ago"); }');
hud = once(hud, 'return String(Math.floor(sec / 86400)) + " d ago";', 'return String(Math.floor(sec / 86400)) + this.hzLt(" d ago");');
hud = once(hud, 'this.hzWT(b,"HORIZON UI · MESSAGE LOG",ox + 22,oy + 14,520,15,"bd",uint(T.txt),2, "left", 13);', 'this.hzWT(b,this.hzLt("HORIZON UI · MESSAGE LOG"),ox + 22,oy + 14,520,15,"bd",uint(T.txt),2, "left", 13);');
hud = once(hud, 'var findLab:String = this.hzMlFind.length > 0 ? this.hzMlFind : "Find...";', 'var findLab:String = this.hzMlFind.length > 0 ? this.hzMlFind : this.hzL("settings.ui.find_ellipsis", "Find...");');
hud = once(hud, 'if(this.hzMlPad && !this.hzMlFindOn && this.hzMlFind.length == 0) { findLab = "Find (keyboard only)"; }', 'if(this.hzMlPad && !this.hzMlFindOn && this.hzMlFind.length == 0) { findLab = this.hzLt("Find (keyboard only)"); }');
hud = once(hud, 'var atf:TextField = this.hzWT(b,"ALL TIME",0,fy + 8,220,13,"sb",uint(T.lab),1.2,"left",13);', 'var atf:TextField = this.hzWT(b,this.hzLt("ALL TIME"),0,fy + 8,220,13,"sb",uint(T.lab),1.2,"left",13);');
hud = once(hud, 'var empty:String = this.hzMlRows.length > 0 ? "No messages for the types that are shown. Stored messages stay." : "Starts empty. Messages from before this log was on cannot be recovered.";', 'var empty:String = this.hzMlRows.length > 0 ? this.hzLt("No messages for the types that are shown. Stored messages stay.") : this.hzLt("Starts empty. Messages from before this log was on cannot be recovered.");');
hud = once(hud, 'var chipLab:String = later ? "from a later point" : (String(it.tag).length > 0 ? String(it.tag) : this.hzMsglogKindLab(String(it.k)));', 'var chipLab:String = later ? this.hzLt("from a later point") : (String(it.tag).length > 0 ? String(it.tag) : this.hzMsglogKindLab(String(it.k)));');
hud = once(hud, 'var when:String = uts.length > 0 ? "IN-GAME " + uts : "";', 'var when:String = uts.length > 0 ? this.hzLt("IN-GAME") + " " + uts : "";');
hud = once(hud, 'if(lts.length > 0) { when += (when.length > 0 ? " + " : "") + "local " + lts; }', 'if(lts.length > 0) { when += (when.length > 0 ? " + " : "") + this.hzLt("local") + " " + lts; }');
hud = once(hud, 'if(sel.later == true) { d2 += (d2.length > 0 ? "  ·  " : "") + "from a later point"; }', 'if(sel.later == true) { d2 += (d2.length > 0 ? "  ·  " : "") + this.hzLt("from a later point"); }');
hud = once(hud, 'var pinLab:String = (sel != null && int(sel.pin) != 0) ? "UNPIN" : "PIN";', 'var pinLab:String = (sel != null && int(sel.pin) != 0) ? this.hzLt("UNPIN") : this.hzLt("PIN");');
hud = once(
	hud,
	`         var hints:Array = this.hzMlPad
            ? [["LB/RB","CHIPS"],["A",pinLab],["X","SETTINGS"],["Y","CLEAR"],["B","BACK"]]
            : [["UP/DN","SELECT"],["ENTER",pinLab],["ESC","BACK"],["/","FIND"]];`,
	`         var hints:Array = this.hzMlPad
            ? [["LB/RB",this.hzLt("CHIPS")],["A",pinLab],["X",this.hzLt("SETTINGS")],["Y",this.hzLt("CLEAR")],["B",this.hzLt("BACK")]]
            : [["UP/DN",this.hzLt("SELECT")],["ENTER",pinLab],["ESC",this.hzLt("BACK")],["/",this.hzLt("FIND")]];`
);
hud = once(hud, 'bxr -= this.hzSetBtn(b,g,bxr,by,"BACK",false,false,this.hzMlHover == "back",T,"mlback",13,13) + 10;', 'bxr -= this.hzSetBtn(b,g,bxr,by,this.hzLt("BACK"),false,false,this.hzMlHover == "back",T,"mlback",13,13) + 10;');
hud = once(hud, 'bxr -= this.hzSetBtn(b,g,bxr,by,"CLEAR SESSION",false,true,this.hzMlHover == "clear",T,"mlclear",13,13) + 10;', 'bxr -= this.hzSetBtn(b,g,bxr,by,this.hzLt("CLEAR SESSION"),false,true,this.hzMlHover == "clear",T,"mlclear",13,13) + 10;');
hud = once(hud, 'var setW:Number = this.hzSetBtn(b,g,bxr,by,"SETTINGS",false,true,this.hzMlHover == "set",T,"mlset",13,13);', 'var setW:Number = this.hzSetBtn(b,g,bxr,by,this.hzLt("SETTINGS"),false,true,this.hzMlHover == "set",T,"mlset",13,13);');
hud = once(hud, 'var title:TextField = this.hzWT(b,"Clear this session?",0,0,noteW,15,"bd",uint(T.txt),2,"left",13);', 'var title:TextField = this.hzWT(b,this.hzLt("Clear this session?"),0,0,noteW,15,"bd",uint(T.txt),2,"left",13);');
hud = once(hud, 'var note:TextField = this.hzWT(b,"Removes " + String(n) + " shown unpinned messages. Hidden messages stay. Can\'t be undone.",0,0,noteW,13,"rg",uint(T.lab),0.3,"left",13);', 'var note:TextField = this.hzWT(b,this.hzLt("Removes {n} shown unpinned messages. Hidden messages stay. Can\'t be undone.").split("{n}").join(String(n)),0,0,noteW,13,"rg",uint(T.lab),0.3,"left",13);');
hud = once(hud, 'br -= this.hzSetBtn(b,g,br,btnY,"CANCEL",false,false,this.hzMlHover == "cfcancel",T,"cfcancel",13,13) + 10;', 'br -= this.hzSetBtn(b,g,br,btnY,this.hzLt("CANCEL"),false,false,this.hzMlHover == "cfcancel",T,"cfcancel",13,13) + 10;');
hud = once(hud, 'this.hzSetBtn(b,g,br,btnY,"CLEAR",true,false,this.hzMlHover == "cfok",T,"cfok",13,13);', 'this.hzSetBtn(b,g,br,btnY,this.hzLt("CLEAR"),true,false,this.hzMlHover == "cfok",T,"cfok",13,13);');
hud = once(
	hud,
	`         var rows:Array = [
            {"id":"record","k":"record","l":"RECORD MESSAGES"},
            {"id":"persist","k":"persist","l":"SAVE TO DISK"}
         ];
         if(!this.hzMlPersist) { rows.push({"id":"folder","k":"folder","l":"FOLDER"}); }
         rows.push({"id":"history","k":"history","l":"HISTORY"});
         rows.push({"id":"viewnote","k":"viewnote","l":"SHOW hides rows in this log. RECORD chooses what is saved."});`,
	`         var rows:Array = [
            {"id":"record","k":"record","l":this.hzLt("RECORD MESSAGES")},
            {"id":"persist","k":"persist","l":this.hzLt("SAVE TO DISK")}
         ];
         if(!this.hzMlPersist) { rows.push({"id":"folder","k":"folder","l":this.hzLt("FOLDER")}); }
         rows.push({"id":"history","k":"history","l":this.hzLt("HISTORY")});
         rows.push({"id":"viewnote","k":"viewnote","l":this.hzLt("SHOW hides rows in this log. RECORD chooses what is saved.")});`
);
hud = once(hud, 'rows.push({"id":"type" + String(i),"k":String(HZ_ML_KIND[i]),"l":String(HZ_ML_CHIPS[i]),"type":1});', 'rows.push({"id":"type" + String(i),"k":String(HZ_ML_KIND[i]),"l":this.hzLt(String(HZ_ML_CHIPS[i])),"type":1});');
hud = once(hud, 'rows.push({"id":"old","k":"old","l":"OLD CHARACTERS"});', 'rows.push({"id":"old","k":"old","l":this.hzLt("OLD CHARACTERS")});');
hud = once(hud, 'this.hzWT(b,"MESSAGE LOG SETTINGS",cx + 22,cy + 16,cw - 44,15,"bd",uint(T.txt),2,"left",13);', 'this.hzWT(b,this.hzLt("MESSAGE LOG SETTINGS"),cx + 22,cy + 16,cw - 44,15,"bd",uint(T.txt),2,"left",13);');
hud = once(hud, 'this.hzWT(b,"Memory only. Existing files stay on disk.",cx + 22,ry + 2,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);', 'this.hzWT(b,this.hzLt("Memory only. Existing files stay on disk."),cx + 22,ry + 2,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);');
hud = once(hud, 'this.hzWT(b,"OLD CHARACTERS (" + String(this.hzMlOtherN) + " FILES)",cx + 22,ry + 8,320,13,"sb",uint(T.txt),1.2,"left",13);', 'this.hzWT(b,this.hzLt("OLD CHARACTERS ({n} FILES)").split("{n}").join(String(this.hzMlOtherN)),cx + 22,ry + 8,320,13,"sb",uint(T.txt),1.2,"left",13);');
hud = once(hud, 'this.hzSetBtn(b,g,cx + cw - 18,ry + 4,"VIEW LIST",false,true,this.hzMlHover == "mlslist",T,"mlslist",13,13);', 'this.hzSetBtn(b,g,cx + cw - 18,ry + 4,this.hzLt("VIEW LIST"),false,true,this.hzMlHover == "mlslist",T,"mlslist",13,13);');
hud = once(hud, 'var recTf:TextField = this.hzWT(b,"RECORD",cx + cw - 168,ry + 8,70,13,"sb",uint(T.lab),0.4,"left",13);', 'var recTf:TextField = this.hzWT(b,this.hzLt("RECORD"),cx + cw - 168,ry + 8,70,13,"sb",uint(T.lab),0.4,"left",13);');
hud = once(hud, 'var showTf:TextField = this.hzWT(b,"SHOW",0,ry + 8,80,13,"sb",uint(T.lab),0.4,"left",13);', 'var showTf:TextField = this.hzWT(b,this.hzLt("SHOW"),0,ry + 8,80,13,"sb",uint(T.lab),0.4,"left",13);');
hud = once(hud, 'this.hzWT(b,"TOGGLE",hx + 30,hy + 4,70,13,"sb",uint(T.mut),1.2,"left",13);', 'this.hzWT(b,this.hzLt("TOGGLE"),hx + 30,hy + 4,70,13,"sb",uint(T.mut),1.2,"left",13);');
hud = once(hud, 'br -= this.hzSetBtn(b,g,br,foot + 20,"BACK",false,false,this.hzMlHover == "mlsback",T,"mlsback",13,13) + 10;', 'br -= this.hzSetBtn(b,g,br,foot + 20,this.hzLt("BACK"),false,false,this.hzMlHover == "mlsback",T,"mlsback",13,13) + 10;');
hud = once(hud, 'this.hzSetBtn(b,g,br,foot + 20,"CLEAR HISTORY",false,true,this.hzMlHover == "mlsclear",T,"mlsclear",13,13);', 'this.hzSetBtn(b,g,br,foot + 20,this.hzLt("CLEAR HISTORY"),false,true,this.hzMlHover == "mlsclear",T,"mlsclear",13,13);');
hud = once(hud, 'var title:TextField = this.hzWT(b,"Clear all history?",0,0,noteW,15,"bd",uint(T.txt),2,"left",13);', 'var title:TextField = this.hzWT(b,this.hzLt("Clear all history?"),0,0,noteW,15,"bd",uint(T.txt),2,"left",13);');
hud = once(hud, 'var note:TextField = this.hzWT(b,"Removes every unpinned message for this character. Pins stay. Can\'t be undone.",0,0,noteW,13,"rg",uint(T.lab),0.3,"left",13);', 'var note:TextField = this.hzWT(b,this.hzLt("Removes every unpinned message for this character. Pins stay. Can\'t be undone."),0,0,noteW,13,"rg",uint(T.lab),0.3,"left",13);');
hud = once(hud, 'br -= this.hzSetBtn(b,g,br,btnY,"CANCEL",false,false,this.hzMlHover == "mhcancel",T,"mhcancel",13,13) + 10;', 'br -= this.hzSetBtn(b,g,br,btnY,this.hzLt("CANCEL"),false,false,this.hzMlHover == "mhcancel",T,"mhcancel",13,13) + 10;');
hud = once(hud, 'this.hzSetBtn(b,g,br,btnY,"CLEAR",true,false,this.hzMlHover == "mhok",T,"mhok",13,13);', 'this.hzSetBtn(b,g,br,btnY,this.hzLt("CLEAR"),true,false,this.hzMlHover == "mhok",T,"mhok",13,13);');
hud = once(hud, 'this.hzWT(b,"OLD CHARACTERS",cx + 22,cy + 16,cw - 44,15,"bd",uint(T.txt),2,"left",13);', 'this.hzWT(b,this.hzLt("OLD CHARACTERS"),cx + 22,cy + 16,cw - 44,15,"bd",uint(T.txt),2,"left",13);');
hud = once(hud, 'this.hzWT(b,"Read-only. The current character is not listed.",cx + 22,cy + 40,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);', 'this.hzWT(b,this.hzLt("Read-only. The current character is not listed."),cx + 22,cy + 40,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);');
hud = once(hud, 'this.hzWT(b,"No other character files.",cx + 22,ry,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);', 'this.hzWT(b,this.hzLt("No other character files."),cx + 22,ry,cw - 44,13,"rg",uint(T.mut),0.3,"left",13);');
hud = once(hud, 'this.hzWT(b,String(oc.n) + " messages",cx + cw - 22,ry,160,13,"rg",uint(T.mut),0.3,"right",13);', 'this.hzWT(b,String(oc.n) + " " + this.hzLt("messages"),cx + cw - 22,ry,160,13,"rg",uint(T.mut),0.3,"right",13);');
hud = once(hud, 'this.hzSetBtn(b,g,cx + cw - 22,cy + ch - 44,"BACK",false,false,this.hzMlHover == "mlcback",T,"mlcback",13,13);', 'this.hzSetBtn(b,g,cx + cw - 22,cy + ch - 44,this.hzLt("BACK"),false,false,this.hzMlHover == "mlcback",T,"mlcback",13,13);');
wr("actionscript/horizon_block.as", hud);

console.log("patched hzc/hzd/hzs/hud module l10n");
