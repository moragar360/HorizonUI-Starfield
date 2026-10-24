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
      // disliked / hated, and the present tense loves / likes / dislikes / hates) is drawn as a Horizon card in the same
      // spot: a pill with a chevron tile (2 up loved, 1 up liked, 1 down disliked, 2 down hated), the name in the speaker color, the reaction in its
      // color (teal / green / amber / red). The game's line (HUDMessageItem.Internal_mc) stays in the list. Its alpha
      // is set to 0 only after a Horizon card for that line has been drawn. It is never removed.
      // v0.42.0.9: the DLL classifies the line (kind, subtype, name, value, raw text). This movie does not parse it.
      // Medical, crew, unavailable, and Kid Stuff use the same card slot. XP, skills, quests, and help tips are not touched.
      // v0.42.0.10: crime and generic credit cards use the same slot. Every Horizon card is a child of hzcRxLayer,
      // which F11 ARRANGE CARDS names HUD Messages. The vanilla fade is still it.alpha * Internal_mc.alpha * Messages_mc.alpha.
      // v0.42.0.7: HUDMessageData is the primary path. A value replayed during Subscribe is ignored, and the skip
      // flag is cleared when Subscribe returns so the first real message is kept. The DLL calls hzcCardPush. hzcRxPush remains.
      // The two paths pair in order, so the same text from both paths is one card and N reactions are N cards.
      // A DLL note that arrives after its linked line has left still pairs inside the 3 s window and does not open another card.
      // A card that links to a vanilla line stays up until that line leaves the list. A card that never links
      // lasts 4 s of time while Messages_mc is visible, so a line held through a conversation is still carded.
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
      private static const HZC_LRG:Boolean = false;
      private static const HZC_ACC:Array = [0x3FD0E0,0x4FD1B8,0xF2B45F,0xB59CF2,0xA8E86F,0xE8F2F5,0xF2839F,0xF28A4F,0x6FB0F2,0xE8C547,0x9FF2D0,0x3E6478,0x1E4A8C];
      private static const HZC_STR:Object = {"SpeakerHex":1,"SubTextHex":1,"AccentHex":1,"SubtitleX":1,"SubtitleY":1,"SpeakerX":1,"SpeakerY":1,"MissionToastX":1,"MissionToastY":1,"HudMessagesX":1,"HudMessagesY":1};
      private static const HZC_SEMI:String = "$NB_Grotesk_Semibold";   // the game's own semibold face (run-time name only)
      private static const HZC_EDGE:Number = 0.10;          // card edge: white @ .10, 1 px stroke
      private static const HZC_TXT:uint = 0xE8F0F5;         // default subtitle text (off-white)
      private static const HZC_GRN:uint = 0x5EE3A1;
      private static const HZC_RED:uint = 0xFF5B5B;
      private static const HZC_TST_HEAD:Array = ["MISSION UPDATED","NEW MISSION","OBJECTIVE COMPLETE","MISSION COMPLETE","MISSION FAILED"];
      private static const HZC_TST_PRIO:Array = [1,3,2,4,5];   // merging two updates of one quest keeps the stronger state
      private var hzcCfg:Object = {"ReactionCard":1,"Subtitles":1,"SubAutoPause":1,"SubSize":1,"SubWidth":50,"SubBgOpacity":0.7,"SubPosition":0,"SubOffsetY":0,"SubAlign":0,"ShowSpeaker":1,"SpeakerColor":-1,"SpeakerHex":"","SpeakerCard":1,"KeepInDialogue":1,"FixedInDialogue":1,"SubMaxLines":3,"SubFont":-1,"Dialogue":1,"DlgAutoPause":1,"HideQuestPopupsWhileScanning":1,"DimTraitPopupDuringBioscan":0,"TraitPopupDim":0.4,"XpToast":0,"FontFace":1,"AccentColor":0,"AccentHex":"","TextScale":1,"ScreenHeight":0,"Margin":40,"SubtitleX":"-1","SubtitleY":"-1","SpeakerX":"-1","SpeakerY":"-1","SubTextColor":-1,"SubTextHex":"","SubCard":1,"SubOffsetX":0,"MissionToast":1,"MissionToastTime":5,"MissionToastMax":3,"MissionToastSound":1,"MissionToastScale":-1,"HudScale":1,"MissionToastX":"-1","MissionToastY":"-1","HudMessagesX":"-1","HudMessagesY":"-1","HzRev":0};
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
            var ln:String = this.hzcTrim(raw);
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
      // Leading and trailing space, tab, line breaks, NBSP, and BOM. No RegExp: Scaleform's PCRE rejects \u.
      private function hzcTrimC(c:int) : Boolean
      {
         return c == 9 || c == 10 || c == 11 || c == 12 || c == 13 || c == 32 || c == 0xA0 || c == 0xFEFF;
      }
      private function hzcTrim(s:String) : String
      {
         if(s == null) { return ""; }
         var a:int = 0;
         var b:int = s.length;
         while(a < b && this.hzcTrimC(s.charCodeAt(a))) { a++; }
         while(b > a && this.hzcTrimC(s.charCodeAt(b - 1))) { b--; }
         return a == 0 && b == s.length ? s : s.substring(a,b);
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
         try { this.hzcMsgLayout(); } catch(eMsg:Error) { }
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
         // marker still loading or absent: game font, so a missing $Horizon_ face is not looked up
         if(this.hzcProbe.font !== 1) { return this.hzcGameFont; }
         var base:String = f == 2 ? "$Horizon_Font_Alt" : (f == 1 ? "$Horizon_Font" : null);
         if(base == null || !this.hzcFontProbe(base)) { return this.hzcGameFont; }
         var want:String = role == "rg" ? base + "_Regular" : base;
         if(want != base && this.hzcFontProbe(want)) { return want; }
         return base;
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
      // HUD Messages box: default is the current column (layer at 0,0). A saved [Layout]
      // HudMessagesX/Y is an offset from that same default spot, so the fade coupling stays.
      private function hzcMsgHome(vr:Rectangle, w:Number, h:Number) : Point
      {
         var x:Number = 40;
         var y:Number = 80;
         var r:Rectangle = null;
         try { if(this.Messages_mc != null) { r = this.Messages_mc.getBounds(this); } } catch(e0:Error) { r = null; }
         if(r != null && !isNaN(r.x) && !isNaN(r.y) && !isNaN(r.width) && r.width > 2)
         {
            x = r.x + r.width - w;
            y = r.y;
         }
         else if(vr != null && !isNaN(vr.right))
         {
            x = vr.right - w - 40;
            y = vr.y + 80;
         }
         return new Point(x,y);
      }
      private function hzcMsgLayout() : void
      {
         if(this.hzcRxLayer == null || this.hzcCfg == null) { return; }
         var xs:String = String(this.hzcCfg.HudMessagesX);
         var ys:String = String(this.hzcCfg.HudMessagesY);
         if((xs == "-1" || xs == "undefined" || xs == "null") && (ys == "-1" || ys == "undefined" || ys == "null"))
         {
            this.hzcRxLayer.x = 0;
            this.hzcRxLayer.y = 0;
            return;
         }
         var vr:Rectangle = null;
         try { vr = this.hzcVis(); } catch(e1:Error) { vr = null; }
         if(vr == null) { this.hzcRxLayer.x = 0; this.hzcRxLayer.y = 0; return; }
         var z:Number = this.hzcCardZ();
         var w:Number = Math.round(360 * z);
         if(w < 280) { w = 280; }
         var h:Number = Math.round(56 * z);
         var home:Point = this.hzcMsgHome(vr,w,h);
         var x:Number = (xs == "-1" || xs == "undefined" || xs == "null") ? home.x : this.hzcAnchor(xs,"x",w,vr.x,vr.right);
         var y:Number = (ys == "-1" || ys == "undefined" || ys == "null") ? home.y : this.hzcAnchor(ys,"y",h,vr.y,vr.bottom);
         if(isNaN(x) || isNaN(y) || isNaN(home.x) || isNaN(home.y)) { this.hzcRxLayer.x = 0; this.hzcRxLayer.y = 0; return; }
         this.hzcRxLayer.x = Math.round(x - home.x);
         this.hzcRxLayer.y = Math.round(y - home.y);
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
      // Category order is the past-tense form. loves/likes/dislikes/hates use the same slot, label, color, and chevrons.
      private static const HZC_RX_VERB:Array = ["loved","liked","disliked","hated"];
      private static const HZC_RX_LBL:Array = ["LOVED THAT","LIKED THAT","DISLIKED THAT","HATED THAT"];
      private static const HZC_RX_COL:Array = [0x4FD1B8,0x5EE3A1,0xF2A93B,0xFF5B5B];   // liked = the scanner's companion green (noted)
      private static const HZC_RX_DIR:Array = [2,1,-1,-2];
      // First word only (and the two-word "no one"). A later word such as a real name is allowed.
      private static const HZC_RX_NOT:Array = ["i","you","we","they","he","she","it","your","my","our","their","his","her","nobody","everyone","everybody","someone","somebody","none","all","some","the","a","an","crew","no one","who","not","people","this","that","many","most","each","several","both","what"];
      // A trailing period is a title or an initial, not a sentence. "Dr." and "J." match. "Okay." does not.
      private static const HZC_RX_TITLE:Array = ["dr","mr","mrs","ms","jr","sr","st","lt","capt","sgt","prof"];
      private static const HZC_RX_LABEL:uint = 0xC4D2D9;
      private static const HZC_RX_PAIR:int = 3000;  // a binding note and a DLL note of the same text pair inside this window
      private static const HZC_RX_VIS:int = 4000;    // unlinked cards only: shown time while the message slot is visible
      private static const HZC_RX_COOL:int = 5000;   // after three message misses, try the card again once this has passed
      private static const HZC_RX_STEP:int = 3;     // consecutive frames whose step threw, then the card turns off
      private var hzcRx:Array = [];          // {it, st, n, k, c, w, h, sig, key, t0, vis, tx, linked, src, paired, blamed}
      private var hzcRxGone:Array = [];      // {key, t0} linked binding cards that ended before their DLL note arrived
      private var hzcRxWait:Array = [];      // {it, f} text not ready yet
      private var hzcRxLayer:Sprite = null;
      private var hzcRxOff:Boolean = false;  // after three message misses: lines stay the game's until the cooldown or a settings reload
      private var hzcRxOffAt:int = 0;
      private var hzcRxSkip:Boolean = true;  // true only while Subscribe may replay the cached value
      private var hzcRxSub:Boolean = false;
      private var hzcRxLast:int = 0;
      private var hzcRxFail:int = 0;         // misses in a row, one per message. A later success clears it.
      private var hzcRxStepN:int = 0;        // consecutive top-level step throws. Three turn the card off.
      private var hzcRxWhyLast:String = "";
      private var hzcRxSelf:String = "";   // one-time matcher self-test: "pass" or "fail"
      private var hzcAlerts:Array = [];    // 0.42.0.9: latest PersonalAlertsData rows, for a medical subtitle
      private static const HZC_CARD_AMB:uint = 0xF2A93B;
      private static const HZC_CARD_BG:uint = 0x0B0F14;
      private function hzcRxInit() : void
      {
         if(this.hzcRxLayer == null)
         {
            this.hzcRxLayer = new Sprite();
            this.hzcRxLayer.mouseEnabled = false;
            this.hzcRxLayer.mouseChildren = false;
            addChild(this.hzcRxLayer);
            addEventListener(Event.ADDED,this.hzcRxAdded);
            addEventListener(Event.ENTER_FRAME,this.hzcRxFrame);
         }
         if(this.hzcRxSub) { return; }
         this.hzcRxSub = true;
         this.hzcRxSkip = true;
         try { BSUIDataManager.Subscribe("HUDMessageData",this.hzcRxOnMsg); }
         catch(eSub:Error) { this.hzcRxSub = false; }
         this.hzcRxSkip = false;
         try { BSUIDataManager.Subscribe("PersonalAlertsData",this.hzcOnAlerts); } catch(eAl:Error) { }
         try { this.hzcRxSelfTest(); } catch(eSelf:Error) { this.hzcRxSelf = "fail"; }
      }
      private function hzcRxOn() : Boolean
      {
         return !this.hzcRxOff && this.hzcIniState != 0 && int(this.hzcCfg.ReactionCard) == 1 && this.Messages_mc != null;
      }
      // Present tense uses the same category as the past tense: card label, color, and chevrons.
      private function hzcRxVerb(v:String) : int
      {
         var s:String = v == null ? "" : v.toLowerCase();
         if(s == "loved" || s == "loves") { return 0; }
         if(s == "liked" || s == "likes") { return 1; }
         if(s == "disliked" || s == "dislikes") { return 2; }
         if(s == "hated" || s == "hates") { return 3; }
         return -1;
      }
      // Letters of a name word, for the pronoun, "and", "that", and verb checks. A title's period is not part of the word.
      private function hzcRxLead(w:String) : String
      {
         var s:String = w == null ? "" : w.toLowerCase();
         while(s.length > 0 && s.charAt(s.length - 1) == ".") { s = s.substr(0,s.length - 1); }
         return s;
      }
      // A-Z, a-z, or Latin-1 / Latin Extended (U+00C0 through U+024F). charCodeAt, not a regex:
      // Scaleform compiles AS3 RegExp with PCRE, and the pattern text keeps a literal \u (FFDec does not expand it).
      private function hzcRxLetter(c:int) : Boolean
      {
         return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 0xC0 && c <= 0x24F);
      }
      // Apostrophe, right single quotation mark, or hyphen.
      private function hzcRxMark(c:int) : Boolean
      {
         return c == 0x27 || c == 0x2019 || c == 0x2D;
      }
      // An initial is one letter and a period, or those pairs stuck together: "J." and "J.T.". "Okay." is neither.
      private function hzcRxInitial(w:String) : Boolean
      {
         if(w == null) { return false; }
         var n:int = w.length;
         if(n < 2 || (n & 1) != 0) { return false; }
         var i:int = 0;
         while(i < n)
         {
            if(!this.hzcRxLetter(w.charCodeAt(i)) || w.charCodeAt(i + 1) != 46) { return false; }
            i += 2;
         }
         return true;
      }
      // Letters, apostrophes, and hyphens. A trailing period is a title (Dr., Lt., Capt.) or an initial.
      // Any other period is a sentence break, so "Okay. Sam liked that." does not swallow the first sentence.
      private function hzcRxWordOk(w:String) : Boolean
      {
         if(w == null || w.length == 0) { return false; }
         if(this.hzcRxInitial(w)) { return true; }
         var body:String = w;
         var p:int = 0;
         if(w.charCodeAt(w.length - 1) == 46)
         {
            body = w.substr(0,w.length - 1);
            if(HZC_RX_TITLE.indexOf(body.toLowerCase()) < 0) { return false; }
         }
         else
         {
            while(p < w.length) { if(w.charCodeAt(p) == 46) { return false; } p++; }
         }
         if(body == null || body.length == 0 || !this.hzcRxLetter(body.charCodeAt(0))) { return false; }
         var i:int = 1;
         var prevMark:Boolean = false;
         while(i < body.length)
         {
            var c:int = body.charCodeAt(i);
            if(this.hzcRxMark(c))
            {
               if(prevMark) { return false; }
               prevMark = true;
            }
            else if(this.hzcRxLetter(c)) { prevMark = false; }
            else { return false; }
            i++;
         }
         return !prevMark;
      }
      // Whole line, English only. The game line may be any case ("Sam likes that" or "SAM COE LIKED THAT").
      // The name is 1 to 4 words. No capital is required. The first word cannot be a pronoun or a quantifier.
      // An initial ("A.", "I.") is a name word, not the article or the pronoun. "and", "that", and a reaction verb cannot be a name word.
      // "Dr. Barrett" is a name. A name that is only a title ("Mr.") is not.
      // The verb is the word immediately before a final "that" or "that.". The period is optional. Trailing space is ignored.
      // Case is folded with toLowerCase. The regex i flag only folds A-Z, and this path does not use a regex.
      // Returns {n, k} or null. k is the past-tense category. n keeps the matched letters; the card uppercases it.
      private function hzcRxTail(s:String, tail:String) : Boolean
      {
         if(s == null || tail == null || s.length < tail.length) { return false; }
         return s.substring(s.length - tail.length).toLowerCase() == tail;
      }
      private function hzcRxMatch(t:String) : Object
      {
         var s:String = this.hzcRxNorm(t);
         if(s == null || s.indexOf("\n") >= 0 || s.indexOf("\r") >= 0) { return null; }
         if(s.length < 11 || s.length > 64) { return null; }
         var cut:int = 0;
         if(this.hzcRxTail(s," that.")) { cut = 6; }
         else if(this.hzcRxTail(s," that")) { cut = 5; }
         else { return null; }
         var head:String = s.substring(0,s.length - cut);
         var sp:int = -1;
         var j:int = head.length - 1;
         while(j >= 0) { if(head.charCodeAt(j) == 32) { sp = j; break; } j--; }
         if(sp <= 0) { return null; }
         var verb:String = head.substring(sp + 1);
         var n:String = head.substring(0,sp);
         var k:int = this.hzcRxVerb(verb);
         if(k < 0 || n.length < 1 || n.length > 40) { return null; }
         var ws:Array = n.split(" ");
         if(ws.length < 1 || ws.length > 4) { return null; }
         var i:int = 0;
         var named:Boolean = false;
         for each(var w:String in ws)
         {
            if(!this.hzcRxWordOk(w)) { return null; }
            var key:String = this.hzcRxLead(w);
            var initial:Boolean = this.hzcRxInitial(w);
            if(key == "and" || key == "that" || this.hzcRxVerb(key) >= 0) { return null; }
            // "A." and "I." are initials. "A" and "I" without the period stay in the leading-word list.
            if(!initial && i == 0 && HZC_RX_NOT.indexOf(key) >= 0) { return null; }
            if(!initial && i == 1 && HZC_RX_NOT.indexOf(this.hzcRxLead(String(ws[0])) + " " + key) >= 0) { return null; }
            if(HZC_RX_TITLE.indexOf(key) < 0) { named = true; }
            i++;
         }
         if(!named) { return null; }
         return {"n":n,"k":k};
      }
      // Tab and the no-break spaces become a normal space. Zero-width space and BOM are dropped.
      // Ends are trimmed. Runs of spaces become one. A line break in the middle is left so the match can reject it.
      private function hzcRxNorm(t:String) : String
      {
         if(t == null) { return null; }
         var raw:String = "";
         var i:int = 0;
         while(i < t.length)
         {
            var c:int = t.charCodeAt(i);
            if(c == 0x200B || c == 0xFEFF) { i++; continue; }
            if(c == 9 || c == 0xA0 || c == 0x2007 || c == 0x202F || c == 0x2009 || c == 0x200A) { raw += " "; }
            else { raw += t.charAt(i); }
            i++;
         }
         var a:int = 0;
         var b:int = raw.length;
         while(a < b && this.hzcRxTrimC(raw.charCodeAt(a))) { a++; }
         while(b > a && this.hzcRxTrimC(raw.charCodeAt(b - 1))) { b--; }
         var o:String = "";
         var spc:Boolean = false;
         i = a;
         while(i < b)
         {
            if(raw.charCodeAt(i) == 32)
            {
               if(!spc) { o += " "; spc = true; }
            }
            else { o += raw.charAt(i); spc = false; }
            i++;
         }
         return o;
      }
      private function hzcRxTrimC(c:int) : Boolean
      {
         return c == 9 || c == 10 || c == 11 || c == 12 || c == 13 || c == 32;
      }
      // One startup line for HorizonUI.log. Pass means "Sam Coe liked that." is Sam Coe, liked.
      // The three probes stay even though the matcher does not use them: they show whether this GFx build accepts \u.
      public function hzcRxSelfTest() : String
      {
         if(this.hzcRxSelf != null && this.hzcRxSelf.length > 0) { return this.hzcRxSelf; }
         var r:Object = null;
         try { r = this.hzcRxMatch("Sam Coe liked that."); } catch(eM:Error) { r = null; }
         var ok:Boolean = r != null && String(r.n) == "Sam Coe" && int(r.k) == 1;
         var uLit:String = "throw";
         var uNew:String = "throw";
         var xLit:String = "throw";
         try { uLit = /\u0041/.test("A") ? "true" : "false"; } catch(eU:Error) { uLit = "throw"; }
         try { uNew = new RegExp("\\u0041").test("A") ? "true" : "false"; } catch(eN:Error) { uNew = "throw"; }
         try { xLit = /\x41/.test("A") ? "true" : "false"; } catch(eX:Error) { xLit = "throw"; }
         this.hzcRxSelf = (ok ? "pass" : "fail") + "\n/\\u0041/.test('A')=" + uLit + "\nnew RegExp('\\\\u0041').test('A')=" + uNew + "\n/\\x41/.test('A')=" + xLit;
         return this.hzcRxSelf;
      }
      // ---------- 0.42.0.6: message log. HZC_MSG_LOG is the switch (true on this test build). ----------
      // Leave this true until the release checklist in README.md. The DLL writes whatever this queue
      // returns. Debug=0 in the ini still stops the queue. A missing Debug key leaves it on.
      private static const HZC_MSG_LOG:Boolean = true;
      private static const HZC_BUILD:String = "0.42.0.10";
      private var hzcRxDbgOn:Boolean = true;   // 0.42.0.6: on with HZC_MSG_LOG. The release checklist sets this default to false. hzcRxDbgIni turns it off when Debug=0.
      private var hzcRxDbgQ:Array = [];
      private var hzcRxDbgSeen:Array = [];   // {it, f}
      private var hzcRxDbgHdr:Boolean = false;
      private var hzcRxErr:String = "";
      private var hzcRxErrSent:Boolean = false;
      private function hzcRxDbgIni(txt:String) : void
      {
         if(!HZC_MSG_LOG) { this.hzcRxDbgOn = false; this.hzcRxDbgQ = []; this.hzcRxDbgSeen = []; return; }
         var on:Boolean = true;
         var sec:String = "";
         if(txt != null)
         {
            for each(var raw:String in txt.split("\r").join("").split("\n"))
            {
               var ln:String = this.hzcTrim(raw);
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
      // One line when the card code turns itself off. The DLL writes it as "comms msg: card code off after error: ...".
      private function hzcRxDbgErr() : void
      {
         if(this.hzcRxErrSent || !this.hzcRxOff || !HZC_MSG_LOG || !this.hzcRxDbgOn) { return; }
         this.hzcRxErrSent = true;
         var em:String = this.hzcRxErr != null ? this.hzcRxErr : "";
         this.hzcRxDbgPush("card code off after error: " + this.hzcRxDbgEsc(em));
      }
      // every new line once (waits up to 3 frames for its text)
      private function hzcRxDbgScan(arr:*) : void
      {
         if(!HZC_MSG_LOG || !this.hzcRxDbgOn || arr == null) { return; }
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
            var tag:String = "none (stays the game's line)";
            var card:Object = this.hzcRxFind(it);
            if(card == null) { card = this.hzcRxOpen(tx); }
            if(card != null) { tag = String(card.kind != null && String(card.kind).length > 0 ? card.kind : "reaction") + "/" + String(card.sub != null ? card.sub : HZC_RX_VERB[int(card.k)]); }
            var tfp:String = "";
            try { tfp = this.hzcRxDbgPath(it.Internal_mc.Text_tf); } catch(e2:Error) { tfp = this.hzcRxDbgPath(it); }
            this.hzcRxDbgPush("line \"" + this.hzcRxDbgEsc(tx) + "\" len " + tx.length + " | " + tfp + " | match " + tag + " | ReactionCard " + this.hzcCfg.ReactionCard + (this.hzcRxOn() ? "" : " (cards off)"));
         }
      }
      public function hzcTakeDbg() : String
      {
         try
         {
            if(!HZC_MSG_LOG || !this.hzcRxDbgOn || this.hzcRxDbgQ.length == 0) { return ""; }
            var o:String = this.hzcRxDbgQ.join("\n");
            this.hzcRxDbgQ = [];
            return o;
         }
         catch(e:Error) { }
         return "";
      }
      public function hzcBuildId() : String
      {
         return HZC_BUILD;
      }
      private function hzcRxFind(it:*) : Object
      {
         for each(var e:Object in this.hzcRx) { if(e != null && e.it === it) { return e; } }
         return null;
      }
      private function hzcRxOne(s:String) : String
      {
         if(s == null) { return ""; }
         var t:String = String(s).replace(/[\r\n]+/g," ");
         if(t.length > 160) { t = t.substr(0,160); }
         return t;
      }
      // Why the card is not running. Independent of Debug. hzcRxPush and hzcRxWhy both use this.
      private function hzcRxWhyText() : String
      {
         if(this.hzcRxOff) { return "off after error: " + this.hzcRxOne(this.hzcRxErr); }
         if(this.hzcIniState == 0) { return "cards off: settings not loaded"; }
         if(this.hzcCfg == null || int(this.hzcCfg.ReactionCard) != 1) { return "cards off: ReactionCard is off"; }
         if(this.Messages_mc == null) { return "cards off: message column missing"; }
         return "cards off: cards are off";
      }
      private function hzcRxKey(t:String) : String
      {
         var s:String = this.hzcRxNorm(t);
         if(s == null || s.length == 0) { return null; }
         return s.toLowerCase();
      }
      // Oldest card for this text that does not have a vanilla line yet.
      private function hzcRxOpen(tx:String) : Object
      {
         var key:String = this.hzcRxKey(tx);
         if(key == null) { return null; }
         for each(var e:Object in this.hzcRx) { if(e != null && e.key == key && e.it == null) { return e; } }
         return null;
      }
      // Settings reload, a ReactionCard toggle, or the miss cooldown. The next message draws again.
      private function hzcRxRearm() : void
      {
         this.hzcRxOff = false;
         this.hzcRxOffAt = 0;
         this.hzcRxFail = 0;
         this.hzcRxStepN = 0;
         this.hzcRxErr = "";
         this.hzcRxErrSent = false;
         this.hzcRxWhyLast = "";
      }
      // Match the unchanged text. The first HUDMessageData event is the value replayed on subscribe.
      private function hzcRxOnMsg(ev:FromClientDataEvent) : void
      {
         try
         {
            if(this.hzcRxSkip) { this.hzcRxSkip = false; return; }
            if(ev == null || ev.data == null) { return; }
            var d:Object = ev.data;
            var clear:Boolean = false;
            try { clear = d.bClearMessages == true; } catch(eC:Error) { clear = false; }
            if(clear) { return; }
            var msg:Object = null;
            try { msg = d.NextMessage; } catch(eN:Error) { msg = null; }
            if(msg == null) { return; }
            var tx:* = null;
            try { tx = msg.sText; } catch(eT:Error) { tx = null; }
            if(tx == null) { return; }
            var raw:String = String(tx);
            if(raw.length == 0) { return; }
            // 0.42.0.9: the binding does not classify and does not hide. hzcCardPush owns the card.
         }
         catch(err:Error) { }
      }
      // queued / no match / cards off: reason / off after error: message.
      // fromDll pairs with the oldest unpaired binding note of the same text, and the other way around.
      private function hzcRxOffer(raw:String, fromDll:Boolean = false) : String
      {
         if(raw == null) { raw = ""; }
         if(this.hzcRxOff || !this.hzcRxOn()) { return this.hzcRxWhyText(); }
         if(String(raw).length == 0) { return "no match"; }
         var r:Object = null;
         try { r = this.hzcRxMatch(String(raw)); } catch(eM:Error) { r = null; }
         if(r == null) { return "no match"; }
         var key:String = this.hzcRxKey(String(raw));
         if(key == null) { return "no match"; }
         var now:int = getTimer();
         var want:String = fromDll ? "b" : "d";
         for each(var e0:Object in this.hzcRx)
         {
            if(e0 == null || e0.key != key || e0.paired == true || e0.src != want) { continue; }
            var age:int = now - int(e0.t0);
            if(age >= 0 && age < HZC_RX_PAIR) { e0.paired = true; e0.src = "both"; return "queued"; }
         }
         if(fromDll && this.hzcRxPairGone(key, now)) { return "queued"; }
         var src:String = fromDll ? "d" : "b";
         this.hzcRx.push({"it":null,"st":1,"n":r.n,"k":r.k,"c":null,"w":0,"h":0,"sig":"","key":key,"t0":now,"vis":0,"tx":String(raw),"linked":false,"src":src,"paired":false,"blamed":false,"covered":false});
         if(this.hzcRx.length > 8)
         {
            var old:Object = this.hzcRx.shift();
            this.hzcRxShow(old);
            this.hzcRxDrop(old);
         }
         return "queued";
      }
      // The line already left. A DLL note of that same text, still inside the pair window, is the backup for it.
      private function hzcRxRemember(e:Object) : void
      {
         if(e == null || e.linked != true || e.paired == true || e.src != "b" || e.key == null) { return; }
         this.hzcRxGone.push({"key":e.key,"t0":int(e.t0)});
         if(this.hzcRxGone.length > 8) { this.hzcRxGone.shift(); }
      }
      private function hzcRxPairGone(key:String, now:int) : Boolean
      {
         var keepG:Array = [];
         var ate:Boolean = false;
         for each(var g0:Object in this.hzcRxGone)
         {
            if(g0 == null) { continue; }
            var gage:int = now - int(g0.t0);
            if(gage < 0 || gage >= HZC_RX_PAIR) { continue; }
            if(!ate && g0.key == key) { ate = true; continue; }
            keepG.push(g0);
         }
         this.hzcRxGone = keepG;
         return ate;
      }
      // DLL backup. The sink thread never calls this. Poll does, and only while HUDMessagesMenu is open.
      public function hzcRxPush(text:String) : String
      {
         try { return this.hzcRxOffer(text == null ? "" : String(text),true); }
         catch(err:Error)
         {
            var em:String = "";
            try { em = err != null && err.message != null ? String(err.message) : ""; } catch(e2:Error) { em = ""; }
            this.hzcRxErr = this.hzcRxOne(em);
            return "off after error: " + this.hzcRxErr;
         }
      }
      private function hzcRxSubK(s:String) : int
      {
         if(s == "loved") { return 0; }
         if(s == "liked") { return 1; }
         if(s == "disliked") { return 2; }
         if(s == "hated") { return 3; }
         return -1;
      }
      // DLL classification. The movie lays the card out. It does not parse the sentence.
      public function hzcCardPush(kind:String, sub:String, name:String, value:String, raw:String) : String
      {
         try
         {
            if(kind == null) { kind = ""; }
            if(sub == null) { sub = ""; }
            if(name == null) { name = ""; }
            if(value == null) { value = ""; }
            if(raw == null) { raw = ""; }
            if(this.hzcRxOff || !this.hzcRxOn()) { return this.hzcRxWhyText(); }
            if(String(kind).length == 0) { return "no match"; }
            var key:String = this.hzcRxKey(String(raw));
            if(key == null) { return "no match"; }
            var now:int = getTimer();
            var k:int = -1;
            if(String(kind) == "reaction")
            {
               k = this.hzcRxSubK(String(sub));
               if(k < 0) { return "no match"; }
            }
            this.hzcRx.push({"it":null,"st":1,"n":String(name),"k":k,"c":null,"w":0,"h":0,"sig":"","key":key,"t0":now,"vis":0,"tx":String(raw),"linked":false,"src":"d","paired":false,"blamed":false,"kind":String(kind),"sub":String(sub),"value":String(value),"covered":false});
            if(this.hzcRx.length > 8)
            {
               var old:Object = this.hzcRx.shift();
               this.hzcRxShow(old);
               this.hzcRxDrop(old);
            }
            return "queued";
         }
         catch(err:Error)
         {
            var em2:String = "";
            try { em2 = err != null && err.message != null ? String(err.message) : ""; } catch(e2:Error) { em2 = ""; }
            this.hzcRxErr = this.hzcRxOne(em2);
            return "off after error: " + this.hzcRxErr;
         }
      }
      // Empty while cards are on, while settings are still loading, or when this reason was already returned.
      public function hzcRxWhy() : String
      {
         try
         {
            if(this.hzcIniState == 0 && !this.hzcRxOff) { return ""; }
            if(this.hzcRxOn()) { this.hzcRxWhyLast = ""; return ""; }
            var why:String = this.hzcRxWhyText();
            if(why == this.hzcRxWhyLast) { return ""; }
            this.hzcRxWhyLast = why;
            return why;
         }
         catch(err:Error) { return ""; }
      }
      private function hzcRxItemTx(it:*) : String
      {
         if(it == null) { return ""; }
         try
         {
            var im:* = it.Internal_mc;
            if(im == null || im.Text_tf == null) { return ""; }
            var tx:* = im.Text_tf.text;
            return tx == null ? "" : String(tx);
         }
         catch(e:Error) { return ""; }
      }
      // The timeline fades Internal_mc. Never write that alpha. These two children are not tweened.
      private function hzcRxReveal(it:*) : void
      {
         try
         {
            if(it == null || it.Internal_mc == null) { return; }
            var im:* = it.Internal_mc;
            if(im.Text_tf != null) { im.Text_tf.visible = true; }
            if(im.Background_mc != null) { im.Background_mc.visible = true; }
         }
         catch(e:Error) { }
      }
      // Hide the game's text and background after the Horizon card has drawn. The clip stays in the list.
      private function hzcRxCover(e:Object, it:*) : void
      {
         try
         {
            if(e == null || it == null || it.Internal_mc == null) { return; }
            var im:* = it.Internal_mc;
            if(im.Text_tf != null) { im.Text_tf.visible = false; e.covered = true; }
            if(im.Background_mc != null) { im.Background_mc.visible = false; e.covered = true; }
         }
         catch(err:Error) { }
      }
      private function hzcRxWaits(it:*) : int
      {
         var i:int = 0;
         while(i < this.hzcRxWait.length)
         {
            var w:Object = this.hzcRxWait[i];
            if(w != null && w.it === it) { w.f = int(w.f) + 1; return int(w.f); }
            i++;
         }
         this.hzcRxWait.push({"it":it,"f":1});
         return 1;
      }
      private function hzcRxWaitClear(it:*) : void
      {
         var keep:Array = [];
         for each(var w:Object in this.hzcRxWait)
         {
            if(w == null || w.it == null || w.it === it) { continue; }
            try { if(w.it.parent == null) { continue; } } catch(e:Error) { continue; }
            keep.push(w);
         }
         this.hzcRxWait = keep;
      }
      // Attach a shown line to an open card. A line with no card is left alone, fade included.
      private function hzcRxLink(arr:*) : void
      {
         if(arr == null) { return; }
         var i:int = 0;
         while(i < arr.length)
         {
            var it:* = arr[i];
            i++;
            if(it == null || this.hzcRxFind(it) != null) { continue; }
            var tx:String = this.hzcRxItemTx(it);
            var n:int = this.hzcRxWaits(it);
            if(tx.length == 0 && n < 3) { continue; }
            this.hzcRxWaitClear(it);
            if(tx.length == 0) { continue; }
            var before:Object = this.hzcRxOpen(tx);
            if(before != null)
            {
               before.it = it;
               before.linked = true;
            }
         }
      }
      private function hzcRxSlot(m:*) : Boolean
      {
         if(m == null) { return false; }
         try { return m.visible == true; } catch(e:Error) { return false; }
      }
      private function hzcRxLatch() : void
      {
         this.hzcRxOff = true;
         this.hzcRxOffAt = getTimer();
         try { this.hzcRxAll(); } catch(eAll:Error) { }
         try { this.hzcRxUnhide(); } catch(eUn:Error) { }
         try { this.hzcRxDbgErr(); } catch(eDbg:Error) { }
      }
      // Only a line this movie covered comes back. Every other HUD line keeps the game's fade.
      private function hzcRxUnhide() : void
      {
         for each(var e:Object in this.hzcRx) { this.hzcRxShow(e); }
      }
      // One miss is recoverable: the next message draws again. The caller turns the card off after three.
      private function hzcRxHit(err:Error) : void
      {
         this.hzcRxFail++;
         try { this.hzcRxErr = err != null && err.message != null ? String(err.message) : ""; } catch(e:Error) { this.hzcRxErr = ""; }
         this.hzcRxErr = this.hzcRxOne(this.hzcRxErr);
      }
      // A new game line stays visible. The card covers its text and background only after that card has drawn.
      private function hzcRxAdded(ev:Event) : void
      {
         if(ev == null) { return; }
      }
      private function hzcRxShow(e:Object) : void
      {
         try
         {
            if(e != null && e.covered == true)
            {
               this.hzcRxReveal(e.it);
               e.covered = false;
            }
         }
         catch(err:Error) { }
         if(e != null && e.c != null) { e.c.visible = false; }
      }
      private function hzcRxDrop(e:Object) : void
      {
         if(e != null && e.c != null && this.hzcRxLayer != null && e.c.parent == this.hzcRxLayer) { this.hzcRxLayer.removeChild(e.c); }
         if(e != null) { e.c = null; }
      }
      // everything back to the game's lines (ReactionCard=0, an error)
      private function hzcRxAll() : void
      {
         for each(var e:Object in this.hzcRx) { this.hzcRxShow(e); this.hzcRxDrop(e); if(e != null) { e.st = 0; } }
         this.hzcRx = [];
         this.hzcRxGone = [];
      }
      private function hzcRxApply() : void
      {
         this.hzcRxRearm();
         if(!this.hzcRxOn()) { this.hzcRxAll(); return; }
         for each(var e:Object in this.hzcRx) { if(e != null) { e.sig = ""; } }
      }
      private function hzcRxFrame(ev:Event) : void
      {
         if(this.hzcRxOff)
         {
            // getTimer is a signed int and wraps. Unsigned subtraction keeps a real elapsed time across that wrap.
            // A backward step becomes a value above 2147483647 and stays latched until settings reload.
            var woke:uint = uint(getTimer()) - uint(this.hzcRxOffAt);
            if(woke >= uint(HZC_RX_COOL) && woke <= uint(2147483647)) { this.hzcRxRearm(); }
            else
            {
               if(this.hzcRxDbgOn) { try { this.hzcRxDbgErr(); this.hzcRxDbgScan(this.Messages_mc != null ? this.Messages_mc.ShownMessageArray : null); } catch(eDbg2:Error) { } }
               return;
            }
         }
         try { this.hzcRxStep(); this.hzcRxStepN = 0; }
         catch(err:Error)
         {
            this.hzcRxStepN++;
            if(this.hzcRxStepN == 1) { this.hzcRxHit(err); }
            if(this.hzcRxStepN >= HZC_RX_STEP) { this.hzcRxLatch(); }
         }
      }
      // Time counts only while Messages_mc is visible. A hidden slot does not age a pending card, and nothing here uses a 30 s wall clock.
      private function hzcRxStep() : void
      {
         var m:* = this.Messages_mc;
         if(m == null || this.hzcRxLayer == null) { return; }
         var arr:* = null;
         try { arr = m.ShownMessageArray; } catch(eArr:Error) { arr = null; }
         var now:int = getTimer();
         var dt:int = 0;
         if(this.hzcRxLast != 0)
         {
            dt = now - this.hzcRxLast;
            if(dt < 0) { dt = 0; }
            if(dt > 100) { dt = 100; }
         }
         this.hzcRxLast = now;
         var slot:Boolean = this.hzcRxSlot(m);
         if(this.hzcRxDbgOn) { try { this.hzcRxDbgScan(arr); } catch(eDbg:Error) { } }
         if(!this.hzcRxOn()) { this.hzcRxAll(); return; }
         try { this.hzcMsgLayout(); } catch(eLay:Error) { }
         this.hzcRxLink(arr);
         var keep:Array = [];
         for each(var e0:Object in this.hzcRx)
         {
            if(e0 == null || e0.st != 1) { continue; }
            if(e0.linked == true)
            {
               var inList:Boolean = false;
               try { inList = e0.it != null && arr != null && arr.indexOf(e0.it) >= 0 && e0.it.parent === m; } catch(eIn:Error) { inList = false; }
               // The card ends with its line. It does not fall back to a standalone card.
               if(!inList) { this.hzcRxShow(e0); this.hzcRxRemember(e0); this.hzcRxDrop(e0); continue; }
            }
            else
            {
               if(slot) { e0.vis = int(e0.vis) + dt; }
               if(int(e0.vis) >= HZC_RX_VIS) { this.hzcRxShow(e0); this.hzcRxDrop(e0); continue; }
            }
            keep.push(e0);
         }
         this.hzcRx = keep;
         var newest:Object = null;
         for each(var eN:Object in this.hzcRx) { if(eN != null && eN.st == 1) { newest = eN; } }
         var drew:Boolean = false;
         for each(var e:Object in this.hzcRx)
         {
            if(e == null || e.st != 1) { continue; }
            try
            {
               this.hzcRxPlace(e,e === newest,m,slot);
               if(e.judged != true) { e.judged = true; drew = true; }
            }
            catch(err:Error)
            {
               if(e.blamed != true) { e.blamed = true; e.judged = true; this.hzcRxHit(err); }
               e.sig = "";
               try { if(e.c != null) { e.c.visible = false; } } catch(eHide:Error) { }
            }
         }
         if(drew) { this.hzcRxFail = 0; }
         try { this.hzcRxStack(); } catch(eSt:Error) { }
         if(this.hzcRxFail >= 3) { this.hzcRxLatch(); return; }
      }
      // A card is taller than the gap between game lines. The top card stays. Lower cards move down. x stays.
      private function hzcRxStack() : void
      {
         var vis:Array = [];
         for each(var e0:Object in this.hzcRx)
         {
            if(e0 == null || e0.c == null || e0.c.visible != true) { continue; }
            if(isNaN(Number(e0.c.y)) || isNaN(Number(e0.h))) { continue; }
            vis.push(e0);
         }
         var i:int = 0;
         while(i < vis.length)
         {
            var j:int = i + 1;
            while(j < vis.length)
            {
               if(Number(vis[j].c.y) < Number(vis[i].c.y))
               {
                  var tmp:Object = vis[i];
                  vis[i] = vis[j];
                  vis[j] = tmp;
               }
               j++;
            }
            i++;
         }
         var gap:Number = 8;
         var p:int = 1;
         while(p < vis.length)
         {
            var prev:Object = vis[p - 1];
            var cur:Object = vis[p];
            var floorY:Number = Number(prev.c.y) + Number(prev.h) + gap;
            if(Number(cur.c.y) < floorY) { cur.c.y = Math.round(floorY); }
            p++;
         }
      }
      private function hzcRxScale() : Number
      {
         var s:Number = this.hzcScale();
         if(isNaN(s) || s <= 0) { s = 1; }
         return Math.max(13 / 14,Math.min(1.3,s));   // 13 px text at least; at most 1.3 so it stays near the game's line height
      }
      private function hzcRxAnchor(e:Object, m:*) : void
      {
         if(e == null || e.c == null) { return; }
         var x:Number = 40;
         var y:Number = 80;
         var r:Rectangle = null;
         if(m != null) { try { r = m.getBounds(this); } catch(e0:Error) { r = null; } }
         if(r != null && !isNaN(r.x) && !isNaN(r.y) && !isNaN(r.width) && r.width > 2 && r.height > 2)
         {
            x = r.x + r.width - Number(e.w);
            y = r.y;
         }
         else
         {
            var vr:Rectangle = null;
            try { vr = this.hzcVis(); } catch(e1:Error) { vr = null; }
            if(vr != null && !isNaN(vr.right)) { x = vr.right - Number(e.w) - 40; y = vr.y + 80; }
         }
         if(isNaN(x) || isNaN(y)) { e.c.visible = false; return; }
         e.c.x = Math.round(x);
         e.c.y = Math.round(y);
         e.c.alpha = 1;
         e.c.visible = true;
      }
      private function hzcRxPlace(e:Object, newest:Boolean, m:*, slot:Boolean) : void
      {
         if(e == null || m == null || this.hzcRxLayer == null) { return; }
         var sig:String = (newest ? "1" : "0") + "|" + this.hzcRxScale() + "|" + this.hzcCfg.SubCard + "|" + this.hzcCfg.SubBgOpacity + "|" + this.hzcCfg.SpeakerColor + "|" + this.hzcCfg.SpeakerHex + "|" + this.hzcCfg.SubFont + "|" + this.hzcCfg.FontFace + "|" + this.hzcCfg.AccentColor + "|" + this.hzcCfg.AccentHex + "|" + e.k + "|" + e.n + "|" + (e.kind != null ? String(e.kind) : "") + "|" + (e.sub != null ? String(e.sub) : "") + "|" + (e.value != null ? String(e.value) : "");
         if(e.c == null || e.sig != sig)
         {
            this.hzcRxDraw(e,newest);
            e.sig = sig;
         }
         if(e.c == null) { return; }
         if(!slot) { e.c.visible = false; return; }
         var it:* = e.it;
         var placed:Boolean = false;
         if(it != null)
         {
            var im:* = null;
            try { im = it.Internal_mc; } catch(eIm:Error) { im = null; }
            if(im != null)
            {
               var bg:* = null;
               try { bg = im.Background_mc; } catch(eBg:Error) { bg = null; }
               if(bg != null)
               {
                  var gp:Point = null;
                  try { gp = im.localToGlobal(new Point(Number(bg.x) + Number(bg.width),Number(bg.y) + Number(bg.height) / 2)); } catch(eGp:Error) { gp = null; }
                  var lp:Point = null;
                  if(gp != null) { try { lp = this.globalToLocal(gp); } catch(eLp:Error) { lp = null; } }
                  if(lp != null && !isNaN(lp.x) && !isNaN(lp.y))
                  {
                     e.c.x = Math.round(lp.x - Number(e.w));
                     e.c.y = Math.round(lp.y - Number(e.h) / 2);
                     var a:Number = 1;
                     try { a = Number(it.alpha) * Number(im.alpha) * Number(m.alpha); } catch(eA:Error) { a = 1; }
                     if(isNaN(a)) { a = 1; }
                     e.c.alpha = Math.max(0,Math.min(1,a));
                     e.c.visible = true;
                     placed = true;
                     if(e.c.visible == true && Number(e.w) > 0) { this.hzcRxCover(e, it); }
                  }
               }
            }
         }
         if(!placed)
         {
            if(e.linked == true) { this.hzcRxShow(e); return; }
            this.hzcRxAnchor(e,m);
         }
      }
      private function hzcOnAlerts(ev:FromClientDataEvent) : void
      {
         try
         {
            if(ev == null || ev.data == null) { return; }
            var a:Array = ev.data.aPersonalAlerts as Array;
            if(a == null) { return; }
            var keep:Array = [];
            var i:int = 0;
            while(i < a.length && keep.length < 8)
            {
               var o:Object = a[i];
               i++;
               if(o == null) { continue; }
               var txt:String = o.sAlertText != null ? String(o.sAlertText) : "";
               var sub:String = o.sAlertSubText != null ? String(o.sAlertSubText) : "";
               var icon:String = o.sEffectIcon != null ? String(o.sEffectIcon) : "";
               keep.push({"txt":txt,"sub":sub,"icon":icon});
            }
            this.hzcAlerts = keep;
         }
         catch(e:Error) { }
      }
      private function hzcSplitCamel(s:String) : String
      {
         if(s == null || s.length < 2) { return s == null ? "" : s; }
         var o:String = s.charAt(0);
         var i:int = 1;
         while(i < s.length)
         {
            var p:int = s.charCodeAt(i - 1);
            var c:int = s.charCodeAt(i);
            if(p >= 97 && p <= 122 && c >= 65 && c <= 90) { o += " "; }
            o += s.charAt(i);
            i++;
         }
         return o;
      }
      private function hzcIconName(icon:String) : String
      {
         var s:String = icon == null ? "" : String(icon);
         var pre:String = "PersonalEffect_";
         if(s.length >= pre.length && s.substr(0,pre.length) == pre) { s = s.substr(pre.length); }
         var neg:String = "_Negative";
         var pos:String = "_Positive";
         if(s.length > neg.length && s.substr(s.length - neg.length) == neg) { s = s.substr(0,s.length - neg.length); }
         if(s.length > pos.length && s.substr(s.length - pos.length) == pos) { s = s.substr(0,s.length - pos.length); }
         return this.hzcSplitCamel(s);
      }
      private function hzcAlertGroup(name:String) : String
      {
         if(name == null || name.length == 0) { return ""; }
         var want:String = name.toLowerCase();
         var i:int = 0;
         while(i < this.hzcAlerts.length)
         {
            var o:Object = this.hzcAlerts[i];
            i++;
            if(o == null) { continue; }
            var txt:String = o.txt != null ? String(o.txt) : "";
            var pretty:String = this.hzcIconName(o.icon != null ? String(o.icon) : "");
            if(txt.toLowerCase() != want && pretty.toLowerCase() != want) { continue; }
            var sub:String = o.sub != null ? String(o.sub) : "";
            if(sub.length > 0 && sub.toLowerCase() != want) { return sub; }
            if(pretty.length > 0 && pretty.toLowerCase() != want) { return pretty; }
         }
         return "";
      }
      private function hzcCardZ() : Number
      {
         var z:Number = 1;
         var ts:Number = Number(this.hzcCfg.TextScale);
         if(isNaN(ts) || ts <= 0) { ts = 1; }
         var hs:Number = Number(this.hzcCfg.HudScale);
         if(isNaN(hs) || hs <= 0) { hs = 1; }
         z = ts * hs;
         if(HZC_LRG) { z = z * 1.25; }
         if(z < 0.75) { z = 0.75; }
         if(z > 2.2) { z = 2.2; }
         return z;
      }
      // -1 means the F11 accent. Tone is the icon and the chip. The left bar stays the accent.
      private function hzcCardTone(kind:String, sub:String) : int
      {
         if(kind == "credits")
         {
            if(sub == "gain" || sub == "bounty-add") { return HZC_GRN; }
            return HZC_RED;
         }
         if(sub == "gained" || sub == "worse" || sub == "furious" || sub == "caught" || sub == "takeback" || sub == "lock" || sub == "alarm") { return HZC_RED; }
         if(sub == "improved" || sub == "severity" || sub == "cured" || sub == "friend" || sub == "ally" || sub == "partner" || sub == "calm") { return HZC_GRN; }
         if(sub == "attempted" || sub == "unfollow" || sub == "follow-unavailable" || sub == "uncompanion" || sub == "companion-unavailable" || sub == "uncrew" || sub == "crew-unavailable" || sub == "busy" || sub == "angry" || sub == "trespass" || sub == "witness") { return HZC_CARD_AMB; }
         return -1;
      }
      private function hzcCardPhrase(sub:String) : String
      {
         if(sub == "gained") { return "Gained"; }
         if(sub == "worse") { return "Became worse"; }
         if(sub == "improved") { return "Prognosis improved"; }
         if(sub == "severity") { return "Severity improved"; }
         if(sub == "attempted") { return "Attempted to cure"; }
         if(sub == "cured") { return "Cured"; }
         if(sub == "follow") { return "Is now following you."; }
         if(sub == "unfollow") { return "Is no longer following you."; }
         if(sub == "follow-available") { return "Is available to be your follower."; }
         if(sub == "follow-unavailable") { return "Is no longer available to be your follower."; }
         if(sub == "companion") { return "Is now your Active Companion."; }
         if(sub == "uncompanion") { return "Is no longer your Active Companion."; }
         if(sub == "companion-available") { return "Is available to be your Companion."; }
         if(sub == "companion-unavailable") { return "Is no longer available to be your companion."; }
         if(sub == "crew") { return "Is now an Active Crew Member."; }
         if(sub == "uncrew") { return "Is no longer an Active Crew Member."; }
         if(sub == "crew-available") { return "Is available for your Crew."; }
         if(sub == "crew-unavailable") { return "Is no longer available for your Crew."; }
         if(sub == "friend") { return "Considers you a friend."; }
         if(sub == "ally") { return "Considers you an ally."; }
         if(sub == "partner") { return "Considers you a committed partner."; }
         if(sub == "angry") { return "Is angry with you."; }
         if(sub == "calm") { return "Is no longer angry with you."; }
         if(sub == "furious") { return "Is furious with you and will no longer be your companion."; }
         return "";
      }
      private function hzcCardTitle(kind:String, sub:String, name:String) : String
      {
         var n:String = name == null ? "" : String(name);
         if(kind == "credits")
         {
            if(sub == "kid") { return "SENT HOME"; }
            if(sub == "bounty") { return "BOUNTY PAID"; }
            return "CREDITS";
         }
         if(kind == "crime")
         {
            if(sub == "takeback" || sub == "lock") { return "CAUGHT"; }
            if(sub == "alarm") { return "ALARM"; }
            if(sub == "trespass") { return "TRESPASS"; }
            if(sub == "witness") { return "WITNESS"; }
            return "CRIME";
         }
         if(n.length > 0) { return n.toUpperCase(); }
         if(kind == "medical") { return "AFFLICTION"; }
         if(kind == "crew") { return "CREW"; }
         if(sub == "busy") { return "BUSY"; }
         if(sub == "calmed") { return "CALMED"; }
         if(sub == "caught") { return "PICKPOCKET"; }
         return "NOTICE";
      }
      private function hzcCardIcon(g:*, kind:String, ix:Number, iy:Number, s:Number, col:uint) : void
      {
         var cx:Number = ix + s / 2;
         var cy:Number = iy + s / 2;
         if(kind == "credits")
         {
            g.lineStyle(Math.max(1,s / 12),col,1,true,"none");
            g.beginFill(col,0.14);
            g.drawCircle(cx,cy,s * 0.36);
            g.endFill();
            g.lineStyle();
            return;
         }
         if(kind == "unavailable" || kind == "crime")
         {
            g.beginFill(col,1);
            g.drawRoundRect(cx - s * 0.22,cy - s * 0.28,s * 0.12,s * 0.56,2,2);
            g.drawRoundRect(cx + s * 0.10,cy - s * 0.28,s * 0.12,s * 0.56,2,2);
            g.endFill();
            return;
         }
         if(kind == "crew")
         {
            g.lineStyle(Math.max(1,s / 14),col,1,true,"none");
            g.beginFill(col,0.16);
            g.drawCircle(cx,cy - s * 0.16,s * 0.16);
            g.endFill();
            g.lineStyle(Math.max(1,s / 12),col,1,true,"none");
            g.moveTo(cx - s * 0.28,cy + s * 0.28);
            g.curveTo(cx,cy - s * 0.02,cx + s * 0.28,cy + s * 0.28);
            g.lineStyle();
            return;
         }
         g.lineStyle(Math.max(1.5,s / 10),col,1,true,"none","round");
         g.moveTo(cx - s * 0.28,cy);
         g.lineTo(cx + s * 0.28,cy);
         g.moveTo(cx,cy - s * 0.28);
         g.lineTo(cx,cy + s * 0.28);
         g.lineStyle();
      }
      private function hzcCardDraw(e:Object) : void
      {
         if(e == null) { return; }
         this.hzcRxDrop(e);
         if(this.hzcRxLayer == null || this.hzcCfg == null) { return; }
         var kind:String = e.kind != null ? String(e.kind) : "";
         var sub:String = e.sub != null ? String(e.sub) : "";
         var name:String = e.n != null ? String(e.n) : "";
         var value:String = e.value != null ? String(e.value) : "";
         var raw:String = e.tx != null ? String(e.tx) : "";
         var z:Number = this.hzcCardZ();
         var acc:uint = this.hzcAccent();
         var toneI:int = this.hzcCardTone(kind,sub);
         var tone:uint = toneI < 0 ? acc : uint(toneI);
         var c:Sprite = new Sprite();
         c.mouseEnabled = false;
         c.mouseChildren = false;
         var titleFs:Number = Math.max(13,Math.round(15 * z));
         var subFs:Number = Math.max(13,Math.round(13 * z));
         var chipFs:Number = Math.max(13,Math.round(13 * z));
         var title:String = this.hzcCardTitle(kind,sub,name);
         var phrase:String = "";
         if(kind == "unavailable" || kind == "credits" || kind == "crime") { phrase = raw; }
         else
         {
            phrase = this.hzcCardPhrase(sub);
            if(kind == "medical")
            {
               var grp:String = this.hzcAlertGroup(name);
               if(grp.length > 0) { phrase = phrase.length > 0 ? phrase + " · " + grp : grp; }
            }
            if(phrase.length == 0) { phrase = raw; }
         }
         var chipTx:String = value;
         if(kind == "credits" && sub == "kid" && value.length > 0) { chipTx = value + " CR"; }
         var w:Number = Math.round(360 * z);
         if(w < 280) { w = 280; }
         var nm:TextField = this.hzcField(true);
         if(nm == null) { return; }
         this.hzcSet(nm,title,"nm",titleFs,0xFFFFFF,Math.round(titleFs * 0.04 * 10) / 10,"left");
         nm.alpha = 0.95;
         var chip:TextField = null;
         var cw:Number = 0;
         var chipH:Number = Math.round(20 * z);
         if(chipH < 20) { chipH = 20; }
         if(chipTx.length > 0)
         {
            chip = this.hzcField(true);
            if(chip != null)
            {
               this.hzcSet(chip,chipTx,"nm",chipFs,tone,0,"left");
               var tw:Number = Math.ceil(chip.textWidth);
               if(isNaN(tw) || tw < 0) { tw = 40; }
               cw = tw + Math.round(16 * z);
            }
         }
         var tx:Number = Math.round(52 * z);
         var right:Number = Math.round(14 * z);
         var gap:Number = Math.round(8 * z);
         var titleW:Number = w - tx - right - (cw > 0 ? cw + gap : 0);
         if(titleW < 48) { titleW = 48; }
         nm.autoSize = TextFieldAutoSize.NONE;
         nm.width = titleW;
         nm.height = Math.round(titleFs + 6);
         var body:TextField = this.hzcField(false);
         if(body == null) { return; }
         body.multiline = true;
         body.wordWrap = true;
         body.autoSize = TextFieldAutoSize.NONE;
         body.width = w - tx - right;
         this.hzcSet(body,phrase,"rg",subFs,0xFFFFFF,0,"left");
         body.alpha = 0.7;
         var bodyH:Number = body.textHeight + 4;
         var two:Number = subFs * 2 + 8;
         if(bodyH > two) { bodyH = two; }
         if(bodyH < subFs) { bodyH = subFs + 4; }
         body.height = bodyH;
         var top:Number = Math.round(10 * z);
         var bot:Number = Math.round(10 * z);
         var rowH:Number = nm.height;
         if(chip != null && chipH > rowH) { rowH = chipH; }
         var h:Number = Math.round(top + rowH + 2 + bodyH + bot);
         var minH:Number = Math.round(56 * z);
         if(h < minH) { h = minH; }
         var opa:Number = Number(this.hzcOpacity);
         if(isNaN(opa)) { opa = 1; }
         opa = Math.max(0,Math.min(1,opa)) * 0.88;
         var g:* = c.graphics;
         if(g == null) { return; }
         var rad:Number = Math.max(4,Math.round(4 * z) * 2);
         g.beginFill(HZC_CARD_BG,opa);
         g.drawRoundRect(0,0,w,h,rad,rad);
         g.endFill();
         g.beginFill(acc,1);
         g.drawRect(0,0,Math.max(4,Math.round(4 * z)),h);
         g.endFill();
         g.lineStyle(1,0xFFFFFF,0.08,true,"none");
         g.drawRoundRect(0.5,0.5,w - 1,h - 1,rad,rad);
         g.lineStyle();
         var iconS:Number = Math.round(24 * z);
         if(iconS < 18) { iconS = 18; }
         this.hzcCardIcon(g,kind,Math.round(16 * z),(h - iconS) / 2,iconS,tone);
         nm.x = tx;
         nm.y = top + Math.round((rowH - nm.height) / 2);
         body.x = tx;
         body.y = top + rowH + 2;
         c.addChild(nm);
         c.addChild(body);
         if(chip != null && cw > 0)
         {
            var boxX:Number = w - right - cw;
            var boxY:Number = top + Math.round((rowH - chipH) / 2);
            g.beginFill(tone,0.14);
            g.drawRoundRect(boxX,boxY,cw,chipH,6,6);
            g.endFill();
            chip.x = boxX + Math.round(8 * z);
            chip.y = boxY + Math.round((chipH - chip.height) / 2);
            c.addChild(chip);
         }
         c.visible = false;
         this.hzcRxLayer.addChild(c);
         e.c = c;
         e.w = w;
         e.h = h;
         if(kind == "crew" && this.hzcRxDbgOn)
         {
            try { this.hzcRxDbgPush("crew card: path=hzcCardDraw sub=" + sub + " name=\"" + this.hzcRxDbgEsc(name) + "\" raw=\"" + this.hzcRxDbgEsc(raw) + "\""); } catch(eCrew:Error) { }
         }
      }
      private function hzcRxDraw(e:Object, newest:Boolean) : void
      {
         if(e == null) { return; }
         if(e.kind != null && String(e.kind).length > 0 && String(e.kind) != "reaction")
         {
            this.hzcCardDraw(e);
            return;
         }
         this.hzcRxDrop(e);
         if(this.hzcRxLayer == null || this.hzcCfg == null) { return; }
         var k:int = int(e.k);
         if(k < 0 || k >= HZC_RX_LBL.length || k >= HZC_RX_COL.length || k >= HZC_RX_DIR.length) { return; }
         var c:Sprite = new Sprite();
         c.mouseEnabled = false;
         c.mouseChildren = false;
         var z:Number = this.hzcRxScale();
         var col:uint = uint(HZC_RX_COL[e.k]);
         var card:Boolean = int(this.hzcCfg.SubCard) == 1;
         var fs:Number = Math.max(13,Math.round(14 * z));
         var h:Number = Math.round(44 * z);
         var nm:TextField = this.hzcField(true);
         if(nm == null) { return; }
         // Same uppercase as the subtitle speaker and the speaker card. All-caps game text is not a second style.
         if(e.n == null) { e.n = ""; }
         this.hzcSet(nm,String(e.n).toUpperCase(),"nm",fs,this.hzcSpeakerCol(),Math.round(fs * 0.1 * 10) / 10,"left");
         var lb:TextField = this.hzcField(true);
         if(lb == null) { return; }
         this.hzcSet(lb,String(HZC_RX_LBL[e.k]),"nm",fs,col,Math.round(fs * 0.12 * 10) / 10,"left");
         var nx:Number = Math.round((14 + 30 + 12) * z);
         var nw:Number = Math.ceil(nm.textWidth);
         if(isNaN(nw) || nw < 0) { nw = 0; }
         var lx:Number = Math.round(nx + nw + 14 * z);
         var lw:Number = Math.ceil(lb.textWidth);
         if(isNaN(lw) || lw < 0) { lw = 0; }
         var w:Number = Math.round(lx + lw + 18 * z);
         if(w < 40) { w = 40; }
         if(h < 20) { h = 20; }
         var g:* = c.graphics;
         if(g == null) { return; }
         if(card)
         {
            var bo:Number = Number(this.hzcCfg.SubBgOpacity);
            if(isNaN(bo)) { bo = 0.7; }
            g.beginFill(0x0B1218,Math.max(0,Math.min(1,bo)));
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
      // file is normal: its IOErrorEvent is caught and counts as no file. The game logs every failed open, so
      // HorizonUI.ini is opened at most once, and only when Compose still needs that unshipped file.
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hzc37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hzc37_BOM:String = String.fromCharCode(0xFEFF);
      private var hzc37Ldr:URLLoader = null;
      private var hzc37Step:int = 0;          // 0 idle, n = reading hzc37_FILES[n - 1]
      private var hzc37T0:Number = 0;
      private var hzc37Got:Array = null;
      private var hzc37Q:Array = [];          // callbacks of the running read
      private var hzc37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private var hzc37Leg:String = null;     // last text of HorizonUI.ini, or null when that open missed
      private var hzc37LegTry:int = 0;        // 0 = not opened yet, 1 = opened once
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
      private function hzc37IsLeg(i:int) : Boolean
      {
         if(i < 0 || i >= hzc37_FILES.length) { return false; }
         var pth:String = String(hzc37_FILES[i]);
         return pth.length >= 13 && pth.substr(pth.length - 13) == "HorizonUI.ini";
      }
      // HorizonUI.ini is not shipped. Skip it when Compose would ignore it, and open it only once when it would not.
      private function hzc37SkipLeg(i:int) : Boolean
      {
         if(!this.hzc37IsLeg(i)) { return false; }
         if(this.hzc37LegTry != 0) { return true; }
         var def:String = this.hzc37Got[0] == null ? null : String(this.hzc37Got[0]);
         var hd:Boolean = def != null && def.length > 0;
         if(hd && (this.hzc37Got[1] != null || this.hzc37Got[2] != null)) { return true; }
         return false;
      }
      private function hzc37Next(i:int) : void
      {
         this.hzc37Step = i + 1;
         if(i >= hzc37_FILES.length) { this.hzc37Ldr = null; this.hzc37Done(); return; }
         if(this.hzc37SkipLeg(i))
         {
            this.hzc37Got[i] = this.hzc37LegTry != 0 ? this.hzc37Leg : null;
            this.hzc37Next(i + 1);
            return;
         }
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
         if(this.hzc37IsLeg(i)) { this.hzc37Leg = this.hzc37Got[i] == null ? null : String(this.hzc37Got[i]); this.hzc37LegTry = 1; }
         this.hzc37Next(i + 1);
      }
      private function hzc37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hzc37Ldr) { return; }
         if(this.hzc37IsLeg(this.hzc37Step - 1)) { this.hzc37Leg = null; this.hzc37LegTry = 1; }
         this.hzc37Next(this.hzc37Step);   // missing file: counted once, not opened again
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

