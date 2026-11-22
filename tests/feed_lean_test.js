// 0.43.5 lean feeds: proves the HUD no longer watches PlayerInventoryData on the normal path. Credits and weight come
// from PlayerData, ammo type and magazine size from FavoritesData and the rollover's item data, and the old inventory
// walk is kept as a once-per-session fallback so no gun loses its ammo type. Also pins the edge-only debug strings,
// the PR #12 width-cache key (applied pixel size) and the change-only power-icon glow.
// The production AS bodies are bound into a small JS host (same harness pattern as slim_shed_test.js).
// Run: node tests/feed_lean_test.js
// Author: Moragar. Last modified: 2026-11-22.
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

// ---- source pins ----
const subs = [...as.matchAll(/Subscribe\("PlayerInventoryData",this\.(\w+)\)/g)].map((m) => m[1]);
expect(subs.length === 1 && subs[0] === "hzOnInventory", "PlayerInventoryData is subscribed at exactly one site (" + subs.join(",") + ")");
const invStart = fnText(as, "hzAmInvStart");
expect(invStart && /Subscribe\("PlayerInventoryData",this\.hzOnInventory\)/.test(invStart.body), "that one site is the fallback hzAmInvStart");
expect(/Subscribe\("FavoritesData",this\.hzAmOnFav\)/.test(as), "FavoritesData feeds the ammo type");
const onPlayer = fnText(as, "hz26OnPlayer");
expect(onPlayer && /d\.uCredits/.test(onPlayer.body) && /hz27CharData\(this\.hz26Lv,this\.hz26Sp,cr0\)/.test(onPlayer.body), "credits come from PlayerData.uCredits");
expect(onPlayer && /d\.fEncumbrance/.test(onPlayer.body) && /d\.fMaxEncumbrance/.test(onPlayer.body), "weight comes from PlayerData");
const onWeap = fnText(as, "hzOnWeapon");
expect(onWeap && /this\.hzAmResolve\(\)/.test(onWeap.body) && !/this\.hzResolveAmmoType\(\)/.test(onWeap.body), "WeaponData resolves through hzAmResolve");
expect(onWeap && /if\(this\.hzDebug\) \{ this\.hzDbgWeap = this\.hzDump\(d\); \}/.test(onWeap.body), "weapon debug dump only with Debug");
expect(/if\(this\.hzDebug\) \{ this\.hzDbgCross = this\.hzDump\(e\.data\); \}/.test(as), "crosshair debug dump only with Debug");
const dumps = [...as.matchAll(/this\.hzDump\(/g)].length;
expect(dumps === 4, "no new hzDump call sites (" + dumps + ")");
const fmt = fnText(as, "hzApplyFmt19");
expect(fmt && /o\.szAp = sz;/.test(fmt.body), "hzApplyFmt19 records the applied pixel size");
const tw = fnText(as, "hzTW");
expect(tw && /o\.twSz === o\.szAp/.test(tw.body) && /o\.twSz = o\.szAp;/.test(tw.body), "hzTW cache key includes the applied pixel size (PR #12)");
const pow = fnText(as, "hz26PowIcon");
expect(pow && /if\(pk != this\.hz26PowFk \|\| col != this\.hz26PowFc\)/.test(pow.body), "power icon glow assigned only on a look change");

// ---- behavior ----
function host() {
	const h = {
		hzAmFav: null, hzAmFavSeen: false, hzAmKnown: {}, hzAmInvOn: false, hzAmT0: NaN, HZ_AM_WAIT: 3000,
		hzWeapName: "", hzAmmoDrawn: true, hzMagCap: 0, hzInvItems: null, hzInvWeapName: "",
		typ: null, subs: [], nowMs: 1000, resolvedOld: 0,
		BSUIDataManager: null,
		hzSetAmmoType(n) { this.typ = n; },
		hzResolveAmmoType() { this.resolvedOld++; },
		hzDrawMag() {},
		hz26Now() { return this.nowMs; },
		hzOnInventory() {},
	};
	h.BSUIDataManager = { Subscribe: (n, f) => { h.subs.push(n); } };
	for (const n of ["hzAmOnFav", "hzAmHover", "hzAmItem", "hzAmLearn", "hzAmFind", "hzAmResolve", "hzAmInvStart", "hzFindNum"]) bind(h, n);
	return h;
}
{
	const h = host();
	h.hzWeapName = "Grendel";
	h.hzAmResolve();
	expect(h.typ === "" && h.subs.length === 0 && !isNaN(h.hzAmT0), "unknown gun before favorites: shows -- and waits");
	h.hzAmOnFav({ data: { aFavoriteItems: [{ sName: "Grendel", bIsEquippable: true, sAmmoName: "6.5mm CT", uAmmoCount: 120 }, { sName: "Med Pack", bIsEquippable: false }] } });
	expect(h.typ === "6.5mm CT" && h.subs.length === 0 && isNaN(h.hzAmT0), "favorited gun: ammo type from FavoritesData, no inventory watch");
}
{
	const h = host();
	h.hzAmOnFav({ data: { aFavoriteItems: [] } });
	h.hzWeapName = "Coachman";
	h.hzAmHover({ CompareItemData: { sName: "Coachman", WeaponInfo: { sAmmoType: "12G Shotgun Shell", uAmmoCapacity: 2 } } });
	h.hzAmResolve();
	expect(h.typ === "12G Shotgun Shell" && h.hzMagCap === 2 && h.subs.length === 0, "hovered weapon data teaches ammo type and magazine size");
}
{
	const h = host();
	h.hzAmHover({ ItemData: { sName: "Old Earth Hunting Rifle", WeaponInfo: { sAmmoType: ".27-30", uAmmoCapacity: 4294967295 } } });
	h.hzWeapName = "Old Earth Hunting Rifle";
	h.hzAmResolve();
	expect(h.typ === ".27-30" && h.hzMagCap === 0, "no-magazine sentinel (uint max) is not a magazine size");
}
{
	const h = host();
	h.hzAmOnFav({ data: { aFavoriteItems: [] } });
	h.hzWeapName = "Kodama";
	h.hzAmResolve();
	expect(h.hzAmInvOn && h.subs.join() === "PlayerInventoryData", "gun nobody knows after favorites arrived: old inventory path starts");
	h.hzAmResolve(); h.hzAmInvStart();
	expect(h.subs.length === 1 && h.resolvedOld === 1, "fallback subscribes once and then owns the resolve");
}
{
	const h = host();
	h.hzWeapName = "Kodama";
	h.hzAmResolve();
	h.nowMs += 2999; h.hzAmResolve();
	expect(h.subs.length === 0, "no favorites yet: still waiting inside 3 s");
	h.nowMs += 1; h.hzAmResolve();
	expect(h.subs.length === 1, "no favorites after 3 s: fallback starts");
}
{
	const h = host();
	h.hzWeapName = "Tanto"; h.hzAmmoDrawn = false; h.typ = "X";
	h.hzAmResolve();
	expect(h.typ === "" && h.subs.length === 0 && isNaN(h.hzAmT0), "melee / no ammo display: -- and no inventory watch");
}
{
	const h = host();
	h.hzAmOnFav({ data: { aFavoriteItems: [{ sName: "Breach (Calibrated)", bIsEquippable: true, sAmmoName: "12G Shotgun Shell" }] } });
	h.hzWeapName = "Breach";
	h.hzAmResolve();
	expect(h.typ === "12G Shotgun Shell", "same name-prefix rule as the inventory walk");
	expect(h.hzAmLearn("Breach (Calibrated)", "12G Shotgun Shell", 0) === false, "relearning the same entry is not a change");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("all ok");
