#pragma once

// Purpose: 0.43.3.1 [Scanner] ScanHighlightArea (0.43.5: five visible levels) - how much of the screen the hand scanner highlights.
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
// 0.43.5 levels (each one a visible step on a 16:9 screen at the default first-person FOV of 85, horizontal):
//   0 = Small (was "Horizon dot")  0.98 / 0.4, the game's fade: about 11.5 degrees, half the vanilla circle.
//   1 = Vanilla (the default)      Horizon writes nothing; the game keeps whatever its own INI files say.
//   4 = Large                      0.82 / 1.4, the game's fade: about 35 degrees, the circle reaches the top and bottom
//                                  of the screen (0.82 is the published "in between" angle; 1.4 is the radius below).
//   5 = Wide                       0.735 / 1.8, the game's fade: about 42.7 degrees, it reaches the left and right edges (the half width at 16:9 / FOV 85 is 42.5);
//                                  the corners stay out.
//   2 = Full screen                0.45 / 4.0 / fade 1.0: about 63 degrees, the corners too (16:9 up to FOV 110, 21:9
//                                  up to about 105, 32:9 up to about 85).
//   3 = the retired "Max" (0.2 / 10 / 10, about 78 degrees): read as Full screen. On a normal monitor it looked the same
//       as Full screen and only added picks off screen, so a saved 3 keeps a full-screen scanner.
// The outline radius follows one rule: about the circle's reach in half screen heights at 16:9 / FOV 85, which fits
// the published pairs 0.92 / 0.8 and 0.59 / 2.6 (an inference, not a measured game formula).
// The ini ids keep their old meaning (0, 1, 2, and 3 read as 2), so no saved value changes meaning; Large and Wide got
// the new ids 4 and 5. F11 lists them in size order: 0, 1, 4, 5, 2.
// Screen corner math: at a horizontal FOV h and aspect a the corner sits atan(tan(h/2) * sqrt(1 + 1/a^2)) from the center.
// The game's own values are read once, right before Horizon first writes, and written back when the player goes
// back to Vanilla (never the hardcoded 0.92 / 0.8 / 0.25, so a StarfieldCustom.ini tweak survives). Small, Large and
// Wide leave the fade to the game (they write back the captured fade when they follow Full screen).
// 0.43.5: main.cpp also reads the values back (Drifted) and writes them again when something else changed them, and
// logs the game's own values once at load (WidenedByOther flags an INI tweak or another mod that already widens).
// Pure logic: no game, no CommonLibSF, no thread (tests/scan_hl_test.cpp). main.cpp does the game calls.
// Author: Moragar. Last modified: 2026-11-24.

#include <string>

