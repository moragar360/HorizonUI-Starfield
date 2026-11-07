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
const checks = readText(path.join(root, "CHECKS_0.43.1.0.md"));
const changelog = readText(path.join(root, "CHANGELOG.md"));

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
expect(block.indexOf("clip.alpha = 1") < 0, "watch hide and restore do not write clip.alpha");
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
expect(funcBody(as, "hz43VanCapture").indexOf("HZ43_VAN_N") >= 0 && funcBody(as, "hz43VanCapture").indexOf("hzFindByName") >= 0, "Arrange finds named watch clips under the lower-left group");
expect(funcBody(as, "hz43VanClip").indexOf("getChildByName") < 0, "Arrange does not look only at direct children");
expect(funcBody(as, "hz43VanWrite").indexOf("hzBlg.x") < 0 && funcBody(as, "hz43VanWrite").indexOf("hzBlg.y") < 0, "Arrange does not drag the lower-left group");
expect(funcBody(as, "hz43VanGather").indexOf("depth > 4") < 0, "gather does not recurse into nested watch clips");
expect(funcBody(as, "hz43VanGather").indexOf("numChildren") >= 0 && funcBody(as, "hz43VanGather").indexOf("hz43VanGather(") < 0, "gather walks BottomLeftGroup siblings only");
expect(funcBody(as, "hz43VanRootOf").indexOf("p != this.hzBlg") >= 0, "a nested clip maps to its BottomLeftGroup sibling root");
expect(funcBody(as, "hz43VanCapture").indexOf("d.parent != this.hzBlg") >= 0, "capture drops nested units that are not BottomLeftGroup siblings");
expect(funcBody(as, "hz43VanCapture").indexOf("hasOutline") >= 0 && funcBody(as, "hz43VanCapture").indexOf("hasO2") >= 0, "capture does not latch until the ring and the O2 bar exist");
expect(funcBody(as, "hz43VanCapture").indexOf("hz43VanWrote") >= 0 && funcBody(as, "hz43VanCapture").indexOf("hz43VanKids") >= 0, "an incomplete first capture can be taken again before Arrange writes");
expect(as.indexOf("HZ43_VAN_MAX:int = 24") >= 0, "sibling roots have enough slots for the native watch set");
expect(as.indexOf("HZ43_VAN_FACE:Number = 221") >= 0, "empty first-load bounds fall back to the native ring size");
expect(as.indexOf("HZ43 watch unit=") >= 0, "the moved watch assembly is traced once");
expect(funcBody(as, "hz43VanEnsure").indexOf("drawCircle(90,90,90)") < 0, "the Arrange box is the watch bounds, not a circle parked above it");
expect(drawBody.indexOf("hz43BodyT.y = -22") >= 0 && drawBody.indexOf("hz43TempT.y = -4") >= 0, "the analog planet name sits below the compass letters");
expect(funcBody(as, "hzT19Buttons").indexOf("isHold || !on") < 0, "an enabled hold is not drawn as disabled");
expect(funcBody(as, "hz38HideVanilla").indexOf("hzT19KeepHold") >= 0, "the hold button stays able to receive the key");
expect(funcBody(as, "hz38HideVanilla").indexOf("hzT19HideA(aw") < 0, "the activation widget is not alpha-hidden");
expect(funcBody(as, "hz38HideVanilla").indexOf("hzT19HidePromptTree") >= 0, "prompt art is hidden off the hold path");
expect(funcBody(as, "hzT19KeepHold").indexOf("p.alpha < 1") >= 0, "hold ancestors are restored to alpha 1");

