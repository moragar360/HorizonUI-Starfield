package
{
   import HUD.QuestUpdateStates.QuestMessage;
   import Shared.AS3.Data.BSUIDataManager;
   import Shared.AS3.Data.FromClientDataEvent;
   import Shared.AS3.IMenu;
   import Shared.GlobalFunc;
   import flash.display.MovieClip;
   import flash.events.Event;
   import flash.geom.Point;
   import scaleform.gfx.Extensions;
   import flash.display.DisplayObject;
   import flash.display.Shape;
   import flash.display.Sprite;
   import flash.events.IOErrorEvent;
   import flash.events.TimerEvent;
   import flash.geom.Rectangle;
   import flash.net.URLLoader;
   import flash.net.URLRequest;
   import flash.text.TextField;
   import flash.text.TextFieldAutoSize;
   import flash.text.TextFormat;
   import flash.utils.Timer;
   import flash.utils.getTimer;
   import flash.filters.GlowFilter;
   
   [Embed(source="/_assets/assets.swf", symbol="symbol266")]
   public class HUDMessagesMenu extends IMenu
   {
      
      public static const REMOVE_QUEST_UPDATE:String = "RemoveQuestUpdate";
      
      public var Messages_mc:Messages;
      
      public var QuestUpdate_mc:MovieClip;
      
      public var XPGroup_mc:XPGroup;
      
      public var BottomCenterGroup_mc:MovieClip;
      
      public var SkillChallengeFlyout_mc:SkillChallengeFlyout;
      
      public var Location_mc:LocationTextWidget;
      
      public var LevelUpHolder_mc:MovieClip;
      
      private var QuestUpdateDataA:Array = new Array();
      
      private var QuestUpdatesA:Array = new Array();
      
      private var StartingQuestUpdatePosition:Point = new Point(0,0);
      
      private var ShowingQuestObjectives:Boolean = false;
      
      private const MAX_NUMBER_OF_QUESTS:int = 8;
      
      private const TALL_ASPECT_RATIO:Number = 1.6;
      
      public function HUDMessagesMenu()
      {
         super();
      }
      
      override protected function onSetSafeRect() : void
      {
         GlobalFunc.LockToSafeRect(this.Messages_mc,"R",SafeX,SafeY,true);
         GlobalFunc.LockToSafeRect(this.BottomCenterGroup_mc,"BC",SafeX,SafeY);
         GlobalFunc.LockToSafeRect(this.XPGroup_mc,"CC",SafeX,SafeY);
         GlobalFunc.LockToSafeRect(this.Location_mc,"CC",SafeX,SafeY);
         GlobalFunc.LockToSafeRect(this.LevelUpHolder_mc,"TC",SafeX,SafeY);
         var _loc1_:int = 0;
         while(_loc1_ < this.QuestUpdatesA.length)
         {
            GlobalFunc.LockToSafeRect(this.QuestUpdatesA[_loc1_],"L",SafeX,SafeY);
            _loc1_++;
         }
         Extensions.enabled = true;
         var _loc2_:Number = Extensions.visibleRect.width / Extensions.visibleRect.height;
         this.BottomCenterGroup_mc.SubtitleText_mc.tallAspectRatio = GlobalFunc.CloseToNumber(_loc2_,this.TALL_ASPECT_RATIO);
      }
      
      override public function onAddedToStage() : void
      {
         super.onAddedToStage();
         this.StartingQuestUpdatePosition.x = this.QuestUpdate_mc.x;
         this.StartingQuestUpdatePosition.y = this.QuestUpdate_mc.y;
         (this as MovieClip).removeChild(this.QuestUpdate_mc);
         this.QuestUpdate_mc = null;
         BSUIDataManager.Subscribe("HudModeData",function(param1:FromClientDataEvent):*
         {
            if(param1.data.ModeVisibilityA.length == HUDUtils.MODE_COUNT)
            {
               SetActiveQuestUpdateVisiblity(param1.data.ModeVisibilityA[HUDUtils.QUEST_UPDATES].bVisible);
               Messages_mc.visible = !param1.data.bDisableHUDMessagesForVideo && Boolean(param1.data.ModeVisibilityA[HUDUtils.MESSAGES].bVisible);
               XPGroup_mc.adjustVertically = param1.data.ModeVisibilityA[HUDUtils.XP_GROUP_ADJUST_VERTICALLY].bVisible;
               XPGroup_mc.SetVisible(param1.data.ModeVisibilityA[HUDUtils.XP_GROUP].bVisible);
               BottomCenterGroup_mc.SubtitleText_mc.adjustVertically = param1.data.ModeVisibilityA[HUDUtils.BOTTOM_CENTER_GROUP_ADJUST_VERTICALLY].bVisible;
               BottomCenterGroup_mc.visible = param1.data.ModeVisibilityA[HUDUtils.BOTTOM_CENTER_GROUP].bVisible;
               Location_mc.SetVisible(param1.data.ModeVisibilityA[HUDUtils.LOCATION].bVisible);
               LevelUpHolder_mc.visible = param1.data.ModeVisibilityA[HUDUtils.LEVEL_UP_PROMPT].bVisible;
            }
         });
         BSUIDataManager.Subscribe("QuestUpdateData",function(param1:FromClientDataEvent):*
         {
            var _loc2_:int = 0;
            var _loc3_:Boolean = false;
            var _loc4_:int = 0;
            if(param1.data.QuestUpdatesA.length > 0)
            {
               QuestUpdateDataA = QuestUpdateDataA.concat(param1.data.QuestUpdatesA);
               _loc2_ = 0;
               while(_loc2_ < param1.data.QuestUpdatesA.length)
               {
                  if(param1.data.QuestUpdatesA[_loc2_].uType == QuestMessage.QUEST_SET_ACTIVE || param1.data.QuestUpdatesA[_loc2_].uType == QuestMessage.QUEST_SET_INACTIVE)
                  {
                     _loc3_ = param1.data.QuestUpdatesA[_loc2_].uType == QuestMessage.QUEST_SET_ACTIVE;
                     _loc4_ = 0;
                     while(_loc4_ < QuestUpdateDataA.length)
                     {
                        if(QuestUpdateDataA[_loc4_].uQuestID == param1.data.QuestUpdatesA[_loc2_].uQuestID)
                        {
                           if(QuestUpdateDataA[_loc4_].uType == QuestMessage.QUEST_SET_ACTIVE && !_loc3_ || QuestUpdateDataA[_loc4_].uType == QuestMessage.QUEST_SET_INACTIVE && _loc3_)
                           {
                              QuestUpdateDataA.splice(_loc4_,1);
                           }
                           else if(QuestUpdateDataA[_loc4_].uType == QuestMessage.QUEST_SET_ACTIVE && HasAlwaysUpQuest(QuestUpdateDataA[_loc4_]))
                           {
                              QuestUpdateDataA.splice(_loc4_,1);
                           }
                           else
                           {
                              QuestUpdateDataA[_loc4_].bActiveQuest = _loc3_;
                              QuestUpdateDataA[_loc4_].bAlwaysUp = _loc3_;
                           }
                        }
                        _loc4_++;
                     }
                  }
                  _loc2_++;
               }
               addEventListener(Event.ENTER_FRAME,showQuestUpdates);
            }
         });
         BSUIDataManager.Subscribe("HUDOpacityData",function(param1:FromClientDataEvent):*
         {
            var _loc3_:MovieClip = null;
            var _loc2_:int = 0;
            while(_loc2_ < numChildren)
            {
               _loc3_ = getChildAt(_loc2_) as MovieClip;
               if(_loc3_)
               {
                  _loc3_.alpha = param1.data.fHUDOpacity;
               }
               _loc2_++;
            }
         });
         BSUIDataManager.Subscribe("FireForgetEventData",function(param1:FromClientDataEvent):*
         {
            if(GlobalFunc.HasFireForgetEvent(param1.data,"MonocleMenu_Opened") || GlobalFunc.HasFireForgetEvent(param1.data,"ShipHud_OnMonocleToggle_Opened"))
            {
               UpdateQuestUpdateObjectiveLists(true);
            }
            else if(GlobalFunc.HasFireForgetEvent(param1.data,"MonocleMenu_Closed") || GlobalFunc.HasFireForgetEvent(param1.data,"ShipHud_OnMonocleToggle_Closed"))
            {
               UpdateQuestUpdateObjectiveLists(false);
            }
         });
         try { this.hzcInit(); } catch(hzcErr:Error) { }
      }
      
      private function IsBlockingQuestUpdateShown() : Boolean
      {
         var _loc1_:* = false;
         var _loc2_:int = 0;
         while(_loc2_ < this.QuestUpdatesA.length)
         {
            if(!this.QuestUpdatesA[_loc2_].CanShowQuestUpdate())
            {
               _loc1_ = true;
               break;
            }
            _loc2_++;
         }
         return _loc1_;
      }
      
      private function HasAlwaysUpQuest(param1:Object) : Boolean
      {
         var _loc2_:* = false;
         var _loc3_:int = 0;
         while(_loc3_ < this.QuestUpdatesA.length)
         {
            if(Boolean(this.QuestUpdatesA[_loc3_].IsShowingThisQuest(param1)) && Boolean(this.QuestUpdatesA[_loc3_].IsAlwaysUp()))
            {
               _loc2_ = true;
               break;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      public function showQuestUpdates(param1:Event) : void
      {
         var _loc7_:Object = null;
         var _loc8_:Boolean = false;
         var _loc9_:MovieClip = null;
         var _loc10_:String = null;
         var _loc11_:MovieClip = null;
         var _loc2_:Array = new Array();
         var _loc3_:Boolean = false;
         var _loc4_:int = 0;
         var _loc5_:QuestUpdate = null;
         var _loc6_:Boolean = false;
         for each(_loc7_ in this.QuestUpdateDataA)
         {
            if(_loc7_.uType != QuestMessage.QUEST_SET_INACTIVE && _loc7_.uType != QuestMessage.QUEST_EXPERIENCE_AWARDED)
            {
               if(_loc6_ || this.IsBlockingQuestUpdateShown())
               {
                  _loc6_ = true;
                  _loc2_.push(_loc7_);
                  continue;
               }
            }
            switch(_loc7_.uType)
            {
               case QuestMessage.QUEST_SET_ACTIVE:
               case QuestMessage.QUEST_ADDED:
               case QuestMessage.QUEST_COMPLETED:
               case QuestMessage.QUEST_FAILED:
               case QuestMessage.OBJECTIVE_ADDED:
               case QuestMessage.OBJECTIVE_COMPLETED:
               case QuestMessage.OBJECTIVE_FAILED:
               case QuestMessage.OBJECTIVE_DORMANT:
               case QuestMessage.OBJECTIVE_MOVE_TO_TOP:
                  _loc8_ = true;
                  _loc5_ = this.FindQuestUpdate(_loc7_);
                  if(_loc5_ != null)
                  {
                     if(_loc5_.CanShowQuestUpdate())
                     {
                        if(_loc7_.uType != QuestMessage.QUEST_ADDED)
                        {
                           _loc5_.ShowQuestUpdate(_loc7_);
                           if(this.CanShowMissionActiveWidget(_loc7_))
                           {
                              _loc5_.ShowMissionActiveButton();
                           }
                        }
                        _loc8_ = false;
                     }
                  }
                  else
                  {
                     _loc8_ = false;
                     if(this.QuestUpdatesA.length < this.MAX_NUMBER_OF_QUESTS)
                     {
                        _loc9_ = new QuestUpdate(stage,_loc7_.bActiveQuest == null || _loc7_.bActiveQuest == false);
                        _loc9_.addEventListener(REMOVE_QUEST_UPDATE,this.OnRemoveQuestUpdateEvent);
                        _loc9_.addEventListener(QuestUpdate.UPDATE_QUEST_UPDATE_POSITION,this.UpdatePositions);
                        _loc9_.ChangeObjectiveListVisibility(this.ShowingQuestObjectives);
                        this.addChild(_loc9_);
                        _loc10_ = _loc7_.strQuestName + "_" + _loc7_.uDisplayedQuestID + "_" + _loc9_.name;
                        _loc9_.name = _loc10_;
                        _loc11_ = this.QuestUpdatesA.length > 0 ? this.QuestUpdatesA[this.QuestUpdatesA.length - 1] : null;
                        this.QuestUpdatesA.push(_loc9_);
                        if(_loc11_)
                        {
                           _loc9_.x = _loc11_.x;
                           _loc9_.y = _loc11_.y + _loc11_.GetVisibleHeight();
                        }
                        else
                        {
                           _loc9_.x = this.StartingQuestUpdatePosition.x;
                           _loc9_.y = this.StartingQuestUpdatePosition.y;
                        }
                        GlobalFunc.LockToSafeRect(_loc9_,"L",SafeX,SafeY);
                        (_loc9_ as QuestUpdate).ShowQuestUpdate(_loc7_);
                        if(this.CanShowMissionActiveWidget(_loc7_))
                        {
                           (_loc9_ as QuestUpdate).ShowMissionActiveButton();
                        }
                     }
                  }
                  if(_loc8_)
                  {
                     _loc2_.push(_loc7_);
                  }
                  break;
               case QuestMessage.QUEST_SET_INACTIVE:
                  _loc5_ = this.FindQuestUpdate(_loc7_);
                  if(_loc5_ != null)
                  {
                     if(_loc5_.CanShowQuestUpdate())
                     {
                        _loc5_.ShowQuestUpdate(_loc7_);
                     }
                     else if(_loc5_.IsShowingActiveQuest())
                     {
                        _loc2_.push(_loc7_);
                     }
                  }
                  break;
               case QuestMessage.QUEST_EXPERIENCE_AWARDED:
                  _loc5_ = this.FindQuestUpdate(_loc7_);
                  if(_loc5_ != null)
                  {
                     _loc5_.ShowQuestUpdate(_loc7_);
                  }
                  else
                  {
                     _loc2_.push(_loc7_);
                  }
                  break;
               case QuestMessage.HDT_QUEST_TEXT_UPDATED:
                  if(_loc7_.bActiveQuest)
                  {
                     _loc5_ = this.FindQuestUpdate(_loc7_);
                     if(_loc5_ != null)
                     {
                        _loc5_.ShowQuestUpdate(_loc7_);
                     }
                     else
                     {
                        _loc2_.push(_loc7_);
                     }
                  }
                  break;
               case QuestMessage.QUEST_TIMER_UPDATED:
                  _loc5_ = this.FindQuestUpdate(_loc7_);
                  if(_loc5_ != null)
                  {
                     if(_loc5_.CanShowQuestUpdate())
                     {
                        _loc5_.UpdateQuestTimer(_loc7_);
                     }
                     else
                     {
                        _loc2_.push(_loc7_);
                     }
                  }
                  break;
               case QuestMessage.QUEST_REJECTED:
                  _loc5_ = this.FindQuestUpdate(_loc7_);
                  if(_loc5_ != null)
                  {
                     this.RemoveQuestUpdate(_loc5_);
                  }
            }
         }
         this.QuestUpdateDataA.splice(0,this.QuestUpdateDataA.length);
         this.QuestUpdateDataA = this.QuestUpdateDataA.concat(_loc2_);
         if(this.QuestUpdateDataA.length == 0)
         {
            removeEventListener(Event.ENTER_FRAME,this.showQuestUpdates);
         }
      }
      
      private function SetActiveQuestUpdateVisiblity(param1:Boolean) : *
      {
         var _loc2_:int = 0;
         while(_loc2_ < this.QuestUpdatesA.length)
         {
            if(this.QuestUpdatesA[_loc2_].IsShowingActiveQuest())
            {
               this.QuestUpdatesA[_loc2_].visible = param1;
            }
            _loc2_++;
         }
      }
      
      private function FindQuestUpdate(param1:Object) : QuestUpdate
      {
         var _loc2_:QuestUpdate = null;
         var _loc3_:int = 0;
         while(_loc3_ < this.QuestUpdatesA.length)
         {
            if(this.QuestUpdatesA[_loc3_].IsShowingThisQuest(param1))
            {
               _loc2_ = this.QuestUpdatesA[_loc3_];
               break;
            }
            _loc3_++;
         }
         return _loc2_;
      }
      
      private function CanShowMissionActiveWidget(param1:Object) : Boolean
      {
         if(param1.bActiveQuest)
         {
            return false;
         }
         if(param1.uType != QuestMessage.QUEST_ADDED && (param1.uType != QuestMessage.OBJECTIVE_ADDED || !param1.bIsMiscQuest))
         {
            return false;
         }
         var _loc2_:Boolean = false;
         var _loc3_:int = 0;
         while(_loc3_ < this.QuestUpdatesA.length && !_loc2_)
         {
            if(this.QuestUpdatesA[_loc3_].IsShowingInputButton())
            {
               _loc2_ = true;
            }
            _loc3_++;
         }
         return !_loc2_;
      }
      
      private function OnRemoveQuestUpdateEvent(param1:Event) : *
      {
         var _loc2_:MovieClip = param1.target as MovieClip;
         this.RemoveQuestUpdate(_loc2_);
      }
      
      private function UpdateQuestUpdateObjectiveLists(param1:Boolean) : *
      {
         this.ShowingQuestObjectives = param1;
         var _loc2_:int = 0;
         while(_loc2_ < this.QuestUpdatesA.length)
         {
            this.QuestUpdatesA[_loc2_].ChangeObjectiveListVisibility(this.ShowingQuestObjectives);
            _loc2_++;
         }
         if(param1)
         {
            this.UpdatePositions();
         }
      }
      
      private function UpdatePositions() : *
      {
         var _loc2_:int = 0;
         var _loc3_:Point = null;
         var _loc1_:int = 0;
         while(_loc1_ < this.QuestUpdatesA.length)
         {
            if(_loc1_ > 0)
            {
               _loc2_ = _loc1_ - 1;
               _loc3_ = new Point(this.QuestUpdatesA[_loc2_].x,this.QuestUpdatesA[_loc2_].y);
               this.QuestUpdatesA[_loc1_].x = this.QuestUpdatesA[_loc2_].x;
               this.QuestUpdatesA[_loc1_].y = this.QuestUpdatesA[_loc2_].y + this.QuestUpdatesA[_loc2_].GetVisibleHeight();
               GlobalFunc.LockToSafeRect(this.QuestUpdatesA[_loc1_],"L",SafeX,SafeY);
            }
            _loc1_++;
         }
      }
      
      private function RemoveQuestUpdate(param1:MovieClip) : *
      {
         var _loc4_:int = 0;
         var _loc5_:Point = null;
         var _loc6_:Point = null;
         var _loc7_:Point = null;
         var _loc2_:int = -1;
         var _loc3_:int = 0;
         while(_loc3_ < this.QuestUpdatesA.length)
         {
            if(this.QuestUpdatesA[_loc3_] == param1)
            {
               _loc2_ = _loc3_;
               break;
            }
            _loc3_++;
         }
         if(_loc2_ != -1)
         {
            _loc4_ = _loc2_ + 1;
            _loc5_ = this.StartingQuestUpdatePosition;
            if(_loc4_ - 2 >= 0)
            {
               _loc5_ = new Point(this.QuestUpdatesA[_loc4_ - 2].x,this.QuestUpdatesA[_loc4_ - 2].y + this.QuestUpdatesA[_loc4_ - 2].GetVisibleHeight());
            }
            while(_loc4_ < this.QuestUpdatesA.length)
            {
               _loc6_ = new Point(this.QuestUpdatesA[_loc4_].x,this.QuestUpdatesA[_loc4_].y);
               this.QuestUpdatesA[_loc4_].x = _loc5_.x;
               this.QuestUpdatesA[_loc4_].y = _loc5_.y;
               GlobalFunc.LockToSafeRect(this.QuestUpdatesA[_loc4_],"L",SafeX,SafeY);
               _loc7_ = new Point(this.QuestUpdatesA[_loc4_].x,this.QuestUpdatesA[_loc4_].y);
               _loc5_ = new Point(_loc7_.x,_loc7_.y);
               _loc5_.y += this.QuestUpdatesA[_loc4_].GetVisibleHeight();
               this.QuestUpdatesA[_loc4_].x = _loc6_.x;
               this.QuestUpdatesA[_loc4_].y = _loc6_.y;
               this.QuestUpdatesA[_loc4_].TranslateToNewPosition(_loc7_);
               _loc4_++;
            }
            this.QuestUpdatesA.splice(_loc2_,1);
         }
         (this as MovieClip).removeChild(param1);
      }
      
      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean
      {
         var _loc3_:Boolean = false;
         var _loc4_:int = 0;
         while(_loc4_ < this.QuestUpdatesA.length)
         {
            if(this.QuestUpdatesA[_loc4_].IsShowingInputButton())
            {
               _loc3_ = Boolean(this.QuestUpdatesA[_loc4_].ProcessUserEvent(param1,param2));
            }
            _loc4_++;
         }
         if(!_loc3_ && Boolean(this.LevelUpHolder_mc.LevelUpWidget_mc.shown))
         {
            _loc3_ = Boolean(this.LevelUpHolder_mc.LevelUpWidget_mc.ProcessUserEvent(param1,param2));
         }
         return _loc3_;
      }
      
      override protected function OnControlMapChanged(param1:Object) : void
      {
         super.OnControlMapChanged(param1);
         var _loc2_:int = 0;
         while(_loc2_ < this.QuestUpdatesA.length)
         {
            this.QuestUpdatesA[_loc2_].SetPlatform(this.uiController);
            _loc2_++;
         }
      }

      // ===================== Horizon UI Comms (HUD Messages) v0.42.0 =====================
      // v0.42.0 r2: companion reaction card ([Comms] ReactionCard=1). The game's HUD message "<Name> liked that." (also loved /
      // disliked / hated; 1.16.244 English strings) is drawn as a Horizon card in the same spot: a pill with a chevron
      // tile (2 up loved, 1 up liked, 1 down disliked, 2 down hated), the name in the speaker color, the reaction in its
      // color (teal / green / amber / red). The game's line (HUDMessageItem.Internal_mc) is set visible = false, never
      // removed: the game's stack, fade and timing stay. Only an exact, whole-line match is changed (one line, name of 1 - 4
      // words, each starting with a capital or digit (name particles like "de" / "van" allowed), no ':' '!' '?' quotes or brackets, not a pronoun like "Everyone"); any
      // other line, other languages, ReactionCard=0 or any error leave the game's line as it is.
      // v0.40.1: the scan state also ends when the HUD's bottom-center group goes from shown to hidden.
      // v0.40: quest popups / the mission toast stay hidden for the whole scan (no 30 s cap); the scan state is cleared by
      // the scanner's close event or a frame gap over 1 s while scanning (a load). HideQuestPopupsWhileScanning defaults to 1.
      // v0.39: no behavior change
      // v0.38: no behavior change (American spelling in comments)
      // v0.37: settings come from HorizonUI.default.ini with HorizonUI.user.ini laid over it (legacy HorizonUI.ini when
      // there is no default file), read by the shared helper below (hzc37IniRead) - the same code as the HUD and the
      // dialogue movie. The poll / event re-reads stay, so F11 SAVE, preset APPLY / UNDO and RESTORE reach this movie
      // the same way a saved HorizonUI.ini did before (a changed merged text is re-applied).
      // v0.34: smaller default subtitle card (base text 27 -> 24, padding trimmed; SubSize range 0.70 - 1.80 keeps the old
      // largest size reachable), SubFont / FontFace 3 = the game's semibold face (run-time name, never bundled), and
      // [Comms] MissionToastScale (-1 = follow [Style] HudScale, else 0.60 - 1.60) for the mission toast.
      // ORIGINAL CODE (Horizon UI). Added as members of the vanilla HUDMessagesMenu class by apply_comms_hooks.ps1, with ONE
      // call in onAddedToStage. Everything else hooks in from outside: own BSUIDataManager subscriptions (registered after the
      // vanilla ones, so they run after them), Event.ADDED for new quest popups. Vanilla clips are hidden by alpha only.
      // With [Comms] Subtitles=0, MissionToast=0, both [Scanner] keys 0 and XpToast=0 nothing vanilla is changed.
      // v0.33: subtitle text size never changes (SubMaxLines widens, then grows the card); SubOffsetX/Y apply on top
      // of the ARRANGE position too.
      // v0.32: mission toast (replaces the vanilla quest-update banner, which gets alpha 0), SubTextColor, SubCard,
      // SubOffsetX, card borders as a stroke on a fresh Shape (fixes the wedge), layout from the stored card size, and the
      // ini is re-applied whenever the file text changes (not only on a new HzRev) so ARRANGE positions always arrive.
      private static const HZC_LRG:Boolean = true;
      private static const HZC_ACC:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZC_STR:Object = {"SpeakerHex":1,"SubTextHex":1,"AccentHex":1,"SubtitleX":1,"SubtitleY":1,"SpeakerX":1,"SpeakerY":1,"MissionToastX":1,"MissionToastY":1};
      private static const HZC_SEMI:String = "$NB_Grotesk_Semibold";   // the game's own semibold face (run-time name only)
      private static const HZC_EDGE:Number = 0.10;          // card edge: white @ .10, 1 px stroke
      private static const HZC_TXT:uint = 0xE8F0F5;         // default subtitle text (off-white)
      private static const HZC_GRN:uint = 0x5EE3A1;
      private static const HZC_RED:uint = 0xFF5B5B;
      private static const HZC_TST_HEAD:Array = ["MISSION UPDATED","NEW MISSION","OBJECTIVE COMPLETE","MISSION COMPLETE","MISSION FAILED"];
      private static const HZC_TST_PRIO:Array = [1,3,2,4,5];   // merging two updates of one quest keeps the stronger state
      private var hzcCfg:Object = {"ReactionCard":1,"Subtitles":1,"SubAutoPause":1,"SubSize":1,"SubWidth":50,"SubBgOpacity":0.7,"SubPosition":0,"SubOffsetY":0,"SubAlign":0,"ShowSpeaker":1,"SpeakerColor":-1,"SpeakerHex":"","SpeakerCard":1,"KeepInDialogue":1,"FixedInDialogue":1,"SubMaxLines":3,"SubFont":-1,"Dialogue":1,"DlgAutoPause":1,"HideQuestPopupsWhileScanning":1,"DimTraitPopupDuringBioscan":0,"TraitPopupDim":0.4,"XpToast":0,"FontFace":1,"AccentColor":0,"AccentHex":"","TextScale":1,"ScreenHeight":0,"Margin":40,"SubtitleX":"-1","SubtitleY":"-1","SpeakerX":"-1","SpeakerY":"-1","SubTextColor":-1,"SubTextHex":"","SubCard":1,"SubOffsetX":0,"MissionToast":1,"MissionToastTime":5,"MissionToastMax":3,"MissionToastSound":1,"MissionToastScale":-1,"HudScale":1,"MissionToastX":"-1","MissionToastY":"-1","HzRev":0};
      private var hzcIniState:int = 0;       // 0 loading, 1 read, 2 missing / unreadable (defaults)
      private var hzcSubBg:Shape = null;     // card art: a fresh Shape per draw (no stale path can survive)
      private var hzcSpkBg:Shape = null;
      private var hzcSubW:Number = 0;        // card size as drawn (layout uses these, never .width / .height)
      private var hzcSubH:Number = 0;
      private var hzcSpkW:Number = 0;
      private var hzcSpkH:Number = 0;
      private var hzcTstLayer:Sprite = null;
      private var hzcTsts:Array = [];        // live toasts, newest first
      private var hzcTstPend:Array = [];     // updates that arrived before the ini was read
      private var hzcTstTick:Boolean = false;
      private var hzcRev:String = null;
      private var hzcReading:Boolean = false;
      private var hzcPoll:Timer = null;
      private var hzcLayer:Sprite = null;
      private var hzcSub:Sprite = null;
      private var hzcSubName:TextField = null;
      private var hzcSubBody:TextField = null;
      private var hzcSpk:Sprite = null;
      private var hzcSpkName:TextField = null;
      private var hzcSpkSub:TextField = null;
      private var hzcProbe:Object = {};      // es / dlg / edi / edi2 / font : 1 found, 0 not found
      private var hzcInDlg:Boolean = false;
      private var hzcGroupVis:Boolean = true;
      private var hzcScan:Boolean = false;
      private var hzcScanT0:int = 0;
      private var hzcScanLast:int = 0;          // v0.40: last frame while scanning
      private var hzcScanTick:Boolean = false;
      private var hzcDllT:int = -100000;      // v0.41.0: last DLL push (getTimer)
      private var hzcDllOn:Boolean = false;
      private var hzcFFClosed:Boolean = false;   // r2: a MonocleMenu_Closed event came while the DLL said open (left to its closed push)
      private var hzcScanShip:Boolean = false; // v0.41.0: the scan state came from the ship scanner (the DLL push does not end it)
      private var hzcOpacity:Number = 1;
      private var hzcWho:String = "";
      private var hzcLine:String = "";
      private var hzcShown:Boolean = false;
      private var hzcGameFont:String = null;
      private var hzcFontOk:Object = {};

      private function hzcInit() : void
      {
         this.hzcLayer = new Sprite();
         this.hzcLayer.mouseEnabled = false;
         this.hzcLayer.mouseChildren = false;
         addChild(this.hzcLayer);
         this.hzcSub = new Sprite();
         this.hzcSubName = this.hzcField(true);
         this.hzcSubBody = this.hzcField(false);
         this.hzcSubBody.multiline = true;
         this.hzcSubBody.wordWrap = true;
         this.hzcSub.addChild(this.hzcSubName);
         this.hzcSub.addChild(this.hzcSubBody);
         this.hzcSub.visible = false;
         this.hzcLayer.addChild(this.hzcSub);
         this.hzcSpk = new Sprite();
         this.hzcSpkName = this.hzcField(true);
         this.hzcSpkSub = this.hzcField(true);
         this.hzcSpk.addChild(this.hzcSpkName);
         this.hzcSpk.addChild(this.hzcSpkSub);
         this.hzcSpk.visible = false;
         this.hzcLayer.addChild(this.hzcSpk);
         this.hzcTstLayer = new Sprite();
         this.hzcTstLayer.mouseEnabled = false;
         this.hzcTstLayer.mouseChildren = false;
         addChild(this.hzcTstLayer);
         try { this.hzcGameFont = this.BottomCenterGroup_mc.SubtitleText_mc.SubtitleText_tf.getTextFormat().font; } catch(e0:Error) { }
         if(this.hzcGameFont == null || this.hzcGameFont.length == 0) { this.hzcGameFont = "$MAIN_Font"; }
         this.hzcProbeFile("es","Enhanced Subtitles - My Edits.ini");
         this.hzcProbeFile("dlg","HorizonUI/modules/comms_dialogue.marker");
         this.hzcProbeFile("edi","Enhanced Dialogue Interface - My Edits.ini");
         this.hzcProbeFile("edi2","Enhanced Dialogue Interface.ini");
         this.hzcProbeFile("font","HorizonUI/modules/font.marker");
         this.hzcProbeFile("scan","HorizonUI/modules/scanner.marker");   // v0.40.3: the Horizon scanner (location banner)
         BSUIDataManager.Subscribe("CurrentSubtitleData",this.hzcOnSub);
         BSUIDataManager.Subscribe("HudModeData",this.hzcOnMode);
         BSUIDataManager.Subscribe("HUDOpacityData",this.hzcOnOpacity);
         BSUIDataManager.Subscribe("FireForgetEventData",this.hzcOnFF);
         BSUIDataManager.Subscribe("QuestUpdateData",this.hzcOnQuest);
         addEventListener(Event.ADDED,this.hzcOnAdded);
         try { this.hzcRxInit(); } catch(eRx0:Error) { }   // v0.42.0 r2: companion reaction card
         this.hzcReload();
      }

      // ---------- settings ----------
      private function hzcReload() : void
      {
         if(this.hzcReading) { return; }
         this.hzcReading = true;
         try { this.hzc37IniRead(this.hzcOnIniTxt); } catch(e:Error) { this.hzcReading = false; }
      }
      // the merged settings text (null = no settings file at all: built-in defaults)
      private function hzcOnIniTxt(txt:String) : void
      {
         this.hzcReading = false;
         if(txt == null)
         {
            if(this.hzcIniState == 0) { this.hzcIniState = 2; this.hzcApply(); }
            return;
         }
         try
         {
            // v0.32: re-apply whenever the file text changed. HzRev alone was not enough: a save that did not bump it
            // (or a bump the movie missed) left ARRANGE positions unapplied.
            if(txt == this.hzcRev) { return; }
            try { this.hzcRxDbgIni(txt); } catch(eDbgI:Error) { }   // v0.42.0 r3: [Debug] Debug (message log)
            var o:Object = this.hzcParse(txt);
            this.hzcRev = txt;
            this.hzcIniState = 1;
            for(var k:String in this.hzcCfg)
            {
               if(o[k] == undefined) { continue; }
               if(HZC_STR[k] != undefined) { this.hzcCfg[k] = String(o[k]); continue; }
               var n:Number = Number(o[k]);
               if(!isNaN(n)) { this.hzcCfg[k] = n; }
            }
            this.hzcApply();
         }
         catch(e1:Error) { }
      }
      // [Comms] [Scanner] [Style] [Layout] [Effects]; the pre-v0.31 name [Effects v0.26] is used only when [Effects] lacks the key
      private function hzcParse(t:String) : Object
      {
         var o:Object = {};
         var old:Object = {};
         var sec:String = "";
         var want:Object = {"comms":1,"scanner":1,"style":1,"layout":1,"effects":1,"effects v0.26":2};
         for each(var raw:String in t.split("\r").join("").split("\n"))
         {
            var ln:String = raw.replace(/^[\s\uFEFF]+|\s+$/g,"");
            if(ln.length == 0 || ln.charAt(0) == ";" || ln.charAt(0) == "#") { continue; }
            if(ln.charAt(0) == "[") { var e:int = ln.indexOf("]"); sec = (e > 0 ? ln.substring(1,e) : ln.substr(1)).replace(/^\s+|\s+$/g,"").toLowerCase(); continue; }
            if(want[sec] == undefined) { continue; }
            var i:int = ln.indexOf("=");
            if(i <= 0) { continue; }
            var v:String = ln.substr(i + 1);
            var c:int = v.indexOf(";");
            if(c >= 0) { v = v.substr(0,c); }
            var k:String = ln.substr(0,i).replace(/\s+$/,"");
            v = v.replace(/^\s+|\s+$/g,"");
            if(want[sec] == 2) { old[k] = v; } else { o[k] = v; }
         }
         for(var ok:String in old) { if(o[ok] == undefined) { o[ok] = old[ok]; } }
         return o;
      }
      private function hzcApply() : void
      {
         var on:Boolean = int(this.hzcCfg.Subtitles) == 1 || int(this.hzcCfg.MissionToast) == 1;
         if(on && this.hzcPoll == null)
         {
            this.hzcPoll = new Timer(5000);
            this.hzcPoll.addEventListener(TimerEvent.TIMER,this.hzcOnPoll);
            this.hzcPoll.start();
         }
         else if(!on && this.hzcPoll != null) { this.hzcPoll.stop(); this.hzcPoll.removeEventListener(TimerEvent.TIMER,this.hzcOnPoll); this.hzcPoll = null; }
         this.hzcFontOk = {};
         if(!this.hzcActive()) { this.hzcHideCards(); }
         else if(this.hzcShown) { this.hzcShowLine(); }
         this.hzcXp();
         this.hzcRefreshAlphas();
         try { this.hzcToastApply(); } catch(e2:Error) { }
         try { this.hzcRxApply(); } catch(eRx1:Error) { }   // v0.42.0 r2
      }
      private function hzcOnPoll(e:TimerEvent) : void { this.hzcReload(); }

      // ---------- probes (relative to Data/Interface) ----------
      private function hzcProbeFile(id:String, path:String) : void
      {
         try
         {
            var l:URLLoader = new URLLoader();
            var self:* = this;
            l.addEventListener(Event.COMPLETE,function(e:Event):void { self.hzcProbeDone(id,1); });
            l.addEventListener(IOErrorEvent.IO_ERROR,function(e:Event):void { self.hzcProbeDone(id,0); });
            l.addEventListener("securityError",function(e:Event):void { self.hzcProbeDone(id,0); });
            l.load(new URLRequest(path));
         }
         catch(e0:Error) { this.hzcProbe[id] = 0; }
      }
      public function hzcProbeDone(id:String, v:int) : void
      {
         this.hzcProbe[id] = v;
         try { if(!this.hzcActive()) { this.hzcHideCards(); } this.hzcFontOk = {}; } catch(e:Error) { }
         if(id == "scan") { this.hzcBanner(); }
      }
      // Horizon subtitles run unless switched off, or another subtitle mod is installed and SubAutoPause=1
      private function hzcActive() : Boolean
      {
         if(int(this.hzcCfg.Subtitles) != 1) { return false; }
         if(int(this.hzcCfg.SubAutoPause) == 1 && this.hzcProbe.es === 1) { return false; }
         return true;
      }
      // during a conversation the Horizon dialogue file draws the speaker card (addendum 4)
      private function hzcDlgOwnsSpeaker() : Boolean
      {
         if(this.hzcProbe.dlg !== 1 || int(this.hzcCfg.Dialogue) != 1) { return false; }
         return !(int(this.hzcCfg.DlgAutoPause) == 1 && (this.hzcProbe.edi === 1 || this.hzcProbe.edi2 === 1));
      }

      // ---------- data ----------
      private function hzcOnSub(ev:FromClientDataEvent) : void
      {
         try
         {
            var vanilla:DisplayObject = this.BottomCenterGroup_mc.SubtitleText_mc;
            if(!this.hzcActive()) { vanilla.alpha = 1; this.hzcHideCards(); return; }
            vanilla.alpha = 0;   // the vanilla Subtitles clip (text + its line backgrounds); vanilla only drives its visible
            var d:Object = ev != null ? ev.data : null;
            if(d == null || !d.bShouldDisplay)
            {
               if(this.hzcInDlg && int(this.hzcCfg.KeepInDialogue) == 1 && this.hzcLine.length > 0) { return; }
               this.hzcLine = "";
               this.hzcHideCards();
               return;
            }
            this.hzcWho = d.sSpeakerName != null ? String(d.sSpeakerName) : "";
            this.hzcLine = d.sSubtitleText != null ? String(d.sSubtitleText) : "";
            this.hzcShowLine();
         }
         catch(e:Error)
         {
            try { this.BottomCenterGroup_mc.SubtitleText_mc.alpha = 1; this.hzcHideCards(); } catch(e2:Error) { }
         }
      }
      private function hzcOnMode(ev:FromClientDataEvent) : void
      {
         try
         {
            var m:* = ev.data.ModeVisibilityA;
            if(m == null || m.length != HUDUtils.MODE_COUNT) { return; }
            var was:Boolean = this.hzcInDlg;
            var gvWas:Boolean = this.hzcGroupVis;
            this.hzcInDlg = Boolean(m[HUDUtils.BOTTOM_CENTER_GROUP_ADJUST_VERTICALLY].bVisible);
            this.hzcGroupVis = Boolean(m[HUDUtils.BOTTOM_CENTER_GROUP].bVisible);
            // v0.40.1 safety clear: the HUD group going away (menu, death, cutscene) ends the scan state
            if(gvWas && !this.hzcGroupVis && this.hzcScan && !(this.hzcDllFresh() && this.hzcDllOn)) { this.hzcScan = false; this.hzcRefreshAlphas(); this.hzcToastVis(); }   // v0.41.0: not while the DLL says the scanner is open
            this.hzcLayer.visible = this.hzcGroupVis;
            if(was && !this.hzcInDlg) { this.hzcLine = ""; this.hzcHideCards(); }
            this.hzcReload();
            if(this.hzcShown) { this.hzcLayout(); }
            this.hzcToastVis();
         }
         catch(e:Error) { }
      }
      // runs after the vanilla handler (same provider, subscribed later): re-apply our hides on top of fHUDOpacity
      private function hzcOnOpacity(ev:FromClientDataEvent) : void
      {
         try { this.hzcOpacity = Number(ev.data.fHUDOpacity); if(isNaN(this.hzcOpacity)) { this.hzcOpacity = 1; } } catch(e:Error) { }
         this.hzcLayer.alpha = this.hzcOpacity;
         if(this.hzcTstLayer) { this.hzcTstLayer.alpha = this.hzcOpacity; }
         this.hzcRefreshAlphas();
      }
      private function hzcOnFF(ev:FromClientDataEvent) : void
      {
         try
         {
            if(GlobalFunc.HasFireForgetEvent(ev.data,"MonocleMenu_Opened") || GlobalFunc.HasFireForgetEvent(ev.data,"ShipHud_OnMonocleToggle_Opened"))
            {
               this.hzcScanShip = !GlobalFunc.HasFireForgetEvent(ev.data,"MonocleMenu_Opened");
               this.hzcScan = true; this.hzcScanT0 = getTimer(); this.hzcScanLast = getTimer(); this.hzcReload();
               if(!this.hzcScanTick) { this.hzcScanTick = true; addEventListener(Event.ENTER_FRAME,this.hzcScanFrame); }
            }
            else if(GlobalFunc.HasFireForgetEvent(ev.data,"MonocleMenu_Closed") || GlobalFunc.HasFireForgetEvent(ev.data,"ShipHud_OnMonocleToggle_Closed"))
            {
               // r2 (NIT-13): while the DLL says the hand scanner is open, its closed push ends the scan (a push during the close
               // animation would turn it back on for 100 - 200 ms: popup / banner flicker); 1.5 s without a push ends it anyway
               if(!this.hzcScanShip && this.hzcDllOn && this.hzcDllFresh() && GlobalFunc.HasFireForgetEvent(ev.data,"MonocleMenu_Closed")) { this.hzcFFClosed = true; return; }
               this.hzcScan = false;
            }
            else { return; }
            this.hzcRefreshAlphas();
            this.hzcToastVis();
         }
         catch(e:Error) { }
      }
      // v0.40: only while scanning. A frame gap over 1 s (a load screen) ends the scan state; so does the close event.
      private function hzcScanFrame(e:Event) : void
      {
         var now:int = getTimer();
         if(!this.hzcScan || now - this.hzcScanLast > 1000 || (this.hzcFFClosed && now - this.hzcDllT > 1500))
         {
            this.hzcFFClosed = false;
            this.hzcScanTick = false;
            removeEventListener(Event.ENTER_FRAME,this.hzcScanFrame);
            if(this.hzcScan) { this.hzcScan = false; this.hzcRefreshAlphas(); this.hzcToastVis(); }
            return;
         }
         this.hzcScanLast = now;
         this.hzcBanner();   // v0.41.0: every frame while scanning (the game re-shows the banner on a tool switch)
      }
      // ---------- v0.41.0: the DLL's scan state (main_v0410r2.cpp: every 100 ms while the hand scanner is open + one closed push) ----------
      public function hzcDllScan(on:Boolean) : void
      {
         try   // r2 (NIT-3): nothing may escape into the DLL's Invoke
         {
            this.hzcDllT = getTimer();
            this.hzcDllOn = on === true;
            if(!this.hzcDllOn) { this.hzcFFClosed = false; }
            if(this.hzcDllOn && !this.hzcScan)
            {
               this.hzcScanShip = false;
               this.hzcScan = true; this.hzcScanT0 = getTimer(); this.hzcScanLast = getTimer(); this.hzcReload();
               if(!this.hzcScanTick) { this.hzcScanTick = true; addEventListener(Event.ENTER_FRAME,this.hzcScanFrame); }
               this.hzcRefreshAlphas();
               this.hzcToastVis();
            }
            else if(!this.hzcDllOn && this.hzcScan && !this.hzcScanShip)
            {
               this.hzcScan = false;
               this.hzcRefreshAlphas();
               this.hzcToastVis();
            }
         }
         catch(e:Error) { }
      }
      private function hzcDllFresh() : Boolean
      {
         return getTimer() - this.hzcDllT < 500;
      }
      private function hzcOnAdded(e:Event) : void
      {
         try
         {
            var c:DisplayObject = e.target as DisplayObject;
            if(c != null && c.parent == this && c is QuestUpdate) { c.alpha = this.hzcAlphaFor(c); }
         }
         catch(err:Error) { }
      }
      // alpha for a direct child (quest popups, location / trait text); the rest keep the vanilla fHUDOpacity
      private function hzcAlphaFor(c:DisplayObject) : Number
      {
         var a:Number = this.hzcOpacity;
         if(c is QuestUpdate && this.hzcToastOn()) { return 0; }   // v0.32: the Horizon toast replaces the banner (alpha only)
         if(!this.hzcScan) { return a; }
         if(c is QuestUpdate && int(this.hzcCfg.HideQuestPopupsWhileScanning) == 1) { return 0; }
         if(c == this.Location_mc && int(this.hzcCfg.DimTraitPopupDuringBioscan) == 1) { return a * Math.max(0.1,Math.min(0.9,Number(this.hzcCfg.TraitPopupDim))); }
         return a;
      }
      private function hzcRefreshAlphas() : void
      {
         try
         {
            var i:int = 0;
            while(i < numChildren)
            {
               var c:DisplayObject = getChildAt(i);
               if(c is QuestUpdate || c == this.Location_mc) { c.alpha = this.hzcAlphaFor(c); }
               i++;
            }
         }
         catch(e:Error) { }
         this.hzcXp();
         this.hzcBanner();
      }
      // v0.40.3: the game's planet location banner (Location_mc > PlanetLocationTextAnim_mc: the body name and its system /
      // type line) shows through the Horizon scanner's cards. While the Horizon scanner is open (scanner.marker found) it is
      // at alpha 0; the alpha it had before comes back when the scan ends. Never removed; the trait popup
      // (LocationTextAnim_mc) and the game's own queue / animation are not touched.
      private var hzcBanA:Number = NaN;
      private function hzcBanner() : void
      {
         try
         {
            var b:DisplayObject = this.Location_mc.PlanetLocationTextAnim_mc as DisplayObject;
            if(b == null) { return; }
            if(this.hzcScan && this.hzcProbe.scan === 1)
            {
               if(isNaN(this.hzcBanA)) { this.hzcBanA = b.alpha; }
               b.alpha = 0;
            }
            else if(!isNaN(this.hzcBanA)) { b.alpha = this.hzcBanA; this.hzcBanA = NaN; }
         }
         catch(e:*) { }
      }
      // the game's +XP popup: hidden while the HUD's own XP toast is on ([Effects] XpToast=1)
      private function hzcXp() : void
      {
         try { this.XPGroup_mc.XPTextAnim_mc.alpha = int(this.hzcCfg.XpToast) == 1 ? 0 : 1; } catch(e:Error) { }
      }

      // ---------- drawing (1080p units; COMMS_BUILD_SPEC_v031.md 3) ----------
      private function hzcField(name:Boolean) : TextField
      {
         var t:TextField = new TextField();
         t.selectable = false;
         t.mouseEnabled = false;
         t.embedFonts = true;
         t.autoSize = TextFieldAutoSize.LEFT;
         t.text = "";
         return t;
      }
      private function hzcFontProbe(n:String) : Boolean
      {
         if(this.hzcFontOk[n] != undefined) { return this.hzcFontOk[n] == 1; }
         var ok:Boolean = false;
         try
         {
            var t:TextField = new TextField();
            t.embedFonts = true;
            var f:TextFormat = new TextFormat(n,20,0xFFFFFF);
            t.defaultTextFormat = f; t.text = "WMW"; t.setTextFormat(f);
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
         catch(e:Error) { ok = false; }
         this.hzcFontOk[n] = ok ? 1 : 0;
         return ok;
      }
      // role: "nm" names (SemiBold / Medium), "rg" body. SubFont -1 = [Style] FontFace. Chosen face -> base face -> game font.
      private function hzcFont(role:String) : String
      {
         var f:int = int(this.hzcCfg.SubFont) >= 0 ? int(this.hzcCfg.SubFont) : int(this.hzcCfg.FontFace);
         if(f == 3) { return this.hzcFontProbe(HZC_SEMI) ? HZC_SEMI : this.hzcGameFont; }   // one weight for every role
         if(this.hzcProbe.font === 0) { f = 0; }
         var base:String = f == 2 ? "$Horizon_Font_Alt" : (f == 1 ? "$Horizon_Font" : null);
         if(base == null) { return this.hzcGameFont; }
         var want:String = role == "rg" ? base + "_Regular" : base;
         if(this.hzcFontProbe(want)) { return want; }
         if(this.hzcFontProbe(base)) { return base; }
         return this.hzcGameFont;
      }
      // a line with characters the Horizon faces don't carry (CJK, Greek in Exo 2...) uses the game font
      private function hzcFits(tf:TextField, s:String) : Boolean
      {
         var i:int = 0;
         while(i < s.length) { if(s.charCodeAt(i) > 0x52F && s.charCodeAt(i) != 0x2019 && s.charCodeAt(i) != 0x2026 && s.charCodeAt(i) != 0x2014 && s.charCodeAt(i) != 0x2013 && s.charCodeAt(i) != 0x201C && s.charCodeAt(i) != 0x201D) { return false; } i++; }
         return true;
      }
      private function hzcAccent() : uint
      {
         var hx:String = String(this.hzcCfg.AccentHex);
         var ai:int = int(this.hzcCfg.AccentColor);
         if(ai >= HZC_ACC.length && hx.length == 7 && hx.charAt(0) == "#") { return uint(parseInt(hx.substr(1),16)); }
         return uint(HZC_ACC[Math.max(0,Math.min(HZC_ACC.length - 1,ai))]);
      }
      private function hzcSpeakerCol() : uint
      {
         var sc:int = int(this.hzcCfg.SpeakerColor);
         var hx:String = String(this.hzcCfg.SpeakerHex);
         if(sc == 13 && hx.length == 7 && hx.charAt(0) == "#") { return uint(parseInt(hx.substr(1),16)); }
         if(sc >= 0 && sc < HZC_ACC.length) { return uint(HZC_ACC[sc]); }
         return this.hzcAccent();
      }
      private function hzcScale() : Number { return Number(this.hzcCfg.SubSize) * Number(this.hzcCfg.TextScale) * (HZC_LRG ? 1.25 : 1); }
      private function hzcSet(t:TextField, s:String, role:String, size:Number, col:uint, spacing:Number, align:String) : void
      {
         var face:String = this.hzcFits(t,s) ? this.hzcFont(role) : this.hzcGameFont;
         var f:TextFormat = new TextFormat(face,Math.round(size),col);
         f.letterSpacing = spacing;
         f.align = align;
         if(role == "rg") { f.leading = Math.round(size * 0.38 - 4); }
         t.defaultTextFormat = f;
         t.text = s;
         t.setTextFormat(f);
      }
      private function hzcHideCards() : void
      {
         this.hzcShown = false;
         if(this.hzcSub) { this.hzcSub.visible = false; }
         if(this.hzcSpk) { this.hzcSpk.visible = false; }
      }
      private function hzcShowLine() : void
      {
         if(this.hzcLine.length == 0) { this.hzcHideCards(); return; }
         var sc:Number = this.hzcScale();
         var who:String = this.hzcWho;
         var withName:Boolean = int(this.hzcCfg.ShowSpeaker) == 1 && who.length > 0;
         var card:Boolean = int(this.hzcCfg.SubCard) != 0;
         var w:Number = Math.round(1920 * Math.max(30,Math.min(90,Number(this.hzcCfg.SubWidth))) / 100);
         // v0.34: trimmed defaults (was 34 / 30 / 18 / 20, text 27, name 16)
         var pl:Number = 28 * sc;
         var pr:Number = 26 * sc;
         var pt:Number = 14 * sc;
         var pb:Number = 16 * sc;
         var tcol:uint = this.hzcTextCol();
         this.hzcSubName.visible = withName;
         if(withName) { this.hzcSet(this.hzcSubName,who.toUpperCase(),"nm",15 * sc,this.hzcSpeakerCol(),Math.round(16 * sc * 0.2),"left"); }
         this.hzcSubName.x = Math.round(pl); this.hzcSubName.y = Math.round(pt);
         var al:String = int(this.hzcCfg.SubAlign) == 1 ? "center" : "left";
         // fixed-width body: the alignment is done by the TextFormat inside the field, so the field never moves
         this.hzcSubBody.autoSize = TextFieldAutoSize.LEFT;
         this.hzcSubBody.width = Math.round(w - pl - pr);
         var body:Number = 24 * sc;
         this.hzcSet(this.hzcSubBody,this.hzcLine,"rg",body,tcol,0,al);
         // v0.33: the text size is never changed. Above SubMaxLines the card first widens (in 4 % steps, up to 90 % of
         // 1920), then simply grows taller to show every line.
         var maxL:int = Math.max(2,Math.min(5,int(this.hzcCfg.SubMaxLines)));
         var wMax:Number = Math.round(1920 * 0.9);
         while(this.hzcSubBody.numLines > maxL && w < wMax)
         {
            w = Math.min(wMax,w + Math.round(1920 * 0.04));
            this.hzcSubBody.width = Math.round(w - pl - pr);
            this.hzcSet(this.hzcSubBody,this.hzcLine,"rg",body,tcol,0,al);
         }
         this.hzcSubBody.width = Math.round(w - pl - pr);
         this.hzcSubBody.x = Math.round(pl);
         this.hzcSubBody.y = Math.round(pt + (withName ? 24.6 * sc : 0));
         var h:Number = Math.round(this.hzcSubBody.y + this.hzcSubBody.textHeight + 4 + pb);
         this.hzcSubW = w;
         this.hzcSubH = h;
         // v0.32: card art on a fresh Shape each time; the edge is a stroke, not an even-odd ring (that ring leaked a
         // stale path point as a pale wedge and widened the bounds, which also pushed the card off-center)
         this.hzcSubBg = this.hzcFreshBg(this.hzcSub,this.hzcSubBg);
         if(card)
         {
            var bg:Number = Number(this.hzcCfg.SubBgOpacity);
            if(isNaN(bg)) { bg = 0.7; }
            this.hzcCard(this.hzcSubBg.graphics,w,h,14 * sc,Math.max(0,Math.min(1,bg)),this.hzcAccent(),12 * sc,4 * sc);
         }
         // SubCard=0: text only, with a soft dark outline so it stays readable on bright scenes
         var fl:Array = card ? [] : [new GlowFilter(0x000000,0.7,4,4,2,2)];
         this.hzcSubBody.filters = fl;
         this.hzcSubName.filters = card ? [] : [new GlowFilter(0x000000,0.7,4,4,2,2)];
         this.hzcSub.visible = true;
         this.hzcShown = true;
         var spk:Boolean = int(this.hzcCfg.SpeakerCard) == 1 && this.hzcInDlg && who.length > 0 && !this.hzcDlgOwnsSpeaker();
         this.hzcSpk.visible = spk;
         if(spk) { this.hzcDrawSpeaker(who); }
         this.hzcLayout();
      }
      // fill + 1 px edge stroke + accent stripe, all on one fresh Shape's graphics (g)
      private function hzcCard(g:*, w:Number, h:Number, r:Number, bg:Number, acc:uint, inset:Number, sw:Number) : void
      {
         g.clear();
         g.lineStyle();
         g.beginFill(0x0B1218,bg); g.drawRoundRect(0,0,w,h,r * 2,r * 2); g.endFill();
         g.lineStyle(1,0xFFFFFF,HZC_EDGE,true);
         g.beginFill(0xFFFFFF,0.004); g.drawRoundRect(0.5,0.5,w - 1,h - 1,r * 2 - 1,r * 2 - 1); g.endFill();   // v0.40.3: the fill closes the path
         g.lineStyle();
         g.beginFill(acc,1); g.drawRoundRect(0,Math.round(inset),Math.max(2,sw),Math.max(4,h - 2 * Math.round(inset)),Math.max(2,sw),Math.max(2,sw)); g.endFill();
      }
      private function hzcFreshBg(p:Sprite, old:Shape) : Shape
      {
         if(old != null && old.parent == p) { p.removeChild(old); }   // our own Shape, never a vanilla object
         var s:Shape = new Shape();
         p.addChildAt(s,0);
         return s;
      }
      // [Comms] SubTextColor: -1 off-white (default), 0 - 12 the Horizon accent palette, 13 = SubTextHex
      private function hzcTextCol() : uint
      {
         var c:int = int(this.hzcCfg.SubTextColor);
         var hx:String = String(this.hzcCfg.SubTextHex);
         if(c == 13 && hx.length == 7 && hx.charAt(0) == "#") { var v:Number = parseInt(hx.substr(1),16); if(!isNaN(v)) { return uint(v); } }
         if(c >= 0 && c < HZC_ACC.length) { return uint(HZC_ACC[c]); }
         return HZC_TXT;
      }
      private function hzcDrawSpeaker(who:String) : void
      {
         var ts:Number = Number(this.hzcCfg.TextScale) * (HZC_LRG ? 1.25 : 1);
         var w:Number = Math.round(400 * ts);
         var h:Number = Math.round(86 * ts);
         var acc:uint = this.hzcAccent();
         this.hzcSpkBg = this.hzcFreshBg(this.hzcSpk,this.hzcSpkBg);
         var g:* = this.hzcSpkBg.graphics;
         this.hzcCard(g,w,h,14 * ts,0.8,acc,14 * ts,4 * ts);
         g.lineStyle(2 * ts,acc,0.7); g.beginFill(acc,0.08); g.drawCircle(46 * ts,43 * ts,26 * ts); g.endFill(); g.lineStyle();
         // original person glyph: head + shoulders
         g.beginFill(acc,0.9); g.drawCircle(46 * ts,36 * ts,7 * ts); g.endFill();
         g.beginFill(acc,0.9); g.drawRoundRect(34 * ts,46 * ts,24 * ts,12 * ts,12 * ts,12 * ts); g.endFill();
         this.hzcSet(this.hzcSpkName,who.toUpperCase(),"nm",20 * ts,0xE8F0F5,Math.round(20 * ts * 0.16),"left");
         this.hzcSpkName.x = Math.round(90 * ts); this.hzcSpkName.y = Math.round(16 * ts);
         this.hzcSet(this.hzcSpkSub,"SPEAKING","nm",13 * ts,acc,Math.round(13 * ts * 0.14),"left");
         this.hzcSpkSub.x = Math.round(100 * ts); this.hzcSpkSub.y = Math.round(50 * ts);
         var cw:Number = this.hzcSpkSub.textWidth + 20 * ts;
         g.lineStyle(1,acc,0.45,true); g.beginFill(acc,0.16); g.drawRoundRect(90 * ts,48 * ts,cw,this.hzcSpkSub.textHeight + 6 * ts,20 * ts,20 * ts); g.endFill(); g.lineStyle();
         this.hzcSpkW = w;
         this.hzcSpkH = h;
      }
      // visible rect in this movie's coordinates
      private function hzcVis() : Rectangle
      {
         try
         {
            var vr:Rectangle = Extensions.visibleRect;
            if(vr != null && vr.width >= 100 && stage != null)
            {
               var tl:Point = globalToLocal(new Point(vr.left,vr.top));
               var br:Point = globalToLocal(new Point(vr.right,vr.bottom));
               if(br.x - tl.x >= 100) { return new Rectangle(tl.x,tl.y,br.x - tl.x,br.y - tl.y); }
            }
         }
         catch(e:Error) { }
         return new Rectangle(0,0,1920,1080);
      }
      // [Layout] edge-anchored value ("L40", "R-20", "C0", "T10", "B60"); same rules as the HUD (offset from the Screen Margin line)
      private function hzcAnchor(v:String, axis:String, size:Number, lo:Number, hi:Number) : Number
      {
         if(v == null || v.length < 2) { return NaN; }
         var a:String = v.charAt(0).toUpperCase();
         var d:Number = Number(v.substr(1).replace(/\s/g,""));
         var m:Number = Number(this.hzcCfg.Margin);
         if(isNaN(m)) { m = 40; }
         if(!isNaN(d))
         {
            if(axis == "x") { if(a == "L") { return lo + m + d; } if(a == "R") { return hi - m - size - d; } if(a == "C") { return (lo + hi) / 2 - size / 2 + d; } }
            else { if(a == "T") { return lo + m + d; } if(a == "B") { return hi - m - size - d; } if(a == "C") { return (lo + hi) / 2 - size / 2 + d; } }
         }
         var f:Number = Number(v);   // a legacy 0-1 fraction
         return !isNaN(f) && f >= 0 && f <= 1 ? lo + f * (hi - lo) : NaN;
      }
      private function hzcSnap(v:Number) : Number
      {
         var sh:Number = Number(this.hzcCfg.ScreenHeight);
         var pu:Number = sh >= 360 ? 1080 / sh : 1;
         return Math.round(v / pu) * pu;
      }
      private function hzcLayout() : void
      {
         var vr:Rectangle = this.hzcVis();
         var w:Number = this.hzcSubW > 0 ? this.hzcSubW : 1040;
         var h:Number = this.hzcSubH > 0 ? this.hzcSubH : 120;
         var mid:Number = vr.x + vr.width / 2;
         var pos:int = int(this.hzcCfg.SubPosition);
         var x:Number = this.hzcAnchor(String(this.hzcCfg.SubtitleX),"x",w,vr.x,vr.right);
         var y:Number = this.hzcAnchor(String(this.hzcCfg.SubtitleY),"y",h,vr.y,vr.bottom);
         var placed:Boolean = !isNaN(x) || !isNaN(y);
         var ox:Number = Number(this.hzcCfg.SubOffsetX);
         var oy:Number = Number(this.hzcCfg.SubOffsetY);
         if(isNaN(x)) { x = mid - w / 2; }
         if(isNaN(y)) { y = pos == 2 ? vr.y + 120 : (pos == 1 ? vr.y + vr.height * 0.8 - h : vr.bottom - 80 - h); }
         // v0.33: the F11 offsets apply on top of the default spot and of the ARRANGE position (+Y = up)
         x += isNaN(ox) ? 0 : ox;
         y -= isNaN(oy) ? 0 : oy;
         // vanilla lifts its subtitles in dialogue (-230, -290 on a narrow aspect); FixedInDialogue=0 follows that
         if(this.hzcInDlg && int(this.hzcCfg.FixedInDialogue) == 0 && !placed) { y -= vr.width / vr.height < 1.7 ? 290 : 230; }
         this.hzcSub.x = this.hzcSnap(Math.max(vr.x,Math.min(vr.right - w,x)));
         this.hzcSub.y = this.hzcSnap(Math.max(vr.y,Math.min(vr.bottom - h,y)));
         if(this.hzcSpk.visible)
         {
            var sw:Number = this.hzcSpkW > 0 ? this.hzcSpkW : 400;
            var sh:Number = this.hzcSpkH > 0 ? this.hzcSpkH : 86;
            var sx:Number = this.hzcAnchor(String(this.hzcCfg.SpeakerX),"x",sw,vr.x,vr.right);
            var sy:Number = this.hzcAnchor(String(this.hzcCfg.SpeakerY),"y",sh,vr.y,vr.bottom);
            if(isNaN(sx)) { sx = vr.right - 710; }
            if(isNaN(sy)) { sy = vr.y + 300; }
            this.hzcSpk.x = this.hzcSnap(Math.max(vr.x,Math.min(vr.right - sw,sx)));
            this.hzcSpk.y = this.hzcSnap(Math.max(vr.y,Math.min(vr.bottom - sh,sy)));
         }
      }

      // ---------- v0.32 mission toast (mockup v032/mockups/mission_toast_v032.png) ----------
      // Reads the same QuestUpdateData the vanilla banner reads (subscribed after it). The vanilla QuestUpdate clips keep
      // running (sounds, the SET MISSION ACTIVE hold input, timers); only their alpha is 0 while MissionToast=1.
      private function hzcToastOn() : Boolean
      {
         return this.hzcIniState != 0 && int(this.hzcCfg.MissionToast) == 1;
      }
      private function hzcOnQuest(ev:FromClientDataEvent) : void
      {
         try
         {
            var a:* = ev != null && ev.data != null ? ev.data.QuestUpdatesA : null;
            if(a == null || a.length == 0) { return; }
            var i:int = 0;
            while(i < a.length)
            {
               if(this.hzcIniState == 0) { if(this.hzcTstPend.length < 16) { this.hzcTstPend.push(a[i]); } }
               else if(this.hzcToastOn()) { this.hzcToastFrom(a[i]); }
               i++;
            }
            this.hzcRefreshAlphas();
         }
         catch(e:Error) { }
      }
      // after an ini read: pending updates become toasts (or are dropped when the toast is off: vanilla showed them)
      private function hzcToastApply() : void
      {
         var p:Array = this.hzcTstPend;
         this.hzcTstPend = [];
         if(!this.hzcToastOn())
         {
            while(this.hzcTsts.length > 0) { this.hzcToastKill(0); }
            this.hzcToastVis();
            return;
         }
         for each(var d:Object in p) { this.hzcToastFrom(d); }
         this.hzcToastLayout();
         this.hzcToastVis();
      }
      private function hzcIsOpt(s:String) : Boolean
      {
         var re:RegExp = new RegExp("^\\s*[(\\[]?\\s*optional\\b","i");
         return re.test(s) || s.toLowerCase().indexOf("(optional)") >= 0;
      }
      private function hzcOptText(s:String) : String
      {
         var lead:RegExp = new RegExp("^\\s*[(\\[]?\\s*optional\\s*[)\\]]?\\s*[:\\-]?\\s*","i");
         var mid:RegExp = new RegExp("\\s*\\(optional\\)\\s*","i");
         var t:String = s.replace(lead,"").replace(mid," ").replace(/^\s+|\s+$/g,"");
         return "Optional: " + t;
      }
      private function hzcToastFrom(d:Object) : void
      {
         if(d == null) { return; }
         var t:uint = uint(d.uType);
         var st:int = -1;
         if(t == QuestMessage.QUEST_ADDED) { st = 1; }
         else if(t == QuestMessage.QUEST_COMPLETED) { st = 3; }
         else if(t == QuestMessage.QUEST_FAILED) { st = 4; }
         else if(t == QuestMessage.OBJECTIVE_ADDED || t == QuestMessage.OBJECTIVE_FAILED) { st = 0; }
         else if(t == QuestMessage.OBJECTIVE_COMPLETED) { st = 2; }
         if(st < 0) { return; }
         var title:String = d.strQuestName != null ? String(d.strQuestName) : "";
         var want:String = st == 2 ? "bCompleted" : (t == QuestMessage.OBJECTIVE_FAILED ? "bFailed" : (st == 0 ? "bAdded" : ""));
         var main:String = "";
         var opt:String = "";
         var first:String = "";
         var obs:* = d.ObjectiveDataA;
         var j:int = 0;
         while(obs != null && j < obs.length)
         {
            var o:Object = obs[j];
            j++;
            if(o == null || Boolean(o.bDormant)) { continue; }
            var tx:String = o.strObjectiveText != null ? String(o.strObjectiveText) : "";
            if(tx.length == 0) { continue; }
            var hit:Boolean = want.length == 0 || Boolean(o[want]);
            if(this.hzcIsOpt(tx)) { if(opt.length == 0 && hit) { opt = this.hzcOptText(tx); } continue; }
            if(first.length == 0) { first = tx; }
            if(hit && main.length == 0) { main = tx; }
         }
         if(main.length == 0 && st != 3 && st != 4) { main = first; }
         if(main.length == 0 && opt.length > 0) { main = opt; opt = ""; }
         var q:String = d.uQuestID != undefined ? String(d.uQuestID) : title;
         var now:int = getTimer();
         // the game often sends "quest added" + "objective added" (or objective + quest complete) together: one card
         for each(var e:Object in this.hzcTsts)
         {
            if(e.q == q && now - int(e.t0) < 2500)
            {
               if(int(HZC_TST_PRIO[st]) >= int(HZC_TST_PRIO[int(e.st)])) { e.st = st; if(main.length > 0) { e.line = main; } }
               else if(String(e.line).length == 0) { e.line = main; }
               if(String(e.sub).length == 0) { e.sub = opt; }
               if(title.length > 0) { e.title = title; }
               e.t0 = now;
               this.hzcToastDraw(e);
               this.hzcToastLayout();
               return;
            }
         }
         var s:Sprite = new Sprite();
         var n:Object = {"s":s,"q":q,"st":st,"title":title,"line":main,"sub":opt,"t0":now,"h":0,"bar":null,"w":0};
         this.hzcTsts.unshift(n);   // newest on top
         this.hzcTstLayer.addChild(s);
         var mx:int = Math.max(1,Math.min(5,int(this.hzcCfg.MissionToastMax)));
         while(this.hzcTsts.length > mx) { this.hzcToastKill(this.hzcTsts.length - 1); }
         this.hzcToastDraw(n);
         this.hzcToastLayout();
         this.hzcToastVis();
         if(!this.hzcTstTick) { this.hzcTstTick = true; addEventListener(Event.ENTER_FRAME,this.hzcToastFrame); }
      }
      private function hzcToastKill(i:int) : void
      {
         var e:Object = this.hzcTsts[i];
         this.hzcTsts.splice(i,1);
         try { if(e && e.s && Sprite(e.s).parent == this.hzcTstLayer) { this.hzcTstLayer.removeChild(Sprite(e.s)); } } catch(err:Error) { }
      }
      private function hzcToastCol(st:int) : uint
      {
         if(st == 2 || st == 3) { return HZC_GRN; }
         if(st == 4) { return HZC_RED; }
         return this.hzcAccent();
      }
      // v0.34: MissionToastScale -1 = the global HUD SCALE, else the toast's own size (HUD SCALE no longer applies to it)
      private function hzcToastSize() : Number
      {
         var v:Number = Number(this.hzcCfg.MissionToastScale);
         if(!isNaN(v) && v > 0) { return Math.max(0.6,Math.min(1.6,v)); }
         var g:Number = Number(this.hzcCfg.HudScale);
         return isNaN(g) || g <= 0 ? 1 : Math.max(0.7,Math.min(1.4,g));
      }
      private function hzcToastScale() : Number { return Number(this.hzcCfg.TextScale) * (HZC_LRG ? 1.25 : 1) * this.hzcToastSize(); }
      // one-line field cut to maxW with "..."
      private function hzcFit(tf:TextField, maxW:Number) : void
      {
         if(tf.textWidth <= maxW) { return; }
         var s:String = tf.text;
         var f:TextFormat = tf.getTextFormat();
         var n:int = s.length;
         while(n > 1)
         {
            n--;
            tf.text = s.substr(0,n).replace(/\s+$/,"") + "...";
            tf.setTextFormat(f);
            if(tf.textWidth <= maxW) { return; }
         }
      }
      private function hzcToastDraw(e:Object) : void
      {
         var s:Sprite = Sprite(e.s);
         while(s.numChildren > 0) { s.removeChildAt(0); }   // our own children only
         var z:Number = this.hzcToastScale();
         var st:int = int(e.st);
         var col:uint = this.hzcToastCol(st);
         var W:Number = Math.round(460 * z);
         var hasLine:Boolean = String(e.line).length > 0;
         var hasSub:Boolean = String(e.sub).length > 0;
         var H:Number = Math.round((hasLine ? 88 : 66) * z + (hasSub ? 22 * z : 0));
         var bg:Shape = new Shape();
         s.addChild(bg);
         var g:* = bg.graphics;
         this.hzcCard(g,W,H,16 * z,0.8,col,10 * z,3 * z);
         // icon tile + state glyph (original vector art)
         var cx:Number = Math.round(44 * z);
         var cy:Number = Math.round((hasLine ? 44 : 33) * z);
         g.beginFill(0x060A0E,0.92); g.drawCircle(cx,cy,24 * z); g.endFill();
         g.lineStyle(1.4 * z,col,0.45,true); g.drawCircle(cx,cy,19 * z); g.lineStyle();
         this.hzcToastIcon(g,st,cx,cy,z,col);
         var tx:Number = Math.round(80 * z);
         var maxW:Number = W - tx - 18 * z;
         var hd:TextField = this.hzcField(true);
         this.hzcSet(hd,String(HZC_TST_HEAD[st]),"nm",13 * z,col,Math.round(13 * z * 0.18),"left");
         hd.x = tx; hd.y = Math.round(10 * z);
         s.addChild(hd);
         var tt:TextField = this.hzcField(true);
         this.hzcSet(tt,String(e.title).toUpperCase(),"nm",19 * z,0xF2F7F9,Math.round(19 * z * 0.12),"left");
         this.hzcFit(tt,maxW);
         tt.x = tx; tt.y = Math.round(27 * z);
         s.addChild(tt);
         if(hasLine)
         {
            var ln:TextField = this.hzcField(false);
            this.hzcSet(ln,String(e.line),"rg",16 * z,0x96A6AE,0,"left");
            this.hzcFit(ln,maxW);
            ln.x = tx; ln.y = Math.round(53 * z);
            s.addChild(ln);
         }
         if(hasSub)
         {
            var sb:TextField = this.hzcField(false);
            this.hzcSet(sb,String(e.sub),"rg",14 * z,0x6E7C84,0,"left");
            this.hzcFit(sb,maxW - 12 * z);
            sb.x = tx + Math.round(12 * z); sb.y = Math.round(75 * z);
            s.addChild(sb);
            var dy:Number = sb.y + sb.textHeight / 2 + 2;
            g.lineStyle(1.2,0x6E7C84,1,true);
            g.moveTo(tx + 4 * z,dy - 3.5 * z); g.lineTo(tx + 7.5 * z,dy); g.lineTo(tx + 4 * z,dy + 3.5 * z); g.lineTo(tx + 0.5 * z,dy); g.lineTo(tx + 4 * z,dy - 3.5 * z);
            g.lineStyle();
         }
         var bar:Shape = new Shape();
         bar.x = tx; bar.y = H - Math.round(10 * z);
         s.addChild(bar);
         e.bar = bar;
         e.w = W;
         e.h = H;
         e.bw = maxW;
         this.hzcToastBar(e,1);
      }
      private function hzcToastIcon(g:*, st:int, cx:Number, cy:Number, z:Number, col:uint) : void
      {
         if(st == 2 || st == 3)
         {
            g.lineStyle(2.4 * z,col,1,true,"normal","round","round");
            g.moveTo(cx - 7 * z,cy); g.lineTo(cx - 2 * z,cy + 5 * z); g.lineTo(cx + 8 * z,cy - 6 * z);
            g.lineStyle();
         }
         else if(st == 4)
         {
            g.lineStyle(2.4 * z,col,1,true,"normal","round");
            g.moveTo(cx - 6 * z,cy - 6 * z); g.lineTo(cx + 6 * z,cy + 6 * z);
            g.moveTo(cx + 6 * z,cy - 6 * z); g.lineTo(cx - 6 * z,cy + 6 * z);
            g.lineStyle();
         }
         else if(st == 1)
         {
            g.lineStyle(1.6 * z,col,1,true);
            g.moveTo(cx,cy - 10 * z); g.lineTo(cx + 10 * z,cy); g.lineTo(cx,cy + 10 * z); g.lineTo(cx - 10 * z,cy); g.lineTo(cx,cy - 10 * z);
            g.moveTo(cx - 4 * z,cy); g.lineTo(cx + 4 * z,cy);
            g.moveTo(cx,cy - 4 * z); g.lineTo(cx,cy + 4 * z);
            g.lineStyle();
         }
         else
         {
            g.beginFill(col,1);
            g.moveTo(cx,cy - 8 * z); g.lineTo(cx + 8 * z,cy); g.lineTo(cx,cy + 8 * z); g.lineTo(cx - 8 * z,cy); g.lineTo(cx,cy - 8 * z);
            g.endFill();
         }
      }
      // thin timer bar along the bottom: k = share of time left
      private function hzcToastBar(e:Object, k:Number) : void
      {
         var b:Shape = e.bar as Shape;
         if(b == null) { return; }
         var z:Number = this.hzcToastScale();
         var w:Number = Number(e.bw);
         var h:Number = Math.max(2,Math.round(2 * z));
         var col:uint = this.hzcToastCol(int(e.st));
         var g:* = b.graphics;
         g.clear();
         g.beginFill(0xFFFFFF,0.07); g.drawRoundRect(0,0,w,h,h,h); g.endFill();
         if(k > 0) { g.beginFill(col,0.67); g.drawRoundRect(0,0,Math.max(h,w * k),h,h,h); g.endFill(); }
      }
      private function hzcToastFrame(ev:Event) : void
      {
         try
         {
            var now:int = getTimer();
            var dur:Number = Math.max(2,Math.min(15,Number(this.hzcCfg.MissionToastTime))) * 1000;
            var i:int = this.hzcTsts.length - 1;
            var gone:Boolean = false;
            while(i >= 0)
            {
               var e:Object = this.hzcTsts[i];
               var age:Number = now - int(e.t0);
               if(age >= dur) { this.hzcToastKill(i); gone = true; }
               else
               {
                  var s:Sprite = Sprite(e.s);
                  s.alpha = age < 150 ? age / 150 : (dur - age < 300 ? (dur - age) / 300 : 1);
                  this.hzcToastBar(e,1 - age / dur);
               }
               i--;
            }
            if(gone) { this.hzcToastLayout(); }
            if(this.hzcTsts.length == 0) { this.hzcTstTick = false; removeEventListener(Event.ENTER_FRAME,this.hzcToastFrame); }
            this.hzcRefreshAlphas();   // vanilla never re-shows a banner under the toast
         }
         catch(err:Error) { }
      }
      // shown unless the scanner is open with [Scanner] HideQuestPopupsWhileScanning=1
      private function hzcToastVis() : void
      {
         if(this.hzcTstLayer == null) { return; }
         var hide:Boolean = this.hzcScan && int(this.hzcCfg.HideQuestPopupsWhileScanning) == 1;
         this.hzcTstLayer.visible = this.hzcToastOn() && !hide;
      }
      // default spot top-center under the compass; [Layout] MissionToastX/Y anchor the newest card, the stack grows away
      // from the anchored edge (down, or up for a B anchor)
      private function hzcToastLayout() : void
      {
         if(this.hzcTsts.length == 0) { return; }
         var vr:Rectangle = this.hzcVis();
         var z:Number = this.hzcToastScale();
         var W:Number = Math.round(460 * z);
         var H0:Number = Math.round(88 * z);
         var m:Number = Number(this.hzcCfg.Margin);
         if(isNaN(m)) { m = 40; }
         var x:Number = this.hzcAnchor(String(this.hzcCfg.MissionToastX),"x",W,vr.x,vr.right);
         var ys:String = String(this.hzcCfg.MissionToastY);
         var y:Number = this.hzcAnchor(ys,"y",H0,vr.y,vr.bottom);
         if(isNaN(x)) { x = vr.x + vr.width / 2 - W / 2; }
         if(isNaN(y)) { y = vr.y + Math.max(28,m - 12) + 90; }
         var up:Boolean = ys.length > 1 && ys.charAt(0).toUpperCase() == "B";
         x = Math.max(vr.x,Math.min(vr.right - W,x));
         var gap:Number = Math.round(8 * z);
         var cy:Number = up ? y + H0 : y;
         for each(var e:Object in this.hzcTsts)
         {
            var s:Sprite = Sprite(e.s);
            var h:Number = Number(e.h);
            var top:Number = up ? cy - h : cy;
            s.x = this.hzcSnap(x);
            s.y = this.hzcSnap(Math.max(vr.y,Math.min(vr.bottom - h,top)));
            cy = up ? top - gap : top + h + gap;
         }
      }
      // ---------- v0.42.0 r2: companion reaction card ([Comms] ReactionCard) ----------
      private static const HZC_RX_VERB:Array = ["loved","liked","disliked","hated"];
      private static const HZC_RX_LBL:Array = ["LOVED THAT","LIKED THAT","DISLIKED THAT","HATED THAT"];
      private static const HZC_RX_COL:Array = [0x4FD1B8,0x5EE3A1,0xF2A93B,0xFF5B5B];   // liked = the scanner's companion green (noted)
      private static const HZC_RX_DIR:Array = [2,1,-1,-2];
      private static const HZC_RX_NOT:Array = ["you","i","we","they","he","she","it","everyone","everybody","someone","somebody","nobody","no one","people","all","this","that"];
      private static const HZC_RX_LABEL:uint = 0xC4D2D9;
      private static const HZC_RX_PART:Array = ["de","da","del","van","von","der","of","the","la","le","du","al"];
      private var hzcRx:Array = [];          // {it: the game's HUDMessageItem, st: -1 pending / 0 game line / 1 card, n, k, c: card, w, h, f: pending frames, sig}
      private var hzcRxLayer:Sprite = null;
      private var hzcRxOff:Boolean = false;  // set after an error: every line stays the game's for this session
      private function hzcRxInit() : void
      {
         this.hzcRxLayer = new Sprite();
         this.hzcRxLayer.mouseEnabled = false;
         this.hzcRxLayer.mouseChildren = false;
         addChild(this.hzcRxLayer);
         addEventListener(Event.ADDED,this.hzcRxAdded);
         addEventListener(Event.ENTER_FRAME,this.hzcRxFrame);
      }
      private function hzcRxOn() : Boolean
      {
         return !this.hzcRxOff && this.hzcIniState != 0 && int(this.hzcCfg.ReactionCard) == 1 && this.Messages_mc != null;
      }
      // whole-line match, English game text: "<Name> loved|liked|disliked|hated that." -> {n, k} or null
      private function hzcRxMatch(t:String) : Object
      {
         var s:String = this.hzcRxNorm(t);   // r3: normalized (spaces, trailing line break)
         if(s == null || s.indexOf("\n") >= 0 || s.indexOf("\r") >= 0) { return null; }
         if(s.length < 11 || s.length > 64) { return null; }
         var m:Object = /^(.+?) (loved|liked|disliked|hated) that\.$/.exec(s);
         if(m == null) { return null; }
         var n:String = String(m[1]);
         if(n.length < 1 || n.length > 40) { return null; }
         if(!/^[A-Z0-9\u00C0-\u00DE][A-Za-z0-9\u00C0-\u024F'\u2019.\- ]*$/.test(n)) { return null; }
         var ws:Array = n.split(" ");
         if(ws.length > 4) { return null; }
         for each(var w:String in ws)   // every word starts with a capital or a digit (name particles excepted)
         {
            if(w.length == 0) { return null; }
            if(!/^[A-Z0-9\u00C0-\u00DE]/.test(w) && HZC_RX_PART.indexOf(w) < 0) { return null; }
         }
         if(HZC_RX_NOT.indexOf(n.toLowerCase()) >= 0) { return null; }
         var k:int = HZC_RX_VERB.indexOf(String(m[2]));
         if(k < 0) { return null; }
         return {"n":n,"k":k};
      }
      // r3: no-break / figure / narrow no-break spaces and tabs -> space, space runs -> one, trimmed (a trailing line break too)
      private function hzcRxNorm(t:String) : String
      {
         if(t == null) { return null; }
         var s:String = t.replace(/[\u00A0\u2007\u202F\u2009\u200A\t]/g," ").replace(/[\u200B\uFEFF]/g,"");
         s = s.replace(/^[\s]+|[\s]+$/g,"").replace(/ {2,}/g," ");
         return s;
      }
      // ---------- r3: debug-only message log ([Debug] Debug=1; off by default) ----------
      private var hzcRxDbgOn:Boolean = false;
      private var hzcRxDbgQ:Array = [];
      private var hzcRxDbgSeen:Array = [];   // {it, f}
      private var hzcRxDbgHdr:Boolean = false;
      private function hzcRxDbgIni(txt:String) : void
      {
         var on:Boolean = false;
         var sec:String = "";
         if(txt != null)
         {
            for each(var raw:String in txt.split("\r").join("").split("\n"))
            {
               var ln:String = raw.replace(/^[\s\uFEFF]+|\s+$/g,"");
               if(ln.length == 0 || ln.charAt(0) == ";" || ln.charAt(0) == "#") { continue; }
               if(ln.charAt(0) == "[") { var e:int = ln.indexOf("]"); sec = (e > 0 ? ln.substring(1,e) : ln.substr(1)).replace(/^\s+|\s+$/g,"").toLowerCase(); continue; }
               if(sec != "debug") { continue; }
               var i:int = ln.indexOf("=");
               if(i <= 0) { continue; }
               if(ln.substr(0,i).replace(/\s+$/,"").toLowerCase() != "debug") { continue; }
               var v:String = ln.substr(i + 1);
               var c:int = v.indexOf(";");
               if(c >= 0) { v = v.substr(0,c); }
               on = int(Number(v.replace(/^\s+|\s+$/g,""))) == 1;
            }
         }
         if(!on) { this.hzcRxDbgQ = []; this.hzcRxDbgSeen = []; }
         this.hzcRxDbgOn = on;
      }
      private function hzcRxDbgEsc(t:String) : String
      {
         var o:String = "";
         var i:int = 0;
         while(i < t.length && i < 200)
         {
            var c:int = t.charCodeAt(i);
            if(c < 32 || c > 126 || c == 92) { var h:String = c.toString(16).toUpperCase(); while(h.length < 4) { h = "0" + h; } o += "\\u" + h; }
            else { o += t.charAt(i); }
            i++;
         }
         return o;
      }
      private function hzcRxDbgPath(d:*) : String
      {
         var a:Array = [];
         var n:int = 0;
         try { while(d != null && n < 12) { a.unshift(String(d.name) + "(" + String(d).replace("[object ","").replace("]","") + ")"); if(d === this) { break; } d = d.parent; n++; } } catch(e:Error) { }
         return a.join(".");
      }
      private function hzcRxDbgPush(s:String) : void
      {
         if(this.hzcRxDbgQ.length >= 40) { this.hzcRxDbgQ.shift(); }
         this.hzcRxDbgQ.push(s);
      }
      // every new line once (waits up to 3 frames for its text)
      private function hzcRxDbgScan(arr:*) : void
      {
         if(!this.hzcRxDbgOn || arr == null) { return; }
         if(!this.hzcRxDbgHdr) { this.hzcRxDbgHdr = true; this.hzcRxDbgPush("comms " + this.hzcBuildId() + ": message column " + this.hzcRxDbgPath(this.Messages_mc) + ", ReactionCard=" + this.hzcCfg.ReactionCard + ", ini state " + this.hzcIniState + ", card code " + (this.hzcRxOff ? "off after an error" : "on")); }
         var keep:Array = [];
         for each(var s0:Object in this.hzcRxDbgSeen) { if(arr.indexOf(s0.it) >= 0) { keep.push(s0); } }
         this.hzcRxDbgSeen = keep;
         var i:int = 0;
         while(i < arr.length)
         {
            var it:* = arr[i];
            i++;
            var se:Object = null;
            for each(var s1:Object in this.hzcRxDbgSeen) { if(s1.it === it) { se = s1; break; } }
            if(se == null) { se = {"it":it,"f":0,"done":false}; this.hzcRxDbgSeen.push(se); }
            if(se.done) { continue; }
            var tx:String = "";
            try { tx = String(it.Internal_mc.Text_tf.text); } catch(e0:Error) { tx = ""; }
            if(tx.length == 0 && se.f < 3) { se.f++; continue; }
            se.done = true;
            var r:Object = null;
            try { r = this.hzcRxMatch(tx); } catch(e1:Error) { r = null; }
            var tfp:String = "";
            try { tfp = this.hzcRxDbgPath(it.Internal_mc.Text_tf); } catch(e2:Error) { tfp = this.hzcRxDbgPath(it); }
            this.hzcRxDbgPush("line \"" + this.hzcRxDbgEsc(tx) + "\" len " + tx.length + " | " + tfp + " | match " + (r == null ? "none (stays the game's line)" : "'" + r.n + "' " + HZC_RX_VERB[r.k]) + " | ReactionCard " + this.hzcCfg.ReactionCard + (this.hzcRxOn() ? "" : " (cards off)"));
         }
      }
      public function hzcTakeDbg() : String
      {
         try
         {
            if(!this.hzcRxDbgOn || this.hzcRxDbgQ.length == 0) { return ""; }
            var o:String = this.hzcRxDbgQ.join("\n");
            this.hzcRxDbgQ = [];
            return o;
         }
         catch(e:Error) { }
         return "";
      }
      public function hzcBuildId() : String
      {
         return "0.42.0 r3";
      }
      private function hzcRxFind(it:*) : Object
      {
         for each(var e:Object in this.hzcRx) { if(e.it === it) { return e; } }
         return null;
      }
      // a new game line: hidden until it is classified (at most a few frames; it is still fading in from frame 1)
      private function hzcRxAdded(ev:Event) : void
      {
         try
         {
            var it:* = ev.target;
            if(it == null || it.parent !== this.Messages_mc || !this.hzcRxOn()) { return; }
            if(this.hzcRxFind(it) != null) { return; }
            var im:* = it.Internal_mc;
            if(im == null) { return; }
            im.visible = false;
            this.hzcRx.push({"it":it,"st":-1,"f":0});
         }
         catch(e:Error) { }
      }
      private function hzcRxShow(e:Object) : void
      {
         try { if(e.it != null && e.it.Internal_mc != null) { e.it.Internal_mc.visible = true; } } catch(err:Error) { }
         if(e.c != null) { e.c.visible = false; }
      }
      private function hzcRxDrop(e:Object) : void
      {
         if(e.c != null && e.c.parent == this.hzcRxLayer) { this.hzcRxLayer.removeChild(e.c); }
         e.c = null;
      }
      // everything back to the game's lines (ReactionCard=0, an error)
      private function hzcRxAll() : void
      {
         for each(var e:Object in this.hzcRx) { this.hzcRxShow(e); this.hzcRxDrop(e); e.st = 0; }
      }
      private function hzcRxApply() : void
      {
         if(!this.hzcRxOn()) { this.hzcRxAll(); return; }
         for each(var e:Object in this.hzcRx) { e.sig = ""; }
      }
      private function hzcRxFrame(ev:Event) : void
      {
         if(this.hzcRxOff) { if(this.hzcRxDbgOn) { try { this.hzcRxDbgScan(this.Messages_mc != null ? this.Messages_mc.ShownMessageArray : null); } catch(eDbg2:Error) { } } return; }
         try { this.hzcRxStep(); }
         catch(err:Error) { this.hzcRxOff = true; try { this.hzcRxAll(); } catch(err2:Error) { } }
      }
      private function hzcRxStep() : void
      {
         var m:* = this.Messages_mc;
         if(m == null) { return; }
         var arr:* = m.ShownMessageArray;
         var on:Boolean = this.hzcRxOn();
         // lines that left the game's list: drop their cards
         var keep:Array = [];
         for each(var e0:Object in this.hzcRx)
         {
            if(arr == null || arr.indexOf(e0.it) < 0 || e0.it.parent !== m) { this.hzcRxDrop(e0); continue; }
            keep.push(e0);
         }
         this.hzcRx = keep;
         if(arr == null || this.hzcRxLayer == null) { return; }
         if(this.hzcRxDbgOn) { try { this.hzcRxDbgScan(arr); } catch(eDbg:Error) { } }   // r3: debug-only log
         if(!on) { this.hzcRxAll(); return; }
         // lines already shown before the listener saw them: classified once, never hidden first
         var i:int = 0;
         while(i < arr.length) { if(this.hzcRxFind(arr[i]) == null) { this.hzcRx.push({"it":arr[i],"st":-1,"f":3}); } i++; }
         var newest:Object = null;
         for each(var e:Object in this.hzcRx)
         {
            if(e.st == -1)
            {
               var tx:String = "";
               try { tx = String(e.it.Internal_mc.Text_tf.text); } catch(err0:Error) { tx = ""; }
               if(tx.length == 0 && e.f < 3) { e.f++; continue; }
               var r:Object = this.hzcRxMatch(tx);
               if(r == null) { e.st = 0; this.hzcRxShow(e); continue; }
               e.st = 1; e.n = r.n; e.k = r.k; e.sig = "";
            }
            if(e.st == 1) { newest = e; }
         }
         for each(var e2:Object in this.hzcRx)
         {
            if(e2.st != 1) { continue; }
            this.hzcRxPlace(e2,e2 === newest,m);
         }
      }
      private function hzcRxScale() : Number
      {
         var s:Number = this.hzcScale();
         if(isNaN(s) || s <= 0) { s = 1; }
         return Math.max(13 / 14,Math.min(1.3,s));   // 13 px text at least; at most 1.3 so it stays near the game's line height
      }
      private function hzcRxPlace(e:Object, newest:Boolean, m:*) : void
      {
         var it:* = e.it;
         var im:* = it.Internal_mc;
         im.visible = false;
         var fr:int = int(it.currentFrame);
         var live:Boolean = it.visible && m.visible && it.fadeInStarted && !it.fullyFadedOut && fr < 70;
         var sig:String = (newest ? "1" : "0") + "|" + this.hzcRxScale() + "|" + this.hzcCfg.SubCard + "|" + this.hzcCfg.SubBgOpacity + "|" + this.hzcCfg.SpeakerColor + "|" + this.hzcCfg.SpeakerHex + "|" + this.hzcCfg.SubFont + "|" + this.hzcCfg.FontFace + "|" + this.hzcCfg.AccentColor + "|" + this.hzcCfg.AccentHex;
         if(e.c == null || e.sig != sig) { e.sig = sig; this.hzcRxDraw(e,newest); }
         if(!live) { e.c.visible = false; return; }
         var bg:* = im.Background_mc;
         var gp:Point = im.localToGlobal(new Point(bg.x + bg.width,bg.y + bg.height / 2));
         var lp:Point = this.globalToLocal(gp);
         e.c.x = Math.round(lp.x - e.w);
         e.c.y = Math.round(lp.y - e.h / 2);
         e.c.alpha = Math.max(0,Math.min(1,it.alpha * im.alpha * m.alpha));
         e.c.visible = true;
      }
      private function hzcRxDraw(e:Object, newest:Boolean) : void
      {
         this.hzcRxDrop(e);
         var c:Sprite = new Sprite();
         c.mouseEnabled = false;
         c.mouseChildren = false;
         var z:Number = this.hzcRxScale();
         var col:uint = uint(HZC_RX_COL[e.k]);
         var card:Boolean = int(this.hzcCfg.SubCard) == 1;
         var fs:Number = Math.max(13,Math.round(14 * z));
         var h:Number = Math.round(44 * z);
         var nm:TextField = this.hzcField(true);
         this.hzcSet(nm,String(e.n).toUpperCase(),"nm",fs,this.hzcSpeakerCol(),Math.round(fs * 0.1 * 10) / 10,"left");
         var lb:TextField = this.hzcField(true);
         this.hzcSet(lb,String(HZC_RX_LBL[e.k]),"nm",fs,col,Math.round(fs * 0.12 * 10) / 10,"left");
         var nx:Number = Math.round((14 + 30 + 12) * z);
         var nw:Number = Math.ceil(nm.textWidth);
         var lx:Number = Math.round(nx + nw + 14 * z);
         var w:Number = Math.round(lx + Math.ceil(lb.textWidth) + 18 * z);
         var g:* = c.graphics;
         if(card)
         {
            g.beginFill(0x0B1218,Math.max(0,Math.min(1,Number(this.hzcCfg.SubBgOpacity))));
            g.drawRoundRect(0,0,w,h,h,h);
            g.endFill();
            if(newest) { g.lineStyle(1,col,150 / 255,true); } else { g.lineStyle(1,0xFFFFFF,HZC_EDGE,true); }
            g.beginFill(0xFFFFFF,0.004); g.drawRoundRect(0.5,0.5,w - 1,h - 1,h - 1,h - 1); g.endFill();
            g.lineStyle();
         }
         // chevron tile
         var tr:Number = 15 * z;
         var tcx:Number = 14 * z + tr;
         var tcy:Number = h / 2;
         g.lineStyle(1,col,170 / 255,true);
         g.beginFill(0xFFFFFF,12 / 255); g.drawCircle(tcx,tcy,tr); g.endFill();
         var d:int = int(HZC_RX_DIR[e.k]);
         var n:int = d < 0 ? -d : d;
         var hw:Number = 6 * z;
         var hh:Number = 3 * z;
         var j:int = 0;
         g.lineStyle(2.2 * z,col,1,true,"normal","round","round");
         while(j < n)
         {
            var oy:Number = n == 2 ? (j == 0 ? -4 * z : 4 * z) : 0;
            var cy:Number = tcy + oy;
            if(d > 0) { g.moveTo(tcx - hw,cy + hh); g.lineTo(tcx,cy - hh); g.lineTo(tcx + hw,cy + hh); }
            else { g.moveTo(tcx - hw,cy - hh); g.lineTo(tcx,cy + hh); g.lineTo(tcx + hw,cy - hh); }
            j++;
         }
         g.lineStyle();
         // separator dot
         g.beginFill(HZC_RX_LABEL,160 / 255); g.drawCircle(nx + nw + 7 * z,tcy,1.5 * z); g.endFill();
         nm.x = nx; nm.y = Math.round(h / 2 - nm.height / 2);
         lb.x = lx; lb.y = Math.round(h / 2 - lb.height / 2);
         if(!card) { var gf:GlowFilter = new GlowFilter(0x000000,0.85,4,4,3,1); nm.filters = [gf]; lb.filters = [gf]; }
         c.addChild(nm);
         c.addChild(lb);
         c.visible = false;
         this.hzcRxLayer.addChild(c);
         e.c = c; e.w = w; e.h = h;
      }
      // =================== v0.37 shared settings reader (hzc37) ===================
      // ONE helper, spliced into every movie that reads the settings (hudmenu + hudmenu_lrg as hz37, hudmessagesmenu
      // x2 as hzc37, dialoguemenu x2 as hzd37; generated from /workspace/v037/work/hzini_shared.as, so the copies are
      // identical apart from the prefix). It reads HorizonUI.default.ini, HorizonUI.user.ini, HorizonUI.state.ini and the
      // legacy HorizonUI.ini (paths relative to Data/Interface) one after the other and hands every waiting callback the
      // merged text: the defaults with user.ini laid over (hzc37Compose; mirrors HZF::Compose in HorizonUI.dll). A missing
      // file is normal: its IOErrorEvent is caught and simply counts as "no file" (nothing is thrown or logged).
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hzc37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hzc37_BOM:String = String.fromCharCode(0xFEFF);
      private var hzc37Ldr:URLLoader = null;
      private var hzc37Step:int = 0;          // 0 idle, n = reading hzc37_FILES[n - 1]
      private var hzc37T0:Number = 0;
      private var hzc37Got:Array = null;
      private var hzc37Q:Array = [];          // callbacks of the running read
      private var hzc37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private function hzc37Ws(c:String) : Boolean { return c == " " || c == "\t" || c == "\r" || c == "\n"; }
      private function hzc37Trim(s:String) : String
      {
         var b:int = 0;
         var e:int = s.length;
         while(b < e && (this.hzc37Ws(s.charAt(b)) || s.charAt(b) == hzc37_BOM)) { b++; }
         while(e > b && this.hzc37Ws(s.charAt(e - 1))) { e--; }
         return s.substring(b,e);
      }
      private function hzc37Blank(s:String) : Boolean { return this.hzc37Trim(s).length == 0; }
      private function hzc37Lines(t:String) : Array
      {
         var out:Array = [];
         if(t == null || t.length == 0) { return out; }
         if(t.charAt(0) == hzc37_BOM) { t = t.substr(1); }
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
      private function hzc37Hdr(ln:String) : String
      {
         var t:String = this.hzc37Trim(ln);
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return this.hzc37Trim(t.substring(1,e)).toLowerCase();
      }
      private function hzc37Alias(n:String) : String
      {
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // key=value line -> {k: key lower case without blanks, o: key as written, v: value up to ';'}; null otherwise
      private function hzc37KV(ln:String) : Object
      {
         var t:String = this.hzc37Trim(ln);
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         var o:String = this.hzc37Trim(t.substr(0,eq));
         var k:String = o.split(" ").join("").split("\t").join("").toLowerCase();
         if(k.length == 0) { return null; }
         var v:String = t.substr(eq + 1);
         var sc:int = v.indexOf(";");
         if(sc >= 0) { v = v.substr(0,sc); }
         return {"k":k,"o":o,"v":this.hzc37Trim(v)};
      }
      // sections; a second copy / the pre-v0.31 name merges into the first, old names first so the new name wins
      private function hzc37Parse(t:String) : Object
      {
         var d:Object = {"secs":[{"n":"","raw":[],"order":[],"kv":{}}],"idx":{"s_":0}};
         var lines:Array = this.hzc37Lines(t);
         var pass:int = 0;
         while(pass < 2)
         {
            var cur:Object = d.secs[0];
            var old:Boolean = false;
            for each(var ln:String in lines)
            {
               var h:String = this.hzc37Hdr(ln);
               if(h != null)
               {
                  old = h == "cards v0.26" || h == "effects v0.26";
                  var n:String = this.hzc37Alias(h);
                  if((pass == 0) != old) { cur = null; continue; }
                  if(d.idx["s_" + n] == undefined) { d.idx["s_" + n] = d.secs.length; d.secs.push({"n":n,"raw":[],"order":[],"kv":{}}); }
                  cur = d.secs[int(d.idx["s_" + n])];
                  cur.raw.push(ln);
                  continue;
               }
               if(cur == null) { continue; }
               if(pass == 0 && cur.n == "") { continue; }
               cur.raw.push(ln);
               var kv:Object = this.hzc37KV(ln);
               if(kv == null) { continue; }
               if(cur.kv["k_" + kv.k] == undefined) { cur.order.push(kv.k); }
               cur.kv["k_" + kv.k] = [kv.o,kv.v];
            }
            pass++;
         }
         return d;
      }
      private function hzc37SecOf(d:Object, kl:String) : String
      {
         for each(var s:Object in d.secs) { if(s.n != "" && s.kv["k_" + kl] != undefined) { return String(s.n); } }
         return "";
      }
      private function hzc37Flush(out:Array, sec:String, U:Object, ext:Object, flushed:Object) : void
      {
         if(sec == "" || flushed["s_" + sec] == true) { return; }
         flushed["s_" + sec] = true;
         var e:Array = ext["s_" + sec];
         if(e == null || e.length == 0) { return; }
         var blanks:int = 0;
         while(out.length > 0 && this.hzc37Blank(String(out[out.length - 1]))) { out.pop(); blanks++; }
         for each(var k:String in e)
         {
            var p:Array = U["s_" + sec]["k_" + k];
            out.push(String(p[0]) + "=" + String(p[1]));
         }
         while(blanks > 0) { out.push(""); blanks--; }
      }
      // base with the player's values laid over it: known keys replace the base value in place, unknown keys of a known
      // section are appended to it, sections the base lacks are appended verbatim. CRLF out.
      private function hzc37Overlay(base:String, over:String) : String
      {
         var B:Object = this.hzc37Parse(base);
         var O:Object = this.hzc37Parse(over);
         var U:Object = {};
         var ext:Object = {};
         var unk:Array = [];
         for each(var s:Object in O.secs)
         {
            if(s.n != "" && B.idx["s_" + s.n] == undefined) { unk.push(s); continue; }
            for each(var kl:String in s.order)
            {
               var sec:String = s.n == "" ? this.hzc37SecOf(B,kl) : String(s.n);
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
         for each(var ln:String in this.hzc37Lines(base))
         {
            var h:String = this.hzc37Hdr(ln);
            if(h != null) { this.hzc37Flush(out,cur,U,ext,flushed); cur = this.hzc37Alias(h); out.push(ln); continue; }
            if(cur != "")
            {
               var kv:Object = this.hzc37KV(ln);
               if(kv != null && U["s_" + cur] != undefined && U["s_" + cur]["k_" + kv.k] != undefined)
               {
                  out.push(kv.o + "=" + String(U["s_" + cur]["k_" + kv.k][1]));
                  continue;
               }
            }
            out.push(ln);
         }
         this.hzc37Flush(out,cur,U,ext,flushed);
         for each(var us:Object in unk)
         {
            if(out.length > 0 && !this.hzc37Blank(String(out[out.length - 1]))) { out.push(""); }
            var r:Array = (us.raw as Array).concat();
            while(r.length > 0 && this.hzc37Blank(String(r[r.length - 1]))) { r.pop(); }
            for each(var rl:String in r) { out.push(rl); }
         }
         return out.length == 0 ? "" : out.join("\r\n") + "\r\n";
      }
      // def / user / state / legacy texts (null = file missing) -> the effective settings text, or null
      private function hzc37Compose(def:String, user:String, state:String, leg:String) : String
      {
         var hd:Boolean = def != null && def.length > 0;
         var hl:Boolean = leg != null && leg.length > 0;
         var base:String = hd ? def : (hl ? leg : null);
         var over:String = user != null ? user : (state == null && hd && hl ? leg : null);   // an old DLL still saves HorizonUI.ini
         if(base == null) { return over == null ? null : this.hzc37Overlay(over,""); }
         return this.hzc37Overlay(base,over != null ? over : "");
      }
      // read all four files, then cb(mergedText or null). Requests during a read get one fresh read afterwards.
      private function hzc37IniRead(cb:Function) : void
      {
         var now:Number = new Date().getTime();
         if(this.hzc37Step != 0 && now - this.hzc37T0 < 3000)
         {
            if(this.hzc37N.indexOf(cb) < 0) { this.hzc37N.push(cb); }
            return;
         }
         if(this.hzc37Step != 0 && this.hzc37Ldr != null) { try { this.hzc37Ldr.close(); } catch(e0:Error) { } }   // stuck: start over
         var q:Array = this.hzc37Step != 0 ? this.hzc37Q.concat(this.hzc37N) : [];
         this.hzc37N = [];
         if(q.indexOf(cb) < 0) { q.push(cb); }
         this.hzc37Q = q;
         this.hzc37Begin();
      }
      private function hzc37Begin() : void
      {
         this.hzc37Got = [null,null,null,null];
         this.hzc37T0 = new Date().getTime();
         this.hzc37Next(0);
      }
      private function hzc37Next(i:int) : void
      {
         this.hzc37Step = i + 1;
         if(i >= hzc37_FILES.length) { this.hzc37Ldr = null; this.hzc37Done(); return; }
         try
         {
            this.hzc37Ldr = new URLLoader();
            this.hzc37Ldr.addEventListener(Event.COMPLETE,this.hzc37OnOk);
            this.hzc37Ldr.addEventListener(IOErrorEvent.IO_ERROR,this.hzc37OnErr);
            this.hzc37Ldr.addEventListener("securityError",this.hzc37OnErr);
            this.hzc37Ldr.load(new URLRequest(String(hzc37_FILES[i])));
         }
         catch(err:Error) { this.hzc37Next(i + 1); }
      }
      private function hzc37OnOk(e:Event) : void
      {
         if(e == null || e.target != this.hzc37Ldr) { return; }
         var i:int = this.hzc37Step - 1;
         try { this.hzc37Got[i] = String(this.hzc37Ldr.data); } catch(err:Error) { }
         this.hzc37Next(i + 1);
      }
      private function hzc37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hzc37Ldr) { return; }
         this.hzc37Next(this.hzc37Step);   // missing file: normal, no error
      }
      private function hzc37Done() : void
      {
         this.hzc37Step = 0;
         var g:Array = this.hzc37Got;
         var txt:String = null;
         try { txt = this.hzc37Compose(g[0],g[1],g[2],g[3]); } catch(errC:Error) { txt = null; }
         var cbs:Array = this.hzc37Q;
         this.hzc37Q = [];
         for each(var cb:Function in cbs) { try { cb(txt); } catch(errCb:Error) { } }
         if(this.hzc37N.length > 0 && this.hzc37Step == 0) { this.hzc37Q = this.hzc37N; this.hzc37N = []; this.hzc37Begin(); }
      }
      // =================== end shared settings reader ===================

      // =================== end Horizon UI Comms (HUD Messages) v0.35 ===================
   }
}

