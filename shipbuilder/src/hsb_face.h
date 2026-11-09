#pragma once

// Purpose: the rule the gold movie uses before Horizon text takes a game face.
// An embedded face counts when Font.hasGlyphs covers the probe string.
// A native face that is already drawing stays a candidate without that.
// Device text still has to measure like real letters.
// Author: Moragar. Last modified: 2026-11-08.

namespace hsb {

// Eight W and eight i at 20 px, as the movie measures them.
struct FaceMeasure {
	float wide = 0;
	float narrow = 0;
	float tall = 0;
};

struct FaceCandidate {
	FaceMeasure measure;
	bool embed = true;
	bool present = true;
	// Font.hasGlyphs covers the probe alphabet. A listed name with a short glyph set is false.
	bool glyphs = false;
	// The module-name field has visible ink. That face stays a candidate without glyphs.
	bool draws = false;
};

inline constexpr float kFaceRatio = 1.6f;
inline constexpr float kFaceSame = 0.5f;

// Box glyphs share one advance, so W and i measure alike. A pair that matches a name
// that cannot exist is the library's stand-in, not the face that was asked for.
inline bool FaceProven(const FaceMeasure& m, const FaceMeasure& missing)
{
	if (!(m.wide > 8.0f) || !(m.narrow > 0.0f) || !(m.tall > 4.0f)) return false;
	if (m.wide < m.narrow * kFaceRatio) return false;
	const auto near = [](float a, float b) { return (a > b ? a - b : b - a) < kFaceSame; };
	if (missing.wide > 0.0f && near(m.wide, missing.wide) && near(m.narrow, missing.narrow)) return false;
	return true;
}

// The movie's order: three mapped names as embedded text, the module-name field's face,
// then the mapped names as device text. Embedded text needs hasGlyphs. A native face
// that draws wins without it. Device text still needs the width rule. missingEmbed is
// unused: width cannot tell a full face from missing-glyph boxes.
inline int PickFace(const FaceCandidate* list, int count, const FaceMeasure& missingEmbed, const FaceMeasure& missingDevice)
{
	(void)missingEmbed;
	if (!list) return -1;
	for (int i = 0; i < count; ++i) {
		if (!list[i].present) continue;
		if (list[i].draws) return i;
		if (list[i].embed) {
			if (list[i].glyphs) return i;
			continue;
		}
		if (FaceProven(list[i].measure, missingDevice)) return i;
	}
	return -1;
}

// HsbKit.size: text grows 20% in the large-font movie (Math.round), and captions are the floor.
inline int TextFloorPx(bool large)
{
	return large ? 15 : 12;
}

inline int TextPx(int px, bool large)
{
	const int floor = TextFloorPx(large);
	const int n = large ? static_cast<int>(px * 1.2 + 0.5) : px;
	return n < floor ? floor : n;
}

} // namespace hsb
