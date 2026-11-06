// Pins for the quest tracker, the affliction popup, and the detection ring in horizon_block.as.
// Run: node tests/quest_tracker_test.js
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const checks = fs.readFileSync(path.join(root, "CHECKS_0.43.1.0.md"), "utf8").replace(/\r\n/g, "\n");

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

const OFF = 3;
const ON = 1;

function isOpt(t) {
	if (t == null) return false;
	return /\(\s*optional\s*\)|^\s*optional\b/i.test(t);
}

function optStrip(t) {
	return String(t).replace(/\s*\(\s*optional\s*\)\s*/gi, " ").replace(/^\s*optional\s*[:\-]?\s*/i, "").replace(/^\s+|\s+$/g, "");
}

function fmtDist(m) {
	if (Number.isNaN(m) || m <= 0) return "";
	return m >= 1000 ? (m / 1000).toFixed(1) + " km" : Math.round(m) + " m";
}

function tracker() {
	return { main: "", mainT: 0, dist: 0, off: false, objs: [], subs: [] };
}

function keep(st, o, now) {
	st.main = String(o.strText);
	st.mainT = now;
	st.dist = Number(o.fDistanceToPlayer);
	st.off = o.uiMarkerIconType === OFF;
}

function pickMain(st, list, now) {
	if (st.main.length > 0) {
		for (const o of list) {
			if (String(o.strText) === st.main) {
				keep(st, o, now);
				return o;
			}
		}
		if (now - st.mainT < 3000) {
			return { strText: st.main, fDistanceToPlayer: st.dist, hzHeld: true, uiMarkerIconType: st.off ? OFF : ON };
		}
	}
	let pick = null;
	for (const ob of st.objs) {
		if (pick != null || isOpt(ob)) continue;
		for (const o of list) {
			if (pick == null && String(o.strText) === ob) pick = o;
		}
	}
	if (pick == null) {
		for (const o of list) {
			if (pick == null && !isOpt(String(o.strText)) && o.uiMarkerIconType !== OFF) pick = o;
		}
	}
	if (pick == null && list.length > 0) pick = list[0];
	if (pick != null) keep(st, pick, now);
	else st.main = "";
	return pick;
}

function buildSubs(st, list, active) {
	const subs = [];
	const texts = [];
	const mt = active ? String(active.strText) : "";
	for (const o of list) {
		const t = String(o.strText);
		texts.push(t);
		if (t === mt) continue;
		const off = o.uiMarkerIconType === OFF;
		subs.push({ t: optStrip(t), opt: isOpt(t), d: off ? "OFF PLANET" : fmtDist(Number(o.fDistanceToPlayer)) });
	}
	for (const ob of st.objs) {
		if (ob === mt || texts.indexOf(ob) >= 0) continue;
		subs.push({ t: optStrip(ob), opt: isOpt(ob), d: "" });
	}
	subs.sort((a, b) => {
		if (Boolean(a.opt) !== Boolean(b.opt)) return a.opt ? 1 : -1;
		const ta = String(a.t).toLowerCase();
		const tb = String(b.t).toLowerCase();
		return ta < tb ? -1 : ta > tb ? 1 : 0;
	});
	while (subs.length > 3) subs.pop();
	st.subs = subs;
}

function setObjs(q) {
	const a = q.ObjectiveDataA;
	if (!a) return null;
	const out = [];
	for (const ob of a) {
		if (!ob || ob.strObjectiveText == null) continue;
		if (ob.bCompleted === true || ob.bFailed === true || ob.bDormant === true) continue;
		const s = String(ob.strObjectiveText);
		if (s.length > 0 && out.indexOf(s) < 0) out.push(s);
	}
	return out;
}

const m = (text, type, dist) => ({ strText: text, uiMarkerIconType: type, fDistanceToPlayer: dist });

