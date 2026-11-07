#pragma once

// Purpose: which vanilla children may be faded, and how live text is restyled.
// The movie applies these rules inside the game clips. It does not remove them.
// Author: Moragar. Last modified: 2026-11-07.

#include <cstdint>
#include <string_view>

namespace hsb {

enum class InteriorPanel { Power, Module, Browser, Credits, Stats, Other };

enum class FadeKind { None, Backdrop, Logo };

enum class ModuleSlot { Skip, Name, Description, Value, Mass };

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

struct ModuleField {
	std::string_view name;
	std::string_view text;
};

struct ModulePlace {
	int index = -1;
	ModuleSlot slot = ModuleSlot::Skip;
	int x = 0;
	int y = 0;
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

inline bool IsProtectedName(std::string_view name)
{
	return HasToken(name, "entry") || HasToken(name, "categor") || HasToken(name, "scroll") || HasToken(name, "button")
		|| HasToken(name, "slider") || HasToken(name, "pip") || HasToken(name, "input") || HasToken(name, "list")
		|| HasToken(name, "tab") || HasToken(name, "select") || HasToken(name, "alloc") || HasToken(name, "meter")
		|| HasToken(name, "reactor") || HasToken(name, "equip");
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

inline bool HasLetter(std::string_view text)
{
	for (char c : text) {
		const char f = FoldInterior(c);
		if (f >= 'a' && f <= 'z') return true;
	}
	return false;
}

inline bool NumericText(std::string_view text)
{
	if (text.empty() || text.size() > 8) return false;
	bool digit = false;
	for (char c : text) {
		if (c >= '0' && c <= '9') digit = true;
		else if (c != ',' && c != '.' && c != ' ') return false;
	}
	return digit;
}

inline ModuleSlot SlotOf(std::string_view name, std::string_view text)
{
	if (HasToken(name, "mass")) return ModuleSlot::Mass;
	if (HasToken(name, "value") || HasToken(name, "cost") || HasToken(name, "credit")) return ModuleSlot::Value;
	if (HasToken(name, "desc") || HasToken(name, "flavor") || HasToken(name, "summary")) return ModuleSlot::Description;
	if (HasToken(name, "name") || HasToken(name, "title") || HasToken(name, "header")) return ModuleSlot::Name;
	(void)text;
	return ModuleSlot::Skip;
}

// Places only fields that already exist. Missing slots stay empty.
inline int PlaceModule(const ModuleField* fields, int count, int cardW, int cardH, ModulePlace* out, int outMax)
{
	if (!fields || !out || count <= 0 || outMax <= 0) return 0;
	int name = -1;
	int desc = -1;
	int value = -1;
	int mass = -1;
	for (int i = 0; i < count; ++i) {
		const ModuleSlot slot = SlotOf(fields[i].name, fields[i].text);
		if (slot == ModuleSlot::Name && name < 0) name = i;
		else if (slot == ModuleSlot::Description && desc < 0) desc = i;
		else if (slot == ModuleSlot::Value && value < 0) value = i;
		else if (slot == ModuleSlot::Mass && mass < 0) mass = i;
	}
	if (name < 0 || desc < 0) {
		int longest = -1;
		for (int i = 0; i < count; ++i) {
			if (!HasLetter(fields[i].text) || fields[i].text.size() < 4) continue;
			if (i == name || i == desc || i == value || i == mass) continue;
			if (longest < 0 || fields[i].text.size() > fields[longest].text.size()) longest = i;
		}
		if (desc < 0 && longest >= 0 && fields[longest].text.size() >= 12) desc = longest;
		if (name < 0) {
			for (int i = 0; i < count; ++i) {
				if (i == desc || i == value || i == mass) continue;
				if (!HasLetter(fields[i].text) || fields[i].text.size() < 4 || fields[i].text.size() > 48) continue;
				name = i;
				break;
			}
		}
	}
	if (value < 0 || mass < 0) {
		for (int i = 0; i < count; ++i) {
			if (i == name || i == desc || i == value || i == mass) continue;
			if (!NumericText(fields[i].text)) continue;
			if (value < 0) value = i;
			else if (mass < 0) mass = i;
		}
	}
	const int yName = 36;
	const int yDesc = 68;
	int yStat = cardH - 56;
	if (yStat < yDesc + 28) yStat = yDesc + 28;
	const int xMass = cardW > 40 ? cardW / 2 : 16;
	int n = 0;
	auto push = [&](int index, ModuleSlot slot, int x, int y) {
		if (index < 0 || n >= outMax) return;
		out[n].index = index;
		out[n].slot = slot;
		out[n].x = x;
		out[n].y = y;
		++n;
	};
	push(name, ModuleSlot::Name, 16, yName);
	push(desc, ModuleSlot::Description, 16, yDesc);
	push(value, ModuleSlot::Value, 16, yStat);
	push(mass, ModuleSlot::Mass, xMass, yStat);
	return n;
}

} // namespace hsb
