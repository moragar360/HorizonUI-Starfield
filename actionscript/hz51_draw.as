      private var hzSetFocus:int = 0;   // 0 list, 1 sidebar, 2 search, 3 dropdown, 4 hex

      // Purpose: draw the Settings 2.0 window. Layout matches the approved mockups
      // (header compact + search, grouped sidebar, table boxes, help lines, preview,
      // dual footer). Colors come from hzSetTheme (player Accent / Background).
      // Inputs: hzSetPend while F11 is open. Outputs: redrawn HorizonSettings_mc.
      // Author: Moragar. Last modified: 2026-11-26.
      private function hz51Draw() : void
      {
         if(!this.HorizonSettings_mc || !this.hzSetPend) { return; }
         var b:Sprite = this.hzSetBody;
         while(b.numChildren > 0) { b.removeChildAt(0); }
         b.graphics.clear();
         this.hzSetKeyOv.graphics.clear();
         this.hzSetHits = [];
         this.hzSetSideHits = [];
         var T:Object = this.hzSetTheme();
         var acc:uint = uint(T.acc);
         var W:Number = HZ_SET_W;
         var H:Number = HZ_SET_H;
         var g:* = b.graphics;
         var i:int = 0;
         i = 0;
         while(i < 5) { g.beginFill(0x000000,0.07); g.drawRoundRect(-2 - i * 2,4 - i,W + 4 + i * 4,H + 4 + i * 3,(14 + i * 2) * 2,(14 + i * 2) * 2); g.endFill(); i++; }
         g.beginFill(uint(T.fill),Number(T.fa));
         g.drawRoundRect(0,0,W,H,14,14);
         g.endFill();
         this.hz33Edge(b,0,0,W,H,14,acc,0.28,1);
         this.hz51DrawHead(b,g,T,acc,W);
         this.hz51DrawTabs(b,g,T,acc,W);
         g.beginFill(uint(T.line),Number(T.la)); g.drawRect(0,74,W,1); g.endFill();
         this.hz51DrawSide(b,g,T,acc);
         var rows:Array = this.hzSetRows(this.hzSetTab);
         if(this.hzSetRow >= rows.length) { this.hzSetRow = 0; }
         this.hzSetFollow(rows);
         this.hz51DrawList(b,g,T,acc,rows);
         this.hz51DrawRight(b,g,T,acc,rows);
         this.hz51DrawFooter(b,g,T,acc,W,H);
         if(this.hzSetFindOn || this.hzSetFind.length > 0) { this.hz51DrawFind(b,g,T,acc,W,H); }
         if(this.hzSetDrop >= 0) { this.hz51DrawDrop(b,g,T,acc,rows); }
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
         g.beginFill(uint(T.line),Number(T.la)); g.drawRect(0,40,W,1); g.endFill();
         this.hzWT(b,"HORIZON UI",24,12,220,16,"bd",uint(T.txt),2.2);
         this.hzWT(b,"SETTINGS",24 + 132,16,120,10,"sb",uint(T.mut),2.6);
         var hv:String = HZ_BUILD;
         if(this.hz42FileVerOk(this.hzDllFileVer)) { hv = this.hzDllFileVer; }
         var pillW:Number = 70;
         var pillX:Number = 248;
         g.beginFill(uint(T.txt),0.04); g.drawRoundRect(pillX,10,pillW,20,20,20); g.endFill();
         this.hz33Edge(b,pillX,10,pillW,20,20,uint(T.txt),0.16,1);
         g.beginFill(acc,1); g.drawCircle(pillX + 10,20,3.5); g.endFill();
         this.hzWT(b,"v" + hv,pillX + 16,13,pillW - 20,10,"sb",uint(T.mut),0.4);
         this.hz51DrawCompact(b,g,T,acc,W);
         this.hz51DrawSearchBox(b,g,T,acc,W);
         if(this.hzSetTab != 4)
         {
            var alab:String = this.hzSetTab == 2 ? "ARRANGE SCANNER" : "ARRANGE CARDS";
            var aid:String = this.hzSetTab == 2 ? "arrscan" : "arrange";
            var aw:Number = this.hzSetTab == 2 ? 150 : 128;
            var ax:Number = W - 24 - aw;
            var hovA:Boolean = this.hzSetHover == aid;
            g.beginFill(acc,hovA ? 1 : 0.92); g.drawRoundRect(ax,8,aw,24,6,6); g.endFill();
            this.hzWT(b,alab,ax,13,aw,10,"sb",uint(T.ontxt),1.4,"center");
            this.hzSetHits.push({"id":aid,"x":ax,"y":8,"w":aw,"h":24});
         }
      }
      private function hz51DrawTabs(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var tx:Number = 48;
         var ty:Number = 48;
         this.hzSetKey(b,g,24,ty + 4,"LB",acc,16,8);
         var i:int = 0;
         var tabTf:Array = [];
         var tabSum:Number = 0;
         while(i < HZ_SET_TABS.length)
         {
            var sel:Boolean = i == this.hzSetTab;
            var hov:Boolean = this.hzSetHover == "tab" + i;
            var tb:TextField = this.hzWT(b,String(HZ_SET_TABS[i]),0,ty,140,11,"sb",sel || hov ? acc : uint(T.mut),1.6);
            tabTf.push(tb);
            tabSum += Math.round(this.hzTW(tb));
            i++;
         }
         var tgap:Number = Math.max(10,Math.min(22,Math.floor((W - 200 - tabSum) / Math.max(1,HZ_SET_TABS.length - 1))));
         i = 0;
         while(i < tabTf.length)
         {
            var tbx:TextField = tabTf[i] as TextField;
            var tw:Number = Math.round(this.hzTW(tbx));
            tbx.x = Math.round(tx - 2);
            if(i == this.hzSetTab) { g.beginFill(acc,1); g.drawRect(tx,70,tw,2); g.endFill(); }
            this.hzSetHits.push({"id":"tab" + i,"x":tx - 6,"y":ty - 6,"w":tw + 12,"h":30});
            tx += tw + tgap;
            i++;
         }
         this.hzSetKey(b,g,tx + 4,ty + 4,"RB",acc,16,8);
      }
      private function hz51DrawCompact(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var pon:Boolean = Boolean(this.hzSetPend.Compact);
         var psel:Boolean = this.hzSetHover == "compact";
         var plab:String = "COMPACT MODE (STRIPS)";
         var pt:TextField = this.hzWT(b,plab,0,14,240,9,"sb",uint(T.mut),1.4);
         var pw:Number = Math.round(this.hzTW(pt) + 14 + 52);
         var arrW:Number = this.hzSetTab == 4 ? 0 : (this.hzSetTab == 2 ? 160 : 138);
         var px0:Number = W - 24 - arrW - 8 - 186 - 8 - pw;
         if(px0 < 330) { pt.text = "COMPACT"; pw = Math.round(this.hzTW(pt) + 14 + 52); px0 = W - 24 - arrW - 8 - 186 - 8 - pw; }
         var py0:Number = 8;
         g.beginFill(0,0);
         this.hz33Edge(b,px0,py0,pw,24,18,uint(T.txt),psel ? 0.28 : 0.16,1);
         pt.x = px0 + 12;
         this.hzSetSwitch(b,g,px0 + pw - 8,py0 + 12,pon,T,true);
         this.hzSetHits.push({"id":"compact","x":px0,"y":py0,"w":pw,"h":24});
      }
      private function hz51DrawSearchBox(b:Sprite, g:*, T:Object, acc:uint, W:Number) : void
      {
         var arrW:Number = this.hzSetTab == 4 ? 0 : (this.hzSetTab == 2 ? 160 : 138);
         var bw:Number = 186;
         var bx:Number = W - 24 - arrW - (arrW > 0 ? 8 : 0) - bw;
         var by:Number = 8;
         var on:Boolean = this.hzSetFindOn || this.hzSetHover == "findbox";
         g.beginFill(uint(T.fill),0.55);
         g.drawRoundRect(bx,by,bw,24,8,8);
         g.endFill();
         this.hz33Edge(b,bx,by,bw,24,8,on ? acc : uint(T.txt),on ? 0.55 : 0.18,1);
         var txt:String = this.hzSetFindOn || this.hzSetFind.length > 0 ? this.hzSetFind : "Search settings...";
         var col:uint = this.hzSetFindOn || this.hzSetFind.length > 0 ? uint(T.txt) : uint(T.mut);
         this.hzWT(b,txt,bx + 12,by + 5,bw - 20,11,"rg",col,0.2);
         this.hzSetHits.push({"id":"findbox","x":bx,"y":by,"w":bw,"h":24});
      }
      private function hz51DrawSide(b:Sprite, g:*, T:Object, acc:uint) : void
      {
         var x0:Number = 0;
         var y0:Number = 76;
         var w:Number = HZ51_SIDE_W;
         var H:Number = HZ_SET_H - HZ51_FOOT - y0;
         g.beginFill(uint(T.line),Number(T.la)); g.drawRect(w,y0,1,H); g.endFill();
         var groups:Array = this.hz51Side(this.hzSetTab);
         var y:Number = y0 + 6;
         var gi:int = 0;
         var pi:int = 0;
         while(gi < groups.length)
         {
            var grp:Object = groups[gi];
            this.hzWT(b,String(grp.g),x0 + 14,y + 4,w - 24,8,"sb",acc,2.0);
            g.beginFill(acc,0.28); g.drawRect(x0 + 14,y + 18,w - 28,1); g.endFill();
            y += 24;
            var items:Array = grp.items as Array;
            var ii:int = 0;
            while(ii < items.length)
            {
               var it:Object = items[ii];
               var sel:Boolean = pi == this.hz51PageClamp(this.hzSetTab);
               var sideSel:Boolean = sel && this.hzSetFocus == 1;
               if(sel)
               {
                  g.beginFill(acc,sideSel ? 0.18 : 0.12);
                  g.drawRect(x0,y,w,34);
                  g.endFill();
                  g.beginFill(acc,1); g.drawRect(x0,y,3,34); g.endFill();
               }
               this.hzWT(b,String(it.l),x0 + 16,y + 3,w - 22,10,"sb",sel ? acc : uint(T.lab),0.8);
               this.hzWT(b,String(it.s),x0 + 16,y + 17,w - 22,9,"rg",uint(T.mut),0.2);
               this.hzSetHits.push({"id":"side" + pi,"x":x0,"y":y,"w":w,"h":34});
               y += 36;
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
         var R:Number = right - 8;
         var bottom:Number = HZ_SET_H - HZ51_FOOT - 8;
         this.hzWT(b,this.hz51Crumb(this.hzSetTab, this.hz51PageClamp(this.hzSetTab)),x0 + 10,HZ_SET_TOP + 8,right - x0 - 20,9,"sb",uint(T.mut),1.8);
         var pages:Array = this.hz51Pages(this.hzSetTab);
         var pobj:Object = pages[this.hz51PageClamp(this.hzSetTab)];
         var title:String = pobj != null ? String(pobj.l) : "";
         this.hzWT(b,title,x0 + 10,HZ_SET_TOP + 22,right - x0 - 20,16,"bd",uint(T.txt),1.6);
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
         while(li < list.length)
         {
            var r:Object = list[li];
            if(y + this.hzSetRowH(r) - 4 > bottom) { break; }
            var i:int = rows.indexOf(r);
            if(r.h)
            {
               if(boxOpen)
               {
                  this.hz33Edge(bMain,boxX,boxY,boxW,boxH,8,acc,0.18,1);
                  boxOpen = false;
               }
               y += 8;
               var ht:TextField = this.hzWT(b,String(r.h),x0 + 8,y + 2,300,9,"sb",acc,2.0);
               g.beginFill(acc,0.28); g.drawRect(x0 + 12 + Math.min(160,this.hzTW(ht) + 8),y + 10,Math.max(16,boxW - this.hzTW(ht) - 20),1); g.endFill();
               y += 20;
               boxY = y;
               boxH = 8;
               boxOpen = true;
               g.beginFill(uint(T.tile),Number(T.tia) * 0.35 + 0.04);
               g.drawRoundRect(boxX,boxY,boxW,8,8,8);
               g.endFill();
            }
            else if(!boxOpen)
            {
               boxY = y;
               boxH = 8;
               boxOpen = true;
               g.beginFill(uint(T.tile),Number(T.tia) * 0.35 + 0.04);
               g.drawRoundRect(boxX,boxY,boxW,8,8,8);
               g.endFill();
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
               this.hz30Lock(g,x0 + 12,y + 18,11,uint(T.mut),0.95,uint(T.fill));
               b = dimS; g = dimS.graphics;
            }
            var rs:Boolean = i == this.hzSetRow && this.hzSetFocus == 0;
            var rh:Boolean = this.hzSetHover == "row" + i;
            var glow:Boolean = this.hzSetGlowK == String(r.k) && new Date().getTime() < this.hzSetGlowT;
            if(rs || rh || glow)
            {
               g.beginFill(acc,glow ? 0.18 : (rs ? 0.12 : 0.06));
               g.drawRect(x0,y,boxW,HZ51_ROW);
               g.endFill();
               if(rs) { g.beginFill(acc,1); g.drawRect(x0,y,3,HZ51_ROW); g.endFill(); }
            }
            if(li > this.hzSetScroll && !r.h)
            {
               g.beginFill(uint(T.line),Number(T.la)); g.drawRect(x0 + 10,y,boxW - 20,1); g.endFill();
            }
            var labX:Number = r.dis ? x0 + 28 : x0 + 12;
            var lb35:TextField = this.hzWT(b,String(r.l),labX,y + 8,boxW - 200,11,"sb",uint(T.txt),1.2);
            this.hzSetHits.push({"id":"row" + i,"x":x0,"y":y,"w":boxW,"h":HZ51_ROW});
            var inf35:String = r.dis ? null : this.hz35InfoOf(r);
            if(inf35 != null && lb35 != null && String(r.l).length > 0)
            {
               var ix35:Number = Math.round(lb35.x + 2 + Math.min(lb35.width,this.hzTW(lb35)) + 10);
               var ion35:Boolean = this.hzSetHover == "inf" + i || (rs && this.hz35Kb);
               this.hz35InfoIcon(b,g,ix35,y + 16,acc,T,ion35,i);
               if(ion35) { this.hz35Tip = {"t":inf35,"x":ix35,"y":y,"h":HZ51_ROW}; }
            }
            var help:String = r.note != undefined ? String(r.note) : "";
            if(help.length > 0)
            {
               var ht2:TextField = this.hzWT(b,help,labX,y + 28,boxW - 200,10,"rg",uint(T.mut),0.1,"left",11);
               ht2.wordWrap = false;
               ht2.multiline = false;
            }
            var v:* = r.dis ? r.dv : this.hzSetPend[r.k];
            var cy:Number = y + 27;
            this.hz51DrawCtrl(b,g,r,i,y,R,cy,v,T,acc,rh);
            if(r.t == "md")
            {
               var badge:String = String(r.badge);
               var bt:TextField = this.hzWT(b,badge,0,cy - 9,140,9,"sb",acc,1.2);
               var bw:Number = Math.round(this.hzTW(bt) + 16);
               var bx:Number = Math.round(R - bw);
               bt.x = bx + 6;
               g.beginFill(acc,0.14); g.drawRoundRect(bx,cy - 10,bw,20,6,6); g.endFill();
               this.hz33Edge(b,bx,cy - 10,bw,20,6,acc,0.55,1);
            }
            if(r.dis)
            {
               this.hzSetHits.splice(hit0,this.hzSetHits.length - hit0);
               b = bMain; g = gMain;
            }
            y += HZ51_ROW;
            boxH = y - boxY + 4;
            lastShown = li;
            li++;
         }
         if(boxOpen) { this.hz33Edge(bMain,boxX,boxY,boxW,Math.max(20,boxH),8,acc,0.18,1); }
         if(this.hzSetMaxScroll > 0)
         {
            var trX:Number = right + 4;
            var trT:Number = Number(box.y);
            var trH:Number = bottom - trT - 4;
            var shown:int = Math.max(1,lastShown - this.hzSetScroll + 1);
            var tot:int = list.length;
            var thH:Number = Math.max(18,Math.round(trH * shown / tot));
            var thY:Number = Math.round(trT + (trH - thH) * this.hzSetScroll / Math.max(1,this.hzSetMaxScroll));
            gMain.beginFill(uint(T.track),Number(T.ta)); gMain.drawRoundRect(trX,trT,5,trH,3,3); gMain.endFill();
            gMain.beginFill(acc,0.9); gMain.drawRoundRect(trX,thY,5,thH,3,3); gMain.endFill();
            this.hzSetHits.push({"id":"strk","x":trX - 8,"y":trT,"w":19,"h":trH,"ty":trT,"th":trH});
         }
      }
      private function hz51DrawCtrl(b:Sprite, g:*, r:Object, i:int, y:Number, R:Number, cy:Number, v:*, T:Object, acc:uint, rh:Boolean) : void
      {
         var isDef:Boolean = this.hzSetIsDef(String(r.k),v);
         var vcol:uint = isDef ? uint(T.txt) : acc;
         if(r.t == "b") { this.hzSetSwitch(b,g,R,cy,Boolean(v),T); }
         else if(r.t == "n")
         {
            var bw:Number = 148;
            var bx:Number = R - 52 - bw;
            var fr:Number = Math.max(0,Math.min(1,(Number(v) - r.mn) / (r.mx - r.mn)));
            var vlab:String = r.st < 1 ? this.hzSetNum(Number(v)) : String(int(Math.round(Number(v))));
            if(r.pct) { vlab = String(int(Math.round(Number(v)))) + "%"; }
            this.hzWT(b,vlab,R,cy - 9,50,13,"sb",acc,0.5,"right");
            g.beginFill(uint(T.track),Number(T.ta)); g.drawRoundRect(bx,cy - 2,bw,4,4,4); g.endFill();
            if(fr > 0) { g.beginFill(acc,1); g.drawRoundRect(bx,cy - 2,Math.max(4,Math.round(bw * fr)),4,4,4); g.endFill(); }
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
            var hw:Number = 96;
            var hxx:Number = R - hw;
            g.beginFill(uint(T.tile),hexOn ? 0.55 : Number(T.tia)); g.drawRoundRect(hxx,cy - 12,hw,24,6,6); g.endFill();
            this.hz33Edge(b,hxx,cy - 12,hw,24,6,hexOn ? acc : uint(T.line),hexOn ? 1 : 0.5,1);
            this.hzWT(b,"#" + hx,hxx + 8,cy - 9,hw - 16,12,"sb",uint(T.txt),0.3);
            var col:int = this.hzParseHex(hx);
            if(col >= 0) { g.beginFill(uint(col),1); g.drawRoundRect(hxx - 22,cy - 8,14,16,4,4); g.endFill(); }
            this.hzSetHits.push({"id":"hex" + i,"x":hxx - 24,"y":y,"w":hw + 28,"h":HZ51_ROW});
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
            var ct:TextField = this.hzWT(b,txt,0,cy - 9,220,11,"sb",vcol,0.4);
            var cw:Number = Math.max(96,Math.round(this.hzTW(ct) + 28));
            var cx:Number = Math.round(R - cw);
            b.removeChild(ct);
            g.beginFill(uint(T.fill),0.7); g.drawRoundRect(cx,cy - 12,cw,24,6,6); g.endFill();
            this.hz33Edge(b,cx,cy - 12,cw,24,6,this.hzSetDrop == i ? acc : uint(T.txt),this.hzSetDrop == i ? 0.7 : 0.22,1);
            if(r.t == "a")
            {
               var pal:Array = r.pal as Array;
               var ai:int = Math.max(0,Math.min(pal.length - 1,int(v)));
               g.beginFill(uint(pal[ai]),1); g.drawRoundRect(cx + 6,cy - 7,12,14,4,4); g.endFill();
               this.hzWT(b,txt,cx + 22,cy - 9,cw - 36,11,"sb",vcol,0.4);
            }
            else { this.hzWT(b,txt,cx + 10,cy - 9,cw - 28,11,"sb",vcol,0.4); }
            g.beginFill(uint(T.mut),0.9);
            g.moveTo(R - 14,cy - 2); g.lineTo(R - 6,cy - 2); g.lineTo(R - 10,cy + 4); g.lineTo(R - 14,cy - 2);
            g.endFill();
            this.hzSetHits.push({"id":"dd" + i,"x":cx,"y":y,"w":cw,"h":HZ51_ROW});
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
            g.beginFill(acc,rs ? 0.12 : 0.06);
            g.drawRect(x0,y,innerW,gh);
            g.endFill();
            if(rs) { g.beginFill(acc,1); g.drawRect(x0,y,3,gh); g.endFill(); }
         }
         if(rowIdx >= 0) { this.hzSetHits.push({"id":"row" + rowIdx,"x":x0,"y":y,"w":innerW,"h":gh}); }
         var qmOff:Boolean = this.hz30Mod != null && this.hz30Mod["quickmenu"] !== 1;
         if(dis && !qmOff)
         {
            this.hzWT(b,"Turn on Extended Mode to bind keys. Saved keys are kept.",x0 + 12,y + 6,innerW - 24,10,"rg",uint(T.mut),0.1,"left",11);
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
         var ht:TextField = this.hzWT(b,"Click a key chip to bind. Esc cancels. Backspace or Delete clears. Orange means a clash: Enter uses a game key anyway or moves a slot key here; the settings key is refused. Tiles are slots 13 through Slot Count, wrapped by Slots per Row. Slots 1-12 keep the game's own favorite keys.",x0 + 12,y + 6,helpW,10,"rg",uint(T.mut),0.05,"left",11);
         ht.wordWrap = true;
         ht.multiline = true;
         var btnW:Number = 118;
         var btnH:Number = 22;
         var btnX:Number = Math.round(x0 + innerW - btnW - 12);
         var btnY:Number = y + 8;
         g.beginFill(uint(T.tile),Number(T.tia));
         g.drawRoundRect(btnX,btnY,btnW,btnH,6,6);
         g.endFill();
         this.hz33Edge(b,btnX,btnY,btnW,btnH,6,dis ? uint(T.mut) : acc,dis ? 0.35 : 0.7,1);
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
            this.hz33Edge(b,xx,yy,tw,th,8,bcol,cap || isClash ? 0.85 : 0.22,1);
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
            this.hz33Edge(b,chipX,chipY,chipW,chipH,6,isClash ? clashCol : (cap ? acc : uint(T.line)),isClash || cap ? 0.9 : 0.4,1);
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
      private function hz51DrawRight(b:Sprite, g:*, T:Object, acc:uint, rows:Array) : void
      {
         var px:Number = HZ_SET_W - HZ51_PREV_W;
         var py:Number = 76;
         var ph:Number = HZ_SET_H - HZ51_FOOT - py;
         g.beginFill(uint(T.line),Number(T.la)); g.drawRect(px,py,1,ph); g.endFill();
         this.hzWT(b,"LIVE PREVIEW",px + 14,py + 10,HZ51_PREV_W - 24,9,"sb",acc,2.0);
         this.hzSetPvDraw(b,g,px + 12,py + 28,T);
         var dy:Number = py + 248;
         this.hzWT(b,"SETTING DETAILS",px + 14,dy,HZ51_PREV_W - 24,9,"sb",acc,2.0);
         g.beginFill(acc,0.28); g.drawRect(px + 14,dy + 16,HZ51_PREV_W - 28,1); g.endFill();
         var r:Object = this.hzSetRow >= 0 && this.hzSetRow < rows.length ? rows[this.hzSetRow] : null;
         var help:String = r != null ? this.hz51HelpOf(String(r.k), r) : "Pick a setting to see what it does.";
         var title:String = r != null && r.l != undefined ? String(r.l) : "";
         if(title.length > 0) { this.hzWT(b,title,px + 14,dy + 24,HZ51_PREV_W - 28,11,"sb",uint(T.txt),1.4); }
         var tf:TextField = this.hzWT(b,help,px + 14,dy + 44,HZ51_PREV_W - 28,11,"rg",uint(T.lab),0.1,"left",12);
         tf.wordWrap = true; tf.multiline = true; tf.width = HZ51_PREV_W - 28; tf.text = help;
         this.hzMsglogWrap(tf,HZ51_PREV_W - 28,160);
         if(r != null && this.hz51On(String(r.k)) && String(r.k).indexOf("Show") == 0 && r.k != "ShowFollowers" && r.k != "ShowLocations" && r.k != "ShowShip" && r.k != "ShowEnemies" && r.k != "ShowPlayerMarker" && r.k != "ShowSpeaker" && r.k != "ShowTarget")
         {
            var ruleK:String = String(r.k).substr(4) + "Rule";
            if(r.k == "ShowAmmo") { ruleK = "AmmoRule"; }
            if(this.hzSetPend[ruleK] != undefined && int(this.hzSetPend[ruleK]) != 0)
            {
               var hint:String = "This card stays on. It only appears when Show when says so. That is not a fault.";
               this.hzWT(b,hint,px + 14,dy + 44 + tf.textHeight + 12,HZ51_PREV_W - 28,11,"rg",uint(T.mut),0.2,"left",12);
            }
         }
      }
      private function hz51DrawFooter(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var fy:Number = H - HZ51_FOOT;
         g.beginFill(uint(T.line),Number(T.la)); g.drawRect(0,fy,W,1); g.endFill();
         g.beginFill(uint(T.txt),0.015); g.drawRect(0,fy + 50,W,50); g.endFill();
         g.beginFill(uint(T.line),Number(T.la) * 0.7); g.drawRect(0,fy + 50,W,1); g.endFill();
         var hx:Number = 24;
         var by:Number = fy + 14;
         this.hzWT(b,"KEYBOARD",hx,by + 4,88,8,"sb",uint(T.mut),1.8);
         hx = 118;
         for each(var hk:Array in [["UP/DN","SELECT"],["L/R","CHANGE"],["PGUP","TAB"],["ENTER","OK"],["ESC","CANCEL"],["/","SEARCH"]])
         {
            var hkw:Number = this.hzSetKey(b,g,hx,by,String(hk[0]),uint(T.mut),18,8);
            var hl:TextField = this.hzWT(b,String(hk[1]),hx + hkw + 4,by + 3,72,9,"sb",uint(T.lab),1.0);
            hx = Math.round(hx + hkw + 4 + this.hzTW(hl) + 10);
         }
         var bxr:Number = W - 24;
         bxr -= this.hzSetBtn(b,g,bxr,fy + 12,"CANCEL",false,false,this.hzSetHover == "cancel",T,"cancel") + 8;
         this.hzSetBtn(b,g,bxr,fy + 12,"OK",true,false,this.hzSetHover == "ok",T,"ok");
         hx = 24;
         by = fy + 64;
         this.hzWT(b,"CONTROLLER",hx,by + 4,88,8,"sb",uint(T.mut),1.8);
         hx = 118;
         for each(var ck:Array in [["LB/RB","TABS"],["D-PAD","SECTION / SETTING"],["A","SELECT"],["B","BACK"],["LS","MOVE"],["RS","SCROLL"]])
         {
            var ckw:Number = this.hzSetKey(b,g,hx,by,String(ck[0]),acc,18,8);
            var cl:TextField = this.hzWT(b,String(ck[1]),hx + ckw + 4,by + 3,110,9,"sb",uint(T.lab),1.0);
            hx = Math.round(hx + ckw + 4 + this.hzTW(cl) + 10);
         }
      }
      private function hz51DrawFind(b:Sprite, g:*, T:Object, acc:uint, W:Number, H:Number) : void
      {
         var hits:Array = this.hz51FindHits();
         var arrW:Number = this.hzSetTab == 4 ? 0 : (this.hzSetTab == 2 ? 160 : 138);
         var w:Number = 280;
         var x:Number = W - 24 - arrW - (arrW > 0 ? 8 : 0) - 186;
         x = x + 186 - w;
         var y:Number = 36;
         var h:Number = Math.min(240, 40 + Math.max(1,hits.length) * 34 + 28);
         if(hits.length == 0) { h = 72; }
         g.beginFill(uint(T.fill),Math.max(0.94,Number(T.fa))); g.drawRoundRect(x,y,w,h,8,8); g.endFill();
         this.hz33Edge(b,x,y,w,h,8,acc,0.55,1);
         if(!this.hzSetFindOn && this.hzSetFind.length == 0) { return; }
         if(hits.length == 0)
         {
            this.hzWT(b,"No settings match",x + 14,y + 16,w - 28,12,"sb",uint(T.mut),0.3);
            return;
         }
         if(this.hzSetFindHi >= hits.length) { this.hzSetFindHi = 0; }
         var i:int = 0;
         var yy:Number = y + 6;
         while(i < hits.length && yy + 34 < y + h - 24)
         {
            var hit:Object = hits[i];
            var sel:Boolean = i == this.hzSetFindHi;
            if(sel) { g.beginFill(acc,0.18); g.drawRect(x + 4,yy,w - 8,32); g.endFill(); g.beginFill(acc,1); g.drawRect(x + 4,yy,3,32); g.endFill(); }
            this.hzWT(b,String(hit.l),x + 16,yy + 3,w - 28,11,"sb",sel ? acc : uint(T.txt),0.4);
            this.hzWT(b,String(hit.crumb),x + 16,yy + 17,w - 28,9,"rg",uint(T.mut),0.2);
            this.hzSetHits.push({"id":"fhit" + i,"x":x + 4,"y":yy,"w":w - 8,"h":32});
            yy += 34;
            i++;
         }
      }
      private function hz51DrawDrop(b:Sprite, g:*, T:Object, acc:uint, rows:Array) : void
      {
         if(this.hzSetDrop < 0 || this.hzSetDrop >= rows.length) { return; }
         var r:Object = rows[this.hzSetDrop];
         var opts:Array = this.hz51DropOpts(r);
         if(opts == null || opts.length == 0) { this.hzSetDrop = -1; return; }
         var box:Object = this.hz51ListBox();
         var w:Number = 220;
         var h:Number = Math.min(260, 8 + opts.length * 26);
         var x:Number = Number(box.r) - w;
         var y:Number = Number(box.y);
         g.beginFill(uint(T.fill),Math.max(0.95,Number(T.fa))); g.drawRoundRect(x,y,w,h,6,6); g.endFill();
         this.hz33Edge(b,x,y,w,h,6,acc,0.7,1);
         if(this.hzSetDropHi < 0) { this.hzSetDropHi = 0; }
         if(this.hzSetDropHi >= opts.length) { this.hzSetDropHi = opts.length - 1; }
         var i:int = 0;
         while(i < opts.length)
         {
            var yy:Number = y + 4 + i * 26;
            var sel:Boolean = i == this.hzSetDropHi;
            if(sel) { g.beginFill(acc,0.16); g.drawRoundRect(x + 4,yy,w - 8,24,4,4); g.endFill(); }
            if(r.t == "a" && r.pal != undefined)
            {
               var pal:Array = r.pal as Array;
               g.beginFill(uint(pal[Math.min(pal.length - 1,i)]),1); g.drawRoundRect(x + 12,yy + 5,12,14,3,3); g.endFill();
               this.hzWT(b,String(opts[i]),x + 30,yy + 4,w - 42,11,"sb",sel ? acc : uint(T.lab),0.3);
            }
            else { this.hzWT(b,String(opts[i]),x + 12,yy + 4,w - 24,11,"sb",sel ? acc : uint(T.lab),0.3); }
            this.hzSetHits.push({"id":"dopt" + i,"x":x + 4,"y":yy,"w":w - 8,"h":24});
            i++;
         }
      }
      private function hz51Key(code:String) : Boolean
      {
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
            if(code.indexOf("ch:") == 0 && code.length >= 4)
            {
               this.hzSetFind += code.substr(3,1);
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
            if(code.indexOf("ch:") == 0 && code.length >= 4)
            {
               var ch:String = code.substr(3,1).toUpperCase();
               if("0123456789ABCDEF".indexOf(ch) >= 0 && this.hzSetHexBuf.length < 6) { this.hzSetHexBuf += ch; }
               return true;
            }
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
         if(code.indexOf("ch:") == 0 && code.substr(3) == "/")
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
         var x:Number = HZ51_SIDE_W + 12;
         var y:Number = HZ_SET_TOP + 44;
         var r:Number = HZ_SET_W - HZ51_PREV_W - 10;
         return {"x":x,"y":y,"r":r,"w":r - x};
      }
