#pragma once

// Purpose: C++ twins of the movie's number, chip and anchor rules, so the host test can
// pin them. The Selected Module card reads ModuleInfo only; numbers go through the game's
// FormatNumberToString, so a value reads as it does on the game card.
// Inputs/outputs: plain values; no game calls. The movie (HorizonShipBuilder.as statText,
// diffText, shortChip, chipNumber, storeAnchor, resolve) is the code that runs in game.
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

// AS3 Number.toString (ECMA-262 Number::toString): the shortest digits that read back,
// with an exponent below 1e-6 and from 1e21 up.
inline std::string NumberText(double value)
{
	if (std::isnan(value)) return "NaN";
	if (value == 0) return "0";
	if (std::isinf(value)) return value < 0 ? "-Infinity" : "Infinity";
	char buf[64];
	const auto out = std::to_chars(buf, buf + sizeof(buf), std::fabs(value), std::chars_format::scientific);
	if (out.ec != std::errc{}) return "NaN";
	const std::string_view sci(buf, static_cast<std::size_t>(out.ptr - buf));
	const auto e = sci.find('e');
	std::string digits;
	for (const char c : sci.substr(0, e))
		if (c != '.') digits.push_back(c);
	int exp10 = 0;
	std::string_view tail = sci.substr(e + 1);
	if (!tail.empty() && tail.front() == '+') tail.remove_prefix(1);
	std::from_chars(tail.data(), tail.data() + tail.size(), exp10);
	const std::string sign = value < 0 ? "-" : "";
	const int k = static_cast<int>(digits.size());
	const int n = exp10 + 1;
	if (k <= n && n <= 21) return sign + digits + std::string(static_cast<std::size_t>(n - k), '0');
	if (0 < n && n <= 21) return sign + digits.substr(0, n) + "." + digits.substr(n);
	if (-6 < n && n <= 0) return sign + "0." + std::string(static_cast<std::size_t>(-n), '0') + digits;
	const std::string power = std::string(n - 1 < 0 ? "-" : "+") + std::to_string(std::abs(n - 1));
	if (k == 1) return sign + digits + "e" + power;
	return sign + digits.substr(0, 1) + "." + digits.substr(1) + "e" + power;
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

// The movie's chipNumber: toFixed(6), cut after the given places, trailing zeros dropped.
// Float noise reads as 0 here, where the game's cut of toString would print exponent digits.
inline std::string ChipNumber(double size, unsigned places)
{
	if (!std::isfinite(size) || std::fabs(size) >= 1e21) return NumberText(size);
	char buf[512];
	const auto out = std::to_chars(buf, buf + sizeof(buf), size, std::chars_format::fixed, 6);
	if (out.ec != std::errc{}) return "0";
	std::string text(buf, out.ptr);
	const auto dot = text.find('.');
	if (dot == std::string::npos) return text;
	text = places > 0 ? text.substr(0, dot + 1 + places) : text.substr(0, dot);
	if (text.find('.') != std::string::npos) {
		while (!text.empty() && text.back() == '0') text.pop_back();
		if (!text.empty() && text.back() == '.') text.pop_back();
	}
	return text;
}

// The game shows a change by frame only, so the chip is new text. A class change has no
// number to print, so its chip is the sign alone. A diff that reads 0 gets no chip.
inline std::string DiffChipText(const CardStat& stat)
{
	const DiffTone tone = ToneOf(stat.diff);
	if (tone == DiffTone::Same) return {};
	const std::string sign = tone == DiffTone::Higher ? "+" : "-";
	if (IsClassStat(stat.text)) return sign;
	const double size = std::fabs(stat.diff);
	const std::string text = stat.percentage ? ChipNumber(size * 100, 0) : ChipNumber(size, 2);
	if (text == "0") return {};
	return sign + text + (stat.percentage ? "%" : "");
}

// The movie's shortChip: a chip too wide for its room drops its places, as a cut would.
// A whole part of 0 would read as no change, so that chip keeps its sign alone. A chip
// still too wide after that is the sign alone.
inline std::string ShortChip(std::string_view chip)
{
	if (chip.empty()) return {};
	const auto dot = chip.find('.');
	if (dot == std::string_view::npos || chip.find('e') != std::string_view::npos) return std::string(chip.substr(0, 1));
	const std::string_view whole = chip.substr(0, dot);
	if (whole.size() == 2 && whole[1] == '0') return std::string(chip.substr(0, 1));
	return std::string(whole);
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

// The movie's resolve for one axis. A value it cannot read keeps the current spot.
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

} // namespace hsb
