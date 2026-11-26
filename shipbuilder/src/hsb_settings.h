#pragma once

// Purpose: the user ini whitelist and merge for protocol 0.2.
// Inputs: "SET Section.Key=value" and "ARRANGE Key=value" lines from the movie, and the
// current text of HorizonShipBuilder.user.ini.
// Outputs: canonical settings, and the merged file text. A value equal to its default is
// removed, so the user file only holds what the player changed. Unknown lines and comments
// in the file are kept as they are.
// Dependencies: hsb_arrange.h (Arrange values, hex, trim, fold). No game calls.
// Author: Moragar. Last modified: 2026-11-08.

#include "hsb_arrange.h"

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace hsb {

inline constexpr int kMarginMax = 120;
inline constexpr int kOpacityMinHundredths = 40;
inline constexpr int kScaleMinHundredths = 80;
inline constexpr int kScaleMaxHundredths = 130;
inline constexpr std::size_t kMaxColumnKey = 36;
inline constexpr std::size_t kMaxColumnId = 32;
inline constexpr std::size_t kMaxColumns = 8;
inline constexpr std::size_t kMaxSettingUpdates = 128;

// The keys the movie's key picker can bind (HsbSettings BINDABLE). ; and # would read as
// an ini comment, and the plugin matches hotkeys by the unshifted key character.
inline constexpr std::string_view kBindableKeys = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/\\.,-=[]'`";

struct Setting {
	std::string section;
	std::string key;
	std::string value;
	bool isDefault = false;
};

inline bool IsAlnum(char c)
{
	return (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
}

inline bool AlnumSpan(std::string_view text, std::size_t limit)
{
	if (text.empty() || text.size() > limit) return false;
	for (const char c : text)
		if (!IsAlnum(c)) return false;
	return true;
}

// "0.85" or "1" as hundredths. At most two places; no sign.
inline bool ParseHundredths(std::string_view text, int& out)
{
	out = 0;
	if (text.empty() || text.size() > 6) return false;
	int whole = 0;
	int frac = 0;
	int places = 0;
	bool dot = false;
	bool digit = false;
	for (const char c : text) {
		if (c == '.') {
			if (dot) return false;
			dot = true;
			continue;
		}
		if (c < '0' || c > '9') return false;
		digit = true;
		if (!dot) whole = whole * 10 + (c - '0');
		else if (places < 2) {
			frac = frac * 10 + (c - '0');
			++places;
		} else return false;
	}
	if (!digit) return false;
	if (places == 1) frac *= 10;
	out = whole * 100 + frac;
	return true;
}

inline std::string HundredthsText(int value)
{
	const int whole = value / 100;
	const int frac = value % 100;
	return std::to_string(whole) + "." + (frac < 10 ? "0" : "") + std::to_string(frac);
}

inline bool ParseFlag(std::string_view text, std::string& out)
{
	if (text == "0" || text == "1") {
		out = std::string(text);
		return true;
	}
	return false;
}

inline bool CanonPanelId(std::string_view key, std::string& out)
{
	static constexpr std::string_view kPanels[] = {"Power", "Module", "Credits", "Browser", "Stats", "Hints", "Cluster"};
	for (const auto name : kPanels) {
		if (EqualsFold(key, name)) {
			out = std::string(name);
			return true;
		}
	}
	return false;
}

// The names AS3's Object defines. The movie keeps column sets in a plain Object, where these
// cannot be keys; HsbJson.RESERVED is the same list.
inline bool ObjectMemberName(std::string_view key)
{
	for (const char* name : { "constructor", "hasOwnProperty", "isPrototypeOf", "propertyIsEnumerable", "setPropertyIsEnumerable", "toLocaleString",
			 "toString", "valueOf" }) {
		if (key == name) return true;
	}
	return false;
}

// A column list is up to kMaxColumns ids joined by commas. A sort is one id with an
// optional trailing - for descending.
inline bool ValidColumnValue(bool sort, std::string_view value)
{
	if (sort) {
		std::string_view id = value;
		if (!id.empty() && id.back() == '-') id.remove_suffix(1);
		return AlnumSpan(id, kMaxColumnId);
	}
	std::size_t count = 0;
	std::size_t at = 0;
	while (at <= value.size()) {
		const auto comma = value.find(',', at);
		const std::string_view id = value.substr(at, comma == std::string_view::npos ? std::string_view::npos : comma - at);
		if (!AlnumSpan(id, kMaxColumnId)) return false;
		if (++count > kMaxColumns) return false;
		if (comma == std::string_view::npos) break;
		at = comma + 1;
	}
	return count > 0;
}

// Checks one setting against the whitelist and fills out with the canonical section, key
// and value. Returns false for anything the movie does not write; the caller drops it.
inline bool CheckSetting(std::string_view sectionIn, std::string_view keyIn, std::string_view valueIn, Setting& out)
{
	const std::string section = Trim(sectionIn);
	const std::string key = Trim(keyIn);
	const std::string value = Trim(valueIn);
	out = {};
	int n = 0;
	bool ok = false;
	if (EqualsFold(section, "Style")) {
		out.section = "Style";
		if (EqualsFold(key, "AccentColor")) {
			n = ParseInt(value, ok);
			if (!ok || n < -1 || n > 13) return false;
			out.key = "AccentColor";
			out.value = std::to_string(n);
			out.isDefault = n == kAccentDefault;
			return true;
		}
		if (EqualsFold(key, "AccentHex")) {
			out.key = "AccentHex";
			if (value.empty()) {
				out.isDefault = true;
				return true;
			}
			if (!ValidHex(value)) return false;
			out.value = CanonHex(value);
			return true;
		}
		if (EqualsFold(key, "CardOpacity")) {
			if (!ParseHundredths(value, n) || n < kOpacityMinHundredths || n > 100) return false;
			out.key = "CardOpacity";
			out.value = HundredthsText(n);
			out.isDefault = n == 100;
			return true;
		}
		return false;
	}
	if (EqualsFold(section, "Layout")) {
		out.section = "Layout";
		if (EqualsFold(key, "ScreenMargin")) {
			n = ParseInt(value, ok);
			if (!ok || n < 0 || n > kMarginMax) return false;
			out.key = "ScreenMargin";
			out.value = std::to_string(n);
			out.isDefault = n == kMarginDefault;
			return true;
		}
		if (EqualsFold(key, "UiScale")) {
			if (!ParseHundredths(value, n) || n < kScaleMinHundredths || n > kScaleMaxHundredths) return false;
			out.key = "UiScale";
			out.value = HundredthsText(n);
			out.isDefault = n == 100;
			return true;
		}
		if (EqualsFold(key, "Density")) {
			if (!EqualsFold(value, "compact") && !EqualsFold(value, "detailed")) return false;
			out.key = "Density";
			out.value = EqualsFold(value, "compact") ? "compact" : "detailed";
			out.isDefault = out.value == "compact";
			return true;
		}
		if (EqualsFold(key, "GroupByMaker") || EqualsFold(key, "RememberLayout")) {
			if (!ParseFlag(value, out.value)) return false;
			out.key = EqualsFold(key, "GroupByMaker") ? "GroupByMaker" : "RememberLayout";
			out.isDefault = out.value == (out.key == "GroupByMaker" ? "0" : "1");
			return true;
		}
		return false;
	}
	if (EqualsFold(section, "Panels")) {
		out.section = "Panels";
		if (!CanonPanelId(key, out.key) || !ParseFlag(value, out.value)) return false;
		out.isDefault = out.value == "1";
		return true;
	}
	if (EqualsFold(section, "Notices")) {
		out.section = "Notices";
		if (!EqualsFold(key, "ShowConflictNotice") || !ParseFlag(value, out.value)) return false;
		out.key = "ShowConflictNotice";
		out.isDefault = out.value == "1";
		return true;
	}
	if (EqualsFold(section, "Keys")) {
		out.section = "Keys";
		std::string v = value;
		if (v.size() == 1 && v[0] >= 'a' && v[0] <= 'z') v[0] = static_cast<char>(v[0] - 'a' + 'A');
		if (EqualsFold(key, "Arrange")) {
			if (v != "L" && v != "0") return false;
			out.key = "Arrange";
			out.value = v;
			out.isDefault = v == "L";
			return true;
		}
		if (EqualsFold(key, "HideAll") || EqualsFold(key, "Find")) {
			if (v.size() != 1 || (v != "0" && kBindableKeys.find(v[0]) == std::string_view::npos)) return false;
			out.key = EqualsFold(key, "HideAll") ? "HideAll" : "Find";
			out.value = v;
			out.isDefault = v == (out.key == "HideAll" ? "H" : "/");
			return true;
		}
		return false;
	}
	if (EqualsFold(section, "Columns")) {
		out.section = "Columns";
		if (!AlnumSpan(key, kMaxColumnKey) || ObjectMemberName(key)) return false;
		out.key = key;
		if (value.empty()) {
			out.isDefault = true;
			return true;
		}
		const bool sort = key.size() > 4 && key.compare(key.size() - 4, 4, "Sort") == 0;
		if (!ValidColumnValue(sort, value)) return false;
		out.value = value;
		return true;
	}
	if (EqualsFold(section, "Debug")) {
		out.section = "Debug";
		if (!EqualsFold(key, "Probe") && !EqualsFold(key, "FontStrip")) return false;
		if (!ParseFlag(value, out.value)) return false;
		out.key = EqualsFold(key, "Probe") ? "Probe" : "FontStrip";
		out.isDefault = out.value == "0";
		return true;
	}
	if (EqualsFold(section, "Arrange")) {
		out.section = "Arrange";
		if (!ValidArrangeValue(key, value)) return false;
		const std::string line = CanonArrange(key, value);
		const auto eq = line.find('=');
		out.key = line.substr(0, eq);
		out.value = line.substr(eq + 1);
		out.isDefault = IsDefaultArrange(out.key, out.value);
		return true;
	}
	return false;
}

// "Section.Key=value" from a SET line. The value may be empty.
inline bool ParseSetBody(std::string_view body, Setting& out)
{
	const auto dot = body.find('.');
	const auto eq = body.find('=');
	if (dot == std::string_view::npos || eq == std::string_view::npos || dot == 0 || eq < dot + 2) return false;
	return CheckSetting(body.substr(0, dot), body.substr(dot + 1, eq - dot - 1), body.substr(eq + 1), out);
}

// "Key=value" from an ARRANGE line.
inline bool ParseArrangeBody(std::string_view body, Setting& out)
{
	const auto eq = body.find('=');
	if (eq == std::string_view::npos || eq == 0) return false;
	return CheckSetting("Arrange", body.substr(0, eq), body.substr(eq + 1), out);
}

inline std::vector<std::string> SplitLines(std::string_view text)
{
	std::vector<std::string> lines;
	std::size_t at = 0;
	while (at < text.size()) {
		const auto next = text.find('\n', at);
		std::string line(text.substr(at, next == std::string_view::npos ? std::string_view::npos : next - at));
		if (!line.empty() && line.back() == '\r') line.pop_back();
		lines.push_back(std::move(line));
		if (next == std::string_view::npos) break;
		at = next + 1;
	}
	return lines;
}

// Applies the updates in order, so a later value for the same key wins. Each key is edited
// in place inside its section; a missing key is added after the section's last entry; a
// missing section is added at the end. A default value removes the key.
inline std::string MergeSettings(std::string_view existing, const std::vector<Setting>& updates)
{
	std::vector<std::string> lines = SplitLines(existing);
	for (const Setting& u : updates) {
		std::size_t sectionAt = lines.size();
		std::size_t sectionEnd = lines.size();
		std::vector<std::size_t> keyAt;
		std::string current;
		for (std::size_t i = 0; i < lines.size(); ++i) {
			const std::string name = SectionName(lines[i]);
			if (!name.empty()) {
				current = name;
				if (sectionAt == lines.size() && EqualsFold(name, u.section)) sectionAt = i;
				continue;
			}
			std::string k, v;
			if (EqualsFold(current, u.section) && SplitKey(lines[i], k, v) && EqualsFold(k, u.key)) keyAt.push_back(i);
		}
		if (sectionAt < lines.size()) {
			for (std::size_t i = sectionAt + 1; i < lines.size(); ++i) {
				if (!SectionName(lines[i]).empty()) {
					sectionEnd = i;
					break;
				}
			}
		}
		const std::string line = u.key + "=" + u.value;
		if (!keyAt.empty()) {
			// A key listed twice (or in a repeated section) is kept once, at its first spot.
			for (std::size_t j = keyAt.size(); j-- > 1;) lines.erase(lines.begin() + static_cast<std::ptrdiff_t>(keyAt[j]));
			if (u.isDefault) lines.erase(lines.begin() + static_cast<std::ptrdiff_t>(keyAt[0]));
			else lines[keyAt[0]] = line;
			continue;
		}
		if (u.isDefault) continue;
		if (sectionAt < lines.size()) {
			std::size_t insertAt = sectionAt + 1;
			for (std::size_t i = sectionAt + 1; i < sectionEnd; ++i)
				if (!Trim(lines[i]).empty()) insertAt = i + 1;
			lines.insert(lines.begin() + static_cast<std::ptrdiff_t>(insertAt), line);
			continue;
		}
		while (!lines.empty() && Trim(lines.back()).empty()) lines.pop_back();
		if (!lines.empty()) lines.emplace_back();
		lines.push_back("[" + u.section + "]");
		lines.push_back(line);
	}
	while (!lines.empty() && Trim(lines.back()).empty()) lines.pop_back();
	std::string out;
	for (const auto& l : lines) {
		out += l;
		out += "\n";
	}
	return out;
}

// The value of Section.Key in the file, or found=false. The first match wins.
inline std::string IniValue(std::string_view ini, std::string_view section, std::string_view key, bool& found)
{
	found = false;
	std::string current;
	for (const auto& line : SplitLines(ini)) {
		const std::string name = SectionName(line);
		if (!name.empty()) {
			current = name;
			continue;
		}
		std::string k, v;
		if (EqualsFold(current, section) && SplitKey(line, k, v) && EqualsFold(k, key)) {
			found = true;
			return v;
		}
	}
	return {};
}

// Every whitelisted key in one section, canonical, in file order. Used for [Panels] and
// [Columns], whose keys are not a fixed list.
inline std::vector<Setting> SectionSettings(std::string_view ini, std::string_view section)
{
	std::vector<Setting> rows;
	std::string current;
	for (const auto& line : SplitLines(ini)) {
		const std::string name = SectionName(line);
		if (!name.empty()) {
			current = name;
			continue;
		}
		std::string k, v;
		Setting s;
		if (EqualsFold(current, section) && SplitKey(line, k, v) && CheckSetting(section, k, v, s) && !s.isDefault)
			rows.push_back(s);
		if (rows.size() >= kMaxSettingUpdates) break;
	}
	return rows;
}

// A whitelisted value from the file, or the fallback when the key is missing or invalid.
inline std::string SettingOr(std::string_view ini, std::string_view section, std::string_view key, std::string_view fallback)
{
	bool found = false;
	const std::string raw = IniValue(ini, section, key, found);
	Setting s;
	if (!found || !CheckSetting(section, key, raw, s)) return std::string(fallback);
	return s.isDefault && s.value.empty() ? std::string(fallback) : s.value;
}

// Purpose: decide whether a settings save may write the user ini. Inputs: whether the file
//    exists, and whether it was read in full. Outputs: true when a merge cannot lose lines.
// Rule (the HUD's, commit 7850269): an existing file that could not be read, or was too large
//    to read, is never treated as empty; merging into "" would drop every other line in it.
inline bool UserReadAllowsWrite(bool exists, bool readOk)
{
	return !exists || readOk;
}

// Purpose: put settings that could not be written back in front of the queue, so the next
//    SET END tries again. Inputs: the live queue and the failed batch. Outputs: the queue,
//    in the failed batch's order first. A value queued since the failure is newer and wins
//    over the failed one for the same key. The queue stays within kMaxSettingUpdates.
inline void RequeueSettings(std::vector<Setting>& queue, const std::vector<Setting>& failed)
{
	std::vector<Setting> out;
	out.reserve(failed.size() + queue.size());
	for (const auto& s : failed) {
		bool newer = false;
		for (const auto& q : queue) newer = newer || (EqualsFold(q.section, s.section) && EqualsFold(q.key, s.key));
		if (!newer && out.size() < kMaxSettingUpdates) out.push_back(s);
	}
	for (const auto& q : queue) {
		if (out.size() < kMaxSettingUpdates) out.push_back(q);
	}
	queue.swap(out);
}

// The HUD's own AccentColor default (HorizonUI.default.ini: 0, cyan).
inline constexpr int kHudAccentDefault = 0;

struct HudAccent {
	int color = kHudAccentDefault;
	std::string hex;
};

// Purpose: the HUD's accent as the HUD resolves it. Inputs: the text of HorizonUI.user.ini and
//    HorizonUI.default.ini (either may be empty). Outputs: AccentColor and a valid AccentHex.
// Rule: [Style] only; the user file holds only what differs from the defaults, so it wins key
//    by key over the default file, and with neither key the HUD's own default applies.
inline HudAccent LayerHudAccent(std::string_view user, std::string_view def)
{
	HudAccent out;
	bool found = false;
	std::string color = IniValue(user, "Style", "AccentColor", found);
	if (!found) color = IniValue(def, "Style", "AccentColor", found);
	if (found) {
		bool ok = false;
		const int n = ParseInt(color, ok);
		if (ok) out.color = n;
	}
	std::string hex = IniValue(user, "Style", "AccentHex", found);
	if (!found) hex = IniValue(def, "Style", "AccentHex", found);
	if (found && ValidHex(hex)) out.hex = CanonHex(hex);
	return out;
}

// Purpose: the only files outside shipbuilder\ the plugin opens are the HUD's two ini files,
//    read-only, at the exact folder the HUD itself uses (<game>\Data\Interface\HorizonUI\).
// Inputs: the full path and that folder (with its trailing separator).
inline bool HudIniMayRead(std::string_view path, std::string_view hudDir)
{
	if (path.empty() || hudDir.empty() || HasDotDot(path) || HasDotDot(hudDir)) return false;
	if (!EndsWithFold(hudDir, "\\Data\\Interface\\HorizonUI\\")) return false;
	if (path.size() <= hudDir.size() || !EqualsFold(path.substr(0, hudDir.size()), hudDir)) return false;
	const std::string_view name = path.substr(hudDir.size());
	return EqualsFold(name, "HorizonUI.user.ini") || EqualsFold(name, "HorizonUI.default.ini");
}

}  // namespace hsb
