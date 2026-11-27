#pragma once

// Purpose: 0.43.3.2 [Scanner] ScanOutlineThickness - how thick the hand scanner draws the outline around highlighted
// objects (minerals, flora, fauna, items). The thickness is eleven game INI settings in [Monocle] (not a Horizon movie
// value), one per highlight kind: fHighlightScannableOutlineThickness and its _FullyScanned, _Generic, _Scanned,
// _Social, _TargetFullyScanned, _TargetGeneric, _TargetScannable, _TargetScanned and _Tracked variants. Game
// defaults (strings dumped from the executable, values read with getini): 3, 1, 2, 1, 1, 2, 3, 3, 2, 3.
// 0.43.5: + _Bounty (bounty targets), the 11th kind found in the 1.16.244 executable; 0.43.3.2 missed it, so bounty
// targets kept the game's thickness under Thick / Thicker. Like every kind it is only read / written when found.
// Positions: 0 = Vanilla (the default: Horizon writes nothing and the game keeps whatever its own INI files say),
// 1 = Thick (1.5x the game's values), 2 = Thicker (2x). The factor multiplies the values read from the game right
// before the first write, so a player's own StarfieldCustom.ini tweak is the base and a kind a player turned off
// (0) stays off. 1.5x and 2x keep every kind apart (1 -> 1.5 / 2, 3 -> 4.5 / 6) without the outline filling small
// objects; more than about 2x turns thin rocks and plants into solid blobs.
// Back to Vanilla writes the captured values back. Pure logic: no game, no CommonLibSF, no thread
// (tests/scan_ol_test.cpp). main.cpp does the game calls. Author: Moragar. Last modified: 2026-11-23.

#include <string>

namespace hzscanol {

inline constexpr int kVanilla = 0;
inline constexpr int kThick = 1;
inline constexpr int kThicker = 2;

inline constexpr int kN = 11;
inline constexpr const char* kKeys[kN] = {
	"fHighlightScannableOutlineThickness:Monocle",
	"fHighlightScannableOutlineThickness_FullyScanned:Monocle",
	"fHighlightScannableOutlineThickness_Generic:Monocle",
	"fHighlightScannableOutlineThickness_Scanned:Monocle",
	"fHighlightScannableOutlineThickness_Social:Monocle",
	"fHighlightScannableOutlineThickness_TargetFullyScanned:Monocle",
	"fHighlightScannableOutlineThickness_TargetGeneric:Monocle",
	"fHighlightScannableOutlineThickness_TargetScannable:Monocle",
	"fHighlightScannableOutlineThickness_TargetScanned:Monocle",
	"fHighlightScannableOutlineThickness_Tracked:Monocle",
	"fHighlightScannableOutlineThickness_Bounty:Monocle",   // 0.43.5
};

inline constexpr float kMulThick = 1.5f;
inline constexpr float kMulThicker = 2.0f;
inline constexpr float kMax = 12.0f;   // a cap for odd captured values (a tweak of 10 stays sane)

// the ini value -> a position; anything but 0, 1 or 2 (after trimming spaces) is Vanilla
inline int Parse(const std::string& a_v)
{
	std::size_t b = 0, e = a_v.size();
	while (b < e && (a_v[b] == ' ' || a_v[b] == '\t')) ++b;
	while (e > b && (a_v[e - 1] == ' ' || a_v[e - 1] == '\t' || a_v[e - 1] == '\r')) --e;
	if (e - b != 1) return kVanilla;
	const char c = a_v[b];
	if (c == '1') return kThick;
	if (c == '2') return kThicker;
	return kVanilla;
}

inline const char* Name(int a_pos)
{
	return a_pos == kThick ? "Thick" : (a_pos == kThicker ? "Thicker" : "Vanilla");
}

inline float Mul(int a_pos)
{
	return a_pos == kThick ? kMulThick : (a_pos == kThicker ? kMulThicker : 1.0f);
}

// the game's own values, read once before the first Horizon write
struct Orig
{
	bool  have = false;      // read (once) - stays true
	bool  ok[kN] = {};       // the setting was found as a float
	float v[kN] = {};
};

// one value for a position from a captured game value: Vanilla gives the value back; 0 or less stays as it is
// (a kind turned off stays off); the result is capped at kMax, and a game value at or above kMax is kept
inline float Value(int a_pos, float a_orig)
{
	if (!(a_orig > 0.0f) || a_orig >= kMax) return a_orig;
	const float r = a_orig * Mul(a_pos);
	return r > kMax ? kMax : r;
}

enum class Act { None, Write, Restore };

// a_applied: what Horizon last left in the game - kVanilla at start (nothing written) and after a restore.
inline Act Next(int a_want, int a_applied, const Orig& a_orig)
{
	if (a_want != kThick && a_want != kThicker) a_want = kVanilla;
	if (a_want == a_applied) return Act::None;
	if (a_want == kVanilla) return a_orig.have ? Act::Restore : Act::None;
	return Act::Write;
}

}
