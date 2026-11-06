// Ports the selected-quest tracker in horizon_block.as.
// Bullets and the subtitle come from that quest's open steps. Markers only supply distance.
// Run: node tests/quest_tracker_test.js
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const checks = fs.readFileSync(path.join(root, "CHECKS_0.43.1.0.md"), "utf8").replace(/\r\n/g, "\n");
const log = fs.readFileSync(path.join(root, "CHANGELOG.md"), "utf8").replace(/\r\n/g, "\n");

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

const QUEST_TEXT = 11;

function isOpt(t) {
	if (t == null) return false;
	return /\(\s*optional\s*\)|^\s*optional\b/i.test(String(t));
}

function optStrip(t) {
	return String(t).replace(/\s*\(\s*optional\s*\)\s*/i, " ").replace(/^\s*optional\s*[:\-]?\s*/i, "").replace(/^\s+|\s+$/g, "");
}

function fmtDist(m) {
	if (Number.isNaN(m) || m <= 0) return "";
	return m >= 1000 ? (m / 1000).toFixed(1) + " km" : Math.round(m) + " m";
}

function idOf(q, key) {
	if (!q || q[key] === undefined || q[key] === null) return "";
	return String(q[key]);
}

function tracker() {
	return {
		name: "",
		id: "",
		disp: "",
		objs: [],
		subs: [],
		list: [],
		marks: null,
		cache: [],
		text: "",
		dist: "",
	};
}

function isSelected(st, q) {
	if (!q) return false;
	const qid = idOf(q, "uQuestID");
	const did = idOf(q, "uDisplayedQuestID");
	if (st.id.length > 0 || st.disp.length > 0) {
		if (qid.length > 0 && (qid === st.id || qid === st.disp)) return true;
		if (did.length > 0 && (did === st.id || did === st.disp)) return true;
		return false;
	}
	const nm = q.strQuestName != null ? String(q.strQuestName) : "";
	return st.name.length > 0 && nm.toLowerCase() === st.name.toLowerCase();
}

function isProse(q) {
	if (!q) return false;
	if (q.bSummary === true || q.bQuestText === true) return true;
	if (q.uType === undefined || q.uType === null) return false;
	return Number(q.uType) === QUEST_TEXT;
}

function carriesSteps(q) {
	if (!q || isProse(q)) return false;
	if (q.uType === undefined || q.uType === null) return true;
	const t = Number(q.uType);
	return t === 0 || t === 3 || t === 4 || t === 5 || t === 6 || t === 7 || t === 9;
}

function setObjs(st, q) {
	st.objs = [];
	const a = q && Array.isArray(q.ObjectiveDataA) ? q.ObjectiveDataA : null;
	if (!a) return;
	for (const ob of a) {
		if (!ob || ob.strObjectiveText == null) continue;
		if (ob.bCompleted === true || ob.bFailed === true || ob.bDormant === true) continue;
		if (ob.bSummary === true || ob.bQuestText === true) continue;
		const s = String(ob.strObjectiveText);
		if (s.length > 0 && st.objs.indexOf(s) < 0) st.objs.push(s);
	}
}

function remember(st, q) {
	const qid = idOf(q, "uQuestID");
	const did = idOf(q, "uDisplayedQuestID");
	if (qid.length > 0) st.id = qid;
	if (did.length > 0) st.disp = did;
	const name = q.strQuestName != null ? String(q.strQuestName) : st.name;
	if (!name) return;
	let hit = st.cache.find((c) => String(c.name).toLowerCase() === name.toLowerCase());
	if (!hit) {
		hit = { name, id: "", disp: "", objs: [] };
		st.cache.push(hit);
	}
	hit.name = name;
	if (st.id) hit.id = st.id;
	if (st.disp) hit.disp = st.disp;
	hit.objs = st.objs.slice();
}

function applyCache(st, name) {
	const hit = st.cache.find((c) => String(c.name).toLowerCase() === name.toLowerCase());
	if (!hit) return;
	st.id = hit.id != null ? String(hit.id) : "";
	st.disp = hit.disp != null ? String(hit.disp) : "";
	st.objs = hit.objs.slice();
}

function markFor(list, text) {
	for (const o of list) {
		if (o && String(o.strText) === text) return o;
	}
	return null;
}

function firstObj(st) {
	let any = "";
	for (const ob of st.objs) {
		if (!any) any = ob;
		if (!isOpt(ob)) return ob;
	}
	return any;
}

function pickMain(st) {
	const text = firstObj(st);
	if (!text) return null;
	const mk = markFor(st.list, text);
	if (mk) return mk;
	return { strText: text, fDistanceToPlayer: 0, uiMarkerIconType: 0 };
}

