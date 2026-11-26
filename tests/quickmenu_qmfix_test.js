// 0.43.5 Quick Menu in-game bugs (extended assign, Horizon cards, CROSS+BARS layout, F11 grey).
// Source-read pins. Run: node tests/quickmenu_qmfix_test.js
// Author: Moragar.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.resolve(__dirname, "..");
const rd = (p) => fs.readFileSync(path.join(root, p), "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(s, name) {
	const re = new RegExp("(?:private|public|protected) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(s);
	if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1;
	let depth = 0;
	for (let p = brace; p < s.length; p++) {
		if (s[p] === "{") depth++;
		else if (s[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: s.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
const codeOnly = (s) => s.replace(/\/\/.*$/gm, "");

const qm = rd("actionscript/favorites/hzq_main.as");
const hdr = rd("src/hz_quickslots.h");
const game = rd("src/hz_quickslots_game.h");
const hud = rd("actionscript/horizon_block.as");

// ---- 1. assign handoff: form ID extra, NamesMatch, no name-only refuse for instance prefixes ----
{
	const pick = fnText(qm, "hzqExtPick").body;
	expect(/this\.hzqExtFormId\(this\.AssignedItem\)/.test(pick) && /this\.hzqExtHex\(fid\)/.test(pick) && /"I\|"/.test(pick),
		"1: the assign extra is I|<formId>|<name> (or P|<name>)");
	expect(/this\.hzqExtFetch\(\)/.test(pick) && /this\.hzqExtDraw\(\)/.test(pick),
		"1: a successful assign fetches the payload and redraws before the menu closes");
	expect(/o\.formId = id/.test(hdr) && /ParseFormId\(raw\.substr\(0, bar\)\)/.test(hdr),
		"1: ParseAssignExtra reads I|0xFORM|name");
	expect(/QmReadInvAssign\(/.test(game) && /form = ex\.formId/.test(game) && /QmFormByName\(ex\.name/.test(game),
		"1: QmAssign prefers InventoryMenu handle/FormID, then the movie form hint, then the inventory name walk");
	{
		const assign = game.slice(game.indexOf("std::string QmAssign("), game.indexOf("std::string QmHandleCmd("));
		expect(/AssignIdMatchesName\(ex\.name/.test(assign) && /return "missing"/.test(assign)
			&& /QmInvObjectFormId\(inv, handle\)/.test(assign)
			&& /strcmp\(invSel\.src, "inv"\)/.test(assign) && /NamesMatch\(ex\.name, formName\)/.test(assign)
			&& /NamesMatch\(ex\.name, invSel\.name\)/.test(assign),
			"1: InventoryMenu identity NamesMatch the assigned name; a movie-only ID still NamesMatch; missing if lookup fails");
	}
	expect(/inline bool NamesMatch\(/.test(hdr) && /shortn\.size\(\) < 5/.test(hdr),
		"1: NamesMatch requires a 5-letter suffix so Med Pack vs Pack is not the same item");
	expect(/NamesMatch\(a\.base, a_curName\)/.test(hdr) && /NamesMatch\(a\.name, a_curName\)/.test(hdr),
		"1: AssignmentCheck uses NamesMatch on base and display name (instance prefix is not a load-order refuse)");
	expect(/PickFormByDisplayName\(a_name/.test(game) && /shortest/.test(hdr) && /never the longest/.test(hdr),
		"1: QmFormByName uses exact then shortest NamesMatch prefix, never the longest");
	expect(/t\[0\] != '0'/.test(hdr) && /hex\.size\(\) > 8/.test(hdr) && /Dead Drop/.test(hdr),
		"1: ParseFormId requires 0x, 1-8 hex digits, fully consumed (Dead Drop is not 0xDEAD)");
	const fid = fnText(qm, "hzqExtFormId").body;
	expect(/it\.uFormID/.test(fid) && !/uHandleID/.test(fid),
		"1: hzqExtFormId reads uFormID and never treats uHandleID as a form ID");
	expect(/QmReadInvAssign\(/.test(game) && /ItemList_mc/.test(game) && /uHandleID/.test(game),
		"1: QmAssign reads InventoryMenu's selected handle / FormID instead of trusting the movie name");
}

// ---- 2 / 3. Horizon card style and a closed selection border ----
{
	const drw = fnText(qm, "hzqExtDraw").body;
	expect(/this\.hzqPanel\(g,-29,-29,58,58,8,dim && !sel \? 0\.6 : 1\)/.test(drw),
		"2: extended slots use hzqPanel (CardOpacity / CardBgOpacity) like the 1-12 Horizon cards");
	expect(/g\.beginFill\(acc,0\.13\)/.test(drw) && /this\.hzqKeycap\(g,-24,-24,kw,kh/.test(drw),
		"2: selected fill and keycap match hzqCard");
	expect(/function hzqRingDraw/.test(qm) && /drawRoundRect\(x - 26,y - 26,52,52,14,14\)/.test(fnText(qm, "hzqRingDraw").body)
		&& /s\.name = "hzqRing"/.test(fnText(qm, "hzqRingEnsure").body) && /s\.mouseEnabled = false/.test(fnText(qm, "hzqRingEnsure").body),
		"3: accent hover/focus stroke is drawn on a menu-level overlay (not clipped by Entry/Catcher)");
	expect(/function hzqUnclip/.test(qm) && /d\.mask = null/.test(fnText(qm, "hzqUnclip").body) && /scrollRect = null/.test(fnText(qm, "hzqUnclip").body),
		"3: Entry / Catcher mask and scrollRect are cleared so the overlay ring is visible on all four sides");
	expect(/this\.hzqSet\(o\.n,this\.hzqUC\(label\),13,/.test(drw) && /this\.hzqSet\(o\.k,klab,13,/.test(drw),
		"2: extended text uses hzqSet at 13 px (Exo 2 through hzqFace)");
	expect(/this\.hzqPanel\(ag,-29,-29,58,58,8,0\.6\)/.test(drw),
		"2: the ADD tile uses the same Horizon panel");
}

// ---- 4 / 6. CROSS+BARS: authored T, do not move 1-12, bars under the T ----
{
	expect(/HZQ_REST_X:Array = \[-195\.75,-120\.8,-40\.05,40,120\.8,195\.8,0,0,0,0,0,0\]/.test(qm),
		"4: authored Entry rest X matches vanilla 1.16.244");
	expect(/HZQ_T_BOTTOM:Number = 268\.75/.test(qm) && /HZQ_T_CX:Number = 0/.test(qm),
		"4: authored T box (Entry_11 + catcher) so bars sit under the T");
	const tbox = codeOnly(fnText(qm, "hzqExtTBox").body);
	expect(!/getBounds/.test(tbox) && /HZQ_T_BOTTOM/.test(tbox),
		"4 / perf: hzqExtTBox is authored constants, not live getBounds");
	const rem = codeOnly(fnText(qm, "hzqExtRemember").body);
	expect(/HZQ_REST_X/.test(rem) && !/\.x/.test(rem.replace(/HZQ_REST_X/g, "")) && !/getBounds/.test(rem),
		"4: homes are authored rest, never captured during the Open animation");
	const place = codeOnly(fnText(qm, "hzqExtPlace").body);
	expect(/if\(bars\)/.test(place) && /ev\.x = x0 \+ col \* pitch/.test(place) && /ev\.y = y0 \+ row \* pitch/.test(place) && !/getBounds/.test(place),
		"4 / 6: BARS sets clip x/y to the cell center (center-registered; no live getBounds)");
	expect(/else if\(this\.hzqExtMoved\)/.test(place) && /er\.x = Number\(this\.hzqExtHome/.test(place),
		"4 / 6: CROSS restores Entry_0..11 when hzqExtMoved is set");
	expect(/CenterClip_mc\.visible = !bars/.test(place),
		"6: CROSS+BARS keeps the vanilla cross; BARS hides it");
	const rest = codeOnly(fnText(qm, "hzqExtRestore").body);
	expect(/hzqExtMoved/.test(rest) && /CenterClip_mc\.visible = true/.test(rest),
		"4: restore only puts 1-12 back after BARS moved them");
	const bld = fnText(qm, "hzqExtBuildClips").body;
	expect(/y = box\.b \+ 12 \+ 29 \+ row \* pitch/.test(bld),
		"6: CROSS+BARS places 13-24 under the T (tBottom + gap + box/2)");
	expect(!/ENTER_FRAME|enterFrame|new Timer|setInterval|setTimeout/.test(qm.slice(qm.indexOf("0.43.5 Extended Mode"))),
		"perf: Extended Mode still has no enterFrame or timer");
}

// ---- 5. F11: Extended looks off when HORIZON STYLE is off; saved value is not written ----
{
	const rows = fnText(hud, "hz34CardRows").body;
	expect(/qmHzOn/.test(rows) && /!qmHzOn && qmk != "QuickMenuHorizon"/.test(rows),
		"5: when HORIZON STYLE is off, Extended rows lock");
	expect(/Extended Mode needs HORIZON STYLE\. Your saved setting is kept\./.test(rows),
		"5: the under-row note says the saved setting is kept");
	expect(!/hzQmExt\s*=/.test(rows) && !/hzSetPend\.\w+\s*=(?!=)/.test(rows),
		"5: the lock does not write the saved Extended value");
	expect(/this\.hzQmOn !== false/.test(rows),
		"5: a missing hzQmOn defaults to on (m09 host without the flag stays unlocked)");
	expect(/hzSetPend\.QuickMenuHorizon !== undefined/.test(rows) && /qmHzOn = this\.hzSetPend\.QuickMenuHorizon === true/.test(rows),
		"5: toggling pending HORIZON STYLE relocks Extended rows at once");
}

// ---- perf pins: change-driven draw, clips built once, bind still edge-only ----
{
	const ens = fnText(qm, "hzqExtEnsureClips").body;
	const bld = fnText(qm, "hzqExtBuildClips").body;
	expect(/if\(this\.hzqExtPool == null\)/.test(ens) && !/new Sprite|addEventListener/.test(bld),
		"perf: hold / pool / ADD are built once; layout only moves clips");
	expect(/if \(!g_qmExtOn\.load/.test(game) && /if \(g_qmBound\.load/.test(game) && /CreateFunction/.test(game),
		"perf: PollFavorites still early-outs when Extended is off or already bound");
}

console.log("quickmenu_qmfix_test " + (failed ? "FAILED" : "passed") + " (" + passed + " ok, " + failed + " FAIL)");
process.exit(failed ? 1 : 0);
