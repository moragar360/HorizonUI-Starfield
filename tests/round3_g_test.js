// 0.43.6 round 3 step G: private census line ([Debug] PerfDiag=1 only, off by default). Taken once, at the first
// layout or when PerfDiag turns on after it; kept in hzCensusS, added to the "perf parts" dump line and queued once for
// the watchlog when WatchLog=1. It only reads the display tree.
// Run: node tests/round3_g_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const fs = require("fs");
const path = require("path");
const { readAs, fnText, mkFn, bind, baseHost, expect, finish } = require("./lib/r3");
const as = readAs();

function tf(vis) { return { __tf: true, visible: vis !== false }; }
function box(kids, vis) { return { __doc: true, visible: vis !== false, kids: kids || [], get numChildren() { return this.kids.length; }, getChildAt(i) { return this.kids[i]; } }; }
const ROOTS = (fnText(as, "hzCensusRoots").body.match(/return \[([^\]]*)\]/) || [0, ""])[1].split(",").map((x) => x.trim().replace(/^this\./, ""));
const NAMES = JSON.parse((as.match(/HZ_CENSUS_ROOTS:Array = (\[[^\]]*\]);/) || [0, "[]"])[1]);

function host(extra) {
	const h = baseHost(Object.assign({ hzPerfOn: true, hzCensusS: null, hzWlOn: false, pushed: [], hzFrameN: 77, hzTexts: [1, 2, 3], hzFades: [1], hzSz: [1, 2],
		hz55Shed: true, hzEqShedOn: true, hz26ChS: null, hzSetBody: box([]), hzSplash: box([]), HZ_CENSUS_ROOTS: NAMES, HZ_CENSUS_MAX: 40000 }, extra || {}));
	ROOTS.forEach((r) => { if (!(r in h)) h[r] = null; });
	h.hzPerfNow = () => 1234.4;
	h.hzWlPush = (s) => h.pushed.push(s);
	h.getChildAt = (i) => h.kids[i];
	bind(h, as, "hzCensusRoots"); bind(h, as, "hzCensusWalk"); bind(h, as, "hzCensusTake");
	return h;
}

expect(ROOTS.length === NAMES.length && ROOTS.length >= 20 && ROOTS.every((r) => /^(Horizon\w+_mc|hzArr_mc|hzSplash|hz43Watch)$/.test(r)), "the root list and its labels line up (" + ROOTS.length + ")");
{
	const h = host({ hzPerfOn: false });
	h.hzCensusTake();
	expect(h.hzCensusS === null && h.pushed.length === 0, "PerfDiag off: nothing is taken");
}
{
	// card: 7 objects (card, body with 2 texts one hidden, a hidden box with a text and an empty box); quest: hidden box + text;
	// the splash (empty) is a root too; the vanilla box is counted only in the HUD total
	const card = box([box([tf(), tf(false)]), box([tf(), box([])], false)]);
	const quest = box([tf()], false);
	const vanilla = box([box([tf()])]);
	const h = host({ HorizonCard_mc: card, HorizonQuest_mc: quest, hzWlOn: true, hz26ChS: {} });
	h.__doc = true; h.visible = true; h.kids = [card, quest, vanilla];
	Object.defineProperty(h, "numChildren", { get() { return this.kids.length; } });
	h.hzCensusTake();
	const s = h.hzCensusS;
	expect(/^census t=1234 f=77 hz=10,4,6,6,3 roots=3\/21 /.test(s), "Horizon totals: objects, text fields, containers, hidden, hidden text fields (" + s.slice(0, 60) + ")");
	expect(/ hud=13,5,8,6,3 /.test(s), "the whole HUD movie is counted too (the root itself included)");
	expect(/ reg=3,1,2 shed=1,1,1,0,0 \| /.test(s), "registry sizes and the round 3 B / C states");
	expect(/ \| Card=7\/3 Quest=2\/1 Splash=1\/0$/.test(s), "per-root objects / text fields, only the roots that exist");
	expect(h.pushed.length === 1 && h.pushed[0] === s, "WatchLog=1: queued once");
	h.HorizonCard_mc = box([]); h.hzCensusTake();
	expect(h.hzCensusS === s && h.pushed.length === 1, "taken once per session");
}
{
	const h = host();
	h.__doc = true; h.visible = true; h.kids = []; Object.defineProperty(h, "numChildren", { get() { return 0; } });
	h.hzCensusWalk = () => { throw new Error("x"); };
	try { h.hzCensusTake(); } catch (e) { }
	expect(h.hzCensusS === "", "a throw still marks it taken (never retried every layout)");
}
{
	const lay = fnText(as, "hzLayout").body;
	expect(/if\(this\.hzPerfOn && this\.hzCensusS == null\) \{ try \{ this\.hzCensusTake\(\); \} catch\(eCen:Error\) \{ \} \}\s*return true;\s*$/.test(lay), "hook 1: the end of a successful layout, gated by PerfDiag");
	const ap = fnText(as, "hzPerfApply").body;
	expect(/if\(this\.hzPerfOn && this\.hzLayEver && this\.hzCensusS == null\) \{ try \{ this\.hzCensusTake\(\); \}/.test(ap), "hook 2: PerfDiag turned on after the first layout");
	const calls = as.split("\n").filter((l) => /this\.hzCensusTake\(\)/.test(l));
	expect(calls.length === 2 && calls.every((l) => /this\.hzPerfOn &&/.test(l)), "no other caller; every caller tests PerfDiag first");
	expect(!/hzCensus/.test(fnText(as, "hzOnFrame").body) && !/hzCensus/.test(fnText(as, "hzPbFrame") ? fnText(as, "hzPbFrame").body : ""), "nothing in the frame handlers");
	expect(/if\(this\.hzCensusS != null && this\.hzCensusS\.length > 0\) \{ s \+= " \| " \+ this\.hzCensusS; \}/.test(fnText(as, "hzPerfParts").body), "the dump's parts line carries it");
	const take = fnText(as, "hzCensusTake").body + fnText(as, "hzCensusWalk").body;
	expect(!/\.(visible|alpha|x|y|text)\s*=[^=]|addChild|removeChild|graphics/.test(take), "it only reads");
	const defIni = fs.readdirSync(path.join(__dirname, "..")).length >= 0 && !/Census/i.test((as.match(/HZ_SET_DEF:Object = \{[^}]*\}/) || [""])[0]);
	expect(defIni, "no setting or INI key");
}
finish("round3 G");
