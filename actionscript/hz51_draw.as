      private var hzSetFocus:int = 0;   // 0 list, 1 sidebar, 2 search, 3 dropdown, 4 hex

      // Purpose: draw the Settings 2.0 window: 1260x726 (height locked; width cap
      // so HUD side cards stay visible), 248 sidebar, 196 preview, 48px rows, 1px
      // bar strokes, one hint row. Colors still come from hzSetTheme.
      // Inputs: hzSetPend while F11 is open. Outputs: redrawn HorizonSettings_mc.
      // Author: Moragar. Last modified: 2026-11-26.
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
         // mockup box-shadow: 0 12px 48px #000a — one offset fill, not a 5-layer blur
         g.beginFill(0x000000,0.40);
         g.drawRoundRect(0,12,W,H,HZ51_WIN_R,HZ51_WIN_R);
         g.endFill();
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(0,0,W,H,HZ51_WIN_R,HZ51_WIN_R);
         g.endFill();
         this.hz51Stroke(g,0,0,W,H,acc,HZ51_WIN_EA,HZ51_WIN_R);
         this.hz51DrawHead(b,g,T,acc,W);
         this.hz51DrawTabs(b,g,T,acc,W);
         this.hz51Hair(g,0,HZ51_HEAD + HZ51_TABS - 1,W,1,uint(T.txt),0.10);
         this.hz51DrawSide(b,g,T,acc,H);
         var rows:Array = [];
         try { rows = this.hzSetRows(this.hzSetTab); } catch(eRowsD:Error) { rows = []; }
         if(rows.length == 0) { rows = [{"k":"_empty","l":"NO SETTINGS IN THIS SECTION","t":"x","btn":"—","h":"THIS SECTION","dis":true}]; }
         if(this.hzSetRow >= rows.length) { this.hzSetRow = 0; }
         try { this.hzSetFollow(rows); } catch(eFol:Error) { }
         try { this.hz51DrawList(b,g,T,acc,rows); } catch(eList:Error) { this.hz51T(b,"This page could not be drawn.",HZ51_SIDE_W + 24,HZ_SET_TOP + 60,400,12,"sb",uint(T.mut),0.2); }
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
         if(this.hzSetFindOn || this.hzSetFind.length > 0) { this.hz51DrawFind(this.hzSetOver,this.hzSetOver.graphics,T,acc,W,H); }
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
         this.hz51T(b,"HORIZON UI",16,14,150,16,"bd",uint(T.txt),2.4);
         this.hz51T(b,"SETTINGS",16 + 128,18,90,11,"sb",uint(T.lab),2.0);
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
            var tb:TextField = this.hz51T(b,String(HZ_SET_TABS[i]),0,ty,140,12,"bd",sel || hov ? acc : uint(T.mut),1.6);
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
         if(Number(lay.arrW) > 0)
         {
            var alab:String = this.hzSetTab == 2 ? "ARRANGE SCANNER" : "ARRANGE CARDS";
            var aid:String = this.hzSetTab == 2 ? "arrscan" : "arrange";
            var aw:Number = Number(lay.arrW);
            var ax:Number = Number(lay.ax);
            var ay:Number = Number(lay.fy);
            var hovA:Boolean = this.hzSetHover == aid;
            g.beginFill(acc,hovA ? 1 : 0.92); g.drawRoundRect(ax,ay,aw,Number(lay.h),6,6); g.endFill();
            // hzWT center treats x as the midpoint. Passing ax (left edge) put
            // "ARRANGE CARDS" over the search box, leaving a cut-off "E CARDS".
            this.hz51T(b,alab,ax + aw / 2,ay + 8,aw - 8,11,"bd",uint(T.ontxt),1.2,"center");
            this.hzSetHits.push({"id":aid,"x":ax,"y":ay,"w":aw,"h":Number(lay.h)});
         }
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
         this.hz51T(b,"COMPACT MODE (STRIPS)",px0 + 12,py0 + 8,pw - 86,11,"bd",uint(T.lab),0.8);
         this.hz51Switch(b,g,px0 + pw - 8,py0 + ph / 2,pon,T);
         this.hzSetHits.push({"id":"compact","x":px0,"y":py0,"w":pw,"h":ph});
      }
      private function hz51DrawSearchBox(b:Sprite, g:*, T:Object, acc:uint, bx:Number, by:Number, bw:Number) : void
      {
         var on:Boolean = this.hzSetFindOn || this.hzSetHover == "findbox";
         g.beginFill(uint(T.fill),0.88);
         g.drawRoundRect(bx,by,bw,HZ51_FIND_H,6,6);
         g.endFill();
         this.hz51Stroke(g,bx,by,bw,HZ51_FIND_H,on ? acc : uint(T.txt),on ? 0.70 : 0.28,6);
         var typed:Boolean = this.hz51FindOpen();
         var txt:String = this.hzSetFind.length > 0 ? this.hzSetFind : (typed ? "" : "Search settings...");
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
            this.hz51T(b,"X",xx,by + 8,14,9,"bd",uint(T.txt),0.4,"center");
            this.hzSetHits.push({"id":"findx","x":xx - 10,"y":by,"w":20,"h":HZ51_FIND_H});
         }
      }
      private function hz51Switch(b:Sprite, g:*, R:Number, cy:Number, on:Boolean, T:Object) : void
      {
         var acc:uint = uint(T.acc);
         var sw:Number = HZ51_SW_W;
         var sh:Number = HZ51_SW_H;
         var sx:Number = Math.round(R - sw);
         var sy:Number = Math.round(cy - sh / 2);
         this.hz51T(b,on ? "ON" : "OFF",sx - 4,cy - 7,28,10,"sb",on ? acc : uint(T.mut),1.5,"right");
         g.beginFill(on ? acc : uint(T.off),on ? 0.92 : 1);
         g.drawRoundRect(sx,sy,sw,sh,sh,sh);
         g.endFill();
         var kn:Number = 16;
         var kx:Number = on ? sx + sw - 3 - kn : sx + 3;
         g.beginFill(on ? uint(T.kon) : uint(T.koff),1);
         g.drawCircle(kx + kn / 2,cy,kn / 2);
         g.endFill();
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
            this.hz51T(b,String(grp.g),x0 + 16,y + 4,w - 24,HZ51_SH_PX,"bd",acc,1.4);
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
                  g.drawRect(x0,y,w,ih);
                  g.endFill();
                  g.beginFill(acc,1); g.drawRect(x0,y,3,ih); g.endFill();
               }
               else { this.hz51Hair(g,x0 + 16,y + ih - 1,w - 16,1,uint(T.txt),0.04); }
               this.hz51T(b,String(it.l),x0 + 16,y + 6,w - 24,11,"bd",sel ? acc : uint(T.lab),0.8);
               this.hz51T(b,String(it.s),x0 + 16,y + 22,w - 24,10,"rg",uint(T.mut),0.1);
               this.hzSetHits.push({"id":"side" + pi,"x":x0,"y":y,"w":w,"h":ih});
               y += ih;
               pi++;
               ii++;
            }
            y += 6;
            gi++;
         }
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
         var title:String = pobj != null ? String(pobj.l) : "";
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
            this.hz51T(b,"No settings in this section.",x0,y + 10,boxW,12,"sb",uint(T.mut),0.2);
         }
         while(li < list.length)
         {
            var r:Object = list[li];
            if(y + this.hzSetRowH(r) - 4 > bottom) { break; }
            var i:int = rows.indexOf(r);
            if(r.h)
            {
               if(boxOpen)
               {
                  this.hz51Stroke(gMain,boxX,boxY,boxW,Math.max(20,boxH),acc,HZ51_BOX_A,HZ51_BOX_R);
                  boxOpen = false;
               }
               var shY:Number = y + (firstSec ? 2 : 10);
               var ht:TextField = this.hz51T(b,String(r.h),x0,shY + 6,Math.min(240,boxW * 0.45),HZ51_SH_PX,"bd",acc,1.4);
               var ruleX:Number = x0 + Math.round(this.hzTW(ht) + 12);
               this.hz51Hair(g,ruleX,shY + 16,Math.max(16,boxW - (ruleX - x0)),1,acc,HZ51_SH_A);
               y += HZ51_SEC;
               firstSec = false;
               boxY = y;
               boxH = 8;
               boxOpen = true;
            }
            else if(!boxOpen)
            {
               boxY = y;
               boxH = 8;
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
            if(r.t == "m")
            {
               try { this.hz51ModBanner(b,g,y,x0,boxW,T,String(r.mod),i == this.hzSetRow,i); } catch(errMb:Error) { }
               y += 40;
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
            g.beginFill(uint(T.fill),0.70);
            g.drawRect(x0,y,boxW,HZ51_ROW);
            g.endFill();
            g.beginFill(0xFFFFFF,0.06);
            g.drawRect(x0,y,boxW,HZ51_ROW);
            g.endFill();
            if(rs || rh || glow)
            {
               g.beginFill(acc,glow ? 0.18 : (rs ? HZ51_SEL_A : 0.05));
               g.drawRect(x0,y,boxW,HZ51_ROW);
               g.endFill();
            }
            var labX:Number = r.dis ? x0 + 32 : x0 + 16;
            var labW:Number = Math.max(120, boxW - 220);
            var lb35:TextField = this.hz51T(b,String(r.l),labX,y + 6,labW,HZ51_TITLE_PX,"bd",uint(T.txt),0.8);
            this.hzSetHits.push({"id":"row" + i,"x":x0,"y":y,"w":boxW,"h":HZ51_ROW});
            var inf35:String = r.dis ? null : this.hz35InfoOf(r);
            if(inf35 != null && lb35 != null && String(r.l).length > 0)
            {
               var ix35:Number = Math.round(lb35.x + 2 + Math.min(lb35.width,this.hzTW(lb35)) + 14);
               var ion35:Boolean = this.hzSetHover == "inf" + i || (rs && this.hz35Kb);
               this.hz51InfoIcon(b,g,ix35,y + 14,acc,T,ion35,i);
               if(ion35) { this.hz35Tip = {"t":inf35,"x":ix35,"y":y,"h":HZ51_ROW}; }
            }
            var help:String = r.note != undefined ? String(r.note) : "";
            if(help.length > 0)
            {
               var ht2:TextField = this.hz51T(b,help,labX,y + 24,labW,HZ51_HELP_PX,"rg",uint(T.mut),0.1);
               ht2.wordWrap = false;
               ht2.multiline = false;
            }
            var v:* = r.dis ? r.dv : this.hzSetPend[r.k];
            var cy:Number = y + Math.round(HZ51_ROW / 2);
            try { this.hz51DrawCtrl(b,g,r,i,y,R,cy,v,T,acc,rh); } catch(eCtrl:Error) { }
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
         if(boxOpen)
         {
            this.hz51Stroke(gMain,boxX,boxY,boxW,Math.max(20,boxH),acc,HZ51_BOX_A,HZ51_BOX_R);
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
      private function hz51DrawCtrl(b:Sprite, g:*, r:Object, i:int, y:Number, R:Number, cy:Number, v:*, T:Object, acc:uint, rh:Boolean) : void
      {
         var isDef:Boolean = this.hzSetIsDef(String(r.k),v);
         var vcol:uint = isDef ? uint(T.txt) : acc;
         if(r.t == "b") { this.hz51Switch(b,g,R,cy,Boolean(v),T); }
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
            this.hzSetHits.push({"id":"bar" + i,"x":bx - 10,"y":y,"w":bw + 20,"h":HZ51_ROW,"bx":bx,"bw":bw});
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
            this.hz51Stroke(g,hxx,hy,hw,HZ51_DD_H,hexOn ? acc : uint(T.txt),hexOn ? 1 : 0.40,6);
            this.hz51T(b,"#" + hx,hxx + 10,hy + 6,hw - 16,12,"sb",uint(T.txt),0.4);
            var col:int = this.hzParseHex(hx);
            if(col >= 0) { g.beginFill(uint(col),1); g.drawRoundRect(hxx - 26,cy - 11,22,22,4,4); g.endFill(); this.hz51Stroke(g,hxx - 26,cy - 11,22,22,uint(T.txt),0.40,4); }
            this.hzSetHits.push({"id":"hex" + i,"x":hxx - 28,"y":y,"w":hw + 32,"h":HZ51_ROW});
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
            var ct:TextField = this.hz51T(b,txt,0,cy - 8,220,12,"bd",vcol,0.3);
            var cw:Number = Math.max(HZ51_CTRL_W,Math.round(this.hzTW(ct) + 36));
            var cx:Number = Math.round(R - cw);
            var dy:Number = Math.round(cy - HZ51_DD_H / 2);
            b.removeChild(ct);
            g.beginFill(uint(T.tile),0.92); g.drawRoundRect(cx,dy,cw,HZ51_DD_H,6,6); g.endFill();
            this.hz51Stroke(g,cx,dy,cw,HZ51_DD_H,this.hzSetDrop == i ? acc : uint(T.txt),this.hzSetDrop == i ? 0.70 : 0.22,6);
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
         else if(r.t == "x") { this.hz51Btn(b,g,R,cy,r.btn != undefined ? String(r.btn) : "OPEN",rh,T,"row" + i); }
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
            this.hzWT(b,"Turn on Extended Mode to bind keys. Saved keys are kept.",x0 + 16,y + 8,innerW - 24,12,"rg",uint(T.mut),0.1,"left",12);
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
         this.hz51T(b,"Click a chip to bind. Esc cancels. Orange is a clash.",x0 + 12,y + 12,Math.max(80,btnX - x0 - 20),10,"rg",uint(T.mut),0.1);
         g.beginFill(uint(T.fill),0.70);
         g.drawRoundRect(btnX,btnY,btnW,btnH,6,6);
         g.endFill();
         this.hz51Stroke(g,btnX,btnY,btnW,btnH,dis ? uint(T.mut) : acc,dis ? 0.35 : 0.7,6);
         this.hz51T(b,"CLEAR ALL KEYS",btnX + btnW / 2,btnY + 4,btnW,9,"sb",dis ? uint(T.mut) : acc,0.8,"center");
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
            if(cap) { kn = this.hzQmCapCand.length > 0 ? this.hzQmCapCand : "PRESS ANY KEY…"; }
            else if(kn.length == 0) { kn = "UNBOUND"; }
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
            this.hz51T(b,"SLOT " + n,xx + 8,yy + 6,tw - 16,9,"bd",acc,1.2);
            g.beginFill(uint(T.tile),0.55);
            g.drawRoundRect(xx + 8,yy + 24,14,14,3,3);
            g.endFill();
            this.hz51T(b,"Empty",xx + 26,yy + 25,tw - 34,9,"rg",uint(T.mut),0.2);
            var chipH:Number = 22;
            var chipY:Number = yy + th - chipH - 8;
            var chipW:Number = tw - 16;
            var chipX:Number = xx + 8;
            g.beginFill(uint(T.tile),0.92);
            g.drawRoundRect(chipX,chipY,chipW,chipH,6,6);
            g.endFill();
            this.hz51Stroke(g,chipX,chipY,chipW,chipH,isClash ? clashCol : (cap ? acc : uint(T.line)),isClash || cap ? 0.9 : 0.4,6);
            var chipCol:uint = isClash ? clashCol : (kn == "UNBOUND" || kn.indexOf("PRESS") == 0 ? uint(T.mut) : uint(T.txt));
            this.hz51T(b,kn,chipX + chipW / 2,chipY + 4,chipW - 4,9,"bd",chipCol,0.4,"center");
            if(isClash) { this.hz51T(b,"CLASH",xx + 8,yy + 42,tw - 16,8,"sb",clashCol,0.8); }
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
         this.hz51T(b,"LIVE PREVIEW",px + 12,py + 12,inn,HZ51_SH_PX,"bd",acc,1.4);
         var pvcX:Number = px + 12;
         var pvcY:Number = py + 30;
         var pvcW:Number = inn;
         g.beginFill(uint(T.fill),0.80);
         g.drawRoundRect(pvcX,pvcY,pvcW,HZ51_PVC_H,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         g.beginFill(acc,0.10);
         g.drawEllipse(pvcX + pvcW * 0.28,pvcY + 8,pvcW * 0.6,48);
         g.endFill();
         this.hz51Stroke(g,pvcX,pvcY,pvcW,HZ51_PVC_H,uint(T.txt),0.14,HZ51_BOX_R);
         var cardW:Number = Math.min(148, pvcW - 20);
         g.beginFill(uint(T.fill),0.88);
         g.drawRoundRect(pvcX + 10,pvcY + 16,cardW,44,6,6);
         g.endFill();
         this.hz51Stroke(g,pvcX + 10,pvcY + 16,cardW,44,uint(T.txt),0.16,6);
         g.beginFill(acc,1); g.drawRoundRect(pvcX + 18,pvcY + 26,Math.min(96,cardW - 20),4,2,2); g.endFill();
         g.beginFill(uint(T.txt),0.40); g.drawRoundRect(pvcX + 18,pvcY + 36,Math.min(72,cardW - 20),3,2,2); g.endFill();
         g.beginFill(uint(T.fill),0.88);
         g.drawRoundRect(pvcX + 10,pvcY + 70,Math.min(108,cardW),28,6,6);
         g.endFill();
         this.hz51Stroke(g,pvcX + 10,pvcY + 70,Math.min(108,cardW),28,uint(T.txt),0.16,6);
         var r:Object = this.hzSetRow >= 0 && this.hzSetRow < rows.length ? rows[this.hzSetRow] : null;
         var cap:String = r != null && r.l != undefined ? String(r.l) : "Pick a setting.";
         var pvn:TextField = this.hz51T(b,cap,px + 12,pvcY + HZ51_PVC_H + 8,inn,11,"rg",uint(T.mut),0.1);
         pvn.wordWrap = true; pvn.multiline = true; pvn.width = inn;
         var dy:Number = pvcY + HZ51_PVC_H + 36;
         this.hz51T(b,"SETTING DETAILS",px + 12,dy,inn,HZ51_SH_PX,"bd",acc,1.4);
         this.hz51Hair(g,px + 12 + 118,dy + 12,Math.max(8,inn - 118),1,acc,HZ51_SH_A);
         var help:String = r != null ? this.hz51HelpOf(String(r.k), r) : "Pick a setting to see what it does.";
         var title:String = r != null && r.l != undefined ? String(r.l) : "";
         if(title.length > 0) { this.hz51T(b,title,px + 12,dy + 20,inn,HZ51_TITLE_PX,"bd",uint(T.txt),0.8); }
         var tf:TextField = this.hz51T(b,help,px + 12,dy + 40,inn,HZ51_HELP_PX,"rg",uint(T.lab),0.1);
         tf.wordWrap = true; tf.multiline = true; tf.width = inn; tf.text = help;
         this.hzMsglogWrap(tf,inn,Math.max(64, H - HZ51_FOOT - dy - 56));
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
      private function hz51DrawFooter(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var fy:Number = H - HZ51_FOOT;
         this.hz51Hair(g,0,fy,W,1,uint(T.txt),0.10);
         var hx:Number = 16;
         var by:Number = fy + 12;
         if(this.hz51Pad)
         {
            this.hz51T(b,"CONTROLLER",hx,by + 2,88,9,"bd",uint(T.mut),1.2);
            hx = 108;
            for each(var ck:Array in [["LB/RB","TABS"],["D-PAD","MOVE"],["A","SELECT"],["B","BACK"]])
            {
               var ckw:Number = this.hzSetKey(b,g,hx,by,String(ck[0]),acc,16,7,9);
               var cl:TextField = this.hz51T(b,String(ck[1]),hx + ckw + 4,by + 2,90,10,"sb",uint(T.lab),0.6);
               hx = Math.round(hx + ckw + 4 + this.hzTW(cl) + 10);
            }
         }
         else
         {
            this.hz51T(b,"KEYBOARD",hx,by + 2,80,9,"bd",uint(T.mut),1.2);
            hx = 100;
            for each(var hk:Array in [["UP/DN","SELECT"],["L/R","CHANGE"],["ENTER","OK"],["ESC","CANCEL"],["/","SEARCH"]])
            {
               var hkw:Number = this.hzSetKey(b,g,hx,by,String(hk[0]),uint(T.mut),16,7,9);
               var hl:TextField = this.hz51T(b,String(hk[1]),hx + hkw + 4,by + 2,70,10,"sb",uint(T.lab),0.6);
               hx = Math.round(hx + hkw + 4 + this.hzTW(hl) + 10);
            }
         }
         var bxr:Number = W - 16;
         bxr -= this.hzSetBtn(b,g,bxr,fy + 9,"CANCEL",false,false,this.hzSetHover == "cancel",T,"cancel",11,10) + 6;
         this.hzSetBtn(b,g,bxr,fy + 9,"OK",true,false,this.hzSetHover == "ok",T,"ok",11,10);
      }
      private function hz51DrawFind(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var hits:Array = this.hz51FindHits();
         var lay:Object = this.hz51HeadSlots();
         var w:Number = 360;
         var x:Number = Number(lay.fx) + Number(lay.findW) - w;
         if(x < 8) { x = 8; }
         var y:Number = Number(lay.fy) + HZ51_FIND_H + 6;
         var h:Number = Math.min(220, 12 + Math.max(1,hits.length) * 34 + 28);
         if(hits.length == 0) { h = 56; }
         g.beginFill(uint(T.fill),Math.max(0.96,Number(T.fa))); g.drawRoundRect(x,y,w,h,6,6); g.endFill();
         this.hz51Stroke(g,x,y,w,h,acc,0.40,6);
         if(!this.hzSetFindOn && this.hzSetFind.length == 0) { return; }
         if(hits.length == 0)
         {
            this.hz51T(b,"No settings match",x + 14,y + 18,w - 28,12,"sb",uint(T.mut),0.2);
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
            if(r.t == "a" && r.pal != undefined)
            {
               var pal:Array = r.pal as Array;
               g.beginFill(uint(pal[Math.min(pal.length - 1,oi)]),1); g.drawRoundRect(x + 10,yy + 6,10,10,2,2); g.endFill();
               this.hz51T(b,String(opts[oi]),x + 26,yy + 4,w - 36,11,"sb",sel ? acc : uint(T.txt),0.2);
            }
            else { this.hz51T(b,String(opts[oi]),x + 10,yy + 4,w - 20,11,"sb",sel ? acc : uint(T.txt),0.2); }
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
      }
      private function hz51ListBox() : Object
      {
         var x:Number = HZ51_SIDE_W + 20;
         var y:Number = HZ_SET_TOP + 64;
         var r:Number = this.HZ_SET_W - HZ51_PREV_W - 14;
         return {"x":x,"y":y,"r":r,"w":r - x};
      }
