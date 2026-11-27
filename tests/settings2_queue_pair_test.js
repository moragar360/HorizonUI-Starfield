// Settings 2.0: QueueKey emits ch: then bind: for one letter; FlushInputToHud
// invokes hzSettingsKey once per queued string. Find and hex must append only
// ch: and swallow bind:, or search becomes "vV" and hex doubles (a -> AA).
// Run: node tests/settings2_queue_pair_test.js
// Author: Moragar. Last modified: 2026-11-26.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.resolve(__dirname, "..");
const as = fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n");
const mainCpp = fs.readFileSync(path.join(root, "src", "main.cpp"), "utf8").replace(/\r\n/g, "\n");

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
function fnBodyCpp(src, sig) {
	const i = src.indexOf(sig);
	if (i < 0) throw new Error("missing " + sig);
	const b = src.indexOf("{", i);
	let d = 0;
	for (let p = b; p < src.length; p++) {
		if (src[p] === "{") d++;
		else if (src[p] === "}" && --d === 0) return src.slice(b, p + 1);
	}
	throw new Error("unbalanced " + sig);
}
function toJs(src, name) {
	const f = fnText(src, name);
	const params = f.params.split(",").map((p) => p.trim()).filter(Boolean).map((p) => p.split(":")[0].trim());
	const b = f.body
		.replace(/var (\w+):[\w.*]+/g, "let $1")
		.replace(/catch\((\w+):\w+\)/g, "catch($1)")
		.replace(/int\(/g, "(");
	return new Function(...params, b);
}

const queueKey = fnBodyCpp(mainCpp, "void QueueKey(UINT a_vk, bool a_down)");
expect(/CharCode\(a_vk\)/.test(queueKey) && /VkToBind\(a_vk\)/.test(queueKey), "QueueKey builds CharCode (ch:) and VkToBind");
expect(/g_keyQueue\.emplace_back\(code \? std::string\(code\) : chr\)/.test(queueKey)
	&& /g_keyQueue\.emplace_back\(std::string\("bind:"\) \+ bind\)/.test(queueKey),
	"one letter key enqueues ch: then bind: (the pair FlushInputToHud drains)");
const flushFn = fnBodyCpp(mainCpp, "void FlushInputToHud(bool a_open)");
expect(/keys\.swap\(g_keyQueue\)/.test(flushFn) && /HudInvoke\("hzSettingsKey"/.test(flushFn),
	"FlushInputToHud invokes hzSettingsKey once per queued string");

function queueKeyPair(ch, bindName) {
	return ["ch:" + ch, "bind:" + bindName];
}
function flushInputToHud(host, keys) {
	for (const k of keys) host.hzSettingsKey(k);
}
function makeHost() {
	const host = {
		hzSetIsOpen: true,
		hzPopLayers: null,
		hzArrange: false,
		hzQmCap: "",
		hz35Kb: false,
		hz51Pad: false,
		hzVehPad: 0,
		hzSetFindOn: false,
		hzSetFind: "",
		hzSetFindHi: 0,
		hzSetFocus: 0,
		hzSetGlowK: "",
		hzSetHexK: "",
		hzSetHexBuf: "",
		hzSetHexPrev: -1,
		hzSetDrop: -1,
		hzSetTab: 0,
		hzSetRow: 0,
		hzSetScroll: 0,
		hzSetPage: 0,
		draws: 0,
		hzSetDraw() { this.draws++; },
		hzPopKey() {},
		hzArrKey() {},
		hzQmCapKey() {},
		hz37Key() { return false; },
		hzSetRows() { return [{ k: "ShowVitals", t: "b" }]; },
		hz30RowStep() {},
		hzSetChange() {},
		hzHex(n) { return "#" + Number(n).toString(16).toUpperCase(); },
		hz51HexCommit() {},
		hz51FindHits() { return []; },
		hz51GotoHit() {}
	};
	host.hz51TypeChar = toJs(as, "hz51TypeChar").bind(host);
	host.hz51NotePad = toJs(as, "hz51NotePad").bind(host);
	host.hz51Key = toJs(as, "hz51Key").bind(host);
	host.hzSettingsKey = toJs(as, "hzSettingsKey").bind(host);
	return host;
}

const vPair = queueKeyPair("v", "V");
expect(vPair[0] === "ch:v" && vPair[1] === "bind:V" && vPair.length === 2, "letter V is the real QueueKey pair ch:v then bind:V");

const search = makeHost();
search.hzSetFindOn = true;
flushInputToHud(search, vPair);
expect(search.hzSetFind === "v", "flush ch:v + bind:V while find is on stores v, not vV (got " + JSON.stringify(search.hzSetFind) + ")");
expect(search.draws >= 1, "find flush still redraws after each hzSettingsKey");

const searchBindOnly = makeHost();
searchBindOnly.hzSetFindOn = true;
flushInputToHud(searchBindOnly, ["bind:V"]);
expect(searchBindOnly.hzSetFind === "", "bind:V alone while find is on does not append");

const aPair = queueKeyPair("a", "A");
const hex = makeHost();
hex.hzSetHexK = "Accent";
hex.hzSetHexBuf = "";
flushInputToHud(hex, aPair);
expect(hex.hzSetHexBuf === "A", "flush ch:a + bind:A while hex is on stores A, not AA (got " + JSON.stringify(hex.hzSetHexBuf) + ")");

const hexBindOnly = makeHost();
hexBindOnly.hzSetHexK = "Accent";
hexBindOnly.hzSetHexBuf = "";
flushInputToHud(hexBindOnly, ["bind:A"]);
expect(hexBindOnly.hzSetHexBuf === "", "bind:A alone while hex is on does not append");

const nav = makeHost();
flushInputToHud(nav, ["hzpad", "down"]);
expect(nav.hz51Pad === true, "hzpad + D-pad down through the flush path switches the hint row to controller");

if (failed) { console.error(failed + " failed, " + passed + " passed"); process.exit(1); }
console.log(passed + " passed");
