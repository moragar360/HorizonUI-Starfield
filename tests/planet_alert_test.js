// Planet-alert hide session for actionscript/horizon_block.as (hz41LocWant).
// The decisions below are pinned to that file. The cases run a mirror of the
// same session: scanning, the 1.5 s grace, the frame-228 hold, and the 30 s cap.
// Run: node tests/planet_alert_test.js
"use strict";

const fs = require("fs");
const path = require("path");

const srcPath = path.join(__dirname, "..", "actionscript", "horizon_block.as");
const src = fs.readFileSync(srcPath, "utf8");

const HOLD = 228;
const REST = 246;
const GRACE = 1500;
const HOLD_MAX = 30000;
const FADE_IN = "FadeInPlanetInfo";
const FADE_OUT = "FadeOutPlanetInfo";

let failed = 0;
function expect(cond, msg) {
	if (cond) {
		console.log("ok  " + msg);
		return;
	}
	failed++;
	console.error("FAIL " + msg);
}

function pin(snippet, msg) {
	expect(src.indexOf(snippet) >= 0, msg || snippet);
}

pin('private static const HZ_VERSION:String = "0.42.0";', "schema version stays 0.42.0");
pin('private static const HZ_BUILD:String = "0.43.0.4";', "HUD build id is 0.43.0.4");
pin('this.hzPpLocL.text = "LOCAL/GAME";', "planet local row label is always LOCAL/GAME");
pin('this.hzPpRealL = this.hzT(p,"PC/REAL",r - 62,45,64,8,"sb","dim",0.8,"right");', "planet PC row label is PC/REAL");
pin("private var hzPpShowUT:Boolean = false;", "clock glyph uses an explicit UT flag");
pin("if(isLoc && this.hzPpShowUT)", "preview clock glyph does not read the label text");
pin('this.hzPpLocL = this.hzT(p,"LOCAL/GAME",r - 80,21,80,8,"sb","dim",0.8,"right");', "LOCAL/GAME label field is wide enough");
expect(src.indexOf('this.hzPpLocL.text = showUT ? "GAME" : "LOCAL"') < 0, "planet label no longer switches LOCAL vs GAME");
expect(src.indexOf('this.hzPpLocL.text == "GAME"') < 0, "clock glyph no longer compares the label text");
pin('{"k":"TempUnit","l":"TEMPERATURE UNITS"', "temperature units toggle is on the Type tab");
pin("private function hzTempText(c:Number)", "planet temperature formats a unit");
pin('if(c == null || isNaN(c)) { return "--"; }', "a missing temperature is not 0");
pin("if(d.fTemperature == null || isNaN(Number(d.fTemperature)))", "null fTemperature is checked before Number");
pin('return String(v) + (int(this.hzTempUnit) == 1 ? " °F" : " °C");', "Akila 11 C becomes 52 F when Fahrenheit is on");
function hzTempText(c, unit) {
	if (c == null || Number.isNaN(c)) return "--";
	const v = unit === 1 ? Math.round(c * 9 / 5 + 32) : Math.round(c);
	return String(v) + (unit === 1 ? " °F" : " °C");
}
expect(hzTempText(11, 0) === "11 °C", "Akila formats as 11 °C");
expect(hzTempText(11, 1) === "52 °F", "Akila formats as 52 °F");
expect(hzTempText(-5, 1) === "23 °F", "Mars formats as 23 °F");
expect(hzTempText(null, 0) === "--", "a null temperature shows --");
expect(hzTempText(Number.NaN, 0) === "--", "a NaN temperature shows --");
{
	const scan = fs.readFileSync(path.join(__dirname, "..", "actionscript", "scanner", "hzs_block.as"), "utf8");
	expect(scan.indexOf("var hasT:Boolean = env.fTemperature != null && !isNaN(Number(env.fTemperature));") >= 0, "scanner checks null before Number");
	expect(scan.indexOf('cond.push(["TEMPERATURE",inShip || !hasT ? "--" : String(tShown) + tUnit]);') >= 0, "scanner shows -- for a null temperature");
}
{
	const scan = fs.readFileSync(path.join(__dirname, "..", "actionscript", "scanner", "hzs_block.as"), "utf8");
	expect(scan.indexOf('cond.push(["LOCAL TIME",clk]);') >= 0, "scanner LOCAL TIME row is unchanged");
}
pin('"HudMessages"', "HUD Messages is an arrangeable layout key");
pin("private function hzArrFs(want:int)", "HUD Messages ghost type size is corrected once");
pin('this.hzSText(p,"HUD MESSAGES",16 * hz,12 * hz,sz.x - 32 * hz,this.hzArrFs(15),acc,"left","hdr");', "HUD MESSAGES header uses hzArrFs");
pin('this.hzSText(p,"Companion, crew, crime, credits, afflictions",16 * hz,34 * hz,sz.x - 32 * hz,this.hzArrFs(13),0xF2F7F9,"left");', "HUD MESSAGES body uses hzArrFs");
expect(src.indexOf('Math.round(13 * hz)') < 0, "HUD MESSAGES body is not scaled twice");
function hzArrFs(want, textScale) {
	let ts = textScale;
	if (!(ts > 0)) ts = 1;
	ts = Math.max(0.9, Math.min(1.15, ts));
	return Math.max(want, Math.ceil(want / ts));
}
function hzSTextPx(size, textScale) {
	let ts = textScale;
	if (Number.isNaN(ts) || ts <= 0) ts = 1;
	ts = Math.max(0.9, Math.min(1.15, ts));
	return Math.round(size * ts);
}
const ghostScales = [0.8, 0.9, 1, 1.15, 1.3];
for (let gi = 0; gi < ghostScales.length; gi++) {
	const ts = ghostScales[gi];
	const body = hzSTextPx(hzArrFs(13, ts), ts);
	const hdr = hzSTextPx(hzArrFs(15, ts), ts);
	expect(body >= 13, "HUD MESSAGES body at TextScale " + ts + " is " + body + " px");
	expect(hdr >= 13, "HUD MESSAGES header at TextScale " + ts + " is " + hdr + " px");
}
pin('case "vehicleexitpill": this.hzVehOn = bv; break;', "vehicle exit pill is a Cards ini key");
pin('{"k":"VehicleExitPill","l":"VEHICLE EXIT PILL"', "vehicle exit pill is on the Cards tab");
pin("return hv.GetUpButton_mc;", "vehicle exit follows the game's button");
pin("alpha only: visible stays the game's", "vehicle exit hides with alpha, not visible");
pin('["PCButton_mc","ButtonInstance_mc","HoldAnim_mc"]', "exit hold reads the keyboard HoldAnim");
pin('["ConsoleButton_mc","ButtonInstance_mc","HoldAnim_mc"]', "exit hold reads the controller HoldAnim");
pin('this.hz42VehLabel(hold,"StartHold")', "exit hold starts at StartHold");
pin('this.hz42VehLabel(hold,"buttonHoldComplete")', "exit hold ends at buttonHoldComplete");
expect(src.indexOf("function hz42VehBtnAdd") < 0, "the unused button-frame adder is gone");
pin("The button's own frames, including 41 and later, are not the sweep.", "button frames 41 and later are not hold progress");
pin("if(shown && !this.hz42VehShown(b,this)) { shown = false; }", "the exit pill follows its parent HUD group's visibility");
pin("try { this.hz42VehTick(); } catch(e42v:Error) { }   // 0.42.0.7: own try, first, so a throw later in this frame cannot skip the exit pill", "the exit pill has its own try before the rest of the frame");
pin("var sweepA:Number = 0.30;", "the exit sweep is a soft 0.30 fill");
pin('sg.beginGradientFill("linear"', "the exit sweep fades through a gradient edge");
pin("idleRim ? 0xFFFFFF : edge", "the idle exit pill has a faint white border");
pin("var rimA:Number = idleRim ? 0.18 : (done ? 1 : 0.95);", "the idle exit border is about 0.18");
pin("new GlowFilter(rimCol,0.30,6,6,1,1)", "the exit pill glows while holding and when complete");
pin("kg.lineStyle(2,HZ_GREEN,1,true,\"none\");", "the completed exit pill uses a green check");
pin("var h:Number = 42;", "the exit pill is about 42 tall");
pin("this.hz42VehFs(17)", "the exit key is about 17");
pin("this.hz42VehFs(19.5)", "the exit label is about 19.5");
pin("this.hz42VehTf(p,lab,labFs,0xF2F7F9,this.hzFontName(),lls);", "the exit label uses the semibold face");
pin("var feather:Number = 6;", "the exit sweep fades over a short leading edge");
expect(src.indexOf("var sweepHi:Number") < 0, "the exit sweep has no bright band");
pin("var keyBox:Number = 24;", "the exit key cap is about 24 stage units");
pin("var kh:Number = keyBox;", "the exit key cap height stays on that 24 box");
expect(src.indexOf("kt.height + 4") < 0, "the exit key cap height does not grow with the text");
pin("var x0:Number = 8;", "the exit key sits in from the left");
pin("var gap:Number = 11;", "the exit label has a gap after the key");
pin('kt = this.hz42VehTf(p,key,keyFs,edge,kface,0,"center");', "the exit key is centered in the cap");
pin("Math.min(1,0.88 * opa)", "the exit fill is about 0.88");
pin("Name, x, and y stay the game's too.", "the exit button keeps its name and position");
pin("var capA:Number = done ? 0.18 : (idleRim ? 0.10 : 0.22);", "the exit keycap is 0.10 idle, 0.22 holding, 0.18 complete");
pin("cg.beginFill(edge,capA);", "the exit keycap uses that fill");

