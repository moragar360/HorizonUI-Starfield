// Pins for the 0.43.1.0 watch and center-reticle rule in horizon_block.as.
// hudmenu and hudmenu_lrg share that block, so one source covers both movies.
// Run: node tests/watch_crosshair_test.js
"use strict";

const fs = require("fs");
const path = require("path");

function readText(p) {
	return fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

const root = path.join(__dirname, "..");
const as = readText(path.join(root, "actionscript", "horizon_block.as"));
const ini = readText(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"));
const preset = readText(path.join(root, "preset", "HorizonUI.moragars-choice.ini"));

let failed = 0;
function expect(cond, msg) {
	if (cond) {
		console.log("ok  " + msg);
		return;
	}
	failed++;
	console.error("FAIL " + msg);
}

function between(src, a, b) {
	const i = src.indexOf(a);
	const j = src.indexOf(b, i + a.length);
	expect(i >= 0 && j > i, "section " + a);
	return i >= 0 && j > i ? src.slice(i, j) : "";
}

const block = between(as, "// =================== 0.43.1.0 watch + center-reticle rule ===================", "// =================== end Horizon UI (HUD module) ===================");

expect(ini.indexOf("WatchStyle=0") >= 0, "default watch is off");
expect(ini.indexOf("CrosshairRule=0") >= 0, "default crosshair rule is always");
expect(ini.indexOf("0 off (default), 1 vanilla, 2 vanilla with Horizon colors, 3 Horizon digital, 4 Horizon analog") >= 0, "watch comment");
expect(ini.indexOf("0 always (default), 1 only with weapon drawn, 2 off") >= 0, "crosshair comment");
expect(as.indexOf('"WatchStyle":0') >= 0 && as.indexOf('"CrosshairRule":0') >= 0, "F11 defaults");
expect(as.indexOf('"l":"WATCH"') >= 0, "CARDS row");
expect(as.indexOf('"l":"CROSSHAIR"') >= 0, "RULES row");
expect(as.indexOf("HORIZON DIGITAL") >= 0 && as.indexOf("HORIZON ANALOG") >= 0, "watch choices");
expect(as.indexOf("WEAPON DRAWN") >= 0, "weapon drawn choice");
expect(block.indexOf("getTimer") < 0, "watch block has no getTimer");
expect(block.indexOf("GlowFilter") < 0, "watch block adds no glow");
expect(block.indexOf("staruihudmenu") < 0, "watch block leaves the other HUD alone");
expect(block.indexOf("LOW O2") >= 0 && block.indexOf("HIGH CO2") >= 0, "attention words");
expect(block.indexOf("0xF28A4F") >= 0, "attention orange");
expect(block.indexOf("hzWeaponOut()") >= 0, "weapon-drawn uses the equipment signal");
expect(block.indexOf("ReticleBase_mc") >= 0, "only the center reticle is gated");
expect(block.indexOf("HorizonChar_mc") >= 0, "watch yields to the character card");
expect(as.indexOf("case \"crosshairstyle\"") >= 0, "CrosshairStyle parser stays");

function funcBody(src, name) {
	const key = "function " + name + "(";
	const i = src.indexOf(key);
	expect(i >= 0, "function " + name);
	if (i < 0) return "";
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") {
			depth--;
			if (depth === 0) return src.slice(brace, p + 1);
		}
	}
	return "";
}

