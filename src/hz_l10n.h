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

// Official Steam interface languages (Starfield app 1716740). File stems
// match Localization/<stem>.json. Korean and Greek are not Steam UI languages
// for Starfield and are not listed here.
inline constexpr const char* kSteamLangs[] = {
	"en", "de", "fr", "it", "es", "es-mx", "ja", "pl", "pt-br", "zh-cn"
};

// Map a game or INI language token to a Localization file stem.
// Steam / sLanguage (PCGamingWiki, LOOT libloadorder, Starfield_<lang>.ini):
//   en, de, fr, it, es, jp, pl, ptbr, zhhans
// LocalEnvironmentData also uses ja for Japanese.
// Steam "latam" (Spanish - Latin America) is mapped to sLanguage=es by the
// game / LOOT. Horizon still accepts esmx / latam / es-mx as stem es-mx so a
// translator can ship es-mx.json; Auto+es uses es.json (Spain).
// Unknown codes stay as lowercased tokens so a community file can still match.
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
	if (s == "en" || s == "english" || s == "en-us" || s == "en_us" || s == "enus") return "en";
	if (s == "de" || s == "german" || s == "de-de" || s == "de_de") return "de";
	if (s == "fr" || s == "french" || s == "fr-fr" || s == "fr_fr") return "fr";
	if (s == "it" || s == "italian" || s == "it-it" || s == "it_it") return "it";
	if (s == "esmx" || s == "es-mx" || s == "es_mx" || s == "esla" || s == "es-419"
			|| s == "latam" || s == "es-latam" || s == "es_latam")
		return "es-mx";
	if (s == "es" || s == "spanish" || s == "es-es" || s == "es_es" || s == "eses") return "es";
	if (s == "jp" || s == "ja" || s == "japanese") return "ja";
	if (s == "pl" || s == "polish" || s == "pl-pl" || s == "pl_pl") return "pl";
	if (s == "ptbr" || s == "pt-br" || s == "pt_br" || s == "brazilian" || s == "pt-brz")
		return "pt-br";
	if (s == "zhhans" || s == "zh-cn" || s == "zhcn" || s == "zh_cn" || s == "zh"
			|| s == "zh-hans" || s == "schinese")
		return "zh-cn";
	return s;
}

// Exo 2 (Settings Language dropdown): Latin, Latin Extended, Vietnamese,
// combining marks, general punctuation, currency. CJK / Hangul / Arabic /
// Thai / Cyrillic / non-BMP are not in the HUD Exo 2 face, so those names
// must never be drawn there (tofu). Translated HUD text still uses
// $MAIN_Font via hzHasCjk per string when that string has CJK. The
// Language dropdown never uses that path (Final rule).
inline bool Exo2CanCp(std::uint32_t a_cp)
{
	if (a_cp <= 0x024F) return true;
	if (a_cp >= 0x0300 && a_cp <= 0x036F) return true;
	if (a_cp >= 0x1E00 && a_cp <= 0x1EFF) return true;
	if (a_cp >= 0x2000 && a_cp <= 0x206F) return true;
	if (a_cp >= 0x20A0 && a_cp <= 0x20CF) return true;
	return false;
}

inline bool Exo2Can(std::string_view a_s)
{
	for (std::size_t i = 0; i < a_s.size();) {
		const auto b = static_cast<unsigned char>(a_s[i]);
		std::uint32_t cp = 0;
		int n = 1;
		if (b < 0x80) {
			cp = b;
		} else if ((b & 0xE0) == 0xC0 && i + 1 < a_s.size()) {
			cp = (static_cast<std::uint32_t>(b & 0x1F) << 6)
				| (static_cast<unsigned char>(a_s[i + 1]) & 0x3F);
			n = 2;
		} else if ((b & 0xF0) == 0xE0 && i + 2 < a_s.size()) {
			cp = (static_cast<std::uint32_t>(b & 0x0F) << 12)
				| ((static_cast<unsigned char>(a_s[i + 1]) & 0x3F) << 6)
				| (static_cast<unsigned char>(a_s[i + 2]) & 0x3F);
			n = 3;
		} else {
			return false;
		}
		if (!Exo2CanCp(cp)) return false;
		i += static_cast<std::size_t>(n);
	}
	return true;
}