const onFrame = funcBody(as, "hzOnFrame");
const style0At = onFrame.indexOf("hzWatchStyle == 0");
const pushMark = onFrame.indexOf('names.push("WatchIconsWidget_mc","WatchPointerOutline_mc")');
expect(style0At >= 0 && pushMark > style0At, "style 0 hides the leftover radar and nearby markers");
expect(onFrame.indexOf("keepMark") >= 0 && onFrame.indexOf("hzWatchStyle == 3") >= 0 && onFrame.indexOf("hzWatchStyle == 4") >= 0, "Horizon faces still keep the live markers");
expect(funcBody(as, "hz43ShowVanilla").indexOf("hz43VanBlgChrome(false)") >= 0, "vanilla restores unnamed watch chrome");
expect(funcBody(as, "hz43ShowVanilla").indexOf("hz43VanRestoreHid") >= 0, "vanilla undoes Horizon Off and custom hides");
expect(funcBody(as, "hz43ShowVanilla").indexOf("clip.alpha = 1") < 0, "vanilla does not force DisplayObject alpha over native FadeIn");
expect(funcBody(as, "hz43ShowVanilla").indexOf("clip.visible = true") < 0, "vanilla does not force-show native conditional clips");
expect(funcBody(as, "hz43ShowVanilla").indexOf("this.hz43InfoHide()") < 0, "vanilla does not name-list hide native info");
expect(funcBody(as, "hz43ShowVanilla").indexOf("hz43VanInfoName(name)") >= 0, "vanilla does not count info clips as forced face hits");
expect(as.indexOf('HZ43_VAN_INFO:Array = ["Temperature_mc","Oxygen_mc","Grav_mc","OffPlanet_mc"]') >= 0, "native conditional readout names stay listed");
expect(as.indexOf("function hz43StRestore") < 0 && as.indexOf("function hz43StCapture") < 0, "there is no separate snapshot restore of native info");
expect(funcBody(as, "hz43VanRestoreHid").indexOf("hz43VanWatchClip") >= 0, "restore only touches verified watch clips");
expect(funcBody(as, "hz43VanRestoreHid").indexOf("d.alpha") < 0 && funcBody(as, "hz43VanNote").indexOf("d.alpha") < 0 && as.indexOf("hz43HidAl") < 0, "restore does not write a stored FadeIn alpha");
expect(funcBody(as, "hz43VanRestoreHid").indexOf("hz43VanEnvWant") >= 0 && funcBody(as, "hz43VanRestoreHid").indexOf("hz43VanGameVis") >= 0, "restore applies payload formulas to the four native vis clips");
expect(funcBody(as, "hz43VanHorizon").indexOf("hz43VanChrome(true)") >= 0 && funcBody(as, "hz43VanHorizon").indexOf("if(this.hz43VanCap == 0) { return; }") < 0, "custom chrome hide does not wait on Arrange capture");
expect(funcBody(as, "hz43VanHorizon").indexOf("hz43VanWrite(cx - rx,cy - ry,1,true)") >= 0, "custom moves live markers only at native scale");
expect(funcBody(as, "hz43VanHorizon").indexOf("face / this.hz43VanRad") < 0 && funcBody(as, "hz43VanWrite").indexOf("marks") >= 0, "custom does not fit-scale the native assembly");
expect(funcBody(as, "hz43VanRingMid").indexOf("HZ43_VAN_FACE / 2") >= 0 && funcBody(as, "hz43VanRingMid").indexOf("getBounds") < 0, "marker follow uses outline local center, not hidden getBounds");
expect(funcBody(as, "hz43VanDump").indexOf("vis=") >= 0 && funcBody(as, "hz43VanDump").indexOf(" a=") >= 0, "HZ43 dump reports vis and alpha separately");
expect(funcBody(as, "hz43ShowVanilla").indexOf("hz43VanDump(\"vanilla\")") >= 0, "Vanilla restore dumps sibling vis and alpha");
expect(funcBody(as, "hz43VanInstName").indexOf('name.indexOf("instance") == 0') >= 0, "instance66 is unnamed cap chrome, not an empty-string name");
expect(funcBody(as, "hz43VanNamed").indexOf("hz43VanInstName") >= 0 && funcBody(as, "hz43VanWatchClip").indexOf("hz43VanInstName") >= 0, "capture and own-hide treat instance names as BLG chrome");
expect(funcBody(as, "hz43VanBlgChrome").indexOf("hz43VanInstName") >= 0, "Vanilla chrome restore unhides instance cap names");
expect(funcBody(as, "hz43VanDump").indexOf("ctA=") >= 0 && funcBody(as, "hz43VanDump").indexOf("HZ43_DIAG") >= 0, "dump records ColorTransform alpha and the diagnostic package token");
expect(funcBody(as, "hz43VanDump").indexOf("hz43VanNamed") < 0, "dump lists every BottomLeftGroup child, not only VanNamed clips");
expect(as.indexOf('HZ43_DIAG:String = "r9-inst66-ct-20261107"') >= 0, "next gfx can prove package r9-inst66-ct-20261107");
expect(funcBody(as, "hz43VanCapture").indexOf('hz43VanDump("cap")') >= 0, "dump after capture latch prints cap=1");
expect(funcBody(as, "hz43VanWrite").indexOf("write-marks") >= 0, "dump runs at native and marker writes");
expect(funcBody(as, "hz43VanNote").indexOf("hz43HidV") < 0 && funcBody(as, "hz43VanRestoreHid").indexOf("hz43HidV") < 0, "hide identity list does not sample clip.visible for restore");
expect(funcBody(as, "hzOnLocalEnv").indexOf("hz43VanEnvCache") >= 0, "LocalEnvironmentData updates the watch vis cache");
expect(funcBody(as, "hz43VanEnvCache").indexOf("bInSpaceship") >= 0 && funcBody(as, "hz43VanEnvCache").indexOf("bIsLanded") >= 0 && funcBody(as, "hz43VanEnvCache").indexOf("bIsShipInCruiseMode") >= 0, "cache uses native local and cruise keys");
expect(funcBody(as, "hz43VanEnvWant").indexOf('lang != "ja"') >= 0 && funcBody(as, "hz43VanEnvWant").indexOf('lang != "zhhans"') >= 0, "location vis matches native UpdateLocationName");
expect(funcBody(as, "hz43VanEnvWant").indexOf("!this.hz43EnvLocal") >= 0, "day vis is not local");
expect(funcBody(as, "hz43VanEnvWant").indexOf("this.hz43EnvLocal && !this.hz43EnvCruise") >= 0, "off-planet vis is local and not cruise");
expect(funcBody(as, "hz43VanEnvWant").indexOf("this.hz43EnvLocal && this.hz43EnvCruise") >= 0, "autopilot vis is local and cruise");
expect(as.indexOf("private var hz43EnvLang:String = \"\"") >= 0, "location language starts as onAdded empty string");
expect(funcBody(as, "hz43StHide").indexOf("d.alpha") < 0, "watch own-hide does not write alpha");
expect(funcBody(as, "hz36HideTick").indexOf("hz43VanWatchClip") >= 0, "hide tick own-hides watch clips apart from health ammo boost");
expect(funcBody(as, "hz43VanNote").indexOf("hz43VanWatchClip") >= 0, "the hid list refuses non-watch clips");
expect(as.indexOf('HZ43_VAN_MARK:Array = ["WatchIconsWidget_mc","WatchPointerOutline_mc","MissionIconsWidget_mc","EnemyIconsWidget_mc"]') >= 0, "live markers include mission and enemy widgets");
expect(as.indexOf("HZ43_HID_MAX:int = 40") >= 0 && funcBody(as, "hz43VanNote").indexOf(">= 32") < 0, "the watch hid list is a 40-slot identity cap");
expect(funcBody(as, "hz43VanRestoreHid").indexOf("HealthBar") < 0 && funcBody(as, "hz43VanNote").indexOf("HealthBar") < 0, "health is not on the watch hid list");
expect(funcBody(as, "hz43VanGameVis").indexOf("DayCycleBase_mc") >= 0 && funcBody(as, "hz43VanGameVis").indexOf("Autopilot_mc") >= 0, "game-owned visibility includes day cycle and autopilot");
expect(as.indexOf("function hz43IdCt") < 0 && as.indexOf("function hz43Ct(") < 0, "style 2 no longer assigns a cached identity ColorTransform");
expect(funcBody(as, "hz43TintRgb").indexOf("alphaMultiplier") < 0 && funcBody(as, "hz43TintClear").indexOf("alphaMultiplier") < 0, "style 2 tint and clear do not write alphaMultiplier");
expect(as.indexOf('HZ43_TINT_N:Array = ["WatchOutline_mc","WatchPointerOutline_mc","O2CO2_mc","O2CO2thin_mc","DayCycleBase_mc","locationNameBase_mc"]') >= 0 && funcBody(as, "hz43VanRestoreHid").indexOf("Temperature_mc") < 0, "restore does not special-case INFO names or force their alpha");
expect(onFrame.indexOf("hzWatchStyle == 0") >= 0 && onFrame.indexOf('names.push("MissionIconsWidget_mc","EnemyIconsWidget_mc")') >= 0, "Off still hides mission and enemy widgets");
expect(funcBody(as, "hz43VanMarkName").indexOf("MissionIconsWidget_mc") >= 0, "custom keep-mark includes mission widgets");
expect(funcBody(as, "hz43VanChrome").indexOf("this.hz43InfoHide()") < 0, "chrome restore does not re-hide native info");
expect(funcBody(as, "hz43VanChrome").indexOf("hz43StRestore") < 0, "chrome restore has no info snapshot helper");
expect(funcBody(as, "hz43VanBlgChrome").indexOf("d.alpha = 1") < 0 && funcBody(as, "hz43VanBlgChrome").indexOf("d.alpha < 1") < 0, "unnamed chrome show does not write alpha");
expect(funcBody(as, "hz43SyncHide").indexOf("hz43InfoHide") < 0, "live vanilla frames do not keep-hide native info");
expect(funcBody(as, "hz36HideTick").indexOf("hz43StHide") >= 0 && funcBody(as, "hz36HideTick").indexOf("continue") >= 0, "hide tick own-hides watch clips then leaves health ammo boost on the generic hide");
expect(funcBody(as, "hz43VanNote").indexOf("hz43VanInfoName") < 0, "the chrome hid list records native info Horizon hid");
expect(funcBody(as, "hz43VanSkip").indexOf("Mission") < 0 && funcBody(as, "hz43VanSkip").indexOf("Autopilot_mc") < 0, "watch-face markers and autopilot are sibling units");
expect(onFrame.indexOf('names.push("WatchOutline_mc","DayCycleBase_mc","locationNameBase_mc")') >= 0, "vanilla face clips leave the compass hide");
expect(onFrame.indexOf('names.push("Temperature_mc","Oxygen_mc","Grav_mc","OffPlanet_mc")') >= 0, "native info leaves the compass hide with the face");
expect(onFrame.indexOf("hzWatchStyle != 1 && this.hzWatchStyle != 2") >= 0, "compass hide of the watch is off on styles 1 and 2");
expect(onFrame.indexOf('names.push("WatchOutline_mc","DayCycleBase_mc","locationNameBase_mc","Temperature_mc"') < 0, "vanilla face restore is not bundled with extra readouts");
expect(as.indexOf('HZ43_TINT_N:Array = ["WatchOutline_mc","WatchPointerOutline_mc","O2CO2_mc","O2CO2thin_mc","DayCycleBase_mc","locationNameBase_mc"]') >= 0, "style 2 tints the original watch face only");
expect(as.indexOf('HZ43_TINT_N:Array = ["WatchOutline_mc","WatchPointerOutline_mc","O2CO2_mc","O2CO2thin_mc","DayCycleBase_mc","locationNameBase_mc","Temperature_mc"') < 0, "style 2 does not tint extra native readouts");
expect(funcBody(as, "hz43Frame").indexOf("hz43Watch.visible = false") >= 0, "vanilla hides the Horizon-drawn watch");
expect(drawBody.indexOf("hz43TempT.text") >= 0 && drawBody.indexOf("hz43BodyT.text") >= 0, "digital and analog still draw planet and temperature");
expect(funcBody(as, "hz43VanChrome").indexOf("hz43VanBlgChrome(hide)") >= 0, "Horizon faces hide unnamed cap art with the vanilla bezel");
expect(funcBody(as, "hz43VanInstName").indexOf("name.length == 0") >= 0 && funcBody(as, "hz43VanNamed").indexOf("hz43VanInstName") >= 0, "unnamed shapes belong to the watch assembly");
expect(funcBody(as, "hz43VanSkip").indexOf("name.length == 0) { return true; }") < 0, "unnamed chrome is not skipped from the watch assembly");
expect(funcBody(as, "hz43VanSkip").indexOf("name.length == 0) { return false; }") >= 0, "unnamed shapes stay in the watch assembly");

