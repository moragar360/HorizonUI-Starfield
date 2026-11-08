package
{
   import flash.display.Graphics;
   import flash.text.TextField;

   // Purpose: the builder's small popups: pick menus (Sort, More, Manage, rule fields and
   //    values; gold mockup 14), the pill export note (mockup 15) and the confirm dialog
   //    (mockup 16).
   // Inputs: a title and item rows {label, id, data, on, dim, note, accent, right} from the
   //    owner; pointer and keys routed by HorizonShipBuilder.
   // Outputs: the chosen row through the owner's callback(id, data); the export writes one
   //    pill file through the DLL's file job (PILLS WRITE user <file>).
   // Dependencies: HsbBox, HsbKit, HsbPillModel (pill file text), HorizonShipBuilder (openPop,
   //    closePop, fileOp).
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbDialog extends HsbBox
   {
      private static const PILL_FOLDER:String = "Data\\Interface\\HorizonUI\\shipbuilder\\pills\\user\\";

      private var hsb:HorizonShipBuilder;
      private var kind:String;
      private var title:String;
      private var items:Array;
      private var pick:Function;
      private var hoverAt:int = -1;
      private var subject:String = "";
      private var body:Array;
      private var yesLabel:String = "Yes";
      private var state:String = "";
      private var fileName:String = "";

      public function HsbDialog(param1:HsbKit, param2:HorizonShipBuilder, param3:String, param4:String)
      {
         super(param1,"HsbDialog");
         this.hsb = param2;
         this.kind = param3;
         this.title = param4;
         this.items = [];
         this.body = [];
      }

      // Purpose: open a pick menu. The caller sets anchorX/anchorY (or leaves it centred).
      // Inputs: kit, builder, title, item rows, callback(id, data). Outputs: the open menu.
      // Dependencies: HorizonShipBuilder.openPop.
      internal static function menu(param1:HsbKit, param2:HorizonShipBuilder, param3:String, param4:Array, param5:Function):HsbDialog
      {
         var d:HsbDialog = new HsbDialog(param1,param2,"menu",param3);
         d.items = param4 != null ? param4 : [];
         d.pick = param5;
         d.lightDismiss = true;
         d.paint();
         return d;
      }

      // Purpose: write one pill to pills\user as a shareable file and show where it went.
      // Inputs: kit, builder, pill. Outputs: an open note; one PILLS WRITE request.
      // Dependencies: HsbPillModel.pillFile, HorizonShipBuilder.fileOp.
      internal static function exportPill(param1:HsbKit, param2:HorizonShipBuilder, param3:Object):HsbDialog
      {
         var d:HsbDialog = new HsbDialog(param1,param2,"export","EXPORT PILL");
         d.subject = String(param3.name);
         d.state = "saving";
         d.fileName = safeFileName(String(param3.name)) + ".json";
         d.lightDismiss = true;
         if(param2.browser != null)
         {
            d.anchorX = param2.browser.x - 104 * param2.browser.scaleX;
            d.anchorY = param2.browser.y + 329 * param2.browser.scaleY;
         }
         d.paint();
         param2.openPop(d);
         param2.fileOp("PILLS",["WRITE","user",d.fileName],HsbPillModel.pillFile(param3),function(param4:Boolean, param5:String):void
         {
            d.state = param4 ? "ok" : "fail";
            if(param4 && param5.length > 0) { d.fileName = param5; }
            d.paint();
            param2.note("PILLS export " + (param4 ? "ok" : "failed"));
         });
         return d;
      }

      // Purpose: ask before a destructive step. Focus starts on No; Esc answers No.
      // Inputs: kit, builder, question, subject (shown in the accent), body lines, the yes
      //    label, callback(yes:Boolean). Outputs: the open modal dialog.
      // Dependencies: HorizonShipBuilder.openPop.
      internal static function confirm(param1:HsbKit, param2:HorizonShipBuilder, param3:String, param4:String, param5:Array, param6:String, param7:Function):HsbDialog
      {
         var d:HsbDialog = new HsbDialog(param1,param2,"confirm",param3);
         d.subject = param4 != null ? param4 : "";
         d.body = param5 != null ? param5 : [];
         d.yesLabel = param6;
         d.pick = function(param8:String, param9:*):void { param7(param8 == "yes"); };
         d.modal = true;
         d.paint();
         var i:int = 0;
         while(i < d.hits.length)
         {
            if(String(d.hits[i].id) == "no") { d.focusAt = i; }
            i++;
         }
         d.drawFocus();
         param2.openPop(d);
         return d;
      }

      // File names keep letters, digits, space, dash and underscore; the DLL checks again.
      internal static function safeFileName(param1:String):String
      {
         var out:String = "";
         var i:int = 0;
         while(i < param1.length && out.length < 40)
         {
            var c:String = param1.charAt(i);
            var n:Number = param1.charCodeAt(i);
            var ok:Boolean = (n >= 48 && n <= 57) || (n >= 65 && n <= 90) || (n >= 97 && n <= 122) || c == " " || c == "-" || c == "_";
            out += ok ? c : "_";
            i++;
         }
         out = HsbPillModel.trim(out);
         return out.length > 0 ? out : "pill";
      }

      internal function paint():void
      {
         this.wipe();
         if(this.kind == "menu") { this.paintMenu(); }
         else if(this.kind == "export") { this.paintExport(); }
         else { this.paintConfirm(); }
         this.drawFocus();
      }

      // Mockup 14: caps title, white rows, accent action rows below a rule, a check on the
      // chosen row, a muted note on a row that cannot be used.
      private function paintMenu():void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var pad:Number = 16;
         var rowH:Number = k.u(32);
         var widest:Number = k.u(200);
         var probe:TextField = k.text(14,HsbKit.TEXT);
         var i:int = 0;
         while(i < this.items.length)
         {
            var it:Object = this.items[i];
            k.put(probe,String(it.label));
            var extra:Number = it.right != null || (it.note != null && String(it.note).length > 0) ? k.u(90) : (it.on == true ? k.u(30) : 0);
            widest = Math.max(widest,probe.textWidth + extra);
            i++;
         }
         var w:Number = Math.min(k.u(380),widest + pad * 2 + 12);
         var titleH:Number = this.title.length > 0 ? k.u(34) : 8;
         var ruleAt:int = -1;
         i = 0;
         while(i < this.items.length)
         {
            if(this.items[i].accent == true && i > 0 && this.items[i - 1].accent != true) { ruleAt = i; }
            i++;
         }
         var h:Number = titleH + this.items.length * rowH + (ruleAt >= 0 ? 9 : 0) + 8;
         if(this.items.length == 0) { h += rowH; }
         k.card(this.graphics,0,0,w,h,10);
         if(this.title.length > 0) { k.label(this,pad,12,this.title.toUpperCase(),12,k.accent,true,2); }
         var y:Number = titleH;
         if(this.items.length == 0) { k.label(this,pad,y + 6,"Nothing here yet",13,HsbKit.MUTED); }
         i = 0;
         while(i < this.items.length)
         {
            var row:Object = this.items[i];
            if(i == ruleAt)
            {
               k.hline(g,pad,y + 4,w - pad * 2,HsbKit.EDGE,1);
               y += 9;
            }
            var dim:Boolean = row.dim == true;
            if(i == this.hoverAt && !dim) { k.fill(g,6,y,w - 12,rowH,6,HsbKit.SELECT,1); }
            var color:uint = dim ? HsbKit.DIM : (row.accent == true ? k.accent : HsbKit.TEXT);
            k.label(this,pad,y + (rowH - k.u(22)) / 2,String(row.label),14,color,row.on == true,0,w - pad * 2 - k.u(90));
            if(row.right != null)
            {
               var rt:TextField = k.text(12,k.accent,true,1.5,"right");
               k.put(rt,String(row.right));
               rt.width = k.u(90);
               this.add(rt,w - pad - k.u(90),y + (rowH - rt.height) / 2 + 1);
            }
            else if(dim && row.note != null && String(row.note).length > 0)
            {
               var nt:TextField = k.text(12,HsbKit.MUTED,false,0,"right");
               k.put(nt,String(row.note));
               nt.width = k.u(120);
               this.add(nt,w - pad - k.u(120),y + (rowH - nt.height) / 2 + 1);
            }
            else if(row.on == true) { k.icon(g,"check",w - pad - 16,y + (rowH - 16) / 2,16,k.accent,1); }
            if(!dim) { this.hit(6,y,w - 12,rowH,"row",i); }
            y += rowH;
            i++;
         }
         this.boxW = w;
         this.boxH = h;
      }

      // Mockup 15: where the pill went, as a path relative to the game folder.
      private function paintExport():void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var pad:Number = 18;
         var w:Number = k.u(413);
         k.label(this,pad,16,this.title,12,k.accent,true,2);
         var capW:Number = k.keycap(this,w - pad - k.u(40),12,"ESC",HsbKit.LABEL,k.u(22));
         this.hit(w - pad - capW - 4,8,capW + 8,k.u(30),"close");
         var y:Number = 16 + k.u(30);
         k.icon(g,"diamond",pad,y + 3,14,k.accent,1);
         var name:TextField = k.label(this,pad + 20,y,this.subject,16,HsbKit.TEXT,true,0,w - pad * 2 - 20);
         y += name.height + 10;
         k.label(this,pad,y,"Saved to",12,HsbKit.MUTED);
         y += k.u(20);
         var path:TextField = k.text(13,HsbKit.LABEL);
         path.multiline = true;
         path.wordWrap = true;
         path.width = w - pad * 2;
         k.put(path,PILL_FOLDER + this.fileName);
         path.height = path.textHeight + 6;
         this.add(path,pad,y);
         y += path.height + 10;
         var msg:String = "Saving\u2026";
         var ink:uint = HsbKit.MUTED;
         var back:uint = 0x1A2128;
         if(this.state == "ok")
         {
            msg = "Exported \u00B7 share this file";
            ink = HsbKit.GREEN;
            back = HsbKit.GREEN_BG;
         }
         else if(this.state == "fail")
         {
            msg = "Could not save the file";
            ink = HsbKit.RED;
            back = HsbKit.RED_BG;
         }
         var mt:TextField = k.text(13,ink,true);
         k.put(mt,msg);
         k.fit(mt);
         var chipH:Number = k.u(28);
         var chipW:Number = mt.width + (this.state == "saving" ? 20 : 40);
         k.fill(g,pad,y,chipW,chipH,7,back,1);
         if(this.state == "ok") { k.icon(g,"check",pad + 8,y + (chipH - 16) / 2,16,ink,1); }
         else if(this.state == "fail") { k.icon(g,"xCircle",pad + 8,y + (chipH - 16) / 2,16,ink,1); }
         this.add(mt,pad + (this.state == "saving" ? 10 : 30),y + (chipH - mt.height) / 2);
         y += chipH + 16;
         k.card(this.graphics,0,0,w,y,12);
         this.boxW = w;
         this.boxH = y;
      }

      // Mockup 16: orange CONFIRM tag, the question, the subject in the accent, the body.
      private function paintConfirm():void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var pad:Number = 24;
         var w:Number = k.u(470);
         var y:Number = 22;
         var tag:TextField = k.text(12,HsbKit.ORANGE,true,1.5);
         k.put(tag,"CONFIRM");
         k.fit(tag);
         var tagH:Number = k.u(24);
         var tagW:Number = 30 + tag.width + 10;
         k.fill(g,pad,y,tagW,tagH,tagH / 2,HsbKit.ORANGE_BG,1);
         k.outline(g,pad,y,tagW,tagH,tagH / 2,HsbKit.ORANGE,1);
         k.icon(g,"info",pad + 8,y + (tagH - 15) / 2,15,HsbKit.ORANGE,1);
         this.add(tag,pad + 28,y + (tagH - tag.height) / 2);
         y += tagH + 14;
         var q:TextField = k.text(18,HsbKit.TEXT,true);
         q.multiline = true;
         q.wordWrap = true;
         q.width = w - pad * 2;
         k.put(q,this.title);
         q.height = q.textHeight + 6;
         this.add(q,pad,y);
         y += q.height + 6;
         if(this.subject.length > 0)
         {
            var s:TextField = k.label(this,pad,y,this.subject,15,k.accent,true,0,w - pad * 2);
            y += s.height + 10;
         }
         var i:int = 0;
         while(i < this.body.length)
         {
            var line:TextField = k.text(13,HsbKit.LABEL);
            line.multiline = true;
            line.wordWrap = true;
            line.width = w - pad * 2;
            k.put(line,String(this.body[i]));
            line.height = line.textHeight + 6;
            this.add(line,pad,y);
            y += line.height + 2;
            i++;
         }
         y += 18;
         var bh:Number = k.u(32);
         var yes:TextField = k.text(13,HsbKit.ORANGE,true,1);
         k.put(yes,this.yesLabel);
         k.fit(yes);
         var yesW:Number = Math.max(k.u(80),yes.width + 28);
         var noW:Number = k.u(80);
         var yx:Number = w - pad - yesW;
         var nx:Number = yx - 10 - noW;
         k.button(this,nx,y,"No","outline","no",null,bh,noW);
         k.button(this,yx,y,this.yesLabel,"orange","yes",null,bh,yesW);
         y += bh + 22;
         k.card(this.graphics,0,0,w,y,12);
         this.boxW = w;
         this.boxH = y;
      }

      override internal function onHover(param1:Number, param2:Number):void
      {
         if(this.kind != "menu") { return; }
         var hit:Object = param1 < 0 ? null : this.hitAt(param1,param2);
         var at:int = hit != null && String(hit.id) == "row" ? int(hit.data) : -1;
         if(at != this.hoverAt)
         {
            this.hoverAt = at;
            this.paint();
         }
      }

      override internal function onKey(param1:String):Boolean
      {
         if(param1 == "cancel")
         {
            if(this.kind == "confirm") { this.answer("no"); return true; }
            return false;
         }
         return this.navKey(param1);
      }

      override internal function onAct(param1:String, param2:*):void
      {
         if(param1 == "close")
         {
            this.hsb.closePop(this,false);
            return;
         }
         if(this.kind == "confirm")
         {
            this.answer(param1);
            return;
         }
         if(param1 != "row") { return; }
         var row:Object = this.items[int(param2)];
         if(row == null || row.dim == true) { return; }
         var cb:Function = this.pick;
         this.hsb.closePop(this,true);
         if(cb != null) { cb(String(row.id),row.data); }
      }

      private function answer(param1:String):void
      {
         var cb:Function = this.pick;
         this.pick = null;
         this.hsb.closePop(this,param1 == "yes");
         if(cb != null) { cb(param1,null); }
      }
   }
}