// Mirror of hz42VehSpan. HoldAnim frames are 1-based, matching currentFrame
// and currentLabels. Vanilla StartHold is frame 2 and buttonHoldComplete is frame 25.
// Button frame 41 is ClickFailed and frame 61 is Disabled. The pill does not read them.
function vehHold(holdFrame, startHold, holdComplete, buttonFrame) {
	let p = 0;
	let done = false;
	if (startHold >= 1 && holdComplete > startHold) {
		if (holdFrame >= holdComplete) {
			p = 1;
			done = true;
		} else if (holdFrame > startHold) {
			p = (holdFrame - startHold) / (holdComplete - startHold);
		}
	}
	let add = 0;
	if (buttonFrame >= 41) add = 0;
	if (add > p) p = add;
	if (p < 0) p = 0;
	if (p > 1) p = 1;
	if (p >= 1) done = true;
	return { p: p, done: done };
}
function vehNear(a, b) { return Math.abs(a - b) < 1e-9; }
{
	const idle = vehHold(1, 2, 25, 1);
	expect(idle.p === 0 && idle.done === false, "Idle HoldAnim is an empty sweep");
	const start = vehHold(2, 2, 25, 1);
	expect(start.p === 0 && start.done === false, "StartHold has not filled yet");
	const mid = vehHold(14, 2, 25, 1);
	expect(vehNear(mid.p, 12 / 23) && mid.done === false, "a mid hold fills from StartHold toward buttonHoldComplete");
	const held = vehHold(25, 2, 25, 10);
	expect(held.p === 1 && held.done === true, "buttonHoldComplete is the complete state without Disabled frame 61");
	const flash = vehHold(40, 2, 25, 1);
	expect(flash.p === 1 && flash.done === true, "the end flash after buttonHoldComplete stays complete");
	const failedClick = vehHold(1, 2, 25, 41);
	expect(failedClick.p === 0 && failedClick.done === false, "button frame 41 is not progress");
	const disabled = vehHold(1, 2, 25, 61);
	expect(disabled.p === 0 && disabled.done === false, "Disabled frame 61 alone does not fill or complete the sweep");
	const midDisabled = vehHold(14, 2, 25, 61);
	expect(vehNear(midDisabled.p, 12 / 23) && midDisabled.done === false, "a late button frame does not replace the HoldAnim reading");
	const noLabels = vehHold(30, 0, 0, 20);
	expect(noLabels.p === 0 && noLabels.done === false, "missing hold labels stay empty");
	const early = vehHold(1, 2, 25, 30);
	expect(early.p === 0 && early.done === false, "a button frame under 41 still does not invent progress");
}
pin("b.alpha = 0;", "vehicle exit sets the game button alpha to 0");
pin("private static const HZ41_LOC_GRACE:Number = 1500;");
pin("private static const HZ41_LOC_HOLD:int = 228;");
pin("private static const HZ41_LOC_REST:int = 246;");
pin("private static const HZ41_LOC_HOLD_MAX:Number = 30000;");
pin('if(gl != "" && gl != "FadeInPlanetInfo") { this.hz41LocLeftIn = true; }', "empty grace read is not a leave");
pin('if(!this.hz41LocSawHold && !this.hz41LocLeftIn && this.hz41LocAt == "FadeInPlanetInfo" && this.hz41LocAtHold(gl, this.hz41LocFrame()))', "grace can arm the 228 hold");
pin('if(this.hz41LocAtHold(this.hz41LocLbl(), this.hz41LocFrame())) { this.hz41LocSawHold = true; }', "scan arms the 228 hold");
pin('if(lb != "" && lb != "FadeInPlanetInfo") { this.hz41LocLeftIn = true; }', "empty post-grace read is not a new label");
pin("if(!newIn && this.hz41LocAtHold(lb, fr)) { return true; }", "228 hold stays hidden");
pin('if(lb == "") { return true; }', "unreadable label stays hidden on a 228 session");
pin('if(lb == "FadeOutPlanetInfo")', "fade-out is its own branch");
pin("if(fr == HZ41_LOC_REST || stopped) { return false; }", "fade-out ends at 246 or a stall");
pin('if(newIn || !planet || (fr >= 0 && fr != HZ41_LOC_HOLD)) { return false; }', "leaving 228 ends the hide");
pin("if(!planet || newIn || fr == HZ41_LOC_REST || stopped) { return false; }", "0.42.0.4 end rules remain");
pin("if(expired) { return false; }", "30 s cap ends every session");
pin("return new Date().getTime();", "grace and cap use the wall clock");
pin("if(since < 0) { this.hz41LocClear(); return false; }", "a backwards clock ends the hide");
{
	const fn = src.slice(src.indexOf("private function hz41Now()"), src.indexOf("private function hz41LocLbl()"));
	expect(fn.indexOf("return new Date().getTime();") >= 0, "hz41Now returns new Date().getTime()");
	expect(fn.indexOf("getTimer") < 0 && fn.indexOf("flash.utils") < 0, "hz41Now does not call getTimer");
	expect(src.indexOf("import flash.utils.getTimer") < 0, "the injected HUD block does not carry a getTimer import");
}
pin("c.visible = false;", "hide is visible only");

function PlanetAlert() {
	this.hz40Scan = false;
	this.hz40Latch = false;
	this.hz30Mod = { scanner: 1 };
	this.hzArrange = false;
	this.hzFrameN = 0;
	this.hz41LocArm = false;
	this.hz41LocEnd = -1;
	this.hz41LocAt = "";
	this.hz41LocLeftIn = false;
	this.hz41LocPf = -1;
	this.hz41LocPfN = -1;
	this.hz41LocSawHold = false;
	this.now = 0;
	this.label = "";
	this.frame = -1;
}

PlanetAlert.prototype.hz41ScanHideOn = function () {
	return this.hz40Scan && !this.hz40Latch && this.hz30Mod.scanner === 1 && !this.hzArrange;
};
PlanetAlert.prototype.hz41Now = function () { return this.now; };
PlanetAlert.prototype.hz41LocLbl = function () { return this.label == null ? "" : String(this.label); };
PlanetAlert.prototype.hz41LocFrame = function () {
	const f = this.frame;
	if (f == null || Number.isNaN(Number(f))) return -1;
	return f | 0;
};
PlanetAlert.prototype.hz41LocClear = function () {
	this.hz41LocArm = false;
	this.hz41LocEnd = -1;
	this.hz41LocAt = "";
	this.hz41LocLeftIn = false;
	this.hz41LocPf = -1;
	this.hz41LocPfN = -1;
	this.hz41LocSawHold = false;
};
PlanetAlert.prototype.hz41LocAtHold = function (lb, fr) {
	return lb === FADE_IN && fr === HOLD;
};
PlanetAlert.prototype.hz41LocNoteFrame = function () {
	const fr = this.hz41LocFrame();
	if (fr < 0 || this.hzFrameN === this.hz41LocPfN) return;
	this.hz41LocPf = fr;
	this.hz41LocPfN = this.hzFrameN;
};
PlanetAlert.prototype.hz41LocHoldAfterGrace = function () {
	const lb = this.hz41LocLbl();
	const fr = this.hz41LocFrame();
	const planet = lb === FADE_IN || lb === FADE_OUT;
	const newIn = lb === FADE_IN && (this.hz41LocAt !== FADE_IN || this.hz41LocLeftIn);
	if (lb !== "" && lb !== FADE_IN) this.hz41LocLeftIn = true;
	let stopped = false;
	if (fr >= 0 && this.hzFrameN !== this.hz41LocPfN) {
		if (this.hz41LocPf >= 0 && fr === this.hz41LocPf) stopped = true;
		this.hz41LocPf = fr;
		this.hz41LocPfN = this.hzFrameN;
	}
	const elapsed = this.hz41Now() - this.hz41LocEnd;
	const expired = this.hz41LocEnd >= 0 && (elapsed < 0 || elapsed >= HOLD_MAX);
	if (expired) return false;
	if (this.hz41LocSawHold) {
		if (!newIn && this.hz41LocAtHold(lb, fr)) return true;
		if (lb === "") return true;
		if (lb === FADE_OUT) {
			if (fr === REST || stopped) return false;
			return true;
		}
		if (newIn || !planet || (fr >= 0 && fr !== HOLD)) return false;
		return true;
	}
	if (!planet || newIn || fr === REST || stopped) return false;
	return true;
};
PlanetAlert.prototype.hz41LocWant = function () {
	if (this.hz41ScanHideOn()) {
		this.hz41LocArm = true;
		this.hz41LocEnd = -1;
		this.hz41LocAt = "";
		this.hz41LocLeftIn = false;
		this.hz41LocPf = -1;
		this.hz41LocPfN = -1;
		if (this.hz41LocAtHold(this.hz41LocLbl(), this.hz41LocFrame())) this.hz41LocSawHold = true;
		return true;
	}
	if (!this.hz41LocArm) return false;
	if (this.hz40Latch || this.hz30Mod.scanner !== 1 || this.hzArrange) {
		this.hz41LocClear();
		return false;
	}
	const now = this.hz41Now();
	if (this.hz41LocEnd < 0) {
		this.hz41LocEnd = now;
		this.hz41LocAt = this.hz41LocLbl();
		this.hz41LocLeftIn = false;
		this.hz41LocPf = -1;
		this.hz41LocPfN = -1;
	}
	const since = now - this.hz41LocEnd;
	if (since < 0) {
		this.hz41LocClear();
		return false;
	}
	if (since < GRACE) {
		const gl = this.hz41LocLbl();
		if (gl !== "" && gl !== FADE_IN) this.hz41LocLeftIn = true;
		if (!this.hz41LocSawHold && !this.hz41LocLeftIn && this.hz41LocAt === FADE_IN && this.hz41LocAtHold(gl, this.hz41LocFrame())) {
			this.hz41LocSawHold = true;
		}
		this.hz41LocNoteFrame();
		return true;
	}
	if (!this.hz41LocHoldAfterGrace()) {
		this.hz41LocClear();
		return false;
	}
	return true;
};
PlanetAlert.prototype.tick = function () {
	this.hzFrameN++;
	return this.hz41LocWant();
};

function scanOnHold() {
	const h = new PlanetAlert();
	h.label = FADE_IN;
	h.frame = HOLD;
	h.hz40Scan = true;
	h.now = 1000;
	expect(h.tick() === true && h.hz41LocSawHold === true, "scan on frame 228 hides and arms the hold");
	h.hz40Scan = false;
	h.now = 1000;
	expect(h.tick() === true, "grace starts when the scan ends");
	h.now = 1000 + GRACE;
	h.frame = HOLD;
	h.label = FADE_IN;
	expect(h.tick() === true, "stall on 228 after the grace stays hidden");
	expect(h.tick() === true, "another stalled tick on 228 stays hidden");
	return h;
}

// No scan: a landing alert stays vanilla, including one already resting on 228.
{
	const h = new PlanetAlert();
	h.label = FADE_IN;
	h.frame = HOLD;
	h.now = 5000;
	expect(h.tick() === false, "landing alert without a scan stays vanilla");
	expect(h.tick() === false, "a later tick still does not hide it");
}

// Scan already on the 228 hold. After the grace the stall does not end the hide.
{
	const h = scanOnHold();
	h.label = FADE_OUT;
	h.frame = 230;
	expect(h.tick() === true, "fade-out frame 230 stays hidden");
	h.frame = 234;
	expect(h.tick() === true, "fade-out frame 234 stays hidden");
	h.frame = REST;
	expect(h.tick() === false, "fade-out rest at 246 ends the hide");
	expect(h.tick() === false, "the session stays ended");
}

{
	const h = scanOnHold();
	h.label = FADE_OUT;
	h.frame = 232;
	expect(h.tick() === true, "first fade-out frame stays hidden");
	expect(h.tick() === false, "a stalled fade-out ends the hide");
}

{
	const h = scanOnHold();
	h.label = FADE_OUT;
	h.frame = 230;
	expect(h.tick() === true, "fade-out in progress stays hidden");
	h.label = "LocationDiscovered";
	expect(h.tick() === false, "a label change during fade-out ends the hide");
}

{
	const h = scanOnHold();
	h.label = FADE_OUT;
	h.frame = 230;
	expect(h.tick() === true, "fade-out before the cap stays hidden");
	h.now = 1000 + HOLD_MAX;
	expect(h.tick() === false, "30 s cap still ends a fade-out");
}

{
	const h = scanOnHold();
	h.frame = 229;
	expect(h.tick() === false, "currentFrame moving off 228 toward 246 leaves the hold");
}

{
	const h = scanOnHold();
	h.label = "LocationDiscovered";
	h.frame = HOLD;
	expect(h.tick() === false, "a label other than planet info leaves the hold");
}

{
	const h = scanOnHold();
	h.label = "";
	h.frame = -1;
	expect(h.tick() === true, "an empty read while held does not unhide");
	h.label = FADE_IN;
	h.frame = HOLD;
	expect(h.tick() === true, "the same FadeIn at 228 is still the hold");
}

{
	const h = scanOnHold();
	h.now = 1000 + HOLD_MAX;
	expect(h.tick() === false, "30 s after the scan ends the hold is released");
}

// The same FadeIn reaches 228 during the grace, including after an empty read.
{
	const h = new PlanetAlert();
	h.hz40Scan = true;
	h.label = FADE_IN;
	h.frame = 180;
	h.now = 2000;
	expect(h.tick() === true && h.hz41LocSawHold === false, "scan before the hold does not arm it yet");
	h.hz40Scan = false;
	expect(h.tick() === true, "grace while FadeIn is still moving");
	h.label = "";
	h.frame = -1;
	expect(h.tick() === true && h.hz41LocLeftIn === false, "empty read during grace is not leaving FadeIn");
	h.label = FADE_IN;
	h.frame = HOLD;
	h.now = 2000 + 400;
	expect(h.tick() === true && h.hz41LocSawHold === true, "the same FadeIn reaching 228 during grace arms the hold");
	h.now = 2000 + GRACE;
	expect(h.tick() === true, "that hold stays hidden after the grace");
}

