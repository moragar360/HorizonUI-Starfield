package
{
   import Shared.AS3.BSScrollingConfigParams;
   import Shared.AS3.BSScrollingContainer;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.Events.ScrollingEvent;
   import flash.display.DisplayObject;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.Event;
   import flash.events.IOErrorEvent;
   import flash.events.KeyboardEvent;
   import flash.events.MouseEvent;
   import flash.events.TimerEvent;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import scaleform.gfx.Extensions;
   import flash.filters.GlowFilter;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol117")]
   public final class DialogueMenu extends DialogueMenuBase
   {
      
      public function DialogueMenu()
      {
         super();
         try { this.hzdInit(); } catch(hzdErr:Error) { }
      }
      
      override protected function GetDialogListParams() : BSScrollingConfigParams
      {
         var _loc1_:BSScrollingConfigParams = null;
         _loc1_ = new BSScrollingConfigParams();
         _loc1_.VerticalSpacing = 4;
         _loc1_.EntryClassName = "DialogueScrollingListEntry";
         _loc1_.MultiLine = true;
         return _loc1_;
      }

      // ===================== Horizon UI Comms (Dialogue) v0.42.0 =====================
      // v0.40: no behavior change
      // v0.39: no behavior change
      // v0.38: the choices card is titled with the name of the character you are talking to (sSpeakerName from the
      // game's dialogue data, upper case), "RESPOND" when the game gives no name; PERSUADE stays PERSUADE. A long name
      // is cut with "..." before it reaches the "1 OF 5" counter.
      // v0.37: settings come from HorizonUI.default.ini with HorizonUI.user.ini laid over it (legacy HorizonUI.ini without
      // a default file), read by the shared helper below (hzd37IniRead), the same code as the HUD and HUD messages.
      // Re-read on every conversation start as before, so F11 SAVE / preset APPLY / RESTORE arrive with the next one.
      // v0.35: DlgSaidStyle HIDDEN: the shown-row view is re-derived before every draw (+ a 0.3 s watch while open) from
      // every known spelling of the already-said flag; v0.34 built it only on a state change
      // v0.34: Horizon button bar under the dialogue card (DlgButtonBar 0 Horizon / 1 vanilla / 2 hidden): the vanilla
      // ButtonBar_mc gets alpha 0 + mouse off (never removed, never visible=false); the pills mirror the vanilla buttons'
      // Visible / Enabled / FillPercent and their resolved key + label text, and a click calls the vanilla handler
      // (onCancelClick / onAutoWinClick). Keyboard + controller input still goes through the vanilla bar. Number keycaps
      // and bar keycaps share one full-ring routine (4 bars + 4 quarter rings, separate opaque fills, pixel grid).
      // DlgFont / FontFace 3 = the game's own semibold face, looked up by name at run time (never bundled).
      // v0.33: DlgOffsetX / DlgOffsetY apply on top of the ARRANGE position too, DlgScale (window size: width, padding and
      // text; DlgTextSize multiplies the option text on top; the option text steps down to 0.7 x only if all options would
      // not fit the screen height), DlgBgColor (HUD card colors + DlgBgHex), DlgTextColor (like SubTextColor).
      // v0.32: DlgCard (panel art on/off), DlgVisible 0 = all (N MORE only with a limit), the "1 OF 5" counter inside the
      // header, keycap outlines as pixel-snapped filled shapes in an overlay (no clipped strokes), DlgOffsetX, card art on
      // its own Shape with a stroked edge, and the ini is re-read when a conversation opens (Arrange / F11 changes apply).
      // ORIGINAL CODE (Horizon UI). Added as members of the vanilla DialogueMenu class (it extends DialogueMenuBase) by
      // apply_comms_hooks.ps1, plus one call in the constructor. The hooks are overrides of DialogueMenuBase's protected
      // methods, each calling super first, so the vanilla code is not edited. The vanilla list stays the selection + protocol
      // engine (focus, keys, controller, IgnoreListInputTimer, the DialogueMenu_OnDialogueSelect dispatch); Horizon only calls
      //   select:  <list>.selectedIndex = i   (BSScrollingContainer setter -> SetSelectedIndex, D-T2)
      //   press:   this.onItemPress()         (DialogueMenuBase -> m_State(LIST_ITEM_PRESS), D-T2)
      // and never dispatches a game event, changes state or skips a vanilla timeline (addendum 7).
      private static const HZD_LRG:Boolean = true;
      private static const HZD_ACC:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZD_SEMI:String = "$NB_Grotesk_Semibold";   // the game's own semibold face (run-time name only)
      private static const HZD_AMB:uint = 0xF2B45F;
      private static const HZD_OK:uint = 0x5EE3A1;
      private static const HZD_BAD:uint = 0xFF5B5B;
      private static const HZD_DIFF:Array = [0x6FD39A,0xF2B45F,0xF27A5F];
      private static const HZD_STR:Object = {"AccentHex":1,"DialogueX":1,"DialogueY":1,"DlgBgHex":1,"DlgTextHex":1};
      private static const HZD_BG:Array = [0x0B1218,0x16181C,0x0B1630,0x0A2226,0x1E1328,0x2A1014,0x3A4652,0xD5DBE0,0xF2F4F6,0xCCDFEE,0xF0E0C2,0xD2ECDF];   // = the HUD card colors
      private var hzdCfg:Object = {"Dialogue":1,"DlgAutoPause":1,"DlgLayout":0,"DlgVisible":0,"DlgCard":1,"DlgOffsetX":0,"DlgOffsetY":0,"DlgScale":1,"DlgBgColor":0,"DlgBgHex":"","DlgTextColor":-1,"DlgTextHex":"","DlgMoreHint":1,"DlgTextSize":1,"DlgFont":-1,"DlgBgOpacity":0.85,"DlgNumberKeys":1,"DlgWheel":1,"DlgHoverScroll":0,"DlgSaidStyle":2,"DlgPersuadeStyle":0,"DlgPersuadeColor":2,"DlgPersuasionMeter":1,"DlgMarkers":0,"DlgInputDelay":150,"DlgRolloverSound":0,"DlgAnim":1,"DlgButtonBar":0,"DlgQuickPickHint":1,"DlgSelectHint":1,"SpeakerCard":1,"HzRev":0,"FontFace":1,"AccentColor":0,"AccentHex":"","TextScale":1,"ScreenHeight":0,"Margin":40,"DialogueX":"-1","DialogueY":"-1"};
      private var hzdIni:int = 0;            // 0 loading, 1 loaded, 2 missing (defaults)
      private var hzdProbe:Object = {};      // edi / edi2 / font: 1 found, 0 not found
      private var hzdOn:Boolean = false;     // Horizon list in charge
      private var hzdLayer:Sprite = null;
      private var hzdPanel:Sprite = null;
      private var hzdSpk:Sprite = null;
      private var hzdView:Array = [];        // vanilla list indices shown, in order
      private var hzdViewSig:String = "";    // v0.35: style + said flags the view was built from
      private var hzdSaidT:Timer = null;     // v0.35: 0.3 s watch for said flags that change while the list is open
      private var hzdSel:int = 0;            // index into hzdView
      private var hzdTop:int = 0;
      private var hzdPers:Boolean = false;
      private var hzdOpen:Boolean = false;
      private var hzdWho:String = "";
      private var hzdAnimT0:int = 0;
      private var hzdHoverT:Timer = null;
      private var hzdHoverDir:int = 0;
      private var hzdGameFont:String = null;
      private var hzdFontOk:Object = {};
      private var hzdRevTxt:String = null;   // last ini text applied
      private var hzdReloadT:int = -100000;
      private var hzdBare:Boolean = false;   // DlgCard=0 while drawing

      private function hzdInit() : void
      {
         this.hzdLayer = new Sprite();
         this.hzdLayer.visible = false;
         this.hzdPanel = new Sprite();
         this.hzdSpk = new Sprite();
         this.hzdSpk.mouseEnabled = false; this.hzdSpk.mouseChildren = false;
         this.hzdLayer.addChild(this.hzdSpk);
         this.hzdLayer.addChild(this.hzdPanel);
         this.hzdBar = new Sprite();
         this.hzdBar.visible = false;
         this.hzdLayer.addChild(this.hzdBar);
         addChild(this.hzdLayer);
         try { this.hzdPmEnsure(); } catch(ePm:Error) { }
         // D10 / D11: the vanilla bar is set up by DialogueMenuBase's constructor (super() already ran). Read-only
         // mirroring: its redraw event + the button-state overrides below; clicks call the vanilla handlers.
         try { this.ButtonBar_mc.addEventListener("ButtonBarRedrawnEvent",this.hzdOnBarRedrawn); } catch(e1:Error) { }
         try { BSUIDataManager.Subscribe("ControlMapData",this.hzdOnCtl); } catch(e2:Error) { }
         this.hzdPanel.addEventListener(MouseEvent.MOUSE_WHEEL,this.hzdOnWheel);
         this.DialogueList_mc.addEventListener(ScrollingEvent.SELECTION_CHANGE,this.hzdOnVanillaSel);
         this.PersuasionList_mc.addEventListener(ScrollingEvent.SELECTION_CHANGE,this.hzdOnVanillaSel);
         addEventListener(Event.ADDED_TO_STAGE,this.hzdOnStage);
         if(stage != null) { this.hzdOnStage(null); }
         this.hzdIniLoad();
         this.hzdLoad("Enhanced Dialogue Interface - My Edits.ini","edi");
         this.hzdLoad("Enhanced Dialogue Interface.ini","edi2");
         this.hzdLoad("HorizonUI/modules/font.marker","font");
         try { this.hzdSaidT = new Timer(300); this.hzdSaidT.addEventListener(TimerEvent.TIMER,this.hzdOnSaidT); this.hzdSaidT.start(); } catch(eSt:Error) { }
      }
      private function hzdOnStage(e:Event) : void
      {
         try { stage.addEventListener(KeyboardEvent.KEY_DOWN,this.hzdOnKey); } catch(err:Error) { }
      }
      // v0.37: merged default + user settings -> hzdLoaded("ini", text or null)
      private function hzdIniLoad() : void
      {
         try { this.hzd37IniRead(this.hzdOnIniTxt); } catch(err:Error) { this.hzdLoaded("ini",null); }
      }
      private function hzdOnIniTxt(txt:String) : void { this.hzdLoaded("ini",txt); }
      private function hzdLoad(path:String, id:String) : void
      {
         try
         {
            var l:URLLoader = new URLLoader();
            var self:* = this;
            l.addEventListener(Event.COMPLETE,function(e:Event):void { self.hzdLoaded(id,String(l.data)); });
            l.addEventListener(IOErrorEvent.IO_ERROR,function(e:Event):void { self.hzdLoaded(id,null); });
            l.addEventListener("securityError",function(e:Event):void { self.hzdLoaded(id,null); });
            l.load(new URLRequest(path));
         }
         catch(err:Error) { this.hzdLoaded(id,null); }
      }
      public function hzdLoaded(id:String, txt:String) : void
      {
         try
         {
            if(id == "ini")
            {
               if(txt == null && this.hzdIni == 1) { return; }            // a failed re-read keeps the last good values
               if(txt != null && this.hzdIni == 1 && txt == this.hzdRevTxt) { return; }   // unchanged
               this.hzdRevTxt = txt;
               this.hzdIni = txt == null ? 2 : 1;
               if(txt != null) { this.hzdParse(txt); }
            }
            else { this.hzdProbe[id] = txt == null ? 0 : 1; }
            this.hzdFontOk = {};
            this.hzdRefresh();
         }
         catch(err:Error) { }
      }
      // re-read the settings (throttled); a changed merged text (Arrange save, F11, HzRev bump) is applied in hzdLoaded
      private function hzdReload() : void
      {
         if(this.hzdIni == 0 || getTimer() - this.hzdReloadT < 1000) { return; }
         this.hzdReloadT = getTimer();
         this.hzdIniLoad();
      }
      private function hzdParse(t:String) : void
      {
         var sec:String = "";
         for each(var raw:String in t.split("\r").join("").split("\n"))
         {
            var ln:String = raw.replace(/^[\s\uFEFF]+|\s+$/g,"");
            if(ln.length == 0 || ln.charAt(0) == ";" || ln.charAt(0) == "#") { continue; }
            if(ln.charAt(0) == "[") { var e:int = ln.indexOf("]"); sec = (e > 0 ? ln.substring(1,e) : ln.substr(1)).replace(/^\s+|\s+$/g,"").toLowerCase(); continue; }
            if(sec != "comms" && sec != "style" && sec != "layout") { continue; }
            var i:int = ln.indexOf("=");
            if(i <= 0) { continue; }
            var k:String = ln.substr(0,i).replace(/\s+$/,"");
            var v:String = ln.substr(i + 1);
            var c:int = v.indexOf(";");
            v = (c >= 0 ? v.substr(0,c) : v).replace(/^\s+|\s+$/g,"");
            if(this.hzdCfg[k] == undefined) { continue; }
            if(HZD_STR[k] != undefined) { this.hzdCfg[k] = v; continue; }
            var n:Number = Number(v);
            if(!isNaN(n)) { this.hzdCfg[k] = n; }
         }
      }
      // active once the ini and both EDI probes have answered (vanilla until then); Dialogue=0 or EDI + DlgAutoPause = vanilla
      private function hzdRefresh() : void
      {
         var ready:Boolean = this.hzdIni != 0 && this.hzdProbe.edi != undefined && this.hzdProbe.edi2 != undefined;
         var want:Boolean = ready && int(this.hzdCfg.Dialogue) == 1 && !(int(this.hzdCfg.DlgAutoPause) == 1 && (this.hzdProbe.edi === 1 || this.hzdProbe.edi2 === 1));
         this.hzdOn = want;
         try { this.IgnoreListInputTimer.delay = want ? Math.max(1,Math.min(1000,int(this.hzdCfg.DlgInputDelay))) : this.IGNORE_INPUT_ON_LIST_OPEN_TIME; } catch(e0:Error) { }
         this.hzdVanillaHide(this.DialogueList_mc,want);
         this.hzdVanillaHide(this.PersuasionList_mc,want);
         try { this.hzdBarApply(); } catch(eba:Error) { }
         this.hzdPmOff = false;
         this.hzdPmFail = 0;
         try { this.hzdPmApply(); } catch(epm:Error) { }
         if(!want) { this.hzdLayer.visible = false; this.hzdOpen = false; return; }
         this.hzdSyncState();
      }
      // alpha + mouse only; the list keeps focus, keys, timelines and its visible flag (addendum 5)
      private function hzdVanillaHide(l:DisplayObject, hide:Boolean) : void
      {
         try
         {
            l.alpha = hide ? 0 : 1;
            var s:Sprite = l as Sprite;
            if(s) { s.mouseEnabled = !hide; s.mouseChildren = !hide; }
         }
         catch(e:Error) { }
      }

      // ---------- hooks (overrides; vanilla first) ----------
      override protected function onChoiceListUpdate(param1:FromClientDataEvent) : void
      {
         super.onChoiceListUpdate(param1);
         try { this.hzdSyncState(); } catch(e:Error) { }
      }
      override protected function onPersuasionListUpdate(param1:FromClientDataEvent) : void
      {
         super.onPersuasionListUpdate(param1);
         try { this.hzdSyncState(); } catch(e:Error) { }
      }
      override protected function onDataUpdate(param1:FromClientDataEvent) : void
      {
         super.onDataUpdate(param1);
         try
         {
            this.hzdWho = param1.data.sSpeakerName != null ? String(param1.data.sSpeakerName) : "";
            this.hzdReload();
            if(param1.data.bClosingMenu) { this.hzdOpen = false; this.hzdLayer.visible = false; this.hzdPmData = null; this.hzdPmDrop(); try { this.hzdPmApply(); } catch(epm0:Error) { } return; }
            if(this.hzdOn) { this.hzdLayer.visible = true; this.hzdDrawSpeaker(); }
         }
         catch(e:Error) { }
      }
      override protected function TransitionToState(param1:Function) : void
      {
         super.TransitionToState(param1);
         try { this.hzdSyncState(); } catch(e:Error) { }
      }
      override protected function playFocusSound() : *
      {
         if(this.hzdOn && int(this.hzdCfg.DlgRolloverSound) == 1) { return; }
         super.playFocusSound();
      }

      // ---------- state ----------
      private function hzdList() : BSScrollingContainer
      {
         return this.hzdPers ? (this.PersuasionList_mc as BSScrollingContainer) : this.DialogueList_mc;
      }
      private function hzdSyncState() : void
      {
         var inChoice:Boolean = this.m_State == this.state_ChoiceList;
         var inPers:Boolean = this.m_State == this.state_PersuasionList;
         if(!this.hzdOn) { this.hzdOpen = false; this.hzdLayer.visible = false; try { this.hzdPmApply(); } catch(epm1:Error) { } return; }
         this.hzdLayer.visible = true;   // the speaker card shows for the whole conversation
         if(!(inChoice || inPers)) { this.hzdOpen = false; this.hzdPanel.visible = false; this.hzdDrawSpeaker(); try { this.hzdBarDraw(); } catch(eb0:Error) { } try { this.hzdPmApply(); } catch(epm2:Error) { } return; }
         this.hzdPanel.visible = true;
         this.hzdVanillaHide(this.DialogueList_mc,true);
         this.hzdVanillaHide(this.PersuasionList_mc,true);
         this.hzdPers = inPers;
         this.hzdBuildView();
         var cur:int = this.hzdView.indexOf(this.hzdList().selectedIndex);
         this.hzdSel = cur >= 0 ? cur : 0;
         this.hzdTop = 0;
         this.hzdKeepInView();
         if(cur < 0 && this.hzdView.length > 0) { this.hzdList().selectedIndex = int(this.hzdView[this.hzdSel]); }
         if(!this.hzdOpen) { this.hzdOpen = true; this.hzdAnimStart(); this.hzdReload(); }
         this.hzdDraw();
         this.hzdDrawSpeaker();
         try { this.hzdBarDraw(); } catch(eb1:Error) { }
         try { this.hzdPmApply(); } catch(epm3:Error) { }
      }
      private function hzdBuildView() : void
      {
         var l:BSScrollingContainer = this.hzdList();
         var said:Array = [];
         var i:int = 0;
         while(i < l.entryCount) { said.push(this.hzdSaid(l.GetDataForEntry(i))); i++; }
         this.hzdView = this.hzdViewOf(said,int(this.hzdCfg.DlgSaidStyle) == 1 && !this.hzdPers);
         this.hzdViewSig = this.hzdSigOf(said);
      }
      // v0.35: the already-said flag of one entry. The 1.16 export names it bWasAlreadySaid (DialogueEntryBase); the
      // other spellings, numbers and "true" strings are accepted too, so a data change in a game update cannot silently
      // turn HIDDEN into "nothing hidden"
      private function hzdSaid(d:Object) : Boolean
      {
         if(d == null) { return false; }
         for each(var n:String in ["bWasAlreadySaid","bAlreadySaid","bSaid","wasAlreadySaid","alreadySaid"])
         {
            var v:* = d[n];
            if(v === undefined || v === null) { continue; }
            if(v is Boolean) { return Boolean(v); }
            var t:String = String(v).toLowerCase();
            return t == "true" || (Number(t) > 0);
         }
         return false;
      }
      // the shown rows as vanilla indices (pure: said flags in, view out). Never empty while there are options
      private function hzdViewOf(said:Array, hide:Boolean) : Array
      {
         var v:Array = [];
         var i:int = 0;
         while(i < said.length) { if(!(hide && said[i] === true)) { v.push(i); } i++; }
         if(v.length == 0) { i = 0; while(i < said.length) { v.push(i); i++; } }   // never hide everything
         return v;
      }
      private function hzdSigOf(said:Array) : String
      {
         var s:String = String(int(this.hzdCfg.DlgSaidStyle)) + (this.hzdPers ? "p" : "c") + ":";
         for each(var b:Boolean in said) { s += b ? "1" : "0"; }
         return s;
      }
      private function hzdOnSaidT(e:TimerEvent) : void
      {
         try
         {
            if(!this.hzdOn || !this.hzdOpen) { return; }
            var l:BSScrollingContainer = this.hzdList();
            var said:Array = [];
            var i:int = 0;
            while(i < l.entryCount) { said.push(this.hzdSaid(l.GetDataForEntry(i))); i++; }
            if(this.hzdSigOf(said) != this.hzdViewSig) { this.hzdDraw(); }
         }
         catch(err:Error) { }
      }
      // v0.35: the view is checked again before every draw. v0.34 built it only on a state change, so a list whose said
      // flags (or the ini style) changed without a TransitionToState kept every row
      private function hzdViewCheck() : void
      {
         var l:BSScrollingContainer = this.hzdList();
         var said:Array = [];
         var i:int = 0;
         while(i < l.entryCount) { said.push(this.hzdSaid(l.GetDataForEntry(i))); i++; }
         if(this.hzdSigOf(said) == this.hzdViewSig) { return; }
         var vi:int = l.selectedIndex;
         this.hzdView = this.hzdViewOf(said,int(this.hzdCfg.DlgSaidStyle) == 1 && !this.hzdPers);
         this.hzdViewSig = this.hzdSigOf(said);
         var v:int = this.hzdView.indexOf(vi);
         if(v < 0)
         {
            v = 0;
            while(v < this.hzdView.length - 1 && int(this.hzdView[v]) < vi) { v++; }
            if(this.hzdView.length > 0) { l.selectedIndex = int(this.hzdView[v]); }
         }
         this.hzdSel = Math.max(0,Math.min(this.hzdView.length - 1,v));
         this.hzdKeepInView();
      }
      // DlgVisible: 0 = all options (the card sizes to its content), else 1 - 12 rows with scrolling
      private function hzdLimit() : int { var n:int = int(this.hzdCfg.DlgVisible); return n <= 0 ? 0 : Math.min(12,n); }
      private function hzdVis() : int { var n:int = this.hzdLimit(); return n == 0 ? 1000 : n; }
      private function hzdKeepInView() : void
      {
         var n:int = this.hzdVis();
         if(this.hzdSel < this.hzdTop) { this.hzdTop = this.hzdSel; }
         else if(this.hzdSel >= this.hzdTop + n) { this.hzdTop = this.hzdSel - n + 1; }
         this.hzdTop = Math.max(0,Math.min(Math.max(0,this.hzdView.length - n),this.hzdTop));
      }
      // keyboard / controller moved the vanilla selection: mirror it, stepping over Hidden rows
      private function hzdOnVanillaSel(e:Event) : void
      {
         try
         {
            if(!this.hzdOn || !this.hzdOpen) { return; }
            var vi:int = this.hzdList().selectedIndex;
            var v:int = this.hzdView.indexOf(vi);
            if(v < 0 && this.hzdView.length > 0)
            {
               var cur:int = int(this.hzdView[Math.min(this.hzdSel,this.hzdView.length - 1)]);
               var j:int = 0;
               v = this.hzdSel;
               if(vi > cur) { while(j < this.hzdView.length && int(this.hzdView[j]) < vi) { j++; } v = Math.min(j,this.hzdView.length - 1); }
               else { j = this.hzdView.length - 1; while(j >= 0 && int(this.hzdView[j]) > vi) { j--; } v = Math.max(j,0); }
               this.hzdList().selectedIndex = int(this.hzdView[v]);   // re-enters here once with a shown row
               return;
            }
            this.hzdSel = v;
            this.hzdKeepInView();
            this.hzdDraw();
            try { this.hzdPmApply(); } catch(epm4:Error) { }
         }
         catch(err:Error) { }
      }
      private function hzdSetSel(v:int) : void
      {
         if(this.hzdView.length == 0) { return; }
         v = Math.max(0,Math.min(this.hzdView.length - 1,v));
         if(v == this.hzdSel && this.hzdList().selectedIndex == int(this.hzdView[v])) { return; }
         this.hzdSel = v;
         this.hzdKeepInView();
         var before:int = this.hzdList().selectedIndex;
         this.hzdList().selectedIndex = int(this.hzdView[v]);
         if(this.hzdList().selectedIndex == before) { this.hzdDraw(); }   // otherwise SELECTION_CHANGE redraws
      }
      private function hzdChoose(v:int) : void
      {
         if(this.IgnoreListInputTimer.running) { return; }   // vanilla input delay
         this.hzdSetSel(v);
         this.onItemPress();                                   // vanilla press path (checks bCanBeChosen, dispatches, changes state)
      }
      private function hzdOnKey(e:KeyboardEvent) : void
      {
         try
         {
            if(!this.hzdOn || !this.hzdOpen || int(this.hzdCfg.DlgNumberKeys) != 1) { return; }
            var n:int = -1;
            if(e.keyCode >= 49 && e.keyCode <= 57) { n = e.keyCode - 49; }
            else if(e.keyCode >= 97 && e.keyCode <= 105) { n = e.keyCode - 97; }
            if(n < 0 || n >= this.hzdView.length) { return; }
            this.hzdChoose(n);
         }
         catch(err:Error) { }
      }
      private function hzdOnWheel(e:MouseEvent) : void
      {
         if(!this.hzdOn || int(this.hzdCfg.DlgWheel) != 1) { return; }
         this.hzdSetSel(this.hzdSel + (e.delta > 0 ? -1 : 1));
      }
      private function hzdOnRowOver(e:MouseEvent) : void
      {
         var v:int = int(Sprite(e.currentTarget).name.substr(3));
         this.hzdSetSel(v);
         this.hzdHoverDir = 0;
         if(int(this.hzdCfg.DlgHoverScroll) == 1)
         {
            if(v == this.hzdTop && this.hzdTop > 0) { this.hzdHoverDir = -1; }
            else if(v == this.hzdTop + this.hzdVis() - 1 && v < this.hzdView.length - 1) { this.hzdHoverDir = 1; }
            if(this.hzdHoverDir != 0)
            {
               if(this.hzdHoverT == null) { this.hzdHoverT = new Timer(250,1); this.hzdHoverT.addEventListener(TimerEvent.TIMER_COMPLETE,this.hzdOnHoverT); }
               this.hzdHoverT.reset(); this.hzdHoverT.start();
            }
         }
      }
      private function hzdOnRowOut(e:MouseEvent) : void { this.hzdHoverDir = 0; if(this.hzdHoverT) { this.hzdHoverT.reset(); } }
      private function hzdOnHoverT(e:TimerEvent) : void { if(this.hzdHoverDir != 0 && this.hzdOpen) { this.hzdSetSel(this.hzdSel + this.hzdHoverDir); } }
      private function hzdOnRowClick(e:MouseEvent) : void
      {
         try { this.hzdChoose(int(Sprite(e.currentTarget).name.substr(3))); } catch(err:Error) { }
      }

      // ---------- drawing (1080p units; addendum 3) ----------
      private function hzdAccent() : uint
      {
         var hx:String = String(this.hzdCfg.AccentHex);
         var ai:int = int(this.hzdCfg.AccentColor);
         if(ai >= HZD_ACC.length && hx.length == 7 && hx.charAt(0) == "#") { return uint(parseInt(hx.substr(1),16)); }
         return uint(HZD_ACC[Math.max(0,Math.min(HZD_ACC.length - 1,ai))]);
      }
      private function hzdFontProbe(n:String) : Boolean
      {
         if(this.hzdFontOk[n] != undefined) { return this.hzdFontOk[n] == 1; }
         var ok:Boolean = false;
         try
         {
            var t:TextField = new TextField(); t.embedFonts = true;
            var f:TextFormat = new TextFormat(n,20,0xFFFFFF); t.defaultTextFormat = f; t.text = "WMW"; t.setTextFormat(f);
            ok = t.textWidth > 8;
            if(ok)
            {
               var b:TextField = new TextField(); b.embedFonts = true;
               var bf:TextFormat = new TextFormat("$Horizon_NoSuchFace_x",20,0xFFFFFF); b.defaultTextFormat = bf; b.text = "WMW"; b.setTextFormat(bf);
               if(b.textWidth > 0 && Math.abs(b.textWidth - t.textWidth) < 0.01) { ok = false; }
            }
         }
         catch(e:Error) { ok = false; }
         this.hzdFontOk[n] = ok ? 1 : 0;
         return ok;
      }
      private function hzdGame() : String
      {
         if(this.hzdGameFont == null)
         {
            try
            {
               var c:* = this.DialogueList_mc.GetClipByIndex(0);
               if(c != null && c.TextHolder_mc != null) { this.hzdGameFont = c.TextHolder_mc.textField.getTextFormat().font; }
            }
            catch(e:Error) { }
         }
         return this.hzdGameFont != null && this.hzdGameFont.length > 0 ? this.hzdGameFont : "$MAIN_Font";
      }
      // role: "" names / labels (SemiBold), "_Regular" body, "_Bold" keycaps. DlgFont -1 = [Style] FontFace.
      // 3 = the game's semibold face (one weight for every role), game font if that name does not resolve.
      private function hzdFont(role:String, s:String) : String
      {
         var f:int = int(this.hzdCfg.DlgFont) >= 0 ? int(this.hzdCfg.DlgFont) : int(this.hzdCfg.FontFace);
         var i:int = 0;
         while(i < s.length) { var cc:int = s.charCodeAt(i); if(cc > 0x52F && (cc < 0x2010 || cc > 0x2026)) { return this.hzdGame(); } i++; }
         if(f == 3) { return this.hzdFontProbe(HZD_SEMI) ? HZD_SEMI : this.hzdGame(); }
         if(this.hzdProbe.font === 0 || f <= 0 || f > 2) { return this.hzdGame(); }
         var base:String = f == 2 ? "$Horizon_Font_Alt" : "$Horizon_Font";
         if(this.hzdFontProbe(base + role)) { return base + role; }
         if(this.hzdFontProbe(base)) { return base; }
         return this.hzdGame();
      }
      private function hzdText(p:Sprite, s:String, role:String, size:Number, col:uint, sp:Number, x:Number, y:Number, w:Number, align:String, wrap:Boolean) : TextField
      {
         var t:TextField = new TextField();
         t.selectable = false; t.mouseEnabled = false; t.embedFonts = true;
         t.multiline = wrap; t.wordWrap = wrap;
         t.autoSize = TextFieldAutoSize.LEFT;
         if(w > 0 && wrap) { t.width = w; }
         var f:TextFormat = new TextFormat(this.hzdFont(role,s),Math.round(size),col);
         f.letterSpacing = sp; f.align = align;
         if(wrap) { f.leading = Math.round(size * 0.35 - 4); }
         t.defaultTextFormat = f; t.text = s; t.setTextFormat(f);
         var lx:Number = x;
         if(!wrap && align == "right") { lx = x - t.width; }
         else if(!wrap && align == "center") { lx = x - t.width / 2; }
         t.x = Math.round(lx); t.y = Math.round(y);
         if(this.hzdBare) { t.filters = [new GlowFilter(0x000000,0.7,4,4,2,2)]; }
         p.addChild(t);
         return t;
      }
      // v0.38: choices card title = the character spoken to (trimmed, upper case), RESPOND without a name
      private function hzdTitle(who:String) : String
      {
         var w:String = who == null ? "" : String(who).replace(/^\s+|\s+$/g,"");
         return w.length > 0 ? w.toUpperCase() : "RESPOND";
      }
      // cut a one-line text field with "..." until it fits maxW (no change when it fits or maxW is not usable)
      private function hzdClip(t:TextField, maxW:Number) : void
      {
         if(t == null || isNaN(maxW) || maxW <= 20) { return; }
         var full:String = t.text;
         var n:int = full.length;
         while(t.textWidth > maxW && n > 1)
         {
            n--;
            t.text = full.substr(0,n).replace(/\s+$/,"") + "...";
         }
      }
      private function hzdChip(p:Sprite, label:String, col:uint, rx:Number, y:Number, z:Number) : Number
      {
         var t:TextField = this.hzdText(p,label,"",13 * z,col,Math.round(13 * z * 0.14),0,y + 2 * z,0,"left",false);
         var w:Number = Math.round(t.textWidth + 24 * z);
         t.x = Math.round(rx - w + 10 * z);
         var g:* = p.graphics;
         g.lineStyle(1,col,0.5); g.beginFill(col,0.15); g.drawRoundRect(rx - w,y,w,t.textHeight + 8 * z,20 * z,20 * z); g.endFill(); g.lineStyle();
         return w;
      }
      // device unit: one screen pixel in movie units
      private function hzdPu() : Number { var sh:Number = Number(this.hzdCfg.ScreenHeight); return sh >= 360 ? 1080 / sh : 1; }
      private function hzdSnap(v:Number) : Number { var pu:Number = this.hzdPu(); return Math.round(v / pu) * pu; }
      // keycap: faint fill under the label, the outline as a full ring of separate filled shapes (hzdRing) in an overlay
      // above the label. a < 1 (already-said rows) mixes the ring toward the panel color instead of lowering its alpha,
      // so the overlapping corner joins stay invisible. Returns the cap width.
      private function hzdKeycap(p:Sprite, label:String, x:Number, y:Number, z:Number, col:uint, a:Number, hh:Number = 26) : Number
      {
         var fs:Shape = new Shape();   // faint fill, under the label
         p.addChild(fs);
         var t:TextField = this.hzdText(p,label,"_Bold",(hh < 26 ? 13 : 15) * z,col,0,0,0,0,"left",false);
         var x0:Number = this.hzdSnap(x);
         var y0:Number = this.hzdSnap(y);
         var w:Number = this.hzdSnap(Math.max(26 * z,t.textWidth + (hh < 26 ? 16 : 18) * z));
         var h:Number = this.hzdSnap(hh * z);
         t.x = Math.round(x0 + (w - t.width) / 2); t.y = Math.round(y0 + (h - t.height) / 2);
         t.alpha = a;
         var r:Number = this.hzdSnap(Math.min(6 * z,h / 2));
         var g:* = fs.graphics;
         g.beginFill(col,0.12 * a); g.drawRoundRect(x0,y0,w,h,r * 2,r * 2); g.endFill();
         var o:Shape = new Shape();
         p.addChild(o);
         var pu:Number = this.hzdPu();
         this.hzdRing(o.graphics,x0,y0,w,h,r,pu < 1 ? 2 * pu : pu,a < 1 ? this.hzdMix(col,this.hzdBgCol(),Math.min(0.6,1 - a + 0.25)) : col);
         return w;
      }
      // v0.34 full ring (same construction as the HUD keycap): 4 straight bars + 4 quarter rings, each its own closed
      // opaque fill, every edge on the device-pixel grid. Never one compound fill (Scaleform joins sub-paths into a wedge).
      private function hzdRing(g:*, x:Number, y:Number, w:Number, h:Number, r:Number, bt:Number, col:uint) : void
      {
         var ov:Number = Math.min(0.5,bt / 2);
         g.lineStyle();
         g.beginFill(col,1); g.drawRect(x + r - ov,y,w - 2 * r + 2 * ov,bt); g.endFill();
         g.beginFill(col,1); g.drawRect(x + r - ov,y + h - bt,w - 2 * r + 2 * ov,bt); g.endFill();
         g.beginFill(col,1); g.drawRect(x,y + r - ov,bt,h - 2 * r + 2 * ov); g.endFill();
         g.beginFill(col,1); g.drawRect(x + w - bt,y + r - ov,bt,h - 2 * r + 2 * ov); g.endFill();
         this.hzdCorner(g,x + r,y + r,r,bt,180,col,1);
         this.hzdCorner(g,x + w - r,y + r,r,bt,270,col,1);
         this.hzdCorner(g,x + w - r,y + h - r,r,bt,0,col,1);
         this.hzdCorner(g,x + r,y + h - r,r,bt,90,col,1);
      }
      // filled quarter ring centered (cx,cy), outer radius r, thickness bt, starting at angle a0 (degrees, clockwise on screen)
      private function hzdCorner(g:*, cx:Number, cy:Number, r:Number, bt:Number, a0:Number, col:uint, al:Number) : void
      {
         var ri:Number = Math.max(0,r - bt);
         var n:int = 6;
         var i:int = 0;
         g.beginFill(col,al);
         while(i <= n)
         {
            var ang:Number = (a0 + 90 * i / n) * Math.PI / 180;
            if(i == 0) { g.moveTo(cx + Math.cos(ang) * r,cy + Math.sin(ang) * r); } else { g.lineTo(cx + Math.cos(ang) * r,cy + Math.sin(ang) * r); }
            i++;
         }
         i = n;
         while(i >= 0)
         {
            var bng:Number = (a0 + 90 * i / n) * Math.PI / 180;
            g.lineTo(cx + Math.cos(bng) * ri,cy + Math.sin(bng) * ri);
            i--;
         }
         g.endFill();
      }
      // card art: fill + 1 px stroked edge + accent stripe on a fresh Shape at the bottom of p
      private function hzdCardBg(p:Sprite, w:Number, h:Number, r:Number, bg:Number, acc:uint, inset:Number, sw:Number, fill:uint = 0x0B1218) : Shape
      {
         var c:Shape = new Shape();
         p.addChildAt(c,0);
         var g:* = c.graphics;
         g.beginFill(fill,bg); g.drawRoundRect(0,0,w,h,r * 2,r * 2); g.endFill();
         g.lineStyle(1,this.hzdLight(fill) ? 0x0E1E1C : 0xFFFFFF,this.hzdLight(fill) ? 0.24 : 0.10,true); g.beginFill(fill,0.004); g.drawRoundRect(0.5,0.5,w - 1,h - 1,r * 2 - 1,r * 2 - 1); g.endFill(); g.lineStyle();   // v0.40.3: fill closes the path
         g.beginFill(acc,1); g.drawRoundRect(0,Math.round(inset),Math.max(2,sw),Math.max(4,h - 2 * Math.round(inset)),Math.max(2,sw),Math.max(2,sw)); g.endFill();
         return c;
      }
      private function hzdTri(g:*, cx:Number, cy:Number, down:Boolean, col:uint) : void
      {
         g.beginFill(col,1);
         if(down) { g.moveTo(cx - 6,cy - 3.5); g.lineTo(cx + 6,cy - 3.5); g.lineTo(cx,cy + 3.5); }
         else { g.moveTo(cx - 6,cy + 3.5); g.lineTo(cx + 6,cy + 3.5); g.lineTo(cx,cy - 3.5); }
         g.endFill();
      }
      // draws at the chosen size; only if every option would not fit the screen height does the option text step down
      private function hzdDraw() : void
      {
         try { if(this.hzdOpen) { this.hzdViewCheck(); } } catch(eVc:Error) { }
         var vr:Rectangle = this.hzdVr();
         var m:Number = Number(this.hzdCfg.Margin);
         if(isNaN(m)) { m = 40; }
         var spk:Number = this.hzdSpk.visible ? Math.round(104 * Number(this.hzdCfg.TextScale) * (HZD_LRG ? 1.25 : 1)) : 0;
         var maxH:Number = vr.height - 2 * Math.min(m,60) - spk - (this.hzdBarMode() == 0 ? this.hzdBarH() + this.hzdBarGap() : 0);
         var fit:Number = 1;
         while(true)
         {
            this.hzdDrawAt(fit);
            if(this.hzdLastH <= maxH || fit <= 0.7 || this.hzdView.length == 0) { break; }
            fit = Math.max(0.7,fit - 0.1);
         }
      }
      private function hzdDsc() : Number { var v:Number = Number(this.hzdCfg.DlgScale); return isNaN(v) ? 1 : Math.max(0.7,Math.min(1.5,v)); }
      private function hzdHex(k:String) : int
      {
         var hx:String = String(this.hzdCfg[k]);
         if(hx.length == 7 && hx.charAt(0) == "#") { var v:Number = parseInt(hx.substr(1),16); if(!isNaN(v)) { return int(v); } }
         return -1;
      }
      // DlgBgColor: 0 - 11 the HUD card colors (0 slate = the v0.32 look), 12 = DlgBgHex
      private function hzdBgCol() : uint
      {
         var c:int = int(this.hzdCfg.DlgBgColor);
         if(c == 12 && this.hzdHex("DlgBgHex") >= 0) { return uint(this.hzdHex("DlgBgHex")); }
         return uint(HZD_BG[Math.max(0,Math.min(HZD_BG.length - 1,c))]);
      }
      private function hzdLight(c:uint) : Boolean
      {
         return (0.2126 * ((c >> 16) & 0xFF) + 0.7152 * ((c >> 8) & 0xFF) + 0.0722 * (c & 0xFF)) / 255 > 0.5;
      }
      // DlgTextColor: -1 off-white (dark on a light panel), 0 - 12 accent palette, 13 = DlgTextHex
      private function hzdTextCol(bg:uint) : uint
      {
         var c:int = int(this.hzdCfg.DlgTextColor);
         if(c == 13 && this.hzdHex("DlgTextHex") >= 0) { return uint(this.hzdHex("DlgTextHex")); }
         if(c >= 0 && c < HZD_ACC.length) { return uint(HZD_ACC[c]); }
         return this.hzdLight(bg) && int(this.hzdCfg.DlgCard) != 0 ? 0x0E151B : 0xE8F0F5;
      }
      private function hzdMix(a:uint, b:uint, t:Number) : uint
      {
         var r:int = int(((a >> 16) & 0xFF) * (1 - t) + ((b >> 16) & 0xFF) * t);
         var g2:int = int(((a >> 8) & 0xFF) * (1 - t) + ((b >> 8) & 0xFF) * t);
         var bl:int = int((a & 0xFF) * (1 - t) + (b & 0xFF) * t);
         return uint((r << 16) | (g2 << 8) | bl);
      }
      private function hzdDrawAt(fit:Number) : void
      {
         var p:Sprite = this.hzdPanel;
         while(p.numChildren > 0) { p.removeChildAt(0); }
         p.graphics.clear();
         if(this.hzdView.length == 0) { return; }
         var lay:int = int(this.hzdCfg.DlgLayout);
         var cmp:Boolean = lay == 1;
         var cls:Boolean = lay == 2;
         var ds:Number = this.hzdDsc();
         var ts:Number = Number(this.hzdCfg.TextScale) * (HZD_LRG ? 1.25 : 1) * ds;
         var z:Number = Number(this.hzdCfg.DlgTextSize) * ts * fit;
         var acc:uint = this.hzdAccent();
         var W:Number = Math.round((HZD_LRG ? 700 : 620) * ds);
         var pad:Number = Math.round((cmp ? 12 : 16) * ds);
         var bgc:uint = this.hzdBgCol();
         var tcol:uint = this.hzdTextCol(bgc);
         var lightBg:Boolean = this.hzdLight(bgc) && int(this.hzdCfg.DlgCard) != 0;
         var mut:uint = lightBg ? 0x4A5A64 : 0x8FA3AE;
         this.hzdBare = int(this.hzdCfg.DlgCard) == 0;
         var bare:Boolean = this.hzdBare;
         var rows:Sprite = new Sprite();
         p.addChild(rows);
         var lines:Shape = new Shape();   // dividers + scroll triangles, above the card art (a Sprite's own graphics sit under its children)
         p.addChild(lines);
         var lg:* = lines.graphics;
         // header
         var hy:Number = pad + 4;
         // counter: right-aligned inside the header, mirroring the title's inset on the left (drawn first: the title stops before it)
         var cntTf:TextField = this.hzdText(p,String(this.hzdSel + 1) + " OF " + String(this.hzdView.length),"",14 * ts,mut,Math.round(14 * ts * 0.12),W - pad - 14,hy,0,"right",false);
         var ttlTf:TextField = this.hzdText(p,this.hzdPers ? "PERSUADE" : this.hzdTitle(this.hzdWho),"",(cmp ? 13 : 14) * ts,acc,Math.round(14 * ts * 0.22),pad + 14,hy,0,"left",false);
         this.hzdClip(ttlTf,cntTf.x - 16 * ts - ttlTf.x);
         var y:Number = hy + 14 * ts + 12;
         if(!bare) { lg.beginFill(0xFFFFFF,0.09); lg.drawRect(pad,y,W - pad * 2,1); lg.endFill(); }
         y += 9;
         var n:int = this.hzdVis();
         var more:Boolean = int(this.hzdCfg.DlgMoreHint) == 1 && this.hzdLimit() > 0;
         if(more && this.hzdTop > 0)
         {
            var at:TextField = this.hzdText(p,String(this.hzdTop) + " ABOVE","",14 * ts,mut,Math.round(14 * ts * 0.18),W / 2 + 11,y + 2,0,"center",false);
            this.hzdTri(lg,at.x - 10,y + 2 + at.textHeight / 2,false,acc);
            y += at.textHeight + 8;
         }
         var padY:Number = Math.round((cmp ? 6 : 11) * ds);
         var padX:Number = Math.round((cmp ? 12 : 14) * ds);
         var gap:Number = Math.round((cmp ? 10 : 14) * ds);
         var fs:Number = (cmp ? 19 : 21) * z;
         var keys:Boolean = int(this.hzdCfg.DlgNumberKeys) == 1;
         var said:int = int(this.hzdCfg.DlgSaidStyle);
         var v:int = this.hzdTop;
         while(v < Math.min(this.hzdView.length,this.hzdTop + n))
         {
            var d:Object = this.hzdList().GetDataForEntry(int(this.hzdView[v]));
            if(d == null) { v++; continue; }
            var r:Sprite = new Sprite();
            r.name = "row" + String(v);
            r.mouseChildren = false;
            r.buttonMode = true;
            rows.addChild(r);
            var sel:Boolean = v == this.hzdSel;
            var wasSaid:Boolean = !this.hzdPers && this.hzdSaid(d);
            var ta:Number = wasSaid && said != 1 ? 0.55 : 1;
            var tx:Number = padX;
            var kw:Number = 0;
            var rx:Number = W - pad * 2 - padX;
            var chipW:Number = 0;
            // chips first (they narrow the text)
            if(this.hzdPers)
            {
               var pts:int = int(d.iPersuasionPointsGained);
               var dc:uint = uint(HZD_DIFF[Math.max(0,Math.min(2,int(d.uDifficulty)))]);
               chipW = this.hzdChip(r,"+" + String(pts),dc,rx,padY + 3,ts);
            }
            else if(Boolean(d.bIsSpeechChallenge) && int(this.hzdCfg.DlgPersuadeStyle) == 0)
            {
               chipW = this.hzdChip(r,"PERSUADE",uint(HZD_ACC[Math.max(0,Math.min(12,int(this.hzdCfg.DlgPersuadeColor)))]),rx,padY + 3,ts);
            }
            if(wasSaid && said == 2) { chipW += this.hzdChip(r,"SAID",0x8FA3AE,rx - chipW - (chipW > 0 ? 6 : 0),padY + 3,ts) + (chipW > 0 ? 6 : 0); }
            var label:String = String(d.sChoiceText != null ? d.sChoiceText : "");
            if(keys && v < 9 && !cls) { kw = this.hzdKeycap(r,String(v + 1),tx,padY + 1,ts,wasSaid ? 0x8FA3AE : acc,wasSaid ? 0.8 : 1) + gap; }
            if(keys && v < 9 && cls) { label = String(v + 1) + "   " + label; }
            var col:uint = sel ? tcol : this.hzdMix(tcol,bgc,0.18);
            if(Boolean(d.bIsSpeechChallenge) && !this.hzdPers && int(this.hzdCfg.DlgPersuadeStyle) == 1) { col = uint(HZD_ACC[Math.max(0,Math.min(12,int(this.hzdCfg.DlgPersuadeColor)))]); }
            if(cls && sel) { col = acc; }
            var tw:Number = Math.max(80,rx - tx - kw - (chipW > 0 ? chipW + 10 : 0));
            var t:TextField = this.hzdText(r,label,sel ? "" : "_Regular",fs,col,0,tx + kw,padY - 2,tw,cls ? "center" : "left",true);
            t.alpha = ta;
            var rh:Number = Math.round(Math.max(26 * ts,t.textHeight + 4) + padY * 2);
            var rw:Number = W - pad * 2;
            var g:* = r.graphics;
            g.beginFill(0xFFFFFF,0.001); g.drawRect(0,0,rw,rh); g.endFill();   // hit area
            if(sel && !cls)
            {
               g.beginFill(acc,0.14); g.drawRoundRect(0,0,rw,rh,20,20); g.endFill();
               g.beginFill(acc,1); g.drawRoundRect(0,10,4,Math.max(4,rh - 20),4,4); g.endFill();
            }
            else if(sel && cls) { g.beginFill(acc,1); g.drawRoundRect(rw / 2 - 20,rh - 3,40,3,3,3); g.endFill(); }
            r.x = this.hzdSnap(pad); r.y = this.hzdSnap(y);
            r.addEventListener(MouseEvent.MOUSE_OVER,this.hzdOnRowOver);
            r.addEventListener(MouseEvent.MOUSE_OUT,this.hzdOnRowOut);
            r.addEventListener(MouseEvent.CLICK,this.hzdOnRowClick);
            y += rh + Math.round(4 * ds);
            v++;
         }
         var left:int = this.hzdView.length - (this.hzdTop + n);
         if(more && left > 0)
         {
            var mt:TextField = this.hzdText(p,String(left) + " MORE","",14 * ts,mut,Math.round(14 * ts * 0.18),W / 2 + 11,y + 8,0,"center",false);
            this.hzdTri(lg,mt.x - 10,y + 8 + mt.textHeight / 2,true,acc);
            y += mt.textHeight + 10;
         }
         if(keys && int(this.hzdCfg.DlgQuickPickHint) == 1 && this.hzdBarMode() != 0)
         {
            y += 8;
            if(!bare) { lg.beginFill(0xFFFFFF,0.09); lg.drawRect(pad,y,W - pad * 2,1); lg.endFill(); }
            y += 12;
            var fw:Number = this.hzdKeycap(p,"1-9",pad + 14,y,ts * 0.92,mut,1);
            this.hzdText(p,"QUICK PICK","",14 * ts,mut,Math.round(14 * ts * 0.12),pad + 14 + fw + 10,y + 3,0,"left",false);
            y += 26 * ts;
         }
         var H:Number = Math.round(y + 14 * ds);
         this.hzdLastH = H;
         this.hzdLastW = W;
         var bo:Number = Number(this.hzdCfg.DlgBgOpacity);
         if(isNaN(bo)) { bo = 0.85; }
         if(!bare) { this.hzdCardBg(p,W,H,14,Math.max(0,Math.min(1,bo)),acc,12,4,bgc); }
         else { p.graphics.beginFill(0xFFFFFF,0.001); p.graphics.drawRect(0,0,W,H); p.graphics.endFill(); }   // wheel hit area only
         this.hzdBare = false;
         this.hzdLayout(W,H);
      }
      private function hzdDrawSpeaker() : void
      {
         var s:Sprite = this.hzdSpk;
         while(s.numChildren > 0) { s.removeChildAt(0); }
         s.graphics.clear();
         s.visible = this.hzdOn && int(this.hzdCfg.SpeakerCard) == 1 && this.hzdWho.length > 0;
         if(!s.visible) { return; }
         if(!this.hzdOpen) { this.hzdLayout(this.hzdLastW,this.hzdLastH); }
         var ts:Number = Number(this.hzdCfg.TextScale) * (HZD_LRG ? 1.25 : 1);
         var w:Number = Math.round(400 * ts);
         var h:Number = Math.round(86 * ts);
         var acc:uint = this.hzdAccent();
         var g:* = this.hzdCardBg(s,w,h,14 * ts,0.8,acc,14 * ts,4 * ts).graphics;
         g.lineStyle(2 * ts,acc,0.7); g.beginFill(acc,0.08); g.drawCircle(46 * ts,43 * ts,26 * ts); g.endFill(); g.lineStyle();
         g.beginFill(acc,0.9); g.drawCircle(46 * ts,36 * ts,7 * ts); g.endFill();
         g.beginFill(acc,0.9); g.drawRoundRect(34 * ts,46 * ts,24 * ts,12 * ts,12 * ts,12 * ts); g.endFill();
         this.hzdText(s,this.hzdWho.toUpperCase(),"",20 * ts,0xE8F0F5,Math.round(20 * ts * 0.16),90 * ts,16 * ts,w - 100 * ts,"left",false);
         this.hzdText(s,"SPEAKING","",14 * ts,0x8FA3AE,Math.round(14 * ts * 0.14),90 * ts,50 * ts,0,"left",false);
         s.y = this.hzdPanel.y - this.hzdAnimDy - Math.round(104 * ts) - (this.hzdBarUp ? this.hzdBarH() + this.hzdBarGap() : 0);
         s.x = this.hzdPanel.x;
      }
      private function hzdAnchor(v:String, axis:String, size:Number, lo:Number, hi:Number) : Number
      {
         if(v == null || v.length < 2) { return NaN; }
         var a:String = v.charAt(0).toUpperCase();
         var d:Number = Number(v.substr(1).replace(/\s/g,""));
         var m:Number = Number(this.hzdCfg.Margin);
         if(isNaN(m)) { m = 40; }
         if(!isNaN(d))
         {
            if(axis == "x") { if(a == "L") { return lo + m + d; } if(a == "R") { return hi - m - size - d; } if(a == "C") { return (lo + hi) / 2 - size / 2 + d; } }
            else { if(a == "T") { return lo + m + d; } if(a == "B") { return hi - m - size - d; } if(a == "C") { return (lo + hi) / 2 - size / 2 + d; } }
         }
         var f:Number = Number(v);   // a legacy 0-1 fraction
         return !isNaN(f) && f >= 0 && f <= 1 ? lo + f * (hi - lo) : NaN;
      }
      private function hzdLayout(W:Number, H:Number) : void
      {
         var vr:Rectangle = this.hzdVr();
         var x:Number = this.hzdAnchor(String(this.hzdCfg.DialogueX),"x",W,vr.x,vr.right);
         var y:Number = this.hzdAnchor(String(this.hzdCfg.DialogueY),"y",H,vr.y,vr.bottom);
         var cls:Boolean = int(this.hzdCfg.DlgLayout) == 2;
         if(isNaN(x)) { x = cls ? vr.x + vr.width / 2 - W / 2 : vr.right - 90 - W; }
         if(isNaN(y)) { y = cls ? vr.bottom - 80 - H : vr.y + 404; }
         // v0.33: the F11 offsets apply on top of the default spot AND of the ARRANGE position (DlgOffsetY + = up).
         // (v0.32 used them only without a [Layout] DialogueX/Y, so after any ARRANGE move they did nothing.)
         var ox:Number = Number(this.hzdCfg.DlgOffsetX);
         var oy:Number = Number(this.hzdCfg.DlgOffsetY);
         x += isNaN(ox) ? 0 : ox;
         y -= isNaN(oy) ? 0 : oy;
         var sh:Number = Number(this.hzdCfg.ScreenHeight);
         var pu:Number = sh >= 360 ? 1080 / sh : 1;
         x = Math.max(vr.x,Math.min(vr.right - W,x));
         y = Math.max(vr.y,Math.min(vr.bottom - H,y));
         this.hzdPanel.x = Math.round(x / pu) * pu;
         this.hzdPanel.y = Math.round(y / pu) * pu + this.hzdAnimDy;
         this.hzdSpk.x = this.hzdPanel.x;
         this.hzdSpk.y = this.hzdPanel.y - Math.round(104 * Number(this.hzdCfg.TextScale) * (HZD_LRG ? 1.25 : 1));
         try { this.hzdBarPlace(); } catch(eb:Error) { }
      }
      private function hzdVr() : Rectangle
      {
         var vr:Rectangle = new Rectangle(0,0,1920,1080);
         try
         {
            var r:Rectangle = Extensions.visibleRect;
            if(r != null && r.width >= 100 && stage != null)
            {
               var a:Point = globalToLocal(new Point(r.left,r.top));
               var b:Point = globalToLocal(new Point(r.right,r.bottom));
               if(b.x - a.x >= 100) { vr = new Rectangle(a.x,a.y,b.x - a.x,b.y - a.y); }
            }
         }
         catch(e:Error) { }
         return vr;
      }
      // ---------- v0.34 button bar (BUTTONBAR_RESEARCH.md option A, hooks D10 / D11) ----------
      private var hzdBar:Sprite = null;
      private var hzdBarW:Number = 0;
      private var hzdBarUp:Boolean = false;       // no room under the panel: the strip sits above it (speaker card moves up)
      private var hzdBarFallback:Boolean = false; // controller glyph font not usable here: the vanilla bar stays visible
      private var hzdAcceptKey:String = "";        // keyboard key of the Accept user event (ControlMapData), "" = unknown
      private var hzdCtlPad:Boolean = false;
      // DlgButtonBar: 0 Horizon (default) / 1 vanilla / 2 hidden (keys still work; auto-win shows once charged)
      private function hzdBarMode() : int { var m:int = int(this.hzdCfg.DlgButtonBar); return m < 0 || m > 2 ? 0 : m; }
      private function hzdBarZ() : Number { return Number(this.hzdCfg.TextScale) * (HZD_LRG ? 1.25 : 1) * this.hzdDsc(); }
      private function hzdBarH() : Number { return Math.round(46 * this.hzdBarZ()); }
      private function hzdBarGap() : Number { return Math.round(10 * this.hzdBarZ()); }
      private function hzdBtn(n:String) : *
      {
         try { return this.ButtonBar_mc[n]; } catch(e:Error) { }
         return null;
      }
      // the vanilla bar: alpha 0 + mouse off while Horizon draws its own (or hides it); alpha 1 + mouse on otherwise.
      // visible is never touched (vanilla drives its buttons' visibility) and the clip is never removed.
      private function hzdBarApply() : void
      {
         var bb:* = this.ButtonBar_mc;
         if(bb == null) { return; }
         var hide:Boolean = this.hzdOn && this.hzdBarMode() != 1 && !this.hzdBarFallback;
         bb.alpha = hide ? 0 : 1;
         bb.mouseEnabled = !hide;
         bb.mouseChildren = !hide;
      }
      private function hzdTfAt(o:*, path:Array) : TextField
      {
         try
         {
            var c:* = o;
            for each(var n:String in path) { if(c == null) { return null; } c = c[n]; }
            return c as TextField;
         }
         catch(e:Error) { }
         return null;
      }
      // shown on screen = it and every parent up to the button are visible (vanilla flips the PC / console holders)
      private function hzdShownIn(d:DisplayObject, top:*) : Boolean
      {
         try
         {
            var c:DisplayObject = d;
            while(c != null && c != top) { if(!c.visible) { return false; } c = c.parent; }
            return true;
         }
         catch(e:Error) { }
         return false;
      }
      // read-only mirror of one vanilla button: state + the text it shows (already resolved / translated by the game)
      private function hzdBtnInfo(b:*) : Object
      {
         var o:Object = {"vis":false,"en":false,"lab":"","key":"","pad":false,"font":null,"fill":0};
         if(b == null) { return o; }
         try { o.vis = Boolean(b.Visible); } catch(e0:Error) { try { o.vis = Boolean(b.visible); } catch(e1:Error) { } }
         try { o.en = Boolean(b.Enabled); } catch(e2:Error) { }
         try { var fp:Number = Number(b.FillPercent); o.fill = isNaN(fp) ? 0 : fp; } catch(e3:Error) { }
         var lt:TextField = this.hzdTfAt(b,["Label_mc","LabelInstance_mc","Label_tf"]);
         if(lt == null) { lt = this.hzdTfAt(b,["Label_mc","Label_tf"]); }
         if(lt != null && lt.text != null) { o.lab = lt.text.replace(/^\s+|\s+$/g,"").toUpperCase(); }
         var ct:TextField = this.hzdTfAt(b,["ConsoleButton_mc","ButtonInstance_mc","ConsoleButton_tf"]);
         if(ct == null) { ct = this.hzdTfAt(b,["ConsoleButton_mc","ConsoleButton_tf"]); }
         var pt:TextField = this.hzdTfAt(b,["PCButton_mc","ButtonInstance_mc","PCButton_tf"]);
         if(pt == null) { pt = this.hzdTfAt(b,["PCButton_mc","PCButton_tf"]); }
         var cs:String = ct != null && ct.text != null ? ct.text.replace(/^\s+|\s+$/g,"") : "";
         var ps:String = pt != null && pt.text != null ? pt.text.replace(/^\s+|\s+$/g,"") : "";
         if(cs.length > 0 && this.hzdShownIn(ct,b))
         {
            o.key = cs; o.pad = true;
            try { o.font = ct.getTextFormat().font; } catch(e4:Error) { o.font = null; }
         }
         else if(ps.length > 0) { o.key = ps.toUpperCase(); }
         return o;
      }
      // keyboard key of Accept for the SELECT hint (no vanilla button carries it); never a guessed key
      public function hzdOnCtl(ev:FromClientDataEvent) : void
      {
         try
         {
            var d:Object = ev != null ? ev.data : null;
            if(d == null) { return; }
            if(d.uiController != undefined) { this.hzdCtlPad = int(d.uiController) != 0; }
            var first:String = "";
            var menu:String = "";
            for each(var m:Object in d.vMappedEvents)
            {
               if(m == null || String(m.strUserEventName) != "Accept") { continue; }
               var bn:String = m.strButtonName != null ? String(m.strButtonName).replace(/^\s+|\s+$/g,"") : "";
               if(bn.length == 0) { continue; }
               if(first.length == 0) { first = bn; }
               if(menu.length == 0 && m.sContextName != null && String(m.sContextName).toLowerCase().indexOf("menu") >= 0) { menu = bn; }
            }
            this.hzdAcceptKey = (menu.length > 0 ? menu : first).toUpperCase();
            if(this.hzdBar != null && this.hzdBar.visible) { this.hzdBarDraw(); }
         }
         catch(e:Error) { }
      }
      public function hzdOnBarRedrawn(e:Event) : void
      {
         try { this.hzdBarDraw(); } catch(err:Error) { }
      }
      // D10 overrides (vanilla first): the moments vanilla changes a button's Visible / Enabled / FillPercent
      override protected function UpdateCancelButtonState() : void
      {
         super.UpdateCancelButtonState();
         try { if(this.hzdBar != null) { this.hzdBarDraw(); } } catch(e:Error) { }
      }
      override protected function ShowPersuasionDataElems() : void
      {
         var was:Boolean = false;
         try { was = this.hzdPmShown(); } catch(eW:Error) { was = false; }
         if(!was) { this.hzdPmShut = false; }
         super.ShowPersuasionDataElems();
         if(!was)
         {
            this.hzdPmData = this.hzdPmNew;
            this.hzdPmNew = null;
            this.hzdPmSig = "";
            this.hzdPmOff = false;
            this.hzdPmFail = 0;
         }
         try { if(this.hzdBar != null) { this.hzdBarDraw(); } this.hzdPmApply(); } catch(e:Error) { }
      }
      override protected function HidePersuasionDataElems() : void
      {
         var up:Boolean = false;
         if(this.hzdPm != null && this.hzdPm.visible) { up = true; }
         if(!up) { try { up = this.hzdPmShown(); } catch(eU:Error) { up = false; } }
         if(up) { this.hzdPmDrop(); }
         else { this.hzdPmShut = false; }
         super.HidePersuasionDataElems();
         try { if(this.hzdBar != null) { this.hzdBarDraw(); } this.hzdPmApply(); } catch(e:Error) { }
      }
      override protected function onPersuasionPointsUpdate(param1:FromClientDataEvent) : void
      {
         super.onPersuasionPointsUpdate(param1);
         try
         {
            if(param1 != null && param1.data != null)
            {
               var mx:Number = Number(param1.data.uMaxPersuasionScore);
               if(!isNaN(mx) && mx > 0)
               {
                  var shown:Boolean = false;
                  try { shown = this.hzdPmShown(); } catch(eS:Error) { shown = false; }
                  if(shown || !this.hzdPmShut)
                  {
                     this.hzdPmData = param1.data;
                     this.hzdPmOff = false;
                     this.hzdPmFail = 0;
                     if(!shown) { this.hzdPmNew = param1.data; }
                  }
               }
            }
            if(this.hzdBar != null) { this.hzdBarDraw(); }
            this.hzdPmApply();
         }
         catch(e:Error) { }
      }
      // one pill: [keycap or controller glyph] + LABEL, optional progress line (auto-win charge). Returns its width.
      private function hzdPill(b:Sprite, id:String, key:String, lab:String, cap:uint, lc:uint, pad:Boolean, font:String, prog:Number, z:Number) : Sprite
      {
         var s:Sprite = new Sprite();
         s.name = id;
         s.mouseChildren = false;
         b.addChild(s);
         var H:Number = this.hzdBarH();
         var x:Number = 0;
         if(key.length > 0)
         {
            if(pad)
            {
               var gt:TextField = new TextField();
               gt.selectable = false; gt.mouseEnabled = false; gt.embedFonts = true;
               gt.autoSize = TextFieldAutoSize.LEFT;
               var gf:TextFormat = new TextFormat(font,Math.round(22 * z),0xE8F0F5);
               gt.defaultTextFormat = gf; gt.text = key; gt.setTextFormat(gf);
               gt.x = 0; gt.y = Math.round((H - gt.height) / 2);
               s.addChild(gt);
               x = Math.round(gt.width);
            }
            else { x = this.hzdKeycap(s,key,0,(H - 24 * z) / 2,z,cap,1,24); }
            x += Math.round(8 * z);
         }
         var t:TextField = this.hzdText(s,lab,"",14 * z,lc,Math.round(14 * z * 0.14),x,0,0,"left",false);
         t.y = Math.round((H - t.height) / 2);
         var w:Number = Math.round(x + t.textWidth + 4);
         if(prog >= 0)
         {
            var g:* = s.graphics;
            var ly:Number = this.hzdSnap(Math.round(H / 2 + 13 * z));
            var lw:Number = Math.round(t.textWidth);
            g.beginFill(0xFFFFFF,0.1); g.drawRect(x,ly,lw,Math.round(3 * z)); g.endFill();
            if(prog > 0) { g.beginFill(HZD_AMB,1); g.drawRect(x,ly,Math.max(2,Math.round(lw * Math.min(1,prog))),Math.round(3 * z)); g.endFill(); }
         }
         s.graphics.beginFill(0xFFFFFF,0.001); s.graphics.drawRect(-4,0,w + 8,H); s.graphics.endFill();   // hit area
         s.buttonMode = id != "quick";
         if(id != "quick") { s.addEventListener(MouseEvent.CLICK,this.hzdOnPill); }
         s.alpha = 1;
         return s;
      }
      private function hzdPillW(s:Sprite) : Number { return Math.round(s.getBounds(s).width - 8); }   // minus the hit-area margin
      public function hzdOnPill(e:MouseEvent) : void
      {
         try
         {
            var id:String = Sprite(e.currentTarget).name;
            var b:* = null;
            if(id == "exit")
            {
               b = this.hzdBtn("CancelButton_mc");
               if(b != null && Boolean(b.Visible) && Boolean(b.Enabled)) { this.onCancelClick(); }   // vanilla re-checks the input timer
            }
            else if(id == "autowin")
            {
               b = this.hzdBtn("Persuasion_AutoWinButton_mc");
               if(b != null && Boolean(b.Visible) && Boolean(b.Enabled)) { this.onAutoWinClick(); }   // vanilla plays its sound
            }
            else if(id == "select" && this.hzdOpen && this.hzdView.length > 0) { this.hzdChoose(this.hzdSel); }
         }
         catch(err:Error) { }
      }
      private function hzdBarDraw() : void
      {
         if(this.hzdBar == null) { return; }
         var b:Sprite = this.hzdBar;
         while(b.numChildren > 0) { b.removeChildAt(0); }
         b.graphics.clear();
         var mode:int = this.hzdBarMode();
         var ex:Object = this.hzdBtnInfo(this.hzdBtn("CancelButton_mc"));
         var aw:Object = this.hzdBtnInfo(this.hzdBtn("Persuasion_AutoWinButton_mc"));
         var pad:Boolean = ex.pad || aw.pad || (ex.key.length == 0 && aw.key.length == 0 && this.hzdCtlPad);
         var font:String = ex.pad ? ex.font : (aw.pad ? aw.font : null);
         // controller glyphs need the game's button font in this movie; if it does not render, keep the vanilla bar
         this.hzdBarFallback = mode != 1 && (ex.pad || aw.pad) && (font == null || font.length == 0 || !this.hzdFontProbe(font));
         this.hzdBarApply();
         if(!this.hzdOn || mode == 1 || this.hzdBarFallback) { b.visible = false; return; }
         var z:Number = this.hzdBarZ();
         var choices:Boolean = this.hzdOpen && this.hzdPanel.visible && this.hzdView.length > 0;
         var acc:uint = this.hzdAccent();
         var bgc:uint = this.hzdBgCol();
         var light:Boolean = this.hzdLight(bgc) && int(this.hzdCfg.DlgCard) != 0;
         var txt:uint = light ? 0x0E151B : 0xE8F0F5;
         var mut:uint = light ? 0x4A5A64 : 0x8FA3AE;
         var dis:uint = light ? 0x5A6A74 : 0xA8B6BE;
         this.hzdBare = int(this.hzdCfg.DlgCard) == 0;
         var right:Array = [];
         if(mode == 0 && ex.vis)
         {
            right.push(this.hzdPill(b,"exit",ex.key,ex.lab.length > 0 ? ex.lab : "$EXIT",ex.en ? acc : this.hzdMix(acc,bgc,0.45),ex.en ? txt : dis,ex.pad,font,-1,z));
         }
         var charged:Boolean = aw.en && aw.fill >= 1;
         if(aw.vis && (mode == 0 || charged))
         {
            right.push(this.hzdPill(b,"autowin",aw.key,aw.lab.length > 0 ? aw.lab : "$Persuasion_AutoWin",charged ? HZD_AMB : this.hzdMix(0x8FA3AE,bgc,0.45),charged ? HZD_AMB : dis,aw.pad,font,charged ? -1 : aw.fill,z));
         }
         if(mode == 0 && choices && !pad && int(this.hzdCfg.DlgSelectHint) == 1 && this.hzdAcceptKey.length > 0)
         {
            right.push(this.hzdPill(b,"select",this.hzdAcceptKey,"SELECT",acc,txt,false,null,-1,z));
         }
         var quick:Sprite = null;
         if(mode == 0 && choices && !pad && int(this.hzdCfg.DlgNumberKeys) == 1 && int(this.hzdCfg.DlgQuickPickHint) == 1)
         {
            quick = this.hzdPill(b,"quick","1-9","QUICK PICK",mut,mut,false,null,-1,z);
         }
         this.hzdBare = false;
         if(right.length == 0 && quick == null) { b.visible = false; return; }
         var sp:Number = Math.round(16 * z);
         var gapB:Number = Math.round(22 * z);
         var need:Number = sp * 2;
         for each(var r0:Sprite in right) { need += this.hzdPillW(r0) + gapB; }
         if(right.length > 0) { need -= gapB; }
         if(quick != null) { need += this.hzdPillW(quick) + gapB; }
         var W:Number = choices ? Math.max(this.hzdLastW,need) : need;
         var x:Number = W - sp;
         for each(var r1:Sprite in right)
         {
            var rw:Number = this.hzdPillW(r1);
            x -= rw;
            r1.x = this.hzdSnap(x);
            x -= gapB;
         }
         if(quick != null) { quick.x = this.hzdSnap(sp); }
         var H:Number = this.hzdBarH();
         if(int(this.hzdCfg.DlgCard) != 0)
         {
            var bo:Number = Number(this.hzdCfg.DlgBgOpacity);
            if(isNaN(bo)) { bo = 0.85; }
            var c:Shape = new Shape();
            b.addChildAt(c,0);
            var g:* = c.graphics;
            var rr:Number = Math.round(12 * z);
            g.beginFill(bgc,Math.max(0,Math.min(1,bo))); g.drawRoundRect(0,0,W,H,rr * 2,rr * 2); g.endFill();
            g.lineStyle(1,light ? 0x0E1E1C : 0xFFFFFF,light ? 0.24 : 0.10,true); g.beginFill(bgc,0.004); g.drawRoundRect(0.5,0.5,W - 1,H - 1,rr * 2 - 1,rr * 2 - 1); g.endFill(); g.lineStyle();   // v0.40.3: fill closes the path
         }
         this.hzdBarW = W;
         b.visible = true;
         this.hzdBarPlace();
      }
      // under the panel (same x, its width), 10 px gap; no room below: above it. Subtitle phase: only EXIT, right-aligned
      // to the panel's last spot. Follows DialogueX/Y and the offsets because it follows the panel.
      private function hzdBarPlace() : void
      {
         if(this.hzdBar == null || !this.hzdBar.visible) { this.hzdBarUp = false; return; }
         var vr:Rectangle = this.hzdVr();
         var H:Number = this.hzdBarH();
         var gap:Number = this.hzdBarGap();
         var py:Number = this.hzdPanel.y - this.hzdAnimDy;
         var choices:Boolean = this.hzdOpen && this.hzdPanel.visible && this.hzdView.length > 0;
         var x:Number = this.hzdPanel.x + this.hzdLastW - this.hzdBarW;
         var y:Number = py;
         this.hzdBarUp = false;
         if(choices)
         {
            x = this.hzdBarW > this.hzdLastW ? this.hzdPanel.x + this.hzdLastW - this.hzdBarW : this.hzdPanel.x;
            y = py + this.hzdLastH + gap;
            if(y + H > vr.bottom - 4) { y = py - gap - H; this.hzdBarUp = true; }
         }
         x = Math.max(vr.x,Math.min(vr.right - this.hzdBarW,x));
         y = Math.max(vr.y,Math.min(vr.bottom - H,y));
         this.hzdBar.x = this.hzdSnap(x);
         this.hzdBar.y = this.hzdSnap(y) + this.hzdAnimDy;
         if(this.hzdBarUp) { this.hzdSpk.y = this.hzdPanel.y - Math.round(104 * Number(this.hzdCfg.TextScale) * (HZD_LRG ? 1.25 : 1)) - H - gap; }
      }
      // open animation: Horizon layer only (the vanilla timelines always play underneath)
      private var hzdAnimDy:Number = 0;
      private var hzdLastH:Number = 300;
      private var hzdLastW:Number = HZD_LRG ? 700 : 620;
      private function hzdAnimStart() : void
      {
         var mode:int = int(this.hzdCfg.DlgAnim);
         if(mode == 0) { this.hzdLayer.alpha = 1; this.hzdAnimDy = 0; return; }
         this.hzdAnimT0 = getTimer();
         this.hzdLayer.alpha = 0;
         this.hzdAnimDy = 8;
         addEventListener(Event.ENTER_FRAME,this.hzdAnimTick);
      }
      private function hzdAnimTick(e:Event) : void
      {
         var dur:Number = int(this.hzdCfg.DlgAnim) == 2 ? 300 : 120;
         var k:Number = Math.min(1,(getTimer() - this.hzdAnimT0) / dur);
         this.hzdLayer.alpha = k;
         var dy:Number = Math.round(8 * (1 - k));
         this.hzdPanel.y += dy - this.hzdAnimDy;
         this.hzdSpk.y += dy - this.hzdAnimDy;
         if(this.hzdBar) { this.hzdBar.y += dy - this.hzdAnimDy; }
         this.hzdAnimDy = dy;
         if(k >= 1) { removeEventListener(Event.ENTER_FRAME,this.hzdAnimTick); }
      }
      // ---------- persuasion meter (part of the dialogue menu; DlgPersuasionMeter) ----------
      // The game's PersuasionData_mc stays in the movie. While this card is up its alpha is 0 and its visible flag
      // is left alone, so the open, close and result animations keep running. A missing clip only skips this card.
      private var hzdPm:Sprite = null;
      private var hzdPmData:Object = null;
      private var hzdPmNew:Object = null;
      private var hzdPmShut:Boolean = false;
      private var hzdPmSig:String = "";
      private var hzdPmHid:Boolean = false;
      private var hzdPmAlpha:Number = 1;
      private var hzdPmFail:int = 0;
      private var hzdPmOff:Boolean = false;
      private var hzdPmListen:Boolean = false;
      private var hzdPmW:Number = 0;
      private var hzdPmH:Number = 0;
      private function hzdPmEnsure() : Boolean
      {
         if(this.hzdPm != null) { return true; }
         try
         {
            this.hzdPm = new Sprite();
            this.hzdPm.name = "hzdPm";
            this.hzdPm.mouseEnabled = false;
            this.hzdPm.mouseChildren = false;
            this.hzdPm.visible = false;
            addChild(this.hzdPm);
            return true;
         }
         catch(e:Error) { return false; }
      }
      private function hzdPmOn() : Boolean
      {
         var n:Number = Number(this.hzdCfg.DlgPersuasionMeter);
         return isNaN(n) ? true : n >= 0.5;
      }
      private function hzdPmClip() : *
      {
         try { return this.PersuasionData_mc; } catch(e:Error) { }
         return null;
      }
      private function hzdPmNum(v:*) : Number
      {
         if(v == undefined || v == null) { return NaN; }
         var n:Number = Number(v);
         return n;
      }
      // alpha only. Vanilla uses PersuasionData_mc.visible as the open and close state, so this card never writes visible.
      private function hzdPmHideVan(hide:Boolean) : void
      {
         var b:* = this.hzdPmClip();
         if(b == null) { return; }
         if(hide)
         {
            if(!this.hzdPmHid)
            {
               var a:Number = Number(b.alpha);
               this.hzdPmAlpha = !isNaN(a) && a > 0 ? a : 1;
               this.hzdPmHid = true;
            }
            b.alpha = 0;
         }
         else if(this.hzdPmHid)
         {
            b.alpha = this.hzdPmAlpha > 0 ? this.hzdPmAlpha : 1;
            this.hzdPmHid = false;
         }
      }
      private function hzdPmShown() : Boolean
      {
         var b:* = this.hzdPmClip();
         if(b == null) { return false; }
         try { return b.visible == true; } catch(e:Error) { }
         return false;
      }
      // highlighted reply only; no ghost when the points field is missing, zero, or the challenge is already over
      private function hzdPmGhost() : Number
      {
         if(!this.hzdPers) { return 0; }
         try
         {
            var l:* = this.PersuasionList_mc;
            if(l == null) { return 0; }
            var idx:int = -1;
            if(this.hzdView != null && this.hzdSel >= 0 && this.hzdSel < this.hzdView.length) { idx = int(this.hzdView[this.hzdSel]); }
            else if(l.selectedIndex != undefined && l.selectedIndex != null) { idx = int(l.selectedIndex); }
            if(idx < 0) { return 0; }
            var d:Object = l.GetDataForEntry(idx);
            if(d == null || d.iPersuasionPointsGained == undefined || d.iPersuasionPointsGained == null) { return 0; }
            var g:Number = Number(d.iPersuasionPointsGained);
            if(isNaN(g) || g <= 0) { return 0; }
            return g;
         }
         catch(e:Error) { }
         return 0;
      }
      private function hzdPmRead() : Object
      {
         var o:Object = {"goal":NaN,"score":NaN,"turns":NaN,"res":this.PERUSASION_RESULT_NONE,"won":false,"failed":false,"last":false,"have":false,"frac":0,"ghost":0,"gfrac":0,"col":this.hzdAccent()};
         var d:Object = this.hzdPmData;
         if(d != null)
         {
            o.goal = this.hzdPmNum(d.uMaxPersuasionScore);
            o.score = this.hzdPmNum(d.uPersuasionScore);
            o.turns = this.hzdPmNum(d.uTurnsLeft);
            if(d.uChallengeResult != undefined && d.uChallengeResult != null)
            {
               var rn:Number = Number(d.uChallengeResult);
               if(!isNaN(rn)) { o.res = int(rn); }
            }
         }
         var won:Boolean = o.res == this.PERUSASION_RESULT_WIN || o.res == this.PERUSASION_RESULT_CRIT_WIN;
         var failed:Boolean = o.res == this.PERUSASION_RESULT_FAIL;
         if(o.res == this.PERUSASION_RESULT_CRIT_WIN && !isNaN(o.goal) && o.goal > 0) { o.score = o.goal; }
         o.won = won;
         o.failed = failed;
         o.last = !won && !failed && !isNaN(o.turns) && int(o.turns) == 1;
         o.have = !isNaN(o.score) && !isNaN(o.goal) && o.goal > 0 && o.score >= 0;
         o.frac = o.have ? Math.max(0,Math.min(1,Number(o.score) / Number(o.goal))) : 0;
         var gh:Number = won || failed ? 0 : this.hzdPmGhost();
         o.ghost = gh;
         o.gfrac = o.have ? Math.max(Number(o.frac),Math.min(1,(Number(o.score) + gh) / Number(o.goal))) : 0;
         o.col = won ? HZD_OK : (failed ? HZD_BAD : (o.last ? HZD_AMB : this.hzdAccent()));
         return o;
      }
      private function hzdPmFs() : Number
      {
         var z:Number = Number(this.hzdCfg.TextScale);
         if(isNaN(z) || z <= 0) { z = 1; }
         z = z * (HZD_LRG ? 1.25 : 1) * this.hzdDsc();
         return Math.max(13,Math.round(13 * z));
      }
      private function hzdPmListenSet(on:Boolean) : void
      {
         if(on == this.hzdPmListen) { return; }
         if(on) { addEventListener(Event.ENTER_FRAME,this.hzdPmTick); }
         else { removeEventListener(Event.ENTER_FRAME,this.hzdPmTick); }
         this.hzdPmListen = on;
      }
      private function hzdPmTick(e:Event) : void
      {
         try { this.hzdPmApply(); } catch(err:Error) { }
      }
      // Shown meter is closing. Drop a saved payload so a late points event cannot refill it.
      private function hzdPmDrop() : void
      {
         this.hzdPmNew = null;
         this.hzdPmShut = true;
      }
      private function hzdPmApply() : void
      {
         if(!this.hzdPmEnsure()) { return; }
         var show:Boolean = false;
         if(!this.hzdPmOff && this.hzdOn && this.hzdPmOn())
         {
            try { show = this.hzdPmShown(); } catch(e0:Error) { show = false; }
            if(show)
            {
               var ready:Boolean = false;
               try
               {
                  var pre:Object = this.hzdPmRead();
                  ready = Boolean(pre.won) || Boolean(pre.failed) || Boolean(pre.have) || (!isNaN(pre.turns) && Number(pre.turns) >= 0);
               }
               catch(er0:Error) { ready = false; }
               if(!ready) { show = false; }
            }
         }
         if(!show)
         {
            if(this.hzdPm.visible) { this.hzdPmDrop(); }
            this.hzdPm.visible = false;
            this.hzdPmSig = "";
            try { this.hzdPmListenSet(false); } catch(e1:Error) { }
            try { this.hzdPmHideVan(false); } catch(e2:Error) { }
            return;
         }
         try
         {
            this.hzdPmDraw();
            this.hzdPmFail = 0;
            this.hzdPmHideVan(true);
            this.hzdPm.visible = true;
            this.hzdPm.mouseEnabled = false;
            this.hzdPm.mouseChildren = false;
            addChild(this.hzdPm);
            this.hzdPmListenSet(true);
         }
         catch(e3:Error)
         {
            this.hzdPmFail++;
            this.hzdPm.visible = false;
            this.hzdPmSig = "";
            this.hzdPmW = 0;
            this.hzdPmH = 0;
            try { this.hzdPmHideVan(false); } catch(e5:Error) { }
            if(this.hzdPmFail >= 3)
            {
               this.hzdPmOff = true;
               try { this.hzdPmListenSet(false); } catch(e4:Error) { }
            }
         }
      }
      private function hzdPmMark(g:*, x:Number, y:Number, s:Number, col:uint, ok:Boolean) : void
      {
         g.lineStyle(Math.max(2,Math.round(s * 0.16)),col,1,true);
         if(ok)
         {
            g.moveTo(x,y + s * 0.55);
            g.lineTo(x + s * 0.34,y + s * 0.88);
            g.lineTo(x + s,y + s * 0.12);
         }
         else
         {
            g.moveTo(x + s * 0.12,y + s * 0.12);
            g.lineTo(x + s * 0.88,y + s * 0.88);
            g.moveTo(x + s * 0.88,y + s * 0.12);
            g.lineTo(x + s * 0.12,y + s * 0.88);
         }
         g.lineStyle();
      }
      private function hzdPmPlace(w:Number, h:Number) : void
      {
         var b:* = this.hzdPmClip();
         var cx:Number = NaN;
         var cy:Number = NaN;
         if(b != null)
         {
            try
            {
               var r:Rectangle = b.getBounds(this);
               if(r != null && r.width >= 1 && r.height >= 1 && r.width <= 1400 && r.height <= 800 && !isNaN(r.x) && !isNaN(r.y) && !isNaN(r.width) && !isNaN(r.height))
               {
                  cx = r.x + r.width / 2;
                  cy = r.y + r.height / 2;
               }
            }
            catch(e0:Error) { }
            if(isNaN(cx) || isNaN(cy))
            {
               try
               {
                  var bw:Number = Number(b.width);
                  var bh:Number = Number(b.height);
                  if(isNaN(bw) || bw < 1) { bw = 0; }
                  if(isNaN(bh) || bh < 1) { bh = 0; }
                  var q:Point = this.globalToLocal(b.localToGlobal(new Point(bw / 2,bh / 2)));
                  if(q != null && !isNaN(q.x) && !isNaN(q.y)) { cx = q.x; cy = q.y; }
               }
               catch(e1:Error) { }
            }
         }
         var vr:Rectangle = this.hzdVr();
         if(isNaN(cx) || isNaN(cy))
         {
            if(this.hzdPanel != null && this.hzdPanel.visible) { cx = this.hzdPanel.x + w / 2; cy = this.hzdPanel.y - 12 - h / 2; }
            else { cx = vr.x + vr.width / 2; cy = vr.y + 120 + h / 2; }
         }
         var x:Number = Math.max(vr.x,Math.min(vr.right - w,cx - w / 2));
         var y:Number = Math.max(vr.y,Math.min(vr.bottom - h,cy - h / 2));
         this.hzdPm.x = Math.round(x);
         this.hzdPm.y = Math.round(y);
      }
      private function hzdPmSpeech(g:*, x:Number, y:Number, s:Number, col:uint) : void
      {
         var bh:Number = Math.round(s * 0.72);
         g.lineStyle(Math.max(1.25,Math.round(s * 0.08)),col,0.85,true);
         g.beginFill(col,0.14);
         g.drawRoundRect(x,y,s,bh,Math.round(s * 0.28),Math.round(s * 0.28));
         g.endFill();
         g.lineStyle();
         g.beginFill(col,0.9);
         var tx0:Number = x + s * 0.22;
         var ty0:Number = y + bh - 1;
         g.moveTo(tx0,ty0);
         g.lineTo(tx0 - s * 0.06,ty0 + s * 0.28);
         g.lineTo(tx0 + s * 0.28,ty0);
         g.endFill();
      }
      private function hzdPmMeterMarks(g:*, tw:Number, mh:Number, goal:Number, col:uint, u:Number, gapCol:uint, flagGap:Number, flagW:Number) : void
      {
         var steps:int = int(Math.round(goal));
         if(!isNaN(goal) && Math.abs(goal - steps) < 0.01 && steps >= 2 && steps <= 16)
         {
            var gapW:Number = Math.max(2,Math.round(2 * u));
            if(gapW > tw / steps) { gapW = Math.max(1,Math.floor(tw / steps) - 1); }
            if(gapW >= 1)
            {
               var k:int = 1;
               g.beginFill(gapCol,1);
               while(k < steps)
               {
                  var nx:Number = tw * k / steps - gapW / 2;
                  if(nx < 0) { nx = 0; }
                  g.drawRect(nx,0,gapW,mh);
                  k++;
               }
               g.endFill();
            }
         }
         var fh:Number = Math.max(8,Math.round(9 * u));
         var fy:Number = Math.round((mh - fh) / 2);
         var fx:Number = tw + flagGap;
         g.beginFill(col,1);
         g.moveTo(fx,fy);
         g.lineTo(fx,fy + fh);
         g.lineTo(fx + flagW,fy + fh * 0.5);
         g.endFill();
      }
      // PERSUADED / FAILED stay 16.5 px. Faces 1 and 2 go through hzdFont so the bold face is the installed
      // one (Exo bold, or Roboto Alt_Bold). Face 0, face 3, a missing Font module, or a failed check use the game bold.
      private function hzdPmBold(s:String) : String
      {
         var f:int = int(this.hzdCfg.DlgFont) >= 0 ? int(this.hzdCfg.DlgFont) : int(this.hzdCfg.FontFace);
         if(f == 1 || f == 2)
         {
            var picked:String = this.hzdFont("_Bold", s);
            var base:String = f == 2 ? "$Horizon_Font_Alt" : "$Horizon_Font";
            if(picked == base + "_Bold") { return picked; }
         }
         return "$MAIN_Font_Bold";
      }
      private function hzdPmDraw() : void
      {
         var s:Sprite = this.hzdPm;
         var o:Object = this.hzdPmRead();
         var fs:Number = this.hzdPmFs();
         var u:Number = fs / 13;
         var sig:String = (o.won ? "W" : (o.failed ? "F" : (o.last ? "L" : "P"))) + ":" + o.score + ":" + o.goal + ":" + o.turns + ":" + o.ghost + ":" + o.col + ":" + fs + ":" + int(this.hzdCfg.DlgFont) + ":" + int(this.hzdCfg.FontFace) + ":" + Number(this.hzdCfg.DlgBgOpacity) + ":" + int(this.hzdCfg.DlgBgColor) + ":" + int(this.hzdCfg.AccentColor) + ":" + String(this.hzdCfg.AccentHex);
         if(sig == this.hzdPmSig && s.visible && this.hzdPmW > 0 && this.hzdPmH > 0)
         {
            this.hzdPmPlace(this.hzdPmW,this.hzdPmH);
            return;
         }
         this.hzdPmSig = sig;
         while(s.numChildren > 0) { s.removeChildAt(0); }
         s.graphics.clear();
         var col:uint = uint(o.col);
         var bg:uint = 0x0B1218;
         try { bg = this.hzdBgCol(); } catch(ebg:Error) { bg = 0x0B1218; }
         var light:Boolean = false;
         try { light = this.hzdLight(bg); } catch(elb:Error) { light = false; }
         var mut:uint = light ? 0x4A5A64 : 0x8FA3AE;
         var titleStr:String = "PERSUASION";
         var titleCol:uint = mut;
         var mark:int = 0;
         if(o.won) { titleStr = "PERSUADED"; titleCol = col; mark = 1; }
         else if(o.failed) { titleStr = "FAILED"; titleCol = col; mark = 2; }
         var titleFs:Number = fs;
         var titleBold:Boolean = false;
         if(mark != 0) { titleFs = 16.5; titleBold = true; }
         var fracTxt:String = "";
         if(o.have) { fracTxt = String(int(Math.max(0,Number(o.score)))) + "/" + String(int(Number(o.goal))); }
         var turnsTxt:String = "";
         if(!isNaN(o.turns) && o.turns >= 0 && o.turns < 1000)
         {
            var ti:int = int(o.turns);
            turnsTxt = "TURNS " + (ti < 10 ? "0" + String(ti) : String(ti));
         }
         var pad:Number = Math.round(14 * u);
         var gap:Number = Math.round(8 * u);
         var pillX:Number = 0;
         var pillY:Number = 0;
         var pillH:Number = 0;
         var iconS:Number = Math.max(13,Math.round(fs * 0.92));
         var iconW:Number = iconS + Math.round(6 * u);
         var title:TextField = this.hzdText(s,titleStr,"",titleFs,titleCol,Math.round(titleFs * 0.16),0,0,0,"left",false);
         if(titleBold && title != null)
         {
            var tbf:TextFormat = title.getTextFormat();
            tbf.font = this.hzdPmBold(titleStr);
            tbf.size = 16.5;
            title.defaultTextFormat = tbf;
            title.setTextFormat(tbf);
         }
         var turnsT:TextField = turnsTxt.length > 0 ? this.hzdText(s,turnsTxt,"",fs,col,Math.round(fs * 0.08),0,0,0,"left",false) : null;
         var fracT:TextField = fracTxt.length > 0 ? this.hzdText(s,fracTxt,"",fs,col,Math.round(fs * 0.06),0,0,0,"left",false) : null;
         var turnsW:Number = turnsT != null ? Math.round(turnsT.textWidth + 20 * u) : 0;
         var fracW:Number = fracT != null ? Math.round(fracT.textWidth) : 0;
         var flagGap:Number = Math.max(3,Math.round(4 * u));
         var flagW:Number = Math.max(6,Math.round(7 * u));
         var meterH:Number = Math.max(10,Math.round(10 * u));
         var headerW:Number = pad + iconW + title.textWidth + gap + (turnsW > 0 ? gap + turnsW : 0) + pad;
         var minBar:Number = Math.round(120 * u);
         var meterNeed:Number = pad + (o.have ? minBar + flagGap + flagW : 0) + (fracW > 0 ? gap + fracW : 0) + pad;
         var W:Number = Math.round(Math.max(300 * u,headerW,meterNeed));
         var row1H:Number = Math.max(title.height,iconS);
         if(turnsT != null && turnsT.height + 6 * u > row1H) { row1H = turnsT.height + 6 * u; }
         var y1:Number = pad;
         title.x = pad + iconW;
         title.y = Math.round(y1 + Math.max(0,(row1H - title.height) / 2));
         if(turnsT != null)
         {
            pillH = Math.round(Math.max(fs + 8 * u,turnsT.height + 6 * u));
            pillX = W - pad - turnsW;
            pillY = Math.round(y1 + Math.max(0,(row1H - pillH) / 2));
            turnsT.x = Math.round(pillX + (turnsW - turnsT.width) / 2);
            turnsT.y = Math.round(pillY + (pillH - turnsT.height) / 2);
         }
         var titleRoom:Number = (turnsT != null ? pillX - gap : W - pad) - title.x;
         this.hzdClip(title,Math.max(20,titleRoom));
         var yM:Number = y1 + row1H + gap;
         var rowMH:Number = meterH;
         if(fracT != null && fracT.height > rowMH) { rowMH = fracT.height; }
         var H:Number = Math.round((o.have ? yM + rowMH : y1 + row1H) + pad);
         var bo:Number = Number(this.hzdCfg.DlgBgOpacity);
         if(isNaN(bo)) { bo = 0.85; }
         bo = Math.max(0.35,Math.min(1,bo));
         var rad:Number = Math.round(14 * u);
         var g:* = s.graphics;
         g.beginFill(bg,bo);
         g.drawRoundRect(0,0,W,H,rad,rad);
         g.endFill();
         g.lineStyle(Math.max(1,Math.round(u)),col,0.8,true);
         g.beginFill(col,0);
         g.drawRoundRect(0.5,0.5,W - 1,H - 1,rad,rad);
         g.endFill();
         g.lineStyle();
         var iconY:Number = y1 + Math.max(0,(row1H - iconS) / 2);
         if(mark == 0) { this.hzdPmSpeech(g,pad,iconY,iconS,col); }
         else { this.hzdPmMark(g,pad,iconY,iconS,col,mark == 1); }
         if(turnsT != null)
         {
            g.beginFill(col,0.16);
            g.drawRoundRect(pillX,pillY,turnsW,pillH,pillH,pillH);
            g.endFill();
         }
         if(o.have)
         {
            var reserve:Number = flagGap + flagW + (fracW > 0 ? gap + fracW : 0);
            var tx0:Number = pad;
            var tw:Number = W - pad - tx0 - reserve;
            if(tw < meterH) { tw = meterH; }
            var barY:Number = Math.round(yM + Math.max(0,(rowMH - meterH) / 2));
            g.beginFill(light ? 0x0E151B : 0xFFFFFF,light ? 0.12 : 0.1);
            g.drawRoundRect(tx0,barY,tw,meterH,meterH,meterH);
            g.endFill();
            if(fracT != null)
            {
               fracT.x = Math.round(W - pad - fracT.width);
               fracT.y = Math.round(yM + Math.max(0,(rowMH - fracT.height) / 2));
            }
            var meterAt:int = 0;
            if(Number(o.gfrac) > Number(o.frac) + 0.001)
            {
               var ghost:Sprite = new Sprite();
               ghost.mouseEnabled = false;
               ghost.mouseChildren = false;
               ghost.x = tx0;
               ghost.y = barY;
               ghost.graphics.beginFill(col,0.32);
               ghost.graphics.drawRoundRect(0,0,tw,meterH,meterH,meterH);
               ghost.graphics.endFill();
               ghost.scrollRect = new Rectangle(0,0,Math.max(1,Math.min(tw,tw * Number(o.gfrac))),meterH + 1);
               s.addChildAt(ghost,meterAt);
               meterAt++;
            }
            if(Number(o.frac) > 0)
            {
               var fill:Sprite = new Sprite();
               fill.mouseEnabled = false;
               fill.mouseChildren = false;
               fill.x = tx0;
               fill.y = barY;
               fill.graphics.beginFill(col,0.92);
               fill.graphics.drawRoundRect(0,0,tw,meterH,meterH,meterH);
               fill.graphics.endFill();
               fill.scrollRect = new Rectangle(0,0,Math.max(1,Math.min(tw,tw * Number(o.frac))),meterH + 1);
               s.addChildAt(fill,meterAt);
            }
            var ticks:Sprite = new Sprite();
            ticks.mouseEnabled = false;
            ticks.mouseChildren = false;
            ticks.x = tx0;
            ticks.y = barY;
            this.hzdPmMeterMarks(ticks.graphics,tw,meterH,Number(o.goal),col,u,bg,flagGap,flagW);
            s.addChild(ticks);
         }
         if(isNaN(W) || isNaN(H) || W < 40 || H < 20) { throw new Error("pm"); }
         this.hzdPmW = W;
         this.hzdPmH = H;
         this.hzdPmPlace(W,H);
      }

      // =================== v0.37 shared settings reader (hzd37) ===================
      // ONE helper, spliced into every movie that reads the settings (hudmenu + hudmenu_lrg as hz37, hudmessagesmenu
      // x2 as hzc37, dialoguemenu x2 as hzd37; generated from /workspace/v037/work/hzini_shared.as, so the copies are
      // identical apart from the prefix). It reads HorizonUI.default.ini, HorizonUI.user.ini, HorizonUI.state.ini and the
      // legacy HorizonUI.ini (paths relative to Data/Interface) one after the other and hands every waiting callback the
      // merged text: the defaults with user.ini laid over (hzd37Compose; mirrors HZF::Compose in HorizonUI.dll). A missing
      // file is normal: its IOErrorEvent is caught and simply counts as "no file" (nothing is thrown or logged).
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hzd37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hzd37_BOM:String = String.fromCharCode(0xFEFF);
      private var hzd37Ldr:URLLoader = null;
      private var hzd37Step:int = 0;          // 0 idle, n = reading hzd37_FILES[n - 1]
      private var hzd37T0:Number = 0;
      private var hzd37Got:Array = null;
      private var hzd37Q:Array = [];          // callbacks of the running read
      private var hzd37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private function hzd37Ws(c:String) : Boolean { return c == " " || c == "\t" || c == "\r" || c == "\n"; }
      private function hzd37Trim(s:String) : String
      {
         var b:int = 0;
         var e:int = s.length;
         while(b < e && (this.hzd37Ws(s.charAt(b)) || s.charAt(b) == hzd37_BOM)) { b++; }
         while(e > b && this.hzd37Ws(s.charAt(e - 1))) { e--; }
         return s.substring(b,e);
      }
      private function hzd37Blank(s:String) : Boolean { return this.hzd37Trim(s).length == 0; }
      private function hzd37Lines(t:String) : Array
      {
         var out:Array = [];
         if(t == null || t.length == 0) { return out; }
         if(t.charAt(0) == hzd37_BOM) { t = t.substr(1); }
         var p:int = 0;
         while(p < t.length)
         {
            var q:int = t.indexOf("\n",p);
            var ln:String = q < 0 ? t.substr(p) : t.substring(p,q);
            if(ln.length > 0 && ln.charAt(ln.length - 1) == "\r") { ln = ln.substr(0,ln.length - 1); }
            out.push(ln);
            if(q < 0) { break; }
            p = q + 1;
         }
         return out;
      }
      // "[Name]" -> canonical section name (lower case; pre-v0.31 names aliased), or null
      private function hzd37Hdr(ln:String) : String
      {
         var t:String = this.hzd37Trim(ln);
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return this.hzd37Trim(t.substring(1,e)).toLowerCase();
      }
      private function hzd37Alias(n:String) : String
      {
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // key=value line -> {k: key lower case without blanks, o: key as written, v: value up to ';'}; null otherwise
      private function hzd37KV(ln:String) : Object
      {
         var t:String = this.hzd37Trim(ln);
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         var o:String = this.hzd37Trim(t.substr(0,eq));
         var k:String = o.split(" ").join("").split("\t").join("").toLowerCase();
         if(k.length == 0) { return null; }
         var v:String = t.substr(eq + 1);
         var sc:int = v.indexOf(";");
         if(sc >= 0) { v = v.substr(0,sc); }
         return {"k":k,"o":o,"v":this.hzd37Trim(v)};
      }
      // sections; a second copy / the pre-v0.31 name merges into the first, old names first so the new name wins
      private function hzd37Parse(t:String) : Object
      {
         var d:Object = {"secs":[{"n":"","raw":[],"order":[],"kv":{}}],"idx":{"s_":0}};
         var lines:Array = this.hzd37Lines(t);
         var pass:int = 0;
         while(pass < 2)
         {
            var cur:Object = d.secs[0];
            var old:Boolean = false;
            for each(var ln:String in lines)
            {
               var h:String = this.hzd37Hdr(ln);
               if(h != null)
               {
                  old = h == "cards v0.26" || h == "effects v0.26";
                  var n:String = this.hzd37Alias(h);
                  if((pass == 0) != old) { cur = null; continue; }
                  if(d.idx["s_" + n] == undefined) { d.idx["s_" + n] = d.secs.length; d.secs.push({"n":n,"raw":[],"order":[],"kv":{}}); }
                  cur = d.secs[int(d.idx["s_" + n])];
                  cur.raw.push(ln);
                  continue;
               }
               if(cur == null) { continue; }
               if(pass == 0 && cur.n == "") { continue; }
               cur.raw.push(ln);
               var kv:Object = this.hzd37KV(ln);
               if(kv == null) { continue; }
               if(cur.kv["k_" + kv.k] == undefined) { cur.order.push(kv.k); }
               cur.kv["k_" + kv.k] = [kv.o,kv.v];
            }
            pass++;
         }
         return d;
      }
      private function hzd37SecOf(d:Object, kl:String) : String
      {
         for each(var s:Object in d.secs) { if(s.n != "" && s.kv["k_" + kl] != undefined) { return String(s.n); } }
         return "";
      }
      private function hzd37Flush(out:Array, sec:String, U:Object, ext:Object, flushed:Object) : void
      {
         if(sec == "" || flushed["s_" + sec] == true) { return; }
         flushed["s_" + sec] = true;
         var e:Array = ext["s_" + sec];
         if(e == null || e.length == 0) { return; }
         var blanks:int = 0;
         while(out.length > 0 && this.hzd37Blank(String(out[out.length - 1]))) { out.pop(); blanks++; }
         for each(var k:String in e)
         {
            var p:Array = U["s_" + sec]["k_" + k];
            out.push(String(p[0]) + "=" + String(p[1]));
         }
         while(blanks > 0) { out.push(""); blanks--; }
      }
      // base with the player's values laid over it: known keys replace the base value in place, unknown keys of a known
      // section are appended to it, sections the base lacks are appended verbatim. CRLF out.
      private function hzd37Overlay(base:String, over:String) : String
      {
         var B:Object = this.hzd37Parse(base);
         var O:Object = this.hzd37Parse(over);
         var U:Object = {};
         var ext:Object = {};
         var unk:Array = [];
         for each(var s:Object in O.secs)
         {
            if(s.n != "" && B.idx["s_" + s.n] == undefined) { unk.push(s); continue; }
            for each(var kl:String in s.order)
            {
               var sec:String = s.n == "" ? this.hzd37SecOf(B,kl) : String(s.n);
               if(sec == "") { continue; }
               if(U["s_" + sec] == undefined) { U["s_" + sec] = {}; }
               var m:Object = U["s_" + sec];
               if(m["k_" + kl] == undefined && B.secs[int(B.idx["s_" + sec])].kv["k_" + kl] == undefined)
               {
                  if(ext["s_" + sec] == undefined) { ext["s_" + sec] = []; }
                  (ext["s_" + sec] as Array).push(kl);
               }
               m["k_" + kl] = s.kv["k_" + kl];
            }
         }
         var out:Array = [];
         var cur:String = "";
         var flushed:Object = {};
         for each(var ln:String in this.hzd37Lines(base))
         {
            var h:String = this.hzd37Hdr(ln);
            if(h != null) { this.hzd37Flush(out,cur,U,ext,flushed); cur = this.hzd37Alias(h); out.push(ln); continue; }
            if(cur != "")
            {
               var kv:Object = this.hzd37KV(ln);
               if(kv != null && U["s_" + cur] != undefined && U["s_" + cur]["k_" + kv.k] != undefined)
               {
                  out.push(kv.o + "=" + String(U["s_" + cur]["k_" + kv.k][1]));
                  continue;
               }
            }
            out.push(ln);
         }
         this.hzd37Flush(out,cur,U,ext,flushed);
         for each(var us:Object in unk)
         {
            if(out.length > 0 && !this.hzd37Blank(String(out[out.length - 1]))) { out.push(""); }
            var r:Array = (us.raw as Array).concat();
            while(r.length > 0 && this.hzd37Blank(String(r[r.length - 1]))) { r.pop(); }
            for each(var rl:String in r) { out.push(rl); }
         }
         return out.length == 0 ? "" : out.join("\r\n") + "\r\n";
      }
      // def / user / state / legacy texts (null = file missing) -> the effective settings text, or null
      private function hzd37Compose(def:String, user:String, state:String, leg:String) : String
      {
         var hd:Boolean = def != null && def.length > 0;
         var hl:Boolean = leg != null && leg.length > 0;
         var base:String = hd ? def : (hl ? leg : null);
         var over:String = user != null ? user : (state == null && hd && hl ? leg : null);   // an old DLL still saves HorizonUI.ini
         if(base == null) { return over == null ? null : this.hzd37Overlay(over,""); }
         return this.hzd37Overlay(base,over != null ? over : "");
      }
      // read all four files, then cb(mergedText or null). Requests during a read get one fresh read afterwards.
      private function hzd37IniRead(cb:Function) : void
      {
         var now:Number = new Date().getTime();
         if(this.hzd37Step != 0 && now - this.hzd37T0 < 3000)
         {
            if(this.hzd37N.indexOf(cb) < 0) { this.hzd37N.push(cb); }
            return;
         }
         if(this.hzd37Step != 0 && this.hzd37Ldr != null) { try { this.hzd37Ldr.close(); } catch(e0:Error) { } }   // stuck: start over
         var q:Array = this.hzd37Step != 0 ? this.hzd37Q.concat(this.hzd37N) : [];
         this.hzd37N = [];
         if(q.indexOf(cb) < 0) { q.push(cb); }
         this.hzd37Q = q;
         this.hzd37Begin();
      }
      private function hzd37Begin() : void
      {
         this.hzd37Got = [null,null,null,null];
         this.hzd37T0 = new Date().getTime();
         this.hzd37Next(0);
      }
      private function hzd37Next(i:int) : void
      {
         this.hzd37Step = i + 1;
         if(i >= hzd37_FILES.length) { this.hzd37Ldr = null; this.hzd37Done(); return; }
         try
         {
            this.hzd37Ldr = new URLLoader();
            this.hzd37Ldr.addEventListener(Event.COMPLETE,this.hzd37OnOk);
            this.hzd37Ldr.addEventListener(IOErrorEvent.IO_ERROR,this.hzd37OnErr);
            this.hzd37Ldr.addEventListener("securityError",this.hzd37OnErr);
            this.hzd37Ldr.load(new URLRequest(String(hzd37_FILES[i])));
         }
         catch(err:Error) { this.hzd37Next(i + 1); }
      }
      private function hzd37OnOk(e:Event) : void
      {
         if(e == null || e.target != this.hzd37Ldr) { return; }
         var i:int = this.hzd37Step - 1;
         try { this.hzd37Got[i] = String(this.hzd37Ldr.data); } catch(err:Error) { }
         this.hzd37Next(i + 1);
      }
      private function hzd37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hzd37Ldr) { return; }
         this.hzd37Next(this.hzd37Step);   // missing file: normal, no error
      }
      private function hzd37Done() : void
      {
         this.hzd37Step = 0;
         var g:Array = this.hzd37Got;
         var txt:String = null;
         try { txt = this.hzd37Compose(g[0],g[1],g[2],g[3]); } catch(errC:Error) { txt = null; }
         var cbs:Array = this.hzd37Q;
         this.hzd37Q = [];
         for each(var cb:Function in cbs) { try { cb(txt); } catch(errCb:Error) { } }
         if(this.hzd37N.length > 0 && this.hzd37Step == 0) { this.hzd37Q = this.hzd37N; this.hzd37N = []; this.hzd37Begin(); }
      }
      // =================== end shared settings reader ===================

      // =================== end Horizon UI Comms (Dialogue) v0.35 ===================
   }
}

