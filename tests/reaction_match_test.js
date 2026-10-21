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
const PUNCT_DBL = takeRegex("doubled punctuation", /if\((\/\['\\u2019-\]\['\\u2019-\]\/)/);
const PUNCT_END = takeRegex("trailing punctuation", /(\/\['\\u2019-\]\$\/)\.test\(body\)/);

const LBL = stringArray("HZC_RX_LBL");
const COL = numArray("HZC_RX_COL");
const DIR = numArray("HZC_RX_DIR");
const NOT = stringArray("HZC_RX_NOT");
const TITLE = stringArray("HZC_RX_TITLE");

expect(src.indexOf('private static const HZC_BUILD:String = "0.42.0.5";') >= 0, "comms build id is 0.42.0.5");
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

function hzcRxWordOk(w) {
	if (w == null || w.length === 0) return false;
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
	for (let i = 0; i < ws.length; i++) {
		const w = ws[i];
		if (!hzcRxWordOk(w)) return null;
		const key = hzcRxLead(w);
		if (key === "and" || key === "that" || hzcRxVerb(key) >= 0) return null;
		if (i === 0 && NOT.indexOf(key) >= 0) return null;
		if (i === 1 && NOT.indexOf(hzcRxLead(ws[0]) + " " + key) >= 0) return null;
	}
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
	["Dr. Barrett liked that.", 1, "Dr. Barrett"]
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
	"Sam and Sarah liked that"
];
for (let i = 0; i < RX1.length; i++) expectMatch(RX1[i][0], RX1[i][2], RX1[i][1], "RX1 " + RX1[i][0]);
for (let i = 0; i < RX2.length; i++) expectNull(RX2[i], "RX2 " + RX2[i]);

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("reaction match: " + (RX1.length + RX2.length) + " harness cases, all passed");
