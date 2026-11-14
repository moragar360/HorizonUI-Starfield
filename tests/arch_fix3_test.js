// arch-fixes Fix 3 tests: the Equipment card rules "Weapon drawn only" and "Combat only".
// Run: node tests/arch_fix3_test.js   (HZ_AS=<file> runs it against another horizon_block.as, used by the mutants)
// Proves, by running the production AS functions (types stripped) on a small host:
//  1. combat: HUDStealthData.bIsInCombat (already subscribed) and PlayerData.bIsInCombat each count on their own edge;
//     the latest edge wins, a provider repeating its old value never undoes the other's newer edge; refresh on change only;
//  2. weapon out: hzSetWeaponDrawn decides when called; otherwise only a weapon reticle (with ammo counter and crosshair
//     on) counts; unknown / unarmed / tool / none do not; interact / command keep the last decision; the old
//     "uType != 2" fallback (true before any crosshair update) is gone;
//  3. static: no timer, listener or frame work added; the stealth handler stays exception-safe.
// Author: Moragar. Last modified: 2026-11-13.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const asPath = process.env.HZ_AS || path.join(root, "actionscript", "horizon_block.as");
const as = fs.readFileSync(asPath, "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(");
	const m = re.exec(src);
	if (!m) throw new Error("missing function " + name);
	const brace = src.indexOf("{", m.index);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(m.index, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function codeOnly(body) { return body.replace(/\/\/[^\n]*/g, ""); }
function toJs(body) {
	return body
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*(?:Error|\*)\s*\)\s*\{/g, "catch($1) {")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].trim().split("=")[0].trim());
}
const G = { HZ_HCT_INTERACT: 7, HZ_HCT_COMMAND: 8, Number: Number, Boolean: Boolean };
function bind(h, names) {
	const wrap = new Proxy(h, { get(t, k) { if (k in t) return t[k]; if (k in G) return G[k]; return undefined; }, has(t, k) { return typeof k === "string" && (k in t || k in G); } });
	for (const n of names) {
		const f = fnText(as, n);
		h[n] = Function.apply(null, argNames(f.sig).concat(["with(this){\n" + toJs(f.body) + "\n}"])).bind(wrap);
	}
	return h;
}
function host() {
	const h = { hzInCombat: false, hzCombatPd: false, hzCombatSt: false, hzT19Sig: "x", refresh: 0, hz26St: null,
		hzPlugActive: false, hzPlugDrawn: false, hzAmmoDrawn: false, hzCrossOn: true, hzCrossType: -1, hzWpnRet: false, hzT19Ver: 0,
		hzCrossIron: false, hzCross3rd: false, hzCrossTool: false, hzDbgCross: "", hzDump: () => "", hzDbgShow: () => {}, hz26Log: () => {} };
	h.hzRefreshVisibility = () => { h.refresh++; };
	return bind(h, ["hzOnPlayerData", "hzOnStealthCombat", "hz26OnStealth", "hz36SetCombat", "hzWeaponOut", "hzWpnReticle", "hzOnCrosshair", "hzSetWeaponDrawn", "hzRuleOk"]);
}
const ev = (d) => ({ data: d });

// ---- 1. combat ----
{
	const h = host();
	h.hz26OnStealth(ev({ bIsInCombat: true, fPercent: 0 }));
	expect(h.hzInCombat === true && h.refresh === 1 && h.hzRuleOk(1) === true, "HUDStealthData combat edge turns combat on (rule 1) with one refresh");
	h.hzOnPlayerData(ev({ bIsInCombat: false }));
	expect(h.hzInCombat === true && h.refresh === 1, "PlayerData repeating its old 'not in combat' does not undo the stealth edge");
	for (let i = 0; i < 20; i++) h.hz26OnStealth(ev({ bIsInCombat: true }));
	expect(h.refresh === 1, "repeated stealth updates with the same flag do nothing");
	h.hz26OnStealth(ev({ bIsInCombat: false }));
	expect(h.hzInCombat === false && h.refresh === 2, "the stealth provider's own 'combat over' edge ends it");
	h.hzOnPlayerData(ev({ bIsInCombat: true }));
	expect(h.hzInCombat === true && h.refresh === 3, "a PlayerData edge alone still turns combat on (the old provider keeps working)");
	h.hz26OnStealth(ev({ bIsInCombat: true }));
	const r0 = h.refresh;
	h.hz26OnStealth(ev({ fPercent: 10 }));
	expect(h.hzInCombat === true && h.refresh === r0 && h.hzCombatSt === true, "a stealth update without the flag changes nothing");
	h.hzOnPlayerData(ev({ bIsInCombat: false }));
	expect(h.hzInCombat === false && h.refresh === r0 + 1, "the latest edge wins");
	h.hz26OnStealth(ev({ bIsInCombat: true }));
	expect(h.hzInCombat === false && h.refresh === r0 + 1, "the stealth provider repeating its old 'in combat' does not undo the newer PlayerData edge");
	let threw = false;
	try { h.hz26OnStealth(ev(null)); } catch (e) { threw = true; }
	expect(!threw, "a null stealth payload is safe");
	expect(h.hz26St === null, "the stealth handler still stores its payload for the stealth card");
}

