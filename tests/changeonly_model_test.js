// Change-only fix (commit after 8e5e702): proves the new hzQSync (change-only signature + hzTxtTop replay), the indexed
// hzTxtObj, the hzApplyFmt format epoch, and the catch(e:*) pass wrappers give the same results as the 8e5e702 bodies.
// The 8e5e702 bodies are frozen below (REF_8E5E702). Both sides run the production AS from horizon_block.as for every
// other function, on identical models, through randomized sequences: quest add / complete / target change, marker
// distance moves, sub-line changes, card rebuilds, a new movie, F11 typography applies, format guards, card scale
// changes, late fonts, writes by other code, watch styles 1-4, and throws of Error and non-Error values.
// Run: node tests/changeonly_model_test.js
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

const REF_8E5E702 = `      private function hzQSync() : void
      {
         var tQs:Number = 0;
         if(this.hzPerfOn) { tQs = this.hzPerfNow(); this.hzRgPush(4,tQs,0); }
         var name:String = this.hzQName != null ? this.hzQName : "";
         var obj:String = this.hzQObjStr != null ? this.hzQObjStr : "";
         var title:String = name.length > 0 ? name : (obj.length > 0 ? obj : "No active objective");
         var sub:String = name.length > 0 ? obj : "";
         var dist:String = this.hzQDistStr != null ? this.hzQDistStr : "";
         if(this.hzQ19T)
         {
            this.hzQ19D.text = dist;
            this.hzQ19D.visible = dist.length > 0;
            var tw:Number = HZ_Q19_W - 74 - 14 - (dist.length > 0 ? this.hzTW(this.hzQ19D) + 12 : 0);
            this.hzFitText(this.hzQ19T,this.hzUC(title),tw);
            this.hzQ19O.visible = sub.length > 0;
            if(sub.length > 0 || this.hz27QSubs.length > 0)
            {
               this.hzFitText(this.hzQ19O,sub,HZ_Q19_W - 74 - 14);
               this.hzTxtTop(this.hzQ19T,10);
               this.hzTxtTop(this.hzQ19D,11);
            }
            else
            {
               this.hzTxtTop(this.hzQ19T,28);
               this.hzTxtTop(this.hzQ19D,29);
            }
            try { this.hz27QLayout(sub.length > 0); } catch(errQL:Error) { }
         }
         if(this.hzCQ19T)
         {
            this.hzCQ19D.text = dist;
            this.hzCQ19D.visible = dist.length > 0;
            var right:Number = HZ_CQ19_W - 14 - (dist.length > 0 ? this.hzTW(this.hzCQ19D) + 12 : 0);
            this.hzFitText(this.hzCQ19T,this.hzUC(title),Math.min(200,right - 32));
            var ox:Number = 32 + this.hzTW(this.hzCQ19T) + 6;
            this.hzCQ19O.visible = sub.length > 0 && right - ox > 40;
            if(this.hzCQ19O.visible)
            {
               this.hzCQ19O.x = ox;
               this.hzFitText(this.hzCQ19O,"\u00b7  " + sub,right - ox);
            }
         }
         if(this.hzPerfOn) { this.hzPsSpan(46,tQs,false); }
      }

      private function hzTxtObj(tf:TextField) : Object
      {
         for each(var o:Object in this.hzTexts) { if(o.tf == tf) { return o; } }
         return null;
      }

      private function hzApplyFmt(o:Object) : void
      {
         if(this.hzPerfOn) { this.hzPcFmt++; }
         if(o.tone != undefined && o.tone !== null) { this.hzApplyFmt19(o); return; }
         var role:String = o.role;
         var ts:Number = Math.max(0.8,Math.min(1.3,this.hzTextScale));
         var base:Number = (role != null && HZ_TY_SIZE[role] != undefined) ? Number(HZ_TY_SIZE[role]) : Number(o.size);
         var sz:int = int(Math.round(base * ts));
         var col:uint = uint(o.col);
         var al:Number = 1;
         if(role != null)
         {
            var lt:Boolean = this.hzDarkText();
            if(!o.keep)
            {
               if(role == "hdr") { col = this.hzTextAccent(); }
               else if(role == "val" || role == "valS" || role == "big") { col = lt ? 0x0E151B : HZ_TY_WHITE; }
               else { col = lt ? 0x1C262E : HZ_TY_MUTED; }
            }
            else if(col == HZ_ACCENT) { col = this.hzTextAccent(); }
            // Mute by color, not alpha: alpha-muted text inherits the card fade and loses contrast (worst on light cards).
            var ra:Number = Number(HZ_TY_ALPHA[role]);
            if(ra < 1) { col = this.hzMix(col,this.hzPanelFill(),(1 - ra) * (lt ? 0.75 : 1)); }
            al = 1;
         }
         if(o.tint != undefined && o.tint !== null) { col = uint(o.tint); }
         var f:TextFormat = new TextFormat(this.hzFontName(),sz,col);
         if(o.right) { f.align = "right"; }
         if(o.center) { f.align = "center"; }
         f.letterSpacing = (o.ls != undefined && o.ls !== null) ? Number(o.ls) : ((role == "hdr" && this.hzHeaderStyle == 0) ? 1.6 : (role == "lbl" ? 0.6 : 0));
         var tf:TextField = TextField(o.tf);
         var keepTxt:String = (role == "hdr" && o.raw != null) ? this.hzHdrCase(String(o.raw)) : tf.text;
         // Scaleform keeps the color of existing glyph runs; clear, set format, re-set text, then color.
         tf.filters = [];
         tf.text = "";
         tf.defaultTextFormat = f;
         tf.text = keepTxt;
         tf.setTextFormat(f);
         tf.textColor = col;
         o.cc = col;
         tf.alpha = al;
         var nl:int = (o.lines != undefined && int(o.lines) > 1) ? int(o.lines) : 1;
         tf.height = (sz + 4) * nl + 6;
         // grow/shrink around the original vertical center so rows stay aligned
         if(o.y0 != undefined && o.y0 != null) { tf.y = Number(o.y0) - (sz - base) / 2; }
         tf.filters = this.hzTyFilters();
         o.sh = this.hzTextShadow;   // v0.36: applied shadow state (hzTypoGuard)
      }

      private function hz43VanBlgChrome(hide:Boolean) : void
      {
         if(!this.hzBlg) { return; }
         this.hz43OlBegin();
         try
         {
            var i:int = 0;
            while(i < this.hzBlg.numChildren)
            {
               var d:DisplayObject = this.hzBlg.getChildAt(i);
               var n:String = d ? d.name : "";
               var capArt:Boolean = this.hz43VanCapClip(d);
               var ringArt:Boolean = this.hz43VanRingClip(d);
               var mark:Boolean = this.hz43VanMarkName(n);
               var named:Boolean = this.hz43VanNamed(n);
               if(!d || this.hz43VanSkip(n)) { }
               else if(hide)
               {
                  if(!mark && (named || capArt || ringArt) && !this.hz43VanHoldsMark(d as DisplayObjectContainer)) { this.hz43StHide(d); }
               }
               else if(mark || named || capArt || ringArt)
               {
                  this.hz43VanShowClip(d);
               }
               i++;
            }
         }
         catch(eOl:Error)
         {
            this.hz43OlEnd();
            throw eOl;
         }
         this.hz43OlEnd();
      }

      private function hz43VanChrome(hide:Boolean) : void
      {
         if(!hide) { this.hz43VanRestoreHid(); this.hz43VanBlgChrome(false); return; }
         this.hz43OlBegin();
         try
         {
            var i:int = 0;
            while(i < HZ43_VAN_N.length)
            {
               var name:String = String(HZ43_VAN_N[i]);
               var mark:Boolean = this.hz43VanMarkName(name);
               var clip:DisplayObject = this.hzFindByName(this.hzBlg,name,0);
               if(clip)
               {
                  var box:DisplayObjectContainer = clip as DisplayObjectContainer;
                  var keep:Boolean = mark || (box != null && this.hz43VanHoldsMark(box));
                  if(hide && mark)
                  {
                     if(!clip.visible) { clip.visible = true; }
                     var up:DisplayObjectContainer = clip.parent;
                     while(up != null && up != this)
                     {
                        if(!up.visible) { up.visible = true; }
                        if(up == this.hzBlg) { break; }
                        up = up.parent;
                     }
                     var sib:DisplayObjectContainer = clip.parent;
                     if(sib != null && sib != this.hzBlg && sib != this)
                     {
                        var si:int = 0;
                        while(si < sib.numChildren)
                        {
                           var sc:DisplayObject = sib.getChildAt(si);
                           var scMark:Boolean = sc && (this.hz43VanMarkName(sc.name) || (sc is DisplayObjectContainer && this.hz43VanHoldsMark(DisplayObjectContainer(sc))));
                           if(sc && !scMark)
                           {
                              this.hz43StHide(sc);
                           }
                           si++;
                        }
                     }
                  }
                  else if(hide && box != null && keep && !mark)
                  {
                     if(!clip.visible) { clip.visible = true; }
                     var ci:int = 0;
                     while(ci < box.numChildren)
                     {
                        var ch:DisplayObject = box.getChildAt(ci);
                        var chMark:Boolean = ch && (this.hz43VanMarkName(ch.name) || (ch is DisplayObjectContainer && this.hz43VanHoldsMark(DisplayObjectContainer(ch))));
                        if(ch && !chMark)
                        {
                           this.hz43StHide(ch);
                        }
                        else if(ch)
                        {
                           if(!ch.visible) { ch.visible = true; }
                        }
                        ci++;
                     }
                  }
                  else if(hide && !keep)
                  {
                     this.hz43StHide(clip);
                  }
               }
               i++;
            }
            this.hz43VanBlgChrome(hide);
         }
         catch(eOc:Error)
         {
            this.hz43OlEnd();
            throw eOc;
         }
         this.hz43OlEnd();
      }
`;

