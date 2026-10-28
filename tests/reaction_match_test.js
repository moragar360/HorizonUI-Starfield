// Companion reaction matcher for actionscript/comms/hzc_block.as (hzcRxMatch).
// The category tables are read from that file. The name test is the same char-code
// loop as the movie, because a unicode escape in a regex is not safe in Scaleform.
// The name may be any case. The card draws it with the same
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

const LBL = stringArray("HZC_RX_LBL");
const COL = numArray("HZC_RX_COL");
const DIR = numArray("HZC_RX_DIR");
const NOT = stringArray("HZC_RX_NOT");
const TITLE = stringArray("HZC_RX_TITLE");

expect(src.indexOf('private static const HZC_BUILD:String = "0.43.0.4";') >= 0, "comms build id is 0.43.0.4");
expect(src.indexOf('HudMessagesX') >= 0 && src.indexOf("function hzcMsgLayout") >= 0, "HUD Messages box reads a saved layout");
expect(src.indexOf("x = Math.max(vr.x,Math.min(vr.right - w,x));") >= 0, "HUD Messages box is clamped on screen");
expect(src.indexOf("y = Math.max(vr.y,Math.min(vr.bottom - h,y));") >= 0, "HUD Messages box is clamped vertically");
expect(src.indexOf("hud messages home:") >= 0, "HUD Messages home is logged for the in-game check");
expect(src.indexOf("Home is the stable visible-rect default") >= 0, "HUD Messages home is not the live line bounds");
expect(src.indexOf('if(sub == "kid") { return "KID STUFF"; }') >= 0, "Kid Stuff title is KID STUFF");
expect(src.indexOf("SENT HOME") < 0, "SENT HOME is not a card title");
expect(src.indexOf('if(sub == "bounty") { return "BOUNTY PAID"; }') >= 0, "bounty paid title is BOUNTY PAID");
expect(src.indexOf('if(sub == "bounty-add") { return "BOUNTY"; }') >= 0, "bounty added title is BOUNTY");
expect(src.indexOf('if(sub == "gain" || sub == "bounty-add")') < 0, "bounty added is not a green credits gain");
expect(src.indexOf('if(sub == "gain") { return HZC_GRN; }') >= 0, "only credit gains are green");
expect(src.indexOf('sub == "alarm" || sub == "bounty-add"') >= 0, "bounty added uses the red crime tone");
expect(src.indexOf('crew card: path=hzcCardDraw') >= 0, "crew cards log the movie draw path");
expect(src.indexOf("private static const HZC_MSG_LOG:Boolean = false;") >= 0, "comms message log is off for this release");
expect(src.indexOf("private var hzcRxDbgOn:Boolean = false;") >= 0, "movie debug default is off for this release");
expect(src.indexOf("private function hzcCardMatch(kind:String, sub:String, name:String, value:String)") >= 0, "movie matcher takes a DLL payload");
expect(src.indexOf("private function hzcRxClaim(arr:*, key:String)") >= 0, "a later clip with the same text can keep the card");
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

function hzcRxLetter(c) {
	return (c >= 65 && c <= 90) || (c >= 97 && c <= 122) || (c >= 0xC0 && c <= 0x24F);
}
function hzcRxMark(c) {
	return c === 0x27 || c === 0x2019 || c === 0x2D;
}
function hzcRxTrimC(c) {
	return c === 9 || c === 10 || c === 11 || c === 12 || c === 13 || c === 32;
}
function hzcRxNorm(t) {
	if (t == null) return null;
	let raw = "";
	for (let i = 0; i < t.length; i++) {
		const c = t.charCodeAt(i);
		if (c === 0x200B || c === 0xFEFF) continue;
		if (c === 9 || c === 0xA0 || c === 0x2007 || c === 0x202F || c === 0x2009 || c === 0x200A) raw += " ";
		else raw += t.charAt(i);
	}
	let a = 0;
	let b = raw.length;
	while (a < b && hzcRxTrimC(raw.charCodeAt(a))) a++;
	while (b > a && hzcRxTrimC(raw.charCodeAt(b - 1))) b--;
	let o = "";
	let spc = false;
	for (let i = a; i < b; i++) {
		if (raw.charCodeAt(i) === 32) {
			if (!spc) { o += " "; spc = true; }
		} else { o += raw.charAt(i); spc = false; }
	}
	return o;
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
	if (w == null) return false;
	const n = w.length;
	if (n < 2 || (n & 1) !== 0) return false;
	for (let i = 0; i < n; i += 2) {
		if (!hzcRxLetter(w.charCodeAt(i)) || w.charCodeAt(i + 1) !== 46) return false;
	}
	return true;
}

function hzcRxWordOk(w) {
	if (w == null || w.length === 0) return false;
	if (hzcRxInitial(w)) return true;
	let body = w;
	if (w.charCodeAt(w.length - 1) === 46) {
		body = w.slice(0, -1);
		if (TITLE.indexOf(body.toLowerCase()) < 0) return false;
	} else if (w.indexOf(".") >= 0) return false;
	if (body == null || body.length === 0 || !hzcRxLetter(body.charCodeAt(0))) return false;
	let prevMark = false;
	for (let i = 1; i < body.length; i++) {
		const c = body.charCodeAt(i);
		if (hzcRxMark(c)) {
			if (prevMark) return false;
			prevMark = true;
		} else if (hzcRxLetter(c)) prevMark = false;
		else return false;
	}
	return !prevMark;
}

function hzcRxTail(s, tail) {
	if (s == null || tail == null || s.length < tail.length) return false;
	return s.substring(s.length - tail.length).toLowerCase() === tail;
}

