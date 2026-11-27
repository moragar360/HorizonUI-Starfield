// Equipment "Weapon drawn only" without a plugin IsWeaponOut feed.
// Run: node tests/weapon_drawn_feed_test.js
// The game's console IsWeaponOut is 2 drawn / 0 holstered (1 is fists). CommonLibSF cannot register
// PlayerSetWeaponStateEvent (GetEventSource id 0). The HUD fallback therefore uses the last weapon reticle
// type; HudCrosshairData.bEnabled can be false (vanilla reticle off, a common Horizon setup). uType still
// arrives on that update. Change-driven only (hzOnCrosshair). Mutants that restore the crosshair AND must fail.
// Author: Moragar. Last modified: 2026-11-27.
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
	const h = { hzPlugActive: false, hzPlugDrawn: false, hzAmmoDrawn: false, hzCrossOn: true, hzCrossType: -1, hzWpnRet: false,
		hzInCombat: false, hzInShip: false, hzJetCharge: 1, hzVitHpF: 1, hzVitO2F: 1, hzAfflCount: 0, refresh: 0,
		hzCrossIron: false, hzCross3rd: false, hzCrossTool: false, hzDbgCross: "", hzT19Ver: 0, hzDebug: false,
		hzDump: () => "", hzDbgShow: () => {} };
	h.hzRefreshVisibility = () => { h.refresh++; };
	return bind(h, ["hzWeaponOut", "hzWpnReticle", "hzOnCrosshair", "hzSetWeaponDrawn", "hzRuleOk"]);
}
const ev = (d) => ({ data: d });

{
	const h = host();
	expect(h.hzWeaponOut() === false, "before any crosshair update: not out");
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 4 }));
	expect(h.hzWeaponOut() === true && h.hzRuleOk(3) === true, "rifle reticle with the HUD crosshair off: WEAPON DRAWN ONLY shows (IsWeaponOut 2)");
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 0 }));
	expect(h.hzWeaponOut() === true, "pistol reticle, crosshair off: still out");
	h.hzOnCrosshair(ev({ bEnabled: true, uType: 2 }));
	expect(h.hzWeaponOut() === false && h.hzRuleOk(3) === false, "unarmed reticle: not out (IsWeaponOut 0 / fists without a weapon reticle)");
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 4 }));
	h.hzAmmoDrawn = false;
	expect(h.hzWeaponOut() === true, "a cutter/rifle reticle counts without the ammo counter");
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 7 }));
	expect(h.hzWeaponOut() === true, "interact keeps the last weapon decision");
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 9 }));
	expect(h.hzWeaponOut() === false, "none reticle: not out");
	h.hzSetWeaponDrawn(false);
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 4 }));
	expect(h.hzWeaponOut() === false, "hzSetWeaponDrawn(false) decides over the reticle (holstered, IsWeaponOut 0)");
	h.hzSetWeaponDrawn(true);
	h.hzOnCrosshair(ev({ bEnabled: false, uType: 2 }));
	expect(h.hzWeaponOut() === true, "hzSetWeaponDrawn(true) decides over the reticle (drawn, IsWeaponOut 1 or 2)");
}

{
	const wo = codeOnly(fnText(as, "hzWeaponOut").body);
	expect(wo.indexOf("hzCrossOn") < 0 && wo.indexOf("hzAmmoDrawn") < 0, "the fallback does not require the HUD crosshair or the ammo counter");
	expect(wo.indexOf("this.hzPlugActive ? this.hzPlugDrawn : this.hzWpnRet") >= 0, "plugin feed first, else the weapon reticle");
	const oc = codeOnly(fnText(as, "hzOnCrosshair").body);
	expect(oc.indexOf("hzWpnReticle") >= 0 && oc.indexOf("bEnabled") >= 0, "uType is applied even when bEnabled is false");
	expect(!/addEventListener|Timer|setInterval|ENTER_FRAME/.test(wo + oc), "no timer, listener or frame work");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("weapon drawn feed: " + passed + " ok, all passed");