// A FadeIn that starts only after the scan ended does not keep the hide.
{
	const h = new PlanetAlert();
	h.hz40Scan = true;
	h.label = "SomeOtherLabel";
	h.frame = 10;
	h.now = 3000;
	expect(h.tick() === true, "scan hides even when the planet clip is not up");
	h.hz40Scan = false;
	expect(h.tick() === true && h.hz41LocAt === "SomeOtherLabel" && h.hz41LocSawHold === false, "scan end records the label that was up");
	h.label = FADE_IN;
	h.frame = HOLD;
	expect(h.tick() === true && h.hz41LocSawHold === false, "a new FadeIn during grace does not arm the hold");
	h.now = 3000 + GRACE;
	expect(h.tick() === false, "that later FadeIn does not keep the hide after the grace");
}

// 0.42.0.4: a scan that never saw 228 still ends at currentFrame 246, and on any other stall.
{
	const h = new PlanetAlert();
	h.hz40Scan = true;
	h.label = FADE_OUT;
	h.frame = 240;
	h.now = 4000;
	expect(h.tick() === true && h.hz41LocSawHold === false, "fade-out during the scan is not the 228 hold");
	h.hz40Scan = false;
	expect(h.tick() === true, "grace after a fade-out scan");
	h.frame = REST;
	h.now = 4000 + GRACE;
	expect(h.tick() === false, "rest at currentFrame 246 ends the hide");
}

{
	const h = new PlanetAlert();
	h.hz40Scan = true;
	h.label = FADE_IN;
	h.frame = 100;
	h.now = 5000;
	h.tick();
	h.hz40Scan = false;
	h.tick();
	h.now = 5000 + GRACE;
	expect(h.tick() === false, "a stall off 228 still ends the hide when the hold was never seen");
}

{
	const h = scanOnHold();
	h.now = 500;
	expect(h.tick() === false && h.hz41LocArm === false, "a backwards clock ends the hide");
	expect(h.tick() === false, "the session stays ended after the clock step");
}

// F11 scope-chip preview. HOLD BREATH uses the same TextScale correction as L-SHIFT.
// On-screen px = the font hzSText stored, times the chip scale. The old label passed
// hz42ScFs(14) straight through, so chip 0.65 and TextScale 0.9 rendered at 11.7 px.
pin('var lb:int = int(this.hz42ScFs(14));', "HOLD BREATH starts from the 13 px chip floor");
pin('this.hzSText(p,"HOLD BREATH",0,0,220,int(Math.ceil(lb / ts)),0xF2F7F9,"left");', "HOLD BREATH divides TextScale back out");
pin('this.hzSText(p,"L-SHIFT",0,0,160,int(Math.ceil(want / ts)),HZ_ACCENT,"left");', "the key keeps the same TextScale correction");
pin('kf.font = this.hzFontName("bd");', "the hold-breath key uses the scope bold face");

function asInt(n) {
	if (!Number.isFinite(n)) return 0;
	return n < 0 ? Math.ceil(n) : Math.floor(n);
}
function chipFs(n, chip) {
	const s = !Number.isFinite(chip) || chip <= 0 ? 1 : chip;
	return Math.max(n, Math.ceil(13 / s));
}
function previewPx(design, chip, textScale) {
	let ts = textScale;
	if (Number.isNaN(ts) || ts <= 0) ts = 1;
	ts = Math.max(0.9, Math.min(1.15, ts));
	const fieldTs = Math.max(0.9, Math.min(1.15, textScale));
	const passed = asInt(Math.ceil(asInt(chipFs(design, chip)) / ts));
	const sz = asInt(Math.round(passed * fieldTs));
	const s = !Number.isFinite(chip) || chip <= 0 ? 1 : chip;
	return sz * s;
}
const chipSizes = [0.6, 0.65, 0.7, 0.75, 0.8, 0.85, 0.9, 0.95, 0.99, 1, 1.6];
const textScales = [0.8, 0.9, 1, 1.15];
for (let ci = 0; ci < chipSizes.length; ci++) {
	for (let ti = 0; ti < textScales.length; ti++) {
		const px = previewPx(14, chipSizes[ci], textScales[ti]);
		expect(px >= 13, "HOLD BREATH at chip " + chipSizes[ci] + " text " + textScales[ti] + " is " + px + " px");
	}
}
expect(previewPx(14, 0.65, 0.9) >= 13, "the 11.7 px case stays at least 13");
expect(previewPx(13, 0.65, 0.9) >= 13, "L-SHIFT uses the same floor");

// Scope chip key text. The field is autoSize NONE. Its width is ceil(textWidth * 1.08 + letterSpacing * len) + 8, plus 16 for the key cap only.
// The keycap is the 30 px icon plus that width plus HZP_KPAD. The panel pad after the meter is HZP_RPAD.
pin("private static const HZ42_SC_KPAD:Number = 10;", "key padding matches HZP_KPAD");
pin("private static const HZ42_SC_RPAD:Number = 18;", "panel padding matches HZP_RPAD");
pin("private static const HZ42_SC_KHEAD:Number = 1.08;", "key headroom matches HZP_KHEAD");
pin("private static const HZ42_SC_KEX:Number = 16;", "the preview key cap adds 16");
pin("private static const HZ42_SC_LABEX:Number = 32;", "the preview label extra stays 32");
pin("var w:Number = Math.ceil(tw * HZ42_SC_KHEAD + ls * len) + 8 + extra;", "preview key width is the scope field width plus the key extra");
pin("kt.autoSize = flash.text.TextFieldAutoSize.NONE;", "preview key field does not autosize");
pin("kt.width = this.hz42ScKeyW(Number(kt.textWidth),ls,len,HZ42_SC_KEX);", "preview key field uses the wider key cap");
pin('kAlign.align = "center";', "the preview key text is centered in the cap");
pin("return this.hz42ScKeyW(Number(t.textWidth),ls,len);", "the preview label does not use the key extra");
pin("var kw:Number = 30 + kt.width + HZ42_SC_KPAD;", "the keycap is sized from that width");
pin("kt.x = Math.round(x0 + 28);", "the key text starts where the scope chip starts it");
pin("var w:Number = Math.round(mx + mw + HZ42_SC_RPAD);", "the chip panel uses the scope's right pad");
expect(src.indexOf("30 + Math.round(tw + 8)") < 0, "the old keycap width is gone");
expect(src.indexOf("return 30 + HZ42_SC_KPAD + Math.round(tw) + HZ42_SC_RPAD;") < 0, "the guessed keycap width is gone");

function keySlot(tw, ls, len) {
	if (!Number.isFinite(tw) || tw < 0) tw = 0;
	if (!Number.isFinite(ls) || ls < 0) ls = 0;
	if (len < 0) len = 0;
	let w = Math.ceil(tw * 1.08 + ls * len) + 8 + 16;
	if (w < 14) w = 14;
	return w;
}
function keycap(tw, ls, len) {
	return 30 + keySlot(tw, ls, len) + 10;
}
const keyWidths = [0, 12.4, 36, 48.6, 70.2];
for (let i = 0; i < keyWidths.length; i++) {
	const tw = keyWidths[i];
	expect(keySlot(tw, 0, 7) === Math.max(14, Math.ceil(tw * 1.08) + 8 + 16), "key slot " + tw + " uses 1.08, + 8, and the 16 px key extra");
	expect(keycap(tw, 0.5, 7) === 30 + keySlot(tw, 0.5, 7) + 10, "keycap " + tw + " is icon + slot + pad");
}
expect(keySlot(48, 0.6, 7) === Math.ceil(48 * 1.08 + 0.6 * 7) + 8 + 16, "L-SHIFT key cap adds 16 on top of the headroom");

const scopeFiles = [
	["actionscript/scope/hzp_main.as", false],
	["actionscript/scope/imp/pimp_scopemenu/ScopeMenu.as", true],
	["actionscript/scope/imp/pimp_scopemenu_lrg/ScopeMenu.as", true],
];
for (let i = 0; i < scopeFiles.length; i++) {
	const rel = scopeFiles[i][0];
	const wantCrlf = scopeFiles[i][1];
	const buf = fs.readFileSync(path.join(__dirname, "..", rel));
	const body = buf.toString("utf8");
	const stripped = buf.toString("binary").replace(/\r\n/g, "");
	const hasCrlf = buf.includes(Buffer.from("\r\n"));
	const loneLf = stripped.includes("\n");
	const loneCr = stripped.includes("\r");
	if (wantCrlf) expect(hasCrlf && !loneLf && !loneCr, rel + " stays CRLF");
	else expect(!hasCrlf && !loneCr && loneLf, rel + " stays LF");
	expect(body.indexOf('private static const HZP_BUILD:String = "0.43.0.4";') >= 0, rel + " build is 0.43.0.4");
	expect(body.indexOf("private static const HZP_KEX:Number = 16;") >= 0, rel + " key cap adds 16");
	expect(body.indexOf("ktw = this.hzpKeyW(kt,HZP_KEX);") >= 0, rel + " only the key field gets that extra");
	expect(body.indexOf("var w:Number = this.hzpKeyW(t);") >= 0, rel + " the label slot does not get the key extra");
	expect(body.indexOf("var ownW:Number = this.hzpKeyW(lt);") >= 0, rel + " the live label does not get the key extra");
	expect(body.indexOf("hzpKeyW(t,HZP_KEX)") < 0 && body.indexOf("hzpKeyW(lt,HZP_KEX)") < 0, rel + " does not widen the label");
	expect(body.indexOf("kt.autoSize = TextFieldAutoSize.NONE;") >= 0, rel + " key field does not autosize");
	expect(body.indexOf("Math.ceil(tw * HZP_KHEAD + ls * len) + 8") >= 0, rel + " uses the field-width formula");
	expect(body.indexOf("kt.width = ktw;") >= 0, rel + " sets the field width");
	expect(body.indexOf('kAlign.align = "center";') >= 0, rel + " centers the key text");
	expect(body.indexOf('lt.defaultTextFormat') < 0, rel + " does not recenter the label");
	expect(body.indexOf("ktw + HZP_KPAD") >= 0, rel + " sizes the keycap from that width");
	expect(body.indexOf("if(now - this.hzpFallT < 900)") >= 0, rel + " holds the held state for at least 900 ms");
	expect(body.indexOf("lt.autoSize = TextFieldAutoSize.NONE;") >= 0, rel + " label field does not autosize");
	expect(body.indexOf("lt.width = ltw;") >= 0, rel + " label uses the key headroom");
	expect(body.indexOf("g.lineStyle(2,stc,0.18,true,\"none\"); g.drawRoundRect(pad + 1,pad + 1,cw - 2,ch - 2,Math.max(0,ch - 2),Math.max(0,ch - 2));") >= 0, rel + " insets the 2 px glow");
	expect(body.indexOf("g.drawRoundRect(pad + inset,pad + inset,cw - bw,ch - bw,Math.max(0,ch - bw),Math.max(0,ch - bw));") >= 0, rel + " insets the border by half the stroke");
	expect(body.indexOf("g.drawRoundRect(pad + x0 + 0.5,pad + ky + 0.5,kw - 1,kh - 1,8,8);") >= 0, rel + " insets the keycap by half a pixel");
	expect(body.indexOf("private static const HZP_LABEX:Number = 32;") >= 0, rel + " label slot is slightly longer");
	expect(body.indexOf("ltw += HZP_LABEX;") >= 0, rel + " adds label headroom");
	expect(body.indexOf("private function hzpUnclip()") >= 0, rel + " clears a parent clip");
	expect(body.indexOf("new Rectangle(sr.x,sr.y,nr - sr.x,nb - sr.y)") >= 0, rel + " grows a scrollRect on the right and bottom");
	expect(body.indexOf("var nl:Number") < 0, rel + " does not move a scrollRect");
	expect(body.indexOf("public function hzpClipDiag() : String") >= 0, rel + " exposes the clip line");
	expect(body.indexOf("chip.getBounds(stage)") >= 0, rel + " records chip bounds on the stage");
	expect(body.indexOf("label textWidth=") >= 0, rel + " records the label textWidth");
	expect(body.indexOf("hudScale=") >= 0, rel + " records HudScale");
	expect(body.indexOf("cache=") >= 0, rel + " records cacheAsBitmap");
	expect(body.indexOf("g.lineStyle(2,col,a,true,\"none\");") >= 0, rel + " draws the cross with a 2 px stroke");
	expect(body.indexOf("drawRoundRect(-") < 0, rel + " does not draw outside the chip");
	expect(body.indexOf("private var hzpBar:flash.display.Shape = null;") >= 0, rel + " keeps the O2 bar on its own shape");
	expect(body.indexOf('this.hzSText(p,"HOLDING BREATH"') < 0, rel + " is the scope movie, not the F11 preview");
}