function buildSubs(st, active) {
	const mt = active ? String(active.strText) : "";
	const subs = [];
	for (const ob of st.objs) {
		if (subs.length >= 3) break;
		if (ob === mt) continue;
		const mk = markFor(st.list, ob);
		const off = mk && Number(mk.uiMarkerIconType) === 3;
		subs.push({
			t: optStrip(ob),
			opt: isOpt(ob),
			d: !mk ? "" : off ? "OFF PLANET" : fmtDist(Number(mk.fDistanceToPlayer)),
		});
	}
	subs.sort((a, b) => {
		if (Boolean(a.opt) !== Boolean(b.opt)) return a.opt ? 1 : -1;
		const ta = String(a.t).toLowerCase();
		const tb = String(b.t).toLowerCase();
		return ta < tb ? -1 : ta > tb ? 1 : 0;
	});
	st.subs = subs;
}

function writeActive(st, active) {
	st.text = active ? String(active.strText) : "";
	if (!active) st.dist = "";
	else if (Number(active.uiMarkerIconType) === 3) st.dist = "OFF PLANET";
	else st.dist = fmtDist(Number(active.fDistanceToPlayer));
}

function refresh(st) {
	const active = pickMain(st);
	buildSubs(st, active);
	writeActive(st, active);
}

function fill(st, mm) {
	st.list = [];
	if (!mm) return;
	for (const o of mm) {
		if (!o) continue;
		const t = o.strText ? String(o.strText) : "";
		if (!t || st.list.some((x) => String(x.strText) === t)) continue;
		st.list.push(o);
	}
}

function updateQuests(st, mm) {
	if (mm) st.marks = mm;
	fill(st, mm || st.marks);
	refresh(st);
}

function clearSteps(st) {
	st.objs = [];
	st.subs = [];
	st.id = "";
	st.disp = "";
	st.text = "";
	st.dist = "";
}

function setTitle(st, name) {
	const next = name != null ? String(name) : "";
	const changed = next.toLowerCase() !== st.name.toLowerCase();
	if (changed) {
		clearSteps(st);
		applyCache(st, next);
	}
	st.name = next;
	if (changed) updateQuests(st, st.marks);
	else refresh(st);
}

function onUpdate(st, entries) {
	let accepted = false;
	for (const q of entries) {
		if (!isSelected(st, q) || isProse(q) || !carriesSteps(q)) continue;
		setObjs(st, q);
		remember(st, q);
		accepted = true;
	}
	if (!accepted) return;
	refresh(st);
}

function shown(st) {
	return [st.text, st.dist].concat(st.subs.map((s) => s.t + " " + s.d)).join(" | ");
}

function absent(st, words) {
	const blob = shown(st);
	for (const w of words) {
		if (blob.indexOf(w) >= 0) return false;
	}
	return true;
}

const m = (text, dist) => ({ strText: text, uiMarkerIconType: 1, fDistanceToPlayer: dist });
const markers = [m("Yumi", 127), m("Well", 110), m("Tuala", 130), m("Washakie", 400)];

const st = tracker();
setTitle(st, "Yumi");
updateQuests(st, markers);
onUpdate(st, [{ strQuestName: "Yumi", uQuestID: 2, ObjectiveDataA: [{ strObjectiveText: "Yumi" }] }]);
expect(st.text === "Yumi" && st.dist === "127 m", "Yumi's own step is cached with its marker distance");

setTitle(st, "PFB");
updateQuests(st, markers);
expect(st.text === "" && st.subs.length === 0 && absent(st, ["Yumi", "Well", "Tuala", "Washakie"]), "an empty step list shows no marker-derived rows");

onUpdate(st, [{ strQuestName: "PFB", uQuestID: 1, ObjectiveDataA: [{ strObjectiveText: "Washakie" }] }]);
expect(st.text === "Washakie" && st.dist === "400 m", "the subtitle is Washakie at 400 m");
expect(st.subs.length === 0 && absent(st, ["Yumi", "Well", "Tuala"]), "Yumi, Well, and Tuala appear nowhere");

updateQuests(st, markers);
expect(st.text === "Washakie" && st.dist === "400 m" && absent(st, ["Yumi", "Well", "Tuala"]), "a later compass tick does not bring the other markers back");

onUpdate(st, [{ strQuestName: "PFB", uQuestID: 1, uType: QUEST_TEXT, ObjectiveDataA: [{ strObjectiveText: "Quest text line" }] }]);
onUpdate(st, [{ strQuestName: "PFB", uQuestID: 1, bSummary: true, uType: 0, ObjectiveDataA: [{ strObjectiveText: "Summary line" }] }]);
expect(st.text === "Washakie" && absent(st, ["Quest text line", "Summary line"]), "a summary or quest-text update never becomes a bullet");

