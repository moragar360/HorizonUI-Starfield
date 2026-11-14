// Build-path check for HorizonUI.dll (arch-fixes, 4th commit).
// Run: node tests/dll_paths_check.js <HorizonUI.dll> [more words]   checks one DLL; exit 1 on any hit
//      node tests/dll_paths_check.js                                 self-test of the scanner (used by the node test run)
// Scans printable ASCII runs (like strings -a) and UTF-16LE runs (like strings -a -el), at least 4 characters, for:
// "\Users\" (any case), a drive-rooted ".pdb" path, the words given on the command line or in HZ_PATH_WORDS
// (comma separated), and xmake.lua is checked for the flags that keep those paths out.
// Author: Moragar. Last modified: 2026-11-13.
"use strict";

const fs = require("fs");
const path = require("path");

function runs(buf) {
	const out = [];
	let s = "";
	for (let i = 0; i < buf.length; i++) {
		const c = buf[i];
		if (c >= 0x20 && c < 0x7f) s += String.fromCharCode(c);
		else { if (s.length >= 4) out.push({ enc: "ascii", at: i - s.length, s: s }); s = ""; }
	}
	if (s.length >= 4) out.push({ enc: "ascii", at: buf.length - s.length, s: s });
	for (const start of [0, 1]) {
		s = "";
		let at = start;
		for (let i = start; i + 1 < buf.length; i += 2) {
			const c = buf[i], hi = buf[i + 1];
			if (hi === 0 && c >= 0x20 && c < 0x7f) { if (!s) at = i; s += String.fromCharCode(c); }
			else { if (s.length >= 4) out.push({ enc: "utf16le", at: at, s: s }); s = ""; }
		}
		if (s.length >= 4) out.push({ enc: "utf16le", at: at, s: s });
	}
	return out;
}
function hits(buf, words) {
	const res = [];
	const ws = words.filter((w) => w && w.length >= 3).map((w) => w.toLowerCase());
	for (const r of runs(buf)) {
		const l = r.s.toLowerCase();
		let why = null;
		if (l.indexOf("\\users\\") >= 0 || l.indexOf("/users/") >= 0) why = "Users path";
		else if (/[a-z]:[\\/][^\s"]*\.pdb/.test(l)) why = "absolute PDB path";
		else for (const w of ws) if (l.indexOf(w) >= 0) { why = "word " + w; break; }
		if (why) res.push(Object.assign({ why: why }, r));
	}
	return res;
}

const args = process.argv.slice(2);
const envWords = (process.env.HZ_PATH_WORDS || "").split(",").map((w) => w.trim());
if (args.length > 0) {
	const file = args[0];
	const buf = fs.readFileSync(file);
	const h = hits(buf, args.slice(1).concat(envWords));
	for (const x of h) console.log("HIT " + x.why + " [" + x.enc + " @0x" + x.at.toString(16) + "] " + x.s.slice(0, 200));
	console.log(path.basename(file) + ": " + buf.length + " bytes, " + h.length + " hit(s)");
	process.exit(h.length ? 1 : 0);
}

// ---- self-test ----
let failed = 0, passed = 0;
function expect(cond, msg) {
	if (cond) { passed++; console.log("ok  " + msg); return; }
	failed++;
	console.error("FAIL " + msg);
}
const u16 = (s) => Buffer.from(s, "utf16le");
const pad = Buffer.from([0, 1, 2, 3]);
const bad1 = Buffer.concat([pad, Buffer.from("C:\\Users\\someone\\build\\src\\lib\\x.h"), pad]);
const bad2 = Buffer.concat([pad, u16("D:\\work\\HorizonUI\\build\\HorizonUI.pdb"), pad]);
const bad3 = Buffer.concat([pad, Buffer.from("built by alice-pc"), pad]);
const good = Buffer.concat([pad, Buffer.from("HorizonUI.pdb"), pad, Buffer.from("\\lib\\commonlibsf\\include\\SFSE/Interfaces.h"), pad, u16("HorizonUI.user.ini"), pad]);
expect(hits(bad1, []).length === 1 && hits(bad1, [])[0].enc === "ascii", "an ASCII Users path is a hit");
expect(hits(bad2, []).length === 1 && hits(bad2, [])[0].enc === "utf16le", "a UTF-16LE drive-rooted .pdb path is a hit");
expect(hits(bad3, ["alice"]).length === 1 && hits(bad3, []).length === 0, "an extra word given on the command line is a hit");
expect(hits(good, ["alice"]).length === 0, "a bare PDB name and a trimmed header path are not hits");
const xm = fs.readFileSync(process.env.HZ_XMAKE || path.join(__dirname, "..", "xmake.lua"), "utf8");
const inc = xm.indexOf('includes("lib/commonlibsf")');
const blk = xm.slice(0, inc);
expect(inc > 0 && blk.indexOf('add_cxflags("/d1trimfile:$(projectdir)", {tools = "cl", force = true})') >= 0, "xmake.lua: MSVC trims the project folder from __FILE__, before CommonLibSF is included");
expect(blk.indexOf('add_cxflags("/clang:-ffile-prefix-map=$(projectdir)=.", {tools = "clang_cl", force = true})') >= 0, "xmake.lua: clang-cl maps the project folder away");
expect(blk.indexOf('add_shflags("/PDBALTPATH:%_PDB%", {force = true})') >= 0 && blk.indexOf('add_ldflags("/PDBALTPATH:%_PDB%", {force = true})') >= 0, "xmake.lua: the DLL names only its PDB file");
expect(/set_version\("0\.43\.3\.0"\)/.test(xm), "xmake.lua: file version unchanged");
if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("dll paths check self-test: " + passed + " ok, all passed");
