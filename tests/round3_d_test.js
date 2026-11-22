// 0.43.6 round 3 step D: no endless whole-HUD searches. hz26V (the vanilla counterparts the target / hit / stealth
// widgets hide) walked the whole HUD every 90 frames, for the whole session, for a name the property path did not
// resolve. Now a name missing for 540 frames (6 walk slots) gets no more walks; the property path is still read on
// every call and a found clip is kept, as before. The per-pass memo of the watch code (hz43*) is unchanged on purpose
// (its re-search follows a moved first match; see hidecache_model_test).
// Run: node tests/round3_d_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { readAs, fnText, mkFn, baseHost, expect, finish } = require("./lib/r3");
const as = readAs();

function host() {
	const h = baseHost({ hz26VCache: {}, hz26VMiss: {}, hz26VMissF: {}, HZ26_V_MISSMAX: 540, hzFrameN: 0, walks: 0, found: null,
		EnemyHealthHolder_mc: null, HitDamageBase_mc: null, HitAndKillIndicator_mc: null, TopCenterGroup_mc: null, CenterGroup_mc: null,
		Object: (o) => o });
	h.hzFindByName = (c, n) => { h.walks++; return h.found; };
	h.hz26V = mkFn(h, ["name"], fnText(as, "hz26V").body);
	return h;
}
{
	const h = host();
	let walkFrames = [];
	for (let f = 1; f <= 2000; f++) { h.hzFrameN = f; const w = h.walks; h.hz26V("HitDamageBase_mc"); h.hz26V("HitDamageBase_mc"); if (h.walks > w) walkFrames.push(f); }
	expect(walkFrames.length === 6 && walkFrames.every((f) => f % 90 === 5), "a never-found name: 6 walks on the old 90-frame slots, then none (" + walkFrames.join(",") + ")");
	h.HitDamageBase_mc = { name: "HitDamageBase_mc" };
	expect(h.hz26V("HitDamageBase_mc") === h.HitDamageBase_mc, "the property path still finds it after the cap");
	h.HitDamageBase_mc = null;
	expect(h.hz26V("HitDamageBase_mc") != null, "and the found clip is kept, as before");
}
{
	const h = host();
	h.found = { name: "StealthMeter_mc" };
	h.hzFrameN = 95; const d = h.hz26V("StealthMeter_mc");
	expect(d === h.found && h.walks === 1, "a walk that finds the clip keeps it (before the cap)");
}
{
	const b = fnText(as, "hz26V").body;
	expect(/if\(d == null && this\.hzFrameN % 90 == 5\) \{ d = this\.hzFindByName\(this,name,0\); \}/.test(b), "the walk line itself is unchanged");
	expect(/private static const HZ26_V_MISSMAX:int = 540;/.test(as), "cap is 540 frames (6 walk slots)");
}
finish("round3 D");
