package
{
   import Components.Icons.DynamicPoiIcon;
   import Shared.AS3.BSScrollingConfigParams;
   import Shared.AS3.BSScrollingContainer;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.Events.CustomEvent;
   import Shared.AS3.Events.ScrollingEvent;
   import Shared.AS3.IMenu;
   import Shared.Components.ButtonControls.ButtonBar.ButtonBar;
   import Shared.Components.ButtonControls.ButtonData.ButtonBaseData;
   import Shared.Components.ButtonControls.ButtonData.UserEventData;
   import Shared.Components.ButtonControls.Buttons.IButton;
   import Shared.EnumHelper;
   import Shared.GlobalFunc;
   import Shared.InventoryItemUtils;
   import Shared.MapMarkerUtils;
   import flash.display.DisplayObject;
   import flash.display.DisplayObjectContainer;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.events.TimerEvent;
   import flash.geom.ColorTransform;
   import flash.geom.Point;
   import flash.geom.Rectangle;
   import flash.text.TextField;
   import flash.utils.Timer;
   import scaleform.gfx.Extensions;
   import scaleform.gfx.TextFieldEx;
   import Components.PlanetInfoCard.TraitsIcon;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.IOErrorEvent;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.getTimer;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol379")]
   public class MonocleMenu extends IMenu
   {
      
      public var RightInfoDisplay_mc:MovieClip;
      
      public var TrackingDisplay_mc:MovieClip;
      
      public var PlanetInfo_mc:MovieClip;
      
      public var range_mc:MovieClip;
      
      public var MaxScannerRange_mc:MovieClip;
      
      public var ButtonBar_mc:ButtonBar;
      
      public var OuterCircle_mc:MovieClip;
      
      public var ScanMapMarkerHolder_mc:ScanMapMarkerHolder;
      
      public var NearbyPOIDisplay_mc:MovieClip;
      
      public var TraitIcon_mc:MovieClip;
      
      public var ResourceArc_mc:ResourceArc;
      
      public var Gradient_mc:MovieClip;
      
      private var isMenuOpening:Boolean = true;
      
      private var isMenuClosing:Boolean = false;
      
      private var bDoingSocialScan:Boolean = false;
      
      private var HarvestButtonData:ButtonBaseData;
      
      private var SocialScanButtonData:ButtonBaseData;
      
      private var BioscanButtonData:ButtonBaseData;
      
      private var OpenDoorButtonData:ButtonBaseData;
      
      private var ShowResourcesButtonData:ButtonBaseData;
      
      private var FastTravelButtonData:ButtonBaseData;
      
      private var SocialSpellButtonData:ButtonBaseData;
      
      private var PlaceBeaconButtonData:ButtonBaseData;
      
      private var PhotoModeButtonData:ButtonBaseData;
      
      private var SurfaceMapButtonData:ButtonBaseData;
      
      private var ZoomButtonData:ButtonBaseData;
      
      private var HiddenButtonData:ButtonBaseData;
      
      private var ContainerTakeData:ButtonBaseData;
      
      private var ContainerTransferData:ButtonBaseData;
      
      private const PICK_TYPE_NONE:int = EnumHelper.GetEnum(0);
      
      private const PICK_TYPE_RESOURCE:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_FLORA:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_FAUNA:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_NPC:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_OBJECT:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_MAP_MARKER:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_CONTAINER:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_LOOSE_ITEM:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_SPACESHIP:int = EnumHelper.GetEnum();
      
      private const PICK_TYPE_DOOR:int = EnumHelper.GetEnum();
      
      private const EVENT_TYPE_NONE:int = EnumHelper.GetEnum(0);
      
      private const EVENT_TYPE_TRAIT_DISCOVERED:int = EnumHelper.GetEnum();
      
      private const EVENT_TYPE_SCAN_FULLY_COMPLETE:int = EnumHelper.GetEnum();
      
      private const SOCIAL_TYPE_NONE:int = EnumHelper.GetEnum(0);
      
      private const SOCIAL_TYPE_NPC:int = EnumHelper.GetEnum();
      
      private const SOCIAL_TYPE_XENOSOCIAL:int = EnumHelper.GetEnum();
      
      private const SOCIAL_TYPE_HACK:int = EnumHelper.GetEnum();
      
      private const VIEW_CAST_TYPE_STANDARD:int = EnumHelper.GetEnum(0);
      
      private const VIEW_CAST_TYPE_HANDSCANNER:int = EnumHelper.GetEnum();
      
      private const NAME_MAX_LENGTH:* = 31;
      
      private var CurrentPickRefType:uint;
      
      private var CurrentViewCastType:uint;
      
      private var CurrentFormID:uint = 0;
      
      private var CurrentPickRefHandle:uint = 0;
      
      private var CurrentPOIName:String = "";
      
      private var PickRefIsScannable:Boolean = false;
      
      private var PickRefIsScanned:Boolean = false;
      
      private var CanFastTravel:Boolean = false;
      
      private var UseItemCard:Boolean = false;
      
      private var RolloverShowing:Boolean = false;
      
      private var CurrentUsePickFrameDelay:Boolean = false;
      
      private var FrameDelayPickRefData:FromClientDataEvent = null;
      
      private var FrameDelayCounter:uint = 0;
      
      private const PICK_FRAME_DELAY_LEN:uint = 5;
      
      private var SocialList_OrigCenterY:Number = 0;
      
      private var ResourceArcDisplayTimer:Timer;
      
      private var StoredSurveyPercent:Number = 0;
      
      private var LocationTraitRefsScanned:uint = 0;
      
      private var LocationTraitRefsRequired:uint = 0;
      
      private const START_CONTAINER_VIEW:String = "MonocleMenu_StartContainerView";
      
      private const STOP_CONTAINER_VIEW:String = "MonocleMenu_StopContainerView";
      
      private const USE_LIST_CONTROLS:String = "MonocleMenu_UseListScrollControls";
      
      private var bPickHasBounty:Boolean = false;
      
      private var bPickBountyAccepted:Boolean = false;
      
      private var bPreviousBountyAccepted:Boolean;
      
      public function MonocleMenu()
      {
         var configParams:BSScrollingConfigParams;
         var legendaryModConfigParams:BSScrollingConfigParams;
         this.HarvestButtonData = new ButtonBaseData("$HARVEST",new UserEventData("Scan",this.onHarvestPressed));
         this.SocialScanButtonData = new ButtonBaseData("$SOCIAL",new UserEventData("Scan",this.onSocialScan),false);
         this.BioscanButtonData = new ButtonBaseData("$BIOSCAN",new UserEventData("Scan",this.onBioscanPressed));
         this.OpenDoorButtonData = new ButtonBaseData("$Open",new UserEventData("Scan",this.onOpenDoorPressed));
         this.ShowResourcesButtonData = new ButtonBaseData("$SHOW_RESOURCES",new UserEventData("Scan",this.onShowResourcesPressed));
         this.FastTravelButtonData = new ButtonBaseData("$FastTravel",new UserEventData("Scan",this.onFastTravel));
         this.SocialSpellButtonData = new ButtonBaseData("$ACTIVATE",new UserEventData("Scan",this.onSocialSpellCast));
         this.PlaceBeaconButtonData = new ButtonBaseData("$OUTPOST",new UserEventData("PlaceBeacon",this.onPlaceBeacon));
         this.PhotoModeButtonData = new ButtonBaseData("$PHOTOMODE",new UserEventData("PhotoMode",this.onPhotoMode));
         this.SurfaceMapButtonData = new ButtonBaseData("$SURFACE MAP",new UserEventData("SurfaceMap",this.onSurfaceMap));
         this.ZoomButtonData = new ButtonBaseData("$ADJUST_ZOOM",[new UserEventData("ScrollListUp",this.onZoomIn),new UserEventData("ScrollListDown",this.onZoomOut),new UserEventData("ScannerZoomIn",this.onZoomIn),new UserEventData("ScannerZoomOut",this.onZoomOut)]);
         this.HiddenButtonData = new ButtonBaseData("",new UserEventData("",null),false,false);
         this.ContainerTakeData = new ButtonBaseData("$TAKE",new UserEventData("QCAButton",null));
         this.ContainerTransferData = new ButtonBaseData("$QuickContainerTransfer",new UserEventData("QCXButton",null));
         this.CurrentPickRefType = this.PICK_TYPE_NONE;
         this.CurrentViewCastType = this.VIEW_CAST_TYPE_STANDARD;
         this.ResourceArcDisplayTimer = new Timer(2000,1);
         this.bPreviousBountyAccepted = this.bPickBountyAccepted;
         super();
         addFrameScript(0,this.frame1,8,this.frame9,15,this.frame16,16,this.frame17,27,this.frame28);
         addEventListener("onOpenAnimComplete",this.onOpenAnimCompleteCallbk);
         addEventListener("onCloseAnimComplete",this.onCloseAnimCompleteCallbk);
         this.ResourceArcDisplayTimer.addEventListener(TimerEvent.TIMER_COMPLETE,this.onResourceDisplayTimerDone);
         this.ResourceArc_mc.addEventListener("ResourceArcClosed",this.onResourceCloseAnimComplete);
         Extensions.enabled = true;
         TextFieldEx.setTextAutoSize(this.RightInfoDisplay_mc.Resource_mc.element_mc.symbol_tf,TextFieldEx.TEXTAUTOSZ_SHRINK);
         this.PlanetInfo_mc.Trait1_mc.mouseEnabled = false;
         this.PlanetInfo_mc.Trait2_mc.mouseEnabled = false;
         this.PlanetInfo_mc.Trait3_mc.mouseEnabled = false;
         this.ButtonBar_mc.Initialize(ButtonBar.JUSTIFY_CENTER,15);
         this.ButtonBar_mc.SetBackgroundPadding(50,7);
         this.ButtonBar_mc.AddButtonWithData(this.AButton_mc,this.BioscanButtonData);
         this.ButtonBar_mc.AddButtonWithData(this.XButton_mc,this.PlaceBeaconButtonData);
         this.ButtonBar_mc.AddButtonWithData(this.SurfaceMapButton_mc,this.SurfaceMapButtonData);
         this.ButtonBar_mc.AddButtonWithData(this.PhotoModeButton_mc,this.PhotoModeButtonData);
         this.ButtonBar_mc.AddButtonWithData(this.ZoomButton_mc,this.ZoomButtonData);
         this.ButtonBar_mc.AddButtonWithData(this.BackButton_mc,new ButtonBaseData("$BACK",new UserEventData("Monocle",this.onCancelPressed)));
         this.ButtonBar_mc.RefreshButtons();
         configParams = new BSScrollingConfigParams();
         configParams.VerticalSpacing = 10;
         configParams.TextOption = TextFieldEx.TEXTAUTOSZ_SHRINK;
         configParams.EntryClassName = "SocialSkillListEntry";
         this.socialSpellList.Configure(configParams);
         this.socialSpellList.addEventListener(ScrollingEvent.ITEM_PRESS,this.onSocialSpellCast);
         this.SocialList_OrigCenterY = this.socialSpellList.y + this.socialSpellList.containerHeight / 2 + 15;
         this.socialSpellList.SetFilterComparitor(function(param1:Object):Boolean
         {
            return param1.bVisible === true;
         },false);
         legendaryModConfigParams = new BSScrollingConfigParams();
         legendaryModConfigParams.VerticalSpacing = 10;
         legendaryModConfigParams.TextOption = TextFieldEx.TEXTAUTOSZ_SHRINK;
         legendaryModConfigParams.EntryClassName = "LegendaryModListEntry";
         this.legendaryModList.Configure(legendaryModConfigParams);
         BSUIDataManager.Subscribe("MonocleMenuData",this.onMonocleDataUpdate);
         BSUIDataManager.Subscribe("MonocleMenuFreqData",this.onMonocleFreqDataUpdate);
         BSUIDataManager.Subscribe("MonoclePickRefData",this.onPickDataUpdate);
         BSUIDataManager.Subscribe("MonocleKnownResourcesData",this.onResourcesUpdate);
         BSUIDataManager.Subscribe("MonocleEventsData",this.onNewEvent);
         BSUIDataManager.Subscribe("FireForgetEventData",this.onFireForgetEvent);
         BSUIDataManager.Subscribe("HUDRolloverActivationData",this.onHUDActivationDataUpdate);
         try { this.hzsInit(); } catch(hzsErr:Error) { }
      }
      
      private function get AButton_mc() : IButton
      {
         return this.ButtonBar_mc.AButton_mc;
      }
      
      private function get XButton_mc() : IButton
      {
         return this.ButtonBar_mc.XButton_mc;
      }
      
      private function get PhotoModeButton_mc() : IButton
      {
         return this.ButtonBar_mc.PhotoModeButton_mc;
      }
      
      private function get SurfaceMapButton_mc() : IButton
      {
         return this.ButtonBar_mc.SurfaceMapButton_mc;
      }
      
      private function get ZoomButton_mc() : IButton
      {
         return this.ButtonBar_mc.ZoomButton_mc;
      }
      
      private function get BackButton_mc() : IButton
      {
         return this.ButtonBar_mc.BackButton_mc;
      }
      
      private function get socialSpellList() : BSScrollingContainer
      {
         return this.RightInfoDisplay_mc.Bioscan_mc.SocialList_mc;
      }
      
      private function get legendaryModList() : BSScrollingContainer
      {
         return this.RightInfoDisplay_mc.LegendaryModList_mc;
      }
      
      override protected function onSetSafeRect() : void
      {
         var _loc1_:Rectangle = Extensions.visibleRect;
         var _loc2_:Point = this.Gradient_mc.parent.globalToLocal(new Point(_loc1_.x,_loc1_.y));
         this.Gradient_mc.width = _loc1_.width;
         this.Gradient_mc.height = _loc1_.height;
         this.Gradient_mc.x = _loc2_.x;
         this.Gradient_mc.y = _loc2_.y;
      }
      
      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      {
         var _loc3_:Boolean = false;
         if(!this.isMenuClosing)
         {
            if(param1 != "QCAButton" && param1 != "QCXButton")
            {
               _loc3_ = this.ButtonBar_mc.ProcessUserEvent(param1,param2);
            }
            if(!_loc3_ && !param2)
            {
               switch(param1)
               {
                  case "Monocle":
                  case "Flashlight":
                  case "Cancel":
                  case "Pause":
                  case "DataMenu":
                     this.onCancelPressed();
                     _loc3_ = true;
                     break;
                  case "ScannerZoomIn":
                     if(stage.focus == this.socialSpellList)
                     {
                        this.socialSpellList.MoveSelection(-1);
                        _loc3_ = true;
                     }
                     break;
                  case "ScannerZoomOut":
                     if(stage.focus == this.socialSpellList)
                     {
                        this.socialSpellList.MoveSelection(1);
                        _loc3_ = true;
                     }
               }
            }
         }
         return _loc3_;
      }
      
      private function onHarvestPressed() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_Harvest"));
      }
      
      private function onBioscanPressed() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_Bioscan"));
      }
      
      private function onOpenDoorPressed() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_OpenDoor"));
      }
      
      private function onShowResourcesPressed() : void
      {
         if(!this.ResourceArc_mc.visible)
         {
            this.ShowResourceArcAnim();
         }
      }
      
      private function onSocialScan() : void
      {
         this.StartSocialScanMode();
      }
      
      private function get doingSocialScan() : Boolean
      {
         return this.bDoingSocialScan;
      }
      
      private function set doingSocialScan(param1:Boolean) : void
      {
         this.bDoingSocialScan = param1;
         this.UpdateButtonData();
      }
      
      private function StartSocialScanMode() : void
      {
         this.socialSpellList.y = this.SocialList_OrigCenterY - this.socialSpellList.itemsShown * this.socialSpellList.GetClipByIndex(0).height / 2;
         this.socialSpellList.visible = true;
         this.RightInfoDisplay_mc.gotoAndStop("Bioscan");
         this.doingSocialScan = true;
         this.socialSpellList.selectedIndex = 0;
         stage.focus = this.socialSpellList;
         (this.socialSpellList.parent as MovieClip).gotoAndPlay("SocialList");
         GlobalFunc.PlayMenuSound("UIMenuMonocleScannerNPCScanProcess");
         BSUIDataManager.dispatchCustomEvent(this.USE_LIST_CONTROLS,{"isShowing":true});
      }
      
      private function EndSocialScanMode() : void
      {
         if(this.bPickHasBounty)
         {
            this.RightInfoDisplay_mc.gotoAndStop("TrackingTarget");
         }
         this.doingSocialScan = false;
         stage.focus = null;
         this.socialSpellList.visible = false;
         (this.socialSpellList.parent as MovieClip).gotoAndPlay("Show");
         BSUIDataManager.dispatchCustomEvent(this.USE_LIST_CONTROLS,{"isShowing":false});
      }
      
      private function onSocialSpellCast() : void
      {
         if(this.socialSpellList.selectedEntry != null)
         {
            BSUIDataManager.dispatchCustomEvent("MonocleMenu_SocialSpell",{
               "selectedIndex":this.socialSpellList.selectedEntry.uSpellIndex,
               "isAvailable":this.socialSpellList.selectedEntry.bCastable
            });
         }
      }
      
      private function onCancelPressed() : void
      {
         if(this.doingSocialScan)
         {
            this.EndSocialScanMode();
         }
         else
         {
            this.doCloseMenu();
         }
      }
      
      private function doCloseMenu() : void
      {
         this.isMenuClosing = true;
         GlobalFunc.PlayMenuSound("UIMenuMonocleClose");
         if(this.CurrentPickRefType == this.PICK_TYPE_CONTAINER || this.CurrentPickRefType == this.PICK_TYPE_LOOSE_ITEM && this.UseItemCard)
         {
            BSUIDataManager.dispatchEvent(new Event(this.STOP_CONTAINER_VIEW));
         }
         gotoAndPlay("Close");
      }
      
      public function OnForceClose() : void
      {
         this.doCloseMenu();
      }
      
      private function onPlaceBeacon() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_Outpost"));
      }
      
      private function onSurfaceMap() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_SurfaceMap"));
         this.onCancelPressed();
      }
      
      private function onPhotoMode() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_PhotoMode"));
         this.onCancelPressed();
      }
      
      private function onZoomIn() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_ZoomIn"));
      }
      
      private function onZoomOut() : void
      {
         BSUIDataManager.dispatchEvent(new Event("MonocleMenu_ZoomOut"));
      }
      
      private function onOpenAnimCompleteCallbk() : void
      {
         this.isMenuOpening = false;
         if(this.CurrentPickRefType == this.PICK_TYPE_CONTAINER && this.CurrentViewCastType == this.VIEW_CAST_TYPE_STANDARD || this.CurrentPickRefType == this.PICK_TYPE_LOOSE_ITEM && this.UseItemCard)
         {
            BSUIDataManager.dispatchEvent(new Event(this.START_CONTAINER_VIEW));
         }
      }
      
      private function onCloseAnimCompleteCallbk() : void
      {
         GlobalFunc.CloseMenu("MonocleMenu");
      }
      
      private function processFrameDelayedPick() : void
      {
         ++this.FrameDelayCounter;
         if(this.FrameDelayCounter >= this.PICK_FRAME_DELAY_LEN)
         {
            this.onPickDataUpdate(this.FrameDelayPickRefData);
            this.FrameDelayPickRefData = null;
            this.FrameDelayCounter = 0;
            removeEventListener(Event.ENTER_FRAME,this.processFrameDelayedPick);
         }
      }
      
      private function onPickDataUpdate(param1:FromClientDataEvent) : void
      {
         var _loc6_:MovieClip = null;
         var _loc7_:int = 0;
         var _loc8_:Boolean = false;
         var _loc9_:Boolean = false;
         var _loc10_:Number = NaN;
         var _loc11_:Number = NaN;
         var _loc12_:Number = NaN;
         var _loc13_:* = undefined;
         var _loc14_:uint = 0;
         var _loc15_:DynamicPoiIcon = null;
         var _loc16_:uint = 0;
         if(this.CurrentUsePickFrameDelay && param1.data.uFormID != this.CurrentFormID && this.FrameDelayCounter < this.PICK_FRAME_DELAY_LEN)
         {
            if(this.FrameDelayPickRefData == null)
            {
               addEventListener(Event.ENTER_FRAME,this.processFrameDelayedPick);
            }
            this.FrameDelayPickRefData = param1;
            return;
         }
         if(this.FrameDelayPickRefData != null)
         {
            this.FrameDelayPickRefData = null;
            this.FrameDelayCounter = 0;
            removeEventListener(Event.ENTER_FRAME,this.processFrameDelayedPick);
         }
         var _loc2_:Boolean = param1.data.uFormID != this.CurrentFormID || param1.data.uPickRefType != this.CurrentPickRefType;
         var _loc3_:String = "";
         var _loc4_:String = this.BuildDescriptionString(param1.data);
         var _loc5_:uint = this.CurrentViewCastType;
         this.CurrentUsePickFrameDelay = param1.data.bShouldApplyPickFrameDelay;
         this.CurrentPickRefType = param1.data.uPickRefType;
         this.CurrentViewCastType = param1.data.uScanType;
         this.PickRefIsScannable = param1.data.bIsScannable;
         this.PickRefIsScanned = param1.data.bIsDiscovered;
         this.UseItemCard = param1.data.bUseItemCard;
         this.bPickHasBounty = param1.data.bHasBounty;
         this.bPickBountyAccepted = param1.data.bBountyAccepted;
         this.HarvestButtonData.sButtonText = param1.data.sHarvestableString;
         this.HarvestButtonData.bEnabled = param1.data.bIsHarvestable;
         this.BioscanButtonData.bEnabled = this.PickRefIsScannable && !this.PickRefIsScanned || Boolean(param1.data.bHasBounty) && !this.bPickBountyAccepted;
         this.OpenDoorButtonData.sButtonText = param1.data.sDoorText;
         if(param1.data.hasOwnProperty("aLegendaryMods") && param1.data.aLegendaryMods.length > 0)
         {
            this.legendaryModList.visible = true;
            this.legendaryModList.InitializeEntries(param1.data.aLegendaryMods);
         }
         else
         {
            this.legendaryModList.visible = false;
         }
         this.SocialScanButtonData.bEnabled = param1.data.bCanCastSocialSpells === true && (!param1.data.bHasBounty || this.bPickBountyAccepted);
         switch(param1.data.uSocialType)
         {
            case this.SOCIAL_TYPE_NPC:
               this.SocialScanButtonData.sButtonText = "$SOCIAL";
               break;
            case this.SOCIAL_TYPE_XENOSOCIAL:
               this.SocialScanButtonData.sButtonText = "$SOCIAL_XENO";
               break;
            case this.SOCIAL_TYPE_HACK:
               this.SocialScanButtonData.sButtonText = "$SOCIAL_ROBOT";
               break;
            default:
               this.SocialScanButtonData.sButtonText = "";
         }
         if(_loc2_ && param1.data.sSoundToPlay.length > 0)
         {
            GlobalFunc.PlayMenuSound(param1.data.sSoundToPlay);
         }
         _loc6_ = this.GetRightInfoInternalClip(param1.data.uPickRefType);
         if(_loc6_ != null)
         {
            switch(param1.data.uPickRefType)
            {
               case this.PICK_TYPE_RESOURCE:
                  _loc7_ = 20;
                  GlobalFunc.SetText(_loc6_.element_mc.symbol_tf,param1.data.sSymbol);
                  GlobalFunc.SetText(_loc6_.element_mc.name_tf,param1.data.sName,false,false,_loc7_);
                  GlobalFunc.SetText(_loc6_.description_mc.description_tf,_loc4_);
                  GlobalFunc.SetText(_loc6_.classification_mc.classification_tf,param1.data.sBioscanType);
                  _loc6_.Rarity_mc.gotoAndStop(param1.data.uScarcity + 1);
                  _loc6_.Tagged_mc.visible = param1.data.bIsTrackedForCrafting;
                  if(_loc2_)
                  {
                     _loc13_ = new ColorTransform();
                     _loc13_.color = param1.data.uColor;
                     _loc6_.color_mc.transform.colorTransform = _loc13_;
                  }
                  break;
               case this.PICK_TYPE_NPC:
                  if(param1.data.bHasBounty)
                  {
                     GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Temperment_tf,param1.data.sTemperment);
                     GlobalFunc.SetText(_loc6_.DisplayName_mc.Name_mc.Text_tf,param1.data.sName,false,true,this.NAME_MAX_LENGTH);
                     if(!param1.data.bBountyAccepted)
                     {
                        if(_loc2_ || this.bPreviousBountyAccepted != param1.data.bBountyAccepted)
                        {
                           this.bPreviousBountyAccepted = param1.data.bBountyAccepted;
                           this.RightInfoDisplay_mc.TrackingDisplay_mc.gotoAndPlay("ShowUnscanned");
                           GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Bounty_tf,"");
                           GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Crimes_tf,"");
                        }
                     }
                     else if(this.bPreviousBountyAccepted || this.bPreviousBountyAccepted != param1.data.bBountyAccepted)
                     {
                        this.bPreviousBountyAccepted = param1.data.bBountyAccepted;
                        this.RightInfoDisplay_mc.TrackingDisplay_mc.gotoAndPlay("Show");
                        GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Bounty_tf,param1.data.uBountyAmount);
                        GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Crimes_tf,param1.data.sCrimes);
                     }
                     break;
                  }
               case this.PICK_TYPE_FAUNA:
               case this.PICK_TYPE_FLORA:
               case this.PICK_TYPE_OBJECT:
               case this.PICK_TYPE_LOOSE_ITEM:
               case this.PICK_TYPE_CONTAINER:
               case this.PICK_TYPE_SPACESHIP:
               case this.PICK_TYPE_DOOR:
                  if(param1.data.uPickRefType == this.PICK_TYPE_FAUNA)
                  {
                     if(param1.data.bIsAlive === false)
                     {
                        _loc6_.DisplayName_mc.gotoAndStop("Dead");
                     }
                     else if(param1.data.bIsDiseased === true)
                     {
                        _loc6_.DisplayName_mc.gotoAndStop("Diseased");
                     }
                     else
                     {
                        _loc6_.DisplayName_mc.gotoAndStop("Alive");
                     }
                  }
                  else
                  {
                     _loc6_.DisplayName_mc.gotoAndStop(InventoryItemUtils.GetFrameLabelFromRarity(param1.data.uRarity));
                  }
                  GlobalFunc.SetText(_loc6_.DisplayName_mc.Name_mc.Text_tf,param1.data.sName,false,true,this.NAME_MAX_LENGTH);
                  _loc8_ = false;
                  _loc9_ = false;
                  if(param1.data.sBioscanType.length > 0)
                  {
                     GlobalFunc.SetText(_loc6_.TextHolder_mc.ScanObjectType_tf,param1.data.uScanTypeProgressPct + "% $$scanned\n$" + param1.data.sBioscanType);
                     _loc9_ = param1.data.uScanTypeProgressPct == 100;
                     _loc8_ = true;
                  }
                  else if(param1.data.uPickRefType == this.PICK_TYPE_OBJECT && this.LocationTraitRefsRequired > 0)
                  {
                     if(this.LocationTraitRefsScanned != this.LocationTraitRefsRequired)
                     {
                        GlobalFunc.SetText(_loc6_.TextHolder_mc.ScanObjectType_tf,this.LocationTraitRefsScanned + "/" + this.LocationTraitRefsRequired + " $$scanned");
                     }
                     else
                     {
                        GlobalFunc.SetText(_loc6_.TextHolder_mc.ScanObjectType_tf,"");
                        _loc9_ = true;
                     }
                     _loc8_ = true;
                  }
                  else if(Boolean(!this.bPickHasBounty) && Boolean(_loc6_.TextHolder_mc) && Boolean(_loc6_.TextHolder_mc.ScanObjectType_tf))
                  {
                     GlobalFunc.SetText(_loc6_.TextHolder_mc.ScanObjectType_tf,"");
                  }
                  if(Boolean(!this.bPickHasBounty) && Boolean(_loc6_.TextHolder_mc) && Boolean(_loc6_.TextHolder_mc.InfoTextHolder_mc))
                  {
                     this.CreateInfoTextClips(_loc6_.TextHolder_mc.InfoTextHolder_mc,param1.data.PickRefDetailsA);
                  }
                  _loc8_ ||= param1.data.PickRefDetailsA.length > 0;
                  this.RightInfoDisplay_mc.Bioscan_mc.Complete_mc.visible = _loc9_ && !this.doingSocialScan;
                  if(!_loc8_ && _loc6_.BG_mc.currentFrameLabel != "Hide")
                  {
                     _loc6_.BG_mc.gotoAndStop("Hide");
                  }
                  else if(_loc8_ && _loc6_.BG_mc.currentFrameLabel == "Hide")
                  {
                     if(Boolean(param1.data.bHasBounty) && !param1.data.bBountyAccepted)
                     {
                        _loc6_.BG_mc.gotoAndPlay("ShowUnscanned");
                     }
                     else
                     {
                        _loc6_.BG_mc.gotoAndPlay("Show");
                     }
                  }
                  _loc10_ = 12;
                  _loc11_ = 5;
                  _loc12_ = _loc6_.DisplayName_mc.Name_mc.x + _loc6_.DisplayName_mc.Name_mc.Text_tf.textWidth + _loc10_;
                  _loc6_.DisplayName_mc.Contraband_mc.visible = param1.data.bIsContraband;
                  _loc6_.DisplayName_mc.Stealing_mc.visible = !param1.data.bIsContraband && param1.data.bIsStealing;
                  _loc6_.DisplayName_mc.Tagged_mc.visible = param1.data.bIsTrackedForCrafting;
                  if(_loc6_.DisplayName_mc.Contraband_mc.visible)
                  {
                     _loc6_.DisplayName_mc.Contraband_mc.x = _loc12_;
                     _loc12_ += _loc6_.DisplayName_mc.Contraband_mc.width + _loc11_;
                  }
                  if(_loc6_.DisplayName_mc.Stealing_mc.visible)
                  {
                     _loc6_.DisplayName_mc.Stealing_mc.x = _loc12_;
                     _loc12_ += _loc6_.DisplayName_mc.Stealing_mc.width + _loc11_;
                  }
                  if(_loc6_.DisplayName_mc.Tagged_mc.visible)
                  {
                     _loc6_.DisplayName_mc.Tagged_mc.x = _loc12_;
                     _loc12_ += _loc6_.DisplayName_mc.Tagged_mc.width + _loc11_;
                  }
                  break;
               case this.PICK_TYPE_MAP_MARKER:
                  _loc14_ = 35;
                  GlobalFunc.SetText(_loc6_.description_mc.description_tf,_loc4_,false,false,_loc14_);
                  _loc15_ = (_loc6_.Icon_mc as ScanMapMarker).internalIcon;
                  _loc16_ = MapMarkerUtils.LMS_ONLY_TYPE_KNOWN;
                  if(Boolean(param1.data.bIsDiscovered) || !param1.data.bIsScannable)
                  {
                     _loc16_ = MapMarkerUtils.LMS_FULL_REVEAL;
                  }
                  if(_loc15_.locationType != param1.data.uMapMarkerType || _loc15_.locationState != _loc16_)
                  {
                     _loc15_.ClearLocation();
                     _loc15_.SetLocation(param1.data.uMapMarkerType,param1.data.uMapMarkerCategory,_loc16_);
                     _loc15_.SetFrame(param1.data.bIsDiscovered ? "Discovered" : "Undiscovered");
                  }
                  this.CanFastTravel = param1.data.bCanFastTravel === true;
            }
         }
         if(_loc2_)
         {
            if(this.doingSocialScan)
            {
               this.EndSocialScanMode();
            }
            this.SetRightInfoDisplayState(param1.data.uPickRefType,param1.data);
            if(!this.isMenuOpening && !this.isMenuClosing)
            {
               if(this.CurrentPickRefType == this.PICK_TYPE_CONTAINER && this.CurrentViewCastType == this.VIEW_CAST_TYPE_STANDARD || this.CurrentPickRefType == this.PICK_TYPE_LOOSE_ITEM && this.UseItemCard)
               {
                  BSUIDataManager.dispatchEvent(new Event(this.START_CONTAINER_VIEW));
               }
               else
               {
                  BSUIDataManager.dispatchEvent(new Event(this.STOP_CONTAINER_VIEW));
               }
            }
         }
         else if(this.CurrentViewCastType != _loc5_ && (this.CurrentPickRefType == this.PICK_TYPE_CONTAINER || this.CurrentPickRefType == this.PICK_TYPE_LOOSE_ITEM && this.UseItemCard))
         {
            if(!this.isMenuOpening && !this.isMenuClosing)
            {
               if(this.CurrentViewCastType == this.VIEW_CAST_TYPE_STANDARD || this.CurrentPickRefType == this.PICK_TYPE_LOOSE_ITEM && this.UseItemCard)
               {
                  BSUIDataManager.dispatchEvent(new Event(this.START_CONTAINER_VIEW));
               }
               else
               {
                  BSUIDataManager.dispatchEvent(new Event(this.STOP_CONTAINER_VIEW));
               }
            }
         }
         this.CurrentFormID = param1.data.uFormID;
         this.CurrentPickRefHandle = param1.data.uHandle;
         this.UpdateButtonData();
         this.hzsOnPickApplied(param1.data);
      }
      
      private function BuildDescriptionString(param1:Object) : String
      {
         var _loc4_:* = undefined;
         var _loc2_:String = "";
         var _loc3_:TextField = new TextField();
         for each(_loc4_ in param1.PickRefDetailsA)
         {
            if(_loc2_ != "")
            {
               _loc2_ += "\n";
            }
            _loc3_.text = _loc4_;
            _loc2_ += _loc3_.text;
         }
         return _loc2_;
      }
      
      private function CreateInfoTextClips(param1:DisplayObjectContainer, param2:Array) : void
      {
         var _loc7_:DisplayObject = null;
         var _loc8_:TextField = null;
         while(param1.numChildren < param2.length)
         {
            param1.addChild(new BioscanInfoTextEntry());
         }
         while(param1.numChildren > param2.length)
         {
            param1.removeChildAt(0);
         }
         var _loc3_:Number = 0;
         var _loc4_:Number = 5;
         var _loc5_:Number = 6;
         var _loc6_:uint = 0;
         while(_loc6_ < param2.length)
         {
            _loc7_ = param1.getChildAt(_loc6_);
            _loc8_ = _loc7_["Text_tf"];
            GlobalFunc.SetText(_loc8_,param2[_loc6_]);
            _loc8_.height = _loc8_.textHeight + _loc4_;
            _loc7_.y = _loc3_;
            _loc3_ += _loc7_.height + _loc5_;
            _loc6_++;
         }
      }
      
      private function UpdateButtonData() : void
      {
         if(this.doingSocialScan)
         {
            this.ButtonBar_mc.AButton_mc.SetButtonData(this.SocialSpellButtonData);
            this.ButtonBar_mc.XButton_mc.SetButtonData(this.HiddenButtonData);
            this.ButtonBar_mc.SurfaceMapButton_mc.SetButtonData(this.HiddenButtonData);
            this.ButtonBar_mc.PhotoModeButton_mc.SetButtonData(this.HiddenButtonData);
            this.ButtonBar_mc.ZoomButton_mc.SetButtonData(this.HiddenButtonData);
         }
         else
         {
            switch(this.CurrentPickRefType)
            {
               case this.PICK_TYPE_RESOURCE:
               case this.PICK_TYPE_FLORA:
                  if(this.HarvestButtonData.bEnabled)
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.HarvestButtonData);
                  }
                  else if(this.CurrentPickRefType == this.PICK_TYPE_RESOURCE)
                  {
                     if(this.ResourceArc_mc.visible === false && this.PickRefIsScanned)
                     {
                        this.ButtonBar_mc.AButton_mc.SetButtonData(this.ShowResourcesButtonData);
                     }
                     else
                     {
                        this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                     }
                  }
                  else
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                  }
                  this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
                  break;
               case this.PICK_TYPE_FAUNA:
                  if(this.SocialScanButtonData.sButtonText.length > 0 && !this.BioscanButtonData.bEnabled)
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.SocialScanButtonData);
                  }
                  else
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                  }
                  this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
                  break;
               case this.PICK_TYPE_OBJECT:
                  this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                  this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
                  break;
               case this.PICK_TYPE_MAP_MARKER:
                  if(this.CanFastTravel)
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.FastTravelButtonData);
                  }
                  else
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                  }
                  this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
                  break;
               case this.PICK_TYPE_LOOSE_ITEM:
                  if(this.UseItemCard && this.RolloverShowing)
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.ContainerTakeData);
                  }
                  else
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.HarvestButtonData);
                  }
                  this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
                  break;
               case this.PICK_TYPE_CONTAINER:
                  if(this.CurrentViewCastType == this.VIEW_CAST_TYPE_STANDARD && this.RolloverShowing)
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.ContainerTakeData);
                     this.ButtonBar_mc.XButton_mc.SetButtonData(this.ContainerTransferData);
                  }
                  else
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                     this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
                  }
                  break;
               case this.PICK_TYPE_NPC:
                  if(this.bPickHasBounty && !this.bPickBountyAccepted)
                  {
                     this.BioscanButtonData.bEnabled = true;
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                  }
                  else
                  {
                     this.ButtonBar_mc.AButton_mc.SetButtonData(this.SocialScanButtonData);
                  }
                  this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
                  break;
               case this.PICK_TYPE_DOOR:
                  this.ButtonBar_mc.AButton_mc.SetButtonData(this.OpenDoorButtonData);
                  break;
               default:
                  this.ButtonBar_mc.AButton_mc.SetButtonData(this.BioscanButtonData);
                  this.ButtonBar_mc.XButton_mc.SetButtonData(this.PlaceBeaconButtonData);
            }
            this.ButtonBar_mc.SurfaceMapButton_mc.SetButtonData(this.SurfaceMapButtonData);
            this.ButtonBar_mc.PhotoModeButton_mc.SetButtonData(this.PhotoModeButtonData);
            this.ButtonBar_mc.ZoomButton_mc.SetButtonData(this.ZoomButtonData);
         }
         this.ButtonBar_mc.RefreshButtons();
      }
      
      private function SetRightInfoDisplayState(param1:uint, param2:Object) : void
      {
         switch(param1)
         {
            case this.PICK_TYPE_NONE:
               this.RightInfoDisplay_mc.gotoAndStop("None");
               break;
            case this.PICK_TYPE_LOOSE_ITEM:
               if(this.UseItemCard)
               {
                  this.RightInfoDisplay_mc.gotoAndStop("None");
               }
               else
               {
                  this.RightInfoDisplay_mc.gotoAndStop("Bioscan");
                  this.RightInfoDisplay_mc.Bioscan_mc.gotoAndPlay("Show");
               }
               break;
            case this.PICK_TYPE_RESOURCE:
               this.RightInfoDisplay_mc.gotoAndStop("Resource");
               this.RightInfoDisplay_mc.Resource_mc.gotoAndPlay("Show");
               break;
            case this.PICK_TYPE_NPC:
               if(this.bPickHasBounty)
               {
                  this.RightInfoDisplay_mc.gotoAndStop("TrackingTarget");
                  if(this.RightInfoDisplay_mc.TrackingDisplay_mc)
                  {
                     if(!this.bPickBountyAccepted)
                     {
                        this.RightInfoDisplay_mc.TrackingDisplay_mc.gotoAndPlay("ShowUnscanned");
                        GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Bounty_tf,"");
                        GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Crimes_tf,"");
                     }
                     else
                     {
                        this.RightInfoDisplay_mc.TrackingDisplay_mc.gotoAndPlay("Show");
                        GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Bounty_tf,param2.uBountyAmount);
                        GlobalFunc.SetText(this.RightInfoDisplay_mc.TrackingDisplay_mc.TextHolder_mc.Crimes_tf,param2.sCrimes);
                     }
                  }
                  break;
               }
               if(this.RightInfoDisplay_mc.TrackingDisplay_mc)
               {
                  this.RightInfoDisplay_mc.TrackingDisplay_mc.gotoAndPlay(0);
               }
            case this.PICK_TYPE_FAUNA:
            case this.PICK_TYPE_FLORA:
            case this.PICK_TYPE_OBJECT:
            case this.PICK_TYPE_CONTAINER:
            case this.PICK_TYPE_SPACESHIP:
            case this.PICK_TYPE_DOOR:
               this.RightInfoDisplay_mc.gotoAndStop("Bioscan");
               this.RightInfoDisplay_mc.Bioscan_mc.gotoAndPlay("Show");
               break;
            case this.PICK_TYPE_MAP_MARKER:
               this.RightInfoDisplay_mc.gotoAndStop("MapMarker");
               this.RightInfoDisplay_mc.MapMarkerInfo_mc.gotoAndPlay("Show");
         }
      }
      
      private function GetRightInfoInternalClip(param1:uint) : MovieClip
      {
         var _loc2_:MovieClip = null;
         switch(param1)
         {
            case this.PICK_TYPE_RESOURCE:
               _loc2_ = this.RightInfoDisplay_mc.Resource_mc;
               break;
            case this.PICK_TYPE_LOOSE_ITEM:
               if(!this.UseItemCard)
               {
                  _loc2_ = this.RightInfoDisplay_mc.Bioscan_mc;
               }
               break;
            case this.PICK_TYPE_NPC:
               if(this.bPickHasBounty)
               {
                  _loc2_ = this.RightInfoDisplay_mc.TrackingDisplay_mc;
                  break;
               }
            case this.PICK_TYPE_FAUNA:
            case this.PICK_TYPE_FLORA:
            case this.PICK_TYPE_OBJECT:
            case this.PICK_TYPE_CONTAINER:
            case this.PICK_TYPE_SPACESHIP:
            case this.PICK_TYPE_DOOR:
               _loc2_ = this.RightInfoDisplay_mc.Bioscan_mc;
               break;
            case this.PICK_TYPE_MAP_MARKER:
               _loc2_ = this.RightInfoDisplay_mc.MapMarkerInfo_mc;
         }
         return _loc2_;
      }
      
      private function onMonocleDataUpdate(param1:FromClientDataEvent) : void
      {
         var updatedScannedTrait:*;
         var numOutposts:*;
         var newFrame:String = null;
         var getCurrFrame:Function = null;
         var MAX_TRAITS:uint = 0;
         var traitIdx:uint = 0;
         var traitClip:* = undefined;
         var currInfoClip:MovieClip = null;
         var arEvent:FromClientDataEvent = param1;
         if(arEvent.data.bShowPlanetInfo === false)
         {
            this.PlanetInfo_mc.visible = false;
         }
         else
         {
            this.PlanetInfo_mc.visible = true;
            GlobalFunc.SetText(this.PlanetInfo_mc.SurveyMeter_mc.Percent_tf,(arEvent.data.fSurveyPercentage * 100).toFixed(0) + "%");
            this.PlanetInfo_mc.SurveyMeter_mc.Meter_mc.Fill_mc.width = GlobalFunc.MapLinearlyToRange(0,this.PlanetInfo_mc.SurveyMeter_mc.Meter_mc.BG_mc.width,0,100,arEvent.data.fSurveyPercentage * 100,true);
            if(arEvent.data.fSurveyPercentage == 1)
            {
               if(this.StoredSurveyPercent != 0 && this.StoredSurveyPercent != arEvent.data.fSurveyPercentage)
               {
                  this.PlanetInfo_mc.SurveyedBanner_mc.gotoAndPlay("animStart");
               }
               else
               {
                  this.PlanetInfo_mc.SurveyedBanner_mc.gotoAndStop("shown");
               }
               this.PlanetInfo_mc.SurveyedBanner_mc.visible = true;
            }
            else
            {
               this.PlanetInfo_mc.SurveyedBanner_mc.visible = false;
            }
            this.StoredSurveyPercent = arEvent.data.fSurveyPercentage;
            newFrame = "Info_Resources";
            if(arEvent.data.uFaunaMax > 0 && arEvent.data.uFloraMax > 0)
            {
               newFrame = "Info_Fauna_Flora_Resources";
            }
            else if(arEvent.data.uFaunaMax > 0)
            {
               newFrame = "Info_Fauna_Resources";
            }
            else if(arEvent.data.uFloraMax > 0)
            {
               newFrame = "Info_Flora_Resources";
            }
            if(newFrame != this.PlanetInfo_mc.currentFrameLabel)
            {
               this.PlanetInfo_mc.gotoAndStop(newFrame);
            }
            getCurrFrame = function(param1:uint, param2:uint):String
            {
               return param1 == param2 ? "Complete" : "Standard";
            };
            newFrame = getCurrFrame(arEvent.data.uFaunaCurrent,arEvent.data.uFaunaMax);
            if(newFrame != this.PlanetInfo_mc.Fauna_mc.currentFrameLabel)
            {
               this.PlanetInfo_mc.Fauna_mc.gotoAndStop(newFrame);
            }
            newFrame = getCurrFrame(arEvent.data.uFloraCurrent,arEvent.data.uFloraMax);
            if(newFrame != this.PlanetInfo_mc.Flora_mc.currentFrameLabel)
            {
               this.PlanetInfo_mc.Flora_mc.gotoAndStop(newFrame);
            }
            newFrame = getCurrFrame(arEvent.data.uResourcesCurrent,arEvent.data.uResourcesMax);
            if(newFrame != this.PlanetInfo_mc.Resources_mc.currentFrameLabel)
            {
               this.PlanetInfo_mc.Resources_mc.gotoAndStop(newFrame);
            }
            this.PlanetInfo_mc.Fauna_mc.BiomeComplete_mc.visible = arEvent.data.bBiomeFaunaComplete === true;
            this.PlanetInfo_mc.Flora_mc.BiomeComplete_mc.visible = arEvent.data.bBiomeFloraComplete === true;
            GlobalFunc.SetText(this.PlanetInfo_mc.Fauna_mc.Value_mc.Text_tf,arEvent.data.uFaunaCurrent + "/" + arEvent.data.uFaunaMax);
            GlobalFunc.SetText(this.PlanetInfo_mc.Flora_mc.Value_mc.Text_tf,arEvent.data.uFloraCurrent + "/" + arEvent.data.uFloraMax);
            GlobalFunc.SetText(this.PlanetInfo_mc.Resources_mc.Value_mc.Text_tf,arEvent.data.uResourcesCurrent + "/" + arEvent.data.uResourcesMax);
            MAX_TRAITS = 5;
            traitIdx = 0;
            while(traitIdx < MAX_TRAITS)
            {
               traitClip = this.PlanetInfo_mc["Trait" + (traitIdx + 1) + "_mc"];
               if(traitClip != null)
               {
                  if(traitIdx < arEvent.data.aPlanetTraits.length)
                  {
                     traitClip.LoadIcon("",arEvent.data.aPlanetTraits[traitIdx]);
                     traitClip.visible = true;
                  }
                  else
                  {
                     traitClip.visible = false;
                  }
               }
               traitIdx++;
            }
         }
         GlobalFunc.SetText(this.MaxScannerRange_mc.Text_tf,"$$RANGE " + arEvent.data.uMaxScanDistance + "M");
         updatedScannedTrait = arEvent.data.uLocationTraitRefsScanned != this.LocationTraitRefsScanned;
         this.LocationTraitRefsScanned = arEvent.data.uLocationTraitRefsScanned;
         this.LocationTraitRefsRequired = arEvent.data.uLocationTraitRefsRequired;
         if(Boolean(updatedScannedTrait) && this.CurrentPickRefType == this.PICK_TYPE_OBJECT)
         {
            currInfoClip = this.GetRightInfoInternalClip(this.CurrentPickRefType);
            if(currInfoClip != null)
            {
               if(this.LocationTraitRefsScanned != this.LocationTraitRefsRequired)
               {
                  GlobalFunc.SetText(currInfoClip.TextHolder_mc.ScanObjectType_tf,this.LocationTraitRefsScanned + "/" + this.LocationTraitRefsRequired + " $$scanned");
               }
               else
               {
                  GlobalFunc.SetText(currInfoClip.TextHolder_mc.ScanObjectType_tf,"");
                  this.RightInfoDisplay_mc.Bioscan_mc.Complete_mc.visible = !this.bDoingSocialScan;
               }
            }
         }
         numOutposts = arEvent.data.uMaxOutposts - arEvent.data.uNumOutposts;
         this.PlaceBeaconButtonData.bEnabled = arEvent.data.bOutpostAllowed;
         this.PlaceBeaconButtonData.sButtonText = arEvent.data.bDecorateMode ? "$DECORATE" : "$$OUTPOST (" + numOutposts + ")";
         this.SurfaceMapButtonData.bEnabled = arEvent.data.bSurfaceMapAllowed;
         this.PhotoModeButtonData.bEnabled = arEvent.data.bPhotoModeAllowed;
         this.ZoomButtonData.bEnabled = arEvent.data.bScannerZoomAllowed;
         this.ZoomButtonData.bVisible = arEvent.data.bScannerZoomAllowed;
         this.UpdateButtonData();
         this.socialSpellList.InitializeEntries(arEvent.data.aSocialSpells);
      }
      
      private function onResourcesUpdate(param1:FromClientDataEvent) : void
      {
         this.ResourceArc_mc.SetResourceArcInfo(param1.data);
         if(param1.data.bShowArcOnUpdate === true)
         {
            this.ShowResourceArcAnim();
         }
      }
      
      private function ShowResourceArcAnim() : void
      {
         this.ResourceArc_mc.visible = true;
         this.ResourceArc_mc.Open();
         this.ResourceArcDisplayTimer.reset();
         this.ResourceArcDisplayTimer.start();
      }
      
      private function onFireForgetEvent(param1:FromClientDataEvent) : void
      {
         if(GlobalFunc.HasFireForgetEvent(param1.data,"MonocleMenu_OutpostOpening"))
         {
            this.onCancelPressed();
         }
      }
      
      private function onHUDActivationDataUpdate(param1:FromClientDataEvent) : void
      {
         if(param1.data.aButtons.length > 0 && Boolean(param1.data.aButtons[0].bPressAndRelease))
         {
            this.ContainerTakeData.sButtonText = param1.data.aButtons[0].sTextPressAndRelease;
            this.ContainerTakeData.bEnabled = param1.data.aButtons[0].bEnabled;
         }
         else
         {
            this.ContainerTakeData.sButtonText = "$TAKE";
            this.ContainerTakeData.bEnabled = false;
         }
         if(param1.data.aButtons.length > 1 && Boolean(param1.data.aButtons[1].bPressAndRelease))
         {
            this.ContainerTransferData.sButtonText = param1.data.aButtons[1].sTextPressAndRelease;
            this.ContainerTransferData.bEnabled = param1.data.aButtons[1].bEnabled;
         }
         else
         {
            this.ContainerTransferData.sButtonText = "$QuickContainerTransfer";
            this.ContainerTransferData.bEnabled = false;
         }
         this.RolloverShowing = param1.data.bShowRolloverActivation;
         this.UpdateButtonData();
      }
      
      private function onNewEvent(param1:FromClientDataEvent) : void
      {
         switch(param1.data.uType)
         {
            case this.EVENT_TYPE_SCAN_FULLY_COMPLETE:
               this.RightInfoDisplay_mc.Bioscan_mc.Complete_mc.gotoAndPlay("fadeIn");
         }
      }
      
      private function onResourceDisplayTimerDone() : void
      {
         this.ResourceArc_mc.Close();
      }
      
      private function onResourceCloseAnimComplete() : void
      {
         this.ResourceArc_mc.visible = false;
         this.UpdateButtonData();
      }
      
      private function onMonocleFreqDataUpdate(param1:FromClientDataEvent) : void
      {
         if(this.FrameDelayPickRefData == null)
         {
            if(param1.data.iScanDistance == -1)
            {
               GlobalFunc.SetText(this.range_mc.range_tf,"---");
            }
            else
            {
               GlobalFunc.SetText(this.range_mc.range_tf,param1.data.iScanDistance + "M");
            }
         }
         var _loc2_:String = param1.data.sCurrentNearbyMarker;
         if(_loc2_ != null && _loc2_ != this.CurrentPOIName)
         {
            this.CurrentPOIName = param1.data.sCurrentNearbyMarker;
            GlobalFunc.SetText(this.NearbyPOIDisplay_mc.location_mc.LocationName_tf,this.CurrentPOIName);
            if(this.CurrentPOIName.length > 0)
            {
               this.NearbyPOIDisplay_mc.gotoAndPlay("Show");
            }
            else
            {
               this.NearbyPOIDisplay_mc.gotoAndPlay("Hide");
            }
         }
         this.OuterCircle_mc.gotoAndStop("Distortion" + String(param1.data.uDistortionLevel));
      }
      
      private function onFastTravel() : void
      {
         BSUIDataManager.dispatchEvent(new CustomEvent("MonocleMenu_FastTravel",{"toRef":this.CurrentPickRefHandle}));
      }
      
      internal function frame1() : *
      {
      }
      
      internal function frame9() : *
      {
         BSUIDataManager.dispatchEvent(new CustomEvent("MonocleMenu_Initialize",{"width":this.getChildByName("OuterCircle_mc").width}));
         dispatchEvent(new Event("onOpenAnimComplete"));
         try { this.hzsOnOpened(); } catch(hzsErr9:Error) { }
      }
      
      internal function frame16() : *
      {
         stop();
      }
      
      internal function frame17() : *
      {
         BSUIDataManager.dispatchEvent(new CustomEvent("MonocleMenu_Shutdown",null));
      }
      
      internal function frame28() : *
      {
         stop();
         dispatchEvent(new Event("onCloseAnimComplete"));
      }


      // ===================== Horizon UI Scanner (monoclemenu) =====================
      // ORIGINAL CODE (Horizon UI) v0.41.0. apply_scanner_hooks.ps1 inserts this block into the game's own MonocleMenu
      // class (exported from the player's monoclemenu.swf on the PC); no game script text is stored in the kit.
      // The game's clips stay on stage and keep working: they are only made transparent (alpha 0, never removed), the
      // game's button bar keeps handling every key, and every dispatch / user event / close path is the game's own code.
      // Horizon draws its own panels from the same data providers. Settings: [Scanner] of HorizonUI.default.ini with
      // HorizonUI.user.ini laid over (the shared reader, prefix hzs37); read when the scanner opens and polled every
      // 2 s while it is open, so an F11 save (HzRev) applies without reopening.
      private static const HZS_VERSION:String = "0.42.0.9";   // 0.42.0.9: the scanner movie's build version (= the test build's DLL file version); bump here only
      private static const HZS_LRG:Boolean = false;
      private static const HZS_SCALE:Number = HZS_LRG ? 1.07 : 1;
      // design tokens 0.3.1 (exotic purple added in v0.40)
      private static const HZS_BG:uint = 0x0B1218;
      private static const HZS_ACC:uint = 0x3FD0E0;
      private static const HZS_TXT:uint = 0xF2F7F9;
      private static const HZS_WHITE:uint = 0xFFFFFF;
      private static const HZS_LABEL:uint = 0xC4D2D9;
      private static const HZS_MUTED:uint = 0x96A6AE;
      private static const HZS_DIM:uint = 0x8E9CA4;
      private static const HZS_AMB:uint = 0xF2A93B;
      private static const HZS_RED:uint = 0xFF5B5B;
      private static const HZS_GRN:uint = 0x5EE3A1;
      private static const HZS_O2B:uint = 0x4DB6FF;
      private static const HZS_EXOTIC:uint = 0xB48CFF;
      private static const HZS_VIO:uint = 0xB48CFF;    // v0.41.0: ships / vehicles that are not yours
      private static const HZS_QST:uint = 0xF2D35F;    // v0.41.0: the quest diamond (gold; the ship is blue)
      private static const HZS_MINPX:Number = 13;
      private static const HZS_KMIN:Number = 0.78;   // 0.42.0.4: smallest on-screen panel scale (text floored to 13 px after it; layouts fit from 0.76)
      private static const HZS_RING_FILL:Number = 0.004;   // v0.40.2: fill of an outline-only rounded rect (closes its path; invisible)
      private static const HZS_CARD_A:Number = 0.8;
      private static const HZS_CW:Number = 400;
      private static const HZS_PAD:Number = 18;
      private static const HZS_GAP:Number = 14;
      private static const HZS_R_CARD:Number = 18;
      private static const HZS_R_SMALL:Number = 16;
      private static const HZS_R_STRIP:Number = 14;
      private static const HZS_ACCENTS:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZS_RAR_N:Array = ["COMMON","UNCOMMON","RARE","EXOTIC","UNIQUE"];
      private static const HZS_RAR_K:Array = ["aCommonResources","aUncommonResources","aRareResources","aExoticResources","aUniqueResources"];
      private static const HZS_PANELS:Array = ["Planet","Bioscan","Signals","Traits","Compass","Mode","Hints"];
      private static const HZS_CMP_PANELS:Array = ["Planet","Bioscan","Signals","Traits","Compass"];
      // the game's clips Horizon draws over: alpha 0 every frame (visible / position / timeline untouched, never removed)
      private static const HZS_HIDE:Array = ["RightInfoDisplay_mc","PlanetInfo_mc","range_mc","MaxScannerRange_mc","ButtonBar_mc","NearbyPOIDisplay_mc","TraitIcon_mc","ResourceArc_mc","ScanMapMarkerHolder_mc","OuterCircle_mc"];
      // the game's button bar, in its own order (hints are mirrored from these, never hard-coded)
      private static const HZS_BTNS:Array = ["AButton_mc","XButton_mc","SurfaceMapButton_mc","PhotoModeButton_mc","ZoomButton_mc","BackButton_mc"];
      private static const HZS_SEMI:String = "$NB_Grotesk_Semibold";   // the game's own semibold face: run-time name only, never shown
      // [Scanner] keys: name, type (b 0/1, i int, f float, z size -1 or 0.60-1.60, p position -1 / L|R|C n / T|B|C n,
      // o optional -1 or min-max, s text), default, min, max. Same table and order as HorizonUI.default.ini.
      private static const HZS_KEYS:Array = [["ScanLayoutVersion","i",1,1,99],["ScanShowPlanet","b",1,0,1],["ScanShowBioscan","b",1,0,1],["ScanShowSignals","b",1,0,1],["ScanShowTraits","b",1,0,1],["ScanShowCompass","b",1,0,1],["ScanShowMode","b",1,0,1],["ScanShowHints","b",1,0,1],["ScanShowWorldTags","b",1,0,1],["ScanWorldMarkers","b",1,0,1],["ScanShowBodyType","b",0,0,1],["ScanShowShip","b",1,0,1],["ScanPlanetX","p","-1",0,0],["ScanPlanetY","p","-1",0,0],["ScanBioscanX","p","-1",0,0],["ScanBioscanY","p","-1",0,0],["ScanSignalsX","p","-1",0,0],["ScanSignalsY","p","-1",0,0],["ScanTraitsX","p","-1",0,0],["ScanTraitsY","p","-1",0,0],["ScanSocialX","p","-1",0,0],["ScanSocialY","p","-1",0,0],["ScanCompassX","p","-1",0,0],["ScanCompassY","p","-1",0,0],["ScanModeX","p","-1",0,0],["ScanModeY","p","-1",0,0],["ScanHintsX","p","-1",0,0],["ScanHintsY","p","-1",0,0],["ScanVitalsX","p","-1",0,0],["ScanVitalsY","p","-1",0,0],["ScanPlanetScale","z",-1,0.6,1.6],["ScanBioscanScale","z",-1,0.6,1.6],["ScanSignalsScale","z",-1,0.6,1.6],["ScanTraitsScale","z",-1,0.6,1.6],["ScanSocialScale","z",-1,0.6,1.6],["ScanCompassScale","z",-1,0.6,1.6],["ScanModeScale","z",-1,0.6,1.6],["ScanHintsScale","z",-1,0.6,1.6],["ScanWorldTagScale","z",-1,0.6,1.6],["ScanPlanetCompact","i",-1,-1,1],["ScanBioscanCompact","i",-1,-1,1],["ScanSignalsCompact","i",-1,-1,1],["ScanTraitsCompact","i",-1,-1,1],["ScanCompassCompact","i",-1,-1,1],["ScanCompactAll","i",-1,-1,1],["ScanOpacity","o",-1,0.2,1.6],["ScanAccent","i",-1,-1,13],["ScanAccentHex","s","",0,0],["ScanTextCase","i",-1,-1,1],["ScanFont","i",-1,-1,3],["ScanMargin","o",-1,20,200],["ScanUnits","i",0,0,1],["ScanMaxSignals","i",5,1,8],["ScanHazardWarn","i",50,5,95],["ScanHazardCrit","i",85,10,100],["ScanCompleteFlash","b",1,0,1],["ScanLeftToFind","b",1,0,1],["ScanMinRarity","i",0,0,4],["ScanNearestUnscanned","b",1,0,1],["HideMainHudWhileScanning","b",1,0,1],["ScanShowVitalsHealth","b",1,0,1],["ScanShowVitalsO2","b",1,0,1],["ScanShowVitalsBoost","b",1,0,1],["ScanVitalsCompact","b",0,0,1],["ScanVitalsLayout","i",0,0,1],["HideQuestPopupsWhileScanning","b",1,0,1],["DimTraitPopupDuringBioscan","b",0,0,1],["TraitPopupDim","f",0.4,0.1,0.9]];   // v0.41.0: = scanner_keys40 (the HUD has the same table)
      private static const HZS_MAX_INI:int = 65536;    // a settings file larger than 64 KB is ignored (defaults instead)
      private var hzsC:Object = null;       // [Scanner] values
      private var hzsS:Object = null;       // the [Style] / [Debug] values the scanner follows
      private var hzsTxt:String = null;     // last applied settings text
      private var hzsReading:Boolean = false;
      private var hzsReady:Boolean = false;
      private var hzsT0:int = 0;
      private var hzsPollT:int = 0;
      private var hzsL:Sprite = null;       // the Horizon layer (mouse off)
      private var hzsP:Object = {};         // panel sprites by name
      private var hzsSig:Object = {};       // last drawn signature by panel
      private var hzsDirty:Boolean = true;
      private var hzsVr:Rectangle = null;   // visible rect in layer units
      private var hzsVrSig:String = "";
      private var hzsMD:Object = null;      // MonocleMenuData
      private var hzsFD:Object = null;      // MonocleMenuFreqData
      private var hzsPD:Object = null;      // MonoclePickRefData as the provider holds it right now (r5: the world tag's live-pick check)
      private var hzsPA:Object = null;      // v0.40.2: a frozen copy of the pick the game APPLIED last (all pick drawing)
      private var hzsPAKey:String = "";     // v0.40.3: form | handle | type | bounty of the last pick drawn at once
      private var hzsRD:Object = null;      // MonocleKnownResourcesData
      private var hzsEnv:Object = null;     // LocalEnvironmentData
      private var hzsFx:Object = null;      // EnvironmentEffectsData
      private var hzsLoc:Object = null;     // HUDLocationData
      private var hzsEnvF:Object = null;    // LocalEnvData_Frequent
      private var hzsCmp:Object = null;     // HudCompassData
      private var hzsGot:Object = {};       // which providers arrived (hazards, compass)
      private var hzsFlashT:int = -100000;  // scan-complete flash start
      private var hzs41PT:int = -100000;    // v0.41.0: SHOW RESOURCES pulse start
      private var hzs41RA:Boolean = false;  // v0.41.0: ResourceArc_mc.visible last frame
      private var hzsHead:Number = NaN;
      private var hzsHeadDrawn:Number = NaN;
      private var hzsFontOk:Object = {};
      private var hzsGameFont:String = null;
      private var hzsFrame:int = 0;
      private var hzsFrameT:int = 0;
      private var hzsAlpha:Number = 0;
      private var hzsCfgSig:String = "";
      private var hzsTk:Number = 1;         // 0.42.0.4: scale of the panel being drawn (HZS_SCALE x hzsF); hzsFs keeps text >= 13 px after it

      // ---------------------------------------------------------------- start
      private function hzsInit() : void
      {
         this.hzsT0 = getTimer();
         this.hzsC = this.hzsDefaults();
         this.hzsS = {"HudScale":1,"CardOpacity":1,"AccentColor":0,"AccentHex":-1,"Margin":40,"Compact":0,"TextScale":1,"FontFace":1,"HeaderStyle":0,"ClockFormat":0};
         this.hzsL = new Sprite();
         this.hzsL.mouseEnabled = false;
         this.hzsL.mouseChildren = false;
         this.hzsL.visible = false;
         this.hzsL.alpha = 0;
         addChild(this.hzsL);
         for each(var n:String in ["Marks","Tag","Ret","Frame","Planet","Bioscan","Signals","Traits","Social","Compass","Head","Mode","Hints"])
         {
            var s:Sprite = new Sprite();
            s.mouseEnabled = false;
            s.mouseChildren = false;
            s.visible = false;
            this.hzsL.addChild(s);
            this.hzsP[n] = s;
         }
         this.hzsSub("MonocleMenuData",this.hzsOnMD);
         this.hzsSub("MonocleMenuFreqData",this.hzsOnFD);
         this.hzsSub("MonoclePickRefData",this.hzsOnPD);
         this.hzsSub("MonocleKnownResourcesData",this.hzsOnRD);
         this.hzsSub("MonocleEventsData",this.hzsOnEv);
         this.hzsSub("LocalEnvironmentData",this.hzsOnEnv);
         this.hzsSub("EnvironmentEffectsData",this.hzsOnFx);
         this.hzsSub("HUDLocationData",this.hzsOnLoc);
         this.hzsSub("LocalEnvData_Frequent",this.hzsOnEnvF);
         this.hzsSub("HudCompassData",this.hzsOnCmp);
         addEventListener(Event.ENTER_FRAME,this.hzsTick);
         this.hzsRead();
      }
      private function hzsSub(n:String, f:Function) : void
      {
         try { BSUIDataManager.Subscribe(n,f); } catch(e:Error) { }
      }
      // called by the hook in the game's open-complete frame: re-read the settings
      private function hzsOnOpened() : void
      {
         this.hzsRead();
      }
      private function hzsOnMD(e:FromClientDataEvent) : void { try { this.hzsMD = e.data; this.hzsGot.md = 1; this.hzsDirty = true; } catch(x:Error) { } }
      private function hzsOnFD(e:FromClientDataEvent) : void { try { this.hzsFD = e.data; this.hzsGot.fd = 1; } catch(x:Error) { } }
      private function hzsOnPD(e:FromClientDataEvent) : void { try { this.hzsPD = e.data; this.hzsGot.pd = 1; } catch(x:Error) { } }
      // v0.40.2: called by the hook at the very end of the game's onPickDataUpdate, i.e. only when the game has applied a pick
      // (its own 5-frame pick delay returns before that line). The provider object is reused for every update, so the
      // values are copied here (arrays too) and everything the pick drives is drawn now, from this copy.
      private function hzsOnPickApplied(d:Object) : void
      {
         try
         {
            if(d == null) { return; }
            var c:Object = {};
            for(var k:String in d) { var v:* = d[k]; c[k] = v is Array ? (v as Array).slice() : v; }
            if(c.uPickRefType === undefined) { c = d; }   // v0.40.3: a copy with nothing in it never blanks the pick panels
            this.hzsPA = c;
            this.hzsDirty = true;
            // v0.40.3: drawn at once only when the pick itself changes (form, handle, type, bounty); progress updates of the
            // same pick (bioscan %) are drawn by the regular tick
            var key:String = uint(c.uFormID) + "|" + uint(c.uHandle) + "|" + uint(c.uPickRefType) + "|" + (c.bHasBounty === true ? 1 : 0) + (c.bBountyAccepted === true ? 1 : 0);
            if(key == this.hzsPAKey) { return; }
            this.hzsPAKey = key;
            if(this.hzsReady && this.hzsVr != null && this.hzsL != null)
            {
               try { this.hzsDrawRet(); } catch(e1:Error) { }
               try { this.hzsDrawPanel("Social"); this.hzsDrawPanel("Traits"); this.hzsDrawPanel("Mode"); this.hzsDrawPanel("Hints"); this.hzsPlace(); } catch(e2:Error) { }
            }
         }
         catch(e0:*) { }   // the hook in the game's onPickDataUpdate is a plain call: nothing may escape (any thrown value)
      }
      private function hzsOnRD(e:FromClientDataEvent) : void { try { this.hzsRD = e.data; this.hzsGot.rd = 1; this.hzsDirty = true; } catch(x:Error) { } }
      private function hzsOnEnv(e:FromClientDataEvent) : void { try { this.hzsEnv = e.data; this.hzsGot.env = 1; this.hzsDirty = true; } catch(x:Error) { } }
      private function hzsOnFx(e:FromClientDataEvent) : void { try { this.hzsFx = e.data; this.hzsGot.fx = 1; this.hzsDirty = true; } catch(x:Error) { } }
      private function hzsOnLoc(e:FromClientDataEvent) : void { try { this.hzsLoc = e.data; this.hzsGot.loc = 1; this.hzsDirty = true; } catch(x:Error) { } }
      private function hzsOnEnvF(e:FromClientDataEvent) : void { try { this.hzsEnvF = e.data; this.hzsGot.envf = 1; } catch(x:Error) { } }
      private function hzsOnCmp(e:FromClientDataEvent) : void
      {
         try
         {
            this.hzsCmp = e.data;
            this.hzsGot.cmp = 1;
            var r:Number = Number(e.data.fDirection);
            if(!isNaN(r)) { var d:Number = (r * 180 / Math.PI) % 360; if(d < 0) { d += 360; } this.hzsHead = d; }
         }
         catch(x:Error) { }
      }
      // MonocleEventsData: the scan-complete type is the game's own enum (this.EVENT_TYPE_SCAN_FULLY_COMPLETE), never a number
      private function hzsOnEv(e:FromClientDataEvent) : void
      {
         try
         {
            this.hzsGot.ev = 1;
            if(e.data != null && uint(e.data.uType) == this.EVENT_TYPE_SCAN_FULLY_COMPLETE && int(this.hzsC.ScanCompleteFlash) == 1) { this.hzsFlashT = getTimer(); this.hzsDirty = true; }
         }
         catch(x:Error) { }
      }

      // ---------------------------------------------------------------- settings
      private function hzsDefaults() : Object
      {
         var o:Object = {};
         for each(var d:Array in HZS_KEYS) { o[d[0]] = d[2]; }
         return o;
      }
      private function hzsKeyDef(k:String) : Array
      {
         var kl:String = k.toLowerCase();
         for each(var d:Array in HZS_KEYS) { if(String(d[0]).toLowerCase() == kl) { return d; } }
         return null;
      }
      // one value through the parsing rules: NaN / unknown -> default, numbers clamped, bad hex / position -> default
      private function hzsClamp(d:Array, v:*) : *
      {
         var t:String = String(d[1]);
         var sv:String = v == null ? "" : String(v).replace(/^\s+|\s+$/g,"");
         if(t == "s")
         {
            if(sv.length == 0) { return ""; }
            return this.hzsHex(sv) >= 0 ? sv : String(d[2]);
         }
         if(t == "p")
         {
            if(sv.length < 2) { return "-1"; }
            var a:String = sv.charAt(0).toUpperCase();
            var isX:Boolean = String(d[0]).charAt(String(d[0]).length - 1) == "X";
            var okA:Boolean = isX ? (a == "L" || a == "R" || a == "C") : (a == "T" || a == "B" || a == "C");
            var dn:Number = Number(sv.substr(1).replace(/\s/g,""));
            if(!okA || isNaN(dn)) { return "-1"; }
            return a + String(int(Math.round(dn)));
         }
         var n:Number = Number(sv);
         if(sv.length == 0 || isNaN(n)) { return d[2]; }
         if(t == "b") { return n >= 0.5 ? 1 : 0; }
         if(t == "z") { if(n < 0) { return -1; } return Math.round(Math.max(0.6,Math.min(1.6,n)) * 1000) / 1000; }
         if(t == "o") { if(n < 0) { return -1; } n = Math.max(Number(d[3]),Math.min(Number(d[4]),n)); return Math.round(n * 1000) / 1000; }
         n = Math.max(Number(d[3]),Math.min(Number(d[4]),n));
         if(t == "i") { return int(Math.round(n)); }
         return Math.round(n * 1000) / 1000;
      }
      private function hzsHex(v:String) : int
      {
         if(v == null) { return -1; }
         v = v.replace(/^\s+|\s+$/g,"").replace("#","").replace("0x","").replace("0X","");
         if(v.length != 6 || !/^[0-9A-Fa-f]{6}$/.test(v)) { return -1; }
         return int(parseInt(v,16));
      }
      // settings text -> hzsC / hzsS. Section-aware; the last duplicate wins.
      private function hzsParse(txt:String) : void
      {
         var c:Object = this.hzsDefaults();
         var st:Object = {"HudScale":1,"CardOpacity":1,"AccentColor":0,"AccentHex":-1,"Margin":40,"Compact":0,"TextScale":1,"FontFace":1,"HeaderStyle":0,"ClockFormat":0};
         if(txt != null)
         {
            var sec:String = "";
            for each(var ln:String in this.hzs37Lines(txt))
            {
               var h:String = this.hzs37Hdr(ln);
               if(h != null) { sec = this.hzs37Alias(h); continue; }
               var kv:Object = this.hzs37KV(ln);
               if(kv == null) { continue; }
               var k:String = String(kv.k);
               var v:String = String(kv.v);
               var nv:Number = Number(v);
               if(sec == "scanner")
               {
                  var d:Array = this.hzsKeyDef(k);
                  if(d != null) { c[d[0]] = this.hzsClamp(d,v); }
               }
               else if(sec == "style")
               {
                  if(k == "hudscale" && !isNaN(nv)) { st.HudScale = Math.max(0.7,Math.min(1.4,nv)); }
                  else if(k == "cardopacity" && !isNaN(nv)) { st.CardOpacity = Math.max(0.2,Math.min(1.6,nv)); }
                  else if(k == "accentcolor" && !isNaN(nv)) { st.AccentColor = Math.max(0,Math.min(13,int(nv))); }
                  else if(k == "accenthex") { st.AccentHex = this.hzsHex(v); }
                  else if(k == "margin" && !isNaN(nv)) { st.Margin = Math.max(0,Math.min(400,nv)); }
                  else if(k == "compact") { st.Compact = (nv >= 0.5 || v.toLowerCase() == "true") ? 1 : 0; }
                  else if(k == "textscale" && !isNaN(nv)) { st.TextScale = Math.max(0.8,Math.min(1.3,nv)); }
                  else if(k == "fontface" && !isNaN(nv)) { st.FontFace = Math.max(0,Math.min(3,int(nv))); }
                  else if(k == "headerstyle" && !isNaN(nv)) { st.HeaderStyle = Math.max(0,Math.min(1,int(nv))); }
                  else if(k == "clockformat" && !isNaN(nv)) { st.ClockFormat = Math.max(0,Math.min(1,int(nv))); }
               }
            }
         }
         if(int(c.ScanHazardCrit) < int(c.ScanHazardWarn) + 5) { c.ScanHazardCrit = Math.min(100,int(c.ScanHazardWarn) + 5); }
         this.hzsC = c;
         this.hzsS = st;
      }
      private function hzsRead() : void
      {
         if(this.hzsReading) { return; }
         this.hzsReading = true;
         this.hzsPollT = getTimer();
         try { this.hzs37IniRead(this.hzsOnIni); } catch(e:Error) { this.hzsReading = false; }
      }
      private function hzsOnIni(txt:String) : void
      {
         this.hzsReading = false;
         try
         {
            // a file over 64 KB is ignored: compose again without it
            var g:Array = this.hzs37Got;
            if(g != null && g.length == 4)
            {
               var big:Boolean = false;
               var i:int = 0;
               while(i < 4) { if(g[i] != null && String(g[i]).length > HZS_MAX_INI) { g[i] = null; big = true; } i++; }
               if(big) { txt = this.hzs37Compose(g[0],g[1],g[2],g[3]); }
            }
            if(txt != this.hzsTxt || !this.hzsReady)
            {
               this.hzsTxt = txt;
               this.hzsParse(txt);
               this.hzsCfgSig = this.hzsSer(this.hzsC) + "|" + this.hzsSer(this.hzsS);
               this.hzsSig = {};
               this.hzsDirty = true;
            }
         }
         catch(e:Error) { }
         this.hzsReady = true;
      }

      // ---------------------------------------------------------------- frame tick
      private function hzsTick(e:Event) : void
      {
         this.hzsTk = 1;   // 0.42.0.4
         this.hzsFrame++;
         var now:int = getTimer();
         try { this.hzsHideVanilla(); } catch(e0:Error) { }
         try { var ra:Boolean = this.ResourceArc_mc != null && this.ResourceArc_mc.visible; if(ra && !this.hzs41RA) { this.hzs41PT = now; } this.hzs41RA = ra; } catch(e41:Error) { }   // v0.41.0 (SF-10)
         if(!this.hzsReady && now - this.hzsT0 > 300) { this.hzsReady = true; }   // no settings yet after 300 ms: defaults
         if(this.hzsReady && now - this.hzsPollT > 2000) { this.hzsRead(); }      // HzRev / any F11 save while open
         if(this.hzsL == null) { return; }
         // fade with the game's own open / close (the close animation ends in the game's CloseMenu call)
         var want:Number = this.isMenuClosing ? 0 : (this.hzsReady ? 1 : 0);
         this.hzsAlpha += (want - this.hzsAlpha) * (this.isMenuClosing ? 0.35 : 0.25);
         if(Math.abs(want - this.hzsAlpha) < 0.02) { this.hzsAlpha = want; }
         this.hzsL.alpha = this.hzsAlpha;
         this.hzsL.visible = this.hzsReady && this.hzsAlpha > 0.01;
         if(!this.hzsReady) { return; }
         try { this.hzsUpdVr(); } catch(e1:Error) { }
         if(this.hzsVr == null) { return; }
         if(this.hzsDirty || this.hzsFrame % 6 == 0)
         {
            this.hzsDirty = false;
            try { this.hzsDrawAll(); } catch(e2:Error) { }
         }
         try { this.hzsDrawCompassIfMoved(); } catch(e3:Error) { }
         try { this.hzsDrawMarks(); } catch(e4:Error) { }
         try { this.hzsDrawRet(); } catch(e5:Error) { }
         if(now - this.hzsFlashT < 2100) { try { this.hzsDrawPanel("Bioscan"); this.hzsPlace(); } catch(e6:Error) { } }
         // v0.41.0 SHOW RESOURCES pulse (r2, NIT-5): redrawn at 10 Hz, plus once when it has faded out (the clear frame)
         if(now - this.hzs41PT < 1500 && (this.hzsFrame % 6 == 0 || (now - this.hzs41PT >= 900 && this.hzs41PEnd != this.hzs41PT)))
         {
            if(now - this.hzs41PT >= 900) { this.hzs41PEnd = this.hzs41PT; }
            try { this.hzsDrawPanel("Traits"); this.hzsPlace(); } catch(e41p:Error) { }
         }
      }
      private function hzsHideVanilla() : void
      {
         for each(var n:String in HZS_HIDE)
         {
            var d:DisplayObject = null;
            try { d = this[n] as DisplayObject; } catch(e:Error) { d = null; }
            if(d != null && d.alpha != 0) { d.alpha = 0; }
         }
         // v0.40.1: the game's unnamed root pieces (reticle ring, cross lines, center dot, open-animation shapes) too.
         // Named clips (Gradient_mc, TrackingDisplay_mc, ...) and the Horizon layer are left alone; alpha only.
         var i:int = 0;
         while(i < numChildren)
         {
            var c:DisplayObject = getChildAt(i);
            if(c != null && c !== this.hzsL && c.name != null && c.name.indexOf("instance") == 0 && c.alpha != 0) { c.alpha = 0; }
            i++;
         }
      }
      // visible rect (the player's screen) in layer units
      private function hzsUpdVr() : void
      {
         var vr:Rectangle = Extensions.visibleRect;
         var tl:Point;
         var br:Point;
         if(vr != null && vr.width >= 100)
         {
            tl = this.hzsL.globalToLocal(new Point(vr.left,vr.top));
            br = this.hzsL.globalToLocal(new Point(vr.right,vr.bottom));
         }
         else
         {
            tl = this.hzsL.globalToLocal(new Point(0,0));
            br = this.hzsL.globalToLocal(new Point(1920,1080));
         }
         if(isNaN(tl.x) || br.x - tl.x < 100) { return; }
         var sig:String = Math.round(tl.x) + "," + Math.round(tl.y) + "," + Math.round(br.x) + "," + Math.round(br.y);
         if(sig != this.hzsVrSig) { this.hzsVrSig = sig; this.hzsVr = new Rectangle(tl.x,tl.y,br.x - tl.x,br.y - tl.y); this.hzsSig = {}; this.hzsDirty = true; }
      }

      // ---------------------------------------------------------------- look
      private function hzsAccent() : uint
      {
         var a:int = int(this.hzsC.ScanAccent);
         if(a == 13) { var hx:int = this.hzsHex(String(this.hzsC.ScanAccentHex)); if(hx >= 0) { return uint(hx); } a = -1; }
         if(a >= 0 && a < HZS_ACCENTS.length) { return uint(HZS_ACCENTS[a]); }
         var h:int = int(this.hzsS.AccentColor);
         if(h == 13 && int(this.hzsS.AccentHex) >= 0) { return uint(this.hzsS.AccentHex); }
         if(h >= 0 && h < HZS_ACCENTS.length) { return uint(HZS_ACCENTS[h]); }
         return HZS_ACC;
      }
      private function hzsOpacity() : Number
      {
         var o:Number = Number(this.hzsC.ScanOpacity);
         if(isNaN(o) || o < 0) { o = Number(this.hzsS.CardOpacity); }
         if(isNaN(o)) { o = 1; }
         var extra:Number = Math.max(0,Math.min(1,(o - 1) / 0.6));
         return Math.max(0,Math.min(1,HZS_CARD_A * Math.min(1,o) + (1 - HZS_CARD_A) * extra));
      }
      private function hzsMargin() : Number
      {
         var m:Number = Number(this.hzsC.ScanMargin);
         if(isNaN(m) || m < 0) { m = Number(this.hzsS.Margin); }
         return isNaN(m) ? 40 : m;
      }
      // panel size factor: -1 = [Style] HudScale. v0.40.3: 0.60 - 1.60 like the HUD cards. 0.42.0.4: a size below 1.00 still
      // shrinks the card, but no text goes under 13 px at 1080p (hzsFs floors the size after this factor, see hzsTk).
      private function hzsF(panel:String) : Number
      {
         var v:Number = Number(this.hzsC["Scan" + panel + "Scale"]);
         if(panel == "Social" && (isNaN(v) || v <= 0)) { v = Number(this.hzsC.ScanTraitsScale); }   // r5: -1 = the traits card's size
         if(isNaN(v) || v <= 0) { v = Number(this.hzsS.HudScale); }
         if(isNaN(v) || v <= 0) { v = 1; }
         return Math.max(0.6,v);   // v0.40.3: 0.60 - 1.60 like the HUD cards (0.42.0.4: text stays >= 13 px at 1080p, hzsFs)
      }
      private function hzsK(panel:String) : Number { return Math.max(HZS_KMIN,HZS_SCALE * this.hzsF(panel)); }   // 0.42.0.4: never under HZS_KMIN
      // compact form: the panel's own value, else ScanCompactAll, else [Style] Compact
      private function hzsCmpOn(panel:String) : Boolean
      {
         var v:int = int(this.hzsC["Scan" + panel + "Compact"]);
         if(v == 0 || v == 1) { return v == 1; }
         var a:int = int(this.hzsC.ScanCompactAll);
         if(a == 0 || a == 1) { return a == 1; }
         return int(this.hzsS.Compact) == 1;
      }
      private function hzsOn(k:String) : Boolean { return int(this.hzsC[k]) == 1; }
      private function hzsTitle() : Boolean
      {
         var t:int = int(this.hzsC.ScanTextCase);
         if(t == 0 || t == 1) { return t == 1; }
         return int(this.hzsS.HeaderStyle) == 1;
      }
      // Horizon's own labels (written in capitals) follow TEXT CASE; game strings are never re-cased to Title
      // v0.40.1: a duration the way the game's own skill list writes it (1h 5m 30s; zero parts left out)
      private function hzsDur(secs:int) : String
      {
         var h:int = int(secs / 3600);
         var m:int = int((secs % 3600) / 60);
         var s:int = secs % 60;
         var a:Array = [];
         if(h > 0) { a.push(h + this.hzsCs("h")); }
         if(m > 0) { a.push(m + this.hzsCs("m")); }
         if(s > 0) { a.push(s + this.hzsCs("s")); }
         return a.join(" ");
      }
      private function hzsCs(s:String) : String
      {
         if(!this.hzsTitle()) { return s.toUpperCase(); }
         var w:Array = s.toLowerCase().split(" ");
         var i:int = 0;
         while(i < w.length) { var x:String = String(w[i]); if(x.length > 0 && !/^(of|and|in|at|to)$/.test(x)) { w[i] = x.charAt(0).toUpperCase() + x.substr(1); } i++; }
         return w.join(" ");
      }
      private function hzsGs(s:String) : String
      {
         if(s == null) { return ""; }
         return this.hzsTitle() ? s : s.toUpperCase();
      }
      // a "$KEY" string through the game's translation table (a TextField resolves it), "" stays ""
      private function hzsTr(s:String) : String
      {
         if(s == null || s.length == 0) { return ""; }
         try { var t:TextField = new TextField(); GlobalFunc.SetText(t,s); return t.text; } catch(e:Error) { }
         return s;
      }
      private function hzsFace(w:String) : String
      {
         var f:int = int(this.hzsC.ScanFont);
         if(f < 0 || f > 3) { f = int(this.hzsS.FontFace); }
         var game:String = this.hzsGame();
         if(f == 3) { return this.hzsProbe(HZS_SEMI) ? HZS_SEMI : game; }
         if(f == 2)
         {
            var r:String = w == "rg" ? "$Horizon_Font_Alt_Regular" : (w == "bd" ? "$Horizon_Font_Alt_Bold" : "$Horizon_Font_Alt");
            if(this.hzsProbe(r)) { return r; }
            if(this.hzsProbe("$Horizon_Font_Alt")) { return "$Horizon_Font_Alt"; }
         }
         if(f == 1 || f == 2)
         {
            var x:String = w == "rg" ? "$Horizon_Font_Regular" : (w == "bd" ? "$Horizon_Font_Bold" : "$Horizon_Font");
            if(this.hzsProbe(x)) { return x; }
            if(this.hzsProbe("$Horizon_Font")) { return "$Horizon_Font"; }
         }
         return game;
      }
      private function hzsGame() : String
      {
         if(this.hzsGameFont != null) { return this.hzsGameFont; }
         var f:String = "$MAIN_Font";
         try { var t:TextField = this.range_mc.range_tf as TextField; if(t != null && t.getTextFormat().font) { f = String(t.getTextFormat().font); } } catch(e:Error) { }
         this.hzsGameFont = f;
         return f;
      }
      // a face counts only when it really renders glyphs (a missing face may silently fall back)
      private function hzsProbe(n:String) : Boolean
      {
         if(this.hzsFontOk[n] != undefined) { return this.hzsFontOk[n] == 1; }
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
               var b:TextField = new TextField();
               b.embedFonts = true;
               var bf:TextFormat = new TextFormat("$Horizon_NoSuchFace_x",20,0xFFFFFF);
               b.defaultTextFormat = bf; b.text = "WMW"; b.setTextFormat(bf);
               if(b.textWidth > 0 && Math.abs(b.textWidth - t.textWidth) < 0.01) { ok = false; }
            }
         }
         catch(err:Error) { ok = false; }
         this.hzsFontOk[n] = ok ? 1 : 0;
         return ok;
      }
      // text size at 1080p: TextScale applies, never under 13 px. 0.42.0.4: also never under 13 px AFTER the panel's scale
      // (hzsTk = HZS_SCALE x hzsF of the panel being drawn): the size is at least 13 / hzsTk, rounded up to 0.1
      private function hzsFs(size:Number) : Number
      {
         var ts:Number = Number(this.hzsS.TextScale);
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         var f:Number = Math.max(HZS_MINPX,Math.round(size * ts * 10) / 10);
         var k:Number = this.hzsTk;
         if(!isNaN(k) && k > 0 && k < 1) { f = Math.max(f,Math.ceil(HZS_MINPX / k * 10) / 10); }
         return f;
      }
      // one text field. (x, cy) = left / right / center x and the vertical middle; tr = tracking in em.
      // maxW > 0 shortens the text with "..." to fit. Returns the field (its right edge = x + width for "l").
      private function hzsT(p:Sprite, s:String, x:Number, cy:Number, size:Number, col:uint, w:String = "sb", tr:Number = 0, al:String = "l", a:Number = 1, maxW:Number = 0, font:String = null) : TextField
      {
         var t:TextField = new TextField();
         t.embedFonts = true;
         t.selectable = false;
         t.mouseEnabled = false;
         t.autoSize = TextFieldAutoSize.LEFT;
         var fs:Number = this.hzsFs(size);
         var f:TextFormat = new TextFormat(font != null ? font : this.hzsFace(w),fs,col);
         f.letterSpacing = Math.round(fs * tr * 10) / 10;
         t.defaultTextFormat = f;
         t.text = s == null ? "" : s;
         t.setTextFormat(f);
         if(maxW > 0 && t.textWidth > maxW && s != null && s.length > 1)
         {
            var n:int = s.length - 1;
            while(n > 1 && t.textWidth > maxW) { t.text = s.substr(0,n).replace(/\s+$/,"") + "..."; t.setTextFormat(f); n--; }
         }
         t.alpha = a;
         var tw:Number = t.textWidth;
         t.x = al == "r" ? Math.round(x - tw - 2) : (al == "c" ? Math.round(x - tw / 2 - 2) : Math.round(x - 2));
         t.y = Math.round(cy - t.height / 2);
         p.addChild(t);
         return t;
      }
      private function hzsTw(t:TextField) : Number { return t == null ? 0 : t.textWidth; }
      private function hzsRight(t:TextField) : Number { return t.x + 2 + t.textWidth; }
      // card: fill, 1 px edge ring, optional accent stripe at the left edge
      private function hzsCard(g:*, w:Number, h:Number, r:Number, stripe:int, ring:uint = 0xFFFFFF, ringA:Number = 0.1) : void
      {
         g.lineStyle(1,ring,ringA,true);
         g.beginFill(HZS_BG,this.hzsOpacity());
         g.drawRoundRect(0,0,w,h,r * 2,r * 2);
         g.endFill();
         g.lineStyle();
         if(stripe >= 0) { g.beginFill(uint(stripe),1); g.drawRoundRect(0,r * 0.9,3,h - r * 1.8,3,3); g.endFill(); }
      }
      private function hzsRR(g:*, x:Number, y:Number, w:Number, h:Number, r:Number, col:uint, a:Number) : void
      {
         g.beginFill(col,a); g.drawRoundRect(x,y,w,h,r * 2,r * 2); g.endFill();
      }
      private function hzsBar(g:*, x:Number, y:Number, w:Number, h:Number, p:Number, col:uint) : void
      {
         this.hzsRR(g,x,y,w,h,h / 2,0xFFFFFF,0.11);
         if(p > 0) { this.hzsRR(g,x,y,Math.max(h,w * Math.min(1,p)),h,h / 2,col,1); }
      }
      private function hzsSeg(g:*, x:Number, y:Number, w:Number, h:Number, n:int, p:Number, col:uint) : void
      {
         if(n <= 0) { return; }
         var gap:Number = n > 12 ? 1 : 3;
         var sw:Number = (w - gap * (n - 1)) / n;
         var k:int = int(Math.round(n * p));
         var i:int = 0;
         while(i < n) { this.hzsRR(g,x + i * (sw + gap),y,sw,h,Math.min(h / 2,sw / 2),i < k ? col : 0xFFFFFF,i < k ? 1 : 0.12); i++; }
      }
      // section header: label, thin rule, optional right text
      private function hzsSection(p:Sprite, x:Number, cy:Number, w:Number, label:String, right:String, col:uint) : void
      {
         var t:TextField = this.hzsT(p,this.hzsCs(label),x,cy,13,col,"sb",0.14);
         var rx:Number = x + w;
         if(right != null && right.length > 0) { var r:TextField = this.hzsT(p,right,x + w,cy,13,HZS_MUTED,"sb",0.06,"r"); rx = r.x; }
         var g:* = p.graphics;
         var e:Number = this.hzsRight(t) + 10;
         if(rx - 10 > e) { g.beginFill(0xFFFFFF,0.086); g.drawRect(e,cy + 0.5,rx - 10 - e,1); g.endFill(); }
      }
      private function hzsTile(g:*, cx:Number, cy:Number, r:Number, ring:uint, ra:Number) : void
      {
         g.lineStyle(1.2,ring,ra,true); g.beginFill(0xFFFFFF,0.047); g.drawCircle(cx,cy,r); g.endFill(); g.lineStyle();
      }
      private function hzsCheck(g:*, cx:Number, cy:Number, col:uint, k:Number = 1) : void
      {
         g.lineStyle(1.8,col,1,true,"normal","round"); g.moveTo(cx - 5 * k,cy); g.lineTo(cx - 1.5 * k,cy + 3.5 * k); g.lineTo(cx + 5 * k,cy - 4 * k); g.lineStyle();
      }
      private function hzsDash(g:*, cx:Number, cy:Number, col:uint) : void
      {
         g.lineStyle(1.8,col,1,true); g.moveTo(cx - 4,cy); g.lineTo(cx + 4,cy); g.lineStyle();
      }
      // original vector icons (drawn in code)
      private function hzsIcon(g:*, kind:String, cx:Number, cy:Number, col:uint, k:Number = 1) : void
      {
         var i:int = 0;
         if(kind == "planet")
         {
            g.lineStyle(1.6,col,1,true); g.drawCircle(cx,cy,9 * k); g.lineStyle();
            g.lineStyle(1.4,col,0.9,true); g.drawEllipse(cx - 17 * k,cy - 5 * k,34 * k,10 * k); g.lineStyle();
         }
         else if(kind == "fauna")
         {
            g.beginFill(col,1); g.drawCircle(cx,cy + 3,4); g.drawCircle(cx - 5,cy - 3,2); g.drawCircle(cx,cy - 6,2); g.drawCircle(cx + 5,cy - 3,2); g.endFill();
         }
         else if(kind == "flora")
         {
            g.lineStyle(1.4,col,1,true); g.moveTo(cx,cy - 7); g.lineTo(cx + 6,cy - 1); g.lineTo(cx,cy + 6); g.lineTo(cx - 6,cy - 1); g.lineTo(cx,cy - 7); g.moveTo(cx,cy - 4); g.lineTo(cx,cy + 8); g.lineStyle();
         }
         else if(kind == "rock")
         {
            g.lineStyle(1.2,col,1,true); g.beginFill(col,0.24); g.moveTo(cx - 7,cy + 5); g.lineTo(cx - 5,cy - 3); g.lineTo(cx,cy - 7); g.lineTo(cx + 6,cy - 3); g.lineTo(cx + 7,cy + 5); g.lineTo(cx - 7,cy + 5); g.endFill(); g.lineStyle();
         }
         else if(kind == "trait")
         {
            g.lineStyle(1.4,col,1,true); g.moveTo(cx,cy - 7 * k); g.lineTo(cx + 7 * k,cy); g.lineTo(cx,cy + 7 * k); g.lineTo(cx - 7 * k,cy); g.lineTo(cx,cy - 7 * k); g.lineStyle();
            g.beginFill(col,1); g.drawCircle(cx,cy,2 * k); g.endFill();
         }
         else if(kind == "hex")
         {
            g.lineStyle(1.4,col,1,true);
            while(i <= 6) { var an:Number = (60 * i + 30) * Math.PI / 180; var hx:Number = cx + 7 * k * Math.cos(an); var hy:Number = cy + 7 * k * Math.sin(an); if(i == 0) { g.moveTo(hx,hy); } else { g.lineTo(hx,hy); } i++; }
            g.lineStyle();
         }
         else if(kind == "cave")
         {
            g.lineStyle(1.6,col,1,true); g.moveTo(cx - 7,cy + 6); g.lineTo(cx - 7,cy); g.curveTo(cx - 7,cy - 7,cx,cy - 7); g.curveTo(cx + 7,cy - 7,cx + 7,cy); g.lineTo(cx + 7,cy + 6); g.moveTo(cx - 9,cy + 6); g.lineTo(cx + 9,cy + 6); g.lineStyle();
         }
         else if(kind == "struct")
         {
            g.lineStyle(1.5,col,1,true); g.moveTo(cx - 7,cy - 1); g.lineTo(cx,cy - 7); g.lineTo(cx + 7,cy - 1); g.drawRect(cx - 5,cy - 1,10,8); g.lineStyle();
         }
         else if(kind == "qdiamond")
         {
            // v0.41.0: the quest diamond, gold with a dark edge (reads apart from the blue ship)
            g.lineStyle(1.2,HZS_BG,0.9,true); g.beginFill(col,1); g.moveTo(cx,cy - 6.5 * k); g.lineTo(cx + 6.5 * k,cy); g.lineTo(cx,cy + 6.5 * k); g.lineTo(cx - 6.5 * k,cy); g.lineTo(cx,cy - 6.5 * k); g.endFill(); g.lineStyle();
         }
         else if(kind == "vehicle")
         {
            // v0.41.0: original rover outline (body, cab, two wheels)
            g.beginFill(col,1); g.drawRoundRect(cx - 8 * k,cy - 2 * k,16 * k,6 * k,3 * k,3 * k); g.drawRoundRect(cx - 3 * k,cy - 6 * k,8 * k,5 * k,2 * k,2 * k); g.endFill();
            g.beginFill(col,1); g.drawCircle(cx - 5 * k,cy + 5 * k,2.6 * k); g.drawCircle(cx + 5 * k,cy + 5 * k,2.6 * k); g.endFill();
         }
         else if(kind == "person")
         {
            // v0.41.0: companion (head + shoulders)
            g.beginFill(col,1); g.drawCircle(cx,cy - 3.5 * k,3.4 * k); g.endFill();
            g.beginFill(col,1); g.moveTo(cx - 7 * k,cy + 7 * k); g.curveTo(cx - 7 * k,cy + 0.5 * k,cx,cy + 0.5 * k); g.curveTo(cx + 7 * k,cy + 0.5 * k,cx + 7 * k,cy + 7 * k); g.lineTo(cx - 7 * k,cy + 7 * k); g.endFill();
         }
         else if(kind == "diamond")
         {
            g.beginFill(col,1); g.moveTo(cx,cy - 6 * k); g.lineTo(cx + 6 * k,cy); g.lineTo(cx,cy + 6 * k); g.lineTo(cx - 6 * k,cy); g.lineTo(cx,cy - 6 * k); g.endFill();
         }
         else if(kind == "ship")
         {
            // v0.40.2: the Horizon HUD compass ship (same outline, drawn 1.3 x)
            var q:Number = 1.3 * k;
            g.beginFill(col,1);
            g.moveTo(cx,cy - 6 * q); g.lineTo(cx + 2 * q,cy - 1.6 * q); g.lineTo(cx + 6 * q,cy + 1.4 * q); g.lineTo(cx + 6 * q,cy + 3 * q); g.lineTo(cx + 1.6 * q,cy + 2.2 * q); g.lineTo(cx + 1.2 * q,cy + 5 * q);
            g.lineTo(cx - 1.2 * q,cy + 5 * q); g.lineTo(cx - 1.6 * q,cy + 2.2 * q); g.lineTo(cx - 6 * q,cy + 3 * q); g.lineTo(cx - 6 * q,cy + 1.4 * q); g.lineTo(cx - 2 * q,cy - 1.6 * q); g.lineTo(cx,cy - 6 * q);
            g.endFill();
         }
         else if(kind == "thermal")
         {
            g.lineStyle(1.4,col,1,true); g.beginFill(col,HZS_RING_FILL); g.drawRoundRect(cx - 2.2,cy - 8,4.4,11,4,4); g.endFill(); g.lineStyle(); g.beginFill(col,1); g.drawCircle(cx,cy + 5,3.6); g.endFill();
         }
         else if(kind == "airborne")
         {
            g.lineStyle(1.6,col,1,true); g.moveTo(cx - 7,cy - 4); g.lineTo(cx + 5,cy - 4); g.moveTo(cx - 7,cy); g.lineTo(cx + 1,cy); g.moveTo(cx - 7,cy + 4); g.lineTo(cx + 4,cy + 4); g.lineStyle();
         }
         else if(kind == "radiation" || kind == "corrosive")
         {
            g.beginFill(col,1);
            while(i < 3)
            {
               var a0:Number = (-120 + i * 120) * Math.PI / 180;
               g.moveTo(cx + 3.6 * Math.cos(a0),cy + 3.6 * Math.sin(a0));
               g.lineTo(cx + 8 * Math.cos(a0),cy + 8 * Math.sin(a0));
               g.lineTo(cx + 8 * Math.cos(a0 + 1.05),cy + 8 * Math.sin(a0 + 1.05));
               g.lineTo(cx + 3.6 * Math.cos(a0 + 1.05),cy + 3.6 * Math.sin(a0 + 1.05));
               i++;
            }
            g.endFill();
            g.beginFill(col,1); g.drawCircle(cx,cy,1.8); g.endFill();
         }
         else
         {
            g.beginFill(col,1); g.drawCircle(cx,cy,3 * k); g.endFill();
         }
      }
      // keycap: 24 tall, at least 26 wide, radius 6, 1.5 px ring, accent fill 12 % (the Comms dialogue bar style)
      private function hzsKeycap(p:Sprite, x:Number, cy:Number, key:String, col:uint, dis:Boolean, font:String = null) : Number
      {
         var g:* = p.graphics;
         var ring:uint = dis ? HZS_MUTED : col;
         var t:TextField = this.hzsT(p,key,0,cy,13,ring,"bd",0.08,"l",dis ? 0.63 : 1,0,font);
         var w:Number = Math.max(26,Math.round(this.hzsTw(t) + 16));
         t.x = Math.round(x + (w - this.hzsTw(t)) / 2 - 2);
         // v0.40.2: ring and fill in ONE drawRoundRect. A stroke-only drawRoundRect loses its closing segment in the game's
         // renderer, which is the right edge (the shape starts and ends on it): the cut right border of every keycap.
         g.lineStyle(1.5,ring,dis ? 0.63 : 1,true); g.beginFill(dis ? 0xFFFFFF : col,dis ? 0.04 : 0.12); g.drawRoundRect(x,cy - 12,w,24,12,12); g.endFill(); g.lineStyle();
         return x + w;
      }
      private function hzsDist(m:Number) : String
      {
         if(isNaN(m) || m < 0) { return ""; }
         if(int(this.hzsC.ScanUnits) == 1 || m < 1000) { return String(int(Math.round(m))) + " m"; }
         return (Math.round(m / 100) / 10).toFixed(1) + " km";
      }
      private function hzsNum(n:Number) : String
      {
         var s:String = String(int(Math.round(Math.abs(n))));
         var o:String = "";
         while(s.length > 3) { o = "," + s.substr(s.length - 3) + o; s = s.substr(0,s.length - 3); }
         return (n < 0 ? "-" : "") + s + o;
      }
      private function hzsClr(p:Sprite) : void
      {
         while(p.numChildren > 0) { p.removeChildAt(0); }   // Horizon's own text fields only
         p.graphics.clear();
      }

      // ---------------------------------------------------------------- models (what each panel shows; null = hidden)
      private function hzsSer(o:*) : String
      {
         if(o == null) { return "~"; }
         if(o is Array) { var a:Array = []; for each(var x:* in o) { a.push(this.hzsSer(x)); } return "[" + a.join(",") + "]"; }
         if(typeof o == "object") { var b:Array = []; for(var k:String in o) { b.push(k + ":" + this.hzsSer(o[k])); } b.sort(); return "{" + b.join(",") + "}"; }
         return String(o);
      }
      private function hzsPick(d:Object, keys:Array) : String
      {
         if(d == null) { return null; }
         for each(var k:String in keys) { if(d[k] != undefined && d[k] != null && String(d[k]).length > 0) { return String(d[k]); } }
         return null;
      }
      private function hzsShowPlanetInfo() : Boolean { return this.hzsMD != null && this.hzsMD.bShowPlanetInfo !== false; }
      private function hzsHazWord(ic:String) : String
      {
         var li:String = ic.toLowerCase();
         if(li.indexOf("thermal") >= 0 || li.indexOf("heat") >= 0 || li.indexOf("cold") >= 0) { return "THERMAL"; }
         if(li.indexOf("radiation") >= 0) { return "RADIATION"; }
         if(li.indexOf("corrosive") >= 0) { return "CORROSIVE"; }
         if(li.indexOf("airborne") >= 0 || li.indexOf("toxic") >= 0) { return "AIRBORNE"; }
         return "HAZARD";
      }
      private function hzsHazards() : Array
      {
         var out:Array = [];
         if(this.hzsFx == null || !(this.hzsFx.aEnvironmentEffects is Array)) { return out; }
         var soak:Number = Number(this.hzsFx.fSoakDamagePct);
         if(isNaN(soak)) { soak = 0; }
         var seen:Object = {};
         for each(var ef:Object in this.hzsFx.aEnvironmentEffects)
         {
            var ic:String = ef != null && ef.sEffectIcon != null ? String(ef.sEffectIcon) : "";
            if(ic == "HazardEffect_RestoreSoak") { continue; }
            var w:String = this.hzsHazWord(ic);
            if(seen[w]) { continue; }
            seen[w] = true;
            var p:int = int(Math.round(Math.max(0,Math.min(1,soak)) * 100));
            out.push({"n":w,"ic":w.toLowerCase(),"p":p});
         }
         return out;
      }
      private function hzsHazCol(p:int) : uint
      {
         return p >= int(this.hzsC.ScanHazardCrit) ? HZS_RED : (p >= int(this.hzsC.ScanHazardWarn) ? HZS_AMB : HZS_GRN);
      }
      private function hzsClock(fr:Number, hpd:Number) : String
      {
         if(isNaN(fr) || isNaN(hpd) || hpd <= 0) { return ""; }
         var mins:int = int(Math.floor(Math.max(0,Math.min(0.99999,fr)) * 24 * 60));
         var h:int = int(mins / 60);
         var m:int = mins % 60;
         var mm:String = (m < 10 ? "0" : "") + m;
         if(int(this.hzsS.ClockFormat) == 1) { return (h < 10 ? "0" : "") + h + ":" + mm; }
         var ap:String = h >= 12 ? "PM" : "AM";
         var h12:int = h % 12;
         if(h12 == 0) { h12 = 12; }
         return h12 + ":" + mm + " " + ap;
      }
      private function hzsMPlanet() : Object
      {
         if(!this.hzsOn("ScanShowPlanet") || !this.hzsShowPlanetInfo()) { return null; }
         var md:Object = this.hzsMD;
         var env:Object = this.hzsEnv;
         var m:Object = {"cmp":this.hzsCmpOn("Planet")};
         var nm:String = this.hzsPick(env,["sBodyName","sLocationName"]);
         m.name = this.hzsGs(nm != null ? nm : this.hzsCs("SURVEY"));
         var sys:String = null;
         try { if(this.hzsLoc != null && this.hzsLoc.SystemBodyInfo != null) { sys = this.hzsPick(this.hzsLoc.SystemBodyInfo,["systemName","sSystemName"]); } } catch(e0:Error) { }
         if(sys == null) { sys = this.hzsPick(env,["sSystemName","sStarSystemName","sSystem","sStarName"]); }
         if(sys == nm) { sys = null; }
         var sub:String = sys != null ? this.hzsGs(sys) : "";
         if(this.hzsOn("ScanShowBodyType") && env != null && env.uBodyType != undefined)
         {
            var bn:Array = ["","STAR","PLANET","MOON","SATELLITE","ASTEROID BELT","STATION"];
            var bt:int = int(env.uBodyType);
            if(bt > 0 && bt < bn.length) { sub = (sub.length > 0 ? sub + "  " + String.fromCharCode(0xB7) + "  " : "") + this.hzsCs(bn[bt]); }
         }
         m.sys = sub;
         m.pct = int(Math.round(Math.max(0,Math.min(1,Number(md.fSurveyPercentage))) * 100));
         var cond:Array = [];
         var inShip:Boolean = env != null && Boolean(env.bInSpaceship) && !env.bIsLanded;
         if(env != null)
         {
            // v0.40.1: rounded; a row is left out when the game gives no number (never "NaN")
            var tv:Number = Number(env.fTemperature);
            var gv:Number = Number(env.fGravity);
            var ov:Number = Number(env.fOxygenPercent);
            if(inShip || !isNaN(tv)) { cond.push(["TEMPERATURE",inShip ? "--" : String(Math.round(tv)) + String.fromCharCode(0xB0)]); }
            if(inShip || !isNaN(gv)) { cond.push(["GRAVITY",inShip ? "--" : gv.toFixed(2) + " G"]); }
            if(inShip || !isNaN(ov)) { cond.push(["OXYGEN",inShip ? "--" : String(Math.round(ov)) + "%"]); }
         }
         if(md.uMaxScanDistance != undefined) { cond.push(["SCAN RANGE",String(int(md.uMaxScanDistance)) + " M"]); }
         var ef:Object = this.hzsEnvF;
         if(ef != null)
         {
            var hpd:Number = Number(ef.fLocalPlanetHoursPerDay);
            if(!isNaN(hpd) && hpd > 0)
            {
               cond.push(["DAY LENGTH",(Math.round(hpd * 10) / 10).toFixed(1) + " H"]);
               var clk:String = this.hzsClock(Number(ef.fLocalPlanetTime),hpd);
               if(clk.length > 0) { cond.push(["LOCAL TIME",clk]); }
            }
         }
         m.cond = cond;
         m.haz = this.hzsGot.fx == 1 ? this.hzsHazards() : null;
         return m;
      }
      private function hzsMBioscan() : Object
      {
         if(!this.hzsOn("ScanShowBioscan") || !this.hzsShowPlanetInfo()) { return null; }
         var md:Object = this.hzsMD;
         var rows:Array = [];
         if(int(md.uFaunaMax) > 0) { rows.push(["FAUNA","fauna",int(md.uFaunaCurrent),int(md.uFaunaMax)]); }
         if(int(md.uFloraMax) > 0) { rows.push(["FLORA","flora",int(md.uFloraCurrent),int(md.uFloraMax)]); }
         if(int(md.uResourcesMax) > 0) { rows.push(["RESOURCES","rock",int(md.uResourcesCurrent),int(md.uResourcesMax)]); }
         var tr:Array = this.hzsTraitState();
         if(tr[1] > 0) { rows.push(["TRAITS","trait",tr[0],tr[1]]); }
         if(rows.length == 0) { return null; }
         var tot:int = 0;
         var mx:int = 0;
         for each(var r:Array in rows) { tot += int(r[2]); mx += int(r[3]); }
         var left:Array = [];
         if(this.hzsOn("ScanLeftToFind"))
         {
            var lf:int = int(md.uFaunaMax) - int(md.uFaunaCurrent);
            var ll:int = int(md.uFloraMax) - int(md.uFloraCurrent);
            if(lf > 0) { left.push(lf + " " + this.hzsCs("FAUNA LEFT")); }
            if(ll > 0) { left.push(ll + " " + this.hzsCs("FLORA LEFT")); }
         }
         var fl:Number = 0;
         var dt:int = getTimer() - this.hzsFlashT;
         if(dt >= 0 && dt < 2000 && this.hzsOn("ScanCompleteFlash")) { fl = Math.round((1 - dt / 2000) * 10) / 10; }
         return {"cmp":this.hzsCmpOn("Bioscan"),"rows":rows,"tot":tot,"mx":mx,"left":left,"lt":this.hzsOn("ScanLeftToFind"),
            "allFF":(int(md.uFaunaMax) - int(md.uFaunaCurrent)) <= 0 && (int(md.uFloraMax) - int(md.uFloraCurrent)) <= 0,
            "bfl":md.bBiomeFloraComplete === true,"bfa":md.bBiomeFaunaComplete === true,"hasFl":int(md.uFloraMax) > 0,"hasFa":int(md.uFaunaMax) > 0,"fl":fl,
            "flc":int(md.uFloraCurrent),"fac":int(md.uFaunaCurrent)};
      }
      // v0.40.2: one biome line in plain words. The game's flag (bBiomeFloraComplete / bBiomeFaunaComplete, the same flags its
      // planet card shows as a check mark) means "every species of this kind that lives in the biome you stand in is
      // scanned". It is also set when the biome has none of that kind: with no species of it found on the planet yet, the
      // only way the flag can be set is an empty biome, so that case says so.
      private function hzsBiomeWord(done:Boolean, foundOnPlanet:int) : String
      {
         if(!done) { return this.hzsCs("still some to find here"); }
         return foundOnPlanet <= 0 ? this.hzsCs("none in this biome") : this.hzsCs("nothing left to find here");
      }
      // [known, total] planet traits (the game's own unknown value, TraitsIcon.TRAIT_UNKNOWN)
      private function hzsTraitState() : Array
      {
         var k:int = 0;
         var n:int = 0;
         try
         {
            if(this.hzsMD != null && this.hzsMD.aPlanetTraits is Array)
            {
               for each(var t:* in this.hzsMD.aPlanetTraits) { n++; if(int(t) != TraitsIcon.TRAIT_UNKNOWN) { k++; } }
            }
         }
         catch(e:Error) { }
         return [k,n];
      }
      private function hzsMarkIcon(o:Object) : String
      {
         try
         {
            if(uint(o.uLocationMarkerState) == MapMarkerUtils.LMS_UNKNOWN) { return "hex"; }
            if(o.uType != undefined && uint(o.uType) == MapMarkerUtils.MARKER_VEHICLE) { return "vehicle"; }   // v0.41.0
            var c:uint = uint(o.uCategory);
            if(c == MapMarkerUtils.MARKER_TYPE_LANDMARK) { return "cave"; }
            if(c == MapMarkerUtils.MARKER_TYPE_STRUCTURE || c == MapMarkerUtils.MARKER_TYPE_SIMPLE || c == MapMarkerUtils.MARKER_TYPE_STATION) { return "struct"; }
            if(c == MapMarkerUtils.MARKER_TYPE_LIFE_SIGNS) { return "fauna"; }
            if(c == MapMarkerUtils.MARKER_TYPE_HAZARD) { return "radiation"; }
            if(c == MapMarkerUtils.MARKER_TYPE_SHIP) { return "ship"; }
         }
         catch(e:Error) { }
         return "hex";
      }
      private function hzsMarkName(o:Object) : String
      {
         try
         {
            if(uint(o.uLocationMarkerState) == MapMarkerUtils.LMS_UNKNOWN) { return this.hzsCs("UNKNOWN SIGNAL"); }
            if(o.uType != undefined && o.uType !== null && uint(o.uType) == MapMarkerUtils.MARKER_VEHICLE) { return this.hzsCs("VEHICLE"); }   // r3: the game has no generic vehicle name
            var s:String = this.hzsTr(MapMarkerUtils.GetGenericTypeLocString(uint(o.uCategory)));
            if(s != null && s.length > 0 && s.charAt(0) != "$") { return this.hzsGs(s); }
         }
         catch(e:Error) { }
         return this.hzsCs("SIGNAL");
      }
      private function hzsMarkers() : Array
      {
         var a:Array = [];
         if(this.hzsFD == null || !(this.hzsFD.aScannableMarkers is Array)) { return a; }
         for each(var o:Object in this.hzsFD.aScannableMarkers) { if(o != null) { a.push(o); } }
         a.sortOn("uRangeM",Array.NUMERIC);
         return a;
      }
      private function hzsNearestUndisc(a:Array) : Object
      {
         for each(var o:Object in a) { if(o.bIsDiscovered !== true) { return o; } }
         return null;
      }
      // v0.40.2: the HUD quest tracker's rule (HudCompassData.aMissionMarkers): quest and quest-door markers only (never a
      // companion or another marker type that rides in the same list), one per objective text, the first non-optional one
      // first; the objective text is the second line. Off-planet objectives have no distance here.
      private function hzsQuestRow() : Object
      {
         try
         {
            if(this.hzsCmp == null || !(this.hzsCmp.aMissionMarkers is Array)) { return null; }
            var seen:Array = [];
            var list:Array = [];
            for each(var o:Object in this.hzsCmp.aMissionMarkers)
            {
               if(o == null) { continue; }
               var mt:uint = uint(o.uiMarkerIconType);
               if(mt != MapMarkerUtils.MIT_MARKER_QUEST && mt != MapMarkerUtils.MIT_MARKER_QUEST_DOOR) { continue; }
               var tx:String = o.strText != null ? String(o.strText) : "";
               if(seen.indexOf(tx) >= 0) { continue; }
               seen.push(tx);
               list.push(o);
            }
            // v0.40.3: the first non-optional marker that has a distance, else the first marker that has one
            var pick:Object = null;
            for each(var q:Object in list) { var qd:Number = Number(q.fDistanceToPlayer); if(pick == null && !isNaN(qd) && qd >= 0 && !this.hzsIsOpt(String(q.strText))) { pick = q; } }
            for each(var q2:Object in list) { var qd2:Number = Number(q2.fDistanceToPlayer); if(pick == null && !isNaN(qd2) && qd2 >= 0) { pick = q2; } }
            if(pick == null) { return null; }
            var d:Number = Number(pick.fDistanceToPlayer);
            var door:Boolean = uint(pick.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_QUEST_DOOR;
            var sub:String = pick.strText != null && String(pick.strText).length > 0 ? String(pick.strText) : (door ? "Entrance" : "Objective");
            return {"ic":"qdiamond","n":this.hzsCs(door ? "QUEST ENTRANCE" : "QUEST OBJECTIVE"),"sub":sub,"d":this.hzsDist(d),"hl":false,"col":HZS_QST,"dc":this.hzsAccent()};   // v0.41.0: gold
         }
         catch(e:Error) { }
         return null;
      }
      // the HUD's optional-objective test: "(optional)" anywhere or a leading "optional"
      private function hzsIsOpt(t:String) : Boolean
      {
         if(t == null) { return false; }
         return new RegExp("\\(\\s*optional\\s*\\)|^\\s*optional\\b","i").test(t);
      }
      // the HUD compass's follower test (a companion and a companion's ship are never "your ship")
      // r4: the icon type only. The compass map type is another table than the scripts' MARKER_* (the player ship arrives as
      // 10/83, and 83 is MARKER_SHIP_COUNT there), so a map type alone never makes a follower.
      private function hzsIsFol(o:Object) : Boolean
      {
         return uint(o.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_COMPANION;
      }
      // r4: your ship by the compass map type only together with the parked-ship icon. v0.42.0: map type 83 only (the parked
      // player ship arrives as 10 / 83 in game; the scripts' MARKER_SHIP_PLAYER 80 is another table and is no longer trusted
      // on the compass). Any other icon with 83 is not trusted.
      private static const HZS41_SHIP_PLAYER_RT:int = 83;
      private function hzs41IsPlayerShipT(o:Object) : Boolean
      {
         if(o.uMapMarkerType == undefined || o.uMapMarkerType === null) { return false; }
         if(uint(o.uiMarkerIconType) != MapMarkerUtils.MIT_MARKER_SHIP_PARKED) { return false; }
         var mmt:int = int(o.uMapMarkerType);
         return mmt == HZS41_SHIP_PLAYER_RT;   // v0.42.0: 80 dropped
      }
      // r3: every compass marker, from the same lists as the HUD compass (aMarkers, aMissionMarkers, aEnemyMarkers, then any other
      // list of markers with a heading), de-duplicated by uiHandle (a follower keeps its own key, as on the HUD). A marker without
      // a handle that sits in two lists counts twice: for your ship / vehicle that means "in doubt" (no YOUR row), fail-safe.
      // r4: built once per scanner frame (per compass data object) and shared by every caller of that frame.
      private var hzs41CmpF:int = -1;
      private var hzs41CmpS:Object = null;
      private var hzs41CmpC:Array = null;
      private function hzs41CmpAll() : Array
      {
         if(this.hzs41CmpC != null && this.hzs41CmpF == this.hzsFrame && this.hzs41CmpS === this.hzsCmp) { return this.hzs41CmpC; }
         this.hzs41CmpC = this.hzs41CmpBuild();
         this.hzs41CmpF = this.hzsFrame;
         this.hzs41CmpS = this.hzsCmp;
         return this.hzs41CmpC;
      }
      private function hzs41CmpBuild() : Array
      {
         var out:Array = [];
         if(this.hzsCmp == null) { return out; }
         var main:Array = ["aMarkers","aMissionMarkers","aEnemyMarkers"];
         var keys:Array = main.slice();
         var other:Array = [];
         for(var dk:String in this.hzsCmp) { if(main.indexOf(dk) < 0) { other.push(dk); } }
         other.sort();
         keys = keys.concat(other);
         var seen:Object = {};
         for each(var k:String in keys)
         {
            var av:Array = this.hzsCmp[k] as Array;
            if(av == null || av.length == 0) { continue; }
            if(main.indexOf(k) < 0 && (av[0] == null || av[0].fHeading == undefined)) { continue; }
            for each(var o:Object in av)
            {
               if(o == null || typeof o != "object") { continue; }
               if(o.uiHandle != undefined && o.uiHandle !== null && uint(o.uiHandle) != 0)
               {
                  var sk:String = (this.hzsIsFol(o) ? "f" : "m") + String(o.uiHandle);
                  if(seen[sk] === true) { continue; }
                  seen[sk] = true;
               }
               out.push(o);
            }
         }
         return out;
      }
      private function hzsShipRow() : Object
      {
         try
         {
            if(this.hzsCmp == null || !(this.hzsCmp.aMarkers is Array)) { return null; }
            var best:Object = this.hzs41MyShip();   // v0.40.2 rule, shared with the compass and the world markers (v0.41.0)
            for each(var o:Object in (best != null ? [best] : []))
            {
               var d:Number = Number(o.fDistanceToPlayer);
               if(isNaN(d) || d < 0) { return null; }   // no distance for the ship: the row stays hidden
               return {"ic":"ship","n":this.hzsCs("YOUR SHIP"),"sub":"Landing zone","d":this.hzsDist(d),"hl":false,"col":HZS_O2B,"dc":this.hzsAccent()};
            }
         }
         catch(e:Error) { }
         return null;
      }
      // ---------------------------------------------------------------- v0.41.0 (test r2 / r4 / final): whose ship / vehicle, companion row
      // The game sends no owner flag on a scan marker. Trusted scan types: MARKER_SHIP_PLAYER and MARKER_SHIP_COMPANION.
      // Otherwise a scan marker is yours only on ONE tight match with the compass marker of your ship / vehicle: the same
      // distance (8 m / 2 %), no other ship / vehicle scan marker within twice that, and the same side of the view (screen
      // position vs the compass bearing); a match holds 1 s through a wobble. Anything in doubt is neutral.
      // Your ship on the compass (r4, v0.42.0): parked-ship icon plus map type 83 (seen in game).
      private var hzs41Hold:Object = {};     // kind -> [time, distance] of the last tight match
      private var hzs41PickF:int = -1;       // frame of the cached picks
      private var hzs41PickC:Object = {};
      private var hzs41PEnd:int = -100000;   // the SHOW RESOURCES pulse whose last (cleared) frame was drawn
      private function hzs41MyShip() : Object
      {
         var one:Object = null;
         var n:int = 0;
         try
         {
            for each(var s:Object in this.hzs41CmpAll())   // r3: every compass list
            {
               if(s == null || this.hzsIsFol(s)) { continue; }   // r4: no companion-ship map type (not trusted: two parked ships = in doubt)
               if(this.hzs41IsPlayerShipT(s)) { return s; }   // parked-ship icon + map type 83
               if(uint(s.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_SHIP_PARKED) { one = s; n++; }
            }
         }
         catch(e:Error) { }
         return n == 1 ? one : null;
      }
      private function hzs41MyVeh() : Object
      {
         var one:Object = null;
         var n:int = 0;
         try
         {
            for each(var s:Object in this.hzs41CmpAll())   // r3: every compass list
            {
               if(s == null || this.hzsIsFol(s)) { continue; }
               if(uint(s.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_VEHICLE) { one = s; n++; }   // r4: the icon only
            }
         }
         catch(e:Error) { }
         return n == 1 ? one : null;
      }
      // a compass marker of a ship (parked, the player's or a companion's); r4: the icon only
      private function hzs41IsShip(s:Object) : Boolean
      {
         return uint(s.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_SHIP_PARKED;
      }
      private function hzs41Tol(a:Number, b:Number) : Number
      {
         return Math.max(8,0.02 * Math.max(a,b));
      }
      private function hzs41Near(a:Number, b:Number) : Boolean
      {
         if(isNaN(a) || isNaN(b) || a < 0 || b < 0) { return false; }
         return Math.abs(a - b) <= this.hzs41Tol(a,b);
      }
      private function hzs41UT(o:Object) : int
      {
         return o.uType != undefined && o.uType !== null ? int(o.uType) : -1;
      }
      // "ship" / "veh" for a ship / vehicle scan marker, "" for anything else
      private function hzs41Kind(o:Object) : String
      {
         var ut:int = this.hzs41UT(o);
         if(ut == int(MapMarkerUtils.MARKER_VEHICLE)) { return "veh"; }
         if(uint(o.uCategory) == MapMarkerUtils.MARKER_TYPE_SHIP || ut == int(MapMarkerUtils.MARKER_SHIP_PLAYER) || ut == int(MapMarkerUtils.MARKER_SHIP_COMPANION)) { return "ship"; }
         return "";
      }
      // the same side of the view: the scan marker's screen x vs the compass marker's bearing relative to the heading, each
      // left / center / right (center = within 5 % of the middle / 6 degrees); anything unknown = false (in doubt)
      private function hzs41Side(o:Object, ref:Object) : Boolean
      {
         var fx:Number = Number(o.fScreenXPct);
         var hd:Number = Number(ref.fHeading);
         if(isNaN(fx) || fx < 0 || fx > 1 || isNaN(hd) || isNaN(this.hzsHead)) { return false; }
         var rel:Number = ((hd * 180 / Math.PI - this.hzsHead) % 360 + 540) % 360 - 180;
         var sx:Number = fx - 0.5;
         var a:int = sx < -0.05 ? -1 : (sx > 0.05 ? 1 : 0);
         var b:int = rel < -6 ? -1 : (rel > 6 ? 1 : 0);
         if(a == b) { return true; }
         return (a == 0 || b == 0) && Math.abs(sx) <= 0.15 && Math.abs(rel) <= 20;
      }
      // the scan marker that is yours for a kind, or null (none, or in doubt); worked out once per frame
      private function hzs41Pick(kind:String) : Object
      {
         if(this.hzs41PickF != this.hzsFrame) { this.hzs41PickF = this.hzsFrame; this.hzs41PickC = {}; }
         if(this.hzs41PickC[kind] !== undefined) { return this.hzs41PickC[kind]; }
         var r:Object = null;
         try { r = this.hzs41PickNow(kind); } catch(e:Error) { r = null; }
         this.hzs41PickC[kind] = r;
         return r;
      }
      private function hzs41PickNow(kind:String) : Object
      {
         var auth:Object = null;
         var cand:Array = [];
         for each(var o:Object in this.hzsMarkers())
         {
            if(this.hzs41Kind(o) != kind) { continue; }
            var ut:int = this.hzs41UT(o);
            if(ut == int(MapMarkerUtils.MARKER_SHIP_PLAYER)) { if(auth != null) { return null; } auth = o; continue; }   // two: in doubt
            if(ut == int(MapMarkerUtils.MARKER_SHIP_COMPANION)) { continue; }
            cand.push(o);
         }
         if(auth != null) { return auth; }
         var ref:Object = kind == "veh" ? this.hzs41MyVeh() : this.hzs41MyShip();
         if(ref == null) { return null; }
         var rd:Number = Number(ref.fDistanceToPlayer);
         if(isNaN(rd) || rd <= 0) { return null; }
         var hit:Object = null;
         var close:int = 0;
         for each(var c:Object in cand)
         {
            var d:Number = Number(c.uRangeM);
            if(isNaN(d) || d < 0) { continue; }
            var tol:Number = this.hzs41Tol(d,rd);
            if(Math.abs(d - rd) <= 2 * tol) { close++; }
            if(Math.abs(d - rd) <= tol) { hit = c; }
         }
         var now:int = getTimer();
         if(close == 1 && hit != null && this.hzs41Side(hit,ref)) { this.hzs41Hold[kind] = [now,Number(hit.uRangeM)]; return hit; }
         var hold:Array = this.hzs41Hold[kind] as Array;
         if(close == 1 && hold != null && now - int(hold[0]) < 1000)
         {
            for each(var h:Object in cand) { var hd2:Number = Number(h.uRangeM); if(this.hzs41Near(hd2,Number(hold[1])) && Math.abs(hd2 - rd) <= 2 * this.hzs41Tol(hd2,rd)) { return h; } }
         }
         return null;
      }
      // scan marker (aScannableMarkers): "mine" (the trusted type or the one tight match), "other" (a companion's ship:
      // MARKER_SHIP_COMPANION, the only "not mine" the game tells), "" (anything else; a ship / vehicle in doubt = neutral)
      private function hzs41Own(o:Object) : String
      {
         try
         {
            var kind:String = this.hzs41Kind(o);
            if(kind == "") { return ""; }
            if(this.hzs41UT(o) == int(MapMarkerUtils.MARKER_SHIP_COMPANION)) { return "other"; }
            return this.hzs41Pick(kind) === o ? "mine" : "";
         }
         catch(e:Error) { }
         return "";
      }
      private function hzs41VehRow() : Object
      {
         var v:Object = this.hzs41MyVeh();
         if(v == null) { return null; }
         var d:Number = Number(v.fDistanceToPlayer);
         if(isNaN(d) || d < 0) { return null; }
         return {"ic":"vehicle","n":this.hzsCs("YOUR VEHICLE"),"sub":"Vehicle","d":this.hzsDist(d),"hl":false,"col":HZS_O2B,"dc":this.hzsAccent()};
      }
      // the compass follower marker (a companion; never a companion's ship), green; list row only (no world marker)
      private function hzs41FolRow() : Object
      {
         try
         {
            for each(var s:Object in this.hzs41CmpAll())   // r3: every compass list (a follower can ride in the mission list)
            {
               if(s == null || !this.hzsIsFol(s)) { continue; }   // r4: the follower icon only (no map-type follower, no map-type ship skip)
               var d:Number = Number(s.fDistanceToPlayer);
               if(isNaN(d) || d < 0) { continue; }
               var nm:String = s.strText != null ? String(s.strText) : (s.sName != null ? String(s.sName) : "");
               var named:Boolean = nm.length > 0 && nm.charAt(0) != "$";
               return {"ic":"person","n":named ? this.hzsGs(nm) : this.hzsCs("COMPANION"),"sub":named ? "Companion" : "Follower","d":this.hzsDist(d),"hl":false,"col":HZS_GRN,"dc":this.hzsAccent()};
            }
         }
         catch(e:Error) { }
         return null;
      }
      // SF-10: an accent ring (and a RESOURCES chip above the card) that fades out over ~0.9 s after SHOW RESOURCES
      private function hzs41Pulse(p:Sprite, w:Number, h:Number, r:Number, pl:Number, acc:uint) : void
      {
         if(isNaN(pl) || pl <= 0) { return; }
         var g:* = p.graphics;
         g.lineStyle(2.5,acc,pl,true); g.beginFill(acc,0.01); g.drawRoundRect(-4,-4,w + 8,h + 8,r * 2 + 8,r * 2 + 8); g.endFill(); g.lineStyle();
         var t:TextField = this.hzsT(p,this.hzsCs("RESOURCES"),0,-20,13,acc,"bd",0.12,"l",pl);
         var cw:Number = this.hzsTw(t) + 24;
         t.x = Math.round(w - cw + 12 - 2);
         this.hzsRR(g,w - cw,-33,cw,26,13,acc,46 / 255 * pl);
      }
      private function hzsMSignals() : Object
      {
         if(!this.hzsOn("ScanShowSignals")) { return null; }
         var acc:uint = this.hzsAccent();
         var mk:Array = this.hzsMarkers();
         var inr:int = mk.length;
         var q:Object = this.hzsQuestRow();
         var sh:Object = this.hzsOn("ScanShowShip") ? this.hzsShipRow() : null;
         var vh:Object = this.hzsOn("ScanShowShip") ? this.hzs41VehRow() : null;   // v0.41.0
         var fo:Object = this.hzs41FolRow();
         var mx:int = int(this.hzsC.ScanMaxSignals);
         var nMk:int = Math.max(0,mx - (q != null ? 1 : 0));
         if(sh != null && nMk > 1) { nMk--; } else { sh = null; }
         if(fo != null && nMk > 1) { nMk--; } else { fo = null; }
         if(vh != null && nMk > 1) { nMk--; } else { vh = null; }
         // r2 (NIT-6): your marker is shown by its YOUR SHIP / YOUR VEHICLE row: left out BEFORE the slots are filled
         // r3: YOUR SHIP ROW off (ScanShowShip=0) leaves your own ship and vehicle out of Signals entirely
         var showMine:Boolean = this.hzsOn("ScanShowShip");
         if(sh != null || vh != null || !showMine)
         {
            var mk2:Array = [];
            for each(var o0:Object in mk) { if(this.hzs41Own(o0) == "mine" && (!showMine || (this.hzs41Kind(o0) == "veh" ? vh != null : sh != null))) { continue; } mk2.push(o0); }
            mk = mk2;
         }
         var near:Object = this.hzsOn("ScanNearestUnscanned") ? this.hzsNearestUndisc(mk) : null;
         var picked:Array = mk.slice(0,nMk);
         if(near != null && picked.indexOf(near) < 0 && picked.length > 0) { picked[picked.length - 1] = near; picked.sortOn("uRangeM",Array.NUMERIC); }
         var rows:Array = [];
         for each(var o:Object in picked)
         {
            var hl:Boolean = near != null && o == near;
            var disc:Boolean = o.bIsDiscovered === true;
            var own:String = this.hzs41Own(o);   // v0.41.0 r2: "mine" / "other" (a companion's ship) / "" (neutral)
            var mcol:uint = own == "mine" ? HZS_O2B : (own == "other" ? HZS_VIO : (disc || hl ? acc : HZS_MUTED));
            var msub:String = hl ? this.hzsCs("NEAREST UNDISCOVERED") : (own == "other" ? "Companion ship" : (disc ? "Discovered" : "Undiscovered"));
            var myName:Boolean = own == "mine" && this.hzsOn("ScanShowShip");   // r2 (NIT-7): the YOUR SHIP name only with that row on
            rows.push({"ic":this.hzsMarkIcon(o),"n":myName ? this.hzsCs(this.hzs41Kind(o) == "veh" ? "YOUR VEHICLE" : "YOUR SHIP") : this.hzsMarkName(o),"sub":msub,"d":this.hzsDist(Number(o.uRangeM)),"hl":hl,"col":hl ? acc : mcol,"dc":acc});
         }
         if(q != null) { rows.push(q); }
         if(fo != null) { rows.push(fo); }
         if(vh != null) { rows.push(vh); }
         if(sh != null) { rows.push(sh); }
         if(rows.length == 0) { return null; }
         var nm:Object = near != null ? {"n":this.hzsCs("NEAREST UNDISCOVERED"),"d":this.hzsDist(Number(near.uRangeM)),"hl":true} : (picked.length > 0 ? {"n":this.hzsMarkName(picked[0]),"d":this.hzsDist(Number(picked[0].uRangeM)),"hl":false} : null);
         return {"cmp":this.hzsCmpOn("Signals"),"rows":rows,"inr":inr,"near":nm};
      }
      private function hzsMTraits() : Object
      {
         if(!this.hzsOn("ScanShowTraits") || !this.hzsShowPlanetInfo()) { return null; }
         var tr:Array = this.hzsTraitState();
         var tiles:Array = [];
         try { for each(var t:* in this.hzsMD.aPlanetTraits) { tiles.push(int(t) != TraitsIcon.TRAIT_UNKNOWN ? 1 : 0); } } catch(e0:Error) { }
         var sites:Array = null;
         if(int(this.hzsMD.uLocationTraitRefsRequired) > 0) { sites = [int(this.hzsMD.uLocationTraitRefsScanned),int(this.hzsMD.uLocationTraitRefsRequired)]; }
         var minr:int = int(this.hzsC.ScanMinRarity);
         var res:Array = [];
         var counts:Array = [];
         var known:int = 0;
         var hidden:int = 0;
         var i:int = 0;
         while(i < HZS_RAR_K.length)
         {
            var arr:Array = this.hzsRD != null ? this.hzsRD[HZS_RAR_K[i]] as Array : null;
            var items:Array = [];
            for each(var r:Object in arr)
            {
               if(r == null) { continue; }
               var dis:Boolean = r.bDisabled === true;
               if(!dis) { known++; }
               items.push([dis ? "?" : String(r.sSymbol),dis ? this.hzsCs("UNKNOWN") : String(r.sName),dis ? 1 : 0]);
            }
            if(i < minr) { hidden += items.length; }
            else if(items.length > 0) { res.push({"r":i,"items":items}); }
            counts.push(i < minr ? 0 : items.length);
            i++;
         }
         var sp:Array = this.hzsRD != null ? this.hzsRD.aSpecialResources as Array : null;
         if(sp != null && sp.length > 0)
         {
            var sitems:Array = [];
            for each(var s:Object in sp) { if(s != null) { sitems.push([String(s.sSymbol),String(s.sName),s.bDisabled === true ? 1 : 0]); if(s.bDisabled !== true) { known++; } } }
            if(sitems.length > 0) { res.push({"r":-1,"items":sitems}); }
         }
         if(tiles.length == 0 && sites == null && res.length == 0) { return null; }
         var lbl:String = minr == 0 ? known + " " + this.hzsCs("KNOWN") : this.hzsCs(["","UNCOMMON+","RARE+","EXOTIC+","UNIQUE"][minr]) + "  " + String.fromCharCode(0xB7) + "  " + hidden + " " + this.hzsCs("HIDDEN");
         var pdt:int = getTimer() - this.hzs41PT;
         var pl:Number = pdt >= 0 && pdt < 900 ? Math.round((1 - pdt / 900) * 10) / 10 : 0;   // v0.41.0: SHOW RESOURCES pulse level
         return {"cmp":this.hzsCmpOn("Traits"),"k":tr[0],"n":tr[1],"tiles":tiles,"sites":sites,"res":res,"lbl":lbl,"counts":counts,"pl":pl};
      }
      // the minimal person strip (D1): social skills (name, % success, duration) + the bounty prompt. Nothing else.
      private function hzsSocialOn() : Boolean
      {
         return this.bDoingSocialScan || this.CurrentPickRefType == this.PICK_TYPE_NPC;
      }
      private function hzsMSocial() : Object
      {
         if(!this.hzsSocialOn()) { return null; }
         var rows:Array = [];
         var selIdx:int = -1;
         try { if(this.bDoingSocialScan && this.socialSpellList.selectedEntry != null) { selIdx = int(this.socialSpellList.selectedEntry.uSpellIndex); } } catch(e0:Error) { }
         try
         {
            for each(var o:Object in this.hzsMD.aSocialSpells)
            {
               if(o == null || o.bVisible !== true) { continue; }   // the game list's own filter
               rows.push([String(o.sName),int(o.uPercentSuccess),int(o.uDurationSecs),selIdx >= 0 && int(o.uSpellIndex) == selIdx ? 1 : 0]);
            }
         }
         catch(e1:Error) { }
         var b:Object = null;
         if(this.bPickHasBounty)
         {
            var amt:Number = this.hzsPA != null ? Number(this.hzsPA.uBountyAmount) : NaN;
            var bi:Object = this.hzsBtnInfo("AButton_mc");
            b = {"acc":this.bPickBountyAccepted ? 1 : 0,"amt":isNaN(amt) || amt <= 0 ? "" : this.hzsNum(amt) + " CR","key":bi.vis && bi.en ? bi.key : "","lab":bi.lab,"font":bi.font};
         }
         if(rows.length == 0 && b == null)
         {
            // v0.40.2: a scanned person with nothing to act on says so (the game shows no skill list then)
            if(uint(this.CurrentPickRefType) == this.PICK_TYPE_NPC && this.hzsPickSettled() && this.hzsPA.bIsAlive !== false) { return {"rows":[],"b":null,"note":this.hzsCs("No bounty") + "  " + String.fromCharCode(0xB7) + "  " + this.hzsCs("no social skill to use")}; }
            return null;
         }
         return {"rows":rows,"b":b};
      }
      // r5: the provider's current pick (MonoclePickRefData, the object the game updates in place) is still the pick the game
      // applied (same type, form and handle). When the crosshair leaves a target the provider changes at once, but the game
      // applies the change up to 5 frames later (its PICK_FRAME_DELAY_LEN); the world tag is hidden for those frames instead of
      // naming the old pick. Nothing known (no provider data yet, no type) = live.
      private function hzs51PickLive() : Boolean
      {
         var l:Object = this.hzsPD;
         var a:Object = this.hzsPA;
         if(l == null || a == null) { return true; }
         try
         {
            if(l.uPickRefType === undefined || l.uPickRefType === null) { return true; }
            return uint(l.uPickRefType) == uint(a.uPickRefType) && uint(l.uFormID) == uint(a.uFormID) && uint(l.uHandle) == uint(a.uHandle);
         }
         catch(e:Error) { }
         return true;
      }
      private function hzsPickSettled() : Boolean
      {
         try { return this.hzsPA != null && uint(this.hzsPA.uPickRefType) == uint(this.CurrentPickRefType); } catch(e:Error) { }
         return false;
      }
      // v0.40.3: the name of a map-marker pick (PICK_TYPE_MAP_MARKER): the game's own detail line (PickRefDetailsA, what its
      // marker card shows), else the marker's type name. Never sName: the game does not refresh it for a marker (it still
      // holds the person or object picked before).
      private function hzsPickMarkName(d:Object) : String
      {
         try
         {
            // v0.40.3 r2: an unscanned marker gets the Signals list's label (its type name); a scanned one its detail
            // line, a "$KEY" line through the game's translation, a key left unresolved counts as empty
            if(this.hzsPickDisc(d) && d.PickRefDetailsA is Array)
            {
               for each(var ln:* in d.PickRefDetailsA)
               {
                  var s:String = ln != null ? this.hzsTrim(String(ln).replace(new RegExp("<[^>]*>","g"),"")) : "";
                  if(s.charAt(0) == "$") { s = this.hzsTrim(this.hzsTr(s)); }
                  if(s.length > 0 && s.charAt(0) != "$") { return this.hzsGs(s); }
               }
            }
            return this.hzsMarkName(this.hzsPickSig(d));
         }
         catch(e:Error) { }
         return this.hzsCs("SIGNAL");
      }
      private function hzsTrim(s:String) : String { return s == null ? "" : s.replace(new RegExp("^\\s+|\\s+$","g"),""); }
      // the game's reveal rule for a picked marker (its marker card): full when discovered or not scannable
      private function hzsPickDisc(d:Object) : Boolean { return Boolean(d.bIsDiscovered) || !d.bIsScannable; }
      // the Signals list entry of the picked marker (same type, category and discovered flag, only when exactly one
      // matches), so the tag and the Signals row use the same state; else the state from the reveal rule
      private function hzsPickSig(d:Object) : Object
      {
         var one:Object = null;
         var n:int = 0;
         try
         {
            for each(var o:Object in this.hzsMarkers())
            {
               if(o != null && uint(o.uType) == uint(d.uMapMarkerType) && uint(o.uCategory) == uint(d.uMapMarkerCategory) && (o.bIsDiscovered === true) == Boolean(d.bIsDiscovered)) { one = o; n++; }
            }
         }
         catch(e:Error) { n = 0; }
         if(n == 1) { return one; }
         return {"uLocationMarkerState":this.hzsPickDisc(d) ? MapMarkerUtils.LMS_FULL_REVEAL : MapMarkerUtils.LMS_ONLY_TYPE_KNOWN,"uCategory":uint(d.uMapMarkerCategory)};
      }
      // world tag for the picked object. v0.40.3: the text comes from the field the game itself shows for that pick type
      // (sName for a resource, flora, fauna, object, item, container, ship, door and a person; the detail line or type name
      // for a map marker). A person (t=4) gets a name-only tag (no type, scan %, chips, crimes or bounty) alongside the
      // minimal D1 bounty / social-skill strip.
      private function hzsMTag() : Object
      {
         if(!this.hzsOn("ScanShowWorldTags") || !this.hzsPickSettled() || !this.hzs51PickLive()) { return null; }   // r5: + the live pick
         var t:uint = uint(this.CurrentPickRefType);
         if(t == this.PICK_TYPE_NONE) { return null; }
         var d:Object = this.hzsPA;   // v0.40.2: the pick the game applied
         var mk:Boolean = t == this.PICK_TYPE_MAP_MARKER;
         var np:Boolean = t == this.PICK_TYPE_NPC;   // a person: the name only
         var nm:String = mk ? this.hzsPickMarkName(d) : (d.sName != null ? String(d.sName) : "");
         if(nm.length == 0) { return null; }
         var col:uint = this.hzsAccent();
         var sym:String = "";
         var sub:String = "";
         if(t == this.PICK_TYPE_RESOURCE)
         {
            sym = d.sSymbol != null ? String(d.sSymbol) : "";
            if(d.uColor != undefined && uint(d.uColor) > 0) { col = uint(d.uColor); }
         }
         var bt:String = !mk && !np && d.sBioscanType != null ? String(d.sBioscanType) : "";   // v0.40.3: a marker has none (the field is stale)
         if(bt.length > 0)
         {
            var tn:String = this.hzsTr("$" + bt);
            sub = (tn.length > 0 && tn.charAt(0) != "$" ? tn : bt);
            if(d.uScanTypeProgressPct != undefined && t != this.PICK_TYPE_RESOURCE) { sub += "  " + String.fromCharCode(0xB7) + "  " + int(d.uScanTypeProgressPct) + "% " + this.hzsCs("SCANNED"); }
         }
         var dist:String = "";   // v0.40.2: the RANGE pill under the reticle carries the distance (once, like the game)
         // v0.40.1: the game's pick flags, same rules as its own pick card (contraband wins over stealing)
         var flg:Array = [];
         if(!mk && !np && d.bIsContraband === true) { flg.push("CONTRABAND"); }
         else if(!mk && !np && d.bIsStealing === true) { flg.push("STEALING"); }
         if(!mk && !np && d.bIsTrackedForCrafting === true) { flg.push("TAGGED"); }
         if(t == this.PICK_TYPE_FAUNA) { if(d.bIsAlive === false) { flg.push("DEAD"); } else if(d.bIsDiseased === true) { flg.push("DISEASED"); } }   // v0.41.0 (SF-9): the game's own fauna card rule
         if(mk && !this.hzsPickDisc(d)) { sub = this.hzsCs("UNDISCOVERED"); }   // an unscanned marker: second line, like the Signals rows
         return {"sym":sym,"n":mk ? nm : this.hzsGs(nm),"sub":sub,"d":dist,"col":col,"res":t == this.PICK_TYPE_RESOURCE ? 1 : 0,"flg":flg.join(",")};
      }
      private function hzsMMode() : Object
      {
         if(!this.hzsOn("ScanShowMode")) { return null; }
         return {"m":this.hzsCs(this.hzsSocialOn() ? "PERSON SCAN" : "PLANET SCAN"),"a":this.hzsCs("AUTO")};
      }
      private function hzsTfAt(o:*, path:Array) : TextField
      {
         try { var c:* = o; for each(var n:String in path) { if(c == null) { return null; } c = c[n]; } return c as TextField; } catch(e:Error) { }
         return null;
      }
      private function hzsShownIn(d:DisplayObject, top:*) : Boolean
      {
         try { var c:DisplayObject = d; while(c != null && c != top) { if(!c.visible) { return false; } c = c.parent; } return true; } catch(e:Error) { }
         return false;
      }
      // read-only mirror of one of the game's buttons: its state and the text it shows (resolved by the game from its
      // ButtonBaseData and ControlMapData; Horizon never names a key or a label itself)
      private function hzsBtnInfo(n:String) : Object
      {
         var o:Object = {"vis":false,"en":false,"lab":"","key":"","font":null};
         var b:* = null;
         try { b = this.ButtonBar_mc[n]; } catch(e0:Error) { b = null; }
         if(b == null) { return o; }
         try { o.vis = Boolean(b.Visible); } catch(e1:Error) { try { o.vis = Boolean(b.visible); } catch(e2:Error) { } }
         try { o.en = Boolean(b.Enabled); } catch(e3:Error) { }
         var lt:TextField = this.hzsTfAt(b,["Label_mc","LabelInstance_mc","Label_tf"]);
         if(lt == null) { lt = this.hzsTfAt(b,["Label_mc","Label_tf"]); }
         if(lt != null && lt.text != null) { o.lab = lt.text.replace(/^\s+|\s+$/g,""); }
         var ct:TextField = this.hzsTfAt(b,["ConsoleButton_mc","ButtonInstance_mc","ConsoleButton_tf"]);
         if(ct == null) { ct = this.hzsTfAt(b,["ConsoleButton_mc","ConsoleButton_tf"]); }
         var pt:TextField = this.hzsTfAt(b,["PCButton_mc","ButtonInstance_mc","PCButton_tf"]);
         if(pt == null) { pt = this.hzsTfAt(b,["PCButton_mc","PCButton_tf"]); }
         var cs:String = ct != null && ct.text != null ? ct.text.replace(/^\s+|\s+$/g,"") : "";
         var ps:String = pt != null && pt.text != null ? pt.text.replace(/^\s+|\s+$/g,"") : "";
         if(cs.length > 0 && this.hzsShownIn(ct,b)) { o.key = cs; try { o.font = ct.getTextFormat().font; } catch(e4:Error) { o.font = null; } }
         else if(ps.length > 0) { o.key = ps.toUpperCase(); }
         if(o.lab.length == 0 || o.key.length == 0) { o.vis = false; }
         return o;
      }
      private function hzsMHints() : Object
      {
         if(!this.hzsOn("ScanShowHints")) { return null; }
         var a:Array = [];
         for each(var n:String in HZS_BTNS)
         {
            var i:Object = this.hzsBtnInfo(n);
            if(i.vis) { a.push({"k":i.key,"l":this.hzsGs(i.lab),"en":i.en ? 1 : 0,"f":i.font}); }
         }
         return a.length == 0 ? null : {"h":a};
      }

      // ---------------------------------------------------------------- panels (local 1080p units, origin = top-left)
      private var hzsSz:Object = {};
      private var hzsCmpSig:String = "";
      private var hzsRetSig:String = "";
      private var hzsMarkSig:String = "";
      private static const HZS_RAR_C:Array = [0xC4D2D9,0x5EE3A1,0x4DB6FF,0xB48CFF,0xF2A93B];
      private function hzsDrawPanel(n:String) : void
      {
         var p:Sprite = this.hzsP[n] as Sprite;
         if(p == null) { return; }
         var m:Object = null;
         try
         {
            if(n == "Planet") { m = this.hzsMPlanet(); }
            else if(n == "Bioscan") { m = this.hzsMBioscan(); }
            else if(n == "Signals") { m = this.hzsMSignals(); }
            else if(n == "Traits") { m = this.hzsSocialOn() ? null : this.hzsMTraits(); }
            else if(n == "Social") { m = this.hzsMSocial(); }
            else if(n == "Mode") { m = this.hzsMMode(); }
            else if(n == "Hints") { m = this.hzsMHints(); }
         }
         catch(e0:Error) { m = null; }
         var sig:String = this.hzsSer(m) + "|" + this.hzsCfgSig;
         if(sig == this.hzsSig[n]) { return; }
         this.hzsSig[n] = sig;
         this.hzsClr(p);
         if(m == null) { p.visible = false; this.hzsSz[n] = null; return; }
         var wh:Array = null;
         this.hzsTk = this.hzsK(this.hzsKeyOf(n));   // 0.42.0.4: text floor after this panel's scale
         try
         {
            if(n == "Planet") { wh = m.cmp ? this.hzsDPlanetC(p,m) : this.hzsDPlanet(p,m); }
            else if(n == "Bioscan") { wh = m.cmp ? this.hzsDBioC(p,m) : this.hzsDBio(p,m); }
            else if(n == "Signals") { wh = m.cmp ? this.hzsDSigC(p,m) : this.hzsDSig(p,m); }
            else if(n == "Traits") { wh = m.cmp ? this.hzsDTraitsC(p,m) : this.hzsDTraits(p,m); }
            else if(n == "Social") { wh = this.hzsDSocial(p,m); }
            else if(n == "Mode") { wh = this.hzsDMode2(p,m); }
            else if(n == "Hints") { wh = this.hzsDHints2(p,m); }
         }
         catch(e1:Error) { wh = null; }
         this.hzsTk = 1;
         if(wh == null) { this.hzsClr(p); p.visible = false; this.hzsSz[n] = null; return; }
         this.hzsSz[n] = wh;
         p.visible = true;
      }
      private function hzsDPlanet(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         var x0:Number = HZS_PAD + 2;
         var iw:Number = w - HZS_PAD - x0;
         var nrow:int = int(Math.ceil(m.cond.length / 2));
         var hy:Number = 118 + nrow * 42 + 6;
         var haz:Array = m.haz as Array;
         var h:Number = haz == null ? hy - 10 : (haz.length == 0 ? hy + 22 : hy + 24 + haz.length * 40);
         this.hzsCard(g,w,h,HZS_R_CARD,acc);
         this.hzsTile(g,x0 + 20,36,20,acc,0.55);
         this.hzsIcon(g,"planet",x0 + 20,36,acc);
         var pt:TextField = this.hzsT(p,m.pct + "%",w - HZS_PAD,28,30,HZS_WHITE,"bd",0,"r");
         this.hzsT(p,this.hzsCs("SURVEYED"),w - HZS_PAD,52,13,HZS_LABEL,"sb",0.12,"r");
         var nmax:Number = pt.x - (x0 + 50) - 12;
         this.hzsT(p,String(m.name),x0 + 50,26,22,HZS_WHITE,"sb",0.08,"l",1,nmax);
         if(String(m.sys).length > 0) { this.hzsT(p,String(m.sys),x0 + 50,50,13,HZS_MUTED,"sb",0.08,"l",1,nmax); }
         this.hzsBar(g,x0,68,iw,6,int(m.pct) / 100,acc);
         if(m.cond.length > 0)
         {
            this.hzsSection(p,x0,94,iw,"CONDITIONS",null,acc);
            var cw:Number = iw / 2;
            var i:int = 0;
            while(i < m.cond.length)
            {
               var cx:Number = x0 + i % 2 * cw;
               var cy:Number = 118 + int(i / 2) * 42;
               this.hzsT(p,this.hzsCs(String(m.cond[i][0])),cx,cy,13,HZS_LABEL,"sb",0.1,"l",1,cw - 8);
               this.hzsT(p,String(m.cond[i][1]),cx,cy + 19,17,HZS_WHITE,"sb",0.02,"l",1,cw - 8);
               i++;
            }
         }
         if(haz != null)
         {
            this.hzsSection(p,x0,hy,iw,"HAZARDS",haz.length == 0 ? this.hzsCs("NONE") : haz.length + " " + this.hzsCs("ACTIVE") + "  " + String.fromCharCode(0xB7) + "  " + this.hzsCs("SHARED"),acc);   // r2 (NIT-8): short, CAPS-aware, the count kept
            var yy:Number = hy + 26;
            for each(var z:Object in haz)
            {
               var c:uint = this.hzsHazCol(int(z.p));
               this.hzsTile(g,x0 + 14,yy + 12,14,c,0.5);
               this.hzsIcon(g,String(z.ic),x0 + 14,yy + 12,c);
               this.hzsT(p,this.hzsCs(String(z.n)),x0 + 38,yy + 5,14,HZS_WHITE,"sb",0.1);
               this.hzsT(p,this.hzsCs("EXPOSURE") + " " + int(z.p) + "%",x0 + iw,yy + 5,13,c,"sb",0.06,"r");   // v0.41.0: the color carries the severity
               this.hzsBar(g,x0 + 38,yy + 19,iw - 38,4,int(z.p) / 100,c);
               yy += 40;
            }
         }
         return [w,h];
      }
      private function hzsDPlanetC(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         this.hzsCard(g,w,44,HZS_R_STRIP,acc);
         this.hzsIcon(g,"planet",28,22,acc,0.78);
         var haz:Array = m.haz as Array;
         var nh:int = haz == null ? 0 : Math.min(4,haz.length);
         var hx:Number = w - 16 - nh * 30;
         var i:int = 0;
         while(i < nh)
         {
            var c:uint = this.hzsHazCol(int(haz[i].p));
            this.hzsTile(g,hx + 14,22,13,c,0.55);
            this.hzsIcon(g,String(haz[i].ic),hx + 14,22,c);
            hx += 30;
            i++;
         }
         var lim:Number = w - 16 - nh * 30 - 10;
         var pct:String = m.pct + "%";
         var nt:TextField = this.hzsT(p,String(m.name),48,22,15,HZS_WHITE,"sb",0.08,"l",1,Math.max(60,lim - 48 - 160));
         var e:Number = this.hzsRight(nt);
         var pt:TextField = this.hzsT(p,pct,e + 10,22,16,HZS_WHITE,"bd");
         e = this.hzsRight(pt);
         var bw:Number = Math.min(90,lim - e - 10);
         if(bw > 20) { this.hzsBar(g,e + 10,19.5,bw,5,int(m.pct) / 100,acc); }
         return [w,44];
      }
      private function hzsDBio(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         var x0:Number = HZS_PAD + 2;
         var iw:Number = w - HZS_PAD - x0;
         var rows:Array = m.rows as Array;
         var yy:Number = 46 + rows.length * 28;
         var ly:Number = m.lt || m.allFF ? yy + 12 : -1;
         var by:Number = ly >= 0 ? yy + 38 : yy + 12;
         var bio:Boolean = m.hasFl || m.hasFa;
         var nk:int = (m.hasFl ? 1 : 0) + (m.hasFa ? 1 : 0);
         var h:Number = bio ? by + 22 * nk + 30 : (ly >= 0 ? ly + 26 : yy + 4);
         var fl:Number = Number(m.fl);
         var full:Boolean = int(m.tot) >= int(m.mx);
         this.hzsCard(g,w,h,HZS_R_CARD,full ? HZS_GRN : acc,fl > 0 ? HZS_GRN : 0xFFFFFF,fl > 0 ? (90 + 150 * fl) / 255 : 0.1);
         this.hzsSection(p,x0,18,iw,"BIOSCAN",fl > 0 ? null : m.tot + " / " + m.mx,acc);
         var y:Number = 46;
         for each(var r:Array in rows)
         {
            var ok:Boolean = int(r[2]) >= int(r[3]);
            var c:uint = ok ? HZS_GRN : acc;
            this.hzsIcon(g,String(r[1]),x0 + 9,y,c);
            this.hzsT(p,this.hzsCs(String(r[0])),x0 + 28,y,13,HZS_LABEL,"sb",0.1);
            this.hzsSeg(g,x0 + 148,y - 2.5,120,5,int(r[3]),int(r[2]) / Math.max(1,int(r[3])),c);
            this.hzsT(p,r[2] + " / " + r[3],w - HZS_PAD - 22,y,14,HZS_WHITE,"sb",0.02,"r");
            if(ok) { this.hzsCheck(g,w - HZS_PAD - 7,y,HZS_GRN,0.9); }
            y += 28;
         }
         g.beginFill(0xFFFFFF,0.078); g.drawRect(x0,yy - 6,iw,1); g.endFill();
         if(ly >= 0)
         {
            if(m.allFF && (m.hasFl || m.hasFa)) { this.hzsT(p,this.hzsCs("ALL FAUNA AND FLORA FOUND"),x0,ly,13,HZS_GRN,"sb",0.1); }
            else
            {
               var e:Number = x0;
               var k:int = 0;
               for each(var s:String in m.left)
               {
                  if(k > 0) { e = this.hzsRight(this.hzsT(p,String.fromCharCode(0xB7),e + 10,ly,13,HZS_MUTED)) ; }
                  e = this.hzsRight(this.hzsT(p,s,k > 0 ? e + 10 : e,ly,13,HZS_WHITE,"bd",0.1));
                  k++;
               }
            }
         }
         if(bio)
         {
            // v0.40.2: "IN THIS BIOME" + one plain line per kind (planet counts stay in the rows above)
            this.hzsT(p,this.hzsCs("IN THIS BIOME"),x0,by,13,HZS_MUTED,"sb",0.1);
            var bl:Number = by + 22;
            for each(var bk:Array in [[m.hasFl,"FLORA",m.bfl,int(m.flc)],[m.hasFa,"FAUNA",m.bfa,int(m.fac)]])
            {
               if(!bk[0]) { continue; }
               var kt:TextField = this.hzsT(p,this.hzsCs(String(bk[1])),x0,bl,13,bk[2] ? HZS_GRN : HZS_LABEL,"sb",0.1);
               if(bk[2]) { this.hzsCheck(g,x0 + 72,bl,HZS_GRN,0.8); }
               this.hzsT(p,this.hzsBiomeWord(Boolean(bk[2]),int(bk[3])),x0 + 88,bl,13,bk[2] ? HZS_GRN : HZS_WHITE,"rg",0.02,"l",1,iw - 88);
               bl += 22;
            }
         }
         if(fl > 0)
         {
            var msg:String = this.hzsCs("SCAN COMPLETE") + "  " + String.fromCharCode(0xB7) + "  " + m.tot + " / " + m.mx;
            var ct:TextField = this.hzsT(p,msg,0,18,13,HZS_WHITE,"bd",0.1);
            var cw:Number = this.hzsTw(ct) + 24;
            g.lineStyle(1.2,HZS_GRN,1,true); g.beginFill(HZS_GRN,(60 + 150 * fl) / 255); g.drawRoundRect(w - HZS_PAD - cw,6,cw,24,24,24); g.endFill(); g.lineStyle();
            ct.x = Math.round(w - HZS_PAD - cw / 2 - this.hzsTw(ct) / 2 - 2);
            p.setChildIndex(ct,p.numChildren - 1);
         }
         return [w,h];
      }
      private function hzsDBioC(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         var fl:Number = Number(m.fl);
         // v0.41.0: the strip grows with TextScale (44 -> 56 at 1.3); a fauna icon instead of the word BIOSCAN and BIOME + a
         // check / dash instead of BIOME DONE / BIOME: MORE, so the count label fits
         var ts:Number = Math.max(1,Math.min(1.3,Number(this.hzsS.TextScale)));
         if(isNaN(ts)) { ts = 1; }
         var bh:Number = Math.max(44,Math.round(44 + (ts - 1) * 40));
         var cy:Number = bh / 2;
         this.hzsCard(g,w,bh,HZS_R_STRIP,int(m.tot) >= int(m.mx) ? HZS_GRN : acc,fl > 0 ? HZS_GRN : 0xFFFFFF,fl > 0 ? (90 + 150 * fl) / 255 : 0.1);
         this.hzsIcon(g,"fauna",22,cy,acc);
         var e:Number = this.hzsRight(this.hzsT(p,m.tot + " / " + m.mx,38,cy,15,HZS_WHITE,"sb",0.02));
         var bio:Boolean = m.hasFl || m.hasFa;
         var lw:Number = 0;
         if(bio)
         {
            var done:Boolean = (!m.hasFl || m.bfl) && (!m.hasFa || m.bfa);
            if(done) { this.hzsCheck(g,w - 22,cy,HZS_GRN); } else { this.hzsDash(g,w - 22,cy,HZS_LABEL); }
            lw = this.hzsTw(this.hzsT(p,this.hzsCs("BIOME"),w - 34,cy,13,done ? HZS_GRN : HZS_LABEL,"sb",0.1,"r")) + 18;
         }
         var lim:Number = w - 16 - (bio ? lw + 10 : 0);
         if(fl > 0) { this.hzsT(p,this.hzsCs("SCAN COMPLETE"),e + 14,cy,13,HZS_GRN,"bd",0.1,"l",1,lim - e - 14); }
         else if(m.allFF && (m.hasFl || m.hasFa)) { this.hzsT(p,this.hzsCs("ALL FOUND"),e + 14,cy,13,HZS_GRN,"bd",0.1,"l",1,lim - e - 14); }
         else if(m.left.length > 0)
         {
            // v0.42.0: at TextScale >= 1.1 "N FAUNA LEFT" did not fit and was cut to "N FAU...". Tried in order: both counts,
            // the first one, the first one with tight tracking, the first one without the word LEFT; only then the "..." cut.
            var both:String = (m.left as Array).join("  " + String.fromCharCode(0xB7) + "  ");
            var avail:Number = lim - e - 14;
            var probe:Sprite = new Sprite();
            var one:String = String(m.left[0]);
            var cands:Array = [[both,0.1],[one,0.1],[one,0],[one.replace(/\s+\S+$/,""),0]];
            var pick:Array = null;
            for each(var cd:Array in cands) { if(pick == null && this.hzsTw(this.hzsT(probe,String(cd[0]),0,0,13,HZS_WHITE,"bd",Number(cd[1]))) <= avail) { pick = cd; } }
            if(pick == null) { pick = [one,0]; }
            this.hzsT(p,String(pick[0]),e + 14,cy,13,HZS_WHITE,"bd",Number(pick[1]),"l",1,avail);
         }
         return [w,bh];
      }
      private function hzsDSig(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         var x0:Number = HZS_PAD + 2;
         var iw:Number = w - HZS_PAD - x0;
         var rows:Array = m.rows as Array;
         var h:Number = 44 + rows.length * 48 + 12;
         this.hzsCard(g,w,h,HZS_R_CARD,acc);
         this.hzsSection(p,x0,18,iw,"SIGNALS",m.inr + " " + this.hzsCs("IN RANGE"),acc);
         var yy:Number = 44;
         for each(var r:Object in rows)
         {
            var hl:Boolean = r.hl == true;
            var c:uint = uint(r.col);
            if(hl)
            {
               this.hzsRR(g,x0 - 8,yy,iw + 14,46,10,acc,34 / 255);
               this.hzsRR(g,x0 - 8,yy + 8,3,30,1.5,acc,1);
            }
            var cy:Number = yy + 23;
            this.hzsTile(g,x0 + 16,cy,16,hl ? acc : c,0.47);
            this.hzsIcon(g,String(r.ic),x0 + 16,cy,hl ? acc : c,1);
            var dt:TextField = this.hzsT(p,String(r.d),w - HZS_PAD,cy,16,r.ic == "ship" || r.ic == "vehicle" ? acc : uint(r.dc),"sb",0.02,"r",r.ic == "ship" || r.ic == "vehicle" ? 0.67 : 1);
            var lim:Number = dt.x - (x0 + 42) - 10;
            this.hzsT(p,String(r.n),x0 + 42,cy - 9,14,c != HZS_MUTED || hl ? HZS_WHITE : HZS_LABEL,"sb",0.1,"l",1,lim);
            if(hl) { this.hzsT(p,String(r.sub),x0 + 42,cy + 10,13,acc,"bd",0.1,"l",1,lim); }
            else { this.hzsT(p,String(r.sub),x0 + 42,cy + 10,13,HZS_MUTED,"rg",0,"l",1,lim); }
            yy += 48;
         }
         return [w,h];
      }
      private function hzsDSigC(p:Sprite, m:Object) : Array
      {
         if(m.near == null) { return null; }
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         this.hzsCard(g,w,44,HZS_R_STRIP,acc);
         var c:uint = m.near.hl ? acc : HZS_LABEL;
         this.hzsIcon(g,"hex",24,22,c);
         var dt:TextField = this.hzsT(p,String(m.near.d),w - 16,22,16,acc,"sb",0.02,"r");
         this.hzsT(p,String(m.near.n),40,22,13,c,"bd",0.1,"l",1,dt.x - 50);
         return [w,44];
      }
      // chips "Fe Iron" in rows; wraps inside the column
      private function hzsResRows(p:Sprite, x0:Number, y:Number, iw:Number, res:Array) : Number
      {
         var g:* = p.graphics;
         var yy:Number = y;
         // 0.42.0.4: the rarity column fits the widest label shown (96 - 130; the 13 px floor makes it wider at small sizes)
         var col:Number = 96;
         var probe:Sprite = new Sprite();
         for each(var r0:Object in res) { var ri0:int = int(r0.r); col = Math.max(col,Math.ceil(this.hzsTw(this.hzsT(probe,this.hzsCs(ri0 < 0 ? "SPECIAL" : String(HZS_RAR_N[ri0])),0,0,13,HZS_WHITE,"sb",0.08))) + 10); }
         col = Math.min(130,col);
         for each(var r:Object in res)
         {
            var ri:int = int(r.r);
            var c:uint = ri < 0 ? HZS_WHITE : uint(HZS_RAR_C[ri]);
            this.hzsT(p,this.hzsCs(ri < 0 ? "SPECIAL" : String(HZS_RAR_N[ri])),x0,yy,13,c,"sb",0.08,"l",1,col - 6);
            var cx:Number = x0 + col;
            for each(var it:Array in r.items)
            {
               var dis:Boolean = int(it[2]) == 1;
               var cc:uint = dis ? HZS_MUTED : c;
               var st:TextField = this.hzsT(p,String(it[0]),0,yy,13,cc,"bd",0,"l",1,60);
               var sw:Number = Math.max(26,this.hzsTw(st) + 10);
               var nt:TextField = this.hzsT(p,String(it[1]),0,yy,13,dis ? HZS_MUTED : HZS_LABEL,"rg",0,"l",1,180);
               var need:Number = sw + 5 + this.hzsTw(nt);
               if(cx > x0 + col && cx + need > x0 + iw) { yy += 28; cx = x0 + col; st.y = Math.round(yy - st.height / 2); nt.y = Math.round(yy - nt.height / 2); }
               g.lineStyle(1.2,cc,0.67,true); g.beginFill(cc,34 / 255); g.drawRoundRect(cx,yy - 11,sw,22,12,12); g.endFill(); g.lineStyle();
               st.x = Math.round(cx + sw / 2 - this.hzsTw(st) / 2 - 2);
               nt.x = Math.round(cx + sw + 5 - 2);
               cx = this.hzsRight(nt) + 12;
            }
            yy += 32;
         }
         return yy;
      }
      private function hzsDTraits(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         var x0:Number = HZS_PAD + 2;
         var iw:Number = w - HZS_PAD - x0;
         // measure first in a scratch sprite (rows may wrap)
         var scratch:Sprite = new Sprite();
         var hasT:Boolean = int(m.n) > 0 || m.sites != null;
         var ry:Number = hasT ? 96 : 18;
         var end:Number = this.hzsResRows(scratch,x0,ry + 26,iw,m.res as Array);
         var h:Number = m.res.length > 0 ? end - 26 + 20 : ry + 20;
         if(!hasT && m.res.length == 0) { return null; }
         this.hzsCard(g,w,h,HZS_R_CARD,acc);
         this.hzs41Pulse(p,w,h,HZS_R_CARD,Number(m.pl),acc);
         if(hasT)
         {
            this.hzsSection(p,x0,18,iw,"TRAITS",int(m.n) > 0 ? m.k + " / " + m.n + " " + this.hzsCs("FOUND") : null,acc);
            var tx:Number = x0 + 16;
            var nt:int = Math.min(6,m.tiles.length);
            var i:int = 0;
            while(i < nt)
            {
               if(int(m.tiles[i]) == 1) { this.hzsTile(g,tx,52,16,HZS_GRN,0.51); this.hzsIcon(g,"trait",tx,52,HZS_GRN); }
               else { this.hzsTile(g,tx,52,16,HZS_MUTED,0.35); this.hzsT(p,"?",tx,52,15,HZS_MUTED,"bd",0,"c"); }
               tx += 38;
               i++;
            }
            if(m.sites != null)
            {
               var sx:Number = nt > 0 ? tx - 8 : x0;
               this.hzsT(p,this.hzsCs("TRAIT SITES"),sx,44,13,HZS_MUTED,"sb",0.1,"l",1,w - HZS_PAD - sx);
               this.hzsT(p,m.sites[0] + " / " + m.sites[1] + " " + this.hzsCs("SCANNED"),sx,62,14,HZS_WHITE,"sb",0.04,"l",1,w - HZS_PAD - sx);
            }
         }
         this.hzsSection(p,x0,ry,iw,"RESOURCES",String(m.lbl),acc);
         if(m.res.length > 0) { this.hzsResRows(p,x0,ry + 26,iw,m.res as Array); }
         return [w,h];
      }
      private function hzsDTraitsC(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         this.hzsCard(g,w,44,HZS_R_STRIP,acc);
         this.hzs41Pulse(p,w,44,HZS_R_STRIP,Number(m.pl),acc);
         var rt:TextField = int(m.n) > 0 ? this.hzsT(p,this.hzsCs("TRAITS") + " " + m.k + " / " + m.n,w - 16,22,13,HZS_LABEL,"sb",0.08,"r") : null;
         var lim:Number = rt != null ? rt.x - 8 : w - 16;
         var x:Number = this.hzsRight(this.hzsT(p,this.hzsCs("RESOURCES"),16,22,13,acc,"sb",0.14)) + 14;
         var i:int = 0;
         while(i < m.counts.length)
         {
            var n:int = int(m.counts[i]);
            if(n > 0 && x + 30 < lim)
            {
               g.beginFill(uint(HZS_RAR_C[i]),1); g.drawCircle(x + 5,22,5); g.endFill();
               x = this.hzsRight(this.hzsT(p,String(n),x + 15,22,14,HZS_WHITE)) + 14;
            }
            i++;
         }
         return [w,44];
      }
      private function hzsDSocial(p:Sprite, m:Object) : Array
      {
         var g:* = p.graphics;
         var acc:uint = this.hzsAccent();
         var w:Number = HZS_CW;
         var x0:Number = HZS_PAD + 2;
         var iw:Number = w - HZS_PAD - x0;
         var rows:Array = m.rows as Array;
         var b:Object = m.b;
         if(m.note != null)
         {
            this.hzsCard(g,w,52,HZS_R_STRIP,-1,acc,100 / 255);
            this.hzsT(p,this.hzsCs("PERSON"),x0,26,13,acc,"sb",0.1);
            this.hzsT(p,String(m.note),w - HZS_PAD,26,13,HZS_LABEL,"rg",0.02,"r",1,iw - 70);
            return [w,52];
         }
         var yy:Number = 46 + rows.length * 32;
         var by:Number = rows.length > 0 ? yy + 14 : 26;
         var h:Number = b != null ? by + 44 - (rows.length > 0 ? 0 : 18) : yy - 6;
         this.hzsCard(g,w,h,HZS_R_CARD,b != null ? HZS_AMB : acc);
         if(rows.length > 0)
         {
            this.hzsSection(p,x0,18,iw,"SOCIAL SKILLS",String(rows.length),acc);
            var y:Number = 46;
            for each(var r:Array in rows)
            {
               var sel:Boolean = int(r[3]) == 1;
               var a:Number = int(r[1]) == 0 ? 0.5 : 1;
               if(sel)
               {
                  this.hzsRR(g,x0 - 8,y - 14,iw + 14,28,9,acc,34 / 255);
                  this.hzsRR(g,x0 - 8,y - 9,3,18,1.5,acc,1);
               }
               var rt:TextField = this.hzsT(p,int(r[1]) + "%" + (int(r[2]) > 0 ? "  " + String.fromCharCode(0xB7) + "  " + this.hzsDur(int(r[2])) : ""),w - HZS_PAD,y,14,sel ? acc : HZS_MUTED,"sb",0.04,"r",a);
               this.hzsT(p,this.hzsGs(String(r[0])),x0 + 4,y,14,sel ? HZS_WHITE : HZS_LABEL,"sb",0.1,"l",a,rt.x - x0 - 14);
               y += 32;
            }
            if(b != null) { g.beginFill(0xFFFFFF,0.086); g.drawRect(x0,yy - 10,iw,1); g.endFill(); }
         }
         if(b != null)
         {
            if(int(b.acc) == 1)
            {
               this.hzsT(p,this.hzsCs("BOUNTY ACCEPTED"),x0,by,14,HZS_AMB,"bd",0.12);
               if(String(b.amt).length > 0) { this.hzsT(p,String(b.amt),w - HZS_PAD,by,15,HZS_AMB,"sb",0.04,"r"); }
            }
            else
            {
               var rx:Number = w - HZS_PAD;
               if(String(b.key).length > 0)
               {
                  var lt:TextField = this.hzsT(p,this.hzsGs(String(b.lab)),w - HZS_PAD,by,14,HZS_WHITE,"sb",0.14,"r",1,120);
                  var kw:TextField = this.hzsT(p,String(b.key),0,by,13,HZS_AMB,"bd",0.08,"l",1,0,b.font != null ? String(b.font) : null);
                  var kcw:Number = Math.max(26,this.hzsTw(kw) + 16);
                  p.removeChild(kw);
                  rx = this.hzsKeycap(p,lt.x - 10 - kcw,by,String(b.key),HZS_AMB,false,b.font != null ? String(b.font) : null) - kcw - 10;
               }
               var e:Number = this.hzsRight(this.hzsT(p,this.hzsCs("BOUNTY"),x0,by,13,HZS_AMB,"bd",0.14));
               if(String(b.amt).length > 0) { this.hzsT(p,String(b.amt),e + 12,by,17,HZS_AMB,"bd",0.02,"l",1,rx - e - 22); }
            }
         }
         return [w,h];
      }
      // the strip panels: measure first, then the card, then the content (graphics render under children)
      private function hzsDMode2(p:Sprite, m:Object) : Array
      {
         var acc:uint = this.hzsAccent();
         var probe:Sprite = new Sprite();
         var e:Number = this.hzsRight(this.hzsT(probe,String(m.m),36,16,14,acc,"bd",0.16));
         var w:Number = this.hzsRight(this.hzsT(probe,String(m.a),e + 24,16,13,HZS_MUTED,"sb",0.12)) + 20;
         var g:* = p.graphics;
         this.hzsCard(g,w,32,HZS_R_SMALL,-1);
         g.lineStyle(1.6,acc,1,true); g.drawCircle(20,16,7); g.lineStyle();
         g.beginFill(acc,1); g.drawCircle(20,16,3); g.endFill();
         g.beginFill(0xFFFFFF,0.2); g.drawRect(e + 12,8,1,16); g.endFill();
         this.hzsT(p,String(m.m),36,16,14,acc,"bd",0.16);
         this.hzsT(p,String(m.a),e + 24,16,13,HZS_MUTED,"sb",0.12);
         return [w,32];
      }
      private function hzsDHints2(p:Sprite, m:Object) : Array
      {
         var acc:uint = this.hzsAccent();
         var probe:Sprite = new Sprite();
         var x:Number = 16;
         for each(var h0:Object in m.h)
         {
            x = this.hzsKeycap(probe,x,20,String(h0.k),acc,int(h0.en) != 1,h0.f != null ? String(h0.f) : null) + 8;
            x = this.hzsRight(this.hzsT(probe,String(h0.l),x,20,14,HZS_LABEL,"sb",0.14,"l",1,220)) + 22;
         }
         var w:Number = x - 22 + 16;
         this.hzsCard(p.graphics,w,40,HZS_R_STRIP,-1);
         x = 16;
         for each(var h:Object in m.h)
         {
            var dis:Boolean = int(h.en) != 1;
            x = this.hzsKeycap(p,x,20,String(h.k),acc,dis,h.f != null ? String(h.f) : null) + 8;
            x = this.hzsRight(this.hzsT(p,String(h.l),x,20,14,HZS_LABEL,"sb",0.14,"l",dis ? 0.63 : 1,220)) + 22;
         }
         return [w,40];
      }

      // ---------------------------------------------------------------- compass + heading
      private function hzsDrawCompassIfMoved(force:Boolean = false) : void
      {
         var p:Sprite = this.hzsP.Compass as Sprite;
         var hp:Sprite = this.hzsP.Head as Sprite;
         if(p == null || hp == null) { return; }
         var on:Boolean = this.hzsOn("ScanShowCompass") && this.hzsGot.cmp == 1 && !isNaN(this.hzsHead);
         var head:Number = on ? Math.round(this.hzsHead * 2) / 2 : -1;
         var sig:String = head + "|" + this.hzsCfgSig + "|" + this.hzsVrSig + "|" + this.hzsCmpMarks();
         if(!force && sig == this.hzsCmpSig) { return; }
         this.hzsCmpSig = sig;
         this.hzsClr(p);
         this.hzsClr(hp);
         if(!on) { p.visible = false; hp.visible = false; this.hzsSz.Compass = null; this.hzsSz.Head = null; this.hzsPlace(); return; }
         var cmp:Boolean = this.hzsCmpOn("Compass");
         var acc:uint = this.hzsAccent();
         this.hzsTk = this.hzsK("Compass");   // 0.42.0.4: compass + heading pill (both drawn at the compass scale)
         var wd:Number = 640;
         var hh:Number = cmp ? 46 : 58;
         var g:* = p.graphics;
         this.hzsCard(g,wd,hh,HZS_R_STRIP,-1);
         var span:Number = 90;
         var ppd:Number = (wd - 40) / (2 * span);
         var cx:Number = wd / 2;
         var ty:Number = cmp ? hh - 17 : hh - 24;
         var a:int = 0;
         while(a < 360)
         {
            var dl:Number = (a - head + 540) % 360 - 180;
            if(Math.abs(dl) <= span)
            {
               var xx:Number = cx + dl * ppd;
               var fade:Number = Math.pow(Math.max(0,1 - Math.abs(xx - cx) / (wd / 2 - 14)),0.6);
               var maj:Boolean = a % 45 == 0;
               var mid:Boolean = a % 15 == 0;
               if(!cmp || mid)
               {
                  var L:Number = maj ? 9 : (mid ? 6 : 3);
                  if(cmp) { L = Math.min(L,6); }
                  g.lineStyle(maj ? 1.6 : 1.1,0xFFFFFF,(maj ? 220 : (mid ? 120 : 70)) / 255 * fade,true);
                  g.moveTo(xx,ty); g.lineTo(xx,ty + L);
                  g.lineStyle();
               }
               if(maj && fade > 0.15)
               {
                  var lb:String = ["N","NE","E","SE","S","SW","W","NW"][a / 45];
                  var big:Boolean = lb.length == 1;
                  this.hzsT(p,lb,xx,cmp ? 17 : 18,big ? 16 : 13,0xFFFFFF,big ? "sb" : "rg",0,"c",(big ? 250 : 170) / 255 * fade);
               }
            }
            a += 5;
         }
         if(!cmp)
         {
            for each(var mk:Array in this.hzsCmpMarkList())
            {
               var md:Number = (Number(mk[0]) - head + 540) % 360 - 180;
               if(Math.abs(md) > span) { continue; }
               var mx:Number = cx + md * ppd;
               if(mk[1] == "ship") { this.hzsIcon(g,"ship",mx,hh - 10,HZS_O2B,0.6); }
               else if(mk[1] == "ship2") { this.hzsIcon(g,"ship",mx,hh - 10,HZS_VIO,0.6); }   // v0.41.0: a companion's ship
               else if(mk[1] == "shipn") { this.hzsIcon(g,"ship",mx,hh - 10,HZS_MUTED,0.6); }   // r2: a ship in doubt (neutral)
               else if(mk[1] == "vehicle") { this.hzsIcon(g,"vehicle",mx,hh - 10,HZS_O2B,0.8); }
               else { this.hzsIcon(g,"qdiamond",mx,hh - 10,HZS_QST,0.75); }   // v0.41.0: gold
            }
         }
         g.beginFill(acc,1); g.moveTo(cx - 6,0); g.lineTo(cx + 6,0); g.lineTo(cx,7); g.lineTo(cx - 6,0); g.endFill();
         this.hzsSz.Compass = [wd,hh];
         p.visible = true;
         // heading pill
         var probe:Sprite = new Sprite();
         var txt:String = String(int(Math.round(head)) % 360) + String.fromCharCode(0xB0);
         var w:Number = this.hzsTw(this.hzsT(probe,txt,0,14,14,HZS_WHITE,"sb",0.06)) + 28;
         this.hzsCard(hp.graphics,w,28,HZS_R_STRIP,-1);
         this.hzsT(hp,txt,w / 2,14,14,HZS_WHITE,"sb",0.06,"c");
         this.hzsTk = 1;
         this.hzsSz.Head = [w,28];
         hp.visible = true;
         this.hzsPlace();
      }
      // compass marks: quest targets and the player's ship (absolute heading in degrees)
      private function hzsCmpMarkList() : Array
      {
         var out:Array = [];
         try
         {
            if(this.hzsCmp == null) { return out; }
            for each(var o:Object in this.hzsCmp.aMissionMarkers)
            {
               if(o == null || o.fHeading == undefined || uint(o.uiMarkerIconType) == MapMarkerUtils.MIT_MARKER_QUEST_OFFPLANET) { continue; }
               out.push([(Number(o.fHeading) * 180 / Math.PI + 360) % 360,"quest"]);
            }
            var mine:Object = this.hzs41MyShip();
            var veh:Object = this.hzs41MyVeh();
            for each(var s:Object in this.hzs41CmpAll())   // r4: every compass list (your ship can ride in the mission list)
            {
               if(s == null || s.fHeading == undefined || !this.hzsOn("ScanShowShip")) { continue; }
               var hd:Number = (Number(s.fHeading) * 180 / Math.PI + 360) % 360;
               if(s === mine) { out.push([hd,"ship"]); }
               else if(s === veh) { out.push([hd,"vehicle"]); }   // r4: no map-type companion ship (other ships are neutral)
               else if(this.hzs41IsShip(s)) { out.push([hd,"shipn"]); }   // r2: any other ship: neutral (never claimed "not yours")
            }
         }
         catch(e:Error) { }
         return out;
      }
      private function hzsCmpMarks() : String
      {
         var a:Array = [];
         for each(var m:Array in this.hzsCmpMarkList()) { a.push(Math.round(Number(m[0])) + m[1]); }
         return a.join(",");
      }

      // ---------------------------------------------------------------- reticle, frame, range, world tag
      private function hzsCenter() : Point
      {
         return new Point(this.hzsVr.x + this.hzsVr.width / 2,this.hzsVr.y + this.hzsVr.height / 2);
      }
      private function hzsDrawRet() : void
      {
         var p:Sprite = this.hzsP.Ret as Sprite;
         var fr:Sprite = this.hzsP.Frame as Sprite;
         if(p == null || fr == null) { return; }
         var rng:String = "";
         try
         {
            if(this.hzsFD != null && int(this.hzsFD.iScanDistance) > 0 && uint(this.CurrentPickRefType) != this.PICK_TYPE_NONE) { rng = this.hzsCs("RANGE") + " " + this.hzsDist(Number(this.hzsFD.iScanDistance)).toUpperCase(); }
         }
         catch(e0:Error) { rng = ""; }
         var tag:Object = null;
         try { tag = this.hzsMTag(); } catch(e1:Error) { tag = null; }
         var sig:String = rng + "|" + this.hzsSer(tag) + "|" + this.hzsCfgSig + "|" + this.hzsVrSig;
         if(sig == this.hzsRetSig) { return; }
         this.hzsRetSig = sig;
         var acc:uint = this.hzsAccent();
         var c:Point = this.hzsCenter();
         // corner frame
         this.hzsClr(fr);
         var fg:* = fr.graphics;
         var L:Number = 46;
         for each(var q:Array in [[18,18,1,1],[-18,18,-1,1],[18,-18,1,-1],[-18,-18,-1,-1]])
         {
            var fx:Number = q[0] > 0 ? this.hzsVr.left + q[0] : this.hzsVr.right + q[0];
            var fy:Number = q[1] > 0 ? this.hzsVr.top + q[1] : this.hzsVr.bottom + q[1];
            fg.lineStyle(2,acc,120 / 255,true);
            fg.moveTo(fx,fy + q[3] * L); fg.lineTo(fx,fy); fg.lineTo(fx + q[2] * L,fy);
            fg.lineStyle();
         }
         fr.visible = true;
         // reticle
         this.hzsClr(p);
         var g:* = p.graphics;
         var k:Number = HZS_SCALE;
         g.lineStyle(1.4,0xFFFFFF,90 / 255,true); g.drawCircle(c.x,c.y,40 * k); g.lineStyle();
         for each(var a0:Number in [40,130,220,310])
         {
            g.lineStyle(2,acc,200 / 255,true);
            var st:int = 0;
            while(st <= 8)
            {
               var an:Number = (a0 + st * 5) * Math.PI / 180;
               var ax:Number = c.x + 52 * k * Math.cos(an);
               var ay:Number = c.y + 52 * k * Math.sin(an);
               if(st == 0) { g.moveTo(ax,ay); } else { g.lineTo(ax,ay); }
               st++;
            }
            g.lineStyle();
         }
         for each(var d:Array in [[-14,0],[14,0],[0,-14],[0,14]])
         {
            g.lineStyle(1.6,0xFFFFFF,1,true); g.moveTo(c.x + d[0] * 0.45 * k,c.y + d[1] * 0.45 * k); g.lineTo(c.x + d[0] * k,c.y + d[1] * k); g.lineStyle();
         }
         g.beginFill(0xFFFFFF,1); g.drawCircle(c.x,c.y,1.6); g.endFill();
         if(rng.length > 0)
         {
            var rp:Sprite = new Sprite();
            var probe:Sprite = new Sprite();
            var w:Number = this.hzsTw(this.hzsT(probe,rng,0,14,13,HZS_LABEL,"sb",0.06)) + 28;
            this.hzsCard(rp.graphics,w,28,HZS_R_STRIP,-1);
            this.hzsT(rp,rng,w / 2,14,13,HZS_LABEL,"sb",0.06,"c");
            rp.scaleX = rp.scaleY = k;
            rp.x = Math.round(c.x - w * k / 2);
            rp.y = Math.round(c.y + 88 * k);
            p.addChild(rp);
         }
         p.visible = true;
         // world tag
         var tp:Sprite = this.hzsP.Tag as Sprite;
         this.hzsClr(tp);
         if(tag == null) { tp.visible = false; return; }
         var tk:Number = this.hzsK("WorldTag");   // 0.42.0.4: = HZS_SCALE x hzsF, never under HZS_KMIN
         this.hzsTk = tk;   // 0.42.0.4: world tag text floor after its scale
         var tc:uint = uint(tag.col);
         var tw:Number = 250;
         var tg:* = tp.graphics;
         this.hzsCard(tg,tw,52,HZS_R_STRIP,-1,tc,100 / 255);
         var tx:Number = 14;
         if(String(tag.sym).length > 0)
         {
            tg.lineStyle(1.2,tc,180 / 255,true); tg.beginFill(tc,40 / 255); tg.drawRoundRect(12,13,34,26,12,12); tg.endFill(); tg.lineStyle();
            this.hzsT(tp,String(tag.sym),29,26,14,tc,"bd",0,"c",1,32);
            tx = 58;
         }
         var dt:TextField = String(tag.d).length > 0 ? this.hzsT(tp,String(tag.d),tw - 14,26,15,acc,"sb",0.02,"r") : null;
         var lim:Number = (dt != null ? dt.x - 8 : tw - 14) - tx;
         this.hzsT(tp,String(tag.n),tx,String(tag.sub).length > 0 ? 17 : 26,15,HZS_WHITE,"sb",0.12,"l",1,lim);
         if(String(tag.sub).length > 0) { this.hzsT(tp,String(tag.sub),tx,36,13,HZS_MUTED,"rg",0,"l",1,lim); }
         if(String(tag.flg).length > 0)
         {
            var fx0:Number = 0;
            for each(var fw:String in String(tag.flg).split(","))
            {
               var fcol:uint = fw == "TAGGED" ? acc : (fw == "DEAD" ? HZS_MUTED : (fw == "DISEASED" ? HZS_AMB : HZS_RED));
               var ft:TextField = this.hzsT(tp,this.hzsCs(fw),fx0 + 12,-15,13,fcol,"bd",0.12);
               var fcw:Number = this.hzsTw(ft) + 24;
               this.hzsRR(tg,fx0,-28,fcw,26,13,fcol,46 / 255);
               fx0 += fcw + 6;
            }
         }
         this.hzsTk = 1;
         tp.scaleX = tp.scaleY = tk;
         tp.x = Math.round(Math.max(this.hzsVr.left + 8,c.x - 370 * k));
         tp.y = Math.round(c.y + 34 * k);
         // leader from the tag to the reticle ring
         g.lineStyle(1.4,tc,200 / 255,true);
         g.moveTo(tp.x + tw * tk + 2,tp.y + 26 * tk); g.lineTo(c.x - 44 * k,c.y + 18 * k);
         g.lineStyle();
         tp.visible = true;
      }

      // ---------------------------------------------------------------- POI markers in the world view
      private function hzsDrawMarks() : void
      {
         var p:Sprite = this.hzsP.Marks as Sprite;
         if(p == null) { return; }
         var list:Array = [];
         if(this.hzsOn("ScanShowWorldTags") && this.hzsOn("ScanWorldMarkers") && this.hzsFD != null && this.hzsFD.aScannableMarkers is Array)
         {
            var hold:DisplayObject = null;
            try { hold = this.ScanMapMarkerHolder_mc as DisplayObject; } catch(e0:Error) { hold = null; }
            for each(var o:Object in this.hzsFD.aScannableMarkers)
            {
               if(o == null) { continue; }
               var fx:Number = Number(o.fScreenXPct);
               var fy:Number = Number(o.fScreenYPct);
               if(isNaN(fx) || isNaN(fy) || fx < 0 || fx > 1 || fy < 0 || fy > 1) { continue; }
               var lp:Point = new Point((fx - 0.5) * stage.stageWidth,(fy - 0.5) * stage.stageHeight);
               var gp:Point = hold != null ? hold.localToGlobal(lp) : new Point(fx * stage.stageWidth,fy * stage.stageHeight);
               var pp:Point = this.hzsL.globalToLocal(gp);
               // v0.40.3: not drawn within 24 px of the visible edge (it would be cut off)
               if(this.hzsVr != null && (pp.x < this.hzsVr.left + 24 || pp.x > this.hzsVr.right - 24 || pp.y < this.hzsVr.top + 24 || pp.y > this.hzsVr.bottom - 24)) { continue; }
               list.push([Math.round(pp.x),Math.round(pp.y),o.bIsDiscovered === true ? 1 : 0,this.hzsDist(Number(o.uRangeM)),o.bIsDiscovered === true ? this.hzsMarkName(o) : "",this.hzsMarkIcon(o),this.hzs41Own(o)]);
            }
         }
         var sig:String = this.hzsSer(list) + "|" + this.hzsCfgSig;
         if(sig == this.hzsMarkSig) { return; }
         this.hzsMarkSig = sig;
         this.hzsClr(p);
         if(list.length == 0) { p.visible = false; return; }
         var acc:uint = this.hzsAccent();
         var g:* = p.graphics;
         var named:int = 0;
         for each(var m:Array in list)
         {
            var c:uint = int(m[2]) == 1 ? acc : HZS_MUTED;
            if(String(m[5]) == "ship" || String(m[5]) == "vehicle") { c = String(m[6]) == "mine" ? HZS_O2B : (String(m[6]) == "other" ? HZS_VIO : c); this.hzsIcon(g,String(m[5]),m[0],m[1],c,1.15); }   // r2: yours blue, a companion's violet, in doubt the normal color
            else { this.hzsIcon(g,"hex",m[0],m[1],c,1.15); g.beginFill(c,1); g.drawCircle(m[0],m[1],2.5); g.endFill(); }
            this.hzsT(p,String(m[3]),m[0],m[1] + 22,13,c,"sb",0.04,"c");
            if(String(m[4]).length > 0 && named < 3)
            {
               named++;
               var probe:Sprite = new Sprite();
               var w:Number = this.hzsTw(this.hzsT(probe,String(m[4]),0,0,14,HZS_WHITE,"sb",0.12,"l",1,260)) + 28;
               g.lineStyle(1,c,120 / 255,true); g.beginFill(HZS_BG,200 / 255); g.drawRoundRect(m[0] + 16,m[1] - 13,w,26,26,26); g.endFill(); g.lineStyle();
               this.hzsT(p,String(m[4]),m[0] + 30,m[1],14,HZS_WHITE,"sb",0.12,"l",1,260);
            }
         }
         p.visible = true;
      }

      // ---------------------------------------------------------------- layout
      private function hzsDrawAll() : void
      {
         for each(var n:String in ["Planet","Bioscan","Signals","Traits","Social","Mode","Hints"]) { this.hzsDrawPanel(n); }
         this.hzsDrawCompassIfMoved();
         this.hzsPlace();
      }
      // r5: the person strip has its own keys (ScanSocialX / Y / Scale); -1 = the traits card's (it is shown instead of that card)
      private function hzsKeyOf(n:String) : String { return n; }
      private function hzsAt(n:String, dx:Number, dy:Number) : void
      {
         var p:Sprite = this.hzsP[n] as Sprite;
         var sz:Array = this.hzsSz[n] as Array;
         if(p == null || sz == null) { return; }
         var kn:String = this.hzsKeyOf(n);
         var k:Number = n == "Head" ? this.hzsK("Compass") : this.hzsK(kn);
         var w:Number = sz[0] * k;
         var h:Number = sz[1] * k;
         var x:Number = dx;
         var y:Number = dy;
         var M:Number = this.hzsMargin();
         var vr:Rectangle = this.hzsVr;
         var ccx:Number = vr.x + vr.width / 2;
         var ccy:Number = vr.y + vr.height / 2;
         if(n != "Head")
         {
            var px:String = String(this.hzsC["Scan" + kn + "X"]);
            var py:String = String(this.hzsC["Scan" + kn + "Y"]);
            if(kn == "Social") { if(px == "-1") { px = String(this.hzsC.ScanTraitsX); } if(py == "-1") { py = String(this.hzsC.ScanTraitsY); } }   // r5
            var cust:Boolean = false;
            if(px != "-1" && px.length > 1)
            {
               var nx:Number = Number(px.substr(1));
               var ax:String = px.charAt(0);
               x = ax == "L" ? vr.left + M + nx : (ax == "R" ? vr.right - M - nx - w : ccx - w / 2 + nx);
               cust = true;
            }
            if(py != "-1" && py.length > 1)
            {
               var ny:Number = Number(py.substr(1));
               var ay:String = py.charAt(0);
               y = ay == "T" ? vr.top + M + ny : (ay == "B" ? vr.bottom - M - ny - h : ccy - h / 2 + ny);
               cust = true;
            }
            if(cust)
            {
               var x0:Number = vr.left + M;
               var x1:Number = vr.right - M - w;
               var y0:Number = vr.top + M;
               var y1:Number = vr.bottom - M - h;
               if(x1 >= x0) { x = Math.max(x0,Math.min(x1,x)); }
               if(y1 >= y0) { y = Math.max(y0,Math.min(y1,y)); }
            }
         }
         p.scaleX = p.scaleY = k;
         p.x = Math.round(x);
         p.y = Math.round(y);
      }
      private function hzsPlace() : void
      {
         if(this.hzsVr == null) { return; }
         var vr:Rectangle = this.hzsVr;
         var M:Number = this.hzsMargin();
         var cx:Number = vr.x + vr.width / 2;
         var y:Number = vr.bottom - M;
         var sz:Array;
         var k:Number;
         for each(var l:String in ["Bioscan","Planet"])
         {
            sz = this.hzsSz[l] as Array;
            if(sz == null) { continue; }
            k = this.hzsK(l);
            y -= sz[1] * k;
            this.hzsAt(l,vr.left + M,y);
            y -= HZS_GAP * k;
         }
         y = vr.bottom - M;
         var right:Array = [this.hzsSz.Social != null ? "Social" : "Traits","Signals"];
         for each(var r:String in right)
         {
            sz = this.hzsSz[r] as Array;
            if(sz == null) { continue; }
            k = this.hzsK(this.hzsKeyOf(r));
            y -= sz[1] * k;
            this.hzsAt(r,vr.right - M - sz[0] * k,y);
            y -= HZS_GAP * k;
         }
         if(this.hzsSz.Social == null) { (this.hzsP.Social as Sprite).visible = false; }
         if(this.hzsSz.Social != null) { (this.hzsP.Traits as Sprite).visible = false; }
         y = vr.top + 36;
         sz = this.hzsSz.Compass as Array;
         if(sz != null)
         {
            k = this.hzsK("Compass");
            this.hzsAt("Compass",cx - sz[0] * k / 2,y);
            var cp:Sprite = this.hzsP.Compass as Sprite;
            var hs:Array = this.hzsSz.Head as Array;
            if(hs != null) { this.hzsAt("Head",cp.x + sz[0] * k / 2 - hs[0] * k / 2,cp.y + (sz[1] + 6) * k); }
            y += (sz[1] + 6 + 28 + 10) * k;
         }
         sz = this.hzsSz.Mode as Array;
         if(sz != null)
         {
            k = this.hzsK("Mode");
            this.hzsAt("Mode",cx - sz[0] * k / 2,y);
            y += (sz[1] + 12) * k;
         }
         sz = this.hzsSz.Hints as Array;
         if(sz != null)
         {
            k = this.hzsK("Hints");
            this.hzsAt("Hints",cx - sz[0] * k / 2,y);
         }
      }


      // =================== v0.37 shared settings reader (hzs37) ===================
      // ONE helper, spliced into every movie that reads the settings (hudmenu + hudmenu_lrg as hz37, hudmessagesmenu
      // x2 as hzc37, dialoguemenu x2 as hzd37; generated from /workspace/v037/work/hzini_shared.as, so the copies are
      // identical apart from the prefix). It reads HorizonUI.default.ini, HorizonUI.user.ini, HorizonUI.state.ini and the
      // legacy HorizonUI.ini (paths relative to Data/Interface) one after the other and hands every waiting callback the
      // merged text: the defaults with user.ini laid over (hzs37Compose; mirrors HZF::Compose in HorizonUI.dll). A missing
      // file is normal: its IOErrorEvent is caught and simply counts as "no file" (nothing is thrown or logged).
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hzs37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hzs37_BOM:String = String.fromCharCode(0xFEFF);
      private var hzs37Ldr:URLLoader = null;
      private var hzs37Step:int = 0;          // 0 idle, n = reading hzs37_FILES[n - 1]
      private var hzs37T0:Number = 0;
      private var hzs37Got:Array = null;
      private var hzs37Q:Array = [];          // callbacks of the running read
      private var hzs37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private function hzs37Ws(c:String) : Boolean { return c == " " || c == "\t" || c == "\r" || c == "\n"; }
      private function hzs37Trim(s:String) : String
      {
         var b:int = 0;
         var e:int = s.length;
         while(b < e && (this.hzs37Ws(s.charAt(b)) || s.charAt(b) == hzs37_BOM)) { b++; }
         while(e > b && this.hzs37Ws(s.charAt(e - 1))) { e--; }
         return s.substring(b,e);
      }
      private function hzs37Blank(s:String) : Boolean { return this.hzs37Trim(s).length == 0; }
      private function hzs37Lines(t:String) : Array
      {
         var out:Array = [];
         if(t == null || t.length == 0) { return out; }
         if(t.charAt(0) == hzs37_BOM) { t = t.substr(1); }
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
      private function hzs37Hdr(ln:String) : String
      {
         var t:String = this.hzs37Trim(ln);
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return this.hzs37Trim(t.substring(1,e)).toLowerCase();
      }
      private function hzs37Alias(n:String) : String
      {
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // key=value line -> {k: key lower case without blanks, o: key as written, v: value up to ';'}; null otherwise
      private function hzs37KV(ln:String) : Object
      {
         var t:String = this.hzs37Trim(ln);
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         var o:String = this.hzs37Trim(t.substr(0,eq));
         var k:String = o.split(" ").join("").split("\t").join("").toLowerCase();
         if(k.length == 0) { return null; }
         var v:String = t.substr(eq + 1);
         var sc:int = v.indexOf(";");
         if(sc >= 0) { v = v.substr(0,sc); }
         return {"k":k,"o":o,"v":this.hzs37Trim(v)};
      }
      // sections; a second copy / the pre-v0.31 name merges into the first, old names first so the new name wins
      private function hzs37Parse(t:String) : Object
      {
         var d:Object = {"secs":[{"n":"","raw":[],"order":[],"kv":{}}],"idx":{"s_":0}};
         var lines:Array = this.hzs37Lines(t);
         var pass:int = 0;
         while(pass < 2)
         {
            var cur:Object = d.secs[0];
            var old:Boolean = false;
            for each(var ln:String in lines)
            {
               var h:String = this.hzs37Hdr(ln);
               if(h != null)
               {
                  old = h == "cards v0.26" || h == "effects v0.26";
                  var n:String = this.hzs37Alias(h);
                  if((pass == 0) != old) { cur = null; continue; }
                  if(d.idx["s_" + n] == undefined) { d.idx["s_" + n] = d.secs.length; d.secs.push({"n":n,"raw":[],"order":[],"kv":{}}); }
                  cur = d.secs[int(d.idx["s_" + n])];
                  cur.raw.push(ln);
                  continue;
               }
               if(cur == null) { continue; }
               if(pass == 0 && cur.n == "") { continue; }
               cur.raw.push(ln);
               var kv:Object = this.hzs37KV(ln);
               if(kv == null) { continue; }
               if(cur.kv["k_" + kv.k] == undefined) { cur.order.push(kv.k); }
               cur.kv["k_" + kv.k] = [kv.o,kv.v];
            }
            pass++;
         }
         return d;
      }
      private function hzs37SecOf(d:Object, kl:String) : String
      {
         for each(var s:Object in d.secs) { if(s.n != "" && s.kv["k_" + kl] != undefined) { return String(s.n); } }
         return "";
      }
      private function hzs37Flush(out:Array, sec:String, U:Object, ext:Object, flushed:Object) : void
      {
         if(sec == "" || flushed["s_" + sec] == true) { return; }
         flushed["s_" + sec] = true;
         var e:Array = ext["s_" + sec];
         if(e == null || e.length == 0) { return; }
         var blanks:int = 0;
         while(out.length > 0 && this.hzs37Blank(String(out[out.length - 1]))) { out.pop(); blanks++; }
         for each(var k:String in e)
         {
            var p:Array = U["s_" + sec]["k_" + k];
            out.push(String(p[0]) + "=" + String(p[1]));
         }
         while(blanks > 0) { out.push(""); blanks--; }
      }
      // base with the player's values laid over it: known keys replace the base value in place, unknown keys of a known
      // section are appended to it, sections the base lacks are appended verbatim. CRLF out.
      private function hzs37Overlay(base:String, over:String) : String
      {
         var B:Object = this.hzs37Parse(base);
         var O:Object = this.hzs37Parse(over);
         var U:Object = {};
         var ext:Object = {};
         var unk:Array = [];
         for each(var s:Object in O.secs)
         {
            if(s.n != "" && B.idx["s_" + s.n] == undefined) { unk.push(s); continue; }
            for each(var kl:String in s.order)
            {
               var sec:String = s.n == "" ? this.hzs37SecOf(B,kl) : String(s.n);
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
         for each(var ln:String in this.hzs37Lines(base))
         {
            var h:String = this.hzs37Hdr(ln);
            if(h != null) { this.hzs37Flush(out,cur,U,ext,flushed); cur = this.hzs37Alias(h); out.push(ln); continue; }
            if(cur != "")
            {
               var kv:Object = this.hzs37KV(ln);
               if(kv != null && U["s_" + cur] != undefined && U["s_" + cur]["k_" + kv.k] != undefined)
               {
                  out.push(kv.o + "=" + String(U["s_" + cur]["k_" + kv.k][1]));
                  continue;
               }
            }
            out.push(ln);
         }
         this.hzs37Flush(out,cur,U,ext,flushed);
         for each(var us:Object in unk)
         {
            if(out.length > 0 && !this.hzs37Blank(String(out[out.length - 1]))) { out.push(""); }
            var r:Array = (us.raw as Array).concat();
            while(r.length > 0 && this.hzs37Blank(String(r[r.length - 1]))) { r.pop(); }
            for each(var rl:String in r) { out.push(rl); }
         }
         return out.length == 0 ? "" : out.join("\r\n") + "\r\n";
      }
      // def / user / state / legacy texts (null = file missing) -> the effective settings text, or null
      private function hzs37Compose(def:String, user:String, state:String, leg:String) : String
      {
         var hd:Boolean = def != null && def.length > 0;
         var hl:Boolean = leg != null && leg.length > 0;
         var base:String = hd ? def : (hl ? leg : null);
         var over:String = user != null ? user : (state == null && hd && hl ? leg : null);   // an old DLL still saves HorizonUI.ini
         if(base == null) { return over == null ? null : this.hzs37Overlay(over,""); }
         return this.hzs37Overlay(base,over != null ? over : "");
      }
      // read all four files, then cb(mergedText or null). Requests during a read get one fresh read afterwards.
      private function hzs37IniRead(cb:Function) : void
      {
         var now:Number = new Date().getTime();
         if(this.hzs37Step != 0 && now - this.hzs37T0 < 3000)
         {
            if(this.hzs37N.indexOf(cb) < 0) { this.hzs37N.push(cb); }
            return;
         }
         if(this.hzs37Step != 0 && this.hzs37Ldr != null) { try { this.hzs37Ldr.close(); } catch(e0:Error) { } }   // stuck: start over
         var q:Array = this.hzs37Step != 0 ? this.hzs37Q.concat(this.hzs37N) : [];
         this.hzs37N = [];
         if(q.indexOf(cb) < 0) { q.push(cb); }
         this.hzs37Q = q;
         this.hzs37Begin();
      }
      private function hzs37Begin() : void
      {
         this.hzs37Got = [null,null,null,null];
         this.hzs37T0 = new Date().getTime();
         this.hzs37Next(0);
      }
      private function hzs37Next(i:int) : void
      {
         this.hzs37Step = i + 1;
         if(i >= hzs37_FILES.length) { this.hzs37Ldr = null; this.hzs37Done(); return; }
         try
         {
            this.hzs37Ldr = new URLLoader();
            this.hzs37Ldr.addEventListener(Event.COMPLETE,this.hzs37OnOk);
            this.hzs37Ldr.addEventListener(IOErrorEvent.IO_ERROR,this.hzs37OnErr);
            this.hzs37Ldr.addEventListener("securityError",this.hzs37OnErr);
            this.hzs37Ldr.load(new URLRequest(String(hzs37_FILES[i])));
         }
         catch(err:Error) { this.hzs37Next(i + 1); }
      }
      private function hzs37OnOk(e:Event) : void
      {
         if(e == null || e.target != this.hzs37Ldr) { return; }
         var i:int = this.hzs37Step - 1;
         try { this.hzs37Got[i] = String(this.hzs37Ldr.data); } catch(err:Error) { }
         this.hzs37Next(i + 1);
      }
      private function hzs37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hzs37Ldr) { return; }
         this.hzs37Next(this.hzs37Step);   // missing file: normal, no error
      }
      private function hzs37Done() : void
      {
         this.hzs37Step = 0;
         var g:Array = this.hzs37Got;
         var txt:String = null;
         try { txt = this.hzs37Compose(g[0],g[1],g[2],g[3]); } catch(errC:Error) { txt = null; }
         var cbs:Array = this.hzs37Q;
         this.hzs37Q = [];
         for each(var cb:Function in cbs) { try { cb(txt); } catch(errCb:Error) { } }
         if(this.hzs37N.length > 0 && this.hzs37Step == 0) { this.hzs37Q = this.hzs37N; this.hzs37N = []; this.hzs37Begin(); }
      }
      // =================== end shared settings reader ===================
   }
}