function hzcRxMatch(t) {
	const s = hzcRxNorm(t);
	if (s == null || s.indexOf("\n") >= 0 || s.indexOf("\r") >= 0) return null;
	if (s.length < 11 || s.length > 64) return null;
	let cut = 0;
	if (hzcRxTail(s, " that.")) cut = 6;
	else if (hzcRxTail(s, " that")) cut = 5;
	else return null;
	const head = s.substring(0, s.length - cut);
	let sp = -1;
	for (let j = head.length - 1; j >= 0; j--) {
		if (head.charCodeAt(j) === 32) { sp = j; break; }
	}
	if (sp <= 0) return null;
	const verb = head.substring(sp + 1);
	const n = head.substring(0, sp);
	const k = hzcRxVerb(verb);
	if (k < 0 || n.length < 1 || n.length > 40) return null;
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
expectMatch("O\u2019Neill likes that", "O\u2019Neill", 1, "curly apostrophe");
expectMatch("Jos\u00e9 likes that", "Jos\u00e9", 1, "accented name");
expectMatch("Sam\u00A0Coe liked that.", "Sam Coe", 1, "no-break space");
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
expect(src.indexOf("this.hzcRxOffer(raw);") < 0, "the binding does not classify the line");
expect(src.indexOf("public function hzcCardPush(kind:String, sub:String, name:String, value:String, raw:String) : String") >= 0, "the DLL pushes kind, subtype, name, value, and the raw text");
expect(src.indexOf("Internal_mc.alpha =") < 0, "the movie never writes Internal_mc.alpha");
expect(src.indexOf("Text_tf.visible = false") >= 0, "a drawn card hides the game text");
expect(src.indexOf("Background_mc.visible = false") >= 0, "a drawn card hides the game background");
expect(src.indexOf("Number(it.alpha) * Number(im.alpha) * Number(m.alpha)") >= 0, "the card fades with the inner clip");
expect(src.indexOf("e.covered == true") >= 0, "only a covered line is restored");
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
expect(src.indexOf("var nxt:* = this.hzcRxClaim(arr,e0.key);") >= 0, "a later clip with the same text can keep the card");
expect(src.indexOf("else { this.hzcRxShow(e0); this.hzcRxRemember(e0); this.hzcRxDrop(e0); continue; }") >= 0, "a linked card ends when its line leaves");
expect(src.indexOf("e0.it = null") < 0, "a finished line does not fall back to a standalone card");
expect(src.indexOf("if(e.linked == true) { this.hzcRxShow(e); return; }") >= 0, "a linked card that cannot sit restores only a covered line");
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
expect(src.indexOf("private function hzcRxLetter(c:int)") >= 0, "names use char codes");
expect(src.indexOf("c >= 0xC0 && c <= 0x24F") >= 0, "the Latin range is a char-code test");
expect(src.indexOf("c == 0x2019") >= 0, "the curly apostrophe is a char code");
expect(src.indexOf("public function hzcRxSelfTest() : String") >= 0, "the movie exposes the startup self-test");
expect(src.indexOf("/\\u0041/.test(\"A\")") >= 0, "the literal unicode probe is in the self-test");
expect(src.indexOf("new RegExp(\"\\\\u0041\")") >= 0, "the constructed unicode probe is in the self-test");
expect(src.indexOf("/\\x41/.test(\"A\")") >= 0, "the hex probe is in the self-test");
expect(src.indexOf("\\u00C0") < 0, "the name class no longer uses a unicode escape");
expect(src.indexOf("loves|likes") < 0, "the sentence match is not a regex");
{
	const cpp = fs.readFileSync(path.join(__dirname, "..", "src", "main.cpp"), "utf8");
	const poll = cpp.indexOf("void CommsRxPoll");
	const invoke = cpp.indexOf('Invoke("hzcRxSelfTest"', poll);
	const gate = cpp.indexOf("#if HZ_COMMS_MSG_LOG", poll);
	expect(poll >= 0 && invoke > poll && cpp.indexOf("comms reaction selftest:", poll) > poll, "the DLL logs the reaction self-test");
	expect(gate > invoke, "the self-test call sits before the verbose-trace ifdef");
	const clipFn = cpp.indexOf("void ScopeClipPoll");
	const clipEnd = cpp.indexOf("void Poll()", clipFn);
	const clipBody = clipFn >= 0 && clipEnd > clipFn ? cpp.slice(clipFn, clipEnd) : "";
	expect(clipBody.indexOf('Invoke("hzpClipDiag"') >= 0 && clipBody.indexOf("#if") < 0, "the hold-breath diag is outside the verbose ifdef");
	expect(clipBody.indexOf("scope holdbreath diag:") >= 0, "the DLL logs the hold-breath diag");
	const clipDbg = clipBody.indexOf("if (!g_iniDebug) return;");
	expect(clipDbg >= 0 && clipDbg < clipBody.indexOf('Invoke("hzpClipDiag"') && clipDbg < clipBody.indexOf("a_now < g_hzpClipNext"), "hold-breath diag stays off unless Debug=1");
	expect(clipBody.indexOf("g_hzpClipLogged = true") > clipDbg, "Debug off does not latch the hold-breath diag");
	expect(clipBody.indexOf("a_now < g_hzpClipNext") >= 0, "the hold-breath diag does not run every frame");
	expect(clipBody.indexOf("g_hzpClipNext = a_now + 500") >= 0, "the hold-breath diag waits 500 ms");
	const clipCall = cpp.indexOf("ScopeClipPoll(now);");
	const clipSafe = cpp.indexOf("if (!HudSafe())", clipCall);
	expect(clipCall > 0 && clipSafe > clipCall, "the hold-breath diag runs while a scope is open");
	expect(cpp.indexOf("ScopeClipPoll();") < 0, "the hold-breath diag takes the poll time");
}

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

function fnBody(name, next) {
	const a = src.indexOf(name);
	const b = src.indexOf(next, a + name.length);
	expect(a >= 0 && b > a, name + " is present");
	return a >= 0 && b > a ? src.slice(a, b) : "";
}
{
	const push = fnBody("public function hzcCardPush", "public function hzcRxWhy");
	expect(push.indexOf("e0.paired = true") < 0, "a repeated DLL card is not swallowed");
	expect(push.indexOf("this.hzcRxShow(old)") >= 0, "overflow restores the dropped DLL card");
	const step = fnBody("private function hzcRxStep", "private function hzcRxStack");
	expect(step.indexOf("this.hzcRxReveal(e0.it)") >= 0, "rebind uncovers the old clip first");
	expect(step.indexOf("e0.rebound = true") >= 0, "rebind marks the card so a late push can merge");
	const draw = fnBody("private function hzcCardDraw", "private function hzcRxDraw");
	expect(draw.indexOf("this.hzcCardMatch(kind,sub,name,value)") >= 0, "card draw uses the live matcher");
	expect(draw.indexOf("this.hzcCardTone(kind,sub)") < 0, "draw does not call tone directly");
	expect(draw.indexOf("this.hzcCardTitle(kind,sub,name)") < 0, "draw does not call title directly");
	const offer = fnBody("private function hzcRxOffer", "private function hzcRxRemember");
	expect(offer.indexOf('e0.paired = true; e0.src = "both"; return "queued";') >= 0, "the backup path still pairs");
	expect(offer.indexOf("this.hzcRxShow(old)") >= 0, "backup overflow restores the dropped card");
	const link = fnBody("private function hzcRxLink", "private function hzcRxSlot");
	expect(link.indexOf("hzcRxReveal") < 0 && link.indexOf("Internal_mc") < 0, "an unclassified line is not rewritten");
	const unhide = fnBody("private function hzcRxUnhide", "private function hzcRxHit");
	expect(unhide.indexOf("ShownMessageArray") < 0, "turning cards off does not rewrite every line");
	const zed = fnBody("private function hzcCardZ", "private function hzcCardTone");
	expect(zed.indexOf("ScreenHeight") < 0, "card size does not scale by screen height");
	expect(zed.indexOf("TextScale") >= 0 && zed.indexOf("HudScale") >= 0 && zed.indexOf("HZC_LRG") >= 0, "text, HUD, and large scale still apply");
	const tone = fnBody("private function hzcCardTone", "private function hzcCardPhrase");
	let redLine = "";
	let ambLine = "";
	const toneLines = tone.split("\n");
	for (let i = 0; i < toneLines.length; i++) {
		if (toneLines[i].indexOf("return HZC_RED") >= 0 && toneLines[i].indexOf("sub ==") >= 0) redLine = toneLines[i];
		if (toneLines[i].indexOf("return HZC_CARD_AMB") >= 0) ambLine = toneLines[i];
	}
	expect(redLine.indexOf('"angry"') < 0 && ambLine.indexOf('"angry"') >= 0, "angry is amber");
	expect(ambLine.indexOf('"calmed"') < 0 && tone.indexOf("return -1") >= 0, "calmed uses the accent");
	expect(tone.indexOf('sub == "calm"') >= 0 && tone.indexOf("return HZC_GRN") >= 0, "calm stays green");
	expect(redLine.indexOf('"furious"') >= 0 && redLine.indexOf('"caught"') >= 0, "furious and caught stay red");
	expect(src.indexOf("private function hzcRxStack()") >= 0 && src.indexOf("var gap:Number = 8;") >= 0, "stacked cards keep a gap");
}

// HC-2: the fade model is a copy. These pins read the movie, including a split name and a helper the model never runs.
function stripMovieComments(s) {
	let out = "";
	let i = 0;
	let q = "";
	while (i < s.length) {
		const c = s[i];
		if (q) {
			out += c;
			if (c === "\\") { out += s[i + 1] || ""; i += 2; continue; }
			if (c === q) q = "";
			i++;
			continue;
		}
		if (c === '"' || c === "'") { q = c; out += c; i++; continue; }
		if (c === "/" && s[i + 1] === "/") { while (i < s.length && s[i] !== "\n") i++; continue; }
		if (c === "/" && s[i + 1] === "*") {
			i += 2;
			while (i < s.length && !(s[i] === "*" && s[i + 1] === "/")) i++;
			i += 2;
			continue;
		}
		out += c;
		i++;
	}
	return out;
}
function foldMovieStrings(s) {
	let prev = "";
	while (prev !== s) {
		prev = s;
		s = s.replace(/"((?:\\.|[^"\\])*)"\s*\+\s*"((?:\\.|[^"\\])*)"/g, function (_m, a, b) { return '"' + a + b + '"'; });
		s = s.replace(/'((?:\\.|[^'\\])*)'\s*\+\s*'((?:\\.|[^'\\])*)'/g, function (_m, a, b) { return "'" + a + b + "'"; });
	}
	return s;
}
function movieFns(text) {
	const re = /\n      (?:private|public) function /g;
	const starts = [];
	let m;
	while ((m = re.exec(text))) starts.push(m.index + 1);
	const spans = [];
	for (let i = 0; i < starts.length; i++) spans.push(text.slice(starts[i], i + 1 < starts.length ? starts[i + 1] : text.length));
	return spans;
}
function fadeProblems(text) {
	const problems = [];
	const allow = { hzcRxFind: 1, hzcRxItemTx: 1, hzcRxWaits: 1, hzcRxWaitClear: 1, hzcRxOpen: 1 };
	const fns = movieFns(stripMovieComments(text));
	for (let fi = 0; fi < fns.length; fi++) {
		const raw = fns[fi];
		const fn = foldMovieStrings(raw);
		const bodyAt = fn.indexOf("{");
		const body = bodyAt >= 0 ? fn.slice(bodyAt + 1) : fn;
		const aliases = {};
		const asg = /(?:var\s+)?([A-Za-z_][A-Za-z0-9_]*)\s*(?::\s*\*)?\s*=\s*([^;\n]*);/g;
		let am;
		while ((am = asg.exec(body))) { if (am[2].indexOf("Internal_mc") >= 0) aliases[am[1]] = 1; }
		let i = 0;
		while (i < body.length) {
			const at = body.indexOf(".alpha", i);
			if (at < 0) break;
			if (!/^\s*=(?!=)/.test(body.slice(at + 6))) { i = at + 6; continue; }
			let j = at - 1;
			while (j >= 0 && /[A-Za-z0-9_$.\[\]"']/.test(body[j])) j--;
			const recv = body.slice(j + 1, at);
			const ids = recv.match(/[A-Za-z_][A-Za-z0-9_]*/g) || [];
			const last = ids.length ? ids[ids.length - 1] : "";
			if (recv.indexOf("Internal_mc") >= 0 || aliases[last]) problems.push("alpha " + recv);
			i = at + 6;
		}
		if (raw.indexOf("function hzcRxLink") >= 0) {
			const call = /(this\.)?([A-Za-z_][A-Za-z0-9_]*)\s*\(/g;
			let cm;
			while ((cm = call.exec(body))) {
				if (!cm[1] && cm[2].indexOf("hzc") !== 0) continue;
				if (!allow[cm[2]]) problems.push("link " + cm[2]);
			}
			const br = /this\[\s*"([A-Za-z_][A-Za-z0-9_]*)"\s*\]\s*\(/g;
			let bm;
			while ((bm = br.exec(body))) { if (!allow[bm[1]]) problems.push("link " + bm[1]); }
		}
	}
	return problems;
}
{
	const clean = fadeProblems(src);
	expect(clean.length === 0, "shipped fade writes stay off Internal_mc" + (clean.length ? " (" + clean[0] + ")" : ""));
	const head = "private function hzcRxLink(arr:*) : void\n      {";
	expect(src.indexOf(head) >= 0, "the link function has a stable head");
	const poked = src.replace(head, head + "\n         this.hzcRxPoke(it);");
	expect(fadeProblems(poked).length > 0, "a new helper on a line without a card fails");
	const split = src.replace(head, head + '\n         it["Internal" + "_mc"].alpha = 1;');
	expect(fadeProblems(split).length > 0, "a split Internal_mc alpha write fails");
	const direct = src.replace(head, head + "\n         it.Internal_mc.alpha = 1;");
	expect(fadeProblems(direct).length > 0, "a direct Internal_mc alpha write fails");
	const aliasAt = "var im:* = it.Internal_mc;\n            if(im == null || im.Text_tf == null)";
	const alias = src.replace(aliasAt, "var im:* = it.Internal_mc;\n            im.alpha = 1;\n            if(im == null || im.Text_tf == null)");
	expect(src.indexOf(aliasAt) >= 0 && fadeProblems(alias).length > 0, "an Internal_mc alias alpha write fails");
}

function cardAlpha(itAlpha, imAlpha, mAlpha) {
	let a = itAlpha * imAlpha * mAlpha;
	if (!Number.isFinite(a)) a = 1;
	return Math.max(0, Math.min(1, a));
}
function tickUnclassified(line, timelineAlpha) {
	const tf = line.tf;
	const bg = line.bg;
	line.imAlpha = timelineAlpha;
	return line.alpha === 1 && line.imAlpha === timelineAlpha && line.tf === tf && line.bg === bg;
}
function coverLine(line) {
	line.tf = false;
	line.bg = false;
	line.covered = true;
}
function showLine(line) {
	if (line.covered === true) {
		line.tf = true;
		line.bg = true;
		line.covered = false;
	}
}
{
	const fade = [0, 27 / 255, 1, 205 / 255, 0];
	const plain = { alpha: 1, imAlpha: 1, tf: true, bg: true, covered: false };
	for (let i = 0; i < fade.length; i++) {
		expect(tickUnclassified(plain, fade[i]), "an unclassified line keeps the timeline alpha");
		expect(Math.abs(cardAlpha(1, fade[i], 1) - fade[i]) < 1e-9, "a card follows Internal_mc.alpha");
	}
	expect(Math.abs(cardAlpha(1, 27 / 255, 0.5) - (27 / 255) * 0.5) < 1e-9, "a card also follows the message column");
	const other = { alpha: 1, imAlpha: 0.2, tf: true, bg: true, covered: false };
	showLine(other);
	expect(other.tf === true && other.bg === true && other.imAlpha === 0.2 && other.covered === false, "a line that was not covered is not rewritten");
	const hid = { alpha: 1, imAlpha: 205 / 255, tf: true, bg: true, covered: false };
	coverLine(hid);
	expect(hid.tf === false && hid.bg === false && hid.covered === true && hid.imAlpha === 205 / 255, "covering hides the children and leaves the fade");
	expect(Math.abs(cardAlpha(hid.alpha, hid.imAlpha, 1) - 205 / 255) < 1e-9, "a covered card is at the fade-out alpha");
	showLine(hid);
	expect(hid.tf === true && hid.bg === true && hid.covered === false && hid.imAlpha === 205 / 255, "ending a covered card restores its children");
}

function cardPush(q, raw, now, dropped) {
	q.push({ key: String(raw).toLowerCase(), t0: now, covered: false });
	if (q.length > 8) {
		const old = q.shift();
		if (old.covered === true) {
			old.covered = false;
			old.restored = true;
		}
		if (dropped) dropped.push(old);
	}
	return "queued";
}
{
	const again = [];
	expect(cardPush(again, "Sam Coe liked that.", 0) === "queued", "the first identical push queues");
	expect(cardPush(again, "Sam Coe liked that.", 1000) === "queued", "the second identical push queues");
	expect(again.length === 2, "two identical DLL cards within 3 s both stay");
	const full = [];
	const dropped = [];
	for (let i = 0; i < 8; i++) cardPush(full, "line " + i, i, dropped);
	full[0].covered = true;
	cardPush(full, "line 9", 9, dropped);
	expect(full.length === 8 && full[0].key === "line 1", "the ninth card drops the oldest");
	expect(dropped.length === 1 && dropped[0].restored === true && dropped[0].covered === false, "the dropped card restores its line");
}

function stackCards(cards) {
	const vis = [];
	for (let i = 0; i < cards.length; i++) if (cards[i].visible) vis.push({ x: cards[i].x, y: cards[i].y, h: cards[i].h });
	vis.sort(function (a, b) { return a.y - b.y; });
	const gap = 8;
	for (let p = 1; p < vis.length; p++) {
		const floorY = vis[p - 1].y + vis[p - 1].h + gap;
		if (vis[p].y < floorY) vis[p].y = Math.round(floorY);
	}
	return vis;
}
{
	const laid = stackCards([
		{ visible: true, x: 10, y: 100, h: 70 },
		{ visible: true, x: 10, y: 151, h: 81 },
		{ visible: true, x: 22, y: 400, h: 56 }
	]);
	expect(laid[0].y === 100 && laid[0].x === 10, "the top card stays");
	expect(laid[1].y === 178 && laid[1].x === 10, "an overlapping card moves down and keeps its x");
	expect(laid[2].y === 400 && laid[2].x === 22, "a card that already clears stays");
	const same = stackCards([
		{ visible: true, x: 4, y: 80, h: 63 },
		{ visible: true, x: 9, y: 80, h: 63 }
	]);
	expect(same[0].y === 80 && same[1].y === 151 && same[1].x === 9, "two cards on one line do not overlap");
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

function shippedRegexes(text) {
	const found = [];
	let i = 0;
	// A slash starts a regex after those punctuation marks, after return / typeof / case, or at the start of a line.
	// A slash after a name stays division, so "a / b" is not scanned.
	function canRegexAt(at) {
		let j = at - 1;
		while (j >= 0 && (text[j] === " " || text[j] === "\t" || text[j] === "\r" || text[j] === "\f")) j--;
		if (j < 0 || text[j] === "\n") return true;
		if (/[A-Za-z0-9_$]/.test(text[j])) {
			let k = j;
			while (k >= 0 && /[A-Za-z0-9_$]/.test(text[k])) k--;
			const word = text.slice(k + 1, j + 1);
			return word === "return" || word === "typeof" || word === "case";
		}
		return "([=,;:!&|?{}~+-*%^<>".indexOf(text[j]) >= 0;
	}
	while (i < text.length) {
		const c = text[i];
		if (c === "/" && text[i + 1] === "/") {
			i += 2;
			while (i < text.length && text[i] !== "\n") i++;
			continue;
		}
		if (c === "/" && text[i + 1] === "*") {
			i += 2;
			while (i < text.length && !(text[i] === "*" && text[i + 1] === "/")) i++;
			i += 2;
			continue;
		}
		if (c === '"' || c === "'") {
			const q = c;
			const start = i;
			i++;
			let s = "";
			while (i < text.length) {
				if (text[i] === "\\") { s += text[i] + (text[i + 1] || ""); i += 2; continue; }
				if (text[i] === q) { i++; break; }
				s += text[i];
				i++;
			}
			const before = text.slice(Math.max(0, start - 40), start);
			if (/new\s+RegExp\s*\(\s*$/.test(before)) {
				found.push(s.replace(/\\(.)/g, function (_, ch) { return ch; }));
			}
			continue;
		}
		if (c === "/" && canRegexAt(i)) {
			i++;
			let pat = "";
			let closed = false;
			while (i < text.length) {
				if (text[i] === "\\") { pat += text[i] + (text[i + 1] || ""); i += 2; continue; }
				if (text[i] === "/") { closed = true; i++; break; }
				if (text[i] === "\n") break;
				pat += text[i];
				i++;
			}
			let flags = "";
			if (closed) {
				while (i < text.length && /[gimsxu]/i.test(text[i])) { flags += text[i]; i++; }
				found.push(pat + "\n" + flags);
			}
			continue;
		}
		i++;
	}
	return found;
}
function regexBanned(item) {
	const nl = item.indexOf("\n");
	const body = nl >= 0 ? item.slice(0, nl) : item;
	const flags = nl >= 0 ? item.slice(nl + 1) : "";
	if (flags.indexOf("u") >= 0) return "u flag";
	if (body.indexOf("(?<") >= 0) return "(?<";
	if (body.indexOf("\\p{") >= 0) return "\\p{";
	if (body.indexOf("\\u") >= 0 && body !== "\\u0041") return "\\u";
	return "";
}
{
	function bannedOf(sample) {
		const items = shippedRegexes(sample);
		const why = [];
		for (let bi = 0; bi < items.length; bi++) {
			const w = regexBanned(items[bi]);
			if (w) why.push(w);
		}
		return { n: items.length, why: why };
	}
	const ret = bannedOf("function f():void { return /\\u0042/; }");
	expect(ret.n === 1 && ret.why[0] === "\\u", "a regex literal after return is scanned");
	const typ = bannedOf("typeof /\\u0043/;");
	expect(typ.n === 1 && typ.why[0] === "\\u", "a regex literal after typeof is scanned");
	const cas = bannedOf("case /\\u0044/:");
	expect(cas.n === 1 && cas.why[0] === "\\u", "a regex literal after case is scanned");
	const paren = bannedOf("(/\\u0045/)");
	expect(paren.n === 1 && paren.why[0] === "\\u", "a regex literal after a parenthesis is scanned");
	const line = bannedOf("var a:int = 1;\n/\\u0046/;");
	expect(line.n === 1 && line.why[0] === "\\u", "a regex literal at the start of a line is scanned");
	const div = bannedOf("var a:Number = 1; a /\\u0042/ b;");
	expect(div.n === 0, "division after a name is not a regex literal");
	const allowed = bannedOf("return /\\u0041/;");
	expect(allowed.n === 1 && allowed.why.length === 0, "the startup probe body stays allowed");
}
// Scaleform String.replace leaves $1, $2, $&, $$, $` and $' in the text.
// A function as the replacement is also rejected: the support table does not say that form works.
function replacementCode(decoded) {
	const m = /\$(\$|&|`|'|[0-9])/.exec(decoded);
	return m ? m[0] : "";
}
function decodeAsString(body) {
	let o = "";
	for (let i = 0; i < body.length; i++) {
		if (body[i] !== "\\") { o += body[i]; continue; }
		const n = body[i + 1] || "";
		if (n === "n") o += "\n";
		else if (n === "r") o += "\r";
		else if (n === "t") o += "\t";
		else o += n;
		i++;
	}
	return o;
}
function skipSpaceAt(text, i) {
	while (i < text.length && /\s/.test(text[i])) i++;
	return i;
}
function readStringAt(text, i) {
	const q = text[i];
	let j = i + 1;
	let body = "";
	while (j < text.length) {
		if (text[j] === "\\") { body += text[j] + (text[j + 1] || ""); j += 2; continue; }
		if (text[j] === q) return { raw: text.slice(i, j + 1), decoded: decodeAsString(body), end: j + 1 };
		body += text[j];
		j++;
	}
	return { raw: text.slice(i), decoded: decodeAsString(body), end: text.length };
}
function canStartRegex(prev) {
	return !prev || "([=,;:!&|?{}~+-*%^<>".indexOf(prev) >= 0;
}
// Second argument of each .replace( call, outside comments.
function replaceReplacements(text) {
	const out = [];
	let i = 0;
	let prev = "";
	function takeString() {
		const s = readStringAt(text, i);
		i = s.end;
		prev = s.raw[0];
		return s;
	}
	while (i < text.length) {
		const c = text[i];
		if (c === "/" && text[i + 1] === "/") {
			i += 2;
			while (i < text.length && text[i] !== "\n") i++;
			continue;
		}
		if (c === "/" && text[i + 1] === "*") {
			i += 2;
			while (i < text.length && !(text[i] === "*" && text[i + 1] === "/")) i++;
			i += 2;
			continue;
		}
		if (c === '"' || c === "'") { takeString(); continue; }
		if (c === "/" && canStartRegex(prev)) {
			i++;
			while (i < text.length) {
				if (text[i] === "\\") { i += 2; continue; }
				if (text[i] === "/" || text[i] === "\n") { i++; break; }
				i++;
			}
			while (i < text.length && /[gimsx]/i.test(text[i])) i++;
			prev = "/";
			continue;
		}
		if (c === "." && text.slice(i, i + 8) === ".replace" && !/[A-Za-z0-9_$]/.test(text[i + 8] || "")) {
			let j = skipSpaceAt(text, i + 8);
			if (text[j] !== "(") { prev = "."; i++; continue; }
			const args = [];
			let cur = "";
			let depth = 1;
			let k = j + 1;
			let ap = "";
			while (k < text.length && depth > 0) {
				if (text[k] === "/" && text[k + 1] === "/") {
					k += 2;
					while (k < text.length && text[k] !== "\n") k++;
					continue;
				}
				if (text[k] === "/" && text[k + 1] === "*") {
					k += 2;
					while (k < text.length && !(text[k] === "*" && text[k + 1] === "/")) k++;
					k += 2;
					continue;
				}
				if (text[k] === '"' || text[k] === "'") {
					const s = readStringAt(text, k);
					cur += text.slice(k, s.end);
					k = s.end;
					ap = s.raw[0];
					continue;
				}
				if (text[k] === "/" && canStartRegex(ap)) {
					const start = k;
					k++;
					while (k < text.length) {
						if (text[k] === "\\") { k += 2; continue; }
						if (text[k] === "/" || text[k] === "\n") { k++; break; }
						k++;
					}
					while (k < text.length && /[gimsx]/i.test(text[k])) k++;
					cur += text.slice(start, k);
					ap = "/";
					continue;
				}
				if (text[k] === "(" || text[k] === "[" || text[k] === "{") { depth++; cur += text[k]; ap = text[k]; k++; continue; }
				if (text[k] === ")" || text[k] === "]" || text[k] === "}") {
					depth--;
					if (depth === 0) break;
					cur += text[k];
					ap = text[k];
					k++;
					continue;
				}
				if (text[k] === "," && depth === 1) { args.push(cur); cur = ""; ap = ","; k++; continue; }
				if (!/\s/.test(text[k])) ap = text[k];
				cur += text[k];
				k++;
			}
			args.push(cur);
			if (args.length >= 2) out.push(args[1]);
			i = k + 1;
			prev = ")";
			continue;
		}
		if (!/\s/.test(c)) prev = c;
		i++;
	}
	return out;
}
function replacementProblem(arg) {
	const trimmed = arg.trim();
	let i = 0;
	let sawString = false;
	let glued = "";
	let onlyStrings = true;
	while (i < trimmed.length) {
		if (/\s/.test(trimmed[i]) || trimmed[i] === "+") { i++; continue; }
		if (trimmed[i] === '"' || trimmed[i] === "'") {
			const s = readStringAt(trimmed, i);
			sawString = true;
			const code = replacementCode(s.decoded);
			if (code) return code;
			glued += s.decoded;
			i = s.end;
			continue;
		}
		onlyStrings = false;
		break;
	}
	if (onlyStrings && sawString) {
		const code = replacementCode(glued);
		if (code) return code;
	}
	let j = 0;
	let inStr = false;
	let q = "";
	while (j < trimmed.length) {
		if (inStr) {
			if (trimmed[j] === "\\") { j += 2; continue; }
			if (trimmed[j] === q) inStr = false;
			j++;
			continue;
		}
		if (trimmed[j] === '"' || trimmed[j] === "'") { inStr = true; q = trimmed[j]; j++; continue; }
		if (trimmed.slice(j, j + 8) === "function" && !/[A-Za-z0-9_$]/.test(trimmed[j + 8] || "")) return "function";
		j++;
	}
	return "";
}
{
	const hit = replacementProblem('"$1 $2"');
	expect(hit === "$1", "the replace rule catches a $1 replacement");
	expect(replacementProblem('"$&"') === "$&", "the replace rule catches $&");
	expect(replacementProblem('"$$"') === "$$", "the replace rule catches $$");
	expect(replacementProblem('"$2"') === "$2", "the replace rule catches $2");
	expect(replacementProblem("function(m:String):String { return m; }") === "function", "the replace rule catches a function replacement");
	expect(replacementProblem('"$MAIN_Font"') === "", "a translation token is not a replacement code");
	expect(replacementProblem('" "') === "", "a space replacement is allowed");
	const sample = 's.replace(/([a-z])([A-Z])/g,"$1 $2");\nGlobalFunc.SetText(tf,"$$scanned");\ns.replace(re,"$MAIN_Font");';
	const reps = replaceReplacements(sample);
	expect(reps.length === 2 && replacementProblem(reps[0]) === "$1" && replacementProblem(reps[1]) === "", "$$ in SetText is not a replace replacement");
}
{
	const iniFiles = [
		"actionscript/horizon_block.as",
		"actionscript/comms/hzc_block.as",
		"actionscript/comms/hzd_block.as",
		"actionscript/scope/hzp37_reader.as",
		"actionscript/scanner/hzs_block.as",
		"actionscript/scope/imp/pimp_scopemenu/ScopeMenu.as",
		"actionscript/scope/imp/pimp_scopemenu_lrg/ScopeMenu.as",
		"actionscript/imp/simp_monoclemenu/MonocleMenu.as",
		"actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as"
	];
	for (let ii = 0; ii < iniFiles.length; ii++) {
		const rel = iniFiles[ii];
		const text = fs.readFileSync(path.join(__dirname, "..", rel), "utf8");
		expect(text.indexOf("LegTry") >= 0 && text.indexOf('substr(pth.length - 13) == "HorizonUI.ini"') >= 0, rel + " opens the unshipped ini at most once");
		expect(text.indexOf("Got[1] != null || this.") >= 0, rel + " skips HorizonUI.ini when defaults and another file are present");
	}
	const hud = fs.readFileSync(path.join(__dirname, "..", "actionscript", "horizon_block.as"), "utf8");
	const fontFn = hud.slice(hud.indexOf("private function hzFontName"), hud.indexOf("private function hzApplyTypo"));
	expect(fontFn.indexOf('hz30Mod["font"] !== 1') >= 0, "HUD waits for the font library");
	expect(fontFn.indexOf('hzFontProbe("$Horizon_Font")') < fontFn.indexOf('"$Horizon_Font_Bold"'), "Bold is not looked up before the base face");
	const scope = fs.readFileSync(path.join(__dirname, "..", "actionscript", "scope", "hzp_main.as"), "utf8");
	expect(scope.indexOf("hzpFontLib !== 1") >= 0 && scope.indexOf('hzpProbe("$Horizon_Font")') < scope.indexOf('"$Horizon_Font_Bold"'), "scope waits for the font library");
	const scopeTwin = fs.readFileSync(path.join(__dirname, "..", "actionscript", "scope", "imp", "pimp_scopemenu_lrg", "ScopeMenu.as"), "utf8");
	expect(scopeTwin.indexOf("hzpFontLib !== 1") >= 0, "the large scope waits for the font library");
	const scan = fs.readFileSync(path.join(__dirname, "..", "actionscript", "scanner", "hzs_block.as"), "utf8");
	expect(scan.indexOf("hzsFontLib !== 1") >= 0 && scan.indexOf('hzsProbe("$Horizon_Font")') < scan.indexOf('"$Horizon_Font_Bold"'), "scanner waits for the font library");
	const dlg = fs.readFileSync(path.join(__dirname, "..", "actionscript", "comms", "hzd_block.as"), "utf8");
	const dlgFont = dlg.slice(dlg.indexOf("private function hzdFont"), dlg.indexOf("private function hzdText"));
	expect(dlgFont.indexOf("hzdProbe.font !== 1") >= 0 && dlgFont.indexOf("hzdFontProbe(base)") < dlgFont.indexOf("hzdFontProbe(base + role)"), "dialogue waits for the font library");
}
// Shipped movies and the blocks they are built from, including each _lrg twin.
// hudmenu and hudmenu_lrg share horizon_block.as. The older HUDMenu_1 / himp snapshots are not this build.
const scanFiles = [
	"actionscript/comms/hzc_block.as",
	"actionscript/comms/hzd_block.as",
	"actionscript/horizon_block.as",
	"actionscript/scope/hzp_main.as",
	"actionscript/scanner/hzs_block.as",
	"actionscript/imp/imp/scripts/HUDMessagesMenu.as",
	"actionscript/imp/imp-Lrg/scripts/HUDMessagesMenu.as",
	"actionscript/imp/dimp/scripts/DialogueMenu.as",
	"actionscript/imp/dimp-Lrg/scripts/DialogueMenu.as",
	"actionscript/scope/imp/pimp_scopemenu/ScopeMenu.as",
	"actionscript/scope/imp/pimp_scopemenu_lrg/ScopeMenu.as",
	"actionscript/imp/simp_monoclemenu/MonocleMenu.as",
	"actionscript/imp/simp_monoclemenu_lrg/MonocleMenu.as"
];
for (let si = 0; si < scanFiles.length; si++) {
	const rel = scanFiles[si];
	const text = fs.readFileSync(path.join(__dirname, "..", rel), "utf8");
	const items = shippedRegexes(text);
	for (let ri = 0; ri < items.length; ri++) {
		const why = regexBanned(items[ri]);
		expect(!why, rel + " regex " + ri + (why ? " uses " + why : " is ascii-safe"));
	}
	const reps = replaceReplacements(text);
	for (let pi = 0; pi < reps.length; pi++) {
		const why = replacementProblem(reps[pi]);
		expect(!why, rel + " replace " + pi + (why ? " uses " + why : " has a plain replacement"));
	}
}

// DLL matcher (src/hz_msg_match.h). The movie no longer parses a live line.
// This is the same suffix rules: disliked before liked, English present tense only
// while the likes phrase is still English, and a cut-off line fails closed.
function dllFold(c) {
	const u = c.charCodeAt(0);
	if (u >= 65 && u <= 90) return String.fromCharCode(u + 32);
	return c;
}
function dllEq(a, b) {
	if (a.length !== b.length) return false;
	for (let i = 0; i < a.length; i++) if (dllFold(a.charAt(i)) !== dllFold(b.charAt(i))) return false;
	return true;
}
function dllTrim(s) {
	let a = 0;
	let b = s.length;
	while (a < b && " \t\n\r\v\f".indexOf(s.charAt(a)) >= 0) a++;
	while (b > a && " \t\n\r\v\f".indexOf(s.charAt(b - 1)) >= 0) b--;
	return s.slice(a, b);
}
function dllEnds(s, suf) {
	if (!suf || s.length < suf.length) return false;
	return dllEq(s.slice(s.length - suf.length), suf);
}
function dllStarts(s, pre) {
	if (!pre || s.length < pre.length) return false;
	return dllEq(s.slice(0, pre.length), pre);
}
function dllDropDot(s) {
	return s.length > 0 && s.charAt(s.length - 1) === "." ? s.slice(0, -1) : s;
}
function dllEndsPhrase(line, phrase) {
	phrase = dllTrim(phrase);
	if (!phrase) return false;
	if (dllEnds(line, phrase)) return true;
	if (phrase.charAt(phrase.length - 1) === ".") {
		const bare = phrase.slice(0, -1);
		return bare.length > 0 && dllEnds(line, bare);
	}
	return dllEnds(dllDropDot(line), phrase);
}
function dllPrefix(line, phrase) {
	phrase = dllTrim(phrase);
	function take(suf) {
		if (!dllEnds(line, suf)) return null;
		return dllTrim(line.slice(0, line.length - suf.length));
	}
	if (dllEnds(line, phrase)) return take(phrase);
	if (phrase.charAt(phrase.length - 1) === ".") {
		const bare = phrase.slice(0, -1);
		if (dllEnds(line, bare)) return take(bare);
	} else if (dllEnds(dllDropDot(line), phrase)) {
		const cut = dllDropDot(line);
		if (dllEnds(cut, phrase)) return dllTrim(cut.slice(0, cut.length - phrase.length));
	}
	return null;
}
function dllWords(s) {
	let n = 0;
	let inn = false;
	for (let i = 0; i < s.length; i++) {
		if (s.charAt(i) === " ") { inn = false; continue; }
		if (!inn) { inn = true; n++; }
	}
	return n;
}
const DLL_TITLE = ["dr", "mr", "mrs", "ms", "jr", "sr", "st", "lt", "capt", "sgt", "prof"];
const DLL_NO = ["i", "you", "we", "they", "he", "she", "it", "your", "my", "our", "their", "his", "her", "nobody", "everyone", "everybody", "someone", "somebody", "none", "all", "some", "the", "a", "an", "crew", "who", "not", "people", "this", "that", "many", "most", "each", "several", "both", "what"];
function dllIs(list, w) {
	for (let i = 0; i < list.length; i++) if (dllEq(w, list[i])) return true;
	return false;
}
function dllRxName(name, english) {
	name = dllTrim(name);
	if (!name || name.length > 80) return false;
	if (name.indexOf("<") >= 0 || name.indexOf(">") >= 0) return false;
	const n = dllWords(name);
	if (!english) return n >= 1 && n <= 8;
	if (n < 1 || n > 4) return false;
	const sp = name.indexOf(" ");
	let first = sp < 0 ? name : name.slice(0, sp);
	while (first.charAt(first.length - 1) === ".") first = first.slice(0, -1);
	if (!first || dllIs(DLL_NO, first)) return false;
	if (n === 1 && dllIs(DLL_TITLE, first)) return false;
	if (sp >= 0) {
		const rest = dllTrim(name.slice(sp + 1));
		const sp2 = rest.indexOf(" ");
		let second = sp2 < 0 ? rest : rest.slice(0, sp2);
		while (second.charAt(second.length - 1) === ".") second = second.slice(0, -1);
		if (dllEq(first, "no") && dllEq(second, "one")) return false;
	}
	return true;
}
function dllPlain(name) {
	name = dllTrim(name);
	if (!name || name.length > 80) return false;
	if (name.indexOf("<") >= 0 || name.indexOf(">") >= 0) return false;
	const n = dllWords(name);
	return n >= 1 && n <= 8;
}
function dllShadow(line, phrase) {
	phrase = dllTrim(phrase);
	const bare = dllDropDot(phrase);
	if (!dllEq(bare, "liked that") && !dllEq(bare, "likes that")) return false;
	const longer = ["disliked that.", "dislikes that."];
	for (let i = 0; i < longer.length; i++) {
		if (dllEq(dllTrim(longer[i]), phrase)) continue;
		if (!dllEndsPhrase(longer[i], phrase)) continue;
		if (dllEndsPhrase(line, longer[i])) return true;
	}
	return false;
}
function dllMake(kind, sub, name, value, tier) {
	return { ok: true, kind: kind, sub: sub, name: name, value: value, tier: tier };
}
function dllReaction(line, t) {
	const slots = [
		[t.dislikes, "disliked", "DISLIKED", dllEq(dllTrim(t.dislikes), "disliked that.")],
		[t.hates, "hated", "HATED", dllEq(dllTrim(t.hates), "hated that.")],
		[t.loves, "loved", "LOVED", dllEq(dllTrim(t.loves), "loved that.")],
		[t.likes, "liked", "LIKED", dllEq(dllTrim(t.likes), "liked that.")]
	];
	for (let i = 0; i < slots.length; i++) {
		if (!dllEndsPhrase(line, slots[i][0]) || dllShadow(line, slots[i][0])) continue;
		const name = dllPrefix(line, slots[i][0]);
		if (!dllRxName(name, slots[i][3])) return null;
		return dllMake("reaction", slots[i][1], name, slots[i][2], slots[i][3] ? "C" : "A");
	}
	if (dllEq(dllTrim(t.likes), "liked that.")) {
		const now = [
			["dislikes that.", "disliked", "DISLIKED"],
			["hates that.", "hated", "HATED"],
			["loves that.", "loved", "LOVED"],
			["likes that.", "liked", "LIKED"]
		];
		for (let i = 0; i < now.length; i++) {
			if (!dllEndsPhrase(line, now[i][0]) || dllShadow(line, now[i][0])) continue;
			const name = dllPrefix(line, now[i][0]);
			if (!dllRxName(name, true)) return null;
			return dllMake("reaction", now[i][1], name, now[i][2], "C");
		}
	}
	return null;
}
function dllCredits(line, tail) {
	tail = dllTrim(tail);
	if (!tail || !dllEndsPhrase(line, tail)) return null;
	let s = line;
	if (dllEnds(s, tail)) {
		/* keep */
	} else if (tail.charAt(tail.length - 1) === "." && dllEnds(s, tail.slice(0, -1))) {
		/* keep */
	} else s = dllDropDot(s);
	const suf = dllEnds(s, tail) ? tail : tail.slice(0, -1);
	if (s.length < suf.length + 2) return null;
	const head = dllTrim(s.slice(0, s.length - suf.length));
	if (!head) return null;
	let digits = "";
	let i = 0;
	while (i < head.length) {
		const c = head.charAt(i);
		if (c >= "0" && c <= "9") { digits += c; i++; continue; }
		if (c === "," && digits.length > 0 && i + 1 < head.length && head.charAt(i + 1) >= "0" && head.charAt(i + 1) <= "9") { i++; continue; }
		break;
	}
	if (i === 0 || i !== head.length || digits.length === 0 || digits.length > 9) return null;
	return dllMake("credits", "kid", "", "-" + digits, "C");
}
function dllMedical(line) {
	const holes = [
		["Prognosis improved (", ")", "improved", "IMPROVED"],
		["Severity improved (", ")", "severity", "LESS SEVERE"],
		["Attempted to cure ", ".", "attempted", "ATTEMPTED"],
		["", " became worse.", "worse", "WORSE"],
		["", " gained.", "gained", "GAINED"],
		["", " cured.", "cured", "CURED"]
	];
	for (let h = 0; h < holes.length; h++) {
		let s = line;
		const paren = holes[h][1] === ")";
		if (paren && s.length > 0 && s.charAt(s.length - 1) === "." && !dllEnds(s, holes[h][1])) s = dllDropDot(s);
		if (holes[h][0] && !dllStarts(s, holes[h][0])) continue;
		if (!dllEndsPhrase(s, holes[h][1]) && !dllEnds(s, holes[h][1])) continue;
		let mid = "";
		if (!dllEnds(s, holes[h][1])) {
			if (!holes[h][1] || holes[h][1].charAt(holes[h][1].length - 1) !== ".") continue;
			const bare = holes[h][1].slice(0, -1);
			if (!dllEnds(s, bare)) continue;
			if (s.length < holes[h][0].length + bare.length) continue;
			mid = dllTrim(s.slice(holes[h][0].length, s.length - bare.length));
		} else {
			if (s.length < holes[h][0].length + holes[h][1].length) continue;
			mid = dllTrim(s.slice(holes[h][0].length, s.length - holes[h][1].length));
		}
		if (!dllPlain(mid)) continue;
		return dllMake("medical", holes[h][2], mid, holes[h][3], "C");
	}
	return null;
}
function dllCrew(line) {
	const rows = [
		["is furious with you and will no longer be your companion.", "furious", "FURIOUS"],
		["is no longer available to be your companion.", "companion-unavailable", "AVAILABLE"],
		["is no longer available to be your follower.", "follow-unavailable", "AVAILABLE"],
		["is no longer available for your Crew.", "crew-unavailable", "CREW"],
		["is no longer an Active Crew Member.", "uncrew", "CREW"],
		["is no longer your Active Companion", "uncompanion", "COMPANION"],
		["is no longer following you.", "unfollow", "FOLLOWING"],
		["is no longer angry with you.", "calm", "CALM"],
		["is now your Active Companion.", "companion", "COMPANION"],
		["is available to be your Companion", "companion-available", "AVAILABLE"],
		["is available to be your follower.", "follow-available", "AVAILABLE"],
		["is now an Active Crew Member.", "crew", "CREW"],
		["is available for your Crew.", "crew-available", "AVAILABLE"],
		["is now following you.", "follow", "FOLLOWING"],
		["considers you a committed partner.", "partner", "PARTNER"],
		["considers you a friend.", "friend", "FRIEND"],
		["considers you an ally.", "ally", "ALLY"],
		["is angry with you.", "angry", "ANGRY"]
	];
	for (let i = 0; i < rows.length; i++) {
		if (!dllEndsPhrase(line, rows[i][0])) continue;
		const name = dllPrefix(line, rows[i][0]);
		if (!dllPlain(name)) continue;
		return dllMake("crew", rows[i][1], name, rows[i][2], "C");
	}
	return null;
}
function dllUnavail(line, t) {
	function tier(got, english) { return dllEq(dllTrim(got), dllTrim(english)) ? "C" : "A"; }
	function eqLine(got, phrase) {
		got = dllTrim(got);
		phrase = dllTrim(phrase);
		if (!phrase) return false;
		if (dllEq(got, phrase)) return true;
		return dllEq(dllDropDot(got), dllDropDot(phrase));
	}
	if (dllEq(line, dllTrim(t.busy))) return dllMake("unavailable", "busy", "", "BUSY", tier(t.busy, "This individual is busy."));
	if (dllEq(line, dllTrim(t.creature))) return dllMake("unavailable", "calmed", "Creature", "CALMED", tier(t.creature, "The creature is calmed and cannot respond."));
	if (dllEq(line, dllTrim(t.pickFail))) return dllMake("crime", "caught", "", "CAUGHT", tier(t.pickFail, "You've been caught pickpocketing."));
	if (eqLine(line, t.stealTake)) return dllMake("crime", "takeback", "", "CAUGHT", tier(t.stealTake, "The owner caught you stealing."));
	if (eqLine(line, t.stealAttack)) return dllMake("crime", "alarm", "", "ALARM", tier(t.stealAttack, "You've been caught stealing and the alarm has been raised."));
	if (eqLine(line, t.lockCaught)) return dllMake("crime", "lock", "", "CAUGHT", tier(t.lockCaught, "You've been caught tampering with a lock."));
	if (eqLine(line, t.trespass)) return dllMake("crime", "trespass", "", "TRESPASS", tier(t.trespass, "You're currently trespassing. Residents will become hostile if you stay."));
	if (eqLine(line, t.witness)) return dllMake("crime", "witness", "", "WITNESS", tier(t.witness, "Last witness killed."));
	if (dllEndsPhrase(line, t.npcCalmed)) {
		const name = dllPrefix(line, t.npcCalmed);
		if (!dllPlain(name)) return null;
		return dllMake("unavailable", "calmed", name, "CALMED", tier(t.npcCalmed, "is calmed and cannot respond."));
	}
	if (dllEndsPhrase(line, t.caught)) {
		const name = dllPrefix(line, t.caught);
		if (!dllPlain(name)) return null;
		return dllMake("unavailable", "caught", name, "CAUGHT", tier(t.caught, "has already caught you."));
	}
	return null;
}
function dllEnglish() {
	return {
		likes: "liked that.",
		loves: "loved that.",
		dislikes: "disliked that.",
		hates: "hated that.",
		busy: "This individual is busy.",
		npcCalmed: "is calmed and cannot respond.",
		creature: "The creature is calmed and cannot respond.",
		caught: "has already caught you.",
		pickFail: "You've been caught pickpocketing.",
		stealTake: "The owner caught you stealing.",
		stealAttack: "You've been caught stealing and the alarm has been raised.",
		lockCaught: "You've been caught tampering with a lock.",
		trespass: "You're currently trespassing. Residents will become hostile if you stay.",
		witness: "Last witness killed.",
		addCrime: "bounty added to",
		remCrime: "bounty removed from",
		added: "Added.",
		removed: "Removed.",
		creditsName: "Credits",
		credits: "credits have been sent home to your parents.",
		kidTpl: "%.0f credits have been sent home to your parents."
	};
}
function dllMatch(text, phrases) {
	const line = dllTrim(text == null ? "" : String(text));
	if (!line || line.length > 200) return null;
	if (line.indexOf("\n") >= 0 || line.indexOf("\r") >= 0) return null;
	const t = phrases || dllEnglish();
	return dllReaction(line, t) || dllUnavail(line, t) || dllCredits(line, t.credits) || dllCreditsSigned(line, t) || dllMedical(line) || dllCrew(line);
}
function dllWordAt(hay, needle) {
	needle = dllTrim(needle);
	if (!needle) return -1;
	const low = String(hay).toLowerCase();
	const want = needle.toLowerCase();
	let i = 0;
	while (i + want.length <= low.length) {
		if (low.substr(i, want.length) === want) {
			const left = i === 0 || !/[A-Za-z0-9]/.test(hay.charAt(i - 1));
			const right = i + want.length === hay.length || !/[A-Za-z0-9]/.test(hay.charAt(i + want.length));
			if (left && right) return i;
		}
		i++;
	}
	return -1;
}
function dllTakeTokAmount(tok) {
	if (tok.length < 2 || (tok.charAt(0) !== "+" && tok.charAt(0) !== "-")) return null;
	const plus = tok.charAt(0) === "+";
	const t0 = 1;
	if (t0 >= tok.length) return null;
	let digits = "";
	let i = t0;
	if (i >= tok.length || tok.charAt(i) < "0" || tok.charAt(i) > "9") return null;
	while (i < tok.length) {
		const c = tok.charAt(i);
		if (c >= "0" && c <= "9") { digits += c; i++; continue; }
		if ((c === "," || c === "." || c === "'" || c === " ") && i + 3 <= tok.length && /^\d{3}$/.test(tok.substr(i + 1, 3))) {
			digits += tok.substr(i + 1, 3);
			i += 4;
			continue;
		}
		break;
	}
	if (i !== tok.length || !digits || digits.length > 9) return null;
	let grouped = "";
	for (let k = 0; k < digits.length; k++) {
		if (k && ((digits.length - k) % 3) === 0) grouped += ",";
		grouped += digits.charAt(k);
	}
	return { plus: plus, chip: (plus ? "+" : "-") + grouped };
}
function dllCreditsAfterOk(after) {
	after = dllTrim(after);
	for (;;) {
		after = dllTrim(after);
		if (!after) return true;
		const c = after.charAt(after.length - 1);
		if (c === "." || c === "!" || c === "?" || c === ":" || c === ";" || c === '"' || c === "'") {
			after = after.slice(0, -1);
			continue;
		}
		break;
	}
	if (after.length >= 2 && after.charAt(0) === "(" && after.charAt(after.length - 1) === ")") return true;
	return after.length === 1 && (after.charAt(0) === ")" || after.charAt(0) === "]");
}
function dllCreditsSigned(line, t) {
	const at = dllWordAt(line, t.creditsName);
	if (at < 0) return null;
	const before = dllTrim(line.slice(0, at));
	if (!before) return null;
	const sp = before.lastIndexOf(" ");
	const tok = sp < 0 ? before : before.slice(sp + 1);
	const amt = dllTakeTokAmount(tok);
	if (!amt) return null;
	const after = dllTrim(line.slice(at + String(t.creditsName).length));
	if (dllEndsPhrase(after, t.added) || dllEndsPhrase(after, t.removed)) return null;
	if (!dllCreditsAfterOk(after)) return null;
	const tier = dllEq(dllTrim(t.creditsName), "Credits") ? "C" : "A";
	return dllMake("credits", amt.plus ? "gain" : "loss", "", amt.chip, tier);
}
function expectDll(text, phrases, kind, sub, name, value, tier, label) {
	const h = dllMatch(text, phrases);
	const good = h && h.kind === kind && h.sub === sub && h.name === name && h.value === value && h.tier === tier;
	expect(good, label + (good ? "" : " got " + (h ? h.kind + "/" + h.sub + " [" + h.name + "] " + h.value + " " + h.tier : "miss")));
}
function expectDllMiss(text, phrases, label) {
	expect(dllMatch(text, phrases) == null, label);
}
{
	const en = dllEnglish();
	expectDll("Sam Coe liked that.", en, "reaction", "liked", "Sam Coe", "LIKED", "C", "DLL Sam Coe liked that");
	expectDll("SAM COE LIKED THAT.", en, "reaction", "liked", "SAM COE", "LIKED", "C", "DLL upper case liked");
	expectDll("Sam Coe loved that.", en, "reaction", "loved", "Sam Coe", "LOVED", "C", "DLL loved");
	expectDll("Sam Coe disliked that.", en, "reaction", "disliked", "Sam Coe", "DISLIKED", "C", "DLL disliked is not liked");
	expectDll("Sam Coe hated that.", en, "reaction", "hated", "Sam Coe", "HATED", "C", "DLL hated");
	expectDll("Sam Coe likes that", en, "reaction", "liked", "Sam Coe", "LIKED", "C", "DLL present likes");
	expectDll("  Sam Coe liked that.  ", en, "reaction", "liked", "Sam Coe", "LIKED", "C", "DLL trimmed reaction");
	expectDllMiss("I liked that.", en, "DLL pronoun");
	expectDllMiss("No one liked that.", en, "DLL no one");
	expectDllMiss("Dr. liked that.", en, "DLL bare title");
	expectDllMiss("Added.", en, "DLL loot line");
	expectDllMiss("", en, "DLL empty");
	expectDllMiss(" cured.", en, "DLL empty affliction name");
	expectDllMiss("<Alias=TextReplacementRefAlias> gained.", en, "DLL unresolved alias");
	expectDllMiss("Sam Coe lik", en, "DLL cut-off reaction");
	const de = dllEnglish();
	de.likes = "das gefiel.";
	de.dislikes = "das missfiel.";
	expectDll("Sam Coe das gefiel.", de, "reaction", "liked", "Sam Coe", "LIKED", "A", "DLL localized likes suffix");
	expectDllMiss("Sam Coe liked that.", de, "DLL English likes is not used once the GMST differs");
	expectDllMiss("Sam Coe likes that.", de, "DLL present tense stays English-only");
	const mixed = dllEnglish();
	mixed.dislikes = "mochte das nicht.";
	expectDll("Sam Coe mochte das nicht.", mixed, "reaction", "disliked", "Sam Coe", "DISLIKED", "A", "DLL localized dislikes");
	expectDllMiss("Sam Coe disliked that.", mixed, "DLL English liked does not claim a disliked line");
	expectDll("This individual is busy.", en, "unavailable", "busy", "", "BUSY", "C", "DLL busy");
	const busy = dllEnglish();
	busy.busy = "Esta persona esta ocupada.";
	expectDll("Esta persona esta ocupada.", busy, "unavailable", "busy", "", "BUSY", "A", "DLL localized busy");
	expectDll("Contusions cured.", en, "medical", "cured", "Contusions", "CURED", "C", "DLL cured");
	expectDll("Prognosis improved (Contusions).", en, "medical", "improved", "Contusions", "IMPROVED", "C", "DLL prognosis");
	expectDll("Severity improved (Poisoning).", en, "medical", "severity", "Poisoning", "LESS SEVERE", "C", "DLL severity");
	expectDll("Attempted to cure Burns.", en, "medical", "attempted", "Burns", "ATTEMPTED", "C", "DLL attempted");
	expectDll("Fractured Limb gained.", en, "medical", "gained", "Fractured Limb", "GAINED", "C", "DLL gained");
	expectDll("Lung Damage became worse.", en, "medical", "worse", "Lung Damage", "WORSE", "C", "DLL worse");
	expectDll("500 credits have been sent home to your parents.", en, "credits", "kid", "", "-500", "C", "DLL kid stuff 500");
	expectDll("1,500 credits have been sent home to your parents.", en, "credits", "kid", "", "-1500", "C", "DLL kid stuff 1500");
	expectDllMiss("about 500 credits have been sent home to your parents.", en, "DLL junk before the amount");
	expectDll("Andreja is now following you.", en, "crew", "follow", "Andreja", "FOLLOWING", "C", "DLL following");
	expectDll("Andreja is no longer following you.", en, "crew", "unfollow", "Andreja", "FOLLOWING", "C", "DLL unfollow");
	expectDll("Andreja is no longer your Active Companion", en, "crew", "uncompanion", "Andreja", "COMPANION", "C", "DLL uncompanion without a period");
	expectDll("Andreja is now your Active Companion.", en, "crew", "companion", "Andreja", "COMPANION", "C", "DLL companion");
	expectDll("Andreja is available to be your Companion", en, "crew", "companion-available", "Andreja", "AVAILABLE", "C", "DLL companion available");
	expectDll("Andreja is no longer available to be your companion.", en, "crew", "companion-unavailable", "Andreja", "AVAILABLE", "C", "DLL longer unavailable suffix wins");
	expectDll("Sarah Morgan considers you a friend.", en, "crew", "friend", "Sarah Morgan", "FRIEND", "C", "DLL friend");
	expectDll("Sam Coe is furious with you and will no longer be your companion.", en, "crew", "furious", "Sam Coe", "FURIOUS", "C", "DLL furious");
	expectDll("Sam Coe is no longer angry with you.", en, "crew", "calm", "Sam Coe", "CALM", "C", "DLL calm is not angry");
	expectDll("Sam Coe is angry with you.", en, "crew", "angry", "Sam Coe", "ANGRY", "C", "DLL angry");
	expectDll("Sarah Morgan has already caught you.", en, "unavailable", "caught", "Sarah Morgan", "CAUGHT", "C", "DLL caught");
	expectDll("The creature is calmed and cannot respond.", en, "unavailable", "calmed", "Creature", "CALMED", "C", "DLL creature");
	expectDll("Sam Coe is calmed and cannot respond.", en, "unavailable", "calmed", "Sam Coe", "CALMED", "C", "DLL npc calmed");
	expectDll("You've been caught pickpocketing.", en, "crime", "caught", "", "CAUGHT", "C", "DLL pickpocket fail");
	expectDll("The owner caught you stealing.", en, "crime", "takeback", "", "CAUGHT", "C", "DLL steal take-back");
	expectDll("You've been caught stealing and the alarm has been raised.", en, "crime", "alarm", "", "ALARM", "C", "DLL steal alarm");
	expectDll("You've been caught tampering with a lock.", en, "crime", "lock", "", "CAUGHT", "C", "DLL lockpick caught");
	expectDll("You're currently trespassing. Residents will become hostile if you stay.", en, "crime", "trespass", "", "TRESPASS", "C", "DLL trespass");
	expectDll("Last witness killed.", en, "crime", "witness", "", "WITNESS", "C", "DLL witness");
	expectDllMiss(new Array(202).join("A"), en, "DLL over the 200 byte cap");
	expectDll("Docking fee: -1890 Credits (Cargo, Tariffs, Fuel, Crew)", en, "credits", "loss", "", "-1,890", "C", "DLL signed credits loss with detail");
	expectDll("Refund: +500 credits", en, "credits", "gain", "", "+500", "C", "DLL signed credits gain any case");
	expectDll("Refund: +500 credits (dock fee)", en, "credits", "gain", "", "+500", "C", "DLL signed credits gain with a parenthetical");
	expectDll("+500 Credits.", en, "credits", "gain", "", "+500", "C", "DLL signed credits with a trailing period");
	expectDll("+500 Credits!", en, "credits", "gain", "", "+500", "C", "DLL signed credits with a trailing bang");
	expectDllMiss("Refund: +500 credits posted", en, "DLL leftover after Credits is not a signed gain");
	expectDllMiss("-1 Credits Card Removed.", en, "DLL item line after Credits is not a signed loss");
	expectDllMiss("Only 100 credits!", en, "DLL unsigned amount is not a signed credits line");
	expectDllMiss("Bring 500 Credits", en, "DLL unsigned Credits sentence stays vanilla");
	expectDllMiss("Fee: +500x Credits", en, "DLL whole-token amount rejects a trailing x");
	expectDllMiss("+500.5.5 Credits", en, "DLL whole-token amount rejects a broken decimal");
	expectDllMiss("Shipment fees: Tariffs Initiated", en, "DLL credits word without an amount stays vanilla");
}

const HZC_GRN = 0x5EE3A1;
const HZC_RED = 0xFF5B5B;
const HZC_CARD_AMB = 0xF2A93B;
function hzcCardTone(kind, sub) {
	if (kind === "credits") return sub === "gain" ? HZC_GRN : HZC_RED;
	if (["gained", "worse", "furious", "caught", "takeback", "lock", "alarm", "bounty-add"].indexOf(sub) >= 0) return HZC_RED;
	if (["improved", "severity", "cured", "friend", "ally", "partner", "calm"].indexOf(sub) >= 0) return HZC_GRN;
	if (["attempted", "unfollow", "follow-unavailable", "uncompanion", "companion-unavailable", "uncrew", "crew-unavailable", "busy", "angry", "trespass", "witness"].indexOf(sub) >= 0) return HZC_CARD_AMB;
	return -1;
}
function hzcCardTitle(kind, sub, name) {
	const n = name == null ? "" : String(name);
	if (kind === "credits") {
		if (sub === "kid") return "KID STUFF";
		if (sub === "bounty") return "BOUNTY PAID";
		return "CREDITS";
	}
	if (kind === "crime") {
		if (sub === "takeback" || sub === "lock") return "CAUGHT";
		if (sub === "caught") return "PICKPOCKET";
		if (sub === "alarm") return "ALARM";
		if (sub === "trespass") return "TRESPASS";
		if (sub === "witness") return "WITNESS";
		if (sub === "bounty-add") return "BOUNTY";
		return "CRIME";
	}
	if (n.length > 0) return n.toUpperCase();
	if (kind === "medical") return "AFFLICTION";
	if (kind === "crew") return "CREW";
	if (sub === "busy") return "BUSY";
	if (sub === "calmed") return "CALMED";
	if (sub === "caught") return "PICKPOCKET";
	return "NOTICE";
}
function hzcCardMatch(kind, sub, name, value) {
	if (kind == null || String(kind).length === 0) return null;
	return { kind: String(kind), sub: String(sub), title: hzcCardTitle(kind, sub, name), tone: hzcCardTone(kind, sub), value: value == null ? "" : String(value) };
}
{
	const en = dllEnglish();
	const crimeRows = [
		["The owner caught you stealing.", "crime", "takeback", "", "CAUGHT", "CAUGHT", HZC_RED, "movie take-back"],
		["You've been caught stealing and the alarm has been raised.", "crime", "alarm", "", "ALARM", "ALARM", HZC_RED, "movie stealattack"],
		["You've been caught tampering with a lock.", "crime", "lock", "", "CAUGHT", "CAUGHT", HZC_RED, "movie lockpick caught"],
		["You're currently trespassing. Residents will become hostile if you stay.", "crime", "trespass", "", "TRESPASS", "TRESPASS", HZC_CARD_AMB, "movie trespass"],
		["Last witness killed.", "crime", "witness", "", "WITNESS", "WITNESS", HZC_CARD_AMB, "movie witness"],
		["You've been caught pickpocketing.", "crime", "caught", "", "CAUGHT", "PICKPOCKET", HZC_RED, "movie pickpocket"]
	];
	for (let i = 0; i < crimeRows.length; i++) {
		const row = crimeRows[i];
		const dll = dllMatch(row[0], en);
		expect(dll && dll.kind === row[1] && dll.sub === row[2] && dll.name === row[3] && dll.value === row[4], row[7] + " DLL payload");
		const movie = hzcCardMatch(dll.kind, dll.sub, dll.name, dll.value);
		expect(movie && movie.kind === "crime" && movie.title === row[5] && movie.tone === row[6] && movie.value === row[4], row[7] + " card " + (movie ? movie.title : "miss"));
	}
	const loss = dllMatch("Docking fee: -1890 Credits (Cargo, Tariffs, Fuel, Crew)", en);
	const lossCard = hzcCardMatch(loss.kind, loss.sub, loss.name, loss.value);
	expect(loss && loss.kind === "credits" && loss.sub === "loss" && loss.value === "-1,890", "signed credits loss payload");
	expect(lossCard && lossCard.title === "CREDITS" && lossCard.tone === HZC_RED && lossCard.value === "-1,890", "signed credits loss uses the credits card");
	const none = dllMatch("Shipment fees: Tariffs Initiated", en);
	expect(none == null, "no-amount fee line has no DLL payload");
	expect(hzcCardMatch("", "info", "", "") == null, "empty kind is not a card");
}
function asFunction(text) {
	const start = text.search(/(?:public|private) function /);
	if (start < 0) return "";
	text = text.slice(start);
	let depth = 0;
	let i = text.indexOf("{");
	if (i < 0) return "";
	for (; i < text.length; i++) {
		if (text[i] === "{") depth++;
		else if (text[i] === "}") {
			depth--;
			if (depth === 0) return text.slice(0, i + 1);
		}
	}
	return text;
}
function asToJs(text) {
	let s = asFunction(text);
	s = s.replace(/for each\(var (\w+):\w+ in /g, "for (var $1 of ");
	s = s.replace(/(?:public|private) function (\w+)\(([^)]*)\)(?:\s*:\s*[\w.*]+)?/g, function (_, name, args) {
		const jsArgs = args.split(",").map(function (a) {
			a = a.trim();
			if (!a) return "";
			const parts = a.split("=");
			const left = parts[0].trim().split(":")[0].trim();
			return parts.length > 1 ? left + "=" + parts.slice(1).join("=") : left;
		}).filter(Boolean);
		return "function " + name + "(" + jsArgs.join(", ") + ")";
	});
	s = s.replace(/var (\w+):[\w.*]+/g, "var $1");
	s = s.replace(/catch\((\w+):\w+\)/g, "catch ($1)");
	s = s.replace(/\bint\(/g, "(0|");
	s = s.replace(/\bgetTimer\(\)/g, "this.getTimer()");
	s = s.replace(/\bHZC_RX_PAIR\b/g, "this.HZC_RX_PAIR");
	s = s.replace(/\bHZC_RX_VIS\b/g, "this.HZC_RX_VIS");
	return s;
}
function installAsFn(host, asText) {
	const js = asToJs(asText);
	const m = js.match(/^function (\w+)\(([^)]*)\)\s*\{([\s\S]*)\}\s*$/);
	const name = (asText.match(/function (\w+)/) || ["", "?"])[1];
	if (!m) {
		expect(false, "live ActionScript " + name + " converts");
		return;
	}
	host[m[1]] = new Function(m[2], m[3]);
}
function hzcClip(text, parent, name) {
	return { name: name, parent: parent, Internal_mc: { Text_tf: { text: text, visible: true }, Background_mc: { visible: true } } };
}
function makeHzcHost(now) {
	const host = {
		HZC_RX_PAIR: 3000,
		HZC_RX_VIS: 4000,
		hzcRx: [],
		hzcRxOff: false,
		hzcIniState: 1,
		hzcCfg: { ReactionCard: 1 },
		Messages_mc: { ShownMessageArray: [], visible: true },
		hzcRxLayer: {},
		hzcRxLast: 0,
		hzcRxDbgOn: false,
		hzcRxErr: "",
		hzcRxWait: [],
		hzcRxGone: [],
		hzcRxFail: 0,
		now: now || 1000,
		shown: [],
		dropped: [],
		getTimer: function () { return this.now; },
		hzcRxSlot: function () { return true; },
		hzcMsgLayout: function () {},
		hzcRxLink: function () {},
		hzcRxPlace: function () {},
		hzcRxStack: function () {},
		hzcRxDbgScan: function () {},
		hzcRxHit: function () {},
		hzcRxShow: function (e) { this.shown.push(e); },
		hzcRxDrop: function (e) { this.dropped.push(e); },
		hzcRxRemember: function () {},
		hzcRxWhyText: function () { return "cards off: cards are off"; }
	};
	host.Messages_mc.parent = host.Messages_mc;
	installAsFn(host, fnBody("private function hzcRxTrimC", "public function hzcRxSelfTest"));
	installAsFn(host, fnBody("private function hzcRxNorm", "private function hzcRxTrimC"));
	installAsFn(host, fnBody("private function hzcRxKey", "private function hzcRxOpenKey"));
	installAsFn(host, fnBody("private function hzcRxOpenKey", "private function hzcRxOpen"));
	installAsFn(host, fnBody("private function hzcRxFind", "private function hzcRxOne"));
	installAsFn(host, fnBody("private function hzcRxItemTx", "private function hzcRxReveal"));
	installAsFn(host, fnBody("private function hzcRxOn", "private function hzcRxVerb"));
	installAsFn(host, fnBody("private function hzcRxSubK", "public function hzcCardPush"));
	installAsFn(host, fnBody("private function hzcRxOne", "private function hzcRxWhyText"));
	installAsFn(host, fnBody("private function hzcRxReveal", "private function hzcRxCover"));
	installAsFn(host, fnBody("private function hzcRxClaim", "private function hzcRxLink"));
	installAsFn(host, fnBody("public function hzcCardPush", "public function hzcRxWhy"));
	installAsFn(host, fnBody("private function hzcRxStep", "private function hzcRxStack"));
	return host;
}
{
	const line = "The owner caught you stealing.";
	const host = makeHzcHost(1000);
	const m = host.Messages_mc;
	const oldClip = hzcClip(line, null, "old15");
	const nextClip = hzcClip(line, m, "new15");
	m.ShownMessageArray = [nextClip];
	const take = { st: 1, linked: true, it: oldClip, key: host.hzcRxKey(line), vis: 0, covered: true, rebound: false, reboundAt: 0, n: "", k: -1, kind: "crime", sub: "takeback", value: "CAUGHT", tx: line };
	host.hzcRx = [take];
	host.hzcRxStep();
	expect(take.it === nextClip && take.linked === true && take.rebound === true, "a later take-back clip keeps the card");
	expect(oldClip.Internal_mc.Text_tf.visible === true && take.covered === false, "rebind uncovers the old clip");
	const before = host.hzcRx.length;
	expect(host.hzcCardPush("crime", "takeback", "", "CAUGHT", line) === "queued" && host.hzcRx.length === before && take.rebound === false, "a rebound push merges once and clears the flag");
	expect(host.hzcCardPush("crime", "takeback", "", "CAUGHT", line) === "queued" && host.hzcRx.length === before + 1, "a third identical take-back still gets its own card");

	const pendingHost = makeHzcHost(1000);
	const pm = pendingHost.Messages_mc;
	const oldA = hzcClip("alarm line", null, "oldA");
	const newA = hzcClip("alarm line", pm, "newA");
	pm.ShownMessageArray = [newA];
	const linked = { st: 1, linked: true, it: oldA, key: pendingHost.hzcRxKey("alarm line"), vis: 0, covered: false, rebound: false };
	const pending = { st: 1, linked: false, it: null, key: pendingHost.hzcRxKey("alarm line"), vis: 0, covered: false, rebound: false };
	pendingHost.hzcRx = [linked, pending];
	expect(pendingHost.hzcRxClaim(pm.ShownMessageArray, linked.key) == null, "claim skips when a card of that text is still pending");
	expect(pendingHost.hzcRxClaim(pm.ShownMessageArray, pendingHost.hzcRxKey("other")) == null, "claim misses a different line");

	const mergeSrc = fnBody("public function hzcCardPush", "public function hzcRxWhy");
	const mergeLoop = "for each(var eR:Object in this.hzcRx)\n            {\n               if(eR == null || eR.key != key || eR.rebound != true) { continue; }\n               var rage:int = now - int(eR.reboundAt);\n               if(rage >= 0 && rage < HZC_RX_PAIR) { eR.rebound = false; return \"queued\"; }\n            }";
	expect(mergeSrc.indexOf(mergeLoop) >= 0, "the live push contains the one-shot merge");
	const noMergeHost = makeHzcHost(1000);
	installAsFn(noMergeHost, mergeSrc.replace(mergeLoop, ""));
	const mergeCard = { st: 1, linked: true, it: nextClip, key: noMergeHost.hzcRxKey(line), rebound: true, reboundAt: 900, n: "", k: -1, kind: "crime", sub: "takeback", value: "CAUGHT", tx: line };
	noMergeHost.hzcRx = [mergeCard];
	const noMergeLen = noMergeHost.hzcRx.length;
	noMergeHost.hzcCardPush("crime", "takeback", "", "CAUGHT", line);
	expect(noMergeHost.hzcRx.length === noMergeLen + 1, "removing the merge adds a second card");

	const claimSrc = fnBody("private function hzcRxClaim", "private function hzcRxLink");
	const guard = "if(this.hzcRxOpenKey(key) != null) { return null; }";
	expect(claimSrc.indexOf(guard) >= 0, "the live claim contains the pending-card guard");
	const invHost = makeHzcHost(1000);
	installAsFn(invHost, claimSrc.replace(guard, "if(this.hzcRxOpenKey(key) == null) { return null; }"));
	const invM = invHost.Messages_mc;
	const invOld = hzcClip("alarm line", null, "oldB");
	const invNew = hzcClip("alarm line", invM, "newB");
	invM.ShownMessageArray = [invNew];
	invHost.hzcRx = [
		{ st: 1, linked: true, it: invOld, key: invHost.hzcRxKey("alarm line") },
		{ st: 1, linked: false, it: null, key: invHost.hzcRxKey("alarm line") }
	];
	expect(invHost.hzcRxClaim(invM.ShownMessageArray, invHost.hzcRxKey("alarm line")) === invNew, "inverting the claim guard steals a pending line");
}

if (failed) {
	console.error(failed + " failed");
	process.exit(1);
}
console.log("reaction match: " + (RX1.length + RX2.length) + " matcher cases, plus lifetime, pairing, and miss harnesses, all passed");
