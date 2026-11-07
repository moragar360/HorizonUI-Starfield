package
{
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.GlobalFunc;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;
   
   public class HorizonShipBuilder extends Sprite
   {
      private static const ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const IDS:Array = ["Power","Module","Credits","Browser","Stats","Hints","Cluster"];
      private static const FIXED:Array = ["FlightCheck_mc","SystemUpgrade_mc","ExitConfirmation_mc","ShipRename_mc","RepairMeter_mc","ColorPicker_mc","Background_mc","MessagePopup_mc"];
      // Mapped names go through the game's font library. The log names a candidate by index only.
      private static const FACES:Array = ["$NB_Grotesk_Semibold","$MAIN_Font_Bold","$MAIN_Font"];
      private static const NO_FACE:String = "$Horizon_NoSuchFace_x";
      
      private var host:Object;
      private var lines:Array;
      private var probe:HorizonShipBuilderProbe;
      private var cards:Array;
      private var mapped:Boolean;
      private var conflict:Boolean;
      private var accent:int;
      private var accentHex:String;
      private var core:Boolean;
      private var margin:int;
      private var lrg:Boolean;
      private var bodyPx:int;
      private var face:String;
      private var faceEmbed:Boolean;
      private var facePick:String;
      private var faceTries:int;
      private var texts:Array;
      private var notedFaces:int;
      private var pt:Point;
      private var gear:Sprite;
      private var titleT:TextField;
      private var setLayer:Sprite;
      private var setOpen:Boolean;
      private var hexBox:TextField;
      private var arrLayer:Sprite;
      private var arranging:Boolean;
      private var armed:Boolean;
      private var ignorePress:Boolean;
      private var dragId:String;
      private var dragDx:Number;
      private var dragDy:Number;
      private var sel:String;
      private var barDx:Number;
      private var barDy:Number;
      private var openBarX:Number;
      private var openBarY:Number;
      private var openLay:Object;
      private var barDrag:Boolean;
      private var barGx:Number;
      private var barGy:Number;
      private var snap:Array;
      private var vis:Array;
      private var homes:Array;
      private var lay:Object;
      private var pendingSave:Boolean;
      private var keysOn:Boolean;
      private var frameN:int;
      private var banner:TextField;
      private var notedMap:Boolean;
      private var fades:Array;
      private var pill:Sprite;
      private var modCard:Sprite;
      private var modLines:Shape;
      private var modHead:TextField;
      private var modName:TextField;
      private var modDesc:TextField;
      private var modValueL:TextField;
      private var modMassL:TextField;
      private var modValue:TextField;
      private var modMass:TextField;
      private var modRows:Array;
      private var modSkills:Array;
      private var modData:Object;
      private var modNative:DisplayObject;
      private var modAlpha:Number;
      private var modOn:Boolean;
      private var modWhy:String;
      private var modFacts:String;
      private var modTint:uint;
      private var modFailed:Boolean;
      private var modView:Object;
      private var modVals:Array;
      private var modValsKey:String;
      private var modValsSaid:String;
      private var modValsLeft:int;
      private var modHigh:Number;
      private var liftView:Object;
      private var liftParent:DisplayObjectContainer;
      private var liftTop:Number;
      private var liftLow:Number;
      
      public function HorizonShipBuilder(param1:Object)
      {
         super();
         this.host = param1;
         this.lines = [];
         this.cards = [];
         this.mapped = false;
         this.conflict = false;
         this.accent = 9;
         this.accentHex = "";
         this.core = false;
         this.margin = 34;
         this.lrg = false;
         this.bodyPx = 13;
         this.face = "";
         this.faceEmbed = false;
         this.facePick = "0";
         this.faceTries = 0;
         this.texts = [];
         this.notedFaces = 0;
         this.pt = new Point();
         this.setOpen = false;
         this.arranging = false;
         this.armed = false;
         this.ignorePress = false;
         this.dragId = "";
         this.sel = "";
         this.barDx = 0;
         this.barDy = 0;
         this.openBarX = 0;
         this.openBarY = 0;
         this.openLay = {};
         this.barDrag = false;
         this.snap = [];
         this.vis = [];
         this.homes = [];
         this.lay = {};
         this.pendingSave = false;
         this.keysOn = true;
         this.frameN = 0;
         this.notedMap = false;
         this.fades = [];
         this.modRows = [];
         this.modSkills = [];
         this.modAlpha = 1;
         this.modOn = false;
         this.modWhy = "";
         this.modFacts = "";
         this.modTint = 0;
         this.modFailed = false;
         this.modView = null;
         this.modVals = [];
         this.modValsKey = "";
         this.modValsSaid = "";
         this.modValsLeft = 24;
         this.modHigh = 0;
         this.liftView = null;
         this.liftParent = null;
         this.liftTop = 0;
         this.liftLow = 0;
         this.mouseEnabled = false;
         this.mouseChildren = true;
         addEventListener(Event.ADDED_TO_STAGE,this.onStage);
      }
      
      public function ping():String
      {
         return "0.1.1.0";
      }
      
      public function stageBox():String
      {
         if(stage == null) { return "stage=0x0"; }
         return "stage=" + stage.stageWidth + "x" + stage.stageHeight;
      }
      
      public function takeLines():String
      {
         this.pushState();
         var text:String = this.lines.join("\n");
         this.lines = [];
         return text;
      }
      
      public function setDebug(param1:Number):void
      {
         if(int(param1) != 1) { return; }
         if(this.probe == null)
         {
            this.probe = new HorizonShipBuilderProbe(this.host,true);
            this.host.addChild(this.probe);
         }
         else
         {
            this.probe.enableDebug();
         }
      }
      
      public function apply(param1:String):void
      {
         if(param1 == null) { return; }
         var rows:Array = param1.split("\n");
         var i:int = 0;
         while(i < rows.length)
         {
            var line:String = String(rows[i]);
            var eq:int = line.indexOf("=");
            if(eq > 0)
            {
               var key:String = line.substring(0,eq);
               var val:String = line.substring(eq + 1);
               if(key == "accent") { this.accent = int(val); }
               else if(key == "hex") { this.accentHex = val == "-" ? "" : val; }
               else if(key == "core") { this.core = val == "1"; }
               else if(key == "probe") { if(val == "1") { this.setDebug(1); } }
               else if(key == "margin") { this.margin = int(val); }
               else if(key == "conflict") { if(val == "1") { this.conflict = true; } }
               else if(key == "keys") { this.keysOn = val != "0"; }
               else if(key == "ArrangeBarX") { this.barDx = Number(val); }
               else if(key == "ArrangeBarY") { this.barDy = Number(val); }
               else { this.lay[key] = val; }
            }
            i++;
         }
         if(this.accent < -1 || this.accent > 13) { this.accent = 9; }
         this.redraw();
         if(this.mapped) { this.placeAll(false); }
      }
      
      public function feed(param1:String):void
      {
         if(param1 == null || param1.length == 0) { return; }
         var rows:Array = param1.split("\n");
         var i:int = 0;
         while(i < rows.length)
         {
            this.onFeed(String(rows[i]));
            i++;
         }
      }
      
      public function saved(param1:Number):void
      {
         this.pendingSave = false;
         if(int(param1) != 1 && this.arrLayer != null)
         {
            this.note("SAVE failed");
         }
      }
      
      // The game's buttons fire on release. Settings and Arrange act on the release too, so the
      // release cannot reach the game's Cancel button after they close.
      public function wantsEvent(param1:String, param2:Boolean):Boolean
      {
         if(!this.arranging && !this.setOpen) { return false; }
         if(param2) { return true; }
         if(param1 == "Escape" || param1 == "Cancel") { this.cancelTop(); return true; }
         if(param1 == "Accept" || param1 == "Enter") { if(this.arranging) { this.okArrange(); } return true; }
         return true;
      }
      
      private function onStage(param1:Event):void
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.onStage);
         var url:String = "";
         try { url = String(root.loaderInfo.url); } catch(err:Error) { url = ""; }
         this.lrg = url.indexOf("_lrg") >= 0;
         this.bodyPx = this.lrg ? 16 : 13;
         this.proveFace();
         this.buildCards();
         this.buildGear();
         this.listenModule();
         stage.addEventListener(Event.ENTER_FRAME,this.onFrame);
         this.note("BUILDER 0.1.1.0 gold lrg=" + (this.lrg ? 1 : 0));
      }
      
      private function onFrame(param1:Event):void
      {
         this.frameN++;
         if(this.face.length == 0 && this.faceTries < 3 && (this.frameN == 30 || this.frameN == 120))
         {
            this.proveFace();
            if(this.face.length > 0) { this.refreshFaces(); }
         }
         if(this.frameN < 3) { return; }
         if(!this.arranging && !this.conflict && (!this.mapped || (this.frameN % 8) == 0)) { this.syncPanels(); }
         this.syncModule();
      }
      
      // Candidates in order: mapped names as embedded text, the face of the game's module name
      // field, then mapped names as device text. Box glyphs share one advance, so a face counts
      // only when W and i measure apart and the pair differs from a name that cannot exist.
      private function proveFace():void
      {
         this.faceTries++;
         this.face = "";
         this.faceEmbed = false;
         var none:Array = this.measureFace(NO_FACE,true);
         var noneDev:Array = this.measureFace(NO_FACE,false);
         var names:Array = [];
         var embeds:Array = [];
         var tags:Array = [];
         var i:int = 0;
         while(i < FACES.length)
         {
            names.push(String(FACES[i]));
            embeds.push(true);
            tags.push("e" + (i + 1));
            i++;
         }
         var label:TextField = this.pathField(["ModuleInfoCard_mc","ModuleLabel_mc","text_tf"]);
         var labelFace:String = this.fieldFace(label);
         var hasLabel:Boolean = labelFace.length > 0;
         if(hasLabel)
         {
            names.push(labelFace);
            embeds.push(label.embedFonts);
            tags.push("n4");
         }
         i = 0;
         while(i < FACES.length)
         {
            names.push(String(FACES[i]));
            embeds.push(false);
            tags.push("d" + (i + 1));
            i++;
         }
         var pick:String = "0";
         var report:String = "n=" + this.metric(none) + " nd=" + this.metric(noneDev) + (hasLabel ? "" : " n4=na");
         var k:int = 0;
         while(k < names.length)
         {
            var embed:Boolean = embeds[k] == true;
            var m:Array = this.measureFace(String(names[k]),embed);
            var ok:Boolean = this.faceProven(m,embed ? none : noneDev);
            report += " " + String(tags[k]) + "=" + this.metric(m) + (ok ? "+" : "-");
            if(ok && pick == "0")
            {
               pick = String(tags[k]);
               this.face = String(names[k]);
               this.faceEmbed = embed;
            }
            k++;
         }
         this.facePick = pick;
         this.note("FONT try=" + this.faceTries + " pick=" + pick + " " + report);
      }
      
      private function measureFace(param1:String, param2:Boolean):Array
      {
         var out:Array = [0,0,0];
         try
         {
            var meter:TextField = new TextField();
            meter.embedFonts = param2;
            var fmt:TextFormat = new TextFormat(param1,20,0xFFFFFF);
            meter.defaultTextFormat = fmt;
            meter.text = "WWWWWWWW";
            meter.setTextFormat(fmt);
            out[0] = meter.textWidth;
            out[2] = meter.textHeight;
            meter.text = "iiiiiiii";
            meter.setTextFormat(fmt);
            out[1] = meter.textWidth;
         }
         catch(err:Error)
         {
            out = [0,0,0];
         }
         return out;
      }
      
      private function faceProven(param1:Array, param2:Array):Boolean
      {
         var wide:Number = Number(param1[0]);
         var narrow:Number = Number(param1[1]);
         var tall:Number = Number(param1[2]);
         if(!(wide > 8) || !(narrow > 0) || !(tall > 4)) { return false; }
         if(wide < narrow * 1.6) { return false; }
         var missWide:Number = Number(param2[0]);
         var missNarrow:Number = Number(param2[1]);
         if(missWide > 0 && Math.abs(wide - missWide) < 0.5 && Math.abs(narrow - missNarrow) < 0.5) { return false; }
         return true;
      }
      
      private function metric(param1:Array):String
      {
         return int(Number(param1[0])) + "/" + int(Number(param1[1])) + "/" + int(Number(param1[2]));
      }
      
      private function refreshFaces():void
      {
         var kept:Array = [];
         var i:int = 0;
         while(i < this.texts.length)
         {
            var box:TextField = this.texts[i] as TextField;
            if(box != null && box.parent != null)
            {
               var fmt:TextFormat = box.defaultTextFormat;
               fmt.font = this.face;
               box.embedFonts = this.faceEmbed;
               box.defaultTextFormat = fmt;
               box.setTextFormat(fmt);
               kept.push(box);
            }
            i++;
         }
         this.texts = kept;
      }
      
      private function pathField(param1:Array):TextField
      {
         var node:Object = this.host;
         var i:int = 0;
         while(node != null && i < param1.length)
         {
            var name:String = String(param1[i]);
            var next:Object = null;
            try { next = node[name]; } catch(err:Error) { next = null; }
            if(next == null && node is DisplayObjectContainer) { next = (node as DisplayObjectContainer).getChildByName(name); }
            node = next;
            i++;
         }
         return node as TextField;
      }
      
      private function fieldFace(param1:TextField):String
      {
         if(param1 == null) { return ""; }
         var fmt:TextFormat = null;
         try { fmt = param1.getTextFormat(); } catch(err:Error) { fmt = null; }
         if(fmt == null || fmt.font == null || String(fmt.font).length == 0) { fmt = param1.defaultTextFormat; }
         if(fmt == null || fmt.font == null) { return ""; }
         return String(fmt.font);
      }
      
      // f1-f3 match a mapped candidate, x$ is another mapped name, x is a plain face, x0 has none.
      private function faceCode(param1:TextField):String
      {
         if(param1 == null) { return "na"; }
         var font:String = this.fieldFace(param1);
         var at:int = FACES.indexOf(font);
         var code:String = "x";
         if(at >= 0) { code = "f" + (at + 1); }
         else if(font.length == 0) { code = "x0"; }
         else if(font.charAt(0) == "$") { code = "x$"; }
         return code + (param1.embedFonts ? "e" : "d");
      }
      
      private function rowField(param1:DisplayObjectContainer, param2:int):TextField
      {
         if(param1 == null || param2 > 5) { return null; }
         var i:int = 0;
         while(i < param1.numChildren)
         {
            var child:DisplayObject = param1.getChildAt(i);
            if(child is TextField && child.name == "text_tf" && child.parent != null && child.parent.name == "Text_mc" && child.parent.parent != null && child.parent.parent.name == "Module_mc") { return child as TextField; }
            if(child is DisplayObjectContainer)
            {
               var hit:TextField = this.rowField(child as DisplayObjectContainer,param2 + 1);
               if(hit != null) { return hit; }
            }
            i++;
         }
         return null;
      }
      
      private function noteFaces(param1:String):void
      {
         var entries:DisplayObjectContainer = null;
         try { entries = this.host["ModulePalette_mc"]["ModuleEntries_mc"] as DisplayObjectContainer; } catch(err:Error) { entries = null; }
         var line:String = "FONTSRC " + param1 + " pick=" + this.facePick;
         line += " name=" + this.faceCode(this.pathField(["ModuleInfoCard_mc","ModuleLabel_mc","text_tf"]));
         line += " stat=" + this.faceCode(this.pathField(["ModuleInfoCard_mc","InfoCardContent_mc","StatEntry1_mc","StatLabel_mc","text_tf"]));
         line += " desc=" + this.faceCode(this.pathField(["ModuleInfoCard_mc","InfoCardContent_mc","Description_mc","text_tf"]));
         line += " head=" + this.faceCode(this.pathField(["ModulePalette_mc","ModuleHeader_mc","Text_mc","text_tf"]));
         line += " row=" + this.faceCode(this.rowField(entries,0));
         this.note(line);
      }
      
      private function buildCards():void
      {
         var i:int = 0;
         while(i < IDS.length)
         {
            var card:Sprite = new Sprite();
            card.name = "Hsb" + String(IDS[i]);
            var gameCard:Boolean = this.followsGame(String(IDS[i]));
            card.mouseEnabled = !gameCard;
            card.mouseChildren = !gameCard;
            addChild(card);
            var title:TextField = this.makeText(this.panelLabel(String(IDS[i])),16,12,330,22,this.bodyPx,this.accentColor());
            card.addChild(title);
            this.cards.push({"id":String(IDS[i]),"card":card,"title":title,"clip":null,"hx":0,"hy":0,"cx":0,"cy":0});
            i++;
         }
         this.redraw();
      }
      
      private function buildGear():void
      {
         var cluster:Object = this.cardBy("Cluster");
         if(cluster == null) { return; }
         var box:Sprite = cluster.card as Sprite;
         box.mouseEnabled = true;
         box.mouseChildren = true;
         this.gear = new Sprite();
         this.gear.name = "HsbGear";
         this.gear.buttonMode = true;
         this.gear.x = 0;
         this.gear.y = 0;
         this.gear.addEventListener(MouseEvent.CLICK,this.onGear);
         box.addChild(this.gear);
         var hide:TextField = this.makeText("HIDE ALL",52,10,140,22,this.bodyPx,0xF4F0E4);
         hide.name = "HsbHide";
         hide.mouseEnabled = false;
         hide.visible = false;
         box.addChild(hide);
         this.paintGear();
      }
      
      private function paintGear():void
      {
         if(this.gear == null) { return; }
         var g:* = this.gear.graphics;
         g.clear();
         var c:uint = this.accentColor();
         g.lineStyle(1.5,c,1);
         g.beginFill(0x121610,0.92);
         g.drawRoundRect(0,0,38,38,10,10);
         g.endFill();
         g.drawCircle(19,19,6);
         var i:int = 0;
         while(i < 8)
         {
            var a:Number = i * 3.14159265 / 4;
            g.moveTo(19 + Math.cos(a) * 8,19 + Math.sin(a) * 8);
            g.lineTo(19 + Math.cos(a) * 12,19 + Math.sin(a) * 12);
            i++;
         }
         g.lineStyle();
      }
      
      private function onGear(param1:MouseEvent):void
      {
         if(this.arranging || this.conflict) { return; }
         this.openSettings();
      }
      
      private function syncPanels():void
      {
         if(!this.mapped)
         {
            var found:Array = [];
            this.collect(this.host as DisplayObjectContainer,0,found);
            this.inventory(found);
            if(this.otherBuilder(found))
            {
               this.conflict = true;
               this.showBanner("Another ship builder mod is loaded. Horizon Ship Builder is standing aside.");
               this.note("CONFLICT step-aside");
               var i0:int = 0;
               while(i0 < this.cards.length)
               {
                  (this.cards[i0].card as Sprite).visible = false;
                  i0++;
               }
               this.mapped = true;
               return;
            }
         }
         var report:String = "";
         var i:int = 0;
         while(i < IDS.length)
         {
            var id:String = String(IDS[i]);
            var row:Object = this.cardBy(id);
            if(id == "Cluster")
            {
               i++;
               continue;
            }
            var clip:DisplayObject = this.clipByName(id);
            if(report.length > 0) { report += ","; }
            report += id + "=" + (clip != null && clip.name != null ? clip.name : "none");
            this.release(row);
            this.strokeBehind(this.clipLive(clip) ? clip : null,id);
            this.captureHome(row,clip);
            i++;
         }
         this.applyNativeAnchors();
         this.dressInteriors();
         this.strokeHangar();
         if(!this.mapped) { this.note("MAP " + report); }
         if(this.notedFaces == 0)
         {
            this.notedFaces = 1;
            this.noteFaces("map");
         }
         if(this.notedFaces == 1 && this.clipLive(this.clipByName("Module")))
         {
            this.notedFaces = 2;
            this.noteFaces("card");
         }
         this.mapped = true;
         this.redraw();
      }
      
      private function otherBuilder(param1:Array):Boolean
      {
         var i:int = 0;
         while(i < param1.length)
         {
            var name:String = String(param1[i].name).toLowerCase();
            if(name.indexOf("starui") >= 0) { return true; }
            i++;
         }
         return false;
      }
      
      private function collect(param1:DisplayObjectContainer, param2:int, param3:Array):void
      {
         if(param1 == null || param2 > 5) { return; }
         var i:int = 0;
         while(i < param1.numChildren)
         {
            var child:DisplayObject = param1.getChildAt(i);
            if(child != this && child.name != null && child.name.indexOf("Hsb") != 0)
            {
               var w:Number = child.width;
               var h:Number = child.height;
               if(w > 40 && h > 24)
               {
                  param3.push({"clip":child,"name":child.name,"w":w,"h":h});
               }
               if(child is DisplayObjectContainer) { this.collect(child as DisplayObjectContainer,param2 + 1,param3); }
            }
            i++;
         }
      }
      
      private function panelLabel(param1:String):String
      {
         if(param1 == "Module") { return "SELECTED MODULE"; }
         if(param1 == "Browser") { return "PARTS BROWSER"; }
         if(param1 == "Cluster") { return "TOP CLUSTER"; }
         return param1.toUpperCase();
      }
      
      private function aliases(param1:String):Array
      {
         if(param1 == "Power") { return ["PowerAllocation_mc"]; }
         if(param1 == "Module") { return ["ModuleInfoCard_mc"]; }
         if(param1 == "Credits") { return ["CostSummary_mc"]; }
         if(param1 == "Browser") { return ["ModulePalette_mc"]; }
         if(param1 == "Stats") { return ["ShipStatsFooter_mc"]; }
         if(param1 == "Hints") { return ["ButtonBar_mc"]; }
         return [];
      }
      
      // Game clips stay on the menu. Removing the parts list from the stage can drop its rows.
      private function followsGame(param1:String):Boolean
      {
         return param1 == "Credits" || param1 == "Hints" || param1 == "Power" || param1 == "Module" || param1 == "Browser" || param1 == "Stats";
      }
      
      // Credits and the button bar stay where the menu writes them.
      // The other live panels and the gear move in place.
      private function panelMovable(param1:String):Boolean
      {
         return param1 == "Power" || param1 == "Module" || param1 == "Browser" || param1 == "Stats" || param1 == "Cluster";
      }
      
      private function liveBounds(param1:String):Rectangle
      {
         if(!this.panelMovable(param1)) { return null; }
         if(param1 == "Cluster")
         {
            var rowC:Object = this.cardBy("Cluster");
            if(rowC == null) { return null; }
            var cardC:Sprite = rowC.card as Sprite;
            if(cardC == null || !cardC.visible) { return null; }
            return cardC.getBounds(this);
         }
         if(param1 == "Module" && this.modOn && this.modCard != null && this.modCard.parent != null && this.modCard.visible)
         {
            return this.modCard.getBounds(this);
         }
         var clip:DisplayObject = this.clipByName(param1);
         if(!this.clipLive(clip)) { return null; }
         return clip.getBounds(this);
      }
      
      private function eligible(param1:String):Boolean
      {
         var box:Rectangle = this.liveBounds(param1);
         return box != null && box.width >= 24 && box.height >= 24;
      }
      
      private function defaultSel():String
      {
         var i:int = 0;
         while(i < IDS.length)
         {
            if(this.eligible(String(IDS[i]))) { return String(IDS[i]); }
            i++;
         }
         return "";
      }
      
      private function captureHome(param1:Object, param2:DisplayObject):void
      {
         if(param1 == null || param1.homed == true) { return; }
         if(!this.panelMovable(String(param1.id)) || String(param1.id) == "Cluster") { return; }
         if(!this.clipLive(param2)) { return; }
         param1.homeX = param2.x;
         param1.homeY = param2.y;
         param1.homed = true;
      }
      
      private function moveNative(param1:DisplayObject, param2:Number, param3:Number):void
      {
         if(param1 == null) { return; }
         var parent:DisplayObjectContainer = param1.parent as DisplayObjectContainer;
         if(parent == null) { return; }
         var origin:Point = parent.globalToLocal(this.localToGlobal(new Point(0,0)));
         var shifted:Point = parent.globalToLocal(this.localToGlobal(new Point(param2,param3)));
         param1.x += shifted.x - origin.x;
         param1.y += shifted.y - origin.y;
      }
      
      private function clipByName(param1:String):DisplayObject
      {
         var names:Array = this.aliases(param1);
         var n:int = 0;
         while(n < names.length)
         {
            var name:String = String(names[n]);
            var direct:DisplayObject = null;
            try { direct = this.host[name] as DisplayObject; } catch(err:Error) { direct = null; }
            if(direct != null) { return direct; }
            var walked:DisplayObject = this.findDeep(this.host as DisplayObjectContainer,name,0);
            if(walked != null) { return walked; }
            n++;
         }
         return null;
      }
      
      private function findDeep(param1:DisplayObjectContainer, param2:String, param3:int):DisplayObject
      {
         if(param1 == null || param3 > 6) { return null; }
         var i:int = 0;
         while(i < param1.numChildren)
         {
            var child:DisplayObject = param1.getChildAt(i);
            if(child.name == param2) { return child; }
            if(child is DisplayObjectContainer)
            {
               var hit:DisplayObject = this.findDeep(child as DisplayObjectContainer,param2,param3 + 1);
               if(hit != null) { return hit; }
            }
            i++;
         }
         return null;
      }
      
      private function clipLive(param1:DisplayObject):Boolean
      {
         if(param1 == null) { return false; }
         var node:DisplayObject = param1;
         var guard:int = 0;
         while(node != null && guard < 8)
         {
            if(!node.visible) { return false; }
            node = node.parent;
            guard++;
         }
         var box:Rectangle = null;
         try { box = param1.getBounds(stage); } catch(err:Error) { box = null; }
         if(box == null) { return false; }
         if(box.width < 40 || box.height < 24) { return false; }
         if(box.width > 1700 || box.height > 1000) { return false; }
         return true;
      }
      
      private function release(param1:Object):void
      {
         var card:Sprite = param1.card as Sprite;
         var clip:DisplayObject = param1.clip as DisplayObject;
         if(clip != null && clip.parent == card && param1.homeParent != null)
         {
            card.removeChild(clip);
            var parent:DisplayObjectContainer = param1.homeParent as DisplayObjectContainer;
            var index:int = int(param1.homeIndex);
            if(index < 0 || index > parent.numChildren) { index = parent.numChildren; }
            parent.addChildAt(clip,index);
            clip.x = Number(param1.homeX);
            clip.y = Number(param1.homeY);
         }
         param1.clip = null;
         param1.ww = 0;
         param1.hh = 0;
         card.visible = false;
         card.graphics.clear();
      }
      
      private function strokeBehind(param1:DisplayObject, param2:String):void
      {
         var frameName:String = "HsbFrame" + param2;
         if(param2 == "Module" && this.modOn) { return; }
         if(param1 == null || param1.parent == null)
         {
            this.removeFrame(frameName);
            return;
         }
         var parent:DisplayObjectContainer = param1.parent as DisplayObjectContainer;
         var frame:Sprite = parent.getChildByName(frameName) as Sprite;
         if(frame == null)
         {
            frame = new Sprite();
            frame.name = frameName;
            frame.mouseEnabled = false;
            frame.mouseChildren = false;
            parent.addChildAt(frame,parent.getChildIndex(param1));
         }
         else if(frame.parent == parent)
         {
            var clipAt:int = parent.getChildIndex(param1);
            var frameAt:int = parent.getChildIndex(frame);
            if(frameAt != clipAt - 1) { parent.setChildIndex(frame,clipAt); }
         }
         var box:Rectangle = param1.getBounds(parent);
         var g:* = frame.graphics;
         g.clear();
         g.lineStyle(1.5,this.accentColor(),0.95);
         g.drawRoundRect(box.x - 8,box.y - 8,box.width + 16,box.height + 16,14,14);
         g.lineStyle();
      }
      
      private function removeFrame(param1:String):void
      {
         var host:DisplayObjectContainer = this.host as DisplayObjectContainer;
         var frame:DisplayObject = this.findDeep(host,param1,0);
         if(frame != null && frame.parent != null)
         {
            (frame.parent as DisplayObjectContainer).removeChild(frame);
         }
      }
      
      private function strokeHangar():void
      {
         var hangar:DisplayObjectContainer = null;
         try { hangar = this.host["HangarInfoPanel_mc"] as DisplayObjectContainer; } catch(err:Error) { hangar = null; }
         if(hangar == null || !hangar.visible)
         {
            var n:int = 0;
            while(n < 6)
            {
               this.removeFrame("Hangar" + n);
               n++;
            }
            return;
         }
         var i:int = 0;
         var used:int = 0;
         while(i < hangar.numChildren && used < 6)
         {
            var child:DisplayObject = hangar.getChildAt(i);
            var name:String = child.name != null ? child.name : "";
            if(name != "ShipSelector_mc" && name.indexOf("Hsb") != 0 && this.clipLive(child))
            {
               var hb:Rectangle = child.getBounds(stage);
               if(hb.width <= 700 && hb.height <= 820)
               {
                  this.strokeBehind(child,"Hangar" + used);
                  used++;
               }
            }
            i++;
         }
         while(used < 6)
         {
            this.removeFrame("Hangar" + used);
            used++;
         }
      }
      
      private function taken(param1:DisplayObject):Boolean
      {
         var i:int = 0;
         while(i < this.cards.length)
         {
            if(this.cards[i].clip == param1) { return true; }
            i++;
         }
         return false;
      }
      
      private function blocked(param1:DisplayObject):Boolean
      {
         var node:DisplayObject = param1;
         var guard:int = 0;
         while(node != null && guard < 8)
         {
            var name:String = node.name != null ? node.name : "";
            var i:int = 0;
            while(i < FIXED.length)
            {
               if(name == String(FIXED[i])) { return true; }
               i++;
            }
            node = node.parent;
            guard++;
         }
         return false;
      }
      
      private function inventory(param1:Array):void
      {
         if(this.notedMap) { return; }
         this.notedMap = true;
         var text:String = "";
         var i:int = 0;
         var shown:int = 0;
         while(i < param1.length && shown < 24)
         {
            var item:Object = param1[i];
            if(Number(item.w) > 80 && Number(item.h) > 40)
            {
               if(text.length > 0) { text += ","; }
               text += item.name + ":" + int(item.w) + "x" + int(item.h);
               shown++;
            }
            i++;
         }
         this.note("CLIPS " + text);
      }
      
      private function placeAll(param1:Boolean):void
      {
         this.applyNativeAnchors();
      }
      
      private function applyNativeAnchors():void
      {
         var r:Object = this.view();
         var i:int = 0;
         while(i < IDS.length)
         {
            var id:String = String(IDS[i]);
            if(id == "Cluster") { this.placeCluster(r); }
            else if(this.panelMovable(id)) { this.placeNative(id,r); }
            i++;
         }
      }
      
      private function placeCluster(param1:Object):void
      {
         var rawX:String = this.lay["ClusterX"] != null ? String(this.lay["ClusterX"]) : "-1";
         var rawY:String = this.lay["ClusterY"] != null ? String(this.lay["ClusterY"]) : "-1";
         if(rawX == "-1" && rawY == "-1") { return; }
         var row:Object = this.cardBy("Cluster");
         if(row == null) { return; }
         var card:Sprite = row.card as Sprite;
         var box:Rectangle = card.getBounds(this);
         var spot:Object = {"x":box.x,"y":box.y,"w":box.width,"h":box.height};
         var x:Number = box.x;
         var y:Number = box.y;
         if(rawX != "-1") { x = this.resolveX("Cluster",spot,param1); }
         if(rawY != "-1") { y = this.resolveY("Cluster",spot,param1); }
         x = this.clamp(x,param1.x,param1.x + param1.width - box.width);
         y = this.clamp(y,param1.y,param1.y + param1.height - box.height);
         card.x += x - box.x;
         card.y += y - box.y;
      }
      
      private function placeNative(param1:String, param2:Object):void
      {
         var rawX:String = this.lay[param1 + "X"] != null ? String(this.lay[param1 + "X"]) : "-1";
         var rawY:String = this.lay[param1 + "Y"] != null ? String(this.lay[param1 + "Y"]) : "-1";
         if(rawX == "-1" && rawY == "-1") { return; }
         var clip:DisplayObject = this.clipByName(param1);
         if(!this.clipLive(clip)) { return; }
         var box:Rectangle = clip.getBounds(this);
         var spot:Object = {"x":box.x,"y":box.y,"w":box.width,"h":box.height};
         var x:Number = box.x;
         var y:Number = box.y;
         if(rawX != "-1") { x = this.resolveX(param1,spot,param2); }
         if(rawY != "-1") { y = this.resolveY(param1,spot,param2); }
         x = this.clamp(x,param2.x,param2.x + param2.width - box.width);
         y = this.clamp(y,param2.y,param2.y + param2.height - box.height);
         if(Math.abs(x - box.x) <= 1 && Math.abs(y - box.y) <= 1) { return; }
         this.moveNative(clip,x - box.x,y - box.y);
         this.strokeBehind(clip,param1);
         if(param1 == "Module" && this.modOn) { this.seatModule(this.modNative); }
      }
      
      private function layoutBoxes(param1:Object):Object
      {
         var m:Number = this.margin;
         var bw:Number = this.lrg ? 560 : 501;
         var powerH:Number = 240;
         var moduleH:Number = 460;
         var statsH:Number = 96;
         var hintsH:Number = 48;
         var out:Object = {};
         out.Power = {"x":param1.x + m,"y":param1.y + m,"w":350,"h":powerH};
         out.Module = {"x":param1.x + m,"y":param1.y + m + powerH + 12,"w":350,"h":moduleH};
         out.Browser = {"x":param1.x + param1.width - m - bw,"y":param1.y + m,"w":bw,"h":Math.min(846,param1.height - m * 2 - statsH - 20)};
         out.Credits = {"x":out.Browser.x - 12 - 363,"y":param1.y + m,"w":363,"h":102};
         out.Hints = {"x":param1.x + param1.width - m - 744,"y":param1.y + param1.height - m - statsH - 8 - hintsH,"w":744,"h":hintsH};
         out.Stats = {"x":param1.x + Math.max(m,400 * param1.width / 1920),"y":param1.y + param1.height - m - statsH,"w":Math.min(1464,param1.width - m * 2),"h":statsH};
         out.Cluster = {"x":param1.x + m,"y":param1.y + 8,"w":190,"h":40};
         return out;
      }
      
      private function resolveX(param1:String, param2:Object, param3:Object):Number
      {
         var raw:String = this.lay[param1 + "X"] != null ? String(this.lay[param1 + "X"]) : "-1";
         if(raw == "-1" || raw.length < 2) { return param2.x; }
         var edge:String = raw.charAt(0);
         var off:Number = Number(raw.substring(1));
         if(isNaN(off)) { return param2.x; }
         var x:Number = param2.x;
         if(edge == "L") { x = param3.x + this.margin + off; }
         else if(edge == "R") { x = param3.x + param3.width - this.margin - param2.w - off; }
         else if(edge == "C") { x = param3.x + (param3.width - param2.w) / 2 + off; }
         return x;
      }
      
      private function resolveY(param1:String, param2:Object, param3:Object):Number
      {
         var raw:String = this.lay[param1 + "Y"] != null ? String(this.lay[param1 + "Y"]) : "-1";
         if(raw == "-1" || raw.length < 2) { return param2.y; }
         var edge:String = raw.charAt(0);
         var off:Number = Number(raw.substring(1));
         if(isNaN(off)) { return param2.y; }
         var y:Number = param2.y;
         if(edge == "T") { y = param3.y + this.margin + off; }
         else if(edge == "B") { y = param3.y + param3.height - this.margin - param2.h - off; }
         else if(edge == "C") { y = param3.y + (param3.height - param2.h) / 2 + off; }
         return y;
      }
      
      private function redraw():void
      {
         var r:Object = this.view();
         this.modView = r;
         var box:Object = this.layoutBoxes(r);
         var c:uint = this.accentColor();
         var i:int = 0;
         while(i < this.cards.length)
         {
            var row:Object = this.cards[i];
            var card:Sprite = row.card as Sprite;
            var spot:Object = box[row.id];
            var g:* = card.graphics;
            g.clear();
            var wide:Number = Number(row.ww) > 0 ? Number(row.ww) : spot.w;
            var high:Number = Number(row.hh) > 0 ? Number(row.hh) : spot.h;
            var show:Boolean = row.id == "Cluster";
            card.visible = show && !this.conflict;
            if(this.followsGame(String(row.id)))
            {
               card.mouseEnabled = false;
               card.mouseChildren = false;
               card.visible = false;
            }
            if(row.id == "Cluster")
            {
               card.mouseEnabled = false;
               card.mouseChildren = true;
               var saved:String = this.lay["ClusterX"] != null ? String(this.lay["ClusterX"]) : "-1";
               if(!this.arranging && saved == "-1")
               {
                  card.x = r.x + this.margin;
                  card.y = r.y + 8;
               }
            }
            if(row.id != "Cluster" && show)
            {
               g.lineStyle(1.5,c,0.95);
               g.beginFill(0x121610,0.82);
               g.drawRoundRect(0,0,wide,high,16,16);
               g.endFill();
               g.lineStyle();
            }
            var title:TextField = row.title as TextField;
            if(title != null)
            {
               title.textColor = c;
               var tf:TextFormat = title.defaultTextFormat;
               tf.color = c;
               tf.size = row.id == "Cluster" ? this.bodyPx : (this.bodyPx + 1);
               title.setTextFormat(tf);
               title.visible = row.id != "Cluster";
            }
            i++;
         }
         this.paintGear();
         if(this.titleT == null)
         {
            this.titleT = this.makeText("HORIZON SHIP BUILDER",0,0,360,24,this.bodyPx,c);
            this.titleT.mouseEnabled = false;
            addChild(this.titleT);
         }
         this.titleT.textColor = c;
         this.titleT.visible = false;
         this.parkTitle(r);
         if(!this.mapped)
         {
            var j:int = 0;
            while(j < this.cards.length)
            {
               var home:Object = box[this.cards[j].id];
               (this.cards[j].card as Sprite).x = home.x;
               (this.cards[j].card as Sprite).y = home.y;
               j++;
            }
         }
         if(this.modOn && this.accentColor() != this.modTint) { this.paintSafe(); }
      }
      
      private function openSettings():void
      {
         if(this.setLayer == null) { this.buildSettings(); }
         this.setOpen = true;
         this.setLayer.visible = true;
         addChild(this.setLayer);
         this.note("SETTINGS open");
      }
      
      private function buildSettings():void
      {
         this.setLayer = new Sprite();
         this.setLayer.name = "HsbSettings";
         this.setLayer.visible = false;
         var g:* = this.setLayer.graphics;
         var r:Object = this.view();
         g.beginFill(0x000000,0.45);
         g.drawRect(r.x,r.y,r.width,r.height);
         g.endFill();
         g.lineStyle(1.5,this.accentColor(),1);
         g.beginFill(0x141810,0.96);
         var panelW:Number = 520;
         var panelH:Number = 560;
         var panelX:Number = r.x + (r.width - panelW) / 2;
         var panelY:Number = r.y + 180;
         if(panelX < r.x + this.margin) { panelX = r.x + this.margin; }
         if(panelY + panelH > r.y + r.height - this.margin) { panelY = r.y + r.height - this.margin - panelH; }
         g.drawRoundRect(panelX,panelY,panelW,panelH,18,18);
         g.endFill();
         var x0:Number = panelX;
         var y0:Number = panelY;
         this.setLayer.addChild(this.makeText("SETTINGS",x0 + 24,y0 + 16,240,28,this.bodyPx + 4,this.accentColor()));
         this.setLayer.addChild(this.makeText("APPEARANCE",x0 + 24,y0 + 58,240,22,this.bodyPx + 1,0xF4F0E4));
         var i:int = 0;
         while(i < ACCENTS.length)
         {
            var sw:Sprite = new Sprite();
            sw.name = "sw" + i;
            var sg:* = sw.graphics;
            sg.beginFill(uint(ACCENTS[i]),1);
            sg.drawRoundRect(0,0,28,28,8,8);
            sg.endFill();
            sw.x = x0 + 24 + (i % 7) * 36;
            sw.y = y0 + 96 + int(i / 7) * 36;
            sw.buttonMode = true;
            sw.addEventListener(MouseEvent.CLICK,this.onSwatch);
            this.setLayer.addChild(sw);
            i++;
         }
         this.hexBox = new TextField();
         this.hexBox.embedFonts = this.faceEmbed;
         this.hexBox.defaultTextFormat = this.textFormat(this.bodyPx,0xF4F0E4);
         this.hexBox.type = TextFieldType.INPUT;
         this.hexBox.border = true;
         this.hexBox.borderColor = this.accentColor();
         this.hexBox.background = true;
         this.hexBox.backgroundColor = 0x1C1A16;
         this.hexBox.textColor = 0xF4F0E4;
         this.hexBox.width = 140;
         this.hexBox.height = this.bodyPx + 13;
         this.hexBox.x = x0 + 24;
         this.hexBox.y = y0 + 180;
         this.hexBox.text = this.accentHex.length == 6 ? this.accentHex : "E8C547";
         this.hexBox.addEventListener(MouseEvent.CLICK,this.onHexField);
         this.texts.push(this.hexBox);
         this.setLayer.addChild(this.hexBox);
         var hexBtn:Sprite = this.makeButton("CUSTOM",x0 + 176,y0 + 180,110,28,false);
         hexBtn.addEventListener(MouseEvent.CLICK,this.onHex);
         this.setLayer.addChild(hexBtn);
         if(this.core)
         {
            var hud:Sprite = this.makeButton("FOLLOW HUD",x0 + 300,y0 + 180,150,28,false);
            hud.addEventListener(MouseEvent.CLICK,this.onFollow);
            this.setLayer.addChild(hud);
         }
         var arr:Sprite = this.makeButton("ARRANGE PANELS",x0 + 24,y0 + 240,472,40,true);
         arr.addEventListener(MouseEvent.CLICK,this.onArrangeBtn);
         this.setLayer.addChild(arr);
         this.setLayer.addChild(this.makeText("Drag panels on the next screen. The parts list stays the game list.",x0 + 24,y0 + 292,472,44,this.bodyPx,0xC8C0B0));
         var done:Sprite = this.makeButton("DONE",x0 + 360,y0 + 500,132,36,true);
         done.addEventListener(MouseEvent.CLICK,this.onDone);
         this.setLayer.addChild(done);
         addChild(this.setLayer);
      }
      
      private function onSwatch(param1:MouseEvent):void
      {
         var name:String = param1.currentTarget.name;
         var n:int = int(name.substring(2));
         if(n < 0 || n > 12) { return; }
         this.accent = n;
         this.accentHex = "";
         this.note("ACCENT " + n);
         this.redraw();
         this.closeSettings();
      }
      
      // The game's rename field takes focus the same way when editing starts. A click alone may
      // not move focus in this menu. The code is selected so six typed characters replace it.
      private function onHexField(param1:MouseEvent):void
      {
         if(stage == null || !this.setOpen) { return; }
         if(stage.focus != this.hexBox)
         {
            this.giveFocus(this.hexBox);
            this.hexBox.setSelection(0,this.hexBox.text.length);
         }
         this.note("SETTINGS hex focus=" + this.focusName(stage.focus));
      }
      
      private function onHex(param1:MouseEvent):void
      {
         var raw:String = this.hexBox != null ? this.hexBox.text : "";
         var hex:String = "";
         var i:int = 0;
         while(i < raw.length)
         {
            var ch:String = raw.charAt(i);
            if(ch != "#") { hex += ch; }
            i++;
         }
         if(hex.length != 6) { return; }
         this.accent = 13;
         this.accentHex = hex.toUpperCase();
         this.note("HEX " + this.accentHex);
         this.redraw();
      }
      
      private function onFollow(param1:MouseEvent):void
      {
         this.accent = -1;
         this.note("ACCENT -1");
         this.redraw();
      }
      
      private function onArrangeBtn(param1:MouseEvent):void
      {
         this.closeSettings();
         this.openArrange();
      }
      
      private function onDone(param1:MouseEvent):void
      {
         this.closeSettings();
      }
      
      // The game list hears arrow keys and Enter only while it holds focus. ModulePalette.Update
      // gives it focus while it shows and clears focus otherwise, so Settings hands back the same way.
      private function closeSettings():void
      {
         var was:Boolean = this.setOpen;
         this.setOpen = false;
         if(this.setLayer != null) { this.setLayer.visible = false; }
         if(stage == null) { return; }
         var held:String = this.focusName(stage.focus);
         if(held == "hex" || held == "ours")
         {
            var list:InteractiveObject = this.nativeList();
            if(list != null && !this.chainShown(list)) { list = null; }
            this.giveFocus(list);
         }
         if(was || held == "hex" || held == "ours") { this.note("SETTINGS close focus=" + held + ">" + this.focusName(stage.focus)); }
      }
      
      // IMenu can put focus back on the object that just lost it after a click. That restore
      // runs once, so a second assignment sticks.
      private function giveFocus(param1:InteractiveObject):void
      {
         stage.focus = param1;
         if(stage.focus != param1) { stage.focus = param1; }
      }
      
      private function nativeList():InteractiveObject
      {
         var list:InteractiveObject = null;
         try { list = this.host["ModulePalette_mc"]["ModuleEntries_mc"] as InteractiveObject; } catch(err:Error) { list = null; }
         return list;
      }
      
      // Names the focus holder for the log by kind only.
      private function focusName(param1:InteractiveObject):String
      {
         if(param1 == null) { return "none"; }
         if(param1 == this.hexBox) { return "hex"; }
         if(this.contains(param1)) { return "ours"; }
         var list:DisplayObjectContainer = this.nativeList() as DisplayObjectContainer;
         if(list != null && list.contains(param1)) { return "list"; }
         return "other";
      }
      
      private function openArrange():void
      {
         if(this.conflict || this.arranging) { return; }
         this.closeSettings();
         this.arranging = true;
         if(this.modOn) { this.seatModule(this.modNative); }
         this.ignorePress = true;
         this.dragId = "";
         this.remember();
         this.sel = this.defaultSel();
         this.showStandIns(true);
         if(this.arrLayer == null)
         {
            this.arrLayer = new Sprite();
            this.arrLayer.name = "HsbArrange";
         }
         this.arrLayer.visible = true;
         addChild(this.arrLayer);
         this.drawArrange();
         this.note("ARRANGE open");
      }
      
      private function remember():void
      {
         this.snap = [];
         this.vis = [];
         this.homes = [];
         this.openBarX = this.barDx;
         this.openBarY = this.barDy;
         this.openLay = {};
         var i:int = 0;
         while(i < this.cards.length)
         {
            var card:Sprite = this.cards[i].card as Sprite;
            var id:String = String(this.cards[i].id);
            var clip:DisplayObject = this.clipByName(id);
            this.snap.push({"x":card.x,"y":card.y});
            this.vis.push(true);
            if(clip != null && this.panelMovable(id) && id != "Cluster")
            {
               this.homes.push({"x":clip.x,"y":clip.y,"ok":true});
            }
            else
            {
               this.homes.push({"x":0,"y":0,"ok":false});
            }
            var ax:String = this.lay[id + "X"] != null ? String(this.lay[id + "X"]) : "-1";
            var ay:String = this.lay[id + "Y"] != null ? String(this.lay[id + "Y"]) : "-1";
            this.openLay[id + "X"] = ax;
            this.openLay[id + "Y"] = ay;
            i++;
         }
      }
      
      private function showStandIns(param1:Boolean):void
      {
         var i:int = 0;
         while(i < this.cards.length)
         {
            var card:Sprite = this.cards[i].card as Sprite;
            var stand:DisplayObject = card.getChildByName("HsbSample");
            if(stand != null) { card.removeChild(stand); }
            i++;
         }
      }
      
      private function drawArrange():void
      {
         if(this.arrLayer == null) { return; }
         var g:* = this.arrLayer.graphics;
         g.clear();
         var r:Object = this.view();
         g.beginFill(0x000000,0.25);
         g.drawRect(r.x,r.y,r.width,r.height);
         g.endFill();
         g.lineStyle(1,0xFFFFFF,0.06);
         var gx:Number = r.x;
         while(gx <= r.x + r.width)
         {
            g.moveTo(gx,r.y);
            g.lineTo(gx,r.y + r.height);
            gx += 40;
         }
         var gy:Number = r.y;
         while(gy <= r.y + r.height)
         {
            g.moveTo(r.x,gy);
            g.lineTo(r.x + r.width,gy);
            gy += 40;
         }
         g.lineStyle(1,this.accentColor(),0.18);
         g.moveTo(r.x + r.width / 2,r.y);
         g.lineTo(r.x + r.width / 2,r.y + r.height);
         var boxes:Object = this.layoutBoxes(r);
         var clear:Object = {"x":boxes.Power.x + boxes.Power.w + 16,"y":boxes.Credits.y + boxes.Credits.h + 8,"w":boxes.Browser.x - (boxes.Power.x + boxes.Power.w) - 32,"h":boxes.Hints.y - (boxes.Credits.y + boxes.Credits.h) - 16};
         this.dash(g,clear.x,clear.y,clear.w,clear.h,0xF28A4F);
         var i:int = 0;
         while(i < this.cards.length)
         {
            var row:Object = this.cards[i];
            var wide:Number = 0;
            var high:Number = 0;
            var on:Boolean = this.sel == row.id || this.dragId == row.id;
            if(!this.eligible(String(row.id)))
            {
               this.hideLabel(String(row.id));
               i++;
               continue;
            }
            var live:Rectangle = this.liveBounds(String(row.id));
            wide = live.width;
            high = live.height;
            g.lineStyle(on ? 2 : 1.5,on ? this.accentColor() : 0xFFFFFF,on ? 1 : 0.55);
            g.beginFill(this.accentColor(),on ? 0.1 : 0.03);
            g.drawRoundRect(live.x - 4,live.y - 4,wide + 8,high + 8,16,16);
            g.endFill();
            this.ensureLabel(row.id,this.panelLabel(String(row.id)),live.x,live.y - 22,on);
            if(this.overlaps(live.x,live.y,wide,high,clear))
            {
               this.chip(g,live.x + 8,live.y + high - 28);
            }
            i++;
         }
         g.lineStyle();
         var tw:Number = 720;
         var th:Number = 96;
         var tx:Number = r.x + (r.width - tw) / 2 + this.barDx;
         var ty:Number = r.y + r.height * 0.42 + this.barDy;
         tx = this.clamp(tx,r.x,r.x + r.width - tw);
         ty = this.clamp(ty,r.y,r.y + r.height - th);
         this.barGx = tx;
         this.barGy = ty;
         g.lineStyle(1.5,this.accentColor(),0.95);
         g.beginFill(0x10160F,0.94);
         g.drawRoundRect(tx,ty,tw,th,16,16);
         g.endFill();
         var d:int = 0;
         while(d < 6)
         {
            g.beginFill(0xFFFFFF,0.55);
            g.drawCircle(tx + 14 + (d % 2) * 6,ty + 22 + int(d / 2) * 7,1.6);
            g.endFill();
            d++;
         }
         this.ensureLabel("hint","Drag a panel  ·  arrows nudge  ·  Tab next  ·  ENTER save  ·  ESC cancel",tx + 28,ty + 14,false);
         this.ensureLabel("nudge","NUDGE",tx + 28,ty + 58,false);
         this.button(g,"nL",tx + 110,ty + 54,36,28,"<");
         this.button(g,"nR",tx + 152,ty + 54,36,28,">");
         this.button(g,"nU",tx + 194,ty + 54,36,28,"^");
         this.button(g,"nD",tx + 236,ty + 54,36,28,"v");
         this.button(g,"reset",tx + tw - 300,ty + 54,88,28,"RESET");
         this.button(g,"ok",tx + tw - 204,ty + 54,88,28,"OK");
         this.button(g,"cancel",tx + tw - 108,ty + 54,88,28,"CANCEL");
      }
      
      private function button(param1:*, param2:String, param3:Number, param4:Number, param5:Number, param6:Number, param7:String):void
      {
         var gold:Boolean = param2 == "ok";
         param1.lineStyle(1,gold ? this.accentColor() : 0x5A6A76,0.9);
         param1.beginFill(gold ? this.accentColor() : 0x26343F,gold ? 0.9 : 0.85);
         param1.drawRoundRect(param3,param4,param5,param6,8,8);
         param1.endFill();
         this.ensureLabel(param2,param7,param3,param4 + 4,false);
      }
      
      private function ensureLabel(param1:String, param2:String, param3:Number, param4:Number, param5:Boolean):void
      {
         var field:TextField = this.arrLayer.getChildByName("lb" + param1) as TextField;
         if(field == null)
         {
            field = this.makeText(param2,param3,param4,280,22,this.bodyPx,param5 ? this.accentColor() : 0xF4F0E4);
            field.name = "lb" + param1;
            field.mouseEnabled = false;
            this.arrLayer.addChild(field);
         }
         field.text = param2;
         field.x = param3;
         field.y = param4;
         field.visible = true;
      }
      
      private function chip(param1:*, param2:Number, param3:Number):void
      {
         param1.lineStyle(1,0xF28A4F,1);
         param1.beginFill(0x2A160C,0.92);
         param1.drawRoundRect(param2,param3,210,24,8,8);
         param1.endFill();
         param1.beginFill(0xF28A4F,1);
         param1.moveTo(param2 + 8,param3 + 16);
         param1.lineTo(param2 + 14,param3 + 6);
         param1.lineTo(param2 + 20,param3 + 16);
         param1.lineTo(param2 + 8,param3 + 16);
         param1.endFill();
         this.ensureLabel("warn" + int(param2),"COVERS THE SHIP VIEW",param2 + 26,param3 + 2,false);
      }
      
      private function dash(param1:*, param2:Number, param3:Number, param4:Number, param5:Number, param6:uint):void
      {
         param1.lineStyle(1.5,param6,0.9);
         var x:Number = param2;
         while(x < param2 + param4)
         {
            param1.moveTo(x,param3);
            param1.lineTo(Math.min(x + 8,param2 + param4),param3);
            param1.moveTo(x,param3 + param5);
            param1.lineTo(Math.min(x + 8,param2 + param4),param3 + param5);
            x += 14;
         }
         var y:Number = param3;
         while(y < param3 + param5)
         {
            param1.moveTo(param2,y);
            param1.lineTo(param2,Math.min(y + 8,param3 + param5));
            param1.moveTo(param2 + param4,y);
            param1.lineTo(param2 + param4,Math.min(y + 8,param3 + param5));
            y += 14;
         }
         param1.lineStyle();
      }
      
      private function overlaps(param1:Number, param2:Number, param3:Number, param4:Number, param5:Object):Boolean
      {
         return param1 < param5.x + param5.w && param1 + param3 > param5.x && param2 < param5.y + param5.h && param2 + param4 > param5.y;
      }
      
      private function onFeed(param1:String):void
      {
         if(param1.indexOf("M ") == 0)
         {
            var bits:Array = param1.split(" ");
            if(bits.length < 4) { return; }
            this.onPointer(String(bits[1]),Number(bits[2]),Number(bits[3]));
            return;
         }
         if(param1.indexOf("K ") != 0) { return; }
         var token:String = param1.substring(2);
         if(token == "open")
         {
            if(this.keysOn && !this.arranging && !this.conflict) { this.openArrange(); }
            return;
         }
         if(!this.arranging)
         {
            if(token == "cancel") { this.cancelTop(); }
            return;
         }
         if(token == "cancel") { this.cancelArrange(); return; }
         if(token == "ok") { this.okArrange(); return; }
         if(token == "noop") { return; }
         if(token == "tab") { this.cycle(1); return; }
         if(token == "tabprev") { this.cycle(-1); return; }
         var step:Number = token.indexOf("40") >= 0 ? 40 : 10;
         if(token.indexOf("left") == 0) { this.nudge(-step,0); }
         else if(token.indexOf("right") == 0) { this.nudge(step,0); }
         else if(token.indexOf("up") == 0) { this.nudge(0,-step); }
         else if(token.indexOf("down") == 0) { this.nudge(0,step); }
      }
      
      private function onPointer(param1:String, param2:Number, param3:Number):void
      {
         if(!this.arranging) { return; }
         this.pt.x = param2;
         this.pt.y = param3;
         var lp:Point = this.globalToLocal(this.pt);
         if(param1 == "D")
         {
            if(this.ignorePress) { this.ignorePress = false; return; }
            var hit:String = this.hitAt(lp.x,lp.y);
            if(hit == "ok") { this.okArrange(); return; }
            if(hit == "cancel") { this.cancelArrange(); return; }
            if(hit == "reset") { this.resetArrange(); return; }
            if(hit == "nL") { this.nudge(-10,0); return; }
            if(hit == "nR") { this.nudge(10,0); return; }
            if(hit == "nU") { this.nudge(0,-10); return; }
            if(hit == "nD") { this.nudge(0,10); return; }
            if(hit == "bar")
            {
               this.barDrag = true;
               this.dragDx = lp.x - this.barGx;
               this.dragDy = lp.y - this.barGy;
               return;
            }
            if(hit.length > 0 && this.eligible(hit))
            {
               this.sel = hit;
               this.dragId = hit;
               var live:Rectangle = this.liveBounds(hit);
               this.dragDx = lp.x - live.x;
               this.dragDy = lp.y - live.y;
            }
            else
            {
               this.dragId = "";
            }
            this.drawArrange();
            return;
         }
         if(param1 == "M")
         {
            if(this.barDrag)
            {
               var r:Object = this.view();
               this.barDx = (lp.x - this.dragDx) - (r.x + (r.width - 720) / 2);
               this.barDy = (lp.y - this.dragDy) - (r.y + r.height * 0.42);
               this.drawArrange();
               return;
            }
            if(this.dragId.length > 0 && this.eligible(this.dragId))
            {
               this.moveLive(this.dragId,lp.x - this.dragDx,lp.y - this.dragDy);
               this.drawArrange();
            }
            return;
         }
         if(param1 == "U")
         {
            this.barDrag = false;
            this.dragId = "";
            this.drawArrange();
         }
      }
      
      private function hitAt(param1:Number, param2:Number):String
      {
         var names:Array = ["ok","cancel","reset","nL","nR","nU","nD"];
         var i:int = 0;
         while(i < names.length)
         {
            var field:TextField = this.arrLayer.getChildByName("lb" + names[i]) as TextField;
            if(field != null && param1 >= field.x - 8 && param1 <= field.x + 96 && param2 >= field.y - 6 && param2 <= field.y + 28) { return String(names[i]); }
            i++;
         }
         if(param1 >= this.barGx && param1 <= this.barGx + 720 && param2 >= this.barGy && param2 <= this.barGy + 96) { return "bar"; }
         var k:int = this.cards.length - 1;
         while(k >= 0)
         {
            var id:String = String(this.cards[k].id);
            if(this.eligible(id))
            {
               var live:Rectangle = this.liveBounds(id);
               if(param1 >= live.x && param1 <= live.x + live.width && param2 >= live.y && param2 <= live.y + live.height) { return id; }
            }
            k--;
         }
         return "";
      }
      
      private function hideLabel(param1:String):void
      {
         if(this.arrLayer == null) { return; }
         var field:TextField = this.arrLayer.getChildByName("lb" + param1) as TextField;
         if(field != null) { field.visible = false; }
      }
      
      private function moveLive(param1:String, param2:Number, param3:Number):void
      {
         if(!this.eligible(param1)) { return; }
         var live:Rectangle = this.liveBounds(param1);
         if(live == null) { return; }
         var r:Object = this.view();
         var size:Rectangle = this.anchorBox(param1,live);
         var x:Number = r.x + Math.round((param2 - r.x) / 10) * 10;
         var y:Number = r.y + Math.round((param3 - r.y) / 10) * 10;
         x = this.clamp(x,r.x,r.x + r.width - Math.max(live.width,size.width));
         y = this.clamp(y,r.y,r.y + r.height - Math.max(live.height,size.height));
         if(param1 == "Cluster")
         {
            var card:Sprite = this.cardBy(param1).card as Sprite;
            card.x += x - live.x;
            card.y += y - live.y;
         }
         else
         {
            var clip:DisplayObject = this.clipByName(param1);
            this.moveNative(clip,x - live.x,y - live.y);
            this.strokeBehind(clip,param1);
            this.parkHeading(param1,clip);
            if(param1 == "Module" && this.modOn) { this.seatModule(this.modNative); }
         }
         var spot:Object = {"x":x,"y":y,"w":size.width,"h":size.height};
         this.storeAnchor(param1,x,y,spot,r);
      }
      
      // Our card's top left is the game card's top left. Module anchors use the game card's
      // size, so a spot saved over our card reloads in place before our card is up.
      private function anchorBox(param1:String, param2:Rectangle):Rectangle
      {
         if(param1 == "Module" && this.modOn && this.modNative != null && this.modNative.parent != null)
         {
            return this.modNative.getBounds(this);
         }
         return param2;
      }
      
      private function storeAnchor(param1:String, param2:Number, param3:Number, param4:Object, param5:Object):void
      {
         var midX:Number = param2 + param4.w / 2;
         var midY:Number = param3 + param4.h / 2;
         var cx:Number = param5.x + param5.width / 2;
         var cy:Number = param5.y + param5.height / 2;
         var ax:String = "C";
         var dx:Number = Math.round(param2 - (cx - param4.w / 2));
         if(Math.abs(midX - cx) >= param5.width / 6)
         {
            if(midX < cx) { ax = "L"; dx = Math.round(param2 - (param5.x + this.margin)); }
            else { ax = "R"; dx = Math.round(param5.x + param5.width - this.margin - param4.w - param2); }
         }
         var ay:String = "C";
         var dy:Number = Math.round(param3 - (cy - param4.h / 2));
         if(Math.abs(midY - cy) >= param5.height / 6)
         {
            if(midY < cy) { ay = "T"; dy = Math.round(param3 - (param5.y + this.margin)); }
            else { ay = "B"; dy = Math.round(param5.y + param5.height - this.margin - param4.h - param3); }
         }
         this.lay[param1 + "X"] = ax + String(int(dx));
         this.lay[param1 + "Y"] = ay + String(int(dy));
      }
      
      private function nudge(param1:Number, param2:Number):void
      {
         if(!this.eligible(this.sel)) { return; }
         var live:Rectangle = this.liveBounds(this.sel);
         if(live == null) { return; }
         this.moveLive(this.sel,live.x + param1,live.y + param2);
         this.drawArrange();
      }
      
      private function cycle(param1:int):void
      {
         var order:Array = [];
         var i:int = 0;
         while(i < IDS.length)
         {
            if(this.eligible(String(IDS[i]))) { order.push(String(IDS[i])); }
            i++;
         }
         if(order.length == 0)
         {
            this.sel = "";
            this.drawArrange();
            return;
         }
         var at:int = order.indexOf(this.sel);
         if(at < 0) { this.sel = param1 < 0 ? String(order[order.length - 1]) : String(order[0]); }
         else
         {
            var n:int = at + param1;
            if(n < 0) { n = order.length - 1; }
            if(n >= order.length) { n = 0; }
            this.sel = String(order[n]);
         }
         this.drawArrange();
      }
      
      private function resetArrange():void
      {
         this.lay = {};
         this.barDx = 0;
         this.barDy = 0;
         var r:Object = this.view();
         var i:int = 0;
         while(i < this.cards.length)
         {
            var id:String = String(this.cards[i].id);
            if(id == "Cluster")
            {
               var card:Sprite = this.cards[i].card as Sprite;
               card.x = r.x + this.margin;
               card.y = r.y + 8;
            }
            else if(this.cards[i].homed == true)
            {
               var clip:DisplayObject = this.clipByName(id);
               if(clip != null)
               {
                  clip.x = Number(this.cards[i].homeX);
                  clip.y = Number(this.cards[i].homeY);
                  this.strokeBehind(this.clipLive(clip) ? clip : null,id);
               }
            }
            i++;
         }
         if(this.modOn) { this.seatModule(this.modNative); }
         this.drawArrange();
      }
      
      private function okArrange():void
      {
         var i:int = 0;
         while(i < IDS.length)
         {
            var id:String = String(IDS[i]);
            if(!this.panelMovable(id))
            {
               this.lay[id + "X"] = "-1";
               this.lay[id + "Y"] = "-1";
            }
            var x:String = this.lay[id + "X"] != null ? String(this.lay[id + "X"]) : "-1";
            var y:String = this.lay[id + "Y"] != null ? String(this.lay[id + "Y"]) : "-1";
            this.note("ARRANGE " + id + "X=" + x);
            this.note("ARRANGE " + id + "Y=" + y);
            i++;
         }
         this.note("ARRANGE ArrangeBarX=" + int(this.barDx));
         this.note("ARRANGE ArrangeBarY=" + int(this.barDy));
         this.note("ARRANGE END");
         this.pendingSave = true;
         this.finishArrange(true);
      }
      
      private function cancelArrange():void
      {
         if(this.openLay != null) { this.lay = this.openLay; }
         this.barDx = this.openBarX;
         this.barDy = this.openBarY;
         var i:int = 0;
         while(i < this.cards.length)
         {
            var card:Sprite = this.cards[i].card as Sprite;
            card.x = this.snap[i].x;
            card.y = this.snap[i].y;
            var id:String = String(this.cards[i].id);
            if(i < this.homes.length && this.homes[i].ok == true)
            {
               var clip:DisplayObject = this.clipByName(id);
               if(clip != null)
               {
                  clip.x = Number(this.homes[i].x);
                  clip.y = Number(this.homes[i].y);
                  this.strokeBehind(this.clipLive(clip) ? clip : null,id);
               }
            }
            i++;
         }
         if(this.modOn) { this.seatModule(this.modNative); }
         this.finishArrange(false);
      }
      
      private function finishArrange(param1:Boolean):void
      {
         var i:int = 0;
         while(i < this.cards.length)
         {
            var clip:DisplayObject = this.cards[i].clip as DisplayObject;
            if(clip != null && i < this.vis.length) { clip.visible = this.vis[i]; }
            i++;
         }
         this.showStandIns(false);
         this.arranging = false;
         this.dragId = "";
         this.barDrag = false;
         if(this.arrLayer != null) { this.arrLayer.visible = false; }
         this.note(param1 ? "ARRANGE saved" : "ARRANGE cancel");
      }
      
      private function cancelTop():void
      {
         if(this.arranging) { this.cancelArrange(); }
         else { this.closeSettings(); }
      }
      
      private function showBanner(param1:String):void
      {
         if(this.banner == null)
         {
            this.banner = this.makeText(param1,80,80,760,28,this.bodyPx,0xF28A4F);
            addChild(this.banner);
         }
         this.banner.text = param1;
         this.banner.visible = true;
      }
      
      private function accentColor():uint
      {
         if(this.accent == 13 && this.accentHex.length == 6) { return this.hexColor(this.accentHex); }
         var n:int = this.accent;
         if(n < 0 || n > 12) { n = 9; }
         return uint(ACCENTS[n]);
      }
      
      private function hexColor(param1:String):uint
      {
         var n:uint = 0;
         var i:int = 0;
         while(i < 6)
         {
            var c:Number = parseInt(param1.charAt(i),16);
            if(isNaN(c)) { return 0xE8C547; }
            n = (n << 4) + uint(c);
            i++;
         }
         return n;
      }
      
      private function cardBy(param1:String):Object
      {
         var i:int = 0;
         while(i < this.cards.length)
         {
            if(this.cards[i].id == param1) { return this.cards[i]; }
            i++;
         }
         return null;
      }
      
      private function view():Object
      {
         try
         {
            var ext:Class = Class(getDefinitionByName("Extensions"));
            var rect:Object = ext["visibleRect"];
            if(rect != null && rect.width > 100 && rect.height > 100)
            {
               return {"x":rect.x,"y":rect.y,"width":rect.width,"height":rect.height};
            }
         }
         catch(err:Error)
         {
         }
         var w:Number = stage != null ? stage.stageWidth : 1920;
         var h:Number = stage != null ? stage.stageHeight : 1080;
         return {"x":0,"y":0,"width":w,"height":h};
      }
      
      private function clamp(param1:Number, param2:Number, param3:Number):Number
      {
         if(param3 < param2) { return param2; }
         if(param1 < param2) { return param2; }
         if(param1 > param3) { return param3; }
         return param1;
      }
      
      private function dressInteriors():void
      {
         this.revalidateFades();
         var ids:Array = ["Power","Module","Browser","Credits","Stats"];
         var n:int = 0;
         while(n < ids.length)
         {
            var id:String = String(ids[n]);
            var clip:DisplayObject = this.clipByName(id);
            if(this.clipLive(clip) && clip is DisplayObjectContainer && !(id == "Module" && this.modOn))
            {
               this.dressClip(id,clip as DisplayObjectContainer);
            }
            else
            {
               this.clearInterior(id,clip);
            }
            n++;
         }
         this.parkTitle(this.view());
      }
      
      private function dressClip(param1:String, param2:DisplayObjectContainer):void
      {
         if(param1 != "Power") { this.paintPlate(param1,param2); }
         this.fadeInside(param1,param2,param2,0);
         this.recolorTree(param2,0);
         this.parkHeading(param1,param2);
      }
      
      private function clearInterior(param1:String, param2:DisplayObject):void
      {
         if(param2 != null) { this.restoreFades(param2); }
         this.removeOurChild(param2,"HsbPlate");
         this.removeHeading(param1);
      }
      
      private function paintPlate(param1:String, param2:DisplayObject):void
      {
         if(param2 == null || param2.parent == null) { return; }
         var parent:DisplayObjectContainer = param2.parent as DisplayObjectContainer;
         var frame:Sprite = parent.getChildByName("HsbFrame" + param1) as Sprite;
         if(frame == null) { return; }
         var box:Rectangle = param2.getBounds(parent);
         var g:* = frame.graphics;
         g.clear();
         g.beginFill(0x121610,0.94);
         g.drawRoundRect(box.x - 8,box.y - 8,box.width + 16,box.height + 16,14,14);
         g.endFill();
         g.lineStyle(1.5,this.accentColor(),0.95);
         g.drawRoundRect(box.x - 8,box.y - 8,box.width + 16,box.height + 16,14,14);
         g.lineStyle();
      }
      
      private function fadeInside(param1:String, param2:DisplayObjectContainer, param3:DisplayObjectContainer, param4:int):void
      {
         if(param3 == null || param4 > 3) { return; }
         var i:int = 0;
         while(i < param3.numChildren)
         {
            var child:DisplayObject = param3.getChildAt(i);
            var cname:String = child.name == null ? "" : String(child.name);
            if(this.isOurNode(cname) || this.isProtectedName(cname))
            {
               i++;
               continue;
            }
            if(this.fadeEligible(param1,child,param2))
            {
               this.rememberFade(child,param1);
            }
            else if(child is DisplayObjectContainer)
            {
               this.fadeInside(param1,param2,child as DisplayObjectContainer,param4 + 1);
            }
            i++;
         }
      }
      
      private function fadeEligible(param1:String, param2:DisplayObject, param3:DisplayObject):Boolean
      {
         if(param2 == null) { return false; }
         var cname:String = param2.name == null ? "" : String(param2.name);
         if(this.nodeHasText(param2) || this.canHoldContent(param2)) { return false; }
         if(param2 is DisplayObjectContainer && (param2 as DisplayObjectContainer).numChildren > 0) { return false; }
         if(this.isOurNode(cname) || this.isProtectedName(cname)) { return false; }
         if(this.usedAs(param3,param2,"mask",0) || this.usedAs(param3,param2,"hit",0)) { return false; }
         if(this.isBackdropName(cname)) { return true; }
         if(param1 == "Module" && this.isLogoName(cname)) { return true; }
         return false;
      }
      
      private function canHoldContent(param1:DisplayObject):Boolean
      {
         return param1 is DisplayObjectContainer && !(param1 is Shape);
      }
      
      private function usedAs(param1:DisplayObject, param2:DisplayObject, param3:String, param4:int):Boolean
      {
         if(param1 == null || param2 == null || param4 > 8) { return false; }
         if(param3 == "mask" && param1.mask == param2) { return true; }
         if(param3 == "hit" && param1.hitArea == param2) { return true; }
         if(param1 is DisplayObjectContainer)
         {
            var box:DisplayObjectContainer = param1 as DisplayObjectContainer;
            var i:int = 0;
            while(i < box.numChildren)
            {
               if(this.usedAs(box.getChildAt(i),param2,param3,param4 + 1)) { return true; }
               i++;
            }
         }
         return false;
      }
      
      private function isOurNode(param1:String):Boolean
      {
         return param1 != null && param1.length >= 3 && param1.charAt(0) == "H" && param1.charAt(1) == "s" && param1.charAt(2) == "b";
      }
      
      private function isProtectedName(param1:String):Boolean
      {
         return this.foldHas(param1,"entry") || this.foldHas(param1,"categor") || this.foldHas(param1,"scroll") || this.foldHas(param1,"button") || this.foldHas(param1,"slider") || this.foldHas(param1,"pip") || this.foldHas(param1,"input") || this.foldHas(param1,"list") || this.foldHas(param1,"tab") || this.foldHas(param1,"select") || this.foldHas(param1,"alloc") || this.foldHas(param1,"meter") || this.foldHas(param1,"reactor") || this.foldHas(param1,"equip") || this.boundHas(param1,"mask") || this.boundHas(param1,"hitarea") || this.boundHas(param1,"hit") || this.boundHas(param1,"hotspot");
      }
      
      private function boundHas(param1:String, param2:String):Boolean
      {
         if(param1 == null || param2 == null || param2.length == 0 || param1.length < param2.length) { return false; }
         var needle:String = param2.toLowerCase();
         var i:int = 0;
         while(i + needle.length <= param1.length)
         {
            if(param1.substr(i,needle.length).toLowerCase() == needle)
            {
               var boundary:Boolean = i == 0;
               if(!boundary)
               {
                  var prev:int = param1.charCodeAt(i - 1);
                  var cur:int = param1.charCodeAt(i);
                  var prevLetter:Boolean = (prev >= 65 && prev <= 90) || (prev >= 97 && prev <= 122);
                  var camel:Boolean = prev >= 97 && prev <= 122 && cur >= 65 && cur <= 90;
                  boundary = !prevLetter || camel;
               }
               if(boundary) { return true; }
            }
            i++;
         }
         return false;
      }
      
      private function isBackdropName(param1:String):Boolean
      {
         return this.foldHas(param1,"background") || this.foldHas(param1,"backdrop") || this.foldHas(param1,"border") || this.foldHas(param1,"plate") || this.foldHas(param1,"shadow") || this.foldHas(param1,"gradient");
      }
      
      private function isLogoName(param1:String):Boolean
      {
         return this.foldHas(param1,"logo") || this.foldHas(param1,"brand") || this.foldHas(param1,"manufact") || this.foldHas(param1,"company") || this.foldHas(param1,"emblem") || this.foldHas(param1,"wordmark");
      }
      
      private function foldHas(param1:String, param2:String):Boolean
      {
         if(param1 == null || param2 == null || param2.length == 0) { return false; }
         return param1.toLowerCase().indexOf(param2.toLowerCase()) >= 0;
      }
      
      private function nodeHasText(param1:DisplayObject):Boolean
      {
         if(param1 is TextField)
         {
            var text:String = (param1 as TextField).text;
            return text != null && text.length > 0;
         }
         if(!(param1 is DisplayObjectContainer)) { return false; }
         var box:DisplayObjectContainer = param1 as DisplayObjectContainer;
         var i:int = 0;
         while(i < box.numChildren)
         {
            if(this.nodeHasText(box.getChildAt(i))) { return true; }
            i++;
         }
         return false;
      }
      
      private function rememberFade(param1:DisplayObject, param2:String):void
      {
         var i:int = 0;
         while(i < this.fades.length)
         {
            if(this.fades[i].target == param1) { return; }
            i++;
         }
         this.fades.push({"target":param1,"alpha":param1.alpha,"mouse":param1.mouseEnabled,"panel":param2});
         param1.alpha = 0;
         param1.mouseEnabled = false;
      }
      
      private function revalidateFades():void
      {
         var kept:Array = [];
         var i:int = 0;
         while(i < this.fades.length)
         {
            var item:Object = this.fades[i];
            var target:DisplayObject = item.target as DisplayObject;
            if(target != null && target.parent != null)
            {
               var root:DisplayObject = this.clipByName(String(item.panel));
               if(root == null) { root = target.parent; }
               if(this.fadeEligible(String(item.panel),target,root))
               {
                  kept.push(item);
               }
               else
               {
                  target.alpha = Number(item.alpha);
                  target.mouseEnabled = item.mouse == true;
               }
            }
            i++;
         }
         this.fades = kept;
      }
      
      private function restoreFades(param1:DisplayObject):void
      {
         var kept:Array = [];
         var i:int = 0;
         while(i < this.fades.length)
         {
            var item:Object = this.fades[i];
            var target:DisplayObject = item.target as DisplayObject;
            if(this.ownsNode(param1,target))
            {
               if(target != null)
               {
                  target.alpha = Number(item.alpha);
                  target.mouseEnabled = item.mouse == true;
               }
            }
            else
            {
               kept.push(item);
            }
            i++;
         }
         this.fades = kept;
      }
      
      private function ownsNode(param1:DisplayObject, param2:DisplayObject):Boolean
      {
         if(param1 == null || param2 == null) { return false; }
         var node:DisplayObject = param2;
         var guard:int = 0;
         while(node != null && guard < 10)
         {
            if(node == param1) { return true; }
            node = node.parent;
            guard++;
         }
         return false;
      }
      
      private function removeOurChild(param1:DisplayObject, param2:String):void
      {
         if(!(param1 is DisplayObjectContainer)) { return; }
         if(!this.isOurNode(param2)) { return; }
         var box:DisplayObjectContainer = param1 as DisplayObjectContainer;
         var child:DisplayObject = box.getChildByName(param2);
         if(child != null) { box.removeChild(child); }
      }
      
      private function removeHeading(param1:String):void
      {
         var node:DisplayObject = this.findDeep(this.host as DisplayObjectContainer,"HsbHead" + param1,0);
         if(node != null && node.parent != null && this.isOurNode(node.name))
         {
            (node.parent as DisplayObjectContainer).removeChild(node);
         }
      }
      
      private function parkHeading(param1:String, param2:DisplayObject):void
      {
         if(param1 == "Module" && this.modOn) { return; }
         if(param1 != "Power" && param1 != "Module" && param1 != "Browser")
         {
            this.removeHeading(param1);
            return;
         }
         if(param2 == null || param2.parent == null) { return; }
         var parent:DisplayObjectContainer = param2.parent as DisplayObjectContainer;
         var headName:String = "HsbHead" + param1;
         var label:String = param1 == "Power" ? "POWER" : (param1 == "Module" ? "SELECTED MODULE" : "PARTS BROWSER");
         var px:int = this.lrg ? 16 : 13;
         var head:TextField = parent.getChildByName(headName) as TextField;
         if(head == null)
         {
            head = this.makeText(label,0,0,360,px + 12,px,0xE8C547);
            head.name = headName;
            head.mouseEnabled = false;
            parent.addChild(head);
         }
         var box:Rectangle = param2.getBounds(parent);
         head.x = box.x;
         head.y = box.y - (px + 8);
         if(head.y < 2) { head.y = box.y + 4; }
      }
      
      private function parkTitle(param1:Object):void
      {
         var live:Boolean = this.clipLive(this.clipByName("Browser"));
         if(this.pill == null)
         {
            this.pill = new Sprite();
            this.pill.name = "HsbTitle";
            this.pill.mouseEnabled = false;
            this.pill.mouseChildren = false;
            var px0:int = this.lrg ? 20 : 16;
            var label0:TextField = this.makeText("HORIZON SHIP BUILDER",18,5,390,px0 + 10,px0,0xE8C547);
            label0.name = "HsbTitleText";
            this.pill.addChild(label0);
            addChild(this.pill);
         }
         this.pill.visible = live && !this.conflict;
         if(!this.pill.visible) { return; }
         var wide:Number = this.lrg ? 460 : 420;
         var high:Number = this.lrg ? 40 : 34;
         var g:* = this.pill.graphics;
         g.clear();
         g.lineStyle(1.5,0xE8C547,1);
         g.beginFill(0x141810,0.94);
         g.drawRoundRect(0,0,wide,high,16,16);
         g.endFill();
         this.pill.x = param1.x + Math.max(this.margin,param1.width * 0.34);
         this.pill.y = param1.y + 6;
      }
      
      private function recolorTree(param1:DisplayObjectContainer, param2:int):void
      {
         if(param1 == null || param2 > 8) { return; }
         var i:int = 0;
         while(i < param1.numChildren)
         {
            var child:DisplayObject = param1.getChildAt(i);
            var cname:String = child.name == null ? "" : String(child.name);
            if(this.isOurNode(cname))
            {
               i++;
               continue;
            }
            if(child is TextField)
            {
               this.recolorField(child as TextField);
            }
            else if(child is DisplayObjectContainer)
            {
               this.recolorTree(child as DisplayObjectContainer,param2 + 1);
            }
            i++;
         }
      }
      
      private function recolorField(param1:TextField):void
      {
         var rgb:int = param1.textColor;
         var style:int = this.styleColor(rgb,param1.name == null ? "" : String(param1.name));
         if(style == rgb) { return; }
         var fmt:TextFormat = param1.defaultTextFormat;
         if(fmt == null) { fmt = new TextFormat(); }
         fmt.color = style;
         param1.defaultTextFormat = fmt;
         param1.textColor = style;
         param1.setTextFormat(fmt);
      }
      
      private function styleColor(param1:int, param2:String):int
      {
         if(this.luma(param1) < 90) { return param1; }
         if(this.foldHas(param2,"header") || this.foldHas(param2,"title") || this.foldHas(param2,"categor") || this.foldHas(param2,"label") || this.foldHas(param2,"tab"))
         {
            return 0xE8C547;
         }
         return 0xF4F0E4;
      }
      
      private function luma(param1:int):int
      {
         var r:int = (param1 >> 16) & 255;
         var g:int = (param1 >> 8) & 255;
         var b:int = param1 & 255;
         return int((r * 3 + g * 6 + b) / 10);
      }
      
      // The Selected Module card reads ModuleInfo only. The game card stays where the menu
      // put it, at alpha 0, so the menu keeps filling, sizing, and showing it.
      private function listenModule():void
      {
         try
         {
            BSUIDataManager.Subscribe("ModuleInfo",this.onModuleInfo);
            this.note("MODCARD listen ok");
         }
         catch(err:Error)
         {
            this.note("MODCARD listen miss");
         }
      }
      
      private function onModuleInfo(param1:Object):void
      {
         var data:Object = null;
         try { data = param1.data; } catch(err:Error) { data = null; }
         if(data == null)
         {
            try { data = param1.target.data; } catch(err2:Error) { data = null; }
         }
         if(data == null) { return; }
         this.modData = data;
         this.modFailed = false;
         var was:Boolean = this.modOn;
         this.syncModule();
         if(was && this.modOn && this.paintSafe()) { this.seatModule(this.modNative); }
      }
      
      private function syncModule():void
      {
         var clip:DisplayObject = this.clipByName("Module");
         if(this.modOn && clip != this.modNative) { this.dropModule(); }
         var why:String = this.moduleGate(clip);
         if(why == "on")
         {
            if(!this.modOn) { this.holdModule(clip); }
            if(this.modOn) { this.seatModule(this.modNative); }
            else { why = "paint"; }
         }
         else if(this.modOn) { this.dropModule(); }
         var said:String = why == "on" ? why + this.modFacts : why;
         if(said != this.modWhy)
         {
            this.modWhy = said;
            this.note("MODCARD " + said);
         }
         if(why == "on" && this.modValsKey != this.modValsSaid && this.modValsLeft > 0)
         {
            this.modValsSaid = this.modValsKey;
            this.modValsLeft--;
            var v:int = 0;
            while(v < this.modVals.length)
            {
               this.note("MODVALS " + this.modVals[v]);
               v++;
            }
         }
      }
      
      // The first failing check names the state in the log.
      private function moduleGate(param1:DisplayObject):String
      {
         if(this.face.length == 0) { return "face"; }
         if(this.conflict) { return "conflict"; }
         if(!this.mapped) { return "map"; }
         if(param1 == null || param1.parent == null) { return "clip"; }
         var data:Object = this.modData;
         if(data == null || data.sModuleName == null || String(data.sModuleName).length == 0) { return "data"; }
         if(this.modFailed) { return "paint"; }
         if(!Boolean(data.bShowWidget) || !this.chainShown(param1)) { return "hidden"; }
         if(this.hangarShown()) { return "hangar"; }
         if(this.arranging && !this.modOn) { return "arrange"; }
         return "on";
      }
      
      private function chainShown(param1:DisplayObject):Boolean
      {
         var node:DisplayObject = param1;
         var guard:int = 0;
         while(node != null && guard < 12)
         {
            if(!node.visible) { return false; }
            node = node.parent;
            guard++;
         }
         return param1.stage != null;
      }
      
      private function hangarShown():Boolean
      {
         var hangar:DisplayObject = null;
         try { hangar = this.host["HangarInfoPanel_mc"] as DisplayObject; } catch(err:Error) { hangar = null; }
         return hangar != null && hangar.visible;
      }
      
      // Our card is painted before the game card is touched, so a bad payload leaves it alone.
      private function holdModule(param1:DisplayObject):void
      {
         if(!this.paintSafe()) { return; }
         this.modNative = param1;
         this.modAlpha = param1.alpha > 0 ? param1.alpha : 1;
         param1.alpha = 0;
         this.modOn = true;
         this.removeFrame("HsbFrameModule");
         this.removeHeading("Module");
      }
      
      private function dropModule():void
      {
         if(this.modNative != null) { this.modNative.alpha = this.modAlpha; }
         this.modNative = null;
         this.modOn = false;
         if(this.modCard != null) { this.modCard.visible = false; }
      }
      
      // A throw keeps the game card up until the next payload.
      private function paintSafe():Boolean
      {
         try
         {
            if(this.modCard == null) { this.buildModule(); }
            this.paintModule();
            return true;
         }
         catch(err:Error)
         {
         }
         this.modFailed = true;
         this.dropModule();
         return false;
      }
      
      // Right above the game card in its own parent, so menu popups still draw over it.
      private function seatModule(param1:DisplayObject):void
      {
         if(this.modCard == null || param1 == null || param1 != this.modNative) { return; }
         var parent:DisplayObjectContainer = param1.parent;
         if(parent == null) { return; }
         var at:int = parent.getChildIndex(param1);
         if(this.modCard.parent != parent) { parent.addChildAt(this.modCard,at + 1); }
         else
         {
            var mine:int = parent.getChildIndex(this.modCard);
            if(mine != at + 1) { parent.setChildIndex(this.modCard,mine > at ? at + 1 : at); }
         }
         var box:Rectangle = param1.getBounds(parent);
         var y:Number = this.arranging ? box.y : this.liftModule(parent,box.y,this.modHigh);
         this.modCard.x = Math.round(box.x);
         this.modCard.y = Math.round(y);
         this.modCard.visible = true;
         if(param1.alpha != 0) { param1.alpha = 0; }
      }
      
      // Outside Arrange a card taller than the room under the game card is lifted to stay on
      // screen. Arrange seats it exactly, so a drag and a saved spot use the game card's top.
      private function liftModule(param1:DisplayObjectContainer, param2:Number, param3:Number):Number
      {
         var r:Object = this.modView;
         if(r == null) { return param2; }
         if(r != this.liftView || param1 != this.liftParent)
         {
            this.liftView = r;
            this.liftParent = param1;
            this.liftTop = param1.globalToLocal(this.localToGlobal(new Point(r.x,r.y))).y;
            this.liftLow = param1.globalToLocal(this.localToGlobal(new Point(r.x,r.y + r.height))).y;
         }
         if(param2 + param3 <= this.liftLow) { return param2; }
         return Math.max(this.liftTop,this.liftLow - param3);
      }
      
      private function cardW():Number
      {
         return this.lrg ? 410 : 350;
      }
      
      private function cardPad():Number
      {
         return this.lrg ? 20 : 18;
      }
      
      private function buildModule():void
      {
         var head:int = this.lrg ? 16 : 13;
         var body:int = this.lrg ? 16 : 14;
         var big:int = this.lrg ? 30 : 26;
         this.modCard = new Sprite();
         this.modCard.name = "HsbModuleCard";
         this.modCard.mouseEnabled = false;
         this.modCard.mouseChildren = false;
         this.modCard.visible = false;
         this.modLines = new Shape();
         this.modCard.addChild(this.modLines);
         this.modHead = this.cardText(head,false);
         this.spaceOut(this.modHead,2);
         this.modName = this.cardText(this.lrg ? 24 : 21,true);
         this.modDesc = this.cardText(body,true);
         this.modValueL = this.cardText(head,false);
         this.modMassL = this.cardText(head,false);
         this.modValue = this.cardText(big,false);
         this.modMass = this.cardText(big,false);
      }
      
      private function cardText(param1:int, param2:Boolean):TextField
      {
         var field:TextField = this.makeText("",0,0,200,param1 + 10,param1,0xFFFFFF);
         if(param2)
         {
            field.multiline = true;
            field.wordWrap = true;
         }
         this.modCard.addChild(field);
         return field;
      }
      
      private function spaceOut(param1:TextField, param2:Number):void
      {
         var fmt:TextFormat = param1.defaultTextFormat;
         fmt.letterSpacing = param2;
         param1.defaultTextFormat = fmt;
         param1.setTextFormat(fmt);
      }
      
      private function alignRight(param1:TextField):void
      {
         var fmt:TextFormat = param1.defaultTextFormat;
         fmt.align = "right";
         param1.defaultTextFormat = fmt;
         param1.setTextFormat(fmt);
      }
      
      // A $ key is translated when the field takes it, as on the game card.
      private function put(param1:TextField, param2:Object, param3:uint):void
      {
         var fmt:TextFormat = param1.defaultTextFormat;
         fmt.color = param3;
         param1.defaultTextFormat = fmt;
         param1.text = param2 == null ? "" : String(param2);
         param1.setTextFormat(fmt);
      }
      
      // The game's own label key, upper-cased once translated. A kept key shows the English
      // word and counts toward keys= in the log.
      private function putKey(param1:TextField, param2:String, param3:String, param4:uint):int
      {
         this.put(param1,param2,param4);
         if(param1.text.charAt(0) == "$")
         {
            this.put(param1,param3,param4);
            return 1;
         }
         param1.text = param1.text.toUpperCase();
         return 0;
      }
      
      private function moduleRow(param1:int):Object
      {
         var body:int = this.lrg ? 16 : 14;
         var small:int = this.lrg ? 16 : 13;
         while(this.modRows.length <= param1)
         {
            var label:TextField = this.cardText(body,true);
            var value:TextField = this.cardText(body,false);
            this.alignRight(value);
            var chip:Sprite = new Sprite();
            chip.mouseEnabled = false;
            chip.mouseChildren = false;
            var tag:TextField = this.makeText("",0,0,96,small + 8,small,0xFFFFFF);
            chip.addChild(tag);
            this.modCard.addChild(chip);
            this.modRows.push({"label":label,"value":value,"chip":chip,"tag":tag});
         }
         return this.modRows[param1];
      }
      
      private function moduleSkill(param1:int):Object
      {
         var body:int = this.lrg ? 16 : 14;
         while(this.modSkills.length <= param1)
         {
            var skill:TextField = this.cardText(body,false);
            var rank:TextField = this.cardText(body,false);
            this.alignRight(rank);
            this.modSkills.push({"skill":skill,"rank":rank});
         }
         return this.modSkills[param1];
      }
      
      // Unused rows sit at the card's corner, so they never widen its bounds.
      private function park(param1:DisplayObject):void
      {
         param1.visible = false;
         param1.x = 0;
         param1.y = 0;
      }
      
      // ModuleInfoCard.UpdateValues formats each stat this way.
      private function statText(param1:Object):String
      {
         if(String(param1.text) == "$CLASS") { return String.fromCharCode(param1.fValue); }
         if(param1.bPercentage) { return GlobalFunc.FormatNumberToString(Number(param1.fValue) * 100) + "%"; }
         return GlobalFunc.FormatNumberToString(Number(param1.fValue),2);
      }
      
      // The game marks a change by frame only, so the chip is new text. A diff too small to
      // show at the value's places gets no chip.
      private function diffText(param1:Object):String
      {
         var diff:Number = Number(param1.fDiff);
         if(!(diff > 0) && !(diff < 0)) { return ""; }
         var sign:String = diff > 0 ? "+" : "-";
         if(String(param1.text) == "$CLASS") { return sign; }
         var size:String = param1.bPercentage ? this.chipNumber(Math.abs(diff) * 100,0) : this.chipNumber(Math.abs(diff),2);
         if(size == "0") { return ""; }
         return sign + size + (param1.bPercentage ? "%" : "");
      }
      
      // A chip too wide for its room drops its places, as a cut would. A whole part of 0 would
      // read as no change, so that chip keeps its sign alone.
      private function shortChip(param1:String):String
      {
         var dot:int = param1.indexOf(".");
         if(dot < 0 || param1.indexOf("e") >= 0) { return param1.charAt(0); }
         var whole:String = param1.substring(0,dot);
         return whole.length == 2 && whole.charAt(1) == "0" ? param1.charAt(0) : whole;
      }
      
      // FormatNumberToString cuts the text of toString, which turns float noise such as
      // 1.2e-7 into "1.2". toFixed never writes an exponent below 1e21.
      private function chipNumber(param1:Number, param2:int):String
      {
         var text:String = param1.toFixed(6);
         var dot:int = text.indexOf(".");
         if(dot < 0 || text.indexOf("e") >= 0) { return text; }
         text = param2 > 0 ? text.substring(0,dot + 1 + param2) : text.substring(0,dot);
         if(text.indexOf(".") >= 0)
         {
            while(text.charAt(text.length - 1) == "0") { text = text.substring(0,text.length - 1); }
            if(text.charAt(text.length - 1) == ".") { text = text.substring(0,text.length - 1); }
         }
         return text;
      }
      
      private function moduleNumber(param1:*):String
      {
         if(param1 == null) { return ""; }
         return GlobalFunc.FormatNumberToString(Number(param1));
      }
      
      private function rule(param1:*, param2:Number):void
      {
         var inset:Number = this.lrg ? 18 : 16;
         param1.beginFill(0x1D2328,1);
         param1.drawRect(inset,param2,this.cardW() - inset * 2,1);
         param1.endFill();
      }
      
      private function paintModule():void
      {
         var data:Object = this.modData;
         if(data == null || this.modCard == null) { return; }
         var w:Number = this.cardW();
         var pad:Number = this.cardPad();
         var pitch:Number = this.lrg ? 34 : 30;
         var barH:Number = this.lrg ? 28 : 24;
         var big:Number = this.lrg ? 30 : 26;
         var right:Number = w - pad - (this.lrg ? 80 : 67);
         var valueW:Number = this.lrg ? 100 : 90;
         var inner:Number = w - pad * 2;
         var c:uint = this.accentColor();
         this.modTint = c;
         var ink:* = this.modLines.graphics;
         ink.clear();
         var kept:int = 0;
         this.put(this.modHead,"SELECTED MODULE",c);
         this.modHead.x = pad;
         this.modHead.y = pad - 4;
         this.modHead.width = inner;
         var y:Number = this.modHead.y + this.modHead.height + 3;
         this.put(this.modName,data.sModuleName,0xFFFFFF);
         this.modName.x = pad + 13;
         this.modName.y = y;
         this.modName.width = inner - 13;
         this.modName.height = this.modName.textHeight + 6;
         ink.beginFill(c,1);
         ink.drawRect(pad + 1,y + 3,3,barH);
         ink.endFill();
         y += Math.max(this.modName.height,barH + 6) + 10;
         this.rule(ink,y);
         y += 6;
         var stats:Array = data.aStats as Array;
         var count:int = stats == null ? 0 : Math.min(stats.length,10);
         var vals:Array = [];
         var i:int = 0;
         while(i < count)
         {
            var stat:Object = stats[i];
            var row:Object = this.moduleRow(i);
            var label:TextField = row.label as TextField;
            var value:TextField = row.value as TextField;
            var shown:String = this.statText(stat);
            this.put(label,stat.text,0xC3D1D8);
            if(label.text.charAt(0) == "$") { kept++; }
            else { label.text = label.text.toUpperCase(); }
            label.x = pad;
            label.width = right - valueW - pad - 4;
            label.height = label.textHeight + 6;
            var rowH:Number = Math.max(pitch,label.height + 6);
            label.y = y + (rowH - label.height) / 2;
            label.visible = true;
            this.put(value,shown,0xFFFFFF);
            value.x = right - valueW;
            value.width = valueW;
            value.y = y + (rowH - value.height) / 2;
            value.visible = true;
            var chip:String = this.paintChip(row,stat,ink,y,rowH);
            vals.push("s" + (i + 1) + "=" + String(stat.fValue) + "/" + String(stat.fDiff) + "/" + (stat.bPercentage ? 1 : 0) + ">" + shown + (chip.length > 0 ? "/" + chip : ""));
            y += rowH;
            i++;
         }
         while(i < this.modRows.length)
         {
            this.park(this.modRows[i].label as TextField);
            this.park(this.modRows[i].value as TextField);
            (this.modRows[i].chip as Sprite).graphics.clear();
            this.park(this.modRows[i].chip as Sprite);
            i++;
         }
         if(count > 0)
         {
            y += 10;
            this.rule(ink,y);
         }
         y += 16;
         this.put(this.modDesc,data.sDescription,0xCDDCE3);
         this.modDesc.x = pad;
         this.modDesc.y = y;
         this.modDesc.width = inner;
         this.modDesc.height = this.modDesc.textHeight + 6;
         y += Math.max(this.modDesc.height,this.lrg ? 62 : 54) + 12;
         this.rule(ink,y);
         y += 14;
         var skills:Array = data.aRequiredAttributes as Array;
         var need:int = skills == null ? 0 : Math.min(skills.length,2);
         var s:int = 0;
         while(s < need)
         {
            if(this.paintSkill(this.moduleSkill(s),skills[s],y)) { kept++; }
            y += pitch;
            s++;
         }
         while(s < this.modSkills.length)
         {
            this.park(this.modSkills[s].skill as TextField);
            this.park(this.modSkills[s].rank as TextField);
            s++;
         }
         if(need > 0)
         {
            y += 8;
            this.rule(ink,y);
            y += 14;
         }
         var half:Number = w / 2 + 14;
         kept += this.putKey(this.modValueL,"$VALUE","VALUE",0xA4A994);
         kept += this.putKey(this.modMassL,"$MASS","MASS",0xA4A994);
         this.modValueL.x = pad;
         this.modMassL.x = half;
         this.modValueL.y = y;
         this.modMassL.y = y;
         this.modValueL.width = half - pad - 8;
         this.modMassL.width = w - pad - half;
         y += this.modValueL.height + 2;
         this.put(this.modValue,this.moduleNumber(data.iModuleCost),0xFFFFFF);
         this.put(this.modMass,this.moduleNumber(data.iModuleMass),0xFFFFFF);
         this.modValue.x = pad;
         this.modMass.x = half;
         this.modValue.y = y;
         this.modMass.y = y;
         this.modValue.width = half - pad - 8;
         this.modMass.width = w - pad - half;
         y += big + 14 + pad;
         var g:* = this.modCard.graphics;
         g.clear();
         g.beginFill(0x2A323A,1);
         g.drawRoundRect(0,0,w,y,14,14);
         g.endFill();
         g.beginFill(0x0E141A,1);
         g.drawRoundRect(1,1,w - 2,y - 2,12,12);
         g.endFill();
         this.modHigh = y;
         this.modFacts = " rows=" + count + " skills=" + need + " keys=" + kept + " inb=" + (Boolean(data.bInBuilderMode) ? 1 : 0) + " w=" + w;
         var head:String = "cost=" + String(data.iModuleCost) + ">" + this.modValue.text + " mass=" + String(data.iModuleMass) + ">" + this.modMass.text;
         this.modVals = [head + (vals.length > 0 ? " " + vals.slice(0,5).join(" ") : "")];
         if(vals.length > 5) { this.modVals.push(vals.slice(5).join(" ")); }
         this.modValsKey = this.modVals.join(" ");
      }
      
      // Higher is green and lower is red, as the game's HigherValue and LowerValue frames.
      private function paintChip(param1:Object, param2:Object, param3:*, param4:Number, param5:Number):String
      {
         var w:Number = this.cardW();
         var pad:Number = this.cardPad();
         var chipH:Number = this.lrg ? 26 : 22;
         var chip:Sprite = param1.chip as Sprite;
         var tag:TextField = param1.tag as TextField;
         var text:String = this.diffText(param2);
         chip.graphics.clear();
         if(text.length == 0)
         {
            this.park(chip);
            param3.beginFill(0x5E6359,1);
            param3.drawRect(w - pad - 14,param4 + param5 / 2,12,1.5);
            param3.endFill();
            return "";
         }
         var up:Boolean = Number(param2.fDiff) > 0;
         var room:Number = (this.lrg ? 80 : 67) - 8;
         this.put(tag,text,up ? 0x69FEB3 : 0xFF6868);
         if(tag.textWidth + 14 > room)
         {
            text = this.shortChip(text);
            this.put(tag,text,up ? 0x69FEB3 : 0xFF6868);
         }
         if(tag.textWidth + 14 > room)
         {
            text = text.charAt(0);
            this.put(tag,text,up ? 0x69FEB3 : 0xFF6868);
         }
         var chipW:Number = Math.min(Math.max(28,tag.textWidth + 14),room);
         tag.width = Math.min(tag.textWidth + 6,chipW - 4);
         tag.x = Math.max(2,(chipW - tag.textWidth) / 2 - 2);
         tag.y = (chipH - tag.height) / 2;
         chip.graphics.beginFill(up ? 0x1A302E : 0x301E24,1);
         chip.graphics.drawRoundRect(0,0,chipW,chipH,8,8);
         chip.graphics.endFill();
         chip.x = w - pad - 2 - chipW;
         chip.y = param4 + (param5 - chipH) / 2;
         chip.visible = true;
         return text;
      }
      
      // ModuleAttributeIcon writes the rank with "$(Rank #)" and DoSubstitutions.
      // Returns true when a field kept its $ key, so the log can say translation did not run.
      private function paintSkill(param1:Object, param2:Object, param3:Number):Boolean
      {
         var w:Number = this.cardW();
         var pad:Number = this.cardPad();
         var pitch:Number = this.lrg ? 34 : 30;
         var has:Boolean = Boolean(param2.bHasSkill);
         var skill:TextField = param1.skill as TextField;
         var rank:TextField = param1.rank as TextField;
         this.put(skill,param2.sName,has ? 0xF4F0E4 : 0xFF6868);
         this.put(rank,"$(Rank #)",has ? 0xA4A994 : 0xFF6868);
         var keyed:Boolean = rank.text.charAt(0) == "$" || skill.text.charAt(0) == "$";
         rank.text = GlobalFunc.DoSubstitutions(rank.text,[param2.uRank]);
         skill.x = pad;
         skill.width = w - pad * 2 - 112;
         rank.x = w - pad - 110;
         rank.width = 110;
         skill.y = param3 + (pitch - skill.height) / 2;
         rank.y = skill.y;
         skill.visible = true;
         rank.visible = true;
         return keyed;
      }
      
      // Without a proven face this stays the earlier device-text path.
      private function textFormat(param1:int, param2:uint):TextFormat
      {
         var floor:int = this.lrg ? 16 : 13;
         var fmt:TextFormat = new TextFormat();
         if(this.face.length > 0) { fmt.font = this.face; }
         fmt.size = param1 < floor ? floor : param1;
         fmt.color = param2;
         return fmt;
      }
      
      private function makeText(param1:String, param2:Number, param3:Number, param4:Number, param5:Number, param6:int, param7:uint):TextField
      {
         var box:TextField = new TextField();
         var fmt:TextFormat = this.textFormat(param6,param7);
         box.embedFonts = this.faceEmbed;
         box.defaultTextFormat = fmt;
         box.mouseEnabled = false;
         box.selectable = false;
         box.x = param2;
         box.y = param3;
         box.width = param4;
         box.height = param5;
         box.text = param1;
         box.setTextFormat(fmt);
         this.texts.push(box);
         return box;
      }
      
      private function makeButton(param1:String, param2:Number, param3:Number, param4:Number, param5:Number, param6:Boolean):Sprite
      {
         var button:Sprite = new Sprite();
         var g:* = button.graphics;
         g.lineStyle(1,param6 ? this.accentColor() : 0x5A6A76,1);
         g.beginFill(param6 ? this.accentColor() : 0x26343F,param6 ? 0.95 : 0.9);
         g.drawRoundRect(0,0,param4,param5,10,10);
         g.endFill();
         button.x = param2;
         button.y = param3;
         button.buttonMode = true;
         var label:TextField = this.makeText(param1,8,6,param4 - 12,param5 - 4,this.bodyPx,param6 ? 0x1A1404 : 0xF4F0E4);
         button.addChild(label);
         return button;
      }
      
      private function pushState():void
      {
         var w:int = stage != null ? stage.stageWidth : 0;
         var h:int = stage != null ? stage.stageHeight : 0;
         var capture:int = (this.arranging || this.setOpen) ? 1 : 0;
         this.lines.push("STATE capture=" + capture + " arrange=" + (this.arranging ? 1 : 0) + " stage=" + w + "x" + h + " keys=" + (this.keysOn ? 1 : 0));
      }
      
      private function note(param1:String):void
      {
         var clean:String = param1.split("\n").join(" ").split("\r").join(" ");
         this.lines.push(clean);
         while(this.lines.length > 200) { this.lines.shift(); }
      }
   }
}