function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) i = src.indexOf("public function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(i, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
// AS3 to JS for the bodies used here. Typed catches keep AS3 semantics: catch(e:Error) lets a non-Error value pass.
function toJs(body) {
	return body
		.replace(/for each\s*\(\s*var\s+(\w+)\s*:\s*[\w.*]+\s+in\s+/g, "for (var $1 of ")
		.replace(/(\w+) is DisplayObjectContainer\b/g, "__isDoc($1)")
		.replace(/\bDisplayObjectContainer\(/g, "(")
		.replace(/(?<!new )\bTextField\(/g, "(")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*\*\s*\)/g, "catch($1)")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.]+\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim());
}
function bind(host, src, name) {
	const f = fnText(src, name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}
function constOf(name) {
	const m = as.match(new RegExp("static const " + name + ":(?:int|Number) = ([\\d.]+);"));
	if (!m) throw new Error("const " + name);
	return Number(m[1]);
}
function rng(seed) { let s = seed >>> 0; return function() { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
function pick(r, a) { return a[Math.floor(r() * a.length)]; }

// ---- TextField / TextFormat model ----
// Flash semantics that matter here: assigning text gives the new text the defaultTextFormat; setTextFormat formats
// the current text; textWidth depends on the applied font and size (not on letterSpacing, so hzLsMode resolves to 0).
const COST = { writes: 0, widths: 0 };
function TextFormat(font, size, color) { this.font = font; this.size = size; this.color = color; this.letterSpacing = 0; this.align = "left"; }
function cloneFmt(f) { const c = new TextFormat(f.font, f.size, f.color); c.letterSpacing = f.letterSpacing; c.align = f.align; return c; }
const FONT_W = {};
function fontW(font) {
	if (FONT_W[font] == null) { let h = 7; for (const ch of String(font)) h = (h * 31 + ch.charCodeAt(0)) % 1000; FONT_W[font] = 0.48 + h / 4000; }
	return FONT_W[font];
}
let tfUid = 0;
function TextField() {
	this._id = ++tfUid; this._text = ""; this._def = new TextFormat("$MAIN_Font", 12, 0xffffff); this._fmt = cloneFmt(this._def);
	this.visible = true; this.x = 0; this.y = 0; this.width = 100; this.height = 20; this.alpha = 1; this.filters = []; this.textColor = 0xffffff;
}
Object.defineProperty(TextField.prototype, "text", {
	get: function() { return this._text; },
	set: function(v) { COST.writes++; this._text = v == null ? "" : String(v); this._fmt = cloneFmt(this._def); }
});
Object.defineProperty(TextField.prototype, "defaultTextFormat", {
	get: function() { return cloneFmt(this._def); },
	set: function(f) { this._def = cloneFmt(f); }
});
Object.defineProperty(TextField.prototype, "textWidth", {
	get: function() {
		COST.widths++;
		let w = 0;
		for (const ch of this._text) w += (ch === " " ? 0.3 : (ch >= "A" && ch <= "Z" ? 0.72 : 0.55)) * Number(this._fmt.size) * fontW(this._fmt.font) * 2;
		return Math.round(w * 100) / 100;
	}
});
TextField.prototype.setTextFormat = function(f) { this._fmt = cloneFmt(f); };
TextField.prototype.getTextFormat = function() { return cloneFmt(this._fmt); };
Object.defineProperty(TextField.prototype, "length", { get: function() { return this._text.length; } });

// ---- hosts ----
const QFUNCS = ["hzTxtObj", "hzFitText", "hzTW", "hzUC", "hzTxtTop", "hz27QLayout", "hzFontName", "hzApplyFmt", "hzApplyFmt19", "hzTextSz19",
	"hzVitTextSz", "hzChipSz", "hzChipSzOn", "hzHdrCase", "hzHdr19", "hzSetSz", "hzT", "hz27QBuild", "hzQSync"];
const QNEW_ONLY = ["hzQsSame", "hzQsKeep", "hzQsTops", "hzQsField"];
const QCHANGED = ["hzTxtObj", "hzApplyFmt", "hzQSync"];

function makeQHost(kind, env) {
	const h = {
		int: function(n) { return Number(n) | 0; }, uint: function(n) { return Number(n) >>> 0; }, trace: function() {},
		TextField: TextField, TextFormat: TextFormat,
		HZ_Q19_W: constOf("HZ_Q19_W"), HZ_CQ19_W: constOf("HZ_CQ19_W"), HZ_QS_N: 12, HZ_QS_W: 9, HZ_SCALE: 1,
		HZ_TY_SIZE: { hdr: 10, val: 16, valS: 14, lbl: 9, sec: 12, big: 24 }, HZ_TY_ALPHA: { hdr: 0.85, val: 1, valS: 1, lbl: 0.6, sec: 0.78, big: 1 },
		HZ34_SEMI: "$Semi_Face",
		hzPerfOn: true, hzPerfN: null, hzPcFmt: 0, hzPcQsSkip: 0, hzPcQsRun: 0, hzPcTxHit: 0, hzPcTxMiss: 0,
		hzTexts: [], hzTextTf: [], hzSz: [], hzLsMode: -1, hzFont: "$MAIN_Font", hzFontFace: 1, hz30Mod: { font: 1 }, hzFontOk: 0,
		hzFontOkMap: {}, hzAfRemeasure: false, hzAfRemeasureAt: 0, hzFrameN: 1, hzTextScale: 1, hzHeaderStyle: 0, hzTextShadow: false,
		hz30Hover: 1, hz30TgSc: 0, hzLaidOut: true, hzDark: false,
		hzQName: "", hzQObjStr: "", hzQDistStr: "", hz27QSubs: [], hz27QL: [], hz27QLD: [], hz27QH: 78,
		hzQ19T: null, hzQ19D: null, hzQ19O: null, hzCQ19T: null, hzCQ19D: null, hzCQ19O: null, HorizonQuest_mc: { _mc: 1 },
		hzQsOk: false, hzQsR: null, hzQsName: null, hzQsObj: null, hzQsDist: null, hzQsSubN: -1, hzQsSubD: null, hzQsSubT: null, hzQsSubO: null,
		hzQsHdr: -1, hzQsTs: NaN, hzQsFace: -1, hzQsFont: null, hzQsFMod: null, hzQsLs: -2, hzQsQL: null, hzQsQLD: null, hzQsQLN: -1, hzQsH: NaN, hzQsMc: null,
		qDraw: 0, probes: [],
		hzPerfNow: function() { return 0; }, hzRgPush: function() {}, hzPsSpan: function() {},
		hzDarkText: function() { return h.hzDark; }, hzTextAccent: function() { return 0x7fd0ff; }, hzIconCol: function(c) { return c >>> 0; },
		hzMix: function(a) { return a; }, hzPanelFill: function() { return 0; }, hzTyFilters: function() { return []; }, hzTy19Filters: function() { return []; },
		hzQDraw19: function() { h.qDraw++; },
		hz34S: function(card) { return env.cardScale; }, hz34Eff: function(v) { return v; },
		hzFontProbe: function(n) {
			if (h.hzFontOkMap[n] != undefined) return h.hzFontOkMap[n] == 1;
			h.probes.push(n);
			const ok = env.fontsReady && n.indexOf("$Horizon_") === 0;
			h.hzFontOkMap[n] = ok ? 1 : 0;
			if (ok) { h.hzAfRemeasure = true; if (h.hzAfRemeasureAt == 0) h.hzAfRemeasureAt = Math.max(1, h.hzFrameN); }
			return ok;
		}
	};
	for (const f of QFUNCS) bind(h, kind === "old" && QCHANGED.indexOf(f) >= 0 ? REF_8E5E702 : as, f);
	if (kind === "new") for (const f of QNEW_ONLY) bind(h, as, f);
	return h;
}
const SPRITE = { addChild: function() {} };
// Card build, as hzBuildQuest19 / hz27QBuild make the fields (same calls and arguments).
function buildCard(h) {
	h.hzQ19T = h.hzT(SPRITE, "", 74, 10, h.HZ_Q19_W - 74 - 14 - 84, 15, "sb", "main", 2, "left", 0xffffff);
	h.hzHdr19(h.hzQ19T);
	h.hzQ19D = h.hzT(SPRITE, "", h.HZ_Q19_W - 14 - 84, 11, 84, 14, "sb", "acc", 1, "right", 0xffffff);
	h.hzQ19O = h.hzT(SPRITE, "", 74, 37, h.HZ_Q19_W - 74 - 14, 13, "rg", "mut", 0, "left", 0xffffff);
	h.hzCQ19T = h.hzT(SPRITE, "", 32, 9, 200, 12, "sb", "main", 1.6, "left", 0xffffff);
	h.hzHdr19(h.hzCQ19T);
	h.hzCQ19O = h.hzT(SPRITE, "", 120, 9, 200, 12, "rg", "mut", 0, "left", 0xffffff);
	h.hzCQ19D = h.hzT(SPRITE, "", h.HZ_CQ19_W - 14 - 80, 9, 80, 12, "sb", "acc", 0.8, "right", 0xffffff);
	h.hz27QBuild(SPRITE);
}
// Unrelated registered texts before and after the card, so the registry looks like the HUD's (texts=204).
function filler(h, n, tag) { for (let i = 0; i < n; i++) h.hzT(SPRITE, tag + i, 0, 0, 80, 12, "sb", "mut", 0, "left", 0xffffff); }

function fmtSnap(f) { return f.font + "/" + f.size + "/" + f.color + "/" + f.letterSpacing + "/" + f.align; }
function tfSnap(t) {
	if (!t) return "null";
	return [JSON.stringify(t._text), t.visible ? 1 : 0, t.x, t.y, t.width, t.height, t.alpha, t.textColor, fmtSnap(t._fmt), fmtSnap(t._def), t.filters.length].join(",");
}
function qSnap(h) {
	const out = [];
	const fields = [h.hzQ19T, h.hzQ19D, h.hzQ19O, h.hzCQ19T, h.hzCQ19D, h.hzCQ19O].concat(h.hz27QL.slice(0, 3), h.hz27QLD.slice(0, 3));
	fields.forEach((t, i) => out.push("f" + i + "=" + tfSnap(t)));
	h.hzTexts.forEach((o, i) => {
		out.push("o" + i + "=" + tfSnap(o.tf) + ";y0=" + o.y0 + ";su=" + o.su + ";cc=" + o.cc + ";sh=" + o.sh + ";hdr19=" + o.hdr19);
	});
	out.push("sz=" + JSON.stringify(h.hzSz.map((e) => [e.w, e.h])) + " qh=" + h.hz27QH + " draw=" + h.qDraw + " laid=" + h.hzLaidOut);
	out.push("fontOk=" + h.hzFontOk + " remeasure=" + h.hzAfRemeasure + "@" + h.hzAfRemeasureAt + " ls=" + h.hzLsMode + " probes=" + h.probes.join("|"));
	return out.join("\n");
}
function firstDiff(a, b) {
	const x = a.split("\n"), y = b.split("\n");
	for (let i = 0; i < Math.max(x.length, y.length); i++) if (x[i] !== y[i]) return (x[i] || "<none>") + "  vs  " + (y[i] || "<none>");
	return "";
}

// ---- quest inputs (the same values go to both hosts) ----
const NAMES = ["", "Into the Unknown", "One Small Step", "The Old Neighborhood: A Very Long Quest Title That Must Be Cut", "Back to Vectera", "UNITY"];
const OBJS = ["", "Talk to Sarah Morgan", "Travel to the Lodge in New Atlantis and speak with everyone present", "Find the artifact", "Optional: Loot the cave"];
const STEPS = ["Go to the Eye", "Speak to Walter Stroud about the sponsorship he offered", "Collect 3 samples", "Return to the Lodge", "Investigate the signal"];
function distStr(r) { const d = r(); return d < 0.15 ? "" : (d < 0.6 ? String(Math.floor(r() * 990) + 10) + " M" : (Math.floor(r() * 99) / 10 + 0.1).toFixed(1) + " KM"); }
// hz27QSubs entries are pooled objects changed in place (hz27QPool): model that too.
function setSubs(h, pool, n, vals) {
	h.hz27QSubs.length = 0;
	for (let i = 0; i < n; i++) { const p = pool[i]; p.t = vals[i].t; p.d = vals[i].d; p.opt = vals[i].opt; h.hz27QSubs.push(p); }
}
function newPool() { return [0, 1, 2, 3].map(() => ({ t: "", opt: false, d: "", src: "", m: 0, off: false, has: false })); }

function qWorld(seed) {
	const env = { cardScale: 1, fontsReady: false };
	const hosts = { old: makeQHost("old", env), neu: makeQHost("new", env) };
	const pools = { old: newPool(), neu: newPool() };
	for (const k of ["old", "neu"]) { filler(hosts[k], 90, "pre"); buildCard(hosts[k]); filler(hosts[k], 100, "post"); }
	return { env, hosts, pools, r: rng(seed) };
}
function both(w, fn) { fn(w.hosts.old, w.pools.old, "old"); fn(w.hosts.neu, w.pools.neu, "neu"); }

// One random event, applied identically to both hosts. Returns its kind.
function qEvent(w, step, allowRebuild) {
	const r = w.r;
	const k = r();
	if (k < 0.30) {
		// marker distance move (most compass frames): only the distance text changes, or nothing changes at all
		const d = r() < 0.5 ? distStr(r) : null;
		if (d != null) both(w, (h) => { h.hzQDistStr = d; });
		return d != null ? "distance" : "steady";
	}
	if (k < 0.42) { return "steady"; }
	if (k < 0.50) {
		// quest target / objective change
		const o = pick(r, OBJS);
		both(w, (h) => { h.hzQObjStr = o; });
		return "target";
	}
	if (k < 0.57) {
		// quest add or title change (hzSetQuestTitle)
		const n = pick(r, NAMES);
		both(w, (h) => { h.hzQName = n; });
		return "quest";
	}
	if (k < 0.65) {
		// sub-lines: steps added, completed, distance per step, optional flag (pooled objects changed in place)
		const n = Math.floor(r() * 4.6);
		const vals = [];
		for (let i = 0; i < n; i++) vals.push({ t: pick(r, STEPS), d: r() < 0.5 ? distStr(r) : "", opt: r() < 0.25 });
		both(w, (h, pool) => setSubs(h, pool, n, vals));
		return "subs";
	}
	if (k < 0.68) {
		// quest complete: title, objective and steps clear
		both(w, (h) => { h.hzQName = ""; h.hzQObjStr = ""; h.hzQDistStr = ""; h.hz27QSubs.length = 0; });
		return "complete";
	}
	if (k < 0.72) {
		// F11 typography apply: settings change, then every registered text is re-formatted (hzApplyTypo)
		const ts = pick(r, [0.8, 0.9, 1, 1.1, 1.3]);
		const hs = r() < 0.5 ? 0 : 1;
		const ff = pick(r, [0, 1, 2, 3]);
		both(w, (h) => { h.hzTextScale = ts; h.hzHeaderStyle = hs; h.hzFontFace = ff; for (const o of h.hzTexts) h.hzApplyFmt(o); });
		return "f11";
	}
	if (k < 0.75) {
		// F11 setting changed but not applied yet (no re-format): the card must still follow (HeaderStyle case, TextScale)
		const hs = r() < 0.5 ? 0 : 1;
		const ts = pick(r, [0.8, 1, 1.2]);
		both(w, (h) => { h.hzHeaderStyle = hs; h.hzTextScale = ts; });
		return "f11-pending";
	}
	if (k < 0.79) {
		// typography guard: one random card field re-formatted (color drop / shadow change)
		const j = Math.floor(r() * 12);
		both(w, (h) => { const t = fieldAt(h, j); const o = t ? h.hzTxtObj(t) : null; if (o) h.hzApplyFmt(o); });
		return "guard";
	}
	if (k < 0.85) {
		// other code writes a card field (visibility pass, a fade, an Arrange drag, a text write)
		const j = Math.floor(r() * 12);
		const what = Math.floor(r() * 4);
		const val = r();
		both(w, (h) => {
			const t = fieldAt(h, j);
			if (!t) return;
			if (what === 0) t.visible = val < 0.5;
			else if (what === 1) t.text = "x" + Math.floor(val * 5);
			else if (what === 2) t.y = Math.floor(val * 90);
			else t.x = Math.floor(val * 200);
		});
		return "external";
	}
	if (k < 0.88) {
		// card scale changes without a re-format (hzTextSz19 reads it in hzTxtTop)
		w.env.cardScale = pick(r, [0.6, 0.8, 1, 1.25, 1.6]);
		return "scale";
	}
	if (k < 0.90) {
		// late font library: faces start to resolve. The hzOnFrame retry (every 300 frames) deletes failed probe entries,
		// re-resolves the three faces and re-formats every text (hzApplyTypo) when one of them changed. Copied logic.
		w.env.fontsReady = true;
		both(w, (h) => {
			const before = h.hzFontName() + h.hzFontName("rg") + h.hzFontName("bd");
			let bad = false;
			for (const k of Object.keys(h.hzFontOkMap)) if (h.hzFontOkMap[k] != 1) { delete h.hzFontOkMap[k]; bad = true; }
			if (bad && h.hzFontName() + h.hzFontName("rg") + h.hzFontName("bd") != before) for (const o of h.hzTexts) h.hzApplyFmt(o);
		});
		return "font";
	}
	if (k < 0.92) {
		// dark text toggle (card color): only a re-format changes colors
		const dk = r() < 0.5;
		both(w, (h) => { h.hzDark = dk; for (const o of h.hzTexts) h.hzApplyFmt(o); });
		return "dark";
	}
	if (k < 0.94 && allowRebuild) {
		// card rebuild inside the same movie: new fields, new sub-line arrays
		both(w, (h) => { h.hz27QL = []; h.hz27QLD = []; buildCard(h); });
		return "rebuild";
	}
	if (k < 0.95 && allowRebuild) {
		// another HorizonQuest_mc (hzSetSz target)
		const mc = { _mc: step };
		both(w, (h) => { h.HorizonQuest_mc = mc; });
		return "mc";
	}
	if (k < 0.97) {
		// card height changed by other code (hzQDraw19 path)
		const v = pick(r, [78, 100, 126]);
		both(w, (h) => { h.hz27QH = v; });
		return "height";
	}
	// more registered texts appear (another card built later): the registry grows
	both(w, (h) => filler(h, 3, "late" + step));
	return "registry";
}
function fieldAt(h, j) {
	return [h.hzQ19T, h.hzQ19D, h.hzQ19O, h.hzCQ19T, h.hzCQ19D, h.hzCQ19O][j] || (j >= 6 && j < 9 ? h.hz27QL[j - 6] : (j >= 9 ? h.hz27QLD[j - 9] : null)) || null;
}

// ---- 1. hzQSync: old vs new over randomized sequences ----
const tally = {};
let qsSteps = 0;
let qsBad = 0;
const cost = { old: { writes: 0, widths: 0 }, neu: { writes: 0, widths: 0 } };
function syncBoth(w) {
	let a = COST.writes, b = COST.widths;
	w.hosts.old.hzQSync();
	cost.old.writes += COST.writes - a; cost.old.widths += COST.widths - b;
	a = COST.writes; b = COST.widths;
	w.hosts.neu.hzQSync();
	cost.neu.writes += COST.writes - a; cost.neu.widths += COST.widths - b;
}
for (let seed = 1; seed <= 12; seed++) {
	let w = qWorld(seed);
	let bad = "";
	let movies = 0;
	for (let step = 0; step < 1500 && !bad; step++) {
		if (w.r() < 0.004) {
			// a new movie: a new AS instance on both sides (fresh hosts, fresh fields)
			const s2 = Math.floor(w.r() * 1e9);
			w = qWorld(s2);
			movies++;
		}
		const kind = qEvent(w, step, true);
		tally[kind] = (tally[kind] || 0) + 1;
		syncBoth(w);
		qsSteps++;
		const a = qSnap(w.hosts.old), b = qSnap(w.hosts.neu);
		if (a !== b) bad = "step " + step + " after " + kind + ": " + firstDiff(a, b);
	}
	if (bad) qsBad++;
	expect(!bad, "seed " + seed + ": 1500 compass frames (" + movies + " new movies) give the same card, fields, registry and side effects" + (bad ? " -- " + bad : ""));
}
console.log("    events: " + Object.keys(tally).sort().map((k) => k + "=" + tally[k]).join(" "));

// Steady compass frames (the run's case): the new pass skips, the old one rewrites and re-measures.
{
	const w = qWorld(99);
	both(w, (h, pool) => { h.hzQName = NAMES[3]; h.hzQObjStr = OBJS[2]; h.hzQDistStr = "120 M"; setSubs(h, pool, 2, [{ t: STEPS[1], d: "40 M", opt: false }, { t: STEPS[2], d: "", opt: true }]); });
	syncBoth(w);
	const before = { o: Object.assign({}, cost.old), n: Object.assign({}, cost.neu) };
	const sk0 = w.hosts.neu.hzPcQsSkip, run0 = w.hosts.neu.hzPcQsRun;
	for (let i = 0; i < 300; i++) syncBoth(w);
	const ow = (cost.old.writes - before.o.writes) / 300, ot = (cost.old.widths - before.o.widths) / 300;
	const nw = (cost.neu.writes - before.n.writes) / 300, nt = (cost.neu.widths - before.n.widths) / 300;
	console.log("    steady frame: text writes " + ow + " -> " + nw + ", textWidth reads " + ot + " -> " + nt + ", skips " + (w.hosts.neu.hzPcQsSkip - sk0) + "/300 runs " + (w.hosts.neu.hzPcQsRun - run0));
	expect(w.hosts.neu.hzPcQsSkip - sk0 === 300 && w.hosts.neu.hzPcQsRun === run0, "steady frames: every hzQSync after the first matches the signature");
	expect(nw === 0 && nt === 0 && ow > 0, "steady frames: no text write and no textWidth read on the skip path");
	expect(qSnap(w.hosts.old) === qSnap(w.hosts.neu), "steady frames: same card after 300 frames");
	// Distance moves every frame: a full pass each time, same as before.
	const run1 = w.hosts.neu.hzPcQsRun;
	for (let i = 0; i < 50; i++) { const d = (100 + i) + " M"; both(w, (h) => { h.hzQDistStr = d; }); syncBoth(w); }
	expect(w.hosts.neu.hzPcQsRun - run1 === 50, "a distance change every frame runs the full pass every frame");
	expect(qSnap(w.hosts.old) === qSnap(w.hosts.neu), "distance frames: same card");
}

// Each single input change forces the full pass (no subset signature).
{
	const cases = [
		["quest name", (h) => { h.hzQName = "Other"; }],
		["objective", (h) => { h.hzQObjStr = "Other objective"; }],
		["distance", (h) => { h.hzQDistStr = "9 M"; }],
		["sub-line text (pooled, in place)", (h) => { h.hz27QSubs[0].t = "Changed"; }],
		["sub-line distance (pooled, in place)", (h) => { h.hz27QSubs[1].d = "77 M"; }],
		["sub-line optional flag", (h) => { h.hz27QSubs[0].opt = !h.hz27QSubs[0].opt; }],
		["sub-line count", (h) => { h.hz27QSubs.length = 1; }],
		["HeaderStyle", (h) => { h.hzHeaderStyle = 1 - h.hzHeaderStyle; }],
		["TextScale", (h) => { h.hzTextScale = 1.2; }],
		["FontFace", (h) => { h.hzFontFace = 2; }],
		["letter-spacing mode", (h) => { h.hzLsMode = 1; }],
		["format epoch (one field re-formatted)", (h) => { h.hzApplyFmt(h.hzTxtObj(h.hz27QLD[2])); }],
		["registry fs", (h) => { h.hzTxtObj(h.hzQ19O).fs = 14; }],
		["registry ls", (h) => { h.hzTxtObj(h.hzCQ19D).ls = 0.4; }],
		["registry face", (h) => { h.hzTxtObj(h.hzQ19T).face = "bd"; }],
		["font module flag", (h) => { h.hz30Mod = { font: 0 }; }],
		["game font found (hzFixFonts)", (h) => { h.hzFont = "$Other_Game_Font"; }],
		["field text written elsewhere", (h) => { h.hzQ19D.text = "?"; }],
		["field visible written elsewhere", (h) => { h.hzQ19O.visible = !h.hzQ19O.visible; }],
		["field x written elsewhere", (h) => { h.hzCQ19O.x += 3; }],
		["card height written elsewhere", (h) => { h.hz27QH = 999; }],
		["HorizonQuest_mc replaced", (h) => { h.HorizonQuest_mc = { _mc: 2 }; }],
		["field replaced (card rebuilt)", (h) => { h.hzCQ19T = h.hzT(SPRITE, "", 32, 9, 200, 12, "sb", "main", 1.6, "left", 0xffffff); }],
		["sub-line array replaced", (h) => { h.hz27QL = h.hz27QL.slice(); }],
		["sub-line array grown", (h) => { h.hz27QBuild(SPRITE); }]
	];
	for (const c of cases) {
		const env = { cardScale: 1, fontsReady: false };
		const h = makeQHost("new", env);
		h.__env = env;
		filler(h, 20, "pre"); buildCard(h);
		const pool = newPool();
		h.hzQName = NAMES[1]; h.hzQObjStr = OBJS[1]; h.hzQDistStr = "50 M";
		setSubs(h, pool, 2, [{ t: STEPS[0], d: "10 M", opt: false }, { t: STEPS[3], d: "", opt: false }]);
		h.hzQSync(); h.hzQSync();
		const run0 = h.hzPcQsRun, sk0 = h.hzPcQsSkip;
		c[1](h);
		h.hzQSync();
		expect(h.hzPcQsRun === run0 + 1 && h.hzPcQsSkip === sk0, "change-only: " + c[0] + " runs the full pass");
	}
}

// A hz27QLayout error or a throw leaves the memo off; the next call runs the full pass (same as before).
{
	const env = { cardScale: 1, fontsReady: false };
	const h = makeQHost("new", env);
	filler(h, 5, "pre"); buildCard(h);
	h.hzQName = NAMES[1]; h.hzQObjStr = OBJS[1];
	h.hz27QSubs.push(null);
	h.hzQSync();
	expect(h.hzQsOk === false, "a hz27QLayout error (null sub-line) does not record the signature");
	const run0 = h.hzPcQsRun;
	h.hzQSync();
	expect(h.hzPcQsRun === run0 + 1, "after a hz27QLayout error the next call runs the full pass");
	h.hz27QSubs.length = 0;
	h.hzQSync(); h.hzQSync();
	const sk = h.hzPcQsSkip;
	const saved = h.hzTW;
	h.hzQDistStr = "1 M";
	h.hzTW = function() { throw "non-Error throw"; };
	let thrown = null;
	try { h.hzQSync(); } catch (e) { thrown = e; }
	h.hzTW = saved;
	expect(thrown === "non-Error throw" && h.hzQsOk === false, "a throw inside the full pass propagates unchanged and leaves the memo off");
	h.hzQSync();
	expect(h.hzPcQsSkip === sk && h.hzQsOk === true, "the next call runs the full pass and records again");
}

// S2 (Bot 3 review of 80327fe): on a skip frame the sub-line tops are replayed under the same catch(Error) the full pass
// has around hz27QLayout. An Error is swallowed as before and drops the memo; any other value propagates as before.
{
	const mk = (kind) => {
		const env = { cardScale: 1, fontsReady: false };
		const h = makeQHost(kind, env);
		filler(h, 5, "pre"); buildCard(h);
		const pool = newPool();
		h.hzQName = NAMES[1]; h.hzQObjStr = OBJS[1]; h.hzQDistStr = "50 M";
		setSubs(h, pool, 3, [{ t: STEPS[0], d: "10 M", opt: false }, { t: STEPS[3], d: "", opt: true }, { t: STEPS[4], d: "2 M", opt: false }]);
		h.hzQSync(); h.hzQSync();
		return h;
	};
	for (const tv of [new RangeError("top"), "top string"]) {
		const ho = mk("old"), hn = mk("new");
		const sk0 = hn.hzPcQsSkip, run0 = hn.hzPcQsRun;
		const real = {};
		for (const [k, h] of [["o", ho], ["n", hn]]) {
			real[k] = h.hzTxtTop;
			const bad = h.hz27QL[1];
			const r0 = h.hzTxtTop;
			h.hzTxtTop = function(tf, top) { if (tf === bad) throw tv; return r0(tf, top); };
		}
		let eo = "none", en = "none";
		try { ho.hzQSync(); } catch (e) { eo = e; }
		try { hn.hzQSync(); } catch (e) { en = e; }
		ho.hzTxtTop = real.o; hn.hzTxtTop = real.n;
		const label = "S2: " + (tv instanceof Error ? "an Error" : "a non-Error value") + " from a sub-line top on a skip frame";
		// the skip counter moves after the replay returns, so a propagated throw leaves it as it was; no full pass either way
		expect(hn.hzPcQsRun === run0 && hn.hzPcQsSkip === sk0 + (tv instanceof Error ? 1 : 0), label + " happens on the skip path (replay, no full pass)");
		if (tv instanceof Error) {
			expect(eo === "none" && en === "none", label + " is swallowed, as the full pass swallows it");
			expect(hn.hzQsOk === false, label + " drops the memo");
		} else {
			expect(eo === tv && en === tv, label + " propagates unchanged, as from the full pass");
		}
		expect(qSnap(ho) === qSnap(hn), label + ": same card as the 8e5e702 pass" + (qSnap(ho) === qSnap(hn) ? "" : " -- " + firstDiff(qSnap(ho), qSnap(hn))));
		const run1 = hn.hzPcQsRun;
		ho.hzQSync(); hn.hzQSync();
		if (tv instanceof Error) expect(hn.hzPcQsRun === run1 + 1, label + ": the next call runs the full pass");
		expect(qSnap(ho) === qSnap(hn), label + ": same card on the next call");
	}
}

// S3 (Bot 3): the field-identity and registry-entry checks are each redundant with the other plus the read-back, so
// dropping one alone is an equivalent mutant. Dropping both must be caught: a field replaced by a twin that shows the same
// text, visible and x, has the same fs / ls / face / epoch, but still carries a leftover text run. The full pass rewrites
// its text (which resets the run to the default format); a skip would not.
function s3Same(src) {
	const env = { cardScale: 1, fontsReady: false };
	const ho = makeQHost("old", env);
	const hn = makeQHost("new", env);
	if (src) for (const f of QFUNCS.concat(QNEW_ONLY)) bind(hn, src, f);
	const pools = [newPool(), newPool()];
	[ho, hn].forEach((h, i) => {
		filler(h, 5, "pre"); buildCard(h);
		h.hzQName = NAMES[1]; h.hzQObjStr = OBJS[1]; h.hzQDistStr = "50 M";
		setSubs(h, pools[i], 1, [{ t: STEPS[0], d: "10 M", opt: false }]);
		h.hzQSync(); h.hzQSync();
	});
	for (const h of [ho, hn]) {
		const was = h.hzQ19O;
		const o1 = h.hzTxtObj(was);
		const t2 = h.hzT(SPRITE, "", 74, 37, h.HZ_Q19_W - 74 - 14, 13, "rg", "mut", 0, "left", 0xffffff);
		const o2 = h.hzTxtObj(t2);
		t2.text = was.text; t2.visible = was.visible; t2.x = was.x; t2.y = was.y;
		o2.fmtN = o1.fmtN;
		t2.setTextFormat(new TextFormat("$Leftover_Run", 30, 0x123456));
		h.hzQ19O = t2;
	}
	const sk = hn.hzPcQsSkip;
	ho.hzQSync(); hn.hzQSync();
	return { same: qSnap(ho) === qSnap(hn), skipped: hn.hzPcQsSkip === sk + 1 };
}
{
	const prod = s3Same(null);
	expect(prod.same && !prod.skipped, "S3: a replaced twin field runs the full pass (same card as the 8e5e702 pass)");
	const noBoth = mutant("               if(tf !== this.hzQsR[b]) { return false; }\n", "").replace("                  if(o !== this.hzQsR[b + 1]) { return false; }\n", "");
	expect(noBoth !== as && noBoth.indexOf("if(o !== this.hzQsR[b + 1])") < 0, "S3: mutant drops both identity checks");
	const m = s3Same(noBoth);
	expect(!m.same && m.skipped, "S3: mutant without the field and the registry-entry identity checks is killed (it skips and keeps the leftover run)");
}

// ---- 2. hzTxtObj: indexed lookup vs the 8e5e702 scan ----
{
	const r = rng(7);
	const oldH = makeQHost("old", { cardScale: 1, fontsReady: false });
	const newH = makeQHost("new", { cardScale: 1, fontsReady: false });
	const tfs = [];
	let mism = 0;
	let checks = 0;
	for (let step = 0; step < 4000; step++) {
		if (r() < 0.2) {
			const t = new TextField();
			const o = { tf: t, size: 12 };
			const o2 = { tf: t, size: 12 };
			oldH.hzTexts.push(o); newH.hzTexts.push(o2);
			tfs.push(t);
		}
		const q = r();
		const t = q < 0.1 ? null : (q < 0.2 ? new TextField() : (tfs.length ? tfs[Math.floor(r() * tfs.length)] : null));
		const a = oldH.hzTxtObj(t), b = newH.hzTxtObj(t);
		const ia = a ? oldH.hzTexts.indexOf(a) : -1, ib = b ? newH.hzTexts.indexOf(b) : -1;
		checks++;
		if (ia !== ib) mism++;
	}
	expect(mism === 0, "hzTxtObj: same entry (by index) as the scan for " + checks + " lookups on a growing registry, null and unregistered fields included");
	expect(newH.hzPcTxMiss <= 400 && newH.hzPcTxHit > 3000, "hzTxtObj: answers come from the index (hit " + newH.hzPcTxHit + ", scan " + newH.hzPcTxMiss + ")");
	// The index is checked on every use: an entry whose tf no longer matches falls back to the scan, which is the old answer.
	const t0 = tfs[3];
	const moved = newH.hzTexts[3];
	moved.tf = new TextField();
	oldH.hzTexts[3].tf = moved.tf;
	expect(newH.hzTxtObj(t0) === null && oldH.hzTxtObj(t0) === null, "hzTxtObj: a stale index slot is not trusted (scan answer)");
}
expect(!/\.tf\s*=[^=]/.test(as.replace(/o\.tf == tf|e\.tf : null/g, "")), "source: no code reassigns a registry entry's tf (the index invariant)");
expect(!/hzTexts\s*=[^=]|hzTexts\.(splice|shift|unshift|pop|reverse|sort)\(|hzTexts\.length\s*=[^=]/.test(as), "source: hzTexts is append-only (no reassignment, removal or reorder)");

// ---- 3. Pass wrappers: catch(e:*) closes the pass for any thrown value (Bot 4 S1, m5, m7) ----
let uid = 0;
function Clip(name, opts) {
	opts = opts || {};
	return { _id: ++uid, name: name, visible: opts.visible !== false, alpha: 1, x: opts.x || 0, y: opts.y || 0,
		scaleX: opts.scaleX == null ? 1 : opts.scaleX, scaleY: opts.scaleY == null ? 1 : opts.scaleY, parent: null, kids: opts.leaf ? null : [],
		transform: { colorTransform: { alphaMultiplier: 1, alphaOffset: 0 } } };
}
function add(p, c) { c.parent = p; p.kids.push(c); return c; }
function makeDoc(c) {
	if (!c.kids) return c;
	Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; }, configurable: true });
	c.getChildAt = function(i) {
		if (this.__throwAt === i) { this.__throwAt = -1; const v = this.__throwVal; throw v; }
		return this.kids[i];
	};
	c.getChildByName = function(n) { for (const k of this.kids) if (k.name === n) return k; return null; };
	c.getChildIndex = function(d) { const i = this.kids.indexOf(d); if (i < 0) throw new Error("not a child"); return i; };
	for (const k of c.kids) makeDoc(k);
	return c;
}
function __isDoc(x) { return !!(x && x.kids); }
global.__isDoc = __isDoc;
function fill(p, n, r, tag) { let cur = p; for (let m = 0; m < n; m++) { const c = add(cur, Clip(tag + "_" + m)); cur = (m % 4 === 3) ? p : c; if (r() < 0.3) add(c, Clip("shape" + m, { leaf: true })); } }
function buildBlg(seed) {
	const r = rng(seed);
	const blg = Clip("BottomLeftGroup_mc");
	fill(add(blg, Clip("WatchOutline_mc")), 20, r, "ol");
	add(blg, Clip("instance540", { x: 0.5, y: -0.25 }));
	fill(add(blg, Clip("WatchPointerOutline_mc")), 10, r, "ptr");
	fill(add(blg, Clip("WatchIconsWidget_mc")), 10, r, "wi");
	fill(add(blg, Clip("MissionIconsWidget_mc")), 10, r, "mi");
	fill(add(blg, Clip("O2CO2_mc")), 10, r, "o2");
	for (const n of ["DayCycleBase_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc", "Autopilot_mc"]) fill(add(blg, Clip(n)), 6, r, n);
	fill(add(blg, Clip("EnvConditionBase_mc")), 4, r, "ecb");
	add(blg, Clip("instance546", { x: 110.5, y: 110.5 }));
	fill(add(blg, Clip("EnemyDetectionAnim_mc")), 4, r, "eda");
	const holder = add(blg, Clip("WatchMarkHolder_mc"));
	fill(holder, 8, r, "hold");
	add(holder.kids[0], Clip("EnemyIconsWidget_mc"));
	const top = Clip("root");
	add(top, blg);
	return makeDoc(top);
}
const CFUNCS = ["hzFindByName", "hz43VanSkip", "hz43VanMarkName", "hz43VanInstName", "hz43VanCapClip", "hz43VanRingProof", "hz43VanRingClip",
	"hz43VanNamed", "hz43VanRootOf", "hz43VanWatchClip", "hz43StHide", "hz43VanNote", "hz43VanNoteAdd", "hz43VanRestoreHid", "hz43VanShowClip", "hz43VanGameVis",
	"hz43VanEnvWant", "hz43VanInfoName", "hz43VanHoldsMark", "hz43VanBlgChrome", "hz43VanChrome", "hz43VanOutline", "hz43OlBegin", "hz43OlEnd",
	"hz43IsMark", "hz43FindMark"];
const CCHANGED = ["hz43VanBlgChrome", "hz43VanChrome"];
function constArr(name) {
	const m = as.match(new RegExp("static const " + name + ":Array = (\\[[^\\]]*\\]);"));
	if (!m) throw new Error("const " + name);
	return JSON.parse(m[1]);
}
function makeCHost(kind, top, style, src) {
	const h = {
		int: function(n) { return n | 0; }, trace: function() {}, __isDoc: __isDoc,
		hzPerfOn: true, hzPcFind: 0, hzPcStHide: 0, hzPcHoldN: 0, hzPcOlHit: 0, hzPcOlMiss: 0,
		hz43OlDepth: 0, hz43OlHave: false, hz43OlRef: null, hz43OlBlg: null,
		hzBlg: top.kids[0], hzWatchStyle: style, hzHideVanillaWatch: style !== 1 && style !== 2, hzHideCache: [], hz43HideStyle: style,
		hz43VanShown: 1, hz43VanTries: 0, hz43VanLogged: true, hzDebug: false, hz26Dbg: {},
		hz43VanRing: null, hz43HidA: null, hz43HidN: 0, hz43VanN: 0, hz43VanD: [],
		hz43EnvGot: 1, hz43EnvLocal: false, hz43EnvCruise: false, hz43EnvLang: "en",
		HZ43_VAN_N: constArr("HZ43_VAN_N"), HZ43_VAN_MARK: constArr("HZ43_VAN_MARK"), HZ43_VAN_INFO: constArr("HZ43_VAN_INFO"),
		HZ43_VAN_A: constArr("HZ43_VAN_A"), HZ43_HID_MAX: constOf("HZ43_HID_MAX"), HZ43_VAN_FACE: constOf("HZ43_VAN_FACE"),
		hz43VanDump: function() {}
	};
	for (const f of CFUNCS) bind(h, kind === "old" && CCHANGED.indexOf(f) >= 0 ? REF_8E5E702 : (src || as), f);
	h.__top = top;
	return h;
}
function chrome(h) {
	if (h.hzWatchStyle === 3 || h.hzWatchStyle === 4) h.hz43VanChrome(true);
	else h.hz43VanChrome(false);
}
function cSnap(h) {
	const out = [];
	(function walk(c, p) { out.push(p + c.name + "=" + (c.visible ? 1 : 0)); if (c.kids) c.kids.forEach((k, i) => walk(k, p + i + "/")); })(h.__top, "");
	out.push("hidN=" + h.hz43HidN + " ring=" + (h.hz43VanRing ? h.hz43VanRing.name : "null"));
	return out.join("\n");
}
function sameThrow(a, b) { return typeof a === typeof b && (a instanceof Error ? (b instanceof Error && a.message === b.message) : a === b); }
let thrownN = { err: 0, str: 0, num: 0 };
for (let seed = 1; seed <= 6; seed++) {
	const r = rng(100 + seed);
	const ta = buildBlg(seed), tb = buildBlg(seed);
	let style = 1 + Math.floor(r() * 4);
	const ho = makeCHost("old", ta, style), hn = makeCHost("new", tb, style);
	let bad = "";
	for (let step = 0; step < 300 && !bad; step++) {
		if (r() < 0.05) { style = 1 + Math.floor(r() * 4); for (const h of [ho, hn]) { h.hzWatchStyle = style; h.hzHideVanillaWatch = style !== 1 && style !== 2; h.hz43HideStyle = style; } }
		if (r() < 0.3) {
			// the native timeline writes visible on a random clip, the same on both trees
			const all = [];
			(function walk(c, p) { all.push(p); if (c.kids) c.kids.forEach((k, i) => walk(k, p.concat([i]))); })(ta, []);
			const p = all[1 + Math.floor(r() * (all.length - 1))];
			const v = r() < 0.5;
			for (const t of [ta, tb]) { let c = t; for (const i of p) c = c.kids[i]; c.visible = v; }
		}
		let tv;
		const q = r();
		if (q < 0.08) {
			tv = q < 0.03 ? new RangeError("model throw") : (q < 0.055 ? "model string throw" : 42);
			const at = Math.floor(r() * ta.kids[0].kids.length);
			for (const t of [ta, tb]) { t.kids[0].__throwAt = at; t.kids[0].__throwVal = tv; }
		}
		let eo = undefined, en = undefined;
		try { chrome(ho); } catch (e) { eo = e; }
		try { chrome(hn); } catch (e) { en = e; }
		for (const t of [ta, tb]) t.kids[0].__throwAt = -1;
		if (tv !== undefined && (eo !== undefined || en !== undefined)) {
			if (tv instanceof Error) thrownN.err++; else if (typeof tv === "string") thrownN.str++; else thrownN.num++;
			if (!sameThrow(eo, en) || !sameThrow(en, tv)) bad = "step " + step + ": thrown values differ (" + String(eo) + " / " + String(en) + ")";
			if (hn.hz43OlDepth !== 0 || hn.hz43OlHave || hn.hz43OlRef !== null) bad = bad || "step " + step + ": new pass left open after a " + typeof tv + " throw";
			if (tv instanceof Error && ho.hz43OlDepth !== 0) bad = bad || "step " + step + ": old pass left open after an Error throw";
			if (!(tv instanceof Error) && ho.hz43OlDepth === 0) bad = bad || "step " + step + ": old body closed a non-Error throw (model lost the catch type)";
			// keep comparing: close the old body's leaked pass by hand (that leak is what S1 fixes)
			ho.hz43OlDepth = 0; ho.hz43OlHave = false; ho.hz43OlRef = null; ho.hz43OlBlg = null;
		}
		if (!bad) { const a = cSnap(ho), b = cSnap(hn); if (a !== b) bad = "step " + step + " style " + style + ": " + firstDiff(a, b); }
		if (!bad && (hn.hz43OlDepth !== 0 || hn.hz43OlHave)) bad = "step " + step + ": memo left after a pass";
	}
	expect(!bad, "seed " + seed + ": 300 chrome passes (styles 1-4, timeline writes, throws) give the same state and the same thrown value" + (bad ? " -- " + bad : ""));
}
expect(thrownN.err > 0 && thrownN.str > 0 && thrownN.num > 0, "throws covered: Error " + thrownN.err + ", string " + thrownN.str + ", number " + thrownN.num);

// Direct S1 cases on both wrappers, each value type.
for (const style of [1, 3]) {
	for (const tv of [new RangeError("e"), "s", 7, null]) {
		const t = buildBlg(9);
		const h = makeCHost("new", t, style);
		t.kids[0].__throwAt = 2; t.kids[0].__throwVal = tv;
		let got = "none";
		try { chrome(h); } catch (e) { got = e; }
		const label = (style === 1 ? "hz43VanBlgChrome" : "hz43VanChrome(true)") + " throw " + (tv === null ? "null" : typeof tv);
		expect(got !== "none" && sameThrow(got, tv), label + ": the same value is rethrown");
		expect(h.hz43OlDepth === 0 && h.hz43OlHave === false && h.hz43OlRef === null && h.hz43OlBlg === null, label + ": the pass is closed and the memo dropped");
	}
}

// m5 / m7: a memo planted outside a pass (what a leaked pass used to leave) is never served.
function plantStale(h) {
	h.hz43OlDepth = 0; h.hz43OlHave = true; h.hz43OlRef = { name: "stale", parent: null }; h.hz43OlBlg = h.hzBlg;
}
function m7Check(src) {
	const t = buildBlg(11); const h = makeCHost("new", t, 1, src);
	plantStale(h);
	const got = h.hz43VanOutline();
	return got !== null && got.name === "WatchOutline_mc";
}
function m5Check(src) {
	const t = buildBlg(12); const h = makeCHost("new", t, 1, src);
	h.hz43OlHave = true; h.hz43OlRef = { name: "stale", parent: null }; h.hz43OlBlg = h.hzBlg; h.hz43OlDepth = -1;
	h.hz43OlBegin();
	const miss0 = h.hzPcOlMiss;
	const got = h.hz43VanOutline();
	h.hz43OlEnd();
	return got !== null && got.name === "WatchOutline_mc" && h.hzPcOlMiss === miss0 + 1;
}
function s1Check(src) {
	const t = buildBlg(13); const h = makeCHost("new", t, 1, src);
	t.kids[0].__throwAt = 1; t.kids[0].__throwVal = "s";
	try { chrome(h); } catch (e) { }
	return h.hz43OlDepth === 0 && !h.hz43OlHave;
}
expect(m7Check(as), "m7: outside a pass a planted memo is not served (plain search)");
expect(m5Check(as), "m5: opening a pass drops a planted memo, the first lookup searches");
expect(s1Check(as), "S1: a non-Error throw closes the pass");
// The checks above must fail on the mutants (self-test of the tests).
function mutant(from, to) { if (as.indexOf(from) < 0) throw new Error("mutant anchor missing: " + from); return as.replace(from, to); }
const M7 = mutant("if(this.hz43OlDepth > 0 && this.hz43OlHave && this.hz43OlBlg == this.hzBlg)", "if(this.hz43OlHave && this.hz43OlBlg == this.hzBlg)");
const M5 = mutant(`         if(this.hz43OlDepth <= 0)
         {
            this.hz43OlDepth = 0;
            this.hz43OlHave = false;
            this.hz43OlRef = null;
            this.hz43OlBlg = null;
         }
         this.hz43OlDepth++;`, `         if(this.hz43OlDepth <= 0)
         {
            this.hz43OlDepth = 0;
         }
         this.hz43OlDepth++;`);
const MS1 = mutant("catch(eOl:*)", "catch(eOl:Error)");
expect(!m7Check(M7), "mutant m7 (memo served outside a pass) is killed");
expect(!m5Check(M5), "mutant m5 (no reset in hz43OlBegin) is killed");
expect(!s1Check(MS1), "mutant catch(eOl:Error) (S1 reverted) is killed by the string throw");
// Mutants of the change-only signature must be killed by section 1 (a subset signature changes the output).
function qMutantKilled(from, to) {
	const src = mutant(from, to);
	for (let seed = 1; seed <= 12; seed++) {
		let w = qWorld(seed);
		w.hosts.neu = makeQHost("new", w.env);
		for (const f of QFUNCS.concat(QNEW_ONLY)) bind(w.hosts.neu, src, f);
		w.pools.neu = newPool();
		filler(w.hosts.neu, 90, "pre"); buildCard(w.hosts.neu); filler(w.hosts.neu, 100, "post");
		for (let step = 0; step < 1500; step++) {
			qEvent(w, step, true);
			w.hosts.old.hzQSync(); w.hosts.neu.hzQSync();
			if (qSnap(w.hosts.old) !== qSnap(w.hosts.neu)) return true;
		}
	}
	return false;
}
const QMUT = [
	["no distance in the signature", "|| this.hzQDistStr !== this.hzQsDist", ""],
	["no sub-line distance", "String(s.d) !== this.hzQsSubD[i] || ", ""],
	["no format epoch", "int(o.fmtN) !== this.hzQsR[b + 2] || ", ""],
	["no text read-back", "tf.text !== this.hzQsR[b + 6] || ", ""],
	["no visible read-back", "tf.visible !== this.hzQsR[b + 7] || ", ""],
	["no HeaderStyle", "this.hzHeaderStyle != this.hzQsHdr || ", ""],
	["no hzTxtTop replay", "            this.hzQsTops();\n", ""],
	["no card height", "this.hz27QH !== this.hzQsH || ", ""],
	["no epoch bump in hzApplyFmt", "         o.fmtN = int(o.fmtN) + 1;", ""]
];
for (const m of QMUT) expect(qMutantKilled(m[1], m[2]), "change-only mutant killed: " + m[0]);

// ---- 4. Source pins ----
function body(name) { return fnText(as, name).body; }
expect(/catch\(eOl:\*\)\s*\{\s*this\.hz43OlEnd\(\);\s*throw eOl;\s*\}/.test(body("hz43VanBlgChrome")), "hz43VanBlgChrome: catch(eOl:*) closes and rethrows");
expect(/catch\(eOc:\*\)\s*\{\s*this\.hz43OlEnd\(\);\s*throw eOc;\s*\}/.test(body("hz43VanChrome")), "hz43VanChrome: catch(eOc:*) closes and rethrows");
expect(body("hzQSync").indexOf("if(this.hzQsSame())") >= 0 && body("hzQSync").indexOf("if(!qlErr) { this.hzQsKeep(); }") >= 0, "hzQSync: skip only on a full match, record only after a clean pass");
expect(body("hzApplyFmt").indexOf("o.fmtN = int(o.fmtN) + 1;") < body("hzApplyFmt").indexOf("this.hzApplyFmt19(o)"), "hzApplyFmt: the epoch moves before both format paths");
expect(as.indexOf(" | co qsSkip=") >= 0 && /this\.hzPcQsSkip = 0;[\s\S]*this\.hzPcTxMiss = 0;/.test(body("hzPbClear")), "parts line reports qsSkip, qsRun, txHit, txMiss; window clear resets them");
for (const n of ["hzQsSame", "hzQsTops", "hzQsField"]) {
	const b = body(n);
	expect(!/new |\[\]|\{\}|removeChild|getTimer|frameN|% ?\d/.test(b), n + ": no allocation, timer, frame counter or removeChild");
}
expect(!/new |\{\}|removeChild|getTimer|frameN|% ?\d/.test(body("hzTxtObj")) && (body("hzTxtObj").match(/\[\]/g) || []).length === 1
	&& body("hzTxtObj").indexOf("if(this.hzTextTf == null) { this.hzTextTf = []; }") >= 0, "hzTxtObj: no allocation except the one-time index array, no timer or removeChild");
expect(!/new (?!Array\()/.test(body("hzQsKeep")) && !/removeChild|getTimer/.test(body("hzQsKeep")), "hzQsKeep: allocates its arrays once, no timer or removeChild");
expect(!/hzFrameN|getTimer|% ?\d/.test(body("hzQSync")), "hzQSync: no frame or interval gating");

if (failed) { console.error(failed + " FAILED"); process.exit(1); }
console.log("changeonly model tests passed");
