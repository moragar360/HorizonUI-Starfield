// 0.43.5 lean feeds: the HUD does not watch PlayerInventoryData on the normal path, and no ammo data is lost.
// - credits and weight are stored from PlayerData (hz26OnPlayer, run here);
// - ammo type and magazine size come from DataInventoryProvider.EquippedWeapon, the rollover's item data (strong only for
//   the equipped handle, CompareItemData standing in while the equipped feed is silent), and FavoritesData (ammo name only:
//   the game sends no magazine size there); a magazine size is never taken from a same-name copy;
// - anything still unknown starts the old inventory walk once per session, so the real magazine size is always recovered.
// Behavior cases run the production AS bodies in a small JS host; source pins strip // comments first.
// Run: node tests/feed_lean_test.js
// 0.43.6: first-watch priming (hzSubPrime / hzAmInvPeek) for the fallback, FavoritesData and DataInventoryProvider.
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const raw = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
// strip // comments (outside string literals) so commented-out code never counts as live
function stripComments(src) {
	return src.split("\n").map((line) => {
		let q = null;
		for (let i = 0; i < line.length; i++) {
			const ch = line[i];
			if (q) { if (ch === "\\") { i++; continue; } if (ch === q) q = null; continue; }
			if (ch === '"' || ch === "'") { q = ch; continue; }
			if (ch === "/" && line[i + 1] === "/") return line.slice(0, i);
		}
		return line;
	}).join("\n");
}
const as = stripComments(raw);

let failed = 0;
function expect(cond, msg) {
	if (cond) { console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) i = src.indexOf("public function " + name + "(");
	if (i < 0) return null;
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
		.replace(/([\w.]+) is Array\b/g, "Array.isArray($1)")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.*]+\s*\)/g, "catch($1)")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].split("=")[0].trim());
}
function bind(host, name) {
	const f = fnText(as, name);
	if (!f) throw new Error("missing function " + name);
	host[name] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(host);
}

// ---- source pins (comments stripped) ----
const lits = [...as.matchAll(/"PlayerInventoryData"/g)].length;
const invStart = fnText(as, "hzAmInvStart");
expect(lits === 1 && /HZ_AM_INV:String = "PlayerInventoryData"/.test(as) && /hzSubPrime\(\s*HZ_AM_INV\s*,\s*this\.hzOnInventory\s*,\s*"aItems"\s*\)/.test(invStart.body),
	"the only PlayerInventoryData literal in live code is HZ_AM_INV, used by the fallback in hzAmInvStart (" + lits + ")");
