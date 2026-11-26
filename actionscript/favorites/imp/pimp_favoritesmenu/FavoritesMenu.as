package
{
   import Components.ImageFixture;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.Events.CustomEvent;
   import Shared.AS3.IMenu;
   import Shared.GlobalFunc;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.KeyboardEvent;
   import flash.ui.Keyboard;
   import Shared.InventoryItemUtils;
   import Shared.PlatformUtils;
   import flash.display.DisplayObject;
   import flash.display.Sprite;
   import flash.events.IOErrorEvent;
   import flash.filters.DropShadowFilter;
   import flash.geom.ColorTransform;
   import flash.geom.Rectangle;
   import flash.geom.Point;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.display.Graphics;
   import flash.events.MouseEvent;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol117")]
   public class FavoritesMenu extends IMenu
   {
      
      public static const FS_LEFT_3:uint = 0;
      
      public static const FS_LEFT_2:uint = 1;
      
      public static const FS_LEFT_1:uint = 2;
      
      public static const FS_RIGHT_1:uint = 3;
      
      public static const FS_RIGHT_2:uint = 4;
      
      public static const FS_RIGHT_3:uint = 5;
      
      public static const FS_UP_3:uint = 6;
      
      public static const FS_UP_2:uint = 7;
      
      public static const FS_UP_1:uint = 8;
      
      public static const FS_DOWN_1:uint = 9;
      
      public static const FS_DOWN_2:uint = 10;
      
      public static const FS_DOWN_3:uint = 11;
      
      public static const FS_NONE:uint = 12;
      
      public var CenterClip_mc:MovieClip;
      
      public var ItemInfo_mc:FavoriteAssigningInfoDisplay;
      
      public var AssignedItemIcon_mc:ImageFixture;
      
      public var Vignette_mc:MovieClip;
      
      public var SelectQuickslot_mc:MovieClip;
      
      public var Entry_0:FavoritesEntry;
      
      public var Entry_1:FavoritesEntry;
      
      public var Entry_2:FavoritesEntry;
      
      public var Entry_3:FavoritesEntry;
      
      public var Entry_4:FavoritesEntry;
      
      public var Entry_5:FavoritesEntry;
      
      public var Entry_6:FavoritesEntry;
      
      public var Entry_7:FavoritesEntry;
      
      public var Entry_8:FavoritesEntry;
      
      public var Entry_9:FavoritesEntry;
      
      public var Entry_10:FavoritesEntry;
      
      public var Entry_11:FavoritesEntry;
      
      private var FavoritesInfoA:Array;
      
      private var AssignedItem:Object = null;
      
      private var HasAssignedSlotOnce:Boolean = false;
      
      private var IsDataInitialized:Boolean = false;
      
      private var _SelectedIndex:uint = 12;
      
      public const TIMELINE_EVENT_CLOSE_ANIM_DONE:String = "onFinishedClosingAnim";
      
      private var OverEntry:Boolean = false;
      
      private const _UpDirectory:Array = [FS_UP_1,FS_UP_1,FS_UP_1,FS_UP_1,FS_UP_1,FS_UP_1,FS_UP_3,FS_UP_3,FS_UP_2,FS_UP_1,FS_DOWN_1,FS_DOWN_2,FS_UP_1];
      
      private const _DownDirectory:Array = [FS_DOWN_1,FS_DOWN_1,FS_DOWN_1,FS_DOWN_1,FS_DOWN_1,FS_DOWN_1,FS_UP_2,FS_UP_1,FS_DOWN_1,FS_DOWN_2,FS_DOWN_3,FS_DOWN_3,FS_DOWN_1];
      
      private const _LeftDirectory:Array = [FS_LEFT_3,FS_LEFT_3,FS_LEFT_2,FS_LEFT_1,FS_RIGHT_1,FS_RIGHT_2,FS_LEFT_1,FS_LEFT_1,FS_LEFT_1,FS_LEFT_1,FS_LEFT_1,FS_LEFT_1,FS_LEFT_1];
      
      private const _RightDirectory:Array = [FS_LEFT_2,FS_LEFT_1,FS_RIGHT_1,FS_RIGHT_2,FS_RIGHT_3,FS_RIGHT_3,FS_RIGHT_1,FS_RIGHT_1,FS_RIGHT_1,FS_RIGHT_1,FS_RIGHT_1,FS_RIGHT_1,FS_RIGHT_1];
      
      public function FavoritesMenu()
      {
         super();
         addFrameScript(12,this.frame13,17,this.frame18,20,this.frame21);
         addEventListener(KeyboardEvent.KEY_DOWN,this.onKeyDownHandler);
         addEventListener(KeyboardEvent.KEY_UP,this.onKeyUpHandler);
         addEventListener(FavoritesEntry.CLICK,this.SelectItem);
         addEventListener(FavoritesEntry.MOUSE_OVER,this.onFavEntryMouseover);
         addEventListener(FavoritesEntry.MOUSE_LEAVE,this.onFavEntryMouseleave);
         BSUIDataManager.Subscribe("FavoritesData",this.onDataUpdate);
         this.AssignedItemIcon_mc.mouseEnabled = false;
         this.AssignedItemIcon_mc.mouseChildren = false;
      }
      
      override public function onAddedToStage() : void
      {
         super.onAddedToStage();
         stage.focus = this;
         try { this.hzqOpen(); } catch(hzqE1:Error) { }   // Horizon: menu open -> read the settings
      }
      
      private function onDataUpdate(param1:FromClientDataEvent) : void
      {
         var _loc3_:Object = null;
         var _loc4_:FavoritesEntry = null;
         this.FavoritesInfoA = param1.data.aFavoriteItems;
         if(!this.IsDataInitialized)
         {
            this.assignedItem = param1.data.ItemToBeAssigned;
            this.selectedIndex = param1.data.uStartingSelection;
            this.CenterClip_mc.gotoAndStop(this.isAssigningItem() ? "Inventory" : "Quick");
         }
         this.SelectQuickslot_mc.visible = this.isAssigningItem() && !this.HasAssignedSlotOnce;
         this.SelectQuickslot_mc.gotoAndPlay(this.SelectQuickslot_mc.visible ? "Open" : "Close");
         this.AssignedItemIcon_mc.visible = this.isAssigningItem() && !this.HasAssignedSlotOnce;
         this.AssignedItemIcon_mc.gotoAndPlay(this.AssignedItemIcon_mc.visible ? "Open" : "Close");
         var _loc2_:uint = 0;
         while(this.FavoritesInfoA != null && _loc2_ < this.FavoritesInfoA.length)
         {
            _loc3_ = this.FavoritesInfoA[_loc2_];
            _loc4_ = this.GetEntryClip(_loc2_);
            if(_loc4_ != null)
            {
               _loc4_.LoadIcon(_loc3_);
            }
            _loc2_++;
         }
         this.IsDataInitialized = true;
         try { this.hzqData(); } catch(hzqE2:Error) { }   // Horizon: FavoritesData
      }
      
      public function isAssigningItem() : Boolean
      {
         return this.AssignedItem != null && this.AssignedItem.sName.length != 0;
      }
      
      public function get assignedItem() : Object
      {
         return this.AssignedItem;
      }
      
      public function set assignedItem(param1:Object) : void
      {
         this.AssignedItem = param1;
         if(this.isAssigningItem())
         {
            this.ItemInfo_mc.UpdateDisplay(this.AssignedItem);
            if(this.AssignedItem.iconImage.iFixtureType == ImageFixture.FT_SYMBOL)
            {
               if(this.AssignedItem.bIsPower)
               {
                  this.AssignedItemIcon_mc.clipSizer = "Sizer_mc";
               }
               this.AssignedItemIcon_mc.centerClip = true;
            }
            else
            {
               this.AssignedItemIcon_mc.clipSizer = "";
               this.AssignedItemIcon_mc.centerClip = false;
            }
            this.AssignedItemIcon_mc.LoadImageFixtureFromUIData(this.AssignedItem.iconImage,"FavoritesIconBuffer");
            this.ItemInfo_mc.visible = true;
            try { this.hzqAssign(); } catch(hzqE3:Error) { }   // Horizon: assign mode info card
         }
      }
      
      public function get selectedIndex() : uint
      {
         return this._SelectedIndex;
      }
      
      public function set selectedIndex(param1:uint) : void
      {
         if(param1 != this._SelectedIndex)
         {
            if(this._SelectedIndex != FS_NONE)
            {
               this.GetEntryClip(this._SelectedIndex).selected = false;
            }
            this._SelectedIndex = param1;
            if(this._SelectedIndex != FS_NONE)
            {
               this.GetEntryClip(this._SelectedIndex).selected = true;
            }
            this.onSelectionChange();
            GlobalFunc.PlayMenuSound(this.selectionSound);
         }
      }
      
      public function get selectedEntry() : Object
      {
         return this.FavoritesInfoA != null && this._SelectedIndex >= 0 && this._SelectedIndex < this.FavoritesInfoA.length ? this.FavoritesInfoA[this._SelectedIndex] : null;
      }
      
      public function get selectionSound() : String
      {
         var _loc1_:String = "";
         switch(this.selectedIndex)
         {
            case FS_UP_1:
            case FS_DOWN_1:
            case FS_LEFT_1:
            case FS_RIGHT_1:
               _loc1_ = "UIMenuQuickUseFocusDpadA";
               break;
            case FS_UP_2:
            case FS_DOWN_2:
            case FS_LEFT_2:
            case FS_RIGHT_2:
               _loc1_ = "UIMenuQuickUseFocusDpadB";
               break;
            case FS_UP_3:
            case FS_DOWN_3:
            case FS_LEFT_3:
            case FS_RIGHT_3:
               _loc1_ = "UIMenuQuickUseFocusDpadC";
         }
         return _loc1_;
      }
      
      public function GetEntryClip(param1:uint) : FavoritesEntry
      {
         var _loc2_:FavoritesEntry = getChildByName("Entry_" + param1) as FavoritesEntry;
         if(_loc2_ == null)
         {
            GlobalFunc.TraceWarning("Could not find the entry \'Entry_" + param1 + "\'!");
         }
         return _loc2_;
      }
      
      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      {
         var _loc4_:Number = NaN;
         var _loc3_:Boolean = false;
         try { if(this.hzqExtUser(param1,param2)) return true; } catch(hzqE5:Error) { }   // Horizon: extra slots 13-24
         if(!param2)
         {
            _loc3_ = true;
            switch(param1)
            {
               case "Cancel":
               case "Quickkeys":
               case "YButton":
                  this.StartClosingMenu();
                  _loc3_ = true;
                  break;
               default:
                  _loc4_ = Number(param1.substr(8));
                  if(_loc4_ >= 1 && _loc4_ <= FS_NONE)
                  {
                     this.selectedIndex = _loc4_ - 1;
                     this.SelectItem();
                  }
                  else
                  {
                     _loc3_ = false;
                  }
            }
         }
         return _loc3_;
      }
      
      private function StartClosingMenu() : void
      {
         gotoAndPlay("Close");
         addEventListener(this.TIMELINE_EVENT_CLOSE_ANIM_DONE,this.onCloseAnimFinished);
      }
      
      private function onCloseAnimFinished() : void
      {
         removeEventListener(this.TIMELINE_EVENT_CLOSE_ANIM_DONE,this.onCloseAnimFinished);
         GlobalFunc.CloseMenu("FavoritesMenu");
      }
      
      private function onSelectionChange() : void
      {
         this.ItemInfo_mc.UpdateDisplay(this.selectedEntry);
         this.ItemInfo_mc.visible = true;
         try { this.hzqSel(); } catch(hzqE4:Error) { }   // Horizon: selection change
      }
      
      public function onKeyDownHandler(param1:KeyboardEvent) : *
      {
         try { if(this.hzqExtArrow(param1)) { param1.stopPropagation(); return; } } catch(hzqE6:Error) { }
         switch(param1.keyCode)
         {
            case Keyboard.UP:
               this.selectedIndex = this._UpDirectory[this.selectedIndex];
               break;
            case Keyboard.DOWN:
               this.selectedIndex = this._DownDirectory[this.selectedIndex];
               break;
            case Keyboard.LEFT:
               this.selectedIndex = this._LeftDirectory[this.selectedIndex];
               break;
            case Keyboard.RIGHT:
               this.selectedIndex = this._RightDirectory[this.selectedIndex];
         }
      }
      
      public function onKeyUpHandler(param1:KeyboardEvent) : *
      {
         try { if(param1.keyCode == Keyboard.ENTER && this.hzqExtConfirm()) { param1.stopPropagation(); return; } } catch(hzqE7:Error) { }
         switch(param1.keyCode)
         {
            case Keyboard.ENTER:
               if(this.selectedIndex != FS_NONE)
               {
                  this.SelectItem();
                  param1.stopPropagation();
               }
         }
      }
      
      private function SelectItem() : void
      {
         try { if(this.hzqExtConfirm()) return; } catch(hzqE8:Error) { }   // Horizon: never AssignQuickkey with index >= 12
         if(int(this.selectedIndex) >= 12) return;
         if(this.isAssigningItem())
         {
            BSUIDataManager.dispatchEvent(new CustomEvent("FavoritesMenu_AssignQuickkey",{"uQuickkeyIndex":this.selectedIndex}));
         }
         else
         {
            BSUIDataManager.dispatchEvent(new CustomEvent("FavoritesMenu_UseQuickkey",{"uQuickkeyIndex":this.selectedIndex}));
         }
         this.StartClosingMenu();
      }
      
      private function onFavEntryMouseover(param1:Event) : void
      {
         try { if(this.hzqExtMouse(param1)) return; } catch(hzqE9:Error) { }   // Horizon: Entry_13-24 name, not constructed entryIndex 0
         this.selectedIndex = param1.target.entryIndex;
         this.OverEntry = true;
      }
      
      private function onFavEntryMouseleave(param1:Event) : void
      {
         this.OverEntry = false;
      }
      
      // =================== Horizon UI quick menu (0.43.3.0, batches f and i): Horizon cards on the game's quick menu ===================
      // Spliced into the vanilla FavoritesMenu class (favoritesmenu.swf / favoritesmenu_lrg.swf, game 1.16.244) by
      // tools/apply_fav_hooks.py. Every vanilla line stays: input, selection, assign mode, the close animation and the
      // game's own icons and data are the game's code. This block only draws on top and hides vanilla art:
      //  - one card per slot (hzqCard), a child of the slot clip at index 0, so the vanilla Open / Close fades move it too.
      //    Every slot gets the same box (HZQ_BOX x HZQ_BOX, batch i), centered on the slot's hit area (Catcher_mc);
      //  - the game's icon (Icon_mc) is fitted into that box (hzqFit): reset to the game's own transform, then scaled by
      //    min(1, room / size) with its aspect kept, centered, below the key badge. Never compounds, never enlarges;
      //  - the slot's key badge = the key the player bound to "Quickkey<n>" (ControlMapData vMappedEvents), keyboard and
      //    mouse only, the same rule as the vanilla Quickkey_tf. No key is hardcoded and nothing keys off Q;
      //  - a header pill above the top slot: QUICK MENU and the bound "Cancel" key: keyboard and mouse = the key text;
      //    controller = the mapped Cancel button (hzqPadKey: a glyph, or the HUD's keycap text, or nothing; never a $ name);
      //  - an info card in ItemInfo_mc built only from the fields the game sends (FavoritesData aFavoriteItems):
      //    sName (+ " (n)" from uCount), AMMO = sAmmoName + uAmmoCount, DAMAGE = aElementalStats (type + floor(fValue)),
      //    SLOT = the selected slot's bound key. There is no magazine / reserve split in the data, so none is shown.
      // Theme: [Style] AccentColor / AccentHex / CardColor / CardHex / CardOpacity / CardBgOpacity / CardShadow / TextTone /
      // FontFace / TextScale / HeaderStyle / TextShadow, read once when the menu opens, through ports of the HUD card
      // functions (hzCardPal, hzAccPal, hzPanel, hzKeycap, ...). Switch: [Cards Extra] QuickMenuHorizon (1 default,
      // 0 = the game's look: nothing is drawn, hidden or moved).
      // Edge-only: no enterFrame, timer or tree search. Handlers and when they fire:
      //   hzqOpen        menu added to stage (onAddedToStage), once per open: starts the ini read
      //   hzqOnIni       the ini read finished (URLLoader COMPLETE / IO_ERROR): builds once, then one full redraw
      //   hzqFontOkEv    font.marker found (URLLoader COMPLETE), once: one full redraw with the Horizon face
      //   hzqData        FavoritesData (end of onDataUpdate, after the game's LoadIcon calls): slot cards + icon fit,
      //                  and hands each Icon_mc the per-slot load handler (hzqIcHook)
      //   hzqIc0..11     an icon finished loading (or failed, or was already loaded): the game's own handler, then that
      //                  slot's icon fit (hzqIcDone). The game's ImageFixture onLoadAttemptComplete edge
      //   hzqSel         selection change (end of onSelectionChange): slot cards + icon fit + info card
      //   hzqAssign      assign mode start (assignedItem setter): info card + icon fit
      //   OnControlMapChanged  ControlMapData (device or binding change): key table, key badges, header, icon fit
      //   OnPlatformChanged    PlatformData (platform change): header (controller close hint)
      // Every Horizon display object has mouseEnabled = mouseChildren = false; the slots keep their own hit areas
      // (Catcher_mc), so mouse hover and click are the game's. Any error turns the Horizon look off for this open and
      // puts the vanilla look back (hzqFail).
      private static const HZQ_LRG:Boolean = false;
      private static const HZQ_ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZQ_CARDCOLS:Array = [0x0B1218,0x16181C,0x0B1630,0x0A2226,0x1E1328,0x2A1014,0x3A4652,0xD5DBE0,0xF2F4F6,0xCCDFEE,0xF0E0C2,0xD2ECDF];
      // One box for all 12 slots (batch i). Measured in both vanilla movies (same numbers at both scales, slot space = menu
      // space): every Catcher_mc is 64 along its arm and 75 across; catcher centers along the arms are 87.95 .. 89.05
      // (inner), 160.65 .. 161.8 (middle) and 235.75 .. 236.8 (outer), so neighbor centers are at least 72.6 apart; the
      // center disc (CenterClip_mc "Quick" backdrop hole) has radius 54. 58 x 58 leaves at least 14.6 between neighbors
      // and 4.95 to the disc, and fits the 64-wide catcher (3 each side) on both arms.
      private static const HZQ_BOX:Number = 58;
      private static const HZQ_ICPAD:Number = 4;          // icon padding inside the box
      private static const HZQ_GLYPH:String = "$Controller_Buttons";   // the game's controller glyph face (fontconfig map)
      // controller glyph character (GlobalFunc.NameToTextMap value) -> keycap text: the HUD's table (horizon_block.as HZ_T19_PADK)
      private static const HZQ_PADK:Object = {"A":"A","B":"B","C":"X","D":"Y","E":"VIEW","O":"MENU","G":"LB","L":"RB","I":"LT","N":"RT","Y":"LT","X":"RT","F":"LS","H":"LS","K":"RS","M":"RS","1":"LB+RB","J":"LT+RT","a":"A","d":"B","c":"X","b":"Y","z":"VIEW","p":"MENU","g":"LB","m":"RB","j":"LT","o":"RT","y":"LT","x":"RT","i":"LS","f":"LS","n":"RS","l":"RS","h":"LB+RB","k":"LT+RT","T":"LEFT","U":"RIGHT","V":"DOWN","W":"UP","t":"LEFT","u":"RIGHT","v":"DOWN","w":"UP","q":"D-PAD","r":"D-PAD","s":"D-PAD"};
      private static const HZQ_INF_W:Number = 380;
      private var hzqOn:Boolean = false;        // Horizon look active for this open (switch on, ini read, no error)
      private var hzqOpened:Boolean = false;
      private var hzqErr:Boolean = false;
      private var hzqS:Object = null;           // [Style] values, read on open
      private var hzqFontLib:int = -1;          // font.marker: -1 checking, 0 absent, 1 present
      private var hzqFontLdr:URLLoader = null;
      private var hzqFontOk:Object = {};
      private var hzqKeys:Object = {};          // user event name -> bound button name (ControlMapData)
      private var hzqKb:Boolean = true;         // keyboard and mouse in use (uiController == 0)
      private var hzqCards:Array = null;        // per slot {s:Sprite, k:TextField, r:Rectangle, ib:{sx,sy,x,y} the game's icon transform, kb:badge bottom below the box top, 0 = no badge}
      private var hzqIcCb:Array = null;         // per slot icon-load handler (hzqIc0 .. hzqIc11)
      private var hzqCtU:ColorTransform = null; // the game's icon tint on an unselected slot (captured before the first Horizon touch)
      private var hzqCtS:ColorTransform = null; // the game's icon tint on the selected slot
      private var hzqGlyph:Object = {};         // controller glyph probe per character: 1 drawn by HZQ_GLYPH, 0 not
      private var hzqHdr:Sprite = null;
      private var hzqHdrT:TextField = null;
      private var hzqHdrK:TextField = null;
      private var hzqInf:Sprite = null;
      private var hzqInfT:Array = null;         // [name, l1, v1, l2, v2, l3, v3]
      private var hzqInfX:Number = 0;
      private var hzqInfY:Number = 0;
      private var hzqInfObj:Object = null;      // what the info card shows (selected entry, or the item being assigned)
      private var hzqInfSel:Boolean = false;    // hzqInfObj is the selected slot (SLOT row allowed)
      private var hzqCtA:ColorTransform = null; // reused: accent tint for symbol icons
      private var hzqCtM:ColorTransform = null; // reused: main text tint for symbol icons
      private var hzqCtN:ColorTransform = null; // reused: identity (images)

      private function hzqOpen() : void
      {
         this.hzqExtDone = false;   // one confirm per open (mouse + SelectItem + Enter must not fire 2-3 assigns)
         if(this.hzqOpened) { return; }
         this.hzqOpened = true;
         try { this.hzq37IniRead(this.hzqOnIni); } catch(e:Error) { this.hzqOn = false; }
      }
      private function hzqOnIni(txt:String) : void
      {
         try
         {
            var on:Boolean = true;
            var st:Object = this.hzqParse(txt);
            on = st.On;
            this.hzqS = st;
            if(!on || this.hzqErr) { this.hzqRestore(); return; }
            this.hzqOn = true;
            this.hzqFontBegin();
            this.hzqBuild();
            this.hzqExtPrepare();
            this.hzqRedraw();
         }
         catch(e:Error) { this.hzqFail(); }
      }
      // defaults = HZ_SET_DEF; ranges = the HUD ini reader (horizon_block.as hzIniApply)
      private function hzqParse(txt:String) : Object
      {
         var st:Object = {"On":true,"AccentColor":0,"AccentHex":-1,"CardColor":0,"CardHex":-1,"CardOpacity":1,"CardBgOpacity":92,"CardShadow":12,"TextTone":0,"FontFace":1,"TextScale":1,"HeaderStyle":0,"TextShadow":false,"HudScale":1,"Extended":false,"SlotCount":24,"SlotsPerRow":6,"ExtLayout":0,"Keys":["","","","","","","","","","","",""]};
         if(txt == null) { return st; }
         var sec:String = "";
         for each(var ln:String in this.hzq37Lines(txt))
         {
            var h:String = this.hzq37Hdr(ln);
            if(h != null) { sec = this.hzq37Alias(h); continue; }
            var kv:Object = this.hzq37KV(ln);
            if(kv == null) { continue; }
            var k:String = String(kv.k);
            var v:String = String(kv.v);
            var nv:Number = Number(v);
            var off:Boolean = v == "0" || v.toLowerCase() == "false";
            if(k == "quickmenuhorizon") { if(sec == "cards extra") { st.On = !off; } }
            else if(k == "quickmenuextended") { st.Extended = !off; }
            else if(k == "quickmenuslotcount" && !isNaN(nv)) { st.SlotCount = int(Math.max(12,Math.min(24,Math.round(nv)))); }
            else if(k == "quickmenuslotsperrow" && !isNaN(nv))
            {
               var pr:int = int(Math.round(nv));
               st.SlotsPerRow = pr <= 4 ? 4 : (pr >= 8 ? 8 : 6);
            }
            else if(k == "quickmenuextendedlayout")
            {
               var lv:String = v.toLowerCase();
               st.ExtLayout = (lv == "1" || lv == "bars" || lv == "bar") ? 1 : 0;
            }
            else if(k.indexOf("quickmenukey") == 0 && k.length > 12)
            {
               var sl:int = int(Number(k.substring(12)));
               if(sl >= 13 && sl <= 24) { st.Keys[sl - 13] = v; }
            }
            if(sec == "style")
            {
               if(k == "accentcolor" && !isNaN(nv)) { st.AccentColor = Math.max(0,Math.min(HZQ_ACCENTS.length,int(nv))); }
               else if(k == "accenthex") { st.AccentHex = this.hzqHex(v); }
               else if(k == "cardcolor" && !isNaN(nv)) { st.CardColor = Math.max(0,Math.min(HZQ_CARDCOLS.length,int(nv))); }
               else if(k == "cardhex") { st.CardHex = this.hzqHex(v); }
               else if(k == "cardopacity" && !isNaN(nv)) { st.CardOpacity = Math.max(0.2,Math.min(1.6,nv)); }
               else if(k == "cardbgopacity") { st.CardBgOpacity = this.hzqPct(v,92); }
               else if(k == "cardshadow") { st.CardShadow = this.hzqPct(v,12); }
               else if(k == "texttone" && !isNaN(nv)) { st.TextTone = Math.max(0,Math.min(2,int(nv))); }
               else if(k == "fontface" && !isNaN(nv)) { st.FontFace = Math.max(0,Math.min(3,int(nv))); }
               else if(k == "textscale" && !isNaN(nv)) { st.TextScale = Math.max(0.8,Math.min(1.3,nv)); }
               else if(k == "headerstyle" && !isNaN(nv)) { st.HeaderStyle = Math.max(0,Math.min(1,int(nv))); }
               else if(k == "textshadow") { st.TextShadow = !off && v.length > 0; }
               else if(k == "hudscale" && !isNaN(nv)) { st.HudScale = Math.max(0.7,Math.min(1.4,nv)); }
            }
         }
         return st;
      }
      private function hzqHex(v:String) : int
      {
         if(v == null) { return -1; }
         v = v.replace(/^\s+|\s+$/g,"").replace("#","").replace("0x","").replace("0X","");
         if(v.length != 6 || !/^[0-9A-Fa-f]{6}$/.test(v)) { return -1; }
         return int(parseInt(v,16));
      }
      private function hzqPct(v:String, def:Number) : Number
      {
         if(v == null) { return def; }
         var t:String = String(v).replace(/^\s+|\s+$/g,"");
         if(t.length == 0) { return def; }
         var n:Number = Number(t);
         if(isNaN(n)) { return def; }
         return Math.max(0,Math.min(100,n));
      }
      // ---------- theme: ports of the HUD card functions (horizon_block.as), same names with hzq ----------
      private function hzqCardPal() : Array
      {
         var a:Array = HZQ_CARDCOLS.concat();
         if(int(this.hzqS.CardHex) >= 0) { a.push(uint(this.hzqS.CardHex)); }
         return a;
      }
      private function hzqAccPal() : Array
      {
         var a:Array = HZQ_ACCENTS.concat();
         if(int(this.hzqS.AccentHex) >= 0) { a.push(uint(this.hzqS.AccentHex)); }
         return a;
      }
      private function hzqAccent() : uint
      {
         var a:Array = this.hzqAccPal();
         return uint(a[Math.max(0,Math.min(a.length - 1,int(this.hzqS.AccentColor)))]);
      }
      private function hzqCardFill() : uint
      {
         var a:Array = this.hzqCardPal();
         return uint(a[Math.max(0,Math.min(a.length - 1,int(this.hzqS.CardColor)))]);
      }
      private function hzqLum(c:uint) : Number
      {
         return (0.2126 * ((c >> 16) & 0xFF) + 0.7152 * ((c >> 8) & 0xFF) + 0.0722 * (c & 0xFF)) / 255;
      }
      private function hzqLight() : Boolean
      {
         return this.hzqLum(this.hzqCardFill()) > 0.55;
      }
      private function hzqDarkText() : Boolean
      {
         if(int(this.hzqS.TextTone) == 1) { return false; }
         if(int(this.hzqS.TextTone) == 2) { return true; }
         return this.hzqLight();
      }
      private function hzqOpExtra() : Number
      {
         return Math.max(0,Math.min(1,(Number(this.hzqS.CardOpacity) - 1) / 0.6));
      }
      private function hzqPanelA() : Number
      {
         var pct:Number = Number(this.hzqS.CardBgOpacity);
         if(isNaN(pct)) { pct = 92; }
         pct = Math.max(0,Math.min(100,pct));
         var a:Number = pct / 100;
         if(Number(this.hzqS.CardOpacity) < 1) { a = a * Math.max(0,Number(this.hzqS.CardOpacity)); }
         return Math.max(0,Math.min(1,a));
      }
      private function hzqCardShA(base:Number) : Number
      {
         var pct:Number = Number(this.hzqS.CardShadow);
         if(isNaN(pct)) { pct = 12; }
         pct = Math.max(0,Math.min(100,pct));
         if(Number(this.hzqS.CardBgOpacity) <= 0) { return 0; }
         return Math.max(0,Math.min(1,base * (pct / 12)));
      }
      private function hzqPanelFill() : uint
      {
         var x:Number = this.hzqOpExtra();
         var f:uint = this.hzqCardFill();
         if(x <= 0) { return f; }
         return this.hzqMix(f,this.hzqLight() ? 0xFFFFFF : 0x000000,x * 0.6);
      }
      private function hzqIconCol(c:uint) : uint
      {
         if(this.hzqDarkText() && this.hzqLum(c) > 0.4) { return this.hzqMix(c,0x000000,0.58); }
         return c;
      }
      private function hzqMix(a:uint, b:uint, t:Number) : uint
      {
         var r:int = int(((a >> 16) & 0xFF) * (1 - t) + ((b >> 16) & 0xFF) * t);
         var g2:int = int(((a >> 8) & 0xFF) * (1 - t) + ((b >> 8) & 0xFF) * t);
         var bl:int = int((a & 0xFF) * (1 - t) + (b & 0xFF) * t);
         return uint((r << 16) | (g2 << 8) | bl);
      }
      private function hzqTextAccent() : uint
      {
         var acc:uint = this.hzqAccent();
         if(this.hzqDarkText() && this.hzqLum(acc) > 0.45) { return this.hzqMix(acc,0x000000,0.55); }
         return acc;
      }
      private function hzqMainCol() : uint { return this.hzqDarkText() ? 0x0E151B : 0xF2F7F9; }
      private function hzqMutCol() : uint { return this.hzqDarkText() ? 0x2E3E46 : 0xB2C0C7; }
      private function hzqDimCol() : uint { return this.hzqDarkText() ? 0x4A5A64 : 0x8E9CA4; }
      // hzPanel: 4 soft shadow rings, a 1 px hairline edge, the card fill at the card opacity
      private function hzqPanel(g:*, x:Number, y:Number, w:Number, h:Number, r:Number, mul:Number) : void
      {
         var lt:Boolean = this.hzqLight();
         var rr:Number = Math.min(r,h / 2);
         var sa:Number = this.hzqCardShA(0.055 * (lt ? 0.55 : 1)) * mul;
         var i:int = 0;
         while(i < 4)
         {
            g.beginFill(0x000000,sa);
            g.drawRoundRect(x - 1 - i,y + 2 - i * 0.5,w + 2 + i * 2,h + 1 + i * 2,(rr + i) * 2,(rr + i) * 2);
            g.endFill();
            i++;
         }
         g.lineStyle(1,lt ? 0x0E1E1C : 0xFFFFFF,(lt ? 0.24 : 0.18) * mul,true,"none");
         g.beginFill(this.hzqPanelFill(),this.hzqPanelA() * mul);
         g.drawRoundRect(x + 0.5,y + 0.5,w - 1,h - 1,rr * 2,rr * 2);
         g.endFill();
         g.lineStyle();
      }
      // hzKeycap + hzKeyCorner: 12 % fill and a ring border in the key color
      private function hzqKeycap(g:*, x:Number, y:Number, w:Number, h:Number, col:uint) : void
      {
         var bt:Number = 1;
         var r:Number = Math.min(h,12) / 2;
         g.lineStyle();
         g.beginFill(col,0.12);
         g.drawRoundRect(x,y,w,h,r * 2,r * 2);
         g.endFill();
         var ri:Number = Math.max(0,r - bt);
         var ov:Number = Math.min(0.5,bt / 2);
         g.beginFill(col,1); g.drawRect(x + r - ov,y,w - 2 * r + 2 * ov,bt); g.endFill();
         g.beginFill(col,1); g.drawRect(x + r - ov,y + h - bt,w - 2 * r + 2 * ov,bt); g.endFill();
         g.beginFill(col,1); g.drawRect(x,y + r - ov,bt,h - 2 * r + 2 * ov); g.endFill();
         g.beginFill(col,1); g.drawRect(x + w - bt,y + r - ov,bt,h - 2 * r + 2 * ov); g.endFill();
         this.hzqKeyCorner(g,x + r,y + r,r,ri,-1,-1,col);
         this.hzqKeyCorner(g,x + w - r,y + r,r,ri,1,-1,col);
         this.hzqKeyCorner(g,x + w - r,y + h - r,r,ri,1,1,col);
         this.hzqKeyCorner(g,x + r,y + h - r,r,ri,-1,1,col);
      }
      private function hzqKeyCorner(g:*, cx:Number, cy:Number, r:Number, ri:Number, sx:int, sy:int, col:uint) : void
      {
         var n:int = 6;
         var i:int = 0;
         g.beginFill(col,1);
         while(i <= n)
         {
            var an:Number = Math.PI / 2 * i / n;
            var px:Number = cx + sx * Math.cos(an) * r;
            var py:Number = cy + sy * Math.sin(an) * r;
            if(i == 0) { g.moveTo(px,py); } else { g.lineTo(px,py); }
            i++;
         }
         i = n;
         while(i >= 0)
         {
            var bn:Number = Math.PI / 2 * i / n;
            g.lineTo(cx + sx * Math.cos(bn) * ri,cy + sy * Math.sin(bn) * ri);
            i--;
         }
         g.lineTo(cx + sx * r,cy);
         g.endFill();
      }
      // hzUC: CAPS, or Title Case when HeaderStyle = 1
      private function hzqUC(s:String) : String
      {
         if(s == null) { return ""; }
         if(int(this.hzqS.HeaderStyle) == 0) { return s.toUpperCase(); }
         var w:Array = s.split(" ");
         var i:int = 0;
         while(i < w.length)
         {
            var ws:String = String(w[i]);
            if(ws.length > 0 && !/[0-9]/.test(ws)) { w[i] = ws.charAt(0).toUpperCase() + ws.substr(1).toLowerCase(); }
            else { w[i] = ws.toUpperCase(); }
            i++;
         }
         return w.join(" ");
      }
      // ---------- fonts (the Scope chip's rule: hzpFace / hzpProbe) ----------
      private function hzqFontBegin() : void
      {
         if(this.hzqFontLdr != null || this.hzqFontLib != -1) { return; }
         var l:URLLoader = new URLLoader();
         this.hzqFontLdr = l;
         l.addEventListener(Event.COMPLETE,this.hzqFontOkEv);
         l.addEventListener(IOErrorEvent.IO_ERROR,this.hzqFontErrEv);
         l.addEventListener("securityError",this.hzqFontErrEv);
         l.load(new URLRequest("HorizonUI/modules/font.marker"));
      }
      private function hzqFontOkEv(e:Event) : void
      {
         this.hzqFontLib = 1;
         this.hzqFontLdr = null;
         try { if(this.hzqOn) { this.hzqRedraw(); } } catch(err:Error) { this.hzqFail(); }
      }
      private function hzqFontErrEv(e:Event) : void
      {
         this.hzqFontLib = 0;
         this.hzqFontLdr = null;
      }
      private function hzqProbe(n:String) : Boolean
      {
         if(this.hzqFontOk[n] != undefined) { return this.hzqFontOk[n] == 1; }
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
         this.hzqFontOk[n] = ok ? 1 : 0;
         return ok;
      }
      // FontFace: 1 $Horizon_Font, 2 $Horizon_Font_Alt (both wait for font.marker), 0 the game font, 3 the game face of the slot key field
      private function hzqFace(w:String) : String
      {
         var f:int = int(this.hzqS.FontFace);
         if(f == 3)
         {
            try { var q:TextField = this.Entry_0.Quickkey_tf; if(q != null && q.getTextFormat().font) { return String(q.getTextFormat().font); } } catch(e3:Error) { }
            return "$MAIN_Font";
         }
         if(f != 1 && f != 2) { return "$MAIN_Font"; }
         if(this.hzqFontLib !== 1) { return "$MAIN_Font"; }
         var want:String;
         if(f == 2 && this.hzqProbe("$Horizon_Font_Alt"))
         {
            want = w == "bd" ? "$Horizon_Font_Alt_Bold" : "$Horizon_Font_Alt";
            if(want == "$Horizon_Font_Alt" || this.hzqProbe(want)) { return want; }
            return "$Horizon_Font_Alt";
         }
         if(!this.hzqProbe("$Horizon_Font")) { return "$MAIN_Font"; }
         want = w == "bd" ? "$Horizon_Font_Bold" : "$Horizon_Font";
         if(want == "$Horizon_Font" || this.hzqProbe(want)) { return want; }
         return "$Horizon_Font";
      }
      private function hzqFs(size:Number) : Number
      {
         var ts:Number = Number(this.hzqS.TextScale);
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         if(HZQ_LRG) { ts *= 1.1; }
         return Math.max(13,Math.round(size * ts * 10) / 10);   // 13 px floor (standing text rule)
      }
      private function hzqTf(p:Sprite) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = TextFieldAutoSize.LEFT;
         p.addChild(t);
         return t;
      }
      // text, size, color, weight, letter spacing (em), header case
      private function hzqSet(t:TextField, s:String, size:Number, col:uint, w:String, tr:Number, hdr:Boolean) : void
      {
         var fs:Number = this.hzqFs(size);
         var f:TextFormat = new TextFormat(this.hzqFace(w),fs,col);
         f.letterSpacing = hdr && int(this.hzqS.HeaderStyle) == 1 ? 0 : Math.round(fs * tr * 10) / 10;
         t.defaultTextFormat = f;
         t.text = s;
         t.setTextFormat(f);
         t.filters = this.hzqS.TextShadow ? [this.hzqDarkText() ? new DropShadowFilter(1.5,90,0xFFFFFF,0.75,2,2,1.6,2) : new DropShadowFilter(1.5,60,0x000000,1,2.5,2.5,2,2)] : [];
      }
      // ---------- build (once per open, after the ini read) ----------
      private function hzqSlot(i:int) : MovieClip
      {
         switch(i)
         {
            case 0: return this.Entry_0;
            case 1: return this.Entry_1;
            case 2: return this.Entry_2;
            case 3: return this.Entry_3;
            case 4: return this.Entry_4;
            case 5: return this.Entry_5;
            case 6: return this.Entry_6;
            case 7: return this.Entry_7;
            case 8: return this.Entry_8;
            case 9: return this.Entry_9;
            case 10: return this.Entry_10;
            case 11: return this.Entry_11;
         }
         return null;
      }
      private function hzqSprite(p:*, at:int) : Sprite
      {
         var s:Sprite = new Sprite();
         s.mouseEnabled = false;
         s.mouseChildren = false;
         if(at >= 0) { p.addChildAt(s,at); } else { p.addChild(s); }
         return s;
      }
      private function hzqBuild() : void
      {
         if(this.hzqCards != null) { return; }
         this.hzqCtA = new ColorTransform();
         this.hzqCtM = new ColorTransform();
         this.hzqCtN = new ColorTransform();
         var cards:Array = [];
         var i:int = 0;
         while(i < 12)
         {
            var e:MovieClip = this.hzqSlot(i);
            var r:Rectangle = null;
            if(e != null)
            {
               // the same box on every slot, centered on the slot's hit area
               var c:* = e["Catcher_mc"];
               var cr:Rectangle = c != null ? c.getBounds(e) : e.getBounds(e);
               r = new Rectangle(cr.x + cr.width / 2 - HZQ_BOX / 2,cr.y + cr.height / 2 - HZQ_BOX / 2,HZQ_BOX,HZQ_BOX);
               // the game's icon transform and tint, before Horizon first touches Icon_mc (fit base and restore)
               var ic:* = e["Icon_mc"];
               var ib:Object = null;
               if(ic != null)
               {
                  ib = {"sx":ic.scaleX,"sy":ic.scaleY,"x":ic.x,"y":ic.y};
                  var ct0:ColorTransform = ic.transform.colorTransform;
                  if(i == int(this.selectedIndex)) { if(this.hzqCtS == null) { this.hzqCtS = ct0; } }
                  else if(this.hzqCtU == null) { this.hzqCtU = ct0; }
               }
               var s:Sprite = this.hzqSprite(e,0);
               s.name = "hzqCard";
               var k:TextField = this.hzqTf(s);
               cards.push({"s":s,"k":k,"r":r,"ib":ib,"kb":0});
            }
            else { cards.push(null); }
            i++;
         }
         this.hzqCards = cards;
         // the game's two icon tints as authored in both movies (Unselected / Selected frame: add 183 / 54, multiply 0),
         // used only when a slot in that state was not seen above
         if(this.hzqCtU == null) { this.hzqCtU = new ColorTransform(0,0,0,1,183,183,183,0); }
         if(this.hzqCtS == null) { this.hzqCtS = new ColorTransform(0,0,0,1,54,54,54,0); }
         this.hzqIcCb = [this.hzqIc0,this.hzqIc1,this.hzqIc2,this.hzqIc3,this.hzqIc4,this.hzqIc5,this.hzqIc6,this.hzqIc7,this.hzqIc8,this.hzqIc9,this.hzqIc10,this.hzqIc11];
         // header pill: a child of the top slot (FS_UP_3), so it fades with the slots
         if(this.Entry_6 != null && cards[6] != null)
         {
            this.hzqHdr = this.hzqSprite(this.Entry_6,-1);
            this.hzqHdr.name = "hzqHeader";
            this.hzqHdrT = this.hzqTf(this.hzqHdr);
            this.hzqHdrK = this.hzqTf(this.hzqHdr);
         }
         // info card: a child of ItemInfo_mc, centered where the game centers its rows (x = 0), top = the name bar's top
         if(this.ItemInfo_mc != null)
         {
            this.hzqInf = this.hzqSprite(this.ItemInfo_mc,0);
            this.hzqInf.name = "hzqInfo";
            var nb:Rectangle = null;
            try { nb = this.ItemInfo_mc.ItemNameBg_mc.getBounds(this.ItemInfo_mc); } catch(eNb:Error) { nb = null; }
            this.hzqInfX = -HZQ_INF_W / 2;
            this.hzqInfY = nb != null ? nb.y : 0;
            this.hzqInfT = [];
            var j:int = 0;
            while(j < 7) { this.hzqInfT.push(this.hzqTf(this.hzqInf)); j++; }
         }
      }
      // ---------- draw ----------
      private function hzqRedraw() : void
      {
         if(!this.hzqOn || this.hzqCards == null) { return; }
         this.hzqTints();
         var i:int = 0;
         while(i < 12) { this.hzqCard(i); i++; }
         this.hzqHeader();
         this.hzqInfo();
         try { this.hzqExtDraw(); } catch(eExtR:Error) { }
      }
      private function hzqTints() : void
      {
         var a:uint = this.hzqIconCol(this.hzqAccent());
         var m:uint = this.hzqMainCol();
         this.hzqCtA.redMultiplier = ((a >> 16) & 0xFF) / 255; this.hzqCtA.greenMultiplier = ((a >> 8) & 0xFF) / 255; this.hzqCtA.blueMultiplier = (a & 0xFF) / 255;
         this.hzqCtM.redMultiplier = ((m >> 16) & 0xFF) / 255; this.hzqCtM.greenMultiplier = ((m >> 8) & 0xFF) / 255; this.hzqCtM.blueMultiplier = (m & 0xFF) / 255;
      }
      // the bound button name of a user event (ControlMapData strButtonName), trimmed; "" when unbound
      private function hzqRaw(ev:String) : String
      {
         var k:* = this.hzqKeys[ev];
         if(k == null) { return ""; }
         return String(k).replace(/^\s+|\s+$/g,"");
      }
      private function hzqKey(ev:String) : String
      {
         var t:String = this.hzqRaw(ev);
         if(t.length == 0 || t == "?" || t.charAt(0) == "$" || t == "null" || t == "undefined") { return ""; }
         return t.length > 10 ? t.substr(0,10).toUpperCase() : t.toUpperCase();
      }
      // hides the slot's vanilla art: its direct children (at most a handful) other than the named parts and the card.
      // Runs on every slot redraw because the Selected / Unselected frames re-create the tier art.
      private function hzqHideArt(e:MovieClip, hide:Boolean) : void
      {
         var n:int = Math.min(e.numChildren,10);
         var i:int = 0;
         while(i < n)
         {
            var d:DisplayObject = e.getChildAt(i);
            var nm:String = d.name;
            if(nm != "Icon_mc" && nm != "Catcher_mc" && nm != "Quickkey_tf" && nm != "SlotInfoSpacer_mc" && nm != "hzqCard" && nm != "hzqHeader") { d.visible = !hide; }
            i++;
         }
         var q:* = e["Quickkey_tf"];
         if(q != null) { q.alpha = hide ? 0 : 1; }
      }
      // Entry / Catcher / a parent mask clip any stroke drawn on the card. Clear those so the
      // overlay ring (a child of the menu) is not cut off. Does not change the 58 px card.
      private function hzqUnclip(d:DisplayObject) : void
      {
         if(d == null) { return; }
         try { d.mask = null; } catch(e0:Error) { }
         try { var m:MovieClip = d as MovieClip; if(m != null) { m.scrollRect = null; } } catch(e1:Error) { }
         try
         {
            var c:* = d["Catcher_mc"];
            if(c != null) { c.mask = null; c.scrollRect = null; }
         }
         catch(e2:Error) { }
      }
      private function hzqCard(i:int) : void
      {
         var c:Object = this.hzqCards[i];
         var e:MovieClip = this.hzqSlot(i);
         if(c == null || e == null) { return; }
         this.hzqHideArt(e,true);
         this.hzqUnclip(e);
         // vanilla Selected frame draws an accent outline that Catcher clips; overlay ring is the hover stroke
         try { e.gotoAndStop("Unselected"); } catch(eUs:Error) { }
         var it:Object = this.FavoritesInfoA != null && i < this.FavoritesInfoA.length ? this.FavoritesInfoA[i] : null;
         var empty:Boolean = it == null || it.sName == null || String(it.sName).length == 0;
         var sel:Boolean = i == int(this.selectedIndex);
         var r:Rectangle = c.r;
         var s:Sprite = c.s;
         var g:* = s.graphics;
         g.clear();
         var acc:uint = this.hzqAccent();
         this.hzqPanel(g,r.x,r.y,r.width,r.height,8,empty && !sel ? 0.6 : 1);
         if(sel)
         {
            g.beginFill(acc,0.13);
            g.drawRoundRect(r.x + 1,r.y + 1,r.width - 2,r.height - 2,14,14);
            g.endFill();
         }
         // key badge: top left, the bound Quickkey<n>, keyboard and mouse only
         var kt:String = this.hzqKb ? this.hzqKey("Quickkey" + (i + 1)) : "";
         var k:TextField = c.k;
         if(kt.length > 0)
         {
            this.hzqSet(k,kt,13,sel ? this.hzqTextAccent() : this.hzqMutCol(),"sb",0.04,false);
            var kw:Number = Math.max(16,Math.ceil(k.textWidth * 1.08) + 8);
            var kh:Number = Math.max(16,Math.ceil(k.textHeight) + 3);
            this.hzqKeycap(g,r.x + 5,r.y + 5,kw,kh,sel ? this.hzqIconCol(acc) : this.hzqDimCol());
            k.x = r.x + 5 + (kw - k.width) / 2;
            k.y = r.y + 5 + (kh - k.height) / 2;
            k.visible = true;
            c.kb = 5 + kh;
         }
         else { k.visible = false; c.kb = 0; }
         // the game's icon: symbols take the accent when selected, the main text color otherwise; pictures stay as they are
         var ic:* = e["Icon_mc"];
         if(ic != null)
         {
            var sym:Boolean = !empty && it.iconImage != null && it.iconImage.iFixtureType == ImageFixture.FT_SYMBOL;
            ic.transform.colorTransform = sym ? (sel ? this.hzqCtA : this.hzqCtM) : this.hzqCtN;
            this.hzqIcHook(i,ic);
            this.hzqFit(i);
         }
      }
      // ---------- the game's icon in the box (batch i) ----------
      // Icon_mc's load edge -> this slot's handler. Set after the game's LoadIcon (which sets the entry's own handler);
      // hzqIcDone calls that handler first, so the game's icon behavior stays.
      private function hzqIcHook(i:int, ic:*) : void
      {
         if(this.hzqIcCb != null && i < this.hzqIcCb.length) { ic.onLoadAttemptComplete = this.hzqIcCb[i]; }
      }
      private function hzqIc0() : void { this.hzqIcDone(0); }
      private function hzqIc1() : void { this.hzqIcDone(1); }
      private function hzqIc2() : void { this.hzqIcDone(2); }
      private function hzqIc3() : void { this.hzqIcDone(3); }
      private function hzqIc4() : void { this.hzqIcDone(4); }
      private function hzqIc5() : void { this.hzqIcDone(5); }
      private function hzqIc6() : void { this.hzqIcDone(6); }
      private function hzqIc7() : void { this.hzqIcDone(7); }
      private function hzqIc8() : void { this.hzqIcDone(8); }
      private function hzqIc9() : void { this.hzqIcDone(9); }
      private function hzqIc10() : void { this.hzqIcDone(10); }
      private function hzqIc11() : void { this.hzqIcDone(11); }
      private function hzqIcDone(i:int) : void
      {
         var fe:FavoritesEntry = this.hzqSlot(i) as FavoritesEntry;
         if(fe == null) { return; }
         try { fe.onIconLoadAttemptComplete(); } catch(e0:Error) { }
         if(!this.hzqOn) { return; }
         try { this.hzqFit(i); } catch(e1:Error) { this.hzqFail(); }
      }
      // Fit: back to the game's transform first (so it never compounds across redraws, selection, assign or a new icon in
      // the same slot), measure the loaded picture / symbol, then scale by min(1, room w / w, room h / h) (aspect kept,
      // never larger than the game's) and center it in the box below the key badge. Nothing loaded or a zero size: the
      // game's transform stays.
      private function hzqFit(i:int) : void
      {
         var c:Object = this.hzqCards != null ? this.hzqCards[i] : null;
         var e:MovieClip = this.hzqSlot(i);
         if(c == null || e == null || c.ib == null) { return; }
         var ic:* = e["Icon_mc"];
         if(ic == null) { return; }
         var b:Object = c.ib;
         ic.scaleX = b.sx;
         ic.scaleY = b.sy;
         ic.x = b.x;
         ic.y = b.y;
         if(!ic.visible) { return; }
         var nb:Rectangle = this.hzqIcB(ic,e);
         if(nb == null || !(nb.width > 0.5) || !(nb.height > 0.5)) { return; }
         var r:Rectangle = c.r;
         var top:Number = r.y + HZQ_ICPAD;
         if(Number(c.kb) > 0) { top = Math.max(top,r.y + Number(c.kb) + 2); }
         var aw:Number = r.width - HZQ_ICPAD * 2;
         var ah:Number = r.y + r.height - HZQ_ICPAD - top;
         if(aw < 4 || ah < 4) { return; }
         var k:Number = Math.min(1,Math.min(aw / nb.width,ah / nb.height));
         ic.scaleX = b.sx * k;
         ic.scaleY = b.sy * k;
         ic.x = r.x + r.width / 2 - (nb.x + nb.width / 2 - b.x) * k;
         ic.y = top + ah / 2 - (nb.y + nb.height / 2 - b.y) * k;
      }
      // the loaded picture and symbol only (ImageFixture imageInstance / symbolInstance while on the display list), in slot
      // space; not BoundClip_mc, the game's fixed 60 x 60 sizer that is always there. null = nothing loaded.
      private function hzqIcB(ic:*, e:MovieClip) : Rectangle
      {
         var u:Rectangle = null;
         var a:* = null;
         try { a = ic.imageInstance; } catch(e1:Error) { a = null; }
         if(a != null && a.parent != null && a.visible) { u = a.getBounds(e); }
         var m:* = null;
         try { m = ic.symbolInstance; } catch(e2:Error) { m = null; }
         if(m != null && m.parent != null && m.visible)
         {
            var mb:Rectangle = m.getBounds(e);
            u = u == null ? mb : u.union(mb);
         }
         return u;
      }
      private function hzqFitAll() : void
      {
         var i:int = 0;
         while(i < 12) { this.hzqFit(i); i++; }
      }
      // the game's icon back: its own transform (captured in hzqBuild) and the game's tint for the slot's state
      private function hzqIcRestore(i:int) : void
      {
         var c:Object = this.hzqCards != null ? this.hzqCards[i] : null;
         var e:MovieClip = this.hzqSlot(i);
         if(c == null || e == null) { return; }
         var ic:* = e["Icon_mc"];
         if(ic == null) { return; }
         if(c.ib != null)
         {
            ic.scaleX = c.ib.sx;
            ic.scaleY = c.ib.sy;
            ic.x = c.ib.x;
            ic.y = c.ib.y;
         }
         var ct:ColorTransform = i == int(this.selectedIndex) ? this.hzqCtS : this.hzqCtU;
         if(ct != null) { ic.transform.colorTransform = ct; }
      }
      private function hzqHeader() : void
      {
         if(this.hzqHdr == null) { return; }
         var r:Rectangle = this.hzqCards[6].r;
         var g:* = this.hzqHdr.graphics;
         g.clear();
         this.hzqSet(this.hzqHdrT,this.hzqUC("Quick Menu"),13,this.hzqTextAccent(),"bd",0.14,true);
         var kt:String = "";
         var kf:String = "";
         if(this.hzqKb) { kt = this.hzqKey("Cancel"); }
         else { var pk:Array = this.hzqPadKey("Cancel"); kt = String(pk[0]); kf = String(pk[1]); }
         var pad:Number = 14;
         var h:Number = Math.max(30,Math.ceil(this.hzqHdrT.textHeight) + 14);
         var w:Number = pad + this.hzqHdrT.width + pad;
         var kw:Number = 0;
         var kh:Number = 0;
         if(kt.length > 0)
         {
            this.hzqSet(this.hzqHdrK,kt,13,this.hzqMutCol(),"sb",0.04,false);
            if(kf.length > 0)
            {
               var gf:TextFormat = new TextFormat(kf,this.hzqFs(14),this.hzqMutCol());
               this.hzqHdrK.defaultTextFormat = gf;
               this.hzqHdrK.setTextFormat(gf);
            }
            kw = Math.max(16,Math.ceil(this.hzqHdrK.textWidth * 1.08) + 8);
            kh = Math.max(16,Math.ceil(this.hzqHdrK.textHeight) + 3);
            w += kw + 10;
            this.hzqHdrK.visible = true;
         }
         else { this.hzqHdrK.visible = false; }
         var x0:Number = Math.round(r.x + r.width / 2 - w / 2);
         var y0:Number = Math.round(r.y - 10 - h);
         this.hzqPanel(g,x0,y0,w,h,h / 2,1);
         this.hzqHdrT.x = x0 + pad;
         this.hzqHdrT.y = y0 + (h - this.hzqHdrT.height) / 2;
         if(kt.length > 0)
         {
            var kx:Number = x0 + w - pad - kw;
            var ky:Number = y0 + (h - kh) / 2;
            if(kf.length == 0) { this.hzqKeycap(g,kx,ky,kw,kh,this.hzqDimCol()); }
            this.hzqHdrK.x = kx + (kw - this.hzqHdrK.width) / 2;
            this.hzqHdrK.y = ky + (kh - this.hzqHdrK.height) / 2;
         }
      }
      // Controller close hint: the button mapped to "Cancel" (ControlMapData strButtonName, a vanilla button name such as
      // Xenon_B or PSN_B) -> the game's glyph character (GlobalFunc.NameToTextMap, the table the vanilla button hints use).
      // Drawn as that glyph in HZQ_GLYPH when this movie can draw it (hzqGlyphOk), else as the HUD's keycap text for the
      // glyph (HZQ_PADK). A name or glyph not in those tables: ["",""] = no badge. Never the raw name, never a "$" token.
      private function hzqPadKey(ev:String) : Array
      {
         var raw:String = this.hzqRaw(ev);
         if(raw.length == 0 || raw.charAt(0) == "$" || !GlobalFunc.NameToTextMap.hasOwnProperty(raw)) { return ["",""]; }
         var gs:String = String(GlobalFunc.NameToTextMap[raw]);
         if(gs.length == 0 || gs.charAt(0) == "$") { return ["",""]; }
         if(this.hzqGlyphOk(gs)) { return [gs,HZQ_GLYPH]; }
         if(HZQ_PADK.hasOwnProperty(gs)) { return [String(HZQ_PADK[gs]),""]; }
         return ["",""];
      }
      // one character drawn by HZQ_GLYPH (not the fallback face): the hzqProbe rule, once per character
      private function hzqGlyphOk(ch:String) : Boolean
      {
         if(ch == null || ch.length != 1) { return false; }
         if(this.hzqGlyph[ch] != undefined) { return this.hzqGlyph[ch] == 1; }
         var ok:Boolean = false;
         try
         {
            var t:TextField = new TextField();
            t.embedFonts = true;
            var tf:TextFormat = new TextFormat(HZQ_GLYPH,20,0xFFFFFF);
            t.defaultTextFormat = tf; t.text = ch; t.setTextFormat(tf);
            var x:TextField = new TextField();
            x.embedFonts = true;
            var xf:TextFormat = new TextFormat("$Horizon_NoSuchFace_x",20,0xFFFFFF);
            x.defaultTextFormat = xf; x.text = ch; x.setTextFormat(xf);
            ok = t.textWidth > 2 && Math.abs(x.textWidth - t.textWidth) >= 0.01;
         }
         catch(err:Error) { ok = false; }
         this.hzqGlyph[ch] = ok ? 1 : 0;
         return ok;
      }
      private function hzqInfoSet(o:Object, isSel:Boolean) : void
      {
         this.hzqInfObj = o;
         this.hzqInfSel = isSel;
         if(this.hzqOn) { this.hzqInfo(); }
      }
      private function hzqElem(t:int) : String
      {
         var l:String = InventoryItemUtils.GetElementalLabel(t);
         if(l == "physical") { return "PHYS"; }
         if(l == "em") { return "EM"; }
         if(l == "energy") { return "ENERGY"; }
         return "";
      }
      private function hzqInfo() : void
      {
         if(this.hzqInf == null) { return; }
         var o:Object = this.hzqInfObj;
         this.hzqHideInfoVan(true);
         var g:* = this.hzqInf.graphics;
         g.clear();
         var T:Array = this.hzqInfT;
         if(o == null || o.sName == null)
         {
            var z:int = 0;
            while(z < T.length) { TextField(T[z]).visible = false; z++; }
            return;
         }
         var W:Number = HZQ_INF_W;
         var P:Number = 16;
         var acc:uint = this.hzqAccent();
         var empty:Boolean = String(o.sName).length == 0;
         // name: the game's string ($EMPTY SLOT is translated by GlobalFunc.SetText), + " (n)" like the game
         var nt:TextField = T[0];
         this.hzqSet(nt," ",17,empty ? this.hzqDimCol() : this.hzqMainCol(),"bd",0.04,false);
         GlobalFunc.SetText(nt,empty ? "$EMPTY SLOT" : String(o.sName),false);
         if(!empty && uint(o.uCount) > 1) { nt.appendText(" (" + uint(o.uCount) + ")"); }
         nt.autoSize = TextFieldAutoSize.NONE;
         nt.wordWrap = true;
         nt.multiline = true;
         nt.width = W - P * 2;
         nt.height = Math.ceil(nt.textHeight) + 4;
         nt.x = this.hzqInfX + P;
         nt.y = this.hzqInfY + 12;
         nt.visible = true;
         var rows:Array = [];
         if(!empty && o.bIsEquippable && o.sAmmoName != null && String(o.sAmmoName).length > 0)
         {
            var n:uint = uint(o.uAmmoCount);
            rows.push(["AMMO",String(o.sAmmoName) + "  " + (n > 999 ? "999+" : String(n))]);
         }
         if(!empty && o.bIsEquippable && o.aElementalStats != null && o.aElementalStats.length > 0)
         {
            var d:Array = [];
            var q:int = 0;
            while(q < o.aElementalStats.length && q < 4)
            {
               var lb:String = this.hzqElem(int(o.aElementalStats[q].iElementalType));
               if(lb.length > 0) { d.push(lb + " " + Math.floor(Number(o.aElementalStats[q].fValue))); }
               q++;
            }
            if(d.length > 0) { rows.push(["DAMAGE",d.join("   ")]); }
         }
         if(this.hzqInfSel && this.hzqKb)
         {
            var sk:String = this.hzqKey("Quickkey" + (int(this.selectedIndex) + 1));
            if(sk.length > 0) { rows.push(["SLOT",sk]); }
         }
         var y:Number = nt.y + nt.height + (rows.length > 0 ? 8 : 4);
         var div:Number = y - 4;
         var j:int = 0;
         while(j < 3)
         {
            var lt:TextField = T[1 + j * 2];
            var vt:TextField = T[2 + j * 2];
            if(j < rows.length)
            {
               this.hzqSet(lt,this.hzqUC(String(rows[j][0])),13,this.hzqDimCol(),"sb",0.14,true);
               this.hzqSet(vt,String(rows[j][1]),13,this.hzqMainCol(),"sb",0.02,false);
               lt.x = this.hzqInfX + P; lt.y = y + (vt.height - lt.height) / 2;
               vt.x = this.hzqInfX + W - P - vt.width; vt.y = y;
               lt.visible = true; vt.visible = true;
               y += vt.height + 2;
            }
            else { lt.visible = false; vt.visible = false; }
            j++;
         }
         var H:Number = Math.ceil(y - this.hzqInfY + 10);
         this.hzqPanel(g,this.hzqInfX,this.hzqInfY,W,H,10,1);
         // the accent bar on the left edge (hzAccStripe on tall cards; this card is short, so a slim bar the card's height)
         g.beginFill(this.hzqIconCol(acc),1);
         g.drawRoundRect(this.hzqInfX,this.hzqInfY + 10,3,Math.max(8,H - 20),3,3);
         g.endFill();
         if(rows.length > 0)
         {
            g.beginFill(this.hzqLight() ? 0x0E1E1C : 0xFFFFFF,0.1);
            g.drawRect(this.hzqInfX + P,div,W - P * 2,1);
            g.endFill();
         }
      }
      private function hzqHideInfoVan(hide:Boolean) : void
      {
         var a:Number = hide ? 0 : 1;
         var m:* = this.ItemInfo_mc;
         if(m == null) { return; }
         if(m.ItemNameBg_mc != null) { m.ItemNameBg_mc.alpha = a; }
         if(m.ItemName_mc != null) { m.ItemName_mc.alpha = a; }
         if(m.AmmoType_mc != null) { m.AmmoType_mc.alpha = a; }
         if(m.AmmoAmount_mc != null) { m.AmmoAmount_mc.alpha = a; }
         if(m.DamageTypeHolder_mc != null) { m.DamageTypeHolder_mc.alpha = a; }
      }
      // ---------- hooks ----------
      private function hzqData() : void
      {
         if(!this.hzqOn) { return; }
         try { this.hzqExtPad(); var i:int = 0; while(i < 12) { this.hzqCard(i); i++; } if(!this.hzqExtGot && this.hzqExtOn()) { this.hzqExtFetch(); } this.hzqExtDraw(); if(this.hzqExtOn()) { this.hzqExtRaise(); } this.hzqRingDraw(); } catch(e:Error) { this.hzqFail(); }
      }
      private function hzqSel() : void
      {
         if(!this.hzqOn)
         {
            this.hzqInfObj = this.selectedEntry;
            this.hzqInfSel = true;
            // after an error: the game's icon tint follows the selection again (hzqRestore set it once)
            if(this.hzqCards != null) { try { var j:int = 0; while(j < 12) { this.hzqIcRestore(j); j++; } } catch(e0:Error) { } }
            return;
         }
         try
         {
            var idx:int = int(this.selectedIndex);
            if(idx >= 13 && idx <= 24)
            {
               this.hzqExtSel = idx;
               var d:Object = this.hzqExtData[String(idx)];
               if(d != null) { this.hzqInfoSet({"sName":String(d.name != null ? d.name : ""),"uCount":d.count,"sAmmoName":"","uAmmoCount":0,"aElementalStats":null},true); }
               else { this.hzqInfoSet({"sName":"EMPTY","uCount":0},true); }
            }
            else
            {
               this.hzqInfObj = this.selectedEntry;
               this.hzqInfSel = true;
               if(idx >= 0 && idx < 12 && this.hzqExtSel != 0) { this.hzqExtSel = 0; }
            }
            var i:int = 0;
            while(i < 12) { this.hzqCard(i); i++; }
            if(idx < 13) { this.hzqInfo(); }
            this.hzqExtDraw();
            this.hzqRingDraw();
         }
         catch(e:Error) { this.hzqFail(); }
      }
      private function hzqAssign() : void
      {
         try { this.hzqExtPad(); this.hzqInfoSet(this.AssignedItem,false); if(this.hzqOn) { this.hzqFitAll(); } if(this.hzqExtOn()) { this.hzqExtRaise(); this.hzqRingDraw(); } } catch(e:Error) { this.hzqFail(); }
      }
      override protected function OnControlMapChanged(param1:Object) : void
      {
         super.OnControlMapChanged(param1);
         try { this.hzqCtl(param1); } catch(e:Error) { this.hzqFail(); }
      }
      // ControlMapData: the bound key names (one pass over vMappedEvents per change) and the device
      // PlatformData (BSDisplayObject.OnPlatformChanged(param1:Object), uPlatform): the controller close hint again
      override protected function OnPlatformChanged(param1:Object) : void
      {
         super.OnPlatformChanged(param1);
         try { if(this.hzqOn) { this.hzqHeader(); } } catch(e:Error) { this.hzqFail(); }
      }
      private function hzqCtl(d:Object) : void
      {
         if(d == null) { return; }
         this.hzqKb = uint(d.uiController) == PlatformUtils.PLATFORM_PC_KB_MOUSE;
         if(d.vMappedEvents != null)
         {
            var t:Object = {};
            for each(var m:* in d.vMappedEvents)
            {
               if(m != null && m.strUserEventName != null && t[String(m.strUserEventName)] == undefined) { t[String(m.strUserEventName)] = m.strButtonName; }
            }
            this.hzqKeys = t;
         }
         if(this.hzqOn) { this.hzqRedraw(); }
      }
      // ---------- off / error: the game's look ----------
      private function hzqRestore() : void
      {
         this.hzqOn = false;
         if(this.hzqCards == null) { return; }
         var i:int = 0;
         while(i < 12)
         {
            var e:MovieClip = this.hzqSlot(i);
            var c:Object = this.hzqCards[i];
            if(e != null) { try { this.hzqHideArt(e,false); } catch(e1:Error) { } }
            if(c != null) { c.s.visible = false; }
            if(e != null) { try { this.hzqIcRestore(i); } catch(e2:Error) { } }
            i++;
         }
         if(this.hzqHdr != null) { this.hzqHdr.visible = false; }
         if(this.hzqInf != null) { this.hzqInf.visible = false; }
         try { this.hzqHideInfoVan(false); } catch(e3:Error) { }
         try { this.hzqExtRestore(); } catch(e4:Error) { }
      }

      // ---------- 0.43.5 Extended Mode (original Horizon layout; slots 13-24) ----------
      // CROSS + BARS leaves Entry_0..11 on the vanilla T (authored rest; never captured live during
      // the Open animation). BARS restores those clips to authored rest, then slides them into rows.
      // Extended slots are first-class Entry_13..Entry_24 in the same container as Entry_0..11.
      // Index 12 stays FS_NONE (vanilla). AssignQuickkey is never sent with an index >= 12.
      private var hzqExtSel:int = 0;          // 13-24, or 0
      private var hzqExtHold:Sprite = null;
      private var hzqRing:Sprite = null;      // accent hover/focus ring; child of the menu so Entry/Catcher cannot clip it
      private var hzqExtSlots:Array = null;   // {s:MovieClip, k:TextField, n:TextField, i:int}
      private var hzqExtAdd:Sprite = null;
      private var hzqExtPool:Array = null;    // 12 slot clips (13-24), built once per open, reused (perf standards 2)
      private var hzqExtAddDrawn:Boolean = false;
      private var hzqExtHome:Array = null;    // authored rest {x,y} for Entry_0..11 (BARS restore)
      private var hzqExtMoved:Boolean = false;  // true after BARS moved Entry_0..11 off the T
      private var hzqExtData:Object = {};     // "13" -> {name,count,kind,empty,refuse}
      private var hzqExtKeyL:Boolean = false;
      private var hzqExtGot:Boolean = false;  // "ready" answered this open
      private var hzqExtDone:Boolean = false; // one-shot: a successful assign/use this open already ran
      // Set by the DLL (SetMember) on the first frame of each open. FavoritesMenu is a sealed class, so the slot
      // must be declared for SetMember to land; null until the DLL binds it.
      public var hzqExtCmd:Function = null;
      private var hzqExtMask:int = 0;   // N-4: bit i = the DLL refused slot 13+i's key (game-bound, F11 or duplicate)
      private static const HZQ_PITCH:Number = 70;
      // Vanilla FavoritesMenu rest geometry (game 1.16.244, both scales). Live getBounds during Open
      // collapses the T to the origin, which stacked the bars on the cross and hid slots 1-12.
      private static const HZQ_REST_X:Array = [-195.75,-120.8,-40.05,40,120.8,195.8,0,0,0,0,0,0];
      private static const HZQ_REST_Y:Array = [0,0,0,0,0,0,-195.65,-120.65,-39.95,40.05,120.65,195.75];
      private static const HZQ_T_LEFT:Number = -267.75;
      private static const HZQ_T_RIGHT:Number = 268.8;
      private static const HZQ_T_TOP:Number = -267.65;
      private static const HZQ_T_BOTTOM:Number = 268.75;
      private static const HZQ_T_CX:Number = 0;
      private function hzqExtOn() : Boolean
      {
         return this.hzqOn && this.hzqS != null && this.hzqS.Extended === true;
      }
      private function hzqExtCount() : int
      {
         if(!this.hzqExtOn()) { return 12; }
         var n:int = int(this.hzqS.SlotCount);
         if(n < 12) { n = 12; }
         if(n > 24) { n = 24; }
         return n;
      }
      private function hzqExtPer() : int
      {
         var p:int = this.hzqS != null ? int(this.hzqS.SlotsPerRow) : 6;
         if(p <= 4) { return 4; }
         if(p >= 8) { return 8; }
         return 6;
      }
      private function hzqExtCmdSend(op:String, slot:int, extra:String) : String
      {
         try
         {
            if(this.hzqExtCmd != null) { return String(this.hzqExtCmd(op,slot,extra)); }
         }
         catch(e:Error) { }
         return "";
      }
      // Pad aFavoriteItems so selectedIndex 13-24 (and FS_NONE=12) has a dummy row.
      // Vanilla UpdateDisplay(null) throws; index 12 is FS_NONE, not a slot.
      private function hzqExtPad() : void
      {
         if(this.FavoritesInfoA == null) { this.FavoritesInfoA = []; }
         while(this.FavoritesInfoA.length < 25)
         {
            this.FavoritesInfoA.push({sName:"",uCount:0,bIsEquippable:false,iconImage:{iFixtureType:0}});
         }
      }
      // Accent hover/focus outline. Drawn on a menu-level sprite so Entry / Catcher / SelectQuickslot
      // cannot clip any of the four sides. Same 2 px accent stroke as the card; the card look is unchanged.
      private function hzqRingEnsure() : void
      {
         if(this.hzqRing != null) { return; }
         var s:Sprite = new Sprite();
         s.name = "hzqRing";
         s.mouseEnabled = false;
         s.mouseChildren = false;
         this.addChild(s);
         this.hzqRing = s;
      }
      private function hzqRingDraw() : void
      {
         this.hzqRingEnsure();
         var g:Graphics = this.hzqRing.graphics;
         g.clear();
         if(!this.hzqOn) { return; }
         var acc:uint = this.hzqAccent();
         var x:Number = 0;
         var y:Number = 0;
         var on:Boolean = false;
         var idx:int = int(this.selectedIndex);
         if(idx >= 0 && idx < 12 && this.hzqCards != null && this.hzqCards[idx] != null)
         {
            var e:MovieClip = this.hzqSlot(idx);
            var r:Rectangle = this.hzqCards[idx].r;
            if(e != null && r != null)
            {
               var p:Point = this.globalToLocal(e.localToGlobal(new Point(r.x + r.width / 2,r.y + r.height / 2)));
               x = p.x;
               y = p.y;
               on = true;
            }
         }
         else if(this.hzqExtSel >= 13)
         {
            var k:int = 0;
            while(this.hzqExtSlots != null && k < this.hzqExtSlots.length)
            {
               if(int(this.hzqExtSlots[k].i) == this.hzqExtSel) { x = Number(this.hzqExtSlots[k].x); y = Number(this.hzqExtSlots[k].y); on = true; break; }
               k++;
            }
         }
         if(!on) { return; }
         g.beginFill(0,0.01);
         g.drawRect(x - 40,y - 40,80,80);
         g.endFill();
         g.lineStyle(2,acc,1,true,"none");
         g.drawRoundRect(x - 26,y - 26,52,52,14,14);
         g.lineStyle();
      }
      // InventoryMenu item objects name both uFormID and uHandleID (separate fields). FavoritesMenu
      // never reads either: AssignedItem / aFavoriteItems are used as sName, bIsPower, iconImage,
      // uCount, sAmmoName, uAmmoCount, aElementalStats. ItemToBeAssigned may still carry uFormID
      // when it is a full inventory object. The DLL resolves the item from InventoryMenu's selected
      // handle / FormID; the movie only sends a hint. Never send uHandleID as a form ID.
      private function hzqExtFormId(it:Object) : uint
      {
         if(it == null) { return 0; }
         var n:Number;
         try { n = Number(it.uFormID); if(n > 0 && n < 4294967295) { return uint(n); } } catch(e1:Error) { }
         try { n = Number(it.formID); if(n > 0 && n < 4294967295) { return uint(n); } } catch(e2:Error) { }
         try { n = Number(it.uBaseFormID); if(n > 0 && n < 4294967295) { return uint(n); } } catch(e3:Error) { }
         return 0;
      }
      private function hzqExtHex(id:uint) : String
      {
         var s:String = id.toString(16).toUpperCase();
         while(s.length < 8) { s = "0" + s; }
         return "0x" + s;
      }
      private function hzqExtPrepare() : void
      {
         if(!this.hzqExtOn()) { this.hzqExtRestore(); return; }
         this.hzqExtRemember();
         this.hzqExtFetch();
         this.hzqExtListen(true);
         this.hzqExtPlace();
      }
      private function hzqExtFetch() : void
      {
         if(this.hzqExtCmd == null) { return; }
         var pay:String = this.hzqExtCmdSend("ready",0,"");
         this.hzqExtGot = true;
         if(pay != null && pay.length > 0) { this.hzqExtApply(pay); }
      }
      // Called by the DLL right after it binds hzqExtCmd (edge, once per open): fetch slot data if the ini read
      // finished first. No-op when Extended Mode is off or the data is already in.
      public function hzqExtKick() : void
      {
         try
         {
            if(!this.hzqOn || this.hzqExtGot || !this.hzqExtOn()) { return; }
            var n0:int = this.hzqExtCount();
            this.hzqExtFetch();
            if(this.hzqExtHold != null && this.hzqExtCount() != n0) { this.hzqExtPlace(); }   // N-5: the DLL's count won
            this.hzqExtDraw();
         }
         catch(e:Error) { }
      }
      private function hzqExtRemember() : void
      {
         if(this.hzqExtHome != null) { return; }
         this.hzqExtHome = [];
         var i:int = 0;
         while(i < 12)
         {
            this.hzqExtHome.push({"x":Number(HZQ_REST_X[i]),"y":Number(HZQ_REST_Y[i])});
            i++;
         }
      }
      private function hzqExtTBox() : Object
      {
         return {"l":HZQ_T_LEFT,"r":HZQ_T_RIGHT,"t":HZQ_T_TOP,"b":HZQ_T_BOTTOM,"cx":HZQ_T_CX,"cy":0};
      }
      private function hzqExtPlace() : void
      {
         if(!this.hzqExtOn()) { return; }
         this.hzqExtRemember();
         var box:Object = this.hzqExtTBox();
         var n:int = this.hzqExtCount();
         var per:int = this.hzqExtPer();
         var pitch:Number = HZQ_PITCH;
         var bars:Boolean = int(this.hzqS.ExtLayout) != 0;
         var i:int;
         try
         {
            if(this.CenterClip_mc != null) { this.CenterClip_mc.visible = !bars; }
         }
         catch(eCc:Error) { }
         if(bars)
         {
            // Clips are center-registered. Live getBounds during Open is the collapsed T, so
            // write x/y to the grid cell center directly (no bounds delta).
            this.hzqExtMoved = true;
            var rows:int = int(Math.ceil(n / per));
            var y0:Number = box.cy - (rows - 1) * pitch / 2;
            i = 0;
            while(i < 12 && i < n)
            {
               var row:int = int(Math.floor(i / per));
               var col:int = i - row * per;
               var take:int = n - row * per;
               if(take > per) { take = per; }
               var x0:Number = box.cx - (take - 1) * pitch / 2;
               var ev:MovieClip = this.hzqSlot(i);
               if(ev != null)
               {
                  ev.x = x0 + col * pitch;
                  ev.y = y0 + row * pitch;
               }
               i++;
            }
         }
         else if(this.hzqExtMoved)
         {
            i = 0;
            while(i < 12)
            {
               var er:MovieClip = this.hzqSlot(i);
               if(er != null && this.hzqExtHome != null && this.hzqExtHome[i] != null)
               {
                  er.x = Number(this.hzqExtHome[i].x);
                  er.y = Number(this.hzqExtHome[i].y);
               }
               i++;
            }
            this.hzqExtMoved = false;
         }
         this.hzqExtBuildClips(box);
         this.hzqExtRaise();
      }
      // Extra slots are first-class Entry_13..Entry_24 in the same container as Entry_0..11 so
      // vanilla MOUSE_OVER / CLICK / SelectItem reach them. Keep them above the assign overlay.
      // Purpose: inventory assign and hover+Enter can pick 13-24. Inputs: none. Outputs: z-order.
      private function hzqExtRaise() : void
      {
         var i:int = 0;
         while(this.hzqExtSlots != null && i < this.hzqExtSlots.length)
         {
            var clip:MovieClip = this.hzqExtSlots[i].s as MovieClip;
            try { if(clip != null && clip.parent == this) { this.setChildIndex(clip,this.numChildren - 1); } } catch(eE:Error) { }
            i++;
         }
         if(this.hzqExtHold != null)
         {
            try { if(this.hzqExtHold.parent == this) { this.setChildIndex(this.hzqExtHold,this.numChildren - 1); } } catch(eZ:Error) { }
         }
         if(this.hzqRing != null)
         {
            try { if(this.hzqRing.parent == this) { this.setChildIndex(this.hzqRing,this.numChildren - 1); } } catch(eR:Error) { }
         }
         try
         {
            if(this.SelectQuickslot_mc != null)
            {
               this.SelectQuickslot_mc.mouseEnabled = false;
               this.SelectQuickslot_mc.mouseChildren = false;
            }
         }
         catch(eSq:Error) { }
         try
         {
            if(this.Vignette_mc != null)
            {
               this.Vignette_mc.mouseEnabled = false;
               this.Vignette_mc.mouseChildren = false;
            }
         }
         catch(eVg:Error) { }
         try
         {
            if(this.CenterClip_mc != null)
            {
               this.CenterClip_mc.mouseEnabled = false;
               this.CenterClip_mc.mouseChildren = false;
            }
         }
         catch(eCc:Error) { }
         try
         {
            if(this.AssignedItemIcon_mc != null)
            {
               this.AssignedItemIcon_mc.mouseEnabled = false;
               this.AssignedItemIcon_mc.mouseChildren = false;
            }
         }
         catch(eAi:Error) { }
      }
      // Native FavoritesEntry.MOUSE_OVER uses target.entryIndex (0 on a constructed clip). Read Entry_N's name instead.
      private function hzqExtMouse(e:Event) : Boolean
      {
         if(e == null || !this.hzqExtOn()) { return false; }
         var slot:int = this.hzqExtSlotOf(e.target);
         if(slot < 13) { return false; }
         this.hzqExtPick(slot,false);
         return true;
      }
      // Confirm the highlighted extra slot (assign or use). Never dispatches uQuickkeyIndex >= 12.
      // Returns true when vanilla SelectItem must not run (including a second Enter/click after success).
      private function hzqExtConfirm() : Boolean
      {
         if(!this.hzqExtOn()) { return false; }
         var slot:int = this.hzqExtSel;
         var idx:int = int(this.selectedIndex);
         if(idx >= 13 && idx <= 24) { slot = idx; }
         if(slot < 13) { return false; }
         if(this.hzqExtDone) { return true; }
         this.hzqExtPick(slot,true);
         return true;
      }
      // Keyboard arrows / Enter while FavoritesMenu is open. Returns true when vanilla must not run.
      private function hzqExtArrow(e:KeyboardEvent) : Boolean
      {
         if(e == null || !this.hzqExtOn()) { return false; }
         var dx:int = 0;
         var dy:int = 0;
         if(e.keyCode == Keyboard.LEFT) { dx = -1; }
         else if(e.keyCode == Keyboard.RIGHT) { dx = 1; }
         else if(e.keyCode == Keyboard.UP) { dy = -1; }
         else if(e.keyCode == Keyboard.DOWN) { dy = 1; }
         else { return false; }
         return this.hzqExtNav(dx,dy);
      }
      // Gamepad / mapped user events (Activate, D-pad names). param2 true = key down: ignore.
      private function hzqExtUser(name:String, down:Boolean) : Boolean
      {
         if(down || name == null || !this.hzqExtOn()) { return false; }
         var u:String = name.toUpperCase();
         if(u == "ACTIVATE" || u == "ACCEPT" || u == "OK") { return this.hzqExtConfirm(); }
         if(u == "LEFT") { return this.hzqExtNav(-1,0); }
         if(u == "RIGHT") { return this.hzqExtNav(1,0); }
         if(u == "UP") { return this.hzqExtNav(0,-1); }
         if(u == "DOWN") { return this.hzqExtNav(0,1); }
         return false;
      }
      // Move onto / around slots 13-24. Down from the T (or the last BARS vanilla row) lands on 13-N.
      // Up from the first extra row returns to vanilla 1-12. Left / right wrap in the extra row.
      private function hzqExtNav(dx:int, dy:int) : Boolean
      {
         var n:int = this.hzqExtCount();
         if(n <= 12) { return false; }
         var per:int = this.hzqExtPer();
         if(per < 1) { per = 6; }
         var bars:Boolean = this.hzqS != null && int(this.hzqS.ExtLayout) != 0;
         if(this.hzqExtSel >= 13)
         {
            var k:int = this.hzqExtSel - 13;
            var extN:int = n - 12;
            var col:int = k - int(Math.floor(k / per)) * per;
            var row:int = int(Math.floor(k / per));
            col += dx;
            row += dy;
            if(dx != 0)
            {
               var rowW:int = extN - row * per;
               if(rowW > per) { rowW = per; }
               if(rowW <= 0) { return true; }
               if(col < 0) { col = rowW - 1; }
               if(col >= rowW) { col = 0; }
               this.hzqExtPick(13 + row * per + col,false);
               return true;
            }
            if(row < 0)
            {
               this.hzqExtSel = 0;
               if(bars)
               {
                  var vIdx:int = 12 - per + (k - int(Math.floor(k / per)) * per);
                  if(vIdx < 0) { vIdx = 0; }
                  if(vIdx > 11) { vIdx = 11; }
                  this.selectedIndex = vIdx;
               }
               else { this.selectedIndex = 11; }
               this.hzqExtDraw();
               return true;
            }
            var next:int = 13 + row * per + col;
            if(next < 13 || next > n) { return true; }
            this.hzqExtPick(next,false);
            return true;
         }
         var idx:int = int(this.selectedIndex);
         if(idx < 0 || idx > 11) { return false; }
         if(dy <= 0) { return false; }
         if(bars)
         {
            var nextB:int = idx + per;
            if(nextB >= 12 && nextB < n)
            {
               this.hzqExtPick(nextB + 1,false);
               return true;
            }
            return false;
         }
         if(idx >= 9 && idx <= 11)
         {
            this.hzqExtPick(13,false);
            return true;
         }
         return false;
      }
      // Build once (hold, 12 slot clips, ADD tile), then every layout change only moves / shows / hides them.
      private function hzqExtEnsureClips() : void
      {
         if(this.hzqExtHold == null)
         {
            this.hzqExtHold = new Sprite();
            this.hzqExtHold.name = "hzqExtHold";
            this.addChild(this.hzqExtHold);
         }
         if(this.hzqExtPool == null)
         {
            this.hzqExtPool = [];
            this.hzqExtSlots = [];
            var q:int = 13;
            while(q <= 24) { this.hzqExtPool.push(this.hzqExtMake(q)); q++; }
         }
         if(this.hzqExtAdd == null)
         {
            var add:Sprite = new Sprite();
            add.name = "hzqExtAdd";
            add.mouseEnabled = true;
            add.mouseChildren = false;
            add.buttonMode = true;
            add.addEventListener(MouseEvent.CLICK,this.hzqExtAddClick);
            add.visible = false;
            this.hzqExtHold.addChild(add);
            this.hzqExtAdd = add;
         }
      }
      private function hzqExtBuildClips(box:Object) : void
      {
         this.hzqExtEnsureClips();
         var n:int = this.hzqExtCount();
         var per:int = this.hzqExtPer();
         var pitch:Number = HZQ_PITCH;
         var bars:Boolean = int(this.hzqS.ExtLayout) != 0;
         var extN:int = n > 12 ? n - 12 : 0;
         this.hzqExtSlots.length = 0;   // the active subset of the pool (array reused)
         var k:int = 0;
         while(k < 12)
         {
            var o:Object = this.hzqExtPool[k];
            var on:Boolean = k < extN;
            if(o.s.visible != on) { o.s.visible = on; }
            if(on)
            {
               var x:Number;
               var y:Number;
               if(bars)
               {
                  // BARS: 13-N continue the grid after slot 12
                  var idx0:int = 12 + k;
                  var rowB:int = int(Math.floor(idx0 / per));
                  var colB:int = idx0 - rowB * per;
                  var takeB:int = n - rowB * per;
                  if(takeB > per) { takeB = per; }
                  var rowsB:int = int(Math.ceil(n / per));
                  x = box.cx - (takeB - 1) * pitch / 2 + colB * pitch;
                  y = box.cy - (rowsB - 1) * pitch / 2 + rowB * pitch;
               }
               else
               {
                  // CROSS + BARS: rows of `per` under the T
                  var row:int = int(Math.floor(k / per));
                  var col:int = k - row * per;
                  var take:int = extN - row * per;
                  if(take > per) { take = per; }
                  x = box.cx - (take - 1) * pitch / 2 + col * pitch;
                  y = box.b + 12 + 29 + row * pitch;
               }
               if(o.s.x != x) { o.s.x = x; }
               if(o.s.y != y) { o.s.y = y; }
               o.x = x;
               o.y = y;
               this.hzqExtSlots.push(o);
            }
            k++;
         }
         var showAdd:Boolean = n < 24;
         if(this.hzqExtAdd.visible != showAdd) { this.hzqExtAdd.visible = showAdd; }
         if(showAdd)
         {
            var ax:Number = box.cx;
            var ay:Number = box.b + 12 + 29;
            if(bars)
            {
               var rowA:int = int(Math.floor(n / per));
               var colA:int = n - rowA * per;
               var rowsA:int = int(Math.ceil((n + 1) / per));
               ax = box.cx - ((n + 1 - rowA * per) - 1) * pitch / 2 + colA * pitch;
               ay = box.cy - (rowsA - 1) * pitch / 2 + rowA * pitch;
            }
            else if(this.hzqExtSlots.length > 0)
            {
               var last:Object = this.hzqExtSlots[this.hzqExtSlots.length - 1];
               if(extN % per == 0) { ax = box.cx - (Math.min(per,24 - n) - 1) * pitch / 2; ay = last.y + pitch; }
               else { ax = last.x + pitch; ay = last.y; }
            }
            if(this.hzqExtAdd.x != ax) { this.hzqExtAdd.x = ax; }
            if(this.hzqExtAdd.y != ay) { this.hzqExtAdd.y = ay; }
         }
      }
      private function hzqExtMake(slot:int) : Object
      {
         var s:MovieClip = null;
         try
         {
            var fe:FavoritesEntry = new FavoritesEntry();
            fe.name = "Entry_" + slot;
            s = fe;
         }
         catch(eFe:Error) { s = null; }
         if(s == null)
         {
            s = new MovieClip();
            s.name = "Entry_" + slot;
            s.entryIndex = slot;
         }
         s.mouseEnabled = true;
         s.mouseChildren = false;
         s.buttonMode = true;
         s.visible = false;
         // CLICK confirms once (hzqExtDone). ROLL_OVER highlights. Do not listen on MOUSE_DOWN:
         // that plus CLICK plus vanilla SelectItem was 2-3 assigns/uses per press.
         s.addEventListener(MouseEvent.CLICK,this.hzqExtClick,false,1,true);
         s.addEventListener(MouseEvent.ROLL_OVER,this.hzqExtOver,false,1,true);
         var card:Sprite = this.hzqSprite(s,0);
         card.name = "hzqCard";
         var k:TextField = this.hzqTf(card);
         var nm:TextField = this.hzqTf(card);
         this.addChild(s);
         this.hzqUnclip(s);
         this.hzqExtHideVan(s);
         try
         {
            s.graphics.beginFill(0,0.01);
            s.graphics.drawRect(-32,-32,64,64);
            s.graphics.endFill();
         }
         catch(eHit:Error) { }
         // c* = what is on screen now (change-driven draw)
         return {"s":s,"c":card,"k":k,"n":nm,"i":slot,"x":0,"y":0,"cSel":null,"cEmpty":null,"cLabel":null,"cKey":null};
      }
      private function hzqExtClick(e:MouseEvent) : void
      {
         try
         {
            if(e != null) { e.stopPropagation(); }
            var slot:int = this.hzqExtSlotOf(e != null ? e.currentTarget : null);
            if(slot <= 0) { return; }
            this.hzqExtPick(slot,true);
         }
         catch(err:Error) { }
      }
      private function hzqExtOver(e:MouseEvent) : void
      {
         try
         {
            var slot:int = this.hzqExtSlotOf(e != null ? e.currentTarget : null);
            if(slot <= 0) { return; }
            this.hzqExtPick(slot,false);
         }
         catch(err:Error) { }
      }
      private function hzqExtSlotOf(t:*) : int
      {
         while(t != null)
         {
            var got:int = this.hzqExtNameSlot(t.name);
            if(got >= 13) { return got; }
            try { t = t.parent; } catch(eP:Error) { t = null; }
         }
         return 0;
      }
      private function hzqExtNameSlot(nm:*) : int
      {
         if(nm == null) { return 0; }
         var s:String = String(nm);
         var n:int = 0;
         if(s.indexOf("Entry_") == 0) { n = int(Number(s.substring(6))); }
         else if(s.indexOf("hzqExt_") == 0) { n = int(Number(s.substring(7))); }
         if(n >= 13 && n <= 24) { return n; }
         return 0;
      }
      private function hzqExtAddClick(e:MouseEvent) : void
      {
         try
         {
            var n:int = this.hzqExtCount();
            if(n >= 24) { return; }
            this.hzqS.SlotCount = n + 1;
            this.hzqExtCmdSend("count",n + 1,"");
            this.hzqExtPlace();
            this.hzqExtDraw();
         }
         catch(err:Error) { }
      }
      private function hzqExtPick(slot:int, useIt:Boolean) : void
      {
         this.hzqExtPad();
         this.hzqExtSel = slot;
         var d:Object = this.hzqExtData[String(slot)];
         if(d != null)
         {
            this.hzqInfoSet({"sName":String(d.name != null ? d.name : ""),"uCount":d.count,"sAmmoName":"","uAmmoCount":0,"aElementalStats":null},true);
         }
         else { this.hzqInfoSet({"sName":"EMPTY","uCount":0},true); }
         // first-class index 13-24 so GetEntryClip / SelectItem see the extra entry; never send that index on AssignQuickkey
         if(slot >= 13 && slot <= 24)
         {
            try { if(int(this.selectedIndex) != slot) { this.selectedIndex = slot; } } catch(eIdx:Error) { }
         }
         else if(this.selectedIndex != 12)
         {
            try { this.selectedIndex = 12; } catch(eNone:Error) { }
         }
         this.hzqExtDraw();
         this.hzqRingDraw();
         if(useIt)
         {
            if(this.hzqExtDone) { return; }
            var assign:Boolean = false; try { assign = this.isAssigningItem(); } catch(eA:Error) { assign = this.AssignedItem != null && String(this.AssignedItem.sName != null ? this.AssignedItem.sName : "").length > 0; }
            var op:String = assign ? "assign" : "use";
            var extra:String = "";
            if(assign && this.AssignedItem != null)
            {
               // Hint only: the DLL prefers InventoryMenu's selected handle / FormID over this display name.
               var pw:Boolean = false; try { pw = this.AssignedItem.bIsPower == true; } catch(eP:Error) { }
               var fid:uint = this.hzqExtFormId(this.AssignedItem);
               extra = (pw ? "P|" : "I|") + (fid != 0 ? this.hzqExtHex(fid) + "|" : "") + String(this.AssignedItem.sName);
            }
            var res:String = this.hzqExtCmdSend(op,slot,extra);
            if(res != "ok")
            {
               // refused (power or Quantum Essence in 13-24, not found) or DLL not bound: stay open, say why
               var why:String = res == "power-later" ? "POWERS: USE SLOTS 1-12 FOR NOW" : (res == "essence-later" ? "QUANTUM ESSENCE: USE SLOTS 1-12 FOR NOW" : (res == "missing" ? "ITEM NOT FOUND IN INVENTORY" : "EXTENDED SLOTS UNAVAILABLE"));
               this.hzqInfoSet({"sName":why,"uCount":0,"sAmmoName":"","uAmmoCount":0,"aElementalStats":null},true);
               return;
            }
            this.hzqExtDone = true;
            if(assign)
            {
               this.hzqExtGot = false;
               this.hzqExtFetch();
               this.hzqExtDraw();
               this.hzqRingDraw();
            }
            try { this.StartClosingMenu(); } catch(eC:Error) { GlobalFunc.CloseMenu("FavoritesMenu"); }
         }
      }
      // Change-driven: a slot's art / text is touched only when its selection, empty / refuse state, label or key changed.
      private function hzqExtDraw() : void
      {
         if(!this.hzqExtOn() || this.hzqExtSlots == null) { return; }
         var i:int = 0;
         while(i < this.hzqExtSlots.length)
         {
            var o:Object = this.hzqExtSlots[i];
            var slot:int = int(o.i);
            var sel:Boolean = this.hzqExtSel == slot;
            var d:Object = this.hzqExtData[String(slot)];
            var refuse:Boolean = d != null && d.refuse === true && d.name != null && String(d.name).length > 0;
            var empty:Boolean = !refuse && (d == null || d.empty === true || d.name == null || String(d.name).length == 0);
            var dim:Boolean = empty || refuse;
            var key:String = "";
            if(this.hzqKb && this.hzqS != null && this.hzqS.Keys != null) { key = String(this.hzqS.Keys[slot - 13] != null ? this.hzqS.Keys[slot - 13] : ""); }
            try { this.hzqUnclip(o.s as DisplayObject); } catch(eUc:Error) { }
            try { this.hzqExtHideVan(o.s as MovieClip); } catch(eHv:Error) { }
            if(o.cSel !== sel || o.cEmpty !== empty || o.cRefuse !== refuse || o.cKey !== key)
            {
               var spr:Sprite = o.c != null ? o.c : o.s;
               var g:Graphics = spr.graphics;
               g.clear();
               var acc:uint = this.hzqAccent();
               this.hzqPanel(g,-29,-29,58,58,8,dim && !sel ? 0.6 : 1);
               if(sel)
               {
                  g.beginFill(acc,0.13);
                  g.drawRoundRect(-28,-28,56,56,14,14);
                  g.endFill();
               }
               if(key.length > 0)
               {
                  var klab:String = this.hzqExtKeyShort(key);
                  this.hzqSet(o.k,klab,13,sel ? this.hzqTextAccent() : this.hzqMutCol(),"sb",0.04,false);
                  this.hzqExtFit(o.k,klab,50);
                  var kw:Number = Math.max(16,Math.ceil(o.k.textWidth * 1.08) + 8);
                  var kh:Number = Math.max(16,Math.ceil(o.k.textHeight) + 3);
                  this.hzqKeycap(g,-24,-24,kw,kh,sel ? this.hzqIconCol(acc) : this.hzqDimCol());
                  o.k.x = -24 + (kw - o.k.width) / 2;
                  o.k.y = -24 + (kh - o.k.height) / 2;
                  if(!o.k.visible) { o.k.visible = true; }
               }
               else if(o.k.visible) { o.k.visible = false; }
            }
            var label:String = empty ? "EMPTY" : String(d.name);
            if(o.cLabel !== label || o.cEmpty !== empty || o.cRefuse !== refuse)
            {
               this.hzqSet(o.n,this.hzqUC(label),13,dim ? this.hzqDimCol() : this.hzqMainCol(),"rg",0.02,false);
               this.hzqExtFit(o.n,this.hzqUC(label),50);   // one line in the 58 px box, "..." when longer
               o.n.x = -26;
               o.n.y = 6;
            }
            o.cSel = sel;
            o.cEmpty = empty;
            o.cRefuse = refuse;
            o.cLabel = label;
            o.cKey = key;
            i++;
         }
         if(this.hzqExtAdd != null && !this.hzqExtAddDrawn)
         {
            // ADD tile art is static for the open: drawn once, same Horizon card panel as the slots
            var ag:Graphics = this.hzqExtAdd.graphics;
            ag.clear();
            this.hzqPanel(ag,-29,-29,58,58,8,0.6);
            var at:TextField = this.hzqTf(this.hzqExtAdd);
            this.hzqSet(at,"+",22,this.hzqTextAccent(),"rg",0,false);
            at.x = -12;
            at.y = -16;
            this.hzqExtAddDrawn = true;
         }
      }
      // Short forms for long navigation key names so the 58 px Extended badge does not overflow (N-a).
      private function hzqExtKeyShort(key:String) : String
      {
         var u:String = key.toUpperCase();
         if(u == "PAGEDOWN") { return "PGDN"; }
         if(u == "PAGEUP") { return "PGUP"; }
         if(u == "INSERT") { return "INS"; }
         if(u == "DELETE") { return "DEL"; }
         return key;
      }
      // One-line fit with "..." by halving (the scanner's pattern): about log2(length) layouts, only when a label changes.
      private function hzqExtFit(t:TextField, str:String, maxW:Number) : void
      {
         if(t.textWidth <= maxW || str.length <= 2) { return; }
         var f:TextFormat = t.defaultTextFormat;
         var lo:int = 2;
         var hi:int = str.length - 1;
         var best:int = 2;
         var cur:int = -1;
         while(lo <= hi)
         {
            var mid:int = (lo + hi) >> 1;
            t.text = str.substr(0,mid).replace(/\s+$/,"") + "...";
            t.setTextFormat(f);
            cur = mid;
            if(t.textWidth <= maxW) { best = mid; lo = mid + 1; }
            else { hi = mid - 1; }
         }
         if(cur != best) { t.text = str.substr(0,best).replace(/\s+$/,"") + "..."; t.setTextFormat(f); }
      }
      private function hzqExtApply(pay:String) : void
      {
         this.hzqExtData = {};
         if(pay == null || pay.length == 0) { return; }
         // header records m|<refused key mask> and c|<DLL slot count>, then 13|name|count|kind|empty|refuse;...
         var parts:Array = pay.split(";");
         var i:int = 0;
         while(i < parts.length)
         {
            var rec:String = String(parts[i]);
            if(rec.length > 0)
            {
               var f:Array = rec.split("|");
               if(f.length >= 1)
               {
                  if(String(f[0]) == "m") { this.hzqExtMask = f.length > 1 ? int(Number(f[1])) : 0; i++; continue; }
                  if(String(f[0]) == "c")
                  {
                     var dc:int = f.length > 1 ? int(Number(f[1])) : 0;
                     if(dc >= 12 && dc <= 24 && this.hzqS != null) { this.hzqS.SlotCount = dc; }
                     i++;
                     continue;
                  }
                  var slot:int = int(Number(f[0]));
                  this.hzqExtData[String(slot)] = {"name":f.length > 1 ? String(f[1]) : "","count":f.length > 2 ? Number(f[2]) : 0,"kind":f.length > 3 ? String(f[3]) : "inventory","empty":f.length > 4 ? String(f[4]) == "1" : (f.length <= 1 || String(f[1]).length == 0),"refuse":f.length > 5 && String(f[5]) == "1"};
               }
            }
            i++;
         }
      }
      private function hzqExtListen(on:Boolean) : void
      {
         if(on && !this.hzqExtKeyL)
         {
            this.stage.addEventListener(KeyboardEvent.KEY_UP,this.hzqExtKey,false,0,true);
            this.hzqExtKeyL = true;
         }
         else if(!on && this.hzqExtKeyL)
         {
            try { this.stage.removeEventListener(KeyboardEvent.KEY_UP,this.hzqExtKey); } catch(e:Error) { }
            this.hzqExtKeyL = false;
         }
      }
      private function hzqExtKey(e:KeyboardEvent) : void
      {
         try
         {
            if(!this.hzqExtOn() || e == null) { return; }
            var name:String = this.hzqExtKeyName(e.keyCode);
            if(name.length == 0 || this.hzqS == null || this.hzqS.Keys == null) { return; }
            var i:int = 0;
            while(i < 12)
            {
               if(String(this.hzqS.Keys[i]).toUpperCase() == name.toUpperCase())
               {
                  if((this.hzqExtMask >> i) & 1) { return; }   // N-4: the DLL refused this key
                  var slot:int = 13 + i;
                  if(slot <= this.hzqExtCount()) { this.hzqExtPick(slot,true); }
                  return;
               }
               i++;
            }
         }
         catch(err:Error) { }
      }
      private function hzqExtKeyName(code:uint) : String
      {
         if(code >= 112 && code <= 123) { return "F" + String(code - 111); }
         if(code >= 48 && code <= 57) { return String.fromCharCode(code); }
         if(code >= 65 && code <= 90) { return String.fromCharCode(code); }
         if(code == 45) { return "Insert"; }
         if(code == 36) { return "Home"; }
         if(code == 35) { return "End"; }
         if(code == 33) { return "PageUp"; }
         if(code == 34) { return "PageDown"; }
         return "";
      }
      // Hide FavoritesEntry timeline art on extra slots (outline, icon frame, Quickkey "1") so only the Horizon card shows.
      // Direct children only, at most 10, same cap as hzqHideArt. Selected/Unselected frames re-create those kids.
      private function hzqExtHideVan(e:MovieClip) : void
      {
         if(e == null) { return; }
         try { e.gotoAndStop("Unselected"); } catch(eUs:Error) { }
         var n:int = Math.min(e.numChildren,10);
         var i:int = 0;
         while(i < n)
         {
            var d:DisplayObject = e.getChildAt(i);
            if(d != null && d.name != "hzqCard") { d.visible = false; }
            i++;
         }
         try { var q:* = e["Quickkey_tf"]; if(q != null) { q.visible = false; q.alpha = 0; } } catch(eQ:Error) { }
         try { var ic:* = e["Icon_mc"]; if(ic != null) { ic.visible = false; } } catch(eI:Error) { }
      }
      private function hzqExtRestore() : void
      {
         this.hzqExtListen(false);
         this.hzqExtSel = 0;
         this.hzqExtDone = false;
         // Bypass the setter: GetEntryClip(13-24) is about to be removed (and is null after hzqFail).
         try { this._SelectedIndex = FS_NONE; } catch(eIdxR:Error) { }
         if(this.hzqExtMoved && this.hzqExtHome != null)
         {
            var i:int = 0;
            while(i < 12)
            {
               var e:MovieClip = this.hzqSlot(i);
               if(e != null && this.hzqExtHome[i] != null) { e.x = Number(this.hzqExtHome[i].x); e.y = Number(this.hzqExtHome[i].y); }
               i++;
            }
         }
         this.hzqExtMoved = false;
         try { if(this.CenterClip_mc != null) { this.CenterClip_mc.visible = true; } } catch(eCcR:Error) { }
         if(this.hzqExtPool != null)
         {
            var p:int = 0;
            while(p < this.hzqExtPool.length)
            {
               var clip:MovieClip = this.hzqExtPool[p] != null ? this.hzqExtPool[p].s as MovieClip : null;
               try { if(clip != null && clip.parent != null) { clip.parent.removeChild(clip); } } catch(eP:Error) { }
               p++;
            }
         }
         if(this.hzqExtHold != null)
         {
            try { if(this.hzqExtHold.parent != null) { this.hzqExtHold.parent.removeChild(this.hzqExtHold); } } catch(e:Error) { }
            this.hzqExtHold = null;
         }
         if(this.hzqRing != null)
         {
            try { this.hzqRing.graphics.clear(); if(this.hzqRing.parent != null) { this.hzqRing.parent.removeChild(this.hzqRing); } } catch(eRg:Error) { }
            this.hzqRing = null;
         }
         // off / error: release the pooled clips (their listeners go with them; nothing else holds them)
         this.hzqExtSlots = null;
         this.hzqExtPool = null;
         this.hzqExtAdd = null;
         this.hzqExtAddDrawn = false;
      }
      private function hzqFail() : void
      {
         this.hzqErr = true;
         try { this.hzqRestore(); } catch(e:Error) { }
      }
      // =================== v0.37 shared settings reader (hzq37) ===================
      // ONE helper, spliced into every movie that reads the settings (hudmenu + hudmenu_lrg as hz37, hudmessagesmenu
      // x2 as hzc37, dialoguemenu x2 as hzd37; generated from hzini_shared.as, so the copies are
      // identical apart from the prefix). It reads HorizonUI.default.ini, HorizonUI.user.ini, HorizonUI.state.ini and the
      // legacy HorizonUI.ini (paths relative to Data/Interface) one after the other and hands every waiting callback the
      // merged text: the defaults with user.ini laid over (hzq37Compose; mirrors HZF::Compose in HorizonUI.dll). A missing
      // file is normal: its IOErrorEvent is caught and counts as no file. The game logs every failed open, so
      // HorizonUI.ini is opened at most once, and only when Compose still needs that unshipped file.
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hzq37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hzq37_BOM:String = String.fromCharCode(0xFEFF);
      private var hzq37Ldr:URLLoader = null;
      private var hzq37Step:int = 0;          // 0 idle, n = reading hzq37_FILES[n - 1]
      private var hzq37T0:Number = 0;
      private var hzq37Got:Array = null;
      private var hzq37Q:Array = [];          // callbacks of the running read
      private var hzq37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private var hzq37Leg:String = null;     // last text of HorizonUI.ini, or null when that open missed
      private var hzq37LegTry:int = 0;        // 0 = not opened yet, 1 = opened once
      private function hzq37Ws(c:String) : Boolean { return c == " " || c == "\t" || c == "\r" || c == "\n"; }
      private function hzq37Trim(s:String) : String
      {
         var b:int = 0;
         var e:int = s.length;
         while(b < e && (this.hzq37Ws(s.charAt(b)) || s.charAt(b) == hzq37_BOM)) { b++; }
         while(e > b && this.hzq37Ws(s.charAt(e - 1))) { e--; }
         return s.substring(b,e);
      }
      private function hzq37Blank(s:String) : Boolean { return this.hzq37Trim(s).length == 0; }
      private function hzq37Lines(t:String) : Array
      {
         var out:Array = [];
         if(t == null || t.length == 0) { return out; }
         if(t.charAt(0) == hzq37_BOM) { t = t.substr(1); }
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
      private function hzq37Hdr(ln:String) : String
      {
         var t:String = this.hzq37Trim(ln);
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return this.hzq37Trim(t.substring(1,e)).toLowerCase();
      }
      private function hzq37Alias(n:String) : String
      {
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // key=value line -> {k: key lower case without blanks, o: key as written, v: value up to ';'}; null otherwise
      private function hzq37KV(ln:String) : Object
      {
         var t:String = this.hzq37Trim(ln);
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         var o:String = this.hzq37Trim(t.substr(0,eq));
         var k:String = o.split(" ").join("").split("\t").join("").toLowerCase();
         if(k.length == 0) { return null; }
         var v:String = t.substr(eq + 1);
         var sc:int = v.indexOf(";");
         if(sc >= 0) { v = v.substr(0,sc); }
         return {"k":k,"o":o,"v":this.hzq37Trim(v)};
      }
      // sections; a second copy / the pre-v0.31 name merges into the first, old names first so the new name wins
      private function hzq37Parse(t:String) : Object
      {
         var d:Object = {"secs":[{"n":"","raw":[],"order":[],"kv":{}}],"idx":{"s_":0}};
         var lines:Array = this.hzq37Lines(t);
         var pass:int = 0;
         while(pass < 2)
         {
            var cur:Object = d.secs[0];
            var old:Boolean = false;
            for each(var ln:String in lines)
            {
               var h:String = this.hzq37Hdr(ln);
               if(h != null)
               {
                  old = h == "cards v0.26" || h == "effects v0.26";
                  var n:String = this.hzq37Alias(h);
                  if((pass == 0) != old) { cur = null; continue; }
                  if(d.idx["s_" + n] == undefined) { d.idx["s_" + n] = d.secs.length; d.secs.push({"n":n,"raw":[],"order":[],"kv":{}}); }
                  cur = d.secs[int(d.idx["s_" + n])];
                  cur.raw.push(ln);
                  continue;
               }
               if(cur == null) { continue; }
               if(pass == 0 && cur.n == "") { continue; }
               cur.raw.push(ln);
               var kv:Object = this.hzq37KV(ln);
               if(kv == null) { continue; }
               if(cur.kv["k_" + kv.k] == undefined) { cur.order.push(kv.k); }
               cur.kv["k_" + kv.k] = [kv.o,kv.v];
            }
            pass++;
         }
         return d;
      }
      private function hzq37SecOf(d:Object, kl:String) : String
      {
         for each(var s:Object in d.secs) { if(s.n != "" && s.kv["k_" + kl] != undefined) { return String(s.n); } }
         return "";
      }
      private function hzq37Flush(out:Array, sec:String, U:Object, ext:Object, flushed:Object) : void
      {
         if(sec == "" || flushed["s_" + sec] == true) { return; }
         flushed["s_" + sec] = true;
         var e:Array = ext["s_" + sec];
         if(e == null || e.length == 0) { return; }
         var blanks:int = 0;
         while(out.length > 0 && this.hzq37Blank(String(out[out.length - 1]))) { out.pop(); blanks++; }
         for each(var k:String in e)
         {
            var p:Array = U["s_" + sec]["k_" + k];
            out.push(String(p[0]) + "=" + String(p[1]));
         }
         while(blanks > 0) { out.push(""); blanks--; }
      }
      // base with the player's values laid over it: known keys replace the base value in place, unknown keys of a known
      // section are appended to it, sections the base lacks are appended verbatim. CRLF out.
      private function hzq37Overlay(base:String, over:String) : String
      {
         var B:Object = this.hzq37Parse(base);
         var O:Object = this.hzq37Parse(over);
         var U:Object = {};
         var ext:Object = {};
         var unk:Array = [];
         for each(var s:Object in O.secs)
         {
            if(s.n != "" && B.idx["s_" + s.n] == undefined) { unk.push(s); continue; }
            for each(var kl:String in s.order)
            {
               var sec:String = s.n == "" ? this.hzq37SecOf(B,kl) : String(s.n);
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
         for each(var ln:String in this.hzq37Lines(base))
         {
            var h:String = this.hzq37Hdr(ln);
            if(h != null) { this.hzq37Flush(out,cur,U,ext,flushed); cur = this.hzq37Alias(h); out.push(ln); continue; }
            if(cur != "")
            {
               var kv:Object = this.hzq37KV(ln);
               if(kv != null && U["s_" + cur] != undefined && U["s_" + cur]["k_" + kv.k] != undefined)
               {
                  out.push(kv.o + "=" + String(U["s_" + cur]["k_" + kv.k][1]));
                  continue;
               }
            }
            out.push(ln);
         }
         this.hzq37Flush(out,cur,U,ext,flushed);
         for each(var us:Object in unk)
         {
            if(out.length > 0 && !this.hzq37Blank(String(out[out.length - 1]))) { out.push(""); }
            var r:Array = (us.raw as Array).concat();
            while(r.length > 0 && this.hzq37Blank(String(r[r.length - 1]))) { r.pop(); }
            for each(var rl:String in r) { out.push(rl); }
         }
         return out.length == 0 ? "" : out.join("\r\n") + "\r\n";
      }
      // def / user / state / legacy texts (null = file missing) -> the effective settings text, or null
      private function hzq37Compose(def:String, user:String, state:String, leg:String) : String
      {
         var hd:Boolean = def != null && def.length > 0;
         var hl:Boolean = leg != null && leg.length > 0;
         var base:String = hd ? def : (hl ? leg : null);
         var over:String = user != null ? user : (state == null && hd && hl ? leg : null);   // an old DLL still saves HorizonUI.ini
         if(base == null) { return over == null ? null : this.hzq37Overlay(over,""); }
         return this.hzq37Overlay(base,over != null ? over : "");
      }
      // read all four files, then cb(mergedText or null). Requests during a read get one fresh read afterwards.
      private function hzq37IniRead(cb:Function) : void
      {
         var now:Number = new Date().getTime();
         if(this.hzq37Step != 0 && now - this.hzq37T0 < 3000)
         {
            if(this.hzq37N.indexOf(cb) < 0) { this.hzq37N.push(cb); }
            return;
         }
         if(this.hzq37Step != 0 && this.hzq37Ldr != null) { try { this.hzq37Ldr.close(); } catch(e0:Error) { } }   // stuck: start over
         var q:Array = this.hzq37Step != 0 ? this.hzq37Q.concat(this.hzq37N) : [];
         this.hzq37N = [];
         if(q.indexOf(cb) < 0) { q.push(cb); }
         this.hzq37Q = q;
         this.hzq37Begin();
      }
      private function hzq37Begin() : void
      {
         this.hzq37Got = [null,null,null,null];
         this.hzq37T0 = new Date().getTime();
         this.hzq37Next(0);
      }
      private function hzq37IsLeg(i:int) : Boolean
      {
         if(i < 0 || i >= hzq37_FILES.length) { return false; }
         var pth:String = String(hzq37_FILES[i]);
         return pth.length >= 13 && pth.substr(pth.length - 13) == "HorizonUI.ini";
      }
      // HorizonUI.ini is not shipped. Skip it when Compose would ignore it, and open it only once when it would not.
      private function hzq37SkipLeg(i:int) : Boolean
      {
         if(!this.hzq37IsLeg(i)) { return false; }
         if(this.hzq37LegTry != 0) { return true; }
         var def:String = this.hzq37Got[0] == null ? null : String(this.hzq37Got[0]);
         var hd:Boolean = def != null && def.length > 0;
         if(hd && (this.hzq37Got[1] != null || this.hzq37Got[2] != null)) { return true; }
         return false;
      }
      private function hzq37Next(i:int) : void
      {
         this.hzq37Step = i + 1;
         if(i >= hzq37_FILES.length) { this.hzq37Ldr = null; this.hzq37Done(); return; }
         if(this.hzq37SkipLeg(i))
         {
            this.hzq37Got[i] = this.hzq37LegTry != 0 ? this.hzq37Leg : null;
            this.hzq37Next(i + 1);
            return;
         }
         try
         {
            this.hzq37Ldr = new URLLoader();
            this.hzq37Ldr.addEventListener(Event.COMPLETE,this.hzq37OnOk);
            this.hzq37Ldr.addEventListener(IOErrorEvent.IO_ERROR,this.hzq37OnErr);
            this.hzq37Ldr.addEventListener("securityError",this.hzq37OnErr);
            this.hzq37Ldr.load(new URLRequest(String(hzq37_FILES[i])));
         }
         catch(err:Error) { this.hzq37Next(i + 1); }
      }
      private function hzq37OnOk(e:Event) : void
      {
         if(e == null || e.target != this.hzq37Ldr) { return; }
         var i:int = this.hzq37Step - 1;
         try { this.hzq37Got[i] = String(this.hzq37Ldr.data); } catch(err:Error) { }
         if(this.hzq37IsLeg(i)) { this.hzq37Leg = this.hzq37Got[i] == null ? null : String(this.hzq37Got[i]); this.hzq37LegTry = 1; }
         this.hzq37Next(i + 1);
      }
      private function hzq37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hzq37Ldr) { return; }
         if(this.hzq37IsLeg(this.hzq37Step - 1)) { this.hzq37Leg = null; this.hzq37LegTry = 1; }
         this.hzq37Next(this.hzq37Step);   // missing file: counted once, not opened again
      }
      private function hzq37Done() : void
      {
         this.hzq37Step = 0;
         var g:Array = this.hzq37Got;
         var txt:String = null;
         try { txt = this.hzq37Compose(g[0],g[1],g[2],g[3]); } catch(errC:Error) { txt = null; }
         var cbs:Array = this.hzq37Q;
         this.hzq37Q = [];
         for each(var cb:Function in cbs) { try { cb(txt); } catch(errCb:Error) { } }
         if(this.hzq37N.length > 0 && this.hzq37Step == 0) { this.hzq37Q = this.hzq37N; this.hzq37N = []; this.hzq37Begin(); }
      }
      // =================== end shared settings reader ===================


      internal function frame13() : *
      {
         stop();
      }
      
      internal function frame18() : *
      {
         dispatchEvent(new Event("onFinishedClosingAnim",true,true));
         stop();
      }
      
      internal function frame21() : *
      {
         dispatchEvent(new Event("onFinishedClosingAnim",true,true));
         stop();
      }
   }
}

