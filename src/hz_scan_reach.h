#pragma once

// Purpose: 0.43.5 [Scanner] ScanReach - how far away the hand scanner works. This changes gameplay, not only the
// look, so it is its own F11 row and off (Vanilla) by default.
// The reach is two game settings (GMSTs in Starfield.esm, not INI settings; the console sets them with setgs):
//   fHandScannerBaseRange - the highlight distance: things this close are outlined (highlightable, not yet
//                           scannable). Starfield.esm uses the exe default, 50 m.
//   fHandScannerScanRange - the scan distance: highlighted and scannable. Starfield.esm sets 10 m (the exe default is
//                           30); the planet card's SCAN RANGE (MonocleMenuData uMaxScanDistance) is this plus the
//                           Surveying bonus.
// fHandScannerScanRangeSkillMult (Starfield.esm 10 m per Surveying rank) is never touched: the skill bonus still adds
// its meters on top of the multiplied base (the "respect the skill" rule).
// Positions: 0 = Vanilla (the default: Horizon writes nothing; the game, Starfield.esm and any range mod keep their
// values), 1 = x2, 2 = x3, 3 = x5. The factor multiplies the values read from the game right before the first write,
// so a range mod (an ESM or a startup bat) applies first and Horizon scales what it set. Capped at x5 and at
// kMaxRange: scanner range mods warn about lag past 500 m (Hand Scanner Utility); vanilla x5 is 250 m / 50 m.
// Back to Vanilla writes the captured values back, but only a value that still holds what Horizon wrote: if something
// else changed it since (another mod, a bat file, the console), Horizon leaves it alone and stops managing it until the
// position changes again (Yielded), so it never fights another range mod.
// GMSTs are not saved in the save game: removing Horizon (or Vanilla) leaves no trace in saves.
// Sources: Hand Scanner Utility (Nexus mods 3003 / 8867), 10x Scanner Range (9984), The Quintessential Tweaks (1326),
// Advanced Hand Scanner (12692); defaults read from Starfield.exe 1.16.244 and Starfield.esm (0.43.5 research).
// Pure logic: no game, no CommonLibSF, no thread (tests/scan_reach_test.cpp). main.cpp does the game calls.
// Author: Moragar. Last modified: 2026-11-24.

#include <string>

