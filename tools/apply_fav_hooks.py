#!/usr/bin/env python3
"""Horizon UI quick menu (0.43.3.0, batch f): adds Horizon's code to ONE vanilla script (FavoritesMenu.as, exported with
ffdec from the player's vanilla 1.16.244 favoritesmenu.swf / favoritesmenu_lrg.swf) and writes the result for
`ffdec -importScript`. Copied from the Scope module's apply_scope_hooks.py. Every vanilla line stays (checked); only
the missing imports, five one-line hooks and the Horizon members (actionscript/favorites/hzq_main.as +
hzq37_reader.as) are added. Fails loudly if an anchor is not found exactly once. Writes a new file only (mode 'x').
  apply_fav_hooks.py VANILLA_FavoritesMenu.as BLOCK_DIR OUT_FavoritesMenu.as [--lrg]"""
import os, re, sys
args = [a for a in sys.argv[1:] if not a.startswith('--')]
lrg = '--lrg' in sys.argv
van, bdir, out = args
src = open(van, newline='').read()
if 'hzqOpen' in src: raise SystemExit(van + ' is already patched; export a fresh vanilla copy')
nl = '\r\n' if '\r\n' in src else '\n'
blk = open(os.path.join(bdir, 'hzq_main.as')).read() + open(os.path.join(bdir, 'hzq37_reader.as')).read()
blk = blk.replace('__HZQ_LRG__', 'true' if lrg else 'false')
assert '__HZ' not in blk
blk = blk.replace('\r\n', '\n').replace('\n', nl)
def once(t, n, what):
    i = t.find(n)
    if i < 0: raise SystemExit('anchor not found: ' + what)
    if t.find(n, i + len(n)) >= 0: raise SystemExit('anchor found more than once: ' + what)
    return i
def after(t, anchor, add, what):
    a = anchor.replace('\n', nl)
    i = once(t, a, what)
    return t[:i + len(a)] + add.replace('\n', nl) + t[i + len(a):]
once(src, 'public class FavoritesMenu extends IMenu', 'class declaration')
# 1. imports
imports = ['Shared.InventoryItemUtils', 'Shared.PlatformUtils', 'flash.display.DisplayObject', 'flash.display.MovieClip',
           'flash.display.Sprite', 'flash.events.Event', 'flash.events.IOErrorEvent', 'flash.filters.DropShadowFilter',
           'flash.geom.ColorTransform', 'flash.geom.Rectangle', 'flash.net.URLLoader', 'flash.net.URLRequest',
           'flash.text.TextField', 'flash.text.TextFieldAutoSize',            'flash.text.TextFormat',
           'flash.display.Graphics', 'flash.events.KeyboardEvent', 'flash.events.MouseEvent',
           'flash.geom.Point']  # last four: 0.43.5 Extended Mode
m = list(re.finditer(r'(?m)^[ \t]*import [A-Za-z0-9_.]+;[ \t]*\r?$', src))
last = m[-1]; add = ''
for im in imports:
    if not re.search(r'import\s+' + re.escape(im) + r'\s*;', src): add += nl + '   import ' + im + ';'
end = last.end() - (1 if last.group(0).endswith('\r') else 0)
src = src[:end] + add + src[end:]
# 2. hooks (each one line, each in try / catch)
src = after(src, '         super.onAddedToStage();\n         stage.focus = this;',
            '\n         try { this.hzqOpen(); } catch(hzqE1:Error) { }   // Horizon: menu open -> read the settings', 'onAddedToStage')
src = after(src, '         this.IsDataInitialized = true;',
            '\n         try { this.hzqData(); } catch(hzqE2:Error) { }   // Horizon: FavoritesData', 'onDataUpdate end')
src = after(src, '            this.AssignedItemIcon_mc.LoadImageFixtureFromUIData(this.AssignedItem.iconImage,"FavoritesIconBuffer");\n            this.ItemInfo_mc.visible = true;',
            '\n            try { this.hzqAssign(); } catch(hzqE3:Error) { }   // Horizon: assign mode info card', 'assignedItem setter')
src = after(src, '      private function onSelectionChange() : void\n      {\n         this.ItemInfo_mc.UpdateDisplay(this.selectedEntry);\n         this.ItemInfo_mc.visible = true;',
            '\n         try { this.hzqSel(); } catch(hzqE4:Error) { }   // Horizon: selection change', 'onSelectionChange')
# Extra slots 13-24 are Horizon clips, not native favorites. Confirm / arrows must not fall
# through to vanilla SelectItem (uQuickkeyIndex 0-11 only) or the T d-pad tables.
src = after(src, '      public function ProcessUserEvent(param1:String, param2:Boolean) : Boolean\n      {\n         var _loc4_:Number = NaN;\n         var _loc3_:Boolean = false;',
            '\n         try { if(this.hzqExtUser(param1,param2)) return true; } catch(hzqE5:Error) { }   // Horizon: extra slots 13-24', 'ProcessUserEvent')
src = after(src, '      public function onKeyDownHandler(param1:KeyboardEvent) : *\n      {\n',
            '         try { if(this.hzqExtArrow(param1)) { param1.stopPropagation(); return; } } catch(hzqE6:Error) { }\n', 'onKeyDownHandler')
src = after(src, '      public function onKeyUpHandler(param1:KeyboardEvent) : *\n      {\n',
            '         try { if(param1.keyCode == Keyboard.ENTER && this.hzqExtConfirm()) { param1.stopPropagation(); return; } } catch(hzqE7:Error) { }\n', 'onKeyUpHandler')
src = after(src, '      private function SelectItem() : void\n      {\n',
            '         try { if(this.hzqExtConfirm()) return; } catch(hzqE8:Error) { }   // Horizon: never AssignQuickkey with index >= 12\n'
            '         if(int(this.selectedIndex) >= 12) return;\n', 'SelectItem')
src = after(src, '      private function onFavEntryMouseover(param1:Event) : void\n      {\n',
            '         try { if(this.hzqExtMouse(param1)) return; } catch(hzqE9:Error) { }   // Horizon: Entry_13-24 name, not constructed entryIndex 0\n', 'onFavEntryMouseover')
# 3. members (OnControlMapChanged override included): before the frame scripts (end of the class)
f = once(src, '      internal function frame13() : *', 'frame13')
src = src[:f] + blk + nl + src[f:]
# every vanilla line is still there, in order
V = [l for l in open(van, newline='').read().replace('\r\n', '\n').split('\n') if l.strip()]
O = src.replace('\r\n', '\n').split('\n'); j = 0
for l in V:
    while j < len(O) and O[j] != l: j += 1
    if j >= len(O): raise SystemExit('vanilla line lost: ' + l.strip()[:80])
    j += 1
os.makedirs(os.path.dirname(out), exist_ok=True)
open(out, 'x', newline='').write(src)
print('apply_fav_hooks:', out, '(lrg)' if lrg else '', len(V), 'vanilla lines kept')