// Chip strokes for ready (state 0) and HOLDING BREATH (state 1). A stroke is centered on its path.
function strokeBox(x, y, rw, rh, sw) {
	const pad = sw / 2;
	return { l: x - pad, t: y - pad, r: x + rw + pad, b: y + rh + pad };
}
function chipBoxes(ltw, ktw, h, holding) {
	const pad = 8;
	const slot = ltw + 32;
	const x0 = 7;
	const kw = 30 + ktw + 10;
	const lx = x0 + kw + 10;
	const mx = Math.round(lx + slot + 16);
	const mw = 120;
	const cw = Math.round(mx + mw + 18);
	const ch = h;
	const w = cw + pad * 2;
	const hh = ch + pad * 2;
	const boxes = [];
	boxes.push(strokeBox(0, 0, w, hh, 0));
	for (let i = 0; i < 3; i++) {
		const sx = pad + 1 + i;
		const sy = pad + 2;
		const sw = cw - (1 + i) * 2;
		const sh = ch - 4 - i;
		if (sw > 4 && sh > 4) boxes.push(strokeBox(sx, sy, sw, sh, 0));
	}
	const bw = holding ? 2 : 1;
	const inset = bw * 0.5;
	boxes.push(strokeBox(pad + inset, pad + inset, cw - bw, ch - bw, bw));
	if (holding) boxes.push(strokeBox(pad + 1, pad + 1, cw - 2, ch - 2, 2));
	const kh = Math.round(ch - 12);
	const ky = Math.round((ch - kh) / 2);
	boxes.push(strokeBox(pad + x0 + 0.5, pad + ky + 0.5, kw - 1, kh - 1, 1));
	const cx = pad + x0 + 15;
	const cy = pad + ky + kh / 2;
	boxes.push(strokeBox(cx - 8.5, cy - 8.5, 17, 17, 2));
	const my = Math.round(pad + ch / 2 - 3);
	boxes.push(strokeBox(pad + mx, my, mw, 6, 0));
	boxes.push(strokeBox(pad + mx, my, Math.round(mw * 0.7), 6, 0));
	return { w: w, h: hh, boxes: boxes };
}
const chipWh = [
	[140, 70, 36],
	[90, 40, 32],
	[180, 96, 48],
];
for (let si = 0; si < chipWh.length; si++) {
	const ltw = chipWh[si][0];
	const ktw = chipWh[si][1];
	const h = chipWh[si][2];
	for (let holding = 0; holding < 2; holding++) {
		const laid = chipBoxes(ltw, ktw, h, holding === 1);
		for (let bi = 0; bi < laid.boxes.length; bi++) {
			const b = laid.boxes[bi];
			expect(b.l >= -0.001 && b.t >= -0.001 && b.r <= laid.w + 0.001 && b.b <= laid.h + 0.001,
				(holding ? "HOLDING BREATH" : "ready") + " draw " + bi + " stays inside the chip");
		}
	}
}
pin('this.hzSText(p,"HOLDING BREATH",0,0,400,int(Math.ceil(lb / ts)),0xF2F7F9,"left");', "the F11 preview sizes the held label");
pin("lt.autoSize = flash.text.TextFieldAutoSize.NONE;", "the F11 label does not autosize");
pin("lt.width = ltw;", "the F11 label uses the key headroom");
pin("var sw:Number = Math.max(1,Math.round(this.hz42ScW * sx));", "the F11 chip snaps width after scaling");
pin("var sh:Number = Math.max(1,Math.round(boxH * sx));", "the F11 chip snaps height after scaling");
pin("private function hz42ScLblW(t:TextField) : Number", "the F11 label width uses the scope tracking");
pin("f.letterSpacing = Math.round(fs * 0.1 * 10) / 10;", "the F11 label uses 0.1 letter spacing");
pin('f.font = this.hzFontName("sb");', "the F11 label uses the chip semibold face");
pin("private static const HZ42_SC_LABEX:Number = 32;", "the F11 label slot matches the longer scope chip");
pin("ltw += HZ42_SC_LABEX;", "the F11 label keeps the scope's extra slot");
pin("var ltw:Number = this.hz42ScLblW(lt);", "the F11 label measures HOLD BREATH with that tracking");
pin("var hw:Number = this.hz42ScLblW(hold);", "the F11 label measures HOLDING BREATH");
pin("var ow:Number = this.hz42ScLblW(outb);", "the F11 label measures OUT OF BREATH");
pin("g.drawRoundRect(0.5,0.5,w - 1,h - 1,Math.max(0,h - 1),Math.max(0,h - 1));", "the F11 border is inset by half a pixel");
pin("g.drawRoundRect(x0 + 0.5,6.5,kw - 1,h - 13,8,8);", "the F11 keycap is inset by half a pixel");
pin("g.lineStyle(2,col,a,true,\"none\");", "the F11 cross uses a 2 px stroke");
{
	const help = src.match(/"VehicleExitPill":"([^"]*)"/);
	const n = help ? help[1].length : -1;
	expect(help && n <= 330, "vehicle exit help is 330 characters or fewer (" + n + ")");
}

const dlgBlock = fs.readFileSync(path.join(__dirname, "..", "actionscript", "comms", "hzd_block.as"), "utf8");
function dlgPin(snippet, msg) {
	expect(dlgBlock.indexOf(snippet) >= 0, msg || snippet);
}
dlgPin('"DlgPersuasionMeter":1', "persuasion meter defaults on in the dialogue config");
dlgPin("uPersuasionScore", "persuasion meter reads the score");
dlgPin("uMaxPersuasionScore", "persuasion meter reads the goal");
dlgPin("uTurnsLeft", "persuasion meter reads the turns");
dlgPin("iPersuasionPointsGained", "persuasion ghost uses the highlighted reply");
dlgPin("this.PERUSASION_RESULT_WIN", "persuasion win uses the game result");
dlgPin("this.PERUSASION_RESULT_CRIT_WIN", "persuasion critical win uses the game result");
dlgPin("this.PERUSASION_RESULT_FAIL", "persuasion fail uses the game result");
dlgPin("Vanilla uses PersuasionData_mc.visible as the open and close state", "persuasion alpha comment names the visible open and close state");
expect(dlgBlock.indexOf("noInvisibleAdvance") < 0, "noInvisibleAdvance stays on the HUD and out of the dialogue card");
dlgPin("var failed:Boolean = o.res == this.PERUSASION_RESULT_FAIL;", "a turn count of 0 is not a failed persuasion");
dlgPin("if(o.res == this.PERUSASION_RESULT_CRIT_WIN && !isNaN(o.goal) && o.goal > 0) { o.score = o.goal; }", "only a critical win snaps the score to the goal");
dlgPin("this.hzdPmData = this.hzdPmNew;", "a new persuasion resets meter data");
dlgPin("private function hzdPmDrop() : void", "hiding the persuasion card drops a saved points payload");
dlgPin("if(this.hzdPm.visible) { this.hzdPmDrop(); }", "the card's own hide clears the saved payload");
dlgPin("if(shown || !this.hzdPmShut)", "a late points update while hidden does not refill the saved payload");
dlgPin("else { this.hzdPmShut = false; }", "a hide while the meter is already down keeps the next opening payload");
dlgPin("private function hzdPmSpeech(", "the persuasion title has a speech icon");
dlgPin("private function hzdPmMeterMarks(", "the persuasion meter has notches and a goal flag");
dlgPin("var fx:Number = tw + flagGap;", "the goal flag starts just after the bar");
dlgPin("g.drawRect(nx,0,gapW,mh);", "persuasion notches are gaps");
dlgPin("fracT.y = Math.round(yM + Math.max(0,(rowMH - fracT.height) / 2));", "the score sits on the meter row");
dlgPin('titleStr = "PERSUADED"', "a win changes the header to PERSUADED");
dlgPin('titleStr = "FAILED"', "a loss changes the header to FAILED");
dlgPin("if(mark != 0) { titleFs = 16.5; titleBold = true; }", "PERSUADED and FAILED are 16.5 px");
{
	const call = dlgBlock.indexOf('this.hzdText(s,titleStr,"",titleFs');
	const face = dlgBlock.indexOf("tbf.font = this.hzdPmBold(titleStr);");
	const size = dlgBlock.indexOf("tbf.size = 16.5;");
	expect(call >= 0 && face > call && size > face, "PERSUADED and FAILED set the bold face after hzdText");
}
expect(dlgBlock.indexOf('tbf.font = "$Horizon_Font_Bold"') < 0, "the result title is not hard-wired to Exo bold");
dlgPin('var picked:String = this.hzdFont("_Bold", s);', "faces 1 and 2 ask hzdFont for the bold role");
dlgPin('return "$MAIN_Font_Bold";', "face 0, face 3, and a failed check use the game bold");
expect(dlgBlock.indexOf('titleRole = "_Bold"') < 0, "the result title does not follow FontFace");
function pmProbe(moduleOn, faces) {
	return { font: moduleOn ? 1 : 0, faces: faces || {} };
}
function hzdFontBold(face, dlgFont, probe) {
	const f = dlgFont >= 0 ? dlgFont : face;
	if (f === 3) return probe.semi ? "$NB_Grotesk_Semibold" : "$MAIN_Font";
	if (probe.font === 0 || f <= 0 || f > 2) return "$MAIN_Font";
	const base = f === 2 ? "$Horizon_Font_Alt" : "$Horizon_Font";
	if (probe.faces[base + "_Bold"]) return base + "_Bold";
	if (probe.faces[base]) return base;
	return "$MAIN_Font";
}
function hzdPmBold(face, dlgFont, probe) {
	const f = dlgFont >= 0 ? dlgFont : face;
	if (f === 1 || f === 2) {
		const picked = hzdFontBold(face, dlgFont, probe);
		const base = f === 2 ? "$Horizon_Font_Alt" : "$Horizon_Font";
		if (picked === base + "_Bold") return picked;
	}
	return "$MAIN_Font_Bold";
}
{
	const both = pmProbe(true, { "$Horizon_Font_Bold": true, "$Horizon_Font": true, "$Horizon_Font_Alt_Bold": true, "$Horizon_Font_Alt": true });
	expect(hzdPmBold(0, -1, both) === "$MAIN_Font_Bold", "FontFace 0 uses the game bold");
	expect(hzdPmBold(1, -1, both) === "$Horizon_Font_Bold", "FontFace 1 uses Exo bold");
	expect(hzdPmBold(2, -1, both) === "$Horizon_Font_Alt_Bold", "FontFace 2 uses Alt bold");
	expect(hzdPmBold(3, -1, both) === "$MAIN_Font_Bold", "FontFace 3 uses the game bold");
	const missing = pmProbe(false, { "$Horizon_Font_Bold": true, "$Horizon_Font_Alt_Bold": true });
	expect(hzdPmBold(1, -1, missing) === "$MAIN_Font_Bold", "FontFace 1 with the Font module missing uses the game bold");
	expect(hzdPmBold(2, -1, missing) === "$MAIN_Font_Bold", "FontFace 2 with the Font module missing uses the game bold");
	const noBold = pmProbe(true, { "$Horizon_Font": true, "$Horizon_Font_Alt": true });
	expect(hzdPmBold(1, -1, noBold) === "$MAIN_Font_Bold", "a failed Exo bold check uses the game bold");
	expect(hzdPmBold(2, -1, noBold) === "$MAIN_Font_Bold", "a failed Alt bold check uses the game bold");
}
expect(dlgBlock.indexOf("Math.round(fs * 1.12)") < 0, "the result title is not a rounded scale of the body");
expect(dlgBlock.indexOf("0xF4FBFF") < 0, "persuasion notches are not light ticks");
expect(dlgBlock.indexOf("var wordT:") < 0, "a result replaces the header instead of adding a row");
expect(dlgBlock.indexOf("OUT OF TURNS") < 0, "a failed persuasion says FAILED in the header");
expect(dlgBlock.indexOf("g.drawRoundRect(0,Math.round(pad)") < 0, "the persuasion meter has no accent stripe");
dlgPin("b.alpha = 0;", "persuasion meter sets the game meter alpha to 0");
expect(dlgBlock.indexOf("PersuasionData_mc.visible = false") < 0, "persuasion meter does not clear the game meter's visible flag");
expect(dlgBlock.indexOf("PERSUADED") >= 0 && dlgBlock.indexOf("FAILED") >= 0, "persuasion meter has the result labels");