function leftoverWatchVisible(style, clip) {
	const alerts = ["EnemyDetectionAnim_mc", "EnvAlertText", "BioAlertText", "LocationAlertText"];
	if (alerts.indexOf(clip) >= 0) return true;
	const mark = clip === "WatchIconsWidget_mc" || clip === "WatchPointerOutline_mc" || clip === "MissionIconsWidget_mc" || clip === "EnemyIconsWidget_mc";
	if (style === 0) return false;
	if (style === 3 || style === 4) return mark;
	return true;
}
expect(leftoverWatchVisible(0, "WatchIconsWidget_mc") === false, "off hides the inner radar");
expect(leftoverWatchVisible(0, "WatchPointerOutline_mc") === false, "off hides the heading outline");
expect(leftoverWatchVisible(0, "MissionIconsWidget_mc") === false, "off hides mission markers");
expect(leftoverWatchVisible(0, "Autopilot_mc") === false, "off hides the native watch autopilot pip");
expect(leftoverWatchVisible(0, "EnemyDetectionAnim_mc") === true, "off leaves the detection ring");
expect(leftoverWatchVisible(3, "WatchIconsWidget_mc") === true, "digital keeps nearby markers");
expect(leftoverWatchVisible(3, "MissionIconsWidget_mc") === true, "digital keeps mission markers");
expect(leftoverWatchVisible(3, "EnemyIconsWidget_mc") === true, "digital keeps enemy markers");
expect(leftoverWatchVisible(4, "WatchIconsWidget_mc") === true, "analog keeps nearby markers");
expect(leftoverWatchVisible(4, "MissionIconsWidget_mc") === true, "analog keeps mission markers");
expect(leftoverWatchVisible(4, "EnemyIconsWidget_mc") === true, "analog keeps enemy markers");
expect(leftoverWatchVisible(1, "WatchIconsWidget_mc") === true, "vanilla keeps nearby markers");
expect(leftoverWatchVisible(3, "WatchOutline_mc") === false, "digital hides the vanilla bezel");

