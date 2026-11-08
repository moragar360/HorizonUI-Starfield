package
{
   import flash.display.Graphics;
   import flash.text.TextField;

   // Purpose: the Settings panel from gold mockup 9: accent, follow the HUD accent, custom hex,
   //    card opacity, screen margin, UI scale, density, group by maker, remember layout, Arrange,
   //    which panels open expanded, keys, the conflict notice and About.
   // Inputs: the builder's current settings; pointer, wheel, keys and typed characters.
   // Outputs: every change applies at once and queues a SET line; Done or closing writes them
   //    (SET END, merged by the DLL into HorizonShipBuilder.user.ini). Undo puts back the
   //    values from when the panel opened; Reset puts back the defaults after a confirm.
   // Dependencies: HorizonShipBuilder (settings fields, setSetting, saveSettings, restyle,
   //    place, setCollapsed, openArrange, keyClash, popups, text input), HsbDialog, HsbKit.
   // Backend limits shown here: "Open Flight Check on errors" has no game signal until Flight
   //    Check runs, so it is shown switched off and cannot be turned on.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbSettings extends HsbBox
   {
      private static const PANEL_ROWS:Array = [["Power","Power"],["Module","Selected module"],["Credits","Credits"],["Browser","Browser"],["Stats","Stats"],["Hints","Hints"]];
      private static const OPACITY_MIN:Number = 0.4;
      private static const MARGIN_MAX:int = 120;
      private static const MARGIN_STEP:int = 2;
      private static const SCALE_MIN:Number = 0.8;
      private static const SCALE_MAX:Number = 1.3;
      private static const STEP:Number = 0.05;

      private var hsb:HorizonShipBuilder;
      private var before:Object;
      private var saveNote:String = "";
      private var editing:String = "";
      private var editText:String = "";
      private var hoverRow:String = "";
      private var scroll:Number = 0;
      private var fullH:Number = 0;
      private var trackX:Number = 0;
      private var trackW:Number = 0;
      private var dragging:Boolean = false;

      public function HsbSettings(param1:HsbKit, param2:HorizonShipBuilder)
      {
         super(param1,"HsbSettings");
         this.hsb = param2;
         this.before = this.snapshot();
         this.paint();
      }

      private function snapshot():Object
      {
         var h:HorizonShipBuilder = this.hsb;
         var open:Object = {};
         var i:int = 0;
         while(i < PANEL_ROWS.length)
         {
            var id:String = String(PANEL_ROWS[i][0]);
            open[id] = h.collapsed[id] != true;
            i++;
         }
         return {"accent":h.accent,"hex":h.accentHex,"follow":h.follow,"opacity":h.opacity,"margin":h.margin,"scale":h.uiScale,"density":h.density,"bymaker":h.byMaker,"remember":h.rememberLayout,"notice":h.showConflict,"keyhide":h.keyHide,"keyfind":h.keyFind,"open":open};
      }

      // Purpose: show whether the last write reached the ini. Inputs: "" or a message.
      internal function setSaveNote(param1:String):void
      {
         this.saveNote = param1 != null ? param1 : "";
         this.paint();
      }

      // ---- paint ---------------------------------------------------------------------------

      internal function paint():void
      {
         this.wipe();
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var h:HorizonShipBuilder = this.hsb;
         var w:Number = k.u(516);
         var view:Object = h.viewRect();
         var maxH:Number = Number(view.height) / Math.max(0.5,this.scaleY) - 40;
         var x0:Number = 20;
         var rowX:Number = 28;
         var right:Number = w - 26;
         var pitch:Number = k.u(21);
         k.icon(g,"gear",14,13,k.u(20),k.accent,1);
         k.label(this,40 + (k.u(20) - 20),12,"SETTINGS",17,k.accent,true,2);
         var esc:TextField = k.text(13,k.accent,true,0,"right");
         k.put(esc,"ESC");
         esc.width = 50;
         this.add(esc,w - 18 - 50,15);
         this.hit(w - 18 - 50,8,58,k.u(30),"done");
         var headH:Number = k.u(44);
         k.hline(g,12,headH,w - 24,HsbKit.EDGE,1);
         var footH:Number = k.u(58) + (this.saveNote.length > 0 ? k.u(22) : 0);
         var bodyTop:Number = headH + 6;
         var y:Number = bodyTop - this.scroll;
         var limit:Number = maxH - footH;
         // Rows are drawn top to bottom; anything scrolled above bodyTop or below limit is
         // skipped, so the body scrolls with the wheel when the panel is taller than the view.
         y = this.head(x0,y,"APPEARANCE",bodyTop,limit);
         y = this.text1(rowX,y,"Accent",HsbKit.TEXT,bodyTop,limit);
         y = this.swatches(rowX,y,bodyTop,limit);
         y = this.toggleRow(rowX,right,y,"Follow Horizon HUD accent","follow",h.follow && h.coreFound,h.coreFound,h.coreFound ? "" : "HUD not found",bodyTop,limit);
         y = this.hexRow(rowX,right,y,bodyTop,limit);
         y = this.sliderRow(rowX,right,y,bodyTop,limit);
         y = this.head(x0,y,"LAYOUT",bodyTop,limit);
         y = this.valueRow(rowX,right,y,"Screen margin",String(h.margin),"margin",bodyTop,limit);
         y = this.valueRow(rowX,right,y,"UI scale",h.uiScale.toFixed(2).replace(/0$/,""),"scale",bodyTop,limit);
         y = this.valueRow(rowX,right,y,"Density",h.density == "detailed" ? "Detailed" : "Compact","density",bodyTop,limit);
         y = this.toggleRow(rowX,right,y,"Group by maker","bymaker",h.byMaker,true,"",bodyTop,limit);
         y = this.toggleRow(rowX,right,y,"Remember my layout","remember",h.rememberLayout,true,"",bodyTop,limit);
         if(this.inside(y + 2,k.u(30),bodyTop,limit))
         {
            var bw:Number = right - rowX + 4;
            k.fill(g,rowX,y + 2,bw,k.u(28),k.u(14),0x14191E,1);
            k.outline(g,rowX,y + 2,bw,k.u(28),k.u(14),k.accent,1);
            var at:TextField = k.text(14,HsbKit.TEXT,true,0.5,"center");
            k.put(at,"Arrange panels");
            at.width = bw;
            this.add(at,rowX,y + 2 + (k.u(28) - at.textHeight - 6) / 2);
            this.hit(rowX,y + 2,bw,k.u(28),"arrange");
         }
         y += k.u(36);
         y = this.head(x0,y,"PANELS",bodyTop,limit);
         var i:int = 0;
         while(i < PANEL_ROWS.length)
         {
            var pid:String = String(PANEL_ROWS[i][0]);
            y = this.toggleRow(rowX,right,y,String(PANEL_ROWS[i][1]),"panel:" + pid,h.collapsed[pid] != true,true,"",bodyTop,limit);
            i++;
         }
         y = this.toggleRow(rowX,right,y,"Open Flight Check on errors","autoflight",false,false,"No game signal",bodyTop,limit);
         y = this.head(x0,y,"COLUMNS",bodyTop,limit);
         y = this.text1(rowX,y,"Per-tab sets are edited in the builder.",HsbKit.LABEL,bodyTop,limit);
         var b:HsbBrowser = h.browser;
         if(b != null && b.tabLabel().length > 0)
         {
            var names:Array = [];
            var cols:Array = b.columns();
            var c:int = 0;
            while(c < cols.length) { names.push(b.columnLabel(String(cols[c]))); c++; }
            y = this.text1(rowX,y,b.tabLabel() + ": " + names.join(", "),HsbKit.TEXT,bodyTop,limit);
         }
         y = this.head(x0,y,"KEYS",bodyTop,limit);
         y = this.keyRow(rowX,right,y,"Hide all","keyhide",h.keyHide,bodyTop,limit);
         y = this.keyRow(rowX,right,y,"Find","keyfind",h.keyFind,bodyTop,limit);
         y = this.head(x0,y,"NOTICES",bodyTop,limit);
         y = this.toggleRow(rowX,right,y,"Warn if another ship builder mod is found","notice",h.showConflict,true,"",bodyTop,limit);
         y = this.head(x0,y,"ABOUT",bodyTop,limit);
         y = this.text1(rowX,y,"Horizon Ship Builder \u00B7 " + HorizonShipBuilder.VERSION,HsbKit.TEXT,bodyTop,limit);
         y = this.text1(rowX,y,"Makers and sizes: read from part names \u00B7 Core: " + (h.coreFound ? "found" : "not found"),HsbKit.MUTED,bodyTop,limit);
         this.fullH = y + this.scroll - bodyTop + 10;
         var bodyRoom:Number = limit - bodyTop;
         var panelH:Number = Math.min(maxH,bodyTop + Math.max(this.fullH,k.u(120)) + footH);
         if(this.fullH <= bodyRoom) { this.scroll = 0; }
         else
         {
            var frac:Number = bodyRoom / this.fullH;
            var thumbH:Number = Math.max(20,bodyRoom * frac);
            var thumbY:Number = bodyTop + (bodyRoom - thumbH) * (this.scroll / Math.max(1,this.fullH - bodyRoom));
            k.fill(g,w - 8,bodyTop,3,bodyRoom,1.5,0x1D2328,1);
            k.fill(g,w - 8,thumbY,3,thumbH,1.5,0x59626A,1);
         }
         var fy:Number = panelH - footH;
         k.hline(g,12,fy,w - 24,HsbKit.EDGE,1);
         fy += 12;
         if(this.saveNote.length > 0)
         {
            k.label(this,x0,fy - 2,this.saveNote,13,HsbKit.RED,false,0,w - x0 * 2);
            fy += k.u(22);
         }
         var btnH:Number = k.u(32);
         k.button(this,x0 - 2,fy + 3,"Reset all settings","red","reset",null,k.u(26));
         var undo:TextField = k.text(14,HsbKit.TEXT);
         k.put(undo,"Undo changes");
         k.fit(undo);
         this.add(undo,x0 + k.u(172),fy + (btnH - undo.height) / 2);
         this.hit(x0 + k.u(166),fy,undo.width + 12,btnH,"undo");
         k.button(this,w - 18 - k.u(90),fy,"DONE","accent","done",null,btnH,k.u(90));
         k.card(this.graphics,0,0,w,panelH,14);
         this.boxW = w;
         this.boxH = panelH;
         this.drawFocus();
      }

      private function inside(param1:Number, param2:Number, param3:Number, param4:Number):Boolean
      {
         return param1 >= param3 - 1 && param1 + param2 <= param4 + 1;
      }

      private function head(param1:Number, param2:Number, param3:String, param4:Number, param5:Number):Number
      {
         var k:HsbKit = this.kit;
         var h:Number = k.u(22);
         if(this.inside(param2 + 2,h - 2,param4,param5)) { k.label(this,param1,param2 + 2,param3,14,k.accent,true,1.5); }
         return param2 + h;
      }

      private function text1(param1:Number, param2:Number, param3:String, param4:uint, param5:Number, param6:Number):Number
      {
         var k:HsbKit = this.kit;
         var h:Number = k.u(21);
         if(this.inside(param2,h,param5,param6)) { k.label(this,param1,param2,param3,14,param4,false,0,k.u(470)); }
         return param2 + h;
      }

      // Thirteen accents in two rows (7 + 6), as in the HUD's own settings.
      private function swatches(param1:Number, param2:Number, param3:Number, param4:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var s:Number = k.u(18);
         var gap:Number = 8;
         var y:Number = param2 + 2;
         var i:int = 0;
         while(i < HorizonShipBuilder.ACCENTS.length)
         {
            var row:int = i < 7 ? 0 : 1;
            var col:int = i < 7 ? i : i - 7;
            var sx:Number = param1 + col * (s + gap);
            var sy:Number = y + row * (s + 4);
            if(this.inside(sy,s,param3,param4))
            {
               var color:uint = uint(HorizonShipBuilder.ACCENTS[i]);
               k.fill(g,sx,sy,s,s,4,color,1);
               var chosen:Boolean = !this.hsb.follow && this.hsb.accent == i;
               if(chosen)
               {
                  k.outline(g,sx - 3,sy - 3,s + 6,s + 6,6,HsbKit.TEXT,1,2);
                  k.outline(g,sx - 1,sy - 1,s + 2,s + 2,5,HsbKit.FILL,1,1);
               }
               this.hit(sx - 3,sy - 2,s + 6,s + 4,"swatch",i);
            }
            i++;
         }
         return y + (s + 4) * 2 + 2;
      }

      private function toggleRow(param1:Number, param2:Number, param3:Number, param4:String, param5:String, param6:Boolean, param7:Boolean, param8:String, param9:Number, param10:Number):Number
      {
         var k:HsbKit = this.kit;
         var h:Number = k.u(21);
         if(!this.inside(param3,h,param9,param10)) { return param3 + h; }
         var label:TextField = k.label(this,param1,param3,param4,14,param7 ? HsbKit.TEXT : HsbKit.MUTED,false,0,k.u(330));
         var tw:Number = k.u(36);
         var th:Number = k.u(16);
         if(param8.length > 0)
         {
            var note:TextField = k.text(12,HsbKit.ORANGE,false,0,"right");
            k.put(note,param8);
            note.width = 130;
            this.add(note,param2 - tw - 10 - 130,param3 + 2);
         }
         this.smallToggle(param2 - tw,param3 + (h - th) / 2,param6,param7);
         if(param7) { this.hit(param1 - 4,param3,param2 - param1 + 8,h,"toggle",param5); }
         return param3 + h;
      }

      // The settings switches are slimmer than the browser's (36 x 16 in mockup 9).
      private function smallToggle(param1:Number, param2:Number, param3:Boolean, param4:Boolean):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var w:Number = k.u(36);
         var h:Number = k.u(16);
         var on:uint = param4 ? k.accent : HsbKit.mix(k.accent,HsbKit.FILL,0.45);
         k.fill(g,param1,param2,w,h,h / 2,param3 ? on : 0x3A4148,1);
         var knob:Number = h - 4;
         k.fill(g,param3 ? param1 + w - knob - 2 : param1 + 2,param2 + 2,knob,knob,knob / 2,param3 ? HsbKit.INK_ON_ACCENT : 0xC7CDD1,1);
      }

      private function hexRow(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var h:Number = k.u(21);
         if(!this.inside(param3,h,param4,param5)) { return param3 + h; }
         k.label(this,param1,param3,"Custom hex",14,HsbKit.TEXT);
         var fx:Number = param1 + k.u(112);
         var fw:Number = k.u(108);
         var on:Boolean = this.editing == "hex";
         k.fill(g,fx,param3,fw,h - 2,4,HsbKit.FIELD,1);
         k.outline(g,fx,param3,fw,h - 2,4,on ? k.accent : HsbKit.EDGE_HI,1);
         var shown:String = on ? "#" + this.editText + "|" : "#" + HsbKit.hex6(this.hsb.accentColor());
         k.label(this,fx + 6,param3 + (h - 2 - k.u(20)) / 2,shown,13,k.accent);
         this.hit(fx,param3,fw,h,"hex");
         if(on) { k.label(this,fx + fw + 10,param3 + 1,"6 hex digits \u00B7 Enter",12,HsbKit.MUTED); }
         return param3 + h;
      }

      private function sliderRow(param1:Number, param2:Number, param3:Number, param4:Number, param5:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var h:Number = k.u(22);
         if(!this.inside(param3,h,param4,param5)) { return param3 + h; }
         k.label(this,param1,param3,"Card opacity",14,HsbKit.TEXT);
         this.trackX = param1 + k.u(132);
         this.trackW = param2 - this.trackX - k.u(80);
         var ty:Number = param3 + h / 2 - 2;
         var frac:Number = (this.hsb.opacity - OPACITY_MIN) / (1 - OPACITY_MIN);
         k.fill(g,this.trackX,ty,this.trackW,4,2,0x2A3238,1);
         k.fill(g,this.trackX,ty,this.trackW * frac,4,2,k.accent,1);
         var kr:Number = k.u(6);
         k.fill(g,this.trackX + this.trackW * frac - kr,ty + 2 - kr,kr * 2,kr * 2,kr,HsbKit.TEXT,1);
         var vt:TextField = k.text(14,HsbKit.TEXT,false,0,"right");
         k.put(vt,this.hsb.opacity.toFixed(2).replace(/0$/,""));
         vt.width = 60;
         this.add(vt,param2 - 60,param3);
         this.hit(this.trackX - 8,param3,this.trackW + 16,h,"opacity");
         return param3 + h;
      }

      // Values show plain, as drawn; arrows appear on the hovered or focused row.
      private function valueRow(param1:Number, param2:Number, param3:Number, param4:String, param5:String, param6:String, param7:Number, param8:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var h:Number = k.u(21);
         if(!this.inside(param3,h,param7,param8)) { return param3 + h; }
         k.label(this,param1,param3,param4,14,HsbKit.TEXT);
         var focused:Object = this.focusedHit();
         var live:Boolean = this.hoverRow == param6 || (focused != null && String(focused.data) == param6);
         var vt:TextField = k.text(14,HsbKit.TEXT,false,0,"right");
         k.put(vt,param5);
         vt.width = 120;
         var vx:Number = param2 - (live ? 18 : 0) - 120;
         this.add(vt,vx,param3);
         if(live)
         {
            k.icon(g,"chevL",vx + 120 - vt.textWidth - 22,param3 + (h - 14) / 2,14,k.accent,1);
            k.icon(g,"chevR",param2 - 14,param3 + (h - 14) / 2,14,k.accent,1);
         }
         var mid:Number = param2 - 70;
         this.hit(param1 - 4,param3,mid - param1 + 4,h,"less",param6);
         this.hit(mid,param3,param2 - mid + 4,h,"more",param6);
         return param3 + h;
      }

      private function keyRow(param1:Number, param2:Number, param3:Number, param4:String, param5:String, param6:String, param7:Number, param8:Number):Number
      {
         var k:HsbKit = this.kit;
         var h:Number = k.u(21);
         if(!this.inside(param3,h,param7,param8)) { return param3 + h; }
         k.label(this,param1,param3,param4,14,HsbKit.TEXT);
         var on:Boolean = this.editing == param5;
         var shown:String = on ? "Press a key \u00B7 Del turns it off" : (param6.length > 0 && param6 != "0" ? param6 : "Off");
         var vt:TextField = k.text(14,on ? k.accent : HsbKit.TEXT,false,0,"right");
         k.put(vt,shown);
         vt.width = 260;
         this.add(vt,param2 - 260,param3);
         var clash:String = on ? "" : this.hsb.keyClash(param6);
         if(clash.length > 0) { k.label(this,param1 + k.u(80),param3 + 1,"Game also uses this key \u00B7 Horizon leaves it alone",12,HsbKit.ORANGE,false,0,k.u(300)); }
         this.hit(param1 - 4,param3,param2 - param1 + 8,h,"key",param5);
         return param3 + h;
      }

      // ---- changes -------------------------------------------------------------------------

      private function setAccent(param1:int, param2:String):void
      {
         var h:HorizonShipBuilder = this.hsb;
         h.follow = false;
         h.accent = param1;
         if(param1 == 13) { h.accentHex = param2; h.setSetting("Style","AccentHex",param2); }
         h.setSetting("Style","AccentColor",String(param1));
         h.restyle();
      }

      private function setOpacity(param1:Number):void
      {
         var v:Number = Math.round(HorizonShipBuilder.clampNum(param1,OPACITY_MIN,1,1) / STEP) * STEP;
         this.hsb.opacity = Number(v.toFixed(2));
         this.hsb.setSetting("Style","CardOpacity",this.hsb.opacity.toFixed(2));
         this.hsb.restyle();
      }

      private function step(param1:String, param2:int):void
      {
         var h:HorizonShipBuilder = this.hsb;
         if(param1 == "margin")
         {
            h.margin = HorizonShipBuilder.clampInt(h.margin + param2 * MARGIN_STEP,0,MARGIN_MAX);
            h.setSetting("Layout","ScreenMargin",String(h.margin));
         }
         else if(param1 == "scale")
         {
            var s:Number = Math.round((h.uiScale + param2 * STEP) * 100) / 100;
            h.uiScale = HorizonShipBuilder.clampNum(s,SCALE_MIN,SCALE_MAX,1);
            h.setSetting("Layout","UiScale",h.uiScale.toFixed(2));
            this.scaleX = h.uiScale;
            this.scaleY = h.uiScale;
         }
         else if(param1 == "density")
         {
            h.density = h.density == "detailed" ? "compact" : "detailed";
            h.setSetting("Layout","Density",h.density);
         }
         h.restyle();
         h.place();
      }

      private function flip(param1:String):void
      {
         var h:HorizonShipBuilder = this.hsb;
         if(param1 == "follow")
         {
            h.follow = !h.follow;
            h.setSetting("Style","AccentColor",h.follow ? "-1" : String(h.accent));
            h.restyle();
         }
         else if(param1 == "bymaker")
         {
            h.byMaker = !h.byMaker;
            h.setSetting("Layout","GroupByMaker",h.byMaker ? "1" : "0");
            h.browser.afterPills();
         }
         else if(param1 == "remember")
         {
            h.rememberLayout = !h.rememberLayout;
            h.setSetting("Layout","RememberLayout",h.rememberLayout ? "1" : "0");
         }
         else if(param1 == "notice")
         {
            h.showConflict = !h.showConflict;
            h.setSetting("Notices","ShowConflictNotice",h.showConflict ? "1" : "0");
            h.browser.invalidate();
         }
         else if(param1.indexOf("panel:") == 0)
         {
            var id:String = param1.substring(6);
            var open:Boolean = h.collapsed[id] == true;
            h.setCollapsed(id,!open);
            h.startOpen[id] = open;
            h.setSetting("Panels",id,open ? "1" : "0");
         }
      }

      private function setKey(param1:String, param2:String):void
      {
         var h:HorizonShipBuilder = this.hsb;
         if(param1 == "keyhide")
         {
            h.keyHide = param2;
            h.setSetting("Keys","HideAll",param2);
         }
         else
         {
            h.keyFind = param2;
            h.setSetting("Keys","Find",param2);
         }
         h.markAll();
      }

      private function undo():void
      {
         var b:Object = this.before;
         var h:HorizonShipBuilder = this.hsb;
         if(b.follow != h.follow || b.accent != h.accent || b.hex != h.accentHex)
         {
            h.accent = int(b.accent);
            h.accentHex = String(b.hex);
            h.follow = b.follow == true;
            if(h.accent == 13) { h.setSetting("Style","AccentHex",h.accentHex); }
            h.setSetting("Style","AccentColor",h.follow ? "-1" : String(h.accent));
         }
         if(b.opacity != h.opacity) { h.opacity = Number(b.opacity); h.setSetting("Style","CardOpacity",h.opacity.toFixed(2)); }
         if(b.margin != h.margin) { h.margin = int(b.margin); h.setSetting("Layout","ScreenMargin",String(h.margin)); }
         if(b.scale != h.uiScale) { h.uiScale = Number(b.scale); h.setSetting("Layout","UiScale",h.uiScale.toFixed(2)); }
         if(b.density != h.density) { h.density = String(b.density); h.setSetting("Layout","Density",h.density); }
         if(b.bymaker != h.byMaker) { h.byMaker = b.bymaker == true; h.setSetting("Layout","GroupByMaker",h.byMaker ? "1" : "0"); }
         if(b.remember != h.rememberLayout) { h.rememberLayout = b.remember == true; h.setSetting("Layout","RememberLayout",h.rememberLayout ? "1" : "0"); }
         if(b.notice != h.showConflict) { h.showConflict = b.notice == true; h.setSetting("Notices","ShowConflictNotice",h.showConflict ? "1" : "0"); }
         if(b.keyhide != h.keyHide) { h.keyHide = String(b.keyhide); h.setSetting("Keys","HideAll",h.keyHide); }
         if(b.keyfind != h.keyFind) { h.keyFind = String(b.keyfind); h.setSetting("Keys","Find",h.keyFind); }
         var i:int = 0;
         while(i < PANEL_ROWS.length)
         {
            var id:String = String(PANEL_ROWS[i][0]);
            var wasOpen:Boolean = b.open[id] == true;
            if(wasOpen != (h.collapsed[id] != true))
            {
               h.setCollapsed(id,!wasOpen);
               h.setSetting("Panels",id,wasOpen ? "1" : "0");
            }
            i++;
         }
         this.scaleX = h.uiScale;
         this.scaleY = h.uiScale;
         h.restyle();
         h.browser.afterPills();
         h.place();
         h.note("SETTINGS undo");
      }

      // Defaults match HorizonShipBuilder.default.ini.
      private function resetAll():void
      {
         var h:HorizonShipBuilder = this.hsb;
         h.follow = false;
         h.accent = 9;
         h.accentHex = "";
         h.opacity = 1;
         h.margin = 34;
         h.uiScale = 1;
         h.density = "compact";
         h.byMaker = false;
         h.rememberLayout = true;
         h.showConflict = true;
         h.keyHide = "H";
         h.keyFind = "/";
         var pairs:Array = [["Style","AccentColor","9"],["Style","AccentHex",""],["Style","CardOpacity","1.00"],["Layout","ScreenMargin","34"],["Layout","UiScale","1.00"],["Layout","Density","compact"],["Layout","GroupByMaker","0"],["Layout","RememberLayout","1"],["Notices","ShowConflictNotice","1"],["Keys","HideAll","H"],["Keys","Find","/"]];
         var i:int = 0;
         while(i < pairs.length)
         {
            h.setSetting(String(pairs[i][0]),String(pairs[i][1]),String(pairs[i][2]));
            i++;
         }
         i = 0;
         while(i < PANEL_ROWS.length)
         {
            var id:String = String(PANEL_ROWS[i][0]);
            if(h.collapsed[id] == true) { h.setCollapsed(id,false); }
            h.startOpen[id] = true;
            h.setSetting("Panels",id,"1");
            i++;
         }
         var key:String;
         var sets:Array = [];
         for(key in h.columnSets) { sets.push(key); }
         i = 0;
         while(i < sets.length)
         {
            h.setSetting("Columns",String(sets[i]),"");
            delete h.columnSets[String(sets[i])];
            i++;
         }
         h.resetLayout();
         h.clearLayoutSaved();
         h.saveSettings();
         this.scaleX = 1;
         this.scaleY = 1;
         h.restyle();
         h.browser.afterPills();
         h.place();
         h.note("SETTINGS reset");
      }

      // ---- input ---------------------------------------------------------------------------

      override internal function onHover(param1:Number, param2:Number):void
      {
         var hit:Object = param1 < 0 ? null : this.hitAt(param1,param2);
         var row:String = hit != null && (String(hit.id) == "less" || String(hit.id) == "more") ? String(hit.data) : "";
         if(row != this.hoverRow)
         {
            this.hoverRow = row;
            this.paint();
         }
      }

      override internal function onWheel(param1:Number, param2:Number, param3:Number):void
      {
         var room:Number = this.boxH - this.kit.u(44) - this.kit.u(58);
         var max:Number = Math.max(0,this.fullH - room);
         this.scroll = HorizonShipBuilder.clampNum(this.scroll - param1 * this.kit.u(42),0,max,0);
         this.paint();
      }

      override internal function onPress(param1:Object, param2:Number, param3:Number):Boolean
      {
         if(param1 == null || String(param1.id) != "opacity") { return false; }
         this.dragging = true;
         this.onMove(param2,param3);
         return true;
      }

      override internal function onMove(param1:Number, param2:Number):void
      {
         if(!this.dragging || this.trackW <= 0) { return; }
         var frac:Number = HorizonShipBuilder.clampNum((this.localX(param1) - this.trackX) / this.trackW,0,1,1);
         this.setOpacity(OPACITY_MIN + frac * (1 - OPACITY_MIN));
         this.paint();
      }

      override internal function onRelease(param1:Number, param2:Number):void
      {
         this.dragging = false;
      }

      override internal function onChar(param1:int):void
      {
         if(this.editing.length == 0 || param1 < 33 || param1 > 126) { return; }
         var c:String = String.fromCharCode(param1).toUpperCase();
         if(this.editing == "hex")
         {
            if(this.editText.length >= 6 || "0123456789ABCDEF".indexOf(c) < 0) { return; }
            this.editText += c;
            this.paint();
            return;
         }
         var key:String = this.editing;
         this.stopEditing();
         this.setKey(key,c);
         this.paint();
      }

      private function stopEditing():void
      {
         this.editing = "";
         this.editText = "";
         this.hsb.endText(this);
      }

      override internal function onKey(param1:String):Boolean
      {
         if(this.editing.length > 0)
         {
            if(param1 == "cancel")
            {
               this.stopEditing();
               this.paint();
               return true;
            }
            if(this.editing == "hex")
            {
               if(param1 == "bksp") { this.editText = this.editText.substring(0,Math.max(0,this.editText.length - 1)); }
               else if(param1 == "ok")
               {
                  var text:String = this.editText;
                  this.stopEditing();
                  if(HsbKit.parseHex(text) >= 0) { this.setAccent(13,text); }
               }
               this.paint();
               return true;
            }
            if(param1 == "del" || param1 == "bksp")
            {
               var key:String = this.editing;
               this.stopEditing();
               this.setKey(key,"0");
               this.paint();
            }
            return true;
         }
         if(param1 == "cancel") { return false; }
         var r:Object = this.focusedHit();
         if(r != null && (String(r.id) == "less" || String(r.id) == "more") && (param1 == "left" || param1 == "right"))
         {
            this.step(String(r.data),param1 == "right" ? 1 : -1);
            this.paint();
            return true;
         }
         if(r != null && String(r.id) == "opacity" && (param1 == "left" || param1 == "right"))
         {
            this.setOpacity(this.hsb.opacity + (param1 == "right" ? STEP : -STEP));
            this.paint();
            return true;
         }
         if(param1 == "ok" && r == null)
         {
            this.hsb.closePop(this,true);
            return true;
         }
         if(param1 == "up" || param1 == "down")
         {
            this.moveFocus(param1 == "down" ? 1 : -1);
            this.keepFocusVisible();
            this.paint();
            return true;
         }
         return this.navKey(param1);
      }

      private function keepFocusVisible():void
      {
         var r:Object = this.focusedHit();
         if(r == null) { return; }
         var top:Number = this.kit.u(44) + 6;
         var bottom:Number = this.boxH - this.kit.u(58);
         if(Number(r.y) < top) { this.scroll = Math.max(0,this.scroll - (top - Number(r.y)) - 8); }
         else if(Number(r.y) + Number(r.h) > bottom) { this.scroll += Number(r.y) + Number(r.h) - bottom + 8; }
      }

      override internal function onAct(param1:String, param2:*):void
      {
         var h:HorizonShipBuilder = this.hsb;
         switch(param1)
         {
            case "done":
               h.closePop(this,true);
               return;
            case "swatch": this.setAccent(int(param2),""); break;
            case "toggle": this.flip(String(param2)); break;
            case "less": this.step(String(param2),-1); break;
            case "more": this.step(String(param2),1); break;
            case "opacity": break;
            case "hex":
               this.editing = "hex";
               this.editText = "";
               h.beginText(this);
               break;
            case "key":
               this.editing = String(param2);
               this.editText = "";
               h.beginText(this);
               break;
            case "arrange":
               h.saveSettings();
               h.closePop(this,true);
               h.openArrange();
               return;
            case "undo": this.undo(); break;
            case "reset":
               var self:HsbSettings = this;
               HsbDialog.confirm(this.kit,h,"Reset all settings?","",["Accent, layout, panels, keys and column sets go back to the defaults.","Your pills are kept."],"Reset",function(param1:Boolean):void
               {
                  if(param1) { self.resetAll(); self.paint(); }
               });
               return;
         }
         this.paint();
      }

      override internal function onClose(param1:Boolean):void
      {
         if(this.editing.length > 0) { this.stopEditing(); }
         this.hsb.saveSettings();
         this.hsb.note("SETTINGS closed");
      }
   }
}