const st = tracker();
st.objs = ["Talk to Sarah", "(Optional) Visit the lodge", "Find the artifact"];
let active = pickMain(st, [m("(Optional) Visit the lodge", ON, 40), m("Find the artifact", ON, 120), m("Talk to Sarah", OFF, 0)], 1000);
expect(active.strText === "Talk to Sarah", "the first open objective wins over an earlier optional marker");
buildSubs(st, [m("(Optional) Visit the lodge", ON, 40), m("Find the artifact", ON, 120), m("Talk to Sarah", OFF, 0)], active);
expect(st.subs.length === 2, "the main objective is not repeated as a sub-line");
expect(st.subs[0].t === "Find the artifact" && st.subs[0].opt === false, "a required sub-line stays ahead of an optional one");
expect(st.subs[1].t === "Visit the lodge" && st.subs[1].opt === true && st.subs[1].d === "40 m", "optional text is stripped and the distance is kept");

const held = pickMain(st, [m("Find the artifact", ON, 90)], 2000);
expect(held.hzHeld === true && held.strText === "Talk to Sarah", "a missing marker is held for 3 seconds");
const next = pickMain(st, [m("Find the artifact", ON, 90), m("(Optional) Visit the lodge", ON, 10)], 5000);
expect(next.strText === "Find the artifact", "after the hold, the next open on-planet objective is the main line");

const many = tracker();
many.objs = [];
const crowd = ["Bravo", "Alpha", "Charlie", "Delta", "Echo"].map((t, i) => m(t, ON, (i + 1) * 100));
const first = pickMain(many, crowd, 0);
buildSubs(many, crowd, first);
expect(first.strText === "Bravo", "with no quest list the first on-planet marker is the main line");
expect(many.subs.length === 3, "sub-lines stop at three");
expect(many.subs.map((s) => s.t).join(",") === "Alpha,Charlie,Delta", "extra sub-lines drop off the end after the sort");

const offOnly = tracker();
const offPick = pickMain(offOnly, [m("Leave the system", OFF, 0)], 0);
expect(offPick.strText === "Leave the system", "an off-planet marker is the main line when it is the only one");
buildSubs(offOnly, [offPick, m("Another system", OFF, 0)], offPick);
expect(offOnly.subs[0].d === "OFF PLANET", "an off-planet sub-line says OFF PLANET");

expect(setObjs({ ObjectiveDataA: [{ strObjectiveText: "Open" }, { strObjectiveText: "Done", bCompleted: true }, { strObjectiveText: "Asleep", bDormant: true }, { strObjectiveText: "Open" }] }).join("|") === "Open", "completed, dormant, and duplicate objectives are dropped");
expect(setObjs({}) === null, "a missing objective list does not invent one");
expect(isOpt("Optional: scan the rock") && optStrip("Optional: scan the rock") === "scan the rock", "a leading optional label is recognized and removed");

const build = funcBody(as, "hz27QBuild");
expect(build.indexOf(',13,"rg","mut"') >= 0 && build.indexOf(',13,"sb","mut"') >= 0, "quest sub-lines are 13 px");
expect(build.indexOf(",11,") < 0, "quest sub-lines are not 11 px");
const title = funcBody(as, "hzSetQuestTitle");
expect(title.indexOf('this.hzQObjStr = ""') >= 0 && title.indexOf('this.hzQDistStr = ""') >= 0, "a new quest name clears the previous objective");
expect(title.indexOf("No active objective") >= 0, "a new quest name clears the old card line");

const bio = funcBody(as, "hz27BioHide");
expect(bio.indexOf("this.hzShowAfflictions && !this.hzUserHidden") >= 0, "the bio popup follows the afflictions card");
expect(bio.indexOf("hzHideVanillaWatch &&") < 0, "the bio popup does not follow the watch style");
const det = funcBody(as, "hz31DetHide");
expect(det.indexOf("this.hzStealthOn || this.hzEnemyBarOn || this.hzEdgePulse") >= 0, "the detection ring follows the combat cues");
expect(det.indexOf("hzHideVanillaWatch") < 0, "the detection ring does not follow the watch style");

expect(checks.indexOf("The last good reading if the clock throws") >= 0, "CHECKS names the PC clock fallback");
expect(checks.indexOf("not the watch style") >= 0, "CHECKS separates the bio popup and the detection ring from the watch");

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("quest tracker tests passed");