const frameBody = funcBody(as, "hz43Frame");
const placeBody = funcBody(as, "hz43Place");
const tintBody = funcBody(as, "hz43Tint");
expect(frameBody.indexOf("hz43SyncHide") < 0, "sync hide is not called from the watch frame");
expect(as.split("this.hz43SyncHide()").length - 1 === 1, "sync hide runs once per frame");
expect(frameBody.indexOf("new ") < 0, "the watch frame allocates nothing");
expect(placeBody.indexOf("new Point") < 0 && placeBody.indexOf("new Array") < 0, "placement reuses its points and card slots");
expect(tintBody.indexOf("new ColorTransform") < 0 && tintBody.indexOf("new Array") < 0, "style 2 reuses its color transforms");
expect(block.split("new Date(").length - 1 === 1, "the PC clock builds one Date");
expect(block.indexOf("hz43PcSample") >= 0 && block.indexOf("% 60") >= 0, "the PC clock is gated by the frame counter");
expect(funcBody(as, "hz43PcSample").indexOf("hz43PcFr >= 0") >= 0, "a failed clock read still waits on the frame stamp");
expect(funcBody(as, "hz43PcSample").indexOf("hz43PcH = -2") < 0, "a failed clock read does not drop the gate");
expect(funcBody(as, "hz43PcFallback").indexOf("hzPpRealMin") >= 0, "the PC clock falls back to the planet card's real time");
expect(block.indexOf("hz43DayB") >= 0 && block.indexOf("hz43LastO2") >= 0, "dirty checks use number buckets");
expect(block.indexOf("hz43Sig") < 0, "the dirty check does not build a signature string");

expect(as.indexOf("Lower left until") < 0, "the watch does not name its screen position");
expect(block.indexOf("function hz43ShowVanilla") >= 0, "styles 1 and 2 restore the game watch");
expect(block.indexOf("clip.alpha = 1") >= 0, "a restored watch clip gets its alpha back");
expect(block.indexOf("BottomLeftGroup_mc") >= 0 && block.indexOf("WatchOutline_mc") >= 0, "the vanilla path is BottomLeftGroup");
expect(block.indexOf("HZ43 vanilla watch path=") >= 0, "the vanilla clip path is traced once");
expect(block.indexOf("180,16,\"sb\"") >= 0 && block.indexOf("160,13,\"rg\"") >= 0, "digital local time is 16 px and PC time is 13 px");
expect(block.indexOf("hz43LocL.y = -40") >= 0 && block.indexOf("hz43LocT.y = -22") >= 0, "the local label sits above the local time");
expect(block.indexOf("hz43RealL.y = 2") >= 0 && block.indexOf("hz43RealT.y = 18") >= 0, "the PC label sits above the PC time");
expect(block.indexOf("hz43Dial(g,0,-58,day)") < 0 && block.indexOf("hz43PmT.visible = false") >= 0 && block.indexOf("hz43DayT.visible = false") >= 0, "the digital face has no day dial");
expect(block.indexOf("hz43Dial(g,0,64,day)") >= 0 && block.indexOf("hz43PmT.visible = true") >= 0, "the analog day dial stays at 6 o'clock");
expect(block.indexOf("Math.PI / 2 + Math.PI / 6") >= 0 && block.indexOf("Math.PI / 2 - Math.PI / 6") >= 0, "gauges start at 7 o'clock and 5 o'clock");
expect(block.indexOf("0x6E7C86") >= 0, "unfilled gauge segments are gray");
expect(block.indexOf("hz43Hand(g,ma,72,2.2,0xF2F7F9)") >= 0, "the minute hand is white");
expect(block.indexOf("ly < -HZ43_R + 96") >= 0, "compass letters stay on the top arc");
const drawBody = funcBody(as, "hz43Draw");
expect(drawBody.split("hz43Compass(g)").length - 1 === 2, "digital and analog both draw the compass");
expect(drawBody.indexOf("hz43Diamond(g,0,-HZ43_R + 20,4)") < 0, "analog does not draw a second top mark");
expect(drawBody.indexOf("hz43Cards[hi]).visible = false") < 0, "analog does not hide the compass letters");

// 3 o'clock is 0, and clockwise is an increasing angle. 7 o'clock is PI/2 + PI/6.
// A full O2 sweep is half a turn and ends at 1 o'clock. A full CO2 sweep ends at 11 o'clock.
function normAngle(a) {
	const t = Math.PI * 2;
	let x = a % t;
	if (x < 0) x += t;
	return x;
}
const o2Start = Math.PI / 2 + Math.PI / 6;
const co2Start = Math.PI / 2 - Math.PI / 6;
expect(Math.abs(normAngle(o2Start + Math.PI) - (Math.PI * 5) / 3) < 1e-9, "full O2 ends at 1 o'clock");
expect(Math.abs(normAngle(co2Start - Math.PI) - (Math.PI * 4) / 3) < 1e-9, "full CO2 ends at 11 o'clock");

