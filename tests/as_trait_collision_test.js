// Purpose: fail if a movie class declares a var/const and a function with the
// same name (duplicate ABC trait). Scaleform then treats this.name as the
// slot, so this.name(...) is "value is not a function" and HUD init can die
// before addChild. 228f3e7 named the compass middot hzDot, colliding with the
// status-dot painter. Run: node tests/as_trait_collision_test.js
// Author: Moragar. Last modified: 2026-11-28.
"use strict";
const fs = require("fs");
const path = require("path");
const { readBase, report } = require("./lib/git_base");
const root = path.join(__dirname, "..");

let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}

function stripAs(src) {
	let out = "";
	for (let i = 0; i < src.length; i++) {
		const c = src[i];
		const n = src[i + 1];
		if (c === "/" && n === "/") {
			out += "  ";
			i += 2;
			while (i < src.length && src[i] !== "\n") { out += " "; i++; }
			if (i < src.length) out += "\n";
			continue;
		}
		if (c === "/" && n === "*") {
			out += "  ";
			i += 2;
			while (i < src.length && !(src[i] === "*" && src[i + 1] === "/")) {
				out += src[i] === "\n" ? "\n" : " ";
				i++;
			}
			if (i < src.length) { out += "  "; i++; }
			continue;
		}
		if (c === "\"" || c === "'") {
			const q = c;
			out += " ";
			i++;
			while (i < src.length && src[i] !== q && src[i] !== "\n") {
				if (src[i] === "\\") { out += "  "; i += 2; continue; }
				out += " ";
				i++;
			}
			if (i < src.length && src[i] !== "\n") { out += " "; }
			else if (i < src.length) out += "\n";
			continue;
		}
		out += c;
	}
	return out;
}

const DECL = /^(?:public|private|protected|internal)\s+(?:override\s+)?(?:static\s+)?(?:final\s+)?(?:(var|const)\s+([A-Za-z_$][\w$]*)|function\s+(?:(get|set)\s+)?([A-Za-z_$][\w$]*)\s*\()/;

function lineAt(src, index) {
	let n = 1;
	for (let i = 0; i < index && i < src.length; i++) if (src[i] === "\n") n++;
	return n;
}

function collectTraits(src) {
	const s = stripAs(src.replace(/\r\n/g, "\n"));
	const classSeen = /\bclass\s+[A-Za-z_$]/.test(s);
	const memberDepth = classSeen ? 1 : 0;
	const slots = Object.create(null);
	const methods = Object.create(null);
	let depth = 0;
	for (let i = 0; i < s.length; i++) {
		const ch = s[i];
		if (ch === "{") { depth++; continue; }
		if (ch === "}") { depth--; continue; }
		if (depth !== memberDepth) continue;
		if (!/[A-Za-z_]/.test(ch)) continue;
		const m = DECL.exec(s.slice(i, i + 160));
		if (!m) continue;
		const kind = m[1] || (m[3] ? m[3] : "function");
		const name = m[2] || m[4];
		const rec = { name: name, kind: kind, line: lineAt(src.replace(/\r\n/g, "\n"), i) };
		if (kind === "var" || kind === "const") {
			if (!slots[name]) slots[name] = [];
			slots[name].push(rec);
		} else {
			if (!methods[name]) methods[name] = [];
			methods[name].push(rec);
		}
		i += m[0].length - 1;
	}
	return { slots: slots, methods: methods };
}

function collisionsOf(src) {
	const t = collectTraits(src);
	const hits = [];
	for (const name of Object.keys(t.slots)) {
		if (!t.methods[name]) continue;
		hits.push({
			name: name,
			slots: t.slots[name],
			methods: t.methods[name]
		});
	}
	return hits;
}

function listLiveAs(dir, out) {
	for (const ent of fs.readdirSync(dir, { withFileTypes: true })) {
		if (ent.name === "imp") continue;
		const p = path.join(dir, ent.name);
		if (ent.isDirectory()) { listLiveAs(p, out); continue; }
		if (!/\.as$/i.test(ent.name)) continue;
		if (/^HUDMenu_1/i.test(ent.name)) continue;
		out.push(p);
	}
}

if (require.main === module) {
	const BAD = [
		"      private var hzDot:String = \"\\u00B7\";",
		"      private function hzDot(d:Sprite, col:uint) : void",
		"      {",
		"      }"
	].join("\n");
	const GOOD = [
		"      private var hzMid:String = \"\\u00B7\";",
		"      private function hzDot(d:Sprite, col:uint) : void",
		"      {",
		"      }"
	].join("\n");

	const badHits = collisionsOf(BAD);
	expect(badHits.length === 1 && badHits[0].name === "hzDot",
		"fixture flags a var and a function named hzDot");
	expect(collisionsOf(GOOD).length === 0,
		"fixture allows hzMid string next to function hzDot");

	const asDir = path.join(root, "actionscript");
	const files = [];
	listLiveAs(asDir, files);
	expect(files.some((p) => /horizon_block\.as$/.test(p.replace(/\\/g, "/"))),
		"scan includes the HUD host");
	expect(files.some((p) => /hzc_block\.as$/.test(p.replace(/\\/g, "/")))
		&& files.some((p) => /hzd_block\.as$/.test(p.replace(/\\/g, "/")))
		&& files.some((p) => /hzs_block\.as$/.test(p.replace(/\\/g, "/")))
		&& files.some((p) => /hzq_main\.as$/.test(p.replace(/\\/g, "/"))),
		"scan includes comms, dialogue, scanner, and quick-menu hosts");

	const movies = [
		{ name: "HUD", rel: ["actionscript/horizon_block.as"] },
		{ name: "HUD F11 insert", rel: ["actionscript/hz51_insert.as"] },
		{ name: "HUD F11 draw", rel: ["actionscript/hz51_draw.as"] },
		{ name: "Comms", rel: ["actionscript/comms/hzc_block.as"] },
		{ name: "Dialogue", rel: ["actionscript/comms/hzd_block.as"] },
		{ name: "Scanner", rel: ["actionscript/scanner/hzs_block.as"] },
		{ name: "Quick Menu", rel: ["actionscript/favorites/hzq_main.as", "actionscript/favorites/hzq37_reader.as"] },
		{ name: "Scope", rel: ["actionscript/scope/hzp_main.as", "actionscript/scope/hzp37_reader.as"] }
	];

	for (const abs of files) {
		const rel = path.relative(root, abs).replace(/\\/g, "/");
		const src = fs.readFileSync(abs, "utf8");
		const hits = collisionsOf(src);
		expect(hits.length === 0,
			rel + (hits.length ? " duplicate trait: " + hits.map((h) => h.name).join(", ") : " has no var/function name collision"));
	}

	for (const movie of movies) {
		const src = movie.rel.map((rel) => fs.readFileSync(path.join(root, rel), "utf8")).join("\n");
		const hits = collisionsOf(src);
		expect(hits.length === 0,
			movie.name + (hits.length ? " duplicate trait: " + hits.map((h) => h.name).join(", ") : " class has no var/function name collision"));
	}

	const oldHud = readBase(root, "228f3e7", "actionscript/horizon_block.as");
	if (oldHud.src) {
		const hits = collisionsOf(oldHud.src);
		expect(hits.some((h) => h.name === "hzDot"),
			"228f3e7 HUD had the hzDot var/function collision");
	} else {
		report(oldHud, "228f3e7", "HUD", expect);
	}

	if (failed) {
		console.error("\n" + failed + " failed, " + passed + " passed");
		process.exit(1);
	}
	console.log("\n" + passed + " passed");
}

module.exports = { collectTraits, collisionsOf };
