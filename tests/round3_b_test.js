// 0.43.6 round 3 step B: closed UI keeps nothing drawn. The F11 window body (every tab, row, label, keycap and preview)
// and the finished intro splash are emptied; both are drawn from scratch on their next use (hzToggleSettings ->
// hzSetDraw, ARRANGE CANCEL -> hzSetDraw; hzSplashStart -> hzSplashMake, hzSplashApply rebuilds a missing splash).
// ARRANGE (hzArrExit) and the message log (hzMsglogForceClose) already emptied their layers; pinned here.
// Run: node tests/round3_b_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { readAs, fnText, mkFn, baseHost, expect, finish } = require("./lib/r3");
const as = readAs();

function spr() { return { kids: [], cleared: 0, get numChildren() { return this.kids.length; }, removeChildAt(i) { this.kids.splice(i, 1); }, addChild(c) { this.kids.push(c); }, graphics: { n: 0, clear() { this.n++; } } }; }
{
	const h = baseHost({ hzSetIsOpen: true, hzSetBody: spr(), hzSetKeyOv: spr(), hzSetHits: [1, 2] });
	h.hzSetFree = mkFn(h, [], fnText(as, "hzSetFree").body);
	h.hzSetBody.kids = ["tab", "row", "label", h.hzSetKeyOv];
	h.hzSetFree();
	expect(h.hzSetBody.kids.length === 4 && h.hzSetHits.length === 2, "F11 open: nothing is freed");
	h.hzSetIsOpen = false; h.hzSetFree();
	expect(h.hzSetBody.kids.length === 0 && h.hzSetBody.graphics.n === 1 && h.hzSetKeyOv.graphics.n === 1 && h.hzSetHits.length === 0, "F11 closed: the body is empty, its drawing and hit list cleared");
	const n = baseHost({ hzSetIsOpen: false, hzSetBody: null, hzSetKeyOv: null, hzSetHits: [] });
	mkFn(n, [], fnText(as, "hzSetFree").body)();
	expect(true, "F11 never opened: no error");
}
{
	const close = fnText(as, "hzSetClose").body;
	expect(/this\.hzSetIsOpen = false;[\s\S]*this\.hzSetFree\(\);\s*$/.test(close), "hzSetClose frees after it marks the window closed");
	const tog = fnText(as, "hzToggleSettings").body;
	expect(/this\.hzSetPlace\(\);\s*this\.hzSetDraw\(\);/.test(tog), "every open draws the whole window again");
	const draw = fnText(as, "hz51Draw").body;
	expect(/while\(b\.numChildren > 0\) \{ b\.removeChildAt\(0\); \}/.test(draw) && /b\.addChild\(this\.hzSetKeyOv\);/.test(draw), "hzSetDraw starts from an empty body and re-adds the keycap layer");
	expect(/if\(this\.hzSetIsOpen && this\.HorizonSettings_mc\)[\s\S]*this\.hzSetDraw\(\);/.test(fnText(as, "hzArrExit").body), "ARRANGE CANCEL back into F11 redraws");
	expect(/removeChildAt\(0\)/.test(fnText(as, "hzArrExit").body) && /removeChildAt\(0\)/.test(fnText(as, "hzMsglogForceClose").body), "ARRANGE and the message log already empty their layers");
}
{
	const h = baseHost({ hzSplash: spr(), hzSplashOn: true });
	h.hzSplashFree = mkFn(h, [], fnText(as, "hzSplashFree").body);
	h.hzSplash.kids = ["hzStreak", "hzLetters", "hzSub"];
	h.hzSplashFree();
	expect(h.hzSplash.kids.length === 3, "splash running: kept");
	h.hzSplashOn = false; h.hzSplashFree();
	expect(h.hzSplash.kids.length === 0, "splash done: emptied");
	const tick = fnText(as, "hzSplashTick").body;
	expect((tick.match(/this\.hzSplashState = "done";\s*this\.hzSplashFree\(\);/g) || []).length === 2, "both done paths (timeout, cancel) free it");
	expect(/getChildByName\("hzLetters"\) == null\) \{ this\.hzSplashMake\(\); \}/.test(fnText(as, "hzSplashApply").body) && /this\.hzSplashMake\(\);/.test(fnText(as, "hzSplashStart").body), "a new start rebuilds it");
}
finish("round3 B");
