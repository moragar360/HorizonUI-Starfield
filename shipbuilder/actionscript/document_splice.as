package
{
   // Notes for the desktop builder. Do not place this class on the stage.
   // Splice the steps below into BOTH vanilla movies:
   // spaceshipeditormenu.swf and spaceshipeditormenu_lrg.swf.
   // Keep the vanilla document class. Do not replace either movie with a new one.
   // Compile against the classes already in that vanilla movie, including
   // Shared.AS3.Data.BSUIDataManager. HorizonShipBuilderProbe.as imports it.
   public class HorizonShipBuilderSpliceNotes
   {
      // 1. Put HorizonShipBuilderProbe.as in the same script list as the document class.
      //    Inside the SpaceshipEditorMenu package, add:
      //    import HorizonShipBuilderProbe;
      //
      // 2. Add this member on SpaceshipEditorMenu:
      //    public var hsbProbe:HorizonShipBuilderProbe;
      //
      // 3. If the class already overrides onAddedToStage, add these lines at the
      //    end of that function, after super.onAddedToStage() and the vanilla
      //    data subscriptions:
      //    this.hsbProbe = new HorizonShipBuilderProbe(this);
      //    this.addChild(this.hsbProbe);
      //
      //    If this decompile has no onAddedToStage, add the override:
      //    override public function onAddedToStage():void
      //    {
      //       super.onAddedToStage();
      //       this.hsbProbe = new HorizonShipBuilderProbe(this);
      //       this.addChild(this.hsbProbe);
      //    }
      //
      // 4. Add these methods. menuObj.Invoke looks them up on the document.
      //    public function hsbProbePing():String
      //    {
      //       return this.hsbProbe != null ? this.hsbProbe.ping() : "";
      //    }
      //
      //    public function hsbTakeLines():String
      //    {
      //       return this.hsbProbe != null ? this.hsbProbe.takeLines() : "";
      //    }
      //
      // 5. ProcessUserEvent returns Boolean. Add this as the first lines.
      //    Do not return from these lines. Let the vanilla body keep running.
      //    public function ProcessUserEvent(param1:String, param2:Boolean):Boolean
      //    {
      //       if(this.hsbProbe != null)
      //       {
      //          this.hsbProbe.noteUserEvent(param1, param2);
      //       }
      //       // vanilla body stays here
      //    }
   }
}