const VAN_N = ["WatchOutline_mc","WatchPointerOutline_mc","WatchIconsWidget_mc","O2CO2_mc","O2CO2thin_mc","DayCycleBase_mc","locationNameBase_mc","Temperature_mc","Oxygen_mc","Grav_mc","OffPlanet_mc"];
const INFO_NAMES = ["Temperature_mc", "Oxygen_mc", "Grav_mc", "OffPlanet_mc"];
function isInfoName(name) {
	return INFO_NAMES.indexOf(name) >= 0;
}
function vanSkip(name) {
	if (name == null) return true;
	if (name.length === 0) return false;
	if (name === "EnemyDetectionAnim_mc") return true;
	if (name.indexOf("Alert") >= 0) return true;
	if (name.indexOf("Bio") === 0 || name.indexOf("Env") === 0) return true;
	if (name.indexOf("Horizon") === 0) return true;
	return false;
}
function vanNamed(name) {
	if (name == null) return false;
	if (vanSkip(name)) return false;
	if (name.length === 0) return true;
	if (name === "MissionIconsWidget_mc" || name === "EnemyIconsWidget_mc" || name === "Autopilot_mc") return true;
	if (VAN_N.indexOf(name) >= 0) return true;
	return name.indexOf("Watch") === 0;
}
function newRootOf(clip, blg) {
	let root = clip;
	let p = clip.parent;
	while (p && p !== blg) {
		root = p;
		p = p.parent;
	}
	return p === blg && !vanSkip(root.name) ? root : null;
}

const blg = { name: "BottomLeftGroup_mc" };
const o2co2 = { name: "O2CO2_mc", parent: blg, x: 21.7, y: 89.85, kids: [] };
const o2anim = { name: "O2Anim_mc", parent: o2co2, x: -9.35, y: 20.7 };
const co2anim = { name: "CO2Anim_mc", parent: o2co2, x: -9.35, y: 20.7 };
const unnamedInner = { name: "", parent: o2anim, x: 0, y: 0 };
o2anim.kids = [unnamedInner];
o2co2.kids = [o2anim, co2anim];
const outline = { name: "WatchOutline_mc", parent: blg, x: 0, y: 0 };
const unnamedCap = { name: "", parent: blg, x: 0, y: -0.25 };
const pointer = { name: "WatchPointerOutline_mc", parent: blg, x: 111, y: 111 };
const icons = { name: "WatchIconsWidget_mc", parent: blg, x: 111.35, y: 111.45 };
const mission = { name: "MissionIconsWidget_mc", parent: blg, x: 111.35, y: 111.45 };
const enemy = { name: "EnemyIconsWidget_mc", parent: blg, x: 111.35, y: 111.45 };
const thin = { name: "O2CO2thin_mc", parent: blg, x: 16.1, y: 88.3 };
const bio = { name: "BioCondition_mc", parent: blg, x: 96.25, y: 24.45 };
const detect = { name: "EnemyDetectionAnim_mc", parent: blg, x: 110.5, y: 110.5 };
const blgKids = [unnamedCap, outline, pointer, o2co2, thin, icons, mission, enemy, bio, detect];

function gatherSiblings(kids) {
	const units = [];
	for (let i = 0; i < kids.length; i++) {
		if (vanNamed(kids[i].name)) units.push(kids[i]);
	}
	return units;
}
function oldSafe(box) {
	const kids = box && box.kids ? box.kids : [];
	for (let i = 0; i < kids.length; i++) {
		const cn = kids[i].name;
		if (cn && cn.length > 0 && !vanNamed(cn)) return false;
	}
	return true;
}
function oldRootOf(clip) {
	let root = clip;
	let p = clip.parent;
	while (p && p !== blg) {
		if (!oldSafe(p)) break;
		root = p;
		p = p.parent;
	}
	return root;
}
function gatherNestedOld(node, depth, out) {
	if (!node || depth > 4) return;
	const kids = node === blg ? blgKids : node.kids;
	if (!kids) return;
	for (let i = 0; i < kids.length; i++) {
		const ch = kids[i];
		if (vanNamed(ch.name)) out.push(oldRootOf(ch));
		if (!vanSkip(ch.name)) gatherNestedOld(ch, depth + 1, out);
	}
}

const siblingUnits = gatherSiblings(blgKids);
expect(siblingUnits.indexOf(o2co2) >= 0 && siblingUnits.indexOf(outline) >= 0, "native ring and O2 bar are sibling units");
expect(siblingUnits.indexOf(unnamedCap) >= 0, "unnamed cap is a BottomLeftGroup sibling unit");
expect(siblingUnits.indexOf(o2anim) < 0 && siblingUnits.indexOf(co2anim) < 0, "inner O2Anim_mc is not a unit");
expect(siblingUnits.indexOf(bio) < 0 && siblingUnits.indexOf(detect) < 0, "bio and detection are not watch units");
expect(siblingUnits.indexOf(mission) >= 0 && siblingUnits.indexOf(enemy) >= 0, "mission and enemy widgets move with the watch");
expect(newRootOf(o2anim, blg) === o2co2, "O2Anim_mc maps to O2CO2_mc");
expect(newRootOf(unnamedInner, blg) === o2co2, "unnamed art inside O2Anim_mc maps to O2CO2_mc, not itself");
const oldNested = [];
gatherNestedOld(blg, 0, oldNested);
expect(oldNested.indexOf(o2anim) >= 0 || oldNested.indexOf(unnamedInner) >= 0, "the old nested gather could pick inner O2 art");

function writeUnits(units, dx) {
	for (let i = 0; i < units.length; i++) {
		const d = units[i];
		if (d.parent !== blg) continue;
		d.x = d.x0 + dx;
		d.y = d.y0;
	}
}

outline.x0 = 0; outline.y0 = 0; outline.x = 0; outline.y = 0;
o2co2.x0 = 21.7; o2co2.y0 = 89.85; o2co2.x = 21.7; o2co2.y = 89.85;
o2anim.x0 = -9.35; o2anim.y0 = 20.7; o2anim.x = -9.35; o2anim.y = 20.7;
writeUnits([outline, o2co2], 10);
expect(outline.x === 10 && o2co2.x === 31.7, "sibling write keeps the native 21.7 px O2 offset");
expect(o2anim.x === -9.35, "inner O2Anim_mc keeps its native local after a sibling write");
writeUnits([outline, o2co2, o2anim], 10);
expect(o2anim.x === -9.35, "a nested unit is not written even if it was listed");

