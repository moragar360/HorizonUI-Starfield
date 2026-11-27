      private var hzSetFocus:int = 0;   // 0 list, 1 sidebar, 2 search, 3 dropdown, 4 hex

      // Purpose: draw the Settings 2.0 window to the approved mockups
      // (cards_status.html / search_jump.html): 1848x1020 window, 268 sidebar,
      // 292 preview, 58px rows, 1px filled-rect dividers, one device hint row.
      // Colors still come from hzSetTheme (player Accent / Card background / Exo 2).
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
         if(this.hzSetPv != null) { this.hzSetPv.visible = false; }
         var T:Object = this.hzSetTheme();
         var acc:uint = uint(T.acc);
         var W:Number = this.HZ_SET_W;
         var H:Number = this.HZ_SET_H;
         var g:* = b.graphics;
         var i:int = 0;
         while(i < 5) { g.beginFill(0x000000,0.07); g.drawRoundRect(-2 - i * 2,4 - i,W + 4 + i * 4,H + 4 + i * 3,(HZ51_WIN_R + i * 2) * 2,(HZ51_WIN_R + i * 2) * 2); g.endFill(); i++; }
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(0,0,W,H,HZ51_WIN_R,HZ51_WIN_R);
         g.endFill();
         this.hz51Stroke(g,0,0,W,H,acc,HZ51_WIN_EA);
         this.hz51DrawHead(b,g,T,acc,W);
         this.hz51DrawTabs(b,g,T,acc,W);
         this.hz51Hair(g,0,HZ51_HEAD + HZ51_TABS - 1,W,1,uint(T.txt),0.10);
         this.hz51DrawSide(b,g,T,acc,H);
         var rows:Array = this.hzSetRows(this.hzSetTab);
         if(this.hzSetRow >= rows.length) { this.hzSetRow = 0; }
         this.hzSetFollow(rows);
         this.hz51DrawList(b,g,T,acc,rows);
         this.hz51DrawRight(b,g,T,acc,rows,H);
         this.hz51DrawFooter(b,g,T,acc,W,H);
         if(this.hzSetFindOn || this.hzSetFind.length > 0) { this.hz51DrawFind(b,g,T,acc,W,H); }
         if(this.hzSetDrop >= 0) { this.hz51DrawDrop(b,g,T,acc,rows,W,H); }
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
         this.hzWT(b,"HORIZON UI",28,18,220,20,"bd",uint(T.txt),4.4);
         this.hzWT(b,"SETTINGS",28 + 168,22,140,12,"sb",uint(T.lab),3.1);
         var hv:String = HZ_BUILD;
         if(this.hz42FileVerOk(this.hzDllFileVer)) { hv = this.hzDllFileVer; }
         var pillW:Number = 88;
         var pillX:Number = 360;
         g.beginFill(uint(T.txt),0.04); g.drawRoundRect(pillX,16,pillW,28,14,14); g.endFill();
         this.hz51Stroke(g,pillX,16,pillW,28,uint(T.txt),0.16);
         g.beginFill(acc,1); g.drawCircle(pillX + 12,30,4); g.endFill();
         this.hzWT(b,"v" + hv,pillX + 20,20,pillW - 24,13,"sb",uint(T.lab),0.8);
         this.hz51DrawCompact(b,g,T,acc,W);
      }
      private function hz51DrawTabs(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var ty:Number = HZ51_HEAD + 12;
         this.hzSetKey(b,g,20,ty + 2,"LB",acc,16,8);
         var tx:Number = 56;
         var i:int = 0;
         var tabTf:Array = [];
         var tabSum:Number = 0;
         while(i < HZ_SET_TABS.length)
         {
            var sel:Boolean = i == this.hzSetTab;
            var hov:Boolean = this.hzSetHover == "tab" + i;
            var tb:TextField = this.hzWT(b,String(HZ_SET_TABS[i]),0,ty,160,13,"bd",sel || hov ? acc : uint(T.mut),2.1);
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
         this.hzSetKey(b,g,tx + 4,ty + 2,"RB",acc,16,8);
      }
      private function hz51HeadRight() : Object
      {
         var W:Number = this.HZ_SET_W;
         var arrW:Number = this.hzSetTab == 4 ? 0 : (this.hzSetTab == 2 ? 168 : 148);
         var ax:Number = W - 28 - arrW;
         var findW:Number = HZ51_FIND_W;
         var fx:Number = ax - (arrW > 0 ? 12 : 0) - findW;
         return {"arrW":arrW,"ax":ax,"findW":findW,"fx":fx,"fy":Math.round((HZ51_HEAD - HZ51_FIND_H) / 2)};
      }
      private function hz51DrawCompact(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var lay:Object = this.hz51HeadRight();
         this.hz51DrawSearchBox(b,g,T,acc,Number(lay.fx),Number(lay.fy),Number(lay.findW));
         if(this.hzSetTab != 4)
         {
            var alab:String = this.hzSetTab == 2 ? "ARRANGE SCANNER" : "ARRANGE CARDS";
            var aid:String = this.hzSetTab == 2 ? "arrscan" : "arrange";
            var aw:Number = Number(lay.arrW);
            var ax:Number = Number(lay.ax);
            var ay:Number = Number(lay.fy);
            var hovA:Boolean = this.hzSetHover == aid;
            g.beginFill(acc,hovA ? 1 : 0.92); g.drawRoundRect(ax,ay,aw,HZ51_FIND_H,6,6); g.endFill();
            this.hzWT(b,alab,ax,ay + 10,aw,12,"bd",uint(T.ontxt),1.7,"center");
            this.hzSetHits.push({"id":aid,"x":ax,"y":ay,"w":aw,"h":HZ51_FIND_H});
         }
         var pon:Boolean = Boolean(this.hzSetPend.Compact);
         var psel:Boolean = this.hzSetHover == "compact";
         var plab:String = "COMPACT MODE (STRIPS)";
         var sw:Number = 42;
         var pt:TextField = this.hzWT(b,plab,0,Number(lay.fy) + 10,240,11,"bd",uint(T.lab),1.5);
         var pw:Number = Math.round(this.hzTW(pt) + 24 + sw + 36);
         var px0:Number = Number(lay.fx) - 12 - pw;
         if(px0 < 470)
         {
            pt.text = "COMPACT";
            pw = Math.round(this.hzTW(pt) + 24 + sw + 36);
            px0 = Number(lay.fx) - 12 - pw;
         }
         var py0:Number = Number(lay.fy);
         g.beginFill(uint(T.txt),0.02);
         g.drawRoundRect(px0,py0,pw,HZ51_FIND_H,18,18);
         g.endFill();
         this.hz51Stroke(g,px0,py0,pw,HZ51_FIND_H,uint(T.txt),psel ? 0.28 : 0.16);
         pt.x = px0 + 16;
         this.hz51Switch(b,g,px0 + pw - 10,py0 + HZ51_FIND_H / 2,pon,T);
         this.hzSetHits.push({"id":"compact","x":px0,"y":py0,"w":pw,"h":HZ51_FIND_H});
      }
      private function hz51DrawSearchBox(b:Sprite, g:*, T:Object, acc:uint, bx:Number, by:Number, bw:Number) : void
      {
         var on:Boolean = this.hzSetFindOn || this.hzSetHover == "findbox";
         g.beginFill(uint(T.fill),0.55);
         g.drawRoundRect(bx,by,bw,HZ51_FIND_H,8,8);
         g.endFill();
         this.hz51Stroke(g,bx,by,bw,HZ51_FIND_H,on ? acc : uint(T.txt),on ? 0.55 : 0.18);
         var txt:String = this.hzSetFindOn || this.hzSetFind.length > 0 ? this.hzSetFind : "Search settings...";
         var col:uint = this.hzSetFindOn || this.hzSetFind.length > 0 ? uint(T.txt) : uint(T.mut);
         this.hzWT(b,txt,bx + 12,by + 10,bw - 20,13,"sb",col,0.4);
         this.hzSetHits.push({"id":"findbox","x":bx,"y":by,"w":bw,"h":HZ51_FIND_H});
      }
      private function hz51Switch(b:Sprite, g:*, R:Number, cy:Number, on:Boolean, T:Object) : void
      {
         var acc:uint = uint(T.acc);
         var sw:Number = 42;
         var sh:Number = 22;
         var sx:Number = Math.round(R - sw);
         var sy:Number = Math.round(cy - sh / 2);
         g.beginFill(on ? acc : uint(T.txt),on ? 0.28 : 0.10);
         g.drawRoundRect(sx,sy,sw,sh,11,11);
         g.endFill();
         this.hz51Stroke(g,sx,sy,sw,sh,on ? acc : uint(T.mut),on ? 1 : 0.85);
         var kn:Number = 16;
         var kx:Number = on ? sx + sw - 2 - kn : sx + 2;
         g.beginFill(on ? acc : uint(T.mut),1);
         g.drawRoundRect(kx,sy + 2,kn,kn,kn,kn);
         g.endFill();
         this.hzWT(b,on ? "ON" : "OFF",sx - 8,Math.round(cy - 8),40,12,"bd",on ? acc : uint(T.mut),1.7,"right");
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
            this.hzWT(b,String(grp.g),x0 + 20,y + 4,w - 28,10,"bd",acc,2.0);
            this.hz51Hair(g,x0 + 20,y + 20,w - 36,1,acc,HZ51_SH_A);
            y += 26;
            var items:Array = grp.items as Array;
            var ii:int = 0;
            while(ii < items.length)
            {
               var it:Object = items[ii];
               var sel:Boolean = pi == this.hz51PageClamp(this.hzSetTab);
               var ih:Number = 52;
               if(sel)
               {
                  g.beginFill(acc,this.hzSetFocus == 1 ? 0.16 : 0.12);
                  g.drawRect(x0,y,w,ih);
                  g.endFill();
                  g.beginFill(acc,1); g.drawRect(x0,y,3,ih); g.endFill();
               }
               else { this.hz51Hair(g,x0 + 20,y + ih - 1,w - 20,1,uint(T.txt),0.04); }
               this.hzWT(b,String(it.l),x0 + 20,y + 11,w - 28,13,"bd",sel ? acc : uint(T.lab),1.6);
               this.hzWT(b,String(it.s),x0 + 20,y + 28,w - 28,11,"rg",uint(T.mut),0.2);
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
         this.hzWT(b,this.hz51Crumb(this.hzSetTab, this.hz51PageClamp(this.hzSetTab)),x0,HZ_SET_TOP + 14,crumbW,11,"sb",uint(T.mut),2.0);
         var pages:Array = this.hz51Pages(this.hzSetTab);
         var pobj:Object = pages[this.hz51PageClamp(this.hzSetTab)];
         var title:String = pobj != null ? String(pobj.l) : "";
         this.hzWT(b,title,x0,HZ_SET_TOP + 30,crumbW,22,"bd",uint(T.txt),3.5);
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
            this.hzWT(b,"No settings in this section.",x0,y + 12,boxW,13,"sb",uint(T.mut),0.3);
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
                  this.hz51Stroke(gMain,boxX,boxY,boxW,Math.max(20,boxH),acc,HZ51_BOX_A);
                  boxOpen = false;
               }
               var shY:Number = y + (firstSec ? 0 : 8);
               var ht:TextField = this.hzWT(b,String(r.h),x0,shY + 8,Math.min(280,boxW * 0.45),11,"bd",acc,2.2);
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
               try { this.hz30ModBanner(b,g,y,right,T,String(r.mod),i == this.hzSetRow,i); } catch(errMb:Error) { }
               y += this.hz34BanH();
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
            var lb35:TextField = this.hzWT(b,String(r.l),labX,y + 9,labW,13,"bd",uint(T.txt),1.6);
            this.hzSetHits.push({"id":"row" + i,"x":x0,"y":y,"w":boxW,"h":HZ51_ROW});
            var inf35:String = r.dis ? null : this.hz35InfoOf(r);
            if(inf35 != null && lb35 != null && String(r.l).length > 0)
            {
               var ix35:Number = Math.round(lb35.x + 2 + Math.min(lb35.width,this.hzTW(lb35)) + 8);
               var ion35:Boolean = this.hzSetHover == "inf" + i || (rs && this.hz35Kb);
               this.hz35InfoIcon(b,g,ix35,y + 16,acc,T,ion35,i);
               if(ion35) { this.hz35Tip = {"t":inf35,"x":ix35,"y":y,"h":HZ51_ROW}; }
            }
            var help:String = r.note != undefined ? String(r.note) : "";
            if(help.length > 0)
            {
               var ht2:TextField = this.hzWT(b,help,labX,y + 28,labW,12,"rg",uint(T.mut),0.1,"left",12);
               ht2.wordWrap = false;
               ht2.multiline = false;
            }
            var v:* = r.dis ? r.dv : this.hzSetPend[r.k];
            var cy:Number = y + Math.round(HZ51_ROW / 2);
            this.hz51DrawCtrl(b,g,r,i,y,R,cy,v,T,acc,rh);
            if(r.t == "md")
            {
               var badge:String = String(r.badge);
               var bt:TextField = this.hzWT(b,badge,0,cy - 8,160,10,"bd",acc,1.4);
               var bw:Number = Math.round(this.hzTW(bt) + 16);
               var bx:Number = Math.round(R - bw);
               var by:Number = Math.round(cy - 10);
               bt.x = bx + 8;
               bt.y = by + 1;
               g.beginFill(acc,0.14); g.drawRoundRect(bx,by,bw,20,4,4); g.endFill();
               this.hz51Stroke(g,bx,by,bw,20,acc,0.55);
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
            this.hz51Stroke(gMain,boxX,boxY,boxW,Math.max(20,boxH),acc,HZ51_BOX_A);
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
            this.hzWT(b,vlab,R,cy - 9,50,14,"bd",acc,0.5,"right");
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
            this.hz51Stroke(g,hxx,hy,hw,HZ51_DD_H,hexOn ? acc : uint(T.txt),hexOn ? 1 : 0.40);
            this.hzWT(b,"#" + hx,hxx + 12,hy + 8,hw - 16,13,"sb",uint(T.txt),1.0);
            var col:int = this.hzParseHex(hx);
            if(col >= 0) { g.beginFill(uint(col),1); g.drawRoundRect(hxx - 26,cy - 11,22,22,4,4); g.endFill(); this.hz51Stroke(g,hxx - 26,cy - 11,22,22,uint(T.txt),0.40); }
            this.hzSetHits.push({"id":"hex" + i,"x":hxx - 28,"y":y,"w":hw + 32,"h":HZ51_ROW});
         }
         else if(r.t == "r" || r.t == "q" || r.t == "l" || r.t == "c" || r.t == "a" || r.t == "p")
         {
            var txt:String = "";
            if(r.t == "p") { var p:Object = this.hz37Cur(); txt = p != null ? String(p.n) : "NONE"; }
            else if(r.t == "r") { txt = String((r.opts as Array)[Math.max(0,Math.min((r.opts as Array).length - 1,this.hz29OptIdx(r,v)))]); }
            else if(r.t == "q") { txt = String(HZ_RULE_NAMES[Math.max(0,Math.min(HZ_RULE_NAMES.length - 1,int(v)))]); if(r.opts != undefined) { txt = String((r.opts as Array)[Math.max(0,this.hz29OptIdx(r,v))]); } }
            else if(r.t == "l") { txt = String((r.names as Array)[this.hzSetListIdx(r,v)]); }
            else if(r.t == "c") { txt = String(v); }
            else if(r.t == "a") { txt = String((r.names as Array)[Math.max(0,Math.min((r.names as Array).length - 1,int(v)))]); }
            var ct:TextField = this.hzWT(b,txt,0,cy - 9,260,13,"sb",vcol,0.5);
            var cw:Number = Math.max(148,Math.round(this.hzTW(ct) + 36));
            var cx:Number = Math.round(R - cw);
            var dy:Number = Math.round(cy - HZ51_DD_H / 2);
            b.removeChild(ct);
            g.beginFill(uint(T.fill),0.70); g.drawRoundRect(cx,dy,cw,HZ51_DD_H,6,6); g.endFill();
            this.hz51Stroke(g,cx,dy,cw,HZ51_DD_H,this.hzSetDrop == i ? acc : uint(T.txt),this.hzSetDrop == i ? 0.70 : 0.22);
            if(r.t == "a")
            {
               var pal:Array = r.pal as Array;
               var ai:int = Math.max(0,Math.min(pal.length - 1,int(v)));
               g.beginFill(uint(pal[ai]),1); g.drawRoundRect(cx + 10,cy - 6,12,12,2,2); g.endFill();
               this.hzWT(b,txt,cx + 28,dy + 8,cw - 44,13,"sb",vcol,0.4);
            }
            else { this.hzWT(b,txt,cx + 12,dy + 8,cw - 32,13,"sb",vcol,0.4); }
            g.beginFill(uint(T.lab),0.9);
            g.moveTo(cx + cw - 18,cy - 2); g.lineTo(cx + cw - 8,cy - 2); g.lineTo(cx + cw - 13,cy + 4); g.lineTo(cx + cw - 18,cy - 2);
            g.endFill();
            this.hzSetHits.push({"id":"dd" + i,"x":cx,"y":dy,"w":cw,"h":HZ51_DD_H});
            if(this.hzSetDrop == i) { this.hzSetDropBox = {"x":cx,"y":dy,"w":cw,"h":HZ51_DD_H}; }
         }
         else if(r.t == "x" && String(r.k).indexOf("_hz37") == 0) { this.hz37DrawBtn(b,g,r,i,R,cy,rh,T); }
         else if(r.t == "x") { this.hzSetBtn(b,g,R,cy - 14,r.btn != undefined ? String(r.btn) : "OPEN",false,true,rh,T,"row" + i); }
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
         var helpW:Number = Math.max(120, innerW - 148);
         var ht:TextField = this.hzWT(b,"Click a key chip to bind. Esc cancels. Backspace or Delete clears. Orange means a clash: Enter uses a game key anyway or moves a slot key here; the settings key is refused. Tiles are slots 13 through Slot Count, wrapped by Slots per Row. Slots 1-12 keep the game's own favorite keys.",x0 + 16,y + 8,helpW,12,"rg",uint(T.mut),0.05,"left",12);
         ht.wordWrap = true;
         ht.multiline = true;
         var btnW:Number = 118;
         var btnH:Number = 22;
         var btnX:Number = Math.round(x0 + innerW - btnW - 12);
         var btnY:Number = y + 8;
         g.beginFill(uint(T.fill),0.70);
         g.drawRoundRect(btnX,btnY,btnW,btnH,6,6);
         g.endFill();
         this.hz51Stroke(g,btnX,btnY,btnW,btnH,dis ? uint(T.mut) : acc,dis ? 0.35 : 0.7);
         this.hzWT(b,"CLEAR ALL KEYS",btnX,btnY + 4,btnW,9,"sb",dis ? uint(T.mut) : acc,0.8,"center");
         if(!dis) { this.hzSetHits.push({"id":"qmclr","x":btnX,"y":btnY,"w":btnW,"h":btnH}); }
         y += HZ51_QM_HEAD;
         var count:int = this.hz51QmCount();
         var per:int = this.hz51QmPer();
         var n:int = 13;
         var col:int = 0;
         var row:int = 0;
         var tw:Number = (innerW - 20 - (per - 1) * HZ51_QM_GAP) / per;
         if(tw < 48) { tw = 48; }
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
            this.hz51Stroke(g,xx,yy,tw,th,bcol,cap || isClash ? 0.85 : 0.22);
            this.hzWT(b,"SLOT " + n,xx + 6,yy + 4,tw - 12,8,"sb",acc,1.4);
            g.beginFill(uint(T.tile),0.55);
            g.drawRoundRect(xx + 6,yy + 18,16,16,4,4);
            g.endFill();
            this.hzWT(b,"Empty",xx + 26,yy + 20,tw - 34,9,"rg",uint(T.mut),0.2);
            var chipH:Number = 18;
            var chipY:Number = yy + th - chipH - 8;
            var chipW:Number = tw - 12;
            var chipX:Number = xx + 6;
            g.beginFill(uint(T.fill),0.7);
            g.drawRoundRect(chipX,chipY,chipW,chipH,6,6);
            g.endFill();
            this.hz51Stroke(g,chipX,chipY,chipW,chipH,isClash ? clashCol : (cap ? acc : uint(T.line)),isClash || cap ? 0.9 : 0.4);
            var chipCol:uint = isClash ? clashCol : (kn == "UNBOUND" || kn == "PRESS ANY KEY…" ? uint(T.mut) : acc);
            this.hzWT(b,kn,chipX,chipY + 2,chipW,9,"sb",chipCol,0.4,"center");
            if(isClash) { this.hzWT(b,"CLASH",xx + 6,yy + 38,tw - 12,8,"sb",clashCol,0.8); }
            if(!dis) { this.hzSetHits.push({"id":"qmk" + n,"x":chipX,"y":chipY,"w":chipW,"h":chipH}); }
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
         this.hzWT(b,"LIVE PREVIEW",px + 18,py + 16,HZ51_PREV_W - 36,11,"bd",acc,2.2);
         var pvcX:Number = px + 18;
         var pvcY:Number = py + 38;
         var pvcW:Number = HZ51_PREV_W - 36;
         g.beginFill(uint(T.fill),0.80);
         g.drawRoundRect(pvcX,pvcY,pvcW,HZ51_PVC_H,HZ51_BOX_R,HZ51_BOX_R);
         g.endFill();
         g.beginFill(acc,0.12);
         g.drawEllipse(pvcX + pvcW * 0.35,pvcY - 20,pvcW * 0.7,90);
         g.endFill();
         this.hz51Stroke(g,pvcX,pvcY,pvcW,HZ51_PVC_H,uint(T.txt),0.14);
         g.beginFill(uint(T.fill),0.88);
         g.drawRoundRect(pvcX + 18,pvcY + 22,168,58,6,6);
         g.endFill();
         this.hz51Stroke(g,pvcX + 18,pvcY + 22,168,58,uint(T.txt),0.16);
         g.beginFill(acc,1); g.drawRoundRect(pvcX + 28,pvcY + 36,110,5,2,2); g.endFill();
         g.beginFill(uint(T.txt),0.40); g.drawRoundRect(pvcX + 28,pvcY + 48,88,4,2,2); g.endFill();
         g.beginFill(acc,0.55); g.drawRoundRect(pvcX + 28,pvcY + 58,64,4,2,2); g.endFill();
         g.beginFill(uint(T.fill),0.88);
         g.drawRoundRect(pvcX + 18,pvcY + 96,120,36,6,6);
         g.endFill();
         this.hz51Stroke(g,pvcX + 18,pvcY + 96,120,36,uint(T.txt),0.16);
         g.beginFill(uint(T.txt),0.40); g.drawRoundRect(pvcX + 28,pvcY + 110,70,4,2,2); g.endFill();
         var r:Object = this.hzSetRow >= 0 && this.hzSetRow < rows.length ? rows[this.hzSetRow] : null;
         var cap:String = r != null && r.l != undefined ? String(r.l) : "Pick a setting.";
         var pvn:TextField = this.hzWT(b,cap,px + 18,pvcY + HZ51_PVC_H + 10,HZ51_PREV_W - 36,12,"rg",uint(T.mut),0.1,"left",12);
         pvn.wordWrap = true; pvn.multiline = true; pvn.width = HZ51_PREV_W - 36;
         var dy:Number = pvcY + HZ51_PVC_H + 48;
         this.hzWT(b,"SETTING DETAILS",px + 18,dy,HZ51_PREV_W - 36,11,"bd",acc,2.2);
         this.hz51Hair(g,px + 18 + 130,dy + 14,HZ51_PREV_W - 36 - 130,1,acc,HZ51_SH_A);
         var help:String = r != null ? this.hz51HelpOf(String(r.k), r) : "Pick a setting to see what it does.";
         var title:String = r != null && r.l != undefined ? String(r.l) : "";
         if(title.length > 0) { this.hzWT(b,title,px + 18,dy + 24,HZ51_PREV_W - 36,13,"bd",uint(T.txt),1.8); }
         var tf:TextField = this.hzWT(b,help,px + 18,dy + 46,HZ51_PREV_W - 36,13,"rg",uint(T.lab),0.1,"left",12);
         tf.wordWrap = true; tf.multiline = true; tf.width = HZ51_PREV_W - 36; tf.text = help;
         this.hzMsglogWrap(tf,HZ51_PREV_W - 36,Math.max(80, H - HZ51_FOOT - dy - 70));
         if(r != null && this.hz51On(String(r.k)) && String(r.k).indexOf("Show") == 0 && r.k != "ShowFollowers" && r.k != "ShowLocations" && r.k != "ShowShip" && r.k != "ShowEnemies" && r.k != "ShowPlayerMarker" && r.k != "ShowSpeaker" && r.k != "ShowTarget")
         {
            var ruleK:String = String(r.k).substr(4) + "Rule";
            if(r.k == "ShowAmmo") { ruleK = "AmmoRule"; }
            if(this.hzSetPend[ruleK] != undefined && int(this.hzSetPend[ruleK]) != 0)
            {
               var hint:String = "This card stays on. It only appears when Show when says so. That is not a fault.";
               this.hzWT(b,hint,px + 18,dy + 46 + tf.textHeight + 12,HZ51_PREV_W - 36,12,"rg",uint(T.mut),0.2,"left",12);
            }
         }
      }
      private function hz51DrawFooter(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var fy:Number = H - HZ51_FOOT;
         this.hz51Hair(g,0,fy,W,1,uint(T.txt),0.10);
         var hx:Number = 24;
         var by:Number = fy + 16;
         if(this.hz51Pad)
         {
            this.hzWT(b,"CONTROLLER",hx,by + 2,96,10,"bd",uint(T.mut),1.8);
            hx = 128;
            for each(var ck:Array in [["LB/RB","TABS"],["D-PAD","SECTION / SETTING"],["A","SELECT"],["B","BACK"],["LS","MOVE"],["RS","SCROLL"]])
            {
               var ckw:Number = this.hzSetKey(b,g,hx,by,String(ck[0]),acc,18,8);
               var cl:TextField = this.hzWT(b,String(ck[1]),hx + ckw + 4,by + 3,140,11,"sb",uint(T.lab),1.0);
               hx = Math.round(hx + ckw + 4 + this.hzTW(cl) + 12);
            }
         }
         else
         {
            this.hzWT(b,"KEYBOARD",hx,by + 2,96,10,"bd",uint(T.mut),1.8);
            hx = 128;
            for each(var hk:Array in [["UP/DN","SELECT"],["L/R","CHANGE"],["PGUP","TAB"],["ENTER","OK"],["ESC","CANCEL"],["/","SEARCH"]])
            {
               var hkw:Number = this.hzSetKey(b,g,hx,by,String(hk[0]),uint(T.mut),18,8);
               var hl:TextField = this.hzWT(b,String(hk[1]),hx + hkw + 4,by + 3,80,11,"sb",uint(T.lab),1.0);
               hx = Math.round(hx + hkw + 4 + this.hzTW(hl) + 12);
            }
         }
         var bxr:Number = W - 24;
         bxr -= this.hzSetBtn(b,g,bxr,fy + 12,"CANCEL",false,false,this.hzSetHover == "cancel",T,"cancel") + 8;
         this.hzSetBtn(b,g,bxr,fy + 12,"OK",true,false,this.hzSetHover == "ok",T,"ok");
      }
      private function hz51DrawFind(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var hits:Array = this.hz51FindHits();
         var lay:Object = this.hz51HeadRight();
         var w:Number = 440;
         var x:Number = Number(lay.fx) + Number(lay.findW) - w;
         if(x < 8) { x = 8; }
         var y:Number = Number(lay.fy) + HZ51_FIND_H + 6;
         var h:Number = Math.min(280, 12 + Math.max(1,hits.length) * 40 + 36);
         if(hits.length == 0) { h = 72; }
         g.beginFill(uint(T.fill),Math.max(0.92,Number(T.fa))); g.drawRoundRect(x,y,w,h,8,8); g.endFill();
         this.hz51Stroke(g,x,y,w,h,acc,0.40);
         if(!this.hzSetFindOn && this.hzSetFind.length == 0) { return; }
         if(hits.length == 0)
         {
            this.hzWT(b,"No settings match",x + 16,y + 22,w - 32,13,"sb",uint(T.mut),0.3);
            return;
         }
         if(this.hzSetFindHi >= hits.length) { this.hzSetFindHi = 0; }
         var i:int = 0;
         var yy:Number = y + 6;
         while(i < hits.length && yy + 40 < y + h - 28)
         {
            var hit:Object = hits[i];
            var sel:Boolean = i == this.hzSetFindHi;
            if(sel) { g.beginFill(acc,0.24); g.drawRect(x + 4,yy,w - 8,38); g.endFill(); g.beginFill(acc,1); g.drawRect(x + 4,yy,3,38); g.endFill(); }
            this.hzWT(b,String(hit.l),x + 16,yy + 4,w - 28,13,"sb",sel ? acc : uint(T.txt),0.4);
            this.hzWT(b,String(hit.crumb),x + 16,yy + 20,w - 28,11,"rg",uint(T.mut),0.4);
            this.hzSetHits.push({"id":"fhit" + i,"x":x + 4,"y":yy,"w":w - 8,"h":38});
            yy += 40;
            i++;
         }
      }
      private function hz51DrawDrop(b:Sprite, g:*, T:Object, acc:uint, rows:Array, W:Number, H:Number) : void
      {
         if(this.hzSetDrop < 0 || this.hzSetDrop >= rows.length) { return; }
         var r:Object = rows[this.hzSetDrop];
         var opts:Array = this.hz51DropOpts(r);
         if(opts == null || opts.length == 0) { this.hzSetDrop = -1; return; }
         var menuW:Number = 220;
         if(this.hzSetDropBox != null) { menuW = Math.max(220, Number(this.hzSetDropBox.w)); }
         var menuH:Number = Math.min(260, 12 + opts.length * 28);
         var ctrl:Object = this.hzSetDropBox;
         if(ctrl == null)
         {
            var box:Object = this.hz51ListBox();
            ctrl = {"x":Number(box.r) - menuW,"y":Number(box.y),"w":menuW,"h":HZ51_DD_H};
         }
         var place:Object = this.hz51DropRect(Number(ctrl.x),Number(ctrl.y),Number(ctrl.w),Number(ctrl.h),menuW,menuH,W,H,HZ51_FOOT,HZ_SET_TOP);
         var x:Number = Number(place.x);
         var y:Number = Number(place.y);
         var w:Number = Number(place.w);
         var h:Number = Number(place.h);
         g.beginFill(uint(T.fill),Math.max(0.92,Number(T.fa))); g.drawRoundRect(x,y,w,h,8,8); g.endFill();
         this.hz51Stroke(g,x,y,w,h,acc,0.40);
         if(this.hzSetDropHi < 0) { this.hzSetDropHi = 0; }
         if(this.hzSetDropHi >= opts.length) { this.hzSetDropHi = opts.length - 1; }
         var i:int = 0;
         while(i < opts.length)
         {
            var yy:Number = y + 6 + i * 28;
            var sel:Boolean = i == this.hzSetDropHi;
            if(sel) { g.beginFill(acc,0.18); g.drawRoundRect(x + 4,yy,w - 8,26,5,5); g.endFill(); }
            if(r.t == "a" && r.pal != undefined)
            {
               var pal:Array = r.pal as Array;
               g.beginFill(uint(pal[Math.min(pal.length - 1,i)]),1); g.drawRoundRect(x + 12,yy + 7,12,12,2,2); g.endFill();
               this.hzWT(b,String(opts[i]),x + 30,yy + 5,w - 42,13,"sb",sel ? acc : uint(T.lab),0.4);
            }
            else { this.hzWT(b,String(opts[i]),x + 12,yy + 5,w - 24,13,"sb",sel ? acc : uint(T.lab),0.4); }
            this.hzSetHits.push({"id":"dopt" + i,"x":x + 4,"y":yy,"w":w - 8,"h":26});
            i++;
         }
      }
      private function hz51Key(code:String) : Boolean
      {
         this.hz51NotePad(code);
         if(this.hzSetFindOn)
         {
            if(code == "cancel") { this.hzSetFindOn = false; this.hzSetFind = ""; this.hzSetFocus = 0; this.hzSetGlowK = ""; return true; }
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
               return true;
            }
            if(code == "ok" || code == "right")
            {
               this.hz51DropPick(rr, this.hzSetDropHi);
               this.hzSetDrop = -1;
               this.hzSetFocus = 0;
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
         this.hzSetFocus = 3;
         if(r.t == "r") { this.hzSetDropHi = Math.max(0,this.hz29OptIdx(r,this.hzSetPend[r.k])); }
         else if(r.t == "q") { var ids:Array = r.ids as Array; this.hzSetDropHi = Math.max(0,ids.indexOf(int(this.hzSetPend[r.k]))); }
         else if(r.t == "l") { this.hzSetDropHi = this.hzSetListIdx(r,this.hzSetPend[r.k]); }
         else if(r.t == "a" || r.t == "c") { this.hzSetDropHi = Math.max(0,int(this.hzSetPend[r.k])); if(r.t == "c") { this.hzSetDropHi = Math.max(0,HZ_SET_KEYS.indexOf(String(this.hzSetPend[r.k]))); } }
      }
      private function hz51ListBox() : Object
      {
         var x:Number = HZ51_SIDE_W + 28;
         var y:Number = HZ_SET_TOP + 64;
         var r:Number = this.HZ_SET_W - HZ51_PREV_W - 18;
         return {"x":x,"y":y,"r":r,"w":r - x};
      }
