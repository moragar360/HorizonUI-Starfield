package
{
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Events.CustomEvent;
   import Shared.GlobalFunc;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.InteractiveObject;
   import flash.display.Graphics;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.EventDispatcher;
   import flash.events.MouseEvent;
   import flash.geom.Point;
   import flash.text.TextField;
   import flash.text.TextFieldType;
   import flash.text.TextFormat;
   import flash.utils.getDefinitionByName;

   // Purpose: Horizon Ship Builder 0.2. Draws the whole builder interface from the approved gold
   //    mockups and drives the game's own builder underneath it. The vanilla panels stay alive at
   //    alpha 0 so their data, focus, controller routing and engine events keep working.
   // Inputs: the vanilla menu object (host); game data feeds through BSUIDataManager; pointer,
   //    wheel, key and character tokens fed by HorizonShipBuilder.dll (feed); settings from the
   //    DLL (apply); file replies (files); controller events through wantsEvent.
   // Outputs: game events (BSUIDataManager.dispatchEvent); log, state, hot-rectangle and
   //    setting lines for the DLL (takeLines); file requests (takeFiles).
   // Dependencies: the vanilla SpaceshipEditorMenu document class (spliced, see
   //    document_splice.as), HsbKit, HsbBox, HsbBrowser, HsbSettings, HsbPillModel, HsbPillEditor,
   //    HsbPillImport, HsbDialog, HsbColors, HsbFlight, HsbArrange, HsbJson,
   //    HorizonShipBuilderProbe (debug only).
   // Why the pointer comes from the DLL: in-game logs (p5) showed presses over the ship view go
   //    to the editor before Scaleform, so Scaleform CLICK never fired on Horizon controls. The
   //    DLL feeds every pointer event and swallows the ones over the rectangles we publish.
   // Author: Moragar. Last modified: 2026-11-08.
   public class HorizonShipBuilder extends Sprite
   {
      internal static const VERSION:String = "0.2.0.0";
      internal static const ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      internal static const PANELS:Array = ["Power","Module","Credits","Browser","Stats","Hints","Cluster"];
      // Mapped names go through the game's font library. The log names a candidate by index only.
      private static const FACES:Array = ["$NB_Grotesk_Semibold","$MAIN_Font_Bold","$MAIN_Font"];
      private static const NO_FACE:String = "$Horizon_NoSuchFace_x";
      // Vanilla clips each Horizon panel stands in for.
      private static const COVERS:Object = {
         "Power":["PowerAllocation_mc","ReactorStats_mc","EquipmentStat_mc"],
         "Module":["ModuleInfoCard_mc"],
         "Credits":["CostSummary_mc"],
         "Browser":["ModulePalette_mc"],
         "Stats":["ShipStatsFooter_mc","StatFooterBar_mc"],
         "Hints":["ButtonBar_mc"],
         "Colors":["ColorPicker_mc"],
         "Flight":["FlightCheck_mc"]
      };
      private static const LOG_CAP:int = 200;
      // A cancel or accept can arrive both as a DLL key token and as the game's own event.
      private static const DOUBLE_FRAMES:int = 6;
      private static const FILE_QUEUE_MAX:int = 64;
      // The stats and hints bars' heights before HsbKit.u, and the gap place() leaves between
      // them (mockup 1: 96, 43 and 11 px). HsbBrowser.fitHeight reads them to end the browser
      // 10 px above the hints, as the mockup does (883 and 893).
      internal static const STATS_HEIGHT:Number = 96;
      internal static const HINTS_HEIGHT:Number = 43;
      internal static const BAR_GAP:Number = 11;
      // Panels with a collapsed tab. Hide all folds these to their tabs (mockup 12); Colors and
      // Flight Check have no tab, so Hide all removes them.
      private static const TABBED:Object = {"Power":true,"Module":true,"Credits":true,"Stats":true,"Hints":true,"Browser":true};

      private var host:Object;
      internal var kit:HsbKit;
      private var lines:Array;
      private var fileOut:Array;
      private var fileWait:Object;
      private var fileSeq:int;
      private var probe:HorizonShipBuilderProbe;
      private var frameN:int;
      private var faceTries:int;
      private var facePick:String;
      private var debugOn:Boolean;

      internal var accent:int = 9;
      internal var accentHex:String = "";
      internal var follow:Boolean = false;
      internal var coreFound:Boolean = false;
      internal var coreAccent:int = -1;
      internal var coreHex:String = "";
      internal var opacity:Number = 1;
      internal var margin:int = 34;
      internal var uiScale:Number = 1;
      internal var density:String = "compact";
      internal var byMaker:Boolean = false;
      // Why pill changes cannot be saved this session ("" when they can); see onProfile.
      internal var pillsLock:String = "loading";
      // The plugin answered the latest pill save with a failure (no backup copy, or the file
      // could not be written). Saving stays open: every save writes every pill, so the next
      // change tries again and a save that succeeds clears this.
      private var pillsSaveFailed:Boolean = false;
      // Counts pill saves. Only the latest one's reply sets or clears pillsSaveFailed: with its
      // queue full the plugin refuses a request at once, ahead of older ones still queued.
      private var pillsSaveSeq:int = 0;
      // A save was refused while the profile was loading or the damaged profile was being set
      // aside; it runs once saving opens on the pills on screen.
      private var pillsWaiting:Boolean = false;
      // A profile loaded over pill changes made while it was loading, so they were not kept.
      private var pillsDropped:Boolean = false;
      // The damaged profile was set aside this visit, so the starter pills are shown.
      private var pillsSetAside:Boolean = false;
      // The profile was empty or blank (only spaces, tabs and line ends), so the starter pills
      // are shown.
      private var pillsEmpty:Boolean = false;
      // This visit started without a loaded profile (none, an empty one, or one set aside), so
      // the plugin keeps ShipBuilderPills.bak as it was: it may hold an older list than the last
      // save.
      internal var pillsBakKept:Boolean = false;
      internal var rememberLayout:Boolean = true;
      internal var startOpen:Object;
      internal var autoFlight:Boolean = true;
      internal var columnSets:Object;
      internal var keyHide:String = "H";
      internal var keyFind:String = "/";
      internal var keyArrange:String = "L";
      internal var showConflict:Boolean = true;
      internal var conflict:Boolean = false;
      internal var starFiles:Boolean = false;
      internal var lay:Object;
      internal var barDx:Number = 0;
      internal var barDy:Number = 0;
      private var applied:Boolean;
      private var saveNote:String = "";

      internal var collapsed:Object;
      internal var hideAll:Boolean = false;
      private var bannerGone:Boolean = false;
      private var stoodDown:Boolean = false;

      internal var dPower:Object;
      internal var dStats:Object;
      internal var dCost:Object;
      internal var dModule:Object;
      internal var dVariant:Object;
      internal var dHelp:Array;
      internal var dControls:Array;
      internal var padUi:uint = 0;
      internal var dFlight:Object;
      internal var dColorInit:Object;
      internal var dColorSel:Object;
      internal var dStatic:Object;
      internal var dHangar:Object;

      private var power:HsbBox;
      private var card:HsbBox;
      private var cluster:HsbBox;
      private var credits:HsbBox;
      private var stats:HsbBox;
      private var hints:HsbBox;
      private var notice:HsbBox;
      internal var browser:HsbBrowser;
      internal var colors:HsbColors;
      internal var flight:HsbFlight;
      internal var pills:HsbPillModel;
      private var layer:Sprite;
      private var popLayer:Sprite;
      private var pops:Array;
      private var arrange:HsbArrange;

      private var vis:Object;
      private var covered:Object;
      private var dirty:Object;
      private var hot:String = "";
      private var heldEvents:Object;
      private var lastCancel:int = -100;
      private var lastOk:int = -100;
      private var dragBox:HsbBox;
      private var textOwner:HsbBox;
      private var pointerX:Number = -1;
      private var pointerY:Number = -1;
      private var hoverBox:HsbBox;
      private var leaks:int = 0;

      public function HorizonShipBuilder(param1:Object)
      {
         super();
         this.host = param1;
         this.lines = [];
         this.fileOut = [];
         this.fileWait = {};
         this.fileSeq = 0;
         this.frameN = 0;
         this.faceTries = 0;
         this.facePick = "0";
         this.debugOn = false;
         this.startOpen = {"Power":true,"Module":true,"Credits":true,"Browser":true,"Stats":true,"Hints":true};
         this.columnSets = {};
         this.lay = {};
         this.collapsed = {};
         this.vis = {};
         this.covered = {};
         this.dirty = {};
         this.pops = [];
         this.heldEvents = {};
         this.dHelp = [];
         this.dControls = [];
         // Boxes are mouse targets so Scaleform sees Horizon as the topmost entity under the
         // pointer; nothing listens to Scaleform mouse events (the DLL feeds the pointer).
         this.mouseEnabled = false;
         this.mouseChildren = true;
         addEventListener(Event.ADDED_TO_STAGE,this.onStage);
      }

      // Purpose: handshake. The DLL drives this movie only when the reply starts with "0.2".
      // Inputs: none. Outputs: the movie version. Dependencies: none.
      public function ping():String
      {
         return VERSION;
      }

      // Purpose: report the stage size for the DLL's window map log line.
      // Inputs: none. Outputs: "stage=WxH view=x,y,w,h". Dependencies: stage, visibleRect.
      public function stageBox():String
      {
         if(stage == null) { return "stage=0x0"; }
         return "stage=" + stage.stageWidth + "x" + stage.stageHeight + " view=" + this.viewText();
      }

      // Purpose: hand queued lines to the DLL once per frame. The first line is always STATE;
      //    HOT follows when the swallowed rectangles changed.
      // Inputs: none. Outputs: newline-joined lines. Dependencies: the DLL's AdvanceFrame poll.
      public function takeLines():String
      {
         this.pushState();
         var text:String = this.lines.join("\n");
         this.lines = [];
         return text;
      }

      // Purpose: hand queued file requests (pill and scheme files) to the DLL.
      // Inputs: none. Outputs: tab-separated request lines; contents escaped (\\ \n \t).
      // Dependencies: the DLL's file job, which only touches the builder's own folders.
      public function takeFiles():String
      {
         var text:String = this.fileOut.join("\n");
         this.fileOut = [];
         return text;
      }

      // Purpose: receive file replies. Each line is "id<TAB>ok<TAB>payload".
      // Inputs: reply text from the DLL. Outputs: calls the waiting callback.
      // Dependencies: requests queued by fileOp.
      public function files(param1:String):void
      {
         if(param1 == null || param1.length == 0) { return; }
         var rows:Array = param1.split("\n");
         var i:int = 0;
         while(i < rows.length)
         {
            var parts:Array = String(rows[i]).split("\t");
            if(parts.length >= 2)
            {
               var id:String = String(parts[0]);
               var cb:Function = this.fileWait[id] as Function;
               delete this.fileWait[id];
               if(cb != null)
               {
                  try { cb(String(parts[1]) == "1",parts.length > 2 ? unescapeText(String(parts.slice(2).join("\t"))) : ""); }
                  catch(err:Error) { this.note("FILE reply failed " + err.errorID); }
               }
            }
            i++;
         }
      }

      // Purpose: turn on the debug probe (Probe=1 in the user ini).
      // Inputs: 1 to enable. Outputs: none. Dependencies: HorizonShipBuilderProbe.
      public function setDebug(param1:Number):void
      {
         if(int(param1) != 1) { return; }
         this.debugOn = true;
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

      // Purpose: receive settings resolved by the DLL from the user ini. The HUD's two ini files
      //    supply only whether the HUD is installed and its accent (core=, coreaccent=, corehex=).
      // Inputs: key=value lines (see BuildApply in probe.cpp). Unknown keys are kept as layout.
      // Outputs: redraws with the new settings. A line that fails is noted and skipped, so it
      //    never stops the lines after it. Dependencies: none.
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
               try { this.applyKey(line.substring(0,eq),line.substring(eq + 1)); }
               catch(err:Error) { this.note("SETTINGS fault " + err.errorID); }
            }
            i++;
         }
         if(this.accent < 0 || this.accent > 13) { this.accent = 9; }
         if(!this.applied)
         {
            this.applied = true;
            var k:int = 0;
            while(k < PANELS.length)
            {
               var id:String = String(PANELS[k]);
               if(this.startOpen[id] === false) { this.collapsed[id] = true; }
               k++;
            }
            this.note("SETTINGS applied scale=" + this.uiScale + " density=" + this.density + " maker=" + (this.byMaker ? 1 : 0));
         }
         this.restyle();
      }

      // Purpose: receive the DLL's input tokens for this frame.
      // Inputs: lines "M D|U|M x y eaten", "W steps x y eaten", "K token", "C code".
      // Outputs: drives Horizon controls. Dependencies: HOT rectangles published by pushState.
      public function feed(param1:String):void
      {
         if(param1 == null || param1.length == 0) { return; }
         var rows:Array = param1.split("\n");
         var i:int = 0;
         while(i < rows.length)
         {
            try { this.onToken(String(rows[i])); }
            catch(err:Error) { this.note("FEED fault " + err.errorID + " at " + String(rows[i]).substr(0,2)); }
            i++;
         }
      }

      // Purpose: the DLL's reply after it merged SET or ARRANGE lines into the user ini.
      // Inputs: 1 saved, 0 failed. Outputs: a note in the open popup. Dependencies: WriteIniNow.
      public function saved(param1:Number):void
      {
         this.saveNote = int(param1) == 1 ? "" : "Could not save. Changes last until you close the game.";
         if(int(param1) != 1) { this.note("SAVE failed"); }
         var top:HsbBox = this.topPop();
         if(top is HsbSettings) { (top as HsbSettings).setSaveNote(this.saveNote); }
      }

      // Purpose: the front of the vanilla ProcessUserEvent chain. While a Horizon popup, dialog,
      //    text field or Arrange is open, every controller or key event is ours, so Esc inside a
      //    dialog never exits the builder. A release whose press we took stays ours after close.
      // Inputs: the event name and whether it is the press. Outputs: true when consumed.
      // Dependencies: the splice calls this before the vanilla chain.
      public function wantsEvent(param1:String, param2:Boolean):Boolean
      {
         var open:Boolean = this.capturing();
         if(param2)
         {
            this.heldEvents[param1] = open ? this.frameN : -1;
            if(open) { this.padEvent(param1); }
            return open;
         }
         var pressed:int = this.heldEvents[param1] != null ? int(this.heldEvents[param1]) : -1;
         delete this.heldEvents[param1];
         var held:Boolean = pressed >= 0;
         if(!open || !held) { return held || open; }
         // The same key press may also have arrived as a DLL key token (cancelTop/acceptTop
         // stamp the frame), so a release acts only when nothing acted since its press.
         if(param1 == "Escape" || param1 == "Cancel") { if(this.lastCancel < pressed) { this.cancelTop("pad"); } return true; }
         if(param1 == "Accept" || param1 == "Enter") { if(this.lastOk < pressed) { this.acceptTop("pad"); } return true; }
         return true;
      }

      // Purpose: the front of the vanilla OnLeftStickInput chain. While Horizon captures input
      //    the stick must not scroll the hidden palette or Flight Check list behind a popup.
      // Outputs: true when the splice should return before the vanilla body.
      // Dependencies: the splice calls this before the vanilla chain.
      public function wantsStick():Boolean
      {
         return this.capturing();
      }

      private function onStage(param1:Event):void
      {
         removeEventListener(Event.ADDED_TO_STAGE,this.onStage);
         var url:String = "";
         try { url = String(root.loaderInfo.url); } catch(err:Error) { url = ""; }
         this.kit = new HsbKit();
         this.kit.lrg = url.indexOf("_lrg") >= 0;
         this.proveFace();
         this.pills = new HsbPillModel();
         this.build();
         this.listen();
         this.fileOp("PROFILE",["READ"],"",this.onProfile);
         stage.addEventListener(Event.ENTER_FRAME,this.onFrame);
         this.note("BUILDER " + VERSION + " gold lrg=" + (this.kit.lrg ? 1 : 0));
      }

      private function onFrame(param1:Event):void
      {
         this.frameN++;
         if(this.kit.face.length == 0 && this.faceTries < 3 && (this.frameN == 30 || this.frameN == 120))
         {
            this.proveFace();
            if(this.kit.face.length > 0) { this.kit.refreshFaces(); this.restyle(); }
         }
         if(this.frameN < 2) { return; }
         try { this.adapt(); }
         catch(err:Error) { if(this.frameN % 120 == 0) { this.note("ADAPT fault " + err.errorID); } }
      }

      // Candidates in order: mapped names as embedded text, the face of the game's module name
      // field, then mapped names as device text. Box glyphs share one advance, so a face counts
      // only when W and i measure apart and the pair differs from a name that cannot exist.
      private function proveFace():void
      {
         this.faceTries++;
         this.kit.face = "";
         this.kit.boldFace = "";
         this.kit.embed = false;
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
               this.kit.face = String(names[k]);
               this.kit.embed = embed;
            }
            k++;
         }
         // The bold face must render the same way (embedded or device) as the body face.
         if(this.kit.face.length > 0 && this.kit.face != String(FACES[1]))
         {
            var bold:Array = this.measureFace(String(FACES[1]),this.kit.embed);
            if(this.faceProven(bold,this.kit.embed ? none : noneDev)) { this.kit.boldFace = String(FACES[1]); }
         }
         this.facePick = pick;
         var boldOk:int = this.kit.boldFace.length > 0 ? 1 : 0;
         this.note("FONT try=" + this.faceTries + " pick=" + pick + " bold=" + boldOk + " " + report);
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

      private function applyKey(param1:String, param2:String):void
      {
         var v:String = param2;
         switch(param1)
         {
            case "accent":
               // AccentColor=-1 in the ini means follow the HUD's accent; the swatch shown as
               // chosen then stays the default.
               if(int(v) == -1) { this.follow = true; }
               else { this.follow = false; this.accent = int(v); }
               break;
            case "hex": this.accentHex = v == "-" ? "" : v; break;
            case "core": this.coreFound = v == "1"; break;
            case "coreaccent": this.coreAccent = int(v); break;
            case "corehex": this.coreHex = v == "-" ? "" : v; break;
            case "probe": if(v == "1") { this.setDebug(1); } break;
            case "margin": this.margin = clampInt(int(v),0,200); break;
            case "conflict": if(v == "1") { this.conflict = true; } break;
            case "starfiles": this.starFiles = v == "1"; break;
            case "keys": if(v == "0") { this.keyArrange = "0"; } break;
            case "opacity": this.opacity = clampNum(Number(v),0.4,1,1); break;
            case "scale": this.uiScale = clampNum(Number(v),0.8,1.3,1); break;
            case "density": this.density = v == "detailed" ? "detailed" : "compact"; break;
            case "bymaker": this.byMaker = v == "1"; break;
            case "remember": this.rememberLayout = v != "0"; break;
            case "autoflight": this.autoFlight = v != "0"; break;
            case "notice": this.showConflict = v != "0"; break;
            case "keyhide": this.keyHide = v; break;
            case "keyfind": this.keyFind = v; break;
            case "keyarrange": this.keyArrange = v; break;
            case "ArrangeBarX": this.barDx = Number(v); break;
            case "ArrangeBarY": this.barDy = Number(v); break;
            default:
               if(param1.indexOf("panel.") == 0) { this.startOpen[param1.substring(6)] = v != "0"; }
               else if(param1.indexOf("col.") == 0) { if(HsbJson.safeKey(param1.substring(4))) { this.columnSets[param1.substring(4)] = v; } }
               else { this.lay[param1] = v; }
         }
      }

      // Purpose: the accent in use. Follow uses the HUD's own index and hex (read by the DLL from
      //    the HUD ini) when the HUD is installed; otherwise the builder's own choice.
      // Inputs: none. Outputs: an RGB colour. Dependencies: ACCENTS (the HUD's palette order).
      internal function accentColor():uint
      {
         var i:int = this.accent;
         var hex:String = this.accentHex;
         if(this.follow && this.coreFound && this.coreAccent >= 0)
         {
            i = this.coreAccent;
            hex = this.coreHex;
         }
         if(i == 13 && hex.length == 6)
         {
            var n:int = HsbKit.parseHex(hex);
            if(n >= 0) { return uint(n); }
         }
         if(i < 0 || i > 12) { i = 9; }
         return uint(ACCENTS[i]);
      }

      // Re-applies colours, opacity and scale everywhere after a settings change.
      internal function restyle():void
      {
         if(this.kit == null) { return; }
         this.kit.accent = this.accentColor();
         this.kit.opacity = 0.94 * this.opacity;
         this.markAll();
      }

      internal function markAll():void
      {
         this.dirty = {"Power":true,"Module":true,"Credits":true,"Browser":true,"Stats":true,"Hints":true,"Cluster":true,"Colors":true,"Flight":true,"Notice":true};
         if(this.browser != null) { this.browser.invalidate(); }
      }

      internal function mark(param1:String):void
      {
         this.dirty[param1] = true;
      }

      // Purpose: queue one setting for the DLL to merge into HorizonShipBuilder.user.ini.
      // Inputs: section, key, value (validated again by the DLL against its whitelist).
      // Outputs: a SET line; the write happens at saveSettings. Dependencies: WriteIniNow.
      internal function setSetting(param1:String, param2:String, param3:String):void
      {
         this.note("SET " + param1 + "." + param2 + "=" + param3);
      }

      internal function saveSettings():void
      {
         this.note("SET END");
      }

      private function build():void
      {
         this.layer = new Sprite();
         this.layer.name = "HsbPanels";
         this.layer.mouseEnabled = false;
         this.layer.mouseChildren = true;
         addChild(this.layer);
         this.power = this.box("HsbPower");
         this.card = this.box("HsbModule");
         this.flight = new HsbFlight(this.kit,this);
         this.layer.addChild(this.flight);
         this.credits = this.box("HsbCredits");
         this.cluster = this.box("HsbCluster");
         this.browser = new HsbBrowser(this.kit,this);
         this.layer.addChild(this.browser);
         this.colors = new HsbColors(this.kit,this);
         this.layer.addChild(this.colors);
         this.hints = this.box("HsbHints");
         this.stats = this.box("HsbStats");
         this.notice = this.box("HsbNotice");
         this.popLayer = new Sprite();
         this.popLayer.name = "HsbPopups";
         this.popLayer.mouseEnabled = false;
         this.popLayer.mouseChildren = true;
         addChild(this.popLayer);
         this.restyle();
      }

      private function box(param1:String):HsbBox
      {
         var b:HsbBox = new HsbBox(this.kit,param1);
         this.layer.addChild(b);
         return b;
      }

      private function listen():void
      {
         this.sub("PowerAllocation",function(param1:Object):void { dPower = param1; mark("Power"); });
         this.sub("ShipStats",function(param1:Object):void { dStats = param1; mark("Power"); mark("Stats"); mark("Module"); });
         this.sub("CostSummaryData",function(param1:Object):void { dCost = param1; mark("Credits"); mark("Module"); browser.invalidate(); });
         this.sub("ModuleInfo",function(param1:Object):void { dModule = param1; browser.learn(param1); mark("Module"); });
         this.sub("ModuleVariant",function(param1:Object):void { dVariant = param1; mark("Module"); browser.invalidate(); });
         this.sub("ShipBuilderHelpList",function(param1:Object):void { dHelp = param1.aHelpList as Array; if(dHelp == null) { dHelp = []; } mark("Hints"); });
         this.sub("ControlMapData",function(param1:Object):void { dControls = param1.vMappedEvents as Array; if(dControls == null) { dControls = []; } padUi = uint(param1.uiController); markAll(); });
         this.sub("FlightCheckData",function(param1:Object):void { dFlight = param1; mark("Flight"); });
         this.sub("ColorInitializationData",function(param1:Object):void { dColorInit = param1; colors.onInit(param1); mark("Colors"); });
         this.sub("ColorSelectionData",function(param1:Object):void { dColorSel = param1; colors.onSelection(param1); mark("Colors"); });
         this.sub("ColorSwatchesRecentUI",function(param1:Object):void { colors.onRecent(param1.aSwatches as Array); mark("Colors"); });
         this.sub("ColorSwatchesHue",function(param1:Object):void { colors.onGradient(0,param1.aSwatches as Array); mark("Colors"); });
         this.sub("ColorSwatchesSaturation",function(param1:Object):void { colors.onGradient(1,param1.aSwatches as Array); mark("Colors"); });
         this.sub("ColorSwatchesBrightness",function(param1:Object):void { colors.onGradient(2,param1.aSwatches as Array); mark("Colors"); });
         this.sub("StaticData",function(param1:Object):void { dStatic = param1; });
         this.sub("HangarData",function(param1:Object):void { dHangar = param1; });
         this.sub("PartEntries",function(param1:Object):void { browser.onParts(param1); });
         this.sub("UpgradeEntries",function(param1:Object):void { browser.onParts(param1); });
      }

      // Every feed is wrapped: one failing panel must not stop the others or the vanilla menu.
      private function sub(param1:String, param2:Function):void
      {
         var self:HorizonShipBuilder = this;
         try
         {
            BSUIDataManager.Subscribe(param1,function(param3:Object):void
            {
               var data:Object = null;
               try { data = param3.data; } catch(err:Error) { data = null; }
               if(data == null) { return; }
               try { param2(data); }
               catch(err2:Error) { self.note("FEED " + param1 + " fault " + err2.errorID); }
            });
         }
         catch(err3:Error)
         {
            this.note("LISTEN miss " + param1);
         }
      }

      // Purpose: send one event to the game, exactly as the vanilla controls do.
      // Inputs: event name and its parameter object. Outputs: none.
      // Dependencies: BSUIDataManager.dispatchEvent and Shared.AS3.Events.CustomEvent.
      internal function send(param1:String, param2:Object):void
      {
         try
         {
            BSUIDataManager.dispatchEvent(new CustomEvent(param1,param2));
            if(this.debugOn) { this.note("SEND " + param1); }
         }
         catch(err:Error)
         {
            this.note("SEND fault " + param1 + " " + err.errorID);
         }
      }

      // Purpose: press a control of a hidden vanilla panel, so the vanilla handler runs as if the
      //    player clicked it and sends the game's event itself (the Flight Check tab bar selects
      //    the tab, then reports it). Inputs: the vanilla clip. Outputs: true when delivered.
      internal function clickNative(param1:EventDispatcher):Boolean
      {
         if(param1 == null) { return false; }
         try
         {
            param1.dispatchEvent(new MouseEvent(MouseEvent.CLICK));
            if(this.debugOn) { this.note("NATIVE click"); }
            return true;
         }
         catch(err:Error)
         {
            this.note("NATIVE click fault " + err.errorID);
         }
         return false;
      }

      internal function sendHint(param1:String):void
      {
         if(param1 == null || param1.length == 0) { return; }
         this.send("ShipEditor_OnHintButtonActivated",{"buttonAction":param1});
      }

      // Purpose: find the event of a hint the game shows right now (for buttons that must do
      //    exactly what a game hint does, such as accepting colours).
      // Inputs: candidate event names in order of preference. Outputs: the first displayed
      //    hint's event that matches, or "" when the game shows none of them.
      // Dependencies: ShipBuilderHelpList (dHelp).
      internal function hintEvent(param1:Array):String
      {
         var i:int = 0;
         while(i < param1.length)
         {
            var k:int = 0;
            while(this.dHelp != null && k < this.dHelp.length)
            {
               var hint:Object = this.dHelp[k];
               if(hint != null && hint.bDisplayed != false && String(hint.sEvent) == String(param1[i])) { return String(hint.sEvent); }
               k++;
            }
            i++;
         }
         return "";
      }

      internal function hostClip():Object
      {
         return this.host;
      }

      // Purpose: tell whether a Horizon key is also mapped by the game in this menu.
      // Inputs: a one-character key label. Outputs: the game's event name, or "" when free.
      // Dependencies: ControlMapData (dControls); keyboard names only.
      internal function keyClash(param1:String):String
      {
         if(param1 == null || param1.length != 1 || param1 == "0" || this.dControls == null || this.padUi > 0) { return ""; }
         var want:String = param1.toUpperCase();
         var i:int = 0;
         while(i < this.dControls.length)
         {
            var row:Object = this.dControls[i];
            if(row != null && pcLabel(String(row.strButtonName)).toUpperCase() == want) { return String(row.strUserEventName); }
            i++;
         }
         return "";
      }

      // The character code the DLL watches for a Horizon key; 0 when off or taken by the game.
      private function keyCode(param1:String):int
      {
         if(param1 == null || param1.length != 1 || param1 == "0") { return 0; }
         if(this.keyClash(param1).length > 0) { return 0; }
         return param1.toUpperCase().charCodeAt(0);
      }

      // The key name the game shows for an event, from the live control map (as ButtonKeyHelper).
      internal function keyName(param1:String):String
      {
         if(param1 == null || this.dControls == null) { return ""; }
         var pad:Boolean = this.padUi > 0;
         var i:int = 0;
         while(i < this.dControls.length)
         {
            var row:Object = this.dControls[i];
            if(row != null && String(row.strUserEventName) == param1)
            {
               var names:Array = row.aButtonName as Array;
               var raw:String = names != null && names.length > 1 ? String(names.join("")) : String(row.strButtonName);
               return pad ? padLabel(raw) : pcLabel(raw);
            }
            i++;
         }
         return "";
      }

      // The game maps controller names to glyph-font letters (Xbox X is "C"); without that font
      // the plain button name is the readable choice.
      private static function padLabel(param1:String):String
      {
         var map:Object = {"Xenon_A":"A","Xenon_B":"B","Xenon_X":"X","Xenon_Y":"Y","Xenon_L1":"LB","Xenon_R1":"RB","Xenon_L2":"LT","Xenon_R2":"RT","Xenon_LS":"LS","Xenon_RS":"RS","Xenon_L3":"L3","Xenon_R3":"R3","Xenon_Start":"MENU","Xenon_Select":"VIEW","PSN_A":"\u2715","PSN_B":"\u25CB","PSN_X":"\u25A1","PSN_Y":"\u25B3","PSN_L1":"L1","PSN_R1":"R1","PSN_L2":"L2","PSN_R2":"R2","DPad_Left":"\u2190","DPad_Right":"\u2192","DPad_Up":"\u2191","DPad_Down":"\u2193","DPad_LR":"\u2190 \u2192","DPad_UD":"\u2191 \u2193"};
         if(map[param1] != null) { return String(map[param1]); }
         return param1.replace("Xenon_","").replace("PSN_","");
      }

      private static function pcLabel(param1:String):String
      {
         var mapped:* = null;
         try { mapped = GlobalFunc.NameToTextMap["PC" + param1]; } catch(err:Error) { mapped = null; }
         if(mapped != null) { return String(mapped); }
         if(param1.length == 1) { return param1.toUpperCase(); }
         return param1;
      }

      private function clip(param1:String):DisplayObject
      {
         var out:DisplayObject = null;
         try { out = this.host[param1] as DisplayObject; } catch(err:Error) { out = null; }
         return out;
      }

      // Shown means the vanilla code asked for this clip: visible itself and in every parent.
      private function nativeOn(param1:String):Boolean
      {
         var c:DisplayObject = this.clip(param1);
         if(c == null) { return false; }
         var node:DisplayObject = c;
         var depth:int = 0;
         while(node != null && depth < 8)
         {
            if(!node.visible) { return false; }
            if(node == this.host) { return true; }
            node = node.parent;
            depth++;
         }
         return true;
      }

      // Purpose: once per frame, mirror which vanilla panels the game shows, keep the matching
      //    vanilla clips alive but unseen (alpha 0, children off the mouse), and redraw what changed.
      // Why alpha and not visible=false: vanilla gates its own work on .visible (the palette's
      //    preview event and controller routing), so hiding with visible would stop the game.
      private function adapt():void
      {
         if(this.conflict)
         {
            this.standDown();
            return;
         }
         var hangar:Boolean = this.nativeOn("HangarInfoPanel_mc");
         var builder:Boolean = this.nativeOn("PowerAllocation_mc");
         var colorOn:Boolean = this.nativeOn("ColorPicker_mc");
         var flightOn:Boolean = this.nativeOn("FlightCheck_mc");
         var want:Object = {};
         want.Power = builder && !hangar;
         want.Module = this.nativeOn("ModuleInfoCard_mc") && !hangar && !flightOn;
         want.Credits = this.nativeOn("CostSummary_mc") && !hangar;
         want.Browser = (this.nativeOn("ModulePalette_mc") || flightOn) && !hangar && !colorOn;
         want.Stats = this.nativeOn("ShipStatsFooter_mc") && !hangar;
         want.Hints = this.nativeOn("ButtonBar_mc") && !hangar;
         want.Cluster = (builder || colorOn) && !hangar;
         want.Colors = colorOn && !hangar;
         want.Flight = flightOn && !hangar;
         var changed:Boolean = false;
         var key:String;
         for(key in want)
         {
            if(this.vis[key] != want[key])
            {
               this.vis[key] = want[key];
               this.dirty[key] = true;
               changed = true;
            }
         }
         this.browser.setReadOnly(flightOn);
         this.coverAll(hangar);
         if(changed) { this.place(); }
         this.paintDirty();
         this.browser.tick();
         this.colors.tick();
         if(this.arrange != null && this.arrange.visible) { this.arrange.tick(); }
      }

      private function coverAll(param1:Boolean):void
      {
         var weapons:Boolean = this.dFlight != null && Boolean(this.dFlight.bShowWeapons);
         var key:String;
         for(key in COVERS)
         {
            var on:Boolean = !param1;
            if(key == "Flight" && weapons) { on = false; }
            var names:Array = COVERS[key] as Array;
            var i:int = 0;
            while(i < names.length)
            {
               this.cover(String(names[i]),on);
               i++;
            }
         }
      }

      private function cover(param1:String, param2:Boolean):void
      {
         var c:DisplayObject = this.clip(param1);
         if(c == null) { return; }
         var row:Object = this.covered[param1];
         if(param2)
         {
            if(row == null)
            {
               row = {"alpha":c.alpha,"kids":c is DisplayObjectContainer ? (c as DisplayObjectContainer).mouseChildren : false};
               this.covered[param1] = row;
            }
            if(c.alpha != 0) { c.alpha = 0; }
            if(c is DisplayObjectContainer) { (c as DisplayObjectContainer).mouseChildren = false; }
         }
         else if(row != null)
         {
            c.alpha = Number(row.alpha);
            if(c is DisplayObjectContainer) { (c as DisplayObjectContainer).mouseChildren = row.kids == true; }
            delete this.covered[param1];
         }
      }

      // Another ship builder's DLL is loaded: Horizon steps aside, restores every vanilla clip and
      // shows the notice from mockup 10 once.
      private function standDown():void
      {
         if(this.stoodDown) { return; }
         this.stoodDown = true;
         var key:String;
         for(key in COVERS)
         {
            var names:Array = COVERS[key] as Array;
            var i:int = 0;
            while(i < names.length) { this.cover(String(names[i]),false); i++; }
         }
         this.layer.visible = false;
         this.layer.addChild(this.notice);
         this.notice.visible = true;
         this.layer.visible = true;
         var k:int = 0;
         while(k < this.layer.numChildren)
         {
            var child:DisplayObject = this.layer.getChildAt(k);
            child.visible = child == this.notice;
            k++;
         }
         this.paintStepAside();
         this.note("CONFLICT stood down");
      }

      private function paintDirty():void
      {
         var key:String;
         for(key in this.dirty)
         {
            if(this.dirty[key] != true) { continue; }
            try { this.paint(key); }
            catch(err:Error) { this.note("PAINT " + key + " fault " + err.errorID); }
         }
         this.dirty = {};
      }

      private function shown(param1:String):Boolean
      {
         if(this.vis[param1] != true) { return false; }
         return !this.hideAll || TABBED[param1] == true;
      }

      // A panel draws as its tab when the player collapsed it or while Hide all is on; Show all
      // brings back each panel's own state.
      private function folded(param1:String):Boolean
      {
         return this.collapsed[param1] == true || this.hideAll;
      }

      private function paint(param1:String):void
      {
         switch(param1)
         {
            case "Power": this.paintPower(); break;
            case "Module": this.paintCard(); break;
            case "Credits": this.paintCredits(); break;
            case "Stats": this.paintStats(); break;
            case "Hints": this.paintHints(); break;
            case "Cluster": this.paintCluster(); break;
            case "Browser":
               this.browser.visible = this.shown("Browser");
               this.browser.collapsed = this.folded("Browser");
               // A folded or hidden browser cannot keep Find: it would hold every press and key
               // with no field on screen.
               if(!this.browser.visible || this.browser.collapsed) { this.browser.endFind(); }
               this.browser.invalidate();
               break;
            case "Colors":
               this.colors.visible = this.shown("Colors");
               if(this.colors.visible) { this.colors.paint(); }
               break;
            case "Flight":
               this.flight.visible = this.shown("Flight");
               if(this.flight.visible) { this.flight.paint(this.dFlight); }
               break;
            case "Notice": this.paintNotice(); break;
         }
         this.place();
      }

      // The visible part of the stage in stage units, from Scaleform (letterbox aware). The DLL
      // maps window pixels into this rectangle.
      private function stageView():Object
      {
         try
         {
            var ext:Object = getDefinitionByName("scaleform.gfx.Extensions");
            var rect:Object = ext["visibleRect"];
            if(rect != null && rect.width > 100 && rect.height > 100)
            {
               return {"x":Number(rect.x),"y":Number(rect.y),"width":Number(rect.width),"height":Number(rect.height)};
            }
         }
         catch(err:Error)
         {
         }
         var w:Number = stage != null ? stage.stageWidth : 1920;
         var h:Number = stage != null ? stage.stageHeight : 1080;
         return {"x":0,"y":0,"width":w,"height":h};
      }

      // The same rectangle in this sprite's units, which every panel position uses. Equal to
      // stageView unless the vanilla menu moves or scales its root.
      internal function viewRect():Object
      {
         var r:Object = this.stageView();
         if(stage == null) { return r; }
         try
         {
            var a:Point = this.globalToLocal(new Point(Number(r.x),Number(r.y)));
            var b:Point = this.globalToLocal(new Point(Number(r.x) + Number(r.width),Number(r.y) + Number(r.height)));
            if(b.x - a.x > 100 && b.y - a.y > 100) { return {"x":a.x,"y":a.y,"width":b.x - a.x,"height":b.y - a.y}; }
         }
         catch(err:Error)
         {
         }
         return r;
      }

      private function viewText():String
      {
         var r:Object = this.stageView();
         return int(r.x) + "," + int(r.y) + "," + int(r.width) + "," + int(r.height);
      }

      // The gold mockups at 1920x1080: power 33,38; card 33,290; cluster 807,37; credits
      // 1012,38; browser 1388,37 (501x846); hints right edge 1888 at y 893; stats 424,947.
      // Edges follow the screen margin; Arrange anchors (L/R/C, T/B/C plus offset) win.
      internal function place():void
      {
         if(this.kit == null) { return; }
         var r:Object = this.viewRect();
         var dm:Number = this.margin - 34;
         var sc:Number = this.uiScale;
         var left:Number = r.x + 33 + dm;
         var top:Number = r.y + 37 + dm;
         var right:Number = r.x + r.width - 31 - dm;
         var bottom:Number = r.y + r.height - 37 - dm;
         var boxes:Array = [this.power,this.card,this.flight,this.credits,this.cluster,this.browser,this.colors,this.hints,this.stats];
         var i:int = 0;
         while(i < boxes.length)
         {
            (boxes[i] as HsbBox).scaleX = sc;
            (boxes[i] as HsbBox).scaleY = sc;
            i++;
         }
         this.power.x = left;
         this.power.y = top + 1;
         this.card.x = left;
         var below:Number = this.power.visible ? this.power.y + this.power.boxH * sc + 12 : top + 1;
         this.card.y = below;
         this.flight.x = left;
         this.flight.y = below;
         this.browser.x = right - this.browser.boxW * sc;
         this.browser.y = top;
         if(this.browser.collapsed) { this.browser.x = r.x + r.width - 12 - this.browser.boxW * sc; }
         this.colors.x = right - this.colors.boxW * sc;
         this.colors.y = top;
         var slot:Number = (this.kit.lrg ? 560 : 501) * sc;
         this.credits.x = right - slot - 13 - this.credits.boxW * sc;
         this.credits.y = top + 1;
         if(this.folded("Credits")) { this.credits.x = right - slot - 13 - (this.kit.lrg ? 400 : 363) * sc; }
         this.cluster.x = this.credits.x - 5 - this.cluster.boxW * sc;
         if(this.folded("Credits")) { this.cluster.x = this.credits.x - 5 - this.cluster.boxW * sc; }
         this.cluster.y = top;
         this.stats.x = right + 1 - this.stats.boxW * sc;
         this.stats.y = bottom - this.stats.boxH * sc;
         if(this.folded("Stats")) { this.stats.x = r.x + (r.width - this.stats.boxW * sc) / 2; this.stats.y = r.y + r.height - 28 - this.stats.boxH * sc; }
         this.hints.x = right + 1 - this.hints.boxW * sc;
         this.hints.y = (this.folded("Stats") || !this.stats.visible ? bottom - this.hints.boxH * sc : this.stats.y - BAR_GAP - this.hints.boxH * sc);
         if(this.folded("Hints")) { this.hints.y = r.y + r.height - 28 - this.hints.boxH * sc; }
         this.anchorAll(r);
         if(this.notice.visible)
         {
            this.notice.x = r.x + (r.width - this.notice.boxW) / 2;
            this.notice.y = r.y + 14;
         }
         this.placePops(r);
      }

      private function anchorAll(param1:Object):void
      {
         var ids:Array = ["Power","Module","Credits","Browser","Stats","Hints","Cluster"];
         var i:int = 0;
         while(i < ids.length)
         {
            var id:String = String(ids[i]);
            var list:Array = this.boxesFor(id);
            var lead:HsbBox = list[0] as HsbBox;
            var rawX:String = this.lay[id + "X"] != null ? String(this.lay[id + "X"]) : "-1";
            var rawY:String = this.lay[id + "Y"] != null ? String(this.lay[id + "Y"]) : "-1";
            if(rawX != "-1" || rawY != "-1")
            {
               var w:Number = lead.boxW * lead.scaleX;
               var h:Number = lead.boxH * lead.scaleY;
               var x:Number = this.resolve(rawX,lead.x,w,param1.x,param1.width,"L","R");
               var y:Number = this.resolve(rawY,lead.y,h,param1.y,param1.height,"T","B");
               x = clampNum(x,param1.x,param1.x + Math.max(0,param1.width - w),lead.x);
               y = clampNum(y,param1.y,param1.y + Math.max(0,param1.height - h),lead.y);
               var k:int = 0;
               while(k < list.length)
               {
                  (list[k] as HsbBox).x = x;
                  (list[k] as HsbBox).y = y;
                  k++;
               }
            }
            i++;
         }
      }

      // Colours share the browser's slot; Flight Check shares the card's.
      internal function boxesFor(param1:String):Array
      {
         switch(param1)
         {
            case "Power": return [this.power];
            case "Module": return [this.card,this.flight];
            case "Credits": return [this.credits];
            case "Browser": return [this.browser,this.colors];
            case "Stats": return [this.stats];
            case "Hints": return [this.hints];
            case "Cluster": return [this.cluster];
         }
         return [];
      }

      private function resolve(param1:String, param2:Number, param3:Number, param4:Number, param5:Number, param6:String, param7:String):Number
      {
         if(param1 == "-1" || param1.length < 2) { return param2; }
         var edge:String = param1.charAt(0);
         var off:Number = Number(param1.substring(1));
         if(isNaN(off)) { return param2; }
         if(edge == param6) { return param4 + this.margin + off; }
         if(edge == param7) { return param4 + param5 - this.margin - param3 - off; }
         if(edge == "C") { return param4 + (param5 - param3) / 2 + off; }
         return param2;
      }

      private function collapseButton(param1:HsbBox, param2:Number, param3:Number, param4:String, param5:String):void
      {
         var s:Number = this.kit.u(22);
         this.kit.fill(param1.gfx,param2,param3,s,s,5,0x1A2128,1);
         this.kit.outline(param1.gfx,param2,param3,s,s,5,HsbKit.EDGE_HI,1);
         this.kit.icon(param1.gfx,param4,param2 + 3,param3 + 3,s - 6,HsbKit.LABEL,1);
         param1.hit(param2 - 4,param3 - 4,s + 8,s + 8,param5);
      }

      private function paintPower():void
      {
         var b:HsbBox = this.power;
         b.wipe();
         b.visible = this.shown("Power");
         if(!b.visible) { return; }
         var k:HsbKit = this.kit;
         var p:Object = this.dPower != null ? this.dPower : {};
         var s:Object = this.dStats != null ? this.dStats : {};
         var names:Array = ["iWeapon1","iWeapon2","iWeapon3","iEngine","iShield","iGravDrive"];
         var assigned:int = 0;
         var i:int = 0;
         while(i < names.length) { assigned += Math.max(0,int(p[names[i]])); i++; }
         var total:int = int(s.iReactorPower);
         if(total <= 0) { total = int(p.iReactor); }
         var w:Number = k.lrg ? 390 : 350;
         if(this.folded("Power"))
         {
            var pillW:Number = k.u(196);
            var pillH:Number = k.u(34);
            k.card(b.graphics,0,0,pillW,pillH,10);
            var pt:TextField = k.text(13,k.accent,true,2);
            k.putCaps(pt,"$POWER","POWER");
            k.fit(pt);
            b.add(pt,12,(pillH - pt.height) / 2);
            var pa:TextField = k.text(13,HsbKit.TEXT,true);
            k.put(pa,assigned + " / " + total);
            k.fit(pa);
            b.add(pa,pt.x + pt.width + 8,(pillH - pa.height) / 2);
            this.collapseButton(b,pillW - k.u(28),(pillH - k.u(22)) / 2,"chevD","power.open");
            b.hit(0,0,pillW,pillH,"power.open");
            b.boxW = pillW;
            b.boxH = pillH;
            return;
         }
         var h:Number = k.u(240);
         k.card(b.graphics,0,0,w,h);
         var title:TextField = k.text(14,k.accent,true,2);
         k.putCaps(title,"$POWER","POWER");
         k.fit(title);
         b.add(title,20,14);
         this.collapseButton(b,w - 20 - k.u(22),12,"dockU","power.close");
         var aside:TextField = k.text(14,HsbKit.MUTED,false,0,"right");
         k.put(aside,assigned + " of " + total + " assigned");
         aside.width = 200;
         b.add(aside,w - 20 - k.u(22) - 8 - 200,14);
         var labels:Array = ["W1","W2","W3","$ENG","$SHD","$GRV"];
         var english:Array = ["W1","W2","W3","ENG","SHD","GRV"];
         var mx:Number = 27;
         var step:Number = (w - 54 - 34) / 5;
         var meterH:Number = k.u(92);
         var my:Number = 45;
         i = 0;
         while(i < names.length)
         {
            var value:int = int(p[names[i]]);
            var diff:int = int(p[names[i] + "Diff"]);
            var x:Number = mx + i * step;
            if(value > 0) { this.meter(b.gfx,x,my,34,meterH,12,value,diff); }
            else
            {
               k.outline(b.gfx,x,my,34,meterH,5,HsbKit.EDGE_HI,1);
               k.hline(b.gfx,x + 12,my + meterH / 2,10,HsbKit.DIM,1);
            }
            var lab:TextField = k.text(13,value > 0 ? HsbKit.TEXT : HsbKit.MUTED,value > 0,1.5,"center");
            if(i < 3) { k.put(lab,english[i]); }
            else { k.putCaps(lab,String(labels[i]),String(english[i])); }
            lab.width = 60;
            b.add(lab,x + 17 - 30,my + meterH + 6);
            i++;
         }
         var pipY:Number = my + meterH + 6 + k.u(28);
         var pips:int = Math.min(38,Math.max(0,total));
         var pipGap:Number = 2.4;
         var pipW:Number = pips > 0 ? Math.min(7,(w - 40 - (pips - 1) * pipGap) / pips) : 7;
         i = 0;
         while(i < pips)
         {
            k.fill(b.gfx,20 + i * (pipW + pipGap),pipY,pipW,7,1.5,i < assigned ? k.accent : k.accentDim(0.22),1);
            i++;
         }
         var rowY:Number = pipY + 18;
         var cls:String = this.reactorClass(int(s.iReactorClass));
         var chipW:Number = 0;
         if(cls.length > 0) { chipW = k.keycap(b,20,rowY,cls,k.accent,k.u(24)) + 10; }
         // Mockup 1 spaces these captions 1.5; the large movie's wider face needs the room for
         // EQUIP POWER, so both captions there sit tighter.
         var capSpacing:Number = k.lrg ? 0.6 : 1.5;
         var rl:TextField = k.text(13,HsbKit.LABEL,false,capSpacing);
         k.putCaps(rl,"$REACTOR","REACTOR");
         k.fit(rl);
         b.add(rl,20 + chipW,rowY + 2);
         var rv:TextField = k.text(16,HsbKit.TEXT,true);
         k.put(rv,HsbKit.num(s.iReactorPower));
         k.fit(rv);
         b.add(rv,rl.x + rl.width + 14,rowY);
         var equip:Number = Number(s.iWeaponPower) + Number(s.iEnginePower) + Number(s.iShieldPower);
         var ev:TextField = k.text(16,HsbKit.TEXT,true);
         k.put(ev,isNaN(equip) ? "" : HsbKit.num(equip));
         k.fit(ev);
         b.add(ev,w - 20 - ev.width + 2,rowY);
         // The label sits against its value and never reaches the reactor number: a long
         // translation ends in an ellipsis instead.
         var el:TextField = k.text(13,HsbKit.LABEL,false,capSpacing);
         k.putCaps(el,"$EQUIP POWER","EQUIP POWER");
         k.fit(el,Math.max(k.u(40),ev.x - 8 - (rv.x + rv.width + 16)));
         b.add(el,ev.x - 8 - el.width + 2,rowY + 2);
         b.boxW = w;
         b.boxH = h;
      }

      // The vanilla meter: value-diff bars lit, |diff| bars as the add or remove state, the rest
      // empty, on a fixed 12-bar scale (the game does not expose a capacity).
      private function meter(param1:Graphics, param2:Number, param3:Number, param4:Number, param5:Number, param6:int, param7:int, param8:int):void
      {
         var lit:int = param8 > 0 ? param7 - param8 : param7;
         var extra:int = Math.abs(param8);
         if(lit + extra > param6)
         {
            if(lit > param6) { lit = param6; }
            extra = param6 - lit;
         }
         var gap:Number = 2.6;
         var barH:Number = (param5 - (param6 - 1) * gap) / param6;
         var n:int = 0;
         while(n < param6)
         {
            var color:uint = this.kit.accentDim(0.22);
            if(n < lit) { color = this.kit.accent; }
            else if(n < lit + extra) { color = param8 < 0 ? HsbKit.RED : HsbKit.GREEN; }
            var by:Number = param3 + param5 - (n + 1) * barH - n * gap;
            this.kit.fill(param1,param2 + 3,by,param4 - 6,barH,1.5,color,1);
            n++;
         }
      }

      private function reactorClass(param1:int):String
      {
         var letters:Array = ["A","B","C","M"];
         if(param1 < 0 || param1 >= letters.length) { return ""; }
         return String(letters[param1]);
      }

      // The Selected Module card, fed by ModuleInfo only. Numbers and translation follow the
      // vanilla ModuleInfoCard rules (statText, diffText, rank substitution).
      private function paintCard():void
      {
         var b:HsbBox = this.card;
         b.wipe();
         var data:Object = this.dModule;
         b.visible = this.shown("Module") && data != null;
         if(!b.visible) { return; }
         var k:HsbKit = this.kit;
         var w:Number = k.lrg ? 390 : 350;
         var pad:Number = 20;
         var g:Graphics = b.gfx;
         if(this.folded("Module"))
         {
            var nm:TextField = k.text(14,HsbKit.TEXT,true);
            k.put(nm,data.sModuleName);
            k.fit(nm,k.u(300));
            var pw:Number = nm.width + k.u(60);
            var ph:Number = k.u(32);
            k.card(g,0,0,pw,ph,9);
            k.fill(g,12,(ph - k.u(16)) / 2,3,k.u(16),0,k.accent,1);
            b.add(nm,22,(ph - nm.height) / 2);
            this.collapseButton(b,pw - k.u(28),(ph - k.u(22)) / 2,"chevR","module.open");
            b.hit(0,0,pw,ph,"module.open");
            b.boxW = pw;
            b.boxH = ph;
            return;
         }
         var inner:Number = w - pad * 2;
         var head:TextField = k.text(14,k.accent,true,2);
         k.putCaps(head,"$SELECTED MODULE","SELECTED MODULE");
         k.fit(head);
         b.add(head,pad,16);
         this.collapseButton(b,w - pad - k.u(22),13,"dockL","module.close");
         var y:Number = 16 + head.height + 6;
         var name:TextField = k.text(18,HsbKit.TEXT,true);
         name.multiline = true;
         name.wordWrap = true;
         name.width = inner - 12;
         k.put(name,data.sModuleName);
         name.height = name.textHeight + 6;
         k.fill(g,pad,y + 4,3,k.u(20),0,k.accent,1);
         b.add(name,pad + 11,y);
         y += name.height + 2;
         var bits:Array = [];
         var maker:String = HsbBrowser.makerOf(String(data.sModuleName));
         if(maker.length > 0) { bits.push(maker); }
         var size:String = HsbBrowser.sizeOf(String(data.sModuleName));
         if(size.length > 0) { bits.push(size); }
         var vline:String = this.browser.variantLine();
         if(vline.length > 0) { bits.push(vline); }
         if(bits.length > 0)
         {
            var subT:TextField = k.text(13,HsbKit.MUTED);
            k.put(subT,bits.join(" \u00B7 "));
            k.fit(subT,inner);
            b.add(subT,pad + 11,y);
            y += subT.height + 4;
         }
         y += 8;
         k.hline(g,pad,y,inner);
         y += 8;
         var rows:Array = data.aStats as Array;
         var count:int = rows == null ? 0 : Math.min(rows.length,10);
         var pitch:Number = k.u(30);
         var i:int = 0;
         while(i < count)
         {
            var stat:Object = rows[i];
            var lab:TextField = k.text(13,0xC9D0D4,false,1);
            k.put(lab,stat.text);
            if(lab.text.length > 0 && lab.text.charAt(0) != "$") { k.put(lab,lab.text.toUpperCase()); }
            lab.width = inner - 120;
            b.add(lab,pad,y + (pitch - lab.height) / 2);
            var val:TextField = k.text(15,HsbKit.TEXT,true,0,"right");
            k.put(val,statText(stat));
            val.width = 80;
            b.add(val,w - pad - 52 - 80,y + (pitch - val.height) / 2);
            var chip:String = diffText(stat);
            if(chip.length == 0) { k.hline(g,w - pad - 16,y + pitch / 2,10,HsbKit.DIM,1); }
            else
            {
               var tag:TextField = k.text(12,Number(stat.fDiff) > 0 ? HsbKit.GREEN : HsbKit.RED,true);
               k.put(tag,chip);
               if(tag.textWidth + 14 > 44) { k.put(tag,shortChip(chip)); }
               if(tag.textWidth + 14 > 44) { k.put(tag,chip.charAt(0)); }
               k.fit(tag);
               var cw:Number = Math.min(44,Math.max(k.u(26),tag.textWidth + 14));
               var ch:Number = k.u(20);
               k.fill(g,w - pad - cw,y + (pitch - ch) / 2,cw,ch,5,Number(stat.fDiff) > 0 ? HsbKit.GREEN_BG : HsbKit.RED_BG,1);
               b.add(tag,w - pad - cw + (cw - tag.width) / 2,y + (pitch - tag.height) / 2);
            }
            y += pitch;
            i++;
         }
         if(count > 0)
         {
            y += 10;
            k.hline(g,pad,y,inner);
         }
         y += 16;
         var desc:TextField = k.text(14,0xD6DBDF);
         desc.multiline = true;
         desc.wordWrap = true;
         desc.width = inner;
         k.put(desc,data.sDescription);
         desc.height = desc.textHeight + 6;
         b.add(desc,pad,y);
         y += Math.max(desc.height,k.u(48)) + 12;
         var skills:Array = data.aRequiredAttributes as Array;
         var need:int = skills == null ? 0 : Math.min(skills.length,2);
         if(need > 0)
         {
            k.hline(g,pad,y,inner);
            y += 10;
            var s:int = 0;
            while(s < need)
            {
               var row:Object = skills[s];
               var has:Boolean = Boolean(row.bHasSkill);
               var sk:TextField = k.text(14,has ? 0xF4F0E4 : HsbKit.RED);
               k.put(sk,row.sName);
               sk.width = inner - 112;
               b.add(sk,pad,y);
               var rk:TextField = k.text(14,has ? HsbKit.LABEL : HsbKit.RED,false,0,"right");
               k.put(rk,"$(Rank #)");
               k.put(rk,GlobalFunc.DoSubstitutions(rk.text,[row.uRank]));
               rk.width = 110;
               b.add(rk,w - pad - 110,y);
               y += pitch;
               s++;
            }
         }
         k.hline(g,pad,y,inner);
         y += 16;
         var half:Number = w / 2 + 14;
         var vl:TextField = k.text(13,HsbKit.MUTED,false,1.5);
         k.putCaps(vl,"$VALUE","VALUE");
         k.fit(vl);
         b.add(vl,pad,y);
         var ml:TextField = k.text(13,HsbKit.MUTED,false,1.5);
         k.putCaps(ml,"$MASS","MASS");
         k.fit(ml);
         b.add(ml,half,y);
         y += vl.height + 2;
         var vv:TextField = k.text(22,HsbKit.TEXT,true);
         k.put(vv,HsbKit.num(data.iModuleCost));
         k.fit(vv);
         b.add(vv,pad,y);
         var mv:TextField = k.text(22,HsbKit.TEXT,true);
         k.put(mv,HsbKit.num(data.iModuleMass));
         k.fit(mv);
         b.add(mv,half,y);
         var st:Object = this.dStats;
         if(st != null && Boolean(st.bShowingPreview) && Number(st.iMassDiff) != 0)
         {
            var md:Number = Number(st.iMassDiff);
            k.diffChip(b,half + mv.width + 6,y + (mv.height - k.u(20)) / 2,(md > 0 ? "+" : "-") + HsbKit.num(Math.abs(md)),md < 0);
         }
         y += vv.height + 10;
         var cost:Object = this.dCost;
         if(cost != null && Number(cost.uTotalCredits) != 0)
         {
            var cl:TextField = k.text(13,HsbKit.MUTED);
            k.put(cl,"Total change cost: " + (Boolean(cost.bBuying) ? "+" : "-") + HsbKit.num(cost.uTotalCredits));
            k.fit(cl,inner);
            b.add(cl,pad,y + 4);
            y += cl.height + 6;
         }
         var h:Number = y + 14;
         k.card(b.graphics,0,0,w,h);
         b.boxW = w;
         b.boxH = h;
      }

      internal static function statText(param1:Object):String
      {
         if(String(param1.text) == "$CLASS") { return String.fromCharCode(param1.fValue); }
         if(param1.bPercentage) { return GlobalFunc.FormatNumberToString(Number(param1.fValue) * 100) + "%"; }
         return GlobalFunc.FormatNumberToString(Number(param1.fValue),2);
      }

      // The game marks a change by frame only, so the chip is new text. A diff too small to
      // show at the value's places gets no chip.
      internal static function diffText(param1:Object):String
      {
         var diff:Number = Number(param1.fDiff);
         if(!(diff > 0) && !(diff < 0)) { return ""; }
         var sign:String = diff > 0 ? "+" : "-";
         if(String(param1.text) == "$CLASS") { return sign; }
         var size:String = param1.bPercentage ? chipNumber(Math.abs(diff) * 100,0) : chipNumber(Math.abs(diff),2);
         if(size == "0") { return ""; }
         return sign + size + (param1.bPercentage ? "%" : "");
      }

      // A chip too wide for its room drops its places, as a cut would. A whole part of 0 would
      // read as no change, so that chip keeps its sign alone.
      internal static function shortChip(param1:String):String
      {
         var dot:int = param1.indexOf(".");
         if(dot < 0 || param1.indexOf("e") >= 0) { return param1.charAt(0); }
         var whole:String = param1.substring(0,dot);
         return whole.length == 2 && whole.charAt(1) == "0" ? param1.charAt(0) : whole;
      }

      // FormatNumberToString cuts the text of toString, which turns float noise such as
      // 1.2e-7 into "1.2". toFixed never writes an exponent below 1e21.
      internal static function chipNumber(param1:Number, param2:int):String
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

      private function paintCluster():void
      {
         var b:HsbBox = this.cluster;
         b.wipe();
         b.visible = this.vis["Cluster"] == true;
         if(!b.visible) { return; }
         var k:HsbKit = this.kit;
         var h:Number = k.u(38);
         var g:Graphics = b.gfx;
         k.card(g,0,0,h,h,7);
         k.icon(g,"gear",(h - k.u(18)) / 2,(h - k.u(18)) / 2,k.u(18),k.accent,1);
         b.hit(0,0,h,h,"gear");
         var bx:Number = h + 8;
         var label:TextField = k.text(13,HsbKit.TEXT,true,1.5);
         k.put(label,this.hideAll ? "SHOW ALL" : "HIDE ALL");
         k.fit(label);
         var capLabel:String = this.keyHide.length > 0 && this.keyHide != "0" ? this.keyHide : "";
         var bw:Number = 12 + k.u(18) + 8 + label.width + (capLabel.length > 0 ? 10 + k.u(24) : 0) + 12;
         k.card(g,bx,0,bw,h,7);
         if(this.hideAll) { k.outline(g,bx,0,bw,h,7,k.accent,1); }
         k.icon(g,this.hideAll ? "eye" : "eyeOff",bx + 12,(h - k.u(18)) / 2,k.u(18),k.accent,1);
         b.add(label,bx + 12 + k.u(18) + 8,(h - label.height) / 2);
         if(capLabel.length > 0) { k.keycap(b,bx + bw - 12 - k.u(24),(h - k.u(22)) / 2,capLabel,k.accent); }
         b.hit(bx,0,bw,h,"hide");
         b.boxW = bx + bw;
         b.boxH = h;
      }

      private function paintCredits():void
      {
         var b:HsbBox = this.credits;
         b.wipe();
         var d:Object = this.dCost;
         b.visible = this.shown("Credits") && d != null;
         if(!b.visible) { return; }
         var k:HsbKit = this.kit;
         var g:Graphics = b.gfx;
         var total:String = HsbKit.num(d.uTotalCredits);
         var refund:Boolean = Number(d.uTotalCredits) != 0 && !Boolean(d.bBuying);
         if(this.folded("Credits"))
         {
            var tl:TextField = k.text(13,k.accent,true,2);
            k.putCaps(tl,"$TOTAL","TOTAL");
            k.fit(tl);
            var tv:TextField = k.text(15,refund ? HsbKit.GREEN : k.accent,true);
            k.put(tv,total);
            k.fit(tv);
            var ph:Number = k.u(38);
            var pw:Number = 14 + tl.width + 20 + tv.width + 12 + k.u(22) + 10;
            k.card(g,0,0,pw,ph,8);
            b.add(tl,14,(ph - tl.height) / 2);
            b.add(tv,pw - 10 - k.u(22) - 12 - tv.width,(ph - tv.height) / 2);
            this.collapseButton(b,pw - 10 - k.u(22),(ph - k.u(22)) / 2,"chevD","credits.open");
            b.hit(0,0,pw,ph,"credits.open");
            b.boxW = pw;
            b.boxH = ph;
            return;
         }
         var w:Number = k.lrg ? 400 : 363;
         var pitch:Number = k.u(30);
         var vendor:Boolean = d.uVendorCredits != null;
         var rows:Array = [["$VENDOR CREDITS","VENDOR CREDITS",HsbKit.num(d.uVendorCredits)],["$YOUR CREDITS","YOUR CREDITS",HsbKit.num(d.uPlayerCredits)]];
         var y:Number = 12;
         // Mockup 5: the collapse button sits at the top right; the values keep its column clear.
         var valueRight:Number = w - 20 - k.u(22) - 10;
         this.collapseButton(b,w - 20 - k.u(22),y + (pitch - k.u(22)) / 2,"dockU","credits.close");
         var i:int = 0;
         while(i < rows.length)
         {
            if(i == 0 && !vendor) { i++; continue; }
            var l:TextField = k.text(13,0xC5CCD1,false,1.5);
            k.putCaps(l,String(rows[i][0]),String(rows[i][1]));
            k.fit(l);
            b.add(l,20,y + (pitch - l.height) / 2);
            var v:TextField = k.text(15,HsbKit.TEXT,false,0,"right");
            k.put(v,rows[i][2]);
            v.width = 140;
            b.add(v,valueRight - 140,y + (pitch - v.height) / 2);
            y += pitch;
            i++;
         }
         var t1:TextField = k.text(13,k.accent,true,1.5);
         k.putCaps(t1,"$TOTAL","TOTAL");
         k.fit(t1);
         b.add(t1,20,y + (pitch - t1.height) / 2);
         var t2:TextField = k.text(15,refund ? HsbKit.GREEN : k.accent,true,0,"right");
         k.put(t2,total);
         t2.width = 140;
         b.add(t2,valueRight - 140,y + (pitch - t2.height) / 2);
         y += pitch + 8;
         k.card(b.graphics,0,0,w,y);
         b.boxW = w;
         b.boxH = y;
      }

      // Stats strip, as ShipStatsFooter: while previewing, the value is the current one and the
      // chip the change; mass is inverted (more mass is red).
      private function paintStats():void
      {
         var b:HsbBox = this.stats;
         b.wipe();
         var d:Object = this.dStats;
         b.visible = this.shown("Stats") && d != null;
         if(!b.visible) { return; }
         var k:HsbKit = this.kit;
         var g:Graphics = b.gfx;
         var preview:Boolean = Boolean(d.bShowingPreview);
         var defs:Array = [["$HULL","HULL","iHealth",false,""],["$SHIELD","SHIELD","iShield",false,""],["$CARGO","CARGO","iCargo",false,""],["$MAX CREW","MAX CREW","iCrew",false,""],["$JUMP RANGE","JUMP RANGE","iJumpRange",false," LY"],["$MOBILITY","MOBILITY","iMobility",false,""],["$TOP SPEED","TOP SPEED","iSpeed",false,""],["$MASS","MASS","iMass",true,""]];
         if(this.folded("Stats"))
         {
            var picks:Array = [];
            var j:int = 0;
            while(j < defs.length && picks.length < 3)
            {
               if(preview && Number(d[defs[j][2] + "Diff"]) != 0) { picks.push(defs[j]); }
               j++;
            }
            if(picks.length == 0) { picks = [defs[7],defs[0]]; }
            var x0:Number = 16;
            var ph:Number = k.u(34);
            var parts:Array = [];
            j = 0;
            while(j < picks.length)
            {
               var cl:TextField = k.text(12,HsbKit.MUTED,false,1.5);
               k.putCaps(cl,String(picks[j][0]),String(picks[j][1]));
               k.fit(cl);
               parts.push({"t":cl,"x":x0});
               x0 += cl.width + 6;
               var cv:TextField = k.text(15,HsbKit.TEXT,true);
               var cdiff:Number = Number(d[picks[j][2] + "Diff"]);
               var cval:Number = Number(d[picks[j][2]]);
               k.put(cv,HsbKit.num(preview && cdiff != 0 ? cval - cdiff : cval) + String(picks[j][4]));
               k.fit(cv);
               parts.push({"t":cv,"x":x0});
               x0 += cv.width + 6;
               if(preview && cdiff != 0)
               {
                  var good:Boolean = picks[j][3] == true ? cdiff < 0 : cdiff > 0;
                  parts.push({"chip":(cdiff > 0 ? "+" : "-") + HsbKit.num(Math.abs(cdiff)),"good":good,"x":x0});
                  x0 += k.u(30) + 6;
               }
               if(j < picks.length - 1) { parts.push({"rule":true,"x":x0 + 6}); x0 += 18; }
               j++;
            }
            var pw:Number = x0 + 10 + k.u(22) + 10;
            k.card(g,0,0,pw,ph,9);
            j = 0;
            while(j < parts.length)
            {
               var row:Object = parts[j];
               if(row.t != null) { b.add(row.t as TextField,row.x,(ph - (row.t as TextField).height) / 2); }
               else if(row.chip != null) { k.diffChip(b,row.x,(ph - k.u(20)) / 2,String(row.chip),row.good == true); }
               else if(row.rule == true) { k.vline(g,row.x,8,ph - 16,0x2A3238,1); }
               j++;
            }
            this.collapseButton(b,pw - 10 - k.u(22),(ph - k.u(22)) / 2,"chevU","stats.open");
            b.hit(0,0,pw,ph,"stats.open");
            b.boxW = pw;
            b.boxH = ph;
            return;
         }
         var r:Object = this.viewRect();
         var w:Number = Math.min(1464,r.width - (this.margin + 391 + 31));
         var h:Number = k.u(STATS_HEIGHT);
         k.card(g,0,0,w,h);
         var cols:int = defs.length + 1;
         var cw:Number = (w - 40) / cols;
         var wl:TextField = k.text(12,HsbKit.MUTED,false,1.5,"center");
         k.putCaps(wl,"$WEAPON GROUPS","WEAPON GROUPS");
         wl.width = cw;
         b.add(wl,20,16);
         var groups:Array = d.aWeaponGroupNames as Array;
         var dmg:Array = d.aWeaponGroupsDmg as Array;
         var wtext:Array = [];
         var gi:int = 0;
         while(groups != null && gi < groups.length && gi < 3)
         {
            var gname:String = String(groups[gi]);
            var gd:* = dmg != null && gi < dmg.length ? dmg[gi] : null;
            wtext.push(gd != null && Number(gd) > 0 ? HsbKit.num(gd) : gname);
            gi++;
         }
         var wv:TextField = k.text(13,HsbKit.LABEL,false,0,"center");
         k.put(wv,wtext.length > 0 ? wtext.join(" \u00B7 ") : "\u2014");
         wv.width = cw;
         b.add(wv,20,16 + k.u(30));
         var i:int = 0;
         while(i < defs.length)
         {
            var x:Number = 20 + (i + 1) * cw;
            k.vline(g,x,14,h - 28,0x222A30,1);
            var lab:TextField = k.text(12,HsbKit.MUTED,false,1.5,"center");
            k.putCaps(lab,String(defs[i][0]),String(defs[i][1]));
            lab.width = cw;
            b.add(lab,x,16);
            var diff:Number = Number(d[defs[i][2] + "Diff"]);
            var value:Number = Number(d[defs[i][2]]);
            var val:TextField = k.text(20,HsbKit.TEXT,true);
            k.put(val,HsbKit.num(preview && diff != 0 ? value - diff : value) + String(defs[i][4]));
            k.fit(val);
            var chipW:Number = preview && diff != 0 ? k.u(30) + 6 : 0;
            var vx:Number = x + (cw - val.width - chipW) / 2;
            b.add(val,vx,16 + k.u(24));
            if(chipW > 0)
            {
               var good2:Boolean = defs[i][3] == true ? diff < 0 : diff > 0;
               k.diffChip(b,vx + val.width + 4,16 + k.u(24) + (val.height - k.u(20)) / 2,(diff > 0 ? "+" : "-") + HsbKit.num(Math.abs(diff)),good2);
            }
            i++;
         }
         this.collapseButton(b,w - 12 - k.u(22),10,"chevD","stats.close");
         b.boxW = w;
         b.boxH = h;
      }

      // The game's own hint list, with its live key names. A click sends the same event the
      // vanilla button sends (ShipEditor_OnHintButtonActivated with the hint's event).
      private function paintHints():void
      {
         var b:HsbBox = this.hints;
         b.wipe();
         b.visible = this.shown("Hints");
         if(!b.visible) { return; }
         var k:HsbKit = this.kit;
         var g:Graphics = b.gfx;
         var h:Number = k.u(HINTS_HEIGHT);
         if(this.folded("Hints"))
         {
            var kl:TextField = k.text(13,HsbKit.TEXT,true,1.5);
            k.put(kl,"KEYS");
            k.fit(kl);
            var pw:Number = 12 + k.u(22) + 10 + kl.width + 10 + k.u(22) + 10;
            var ph:Number = k.u(34);
            k.card(g,0,0,pw,ph,9);
            k.keycap(b,12,(ph - k.u(22)) / 2,"?",HsbKit.LABEL);
            b.add(kl,12 + k.u(22) + 10,(ph - kl.height) / 2);
            this.collapseButton(b,pw - 10 - k.u(22),(ph - k.u(22)) / 2,"chevU","hints.open");
            b.hit(0,0,pw,ph,"hints.open");
            b.boxW = pw;
            b.boxH = ph;
            return;
         }
         var x:Number = 14;
         var list:Array = this.dHelp != null ? this.dHelp : [];
         var items:Array = [];
         var i:int = 0;
         while(i < list.length)
         {
            var hint:Object = list[i];
            if(hint != null && hint.bDisplayed != false)
            {
               var cap:String = this.keyName(String(hint.sEvent));
               var lab:TextField = k.text(13,HsbKit.TEXT,false,1.5);
               k.put(lab,hint.sText);
               if(lab.text.length > 0 && lab.text.charAt(0) != "$") { k.put(lab,lab.text.toUpperCase()); }
               if(hint.sHoldText != null && String(hint.sHoldText).length > 0)
               {
                  var hold:TextField = k.text(13,HsbKit.TEXT);
                  k.put(hold,hint.sHoldText);
                  k.put(lab,lab.text + " / " + hold.text.toUpperCase());
               }
               k.fit(lab);
               items.push({"cap":cap,"lab":lab,"event":String(hint.sEvent),"idx":i});
            }
            i++;
         }
         i = 0;
         while(i < items.length)
         {
            var it:Object = items[i];
            var start:Number = x;
            if(String(it.cap).length > 0)
            {
               x += k.keycap(b,x,(h - k.u(22)) / 2,String(it.cap),HsbKit.LABEL) + 9;
            }
            b.add(it.lab as TextField,x,(h - (it.lab as TextField).height) / 2);
            x += (it.lab as TextField).width + 18;
            b.hit(start - 4,0,x - start - 10,h,"hint",it.event);
            i++;
         }
         var w:Number = Math.max(k.u(200),x + k.u(22) + 6);
         k.card(b.graphics,0,0,w,h,10);
         this.collapseButton(b,w - 10 - k.u(22),(h - k.u(22)) / 2,"chevD","hints.close");
         b.boxW = w;
         b.boxH = h;
      }

      private function paintNotice():void
      {
         var b:HsbBox = this.notice;
         if(this.stoodDown) { return; }
         b.wipe();
         b.visible = false;
      }

      // Mockup 10: the builder is off because another ship builder's DLL is loaded.
      private function paintStepAside():void
      {
         var b:HsbBox = this.notice;
         b.wipe();
         var k:HsbKit = this.kit;
         var t:TextField = k.text(14,HsbKit.TEXT,true);
         k.put(t,"Horizon Ship Builder is turned off because StarUI Ship Builder is installed. Nothing was changed.");
         k.fit(t,900);
         var w:Number = t.width + 64;
         var h:Number = k.u(46);
         k.card(b.graphics,0,0,w,h,10);
         k.outline(b.graphics,0,0,w,h,10,HsbKit.ORANGE,1);
         k.icon(b.graphics,"info",16,(h - 18) / 2,18,HsbKit.ORANGE,1);
         b.add(t,44,(h - t.height) / 2);
         b.boxW = w;
         b.boxH = h;
         var r:Object = this.viewRect();
         b.x = r.x + (r.width - w) / 2;
         b.y = r.y + 14;
      }

      // Mockup 11: StarUI files are present but Horizon is running.
      internal function bannerWanted():Boolean
      {
         return this.starFiles && this.showConflict && !this.bannerGone && !this.conflict;
      }

      internal function dismissBanner(param1:Boolean):void
      {
         this.bannerGone = true;
         if(param1)
         {
            this.showConflict = false;
            this.setSetting("Notices","ShowConflictNotice","0");
            this.saveSettings();
         }
         this.browser.invalidate();
      }

      // ---- input ---------------------------------------------------------------------------

      internal function capturing():Boolean
      {
         return this.pops.length > 0 || this.textOwner != null || (this.arrange != null && this.arrange.visible) || this.gridOpen();
      }

      private function gridOpen():Boolean
      {
         return this.browser != null && this.browser.gridOpen && this.shown("Browser") && !this.folded("Browser");
      }

      private function pushState():void
      {
         var w:int = stage != null ? stage.stageWidth : 0;
         var h:int = stage != null ? stage.stageHeight : 0;
         var arranging:Boolean = this.arrange != null && this.arrange.visible;
         var hotkeys:Boolean = this.hotkeysAllowed();
         var line:String = "STATE capture=" + (this.capturing() ? 1 : 0) + " text=" + (this.textOwner != null ? 1 : 0) + " arrange=" + (arranging ? 1 : 0) + " stage=" + w + "x" + h + " view=" + this.viewText() + " keys=" + (hotkeys && this.keyArrange != "0" ? 1 : 0) + " hide=" + (hotkeys ? this.keyCode(this.keyHide) : 0) + " find=" + (hotkeys ? this.keyCode(this.keyFind) : 0);
         this.lines.unshift(line);
         var nextHot:String = this.hotText();
         if(nextHot != this.hot)
         {
            this.hot = nextHot;
            this.lines.splice(1,0,"HOT " + nextHot);
         }
      }

      // The rectangles the DLL swallows presses and wheel in: every visible Horizon box, or the
      // whole screen while a popup, dialog, text field, the category grid or Arrange is open.
      private function hotText():String
      {
         if(this.conflict || this.kit == null) { return "none"; }
         if(this.capturing()) { return "all"; }
         var out:Array = [];
         var boxes:Array = [this.power,this.card,this.flight,this.cluster,this.credits,this.browser,this.colors,this.hints,this.stats];
         var i:int = 0;
         while(i < boxes.length)
         {
            var b:HsbBox = boxes[i] as HsbBox;
            if(b.visible && b.parent != null && b.boxW > 0 && b.boxH > 0)
            {
               var tl:Point = this.localToGlobal(new Point(b.x,b.y));
               var br:Point = this.localToGlobal(new Point(b.x + b.boxW * b.scaleX,b.y + b.boxH * b.scaleY));
               out.push(int(Math.floor(tl.x)) + "," + int(Math.floor(tl.y)) + "," + int(Math.ceil(br.x - tl.x)) + "," + int(Math.ceil(br.y - tl.y)));
            }
            i++;
         }
         return out.length > 0 ? out.join(";") : "none";
      }

      private function onToken(param1:String):void
      {
         if(param1.length < 3) { return; }
         var bits:Array = param1.split(" ");
         var kind:String = String(bits[0]);
         if(kind == "M" && bits.length >= 4)
         {
            var mp:Point = this.globalToLocal(new Point(Number(bits[2]),Number(bits[3])));
            this.onPointer(String(bits[1]),mp.x,mp.y,bits.length < 5 || String(bits[4]) == "1");
            return;
         }
         if(kind == "W" && bits.length >= 4)
         {
            var wp:Point = this.globalToLocal(new Point(Number(bits[2]),Number(bits[3])));
            this.onWheel(Number(bits[1]),wp.x,wp.y,bits.length < 5 || String(bits[4]) == "1");
            return;
         }
         if(kind == "K") { this.onKey(param1.substring(2)); return; }
         if(kind == "C" && bits.length >= 2) { this.onChar(int(bits[1])); return; }
         if(kind == "LEAK") { this.leaks++; }
      }

      // Which box gets a point: popups first (topmost), then Arrange, then panels.
      private function boxAt(param1:Number, param2:Number):HsbBox
      {
         var i:int = this.pops.length - 1;
         if(i >= 0) { return this.pops[i] as HsbBox; }
         var boxes:Array = [this.cluster,this.browser,this.colors,this.credits,this.power,this.card,this.flight,this.hints,this.stats];
         var k:int = 0;
         while(k < boxes.length)
         {
            var b:HsbBox = boxes[k] as HsbBox;
            if(b.contains2(param1,param2)) { return b; }
            k++;
         }
         return null;
      }

      private function onPointer(param1:String, param2:Number, param3:Number, param4:Boolean):void
      {
         this.pointerX = param2;
         this.pointerY = param3;
         if(this.arrange != null && this.arrange.visible)
         {
            this.arrange.pointer(param1,param2,param3);
            return;
         }
         if(param1 == "M")
         {
            if(this.dragBox != null) { this.dragBox.onMove(param2,param3); return; }
            var over:HsbBox = this.boxAt(param2,param3);
            if(over != this.hoverBox)
            {
               if(this.hoverBox != null) { this.hoverBox.onHover(-1,-1); }
               this.hoverBox = over;
            }
            if(over != null) { over.onHover(param2,param3); }
            return;
         }
         if(param1 == "U")
         {
            if(this.dragBox != null)
            {
               var was:HsbBox = this.dragBox;
               this.dragBox = null;
               was.onRelease(param2,param3);
            }
            return;
         }
         if(param1 != "D" || !param4) { return; }
         var top:HsbBox = this.topPop();
         if(top != null && !top.contains2(param2,param3))
         {
            if(top.lightDismiss) { this.closePop(top,false); }
            return;
         }
         if(top == null && this.gridOpen() && !this.browser.contains2(param2,param3))
         {
            this.browser.closeGrid();
            return;
         }
         // A press outside the browser ends Find like a click away from a text field; a Horizon
         // control under the press still acts on it.
         if(top == null && this.textOwner == this.browser && !this.browser.contains2(param2,param3)) { this.browser.endFind(); }
         var target:HsbBox = this.boxAt(param2,param3);
         if(target == null) { return; }
         var hit:Object = target.hitAt(param2,param3);
         if(this.debugOn) { this.note("PRESS " + int(param2) + "," + int(param3) + " box=" + target.name + " hit=" + (hit != null ? String(hit.id) : "-") + " top=" + this.topName(param2,param3)); }
         if(target.onPress(hit,param2,param3)) { this.dragBox = target; return; }
         if(hit != null) { this.act(target,String(hit.id),hit.data); }
      }

      // Scaleform's own hit test at a point, for the debug log only (desktop verification of
      // the p5 diagnosis: whether Scaleform even sees Horizon boxes as topmost).
      private function topName(param1:Number, param2:Number):String
      {
         try
         {
            var ext:Object = getDefinitionByName("scaleform.gfx.Extensions");
            var at:Point = this.localToGlobal(new Point(param1,param2));
            var found:DisplayObject = ext["getTopMostEntity"](at.x,at.y,true) as DisplayObject;
            if(found == null) { return "none"; }
            var path:Array = [];
            var node:DisplayObject = found;
            while(node != null && path.length < 4) { path.unshift(node.name); node = node.parent; }
            return path.join(">");
         }
         catch(err:Error)
         {
         }
         return "na";
      }

      private function onWheel(param1:Number, param2:Number, param3:Number, param4:Boolean):void
      {
         if(!param4) { return; }
         var target:HsbBox = this.boxAt(param2,param3);
         if(target != null) { target.onWheel(param1,param2,param3); }
      }

      private function onKey(param1:String):void
      {
         if(this.capturing())
         {
            if(param1 == "cancel") { this.cancelTop("key"); return; }
            if(param1 == "ok") { this.acceptTop("key"); return; }
         }
         if(this.arrange != null && this.arrange.visible)
         {
            this.arrange.key(param1);
            return;
         }
         if(this.textOwner != null)
         {
            if(this.textOwner.onKey(param1)) { return; }
         }
         var top:HsbBox = this.topPop();
         if(top != null)
         {
            top.onKey(param1);
            return;
         }
         if(this.gridOpen())
         {
            this.browser.onKey(param1);
            return;
         }
         if(!this.hotkeysAllowed()) { return; }
         if(param1 == "open") { this.openArrange(); return; }
         if(param1 == "hide") { this.toggleHide(); return; }
         if(param1 == "find" && this.shown("Browser") && !this.folded("Browser")) { this.browser.startFind(); return; }
      }

      // Purpose: whether Horizon's own hotkeys (Hide all, Find, Ctrl+L for Arrange) may act.
      // Outputs: false while the player types in a vanilla text field (the ship-rename screen
      //    turns the name into an INPUT field with stage focus), while that screen is up, in the
      //    hangar view and while Horizon stands down for StarUI. STATE then sends keys=0 hide=0
      //    find=0, so the DLL lets those keys and their characters reach the game.
      private function hotkeysAllowed():Boolean
      {
         if(this.conflict || this.kit == null) { return false; }
         if(this.nativeOn("ShipRename_mc") || this.nativeOn("HangarInfoPanel_mc")) { return false; }
         var focus:InteractiveObject = stage != null ? stage.focus : null;
         var field:TextField = focus as TextField;
         if(field != null && field.type == TextFieldType.INPUT && !this.contains(field)) { return false; }
         return true;
      }

      private function onChar(param1:int):void
      {
         if(this.textOwner != null) { this.textOwner.onChar(param1); }
      }

      // Controller events while a Horizon popup is open.
      private function padEvent(param1:String):void
      {
         if(this.arrange != null && this.arrange.visible)
         {
            var nudge:Object = {"Up":"up","Down":"down","Left":"left","Right":"right","LShoulder":"tabprev","RShoulder":"tab"};
            if(nudge[param1] != null) { this.arrange.key(String(nudge[param1])); }
            return;
         }
         var top:HsbBox = this.topPop();
         var map:Object = {"Up":"up","Down":"down","Left":"left","Right":"right","LShoulder":"tabprev","RShoulder":"tab","XButton":"x","YButton":"y"};
         if(top == null)
         {
            if(this.gridOpen() && map[param1] != null) { this.browser.onKey(String(map[param1])); }
            return;
         }
         if(map[param1] != null) { top.onKey(String(map[param1])); }
         else if(param1 != "Accept" && param1 != "Cancel" && param1 != "Escape" && param1 != "Enter" && this.debugOn) { this.note("PAD unhandled " + param1); }
      }

      internal function cancelTop(param1:String):void
      {
         if(this.frameN - this.lastCancel < DOUBLE_FRAMES) { return; }
         this.lastCancel = this.frameN;
         if(this.textOwner != null && this.textOwner.onKey("cancel")) { return; }
         if(this.arrange != null && this.arrange.visible) { this.arrange.cancel(); return; }
         var top:HsbBox = this.topPop();
         if(top != null)
         {
            if(!top.onKey("cancel")) { this.closePop(top,false); }
            return;
         }
         if(this.gridOpen()) { this.browser.closeGrid(); }
      }

      internal function acceptTop(param1:String):void
      {
         if(this.frameN - this.lastOk < DOUBLE_FRAMES) { return; }
         this.lastOk = this.frameN;
         if(this.textOwner != null && this.textOwner.onKey("ok")) { return; }
         if(this.arrange != null && this.arrange.visible) { this.arrange.ok(); return; }
         var top:HsbBox = this.topPop();
         if(top != null) { top.onKey("ok"); return; }
         if(this.gridOpen()) { this.browser.onKey("ok"); }
      }

      // Central actions for the simple panels; popups and the browser handle their own ids.
      internal function act(param1:HsbBox, param2:String, param3:*):void
      {
         if(param1 != this.power && param1 != this.card && param1 != this.cluster && param1 != this.credits && param1 != this.hints && param1 != this.stats)
         {
            param1.onAct(param2,param3);
            return;
         }
         switch(param2)
         {
            case "gear": this.openSettings(); break;
            case "hide": this.toggleHide(); break;
            case "hint": this.sendHint(String(param3)); break;
            default:
               var dot:int = param2.indexOf(".");
               if(dot > 0)
               {
                  var id:String = param2.substring(0,dot);
                  var ids:Object = {"power":"Power","module":"Module","credits":"Credits","stats":"Stats","hints":"Hints"};
                  if(ids[id] != null) { this.setCollapsed(String(ids[id]),param2.substring(dot + 1) == "close"); }
               }
         }
      }

      internal function setCollapsed(param1:String, param2:Boolean):void
      {
         // Opening any tab while everything is folded means Show all.
         if(!param2 && this.hideAll) { this.toggleHide(); }
         if(param2) { this.collapsed[param1] = true; }
         else { delete this.collapsed[param1]; }
         this.mark(param1);
         if(param1 == "Credits") { this.mark("Cluster"); }
         if(param1 == "Power") { this.mark("Module"); }
         if(this.rememberLayout)
         {
            this.setSetting("Panels",param1,param2 ? "0" : "1");
            this.saveSettings();
         }
      }

      internal function toggleHide():void
      {
         this.hideAll = !this.hideAll;
         this.markAll();
         this.note("HIDEALL " + (this.hideAll ? 1 : 0));
      }

      internal function beginText(param1:HsbBox):void
      {
         this.textOwner = param1;
      }

      internal function endText(param1:HsbBox):void
      {
         if(this.textOwner == param1) { this.textOwner = null; }
      }

      internal function textActive(param1:HsbBox):Boolean
      {
         return this.textOwner == param1;
      }

      // ---- popups --------------------------------------------------------------------------

      internal function topPop():HsbBox
      {
         return this.pops.length > 0 ? this.pops[this.pops.length - 1] as HsbBox : null;
      }

      internal function openPop(param1:HsbBox):void
      {
         // Find keeps its text but stops typing, so ESC closes the popup instead of clearing
         // the search, and a popup with its own field gets the keyboard cleanly.
         if(this.browser != null) { this.browser.endFind(); }
         var at:int = this.pops.indexOf(param1);
         if(at >= 0) { this.pops.splice(at,1); }
         this.pops.push(param1);
         param1.scaleX = this.uiScale;
         param1.scaleY = this.uiScale;
         this.popLayer.addChild(param1);
         param1.visible = true;
         this.place();
      }

      internal function closePop(param1:HsbBox, param2:Boolean):void
      {
         var at:int = this.pops.indexOf(param1);
         if(at < 0) { return; }
         this.pops.splice(at,1);
         if(this.textOwner == param1) { this.textOwner = null; }
         param1.onClose(param2);
         if(param1.parent != null) { param1.parent.removeChild(param1); }
         this.kit.forget(param1);
         this.place();
      }

      private function placePops(param1:Object):void
      {
         var i:int = 0;
         while(i < this.pops.length)
         {
            var p:HsbBox = this.pops[i] as HsbBox;
            var pw:Number = p.boxW * p.scaleX;
            var ph:Number = p.boxH * p.scaleY;
            if(p.anchorX < 0)
            {
               p.x = param1.x + (param1.width - pw) / 2;
               p.y = param1.y + Math.max(14,(param1.height - ph) / 2);
            }
            else
            {
               p.x = clampNum(p.anchorX,param1.x + 8,param1.x + param1.width - pw - 8,p.anchorX);
               p.y = clampNum(p.anchorY,param1.y + 8,param1.y + param1.height - ph - 8,p.anchorY);
            }
            i++;
         }
      }

      internal function openSettings():void
      {
         if(this.colors.previewing) { return; }
         var s:HsbSettings = new HsbSettings(this.kit,this);
         s.anchorX = this.cluster.x - 107 * this.uiScale;
         s.anchorY = this.cluster.y + (this.cluster.boxH + 11) * this.uiScale;
         this.openPop(s);
         s.paint();
         this.place();
         this.note("SETTINGS open");
      }

      internal function openArrange():void
      {
         if(this.conflict) { return; }
         while(this.pops.length > 0) { this.closePop(this.topPop(),false); }
         if(this.arrange == null)
         {
            this.arrange = new HsbArrange(this.kit,this);
            addChild(this.arrange);
         }
         this.arrange.open();
         this.note("ARRANGE open");
      }

      internal function arrangeBoxes():Array
      {
         var out:Array = [];
         var labels:Object = {"Power":"POWER","Module":"SELECTED MODULE","Credits":"CREDITS","Browser":"PARTS BROWSER","Stats":"STATS","Hints":"HINTS","Cluster":"TOP CLUSTER"};
         var i:int = 0;
         while(i < PANELS.length)
         {
            var id:String = String(PANELS[i]);
            var list:Array = this.boxesFor(id);
            var lead:HsbBox = null;
            var k:int = 0;
            while(k < list.length)
            {
               if((list[k] as HsbBox).visible) { lead = list[k] as HsbBox; break; }
               k++;
            }
            if(lead != null && lead.boxW > 0)
            {
               out.push({"id":id,"label":labels[id],"box":lead,"x":lead.x,"y":lead.y,"w":lead.boxW * lead.scaleX,"h":lead.boxH * lead.scaleY});
            }
            i++;
         }
         return out;
      }

      internal function moveBox(param1:String, param2:Number, param3:Number):void
      {
         var list:Array = this.boxesFor(param1);
         var i:int = 0;
         while(i < list.length)
         {
            (list[i] as HsbBox).x = param2;
            (list[i] as HsbBox).y = param3;
            i++;
         }
      }

      internal function storeAnchor(param1:String, param2:Number, param3:Number, param4:Number, param5:Number):void
      {
         var r:Object = this.viewRect();
         var midX:Number = param2 + param4 / 2;
         var midY:Number = param3 + param5 / 2;
         var cx:Number = r.x + r.width / 2;
         var cy:Number = r.y + r.height / 2;
         var ax:String = "C";
         var dx:Number = Math.round(param2 - (cx - param4 / 2));
         if(Math.abs(midX - cx) >= r.width / 6)
         {
            if(midX < cx) { ax = "L"; dx = Math.round(param2 - (r.x + this.margin)); }
            else { ax = "R"; dx = Math.round(r.x + r.width - this.margin - param4 - param2); }
         }
         var ay:String = "C";
         var dy:Number = Math.round(param3 - (cy - param5 / 2));
         if(Math.abs(midY - cy) >= r.height / 6)
         {
            if(midY < cy) { ay = "T"; dy = Math.round(param3 - (r.y + this.margin)); }
            else { ay = "B"; dy = Math.round(r.y + r.height - this.margin - param5 - param3); }
         }
         this.lay[param1 + "X"] = ax + String(int(dx));
         this.lay[param1 + "Y"] = ay + String(int(dy));
      }

      internal function arrangeDone(param1:Boolean, param2:Object, param3:Number, param4:Number):void
      {
         if(param1)
         {
            var i:int = 0;
            while(i < PANELS.length)
            {
               var id:String = String(PANELS[i]);
               var x:String = this.lay[id + "X"] != null ? String(this.lay[id + "X"]) : "-1";
               var y:String = this.lay[id + "Y"] != null ? String(this.lay[id + "Y"]) : "-1";
               this.note("ARRANGE " + id + "X=" + x);
               this.note("ARRANGE " + id + "Y=" + y);
               i++;
            }
            this.barDx = param3;
            this.barDy = param4;
            this.note("ARRANGE ArrangeBarX=" + int(param3));
            this.note("ARRANGE ArrangeBarY=" + int(param4));
            this.note("ARRANGE END");
         }
         else
         {
            this.lay = param2;
         }
         this.place();
         this.note(param1 ? "ARRANGE saved" : "ARRANGE cancel");
      }

      internal function resetLayout():void
      {
         this.lay = {};
         this.place();
      }

      // Purpose: forget the saved Arrange layout in the user ini (Reset all settings).
      // Inputs: none. Outputs: ARRANGE lines with -1 (default spot) and a zero bar offset.
      // Dependencies: the DLL's ARRANGE merge (HorizonShipBuilder.user.ini [Layout]).
      internal function clearLayoutSaved():void
      {
         var i:int = 0;
         while(i < PANELS.length)
         {
            this.note("ARRANGE " + String(PANELS[i]) + "X=-1");
            this.note("ARRANGE " + String(PANELS[i]) + "Y=-1");
            i++;
         }
         this.barDx = 0;
         this.barDy = 0;
         this.note("ARRANGE ArrangeBarX=0");
         this.note("ARRANGE ArrangeBarY=0");
         this.note("ARRANGE END");
      }

      // ---- files ---------------------------------------------------------------------------

      // Purpose: queue a request for the DLL's file job. The DLL accepts only the builder's own
      //    folders (pills, packs, schemes, the pill profile) and sanitized file names.
      // Inputs: kind (PILLS, SCHEMES, PROFILE), verb plus arguments, body text, reply callback
      //    function(ok:Boolean, payload:String).
      // Outputs: none now; the callback runs when files() receives the reply.
      internal function fileOp(param1:String, param2:Array, param3:String, param4:Function):void
      {
         this.fileSeq++;
         var id:String = "f" + this.fileSeq;
         if(param4 != null) { this.fileWait[id] = param4; }
         var parts:Array = [id,param1].concat(param2);
         var clean:Array = [];
         var i:int = 0;
         while(i < parts.length)
         {
            clean.push(String(parts[i]).split("\t").join(" ").split("\n").join(" "));
            i++;
         }
         this.fileOut.push(clean.join("\t") + "\t" + escapeText(param3));
         // The DLL drains this every frame, so a full queue means the DLL is not answering.
         // The oldest request fails at once rather than waiting for a reply that cannot come.
         if(this.fileOut.length > FILE_QUEUE_MAX)
         {
            var dropped:String = String(this.fileOut.shift());
            var dropId:String = dropped.substring(0,dropped.indexOf("\t"));
            var dropCb:Function = this.fileWait[dropId] as Function;
            delete this.fileWait[dropId];
            this.note("FILE queue full dropped=1");
            if(dropCb != null)
            {
               try { dropCb(false,""); }
               catch(err:Error) { this.note("FILE reply failed " + err.errorID); }
            }
         }
      }

      internal static function escapeText(param1:String):String
      {
         if(param1 == null) { return ""; }
         return param1.split("\\").join("\\\\").split("\r").join("").split("\n").join("\\n").split("\t").join("\\t");
      }

      internal static function unescapeText(param1:String):String
      {
         var out:String = "";
         var i:int = 0;
         while(i < param1.length)
         {
            var c:String = param1.charAt(i);
            if(c == "\\" && i + 1 < param1.length)
            {
               var n:String = param1.charAt(i + 1);
               out += n == "n" ? "\n" : (n == "t" ? "\t" : n);
               i += 2;
               continue;
            }
            out += c;
            i++;
         }
         return out;
      }

      // Purpose: take the pill profile the DLL read at open. Inputs: the reply (ok, text); on a
      //    failed read the text is "missing", "damaged" or "unreadable". Outputs: the loaded
      //    pills, or the defaults with saving locked when a profile exists that the movie cannot
      //    use. Saving stays locked ("loading") until this reply, so an early edit never
      //    replaces the file.
      // Rules: only "missing" (or an empty or blank file) may start fresh and be saved over; the
      //    DLL then keeps ShipBuilderPills.bak as it was for the visit, and an empty or blank
      //    file says so on screen. A damaged profile (one that does not parse, or "damaged": a
      //    NUL byte) is set aside by the DLL (PROFILE BAD), and saving stays locked ("setaside")
      //    until the DLL confirms it is out of the way (onSetAside). One that could not be read,
      //    is too long to parse, comes from a newer version or that the model failed to take in
      //    is left as it is and never saved over. A save refused while loading runs when saving
      //    opens on the pills on screen; a profile that loads replaces them, and a line says so.
      private function onProfile(param1:Boolean, param2:String):void
      {
         if(!param1)
         {
            if(param2 == "damaged") { this.setAsideProfile(); }
            else
            {
               this.pillsBakKept = param2 == "missing";
               this.lockPills(param2 == "missing" ? "" : "unreadable");
               this.note("PILLS profile " + (param2 == "missing" ? "none" : "unreadable, saving off"));
               if(param2 == "missing") { this.runWaitingSave(); }
            }
            return;
         }
         if(isBlank(param2))
         {
            this.pillsEmpty = true;
            this.pillsBakKept = true;
            this.lockPills("");
            this.note("PILLS profile empty");
            this.runWaitingSave();
            return;
         }
         var count:int = this.pills.load(param2);
         if(count >= 0)
         {
            this.pillsLock = "";
            this.pillsDropped = this.pillsWaiting;
            this.pillsWaiting = false;
            this.note("PILLS profile loaded n=" + count + (this.pillsDropped ? ", earlier changes dropped" : ""));
         }
         else if(count == HsbPillModel.LOAD_BAD) { this.setAsideProfile(); }
         else if(count == HsbPillModel.LOAD_FAILED)
         {
            this.lockPills("loadfailed");
            this.note("PILLS profile load failed, saving off");
         }
         else
         {
            this.lockPills(count == HsbPillModel.LOAD_NEWER ? "newer" : "toolong");
            this.note("PILLS profile " + (count == HsbPillModel.LOAD_NEWER ? "newer" : "too long") + ", saving off");
         }
         this.browser.invalidate();
      }

      // Asks the DLL to set the damaged profile aside; saving waits for its answer.
      private function setAsideProfile():void
      {
         this.lockPills("setaside");
         this.note("PILLS profile bad, setting it aside");
         this.fileOp("PROFILE",["BAD"],"",this.onSetAside);
      }

      // Purpose: take the DLL's answer to PROFILE BAD. Inputs: ok, and on a failure the reason:
      //    "exists" when a ShipBuilderPills.bad.json is already there, otherwise "failed".
      // Outputs: on ok, saving opens with the starter pills, the DLL keeps ShipBuilderPills.bak
      //    as it was for the visit, and a save refused meanwhile runs. On a failure, saving
      //    stays locked for this visit and the damaged file stays where it is; the next visit
      //    tries again.
      private function onSetAside(param1:Boolean, param2:String):void
      {
         if(!param1)
         {
            this.lockPills(param2 == "exists" ? "badexists" : "badfailed");
            this.note("PILLS profile set aside failed " + (param2 == "exists" ? "exists" : "error") + ", saving off");
            return;
         }
         this.pillsSetAside = true;
         this.pillsBakKept = true;
         this.lockPills("");
         this.note("PILLS profile set aside");
         this.runWaitingSave();
      }

      // Runs a save refused while saving was locked, once saving opens on the pills on screen.
      private function runWaitingSave():void
      {
         if(!this.pillsWaiting) { return; }
         this.pillsWaiting = false;
         this.savePills();
      }

      private function lockPills(param1:String):void
      {
         this.pillsLock = param1;
         if(this.browser != null) { this.browser.invalidate(); }
      }

      // True for text with nothing but JSON whitespace (spaces, tabs, line ends), as the DLL's
      // ProfileBlank: such a profile holds no pills.
      internal static function isBlank(param1:String):Boolean
      {
         return param1 == null || /^[ \t\r\n]*$/.test(param1);
      }

      // The lines the browser shows while pill changes cannot be saved, or after the profile
      // was set aside or empty; empty when there is nothing to say. Lines are joined by "\n".
      internal function pillsWarning():String
      {
         switch(this.pillsLock)
         {
            case "loading": return this.pillsWaiting ? "Pill changes wait: the pills file is still loading" : "";
            case "setaside": return "Pill changes wait: the damaged pills file is being set aside";
            case "badexists": return "Pill changes are not saved: the pills file is damaged\nMove ShipBuilderPills.bad.json away, then reopen the builder\nIt is in Data\\Interface\\HorizonUI\\shipbuilder\\";
            case "badfailed": return "Pill changes are not saved: the pills file is damaged\nIt could not be renamed to ShipBuilderPills.bad.json\nClose programs using the pills file, then reopen the builder";
            case "unreadable": return "Pill changes are not saved: the pills file could not be read";
            case "loadfailed": return "Pill changes are not saved: the pills file could not be loaded";
            case "newer": return "Pill changes are not saved: the pills file is from a newer version";
            case "toolong": return "Pill changes are not saved: the pills file is too long to read";
            case "full": return "Pill changes are not saved: too many pills and rules for one file";
            case "unsavable": return "Pill changes are not saved: a pill holds data the file cannot keep";
         }
         if(this.pillsSaveFailed) { return "Pill changes are not saved: the pills file could not be written"; }
         if(this.pillsDropped) { return "Pill changes made while the pills file loaded were not kept"; }
         if(this.pillsSetAside) { return "The damaged pills file is kept as ShipBuilderPills.bad.json\nAn older copy may be in ShipBuilderPills.bak"; }
         if(this.pillsEmpty) { return "The pills file was empty, so the starter pills are shown\nAn older copy may be in ShipBuilderPills.bak"; }
         return "";
      }

      // Purpose: write the pill profile. Inputs: the pill model. Outputs: one PROFILE WRITE, or
      //    none while saving is locked; a failed reply to the latest save shows pillsWarning's
      //    "could not be written" line until a later save succeeds. Rule: the movie never
      //    writes what its own reader would refuse (longer than HsbJson.MAX_CHARS, or text
      //    HsbJson.parse rejects), so a saved profile always loads again. "full" and
      //    "unsavable" clear on the next save that passes, so removing the pills that caused
      //    them unlocks saving. A save refused while the profile loads, or while the damaged
      //    profile is being set aside, waits for that (runWaitingSave).
      internal function savePills():void
      {
         var retry:Boolean = this.pillsLock == "full" || this.pillsLock == "unsavable";
         if(this.pillsLock.length > 0 && !retry)
         {
            if((this.pillsLock == "loading" || this.pillsLock == "setaside") && !this.pillsWaiting)
            {
               this.pillsWaiting = true;
               if(this.browser != null) { this.browser.invalidate(); }
            }
            this.note("PILLS save refused " + this.pillsLock);
            return;
         }
         var text:String = this.pills.save();
         if(text.length > HsbJson.MAX_CHARS)
         {
            this.lockPills("full");
            this.note("PILLS save refused toolong");
            return;
         }
         if(HsbJson.parse(text) == null)
         {
            this.lockPills("unsavable");
            this.note("PILLS save refused unreadable");
            return;
         }
         if(retry) { this.lockPills(""); }
         var seq:int = ++this.pillsSaveSeq;
         this.fileOp("PROFILE",["WRITE"],text,function(param1:Boolean, param2:String):void
         {
            note("PILLS save " + (param1 ? "ok" : "failed") + (seq != pillsSaveSeq ? ", a later save decides" : ""));
            if(seq != pillsSaveSeq) { return; }
            var was:String = pillsWarning();
            pillsSaveFailed = !param1;
            if(param1) { pillsDropped = false; }
            if(browser != null && pillsWarning() != was) { browser.invalidate(); }
         });
      }

      // ---- helpers -------------------------------------------------------------------------

      internal static function clampInt(param1:int, param2:int, param3:int):int
      {
         return param1 < param2 ? param2 : (param1 > param3 ? param3 : param1);
      }

      internal static function clampNum(param1:Number, param2:Number, param3:Number, param4:Number):Number
      {
         if(isNaN(param1)) { return param4; }
         if(param3 < param2) { return param2; }
         return param1 < param2 ? param2 : (param1 > param3 ? param3 : param1);
      }

      internal function frame():int
      {
         return this.frameN;
      }

      internal function partCredits():Number
      {
         return this.dCost != null ? Number(this.dCost.uPlayerCredits) : NaN;
      }

      internal function note(param1:String):void
      {
         var clean:String = param1.split("\n").join(" ").split("\r").join(" ");
         this.lines.push(clean);
         while(this.lines.length > LOG_CAP) { this.lines.shift(); }
      }
   }
}
