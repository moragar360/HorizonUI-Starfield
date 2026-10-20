      // =================== Horizon UI Scope module (v0.42.0): hold-breath chip ===================
      // The game's hold-breath prompt (HoldBreathButton_mc: a ButtonBase with "$Hold Breath" / user event "Steady", and the
      // ButtonBackground_mc behind it) is set visible = false while the chip is on; nothing is removed and the game's own
      // handling of the "Steady" control is not touched (this menu never handled it; the button only shows the key).
      // The chip sits where the hidden button sits and keeps its 1:1 size against the scope zoom scale (the button's own
      // counter-scale), moved by [Scope] ScopeChipX / ScopeChipY (1080p units from the game's spot, X + = right, Y + = up)
      // and sized by ScopeChipScale (0.60 - 1.60, 1 = the game's size). Icon tile = an original target icon drawn in code
      // (ring, 4 ticks, center dot) + the hold-breath key name (r3: the game's own key text on the hidden button, else the
      // "Steady" control map entry, else SHIFT / L3; never "?"), label, slim O2 meter:
      // the scope menu gets no breath value, so the meter is O2 (PlayerFrequentData fOxygen / fMaxO2CO2, the same source as
      // the HUD's O2 bar; verified in game). O2 colors = the main HUD vitals card (hz26Band / hz26WarnCol): under 35 % the
      // bar and the border are amber, under 15 % red; OUT OF BREATH (red, no fill) after 2 readings in a row under 1 %
      // (a single 0 reading when the scope opens never flashes it). HOLDING BREATH = O2 fell on 2 readings in a row (the
      // game sends no breath-hold state to this menu, so a steady O2 drain also shows it).
      // Settings: [Scope] ScopeHoldBreathChip (0 = the game's prompt) / ScopeChipX / ScopeChipY / ScopeChipScale and [Style]
      // AccentColor / AccentHex / CardOpacity / TextScale / FontFace / HeaderStyle (same meaning as on the HUD). Read when
      // the scope opens and every 5 s after.
      private static const HZP_VERSION:String = "0.42.0";
      private static const HZP_BUILD:String = "0.42.0 r3";
      private static const HZP_ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZP_ACC:uint = 0x3FD0E0;
      private static const HZP_O2:uint = 0x4DB6FF;
      private static const HZP_AMB:uint = 0xF2A93B;
      private static const HZP_RED:uint = 0xFF5B5B;
      private static const HZP_BG:uint = 0x0B1218;
      private static const HZP_TXT:uint = 0xF2F7F9;
      private static const HZP_DIM:uint = 0x8E9CA4;
      private static const HZP_MINPX:Number = 13;
      private static const HZP_O2_WARN:Number = 0.35;   // = the HUD vitals card warning band (hz26Band 1, hz26WarnCol amber)
      private static const HZP_O2_CRIT:Number = 0.15;   // = the HUD vitals card critical band (hz26Band 2, hz26WarnCol red)
      private static const HZP_LRG:Boolean = __HZP_LRG__;
      private static const HZP_LBL:Array = ["HOLD BREATH","HOLDING BREATH","HOLD BREATH","OUT OF BREATH"];   // [2] unused since r2 (bands color the chip)
      private var hzpOn:Boolean = true;
      private var hzpReady:Boolean = false;
      private var hzpSub:Boolean = false;
      private var hzpHid:Boolean = false;
      private var hzpS:Object = {"AccentColor":0,"AccentHex":-1,"CardOpacity":1,"TextScale":1,"FontFace":1,"HeaderStyle":0,"ChipX":0,"ChipY":0,"ChipS":1};
      private var hzpChip:Sprite = null;
      private var hzpW:Number = 0;
      private var hzpH:Number = 32;
      private var hzpO2:Number = -1;          // 0 - 1, -1 = no data yet
      private var hzpFallT:int = -100000;     // last time O2 went down on 2 readings in a row (getTimer)
      private var hzpFallN:int = 0;           // falling readings in a row
      private var hzpZeroN:int = 0;           // readings under 1 % in a row
      private var hzpSig:String = "";
      private var hzpIniT:int = -100000;
      private var hzpFontOk:Object = {};
      private var hzpLastX:Number = NaN;
      private var hzpLastY:Number = NaN;
      private var hzpKeyTx:String = "";      // r3: key name shown in the keycap
      private var hzpKeyFace:String = null;  // r3: the game's glyph face when the key came from the controller button
      private var hzpMap:Array = null;       // r3: ControlMapData vMappedEvents
      private var hzpPad:Boolean = false;    // r3: a controller is in use (uiController > keyboard / mouse)
      private var hzpErr:Boolean = false;    // r3: an error turned the chip off for this scope session

      private function hzpInit() : void
      {
         this.hzpChip = new Sprite();
         this.hzpChip.name = "hzpChip";
         this.hzpChip.mouseEnabled = false;
         this.hzpChip.mouseChildren = false;
         this.hzpChip.visible = false;
         addChild(this.hzpChip);
         this.addEventListener(Event.ENTER_FRAME,this.hzpTick);
         try { this.HoldBreathButton_mc.addEventListener(ButtonBase.BUTTON_REDRAWN_EVENT,this.hzpRedrawn); } catch(e1:Error) { }
         this.hzpRead();
      }
      private function hzpRead() : void
      {
         this.hzpIniT = getTimer();
         try { this.hzp37IniRead(this.hzpOnIni); } catch(e:Error) { this.hzpReady = true; }
      }
      private function hzpOnIni(txt:String) : void
      {
         var on:Boolean = true;
         var st:Object = {"AccentColor":0,"AccentHex":-1,"CardOpacity":1,"TextScale":1,"FontFace":1,"HeaderStyle":0,"ChipX":0,"ChipY":0,"ChipS":1};
         if(txt != null)
         {
            var sec:String = "";
            for each(var ln:String in this.hzp37Lines(txt))
            {
               var h:String = this.hzp37Hdr(ln);
               if(h != null) { sec = this.hzp37Alias(h); continue; }
               var kv:Object = this.hzp37KV(ln);
               if(kv == null) { continue; }
               var k:String = String(kv.k);
               var v:String = String(kv.v);
               var nv:Number = Number(v);
               if(sec == "scope")
               {
                  if(k == "scopeholdbreathchip") { on = !(v == "0" || v.toLowerCase() == "false"); }
                  else if(k == "scopechipx" && !isNaN(nv)) { st.ChipX = Math.round(Math.max(-900,Math.min(900,nv))); }
                  else if(k == "scopechipy" && !isNaN(nv)) { st.ChipY = Math.round(Math.max(-500,Math.min(500,nv))); }
                  else if(k == "scopechipscale" && !isNaN(nv)) { st.ChipS = Math.round(Math.max(0.6,Math.min(1.6,nv)) * 100) / 100; }
               }
               else if(sec == "style")
               {
                  if(k == "accentcolor" && !isNaN(nv)) { st.AccentColor = Math.max(0,Math.min(13,int(nv))); }
                  else if(k == "accenthex") { st.AccentHex = this.hzpHex(v); }
                  else if(k == "cardopacity" && !isNaN(nv)) { st.CardOpacity = Math.max(0.2,Math.min(1.6,nv)); }
                  else if(k == "textscale" && !isNaN(nv)) { st.TextScale = Math.max(0.8,Math.min(1.3,nv)); }
                  else if(k == "fontface" && !isNaN(nv)) { st.FontFace = Math.max(0,Math.min(3,int(nv))); }
                  else if(k == "headerstyle" && !isNaN(nv)) { st.HeaderStyle = Math.max(0,Math.min(1,int(nv))); }
               }
            }
         }
         this.hzpOn = on && !this.hzpErr;
         this.hzpS = st;
         this.hzpSig = "";
         this.hzpReady = true;
      }
      private function hzpHex(v:String) : int
      {
         if(v == null) { return -1; }
         v = v.replace(/^\s+|\s+$/g,"").replace("#","").replace("0x","").replace("0X","");
         if(v.length != 6 || !/^[0-9A-Fa-f]{6}$/.test(v)) { return -1; }
         return int(parseInt(v,16));
      }
      private function hzpAccent() : uint
      {
         var a:int = int(this.hzpS.AccentColor);
         if(a == 13 && int(this.hzpS.AccentHex) >= 0) { return uint(this.hzpS.AccentHex); }
         if(a >= 0 && a < HZP_ACCENTS.length) { return uint(HZP_ACCENTS[a]); }
         return HZP_ACC;
      }
      private function hzpOnFreq(e:FromClientDataEvent) : void
      {
         try
         {
            var d:Object = e.data;
            var o2:Number = Number(d.fOxygen);
            var mo2:Number = Number(d.fMaxO2CO2);
            if(isNaN(o2) || isNaN(mo2) || mo2 <= 0) { return; }
            var f:Number = Math.max(0,Math.min(1,o2 / mo2));
            if(this.hzpO2 >= 0 && f < this.hzpO2 - 0.0005) { this.hzpFallN++; } else { this.hzpFallN = 0; }
            if(this.hzpFallN >= 2) { this.hzpFallT = getTimer(); }
            this.hzpZeroN = f < 0.01 ? this.hzpZeroN + 1 : 0;
            this.hzpO2 = f;
         }
         catch(err:Error) { }
      }
      // the button redraws itself visible (MinimalButton.UpdateVisibility): hide it again at once
      private function hzpRedrawn(e:Event) : void
      {
         if(this.hzpHid) { this.hzpHideVan(true); }
      }
      private function hzpHideVan(hide:Boolean) : void
      {
         var b:* = this.HoldBreathButton_mc;
         if(hide)
         {
            if(b != null) { b.visible = false; }
            if(this.ButtonBackground_mc != null) { this.ButtonBackground_mc.visible = false; }
            this.hzpHid = true;
            return;
         }
         if(!this.hzpHid) { return; }
         this.hzpHid = false;
         try { if(b != null) { b.visible = b.Visible; } } catch(e1:Error) { if(b != null) { b.visible = true; } }
         if(this.ButtonBackground_mc != null) { this.ButtonBackground_mc.visible = true; }
      }
      private function hzpTick(e:Event) : void
      {
         try { this.hzpFrame(); } catch(err:Error) { this.hzpFail(); }
      }
      // r3: any error -> the game's own prompt for the rest of this scope session (chip hidden, the button shown again)
      private function hzpFail() : void
      {
         this.hzpErr = true;
         this.hzpOn = false;
         try { this.hzpHideVan(false); } catch(e1:Error) { }
         try { if(this.HoldBreathButton_mc != null) { this.HoldBreathButton_mc.visible = true; } } catch(e2:Error) { }
         try { if(this.ButtonBackground_mc != null) { this.ButtonBackground_mc.visible = true; } } catch(e3:Error) { }
         try { if(this.hzpChip != null) { this.hzpChip.visible = false; } } catch(e4:Error) { }
      }
      private function hzpOnMap(e:FromClientDataEvent) : void
      {
         try
         {
            var d:Object = e.data;
            if(d == null) { return; }
            if(d.vMappedEvents != null) { this.hzpMap = d.vMappedEvents as Array; if(this.hzpMap == null) { this.hzpMap = []; for each(var m0:* in d.vMappedEvents) { this.hzpMap.push(m0); } } }
            this.hzpPad = uint(d.uiController) > 0;
         }
         catch(err:Error) { }
      }
      private function hzpKeyOk(s:*) : Boolean
      {
         if(s == null) { return false; }
         var t:String = String(s).replace(/^\s+|\s+$/g,"");
         return t.length > 0 && t != "?" && t != "null" && t != "undefined" && t.indexOf("$") != 0;
      }
      private function hzpKeyClip(s:String) : String
      {
         var t:String = s.replace(/^\s+|\s+$/g,"").replace(/\s+/g," ");
         return t.length > 12 ? t.substr(0,12) : t;
      }
      private function hzpTfTx(t:*) : String
      {
         try { if(t != null && t.visible != false && this.hzpKeyOk(t.text)) { return String(t.text); } } catch(e:Error) { }
         return null;
      }
      private function hzpTfFace(t:*) : String
      {
         try { var f:* = t.getTextFormat().font; if(f) { return String(f); } } catch(e:Error) { }
         return null;
      }
      // r3: [key text, glyph face or null]
      private function hzpKey() : Array
      {
         var b:* = this.HoldBreathButton_mc;
         var tx:String = null;
         var t:* = null;
         try
         {
            if(!this.hzpPad)
            {
               try { t = b.PCButton_mc.ButtonInstance_mc.PCButton_tf; } catch(e1:Error) { t = null; }
               tx = this.hzpTfTx(t);
               if(tx == null) { try { t = b.PCButton_mc.PCButton_tf; } catch(e2:Error) { t = null; } tx = this.hzpTfTx(t); }
               if(tx != null) { return [this.hzpKeyClip(tx).toUpperCase(),null]; }
            }
            else
            {
               try { t = b.ConsoleButton_mc.ButtonInstance_mc.ConsoleButton_tf; } catch(e3:Error) { t = null; }
               tx = this.hzpTfTx(t);
               if(tx == null) { try { t = b.ConsoleButton_mc.ConsoleButton_tf; } catch(e4:Error) { t = null; } tx = this.hzpTfTx(t); }
               if(tx != null) { return [this.hzpKeyClip(tx),this.hzpTfFace(t)]; }
            }
         }
         catch(e5:Error) { }
         var mk:String = this.hzpMapKey();
         if(mk != null) { return [mk,null]; }
         return [this.hzpPad ? "L3" : "SHIFT",null];
      }
      // the "Steady" entry of ControlMapData: the raw button name(s), upper case ("LShift" -> "L-SHIFT")
      private function hzpMapKey() : String
      {
         if(this.hzpMap == null) { return null; }
         try
         {
            for each(var m:* in this.hzpMap)
            {
               if(m == null || String(m.strUserEventName) != "Steady") { continue; }
               var parts:Array = [];
               try { for each(var a:* in m.aButtonName) { if(this.hzpKeyOk(a)) { parts.push(this.hzpPretty(String(a))); } } } catch(e1:Error) { }
               if(parts.length == 0 && this.hzpKeyOk(m.strButtonName)) { parts.push(this.hzpPretty(String(m.strButtonName))); }
               if(parts.length > 0) { return this.hzpKeyClip(parts.join("+")); }
            }
         }
         catch(e2:Error) { }
         return null;
      }
      private function hzpPretty(s:String) : String
      {
         var u:String = s.replace(/^\s+|\s+$/g,"");
         var m:Object = /^([LR])(Shift|Ctrl|Control|Alt)$/i.exec(u);
         if(m != null) { return String(m[1]).toUpperCase() + "-" + String(m[2]).toUpperCase().replace("CONTROL","CTRL"); }
         return u.toUpperCase();
      }
      private function hzpFrame() : void
      {
         var now:int = getTimer();
         if(!this.hzpSub && stage != null)
         {
            this.hzpSub = true;
            try { BSUIDataManager.Subscribe("PlayerFrequentData",this.hzpOnFreq); } catch(e1:Error) { }
            try { BSUIDataManager.Subscribe("ControlMapData",this.hzpOnMap); } catch(e1b:Error) { }
         }
         if(this.hzpReady && now - this.hzpIniT > 5000) { this.hzpRead(); }
         var b:* = this.HoldBreathButton_mc;
         if(!this.hzpReady || !this.hzpOn || b == null)
         {
            this.hzpHideVan(false);
            if(this.hzpChip) { this.hzpChip.visible = false; }
            return;
         }
         var want:Boolean = true;
         try { want = b.Visible == true; } catch(e2:Error) { want = true; }
         this.hzpHideVan(true);
         if(!want || b.stage == null) { this.hzpChip.visible = false; return; }
         var o:Number = this.hzpO2;
         var st:int = this.hzpState(o,now);
         var band:int = this.hzpBand(o);
         var ka:Array = this.hzpKey();
         if(String(ka[0]) != this.hzpKeyTx || ka[1] != this.hzpKeyFace) { this.hzpKeyTx = String(ka[0]); this.hzpKeyFace = ka[1]; }
         var sig:String = this.hzpKeyTx + "|" + this.hzpKeyFace + "|" + this.hzpS.ChipS + "|" + st + "|" + band + "|" + Math.round((o < 0 ? -1 : o) * 120) + "|" + this.hzpS.AccentColor + "|" + this.hzpS.AccentHex + "|" + this.hzpS.CardOpacity + "|" + this.hzpS.TextScale + "|" + this.hzpS.FontFace + "|" + this.hzpS.HeaderStyle;
         if(sig != this.hzpSig) { this.hzpSig = sig; this.hzpDraw(st,band,o); }
         // where the hidden button sits, at its own (counter-scaled) size
         var r:Rectangle = b.getBounds(this);
         if(r != null && r.width > 1 && r.height > 1) { this.hzpLastX = r.x + r.width / 2; this.hzpLastY = r.y + r.height / 2; }
         if(isNaN(this.hzpLastX)) { this.hzpChip.visible = false; return; }
         // r2: [Scope] offset (1080p screen units -> this menu's units = x the button's counter-scale) and size
         var cs:Number = Number(this.hzpS.ChipS);
         if(isNaN(cs) || cs <= 0) { cs = 1; }
         var ox:Number = Number(this.hzpS.ChipX) * b.scaleX;
         var oy:Number = -Number(this.hzpS.ChipY) * b.scaleY;
         if(isNaN(ox)) { ox = 0; }
         if(isNaN(oy)) { oy = 0; }
         this.hzpChip.scaleX = b.scaleX * cs;
         this.hzpChip.scaleY = b.scaleY * cs;
         this.hzpChip.x = Math.round(this.hzpLastX + ox - this.hzpW * this.hzpChip.scaleX / 2);
         this.hzpChip.y = Math.round(this.hzpLastY + oy - this.hzpH * this.hzpChip.scaleY / 2);
         if(this.hzpChip.parent == this && getChildIndex(this.hzpChip) != numChildren - 1) { setChildIndex(this.hzpChip,numChildren - 1); }
         this.hzpChip.visible = true;
      }
      // O2 band, same thresholds as the HUD vitals card (hz26Band): 0 normal, 1 warning (< 35 %), 2 critical (< 15 %)
      private function hzpBand(o:Number) : int
      {
         if(o < 0) { return 0; }
         return o < HZP_O2_CRIT ? 2 : (o < HZP_O2_WARN ? 1 : 0);
      }
      // 0 ready, 1 holding (O2 fell on 2 readings in a row, within 400 ms), 3 out of breath (2 readings under 1 % in a row)
      private function hzpState(o:Number, now:int) : int
      {
         if(o >= 0 && o < 0.01 && this.hzpZeroN >= 2) { return 3; }
         if(now - this.hzpFallT < 400) { return 1; }
         return 0;
      }
      // original target icon (ring, 4 ticks, center dot), drawn in code; 17 px across at 1080p
      private function hzpCross(g:*, cx:Number, cy:Number, col:uint, a:Number) : void
      {
         g.lineStyle(1.6,col,a,true,"none");
         g.drawCircle(cx,cy,6);
         g.moveTo(cx,cy - 8.5); g.lineTo(cx,cy - 3.5);
         g.moveTo(cx,cy + 3.5); g.lineTo(cx,cy + 8.5);
         g.moveTo(cx - 8.5,cy); g.lineTo(cx - 3.5,cy);
         g.moveTo(cx + 3.5,cy); g.lineTo(cx + 8.5,cy);
         g.lineStyle();
         g.beginFill(col,a); g.drawCircle(cx,cy,1.8); g.endFill();
      }
      private function hzpProbe(n:String) : Boolean
      {
         if(this.hzpFontOk[n] != undefined) { return this.hzpFontOk[n] == 1; }
         var ok:Boolean = false;
         try
         {
            var t:TextField = new TextField();
            t.embedFonts = true;
            var tf:TextFormat = new TextFormat(n,20,0xFFFFFF);
            t.defaultTextFormat = tf; t.text = "WMW"; t.setTextFormat(tf);
            ok = t.textWidth > 8;
            if(ok)
            {
               var x:TextField = new TextField();
               x.embedFonts = true;
               var xf:TextFormat = new TextFormat("$Horizon_NoSuchFace_x",20,0xFFFFFF);
               x.defaultTextFormat = xf; x.text = "WMW"; x.setTextFormat(xf);
               if(x.textWidth > 0 && Math.abs(x.textWidth - t.textWidth) < 0.01) { ok = false; }
            }
         }
         catch(err:Error) { ok = false; }
         this.hzpFontOk[n] = ok ? 1 : 0;
         return ok;
      }
      // FontFace: 1 Exo 2, 2 Roboto (both from the Horizon font package), 0 game font, 3 the game face of the prompt label
      private function hzpFace(w:String) : String
      {
         var f:int = int(this.hzpS.FontFace);
         if(f == 2)
         {
            var r:String = w == "bd" ? "$Horizon_Font_Alt_Bold" : "$Horizon_Font_Alt";
            if(this.hzpProbe(r)) { return r; }
            if(this.hzpProbe("$Horizon_Font_Alt")) { return "$Horizon_Font_Alt"; }
         }
         if(f == 1 || f == 2)
         {
            var x:String = w == "bd" ? "$Horizon_Font_Bold" : "$Horizon_Font";
            if(this.hzpProbe(x)) { return x; }
            if(this.hzpProbe("$Horizon_Font")) { return "$Horizon_Font"; }
         }
         if(f == 3)
         {
            try
            {
               var lt:TextField = this.HoldBreathButton_mc.Label_mc.Label_tf as TextField;
               if(lt != null && lt.getTextFormat().font) { return String(lt.getTextFormat().font); }
            }
            catch(e3:Error) { }
         }
         return "$MAIN_Font";
      }
      private function hzpFs(size:Number) : Number
      {
         var ts:Number = Number(this.hzpS.TextScale);
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         if(HZP_LRG) { ts *= 1.1; }
         var cs:Number = Number(this.hzpS.ChipS);
         if(isNaN(cs) || cs <= 0) { cs = 1; }
         // r3: the chip is scaled by ScopeChipScale after drawing: keep 13 px on screen at every size (floor after scaling)
         return Math.max(HZP_MINPX,Math.round(size * ts * 10) / 10,Math.ceil(HZP_MINPX / cs * 10) / 10);
      }
      private function hzpT(p:Sprite, s:String, size:Number, col:uint, w:String, tr:Number, face:String = null) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = TextFieldAutoSize.LEFT;
         var fs:Number = this.hzpFs(size);
         var f:TextFormat = new TextFormat(face != null ? face : this.hzpFace(w),fs,col);
         f.letterSpacing = Math.round(fs * tr * 10) / 10;
         t.defaultTextFormat = f;
         t.text = s;
         t.setTextFormat(f);
         p.addChild(t);
         return t;
      }
      private function hzpCase(s:String) : String
      {
         if(int(this.hzpS.HeaderStyle) != 1) { return s; }
         var w:Array = s.toLowerCase().split(" ");
         var i:int = 0;
         while(i < w.length) { if(String(w[i]).length > 0 && w[i] != "o2") { w[i] = String(w[i]).charAt(0).toUpperCase() + String(w[i]).substr(1); } i++; }
         return w.join(" ").replace("o2","O2");
      }
      // st: 0 ready, 1 holding, 3 out of breath; band: 0 normal, 1 warning (amber), 2 critical (red). o = O2 0 - 1 (-1 = no data)
      private function hzpDraw(st:int, band:int, o:Number) : void
      {
         var p:Sprite = this.hzpChip;
         while(p.numChildren > 0) { p.removeChildAt(0); }
         var g:* = p.graphics;
         g.clear();
         var acc:uint = this.hzpAccent();
         var bc:uint = (st == 3 || band == 2) ? HZP_RED : (band == 1 ? HZP_AMB : HZP_O2);   // meter: HUD O2 colors
         var stc:uint = (st == 3 || band == 2) ? HZP_RED : (band == 1 ? HZP_AMB : acc);
         var keyCol:uint = st == 3 ? HZP_DIM : stc;
         var ts:Number = Math.max(1,Math.min(1.3,Number(this.hzpS.TextScale)));
         if(isNaN(ts)) { ts = 1; }
         var h:Number = Math.round(32 + (ts - 1) * 20);
         var lt:TextField = this.hzpT(p,this.hzpCase(String(HZP_LBL[st])),14,st == 3 ? HZP_DIM : HZP_TXT,"sb",0.1);
         var kt:TextField = null;
         if(this.hzpKeyTx.length > 0) { kt = this.hzpT(p,this.hzpKeyTx,13,keyCol,"bd",0.04,this.hzpKeyFace); }
         h = Math.max(h,Math.round(lt.height + 6),kt != null ? Math.round(kt.height + 6) : 0);
         var kw:Number = 30 + (kt != null ? Math.round(kt.textWidth + 8) : 0);
         var kh:Number = Math.round(h - 12);
         var mw:Number = 120;
         var x0:Number = 7;
         var lx:Number = x0 + kw + 10;
         var mx:Number = Math.round(lx + lt.textWidth + 16);
         var w:Number = Math.round(mx + mw + 14);
         // panel: soft shadow, translucent fill (CardOpacity), 1 px edge; HOLDING = accent edge
         var opa:Number = Number(this.hzpS.CardOpacity);
         if(isNaN(opa)) { opa = 1; }
         var i:int = 0;
         while(i < 3) { g.beginFill(0x000000,0.07); g.drawRoundRect(-1 - i,2 - i * 0.5,w + 2 + i * 2,h + 1 + i * 2,h + i * 2,h + i * 2); g.endFill(); i++; }
         if(st == 3) { g.lineStyle(1,HZP_RED,0.7,true,"none"); }
         else if(band == 2) { g.lineStyle(1.5,HZP_RED,1,true,"none"); }
         else if(band == 1) { g.lineStyle(1.5,HZP_AMB,1,true,"none"); }
         else if(st == 1) { g.lineStyle(1.5,acc,1,true,"none"); }
         else { g.lineStyle(1,0xFFFFFF,0.18,true,"none"); }
         g.beginFill(HZP_BG,Math.min(1,0.84 * opa));
         g.drawRoundRect(0.5,0.5,w - 1,h - 1,h - 1,h - 1);
         g.endFill();
         g.lineStyle();
         if(st == 1 || (band > 0 && st != 3)) { g.lineStyle(4,stc,0.18,true,"none"); g.drawRoundRect(-2,-2,w + 4,h + 4,h + 4,h + 4); g.lineStyle(); }
         // keycap
         var ky:Number = Math.round((h - kh) / 2);
         g.lineStyle(1,keyCol,st == 3 ? 0.5 : 0.95,true,"none");
         g.beginFill(keyCol,st == 1 ? 0.22 : 0.1);
         g.drawRoundRect(x0,ky,kw,kh,8,8);
         g.endFill();
         g.lineStyle();
         this.hzpCross(g,x0 + 15,ky + kh / 2,keyCol,st == 3 ? 0.6 : 1);
         if(kt != null) { kt.x = Math.round(x0 + 28); kt.y = Math.round(h / 2 - kt.height / 2); }
         lt.x = lx - 2;
         lt.y = Math.round(h / 2 - lt.height / 2);
         // slim O2 meter (120 x 6)
         var my:Number = Math.round(h / 2 - 3);
         g.beginFill(0xFFFFFF,0.14); g.drawRoundRect(mx,my,mw,6,6,6); g.endFill();
         if(o > 0 && st != 3)
         {
            var fw:Number = Math.max(3,Math.round(mw * o));
            g.beginFill(bc,1); g.drawRoundRect(mx,my,fw,6,6,6); g.endFill();
         }
         this.hzpW = w;
         this.hzpH = h;
      }
      // =================== end Horizon UI Scope module ===================