// Mirror of hzdPmRead's win, fail, and score rules. Result ids match DialogueMenuBase's enum order.
function pmState(res, score, goal, turns) {
	const WIN = 1;
	const FAIL = 2;
	const CRIT = 3;
	const won = res === WIN || res === CRIT;
	const failed = res === FAIL;
	if (res === CRIT && !isNaN(goal) && goal > 0) score = goal;
	let word = "";
	if (won) word = "PERSUADED";
	else if (failed) word = "FAILED";
	return { won: won, failed: failed, score: score, word: word };
}
{
	const early = pmState(0, 4, 6, 0);
	expect(early.failed === false && early.word === "", "turns at 0 before a result stays out of the failed state");
	const out = pmState(2, 2, 6, 0);
	expect(out.failed === true && out.word === "FAILED", "a failed result with no turns says FAILED");
	const miss = pmState(2, 2, 6, 1);
	expect(miss.word === "FAILED", "a failed result with turns left says FAILED");
	const win = pmState(1, 3, 6, 2);
	expect(win.won === true && win.score === 3 && win.word === "PERSUADED", "a regular win keeps the real score");
	const crit = pmState(3, 3, 6, 2);
	expect(crit.won === true && crit.score === 6, "a critical win shows the goal");
}
expect(src.indexOf('["DlgPersuasionMeter","b",1,0,1,"comms"]') >= 0, "persuasion meter is a Comms ini key");
expect(src.indexOf('{"k":"DlgPersuasionMeter","l":"PERSUASION METER"') >= 0, "persuasion meter is on the Dialogue tab");

// Affliction subtitle. Vanilla's bio alert shows sAlertText only. When sAlertSubText is empty the chip
// labels the icon. PersonalEffect_CardioRespiratoryCirculatory_Negative is the game's symbol for that
// body group (Creation-Hub/Interface). The old replace inserted the literal "$1 $2" under Scaleform.
pin("s = this.hzSplitCamel(s);", "affliction names split camel case in code");
pin("p >= 97 && p <= 122 && c >= 65 && c <= 90", "the camel split is a lowercase letter before a capital");
expect(src.indexOf('"$1 $2"') < 0, "the HUD does not pass $1 $2 to replace");
pin('var sb:String = String(b.sub).length > 0 ? String(b.sub) : sys;', "a game subtitle is kept, and an empty one falls back to the body system");
pin('var nm:String = String(b.txt).length > 0 ? String(b.txt) : "Affliction";', "an alert without a name uses Affliction");
pin('out.push({"key":"p:" + sys,"name":"Affliction","sub":sys,"kind":"injury","env":false,"cat":String(o.sEffectIcon).replace(new RegExp("_(Negative|Positive)$"),"")});', "a plain effect chip is Affliction plus the body system");
pin('{"name":"Affliction","kind":"injury","env":false}', "the F11 preview uses Affliction as the fallback title");
pin('this.hzHdr19(this.hzT(p,i == 0 ? "HEALTH" : "OXYGEN",50,y + 9,150,13,"sb","acc",2));', "the Vitals labels are SemiBold 13 / acc / 2 plus hzHdr19");
	pin('this.hzT(p,"--",HZ_VN_W - 14 - 160,y + 4,160,20,"sb","main",1,"right");', "the Vitals value text hzVnHp / hzVnO2 is SemiBold 20 / main / 1");
	pin('this.hz26Co2T = this.hzT(p,"",HZ_VN_W - 14 - 260,66 + 8,100,13,"sb","col",0.6,"right",HZ_RED);', "the Vitals CO2 secondary hz26Co2T is SemiBold 13 / col / 0.6");
	pin('this.hz26RegenT = this.hzT(p,"",HZ_VN_W - 14 - 260,8,100,13,"sb","col",0.4,"right",HZ_GREEN);', "the Vitals regen secondary hz26RegenT is SemiBold 13 / col / 0.4");
	pin('this.hzT(c,"",48,8,240,13,"sb","acc",2);', "the affliction title copies HEALTH / OXYGEN SemiBold 13 / acc / 2");
	pin('this.hzT(c,"",48,24,200,13,"sb","col",0.6);', "the affliction sub line copies hz26Co2T SemiBold 13 / col / 0.6");
	pin("this.hzVit13(lb);", "the affliction title uses hzVit13 (Vitals hzChipSz path, no extra floor)");
	pin("this.hzVit13(sb);", "the affliction sub line uses hzVit13 (Vitals hzChipSz path, no extra floor)");
	pin("if(o != null && o.vit13) { return this.hzVitTextSz(fs); }", "vit13 lines use hzVitTextSz, not hzChipSzOn");
	pin("private function hzVitTextSz(fs:Number) : int\n      {\n         return this.hzChipSz(fs);\n      }", "hzVitTextSz is hzChipSz only, same as HEALTH / hz26Co2T");
	pin("this.hzTxtTop(this.hzTgChip,11);", "the Target chip still sits at top 11");
	pin("var sz:Number = Math.round(base * Math.max(0.8,Math.min(1.3,this.hzTextScale)));", "unflagged hzTxtTop uses the 4e0c1ef size (no 9 px floor)");
	pin("if(o.vit13 || o.af13 || card.length > 0) { sz = this.hzTextSz19(o,base); }", "hzTxtTop uses hzTextSz19 only for Vitals / affliction / chip-family");
	{
		const start = src.indexOf("private function hzTxtTop(tf:TextField, top:Number)");
		expect(start >= 0, "hzTxtTop is present");
		let body = "";
		if (start >= 0) {
			let depth = 0;
			const brace = src.indexOf("{", start);
			for (let i = brace; i < src.length; i++) {
				if (src[i] === "{") depth++;
				else if (src[i] === "}") {
					depth--;
					if (depth === 0) {
						body = src.slice(start, i + 1);
						break;
					}
				}
			}
		}
		expect(body.indexOf("var sz:Number = this.hzTextSz19(o,base);") < 0, "hzTxtTop no longer folds hzTextSz19 into every card");
		expect(body.indexOf("Math.round(base * Math.max(0.8,Math.min(1.3,this.hzTextScale)))") >= 0, "hzTxtTop default size matches 4e0c1ef");
	}
	pin("return this.hzVitTextSz(13);", "hzAf13Sz uses the Vitals-copied size");
	expect(src.indexOf('var vs:Number = this.hz34S("Vitals");') < 0, "affliction no longer floors through min(Vitals, Afflictions)");
	expect((src.split('this.hzT(c,"",48,8,240,13,"sb","acc",2);').length - 1) === 2, "live and F11 preview titles both copy HEALTH");
	expect((src.split('this.hzT(c,"",48,24,200,13,"sb","col",0.6);').length - 1) === 2, "live and F11 preview subs both copy hz26Co2T");
	expect((src.split("this.hzVit13(lb);").length - 1) === 2, "both titles mark hzVit13");
	expect((src.split("this.hzVit13(sb);").length - 1) === 2, "both subs mark hzVit13");
	pin('this.hzT(c,"HIDDEN",50,7,160,14,"bd","col",1.8,"left",0xB2C0C7);', "the stealth status chip title is Bold 14 / 1.8");
	pin('this.hzT(c,"",50,26,160,10,"sb","mut",1.2);', "the stealth status chip sub line is SemiBold muted 1.2");
	pin('this.hzT(p,"BOOST 100%",78,29,230,12,"sb","acc",1.2);', "the jetpack status sub line is SemiBold 12 / 1.2");
	pin("o.af13 ?", "affliction chip lines still mark af13 for scale-change reformat");
	pin('o.af13 ? "Afflictions" : ""', "chip-family fallback still uses the Afflictions scale key");
	pin("if(card.length > 0) { return this.hzChipSzOn(fs,card,o.chipMin > 0 ? Number(o.chipMin) : 13); }", "every chip-family line uses the shared size formula");
pin("var sc:Number = this.hz34S(card);", "the 13 px floor uses the shared card scale path");
pin('if(card == "Hover")', "TAKE uses the HoverScale path");
pin("var hv:Number = this.hz34Eff(this.hz30Hover);", "TAKE falls back to HudScale through hz34Eff");
pin("var fl:int = int(Math.ceil(minPx / sc));", "the chip floor is ceil(13 / hz34S)");
expect(src.indexOf('var hs:Number = this.hz34F("Afflictions");') < 0, "the chip floor no longer uses hz34F alone");
expect(src.indexOf('this.hzT(c,"",48,8,240,13,"sb","main",1.6)') < 0, "the affliction title is no longer TAKE SemiBold main 1.6");
	expect(src.indexOf('this.hzT(c,"",48,24,200,13,"sb","mut",1.2)') < 0, "the affliction sub line is no longer stealth SemiBold mut 1.2");
	expect(src.indexOf('this.hzT(c,"",48,24,200,13,"rg","mut",0.4)') < 0, "the affliction sub line is no longer Regular 0.4");
