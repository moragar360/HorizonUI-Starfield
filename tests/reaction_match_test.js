// Companion reaction matcher for actionscript/comms/hzc_block.as (hzcRxMatch).
// The regex and the category tables are read from that file, so a drift in the
// movie fails here. The name may be any case. The card draws it with the same
// toUpperCase the subtitle speaker and the speaker card already use.
// Run: node tests/reaction_match_test.js
"use strict";

const fs = require("fs");
const path = require("path");

const srcPath = path.join(__dirname, "..", "actionscript", "comms", "hzc_block.as");
const src = fs.readFileSync(srcPath, "utf8");

let failed = 0;
function expect(cond, msg) {
	if (cond) {
		console.log("ok  " + msg);
		return;
	}
	failed++;
	console.error("FAIL " + msg);
}

function stringArray(name) {
	const m = src.match(new RegExp(name + ":Array = \\[([^\\]]*)\\]"));
	if (!m) throw new Error("missing " + name);
	const out = [];
	const re = /"((?:\\.|[^"\\])*)"/g;
	let x;
	while ((x = re.exec(m[1]))) out.push(x[1]);
	return out;
}

function numArray(name) {
	const m = src.match(new RegExp(name + ":Array = \\[([^\\]]*)\\]"));
	if (!m) throw new Error("missing " + name);
	return m[1].split(",").map(function (s) {
		const t = s.trim();
		return t.indexOf("0x") === 0 || t.indexOf("0X") === 0 ? parseInt(t, 16) : Number(t);
	});
}

function takeRegex(label, re) {
	const m = src.match(re);
	if (!m) throw new Error("missing " + label + " in hzc_block.as");
	return new Function("return " + m[1])();
}