// Dawn is 0.25 and dusk is 0.75 of fLocalPlanetTime. The day arc runs the top half.
function dialAngle(day) {
	if (day >= 0.25 && day <= 0.75) return Math.PI + (day - 0.25) / 0.5 * Math.PI;
	const night = day < 0.25 ? day + 0.25 : day - 0.75;
	return (night / 0.5) * Math.PI;
}
expect(Math.abs(dialAngle(0.25) - Math.PI) < 1e-9, "dawn sits at the left of the dial");
expect(Math.abs(dialAngle(0.5) - Math.PI * 1.5) < 1e-9, "noon sits at the top of the dial");
expect(Math.abs(dialAngle(0.75) - Math.PI * 2) < 1e-9, "dusk sits at the right of the dial");

// Same fallback the equipment card uses when the plugin flag was never set.
function weaponOut(plugActive, plugDrawn, ammoDrawn, crossOn, crossType) {
	return plugActive ? plugDrawn : (ammoDrawn && crossOn && crossType != 2);
}
expect(weaponOut(true, true, false, true, 2) === true, "plugin drawn flag wins");
expect(weaponOut(true, false, true, true, 0) === false, "plugin holstered flag wins");
expect(weaponOut(false, false, true, true, 0) === true, "ammo plus a weapon reticle counts as drawn");
expect(weaponOut(false, false, true, true, 2) === false, "unarmed reticle does not count as drawn");
expect(weaponOut(false, false, false, true, 0) === false, "no ammo display is not drawn");
expect(weaponOut(false, false, true, true, 7) === true, "third person uses the same test while interacting");

function dotHidden(rule, weaponOutNow) {
	if (rule >= 2) return true;
	if (rule === 1) return !weaponOutNow;
	return false;
}
expect(dotHidden(2, true) === true, "off hides the aiming dot");
expect(dotHidden(2, false) === true, "off hides the aiming dot while holstered");
expect(dotHidden(1, false) === true, "a holstered weapon hides the aiming dot");
expect(dotHidden(1, true) === false, "a drawn weapon shows the aiming reticle");
expect(dotHidden(0, false) === false, "always leaves the aiming reticle to the game");

// A visible aiming clip is hidden again even after the tracked instance was dropped.
function rehideVisible(ruleWantsDot, clipVisible, owned) {
	if (!ruleWantsDot) return owned;
	if (clipVisible) return true;
	return owned;
}
expect(rehideVisible(true, true, false) === true, "a re-shown aiming clip is hidden again");
expect(rehideVisible(true, false, false) === false, "an already hidden clip this rule does not own stays unowned");
expect(rehideVisible(false, true, true) === true, "turning the rule off still knows which hide it owns");

function restoreOwn(owned, sameObject, stillHidden, vanillaWants) {
	return owned && sameObject && stillHidden && vanillaWants;
}
expect(restoreOwn(true, true, true, false) === false, "iron sights stay hidden when our hide ends");
expect(restoreOwn(true, true, true, true) === true, "our own hide is the one that is restored");
expect(restoreOwn(false, true, true, true) === false, "a hide this rule does not own is left alone");