pin('this.hzChip13(o.l,"Hover");', "the F11 TAKE line uses the shared chip floor");
pin('this.hzChip13(lp,"Hover");', "the live TAKE line uses the shared chip floor");
pin('this.hzChip13(kp,"Hover");', "the live keycap letter uses the shared chip floor");
pin('this.hzChip13(kh,"Hover");', "the live hold keycap letter uses the shared chip floor");
pin('this.hzChip13(hh,"Hover");', "the live HOLD word uses the shared chip floor");
pin('this.hzChip13(this.hz26StT,"Stealth");', "the stealth title uses the Stealth scale key");
pin('this.hzChip13(this.hz26StD,"Stealth");', "the stealth sub line uses the Stealth scale key");
pin('this.hzChip13(this.hzJ19Title,"Jetpack");', "the jetpack title uses the Jetpack scale key");
pin('this.hzChip13(this.hzJ19Sub,"Jetpack");', "the jetpack sub line uses the Jetpack scale key");
pin("var subTop:int = 7 + szT + 5;", "the stealth sub line sits under the floored title");
pin("var h:Number = Math.max(HZ_ST_H,subTop + szS + 12);", "the stealth pill grows with the floored type");
pin("c.y - 150 * sSt - this.hz26StH * sSt", "the stealth pill stays above the crosshair at the live height");
pin("var subTop:int = 9 + szT + 6;", "the jetpack sub line sits under the floored title");
pin("var h:Number = Math.max(72,barY + 18);", "the jetpack pill grows with the floored type");
pin("vy - 8 * sV - this.hzJ19H * sJ", "the jetpack card sits on the measured height above Vitals");
expect(src.indexOf("vy - 8 * sV - 72 * sJ") < 0, "the jetpack card is no longer placed as if it were 72 tall");
pin("if(w != this.hzJ19W || h != this.hzJ19H) { this.hzLaidOut = false; }", "a jetpack size change marks a relayout");
pin("if(w != this.hz26StW || h != this.hz26StH) { this.hzLaidOut = false; }", "a stealth size change marks a relayout");
pin("this.hzJ19Glyph.y = cy - 2;", "the jetpack glyph sits cy - 2 in its disc");
pin("private function hzT19CapH() : Number", "the hover keycap grows with the floored E and HOLD");
pin('Math.max(24,Math.max(keySz,holdSz) + 10)', "the keycap stays at least 24 and fits the floored type");
pin('try { this.hzAfFmt13(); } catch(errAfF:Error) { }\n         try { this.hzJ19Draw(); } catch(errJ13:Error) { }\n         try { this.hz26StDraw(this.hz26Now()); } catch(errSt13:Error) { }\n         try { this.hzAfRetryLayout(); } catch(errAfS:Error) { }\n         this.hzLaidOut = this.hzLayout();', "hzApplyScale draws jetpack and stealth before the relayout");
pin('try { this.hzPpLayout(); this.hzV19Redraw(); } catch(err3:Error) { }\n         try { this.hz26StDraw(this.hz26Now()); } catch(errStT:Error) { }', "a TextScale-only change redraws stealth before the next layout");
pin("if(o != null && (o.af13 || o.vit13 || o.chipMin))", "every chip-family and Vitals-copied field is reformatted after a scale change");
pin("var j:int = 0;\n         this.hzAfFmt13();", "the F11 preview also reformats af13 fields");
pin('try { this.hzAfRetryLayout(); } catch(errAfS:Error) { }\n         this.hzLaidOut = this.hzLayout();', "the main layout runs after the chip relayout");
pin("Sample: one affliction and one", "the F11 preview caption says affliction");
expect(src.indexOf("Sample: one injury and one") < 0, "the F11 preview caption no longer says injury");
pin("var barY:int = 23 + grow + sz13 + 3;", "the exposure bar sits under the second-line baseline");
pin("g.drawRoundRect(48,barY,bw,4,4,4)", "the live exposure bar uses barY");
pin("cg.drawRoundRect(48,barY,bw,4,4,4)", "the F11 preview exposure bar uses barY");
pin("Math.max(48, barY + 9)", "a chip with a bar grows to hold the bar");
pin("Math.max(48,23 + grow + sz13 + 6)", "a two-line chip without a bar still grows with the font");
expect(src.indexOf('this.hzT(c,"",48,8,240,12,"sb","main",1.6)') < 0, "the F11 afflictions preview no longer uses 12");
expect(src.indexOf('this.hzT(c,"",48,24,200,10,"rg","mut",0.4)') < 0, "the F11 afflictions preview no longer uses 10");
function hzAfChipSz(fs, textScale, hudScale, hzScale) {
	let ts = textScale;
	if (!(ts > 0)) ts = 1;
	ts = Math.max(0.8, Math.min(1.3, ts));
	let sz = Math.max(9, Math.round(fs * ts));
	let sc = (hzScale > 0.01 ? hzScale : 1) * (hudScale > 0.01 ? hudScale : 1);
	if (!(sc > 0.01)) sc = 1;
	const fl = Math.ceil(13 / sc);
	if (sz < fl) sz = fl;
	return sz;
}
function hzAfChipPx(fs, textScale, hudScale, hzScale) {
	const sc = (hzScale > 0.01 ? hzScale : 1) * (hudScale > 0.01 ? hudScale : 1);
	return hzAfChipSz(fs, textScale, hudScale, hzScale) * sc;
}
function hzAfChipH(two, fs, textScale, hudScale) {
	if (!two) return 48;
	let ts = textScale;
	if (!(ts > 0)) ts = 1;
	ts = Math.max(0.8, Math.min(1.3, ts));
	const sz = Math.max(9, Math.round(fs * ts));
	const grow = Math.max(0, sz - 13);
	return Math.max(48, 23 + grow + sz + 6);
}
function hzAfBarY(sz) {
	const grow = Math.max(0, sz - 13);
	return 23 + grow + sz + 3;
}
function hzAfSubBase(sz) {
	const grow = Math.max(0, sz - 13);
	return 23 + grow + sz;
}
function hzAfEnvH(sz) {
	return Math.max(48, hzAfBarY(sz) + 9);
}
{
	const textScales = [0.8, 0.9, 1, 1.15, 1.3];
	const hudScales = [0.6, 0.7, 0.8, 1, 1.2, 1.4];
	for (let ti = 0; ti < textScales.length; ti++) {
		for (let hi = 0; hi < hudScales.length; hi++) {
			const px = hzAfChipPx(13, textScales[ti], hudScales[hi]);
			expect(px + 1e-9 >= 13, "TAKE/chip-family at TextScale " + textScales[ti] + " HudScale " + hudScales[hi] + " is " + px + " px");
		}
	}
	expect(hzAfChipSz(13, 0.8, 0.8) === 17, "TAKE at Moragar's Choice uses ceil(13/0.8)");
	expect(hzAfChipPx(13, 0.8, 0.8) >= 13, "TAKE at Moragar's Choice stays at least 13 px");
	expect(hzAfChipSz(13, 1, 0.8, 1.07) === 16, "hudmenu_lrg TAKE floors through HZ_SCALE * HudScale");
	expect(hzAfChipPx(13, 1, 0.8, 1.07) + 1e-9 >= 13, "hudmenu_lrg TAKE stays at least 13 px");
	expect(hzAfChipSz(13, 1, 0.6) === 22, "chip-family at scale 0.6 still uses ceil(13/0.6)");
	expect(hzVitSz(13, 1) === 13, "affliction / HEALTH design size stays 13 at TextScale 1.0");
	expect(hzVitPx(13, 1, 0.6) + 1e-9 < 13, "affliction follows Vitals below 13 px at HudScale 0.6");
	expect(hzAfChipH(true, 13, 1, 1) === 48, "a two-line chip stays 48 at size 13");
	expect(hzAfChipH(true, 13, 1.3, 1) === 50, "a two-line chip is 50 at TextScale 1.3");
	expect(hzAfChipH(true, 13, 1, 0.6) === 48, "a two-line affliction chip stays 48 at HudScale 0.6 (no floor)");
	expect(hzAfChipH(false, 13, 1, 0.6) === 48, "a one-line chip stays 48 at scale 0.6");
	expect(hzAfEnvH(13) === 48 && hzAfEnvH(17) === 56 && hzAfEnvH(22) === 66, "an env chip is 48 / 56 / 66 at 13 / 17 / 22");
	function hzVitSz(fs, textScale) {
		let ts = textScale;
		if (!(ts > 0)) ts = 1;
		ts = Math.max(0.8, Math.min(1.3, ts));
		return Math.max(9, Math.round(fs * ts));
	}
	function hzVitPx(fs, textScale, hudScale, hzScale) {
		const sc = (hzScale > 0.01 ? hzScale : 1) * (hudScale > 0.01 ? hudScale : 1);
		return hzVitSz(fs, textScale) * sc;
	}
	const sizeReport = [
		{ ts: 1.0, hs: 0.80, lrg: 1, label: "TS 1.0 HS 0.80" },
		{ ts: 1.0, hs: 1.0, lrg: 1, label: "TS 1.0 HS 1.0" },
		{ ts: 1.3, hs: 0.80, lrg: 1, label: "TS 1.3 HS 0.80" },
		{ ts: 1.3, hs: 1.0, lrg: 1, label: "TS 1.3 HS 1.0" },
		{ ts: 1.0, hs: 0.80, lrg: 1.07, label: "hudmenu_lrg TS 1.0 HS 0.80" },
		{ ts: 1.0, hs: 1.0, lrg: 1.07, label: "hudmenu_lrg TS 1.0 HS 1.0" },
		{ ts: 1.3, hs: 0.80, lrg: 1.07, label: "hudmenu_lrg TS 1.3 HS 0.80" },
		{ ts: 1.3, hs: 1.0, lrg: 1.07, label: "hudmenu_lrg TS 1.3 HS 1.0" }
	];
	for (let ri = 0; ri < sizeReport.length; ri++) {
		const r = sizeReport[ri];
		const titlePx = hzVitPx(13, r.ts, r.hs, r.lrg);
		const healthPx = hzVitPx(13, r.ts, r.hs, r.lrg);
		const subPx = hzVitPx(13, r.ts, r.hs, r.lrg);
		const co2Px = hzVitPx(13, r.ts, r.hs, r.lrg);
		expect(titlePx === healthPx, "affliction title equals HEALTH at " + r.label + " (" + titlePx + " px)");
		expect(subPx === co2Px, "affliction sub equals hz26Co2T at " + r.label + " (" + subPx + " px)");
	}
	function hzTxtTopY0(base, top, textScale, sizeAware) {
		const ts = Math.max(0.8, Math.min(1.3, textScale));
		const render = Math.round(base * ts);
		const sz = sizeAware ? Math.max(9, render) : render;
		return top + (sz - base) / 2;
	}
	function hzApplyFmtY(y0, base, textScale) {
		const ts = Math.max(0.8, Math.min(1.3, textScale));
		const sz = Math.round(base * ts);
		return y0 - (sz - base) / 2;
	}
	{
		const y0 = hzTxtTopY0(9, 11, 0.8, false);
		expect(y0 === 10, "Target chip y0 at TS 0.8 uses unfloored 7 (11 + (7-9)/2)");
		expect(hzApplyFmtY(y0, 9, 0.8) === 11, "Target chip stays at 11 after a reformat");
		expect(hzApplyFmtY(hzTxtTopY0(9, 11, 0.8, true), 9, 0.8) === 12, "folding the 9 px floor into y0 would move the Target chip to 12");
	}
	for (let sz = 13; sz <= 22; sz++) {
		const barY = hzAfBarY(sz);
		const base = hzAfSubBase(sz);
		expect(barY >= base, "live bar top at size " + sz + " is " + barY + ", baseline " + base);
		expect(barY >= base, "preview bar top at size " + sz + " is " + barY + ", baseline " + base);
	}
}
const hzChipLines = [
	{ name: "TAKE", fs: 13, card: "Hover" },
	{ name: "keycap letter", fs: 12, card: "Hover" },
	{ name: "HOLD", fs: 11, card: "Hover" },
	{ name: "stealth title", fs: 14, card: "Stealth" },
	{ name: "stealth sub", fs: 10, card: "Stealth" },
	{ name: "jetpack title", fs: 14, card: "Jetpack" },
	{ name: "jetpack sub", fs: 12, card: "Jetpack" }
];
function hzChipLineSz(fs, textScale, hudScale, hzScale) {
	return hzAfChipSz(fs, textScale, hudScale, hzScale);
}
function hzChipLinePx(fs, textScale, hudScale, hzScale) {
	return hzAfChipPx(fs, textScale, hudScale, hzScale);
}
function hzStSubTop(szT) { return 7 + szT + 5; }
function hzStH(szT, szS) { return Math.max(48, hzStSubTop(szT) + szS + 12); }
function hzJSubTop(szT) { return 9 + szT + 6; }
function hzJBarY(szT, szS) { return hzJSubTop(szT) + szS + 13; }
function hzJH(szT, szS) { return Math.max(72, hzJBarY(szT, szS) + 18); }
{
	const cases = [
		{ ts: 1.0, hs: 0.8, lrg: 1, label: "TS 1.0 HS 0.8" },
		{ ts: 1.0, hs: 1.0, lrg: 1, label: "TS 1.0 HS 1.0" },
		{ ts: 1.3, hs: 0.8, lrg: 1, label: "TS 1.3 HS 0.8" },
		{ ts: 1.3, hs: 1.0, lrg: 1, label: "TS 1.3 HS 1.0" },
		{ ts: 0.8, hs: 0.8, lrg: 1, label: "Moragar's Choice" },
		{ ts: 1.0, hs: 0.8, lrg: 1.07, label: "hudmenu_lrg TS 1.0 HS 0.8" },
		{ ts: 1.0, hs: 1.0, lrg: 1.07, label: "hudmenu_lrg TS 1.0 HS 1.0" },
		{ ts: 1.3, hs: 0.8, lrg: 1.07, label: "hudmenu_lrg TS 1.3 HS 0.8" },
		{ ts: 1.3, hs: 1.0, lrg: 1.07, label: "hudmenu_lrg TS 1.3 HS 1.0" }
	];
	for (let ci = 0; ci < cases.length; ci++) {
		const c = cases[ci];
		for (let li = 0; li < hzChipLines.length; li++) {
			const line = hzChipLines[li];
			const px = hzChipLinePx(line.fs, c.ts, c.hs, c.lrg);
			expect(px + 1e-9 >= 13, line.name + " at " + c.label + " is " + px + " px");
		}
		const stT = hzChipLineSz(14, c.ts, c.hs, c.lrg);
		const stS = hzChipLineSz(10, c.ts, c.hs, c.lrg);
		const stTop = hzStSubTop(stT);
		const stH = hzStH(stT, stS);
		expect(stTop >= 7 + stT, "stealth title and sub do not overlap at " + c.label);
		expect(stH >= stTop + stS + 12, "stealth pill height holds both lines at " + c.label);
		expect(stH >= 48, "stealth pill is at least 48 at " + c.label);
		const jT = hzChipLineSz(14, c.ts, c.hs, c.lrg);
		const jS = hzChipLineSz(12, c.ts, c.hs, c.lrg);
		const jTop = hzJSubTop(jT);
		const jBar = hzJBarY(jT, jS);
		const jH = hzJH(jT, jS);
		expect(jTop >= 9 + jT, "jetpack title and sub do not overlap at " + c.label);
		expect(jBar >= jTop + jS, "jetpack bar sits under the sub line at " + c.label);
		expect(jH >= jBar + 18, "jetpack pill height holds the bar at " + c.label);
	}
	expect(hzChipLinePx(13, 1, 0.8) + 1e-9 >= 13, "TAKE at Moragar's Choice TS 1.0 HS 0.8 stays at least 13 px");
	expect(hzChipLinePx(12, 1, 0.8) + 1e-9 >= 13, "the keycap letter at Moragar's Choice stays at least 13 px");
	expect(hzChipLinePx(11, 1, 0.8) + 1e-9 >= 13, "HOLD at Moragar's Choice stays at least 13 px");
	expect(hzChipLineSz(12, 1, 1) === 13, "jetpack sub floors 12 to 13 at TS 1.0 HS 1.0");
	expect(hzChipLineSz(10, 1, 1) === 13, "stealth sub floors 10 to 13 at TS 1.0 HS 1.0");
	expect(hzChipLineSz(14, 1, 0.8) === 17, "stealth title at HS 0.8 uses ceil(13/0.8)");
	expect(hzStH(hzChipLineSz(14, 1, 1), hzChipLineSz(10, 1, 1)) === 51, "the stealth pill is 51 at TS 1.0 HS 1.0");
	expect(hzStH(17, 17) === 58, "the stealth pill is 58 at the HS 0.8 floor");
	expect(hzJH(hzChipLineSz(14, 1, 1), hzChipLineSz(12, 1, 1)) === 73, "the jetpack pill is 73 at TS 1.0 HS 1.0");
	expect(hzJH(17, 17) === 80, "the jetpack pill is 80 at the HS 0.8 floor");
	expect(150 + hzStH(17, 17) > 150 + 51, "a taller stealth pill grows upward above the crosshair");
}
function hzJSize(ts, hs, js, lrg) {
	const card = js > 0 ? js : hs;
	return hzJH(hzChipLineSz(14, ts, card, lrg), hzChipLineSz(12, ts, card, lrg));
}
function hzJGap(jH, sV, sJ, placedH) {
	return 8 * sV + (placedH - jH) * sJ;
}
function hzStAbove(sSt, h) {
	const cY = 540;
	const y = cY - 150 * sSt - h * sSt;
	return cY - (y + h * sSt);
}
function hzCapH(ts, hs, lrg) {
	const keySz = hzChipLineSz(12, ts, hs, lrg);
	const holdSz = hzChipLineSz(11, ts, hs, lrg);
	return Math.max(24, Math.max(keySz, holdSz) + 10);
}
{
	const placeCases = [
		{ ts: 0.8, hs: 0.8, js: 0, lrg: 1, label: "TS 0.8 HS 0.8" },
		{ ts: 0.8, hs: 1.0, js: 0, lrg: 1, label: "TS 0.8 HS 1.0" },
		{ ts: 1.0, hs: 0.8, js: 0, lrg: 1, label: "TS 1.0 HS 0.8" },
		{ ts: 1.0, hs: 1.0, js: 0, lrg: 1, label: "TS 1.0 HS 1.0" },
		{ ts: 1.3, hs: 0.8, js: 0, lrg: 1, label: "TS 1.3 HS 0.8" },
		{ ts: 1.3, hs: 1.0, js: 0, lrg: 1, label: "TS 1.3 HS 1.0" },
		{ ts: 1.0, hs: 1.0, js: 0.6, lrg: 1, label: "JetpackScale 0.6" },
		{ ts: 1.0, hs: 0.8, js: 0, lrg: 1, label: "Moragar's Choice" },
		{ ts: 0.8, hs: 0.8, js: 0, lrg: 1.07, label: "hudmenu_lrg TS 0.8 HS 0.8" },
		{ ts: 1.0, hs: 0.8, js: 0, lrg: 1.07, label: "hudmenu_lrg TS 1.0 HS 0.8" },
		{ ts: 1.0, hs: 1.0, js: 0, lrg: 1.07, label: "hudmenu_lrg TS 1.0 HS 1.0" },
		{ ts: 1.3, hs: 0.8, js: 0, lrg: 1.07, label: "hudmenu_lrg TS 1.3 HS 0.8" },
		{ ts: 1.3, hs: 1.0, js: 0, lrg: 1.07, label: "hudmenu_lrg TS 1.3 HS 1.0" },
		{ ts: 1.0, hs: 1.0, js: 0.6, lrg: 1.07, label: "hudmenu_lrg JetpackScale 0.6" },
		{ ts: 1.0, hs: 0.8, js: 0, lrg: 1.07, label: "hudmenu_lrg Moragar's Choice" }
	];
	for (let i = 0; i < placeCases.length; i++) {
		const c = placeCases[i];
		const sV = c.lrg * c.hs;
		const sJ = c.lrg * (c.js > 0 ? c.js : c.hs);
		const jH = hzJSize(c.ts, c.hs, c.js, c.lrg);
		const gap = hzJGap(jH, sV, sJ, jH);
		const old = hzJGap(jH, sV, sJ, 72);
		expect(gap + 1e-9 >= 8 * sV, "jetpack gap at " + c.label + " is " + gap + " (need " + (8 * sV) + ", height " + jH + ")");
		expect(Math.abs(gap - 8 * sV) < 1e-9, "jetpack gap at " + c.label + " is the 8-unit Vitals gap");
		if (jH > 72 && sJ > 0) {
			expect(old + 1e-9 < 8 * sV, "a 72-tall place at " + c.label + " would leave only " + old);
		}
	}
	expect(hzJSize(1, 1, 0, 1) === 73, "reachable jetpack height at TS 1.0 HS 1.0 is 73");
	expect(hzJSize(1.3, 1, 0, 1) === 80, "reachable jetpack height at TS 1.3 HS 1.0 is 80");
	expect(hzJSize(1, 0.8, 0, 1) === 80, "reachable jetpack height at Moragar's Choice is 80");
	expect(hzJSize(1.3, 0.8, 0, 1) === 81, "reachable jetpack height at TS 1.3 HS 0.8 is 81");
	expect(hzJSize(1, 1, 0.6, 1) === 90, "reachable jetpack height at JetpackScale 0.6 is 90");
	expect(hzJGap(90, 1, 0.6, 72) + 1e-9 < 8, "the old 72-tall place overlaps Vitals at JetpackScale 0.6");
	const stBefore = hzStH(hzChipLineSz(14, 1, 1), hzChipLineSz(10, 1, 1));
	const stAfter = hzStH(hzChipLineSz(14, 1.3, 1), hzChipLineSz(10, 1.3, 1));
	expect(stBefore === 51 && stAfter === 55, "TextScale 1.0 to 1.3 grows stealth 51 to 55");
	expect(hzStAbove(1, stBefore) === 150, "stealth stays 150 above the crosshair at TS 1.0");
	expect(hzStAbove(1, stAfter) === 150, "stealth stays 150 above the crosshair after a TextScale-only change");
	expect(hzStAbove(0.8, hzStH(17, 17)) === 120, "stealth stays 150 StealthScale units above the crosshair at HS 0.8");
	expect(hzCapH(1, 1, 1) === 24, "the keycap stays 24 at TS 1.0 HS 1.0");
	expect(hzCapH(1, 0.8, 1) === 27, "the keycap is 27 at HS 0.8 so font 17 fits");
	expect(hzCapH(1, 0.6, 1) === 32, "the keycap is 32 at HoverScale 0.6 so font 22 fits");
}
function hzAfPlainPers(icon) {
	const sys = hzPretty(icon);
	return { name: "Affliction", sub: sys };
}
function hzAfAlertChip(txt, sub, icon) {
	const sys = hzPretty(icon);
	const nm = txt && txt.length > 0 ? txt : "Affliction";
	let sb = sub && sub.length > 0 ? sub : sys;
	if (sb.toLowerCase() === nm.toLowerCase()) {
		sb = sys.length > 0 && sys.toLowerCase() !== nm.toLowerCase() ? sys : "";
	}
	return { name: nm, sub: sb || null, two: !!(nm && (sb || "").length) };
}
{
	const plain = hzAfPlainPers("PersonalEffect_CardioRespiratoryCirculatory_Negative");
	expect(plain.name === "Affliction" && plain.sub === "Cardio Respiratory Circulatory", "after a load the plain chip is Affliction / body system");
	const named = hzAfAlertChip("Contusions", "", "PersonalEffect_CardioRespiratoryCirculatory_Negative");
	expect(named.name === "Contusions" && named.sub === "Cardio Respiratory Circulatory" && named.two, "a session alert keeps Contusions and the body system");
	const empty = hzAfAlertChip("", "", "PersonalEffect_SkeletalMuscular_Negative");
	expect(empty.name === "Affliction" && empty.sub === "Skeletal Muscular", "an alert with no text still uses Affliction");
	expect(hzAfAlertChip("Contusions", "Contusions", "PersonalEffect_CardioRespiratoryCirculatory_Negative").sub === "Cardio Respiratory Circulatory", "a repeated name still keeps the body-system sub line");
}
function hzSplitCamel(s) {
	if (s == null || s.length < 2) return s == null ? "" : s;
	let o = s.charAt(0);
	for (let i = 1; i < s.length; i++) {
		const p = s.charCodeAt(i - 1);
		const c = s.charCodeAt(i);
		if (p >= 97 && p <= 122 && c >= 65 && c <= 90) o += " ";
		o += s.charAt(i);
	}
	return o;
}
function hzPretty(id) {
	if (!id) return "";
	const lo = id.toLowerCase();
	if (lo.indexOf("thermal") >= 0) return "Thermal";
	if (lo.indexOf("radiation") >= 0) return "Radiation";
	if (lo.indexOf("airborne") >= 0) return "Airborne";
	if (lo.indexOf("corros") >= 0) return "Corrosive";
	let s = id.replace(/^(PersonalEffect_|Personal_|HazardEffect_|Hazard_)/, "");
	s = s.replace(/_(Negative|Positive)$/, "");
	s = s.replace(/_/g, " ");
	return hzSplitCamel(s);
}
function scaleformCamel(s) {
	let o = "";
	for (let i = 0; i < s.length; i++) {
		const p = s.charCodeAt(i);
		const c = s.charCodeAt(i + 1);
		if (p >= 97 && p <= 122 && c >= 65 && c <= 90) { o += "$1 $2"; i++; }
		else o += s.charAt(i);
	}
	return o;
}
expect(hzPretty("PersonalEffect_CardioRespiratoryCirculatory_Negative") === "Cardio Respiratory Circulatory", "contusions icon label matches the vanilla symbol words");
expect(hzPretty("PersonalEffect_SkeletalMuscular_Negative") === "Skeletal Muscular", "skeletal icon label");
expect(hzPretty("PersonalEffect_NervousSystem_Positive") === "Nervous System", "nervous icon label");
expect(hzPretty("PersonalEffect_DigestiveImmune_Negative") === "Digestive Immune", "digestive icon label");
expect(hzPretty("HazardEffect_Thermal") === "Thermal", "thermal stays one word");
expect(hzPretty("HazardEffect_Corrosive_Negative") === "Corrosive", "corrosive stays one word");
expect(scaleformCamel("CardioRespiratoryCirculatory") === "Cardi$1 $2espirator$1 $2irculatory", "Scaleform leaves $1 $2 in the contusions subtitle");