onUpdate(st, [{ strQuestName: "Other", uQuestID: 99, ObjectiveDataA: [{ strObjectiveText: "Yumi" }] }]);
expect(st.text === "Washakie" && absent(st, ["Yumi"]), "an update for a non-selected quest is ignored");

onUpdate(st, [{
	strQuestName: "PFB",
	uQuestID: 1,
	uType: 4,
	ObjectiveDataA: [
		{ strObjectiveText: "Washakie", bCompleted: true },
		{ strObjectiveText: "Report back" },
	],
}]);
expect(st.text === "Report back" && absent(st, ["Washakie"]), "a completed step drops out");

onUpdate(st, [{ strQuestName: "PFB", uQuestID: 1, uType: 3 }]);
expect(st.objs.length === 0 && st.text === "" && st.subs.length === 0 && absent(st, ["Yumi", "Well", "Tuala", "Washakie", "Report back"]), "a missing ObjectiveDataA clears");

setTitle(st, "Yumi");
expect(st.text === "Yumi" && st.dist === "127 m" && st.subs.length === 0 && absent(st, ["Washakie", "Report back", "Well", "Tuala"]), "switching to Yumi shows only Yumi, with no previous steps and no hold");

const pick = funcBody(as, "hz27PickMain");
expect(pick.indexOf("3000") < 0 && pick.indexOf("list[0]") < 0 && pick.indexOf("hzHeld") < 0, "the subtitle has no hold and no foreign-marker fallback");
expect(pick.indexOf("hz27QFirst") >= 0 && pick.indexOf("hz27QMark") >= 0, "the subtitle is the selected quest's first open step");
const subs = funcBody(as, "hz27QBuildSubs");
expect(subs.indexOf("hz27QObjs") >= 0 && subs.indexOf("subs.push") < 0, "bullets are taken from the selected quest's steps");
const setBody = funcBody(as, "hz27QSetObjs");
expect(setBody.indexOf("this.hz27QObjs = []") >= 0, "a missing objective array clears the step list");
expect(setBody.indexOf("bCompleted") >= 0 && setBody.indexOf("bFailed") >= 0 && setBody.indexOf("bDormant") >= 0, "completed, failed, and dormant steps are dropped");
const upd = funcBody(as, "hzOnQuestUpdate");
expect(upd.indexOf("uQuestID") >= 0 && upd.indexOf("uDisplayedQuestID") >= 0, "an update must match the selected quest id");
expect(upd.indexOf("hz27QIsProse") >= 0 && funcBody(as, "hz27QIsProse").indexOf("HDT_QUEST_TEXT_UPDATED") >= 0, "quest-text and summary updates are not steps");
expect(upd.indexOf("hz27QBuildSubs") >= 0 && upd.indexOf("hzQSync") >= 0, "the update handler rebuilds the bullets and syncs the card");
const title = funcBody(as, "hzSetQuestTitle");
expect(title.indexOf("hz27QClearSteps") >= 0 && title.indexOf("hz27QApplyCache") >= 0 && title.indexOf("hzUpdateQuests") >= 0, "a new title clears, restores that quest's steps, and reruns the marker lookup");
const build = funcBody(as, "hz27QBuild");
expect(build.indexOf(',13,"rg","mut"') >= 0 && build.indexOf(",11,") < 0, "quest sub-lines are 13 px");

expect(checks.split("\n")[6].indexOf("quest_tracker_test.js") >= 0, "CHECKS lists the quest tracker suite");
expect(checks.split("\n")[66].indexOf("Digital: O2 fills from 7 o'clock, CO2 from 5 o'clock") >= 0, "CHECKS names the digital gauge starts");
expect(log.indexOf("steps come only from the selected quest") >= 0, "the changelog describes the selected-quest tracker");

const bio = funcBody(as, "hz27BioHide");
expect(bio.indexOf("this.hzShowAfflictions && !this.hzUserHidden") >= 0, "the bio popup follows the afflictions card");
expect(bio.indexOf("hzHideVanillaWatch &&") < 0, "the bio popup does not follow the watch style");
const det = funcBody(as, "hz31DetHide");
expect(det.indexOf("this.hzStealthOn || this.hzEnemyBarOn || this.hzEdgePulse") >= 0, "the detection ring follows the combat cues");
expect(det.indexOf("hzHideVanillaWatch") < 0, "the detection ring does not follow the watch style");

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("quest tracker tests passed");
