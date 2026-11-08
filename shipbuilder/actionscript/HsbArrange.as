package
{
   import flash.display.Graphics;
   import flash.text.TextField;

   // Purpose: Arrange mode from gold mockup 17: every Horizon panel gets an accent outline and
   //    a name tag; drag a panel (or nudge it with the arrows) and it snaps to a 10 px grid and
   //    to the edges and centres of the other panels and the screen. Overlaps are tagged.
   // Inputs: the panel boxes from HorizonShipBuilder.arrangeBoxes; pointer points (stage
   //    space) and key tokens routed by the builder while Arrange is open (the DLL swallows all
   //    pointer input then, so the ship view never moves under a drag).
   // Outputs: live panel moves (moveBox) and anchors (storeAnchor); OK saves them through
   //    ARRANGE lines (merged by the DLL into HorizonShipBuilder.user.ini); Cancel restores
   //    the layout from when Arrange opened; Reset returns to the default layout.
   // Dependencies: HorizonShipBuilder (arrangeBoxes, moveBox, storeAnchor, arrangeDone,
   //    resetLayout, viewRect, lay), HsbBox, HsbKit.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbArrange extends HsbBox
   {
      private static const GRID:Number = 10;
      private static const GRID_DRAWN:Number = 40;
      private static const SNAP:Number = 6;
      private static const NUDGE:Number = 10;

      private var hsb:HorizonShipBuilder;
      private var items:Array;
      private var sel:int = 0;
      private var dragAt:int = -1;
      private var dragBar:Boolean = false;
      private var offX:Number = 0;
      private var offY:Number = 0;
      private var savedLay:Object;
      private var savedBarX:Number = 0;
      private var savedBarY:Number = 0;
      private var barX:Number = 0;
      private var barY:Number = 0;
      private var barRect:Object;
      private var guidesX:Array;
      private var guidesY:Array;
      private var lastTick:int = 0;

      public function HsbArrange(param1:HsbKit, param2:HorizonShipBuilder)
      {
         super(param1,"HsbArrange");
         this.hsb = param2;
         this.items = [];
         this.guidesX = [];
         this.guidesY = [];
         this.visible = false;
      }

      // Purpose: enter Arrange. Inputs: none. Outputs: the overlay is shown and painted.
      internal function open():void
      {
         this.savedLay = {};
         var key:String;
         for(key in this.hsb.lay) { this.savedLay[key] = this.hsb.lay[key]; }
         this.savedBarX = this.hsb.barDx;
         this.savedBarY = this.hsb.barDy;
         this.barX = this.hsb.barDx;
         this.barY = this.hsb.barDy;
         this.items = this.hsb.arrangeBoxes();
         this.sel = this.items.length > 0 ? 0 : -1;
         this.dragAt = -1;
         this.dragBar = false;
         this.visible = true;
         this.paint();
      }

      internal function tick():void
      {
         if(this.dragAt >= 0 || this.dragBar) { return; }
         if(this.hsb.frame() - this.lastTick < 10) { return; }
         this.lastTick = this.hsb.frame();
         var selId:String = this.sel >= 0 && this.sel < this.items.length ? String(this.items[this.sel].id) : "";
         this.items = this.hsb.arrangeBoxes();
         this.sel = this.indexOf(selId);
         if(this.sel < 0 && this.items.length > 0) { this.sel = 0; }
         this.paint();
      }

      private function indexOf(param1:String):int
      {
         var i:int = 0;
         while(i < this.items.length)
         {
            if(String(this.items[i].id) == param1) { return i; }
            i++;
         }
         return -1;
      }

      // ---- paint ---------------------------------------------------------------------------

      internal function paint():void
      {
         this.wipe();
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var r:Object = this.hsb.viewRect();
         var vx:Number = Number(r.x);
         var vy:Number = Number(r.y);
         var vw:Number = Number(r.width);
         var vh:Number = Number(r.height);
         var gx:Number = vx;
         while(gx <= vx + vw)
         {
            k.vline(g,gx,vy,vh,HsbKit.EDGE_HI,0.22);
            gx += GRID_DRAWN;
         }
         var gy:Number = vy;
         while(gy <= vy + vh)
         {
            k.hline(g,vx,gy,vw,HsbKit.EDGE_HI,0.22);
            gy += GRID_DRAWN;
         }
         k.vline(g,vx + vw / 2,vy,vh,k.accent,0.35);
         var i:int = 0;
         while(i < this.guidesX.length) { k.vline(g,Number(this.guidesX[i]),vy,vh,k.accent,0.75); i++; }
         i = 0;
         while(i < this.guidesY.length) { k.hline(g,vx,Number(this.guidesY[i]),vw,k.accent,0.75); i++; }
         i = 0;
         while(i < this.items.length)
         {
            this.paintItem(i,i == this.sel);
            i++;
         }
         this.paintOverlaps();
         this.paintBar(r);
         this.boxW = vx + vw;
         this.boxH = vy + vh;
      }

      private function paintItem(param1:int, param2:Boolean):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var it:Object = this.items[param1];
         var x:Number = Number(it.x);
         var y:Number = Number(it.y);
         var w:Number = Number(it.w);
         var h:Number = Number(it.h);
         if(param2) { k.fill(g,x - 3,y - 3,w + 6,h + 6,12,k.accent,0.28); }
         k.outline(g,x - 3,y - 3,w + 6,h + 6,12,k.accent,param2 ? 1 : 0.7,param2 ? 2 : 1.5);
         var tag:TextField = k.text(11,HsbKit.TEXT,true,1.2);
         k.put(tag,String(it.label));
         k.fit(tag);
         var th:Number = k.u(18);
         var tw:Number = tag.width + 10;
         var ty:Number = Math.max(Number(this.hsb.viewRect().y),y - 3 - th - 1);
         k.fill(g,x - 3,ty,tw,th,4,HsbKit.FILL,0.95);
         k.outline(g,x - 3,ty,tw,th,4,k.accent,0.8);
         this.add(tag,x + 2,ty + (th - tag.height) / 2);
         if(param2)
         {
            k.fill(g,x + w / 2 - 7,y - 3 - 7,14,14,7,HsbKit.FILL,1);
            k.outline(g,x + w / 2 - 7,y - 3 - 7,14,14,7,k.accent,1,2);
            k.fill(g,x + w / 2 - 3,y - 3 - 3,6,6,3,k.accent,1);
         }
      }

      private function paintOverlaps():void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var tagged:Object = {};
         var i:int = 0;
         while(i < this.items.length)
         {
            var a:Object = this.items[i];
            var j:int = i + 1;
            while(j < this.items.length)
            {
               var b:Object = this.items[j];
               var ox:Number = Math.min(Number(a.x) + Number(a.w),Number(b.x) + Number(b.w)) - Math.max(Number(a.x),Number(b.x));
               var oy:Number = Math.min(Number(a.y) + Number(a.h),Number(b.y) + Number(b.h)) - Math.max(Number(a.y),Number(b.y));
               if(ox > 2 && oy > 2 && tagged[j] != true)
               {
                  tagged[j] = true;
                  var tx:Number = Math.max(Number(a.x),Number(b.x));
                  var ty:Number = Math.min(Number(a.y) + Number(a.h),Number(b.y) + Number(b.h)) - k.u(22) - 4;
                  var t:TextField = k.text(12,HsbKit.ORANGE,true,1.2);
                  k.put(t,"OVERLAP");
                  k.fit(t);
                  var cw:Number = 26 + t.width + 8;
                  var ch:Number = k.u(22);
                  k.fill(g,tx + 4,ty,cw,ch,ch / 2,HsbKit.ORANGE_BG,1);
                  k.outline(g,tx + 4,ty,cw,ch,ch / 2,HsbKit.ORANGE,1);
                  k.icon(g,"info",tx + 10,ty + (ch - 13) / 2,13,HsbKit.ORANGE,1);
                  this.add(t,tx + 28,ty + (ch - t.height) / 2);
               }
               j++;
            }
            i++;
         }
      }

      // The floating bar: title, how-to line, Reset, OK, Cancel. Dragging its body moves it.
      private function paintBar(param1:Object):void
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var w:Number = k.u(680);
         var h:Number = k.u(74);
         var x:Number = Number(param1.x) + (Number(param1.width) - w) / 2 + this.barX;
         var y:Number = Number(param1.y) + Number(param1.height) * 0.4 + this.barY;
         x = HorizonShipBuilder.clampNum(x,Number(param1.x),Number(param1.x) + Number(param1.width) - w,x);
         y = HorizonShipBuilder.clampNum(y,Number(param1.y),Number(param1.y) + Number(param1.height) - h,y);
         this.barRect = {"x":x,"y":y,"w":w,"h":h};
         k.fill(g,x,y,w,h,12,HsbKit.EDGE,0.98);
         k.fill(g,x + 1,y + 1,w - 2,h - 2,11,HsbKit.FILL,0.96);
         k.fill(g,x,y + 10,3,h - 20,1.5,k.accent,1);
         k.icon(g,"handle",x + 10,y + 26,16,HsbKit.LABEL,1);
         k.label(this,x + 30,y + 12,"ARRANGE PANELS",15,HsbKit.TEXT,true,1.5);
         k.label(this,x + 30,y + 12 + k.u(24),"Drag a panel \u00B7 arrows nudge \u00B7 ENTER save \u00B7 ESC cancel",13,HsbKit.LABEL,false,0,w - 330);
         var bh:Number = k.u(26);
         var by:Number = y + h - bh - 12;
         var bw:Number = k.u(88);
         var cx:Number = x + w - 14 - bw;
         k.button(this,cx,by,"CANCEL","outline","cancel",null,bh,bw);
         k.button(this,cx - 8 - bw,by,"OK","accent","ok",null,bh,bw);
         k.button(this,cx - 16 - bw * 2,by,"RESET","outline","reset",null,bh,bw);
      }

      // ---- moving --------------------------------------------------------------------------

      // Snap one axis: to another panel's edge or centre, the screen centre, or the margin
      // lines within SNAP px; otherwise to the 10 px grid.
      private function snapAxis(param1:Number, param2:Number, param3:Array, param4:Array, param5:Number):Number
      {
         var ends:Array = [0,param2 / 2,param2];
         var best:Number = SNAP + 1;
         var pick:Number = NaN;
         var line:Number = NaN;
         var i:int = 0;
         while(i < param3.length)
         {
            var target:Number = Number(param3[i]);
            var e:int = 0;
            while(e < ends.length)
            {
               var d:Number = Math.abs(param1 + Number(ends[e]) - target);
               if(d < best)
               {
                  best = d;
                  pick = target - Number(ends[e]);
                  line = target;
               }
               e++;
            }
            i++;
         }
         if(!isNaN(pick))
         {
            param4.push(line);
            return pick;
         }
         return param5 + Math.round((param1 - param5) / GRID) * GRID;
      }

      private function targets(param1:int, param2:Boolean):Array
      {
         var r:Object = this.hsb.viewRect();
         var m:Number = this.hsb.margin;
         var out:Array = param2 ? [Number(r.x) + Number(r.width) / 2,Number(r.x) + m,Number(r.x) + Number(r.width) - m] : [Number(r.y) + Number(r.height) / 2,Number(r.y) + m,Number(r.y) + Number(r.height) - m];
         var i:int = 0;
         while(i < this.items.length)
         {
            if(i != param1)
            {
               var it:Object = this.items[i];
               if(param2) { out.push(Number(it.x),Number(it.x) + Number(it.w) / 2,Number(it.x) + Number(it.w)); }
               else { out.push(Number(it.y),Number(it.y) + Number(it.h) / 2,Number(it.y) + Number(it.h)); }
            }
            i++;
         }
         return out;
      }

      private function moveTo(param1:int, param2:Number, param3:Number, param4:Boolean):void
      {
         var it:Object = this.items[param1];
         var r:Object = this.hsb.viewRect();
         this.guidesX = [];
         this.guidesY = [];
         var nx:Number = param2;
         var ny:Number = param3;
         if(param4)
         {
            nx = this.snapAxis(param2,Number(it.w),this.targets(param1,true),this.guidesX,Number(r.x));
            ny = this.snapAxis(param3,Number(it.h),this.targets(param1,false),this.guidesY,Number(r.y));
         }
         nx = HorizonShipBuilder.clampNum(nx,Number(r.x),Number(r.x) + Math.max(0,Number(r.width) - Number(it.w)),nx);
         ny = HorizonShipBuilder.clampNum(ny,Number(r.y),Number(r.y) + Math.max(0,Number(r.height) - Number(it.h)),ny);
         it.x = nx;
         it.y = ny;
         this.hsb.moveBox(String(it.id),nx,ny);
      }

      private function settle(param1:int):void
      {
         var it:Object = this.items[param1];
         this.hsb.storeAnchor(String(it.id),Number(it.x),Number(it.y),Number(it.w),Number(it.h));
         this.guidesX = [];
         this.guidesY = [];
      }

      // ---- input from the builder ----------------------------------------------------------

      internal function pointer(param1:String, param2:Number, param3:Number):void
      {
         if(param1 == "D")
         {
            var hit:Object = this.hitAt(param2,param3);
            if(hit != null)
            {
               this.act(String(hit.id));
               return;
            }
            var i:int = this.items.length - 1;
            while(i >= 0)
            {
               var it:Object = this.items[i];
               if(param2 >= Number(it.x) && param2 < Number(it.x) + Number(it.w) && param3 >= Number(it.y) && param3 < Number(it.y) + Number(it.h))
               {
                  this.sel = i;
                  this.dragAt = i;
                  this.offX = param2 - Number(it.x);
                  this.offY = param3 - Number(it.y);
                  this.paint();
                  return;
               }
               i--;
            }
            var b:Object = this.barRect;
            if(b != null && param2 >= Number(b.x) && param2 < Number(b.x) + Number(b.w) && param3 >= Number(b.y) && param3 < Number(b.y) + Number(b.h))
            {
               this.dragBar = true;
               this.offX = param2 - this.barX;
               this.offY = param3 - this.barY;
            }
            return;
         }
         if(param1 == "M")
         {
            if(this.dragAt >= 0)
            {
               this.moveTo(this.dragAt,param2 - this.offX,param3 - this.offY,true);
               this.paint();
            }
            else if(this.dragBar)
            {
               this.barX = param2 - this.offX;
               this.barY = param3 - this.offY;
               this.paint();
            }
            return;
         }
         if(param1 == "U")
         {
            if(this.dragAt >= 0)
            {
               this.settle(this.dragAt);
               this.dragAt = -1;
               this.paint();
            }
            this.dragBar = false;
         }
      }

      internal function key(param1:String):void
      {
         if(this.items.length == 0) { return; }
         if(param1 == "tab" || param1 == "tabprev")
         {
            this.sel = (Math.max(0,this.sel) + (param1 == "tab" ? 1 : this.items.length - 1)) % this.items.length;
            this.paint();
            return;
         }
         // Shift+arrow arrives as left40, right40, up40, down40: one drawn grid cell.
         var fast:Boolean = param1.length > 2 && param1.substring(param1.length - 2) == "40";
         var dir:String = fast ? param1.substring(0,param1.length - 2) : param1;
         var step:Number = fast ? GRID_DRAWN : NUDGE;
         var dx:Number = dir == "left" ? -step : (dir == "right" ? step : 0);
         var dy:Number = dir == "up" ? -step : (dir == "down" ? step : 0);
         if((dx != 0 || dy != 0) && this.sel >= 0)
         {
            var it:Object = this.items[this.sel];
            this.moveTo(this.sel,Number(it.x) + dx,Number(it.y) + dy,false);
            this.settle(this.sel);
            this.paint();
         }
      }

      private function act(param1:String):void
      {
         if(param1 == "ok") { this.ok(); }
         else if(param1 == "cancel") { this.cancel(); }
         else if(param1 == "reset")
         {
            this.hsb.resetLayout();
            this.barX = 0;
            this.barY = 0;
            this.items = this.hsb.arrangeBoxes();
            this.paint();
         }
      }

      internal function ok():void
      {
         this.visible = false;
         this.wipe();
         this.hsb.arrangeDone(true,null,this.barX,this.barY);
      }

      internal function cancel():void
      {
         this.visible = false;
         this.wipe();
         this.hsb.arrangeDone(false,this.savedLay,this.savedBarX,this.savedBarY);
      }
   }
}
