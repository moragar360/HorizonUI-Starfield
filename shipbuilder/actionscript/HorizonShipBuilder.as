package
{
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
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
      private var useEmbed:Boolean;
      private var faceFmt:TextFormat;
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
         this.useEmbed = false;
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
         this.mouseEnabled = false;
         this.mouseChildren = true;
         addEventListener(Event.ADDED_TO_STAGE,this.onStage);
      }
      
      public function ping():String
      {
         return "0.1.0.0";
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
      
      public function wantsEvent(param1:String, param2:Boolean):Boolean
      {
         if(!this.arranging && !this.setOpen) { return false; }
         if(!param2) { return this.arranging || this.setOpen; }
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
         this.faceFmt = this.copyFormat();
         this.buildCards();
         this.buildGear();
         stage.addEventListener(Event.ENTER_FRAME,this.onFrame);
         this.note("BUILDER 0.1.0.0 gold lrg=" + (this.lrg ? 1 : 0));
      }
      
      private function onFrame(param1:Event):void
      {
         this.frameN++;
         if(this.frameN < 3 || this.arranging || this.conflict) { return; }
         if(!this.mapped || (this.frameN % 8) == 0) { this.syncPanels(); }
      }
      
      private function copyFormat():TextFormat
      {
         var fmt:TextFormat = new TextFormat();
         fmt.size = this.bodyPx;
         fmt.color = 0xF4F0E4;
         this.useEmbed = false;
         var sample:TextField = this.findLatinField(this.host as DisplayObjectContainer,0);
         var face:String = this.latinFace(sample);
         if(face.length > 0) { fmt.font = face; }
         return fmt;
      }
      
      private function latinFace(param1:TextField):String
      {
         if(param1 == null || param1.embedFonts) { return ""; }
         if(!this.hasLatin(param1.text)) { return ""; }
         var src:TextFormat = param1.getTextFormat();
         if(src == null || src.font == null || String(src.font).length == 0) { src = param1.defaultTextFormat; }
         if(src == null || src.font == null) { return ""; }
         return String(src.font);
      }
      
      private function findLatinField(param1:DisplayObjectContainer, param2:int):TextField
      {
         if(param1 == null || param2 > 6) { return null; }
         var i:int = 0;
         while(i < param1.numChildren)
         {
            var child:DisplayObject = param1.getChildAt(i);
            if(child != this && child is TextField && this.latinFace(child as TextField).length > 0) { return child as TextField; }
            if(child != this && child is DisplayObjectContainer)
            {
               var hit:TextField = this.findLatinField(child as DisplayObjectContainer,param2 + 1);
               if(hit != null) { return hit; }
            }
            i++;
         }
         return null;
      }
      
      private function hasLatin(param1:String):Boolean
      {
         if(param1 == null) { return false; }
         var letters:int = 0;
         var i:int = 0;
         while(i < param1.length)
         {
            var c:int = param1.charCodeAt(i);
            if((c >= 65 && c <= 90) || (c >= 97 && c <= 122))
            {
               letters++;
               if(letters >= 4) { return true; }
            }
            i++;
         }
         return false;
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
         hide.mouseEnabled = false;
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
         this.strokeHangar();
         if(!this.mapped) { this.note("MAP " + report); }
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
         this.titleT.x = r.x + this.margin + 200;
         this.titleT.y = r.y + 10;
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
         this.hexBox.embedFonts = false;
         this.hexBox.defaultTextFormat = this.faceFmt;
         this.hexBox.type = TextFieldType.INPUT;
         this.hexBox.border = true;
         this.hexBox.borderColor = this.accentColor();
         this.hexBox.background = true;
         this.hexBox.backgroundColor = 0x1C1A16;
         this.hexBox.textColor = 0xF4F0E4;
         this.hexBox.width = 140;
         this.hexBox.height = 26;
         this.hexBox.x = x0 + 24;
         this.hexBox.y = y0 + 180;
         this.hexBox.text = this.accentHex.length == 6 ? this.accentHex : "E8C547";
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
      
      private function closeSettings():void
      {
         this.setOpen = false;
         if(this.setLayer != null) { this.setLayer.visible = false; }
         if(stage != null && this.hexBox != null && stage.focus == this.hexBox) { stage.focus = null; }
      }
      
      private function openArrange():void
      {
         if(this.conflict || this.arranging) { return; }
         this.closeSettings();
         this.arranging = true;
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
         var x:Number = r.x + Math.round((param2 - r.x) / 10) * 10;
         var y:Number = r.y + Math.round((param3 - r.y) / 10) * 10;
         x = this.clamp(x,r.x,r.x + r.width - live.width);
         y = this.clamp(y,r.y,r.y + r.height - live.height);
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
         }
         var spot:Object = {"x":x,"y":y,"w":live.width,"h":live.height};
         this.storeAnchor(param1,x,y,spot,r);
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
      
      private function makeText(param1:String, param2:Number, param3:Number, param4:Number, param5:Number, param6:int, param7:uint):TextField
      {
         var box:TextField = new TextField();
         var fmt:TextFormat = new TextFormat();
         if(this.faceFmt != null && this.faceFmt.font != null) { fmt.font = this.faceFmt.font; }
         fmt.size = param6 < 13 ? 13 : param6;
         fmt.color = param7;
         box.embedFonts = false;
         box.defaultTextFormat = fmt;
         box.mouseEnabled = false;
         box.selectable = false;
         box.x = param2;
         box.y = param3;
         box.width = param4;
         box.height = param5;
         box.text = param1;
         box.setTextFormat(fmt);
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
