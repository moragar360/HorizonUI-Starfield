package
{
   // Notes for the desktop builder. Do not place this class on the stage.
   // Splice the steps below into BOTH vanilla movies:
   // spaceshipeditormenu.swf and spaceshipeditormenu_lrg.swf.
   // Keep the vanilla document class. Do not replace either movie with a new one.
   public class HorizonShipBuilderSpliceNotes
   {
      // 1. Add this member on SpaceshipEditorMenu:
      //    public var hsbProbe:HorizonShipBuilderProbe;
      //
      // 2. At the end of onAddedToStage, after the vanilla subscriptions:
      //    this.hsbProbe = new HorizonShipBuilderProbe(this);
      //    this.addChild(this.hsbProbe);
      //
      // 3. Add these methods. menuObj.Invoke looks them up on the document.
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
      // 4. ProcessUserEvent returns Boolean. Add this as the first lines.
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