const WATCH_NAMES = {
	WatchOutline_mc: 1, O2CO2_mc: 1, O2CO2thin_mc: 1, WatchIconsWidget_mc: 1,
	WatchPointerOutline_mc: 1, MissionIconsWidget_mc: 1, EnemyIconsWidget_mc: 1,
	Temperature_mc: 1, Oxygen_mc: 1, Grav_mc: 1, OffPlanet_mc: 1,
	DayCycleBase_mc: 1, locationNameBase_mc: 1, Autopilot_mc: 1
};
const GAME_VIS = { DayCycleBase_mc: 1, OffPlanet_mc: 1, Autopilot_mc: 1, locationNameBase_mc: 1 };
const MARK_NAMES = { WatchIconsWidget_mc: 1, WatchPointerOutline_mc: 1, MissionIconsWidget_mc: 1, EnemyIconsWidget_mc: 1 };
const OTHER_HIDES = { HealthBar_mc: 1, EquippedWeaponAmmo_mc: 1, JetpackMeterWrapper_mc: 1 };

function makeClip(name, visible, alpha, x, y) {
	return {
		name: name, visible: visible, alpha: alpha, alphaMultiplier: alpha,
		x: x || 0, y: y || 0, x0: x || 0, y0: y || 0, scaleX: 1, scaleY: 1
	};
}
function displayed(d) {
	return !!(d && d.visible && d.alpha > 0);
}
function isInstName(name) {
	return name === "" || (typeof name === "string" && name.indexOf("instance") === 0);
}
function isWatchClip(d) {
	return !!(d && (WATCH_NAMES[d.name] || isInstName(d.name)));
}
function hidHas(hid, clip) {
	for (let i = 0; i < hid.length; i++) {
		if (hid[i].d === clip) return true;
	}
	return false;
}
function nativeLocal(d) {
	return Boolean(d.bInSpaceship) && !d.bIsLanded;
}
function envCache(state, d) {
	if (!d) return;
	state.envLocal = nativeLocal(d);
	state.envCruise = Boolean(d.bIsShipInCruiseMode);
	state.envLang = d.sLanguage != null ? String(d.sLanguage) : "";
	state.envGot = 1;
}
function envWant(state, name) {
	if (name === "locationNameBase_mc") {
		const lang = state.envLang != null ? String(state.envLang) : "";
		return lang !== "ja" && lang !== "zhhans";
	}
	if (!state.envGot) return false;
	if (name === "DayCycleBase_mc") return !state.envLocal;
	if (name === "OffPlanet_mc") return state.envLocal && !state.envCruise;
	if (name === "Autopilot_mc") return state.envLocal && state.envCruise;
	return false;
}
function planetPayload() {
	return { bInSpaceship: false, bIsLanded: false, bIsShipInCruiseMode: false, sLanguage: "" };
}
function noteClip(hid, d) {
	if (!isWatchClip(d)) return;
	for (let i = 0; i < hid.length; i++) {
		if (hid[i].d === d) return;
	}
	hid.push({ d: d });
}
function stHideWatch(hid, d) {
	noteClip(hid, d);
	d.visible = false;
}
function hideTick(clips, hid, style) {
	const showVan = style === 1 || style === 2;
	const keepMarks = style === 3 || style === 4;
	const names = Object.keys(clips);
	for (let i = 0; i < names.length; i++) {
		const d = clips[names[i]];
		if (OTHER_HIDES[d.name]) {
			d.visible = false;
			d.alpha = 0;
			continue;
		}
		if (!isWatchClip(d) || showVan) continue;
		if (keepMarks && MARK_NAMES[d.name]) continue;
		stHideWatch(hid, d);
	}
}
function restoreHid(state) {
	const hid = state.hid;
	for (let i = 0; i < hid.length; i++) {
		const d = hid[i].d;
		if (!isWatchClip(d)) continue;
		if (GAME_VIS[d.name]) {
			if (state.envGot || d.name === "locationNameBase_mc") d.visible = envWant(state, d.name);
		} else if (!d.visible) {
			d.visible = true;
		}
	}
	hid.length = 0;
}
function showVanilla(state) {
	restoreHid(state);
}
function captureWatch(state) {
	const outline = state.clips.WatchOutline_mc;
	const o2 = state.clips.O2CO2_mc;
	if (!outline || !o2) {
		state.vanCap = 0;
		return;
	}
	if (state.vanCap && (state.vanWrote || state.markMoved)) return;
	const names = Object.keys(state.clips);
	state.units = [];
	for (let i = 0; i < names.length; i++) {
		const d = state.clips[names[i]];
		if (!isWatchClip(d)) continue;
		d.x0 = d.x;
		d.y0 = d.y;
		state.units.push(d);
	}
	state.vanCap = 1;
}
function ringMid(state) {
	const d = state.clips.WatchOutline_mc;
	if (!d) return null;
	return { x: d.x + 221 / 2, y: d.y + 221 / 2 };
}
function vanWrite(state, dx, dy, sc, marks) {
	if (!state.vanCap) return;
	const units = state.units || [];
	for (let i = 0; i < units.length; i++) {
		const d = units[i];
		if (marks && !MARK_NAMES[d.name]) continue;
		const useSc = marks ? 1 : sc;
		d.x = d.x0 + (d.x0 - d.x0) * useSc + dx;
		d.y = d.y0 + (d.y0 - d.y0) * useSc + dy;
		if (!marks) {
			d.scaleX = useSc;
			d.scaleY = useSc;
		}
	}
	if (marks) {
		if (dx !== 0 || dy !== 0) state.markMoved = true;
	} else {
		state.vanWrote = sc !== 1 || dx !== 0 || dy !== 0;
	}
}
function vanHorizon(state) {
	chromeHide(state.clips, state.hid, true);
	captureWatch(state);
	const face = state.face;
	const ring = ringMid(state);
	if (state.vanCap && ring && face) {
		const sc = face.sc || 1;
		vanWrite(state, face.x + 132 * sc - ring.x, face.y + 132 * sc - ring.y, 1, true);
	}
}
function chromeHide(clips, hid, keepMarks) {
	const names = Object.keys(clips);
	for (let i = 0; i < names.length; i++) {
		const d = clips[names[i]];
		if (!isWatchClip(d)) continue;
		if (keepMarks && MARK_NAMES[d.name]) {
			d.visible = true;
			continue;
		}
		stHideWatch(hid, d);
	}
}
function tintRgb(clip, amt) {
	clip.redMultiplier = 1 - amt;
	clip.redOffset = 10;
}
function tintClear(clip) {
	clip.redMultiplier = 1;
	clip.redOffset = 0;
}
function makeWatchState(payload) {
	const state = {
		style: 0,
		hideWatch: true,
		vanShown: 0,
		hid: [],
		vanCap: 0,
		vanWrote: false,
		markMoved: false,
		units: [],
		face: { x: 0, y: 80, sc: 1, visible: false },
		envGot: 0,
		envLocal: false,
		envCruise: false,
		envLang: "",
		clips: {
			instance66: makeClip("instance66", true, 0, 0, -0.25),
			WatchOutline_mc: makeClip("WatchOutline_mc", true, 0, 0, 0),
			O2CO2_mc: makeClip("O2CO2_mc", true, 0, 21.7, 89.85),
			O2CO2thin_mc: makeClip("O2CO2thin_mc", true, 0, 16.1, 88.3),
			WatchIconsWidget_mc: makeClip("WatchIconsWidget_mc", true, 1, 111.35, 111.45),
			WatchPointerOutline_mc: makeClip("WatchPointerOutline_mc", true, 0, 111, 111),
			MissionIconsWidget_mc: makeClip("MissionIconsWidget_mc", true, 1, 111.35, 111.45),
			EnemyIconsWidget_mc: makeClip("EnemyIconsWidget_mc", true, 1, 111.35, 111.45),
			Temperature_mc: makeClip("Temperature_mc", true, 0, 79.7, 133.75),
			Oxygen_mc: makeClip("Oxygen_mc", true, 0, 112.95, 133.75),
			Grav_mc: makeClip("Grav_mc", true, 0, 149.7, 133.75),
			OffPlanet_mc: makeClip("OffPlanet_mc", false, 0, 110.45, 104.45),
			DayCycleBase_mc: makeClip("DayCycleBase_mc", true, 0, 110.5, 110.5),
			locationNameBase_mc: makeClip("locationNameBase_mc", true, 0, 110.15, 139.75),
			Autopilot_mc: makeClip("Autopilot_mc", false, 0, 110.45, 104.45),
			HealthBar_mc: makeClip("HealthBar_mc", true, 1),
			EquippedWeaponAmmo_mc: makeClip("EquippedWeaponAmmo_mc", true, 1),
			JetpackMeterWrapper_mc: makeClip("JetpackMeterWrapper_mc", true, 1)
		}
	};
	if (payload !== null) envCache(state, payload || planetPayload());
	return state;
}
function applyWatchStyle(state, style) {
	const showVan = style === 1 || style === 2;
	const hideWatch = !showVan;
	if (hideWatch !== state.hideWatch) {
		state.hideWatch = hideWatch;
		if (showVan) state.vanShown = 0;
	}
	hideTick(state.clips, state.hid, style);
	if (style === 3 || style === 4) {
		state.face.visible = true;
		vanHorizon(state);
	} else if (hideWatch) {
		state.face.visible = false;
		chromeHide(state.clips, state.hid, false);
	}
	if (showVan) {
		state.face.visible = false;
		if (state.markMoved) {
			vanWrite(state, 0, 0, 1, false);
			state.markMoved = false;
		}
	}
	if (showVan && state.vanShown === 0) {
		showVanilla(state);
		state.vanShown = 1;
	}
	hideTick(state.clips, state.hid, style);
	if (showVan) restoreHid(state);
	state.style = style;
}