// If Exo 2 cannot draw a_s, use the last parenthetical (the English name) or a_fb.
inline std::string Exo2Text(std::string_view a_s, std::string_view a_fb)
{
	if (a_s.empty()) return std::string(a_fb);
	if (Exo2Can(a_s)) return std::string(a_s);
	const auto a = a_s.rfind('(');
	const auto b = a_s.rfind(')');
	if (a != std::string_view::npos && b != std::string_view::npos && b > a + 1) {
		auto inner = Trim(a_s.substr(a + 1, b - a - 1));
		if (!inner.empty() && Exo2Can(inner)) return inner;
	}
	if (!a_fb.empty() && Exo2Can(a_fb)) return std::string(a_fb);
	std::string o;
	for (std::size_t i = 0; i < a_s.size();) {
		const auto b0 = static_cast<unsigned char>(a_s[i]);
		std::uint32_t cp = 0;
		int n = 1;
		if (b0 < 0x80) {
			cp = b0;
		} else if ((b0 & 0xE0) == 0xC0 && i + 1 < a_s.size()) {
			cp = (static_cast<std::uint32_t>(b0 & 0x1F) << 6)
				| (static_cast<unsigned char>(a_s[i + 1]) & 0x3F);
			n = 2;
		} else if ((b0 & 0xF0) == 0xE0 && i + 2 < a_s.size()) {
			cp = (static_cast<std::uint32_t>(b0 & 0x0F) << 12)
				| ((static_cast<unsigned char>(a_s[i + 1]) & 0x3F) << 6)
				| (static_cast<unsigned char>(a_s[i + 2]) & 0x3F);
			n = 3;
		} else {
			break;
		}
		if (Exo2CanCp(cp)) o.append(a_s.substr(i, static_cast<std::size_t>(n)));
		i += static_cast<std::size_t>(n);
	}
	o = Trim(o);
	if (!o.empty()) return o;
	return std::string(a_fb);
}

// Native name with English in parentheses (Settings 2.0 dropdown). Scripts
// Exo 2 cannot draw use the English name only so the list never tofu.
inline const char* DisplayName(std::string_view a_code)
{
	const auto c = MapCode(a_code);
	if (c == "auto") return "Auto (game)";
	if (c == "en") return "English";
	if (c == "de") return "Deutsch (German)";
	if (c == "fr") return "Fran\xC3\xA7" "ais (French)";
	if (c == "es") return "Espa\xC3\xB1" "ol (Spanish)";
	if (c == "es-mx") return "Espa\xC3\xB1" "ol (Latinoam\xC3\xA9" "rica)";
	if (c == "it") return "Italiano (Italian)";
	if (c == "ja") return "Japanese";
	if (c == "pl") return "Polski (Polish)";
	if (c == "pt-br") return "Portugu\xC3\xAA" "s (Brasil)";
	if (c == "zh-cn") return "Simplified Chinese";
	return "Unknown";
}

inline std::string MenuName(std::string_view a_code)
{
	return DisplayName(a_code);
}

