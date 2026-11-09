#pragma once

// Purpose: the rule the gold movie uses before Horizon text takes a game face.
// An embedded face counts when Font.hasGlyphs covers the probe string.
// The module-name face counts when that probe passes, or when the name is not
// in the embedded list and a real ink sample of the field succeeds.
// A listed face that lacks a probe glyph does not count, ink or not.
// Device text still has to measure like real letters.
// Author: Moragar. Last modified: 2026-11-08.

namespace hsb {

// Eight W and eight i at 20 px, as the movie measures them.
struct FaceMeasure {
	float wide = 0;
	float narrow = 0;
	float tall = 0;
};

// Embed: a mapped name drawn with embedFonts. Native: the module-name field.
// Device: a mapped name drawn through the font library.
enum class FaceKind { Embed, Native, Device };

// glyphs: 1 the probe alphabet is covered, 0 the name is listed and a glyph is missing,
// -1 the name is not in enumerateFonts(false).
// draw: 1 a sample found ink, 0 a sample found none, -1 the field has no size,
// -2 the sample threw. Only 1 is a real ink result.
struct FaceCandidate {
	FaceMeasure measure;
	FaceKind kind = FaceKind::Embed;
	bool present = true;
	int glyphs = -1;
	int draw = 0;
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
// then the mapped names as device text. Embedded text needs hasGlyphs. The native face
// needs hasGlyphs, or an unknown name plus a real ink sample. A partial native face
// (glyphs 0) is refused. Empty and error samples are not ink. Device text still needs
// the width rule. missingEmbed is unused: width cannot tell a full face from boxes.
inline int PickFace(const FaceCandidate* list, int count, const FaceMeasure& missingEmbed, const FaceMeasure& missingDevice)
{
	(void)missingEmbed;
	if (!list) return -1;
	for (int i = 0; i < count; ++i) {
		if (!list[i].present) continue;
		const int g = list[i].glyphs;
		if (list[i].kind == FaceKind::Embed) {
			if (g == 1) return i;
			continue;
		}
		if (list[i].kind == FaceKind::Native) {
			if (g == 1) return i;
			if (g < 0 && list[i].draw == 1) return i;
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
