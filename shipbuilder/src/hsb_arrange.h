#pragma once

// Purpose: pure rules for Arrange, the gold accent, and the user ini.
// No game calls. The movie and the plugin both follow these rules.
// Author: Moragar. Last modified: 2026-11-07.

#include "hsb_guard.h"

#include <array>
#include <cstdint>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace hsb {

inline constexpr int kMarginDefault = 34;
inline constexpr int kAccentDefault = 9;
inline constexpr int kAccentGold = 0xE8C547;
inline constexpr int kSnap = 10;
inline constexpr int kGrid = 40;
inline constexpr int kNudge = 10;
inline constexpr int kNudgeFast = 40;
inline constexpr int kOffsetLimit = 4000;

// F6, F7, F8. Off unless the user ini turns the probe on.
inline constexpr unsigned kVkF6 = 0x75;
inline constexpr unsigned kVkF7 = 0x76;
inline constexpr unsigned kVkF8 = 0x77;
inline constexpr unsigned kVkL = 'L';
inline constexpr unsigned kVkEsc = 0x1B;
inline constexpr unsigned kVkReturn = 0x0D;
inline constexpr unsigned kVkLeft = 0x25;
inline constexpr unsigned kVkUp = 0x26;
inline constexpr unsigned kVkRight = 0x27;
inline constexpr unsigned kVkDown = 0x28;
inline constexpr unsigned kVkTab = 0x09;
inline constexpr unsigned kVkPrior = 0x21;
inline constexpr unsigned kVkNext = 0x22;
inline constexpr unsigned kVkDelete = 0x2E;
inline constexpr unsigned kVkBack = 0x08;

inline bool IsProbeHotkey(bool debug, unsigned vk)
{
	if (!debug) return false;
	return vk == kVkF6 || vk == kVkF7 || vk == kVkF8;
}

// Bare L is not an entry key. Ctrl+L is the fallback that does not take a vanilla builder key.
inline bool IsArrangeEntry(bool captured, bool ctrl, unsigned vk)
{
	return !captured && ctrl && (vk == kVkL || vk == 'l');
}

// While Arrange or the settings popup is up, keys do not reach the builder.
// Mouse is eaten only in Arrange, so a drag cannot move the ship.
inline bool EatKey(bool captured)
{
	return captured;
}

inline bool EatMouse(bool arranging)
{
	return arranging;
}

// Esc and Enter act on release, as the game's buttons do. Arrange's other keys act on the
// press, so a held key repeats.
inline bool KeyTokenOnRelease(unsigned vk)
{
	return vk == kVkEsc || vk == kVkReturn;
}

struct EdgeCall
{
	bool eat = false;
	bool feed = false;
};

// The game gets both halves of a press or neither. A release, or a repeat, follows what the hook
// did with the first press, even after capture or Arrange ends. pressEaten says the hook ate
// the first press of this key or button.
inline EdgeCall KeyEdge(bool down, bool repeat, bool captured, bool pressEaten, unsigned vk)
{
	EdgeCall call;
	if (!down) call.eat = pressEaten;
	else if (repeat) call.eat = EatKey(captured) || pressEaten;
	else call.eat = EatKey(captured);
	call.feed = call.eat && EatKey(captured) && down != KeyTokenOnRelease(vk);
	return call;
}

