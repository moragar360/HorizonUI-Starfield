// Shared by the tests that compare the production AS with old bodies read through git show
// (afflictions_p0_test, perf_r2_fix1 / fix4 / fix5). Not a test itself (tests/lib is not run by the suite).
// readBase(root, rev): the old horizon_block.as, or why it is missing.
//  - SKIP (pass) only when the folder is not a git repository (a source zip) or the clone is shallow.
//  - FAIL with git's own error and the revision for anything else: the revision is missing in a full repository
//    (for example after a squash-merge), git cannot start (not on PATH), or any other git error.
//  - HZ_REQUIRE_GIT=1 turns a SKIP into a FAIL too.
// Author: Moragar. Last modified: 2026-11-14.
"use strict";

const cp = require("child_process");

function git(root, args) {
	return cp.spawnSync("git", args, { cwd: root, encoding: "utf8", maxBuffer: 1 << 26, stdio: ["ignore", "pipe", "pipe"] });
}
function errText(r) {
	if (r.error) return "git could not start (" + (r.error.code || r.error.message) + ")";
	const t = String(r.stderr || "").trim().split("\n")[0];
	return t.length ? t : "git exited with " + r.status;
}

function readBase(root, rev, file) {
	const f = file || "actionscript/horizon_block.as";
	const show = git(root, ["show", rev + ":" + f]);
	if (!show.error && show.status === 0) return { src: show.stdout.replace(/\r\n/g, "\n"), skip: false, why: "" };
	if (show.error) return { src: null, skip: false, why: errText(show) };
	const inside = git(root, ["rev-parse", "--is-inside-work-tree"]);
	if (!inside.error && inside.status !== 0 && /not a git repository/i.test(String(inside.stderr))) {
		return { src: null, skip: true, why: "not a git repository" };
	}
	const shallow = git(root, ["rev-parse", "--is-shallow-repository"]);
	if (!shallow.error && shallow.status === 0 && shallow.stdout.trim() === "true") {
		return { src: null, skip: true, why: "shallow clone" };
	}
	return { src: null, skip: false, why: errText(show) };
}

// one line for a missing base: SKIP, or a FAIL through the test's own expect
function report(res, rev, what, expect) {
	if (res.src != null) return;
	const msg = what + ": base revision " + rev + " not readable (" + res.why + ")";
	if (res.skip && process.env.HZ_REQUIRE_GIT !== "1") {
		console.log("SKIP " + msg + "; the old-vs-new checks are skipped (HZ_REQUIRE_GIT=1 makes this a FAIL)");
		return;
	}
	expect(false, msg + (res.skip ? " (HZ_REQUIRE_GIT=1)" : ""));
}

module.exports = { readBase, report };