namespace hzscanreach {

inline constexpr int kVanilla = 0;
inline constexpr int kX2 = 1;
inline constexpr int kX3 = 2;
inline constexpr int kX5 = 3;

inline constexpr int kN = 2;
inline constexpr int kBase = 0;   // highlight distance
inline constexpr int kScan = 1;   // scan distance
inline constexpr const char* kKeys[kN] = { "fHandScannerBaseRange", "fHandScannerScanRange" };

inline constexpr float kMaxRange = 500.0f;   // m: never write more (mods report lag past 500 m); a larger game value is kept

// the ini value -> a position; anything but 0 - 3 (after trimming spaces) is Vanilla
inline int Parse(const std::string& a_v)
{
	std::size_t b = 0, e = a_v.size();
	while (b < e && (a_v[b] == ' ' || a_v[b] == '\t')) ++b;
	while (e > b && (a_v[e - 1] == ' ' || a_v[e - 1] == '\t' || a_v[e - 1] == '\r')) --e;
	if (e - b != 1) return kVanilla;
	const char c = a_v[b];
	if (c == '1') return kX2;
	if (c == '2') return kX3;
	if (c == '3') return kX5;
	return kVanilla;
}

inline const char* Name(int a_pos)
{
	return a_pos == kX2 ? "x2" : (a_pos == kX3 ? "x3" : (a_pos == kX5 ? "x5" : "Vanilla"));
}

inline float Mul(int a_pos)
{
	return a_pos == kX2 ? 2.0f : (a_pos == kX3 ? 3.0f : (a_pos == kX5 ? 5.0f : 1.0f));
}

// one value for a position from a captured game value: Vanilla gives it back; 0 or less stays as it is; capped at
// kMaxRange, and a game value already at or above kMaxRange is kept (a range mod's big value is never shrunk)
inline float Value(int a_pos, float a_orig)
{
	if (!(a_orig > 0.0f) || a_orig >= kMaxRange) return a_orig;
	const float r = a_orig * Mul(a_pos);
	return r > kMaxRange ? kMaxRange : r;
}

// the game's values, read right before the first Horizon write (again after a yield)
struct Orig
{
	bool  have = false;
	bool  ok[kN] = {};
	float v[kN] = {};
};

enum class Act { None, Write, Restore };

// a_applied: what Horizon last left in the game (kVanilla at start, after a restore and after a yield)
inline Act Next(int a_want, int a_applied, const Orig& a_orig)
{
	if (a_want != kX2 && a_want != kX3 && a_want != kX5) a_want = kVanilla;
	if (a_want == a_applied) return Act::None;
	if (a_want == kVanilla) return a_orig.have ? Act::Restore : Act::None;
	return Act::Write;
}

// the value in the game no longer is the one Horizon wrote (another mod, a bat file, the console)
inline bool Drifted(float a_now, float a_wrote)
{
	const float d = a_now - a_wrote;
	return d > 0.01f || d < -0.01f;
}

// ---- 0.43.5: the whole state machine, pure, so main.cpp and tests/scan_reach_test.cpp run the same code ----
// main.cpp reads the game's two values (cur / found), asks Pick or Recheck what to write, and writes exactly that.
// Rules: a yield never leaves Horizon's multiplied value behind, and Vanilla always takes back what Horizon wrote:
//  - Settled(): a pick equal to the position Horizon yielded at is ignored; any other pick clears the yield first, then
//    "nothing changed" is decided (so Vanilla and then the same level again applies again).
//  - Pick(Vanilla): gives back every setting that still holds Horizon's value (a value someone else changed is left).
//  - Pick(level): captures the game's current values as the base once, writes base x factor (capped). If a key no
//    longer holds what Horizon wrote (a new pick before the next recheck), that key is rebased on the current value
//    so a new factor never compounds and an outside value is never overwritten unless Horizon rebased on it.
//  - Recheck(): when a setting no longer holds what Horizon wrote, Horizon yields: it gives back the OTHER settings that
//    still hold its value (only those), forgets the base and manages nothing until the player picks again.
inline int Norm(int a_want) { return (a_want == kX2 || a_want == kX3 || a_want == kX5) ? a_want : kVanilla; }

struct State
{
	int   applied = kVanilla;   // what Horizon last left in the game (kVanilla at start, after a restore and after a yield)
	int   yielded = -1;         // the position Horizon yielded at (-1 = none)
	Orig  orig;                 // the base: the game's values right before the first write
	float wrote[kN] = {};       // what Horizon last wrote
};

struct Plan
{
	bool  act = false;          // something to write (or a yield to log)
	bool  restore = false;      // a Vanilla pick that had something to give back
	bool  yielded = false;      // Recheck: Horizon yielded
	bool  noKeys = false;       // Pick: neither setting exists in the game (nothing written)
	int   driftKey = -1;        // Recheck: the setting that changed
	bool  w[kN] = {};           // write val[i]
	float val[kN] = {};
	int   skipped = 0;          // settings left alone because somebody else changed them
};

inline bool Settled(State& a_s, int a_want)
{
	a_want = Norm(a_want);
	if (a_want == a_s.yielded) return true;
	a_s.yielded = -1;
	return a_want == a_s.applied;
}

inline Plan Pick(State& a_s, int a_want, const float a_cur[kN], const bool a_found[kN])
{
	Plan p;
	a_want = Norm(a_want);
	if (a_want == a_s.applied) return p;
	if (a_want == kVanilla) {
		a_s.applied = kVanilla;
		if (!a_s.orig.have) return p;
		p.act = true;
		p.restore = true;
		for (int i = 0; i < kN; ++i) {
			if (!a_s.orig.ok[i] || !a_found[i]) continue;
			if (Drifted(a_cur[i], a_s.wrote[i])) { ++p.skipped; continue; }
			p.w[i] = true;
			p.val[i] = a_s.orig.v[i];
		}
		a_s.orig = Orig{};   // the next pick reads the game again (a range mod may have changed it)
		return p;
	}
	if (!a_s.orig.have) {
		a_s.orig.have = true;
		for (int i = 0; i < kN; ++i) { a_s.orig.ok[i] = a_found[i]; a_s.orig.v[i] = a_cur[i]; }
	} else {
		// a new level before the next recheck: rebase any key that no longer holds what Horizon wrote, so the new
		// factor is applied to the current value (never to an already-multiplied Horizon value, and never over a
		// value Horizon did not write unless it rebased on it)
		for (int i = 0; i < kN; ++i) {
			if (!a_s.orig.ok[i] || !a_found[i]) continue;
			if (Drifted(a_cur[i], a_s.wrote[i])) a_s.orig.v[i] = a_cur[i];
		}
	}
	a_s.applied = a_want;
	bool any = false;
	for (int i = 0; i < kN; ++i) {
		if (!a_s.orig.ok[i]) continue;
		any = true;
		p.w[i] = true;
		p.val[i] = Value(a_want, a_s.orig.v[i]);
		a_s.wrote[i] = p.val[i];
	}
	if (!any) { p.noKeys = true; a_s.orig = Orig{}; return p; }
	p.act = true;
	return p;
}

inline Plan Recheck(State& a_s, const float a_cur[kN], const bool a_found[kN])
{
	Plan p;
	if (a_s.applied == kVanilla) return p;
	for (int i = 0; i < kN; ++i)
		if (a_s.orig.ok[i] && a_found[i] && Drifted(a_cur[i], a_s.wrote[i])) { p.driftKey = i; break; }
	if (p.driftKey < 0) return p;
	p.act = true;
	p.yielded = true;
	for (int i = 0; i < kN; ++i) {
		if (!a_s.orig.ok[i] || !a_found[i]) continue;
		if (Drifted(a_cur[i], a_s.wrote[i])) { ++p.skipped; continue; }
		p.w[i] = true;
		p.val[i] = a_s.orig.v[i];
	}
	a_s.yielded = a_s.applied;
	a_s.applied = kVanilla;
	a_s.orig = Orig{};
	return p;
}

}
