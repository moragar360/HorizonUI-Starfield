// 0.43.6 round 3 review SF-1: the step D walk cutoff (HZ26_V_MISSMAX) starts again on every edge where a missing
// clip can appear: a save load (a frame gap over 1 s), a hide-list rebuild, and a child-count change (HUD, BottomLeftGroup,
// or a container of a clip already found). A kept clip that leaves the HUD is searched again. Edges only: the child
// counts are read only while a name is at the cap.
// Run: node tests/round3_sf1_test.js
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const { readAs, fnText, mkFn, bind, baseHost, expect, finish } = require("./lib/r3");
const as = readAs();

function host() {
	const brg = { numChildren: 5, name: "BottomRightGroup" };
	const h = baseHost({ hz26VCache: {}, hz26VMiss: {}, hz26VMissF: {}, HZ26_V_MISSMAX: 540, hzFrameN: 0, walks: 0, kidReads: 0,
		hz26VMissAny: false, hz26VCapN: 0, hz26VSig: -1, hz26VLastW: 0, hz26VPar: [], numChildren: 40, hzBlg: { numChildren: 12 },
		EnemyHealthHolder_mc: null, HitDamageBase_mc: null, HitAndKillIndicator_mc: null, TopCenterGroup_mc: null, CenterGroup_mc: null,
		tree: {}, brg, Object: (o) => o });
	h.hzFindByName = (c, n) => { h.walks++; return h.tree[n] || null; };
	for (const n of ["hz26V", "hz26VMissReset", "hz26VKids", "hz26VEdge"]) bind(h, as, n);
	const kids = h.hz26VKids;
	h.hz26VKids = () => { h.kidReads++; return kids(); };
	return h;
}
// run frames: the hz26Tick order (hz26VEdge, then the hz26Vanilla lookups), 16 ms apart
function run(h, from, to, names, t0) {
	let w = 0;
	for (let f = from; f <= to; f++) { h.hzFrameN = f; const b = h.walks; h.hz26VEdge(t0 + f * 16); for (const n of names) h.hz26V(n); if (h.walks > b) w++; }
	return w;
}
const G = "EquippedGrenadeIcon_mc", P = "PowerBar_mc";
{
	// late appearance after the cap, with no edge: still not found (the cutoff holds), then a child-count change finds it
	const h = host();
	expect(run(h, 1, 2000, [G], 0) === 6 && h.hz26VCapN === 1, "a missing walk-only name: 6 walks, then capped");
	const r0 = h.kidReads;
	run(h, 2001, 2100, [G], 0);
	expect(h.kidReads - r0 === 100, "while capped: one child-count read per frame (hz26VEdge), not per lookup");
	h.tree[G] = { name: G, parent: h.brg };   // appears inside a container whose count we cannot see yet
	expect(run(h, 2101, 2400, [G], 0) === 0, "no edge, no walk (the cutoff still holds)");
	h.numChildren++;   // the group that carries it is added to the HUD
	run(h, 2401, 2600, [G], 0);
	expect(h.hz26VCache[G] === h.tree[G], "late appearance + a HUD child-count change: found again");
	expect(h.hz26VCapN === 0 && h.hz26VMiss[G] === undefined, "found: no cap left, no count for the name");
	const r1 = h.kidReads;
	run(h, 2601, 2800, [G], 0);
	expect(h.kidReads === r1, "nothing capped: the child counts are not read at all");
}
{
	// the BottomLeftGroup child count is an edge too
	const h = host();
	run(h, 1, 2000, [P], 0);
	h.tree[P] = { name: P, parent: h.brg };
	h.hzBlg.numChildren--;
	run(h, 2001, 2200, [P], 0);
	expect(h.hz26VCache[P] === h.tree[P], "BottomLeftGroup child-count change restarts the counts");
}
{
	// a container of a found clip: a sibling walk-only part appears late in the same group
	const h = host();
	h.tree[G] = { name: G, parent: h.brg };
	run(h, 1, 2000, [G, P], 0);
	expect(h.hz26VCache[G] != null && h.hz26VCapN === 1 && h.hz26VPar.indexOf(h.brg) >= 0, "the grenade icon is found and its group recorded; PowerBar capped");
	h.tree[P] = { name: P, parent: h.brg };
	expect(run(h, 2001, 2300, [G, P], 0) === 0, "no count change yet: no walk");
	h.brg.numChildren++;
	run(h, 2301, 2500, [G, P], 0);
	expect(h.hz26VCache[P] === h.tree[P], "the group's child count changes: the late sibling is found");
}
{
	// replaced / rebuilt by a mod: the kept clip leaves the HUD, a new one takes its place
	const h = host();
	const old = { name: G, parent: h.brg };
	h.tree[G] = old;
	run(h, 1, 100, [G], 0);
	expect(h.hz26VCache[G] === old, "found and kept");
	old.parent = null;
	const nu = { name: G, parent: h.brg };
	h.tree[G] = nu;
	run(h, 101, 400, [G], 0);
	expect(h.hz26VCache[G] === nu, "the kept clip left the HUD: the new clip is found");
	expect(h.hz26V(G) === nu && h.hz26VCapN === 0, "and kept");
}
{
	// replaced after the cap of an unrelated name, rebuilt with no visible count change: the load gap restarts the counts
	const h = host();
	run(h, 1, 2000, [G], 0);
	h.tree[G] = { name: G, parent: h.brg };
	expect(run(h, 2001, 2300, [G], 0) === 0, "capped, no edge");
	h.hzFrameN = 2301; h.hz26VEdge(2300 * 16 + 5000);   // a save load: a 5 s frame gap
	expect(h.hz26VCapN === 0 && Object.keys(h.hz26VMiss).length === 0 && h.hz26VSig === -1, "a load gap clears every miss count");
	run(h, 2302, 2500, [G], 5000 - 16);
	expect(h.hz26VCache[G] === h.tree[G], "after the load the late clip is found");
	const h2 = host();
	run(h2, 1, 200, [G], 0);
	const m = h2.hz26VMiss;
	h2.hzFrameN = 201; h2.hz26VEdge(201 * 16 + 900);
	expect(h2.hz26VMiss === m, "a frame gap under 1 s is not a load");
}
{
	// the hide-list rebuild clears the counts (functional + it is called inside the rebuild block)
	const h = host();
	run(h, 1, 2000, [G], 0);
	h.tree[G] = { name: G, parent: h.brg };
	h.hz26VMissReset();
	run(h, 2001, 2200, [G], 0);
	expect(h.hz26VCache[G] === h.tree[G], "a rebuild reset lets the walk find a late clip");
	h.hz26VMissReset();
	const before = h.hz26VMiss;
	h.hz26VMissReset();
	expect(h.hz26VMiss === before, "a reset with no counts allocates nothing");
	const ofb = fnText(as, "hzOnFrame").body;
	const i = ofb.indexOf("this.hzHideCache = [];"), j = ofb.indexOf("this.hz26VMissReset();");
	expect(i > 0 && j > i && j - i < 300, "hzOnFrame: the hide-list rebuild block calls hz26VMissReset");
	const tb = fnText(as, "hz26Tick").body;
	expect(tb.indexOf("this.hz26VEdge(now);") > 0 && tb.indexOf("this.hz26VEdge(now);") < tb.indexOf("this.hz26Vanilla();"), "hz26Tick runs hz26VEdge before the vanilla lookups");
}
{
	// still edge-only and within the step D rules
	const b = fnText(as, "hz26V").body;
	expect(/if\(d == null && this\.hzFrameN % 90 == 5\) \{ d = this\.hzFindByName\(this,name,0\); \}/.test(b), "the walk line is unchanged");
	const e = fnText(as, "hz26VEdge").body + fnText(as, "hz26VKids").body + fnText(as, "hz26VMissReset").body;
	expect(!/getChildAt|getChildByName|addEventListener|hzFrameN %/.test(e), "the edge code does no lookups or frame-modulo work");
}
finish("round3 SF-1");
