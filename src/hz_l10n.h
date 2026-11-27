#pragma once

// Purpose: Horizon UI localization table. Load UTF-8 JSON from
// Data/SFSE/Plugins/HorizonUI/Localization once (init or a Language
// reload), flatten nested objects to dotted keys, overlay the chosen
// language on English, and cache. No polling, no per-frame work, no
// UI-thread I/O. Tests: tests/l10n_test.cpp. Author: Moragar.
// Last modified: 2026-11-27.
//
// Inputs: Localization folder, Horizon Language= override (auto or a
// file code), game sLanguage as detected at init.
// Outputs: flattened key map, a one-shot Scaleform payload, available
// file codes for the Settings 2.0 dropdown.
// Dependencies: std only (no CommonLibSF). JSON files are 512 KiB max.

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>
#include <string_view>
#include <unordered_map>
#include <utility>
#include <vector>

namespace hzl10n {

inline constexpr std::size_t kMaxFileBytes = 512 * 1024;
inline constexpr int kMaxDepth = 16;

inline std::string Lower(std::string_view a_s)
{
	std::string o(a_s);
	for (char& c : o)
		if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
	return o;
}

inline std::string Trim(std::string_view a_s)
{
	std::size_t b = 0, e = a_s.size();
	while (b < e && (a_s[b] == ' ' || a_s[b] == '\t' || a_s[b] == '\r' || a_s[b] == '\n')) ++b;
	while (e > b && (a_s[e - 1] == ' ' || a_s[e - 1] == '\t' || a_s[e - 1] == '\r' || a_s[e - 1] == '\n')) --e;
	return std::string(a_s.substr(b, e - b));
}

// Map a game or INI language token to a Localization file stem.
// jp/ja -> ja, zhhans/zh-cn -> zh-cn. Unknown codes stay as lowercased
// tokens so a community file can still match. auto and empty stay auto.
// Path separators, drive letters, and '..' are rejected (become auto)
// so Language= cannot walk out of the Localization folder.
inline std::string MapCode(std::string_view a_raw)
{
	auto s = Lower(Trim(a_raw));
	if (s.size() >= 2 && s.front() == '"' && s.back() == '"')
		s = s.substr(1, s.size() - 2);
	s = Trim(s);
	if (s.find_first_of("/\\:") != std::string::npos || s.find("..") != std::string::npos)
		return "auto";
	if (s.empty() || s == "auto") return "auto";
	if (s == "jp" || s == "ja") return "ja";
	if (s == "zhhans" || s == "zh-cn" || s == "zhcn" || s == "zh_cn" || s == "zh") return "zh-cn";
	if (s == "ptbr" || s == "pt-br" || s == "pt_br") return "ptbr";
	return s;
}

inline const char* DisplayName(std::string_view a_code)
{
	const auto c = MapCode(a_code);
	if (c == "auto") return "Auto (game)";
	if (c == "en") return "English";
	if (c == "de") return "German";
	if (c == "fr") return "French";
	if (c == "es") return "Spanish";
	if (c == "it") return "Italian";
	if (c == "ja") return "Japanese";
	if (c == "ko") return "Korean";
	if (c == "pl") return "Polish";
	if (c == "zh-cn") return "Chinese (Simplified)";
	if (c == "ptbr") return "Portuguese (Brazil)";
	return "Unknown";
}

// Uppercase Settings 2.0 label for a file code (ENGLISH, GERMAN, ...).
inline std::string MenuName(std::string_view a_code)
{
	const auto c = MapCode(a_code);
	if (c == "auto") return "AUTO (GAME)";
	if (c == "en") return "ENGLISH";
	if (c == "de") return "GERMAN";
	if (c == "fr") return "FRENCH";
	if (c == "es") return "SPANISH";
	if (c == "it") return "ITALIAN";
	if (c == "ja") return "JAPANESE";
	if (c == "ko") return "KOREAN";
	if (c == "pl") return "POLISH";
	if (c == "zh-cn") return "CHINESE (SIMPLIFIED)";
	if (c == "ptbr") return "PORTUGUESE (BRAZIL)";
	std::string o = Lower(c);
	for (char& ch : o)
		if (ch >= 'a' && ch <= 'z') ch = static_cast<char>(ch - 'a' + 'A');
	return o;
}

// Last sLanguage under [General] in a Starfield INI body. Empty if none.
inline std::string ParseSLanguage(std::string_view a_text)
{
	std::string last;
	std::string sec;
	std::size_t i = 0;
	while (i < a_text.size()) {
		std::size_t n = a_text.find('\n', i);
		if (n == std::string_view::npos) n = a_text.size();
		auto line = Trim(a_text.substr(i, n - i));
		i = n < a_text.size() ? n + 1 : a_text.size();
		if (line.empty() || line[0] == ';' || line[0] == '#') continue;
		if (line.front() == '[' && line.back() == ']') {
			sec = Lower(line.substr(1, line.size() - 2));
			continue;
		}
		const auto eq = line.find('=');
		if (eq == std::string::npos) continue;
		if (sec != "general") continue;
		if (Lower(Trim(line.substr(0, eq))) != "slanguage") continue;
		last = Trim(line.substr(eq + 1));
	}
	return last;
}

inline void Utf8Push(std::string& a_o, std::uint32_t a_cp)
{
	if (a_cp <= 0x7F) {
		a_o += static_cast<char>(a_cp);
	} else if (a_cp <= 0x7FF) {
		a_o += static_cast<char>(0xC0 | (a_cp >> 6));
		a_o += static_cast<char>(0x80 | (a_cp & 0x3F));
	} else if (a_cp <= 0xFFFF) {
		a_o += static_cast<char>(0xE0 | (a_cp >> 12));
		a_o += static_cast<char>(0x80 | ((a_cp >> 6) & 0x3F));
		a_o += static_cast<char>(0x80 | (a_cp & 0x3F));
	} else if (a_cp <= 0x10FFFF) {
		a_o += static_cast<char>(0xF0 | (a_cp >> 18));
		a_o += static_cast<char>(0x80 | ((a_cp >> 12) & 0x3F));
		a_o += static_cast<char>(0x80 | ((a_cp >> 6) & 0x3F));
		a_o += static_cast<char>(0x80 | (a_cp & 0x3F));
	}
}

struct Tok {
	const char* p{nullptr};
	const char* e{nullptr};
	void Skip()
	{
		while (p < e && std::isspace(static_cast<unsigned char>(*p))) ++p;
	}
	bool Eat(char c)
	{
		Skip();
		if (p < e && *p == c) {
			++p;
			return true;
		}
		return false;
	}
};

inline int HexNibble(char c)
{
	if (c >= '0' && c <= '9') return c - '0';
	if (c >= 'a' && c <= 'f') return c - 'a' + 10;
	if (c >= 'A' && c <= 'F') return c - 'A' + 10;
	return -1;
}

inline bool ParseString(Tok& a_t, std::string& a_o)
{
	a_t.Skip();
	if (a_t.p >= a_t.e || *a_t.p != '"') return false;
	++a_t.p;
	a_o.clear();
	while (a_t.p < a_t.e) {
		char c = *a_t.p++;
		if (c == '"') return true;
		if (c == '\\' && a_t.p < a_t.e) {
			c = *a_t.p++;
			if (c == 'n') a_o += '\n';
			else if (c == 'r') a_o += '\r';
			else if (c == 't') a_o += '\t';
			else if (c == 'u' && a_t.p + 4 <= a_t.e) {
				int n[4];
				bool ok = true;
				for (int i = 0; i < 4; ++i) {
					n[i] = HexNibble(a_t.p[i]);
					if (n[i] < 0) ok = false;
				}
				a_t.p += 4;
				if (ok) {
					const auto cp = static_cast<std::uint32_t>((n[0] << 12) | (n[1] << 8) | (n[2] << 4) | n[3]);
					Utf8Push(a_o, cp);
				} else {
					a_o += '?';
				}
			} else {
				a_o += c;
			}
		} else {
			a_o += c;
		}
	}
	return false;
}

inline bool SkipValue(Tok& a_t, int a_depth);

inline bool SkipObject(Tok& a_t, int a_depth)
{
	if (a_depth > kMaxDepth) return false;
	if (!a_t.Eat('{')) return false;
	if (a_t.Eat('}')) return true;
	for (;;) {
		std::string k;
		if (!ParseString(a_t, k) || !a_t.Eat(':') || !SkipValue(a_t, a_depth + 1)) return false;
		if (a_t.Eat('}')) return true;
		if (!a_t.Eat(',')) return false;
	}
}

inline bool SkipArray(Tok& a_t, int a_depth)
{
	if (a_depth > kMaxDepth) return false;
	if (!a_t.Eat('[')) return false;
	if (a_t.Eat(']')) return true;
	for (;;) {
		if (!SkipValue(a_t, a_depth + 1)) return false;
		if (a_t.Eat(']')) return true;
		if (!a_t.Eat(',')) return false;
	}
}

inline bool SkipValue(Tok& a_t, int a_depth)
{
	if (a_depth > kMaxDepth) return false;
	a_t.Skip();
	if (a_t.p >= a_t.e) return false;
	if (*a_t.p == '"') {
		std::string s;
		return ParseString(a_t, s);
	}
	if (*a_t.p == '{') return SkipObject(a_t, a_depth);
	if (*a_t.p == '[') return SkipArray(a_t, a_depth);
	if (a_t.p + 4 <= a_t.e && std::strncmp(a_t.p, "true", 4) == 0) {
		a_t.p += 4;
		return true;
	}
	if (a_t.p + 5 <= a_t.e && std::strncmp(a_t.p, "false", 5) == 0) {
		a_t.p += 5;
		return true;
	}
	if (a_t.p + 4 <= a_t.e && std::strncmp(a_t.p, "null", 4) == 0) {
		a_t.p += 4;
		return true;
	}
	char* end = nullptr;
	std::strtod(a_t.p, &end);
	if (!end || end == a_t.p) return false;
	a_t.p = end;
	return true;
}

inline bool ParseObject(Tok& a_t, const std::string& a_prefix,
	std::unordered_map<std::string, std::string>& a_out, int a_depth)
{
	if (a_depth > kMaxDepth) return false;
	if (!a_t.Eat('{')) return false;
	if (a_t.Eat('}')) return true;
	for (;;) {
		std::string key;
		if (!ParseString(a_t, key) || !a_t.Eat(':')) return false;
		a_t.Skip();
		if (a_t.p >= a_t.e) return false;
		const bool skipKey = !key.empty() && key.front() == '_';
		const std::string dotted = a_prefix.empty() ? key : (a_prefix + "." + key);
		if (*a_t.p == '{') {
			if (skipKey) {
				if (!SkipObject(a_t, a_depth + 1)) return false;
			} else if (!ParseObject(a_t, dotted, a_out, a_depth + 1)) {
				return false;
			}
		} else if (*a_t.p == '"') {
			std::string val;
			if (!ParseString(a_t, val)) return false;
			if (!skipKey) a_out[dotted] = std::move(val);
		} else {
			if (!SkipValue(a_t, a_depth + 1)) return false;
		}
		if (a_t.Eat('}')) return true;
		if (!a_t.Eat(',')) return false;
	}
}

inline bool ParseFlat(std::string_view a_json, std::unordered_map<std::string, std::string>& a_out)
{
	if (a_json.size() >= 3 &&
		static_cast<unsigned char>(a_json[0]) == 0xEF &&
		static_cast<unsigned char>(a_json[1]) == 0xBB &&
		static_cast<unsigned char>(a_json[2]) == 0xBF) {
		a_json.remove_prefix(3);
	}
	Tok t;
	t.p = a_json.data();
	t.e = a_json.data() + a_json.size();
	if (!ParseObject(t, "", a_out, 0)) return false;
	t.Skip();
	return t.p == t.e;
}

inline bool ReadUtf8File(const std::filesystem::path& a_path, std::string& a_out)
{
	std::error_code ec;
	if (!std::filesystem::is_regular_file(a_path, ec)) return false;
	const auto sz = std::filesystem::file_size(a_path, ec);
	if (ec || sz == 0 || sz > kMaxFileBytes) return false;
	std::ifstream in(a_path, std::ios::binary);
	if (!in) return false;
	a_out.assign(static_cast<std::size_t>(sz), '\0');
	in.read(a_out.data(), static_cast<std::streamsize>(sz));
	return static_cast<bool>(in);
}

inline std::vector<std::string> ListLangFiles(const std::filesystem::path& a_dir)
{
	std::vector<std::string> out;
	std::error_code ec;
	if (!std::filesystem::is_directory(a_dir, ec)) return out;
	for (std::filesystem::directory_iterator it(a_dir, ec), end; it != end && !ec; it.increment(ec)) {
		if (!it->is_regular_file(ec)) continue;
		if (Lower(it->path().extension().string()) != ".json") continue;
		auto stem = Lower(it->path().stem().string());
		if (stem.empty() || stem.front() == '_') continue;
		if (stem.find_first_of("/\\:") != std::string::npos || stem.find("..") != std::string::npos) continue;
		out.push_back(std::move(stem));
	}
	std::sort(out.begin(), out.end());
	out.erase(std::unique(out.begin(), out.end()), out.end());
	// English first so the Settings dropdown is Auto, English, then the rest.
	std::stable_partition(out.begin(), out.end(), [](const std::string& c) { return c == "en"; });
	return out;
}

inline std::string JoinCsv(const std::vector<std::string>& a_v)
{
	std::string o;
	for (const auto& s : a_v) {
		if (!o.empty()) o += ',';
		o += s;
	}
	return o;
}

inline std::string EscField(std::string_view a_s)
{
	std::string o;
	o.reserve(a_s.size());
	for (char c : a_s) {
		if (c == '\\') o += "\\\\";
		else if (c == '\n') o += "\\n";
		else if (c == '\r') o += "\\r";
		else if (c == '\t') o += "\\t";
		else o += c;
	}
	return o;
}

struct Table {
	std::unordered_map<std::string, std::string> keys;
	std::string gameCode;      // detected game language, file code
	std::string gameName;      // English display name for F11
	std::string overrideCode;  // auto or a file code as requested
	std::string usedCode;      // overlay that actually loaded
	std::string filesCsv;
	std::string payload;
	std::string notice;        // one log token, no paths
	int count{0};
	bool ok{false};
};

inline std::string Get(const Table& a_t, std::string_view a_key, std::string_view a_fb)
{
	auto it = a_t.keys.find(std::string(a_key));
	if (it != a_t.keys.end() && !it->second.empty()) return it->second;
	return std::string(a_fb);
}

inline void BuildPayload(Table& a_t)
{
	std::ostringstream os;
	os << "#l10n1\n";
	os << "g\t" << EscField(a_t.gameCode) << "\n";
	os << "gn\t" << EscField(a_t.gameName) << "\n";
	os << "o\t" << EscField(a_t.overrideCode) << "\n";
	os << "used\t" << EscField(a_t.usedCode) << "\n";
	os << "files\t" << EscField(a_t.filesCsv) << "\n";
	std::vector<std::string> ks;
	ks.reserve(a_t.keys.size());
	for (const auto& kv : a_t.keys) ks.push_back(kv.first);
	std::sort(ks.begin(), ks.end());
	for (const auto& k : ks)
		os << k << '\t' << EscField(a_t.keys[k]) << '\n';
	a_t.payload = os.str();
}

// Load English, then overlay the resolved language file if it exists.
// Missing overlay = English. Missing English = empty table (HUD keeps its literals).
inline Table Load(const std::filesystem::path& a_dir, std::string_view a_override, std::string_view a_game)
{
	Table t;
	t.overrideCode = MapCode(a_override);
	if (t.overrideCode.empty()) t.overrideCode = "auto";
	t.gameCode = MapCode(a_game);
	if (t.gameCode == "auto" || t.gameCode.empty()) t.gameCode = "en";
	t.gameName = DisplayName(t.gameCode);
	const auto files = ListLangFiles(a_dir);
	t.filesCsv = JoinCsv(files);

	std::string want = t.overrideCode == "auto" ? t.gameCode : t.overrideCode;
	if (want == "auto" || want.empty()) want = "en";

	std::string body;
	const auto enPath = a_dir / "en.json";
	if (ReadUtf8File(enPath, body)) {
		if (!ParseFlat(body, t.keys)) t.keys.clear();
	}

	t.usedCode = "en";
	t.notice = "en";
	if (want != "en") {
		std::unordered_map<std::string, std::string> over;
		std::string ob;
		const auto langPath = a_dir / (want + ".json");
		if (ReadUtf8File(langPath, ob) && ParseFlat(ob, over) && !over.empty()) {
			for (auto& kv : over) {
				if (!kv.second.empty()) t.keys[kv.first] = std::move(kv.second);
			}
			t.usedCode = want;
			t.notice = std::string("en+") + want;
		} else {
			t.notice = std::string("en (") + want + " missing)";
		}
	}

	t.count = static_cast<int>(t.keys.size());
	t.ok = t.count > 0;
	BuildPayload(t);
	return t;
}

} // namespace hzl10n