const RX = takeRegex(
	"match regex",
	/var m:Object = (\/\^\(\.\+\?\) \(loves\|likes\|dislikes\|hates\|loved\|liked\|disliked\|hated\) that\\\.\?\\s\*\$\/i)\.exec\(s\);/
);
const WORD = takeRegex(
	"word regex",
	/if\(!(\/\^\[A-Za-z\\u00C0-\\u024F\]\[A-Za-z\\u00C0-\\u024F'\\u2019-\]\*\$\/)\.test\(body\)\)/
);
const INITIAL = takeRegex(
	"initial regex",
	/(\/\^\(\?:\[A-Za-z\\u00C0-\\u024F\]\\.\)\+\$\/)\.test\(w\)/
);
const PUNCT_DBL = takeRegex("doubled punctuation", /if\((\/\['\\u2019-\]\['\\u2019-\]\/)/);
const PUNCT_END = takeRegex("trailing punctuation", /(\/\['\\u2019-\]\$\/)\.test\(body\)/);

const LBL = stringArray("HZC_RX_LBL");
const COL = numArray("HZC_RX_COL");
const DIR = numArray("HZC_RX_DIR");
const NOT = stringArray("HZC_RX_NOT");
const TITLE = stringArray("HZC_RX_TITLE");

expect(src.indexOf('private static const HZC_BUILD:String = "0.42.0.7";') >= 0, "comms build id is 0.42.0.7");
expect(src.indexOf("private static const HZC_MSG_LOG:Boolean = true;") >= 0, "comms message log is on for this test build");
expect(src.indexOf('this.hzcRxDbgPush("card code off after error: " + this.hzcRxDbgEsc(em));') >= 0, "a card error records the error text");
expect(src.indexOf('if(s == "loved" || s == "loves") { return 0; }') >= 0, "loves maps with loved");
expect(src.indexOf('if(s == "liked" || s == "likes") { return 1; }') >= 0, "likes maps with liked");
expect(src.indexOf('if(s == "disliked" || s == "dislikes") { return 2; }') >= 0, "dislikes maps with disliked");
expect(src.indexOf('if(s == "hated" || s == "hates") { return 3; }') >= 0, "hates maps with hated");
expect(src.indexOf("this.hzcSet(lb,String(HZC_RX_LBL[e.k])") >= 0, "card text uses the category index");
expect(src.indexOf("uint(HZC_RX_COL[e.k])") >= 0, "card color uses the category index");
expect(src.indexOf("int(HZC_RX_DIR[e.k])") >= 0, "chevrons use the category index");
expect(src.indexOf('this.hzcSet(nm,String(e.n).toUpperCase(),"nm"') >= 0, "card name uses the existing uppercase");
expect(src.indexOf("HZC_RX_PART") < 0, "capital-letter particle exception is gone");
expect(src.indexOf('if(key == "and" || key == "that" || this.hzcRxVerb(key) >= 0) { return null; }') >= 0, "and, that, and a reaction verb are rejected");
expect(src.indexOf("if(!named) { return null; }") >= 0, "a bare title is not a name");
expect(src.indexOf("if(!initial && i == 0 && HZC_RX_NOT.indexOf(key) >= 0)") >= 0, "an initial is not the article or the pronoun");
const LEAD = ["i","you","we","they","he","she","it","your","my","our","their","his","her","nobody","everyone","everybody","someone","somebody","none","all","some","the","a","an","crew","no one","who","not","people","this","that","many","most","each","several","both","what"];
expect(NOT.length === LEAD.length && LEAD.every(function (w) { return NOT.indexOf(w) >= 0; }), "first-word pronoun list");
expect(["dr","mr","mrs","ms","jr","sr","st","lt","capt","sgt","prof"].every(function (w) { return TITLE.indexOf(w) >= 0; }), "title period list");
expect(LBL.join("|") === "LOVED THAT|LIKED THAT|DISLIKED THAT|HATED THAT", "category labels stay past tense");
expect(COL[0] === 0x4FD1B8 && COL[1] === 0x5EE3A1 && COL[2] === 0xF2A93B && COL[3] === 0xFF5B5B, "category colors");
expect(DIR.join(",") === "2,1,-1,-2", "chevron directions");

// The card's normal name style. Subtitle speaker and speaker card use the same call.
function cardName(n) {
	return String(n).toUpperCase();
}

function hzcRxNorm(t) {
	if (t == null) return null;
	let s = t.replace(/[\u00A0\u2007\u202F\u2009\u200A\t]/g, " ").replace(/[\u200B\uFEFF]/g, "");
	s = s.replace(/^[\s]+|[\s]+$/g, "").replace(/ {2,}/g, " ");
	return s;
}

function hzcRxVerb(v) {
	const s = v == null ? "" : String(v).toLowerCase();
	if (s === "loved" || s === "loves") return 0;
	if (s === "liked" || s === "likes") return 1;
	if (s === "disliked" || s === "dislikes") return 2;
	if (s === "hated" || s === "hates") return 3;
	return -1;
}

function hzcRxLead(w) {
	let s = w == null ? "" : String(w).toLowerCase();
	while (s.length > 0 && s.charAt(s.length - 1) === ".") s = s.slice(0, -1);
	return s;
}

function hzcRxInitial(w) {
	return w != null && INITIAL.test(w);
}

function hzcRxWordOk(w) {
	if (w == null || w.length === 0) return false;
	if (hzcRxInitial(w)) return true;
	let body = w;
	if (w.charAt(w.length - 1) === ".") {
		body = w.slice(0, -1);
		if (TITLE.indexOf(body.toLowerCase()) < 0) return false;
	} else if (w.indexOf(".") >= 0) return false;
	if (!WORD.test(body)) return false;
	if (PUNCT_DBL.test(body) || PUNCT_END.test(body)) return false;
	return true;
}

function hzcRxMatch(t) {
	const s = hzcRxNorm(t);
	if (s == null || s.indexOf("\n") >= 0 || s.indexOf("\r") >= 0) return null;
	if (s.length < 11 || s.length > 64) return null;
	const m = RX.exec(s);
	if (m == null) return null;
	const n = String(m[1]);
	if (n.length < 1 || n.length > 40) return null;
	const ws = n.split(" ");
	if (ws.length < 1 || ws.length > 4) return null;
	let named = false;
	for (let i = 0; i < ws.length; i++) {
		const w = ws[i];
		if (!hzcRxWordOk(w)) return null;
		const key = hzcRxLead(w);
		const initial = hzcRxInitial(w);
		if (key === "and" || key === "that" || hzcRxVerb(key) >= 0) return null;
		if (!initial && i === 0 && NOT.indexOf(key) >= 0) return null;
		if (!initial && i === 1 && NOT.indexOf(hzcRxLead(ws[0]) + " " + key) >= 0) return null;
		if (TITLE.indexOf(key) < 0) named = true;
	}
	if (!named) return null;
	const k = hzcRxVerb(String(m[2]));
	if (k < 0) return null;
	return { n: n, k: k, label: LBL[k], color: COL[k], dir: DIR[k], card: cardName(n) };
}

function expectMatch(text, name, k, msg) {
	const r = hzcRxMatch(text);
	const ok = r != null && r.n === name && r.k === k && r.label === LBL[k] && r.color === COL[k] && r.dir === DIR[k]
		&& r.card === cardName(name);
	expect(ok, (msg || text) + (ok ? "" : " -> " + JSON.stringify(r)));
}

function expectNull(text, msg) {
	const r = hzcRxMatch(text);
	expect(r == null, (msg || text) + " stays vanilla" + (r == null ? "" : " -> " + JSON.stringify(r)));
}

expectMatch("Sam likes that", "Sam", 1);
expectMatch("Sam likes that.", "Sam", 1);
expectMatch("Sam likes that.   ", "Sam", 1, "trailing whitespace");
expectMatch("Sam likes that.\n", "Sam", 1, "trailing line break");
expectMatch("Sam LIKES that", "Sam", 1, "verb any case");
expectMatch("Sarah Morgan loved that.", "Sarah Morgan", 0);
expectMatch("Barrett dislikes that", "Barrett", 2);
expectMatch("Andreja hates that.", "Andreja", 3);
expectMatch("SAM COE LIKED THAT", "SAM COE", 1);
expectMatch("SAM COE LIKED THAT.", "SAM COE", 1);
expectMatch("sam coe hated that", "sam coe", 3);
expectMatch("SARAH MORGAN LOVES THAT", "SARAH MORGAN", 0);

expect(hzcRxMatch("SAM COE LIKED THAT").card === "SAM COE", "all-caps name stays the card uppercase");
expect(hzcRxMatch("sam coe hated that").card === "SAM COE", "lowercase name is drawn in the card uppercase");
expect(hzcRxMatch("Sam likes that").card === "SAM", "mixed-case name is drawn in the card uppercase");
expect(hzcRxMatch("sam coe hated that").card !== "sam coe", "raw lowercase is not the card text");

expectMatch("Dr. Barrett liked that", "Dr. Barrett", 1, "period in a name");
expectMatch("Dr. Barrett liked that.", "Dr. Barrett", 1, "period in a name and after that");
expectNull("You really liked that");
expectNull("Nobody else likes that");
expectNull("Your crew liked that.");
expectNull("Sam Coe and Andreja liked that");
expectNull("No one likes that");
expectNull("Sam likes that ship.");
expectNull("Sam likes that ship");
expectNull("SAM COE LIKED THAT SHIP.");
expectNull("Everyone likes that.", "pronoun");
expectNull("EVERYONE LIKED THAT", "pronoun in caps");
expectNull("Sam likes that!", "other punctuation");
expectNull("Sam likes\nthat", "a line break inside");
expectNull("R2 likes that.", "a digit is not a name word");
expectNull("Sam- liked that.", "a hyphen cannot end a word");
expectNull("Anna Beth Cara Dana Eve liked that", "five name words");

expectMatch("O'Neill likes that", "O'Neill", 1, "apostrophe inside a word");
expectMatch("Anne-Marie liked that.", "Anne-Marie", 1, "hyphen inside a word");
expectMatch("Sam Coe liked that.", "Sam Coe", 1, "two-word mixed case");

const pairs = [
	["loves", "loved", 0, "LOVED THAT", 0x4fd1b8, 2],
	["likes", "liked", 1, "LIKED THAT", 0x5ee3a1, 1],
	["dislikes", "disliked", 2, "DISLIKED THAT", 0xf2a93b, -1],
	["hates", "hated", 3, "HATED THAT", 0xff5b5b, -2]
];
for (let i = 0; i < pairs.length; i++) {
	const present = hzcRxMatch("Sam " + pairs[i][0] + " that");
	const past = hzcRxMatch("SAM " + pairs[i][1].toUpperCase() + " THAT.");
	const same = present && past && present.k === past.k && present.k === pairs[i][2]
		&& present.label === past.label && present.label === pairs[i][3]
		&& present.color === past.color && present.color === pairs[i][4]
		&& present.dir === past.dir && present.dir === pairs[i][5]
		&& present.card === "SAM" && past.card === "SAM";
	expect(same, pairs[i][0] + " uses the same card as " + pairs[i][1]);
}

// Main Worker harness (new_04205rx.js): RX1 must match, RX2 must stay vanilla, and the SF-2 lines must not match.
const RX1 = [
	["Sam likes that", 1, "Sam"],
	["Sarah liked that.", 1, "Sarah"],
	["Sam LOVES that", 0, "Sam"],
	["Andreja dislikes that", 2, "Andreja"],
	["Vasco hates that", 3, "Vasco"],
	["SAM COE LIKED THAT", 1, "SAM COE"],
	["Sam Coe loved that.", 0, "Sam Coe"],
	["Barrett hated that.", 3, "Barrett"],
	["Sam likes that  ", 1, "Sam"],
	["Dr. Barrett liked that.", 1, "Dr. Barrett"],
	["J.T. Kirk liked that", 1, "J.T. Kirk"],
	["J. T. Kirk liked that.", 1, "J. T. Kirk"],
	["R. Kim likes that", 1, "R. Kim"],
	["A. Kim liked that", 1, "A. Kim"],
	["St. John liked that", 1, "St. John"]
];
const RX2 = [
	"Sam likes that ship",
	"Sam likes that ship.",
	"Sam liked that!",
	"Sam liked: that.",
	"Objective: Talk to Sam Coe",
	"Quest Completed: Into the Unknown",
	"Sam Coe likes your ship",
	"Everyone liked that.",
	"Someone liked that",
	"Sam likes this",
	"Sam liked that.\nSarah liked that.",
	"Discovered: Sam liked that",
	"\"Sam\" liked that.",
	"Sam (Constellation) liked that.",
	"Location discovered: The Lodge",
	"Sam liked that. Sarah hated that.",
	"Okay. Sam liked that.",
	"Quest done. Sam liked that.",
	"Who liked that",
	"Not everyone liked that",
	"Bounty paid. Sam likes that",
	"People liked that",
	"This liked that",
	"That liked that",
	"Many liked that",
	"Most liked that",
	"Each liked that",
	"Several liked that",
	"Both liked that",
	"What liked that",
	"Your crew liked that",
	"No one liked that",
	"My ship liked that",
	"Some people liked that",
	"Sam and Sarah liked that",
	"Mr. liked that",
	"Dr. liked that.",
	"Mrs. likes that",
	"Ms. liked that",
	"Jr. liked that",
	"Sr. liked that",
	"St. liked that",
	"Lt. liked that",
	"Capt. liked that",
	"Sgt. liked that",
	"Prof. hated that",
	"A liked that",
	"I liked that"
];
for (let i = 0; i < RX1.length; i++) expectMatch(RX1[i][0], RX1[i][2], RX1[i][1], "RX1 " + RX1[i][0]);
for (let i = 0; i < RX2.length; i++) expectNull(RX2[i], "RX2 " + RX2[i]);

expect(src.indexOf('BSUIDataManager.Subscribe("HUDMessageData",this.hzcRxOnMsg);') >= 0, "the movie subscribes to HUDMessageData");
expect(src.indexOf("if(this.hzcRxSkip) { this.hzcRxSkip = false; return; }") >= 0, "the subscribe replay is ignored");
expect(src.indexOf("this.hzcRxOffer(raw);") >= 0, "a new message is matched from the unchanged text");
expect(src.indexOf("public function hzcRxPush(text:String) : String") >= 0, "the DLL backup calls hzcRxPush");
expect(src.indexOf('return "queued";') >= 0, "a match returns queued");
expect(src.indexOf('return "no match";') >= 0, "a non-reaction returns no match");
expect(src.indexOf('return "cards off: settings not loaded";') >= 0, "cards off names settings");
expect(src.indexOf('return "cards off: ReactionCard is off";') >= 0, "cards off names the toggle");
expect(src.indexOf('return "cards off: message column missing";') >= 0, "cards off names a missing column");
expect(src.indexOf('return "off after error: " + this.hzcRxOne(this.hzcRxErr);') >= 0, "a latched error returns the exception text");
expect(src.indexOf("if(this.hzcRxFail >= 3) { this.hzcRxLatch(); return; }") >= 0, "one place error does not turn the card off");
expect(src.indexOf("HZC_RX_DUP") < 0, "identical reactions are not collapsed inside a time window");
expect(src.indexOf("private static const HZC_RX_VIS:int = 4000;") >= 0, "visible time is not a 30 s wall clock");
expect(src.indexOf("if(slot) { e0.vis = int(e0.vis) + dt; }") >= 0, "time counts only while the message slot is visible");
expect(src.indexOf("if(int(e0.vis) >= HZC_RX_VIS)") >= 0, "an unlinked card ends on visible time");
expect(src.indexOf("30000") < 0, "the reaction movie has no 30 s wall clock");
expect(src.indexOf("public function hzcRxWhy() : String") >= 0, "cards-off is reported once per reason");
expect(src.indexOf("catch(eSub:Error) { this.hzcRxSub = false; }\n         this.hzcRxSkip = false;") >= 0, "the skip flag clears when Subscribe returns");
expect(src.indexOf("private static const HZC_RX_PAIR:int = 3000;") >= 0, "the two paths pair inside 3 s");
expect(src.indexOf("private static const HZC_RX_COOL:int = 5000;") >= 0, "a miss latch rearms after 5 s");
expect(src.indexOf('if(age >= 0 && age < HZC_RX_PAIR) { e0.paired = true; e0.src = "both"; return "queued"; }') >= 0, "pairing keeps the oldest card");
expect(src.indexOf('try { return this.hzcRxOffer(text == null ? "" : String(text),true); }') >= 0, "the DLL path offers through the same queue");
expect(src.indexOf("if(e0.linked == true)") >= 0, "a linked card follows its line");
expect(src.indexOf("if(!inList) { this.hzcRxShow(e0); this.hzcRxRemember(e0); this.hzcRxDrop(e0); continue; }") >= 0, "a linked card ends when its line leaves");
expect(src.indexOf("e0.it = null") < 0, "a finished line does not fall back to a standalone card");
expect(src.indexOf("if(e.linked == true) { e.c.visible = false; return; }") >= 0, "a linked card stays hidden when it cannot sit on its line");
expect(src.indexOf("private function hzcRxRearm() : void") >= 0, "a settings reload rearms the card");
expect(src.indexOf("if(woke >= uint(HZC_RX_COOL) && woke <= uint(2147483647)) { this.hzcRxRearm(); }") >= 0, "the cooldown rearms across a timer wrap");
expect(src.indexOf("woke < 120000") < 0, "a long pause still rearms");
expect(src.indexOf("private static const HZC_RX_STEP:int = 3;") >= 0, "three consecutive step throws turn the card off");
expect(src.indexOf("if(this.hzcRxStepN >= HZC_RX_STEP) { this.hzcRxLatch(); }") >= 0, "the step-throw cutoff calls the off switch");
expect(src.indexOf("private function hzcRxUnhide() : void") >= 0, "turning the card off restores vanilla lines");
expect(src.indexOf("hzcRxStepBad") < 0, "a repeating step throw is not counted only once");
expect(src.indexOf("if(fromDll && this.hzcRxPairGone(key, now)) { return \"queued\"; }") >= 0, "a late DLL note pairs with an ended card");
expect(src.indexOf("e.paired == true || e.src != \"b\"") >= 0, "only an unpaired binding card leaves a pair slot");
expect(src.indexOf("if(e.blamed != true) { e.blamed = true; e.judged = true; this.hzcRxHit(err); }") >= 0, "one message counts one miss");
expect(src.indexOf("if(e.judged != true) { e.judged = true; drew = true; }") >= 0, "the first successful place of a message clears the streak");
expect(src.indexOf("if(drew) { this.hzcRxFail = 0; }") >= 0, "a later success clears the miss streak");

function constInt(name) {
	const m = src.match(new RegExp("private static const " + name + ":int = (\\d+);"));
	if (!m) throw new Error("missing " + name);
	return Number(m[1]);
}
const PAIR = constInt("HZC_RX_PAIR");
const VIS = constInt("HZC_RX_VIS");
const COOL = constInt("HZC_RX_COOL");
expect(PAIR === 3000 && VIS === 4000 && COOL === 5000, "pair, visible, and cooldown windows");

// Keep loop from hzcRxStep. A linked card drops when its item leaves. Visible time applies only when it never linked.
function rxKeep(entries, present, slot, dt) {
	const out = [];
	for (let i = 0; i < entries.length; i++) {
		const e0 = entries[i];
		if (e0 == null || e0.st !== 1) continue;
		if (e0.linked === true) {
			const inList = e0.it != null && present.indexOf(e0.it) >= 0;
			if (!inList) continue;
		} else {
			if (slot) e0.vis = (e0.vis | 0) + dt;
			if ((e0.vis | 0) >= VIS) continue;
		}
		out.push(e0);
	}
	return out;
}
function rxPlace(e, placed) {
	if (placed) return "beside";
	if (e.linked === true) return "hidden";
	return "anchor";
}
{
	const line = 1;
	let cur = [{ st: 1, linked: true, it: line, vis: 0 }];
	for (let i = 0; i < 23; i++) cur = rxKeep(cur, [line], true, 100);
	expect(cur.length === 1, "a linked card is still up at about 2.3 s while its line is shown");
	cur = rxKeep(cur, [], true, 16);
	expect(cur.length === 0, "a linked card ends when its line leaves at about 2.3 s");
	cur = rxKeep(cur, [], true, 100);
	expect(cur.length === 0 && rxPlace({ linked: true }, false) === "hidden", "a linked card does not pop back as a standalone card");
	let held = [{ st: 1, linked: true, it: line, vis: 0 }];
	for (let i = 0; i < 60; i++) held = rxKeep(held, [line], true, 100);
	expect(held.length === 1, "a line held past 4 s keeps its card");
	let loose = [{ st: 1, linked: false, it: null, vis: 0 }];
	for (let i = 0; i < 39; i++) loose = rxKeep(loose, [], true, 100);
	expect(loose.length === 1 && loose[0].vis === 3900, "an unlinked card is still up just before 4 s");
	loose = rxKeep(loose, [], true, 100);
	expect(loose.length === 0, "an unlinked card ends at 4 s of visible time");
	const hidden = rxKeep([{ st: 1, linked: false, it: null, vis: 0 }], [], false, 5000);
	expect(hidden.length === 1 && hidden[0].vis === 0, "a hidden message slot does not age an unlinked card");
}

// FIFO: opposite sources of the same text pair in order. N reactions stay N cards.
function rxRemember(gone, e) {
	if (!e || e.linked !== true || e.paired === true || e.src !== "b" || e.key == null) return;
	gone.push({ key: e.key, t0: e.t0 | 0 });
	if (gone.length > 8) gone.shift();
}
function rxOffer(q, text, fromDll, now, gone) {
	const key = String(text).toLowerCase();
	const want = fromDll ? "b" : "d";
	for (let i = 0; i < q.length; i++) {
		const e0 = q[i];
		if (e0 == null || e0.key !== key || e0.paired === true || e0.src !== want) continue;
		const age = now - e0.t0;
		if (age >= 0 && age < PAIR) { e0.paired = true; e0.src = "both"; return "queued"; }
	}
	if (fromDll && gone) {
		const keep = [];
		let ate = false;
		for (let gi = 0; gi < gone.length; gi++) {
			const g0 = gone[gi];
			const gage = now - (g0.t0 | 0);
			if (gage < 0 || gage >= PAIR) continue;
			if (!ate && g0.key === key) { ate = true; continue; }
			keep.push(g0);
		}
		gone.length = 0;
		for (let ki = 0; ki < keep.length; ki++) gone.push(keep[ki]);
		if (ate) return "queued";
	}
	const srcName = fromDll ? "d" : "b";
	q.push({ key: key, t0: now, src: srcName, paired: false, it: null });
	if (q.length > 8) q.shift();
	return "queued";
}
{
	const line = "Sam Coe liked that.";
	const q = [];
	for (let i = 0; i < 4; i++) rxOffer(q, line, false, i * 10);
	expect(q.length === 4 && q.every(function (e) { return e.src === "b" && e.paired === false; }), "four binding notes are four cards");
	for (let i = 0; i < 4; i++) rxOffer(q, line, true, 100 + i * 10);
	expect(q.length === 4 && q.every(function (e) { return e.src === "both" && e.paired === true; }), "four DLL notes pair onto those four cards");
	const rev = [];
	for (let i = 0; i < 3; i++) rxOffer(rev, line, true, i * 20);
	for (let i = 0; i < 3; i++) rxOffer(rev, line, false, 80 + i * 20);
	expect(rev.length === 3 && rev.every(function (e) { return e.paired === true; }), "DLL notes then binding notes still pair one to one");
	const only = [];
	rxOffer(only, line, false, 0);
	rxOffer(only, line, false, 10);
	expect(only.length === 2, "binding-only reactions are not collapsed");
	const late = [];
	rxOffer(late, line, false, 0);
	rxOffer(late, line, true, PAIR);
	expect(late.length === 2 && late[0].paired === false, "a DLL note older than 3 s does not pair");
	const other = [];
	rxOffer(other, "Sam Coe liked that.", false, 0);
	rxOffer(other, "Sarah Morgan hated that.", true, 10);
	expect(other.length === 2, "different lines do not pair");
	const order = [];
	rxOffer(order, line, false, 0);
	rxOffer(order, line, false, 10);
	rxOffer(order, line, true, 20);
	expect(order[0].paired === true && order[1].paired === false, "pairing takes the oldest unpaired note");
	const ended = { key: line.toLowerCase(), t0: 0, linked: true, src: "b", paired: false };
	const gone = [];
	rxRemember(gone, ended);
	const lateCard = [];
	expect(rxOffer(lateCard, line, true, 2500, gone) === "queued" && lateCard.length === 0 && gone.length === 0, "a DLL note 2.5 s after a short line adds no second card");
	const edgeGone = [];
	rxRemember(edgeGone, ended);
	const edgeCard = [];
	rxOffer(edgeCard, line, true, PAIR, edgeGone);
	expect(edgeCard.length === 1, "a DLL note at 3 s does not pair with the ended card");
	const pairedGone = [];
	rxRemember(pairedGone, { key: line.toLowerCase(), t0: 0, linked: true, src: "both", paired: true });
	const second = [];
	rxOffer(second, line, true, 2500, pairedGone);
	expect(pairedGone.length === 0 && second.length === 1, "an already paired line does not swallow the next DLL note");
	const two = [];
	rxRemember(two, ended);
	rxRemember(two, { key: line.toLowerCase(), t0: 20, linked: true, src: "b", paired: false });
	const none = [];
	rxOffer(none, line, true, 2400, two);
	rxOffer(none, line, true, 2500, two);
	expect(none.length === 0 && two.length === 0, "two ended lines take two late DLL notes in order");
	const bindGone = [];
	rxRemember(bindGone, ended);
	const bindCard = [];
	rxOffer(bindCard, line, false, 2500, bindGone);
	expect(bindCard.length === 1 && bindGone.length === 1, "a new binding note is not consumed by an ended line");
}

// Misses are one per message. A healthy card that already drew does not clear the streak every frame.
function rxPlaces(entries, state) {
	let drew = false;
	for (let i = 0; i < entries.length; i++) {
		const e = entries[i];
		if (e.bad) {
			if (e.blamed !== true) { e.blamed = true; e.judged = true; state.fail++; }
		} else if (e.judged !== true) { e.judged = true; drew = true; }
	}
	if (drew) state.fail = 0;
	if (state.fail >= 3) { state.off = true; state.offAt = state.now; }
}
function wokeOf(now, offAt) {
	return ((now >>> 0) - (offAt >>> 0)) >>> 0;
}
function rxCool(now, offAt) {
	const woke = wokeOf(now, offAt);
	return woke >= COOL && woke <= 2147483647;
}
function rxRearm(state) {
	state.off = false;
	state.offAt = 0;
	state.fail = 0;
	state.stepN = 0;
}
function rxFrame(state, now, stepThrows) {
	state.now = now;
	if (state.off) {
		if (rxCool(now, state.offAt)) rxRearm(state);
		else return;
	}
	if (stepThrows) {
		state.stepN = (state.stepN | 0) + 1;
		if (state.stepN === 1) state.fail++;
		if (state.stepN >= 3) { state.off = true; state.offAt = now; state.restored = true; }
	} else state.stepN = 0;
}
{
	const one = { bad: true, blamed: false, judged: false };
	const state = { fail: 0, off: false, offAt: 0, now: 0, stepBad: false };
	rxPlaces([one], state);
	rxPlaces([one], state);
	rxPlaces([one], state);
	expect(state.fail === 1 && state.off === false, "one bad message counts once across frames");
	const three = { fail: 0, off: false, offAt: 0, now: 0 };
	rxPlaces([{ bad: true }, { bad: true }, { bad: true }], three);
	expect(three.fail === 3 && three.off === true, "three new message misses turn the card off");
	const healed = { fail: 2, off: false, offAt: 0, now: 0 };
	rxPlaces([{ bad: false, judged: false }], healed);
	expect(healed.fail === 0 && healed.off === false, "the first success of a message clears the streak");
	const steady = { fail: 2, off: false, offAt: 0, now: 0 };
	rxPlaces([{ bad: false, judged: true }], steady);
	expect(steady.fail === 2, "a card that already drew does not clear the streak every frame");
	rxRearm(three);
	expect(three.off === false && three.fail === 0, "a settings reload rearms a latched card");
	const cool = { fail: 3, off: true, offAt: 1000, now: 1000, stepN: 0 };
	rxFrame(cool, 1000 + COOL - 1, false);
	expect(cool.off === true, "the latch holds through 4999 ms");
	rxFrame(cool, 1000 + COOL, false);
	expect(cool.off === false && cool.fail === 0, "the latch clears after 5 s");
	const back = { fail: 3, off: true, offAt: 5000, now: 5000, stepN: 0 };
	rxFrame(back, 4000, false);
	expect(back.off === true && rxCool(4000, 5000) === false, "a clock step backward does not rearm");
	const long = { fail: 3, off: true, offAt: 1000, now: 1000, stepN: 0 };
	rxFrame(long, 1000 + 130000, false);
	expect(long.off === false, "a pause longer than 120 s still rearms");
	const wrapAt = 2147483000;
	const wrapNow = (wrapAt + 6000) | 0;
	expect(rxCool(wrapNow, wrapAt) === true, "a timer wrap of 6 s rearms");
	expect(rxCool((wrapAt + 1000) | 0, wrapAt) === false, "a timer wrap under 5 s stays latched");
	const stuck = { fail: 0, off: false, offAt: 0, now: 0, stepN: 0, restored: false };
	rxFrame(stuck, 0, true);
	rxFrame(stuck, 16, true);
	expect(stuck.fail === 1 && stuck.off === false, "two step throws stay on");
	rxFrame(stuck, 32, true);
	expect(stuck.off === true && stuck.restored === true, "three consecutive step throws turn the card off and restore vanilla");
	const gap = { fail: 0, off: false, offAt: 0, now: 0, stepN: 0, restored: false };
	rxFrame(gap, 0, true);
	rxFrame(gap, 16, true);
	rxFrame(gap, 32, false);
	rxFrame(gap, 48, true);
	rxFrame(gap, 64, true);
	expect(gap.off === false, "a successful frame resets the step-throw count");
	rxFrame(gap, 80, true);
	expect(gap.off === true && gap.restored === true, "the count reaches three again after a reset");
}

const msgTwins = [
	["actionscript/imp/imp/scripts/HUDMessagesMenu.as", false],
	["actionscript/imp/imp-Lrg/scripts/HUDMessagesMenu.as", true],
];
const msgStart = "// ===================== Horizon UI Comms (HUD Messages) v0.42.0 =====================";
const msgEnd = "// =================== end Horizon UI Comms (HUD Messages) v0.35 ===================";
function msgSpan(text) {
	const a = text.indexOf(msgStart);
	const b = text.indexOf(msgEnd);
	expect(a >= 0 && b > a, "HUD messages block markers");
	return text.slice(a, b);
}
const msgBlock = msgSpan(src);
for (let i = 0; i < msgTwins.length; i++) {
	const rel = msgTwins[i][0];
	const lrg = msgTwins[i][1];
	const buf = fs.readFileSync(path.join(__dirname, "..", rel));
	const stripped = buf.toString("binary").replace(/\r\n/g, "");
	expect(buf.includes(Buffer.from("\r\n")) && !stripped.includes("\n") && !stripped.includes("\r"), rel + " stays CRLF");
	const body = buf.toString("utf8").replace(/\r\n/g, "\n");
	let expectSpan = msgBlock;
	expectSpan = expectSpan.replace("private static const HZC_LRG:Boolean = __HZC_LRG__;", "private static const HZC_LRG:Boolean = " + (lrg ? "true" : "false") + ";");
	expect(msgSpan(body) === expectSpan, rel + " matches the comms block");
	expect(body.indexOf("public function hzcRxPush(text:String) : String") >= 0, rel + " defines hzcRxPush");
}

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("reaction match: " + (RX1.length + RX2.length) + " matcher cases, plus lifetime, pairing, and miss harnesses, all passed");