namespace hzscanhl {

inline constexpr int kDot = 0;       // F11 "SMALL" (the name kDot is kept from 0.43.3.1)
inline constexpr int kVanilla = 1;
inline constexpr int kFull = 2;
inline constexpr int kMax = 3;       // retired: Parse reads it as kFull, nothing writes it
inline constexpr int kLarge = 4;
inline constexpr int kWide = 5;

inline constexpr float kDotAngleDot = 0.98f;    // Small: half the vanilla cone angle (about 11.5 degrees)
inline constexpr float kDotDecal = 0.4f;        // Small: half the vanilla outline radius
inline constexpr float kLargeAngleDot = 0.82f;  // Large: about 35 degrees (the published "in between" angle)
inline constexpr float kLargeDecal = 1.4f;
inline constexpr float kWideAngleDot = 0.735f;  // Wide: about 42.7 degrees, just past the side edges of 16:9 at FOV 85 (half width 42.5)
inline constexpr float kWideDecal = 1.8f;
inline constexpr float kFullAngleDot = 0.45f;   // Full screen: about 63 degrees from the center (see above)
inline constexpr float kFullDecal = 4.0f;
inline constexpr float kFullFall = 1.0f;

inline constexpr float kGameDot = 0.92f;        // the game's defaults (getini), only used to spot an outside widening
inline constexpr float kGameDecal = 0.8f;

inline constexpr const char* kKeyDot = "fScanHighlightDotAngle:Interface";
inline constexpr const char* kKeyDecal = "fResourceDecalRenderRadiusPct:ResourceVeins";
inline constexpr const char* kKeyFall = "fResourceDecalRenderRadiusFalloffPct:ResourceVeins";

// the ini value -> a position; 3 (the retired Max) is Full screen; anything but 0 - 5 (after trimming spaces) is Vanilla
inline int Parse(const std::string& a_v)
{
	std::size_t b = 0, e = a_v.size();
	while (b < e && (a_v[b] == ' ' || a_v[b] == '\t')) ++b;
	while (e > b && (a_v[e - 1] == ' ' || a_v[e - 1] == '\t' || a_v[e - 1] == '\r')) --e;
	if (e - b != 1) return kVanilla;
	const char c = a_v[b];
	if (c == '0') return kDot;
	if (c == '2' || c == '3') return kFull;
	if (c == '4') return kLarge;
	if (c == '5') return kWide;
	return kVanilla;
}

inline const char* Name(int a_pos)
{
	return a_pos == kDot ? "Small" : (a_pos == kLarge ? "Large" : (a_pos == kWide ? "Wide" : (a_pos == kFull ? "Full screen" : "Vanilla")));
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
	bool  wFall = false;     // write the fade too (Full screen; Small / Large / Wide and Vanilla only to give a captured one back)
	float fall = 0.0f;
};

// a_applied: what Horizon last left in the game - kVanilla at start (nothing written) and after a restore.
// None when nothing changes; Vanilla with no earlier write is None too (nothing to give back).
inline Plan Next(int a_want, int a_applied, const Orig& a_orig)
{
	Plan p;
	if (a_want == kMax) a_want = kFull;
	if (a_applied == kMax) a_applied = kFull;
	if (a_want != kDot && a_want != kFull && a_want != kLarge && a_want != kWide) a_want = kVanilla;
	if (a_want == a_applied) return p;
	if (a_want == kVanilla) {
		if (a_orig.have) { p.act = Act::Restore; p.dot = a_orig.dot; p.decal = a_orig.decal; p.wFall = a_orig.fallOk; p.fall = a_orig.fall; }
		return p;
	}
	p.act = Act::Write;
	if (a_want == kFull) {
		p.dot = kFullAngleDot; p.decal = kFullDecal; p.wFall = true; p.fall = kFullFall;
		return p;
	}
	if (a_want == kDot) { p.dot = kDotAngleDot; p.decal = kDotDecal; }
	else if (a_want == kLarge) { p.dot = kLargeAngleDot; p.decal = kLargeDecal; }
	else { p.dot = kWideAngleDot; p.decal = kWideDecal; }
	p.wFall = a_orig.have && a_orig.fallOk; p.fall = a_orig.fall;   // the game's own fade (before any capture it is still the game's)
	return p;
}

// 0.43.5: the value in the game no longer is the one Horizon wrote (another mod's setini, a bat file or the console)
inline bool Drifted(float a_now, float a_wrote)
{
	const float d = a_now - a_wrote;
	return d > 0.0005f || d < -0.0005f;
}

// 0.43.5: the game's own values (read at load, before any Horizon write) already make the area wider than the game's
// defaults 0.92 / 0.8: an INI tweak or another scanner mod (then Vanilla is not the game's small circle)
inline bool WidenedByOther(bool a_dotOk, float a_dot, bool a_decalOk, float a_decal)
{
	return (a_dotOk && a_dot < kGameDot - 0.005f) || (a_decalOk && a_decal > kGameDecal + 0.005f);
}

// ---- 0.43.5: yield after a few reapplies, so Horizon never fights another mod forever ----
// What Horizon last wrote (the recheck compares against it) and what the game holds now.
struct Wrote { bool on = false; float dot = 0.0f; float decal = 0.0f; bool wFall = false; float fall = 0.0f; };
struct Now { bool dotFound = false; bool decalFound = false; bool fallFound = false; float dot = 0.0f; float decal = 0.0f; float fall = 0.0f; };

inline constexpr int kMaxReapply = 3;   // reapplies per pick; the next drift is a yield

inline bool AnyDrift(const Wrote& a_w, const Now& a_n)
{
	return (a_n.dotFound && Drifted(a_n.dot, a_w.dot)) ||
	       (a_n.decalFound && Drifted(a_n.decal, a_w.decal)) ||
	       (a_n.fallFound && a_w.wFall && Drifted(a_n.fall, a_w.fall));
}

// the pick guard: a pick equal to the position Horizon yielded at is ignored; any other pick clears the yield first and
// resets the reapply count, then "nothing changed" is decided (clear the yield first, then compare)
struct Guard { int reapplied = 0; int yielded = -1; };

inline bool Settled(Guard& a_g, int a_want, int a_applied)
{
	if (a_want == a_g.yielded) return true;
	if (a_g.yielded != -1 || a_want != a_applied) a_g.reapplied = 0;
	a_g.yielded = -1;
	return a_want == a_applied;
}

enum class Re { None, Reapply, Yield };

// a_wrote.on: a non-Vanilla level is in the game. Reapply up to kMaxReapply times per pick, then yield.
inline Re Recheck(Guard& a_g, const Wrote& a_w, const Now& a_n)
{
	if (!a_w.on || !AnyDrift(a_w, a_n)) return Re::None;
	if (a_g.reapplied < kMaxReapply) { ++a_g.reapplied; return Re::Reapply; }
	return Re::Yield;
}

// a yield gives back, from the captured game values, only the settings that still hold Horizon's value (never a value
// somebody else set), so Horizon's cone is not left in the game and another mod's value is not overwritten
struct Give { bool dot = false; bool decal = false; bool fall = false; };

inline Give GiveBack(const Wrote& a_w, const Orig& a_o, const Now& a_n)
{
	Give g;
	g.dot = a_o.have && a_o.dotOk && a_n.dotFound && !Drifted(a_n.dot, a_w.dot);
	g.decal = a_o.have && a_o.decalOk && a_n.decalFound && !Drifted(a_n.decal, a_w.decal);
	g.fall = a_o.have && a_w.wFall && a_o.fallOk && a_n.fallFound && !Drifted(a_n.fall, a_w.fall);
	return g;
}

// the full HIGHLIGHT AREA state main.cpp and the tests share (applied, yield/reapply guard, captured base, last write)
struct State
{
	int   applied = kVanilla;
	Guard guard;
	Orig  orig;
	Wrote wrote;
};

inline bool Settled(State& a_s, int a_want) { return Settled(a_s.guard, a_want, a_s.applied); }

// what Recheck(State) tells main.cpp to write. On Yield the state is already updated (yielded, applied = Vanilla,
// wrote and orig cleared), so a regression in that bookkeeping is caught by the tests, not only by string pins.
struct RePlan
{
	Re    re = Re::None;
	bool  writeDot = false;
	bool  writeDecal = false;
	bool  writeFall = false;
	float dot = 0.0f;
	float decal = 0.0f;
	float fall = 0.0f;
};

inline RePlan Recheck(State& a_s, const Now& a_n)
{
	RePlan p;
	p.re = Recheck(a_s.guard, a_s.wrote, a_n);
	if (p.re == Re::None) return p;
	if (p.re == Re::Reapply) {
		p.writeDot = a_n.dotFound;
		p.writeDecal = a_n.decalFound;
		p.writeFall = a_s.wrote.wFall;
		p.dot = a_s.wrote.dot;
		p.decal = a_s.wrote.decal;
		p.fall = a_s.wrote.fall;
		return p;
	}
	const auto g = GiveBack(a_s.wrote, a_s.orig, a_n);
	p.writeDot = g.dot;
	p.writeDecal = g.decal;
	p.writeFall = g.fall;
	if (g.dot) p.dot = a_s.orig.dot;
	if (g.decal) p.decal = a_s.orig.decal;
	if (g.fall) p.fall = a_s.orig.fall;
	a_s.guard.yielded = a_s.applied;
	a_s.applied = kVanilla;
	a_s.wrote = Wrote{};
	a_s.orig = Orig{};
	return p;
}

}
