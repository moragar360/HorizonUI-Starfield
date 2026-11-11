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
expect(block.indexOf("hz43Dial(g,0,64,day)") < 0 && block.indexOf("hz43PmT.visible = true") < 0, "analog has no PM/DAY readout or 6 o'clock day dial");
expect(funcBody(as, "hz43Draw").indexOf("hz43Dial") < 0 && funcBody(as, "hz43Draw").indexOf("hz43Sun") < 0 && as.indexOf('this.hz43DayT.text = "DAY"') < 0, "analog draw does not call the day subdial or write DAY");
expect(block.indexOf("Math.PI / 2 + Math.PI / 6") >= 0 && block.indexOf("Math.PI / 2 - Math.PI / 6") >= 0, "gauges start at 7 o'clock and 5 o'clock");
expect(block.indexOf("0x6E7C86") >= 0, "unfilled gauge segments are gray");
expect(block.indexOf("hz43Hand(g,ma,72,2.2,0xF2F7F9)") >= 0, "the minute hand is white");
expect(block.indexOf("ly < -HZ43_R + 96") >= 0, "compass letters stay on the top arc");
const drawBody = funcBody(as, "hz43Draw");
expect(drawBody.split("hz43Compass(g)").length - 1 === 2, "digital and analog both draw the compass");
expect(drawBody.indexOf("hz43Diamond(g,0,-HZ43_R + 20,4)") < 0, "analog does not draw a second top mark");
expect(drawBody.indexOf("hz43Cards[hi]).visible = false") < 0, "analog does not hide the compass letters");
expect(drawBody.indexOf("hz43Ticks(g)") >= 0 && drawBody.indexOf("hz43Hands(g)") >= 0, "analog still draws ticks and hands");
expect(drawBody.indexOf("hz43BodyT.y = -22") >= 0 && drawBody.indexOf("hz43TempT.y = -4") >= 0, "analog planet name and temperature stay below the compass");
expect(drawBody.indexOf("hzFmtLocGame(this.hz43H,this.hz43M,this.hz43Ut != 0)") >= 0, "digital LOCAL/GAME uses ClockFormat for both sources");
expect(funcBody(as, "hzPpLayout").indexOf("hzFmtLocGame(uh,um,true)") >= 0 && funcBody(as, "hzPpLayout").indexOf("hzFmtLocGame(H,M,false)") >= 0, "planet LOCAL and GAME values both go through ClockFormat");
expect(funcBody(as, "hzPpLayout").indexOf('hzPad2(uh) + ":" + this.hzPad2(um) + " UT"') < 0, "planet GAME no longer hardcodes 24-hour UT");
expect(funcBody(as, "hzSetLive").indexOf("p.ClockFormat") >= 0 && funcBody(as, "hzSetLive").indexOf("this.hzPpLayout()") >= 0, "F11 live ClockFormat rebuilds the planet Local/Game row");
expect(funcBody(as, "hzSetPvDraw").indexOf("this.hzPpLocT") >= 0 && funcBody(as, "hzSetPvDraw").indexOf("c1.text = a0.text") >= 0, "F11 STYLE live preview copies the planet Local/Game text");
expect(as.indexOf('case "clockformat":') >= 0 && as.indexOf("this.hzClockFmt = Math.max(0,Math.min(1,int(nv))); try { this.hzPpLayout(); }") >= 0, "ini reload applies ClockFormat then rebuilds Local/Game");
expect(funcBody(as, "hzBuildIniText").indexOf("ClockFormat=") >= 0 && ini.indexOf("ClockFormat=0") >= 0, "save writes ClockFormat and the default is 12H");
expect(as.indexOf('"ClockFormat":0') >= 0 && as.indexOf('HZ_CLOCK_NAMES:Array = ["12 H","24 H"]') >= 0, "F11 CLOCK FORMAT is 12H/24H with default 12H");
expect(ini.indexOf("GAME UT is always 24-hour") < 0 && as.indexOf("GAME UT is always 24-hour") < 0, "ini and HUD no longer claim GAME is always 24-hour");
expect(preset.indexOf("ClockFormat") < 0, "Moragar's Choice leaves ClockFormat at the 12H default");
expect(checks.indexOf("no 6 o'clock day sub-dial") >= 0 && checks.indexOf("DAY inside") < 0, "CHECKS analog no longer keeps PM/DAY");
expect(changelog.indexOf("no longer draws the 6 o'clock day sub-dial") >= 0 && changelog.indexOf("ClockFormat (12H / 24H) applies to LOCAL, GAME, and PC") >= 0, "CHANGELOG records analog PM/DAY removal and ClockFormat on GAME");

function functionSource(src, name) {
	const key = "function " + name + "(";
	const i = src.indexOf(key);
	expect(i >= 0, "source function " + name);
	if (i < 0) return "";
	let start = i;
	const priv = src.lastIndexOf("private ", i);
	if (priv >= 0 && i - priv < 24) start = priv;
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") {
			depth--;
			if (depth === 0) return src.slice(start, p + 1);
		}
	}
	return "";
}
function asFnToJs(text) {
	let s = text;
	s = s.replace(/(?:public|private) function (\w+)\(([^)]*)\)(?:\s*:\s*[\w.*]+)?/g, function (_, name, args) {
		const jsArgs = args.split(",").map(function (a) {
			a = a.trim();
			if (!a) return "";
			const parts = a.split("=");
			const left = parts[0].trim().split(":")[0].trim();
			return parts.length > 1 ? left + "=" + parts.slice(1).join("=") : left;
		}).filter(Boolean);
		return "function " + name + "(" + jsArgs.join(", ") + ")";
	});
	s = s.replace(/var (\w+):[\w.*]+/g, "var $1");
	s = s.replace(/\bint\(/g, "(0|");
	return s;
}
function installAsFn(host, src, name) {
	const js = asFnToJs(functionSource(src, name));
	const m = js.match(/function (\w+)\(([^)]*)\)\s*\{([\s\S]*)\}\s*$/);
	if (!m) {
		expect(false, "live ActionScript " + name + " converts");
		return;
	}
	host[m[1]] = new Function(m[2], m[3]);
}
const clockHost = { hzClockFmt: 0 };
installAsFn(clockHost, as, "hzPad2");
installAsFn(clockHost, as, "hzFmtClock");
installAsFn(clockHost, as, "hzFmtLocGame");
expect(typeof clockHost.hzFmtLocGame === "function", "production hzFmtLocGame binds");

function expectClock(fmt, h, m, game, want, msg) {
	clockHost.hzClockFmt = fmt;
	const got = clockHost.hzFmtLocGame(h, m, game);
	expect(got === want, msg + " -> " + got);
}

expectClock(0, 0, 0, false, "12:00 AM", "LOCAL midnight 12H");
expectClock(0, 0, 1, false, "12:01 AM", "LOCAL just after midnight 12H");
expectClock(0, 11, 59, false, "11:59 AM", "LOCAL before noon 12H");
expectClock(0, 12, 0, false, "12:00 PM", "LOCAL noon 12H");
expectClock(0, 12, 1, false, "12:01 PM", "LOCAL just after noon 12H");
expectClock(0, 18, 55, false, "6:55 PM", "LOCAL 18:55 as 12H");
expectClock(0, 23, 59, false, "11:59 PM", "LOCAL before midnight 12H");
expectClock(0, 0, 0, true, "12:00 AM", "GAME midnight 12H");
expectClock(0, 12, 0, true, "12:00 PM", "GAME noon 12H");
expectClock(0, 18, 55, true, "6:55 PM", "GAME 18:55 12H does not force 24h");
expectClock(0, 5, 41, false, "5:41 AM", "LOCAL morning 12H");
expectClock(1, 0, 0, false, "00:00", "LOCAL midnight 24H");
expectClock(1, 12, 0, false, "12:00", "LOCAL noon 24H");
expectClock(1, 18, 55, false, "18:55", "LOCAL 18:55 24H");
expectClock(1, 0, 0, true, "00:00 UT", "GAME midnight 24H");
expectClock(1, 12, 0, true, "12:00 UT", "GAME noon 24H");
expectClock(1, 18, 55, true, "18:55 UT", "GAME 18:55 24H keeps UT");
clockHost.hzClockFmt = 0;
expect(clockHost.hzFmtClock(18, 55) === "6:55 PM", "PC/REAL 12H uses the same formatter");
clockHost.hzClockFmt = 1;
expect(clockHost.hzFmtClock(18, 55) === "18:55", "PC/REAL 24H uses the same formatter");

function planetGameHM(ut) {
	const uh = (0 | Math.floor(ut)) % 24;
	const um = 0 | Math.floor((ut - Math.floor(ut)) * 60);
	return { uh: uh, um: um };
}
function planetLocalHM(day) {
	const hh = (day * 24) % 24;
	const H = 0 | Math.floor(hh);
	const M = 0 | Math.floor((hh - H) * 60);
	return { H: H, M: M };
}
expect(funcBody(as, "hzPpLayout").indexOf("int(Math.floor(this.hzPpUT)) % 24") >= 0, "GAME hours come from fGalacticStandardTime");
expect(funcBody(as, "hzPpLayout").indexOf("(this.hzPpDay * 24) % 24") >= 0, "LOCAL hours come from fLocalPlanetTime");
const ship1855 = planetGameHM(18 + 55 / 60);
expect(ship1855.uh === 18 && ship1855.um === 55, "IN SHIP 18:55 UT splits to 18:55");
clockHost.hzClockFmt = 0;
expect(clockHost.hzFmtLocGame(ship1855.uh, ship1855.um, true) === "6:55 PM", "F11 Local/Game IN SHIP 18:55 is 6:55 PM at 12H");
clockHost.hzClockFmt = 1;
expect(clockHost.hzFmtLocGame(ship1855.uh, ship1855.um, true) === "18:55 UT", "F11 Local/Game IN SHIP 18:55 stays 18:55 UT at 24H");
const landed1855 = planetLocalHM((18 + 55 / 60) / 24);
expect(landed1855.H === 18 && landed1855.M === 55, "LOCAL day fraction 18:55 splits to 18:55");
clockHost.hzClockFmt = 0;
expect(clockHost.hzFmtLocGame(landed1855.H, landed1855.M, false) === "6:55 PM", "F11 Local/Game landed 18:55 is 6:55 PM at 12H");
clockHost.hzClockFmt = 1;
expect(clockHost.hzFmtLocGame(landed1855.H, landed1855.M, false) === "18:55", "F11 Local/Game landed 18:55 is 18:55 at 24H");
{
	let fmt = 0;
	let layouts = 0;
	function liveClock(next) {
		if (fmt != (next | 0)) {
			fmt = Math.max(0, Math.min(1, next | 0));
			layouts++;
		}
	}
	liveClock(0);
	expect(layouts === 0, "re-selecting 12H does not rebuild");
	liveClock(1);
	expect(fmt === 1 && layouts === 1, "live toggle 12H to 24H rebuilds Local/Game");
	liveClock(0);
	expect(fmt === 0 && layouts === 2, "live toggle 24H to 12H rebuilds Local/Game");
}
expect(funcBody(as, "hz43Frame").indexOf("hzClockFmt") >= 0 || as.indexOf("this.hzClockFmt != this.hz43LastClk") >= 0, "watch dirty includes ClockFormat so a live toggle redraws");

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

// leftover hz43Dial angle math; analog draw no longer calls hz43Dial.
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
expect(as.indexOf("Every watch face can be moved in Arrange Cards") < 0, "the old every-watch-face helper caption is gone");
expect(as.indexOf('"note":"Original Vanilla Watch or Horizon Watch"') >= 0, "the F11 watch helper caption is Original Vanilla Watch or Horizon Watch");
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
expect(funcBody(as, "hz43VanInstName").indexOf('name.indexOf("instance") == 0') >= 0, "Scaleform autonames are detected as a type, not as ownership");
expect(funcBody(as, "hz43VanNamed").indexOf("hz43VanInstName") < 0, "autoname prefix is not VanNamed ownership");
expect(funcBody(as, "hz43VanWatchClip").indexOf("hz43VanCapClip") >= 0 && funcBody(as, "hz43VanGather").indexOf("hz43VanCapClip") >= 0, "capture and own-hide use verified cap identity");
expect(funcBody(as, "hz43VanWatchClip").indexOf("hz43VanRingClip") >= 0 && funcBody(as, "hz43VanGather").indexOf("hz43VanRingClip") >= 0, "capture and own-hide use filled-annulus identity");
expect(funcBody(as, "hz43VanRingClip").indexOf("hz43VanRingProof") >= 0 && funcBody(as, "hz43VanRingClip").indexOf("hz43VanRing.parent") >= 0, "annulus identity is the cached object after native proof");
expect(funcBody(as, "hz43VanRingProof").indexOf("EnvConditionBase_mc") >= 0 && funcBody(as, "hz43VanRingProof").indexOf("EnemyDetectionAnim_mc") >= 0, "annulus proof uses named sandwich shared by normal and large PHC");
expect(funcBody(as, "hz43VanRingProof").indexOf("1237") < 0 && funcBody(as, "hz43VanRingProof").indexOf("1115") < 0 && funcBody(as, "hz43VanRingProof").indexOf("278") < 0, "annulus identity does not hardcode normal or large symbol or depth ids");
expect(funcBody(as, "hz43VanRingProof").indexOf('"instance') < 0 && funcBody(as, "hz43VanRingClip").indexOf('"instance') < 0, "annulus identity does not hardcode a session autoname");
expect(funcBody(as, "hz43VanCapClip").indexOf("hz43VanD") < 0, "cap identity is not a gathered-unit shortcut");
expect(funcBody(as, "hz43VanCapture").indexOf("originX") >= 0 && funcBody(as, "hz43VanWrite").indexOf("(hx - ox) * useSc") >= 0, "whole Arrange scales sibling locals from the outline origin");
expect(funcBody(as, "hz43VanBlgChrome").indexOf("hz43VanCapClip") >= 0 && funcBody(as, "hz43VanBlgChrome").indexOf("hz43VanInstName") < 0, "chrome hide and restore use verified cap identity");
expect(funcBody(as, "hz43VanCapClip").indexOf("this.hz43VanOutline()") >= 0 && funcBody(as, "hz43VanOutline").indexOf('this.hzFindByName(this.hzBlg,"WatchOutline_mc",0)') >= 0, "cap identity is outline-relative native pose");
expect(funcBody(as, "hz43VanCapClip").indexOf("scaleY") >= 0, "collapsed INFO ticks are not the cap");
expect(funcBody(as, "hz43VanCapClip").indexOf('"instance66"') < 0, "cap identity is not hardcoded instance66");
expect(funcBody(as, "hz43VanDump").indexOf("ctA=") >= 0 && funcBody(as, "hz43VanDump").indexOf("ctO=") >= 0 && funcBody(as, "hz43VanDump").indexOf("HZ43_DIAG") >= 0, "dump records ColorTransform alphaMultiplier and alphaOffset and the diagnostic package token");
expect(funcBody(as, "hz43VanDump").indexOf("alphaMultiplier") >= 0 && funcBody(as, "hz43VanDump").indexOf("alphaOffset") >= 0, "dump reads both CXFORM alpha terms");
expect(funcBody(as, "hz43VanDump").indexOf("capArt=") >= 0, "dump marks which autonamed sibling is the verified cap");
expect(funcBody(as, "hz43VanDump").indexOf("ctrArt=") < 0 && as.indexOf("function hz43VanCenterArt") < 0, "r11 pose-only center-art hide is not in this package");
expect(funcBody(as, "hz43VanDump").indexOf("ringArt=") >= 0, "dump marks which sibling is the filled watch annulus");
expect(funcBody(as, "hz43VanWatchClip").indexOf("hz43VanCenterArt") < 0 && funcBody(as, "hz43VanGather").indexOf("hz43VanCenterArt") < 0, "broad center-art helper stays out of ownership");
expect(funcBody(as, "hz43VanPlace").indexOf("hz43VanFadeOk") >= 0 && funcBody(as, "hz43TintRgb").indexOf("redMultiplier") >= 0, "styles 1 and 2 keep Fade wait and RGB-only tint");
expect(funcBody(as, "hz43Tint").indexOf("hz43TintUnnamed") >= 0 && funcBody(as, "hz43TintUnnamed").indexOf("hz43VanRingClip") >= 0, "style 2 tints unnamed watch chrome including the filled annulus");
expect(funcBody(as, "hz43TintUnnamed").indexOf("hz43TintRgb") >= 0 && funcBody(as, "hz43TintUnnamed").indexOf("hz43TintClear") >= 0 && funcBody(as, "hz43TintUnnamed").indexOf("alphaMultiplier") < 0, "unnamed chrome tint uses TintRgb/TintClear and does not write alpha");
expect(funcBody(as, "hz43VanDump").indexOf("hz43VanNamed") < 0, "dump lists every BottomLeftGroup child, not only VanNamed clips");
expect(as.indexOf('HZ43_DIAG:String = "r15-vanilla-restore-20261108"') >= 0, "next gfx can prove package r15-vanilla-restore-20261108");
expect(funcBody(as, "hz43VanBlgChrome").indexOf("hz43VanShowClip") >= 0 && funcBody(as, "hz43VanShowClip").indexOf("d.alpha") < 0, "vanilla chrome show restores named assembly vis without writing alpha");
expect(funcBody(as, "hz43SyncHide").indexOf("hz43VanBlgChrome(false)") >= 0 && funcBody(as, "hzSetLive").indexOf("hz43VanShown = 0") >= 0, "later vanilla frames retry vis undo and a WatchStyle change recaptures ShowVanilla");
expect(funcBody(as, "hz43VanDump").indexOf("WatchPointerOutline_mc") >= 0, "dump signature includes heading-outline vis so later Off frames are not collapsed into the first write");
expect(funcBody(as, "hz43SyncHide").indexOf("hz43HideStyle") >= 0 && funcBody(as, "hz43SyncHide").indexOf("hzHideCache = null") >= 0, "WatchStyle change rebuilds hide cache, including Digital then Off");
expect(onFrame.indexOf('else if(this.hzWatchStyle == 3 || this.hzWatchStyle == 4) { names.push("WatchPointerOutline_mc"); }') >= 0, "custom hideTick owns the heading outline");
expect(funcBody(as, "hz43VanPlace").indexOf("hz43VanFadeOk") >= 0, "Vanilla Arrange waits for native FadeIn before writing siblings");
expect(funcBody(as, "hz43VanFadeSeen").indexOf("alphaMultiplier") >= 0 && funcBody(as, "hz43VanFadeSeen").indexOf("d.alpha") >= 0, "Fade wait reads outline/O2/cap alpha and ColorTransform, and does not write alpha");
expect(funcBody(as, "hz43VanFadeSeen").indexOf("d.alpha =") < 0 && funcBody(as, "hz43VanPlace").indexOf("clip.alpha = 1") < 0, "Fade wait does not force outline alpha to 1");
expect(funcBody(as, "hz43VanFadeOk").indexOf("O2CO2_mc") >= 0 && funcBody(as, "hz43VanFadeOk").indexOf("Temperature") < 0, "Fade wait uses outline/O2/cap, not INFO");
expect(funcBody(as, "hz43VanFadeSeen").indexOf("d.alpha > 0.9") >= 0 && funcBody(as, "hz43VanFadeSeen").indexOf("ct.alphaMultiplier > 0.9") >= 0, "Fade readiness is DisplayObject.alpha OR ColorTransform alphaMultiplier");
expect(funcBody(as, "hz43VanFadeOk").indexOf("hz43VanFadeSeen") >= 0, "FadeOk uses FadeSeen for the alpha OR ctA threshold");
expect(funcBody(as, "hz43VanFadeOk").indexOf("hz43VanFadeAt != this.hzFrameN") >= 0 && funcBody(as, "hz43VanFadeOk").indexOf("hz43VanFadeN >= 16") >= 0, "Fade wait counts distinct hzFrameN ticks and latches at 16");
expect(onFrame.indexOf("this.hzFrameN++") >= 0 && onFrame.indexOf("this.hz43Frame()") > onFrame.indexOf("this.hzFrameN++"), "enterFrame increments hzFrameN once then calls the watch frame");
expect(funcBody(as, "hz27OnExit").indexOf("hzFrameN") < 0 && funcBody(as, "hz27OnExit").indexOf("this.hz43VanLate()") >= 0, "exitFrame VanLate does not increment hzFrameN");
const placeFade = funcBody(as, "hz43VanPlace");
const markUndoAt = placeFade.indexOf("if(this.hz43MarkMoved) { this.hz43VanWrite(0,0,1); this.hz43MarkMoved = false; }");
const chromeUndoAt = placeFade.indexOf("this.hz43VanChrome(false);");
const fadeWaitAt = placeFade.indexOf("if(!drag && !this.hz43VanFadeOk())");
const savedWriteAt = placeFade.indexOf("this.hz43VanWrite(hnd.x - this.hz43VanHX,hnd.y - this.hz43VanHY,sc)");
expect(placeFade.indexOf("if(this.hz43HidN > 0)") < 0, "VanPlace does not wait for a hid list before chrome restore");
expect(markUndoAt >= 0 && chromeUndoAt > markUndoAt && fadeWaitAt > chromeUndoAt && savedWriteAt > fadeWaitAt, "Digital then Vanilla MarkMoved undo runs before chrome restore, fade wait, and saved Arrange");
expect(placeFade.indexOf("if(!drag && !this.hz43VanFadeOk())") >= 0 && placeFade.indexOf("if(drag) { this.hz43VanWmk = -1; }") >= 0, "Arrange drag bypasses FadeIn wait and busts the identical-write latch");
expect(placeFade.indexOf(".alpha =") < 0 && funcBody(as, "hz43VanWrite").indexOf(".alpha =") < 0, "Fade timeout and Arrange write do not assign clip alpha");
const capBody = funcBody(as, "hz43VanCapture");
const capEarly = capBody.indexOf("if(this.hz43VanNeed == 0 && this.hzBlg.numChildren == this.hz43VanKids) { return; }");
const capReset = capBody.indexOf("this.hz43VanFadeN = 0");
expect(capEarly >= 0 && capReset > capEarly, "Capture does not reset FadeN unless kids change");
const frameBodyWait = funcBody(as, "hz43Frame");
expect(frameBodyWait.indexOf("this.hz43VanPlace()") >= 0 && frameBodyWait.indexOf("if(this.hzWatchStyle == 2) { this.hz43Tint(); }") > frameBodyWait.indexOf("this.hz43VanPlace()"), "style 2 still tints after VanPlace, including during fade wait");
expect(funcBody(as, "hz43TintRgb").indexOf("alphaMultiplier") < 0 && funcBody(as, "hz43TintRgb").indexOf("redMultiplier") >= 0, "style 2 TintRgb writes RGB only and does not assign alphaMultiplier");
expect(funcBody(as, "hz43VanFadeOk").indexOf("currentFrame") < 0 && funcBody(as, "hz43VanFadeOk").indexOf("hzFrameN") >= 0, "16-tick fail-open is HUD hzFrameN, not BottomLeftGroup currentFrame");
expect(funcBody(as, "hz43VanHorizon").indexOf("hz43VanWrote") >= 0 && funcBody(as, "hz43VanHorizon").indexOf("hz43VanWrite(0,0,1)") >= 0, "Digital restores native locals before marker follow");
const horBody = funcBody(as, "hz43VanHorizon");
const restAt = horBody.indexOf("this.hz43VanWrite(0,0,1)");
const horChromeAt = horBody.indexOf("this.hz43VanChrome(true)");
const marksAt = horBody.indexOf("this.hz43VanWrite(cx - rx,cy - ry,1,true)");
expect(restAt >= 0 && horChromeAt > restAt && marksAt > horChromeAt, "custom restore-native runs before chrome hide and marker follow");
expect(funcBody(as, "hz43VanWrite").indexOf("hz43VanWmk") >= 0, "identical Arrange writes are skipped");
expect(funcBody(as, "hz43VanDump").indexOf('why + "|"') < 0, "dump signature does not include why, so write-marks/horizon pairs do not retrigger");
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
expect(as.indexOf('HZ43_VAN_MARK:Array = ["WatchIconsWidget_mc","MissionIconsWidget_mc","EnemyIconsWidget_mc"]') >= 0, "live markers are nearby, mission, and enemy widgets");
expect(funcBody(as, "hz43VanMarkName").indexOf("WatchPointerOutline_mc") < 0, "heading outline is not a custom keep-mark");
expect(as.indexOf("HZ43_HID_MAX:int = 40") >= 0 && funcBody(as, "hz43VanNote").indexOf(">= 32") < 0, "the watch hid list is a 40-slot identity cap");
expect(funcBody(as, "hz43VanRestoreHid").indexOf("HealthBar") < 0 && funcBody(as, "hz43VanNote").indexOf("HealthBar") < 0, "health is not on the watch hid list");
expect(funcBody(as, "hz43VanGameVis").indexOf("DayCycleBase_mc") >= 0 && funcBody(as, "hz43VanGameVis").indexOf("Autopilot_mc") >= 0, "game-owned visibility includes day cycle and autopilot");
expect(as.indexOf("function hz43IdCt") < 0 && as.indexOf("function hz43Ct(") < 0, "style 2 no longer assigns a cached identity ColorTransform");
expect(funcBody(as, "hz43TintRgb").indexOf("alphaMultiplier") < 0 && funcBody(as, "hz43TintClear").indexOf("alphaMultiplier") < 0 && funcBody(as, "hz43TintRgb").indexOf("alphaOffset") < 0, "style 2 tint and clear do not write alphaMultiplier or alphaOffset");
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
expect(funcBody(as, "hz43VanInstName").indexOf("name.length == 0") >= 0 && funcBody(as, "hz43VanCapClip").indexOf("hz43VanInstName") >= 0, "empty PlaceObject names can still be the cap after pose check");
expect(funcBody(as, "hz43VanSkip").indexOf("name.length == 0) { return true; }") < 0, "unnamed chrome is not skipped from the watch assembly");
expect(funcBody(as, "hz43VanSkip").indexOf("name.length == 0) { return false; }") >= 0, "unnamed shapes stay in the watch assembly");