expect(nativeLocal({ bInSpaceship: true, bIsLanded: false }) === true, "local is in spaceship and not landed");
expect(nativeLocal({ bInSpaceship: true, bIsLanded: true }) === false, "landed ship is not local");
expect(nativeLocal({ bInSpaceship: false, bIsLanded: false }) === false, "planet is not local");

const fade = makeWatchState();
applyWatchStyle(fade, 0);
expect(fade.clips.WatchOutline_mc.visible === false && fade.clips.WatchOutline_mc.alpha === 0, "Off hides the ring by visible and leaves FadeIn alpha 0");
expect(!hidHas(fade.hid, fade.clips.HealthBar_mc) && !hidHas(fade.hid, fade.clips.EquippedWeaponAmmo_mc) && !hidHas(fade.hid, fade.clips.JetpackMeterWrapper_mc), "Off does not put health ammo or boost on the watch hid list");
fade.clips.WatchOutline_mc.alpha = 1;
fade.clips.O2CO2_mc.alpha = 1;
applyWatchStyle(fade, 1);
expect(fade.clips.WatchOutline_mc.visible === true && fade.clips.WatchOutline_mc.alpha === 1, "Off then Vanilla shows the ring and keeps post-FadeIn alpha");
expect(fade.clips.O2CO2thin_mc.visible === true && fade.clips.O2CO2thin_mc.alpha === 0, "Vanilla does not force the native-0 thin bar on");
expect(fade.clips.Temperature_mc.visible === true && fade.clips.Temperature_mc.alpha === 0, "Off vis undo on Temperature does not display INFO at FadeInPlanetInfo alpha 0");
expect(fade.clips.Oxygen_mc.visible === true && fade.clips.Oxygen_mc.alpha === 0, "Off vis undo on Oxygen does not display INFO at alpha 0");
expect(fade.clips.Grav_mc.visible === true && fade.clips.Grav_mc.alpha === 0, "Off vis undo on Grav does not display INFO at alpha 0");
expect(fade.clips.DayCycleBase_mc.visible === true && fade.clips.locationNameBase_mc.visible === true, "planet payload restores day and location true");
expect(fade.clips.OffPlanet_mc.visible === false && fade.clips.Autopilot_mc.visible === false, "planet payload restores off-planet and autopilot false");
expect(fade.clips.HealthBar_mc.visible === false && fade.clips.HealthBar_mc.alpha === 0, "health stays hidden through Off then Vanilla");
expect(fade.clips.EquippedWeaponAmmo_mc.visible === false && fade.clips.JetpackMeterWrapper_mc.visible === false, "ammo and boost stay hidden through Off then Vanilla");
expect(fade.hid.length === 0, "Off then Vanilla leaves the watch hid list empty");

const noEnv = makeWatchState(null);
applyWatchStyle(noEnv, 0);
applyWatchStyle(noEnv, 1);
expect(noEnv.clips.locationNameBase_mc.visible === true, "onAdded empty language restores location true before first env payload");
expect(noEnv.clips.DayCycleBase_mc.visible === false && noEnv.clips.OffPlanet_mc.visible === false && noEnv.clips.Autopilot_mc.visible === false, "day off-planet and autopilot wait for the first LocalEnvironmentData");

