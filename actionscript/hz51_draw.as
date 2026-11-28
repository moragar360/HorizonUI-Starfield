      private var hzSetFocus:int = 0;   // 0 list, 1 sidebar, 2 search, 3 dropdown, 4 hex

      // Purpose: draw the Settings 2.0 window: 1260x726 (height locked; width cap
      // so HUD side cards stay visible), 248 sidebar, 196 preview, 48px rows, 1px
      // bar strokes, one hint row. Colors still come from hzSetTheme.
      // Inputs: hzSetPend while F11 is open. Outputs: redrawn HorizonSettings_mc.
      // Author: Moragar. Last modified: 2026-11-27.
      private function hz51Draw() : void
      {
         if(!this.HorizonSettings_mc || !this.hzSetPend) { return; }
         this.hz51Fit();
         this.hzSetPlace();
         var b:Sprite = this.hzSetBody;
         while(b.numChildren > 0) { b.removeChildAt(0); }
         b.graphics.clear();
         this.hzSetKeyOv.graphics.clear();
         this.hzSetHits = [];
         this.hzSetSideHits = [];
         this.hzSetDropBox = null;
         this.hzSetDropMenu = null;
         if(this.hzSetPv != null) { this.hzSetPv.visible = false; }
         var T:Object = this.hzSetTheme();
         var acc:uint = uint(T.acc);
         var W:Number = this.HZ_SET_W;
         var H:Number = this.HZ_SET_H;
         var g:* = b.graphics;
         var win:Sprite = this.HorizonSettings_mc;
         win.graphics.clear();
         // mockup box-shadow: 0 12px 48px #000a — one offset fill on the parent so the
         // body mask can clip children to the rounded window without eating the shadow.
         win.graphics.beginFill(0x000000,0.40);
         win.graphics.drawRoundRect(0,12,W,H,HZ51_WIN_R,HZ51_WIN_R);
         win.graphics.endFill();
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(0,0,W,H,HZ51_WIN_R,HZ51_WIN_R);
         g.endFill();
         this.hz34Ring(b,0,0,W,H,HZ51_WIN_R,acc,HZ51_WIN_EA,1);
         if(this.hzSetWinMask == null) { this.hzSetWinMask = new Sprite(); this.hzSetWinMask.mouseEnabled = false; this.hzSetWinMask.mouseChildren = false; }
         this.hzSetWinMask.graphics.clear();
         this.hzSetWinMask.graphics.beginFill(0xFFFFFF,1);
         this.hzSetWinMask.graphics.drawRoundRect(0,0,W,H,HZ51_WIN_R,HZ51_WIN_R);
         this.hzSetWinMask.graphics.endFill();
         if(this.hzSetWinMask.parent != win) { win.addChild(this.hzSetWinMask); }
         b.mask = this.hzSetWinMask;
         this.hz51DrawHead(b,g,T,acc,W);
         this.hz51DrawTabs(b,g,T,acc,W);
         this.hz51Hair(g,0,HZ51_HEAD + HZ51_TABS - 1,W,1,uint(T.txt),0.10);
         this.hz51DrawSide(b,g,T,acc,H);
         var rows:Array = [];
         try { rows = this.hzSetRows(this.hzSetTab); } catch(eRowsD:Error) { rows = []; }
         if(rows.length == 0) { rows = [{"k":"_empty","l":"NO SETTINGS IN THIS SECTION","t":"x","btn":"—","h":"THIS SECTION","dis":true}]; }
         if(this.hzSetRow >= rows.length) { this.hzSetRow = 0; }
         try { this.hzSetFollow(rows); } catch(eFol:Error) { }
         try { this.hz51DrawList(b,g,T,acc,rows); } catch(eList:Error) { this.hz51T(b,this.hzLt("This page could not be drawn."),HZ51_SIDE_W + 24,HZ_SET_TOP + 60,400,12,"sb",uint(T.mut),0.2); }
         this.hz51DrawRight(b,g,T,acc,rows,H);
         this.hz51DrawFooter(b,g,T,acc,W,H);
         // Row labels are TextFields (children). body.graphics is behind them, so a
         // dropdown fill drawn on g sat under GRAPHITE / "#" from later rows. The
         // overlay sprite is added last so its fill and text cover every row.
         if(this.hzSetOver == null)
         {
            this.hzSetOver = new Sprite();
            this.hzSetOver.mouseEnabled = false;
            this.hzSetOver.mouseChildren = false;
         }
         while(this.hzSetOver.numChildren > 0) { this.hzSetOver.removeChildAt(0); }
         this.hzSetOver.graphics.clear();
         b.addChild(this.hzSetOver);
         if(this.hzSetFindOn || this.hzSetFind.length > 0)
         {
            this.hz51DrawFind(this.hzSetOver,this.hzSetOver.graphics,T,acc,W,H);
            this.hz51DrawArrangeBtn(this.hzSetOver,this.hzSetOver.graphics,T,acc,W);
         }
         if(this.hzSetDrop >= 0) { this.hz51DrawDrop(this.hzSetOver,this.hzSetOver.graphics,T,acc,rows,W,H); }
         b.addChild(this.hzSetKeyOv);
         try { this.hz35TipDraw(b,W,H,T,acc); } catch(e35p:Error) { }
         this.HorizonSettings_mc.setChildIndex(this.hzSetCursor,this.HorizonSettings_mc.numChildren - 1);
         if(this.HorizonSettings_mc.parent == this && getChildIndex(this.HorizonSettings_mc) != numChildren - 1)
         {
            setChildIndex(this.HorizonSettings_mc,numChildren - 1);
         }
      }
      private function hz51DrawHead(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         this.hz51Hair(g,0,HZ51_HEAD - 1,W,1,uint(T.txt),0.10);
         this.hz51T(b,this.hzLt("HORIZON UI"),16,14,150,16,"bd",uint(T.txt),2.4);
         this.hz51T(b,this.hzLt("SETTINGS"),16 + 128,18,90,11,"sb",uint(T.lab),2.0);
         var hv:String = HZ_BUILD;
         if(this.hz42FileVerOk(this.hzDllFileVer)) { hv = this.hzDllFileVer; }
         var pillW:Number = 78;
         var pillX:Number = 250;
         g.beginFill(uint(T.txt),0.04); g.drawRoundRect(pillX,12,pillW,24,12,12); g.endFill();
         this.hz51Stroke(g,pillX,12,pillW,24,uint(T.txt),0.16,12);
         g.beginFill(acc,1); g.drawCircle(pillX + 10,24,3); g.endFill();
         this.hz51T(b,"v" + hv,pillX + 16,16,pillW - 22,11,"sb",uint(T.lab),0.4);
         this.hz51DrawCompact(b,g,T,acc,W);
      }
      private function hz51DrawTabs(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var ty:Number = HZ51_HEAD + 10;
         // LB/RB belong with the footer hints: gamepad only, change-driven (hz51Pad).
         if(this.hz51Pad) { this.hzSetKey(b,g,16,ty + 2,"LB",acc,14,8,10); }
         var tx:Number = this.hz51Pad ? 48 : 16;
         var i:int = 0;
         var tabTf:Array = [];
         var tabSum:Number = 0;
         while(i < HZ_SET_TABS.length)
         {
            var sel:Boolean = i == this.hzSetTab;
            var hov:Boolean = this.hzSetHover == "tab" + i;
            var tb:TextField = this.hz51T(b,this.hzLt(String(HZ_SET_TABS[i])),0,ty,140,12,"bd",sel || hov ? acc : uint(T.mut),1.6);
            tabTf.push(tb);
            tabSum += Math.round(this.hzTW(tb));
            i++;
         }
         var tgap:Number = Math.max(16,Math.min(28,Math.floor((W - 280 - tabSum) / Math.max(1,HZ_SET_TABS.length - 1))));
         i = 0;
         while(i < tabTf.length)
         {
            var tbx:TextField = tabTf[i] as TextField;
            var tw:Number = Math.round(this.hzTW(tbx));
            tbx.x = Math.round(tx - 2);
            if(i == this.hzSetTab) { this.hz51Hair(g,tx,HZ51_HEAD + HZ51_TABS - 2,tw,2,acc,1); }
            this.hzSetHits.push({"id":"tab" + i,"x":tx - 8,"y":HZ51_HEAD,"w":tw + 16,"h":HZ51_TABS});
            tx += tw + tgap;
            i++;
         }
         if(this.hz51Pad) { this.hzSetKey(b,g,tx + 4,ty + 2,"RB",acc,14,8,10); }
      }
      private function hz51DrawCompact(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var lay:Object = this.hz51HeadSlots();
         this.hz51DrawSearchBox(b,g,T,acc,Number(lay.fx),Number(lay.fy),Number(lay.findW));
         this.hz51DrawArrangeBtn(b,g,T,acc,W);
         var pon:Boolean = Boolean(this.hzSetPend.Compact);
         var psel:Boolean = this.hzSetHover == "compact";
         var px0:Number = Number(lay.cx);
         var py0:Number = Number(lay.fy);
         var pw:Number = Number(lay.cw);
         var ph:Number = Number(lay.h);
         g.beginFill(uint(T.txt),0.02);
         g.drawRoundRect(px0,py0,pw,ph,15,15);
         g.endFill();
         this.hz51Stroke(g,px0,py0,pw,ph,uint(T.txt),psel ? 0.28 : 0.16,15);
         this.hz51T(b,this.hzLt("COMPACT MODE (STRIPS)"),px0 + 12,py0 + 8,pw - 86,11,"bd",uint(T.lab),0.8);
         this.hz51Switch(b,g,px0 + pw - 8,py0 + ph / 2,pon,T);
         this.hzSetHits.push({"id":"compact","x":px0,"y":py0,"w":pw,"h":ph});
      }
      private function hz51DrawArrangeBtn(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var lay:Object = this.hz51HeadSlots();
         if(Number(lay.arrW) <= 0) { return; }
         var alab:String = this.hzLt(this.hzSetTab == 2 ? "ARRANGE SCANNER" : "ARRANGE CARDS");
         var aid:String = this.hzSetTab == 2 ? "arrscan" : "arrange";
         var aw:Number = Number(lay.arrW);
         var ax:Number = Number(lay.ax);
         var ay:Number = Number(lay.fy);
         var hovA:Boolean = this.hzSetHover == aid;
         g.beginFill(acc,hovA ? 1 : 0.92); g.drawRoundRect(ax,ay,aw,Number(lay.h),HZ51_BOX_R,HZ51_BOX_R); g.endFill();
         this.hz34Ring(b,ax,ay,aw,Number(lay.h),HZ51_BOX_R,acc,hovA ? 1 : 0.55,1);
         this.hz51T(b,alab,ax + aw / 2,ay + 8,aw - 8,11,"bd",uint(T.ontxt),1.2,"center");
         this.hzSetHits.push({"id":aid,"x":ax,"y":ay,"w":aw,"h":Number(lay.h)});
      }
      private function hz51DrawSearchBox(b:Sprite, g:*, T:Object, acc:uint, bx:Number, by:Number, bw:Number) : void
      {
         var on:Boolean = this.hzSetFindOn || this.hzSetHover == "findbox";
         g.beginFill(uint(T.fill),0.88);
         g.drawRoundRect(bx,by,bw,HZ51_FIND_H,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,bx,by,bw,HZ51_FIND_H,HZ51_BOX_R,on ? acc : uint(T.txt),on ? 0.70 : 0.28,1);
         var typed:Boolean = this.hz51FindOpen();
         var txt:String = this.hzSetFind.length > 0 ? this.hzSetFind : (typed ? "" : this.hzLt("Search settings..."));
         var col:uint = this.hzSetFind.length > 0 ? uint(T.txt) : uint(T.lab);
         var textW:Number = typed ? bw - 36 : bw - 18;
         this.hz51T(b,txt,bx + 10,by + 8,textW,12,"sb",col,0.2);
         this.hzSetHits.push({"id":"findbox","x":bx,"y":by,"w":bw,"h":HZ51_FIND_H});
         if(typed)
         {
            var xx:Number = bx + bw - 16;
            var xy:Number = by + HZ51_FIND_H / 2;
            g.beginFill(uint(T.mut),this.hzSetHover == "findx" ? 0.45 : 0.22);
            g.drawCircle(xx,xy,7);
            g.endFill();
            this.hz51T(b,"×",xx,xy - 6,16,11,"bd",uint(T.txt),0,"center");
            this.hzSetHits.push({"id":"findx","x":xx - 10,"y":by,"w":20,"h":HZ51_FIND_H});
         }
      }
      private function hz51Switch(b:Sprite, g:*, R:Number, cy:Number, on:Boolean, T:Object, hitId:String = null) : void
      {
         var acc:uint = uint(T.acc);
         var sw:Number = HZ51_SW_W;
         var sh:Number = HZ51_SW_H;
         var sx:Number = Math.round(R - sw);
         var sy:Number = Math.round(cy - sh / 2);
         this.hz51T(b,this.hzLt(on ? "ON" : "OFF"),sx - 4,cy - 7,28,10,"sb",on ? acc : uint(T.mut),1.5,"right");
         g.beginFill(on ? acc : uint(T.off),on ? 0.92 : 1);
         g.drawRoundRect(sx,sy,sw,sh,sh,sh);
         g.endFill();
         var kn:Number = 16;
         var kx:Number = on ? sx + sw - 3 - kn : sx + 3;
         g.beginFill(on ? uint(T.kon) : uint(T.koff),1);
         g.drawCircle(kx + kn / 2,cy,kn / 2);
         g.endFill();
         if(hitId != null && hitId.length > 0) { this.hzSetHits.push({"id":hitId,"x":sx,"y":sy,"w":sw,"h":sh}); }
      }
      private function hz51DrawSide(b:Sprite, g:*, T:Object, acc:uint, H:Number) : void
      {
         var x0:Number = 0;
         var y0:Number = HZ51_HEAD + HZ51_TABS;
         var w:Number = HZ51_SIDE_W;
         var sh:Number = H - HZ51_FOOT - y0;
         this.hz51Hair(g,w - 1,y0,1,sh,uint(T.txt),HZ51_DIV_A);
         var groups:Array = this.hz51Side(this.hzSetTab);
         var y:Number = y0 + 8;
         var gi:int = 0;
         var pi:int = 0;
         while(gi < groups.length)
         {
            var grp:Object = groups[gi];
            this.hz51T(b,this.hzLt(String(grp.g)),x0 + 16,y + 4,w - 24,HZ51_SH_PX,"bd",acc,1.4);
            this.hz51Hair(g,x0 + 16,y + 18,w - 32,1,acc,HZ51_SH_A);
            y += 22;
            var items:Array = grp.items as Array;
            var ii:int = 0;
            while(ii < items.length)
            {
               var it:Object = items[ii];
               var sel:Boolean = pi == this.hz51PageClamp(this.hzSetTab);
               var ih:Number = 44;
               if(sel)
               {
                  g.beginFill(acc,this.hzSetFocus == 1 ? 0.16 : 0.12);
                  g.drawRoundRect(x0 + 4,y + 2,w - 8,ih - 4,HZ51_BOX_R,HZ51_BOX_R);
                  g.endFill();
                  g.beginFill(acc,1); g.drawRoundRect(x0,y + 6,3,ih - 12,2,2); g.endFill();
               }
               else { this.hz51Hair(g,x0 + 16,y + ih - 1,w - 16,1,uint(T.txt),0.04); }
               this.hz51T(b,this.hzLt(String(it.l)),x0 + 16,y + 6,w - 24,11,"bd",sel ? acc : uint(T.lab),0.8);
               this.hz51T(b,this.hzLt(String(it.s)),x0 + 16,y + 22,w - 24,10,"rg",uint(T.mut),0.1);
               this.hzSetHits.push({"id":"side" + pi,"x":x0,"y":y,"w":w,"h":ih});
               if(sel) { this.hz34Ring(b,x0 + 4,y + 2,w - 8,ih - 4,HZ51_BOX_R,acc,0.55,1); }
               y += ih;
               pi++;
               ii++;
            }
            y += 6;
            gi++;
         }
      }
      // Purpose: content height of one list row, without the section-header gap.
      // Inputs: row. Outputs: pixels. Author: Moragar. Last modified: 2026-11-27.
      private function hz51ItemH(r:Object) : Number
      {
         if(r == null) { return HZ51_ROW; }
         if(r.t == "m") { return 40; }
         if(r.t == "mb") { return 88; }
         if(r.t == "mc") { return 76; }
         if(r.t == "w") { return 44; }
         if(r.t == "kg") { return this.hz51QmGridH(r.dis); }
         return HZ51_ROW;
      }
      private function hz51GroupH(list:Array, fromLi:int, y0:Number, bottom:Number) : Number
      {
         var y:Number = y0;
         var i:int = fromLi;
         while(i < list.length)
         {
            var r:Object = list[i];
            if(r.t == "m" || r.t == "mb" || r.t == "mc") { break; }
            if(i > fromLi && r.h) { break; }
            var h:Number = this.hz51ItemH(r);
            if(y + h - 4 > bottom) { break; }
            y += h;
            i++;
         }
         return Math.max(8, y - y0);
      }
      // Purpose: one rounded section panel (mock 6px, thin accent border) behind
      // the rows of DIALOGUE / OPTION TEXT / PANEL / etc. Filled before the rows
      // so labels sit on the panel. hz34Ring, never even-odd stroke.
      private function hz51FillGroup(g:*, b:Sprite, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number) : void
      {
         g.beginFill(uint(T.tile),Number(T.tia));
         g.drawRoundRect(x,y,w,h,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,x,y,w,h,HZ51_BOX_R,acc,HZ51_BOX_A,1);
      }
      private function hz51DrawList(b:Sprite, g:*, T:Object, acc:uint, rows:Array) : void
      {
         var box:Object = this.hz51ListBox();
         var x0:Number = Number(box.x);
         var right:Number = Number(box.r);
         var R:Number = right - 16;
         var bottom:Number = this.HZ_SET_H - HZ51_FOOT - 8;
         var crumbW:Number = right - x0;
         this.hz51T(b,this.hz51Crumb(this.hzSetTab, this.hz51PageClamp(this.hzSetTab)),x0,HZ_SET_TOP + 10,crumbW,10,"sb",uint(T.mut),1.2);
         var pages:Array = this.hz51Pages(this.hzSetTab);
         var pobj:Object = pages[this.hz51PageClamp(this.hzSetTab)];
         var title:String = pobj != null ? this.hzLt(String(pobj.l)) : "";
         this.hz51T(b,title,x0,HZ_SET_TOP + 24,crumbW,16,"bd",uint(T.txt),1.8);
         var list:Array = [];
         var ri:int = 0;
         while(ri < rows.length) { if(!rows[ri].pill) { list.push(rows[ri]); } ri++; }
         var y:Number = Number(box.y);
         var li:int = this.hzSetScroll;
         var lastShown:int = li - 1;
         this.hz35Tip = null;
         var bMain:Sprite = b;
         var gMain:* = g;
         var dimS:Sprite = new Sprite();
         dimS.mouseEnabled = false; dimS.mouseChildren = false;
         dimS.alpha = 0.42;
         b.addChild(dimS);
         var boxOpen:Boolean = false;
         var boxY:Number = 0;
         var boxH:Number = 0;
         var boxX:Number = x0;
         var boxW:Number = right - x0;
         var firstSec:Boolean = true;
         if(list.length == 0)
         {
            this.hz51T(b,this.hzLt("No settings in this section."),x0,y + 10,boxW,12,"sb",uint(T.mut),0.2);
         }
         while(li < list.length)
         {
            var r:Object = list[li];
            if(y + this.hzSetRowH(r) - 4 > bottom) { break; }
            var i:int = rows.indexOf(r);
            if(r.h)
            {
               boxOpen = false;
               var shY:Number = y + 10;
               var ht:TextField = this.hz51T(b,String(r.h),x0,shY + 6,Math.min(240,boxW * 0.45),HZ51_SH_PX,"bd",acc,1.4);
               var ruleX:Number = x0 + Math.round(this.hzTW(ht) + 12);
               this.hz51Hair(g,ruleX,shY + 16,Math.max(16,boxW - (ruleX - x0)),1,acc,HZ51_SH_A);
               y += HZ51_SEC;
               firstSec = false;
               boxY = y;
               if(r.t != "m" && r.t != "mb" && r.t != "mc")
               {
                  boxH = this.hz51GroupH(list,li,y,bottom);
                  this.hz51FillGroup(gMain,bMain,T,acc,boxX,boxY,boxW,boxH);
                  boxOpen = true;
               }
            }
            if(r.t == "m" || r.t == "mb")
            {
               boxOpen = false;
               var bh:Number = 40;
               try { bh = this.hz51ModBanner(b,g,y,x0,boxW,T,r,i == this.hzSetRow,i); } catch(errMb:Error) { }
               y += bh + HZ51_MOD_GAP;
               boxH = y - boxY;
               lastShown = li;
               li++;
               continue;
            }
            if(r.t == "mc")
            {
               boxOpen = false;
               var mch:Number = this.hz51DrawModCard(b,g,T,acc,x0,y,boxW,r,i);
               y += mch + HZ51_MOD_GAP;
               boxH = y - boxY;
               lastShown = li;
               li++;
               continue;
            }
            if(!boxOpen)
            {
               boxY = y;
               boxH = this.hz51GroupH(list,li,y,bottom);
               this.hz51FillGroup(gMain,bMain,T,acc,boxX,boxY,boxW,boxH);
               boxOpen = true;
            }
            if(r.t == "w")
            {
               this.hz37DrawWarn(b,g,y,right,T,String(r.l) + (r.note != undefined ? "  " + String(r.note) : ""));
               y += 44;
               boxH = y - boxY;
               lastShown = li;
               li++;
               continue;
            }
            if(r.t == "kg")
            {
               var gh:Number = this.hz51DrawQmGrid(b,g,T,acc,x0,y,R,r.dis,i,boxW);
               y += gh;
               boxH = y - boxY + 4;
               lastShown = li;
               li++;
               continue;
            }
            var hit0:int = this.hzSetHits.length;
            if(r.dis)
            {
               this.hz30Lock(g,x0 + 16,y + Math.round(HZ51_ROW / 2),11,uint(T.mut),0.95,uint(T.fill));
               b = dimS; g = dimS.graphics;
            }
            var rs:Boolean = i == this.hzSetRow && this.hzSetFocus == 0;
            var rh:Boolean = this.hzSetHover == "row" + i;
            var glow:Boolean = this.hzSetGlowK == String(r.k) && new Date().getTime() < this.hzSetGlowT;
            if(rs || rh || glow)
            {
               g.beginFill(acc,glow ? 0.18 : (rs ? HZ51_SEL_A : 0.05));
               g.drawRect(x0 + 1,y,boxW - 2,HZ51_ROW);
               g.endFill();
            }
            if(rs)
            {
               g.beginFill(acc,1);
               g.drawRoundRect(x0,y + 8,3,HZ51_ROW - 16,2,2);
               g.endFill();
            }
            var labX:Number = r.dis ? x0 + 32 : x0 + 16;
            var ctrlReserve:Number = r.t == "z" ? HZ51_Z_RESERVE : 220;
            var labW:Number = Math.max(80, boxW - ctrlReserve);
            var lb35:TextField = this.hz51T(b,String(r.l),labX,y + 6,labW,HZ51_TITLE_PX,"bd",uint(T.txt),0.8);
            this.hzSetHits.push({"id":"row" + i,"x":x0,"y":y,"w":boxW,"h":HZ51_ROW});
            var inf35:String = r.dis ? null : this.hz35InfoOf(r);
            if(inf35 != null && lb35 != null && String(r.l).length > 0)
            {
               var ix35:Number = Math.round(lb35.x + 2 + Math.min(lb35.width,this.hzTW(lb35)) + 14);
               if(ix35 + 16 > labX + labW) { ix35 = labX + labW - 16; }
               var ion35:Boolean = this.hzSetHover == "inf" + i || (rs && this.hz35Kb);
               this.hz51InfoIcon(b,g,ix35,y + 14,acc,T,ion35,i);
               if(ion35) { this.hz35Tip = {"t":inf35,"x":ix35,"y":y,"h":HZ51_ROW}; }
            }
            var help:String = r.note != undefined ? String(r.note) : "";
            if(help.length > 0)
            {
               var ht2:TextField = this.hz51T(b,help,labX,y + 24,labW,HZ51_HELP_PX,"rg",uint(T.mut),0.1);
               ht2.wordWrap = true;
               ht2.multiline = true;
               ht2.width = labW;
               ht2.height = 20;
            }
            var v:* = r.dis ? r.dv : this.hzSetPend[r.k];
            var cy:Number = y + Math.round(HZ51_ROW / 2);
            try
            {
               if(r.chip == "unavail") { this.hz51UnavailChip(b,g,R,cy,T); }
               else { this.hz51DrawCtrl(b,g,r,i,y,R,cy,v,T,acc,rh); }
            }
            catch(eCtrl:Error) { }
            if(r.t == "md")
            {
               var badge:String = String(r.badge);
               var bt:TextField = this.hz51T(b,badge,0,cy - 7,140,9,"bd",acc,0.8);
               var bw:Number = Math.round(this.hzTW(bt) + 16);
               var bx:Number = Math.round(R - bw);
               var by:Number = Math.round(cy - 10);
               bt.x = bx + 8;
               bt.y = by + 1;
               g.beginFill(acc,0.14); g.drawRoundRect(bx,by,bw,20,4,4); g.endFill();
               this.hz51Stroke(g,bx,by,bw,20,acc,0.55,4);
            }
            if(r.dis)
            {
               this.hzSetHits.splice(hit0,this.hzSetHits.length - hit0);
               b = bMain; g = gMain;
            }
            var next:Object = li + 1 < list.length ? list[li + 1] : null;
            if(next != null && !next.h)
            {
               this.hz51Hair(g,x0,y + HZ51_ROW - 1,boxW,1,uint(T.txt),HZ51_DIV_A);
            }
            y += HZ51_ROW;
            boxH = y - boxY;
            lastShown = li;
            li++;
         }
         if(this.hzSetMaxScroll > 0)
         {
            var trX:Number = right + 6;
            var trT:Number = Number(box.y);
            var trH:Number = bottom - trT - 4;
            var shown:int = Math.max(1,lastShown - this.hzSetScroll + 1);
            var tot:int = list.length;
            var thH:Number = Math.max(18,Math.round(trH * shown / tot));
            var thY:Number = Math.round(trT + (trH - thH) * this.hzSetScroll / Math.max(1,this.hzSetMaxScroll));
            gMain.beginFill(uint(T.txt),0.14); gMain.drawRoundRect(trX,trT,6,trH,3,3); gMain.endFill();
            gMain.beginFill(acc,0.9); gMain.drawRoundRect(trX,thY,6,thH,3,3); gMain.endFill();
            this.hzSetHits.push({"id":"strk","x":trX - 8,"y":trT,"w":19,"h":trH,"ty":trT,"th":trH});
         }
      }
      private function hz51DrawModCard(b:Sprite, g:*, T:Object, acc:uint, x0:Number, y:Number, boxW:Number, r:Object, idx:int) : Number
      {
         var h:Number = 76;
         var warn:uint = 0xE8B84A;
         var paused:Boolean = r.warn === true || String(r.badge).indexOf("PAUSED") == 0;
         var inst:Boolean = String(r.badge).indexOf("INSTALLED") == 0 && String(r.badge).indexOf("NOT") < 0;
         var edge:uint = paused ? warn : (inst ? acc : uint(T.line));
         g.beginFill(uint(T.tile),Number(T.tia)); g.drawRoundRect(x0,y,boxW,h,HZ51_BOX_R,HZ51_BOX_R); g.endFill();
         if(inst) { g.beginFill(acc,0.07); g.drawRoundRect(x0,y,boxW,h,HZ51_BOX_R,HZ51_BOX_R); g.endFill(); }
         if(paused) { g.beginFill(warn,0.08); g.drawRoundRect(x0,y,boxW,h,HZ51_BOX_R,HZ51_BOX_R); g.endFill(); }
         this.hz34Ring(b,x0,y,boxW,h,HZ51_BOX_R,edge,inst || paused ? 0.65 : 0.28,1);
         this.hz51T(b,this.hzLt("MODULE"),x0 + 14,y + 8,70,8,"sb",uint(T.mut),1.2);
         this.hz51T(b,String(r.l),x0 + 14,y + 22,boxW * 0.55,12,"bd",uint(T.txt),0.8);
         var body:String = r.body != undefined ? String(r.body) : "";
         if(body.length > 0) { this.hz51T(b,body,x0 + 14,y + 42,boxW * 0.55,10,"rg",uint(T.lab),0.1); }
         var badge:String = String(r.badge);
         var bt:TextField = this.hz51T(b,badge,0,y + 10,160,9,"bd",paused ? warn : acc,0.8);
         var bw:Number = Math.round(this.hzTW(bt) + 16);
         var bx:Number = Math.round(x0 + boxW - bw - 14);
         bt.x = bx + 8;
         bt.y = y + 10;
         g.beginFill(paused ? warn : acc,0.14); g.drawRoundRect(bx,y + 8,bw,20,HZ51_BOX_R,HZ51_BOX_R); g.endFill();
         this.hz34Ring(b,bx,y + 8,bw,20,HZ51_BOX_R,paused ? warn : acc,0.55,1);
         this.hzSetHits.push({"id":"row" + idx,"x":x0,"y":y,"w":boxW,"h":h});
         var swk:String = r.swk != undefined ? String(r.swk) : "";
         if(swk.length == 0 && String(r.modid) == "quickmenu") { swk = "QuickMenuHorizon"; }
         if(swk.length > 0 && inst && !paused)
         {
            var R:Number = x0 + boxW - 14;
            var cy:Number = y + 52;
            this.hz51T(b,this.hzLt("ENABLE"),R - 90,cy - 8,90,9,"sb",uint(T.lab),0.8,"right");
            this.hz51Switch(b,g,R,cy,this.hz51On(swk),T,"tog" + idx);
         }
         return h;
      }
      private function hz51UnavailChip(b:Sprite, g:*, R:Number, cy:Number, T:Object) : void
      {
         var lab:String = this.hzLt("UNAVAILABLE");
         var t:TextField = this.hz51T(b,lab,0,cy - 7,140,9,"sb",uint(T.mut),1.2);
         var w:Number = Math.round(this.hzTW(t) + 16);
         var h:Number = HZ51_BTN_H;
         var x:Number = Math.round(R - w);
         var y:Number = Math.round(cy - h / 2);
         b.removeChild(t);
         g.beginFill(uint(T.fill),0.20);
         g.drawRoundRect(x,y,w,h,6,6);
         g.endFill();
         this.hz51Stroke(g,x,y,w,h,uint(T.mut),0.55,6);
         this.hz51T(b,lab,x + w / 2,y + 4,w,9,"sb",uint(T.mut),1.2,"center");
      }
      private function hz51DrawCtrl(b:Sprite, g:*, r:Object, i:int, y:Number, R:Number, cy:Number, v:*, T:Object, acc:uint, rh:Boolean) : void
      {
         var isDef:Boolean = this.hzSetIsDef(String(r.k),v);
         var vcol:uint = isDef ? uint(T.txt) : acc;
         if(r.t == "b") { this.hz51Switch(b,g,R,cy,Boolean(v),T,"tog" + i); }
         else if(r.t == "n")
         {
            var bw:Number = 148;
            var bx:Number = R - 52 - bw;
            var fr:Number = Math.max(0,Math.min(1,(Number(v) - r.mn) / (r.mx - r.mn)));
            var vlab:String = r.st < 1 ? this.hzSetNum(Number(v)) : String(int(Math.round(Number(v))));
            if(r.pct) { vlab = String(int(Math.round(Number(v)))) + "%"; }
            this.hz51T(b,vlab,R,cy - 8,50,12,"bd",acc,0.3,"right");
            g.beginFill(uint(T.txt),0.14); g.drawRoundRect(bx,cy - 2,bw,4,2,2); g.endFill();
            if(fr > 0) { g.beginFill(acc,1); g.drawRoundRect(bx,cy - 2,Math.max(4,Math.round(bw * fr)),4,2,2); g.endFill(); }
            var kx:Number = Math.round(bx + bw * fr);
            g.beginFill(acc,1); g.drawCircle(kx,cy,8); g.endFill();
            this.hzSetHits.push({"id":"bar" + i,"x":bx,"y":cy - 10,"w":bw,"h":20,"bx":bx,"bw":bw});
         }
         else if(r.t == "z") { this.hz34ZDraw(b,g,i,y,R,v,T,acc,true); }
         else if(r.t == "h")
         {
            var hx:String = this.hzSetHexK == String(r.hex) ? this.hzSetHexBuf : String(v != undefined ? v : "");
            if(hx.indexOf("#") == 0) { hx = hx.substr(1); }
            var hexOn:Boolean = this.hzSetHexK == String(r.hex);
            var hw:Number = 118;
            var hxx:Number = R - hw;
            var hy:Number = Math.round(cy - HZ51_DD_H / 2);
            g.beginFill(uint(T.fill),0.70); g.drawRoundRect(hxx,hy,hw,HZ51_DD_H,6,6); g.endFill();
            this.hz34Ring(b,hxx,hy,hw,HZ51_DD_H,6,hexOn ? acc : uint(T.txt),hexOn ? 1 : 0.40,1);
            this.hz51T(b,"#" + hx,hxx + 10,hy + 6,hw - 16,12,"sb",uint(T.txt),0.4);
            var col:int = this.hzParseHex(hx);
            if(col >= 0) { g.beginFill(uint(col),1); g.drawRoundRect(hxx - 26,cy - 11,22,22,4,4); g.endFill(); this.hz34Ring(b,hxx - 26,cy - 11,22,22,4,uint(T.txt),0.40,1); }
            this.hzSetHits.push({"id":"hex" + i,"x":hxx,"y":hy,"w":hw,"h":HZ51_DD_H});
         }
         else if(r.t == "r" || r.t == "q" || r.t == "l" || r.t == "c" || r.t == "a" || r.t == "p")
         {
            var txt:String = "";
            var dropOpts:Array = r.opts as Array;
            if(dropOpts == null) { dropOpts = r.names as Array; }
            if(r.t == "p") { var p:Object = this.hz37Cur(); txt = p != null ? String(p.n) : "NONE"; }
            else if(r.t == "r") { txt = (dropOpts != null && dropOpts.length > 0) ? String(dropOpts[Math.max(0,Math.min(dropOpts.length - 1,this.hz29OptIdx(r,v)))]) : ""; }
            else if(r.t == "q") { txt = String(HZ_RULE_NAMES[Math.max(0,Math.min(HZ_RULE_NAMES.length - 1,int(v)))]); if(dropOpts != null && dropOpts.length > 0) { txt = String(dropOpts[Math.max(0,Math.min(dropOpts.length - 1,this.hz29OptIdx(r,v)))]); } }
            else if(r.t == "l") { txt = (r.names != undefined && (r.names as Array).length > 0) ? String((r.names as Array)[this.hzSetListIdx(r,v)]) : ""; }
            else if(r.t == "c") { txt = String(v); }
            else if(r.t == "a") { txt = (r.names != undefined && (r.names as Array).length > 0) ? String((r.names as Array)[Math.max(0,Math.min((r.names as Array).length - 1,int(v)))]) : ""; }
            var optsA:Array = r.opts as Array;
            if(optsA == null) { optsA = r.names as Array; }
            if(txt.length == 0 && optsA != null && optsA.length > 0) { txt = String(optsA[0]); }
            txt = this.hz51Exo2Text(txt);
            var ct:TextField = this.hz51T(b,txt,0,cy - 8,280,12,"bd",vcol,0.3);
            var maxTw:Number = this.hzTW(ct);
            var labs:Array = r.t == "l" && r.names != undefined ? r.names as Array : dropOpts;
            var li:int = 0;
            while(labs != null && li < labs.length)
            {
               var lab:String = this.hz51Exo2Text(String(labs[li]));
               if(lab != txt)
               {
                  ct.text = lab;
                  var twLab:Number = this.hzTW(ct);
                  if(twLab > maxTw) { maxTw = twLab; }
               }
               li++;
            }
            ct.text = txt;
            var cw:Number = Math.max(HZ51_CTRL_W,Math.round(maxTw + 36));
            if(cw > 280) { cw = 280; }
            var cx:Number = Math.round(R - cw);
            var dy:Number = Math.round(cy - HZ51_DD_H / 2);
            b.removeChild(ct);
            g.beginFill(uint(T.tile),0.92); g.drawRoundRect(cx,dy,cw,HZ51_DD_H,HZ51_BOX_R,HZ51_BOX_R); g.endFill();
            this.hz34Ring(b,cx,dy,cw,HZ51_DD_H,HZ51_BOX_R,this.hzSetDrop == i ? acc : uint(T.txt),this.hzSetDrop == i ? 0.70 : 0.22,1);
            if(r.t == "a")
            {
               var pal:Array = r.pal as Array;
               var ai:int = Math.max(0,Math.min(pal.length - 1,int(v)));
               g.beginFill(uint(pal[ai]),1); g.drawRoundRect(cx + 8,cy - 5,10,10,2,2); g.endFill();
               this.hz51T(b,txt,cx + 24,dy + 6,cw - 40,12,"bd",vcol,0.2);
            }
            else { this.hz51T(b,txt,cx + 10,dy + 6,cw - 28,12,"bd",vcol,0.2); }
            g.beginFill(uint(T.lab),0.9);
            g.moveTo(cx + cw - 16,cy - 2); g.lineTo(cx + cw - 8,cy - 2); g.lineTo(cx + cw - 12,cy + 3); g.lineTo(cx + cw - 16,cy - 2);
            g.endFill();
            this.hzSetHits.push({"id":"dd" + i,"x":cx,"y":dy,"w":cw,"h":HZ51_DD_H});
            if(this.hzSetDrop == i) { this.hzSetDropBox = {"x":cx,"y":dy,"w":cw,"h":HZ51_DD_H}; }
         }
         else if(r.t == "x" && String(r.k).indexOf("_hz37") == 0) { this.hz37DrawBtn(b,g,r,i,R,cy,rh,T); }
         else if(r.t == "x") { this.hz51Btn(b,g,R,cy,r.btn != undefined ? String(r.btn) : "OPEN",rh,T,"act" + i); }
      }
      // Purpose: extra-slot key grid (QuickMenuKey13-24). Tiles 13..SlotCount wrap by
      // Slots per Row. Lowering count only hides tiles; pending keys stay. Capture is
      // event-driven (hzQmCap*) while a chip is waiting; no idle poll.
      // Inputs: pending count/row/keys, hzQmCap*. Outputs: hits qmkN / qmclr.
      private function hz51QmCount() : int
      {
         var count:int = this.hzSetPend != null ? int(this.hzSetPend.QuickMenuSlotCount) : 24;
         if(count < 12) { count = 12; }
         if(count > 24) { count = 24; }
         return count;
      }
      private function hz51QmPer() : int
      {
         var per:int = this.hzSetPend != null ? int(this.hzSetPend.QuickMenuSlotsPerRow) : 6;
         if(per != 4 && per != 6 && per != 8) { per = 6; }
         return per;
      }
      private function hz51QmGridH(dis:Boolean) : Number
      {
         var extra:int = Math.max(0, this.hz51QmCount() - 12);
         var per:int = this.hz51QmPer();
         var lines:int = extra <= 0 ? 0 : int(Math.ceil(extra / per));
         var h:Number = HZ51_QM_HEAD + lines * (HZ51_QM_TH + HZ51_QM_GAP) + 8;
         var qmOff:Boolean = this.hz30Mod != null && this.hz30Mod["quickmenu"] !== 1;
         if(dis && !qmOff) { h += HZ51_QM_LOCK; }
         if(this.hzQmCapWarn != null && String(this.hzQmCapWarn).length > 0) { h += HZ51_QM_WARN; }
         return h;
      }
      private function hz51DrawQmGrid(b:Sprite, g:*, T:Object, acc:uint, x0:Number, y:Number, R:Number, dis:Boolean, rowIdx:int = -1, boxW:Number = 0) : Number
      {
         var start:Number = y;
         var innerW:Number = boxW > 0 ? boxW : (R - x0);
         var rs:Boolean = rowIdx >= 0 && rowIdx == this.hzSetRow && this.hzSetFocus == 0;
         var rh:Boolean = rowIdx >= 0 && this.hzSetHover == "row" + rowIdx;
         var gh:Number = this.hz51QmGridH(dis);
         if(rs || rh)
         {
            g.beginFill(acc,rs ? HZ51_SEL_A : 0.05);
            g.drawRect(x0,y,innerW,gh);
            g.endFill();
         }
         if(rowIdx >= 0) { this.hzSetHits.push({"id":"row" + rowIdx,"x":x0,"y":y,"w":innerW,"h":gh}); }
         var qmOff:Boolean = this.hz30Mod != null && this.hz30Mod["quickmenu"] !== 1;
         if(dis && !qmOff)
         {
            this.hzWT(b,this.hzLt("Turn on Extended Mode to bind keys. Saved keys are kept."),x0 + 16,y + 8,innerW - 24,12,"rg",uint(T.mut),0.1,"left",12);
            y += HZ51_QM_LOCK;
         }
         var bMain:Sprite = b;
         var gMain:* = g;
         var dimS:Sprite = null;
         if(dis)
         {
            dimS = new Sprite();
            dimS.mouseEnabled = false; dimS.mouseChildren = false;
            dimS.alpha = 0.42;
            b.addChild(dimS);
            b = dimS; g = dimS.graphics;
         }
         // One-line hint on the left, CLEAR ALL KEYS on the right. Long help lives
         // only in Setting Details so it is not drawn twice over the tiles.
         var btnW:Number = 118;
         var btnH:Number = 22;
         var btnX:Number = Math.round(x0 + innerW - btnW - 12);
         var btnY:Number = y + 8;
         this.hz51T(b,this.hzLt("Click a key chip to bind. Backspace or Delete clears. A clash is warned and ignored. Tiles are slots 13 through Slot Count."),x0 + 12,y + 8,Math.max(80,btnX - x0 - 20),10,"rg",uint(T.mut),0.1);
         g.beginFill(uint(T.fill),0.70);
         g.drawRoundRect(btnX,btnY,btnW,btnH,6,6);
         g.endFill();
         this.hz51Stroke(g,btnX,btnY,btnW,btnH,dis ? uint(T.mut) : acc,dis ? 0.35 : 0.7,6);
         this.hz51T(b,this.hzLt("CLEAR ALL KEYS"),btnX + btnW / 2,btnY + 4,btnW,9,"sb",dis ? uint(T.mut) : acc,0.8,"center");
         if(!dis) { this.hzSetHits.push({"id":"qmclr","x":btnX,"y":btnY,"w":btnW,"h":btnH}); }
         y += HZ51_QM_HEAD;
         var count:int = this.hz51QmCount();
         var per:int = this.hz51QmPer();
         var n:int = 13;
         var col:int = 0;
         var row:int = 0;
         var tw:Number = (innerW - 20 - (per - 1) * HZ51_QM_GAP) / per;
         if(tw < 72) { tw = 72; }
         var th:Number = HZ51_QM_TH;
         var clashCol:uint = HZ51_QM_CLASH;
         while(n <= count)
         {
            var k:String = "QuickMenuKey" + n;
            var raw:String = this.hzSetPend != null ? String(this.hzSetPend[k] != null ? this.hzSetPend[k] : "") : "";
            var cap:Boolean = this.hzQmCap == k;
            var kn:String = raw;
            if(cap) { kn = this.hzQmCapCand.length > 0 ? this.hzQmCapCand : this.hzLt("PRESS ANY KEY…"); }
            else if(kn.length == 0) { kn = this.hzLt("UNBOUND"); }
            var kind:String = "";
            if(cap && this.hzQmCapCand.length > 0) { kind = this.hzQmCapKind; }
            else if(!cap && raw.length > 0) { kind = this.hzQmNameKind(raw, k); }
            var isClash:Boolean = kind != null && kind.length > 0;
            var xx:Number = x0 + 10 + col * (tw + HZ51_QM_GAP);
            var yy:Number = y + row * (th + HZ51_QM_GAP);
            var on:Boolean = cap || this.hzSetHover == "qmk" + n;
            var bcol:uint = isClash ? clashCol : acc;
            g.beginFill(isClash ? clashCol : acc, cap ? 0.14 : (isClash ? 0.08 : (on ? 0.1 : 0.04)));
            g.drawRoundRect(xx,yy,tw,th,8,8);
            g.endFill();
            this.hz51Stroke(g,xx,yy,tw,th,bcol,cap || isClash ? 0.85 : 0.22,8);
            this.hz51T(b,this.hzLt("SLOT") + " " + n,xx + 8,yy + 6,tw - 16,9,"bd",acc,1.2);
            g.beginFill(uint(T.tile),0.55);
            g.drawRoundRect(xx + 8,yy + 24,14,14,3,3);
            g.endFill();
            this.hz51T(b,this.hzLt("Empty"),xx + 26,yy + 25,tw - 34,9,"rg",uint(T.mut),0.2);
            var chipH:Number = 22;
            var chipY:Number = yy + th - chipH - 8;
            var chipW:Number = tw - 16;
            var chipX:Number = xx + 8;
            g.beginFill(uint(T.tile),0.92);
            g.drawRoundRect(chipX,chipY,chipW,chipH,6,6);
            g.endFill();
            this.hz51Stroke(g,chipX,chipY,chipW,chipH,isClash ? clashCol : (cap ? acc : uint(T.line)),isClash || cap ? 0.9 : 0.4,6);
            var chipCol:uint = isClash ? clashCol : (raw.length == 0 || (cap && this.hzQmCapCand.length == 0) ? uint(T.mut) : uint(T.txt));
            this.hz51T(b,kn,chipX + chipW / 2,chipY + 4,chipW - 4,9,"bd",chipCol,0.4,"center");
            if(isClash) { this.hz51T(b,this.hzLt("CLASH"),xx + 8,yy + 42,tw - 16,8,"sb",clashCol,0.8); }
            if(!dis) { this.hzSetHits.push({"id":"qmk" + n,"x":xx,"y":yy,"w":tw,"h":th}); }
            col++;
            if(col >= per) { col = 0; row++; }
            n++;
         }
         var extraTiles:int = Math.max(0, count - 12);
         var lines:int = extraTiles <= 0 ? 0 : int(Math.ceil(extraTiles / per));
         y = start + (dis && !qmOff ? HZ51_QM_LOCK : 0) + HZ51_QM_HEAD + lines * (th + HZ51_QM_GAP) + 8;
         if(dimS != null) { b = bMain; g = gMain; }
         if(this.hzQmCapWarn != null && String(this.hzQmCapWarn).length > 0)
         {
            this.hz37DrawWarn(b,g,y,R,T,this.hzQmCapWarn);
            y += HZ51_QM_WARN;
         }
         return y - start;
      }
      private function hz51DrawRight(b:Sprite, g:*, T:Object, acc:uint, rows:Array, H:Number) : void
      {
         var px:Number = this.HZ_SET_W - HZ51_PREV_W;
         var py:Number = HZ51_HEAD + HZ51_TABS;
         var ph:Number = H - HZ51_FOOT - py;
         this.hz51Hair(g,px,py,1,ph,uint(T.txt),HZ51_DIV_A);
         var inn:Number = HZ51_PREV_W - 24;
         this.hz51T(b,this.hzLt("LIVE PREVIEW"),px + 12,py + 12,inn,HZ51_SH_PX,"bd",acc,1.4);
         var pvcX:Number = px + 12;
         var pvcY:Number = py + 30;
         var pvcW:Number = inn;
         var r:Object = this.hzSetRow >= 0 && this.hzSetRow < rows.length ? rows[this.hzSetRow] : null;
         this.hz51PvPaint(b,g,T,acc,pvcX,pvcY,pvcW,HZ51_PVC_H,r);
         var cap:String = r != null && r.l != undefined ? String(r.l) : this.hzLt("Pick a setting.");
         var pvn:TextField = this.hz51T(b,cap,px + 12,pvcY + HZ51_PVC_H + 8,inn,11,"rg",uint(T.mut),0.1);
         pvn.wordWrap = true; pvn.multiline = true; pvn.width = inn;
         var dy:Number = pvcY + HZ51_PVC_H + 36;
         var dH:Number = Math.max(72, H - HZ51_FOOT - dy - 8);
         g.beginFill(uint(T.fill),0.55);
         g.drawRoundRect(px + 8,dy - 4,inn + 8,dH,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,px + 8,dy - 4,inn + 8,dH,HZ51_BOX_R,uint(T.txt),0.14,1);
         this.hz51T(b,this.hzLt("SETTING DETAILS"),px + 12,dy,inn,HZ51_SH_PX,"bd",acc,1.4);
         this.hz51Hair(g,px + 12 + 118,dy + 12,Math.max(8,inn - 118),1,acc,HZ51_SH_A);
         var help:String = r != null ? this.hz51HelpOf(String(r.k), r) : this.hzLt("Pick a setting to see what it does.");
         var title:String = r != null && r.l != undefined ? String(r.l) : "";
         if(title.length > 0) { this.hz51T(b,title,px + 12,dy + 20,inn,HZ51_TITLE_PX,"bd",uint(T.txt),0.8); }
         var tf:TextField = this.hz51T(b,help,px + 12,dy + 40,inn,HZ51_HELP_PX,"rg",uint(T.lab),0.1);
         tf.wordWrap = true; tf.multiline = true; tf.width = inn; tf.text = help;
         // Fill the details box. hzMsglogWrap shrinks to textHeight, which
         // Scaleform often reports as one line for embedFonts fields, clipping
         // the paragraph at the bottom.
         tf.height = Math.max(48, dH - 56);
         if(r != null && this.hz51On(String(r.k)) && String(r.k).indexOf("Show") == 0 && r.k != "ShowFollowers" && r.k != "ShowLocations" && r.k != "ShowShip" && r.k != "ShowEnemies" && r.k != "ShowPlayerMarker" && r.k != "ShowSpeaker" && r.k != "ShowTarget")
         {
            var ruleK:String = String(r.k).substr(4) + "Rule";
            if(r.k == "ShowAmmo") { ruleK = "AmmoRule"; }
            if(this.hzSetPend[ruleK] != undefined && int(this.hzSetPend[ruleK]) != 0)
            {
               var hint:String = "This card stays on. It only appears when Show when says so. That is not a fault.";
               this.hz51T(b,hint,px + 12,dy + 40 + tf.textHeight + 10,inn,11,"rg",uint(T.mut),0.1);
            }
         }
      }
      // Purpose: change-driven Live Preview while F11 is open. Dispatches on the
      // selected row key (not the page group). Planet / character reuse the live
      // card renderers (hzPpDrawIcon, character name/LV/XP). CANCEL reverts
      // because paint reads hzSetPend. No per-frame timer. Author: Moragar.
      // Last modified: 2026-11-27.
      private function hz51PvPaint(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, r:Object) : void
      {
         g.beginFill(uint(T.fill),0.80);
         g.drawRoundRect(x,y,w,h,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,x,y,w,h,HZ51_BOX_R,uint(T.txt),0.14,1);
         var k:String = r != null && r.k != undefined ? String(r.k) : "";
         var p:Object = this.hzSetPend;
         var kind:String = this.hz51PvKind(k);
         if(kind == "text") { this.hz51PvText(b,T,acc,x,y,w,h,r,k); return; }
         if(kind == "planet") { this.hz51PvPlanet(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "character") { this.hz51PvCharacter(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "vitals") { this.hz51PvVitals(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "compass") { this.hz51PvCompass(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "watch") { this.hz51PvWatch(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "target" || kind == "crosshair") { this.hz51PvTarget(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "qm") { this.hz51PvQm(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "toast" || kind == "xp") { this.hz51PvToast(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "speaker" || kind == "subtitle") { this.hz51PvSubtitle(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "dialogue") { this.hz51PvDialogue(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "scanner") { this.hz51PvScanner(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "theme") { this.hz51PvTheme(b,g,T,acc,x,y,w,h,p,k); return; }
         if(kind == "module") { this.hz51PvModule(b,g,T,acc,x,y,w,h,r); return; }
         if(kind == "preset")
         {
            var pr:Object = this.hz37Cur();
            this.hz51T(b,pr != null ? String(pr.n) : this.hzLt("NO PRESET"),x + w / 2,y + h / 2 - 8,w - 16,11,"bd",acc,0.6,"center");
            this.hz51T(b,this.hzLt("Pending look · CANCEL reverts"),x + w / 2,y + h / 2 + 8,w - 16,9,"rg",uint(T.mut),0.2,"center");
            return;
         }
         this.hz51PvCard(b,g,T,acc,x,y,w,h,p,k);
      }
      // Purpose: pick the Live Preview painter for one settings row. Page group
      // is not used; two rows on the same page can show different minis.
      // Inputs: row key. Outputs: kind string. Author: Moragar. Last modified: 2026-11-27.
      private function hz51PvKind(k:String) : String
      {
         if(k == null || k.length == 0) { return "text"; }
         if(k.indexOf("_goto") == 0 || k == "_arrange" || k == "_empty" || k == "_diagoff" || k == "_dirinst" || k == "_cmpok" || k.indexOf("_own") == 0 || k.indexOf("_hz31") == 0 || k.indexOf("_modban") == 0) { return "text"; }
         if(k.indexOf("_hz37") == 0) { return (k == "_hz37pick" || k == "_hz37save") ? "preset" : "text"; }
         if(k.indexOf("_mod_") == 0) { return "module"; }
         if(k.indexOf("_ml") == 0 || k == "_msglog" || k == "Record" || k == "Persist" || k == "HistorySize" || k == "SettingsKey" || k == "Language" || k == "_l10nGame" || k == "StartupIntro" || k == "Debug" || k.indexOf("Perf") == 0) { return "text"; }
         if(k.indexOf("_hz40") == 0 || k.indexOf("_hz41") == 0 || k == "_hz42scrst" || k == "_qmclear" || k == "_qmkeys") { return "text"; }
         if(k == "SubAutoPause" || k == "DlgAutoPause" || k == "DlgInputDelay" || k == "DlgRolloverSound" || k == "DlgMarkers" || k == "MissionToastSound" || k == "DlgHoverScroll" || k == "DlgWheel" || k == "DlgNumberKeys" || k == "DlgSelectHint" || k == "DlgQuickPickHint") { return "text"; }
         if(k == "ShowPlanet" || k.indexOf("Planet") == 0 || k == "HazardAlert" || k == "TimeDisplay" || k == "ClockFormat" || k == "TempUnit") { return "planet"; }
         if(k == "ShowCharacter" || k.indexOf("Character") == 0) { return "character"; }
         if(k.indexOf("Watch") == 0) { return "watch"; }
         if(k == "ShowVitals" || k.indexOf("Vitals") == 0 || k == "AutoCenterVitals" || k == "RegenSliver" || k == "SmoothBars" || k == "EdgePulse") { return "vitals"; }
         if(k == "ShowJetpack" || k.indexOf("Jetpack") == 0) { return "jetpack"; }
         if(k == "ShowAfflictions" || k.indexOf("Afflict") == 0) { return "affliction"; }
         if(k.indexOf("Hazard") == 0) { return "hazard"; }
         if(k == "ShowAmmo" || k.indexOf("Equipment") == 0 || k == "AmmoRule" || k == "EquipmentExtras") { return "equipment"; }
         if(k.indexOf("Enemy") == 0) { return "enemy"; }
         if(k.indexOf("Stealth") == 0) { return "stealth"; }
         if(k.indexOf("Crosshair") == 0 || k == "HitMarkers" || k == "DamageNumbers" || k == "DirectionRing" || k.indexOf("Scope") == 0) { return "crosshair"; }
         if(k == "ShowCompass" || k.indexOf("Compass") == 0 || k == "CompassMarkers" || k == "ShowFollowers" || k == "FollowerColor" || k == "ShowLocations" || k == "ShowShip" || k == "ShowEnemies" || k == "ShowPlayerMarker") { return "compass"; }
         if(k == "ShowQuests" || k.indexOf("Quests") == 0) { return "quests"; }
         if(k == "ShowTarget" || k == "NameHover" || k == "HoverScale" || k == "TargetAnchor" || k == "TargetShowValue" || k == "ContainerScale" || k == "ContainerOpacity" || k == "ObjectRing") { return "target"; }
         if(k == "VehicleExitPill") { return "vehicle"; }
         if(k.indexOf("QuickMenu") == 0) { return "qm"; }
         if(k.indexOf("XpToast") == 0) { return "xp"; }
         if(k.indexOf("MissionToast") == 0 || k == "ReactionCard" || k == "GameCardTitle") { return "toast"; }
         if(k == "ShowSpeaker" || k == "SpeakerCard" || k == "SpkColIdx") { return "speaker"; }
         if(k == "Subtitles" || k.indexOf("Sub") == 0 || k == "TxtColIdx" || k == "KeepInDialogue" || k == "FixedInDialogue") { return "subtitle"; }
         if(k == "Dialogue" || k.indexOf("Dlg") == 0) { return "dialogue"; }
         if(k.indexOf("Scan") == 0 || (k.indexOf("Hide") == 0 && k.indexOf("Scan") > 0) || k == "DimTraitPopupDuringBioscan" || k == "TraitPopupDim" || k == "HideQuestPopupsWhileScanning" || k == "HideMainHudWhileScanning" || k == "HideWatchWhileScanning") { return "scanner"; }
         if(k == "AccentColor" || k == "AccentHex" || k == "CardColor" || k == "CardHex" || k == "CardOpacity" || k == "CardBgOpacity" || k == "CardShadow" || k == "FontFace" || k == "TextScale" || k == "TextTone" || k == "HeaderStyle" || k == "TextShadow" || k == "HudScale" || k == "Margin" || k == "ScreenHeight" || k == "FadeCards" || k == "CombatDim" || k == "DimOpacity" || k == "SettingsOpacity" || k == "CompactScale" || k == "Compact") { return "theme"; }
         return "card";
      }
      private function hz51PvText(b:Sprite, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, r:Object, k:String) : void
      {
         var help:String = this.hz51HelpOf(k, r);
         if(help == null || help.length == 0) { help = r != null && r.note != undefined ? String(r.note) : "This setting has no separate HUD picture. The details below describe what it does."; }
         this.hz51T(b,this.hzLt("SETTING DETAILS"),x + 10,y + 10,w - 20,8,"sb",acc,0.8);
         var tf:TextField = this.hz51T(b,help,x + 10,y + 26,w - 20,10,"rg",uint(T.lab),0.1);
         tf.wordWrap = true; tf.multiline = true; tf.width = w - 20;
         this.hzMsglogWrap(tf,w - 20,h - 36);
      }
      // Purpose: planet-card Live Preview using the live disc renderer (hzPpDrawIcon)
      // plus pending on/off, compact, scale, details, and hazard. Same painter the
      // old F11 used for STYLE. Inputs: pending values + selected key.
      private function hz51PvPlanet(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(k == "ShowPlanet" && !this.hz51On("ShowPlanet")) { this.hz51PvOff(b,T,x,y,w,h,"Planet card hidden"); return; }
         if(!this.hz51On("ShowPlanet") && (k.indexOf("Planet") == 0 || k == "HazardAlert") && k != "ShowPlanet") { this.hz51PvOff(b,T,x,y,w,h,"Planet card hidden"); return; }
         var compact:Boolean = p != null && (int(p.PlanetCompact) == 1 || (k == "PlanetCompact" && int(p.PlanetCompact) == 1));
         if(p != null && int(p.PlanetCompact) < 0) { compact = Boolean(p.Compact); }
         var sc:Number = p != null && !isNaN(Number(p.PlanetScale)) ? Number(p.PlanetScale) : 1;
         if(isNaN(sc) || sc <= 0) { sc = 1; }
         sc = Math.max(0.55, Math.min(1.2, sc));
         var cw:Number = (w - 16) * (compact ? 0.82 : 1);
         var ch:Number = (compact ? 36 : 64) * sc;
         var cx:Number = x + 8;
         var cy:Number = y + 12;
         g.beginFill(uint(T.tile),0.92);
         g.drawRoundRect(cx,cy,cw,ch,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,cx,cy,cw,ch,HZ51_BOX_R,acc,0.7,1);
         var disc:Sprite = new Sprite();
         disc.x = cx + (compact ? 16 : 22);
         disc.y = cy + ch / 2;
         disc.scaleX = disc.scaleY = compact ? 0.32 : 0.48;
         b.addChild(disc);
         try { this.hzPpDrawIcon(disc); } catch(ePvP:Error) {
            var dg:* = disc.graphics;
            dg.beginFill(acc,0.9); dg.drawCircle(0,0,30); dg.endFill();
         }
         var nm:String = "--";
         try { if(this.hzPpName != null && String(this.hzPpName.text).length > 0) { nm = String(this.hzPpName.text); } } catch(ePvN:Error) { }
         this.hz51T(b,nm,cx + (compact ? 30 : 48),cy + (compact ? 10 : 8),cw - 56,compact ? 9 : 11,"bd",uint(T.txt),0.4);
         var detOn:Boolean = p == null || p.PlanetDetails === undefined || Boolean(p.PlanetDetails);
         if(k == "PlanetDetails") { detOn = this.hz51On("PlanetDetails"); }
         if(!compact && detOn) { this.hz51T(b,"Temperate  ·  1.0 G",cx + 48,cy + 26,cw - 56,8,"rg",uint(T.mut),0.2); }
         var hazOn:Boolean = this.hz51On("HazardAlert");
         if(hazOn) { this.hz51T(b,"HAZARD",cx + cw - 52,cy + 8,48,8,"sb",acc,0.8); }
         if(k == "TimeDisplay" || k == "ClockFormat") { this.hz51T(b,k == "ClockFormat" ? "14:32" : "PLANET TIME",cx + 48,cy + ch - 16,cw - 56,8,"sb",acc,0.6); }
         if(k == "TempUnit") { this.hz51T(b,p != null && int(p.TempUnit) == 1 ? "68 F" : "20 C",cx + 48,cy + ch - 16,cw - 56,8,"sb",acc,0.6); }
      }
      // Purpose: character-card Live Preview from the live character fields
      // (name, LV, XP, credits, mass) the same way the old F11 cloned the planet
      // card. Compact / scale / show-for follow pending values.
      private function hz51PvCharacter(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(!this.hz51On("ShowCharacter") && k != "ShowCharacter") { this.hz51PvOff(b,T,x,y,w,h,"Character card hidden"); return; }
         if(k == "ShowCharacter" && !this.hz51On("ShowCharacter")) { this.hz51PvOff(b,T,x,y,w,h,"Character card hidden"); return; }
         var compact:Boolean = p != null && int(p.CharacterCompact) == 1;
         if(p != null && int(p.CharacterCompact) < 0) { compact = Boolean(p.Compact); }
         var sc:Number = p != null && !isNaN(Number(p.CharacterScale)) ? Number(p.CharacterScale) : 1;
         if(isNaN(sc) || sc <= 0) { sc = 1; }
         sc = Math.max(0.6, Math.min(1.2, sc));
         var nm:String = "Character";
         try { if(this.hz26Name != null && String(this.hz26Name).length > 0) { nm = String(this.hz26Name); } } catch(ePvC:Error) { }
         var lv:String = "LV 34";
         try { if(this.hz26Lv >= 0) { lv = "LV " + String(this.hz26Lv); } } catch(ePvL:Error) { }
         var cw:Number = (w - 16) * sc;
         var ch:Number = (compact ? 28 : 58) * Math.max(0.85, sc);
         var cx:Number = x + 8;
         var cy:Number = y + 14;
         g.beginFill(uint(T.tile),0.92);
         g.drawRoundRect(cx,cy,cw,ch,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,cx,cy,cw,ch,HZ51_BOX_R,acc,0.7,1);
         this.hz51T(b,compact ? lv : nm,cx + 8,cy + 6,cw - 16,compact ? 9 : 11,"bd",uint(T.txt),0.4);
         if(!compact)
         {
            this.hz51T(b,lv,cx + 8,cy + 22,60,8,"sb",acc,0.6);
            g.beginFill(uint(T.fill),0.9); g.drawRoundRect(cx + 70,cy + 26,cw - 86,5,3,3); g.endFill();
            g.beginFill(acc,1); g.drawRoundRect(cx + 70,cy + 26,Math.max(8,(cw - 86) * 0.62),5,3,3); g.endFill();
            this.hz51T(b,"48,320 CR",cx + 8,cy + 38,cw * 0.5,8,"rg",uint(T.lab),0.2);
            this.hz51T(b,"142 / 175 KG",cx + cw * 0.5,cy + 38,cw * 0.5 - 8,8,"rg",uint(T.lab),0.2);
         }
         else
         {
            g.beginFill(acc,1); g.drawRoundRect(cx + 52,cy + 12,Math.max(24,cw * 0.35),4,2,2); g.endFill();
         }
         if(k == "CharacterShowSeconds")
         {
            var secs:Number = p != null && !isNaN(Number(p.CharacterShowSeconds)) ? Number(p.CharacterShowSeconds) : 8;
            this.hz51T(b,"SHOWS " + String(int(secs)) + "s",cx,cy + ch + 4,cw,8,"sb",acc,0.8);
         }
      }
      private function hz51PvVitals(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(k == "ShowVitals" && !this.hz51On("ShowVitals")) { this.hz51PvOff(b,T,x,y,w,h,"Vitals hidden"); return; }
         if(!this.hz51On("ShowVitals") && k.indexOf("Vitals") == 0 && k != "ShowVitals") { this.hz51PvOff(b,T,x,y,w,h,"Vitals hidden"); return; }
         var horiz:Boolean = p != null && int(p.VitalsLayout) == 1;
         var compact:Boolean = p != null && int(p.VitalsBars) == 1;
         var bx:Number = x + 12;
         var by:Number = y + 18;
         var bw:Number = w - 24;
         var bh:Number = compact ? 6 : 10;
         if(horiz)
         {
            g.beginFill(acc,0.85); g.drawRoundRect(bx,by,bw * 0.46,bh,bh,bh); g.endFill();
            g.beginFill(uint(T.lab),0.7); g.drawRoundRect(bx + bw * 0.52,by,bw * 0.46,bh,bh,bh); g.endFill();
            this.hz51T(b,"HP",bx,by + 14,40,8,"sb",acc,0.6);
            this.hz51T(b,"O2",bx + bw * 0.52,by + 14,40,8,"sb",uint(T.lab),0.6);
         }
         else
         {
            g.beginFill(acc,0.85); g.drawRoundRect(bx,by,bw,bh,bh,bh); g.endFill();
            g.beginFill(uint(T.lab),0.7); g.drawRoundRect(bx,by + bh + 10,bw * 0.72,bh,bh,bh); g.endFill();
            this.hz51T(b,"HEALTH",bx,by + bh + 2,bw,8,"sb",acc,0.6);
            this.hz51T(b,"O2",bx,by + bh * 2 + 12,bw,8,"sb",uint(T.lab),0.6);
         }
         if(k == "RegenSliver" && this.hz51On("RegenSliver")) { g.beginFill(0x7DFFB3,0.9); g.drawRect(bx + bw * 0.62,by,3,bh); g.endFill(); }
         if(k == "EdgePulse" && this.hz51On("EdgePulse")) { this.hz34Ring(b,x + 4,y + 4,w - 8,h - 8,HZ51_BOX_R,0xC45C5C,0.55,2); }
         if(k == "SmoothBars") { this.hz51T(b,this.hz51On("SmoothBars") ? "SMOOTH FILL" : "SNAP FILL",x,y + h - 18,w,8,"sb",acc,0.8); }
      }
      private function hz51PvCompass(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(k == "ShowCompass" && !this.hz51On("ShowCompass")) { this.hz51PvOff(b,T,x,y,w,h,"Compass hidden"); return; }
         if(!this.hz51On("ShowCompass") && k != "ShowCompass") { this.hz51PvOff(b,T,x,y,w,h,"Compass hidden"); return; }
         var bx:Number = x + 10;
         var by:Number = y + h / 2 - 10;
         var bw:Number = w - 20;
         g.beginFill(uint(T.tile),0.9); g.drawRoundRect(bx,by,bw,22,11,11); g.endFill();
         this.hz34Ring(b,bx,by,bw,22,11,acc,0.55,1);
         this.hz51T(b,"W",bx + 8,by + 5,16,9,"sb",uint(T.mut),0.4);
         this.hz51T(b,"N",bx + bw / 2 - 6,by + 4,16,10,"bd",acc,0.4);
         this.hz51T(b,"E",bx + bw - 20,by + 5,16,9,"sb",uint(T.mut),0.4);
         if(!this.hz51On("CompassMarkers") && k != "CompassMarkers") { this.hz51T(b,"MARKERS OFF",bx,by + 26,bw,8,"sb",uint(T.mut),0.8); return; }
         if(k == "CompassMarkers" && !this.hz51On("CompassMarkers")) { this.hz51T(b,"MARKERS OFF",bx,by + 26,bw,8,"sb",uint(T.mut),0.8); return; }
         var folCol:uint = acc;
         try { if(p != null && p.FollowerColor != undefined) { var pal:Array = HZ_FOL_PAL; var fi:int = int(p.FollowerColor); if(pal != null && fi >= 0 && fi < pal.length) { folCol = uint(pal[fi]); } } } catch(eFol:Error) { }
         if(this.hz51On("ShowFollowers") || k == "ShowFollowers" || k == "FollowerColor")
         {
            if(k == "ShowFollowers" && !this.hz51On("ShowFollowers")) { }
            else if(this.hz51On("ShowFollowers") || k == "FollowerColor") { g.beginFill(folCol,1); g.drawCircle(bx + bw * 0.38,by + 11,3); g.endFill(); }
         }
         if(this.hz51On("ShowLocations") || (k == "ShowLocations" && this.hz51On("ShowLocations"))) { g.beginFill(uint(T.txt),0.9); g.drawCircle(bx + bw * 0.62,by + 11,2.5); g.endFill(); }
         if(this.hz51On("ShowShip") || (k == "ShowShip" && this.hz51On("ShowShip"))) { g.beginFill(acc,0.9); g.drawRoundRect(bx + bw * 0.72,by + 8,8,6,2,2); g.endFill(); }
         if(this.hz51On("ShowEnemies") || (k == "ShowEnemies" && this.hz51On("ShowEnemies"))) { g.beginFill(0xC45C5C,1); g.drawCircle(bx + bw * 0.28,by + 11,2.5); g.endFill(); }
         if(this.hz51On("ShowPlayerMarker") || (k == "ShowPlayerMarker" && this.hz51On("ShowPlayerMarker"))) { g.beginFill(acc,1); g.moveTo(bx + bw * 0.5,by + 4); g.lineTo(bx + bw * 0.5 + 4,by + 12); g.lineTo(bx + bw * 0.5 - 4,by + 12); g.lineTo(bx + bw * 0.5,by + 4); g.endFill(); }
      }
      private function hz51PvWatch(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         var ws:int = p != null ? int(p.WatchStyle) : 0;
         if(ws == 0) { this.hz51PvOff(b,T,x,y,w,h,"Watch off"); return; }
         var cx:Number = x + w / 2;
         var cy:Number = y + h / 2 - 4;
         var lab:String = ws == 4 ? "ANALOG" : (ws == 3 ? "DIGITAL" : (ws == 2 ? "VANILLA + HORIZON" : "VANILLA"));
         if(ws == 4)
         {
            g.lineStyle(2,acc,0.9); g.drawCircle(cx,cy,22); g.lineStyle();
            g.beginFill(acc,1); g.drawRect(cx - 1,cy - 14,2,14); g.endFill();
            g.beginFill(uint(T.txt),0.8); g.drawRect(cx,cy - 1,12,2); g.endFill();
         }
         else
         {
            g.beginFill(uint(T.tile),0.92); g.drawRoundRect(cx - 40,cy - 16,80,32,8,8); g.endFill();
            this.hz34Ring(b,cx - 40,cy - 16,80,32,8,acc,0.7,1);
            this.hz51T(b,ws >= 3 ? "14:32" : "WATCH",cx,cy - 6,70,12,"bd",uint(T.txt),0.4,"center");
         }
         this.hz51T(b,lab,x,y + h - 18,w,8,"sb",acc,0.8);
      }
      private function hz51PvTarget(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         var cx:Number = x + w / 2;
         var cy:Number = y + 28;
         var style:int = p != null ? int(p.CrosshairStyle) : 1;
         if(k == "CrosshairRule" && p != null && int(p.CrosshairRule) == 2) { this.hz51PvOff(b,T,x,y,w,h,"Crosshair off"); return; }
         if(style == 3 && (k.indexOf("Crosshair") == 0)) { this.hz51T(b,"NONE",cx,cy,w - 16,11,"bd",uint(T.mut),0.6,"center"); }
         else if(style == 2)
         {
            g.beginFill(acc,1); g.drawRect(cx - 8,cy - 1,6,2); g.drawRect(cx + 2,cy - 1,6,2); g.drawRect(cx - 1,cy - 8,2,6); g.drawRect(cx - 1,cy + 2,2,6); g.endFill();
         }
         else if(style == 1)
         {
            g.beginFill(acc,1); g.drawCircle(cx,cy,2.5); g.endFill();
         }
         else
         {
            g.lineStyle(1,acc,0.8); g.moveTo(cx - 8,cy); g.lineTo(cx + 8,cy); g.moveTo(cx,cy - 8); g.lineTo(cx,cy + 8); g.lineStyle();
         }
         if(k == "HitMarkers" && this.hz51On("HitMarkers")) { this.hz51T(b,"X",cx + 14,cy - 10,16,10,"bd",acc,0.4); }
         if(k == "DamageNumbers" && this.hz51On("DamageNumbers")) { this.hz51T(b,"-12",cx + 18,cy - 4,28,9,"sb",0xC45C5C,0.4); }
         if(k == "DirectionRing" && this.hz51On("DirectionRing")) { g.lineStyle(2,0xC45C5C,0.8); g.drawCircle(cx,cy,18); g.lineStyle(); }
         if(k.indexOf("Scope") == 0)
         {
            g.beginFill(uint(T.tile),0.9); g.drawRoundRect(x + 16,y + h - 40,w - 32,22,6,6); g.endFill();
            this.hz51T(b,this.hz51On("ScopeHoldBreathChip") ? "HOLD BREATH" : "CHIP OFF",x,y + h - 36,w,9,"sb",acc,0.6);
            return;
         }
         var hoverOn:Boolean = this.hz51On("ShowTarget");
         if(k == "ShowTarget" && !hoverOn) { this.hz51PvOff(b,T,x,y,w,h,"Target card hidden"); return; }
         if(k == "ObjectRing")
         {
            var ring:int = p != null ? int(p.ObjectRing) : 0;
            if(ring == 0) { this.hz51T(b,"RING OFF",x,y + h - 18,w,8,"sb",uint(T.mut),0.8); }
            else { g.lineStyle(1,acc,0.7); g.drawCircle(cx,cy,22); g.lineStyle(); this.hz51T(b,ring == 1 ? "CONTAINERS" : "VANILLA",x,y + h - 18,w,8,"sb",acc,0.8); }
            return;
         }
         if(hoverOn || k == "NameHover" || k == "HoverScale" || k == "TargetShowValue" || k == "ContainerScale" || k == "ContainerOpacity")
         {
            var hs:Number = p != null && !isNaN(Number(p.HoverScale)) ? Number(p.HoverScale) : 1;
            if(k == "ContainerScale" && p != null && !isNaN(Number(p.ContainerScale))) { hs = Number(p.ContainerScale); }
            if(isNaN(hs) || hs <= 0) { hs = 1; }
            hs = Math.max(0.6, Math.min(1.3, hs));
            var tw:Number = 96 * hs;
            var th:Number = (p != null && int(p.NameHover) == 1 ? 36 : 20) * hs;
            var tx:Number = cx - tw / 2;
            var ty:Number = cy + 18;
            var opa:Number = p != null && !isNaN(Number(p.ContainerOpacity)) ? Number(p.ContainerOpacity) : 1;
            if(isNaN(opa) || opa <= 0) { opa = 1; }
            if(opa > 1) { opa = 1; }
            g.beginFill(uint(T.tile),0.55 + 0.4 * opa); g.drawRoundRect(tx,ty,tw,th,6,6); g.endFill();
            this.hz34Ring(b,tx,ty,tw,th,6,acc,0.6,1);
            this.hz51T(b,"LOCKBOX",tx + 6,ty + 3,tw - 12,9,"sb",uint(T.txt),0.4);
            if(p != null && int(p.NameHover) == 1 && (k == "NameHover" || this.hz51On("TargetShowValue") || k == "TargetShowValue")) { this.hz51T(b,"12  ·  0.4 KG",tx + 6,ty + 18,tw - 12,8,"rg",uint(T.mut),0.2); }
         }
      }
      private function hz51PvQm(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(k == "QuickMenuHorizon" && !this.hz51On("QuickMenuHorizon")) { this.hz51PvOff(b,T,x,y,w,h,"Game favorites menu"); return; }
         var per:int = p != null ? int(p.QuickMenuSlotsPerRow) : 6;
         if(per < 4) { per = 6; }
         var count:int = p != null ? int(p.QuickMenuSlotCount) : 12;
         if(count < 4) { count = 12; }
         if(count > 12) { count = 12; }
         var ext:Boolean = this.hz51On("QuickMenuExtended");
         var n:int = ext ? Math.min(12, count) : 8;
         var gap:Number = 4;
         var tw:Number = Math.max(10, (w - 20 - (per - 1) * gap) / per);
         var i:int = 0;
         while(i < n)
         {
            var col:int = i % per;
            var row:int = int(i / per);
            var xx:Number = x + 10 + col * (tw + gap);
            var yy:Number = y + 16 + row * (tw + gap);
            g.beginFill(i < 4 ? acc : uint(T.tile),i < 4 ? 0.22 : 0.7);
            g.drawRoundRect(xx,yy,tw,tw,3,3);
            g.endFill();
            i++;
         }
         if(k == "QuickMenuExtPanelOpacity" || k == "QuickMenuExtSlotScale") { this.hz51T(b,k == "QuickMenuExtSlotScale" ? "SLOT SCALE" : "PANEL OPACITY",x,y + h - 16,w,8,"sb",acc,0.8); }
      }
      private function hz51PvToast(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         var on:Boolean = true;
         if(k.indexOf("XpToast") == 0) { on = this.hz51On("XpToast"); if(k == "XpToast" && !on) { this.hz51PvOff(b,T,x,y,w,h,"XP toast hidden"); return; } }
         if(k.indexOf("MissionToast") == 0) { on = this.hz51On("MissionToast"); if(k == "MissionToast" && !on) { this.hz51PvOff(b,T,x,y,w,h,"Game quest banner"); return; } }
         if(k == "ReactionCard" && !this.hz51On("ReactionCard")) { this.hz51PvOff(b,T,x,y,w,h,"Game reaction line"); return; }
         var lab:String = k.indexOf("Xp") == 0 ? "+ 25 XP" : (k == "ReactionCard" ? "ANDREJA LIKED THAT" : "NEW MISSION");
         var tw:Number = w - 28;
         var th:Number = 28;
         var tx:Number = x + 14;
         var ty:Number = y + h / 2 - 14;
         g.beginFill(uint(T.tile),0.92); g.drawRoundRect(tx,ty,tw,th,HZ51_BOX_R,HZ51_BOX_R); g.endFill();
         this.hz34Ring(b,tx,ty,tw,th,HZ51_BOX_R,acc,0.7,1);
         this.hz51T(b,lab,tx + 10,ty + 8,tw - 20,10,"bd",uint(T.txt),0.4);
         if(k == "GameCardTitle")
         {
            var gt:int = p != null ? int(p.GameCardTitle) : 0;
            this.hz51T(b,gt == 1 ? "DATA" : (gt == 2 ? "MISC" : "NO LABEL"),tx + 10,ty - 14,tw - 20,8,"sb",acc,0.8);
         }
      }
      private function hz51PvOff(b:Sprite, T:Object, x:Number, y:Number, w:Number, h:Number, why:String) : void
      {
         this.hz51T(b,"OFF",x + w / 2,y + h / 2 - 8,w - 16,12,"bd",uint(T.mut),1.2,"center");
         this.hz51T(b,why,x + w / 2,y + h / 2 + 8,w - 16,10,"rg",uint(T.mut),0.2,"center");
      }
      private function hz51PvDialogue(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(k == "Dialogue" && !this.hz51On("Dialogue")) { this.hz51PvOff(b,T,x,y,w,h,"Game dialogue menu"); return; }
         var vis:int = p != null ? int(p.DlgVisible) : 4;
         if(vis < 1) { vis = 4; }
         if(vis > 6) { vis = 6; }
         var more:Boolean = p == null || p.DlgMoreHint === undefined || Boolean(p.DlgMoreHint);
         var said:int = p != null ? int(p.DlgSaidStyle) : 0;
         var bgA:Number = p != null ? Number(p.DlgBgOpacity) : 80;
         if(bgA > 1) { bgA = bgA / 100; }
         if(isNaN(bgA)) { bgA = 0.8; }
         var px:Number = x + 8;
         var py:Number = y + 10;
         var pw:Number = w - 16;
         var ph:Number = h - 18;
         g.beginFill(uint(T.tile),Math.max(0.35, bgA));
         g.drawRoundRect(px,py,pw,ph,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,px,py,pw,ph,HZ51_BOX_R,acc,0.55,1);
         var fs:Number = 9;
         if(p != null && !isNaN(Number(p.DlgTextSize)) && Number(p.DlgTextSize) > 0) { fs = Math.max(8, Math.min(12, Number(p.DlgTextSize) * 0.55)); }
         var lines:Array = ["Ask about the job.","I can pay.","Walk away."];
         var n:int = Math.min(vis, lines.length);
         var i:int = 0;
         while(i < n)
         {
            var ly:Number = py + 8 + i * 22;
            var dim:Boolean = said == 0 && i == 2;
            var hide:Boolean = said == 1 && i == 2;
            if(!hide)
            {
               g.beginFill(i == 0 ? acc : uint(T.txt),i == 0 ? 0.18 : 0.06);
               g.drawRoundRect(px + 6,ly,pw - 12,18,4,4);
               g.endFill();
               this.hz51T(b,String(i + 1) + "  " + String(lines[i]),px + 12,ly + 3,pw - 28,fs,"rg",dim ? uint(T.mut) : uint(T.txt),0.2);
               if(said == 2 && i == 2) { this.hz51T(b,"SAID",px + pw - 40,ly + 4,32,8,"sb",uint(T.mut),0.8); }
            }
            i++;
         }
         if(more) { this.hz51T(b,(6 - n) + " MORE",px + pw / 2,py + ph - 16,pw - 12,8,"sb",acc,0.8,"center"); }
         if(k == "DlgPersuadeStyle" || k == "DlgPersuadeColor" || k == "DlgPersuasionMeter")
         {
            var psStyle:int = p != null ? int(p.DlgPersuadeStyle) : 0;
            var pcol:uint = acc;
            try { if(p != null && p.DlgPersuadeColor != undefined) { var ppal:Array = HZ_ACCENTS; var pi2:int = int(p.DlgPersuadeColor); if(ppal != null && pi2 >= 0 && pi2 < ppal.length) { pcol = uint(ppal[pi2]); } } } catch(ePrs:Error) { }
            if(psStyle == 0) { g.beginFill(pcol,0.25); g.drawRoundRect(px + pw - 56,py + 10,44,14,4,4); g.endFill(); this.hz51T(b,"PERSUADE",px + pw - 54,py + 12,42,8,"sb",pcol,0.4); }
            else if(psStyle == 1) { this.hz51T(b,"Persuade",px + pw - 54,py + 12,50,8,"sb",pcol,0.4); }
            if(this.hz51On("DlgPersuasionMeter") || k == "DlgPersuasionMeter")
            {
               if(k != "DlgPersuasionMeter" || this.hz51On("DlgPersuasionMeter"))
               {
                  g.beginFill(uint(T.fill),0.9); g.drawRoundRect(px + 8,py + ph - 10,pw - 16,4,2,2); g.endFill();
                  g.beginFill(pcol,1); g.drawRoundRect(px + 8,py + ph - 10,(pw - 16) * 0.55,4,2,2); g.endFill();
               }
            }
         }
      }
      private function hz51PvSubtitle(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(k == "Subtitles" && !this.hz51On("Subtitles")) { this.hz51PvOff(b,T,x,y,w,h,"Game subtitles"); return; }
         if(!this.hz51On("Subtitles") && k != "Subtitles" && k != "ShowSpeaker" && k != "SpeakerCard" && k != "SpkColIdx") { this.hz51PvOff(b,T,x,y,w,h,"Game subtitles"); return; }
         var widthPct:Number = p != null && !isNaN(Number(p.SubWidth)) ? Number(p.SubWidth) : 70;
         if(widthPct > 1) { widthPct = widthPct / 100; }
         if(isNaN(widthPct) || widthPct <= 0) { widthPct = 0.7; }
         var barW:Number = Math.max(80, (w - 20) * Math.max(0.45, Math.min(1, widthPct)));
         var barH:Number = 40;
         var align:int = p != null ? int(p.SubAlign) : 0;
         var bx:Number = x + 10;
         if(align == 1) { bx = x + (w - barW) / 2; }
         else if(align == 2) { bx = x + w - 10 - barW; }
         var by:Number = y + h / 2 - 8;
         if(k == "SubPosition" || k == "SubOffsetY")
         {
            var pos:int = p != null ? int(p.SubPosition) : 0;
            by = pos == 1 ? y + 16 : (pos == 2 ? y + h - barH - 16 : y + h / 2 - 8);
         }
         var opa:Number = p != null ? Number(p.SubBgOpacity) : 70;
         if(opa > 1) { opa = opa / 100; }
         if(isNaN(opa)) { opa = 0.7; }
         var cardOn:Boolean = p == null || p.SubCard === undefined || Boolean(p.SubCard);
         if(k == "SubCard") { cardOn = this.hz51On("SubCard"); }
         if(cardOn)
         {
            g.beginFill(uint(T.fill),Math.max(0.25, opa));
            g.drawRoundRect(bx,by,barW,barH,HZ51_BOX_R,HZ51_BOX_R);
            g.endFill();
            this.hz34Ring(b,bx,by,barW,barH,HZ51_BOX_R,acc,0.4,1);
         }
         var spkOn:Boolean = this.hz51On("ShowSpeaker");
         if(k == "ShowSpeaker") { spkOn = this.hz51On("ShowSpeaker"); }
         var spkCard:Boolean = this.hz51On("SpeakerCard");
         var fs:Number = 10;
         if(p != null && !isNaN(Number(p.SubSize)) && Number(p.SubSize) > 0) { fs = Math.max(8, Math.min(13, 8 + Number(p.SubSize) * 2)); }
         if(spkOn)
         {
            var sx:Number = bx + 8;
            var sy:Number = by + (cardOn ? 4 : -12);
            if(spkCard)
            {
               g.beginFill(uint(T.tile),0.95); g.drawRoundRect(sx - 2,sy - 2,64,14,4,4); g.endFill();
               this.hz34Ring(b,sx - 2,sy - 2,64,14,4,acc,0.8,1);
            }
            var spkCol:uint = acc;
            try { if(p != null && p.SpkColIdx != undefined) { var spal:Array = HZ_ACCENTS; var si:int = int(p.SpkColIdx); if(spal != null && si >= 0 && si < spal.length) { spkCol = uint(spal[si]); } } } catch(eSpk:Error) { }
            this.hz51T(b,"ANDREJA",sx,sy,barW - 16,8,"sb",spkCol,0.8);
            this.hz51T(b,"We should keep moving.",bx + 8,by + 18,barW - 16,fs,"rg",uint(T.txt),0.2);
         }
         else
         {
            this.hz51T(b,"We should keep moving.",bx + 8,by + 12,barW - 16,fs,"rg",uint(T.txt),0.2);
         }
         if(k == "SubMaxLines") { this.hz51T(b,String(p != null ? int(p.SubMaxLines) : 2) + " LINES",bx,by + barH + 4,barW,8,"sb",uint(T.mut),0.8); }
      }
      private function hz51PvScanner(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         if(k == "ScanShowSignals" && !this.hz51On("ScanShowSignals")) { this.hz51PvOff(b,T,x,y,w,h,"Signals hidden"); return; }
         if(k == "ScanShowMode" && !this.hz51On("ScanShowMode")) { this.hz51PvOff(b,T,x,y,w,h,"Mode pill hidden"); return; }
         var rx:Number = x + 10;
         var ry:Number = y + 16;
         var rw:Number = w - 20;
         if(k == "ScanShowMode" || k == "ScanModeScale")
         {
            g.beginFill(acc,0.16); g.drawRoundRect(rx,ry + 20,64,22,11,11); g.endFill();
            this.hz34Ring(b,rx,ry + 20,64,22,11,acc,0.7,1);
            this.hz51T(b,"SCAN",rx + 32,ry + 25,60,9,"sb",acc,0.4,"center");
            return;
         }
         g.beginFill(uint(T.tile),0.92);
         g.drawRoundRect(rx,ry,rw,28,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,rx,ry,rw,28,HZ51_BOX_R,acc,0.5,1);
         g.beginFill(acc,1); g.drawCircle(rx + 12,ry + 14,4); g.endFill();
         this.hz51T(b,"FLORA",rx + 22,ry + 5,rw - 50,9,"sb",acc,0.8);
         this.hz51T(b,"12 m",rx + rw - 36,ry + 6,32,9,"rg",uint(T.mut),0.2);
         g.beginFill(uint(T.tile),0.70);
         g.drawRoundRect(rx,ry + 34,rw,22,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         g.beginFill(uint(T.lab),1); g.drawCircle(rx + 12,ry + 45,3); g.endFill();
         this.hz51T(b,"RESOURCE",rx + 22,ry + 38,rw - 50,8,"sb",uint(T.lab),0.6);
         var maxN:int = p != null ? int(p.ScanMaxSignals) : 5;
         this.hz51T(b,String(maxN) + " ON LIST",rx,ry + 62,rw,8,"sb",uint(T.mut),0.8);
      }
      private function hz51PvTheme(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         var cw:Number = w - 24;
         var ch:Number = 52;
         var cx:Number = x + 12;
         var cy:Number = y + 18;
         var opa:Number = p != null ? Number(p.CardOpacity) : 1;
         if(isNaN(opa) || opa <= 0) { opa = 1; }
         if(opa > 1) { opa = 1; }
         var bgA:Number = p != null ? Number(p.CardBgOpacity) : 92;
         if(bgA > 1) { bgA = bgA / 100; }
         g.beginFill(uint(T.fill),Math.max(0.35, 0.55 + bgA * 0.4) * opa);
         g.drawRoundRect(cx,cy,cw,ch,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,cx,cy,cw,ch,HZ51_BOX_R,acc,0.85,1);
         var face:String = "EXO 2";
         if(p != null && p.FontFace != undefined)
         {
            var fi:int = int(p.FontFace);
            if(fi == 2) { face = "ROBOTO"; }
            else if(fi == 0) { face = "GAME FONT"; }
            else if(fi == 3) { face = "GAME SEMIBOLD"; }
         }
         var ts:Number = p != null && !isNaN(Number(p.TextScale)) ? Number(p.TextScale) : 1;
         var fs:Number = Math.max(9, Math.min(13, 11 * (ts > 0 ? ts : 1)));
         this.hz51T(b,face,cx + 10,cy + 8,cw - 20,fs,"bd",uint(T.txt),0.4);
         this.hz51T(b,"Sample HUD text",cx + 10,cy + 28,cw - 20,9,"rg",uint(T.lab),0.2);
         this.hz51T(b,k == "FontFace" || k == "TextScale" ? "TYPOGRAPHY" : "THEME",cx + 10,cy + ch + 8,cw - 20,8,"sb",acc,0.8);
      }
      private function hz51PvModule(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, r:Object) : void
      {
         var on:Boolean = r != null && r.swk != undefined ? this.hz51On(String(r.swk)) : (r != null && String(r.badge).indexOf("INSTALLED") == 0 && String(r.badge).indexOf("NOT") < 0 && String(r.badge).indexOf("DISABLED") < 0);
         var lab:String = r != null && r.l != undefined ? String(r.l) : "MODULE";
         g.beginFill(on ? acc : uint(T.tile),on ? 0.16 : 0.5);
         g.drawRoundRect(x + 12,y + 28,w - 24,40,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,x + 12,y + 28,w - 24,40,HZ51_BOX_R,on ? acc : uint(T.mut),0.6,1);
         this.hz51T(b,lab,x + w / 2,y + 34,w - 32,10,"bd",uint(T.txt),0.4,"center");
         this.hz51T(b,on ? "HORIZON ON" : "STATUS",x + w / 2,y + 50,w - 32,8,"sb",on ? acc : uint(T.mut),0.8,"center");
      }
      private function hz51PvCard(b:Sprite, g:*, T:Object, acc:uint, x:Number, y:Number, w:Number, h:Number, p:Object, k:String) : void
      {
         var opa:Number = p != null ? Number(p.CardOpacity) : 1;
         if(isNaN(opa) || opa <= 0) { opa = 1; }
         if(opa > 1) { opa = 1; }
         var bgA:Number = p != null ? Number(p.CardBgOpacity) : 92;
         if(bgA > 1) { bgA = bgA / 100; }
         var sc:Number = 1;
         var compact:Boolean = Boolean(p != null && p.Compact);
         if(k.indexOf("Scale") > 0 && p != null)
         {
            var sv:Number = Number(p[k]);
            if(!isNaN(sv) && sv > 0) { sc = sv; }
         }
         else if(k.indexOf("Compact") > 0 && p != null)
         {
            var cv:Number = Number(p[k]);
            compact = cv > 0.5 || (k == "Compact" && Boolean(p.Compact));
            if(cv < 0) { compact = Boolean(p.Compact); }
         }
         var shown:Boolean = true;
         if(k.indexOf("Show") == 0 || k == "XpToast" || k == "MissionToast" || k == "HazardStatus" || k == "EnemyBar" || k == "StealthMeter" || k == "EquipmentExtras" || k == "Subtitles" || k == "Dialogue" || k == "QuickMenuHorizon")
         {
            shown = this.hz51On(k);
         }
         if(k == "WatchStyle") { shown = p != null && int(p.WatchStyle) != 0; }
         var cw:Number = Math.min(148, w - 20) * (compact ? 0.78 : 1) * Math.max(0.55, Math.min(1.25, sc));
         var ch:Number = (compact ? 28 : 44) * Math.max(0.55, Math.min(1.25, sc));
         var cx:Number = x + 10;
         var cy:Number = y + 16;
         if(!shown) { this.hz51PvOff(b,T,x,y,w,h,"Hidden on the HUD"); return; }
         g.beginFill(uint(T.fill),Math.max(0.35, 0.55 + bgA * 0.4) * opa);
         g.drawRoundRect(cx,cy,cw,ch,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         this.hz34Ring(b,cx,cy,cw,ch,HZ51_BOX_R,acc,0.85,1);
         g.beginFill(acc,1); g.drawRoundRect(cx + 8,cy + ch * 0.28,Math.max(24,cw * 0.62),4,2,2); g.endFill();
         g.beginFill(uint(T.txt),0.40); g.drawRoundRect(cx + 8,cy + ch * 0.52,Math.max(18,cw * 0.42),3,2,2); g.endFill();
         if(k == "WatchStyle")
         {
            var ws:int = p != null ? int(p.WatchStyle) : 0;
            var lab:String = ws == 4 ? "ANALOG" : (ws == 3 ? "DIGITAL" : (ws == 2 ? "VANILLA + HORIZON" : (ws == 1 ? "VANILLA" : "OFF")));
            this.hz51T(b,lab,cx + cw / 2,cy + ch + 8,cw,10,"sb",acc,0.4,"center");
            if(ws == 4) { g.beginFill(acc,0.18); g.drawCircle(cx + cw / 2,cy + ch / 2,Math.min(12,ch / 2 - 2)); g.endFill(); }
         }
         else if(k.indexOf("Afflict") == 0)
         {
            var lay:int = p != null ? int(p.AfflictionLayout) : 0;
            var ai:int = 0;
            while(ai < 2)
            {
               var ax:Number = cx + 8 + (lay == 1 ? ai * 36 : 0);
               var ay:Number = cy + 6 + (lay == 1 ? 0 : ai * 16);
               if(lay == 2) { g.beginFill(acc,0.9); g.drawCircle(cx + 16 + ai * 18,cy + ch / 2,5); g.endFill(); }
               else { g.beginFill(acc,0.2); g.drawRoundRect(ax,ay,32,12,4,4); g.endFill(); this.hz51T(b,ai == 0 ? "BURN" : "COLD",ax + 4,ay + 1,28,8,"sb",acc,0.6); }
               ai++;
            }
            this.hz51T(b,lay == 2 ? "ICONS" : (lay == 1 ? "ROW" : "COLUMN"),cx + 8,cy + ch + 4,cw,8,"sb",uint(T.lab),0.4);
         }
         else if(k.indexOf("Scale") > 0 || k.indexOf("Compact") > 0)
         {
            this.hz51T(b,compact ? "COMPACT" : (sc == 1 ? "FOLLOW HUD" : "CUSTOM " + this.hzSetNum(sc)),cx + 8,cy + ch + 6,cw,9,"sb",uint(T.lab),0.4);
         }
         else { this.hz51T(b,String(k).toUpperCase(),cx + 8,cy + ch + 6,cw,8,"sb",acc,0.8); }
      }
      private function hz51DrawFooter(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var fy:Number = H - HZ51_FOOT;
         this.hz51Hair(g,0,fy,W,1,uint(T.txt),0.10);
         var hx:Number = 16;
         var by:Number = fy + 12;
         if(this.hz51Pad)
         {
            this.hz51T(b,this.hzLt("CONTROLLER"),hx,by + 2,88,9,"bd",uint(T.mut),1.2);
            hx = 108;
            for each(var ck:Array in [["LB/RB","TABS"],["D-PAD","MOVE"],["A","SELECT"],["B","BACK"]])
            {
               var ckw:Number = this.hzSetKey(b,g,hx,by,String(ck[0]),acc,16,7,9);
               var cl:TextField = this.hz51T(b,this.hzLt(String(ck[1])),hx + ckw + 4,by + 2,90,10,"sb",uint(T.lab),0.6);
               hx = Math.round(hx + ckw + 4 + this.hzTW(cl) + 10);
            }
         }
         else
         {
            this.hz51T(b,this.hzLt("KEYBOARD"),hx,by + 2,80,9,"bd",uint(T.mut),1.2);
            hx = 100;
            for each(var hk:Array in [["UP/DN","SELECT"],["L/R","CHANGE"],["ENTER","OK"],["ESC","CANCEL"],["/","SEARCH"]])
            {
               var hkw:Number = this.hzSetKey(b,g,hx,by,String(hk[0]),uint(T.mut),16,7,9);
               var hl:TextField = this.hz51T(b,this.hzLt(String(hk[1])),hx + hkw + 4,by + 2,70,10,"sb",uint(T.lab),0.6);
               hx = Math.round(hx + hkw + 4 + this.hzTW(hl) + 10);
            }
         }
         var bxr:Number = W - 16;
         bxr -= this.hzSetBtn(b,g,bxr,fy + 9,this.hzLt("CANCEL"),false,false,this.hzSetHover == "cancel",T,"cancel",11,10) + 6;
         this.hzSetBtn(b,g,bxr,fy + 9,this.hzLt("OK"),true,false,this.hzSetHover == "ok",T,"ok",11,10);
      }
      private function hz51DrawFind(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var hits:Array = this.hz51FindHits();
         var lay:Object = this.hz51HeadSlots();
         var w:Number = 360;
         var x:Number = Number(lay.fx) + Number(lay.findW) - w;
         if(x < 8) { x = 8; }
         var arrX:Number = Number(lay.ax);
         if(Number(lay.arrW) > 0 && x + w > arrX - 8)
         {
            w = Math.max(160, arrX - 8 - x);
            if(w < 200) { x = Math.max(8, arrX - 8 - 280); w = arrX - 8 - x; }
         }
         var y:Number = Number(lay.fy) + HZ51_FIND_H + 6;
         var h:Number = Math.min(220, 12 + Math.max(1,hits.length) * 34 + 28);
         if(hits.length == 0) { h = 56; }
         g.beginFill(uint(T.fill),Math.max(0.96,Number(T.fa))); g.drawRoundRect(x,y,w,h,6,6); g.endFill();
         this.hz51Stroke(g,x,y,w,h,acc,0.40,6);
         if(!this.hzSetFindOn && this.hzSetFind.length == 0) { return; }
         if(hits.length == 0)
         {
            this.hz51T(b,this.hzLt("No settings match"),x + 14,y + 18,w - 28,12,"sb",uint(T.mut),0.2);
            return;
         }
         if(this.hzSetFindHi >= hits.length) { this.hzSetFindHi = 0; }
         var i:int = 0;
         var yy:Number = y + 6;
         while(i < hits.length && yy + 34 < y + h - 20)
         {
            var hit:Object = hits[i];
            var sel:Boolean = i == this.hzSetFindHi;
            if(sel) { g.beginFill(acc,0.24); g.drawRect(x + 4,yy,w - 8,32); g.endFill(); g.beginFill(acc,1); g.drawRect(x + 4,yy,3,32); g.endFill(); }
            this.hz51T(b,String(hit.l),x + 14,yy + 2,w - 24,12,"sb",sel ? acc : uint(T.txt),0.2);
            this.hz51T(b,String(hit.crumb),x + 14,yy + 16,w - 24,10,"rg",uint(T.mut),0.2);
            this.hzSetHits.push({"id":"fhit" + i,"x":x + 4,"y":yy,"w":w - 8,"h":32});
            yy += 34;
            i++;
         }
      }
      private function hz51DrawDrop(b:Sprite, g:*, T:Object, acc:uint, rows:Array, W:Number, H:Number) : void
      {
         if(this.hzSetDrop < 0 || this.hzSetDrop >= rows.length) { return; }
         var r:Object = rows[this.hzSetDrop];
         var opts:Array = this.hz51DropOpts(r);
         if(opts == null || opts.length == 0) { this.hzSetDrop = -1; return; }
         var ctrl:Object = this.hzSetDropBox;
            if(ctrl == null)
            {
            var box:Object = this.hz51ListBox();
            ctrl = {"x":Number(box.r) - HZ51_CTRL_W,"y":Number(box.y),"w":HZ51_CTRL_W,"h":HZ51_DD_H};
            }
         var needH:Number = 8 + opts.length * HZ51_DROP_ITEM;
         var place:Object = this.hz51DropRect(Number(ctrl.x),Number(ctrl.y),Number(ctrl.w),Number(ctrl.h),Number(ctrl.w),needH,W,H,HZ51_FOOT,HZ_SET_TOP);
         var x:Number = Number(place.x);
         var y:Number = Number(place.y);
         var w:Number = Number(place.w);
         var h:Number = Number(place.h);
         var vis:int = int(place.vis);
         if(vis < 1) { vis = 1; }
         if(vis > opts.length) { vis = opts.length; }
         this.hzSetDropVis = vis;
         if(this.hzSetDropHi < 0) { this.hzSetDropHi = 0; }
         if(this.hzSetDropHi >= opts.length) { this.hzSetDropHi = opts.length - 1; }
         if(this.hzSetDropHi < this.hzSetDropScroll) { this.hzSetDropScroll = this.hzSetDropHi; }
         if(this.hzSetDropHi >= this.hzSetDropScroll + vis) { this.hzSetDropScroll = this.hzSetDropHi - vis + 1; }
         if(this.hzSetDropScroll < 0) { this.hzSetDropScroll = 0; }
         if(this.hzSetDropScroll > Math.max(0, opts.length - vis)) { this.hzSetDropScroll = Math.max(0, opts.length - vis); }
         h = 8 + vis * HZ51_DROP_ITEM;
         this.hzSetDropMenu = {"x":x,"y":y,"w":w,"h":h};
         g.beginFill(uint(T.fill),1);
         g.drawRoundRect(x,y,w,h,6,6);
         g.endFill();
         this.hz51Stroke(g,x,y,w,h,acc,0.45,6);
         var i:int = 0;
         while(i < vis)
         {
            var oi:int = this.hzSetDropScroll + i;
            if(oi >= opts.length) { break; }
            var yy:Number = y + 4 + i * HZ51_DROP_ITEM;
            if(yy + HZ51_DROP_ITEM > y + h) { break; }
            var sel:Boolean = oi == this.hzSetDropHi;
            if(sel) { g.beginFill(acc,0.18); g.drawRoundRect(x + 3,yy,w - 6,HZ51_DROP_ITEM - 2,4,4); g.endFill(); }
            var dlab:String = this.hz51Exo2Text(String(opts[oi]));
            if(r.t == "a" && r.pal != undefined)
            {
               var pal:Array = r.pal as Array;
               g.beginFill(uint(pal[Math.min(pal.length - 1,oi)]),1); g.drawRoundRect(x + 10,yy + 6,10,10,2,2); g.endFill();
               this.hz51T(b,dlab,x + 26,yy + 4,w - 36,11,"sb",sel ? acc : uint(T.txt),0.2);
            }
            else { this.hz51T(b,dlab,x + 10,yy + 4,w - 20,11,"sb",sel ? acc : uint(T.txt),0.2); }
            this.hzSetHits.push({"id":"dopt" + oi,"x":x + 3,"y":yy,"w":w - 6,"h":HZ51_DROP_ITEM});
            i++;
         }
         if(opts.length > vis)
         {
            var trX:Number = x + w - 7;
            var trT:Number = y + 6;
            var trH:Number = h - 12;
            var thH:Number = Math.max(10,Math.round(trH * vis / opts.length));
            var thY:Number = Math.round(trT + (trH - thH) * this.hzSetDropScroll / Math.max(1,opts.length - vis));
            g.beginFill(uint(T.txt),0.14); g.drawRoundRect(trX,trT,4,trH,2,2); g.endFill();
            g.beginFill(acc,0.9); g.drawRoundRect(trX,thY,4,thH,2,2); g.endFill();
         }
      }
      // Purpose: mouse wheel on an open dropdown. One option row per notch from
      // the existing wheelup/wheeldown queue (native already forwards the wheel).
      // Keeps the highlight in the visible window. No polling, no extra listeners.
      // Inputs: d +1 down / -1 up, n option count. Outputs: hzSetDropScroll / Hi.
      private function hz51DropWheel(d:int, n:int) : void
      {
         var vis:int = this.hzSetDropVis > 0 ? this.hzSetDropVis : 1;
         if(n < 1) { return; }
         var maxS:int = Math.max(0, n - vis);
         this.hzSetDropScroll = Math.max(0, Math.min(maxS, this.hzSetDropScroll + d));
         if(this.hzSetDropHi < this.hzSetDropScroll) { this.hzSetDropHi = this.hzSetDropScroll; }
         if(this.hzSetDropHi >= this.hzSetDropScroll + vis) { this.hzSetDropHi = this.hzSetDropScroll + vis - 1; }
      }
      private function hz51Key(code:String) : Boolean
      {
         this.hz51NotePad(code);
         if(code == "hzpad") { return true; }
         if(code == "cancel" && this.hz51FindOpen()) { this.hz51FindClose(); return true; }
         if(this.hzSetFindOn)
         {
            if(code == "ok")
            {
               var hits:Array = this.hz51FindHits();
               if(this.hzSetFindHi >= 0 && this.hzSetFindHi < hits.length) { this.hz51GotoHit(hits[this.hzSetFindHi]); }
               return true;
            }
            if(code == "up" || code == "down")
            {
               var hs:Array = this.hz51FindHits();
               if(hs.length == 0) { return true; }
               this.hzSetFindHi = (this.hzSetFindHi + (code == "down" ? 1 : hs.length - 1)) % hs.length;
               return true;
            }
            if(code == "bksp")
            {
               if(this.hzSetFind.length > 0) { this.hzSetFind = this.hzSetFind.substr(0,this.hzSetFind.length - 1); }
               this.hzSetFindHi = 0;
               this.hzSetGlowK = "";
               return true;
            }
            // QueueKey sends ch:v then bind:V for one key. Append only ch:; swallow bind:.
            if(code.indexOf("bind:") == 0) { return true; }
            var typed:String = this.hz51TypeChar(code);
            if(typed.length == 1)
            {
               this.hzSetFind += typed;
               this.hzSetFindHi = 0;
               this.hzSetGlowK = "";
               return true;
            }
            return true;
         }
         if(this.hzSetHexK.length > 0)
         {
            if(code == "cancel") { this.hzSetHexBuf = this.hzSetHexPrev >= 0 ? this.hzHex(this.hzSetHexPrev).substr(1) : this.hzSetHexBuf; this.hzSetHexK = ""; this.hzSetFocus = 0; return true; }
            if(code == "ok") { this.hz51HexCommit(); this.hzSetHexK = ""; this.hzSetFocus = 0; return true; }
            if(code == "bksp") { if(this.hzSetHexBuf.length > 0) { this.hzSetHexBuf = this.hzSetHexBuf.substr(0,this.hzSetHexBuf.length - 1); } return true; }
            if(code.indexOf("bind:") == 0) { return true; }
            var hxCh:String = this.hz51TypeChar(code).toUpperCase();
            if(hxCh.length == 1 && "0123456789ABCDEF".indexOf(hxCh) >= 0 && this.hzSetHexBuf.length < 6) { this.hzSetHexBuf += hxCh; return true; }
            return true;
         }
         if(this.hzSetDrop >= 0)
         {
            var rowsD:Array = this.hzSetRows(this.hzSetTab);
            var rr:Object = this.hzSetDrop < rowsD.length ? rowsD[this.hzSetDrop] : null;
            var opts:Array = this.hz51DropOpts(rr);
            if(code == "cancel" || code == "left") { this.hzSetDrop = -1; this.hzSetFocus = 0; return true; }
            if(code == "up" || code == "down")
            {
               if(opts.length == 0) { return true; }
               this.hzSetDropHi = (this.hzSetDropHi + (code == "down" ? 1 : opts.length - 1)) % opts.length;
               if(this.hzSetDropHi < this.hzSetDropScroll) { this.hzSetDropScroll = this.hzSetDropHi; }
               if(this.hzSetDropVis > 0 && this.hzSetDropHi >= this.hzSetDropScroll + this.hzSetDropVis) { this.hzSetDropScroll = this.hzSetDropHi - this.hzSetDropVis + 1; }
               return true;
            }
            if(code == "ok" || code == "right")
            {
               this.hz51DropPick(rr, this.hzSetDropHi);
               this.hzSetDrop = -1;
               this.hzSetFocus = 0;
               return true;
            }
            if(code == "wheelup" || code == "wheeldown")
            {
               this.hz51DropWheel(code == "wheeldown" ? 1 : -1, opts.length);
               return true;
            }
            return true;
         }
         if(this.hz51TypeChar(code) == "/")
         {
            this.hzSetFindOn = true;
            this.hzSetFindHi = 0;
            this.hzSetFocus = 2;
            return true;
         }
         return false;
      }
      private function hz51OpenDrop(i:int, rows:Array) : void
      {
         if(i < 0 || i >= rows.length) { return; }
         var r:Object = rows[i];
         if(r.dis) { return; }
         if(r.t != "r" && r.t != "q" && r.t != "l" && r.t != "a" && r.t != "c" && r.t != "p") { return; }
         this.hzSetDrop = i;
         this.hzSetDropHi = 0;
         this.hzSetDropScroll = 0;
         this.hzSetFocus = 3;
         if(r.t == "r") { this.hzSetDropHi = Math.max(0,this.hz29OptIdx(r,this.hzSetPend[r.k])); }
         else if(r.t == "q") { var ids:Array = r.ids as Array; this.hzSetDropHi = Math.max(0,ids.indexOf(int(this.hzSetPend[r.k]))); }
         else if(r.t == "l") { this.hzSetDropHi = this.hzSetListIdx(r,this.hzSetPend[r.k]); }
         else if(r.t == "a" || r.t == "c") { this.hzSetDropHi = Math.max(0,int(this.hzSetPend[r.k])); if(r.t == "c") { this.hzSetDropHi = Math.max(0,HZ_SET_KEYS.indexOf(String(this.hzSetPend[r.k]))); } }
         else if(r.t == "p") { this.hzSetDropHi = Math.max(0,this.hz37Sel); }
      }
      private function hz51ListBox() : Object
      {
         var x:Number = HZ51_SIDE_W + 20;
         var y:Number = HZ_SET_TOP + 64;
         var r:Number = this.HZ_SET_W - HZ51_PREV_W - 14;
         return {"x":x,"y":y,"r":r,"w":r - x};
      }
