// Hide-path redundant-work fix (hidecache): proves the new hz43VanBlgChrome / hz43VanChrome / hz43VanHoldsMark /
// hz43VanCapClip / hz43VanRingProof give the same hide and show results as the 43dfca4 bodies, frame by frame,
// and counts hzFindByName nodes per loop before and after.
// The 43dfca4 bodies are frozen below (REF_43DFCA4). Both sides run the production AS from horizon_block.as
// for every other function, on two identical display trees.
// Run: node tests/hidecache_model_test.js
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

const REF_43DFCA4 = `      private function hz43VanCapClip(d:DisplayObject) : Boolean
      {
         if(!d || this.hzBlg == null || d.parent != this.hzBlg) { return false; }
         if(this.hz43VanSkip(d.name)) { return false; }
         if(!this.hz43VanInstName(d.name)) { return false; }
         if(d.scaleX < 0.5 && d.scaleX > -0.5) { return false; }
         if(d.scaleY < 0.5 && d.scaleY > -0.5) { return false; }
         var outline:DisplayObject = this.hzFindByName(this.hzBlg,"WatchOutline_mc",0);
         if(outline && outline.parent == this.hzBlg)
         {
            var dx:Number = d.x - outline.x;
            var dy:Number = d.y - outline.y;
            return dx > -2 && dx < 2 && dy > -2 && dy < 2;
         }
         return d.x > -2 && d.x < 2 && d.y > -2 && d.y < 2;
      }

      private function hz43VanRingProof(d:DisplayObject) : Boolean
      {
         if(!d || this.hzBlg == null || d.parent != this.hzBlg) { return false; }
         if(this.hz43VanSkip(d.name)) { return false; }
         if(!this.hz43VanInstName(d.name)) { return false; }
         if(d.scaleX < 0.5 && d.scaleX > -0.5) { return false; }
         if(d.scaleY < 0.5 && d.scaleY > -0.5) { return false; }
         var outline:DisplayObject = this.hzFindByName(this.hzBlg,"WatchOutline_mc",0);
         var ox:Number = 0;
         var oy:Number = 0;
         if(outline && outline.parent == this.hzBlg)
         {
            ox = outline.x;
            oy = outline.y;
         }
         var mid:Number = HZ43_VAN_FACE * 0.5;
         var dx:Number = d.x - ox;
         var dy:Number = d.y - oy;
         if(dx <= mid - 2 || dx >= mid + 2 || dy <= mid - 2 || dy >= mid + 2) { return false; }
         var idx:int = -1;
         try { idx = this.hzBlg.getChildIndex(d); } catch(eRing:Error) { return false; }
         if(idx < 1 || idx >= this.hzBlg.numChildren - 1) { return false; }
         var prev:DisplayObject = this.hzBlg.getChildAt(idx - 1);
         var next:DisplayObject = this.hzBlg.getChildAt(idx + 1);
         var pn:String = prev && prev.name != null ? prev.name : "";
         var nn:String = next && next.name != null ? next.name : "";
         return pn == "EnvConditionBase_mc" && nn == "EnemyDetectionAnim_mc";
      }

      private function hz43VanHoldsMark(box:DisplayObjectContainer) : Boolean
      {
         if(!box) { return false; }
         var i:int = 0;
         while(i < HZ43_VAN_MARK.length)
         {
            if(box.name == String(HZ43_VAN_MARK[i])) { return true; }
            if(this.hzFindByName(box,String(HZ43_VAN_MARK[i]),0) != null) { return true; }
            i++;
         }
         return false;
      }

      private function hz43VanBlgChrome(hide:Boolean) : void
      {
         if(!this.hzBlg) { return; }
         var i:int = 0;
         while(i < this.hzBlg.numChildren)
         {
            var d:DisplayObject = this.hzBlg.getChildAt(i);
            var n:String = d ? d.name : "";
            var capArt:Boolean = this.hz43VanCapClip(d);
            var ringArt:Boolean = this.hz43VanRingClip(d);
            var holds:Boolean = false;
            if(d) { holds = this.hz43VanHoldsMark(d as DisplayObjectContainer); }
            var mark:Boolean = this.hz43VanMarkName(n);
            var named:Boolean = this.hz43VanNamed(n);
            if(!d || this.hz43VanSkip(n)) { }
            else if(hide)
            {
               if(!mark && !holds && (named || capArt || ringArt)) { this.hz43StHide(d); }
            }
            else if(mark || named || capArt || ringArt)
            {
               this.hz43VanShowClip(d);
            }
            i++;
         }
      }

      private function hz43VanChrome(hide:Boolean) : void
      {
         if(!hide) { this.hz43VanRestoreHid(); this.hz43VanBlgChrome(false); return; }
         var i:int = 0;
         while(i < HZ43_VAN_N.length)
         {
            var name:String = String(HZ43_VAN_N[i]);
            var mark:Boolean = this.hz43VanMarkName(name);
            var clip:DisplayObject = this.hzFindByName(this.hzBlg,name,0);
            if(clip)
            {
               var box:DisplayObjectContainer = clip as DisplayObjectContainer;
               var keep:Boolean = mark || (box != null && this.hz43VanHoldsMark(box));
               if(hide && mark)
               {
                  if(!clip.visible) { clip.visible = true; }
                  var up:DisplayObjectContainer = clip.parent;
                  while(up != null && up != this)
                  {
                     if(!up.visible) { up.visible = true; }
                     if(up == this.hzBlg) { break; }
                     up = up.parent;
                  }
                  var sib:DisplayObjectContainer = clip.parent;
                  if(sib != null && sib != this.hzBlg && sib != this)
                  {
                     var si:int = 0;
                     while(si < sib.numChildren)
                     {
                        var sc:DisplayObject = sib.getChildAt(si);
                        var scMark:Boolean = sc && (this.hz43VanMarkName(sc.name) || (sc is DisplayObjectContainer && this.hz43VanHoldsMark(DisplayObjectContainer(sc))));
                        if(sc && !scMark)
                        {
                           this.hz43StHide(sc);
                        }
                        si++;
                     }
                  }
               }
               else if(hide && box != null && keep && !mark)
               {
                  if(!clip.visible) { clip.visible = true; }
                  var ci:int = 0;
                  while(ci < box.numChildren)
                  {
                     var ch:DisplayObject = box.getChildAt(ci);
                     var chMark:Boolean = ch && (this.hz43VanMarkName(ch.name) || (ch is DisplayObjectContainer && this.hz43VanHoldsMark(DisplayObjectContainer(ch))));
                     if(ch && !chMark)
                     {
                        this.hz43StHide(ch);
                     }
                     else if(ch)
                     {
                        if(!ch.visible) { ch.visible = true; }
                     }
                     ci++;
                  }
               }
               else if(hide && !keep)
               {
                  this.hz43StHide(clip);
               }
            }
            i++;
         }
         this.hz43VanBlgChrome(hide);
      }
`;

