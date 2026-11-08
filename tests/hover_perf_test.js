// Pins for 0.43.1.0 hover-card performance diagnostics and rebuild gates.
// Run: node tests/hover_perf_test.js
"use strict";

const fs = require("fs");
const path = require("path");

function readText(p) {
	return fs.readFileSync(p, "utf8").replace(/\r\n/g, "\n").replace(/\r/g, "\n");
}

const root = path.join(__dirname, "..");
const as = readText(path.join(root, "actionscript", "horizon_block.as"));
const scan = readText(path.join(root, "actionscript", "scanner", "hzs_block.as"));
const ini = readText(path.join(root, "Interface", "HorizonUI", "HorizonUI.default.ini"));
const perfH = readText(path.join(root, "src", "hz_perf.h"));
const main = readText(path.join(root, "src", "main.cpp"));

let failed = 0;
function expect(cond, msg) {
	if (cond) {
		console.log("ok  " + msg);
		return;
	}
	failed++;
	console.error("FAIL " + msg);
}

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

expect(ini.indexOf("PerfDiag=0") >= 0, "PerfDiag off by default");
expect(ini.indexOf("Debug=0") >= 0, "Debug overlay still off");
expect(as.indexOf("hzPerfDiag:Boolean = false") >= 0, "AS diag off by default");
expect(as.indexOf("NOT GAME DATA") >= 0 && as.indexOf("HZ PERF FIXTURE") >= 0, "Mode B fixture is labeled");
expect(as.indexOf("public function hzPerfSnapshot") >= 0, "explicit AS snapshot");

const act = funcBody(as, "hzOnTgAct");
const items = funcBody(as, "hzOnTgItems");
expect(act.indexOf("hzT19Ver++") < 0, "activation does not blindly bump hzT19Ver");
expect(items.indexOf("hzT19Ver++") < 0, "item list does not blindly bump hzT19Ver");
expect(act.indexOf("hzT19ActPay") >= 0 && items.indexOf("hzT19ItemsPay") >= 0, "payload fingerprints on events");

const tick = funcBody(as, "hzT19Tick");
expect(tick.indexOf("hzTgGhost * 200") < 0, "ghost fill is not in the content signature");
expect(tick.indexOf("hf * 8") < 0 && tick.indexOf("int(hf*") < 0, "hold fraction is not in the content signature");
expect(tick.indexOf("hzT19ActCached") >= 0 && tick.indexOf("hzT19ItemsCached") >= 0, "content sig uses payload cache");
expect(tick.indexOf("hzT19PaintFoeBars") >= 0 && tick.indexOf("hzT19PaintHold") >= 0, "HP and hold are property paints");
expect(tick.indexOf("hzT19Content") >= 0, "full rebuild still exists for payload/layout changes");
expect(tick.indexOf("hzPerfSkipHover") >= 0, "Mode A/G can skip hover GFx");
expect(tick.indexOf("hzT19Off") >= 0, "Mode A/G hide a leftover Horizon card once");
expect(tick.indexOf("hzT19Fixture") >= 0, "Mode B draws the fixture");

const content = funcBody(as, "hzT19Content");
expect(content.indexOf("hzT19BarG") >= 0 || as.indexOf("this.hzT19BarG") >= 0, "foe bars use a retained sprite");
expect(as.indexOf("this.hzT19HoldG") >= 0, "hold meters use a retained sprite");

const tw = funcBody(as, "hzTW");
expect(tw.indexOf("twTxt") >= 0, "text width cache is keyed on the field text");
expect(tw.indexOf("twFace") >= 0 && tw.indexOf("hzFontFace") >= 0, "text width cache misses on FontFace");
expect(tw.indexOf("hzTextScale") >= 0 && tw.indexOf("hzHeaderStyle") >= 0, "text width cache misses on TextScale/HeaderStyle");
expect(as.indexOf("hzApplyTypo") >= 0, "F11 typography path still exists");

const fade = funcBody(as, "hzShow");
expect(as.indexOf("if(!this.hzFadeCards)") >= 0, "FadeCards still only snaps fixed HUD fades");
expect(tick.indexOf("hzFadeCards") < 0, "hover tick is not gated by FadeCards");

const watchBlockStart = as.indexOf("// =================== 0.43.1.0 watch + center-reticle rule ===================");
const watchBlockEnd = as.indexOf("// =================== end Horizon UI (HUD module) ===================");
const watch = watchBlockStart >= 0 && watchBlockEnd > watchBlockStart ? as.slice(watchBlockStart, watchBlockEnd) : "";
expect(watch.indexOf("getTimer") < 0, "watch block still has no getTimer");

expect(scan.indexOf("hzsPerfSkipDraw") >= 0, "scanner honors Mode A/F/G skip");
expect(scan.indexOf("hzsFrame % 6") >= 0, "scanner 6-frame progress walk stays (live bioscan %)");

expect(perfH.indexOf("std::thr") < 0, "perf header starts no worker");
expect(main.indexOf("HzPerfDumpOnce") >= 0, "DLL dump is explicit");
expect(main.indexOf("QueryPerformanceCounter") >= 0, "native clock is QPC");

const pay = funcBody(as, "hzT19ActPay");
expect(pay.indexOf("sHeaderText") >= 0 && pay.indexOf("uMode") >= 0 && pay.indexOf("bStealing") >= 0, "prompt identity is in the fingerprint");
expect(pay.indexOf("sTextPressAndRelease") >= 0 && pay.indexOf("sTextHold") >= 0, "button labels are in the fingerprint");
const itemPay = funcBody(as, "hzT19ItemsPay");
expect(itemPay.indexOf("uCount") >= 0 && itemPay.indexOf("uRarity") >= 0 && itemPay.indexOf("uValue") >= 0, "loot count/content stay live");
const onePay = funcBody(as, "hzT19ItemPay");
expect(onePay.indexOf("uCount") >= 0, "single-item quantity stays in the fingerprint");

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("ok hover_perf_test");