expect([...as.matchAll(/HZ_AM_INV\b/g)].length === 3, "HZ_AM_INV is used only by the fallback subscribe and its peek");
expect(!/function hz26OnInv\(/.test(as), "the dead hz26OnInv handler is gone");
expect(/hzSubPrime\(\s*"FavoritesData"\s*,\s*this\.hzAmOnFav\s*,\s*"aFavoriteItems"\s*\)/.test(as), "FavoritesData is watched (primed)");
expect(/hzSubPrime\(\s*"DataInventoryProvider"\s*,\s*this\.hzAmOnEq\s*,\s*"EquippedWeapon"\s*\)/.test(as), "DataInventoryProvider (equipped weapon) is watched (primed)");
const onWeap = fnText(as, "hzOnWeapon");
expect(/this\.hzAmResolve\(\)/.test(onWeap.body) && !/this\.hzResolveAmmoType\(\)/.test(onWeap.body), "WeaponData resolves through hzAmResolve");
expect(/if\(this\.hzDebug\) \{ this\.hzDbgWeap = this\.hzDump\(d\); \}/.test(onWeap.body), "weapon debug dump only with Debug");
expect(/if\(this\.hzDebug\) \{ this\.hzDbgWeap = "sIconLinkageName=" \+ icn/.test(onWeap.body) && !/^\s*this\.hzDbgWeap = "sIconLinkageName="/m.test(onWeap.body), "weapon icon debug prefix only with Debug");
expect(/if\(this\.hzDebug\) \{ this\.hzDbgCross = this\.hzDump\(e\.data\); \}/.test(as), "crosshair debug dump only with Debug");
expect([...as.matchAll(/this\.hzDump\(/g)].length === 4, "no new hzDump call sites");
expect(/o\.szAp = sz;/.test(fnText(as, "hzApplyFmt19").body), "hzApplyFmt19 records the applied pixel size (live code)");
const tw = fnText(as, "hzTW");
expect(/o\.twSz === o\.szAp/.test(tw.body) && /o\.twSz = o\.szAp;/.test(tw.body), "hzTW cache key includes the applied pixel size (PR #12)");
expect(/if\(pk != this\.hz26PowFk \|\| col != this\.hz26PowFc\)/.test(fnText(as, "hz26PowIcon").body), "power icon glow assigned only on a look change");
const freq = fnText(as, "hzOnPlayerFrequent").body.split("\n").filter((l) => /hzAmT0/.test(l));
expect(freq.length === 1, "PlayerFrequentData carries the pending check");
expect(/this\.hzAmHover\(this\.hzTgAct\)/.test(fnText(as, "hzOnTgAct").body), "every rollover activation update offers its item data to hzAmHover (live code)");
const DBG = fnText(as, "hz26DbgText");
expect(!/PlayerInventoryData/.test(DBG.body), "the debug key list no longer names PlayerInventoryData");

// ---- behavior host ----
function host() {
	const h = {
		hzAmFav: null, hzAmEq: null, hzAmEqH: NaN, hzAmKnown: {}, hzAmInvOn: false, hzAmT0: NaN,
		HZ_AM_WAIT: 3000, HZ_AM_NOMAG: 4294967295,
		hzWeapName: "", hzAmmoDrawn: true, hzMagCap: 0, hzInvItems: null, hzInvWeapName: "",
		hzAmmoType: { _t: "--", writes: 0, get text() { return this._t; }, set text(v) { this._t = v; this.writes++; } },
		subs: [], nowMs: 1000, eqSync: 0, hzDebug: false, hz26Dbg: {},
		hzDump(o) { return JSON.stringify(o); },
		BSUIDataManager: null,
		hzEqSync() { this.eqSync++; },
		hzDrawMag() {},
		hz26Now() { return this.nowMs; },
	};
	// a model of the game's BSUIDataManager (Bethesda/Shared/AS3/Data/BSUIDataManager.as): Subscribe calls the listener at
	// once only for a provider that existed and was ready before; a first watch after the link is attached fills the
	// payload but its CHANGE goes out before the listener is added. h.prov[name] = { dataReady, data, existed }.
	h.prov = {};
	h.calls = [];
	h.BSUIDataManager = {
		Subscribe: (n, f) => { h.subs.push(n); let p = h.prov[n]; const existed = p && p.existed; if (!p) p = h.prov[n] = { dataReady: false, data: {} }; p.existed = true; if (existed && p.dataReady) f({ data: p.data }); },
		GetDataFromClient: (n, create) => { const p = h.prov[n]; return p && p.existed ? p : null; },
	};
	h.FromClientDataEvent = function (p) { this.data = p.data; };
	h.HZ_AM_INV = "PlayerInventoryData";
	for (const n of ["hzSubPrime", "hzAmInvPeek", "hzAmCap", "hzAmOnEq", "hzAmOnFav", "hzAmHover", "hzAmItem", "hzAmLearn", "hzAmFind", "hzAmResolve", "hzAmInvStart",
		"hzFindNum", "hzFindAmmo", "hzResolveAmmoType", "hzOnInventory", "hzSetAmmoType", "hz26Log"]) bind(h, n);
	h.pending = Function("with(this){\n" + toJs(freq[0]) + "\n}").bind(h);   // the production line from hzOnPlayerFrequent
	h.weapon = (name, drawn) => { if (h.hzWeapName !== name) h.hzMagCap = 0; h.hzWeapName = name; h.hzAmmoDrawn = drawn !== false; h.hzAmResolve(); };
	return h;
}
const typ = (h) => h.hzAmmoType.text;
const inv = (items) => ({ data: { aItems: items } });
const fav = (items) => ({ data: { aFavoriteItems: items } });

{	// M-1: a favorited gun, never hovered, no equipped feed: the game's favorites entry has no uAmmoCapacity
	const h = host();
	h.hzAmOnFav(fav([{ sName: "Grendel", bIsEquippable: true, sAmmoName: "6.5mm CT", uAmmoCount: 120, uCount: 1 }]));
	h.weapon("Grendel");
	expect(typ(h) === "6.5MM CT" && h.subs.length === 0 && h.hzMagCap === 0, "favorites give the ammo type at once; the size is still unknown");
	h.nowMs += 2999; h.pending();
	expect(h.subs.length === 0, "inside 3 s the PlayerFrequentData check keeps waiting");
	h.nowMs += 1; h.pending();
	expect(h.subs.join() === "PlayerInventoryData" && h.hzAmInvOn, "after 3 s the PlayerFrequentData check starts the inventory read");
	h.hzOnInventory(inv([{ sName: "Grendel", bIsEquipped: true, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 30 } }, { sName: "Spacesuit", bIsEquipped: true }]));
	expect(h.hzMagCap === 30 && typ(h) === "6.5MM CT", "magazine size recovered without a hover (30 from the inventory read)");
	h.pending(); h.weapon("Grendel");
	expect(h.subs.length === 1, "the inventory read subscribes once for the session");
}
{	// equipped feed with the real size: nothing else needed
	const h = host();
	h.hzAmOnEq({ data: { EquippedWeapon: { sName: "Coachman", uFormID: 77, uHandleID: 5, WeaponInfo: { sAmmoType: "12G Shotgun Shell", uAmmoCapacity: 2 } } } });
	h.weapon("Coachman");
	expect(typ(h) === "12G SHOTGUN SHELL" && h.hzMagCap === 2 && h.subs.length === 0 && isNaN(h.hzAmT0), "the equipped feed gives type and size, no inventory watch");
}
{	// equipped feed spoke for this gun but has no size: fall back at once
	const h = host();
	h.hzAmOnEq({ data: { EquippedWeapon: { sName: "Kodama", uFormID: 9, uHandleID: 3, WeaponInfo: { sAmmoType: "7.77mm Caseless", uAmmoCapacity: 4294967295 } } } });
	h.weapon("Kodama");
	expect(h.subs.length === 1, "equipped feed without a usable size (no-magazine value filtered): inventory read starts at once");
}
{	// weapon swap: WeaponData first, the equipped feed a moment later -> no early fallback
	const h = host();
	h.hzAmOnEq({ data: { EquippedWeapon: { sName: "Coachman", uFormID: 77, uHandleID: 5, WeaponInfo: { sAmmoType: "12G Shotgun Shell", uAmmoCapacity: 2 } } } });
	h.weapon("Coachman");
	h.weapon("Breach");
	expect(h.subs.length === 0 && !isNaN(h.hzAmT0), "a swap waits for the equipped feed instead of starting the fallback");
	h.hzAmOnEq({ data: { EquippedWeapon: { sName: "Breach", uFormID: 78, uHandleID: 6, WeaponInfo: { sAmmoType: "12G Shotgun Shell", uAmmoCapacity: 4 } } } });
	expect(h.hzMagCap === 4 && h.subs.length === 0 && isNaN(h.hzAmT0), "the equipped feed for the new gun settles it");
}
{	// S-3: no-magazine value on the favorites path
	const h = host();
	h.hzAmOnFav(fav([{ sName: "Tanto", bIsEquippable: true, sAmmoName: "X", uAmmoCapacity: 4294967295 }]));
	expect(h.hzAmKnown["Tanto"].c === undefined && h.hzAmKnown["Tanto"].t === "X", "favorites give a name only; no size is kept by name (so 4294967295 can't get in)");
	expect(h.hzAmCap(4294967295) === 0 && h.hzAmCap(-1) === 0 && h.hzAmCap(undefined) === 0 && h.hzAmCap(30) === 30, "hzAmCap: invalid, missing and no-magazine are 0");
}
{	// hover learning before the wait ends, equipped handle known
	const h = host();
	h.hzAmOnEq({ data: { EquippedWeapon: { sName: "Old Earth Hunting Rifle", uFormID: 1, uHandleID: 42 } } });   // no WeaponInfo
	h.hzAmOnFav(fav([{ sName: "Old Earth Hunting Rifle", bIsEquippable: true, sAmmoName: ".27-30" }]));
	h.weapon("Old Earth Hunting Rifle");
	expect(h.subs.length === 1, "(control) equipped feed for this gun without WeaponInfo: fallback");
	const g = host();
	g.hzAmOnFav(fav([{ sName: "Old Earth Hunting Rifle", bIsEquippable: true, sAmmoName: ".27-30" }]));
	g.weapon("Old Earth Hunting Rifle");
	g.hzAmHover({ CompareItemData: { sName: "Old Earth Hunting Rifle", uHandleID: 42, WeaponInfo: { sAmmoType: ".27-30", uAmmoCapacity: 4 } } });
	expect(g.hzMagCap === 4 && g.subs.length === 0 && isNaN(g.hzAmT0) && g.hzAmEq.s === "cmp", "equipped feed silent: CompareItemData (the equipped item) fills the size, so no fallback starts");
}
{	// S-2: a same-name copy hovered must not overwrite the equipped gun's known size or type
	const h = host();
	h.hzAmOnEq({ data: { EquippedWeapon: { sName: "Grendel", uFormID: 7, uHandleID: 100, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 45 } } } });
	h.weapon("Grendel");
	h.hzAmHover({ ItemData: { sName: "Grendel", uHandleID: 200, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 30 } } });
	h.weapon("Grendel");
	expect(h.hzMagCap === 45, "a hovered copy with another handle does not overwrite the equipped size (45 kept)");
	h.hzAmHover({ ItemData: { sName: "Grendel", uHandleID: 100, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 60 } } });
	h.weapon("Grendel");
	expect(h.hzMagCap === 60, "the equipped handle itself is authoritative (60 after a magazine mod)");
	h.hzAmHover({ CompareItemData: { sName: "Grendel", WeaponInfo: { sAmmoType: "Other", uAmmoCapacity: 12 } } });
	h.hzAmHover({ CompareItemData: { sName: "Grendel", uHandleID: 300, WeaponInfo: { sAmmoType: "Other", uAmmoCapacity: 12 } } });
	h.weapon("Grendel");
	expect(h.hzMagCap === 60 && typ(h) === "6.5MM CT" && h.hzAmEq.s === "eq", "while the equipped feed speaks, compare data without its handle never overrides it");
	const b = host();   // no name-keyed entry, so only the equipped data can supply the type
	b.hzAmOnEq({ data: { EquippedWeapon: { sName: "Breach", uFormID: 8, uHandleID: 11, WeaponInfo: { sAmmoType: "12G", uAmmoCapacity: 4 } } } });
	b.weapon("Breach");
	b.hzAmHover({ ItemData: { sName: "Breach", uHandleID: 11, WeaponInfo: { sAmmoType: "", uAmmoCapacity: 4294967295 } } });
	b.weapon("Breach");
	expect(b.hzAmEq.t === "12G" && b.hzAmEq.c === 4 && typ(b) === "12G" && b.hzMagCap === 4 && b.subs.length === 0,
		"an equipped-handle hover with no size and no name never blanks the known size or type (and starts no fallback)");
	const k = host();
	k.hzAmLearn("Rattler", "Heavy Fuel");
	k.hzAmLearn("Rattler", "Other");
	k.hzAmLearn("Rattler", "");
	expect(k.hzAmKnown["Rattler"].t === "Heavy Fuel", "name-keyed sources never overwrite (or blank) a known ammo name");
	k.hzAmLearn("Tanto", ""); k.hzAmLearn("Tanto", "Fuel");
	expect(k.hzAmKnown["Tanto"].t === "Fuel", "a name-keyed source may fill an empty ammo name");
	const f = host();
	f.hzAmOnFav(fav([{ sName: "Grendel", bIsEquippable: true, sAmmoName: "Pulse" }]));
	f.weapon("Grendel");
	f.hzAmHover({ ItemData: { sName: "Grendel", WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 30 } } });
	f.weapon("Grendel");
	expect(typ(f) === "PULSE", "favorites and name-keyed hover only fill a missing name; the first known name stays");
}
{	// SF-2: equipped feed silent, a same-name copy with another magazine is hovered (ItemData): its size is not used
	const h = host();
	h.hzAmOnFav(fav([{ sName: "Grendel", bIsEquippable: true, sAmmoName: "6.5mm CT" }]));
	h.weapon("Grendel");
	h.hzAmHover({ ItemData: { sName: "Grendel", uHandleID: 200, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 30 } } });
	h.weapon("Grendel");
	expect(h.hzMagCap === 0 && !isNaN(h.hzAmT0) && h.subs.length === 0, "a same-name copy's size is never taken as the equipped size; still waiting");
	h.nowMs += 3000; h.pending();
	h.hzOnInventory(inv([{ sName: "Grendel", bIsEquipped: false, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 30 } },
		{ sName: "Grendel", bIsEquipped: true, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 45 } }]));
	expect(h.subs.length === 1 && h.hzMagCap === 45, "so the fallback still runs and gives the equipped gun's real size (45, as in 0.43.4)");
	const g = host();
	g.hzAmOnEq({ data: { EquippedWeapon: { sName: "Grendel", uFormID: 7, uHandleID: 100, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 45 } } } });
	g.hzAmOnEq({ data: { EquippedWeapon: { sName: "", uFormID: 0, uHandleID: 0 } } });
	expect(g.hzAmEq === null && isNaN(g.hzAmEqH), "an empty equipped entry clears the equipped data");
	g.hzAmOnEq({ data: { EquippedWeapon: { sName: "Grendel", uFormID: 7, uHandleID: 4294967295, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 45 } } } });
	expect(g.hzAmEq === null && isNaN(g.hzAmEqH), "an equipped entry with the no-handle value is ignored");
}
{	// SF-1: the fallback inventory walk filters the no-magazine value
	const h = host();
	h.weapon("Solstice");
	h.hzAmInvStart();
	h.hzOnInventory(inv([{ sName: "Solstice", bIsEquipped: true, WeaponInfo: { sAmmoType: "Lightning", uAmmoCapacity: 4294967295 } }]));
	expect(h.hzMagCap === 0 && typ(h) === "LIGHTNING", "fallback path: 4294967295 is not stored as a magazine size");
	h.hzOnInventory(inv([{ sName: "Solstice", bIsEquipped: true, WeaponInfo: { sAmmoType: "Lightning", uAmmoCapacity: 20 } }]));
	expect(h.hzMagCap === 20, "fallback path: a real size still comes through");
}
{	// Debug=1 line for the equipped feed
	const h = host();
	const ev = { data: { EquippedWeapon: { sName: "Coachman", uFormID: 77, uHandleID: 5, WeaponInfo: { sAmmoType: "12G", uAmmoCapacity: 2 } } } };
	h.hzAmOnEq(ev);
	expect(h.hz26Dbg.DataInventoryProvider === undefined, "Debug=0: the equipped feed builds no debug text");
	h.hzDebug = true; h.hzAmOnEq(ev);
	expect(/Coachman/.test(h.hz26Dbg.DataInventoryProvider) && /"s":"eq"/.test(h.hz26Dbg.DataInventoryProvider), "Debug=1: each equipped-feed dispatch is shown");
	expect(/"DataInventoryProvider"/.test(DBG.body), "the debug key list shows DataInventoryProvider");
}
{	// N-6: prefix ambiguity
	const h = host();
	h.hzAmLearn("X Extended", "A");
	h.hzAmLearn("X (Calibrated)", "B");
	expect(h.hzAmFind("X").t === "B", "\"X\" picks \"X (Calibrated)\" over \"X Extended\" regardless of insert order");
	const g = host();
	g.hzAmLearn("X (Calibrated)", "B");
	g.hzAmLearn("X Extended", "A");
	expect(g.hzAmFind("X").t === "B", "same pick with the other insert order");
}
{	// N-3 and melee
	const h = host();
	h.weapon("Kodama", false);
	h.nowMs += 3000; h.pending();
	expect(h.subs.length === 1, "an unknown holstered gun still gets the fallback after 3 s");
	const m = host();
	m.hzAmOnFav(fav([{ sName: "Tanto", bIsEquippable: true }]));
	m.weapon("Tanto", false);
	m.nowMs += 5000; m.pending();
	expect(m.subs.length === 0 && typ(m) === "--", "a favorited melee weapon (no ammo name) is known: no fallback, type --");
}
{	// 0.43.6 fresh game (a new-game start that hands the player a gun): no favorites, never hovered, the equipped feed
	// silent. The fallback's first watch is made at run time, so the game's Subscribe never delivers the current inventory;
	// before 0.43.6 the ammo name stayed "--" until the first shot changed the inventory. hzSubPrime hands it over at once.
	const h = host();
	h.prov.PlayerInventoryData = { dataReady: true, data: { aItems: [{ sName: "Grendel", bIsEquipped: true, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 30 } }] } };
	h.weapon("Grendel");
	expect(typ(h) === "--" && h.subs.length === 0, "fresh game: nothing known, waiting");
	h.nowMs += 3000; h.pending();
	expect(h.subs.join() === "PlayerInventoryData" && typ(h) === "6.5MM CT" && h.hzMagCap === 30 && isNaN(h.hzAmT0),
		"fresh game: the fallback shows the ammo name and magazine size at once, no shot needed");
	h.pending(); h.weapon("Grendel");
	expect(h.subs.length === 1, "still one inventory subscribe for the session");
}
{	// payload filled only after the subscribe: found on the next PlayerFrequentData check, still no shot needed
	const h = host();
	h.weapon("Grendel");
	h.nowMs += 3000; h.pending();
	expect(h.subs.length === 1 && typ(h) === "--" && !isNaN(h.hzAmT0), "empty payload at the subscribe: the check stays armed");
	h.prov.PlayerInventoryData.dataReady = true;
	h.prov.PlayerInventoryData.data = { aItems: [{ sName: "Grendel", bIsEquipped: true, WeaponInfo: { sAmmoType: "6.5mm CT", uAmmoCapacity: 30 } }] };
	h.nowMs += 100; h.pending();
	expect(typ(h) === "6.5MM CT" && h.hzMagCap === 30 && isNaN(h.hzAmT0), "the next PlayerFrequentData check reads the filled payload and disarms");
}
{	// the equipped feed primed at build time when the movie already holds it: no fallback at all
	const h = host();
	h.prov.DataInventoryProvider = { dataReady: true, data: { EquippedWeapon: { sName: "Coachman", uFormID: 77, uHandleID: 5, WeaponInfo: { sAmmoType: "12G Shotgun Shell", uAmmoCapacity: 2 } } } };
	h.hzSubPrime("DataInventoryProvider", h.hzAmOnEq, "EquippedWeapon");
	h.weapon("Coachman");
	expect(typ(h) === "12G SHOTGUN SHELL" && h.hzMagCap === 2 && h.subs.join() === "DataInventoryProvider", "primed equipped feed gives type and size; no inventory watch");
}
{	// a provider that existed and was ready: Subscribe delivers it itself, hzSubPrime does not call a second time
	const h = host();
	let n = 0;
	h.prov.FavoritesData = { existed: true, dataReady: true, data: { aFavoriteItems: [] } };
	h.hzSubPrime("FavoritesData", () => { n++; }, "aFavoriteItems");
	expect(n === 1, "one call for an already-watched provider");
	let m = 0;
	h.prov.QuestData = { dataReady: false, data: {} };
	h.hzSubPrime("QuestData", () => { m++; }, "aQuests");
	expect(m === 0, "a provider that is not ready yet is left to the link's first dispatch");
}
{	// change-only ammo-type text
	const h = host();
	h.hzSetAmmoType("6.5mm CT"); h.hzSetAmmoType("6.5mm CT"); h.hzSetAmmoType("6.5mm CT");
	expect(h.hzAmmoType.writes === 1, "ammo-type text written once for three identical updates");
	h.hzSetAmmoType(""); expect(h.hzAmmoType.writes === 2 && typ(h) === "--", "a real change is written");
}
{	// credits and weight stored from PlayerData
	const h = {
		hz26Name: "", hz26Lv: -1, hz26Xp: NaN, hz26XpN: NaN, hz26XpSeen: true, hz26Sp: -1, hz26Enc: NaN, hz26EncMax: NaN, hz26Cr: NaN, hz26CharOk: false,
		crArg: null, changed: 0,
		int(v) { return Number(v) | 0; },
		hz26Log() {}, hz26XpAdd() {}, hz27CharData(lv, sp, cr) { this.crArg = cr; }, hz26CharChanged() { this.changed++; },
	};
	bind(h, "hz26OnPlayer");
	h.hz26OnPlayer({ data: { sName: "Player", uLevel: 12, fLevelXP: 5, fNextLevelXP: 10, uSkillPoints: 1, uCredits: 76320, fEncumbrance: 77, fMaxEncumbrance: 169 } });
	expect(h.hz26Cr === 76320 && h.crArg === 76320, "credits stored from PlayerData.uCredits and passed on");
	expect(h.hz26Enc === 77 && h.hz26EncMax === 169 && h.changed === 1, "weight stored from PlayerData");
	h.hz26OnPlayer({ data: { uLevel: 12 } });
	expect(h.hz26Cr === 76320 && isNaN(h.crArg), "an update without uCredits keeps the stored credits");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("all ok");