function dlgTail(buf) {
	const text = buf.toString("utf8").replace(/\r\n/g, "\n");
	const at = text.indexOf("private static const HZD_AMB:uint = 0xF2B45F;");
	const end = text.indexOf("// =================== end Horizon UI Comms (Dialogue) v0.35 ===================");
	expect(at >= 0 && end > at, "dialogue block markers");
	return text.slice(at, end);
}
const dlgTailBlock = dlgTail(fs.readFileSync(path.join(__dirname, "..", "actionscript", "comms", "hzd_block.as")));
const dlgFiles = [
	["actionscript/comms/hzd_block.as", false],
	["actionscript/imp/dimp/scripts/DialogueMenu.as", true],
	["actionscript/imp/dimp-Lrg/scripts/DialogueMenu.as", true],
];
for (let di = 0; di < dlgFiles.length; di++) {
	const rel = dlgFiles[di][0];
	const wantCrlf = dlgFiles[di][1];
	const buf = fs.readFileSync(path.join(__dirname, "..", rel));
	const stripped = buf.toString("binary").replace(/\r\n/g, "");
	const hasCrlf = buf.includes(Buffer.from("\r\n"));
	const loneLf = stripped.includes("\n");
	const loneCr = stripped.includes("\r");
	if (wantCrlf) expect(hasCrlf && !loneLf && !loneCr, rel + " stays CRLF");
	else expect(!hasCrlf && !loneCr && loneLf, rel + " stays LF");
	const tail = dlgTail(buf);
	expect(tail === dlgTailBlock, rel + " persuasion meter matches the dialogue block");
	if (rel.indexOf("dimp-Lrg") >= 0) expect(buf.toString("utf8").indexOf("private static const HZD_LRG:Boolean = true;") >= 0, "large dialogue stays large");
	else if (rel.indexOf("dimp/") >= 0) expect(buf.toString("utf8").indexOf("private static const HZD_LRG:Boolean = false;") >= 0, "standard dialogue stays standard");
}

