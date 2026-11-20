// Hazard Status card soak direction tests (0.43.3.1). Run: node tests/hazard_soak_test.js
// Runs the production hzHsFx and hzHsSync (types stripped) on a small host and checks the source:
//  green while the soak moves back toward its value when the hazard appeared, red while it moves away,
//  ambiguous (no change, first sample, NaN) = red, a switch needs 2 updates in a row (no single-sample toggle),
//  the baseline resets when a new hazard appears, and the change stays inside the card (no timer / frame / search /
//  allocation, the hzOnEnvEffects affliction loop untouched).
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
function fnText(src, name) {
	const re = new RegExp("(?:private|public) function " + name + "\\(([^)]*)\\)[^{]*\\{");
	const m = re.exec(src);
	if (!m) throw new Error("missing function " + name);
	const brace = m.index + m[0].length - 1;
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { params: m[1], body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function toJs(name) {
	const f = fnText(as, name);
	const params = f.params.split(",").map((p) => p.trim().split(":")[0].split("=")[0].trim()).filter(Boolean);
	const body = f.body
		.replace(/for each\(var (\w+):[\w*]+ in /g, "for (let $1 of ")
		.replace(/var (\w+):[\w*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/\bHZ_HS_(\w+)/g, "this.HZ_HS_$1");
	return new Function(...params, body);
}
const CONST = {};
{ const re = /private static const (HZ_HS_\w+):\w+ = ([^;]+);/g; let m; while ((m = re.exec(as))) CONST[m[1]] = /^"/.test(m[2]) ? JSON.parse(m[2]) : Number(m[2]); }
const FIELDS = {};
{ const re = /private var (hzHsSk\w+):(\w+) = ([^;]+);/g; let m; while ((m = re.exec(as))) FIELDS[m[1]] = m[3] === "NaN" ? NaN : m[3] === "false" ? false : m[3] === "true" ? true : Number(m[3]); }

function makeHost() {
	const h = Object.assign({
		hzHsOn: true, hzHsCardOn: true, hzArrange: false, hz43EnvLang: "en", HorizonHazard_mc: {},
		hzHsSeq: 0, hzHsCat: 0, hzHsCatSeq: 0, hzHsWord: "HAZARD", hzHsAlSeq: 0, hzHsAlPos: false, hzHsAlTxt: "", hzHsGrn: false, hzHsHoldT: -1, now: 1000,
		hz26Now() { return this.now; },
		hzHsSt: -1, hzHsSrc: -1, hzHsSrcTxt: null, hzHsW: -1, hzHsCm: -1, hzHsShown: false, draws: 0, sts: [],
		hzHsWant() { return this.hzHsOn && this.hzHsCardOn && this.HorizonHazard_mc != null; },
		hzHsMaxW() { return 300; }, hzHsCmp() { return 0; },
		hzHsDraw() { this.draws++; this.hzHsCm = this.hzHsCmp(); this.sts.push(this.hzHsSt); }, hzShow() { }, hzHsVan() { },
	}, CONST, FIELDS);
	h.hzHsFx = toJs("hzHsFx").bind(h);
	h.hzHsSync = toJs("hzHsSync").bind(h);
	h.hzHsHoldTick = toJs("hzHsHoldTick").bind(h);
	return h;
}
const HZ = [{ sEffectIcon: "HazardEffect_Radiation" }];
const fx = (h, soak) => h.hzHsFx(HZ, 1, "RADIATION", soak);
const none = (h) => h.hzHsFx([], 0, "HAZARD", 0);
const run = (h, list) => list.map((s) => { fx(h, s); return h.hzHsSt; });
const RED = 1, GRN = 2;

expect(CONST.HZ_HS_SKRUN === 2, "a color switch needs 2 updates in a row");
expect(CONST.HZ_HS_SKEPS > 0 && CONST.HZ_HS_SKEPS <= 0.001, "a tiny soak step (rounding) counts as no change");
expect(Number.isNaN(FIELDS.hzHsSkB) && Number.isNaN(FIELDS.hzHsSkL) && FIELDS.hzHsSkRun === 0 && FIELDS.hzHsSkGrn === false, "starts with no baseline, red");

// away from the baseline: red
{
	const h = makeHost();
	const s = run(h, [0.5, 0.6, 0.7, 0.8]);
	expect(s.every((v) => v === RED), "the hazard appears and the soak moves away: red the whole time");
	expect(h.hzHsSkB === 0.5, "the baseline is the soak when the hazard appeared");
}
// back toward it: green after 2 updates
{
	const h = makeHost();
	run(h, [0.5, 0.6, 0.7]);
	fx(h, 0.65);
	expect(h.hzHsSt === RED, "one step back toward the baseline: still red (no single-sample toggle)");
	fx(h, 0.6);
	expect(h.hzHsSt === GRN && h.hzHsSrc === 3, "two steps back toward the baseline: green, SUIT PROTECTION RESTORING");
	fx(h, 0.55);
	expect(h.hzHsSt === GRN, "keeps going back: green stays");
	fx(h, 0.55);
	expect(h.hzHsSt === GRN, "one no-change update: green stays (no single-sample toggle)");
	fx(h, 0.55);
	expect(h.hzHsSt === RED, "two no-change updates: ambiguous = red");
}
// the other sign: the soak falls while draining
{
	const h = makeHost();
	expect(run(h, [0.5, 0.4, 0.3]).every((v) => v === RED), "other sign: the soak falls away from the baseline: red");
	expect(run(h, [0.35, 0.4]).join() === [RED, GRN].join(), "other sign: it rises back toward the baseline: green after 2 updates");
}
// never flicker: alternating directions never switch
{
	const h = makeHost();
	const s = run(h, [0.5, 0.6, 0.55, 0.65, 0.6, 0.7, 0.65, 0.75]);
	expect(s.every((v) => v === RED), "alternating away / toward: never green (each toward vote is reset by the next)");
	const g = makeHost();
	run(g, [0.5, 0.8, 0.7, 0.6]);
	const s2 = run(g, [0.65, 0.55, 0.6, 0.52, 0.56, 0.51]);
	expect(g.sts.filter((v, i, a) => i > 0 && v !== a[i - 1]).length === 1 && s2.every((v) => v === GRN), "green, then alternating: stays green, one switch in total");
}
// ambiguous = red
{
	const h = makeHost();
	expect(run(h, [0.5, 0.5, 0.5, 0.5]).every((v) => v === RED), "no change at all: red");
	const t = makeHost();
	expect(run(t, [0.5, 0.6, 0.55, 0.55 - 0.00005, 0.55 - 0.0001]).every((v) => v === RED), "steps below the threshold are no change: red");
	const n = makeHost();
	expect(run(n, [NaN, 0.6, 0.5, 0.4]).join() === [RED, RED, RED, RED].join(), "no number when the hazard appeared: the first number is the baseline, moving away is red");
	const m = makeHost();
	run(m, [0.5, 0.8, 0.7, 0.6]);
	expect(m.hzHsSt === GRN, "(setup) green");
	expect(run(m, [NaN, NaN]).join() === [GRN, RED].join(), "unknown soak twice: red (one NaN alone does not toggle)");
}
// a new hazard resets the baseline
{
	const h = makeHost();
	run(h, [0.5, 0.8, 0.7, 0.6]);
	expect(h.hzHsSt === GRN, "(setup) green");
	none(h);
	expect(h.hzHsSt === GRN, "0.43.3.2: the hazard left the list: green hold (was hidden at once)");
	h.now += h.HZ_HS_HOLD_MS; h.hzHsHoldTick();
	expect(h.hzHsSt === 0, "0.43.3.2: the hold ended on the existing clock slot: hidden");
	fx(h, 0.2);
	expect(h.hzHsSt === RED && h.hzHsSkB === 0.2 && h.hzHsSkRun === 0 && h.hzHsSkGrn === false, "the hazard appears again: red, new baseline, counters reset");
	expect(run(h, [0.1, 0.0]).every((v) => v === RED), "away from the new baseline: red");
}
// the newest event sets the color
{
	const h = makeHost();
	run(h, [0.5, 0.8, 0.7, 0.6]);
	h.hzHsAlPos = false; h.hzHsAlSeq = ++h.hzHsSeq; h.hzHsSync();
	expect(h.hzHsSt === RED, "a newer negative alert turns the green card red");
	fx(h, 0.55);
	expect(h.hzHsSt === RED, "the soak keeps going back (no switch): the newer alert still wins");
	run(h, [0.6, 0.7]);
	h.hzHsAlPos = true; h.hzHsAlSeq = ++h.hzHsSeq; h.hzHsSync();
	expect(h.hzHsSt === GRN, "a newer positive alert is green");
	expect(run(h, [0.75]).join() === [GRN].join(), "one soak update does not override it");
	h.hzHsSkGrn = true; h.hzHsSkRun = 0;
	expect(run(h, [0.8, 0.85]).join() === [GRN, RED].join(), "a soak switch to red (2 updates away) is newer than the alert: red");
}
// diff-and-skip: the same state draws once
{
	const h = makeHost();
	run(h, [0.5, 0.6, 0.7, 0.8, 0.9]);
	expect(h.draws === 1, "five red updates: one draw");
}
// source rules
{
	const fxb = fnText(as, "hzHsFx").body.replace(/\/\/.*$/gm, "");
	expect(!/Timer|setTimeout|setInterval|ENTER_FRAME|enterFrame|getTimer|getChildByName|hzFindByName|hzFrameN|\bnew\b|\[\]|\{\s*\}|Array\(/.test(fxb.replace(/catch\(\w+:\w+\) \{ \}/g, "")), "hzHsFx: no timer, frame, tree search or allocation");
	const env = fnText(as, "hzOnEnvEffects").body;
	expect(/try \{ this\.hzHsFx\(a,n,word,soak\); \} catch\(eHs:Error\) \{ \}/.test(env), "hzOnEnvEffects passes the soak to the card (one call line)");
	expect(env.indexOf('if(ic == "HazardEffect_RestoreSoak") { continue; }') > 0 && /n\+\+;\n\s*var li:String = ic\.toLowerCase\(\);/.test(env), "the effects / word loop is unchanged");
	const sy = fnText(as, "hzHsSync").body;
	expect(/this\.hzHsCat == 2 \? \(this\.hzHsSkGrn \? 2 : 1\) : 2/.test(sy), "hzHsSync: a listed hazard is green only while the soak goes back");
}

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("hazard soak: " + passed + " ok, all passed");
