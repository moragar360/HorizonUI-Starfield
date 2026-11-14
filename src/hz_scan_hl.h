#pragma once

// Purpose: 0.43.3.1 [Scanner] ScanHighlightArea - how much of the screen the hand scanner highlights.
// The area is two game INI settings (not a Horizon movie value):
//   fScanHighlightDotAngle:Interface       - how close to the screen center (a cosine: higher = smaller cone) an
//                                             object must be to get picked up and highlighted; game default 0.92.
//   fResourceDecalRenderRadiusPct:ResourceVeins - how far from the center an already highlighted object keeps its
//                                             outline; game default 0.8.
// Positions: 0 = Horizon dot (a smaller cone than the game), 1 = Vanilla (the default: Horizon writes nothing and the
// game keeps whatever its own INI files say), 2 = Full screen (0.59 / 2.6, the published full-screen values for a
// 16:9 screen at the default FOV).
// Horizon dot = 0.98 / 0.4: acos(0.92) is about 23 degrees from the center, acos(0.98) about 11.5 degrees, so the
// pick-up cone has half the vanilla angle, and the outline radius is half the vanilla 0.8. Small and centered, still
// wide enough to aim at one object; a near-1 value (a literal dot) would make picking anything up hard.
// The game's own values are read once, right before Horizon first writes, and written back when the player goes
// back to Vanilla (never the hardcoded 0.92 / 0.8, so a StarfieldCustom.ini tweak survives).
// Pure logic: no game, no CommonLibSF, no thread (tests/scan_hl_test.cpp). main.cpp does the game calls.
// Author: Moragar. Last modified: 2026-11-14.

#include <string>

namespace hzscanhl {

inline constexpr int kDot = 0;
inline constexpr int kVanilla = 1;
inline constexpr int kFull = 2;

inline constexpr float kDotAngleDot = 0.98f;    // Horizon dot: half the vanilla cone angle (about 11.5 degrees)
inline constexpr float kDotDecal = 0.4f;        // Horizon dot: half the vanilla outline radius
inline constexpr float kFullAngleDot = 0.59f;   // Full screen
inline constexpr float kFullDecal = 2.6f;

inline constexpr const char* kKeyDot = "fScanHighlightDotAngle:Interface";
inline constexpr const char* kKeyDecal = "fResourceDecalRenderRadiusPct:ResourceVeins";

// the ini value -> a position; anything but 0, 1 or 2 (after trimming spaces) is Vanilla
inline int Parse(const std::string& a_v)
{
	std::size_t b = 0, e = a_v.size();
	while (b < e && (a_v[b] == ' ' || a_v[b] == '\t')) ++b;
	while (e > b && (a_v[e - 1] == ' ' || a_v[e - 1] == '\t' || a_v[e - 1] == '\r')) --e;
	if (e - b != 1) return kVanilla;
	const char c = a_v[b];
	if (c == '0') return kDot;
	if (c == '2') return kFull;
	return kVanilla;
}

inline const char* Name(int a_pos)
{
	return a_pos == kDot ? "Horizon dot" : (a_pos == kFull ? "Full screen" : "Vanilla");
}

// the game's own values, read once before the first Horizon write
struct Orig
{
	bool  have = false;      // read (once) - stays true
	bool  dotOk = false;     // fScanHighlightDotAngle was found as a float
	bool  decalOk = false;   // fResourceDecalRenderRadiusPct was found as a float
	float dot = 0.0f;
	float decal = 0.0f;
};

enum class Act { None, Write, Restore };

struct Plan
{
	Act   act = Act::None;
	float dot = 0.0f;
	float decal = 0.0f;
};

// a_applied: what Horizon last left in the game - kVanilla at start (nothing written) and after a restore.
// None when nothing changes; Vanilla with no earlier write is None too (nothing to give back).
inline Plan Next(int a_want, int a_applied, const Orig& a_orig)
{
	Plan p;
	if (a_want != kDot && a_want != kFull) a_want = kVanilla;
	if (a_want == a_applied) return p;
	if (a_want == kVanilla) {
		if (a_orig.have) { p.act = Act::Restore; p.dot = a_orig.dot; p.decal = a_orig.decal; }
		return p;
	}
	p.act = Act::Write;
	p.dot = a_want == kDot ? kDotAngleDot : kFullAngleDot;
	p.decal = a_want == kDot ? kDotDecal : kFullDecal;
	return p;
}

}
