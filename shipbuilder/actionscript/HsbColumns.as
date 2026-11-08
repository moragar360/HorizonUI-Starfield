package
{
   import flash.display.Graphics;
   import flash.text.TextField;

   // Purpose: the column chooser from gold mockup 8. Up to four columns after Name, one set per
   //    tab; drag a row to reorder, switch a row to show or hide it.
   // Inputs: the browser's live column list, the columns available on this tab and the pill
   //    that brings its own columns; pointer, wheel and keys routed by HorizonShipBuilder.
   // Outputs: changes apply to the list at once; Done or a click outside saves the set for
   //    this tab (Columns.<tab> in the user ini); Esc puts the old set back.
   // Dependencies: HsbBrowser (columns, availableColumns, columnLabel, previewColumns,
   //    saveColumns, resetColumns, pillColumns, tabLabel, sortInfo), HsbBox, HsbKit.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbColumns extends HsbBox
   {
      private var hsb:HorizonShipBuilder;
      private var browser:HsbBrowser;
      private var before:Array;
      private var shown:Array;
      private var dragId:String = "";
      private var dragFrom:Number = 0;
      private var rowTop:Number = 0;
      private var rowPitch:Number = 39;
      private var cancelled:Boolean = false;
      private var reset:Boolean = false;

      public function HsbColumns(param1:HsbKit, param2:HorizonShipBuilder, param3:HsbBrowser)
      {
         super(param1,"HsbColumns");
         this.hsb = param2;
         this.browser = param3;
         this.before = param3.tabColumns();
         this.shown = this.before.slice();
         this.lightDismiss = true;
         this.paint();
      }

      private function available():Array
      {
         var out:Array = [];
         var all:Array = this.browser.availableColumns();
         var i:int = 0;
         while(i < all.length)
         {
            if(this.shown.indexOf(String(all[i])) < 0) { out.push(String(all[i])); }
            i++;
         }
         return out;
      }

      internal function paint():void
      {
         this.wipe();
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var w:Number = k.u(416);
         var pad:Number = 22;
         var inset:Number = 10;
         var tab:String = this.browser.tabLabel();
         var y:Number = 18;
         var title:TextField = k.label(this,pad,y,"COLUMNS",17,HsbKit.TEXT,true,3);
         var saved:Boolean = this.hsb.columnSets[this.browser.tabKeyNow()] != null && String(this.hsb.columnSets[this.browser.tabKeyNow()]).length > 0;
         var chip:TextField = k.text(13,k.accent,true);
         k.put(chip,(saved ? "Saved for " : "Default for ") + tab);
         k.fit(chip,k.u(200));
         var chipH:Number = k.u(22);
         var chipX:Number = pad + title.width + 10;
         var chipY:Number = y + (title.height - chipH) / 2;
         k.fill(g,chipX,chipY,chip.width + 16,chipH,chipH / 2,k.accentDim(0.18),1);
         k.outline(g,chipX,chipY,chip.width + 16,chipH,chipH / 2,k.accent,saved ? 1 : 0.5);
         this.add(chip,chipX + 8,chipY + (chipH - chip.height) / 2);
         var capW:Number = k.keycap(this,w - pad - k.u(38),chipY - 1,"ESC",HsbKit.LABEL,k.u(24));
         this.hit(w - pad - capW - 4,chipY - 5,capW + 8,k.u(32),"close");
         y += title.height + 10;
         k.label(this,pad,y,"Pick up to " + HsbPillModel.MAX_COLUMNS + ". Drag to reorder. Name is always first.",13,HsbKit.LABEL,false,0,w - pad * 2);
         y += k.u(26);
         k.hline(g,pad,y,w - pad * 2,HsbKit.EDGE,1);
         y += 14;
         k.label(this,pad,y,"SHOWN",13,k.accent,true,2);
         var count:TextField = k.text(13,HsbKit.MUTED,false,0,"right");
         k.put(count,this.shown.length + " of " + HsbPillModel.MAX_COLUMNS);
         count.width = 80;
         this.add(count,w - pad - 80,y);
         y += k.u(24);
         var rowH:Number = k.u(34);
         this.rowPitch = rowH + 5;
         this.rowTop = y;
         var sortInfo:Object = this.browser.sortInfo();
         var i:int = 0;
         while(i < this.shown.length)
         {
            var id:String = String(this.shown[i]);
            var dragging:Boolean = id == this.dragId;
            var ry:Number = y;
            if(dragging)
            {
               k.fill(g,inset,ry,w - inset * 2,rowH,7,HsbKit.SELECT,1);
               k.outline(g,inset,ry,w - inset * 2,rowH,7,k.accentDim(0.6),1);
               k.fill(g,3,ry + 6,3,rowH - 12,1.5,k.accent,1);
            }
            else { k.fill(g,inset,ry,w - inset * 2,rowH,7,HsbKit.ROW,1); }
            k.icon(g,"handle",inset + 12,ry + (rowH - 16) / 2,16,HsbKit.LABEL,1);
            var lab:TextField = k.label(this,inset + 40,ry + (rowH - k.u(24)) / 2,this.browser.columnLabel(id),15,HsbKit.TEXT,false,0,k.u(180));
            if(String(sortInfo.col) == id && !dragging)
            {
               k.label(this,lab.x + lab.width + 4,ry + (rowH - k.u(20)) / 2 + 1,sortInfo.desc == true ? "Sorted, high to low" : "Sorted, low to high",13,k.accent,false,0,k.u(150));
            }
            var tx:Number = w - inset - 14 - k.u(38);
            if(dragging)
            {
               var dt:TextField = k.text(13,k.accent,true,1.5,"right");
               k.put(dt,"DRAGGING");
               dt.width = 110;
               this.add(dt,tx - 10 - 110,ry + (rowH - dt.height) / 2);
            }
            var lastOne:Boolean = this.shown.length <= 1;
            k.toggle(g,tx,ry + (rowH - k.u(18)) / 2,true,!lastOne);
            this.hit(inset,ry,tx - inset - 8,rowH,"grip",id);
            if(!lastOne) { this.hit(tx - 6,ry,k.u(38) + 12,rowH,"toggle",id); }
            y += this.rowPitch;
            i++;
         }
         y += 8;
         k.label(this,pad,y,"AVAILABLE FOR " + tab.toUpperCase(),13,k.accent,true,2,w - pad * 2);
         y += k.u(26);
         var avail:Array = this.available();
         var full:Boolean = this.shown.length >= HsbPillModel.MAX_COLUMNS;
         i = 0;
         while(i < avail.length)
         {
            var aid:String = String(avail[i]);
            k.icon(g,"handle",inset + 12,y + (rowH - 16) / 2,16,HsbKit.DIM,1);
            k.label(this,inset + 40,y + (rowH - k.u(24)) / 2,this.browser.columnLabel(aid),15,full ? HsbKit.MUTED : HsbKit.TEXT,false,0,k.u(220));
            var ax:Number = w - inset - 14 - k.u(38);
            k.toggle(g,ax,y + (rowH - k.u(18)) / 2,false,!full);
            if(!full) { this.hit(inset,y,w - inset * 2,rowH,"toggle",aid); }
            y += this.rowPitch;
            i++;
         }
         if(avail.length == 0)
         {
            k.label(this,pad,y + 6,"Every column for this tab is shown.",13,HsbKit.MUTED);
            y += rowH;
         }
         y += 6;
         k.hline(g,pad,y,w - pad * 2,HsbKit.EDGE,1);
         y += 12;
         var others:String = this.otherTabs();
         var ot:TextField = k.text(13,HsbKit.MUTED);
         ot.multiline = true;
         ot.wordWrap = true;
         ot.width = w - pad * 2;
         k.put(ot,others);
         ot.height = ot.textHeight + 6;
         this.add(ot,pad,y);
         y += ot.height + 8;
         var pill:Object = this.browser.pillColumns();
         if(pill != null)
         {
            var cols:Array = pill.columns as Array;
            var names:Array = [];
            var c:int = 0;
            while(c < cols.length)
            {
               names.push(this.browser.columnLabel(HsbPillModel.columnId(String(cols[c]))));
               c++;
            }
            var bx:Number = inset;
            var bw:Number = w - inset * 2;
            var l1:TextField = k.text(13,HsbKit.TEXT,true);
            k.put(l1,String(pill.name) + " brings its own columns:");
            k.fit(l1,bw - 44);
            var l2:TextField = k.text(13,HsbKit.LABEL);
            l2.multiline = true;
            l2.wordWrap = true;
            l2.width = bw - 44;
            k.put(l2,names.join(", ") + ". Used while that pill is on.");
            l2.height = l2.textHeight + 6;
            var bh:Number = 12 + l1.height + l2.height + 8;
            k.fill(g,bx,y,bw,bh,8,HsbKit.HEAD,1);
            k.icon(g,"diamond",bx + 12,y + 13,12,k.accent,1);
            this.add(l1,bx + 32,y + 10);
            this.add(l2,bx + 32,y + 10 + l1.height);
            y += bh + 10;
         }
         y += 14;
         var btnH:Number = k.u(30);
         k.button(this,pad,y,"RESET TO DEFAULT","outline","reset",null,btnH);
         k.button(this,w - pad - k.u(80),y,"DONE","accent","done",null,btnH,k.u(80));
         y += btnH + 18;
         k.card(this.graphics,0,0,w,y,14);
         this.boxW = w;
         this.boxH = y;
         this.drawFocus();
      }

      // Mockup 8's "Other tabs" line: tabs that keep a set of their own.
      private function otherTabs():String
      {
         var names:Array = [];
         var key:String;
         for(key in this.hsb.columnSets)
         {
            if(key == this.browser.tabKeyNow() || (key.length > 4 && key.substr(-4) == "Sort")) { continue; }
            if(String(this.hsb.columnSets[key]).length == 0) { continue; }
            names.push(this.browser.tabNameFor(key));
         }
         if(names.length == 0) { return "Each tab keeps its own set."; }
         names.sort();
         var text:String = names.slice(0,5).join(", ");
         return "Other tabs with their own set: " + text + (names.length > 5 ? "\u2026" : ".");
      }

      private function apply():void
      {
         this.browser.previewColumns(this.shown.slice());
         this.paint();
      }

      override internal function onPress(param1:Object, param2:Number, param3:Number):Boolean
      {
         if(param1 == null || String(param1.id) != "grip") { return false; }
         this.dragId = String(param1.data);
         this.dragFrom = this.localY(param3);
         this.paint();
         return true;
      }

      override internal function onMove(param1:Number, param2:Number):void
      {
         if(this.dragId.length == 0) { return; }
         var ly:Number = this.localY(param2);
         var at:int = HorizonShipBuilder.clampInt(int(Math.floor((ly - this.rowTop) / this.rowPitch)),0,this.shown.length - 1);
         var now:int = this.shown.indexOf(this.dragId);
         if(now >= 0 && at != now)
         {
            this.shown.splice(now,1);
            this.shown.splice(at,0,this.dragId);
            this.apply();
         }
      }

      override internal function onRelease(param1:Number, param2:Number):void
      {
         this.dragId = "";
         this.paint();
      }

      override internal function onKey(param1:String):Boolean
      {
         if(param1 == "cancel")
         {
            this.cancelled = true;
            return false;
         }
         var r:Object = this.focusedHit();
         // Shoulder buttons and tab move the focused shown row; arrows walk the controls.
         if(r != null && (String(r.id) == "grip" || String(r.id) == "toggle") && (param1 == "tabprev" || param1 == "tab"))
         {
            var id:String = String(r.data);
            var at:int = this.shown.indexOf(id);
            if(at < 0) { return true; }
            var to:int = HorizonShipBuilder.clampInt(at + (param1 == "tab" ? 1 : -1),0,this.shown.length - 1);
            if(to != at)
            {
               this.shown.splice(at,1);
               this.shown.splice(to,0,id);
               this.apply();
            }
            return true;
         }
         if(param1 == "ok" && r == null)
         {
            this.hsb.closePop(this,true);
            return true;
         }
         if(r != null && String(r.id) == "grip" && (param1 == "ok" || param1 == "x"))
         {
            this.onAct("toggle",r.data);
            return true;
         }
         return this.navKey(param1);
      }

      override internal function onAct(param1:String, param2:*):void
      {
         switch(param1)
         {
            case "close":
               this.cancelled = true;
               this.hsb.closePop(this,false);
               break;
            case "toggle":
               var id:String = String(param2);
               var at:int = this.shown.indexOf(id);
               if(at >= 0)
               {
                  if(this.shown.length > 1) { this.shown.splice(at,1); }
               }
               else if(this.shown.length < HsbPillModel.MAX_COLUMNS) { this.shown.push(id); }
               this.reset = false;
               this.apply();
               break;
            case "reset":
               this.browser.previewColumns(null);
               this.reset = true;
               this.shown = this.browser.defaultColumns();
               this.apply();
               break;
            case "done":
               this.hsb.closePop(this,true);
               break;
         }
      }

      override internal function onClose(param1:Boolean):void
      {
         this.browser.previewColumns(null);
         if(this.cancelled)
         {
            this.hsb.note("COLUMNS cancel");
            return;
         }
         if(this.reset) { this.browser.resetColumns(); }
         else if(this.shown.join(",") != this.before.join(",")) { this.browser.saveColumns(this.shown.slice()); }
         this.hsb.note("COLUMNS saved n=" + this.shown.length);
      }
   }
}