const ship = makeWatchState({ bInSpaceship: true, bIsLanded: false, bIsShipInCruiseMode: false, sLanguage: "" });
applyWatchStyle(ship, 0);
applyWatchStyle(ship, 1);
expect(ship.clips.DayCycleBase_mc.visible === false && ship.clips.Autopilot_mc.visible === false, "ship payload restores day and autopilot false");
expect(ship.clips.OffPlanet_mc.visible === true && ship.clips.locationNameBase_mc.visible === true, "ship payload restores off-planet and location true");
expect(ship.clips.HealthBar_mc.visible === false, "health stays hidden through ship Off then Vanilla");

const cruise = makeWatchState({ bInSpaceship: true, bIsLanded: false, bIsShipInCruiseMode: true, sLanguage: "" });
applyWatchStyle(cruise, 0);
applyWatchStyle(cruise, 1);
expect(cruise.clips.Autopilot_mc.visible === true, "cruise payload restores autopilot true");
expect(cruise.clips.OffPlanet_mc.visible === false && cruise.clips.DayCycleBase_mc.visible === false, "cruise payload restores off-planet and day false");

const duringOff = makeWatchState();
applyWatchStyle(duringOff, 0);
envCache(duringOff, { bInSpaceship: true, bIsLanded: false, bIsShipInCruiseMode: false, sLanguage: "" });
applyWatchStyle(duringOff, 0);
expect(duringOff.clips.OffPlanet_mc.visible === false, "Off still hides after a boarding payload until Vanilla");
applyWatchStyle(duringOff, 1);
expect(duringOff.clips.OffPlanet_mc.visible === true, "boarding during Off restores off-planet true from the payload");
expect(duringOff.clips.DayCycleBase_mc.visible === false, "boarding during Off restores day false from the payload");
expect(duringOff.clips.Autopilot_mc.visible === false, "boarding without cruise restores autopilot false");
expect(duringOff.clips.HealthBar_mc.visible === false, "health stays hidden after a native watch event during Off");

const landed = makeWatchState({ bInSpaceship: true, bIsLanded: false, bIsShipInCruiseMode: false, sLanguage: "" });
applyWatchStyle(landed, 0);
envCache(landed, { bInSpaceship: true, bIsLanded: true, bIsShipInCruiseMode: false, sLanguage: "" });
applyWatchStyle(landed, 1);
expect(landed.clips.DayCycleBase_mc.visible === true && landed.clips.OffPlanet_mc.visible === false, "landing during Off restores day true and off-planet false");

const cruiseDuringOff = makeWatchState({ bInSpaceship: true, bIsLanded: false, bIsShipInCruiseMode: false, sLanguage: "" });
applyWatchStyle(cruiseDuringOff, 0);
envCache(cruiseDuringOff, { bInSpaceship: true, bIsLanded: false, bIsShipInCruiseMode: true, sLanguage: "" });
applyWatchStyle(cruiseDuringOff, 1);
expect(cruiseDuringOff.clips.Autopilot_mc.visible === true && cruiseDuringOff.clips.OffPlanet_mc.visible === false, "cruise during Off restores autopilot true and off-planet false");

const jaDuringOff = makeWatchState();
applyWatchStyle(jaDuringOff, 0);
envCache(jaDuringOff, { bInSpaceship: false, bIsLanded: false, bIsShipInCruiseMode: false, sLanguage: "ja" });
applyWatchStyle(jaDuringOff, 1);
expect(jaDuringOff.clips.locationNameBase_mc.visible === false, "ja language during Off restores location hidden");
expect(jaDuringOff.clips.DayCycleBase_mc.visible === true, "ja language does not change planet day vis");

const zhDuringOff = makeWatchState();
applyWatchStyle(zhDuringOff, 0);
envCache(zhDuringOff, { bInSpaceship: false, bIsLanded: false, bIsShipInCruiseMode: false, sLanguage: "zhhans" });
applyWatchStyle(zhDuringOff, 1);
expect(zhDuringOff.clips.locationNameBase_mc.visible === false, "zhhans language during Off restores location hidden");

const oneTwo = makeWatchState();
applyWatchStyle(oneTwo, 0);
applyWatchStyle(oneTwo, 1);
tintRgb(oneTwo.clips.O2CO2thin_mc, 0.55);
expect(oneTwo.clips.O2CO2thin_mc.alpha === 0, "style 2 tint leaves native thin-bar alpha 0");
expect(oneTwo.clips.Temperature_mc.alpha === 0, "style 2 does not force INFO alpha");
applyWatchStyle(oneTwo, 2);
tintRgb(oneTwo.clips.O2CO2thin_mc, 0.55);
applyWatchStyle(oneTwo, 1);
tintClear(oneTwo.clips.O2CO2thin_mc);
expect(oneTwo.clips.O2CO2thin_mc.alpha === 0, "leaving style 2 does not set thin-bar alpha to 1");
expect(oneTwo.clips.HealthBar_mc.visible === false, "health stays hidden through color style");

