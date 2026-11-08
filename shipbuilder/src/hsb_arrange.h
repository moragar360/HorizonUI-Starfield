#pragma once

// Purpose: pure rules for Arrange values, the gold accent, and the user ini path.
// No game calls. The movie and the plugin both follow these rules. Settings whitelist and
// merging live in hsb_settings.h; window input rules live in hsb_input.h.
// Author: Moragar. Last modified: 2026-11-07.

#include "hsb_guard.h"

#include <array>
#include <string>
#include <string_view>

namespace hsb {

inline constexpr int kMarginDefault = 34;
inline constexpr int kAccentDefault = 9;
inline constexpr int kAccentGold = 0xE8C547;
inline constexpr int kOffsetLimit = 4000;

// F6, F7, F8. Off unless the user ini turns the probe on.
inline constexpr unsigned kVkF6 = 0x75;
inline constexpr unsigned kVkF7 = 0x76;
inline constexpr unsigned kVkF8 = 0x77;

inline bool IsProbeHotkey(bool debug, unsigned vk)
{
	if (!debug) return false;
	return vk == kVkF6 || vk == kVkF7 || vk == kVkF8;
}

// Which keys or buttons are held from a press the hook ate. Only the window procedure uses it.
class PressLedger
{
public:
	bool Held(unsigned code) const { return code < kCodes && held_[code]; }

	void Set(unsigned code, bool eaten)
	{
		if (code < kCodes) held_[code] = eaten;
	}

