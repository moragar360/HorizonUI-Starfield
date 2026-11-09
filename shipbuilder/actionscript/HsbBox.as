package
{
   import flash.display.Bitmap;
   import flash.display.DisplayObject;
   import flash.display.Graphics;
   import flash.display.Sprite;

   // Purpose: one Horizon panel, popover or dialog. Its controls are rectangles recorded while it
   //    draws; the builder hit-tests them with the pointer the DLL feeds, because the engine
   //    gives presses over the ship view to the editor before Scaleform sees them (p5 finding).
   // Inputs: drawing calls from the owner; pointer points in stage coordinates.
   // Outputs: the topmost control under a point, as {id, data, x, y, w, h}; input hooks that
   //    subclasses override (press, move, release, hover, wheel, key, char, act, close).
   // Dependencies: HsbKit for the look. No Scaleform mouse listeners are used.
   // Author: Moragar. Last modified: 2026-11-08.
   public class HsbBox extends Sprite
   {
      internal var kit:HsbKit;
      internal var hits:Array;
      internal var boxW:Number = 0;
      internal var boxH:Number = 0;
      // Popups: a press outside closes a light-dismiss popup; anchor -1 centres it on screen; a
      // modal popup dims everything below it.
      internal var lightDismiss:Boolean = false;
      internal var modal:Boolean = false;
      internal var anchorX:Number = -1;
      internal var anchorY:Number = -1;
      // Keyboard and controller focus: an index into hits, drawn as a ring over that control.
      internal var focusAt:int = -1;
      private var ring:Sprite;
      private var ink:Sprite;

      // The box takes Scaleform hit tests (mouseEnabled) so the engine sees a UI element under
      // the pointer, but no Scaleform listener is attached: input comes from the DLL feed.
      public function HsbBox(param1:HsbKit, param2:String)
      {
         super();
         this.kit = param1;
         this.name = param2;
         this.hits = [];
         this.mouseEnabled = true;
         this.mouseChildren = false;
         this.newInk();
      }

      // Shapes go on the ink layer; the card goes into the box's own graphics, which Flash
      // renders under every child. A card sized after the contents are measured therefore
      // still sits under them.
      internal function get gfx():Graphics
      {
         return this.ink.graphics;
      }

      private function newInk():void
      {
         this.ink = new Sprite();
         this.ink.name = "ink";
         this.ink.mouseEnabled = false;
         this.addChild(this.ink);
      }

      internal function wipe():void
      {
         this.kit.forget(this);
         while(this.numChildren > 0)
         {
            var child:DisplayObject = this.getChildAt(0);
            this.removeChildAt(0);
            var pic:Bitmap = child as Bitmap;
            if(pic != null && pic.bitmapData != null)
            {
               pic.bitmapData.dispose();
               pic.bitmapData = null;
            }
         }
         this.graphics.clear();
         this.hits = [];
         this.newInk();
      }

      // Ids starting with "_" are drawing anchors, not controls.
      internal function focusable(param1:Object):Boolean
      {
         return param1 != null && Number(param1.w) > 0 && Number(param1.h) > 0 && String(param1.id).charAt(0) != "_";
      }

      internal function moveFocus(param1:int):void
      {
         var n:int = this.hits.length;
         if(n == 0)
         {
            this.focusAt = -1;
            this.drawFocus();
            return;
         }
         var at:int = this.focusAt;
         var tries:int = 0;
         while(tries < n)
         {
            at = at < 0 || at >= n ? (param1 > 0 ? 0 : n - 1) : (at + param1 + n) % n;
            if(this.focusable(this.hits[at])) { break; }
            tries++;
         }
         this.focusAt = tries < n ? at : -1;
         this.drawFocus();
      }

      internal function focusedHit():Object
      {
         if(this.focusAt < 0 || this.focusAt >= this.hits.length) { return null; }
         var r:Object = this.hits[this.focusAt];
         return this.focusable(r) ? r : null;
      }

      // Call at the end of every paint: the ring sits above the drawn controls.
      internal function drawFocus():void
      {
         if(this.ring == null)
         {
            this.ring = new Sprite();
            this.ring.mouseEnabled = false;
         }
         this.ring.graphics.clear();
         var r:Object = this.focusedHit();
         if(r == null)
         {
            if(this.ring.parent == this) { this.removeChild(this.ring); }
            return;
         }
         this.kit.outline(this.ring.graphics,Number(r.x) - 3,Number(r.y) - 3,Number(r.w) + 6,Number(r.h) + 6,7,this.kit.accent,1,2);
         this.addChild(this.ring);
      }

      // The recorded control with this id (and data, when given), or null.
      internal function hitFor(param1:String, param2:* = null):Object
      {
         var i:int = 0;
         while(i < this.hits.length)
         {
            var r:Object = this.hits[i];
            if(String(r.id) == param1 && (param2 === null || r.data === param2)) { return r; }
            i++;
         }
         return null;
      }

      // Places a popup just under one of this box's controls (coordinates of the builder).
      internal function anchorUnder(param1:HsbBox, param2:Object):void
      {
         if(param2 == null) { return; }
         param1.anchorX = this.x + Number(param2.x) * this.scaleX;
         param1.anchorY = this.y + (Number(param2.y) + Number(param2.h) + 4) * this.scaleY;
      }

      // Shared popup keys: arrows and tab walk the controls; ok presses the focused one.
      internal function navKey(param1:String):Boolean
      {
         if(param1 == "up" || param1 == "left" || param1 == "tabprev")
         {
            this.moveFocus(-1);
            return true;
         }
         if(param1 == "down" || param1 == "right" || param1 == "tab")
         {
            this.moveFocus(1);
            return true;
         }
         var r:Object = this.focusedHit();
         if((param1 == "ok" || param1 == "x") && r != null)
         {
            this.onAct(String(r.id),r.data);
            return true;
         }
         return false;
      }

      internal function hit(param1:Number, param2:Number, param3:Number, param4:Number, param5:String, param6:* = null):void
      {
         this.hits.push({"x":param1,"y":param2,"w":param3,"h":param4,"id":param5,"data":param6});
      }

      internal function localX(param1:Number):Number
      {
         return (param1 - this.x) / (this.scaleX != 0 ? this.scaleX : 1);
      }

      internal function localY(param1:Number):Number
      {
         return (param1 - this.y) / (this.scaleY != 0 ? this.scaleY : 1);
      }

      // Later rectangles sit on top: rows are recorded after their group, popovers last.
      internal function hitAt(param1:Number, param2:Number):Object
      {
         if(!this.visible || this.parent == null) { return null; }
         var lx:Number = this.localX(param1);
         var ly:Number = this.localY(param2);
         var i:int = this.hits.length - 1;
         while(i >= 0)
         {
            var r:Object = this.hits[i];
            if(lx >= r.x && lx < r.x + r.w && ly >= r.y && ly < r.y + r.h) { return r; }
            i--;
         }
         return null;
      }

      internal function contains2(param1:Number, param2:Number):Boolean
      {
         if(!this.visible || this.parent == null) { return false; }
         var lx:Number = this.localX(param1);
         var ly:Number = this.localY(param2);
         return lx >= 0 && lx < this.boxW && ly >= 0 && ly < this.boxH;
      }

      internal function add(param1:DisplayObject, param2:Number, param3:Number):DisplayObject
      {
         param1.x = param2;
         param1.y = param3;
         this.addChild(param1);
         return param1;
      }

      // Return true to keep receiving move and release (a drag); false lets the owner act on
      // the hit id.
      internal function onPress(param1:Object, param2:Number, param3:Number):Boolean
      {
         return false;
      }

      internal function onMove(param1:Number, param2:Number):void
      {
      }

      internal function onRelease(param1:Number, param2:Number):void
      {
      }

      internal function onHover(param1:Number, param2:Number):void
      {
      }

      internal function onWheel(param1:Number, param2:Number, param3:Number):void
      {
      }

      // Tokens: cancel, ok, up, down, left, right, tab, tabprev, pgup, pgdn, home, end, del,
      // bksp, x, y. Return true when handled.
      internal function onKey(param1:String):Boolean
      {
         return false;
      }

      internal function onChar(param1:int):void
      {
      }

      internal function onAct(param1:String, param2:*):void
      {
      }

      internal function onClose(param1:Boolean):void
      {
      }
   }
}
