#pragma once

// Purpose: 0.43.3.1 [Scanner] ScanHighlightArea - how much of the screen the hand scanner highlights.
// The area is three game INI settings (not a Horizon movie value):
//   fScanHighlightDotAngle:Interface       - how close to the screen center an object must be to get picked up and
//                                             highlighted. A dot product, i.e. the cosine of the half angle between
//                                             the view direction and the object: higher = smaller cone. Game default
//                                             0.92 (about 23 degrees from the center).
//   fResourceDecalRenderRadiusPct:ResourceVeins - how far from the center an already highlighted object keeps its
//                                             outline; game default 0.8.
//   fResourceDecalRenderRadiusFalloffPct:ResourceVeins - the fade band at the edge of that radius; game default 0.25.
// (Defaults: the published getini dump of all valid Starfield INI settings and the Nexus "scanner highlight radius"
// article. The pick-up distance is game form data, not an INI setting, and is not changed here.)
// Positions: 0 = Horizon dot (a smaller cone than the game), 1 = Vanilla (the default: Horizon writes nothing and the
// game keeps whatever its own INI files say), 2 = Full screen, 3 = Max.
// Full screen = 0.45 / 4.0 / 1.0. The published 16:9 values (0.59 / 2.6, about 54 degrees) were too small in game, and
// a wider screen or FOV needs a wider cone: at a horizontal FOV h and aspect a, the screen corner sits
// atan(tan(h/2) * sqrt(1 + 1/a^2)) from the center: 16:9 at 90 is about 49 degrees (cos 0.66), 21:9 at 110 about 57
// (cos 0.54), 32:9 at 120 about 61 (cos 0.48). 0.45 is about 63 degrees, so the corners of all three are inside, and
// the outline radius and fade grow with it (4.0 / 1.0 are an inference: larger than the published 2.6, not measured).
// Max = 0.2 / 10 / 10, the values the published "whole screen" scanner mods use (about 78 degrees: past any corner).
// Horizon dot = 0.98 / 0.4: acos(0.92) is about 23 degrees from the center, acos(0.98) about 11.5 degrees, so the
// pick-up cone has half the vanilla angle, and the outline radius is half the vanilla 0.8. Small and centered, still
// wide enough to aim at one object; a near-1 value (a literal dot) would make picking anything up hard.
// The game's own values are read once, right before Horizon first writes, and written back when the player goes
// back to Vanilla (never the hardcoded 0.92 / 0.8 / 0.25, so a StarfieldCustom.ini tweak survives). Horizon dot leaves
// the fade to the game (it writes back the captured fade when it follows Full screen or Max).
// Pure logic: no game, no CommonLibSF, no thread (tests/scan_hl_test.cpp). main.cpp does the game calls.
// Author: Moragar. Last modified: 2026-11-18.

#include <string>

namespace hzscanhl {

inline constexpr int kDot = 0;
inline constexpr int kVanilla = 1;
inline constexpr int kFull = 2;
inline constexpr int kMax = 3;

inline constexpr float kDotAngleDot = 0.98f;    // Horizon dot: half the vanilla cone angle (about 11.5 degrees)
inline constexpr float kDotDecal = 0.4f;        // Horizon dot: half the vanilla outline radius
inline constexpr float kFullAngleDot = 0.45f;   // Full screen: about 63 degrees from the center (see above)
inline constexpr float kFullDecal = 4.0f;
inline constexpr float kFullFall = 1.0f;
inline constexpr float kMaxAngleDot = 0.2f;     // Max: about 78 degrees, the published whole-screen values
inline constexpr float kMaxDecal = 10.0f;
inline constexpr float kMaxFall = 10.0f;

inline constexpr const char* kKeyDot = "fScanHighlightDotAngle:Interface";
inline constexpr const char* kKeyDecal = "fResourceDecalRenderRadiusPct:ResourceVeins";
inline constexpr const char* kKeyFall = "fResourceDecalRenderRadiusFalloffPct:ResourceVeins";

// the ini value -> a position; anything but 0, 1, 2 or 3 (after trimming spaces) is Vanilla
inline int Parse(const std::string& a_v)
{
	std::size_t b = 0, e = a_v.size();
	while (b < e && (a_v[b] == ' ' || a_v[b] == '\t')) ++b;
	while (e > b && (a_v[e - 1] == ' ' || a_v[e - 1] == '\t' || a_v[e - 1] == '\r')) --e;
	if (e - b != 1) return kVanilla;
	const char c = a_v[b];
	if (c == '0') return kDot;
	if (c == '2') return kFull;
	if (c == '3') return kMax;
	return kVanilla;
}

inline const char* Name(int a_pos)
{
	return a_pos == kDot ? "Horizon dot" : (a_pos == kFull ? "Full screen" : (a_pos == kMax ? "Max" : "Vanilla"));
}

// the game's own values, read once before the first Horizon write
struct Orig
{
	bool  have = false;      // read (once) - stays true
	bool  dotOk = false;     // fScanHighlightDotAngle was found as a float
	bool  decalOk = false;   // fResourceDecalRenderRadiusPct was found as a float
	bool  fallOk = false;    // fResourceDecalRenderRadiusFalloffPct was found as a float
	float dot = 0.0f;
	float decal = 0.0f;
	float fall = 0.0f;
};

enum class Act { None, Write, Restore };

struct Plan
{
	Act   act = Act::None;
	float dot = 0.0f;
	float decal = 0.0f;
	bool  wFall = false;     // write the fade too (Full / Max; Horizon dot and Vanilla only to give a captured one back)
	float fall = 0.0f;
};

// a_applied: what Horizon last left in the game - kVanilla at start (nothing written) and after a restore.
// None when nothing changes; Vanilla with no earlier write is None too (nothing to give back).
inline Plan Next(int a_want, int a_applied, const Orig& a_orig)
{
	Plan p;
	if (a_want != kDot && a_want != kFull && a_want != kMax) a_want = kVanilla;
	if (a_want == a_applied) return p;
	if (a_want == kVanilla) {
		if (a_orig.have) { p.act = Act::Restore; p.dot = a_orig.dot; p.decal = a_orig.decal; p.wFall = a_orig.fallOk; p.fall = a_orig.fall; }
		return p;
	}
	p.act = Act::Write;
	if (a_want == kDot) {
		p.dot = kDotAngleDot; p.decal = kDotDecal;
		p.wFall = a_orig.have && a_orig.fallOk; p.fall = a_orig.fall;   // the game's own fade (before any capture it is still the game's)
	} else if (a_want == kFull) {
		p.dot = kFullAngleDot; p.decal = kFullDecal; p.wFall = true; p.fall = kFullFall;
	} else {
		p.dot = kMaxAngleDot; p.decal = kMaxDecal; p.wFall = true; p.fall = kMaxFall;
	}
	return p;
}

}
