// Hide-path redundant-work fix (hidewalk): proves that
//  1. the hide-list rebuild with one tree walk (hz36HideFindAll / hz36Walk) gives the same hzHideCache entries, in the same
//     order, as the 80327fe per-name loop (one hzFindByName per name), on random trees, name lists and throws, and
//  2. hz36HideTick / hz43StHide without the repeated hz43VanWatchClip checks (hz43StHideV, hz43VanNoteAdd) leave the same
//     display state, hid list, ring memo, stale flag and counters as the 80327fe bodies, frame by frame.
// The 80327fe bodies are frozen below (REF_80327FE). Both sides run the production AS from horizon_block.as for every
// other function. Run: node tests/hidewalk_model_test.js
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

// 80327fe: the rebuild loop of hzOnFrame (as a function of the searched root c; in hzOnFrame c is this), and the three
// hide-tick bodies this commit changes.
const REF_80327FE = `      private function hz36RebuildOld(c:DisplayObjectContainer, names:Array, out:Array) : void
      {
            for each(var n:String in names)
            {
               try { this.hz36HideFind(c,n,out); } catch(e36f:Error) { }   // v0.36: parent + name kept
            }
      }

      private function hz36HideTick() : void
      {
         if(this.hzHideCache == null) { return; }
         for each(var e:Object in this.hzHideCache)
         {
            if(e == null) { continue; }
            var d:DisplayObject = e.d;
            try
            {
               var p:DisplayObjectContainer = e.p;
               if(p != null)
               {
                  var cur:DisplayObject = p.getChildByName(String(e.n));
                  if(cur != null && cur != d) { e.d = cur; d = cur; }
               }
            }
            catch(errP:Error) { }
            if(d == null) { continue; }
            if(d.stage == null) { this.hz36HideStale = true; }
            if(this.hz43VanWatchClip(d)) { this.hz43StHide(d); continue; }
            if(d.visible) { d.visible = false; }
            if(d.alpha != 0) { d.alpha = 0; }
         }
      }

      private function hz43StHide(d:DisplayObject) : void
      {
         if(this.hzPerfOn) { this.hzPcStHide++; }
         if(!d || !this.hz43VanWatchClip(d)) { return; }
         this.hz43VanNote(d);
         if(d.visible) { d.visible = false; }
      }

      private function hz43VanNote(d:DisplayObject) : void
      {
         if(!d || !this.hz43VanWatchClip(d)) { return; }
         if(this.hz43HidA == null) { this.hz43HidA = new Array(HZ43_HID_MAX); }
         var i:int = 0;
         while(i < this.hz43HidN)
         {
            if(this.hz43HidA[i] == d) { return; }
            i++;
         }
         if(this.hz43HidN >= HZ43_HID_MAX) { return; }
         this.hz43HidA[this.hz43HidN] = d;
         this.hz43HidN++;
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
// AS3 to JS for the bodies used here. Typed catches keep AS3 semantics: catch(e:Error) lets a non-Error value pass.
function toJs(body) {
	return body
		.replace(/for each\s*\(\s*var\s+(\w+)\s*:\s*[\w.*]+\s+in\s+/g, "for (var $1 of ")
		.replace(/(\w+) is DisplayObjectContainer\b/g, "__isDoc($1)")
		.replace(/\bDisplayObjectContainer\(/g, "(")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*\*\s*\)/g, "catch($1)")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.]+\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
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
function rng(seed) { let s = seed >>> 0; return function() { s = (s * 1664525 + 1013904223) >>> 0; return s / 4294967296; }; }
function mutant(from, to) { if (as.indexOf(from) < 0) throw new Error("mutant anchor missing: " + from); return as.replace(from, to); }

// ---- display tree model ----
// Containers have kids (null slots allowed, as getChildAt can hand back null); leaves have kids == null.
// getChildAt can be made to throw at one index, once (__throwOnce) or every time (__throwAlways).
// stage is non-null only while the clip is attached under a tree root (__stageRoot).
let uidTree = 0;
const ClipProto = {};
Object.defineProperty(ClipProto, "stage", { get: function() { let c = this; while (c.parent) c = c.parent; return c.__stageRoot ? c : null; } });
function Clip(name, opts) {
	opts = opts || {};
	const c = Object.create(ClipProto);
	Object.assign(c, { key: ++uidTree, name: name, visible: opts.visible !== false, alpha: opts.alpha == null ? 1 : opts.alpha, x: opts.x || 0, y: opts.y || 0,
		scaleX: opts.scaleX == null ? 1 : opts.scaleX, scaleY: opts.scaleY == null ? 1 : opts.scaleY, parent: null, kids: opts.leaf ? null : [] });
	if (c.kids) makeDoc(c);
	return c;
}
function makeDoc(c) {
	Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; }, configurable: true });
	c.getChildAt = function(i) {
		if (this.__throwAlways && this.__throwAlways.at === i) throw this.__throwAlways.v;
		if (this.__throwOnce && this.__throwOnce.at === i) { const v = this.__throwOnce.v; this.__throwOnce = null; throw v; }
		return this.kids[i];
	};
	c.getChildByName = function(n) { for (const k of this.kids) if (k && k.name === n) return k; return null; };
	c.getChildIndex = function(d) { const i = this.kids.indexOf(d); if (i < 0) throw new Error("not a child"); return i; };
}
function add(p, c) { if (c) c.parent = p; p.kids.push(c); return c; }
function __isDoc(x) { return !!(x && x.kids); }
global.__isDoc = __isDoc;
const CARD_MEMBERS = ["HorizonCard_mc", "HorizonVitals_mc", "HorizonEnv_mc", "HorizonCompass_mc", "HorizonAffl_mc", "HorizonAmmo_mc", "HorizonQuest_mc",
	"HorizonCompact_mc", "HorizonCompactQuest_mc", "HorizonSettings_mc"];

// The names hzOnFrame can put on the hide list (taken from the source, so they follow the code).
function hideNames() {
	const b = fnText(as, "hzOnFrame").body;
	const out = [];
	const re = /names\.push\(([^)]*)\)/g;
	let m;
	while ((m = re.exec(b))) for (const s of m[1].split(",")) out.push(JSON.parse(s.trim()));
	return out;
}
const HIDE_NAMES = hideNames();

// ===================== 1. hide-list rebuild: one walk vs one search per name =====================
const WFUNCS = ["hzFindByName", "hz36HideFind"];
function makeWHost(kind, top, cards, src) {
	const h = { int: function(n) { return n | 0; }, trace: function() {}, __isDoc: __isDoc, hzPerfOn: true, hzPcFind: 0, hzPcHrWalk: 0, hzPcHrFb: 0 };
	for (const k of CARD_MEMBERS) h[k] = cards[k] || null;
	for (const f of WFUNCS) bind(h, src || as, f);
	if (kind === "old") bind(h, REF_80327FE, "hz36RebuildOld");
	else { bind(h, src || as, "hz36HideFindAll"); bind(h, src || as, "hz36Walk"); }
	h.__top = top;
	h.rebuild = kind === "old" ? function(names, out) { h.hz36RebuildOld(top, names, out); } : function(names, out) { h.hz36HideFindAll(top, names, out); };
	return h;
}
// Random HUD-like tree: nested containers with wanted names at any depth (also several times, under each other, as
// leaves, below the depth limit and inside Horizon cards), null slots, null and empty names.
function randTree(seed) {
	const r = rng(seed);
	const top = Clip("root");
	top.__stageRoot = true;
	const conts = [top];
	const pool = HIDE_NAMES.concat(["Other_mc", "HealthBar_mc", "instance12", ""]);
	const n = 150 + Math.floor(r() * 650);
	for (let i = 0; i < n; i++) {
		const p = r() < 0.6 ? conts[conts.length - 1 - Math.floor(r() * Math.min(conts.length, 12))] : conts[Math.floor(r() * conts.length)];
		const q = r();
		const name = q < 0.12 ? pool[Math.floor(r() * pool.length)] : (q < 0.14 ? null : "n" + i);
		if (r() < 0.02) { add(p, null); continue; }
		const leaf = r() < 0.25;
		const c = add(p, Clip(name, { leaf: leaf }));
		if (!leaf) conts.push(c);
	}
	// a deep chain with wanted names around the depth limit
	let d = conts[Math.floor(r() * conts.length)];
	for (let k = 0; k < 14; k++) {
		d = add(d, Clip(r() < 0.35 ? HIDE_NAMES[Math.floor(r() * HIDE_NAMES.length)] : "deep" + k));
	}
	// Horizon cards (pruned by hzFindByName) holding wanted names
	const cards = {};
	for (const k of CARD_MEMBERS) {
		if (r() < 0.4) {
			const card = add(conts[Math.floor(r() * Math.min(conts.length, 30))], Clip(k));
			cards[k] = card;
			for (let j = 0; j < 4; j++) add(card, Clip(HIDE_NAMES[Math.floor(r() * HIDE_NAMES.length)], { leaf: r() < 0.5 }));
		}
	}
	return { top, cards, r };
}
function randNames(r) {
	const out = [];
	const n = Math.floor(r() * 32);
	for (let i = 0; i < n; i++) out.push(r() < 0.85 ? HIDE_NAMES[Math.floor(r() * HIDE_NAMES.length)] : (r() < 0.5 ? "Missing" + i + "_mc" : ""));
	return out;
}
function sameEntries(a, b) {
	if (a.length !== b.length) return "length " + a.length + " vs " + b.length;
	for (let i = 0; i < a.length; i++) {
		if (a[i].n !== b[i].n || a[i].d !== b[i].d || a[i].p !== b[i].p) return "entry " + i + " (" + a[i].n + " vs " + b[i].n + ")";
	}
	return "";
}
function sameThrow(a, b) { return typeof a === typeof b && (a instanceof Error ? (b instanceof Error && a.message === b.message) : a === b); }

let lists = 0, entries = 0, findsOld = 0, findsNew = 0, dupLists = 0, missLists = 0;
for (let seed = 1; seed <= 40; seed++) {
	const t = randTree(seed);
	const ho = makeWHost("old", t.top, t.cards), hn = makeWHost("new", t.top, t.cards);
	let bad = "";
	for (let k = 0; k < 25 && !bad; k++) {
		const names = k === 0 ? HIDE_NAMES.slice() : randNames(t.r);
		if (new Set(names).size < names.length) dupLists++;
		const a = [], b = [];
		const f0 = ho.hzPcFind, f1 = hn.hzPcFind;
		ho.rebuild(names, a); hn.rebuild(names, b);
		findsOld += ho.hzPcFind - f0; findsNew += hn.hzPcFind - f1;
		if (b.length < names.length) missLists++;
		bad = sameEntries(a, b);
		if (!bad && hn.hzPcFind - f1 > Math.max(ho.hzPcFind - f0, 0) && names.length > 0) bad = "the walk searched more nodes than the per-name loop (" + (hn.hzPcFind - f1) + " > " + (ho.hzPcFind - f0) + ")";
		lists++; entries += a.length;
	}
	expect(!bad, "walk seed " + seed + ": 25 name lists give the same entries (clip, parent, name, order) as one search per name" + (bad ? " -- " + bad : ""));
}
expect(dupLists > 0 && missLists > 0, "walk: lists with duplicate names (" + dupLists + ") and names not in the tree (" + missLists + ") covered");
console.log("    walk: " + lists + " lists, " + entries + " entries; nodes searched " + findsOld + " (per name) -> " + findsNew + " (one walk)");

// The run's list (style 0, HideVanillaWatch=1, HideVanillaCompass=1) on a HUD-sized model tree: one walk instead of 19+.
{
	const t = randTree(777);
	const ho = makeWHost("old", t.top, t.cards), hn = makeWHost("new", t.top, t.cards);
	const a = [], b = [];
	ho.rebuild(HIDE_NAMES, a); hn.rebuild(HIDE_NAMES, b);
	expect(!sameEntries(a, b), "walk: the full hzOnFrame name list (" + HIDE_NAMES.length + " names) gives the same entries");
	console.log("    full list: nodes searched " + ho.hzPcFind + " -> " + hn.hzPcFind + " (walks " + hn.hzPcHrWalk + ", fallbacks " + hn.hzPcHrFb + ")");
}

// Throws. A deterministic Error (getChildAt throws every time at one slot): the walk throws, the per-name loop runs, and
// every name whose search reaches that slot is skipped exactly as before. A non-Error value propagates as before, with
// the same entries already pushed.
{
	let errN = 0, valN = 0, fb = 0, bad = "";
	for (let seed = 1; seed <= 30 && !bad; seed++) {
		const t = randTree(500 + seed);
		const all = [];
		(function walk(c) { if (c && c.kids) { if (c.kids.length) all.push(c); c.kids.forEach(walk); } })(t.top);
		const at = all[Math.floor(t.r() * all.length)];
		const v = seed % 3 === 0 ? "string throw" : (seed % 3 === 1 ? new RangeError("persistent") : 7);
		at.__throwAlways = { at: Math.floor(t.r() * at.kids.length), v: v };
		const ho = makeWHost("old", t.top, t.cards), hn = makeWHost("new", t.top, t.cards);
		const names = HIDE_NAMES.concat(randNames(t.r));
		const a = [], b = [];
		let eo = "none", en = "none";
		try { ho.rebuild(names, a); } catch (e) { eo = e; }
		try { hn.rebuild(names, b); } catch (e) { en = e; }
		fb += hn.hzPcHrFb;
		if (v instanceof Error) errN++; else valN++;
		const d = sameEntries(a, b);
		if (d) bad = "seed " + seed + ": " + d;
		else if (!(eo === "none" && en === "none") && !sameThrow(eo, en)) bad = "seed " + seed + ": thrown values differ";
		else if (eo === "none" && en !== "none") bad = "seed " + seed + ": only the new code threw";
	}
	expect(!bad, "walk throws: Error and non-Error values on random slots give the same entries and the same thrown value" + (bad ? " -- " + bad : ""));
	expect(errN > 0 && valN > 0 && fb > 0, "walk throws covered: Error " + errN + ", other values " + valN + ", fallbacks taken " + fb);
}

// Bot 3 S1: one-off throws (__throwOnce: getChildAt throws once at one slot, then works). The 80327fe per-name loop lost
// the one name whose search hit the throw (Error) or stopped the whole rebuild (non-Error). The walk uses up the throw,
// then the per-name fallback runs clean, so the new list holds every old entry (same name, same clip) and never fewer;
// a non-Error no longer escapes. This is the only behavior difference, and only on a throw path.
{
	let runs = 0, more = 0, same = 0, oldThrew = 0, newThrew = 0, bad = "";
	for (let seed = 1; seed <= 200 && !bad; seed++) {
		for (const kind of ["error", "value"]) {
			const mk = () => {
				const t = randTree(900 + seed);
				const all = [];
				(function walk(c) { if (c && c.kids) { if (c.kids.length) all.push(c); c.kids.forEach(walk); } })(t.top);
				const at = all[Math.floor(t.r() * all.length)];
				at.__throwOnce = { at: Math.floor(t.r() * at.kids.length), v: kind === "error" ? new RangeError("once") : "once" };
				return t;
			};
			const to = mk(), tn = mk();
			const ho = makeWHost("old", to.top, to.cards), hn = makeWHost("new", tn.top, tn.cards);
			const names = HIDE_NAMES.concat(randNames(randTree(900 + seed).r));
			const a = [], b = [];
			try { ho.rebuild(names, a); } catch (e) { oldThrew++; }
			try { hn.rebuild(names, b); } catch (e) { newThrew++; bad = "seed " + seed + " " + kind + ": the new code threw"; }
			runs++;
			// the two trees are built from the same seed, so compare by tree path (clip key order is the same)
			const key = (e) => { const p = []; let d = e.d; while (d && d.parent) { p.push(d.parent.kids.indexOf(d)); d = d.parent; } return e.n + "@" + p.join("/"); };
			const kb = b.map(key);
			for (const e of a) { if (kb.indexOf(key(e)) < 0) { bad = bad || ("seed " + seed + " " + kind + ": an old entry is missing (" + key(e) + ")"); } }
			if (b.length > a.length) more++; else if (b.length === a.length) same++;
		}
	}
	expect(!bad, "S1 one-off throws: the new list holds every 80327fe entry, never fewer, and never throws (" + runs + " runs)" + (bad ? " -- " + bad : ""));
	expect(more > 0 && oldThrew > 0 && newThrew === 0, "S1 one-off throws covered: new list longer in " + more + " runs, equal in " + same + ", 80327fe threw in " + oldThrew + ", new code threw in " + newThrew);
}

// Bot 3 S2: an Error from the parent read in the push loop is swallowed per name (as the 80327fe per-name try did),
// so the other entries are kept, in order, and nothing escapes. A mutant without the per-entry try lets it escape.
{
	const s2 = (src) => {
		let bad = "", hits = 0;
		for (let seed = 1; seed <= 40 && !bad; seed++) {
			const t = randTree(1300 + seed);
			const found = [];
			(function walk(c, depth) { if (!c || !c.kids || depth > 8) return; for (const k of c.kids) { if (k && HIDE_NAMES.indexOf(k.name) >= 0) found.push(k); if (k) walk(k, depth + 1); } })(t.top, 0);
			if (!found.length) continue;
			const victim = found[Math.floor(t.r() * found.length)];
			const realParent = victim.parent;
			let armed = false;
			Object.defineProperty(victim, "parent", { get() { if (armed) throw new RangeError("parent read"); return realParent; }, set(v) { }, configurable: true });
			const ho = makeWHost("old", t.top, t.cards), hn = makeWHost("new", t.top, t.cards, src);
			const a = [], b = [];
			let eo = null, en = null;
			armed = true;
			try { ho.rebuild(HIDE_NAMES, a); } catch (e) { eo = e; }
			try { hn.rebuild(HIDE_NAMES, b); } catch (e) { en = e; }
			armed = false;
			hits++;
			if (en) { bad = "seed " + seed + ": the Error escaped"; break; }
			if (eo) { bad = "seed " + seed + ": 80327fe threw (harness)"; break; }
			const d = sameEntries(a, b);
			if (d) bad = "seed " + seed + ": " + d;
		}
		return { bad: bad, hits: hits };
	};
	const r = s2(null);
	expect(!r.bad && r.hits > 10, "S2: an Error from the parent read drops only that name, same entries as 80327fe, no escape (" + r.hits + " trees)" + (r.bad ? " -- " + r.bad : ""));
	const m = s2(mutant("            try\n            {\n               var d:DisplayObject = wd[wn.indexOf(m)] as DisplayObject;\n               if(d == null) { continue; }\n               out.push({\"p\":d.parent,\"n\":m,\"d\":d});\n            }\n            catch(eHp:Error) { }",
		"            {\n               var d:DisplayObject = wd[wn.indexOf(m)] as DisplayObject;\n               if(d == null) { continue; }\n               out.push({\"p\":d.parent,\"n\":m,\"d\":d});\n            }"));
	expect(!!m.bad, "S2 mutant killed: the push loop without the per-entry try");
}

// Mutants of the walk must be killed by the same comparison.
function walkKilled(src) {
	for (let seed = 1; seed <= 40; seed++) {
		const t = randTree(seed);
		const ho = makeWHost("old", t.top, t.cards), hn = makeWHost("new", t.top, t.cards, src);
		for (let k = 0; k < 25; k++) {
			const names = k === 0 ? HIDE_NAMES.slice() : randNames(t.r);
			const a = [], b = [];
			try { ho.rebuild(names, a); hn.rebuild(names, b); } catch (e) { return true; }
			if (sameEntries(a, b)) return true;
		}
	}
	return false;
}
const WMUT = [
	["no depth limit", "         if(this.hzPerfOn) { this.hzPcFind++; }\n         if(depth > 8) { return left; }\n         while(i < c.numChildren)", "         if(this.hzPerfOn) { this.hzPcFind++; }\n         while(i < c.numChildren)"],
	["no Horizon-card pruning", "if(ch is DisplayObjectContainer && ch != this.HorizonCard_mc && ch != this.HorizonVitals_mc && ch != this.HorizonEnv_mc && ch != this.HorizonCompass_mc && ch != this.HorizonAffl_mc && ch != this.HorizonAmmo_mc && ch != this.HorizonQuest_mc && ch != this.HorizonCompact_mc && ch != this.HorizonCompactQuest_mc && ch != this.HorizonSettings_mc)\n               {\n                  left = this.hz36Walk(", "if(ch is DisplayObjectContainer)\n               {\n                  left = this.hz36Walk("],
	["a later match overwrites the first", "if(k >= 0 && wd[k] == null)", "if(k >= 0)"],
	["a matched node is not descended into", "               if(ch is DisplayObjectContainer && ch != this.HorizonCard_mc", "               else if(ch is DisplayObjectContainer && ch != this.HorizonCard_mc"],
	["entries in first-found order, not names order (no duplicates)", "         for each(var m:String in names)\n         {\n            try\n            {\n               var d:DisplayObject = wd[wn.indexOf(m)] as DisplayObject;", "         for each(var m:String in wn)\n         {\n            try\n            {\n               var d:DisplayObject = wd[wn.indexOf(m)] as DisplayObject;"]
];
for (const m of WMUT) {
	const src = mutant(m[1], m[2]);
	expect(walkKilled(src), "walk mutant killed: " + m[0]);
}
{
	// No fallback: the catch keeps the partial walk. For an Error that throws every time this is an equivalent mutant (every
	// per-name search walks the same order, so a name is found exactly when its first match comes before the throwing slot,
	// which is what the partial walk holds). A non-Error value must still propagate as before, so that kills it.
	const src = mutant("         catch(eHw:*)\n         {\n            wn = null;\n         }", "         catch(eHw:*)\n         {\n         }");
	let killed = false;
	for (let seed = 1; seed <= 30 && !killed; seed++) {
		const t = randTree(500 + seed);
		const all = [];
		(function walk(c) { if (c && c.kids) { if (c.kids.length) all.push(c); c.kids.forEach(walk); } })(t.top);
		const at = all[Math.floor(t.r() * all.length)];
		at.__throwAlways = { at: Math.floor(t.r() * at.kids.length), v: "non-Error" };
		const ho = makeWHost("old", t.top, t.cards), hn = makeWHost("new", t.top, t.cards, src);
		const a = [], b = [];
		let eo = "none", en = "none";
		try { ho.rebuild(HIDE_NAMES, a); } catch (e) { eo = e; }
		try { hn.rebuild(HIDE_NAMES, b); } catch (e) { en = e; }
		if (eo !== en || sameEntries(a, b)) killed = true;
	}
	expect(killed, "walk mutant killed: no per-name fallback after a throw");
}

// ===================== 2. hide tick without the repeated watch-clip checks =====================
const TFUNCS = ["hzFindByName", "hz43VanSkip", "hz43VanMarkName", "hz43VanInstName", "hz43VanCapClip", "hz43VanRingProof", "hz43VanRingClip",
	"hz43VanNamed", "hz43VanRootOf", "hz43VanWatchClip", "hz43VanOutline", "hz43OlBegin", "hz43OlEnd", "hz36HideFind"];
const TCHANGED = ["hz36HideTick", "hz43StHide", "hz43VanNote"];
const TNEW_ONLY = ["hz43StHideV", "hz43VanNoteAdd"];
function makeTHost(kind, top, style, src) {
	const h = {
		int: function(n) { return n | 0; }, trace: function() {}, __isDoc: __isDoc,
		hzPerfOn: true, hzPcFind: 0, hzPcStHide: 0, hzPcOlHit: 0, hzPcOlMiss: 0, hzPcWcSkip: 0,
		hz43OlDepth: 0, hz43OlHave: false, hz43OlRef: null, hz43OlBlg: null,
		hzBlg: top.kids[0], hzWatchStyle: style, hzHideCache: [], hz36HideStale: false,
		hz43VanRing: null, hz43HidA: null, hz43HidN: 0,
		HZ43_VAN_N: constArr("HZ43_VAN_N"), HZ43_HID_MAX: constNum("HZ43_HID_MAX"), HZ43_VAN_FACE: constNum("HZ43_VAN_FACE")
	};
	for (const k of CARD_MEMBERS) h[k] = null;
	for (const f of TFUNCS) bind(h, src || as, f);
	for (const f of TCHANGED) bind(h, kind === "old" ? REF_80327FE : (src || as), f);
	if (kind === "new") for (const f of TNEW_ONLY) bind(h, src || as, f);
	bind(h, REF_80327FE, "hz36RebuildOld");
	h.__wc = 0;
	const raw = h.hz43VanWatchClip;
	h.hz43VanWatchClip = function(d) { h.__wc++; return raw(d); };
	h.__top = top;
	return h;
}
// The HUD model: BottomLeftGroup (watch assembly: named chrome, the cap and the annulus, nested art), plus health / ammo /
// compass groups elsewhere in the movie.
function fillT(p, n, r, tag) { let cur = p; for (let m = 0; m < n; m++) { const c = add(cur, Clip(tag + "_" + m)); cur = (m % 4 === 3) ? p : c; if (r() < 0.3) add(c, Clip("shape" + m, { leaf: true })); } }
function buildHud(seed) {
	uidTree = 0;
	const r = rng(seed);
	const top = Clip("root");
	top.__stageRoot = true;
	const blg = add(top, Clip("BottomLeftGroup_mc"));
	fillT(add(blg, Clip("WatchOutline_mc")), 12, r, "ol");
	add(blg, Clip("instance540", { x: 0.5, y: -0.25 }));
	fillT(add(blg, Clip("WatchPointerOutline_mc")), 6, r, "ptr");
	fillT(add(blg, Clip("WatchIconsWidget_mc")), 6, r, "wi");
	fillT(add(blg, Clip("MissionIconsWidget_mc")), 6, r, "mi");
	fillT(add(blg, Clip("EnemyIconsWidget_mc")), 6, r, "ei");
	const o2 = add(blg, Clip("O2CO2_mc"));
	fillT(add(o2, Clip("O2Anim_mc")), 6, r, "o2");
	fillT(add(blg, Clip("O2CO2thin_mc")), 4, r, "thin");
	for (const n of ["DayCycleBase_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc", "Autopilot_mc"]) fillT(add(blg, Clip(n)), 4, r, n);
	for (const n of ["BioCondition_mc", "BioConditionBase_mc", "EnvCondition_mc"]) fillT(add(blg, Clip(n)), 3, r, n);
	fillT(add(blg, Clip("EnvConditionBase_mc")), 3, r, "ecb");
	add(blg, Clip("instance546", { x: 110.5, y: 110.5 }));
	fillT(add(blg, Clip("EnemyDetectionAnim_mc")), 3, r, "eda");
	add(blg, Clip("BioAlertBG_mc"));
	const brg = add(top, Clip("BottomRightGroup_mc"));
	for (const n of ["HealthBar_mc", "HealthBarEmpty_mc", "HealthBarGhost_mc", "HealthBarDamage_mc", "HealthBarIncrease_mc", "Health_mc"]) fillT(add(brg, Clip(n)), 2, r, n);
	const ammo = add(top, Clip("AmmoGroup_mc"));
	for (const n of ["EquippedWeaponAmmo_mc", "EquippedWeaponAmmoTotal_mc", "VerticalDivider_mc", "EquippedWeaponIconHolder_mc", "JetpackMeterWrapper_mc", "JetpackMeterAnim_mc"]) fillT(add(ammo, Clip(n)), 2, r, n);
	return top;
}
function keyOf(x) { return x ? String(x.key) : "null"; }
function tSnap(h) {
	const out = [];
	(function walk(c, p) { if (!c) { out.push(p + "null"); return; } out.push(p + c.key + ":" + c.name + "=" + (c.visible ? 1 : 0) + "/" + c.alpha); if (c.kids) c.kids.forEach((k, i) => walk(k, p + i + "/")); })(h.__top, "");
	const hid = [];
	for (let i = 0; i < h.hz43HidN; i++) hid.push(keyOf(h.hz43HidA[i]));
	out.push("hid=" + hid.join(",") + " n=" + h.hz43HidN + " ring=" + keyOf(h.hz43VanRing) + " stale=" + h.hz36HideStale + " stHide=" + h.hzPcStHide + " blg=" + keyOf(h.hzBlg));
	out.push("cache=" + (h.hzHideCache || []).map((e) => e.n + ":" + keyOf(e.d) + "<" + keyOf(e.p)).join(","));
	out.push("ol=" + h.hz43OlDepth + "/" + h.hz43OlHave + "/" + keyOf(h.hz43OlRef));
	return out.join("\n");
}
function firstDiff(a, b) {
	const x = a.split("\n"), y = b.split("\n");
	for (let i = 0; i < Math.max(x.length, y.length); i++) if (x[i] !== y[i]) return (x[i] || "<none>") + "  vs  " + (y[i] || "<none>");
	return "";
}
function nodeAt(top, p) { let c = top; for (const i of p) { if (!c || !c.kids || i >= c.kids.length) return null; c = c.kids[i]; } return c || null; }
function paths(top) { const all = []; (function walk(c, p) { if (!c) return; all.push(p); if (c.kids) c.kids.forEach((k, i) => walk(k, p.concat([i]))); })(top, []); return all; }
function namesFor(style) {
	// as hzOnFrame builds the list with HideVanillaCompass=1, HideVanillaWatch = style is not 1 or 2, ammo and health hidden
	const n = [];
	if (style === 0) n.push("MissionIconsWidget_mc", "EnemyIconsWidget_mc", "WatchOutline_mc", "DayCycleBase_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc");
	else if (style !== 1 && style !== 2) n.push("WatchOutline_mc", "DayCycleBase_mc", "locationNameBase_mc", "Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc");
	if (style !== 1 && style !== 2) n.push("O2CO2_mc", "O2CO2thin_mc", "WatchOutline_mc", "BioCondition_mc", "BioConditionBase_mc", "EnvCondition_mc", "EnvConditionBase_mc", "BioAlertBG_mc");
	if (style === 0) n.push("WatchIconsWidget_mc", "WatchPointerOutline_mc");
	else if (style === 3 || style === 4) n.push("WatchPointerOutline_mc");
	n.push("EquippedWeaponAmmo_mc", "EquippedWeaponAmmoTotal_mc", "VerticalDivider_mc", "EquippedWeaponIconHolder_mc");
	n.push("HealthBar_mc", "HealthBarEmpty_mc", "HealthBarGhost_mc", "HealthBarDamage_mc", "HealthBarIncrease_mc", "Health_mc");
	return n;
}
function tickWorld(seed, src) {
	const ta = buildHud(seed), tb = buildHud(seed);
	const r = rng(seed * 7 + 1);
	let style = [0, 0, 3, 4, 1][seed % 5];
	const ho = makeTHost("old", ta, style), hn = makeTHost("new", tb, style, src);
	return { ta, tb, ho, hn, r, style };
}
function rebuildBoth(w) {
	const names = namesFor(w.style);
	for (const h of [w.ho, w.hn]) { h.hzHideCache = []; h.hz36HideStale = false; }
	w.ho.hz36RebuildOld(w.ta, names, w.ho.hzHideCache);
	w.hn.hz36RebuildOld(w.tb, names, w.hn.hzHideCache);
}
// One random frame, the same on both trees: native timeline writes, a clip replaced or removed under its name, the ring
// memo stale or set, hzBlg lost and found, scale and position changes of the unnamed art, the hid list near its cap.
const TEV = { write: 0, replace: 0, remove: 0, ring: 0, blg: 0, art: 0, cap: 0, style: 0, staleRebuild: 0 };
function tickEvent(w, step) {
	const r = w.r;
	const both = (fn) => { fn(w.ta, w.ho); fn(w.tb, w.hn); };
	const all = paths(w.ta);
	if (r() < 0.35) { const p = all[1 + Math.floor(r() * (all.length - 1))]; const v = r() < 0.6; const a = r() < 0.5 ? 1 : 0.4; both((t) => { const c = nodeAt(t, p); if (c) { c.visible = v; c.alpha = a; } }); TEV.write++; }
	if (r() < 0.05) {
		// the game hands back a new clip under the same name (timeline jump)
		const i = Math.floor(r() * w.ho.hzHideCache.length);
		both((t, h) => { const e = h.hzHideCache[i]; if (!e || !e.d || !e.d.parent) return; const p = e.d.parent; const k = p.kids.indexOf(e.d); const c = Clip(e.n); c.key = "r" + step + ":" + e.n; c.parent = p; p.kids[k] = c; e.d.parent = null; });
		TEV.replace++;
	}
	if (r() < 0.03) {
		// a clip leaves the stage
		const i = Math.floor(r() * w.ho.hzHideCache.length);
		both((t, h) => { const e = h.hzHideCache[i]; if (!e || !e.d || !e.d.parent) return; const p = e.d.parent; p.kids.splice(p.kids.indexOf(e.d), 1); e.d.parent = null; });
		TEV.remove++;
	}
	if (r() < 0.05) { const p = all[Math.floor(r() * all.length)]; const none = r() < 0.4; both((t, h) => { h.hz43VanRing = none ? null : nodeAt(t, p); }); TEV.ring++; }
	if (r() < 0.03) { const lose = r() < 0.5; both((t, h) => { h.hzBlg = lose ? null : t.kids[0]; }); TEV.blg++; }
	if (r() < 0.06) {
		const nm = r() < 0.5 ? "instance540" : "instance546";
		const sc = r() < 0.3 ? 0.2 : 1, dx = r() < 0.3 ? 5 : 0;
		both((t) => { const c = t.kids[0].getChildByName(nm); if (c) { c.scaleX = sc; c.x += dx; } });
		TEV.art++;
	}
	if (r() < 0.02) { both((t, h) => { h.hz43HidN = Math.min(h.hz43HidN, h.HZ43_HID_MAX - 1); }); TEV.cap++; }
	if (r() < 0.02) { const s2 = [0, 3, 4, 1][Math.floor(r() * 4)]; w.style = s2; both((t, h) => { h.hzWatchStyle = s2; }); rebuildBoth(w); TEV.style++; }
}
let tickFrames = 0, wcOld = 0, wcNew = 0, stOld = 0;
for (let seed = 1; seed <= 12; seed++) {
	const w = tickWorld(seed);
	rebuildBoth(w);
	let bad = "";
	for (let step = 0; step < 400 && !bad; step++) {
		tickEvent(w, step);
		if (w.ho.hz36HideStale) TEV.staleRebuild++;
		if (w.ho.hz36HideStale || step % 90 === 1) rebuildBoth(w);
		const a0 = w.ho.__wc, b0 = w.hn.__wc;
		// the frame runs the tick twice (start and end of hzOnFrame)
		w.ho.hz36HideTick(); w.hn.hz36HideTick();
		w.ho.hz36HideTick(); w.hn.hz36HideTick();
		// chrome-pass style callers of hz43StHide on a random clip, sometimes inside an outline-memo pass
		if (w.r() < 0.3) {
			const p = paths(w.ta)[Math.floor(w.r() * paths(w.ta).length)];
			const inPass = w.r() < 0.5;
			for (const [t, h] of [[w.ta, w.ho], [w.tb, w.hn]]) { const d = nodeAt(t, p); if (inPass) h.hz43OlBegin(); h.hz43StHide(d); if (inPass) h.hz43OlEnd(); }
		}
		if (w.r() < 0.05) { w.ho.hz43StHide(null); w.hn.hz43StHide(null); }
		wcOld += w.ho.__wc - a0; wcNew += w.hn.__wc - b0;
		tickFrames++;
		const a = tSnap(w.ho), b = tSnap(w.hn);
		if (a !== b) bad = "step " + step + " style " + w.style + ": " + firstDiff(a, b);
	}
	stOld += w.ho.hzPcStHide;
	expect(!bad, "tick seed " + seed + ": 400 frames (styles 0/3/4/1, timeline writes, replaced and removed clips, ring and hzBlg changes) give the same state" + (bad ? " -- " + bad : ""));
}
console.log("    tick events: " + Object.keys(TEV).map((k) => k + "=" + TEV[k]).join(" "));
expect(Object.keys(TEV).every((k) => TEV[k] > 0), "tick: every event kind occurred");
expect(wcNew < wcOld, "tick: hz43VanWatchClip calls " + wcOld + " -> " + wcNew + " over " + tickFrames + " frames");
console.log("    tick: hz43VanWatchClip calls " + wcOld + " -> " + wcNew + " (" + (100 * (1 - wcNew / wcOld)).toFixed(1) + "% fewer), hz43StHide calls " + stOld);

// hz43VanWatchClip is idempotent on an unchanged state (the property the skipped checks rely on), for every clip of the
// model, every ring memo state and inside and outside an outline-memo pass.
{
	let bad = 0, n = 0;
	for (let seed = 1; seed <= 6; seed++) {
		const t = buildHud(seed);
		const h = makeTHost("new", t, 0);
		const all = paths(t).map((p) => nodeAt(t, p));
		for (const ringState of [null, "stale", "self", "annulus"]) {
			for (const d of all) {
				for (const inPass of [false, true]) {
					if (ringState === "stale") { const s = Clip("instance999"); h.hz43VanRing = s; }
					else if (ringState === "self") h.hz43VanRing = d;
					else if (ringState === "annulus") h.hz43VanRing = t.kids[0].getChildByName("instance546");
					else h.hz43VanRing = null;
					if (inPass) h.hz43OlBegin();
					const a = h.hz43VanWatchClip(d);
					const ring1 = h.hz43VanRing;
					const b = h.hz43VanWatchClip(d);
					const c = h.hz43VanWatchClip(d);
					if (inPass) h.hz43OlEnd();
					n++;
					if (a !== b || b !== c || h.hz43VanRing !== ring1) bad++;
				}
			}
		}
	}
	expect(bad === 0, "hz43VanWatchClip: the second and third call on the same state give the first answer and keep the ring memo (" + n + " cases)");
}

// Mutants of the tick change must be killed.
function tickKilled(src) {
	for (let seed = 1; seed <= 12; seed++) {
		const w = tickWorld(seed, src);
		rebuildBoth(w);
		for (let step = 0; step < 400; step++) {
			tickEvent(w, step);
			if (w.ho.hz36HideStale || step % 90 === 1) rebuildBoth(w);
			try { w.ho.hz36HideTick(); w.hn.hz36HideTick(); } catch (e) { return true; }
			if (w.r() < 0.3) {
				const p = paths(w.ta)[Math.floor(w.r() * paths(w.ta).length)];
				w.ho.hz43StHide(nodeAt(w.ta, p)); w.hn.hz43StHide(nodeAt(w.tb, p));
			}
			if (tSnap(w.ho) !== tSnap(w.hn)) return true;
		}
	}
	return false;
}
const TMUT = [
	["hz43StHideV without the note", "         if(!d) { return; }\n         this.hz43VanNoteAdd(d);\n         if(this.hzPerfOn) { this.hzPcWcSkip += 2; }", "         if(!d) { return; }\n         if(this.hzPerfOn) { this.hzPcWcSkip += 2; }"],
	["hz43StHideV without the visible write", "         if(this.hzWlOn && d.visible) { this.hzWlPre(d,2); }\n         if(d.visible) { d.visible = false; }", "         if(this.hzWlOn && d.visible) { this.hzWlPre(d,2); }"],
	["hz36HideTick without its own check", "if(this.hz43VanWatchClip(d)) { this.hz43StHideV(d); continue; }", "if(true) { this.hz43StHideV(d); continue; }"],
	["hz43StHide without its own check", "         if(!d || !this.hz43VanWatchClip(d)) { return; }\n         this.hz43VanNoteAdd(d);", "         if(!d) { return; }\n         this.hz43VanNoteAdd(d);"],
	["hz43VanNoteAdd without the duplicate check", "            if(this.hz43HidA[i] == d) { return; }\n", ""]
];
for (const m of TMUT) expect(tickKilled(mutant(m[1], m[2])), "tick mutant killed: " + m[0]);

// ---- source pins ----
function body(name) { return fnText(as, name).body; }
const onFrame = body("hzOnFrame");
expect(onFrame.indexOf("this.hz36HideFindAll(this,names,this.hzHideCache);") >= 0 && onFrame.indexOf("hz36HideFind(this,n,") < 0,
	"hzOnFrame: the rebuild calls hz36HideFindAll on the same root, list and cache (the per-name loop is gone)");
expect(/catch\(eHw:\*\)\s*\{\s*wn = null;\s*\}/.test(body("hz36HideFindAll")) && body("hz36HideFindAll").indexOf("try { this.hz36HideFind(c,n,out); } catch(e36f:Error) { }") >= 0,
	"hz36HideFindAll: any throw runs the original per-name loop with its own catch");
{
	// hz36Walk keeps hzFindByName's order, pruning and depth rule: the pruning condition is the same text
	const fb = body("hzFindByName"), wb = body("hz36Walk");
	const cond = (b) => { const m = b.match(/if\((ch is DisplayObjectContainer[^\n]*)\)\s*\n/); return m ? m[1] : null; };
	expect(cond(fb) !== null && cond(fb) === cond(wb), "hz36Walk: same descent condition as hzFindByName (Horizon cards pruned)");
	expect(fb.indexOf("if(depth > 8) { return null; }") >= 0 && wb.indexOf("if(depth > 8) { return left; }") >= 0, "hz36Walk: same depth limit as hzFindByName");
	expect(wb.indexOf("if(this.hzPerfOn) { this.hzPcFind++; }") < wb.indexOf("if(depth > 8)"), "hz36Walk: counts a node exactly where hzFindByName does");
}
for (const n of ["hz36HideFindAll", "hz36Walk", "hz43StHideV", "hz43VanNoteAdd", "hz36HideTick"]) {
	expect(!/removeChild|getTimer|frameN|% ?\d|\.alpha\s*=[^=]/.test(body(n)) || n === "hz36HideTick", n + ": no removeChild, timer, frame counter or alpha write");
}
expect(!/removeChild|getTimer|frameN|% ?\d/.test(body("hz36HideTick")), "hz36HideTick: no removeChild, timer or frame gating");
expect(body("hz36Walk").indexOf("new ") < 0 && body("hz36Walk").indexOf("[]") < 0, "hz36Walk: no allocation");
expect(body("hz43VanNote").replace(/\s/g, "") === "if(!d||!this.hz43VanWatchClip(d)){return;}this.hz43VanNoteAdd(d);", "hz43VanNote: the check, then the unchanged body (hz43VanNoteAdd)");
expect(as.indexOf(" | hw walk=") >= 0 && /this\.hzPcHrWalk = 0;\s*this\.hzPcHrFb = 0;\s*this\.hzPcWcSkip = 0;/.test(body("hzPbClear")), "parts line reports walk, fb, wcSkip; window clear resets them");
for (const n of ["hz36HideFindAll", "hz36Walk", "hz43StHide", "hz43StHideV"]) {
	const b = body(n);
	const lines = b.split("\n").filter((l) => /hzPc(HrWalk|HrFb|WcSkip|Find|StHide)/.test(l));
	expect(lines.every((l) => /if\(this\.hzPerfOn\) \{ this\.hzPc\w+( \+= 2|\+\+); \}/.test(l.trim())), n + ": counters only behind PerfDiag");
}

if (failed) { console.error(failed + " FAILED"); process.exit(1); }
console.log("hidewalk model tests passed");
