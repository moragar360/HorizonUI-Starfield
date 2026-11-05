package
{
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.text.Font;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
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
      
      public function HorizonShipBuilderProbe(param1:Object)
      {
         super();
         this.host = param1;
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
         this.providers = ["StaticData","HangarData","FloorData","PartEntries","UpgradeEntries","ModuleVariant","ModuleInfo","ShipBuilderHelpList","FlightCheckData","SystemUpgradeData","ColorInitializationData","ColorSelectionData","ShipStats","CostSummaryData","NotificationBadgeData","ExitConfirmationData","ShipHangarModuleInfoData","RepairButtonData"];
         addEventListener(Event.ADDED_TO_STAGE,this.onStage);
      }
      
      public function ping():String
      {
         return "0.0.1.0";
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
         if(this.captureOn && param2)
         {
            this.arm("user " + param1);
         }
      }
      
      private function onStage(param1:Event):void
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.onStage);
         this.buildOverlay();
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
         stage.addEventListener(KeyboardEvent.KEY_DOWN,this.onKey,false,0,true);
         stage.addEventListener(Event.ENTER_FRAME,this.onFrame);
         stage.addEventListener(Event.RESIZE,this.onResize);
      }
      
      private function buildOverlay():void
      {
         var face:String = this.faceName();
         var label:TextFormat = new TextFormat();
         label.size = 13;
         if(face.length > 0)
         {
            label.font = face;
         }
         label.color = 0xF2E6C8;
         
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
         this.panel.graphics.drawRect(0,0,460,168);
         this.panel.graphics.endFill();
         this.panel.x = 8;
         this.panel.y = 8;
         addChild(this.panel);
         
         var title:TextField = this.makeText(label,8,6,444,36,"Horizon Ship Builder probe 0.0.1.0. Read only. Capture is off.");
         this.panel.addChild(title);
         
         var toggle:Sprite = this.makeButton(label,"Capture layer",8,46,140,28);
         toggle.addEventListener(MouseEvent.CLICK,this.onToggle);
         this.panel.addChild(toggle);
         
         var mark:Sprite = this.makeButton(label,"Mark colors",156,46,120,28);
         mark.addEventListener(MouseEvent.CLICK,this.onMark);
         this.panel.addChild(mark);
         
         this.field = new TextField();
         this.field.defaultTextFormat = label;
         this.field.type = TextFieldType.INPUT;
         this.field.border = true;
         this.field.borderColor = 0xC8B27A;
         this.field.background = true;
         this.field.backgroundColor = 0x1C1A16;
         this.field.textColor = 0xF2E6C8;
         this.field.width = 160;
         this.field.height = 22;
         this.field.x = 284;
         this.field.y = 49;
         this.field.text = "Type here";
         if(face.length > 0)
         {
            this.field.embedFonts = true;
         }
         this.panel.addChild(this.field);
         
         this.status = this.makeText(label,8,82,444,78,"Log is on. Capture is off.");
         this.status.wordWrap = true;
         this.panel.addChild(this.status);
      }
      
      private function makeText(param1:TextFormat, param2:Number, param3:Number, param4:Number, param5:Number, param6:String):TextField
      {
         var box:TextField = new TextField();
         box.defaultTextFormat = param1;
         box.mouseEnabled = false;
         box.selectable = false;
         box.x = param2;
         box.y = param3;
         box.width = param4;
         box.height = param5;
         box.text = param6;
         if(param1.font != null && String(param1.font).length > 0)
         {
            box.embedFonts = true;
         }
         return box;
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
      
      private function faceName():String
      {
         var found:Array = Font.enumerateFonts(false);
         if(found != null && found.length > 0)
         {
            return Font(found[0]).fontName;
         }
         return "";
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
      
      private function onParts(param1:Object):void
      {
         if(param1 == null)
         {
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
         this.note("PARTS category=" + category + " index=" + this.pick(param1,"iCategoryIndex") + " stat=" + this.pick(param1,"sStatName1") + " count=" + count + " rowKeys=" + this.keysOf(count > 0 ? list[0] : null));
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
         try
         {
            return String(param1.loaderInfo.url);
         }
         catch(err:Error)
         {
            return "";
         }
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
