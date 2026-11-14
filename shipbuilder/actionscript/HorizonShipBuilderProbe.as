package
{
   import Shared.AS3.Data.BSUIDataManager;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.text.Font;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.ui.Keyboard;
   import flash.utils.getDefinitionByName;
   
   public class HorizonShipBuilderProbe extends Sprite
   {
      private var host:Object;
      private var lines:Array;
      private var status:TextField;
      private var field:TextField;
      private var capture:Sprite;
      private var panel:Sprite;
      private var captureOn:Boolean;
      private var seen:Object;
      private var sentForms:Object;
      private var lastModule:String;
      private var lastStats:String;
      private var lastColor:String;
      private var lastExit:String;
      private var watchLeft:int;
      private var watchLabel:String;
      private var watchBase:String;
      private var moveSkips:int;
      private var providers:Array;
      private var useEmbed:Boolean;
      private var frameN:int;
      private var hotF7:int;
      private var hotF8:int;
      private var hotF6:int;
      private var helpNoted:Boolean;
      private var lastParts:String;
      private var debugOn:Boolean;
      private var started:Boolean;
      
      public function HorizonShipBuilderProbe(param1:Object, param2:Boolean = false)
      {
         super();
         this.host = param1;
         this.debugOn = param2;
         this.started = false;
         this.lines = [];
         this.seen = {};
         this.sentForms = {};
         this.captureOn = false;
         this.lastModule = "";
         this.lastStats = "";
         this.lastColor = "";
         this.lastExit = "";
         this.watchLeft = 0;
         this.moveSkips = 0;
         this.useEmbed = false;
         this.frameN = 0;
         this.hotF7 = -1000;
         this.hotF8 = -1000;
         this.hotF6 = -1000;
         this.helpNoted = false;
         this.lastParts = "";
         this.providers = ["StaticData","HangarData","FloorData","PartEntries","UpgradeEntries","ModuleVariant","ModuleInfo","ShipBuilderHelpList","FlightCheckData","SystemUpgradeData","ColorInitializationData","ColorSelectionData","ShipStats","CostSummaryData","NotificationBadgeData","ExitConfirmationData","ShipHangarModuleInfoData","RepairButtonData"];
         addEventListener(Event.ADDED_TO_STAGE,this.onStage);
      }
      
      public function ping():String
      {
         return "0.0.2.0";
      }
      
      // The overlay, the F keys, and the data subscriptions stay off until this is set.
      public function enableDebug():void
      {
         this.debugOn = true;
         if(stage != null) { this.startProbe(); }
      }
      
      public function stageBox():String
      {
         if(stage == null) { return "stage=0x0"; }
         return "stage=" + stage.stageWidth + "x" + stage.stageHeight;
      }
      
      // Bits from the window hook: 1 mark, 2 capture, 4 dump. Does not swallow the key.
      public function hsbProbeHotkey(param1:Number):void
      {
         var bits:int = int(param1);
         if((bits & 1) != 0) { this.takeHot(7); }
         if((bits & 2) != 0) { this.takeHot(8); }
         if((bits & 4) != 0) { this.takeHot(6); }
      }
      
      public function takeLines():String
      {
         var text:String = this.lines.join("\n");
         this.lines = [];
         return text;
      }
      
      public function noteUserEvent(param1:String, param2:Boolean):void
      {
         this.note("USER " + param1 + " down=" + param2 + " capture=" + this.captureOn + " field=" + this.fieldFocused());
         if(param2)
         {
            if(param1 == "F7") { this.takeHot(7); }
            else if(param1 == "F8") { this.takeHot(8); }
            else if(param1 == "F6") { this.takeHot(6); }
         }
         if(this.captureOn && param2)
         {
            this.arm("user " + param1);
         }
      }
      
      private function onStage(param1:Event):void
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.onStage);
         if(!this.debugOn)
         {
            this.note("PROBE off");
            return;
         }
         this.startProbe();
      }
      
      private function startProbe():void
      {
         if(this.started) { return; }
         this.started = true;
         this.note("KEYS F7=mark F8=capture F6=dump");
         this.buildOverlay(this.labelFormat());
         this.note("MOVIE url=" + this.urlOf(root) + " stage=" + stage.stageWidth + "x" + stage.stageHeight);
         this.noteRect();
         this.noteClips();
         var i:int = 0;
         while(i < this.providers.length)
         {
            this.listen(String(this.providers[i]));
            i++;
         }
         stage.addEventListener(MouseEvent.MOUSE_DOWN,this.onStageMouse,true,0,true);
         stage.addEventListener(MouseEvent.MOUSE_UP,this.onStageMouse,true,0,true);
         stage.addEventListener(MouseEvent.MOUSE_MOVE,this.onStageMouse,true,0,true);
         stage.addEventListener(MouseEvent.MOUSE_WHEEL,this.onStageMouse,true,0,true);
         stage.addEventListener(MouseEvent.CLICK,this.onStageMouse,true,0,true);
         stage.addEventListener(KeyboardEvent.KEY_DOWN,this.onKey,false,0,true);
         stage.addEventListener(Event.ENTER_FRAME,this.onFrame);
         stage.addEventListener(Event.RESIZE,this.onResize);
      }
      
      private function buildOverlay(label:TextFormat):void
      {
         this.capture = new Sprite();
         this.capture.mouseEnabled = false;
         this.capture.mouseChildren = false;
         this.capture.visible = false;
         this.capture.addEventListener(MouseEvent.MOUSE_DOWN,this.onLayerMouse);
         this.capture.addEventListener(MouseEvent.MOUSE_UP,this.onLayerMouse);
         this.capture.addEventListener(MouseEvent.MOUSE_MOVE,this.onLayerMouse);
         this.capture.addEventListener(MouseEvent.MOUSE_WHEEL,this.onLayerMouse);
         addChild(this.capture);
         
         this.panel = new Sprite();
         this.panel.graphics.beginFill(0x12110E,0.72);
         this.panel.graphics.drawRect(0,0,520,188);
         this.panel.graphics.endFill();
         this.panel.x = 8;
         this.panel.y = 8;
         this.panel.addEventListener(MouseEvent.MOUSE_DOWN,this.onPanelMouse);
         this.panel.addEventListener(MouseEvent.MOUSE_UP,this.onPanelMouse);
         this.panel.addEventListener(MouseEvent.MOUSE_WHEEL,this.onPanelMouse);
         this.panel.addEventListener(MouseEvent.CLICK,this.onPanelMouse);
         addChild(this.panel);
         
         var title:TextField = this.makeText(label,8,6,504,22,"Horizon Ship Builder probe 0.0.2.0. Read only. Capture is off.");
         this.panel.addChild(title);
         var keys:TextField = this.makeText(label,8,28,504,20,"F7 mark colors. F8 capture layer. F6 dump parts.");
         this.panel.addChild(keys);
         
         var mark:Sprite = this.makeButton(label,"F7 Mark colors",8,52,150,28);
         mark.addEventListener(MouseEvent.CLICK,this.onMark);
         this.panel.addChild(mark);
         
         var toggle:Sprite = this.makeButton(label,"F8 Capture",166,52,130,28);
         toggle.addEventListener(MouseEvent.CLICK,this.onToggle);
         this.panel.addChild(toggle);
         
         var dump:Sprite = this.makeButton(label,"F6 Dump",304,52,100,28);
         dump.addEventListener(MouseEvent.CLICK,this.onDumpClick);
         this.panel.addChild(dump);
         
         this.field = new TextField();
         this.field.embedFonts = this.useEmbed;
         this.field.defaultTextFormat = label;
         this.field.type = TextFieldType.INPUT;
         this.field.border = true;
         this.field.borderColor = 0xC8B27A;
         this.field.background = true;
         this.field.backgroundColor = 0x1C1A16;
         this.field.textColor = 0xF2E6C8;
         this.field.width = 160;
         this.field.height = 22;
         this.field.x = 8;
         this.field.y = 86;
         this.field.text = "Type here";
         this.field.setTextFormat(label);
         this.panel.addChild(this.field);
         
         this.status = this.makeText(label,8,112,504,68,"Log is on. Capture is off.");
         this.status.wordWrap = true;
         this.panel.addChild(this.status);
      }
      
      private function makeText(param1:TextFormat, param2:Number, param3:Number, param4:Number, param5:Number, param6:String):TextField
      {
         var box:TextField = new TextField();
         box.embedFonts = this.useEmbed;
         box.defaultTextFormat = param1;
         box.mouseEnabled = false;
         box.selectable = false;
         box.x = param2;
         box.y = param3;
         box.width = param4;
         box.height = param5;
         box.text = param6;
         box.setTextFormat(param1);
         return box;
      }
      
      // Copy the face a vanilla text field in this movie already uses. The name stays off the panel.
      private function labelFormat():TextFormat
      {
         var fmt:TextFormat = new TextFormat();
         fmt.size = 13;
         fmt.color = 0xF2E6C8;
         var sample:TextField = this.findVanillaField();
         if(sample != null)
         {
            var src:TextFormat = sample.getTextFormat();
            if(src == null || src.font == null || String(src.font).length == 0) { src = sample.defaultTextFormat; }
            if(src != null && src.font != null && String(src.font).length > 0)
            {
               fmt.font = src.font;
               this.useEmbed = sample.embedFonts && this.faceExported(String(src.font));
               var from:String = "field";
               if(sample.parent != null && sample.parent.name != null && String(sample.parent.name).length > 0) { from = String(sample.parent.name); }
               this.note("FONT copied=1 fieldEmbed=" + (sample.embedFonts ? 1 : 0) + " drawEmbed=" + (this.useEmbed ? 1 : 0) + " from=" + from);
               return fmt;
            }
         }
         var embedded:Array = Font.enumerateFonts(false);
         if(embedded != null && embedded.length > 0)
         {
            var face:Font = embedded[0] as Font;
            if(face != null && face.fontName != null && face.fontName.length > 0)
            {
               fmt.font = face.fontName;
               this.useEmbed = true;
               this.note("FONT copied=0 embedded=1 count=" + embedded.length);
               return fmt;
            }
         }
         this.note("FONT copied=0 embedded=0");
         return fmt;
      }

      // A copied timeline face is embedded only when this movie exports it. Otherwise the
      // probe draws it through the font library, the same rule as the gold panels.
      private function faceExported(param1:String):Boolean
      {
         if(param1 == null || param1.length == 0) { return false; }
         var list:Array = null;
         try { list = Font.enumerateFonts(false); }
         catch(err:Error) { list = null; }
         if(list == null) { return false; }
         var i:int = 0;
         while(i < list.length)
         {
            var font:Font = list[i] as Font;
            if(font != null && font.fontName == param1) { return true; }
            i++;
         }
         return false;
      }
      
      private function findVanillaField():TextField
      {
         var rootClip:DisplayObjectContainer = this.host as DisplayObjectContainer;
         if(rootClip == null) { return null; }
         var i:int = 0;
         while(i < rootClip.numChildren)
         {
            var child:DisplayObject = rootClip.getChildAt(i);
            if(child != this)
            {
               var hit:TextField = this.findField(child,0);
               if(hit != null) { return hit; }
            }
            i++;
         }
         return null;
      }
      
      private function findField(param1:Object, param2:int):TextField
      {
         if(param1 == null || param2 > 8) { return null; }
         if(param1 is TextField) { return param1 as TextField; }
         var box:DisplayObjectContainer = param1 as DisplayObjectContainer;
         if(box == null) { return null; }
         var i:int = 0;
         while(i < box.numChildren)
         {
            var hit:TextField = this.findField(box.getChildAt(i),param2 + 1);
            if(hit != null) { return hit; }
            i++;
         }
         return null;
      }
      
      private function makeButton(param1:TextFormat, param2:String, param3:Number, param4:Number, param5:Number, param6:Number):Sprite
      {
         var button:Sprite = new Sprite();
         button.graphics.beginFill(0x3A3428);
         button.graphics.drawRect(0,0,param5,param6);
         button.graphics.endFill();
         button.x = param3;
         button.y = param4;
         button.buttonMode = true;
         var caption:TextField = this.makeText(param1,6,4,param5 - 8,20,param2);
         button.addChild(caption);
         return button;
      }
      
      private function onToggle(param1:MouseEvent):void
      {
         this.captureOn = !this.captureOn;
         this.capture.graphics.clear();
         if(this.captureOn)
         {
            this.capture.graphics.beginFill(0x66CCFF,0.12);
            this.capture.graphics.drawRect(0,0,stage.stageWidth,stage.stageHeight);
            this.capture.graphics.endFill();
         }
         this.capture.mouseEnabled = this.captureOn;
         this.capture.visible = this.captureOn;
         addChild(this.panel);
         this.note("CAPTURE " + (this.captureOn ? "on" : "off"));
      }
      
      private function onMark(param1:MouseEvent):void
      {
         this.note("MARK module=" + this.lastModule + " color=" + this.lastColor + " stats=" + this.lastStats);
      }
      
      private function onDumpClick(param1:MouseEvent):void
      {
         this.onDump();
      }
      
      private function onDump():void
      {
         this.note("DUMP parts=" + this.lastParts + " module=" + this.lastModule + " stats=" + this.lastStats);
      }
      
      private function onPanelMouse(param1:MouseEvent):void
      {
         this.note("PANEL " + param1.type + " x=" + int(param1.stageX) + " y=" + int(param1.stageY) + " delta=" + param1.delta);
      }
      
      // A second path for the same press is ignored for a short run of frames. The key is not swallowed.
      private function takeHot(param1:int):void
      {
         var last:int = param1 == 7 ? this.hotF7 : (param1 == 8 ? this.hotF8 : this.hotF6);
         if(this.frameN - last < 30) { return; }
         if(param1 == 7) { this.hotF7 = this.frameN; this.onMark(null); }
         else if(param1 == 8) { this.hotF8 = this.frameN; this.onToggle(null); }
         else if(param1 == 6) { this.hotF6 = this.frameN; this.onDump(); }
         else { return; }
         this.note("HOTKEY F" + param1);
      }
      
      private function onStageMouse(param1:MouseEvent):void
      {
         if(param1.type == MouseEvent.MOUSE_MOVE)
         {
            this.moveSkips++;
            if(this.moveSkips % 12 != 0)
            {
               return;
            }
         }
         this.note("STAGE " + param1.type + " x=" + int(param1.stageX) + " y=" + int(param1.stageY) + " delta=" + param1.delta + " capture=" + this.captureOn);
      }
      
      private function onLayerMouse(param1:MouseEvent):void
      {
         this.note("LAYER " + param1.type + " x=" + int(param1.stageX) + " y=" + int(param1.stageY) + " delta=" + param1.delta);
         if(param1.type == MouseEvent.MOUSE_DOWN)
         {
            this.arm("layer down");
         }
      }
      
      private function onKey(param1:KeyboardEvent):void
      {
         this.note("KEY code=" + param1.keyCode + " char=" + param1.charCode + " ctrl=" + param1.ctrlKey + " shift=" + param1.shiftKey + " alt=" + param1.altKey + " field=" + this.fieldFocused() + " capture=" + this.captureOn);
         if(param1.keyCode == Keyboard.F7) { this.takeHot(7); }
         else if(param1.keyCode == Keyboard.F8) { this.takeHot(8); }
         else if(param1.keyCode == Keyboard.F6) { this.takeHot(6); }
         if(this.fieldFocused() || this.captureOn)
         {
            this.arm("key " + param1.keyCode);
         }
      }
      
      private function onResize(param1:Event):void
      {
         this.note("RESIZE stage=" + stage.stageWidth + "x" + stage.stageHeight);
         this.noteRect();
      }
      
      private function onFrame(param1:Event):void
      {
         this.frameN++;
         if(this.watchLeft <= 0)
         {
            return;
         }
         this.watchLeft--;
         if(this.watchLeft == 0)
         {
            var now:String = this.signature();
            this.note("AFTER " + this.watchLabel + " same=" + (now == this.watchBase) + " before=" + this.watchBase + " after=" + now);
         }
      }
      
      private function arm(param1:String):void
      {
         this.watchLabel = param1;
         this.watchBase = this.signature();
         this.watchLeft = 30;
      }
      
      private function signature():String
      {
         return this.lastModule + "|" + this.lastStats + "|" + this.lastColor + "|" + this.lastExit;
      }
      
      private function fieldFocused():Boolean
      {
         return stage != null && stage.focus == this.field;
      }
      
      private function listen(param1:String):void
      {
         var self:HorizonShipBuilderProbe = this;
         try
         {
            BSUIDataManager.Subscribe(param1,function(param2:Object):void
            {
               self.onNamed(param1,param2);
            });
            this.note("SUBSCRIBE ok " + param1);
         }
         catch(err:Error)
         {
            this.note("SUBSCRIBE miss " + param1);
         }
      }
      
      public function onNamed(param1:String, param2:Object):void
      {
         var data:Object = null;
         try
         {
            data = param2.data;
         }
         catch(err:Error)
         {
         }
         if(data == null)
         {
            try
            {
               data = param2.target.data;
            }
            catch(err:Error)
            {
            }
         }
         var shape:String = this.keysOf(data);
         if(this.seen[param1] != shape)
         {
            this.seen[param1] = shape;
            this.note("DATA " + param1 + " keys=" + shape);
         }
         if(param1 == "ShipBuilderHelpList")
         {
            this.noteHelp(data);
         }
         if(param1 == "PartEntries")
         {
            this.onParts(data);
         }
         else if(param1 == "ModuleInfo")
         {
            this.lastModule = this.pick(data,"sModuleName");
            this.note("MODULE " + this.lastModule + " logo=" + this.pick(data,"sLogoID") + " stats=" + this.statTexts(data));
         }
         else if(param1 == "ShipStats")
         {
            var stats:String = this.primitiveSample(data);
            if(stats != this.lastStats)
            {
               this.lastStats = stats;
               this.note("STATS " + stats);
            }
         }
         else if(param1 == "ColorInitializationData" || param1 == "ColorSelectionData")
         {
            var color:String = "visible=" + this.pick(data,"bVisible") + " tab=" + this.pick(data,"iSelectedTab") + " control=" + this.pick(data,"iSelectedControl") + " h=" + this.pick(data,"fHue") + " s=" + this.pick(data,"fSaturation") + " b=" + this.pick(data,"fBrightness") + " recent=" + this.pick(data,"iRecentIndex");
            if(color != this.lastColor)
            {
               this.lastColor = color;
               this.note("COLOR " + param1 + " " + color);
            }
         }
         else if(param1 == "ExitConfirmationData")
         {
            var exit:String = this.primitiveSample(data);
            if(exit != this.lastExit)
            {
               this.lastExit = exit;
               this.note("EXIT " + exit);
            }
         }
         else if(param1 == "CostSummaryData")
         {
            this.note("COST credits=" + this.pick(data,"uTotalCredits") + " " + this.primitiveSample(data));
         }
      }
      
      private function noteHelp(param1:Object):void
      {
         if(this.helpNoted || param1 == null) { return; }
         var list:Object = param1.aHelpList;
         if(list == null)
         {
            this.helpNoted = true;
            this.note("HELP absent keys=" + this.keysOf(param1));
            return;
         }
         this.helpNoted = true;
         var count:int = int(list.length);
         this.note("HELP count=" + count + " rowKeys=" + this.keysOf(count > 0 ? list[0] : null));
         var i:int = 0;
         while(i < count && i < 40)
         {
            this.note("HELP " + i + " " + this.primitiveSample(list[i]));
            i++;
         }
      }
      
      private function onParts(param1:Object):void
      {
         if(param1 == null)
         {
            this.lastParts = "empty";
            this.note("PARTS empty");
            return;
         }
         var list:Object = param1.aPartList;
         var count:int = 0;
         if(list != null)
         {
            count = int(list.length);
         }
         var category:String = this.pick(param1,"sCategoryName");
         this.lastParts = "category=" + category + " index=" + this.pick(param1,"iCategoryIndex") + " stat=" + this.pick(param1,"sStatName1") + " count=" + count;
         this.note("PARTS " + this.lastParts + " rowKeys=" + this.keysOf(count > 0 ? list[0] : null));
         var shown:int = 0;
         var i:int = 0;
         while(i < count && shown < 24)
         {
            var row:Object = list[i];
            if(row != null && row.uFormID != null)
            {
               var id:uint = uint(row.uFormID);
               var hex:String = id.toString(16);
               while(hex.length < 8)
               {
                  hex = "0" + hex;
               }
               var token:String = category + "|" + hex;
               if(this.sentForms[token] == null)
               {
                  this.sentForms[token] = true;
                  this.note("FORM " + hex);
                  shown++;
               }
            }
            i++;
         }
         if(count > 0 && list[0] != null && list[0].uFormID == null)
         {
            this.note("FORM field absent");
         }
      }
      
      private function keysOf(param1:Object):String
      {
         if(param1 == null)
         {
            return "(null)";
         }
         var names:Array = [];
         var key:String;
         for(key in param1)
         {
            names.push(key);
            if(names.length >= 40)
            {
               break;
            }
         }
         return names.join(",");
      }
      
      private function primitiveSample(param1:Object):String
      {
         if(param1 == null)
         {
            return "(null)";
         }
         var parts:Array = [];
         var key:String;
         for(key in param1)
         {
            var value:Object = param1[key];
            if(value is String || value is Number || value is Boolean || value is int || value is uint)
            {
               parts.push(key + "=" + value);
            }
            if(parts.length >= 12)
            {
               break;
            }
         }
         return parts.join(" ");
      }
      
      private function statTexts(param1:Object):String
      {
         if(param1 == null || param1.aStats == null)
         {
            return "";
         }
         var parts:Array = [];
         var i:int = 0;
         var list:Object = param1.aStats;
         while(i < int(list.length) && i < 8)
         {
            parts.push(this.pick(list[i],"text"));
            i++;
         }
         return parts.join(",");
      }
      
      private function pick(param1:Object, param2:String):String
      {
         if(param1 == null || param1[param2] == null)
         {
            return "";
         }
         return String(param1[param2]);
      }
      
      private function noteRect():void
      {
         try
         {
            var ext:Class = Class(getDefinitionByName("Extensions"));
            var rect:Object = ext["visibleRect"];
            if(rect != null)
            {
               this.note("RECT x=" + rect.x + " y=" + rect.y + " w=" + rect.width + " h=" + rect.height);
               return;
            }
         }
         catch(err:Error)
         {
         }
         this.note("RECT unavailable");
      }
      
      private function noteClips():void
      {
         var names:Array = ["ButtonBar_mc","ShipRename_mc","RepairMeter_mc","ExitConfirmation_mc","FlightCheck_mc","SystemUpgrade_mc","ColorPicker_mc","Background_mc","MessagePopup_mc","PowerPanel"];
         var parts:Array = [];
         var i:int = 0;
         while(i < names.length)
         {
            var clip:Object = this.host[names[i]];
            if(clip == null)
            {
               parts.push(names[i] + "=absent");
            }
            else
            {
               parts.push(names[i] + "=" + int(clip.width) + "x" + int(clip.height));
            }
            i++;
         }
         this.note("CLIPS " + parts.join(" "));
      }
      
      private function urlOf(param1:Object):String
      {
         var url:String = "";
         try
         {
            url = String(param1.loaderInfo.url);
         }
         catch(err:Error)
         {
            url = "";
         }
         return url;
      }
      
      private function note(param1:String):void
      {
         var clean:String = param1.split("\n").join(" ").split("\r").join(" ");
         this.lines.push(clean);
         while(this.lines.length > 200)
         {
            this.lines.shift();
         }
         if(this.status != null)
         {
            this.status.text = clean;
         }
      }
   }
}
