package
{
   import Shared.GlobalFunc;
   import flash.display.Bitmap;
   import flash.display.BitmapData;
   import flash.display.DisplayObject;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.geom.Matrix;
   import flash.text.TextField;
   import flash.text.TextFormat;

   // Purpose: the builder's whole look in one place: colours measured from the approved gold
   //    mockups, text on the proven game face, panel and control shapes, vector icons, and the
   //    vanilla number format.
   // Inputs: the accent and card opacity from the user settings; the proven face names.
   // Outputs: TextFields and drawing into Graphics. It holds no game state.
   // Dependencies: Shared.GlobalFunc (FormatNumberToString), already inside the vanilla movie.
   // Author: Moragar. Last modified: 2026-11-09.
   public class HsbKit
   {
      internal static const FILL:uint = 0x0B1016;
      internal static const EDGE:uint = 0x22292E;
      internal static const EDGE_HI:uint = 0x3A444B;
      internal static const ROW:uint = 0x181E24;
      internal static const ROW_OPEN:uint = 0x1F2429;
      internal static const HEAD:uint = 0x192027;
      internal static const FIELD:uint = 0x0E1419;
      // Every selected row in the gold mockups uses this dark teal, whatever the accent.
      internal static const SELECT:uint = 0x142D33;
      internal static const TEXT:uint = 0xF2F4F5;
      internal static const LABEL:uint = 0xB4BBC0;
      internal static const MUTED:uint = 0x8A9298;
      internal static const DIM:uint = 0x5C646A;
      internal static const GREEN:uint = 0x6FE3A6;
      internal static const GREEN_BG:uint = 0x16302A;
      internal static const RED:uint = 0xFF6A6A;
      internal static const RED_BG:uint = 0x34191D;
      // Attention states: the gold accent is too close to amber, so warnings are orange (D6).
      internal static const ORANGE:uint = 0xF28A4F;
      internal static const ORANGE_BG:uint = 0x2E1D12;
      internal static const INK_ON_ACCENT:uint = 0x15130A;
      // A drawn glyph is ink. A blank picture (every sample under this alpha) is not.
      internal static const INK_ALPHA:uint = 16;
      internal static const INK_COUNT:int = 8;
      // Room around a button label (11 each side).
      private static const BUTTON_PAD:Number = 22;

      internal var accent:uint = 0xE8C547;
      internal var opacity:Number = 0.94;
      internal var lrg:Boolean = false;
      internal var face:String = "";
      internal var boldFace:String = "";
      // fontStyle of the chosen faces. "boldItalic" sets both flags. A regular face sets neither.
      internal var faceStyle:String = "";
      internal var boldStyle:String = "";
      internal var embed:Boolean = false;
      private var fields:Array = [];

      public function HsbKit()
      {
         super();
      }

      // Text sizes grow 20% in the large-font movie. Captions are the floor: 12 units, 15 large.
      internal function size(param1:Number):int
      {
         var n:Number = this.lrg ? Math.round(param1 * 1.2) : param1;
         var floor:Number = this.lrg ? 15 : 12;
         return int(n < floor ? floor : n);
      }

      // Layout lengths that follow text height in the large movie.
      internal function u(param1:Number):Number
      {
         return this.lrg ? Math.round(param1 * 1.15) : param1;
      }

      internal function accentDim(param1:Number):uint
      {
         return mix(this.accent,FILL,param1);
      }

      // "bold" and "boldItalic" contain bold. "italic" and "boldItalic" contain italic.
      internal static function styleHas(param1:String, param2:String):Boolean
      {
         if(param1 == null || param2 == null || param2.length == 0) { return false; }
         return param1.toLowerCase().indexOf(param2) >= 0;
      }

      internal static function mix(param1:uint, param2:uint, param3:Number):uint
      {
         var r:Number = ((param1 >> 16) & 255) * param3 + ((param2 >> 16) & 255) * (1 - param3);
         var g:Number = ((param1 >> 8) & 255) * param3 + ((param2 >> 8) & 255) * (1 - param3);
         var b:Number = (param1 & 255) * param3 + (param2 & 255) * (1 - param3);
         return (uint(r) << 16) | (uint(g) << 8) | uint(b);
      }

      // A non-interactive field. All Horizon controls are hit-tested from the plugin's pointer
      // feed, so no field ever needs Scaleform mouse input.
      internal function text(param1:Number, param2:uint, param3:Boolean = false, param4:Number = 0, param5:String = "left"):TextField
      {
         var tf:TextField = new TextField();
         tf.mouseEnabled = false;
         tf.selectable = false;
         tf.embedFonts = this.face.length > 0 || this.boldFace.length > 0 || this.embed;
         var fmt:TextFormat = this.format(param1,param2,param3,param4,param5);
         tf.defaultTextFormat = fmt;
         tf.width = 200;
         tf.height = this.size(param1) + 8;
         tf.text = "";
         this.fields.push({"tf":tf,"bold":param3,"kind":param3 ? "head" : "body"});
         return tf;
      }

      // Category tabs read upward. Scaleform turns a TextField only when its face is embedded
      // in this movie. The stock editor does not export the mapped faces, so those labels are
      // drawn flat and the picture is turned. A picture with no ink, or a draw that throws,
      // leaves the field upright so the words are still readable.
      internal function turnUp(param1:TextField):DisplayObject
      {
         if(this.embed)
         {
            param1.rotation = -90;
            return param1;
         }
         var w:int = int(Math.ceil(param1.width));
         var h:int = int(Math.ceil(param1.height));
         if(w < 1) { w = 1; }
         if(h < 1) { h = 1; }
         var pixels:BitmapData = null;
         try
         {
            pixels = new BitmapData(w,h,true,0);
            pixels.draw(param1);
            if(!this.inked(pixels,INK_COUNT,INK_ALPHA))
            {
               pixels.dispose();
               param1.rotation = 0;
               return param1;
            }
         }
         catch(err:Error)
         {
            if(pixels != null) { pixels.dispose(); }
            param1.rotation = 0;
            return param1;
         }
         var pic:Bitmap = new Bitmap(pixels,"auto",false);
         pic.rotation = -90;
         return pic;
      }

      // True when at least param2 samples have alpha above param3. A fully transparent
      // picture fails. Scanning stops at the count.
      internal function inked(param1:BitmapData, param2:int, param3:uint):Boolean
      {
         if(param1 == null || param2 < 1) { return false; }
         var ink:int = 0;
         var y:int = 0;
         var h:int = param1.height;
         var w:int = param1.width;
         while(y < h)
         {
            var x:int = 0;
            while(x < w)
            {
               var pix:uint = param1.getPixel32(x,y);
               if((pix >>> 24) > param3)
               {
                  ink++;
                  if(ink >= param2) { return true; }
               }
               x++;
            }
            y++;
         }
         return false;
      }

      // The module-name field is already on screen. Sample a scaled picture of it.
      // 1: at least INK_COUNT pixels have alpha above INK_ALPHA.
      // 0: the sample ran and the field has no such ink, or it has no text.
      // -1: the field has no positive size, so there is nothing to sample.
      // -2: the sample threw. An empty field and a thrown sample are not ink.
      internal function nativeDraws(param1:TextField):int
      {
         if(param1 == null || param1.text == null || param1.text.length == 0) { return 0; }
         var srcW:Number = param1.width;
         var srcH:Number = param1.height;
         if(!(srcW > 0) || !(srcH > 0)) { return -1; }
         var dw:int = srcW > 80 ? 80 : int(Math.ceil(srcW));
         var dh:int = srcH > 32 ? 32 : int(Math.ceil(srcH));
         if(dw < 1) { dw = 1; }
         if(dh < 1) { dh = 1; }
         var pixels:BitmapData = null;
         try
         {
            pixels = new BitmapData(dw,dh,true,0);
            var fit:Matrix = new Matrix();
            fit.scale(dw / srcW,dh / srcH);
            pixels.draw(param1,fit);
            var ink:Boolean = this.inked(pixels,INK_COUNT,INK_ALPHA);
            pixels.dispose();
            return ink ? 1 : 0;
         }
         catch(err:Error)
         {
            if(pixels != null) { pixels.dispose(); }
            return -2;
         }
         return -2;
      }

      internal function format(param1:Number, param2:uint, param3:Boolean, param4:Number, param5:String):TextFormat
      {
         var fmt:TextFormat = new TextFormat();
         var head:Boolean = param3 && this.boldFace.length > 0;
         var pick:String = head ? this.boldFace : this.face;
         var style:String = head ? this.boldStyle : this.faceStyle;
         if(pick.length > 0) { fmt.font = pick; }
         fmt.bold = HsbKit.styleHas(style,"bold");
         fmt.italic = HsbKit.styleHas(style,"italic");
         fmt.size = this.size(param1);
         fmt.color = param2;
         fmt.letterSpacing = param4;
         fmt.align = param5;
         return fmt;
      }

      // A $ key is translated when the field takes it, as on the game's own fields.
      internal function put(param1:TextField, param2:*, param3:int = -1):void
      {
         var fmt:TextFormat = param1.defaultTextFormat;
         if(param3 >= 0)
         {
            fmt.color = uint(param3);
            param1.defaultTextFormat = fmt;
         }
         param1.text = param2 == null ? "" : String(param2);
         param1.setTextFormat(fmt);
      }

      // The translated game label in capitals. A key the translator kept falls back to the
      // English word, so a missing string table never shows a raw $ key.
      internal function putCaps(param1:TextField, param2:String, param3:String, param4:int = -1):void
      {
         this.put(param1,param2,param4);
         if(param1.text.length == 0 || param1.text.charAt(0) == "$") { this.put(param1,param3,param4); }
         this.put(param1,param1.text.toUpperCase(),param4);
      }

      // Width fits the text so the next item can sit after it. A text wider than the room ends
      // in an ellipsis (the longest start that fits) instead of being cut through a letter.
      internal function fit(param1:TextField, param2:Number = 0):Number
      {
         param1.width = Math.max(4,param1.textWidth + 6);
         param1.height = param1.textHeight + 6;
         if(param2 > 0 && param1.width > param2)
         {
            var full:String = param1.text;
            var lo:int = 0;
            var hi:int = full.length - 1;
            while(lo < hi)
            {
               var mid:int = (lo + hi + 1) >> 1;
               param1.text = full.substring(0,mid) + "\u2026";
               if(param1.textWidth + 6 <= param2) { lo = mid; }
               else { hi = mid - 1; }
            }
            param1.text = full.substring(0,lo) + "\u2026";
            param1.width = param2;
         }
         return param1.width;
      }

      // The first on-stage field of each kind is logged after the first build.
      internal function retag(param1:TextField, param2:String):void
      {
         var i:int = this.fields.length - 1;
         while(i >= 0)
         {
            var row:Object = this.fields[i];
            if(row.tf == param1)
            {
               row.kind = param2;
               return;
            }
            i--;
         }
      }

      internal function fieldReport():Array
      {
         var out:Array = [];
         var seen:Object = {};
         var i:int = 0;
         while(i < this.fields.length)
         {
            var row:Object = this.fields[i];
            var tf:TextField = row.tf as TextField;
            var kind:String = row.kind != null ? String(row.kind) : "body";
            if(tf != null && tf.parent != null && seen[kind] != true)
            {
               seen[kind] = true;
               var shown:String = "-";
               var boldBit:int = 0;
               var italicBit:int = 0;
               try
               {
                  var fmt:TextFormat = tf.getTextFormat();
                  if(fmt != null)
                  {
                     if(fmt.font != null && String(fmt.font).length > 0) { shown = String(fmt.font); }
                     boldBit = fmt.bold ? 1 : 0;
                     italicBit = fmt.italic ? 1 : 0;
                  }
               }
               catch(err:Error) { shown = "-"; }
               out.push("FONT field kind=" + kind + " font=" + shown + " embed=" + (tf.embedFonts ? 1 : 0) + " bold=" + boldBit + " italic=" + italicBit + " w=" + int(tf.textWidth) + " n=" + tf.text.length);
            }
            i++;
         }
         return out;
      }

      internal function refreshFaces():void
      {
         var kept:Array = [];
         var i:int = 0;
         while(i < this.fields.length)
         {
            var row:Object = this.fields[i];
            var tf:TextField = row.tf as TextField;
            if(tf != null && tf.parent != null)
            {
               var fmt:TextFormat = tf.defaultTextFormat;
               var head:Boolean = row.bold == true && this.boldFace.length > 0;
               var pick:String = head ? this.boldFace : this.face;
               var style:String = head ? this.boldStyle : this.faceStyle;
               fmt.font = pick.length > 0 ? pick : null;
               fmt.bold = HsbKit.styleHas(style,"bold");
               fmt.italic = HsbKit.styleHas(style,"italic");
               tf.embedFonts = this.face.length > 0 || this.boldFace.length > 0 || this.embed;
               tf.defaultTextFormat = fmt;
               tf.setTextFormat(fmt);
               kept.push(row);
            }
            i++;
         }
         this.fields = kept;
      }

      // Called when a box repaints or closes. Fields used only to measure text were never added
      // to a box; they are dropped here too, so the list cannot grow across repaints.
      internal function forget(param1:Sprite):void
      {
         var kept:Array = [];
         var i:int = 0;
         while(i < this.fields.length)
         {
            var tf:TextField = this.fields[i].tf as TextField;
            if(tf != null && tf.parent != null && !param1.contains(tf)) { kept.push(this.fields[i]); }
            i++;
         }
         this.fields = kept;
      }

      // Glass card: graphite fill at the card opacity and a 1 px edge, radius 14 as drawn.
      internal function card(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number = 14):void
      {
         param1.lineStyle();
         param1.beginFill(EDGE,Math.min(1,this.opacity + 0.04));
         param1.drawRoundRect(param2,param3,param4,param5,param6 * 2,param6 * 2);
         param1.endFill();
         param1.beginFill(FILL,this.opacity);
         param1.drawRoundRect(param2 + 1,param3 + 1,param4 - 2,param5 - 2,param6 * 2 - 2,param6 * 2 - 2);
         param1.endFill();
      }

      internal function fill(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number, param7:uint, param8:Number = 1):void
      {
         param1.lineStyle();
         param1.beginFill(param7,param8);
         if(param6 > 0) { param1.drawRoundRect(param2,param3,param4,param5,param6 * 2,param6 * 2); }
         else { param1.drawRect(param2,param3,param4,param5); }
         param1.endFill();
      }

      internal function outline(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number, param7:uint, param8:Number = 1, param9:Number = 1):void
      {
         param1.lineStyle(param9,param7,param8,true);
         param1.drawRoundRect(param2 + 0.5,param3 + 0.5,param4 - 1,param5 - 1,param6 * 2,param6 * 2);
         param1.lineStyle();
      }

      // Dashed rounded outline, used by pills that are off and by "+ New pill". Corners are
      // drawn whole; dashes run along the straight edges.
      internal function dashed(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number, param7:uint, param8:Number = 1):void
      {
         var r:Number = Math.min(param6,param5 / 2,param4 / 2);
         param1.lineStyle(1,param7,param8,true);
         this.dashLine(param1,param2 + r,param3 + 0.5,param2 + param4 - r,param3 + 0.5);
         this.dashLine(param1,param2 + r,param3 + param5 - 0.5,param2 + param4 - r,param3 + param5 - 0.5);
         this.dashLine(param1,param2 + 0.5,param3 + r,param2 + 0.5,param3 + param5 - r);
         this.dashLine(param1,param2 + param4 - 0.5,param3 + r,param2 + param4 - 0.5,param3 + param5 - r);
         this.arc(param1,param2 + r,param3 + r,r - 0.5,180,270);
         this.arc(param1,param2 + param4 - r,param3 + r,r - 0.5,270,360);
         this.arc(param1,param2 + param4 - r,param3 + param5 - r,r - 0.5,0,90);
         this.arc(param1,param2 + r,param3 + param5 - r,r - 0.5,90,180);
         param1.lineStyle();
      }

      private function dashLine(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number):void
      {
         var len:Number = Math.sqrt((param4 - param2) * (param4 - param2) + (param5 - param3) * (param5 - param3));
         if(len <= 0) { return; }
         var dx:Number = (param4 - param2) / len;
         var dy:Number = (param5 - param3) / len;
         var at:Number = 0;
         while(at < len)
         {
            // Mockup 1 dashes: 5 px on, 3 px off.
            var end:Number = Math.min(len,at + 5);
            param1.moveTo(param2 + dx * at,param3 + dy * at);
            param1.lineTo(param2 + dx * end,param3 + dy * end);
            at += 8;
         }
      }

      private function arc(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number, param6:Number):void
      {
         if(param4 <= 0) { return; }
         var steps:int = 6;
         var i:int = 0;
         while(i <= steps)
         {
            var a:Number = (param5 + (param6 - param5) * i / steps) * Math.PI / 180;
            var px:Number = param2 + Math.cos(a) * param4;
            var py:Number = param3 + Math.sin(a) * param4;
            if(i == 0) { param1.moveTo(px,py); }
            else { param1.lineTo(px,py); }
            i++;
         }
      }

      internal function hline(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:uint = 0x1D2328, param6:Number = 1):void
      {
         param1.lineStyle();
         param1.beginFill(param5,param6);
         param1.drawRect(param2,param3,param4,1);
         param1.endFill();
      }

      internal function vline(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:uint = 0x1D2328, param6:Number = 1):void
      {
         param1.lineStyle();
         param1.beginFill(param5,param6);
         param1.drawRect(param2,param3,1,param4);
         param1.endFill();
      }

      // 38 x 18 switch, as Horizon's F11 window draws it.
      internal function toggle(param1:Graphics, param2:Number, param3:Number, param4:Boolean, param5:Boolean = true):void
      {
         var w:Number = this.u(38);
         var h:Number = this.u(18);
         var on:uint = param5 ? this.accent : mix(this.accent,FILL,0.45);
         this.fill(param1,param2,param3,w,h,h / 2,param4 ? on : 0x2A3238,1);
         var knob:Number = h - 6;
         var kx:Number = param4 ? param2 + w - knob - 3 : param2 + 3;
         this.fill(param1,kx,param3 + 3,knob,knob,knob / 2,param4 ? INK_ON_ACCENT : 0x8D959B,1);
      }

      // Shapes on a Horizon box go to its ink layer (above its card); any other sprite draws
      // into its own graphics.
      internal static function inkOf(param1:Sprite):Graphics
      {
         var b:HsbBox = param1 as HsbBox;
         return b != null ? b.gfx : param1.graphics;
      }

      // Key cap: rounded outline with the live key name inside. Returns the cap width.
      internal function keycap(param1:Sprite, param2:Number, param3:Number, param4:String, param5:uint, param6:Number = 0):Number
      {
         var tf:TextField = this.text(12,param5,true,0.5);
         this.put(tf,param4);
         this.fit(tf);
         var h:Number = param6 > 0 ? param6 : this.u(22);
         var w:Number = Math.max(h,tf.textWidth + this.u(12));
         this.outline(inkOf(param1),param2,param3,w,h,5,param5,0.85,1);
         tf.x = param2 + (w - tf.width) / 2;
         tf.y = param3 + (h - tf.height) / 2;
         param1.addChild(tf);
         return w;
      }

      // Diff chip: green when higher, red when lower, as the game's HigherValue/LowerValue frames.
      internal function diffChip(param1:Sprite, param2:Number, param3:Number, param4:String, param5:Boolean, param6:Number = 0):Number
      {
         var tf:TextField = this.text(12,param5 ? GREEN : RED,true);
         this.put(tf,param4);
         this.fit(tf);
         var h:Number = param6 > 0 ? param6 : this.u(20);
         var w:Number = Math.max(h + 4,tf.textWidth + this.u(12));
         this.fill(inkOf(param1),param2,param3,w,h,5,param5 ? GREEN_BG : RED_BG,1);
         tf.x = param2 + (w - tf.width) / 2;
         tf.y = param3 + (h - tf.height) / 2;
         param1.addChild(tf);
         return w;
      }

      // Count chip such as the "5" beside a maker name.
      internal function countChip(param1:Sprite, param2:Number, param3:Number, param4:String, param5:Boolean):Number
      {
         var tf:TextField = this.text(12,param5 ? this.accent : LABEL,true);
         this.put(tf,param4);
         this.fit(tf);
         var h:Number = this.u(20);
         var w:Number = Math.max(h,tf.textWidth + this.u(12));
         this.fill(inkOf(param1),param2,param3,w,h,5,param5 ? mix(this.accent,FILL,0.22) : 0x262D33,1);
         tf.x = param2 + (w - tf.width) / 2;
         tf.y = param3 + (h - tf.height) / 2;
         param1.addChild(tf);
         return w;
      }

      // One fitted text added to a box: the common case for every label in the popups.
      internal function label(param1:Sprite, param2:Number, param3:Number, param4:String, param5:Number, param6:uint, param7:Boolean = false, param8:Number = 0, param9:Number = 0):TextField
      {
         var tf:TextField = this.text(param5,param6,param7,param8);
         this.put(tf,param4);
         this.fit(tf,param9);
         tf.x = param2;
         tf.y = param3;
         param1.addChild(tf);
         return tf;
      }

      // Rounded text button shared by every Horizon panel and popup; records its hit rectangle.
      // Styles: accent (filled), outline, accentOutline, red, orange, dim (drawn, never hit).
      // Returns the width so the caller can place the next button.
      internal function button(param1:HsbBox, param2:Number, param3:Number, param4:String, param5:String, param6:String, param7:* = null, param8:Number = 0, param9:Number = 0):Number
      {
         var g:Graphics = param1.gfx;
         var h:Number = param8 > 0 ? param8 : this.u(28);
         var ink:uint = TEXT;
         if(param5 == "accent") { ink = INK_ON_ACCENT; }
         else if(param5 == "accentOutline") { ink = this.accent; }
         else if(param5 == "red") { ink = RED; }
         else if(param5 == "orange") { ink = ORANGE; }
         else if(param5 == "dim") { ink = DIM; }
         var t:TextField = this.text(13,ink,true,1);
         this.retag(t,"button");
         this.put(t,param4);
         this.fit(t);
         var w:Number = Math.max(param9,t.width + BUTTON_PAD);
         if(param5 == "accent") { this.fill(g,param2,param3,w,h,h / 2,this.accent,1); }
         else
         {
            var edge:uint = EDGE_HI;
            var back:uint = 0x1A2128;
            if(param5 == "accentOutline") { edge = this.accent; }
            else if(param5 == "red") { edge = RED; back = RED_BG; }
            else if(param5 == "orange") { edge = ORANGE; back = ORANGE_BG; }
            else if(param5 == "dim") { edge = EDGE; }
            this.fill(g,param2,param3,w,h,h / 2,back,1);
            this.outline(g,param2,param3,w,h,h / 2,edge,1);
         }
         t.x = param2 + (w - t.width) / 2;
         t.y = param3 + (h - t.height) / 2;
         param1.addChild(t);
         if(param5 != "dim") { param1.hit(param2,param3,w,h,param6,param7); }
         return w;
      }

      // Width button() gives a label (param2 is the same minimum), so a row can be right-aligned
      // before it is drawn.
      internal function buttonWidth(param1:String, param2:Number = 0):Number
      {
         var t:TextField = this.text(13,TEXT,true,1);
         this.put(t,param1);
         this.fit(t);
         return Math.max(param2,t.width + BUTTON_PAD);
      }

      // Segmented control; the chosen segment is filled with the accent. Each segment records a
      // hit with its index as data. A disabled control draws dim and records no hits. param9 and
      // param10 are the padding around each label and its letter spacing; a crowded row
      // (mockup 6, APPLY TO) uses 16 and 0.6 before it shortens labels.
      internal function segments(param1:HsbBox, param2:Number, param3:Number, param4:Array, param5:int, param6:String, param7:Number = 0, param8:Boolean = true, param9:Number = 20, param10:Number = 1.2):Number
      {
         var g:Graphics = param1.gfx;
         var h:Number = param7 > 0 ? param7 : this.u(26);
         var fields:Array = [];
         var total:Number = 0;
         var i:int = 0;
         while(i < param4.length)
         {
            var on:Boolean = i == param5 && param8;
            var t:TextField = this.text(12,on ? INK_ON_ACCENT : (param8 ? LABEL : DIM),true,param10);
            this.put(t,String(param4[i]));
            this.fit(t);
            fields.push(t);
            total += t.width + param9;
            i++;
         }
         this.fill(g,param2,param3,total,h,6,FIELD,1);
         this.outline(g,param2,param3,total,h,6,param8 ? EDGE_HI : EDGE,1);
         var x:Number = param2;
         i = 0;
         while(i < fields.length)
         {
            var tf:TextField = fields[i] as TextField;
            var sw:Number = tf.width + param9;
            if(i == param5 && param8) { this.fill(g,x + 2,param3 + 2,sw - 4,h - 4,5,this.accent,1); }
            tf.x = x + param9 / 2;
            tf.y = param3 + (h - tf.height) / 2;
            param1.addChild(tf);
            if(param8) { param1.hit(x,param3,sw,h,param6,i); }
            x += sw;
            i++;
         }
         return total;
      }

      // Width segments() gives these labels with the same padding (param2) and letter spacing
      // (param3), so a crowded row can be fitted before it is drawn.
      internal function segmentsWidth(param1:Array, param2:Number = 20, param3:Number = 1.2):Number
      {
         var total:Number = 0;
         var t:TextField = this.text(12,LABEL,true,param3);
         var i:int = 0;
         while(i < param1.length)
         {
            this.put(t,String(param1[i]));
            this.fit(t);
            total += t.width + param2;
            i++;
         }
         return total;
      }

      // FormatNumberToString is what the game uses for every number on these panels. param2 is
      // the most decimal places shown: the game's lists and totals use none, the part card 2.
      internal static function num(param1:*, param2:uint = 0):String
      {
         if(param1 == null || param1 === undefined) { return ""; }
         var n:Number = Number(param1);
         if(isNaN(n)) { return ""; }
         return GlobalFunc.FormatNumberToString(n,param2);
      }

      // Two ends that print the same (12.2 and 12.7 at no places) show as one number.
      internal static function range(param1:Number, param2:Number, param3:uint = 0):String
      {
         if(isNaN(param1) || isNaN(param2)) { return "\u2014"; }
         var lo:String = num(param1,param3);
         var hi:String = num(param2,param3);
         return lo == hi ? lo : lo + "\u2013" + hi;
      }

      internal static function hex6(param1:uint):String
      {
         var s:String = (param1 & 0xFFFFFF).toString(16).toUpperCase();
         while(s.length < 6) { s = "0" + s; }
         return s;
      }

      internal static function parseHex(param1:String):int
      {
         var t:String = param1 == null ? "" : param1;
         if(t.charAt(0) == "#") { t = t.substring(1); }
         if(t.length != 6) { return -1; }
         var n:uint = 0;
         var i:int = 0;
         while(i < 6)
         {
            var c:Number = parseInt(t.charAt(i),16);
            if(isNaN(c)) { return -1; }
            n = (n << 4) + uint(c);
            i++;
         }
         return int(n);
      }

      // Standard HSB to RGB. The game's own conversion is not exposed, so a hex shown from the
      // picker's three values is an estimate (flagged in the Colors panel).
      internal static function hsb(param1:Number, param2:Number, param3:Number):uint
      {
         var h:Number = (param1 - Math.floor(param1)) * 6;
         var s:Number = Math.max(0,Math.min(1,param2));
         var v:Number = Math.max(0,Math.min(1,param3));
         var i:int = int(Math.floor(h));
         var f:Number = h - i;
         var p:Number = v * (1 - s);
         var q:Number = v * (1 - s * f);
         var t:Number = v * (1 - s * (1 - f));
         var r:Number = v;
         var g:Number = t;
         var b:Number = p;
         if(i == 1) { r = q; g = v; b = p; }
         else if(i == 2) { r = p; g = v; b = t; }
         else if(i == 3) { r = p; g = q; b = v; }
         else if(i == 4) { r = t; g = p; b = v; }
         else if(i >= 5) { r = v; g = p; b = q; }
         return (uint(Math.round(r * 255)) << 16) | (uint(Math.round(g * 255)) << 8) | uint(Math.round(b * 255));
      }

      internal static function toHsb(param1:uint):Array
      {
         var r:Number = ((param1 >> 16) & 255) / 255;
         var g:Number = ((param1 >> 8) & 255) / 255;
         var b:Number = (param1 & 255) / 255;
         var hi:Number = Math.max(r,g,b);
         var lo:Number = Math.min(r,g,b);
         var d:Number = hi - lo;
         var h:Number = 0;
         if(d > 0)
         {
            if(hi == r) { h = ((g - b) / d) % 6; }
            else if(hi == g) { h = (b - r) / d + 2; }
            else { h = (r - g) / d + 4; }
            h /= 6;
            if(h < 0) { h += 1; }
         }
         return [h,hi > 0 ? d / hi : 0,hi];
      }

      // Vector icons drawn in a square of side param5 at (param3, param4). No game art is used.
      internal function icon(param1:Graphics, param2:String, param3:Number, param4:Number, param5:Number, param6:uint, param7:Number = 1):void
      {
         var s:Number = param5;
         var cx:Number = param3 + s / 2;
         var cy:Number = param4 + s / 2;
         var t:Number = Math.max(1.2,s / 10);
         param1.lineStyle(t,param6,param7,true,"normal","round","round");
         switch(param2)
         {
            case "gear":
               param1.lineStyle();
               param1.beginFill(param6,param7);
               var k:int = 0;
               while(k < 8)
               {
                  var ang:Number = k * Math.PI / 4;
                  var tx:Number = cx + Math.cos(ang) * s * 0.36;
                  var ty:Number = cy + Math.sin(ang) * s * 0.36;
                  param1.drawCircle(tx,ty,s * 0.1);
                  k++;
               }
               param1.drawCircle(cx,cy,s * 0.32);
               param1.endFill();
               param1.beginFill(FILL,1);
               param1.drawCircle(cx,cy,s * 0.13);
               param1.endFill();
               break;
            case "eye":
            case "eyeOff":
               param1.moveTo(param3 + s * 0.06,cy);
               param1.curveTo(cx,param4 + s * 0.08,param3 + s * 0.94,cy);
               param1.curveTo(cx,param4 + s * 0.92,param3 + s * 0.06,cy);
               param1.drawCircle(cx,cy,s * 0.14);
               if(param2 == "eyeOff")
               {
                  param1.moveTo(param3 + s * 0.15,param4 + s * 0.88);
                  param1.lineTo(param3 + s * 0.85,param4 + s * 0.12);
               }
               break;
            case "search":
               param1.drawCircle(param3 + s * 0.42,param4 + s * 0.42,s * 0.28);
               param1.moveTo(param3 + s * 0.63,param4 + s * 0.63);
               param1.lineTo(param3 + s * 0.9,param4 + s * 0.9);
               break;
            case "chevR":
               param1.moveTo(param3 + s * 0.38,param4 + s * 0.22);
               param1.lineTo(param3 + s * 0.64,cy);
               param1.lineTo(param3 + s * 0.38,param4 + s * 0.78);
               break;
            case "chevL":
               param1.moveTo(param3 + s * 0.62,param4 + s * 0.22);
               param1.lineTo(param3 + s * 0.36,cy);
               param1.lineTo(param3 + s * 0.62,param4 + s * 0.78);
               break;
            case "chevD":
               param1.moveTo(param3 + s * 0.22,param4 + s * 0.38);
               param1.lineTo(cx,param4 + s * 0.64);
               param1.lineTo(param3 + s * 0.78,param4 + s * 0.38);
               break;
            case "chevU":
               param1.moveTo(param3 + s * 0.22,param4 + s * 0.62);
               param1.lineTo(cx,param4 + s * 0.36);
               param1.lineTo(param3 + s * 0.78,param4 + s * 0.62);
               break;
            case "chevUU":
               param1.moveTo(param3 + s * 0.25,param4 + s * 0.5);
               param1.lineTo(cx,param4 + s * 0.28);
               param1.lineTo(param3 + s * 0.75,param4 + s * 0.5);
               param1.moveTo(param3 + s * 0.25,param4 + s * 0.74);
               param1.lineTo(cx,param4 + s * 0.52);
               param1.lineTo(param3 + s * 0.75,param4 + s * 0.74);
               break;
            case "dockU":
               param1.moveTo(param3 + s * 0.22,param4 + s * 0.24);
               param1.lineTo(param3 + s * 0.78,param4 + s * 0.24);
               param1.moveTo(param3 + s * 0.26,param4 + s * 0.72);
               param1.lineTo(cx,param4 + s * 0.44);
               param1.lineTo(param3 + s * 0.74,param4 + s * 0.72);
               break;
            case "dockL":
               param1.moveTo(param3 + s * 0.24,param4 + s * 0.2);
               param1.lineTo(param3 + s * 0.24,param4 + s * 0.8);
               param1.moveTo(param3 + s * 0.7,param4 + s * 0.26);
               param1.lineTo(param3 + s * 0.44,cy);
               param1.lineTo(param3 + s * 0.7,param4 + s * 0.74);
               break;
            case "dockR":
               param1.moveTo(param3 + s * 0.76,param4 + s * 0.2);
               param1.lineTo(param3 + s * 0.76,param4 + s * 0.8);
               param1.moveTo(param3 + s * 0.3,param4 + s * 0.26);
               param1.lineTo(param3 + s * 0.56,cy);
               param1.lineTo(param3 + s * 0.3,param4 + s * 0.74);
               break;
            case "x":
               param1.moveTo(param3 + s * 0.28,param4 + s * 0.28);
               param1.lineTo(param3 + s * 0.72,param4 + s * 0.72);
               param1.moveTo(param3 + s * 0.72,param4 + s * 0.28);
               param1.lineTo(param3 + s * 0.28,param4 + s * 0.72);
               break;
            case "xCircle":
               param1.drawCircle(cx,cy,s * 0.42);
               param1.moveTo(param3 + s * 0.36,param4 + s * 0.36);
               param1.lineTo(param3 + s * 0.64,param4 + s * 0.64);
               param1.moveTo(param3 + s * 0.64,param4 + s * 0.36);
               param1.lineTo(param3 + s * 0.36,param4 + s * 0.64);
               break;
            case "plus":
               param1.moveTo(cx,param4 + s * 0.24);
               param1.lineTo(cx,param4 + s * 0.76);
               param1.moveTo(param3 + s * 0.24,cy);
               param1.lineTo(param3 + s * 0.76,cy);
               break;
            case "check":
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.52);
               param1.lineTo(param3 + s * 0.42,param4 + s * 0.74);
               param1.lineTo(param3 + s * 0.82,param4 + s * 0.3);
               break;
            case "checkCircle":
               param1.drawCircle(cx,cy,s * 0.42);
               param1.moveTo(param3 + s * 0.3,param4 + s * 0.52);
               param1.lineTo(param3 + s * 0.45,param4 + s * 0.66);
               param1.lineTo(param3 + s * 0.72,param4 + s * 0.38);
               break;
            case "diamond":
               param1.lineStyle();
               param1.beginFill(param6,param7);
               param1.moveTo(cx,param4 + s * 0.2);
               param1.lineTo(param3 + s * 0.8,cy);
               param1.lineTo(cx,param4 + s * 0.8);
               param1.lineTo(param3 + s * 0.2,cy);
               param1.lineTo(cx,param4 + s * 0.2);
               param1.endFill();
               break;
            case "dot":
               param1.lineStyle();
               param1.beginFill(param6,param7);
               param1.drawCircle(cx,cy,s * 0.22);
               param1.endFill();
               break;
            case "columns":
               param1.moveTo(param3 + s * 0.25,param4 + s * 0.2);
               param1.lineTo(param3 + s * 0.25,param4 + s * 0.8);
               param1.moveTo(cx,param4 + s * 0.2);
               param1.lineTo(cx,param4 + s * 0.8);
               param1.moveTo(param3 + s * 0.75,param4 + s * 0.2);
               param1.lineTo(param3 + s * 0.75,param4 + s * 0.8);
               break;
            case "rows":
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.3);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.3);
               param1.moveTo(param3 + s * 0.2,cy);
               param1.lineTo(param3 + s * 0.8,cy);
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.7);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.7);
               break;
            case "compact":
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.38);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.38);
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.62);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.62);
               break;
            case "lock":
               param1.drawRoundRect(param3 + s * 0.24,param4 + s * 0.46,s * 0.52,s * 0.38,4,4);
               param1.moveTo(param3 + s * 0.34,param4 + s * 0.46);
               param1.lineTo(param3 + s * 0.34,param4 + s * 0.34);
               param1.curveTo(cx,param4 + s * 0.08,param3 + s * 0.66,param4 + s * 0.34);
               param1.lineTo(param3 + s * 0.66,param4 + s * 0.46);
               break;
            case "sortDown":
               param1.lineStyle();
               param1.beginFill(param6,param7);
               param1.moveTo(param3 + s * 0.22,param4 + s * 0.36);
               param1.lineTo(param3 + s * 0.78,param4 + s * 0.36);
               param1.lineTo(cx,param4 + s * 0.72);
               param1.lineTo(param3 + s * 0.22,param4 + s * 0.36);
               param1.endFill();
               break;
            case "sortUp":
               param1.lineStyle();
               param1.beginFill(param6,param7);
               param1.moveTo(param3 + s * 0.22,param4 + s * 0.64);
               param1.lineTo(param3 + s * 0.78,param4 + s * 0.64);
               param1.lineTo(cx,param4 + s * 0.28);
               param1.lineTo(param3 + s * 0.22,param4 + s * 0.64);
               param1.endFill();
               break;
            case "handle":
               param1.lineStyle();
               param1.beginFill(param6,param7);
               var hr:int = 0;
               while(hr < 3)
               {
                  // Mockup 8 grip: two columns of three 3 px dots.
                  param1.drawCircle(param3 + s * 0.36,param4 + s * (0.25 + hr * 0.25),s * 0.095);
                  param1.drawCircle(param3 + s * 0.64,param4 + s * (0.25 + hr * 0.25),s * 0.095);
                  hr++;
               }
               param1.endFill();
               break;
            case "import":
               param1.moveTo(cx,param4 + s * 0.16);
               param1.lineTo(cx,param4 + s * 0.62);
               param1.moveTo(param3 + s * 0.32,param4 + s * 0.44);
               param1.lineTo(cx,param4 + s * 0.64);
               param1.lineTo(param3 + s * 0.68,param4 + s * 0.44);
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.84);
               break;
            case "export":
               param1.moveTo(cx,param4 + s * 0.66);
               param1.lineTo(cx,param4 + s * 0.18);
               param1.moveTo(param3 + s * 0.32,param4 + s * 0.38);
               param1.lineTo(cx,param4 + s * 0.16);
               param1.lineTo(param3 + s * 0.68,param4 + s * 0.38);
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.84);
               break;
            case "save":
               param1.drawRoundRect(param3 + s * 0.2,param4 + s * 0.2,s * 0.6,s * 0.6,3,3);
               param1.moveTo(param3 + s * 0.34,param4 + s * 0.2);
               param1.lineTo(param3 + s * 0.34,param4 + s * 0.4);
               param1.lineTo(param3 + s * 0.62,param4 + s * 0.4);
               param1.lineTo(param3 + s * 0.62,param4 + s * 0.2);
               break;
            case "dropper":
               param1.moveTo(param3 + s * 0.22,param4 + s * 0.8);
               param1.lineTo(param3 + s * 0.6,param4 + s * 0.42);
               param1.moveTo(param3 + s * 0.52,param4 + s * 0.32);
               param1.lineTo(param3 + s * 0.7,param4 + s * 0.5);
               param1.moveTo(param3 + s * 0.6,param4 + s * 0.4);
               param1.lineTo(param3 + s * 0.76,param4 + s * 0.24);
               break;
            case "warn":
               param1.moveTo(cx,param4 + s * 0.14);
               param1.lineTo(param3 + s * 0.9,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.1,param4 + s * 0.84);
               param1.lineTo(cx,param4 + s * 0.14);
               param1.moveTo(cx,param4 + s * 0.4);
               param1.lineTo(cx,param4 + s * 0.6);
               param1.moveTo(cx,param4 + s * 0.7);
               param1.lineTo(cx,param4 + s * 0.72);
               break;
            case "alert":
               param1.drawCircle(cx,cy,s * 0.42);
               param1.moveTo(cx,param4 + s * 0.28);
               param1.lineTo(cx,param4 + s * 0.54);
               param1.moveTo(cx,param4 + s * 0.68);
               param1.lineTo(cx,param4 + s * 0.7);
               break;
            case "info":
               param1.drawCircle(cx,cy,s * 0.42);
               param1.moveTo(cx,param4 + s * 0.46);
               param1.lineTo(cx,param4 + s * 0.7);
               param1.moveTo(cx,param4 + s * 0.3);
               param1.lineTo(cx,param4 + s * 0.32);
               break;
            case "question":
               param1.drawCircle(cx,cy,s * 0.42);
               param1.moveTo(param3 + s * 0.38,param4 + s * 0.38);
               param1.curveTo(cx,param4 + s * 0.18,param3 + s * 0.62,param4 + s * 0.38);
               param1.curveTo(param3 + s * 0.64,param4 + s * 0.5,cx,param4 + s * 0.56);
               param1.moveTo(cx,param4 + s * 0.7);
               param1.lineTo(cx,param4 + s * 0.72);
               break;
            case "globe":
               param1.drawCircle(cx,cy,s * 0.4);
               param1.moveTo(param3 + s * 0.1,cy);
               param1.lineTo(param3 + s * 0.9,cy);
               param1.drawEllipse(param3 + s * 0.32,param4 + s * 0.1,s * 0.36,s * 0.8);
               break;
            case "pack":
               param1.drawRoundRect(param3 + s * 0.14,param4 + s * 0.3,s * 0.52,s * 0.52,4,4);
               param1.moveTo(param3 + s * 0.34,param4 + s * 0.3);
               param1.lineTo(param3 + s * 0.34,param4 + s * 0.14);
               param1.lineTo(param3 + s * 0.86,param4 + s * 0.14);
               param1.lineTo(param3 + s * 0.86,param4 + s * 0.66);
               param1.lineTo(param3 + s * 0.66,param4 + s * 0.66);
               break;
            case "arrange":
               param1.drawRect(param3 + s * 0.18,param4 + s * 0.18,s * 0.26,s * 0.26);
               param1.drawRect(param3 + s * 0.56,param4 + s * 0.18,s * 0.26,s * 0.26);
               param1.drawRect(param3 + s * 0.18,param4 + s * 0.56,s * 0.26,s * 0.26);
               param1.drawRect(param3 + s * 0.56,param4 + s * 0.56,s * 0.26,s * 0.26);
               break;
            default:
               this.categoryIcon(param1,param2,param3,param4,s,param6,param7);
         }
         param1.lineStyle();
      }

      // Our own drawings for the 14 vanilla categories, plus a generic box for any category a
      // mod such as ShipBuilderCategories adds.
      private function categoryIcon(param1:Graphics, param2:String, param3:Number, param4:Number, param5:Number, param6:uint, param7:Number):void
      {
         var s:Number = param5;
         var cx:Number = param3 + s / 2;
         var cy:Number = param4 + s / 2;
         switch(param2)
         {
            case "cat:weapons":
               param1.drawCircle(cx,cy,s * 0.3);
               param1.moveTo(cx,param4 + s * 0.08);
               param1.lineTo(cx,param4 + s * 0.32);
               param1.moveTo(cx,param4 + s * 0.68);
               param1.lineTo(cx,param4 + s * 0.92);
               param1.moveTo(param3 + s * 0.08,cy);
               param1.lineTo(param3 + s * 0.32,cy);
               param1.moveTo(param3 + s * 0.68,cy);
               param1.lineTo(param3 + s * 0.92,cy);
               break;
            case "cat:engines":
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.3);
               param1.lineTo(param3 + s * 0.6,param4 + s * 0.3);
               param1.lineTo(param3 + s * 0.84,param4 + s * 0.16);
               param1.lineTo(param3 + s * 0.84,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.6,param4 + s * 0.7);
               param1.lineTo(param3 + s * 0.2,param4 + s * 0.7);
               param1.lineTo(param3 + s * 0.2,param4 + s * 0.3);
               break;
            case "cat:reactors":
               param1.drawCircle(cx,cy,s * 0.38);
               param1.drawCircle(cx,cy,s * 0.14);
               break;
            case "cat:gravdrives":
               param1.moveTo(param3 + s * 0.16,param4 + s * 0.3);
               param1.lineTo(param3 + s * 0.4,cy);
               param1.lineTo(param3 + s * 0.16,param4 + s * 0.7);
               param1.moveTo(param3 + s * 0.5,param4 + s * 0.3);
               param1.lineTo(param3 + s * 0.74,cy);
               param1.lineTo(param3 + s * 0.5,param4 + s * 0.7);
               break;
            case "cat:shields":
               param1.moveTo(cx,param4 + s * 0.12);
               param1.lineTo(param3 + s * 0.84,param4 + s * 0.26);
               param1.curveTo(param3 + s * 0.84,param4 + s * 0.76,cx,param4 + s * 0.9);
               param1.curveTo(param3 + s * 0.16,param4 + s * 0.76,param3 + s * 0.16,param4 + s * 0.26);
               param1.lineTo(cx,param4 + s * 0.12);
               break;
            case "cat:fueltanks":
               param1.drawRoundRect(param3 + s * 0.28,param4 + s * 0.12,s * 0.44,s * 0.76,s * 0.3,s * 0.3);
               param1.moveTo(param3 + s * 0.28,cy);
               param1.lineTo(param3 + s * 0.72,cy);
               break;
            case "cat:cargo":
               param1.drawRect(param3 + s * 0.16,param4 + s * 0.28,s * 0.68,s * 0.54);
               param1.moveTo(param3 + s * 0.16,param4 + s * 0.46);
               param1.lineTo(param3 + s * 0.84,param4 + s * 0.46);
               break;
            case "cat:cockpits":
               param1.moveTo(param3 + s * 0.12,param4 + s * 0.7);
               param1.curveTo(cx,param4 + s * 0.04,param3 + s * 0.88,param4 + s * 0.7);
               param1.lineTo(param3 + s * 0.12,param4 + s * 0.7);
               break;
            case "cat:habs":
               param1.moveTo(param3 + s * 0.14,param4 + s * 0.48);
               param1.lineTo(cx,param4 + s * 0.16);
               param1.lineTo(param3 + s * 0.86,param4 + s * 0.48);
               param1.moveTo(param3 + s * 0.24,param4 + s * 0.42);
               param1.lineTo(param3 + s * 0.24,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.76,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.76,param4 + s * 0.42);
               break;
            case "cat:bays":
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.16);
               param1.lineTo(param3 + s * 0.2,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.16);
               param1.moveTo(param3 + s * 0.36,param4 + s * 0.56);
               param1.lineTo(param3 + s * 0.64,param4 + s * 0.56);
               break;
            case "cat:dockers":
               param1.drawCircle(cx,cy,s * 0.36);
               param1.moveTo(cx,param4 + s * 0.14);
               param1.lineTo(cx,param4 + s * 0.86);
               break;
            case "cat:gear":
               param1.moveTo(param3 + s * 0.2,param4 + s * 0.2);
               param1.lineTo(param3 + s * 0.5,param4 + s * 0.6);
               param1.lineTo(param3 + s * 0.8,param4 + s * 0.2);
               param1.moveTo(param3 + s * 0.5,param4 + s * 0.6);
               param1.lineTo(param3 + s * 0.5,param4 + s * 0.84);
               param1.moveTo(param3 + s * 0.3,param4 + s * 0.84);
               param1.lineTo(param3 + s * 0.7,param4 + s * 0.84);
               break;
            case "cat:structural":
               param1.drawRect(param3 + s * 0.16,param4 + s * 0.16,s * 0.68,s * 0.68);
               param1.moveTo(param3 + s * 0.16,param4 + s * 0.16);
               param1.lineTo(param3 + s * 0.84,param4 + s * 0.84);
               param1.moveTo(param3 + s * 0.84,param4 + s * 0.16);
               param1.lineTo(param3 + s * 0.16,param4 + s * 0.84);
               break;
            case "cat:equipment":
               param1.drawCircle(cx,cy,s * 0.34);
               param1.drawCircle(cx,cy,s * 0.12);
               break;
            default:
               param1.drawRoundRect(param3 + s * 0.2,param4 + s * 0.2,s * 0.6,s * 0.6,4,4);
         }
      }
   }
}