// ---- 2. weapon out ----
{
	const h = host();
	h.hzAmmoDrawn = true;
	expect(h.hzWeaponOut() === false, "before any crosshair update a gun does not count as out (the old fallback said yes: -1 != 2)");
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 4 }));
	expect(h.hzWeaponOut() === true && h.hzRuleOk(3) === true, "rifle reticle, crosshair on, ammo counter on: out");
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 7 }));
	expect(h.hzWeaponOut() === true, "looking at a door / item (interact) keeps the last decision: still out");
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 8 }));
	expect(h.hzWeaponOut() === true, "command reticle keeps the last decision");
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 2 }));
	expect(h.hzWeaponOut() === false, "unarmed reticle: not out");
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 7 }));
	expect(h.hzWeaponOut() === false, "interact after unarmed keeps 'not out'");
	for (const t of [6, 9, -1, NaN]) { h.hzOnCrosshair(ev({ bEnabled: true, uType: 3 })); h.hzOnCrosshair(ev({ bEnabled: true, uType: t })); if (h.hzWeaponOut()) expect(false, "type " + t + " must not count"); }
	expect(true, "tool, none and unknown reticle types do not count");
	for (const t of [0, 1, 3, 4, 5]) { h.hzOnCrosshair(ev({ bEnabled: true, uType: 2 })); h.hzOnCrosshair(ev({ bEnabled: true, uType: t })); if (!h.hzWeaponOut()) expect(false, "type " + t + " must count"); }
	expect(true, "pistol, cutter, shotgun, rifle and laser reticles count");
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 4 }));
	expect(h.hzWeaponOut() === false, "crosshair off (scanner, menus): not out");
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 4 }));
	h.hzAmmoDrawn = false;
	expect(h.hzWeaponOut() === false, "no ammo counter (WeaponData.bDisplayAmmo off): not out");
	h.hzSetWeaponDrawn(false);
	h.hzAmmoDrawn = true;
	expect(h.hzWeaponOut() === false, "hzSetWeaponDrawn(false) decides over the reticle");
	h.hzSetWeaponDrawn(true);
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 2 }));
	expect(h.hzWeaponOut() === true, "hzSetWeaponDrawn(true) decides over the reticle");
}

// ---- 3. static ----
{
	const wo = codeOnly(fnText(as, "hzWeaponOut").body);
	expect(wo.indexOf("hzCrossType != 2") < 0 && wo.indexOf("this.hzPlugActive ? this.hzPlugDrawn") >= 0, "the 'uType != 2' fallback is gone; the plugin feed still decides first");
	const oc = codeOnly(fnText(as, "hzOnCrosshair").body);
	expect((oc.match(/hzWpnReticle\(/g) || []).length === 1, "the reticle decision is made once per crosshair update (event, not frame)");
	const st = codeOnly(fnText(as, "hz26OnStealth").body);
	expect(/try \{ this\.hzOnStealthCombat\(e\.data\); \} catch\(errC:Error\) \{ \}/.test(st), "the stealth handler forwards the combat flag inside its own try");
	let clean = true;
	for (const n of ["hzOnStealthCombat", "hzWpnReticle", "hzOnPlayerData", "hzWeaponOut"]) {
		if (/addEventListener|Timer|setInterval|ENTER_FRAME|hzFindByName|new /.test(codeOnly(fnText(as, n).body))) clean = false;
	}
	expect(clean, "no timer, listener, search or allocation in the changed handlers");
	expect((as.match(/BSUIDataManager\.Subscribe\("HUDStealthData"/g) || []).length === 1, "HUDStealthData stays subscribed once (no new subscription)");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("arch fix 3: " + passed + " ok, all passed");
