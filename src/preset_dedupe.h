#pragma once

// Preset list dedupe and the shared preset-name character set.
// The HUD movie (actionscript/horizon_block.as, hz42NmOk) drops the same characters.
// Last modified: 2026-10-20.

#include <cctype>
#include <cstddef>
#include <cstdint>
#include <cstring>
#include <string>
#include <vector>

namespace hzpreset {

// ASCII characters removed from a saved preset name, in addition to control
// characters (code points below 32) and DEL (127). '|' is included so a name
// cannot break the F11 state line. The movie uses this same set.
inline constexpr char kPresetNameDrop[] = "=+[];#\"\\|";

inline bool IsWs(unsigned char c) { return c == ' ' || c == '\t' || c == '\r' || c == '\n'; }

inline std::string Trim(const std::string& a_s)
{
	std::size_t b = 0, e = a_s.size();
	while (b < e && IsWs(static_cast<unsigned char>(a_s[b]))) ++b;
	while (e > b && IsWs(static_cast<unsigned char>(a_s[e - 1]))) --e;
	return a_s.substr(b, e - b);
}

inline std::string Lower(std::string a_s)
{
	for (char& c : a_s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
	return a_s;
}

// Purpose: true when a_s[a_i] is the UTF-8 non-breaking space (C2 A0).
// Outputs: byte length 2 through a_step. A lone A0 is not a space: it is the
// second byte of characters such as 'à' (C3 A0).
inline bool IsNbsp(const std::string& a_s, std::size_t a_i, std::size_t& a_step)
{
	const auto c = static_cast<unsigned char>(a_s[a_i]);
	if (c == 0xC2 && a_i + 1 < a_s.size() && static_cast<unsigned char>(a_s[a_i + 1]) == 0xA0) {
		a_step = 2;
		return true;
	}
	return false;
}

// Purpose: turn a preset display name into the dedupe key.
// Inputs: the name already stored on the preset. Outputs: trimmed, ASCII
// case-folded, with runs of whitespace collapsed to one space. A non-breaking
// space counts as a space, so it does not make a second name.
// Dependencies: IsNbsp.
// Last modified: 2026-10-20.
inline std::string NormalizePresetName(const std::string& a_name)
{
	const std::string t = Trim(a_name);
	std::string o;
	bool sp = false;
	for (std::size_t i = 0; i < t.size();) {
		std::size_t step = 0;
		const auto c = static_cast<unsigned char>(t[i]);
		if (IsNbsp(t, i, step) || IsWs(c)) {
			if (!o.empty()) sp = true;
			i += step ? step : 1;
			continue;
		}
		if (sp) { o += ' '; sp = false; }
		o += static_cast<char>(std::tolower(c));
		++i;
	}
	return o;
}

// Purpose: a prefix of at most a_max bytes that does not end inside a UTF-8 character.
// Inputs: text and a byte budget. Outputs: the text when it already fits, otherwise
// bytes [0, a_max) with a split character removed. A continuation byte (10xxxxxx)
// at the cut means the character started earlier; that lead byte is dropped too.
// Dependencies: none.
// Last modified: 2026-10-20.
inline std::string Utf8Prefix(const std::string& a_s, std::size_t a_max)
{
	if (a_s.size() <= a_max) return a_s;
	std::size_t n = a_max;
	if ((static_cast<unsigned char>(a_s[n]) & 0xC0) == 0x80) {
		while (n > 0 && (static_cast<unsigned char>(a_s[n]) & 0xC0) == 0x80) --n;
	}
	return a_s.substr(0, n);
}

// Purpose: copy a HUD string into a fixed buffer without splitting a UTF-8 character.
// Inputs: destination, its size in bytes (including the NUL), and the source. Outputs: at most
// a_cap - 1 bytes, ending on a character boundary. A character that would cross that limit is left out.
// Controls and DEL become spaces. Dependencies: none.
// Last modified: 2026-10-22.
inline void CopyHudText(char* a_dst, std::size_t a_cap, const char* a_src)
{
	if (!a_dst || a_cap == 0) return;
	a_dst[0] = '\0';
	if (!a_src) return;
	const std::size_t max = a_cap - 1;
	std::size_t o = 0;
	for (std::size_t i = 0; a_src[i] != '\0' && o < max;) {
		const auto lead = static_cast<unsigned char>(a_src[i]);
		int need = 1;
		if ((lead & 0x80) == 0x00) need = 1;
		else if ((lead & 0xE0) == 0xC0) need = 2;
		else if ((lead & 0xF0) == 0xE0) need = 3;
		else if ((lead & 0xF8) == 0xF0) need = 4;
		int got = 1;
		while (got < need) {
			const auto cc = static_cast<unsigned char>(a_src[i + static_cast<std::size_t>(got)]);
			if (cc == 0 || (cc & 0xC0) != 0x80) break;
			++got;
		}
		if (got != need || o + static_cast<std::size_t>(need) > max) break;
		for (int k = 0; k < need; ++k) {
			const auto b = static_cast<unsigned char>(a_src[i + static_cast<std::size_t>(k)]);
			a_dst[o++] = (k == 0 && (b < 32 || b == 127)) ? ' ' : static_cast<char>(b);
		}
		i += static_cast<std::size_t>(need);
	}
	a_dst[o] = '\0';
}

// Purpose: drop the characters a preset name must not contain, matching the HUD.
// Inputs: the raw name from F11. Outputs: the name with those characters and
// control characters removed, trimmed, and cut at 48 bytes on a UTF-8 boundary.
// Dependencies: kPresetNameDrop, Utf8Prefix. The movie's typing box still stops at 32.
// Last modified: 2026-10-20.
inline std::string CleanPresetName(const std::string& a_name)
{
	std::string s;
	for (unsigned char c : a_name) {
		if (c < 0x20 || c == 0x7f) continue;
		if (std::strchr(kPresetNameDrop, static_cast<char>(c)) != nullptr) continue;
		s += static_cast<char>(c);
	}
	s = Trim(s);
	if (s.size() > 48) s = Trim(Utf8Prefix(s, 48));
	return s;
}

// Purpose: fingerprint the settings in a preset so two installs of the same look match.
// Inputs: the preset file text. Outputs: key=value lines outside [Preset], with
// line endings and surrounding space normalized. The [Preset] header (name, author,
// version, description) is not part of the fingerprint.
// Dependencies: none.
// Last modified: 2026-10-20.
inline std::string PresetContentKey(const std::string& a_text)
{
	std::string out;
	bool skip = false;
	std::size_t i = 0;
	if (a_text.size() >= 3 && static_cast<unsigned char>(a_text[0]) == 0xEF &&
	    static_cast<unsigned char>(a_text[1]) == 0xBB && static_cast<unsigned char>(a_text[2]) == 0xBF)
		i = 3;
	while (i < a_text.size()) {
		std::size_t j = i;
		while (j < a_text.size() && a_text[j] != '\n' && a_text[j] != '\r') ++j;
		std::string line = a_text.substr(i, j - i);
		if (j < a_text.size() && a_text[j] == '\r') ++j;
		if (j < a_text.size() && a_text[j] == '\n') ++j;
		i = j;
		line = Trim(line);
		if (!line.empty() && static_cast<unsigned char>(line[0]) == 0xEF) {
			if (line.size() >= 3 && static_cast<unsigned char>(line[0]) == 0xEF &&
			    static_cast<unsigned char>(line[1]) == 0xBB && static_cast<unsigned char>(line[2]) == 0xBF)
				line = Trim(line.substr(3));
		}
		if (line.empty() || line[0] == ';' || line[0] == '#') continue;
		if (line[0] == '[') {
			const auto e = line.find(']');
			std::string sec = e == std::string::npos ? line.substr(1) : line.substr(1, e - 1);
			sec = Lower(Trim(sec));
			skip = sec == "preset";
			if (!skip && !sec.empty()) out += "[" + sec + "]\n";
			continue;
		}
		if (skip) continue;
		const auto eq = line.find('=');
		if (eq == std::string::npos || eq == 0) continue;
		std::string key;
		for (unsigned char c : line.substr(0, eq))
			if (!IsWs(c)) key += static_cast<char>(std::tolower(c));
		if (key.empty()) continue;
		std::string val = line.substr(eq + 1);
		if (const auto sc = val.find(';'); sc != std::string::npos) val.erase(sc);
		out += key + "=" + Trim(val) + "\n";
	}
	return out;
}

// Purpose: tell the FOMOD / installer copy from the loose standalone package file.
// Inputs: user flag (true for presets\user) and the file name only.
// Outputs: true for a shipped file whose name does not start with "HorizonUI.".
// The installer copy is moragars_choice.ini. The loose file is
// HorizonUI.moragars-choice-0.42.0.ini.
// Dependencies: none.
// Last modified: 2026-10-20.
inline bool IsInstallerPresetFile(bool a_user, const std::string& a_fileName)
{
	if (a_user) return false;
	const std::string f = Lower(a_fileName);
	// "HorizonUI." is the loose package name (HorizonUI.moragars-choice-0.42.0.ini), not the installer file.
	return !f.starts_with("horizonui.");
}

struct Candidate
{
	std::string id;
	bool user = false;
	std::string name;
	std::string fileName;
	std::string contentKey;
	std::int64_t mtime = 0;
};

struct Drop
{
	std::string line;
};

// Purpose: choose which of two same-name presets stays in the F11 list.
// Inputs: a is the challenger, b is the one currently kept, a_same is true when
// every copy in the group has the same settings fingerprint.
// Outputs: true when a replaces b.
// Rule: same settings keep the installer copy (then the newer file, then the
// smaller id). Different settings keep the newer file (then the installer copy,
// then the smaller id).
// Dependencies: IsInstallerPresetFile.
// Last modified: 2026-10-20.
inline bool PreferPreset(const Candidate& a, const Candidate& b, bool a_same)
{
	const bool ai = IsInstallerPresetFile(a.user, a.fileName);
	const bool bi = IsInstallerPresetFile(b.user, b.fileName);
	if (a_same) {
		if (ai != bi) return ai;
		if (a.mtime != b.mtime) return a.mtime > b.mtime;
		return a.id < b.id;
	}
	if (a.mtime != b.mtime) return a.mtime > b.mtime;
	if (ai != bi) return ai;
	return a.id < b.id;
}

inline std::string DropReason(const Candidate& a_dropped, const Candidate& a_kept, bool a_same)
{
	const bool ki = IsInstallerPresetFile(a_kept.user, a_kept.fileName);
	const bool di = IsInstallerPresetFile(a_dropped.user, a_dropped.fileName);
	if (a_same) {
		if (ki && !di) return "same settings, kept the installer copy";
		if (a_kept.mtime != a_dropped.mtime) return "same settings, kept the newer file";
		return "same settings, kept the stable id";
	}
	if (a_kept.mtime != a_dropped.mtime) return "settings differ, kept the newer file";
	if (ki && !di) return "settings differ, same time, kept the installer copy";
	return "settings differ, same time, kept the stable id";
}

// Purpose: hide duplicate shipped preset names in the F11 list.
// Inputs: presets in the order ScanPresets already shows (shipped, then saved).
// Outputs: indexes to keep, in that same order, and one log line per hidden file.
// Only shipped files (user == false) are compared with each other. A saved preset
// is always kept, even when its name matches a shipped preset and that file is newer.
// The hidden file stays on disk. Dependencies: NormalizePresetName, PreferPreset.
// Last modified: 2026-10-20.
inline std::vector<std::size_t> DedupePresetIndices(const std::vector<Candidate>& a_items, std::vector<Drop>& a_drops)
{
	a_drops.clear();
	struct Group
	{
		std::string key;
		std::vector<std::size_t> idx;
	};
	std::vector<Group> groups;
	for (std::size_t i = 0; i < a_items.size(); ++i) {
		if (a_items[i].user) continue;
		const std::string key = NormalizePresetName(a_items[i].name);
		std::size_t g = 0;
		for (; g < groups.size(); ++g)
			if (groups[g].key == key) break;
		if (g == groups.size()) groups.push_back(Group{ key, {} });
		groups[g].idx.push_back(i);
	}
	std::vector<bool> drop(a_items.size(), false);
	for (const auto& g : groups) {
		if (g.idx.size() < 2) continue;
		bool same = true;
		for (std::size_t k = 1; k < g.idx.size(); ++k)
			if (a_items[g.idx[k]].contentKey != a_items[g.idx[0]].contentKey) same = false;
		std::size_t win = g.idx[0];
		for (std::size_t k = 1; k < g.idx.size(); ++k)
			if (PreferPreset(a_items[g.idx[k]], a_items[win], same)) win = g.idx[k];
		for (std::size_t ix : g.idx) {
			if (ix == win) continue;
			drop[ix] = true;
			const auto& d = a_items[ix];
			const auto& w = a_items[win];
			Drop row;
			row.line = "preset duplicate: hid " + d.id + " ('" + d.name + "'); kept " + w.id + " (" + DropReason(d, w, same) + ")";
			a_drops.push_back(row);
		}
	}
	std::vector<std::size_t> keep;
	for (std::size_t i = 0; i < a_items.size(); ++i)
		if (!drop[i]) keep.push_back(i);
	return keep;
}

} // namespace hzpreset