const digitalRound = makeWatchState();
applyWatchStyle(digitalRound, 0);
applyWatchStyle(digitalRound, 1);
applyWatchStyle(digitalRound, 3);
expect(digitalRound.clips.WatchOutline_mc.visible === false, "Digital hides native chrome");
expect(digitalRound.clips.WatchIconsWidget_mc.visible === true, "Digital keeps location markers");
expect(digitalRound.clips.MissionIconsWidget_mc.visible === true, "Digital keeps mission markers");
expect(digitalRound.clips.EnemyIconsWidget_mc.visible === true, "Digital keeps enemy markers");
expect(digitalRound.clips.O2CO2_mc.x === 21.7 && digitalRound.clips.WatchOutline_mc.x === 0, "Digital does not drag native O2 or outline locals");
expect(digitalRound.clips.instance66.x === 0 && digitalRound.clips.instance66.y === -0.25, "Digital does not drag native cap instance66 locals");
expect(digitalRound.clips.instance66.visible === false, "Digital hides native cap instance66 with chrome");
expect(digitalRound.clips.O2CO2_mc.scaleX === 1 && digitalRound.clips.WatchOutline_mc.scaleX === 1, "Digital does not scale native chrome");
expect(digitalRound.clips.WatchIconsWidget_mc.x === 111.35 + (0 + 132 - 110.5), "Digital moves location markers from the outline center to the Horizon face");
expect(displayed(digitalRound.clips.WatchOutline_mc) === false, "hidden Digital chrome at FadeIn alpha 0 is not displayed");
expect(digitalRound.clips.HealthBar_mc.visible === false, "health stays hidden on Digital");
applyWatchStyle(digitalRound, 1);
expect(digitalRound.clips.WatchOutline_mc.visible === true, "Digital then Vanilla restores the outline");
expect(digitalRound.clips.instance66.visible === true && digitalRound.clips.instance66.x === 0, "Digital then Vanilla restores instance66 vis and native cap local");
expect(digitalRound.clips.WatchIconsWidget_mc.x === 111.35, "Vanilla restores marker locals captured before the custom write");
expect(digitalRound.clips.WatchOutline_mc.visible === true && digitalRound.clips.WatchOutline_mc.alpha === 0, "Vanilla vis undo does not write FadeIn alpha");
expect(displayed(digitalRound.clips.WatchOutline_mc) === false, "Vanilla vis-true does not display native chrome at alpha 0");
expect(digitalRound.clips.DayCycleBase_mc.visible === true && digitalRound.clips.OffPlanet_mc.visible === false, "Digital then Vanilla restores planet day true and off-planet false");
expect(digitalRound.clips.MissionIconsWidget_mc.visible === true, "Digital then Vanilla keeps mission markers");
expect(digitalRound.clips.HealthBar_mc.visible === false && digitalRound.clips.EquippedWeaponAmmo_mc.visible === false, "health and ammo stay hidden after Digital then Vanilla");
expect(digitalRound.clips.JetpackMeterWrapper_mc.visible === false, "boost stays hidden after Digital then Vanilla");

const noCap = makeWatchState();
delete noCap.clips.O2CO2_mc;
applyWatchStyle(noCap, 3);
expect(noCap.vanCap === 0, "missing O2 bar does not latch Arrange capture");
expect(noCap.clips.WatchOutline_mc.visible === false, "custom still hides the native outline when capture has not latched");
expect(noCap.clips.WatchIconsWidget_mc.visible === true && noCap.clips.WatchIconsWidget_mc.x === 111.35, "custom keeps markers at native locals until capture can follow the face");

const f11Live = makeWatchState();
applyWatchStyle(f11Live, 0);
applyWatchStyle(f11Live, 1);
applyWatchStyle(f11Live, 2);
applyWatchStyle(f11Live, 3);
applyWatchStyle(f11Live, 4);
applyWatchStyle(f11Live, 2);
applyWatchStyle(f11Live, 1);
expect(f11Live.clips.WatchOutline_mc.visible === true && f11Live.clips.O2CO2_mc.visible === true, "repeated F11 style cycles still restore the original watch face");
expect(f11Live.clips.DayCycleBase_mc.visible === true && f11Live.clips.Autopilot_mc.visible === false, "repeated F11 cycles restore planet day true and autopilot false");
expect(f11Live.clips.MissionIconsWidget_mc.visible === true && f11Live.clips.EnemyIconsWidget_mc.visible === true, "repeated F11 cycles keep mission and enemy markers on Vanilla");
expect(f11Live.clips.HealthBar_mc.visible === false && f11Live.clips.JetpackMeterWrapper_mc.visible === false, "repeated F11 cycles never restore health or boost");
expect(f11Live.clips.Temperature_mc.alpha === 0 && f11Live.clips.Oxygen_mc.alpha === 0 && f11Live.clips.Grav_mc.alpha === 0, "F11 cycles never force INFO alpha");

const live = makeWatchState();
applyWatchStyle(live, 1);
live.clips.OffPlanet_mc.visible = true;
applyWatchStyle(live, 1);
expect(live.clips.OffPlanet_mc.visible === true, "a later game show during Vanilla is left for the game");
expect(live.clips.HealthBar_mc.visible === false, "a later Vanilla frame does not restore health");
expect(funcBody(as, "hz43ShowVanilla").indexOf("clip.alpha = 1") < 0, "vanilla does not force the thin bar to alpha 1");
expect(checks.indexOf("keep those four clips hidden") < 0, "CHECKS does not keep-hide native info on vanilla");
expect(checks.indexOf("keep those four extra native readout clips hidden") < 0, "CHECKS risks do not keep-hide native info every frame");
expect(checks.indexOf("wait for the next native") < 0 && checks.indexOf("How soon that write repeats") < 0, "CHECKS does not accept missing native events as Off to Vanilla restore");
expect(checks.indexOf("LocalEnvironmentData") >= 0 && checks.indexOf("bIsShipInCruiseMode") >= 0, "CHECKS describes restoring the four vis clips from payload formulas");
expect(checks.indexOf("FadeInPlanetInfo") >= 0, "CHECKS records that INFO appearance is timeline alpha");
expect(checks.indexOf("does not display") >= 0, "CHECKS does not treat INFO vis-true as shown at alpha 0");
expect(checks.indexOf("move only the live marker widgets") >= 0, "CHECKS describes custom marker-only follow");
expect(checks.indexOf("HZ43 dump") >= 0 && checks.indexOf("vis/alpha") >= 0, "CHECKS records vis and alpha sibling dumps");
expect(checks.indexOf("health") >= 0 && checks.indexOf("ammo") >= 0 && checks.indexOf("boost") >= 0, "CHECKS records that health ammo and boost stay off the watch hid list");
expect(checks.indexOf("FadeIn") >= 0 || checks.indexOf("native") >= 0, "CHECKS describes native watch passthrough");
expect(checks.indexOf("not proven freeze") >= 0, "CHECKS reports FadeIn on invisible children as unknown, not a freeze");
expect(checks.indexOf("last observed") < 0 && changelog.indexOf("last observed") < 0, "docs no longer claim sampled clip vis");

function holdPathLive(awAlphaHidden, ancestorAlphaRestored) {
	return ancestorAlphaRestored ? 1 : (awAlphaHidden ? 0 : 1);
}
expect(holdPathLive(true, false) === 0, "an alpha-0 ancestor blocks the hold");
expect(holdPathLive(false, true) === 1, "restored ancestors keep the hold live");

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