function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) i = src.indexOf("public function " + name + "(");
	if (i < 0) throw new Error("missing function " + name);
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(i, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function toJs(body) {
	return body
		.replace(/(\w+) is DisplayObjectContainer\b/g, "__isDoc($1)")
		.replace(/\bDisplayObjectContainer\(/g, "(")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		// AS3 catch types: catch(e:Error) lets a non-Error value pass, catch(e:*) takes any value. Keep that in JS.
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*\*\s*\)/g, "catch($1)")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.]+\s*\)/g, "catch($1)")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim());
}
function bind(host, src, name) {
	const f = fnText(src, name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}
function constArr(name) {
	const m = as.match(new RegExp("static const " + name + ":Array = (\\[[^\\]]*\\]);"));
	if (!m) throw new Error("const " + name);
	return JSON.parse(m[1]);
}
function constNum(name) {
	const m = as.match(new RegExp("static const " + name + ":(?:int|Number) = ([\\d.]+);"));
	if (!m) throw new Error("const " + name);
	return Number(m[1]);
}

// ---- display tree model ----
let uid = 0;
function Clip(name, opts) {
	opts = opts || {};
	const c = { _id: ++uid, name: name, visible: opts.visible !== false, alpha: opts.alpha == null ? 1 : opts.alpha, x: opts.x || 0, y: opts.y || 0,
		scaleX: opts.scaleX == null ? 1 : opts.scaleX, scaleY: opts.scaleY == null ? 1 : opts.scaleY, parent: null, kids: opts.leaf ? null : [],
		transform: { colorTransform: { alphaMultiplier: 1, alphaOffset: 0 } } };
	return c;
}
function add(p, c) { c.parent = p; p.kids.push(c); return c; }
function makeDoc(c) {
	if (!c.kids) return c;
	Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; }, configurable: true });
	c.getChildAt = function(i) {
		if (this.__throwAt === i) { this.__throwAt = -1; throw new RangeError("model throw"); }
		return this.kids[i];
	};
	c.getChildByName = function(n) { for (const k of this.kids) if (k.name === n) return k; return null; };
	c.getChildIndex = function(d) { const i = this.kids.indexOf(d); if (i < 0) throw new Error("not a child"); return i; };
	for (const k of c.kids) makeDoc(k);
	return c;
}
function __isDoc(x) { return !!(x && x.kids); }
global.__isDoc = __isDoc;

