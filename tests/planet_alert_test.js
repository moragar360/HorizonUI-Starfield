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

pin('private static const HZ_BUILD:String = "0.42.0.5";', "HUD build id is 0.42.0.5");
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

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("planet alert: all cases passed");