inline EdgeCall MouseEdge(bool button, bool release, bool arranging, bool pressEaten)
{
	EdgeCall call;
	call.eat = button && release ? pressEaten : EatMouse(arranging);
	call.feed = call.eat && EatMouse(arranging);
	return call;
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

// Swallowed keys that Arrange itself does not use. Delete and Backspace stay unbound.
inline const char* ArrangeKeyToken(unsigned vk, bool shift)
{
	switch (vk) {
	case kVkEsc: return "cancel";
	case kVkReturn: return "ok";
	case kVkLeft: return shift ? "left40" : "left";
	case kVkRight: return shift ? "right40" : "right";
	case kVkUp: return shift ? "up40" : "up";
	case kVkDown: return shift ? "down40" : "down";
	case kVkTab: return shift ? "tabprev" : "tab";
	case kVkPrior: return "tabprev";
	case kVkNext: return "tab";
	case kVkDelete: return "noop";
	case kVkBack: return "noop";
	default: return "";
	}
}

inline int SnapTo(int value, int origin, int grid)
{
	if (grid <= 1) return value;
	const int delta = value - origin;
	int steps = delta / grid;
	const int rem = delta % grid;
	if (rem >= grid / 2) ++steps;
	if (rem <= -((grid + 1) / 2)) --steps;
	return origin + steps * grid;
}

inline int ClampSpan(int value, int lo, int hi)
{
	if (hi < lo) return lo;
	if (value < lo) return lo;
	if (value > hi) return hi;
	return value;
}

// Arrange handles are live panels we can translate without taking them off the menu.
// Credits and the button bar are not handles: the menu writes their x and y.
struct ArrangeBox {
	int x = 0;
	int y = 0;
	int w = 0;
	int h = 0;
};

struct ArrangePanel {
	std::string_view id;
	bool live = false;
	ArrangeBox bounds{};
};

inline bool ArrangeMovableId(std::string_view id)
{
	return id == "Power" || id == "Module" || id == "Browser" || id == "Stats" || id == "Cluster";
}

inline bool ArrangeEligible(const ArrangePanel& panel)
{
	if (!panel.live || !ArrangeMovableId(panel.id)) return false;
	return panel.bounds.w >= 24 && panel.bounds.h >= 24;
}

inline int ArrangeDefault(const ArrangePanel* panels, int count)
{
	if (!panels || count <= 0) return -1;
	for (int i = 0; i < count; ++i) {
		if (ArrangeEligible(panels[i])) return i;
	}
	return -1;
}

inline int ArrangeHit(const ArrangePanel* panels, int count, int x, int y)
{
	if (!panels || count <= 0) return -1;
	for (int i = count - 1; i >= 0; --i) {
		if (!ArrangeEligible(panels[i])) continue;
		const ArrangeBox& b = panels[i].bounds;
		if (x >= b.x && x <= b.x + b.w && y >= b.y && y <= b.y + b.h) return i;
	}
	return -1;
}

inline int ArrangeCycle(const ArrangePanel* panels, int count, int selected, int dir)
{
	if (!panels || count <= 0 || dir == 0) return -1;
	int ids[8];
	int n = 0;
	for (int i = 0; i < count && n < 8; ++i) {
		if (ArrangeEligible(panels[i])) ids[n++] = i;
	}
	if (n == 0) return -1;
	int pos = -1;
	for (int i = 0; i < n; ++i) {
		if (ids[i] == selected) pos = i;
	}
	if (pos < 0) return dir > 0 ? ids[0] : ids[n - 1];
	const int step = dir > 0 ? 1 : -1;
	int next = pos + step;
	if (next < 0) next = n - 1;
	if (next >= n) next = 0;
	return ids[next];
}

inline ArrangeBox ArrangeShift(ArrangeBox bounds, int dx, int dy, int originX, int originY, int viewX, int viewY, int viewW, int viewH)
{
	const int x = SnapTo(bounds.x + dx, originX, kSnap);
	const int y = SnapTo(bounds.y + dy, originY, kSnap);
	bounds.x = ClampSpan(x, viewX, viewX + viewW - bounds.w);
	bounds.y = ClampSpan(y, viewY, viewY + viewH - bounds.h);
	return bounds;
}

// A rejected move leaves the native bounds alone. A kept move is the new native position.
inline bool ArrangeTryMove(ArrangePanel& panel, int dx, int dy, int originX, int originY, int viewX, int viewY, int viewW, int viewH)
{
	if (!ArrangeEligible(panel)) return false;
	panel.bounds = ArrangeShift(panel.bounds, dx, dy, originX, originY, viewX, viewY, viewW, viewH);
	return true;
}

inline ArrangeBox ArrangeFrame(ArrangeBox native, int pad)
{
	native.x -= pad;
	native.y -= pad;
	native.w += pad * 2;
	native.h += pad * 2;
	return native;
}

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

inline bool IsStyleKey(std::string_view key)
{
	return EqualsFold(key, "AccentColor") || EqualsFold(key, "AccentHex") || EqualsFold(key, "ScreenMargin") ||
		EqualsFold(key, "Probe") || EqualsFold(key, "Arrange");
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
	const char edge = v[0];
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

// Merge changed keys into the user file. Defaults are dropped. Other sections stay.
inline std::string MergeUserIni(std::string_view existing, const std::vector<std::pair<std::string, std::string>>& updates)
{
	struct Row { std::string key, value; };
	std::vector<std::pair<std::string, std::vector<std::string>>> sections;
	std::vector<Row> arrange;
	std::vector<Row> style;
	auto findRow = [](std::vector<Row>& rows, std::string_view key) -> Row* {
		for (auto& row : rows) {
			if (EqualsFold(row.key, key)) return &row;
		}
		return nullptr;
	};
	std::string current;
	bool seenArrange = false;
	bool seenStyle = false;
	auto flushLine = [&](const std::string& line) {
		if (EqualsFold(current, "Arrange")) {
			std::string key, value;
			if (SplitKey(line, key, value) && IsArrangeKey(key) && ValidArrangeValue(key, value) && !IsDefaultArrange(key, value)) {
				const std::string canon = CanonArrange(key, value);
				const auto eq = canon.find('=');
				Row row{canon.substr(0, eq), canon.substr(eq + 1)};
				if (Row* have = findRow(arrange, row.key)) have->value = row.value;
				else arrange.push_back(row);
			}
			return;
		}
		if (EqualsFold(current, "Style") || EqualsFold(current, "Layout") || EqualsFold(current, "Debug") || EqualsFold(current, "Keys")) {
			std::string key, value;
			if (SplitKey(line, key, value)) {
				if (Row* have = findRow(style, key)) have->value = value;
				else style.push_back(Row{key, value});
			}
			return;
		}
		if (!sections.empty()) sections.back().second.push_back(line);
	};
	std::size_t at = 0;
	while (at <= existing.size()) {
		const auto next = existing.find('\n', at);
		std::string line(existing.substr(at, next == std::string::npos ? std::string::npos : next - at));
		if (!line.empty() && line.back() == '\r') line.pop_back();
		const std::string sec = SectionName(line);
		if (!sec.empty()) {
			current = sec;
			if (EqualsFold(sec, "Arrange")) seenArrange = true;
			else if (EqualsFold(sec, "Style") || EqualsFold(sec, "Layout") || EqualsFold(sec, "Debug") || EqualsFold(sec, "Keys")) {
				if (!seenStyle) seenStyle = true;
			} else {
				sections.push_back({sec, {}});
			}
		} else {
			flushLine(line);
		}
		if (next == std::string::npos) break;
		at = next + 1;
	}
	(void)seenArrange;
	(void)seenStyle;
	for (const auto& upd : updates) {
		if (IsArrangeKey(upd.first)) {
			if (!ValidArrangeValue(upd.first, upd.second)) continue;
			if (IsDefaultArrange(upd.first, upd.second)) {
				const std::string canon = CanonArrange(upd.first, upd.second);
				const auto eq = canon.find('=');
				const std::string key = canon.substr(0, eq);
				std::vector<Row> kept;
				for (const auto& row : arrange) {
					if (!EqualsFold(row.key, key)) kept.push_back(row);
				}
				arrange.swap(kept);
				continue;
			}
			const std::string canon = CanonArrange(upd.first, upd.second);
			const auto eq = canon.find('=');
			Row row{canon.substr(0, eq), canon.substr(eq + 1)};
			if (Row* have = findRow(arrange, row.key)) have->value = row.value;
			else arrange.push_back(std::move(row));
			continue;
		}
		if (!IsStyleKey(upd.first)) continue;
		if (EqualsFold(upd.first, "AccentColor")) {
			bool ok = false;
			const int n = ParseInt(Trim(upd.second), ok);
			if (!ok || n < -1 || n > 13) continue;
			if (n == kAccentDefault) {
				std::vector<Row> kept;
				for (const auto& row : style) {
					if (!EqualsFold(row.key, "AccentColor")) kept.push_back(row);
				}
				style.swap(kept);
				continue;
			}
		}
		if (EqualsFold(upd.first, "AccentHex")) {
			if (!ValidHex(upd.second)) continue;
		}
		if (EqualsFold(upd.first, "ScreenMargin")) {
			bool ok = false;
			const int n = ParseInt(Trim(upd.second), ok);
			if (!ok || n < 0 || n > 200) continue;
			if (n == kMarginDefault) {
				std::vector<Row> kept;
				for (const auto& row : style) {
					if (!EqualsFold(row.key, "ScreenMargin")) kept.push_back(row);
				}
				style.swap(kept);
				continue;
			}
		}
		if (EqualsFold(upd.first, "Probe")) {
			const std::string v = Trim(upd.second);
			if (v == "0") {
				std::vector<Row> kept;
				for (const auto& row : style) {
					if (!EqualsFold(row.key, "Probe")) kept.push_back(row);
				}
				style.swap(kept);
				continue;
			}
			if (v != "1") continue;
		}
		if (Row* have = findRow(style, upd.first)) have->value = Trim(upd.second);
		else style.push_back(Row{std::string(upd.first), Trim(upd.second)});
	}
	std::string out;
	auto addSection = [&](const char* name, const std::vector<Row>& rows) {
		if (rows.empty()) return;
		if (!out.empty() && out.back() != '\n') out.push_back('\n');
		out += "[";
		out += name;
		out += "]\n";
		for (const auto& row : rows) {
			out += row.key;
			out += "=";
			out += row.value;
			out += "\n";
		}
	};
	std::vector<Row> styleRows, layoutRows, debugRows, keyRows;
	for (const auto& row : style) {
		if (EqualsFold(row.key, "AccentColor") || EqualsFold(row.key, "AccentHex")) styleRows.push_back(row);
		else if (EqualsFold(row.key, "ScreenMargin")) layoutRows.push_back(row);
		else if (EqualsFold(row.key, "Probe")) debugRows.push_back(row);
		else if (EqualsFold(row.key, "Arrange")) keyRows.push_back(row);
	}
	addSection("Style", styleRows);
	addSection("Layout", layoutRows);
	addSection("Debug", debugRows);
	addSection("Keys", keyRows);
	addSection("Arrange", arrange);
	for (const auto& sec : sections) {
		if (!out.empty() && out.back() != '\n') out.push_back('\n');
		out += "[";
		out += sec.first;
		out += "]\n";
		for (const auto& line : sec.second) {
			if (Trim(line).empty()) continue;
			out += line;
			out += "\n";
		}
	}
	return out;
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
