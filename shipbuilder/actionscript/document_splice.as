package
{
   // Notes for the desktop builder. Do not place this class on the stage.
   // Splice the steps below into BOTH vanilla movies:
   // spaceshipeditormenu.swf and spaceshipeditormenu_lrg.swf.
   // Keep the vanilla document class. Do not replace either movie with a new one.
   // Compile every .as file in this folder except this one (HorizonShipBuilder, Hsb*, and
   // HorizonShipBuilderProbe) against the classes already in that vanilla movie, including
   // Shared.AS3.Data.BSUIDataManager and Shared.AS3.Events.CustomEvent.
   public class HorizonShipBuilderSpliceNotes
   {
      // 1. Put both scripts in the same script list as the document class.
      //    Inside the SpaceshipEditorMenu package, add:
      //    import HorizonShipBuilder;
      //    import HorizonShipBuilderProbe;
      //
      // 2. Add this member on SpaceshipEditorMenu:
      //    public var hsb:HorizonShipBuilder;
      //
      // 3. If the class already overrides onAddedToStage, add these lines at the
      //    end of that function, after super.onAddedToStage() and the vanilla
      //    data subscriptions:
      //    this.hsb = new HorizonShipBuilder(this);
      //    this.addChild(this.hsb);
      //
      //    If this decompile has no onAddedToStage, add the override:
      //    override public function onAddedToStage():void
      //    {
      //       super.onAddedToStage();
      //       this.hsb = new HorizonShipBuilder(this);
      //       this.addChild(this.hsb);
      //    }
      //
      //    Do not construct HorizonShipBuilderProbe here. The gold layer creates
      //    it only when the user ini sets Probe=1. The default path has no
      //    overlay and no F keys.
      //
      // 4. Add these methods. menuObj.Invoke looks them up on the document.
      //    public function hsbProbePing():String
      //    {
      //       return this.hsb != null ? this.hsb.ping() : "";
      //    }
      //
      //    public function hsbTakeLines():String
      //    {
      //       return this.hsb != null ? this.hsb.takeLines() : "";
      //    }
      //
      //    public function hsbProbeHotkey(param1:Number):void
      //    {
      //    }
      //
      //    public function hsbProbeStage():String
      //    {
      //       return this.hsb != null ? this.hsb.stageBox() : "";
      //    }
      //
      //    public function hsbSetDebug(param1:Number):void
      //    {
      //       if(this.hsb != null) { this.hsb.setDebug(param1); }
      //    }
      //
      //    public function hsbApply(param1:String):void
      //    {
      //       if(this.hsb != null) { this.hsb.apply(param1); }
      //    }
      //
      //    public function hsbFeed(param1:String):void
      //    {
      //       if(this.hsb != null) { this.hsb.feed(param1); }
      //    }
      //
      //    public function hsbSaved(param1:Number):void
      //    {
      //       if(this.hsb != null) { this.hsb.saved(param1); }
      //    }
      //
      //    public function hsbTakeFiles():String
      //    {
      //       return this.hsb != null ? this.hsb.takeFiles() : "";
      //    }
      //
      //    public function hsbFiles(param1:String):void
      //    {
      //       if(this.hsb != null) { this.hsb.files(param1); }
      //    }
      //
      // 5. ProcessUserEvent returns Boolean. While a Horizon popup, dialog, text
      //    field, the category grid or Arrange is open, return true before the
      //    vanilla body so Esc does not open the exit confirm. Do not return early
      //    on the default path. Let the vanilla body keep running then.
      //    public function ProcessUserEvent(param1:String, param2:Boolean):Boolean
      //    {
      //       if(this.hsb != null && this.hsb.wantsEvent(param1, param2))
      //       {
      //          return true;
      //       }
      //       // vanilla body stays here
      //    }
      //
      // 6. OnLeftStickInput returns Boolean. While Horizon captures input, return true
      //    before the vanilla body so the stick does not scroll the hidden palette or
      //    Flight Check list behind a Horizon popup. Keep the vanilla body otherwise.
      //    public function OnLeftStickInput(param1:Number, param2:Number, param3:Number, param4:Boolean, param5:Boolean, param6:uint):Boolean
      //    {
      //       if(this.hsb != null && this.hsb.wantsStick())
      //       {
      //          return true;
      //       }
      //       // vanilla body stays here
      //    }
   }
}
