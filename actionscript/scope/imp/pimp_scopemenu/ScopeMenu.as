package
{
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.IMenu;
   import Shared.Components.ButtonControls.ButtonData.ButtonBaseData;
   import Shared.Components.ButtonControls.ButtonData.UserEventData;
   import Shared.Components.ButtonControls.Buttons.ButtonBase;
   import Shared.EnumHelper;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.Rectangle;
   import flash.display.Sprite;
   import flash.events.IOErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getTimer;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol43")]
   public class ScopeMenu extends IMenu
   {
      
      public static const TIMELINE_SCOPE_ANIMATION_DONE:String = "Timeline_Scope_Animation_Done";
      
      public var StandardScopeCircle_mc:MovieClip;
      
      public var HoldBreathButton_mc:ButtonBase;
      
      public var ButtonBackground_mc:MovieClip;
      
      private const BUTTON_BACKGROUND_LEFT_BUFFER:uint = 8;
      
      private const BUTTON_BACKGROUND_RIGHT_BUFFER:uint = 13;
      
      private const ZOOM_LEVEL_x2:* = EnumHelper.GetEnum(0);
      
      private const ZOOM_LEVEL_x4:* = EnumHelper.GetEnum();
      
      private const ZOOM_LEVEL_x8:* = EnumHelper.GetEnum();
      
      private const ZOOM_LEVEL_x40:* = EnumHelper.GetEnum();
      
      private var CurrentZoomLevel:int = this.ZOOM_LEVEL_x2;
      
      private var TargetZoomLevel:int = this.CurrentZoomLevel;
      
      private var bIsAnimating:Boolean = false;
      
      public function ScopeMenu()
      {
         super();
         addFrameScript(0,this.frame1);
         this.HoldBreathButton_mc.addEventListener(ButtonBase.BUTTON_REDRAWN_EVENT,this.UpdateBackground);
         this.HoldBreathButton_mc.SetButtonData(new ButtonBaseData("$Hold Breath",new UserEventData("Steady",null)));
         try { this.hzpInit(); } catch(hzpErr:Error) { }
      }
      
      public function get ZoomLevel() : MovieClip
      {
         var _loc1_:MovieClip = null;
         if(this.StandardScopeCircle_mc != null)
         {
            _loc1_ = this.StandardScopeCircle_mc.ZoomLevel_mc;
         }
         return _loc1_;
      }
      
      override public function onAddedToStage() : void
      {
         super.onAddedToStage();
         BSUIDataManager.Subscribe("ZoomLevelData",this.onZoomLevelDataChange);
         BSUIDataManager.Subscribe("ScopeScalingData",this.onScopeScalingDataChange);
      }
      
      private function UpdateBackground() : *
      {
         var _loc1_:Rectangle = this.HoldBreathButton_mc.getBounds(this);
         this.ButtonBackground_mc.width = _loc1_.width + this.BUTTON_BACKGROUND_LEFT_BUFFER + this.BUTTON_BACKGROUND_RIGHT_BUFFER;
         this.ButtonBackground_mc.x = _loc1_.left - this.BUTTON_BACKGROUND_LEFT_BUFFER;
      }
      
      public function SetOverlay(param1:uint) : *
      {
         this.gotoAndStop(param1 + 1);
         this.SetZoomLevel(this.CurrentZoomLevel,true);
      }
      
      protected function onZoomLevelDataChange(param1:FromClientDataEvent) : *
      {
         this.SetZoomLevel(param1.data.iZoomLevel);
      }
      
      protected function onScopeScalingDataChange(param1:FromClientDataEvent) : *
      {
         scaleX = param1.data.fScaleX;
         scaleY = param1.data.fScaleY;
         this.HoldBreathButton_mc.scaleX = 1 / scaleX;
         this.HoldBreathButton_mc.scaleY = 1 / scaleY;
      }
      
      private function SetZoomLevel(param1:int, param2:Boolean = false) : *
      {
         if(this.ZoomLevel != null)
         {
            if(param2)
            {
               this.ZoomLevel.gotoAndPlay(this.GetUpAnimationName(param1));
               this.CurrentZoomLevel = param1;
            }
            else
            {
               this.TargetZoomLevel = param1;
               this.ProcessPendingZoomLevel();
            }
         }
         else
         {
            this.CurrentZoomLevel = param1;
         }
      }
      
      private function ProcessPendingZoomLevel() : *
      {
         if(this.ZoomLevel != null)
         {
            if(!this.bIsAnimating)
            {
               if(this.CurrentZoomLevel != this.TargetZoomLevel)
               {
                  this.bIsAnimating = true;
                  if(!this.ZoomLevel.hasEventListener(TIMELINE_SCOPE_ANIMATION_DONE))
                  {
                     this.ZoomLevel.addEventListener(TIMELINE_SCOPE_ANIMATION_DONE,this.onTimelineScopeAnimationDone);
                  }
                  if(this.CurrentZoomLevel < this.TargetZoomLevel)
                  {
                     ++this.CurrentZoomLevel;
                     this.ZoomLevel.gotoAndPlay(this.GetUpAnimationName(this.CurrentZoomLevel));
                  }
                  else
                  {
                     --this.CurrentZoomLevel;
                     this.ZoomLevel.gotoAndPlay(this.GetDownAnimationName(this.CurrentZoomLevel));
                  }
               }
            }
         }
      }
      
      private function onTimelineScopeAnimationDone(param1:Event) : *
      {
         this.bIsAnimating = false;
         this.ProcessPendingZoomLevel();
      }
      
      private function GetNumberFromZoomLevel(param1:int) : int
      {
         var _loc2_:int = 0;
         switch(param1)
         {
            case this.ZOOM_LEVEL_x2:
               _loc2_ = 2;
               break;
            case this.ZOOM_LEVEL_x4:
               _loc2_ = 4;
               break;
            case this.ZOOM_LEVEL_x8:
               _loc2_ = 8;
               break;
            case this.ZOOM_LEVEL_x40:
               _loc2_ = 40;
         }
         return _loc2_;
      }
      
      private function GetUpAnimationName(param1:int) : String
      {
         var _loc2_:String = "Idle";
         if(param1 != this.ZOOM_LEVEL_x2)
         {
            _loc2_ = "up_" + this.GetNumberFromZoomLevel(param1).toString() + "x";
         }
         return _loc2_;
      }
      
      private function GetDownAnimationName(param1:int) : String
      {
         var _loc2_:String = "up_40x";
         if(param1 != this.ZOOM_LEVEL_x40)
         {
            _loc2_ = "down_" + this.GetNumberFromZoomLevel(param1).toString() + "x";
         }
         return _loc2_;
      }
      
      // =================== Horizon UI Scope module (v0.42.0): hold-breath chip ===================
      // The game's hold-breath prompt (HoldBreathButton_mc: a ButtonBase with "$Hold Breath" / user event "Steady", and the
      // ButtonBackground_mc behind it) is set visible = false while the chip is on; nothing is removed and the game's own
      // handling of the "Steady" control is not touched (this menu never handled it; the button only shows the key).
      // The chip sits where the hidden button sits and keeps its 1:1 size against the scope zoom scale (the button's own
      // counter-scale), moved by [Scope] ScopeChipX / ScopeChipY (1080p units from the game's spot, X + = right, Y + = up)
      // and sized by ScopeChipScale (0.60 - 1.60, 1 = the game's size). Icon tile = an original target icon drawn in code
      // (ring, 4 ticks, center dot) + the hold-breath key name (r3: the game's own key text on the hidden button, else the
      // "Steady" control map entry, else SHIFT / L3; never "?"), label, slim O2 meter:
      // the scope menu gets no breath value, so the meter is O2 (PlayerFrequentData fOxygen / fMaxO2CO2, the same source as
      // the HUD's O2 bar; verified in game). O2 colors = the main HUD vitals card (hz26Band / hz26WarnCol): under 35 % the
      // bar and the border are amber, under 15 % red; OUT OF BREATH (red, no fill) after 2 readings in a row under 1 %
      // (a single 0 reading when the scope opens never flashes it). HOLDING BREATH = O2 fell on 2 readings in a row, and
      // that state stays up for at least 900 ms (the game sends no breath-hold state, so a steady O2 drain also shows it).
      // Settings: [Scope] ScopeHoldBreathChip (0 = the game's prompt) / ScopeChipX / ScopeChipY / ScopeChipScale and [Style]
      // AccentColor / AccentHex / CardOpacity / TextScale / FontFace / HeaderStyle (same meaning as on the HUD). Read when
      // the scope opens and every 5 s after.
      private static const HZP_VERSION:String = "0.42.0.9";   // 0.42.0.9: scope movie version (= the test build's DLL file version)
      private static const HZP_BUILD:String = "0.42.0.9";   // 0.42.0.9: scope movie build label (= the test build's DLL file version)
      private static const HZP_ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZP_ACC:uint = 0x3FD0E0;
      private static const HZP_O2:uint = 0x4DB6FF;
      private static const HZP_AMB:uint = 0xF2A93B;
      private static const HZP_RED:uint = 0xFF5B5B;
      private static const HZP_BG:uint = 0x0B1218;
      private static const HZP_TXT:uint = 0xF2F7F9;
      private static const HZP_DIM:uint = 0x8E9CA4;
      private static const HZP_MINPX:Number = 13;
      private static const HZP_KPAD:Number = 10;        // 0.42.0.5: keycap padding right of the key text (was 8)
      private static const HZP_KHEAD:Number = 1.08;     // 0.42.0.5: headroom on the measured key text width (bold faces, renderer rounding)
      private static const HZP_KMINW:Number = 14;       // 0.42.0.5: smallest key text slot (a one-glyph gamepad face such as L3)
      private static const HZP_KEX:Number = 16;         // 0.42.0.9: extra width for the key text only. The label slot does not use it.
      private static const HZP_RPAD:Number = 18;        // 0.42.0.5: panel padding right of the O2 meter (was 14)
      private static const HZP_GLOW:Number = 8;         // 0.42.0.8: transparent pad so a parent scrollRect can include the held edge
      private static const HZP_LABEX:Number = 32;       // 0.42.0.8: extra label field past textWidth so the held card is slightly longer
      private static const HZP_O2_WARN:Number = 0.35;   // = the HUD vitals card warning band (hz26Band 1, hz26WarnCol amber)
      private static const HZP_O2_CRIT:Number = 0.15;   // = the HUD vitals card critical band (hz26Band 2, hz26WarnCol red)
      private static const HZP_LRG:Boolean = false;
      private static const HZP_LBL:Array = ["HOLD BREATH","HOLDING BREATH","HOLD BREATH","OUT OF BREATH"];   // [2] unused since r2 (bands color the chip)
      private var hzpOn:Boolean = true;
      private var hzpReady:Boolean = false;
      private var hzpSub:Boolean = false;
      private var hzpHid:Boolean = false;
      private var hzpS:Object = {"AccentColor":0,"AccentHex":-1,"CardOpacity":1,"TextScale":1,"FontFace":1,"HeaderStyle":0,"ChipX":0,"ChipY":0,"ChipS":1,"HudScale":1};
      private var hzpChip:Sprite = null;
      private var hzpW:Number = 0;
      private var hzpH:Number = 32;
      private var hzpO2:Number = -1;          // 0 - 1, -1 = no data yet
      private var hzpFallT:int = -100000;     // last time O2 went down on 2 readings in a row (getTimer)
      private var hzpFallN:int = 0;           // falling readings in a row
      private var hzpZeroN:int = 0;           // readings under 1 % in a row
      private var hzpSig:String = "";
      private var hzpMaskOnce:Boolean = false;   // 0.42.0.8: a non-round ancestor mask is widened once, not every frame
      private var hzpIniT:int = -100000;
      private var hzpFontOk:Object = {};
      private var hzpLastX:Number = NaN;
      private var hzpLastY:Number = NaN;
      private var hzpKeyTx:String = "";      // r3: key name shown in the keycap
      private var hzpKeyFace:String = null;  // r3: the game's glyph face when the key came from the controller button
      private var hzpMap:Array = null;       // r3: ControlMapData vMappedEvents
      private var hzpPad:Boolean = false;    // r3: a controller is in use (uiController > keyboard / mouse)
      private var hzpErr:Boolean = false;    // r3: an error turned the chip off for this scope session
      private var hzpBar:flash.display.Shape = null;   // O2 fill. Its own shape, so a tick does not redraw the frame.
      private var hzpLbl:TextField = null;          // label field, kept for the one-time clip line
      private var hzpDiag:String = "";              // first HOLDING BREATH clip report; the DLL logs it once
      private var hzpMx:Number = 0;
      private var hzpMy:Number = 0;
      private var hzpMw:Number = 120;

      private function hzpInit() : void
      {
         this.hzpChip = new Sprite();
         this.hzpChip.name = "hzpChip";
         this.hzpChip.mouseEnabled = false;
         this.hzpChip.mouseChildren = false;
         this.hzpChip.visible = false;
         addChild(this.hzpChip);
         this.addEventListener(Event.ENTER_FRAME,this.hzpTick);
         try { this.HoldBreathButton_mc.addEventListener(ButtonBase.BUTTON_REDRAWN_EVENT,this.hzpRedrawn); } catch(e1:Error) { }
         this.hzpRead();
      }
      private function hzpRead() : void
      {
         this.hzpIniT = getTimer();
         try { this.hzp37IniRead(this.hzpOnIni); } catch(e:Error) { this.hzpReady = true; }
      }
      private function hzpOnIni(txt:String) : void
      {
         var on:Boolean = true;
         var st:Object = {"AccentColor":0,"AccentHex":-1,"CardOpacity":1,"TextScale":1,"FontFace":1,"HeaderStyle":0,"ChipX":0,"ChipY":0,"ChipS":1,"HudScale":1};
         if(txt != null)
         {
            var sec:String = "";
            for each(var ln:String in this.hzp37Lines(txt))
            {
               var h:String = this.hzp37Hdr(ln);
               if(h != null) { sec = this.hzp37Alias(h); continue; }
               var kv:Object = this.hzp37KV(ln);
               if(kv == null) { continue; }
               var k:String = String(kv.k);
               var v:String = String(kv.v);
               var nv:Number = Number(v);
               if(sec == "scope")
               {
                  if(k == "scopeholdbreathchip") { on = !(v == "0" || v.toLowerCase() == "false"); }
                  else if(k == "scopechipx" && !isNaN(nv)) { st.ChipX = Math.round(Math.max(-900,Math.min(900,nv))); }
                  else if(k == "scopechipy" && !isNaN(nv)) { st.ChipY = Math.round(Math.max(-500,Math.min(500,nv))); }
                  else if(k == "scopechipscale" && !isNaN(nv)) { st.ChipS = Math.round(Math.max(0.6,Math.min(1.6,nv)) * 100) / 100; }
               }
               else if(sec == "style")
               {
                  if(k == "accentcolor" && !isNaN(nv)) { st.AccentColor = Math.max(0,Math.min(13,int(nv))); }
                  else if(k == "accenthex") { st.AccentHex = this.hzpHex(v); }
                  else if(k == "cardopacity" && !isNaN(nv)) { st.CardOpacity = Math.max(0.2,Math.min(1.6,nv)); }
                  else if(k == "textscale" && !isNaN(nv)) { st.TextScale = Math.max(0.8,Math.min(1.3,nv)); }
                  else if(k == "fontface" && !isNaN(nv)) { st.FontFace = Math.max(0,Math.min(3,int(nv))); }
                  else if(k == "headerstyle" && !isNaN(nv)) { st.HeaderStyle = Math.max(0,Math.min(1,int(nv))); }
                  else if(k == "hudscale" && !isNaN(nv)) { st.HudScale = nv; }
               }
            }
         }
         this.hzpOn = on && !this.hzpErr;
         this.hzpS = st;
         this.hzpSig = "";
         this.hzpReady = true;
      }
      private function hzpHex(v:String) : int
      {
         if(v == null) { return -1; }
         v = v.replace(/^\s+|\s+$/g,"").replace("#","").replace("0x","").replace("0X","");
         if(v.length != 6 || !/^[0-9A-Fa-f]{6}$/.test(v)) { return -1; }
         return int(parseInt(v,16));
      }
      private function hzpAccent() : uint
      {
         var a:int = int(this.hzpS.AccentColor);
         if(a == 13 && int(this.hzpS.AccentHex) >= 0) { return uint(this.hzpS.AccentHex); }
         if(a >= 0 && a < HZP_ACCENTS.length) { return uint(HZP_ACCENTS[a]); }
         return HZP_ACC;
      }
      private function hzpOnFreq(e:FromClientDataEvent) : void
      {
         try
         {
            var d:Object = e.data;
            var o2:Number = Number(d.fOxygen);
            var mo2:Number = Number(d.fMaxO2CO2);
            if(isNaN(o2) || isNaN(mo2) || mo2 <= 0) { return; }
            var f:Number = Math.max(0,Math.min(1,o2 / mo2));
            if(this.hzpO2 >= 0 && f < this.hzpO2 - 0.0005) { this.hzpFallN++; } else { this.hzpFallN = 0; }
            if(this.hzpFallN >= 2) { this.hzpFallT = getTimer(); }
            this.hzpZeroN = f < 0.01 ? this.hzpZeroN + 1 : 0;
            this.hzpO2 = f;
         }
         catch(err:Error) { }
      }
      // the button redraws itself visible (MinimalButton.UpdateVisibility): hide it again at once
      private function hzpRedrawn(e:Event) : void
      {
         if(this.hzpHid) { this.hzpHideVan(true); }
      }
      private function hzpHideVan(hide:Boolean) : void
      {
         var b:* = this.HoldBreathButton_mc;
         if(hide)
         {
            if(b != null) { b.visible = false; }
            if(this.ButtonBackground_mc != null) { this.ButtonBackground_mc.visible = false; }
            this.hzpHid = true;
            return;
         }
         if(!this.hzpHid) { return; }
         this.hzpHid = false;
         try { if(b != null) { b.visible = b.Visible; } } catch(e1:Error) { if(b != null) { b.visible = true; } }
         if(this.ButtonBackground_mc != null) { this.ButtonBackground_mc.visible = true; }
      }
      private function hzpTick(e:Event) : void
      {
         try { this.hzpFrame(); } catch(err:Error) { this.hzpFail(); }
      }
      // r3: any error -> the game's own prompt for the rest of this scope session (chip hidden, the button shown again)
      private function hzpFail() : void
      {
         this.hzpErr = true;
         this.hzpOn = false;
         try { this.hzpHideVan(false); } catch(e1:Error) { }
         try { if(this.HoldBreathButton_mc != null) { this.HoldBreathButton_mc.visible = true; } } catch(e2:Error) { }
         try { if(this.ButtonBackground_mc != null) { this.ButtonBackground_mc.visible = true; } } catch(e3:Error) { }
         try { if(this.hzpChip != null) { this.hzpChip.visible = false; } } catch(e4:Error) { }
      }
      private function hzpOnMap(e:FromClientDataEvent) : void
      {
         try
         {
            var d:Object = e.data;
            if(d == null) { return; }
            if(d.vMappedEvents != null) { this.hzpMap = d.vMappedEvents as Array; if(this.hzpMap == null) { this.hzpMap = []; for each(var m0:* in d.vMappedEvents) { this.hzpMap.push(m0); } } }
            this.hzpPad = uint(d.uiController) > 0;
         }
         catch(err:Error) { }
      }
      private function hzpKeyOk(s:*) : Boolean
      {
         if(s == null) { return false; }
         var t:String = String(s).replace(/^\s+|\s+$/g,"");
         return t.length > 0 && t != "?" && t != "null" && t != "undefined" && t.indexOf("$") != 0;
      }
      private function hzpKeyClip(s:String) : String
      {
         var t:String = s.replace(/^\s+|\s+$/g,"").replace(/\s+/g," ");
         return t.length > 12 ? t.substr(0,12) : t;
      }
      private function hzpTfTx(t:*) : String
      {
         try { if(t != null && t.visible != false && this.hzpKeyOk(t.text)) { return String(t.text); } } catch(e:Error) { }
         return null;
      }
      private function hzpTfFace(t:*) : String
      {
         try { var f:* = t.getTextFormat().font; if(f) { return String(f); } } catch(e:Error) { }
         return null;
      }
      // r3: [key text, glyph face or null]
      private function hzpKey() : Array
      {
         var b:* = this.HoldBreathButton_mc;
         var tx:String = null;
         var t:* = null;
         try
         {
            if(!this.hzpPad)
            {
               try { t = b.PCButton_mc.ButtonInstance_mc.PCButton_tf; } catch(e1:Error) { t = null; }
               tx = this.hzpTfTx(t);
               if(tx == null) { try { t = b.PCButton_mc.PCButton_tf; } catch(e2:Error) { t = null; } tx = this.hzpTfTx(t); }
               if(tx != null) { return [this.hzpKeyClip(tx).toUpperCase(),null]; }
            }
            else
            {
               try { t = b.ConsoleButton_mc.ButtonInstance_mc.ConsoleButton_tf; } catch(e3:Error) { t = null; }
               tx = this.hzpTfTx(t);
               if(tx == null) { try { t = b.ConsoleButton_mc.ConsoleButton_tf; } catch(e4:Error) { t = null; } tx = this.hzpTfTx(t); }
               if(tx != null) { return [this.hzpKeyClip(tx),this.hzpTfFace(t)]; }
            }
         }
         catch(e5:Error) { }
         var mk:String = this.hzpMapKey();
         if(mk != null) { return [mk,null]; }
         return [this.hzpPad ? "L3" : "SHIFT",null];
      }
      // the "Steady" entry of ControlMapData: the raw button name(s), upper case ("LShift" -> "L-SHIFT")
      private function hzpMapKey() : String
      {
         if(this.hzpMap == null) { return null; }
         try
         {
            for each(var m:* in this.hzpMap)
            {
               if(m == null || String(m.strUserEventName) != "Steady") { continue; }
               var parts:Array = [];
               try { for each(var a:* in m.aButtonName) { if(this.hzpKeyOk(a)) { parts.push(this.hzpPretty(String(a))); } } } catch(e1:Error) { }
               if(parts.length == 0 && this.hzpKeyOk(m.strButtonName)) { parts.push(this.hzpPretty(String(m.strButtonName))); }
               if(parts.length > 0) { return this.hzpKeyClip(parts.join("+")); }
            }
         }
         catch(e2:Error) { }
         return null;
      }
      private function hzpPretty(s:String) : String
      {
         var u:String = s.replace(/^\s+|\s+$/g,"");
         var m:Object = /^([LR])(Shift|Ctrl|Control|Alt)$/i.exec(u);
         if(m != null) { return String(m[1]).toUpperCase() + "-" + String(m[2]).toUpperCase().replace("CONTROL","CTRL"); }
         return u.toUpperCase();
      }
      private function hzpFrame() : void
      {
         var now:int = getTimer();
         if(!this.hzpSub && stage != null)
         {
            this.hzpSub = true;
            try { BSUIDataManager.Subscribe("PlayerFrequentData",this.hzpOnFreq); } catch(e1:Error) { }
            try { BSUIDataManager.Subscribe("ControlMapData",this.hzpOnMap); } catch(e1b:Error) { }
         }
         if(this.hzpReady && now - this.hzpIniT > 5000) { this.hzpRead(); }
         var b:* = this.HoldBreathButton_mc;
         if(!this.hzpReady || !this.hzpOn || b == null)
         {
            this.hzpHideVan(false);
            if(this.hzpChip) { this.hzpChip.visible = false; }
            return;
         }
         var want:Boolean = true;
         try { want = b.Visible == true; } catch(e2:Error) { want = true; }
         this.hzpHideVan(true);
         if(!want || b.stage == null) { this.hzpChip.visible = false; return; }
         var o:Number = this.hzpO2;
         var st:int = this.hzpState(o,now);
         var band:int = this.hzpBand(o);
         var ka:Array = this.hzpKey();
         if(String(ka[0]) != this.hzpKeyTx || ka[1] != this.hzpKeyFace) { this.hzpKeyTx = String(ka[0]); this.hzpKeyFace = ka[1]; }
         var sig:String = this.hzpKeyTx + "|" + this.hzpKeyFace + "|" + this.hzpS.ChipS + "|" + st + "|" + band + "|" + this.hzpS.AccentColor + "|" + this.hzpS.AccentHex + "|" + this.hzpS.CardOpacity + "|" + this.hzpS.TextScale + "|" + this.hzpS.FontFace + "|" + this.hzpS.HeaderStyle;
         if(sig != this.hzpSig) { this.hzpSig = sig; this.hzpDraw(st,band); }
         this.hzpBarDraw(st,band,o);
         // where the hidden button sits, at its own (counter-scaled) size
         var r:Rectangle = b.getBounds(this);
         if(r != null && r.width > 1 && r.height > 1) { this.hzpLastX = r.x + r.width / 2; this.hzpLastY = r.y + r.height / 2; }
         if(isNaN(this.hzpLastX)) { this.hzpChip.visible = false; return; }
         // r2: [Scope] offset (1080p screen units -> this menu's units = x the button's counter-scale) and size
         var cs:Number = Number(this.hzpS.ChipS);
         if(isNaN(cs) || cs <= 0) { cs = 1; }
         var ox:Number = Number(this.hzpS.ChipX) * b.scaleX;
         var oy:Number = -Number(this.hzpS.ChipY) * b.scaleY;
         if(isNaN(ox)) { ox = 0; }
         if(isNaN(oy)) { oy = 0; }
         var sx:Number = b.scaleX * cs;
         var sy:Number = b.scaleY * cs;
         if(isNaN(sx) || sx == 0) { sx = 1; }
         if(isNaN(sy) || sy == 0) { sy = 1; }
         var sw:Number = Math.round(this.hzpW * sx);
         var sh:Number = Math.round(this.hzpH * sy);
         if(sw < 1) { sw = 1; }
         if(sh < 1) { sh = 1; }
         if(this.hzpW > 0) { this.hzpChip.scaleX = sw / this.hzpW; }
         if(this.hzpH > 0) { this.hzpChip.scaleY = sh / this.hzpH; }
         this.hzpChip.x = Math.round(this.hzpLastX + ox - sw / 2);
         this.hzpChip.y = Math.round(this.hzpLastY + oy - sh / 2);
         this.hzpUnclip();
         if(this.hzpChip.parent == this && getChildIndex(this.hzpChip) != numChildren - 1) { setChildIndex(this.hzpChip,numChildren - 1); }
         this.hzpChip.visible = true;
         if(st == 1 && this.hzpDiag.length == 0) { try { this.hzpSnap(); } catch(eSnap:Error) { this.hzpDiag = "chip bounds error"; } }
      }
      // O2 band, same thresholds as the HUD vitals card (hz26Band): 0 normal, 1 warning (< 35 %), 2 critical (< 15 %)
      private function hzpBand(o:Number) : int
      {
         if(o < 0) { return 0; }
         return o < HZP_O2_CRIT ? 2 : (o < HZP_O2_WARN ? 1 : 0);
      }
      // 0 ready, 1 holding (O2 fell on 2 readings in a row; held at least 900 ms), 3 out of breath (2 readings under 1 % in a row)
      private function hzpState(o:Number, now:int) : int
      {
         if(o >= 0 && o < 0.01 && this.hzpZeroN >= 2) { return 3; }
         if(now - this.hzpFallT < 900) { return 1; }
         return 0;
      }
      // original target icon (ring, 4 ticks, center dot), drawn in code; 17 px across at 1080p
      private function hzpCross(g:*, cx:Number, cy:Number, col:uint, a:Number) : void
      {
         g.lineStyle(2,col,a,true,"none");
         g.drawCircle(cx,cy,6);
         g.moveTo(cx,cy - 8.5); g.lineTo(cx,cy - 3.5);
         g.moveTo(cx,cy + 3.5); g.lineTo(cx,cy + 8.5);
         g.moveTo(cx - 8.5,cy); g.lineTo(cx - 3.5,cy);
         g.moveTo(cx + 3.5,cy); g.lineTo(cx + 8.5,cy);
         g.lineStyle();
         g.beginFill(col,a); g.drawCircle(cx,cy,1.8); g.endFill();
      }
      private function hzpProbe(n:String) : Boolean
      {
         if(this.hzpFontOk[n] != undefined) { return this.hzpFontOk[n] == 1; }
         var ok:Boolean = false;
         try
         {
            var t:TextField = new TextField();
            t.embedFonts = true;
            var tf:TextFormat = new TextFormat(n,20,0xFFFFFF);
            t.defaultTextFormat = tf; t.text = "WMW"; t.setTextFormat(tf);
            ok = t.textWidth > 8;
            if(ok)
            {
               var x:TextField = new TextField();
               x.embedFonts = true;
               var xf:TextFormat = new TextFormat("$Horizon_NoSuchFace_x",20,0xFFFFFF);
               x.defaultTextFormat = xf; x.text = "WMW"; x.setTextFormat(xf);
               if(x.textWidth > 0 && Math.abs(x.textWidth - t.textWidth) < 0.01) { ok = false; }
            }
         }
         catch(err:Error) { ok = false; }
         this.hzpFontOk[n] = ok ? 1 : 0;
         return ok;
      }
      // FontFace: 1 Exo 2, 2 Roboto (both from the Horizon font package), 0 game font, 3 the game face of the prompt label
      private function hzpFace(w:String) : String
      {
         var f:int = int(this.hzpS.FontFace);
         if(f == 2)
         {
            var r:String = w == "bd" ? "$Horizon_Font_Alt_Bold" : "$Horizon_Font_Alt";
            if(this.hzpProbe(r)) { return r; }
            if(this.hzpProbe("$Horizon_Font_Alt")) { return "$Horizon_Font_Alt"; }
         }
         if(f == 1 || f == 2)
         {
            var x:String = w == "bd" ? "$Horizon_Font_Bold" : "$Horizon_Font";
            if(this.hzpProbe(x)) { return x; }
            if(this.hzpProbe("$Horizon_Font")) { return "$Horizon_Font"; }
         }
         if(f == 3)
         {
            try
            {
               var lt:TextField = this.HoldBreathButton_mc.Label_mc.Label_tf as TextField;
               if(lt != null && lt.getTextFormat().font) { return String(lt.getTextFormat().font); }
            }
            catch(e3:Error) { }
         }
         return "$MAIN_Font";
      }
      private function hzpFs(size:Number) : Number
      {
         var ts:Number = Number(this.hzpS.TextScale);
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         if(HZP_LRG) { ts *= 1.1; }
         var cs:Number = Number(this.hzpS.ChipS);
         if(isNaN(cs) || cs <= 0) { cs = 1; }
         // r3: the chip is scaled by ScopeChipScale after drawing: keep 13 px on screen at every size (floor after scaling)
         return Math.max(HZP_MINPX,Math.round(size * ts * 10) / 10,Math.ceil(HZP_MINPX / cs * 10) / 10);
      }
      private function hzpT(p:Sprite, s:String, size:Number, col:uint, w:String, tr:Number, face:String = null) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = TextFieldAutoSize.LEFT;
         var fs:Number = this.hzpFs(size);
         var f:TextFormat = new TextFormat(face != null ? face : this.hzpFace(w),fs,col);
         f.letterSpacing = Math.round(fs * tr * 10) / 10;
         t.defaultTextFormat = f;
         t.text = s;
         t.setTextFormat(f);
         p.addChild(t);
         return t;
      }
      private function hzpCase(s:String) : String
      {
         if(int(this.hzpS.HeaderStyle) != 1) { return s; }
         var w:Array = s.toLowerCase().split(" ");
         var i:int = 0;
         while(i < w.length) { if(String(w[i]).length > 0 && w[i] != "o2") { w[i] = String(w[i]).charAt(0).toUpperCase() + String(w[i]).substr(1); } i++; }
         return w.join(" ").replace("o2","O2");
      }
      // 0.42.0.6: an autosized key field clips its last glyph, so the keycap's right border looks cut off
      // (L-SHIFT on the hold-breath chip). Measure textWidth first, then lock autoSize to NONE and set the
      // field width to ceil(textWidth * 1.08 + letterSpacing * length) + 8. The keycap and the chip use that width.
      // extra is 0 for the label slot. The key cap passes HZP_KEX so L-SHIFT fits. The card grows only by that extra.
      private function hzpKeyW(t:TextField, extra:Number = 0) : Number
      {
         if(t == null) { return 0; }
         if(isNaN(extra) || extra < 0) { extra = 0; }
         var ls:Number = 0;
         try { ls = Number(t.getTextFormat().letterSpacing); } catch(e:Error) { ls = 0; }
         if(isNaN(ls) || ls < 0) { ls = 0; }
         var tw:Number = Number(t.textWidth);
         if(isNaN(tw) || tw < 0) { tw = 0; }
         var len:Number = t.text != null ? Number(t.text.length) : 0;
         var w:Number = Math.ceil(tw * HZP_KHEAD + ls * len) + 8 + extra;
         if(w < HZP_KMINW) { w = HZP_KMINW; }
         return w;
      }
      // Widest label (HOLDING BREATH). The chip keeps that width in every state, so it does not resize or re-center.
      private function hzpLblSlot(p:Sprite) : Array
      {
         var bestW:Number = 0;
         var bestH:Number = 0;
         var seen:Object = {};
         var i:int = 0;
         while(i < HZP_LBL.length)
         {
            var s:String = this.hzpCase(String(HZP_LBL[i]));
            if(seen[s] != 1)
            {
               seen[s] = 1;
               var t:TextField = this.hzpT(p,s,14,HZP_TXT,"sb",0.1);
               var w:Number = this.hzpKeyW(t);
               var th:Number = t.height;
               if(t.parent == p) { p.removeChild(t); }
               if(w > bestW) { bestW = w; }
               if(th > bestH) { bestH = th; }
            }
            i++;
         }
         return [bestW,bestH];
      }
      // st: 0 ready, 1 holding, 3 out of breath; band: 0 normal, 1 warning (amber), 2 critical (red).
      // Every stroke stays inside [0,w] x [0,h]. Strokes are 1 or 2 px, inset by half their width. The O2 bar is hzpBar.
      private function hzpDraw(st:int, band:int) : void
      {
         var p:Sprite = this.hzpChip;
         if(p == null) { return; }
         if(this.hzpBar != null && this.hzpBar.parent == p) { p.removeChild(this.hzpBar); }
         while(p.numChildren > 0) { p.removeChildAt(0); }
         var g:* = p.graphics;
         g.clear();
         var acc:uint = this.hzpAccent();
         var stc:uint = (st == 3 || band == 2) ? HZP_RED : (band == 1 ? HZP_AMB : acc);
         var keyCol:uint = st == 3 ? HZP_DIM : stc;
         var ts:Number = Math.max(1,Math.min(1.3,Number(this.hzpS.TextScale)));
         if(isNaN(ts)) { ts = 1; }
         var slot:Array = this.hzpLblSlot(p);
         var ltw:Number = Number(slot[0]);
         var lth0:Number = Number(slot[1]);
         if(isNaN(ltw) || ltw < 1) { ltw = 80; }
         if(isNaN(lth0) || lth0 < 1) { lth0 = 16; }
         var ch:Number = Math.round(32 + (ts - 1) * 20);
         var lt:TextField = this.hzpT(p,this.hzpCase(String(HZP_LBL[st])),14,st == 3 ? HZP_DIM : HZP_TXT,"sb",0.1);
         this.hzpLbl = lt;
         var ownW:Number = this.hzpKeyW(lt);
         if(ownW > ltw) { ltw = ownW; }
         ltw += HZP_LABEX;
         var lth:Number = lt.height;
         if(lth0 > lth) { lth = lth0; }
         lt.autoSize = TextFieldAutoSize.NONE;
         lt.width = ltw;
         if(lt.height < lth) { lt.height = lth; }
         var kt:TextField = null;
         var ktw:Number = 0;
         if(this.hzpKeyTx.length > 0) { kt = this.hzpT(p,this.hzpKeyTx,13,keyCol,"bd",0.04,this.hzpKeyFace); }
         if(kt != null)
         {
            ktw = this.hzpKeyW(kt,HZP_KEX);
            var kth:Number = kt.height;
            kt.autoSize = TextFieldAutoSize.NONE;
            kt.width = ktw;
            if(kt.height < kth) { kt.height = kth; }
         }
         ch = Math.max(ch,Math.round(lth + 6),kt != null ? Math.round(kt.height + 6) : 0);
         ch = Math.round(ch);
         var kw:Number = 30 + (kt != null ? ktw + HZP_KPAD : 0);   // 0.42.0.6: keycap from the locked key-field width
         var kh:Number = Math.round(ch - 12);
         var mw:Number = 120;
         var x0:Number = 7;
         var lx:Number = x0 + kw + 10;
         var mx:Number = Math.round(lx + ltw + 16);
         var cw:Number = Math.round(mx + mw + HZP_RPAD);   // 0.42.0.5: + 4
         var pad:Number = HZP_GLOW;
         // A 1% fill makes getBounds include the pad. Filters and strokes are cropped by an ancestor scrollRect.
         g.beginFill(0x000000,0.01);
         g.drawRect(0,0,cw + pad * 2,ch + pad * 2);
         g.endFill();
         // panel: shadow and strokes stay inside the chip. Strokes are 1 or 2 px and inset by half that width.
         var opa:Number = Number(this.hzpS.CardOpacity);
         if(isNaN(opa)) { opa = 1; }
         var i:int = 0;
         while(i < 3)
         {
            var sx:Number = pad + 1 + i;
            var sy:Number = pad + 2;
            var sw:Number = cw - (1 + i) * 2;
            var shd:Number = ch - 4 - i;
            if(sw > 4 && shd > 4) { g.beginFill(0x000000,0.07); g.drawRoundRect(sx,sy,sw,shd,ch,ch); g.endFill(); }
            i++;
         }
         var bw:Number = 1;
         var bcol:uint = 0xFFFFFF;
         var ba:Number = 0.18;
         if(st == 3) { bw = 1; bcol = HZP_RED; ba = 0.7; }
         else if(band == 2) { bw = 2; bcol = HZP_RED; ba = 1; }
         else if(band == 1) { bw = 2; bcol = HZP_AMB; ba = 1; }
         else if(st == 1) { bw = 2; bcol = acc; ba = 1; }
         var inset:Number = bw * 0.5;
         g.lineStyle(bw,bcol,ba,true,"none");
         g.beginFill(HZP_BG,Math.min(1,0.84 * opa));
         g.drawRoundRect(pad + inset,pad + inset,cw - bw,ch - bw,Math.max(0,ch - bw),Math.max(0,ch - bw));
         g.endFill();
         g.lineStyle();
         if(st == 1 || (band > 0 && st != 3)) { g.lineStyle(2,stc,0.18,true,"none"); g.drawRoundRect(pad + 1,pad + 1,cw - 2,ch - 2,Math.max(0,ch - 2),Math.max(0,ch - 2)); g.lineStyle(); }
         // keycap. A 1 px stroke is inset by half a pixel so it stays on whole pixels and inside the cap.
         var ky:Number = Math.round((ch - kh) / 2);
         g.lineStyle(1,keyCol,st == 3 ? 0.5 : 0.95,true,"none");
         g.beginFill(keyCol,st == 1 ? 0.22 : 0.1);
         g.drawRoundRect(pad + x0 + 0.5,pad + ky + 0.5,kw - 1,kh - 1,8,8);
         g.endFill();
         g.lineStyle();
         this.hzpCross(g,pad + x0 + 15,pad + ky + kh / 2,keyCol,st == 3 ? 0.6 : 1);
         if(kt != null) { kt.x = Math.round(pad + x0 + 28); kt.y = Math.round(pad + ch / 2 - kt.height / 2); }
         lt.x = pad + lx - 2;
         lt.y = Math.round(pad + ch / 2 - lt.height / 2);
         this.hzpMx = pad + mx;
         this.hzpMy = Math.round(pad + ch / 2 - 3);
         this.hzpMw = mw;
         if(this.hzpBar == null) { this.hzpBar = new flash.display.Shape(); }
         p.addChild(this.hzpBar);
         this.hzpW = cw + pad * 2;
         this.hzpH = ch + pad * 2;
      }
      // Clear a clip on the chip itself. Grow an ancestor scrollRect on the right and bottom only; x and y stay.
      // A round mask (width about equal to height) is left alone: that is the scope reticle, not the chip's box.
      private function hzpUnclip() : void
      {
         var chip:Sprite = this.hzpChip;
         if(chip == null) { return; }
         chip.scrollRect = null;
         chip.mask = null;
         chip.cacheAsBitmap = false;
         var d:* = chip.parent;
         var n:int = 0;
         while(d != null && n < 6)
         {
            var sr:Rectangle = null;
            var mb:Rectangle = null;
            var cb:Rectangle = null;
            try { sr = d.scrollRect; } catch(eS:Error) { sr = null; }
            try { cb = chip.getBounds(d); } catch(eB:Error) { cb = null; }
            if(sr != null && cb != null && cb.width > 0 && cb.height > 0)
            {
               var nr:Number = sr.x + sr.width;
               var nb:Number = sr.y + sr.height;
               var r:Number = cb.x + cb.width + HZP_GLOW;
               var btm:Number = cb.y + cb.height + HZP_GLOW;
               if(r > nr) { nr = r; }
               if(btm > nb) { nb = btm; }
               if(nr > sr.x + sr.width + 0.5 || nb > sr.y + sr.height + 0.5)
               {
                  try { d.scrollRect = new Rectangle(sr.x,sr.y,nr - sr.x,nb - sr.y); } catch(eSet:Error) { }
               }
            }
            try
            {
               if(d.mask != null) { mb = d.mask.getBounds(d); }
            }
            catch(eM:Error) { mb = null; }
            if(!this.hzpMaskOnce && mb != null && cb != null && mb.width > 20 && Math.abs(mb.width - mb.height) >= 4)
            {
               this.hzpMaskOnce = true;
               var overR:Number = (cb.x + cb.width + HZP_GLOW) - (mb.x + mb.width);
               var overB:Number = (cb.y + cb.height + HZP_GLOW) - (mb.y + mb.height);
               if(overR > 0 && overR <= HZP_GLOW + 1) { try { d.mask.width = d.mask.width + overR; } catch(eW:Error) { } }
               if(overB > 0 && overB <= HZP_GLOW + 1) { try { d.mask.height = d.mask.height + overB; } catch(eH:Error) { } }
            }
            d = d.parent;
            n++;
         }
      }
      // First HOLDING BREATH this movie. trace() does not reach HorizonUI.log, and Debug=0 leaves the movie
      // queue off, so the DLL reads hzpClipDiag and logs it once per session.
      public function hzpClipDiag() : String
      {
         try { return this.hzpDiag != null ? this.hzpDiag : ""; } catch(e:Error) { return ""; }
      }
      private function hzpNum(n:Number) : String
      {
         if(isNaN(n) || n > 1000000000 || n < -1000000000) { return "nan"; }
         return String(Math.round(n * 100) / 100);
      }
      private function hzpFlat(s:String) : String
      {
         if(s == null) { return ""; }
         var o:String = "";
         var i:int = 0;
         while(i < s.length && i < 80)
         {
            var c:int = s.charCodeAt(i);
            o += (c < 32 ? " " : s.charAt(i));
            i++;
         }
         return o;
      }
      private function hzpSnap() : void
      {
         var chip:Sprite = this.hzpChip;
         if(chip == null) { return; }
         var o:String = "";
         try
         {
            var br:Rectangle = chip.getBounds(stage);
            if(br == null) { o = "chip bounds none"; }
            else { o = "chip bounds x=" + this.hzpNum(br.x) + " y=" + this.hzpNum(br.y) + " w=" + this.hzpNum(br.width) + " h=" + this.hzpNum(br.height); }
         }
         catch(eB:Error) { o = "chip bounds error"; }
         var tw:String = "none";
         var fw:String = "none";
         try
         {
            if(this.hzpLbl != null)
            {
               tw = this.hzpNum(Number(this.hzpLbl.textWidth));
               fw = this.hzpNum(Number(this.hzpLbl.width));
            }
         }
         catch(eL:Error) { tw = "error"; fw = "error"; }
         o += "\nlabel textWidth=" + tw + " width=" + fw;
         var ssx:String = "none";
         var ssy:String = "none";
         try
         {
            if(stage != null) { ssx = this.hzpNum(stage.scaleX); ssy = this.hzpNum(stage.scaleY); }
         }
         catch(eS:Error) { ssx = "error"; ssy = "error"; }
         var hs:Number = Number(this.hzpS.HudScale);
         if(isNaN(hs)) { hs = 1; }
         o += "\nstage scaleX=" + ssx + " scaleY=" + ssy + " hudScale=" + this.hzpNum(hs);
         var d:* = chip.parent;
         var n:int = 0;
         while(d != null && n < 16)
         {
            var nm:String = "";
            var scr:String = "none";
            var mk:String = "no";
            var sx:String = "none";
            var sy:String = "none";
            var bit:String = "none";
            try { nm = this.hzpFlat(d.name == null ? "" : String(d.name)); } catch(eN:Error) { nm = ""; }
            try
            {
               var asr:Rectangle = d.scrollRect;
               if(asr != null) { scr = this.hzpNum(asr.x) + "," + this.hzpNum(asr.y) + "," + this.hzpNum(asr.width) + "," + this.hzpNum(asr.height); }
            }
            catch(eR:Error) { scr = "error"; }
            try { mk = d.mask != null ? "yes" : "no"; } catch(eM:Error) { mk = "error"; }
            try { sx = this.hzpNum(Number(d.scaleX)); sy = this.hzpNum(Number(d.scaleY)); } catch(eSc:Error) { sx = "error"; sy = "error"; }
            try { bit = d.cacheAsBitmap ? "true" : "false"; } catch(eC:Error) { bit = "error"; }
            o += "\nancestor name=" + nm + " scroll=" + scr + " mask=" + mk + " scaleX=" + sx + " scaleY=" + sy + " cache=" + bit;
            if(d == stage) { break; }
            try { d = d.parent; } catch(eP:Error) { break; }
            n++;
         }
         this.hzpDiag = o;
      }
      private function hzpBarDraw(st:int, band:int, o:Number) : void
      {
         if(this.hzpBar == null) { return; }
         var g:* = this.hzpBar.graphics;
         if(g == null) { return; }
         g.clear();
         var bc:uint = (st == 3 || band == 2) ? HZP_RED : (band == 1 ? HZP_AMB : HZP_O2);
         var mw:Number = this.hzpMw;
         var mx:Number = this.hzpMx;
         var my:Number = this.hzpMy;
         if(mw < 4 || mx < 0 || my < 0) { return; }
         g.beginFill(0xFFFFFF,0.14); g.drawRoundRect(mx,my,mw,6,6,6); g.endFill();
         if(o > 0 && st != 3)
         {
            var fw:Number = Math.max(3,Math.round(mw * o));
            if(fw > mw) { fw = mw; }
            g.beginFill(bc,1); g.drawRoundRect(mx,my,fw,6,6,6); g.endFill();
         }
      }
      // =================== end Horizon UI Scope module ===================
      // =================== v0.37 shared settings reader (hzp37) ===================
      // ONE helper, spliced into every movie that reads the settings (hudmenu + hudmenu_lrg as hz37, hudmessagesmenu
      // x2 as hzc37, dialoguemenu x2 as hzd37; generated from /workspace/v037/work/hzini_shared.as, so the copies are
      // identical apart from the prefix). It reads HorizonUI.default.ini, HorizonUI.user.ini, HorizonUI.state.ini and the
      // legacy HorizonUI.ini (paths relative to Data/Interface) one after the other and hands every waiting callback the
      // merged text: the defaults with user.ini laid over (hzp37Compose; mirrors HZF::Compose in HorizonUI.dll). A missing
      // file is normal: its IOErrorEvent is caught and simply counts as "no file" (nothing is thrown or logged).
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hzp37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hzp37_BOM:String = String.fromCharCode(0xFEFF);
      private var hzp37Ldr:URLLoader = null;
      private var hzp37Step:int = 0;          // 0 idle, n = reading hzp37_FILES[n - 1]
      private var hzp37T0:Number = 0;
      private var hzp37Got:Array = null;
      private var hzp37Q:Array = [];          // callbacks of the running read
      private var hzp37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private function hzp37Ws(c:String) : Boolean { return c == " " || c == "\t" || c == "\r" || c == "\n"; }
      private function hzp37Trim(s:String) : String
      {
         var b:int = 0;
         var e:int = s.length;
         while(b < e && (this.hzp37Ws(s.charAt(b)) || s.charAt(b) == hzp37_BOM)) { b++; }
         while(e > b && this.hzp37Ws(s.charAt(e - 1))) { e--; }
         return s.substring(b,e);
      }
      private function hzp37Blank(s:String) : Boolean { return this.hzp37Trim(s).length == 0; }
      private function hzp37Lines(t:String) : Array
      {
         var out:Array = [];
         if(t == null || t.length == 0) { return out; }
         if(t.charAt(0) == hzp37_BOM) { t = t.substr(1); }
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
      private function hzp37Hdr(ln:String) : String
      {
         var t:String = this.hzp37Trim(ln);
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return this.hzp37Trim(t.substring(1,e)).toLowerCase();
      }
      private function hzp37Alias(n:String) : String
      {
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // key=value line -> {k: key lower case without blanks, o: key as written, v: value up to ';'}; null otherwise
      private function hzp37KV(ln:String) : Object
      {
         var t:String = this.hzp37Trim(ln);
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         var o:String = this.hzp37Trim(t.substr(0,eq));
         var k:String = o.split(" ").join("").split("\t").join("").toLowerCase();
         if(k.length == 0) { return null; }
         var v:String = t.substr(eq + 1);
         var sc:int = v.indexOf(";");
         if(sc >= 0) { v = v.substr(0,sc); }
         return {"k":k,"o":o,"v":this.hzp37Trim(v)};
      }
      // sections; a second copy / the pre-v0.31 name merges into the first, old names first so the new name wins
      private function hzp37Parse(t:String) : Object
      {
         var d:Object = {"secs":[{"n":"","raw":[],"order":[],"kv":{}}],"idx":{"s_":0}};
         var lines:Array = this.hzp37Lines(t);
         var pass:int = 0;
         while(pass < 2)
         {
            var cur:Object = d.secs[0];
            var old:Boolean = false;
            for each(var ln:String in lines)
            {
               var h:String = this.hzp37Hdr(ln);
               if(h != null)
               {
                  old = h == "cards v0.26" || h == "effects v0.26";
                  var n:String = this.hzp37Alias(h);
                  if((pass == 0) != old) { cur = null; continue; }
                  if(d.idx["s_" + n] == undefined) { d.idx["s_" + n] = d.secs.length; d.secs.push({"n":n,"raw":[],"order":[],"kv":{}}); }
                  cur = d.secs[int(d.idx["s_" + n])];
                  cur.raw.push(ln);
                  continue;
               }
               if(cur == null) { continue; }
               if(pass == 0 && cur.n == "") { continue; }
               cur.raw.push(ln);
               var kv:Object = this.hzp37KV(ln);
               if(kv == null) { continue; }
               if(cur.kv["k_" + kv.k] == undefined) { cur.order.push(kv.k); }
               cur.kv["k_" + kv.k] = [kv.o,kv.v];
            }
            pass++;
         }
         return d;
      }
      private function hzp37SecOf(d:Object, kl:String) : String
      {
         for each(var s:Object in d.secs) { if(s.n != "" && s.kv["k_" + kl] != undefined) { return String(s.n); } }
         return "";
      }
      private function hzp37Flush(out:Array, sec:String, U:Object, ext:Object, flushed:Object) : void
      {
         if(sec == "" || flushed["s_" + sec] == true) { return; }
         flushed["s_" + sec] = true;
         var e:Array = ext["s_" + sec];
         if(e == null || e.length == 0) { return; }
         var blanks:int = 0;
         while(out.length > 0 && this.hzp37Blank(String(out[out.length - 1]))) { out.pop(); blanks++; }
         for each(var k:String in e)
         {
            var p:Array = U["s_" + sec]["k_" + k];
            out.push(String(p[0]) + "=" + String(p[1]));
         }
         while(blanks > 0) { out.push(""); blanks--; }
      }
      // base with the player's values laid over it: known keys replace the base value in place, unknown keys of a known
      // section are appended to it, sections the base lacks are appended verbatim. CRLF out.
      private function hzp37Overlay(base:String, over:String) : String
      {
         var B:Object = this.hzp37Parse(base);
         var O:Object = this.hzp37Parse(over);
         var U:Object = {};
         var ext:Object = {};
         var unk:Array = [];
         for each(var s:Object in O.secs)
         {
            if(s.n != "" && B.idx["s_" + s.n] == undefined) { unk.push(s); continue; }
            for each(var kl:String in s.order)
            {
               var sec:String = s.n == "" ? this.hzp37SecOf(B,kl) : String(s.n);
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
         for each(var ln:String in this.hzp37Lines(base))
         {
            var h:String = this.hzp37Hdr(ln);
            if(h != null) { this.hzp37Flush(out,cur,U,ext,flushed); cur = this.hzp37Alias(h); out.push(ln); continue; }
            if(cur != "")
            {
               var kv:Object = this.hzp37KV(ln);
               if(kv != null && U["s_" + cur] != undefined && U["s_" + cur]["k_" + kv.k] != undefined)
               {
                  out.push(kv.o + "=" + String(U["s_" + cur]["k_" + kv.k][1]));
                  continue;
               }
            }
            out.push(ln);
         }
         this.hzp37Flush(out,cur,U,ext,flushed);
         for each(var us:Object in unk)
         {
            if(out.length > 0 && !this.hzp37Blank(String(out[out.length - 1]))) { out.push(""); }
            var r:Array = (us.raw as Array).concat();
            while(r.length > 0 && this.hzp37Blank(String(r[r.length - 1]))) { r.pop(); }
            for each(var rl:String in r) { out.push(rl); }
         }
         return out.length == 0 ? "" : out.join("\r\n") + "\r\n";
      }
      // def / user / state / legacy texts (null = file missing) -> the effective settings text, or null
      private function hzp37Compose(def:String, user:String, state:String, leg:String) : String
      {
         var hd:Boolean = def != null && def.length > 0;
         var hl:Boolean = leg != null && leg.length > 0;
         var base:String = hd ? def : (hl ? leg : null);
         var over:String = user != null ? user : (state == null && hd && hl ? leg : null);   // an old DLL still saves HorizonUI.ini
         if(base == null) { return over == null ? null : this.hzp37Overlay(over,""); }
         return this.hzp37Overlay(base,over != null ? over : "");
      }
      // read all four files, then cb(mergedText or null). Requests during a read get one fresh read afterwards.
      private function hzp37IniRead(cb:Function) : void
      {
         var now:Number = new Date().getTime();
         if(this.hzp37Step != 0 && now - this.hzp37T0 < 3000)
         {
            if(this.hzp37N.indexOf(cb) < 0) { this.hzp37N.push(cb); }
            return;
         }
         if(this.hzp37Step != 0 && this.hzp37Ldr != null) { try { this.hzp37Ldr.close(); } catch(e0:Error) { } }   // stuck: start over
         var q:Array = this.hzp37Step != 0 ? this.hzp37Q.concat(this.hzp37N) : [];
         this.hzp37N = [];
         if(q.indexOf(cb) < 0) { q.push(cb); }
         this.hzp37Q = q;
         this.hzp37Begin();
      }
      private function hzp37Begin() : void
      {
         this.hzp37Got = [null,null,null,null];
         this.hzp37T0 = new Date().getTime();
         this.hzp37Next(0);
      }
      private function hzp37Next(i:int) : void
      {
         this.hzp37Step = i + 1;
         if(i >= hzp37_FILES.length) { this.hzp37Ldr = null; this.hzp37Done(); return; }
         try
         {
            this.hzp37Ldr = new URLLoader();
            this.hzp37Ldr.addEventListener(Event.COMPLETE,this.hzp37OnOk);
            this.hzp37Ldr.addEventListener(IOErrorEvent.IO_ERROR,this.hzp37OnErr);
            this.hzp37Ldr.addEventListener("securityError",this.hzp37OnErr);
            this.hzp37Ldr.load(new URLRequest(String(hzp37_FILES[i])));
         }
         catch(err:Error) { this.hzp37Next(i + 1); }
      }
      private function hzp37OnOk(e:Event) : void
      {
         if(e == null || e.target != this.hzp37Ldr) { return; }
         var i:int = this.hzp37Step - 1;
         try { this.hzp37Got[i] = String(this.hzp37Ldr.data); } catch(err:Error) { }
         this.hzp37Next(i + 1);
      }
      private function hzp37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hzp37Ldr) { return; }
         this.hzp37Next(this.hzp37Step);   // missing file: normal, no error
      }
      private function hzp37Done() : void
      {
         this.hzp37Step = 0;
         var g:Array = this.hzp37Got;
         var txt:String = null;
         try { txt = this.hzp37Compose(g[0],g[1],g[2],g[3]); } catch(errC:Error) { txt = null; }
         var cbs:Array = this.hzp37Q;
         this.hzp37Q = [];
         for each(var cb:Function in cbs) { try { cb(txt); } catch(errCb:Error) { } }
         if(this.hzp37N.length > 0 && this.hzp37Step == 0) { this.hzp37Q = this.hzp37N; this.hzp37N = []; this.hzp37Begin(); }
      }
      // =================== end shared settings reader ===================

      internal function frame1() : *
      {
         stop();
      }
   }
}