	void Clear() { held_.fill(false); }

private:
	static constexpr unsigned kCodes = 256;
	std::array<bool, kCodes> held_{};
};

inline bool IsHexDigit(char c)
{
	return (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
}

inline char FoldAscii(char c)
{
	if (c >= 'A' && c <= 'Z') return static_cast<char>(c - 'A' + 'a');
	return c;
}

inline bool EqualsFold(std::string_view a, std::string_view b)
{
	if (a.size() != b.size()) return false;
	for (std::size_t i = 0; i < a.size(); ++i) {
		if (FoldAscii(a[i]) != FoldAscii(b[i])) return false;
	}
	return true;
}

inline std::string Trim(std::string_view text)
{
	std::size_t a = 0;
	while (a < text.size() && (text[a] == ' ' || text[a] == '\t' || text[a] == '\r')) ++a;
	std::size_t b = text.size();
	while (b > a && (text[b - 1] == ' ' || text[b - 1] == '\t' || text[b - 1] == '\r')) --b;
	return std::string(text.substr(a, b - a));
}

inline bool KnownPanel(std::string_view name)
{
	return EqualsFold(name, "Power") || EqualsFold(name, "Module") || EqualsFold(name, "Credits") ||
		EqualsFold(name, "Browser") || EqualsFold(name, "Stats") || EqualsFold(name, "Hints") ||
		EqualsFold(name, "Cluster");
}

inline bool IsArrangeKey(std::string_view key)
{
	if (EqualsFold(key, "ArrangeBarX") || EqualsFold(key, "ArrangeBarY")) return true;
	if (key.size() < 2) return false;
	const char axis = key.back();
	if (axis != 'X' && axis != 'x' && axis != 'Y' && axis != 'y') return false;
	return KnownPanel(key.substr(0, key.size() - 1));
}

inline int ParseInt(std::string_view text, bool& ok)
{
	ok = false;
	if (text.empty()) return 0;
	std::size_t i = 0;
	int sign = 1;
	if (text[0] == '+') i = 1;
	else if (text[0] == '-') {
		sign = -1;
		i = 1;
	}
	if (i >= text.size()) return 0;
	int value = 0;
	for (; i < text.size(); ++i) {
		if (text[i] < '0' || text[i] > '9') return 0;
		value = value * 10 + (text[i] - '0');
	}
	ok = true;
	return sign * value;
}

inline bool ValidHex(std::string_view text)
{
	std::string_view body = text;
	if (!body.empty() && body[0] == '#') body.remove_prefix(1);
	if (body.size() != 6) return false;
	for (char c : body) {
		if (!IsHexDigit(c)) return false;
	}
	return true;
}

inline std::string CanonHex(std::string_view text)
{
	std::string out;
	for (char c : text) {
		if (c == '#') continue;
		if (c >= 'a' && c <= 'f') out.push_back(static_cast<char>(c - 'a' + 'A'));
		else out.push_back(c);
	}
	return out;
}

// -1 is the default spot. Otherwise X is L/R/C and Y is T/B/C, plus an offset.
inline bool ValidArrangeValue(std::string_view key, std::string_view value)
{
	if (!IsArrangeKey(key)) return false;
	bool ok = false;
	if (EqualsFold(key, "ArrangeBarX") || EqualsFold(key, "ArrangeBarY")) {
		const int n = ParseInt(Trim(value), ok);
		return ok && n >= -kOffsetLimit && n <= kOffsetLimit;
	}
	const std::string v = Trim(value);
	if (v == "-1") return true;
	if (v.size() < 2) return false;
	// A hand-edited file may use lower case; CanonArrange writes it back in upper case.
	const char edge = (v[0] >= 'a' && v[0] <= 'z') ? static_cast<char>(v[0] - 'a' + 'A') : v[0];
	const bool x = key.back() == 'X' || key.back() == 'x';
	const bool edgeOk = x ? (edge == 'L' || edge == 'R' || edge == 'C') : (edge == 'T' || edge == 'B' || edge == 'C');
	if (!edgeOk) return false;
	const int n = ParseInt(v.substr(1), ok);
	return ok && n >= -kOffsetLimit && n <= kOffsetLimit;
}

inline bool IsDefaultArrange(std::string_view key, std::string_view value)
{
	const std::string v = Trim(value);
	if (EqualsFold(key, "ArrangeBarX") || EqualsFold(key, "ArrangeBarY")) return v == "0";
	return v == "-1";
}

inline int ResolveAccent(int color, std::string_view hex, bool coreIniFound, int coreColor, std::string_view coreHex)
{
	int pick = color;
	std::string_view useHex = hex;
	if (pick == -1) {
		if (!coreIniFound) return kAccentDefault;
		pick = coreColor;
		useHex = coreHex;
	}
	if (pick == 13) {
		if (!ValidHex(useHex)) return kAccentDefault;
		return 13;
	}
	if (pick < 0 || pick > 12) return kAccentDefault;
	return pick;
}

inline std::string SectionName(std::string_view line)
{
	const std::string t = Trim(line);
	if (t.size() < 3 || t.front() != '[') return {};
	const auto end = t.find(']');
	if (end == std::string::npos || end < 2) return {};
	return t.substr(1, end - 1);
}

inline bool SplitKey(std::string_view line, std::string& key, std::string& value)
{
	const std::string t = Trim(line);
	if (t.empty() || t[0] == ';' || t[0] == '[') return false;
	const auto eq = t.find('=');
	if (eq == std::string::npos || eq == 0) return false;
	key = Trim(t.substr(0, eq));
	value = Trim(t.substr(eq + 1));
	const auto semi = value.find(';');
	if (semi != std::string::npos) value = Trim(value.substr(0, semi));
	return !key.empty();
}

inline std::string CanonArrange(std::string_view key, std::string_view value)
{
	if (EqualsFold(key, "ArrangeBarX")) return "ArrangeBarX=" + std::string(Trim(value));
	if (EqualsFold(key, "ArrangeBarY")) return "ArrangeBarY=" + std::string(Trim(value));
	std::string name(key.substr(0, key.size() - 1));
	if (EqualsFold(name, "Power")) name = "Power";
	else if (EqualsFold(name, "Module")) name = "Module";
	else if (EqualsFold(name, "Credits")) name = "Credits";
	else if (EqualsFold(name, "Browser")) name = "Browser";
	else if (EqualsFold(name, "Stats")) name = "Stats";
	else if (EqualsFold(name, "Hints")) name = "Hints";
	else if (EqualsFold(name, "Cluster")) name = "Cluster";
	const char axis = (key.back() == 'y' || key.back() == 'Y') ? 'Y' : 'X';
	name.push_back(axis);
	std::string v = Trim(value);
	if (!(EqualsFold(key, "ArrangeBarX") || EqualsFold(key, "ArrangeBarY")) && v.size() > 1 && v != "-1") {
		if (v[0] >= 'a' && v[0] <= 'z') v[0] = static_cast<char>(v[0] - 'a' + 'A');
	}
	return name + "=" + v;
}

inline int StyleInt(std::string_view ini, std::string_view key, int fallback)
{
	std::string section;
	std::size_t at = 0;
	const std::string text(ini);
	while (at <= text.size()) {
		const auto next = text.find('\n', at);
		std::string line = text.substr(at, next == std::string::npos ? std::string::npos : next - at);
		const std::string sec = SectionName(line);
		if (!sec.empty()) section = sec;
		else {
			std::string k, v;
			if (SplitKey(line, k, v) && EqualsFold(k, key)) {
				bool ok = false;
				const int n = ParseInt(v, ok);
				if (ok) return n;
			}
		}
		if (next == std::string::npos) break;
		at = next + 1;
		(void)section;
	}
	return fallback;
}

inline bool IniMayWrite(std::string_view path)
{
	if (path.empty() || HasDotDot(path)) return false;
	const auto slash = path.find_last_of("/\\");
	if (slash == std::string_view::npos) return false;
	if (path.substr(slash + 1) != "HorizonShipBuilder.user.ini") return false;
	if (!ContainsFold(path, "My Games") || !ContainsFold(path, "Starfield")) return false;
	if (!ContainsFold(path, "Interface") || !ContainsFold(path, "HorizonUI")) return false;
	if (!ContainsFold(path, "shipbuilder")) return false;
	if (ContainsFold(path, "steamapps")) return false;
	if (ContainsFold(path, "Saves")) return false;
	return true;
}

}  // namespace hsb
