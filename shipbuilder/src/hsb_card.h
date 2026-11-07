#pragma once

// Purpose: the rules the gold movie follows for the Selected Module card.
// The card reads ModuleInfo only. Numbers go through the game's FormatNumberToString,
// so a value reads as it does on the game card. The game card stays in place at alpha 0.
// Author: Moragar. Last modified: 2026-11-07.

#include "hsb_arrange.h"

#include <algorithm>
#include <charconv>
#include <cmath>
#include <cstdint>
#include <string>
#include <string_view>
#include <system_error>
#include <vector>

namespace hsb {

// ModuleInfoCard shows ten stats and two skills.
inline constexpr int kCardStats = 10;
inline constexpr int kCardSkills = 2;

struct CardMetrics {
	int width = 350;
	int pad = 18;
	int headPx = 13;
	int namePx = 21;
	int bodyPx = 14;
	int chipPx = 13;
	int bigPx = 26;
	int rowPitch = 30;
	int chipH = 22;
	int barH = 24;
	int valueRight = 265;
};

// Mock 1 measured at 1920 wide. The large movie keeps its 16 px floor.
inline CardMetrics CardSize(bool large)
{
	if (large) return {410, 20, 16, 24, 16, 16, 30, 34, 26, 28, 310};
	return {350, 18, 13, 21, 14, 13, 26, 30, 22, 24, 265};
}

inline int CardSmallestPx(const CardMetrics& m)
{
	return std::min({m.headPx, m.namePx, m.bodyPx, m.chipPx, m.bigPx});
}

// AS3 Number.toString in fixed notation, for the magnitudes a stat uses.
inline std::string NumberText(double value)
{
	if (std::isnan(value)) return "NaN";
	if (std::isinf(value)) return value < 0 ? "-Infinity" : "Infinity";
	if (value == 0) return "0";
	char buf[512];
	const auto out = std::to_chars(buf, buf + sizeof(buf), value, std::chars_format::fixed);
	if (out.ec != std::errc{}) return "NaN";
	return std::string(buf, out.ptr);
}

// GlobalFunc.FormatNumberToString(value, places) with its third argument false.
// The text is cut after the given places. It does not round and adds no group marks.
inline std::string FormatNumberText(std::string_view text, unsigned places)
{
	const auto dot = text.find('.');
	if (dot == std::string_view::npos) return std::string(text);
	if (places == 0) return std::string(text.substr(0, dot));
	return std::string(text.substr(0, std::min<std::size_t>(dot + places + 1, text.size())));
}

inline std::string FormatNumber(double value, unsigned places = 0)
{
	return FormatNumberText(NumberText(value), places);
}

// String.fromCharCode: the low 16 bits of the whole part, written as UTF-8.
inline std::string CharCodeText(double code)
{
	std::uint32_t unit = 0;
	if (std::isfinite(code)) {
		const double whole = std::fmod(std::trunc(code), 65536.0);
		unit = static_cast<std::uint32_t>(whole < 0 ? whole + 65536.0 : whole);
	}
	std::string out;
	if (unit < 0x80) {
		out.push_back(static_cast<char>(unit));
	} else if (unit < 0x800) {
		out.push_back(static_cast<char>(0xC0 | (unit >> 6)));
		out.push_back(static_cast<char>(0x80 | (unit & 0x3F)));
	} else {
		out.push_back(static_cast<char>(0xE0 | (unit >> 12)));
		out.push_back(static_cast<char>(0x80 | ((unit >> 6) & 0x3F)));
		out.push_back(static_cast<char>(0x80 | (unit & 0x3F)));
	}
	return out;
}

// One aStats entry: text is a $ key or plain text, as the payload sends it.
struct CardStat {
	std::string_view text;
	double value = 0;
	double diff = 0;
	bool percentage = false;
};

enum class DiffTone { Same, Higher, Lower };

// The game's frame choice. A missing or NaN diff is Default.
inline DiffTone ToneOf(double diff)
{
	if (diff > 0) return DiffTone::Higher;
	if (diff < 0) return DiffTone::Lower;
	return DiffTone::Same;
}

inline bool IsClassStat(std::string_view text)
{
	return text == "$CLASS";
}

// ModuleInfoCard.UpdateValues: a class letter, a percent cut to a whole number, or two places.
inline std::string StatValueText(const CardStat& stat)
{
	if (IsClassStat(stat.text)) return CharCodeText(stat.value);
	if (stat.percentage) return FormatNumber(stat.value * 100) + "%";
	return FormatNumber(stat.value, 2);
}

// The game shows a change by frame only. The chip prints that diff with the value's rule.
// A class change has no number to print, so its chip is the sign alone.
inline std::string DiffChipText(const CardStat& stat)
{
	const DiffTone tone = ToneOf(stat.diff);
	if (tone == DiffTone::Same) return {};
	const std::string sign = tone == DiffTone::Higher ? "+" : "-";
	if (IsClassStat(stat.text)) return sign;
	const double size = std::fabs(stat.diff);
	if (stat.percentage) return sign + FormatNumber(size * 100) + "%";
	return sign + FormatNumber(size, 2);
}

inline int CardStatRows(int count)
{
	return std::clamp(count, 0, kCardStats);
}

inline int CardSkillRows(int count)
{
	return std::clamp(count, 0, kCardSkills);
}

// iModuleCost and iModuleMass. A field the payload did not send stays blank.
inline std::string CardNumberText(bool present, double value)
{
	return present ? FormatNumber(value) : std::string();
}

// GlobalFunc.DoSubstitutions: each {n} becomes the nth value.
inline std::string Substitute(std::string_view text, const std::vector<std::string>& values)
{
	std::string out(text);
	for (std::size_t i = 0; i < values.size() && i < 10; ++i) {
		const std::string token = "{" + std::to_string(i) + "}";
		for (std::size_t at = out.find(token); at != std::string::npos; at = out.find(token, at + values[i].size()))
			out.replace(at, token.size(), values[i]);
	}
	return out;
}

// The movie upper-cases a label only after the field has translated it.
inline bool LabelKeptKey(std::string_view shown)
{
	return !shown.empty() && shown.front() == '$';
}

enum class CardGate { Face, Conflict, Map, Clip, Data, Hidden, Hangar, On };

struct CardState {
	bool faceProven = false;
	bool conflict = false;
	bool mapped = false;
	bool nativeSeated = false;
	bool hasName = false;
	bool showWidget = false;
	bool nativeShown = false;
	bool hangarShown = false;
};

// First failing check wins, so the log names one reason.
inline CardGate ModuleCardGate(const CardState& s)
{
	if (!s.faceProven) return CardGate::Face;
	if (s.conflict) return CardGate::Conflict;
	if (!s.mapped) return CardGate::Map;
	if (!s.nativeSeated) return CardGate::Clip;
	if (!s.hasName) return CardGate::Data;
	if (!s.showWidget || !s.nativeShown) return CardGate::Hidden;
	if (s.hangarShown) return CardGate::Hangar;
	return CardGate::On;
}

inline const char* CardGateName(CardGate gate)
{
	switch (gate) {
	case CardGate::Face: return "face";
	case CardGate::Conflict: return "conflict";
	case CardGate::Map: return "map";
	case CardGate::Clip: return "clip";
	case CardGate::Data: return "data";
	case CardGate::Hidden: return "hidden";
	case CardGate::Hangar: return "hangar";
	case CardGate::On: return "on";
	}
	return "face";
}

// Only the game card's alpha changes, and only while ours is up.
inline float NativeCardAlpha(CardGate gate, float saved)
{
	return gate == CardGate::On ? 0.0f : saved;
}

// Our card's top left is the game card's top left.
inline ArrangeBox CardSeat(const ArrangeBox& native, int cardW, int cardH)
{
	return {native.x, native.y, cardW, cardH};
}

struct ArrangeView {
	int x = 0;
	int y = 0;
	int w = 1920;
	int h = 1080;
};

// AS3 Math.round: halves go up.
inline int RoundHalfUp(double value)
{
	return static_cast<int>(std::floor(value + 0.5));
}

// The movie's storeAnchor for one axis. Near the middle sixth the anchor is C.
inline std::string StoreAnchor(bool xAxis, int pos, int size, int viewPos, int viewSize, int margin)
{
	const double mid = pos + size / 2.0;
	const double center = viewPos + viewSize / 2.0;
	if (std::fabs(mid - center) < viewSize / 6.0)
		return "C" + std::to_string(RoundHalfUp(pos - (center - size / 2.0)));
	if (mid < center)
		return std::string(xAxis ? "L" : "T") + std::to_string(RoundHalfUp(pos - (viewPos + margin)));
	return std::string(xAxis ? "R" : "B") + std::to_string(RoundHalfUp(viewPos + viewSize - margin - size - pos));
}

// The movie's resolveX and resolveY. A value it cannot read keeps the current spot.
inline double ResolveAnchor(bool xAxis, std::string_view value, double current, int size, int viewPos, int viewSize, int margin)
{
	const std::string v = Trim(value);
	if (v == "-1" || v.size() < 2) return current;
	bool ok = false;
	const int off = ParseInt(v.substr(1), ok);
	if (!ok) return current;
	const char edge = v[0];
	if (edge == (xAxis ? 'L' : 'T')) return viewPos + margin + off;
	if (edge == (xAxis ? 'R' : 'B')) return viewPos + viewSize - margin - size - off;
	if (edge == 'C') return viewPos + (viewSize - size) / 2.0 + off;
	return current;
}

// placeNative: resolve with the game card's size, then keep that box on screen.
inline ArrangeBox PlaceSaved(std::string_view ax, std::string_view ay, ArrangeBox native, const ArrangeView& view, int margin)
{
	int x = static_cast<int>(ResolveAnchor(true, ax, native.x, native.w, view.x, view.w, margin));
	int y = static_cast<int>(ResolveAnchor(false, ay, native.y, native.h, view.y, view.h, margin));
	x = ClampSpan(x, view.x, view.x + view.w - native.w);
	y = ClampSpan(y, view.y, view.y + view.h - native.h);
	return {x, y, native.w, native.h};
}

// A drag keeps both boxes on screen, so a saved spot reloads without a clamp moving it.
inline ArrangeBox CardMoveSpan(const ArrangeBox& card, const ArrangeBox& native)
{
	return {card.x, card.y, std::max(card.w, native.w), std::max(card.h, native.h)};
}

struct CardDrag {
	ArrangeBox native;
	ArrangeBox card;
	std::string ax;
	std::string ay;
};

// moveLive with our card up: the outline is our card, the game card moves by the same
// step, and the anchor is stored with the game card's size.
inline CardDrag DragCard(ArrangeBox native, int cardW, int cardH, int toX, int toY, const ArrangeView& view, int margin)
{
	const ArrangeBox card = CardSeat(native, cardW, cardH);
	const ArrangeBox span = CardMoveSpan(card, native);
	int x = SnapTo(toX, view.x, kSnap);
	int y = SnapTo(toY, view.y, kSnap);
	x = ClampSpan(x, view.x, view.x + view.w - span.w);
	y = ClampSpan(y, view.y, view.y + view.h - span.h);
	native.x += x - card.x;
	native.y += y - card.y;
	CardDrag out;
	out.native = native;
	out.card = CardSeat(native, cardW, cardH);
	out.ax = StoreAnchor(true, x, native.w, view.x, view.w, margin);
	out.ay = StoreAnchor(false, y, native.h, view.y, view.h, margin);
	return out;
}

} // namespace hsb