// Deterministic PRNG.
function rng(seed) { let s = seed >>> 0; return function() { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }

// Synthetic BottomLeftGroup: the 27 direct children of the 0.43 log (blgN=27) with nested subtrees.
// filler(n) adds n nested containers (in nested groups of 4) so the whole group holds about 480 containers.
function filler(p, n, r, tag) {
	let made = 0;
	let cur = p;
	while (made < n) {
		const c = add(cur, Clip(tag + "_" + made));
		made++;
		if (made % 4 === 0) cur = p; else cur = c;
		if (r() < 0.3) add(c, Clip("shape" + made, { leaf: true }));
	}
}
function buildBlg(seed, opts) {
	opts = opts || {};
	const r = rng(seed);
	const blg = Clip("BottomLeftGroup_mc");
	const outline = add(blg, Clip("WatchOutline_mc", { x: 0, y: 0 }));
	filler(outline, 30, r, "olArt");
	add(blg, Clip("instance540", { x: 0.5, y: -0.25 }));                    // cap
	const ptr = add(blg, Clip("WatchPointerOutline_mc"));
	filler(ptr, 25, r, "ptr");
	const icons = add(blg, Clip("WatchIconsWidget_mc"));
	filler(icons, 40, r, "wi");
	const miss = add(blg, Clip("MissionIconsWidget_mc"));
	filler(miss, 40, r, "mi");
	const en = add(blg, Clip("EnemyIconsWidget_mc"));
	filler(en, 30, r, "ei");
	const o2 = add(blg, Clip("O2CO2_mc"));
	const o2a = add(o2, Clip("O2Anim_mc"));
	filler(o2a, 30, r, "o2");
	const thin = add(blg, Clip("O2CO2thin_mc"));
	filler(thin, 15, r, "thin");
	for (const n of ["DayCycleBase_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc", "Autopilot_mc"]) {
		filler(add(blg, Clip(n)), 18, r, n);
	}
	for (let t = 0; t < 3; t++) add(blg, Clip("instance6" + t, { x: 30 + t, y: 40, scaleX: 0.1, scaleY: 0.1 }));   // collapsed INFO ticks
	for (const n of ["BioCondition_mc", "BioConditionBase_mc", "EnvCondition_mc"]) filler(add(blg, Clip(n)), 12, r, n);
	filler(add(blg, Clip("EnvConditionBase_mc")), 12, r, "ecb");
	add(blg, Clip("instance546", { x: 110.5, y: 110.5 }));                 // filled annulus
	filler(add(blg, Clip("EnemyDetectionAnim_mc")), 14, r, "eda");
	add(blg, Clip("BioAlertBG_mc"));
	add(blg, Clip("EnvAlertText", { leaf: true }));
	add(blg, Clip("BioAlertText", { leaf: true }));
	add(blg, Clip("LocationAlertText", { leaf: true }));
	const holder = add(blg, Clip("WatchMarkHolder_mc"));                    // a named chrome clip that holds a nested marker
	filler(holder, 20, r, "hold");
	const deep = holder.kids[0];
	if (!opts.noNestedMark) add(deep, Clip("EnemyIconsWidget_mc"));
	return makeDoc(blg);
}
function countDocs(c) { if (!c || !c.kids) return 0; let n = 1; for (const k of c.kids) n += countDocs(k); return n; }
function pathOf(c, top) { const p = []; while (c && c !== top) { p.unshift(c.parent ? c.parent.kids.indexOf(c) + ":" + c.name : c.name); c = c.parent; } return p.join("/"); }

// ---- hosts ----
const FUNCS = ["hzFindByName", "hz43VanSkip", "hz43VanMarkName", "hz43VanInstName", "hz43VanCapClip", "hz43VanRingProof", "hz43VanRingClip",
	"hz43VanNamed", "hz43VanRootOf", "hz43VanWatchClip", "hz43StHide", "hz43VanNote", "hz43VanNoteAdd", "hz43VanRestoreHid", "hz43VanShowClip", "hz43VanGameVis",
	"hz43VanEnvWant", "hz43VanInfoName", "hz43VanHoldsMark", "hz43VanBlgChrome", "hz43VanChrome", "hz43SyncHide", "hz43ShowVanilla"];
const NEW_ONLY = ["hz43VanOutline", "hz43OlBegin", "hz43OlEnd", "hz43IsMark", "hz43FindMark"];
const CHANGED = ["hz43VanCapClip", "hz43VanRingProof", "hz43VanHoldsMark", "hz43VanBlgChrome", "hz43VanChrome"];

function makeHost(kind, top, style) {
	const h = {
		int: function(n) { return n | 0; }, trace: function() {}, __isDoc: __isDoc,
		hzPerfOn: true, hzPcFind: 0, hzPcStHide: 0, hzPcHoldN: 0, hzPcOlHit: 0, hzPcOlMiss: 0,
		hz43OlDepth: 0, hz43OlHave: false, hz43OlRef: null, hz43OlBlg: null,
		hzBlg: null, hzWatchStyle: style, hzHideVanillaWatch: style !== 1 && style !== 2, hzHideCache: [], hz43HideStyle: style,
		hz43VanShown: 1, hz43VanTries: 0, hz43VanLogged: true, hzDebug: false, hz26Dbg: {},
		hz43VanRing: null, hz43HidA: null, hz43HidN: 0, hz43VanN: 0, hz43VanD: [],
		hz43EnvGot: 1, hz43EnvLocal: false, hz43EnvCruise: false, hz43EnvLang: "en",
		HZ43_VAN_N: constArr("HZ43_VAN_N"), HZ43_VAN_MARK: constArr("HZ43_VAN_MARK"), HZ43_VAN_INFO: constArr("HZ43_VAN_INFO"),
		HZ43_VAN_A: constArr("HZ43_VAN_A"), HZ43_HID_MAX: constNum("HZ43_HID_MAX"), HZ43_VAN_FACE: constNum("HZ43_VAN_FACE"),
		hz43VanDump: function() {}
	};
	h.__top = top;
	h.hzBlg = top.kids[0];
	h.hzFindByNameTop = top;
	for (const f of FUNCS) bind(h, kind === "old" && CHANGED.indexOf(f) >= 0 ? REF_43DFCA4 : as, f);
	if (kind === "new") for (const f of NEW_ONLY) bind(h, as, f);
	return h;
}
// The HUD root: hzFindByName(this, ...) searches from the movie root that holds BottomLeftGroup_mc.
function makeRoot(seed, opts) {
	const top = Clip("root");
	add(top, buildBlg(seed, opts));
	return makeDoc(top);
}
// hzOnFrame BottomLeftGroup loop (unchanged by this commit), copied from horizon_block.as.
function blgLoop(h) {
	if (!h.hzHideVanillaWatch || !h.hzBlg) return;
	let bi = 0;
	while (bi < h.hzBlg.numChildren) {
		const bc = h.hzBlg.getChildAt(bi);
		const keepMark = (h.hzWatchStyle === 3 || h.hzWatchStyle === 4) && bc && h.hz43VanMarkName(bc.name);
		if (bc && bc.visible && !keepMark && bc.name !== "EnemyDetectionAnim_mc" && bc.name !== "EnvAlertText" && bc.name !== "BioAlertText" && bc.name !== "LocationAlertText" && !(bc.name != null && (bc.name.indexOf("Bio") === 0 || bc.name.indexOf("Env") === 0))) {
			h.hz43StHide(bc);
		}
		bi++;
	}
}
// One loop + one exit, at the call sites the parts diag times: syncHide, the hide loop, h43 (VanPlace / VanHorizon chrome),
// then exitFrame xVanLate (the same chrome call again).
const PH = { sync: 0, loop: 0, h43: 0, exit: 0 };
function chrome(h) {
	if (h.hzWatchStyle === 3 || h.hzWatchStyle === 4) h.hz43VanChrome(true);
	else if (h.hzWatchStyle === 1 || h.hzWatchStyle === 2) h.hz43VanChrome(false);
}
function frame(h, counts) {
	let f0 = h.hzPcFind;
	h.hz43SyncHide();
	if (counts) counts.sync += h.hzPcFind - f0;
	f0 = h.hzPcFind;
	blgLoop(h);
	if (counts) counts.loop += h.hzPcFind - f0;
	f0 = h.hzPcFind;
	chrome(h);
	if (counts) counts.h43 += h.hzPcFind - f0;
}
function exitFrame(h, counts) {
	const f0 = h.hzPcFind;
	chrome(h);
	if (counts) counts.exit += h.hzPcFind - f0;
}
function snap(h) {
	const out = [];
	(function walk(c) {
		out.push(pathOf(c, h.__top) + "=" + (c.visible ? 1 : 0) + "," + c.alpha);
		if (c.kids) for (const k of c.kids) walk(k);
	})(h.__top);
	const hid = [];
	for (let i = 0; i < h.hz43HidN; i++) hid.push(pathOf(h.hz43HidA[i], h.__top));
	out.push("hid=" + hid.join("|"));
	out.push("ring=" + (h.hz43VanRing ? pathOf(h.hz43VanRing, h.__top) : "null"));
	out.push("hvw=" + h.hzHideVanillaWatch + " shown=" + h.hz43VanShown + " cacheNull=" + (h.hzHideCache === null) + " stHide=" + h.hzPcStHide);
	return out.join("\n");
}
function firstDiff(a, b) {
	const x = a.split("\n"), y = b.split("\n");
	for (let i = 0; i < Math.max(x.length, y.length); i++) if (x[i] !== y[i]) return (x[i] || "<none>") + " vs " + (y[i] || "<none>");
	return "";
}

// Same mutation on both trees: index paths are identical because both trees are built from one seed.
function nodeAt(top, idxPath) { let c = top; for (const i of idxPath) { if (!c.kids || !c.kids[i]) return null; c = c.kids[i]; } return c; }
function allPaths(top) {
	const out = [];
	(function walk(c, p) { out.push(p); if (c.kids) c.kids.forEach((k, i) => walk(k, p.concat([i]))); })(top, []);
	return out;
}
function mutate(r, tops, step) {
	const paths = allPaths(tops[0]).filter((p) => p.length >= 2);
	const kind = r();
	if (kind < 0.55) {
		// native timeline / game writes visible on a random clip
		const p = paths[Math.floor(r() * paths.length)];
		const v = r() < 0.5;
		for (const t of tops) { const n = nodeAt(t, p); if (n) n.visible = v; }
	} else if (kind < 0.7) {
		// an alert or INFO clip is re-created: remove a direct child and add a fresh one with the same name at the same index
		const blgs = tops.map((t) => t.kids[0]);
		const i = Math.floor(r() * blgs[0].kids.length);
		for (const b of blgs) {
			const old = b.kids[i];
			const fresh = makeDoc(Clip(old.name, { x: old.x, y: old.y, scaleX: old.scaleX, scaleY: old.scaleY, leaf: !old.kids }));
			if (old.kids) filler(fresh, 3, rng(step), "re");
			if (fresh.kids) makeDoc(fresh);
			old.parent = null;
			fresh.parent = b;
			b.kids[i] = fresh;
		}
	} else if (kind < 0.8) {
		// a nested marker widget appears inside or disappears from a chrome clip (styles 3/4 keep marker holders)
		const blgs = tops.map((t) => t.kids[0]);
		const i = 1 + Math.floor(r() * (blgs[0].kids.length - 1));
		const appear = r() < 0.5;
		for (const b of blgs) {
			const box = b.kids[i];
			if (!box.kids) continue;
			if (appear) { const m = Clip("MissionIconsWidget_mc"); add(box, m); makeDoc(m); }
			else { const j = box.kids.findIndex((k) => k.name === "MissionIconsWidget_mc"); if (j >= 0) { box.kids[j].parent = null; box.kids.splice(j, 1); } }
		}
	} else if (kind < 0.88) {
		// a direct child appears or disappears (blgN changes)
		const blgs = tops.map((t) => t.kids[0]);
		const appear = r() < 0.5 || blgs[0].kids.length < 20;
		const at = Math.floor(r() * blgs[0].kids.length);
		const nx = r() < 0.5 ? 0 : 50;
		for (const b of blgs) {
			if (appear) { const c = makeDoc(Clip("instance7" + step, { x: nx, y: 0 })); c.parent = b; b.kids.splice(at, 0, c); }
			else { b.kids[at].parent = null; b.kids.splice(at, 1); }
		}
	} else if (kind < 0.94) {
		// a second WatchOutline_mc nested earlier in depth-first order (first match moves)
		for (const t of tops) { const b = t.kids[0]; const host = b.kids[2]; if (host && host.kids) { const o = Clip("WatchOutline_mc", { x: 3, y: 4 }); add(host, o); makeDoc(o); } }
	} else {
		// the cap moves off the outline pose and back (cap proof flips)
		for (const t of tops) { const cap = t.kids[0].kids.find((k) => k.name === "instance540"); if (cap) cap.x = cap.x > 1 ? 0.5 : 9; }
	}
}

// ---- 1. Steady frames per style: same results, finds per loop before and after ----
const N_DOCS = countDocs(buildBlg(7));
expect(N_DOCS > 400 && N_DOCS < 560, "synthetic BottomLeftGroup holds " + N_DOCS + " containers in 27 children");
const perStyle = {};
for (const style of [0, 1, 2, 3, 4]) {
	const tO = makeRoot(7), tN = makeRoot(7);
	const o = makeHost("old", tO, style), n = makeHost("new", tN, style);
	const cO = Object.assign({}, PH), cN = Object.assign({}, PH);
	let same = true, diff = "";
	const LOOPS = 30;
	for (let f = 0; f < LOOPS; f++) {
		frame(o, cO); frame(n, cN);
		exitFrame(o, cO); exitFrame(n, cN);
		const a = snap(o), b = snap(n);
		if (a.replace(/ stHide=\d+/, "") !== b.replace(/ stHide=\d+/, "")) { same = false; diff = firstDiff(a, b); break; }
	}
	expect(same, "style " + style + ": 30 steady loops give the same hide/show state" + (diff ? " (" + diff + ")" : ""));
	expect(n.hz43OlDepth === 0 && n.hz43OlRef === null && n.hz43OlHave === false, "style " + style + ": no outline memo left after the loops");
	perStyle[style] = { old: cO, neu: cN, holds: n.hzPcHoldN, hit: n.hzPcOlHit, miss: n.hzPcOlMiss };
	const per = (c) => Math.round((c.sync + c.loop + c.h43 + c.exit) / LOOPS);
	console.log("    finds/loop style " + style + ": before " + per(cO) + " (sync " + cO.sync / LOOPS + ", loop " + cO.loop / LOOPS + ", h43 " + cO.h43 / LOOPS + ", exit " + cO.exit / LOOPS + ")"
		+ "  after " + per(cN) + " (sync " + cN.sync / LOOPS + ", loop " + cN.loop / LOOPS + ", h43 " + cN.h43 / LOOPS + ", exit " + cN.exit / LOOPS + ")"
		+ "  holds=" + n.hzPcHoldN + " olHit=" + n.hzPcOlHit + " olMiss=" + n.hzPcOlMiss);
}
{
	const s1 = perStyle[1];
	const before = (s1.old.sync + s1.old.h43 + s1.old.exit) / 30, after = (s1.neu.sync + s1.neu.h43 + s1.neu.exit) / 30;
	expect(before > 1000 && after < 60, "style 1 (the run): syncHide + h43 + xVanLate finds per loop " + before + " -> " + after);
	expect(s1.holds === 0, "style 1: the show pass runs no marker-holder walk (holds=0)");
	const s3 = perStyle[3];
	const b3 = (s3.old.h43 + s3.old.exit) / 30, a3 = (s3.neu.h43 + s3.neu.exit) / 30;
	expect(a3 < b3, "style 3: h43 + exit finds per loop " + b3 + " -> " + a3 + " (marker walks stay, one walk per call instead of three)");
}

// ---- 2. Randomized sequences: mode changes, F11 toggles, clips appearing and disappearing, menu recreate ----
for (const seed of [1, 2, 3, 4, 5, 6, 7, 8]) {
	const r = rng(seed * 7919);
	let tO = makeRoot(seed), tN = makeRoot(seed);
	let style = seed % 5;
	let o = makeHost("old", tO, style), n = makeHost("new", tN, style);
	let same = true, diff = "", at = -1, styles = new Set(), recreates = 0;
	for (let step = 0; step < 400 && same; step++) {
		const k = r();
		if (k < 0.06) {
			// F11: WatchStyle change (SetLive path re-arms ShowVanilla like hzSetLive does)
			style = Math.floor(r() * 5);
			for (const h of [o, n]) { h.hzWatchStyle = style; h.hz43VanShown = 0; h.hz43VanTries = 0; }
		} else if (k < 0.09) {
			// F11 open/close with no change, or the hide list marked stale: nothing to do in these paths but a full frame
			for (const h of [o, n]) h.hzHideCache = null;
		} else if (k < 0.11) {
			// menu recreate: a new movie instance, new tree, fresh AS state (nothing carries over)
			recreates++;
			tO = makeRoot(seed + 100 + step); tN = makeRoot(seed + 100 + step);
			o = makeHost("old", tO, style); n = makeHost("new", tN, style);
		} else if (k < 0.13) {
			// BottomLeftGroup replaced under a live instance (hzBlg re-found): memo must not follow the old group
			const nb = [tO, tN].map((t) => { const b = buildBlg(seed + 500 + step); b.parent = t; t.kids[0].parent = null; t.kids[0] = b; return b; });
			o.hzBlg = nb[0]; n.hzBlg = nb[1]; o.hz43VanRing = null; n.hz43VanRing = null; o.hz43HidN = 0; n.hz43HidN = 0;
		} else {
			mutate(r, [tO, tN], step);
		}
		styles.add(style);
		frame(o); frame(n);
		if (r() < 0.5) mutate(r, [tO, tN], step + 1000);   // the timeline runs between enterFrame and exitFrame
		exitFrame(o); exitFrame(n);
		const a = snap(o), b = snap(n);
		if (a.replace(/ stHide=\d+/, "") !== b.replace(/ stHide=\d+/, "")) { same = false; diff = firstDiff(a, b); at = step; }
		if (n.hz43OlDepth !== 0 || n.hz43OlRef !== null) { same = false; diff = "memo left open"; at = step; }
	}
	expect(same, "seed " + seed + ": 400 mixed frames (styles " + Array.from(styles).sort().join("") + ", " + recreates + " recreates) give the same state" + (diff ? " at step " + at + ": " + diff : ""));
}

// ---- 3. Outline memo: exact first-match, never outside a pass, never across groups, safe on a throw ----
{
	const t = makeRoot(11);
	const h = makeHost("new", t, 1);
	const blg = h.hzBlg;
	const plain = h.hzFindByName(blg, "WatchOutline_mc", 0);
	expect(h.hz43VanOutline() === plain && h.hzPcOlMiss === 0 && h.hzPcOlHit === 0, "outside a pass the outline lookup is the plain search and is not memoized");
	h.hz43OlBegin();
	const a = h.hz43VanOutline(), b = h.hz43VanOutline();
	expect(a === plain && b === plain && h.hzPcOlMiss === 1 && h.hzPcOlHit === 1, "inside a pass: one search, then the memo");
	h.hz43OlBegin(); h.hz43VanOutline(); h.hz43OlEnd();
	expect(h.hz43OlDepth === 1 && h.hz43OlHave === true && h.hzPcOlHit === 2, "nested pass shares the memo; inner close keeps it");
	h.hz43OlEnd();
	expect(h.hz43OlDepth === 0 && h.hz43OlRef === null && h.hz43OlBlg === null, "outer close drops the memo and its ref");
	// first match moves between passes (nested duplicate earlier in depth-first order)
	const dup = Clip("WatchOutline_mc", { x: 9, y: 9 }); add(blg.kids[0], dup); makeDoc(dup);
	h.hz43OlBegin();
	expect(h.hz43VanOutline() === h.hzFindByName(blg, "WatchOutline_mc", 0), "a new pass re-searches, so it follows a moved first match");
	h.hz43OlEnd();
	// group swap inside an open pass: memo keyed to hzBlg
	const t2 = makeRoot(12);
	h.hz43OlBegin(); h.hz43VanOutline();
	h.hzBlg = t2.kids[0];
	expect(h.hz43VanOutline() === h.hzFindByName(t2.kids[0], "WatchOutline_mc", 0), "a different hzBlg inside a pass is searched, not served from the memo");
	h.hz43OlEnd();
	h.hzBlg = blg;
	// throw mid-pass: rethrown, memo closed
	let threw = false;
	blg.__throwAt = 5;
	try { h.hz43VanBlgChrome(false); } catch (e) { threw = e instanceof RangeError; }
	expect(threw && h.hz43OlDepth === 0 && h.hz43OlRef === null, "a throw inside hz43VanBlgChrome is rethrown and closes the pass");
	const t3 = makeRoot(13); const h3 = makeHost("new", t3, 3); h3.hz43VanShown = 1;
	const kidsBox = h3.hzBlg.kids.find((k) => k.name === "WatchIconsWidget_mc");
	h3.hzBlg.__throwAt = 7;
	threw = false;
	try { h3.hz43VanChrome(true); } catch (e) { threw = true; }
	expect(threw && h3.hz43OlDepth === 0 && h3.hz43OlRef === null && !!kidsBox, "a throw inside hz43VanChrome(true) closes both nested passes");
	const after = h.hz43VanOutline();
	expect(after === h.hzFindByName(blg, "WatchOutline_mc", 0) && h.hz43OlHave === false, "after the throw, lookups are plain searches again");
}

// ---- 4. hz43VanHoldsMark: one walk gives the per-name answer on every clip of every tree ----
{
	let n = 0, bad = 0;
	for (const seed of [21, 22, 23]) {
		for (const noNested of [false, true]) {
			const tO = makeRoot(seed, { noNestedMark: noNested }), tN = makeRoot(seed, { noNestedMark: noNested });
			const o = makeHost("old", tO, 3), h = makeHost("new", tN, 3);
			const po = allPaths(tO), pn = allPaths(tN);
			for (let i = 0; i < po.length; i++) {
				const a = nodeAt(tO, po[i]), b = nodeAt(tN, pn[i]);
				if (!a.kids) continue;
				n++;
				if (o.hz43VanHoldsMark(a) !== h.hz43VanHoldsMark(b)) bad++;
			}
			// depth limit: a marker 10 levels down is past hzFindByName's depth 8 on both sides
			const mk = (t) => { let c = t.kids[0].kids[1 + 2]; for (let d = 0; d < 10; d++) { const x = Clip("deep" + d); add(c, x); makeDoc(x); c = x; } const m = Clip("WatchIconsWidget_mc"); add(c, m); makeDoc(m); return t.kids[0].kids[3]; };
			const bo = mk(tO), bn = mk(tN);
			n++;
			if (o.hz43VanHoldsMark(bo) !== h.hz43VanHoldsMark(bn)) bad++;
		}
	}
	expect(n > 2000 && bad === 0, "HoldsMark single walk equals the three per-name walks on " + n + " containers (0 mismatches)");
	const h = makeHost("new", makeRoot(5), 3);
	expect(h.hz43VanHoldsMark(null) === false, "HoldsMark(null) is false");
}

// ---- 5. Source pins ----
{
	const blg = fnText(as, "hz43VanBlgChrome").body;
	expect(blg.indexOf("var holds") < 0 && blg.indexOf("!mark && (named || capArt || ringArt) && !this.hz43VanHoldsMark(d as DisplayObjectContainer)") >= 0,
		"BlgChrome walks marker holders only in the hide branch, after the cheap tests");
	expect(blg.indexOf("this.hz43OlBegin();") >= 0 && blg.split("this.hz43OlEnd();").length === 3 && blg.indexOf("throw eOl;") >= 0, "BlgChrome opens one pass and closes it on both exits");
	const vc = fnText(as, "hz43VanChrome").body;
	expect(vc.indexOf("this.hz43OlBegin();") >= 0 && vc.split("this.hz43OlEnd();").length === 3 && vc.indexOf("throw eOc;") >= 0, "VanChrome(true) opens one pass and closes it on both exits");
	expect(fnText(as, "hz43VanCapClip").body.indexOf("hzFindByName") < 0 && fnText(as, "hz43VanRingProof").body.indexOf("hzFindByName") < 0, "cap and annulus proofs use hz43VanOutline");
	const fm = fnText(as, "hz43FindMark").body, fb = fnText(as, "hzFindByName").body;
	const excl = (s) => (s.match(/ch != this\.\w+/g) || []).join(",");
	expect(excl(fm) === excl(fb) && fm.indexOf("depth > 8") >= 0, "FindMark skips the same Horizon panels and depth as hzFindByName");
	expect(fnText(as, "hz43SyncHide").body.indexOf("hzFrameN %") < 0 && fnText(as, "hz43VanBlgChrome").body.indexOf("hzFrameN") < 0
		&& fnText(as, "hz43VanChrome").body.indexOf("hzFrameN") < 0, "no frame-interval gating added to the hide paths");
	const parts = fnText(as, "hzPerfParts").body;
	expect(parts.indexOf('" | hc holds=" + this.hzPcHoldN + " olHit=" + this.hzPcOlHit + " olMiss=" + this.hzPcOlMiss') >= 0, "parts line reports holds, olHit, olMiss");
	const clr = fnText(as, "hzPbClear").body;
	expect(clr.indexOf("this.hzPcHoldN = 0;") >= 0 && clr.indexOf("this.hzPcOlHit = 0;") >= 0 && clr.indexOf("this.hzPcOlMiss = 0;") >= 0, "window clear resets the new counters");
	for (const f of ["hz43VanOutline", "hz43OlBegin", "hz43OlEnd", "hz43IsMark", "hz43FindMark", "hz43VanHoldsMark", "hz43VanBlgChrome", "hz43VanChrome"]) {
		const b = fnText(as, f).body;
		expect(!/\bnew\s|removeChild|\+= "|" \+/.test(b), f + ": no allocation, string building, or removeChild");
	}
}

if (failed > 0) { console.error(failed + " failed"); process.exit(1); }
console.log("hidecache model tests passed");