// es-mx overlays es.json then es-mx.json, then English. Other stems overlay
// only themselves on English. Missing files are skipped (English remains).
inline const char* FallbackStem(std::string_view a_code)
{
	if (a_code == "es-mx") return "es";
	return nullptr;
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

// Steam appmanifest UserConfig.language (last quoted value). Empty if none.
// Starfield stores the Steam UI language here; it is not written to Prefs.ini.
inline std::string ParseSteamAcfLanguage(std::string_view a_text)
{
	std::string_view span = a_text;
	const auto key = std::string_view("\"UserConfig\"");
	const auto u = a_text.find(key);
	if (u != std::string_view::npos) {
		const auto brace = a_text.find('{', u + key.size());
		if (brace != std::string_view::npos) {
			int depth = 1;
			std::size_t i = brace + 1;
			while (i < a_text.size() && depth > 0) {
				if (a_text[i] == '{') ++depth;
				else if (a_text[i] == '}') --depth;
				++i;
			}
			span = a_text.substr(brace, i - brace);
		}
	}
	std::string last;
	std::size_t p = 0;
	while (p < span.size()) {
		const auto k = span.find("\"language\"", p);
		if (k == std::string_view::npos) break;
		const auto q1 = span.find('"', k + 10);
		if (q1 == std::string_view::npos) break;
		const auto q2 = span.find('"', q1 + 1);
		if (q2 == std::string_view::npos) break;
		last.assign(span.substr(q1 + 1, q2 - q1 - 1));
		p = q2 + 1;
	}
	return last;
}

// Game-directory language INI the engine loads after Starfield.ini
// (Starfield_de.ini, Starfield_zhhans.ini, Starfield_ja.ini, ...).
inline std::string LanguageIniName(std::string_view a_code)
{
	const auto c = MapCode(a_code);
	if (c.empty() || c == "auto") return {};
	if (c == "zh-cn") return "Starfield_zhhans.ini";
	if (c == "pt-br") return "Starfield_ptbr.ini";
	if (c == "es-mx") return "Starfield_es.ini";
	return std::string("Starfield_") + c + ".ini";
}

// Merge order matches the game: Starfield.ini, then Starfield_<lang>.ini
// (lang from Steam ACF), then Prefs, then Custom. Last sLanguage wins.
// If no INI sets sLanguage, Steam ACF is the language (that is how a German
// Steam install loads Starfield_de.ini while Prefs/Custom stay English-empty).
inline std::string DetectGameLanguage(
	std::string_view a_acf,
	std::string_view a_gameIni,
	const std::unordered_map<std::string, std::string>& a_langIni,
	std::string_view a_prefs,
	std::string_view a_custom)
{
	std::string last;
	auto apply = [&](std::string_view body) {
		auto s = ParseSLanguage(body);
		if (!s.empty()) last = std::move(s);
	};
	apply(a_gameIni);
	const auto steam = MapCode(ParseSteamAcfLanguage(a_acf));
	if (!steam.empty() && steam != "auto") {
		const auto fn = LanguageIniName(steam);
		const auto it = a_langIni.find(fn);
		if (it != a_langIni.end()) apply(it->second);
	}
	apply(a_prefs);
	apply(a_custom);
	if (last.empty() && !steam.empty() && steam != "auto") last = steam;
	if (last.empty()) return "en";
	auto mapped = MapCode(last);
	if (mapped.empty() || mapped == "auto") return "en";
	return mapped;
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
		const bool skipKey = key == "_meta" || key == "_comment";
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
	// English first so extra community files stay after the official list.
	std::stable_partition(out.begin(), out.end(), [](const std::string& c) { return c == "en"; });
	return out;
}

// Auto is prepended in ActionScript. Official Steam stems always appear so a
// missing fr.json still shows Français (French) and falls back to English.
inline std::vector<std::string> DropdownCodes(const std::filesystem::path& a_dir)
{
	std::vector<std::string> out;
	out.reserve(16);
	for (const char* s : kSteamLangs) out.emplace_back(s);
	for (const auto& f : ListLangFiles(a_dir)) {
		auto c = MapCode(f);
		if (c.empty() || c == "auto") continue;
		if (std::find(out.begin(), out.end(), c) == out.end()) out.push_back(c);
	}
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
	t.filesCsv = JoinCsv(DropdownCodes(a_dir));

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
		std::vector<std::string> chain;
		if (const char* fb = FallbackStem(want)) chain.emplace_back(fb);
		chain.push_back(want);
		std::string loaded;
		bool wantHit = false;
		for (const auto& code : chain) {
			if (code == "en") continue;
			std::unordered_map<std::string, std::string> over;
			std::string ob;
			const auto langPath = a_dir / (code + ".json");
			if (ReadUtf8File(langPath, ob) && ParseFlat(ob, over) && !over.empty()) {
				for (auto& kv : over) {
					if (!kv.second.empty()) t.keys[kv.first] = std::move(kv.second);
				}
				if (!loaded.empty()) loaded += '+';
				loaded += code;
				t.usedCode = code;
				if (code == want) wantHit = true;
			}
		}
		if (!loaded.empty()) {
			t.notice = std::string("en+") + loaded;
			if (!wantHit) t.notice += std::string(" (") + want + " missing)";
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
