      // =================== Horizon UI quick menu (0.43.3.0, batch f): Horizon cards on the game's quick menu ===================
      // Spliced into the vanilla FavoritesMenu class (favoritesmenu.swf / favoritesmenu_lrg.swf, game 1.16.244) by
      // tools/apply_fav_hooks.py. Every vanilla line stays: input, selection, assign mode, the close animation and the
      // game's own icons and data are the game's code. This block only draws on top and hides vanilla art:
      //  - one card per slot (hzqCard), a child of the slot clip at index 0, so the vanilla Open / Close fades move it too;
      //  - the slot's key badge = the key the player bound to "Quickkey<n>" (ControlMapData vMappedEvents), keyboard and
      //    mouse only, the same rule as the vanilla Quickkey_tf. No key is hardcoded and nothing keys off Q;
      //  - a header pill above the top slot: QUICK MENU and the bound "Cancel" key (keyboard and mouse only);
      //  - an info card in ItemInfo_mc built only from the fields the game sends (FavoritesData aFavoriteItems):
      //    sName (+ " (n)" from uCount), AMMO = sAmmoName + uAmmoCount, DAMAGE = aElementalStats (type + floor(fValue)),
      //    SLOT = the selected slot's bound key. There is no magazine / reserve split in the data, so none is shown.
      // Theme: [Style] AccentColor / AccentHex / CardColor / CardHex / CardOpacity / CardBgOpacity / CardShadow / TextTone /
      // FontFace / TextScale / HeaderStyle / TextShadow, read once when the menu opens, through ports of the HUD card
      // functions (hzCardPal, hzAccPal, hzPanel, hzKeycap, ...). Switch: [Cards Extra] QuickMenuHorizon (1 default,
      // 0 = the game's look: nothing is drawn, hidden or moved).
      // Edge-only: no enterFrame, timer or tree search. Handlers and when they fire:
      //   hzqOpen        menu added to stage (onAddedToStage), once per open: starts the ini read
      //   hzqOnIni       the ini read finished (URLLoader COMPLETE / IO_ERROR): builds once, then one full redraw
      //   hzqFontOkEv    font.marker found (URLLoader COMPLETE), once: one full redraw with the Horizon face
      //   hzqData        FavoritesData (end of onDataUpdate): slot cards
      //   hzqSel         selection change (end of onSelectionChange): slot cards + info card
      //   hzqInfoSet     assign mode start (assignedItem setter): info card
      //   OnControlMapChanged  ControlMapData (device or binding change): key table, key badges, header
      // Every Horizon display object has mouseEnabled = mouseChildren = false; the slots keep their own hit areas
      // (Catcher_mc), so mouse hover and click are the game's. Any error turns the Horizon look off for this open and
      // puts the vanilla look back (hzqFail).
      private static const HZQ_LRG:Boolean = __HZQ_LRG__;
      private static const HZQ_ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZQ_CARDCOLS:Array = [0x0B1218,0x16181C,0x0B1630,0x0A2226,0x1E1328,0x2A1014,0x3A4652,0xD5DBE0,0xF2F4F6,0xCCDFEE,0xF0E0C2,0xD2ECDF];
      private static const HZQ_INNER:Array = [2,3,8,9];   // FS_LEFT_1, FS_RIGHT_1, FS_UP_1, FS_DOWN_1: the slots next to the center disc
      private static const HZQ_INF_W:Number = 380;
      private var hzqOn:Boolean = false;        // Horizon look active for this open (switch on, ini read, no error)
      private var hzqOpened:Boolean = false;
      private var hzqErr:Boolean = false;
      private var hzqS:Object = null;           // [Style] values, read on open
      private var hzqFontLib:int = -1;          // font.marker: -1 checking, 0 absent, 1 present
      private var hzqFontLdr:URLLoader = null;
      private var hzqFontOk:Object = {};
      private var hzqKeys:Object = {};          // user event name -> bound button name (ControlMapData)
      private var hzqKb:Boolean = true;         // keyboard and mouse in use (uiController == 0)
      private var hzqCards:Array = null;        // per slot {s:Sprite, k:TextField, r:Rectangle}
      private var hzqHdr:Sprite = null;
      private var hzqHdrT:TextField = null;
      private var hzqHdrK:TextField = null;
      private var hzqInf:Sprite = null;
      private var hzqInfT:Array = null;         // [name, l1, v1, l2, v2, l3, v3]
      private var hzqInfX:Number = 0;
      private var hzqInfY:Number = 0;
      private var hzqInfObj:Object = null;      // what the info card shows (selected entry, or the item being assigned)
      private var hzqInfSel:Boolean = false;    // hzqInfObj is the selected slot (SLOT row allowed)
      private var hzqCtA:ColorTransform = null; // reused: accent tint for symbol icons
      private var hzqCtM:ColorTransform = null; // reused: main text tint for symbol icons
      private var hzqCtN:ColorTransform = null; // reused: identity (images, and the restore)

      private function hzqOpen() : void
      {
         if(this.hzqOpened) { return; }
         this.hzqOpened = true;
         try { this.hzq37IniRead(this.hzqOnIni); } catch(e:Error) { this.hzqOn = false; }
      }
      private function hzqOnIni(txt:String) : void
      {
         try
         {
            var on:Boolean = true;
            var st:Object = this.hzqParse(txt);
            on = st.On;
            this.hzqS = st;
            if(!on || this.hzqErr) { this.hzqRestore(); return; }
            this.hzqOn = true;
            this.hzqFontBegin();
            this.hzqBuild();
            this.hzqRedraw();
         }
         catch(e:Error) { this.hzqFail(); }
      }
      // defaults = HZ_SET_DEF; ranges = the HUD ini reader (horizon_block.as hzIniApply)
      private function hzqParse(txt:String) : Object
      {
         var st:Object = {"On":true,"AccentColor":0,"AccentHex":-1,"CardColor":0,"CardHex":-1,"CardOpacity":1,"CardBgOpacity":92,"CardShadow":12,"TextTone":0,"FontFace":1,"TextScale":1,"HeaderStyle":0,"TextShadow":false,"HudScale":1};
         if(txt == null) { return st; }
         var sec:String = "";
         for each(var ln:String in this.hzq37Lines(txt))
         {
            var h:String = this.hzq37Hdr(ln);
            if(h != null) { sec = this.hzq37Alias(h); continue; }
            var kv:Object = this.hzq37KV(ln);
            if(kv == null) { continue; }
            var k:String = String(kv.k);
            var v:String = String(kv.v);
            var nv:Number = Number(v);
            var off:Boolean = v == "0" || v.toLowerCase() == "false";
            if(sec == "cards extra")
            {
               if(k == "quickmenuhorizon") { st.On = !off; }
            }
            else if(sec == "style")
            {
               if(k == "accentcolor" && !isNaN(nv)) { st.AccentColor = Math.max(0,Math.min(HZQ_ACCENTS.length,int(nv))); }
               else if(k == "accenthex") { st.AccentHex = this.hzqHex(v); }
               else if(k == "cardcolor" && !isNaN(nv)) { st.CardColor = Math.max(0,Math.min(HZQ_CARDCOLS.length,int(nv))); }
               else if(k == "cardhex") { st.CardHex = this.hzqHex(v); }
               else if(k == "cardopacity" && !isNaN(nv)) { st.CardOpacity = Math.max(0.2,Math.min(1.6,nv)); }
               else if(k == "cardbgopacity") { st.CardBgOpacity = this.hzqPct(v,92); }
               else if(k == "cardshadow") { st.CardShadow = this.hzqPct(v,12); }
               else if(k == "texttone" && !isNaN(nv)) { st.TextTone = Math.max(0,Math.min(2,int(nv))); }
               else if(k == "fontface" && !isNaN(nv)) { st.FontFace = Math.max(0,Math.min(3,int(nv))); }
               else if(k == "textscale" && !isNaN(nv)) { st.TextScale = Math.max(0.8,Math.min(1.3,nv)); }
               else if(k == "headerstyle" && !isNaN(nv)) { st.HeaderStyle = Math.max(0,Math.min(1,int(nv))); }
               else if(k == "textshadow") { st.TextShadow = !off && v.length > 0; }
               else if(k == "hudscale" && !isNaN(nv)) { st.HudScale = Math.max(0.7,Math.min(1.4,nv)); }
            }
         }
         return st;
      }
      private function hzqHex(v:String) : int
      {
         if(v == null) { return -1; }
         v = v.replace(/^\s+|\s+$/g,"").replace("#","").replace("0x","").replace("0X","");
         if(v.length != 6 || !/^[0-9A-Fa-f]{6}$/.test(v)) { return -1; }
         return int(parseInt(v,16));
      }
      private function hzqPct(v:String, def:Number) : Number
      {
         if(v == null) { return def; }
         var t:String = String(v).replace(/^\s+|\s+$/g,"");
         if(t.length == 0) { return def; }
         var n:Number = Number(t);
         if(isNaN(n)) { return def; }
         return Math.max(0,Math.min(100,n));
      }
      // ---------- theme: ports of the HUD card functions (horizon_block.as), same names with hzq ----------
      private function hzqCardPal() : Array
      {
         var a:Array = HZQ_CARDCOLS.concat();
         if(int(this.hzqS.CardHex) >= 0) { a.push(uint(this.hzqS.CardHex)); }
         return a;
      }
      private function hzqAccPal() : Array
      {
         var a:Array = HZQ_ACCENTS.concat();
         if(int(this.hzqS.AccentHex) >= 0) { a.push(uint(this.hzqS.AccentHex)); }
         return a;
      }
      private function hzqAccent() : uint
      {
         var a:Array = this.hzqAccPal();
         return uint(a[Math.max(0,Math.min(a.length - 1,int(this.hzqS.AccentColor)))]);
      }
      private function hzqCardFill() : uint
      {
         var a:Array = this.hzqCardPal();
         return uint(a[Math.max(0,Math.min(a.length - 1,int(this.hzqS.CardColor)))]);
      }
      private function hzqLum(c:uint) : Number
      {
         return (0.2126 * ((c >> 16) & 0xFF) + 0.7152 * ((c >> 8) & 0xFF) + 0.0722 * (c & 0xFF)) / 255;
      }
      private function hzqLight() : Boolean
      {
         return this.hzqLum(this.hzqCardFill()) > 0.55;
      }
      private function hzqDarkText() : Boolean
      {
         if(int(this.hzqS.TextTone) == 1) { return false; }
         if(int(this.hzqS.TextTone) == 2) { return true; }
         return this.hzqLight();
      }
      private function hzqOpExtra() : Number
      {
         return Math.max(0,Math.min(1,(Number(this.hzqS.CardOpacity) - 1) / 0.6));
      }
      private function hzqPanelA() : Number
      {
         var pct:Number = Number(this.hzqS.CardBgOpacity);
         if(isNaN(pct)) { pct = 92; }
         pct = Math.max(0,Math.min(100,pct));
         var a:Number = pct / 100;
         if(Number(this.hzqS.CardOpacity) < 1) { a = a * Math.max(0,Number(this.hzqS.CardOpacity)); }
         return Math.max(0,Math.min(1,a));
      }
      private function hzqCardShA(base:Number) : Number
      {
         var pct:Number = Number(this.hzqS.CardShadow);
         if(isNaN(pct)) { pct = 12; }
         pct = Math.max(0,Math.min(100,pct));
         if(Number(this.hzqS.CardBgOpacity) <= 0) { return 0; }
         return Math.max(0,Math.min(1,base * (pct / 12)));
      }
      private function hzqPanelFill() : uint
      {
         var x:Number = this.hzqOpExtra();
         var f:uint = this.hzqCardFill();
         if(x <= 0) { return f; }
         return this.hzqMix(f,this.hzqLight() ? 0xFFFFFF : 0x000000,x * 0.6);
      }
      private function hzqIconCol(c:uint) : uint
      {
         if(this.hzqDarkText() && this.hzqLum(c) > 0.4) { return this.hzqMix(c,0x000000,0.58); }
         return c;
      }
      private function hzqMix(a:uint, b:uint, t:Number) : uint
      {
         var r:int = int(((a >> 16) & 0xFF) * (1 - t) + ((b >> 16) & 0xFF) * t);
         var g2:int = int(((a >> 8) & 0xFF) * (1 - t) + ((b >> 8) & 0xFF) * t);
         var bl:int = int((a & 0xFF) * (1 - t) + (b & 0xFF) * t);
         return uint((r << 16) | (g2 << 8) | bl);
      }
      private function hzqTextAccent() : uint
      {
         var acc:uint = this.hzqAccent();
         if(this.hzqDarkText() && this.hzqLum(acc) > 0.45) { return this.hzqMix(acc,0x000000,0.55); }
         return acc;
      }
      private function hzqMainCol() : uint { return this.hzqDarkText() ? 0x0E151B : 0xF2F7F9; }
      private function hzqMutCol() : uint { return this.hzqDarkText() ? 0x2E3E46 : 0xB2C0C7; }
      private function hzqDimCol() : uint { return this.hzqDarkText() ? 0x4A5A64 : 0x8E9CA4; }
      // hzPanel: 4 soft shadow rings, a 1 px hairline edge, the card fill at the card opacity
      private function hzqPanel(g:*, x:Number, y:Number, w:Number, h:Number, r:Number, mul:Number) : void
      {
         var lt:Boolean = this.hzqLight();
         var rr:Number = Math.min(r,h / 2);
         var sa:Number = this.hzqCardShA(0.055 * (lt ? 0.55 : 1)) * mul;
         var i:int = 0;
         while(i < 4)
         {
            g.beginFill(0x000000,sa);
            g.drawRoundRect(x - 1 - i,y + 2 - i * 0.5,w + 2 + i * 2,h + 1 + i * 2,(rr + i) * 2,(rr + i) * 2);
            g.endFill();
            i++;
         }
         g.lineStyle(1,lt ? 0x0E1E1C : 0xFFFFFF,(lt ? 0.24 : 0.18) * mul,true,"none");
         g.beginFill(this.hzqPanelFill(),this.hzqPanelA() * mul);
         g.drawRoundRect(x + 0.5,y + 0.5,w - 1,h - 1,rr * 2,rr * 2);
         g.endFill();
         g.lineStyle();
      }
      // hzKeycap + hzKeyCorner: 12 % fill and a ring border in the key color
      private function hzqKeycap(g:*, x:Number, y:Number, w:Number, h:Number, col:uint) : void
      {
         var bt:Number = 1;
         var r:Number = Math.min(h,12) / 2;
         g.lineStyle();
         g.beginFill(col,0.12);
         g.drawRoundRect(x,y,w,h,r * 2,r * 2);
         g.endFill();
         var ri:Number = Math.max(0,r - bt);
         var ov:Number = Math.min(0.5,bt / 2);
         g.beginFill(col,1); g.drawRect(x + r - ov,y,w - 2 * r + 2 * ov,bt); g.endFill();
         g.beginFill(col,1); g.drawRect(x + r - ov,y + h - bt,w - 2 * r + 2 * ov,bt); g.endFill();
         g.beginFill(col,1); g.drawRect(x,y + r - ov,bt,h - 2 * r + 2 * ov); g.endFill();
         g.beginFill(col,1); g.drawRect(x + w - bt,y + r - ov,bt,h - 2 * r + 2 * ov); g.endFill();
         this.hzqKeyCorner(g,x + r,y + r,r,ri,-1,-1,col);
         this.hzqKeyCorner(g,x + w - r,y + r,r,ri,1,-1,col);
         this.hzqKeyCorner(g,x + w - r,y + h - r,r,ri,1,1,col);
         this.hzqKeyCorner(g,x + r,y + h - r,r,ri,-1,1,col);
      }
      private function hzqKeyCorner(g:*, cx:Number, cy:Number, r:Number, ri:Number, sx:int, sy:int, col:uint) : void
      {
         var n:int = 6;
         var i:int = 0;
         g.beginFill(col,1);
         while(i <= n)
         {
            var an:Number = Math.PI / 2 * i / n;
            var px:Number = cx + sx * Math.cos(an) * r;
            var py:Number = cy + sy * Math.sin(an) * r;
            if(i == 0) { g.moveTo(px,py); } else { g.lineTo(px,py); }
            i++;
         }
         i = n;
         while(i >= 0)
         {
            var bn:Number = Math.PI / 2 * i / n;
            g.lineTo(cx + sx * Math.cos(bn) * ri,cy + sy * Math.sin(bn) * ri);
            i--;
         }
         g.lineTo(cx + sx * r,cy);
         g.endFill();
      }
      // hzUC: CAPS, or Title Case when HeaderStyle = 1
      private function hzqUC(s:String) : String
      {
         if(s == null) { return ""; }
         if(int(this.hzqS.HeaderStyle) == 0) { return s.toUpperCase(); }
         var w:Array = s.split(" ");
         var i:int = 0;
         while(i < w.length)
         {
            var ws:String = String(w[i]);
            if(ws.length > 0 && !/[0-9]/.test(ws)) { w[i] = ws.charAt(0).toUpperCase() + ws.substr(1).toLowerCase(); }
            else { w[i] = ws.toUpperCase(); }
            i++;
         }
         return w.join(" ");
      }
      // ---------- fonts (the Scope chip's rule: hzpFace / hzpProbe) ----------
      private function hzqFontBegin() : void
      {
         if(this.hzqFontLdr != null || this.hzqFontLib != -1) { return; }
         var l:URLLoader = new URLLoader();
         this.hzqFontLdr = l;
         l.addEventListener(Event.COMPLETE,this.hzqFontOkEv);
         l.addEventListener(IOErrorEvent.IO_ERROR,this.hzqFontErrEv);
         l.addEventListener("securityError",this.hzqFontErrEv);
         l.load(new URLRequest("HorizonUI/modules/font.marker"));
      }
      private function hzqFontOkEv(e:Event) : void
      {
         this.hzqFontLib = 1;
         this.hzqFontLdr = null;
         try { if(this.hzqOn) { this.hzqRedraw(); } } catch(err:Error) { this.hzqFail(); }
      }
      private function hzqFontErrEv(e:Event) : void
      {
         this.hzqFontLib = 0;
         this.hzqFontLdr = null;
      }
      private function hzqProbe(n:String) : Boolean
      {
         if(this.hzqFontOk[n] != undefined) { return this.hzqFontOk[n] == 1; }
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
         this.hzqFontOk[n] = ok ? 1 : 0;
         return ok;
      }
      // FontFace: 1 $Horizon_Font, 2 $Horizon_Font_Alt (both wait for font.marker), 0 the game font, 3 the game face of the slot key field
      private function hzqFace(w:String) : String
      {
         var f:int = int(this.hzqS.FontFace);
         if(f == 3)
         {
            try { var q:TextField = this.Entry_0.Quickkey_tf; if(q != null && q.getTextFormat().font) { return String(q.getTextFormat().font); } } catch(e3:Error) { }
            return "$MAIN_Font";
         }
         if(f != 1 && f != 2) { return "$MAIN_Font"; }
         if(this.hzqFontLib !== 1) { return "$MAIN_Font"; }
         var want:String;
         if(f == 2 && this.hzqProbe("$Horizon_Font_Alt"))
         {
            want = w == "bd" ? "$Horizon_Font_Alt_Bold" : "$Horizon_Font_Alt";
            if(want == "$Horizon_Font_Alt" || this.hzqProbe(want)) { return want; }
            return "$Horizon_Font_Alt";
         }
         if(!this.hzqProbe("$Horizon_Font")) { return "$MAIN_Font"; }
         want = w == "bd" ? "$Horizon_Font_Bold" : "$Horizon_Font";
         if(want == "$Horizon_Font" || this.hzqProbe(want)) { return want; }
         return "$Horizon_Font";
      }
      private function hzqFs(size:Number) : Number
      {
         var ts:Number = Number(this.hzqS.TextScale);
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         if(HZQ_LRG) { ts *= 1.1; }
         return Math.max(10,Math.round(size * ts * 10) / 10);
      }
      private function hzqTf(p:Sprite) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = TextFieldAutoSize.LEFT;
         p.addChild(t);
         return t;
      }
      // text, size, color, weight, letter spacing (em), header case
      private function hzqSet(t:TextField, s:String, size:Number, col:uint, w:String, tr:Number, hdr:Boolean) : void
      {
         var fs:Number = this.hzqFs(size);
         var f:TextFormat = new TextFormat(this.hzqFace(w),fs,col);
         f.letterSpacing = hdr && int(this.hzqS.HeaderStyle) == 1 ? 0 : Math.round(fs * tr * 10) / 10;
         t.defaultTextFormat = f;
         t.text = s;
         t.setTextFormat(f);
         t.filters = this.hzqS.TextShadow ? [this.hzqDarkText() ? new DropShadowFilter(1.5,90,0xFFFFFF,0.75,2,2,1.6,2) : new DropShadowFilter(1.5,60,0x000000,1,2.5,2.5,2,2)] : [];
      }
      // ---------- build (once per open, after the ini read) ----------
      private function hzqSlot(i:int) : MovieClip
      {
         switch(i)
         {
            case 0: return this.Entry_0;
            case 1: return this.Entry_1;
            case 2: return this.Entry_2;
            case 3: return this.Entry_3;
            case 4: return this.Entry_4;
            case 5: return this.Entry_5;
            case 6: return this.Entry_6;
            case 7: return this.Entry_7;
            case 8: return this.Entry_8;
            case 9: return this.Entry_9;
            case 10: return this.Entry_10;
            case 11: return this.Entry_11;
         }
         return null;
      }
      private function hzqSprite(p:*, at:int) : Sprite
      {
         var s:Sprite = new Sprite();
         s.mouseEnabled = false;
         s.mouseChildren = false;
         if(at >= 0) { p.addChildAt(s,at); } else { p.addChild(s); }
         return s;
      }
      private function hzqBuild() : void
      {
         if(this.hzqCards != null) { return; }
         this.hzqCtA = new ColorTransform();
         this.hzqCtM = new ColorTransform();
         this.hzqCtN = new ColorTransform();
         var cards:Array = [];
         var cb:Rectangle = null;
         var i:int = 0;
         while(i < 12)
         {
            var e:MovieClip = this.hzqSlot(i);
            var r:Rectangle = null;
            if(e != null)
            {
               var c:* = e["Catcher_mc"];
               r = c != null ? c.getBounds(e) : e.getBounds(e);
               r = new Rectangle(r.x + 3,r.y + 3,Math.max(8,r.width - 6),Math.max(8,r.height - 6));
               if(HZQ_INNER.indexOf(i) >= 0 && this.CenterClip_mc != null)
               {
                  cb = this.CenterClip_mc.getBounds(e);
                  this.hzqTrim(r,cb,i);
               }
               var s:Sprite = this.hzqSprite(e,0);
               s.name = "hzqCard";
               var k:TextField = this.hzqTf(s);
               cards.push({"s":s,"k":k,"r":r});
            }
            else { cards.push(null); }
            i++;
         }
         this.hzqCards = cards;
         // header pill: a child of the top slot (FS_UP_3), so it fades with the slots
         if(this.Entry_6 != null && cards[6] != null)
         {
            this.hzqHdr = this.hzqSprite(this.Entry_6,-1);
            this.hzqHdr.name = "hzqHeader";
            this.hzqHdrT = this.hzqTf(this.hzqHdr);
            this.hzqHdrK = this.hzqTf(this.hzqHdr);
         }
         // info card: a child of ItemInfo_mc, centered where the game centers its rows (x = 0), top = the name bar's top
         if(this.ItemInfo_mc != null)
         {
            this.hzqInf = this.hzqSprite(this.ItemInfo_mc,0);
            this.hzqInf.name = "hzqInfo";
            var nb:Rectangle = null;
            try { nb = this.ItemInfo_mc.ItemNameBg_mc.getBounds(this.ItemInfo_mc); } catch(eNb:Error) { nb = null; }
            this.hzqInfX = -HZQ_INF_W / 2;
            this.hzqInfY = nb != null ? nb.y : 0;
            this.hzqInfT = [];
            var j:int = 0;
            while(j < 7) { this.hzqInfT.push(this.hzqTf(this.hzqInf)); j++; }
         }
      }
      // inner slots: keep the card off the center disc (only when that leaves at least 60 % of the slot)
      private function hzqTrim(r:Rectangle, cb:Rectangle, i:int) : void
      {
         var g:Number = 4;
         var w0:Number = r.width;
         var h0:Number = r.height;
         if(i == 2 && r.right > cb.left - g) { var w2:Number = cb.left - g - r.x; if(w2 >= w0 * 0.6) { r.width = w2; } }
         else if(i == 3 && r.left < cb.right + g) { var w3:Number = r.right - (cb.right + g); if(w3 >= w0 * 0.6) { r.x = cb.right + g; r.width = w3; } }
         else if(i == 8 && r.bottom > cb.top - g) { var h8:Number = cb.top - g - r.y; if(h8 >= h0 * 0.6) { r.height = h8; } }
         else if(i == 9 && r.top < cb.bottom + g) { var h9:Number = r.bottom - (cb.bottom + g); if(h9 >= h0 * 0.6) { r.y = cb.bottom + g; r.height = h9; } }
      }
      // ---------- draw ----------
      private function hzqRedraw() : void
      {
         if(!this.hzqOn || this.hzqCards == null) { return; }
         this.hzqTints();
         var i:int = 0;
         while(i < 12) { this.hzqCard(i); i++; }
         this.hzqHeader();
         this.hzqInfo();
      }
      private function hzqTints() : void
      {
         var a:uint = this.hzqIconCol(this.hzqAccent());
         var m:uint = this.hzqMainCol();
         this.hzqCtA.redMultiplier = ((a >> 16) & 0xFF) / 255; this.hzqCtA.greenMultiplier = ((a >> 8) & 0xFF) / 255; this.hzqCtA.blueMultiplier = (a & 0xFF) / 255;
         this.hzqCtM.redMultiplier = ((m >> 16) & 0xFF) / 255; this.hzqCtM.greenMultiplier = ((m >> 8) & 0xFF) / 255; this.hzqCtM.blueMultiplier = (m & 0xFF) / 255;
      }
      private function hzqKey(ev:String) : String
      {
         var k:* = this.hzqKeys[ev];
         if(k == null) { return ""; }
         var t:String = String(k).replace(/^\s+|\s+$/g,"");
         if(t.length == 0 || t == "?" || t.charAt(0) == "$" || t == "null" || t == "undefined") { return ""; }
         return t.length > 10 ? t.substr(0,10).toUpperCase() : t.toUpperCase();
      }
      // hides the slot's vanilla art: its direct children (at most a handful) other than the named parts and the card.
      // Runs on every slot redraw because the Selected / Unselected frames re-create the tier art.
      private function hzqHideArt(e:MovieClip, hide:Boolean) : void
      {
         var n:int = Math.min(e.numChildren,10);
         var i:int = 0;
         while(i < n)
         {
            var d:DisplayObject = e.getChildAt(i);
            var nm:String = d.name;
            if(nm != "Icon_mc" && nm != "Catcher_mc" && nm != "Quickkey_tf" && nm != "SlotInfoSpacer_mc" && nm != "hzqCard" && nm != "hzqHeader") { d.visible = !hide; }
            i++;
         }
         var q:* = e["Quickkey_tf"];
         if(q != null) { q.alpha = hide ? 0 : 1; }
      }
      private function hzqCard(i:int) : void
      {
         var c:Object = this.hzqCards[i];
         var e:MovieClip = this.hzqSlot(i);
         if(c == null || e == null) { return; }
         this.hzqHideArt(e,true);
         var it:Object = this.FavoritesInfoA != null && i < this.FavoritesInfoA.length ? this.FavoritesInfoA[i] : null;
         var empty:Boolean = it == null || it.sName == null || String(it.sName).length == 0;
         var sel:Boolean = i == int(this.selectedIndex);
         var r:Rectangle = c.r;
         var s:Sprite = c.s;
         var g:* = s.graphics;
         g.clear();
         var acc:uint = this.hzqAccent();
         this.hzqPanel(g,r.x,r.y,r.width,r.height,8,empty && !sel ? 0.6 : 1);
         if(sel)
         {
            g.beginFill(acc,0.13);
            g.drawRoundRect(r.x + 1,r.y + 1,r.width - 2,r.height - 2,14,14);
            g.endFill();
            g.lineStyle(2,acc,1,true,"none");
            g.drawRoundRect(r.x + 1,r.y + 1,r.width - 2,r.height - 2,14,14);
            g.lineStyle();
         }
         // key badge: top left, the bound Quickkey<n>, keyboard and mouse only
         var kt:String = this.hzqKb ? this.hzqKey("Quickkey" + (i + 1)) : "";
         var k:TextField = c.k;
         if(kt.length > 0)
         {
            this.hzqSet(k,kt,11,sel ? this.hzqTextAccent() : this.hzqMutCol(),"sb",0.04,false);
            var kw:Number = Math.max(16,Math.ceil(k.textWidth * 1.08) + 8);
            var kh:Number = Math.max(16,Math.ceil(k.textHeight) + 3);
            this.hzqKeycap(g,r.x + 5,r.y + 5,kw,kh,sel ? this.hzqIconCol(acc) : this.hzqDimCol());
            k.x = r.x + 5 + (kw - k.width) / 2;
            k.y = r.y + 5 + (kh - k.height) / 2;
            k.visible = true;
         }
         else { k.visible = false; }
         // the game's icon: symbols take the accent when selected, the main text color otherwise; pictures stay as they are
         var ic:* = e["Icon_mc"];
         if(ic != null)
         {
            var sym:Boolean = !empty && it.iconImage != null && it.iconImage.iFixtureType == ImageFixture.FT_SYMBOL;
            ic.transform.colorTransform = sym ? (sel ? this.hzqCtA : this.hzqCtM) : this.hzqCtN;
         }
      }
      private function hzqHeader() : void
      {
         if(this.hzqHdr == null) { return; }
         var r:Rectangle = this.hzqCards[6].r;
         var g:* = this.hzqHdr.graphics;
         g.clear();
         this.hzqSet(this.hzqHdrT,this.hzqUC("Quick Menu"),12,this.hzqTextAccent(),"bd",0.14,true);
         var kt:String = this.hzqKb ? this.hzqKey("Cancel") : "";
         var pad:Number = 14;
         var h:Number = Math.max(30,Math.ceil(this.hzqHdrT.textHeight) + 14);
         var w:Number = pad + this.hzqHdrT.width + pad;
         var kw:Number = 0;
         var kh:Number = 0;
         if(kt.length > 0)
         {
            this.hzqSet(this.hzqHdrK,kt,11,this.hzqMutCol(),"sb",0.04,false);
            kw = Math.max(16,Math.ceil(this.hzqHdrK.textWidth * 1.08) + 8);
            kh = Math.max(16,Math.ceil(this.hzqHdrK.textHeight) + 3);
            w += kw + 10;
            this.hzqHdrK.visible = true;
         }
         else { this.hzqHdrK.visible = false; }
         var x0:Number = Math.round(r.x + r.width / 2 - w / 2);
         var y0:Number = Math.round(r.y - 10 - h);
         this.hzqPanel(g,x0,y0,w,h,h / 2,1);
         this.hzqHdrT.x = x0 + pad;
         this.hzqHdrT.y = y0 + (h - this.hzqHdrT.height) / 2;
         if(kt.length > 0)
         {
            var kx:Number = x0 + w - pad - kw;
            var ky:Number = y0 + (h - kh) / 2;
            this.hzqKeycap(g,kx,ky,kw,kh,this.hzqDimCol());
            this.hzqHdrK.x = kx + (kw - this.hzqHdrK.width) / 2;
            this.hzqHdrK.y = ky + (kh - this.hzqHdrK.height) / 2;
         }
      }
      private function hzqInfoSet(o:Object, isSel:Boolean) : void
      {
         this.hzqInfObj = o;
         this.hzqInfSel = isSel;
         if(this.hzqOn) { this.hzqInfo(); }
      }
      private function hzqElem(t:int) : String
      {
         var l:String = InventoryItemUtils.GetElementalLabel(t);
         if(l == "physical") { return "PHYS"; }
         if(l == "em") { return "EM"; }
         if(l == "energy") { return "ENERGY"; }
         return "";
      }
      private function hzqInfo() : void
      {
         if(this.hzqInf == null) { return; }
         var o:Object = this.hzqInfObj;
         this.hzqHideInfoVan(true);
         var g:* = this.hzqInf.graphics;
         g.clear();
         var T:Array = this.hzqInfT;
         if(o == null || o.sName == null)
         {
            var z:int = 0;
            while(z < T.length) { TextField(T[z]).visible = false; z++; }
            return;
         }
         var W:Number = HZQ_INF_W;
         var P:Number = 16;
         var acc:uint = this.hzqAccent();
         var empty:Boolean = String(o.sName).length == 0;
         // name: the game's string ($EMPTY SLOT is translated by GlobalFunc.SetText), + " (n)" like the game
         var nt:TextField = T[0];
         this.hzqSet(nt," ",17,empty ? this.hzqDimCol() : this.hzqMainCol(),"bd",0.04,false);
         GlobalFunc.SetText(nt,empty ? "$EMPTY SLOT" : String(o.sName),false);
         if(!empty && uint(o.uCount) > 1) { nt.appendText(" (" + uint(o.uCount) + ")"); }
         nt.autoSize = TextFieldAutoSize.NONE;
         nt.wordWrap = true;
         nt.multiline = true;
         nt.width = W - P * 2;
         nt.height = Math.ceil(nt.textHeight) + 4;
         nt.x = this.hzqInfX + P;
         nt.y = this.hzqInfY + 12;
         nt.visible = true;
         var rows:Array = [];
         if(!empty && o.bIsEquippable && o.sAmmoName != null && String(o.sAmmoName).length > 0)
         {
            var n:uint = uint(o.uAmmoCount);
            rows.push(["AMMO",String(o.sAmmoName) + "  " + (n > 999 ? "999+" : String(n))]);
         }
         if(!empty && o.bIsEquippable && o.aElementalStats != null && o.aElementalStats.length > 0)
         {
            var d:Array = [];
            var q:int = 0;
            while(q < o.aElementalStats.length && q < 4)
            {
               var lb:String = this.hzqElem(int(o.aElementalStats[q].iElementalType));
               if(lb.length > 0) { d.push(lb + " " + Math.floor(Number(o.aElementalStats[q].fValue))); }
               q++;
            }
            if(d.length > 0) { rows.push(["DAMAGE",d.join("   ")]); }
         }
         if(this.hzqInfSel && this.hzqKb)
         {
            var sk:String = this.hzqKey("Quickkey" + (int(this.selectedIndex) + 1));
            if(sk.length > 0) { rows.push(["SLOT",sk]); }
         }
         var y:Number = nt.y + nt.height + (rows.length > 0 ? 8 : 4);
         var div:Number = y - 4;
         var j:int = 0;
         while(j < 3)
         {
            var lt:TextField = T[1 + j * 2];
            var vt:TextField = T[2 + j * 2];
            if(j < rows.length)
            {
               this.hzqSet(lt,this.hzqUC(String(rows[j][0])),10.5,this.hzqDimCol(),"sb",0.14,true);
               this.hzqSet(vt,String(rows[j][1]),13,this.hzqMainCol(),"sb",0.02,false);
               lt.x = this.hzqInfX + P; lt.y = y + (vt.height - lt.height) / 2;
               vt.x = this.hzqInfX + W - P - vt.width; vt.y = y;
               lt.visible = true; vt.visible = true;
               y += vt.height + 2;
            }
            else { lt.visible = false; vt.visible = false; }
            j++;
         }
         var H:Number = Math.ceil(y - this.hzqInfY + 10);
         this.hzqPanel(g,this.hzqInfX,this.hzqInfY,W,H,10,1);
         // the accent bar on the left edge (hzAccStripe on tall cards; this card is short, so a slim bar the card's height)
         g.beginFill(this.hzqIconCol(acc),1);
         g.drawRoundRect(this.hzqInfX,this.hzqInfY + 10,3,Math.max(8,H - 20),3,3);
         g.endFill();
         if(rows.length > 0)
         {
            g.beginFill(this.hzqLight() ? 0x0E1E1C : 0xFFFFFF,0.1);
            g.drawRect(this.hzqInfX + P,div,W - P * 2,1);
            g.endFill();
         }
      }
      private function hzqHideInfoVan(hide:Boolean) : void
      {
         var a:Number = hide ? 0 : 1;
         var m:* = this.ItemInfo_mc;
         if(m == null) { return; }
         if(m.ItemNameBg_mc != null) { m.ItemNameBg_mc.alpha = a; }
         if(m.ItemName_mc != null) { m.ItemName_mc.alpha = a; }
         if(m.AmmoType_mc != null) { m.AmmoType_mc.alpha = a; }
         if(m.AmmoAmount_mc != null) { m.AmmoAmount_mc.alpha = a; }
         if(m.DamageTypeHolder_mc != null) { m.DamageTypeHolder_mc.alpha = a; }
      }
      // ---------- hooks ----------
      private function hzqData() : void
      {
         if(!this.hzqOn) { return; }
         try { var i:int = 0; while(i < 12) { this.hzqCard(i); i++; } } catch(e:Error) { this.hzqFail(); }
      }
      private function hzqSel() : void
      {
         this.hzqInfObj = this.selectedEntry;
         this.hzqInfSel = true;
         if(!this.hzqOn) { return; }
         try { var i:int = 0; while(i < 12) { this.hzqCard(i); i++; } this.hzqInfo(); } catch(e:Error) { this.hzqFail(); }
      }
      private function hzqAssign() : void
      {
         try { this.hzqInfoSet(this.AssignedItem,false); } catch(e:Error) { this.hzqFail(); }
      }
      override protected function OnControlMapChanged(param1:Object) : void
      {
         super.OnControlMapChanged(param1);
         try { this.hzqCtl(param1); } catch(e:Error) { this.hzqFail(); }
      }
      // ControlMapData: the bound key names (one pass over vMappedEvents per change) and the device
      private function hzqCtl(d:Object) : void
      {
         if(d == null) { return; }
         this.hzqKb = uint(d.uiController) == PlatformUtils.PLATFORM_PC_KB_MOUSE;
         if(d.vMappedEvents != null)
         {
            var t:Object = {};
            for each(var m:* in d.vMappedEvents)
            {
               if(m != null && m.strUserEventName != null && t[String(m.strUserEventName)] == undefined) { t[String(m.strUserEventName)] = m.strButtonName; }
            }
            this.hzqKeys = t;
         }
         if(this.hzqOn) { this.hzqRedraw(); }
      }
      // ---------- off / error: the game's look ----------
      private function hzqRestore() : void
      {
         this.hzqOn = false;
         if(this.hzqCards == null) { return; }
         var i:int = 0;
         while(i < 12)
         {
            var e:MovieClip = this.hzqSlot(i);
            var c:Object = this.hzqCards[i];
            if(e != null) { try { this.hzqHideArt(e,false); } catch(e1:Error) { } }
            if(c != null) { c.s.visible = false; }
            if(e != null && this.hzqCtN != null) { try { if(e["Icon_mc"] != null) { e["Icon_mc"].transform.colorTransform = this.hzqCtN; } } catch(e2:Error) { } }
            i++;
         }
         if(this.hzqHdr != null) { this.hzqHdr.visible = false; }
         if(this.hzqInf != null) { this.hzqInf.visible = false; }
         try { this.hzqHideInfoVan(false); } catch(e3:Error) { }
      }
      private function hzqFail() : void
      {
         this.hzqErr = true;
         try { this.hzqRestore(); } catch(e:Error) { }
      }