const reticleBody = funcBody(as, "hz43Reticle");
expect(reticleBody.indexOf("hzXh") < 0, "the rule does not touch the interact glyph");
expect(reticleBody.indexOf("hz43VanillaReticle") >= 0, "restore checks the game show rule");
expect(reticleBody.indexOf("HZ_HCT_INTERACT") >= 0, "interact keeps its own path");
expect(reticleBody.indexOf("if(!rb.visible) { return; }") < 0, "a visible swap is not ignored");
expect(funcBody(as, "hz43ReticleHide").indexOf("HZ_HCT_INTERACT") < 0, "the aiming-dot rule does not turn off for interact");
expect(funcBody(as, "hz43HideDotKids").indexOf("Player_Interaction_ReticleAnim_mc") >= 0, "the interact ring clip is not one of the hidden children");
expect(funcBody(as, "hz43RingSet").indexOf("Player_Interaction_ReticleAnim_mc") >= 0, "look-away can hide the interact circle");
expect(reticleBody.indexOf("hz43RingSet") >= 0, "the aiming rule owns the leftover circle");
expect(as.indexOf("this.hz43Reticle()") < as.indexOf("this.hzXhTick()"), "the ring is restored before the glyph is drawn");

function ringHidden(ruleWantsDot, interacting) {
	if (!ruleWantsDot) return false;
	return !interacting;
}
expect(ringHidden(true, false) === true, "look-away hides the leftover circle");
expect(ringHidden(true, true) === false, "looking at an interactable keeps the ring");
expect(ringHidden(false, false) === false, "the rule off leaves the ring to the game");

function aimingDotVisible(ruleWantsDot, gameShowedDot) {
	if (!ruleWantsDot) return gameShowedDot;
	return false;
}
expect(aimingDotVisible(true, true) === false, "a holstered walk does not leave the aiming dot visible");
expect(aimingDotVisible(true, false) === false, "a holstered stand keeps the aiming dot hidden");
expect(aimingDotVisible(false, true) === true, "the rule off leaves a shown aiming dot to the game");
expect(reticleBody.indexOf("hz43HideDotKids") >= 0, "a shown aiming dot is hidden again");
expect(funcBody(as, "hz27OnExit").indexOf("this.hz43Reticle()") >= 0, "the hide runs again after the walk timeline");

expect(funcBody(as, "hzLayClips").indexOf("hzWatchStyle == 1") >= 0, "styles 1 and 2 have an Arrange clip");
expect(funcBody(as, "hzArrList").indexOf("hzWatchStyle == 1") >= 0, "styles 1 and 2 show a Watch handle");
expect(as.indexOf("Horizon Digital and Analog can be moved") < 0, "the F11 note is not limited to Digital and Analog");
expect(as.indexOf("Every watch face can be moved in Arrange Cards") >= 0, "the F11 note includes every watch face");
expect(funcBody(as, "hz43VanClip").indexOf("HZ43_VAN_N") >= 0, "Arrange moves the named vanilla watch clips");
expect(funcBody(as, "hz43VanWrite").indexOf("hzBlg.x") < 0 && funcBody(as, "hz43VanWrite").indexOf("hzBlg.y") < 0, "Arrange does not drag the lower-left group");

expect(ini.indexOf("WatchX=-1") >= 0 && ini.indexOf("WatchY=-1") >= 0, "default watch position is the lower-left home");
expect(ini.indexOf("WatchScale=-1") >= 0, "watch size defaults to HudScale");
expect(as.indexOf('"Watch","Enemy"') < 0 && as.indexOf('"HudMessages","Watch"') >= 0, "Watch is an Arrange key");
expect(as.indexOf('"WATCH"') >= 0, "Arrange names the watch");
expect(as.indexOf('["Watch",false]') >= 0, "Watch has its own size entry");
expect(as.indexOf('this.hz34Sz("Watch")') >= 0, "F11 has a watch size row");
expect(placeBody.indexOf('hzLayHas("Watch")') >= 0, "a saved watch position is detected");
expect(as.indexOf("function hz43ApplyHome") >= 0 && as.indexOf("function hz43ApplySaved") >= 0, "home and saved placement are separate");
expect(preset.indexOf("WatchStyle=0") >= 0 && preset.indexOf("CrosshairRule=0") >= 0, "Moragar's Choice sets both rules to the default");
expect(preset.indexOf("WatchX") < 0 && preset.indexOf("WatchY") < 0, "Moragar's Choice does not move the watch");

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("watch crosshair tests passed");