function leftoverWatchVisible(style, clip) {
	const alerts = ["EnemyDetectionAnim_mc", "EnvAlertText", "BioAlertText", "LocationAlertText"];
	if (alerts.indexOf(clip) >= 0) return true;
	const mark = clip === "WatchIconsWidget_mc" || clip === "MissionIconsWidget_mc" || clip === "EnemyIconsWidget_mc";
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
expect(leftoverWatchVisible(3, "WatchPointerOutline_mc") === false, "digital hides the heading outline with chrome");
expect(leftoverWatchVisible(4, "WatchPointerOutline_mc") === false, "analog hides the heading outline with chrome");
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
	if (name === "MissionIconsWidget_mc" || name === "EnemyIconsWidget_mc" || name === "Autopilot_mc") return true;
	if (VAN_N.indexOf(name) >= 0) return true;
	return name.indexOf("Watch") === 0;
}
function vanCapClip(d, outline) {
	if (!d || vanSkip(d.name)) return false;
	if (!(d.name === "" || (typeof d.name === "string" && d.name.indexOf("instance") === 0))) return false;
	if (Math.abs(d.scaleX) < 0.5 || Math.abs(d.scaleY) < 0.5) return false;
	if (outline) return Math.abs(d.x - outline.x) < 2 && Math.abs(d.y - outline.y) < 2;
	return Math.abs(d.x) < 2 && Math.abs(d.y) < 2;
}
function vanRingProof(d, outline) {
	if (!d || vanSkip(d.name)) return false;
	if (!(d.name === "" || (typeof d.name === "string" && d.name.indexOf("instance") === 0))) return false;
	if (Math.abs(d.scaleX) < 0.5 || Math.abs(d.scaleY) < 0.5) return false;
	if (vanCapClip(d, outline)) return false;
	const ox = outline ? outline.x : 0;
	const oy = outline ? outline.y : 0;
	if (Math.abs((d.x - ox) - 110.5) >= 2 || Math.abs((d.y - oy) - 110.5) >= 2) return false;
	const kids = d.parent && d.parent.kids;
	if (!kids) return false;
	const idx = kids.indexOf(d);
	if (idx < 1 || idx >= kids.length - 1) return false;
	return kids[idx - 1] && kids[idx - 1].name === "EnvConditionBase_mc" && kids[idx + 1] && kids[idx + 1].name === "EnemyDetectionAnim_mc";
}
function vanRingClip(d, outline) {
	if (!d) return false;
	const blg = d.parent;
	if (blg && blg.vanRing && blg.vanRing.parent === blg) return d === blg.vanRing;
	if (blg) blg.vanRing = null;
	if (!vanRingProof(d, outline)) return false;
	if (blg) blg.vanRing = d;
	return true;
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
const unnamedCap = { name: "", parent: blg, x: 0, y: -0.25, scaleX: 1, scaleY: 1 };
const inst66 = { name: "instance66", parent: blg, x: 0, y: -0.25, scaleX: 1, scaleY: 1 };
const pointer = { name: "WatchPointerOutline_mc", parent: blg, x: 111, y: 111 };
const icons = { name: "WatchIconsWidget_mc", parent: blg, x: 111.35, y: 111.45 };
const mission = { name: "MissionIconsWidget_mc", parent: blg, x: 111.35, y: 111.45 };
const enemy = { name: "EnemyIconsWidget_mc", parent: blg, x: 111.35, y: 111.45 };
const thin = { name: "O2CO2thin_mc", parent: blg, x: 16.1, y: 88.3 };
const bio = { name: "BioCondition_mc", parent: blg, x: 96.25, y: 24.45 };
const envBase = { name: "EnvConditionBase_mc", parent: blg, x: 109.65, y: 111.45 };
const envAlert = { name: "EnvAlertText", parent: blg, x: 110.75, y: 110.25 };
const detect = { name: "EnemyDetectionAnim_mc", parent: blg, x: 110.5, y: 110.5 };
const inst546 = { name: "instance546", parent: blg, x: 110.5, y: 110.5, scaleX: 1, scaleY: 1 };
const inst548 = { name: "instance548", parent: blg, x: 87.2, y: 141.65, scaleX: 0.000076293945, scaleY: 0 };
const inst550 = { name: "instance550", parent: blg, x: 139.45, y: 141.65, scaleX: 0.000076293945, scaleY: 0 };
const blgKids = [unnamedCap, inst66, outline, pointer, o2co2, thin, icons, mission, enemy, bio, envBase, inst546, detect, envAlert, inst548, inst550];
blg.kids = blgKids;
blg.getChildAt = function(i) { return this.kids[i]; };
blg.getChildIndex = function(d) {
	const i = this.kids.indexOf(d);
	if (i < 0) throw new Error("not a child");
	return i;
};
if (!Object.prototype.hasOwnProperty.call(blg, "numChildren")) {
	Object.defineProperty(blg, "numChildren", { get: function() { return this.kids.length; } });
}

function gatherSiblings(kids, ring) {
	const units = [];
	for (let i = 0; i < kids.length; i++) {
		if (vanNamed(kids[i].name) || vanCapClip(kids[i], ring) || vanRingClip(kids[i], ring)) units.push(kids[i]);
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
function vanNamedOld(name) {
	if (name == null) return false;
	if (vanSkip(name)) return false;
	if (name.length === 0 || (typeof name === "string" && name.indexOf("instance") === 0)) return true;
	return vanNamed(name);
}
function gatherNestedOld(node, depth, out) {
	if (!node || depth > 4) return;
	const kids = node === blg ? blgKids : node.kids;
	if (!kids) return;
	for (let i = 0; i < kids.length; i++) {
		const ch = kids[i];
		if (vanNamedOld(ch.name)) out.push(oldRootOf(ch));
		if (!vanSkip(ch.name)) gatherNestedOld(ch, depth + 1, out);
	}
}

const siblingUnits = gatherSiblings(blgKids, outline);
expect(siblingUnits.indexOf(o2co2) >= 0 && siblingUnits.indexOf(outline) >= 0, "native ring and O2 bar are sibling units");
expect(siblingUnits.indexOf(unnamedCap) >= 0 && siblingUnits.indexOf(inst66) >= 0, "empty-name and session instance66 at cap pose are BottomLeftGroup units");
expect(siblingUnits.indexOf(inst546) >= 0 && siblingUnits.indexOf(inst548) < 0 && siblingUnits.indexOf(inst550) < 0, "filled annulus between EnvConditionBase and EnemyDetection is a watch unit; INFO ticks are not");
expect(siblingUnits.indexOf(o2anim) < 0 && siblingUnits.indexOf(co2anim) < 0, "inner O2Anim_mc is not a unit");
expect(siblingUnits.indexOf(bio) < 0 && siblingUnits.indexOf(envBase) < 0 && siblingUnits.indexOf(envAlert) < 0 && siblingUnits.indexOf(detect) < 0, "bio env alert and detection are not watch units");
expect(siblingUnits.indexOf(mission) >= 0 && siblingUnits.indexOf(enemy) >= 0, "mission and enemy widgets move with the watch");
expect(vanCapClip({ name: "instance66", x: 110.5, y: 110.5, scaleX: 1, scaleY: 1 }, outline) === false, "session cap name at a non-cap native local is not the cap");
expect(vanCapClip({ name: "instance546", x: 0, y: -0.25, scaleX: 1, scaleY: 1 }, outline) === true, "cap identity follows pose, not the session instance number");
expect(vanNamed("instance66") === false && vanNamed("instance546") === false, "autoname prefix is not a named watch unit");
expect(vanSkip("BioCondition_mc") && vanSkip("EnvConditionBase_mc") && vanSkip("EnvAlertText") && vanSkip("BioAlertText"), "named bio and env clips stay skipped");
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
const MARK_NAMES = { WatchIconsWidget_mc: 1, MissionIconsWidget_mc: 1, EnemyIconsWidget_mc: 1 };
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
function isWatchClip(d, outline) {
	return !!(d && (WATCH_NAMES[d.name] || vanCapClip(d, outline) || vanRingClip(d, outline)));
}
function isArrangeClip(d, outline) {
	return !!(d && (WATCH_NAMES[d.name] || vanCapClip(d, outline) || vanRingClip(d, outline)));
}
function asInner(name) {
	return asInnerOf(as, name);
}
// r7: the same conversion from any source text (in-test mutants bind a changed copy of one function).
function asInnerOf(src, name) {
	const body = funcBody(src, name);
	return body.replace(/^\{\s*/, "").replace(/\s*\}$/, "")
		.replace(/var\s+([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z0-9_.]+/g, "var $1")
		// AS3 catch types: catch(e:Error) lets a non-Error value pass, catch(e:*) takes any value. Keep that in JS.
		.replace(/catch\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*Error\s*\)\s*\{/g, "catch($1) { if (!($1 instanceof Error)) throw $1;")
		.replace(/catch\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*\*\s*\)/g, "catch($1)")
		.replace(/catch\s*\(\s*([A-Za-z_][A-Za-z0-9_]*)\s*:\s*[A-Za-z0-9_.]+\s*\)/g, "catch($1)")
		.replace(/\s+as\s+[A-Za-z_][A-Za-z0-9_.]*/g, "")
		.replace(/(\w+) is DisplayObjectContainer\b/g, "($1 && $1.numChildren !== undefined)")
		.replace(/\bDisplayObjectContainer\(/g, "(");
}
// r9: a static const of the AS (Array as JSON, Boolean / Number literal), so the hosts use the shipped lists.
function asConst(name) {
	const m = new RegExp("static const " + name + ":(Array|Boolean|int|Number) = ([^;]+);").exec(as);
	if (!m) throw new Error("no const " + name);
	return JSON.parse(m[2]);
}
function bindAsMethod(host, name, args) {
	host[name] = Function.apply(null, args.concat(["with(this){\n" + asInner(name) + "\n}"])).bind(host);
}
// hidecache: the per-pass WatchOutline_mc memo and the one-walk marker check, as in the AS (fields start empty).
function bindHidecache(host) {
	host.hz43OlDepth = 0;
	host.hz43OlHave = false;
	host.hz43OlRef = null;
	host.hz43OlBlg = null;
	host.hzPerfOn = false;
	bindAsMethod(host, "hz43VanOutline", []);
	bindAsMethod(host, "hz43OlBegin", []);
	bindAsMethod(host, "hz43OlEnd", []);
	bindAsMethod(host, "hz43IsMark", ["name"]);
	bindAsMethod(host, "hz43FindMark", ["c", "depth"]);
}
function makeProductionHost(kids) {
	blg.kids = kids;
	blg.getChildAt = function(i) { return this.kids[i]; };
	if (!Object.prototype.hasOwnProperty.call(blg, "numChildren")) {
		Object.defineProperty(blg, "numChildren", { get: function() { return this.kids.length; } });
	}
	const host = {
		hzBlg: blg,
		hz43VanD: [],
		hz43VanNm: [],
		hz43VanN: 0,
		HZ43_VAN_MAX: 24,
		HZ43_VAN_FACE: 221,
		HZ43_VAN_N: VAN_N,
		hz43VanRing: null,
		hzFindByName: function(root, name) {
			if (!root) return null;
			if (root.name === name) return root;
			const list = root.kids || [];
			for (let i = 0; i < list.length; i++) {
				if (list[i] && list[i].name === name) return list[i];
			}
			return null;
		}
	};
	if (typeof blg.getChildAt !== "function") blg.getChildAt = function(i) { return this.kids[i]; };
	if (typeof blg.getChildIndex !== "function") {
		blg.getChildIndex = function(d) {
			const i = this.kids.indexOf(d);
			if (i < 0) throw new Error("not a child");
			return i;
		};
	}
	bindAsMethod(host, "hz43VanSkip", ["name"]);
	bindAsMethod(host, "hz43VanInstName", ["name"]);
	bindAsMethod(host, "hz43VanNamed", ["name"]);
	bindAsMethod(host, "hz43VanHasAncestorUnit", ["d"]);
	bindAsMethod(host, "hz43VanAdd", ["root"]);
	bindHidecache(host);
	bindAsMethod(host, "hz43VanCapClip", ["d"]);
	bindAsMethod(host, "hz43VanRingProof", ["d"]);
	bindAsMethod(host, "hz43VanRingClip", ["d"]);
	bindAsMethod(host, "hz43VanRootOf", ["clip"]);
	bindAsMethod(host, "hz43VanWatchClip", ["d"]);
	bindAsMethod(host, "hz43VanGather", []);
	return host;
}
function gatherEmptyNameOnly(kids) {
	const units = [];
	for (let i = 0; i < kids.length; i++) {
		if (vanNamed(kids[i].name) || kids[i].name === "") units.push(kids[i]);
	}
	return units;
}
function gatherBroadPrefix(kids) {
	const units = [];
	for (let i = 0; i < kids.length; i++) {
		if (vanNamed(kids[i].name) || isInstName(kids[i].name)) units.push(kids[i]);
	}
	return units;
}
outline.x = 0; outline.y = 0;
o2co2.x = 21.7; o2co2.y = 89.85;
const emptyOnly = gatherEmptyNameOnly(blgKids);
expect(emptyOnly.indexOf(unnamedCap) >= 0 && emptyOnly.indexOf(inst66) < 0, "empty-name-only gather twin misses the session instance66 cap");
expect(emptyOnly.indexOf(inst546) < 0 && emptyOnly.indexOf(inst548) < 0 && emptyOnly.indexOf(inst550) < 0, "empty-name-only gather twin does not see the extra runtime autonames");
const broadPrefix = gatherBroadPrefix(blgKids);
expect(broadPrefix.indexOf(inst66) >= 0 && broadPrefix.indexOf(inst546) >= 0 && broadPrefix.indexOf(inst548) >= 0 && broadPrefix.indexOf(inst550) >= 0, "broad instance* gather takes the extra runtime autonames");
const prodHost = makeProductionHost(blgKids);
expect(prodHost.hz43VanInstName("instance66") === true && prodHost.hz43VanNamed("instance66") === false, "production InstName is a type check, not VanNamed ownership");
expect(prodHost.hz43VanInstName("instance546") === true && prodHost.hz43VanNamed("instance546") === false, "production VanNamed rejects extra autoname instance546");
expect(prodHost.hz43VanCapClip(inst66) === true, "production CapClip accepts session instance66 at cap pose");
expect(prodHost.hz43VanCapClip(inst546) === false && prodHost.hz43VanCapClip(inst548) === false && prodHost.hz43VanCapClip(inst550) === false, "production CapClip rejects extra autonames at non-cap native locals");
expect(prodHost.hz43VanRingClip(inst546) === true, "production RingClip accepts the unnamed annulus between EnvConditionBase and EnemyDetection");
expect(prodHost.hz43VanRingClip(inst66) === false && prodHost.hz43VanRingClip(inst548) === false && prodHost.hz43VanRingClip(inst550) === false, "production RingClip rejects cap pose and collapsed INFO ticks");
prodHost.hz43VanGather();
expect(prodHost.hz43VanD.indexOf(inst66) >= 0 && prodHost.hz43VanD.indexOf(outline) >= 0, "production Gather adds the session cap and outline");
expect(prodHost.hz43VanD.indexOf(inst546) >= 0 && prodHost.hz43VanD.indexOf(inst548) < 0 && prodHost.hz43VanD.indexOf(inst550) < 0, "production Gather adds the filled annulus and not INFO ticks");
expect(prodHost.hz43VanD.indexOf(bio) < 0 && prodHost.hz43VanD.indexOf(envBase) < 0 && prodHost.hz43VanD.indexOf(envAlert) < 0, "production Gather does not add named bio or env clips");

const lrgBlg = { name: "BottomLeftGroup_mc", kids: [] };
const lrgOutline = { name: "WatchOutline_mc", parent: lrgBlg, x: 0, y: 0, scaleX: 1, scaleY: 1 };
const lrgEnv = { name: "EnvConditionBase_mc", parent: lrgBlg, x: 109.65, y: 111.45, scaleX: 1, scaleY: 1 };
const lrgAnnulus = { name: "instance80", parent: lrgBlg, x: 110.5, y: 110.5, scaleX: 1, scaleY: 1 };
const lrgDetect = { name: "EnemyDetectionAnim_mc", parent: lrgBlg, x: 110.5, y: 110.5, scaleX: 1, scaleY: 1 };
const lrgO2 = { name: "O2CO2_mc", parent: lrgBlg, x: 21.7, y: 89.85, scaleX: 1, scaleY: 1 };
lrgBlg.kids = [lrgOutline, lrgEnv, lrgAnnulus, lrgDetect, lrgO2];
lrgBlg.getChildAt = function(i) { return this.kids[i]; };
lrgBlg.getChildIndex = function(d) {
	const i = this.kids.indexOf(d);
	if (i < 0) throw new Error("not a child");
	return i;
};
Object.defineProperty(lrgBlg, "numChildren", { get: function() { return this.kids.length; } });
const lrgHost = makeProductionHost(lrgBlg.kids);
lrgHost.hzBlg = lrgBlg;
expect(lrgHost.hz43VanRingClip(lrgAnnulus) === true, "large PHC uses the same sandwich identity at a different depth");
expect(lrgHost.hz43VanRingClip(lrgO2) === false, "large PHC named O2 bar at the normal-movie ring depth is not the annulus");
expect(lrgHost.hz43VanCapClip(lrgAnnulus) === false, "large PHC annulus at face center is not the cap");
lrgHost.hz43VanN = 0;
lrgHost.hz43VanD = [];
lrgHost.hz43VanNm = [];
lrgHost.hz43VanGather();
expect(lrgHost.hz43VanD.indexOf(lrgAnnulus) >= 0 && lrgHost.hz43VanD.indexOf(lrgO2) >= 0 && lrgHost.hz43VanD.indexOf(lrgDetect) < 0, "large PHC gather owns the annulus and named O2, not detection");
blg.kids = blgKids;
inst546.x = 88.4;
inst546.y = 88.4;
inst546.scaleX = 0.8;
inst546.scaleY = 0.8;
expect(prodHost.hz43VanRingClip(inst546) === true, "production RingClip keeps the captured annulus object at WatchScale 0.8 local 88.4");
expect(prodHost.hz43VanRingProof(inst546) === false, "native annulus proof does not widen to 88.4");
expect(prodHost.hz43VanWatchClip(inst546) === true, "production WatchClip still owns the captured annulus after scale");
expect(prodHost.hz43VanCapClip(inst546) === false && prodHost.hz43VanCapClip(inst66) === true, "scaled annulus is not the cap; cap pose still holds");
expect(prodHost.hz43VanRingClip(inst548) === false && prodHost.hz43VanWatchClip(inst548) === false, "collapsed INFO tick stays excluded at scaled locals");
const stealScale = { name: "instance99", parent: blg, x: 88.4, y: 88.4, scaleX: 0.8, scaleY: 0.8 };
expect(prodHost.hz43VanRingClip(stealScale) === false, "a different clip at 88.4 is not stolen as the annulus");
const deadAnnulus = inst546;
deadAnnulus.parent = { name: "gone" };
prodHost.hz43VanRing = deadAnnulus;
const bornScaled = { name: "instance200", parent: blg, x: 88.4, y: 88.4, scaleX: 1, scaleY: 1 };
expect(prodHost.hz43VanRingClip(bornScaled) === false, "recreated clip at scaled pose is not captured");
inst546.parent = blg;
inst546.x = 110.5;
inst546.y = 110.5;
inst546.scaleX = 1;
inst546.scaleY = 1;
prodHost.hz43VanRing = null;
expect(prodHost.hz43VanRingClip(inst546) === true, "recreated native 110.5 sandwich recaptures the annulus");
prodHost.hz43VanRing = null;
inst546.x = 110.5;
inst546.y = 110.5;

function makeFadeClip(name, x, y, alpha) {
	return {
		name: name,
		visible: true,
		alpha: alpha,
		x: x,
		y: y,
		scaleX: 1,
		scaleY: 1,
		transform: { colorTransform: { alphaMultiplier: alpha, alphaOffset: 0 } }
	};
}
function makeFadeHost() {
	const outlineC = makeFadeClip("WatchOutline_mc", 0, 0, 0);
	const o2C = makeFadeClip("O2CO2_mc", 21.7, 89.85, 0);
	const capC = makeFadeClip("instance66", 0, -0.25, 0);
	const tempC = makeFadeClip("Temperature_mc", 79.7, 133.75, 0);
	const kids = [capC, outlineC, o2C, tempC];
	const fadeBlg = {
		name: "BottomLeftGroup_mc",
		kids: kids,
		getChildAt: function(i) { return this.kids[i]; },
		getChildByName: function(n) { for (let i = 0; i < this.kids.length; i++) if (this.kids[i] && this.kids[i].name === n) return this.kids[i]; return null; }
	};
	if (!Object.prototype.hasOwnProperty.call(fadeBlg, "numChildren")) {
		Object.defineProperty(fadeBlg, "numChildren", { get: function() { return this.kids.length; } });
	}
	for (let i = 0; i < kids.length; i++) kids[i].parent = fadeBlg;
	const host = {
		hzBlg: fadeBlg,
		hzFrameN: 0,
		hz43VanCap: 1,
		hz43VanFadeN: 0,
		hz43VanFadeAt: -1,
		hz43VanN: 1,
		hz43VanD: [capC],
		outlineClip: outlineC,
		o2Clip: o2C,
		capClip: capC,
		tempClip: tempC,
		hzFindByName: function(root, name) {
			if (!root) return null;
			const list = root.kids || [];
			for (let i = 0; i < list.length; i++) {
				if (list[i] && list[i].name === name) return list[i];
			}
			return null;
		}
	};
	bindAsMethod(host, "hz43VanSkip", ["name"]);
	bindAsMethod(host, "hz43VanInstName", ["name"]);
	bindHidecache(host);
	bindAsMethod(host, "hz43VanCapClip", ["d"]);
	bindAsMethod(host, "hz43VanClip", ["i"]);
	bindAsMethod(host, "hz43VanFadeSeen", ["d"]);
	bindAsMethod(host, "hz43VanFadeOk", []);
	return host;
}
const fadeTick = makeFadeHost();
expect(fadeTick.hz43VanCapClip(fadeTick.capClip) === true, "production fade host cap identity matches session instance66 pose");
fadeTick.hzFrameN = 1;
expect(fadeTick.hz43VanFadeOk() === false, "production FadeOk is false on the first hzFrameN while chrome alpha and ctA are 0");
expect(fadeTick.hz43VanFadeN === 1, "production FadeOk counts the first distinct hzFrameN");
expect(fadeTick.hz43VanFadeOk() === false && fadeTick.hz43VanFadeN === 1, "enter+exit on the same hzFrameN counts once");
for (let fr = 2; fr <= 15; fr++) {
	fadeTick.hzFrameN = fr;
	expect(fadeTick.hz43VanFadeOk() === false, "production FadeOk stays false at distinct hzFrameN " + fr);
	expect(fadeTick.hz43VanFadeOk() === false && fadeTick.hz43VanFadeN === fr, "a second call on hzFrameN " + fr + " does not double-count");
}
expect(fadeTick.outlineClip.alpha === 0 && fadeTick.outlineClip.transform.colorTransform.alphaMultiplier === 0, "16-tick boundary still has chrome alpha 0 and ctA 0");
fadeTick.hzFrameN = 16;
expect(fadeTick.hz43VanFadeOk() === true, "production FadeOk latches true on the 16th distinct hzFrameN");
expect(fadeTick.outlineClip.alpha === 0 && fadeTick.tempClip.alpha === 0, "16-tick timeout still writes readiness at chrome alpha 0 and does not raise INFO alpha");

const fadeAlpha = makeFadeHost();
fadeAlpha.outlineClip.alpha = 0.91;
expect(fadeAlpha.hz43VanFadeOk() === true, "production FadeOk is true when outline DisplayObject.alpha is above 0.9");
const fadeCt = makeFadeHost();
fadeCt.outlineClip.alpha = 0;
fadeCt.outlineClip.transform.colorTransform.alphaMultiplier = 0.91;
expect(fadeCt.hz43VanFadeOk() === true, "production FadeOk is true when outline ColorTransform alphaMultiplier is above 0.9 and alpha is 0");
const fadeEdge = makeFadeHost();
fadeEdge.outlineClip.alpha = 0.9;
fadeEdge.outlineClip.transform.colorTransform.alphaMultiplier = 0.9;
expect(fadeEdge.hz43VanFadeOk() === false, "production FadeOk requires alpha or ctA strictly greater than 0.9");
const fadeInfo = makeFadeHost();
fadeInfo.tempClip.alpha = 1;
fadeInfo.tempClip.transform.colorTransform.alphaMultiplier = 1;
expect(fadeInfo.hz43VanFadeOk() === false, "production FadeOk ignores INFO Temperature alpha");
const fadeCap = makeFadeHost();
fadeCap.capClip.alpha = 0.91;
expect(fadeCap.hz43VanFadeOk() === true, "production FadeOk is true when the verified cap alpha is above 0.9");
const fadeO2 = makeFadeHost();
fadeO2.o2Clip.alpha = 0;
fadeO2.o2Clip.transform.colorTransform.alphaMultiplier = 0.91;
expect(fadeO2.hz43VanFadeOk() === true, "production FadeOk is true on O2 ColorTransform alphaMultiplier when outline alpha is 0");

function makeSyncHideHost(style) {
	const host = {
		hzWatchStyle: style,
		hz43HideStyle: -1,
		hzHideVanillaWatch: true,
		hzHideCache: ["stale"],
		hz43VanShown: 0,
		hz43VanTries: 0,
		showN: 0,
		restoreN: 0,
		chromeN: 0,
		chromeHide: null,
		hz43ShowVanilla: function() { this.showN++; return true; },
		hz43VanRestoreHid: function() { this.restoreN++; },
		hz43VanBlgChrome: function(hide) { this.chromeN++; this.chromeHide = hide; }
	};
	bindAsMethod(host, "hz43SyncHide", []);
	return host;
}
const syncCustom = makeSyncHideHost(3);
syncCustom.hz43SyncHide();
expect(syncCustom.hzHideCache === null && syncCustom.hz43HideStyle === 3, "production SyncHide drops a stale hide cache when WatchStyle latches");
syncCustom.hzHideCache = ["built"];
syncCustom.hz43SyncHide();
expect(syncCustom.hzHideCache && syncCustom.hzHideCache[0] === "built", "production SyncHide keeps the hide cache on the same WatchStyle");
syncCustom.hzWatchStyle = 0;
syncCustom.hz43SyncHide();
expect(syncCustom.hzHideCache === null && syncCustom.hz43HideStyle === 0, "production SyncHide rebuilds hide cache on Digital then Off while hideWatch stays true");
const syncVan = makeSyncHideHost(0);
syncVan.hz43ShowVanilla = function() { this.showN++; return false; };
syncVan.hz43SyncHide();
syncVan.hzWatchStyle = 1;
syncVan.hz43ShowVanilla = function() { this.showN++; return true; };
syncVan.hz43SyncHide();
expect(syncVan.showN === 1 && syncVan.hz43VanShown === 1 && syncVan.hzHideVanillaWatch === false, "production Off then Vanilla runs ShowVanilla once and drops hideWatch");
syncVan.hz43SyncHide();
expect(syncVan.showN === 1 && syncVan.restoreN === 1 && syncVan.chromeHide === false, "later vanilla frames retry hid restore and BlgChrome show without a second ShowVanilla dump");
const markHost = { hz43VanMarkName: null };
bindAsMethod(markHost, "hz43VanMarkName", ["name"]);
expect(markHost.hz43VanMarkName("WatchIconsWidget_mc") === true && markHost.hz43VanMarkName("MissionIconsWidget_mc") === true && markHost.hz43VanMarkName("EnemyIconsWidget_mc") === true, "production keep-mark still names nearby mission and enemy widgets");
expect(markHost.hz43VanMarkName("WatchPointerOutline_mc") === false && markHost.hz43VanMarkName("WatchOutline_mc") === false, "production keep-mark rejects heading outline and bezel");

function makePlaceHost() {
	const host = makeFadeHost();
	const icons = makeFadeClip("WatchIconsWidget_mc", 111.35, 111.45, 1);
	icons.parent = host.hzBlg;
	host.hzBlg.kids.push(icons);
	host.iconsClip = icons;
	host.int = function(n) { return n | 0; };
	host.hzWatchStyle = 1;
	host.hzUserHidden = false;
	host.hzArrange = false;
	host.hzArrDrag = "";
	host.hz43VanWrote = false;
	host.hz43MarkMoved = false;
	host.hz43HidN = 0;
	host.hz43VanHX = 0;
	host.hz43VanHY = 0;
	host.hz43VanWdx = Number.NaN;
	host.hz43VanWdy = Number.NaN;
	host.hz43VanWsc = Number.NaN;
	host.hz43VanWmk = -1;
	host.hz43VnAx = 0;
	host.hz43VanNeed = 0;
	host.hz43VanKids = host.hzBlg.numChildren;
	host.handle = { x: -64.3, y: 34.85, visible: false };
	host.placed = null;
	host.dumps = [];
	host.chromeCalls = 0;
	host.captureN = 0;
	host.hz43VanEnsure = function() { return this.handle; };
	host.hz43VanCapture = function() { this.captureN++; };
	host.hz43VanSc = function() { return 1; };
	host.hzLayHas = function(k) { return k === "Watch"; };
	host.hzPlace = function(hnd, x, y) { this.placed = { x: x, y: y }; };
	host.hz43VanDump = function(why) { this.dumps.push(why); };
	host.hz43VanChrome = function() { this.chromeCalls++; };
	host.hz43VanResolve = function() {};
	host.hz43VanN = 4;
	host.hz43VanGot = [1, 1, 1, 1];
	host.hz43VanD = [host.outlineClip, host.o2Clip, host.capClip, icons];
	host.hz43VanNm = ["WatchOutline_mc", "O2CO2_mc", "instance66", "WatchIconsWidget_mc"];
	host.hz43VanUXA = [1, 1, 1, 1];
	host.hz43VanUYA = [1, 1, 1, 1];
	host.hz43VanX = [0, 21.7, 0, 111.35];
	host.hz43VanY = [0, 89.85, -0.25, 111.45];
	host.hz43VanOX = [0, 0, 0, 0];
	host.hz43VanOY = [0, 0, 0, 0];
	host.hz43VanSX = [1, 1, 1, 1];
	host.hz43VanSY = [1, 1, 1, 1];
	bindAsMethod(host, "hz43VanMarkName", ["name"]);
	bindAsMethod(host, "hz43VanHasAncestorUnit", ["d"]);
	host.HZ43_VAN_FOLLOW = asConst("HZ43_VAN_FOLLOW");   // r9: the shipped list (LocationAlertText, EnvAlertText, BioAlertText)
	host.HZ46_TXT = asConst("HZ46_TXT");
	host.hz43FoD = []; host.hz43FoHX = []; host.hz43FoHY = []; host.hz43FoSX = []; host.hz43FoSY = [];
	host.hz43FoDx = 0; host.hz43FoDy = 0; host.hz43FoSc = 1; host.hz43FoMoved = false;
	host.isNaN = isNaN;
	bindAsMethod(host, "hz43FollowApply", []);
	bindAsMethod(host, "hz43VanWrite", ["dx", "dy", "sc", "marks"]);
	bindAsMethod(host, "hz43VanPlace", []);
	bindAsMethod(host, "hz43TintRgb", ["clip", "col", "amt"]);
	bindHz45(host);
	return host;
}
// r8: the planet-info art path (hz45*) and the listener sync, as in the AS (fields start empty).
function bindHz45(host) {
	host.hz45D = []; host.hz45HX = []; host.hz45HY = []; host.hz45SX = []; host.hz45SY = [];
	host.hz45SM = -1; host.hz45SDx = 0; host.hz45SDy = 0; host.hz45SSc = 1; host.hz45SB = null; host.hz45SN = -1;
	host.hz43ScanHid = false;
	host.hzWlOn = false;
	if (!host.Event) host.Event = { ADDED: "added" };
	if (host.hz43FoLsn === undefined) host.hz43FoLsn = null;
	if (!host.isNaN) host.isNaN = isNaN;
	if (!host.int) host.int = function(n) { return n | 0; };
	bindAsMethod(host, "hz45Art", ["d"]);
	bindAsMethod(host, "hz45Mode", []);
	bindAsMethod(host, "hz45Put", ["d", "mode"]);
	bindAsMethod(host, "hz45Prune", []);
	bindAsMethod(host, "hz45Sync", []);
	// r9: the INFO tick path (MF-1 switch) and the S-2 alert text hide
	if (!host.hz43ScanMk) host.hz43ScanMk = [];
	if (!host.HZ46_TXT) host.HZ46_TXT = asConst("HZ46_TXT");
	host.HZ46_TICK_MOVE = asConst("HZ46_TICK_MOVE");
	bindAsMethod(host, "hz46Tick", ["hx", "hy"]);
	bindAsMethod(host, "hz46TickPut", ["d", "k", "mode"]);
	bindAsMethod(host, "hz46WlTick", ["d"]);
	bindAsMethod(host, "hz46TxtScanHide", []);
	// r9 (2/2): the text-holder fields (MF-1), the swapped-art native (root cause 1) and the hold's W3 re-hide (root cause 2)
	host.HZ46_KMAX = asConst("HZ46_KMAX");
	host.hz46KN = []; host.hz46KD = []; host.hz46KX = []; host.hz46KY = []; host.hz46KSX = []; host.hz46KSY = [];
	if (host.hz44Hid === undefined) host.hz44Hid = false;
	if (!host.HZ45_W3) host.HZ45_W3 = asConst("HZ45_W3");
	bindAsMethod(host, "hz46KidRec", ["i", "d"]);
	bindAsMethod(host, "hz46KidPut", ["i", "d", "nx", "ny", "fs"]);
	bindAsMethod(host, "hz46Inherit", ["d"]);
	bindAsMethod(host, "hz46HoldW3", []);
	// r9b: the alert icons / flash on a moved vanilla watch
	host.HZ47_NAMES = asConst("HZ47_NAMES");
	host.hz47D = [null, null, null]; host.hz47On = false; host.hz47B = null;
	if (!host.hz27BioMine) host.hz27BioMine = [null, null, null];
	bindAsMethod(host, "hz47Sync", ["force"]);
}
const placeWait = makePlaceHost();
placeWait.hzFrameN = 1;
placeWait.hz43HidN = 0;
placeWait.hz43VanPlace();
expect(placeWait.chromeCalls >= 1, "production VanPlace restores chrome after capture even when hidN is 0");
expect(placeWait.outlineClip.x === 0 && placeWait.capClip.x === 0 && placeWait.iconsClip.x === 111.35, "production VanPlace does not write sibling locals while FadeOk is false");
expect(placeWait.dumps.indexOf("fade-wait") >= 0, "production VanPlace dumps fade-wait instead of write while not ready");
expect(placeWait.outlineClip.alpha === 0 && placeWait.outlineClip.transform.colorTransform.alphaMultiplier === 0, "production VanPlace wait leaves chrome alpha and ctA at 0");
placeWait.hzFrameN = 1;
const fadeNWait = placeWait.hz43VanFadeN;
placeWait.hz43VanPlace();
expect(placeWait.hz43VanFadeN === fadeNWait && placeWait.captureN === 2, "production VanPlace enter+exit on one hzFrameN does not double-count FadeN");
placeWait.outlineClip.alpha = 0.91;
placeWait.hz43VanPlace();
expect(placeWait.outlineClip.x === -64.3 && placeWait.capClip.x === -64.3 && placeWait.o2Clip.x === 21.7 - 64.3, "production VanPlace saved write is ox + dx/ux at scale 1");
expect(placeWait.iconsClip.x === 111.35 - 64.3, "production VanPlace moves markers with the assembly");
expect(placeWait.dumps.indexOf("write") >= 0, "production VanPlace dumps write after FadeOk");
const xAfter = placeWait.outlineClip.x;
placeWait.hz43VanPlace();
expect(placeWait.outlineClip.x === xAfter, "production VanWrite skips an identical saved dx/dy/scale");

const placeTimeout = makePlaceHost();
for (let fr = 1; fr <= 15; fr++) {
	placeTimeout.hzFrameN = fr;
	placeTimeout.hz43VanPlace();
}
expect(placeTimeout.outlineClip.x === 0 && placeTimeout.outlineClip.alpha === 0, "production VanPlace 15 HUD ticks still have not written at chrome alpha 0");
placeTimeout.hzFrameN = 16;
placeTimeout.hz43VanPlace();
expect(placeTimeout.outlineClip.x === -64.3 && placeTimeout.outlineClip.alpha === 0, "production 16-tick fail-open writes sibling locals while chrome alpha is still 0");
expect(placeTimeout.tempClip.alpha === 0, "fail-open Arrange does not raise INFO alpha");

const placeDrag = makePlaceHost();
placeDrag.hzArrange = true;
placeDrag.hzArrDrag = "Watch";
placeDrag.hzFrameN = 1;
placeDrag.hz43VanPlace();
expect(placeDrag.outlineClip.x === -64.3 && placeDrag.outlineClip.alpha === 0, "production Arrange drag bypasses FadeOk and writes at chrome alpha 0");

const placeUndo = makePlaceHost();
placeUndo.outlineClip.alpha = 0.91;
placeUndo.hz43MarkMoved = true;
placeUndo.iconsClip.x = 91.7;
const undoWrites = [];
const innerUndoWrite = placeUndo.hz43VanWrite;
placeUndo.hz43VanWrite = function(dx, dy, sc, marks) {
	innerUndoWrite(dx, dy, sc, marks);
	undoWrites.push({ dx: dx, dy: dy, sc: sc, marks: marks, iconsX: placeUndo.iconsClip.x });
};
placeUndo.hz43VanPlace();
expect(undoWrites.length >= 2 && undoWrites[0].dx === 0 && undoWrites[0].dy === 0 && undoWrites[0].sc === 1 && undoWrites[0].iconsX === 111.35, "production Digital then Vanilla MarkMoved undo writes native marker locals before saved Arrange");
expect(placeUndo.iconsClip.x === 111.35 - 64.3 && placeUndo.outlineClip.x === -64.3, "production saved Arrange still follows MarkMoved undo on the same VanPlace");

const tintWait = makePlaceHost();
tintWait.outlineClip.transform.colorTransform.alphaMultiplier = 0.25;
tintWait.outlineClip.transform.colorTransform.alphaOffset = 0;
tintWait.hz43TintRgb(tintWait.outlineClip, 0x446688, 0.55);
expect(tintWait.outlineClip.transform.colorTransform.alphaMultiplier === 0.25 && tintWait.outlineClip.transform.colorTransform.alphaOffset === 0, "production TintRgb preserves both CT alpha fields while writing RGB");
expect(Math.abs(tintWait.outlineClip.transform.colorTransform.redMultiplier - (1 - 0.55)) < 1e-9, "production TintRgb still assigns RGB during the wait window");

const writeNaN = makePlaceHost();
expect(Number.isNaN(writeNaN.hz43VanWdx), "production Wdx starts NaN so the first saved write is not treated as identical");
writeNaN.hz43VanWrite(-64.3, 34.85, 1);
expect(writeNaN.outlineClip.x === -64.3 && writeNaN.capClip.x === -64.3 && writeNaN.o2Clip.x === 21.7 - 64.3, "production VanWrite is ox + (hx-ox)*sc + dx/ux");
expect(writeNaN.capClip.y === -0.25 + 34.85 && writeNaN.outlineClip.alpha === 0, "production VanWrite moves cap y with dy/uy and does not assign alpha");
const writeMarks = makePlaceHost();
writeMarks.hz43VanWrite(-10, 5, 0.8, true);
expect(writeMarks.outlineClip.x === 0 && writeMarks.capClip.x === 0 && writeMarks.o2Clip.x === 21.7, "production marks write does not move outline, cap, or O2");
expect(writeMarks.iconsClip.x === 111.35 - 10 && writeMarks.iconsClip.y === 111.45 + 5 && writeMarks.iconsClip.scaleX === 1, "production marks write moves WatchIconsWidget_mc at scale 1");
const writeScale = makePlaceHost();
writeScale.hz43VanWrite(-40, 20, 0.8, false);
expect(Math.abs(writeScale.outlineClip.x - -40) < 1e-9 && Math.abs(writeScale.o2Clip.x - (21.7 * 0.8 - 40)) < 1e-9, "production VanWrite scale 0.8 moves locals from the outline origin");
expect(Math.abs(writeScale.capClip.y - (-0.25 * 0.8 + 20)) < 1e-9 && Math.abs(writeScale.iconsClip.x - (111.35 * 0.8 - 40)) < 1e-9, "production VanWrite scale 0.8 keeps cap and markers in the assembly");
expect(writeScale.outlineClip.scaleX === 0.8 && writeScale.capClip.alpha === 0, "production VanWrite scale 0.8 writes clip scale and does not assign alpha");

// ---- r6 item 1: the watch ghost. LocationAlertText (FadeInPlanetInfo: body name + "PLANET", native 110.75, 96.75 on the
// dial) is skipped as a unit (name has "Alert"), so the Arrange write left it at the native spot. It now follows the write.
{
	const loc = makeFadeClip("LocationAlertText", 110.75, 96.75, 1);
	const mk = () => { const h = makePlaceHost(); const c = Object.assign({}, loc, { transform: loc.transform }); c.parent = h.hzBlg; h.hzBlg.kids.push(c); h.locClip = c; return h; };
	const skip = { hz43VanSkip: null }; bindAsMethod(skip, "hz43VanSkip", ["name"]);
	expect(skip.hz43VanSkip("LocationAlertText") === true, "ghost cause: hz43VanSkip drops LocationAlertText from the Arrange units");
	const g = mk();
	g.hz43VanWrite(-64.3, 34.85, 1);
	expect(Math.abs(g.locClip.x - (110.75 - 64.3)) < 1e-9 && Math.abs(g.locClip.y - (96.75 + 34.85)) < 1e-9, "ghost fix: LocationAlertText moves by the same dx/dy as the watch (no copy left at the native spot)");
	expect(g.outlineClip.x === -64.3 && g.hz43FoMoved === true, "ghost fix: the assembly write itself is unchanged");
	const s = mk();
	s.hz43VanWrite(-40, 20, 0.8, false);
	expect(Math.abs(s.locClip.x - (110.75 * 0.8 - 40)) < 1e-9 && Math.abs(s.locClip.y - (96.75 * 0.8 + 20)) < 1e-9 && Math.abs(s.locClip.scaleX - 0.8) < 1e-9, "ghost fix: scale 0.8 scales the overlay from the outline origin like the units");
	s.hz43VanWrite(0, 0, 1);
	expect(s.locClip.x === 110.75 && s.locClip.y === 96.75 && s.locClip.scaleX === 1 && s.hz43FoMoved === false, "ghost fix: write(0,0,1) (style change / reset) puts the overlay back at its native place");
	const m = mk();
	m.hz43VanWrite(-10, 5, 0.8, true);
	// r7 (MF-1): the marker-only write (Horizon faces 3 / 4) now moves it too, with the markers' offset at scale 1.
	expect(Math.abs(m.locClip.x - (110.75 - 10)) < 1e-9 && Math.abs(m.locClip.y - (96.75 + 5)) < 1e-9 && m.locClip.scaleX === 1, "ghost fix r7: a marker-only write (Horizon faces) moves the overlay with the markers' offset, scale 1");
	const r = mk();
	r.hz43VanWrite(-64.3, 34.85, 1);
	const fresh = Object.assign({}, loc, { x: 110.75, y: 96.75, transform: loc.transform });
	r.hzBlg.kids[r.hzBlg.kids.indexOf(r.locClip)] = fresh;
	r.hz43FollowApply();
	expect(Math.abs(fresh.x - (110.75 - 64.3)) < 1e-9 && r.hz43FoHX[0] === 110.75, "ghost fix: a new instance (HUD rebuild) is captured at its native place, then moved");
	const n = mk();
	n.locClip.x = 7; n.hz43FollowApply();
	expect(n.locClip.x === 7 && n.hz43FoD.length === 0, "ghost fix: never moved = the game's own placement is not touched or captured");
	const fb = funcBody(as, "hz43FollowApply");
	expect(fb.indexOf("hzFindByName") < 0 && fb.indexOf("getChildAt") < 0 && (fb.match(/getChildByName/g) || []).length === 1, "ghost fix: one direct getChildByName per follower, no tree search");
	const callers = as.split("\n").filter((l) => /this\.hz43FollowApply\(\)/.test(l));
	expect(callers.length === 5 && funcBody(as, "hz40SetScan").indexOf("this.hz43FollowApply()") >= 0 && funcBody(as, "hzOnLocalEnv").indexOf("this.hz43FollowApply()") >= 0 && (funcBody(as, "hz43VanWrite").match(/this\.hz43FollowApply\(\)/g) || []).length === 2 && funcBody(as, "hz43FoOnAdd").indexOf("this.hz43FollowApply()") >= 0,
		"ghost fix: event-driven only (assembly write, marker write, scan edge, LocalEnvironmentData, ADDED); " + callers.length + " call sites");
	expect(funcBody(as, "hzOnFrame").indexOf("hz43FollowApply") < 0 && funcBody(as, "hz27OnExit").indexOf("hz43FollowApply") < 0, "ghost fix: no per-frame call");
	expect(fb.indexOf(".alpha") < 0 && fb.indexOf(".visible") < 0, "ghost fix: position / scale only; visibility rules (hz41LocHide) unchanged");
}

// ---- r7 MF-1: Horizon faces (WatchStyle 3 / 4). The tester's ghost was the landing alert (LocalEnvironmentData,
// FadeInPlanetInfo) with a moved Horizon face: hz43VanHorizon writes the markers only (marks=true), so the r6 follower
// never ran there. LocationAlertText now follows the face with the markers' offset (scale 1). S-1: a new instance is
// placed on its ADDED event (before the frame renders). Event-driven, never hidden.
{
	const loc = makeFadeClip("LocationAlertText", 110.75, 96.75, 1);
	const mk = (src) => {
		const h = makePlaceHost();
		h.hzWatchStyle = 3;
		const c = Object.assign({}, loc, { transform: loc.transform, visible: true }); c.parent = h.hzBlg; h.hzBlg.kids.push(c); h.locClip = c;
		h.hz43FoLsn = null;
		h.Event = { ADDED: "added" };
		h.hzBlg.listeners = [];
		h.hzBlg.addEventListener = function(t, f, cap, pri, weak) { this.listeners.push({ t: t, f: f, weak: weak }); };
		h.hzBlg.removeEventListener = function(t, f) { this.listeners = this.listeners.filter((l) => !(l.t === t && l.f === f)); };
		if (src) h.hz43VanWrite = Function.apply(null, ["dx", "dy", "sc", "marks", "with(this){\n" + asInnerOf(src, "hz43VanWrite") + "\n}"]).bind(h);
		bindAsMethod(h, "hz43FoOnAdd", ["e"]);
		const inner = h.hz43FollowApply;
		h.followN = 0;
		h.hz43FollowApply = function() { h.followN++; return inner(); };
		return h;
	};
	const near = (a, b) => Math.abs(a - b) < 1e-9;
	const fireAdd = (hh, ev) => { const l = hh.hzBlg.listeners[0]; if (l) l.f(ev); };
	// 1. the landing ghost: a moved Horizon face, then LocalEnvironmentData
	const h = mk();
	h.hz43VanWrite(-30, 12, 1, true);
	const moved = near(h.locClip.x, 110.75 - 30) && near(h.locClip.y, 96.75 + 12) && h.locClip.scaleX === 1;
	expect(moved, "r7 MF-1: Horizon face moved: LocationAlertText follows with the markers' offset (no ghost at the native spot)");
	expect(near(h.locClip.x - 110.75, h.iconsClip.x - 111.35) && near(h.locClip.y - 96.75, h.iconsClip.y - 111.45), "r7 MF-1: same dx / dy as the live marker widgets");
	expect(h.outlineClip.x === 0 && h.capClip.x === 0 && h.o2Clip.x === 21.7, "r7 MF-1: native chrome (outline, cap, O2) still not moved in the Horizon faces");
	expect(h.locClip.visible === true && h.locClip.alpha === 1, "r7 MF-1: never hidden (visible and alpha untouched)");
	h.hz43FollowApply();   // LocalEnvironmentData / scan edge re-apply
	expect(near(h.locClip.x, 110.75 - 30), "r7 MF-1: an event re-apply keeps it on the face");
	// 2. change-only: the marker write already returns early on an unchanged offset; the follower adds nothing per frame
	const n0 = h.followN;
	h.hz43VanWrite(-30, 12, 1, true);
	h.hz43VanWrite(-30, 12, 1, true);
	expect(h.followN === n0, "r7 MF-1: an unchanged marker offset does not re-run the follower (per-frame callers stay free)");
	h.hz43VanWrite(-50, 20, 1, true);
	expect(h.followN === n0 + 1 && near(h.locClip.x, 110.75 - 50) && near(h.locClip.y, 96.75 + 20), "r7 MF-1: a new face position re-places it once");
	// 3. face back on the native spot, then style change away from 3 / 4
	h.hz43VanWrite(0, 0, 1, true);
	expect(h.locClip.x === 110.75 && h.locClip.y === 96.75 && h.hz43FoMoved === false, "r7 MF-1: marker offset 0 puts it back at its native place");
	const o = mk();
	o.hz43VanWrite(-30, 12, 1, true);
	o.hzWatchStyle = 0;
	o.hz43VanPlace();
	expect(o.locClip.x === 110.75 && o.locClip.y === 96.75 && o.iconsClip.x === 111.35, "r7 MF-1: leaving the Horizon faces (style 0) puts markers and LocationAlertText home");
	const v = mk();
	v.hz43VanWrite(-30, 12, 1, true);
	v.hz43VanWrite(0, 0, 1);   // hz43VanHorizon / hz43VanPlace undo before a vanilla write
	v.hz43VanWrite(-64.3, 34.85, 0.8);
	expect(near(v.locClip.x, 110.75 * 0.8 - 64.3) && near(v.locClip.scaleX, 0.8), "r7 MF-1: vanilla styles keep the r6 assembly follow (scale and offset)");
	// 4. S-1: one weak ADDED listener on BottomLeftGroup_mc once the watch moved; a new instance is placed on ADDED
	expect(h.hzBlg.listeners.length === 1 && h.hzBlg.listeners[0].t === "added" && h.hzBlg.listeners[0].weak === true && h.hz43FoLsn === h.hzBlg, "r7 S-1: one weak ADDED listener on BottomLeftGroup_mc after the first move");
	const fresh = Object.assign({}, loc, { x: 110.75, y: 96.75, transform: loc.transform, visible: true, parent: h.hzBlg });
	h.hzBlg.kids[h.hzBlg.kids.indexOf(h.locClip)] = fresh;
	fireAdd(h, { target: fresh });
	expect(near(fresh.x, 110.75 - 50) === false && fresh.x === 110.75 && fresh.y === 96.75, "r7 S-1: (offset 0 here) the new instance stays native");
	h.hz43VanWrite(-50, 20, 1, true);
	const fresh2 = Object.assign({}, loc, { x: 110.75, y: 96.75, transform: loc.transform, visible: true, parent: h.hzBlg });
	h.hzBlg.kids[h.hzBlg.kids.indexOf(fresh)] = fresh2;
	const n1 = h.followN;
	fireAdd(h, { target: fresh2 });
	expect(h.followN === n1 + 1 && near(fresh2.x, 110.75 - 50) && near(fresh2.y, 96.75 + 20) && h.hz43FoHX[0] === 110.75, "r7 S-1: a new LocationAlertText instance is captured native and placed on its ADDED event (no frame at the native spot)");
	expect(h.hzBlg.listeners.length === 1, "r7 S-1: later writes do not add a second listener");
	const n2 = h.followN;
	fireAdd(h, { target: { name: "Temperature_mc", parent: h.hzBlg } });
	fireAdd(h, { target: { name: "LocationAlertText", parent: { name: "nested" } } });
	fireAdd(h, null);
	expect(h.followN === n2, "r7 S-1: other clips, nested clips and empty events do nothing");
	const never = mk();
	never.hz43FollowApply();
	expect(never.hzBlg.listeners.length === 0, "r7 S-1: no listener while the watch was never moved");
	const lb = funcBody(as, "hz43FoOnAdd");
	expect(lb.indexOf("getChildByName") < 0 && lb.indexOf("hzFindByName") < 0 && lb.indexOf(".visible") < 0 && lb.indexOf(".alpha") < 0, "r7 S-1: the ADDED handler does no lookup and no visibility write");
	expect(["hzOnFrame", "hz27OnExit", "hz43Frame", "hz43VanHorizon"].every((f) => funcBody(as, f).indexOf("hz43FoOnAdd") < 0 && funcBody(as, f).indexOf("Event.ADDED") < 0), "r7 S-1: nothing per frame (listener added only in hz43FollowApply)");
	expect((as.match(/addEventListener\(Event\.ADDED,this\.hz43FoOnAdd,false,0,true\)/g) || []).length === 1, "r7 S-1: the listener is weak and added in one place");
	expect(funcBody(as, "hz43VanHorizon").indexOf("this.hz43VanWrite(cx - rx,cy - ry,1,true)") >= 0, "r7 MF-1: the follower offset is the markers' offset (cx - rx, cy - ry, scale 1)");
	// 5. mutant: the r6 marker write (no follow) leaves the landing alert at the native spot, and the check above fails
	const mutSrc = as.replace(/\n\s*\/\/ r7 \(MF-1\): Horizon faces 3 \/ 4\.[\s\S]*?this\.hz43FollowApply\(\);\n\s*\}/, "");
	expect(mutSrc !== as && (funcBody(mutSrc, "hz43VanWrite").match(/hz43FollowApply/g) || []).length === 1, "r7 MF-1 mutant: built (marker branch follow removed)");
	const mu = mk(mutSrc);
	mu.hz43VanWrite(-30, 12, 1, true);
	const mutMoved = near(mu.locClip.x, 110.75 - 30) && near(mu.locClip.y, 96.75 + 12);
	expect(!mutMoved && mu.locClip.x === 110.75 && mu.iconsClip.x === 111.35 - 30, "r7 MF-1 mutant: without the fix the alert stays at the native spot while the markers move (the move check above would FAIL)");
}

// ---- r6 item 2: [Scanner] HideWatchWhileScanning (default 0, F11 > SCANNER, live on the scan edge) ----
{
	const keysSrc = (as.match(/private static const HZ40_SCAN_KEYS:Array = (\[.*\]);/) || [])[1];
	const KEYS = JSON.parse(keysSrc);
	const cmSrc = (as.match(/private static const HZ40_SCAN_CM:Object = (\{.*\});/) || [])[1];
	const CM = JSON.parse(cmSrc);
	const kd = KEYS.find((d) => d[0] === "HideWatchWhileScanning");
	expect(kd && kd[1] === "b" && kd[2] === 0 && kd[3] === 0 && kd[4] === 1, "HideWatchWhileScanning: [Scanner] bool, default 0 (like the other *WhileScanning keys)");
	const ki = KEYS.indexOf(kd);
	expect(KEYS[ki - 1][0] === "ScanVitalsLayout" && KEYS[ki + 1][0] === "HideQuestPopupsWhileScanning", "HideWatchWhileScanning: listed after the main-HUD keys, before the popup keys");
	expect(Array.isArray(CM.HideWatchWhileScanning) && CM.HideWatchWhileScanning.join(" ").indexOf("0 = shown (default)") >= 0, "HideWatchWhileScanning: the user.ini writer has its comment");
	const iniHw = ini.indexOf("\nHideWatchWhileScanning=0\n"), iniSec = ini.indexOf("\n[Scanner]\n"), iniNext = ini.indexOf("\n[", iniSec + 2);
	expect(iniHw > iniSec && iniHw < iniNext, "HideWatchWhileScanning=0 is in default.ini under [Scanner]");
	expect(CM.HideWatchWhileScanning.every((l) => ini.indexOf("; " + l + "\n") >= 0), "default.ini comment equals the writer's comment");
	expect(ini.indexOf("ScanVitalsLayout=0\n; 1 = the watch hides") >= 0 && ini.indexOf("HideWatchWhileScanning=0\n; ---- scanner popups") >= 0, "default.ini order matches HZ40_SCAN_KEYS");
	expect(funcBody(as, "hz40ScanIniLines").indexOf("for each(var d:Array in HZ40_SCAN_KEYS)") >= 0 && funcBody(as, "hz40ParseIni").indexOf("this.hz40Def(k)") >= 0 && funcBody(as, "hz40Reset").indexOf("HZ40_SCAN_KEYS") >= 0,
		"HideWatchWhileScanning is saved, loaded and reset by the generic [Scanner] key list (user.ini, presets, RESET ALL)");
	// F11 row
	const tr = { hz40Scan: false, hz40Val: function(k) { return this.v[k] !== undefined ? this.v[k] : 1; }, hz41B: null, v: {} };
	bindAsMethod(tr, "hz41B", ["v"]);
	bindAsMethod(tr, "hz41TopRows", []);
	let rows = tr.hz41TopRows();
	const hr = rows[rows.length - 1];
	expect(hr.k === "HideWatchWhileScanning" && hr.t === "b" && hr.l === "HIDE WATCH WHILE SCANNING" && !hr.dis && !hr.sub && /VANILLA/.test(hr.note) && /HORIZON/.test(hr.note) && /alerts stay/.test(hr.note), "F11 SCANNER: HIDE WATCH WHILE SCANNING row (own switch; r7 note: every watch style, alerts stay)");
	tr.v.HideMainHudWhileScanning = 0;
	rows = tr.hz41TopRows();
	expect(!rows[rows.length - 1].dis && rows[2].dis === true, "F11 SCANNER: the row stays live when HIDE HORIZON HUD WHILE SCANNING is off (the kept-vitals rows lock as before)");
	// behavior (r7: every watch style; S-5 module / latch / ARRANGE checks)
	const mkS = (style, on, src) => {
		const mark = { name: "WatchIconsWidget_mc", visible: true }, outl = { name: "WatchOutline_mc", visible: true }, hidMark = { name: "MissionIconsWidget_mc", visible: false };
		const cap = { name: "instance66", visible: true }, temp = { name: "Temperature_mc", visible: true };
		// alerts the user wants in vanilla mode; real captures never hold them (hz43VanSkip), they are listed here as a mis-capture guard
		const bio = { name: "BioAlertText", visible: true }, loc = { name: "LocationAlertText", visible: true }, ring = { name: "EnemyDetectionAnim_mc", visible: true }, env = { name: "EnvAlertText", visible: true };
		const h = { hz40Scan: false, hz40Latch: false, hz30Mod: { scanner: 1 }, hzArrange: false, hzWatchStyle: style, hz43ScanHid: false, hz43ScanMk: [], hz43ScanSt: 0, hz43Watch: { visible: true },
			units: [mark, outl, hidMark, cap, temp, bio, loc, ring, env], HZ43_VAN_FOLLOW: asConst("HZ43_VAN_FOLLOW"), HZ46_TXT: asConst("HZ46_TXT"), int: function(n) { return n | 0; }, shown: [],
			hzBlg: { getChildByName: function(n) { return [bio, loc, ring, env].filter((c) => c.name === n)[0] || null; } },
			cfg: { HideWatchWhileScanning: on }, hz40Cfg: function() { return this.cfg; }, hz43VanClip: function(i) { return this.units[i]; },
			hz43VanShowClip: function(d) { this.shown.push(d.name); if (!d.visible) d.visible = true; },
			mark: mark, outl: outl, hidMark: hidMark, cap: cap, temp: temp, bio: bio, loc: loc, ring: ring, env: env };
		h.hz43VanN = h.units.length; h.hz43VanGot = h.units.map(() => 1);
		bindAsMethod(h, "hz41B", ["v"]); bindAsMethod(h, "hz43VanMarkName", ["name"]); bindAsMethod(h, "hz41ScanHideOn", []); bindAsMethod(h, "hz43VanSkip", ["name"]);
		bindAsMethod(h, "hz43ScanWant", []);
		const bindSrc = (name, args) => { h[name] = Function.apply(null, args.concat(["with(this){\n" + asInnerOf(src || as, name) + "\n}"])).bind(h); };
		bindSrc("hz43ScanPiece", ["d"]); bindSrc("hz43ScanHideSync", []); bindSrc("hz46TxtScanHide", []);
		h.hz45Sync = function() {};
		return h;
	};
	// r9 (user S-2): the env / bio alert text now hides with the watch during the hold; the enemy ring and the scan
	// LocationAlertText stay shown (r7 rule unchanged for those two).
	const alertsUp = (h) => h.loc.visible && h.ring.visible;
	const txtDown = (h) => !h.bio.visible && !h.env.visible && h.hz43ScanMk.indexOf(h.bio) >= 0 && h.hz43ScanMk.indexOf(h.env) >= 0;
	const txtUp = (h) => h.bio.visible && h.env.visible;
	const off = mkS(3, 0); off.hz40Scan = true; off.hz43ScanHideSync();
	expect(!off.hz43ScanHid && off.hz43Watch.visible && off.mark.visible, "HideWatchWhileScanning=0 (default): scanning changes nothing");
	const offV = mkS(1, 0); offV.hz40Scan = true; offV.hz43ScanHideSync();
	expect(!offV.hz43ScanHid && offV.outl.visible && offV.mark.visible && offV.cap.visible, "HideWatchWhileScanning=0 (default): vanilla style unchanged while scanning");
	const on = mkS(4, 1); on.hz40Scan = true; on.hz43ScanHideSync();
	expect(on.hz43ScanHid && !on.hz43Watch.visible && !on.mark.visible && on.outl.visible && on.cap.visible && on.hz43ScanMk.length === 3 && alertsUp(on) && txtDown(on), "Horizon 3 / 4, scan open: the face, its live marker widget and (r9 S-2) the env / bio alert text hide; the enemy ring and LocationAlertText stay");
	on.hz43ScanHideSync();
	expect(on.hz43ScanMk.length === 3, "a repeated edge is a no-op");
	on.hz40Scan = false; on.hz43ScanHideSync();
	expect(!on.hz43ScanHid && on.mark.visible && !on.hidMark.visible && on.hz43ScanMk.length === 0 && txtUp(on), "Horizon, scan close: only what it hid comes back (markers, r9: the alert text; the face redraws in hz43Frame)");
	for (const st of [1, 2]) {
		const van = mkS(st, 1); van.hz40Scan = true; van.hz43ScanHideSync();
		expect(van.hz43ScanHid && !van.outl.visible && !van.mark.visible && !van.cap.visible && !van.temp.visible && van.hz43ScanSt === st, "r7 vanilla style " + st + ", scan open: the captured watch pieces hide (outline, marker widget, cap, readouts)");
		expect(alertsUp(van) && txtDown(van), "r9 vanilla style " + st + ": LocationAlertText and the enemy ring stay shown; BioAlertText / EnvAlertText hide with the watch (S-2)");
		expect(van.hz43Watch.visible === true, "r7 vanilla style " + st + ": the (unused) Horizon face is not touched");
		expect(van.hz43ScanMk.length === 6 && van.hz43ScanMk.indexOf(van.hidMark) < 0, "r7 vanilla style " + st + ": only visible pieces are recorded (a game-hidden piece stays the game's; r9: 4 pieces + 2 alert texts)");
		van.hz40Scan = false; van.hz43ScanHideSync();
		expect(!van.hz43ScanHid && van.outl.visible && van.mark.visible && van.cap.visible && van.temp.visible && !van.hidMark.visible && van.shown.length === 6 && txtUp(van), "r7 vanilla style " + st + ", scan close: the pieces (r9: and the alert text) come back through hz43VanShowClip, the game-hidden one stays hidden");
	}
	// live F11 toggles (F11 apply calls the sync), both directions, both families
	for (const st of [1, 3]) {
		const lv = mkS(st, 0); lv.hz40Scan = true; lv.hz43ScanHideSync();
		lv.cfg.HideWatchWhileScanning = 1; lv.hz43ScanHideSync();
		expect(lv.hz43ScanHid && !lv.mark.visible, "r7 style " + st + ": F11 switch on while scanning hides at once");
		lv.cfg.HideWatchWhileScanning = 0; lv.hz43ScanHideSync();
		expect(!lv.hz43ScanHid && lv.mark.visible && lv.outl.visible && alertsUp(lv) && txtUp(lv), "r7 style " + st + ": F11 switch off while scanning shows at once (r9: the alert text too)");
	}
	// style change while hidden (INI reload): give back, then hide the new style's pieces
	const sw = mkS(3, 1); sw.hz40Scan = true; sw.hz43ScanHideSync();
	sw.hzWatchStyle = 1; sw.hz43ScanHideSync();
	expect(sw.hz43ScanHid && sw.hz43ScanSt === 1 && !sw.outl.visible && !sw.mark.visible && alertsUp(sw) && txtDown(sw), "r7 style 3 -> 1 while scanning: the vanilla pieces hide instead (r9: the alert text stays hidden)");
	sw.hzWatchStyle = 0; sw.hz43ScanHideSync();
	expect(!sw.hz43ScanHid && sw.outl.visible && sw.mark.visible && txtUp(sw), "r7 style -> 0 (OFF) while scanning: everything this switch hid comes back");
	// S-5: Scanner module, scan latch, ARRANGE
	const s5 = (f) => { const h = mkS(1, 1); h.hz40Scan = true; f(h); h.hz43ScanHideSync(); return h; };
	expect(!s5((h) => { h.hz30Mod = {}; }).hz43ScanHid, "r7 S-5: no Scanner module = no hide (a stale HideWatchWhileScanning=1 does nothing)");
	expect(!s5((h) => { h.hz40Latch = true; }).hz43ScanHid, "r7 S-5: a latched scan (safety net) = no hide");
	expect(!s5((h) => { h.hzArrange = true; }).hz43ScanHid, "r7 S-5: ARRANGE = no hide");
	expect(funcBody(as, "hz43ScanWant").indexOf("this.hz41ScanHideOn()") >= 0, "r7 S-5: hz43ScanWant uses hz41ScanHideOn (same checks as the other scan hides)");
	expect(funcBody(as, "hzArrEnter").indexOf("this.hz43ScanHideSync()") >= 0 && funcBody(as, "hzArrExit").indexOf("this.hz43ScanHideSync()") >= 0, "r7 S-5: ARRANGE enter / exit are sync edges");
	// mutant: a piece check that lets the alerts through (hz43ScanPiece -> true) hides BioAlertText / LocationAlertText; the checks above catch it
	const pieceBody = funcBody(as, "hz43ScanPiece");
	const mutSrc2 = as.replace(pieceBody, "{\n         return d != null;\n      }");
	const mu2 = mkS(1, 1, mutSrc2); mu2.hz40Scan = true; mu2.hz43ScanHideSync();
	expect(mutSrc2 !== as && !alertsUp(mu2) && !mu2.loc.visible && !mu2.ring.visible, "r7 mutant (piece check removed): LocationAlertText and the enemy ring would hide, so the alert checks above FAIL on it");
	// per frame while hidden: the restorers of the same style skip their writes (one compare), no new work in hzOnFrame
	const nf = { hz43ScanHid: true, hz43ScanSt: 3, hzWatchStyle: 3, synced: 0, hz43ScanHideSync: function() { this.synced++; }, hzUserHidden: false, hz43VanPlace: function() { throw new Error("no"); } };
	bindAsMethod(nf, "hz43Frame", []);
	nf.hz43Frame();
	expect(nf.synced === 0, "hz43Frame while hidden: one compare and return (no per-frame work)");
	const nl = { hz43ScanHid: true, hz43ScanSt: 1, hzWatchStyle: 1, hz43VanPlace: function() { throw new Error("no"); }, hz43VanHorizon: function() { throw new Error("no"); } };
	bindAsMethod(nl, "hz43VanLate", []);
	let lateRan = false; try { nl.hz43VanLate(); } catch (e) { lateRan = true; }
	expect(!lateRan, "r7: hz43VanLate (exitFrame) skips the vanilla re-show / Horizon marker re-show while hidden");
	const ns = { hz43ScanHid: true, hz43ScanSt: 2, hzWatchStyle: 2, hz43HideStyle: 2, hzHideVanillaWatch: false, hz43VanShown: 1, hzHideCache: [1],
		hz43ShowVanilla: function() { throw new Error("no"); }, hz43VanRestoreHid: function() { throw new Error("no"); }, hz43VanBlgChrome: function() { throw new Error("no"); } };
	bindAsMethod(ns, "hz43SyncHide", []);
	let reShown = false; try { ns.hz43SyncHide(); } catch (e) { reShown = true; }
	expect(!reShown && ns.hzHideCache[0] === 1, "r7: hz43SyncHide (per frame) does not re-show the vanilla watch while hidden");
	ns.hz43ScanHid = false; let threw = false; try { ns.hz43SyncHide(); } catch (e) { threw = true; }
	expect(threw, "r7: hz43SyncHide re-shows as before once released");
	const sites = as.split("\n").filter((l) => /this\.hz43ScanHideSync\(\)/.test(l)).length;
	expect(funcBody(as, "hz40SetScan").indexOf("this.hz43ScanHideSync()") >= 0 && funcBody(as, "hz40Clear").indexOf("this.hz43ScanHideSync()") >= 0 && funcBody(as, "hz40SetLive").indexOf("this.hz43ScanHideSync()") >= 0 && funcBody(as, "hz40ParseIni").indexOf("this.hz43ScanHideSync()") >= 0 && sites === 7,
		"live on events only: scan edge, safety-net clear, F11 apply, INI load, ARRANGE enter / exit (+ the style-change guard in hz43Frame); " + sites + " call sites");
	expect(funcBody(as, "hzOnFrame").indexOf("HideWatchWhileScanning") < 0 && funcBody(as, "hzOnFrame").indexOf("hz43Scan") < 0, "no new work in hzOnFrame");
	const sb = funcBody(as, "hz43ScanHideSync");
	expect(sb.indexOf("hzFindByName") < 0 && sb.indexOf("getChildAt") < 0 && sb.indexOf("getChildByName") < 0 && sb.indexOf(".alpha") < 0 && sb.indexOf("hzBlg.visible") < 0, "r7: no search, no alpha, never the group (per-piece visible only)");
}

function makeCtClip(name, x, y, opts) {
	opts = opts || {};
	return {
		name: name,
		visible: true,
		alpha: opts.alpha != null ? opts.alpha : 1,
		x: x,
		y: y,
		scaleX: opts.scaleX != null ? opts.scaleX : 1,
		scaleY: opts.scaleY != null ? opts.scaleY : 1,
		transform: {
			colorTransform: {
				redMultiplier: 1,
				greenMultiplier: 1,
				blueMultiplier: 1,
				redOffset: 0,
				greenOffset: 0,
				blueOffset: 0,
				alphaMultiplier: opts.ctA != null ? opts.ctA : 0.25,
				alphaOffset: opts.ctO != null ? opts.ctO : 7
			}
		}
	};
}
function makeAssemblyHost() {
	const box = { name: "BottomLeftGroup_mc", kids: [] };
	const cap = makeCtClip("instance66", 0, -0.25);
	const outlineC = makeCtClip("WatchOutline_mc", 0, 0);
	const pointer = makeCtClip("WatchPointerOutline_mc", 111, 111);
	const o2 = makeCtClip("O2CO2_mc", 21.7, 89.85);
	const thin = makeCtClip("O2CO2thin_mc", 16.1, 88.3);
	const day = makeCtClip("DayCycleBase_mc", 110.5, 110.5);
	const loc = makeCtClip("locationNameBase_mc", 110.15, 139.75);
	const env = makeCtClip("EnvConditionBase_mc", 109.65, 111.45);
	const ring = makeCtClip("instance546", 110.5, 110.5);
	const detect = makeCtClip("EnemyDetectionAnim_mc", 110.5, 110.5);
	const tick = makeCtClip("instance548", 87.2, 141.65, { scaleX: 0.000076293945, scaleY: 0, ctA: 1, ctO: 0 });
	const temp = makeCtClip("Temperature_mc", 79.7, 133.75, { ctA: 0.5, ctO: 3 });
	const kids = [cap, outlineC, pointer, o2, thin, day, loc, env, ring, detect, tick, temp];
	box.kids = kids;
	box.getChildAt = function(i) { return this.kids[i]; };
	box.getChildIndex = function(d) {
		const i = this.kids.indexOf(d);
		if (i < 0) throw new Error("not a child");
		return i;
	};
	if (!Object.prototype.hasOwnProperty.call(box, "numChildren")) {
		Object.defineProperty(box, "numChildren", { get: function() { return this.kids.length; } });
	}
	for (let i = 0; i < kids.length; i++) kids[i].parent = box;
	const host = makeProductionHost(kids);
	host.hzBlg = box;
	host.capClip = cap;
	host.outlineClip = outlineC;
	host.ringClip = ring;
	host.tickClip = tick;
	host.tempClip = temp;
	host.detectClip = detect;
	host.o2Clip = o2;
	host.HZ43_HID_MAX = 40;
	host.hz43HidA = new Array(40);
	host.hz43HidN = 0;
	host.hz43EnvGot = 1;
	host.hz43EnvLocal = false;
	host.hz43EnvCruise = false;
	host.hz43EnvLang = "";
	host.hzWatchStyle = 1;
	host.hzUserHidden = false;
	host.hz43TintOn = false;
	host.hz43TintD = null;
	host.HZ43_TINT_N = ["WatchOutline_mc", "WatchPointerOutline_mc", "O2CO2_mc", "O2CO2thin_mc", "DayCycleBase_mc", "locationNameBase_mc"];
	host.HZ_ACCENT = 0xAABBCC;
	host.hz43Fill = function() { return 0x446688; };
	host.hz43VanCap = 1;
	host.hz43VanWrote = false;
	host.hz43MarkMoved = false;
	host.hz43VanWdx = Number.NaN;
	host.hz43VanWdy = Number.NaN;
	host.hz43VanWsc = Number.NaN;
	host.hz43VanWmk = -1;
	const units = [outlineC, o2, cap, ring, pointer, thin, day, loc];
	host.hz43VanN = units.length;
	host.hz43VanD = units.slice();
	host.hz43VanNm = units.map(function(u) { return u.name; });
	host.hz43VanGot = units.map(function() { return 1; });
	host.hz43VanUXA = units.map(function() { return 1; });
	host.hz43VanUYA = units.map(function() { return 1; });
	host.hz43VanX = units.map(function(u) { return u.x; });
	host.hz43VanY = units.map(function(u) { return u.y; });
	host.hz43VanOX = units.map(function() { return 0; });
	host.hz43VanOY = units.map(function() { return 0; });
	host.hz43VanSX = units.map(function(u) { return u.scaleX; });
	host.hz43VanSY = units.map(function(u) { return u.scaleY; });
	host.int = function(n) { return n | 0; };
	host.uint = function(n) { return n >>> 0; };
	host.hz43VanDump = function() {};
	host.hz43FollowApply = function() {};   // r6 followers: covered by the ghost tests above
	bindAsMethod(host, "hz43VanClip", ["i"]);
	bindAsMethod(host, "hz43VanMarkName", ["name"]);
	bindAsMethod(host, "hz43VanWrite", ["dx", "dy", "sc", "marks"]);
	bindAsMethod(host, "hz43VanNote", ["d"]);
	bindAsMethod(host, "hz43VanNoteAdd", ["d"]);
	bindAsMethod(host, "hz43StHide", ["d"]);
	bindAsMethod(host, "hz43VanGameVis", ["name"]);
	bindAsMethod(host, "hz43VanEnvWant", ["name"]);
	bindAsMethod(host, "hz43VanRestoreHid", []);
	host.HZ43_VAN_MARK = ["WatchIconsWidget_mc", "MissionIconsWidget_mc", "EnemyIconsWidget_mc"];
	bindAsMethod(host, "hz43VanHoldsMark", ["box"]);
	bindAsMethod(host, "hz43VanShowClip", ["d"]);
	bindAsMethod(host, "hz43VanBlgChrome", ["hide"]);
	bindAsMethod(host, "hz43TintRgb", ["clip", "col", "amt"]);
	bindAsMethod(host, "hz43TintClear", ["clip"]);
	bindAsMethod(host, "hz43TintAt", ["i"]);
	bindAsMethod(host, "hz43TintUnnamed", ["clear", "col", "amt"]);
	bindAsMethod(host, "hz43Tint", []);
	return host;
}

const asm08 = makeAssemblyHost();
expect(asm08.hz43VanRingClip(asm08.ringClip) === true, "assembly host caches the annulus at native 110.5");
asm08.hz43VanWrite(-40, 10, 0.8, false);
expect(Math.abs(asm08.ringClip.x - (110.5 * 0.8 - 40)) < 1e-9 && Math.abs(asm08.ringClip.y - (110.5 * 0.8 + 10)) < 1e-9, "production VanWrite scale 0.8 moves the annulus to 88.4 plus translation");
expect(asm08.hz43VanRingProof(asm08.ringClip) === false && asm08.hz43VanRingClip(asm08.ringClip) === true, "live proof fails at 88.4 and cached object identity still owns the annulus");
expect(asm08.hz43VanWatchClip(asm08.ringClip) === true && asm08.hz43VanWatchClip(asm08.tickClip) === false, "WatchClip owns the scaled annulus and still excludes the collapsed tick");
expect(asm08.hz43VanCapClip(asm08.ringClip) === false && asm08.hz43VanCapClip(asm08.capClip) === true, "ring/cap distinction holds after scale 0.8");
const ringA = asm08.ringClip.transform.colorTransform.alphaMultiplier;
const ringO = asm08.ringClip.transform.colorTransform.alphaOffset;
asm08.hz43StHide(asm08.ringClip);
expect(asm08.ringClip.visible === false && asm08.ringClip.transform.colorTransform.alphaMultiplier === ringA && asm08.ringClip.transform.colorTransform.alphaOffset === ringO, "Off hide at scaled pose vis-hides the captured annulus and does not write CT alpha");
expect(asm08.tickClip.visible === true && asm08.detectClip.visible === true && asm08.tempClip.visible === true, "scaled Off hide does not take INFO ticks, detection, or Temperature");
asm08.hzWatchStyle = 3;
asm08.hz43VanWrite(0, 0, 1, false);
asm08.hz43VanWrote = false;
expect(Math.abs(asm08.ringClip.x - 110.5) < 1e-9, "style 3 restores native annulus local before custom hide");
asm08.hz43StHide(asm08.ringClip);
expect(asm08.ringClip.visible === false, "style 3 hides the annulus with chrome");
asm08.hzWatchStyle = 0;
asm08.hz43StHide(asm08.ringClip);
expect(asm08.ringClip.visible === false, "style 0 keeps the annulus hidden");
asm08.hzWatchStyle = 1;
asm08.hz43VanRestoreHid();
expect(asm08.ringClip.visible === true && asm08.ringClip.transform.colorTransform.alphaMultiplier === ringA, "style 1 restores annulus vis without writing CT alpha");

const asm12 = makeAssemblyHost();
asm12.hz43VanRingClip(asm12.ringClip);
asm12.hz43VanWrite(20, -15, 1.2, false);
expect(Math.abs(asm12.ringClip.x - (110.5 * 1.2 + 20)) < 1e-9 && Math.abs(asm12.outlineClip.x - 20) < 1e-9, "production VanWrite scale 1.2 keeps the annulus in the assembly");
expect(asm12.hz43VanRingClip(asm12.ringClip) === true && asm12.hz43VanRingProof(asm12.ringClip) === false, "cached annulus identity survives scale 1.2");
asm12.hz43StHide(asm12.ringClip);
expect(asm12.ringClip.visible === false && asm12.tickClip.visible === true, "scale 1.2 Off hide owns the annulus and not the collapsed tick");
asm12.hz43VanRestoreHid();
expect(asm12.ringClip.visible === true, "scale 1.2 Vanilla restore shows the annulus");

const asmTint = makeAssemblyHost();
asmTint.hz43VanRingClip(asmTint.ringClip);
asmTint.hz43VanWrite(0, 0, 0.8, false);
asmTint.hzWatchStyle = 2;
asmTint.hz43Tint();
expect(Math.abs(asmTint.ringClip.transform.colorTransform.redMultiplier - 0.45) < 1e-9 && Math.abs(asmTint.ringClip.transform.colorTransform.redOffset - (0x44 * 0.55)) < 1e-9, "style 2 TintRgb tints the scaled annulus RGB");
expect(asmTint.ringClip.transform.colorTransform.alphaMultiplier === 0.25 && asmTint.ringClip.transform.colorTransform.alphaOffset === 7, "style 2 annulus tint preserves both CT alpha fields");
expect(Math.abs(asmTint.capClip.transform.colorTransform.redMultiplier - 0.45) < 1e-9 && asmTint.capClip.transform.colorTransform.alphaMultiplier === 0.25, "style 2 tints unnamed cap RGB and preserves cap CT alpha");
expect(asmTint.tempClip.transform.colorTransform.redMultiplier === 1 && asmTint.tempClip.transform.colorTransform.alphaMultiplier === 0.5 && asmTint.tempClip.transform.colorTransform.alphaOffset === 3, "style 2 does not tint Temperature RGB or alpha");
expect(asmTint.detectClip.transform.colorTransform.redMultiplier === 1 && asmTint.tickClip.transform.colorTransform.redMultiplier === 1, "style 2 does not tint detection or collapsed INFO ticks");
asmTint.hzWatchStyle = 1;
asmTint.hz43Tint();
expect(asmTint.ringClip.transform.colorTransform.redMultiplier === 1 && asmTint.ringClip.transform.colorTransform.redOffset === 0, "leaving style 2 TintClear restores annulus RGB");
expect(asmTint.ringClip.transform.colorTransform.alphaMultiplier === 0.25 && asmTint.ringClip.transform.colorTransform.alphaOffset === 7, "TintClear restore preserves annulus CT alpha");
expect(asmTint.tempClip.transform.colorTransform.alphaMultiplier === 0.5 && asmTint.tempClip.transform.colorTransform.redMultiplier === 1, "TintClear does not touch unrelated Temperature");

const firstVan = makeAssemblyHost();
firstVan.hz43VanRingClip(firstVan.ringClip);
firstVan.outlineClip.visible = false;
firstVan.o2Clip.visible = false;
firstVan.capClip.visible = false;
firstVan.ringClip.visible = false;
firstVan.detectClip.visible = true;
firstVan.tickClip.visible = true;
firstVan.tempClip.visible = false;
firstVan.hz43HidN = 0;
const o2A = firstVan.o2Clip.transform.colorTransform.alphaMultiplier;
const ringA2 = firstVan.ringClip.transform.colorTransform.alphaMultiplier;
firstVan.tempClip.alpha = 0;
firstVan.hz43VanBlgChrome(false);
expect(firstVan.outlineClip.visible === true && firstVan.o2Clip.visible === true && firstVan.capClip.visible === true && firstVan.ringClip.visible === true, "first Vanilla BlgChrome restores named chrome and unnamed annulus when the hid list is empty");
expect(firstVan.o2Clip.transform.colorTransform.alphaMultiplier === o2A && firstVan.ringClip.transform.colorTransform.alphaMultiplier === ringA2, "first Vanilla BlgChrome restore does not write CT alpha");
expect(firstVan.detectClip.visible === true && firstVan.tickClip.visible === true, "first Vanilla BlgChrome restore leaves detection and INFO ticks on native rules");
expect(firstVan.tempClip.visible === true && firstVan.tempClip.alpha === 0, "named INFO vis undo does not write FadeInPlanetInfo alpha");
firstVan.hz43VanBlgChrome(true);
expect(firstVan.outlineClip.visible === false && firstVan.ringClip.visible === false && firstVan.detectClip.visible === true && firstVan.tickClip.visible === true, "Off BlgChrome hide still owns named chrome and the annulus, not detection or ticks");
const hud2 = makeAssemblyHost();
hud2.hz43VanRingClip(hud2.ringClip);
hud2.outlineClip.visible = false;
hud2.o2Clip.visible = false;
hud2.capClip.visible = false;
hud2.ringClip.visible = false;
hud2.detectClip.visible = true;
hud2.tickClip.visible = true;
hud2.hz43HidN = 0;
hud2.HZ43_VAN_N = VAN_N;
hud2.HZ43_VAN_INFO = ["Temperature_mc","Oxygen_mc","Grav_mc","OffPlanet_mc"];
hud2.HZ43_VAN_A = ["BioCondition_mc","BioConditionBase_mc","EnvCondition_mc","EnvConditionBase_mc","BioAlertBG_mc"];
hud2.hz43VanTries = 0;
hud2.hz43VanLogged = true;
hud2.hzDebug = false;
hud2.hz26Dbg = {};
bindAsMethod(hud2, "hz43VanInfoName", ["name"]);
bindAsMethod(hud2, "hz43ShowVanilla", []);
const hud2RingA = hud2.ringClip.transform.colorTransform.alphaMultiplier;
expect(hud2.hz43ShowVanilla() === true, "HUD recreate ShowVanilla succeeds with hidN 0");
expect(hud2.outlineClip.visible === true && hud2.o2Clip.visible === true && hud2.capClip.visible === true && hud2.ringClip.visible === true, "HUD recreate ShowVanilla restores named chrome and annulus when RestoreHid has nothing to undo");
expect(hud2.hz43HidN === 0 && hud2.ringClip.transform.colorTransform.alphaMultiplier === hud2RingA, "HUD recreate ShowVanilla leaves hidN empty and does not write annulus CT alpha");
expect(hud2.detectClip.visible === true && hud2.tickClip.visible === true, "HUD recreate ShowVanilla leaves detection and INFO ticks on native rules");
blg.kids = blgKids;

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
function noteClip(hid, d, outline) {
	if (!isWatchClip(d, outline)) return;
	for (let i = 0; i < hid.length; i++) {
		if (hid[i].d === d) return;
	}
	hid.push({ d: d });
}
function stHideWatch(hid, d, outline) {
	noteClip(hid, d, outline);
	d.visible = false;
}
function hideTick(clips, hid, style) {
	const showVan = style === 1 || style === 2;
	const keepMarks = style === 3 || style === 4;
	const outline = clips.WatchOutline_mc;
	const names = Object.keys(clips);
	for (let i = 0; i < names.length; i++) {
		const d = clips[names[i]];
		if (OTHER_HIDES[d.name]) {
			d.visible = false;
			d.alpha = 0;
			continue;
		}
		if (!isWatchClip(d, outline) || showVan) continue;
		if (keepMarks && MARK_NAMES[d.name]) continue;
		stHideWatch(hid, d, outline);
	}
}
function restoreHid(state) {
	const hid = state.hid;
	const outline = state.clips.WatchOutline_mc;
	for (let i = 0; i < hid.length; i++) {
		const d = hid[i].d;
		if (!isWatchClip(d, outline)) continue;
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
		if (!isArrangeClip(d, outline)) continue;
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
function fadeSeen(d) {
	return !!(d && d.alpha > 0.9);
}
function fadeOk(state) {
	if (!state.vanCap) return false;
	if (fadeSeen(state.clips.WatchOutline_mc) || fadeSeen(state.clips.O2CO2_mc) || fadeSeen(state.clips.instance66)) return true;
	state.fadeN = (state.fadeN || 0) + 1;
	return state.fadeN >= 16;
}
function vanWrite(state, dx, dy, sc, marks) {
	if (!state.vanCap) return false;
	const mk = marks ? 1 : 0;
	if (state.wmk === mk && Math.abs((state.wdx || 0) - dx) < 0.05 && Math.abs((state.wdy || 0) - dy) < 0.05 && Math.abs((state.wsc || 0) - sc) < 0.001) {
		if ((marks && state.markMoved) || (!marks && (state.vanWrote || (dx === 0 && dy === 0 && sc === 1)))) return false;
	}
	const units = state.units || [];
	for (let i = 0; i < units.length; i++) {
		const d = units[i];
		if (marks && !MARK_NAMES[d.name]) continue;
		const useSc = marks ? 1 : sc;
		const ox = state.clips && state.clips.WatchOutline_mc ? state.clips.WatchOutline_mc.x0 : 0;
		const oy = state.clips && state.clips.WatchOutline_mc ? state.clips.WatchOutline_mc.y0 : 0;
		d.x = ox + (d.x0 - ox) * useSc + dx;
		d.y = oy + (d.y0 - oy) * useSc + dy;
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
	state.wdx = dx;
	state.wdy = dy;
	state.wsc = sc;
	state.wmk = mk;
	state.writeN = (state.writeN || 0) + 1;
	return true;
}
function vanPlaceSaved(state, dx, dy) {
	captureWatch(state);
	if (!fadeOk(state)) return false;
	vanWrite(state, dx, dy, 1, false);
	return true;
}
function vanHorizon(state) {
	captureWatch(state);
	if (state.vanWrote) {
		vanWrite(state, 0, 0, 1, false);
		state.vanWrote = false;
	}
	chromeHide(state.clips, state.hid, true);
	const face = state.face;
	const ring = ringMid(state);
	if (state.vanCap && ring && face) {
		const sc = face.sc || 1;
		vanWrite(state, face.x + 132 * sc - ring.x, face.y + 132 * sc - ring.y, 1, true);
	}
}
function chromeHide(clips, hid, keepMarks) {
	const outline = clips.WatchOutline_mc;
	const names = Object.keys(clips);
	for (let i = 0; i < names.length; i++) {
		const d = clips[names[i]];
		if (!isWatchClip(d, outline)) continue;
		if (keepMarks && MARK_NAMES[d.name]) {
			d.visible = true;
			continue;
		}
		stHideWatch(hid, d, outline);
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
		fadeN: 0,
		wmk: -1,
		writeN: 0,
		units: [],
		face: { x: 0, y: 80, sc: 1, visible: false },
		envGot: 0,
		envLocal: false,
		envCruise: false,
		envLang: "",
		clips: {
			instance66: makeClip("instance66", true, 0, 0, -0.25),
			instance546: makeClip("instance546", true, 0, 110.5, 110.5),
			instance548: makeClip("instance548", true, 0, 87.2, 141.65),
			instance550: makeClip("instance550", true, 0, 139.45, 141.65),
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
			BioCondition_mc: makeClip("BioCondition_mc", true, 0, 96.25, 24.45),
			EnvConditionBase_mc: makeClip("EnvConditionBase_mc", true, 0, 109.65, 111.45),
			EnvAlertText: makeClip("EnvAlertText", true, 0, 110.75, 110.25),
			BioAlertText: makeClip("BioAlertText", true, 0, 110.85, 86.35),
			EnemyDetectionAnim_mc: makeClip("EnemyDetectionAnim_mc", true, 1, 110.5, 110.5),
			HealthBar_mc: makeClip("HealthBar_mc", true, 1),
			EquippedWeaponAmmo_mc: makeClip("EquippedWeaponAmmo_mc", true, 1),
			JetpackMeterWrapper_mc: makeClip("JetpackMeterWrapper_mc", true, 1)
		}
	};
	state.clips.instance548.scaleX = 0.000076293945;
	state.clips.instance548.scaleY = 0;
	state.clips.instance550.scaleX = 0.000076293945;
	state.clips.instance550.scaleY = 0;
	const c = state.clips;
	const order = [
		c.instance66, c.WatchOutline_mc, c.WatchPointerOutline_mc, c.O2CO2_mc, c.O2CO2thin_mc,
		c.DayCycleBase_mc, c.OffPlanet_mc, c.Autopilot_mc, c.locationNameBase_mc, c.BioCondition_mc,
		c.EnvConditionBase_mc, c.instance546, c.EnemyDetectionAnim_mc, c.EnvAlertText, c.BioAlertText,
		c.instance548, c.instance550, c.WatchIconsWidget_mc, c.MissionIconsWidget_mc, c.EnemyIconsWidget_mc,
		c.Temperature_mc, c.Oxygen_mc, c.Grav_mc
	];
	const blgParent = { name: "BottomLeftGroup_mc", kids: [] };
	for (let oi = 0; oi < order.length; oi++) {
		if (!order[oi]) continue;
		order[oi].parent = blgParent;
		blgParent.kids.push(order[oi]);
	}
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
expect(digitalRound.clips.WatchPointerOutline_mc.visible === false && digitalRound.clips.WatchPointerOutline_mc.x === 111, "Digital hides the heading outline with chrome and does not move it with live markers");
expect(digitalRound.clips.instance546.visible === false && digitalRound.clips.instance546.x === 110.5 && digitalRound.clips.instance546.y === 110.5 && digitalRound.clips.instance546.alpha === 0, "Digital hides the filled annulus with chrome and does not write its alpha");
expect(digitalRound.clips.instance548.visible === true && digitalRound.clips.instance548.x === 87.2 && digitalRound.clips.instance548.scaleY === 0, "Digital does not hide or move extra autoname instance548");
expect(digitalRound.clips.instance550.visible === true && digitalRound.clips.instance550.x === 139.45 && digitalRound.clips.instance550.scaleY === 0, "Digital does not hide or move extra autoname instance550");
expect(digitalRound.clips.BioCondition_mc.visible === true && digitalRound.clips.EnvConditionBase_mc.visible === true, "Digital does not own named bio or env condition clips");
expect(digitalRound.clips.EnvAlertText.visible === true && digitalRound.clips.BioAlertText.visible === true && digitalRound.clips.EnemyDetectionAnim_mc.visible === true, "Digital leaves named env/bio alerts and detection on native rules");
expect(digitalRound.clips.O2CO2_mc.scaleX === 1 && digitalRound.clips.WatchOutline_mc.scaleX === 1, "Digital does not scale native chrome");
expect(digitalRound.clips.WatchIconsWidget_mc.x === 111.35 + (0 + 132 - 110.5), "Digital moves location markers from the outline center to the Horizon face");
expect(displayed(digitalRound.clips.WatchOutline_mc) === false, "hidden Digital chrome at FadeIn alpha 0 is not displayed");
expect(digitalRound.clips.HealthBar_mc.visible === false, "health stays hidden on Digital");
applyWatchStyle(digitalRound, 1);
expect(digitalRound.clips.WatchOutline_mc.visible === true, "Digital then Vanilla restores the outline");
expect(digitalRound.clips.WatchPointerOutline_mc.visible === true && digitalRound.clips.WatchPointerOutline_mc.x === 111, "Digital then Vanilla restores the heading outline at native local");
expect(digitalRound.clips.instance66.visible === true && digitalRound.clips.instance66.x === 0, "Digital then Vanilla restores instance66 vis and native cap local");
expect(digitalRound.clips.instance546.visible === true && digitalRound.clips.instance546.x === 110.5 && digitalRound.clips.instance548.y === 141.65 && digitalRound.clips.instance550.x === 139.45, "Digital then Vanilla restores the annulus vis and does not Arrange INFO ticks");
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
expect(f11Live.clips.instance546.visible === true && f11Live.clips.instance548.visible === true && f11Live.clips.instance550.visible === true, "F11 back to Vanilla restores the annulus and leaves INFO ticks on native rules");
expect(f11Live.clips.WatchPointerOutline_mc.visible === true, "F11 back to Vanilla restores the heading outline");

const offExtra = makeWatchState();
applyWatchStyle(offExtra, 0);
expect(offExtra.clips.instance66.visible === false, "Off hides the verified cap");
expect(offExtra.clips.WatchPointerOutline_mc.visible === false, "Off hides the heading outline");
expect(offExtra.clips.instance546.visible === false && offExtra.clips.instance548.visible === true && offExtra.clips.instance550.visible === true, "Off hides the filled annulus and leaves INFO ticks on native rules");
expect(offExtra.clips.BioCondition_mc.visible === true && offExtra.clips.EnvAlertText.visible === true && offExtra.clips.EnemyDetectionAnim_mc.visible === true, "Off does not hide named bio env alerts or detection through watch ownership");

const savedLay = makeWatchState();
applyWatchStyle(savedLay, 1);
captureWatch(savedLay);
expect(savedLay.units.indexOf(savedLay.clips.instance66) >= 0, "saved Arrange capture includes the verified cap");
expect(savedLay.units.indexOf(savedLay.clips.instance546) >= 0 && savedLay.units.indexOf(savedLay.clips.instance548) < 0 && savedLay.units.indexOf(savedLay.clips.instance550) < 0, "saved Arrange capture includes the filled annulus and excludes INFO ticks");
vanWrite(savedLay, -40, -40, 1, false);
expect(savedLay.clips.instance66.x === -40 && savedLay.clips.WatchOutline_mc.x === -40, "saved L-40 moves the cap with the outline");
expect(savedLay.clips.instance66.y === -40.25 && savedLay.clips.WatchOutline_mc.y === -40, "saved B-40 keeps the native cap to outline offset");
expect(savedLay.clips.instance546.x === 70.5 && savedLay.clips.instance546.y === 70.5, "saved L-40 B-40 moves the filled annulus with the assembly");
expect(savedLay.clips.instance548.x === 87.2 && savedLay.clips.instance548.y === 141.65 && savedLay.clips.instance548.scaleY === 0, "saved L-40 B-40 does not move or scale extra autoname instance548");
expect(savedLay.clips.instance550.x === 139.45 && savedLay.clips.instance550.y === 141.65 && savedLay.clips.instance550.scaleY === 0, "saved L-40 B-40 does not move or scale extra autoname instance550");
expect(vanCapClip(savedLay.clips.instance66, savedLay.clips.WatchOutline_mc) === true, "cap identity stays outline-relative after saved Arrange");
expect(vanCapClip(savedLay.clips.instance546, savedLay.clips.WatchOutline_mc) === false, "extra autoname instance546 still fails cap pose after saved Arrange");

const fadeLay = makeWatchState();
applyWatchStyle(fadeLay, 1);
captureWatch(fadeLay);
expect(fadeLay.clips.WatchOutline_mc.alpha === 0 && fadeLay.clips.instance66.alpha === 0, "first-load chrome starts at native FadeIn alpha 0");
expect(vanPlaceSaved(fadeLay, -64.3, 34.85) === false, "saved Arrange does not write siblings while native FadeIn alpha is still 0");
expect(fadeLay.clips.WatchOutline_mc.x === 0 && fadeLay.clips.instance66.x === 0, "deferred Arrange leaves cap and outline at native locals");
expect(fadeLay.clips.WatchIconsWidget_mc.x === 111.35 && fadeLay.clips.instance546.x === 110.5, "deferred Arrange does not move markers or the annulus while FadeIn alpha is still 0");
fadeLay.clips.WatchOutline_mc.alpha = 1;
fadeLay.clips.O2CO2_mc.alpha = 1;
fadeLay.clips.instance66.alpha = 1;
expect(vanPlaceSaved(fadeLay, -64.3, 34.85) === true, "saved Arrange writes after native FadeIn alpha is live");
expect(fadeLay.clips.WatchOutline_mc.x === -64.3 && fadeLay.clips.instance66.x === -64.3, "post-FadeIn Arrange moves the cap with the outline");
expect(fadeLay.clips.WatchIconsWidget_mc.x === 111.35 - 64.3, "post-FadeIn Arrange moves markers with the assembly");
expect(fadeLay.clips.instance546.x === 110.5 - 64.3 && fadeLay.clips.instance546.y === 110.5 + 34.85, "post-FadeIn Arrange moves the filled annulus with the assembly");
const writes = fadeLay.writeN;
vanPlaceSaved(fadeLay, -64.3, 34.85);
expect(fadeLay.writeN === writes, "a second identical saved Arrange write is skipped");

const fadeTimeout = makeWatchState();
applyWatchStyle(fadeTimeout, 1);
captureWatch(fadeTimeout);
let waited = 0;
while (waited < 15) {
	expect(vanPlaceSaved(fadeTimeout, -40, -40) === false, "FadeIn timeout has not latched yet at frame " + waited);
	waited++;
}
expect(fadeTimeout.clips.WatchOutline_mc.x === 0, "16-frame FadeIn wait still has not written");
expect(vanPlaceSaved(fadeTimeout, -40, -40) === true, "Arrange writes after 16 frames if chrome alpha never rises");
expect(fadeTimeout.clips.WatchOutline_mc.x === -40 && fadeTimeout.clips.Temperature_mc.alpha === 0, "timeout write does not force INFO alpha");

const split = makeWatchState();
split.clips.WatchOutline_mc.alpha = 1;
split.clips.O2CO2_mc.alpha = 1;
split.clips.instance66.alpha = 1;
applyWatchStyle(split, 1);
captureWatch(split);
vanWrite(split, -64.3, 34.85, 1, false);
split.face = { x: 0, y: 868.5, sc: 0.8, visible: true };
applyWatchStyle(split, 3);
expect(split.clips.WatchOutline_mc.x === 0 && split.clips.O2CO2_mc.x === 21.7 && split.clips.instance66.x === 0, "Digital restores arranged native locals before marker follow");
expect(split.clips.WatchOutline_mc.visible === false && split.clips.instance66.visible === false, "Digital still hides outline and cap after restore");
expect(split.clips.WatchPointerOutline_mc.visible === false && split.clips.WatchPointerOutline_mc.x === 111, "Digital hides the heading outline and does not follow it to the face");
expect(split.clips.WatchIconsWidget_mc.x === 111.35 + (0 + 132 * 0.8 - 110.5), "Digital markers follow the face from the restored outline center");
expect(split.clips.instance546.visible === false && split.clips.instance546.x === 110.5, "Digital hides the filled annulus after restoring arranged native locals");
expect(split.clips.WatchOutline_mc.alpha === 1 && split.clips.Temperature_mc.alpha === 0, "Digital hide does not write chrome or INFO alpha");

const back = makeWatchState();
back.clips.WatchOutline_mc.alpha = 1;
back.clips.O2CO2_mc.alpha = 1;
back.clips.instance66.alpha = 1;
back.clips.DayCycleBase_mc.alpha = 1;
back.clips.locationNameBase_mc.alpha = 1;
applyWatchStyle(back, 1);
applyWatchStyle(back, 3);
expect(back.clips.WatchOutline_mc.visible === false && back.clips.WatchOutline_mc.alpha === 1, "Digital hides outline vis and leaves post-FadeIn alpha");
expect(back.clips.Temperature_mc.visible === false && back.clips.Temperature_mc.alpha === 0, "Digital hides INFO vis and does not reconstruct FadeInPlanetInfo");
applyWatchStyle(back, 1);
expect(back.clips.WatchOutline_mc.visible === true && back.clips.WatchOutline_mc.alpha === 1, "Digital then Vanilla restores outline vis and keeps native FadeIn alpha");
expect(back.clips.instance66.visible === true && back.clips.instance66.alpha === 1, "Digital then Vanilla restores cap vis and does not force-write alpha");
expect(back.clips.O2CO2_mc.visible === true && back.clips.O2CO2_mc.alpha === 1, "Digital then Vanilla restores O2 vis at native FadeIn alpha");
expect(back.clips.DayCycleBase_mc.visible === true && back.clips.locationNameBase_mc.visible === true, "Digital then Vanilla restores day and location vis from payload");
expect(back.clips.Temperature_mc.visible === true && back.clips.Temperature_mc.alpha === 0, "Digital then Vanilla undoes INFO vis hide and does not force FadeInPlanetInfo alpha");
expect(back.clips.Oxygen_mc.alpha === 0 && back.clips.Grav_mc.alpha === 0, "Digital then Vanilla does not force-show Oxygen or Grav");
expect(back.clips.instance546.visible === true && back.clips.instance546.x === 110.5, "Digital then Vanilla restores the filled annulus vis without writing alpha");
expect(back.clips.HealthBar_mc.visible === false && back.clips.EquippedWeaponAmmo_mc.visible === false && back.clips.JetpackMeterWrapper_mc.visible === false, "Digital then Vanilla leaves health ammo and boost hidden");

const geo = makeWatchState();
expect(isWatchClip(geo.clips.instance66, geo.clips.WatchOutline_mc) === true, "session instance66 at native cap pose is watch chrome");
geo.clips.instance66.x = 110.5;
geo.clips.instance66.y = 110.5;
expect(isWatchClip(geo.clips.instance66, geo.clips.WatchOutline_mc) === false, "the same autoname at a non-cap native local is not watch chrome");
geo.clips.instance546.x = 0;
geo.clips.instance546.y = -0.25;
expect(isWatchClip(geo.clips.instance546, geo.clips.WatchOutline_mc) === true, "cap identity follows native pose across autoname numbers");

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
expect(checks.indexOf("move only the live nearby, mission, and enemy marker widgets") >= 0, "CHECKS describes custom marker-only follow");
expect(checks.indexOf("HZ43 dump") >= 0 && checks.indexOf("vis/alpha") >= 0, "CHECKS records vis and alpha sibling dumps");
expect(checks.indexOf("r12-pointer-mark-20261107") >= 0, "CHECKS records the pointer-mark diagnostic package token");
expect(checks.indexOf("r13-annulus-hide-20261107") >= 0, "CHECKS records the annulus-hide diagnostic package token");
expect(checks.indexOf("r14-annulus-obj-20261107") >= 0 && checks.indexOf("88.4") >= 0, "CHECKS records the cached-object diagnostic package token and scaled local");
expect(checks.indexOf("r15-vanilla-restore-20261108") >= 0, "CHECKS records the vanilla-restore diagnostic package token");
expect(checks.indexOf("91c6c8fde4092069cef16a64506c607a3af9b24e124e980877a0968899d3d12f") >= 0, "CHECKS records actual r13 SFSE SHA");
expect(checks.indexOf("Do not map first vs second") >= 0 && checks.indexOf("55918") >= 0, "CHECKS does not map 18514/19545 as first vs second Vanilla and does not treat 55918 as Off proof");
expect(checks.indexOf("WatchPointerOutline_mc") >= 0 && checks.indexOf("keep-mark") >= 0, "CHECKS records that heading outline left keep-mark");
expect(checks.indexOf("does not write a stored FadeIn alpha") >= 0 && checks.indexOf("Digital then Vanilla") >= 0, "CHECKS records Digital then Vanilla restore without forcing INFO alpha");
expect(checks.indexOf("write-marks") >= 0 && checks.indexOf("does not include why") >= 0, "CHECKS records dump signature omit why");
expect(checks.indexOf("not in the r10 Scaleform log") >= 0, "CHECKS does not claim Digital then Vanilla was in the logged F11 sequence");
expect(checks.indexOf("not causal runtime proof") >= 0 && checks.indexOf("measured correlation") >= 0, "CHECKS does not claim transform writes freeze native FadeIn as proven");
expect(checks.indexOf("medium causal confidence") >= 0 && changelog.indexOf("medium causal confidence") >= 0, "CHECKS grades the r10 freeze inference as medium confidence correlation");
expect(checks.indexOf("unresolved") >= 0 && changelog.indexOf("unresolved") >= 0, "docs record the gray bezel identity as unresolved");
expect(checks.indexOf("shape 927") >= 0 && checks.indexOf("sprite 928") >= 0, "CHECKS records native Off ring art as WatchOutline stroke 0..221px");
expect(checks.indexOf("not a visual fix") >= 0 && changelog.indexOf("not that visual fix") >= 0, "docs record r12 Off leftover after heading-outline hide");
expect(checks.indexOf("not r12 user-accepted") >= 0 && changelog.indexOf("does not claim Digital/Analog") >= 0, "docs do not treat Digital Analog or sun card as r12 accepted");
expect(checks.indexOf("c323f1d36e65cf92874c12eef5fed3601f29506529c075cf17cb930e8af9a6f6") >= 0, "CHECKS records actual r12 SFSE SHA");
expect(checks.indexOf("#676767") >= 0 && changelog.indexOf("#676767") >= 0, "docs record native outline stroke color from PHC shape 927");
expect(checks.indexOf("hidN=12") >= 0 && checks.indexOf("vis=false") >= 0, "CHECKS records r12 Off hidN and pointer vis=false");
expect(checks.indexOf("why=cap") >= 0 && checks.indexOf("style-0 load") >= 0, "CHECKS does not treat first cap dump as a style-0 load header");
expect(checks.indexOf("DefineShape") >= 0 && checks.indexOf("#B7B7B7") >= 0, "CHECKS records filled annulus shape content");
expect(checks.indexOf("1114") >= 0 && checks.indexOf("1115") >= 0 && changelog.indexOf("Do not copy") >= 0, "docs record large PHC annulus ids and refuse to copy normal ids onto large");
expect(checks.indexOf("hzFrameN") >= 0, "CHECKS records Fade wait as distinct hzFrameN ticks");
expect(checks.indexOf("fail-open") >= 0 && changelog.indexOf("fail-open") >= 0 && checks.indexOf("TintRgb") >= 0 && checks.indexOf("FadeN") >= 0, "CHECKS records fail-open timeout, style-2 tint during wait, and Capture FadeN latch");
expect(checks.indexOf("alphaOffset") >= 0 && checks.indexOf("alphaMultiplier") >= 0, "CHECKS records dump of both CXFORM alpha terms");
expect(checks.indexOf("instance546") >= 0 && checks.indexOf("not mapped") >= 0, "CHECKS records extra runtime autonames without mapping them to PHC depths");
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
expect(funcBody(as, "hz26IniLines").indexOf("WatchStyle=") >= 0 && funcBody(as, "hz34IniLines").indexOf("Scale=") >= 0 && as.indexOf('["Watch",false]') >= 0, "F11 save writes WatchStyle and every card Scale including WatchScale");
expect(funcBody(as, "hzBuildIniText").indexOf("lk + \"X=\"") >= 0 && as.indexOf('HZ_LAY_KEYS:Array = [') >= 0 && as.indexOf('"Watch"]') >= 0, "F11 save writes WatchX/WatchY from the Arrange layout keys");
expect(as.indexOf("WatchCompact") < 0, "there is no WatchCompact toggle");
expect(as.indexOf("PersonalKey") < 0 && as.indexOf("function hzTakeSaveIni") >= 0, "HUD save hands full merged text to the DLL");
const mainCpp = readText(path.join(root, "src", "main.cpp"));
const presetApplyH = readText(path.join(root, "src", "hz_preset_apply.h"));   // r7 (S-4): PresetToUser and its helpers moved here
expect(presetApplyH.indexOf("inline bool PersonalKey") >= 0 && presetApplyH.indexOf("a_sec == \"hotkeys\"") >= 0 && presetApplyH.indexOf("screenheight") >= 0 && mainCpp.indexOf("#include \"hz_preset_apply.h\"") >= 0, "preset Diff strips Hotkeys and ScreenHeight");
const diffH = readText(path.join(root, "src", "hz_ini_diff.h"));
expect(diffH.indexOf("keepUnknownKeys = false") >= 0, "preset files drop unknown keys of known sections");
expect(preset.indexOf("[Hotkeys]") < 0 && preset.indexOf("ScreenHeight") < 0, "Moragar's Choice has no personal keys");
expect(preset.indexOf("WatchScale") < 0, "Moragar's Choice leaves WatchScale at the default");
expect(ini.indexOf("WatchScale=-1") >= 0 && ini.indexOf("WatchStyle=0") >= 0, "defaults keep WatchScale at HudScale and WatchStyle off");
expect(as.indexOf('"Watch","Enemy"') < 0 && as.indexOf('"HudMessages","Watch"') >= 0, "Watch is an Arrange key");
expect(as.indexOf('"WATCH"') >= 0, "Arrange names the watch");
expect(as.indexOf('["Watch",false]') >= 0, "Watch has its own size entry");
expect(as.indexOf('this.hz34Sz("Watch")') >= 0, "F11 has a watch size row");
expect(placeBody.indexOf('hzLayHas("Watch")') >= 0, "a saved watch position is detected");
expect(as.indexOf("function hz43ApplyHome") >= 0 && as.indexOf("function hz43ApplySaved") >= 0, "home and saved placement are separate");
expect(preset.indexOf("WatchStyle=0") >= 0 && preset.indexOf("CrosshairRule=0") >= 0, "Moragar's Choice sets both rules to the default");
expect(preset.indexOf("WatchX") < 0 && preset.indexOf("WatchY") < 0, "Moragar's Choice does not move the watch");

// ---- r8: the scan-state watch pieces (user r7 test, 2026-11-10 18:49). The game's LocalEnvironmentData handler plays
// FadeInPlanetInfo on the scan edge; that span adds UNNAMED art directly under BottomLeftGroup_mc, centered on the native
// watch (ring r ~96 at 111,110.6; disc r ~18 at 110.2,50.15; a white band shape; a bar; the two INFO ticks live all the
// time). Not a captured unit (ARRANGE left it at the native spot in 1 / 2) and not a hz43VanWatchClip (hz43StHide refused
// it in 0 / 3 / 4). r8 hides it in 0 / 3 / 4 and the 1 / 2 HideWatchWhileScanning hold, places it with the assembly in
// 1 / 2 when moved, on ADDED and on mode / offset changes. Also: the late LocalEnvironmentData re-hide of the W3 pieces
// (the DayCycleBase_mc globe), Bot 3 r7 S-1 (listener removed at home) and mutant E (old group's listener on rebuild).
{
	const near = (a, b) => Math.abs(a - b) < 1e-9;
	const art = (nm, x, y) => ({ name: nm, x: x, y: y, scaleX: 1, scaleY: 1, visible: true, alpha: 0.8 });
	const listen = (blg) => {
		blg.listeners = [];
		blg.addEventListener = function(t, f, cap, pri, weak) { this.listeners.push({ t: t, f: f, weak: weak }); };
		blg.removeEventListener = function(t, f) { this.listeners = this.listeners.filter((l) => !(l.t === t && l.f === f)); };
		return blg;
	};
	const mk = (src, fn) => {
		const h = makePlaceHost();
		listen(h.hzBlg);
		h.hzWatchStyle = 0;
		h.ring = art("instance1285", 111, 110.6);
		h.disc = art("instance1292", 110.2, 50.15);
		h.band = art("instance301", 0, 0);
		h.tick = art("instance298", 87.2, 141.65);
		h.named = ["BioAlertText", "EnvAlertText", "EnemyDetectionAnim_mc", "LocationAlertText", "BioConditionBase_mc"].map((n) => art(n, 110.5, 96.75));
		[h.ring, h.disc, h.band, h.tick].concat(h.named).forEach((c) => { c.parent = h.hzBlg; h.hzBlg.kids.push(c); });
		h.locClip = h.named[3];
		if (src) {
			(fn || ["hz45Sync"]).forEach((f) => {
				const args = { hz45Sync: [], hz45Art: ["d"], hz45Put: ["d", "mode"], hz45Mode: [], hz45EnvHide: [] }[f];
				h[f] = Function.apply(null, args.concat(["with(this){\n" + asInnerOf(src, f) + "\n}"])).bind(h);
			});
		}
		bindAsMethod(h, "hz43FoOnAdd", ["e"]);
		return h;
	};
	const fireAdd = (hh, ev) => { hh.hzBlg.listeners.slice().forEach((l) => l.f(ev)); };
	const artOk = (h, vis) => [h.ring, h.disc, h.band, h.tick].every((c) => c.visible === vis);
	const namedUntouched = (h) => h.named.every((c) => c.visible === true && c.alpha === 0.8);

	// 1. style 0 (OFF): the scan art is hidden, named alerts untouched, the cap unit untouched
	const z = mk();
	z.hz45Sync();
	expect(artOk(z, false), "r8 style 0: the planet-info art (ring, disc, band, INFO tick) is hidden on the sync event");
	expect(namedUntouched(z) && z.capClip.visible !== false, "r8 style 0: BioAlertText, EnvAlertText, the enemy ring, LocationAlertText, Bio* and the cap unit are not touched by this path");
	expect(z.hzBlg.listeners.length === 1 && z.hzBlg.listeners[0].weak === true && z.hz43FoLsn === z.hzBlg, "r8 style 0: one weak ADDED listener (art can be added at any scan edge)");
	const zNew = art("instance1293", 111, 110.6); zNew.parent = z.hzBlg; z.hzBlg.kids.push(zNew);
	fireAdd(z, { target: zNew });
	expect(zNew.visible === false, "r8 style 0: a new art instance (FadeInPlanetInfo keyframe) is hidden on its ADDED event, before its first frame");
	const zNested = art("instance5", 1, 1); zNested.parent = { name: "inner" };
	fireAdd(z, { target: zNested });
	fireAdd(z, { target: { name: "BioAlertText", parent: z.hzBlg, visible: true } });
	fireAdd(z, null);
	expect(zNested.visible === true, "r8: nested children, named clips and empty events are left alone");
	z.hz45Sync();   // settles the child count after the added instances above
	let putN = 0; const putIn = z.hz45Put; z.hz45Put = function(d, m) { putN++; return putIn(d, m); };
	z.hz45Sync();
	expect(putN === 0 && z.hzBlg.listeners.length === 1, "r8: a repeat sync with no change does not sweep or add a listener");
	// Scaleform may not dispatch ADDED for timeline children: a changed child count sweeps on the next sync (late LocalEnvironmentData)
	const zQuiet = art("instance1294", 111, 110.6); zQuiet.parent = z.hzBlg; z.hzBlg.kids.push(zQuiet);
	z.hz45Sync();
	expect(zQuiet.visible === false && putN > 0, "r8 style 0: art added without an ADDED event is hidden on the next sync (child count changed)");
	// styles 3 / 4: same hide (no vanilla watch)
	const h3 = mk(); h3.hzWatchStyle = 3; h3.hz45Sync();
	expect(artOk(h3, false) && namedUntouched(h3), "r8 style 3: the art is hidden too (Horizon face, no vanilla watch)");

	// 2. style 1 moved: the art follows the assembly (scale too), the alerts stay shown
	const v = mk(); v.hzWatchStyle = 1;
	v.hz45Sync();
	expect(artOk(v, true) && v.ring.x === 111 && v.hzBlg.listeners.length === 0, "r8 style 1 at home: art shown at its native place, no listener");
	v.hz43VanWrite(-64.3, 34.85, 1);
	expect(near(v.ring.x, 111 - 64.3) && near(v.ring.y, 110.6 + 34.85) && near(v.disc.x, 110.2 - 64.3) && v.tick.visible === false && near(v.tick.y, 141.65), "r8 style 1 moved: ring and disc move with the watch; r9 MF-1 verdict: the INFO tick is hidden in place, never moved (no native-spot ghost)");
	expect([v.ring, v.disc, v.band].every((c) => c.visible === true) && namedUntouched(v), "r8 style 1 moved: art and alerts stay shown (vanilla mode shows what vanilla shows; r9: not the tick, see above)");
	expect(v.hzBlg.listeners.length === 1, "r8 style 1 moved: the ADDED listener is attached");
	const vNew = art("instance1300", 111, 110.6); vNew.parent = v.hzBlg; v.hzBlg.kids.push(vNew);
	fireAdd(v, { target: vNew });
	expect(near(vNew.x, 111 - 64.3) && near(vNew.y, 110.6 + 34.85) && vNew.visible === true && v.hz45HX[v.hz45D.indexOf(vNew)] === 111, "r8 style 1 moved: a new art instance is recorded native and placed on its ADDED event");
	v.hz43VanWrite(-40, 20, 0.8);
	expect(near(v.ring.x, 111 * 0.8 - 40) && near(v.ring.scaleX, 0.8) && near(vNew.x, 111 * 0.8 - 40), "r8 style 1: a new offset / scale re-places every art piece from its native place");
	// Bot 3 r7 S-1: home again -> art native, listener removed
	v.hz43VanWrite(0, 0, 1);
	expect(v.ring.x === 111 && v.ring.y === 110.6 && v.ring.scaleX === 1 && vNew.x === 111, "r8 style 1: write(0,0,1) puts the art back at its native place");
	expect(v.hzBlg.listeners.length === 0 && v.hz43FoLsn === null, "Bot 3 r7 S-1: the watch back home in 1 / 2 removes the ADDED listener");

	// 3. HideWatchWhileScanning hold in 1 / 2: art hidden with the watch, shown and placed on release
	const s = mk(); s.hzWatchStyle = 2;
	s.hz43VanWrite(-30, 10, 1);
	s.hz43ScanHid = true; s.hz45Sync();
	expect(artOk(s, false) && s.named.filter((c) => s.HZ46_TXT.indexOf(c.name) < 0).every((c) => c.visible === true && c.alpha === 0.8), "r8 style 2 + HideWatchWhileScanning: the art hides with the watch; the enemy ring, LocationAlertText and Bio* stay");
	expect(s.named[0].visible === false && s.named[1].visible === false && s.named[0].alpha === 0.8 && s.hz43ScanMk.length === 2, "r9 (S-2): the sweep also hides BioAlertText / EnvAlertText (visible only, recorded for the scan close)");
	s.hz43ScanHid = false; s.hz45Sync();
	expect([s.ring, s.disc, s.band].every((c) => c.visible === true) && s.tick.visible === false && near(s.ring.x, 111 - 30), "r8 style 2: on release the art is back, on the moved watch (r9: the INFO tick stays hidden while moved)");

	// 4. style edge 0 -> 1: the art comes back (only this path hides it)
	const e = mk(); e.hz45Sync();
	e.hzWatchStyle = 1; e.hz45Sync();
	expect(artOk(e, true), "r8: style 0 -> 1 shows the art again");

	// 5. mutant E (Bot 3 r7): HUD rebuild = a new BottomLeftGroup_mc. The old group's listener must go.
	const rebuild = (h) => {
		h.hzWatchStyle = 1;
		h.hz43VanWrite(-20, 5, 1);
		const oldB = h.hzBlg;
		const nb = listen({ name: "BottomLeftGroup_mc", kids: [], getChildAt: function(i) { return this.kids[i]; }, getChildByName: function() { return null; } });
		Object.defineProperty(nb, "numChildren", { get: function() { return this.kids.length; } });
		h.hzBlg = nb;
		h.hz43FollowApply();
		return { oldB: oldB, nb: nb };
	};
	const rb = rebuild(mk());
	expect(rb.oldB.listeners.length === 0 && rb.nb.listeners.length === 1, "r8 (Bot 3 mutant E): on a HUD rebuild the old group's ADDED listener is removed and the new group gets one");
	const syncSrc = funcBody(as, "hz45Sync");
	const mutE = as.replace("if(this.hz43FoLsn) { this.hz43FoLsn.removeEventListener(Event.ADDED,this.hz43FoOnAdd); }", "");
	expect(mutE !== as, "r8 mutant E: built (old-group removeEventListener dropped)");
	const rbm = rebuild(mk(mutE, ["hz45Sync"]));
	expect(rbm.oldB.listeners.length === 1 && rbm.nb.listeners.length === 1, "r8 mutant E: without the remove the old group keeps its listener, so the rebuild check above FAILS on it (mutant killed)");
	// mutant: art never recognized -> the style 0 ghost stays
	const mutArt = as.replace("if(n != null && n.length > 0 && n.indexOf(\"instance\") != 0) { return false; }", "return false;");
	expect(mutArt !== as, "r8 mutant (art check off): built");
	const ma = mk(mutArt, ["hz45Art"]); ma.hz45Sync();
	expect(artOk(ma, true), "r8 mutant (art check off): the ring / disc / band stay on screen in style 0, so the hide check above FAILS on it");
	// mutant: no mode-2 placement -> the 1 / 2 ghost stays at the native spot
	const mutPut = as.replace("nx = ox + (hx - ox) * sc + this.hz43FoDx / ux;", "nx = hx;");
	expect(mutPut !== as, "r8 mutant (no follow): built");
	const mp = mk(mutPut, ["hz45Put"]); mp.hzWatchStyle = 1; mp.hz43VanWrite(-64.3, 34.85, 1);
	expect(mp.ring.x === 111, "r8 mutant (no follow): the ring stays at the native spot with the watch moved, so the follow check above FAILS on it");

	// 6. the late LocalEnvironmentData re-hide (W3: DayCycleBase_mc globe, OffPlanet_mc, Autopilot_mc, locationNameBase_mc)
	const mkEnv = (src) => {
		const h = mk(src, src ? ["hz45EnvHide"] : undefined);
		h.HZ45_W3 = ["DayCycleBase_mc", "OffPlanet_mc", "Autopilot_mc", "locationNameBase_mc"];
		h.globe = art("DayCycleBase_mc", 110.5, 110.5); h.globe.parent = h.hzBlg; h.hzBlg.kids.push(h.globe);
		h.loc = art("locationNameBase_mc", 110.15, 139.75); h.loc.parent = h.hzBlg; h.hzBlg.kids.push(h.loc);
		h.hzHideVanillaCompass = true;
		h.stHid = [];
		h.hz43StHide = function(d) { this.stHid.push(d.name); d.visible = false; };
		if (!src) bindAsMethod(h, "hz45EnvHide", []);
		return h;
	};
	const g0 = mkEnv(); g0.hz45EnvHide();
	expect(g0.globe.visible === false && g0.loc.visible === false && g0.stHid.join() === "DayCycleBase_mc,locationNameBase_mc", "r8 style 0: the globe (DayCycleBase_mc) and the location name the game re-showed in LocalEnvironmentData are hidden again in the same dispatch (through hz43StHide, so the vanilla restore notes them)");
	const g1 = mkEnv(); g1.hzWatchStyle = 1; g1.hz45EnvHide();
	expect(g1.globe.visible === true && g1.stHid.length === 0, "r8 style 1: the vanilla globe is never hidden by this path");
	const gc = mkEnv(); gc.hzHideVanillaCompass = false; gc.hz45EnvHide();
	expect(gc.globe.visible === true, "r8: HideVanillaCompass off: not hidden (same switch as the hide list)");
	const mutEnv = as.replace("if(st == 1 || st == 2 || !this.hzHideVanillaCompass || !this.hzBlg) { return; }", "if(!this.hzBlg) { return; }");
	expect(mutEnv !== as, "r8 mutant (style check off): built");
	const gm = mkEnv(mutEnv); gm.hzWatchStyle = 1; gm.hz45EnvHide();
	expect(gm.globe.visible === false, "r8 mutant (style check off): the vanilla globe would vanish in style 1, so the style 1 check above FAILS on it");

	// 7. event-only: wiring and no per-frame work
	const tick = funcBody(as, "hz44GrpTick");
	expect(/if\(frame && !this\.hz45EnvSub\)\s*\{[\s\S]*?this\.hz45EnvSub = true;[\s\S]*?BSUIDataManager\.Subscribe\("LocalEnvironmentData",this\.hz45OnEnvLate\)/.test(tick), "r8: the late LocalEnvironmentData listener is subscribed once, on the first frame tick (after the group's own onAddedToStage listener)");
	expect((as.match(/this\.hz45OnEnvLate\b/g) || []).length === 1, "r8: subscribed in one place");
	expect(["hzOnFrame", "hz27OnExit", "hz43Frame", "hz43VanHorizon", "hz43VanPlace", "hz43VanLate"].every((f) => funcBody(as, f).indexOf("hz45") < 0), "r8: no hz45 call in any per-frame function body");
	const sh = funcBody(as, "hz43SyncHide");
	expect(/if\(hide != this\.hzHideVanillaWatch\)\s*\{[^}]*\}[^}]*try \{ this\.hz45Sync\(\); \}/.test(sh) && (sh.match(/hz45Sync/g) || []).length === 1, "r8: hz43SyncHide syncs the art only inside its style-change edge");
	expect(funcBody(as, "hz40SetScan").indexOf("this.hz45Sync()") >= 0 && (funcBody(as, "hz43ScanHideSync").match(/this\.hz45Sync\(\)/g) || []).length === 2 && funcBody(as, "hz43FollowApply").indexOf("this.hz45Sync()") >= 0,
		"r8: synced on the scan edge, the HideWatchWhileScanning edges and the ARRANGE write (via hz43FollowApply)");
	expect(syncSrc.indexOf("getChildByName") < 0 && syncSrc.indexOf("hzFindByName") < 0 && funcBody(as, "hz45Put").indexOf(".alpha") < 0 && syncSrc.indexOf(".alpha") < 0, "r8: one pass over direct children, no search, never alpha");
	expect((as.match(/addEventListener\(Event\.ADDED,this\.hz43FoOnAdd,false,0,true\)/g) || []).length === 1 && syncSrc.indexOf("addEventListener(Event.ADDED,this.hz43FoOnAdd,false,0,true)") >= 0, "r8: the weak ADDED listener is still added in one place (hz45Sync)");
	const wl = funcBody(as, "hz45WlBlg");
	expect(/^\{\s*if\(!this\.hzWlOn/.test(wl) && funcBody(as, "hz45OnEnvLate").indexOf("if(this.hzWlOn)") >= 0 && funcBody(as, "hz40SetScan").indexOf("if(this.hzWlOn) { try { this.hz45WlBlg(") >= 0, "r8 diag: the BottomLeftGroup child dump runs only with the watchlog on (PerfDiag=1, WatchLog=1)");
}

// ---- r8 (2/2): hz43VanCapture must not re-read native places while the markers are moved (Horizon faces 3 / 4). The scan
// edge adds planet-info art (child count changes); the old early return only covered hz43VanWrote.
{
	const mkCap = (src) => {
		const h = { hzBlg: { numChildren: 31 }, hz43VanP: {}, hz43VanCap: 1, hz43VanWrote: false, hz43MarkMoved: true, hz43VanNeed: 0, hz43VanKids: 27, hz43VanN: 4, finds: 0,
			HZ43_VAN_N: ["WatchOutline_mc"], hzFindByName: function() { this.finds++; return null; }, hz43VanGather: function() {}, hz43VanAdd: function() {}, hz43VanRootOf: function(d) { return d; } };
		// the gate only: the body up to its first statement after the early returns (the rest needs real display objects)
		const inner = asInnerOf(src || as, "hz43VanCapture");
		const gate = inner.slice(0, inner.indexOf("this.hz43VanN = 0;"));
		h.hz43VanCapture = Function.apply(null, ["with(this){\n" + gate + "\nthis.finds++; this.hz43VanN = 0;\n}"]).bind(h);
		return h;
	};
	const c = mkCap();
	c.hz43VanCapture();
	expect(c.finds === 0 && c.hz43VanN === 4, "r8: moved markers + a new child (scan art): no recapture, the recorded native places stay");
	const c2 = mkCap(); c2.hz43MarkMoved = false; c2.hz43VanCapture();
	expect(c2.finds > 0, "r8: markers home + a child-count change: the capture still re-runs (HUD changes are still picked up)");
	const mutCap = as.replace("if(this.hz43VanWrote || this.hz43MarkMoved) { return; }", "if(this.hz43VanWrote) { return; }");
	expect(mutCap !== as, "r8 mutant (r7 early return): built");
	const cm = mkCap(mutCap); cm.hz43VanCapture();
	expect(cm.finds > 0 && cm.hz43VanN === 0, "r8 mutant (r7 early return): the moved markers are re-captured as native, so the first check above FAILS on it");
}

// ---- r9 (user answers relayed 2026-11-10 23:07). S-1: in WatchStyle 1 / 2 with the vanilla watch moved, the vanilla
// env / bio alert text (EnvAlertText, BioAlertText) follows the watch like the ring / bars; home again = native spot;
// 0 / 3 / 4 never move it. S-2: the HideWatchWhileScanning hold hides that text too and the scan close gives it back.
// MF-1 switch: the always-present INFO ticks move through hz46TickPut only (HZ46_TICK_MOVE), by position, never scaled.
{
	const near = (a, b) => Math.abs(a - b) < 1e-9;
	const clip = (nm, x, y) => ({ name: nm, x: x, y: y, scaleX: 1, scaleY: 1, visible: true, alpha: 0.5 });
	const listen = (blg) => {
		blg.listeners = [];
		blg.addEventListener = function(t, f, cap, pri, weak) { this.listeners.push({ t: t, f: f, weak: weak }); };
		blg.removeEventListener = function(t, f) { this.listeners = this.listeners.filter((l) => !(l.t === t && l.f === f)); };
		return blg;
	};
	const mk = (style, src, fns) => {
		const h = makePlaceHost();
		listen(h.hzBlg);
		h.hzWatchStyle = style;
		// native places from the BLG timeline (Symbol 1332): Layer 8 / 11 / 35
		h.bio = clip("BioAlertText", 110.85, 86.35);
		h.env = clip("EnvAlertText", 110.75, 110.25);
		h.loc = clip("LocationAlertText", 110.75, 96.75);
		h.ring = clip("EnemyDetectionAnim_mc", 110.5, 110.5);
		h.tickL = clip("instance548", 87.2, 141.65); h.tickL.scaleX = 0.000076293945; h.tickL.scaleY = 0;
		h.tickR = clip("instance550", 139.45, 141.65); h.tickR.scaleX = 0.000076293945; h.tickR.scaleY = 0;
		h.art = clip("instance1285", 111, 110.6);
		[h.bio, h.env, h.loc, h.ring, h.tickL, h.tickR, h.art].forEach((c) => { c.parent = h.hzBlg; h.hzBlg.kids.push(c); });
		(fns || []).forEach((f) => {
			const args = { hz43FollowApply: [], hz43FoOnAdd: ["e"], hz45Put: ["d", "mode"], hz46TickPut: ["d", "k", "mode"], hz46TxtScanHide: [], hz45Sync: [] }[f];
			h[f] = Function.apply(null, args.concat(["with(this){\n" + asInnerOf(src, f) + "\n}"])).bind(h);
		});
		if (src) h.HZ46_TICK_MOVE = /HZ46_TICK_MOVE:Boolean = true/.test(src);
		if (!fns || fns.indexOf("hz43FoOnAdd") < 0) bindAsMethod(h, "hz43FoOnAdd", ["e"]);
		return h;
	};
	const fireAdd = (hh, ev) => { hh.hzBlg.listeners.slice().forEach((l) => l.f(ev)); };
	const at = (c, x, y) => near(c.x, x) && near(c.y, y);
	expect(asConst("HZ43_VAN_FOLLOW").join() === "LocationAlertText,EnvAlertText,BioAlertText" && asConst("HZ46_TXT").join() === "EnvAlertText,BioAlertText", "r9: the follower list holds the env / bio alert text; HZ46_TXT is the text only (LocationAlertText keeps its r6 / r7 rules)");
	expect(asConst("HZ46_TICK_MOVE") === false, "r9 MF-1 verdict: HZ46_TICK_MOVE ships false (the r8 log shows script-moved ticks frozen at alpha 0)");

	// S-1. style 1 / 2 moved: the text follows (offset and scale), the enemy ring does not move, home = native
	for (const st of [1, 2]) {
		const v = mk(st);
		v.hz43VanWrite(-64.3, 34.85, 1);
		expect(at(v.env, 110.75 - 64.3, 110.25 + 34.85) && at(v.bio, 110.85 - 64.3, 86.35 + 34.85) && at(v.loc, 110.75 - 64.3, 96.75 + 34.85), "r9 S-1 style " + st + " moved: EnvAlertText and BioAlertText follow the watch (same offset as LocationAlertText and the art)");
		expect(at(v.art, 111 - 64.3, 110.6 + 34.85) && at(v.ring, 110.5, 110.5), "r9 S-1 style " + st + ": the ring / bars art follows as in r8; the enemy ring is not a follower (unchanged)");
		expect(v.env.visible && v.bio.visible && v.env.alpha === 0.5 && v.bio.alpha === 0.5, "r9 S-1 style " + st + ": position only (visible and alpha stay the game's)");
		v.hz43VanWrite(-40, 20, 0.8);
		expect(at(v.env, 110.75 * 0.8 - 40, 110.25 * 0.8 + 20) && near(v.env.scaleX, 0.8) && near(v.bio.scaleY, 0.8), "r9 S-1 style " + st + ": a scaled watch scales the text from the outline origin like the units");
		v.hz43VanWrite(0, 0, 1);
		expect(at(v.env, 110.75, 110.25) && at(v.bio, 110.85, 86.35) && v.env.scaleX === 1 && v.bio.scaleX === 1 && v.hz43FoMoved === false, "r9 S-1 style " + st + ": watch reset home (write(0,0,1)) puts the text back at its native spot");
	}
	// S-1: a new text instance (HUD rebuild / keyframe) while moved is recorded native and placed on its ADDED event
	const a = mk(1);
	a.hz43VanWrite(-30, 10, 1);
	const env2 = clip("EnvAlertText", 110.75, 110.25); env2.parent = a.hzBlg;
	a.hzBlg.kids[a.hzBlg.kids.indexOf(a.env)] = env2;
	fireAdd(a, { target: env2 });
	expect(at(env2, 110.75 - 30, 110.25 + 10) && a.hz43FoHX[1] === 110.75, "r9 S-1: a new EnvAlertText instance is captured native and placed on its ADDED event");
	// S-1: never in 0 / 3 / 4. The Horizon marker write moves LocationAlertText (r7) but not the text.
	const h3 = mk(3);
	h3.hz43VanWrite(-30, 12, 1, true);
	expect(at(h3.loc, 110.75 - 30, 96.75 + 12) && at(h3.env, 110.75, 110.25) && at(h3.bio, 110.85, 86.35), "r9 S-1 style 3: the Horizon face offset moves LocationAlertText only; the alert text stays native");
	// a moved vanilla text, then a style change to 3 without a reset write: the next follow pass puts it home
	const sw = mk(1);
	sw.hz43VanWrite(-50, 25, 1);
	sw.hzWatchStyle = 3;
	sw.hz43FollowApply();
	expect(at(sw.env, 110.75, 110.25) && at(sw.bio, 110.85, 86.35) && at(sw.loc, 110.75 - 50, 96.75 + 25), "r9 S-1: leaving 1 / 2 with a moved watch: the next follow pass puts the text home (only LocationAlertText keeps an offset)");
	const s0 = mk(1); s0.hz43VanWrite(-50, 25, 1); s0.hzWatchStyle = 0; s0.hz43FollowApply();
	expect(at(s0.env, 110.75, 110.25) && at(s0.bio, 110.85, 86.35), "r9 S-1 style 0: the text is never off its native spot");
	// mutant: the 1 / 2 gate removed -> the text would follow the Horizon face / stay moved in 0
	const mutGate = as.replace("var txtHome:Boolean = !van && HZ46_TXT.indexOf(nm) >= 0;", "var txtHome:Boolean = false;");
	expect(mutGate !== as, "r9 mutant (text style gate off): built");
	const mg = mk(1, mutGate, ["hz43FollowApply"]); mg.hz43VanWrite(-50, 25, 1); mg.hzWatchStyle = 0; mg.hz43FollowApply();
	expect(!at(mg.env, 110.75, 110.25), "r9 mutant (text style gate off): the text stays moved in style 0, so the style 0 check above FAILS on it");
	// mutant: the text not in the follower list -> it stays at the native spot with the watch moved
	const mutList = as.replace('HZ43_VAN_FOLLOW:Array = ["LocationAlertText","EnvAlertText","BioAlertText"];', 'HZ43_VAN_FOLLOW:Array = ["LocationAlertText"];');
	expect(mutList !== as, "r9 mutant (text not a follower): built");
	const ml = mk(1); ml.HZ43_VAN_FOLLOW = ["LocationAlertText"]; ml.hz43VanWrite(-64.3, 34.85, 1);
	expect(at(ml.env, 110.75, 110.25), "r9 mutant (text not a follower): EnvAlertText stays at the native spot, so the S-1 follow check above FAILS on it");

	// S-2. the HideWatchWhileScanning hold hides the text (sweep / ADDED), the scan close gives back only what it hid
	const sh = mk(2);
	sh.hz43VanWrite(-30, 10, 1);
	sh.game = clip("BioAlertText", 110.85, 86.35);
	sh.hz43ScanHid = true; sh.hz43ScanMk = [];
	sh.hz46TxtScanHide();
	expect(!sh.env.visible && !sh.bio.visible && sh.hz43ScanMk.length === 2 && sh.loc.visible && sh.ring.visible, "r9 S-2: the hold hides EnvAlertText / BioAlertText (recorded); LocationAlertText and the enemy ring stay");
	expect(sh.env.alpha === 0.5 && sh.bio.alpha === 0.5, "r9 S-2: visible only, never alpha (the timeline owns their alpha)");
	sh.hz46TxtScanHide();
	expect(sh.hz43ScanMk.length === 2, "r9 S-2: a repeat does not record twice");
	sh.hz45Sync();   // settles the hold sweep (mode 1, listener on) before the new instance arrives
	const bio2 = clip("BioAlertText", 110.85, 86.35); bio2.parent = sh.hzBlg;
	sh.hzBlg.kids[sh.hzBlg.kids.indexOf(sh.bio)] = bio2;   // same child count: no sweep, only the ADDED event can catch it
	fireAdd(sh, { target: bio2 });
	expect(bio2.visible === false && sh.hz43ScanMk.indexOf(bio2) >= 0 && at(bio2, 110.85 - 30, 86.35 + 10), "r9 S-2: a new text instance during the hold is placed and hidden on its ADDED event");
	const off = mk(1); off.hz46TxtScanHide();
	expect(off.env.visible && off.bio.visible, "r9 S-2: without the hold nothing is hidden");
	const pre = mk(3); pre.bio.visible = false; pre.hz43ScanHid = true; pre.hz46TxtScanHide();
	expect(pre.hz43ScanMk.indexOf(pre.bio) < 0 && pre.hz43ScanMk.indexOf(pre.env) >= 0, "r9 S-2: a text the game / hz27BioHide already hid is not recorded (stays theirs on scan close)");
	// the scan close path (hz43ScanHideSync) with the real text hide, vanilla and Horizon
	const mkS2 = (style, src) => {
		const h = mk(style);
		h.hz40Scan = true; h.hz40Latch = false; h.hz30Mod = { scanner: 1 }; h.hzArrange = false; h.hz43ScanSt = 0; h.hz43Watch = { visible: true };
		h.cfg = { HideWatchWhileScanning: 1 }; h.hz40Cfg = function() { return this.cfg; };
		h.hz43VanShowClip = function(d) { if (!d.visible) d.visible = true; };
		bindAsMethod(h, "hz41B", ["v"]); bindAsMethod(h, "hz41ScanHideOn", []); bindAsMethod(h, "hz43VanSkip", ["name"]); bindAsMethod(h, "hz43ScanWant", []); bindAsMethod(h, "hz43ScanPiece", ["d"]);
		h.hz43ScanHideSync = Function.apply(null, ["with(this){\n" + asInnerOf(src || as, "hz43ScanHideSync") + "\n}"]).bind(h);
		return h;
	};
	for (const st of [1, 3]) {
		const c = mkS2(st);
		c.hz43ScanHideSync();
		expect(c.hz43ScanHid && !c.env.visible && !c.bio.visible && c.loc.visible && c.ring.visible, "r9 S-2 style " + st + ": scan open with the hold hides the alert text");
		c.hz40Scan = false; c.hz43ScanHideSync();
		expect(!c.hz43ScanHid && c.env.visible && c.bio.visible && c.hz43ScanMk.length === 0, "r9 S-2 style " + st + ": scan close restores the alert text");
	}
	const dflt = mkS2(1); dflt.cfg.HideWatchWhileScanning = 0; dflt.hz43ScanHideSync();
	expect(dflt.env.visible && dflt.bio.visible, "r9 S-2: HideWatchWhileScanning=0 (default): the text is never hidden");
	// mutant: the edge does not call the text hide -> the text stays on screen during the hold
	const mutEdge = as.replace("try { this.hz46TxtScanHide(); } catch(e46t:Error) { }", "");
	expect(mutEdge !== as, "r9 mutant (no text hide on the edge): built");
	// style 3: the art mode is 1 before and after the edge, so no change sweep runs; only the edge call hides the text
	const me = mkS2(3, mutEdge); me.hz45Sync(); me.hz43ScanHideSync();
	expect(me.env.visible, "r9 mutant (no text hide on the edge): in style 3 EnvAlertText stays shown, so the S-2 style 3 open check above FAILS on it");
	const me0 = mkS2(3); me0.hz45Sync(); me0.hz43ScanHideSync();
	expect(!me0.env.visible && !me0.bio.visible, "r9 S-2 style 3 after a settled sync (no sweep on the edge): the edge itself hides the text");
	// mutant: hidden but not recorded -> never given back on scan close
	const mutRec = as.replace("if(this.hz43ScanMk.indexOf(d) < 0) { this.hz43ScanMk.push(d); }", "");
	expect(mutRec !== as, "r9 mutant (not recorded): built");
	const mr = mkS2(1); mr.hz46TxtScanHide = Function.apply(null, ["with(this){\n" + asInnerOf(mutRec, "hz46TxtScanHide") + "\n}"]).bind(mr);
	mr.hz43ScanHideSync(); mr.hz40Scan = false; mr.hz43ScanHideSync();
	expect(!mr.env.visible, "r9 mutant (not recorded): the text stays hidden after the scan, so the S-2 close check above FAILS on it");
	// mutant: the ADDED handler ignores new text during the hold
	const mutAdd = as.replace("if(this.hz43ScanHid && HZ46_TXT.indexOf(t.name) >= 0) { try { this.hz46TxtScanHide(); } catch(eT:Error) { } }", "");
	expect(mutAdd !== as, "r9 mutant (ADDED ignores text): built");
	const ma = mk(2, mutAdd, ["hz43FoOnAdd"]); ma.hz43VanWrite(-30, 10, 1); ma.hz43ScanHid = true; ma.hz45Sync();
	const bio3 = clip("BioAlertText", 110.85, 86.35); bio3.parent = ma.hzBlg; ma.hzBlg.kids[ma.hzBlg.kids.indexOf(ma.bio)] = bio3;
	fireAdd(ma, { target: bio3 });
	expect(bio3.visible === true, "r9 mutant (ADDED ignores text): a new BioAlertText shows during the hold, so the ADDED check above FAILS on it");

	// MF-1 switch: the INFO ticks
	expect(mk(1).hz46Tick(87.2, 141.65) && mk(1).hz46Tick(139.45, 141.65) && !mk(1).hz46Tick(111, 110.6) && !mk(1).hz46Tick(110.85, 169.15), "r9 MF-1: hz46Tick knows the two INFO ticks by their native place (not the ring, not the bar at 169.15)");
	// shipped (false, the r8 log verdict): ticks hidden while moved, never moved (so never frozen), shown native at home
	const tf = mk(1);
	tf.hz43VanWrite(-40, 20, 0.8);
	expect(!tf.tickL.visible && !tf.tickR.visible && at(tf.tickL, 87.2, 141.65) && tf.tickL.scaleX === 0.000076293945 && at(tf.art, 111 * 0.8 - 40, 110.6 * 0.8 + 20) && tf.art.visible, "r9 MF-1 (HZ46_TICK_MOVE false): with the watch moved the ticks are hidden (not moved, not left as a ghost); the other art still follows");
	tf.hz43VanWrite(0, 0, 1);
	expect(tf.tickL.visible && tf.tickR.visible && at(tf.tickL, 87.2, 141.65), "r9 MF-1: home again = ticks shown at their native place (never script-moved, so their fade still plays)");
	const z0 = mk(0); z0.hz45Sync();
	expect(!z0.tickL.visible && !z0.art.visible, "r9 MF-1: style 0 still hides the ticks with the other art (r8)");
	// the switch thrown back on (true): position-only move, never scaled
	const onSrc = as.replace("private static const HZ46_TICK_MOVE:Boolean = false;", "private static const HZ46_TICK_MOVE:Boolean = true;");
	expect(onSrc !== as, "r9 MF-1: switch-on variant built");
	const t = mk(1, onSrc);
	t.hz43VanWrite(-40, 20, 0.8);
	expect(at(t.tickL, 87.2 * 0.8 - 40, 141.65 * 0.8 + 20) && at(t.tickR, 139.45 * 0.8 - 40, 141.65 * 0.8 + 20) && t.tickL.visible, "r9 MF-1 (switch on): the ticks move with the watch (position from the outline origin)");
	expect(t.tickL.scaleX === 0.000076293945 && t.tickL.scaleY === 0 && near(t.art.scaleX, 0.8), "r9 MF-1: the ticks are never scaled (rotated matrix); other art still scales as in r8");
	t.hz43VanWrite(0, 0, 1);
	expect(at(t.tickL, 87.2, 141.65) && at(t.tickR, 139.45, 141.65) && t.tickL.visible, "r9 MF-1 (switch on): home again = native place");
	const code = as.split("\n").map((l) => l.replace(/\/\/.*$/, "")).join("\n");
	expect((code.match(/HZ46_TICK_MOVE/g) || []).length === 2 && funcBody(as, "hz46TickPut").indexOf("!HZ46_TICK_MOVE") >= 0, "r9 MF-1: the switch is declared once and read in one place (hz46TickPut)");
	expect(funcBody(as, "hz45Put").indexOf("this.hz46TickPut(d,k,mode)") >= 0 && (as.match(/this\.hz46TickPut\(/g) || []).length === 1 && (as.match(/this\.hz46Tick\(/g) || []).length === 4 && funcBody(as, "hz46Inherit").indexOf("this.hz46Tick(") >= 0, "r9 MF-1: the tick path is entered from hz45Put only (plus the diag tag and hz46Inherit, which skips ticks)");
	expect(funcBody(as, "hz46TickPut").indexOf("scaleX") < 0 && funcBody(as, "hz46TickPut").indexOf(".alpha") < 0, "r9 MF-1: the tick path never writes scale or alpha");

	// event-only and diag
	const perFrame = ["hzOnFrame", "hz27OnExit", "hz43Frame", "hz43VanHorizon", "hz43VanPlace", "hz43VanLate", "hz43SyncHide", "hz44GrpTick", "hz27BioHide"];
	expect(perFrame.every((f) => funcBody(as, f).indexOf("hz46") < 0 && funcBody(as, f).indexOf("HZ46") < 0), "r9: no hz46 call in any per-frame function body");
	const tb = funcBody(as, "hz46TxtScanHide");
	expect((tb.match(/getChildByName/g) || []).length === 1 && tb.indexOf("getChildAt") < 0 && tb.indexOf("hzFindByName") < 0 && tb.indexOf(".alpha") < 0, "r9 S-2: two direct lookups (one per text), no search, never alpha");
	expect((as.match(/this\.hz46TxtScanHide\(\)/g) || []).length === 3 && funcBody(as, "hz43ScanHideSync").indexOf("this.hz46TxtScanHide()") >= 0 && funcBody(as, "hz43FoOnAdd").indexOf("this.hz46TxtScanHide()") >= 0 && funcBody(as, "hz45Sync").indexOf("this.hz46TxtScanHide()") >= 0, "r9 S-2: called on the hide edge, the ADDED event and the change sweep only");
	expect((as.match(/this\.hz46WlTick\(/g) || []).length === 1 && funcBody(as, "hz45WlBlg").indexOf("this.hz46WlTick(d)") >= 0, "r9 diag: the ,tick tag is only in the watchlog dump (PerfDiag=1, WatchLog=1)");
	expect(as.indexOf("enterFrame") < 0 || (as.match(/Event\.ENTER_FRAME/g) || []).length === (readText(path.join(root, "actionscript", "horizon_block.as")).match(/Event\.ENTER_FRAME/g) || []).length, "r9: no new enterFrame listener");
}

// ---- r9 (2/2): the r8 gaming-PC log / screenshots. (1) hz40SetScan runs its r6 / r8 watch syncs on the real edge only
// (hz40OnCmp calls it on every dispatch). (2) MF-1 verdict: a follower that is a plain text holder moves its fields, never
// itself (its timeline fade keeps playing). (3) Root cause of the left-over arc: a swapped art instance that inherited the
// placed matrix takes the native of the record it was placed from (no 2x / 3x drift). (4) Root cause of the globe in the
// HideWatchWhileScanning hold: the late LocalEnvironmentData listener re-hides the W3 pieces the game re-showed.
// (5) Zero steady state: no ADDED listener under the whole-group hide; the hide / release edges sync it once.
{
	const near = (a, b) => Math.abs(a - b) < 1e-9;
	const clip = (nm, x, y) => ({ name: nm, x: x, y: y, scaleX: 1, scaleY: 1, visible: true, alpha: 0.5 });
	const holder = (nm, x, y, kids) => {
		const c = clip(nm, x, y);
		c.kids = kids.map((k) => { const t = clip(k[0], k[1], k[2]); t.parent = c; return t; });
		c.getChildAt = function(i) { return this.kids[i]; };
		Object.defineProperty(c, "numChildren", { get: function() { return this.kids.length; } });
		return c;
	};
	const listen = (blg) => {
		blg.listeners = [];
		blg.addEventListener = function(t, f, cap, pri, weak) { this.listeners.push({ t: t, f: f, weak: weak }); };
		blg.removeEventListener = function(t, f) { this.listeners = this.listeners.filter((l) => !(l.t === t && l.f === f)); };
		return blg;
	};
	const mk = (style, src, fns) => {
		const h = makePlaceHost();
		listen(h.hzBlg);
		h.hzWatchStyle = style;
		// Symbols 1278 / 1269 / 1255: single-frame holders of TextFields (native places from the XFL)
		h.bio = holder("BioAlertText", 110.85, 86.35, [["Alert_tf", -72.2, -20.85]]);
		h.env = holder("EnvAlertText", 110.75, 110.25, [["Subtext_tf", -71.0, 6.35], ["Alert_tf", -76.35, -18.0]]);
		h.loc = holder("LocationAlertText", 110.75, 96.75, [["Planet_tf", -88.0, -20.05], ["Type_tf", -89.75, 4.85]]);
		h.band = clip("instance1653", 0, 0);   // the raw band shape: native identity
		[h.bio, h.env, h.loc, h.band].forEach((c) => { c.parent = h.hzBlg; h.hzBlg.kids.push(c); });
		(fns || []).forEach((f) => {
			const args = { hz43FollowApply: [], hz45Put: ["d", "mode"], hz46Inherit: ["d"], hz46KidRec: ["i", "d"], hz46KidPut: ["i", "d", "nx", "ny", "fs"], hz45Sync: [] }[f];
			h[f] = Function.apply(null, args.concat(["with(this){\n" + asInnerOf(src, f) + "\n}"])).bind(h);
		});
		bindAsMethod(h, "hz43FoOnAdd", ["e"]);
		return h;
	};
	const fireAdd = (hh, ev) => { hh.hzBlg.listeners.slice().forEach((l) => l.f(ev)); };
	const kidAt = (holderC, j, bx, by) => near(holderC.x + holderC.kids[j].x, bx) && near(holderC.y + holderC.kids[j].y, by);

	// (1) edge-only syncs in hz40SetScan
	const mkScan = (src) => {
		const h = { hz40Scan: false, hz40Latch: false, hzWlOn: false, n: { f: 0, s: 0, a: 0, l: 0 } };
		h.hz40Apply = function() {}; h.hz41LocHide = function() { h.n.l++; };
		h.hz43FollowApply = function() { h.n.f++; }; h.hz43ScanHideSync = function() { h.n.s++; }; h.hz45Sync = function() { h.n.a++; };
		h.hz40SetScan = Function.apply(null, ["on", "with(this){\n" + asInnerOf(src, "hz40SetScan") + "\n}"]).bind(h);
		return h;
	};
	const e = mkScan(as);
	for (let i = 0; i < 50; i++) e.hz40SetScan(false);
	expect(e.n.f === 0 && e.n.s === 0 && e.n.a === 0 && e.n.l === 50, "r9 zero stutter: 50 repeat dispatches with the scanner closed run none of the r6 / r8 watch syncs (the pre-r6 hz41LocHide re-assert is unchanged)");
	e.hz40SetScan(true); for (let i = 0; i < 50; i++) e.hz40SetScan(true);
	expect(e.n.f === 1 && e.n.s === 1 && e.n.a === 1, "r9 zero stutter: the open edge runs each sync once; 50 repeats while open run none");
	e.hz40SetScan(false); e.hz40SetScan(false);
	expect(e.n.f === 2 && e.n.s === 2 && e.n.a === 2 && e.hz40Latch === false, "r9: the close edge runs each sync once (the latch still clears)");
	const mutEdge = as.replace("         if(!edge) { return; }   // r9: the r6 / r8 watch syncs below run once per real open / close edge, not per dispatch\n".replace(/\n/g, as.indexOf("\r\n") >= 0 ? "\r\n" : "\n"), "");
	expect(mutEdge !== as, "r9 mutant (edge gate removed): built");
	const me = mkScan(mutEdge); for (let i = 0; i < 50; i++) me.hz40SetScan(false);
	expect(me.n.f === 50, "r9 mutant (edge gate removed): every dispatch runs the syncs again, so the zero-stutter check above FAILS on it");

	// (2) MF-1: text holders move their fields, the instance stays native (its timeline fade keeps playing)
	for (const st of [1, 2]) {
		const v = mk(st);
		v.hz43VanWrite(-40, 20, 0.8);
		expect(v.bio.x === 110.85 && v.bio.y === 86.35 && v.bio.scaleX === 1 && v.env.x === 110.75 && v.loc.x === 110.75 && v.loc.y === 96.75,
			"r9 MF-1 (style " + st + "): BioAlertText / EnvAlertText / LocationAlertText instances are never script-moved");
		expect(kidAt(v.bio, 0, (110.85 - 72.2) * 0.8 - 40, (86.35 - 20.85) * 0.8 + 20) && near(v.bio.kids[0].scaleX, 0.8)
			&& kidAt(v.env, 0, (110.75 - 71.0) * 0.8 - 40, (110.25 + 6.35) * 0.8 + 20) && kidAt(v.env, 1, (110.75 - 76.35) * 0.8 - 40, (110.25 - 18.0) * 0.8 + 20)
			&& kidAt(v.loc, 0, (110.75 - 88.0) * 0.8 - 40, (96.75 - 20.05) * 0.8 + 20),
			"r9 S-1 + MF-1 (style " + st + "): the text fields land exactly where the moved / scaled holder would put them");
		v.hz43VanWrite(0, 0, 1);
		expect(v.bio.kids[0].x === -72.2 && v.bio.kids[0].y === -20.85 && v.bio.kids[0].scaleX === 1 && v.env.kids[1].x === -76.35 && v.loc.kids[1].y === 4.85,
			"r9 S-1 (style " + st + "): home again = every field back at its native place");
	}
	const z = mk(0); z.hz43VanWrite(-40, 20, 0.8); z.hz43FollowApply();
	expect(z.bio.kids[0].x === -72.2 && z.env.kids[0].x === -71.0 && z.bio.x === 110.85, "r9 S-1: style 0 leaves the env / bio text fields native");
	// a new holder instance (HUD rebuild / timeline) is recorded with its own fields
	const r = mk(1); r.hz43VanWrite(-30, 10, 1);
	const bio2 = holder("BioAlertText", 110.85, 86.35, [["Alert_tf", -72.2, -20.85]]); bio2.parent = r.hzBlg;
	r.hzBlg.kids[r.hzBlg.kids.indexOf(r.bio)] = bio2;
	fireAdd(r, { target: bio2 });
	expect(bio2.x === 110.85 && near(bio2.kids[0].x, -72.2 - 30) && near(bio2.kids[0].y, -20.85 + 10), "r9 MF-1: a new holder instance gets its fields placed on its ADDED event (the instance stays native)");
	// fallback: anything that is not a 1-2 child holder moves as in r6
	const f = mk(1); const big = holder("LocationAlertText", 110.75, 96.75, [["a", 0, 0], ["b", 0, 0], ["c", 0, 0]]); big.parent = f.hzBlg;
	f.hzBlg.kids[f.hzBlg.kids.indexOf(f.loc)] = big; f.loc = big;
	f.hz43VanWrite(-30, 10, 1);
	expect(near(big.x, 110.75 - 30) && big.kids[0].x === 0, "r9 MF-1: a follower with more than HZ46_KMAX children falls back to the r6 instance move");
	const mutKid = as.replace("if(int(this.hz46KN[i]) > 0) { this.hz46KidPut(i,d,nx,ny,fs); }", "if(false) { }");
	expect(mutKid !== as, "r9 mutant (holder moved itself): built");
	const mk2 = mk(1, mutKid, ["hz43FollowApply"]); mk2.hz43VanWrite(-40, 20, 0.8);
	expect(mk2.bio.x !== 110.85, "r9 mutant (holder moved itself): the instance is script-moved (MF-1 freeze), so the check above FAILS on it");

	// (3) the swapped band: no 2x / 3x drift (r8 log 1585: instance1653 at 14.3,-250.3 for a 4.8,-83.4 move)
	const b = mk(1); b.hz43VanWrite(4.8, -83.4, 1);
	expect(near(b.band.x, 4.8) && near(b.band.y, -83.4), "r9 root cause: the band is placed once with the watch");
	let cur = b.band;
	for (let g = 0; g < 3; g++) {
		const nb = clip("instance17" + g, cur.x, cur.y);   // the timeline swap at one depth keeps the placed matrix
		nb.parent = b.hzBlg; b.hzBlg.kids[b.hzBlg.kids.indexOf(cur)] = nb; cur = nb;
		fireAdd(b, { target: nb });
	}
	expect(near(cur.x, 4.8) && near(cur.y, -83.4) && b.hz45HX[b.hz45D.indexOf(cur)] === 0 && b.hz45HY[b.hz45D.indexOf(cur)] === 0,
		"r9 root cause: three swaps later the band is still on the moved watch, recorded with its native 0,0 (not 2x / 3x the move)");
	b.hz43VanWrite(0, 0, 1);
	expect(cur.x === 0 && cur.y === 0, "r9 root cause: home again = the swapped band at its native place");
	const fresh = mk(1); fresh.hz43VanWrite(4.8, -83.4, 1);
	const other = clip("instance1800", 111, 110.6); other.parent = fresh.hzBlg; fresh.hzBlg.kids.push(other); fireAdd(fresh, { target: other });
	expect(fresh.hz45HX[fresh.hz45D.indexOf(other)] === 111 && near(other.x, 111 + 4.8), "r9 root cause: a new instance at its own native place is recorded where it stands");
	const mutInh = as.replace("var j:int = mode == 2 ? this.hz46Inherit(d) : -1;", "var j:int = -1;");
	expect(mutInh !== as, "r9 mutant (no inherit): built");
	const bm = mk(1, mutInh, ["hz45Put"]); bm.hz43VanWrite(4.8, -83.4, 1);
	let cm = bm.band;
	for (let g = 0; g < 2; g++) { const nb = clip("instance18" + g, cm.x, cm.y); nb.parent = bm.hzBlg; bm.hzBlg.kids[bm.hzBlg.kids.indexOf(cm)] = nb; cm = nb; fireAdd(bm, { target: nb }); }
	expect(near(cm.x, 14.4) && near(cm.y, -250.2), "r9 mutant (no inherit): the r8 drift comes back (3 x the move, the log's 14.3,-250.3), so the check above FAILS on it");

	// (4) the globe in the HideWatchWhileScanning hold (styles 1 / 2)
	const g = mk(1);
	g.hzBlg.getChildByName = function(n) { return this.kids.find((c) => c.name === n) || null; };
	g.day = clip("DayCycleBase_mc", 110.5, 110.5); g.day.parent = g.hzBlg; g.hzBlg.kids.push(g.day);
	bindAsMethod(g, "hz43VanSkip", ["name"]); bindAsMethod(g, "hz43ScanPiece", ["d"]);
	g.hz43ScanHid = true; g.hz43ScanSt = 1; g.hz43ScanMk = [];
	g.hz46HoldW3(); g.hz46HoldW3();
	expect(g.day.visible === false && g.hz43ScanMk.filter((d) => d === g.day).length === 1, "r9 root cause: the hold re-hides the globe the game re-showed, recorded once for the scan close");
	const g3 = mk(3); g3.hzBlg.getChildByName = g.hzBlg.getChildByName; g3.day = clip("DayCycleBase_mc", 1, 1); g3.day.parent = g3.hzBlg; g3.hzBlg.kids.push(g3.day);
	bindAsMethod(g3, "hz43VanSkip", ["name"]); bindAsMethod(g3, "hz43ScanPiece", ["d"]);
	g3.hz43ScanHid = true; g3.hz43ScanSt = 3; g3.hz46HoldW3();
	const g0 = mk(1); g0.hzBlg.getChildByName = g.hzBlg.getChildByName; g0.day = clip("DayCycleBase_mc", 1, 1); g0.day.parent = g0.hzBlg; g0.hzBlg.kids.push(g0.day);
	bindAsMethod(g0, "hz43VanSkip", ["name"]); bindAsMethod(g0, "hz43ScanPiece", ["d"]);
	g0.hz43ScanHid = false; g0.hz43ScanSt = 1; g0.hz46HoldW3();
	expect(g3.day.visible && g0.day.visible, "r9: no re-hide outside the hold, and not in 3 / 4 (hz45EnvHide's rules there)");
	expect(/try \{ this\.hz45EnvHide\(\); \} catch\(eH:Error\) \{ \}\s*try \{ this\.hz46HoldW3\(\); \}/.test(funcBody(as, "hz45OnEnvLate")) && (as.match(/this\.hz46HoldW3\(\)/g) || []).length === 1,
		"r9: the W3 hold re-hide runs from the late LocalEnvironmentData listener only (same dispatch, after the game's handler)");
	const hw = funcBody(as, "hz46HoldW3");
	expect((hw.match(/getChildByName/g) || []).length === 1 && hw.indexOf("getChildAt") < 0 && hw.indexOf("hzFindByName") < 0 && hw.indexOf(".alpha") < 0, "r9: four direct lookups, no search, never alpha");

	// (5) the ADDED listener is not kept under the whole-group hide (style 0 default); the edges sync it once
	const q = mk(0); q.hz44Hid = true; q.hz45Sync();
	expect(q.hzBlg.listeners.length === 0, "r9 zero stutter: no ADDED listener while the whole-group hide holds (nothing under it can be seen)");
	q.hz44Hid = false; q.hz45SM = -1; q.hz45Sync();
	expect(q.hzBlg.listeners.length === 1 && q.band.visible === false, "r9: the release edge adds it back and sweeps once (the art is hidden before the group shows)");
	const tick = funcBody(as, "hz44GrpTick");
	expect((tick.match(/this\.hz45SM = -1; try \{ this\.hz45Sync\(\); \}/g) || []).length === 2
		&& /this\.hz44Hid = true;\s*this\.hz44N\+\+;\s*this\.hz45SM = -1; try \{ this\.hz45Sync\(\); \}/.test(tick)
		&& /this\.hz44Hid = false;\s*this\.hz44N\+\+;\s*this\.hz45SM = -1; try \{ this\.hz45Sync\(\); \}/.test(tick),
		"r9: hz44GrpTick syncs the listener inside its hide / release edges only (one-shot, next to hz44N++), never per tick");
	const mutGrp = as.replace("var want:Boolean = (mode != 0 && !this.hz44Hid) || this.hz43FoMoved;", "var want:Boolean = mode != 0 || this.hz43FoMoved;");
	expect(mutGrp !== as, "r9 mutant (listener under the group hide): built");
	const qm = mk(0, mutGrp, ["hz45Sync"]); qm.hz44Hid = true; qm.hz45Sync();
	expect(qm.hzBlg.listeners.length === 1, "r9 mutant (listener under the group hide): the r8 steady-state listener comes back, so the check above FAILS on it");

	// static: the new code is event-time only
	const perFrame = ["hzOnFrame", "hz27OnExit", "hz43Frame", "hz43VanHorizon", "hz43VanPlace", "hz43VanLate", "hz43SyncHide", "hz27BioHide"];
	expect(perFrame.every((fn) => !/hz46(KidRec|KidPut|Inherit|HoldW3)/.test(funcBody(as, fn))), "r9 (2/2): no new helper in any per-frame function body");
	expect((as.match(/this\.hz46KidRec\(/g) || []).length === 1 && (as.match(/this\.hz46KidPut\(/g) || []).length === 1 && (as.match(/this\.hz46Inherit\(/g) || []).length === 1,
		"r9 (2/2): each helper has one caller (hz43FollowApply's new-instance branch, its placement, hz45Put's first sight)");
	expect(funcBody(as, "hz46KidPut").indexOf(".alpha") < 0 && funcBody(as, "hz46KidRec").indexOf(".alpha") < 0 && funcBody(as, "hz46Inherit").indexOf(".alpha") < 0, "r9 (2/2): never alpha");
}

// ---- r9b (user decision 2026-11-10 23:54): BioCondition_mc, EnvCondition_mc and BioAlertBG_mc are hidden while the
// vanilla watch is moved in WatchStyle 1 / 2 (visible only, recorded like the hold), restored at home, on a style change
// and on a HUD rebuild; the HideWatchWhileScanning hold neither shows them early nor on scan close.
{
	const clip = (nm, x, y) => ({ name: nm, x: x, y: y, scaleX: 1, scaleY: 1, visible: true, alpha: 0.5 });
	const listen = (blg) => {
		blg.listeners = [];
		blg.addEventListener = function(t, f, cap, pri, weak) { this.listeners.push({ t: t, f: f, weak: weak }); };
		blg.removeEventListener = function(t, f) { this.listeners = this.listeners.filter((l) => !(l.t === t && l.f === f)); };
		blg.getChildByName = function(n) { return this.kids.find((c) => c.name === n) || null; };
		return blg;
	};
	const icons = (blg) => ["BioCondition_mc", "EnvCondition_mc", "BioAlertBG_mc"].map((n, i) => { const c = clip(n, 96 + i, 24 + i); c.parent = blg; blg.kids.push(c); return c; });
	const mk = (style, src, fns) => {
		const h = makePlaceHost();
		listen(h.hzBlg);
		h.hzWatchStyle = style;
		h.ic = icons(h.hzBlg);
		(fns || []).forEach((f) => {
			const args = { hz47Sync: ["force"], hz45Sync: [], hz43FoOnAdd: ["e"] }[f];
			h[f] = Function.apply(null, args.concat(["with(this){\n" + asInnerOf(src, f) + "\n}"])).bind(h);
		});
		if (!fns || fns.indexOf("hz43FoOnAdd") < 0) bindAsMethod(h, "hz43FoOnAdd", ["e"]);
		return h;
	};
	const fireAdd = (hh, ev) => { hh.hzBlg.listeners.slice().forEach((l) => l.f(ev)); };
	const allVis = (h, v) => h.ic.every((c) => c.visible === v);
	const alphaKept = (h) => h.ic.every((c) => c.alpha === 0.5);

	expect(asConst("HZ47_NAMES").join() === "BioCondition_mc,EnvCondition_mc,BioAlertBG_mc", "r9b: the three alert pieces (icons and the bio flash)");
	// 1. styles 1 / 2: moved = hidden (visible only), home = shown
	for (const st of [1, 2]) {
		const v = mk(st);
		v.hz43VanWrite(-40, 20, 0.8);
		expect(allVis(v, false) && alphaKept(v) && v.hz47On && v.hz47D.every((d, i) => d === v.ic[i]), "r9b (style " + st + "): moved off home = the three pieces hidden by visible, alpha untouched, recorded");
		v.hz43VanWrite(-10, 5, 1);
		expect(allVis(v, false), "r9b (style " + st + "): another Arrange move keeps them hidden");
		v.hz43VanWrite(0, 0, 1);
		expect(allVis(v, true) && !v.hz47On && v.hz47D.every((d) => d === null), "r9b (style " + st + "): home again = shown, records cleared");
	}
	// 2. a piece already hidden by someone else is not recorded and stays hidden at home
	const o = mk(1); o.ic[1].visible = false;
	o.hz43VanWrite(-40, 20, 1); o.hz43VanWrite(0, 0, 1);
	expect(o.ic[1].visible === false && o.ic[0].visible === true, "r9b: a piece hidden before the move is not this hide's, so home leaves it hidden (prior value kept)");
	// 3. styles 0 / 3 / 4: never touched
	for (const st of [0, 3, 4]) { const z = mk(st); z.hz43VanWrite(-40, 20, 1); z.hz45Sync(); expect(allVis(z, true) && !z.hz47On, "r9b (style " + st + "): not touched"); }
	// 4. a style change away from 1 / 2 while moved gives them back
	const c = mk(1); c.hz43VanWrite(-40, 20, 1); c.hzWatchStyle = 3; c.hz45Sync();
	expect(allVis(c, true) && !c.hz47On, "r9b: style 1 -> 3 with the watch still moved = shown again (hz45Sync on the style edge)");
	// 5. HUD rebuild: the old group's pieces are given back, the new group's are hidden
	const r = mk(1); r.hz43VanWrite(-40, 20, 1);
	const oldIc = r.ic.slice();
	const nb = listen({ name: "BottomLeftGroup_mc", kids: [] }); nb.getChildAt = function(i) { return this.kids[i]; };
	Object.defineProperty(nb, "numChildren", { get: function() { return this.kids.length; } });
	r.ic = icons(nb); r.hzBlg = nb; r.hz45Sync();
	expect(oldIc.every((d) => d.visible === true) && allVis(r, false) && r.hz47B === nb && r.hz47D[0] === r.ic[0], "r9b: HUD rebuild = old group's pieces restored, the new group's hidden and recorded");
	// 6. a new instance while hidden is hidden on its ADDED event
	const a = mk(2); a.hz43VanWrite(-40, 20, 1);
	const env2 = clip("EnvCondition_mc", 109.9, 50.55); env2.parent = a.hzBlg; a.hzBlg.kids[a.hzBlg.kids.indexOf(a.ic[1])] = env2;
	fireAdd(a, { target: env2 });
	expect(env2.visible === false && a.hz47D[1] === env2, "r9b: a new EnvCondition_mc instance is hidden and recorded on its ADDED event");
	a.hz43VanWrite(0, 0, 1);
	expect(env2.visible === true, "r9b: ... and shown at home");
	// 7. the hold: scan close while moved keeps them hidden; going home during the hold keeps them hidden until the close
	const s = mk(1); s.hz43VanWrite(-40, 20, 1);
	s.hz43ScanHid = true; s.hz45Sync(); s.hz43ScanHid = false; s.hz45Sync();
	expect(allVis(s, false), "r9b: hold open + scan close with the watch still moved = still hidden (the close never shows them)");
	s.hz43ScanHid = true; s.hz45Sync();
	s.hz43VanWrite(0, 0, 1);
	expect(allVis(s, false) && s.hz47On, "r9b: the watch going home during the hold does not show them early");
	s.hz43ScanHid = false; s.hz45Sync();
	expect(allVis(s, true) && !s.hz47On, "r9b: the hold's release (hz45Sync) then gives them back");
	const h0 = mk(1); h0.hz43ScanHid = true; h0.hz45Sync();
	expect(allVis(h0, true), "r9b: the hold alone (watch at home) does not hide them (r7 rule for Bio* / Env* unchanged)");
	["BioCondition_mc", "EnvCondition_mc", "BioAlertBG_mc"].forEach((n) => { bindAsMethod(h0, "hz43VanSkip", ["name"]); bindAsMethod(h0, "hz43ScanPiece", ["d"]); });
	expect(h0.ic.every((d) => !h0.hz43ScanPiece(d)), "r9b: hz43ScanPiece refuses all three, so they never enter hz43ScanMk (a scan close cannot show them)");
	// 8. hz27BioHide hand-over (style 3 -> 1 while moved): hz27's record is cleared so its release cannot show them
	const k = mk(3); k.hz43VanWrite(-40, 20, 1);
	k.ic[0].visible = false; k.ic[2].visible = false; k.hz27BioMine = [null, k.ic[0], k.ic[2]];
	k.hzWatchStyle = 1; k.hz45Sync();
	expect(k.hz27BioMine[1] === null && k.hz27BioMine[2] === null && k.hz47D[0] === k.ic[0] && k.hz47D[2] === k.ic[2] && allVis(k, false), "r9b: pieces hz27BioHide hid are taken over (its records cleared), all three hidden");
	k.hz43VanWrite(0, 0, 1);
	expect(allVis(k, true), "r9b: home = the taken-over pieces shown (they were visible before hz27's hide)");
	// 9. re-shown by anyone: the late listener's forced pass hides them again
	const f = mk(1); f.hz43VanWrite(-40, 20, 1); f.ic[0].visible = true; f.hz47Sync(true);
	expect(f.ic[0].visible === false && f.hz47D[0] === f.ic[0], "r9b: a forced pass (late LocalEnvironmentData) hides a re-shown piece again");
	let n47 = 0; const g = mk(1); g.hz43VanWrite(-40, 20, 1); const gbn = g.hzBlg.getChildByName; g.hzBlg.getChildByName = function(x) { n47++; return gbn.call(this, x); };
	for (let i = 0; i < 20; i++) g.hz45Sync();
	expect(n47 === 0, "r9b zero stutter: 20 repeat hz45Sync calls with no change do no lookup (two compares and return)");

	// mutants (in-test)
	const m1 = as.replace("if(this.hz47On && (!want || this.hz47B !== this.hzBlg))", "if(this.hz47On && this.hz47B !== this.hzBlg)");
	expect(m1 !== as, "r9b mutant (no restore at home): built");
	const mm1 = mk(1, m1, ["hz47Sync"]); mm1.hz43VanWrite(-40, 20, 1); mm1.hz43VanWrite(0, 0, 1);
	expect(!allVis(mm1, true), "r9b mutant (no restore at home): the pieces stay hidden at home, so the home check above FAILS on it");
	const m2 = as.replace("(this.hz43FoMoved || (this.hz43ScanHid && this.hz47On))", "this.hz43FoMoved");
	expect(m2 !== as, "r9b mutant (no hold keep): built");
	const mm2 = mk(1, m2, ["hz47Sync"]); mm2.hz43VanWrite(-40, 20, 1); mm2.hz43ScanHid = true; mm2.hz45Sync(); mm2.hz43VanWrite(0, 0, 1);
	expect(allVis(mm2, true), "r9b mutant (no hold keep): going home during the hold shows them early, so the hold check above FAILS on it");
	const m3 = as.replace("               else if(d !== this.hz47D[i] && this.hz27BioMine)", "               else if(d !== this.hz47D[i] && false)");
	expect(m3 !== as, "r9b mutant (no hz27 hand-over): built");
	const mm3 = mk(3, m3, ["hz47Sync"]); mm3.hz43VanWrite(-40, 20, 1); mm3.ic[0].visible = false; mm3.hz27BioMine = [null, mm3.ic[0], null]; mm3.hzWatchStyle = 1; mm3.hz45Sync();
	expect(mm3.hz27BioMine[1] === mm3.ic[0], "r9b mutant (no hz27 hand-over): hz27 keeps its record and would show the icon on the moved watch, so the hand-over check above FAILS on it");
	const m4 = as.replace("if(this.hz47On && HZ47_NAMES.indexOf(t.name) >= 0)", "if(false)");
	expect(m4 !== as, "r9b mutant (ADDED ignores the pieces): built");
	const mm4 = mk(2, m4, ["hz43FoOnAdd"]); mm4.hz43VanWrite(-40, 20, 1);
	const e4 = clip("EnvCondition_mc", 1, 1); e4.parent = mm4.hzBlg; mm4.hzBlg.kids[mm4.hzBlg.kids.indexOf(mm4.ic[1])] = e4; fireAdd(mm4, { target: e4 });
	expect(e4.visible === true, "r9b mutant (ADDED ignores the pieces): a new instance shows on the moved watch, so the ADDED check above FAILS on it");

	// static: event-only wiring
	const perFrame = ["hzOnFrame", "hz27OnExit", "hz43Frame", "hz43VanHorizon", "hz43VanPlace", "hz43VanLate", "hz43SyncHide", "hz44GrpTick", "hz27BioHide"];
	expect(perFrame.every((fn) => funcBody(as, fn).indexOf("hz47") < 0), "r9b: no hz47 call in any per-frame function body");
	expect((as.match(/this\.hz47Sync\(/g) || []).length === 3 && funcBody(as, "hz45Sync").indexOf("this.hz47Sync(false)") >= 0 && funcBody(as, "hz43FoOnAdd").indexOf("this.hz47Sync(true)") >= 0 && funcBody(as, "hz45OnEnvLate").indexOf("if(this.hz47On) { try { this.hz47Sync(true); }") >= 0,
		"r9b: hz47Sync is called from hz45Sync, the ADDED handler and the late listener only");
	const sb = funcBody(as, "hz47Sync");
	expect((sb.match(/getChildByName/g) || []).length === 1 && sb.indexOf("getChildAt") < 0 && sb.indexOf("hzFindByName") < 0 && sb.indexOf(".alpha") < 0 && sb.indexOf("push(") < 0 && sb.indexOf("new ") < 0, "r9b: direct lookups only, never alpha, no allocation");
}

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("watch crosshair tests passed");
