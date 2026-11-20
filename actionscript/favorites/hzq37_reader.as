      // =================== v0.37 shared settings reader (hzq37) ===================
      // ONE helper, spliced into every movie that reads the settings (hudmenu + hudmenu_lrg as hz37, hudmessagesmenu
      // x2 as hzc37, dialoguemenu x2 as hzd37; generated from hzini_shared.as, so the copies are
      // identical apart from the prefix). It reads HorizonUI.default.ini, HorizonUI.user.ini, HorizonUI.state.ini and the
      // legacy HorizonUI.ini (paths relative to Data/Interface) one after the other and hands every waiting callback the
      // merged text: the defaults with user.ini laid over (hzq37Compose; mirrors HZF::Compose in HorizonUI.dll). A missing
      // file is normal: its IOErrorEvent is caught and counts as no file. The game logs every failed open, so
      // HorizonUI.ini is opened at most once, and only when Compose still needs that unshipped file.
      // No defaults file -> the legacy HorizonUI.ini is the base. Nothing at all -> null (callers keep built-in defaults).
      private static const hzq37_FILES:Array = ["HorizonUI/HorizonUI.default.ini","HorizonUI/HorizonUI.user.ini","HorizonUI/HorizonUI.state.ini","HorizonUI/HorizonUI.ini"];
      private static const hzq37_BOM:String = String.fromCharCode(0xFEFF);
      private var hzq37Ldr:URLLoader = null;
      private var hzq37Step:int = 0;          // 0 idle, n = reading hzq37_FILES[n - 1]
      private var hzq37T0:Number = 0;
      private var hzq37Got:Array = null;
      private var hzq37Q:Array = [];          // callbacks of the running read
      private var hzq37N:Array = [];          // callbacks that arrived meanwhile (they get a fresh read)
      private var hzq37Leg:String = null;     // last text of HorizonUI.ini, or null when that open missed
      private var hzq37LegTry:int = 0;        // 0 = not opened yet, 1 = opened once
      private function hzq37Ws(c:String) : Boolean { return c == " " || c == "\t" || c == "\r" || c == "\n"; }
      private function hzq37Trim(s:String) : String
      {
         var b:int = 0;
         var e:int = s.length;
         while(b < e && (this.hzq37Ws(s.charAt(b)) || s.charAt(b) == hzq37_BOM)) { b++; }
         while(e > b && this.hzq37Ws(s.charAt(e - 1))) { e--; }
         return s.substring(b,e);
      }
      private function hzq37Blank(s:String) : Boolean { return this.hzq37Trim(s).length == 0; }
      private function hzq37Lines(t:String) : Array
      {
         var out:Array = [];
         if(t == null || t.length == 0) { return out; }
         if(t.charAt(0) == hzq37_BOM) { t = t.substr(1); }
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
      private function hzq37Hdr(ln:String) : String
      {
         var t:String = this.hzq37Trim(ln);
         if(t.length < 3 || t.charAt(0) != "[") { return null; }
         var e:int = t.indexOf("]");
         if(e < 2) { return null; }
         return this.hzq37Trim(t.substring(1,e)).toLowerCase();
      }
      private function hzq37Alias(n:String) : String
      {
         if(n == "cards v0.26") { return "cards extra"; }
         if(n == "effects v0.26") { return "effects"; }
         return n;
      }
      // key=value line -> {k: key lower case without blanks, o: key as written, v: value up to ';'}; null otherwise
      private function hzq37KV(ln:String) : Object
      {
         var t:String = this.hzq37Trim(ln);
         if(t.length == 0) { return null; }
         var c:String = t.charAt(0);
         if(c == ";" || c == "#" || c == "[") { return null; }
         var eq:int = t.indexOf("=");
         if(eq <= 0) { return null; }
         var o:String = this.hzq37Trim(t.substr(0,eq));
         var k:String = o.split(" ").join("").split("\t").join("").toLowerCase();
         if(k.length == 0) { return null; }
         var v:String = t.substr(eq + 1);
         var sc:int = v.indexOf(";");
         if(sc >= 0) { v = v.substr(0,sc); }
         return {"k":k,"o":o,"v":this.hzq37Trim(v)};
      }
      // sections; a second copy / the pre-v0.31 name merges into the first, old names first so the new name wins
      private function hzq37Parse(t:String) : Object
      {
         var d:Object = {"secs":[{"n":"","raw":[],"order":[],"kv":{}}],"idx":{"s_":0}};
         var lines:Array = this.hzq37Lines(t);
         var pass:int = 0;
         while(pass < 2)
         {
            var cur:Object = d.secs[0];
            var old:Boolean = false;
            for each(var ln:String in lines)
            {
               var h:String = this.hzq37Hdr(ln);
               if(h != null)
               {
                  old = h == "cards v0.26" || h == "effects v0.26";
                  var n:String = this.hzq37Alias(h);
                  if((pass == 0) != old) { cur = null; continue; }
                  if(d.idx["s_" + n] == undefined) { d.idx["s_" + n] = d.secs.length; d.secs.push({"n":n,"raw":[],"order":[],"kv":{}}); }
                  cur = d.secs[int(d.idx["s_" + n])];
                  cur.raw.push(ln);
                  continue;
               }
               if(cur == null) { continue; }
               if(pass == 0 && cur.n == "") { continue; }
               cur.raw.push(ln);
               var kv:Object = this.hzq37KV(ln);
               if(kv == null) { continue; }
               if(cur.kv["k_" + kv.k] == undefined) { cur.order.push(kv.k); }
               cur.kv["k_" + kv.k] = [kv.o,kv.v];
            }
            pass++;
         }
         return d;
      }
      private function hzq37SecOf(d:Object, kl:String) : String
      {
         for each(var s:Object in d.secs) { if(s.n != "" && s.kv["k_" + kl] != undefined) { return String(s.n); } }
         return "";
      }
      private function hzq37Flush(out:Array, sec:String, U:Object, ext:Object, flushed:Object) : void
      {
         if(sec == "" || flushed["s_" + sec] == true) { return; }
         flushed["s_" + sec] = true;
         var e:Array = ext["s_" + sec];
         if(e == null || e.length == 0) { return; }
         var blanks:int = 0;
         while(out.length > 0 && this.hzq37Blank(String(out[out.length - 1]))) { out.pop(); blanks++; }
         for each(var k:String in e)
         {
            var p:Array = U["s_" + sec]["k_" + k];
            out.push(String(p[0]) + "=" + String(p[1]));
         }
         while(blanks > 0) { out.push(""); blanks--; }
      }
      // base with the player's values laid over it: known keys replace the base value in place, unknown keys of a known
      // section are appended to it, sections the base lacks are appended verbatim. CRLF out.
      private function hzq37Overlay(base:String, over:String) : String
      {
         var B:Object = this.hzq37Parse(base);
         var O:Object = this.hzq37Parse(over);
         var U:Object = {};
         var ext:Object = {};
         var unk:Array = [];
         for each(var s:Object in O.secs)
         {
            if(s.n != "" && B.idx["s_" + s.n] == undefined) { unk.push(s); continue; }
            for each(var kl:String in s.order)
            {
               var sec:String = s.n == "" ? this.hzq37SecOf(B,kl) : String(s.n);
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
         for each(var ln:String in this.hzq37Lines(base))
         {
            var h:String = this.hzq37Hdr(ln);
            if(h != null) { this.hzq37Flush(out,cur,U,ext,flushed); cur = this.hzq37Alias(h); out.push(ln); continue; }
            if(cur != "")
            {
               var kv:Object = this.hzq37KV(ln);
               if(kv != null && U["s_" + cur] != undefined && U["s_" + cur]["k_" + kv.k] != undefined)
               {
                  out.push(kv.o + "=" + String(U["s_" + cur]["k_" + kv.k][1]));
                  continue;
               }
            }
            out.push(ln);
         }
         this.hzq37Flush(out,cur,U,ext,flushed);
         for each(var us:Object in unk)
         {
            if(out.length > 0 && !this.hzq37Blank(String(out[out.length - 1]))) { out.push(""); }
            var r:Array = (us.raw as Array).concat();
            while(r.length > 0 && this.hzq37Blank(String(r[r.length - 1]))) { r.pop(); }
            for each(var rl:String in r) { out.push(rl); }
         }
         return out.length == 0 ? "" : out.join("\r\n") + "\r\n";
      }
      // def / user / state / legacy texts (null = file missing) -> the effective settings text, or null
      private function hzq37Compose(def:String, user:String, state:String, leg:String) : String
      {
         var hd:Boolean = def != null && def.length > 0;
         var hl:Boolean = leg != null && leg.length > 0;
         var base:String = hd ? def : (hl ? leg : null);
         var over:String = user != null ? user : (state == null && hd && hl ? leg : null);   // an old DLL still saves HorizonUI.ini
         if(base == null) { return over == null ? null : this.hzq37Overlay(over,""); }
         return this.hzq37Overlay(base,over != null ? over : "");
      }
      // read all four files, then cb(mergedText or null). Requests during a read get one fresh read afterwards.
      private function hzq37IniRead(cb:Function) : void
      {
         var now:Number = new Date().getTime();
         if(this.hzq37Step != 0 && now - this.hzq37T0 < 3000)
         {
            if(this.hzq37N.indexOf(cb) < 0) { this.hzq37N.push(cb); }
            return;
         }
         if(this.hzq37Step != 0 && this.hzq37Ldr != null) { try { this.hzq37Ldr.close(); } catch(e0:Error) { } }   // stuck: start over
         var q:Array = this.hzq37Step != 0 ? this.hzq37Q.concat(this.hzq37N) : [];
         this.hzq37N = [];
         if(q.indexOf(cb) < 0) { q.push(cb); }
         this.hzq37Q = q;
         this.hzq37Begin();
      }
      private function hzq37Begin() : void
      {
         this.hzq37Got = [null,null,null,null];
         this.hzq37T0 = new Date().getTime();
         this.hzq37Next(0);
      }
      private function hzq37IsLeg(i:int) : Boolean
      {
         if(i < 0 || i >= hzq37_FILES.length) { return false; }
         var pth:String = String(hzq37_FILES[i]);
         return pth.length >= 13 && pth.substr(pth.length - 13) == "HorizonUI.ini";
      }
      // HorizonUI.ini is not shipped. Skip it when Compose would ignore it, and open it only once when it would not.
      private function hzq37SkipLeg(i:int) : Boolean
      {
         if(!this.hzq37IsLeg(i)) { return false; }
         if(this.hzq37LegTry != 0) { return true; }
         var def:String = this.hzq37Got[0] == null ? null : String(this.hzq37Got[0]);
         var hd:Boolean = def != null && def.length > 0;
         if(hd && (this.hzq37Got[1] != null || this.hzq37Got[2] != null)) { return true; }
         return false;
      }
      private function hzq37Next(i:int) : void
      {
         this.hzq37Step = i + 1;
         if(i >= hzq37_FILES.length) { this.hzq37Ldr = null; this.hzq37Done(); return; }
         if(this.hzq37SkipLeg(i))
         {
            this.hzq37Got[i] = this.hzq37LegTry != 0 ? this.hzq37Leg : null;
            this.hzq37Next(i + 1);
            return;
         }
         try
         {
            this.hzq37Ldr = new URLLoader();
            this.hzq37Ldr.addEventListener(Event.COMPLETE,this.hzq37OnOk);
            this.hzq37Ldr.addEventListener(IOErrorEvent.IO_ERROR,this.hzq37OnErr);
            this.hzq37Ldr.addEventListener("securityError",this.hzq37OnErr);
            this.hzq37Ldr.load(new URLRequest(String(hzq37_FILES[i])));
         }
         catch(err:Error) { this.hzq37Next(i + 1); }
      }
      private function hzq37OnOk(e:Event) : void
      {
         if(e == null || e.target != this.hzq37Ldr) { return; }
         var i:int = this.hzq37Step - 1;
         try { this.hzq37Got[i] = String(this.hzq37Ldr.data); } catch(err:Error) { }
         if(this.hzq37IsLeg(i)) { this.hzq37Leg = this.hzq37Got[i] == null ? null : String(this.hzq37Got[i]); this.hzq37LegTry = 1; }
         this.hzq37Next(i + 1);
      }
      private function hzq37OnErr(e:Event) : void
      {
         if(e == null || e.target != this.hzq37Ldr) { return; }
         if(this.hzq37IsLeg(this.hzq37Step - 1)) { this.hzq37Leg = null; this.hzq37LegTry = 1; }
         this.hzq37Next(this.hzq37Step);   // missing file: counted once, not opened again
      }
      private function hzq37Done() : void
      {
         this.hzq37Step = 0;
         var g:Array = this.hzq37Got;
         var txt:String = null;
         try { txt = this.hzq37Compose(g[0],g[1],g[2],g[3]); } catch(errC:Error) { txt = null; }
         var cbs:Array = this.hzq37Q;
         this.hzq37Q = [];
         for each(var cb:Function in cbs) { try { cb(txt); } catch(errCb:Error) { } }
         if(this.hzq37N.length > 0 && this.hzq37Step == 0) { this.hzq37Q = this.hzq37N; this.hzq37N = []; this.hzq37Begin(); }
      }
      // =================== end shared settings reader ===================