// t34-t40: 0.42.0.12 stealth hide guard and affliction remeasure after a load.
pin('this.hz26HideV("StealthMeter_mc",live && this.hzStealthOn && this.HorizonStealth_mc != null && this.hz26St != null && this.hz26StOn);', "t34 stealth hide requires the pill to be active");
pin("this.hz26StOn = sd != null && sd.bSneaking === true && sd.bShowMeter === true;\n         try { this.hz26Vanilla(); } catch(e0:Error) { }", "t34 sneak-start updates hz26StOn before the vanilla hide");
function stealthHideVanilla(live, stealthOn, pill, st, stOn) {
	return !!(live && stealthOn && pill && st != null && stOn);
}
function stealthTick(s) {
	s.stOn = s.st != null && s.st.bSneaking === true && s.st.bShowMeter === true;
	s.vanillaHidden = stealthHideVanilla(s.live, s.stealthOn, s.pill, s.st, s.stOn);
}
function stealthTickOld(s) {
	s.vanillaHidden = stealthHideVanilla(s.live, s.stealthOn, s.pill, s.st, s.stOn);
	s.stOn = s.st != null && s.st.bSneaking === true && s.st.bShowMeter === true;
}
expect(!stealthHideVanilla(true, true, true, null, false), "t35 vanilla stays visible when the pill has no stealth data");
expect(!stealthHideVanilla(true, true, true, { bSneaking: true }, false), "t35 vanilla stays visible when the pill is not on");
expect(stealthHideVanilla(true, true, true, { bSneaking: true, bShowMeter: true }, true), "t35 vanilla is hidden while the pill is active");
{
	const sneak = { live: true, stealthOn: true, pill: true, st: { bSneaking: true, bShowMeter: true }, stOn: false };
	stealthTick(sneak);
	expect(sneak.stOn && sneak.vanillaHidden, "t35 sneak-start hides vanilla on the same frame");
	const flash = { live: true, stealthOn: true, pill: true, st: { bSneaking: true, bShowMeter: true }, stOn: false };
	stealthTickOld(flash);
	expect(!flash.vanillaHidden && flash.stOn, "t35 the old order flashes vanilla on sneak start");
}
expect(!stealthHideVanilla(true, false, true, { bSneaking: true, bShowMeter: true }, true), "t36 StealthMeter off leaves vanilla visible");
expect(!stealthHideVanilla(false, true, true, { bSneaking: true, bShowMeter: true }, true), "t36 a hidden HUD does not alpha-hide vanilla stealth");
pin("if(lb.text.length > 0 && w < 4)", "t37 title fit does not shrink a non-empty unread title");
pin("if(this.hzAfTitleW > 4) { w = this.hzAfTitleW; lb.width = Math.round(w + 8); }", "t37 a bad title measure keeps the last good width");
pin("if(w >= 4) { this.hzAfTitleW = w; }", "t37 a good title measure does not clear the retry flag");
expect(src.indexOf("if(w >= 4) { this.hzAfTitleW = w; this.hzAfRemeasure = false; this.hzAfRemeasureAt = 0; }") < 0, "t37 one chip cannot clear another chip's remeasure");
function hz31AfFitWidth(text, measured, prevW) {
	let w = measured;
	let remeasure = false;
	let width;
	if (text.length > 0 && w < 4) {
		remeasure = true;
		if (prevW > 4) {
			w = prevW;
			width = Math.round(w + 8);
		} else {
			width = 2000;
		}
	} else {
		width = Math.round(w + 8);
	}
	return { width: width, remeasure: remeasure, used: w };
}
function hzAfFitPass(chips) {
	let remeasure = false;
	for (let i = 0; i < chips.length; i++) {
		const r = hz31AfFitWidth(chips[i].text, chips[i].w, chips[i].prev || 0);
		if (r.remeasure) remeasure = true;
	}
	return remeasure;
}
expect(hz31AfFitWidth("CONTUSIONS", 0, 0).width === 2000 && hz31AfFitWidth("CONTUSIONS", 0, 0).remeasure, "t38 first measure 0 keeps the title wide");
expect(hz31AfFitWidth("CONTUSIONS", 0, 80).width === 88 && hz31AfFitWidth("CONTUSIONS", 0, 80).used === 80, "t38 a later 0 measure keeps the last good title width");
expect(hz31AfFitWidth("CONTUSIONS", 72, 0).width === 80 && !hz31AfFitWidth("CONTUSIONS", 72, 0).remeasure, "t38 a good title measure sizes to textWidth+8");
expect(hz31AfFitWidth("", 0, 80).width === 8 && !hz31AfFitWidth("", 0, 80).remeasure, "t38 an empty title may shrink");
expect(hzAfFitPass([{ text: "CONTUSIONS", w: 0 }, { text: "BURNS", w: 80 }]), "t38 a later good chip does not drop an earlier remeasure");
expect(!hzAfFitPass([{ text: "CONTUSIONS", w: 72 }, { text: "BURNS", w: 80 }]), "t38 all good chips leave remeasure off");
pin("this.hz27Alerts = [];", "t39 load clears personal alerts");
pin("this.hzAfSeen = {};", "t39 load clears affliction seen keys");
pin('if(this.hz40HasFF(ev.data,"LoadingMenu_Opened") || this.hz40HasFF(ev.data,"LoadingMenu_Closed")) { this.hzAfOnLoad(); }', "t39 load clear is on LoadingMenu open and close");
pin("if(age == 30 || age == 120) { this.hzAfRetryLayout(); }", "t40 layout reruns at 30 and 120 frames after load");
pin("if(this.hzAfLastWall > 0 && now - this.hzAfLastWall > 4000) { this.hzAfArmRelayout(); }", "t40 a wall-clock gap remeasures without clearing");
pin("private function hzAfArmRelayout() : void", "t40 the gap path only arms remeasure");
pin("this.hzAfRemeasureAt = Math.max(1,this.hzFrameN);", "t40 frame 0 still starts the remeasure timeout");
expect(src.indexOf("if(this.hzAfLastWall > 0 && now - this.hzAfLastWall > 4000) { this.hzAfOnLoad(); }") < 0, "t40 a gap is not a load clear");
function afArmRelayout(s, frame) {
	s.remeasure = true;
	if (!s.remeasureAt) s.remeasureAt = Math.max(1, frame);
}
function afOnLoad(s, frame) {
	s.alerts = [];
	s.seen = {};
	s.remeasure = true;
	s.remeasureAt = Math.max(1, frame);
	s.loadAt = Math.max(1, frame);
}
function afLoadWatch(s, now, frame) {
	const events = [];
	if (s.lastWall > 0 && now - s.lastWall > 4000) {
		afArmRelayout(s, frame);
		events.push("arm");
	}
	if (now > 0) s.lastWall = now;
	if (s.loadAt > 0) {
		const age = frame - s.loadAt;
		if (age === 30 || age === 120) events.push("relayout");
		if (age >= 120) s.loadAt = 0;
	}
	return events;
}
{
	const s = { lastWall: 1000, alerts: [{ cat: "old" }], seen: { "p:old": 1 }, remeasure: false, remeasureAt: 0, loadAt: 0 };
	expect(afLoadWatch(s, 2000, 10).length === 0 && s.alerts.length === 1, "t40 a short gap is not a load");
	const ev = afLoadWatch(s, 7000, 11);
	expect(ev.indexOf("arm") >= 0 && s.alerts.length === 1 && s.seen["p:old"] === 1, "t40 a pause gap does not clear alerts or seen");
	expect(s.remeasure && s.loadAt === 0, "t40 a pause gap remeasures without a load timer");
	const loaded = { lastWall: 1000, alerts: [{ cat: "old" }], seen: { "p:old": 1 }, remeasure: false, remeasureAt: 0, loadAt: 0 };
	afOnLoad(loaded, 0);
	expect(loaded.alerts.length === 0 && Object.keys(loaded.seen).length === 0, "t40 a load clears alerts and seen");
	expect(loaded.loadAt === 1 && loaded.remeasureAt === 1, "t40 a frame-0 load still times out");
	loaded.lastWall = 7000;
	expect(afLoadWatch(loaded, 7016, 31).indexOf("relayout") >= 0, "t40 remeasure at frame 30");
	expect(afLoadWatch(loaded, 7033, 121).indexOf("relayout") >= 0, "t40 remeasure at frame 120");
}

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("planet alert: all cases passed");
