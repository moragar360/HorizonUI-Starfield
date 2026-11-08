package
{
   // Purpose: read and write the small JSON files that pills, packs and the pill profile use.
   //    No vanilla movie calls the Flash JSON class, so its presence in the game's Scaleform is
   //    unproven; this reader needs nothing beyond String.
   // Inputs: text up to MAX_CHARS, with or without a leading byte-order mark; values made of
   //    Object, Array, String, Number, Boolean, null.
   // Outputs: parse returns the value, or null when the text is not valid JSON, nests deeper
   //    than MAX_DEPTH or is too long. stringify writes keys in a fixed order so files diff well.
   // Dependencies: none.
   // Author: Moragar. Last modified: 2026-11-07.
   public class HsbJson
   {
      internal static const MAX_CHARS:int = 65536;
      internal static const MAX_DEPTH:int = 16;
      private static const FIRST_KEYS:Array = ["type","version","id","name","author","description","tabs","match","inRow","rules","field","op","value","values","columns","pills","columnSets"];

      private var src:String;
      private var at:int;
      private var bad:Boolean;

      public function HsbJson()
      {
         super();
      }

      internal static function parse(param1:String):*
      {
         if(param1 == null) { return null; }
         // Editors that save "UTF-8 with BOM" put U+FEFF first; RFC 8259 lets a reader skip it,
         // and without this a hand-edited profile would be set aside as damaged.
         if(param1.length > 0 && param1.charCodeAt(0) == 0xFEFF) { param1 = param1.substring(1); }
         if(param1.length > MAX_CHARS) { return null; }
         var p:HsbJson = new HsbJson();
         p.src = param1;
         p.at = 0;
         p.bad = false;
         var out:* = p.value(0);
         p.space();
         if(p.bad || p.at != p.src.length) { return null; }
         return out;
      }

      private function space():void
      {
         while(this.at < this.src.length)
         {
            var c:String = this.src.charAt(this.at);
            if(c == " " || c == "\t" || c == "\n" || c == "\r") { this.at++; }
            else { return; }
         }
      }

      private function value(param1:int):*
      {
         if(param1 > MAX_DEPTH) { this.bad = true; return null; }
         this.space();
         if(this.at >= this.src.length) { this.bad = true; return null; }
         var c:String = this.src.charAt(this.at);
         if(c == "{") { return this.object(param1 + 1); }
         if(c == "[") { return this.array(param1 + 1); }
         if(c == "\"") { return this.string(); }
         if(this.src.substr(this.at,4) == "true") { this.at += 4; return true; }
         if(this.src.substr(this.at,5) == "false") { this.at += 5; return false; }
         if(this.src.substr(this.at,4) == "null") { this.at += 4; return null; }
         return this.number();
      }

      private function object(param1:int):Object
      {
         var out:Object = {};
         this.at++;
         this.space();
         if(this.src.charAt(this.at) == "}") { this.at++; return out; }
         while(!this.bad)
         {
            this.space();
            if(this.src.charAt(this.at) != "\"") { this.bad = true; return null; }
            var key:String = this.string();
            this.space();
            if(this.src.charAt(this.at) != ":") { this.bad = true; return null; }
            this.at++;
            out[key] = this.value(param1);
            this.space();
            var c:String = this.src.charAt(this.at);
            this.at++;
            if(c == "}") { return out; }
            if(c != ",") { this.bad = true; return null; }
         }
         return null;
      }

      private function array(param1:int):Array
      {
         var out:Array = [];
         this.at++;
         this.space();
         if(this.src.charAt(this.at) == "]") { this.at++; return out; }
         while(!this.bad)
         {
            out.push(this.value(param1));
            this.space();
            var c:String = this.src.charAt(this.at);
            this.at++;
            if(c == "]") { return out; }
            if(c != ",") { this.bad = true; return null; }
         }
         return null;
      }

      private function string():String
      {
         var out:String = "";
         this.at++;
         while(this.at < this.src.length)
         {
            var c:String = this.src.charAt(this.at);
            this.at++;
            if(c == "\"") { return out; }
            if(c == "\\")
            {
               var e:String = this.src.charAt(this.at);
               this.at++;
               if(e == "n") { out += "\n"; }
               else if(e == "t") { out += "\t"; }
               else if(e == "r") { out += "\r"; }
               else if(e == "b") { out += "\b"; }
               else if(e == "f") { out += "\f"; }
               else if(e == "u")
               {
                  var code:Number = parseInt(this.src.substr(this.at,4),16);
                  if(isNaN(code) || this.src.substr(this.at,4).length < 4) { this.bad = true; return ""; }
                  out += String.fromCharCode(code);
                  this.at += 4;
               }
               else { out += e; }
            }
            else
            {
               if(c.charCodeAt(0) < 32) { this.bad = true; return ""; }
               out += c;
            }
         }
         this.bad = true;
         return "";
      }

      private function number():Number
      {
         var start:int = this.at;
         while(this.at < this.src.length && "+-0123456789.eE".indexOf(this.src.charAt(this.at)) >= 0) { this.at++; }
         if(this.at == start) { this.bad = true; return 0; }
         var n:Number = Number(this.src.substring(start,this.at));
         if(isNaN(n)) { this.bad = true; return 0; }
         return n;
      }

      internal static function stringify(param1:*, param2:String = ""):String
      {
         if(param1 == null) { return "null"; }
         if(param1 is Boolean) { return param1 ? "true" : "false"; }
         if(param1 is Number || param1 is int || param1 is uint) { return isFinite(Number(param1)) ? String(param1) : "0"; }
         if(param1 is String) { return quote(String(param1)); }
         var inner:String = param2 + "  ";
         var parts:Array = [];
         if(param1 is Array)
         {
            var list:Array = param1 as Array;
            if(list.length == 0) { return "[]"; }
            var flat:Boolean = true;
            var i:int = 0;
            while(i < list.length)
            {
               if(list[i] != null && typeof list[i] == "object") { flat = false; }
               parts.push(stringify(list[i],inner));
               i++;
            }
            if(flat) { return "[" + parts.join(", ") + "]"; }
            return "[\n" + inner + parts.join(",\n" + inner) + "\n" + param2 + "]";
         }
         var keys:Array = [];
         var k:String;
         for(k in param1) { keys.push(k); }
         keys.sort(function(a:String, b:String):int
         {
            var ia:int = FIRST_KEYS.indexOf(a);
            var ib:int = FIRST_KEYS.indexOf(b);
            if(ia < 0) { ia = 999; }
            if(ib < 0) { ib = 999; }
            if(ia != ib) { return ia - ib; }
            return a < b ? -1 : (a > b ? 1 : 0);
         });
         if(keys.length == 0) { return "{}"; }
         var j:int = 0;
         while(j < keys.length)
         {
            parts.push(quote(String(keys[j])) + ": " + stringify(param1[keys[j]],inner));
            j++;
         }
         return "{\n" + inner + parts.join(",\n" + inner) + "\n" + param2 + "}";
      }

      private static function quote(param1:String):String
      {
         var out:String = "\"";
         var i:int = 0;
         while(i < param1.length)
         {
            var c:String = param1.charAt(i);
            var code:int = param1.charCodeAt(i);
            if(c == "\"") { out += "\\\""; }
            else if(c == "\\") { out += "\\\\"; }
            else if(c == "\n") { out += "\\n"; }
            else if(c == "\r") { out += "\\r"; }
            else if(c == "\t") { out += "\\t"; }
            else if(code < 32)
            {
               var h:String = code.toString(16);
               while(h.length < 4) { h = "0" + h; }
               out += "\\u" + h;
            }
            else { out += c; }
            i++;
         }
         return out + "\"";
      }
   }
}
