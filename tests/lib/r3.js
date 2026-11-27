// Shared helpers for the 0.43.6 round 3 tests (not a test itself; tests/lib is not run by the suite).
// stripComments, fnText (a function body by name), toJs (the small AS -> JS rewrite the other tests use), mkFn.
// Author: Moragar. Last modified: 2026-11-22.
"use strict";

const fs = require("fs");
const path = require("path");

const root = path.join(__dirname, "..", "..");
function stripComments(src) {
	return src.split("\n").map((line) => {
		let q = null;
		for (let i = 0; i < line.length; i++) {
			const ch = line[i];
			if (q) { if (ch === "\\") { i++; continue; } if (ch === q) q = null; continue; }
			if (ch === '"' || ch === "'") { q = ch; continue; }
			if (ch === "/" && line[i + 1] === "/") return line.slice(0, i);
		}
		return line;
	}).join("\n");
}
function readAs() {
	return stripComments(fs.readFileSync(path.join(root, "actionscript", "horizon_block.as"), "utf8").replace(/\r\n/g, "\n"));
}
function fnText(src, name) {
	let i = src.indexOf("private function " + name + "(");
	if (i < 0) i = src.indexOf("public function " + name + "(");
	if (i < 0) return null;
	const brace = src.indexOf("{", i);
	let depth = 0;
	for (let p = brace; p < src.length; p++) {
		if (src[p] === "{") depth++;
		else if (src[p] === "}") { depth--; if (depth === 0) return { sig: src.slice(i, brace), body: src.slice(brace + 1, p) }; }
	}
	throw new Error("unbalanced " + name);
}
function toJs(body) {
	return body
		.replace(/([\w.]+) is Array\b/g, "Array.isArray($1)")
		.replace(/([\w.()]+) is DisplayObjectContainer\b/g, "isDoc($1)")
		.replace(/([\w.()]+) is TextField\b/g, "isTf($1)")
		.replace(/catch\s*\(\s*([A-Za-z_]\w*)\s*:\s*[\w.*]+\s*\)/g, "catch($1)")
		.replace(/for each\s*\(\s*var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+\s+in\s+([^)]+)\)/g, "for (var $1 of hzVals($2))")
		.replace(/for\s*\(\s*var\s+([A-Za-z_]\w*)\s*:\s*[\w.*]+\s+in\s+/g, "for (var $1 in ")
		.replace(/var\s+([A-Za-z_]\w*)\s*:\s*[\w.*<>]+/g, "var $1")
		.replace(/\s+as\s+[A-Za-z_][\w.]*/g, "")
		.replace(/\b(DisplayObject|DisplayObjectContainer|TextField|MovieClip|Sprite)\(([^()]*)\)/g, "($2)");
}
function argNames(sig) {
	const m = sig.match(/\(([^)]*)\)/);
	if (!m || !m[1].trim()) return [];
	return m[1].split(",").map((a) => a.trim().split(":")[0].split("=")[0].trim());
}
function mkFn(host, args, body) {
	return Function.apply(null, args.concat(["with(this){\n" + toJs(body) + "\n}"])).bind(host);
}
function bind(host, src, name, as) {
	const f = fnText(src, name);
	if (!f) throw new Error("missing function " + name);
	host[as || name] = mkFn(host, argNames(f.sig), f.body);
}
// default host helpers used by the rewritten bodies
function baseHost(extra) {
	const h = {
		int: (v) => Number(v) | 0, uint: (v) => Number(v) >>> 0, isNaN: (v) => Number.isNaN(Number(v)),
		hzVals: (o) => (o == null ? [] : Array.isArray(o) ? o.slice() : Object.keys(o).map((k) => o[k])),
		isDoc: (o) => !!(o && o.__doc), isTf: (o) => !!(o && o.__tf),
		hzLt: (s) => s, hzHasCjk: () => false,
	};
	return Object.assign(h, extra || {});
}
let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++; console.error("FAIL " + msg);
}
function finish(name) {
	if (failed) { console.error(name + ": " + failed + " failed (" + passed + " ok)"); process.exit(1); }
	console.log(name + ": all ok (" + passed + ")");
}
module.exports = { root, stripComments, readAs, fnText, toJs, argNames, mkFn, bind, baseHost, expect, finish };
