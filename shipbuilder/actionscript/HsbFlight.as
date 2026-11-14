package
{
   import flash.display.Graphics;
   import flash.events.EventDispatcher;
   import flash.text.TextField;

   // Purpose: the Flight Check card from gold mockup 13, in the Selected Module card's slot:
   //    the game's tabs with their live keys, error, warning and passed counts, then each
   //    message as the game words it (errors first, then warnings, then passed checks).
   // Inputs: FlightCheckData {aFlightCheckTabs [{sName, iTabType}], bShowMessages,
   //    bShowWeapons, aMessages [{uMessageType 0 nominal / 1 warning / 2 error, sHeaderText,
   //    sBodyText}]}; pointer and wheel routed by the builder.
   // Outputs: a tab click clicks the same tab of the game's own (hidden) tab bar, which selects
   //    it and sends ShipEditor_OnFlightCheckTabChanged {tabType} itself, so the bar, its keys
   //    and the game agree on the tab. Without that bar the event is sent directly.
   // Dependencies: HorizonShipBuilder (send, clickNative, keyName, hostClip), HsbKit, the vanilla
   //    FlightCheck_mc.FlightCheckCategories_mc (BSTabbedSelection: selectedIndex, GetClipByIndex).
   // Backend limits: the game gives no fix actions per message, so none are drawn; the
   //    Weapons tab shows the game's own weapon groups panel (Horizon steps aside for it).
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbFlight extends HsbBox
   {
      private static const NOMINAL:uint = 0;
      private static const WARNING:uint = 1;
      private static const ERROR:uint = 2;

      private var hsb:HorizonShipBuilder;
      private var scroll:int = 0;
      private var lastCount:int = -1;
      private var tabTypes:Array = [];

      public function HsbFlight(param1:HsbKit, param2:HorizonShipBuilder)
      {
         super(param1,"HsbFlight");
         this.hsb = param2;
      }

      internal function paint(param1:Object):void
      {
         this.wipe();
         if(param1 == null || !Boolean(param1.bShowMessages))
         {
            this.boxW = 0;
            this.boxH = 0;
            return;
         }
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var w:Number = k.lrg ? 390 : 350;
         var pad:Number = 20;
         var y:Number = 18;
         k.label(this,pad,y,"FLIGHT CHECK",16,HsbKit.TEXT,true,3);
         y += k.u(34);
         y = this.paintTabs(param1,pad,y,w);
         var msgs:Array = param1.aMessages as Array;
         if(msgs == null) { msgs = []; }
         if(msgs.length != this.lastCount)
         {
            this.lastCount = msgs.length;
            this.scroll = 0;
         }
         var errors:Array = [];
         var warnings:Array = [];
         var passed:Array = [];
         var i:int = 0;
         while(i < msgs.length)
         {
            var m:Object = msgs[i];
            var t:uint = uint(m.uMessageType);
            if(t == NOMINAL) { passed.push(m); }
            else if(t == WARNING) { warnings.push(m); }
            else { errors.push(m); }
            i++;
         }
         var cx:Number = pad;
         cx += this.chip(cx,y,errors.length + (errors.length == 1 ? " ERROR" : " ERRORS"),HsbKit.RED,HsbKit.RED_BG) + 8;
         cx += this.chip(cx,y,warnings.length + (warnings.length == 1 ? " WARNING" : " WARNINGS"),HsbKit.ORANGE,HsbKit.ORANGE_BG) + 8;
         this.chip(cx,y,passed.length + " PASSED",HsbKit.GREEN,HsbKit.GREEN_BG);
         y += k.u(24) + 14;
         k.hline(g,pad,y,w - pad * 2,HsbKit.EDGE,1);
         y += 14;
         var r:Object = this.hsb.viewRect();
         var bottomLimit:Number = Number(r.height) / Math.max(0.5,this.scaleY) - (this.y - Number(r.y)) / Math.max(0.5,this.scaleY) - 30;
         var ordered:Array = errors.concat(warnings).concat(passed);
         var skipped:int = 0;
         i = this.scroll;
         var drawn:int = 0;
         while(i < ordered.length)
         {
            var info:Object = this.measure(ordered[i] as Object,w - pad * 2);
            if(y + Number(info.h) > bottomLimit && drawn > 0)
            {
               skipped = ordered.length - i;
               break;
            }
            y = this.paintMessage(info,pad,y,w - pad * 2);
            drawn++;
            i++;
         }
         if(skipped > 0 || this.scroll > 0)
         {
            k.label(this,pad,y + 2,(skipped > 0 ? skipped + " more \u00B7 " : "") + "scroll for more",12,HsbKit.MUTED);
            y += k.u(22);
         }
         if(msgs.length == 0)
         {
            k.label(this,pad,y,"No messages from the game yet.",13,HsbKit.MUTED);
            y += k.u(24);
         }
         y += 8;
         k.card(this.graphics,0,0,w,y);
         this.boxW = w;
         this.boxH = y;
      }

      // Game tab names; the outer caps are the game's own keys for the previous and next tab.
      private function paintTabs(param1:Object, param2:Number, param3:Number, param4:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var tabs:Array = param1.aFlightCheckTabs as Array;
         if(tabs == null || tabs.length == 0) { return param3; }
         var capH:Number = k.u(22);
         var x:Number = param2;
         var prev:String = this.hsb.keyName("PrevCategory");
         if(prev.length > 0) { x += k.keycap(this,x,param3,prev,HsbKit.LABEL,capH) + 14; }
         var picked:int = this.selectedTab(tabs.length,Boolean(param1.bShowWeapons));
         this.tabTypes = [];
         var i:int = 0;
         while(i < tabs.length)
         {
            var tab:Object = tabs[i];
            this.tabTypes.push(int(tab.iTabType));
            var on:Boolean = i == picked;
            var tf:TextField = k.text(13,on ? k.accent : HsbKit.LABEL,true,1.5);
            k.put(tf,tab.sName);
            k.put(tf,tf.text.toUpperCase());
            k.fit(tf);
            this.add(tf,x,param3 + (capH - tf.height) / 2);
            if(on) { k.fill(g,x,param3 + capH + 3,tf.width - 4,2,0,k.accent,1); }
            this.hit(x - 4,param3 - 4,tf.width + 8,capH + 10,"tab",i);
            x += tf.width + 16;
            i++;
         }
         var nextKey:String = this.hsb.keyName("NextCategory");
         if(nextKey.length > 0) { k.keycap(this,x,param3,nextKey,HsbKit.LABEL,capH); }
         return param3 + capH + 18;
      }

      private function chip(param1:Number, param2:Number, param3:String, param4:uint, param5:uint):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var t:TextField = k.text(12,param4,true,1);
         k.put(t,param3);
         k.fit(t);
         var h:Number = k.u(24);
         var w:Number = t.width + 18;
         k.fill(g,param1,param2,w,h,h / 2,param5,1);
         k.outline(g,param1,param2,w,h,h / 2,HsbKit.mix(param4,HsbKit.FILL,0.7),1);
         this.add(t,param1 + 9,param2 + (h - t.height) / 2);
         return w;
      }

      // Builds one message's fields and its height; paintMessage then places them.
      private function measure(param1:Object, param2:Number):Object
      {
         var k:HsbKit = this.kit;
         var type:uint = uint(param1.uMessageType);
         if(type > ERROR) { type = ERROR; }
         var head:TextField = k.text(15,type == ERROR ? HsbKit.RED : (type == WARNING ? HsbKit.ORANGE : HsbKit.TEXT),type != NOMINAL);
         head.multiline = true;
         head.wordWrap = true;
         head.width = param2 - (type == ERROR ? 52 : 34);
         k.put(head,param1.sHeaderText);
         head.height = head.textHeight + 6;
         var body:TextField = null;
         var bodyText:String = param1.sBodyText != null ? String(param1.sBodyText) : "";
         if(bodyText.length > 0)
         {
            body = k.text(13,type == ERROR ? HsbKit.TEXT : HsbKit.LABEL);
            body.multiline = true;
            body.wordWrap = true;
            body.width = head.width;
            k.put(body,bodyText);
            body.height = body.textHeight + 6;
         }
         var h:Number;
         if(type == NOMINAL) { h = Math.max(k.u(32),head.height + (body != null ? body.height : 0) + 6); }
         else { h = 12 + head.height + (body != null ? body.height + 2 : 0) + 12 + 10; }
         return {"type":type,"head":head,"body":body,"h":h};
      }

      // Errors sit in a red box with a red edge; warnings get the orange mark; passed checks a
      // green tick. Returns where the next message starts.
      private function paintMessage(param1:Object, param2:Number, param3:Number, param4:Number):Number
      {
         var k:HsbKit = this.kit;
         var g:Graphics = this.gfx;
         var type:uint = uint(param1.type);
         var head:TextField = param1.head as TextField;
         var body:TextField = param1.body as TextField;
         if(type == NOMINAL)
         {
            k.icon(g,"checkCircle",param2,param3 + (k.u(32) - 20) / 2,20,HsbKit.GREEN,1);
            this.add(head,param2 + 30,param3 + (k.u(32) - head.height) / 2);
            if(body != null) { this.add(body,param2 + 30,param3 + head.height); }
            return param3 + Number(param1.h);
         }
         var inner:Number = 12;
         var bh:Number = Number(param1.h) - 10;
         if(type == ERROR)
         {
            k.fill(g,param2,param3,param4,bh,10,HsbKit.RED_BG,1);
            k.fill(g,param2 - 6,param3 + 10,3,bh - 20,1.5,HsbKit.RED,1);
            k.icon(g,"xCircle",param2 + 10,param3 + inner,20,HsbKit.RED,1);
            this.add(head,param2 + 40,param3 + inner - 2);
            if(body != null) { this.add(body,param2 + 40,param3 + inner + head.height); }
         }
         else
         {
            k.icon(g,"warn",param2,param3 + inner - 2,20,HsbKit.ORANGE,1);
            this.add(head,param2 + 30,param3 + inner - 4);
            if(body != null) { this.add(body,param2 + 30,param3 + inner - 2 + head.height); }
         }
         return param3 + Number(param1.h);
      }

      override internal function onWheel(param1:Number, param2:Number, param3:Number):void
      {
         this.scroll = HorizonShipBuilder.clampInt(this.scroll - int(param1),0,Math.max(0,this.lastCount - 1));
         this.hsb.mark("Flight");
      }

      override internal function onAct(param1:String, param2:*):void
      {
         if(param1 != "tab") { return; }
         var index:int = int(param2);
         var entry:EventDispatcher = null;
         try
         {
            var bar:Object = this.nativeTabs();
            entry = bar != null ? bar.GetClipByIndex(index) as EventDispatcher : null;
         }
         catch(err:Error) { entry = null; }
         if(!this.hsb.clickNative(entry) && index >= 0 && index < this.tabTypes.length)
         {
            this.hsb.send("ShipEditor_OnFlightCheckTabChanged",{"tabType":int(this.tabTypes[index])});
         }
         this.hsb.mark("Flight");
      }

      // The game's own tab bar, kept alive under Horizon; null when the clip is not there.
      private function nativeTabs():Object
      {
         try
         {
            var host:Object = this.hsb.hostClip();
            if(host != null && host.FlightCheck_mc != null) { return host.FlightCheck_mc.FlightCheckCategories_mc; }
         }
         catch(err:Error) { }
         return null;
      }

      // The tab the game's bar has selected; without the bar, the Weapons tab is the second of
      // two while the game shows weapon groups, else the first.
      private function selectedTab(param1:int, param2:Boolean):int
      {
         try
         {
            var bar:Object = this.nativeTabs();
            if(bar != null && bar.selectedIndex != null)
            {
               var n:int = int(bar.selectedIndex);
               if(n >= 0 && n < param1) { return n; }
            }
         }
         catch(err:Error) { }
         return param1 == 2 && param2 ? 1 : 0;
      }
   }
}
