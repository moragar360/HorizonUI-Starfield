#pragma once

// Purpose: which vanilla children may be faded, and how live text is restyled.
// The movie applies these rules inside the game clips. It does not remove them.
// Author: Moragar. Last modified: 2026-11-07.

#include <cstdint>
#include <string_view>

namespace hsb {

enum class InteriorPanel { Power, Module, Browser, Credits, Stats, Other };

enum class FadeKind { None, Backdrop, Logo };

struct InteriorChild {
	std::string_view name;
	bool hasText = false;
	int childCount = 0;
	float relX = 0;
	float relY = 0;
	float relW = 0;
	float relH = 0;
	// A Sprite or MovieClip can gain rows later. A Shape cannot.
	bool canHoldContent = false;
	bool isMask = false;
	bool isHit = false;
};

struct TextStyle {
	int color = 0xF4F0E4;
	bool keepFace = true;
	bool keepEmbed = true;
};

inline constexpr int kOffwhite = 0xF4F0E4;
inline constexpr int kGold = 0xE8C547;

inline char FoldInterior(char c)
{
	if (c >= 'A' && c <= 'Z') return static_cast<char>(c - 'A' + 'a');
	return c;
}

inline bool HasToken(std::string_view name, std::string_view token)
{
	if (token.empty() || name.size() < token.size()) return false;
	for (std::size_t i = 0; i + token.size() <= name.size(); ++i) {
		bool match = true;
		for (std::size_t j = 0; j < token.size(); ++j) {
			if (FoldInterior(name[i + j]) != FoldInterior(token[j])) {
				match = false;
				break;
			}
		}
		if (match) return true;
	}
	return false;
}

inline bool IsOurNode(std::string_view name)
{
	return name.size() >= 3 && name[0] == 'H' && name[1] == 's' && name[2] == 'b';
}

// Our plates and headings are the only children the movie may remove.
inline bool MayRemoveChild(std::string_view name)
{
	return IsOurNode(name);
}

// A token at the start, after a non-letter, or at a camel-case break.
// "hit" matches Hit_mc and BackgroundHit, and does not match "white".
inline bool HasBoundToken(std::string_view name, std::string_view token)
{
	if (token.empty() || name.size() < token.size()) return false;
	for (std::size_t i = 0; i + token.size() <= name.size(); ++i) {
		bool match = true;
		for (std::size_t j = 0; j < token.size(); ++j) {
			if (FoldInterior(name[i + j]) != FoldInterior(token[j])) {
				match = false;
				break;
			}
		}
		if (!match) continue;
		if (i == 0) return true;
		const char prev = name[i - 1];
		const char cur = name[i];
		const bool prevLetter = (prev >= 'A' && prev <= 'Z') || (prev >= 'a' && prev <= 'z');
		const bool camel = prev >= 'a' && prev <= 'z' && cur >= 'A' && cur <= 'Z';
		if (!prevLetter || camel) return true;
	}
	return false;
}

inline bool IsProtectedName(std::string_view name)
{
	return HasToken(name, "entry") || HasToken(name, "categor") || HasToken(name, "scroll") || HasToken(name, "button")
		|| HasToken(name, "slider") || HasToken(name, "pip") || HasToken(name, "input") || HasToken(name, "list")
		|| HasToken(name, "tab") || HasToken(name, "select") || HasToken(name, "alloc") || HasToken(name, "meter")
		|| HasToken(name, "reactor") || HasToken(name, "equip") || HasBoundToken(name, "mask")
		|| HasBoundToken(name, "hitarea") || HasBoundToken(name, "hit") || HasBoundToken(name, "hotspot");
}

inline bool IsBackdropName(std::string_view name)
{
	return HasToken(name, "background") || HasToken(name, "backdrop") || HasToken(name, "border")
		|| HasToken(name, "plate") || HasToken(name, "shadow") || HasToken(name, "gradient");
}

inline bool IsLogoName(std::string_view name)
{
	return HasToken(name, "logo") || HasToken(name, "brand") || HasToken(name, "manufact")
		|| HasToken(name, "company") || HasToken(name, "emblem") || HasToken(name, "wordmark");
}

// Only a named decorative shape. Containers, masks, and hit areas stay visible.
inline FadeKind ClassifyFade(InteriorPanel panel, const InteriorChild& child)
{
	if (child.hasText || child.canHoldContent || child.childCount > 0) return FadeKind::None;
	if (child.isMask || child.isHit || IsOurNode(child.name) || IsProtectedName(child.name)) return FadeKind::None;
	if (IsBackdropName(child.name)) return FadeKind::Backdrop;
	if (panel == InteriorPanel::Module && IsLogoName(child.name)) return FadeKind::Logo;
	return FadeKind::None;
}

enum class FadeAction { Leave, Fade, Restore };

// A node faded while empty is checked again. Content, a mask, or a hit target restores it.
inline FadeAction DecideFade(bool alreadyFaded, InteriorPanel panel, const InteriorChild& child)
{
	const bool eligible = ClassifyFade(panel, child) != FadeKind::None;
	if (eligible && !alreadyFaded) return FadeAction::Fade;
	if (!eligible && alreadyFaded) return FadeAction::Restore;
	return FadeAction::Leave;
}

// The plate is drawn on the frame behind the clip. Nothing is inserted into the clip.
inline bool MayInsertInsideClip()
{
	return false;
}

inline int Luma(int rgb)
{
	const int r = (rgb >> 16) & 255;
	const int g = (rgb >> 8) & 255;
	const int b = rgb & 255;
	return (r * 3 + g * 6 + b) / 10;
}

inline bool HeadingName(std::string_view name)
{
	return HasToken(name, "header") || HasToken(name, "title") || HasToken(name, "categor") || HasToken(name, "label")
		|| HasToken(name, "tab");
}

// Dark text is the game's selected-row treatment. Leave it so the row stays readable.
inline TextStyle StyleText(int rgb, std::string_view name)
{
	TextStyle out;
	out.keepFace = true;
	out.keepEmbed = true;
	if (Luma(rgb) < 90) {
		out.color = rgb;
		return out;
	}
	out.color = HeadingName(name) ? kGold : kOffwhite;
	return out;
}

inline int HeadingPx(bool large)
{
	return large ? 16 : 13;
}

inline int TitlePx(bool large)
{
	return large ? 20 : 16;
}

inline bool ShowBuilderTitle(bool browserLive)
{
	return browserLive;
}

// Power pips are drawn by the game. A plate on that clip can cover them.
inline bool MayCoverWithPlate(InteriorPanel panel)
{
	return panel != InteriorPanel::Power;
}

// The game card's own fields are never moved. The Selected Module card shows the data.
inline bool MayMoveModuleFields()
{
	return false;
}

} // namespace hsb
