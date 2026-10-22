// HorizonUI SFSE plugin v0.42.0 - drop-in src\main.cpp (CommonLibSF libxse 9d090c4)
// v0.42.0.4: F11 lists each shipped preset name once. Saved presets are never hidden.
// Same settings keep the installer copy; different settings keep the newer shipped file.
// The F11 header, the load line, and the "movie builds" line use the DLL file version (src/hz_version.h, also the version resource).
// v0.42.0.6: ShowHUDMessageEvent (address id 86800) logs HUD text that contains " that", and the Comms
// message queue is written as "comms msg:" lines. Both are compiled only when HZ_COMMS_MSG_LOG is 1
// (src/hz_version.h). The release checklist in README.md turns that log off. The settings schema stays 0.42.0.
// Saved preset names drop the same characters as the HUD: '=' '+' '[' ']' ';' '#' '"' '\' '|' and control characters.
// v0.42.0 r3 (file version 0.42.0.3): a scope (ScopeMenu) still blocks F11 but no longer restarts the 3 s "HUD ready" wait,
// so F11 works right after leaving the scope. The 0.42.0.4 no-debug build compiled this log out. In 0.42.0.6 it is on
// when HZ_COMMS_MSG_LOG is 1 (Debug=0 in the ini still stops the movie queue): every 500 ms hzcTakeDbg goes to the log as
// "comms msg:" lines. "movie builds:" logs
// the loaded HUD / Comms builds (hzBuildId / hzcBuildId). Saved preset names drop '=' '+' '[' ']' ';' '#' '"' '\'.
// v0.42.0 r2: F11 is also ignored while a scope (ScopeMenu) or the item inspect view (InspectMenu) is open; the deny list
// uses the registered "MissionBoard" only (MissionBoardMenu / ShipDialogueMenu dropped). '+' / '=' reach the HUD as
// "ch:+" / "ch:=" (ARRANGE CARDS: scope chip size).
// v0.42.0: F11 opens only from the main HUD. The key is ignored while the hand scanner (MonocleMenu) is open, and a
// window left open when the scanner opens is closed once (close-only, like the full-screen menus). The full-screen
// deny list also covers pickpocket, mission board, sleep / sit wait, book, data slate, message box, video, credits,
// title sequence, weapon groups, takeoff, favorites, marketplace, almanac, dialogue and the workshop quick menus.
// v0.41.0: the hand scanner state is pushed to the HUD (hz41DllScan) and the Comms HUD messages movie (hzcDllScan) every
// 100 ms (ScanPush, from BannerPoll), so a tool switch inside the scanner no longer ends their scan state.
// v0.41.0 test r2: ScanPush only while the hand scanner is open (+ one closed push) and only with the Scanner module; the
// retired [Scanner] ScanShowVitals key is never written again (presets that still have it set the three vitals keys).
// v0.41.0 FINAL: F11 / settings ignored while a full-screen menu is open (ship builder, outpost, inventory, galaxy map,
// photo mode, Data Menu, ship crew, skills, missions, powers, status, research, crafting, container, barter, terminal,
// digipick, chargen, photo gallery, blueprint, ...), same as load / pause / console; ResetSettingsState fully closes
// ARRANGE then the F11 window (toggle at most twice while open).
// v0.40.3: without the Comms module, the game's planet location banner (HUD messages movie) is set to alpha 0 while the
// Horizon scanner is open (BannerPoll; GFx::Value GetMember / SetMember on the menu's document object), and restored after.
// v0.39: the hovered-person data feature (v0.35 - 0.38) is deleted: the DLL reads nothing about the person under
// the crosshair, writes no extra files and has no settings section of its own. It only runs the F11 settings window
// and the settings files. The v0.38 check that the loaded HUDMenu is Horizon's now asks hzSettingsOpen.
// v0.37: settings files (HorizonUI.default.ini + HorizonUI.user.ini, update backup, migration, presets) - plain
// std / Win32 file code in the HZF section, no new CommonLibSF calls. Everything from v0.36 is unchanged.
#include <Windows.h>
#include <winver.h>
#pragma comment(lib, "version.lib")
#undef GetObject
#undef ERROR
#undef PostMessage
#undef SendMessage
#include <cctype>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <atomic>
#include <mutex>
#include <deque>
#include <vector>
#include <string>
#include <cstdio>
#include <exception>
#include <algorithm>
#include <cmath>
#include <utility>
#include <map>
#include <iterator>
#include "hz_version.h"
#include "preset_dedupe.h"

// v0.37: the settings-file code (HZF) replaces files through this (temp file + MoveFileExW)
static bool HzfReplace(const std::filesystem::path& a_tmp, const std::filesystem::path& a_dst)
{
	if (::MoveFileExW(a_tmp.c_str(), a_dst.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)) return true;
	REX::WARN("file replace failed (error {})", ::GetLastError());
	return false;
}

namespace HZ
{
	using GValue = RE::Scaleform::GFx::Value;

	// DirectInput scan codes
	std::uint32_t KeyNameToScan(std::string n)
	{
		for (auto& c : n) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
		static const std::uint32_t fkeys[12] = { 0x3B, 0x3C, 0x3D, 0x3E, 0x3F, 0x40, 0x41, 0x42, 0x43, 0x44, 0x57, 0x58 };
		if (n.size() >= 2 && n[0] == 'F' && std::isdigit(static_cast<unsigned char>(n[1]))) {
			int i = std::atoi(n.c_str() + 1);
			if (i >= 1 && i <= 12) return fkeys[i - 1];
		}
		if (n.size() == 1) {
			static const char* rows[] = { "QWERTYUIOP", "ASDFGHJKL", "ZXCVBNM", "1234567890" };
			static const std::uint32_t base[] = { 0x10, 0x1E, 0x2C, 0x02 };
			for (int r = 0; r < 4; ++r)
				if (auto p = std::strchr(rows[r], n[0]); p && *p) return base[r] + static_cast<std::uint32_t>(p - rows[r]);
		}
		if (n == "INSERT") return 0xD2;
		if (n == "HOME") return 0xC7;
		if (n == "END") return 0xCF;
		if (n == "PAGEUP") return 0xC9;
		if (n == "PAGEDOWN") return 0xD1;
		return 0;
	}

	std::uint32_t g_scan = 0x57;  // F11
	int           g_vk = VK_F11;
	bool          g_wasDown = false;

	std::filesystem::path IniPath()
	{
		wchar_t exe[MAX_PATH]{};
		GetModuleFileNameW(nullptr, exe, MAX_PATH);
		return std::filesystem::path(exe).parent_path() / "Data" / "Interface" / "HorizonUI" / "HorizonUI.ini";
	}
	// v0.37: the folder (HorizonUI.ini above is the legacy file: read for migration only, never written)
	std::filesystem::path HzDir() { return IniPath().parent_path(); }

	// ==== HZF BEGIN: v0.37 settings files (plain std + one Win32 call through HzfReplace; unit-tested on the box) ====
	// Data\Interface\HorizonUI\:
	//   HorizonUI.default.ini   shipped, replaced by every update, never written here
	//   HorizonUI.user.ini      the player's settings: only what differs from the defaults (+ keys the file already had)
	//   HorizonUI.user.bak.ini  copy of user.ini made once per update (state.ini LastVersion != this DLL)
	//   HorizonUI.user.preapply.ini  user.ini as it was before the last preset was applied (one-step undo)
	//   HorizonUI.state.ini     [State] LastVersion / LegacyImported / PresetSeeded
	//   HorizonUI.ini           legacy (v0.36 and older): read for migration only, never written, never deleted
	//   presets\*.ini           shipped presets (moragars_choice.ini from the installer); presets\user\*.ini saved in game
	namespace HZF
	{
		inline const char* kVersion = "0.42.0";
		using LogFn = void (*)(int, const std::string&);   // 0 info, 1 warn
		inline LogFn g_log = nullptr;
		inline void Log(int a_lvl, const std::string& a_s) { if (g_log) g_log(a_lvl, a_s); }

		inline std::string Lower(std::string a_s)
		{
			for (auto& c : a_s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
			return a_s;
		}
		inline bool IsWs(char c) { return c == ' ' || c == '\t' || c == '\r' || c == '\n'; }
		inline std::string Trim(const std::string& a_s)
		{
			std::size_t b = 0, e = a_s.size();
			while (b < e && IsWs(a_s[b])) ++b;
			while (e > b && IsWs(a_s[e - 1])) --e;
			return a_s.substr(b, e - b);
		}
		// leading blanks and UTF-8 BOMs off (hz30Hdr / hz30Key do the same in the HUD)
		inline std::string LTrimBom(const std::string& a_s)
		{
			std::size_t b = 0;
			for (;;) {
				if (b < a_s.size() && IsWs(a_s[b])) { ++b; continue; }
				if (a_s.compare(b, 3, "\xEF\xBB\xBF") == 0) { b += 3; continue; }
				break;
			}
			return a_s.substr(b);
		}
		inline std::vector<std::string> SplitLines(const std::string& a_text)
		{
			std::vector<std::string> out;
			std::string t = a_text;
			if (t.compare(0, 3, "\xEF\xBB\xBF") == 0) t.erase(0, 3);
			std::size_t p = 0;
			while (p < t.size()) {
				auto q = t.find('\n', p);
				std::string ln = t.substr(p, q == std::string::npos ? std::string::npos : q - p);
				if (!ln.empty() && ln.back() == '\r') ln.pop_back();
				out.push_back(ln);
				if (q == std::string::npos) break;
				p = q + 1;
			}
			return out;
		}
		inline std::string Alias(const std::string& a_n)
		{
			if (a_n == "cards v0.26") return "cards extra";   // v0.31 renames (the HUD's hz31SecAlias)
			if (a_n == "effects v0.26") return "effects";
			return a_n;
		}
		inline bool IsOldName(const std::string& a_n) { return a_n == "cards v0.26" || a_n == "effects v0.26"; }
		// "[Name]" -> "name" (lower case, not aliased)
		inline bool HeaderOf(const std::string& a_ln, std::string& a_out)
		{
			std::string t = LTrimBom(a_ln);
			while (!t.empty() && IsWs(t.back())) t.pop_back();
			if (t.size() < 3 || t[0] != '[') return false;
			const auto e = t.find(']');
			if (e == std::string::npos || e < 2) return false;
			a_out = Lower(Trim(t.substr(1, e - 1)));
			return true;
		}
		// key=value line (comments / headers / malformed -> false). Value: up to ';', trimmed
		inline bool KeyOf(const std::string& a_ln, std::string& a_kl, std::string& a_ko, std::string& a_v)
		{
			std::string t = LTrimBom(a_ln);
			if (t.empty() || t[0] == ';' || t[0] == '#' || t[0] == '[') return false;
			const auto eq = t.find('=');
			if (eq == std::string::npos || eq == 0) return false;
			std::string k;
			for (char c : t.substr(0, eq))
				if (!IsWs(c)) k += c;
			if (k.empty()) return false;
			a_kl = Lower(k);
			a_ko = Trim(t.substr(0, eq));
			std::string v = t.substr(eq + 1);
			if (auto sc = v.find(';'); sc != std::string::npos) v.erase(sc);
			a_v = Trim(v);
			return true;
		}

		struct Sec
		{
			std::string name;     // canonical (lower case, aliased); "" = lines before the first header
			std::string header;   // header line as written (trimmed)
			std::vector<std::string> raw;     // every line (header first)
			std::vector<std::string> order;   // keys (lower) in first-seen order
			std::map<std::string, std::pair<std::string, std::string>> kv;   // key (lower) -> (key as written, value); last wins
		};
		struct Doc
		{
			std::vector<Sec> secs;
			Sec* Find(const std::string& a_n)
			{
				for (auto& s : secs)
					if (s.name == a_n) return &s;
				return nullptr;
			}
			bool Has(const std::string& a_n) { return Find(a_n) != nullptr; }
			std::string SectionOfKey(const std::string& a_kl)
			{
				for (auto& s : secs)
					if (!s.name.empty() && s.kv.count(a_kl)) return s.name;
				return {};
			}
		};
		// a second copy of a section (or its pre-v0.31 name) merges into the first one; old names first, so the new name wins
		inline Doc Parse(const std::string& a_text)
		{
			Doc d;
			d.secs.push_back(Sec{});
			const auto lines = SplitLines(a_text);
			for (int pass = 0; pass < 2; ++pass) {
				Sec* cur = &d.secs[0];
				bool old = false;
				for (const auto& ln : lines) {
					std::string h;
					if (HeaderOf(ln, h)) {
						old = IsOldName(h);
						const auto n = Alias(h);
						if ((pass == 0) != old) { cur = nullptr; continue; }
						cur = d.Find(n);
						if (!cur) {
							d.secs.push_back(Sec{});
							cur = &d.secs.back();
							cur->name = n;
							cur->header = Trim(LTrimBom(ln));
						}
						cur->raw.push_back(ln);
						continue;
					}
					if (!cur) continue;
					if (pass == 0 && cur->name.empty()) continue;   // pre-header lines: second pass only
					if (pass == 1 && old) continue;
					cur->raw.push_back(ln);
					std::string kl, ko, v;
					if (!KeyOf(ln, kl, ko, v)) continue;
					if (!cur->kv.count(kl)) cur->order.push_back(kl);
					cur->kv[kl] = { ko, v };
				}
			}
			return d;
		}
		inline bool IsNum(const std::string& a_s, double& a_out)
		{
			if (a_s.empty()) return false;
			char* end = nullptr;
			a_out = std::strtod(a_s.c_str(), &end);
			return end && *end == 0;
		}
		inline bool SameValue(const std::string& a, const std::string& b)
		{
			double x, y;
			if (IsNum(a, x) && IsNum(b, y)) return std::fabs(x - y) < 1e-9;
			return a == b;
		}
		inline std::string Join(const std::vector<std::string>& a_l)
		{
			std::string s;
			for (const auto& l : a_l) { s += l; s += "\r\n"; }
			return s;
		}
		inline bool Blank(const std::string& a_s) { return Trim(LTrimBom(a_s)).empty(); }

		// base with the player's values laid over it (identical to the HUD's hz37Overlay; tested for parity):
		// known keys replace the base value in place, unknown keys of a known section are appended to it, sections the
		// base lacks are appended verbatim. Keys before any header go to the base section that has them. Malformed lines
		// are skipped. CRLF out.
		inline std::string Overlay(const std::string& a_base, const std::string& a_over)
		{
			Doc B = Parse(a_base);
			Doc O = Parse(a_over);
			std::map<std::string, std::map<std::string, std::pair<std::string, std::string>>> U;
			std::map<std::string, std::vector<std::string>> ext;
			std::vector<const Sec*> unk;
			for (const auto& s : O.secs) {
				if (!s.name.empty() && !B.Has(s.name)) { unk.push_back(&s); continue; }
				for (const auto& kl : s.order) {
					std::string sec = s.name.empty() ? B.SectionOfKey(kl) : s.name;
					if (sec.empty()) continue;
					auto& m = U[sec];
					if (!m.count(kl) && !B.Find(sec)->kv.count(kl)) ext[sec].push_back(kl);
					m[kl] = s.kv.at(kl);
				}
			}
			std::vector<std::string> out;
			std::string cur;
			std::map<std::string, bool> flushed;
			auto flush = [&](const std::string& a_sec) {
				if (a_sec.empty() || flushed[a_sec]) return;
				flushed[a_sec] = true;
				auto it = ext.find(a_sec);
				if (it == ext.end() || it->second.empty()) return;
				int blanks = 0;
				while (!out.empty() && Blank(out.back())) { out.pop_back(); ++blanks; }
				for (const auto& kl : it->second) { const auto& p = U[a_sec][kl]; out.push_back(p.first + "=" + p.second); }
				for (int i = 0; i < blanks; ++i) out.emplace_back();
			};
			for (const auto& ln : SplitLines(a_base)) {
				std::string h;
				if (HeaderOf(ln, h)) { flush(cur); cur = Alias(h); out.push_back(ln); continue; }
				std::string kl, ko, v;
				if (!cur.empty() && KeyOf(ln, kl, ko, v)) {
					auto su = U.find(cur);
					if (su != U.end()) {
						auto ku = su->second.find(kl);
						if (ku != su->second.end()) { out.push_back(ko + "=" + ku->second.second); continue; }
					}
				}
				out.push_back(ln);
			}
			flush(cur);
			for (const auto* s : unk) {
				if (!out.empty() && !Blank(out.back())) out.emplace_back();
				auto r = s->raw;
				while (!r.empty() && Blank(r.back())) r.pop_back();
				for (const auto& l : r) out.push_back(l);
			}
			return Join(out);
		}

		inline std::string StripSection(const std::string& a_text, const std::string& a_sec)
		{
			std::vector<std::string> out;
			bool skip = false;
			for (const auto& ln : SplitLines(a_text)) {
				std::string h;
				if (HeaderOf(ln, h)) skip = Alias(h) == a_sec;
				if (!skip) out.push_back(ln);
			}
			return Join(out);
		}

		inline bool IsModuleSec(const std::string& a_n) { return a_n == "scanner" || a_n == "comms"; }
		// v0.41.0 r2: keys a newer version replaced. Never written again by Diff (F11 save, presets, migration), so an old
		// line cannot outlive the keys that replaced it. [Scanner] ScanShowVitals (0.40.3) = ScanShowVitalsHealth / O2 / Boost.
		inline bool RetiredKey(const std::string& a_sec, const std::string& a_kl) { return a_sec == "scanner" && a_kl == "scanshowvitals"; }

		struct DiffOpt
		{
			bool keepUnknownKeys = false;       // unknown keys of known sections (migration)
			bool keepUnknownSections = true;    // sections the defaults do not have (other modules / the player's own)
		};
		inline std::string UserHeader()
		{
			return std::string("; Horizon UI - your settings. Only what differs from HorizonUI.default.ini is kept here (plus keys this\r\n"
			                   "; file already had). Written by HorizonUI.dll ") + kVersion + " (F11). Delete it to go back to the defaults.\r\n";
		}
		// what goes into HorizonUI.user.ini: a_full = the complete settings text, a_defs = HorizonUI.default.ini,
		// a_user = the current user.ini (its known keys are always kept). [Preset] is never written.
		inline std::string Diff(const std::string& a_full, const std::string& a_defs, const std::string& a_user, DiffOpt a_opt)
		{
			Doc D = Parse(a_defs), F = Parse(a_full), U = Parse(a_user);
			std::vector<std::string> order;
			std::map<std::string, std::vector<std::pair<std::string, std::string>>> keep;
			std::map<std::string, std::map<std::string, std::size_t>> pos;
			std::map<std::string, std::vector<std::string>> rawUnk;
			auto put = [&](const std::string& a_sec, const std::string& a_k, const std::string& a_v, const std::string& a_kl) {
				if (!keep.count(a_sec) && !rawUnk.count(a_sec)) order.push_back(a_sec);
				auto& p = pos[a_sec];
				auto it = p.find(a_kl);
				if (it != p.end()) { keep[a_sec][it->second].second = a_v; return; }
				p[a_kl] = keep[a_sec].size();
				keep[a_sec].push_back({ a_k, a_v });
			};
			auto inUser = [&](const std::string& a_sec, const std::string& a_kl) {
				auto s = U.Find(a_sec);
				if (!s) return false;
				if (s->kv.count(a_kl)) return true;
				auto o = U.Find("");   // a key the player wrote above every header
				return o && o->kv.count(a_kl) && D.SectionOfKey(a_kl) == a_sec;
			};
			auto consider = [&](const std::string& a_sec, const std::string& a_kl, const std::pair<std::string, std::string>& a_p) {
				if (RetiredKey(a_sec, a_kl)) return;   // v0.41.0 r2
				auto ds = D.Find(a_sec);
				auto dk = ds->kv.find(a_kl);
				const bool inU = inUser(a_sec, a_kl);
				if (dk != ds->kv.end()) {
					if (!SameValue(a_p.second, dk->second.second) || inU) put(a_sec, dk->second.first, a_p.second, a_kl);
				} else if (a_opt.keepUnknownKeys || (IsModuleSec(a_sec) && inU)) {
					put(a_sec, a_p.first, a_p.second, a_kl);
				}
			};
			auto take = [&](Doc& a_doc, bool a_fromUser) {
				for (auto& s : a_doc.secs) {
					if (s.name == "preset") continue;
					if (s.name.empty()) {
						for (const auto& kl : s.order) {
							const auto sec = D.SectionOfKey(kl);
							if (!sec.empty() && !(a_fromUser && F.Has(sec) && F.Find(sec)->kv.count(kl))) consider(sec, kl, s.kv.at(kl));
						}
						continue;
					}
					if (!D.Has(s.name)) {
						if (!a_opt.keepUnknownSections || rawUnk.count(s.name)) continue;
						auto r = s.raw;
						while (!r.empty() && Blank(r.back())) r.pop_back();
						if (!keep.count(s.name)) order.push_back(s.name);
						rawUnk[s.name] = r;
						continue;
					}
					for (const auto& kl : s.order) {
						if (a_fromUser) {   // a key of user.ini that the full text lost: the player's value stays
							auto fs = F.Find(s.name);
							if (fs && fs->kv.count(kl)) continue;
							auto fo = F.Find("");
							if (fo && fo->kv.count(kl) && D.SectionOfKey(kl) == s.name) continue;
						}
						consider(s.name, kl, s.kv.at(kl));
					}
				}
			};
			take(F, false);
			take(U, true);
			std::string out = UserHeader();
			for (const auto& n : order) {
				if (rawUnk.count(n)) {
					out += "\r\n";
					out += Join(rawUnk[n]);
					continue;
				}
				const auto& kv = keep[n];
				if (kv.empty()) continue;
				out += "\r\n" + D.Find(n)->header + "\r\n";
				for (const auto& [k, v] : kv) out += k + "=" + v + "\r\n";
			}
			return out;
		}

		// ---------------- files ----------------
		struct Paths
		{
			std::filesystem::path dir, def, user, bak, preapply, state, legacy, presets, userPresets, seed;
		};
		inline Paths MakePaths(const std::filesystem::path& a_dir)
		{
			Paths p;
			p.dir = a_dir;
			p.def = a_dir / "HorizonUI.default.ini";
			p.user = a_dir / "HorizonUI.user.ini";
			p.bak = a_dir / "HorizonUI.user.bak.ini";
			p.preapply = a_dir / "HorizonUI.user.preapply.ini";
			p.state = a_dir / "HorizonUI.state.ini";
			p.legacy = a_dir / "HorizonUI.ini";
			p.presets = a_dir / "presets";
			p.userPresets = a_dir / "presets" / "user";
			p.seed = a_dir / "presets" / "moragars_choice.ini";
			return p;
		}
		inline std::string U8(const std::filesystem::path& a_p)
		{
			const auto s = a_p.u8string();
			return std::string(s.begin(), s.end());
		}
		inline bool Exists(const std::filesystem::path& a_p)
		{
			std::error_code ec;
			return std::filesystem::is_regular_file(a_p, ec);
		}
		inline bool ReadText(const std::filesystem::path& a_p, std::string& a_out, std::size_t a_max = 1024 * 1024)
		{
			a_out.clear();
			if (!Exists(a_p)) return false;
			std::ifstream f(a_p, std::ios::binary);
			if (!f) return false;
			std::string s((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
			if (s.size() > a_max) return false;
			a_out = std::move(s);
			return true;
		}
		inline std::string ReadOr(const std::filesystem::path& a_p)
		{
			std::string s;
			ReadText(a_p, s);
			return s;
		}
		// temp file next to the target, flushed, then HzfReplace (MoveFileExW REPLACE_EXISTING | WRITE_THROUGH in the DLL)
		inline bool WriteAtomic(const std::filesystem::path& a_p, const std::string& a_data)
		{
			std::error_code ec;
			std::filesystem::create_directories(a_p.parent_path(), ec);
			auto tmp = a_p;
			tmp += ".tmp";
			{
				std::ofstream o(tmp, std::ios::binary | std::ios::trunc);
				if (!o) return false;
				o.write(a_data.data(), static_cast<std::streamsize>(a_data.size()));
				o.flush();
				if (!o) { o.close(); std::filesystem::remove(tmp, ec); return false; }
			}
			if (!HzfReplace(tmp, a_p)) { std::filesystem::remove(tmp, ec); return false; }
			return true;
		}

		// the effective settings text (what the HUD composes too, see hz37Compose): defaults (else the legacy file),
		// with user.ini laid over. Without user.ini and without state.ini (no 0.37 DLL ran yet) the legacy file is the
		// overlay, so an older DLL that still saves HorizonUI.ini keeps working.
		inline bool Compose(const std::string* a_def, const std::string* a_user, bool a_state, const std::string* a_leg, std::string& a_out)
		{
			const bool hd = a_def && !a_def->empty(), hl = a_leg && !a_leg->empty();
			const std::string* base = hd ? a_def : (hl ? a_leg : nullptr);
			const std::string* over = a_user ? a_user : (!a_state && hd && hl ? a_leg : nullptr);
			if (!base) { if (!over) return false; a_out = Overlay(*over, ""); return true; }
			a_out = Overlay(*base, over ? *over : std::string());
			return true;
		}
		inline bool MergedText(const Paths& a_p, std::string& a_out)
		{
			std::string d, u, l;
			const bool hd = ReadText(a_p.def, d), hu = ReadText(a_p.user, u), hl = ReadText(a_p.legacy, l);
			return Compose(hd ? &d : nullptr, hu ? &u : nullptr, Exists(a_p.state), hl ? &l : nullptr, a_out);
		}
		inline std::string Defaults(const Paths& a_p)
		{
			std::string d;
			if (ReadText(a_p.def, d) && !d.empty()) return d;
			return {};
		}

		// v0.37 layering rule 2 (approved): preset -> user.ini = the defaults with ONLY the preset's keys laid over,
		// stored as the difference from the defaults. [Preset] is dropped; unknown / renamed / removed keys and
		// sections are ignored silently; keys the preset does not list go back to their defaults (nothing of the old
		// user.ini carries over - its copy is HorizonUI.user.preapply.ini). Module sections follow the same rule.
		// Decision (presets round-trip): [Debug] is saved in presets but Apply skips it - it holds diagnostics (log
		// switches), not the look - so the player's own [Debug] lines in user.ini stay.
		inline bool ApplySkips(const std::string& a_sec) { return a_sec == "debug"; }
		// v0.37 personal keys (approved): the settings hotkey(s) - every key in [Hotkeys] - and ScreenHeight (the
		// player's monitor). Apply keeps the player's own values (like [Debug]); saved presets never hold them.
		inline bool PersonalKey(const std::string& a_sec, const std::string& a_kl) { return a_sec == "hotkeys" || a_kl == "screenheight"; }
		inline std::string StripPersonal(const std::string& a_text)
		{
			std::vector<std::string> out;
			std::string sec;
			for (const auto& ln : SplitLines(a_text)) {
				std::string h, kl, ko, v;
				if (HeaderOf(ln, h)) sec = Alias(h);
				else if (KeyOf(ln, kl, ko, v) && PersonalKey(sec, kl)) continue;
				out.push_back(ln);
			}
			return Join(out);
		}
		// v0.41.0 r2: a preset (0.40.3) with [Scanner] ScanShowVitals=0 / 1 sets the three vitals keys it stood for (the ones
		// the preset does not set itself); any other value is ignored. The retired line itself is dropped by Diff.
		inline std::string ExpandRetired(const std::string& a_text)
		{
			Doc d = Parse(a_text);
			auto s = d.Find("scanner");
			if (!s) return a_text;
			auto it = s->kv.find("scanshowvitals");
			if (it == s->kv.end()) return a_text;
			double v = -1;
			if (!IsNum(it->second.second, v) || (v != 0.0 && v != 1.0)) return a_text;
			std::string add;
			for (auto k : { "ScanShowVitalsHealth", "ScanShowVitalsO2", "ScanShowVitalsBoost" })
				if (!s->kv.count(Lower(k))) add += std::string(k) + "=" + (v == 1.0 ? "1" : "0") + "\r\n";
			if (add.empty()) return a_text;
			return Overlay(a_text, "[Scanner]\r\n" + add);
		}
		inline std::string PresetToUser(const std::string& a_preset, const std::string& a_defs, const std::string& a_oldUser = std::string())
		{
			std::string p = ExpandRetired(StripSection(a_preset, "preset"));   // v0.41.0 r2
			p = StripPersonal(StripSection(p, "debug"));
			if (!a_oldUser.empty()) {
				Doc U = Parse(a_oldUser);
				for (auto& s : U.secs) {
					if (ApplySkips(s.name)) {
						p += "\r\n";
						p += Join(s.raw);
						continue;
					}
					std::string keep;   // the player's own personal keys (a second copy of a section merges into the first)
					for (const auto& kl : s.order)
						if (PersonalKey(s.name, kl)) keep += s.kv[kl].first + "=" + s.kv[kl].second + "\r\n";
					if (!keep.empty() && !s.name.empty()) p += "\r\n" + s.header + "\r\n" + keep;
				}
			}
			DiffOpt o;
			o.keepUnknownKeys = false;
			o.keepUnknownSections = false;
			return Diff(p, a_defs, "", o);
		}
		// what a saved preset holds: like PresetToUser but [Debug] is kept
		inline std::string PresetDiff(const std::string& a_full, const std::string& a_defs)
		{
			DiffOpt o;
			o.keepUnknownKeys = false;
			o.keepUnknownSections = false;
			return Diff(StripPersonal(StripSection(a_full, "preset")), a_defs, "", o);
		}
		// rule 3: the body of a saved preset = only the known keys whose value differs from the defaults (no header)
		inline std::string PresetBody(const std::string& a_full, const std::string& a_defs)
		{
			if (a_defs.empty()) return Overlay(StripPersonal(StripSection(a_full, "preset")), "");   // nothing to compare with: everything
			std::string d = PresetDiff(a_full, a_defs);
			const auto h = UserHeader();
			if (d.compare(0, h.size(), h) == 0) d.erase(0, h.size());
			while (!d.empty() && (d[0] == '\r' || d[0] == '\n')) d.erase(0, 1);
			return d;
		}
		// "0.36.2" < "0.37.0": numeric parts compared in order (missing parts = 0); false when either is not a version
		inline bool VersionOlder(const std::string& a_v, const std::string& a_cur)
		{
			auto parts = [](const std::string& a_s, std::vector<long>& a_out) {
				a_out.clear();
				std::string t = Trim(a_s);
				if (!t.empty() && (t[0] == 'v' || t[0] == 'V')) t.erase(0, 1);
				if (t.empty()) return false;
				long n = -1;
				for (char c : t) {
					if (c >= '0' && c <= '9') { n = (n < 0 ? 0 : n) * 10 + (c - '0'); if (n > 1000000) return false; }
					else if (c == '.') { if (n < 0) return false; a_out.push_back(n); n = -1; }
					else return false;
				}
				if (n < 0) return false;
				a_out.push_back(n);
				return true;
			};
			std::vector<long> x, y;
			if (!parts(a_v, x) || !parts(a_cur, y)) return false;
			for (std::size_t i = 0; i < (std::max)(x.size(), y.size()); ++i) {
				const long xa = i < x.size() ? x[i] : 0, ya = i < y.size() ? y[i] : 0;
				if (xa != ya) return xa < ya;
			}
			return false;
		}

		// ---------------- presets ----------------
		struct Preset
		{
			std::string id;     // "s:<file>" shipped, "u:<file>" saved in game
			bool        user = false;
			std::string name, author, version, desc;
			std::filesystem::path path;
		};
		inline std::string CleanField(const std::string& a_s, std::size_t a_max)
		{
			std::string s;
			for (char c : a_s) {
				if (c == '|' || c == '\r' || c == '\n' || c == '\t') c = ' ';
				if (static_cast<unsigned char>(c) < 0x20) continue;
				s += c;
			}
			s = Trim(s);
			if (s.size() > a_max) s = Trim(hzpreset::Utf8Prefix(s, a_max));
			return s;
		}
		inline const std::vector<std::string>& BuiltinSections()
		{
			static const std::vector<std::string> v = { "hotkeys", "cards", "compass", "style", "cards extra", "effects", "rules", "layout", "ui", "comms", "scanner", "debug" };
			return v;
		}
		// valid = a [Preset] section with a Name and at least one known settings section with a key
		inline bool ValidatePreset(const std::string& a_text, const std::string& a_defs, Preset& a_out, std::string& a_why)
		{
			if (a_text.size() > 256 * 1024) { a_why = "file too large"; return false; }
			if (a_text.find('\0') != std::string::npos) { a_why = "not a text file"; return false; }
			Doc d = Parse(a_text);
			Doc D = Parse(a_defs);
			auto p = d.Find("preset");
			if (!p) { a_why = "no [Preset] section"; return false; }
			auto get = [&](const char* a_k) { return p->kv.count(a_k) ? p->kv[a_k].second : std::string(); };
			a_out.name = CleanField(get("name"), 48);
			if (a_out.name.empty()) { a_why = "[Preset] has no Name"; return false; }
			a_out.author = CleanField(get("author"), 32);
			a_out.version = CleanField(get("version"), 16);
			a_out.desc = CleanField(get("description"), 300);
			bool known = false;
			for (auto& s : d.secs) {
				if (s.name.empty() || s.name == "preset" || s.order.empty()) continue;
				const bool k = D.secs.size() > 1 ? D.Has(s.name) : std::find(BuiltinSections().begin(), BuiltinSections().end(), s.name) != BuiltinSections().end();
				if (k) { known = true; break; }
			}
			if (!known) { a_why = "no known settings section"; return false; }
			return true;
		}
		inline std::string Slug(const std::string& a_name)
		{
			std::string s;
			bool us = false;
			for (char c : a_name) {
				const auto u = static_cast<unsigned char>(c);
				if ((u >= 'a' && u <= 'z') || (u >= '0' && u <= '9')) { s += c; us = false; }
				else if (u >= 'A' && u <= 'Z') { s += static_cast<char>(u + 32); us = false; }
				else if (!s.empty() && !us) { s += '_'; us = true; }
			}
			while (!s.empty() && s.back() == '_') s.pop_back();
			if (s.size() > 40) { s.resize(40); while (!s.empty() && s.back() == '_') s.pop_back(); }
			if (s.empty()) s = "preset";
			static const char* res[] = { "con", "prn", "aux", "nul", "com1", "com2", "com3", "com4", "com5", "com6", "com7", "com8", "com9",
				"lpt1", "lpt2", "lpt3", "lpt4", "lpt5", "lpt6", "lpt7", "lpt8", "lpt9" };
			for (auto r : res)
				if (s == r) { s += "_1"; break; }
			return s;
		}
		struct Scan
		{
			std::vector<Preset>      list;
			std::vector<std::string> skipped;   // "<id>: <reason>"
			std::vector<std::string> deduped;   // duplicate names hidden from the list; the file stays on disk
		};
		inline std::int64_t WriteTicks(const std::filesystem::path& a_p)
		{
			std::error_code ec;
			const auto t = std::filesystem::last_write_time(a_p, ec);
			if (ec) return 0;
			return static_cast<std::int64_t>(t.time_since_epoch().count());
		}
		// Purpose: list presets for F11. Shipped files collapse to one row per name.
		// Inputs: preset folders and the defaults text used to validate files.
		// Outputs: the list the HUD shows, skip reasons, and duplicate-hide notes.
		// Saved presets (presets\user) are always listed, so a player look that reuses a
		// shipped name can still be applied and deleted after a mod update.
		// Same settings: keep the installer copy (shipped file not named HorizonUI.*.ini).
		// Different settings: keep the newer last-write time. Ties then prefer the installer copy, then the smaller id.
		// Dependencies: hzpreset::DedupePresetIndices. A duplicate is not a skip.
		// Last modified: 2026-10-20.
		inline Scan ScanPresets(const Paths& a_p, const std::string& a_defs)
		{
			Scan r;
			struct Row
			{
				Preset preset;
				hzpreset::Candidate cand;
			};
			std::vector<Row> rows;
			for (int u = 0; u < 2; ++u) {
				const auto& dir = u ? a_p.userPresets : a_p.presets;
				std::error_code ec;
				if (!std::filesystem::is_directory(dir, ec)) continue;
				std::vector<Row> part;
				int n = 0;
				for (std::filesystem::directory_iterator it(dir, ec), end; !ec && it != end; it.increment(ec)) {
					std::error_code ec2;
					if (!it->is_regular_file(ec2)) continue;
					const auto f = it->path();
					if (Lower(U8(f.extension())) != ".ini") continue;
					const std::string id = std::string(u ? "u:" : "s:") + U8(f.filename());
					if (++n > 64) { r.skipped.push_back(id + ": more than 64 presets in this folder"); continue; }
					std::string text, why;
					Preset p;
					if (!ReadText(f, text, 512 * 1024)) { r.skipped.push_back(id + ": unreadable or too large"); continue; }
					if (!ValidatePreset(text, a_defs, p, why)) { r.skipped.push_back(id + ": " + why); continue; }
					p.id = id;
					p.user = u == 1;
					p.path = f;
					Row row;
					row.preset = p;
					row.cand.id = id;
					row.cand.user = p.user;
					row.cand.name = p.name;
					row.cand.fileName = U8(f.filename());
					row.cand.contentKey = hzpreset::PresetContentKey(text);
					row.cand.mtime = WriteTicks(f);
					part.push_back(std::move(row));
				}
				std::sort(part.begin(), part.end(), [](const Row& a, const Row& b) {
					const auto x = Lower(a.preset.name), y = Lower(b.preset.name);
					return x != y ? x < y : a.preset.id < b.preset.id;
				});
				rows.insert(rows.end(), part.begin(), part.end());
			}
			std::vector<hzpreset::Candidate> cands;
			cands.reserve(rows.size());
			for (const auto& row : rows) cands.push_back(row.cand);
			std::vector<hzpreset::Drop> drops;
			const auto keep = hzpreset::DedupePresetIndices(cands, drops);
			for (std::size_t i : keep) r.list.push_back(rows[i].preset);
			for (const auto& d : drops) r.deduped.push_back(d.line);
			return r;
		}
		inline const Preset* FindPreset(const Scan& a_s, const std::string& a_id)
		{
			for (const auto& p : a_s.list)
				if (p.id == a_id) return &p;
			return nullptr;
		}

		// ---------------- state + startup ----------------
		struct State
		{
			std::string lastVersion;
			bool legacyImported = false, presetSeeded = false;
			std::string lastPreset;   // id of the last applied preset ("u:<file>" / "s:<file>"), for the SAVE name box
		};
		inline State ReadState(const Paths& a_p)
		{
			State s;
			Doc d = Parse(ReadOr(a_p.state));
			if (auto x = d.Find("state")) {
				auto get = [&](const char* a_k) { return x->kv.count(a_k) ? x->kv[a_k].second : std::string(); };
				s.lastVersion = get("lastversion");
				s.legacyImported = get("legacyimported") == "1";
				s.presetSeeded = get("presetseeded") == "1";
				s.lastPreset = get("lastpreset");
			}
			return s;
		}
		inline bool WriteState(const Paths& a_p, const State& a_s)
		{
			std::string t = "; HorizonUI.dll state (not settings)\r\n[State]\r\nLastVersion=" + a_s.lastVersion + "\r\nLegacyImported=" +
			                (a_s.legacyImported ? "1" : "0") + "\r\nPresetSeeded=" + (a_s.presetSeeded ? "1" : "0") + "\r\nLastPreset=" + CleanField(a_s.lastPreset, 120) + "\r\n";
			return WriteAtomic(a_p.state, t);
		}
		// once per game start, before any menu loads: update backup, then (no user.ini) migration / preset seeding
		inline void Startup(const Paths& a_p, const std::string& a_ver)
		{
			State st = ReadState(a_p);
			bool changed = false;
			if (st.lastVersion != a_ver) {
				if (Exists(a_p.user)) {
					std::string u;
					if (ReadText(a_p.user, u) && WriteAtomic(a_p.bak, u)) Log(0, "files: update " + (st.lastVersion.empty() ? std::string("(none)") : st.lastVersion) + " -> " + a_ver + ": HorizonUI.user.ini backed up to HorizonUI.user.bak.ini");
					else Log(1, "files: update backup FAILED (HorizonUI.user.bak.ini)");
				} else {
					Log(0, "files: first start of " + a_ver + " (no HorizonUI.user.ini to back up)");
				}
				st.lastVersion = a_ver;
				changed = true;
			}
			if (!Exists(a_p.user)) {
				const std::string defs = Defaults(a_p);
				if (defs.empty()) Log(1, "files: HorizonUI.default.ini missing - comparing with nothing");
				if (Exists(a_p.legacy)) {
					if (!st.legacyImported) {
						DiffOpt o;
						o.keepUnknownKeys = true;
						o.keepUnknownSections = true;
						std::string leg;
						ReadText(a_p.legacy, leg);
						const std::string u = Diff(StripSection(leg, "preset"), defs, "", o);
						if (WriteAtomic(a_p.user, u)) {
							st.legacyImported = true;
							changed = true;
							Log(0, "files: migrated HorizonUI.ini -> HorizonUI.user.ini (" + std::to_string(std::count(u.begin(), u.end(), '=')) + " values; HorizonUI.ini is left as it is)");
						} else Log(1, "files: migration FAILED (could not write HorizonUI.user.ini)");
					} else Log(0, "files: no HorizonUI.user.ini; HorizonUI.ini was imported before -> defaults (not imported again)");
				} else if (Exists(a_p.seed)) {
					if (!st.presetSeeded) {
						std::string pr;
						ReadText(a_p.seed, pr);
						if (WriteAtomic(a_p.user, PresetToUser(pr, defs))) {
							st.presetSeeded = true;
							changed = true;
							Log(0, "files: seeded HorizonUI.user.ini from presets/moragars_choice.ini (first start)");
						} else Log(1, "files: preset seeding FAILED");
					} else Log(0, "files: no HorizonUI.user.ini; the preset was seeded before -> defaults");
				} else Log(0, "files: no HorizonUI.user.ini -> defaults");
			}
			if (changed && !WriteState(a_p, st)) Log(1, "files: could not write HorizonUI.state.ini");
		}

		// ---------------- actions (F11) ----------------
		struct Result
		{
			bool        ok = false;
			std::string msg;
		};
		inline Result SaveFromHud(const Paths& a_p, const std::string& a_full)
		{
			Result r;
			DiffOpt o;
			const std::string u = Diff(a_full, Defaults(a_p), ReadOr(a_p.user), o);
			r.ok = WriteAtomic(a_p.user, u);
			r.msg = r.ok ? "settings saved (HorizonUI.user.ini, " + std::to_string(std::count(u.begin(), u.end(), '=')) + " values)" : "failed to write HorizonUI.user.ini";
			return r;
		}
		inline Result RestoreBackup(const Paths& a_p)
		{
			std::string b;
			if (!ReadText(a_p.bak, b)) return { false, "No update backup yet" };
			if (!WriteAtomic(a_p.user, b)) return { false, "Could not write HorizonUI.user.ini" };
			return { true, "Backup restored" };
		}
		inline Result UndoPreset(const Paths& a_p)
		{
			std::string b;
			if (!ReadText(a_p.preapply, b)) return { false, "Nothing to undo" };
			if (!WriteAtomic(a_p.user, b)) return { false, "Could not write HorizonUI.user.ini" };
			std::error_code ec;
			std::filesystem::remove(a_p.preapply, ec);
			return { true, "Settings from before the preset are back" };
		}
		inline Result ApplyPreset(const Paths& a_p, const std::string& a_id)
		{
			const auto defs = Defaults(a_p);
			const auto sc = ScanPresets(a_p, defs);
			const Preset* pr = FindPreset(sc, a_id);
			if (!pr) return { false, "Preset not found" };
			std::string text;
			if (!ReadText(pr->path, text, 512 * 1024)) return { false, "Could not read the preset" };
			std::string old;
			const bool hadUser = ReadText(a_p.user, old);
			const std::string undo = hadUser ? old : std::string("; no HorizonUI.user.ini before the preset was applied (undo = the defaults)\r\n");
			if (!WriteAtomic(a_p.preapply, undo)) return { false, "Could not write the undo copy" };
			if (!WriteAtomic(a_p.user, PresetToUser(text, defs, old))) return { false, "Could not write HorizonUI.user.ini" };
			State st = ReadState(a_p);
			st.lastPreset = pr->id;
			WriteState(a_p, st);
			return { true, "Applied '" + pr->name + "'" };
		}
		inline Result SavePreset(const Paths& a_p, const std::string& a_name, bool a_overwrite, const std::string& a_full, const std::string& a_when)
		{
			const auto name = hzpreset::CleanPresetName(a_name);   // same characters as the HUD (hz42NmOk), including '|' and DEL
			if (name.empty()) return { false, "Type a name first" };
			const auto file = a_p.userPresets / (Slug(name) + ".ini");
			// A shipped name stays in this list: dedupe only hides one shipped file when another
			// shipped file has the same name. Saved presets are not removed, so this guard still fires.
			for (const auto& sp : ScanPresets(a_p, Defaults(a_p)).list)
				if (!sp.user && Slug(sp.name) == Slug(name)) return { false, "A preset that came with the mod has that name - pick another name" };
			if (Exists(file) && !a_overwrite) return { false, "A saved preset with that name exists" };
			const std::string body = PresetBody(a_full, Defaults(a_p));   // rule 3: only what differs from the defaults
			if (body.find('=') == std::string::npos) return { false, "Nothing differs from the defaults - no preset needed" };
			const std::string text = "[Preset]\r\nName=" + name + "\r\nAuthor=Player\r\nVersion=" + kVersion + "\r\nDescription=Saved in game" +
			                         (a_when.empty() ? std::string() : " on " + a_when) + ".\r\n" + (body.empty() ? std::string() : "\r\n" + body);
			if (!WriteAtomic(file, text)) return { false, "Could not write presets/user/" + U8(file.filename()) };
			return { true, "Saved '" + name + "'" };
		}
		inline Result DeletePreset(const Paths& a_p, const std::string& a_id)
		{
			if (a_id.compare(0, 2, "u:") != 0) return { false, "Only saved presets can be deleted" };
			const auto sc = ScanPresets(a_p, Defaults(a_p));
			const Preset* pr = FindPreset(sc, a_id);
			if (!pr || !pr->user) return { false, "Preset not found" };
			std::error_code ec;
			if (std::filesystem::canonical(pr->path.parent_path(), ec) != std::filesystem::canonical(a_p.userPresets, ec)) return { false, "Refused" };
			if (!std::filesystem::remove(pr->path, ec)) return { false, "Could not delete it" };
			return { true, "Deleted '" + pr->name + "'" };
		}
		// for the HUD (hzSetFileState): "v=..|bak=..|undo=..|user=..|def=..|skip=N|last=<id>" then one line per preset:
		// "<id>|<1 user / 0 shipped>|<name>|<author>|<version>|<description>"
		inline std::string StateString(const Paths& a_p, const Scan& a_s)
		{
			std::string s = std::string("v=") + kVersion + "|bak=" + (Exists(a_p.bak) ? "1" : "0") + "|undo=" + (Exists(a_p.preapply) ? "1" : "0") +
			                "|user=" + (Exists(a_p.user) ? "1" : "0") + "|def=" + (Exists(a_p.def) ? "1" : "0") + "|skip=" + std::to_string(a_s.skipped.size()) + "|last=" + CleanField(ReadState(a_p).lastPreset, 120);
			for (const auto& p : a_s.list)
				s += "\n" + CleanField(p.id, 120) + "|" + (p.user ? "1" : "0") + "|" + p.name + "|" + p.author + "|" + p.version + "|" + p.desc;
			return s;
		}
		// one action string from the HUD (hzTakeFileAction)
		inline Result DoAction(const Paths& a_p, const std::string& a_act, const std::string& a_when, std::string& a_kind)
		{
			const auto nl = a_act.find('\n');
			const std::string head = a_act.substr(0, nl);
			const auto bar = head.find('|');
			a_kind = head.substr(0, bar);
			const std::string arg = bar == std::string::npos ? std::string() : head.substr(bar + 1);
			if (a_kind == "restore") return RestoreBackup(a_p);
			if (a_kind == "undo") return UndoPreset(a_p);
			if (a_kind == "apply") return ApplyPreset(a_p, arg);
			if (a_kind == "delete") return DeletePreset(a_p, arg);
			if (a_kind == "save") {
				const auto b2 = arg.find('|');
				if (b2 == std::string::npos || nl == std::string::npos) return { false, "bad save request" };
				return SavePreset(a_p, arg.substr(b2 + 1), arg.substr(0, b2) == "1", a_act.substr(nl + 1), a_when);
			}
			return { false, "unknown action" };
		}
	}
	// ==== HZF END ====

	HZF::Paths FilesP() { return HZF::MakePaths(HzDir()); }

	void LoadIni()
	{
		std::string key = "F11";
		std::string text;
		const auto  P = FilesP();
		// v0.37: HorizonUI.default.ini with HorizonUI.user.ini laid over (legacy HorizonUI.ini only when there is no default)
		if (!HZF::MergedText(P, text)) {
			REX::WARN("no settings file in {} (default / user / legacy), using F11", HZF::U8(P.dir));
		} else {
			HZF::Doc d = HZF::Parse(text);
			// any section, last one wins (as the v0.36 whole-file reader)
			auto get = [&](const char* a_k, std::string& a_v) {
				bool f = false;
				for (auto& sec : d.secs)
					if (auto it = sec.kv.find(a_k); it != sec.kv.end()) { a_v = it->second.second; f = true; }
				return f;
			};
			std::string v;
			if (get("settingskey", v) && !v.empty()) key = v;
		}
		auto sc = KeyNameToScan(key);
		if (!sc) { REX::WARN("unknown SettingsKey '{}', using F11", key); sc = 0x57; key = "F11"; }
		g_scan = sc;
		g_vk = static_cast<int>(MapVirtualKeyW(sc > 0x7F ? (0xE000 | (sc & 0x7F)) : sc, MAPVK_VSC_TO_VK_EX));
		REX::INFO("SettingsKey={} scan=0x{:X} vk=0x{:X}", key, g_scan, g_vk);
	}

	HWND GameWindow()
	{
		HWND w = GetForegroundWindow();
		DWORD pid = 0;
		GetWindowThreadProcessId(w, &pid);
		return pid == GetCurrentProcessId() ? w : nullptr;
	}

	bool TextMenuOpen(RE::UI* ui)
	{
		for (auto m : { "Console", "TextInputMenu", "PauseMenu" })
			if (ui->IsMenuOpen(m)) return true;
		return false;
	}

	// Call a function on the HUDMenu document object. Fallback to root.<fn> only when a_allowFallback.
	bool HudInvoke(const char* a_fn, GValue* a_result = nullptr, const GValue* a_args = nullptr, std::uint32_t a_n = 0, bool a_allowFallback = false)
	{
		auto ui = RE::UI::GetSingleton();
		if (!ui) return false;
		auto menu = ui->GetMenu("HUDMenu");
		if (!menu) return false;
		if (menu->menuObj.IsObject()) return menu->menuObj.Invoke(a_fn, a_result, a_args, a_n);
		if (a_allowFallback && menu->uiMovie && menu->uiMovie->asMovieRoot) {
			std::string path = std::string("root.") + a_fn;
			return menu->uiMovie->asMovieRoot->Invoke(path.c_str(), a_result, a_args, a_n);
		}
		return false;
	}

	// True only when the HUD is fully up and nothing loading-related or full-screen is open.
	// r6 / final: ship builder, outpost, inventory, galaxy map, photo mode, Data Menu, ship crew, plus skills,
	// missions, powers, status, research, the five crafting menus, container, barter, terminal, digipick (SecurityMenu),
	// chargen, photo gallery and blueprint (F11 on top of those froze input until Escape was mashed).
	// v0.42.0: + the remaining full-screen / modal menus (kDenyMenus42), registered menu names only (the lookup is
	// case-insensitive and an unknown name is simply never open). r2: + ScopeMenu, InspectMenu; the mission board is
	// registered as "MissionBoard" (MissionBoardMenu is its class name, ShipDialogueMenu was never verified: both dropped).
	constexpr const char* kDenyMenus42[] = {
		"PickpocketMenu", "MissionBoard", "WorkshopTargetMenu", "WorkshopQuickMenu",
		"ShipRefuelMenu", "SleepWaitMenu", "SitWaitMenu", "BookMenu", "DataSlateMenu", "MessageBoxMenu",
		"PlayBinkMenu", "CreditsMenu", "EndGameCreditsMenu", "TitleSequenceMenu", "WeaponGroupAssignmentMenu",
		"TakeoffMenu", "FavoritesMenu", "MarketplaceMenu", "AlmanacMenu", "DialogueMenu",
		"DocAcceptMenu", "StreamingInstallMenu", "TestMenu", "ScopeMenu", "InspectMenu"
	};

	// v0.42.0 r3: menus that block F11 but leave the HUD up underneath (no 3 s "HUD ready" restart after them)
	constexpr const char* kLightMenus422[] = { "ScopeMenu" };
	bool LightMenuOpen(RE::UI* a_ui)
	{
		for (auto m : kLightMenus422)
			if (a_ui->IsMenuOpen(m)) return true;
		return false;
	}

	bool HudSafe(bool a_light = true)
	{
		auto ui = RE::UI::GetSingleton();
		if (!ui) return false;
		if (!ui->IsMenuOpen("HUDMenu")) return false;
		for (auto m : { "LoadingMenu", "FaderMenu", "MainMenu", "PauseMenu", "Console",
		                "SpaceshipEditorMenu", "WorkshopMenu", "WorkshopBuilderMenu", "InventoryMenu",
		                "PhotoModeMenu", "GalaxyStarMapMenu", "DataMenu", "ShipCrewMenu", "ShipCrewAssignMenu",
		                "SpaceshipInfoMenu",
		                "SkillsMenu", "BSMissionMenu", "PowersMenu", "StatusMenu", "ResearchMenu",
		                "ArmorCraftingMenu", "WeaponsCraftingMenu", "DrugsCraftingMenu", "FoodCraftingMenu",
		                "IndustrialCraftingMenu", "ContainerMenu", "BarterMenu", "GenesisTerminalMenu",
		                "SecurityMenu", "ChargenMenu", "PhotoGalleryMenu", "Workshop_BlueprintMenu" })
			if (ui->IsMenuOpen(m)) return false;
		for (auto m : kDenyMenus42)   // v0.42.0
			if ((a_light || !LightMenuOpen(ui) || std::strcmp(m, "ScopeMenu") != 0) && ui->IsMenuOpen(m)) return false;
		auto menu = ui->GetMenu("HUDMenu");
		if (!menu || !menu->uiMovie || !menu->uiMovie->asMovieRoot) return false;
		return menu->menuObj.IsObject();
	}

	void PushDllFileVersion();   // v0.42.0.4: defined with the movie-build log

	void OnSettingsKey()
	{
		REX::INFO("Settings key pressed");
		auto ui = RE::UI::GetSingleton();
		if (!ui) return;
		if (TextMenuOpen(ui)) { REX::INFO("ignored: text/console/pause menu open"); return; }
		if (!HudSafe()) { REX::INFO("ignored: full-screen or loading menu open"); return; }
		if (ui->IsMenuOpen("MonocleMenu")) { REX::INFO("ignored: hand scanner open (F11 opens from the main HUD only)"); return; }   // v0.42.0
		PushDllFileVersion();   // v0.42.0.4: the header reads this on the open that follows
		bool ok = HudInvoke("hzToggleSettings", nullptr, nullptr, 0, true);
		REX::INFO("hzToggleSettings invoke {}", ok ? "OK" : "FAILED (HUD lacks function or HUDMenu missing)");
	}

	// ---------------- WndProc subclass: raw-input virtual cursor + input swallowing ----------------
	std::atomic<bool>        g_swallow{ false };  // set on main thread while settings is open & HUD safe
	std::mutex               g_qLock;
	std::vector<std::string> g_keyQueue;          // nav codes queued from window thread
	double                   g_curX = 0.5, g_curY = 0.5;
	bool                     g_lmb = false;
	bool                     g_mouseDirty = false;
	HWND                     g_hookedWnd = nullptr;
	WNDPROC                  g_origProc = nullptr;
	std::atomic<ULONGLONG>   g_lastRawKbd{ 0 };

	const char* VkToCode(UINT a_vk)
	{
		switch (a_vk) {
		case VK_UP: return "up";
		case VK_DOWN: return "down";
		case VK_LEFT: return "left";
		case VK_RIGHT: return "right";
		case VK_PRIOR: return "tabprev";
		case VK_NEXT:
		case VK_TAB: return "tabnext";
		case VK_RETURN: return "ok";
		case VK_ESCAPE: return "cancel";
		case VK_BACK: return "bksp";   // v0.37: delete in the preset name entry (the HUD treats it as cancel elsewhere)
		default: return nullptr;
		}
	}
	bool IsArrow(UINT a_vk) { return a_vk == VK_UP || a_vk == VK_DOWN || a_vk == VK_LEFT || a_vk == VK_RIGHT; }

	// v0.37: letters / digits / space / '-' for the F11 preset name entry, as "ch:<c>" (the HUD ignores them elsewhere)
	// v0.42.0 r2: + '+' / '=' (ARRANGE CARDS: scope chip size)
	std::string CharCode(UINT a_vk)
	{
		char       c = 0;
		const bool shift = (GetAsyncKeyState(VK_SHIFT) & 0x8000) != 0;
		if (a_vk >= 'A' && a_vk <= 'Z') {
			const bool caps = (GetKeyState(VK_CAPITAL) & 1) != 0;
			c = static_cast<char>(shift != caps ? a_vk : a_vk + 32);
		} else if (a_vk >= '0' && a_vk <= '9') {
			if (!shift) c = static_cast<char>(a_vk);
		} else if (a_vk >= VK_NUMPAD0 && a_vk <= VK_NUMPAD9) {
			c = static_cast<char>('0' + (a_vk - VK_NUMPAD0));
		} else if (a_vk == VK_SPACE) {
			c = ' ';
		} else if (a_vk == VK_OEM_MINUS || a_vk == VK_SUBTRACT) {
			c = (shift && a_vk == VK_OEM_MINUS) ? '_' : '-';
		} else if (a_vk == VK_OEM_PLUS || a_vk == VK_ADD) {
			c = (a_vk == VK_ADD || shift) ? '+' : '=';
		}
		if (!c) return {};
		return std::string("ch:") + c;
	}

	// key repeat state (window thread only)
	bool      g_kDown[256]{};
	ULONGLONG g_kNext[256]{};

	void QueueKey(UINT a_vk, bool a_down)
	{
		if (a_vk >= 256) return;
		auto        code = VkToCode(a_vk);
		std::string chr = code ? std::string() : CharCode(a_vk);
		if (!a_down) { g_kDown[a_vk] = false; return; }
		auto now = GetTickCount64();
		bool fire = false;
		if (!g_kDown[a_vk]) { fire = true; g_kNext[a_vk] = now + 400; }
		else if (IsArrow(a_vk) && now >= g_kNext[a_vk]) { fire = true; g_kNext[a_vk] = now + 150; }
		g_kDown[a_vk] = true;
		if (fire && (code || !chr.empty())) {
			std::lock_guard l(g_qLock);
			if (g_keyQueue.size() < 64) g_keyQueue.emplace_back(code ? std::string(code) : chr);
		}
	}

	void HandleRawInput(HWND a_wnd, LPARAM a_lp)
	{
		alignas(8) BYTE buf[sizeof(RAWINPUT) + 64];
		UINT            size = sizeof(buf);
		if (GetRawInputData(reinterpret_cast<HRAWINPUT>(a_lp), RID_INPUT, buf, &size, sizeof(RAWINPUTHEADER)) == static_cast<UINT>(-1)) return;
		auto* ri = reinterpret_cast<RAWINPUT*>(buf);
		if (ri->header.dwType == RIM_TYPEMOUSE) {
			const auto& m = ri->data.mouse;
			RECT        rc{};
			GetClientRect(a_wnd, &rc);
			double w = (std::max)(1L, rc.right - rc.left), h = (std::max)(1L, rc.bottom - rc.top);
			std::lock_guard l(g_qLock);
			if (m.usFlags & MOUSE_MOVE_ABSOLUTE) {
				POINT pt{};
				if (GetCursorPos(&pt) && ScreenToClient(a_wnd, &pt)) { g_curX = pt.x / w; g_curY = pt.y / h; }
			} else {
				g_curX += m.lLastX / w;
				g_curY += m.lLastY / h;
			}
			g_curX = std::clamp(g_curX, 0.0, 1.0);
			g_curY = std::clamp(g_curY, 0.0, 1.0);
			if (m.usButtonFlags & RI_MOUSE_LEFT_BUTTON_DOWN) g_lmb = true;
			if (m.usButtonFlags & RI_MOUSE_LEFT_BUTTON_UP) g_lmb = false;
			if (m.usButtonFlags & RI_MOUSE_WHEEL) {  // Horizon UI v0.23: wheel scrolls the settings list
				const auto dz = static_cast<short>(m.usButtonData);
				if (dz != 0 && g_keyQueue.size() < 64) g_keyQueue.emplace_back(dz > 0 ? "wheelup" : "wheeldown");
			}
			g_mouseDirty = true;
		} else if (ri->header.dwType == RIM_TYPEKEYBOARD) {
			g_lastRawKbd = GetTickCount64();
			const auto& k = ri->data.keyboard;
			QueueKey(k.VKey, !(k.Flags & RI_KEY_BREAK));
		}
	}

	bool IsSettingsKeyVk(WPARAM a_vk) { return static_cast<int>(a_vk) == g_vk; }

	LRESULT CALLBACK HzWndProc(HWND a_wnd, UINT a_msg, WPARAM a_wp, LPARAM a_lp)
	{
		if (g_swallow.load()) {
			switch (a_msg) {
			case WM_INPUT:
				{
					// peek: let the settings key through to the game/poller untouched
					alignas(8) BYTE buf[sizeof(RAWINPUT) + 64];
					UINT            size = sizeof(buf);
					if (GetRawInputData(reinterpret_cast<HRAWINPUT>(a_lp), RID_INPUT, buf, &size, sizeof(RAWINPUTHEADER)) != static_cast<UINT>(-1)) {
						auto* ri = reinterpret_cast<RAWINPUT*>(buf);
						if (ri->header.dwType == RIM_TYPEKEYBOARD && IsSettingsKeyVk(ri->data.keyboard.VKey))
							break;  // passthrough
					}
					HandleRawInput(a_wnd, a_lp);
					return DefWindowProcW(a_wnd, a_msg, a_wp, a_lp);  // required cleanup, game never sees it
				}
			case WM_KEYDOWN:
			case WM_SYSKEYDOWN:
			case WM_KEYUP:
			case WM_SYSKEYUP:
				if (IsSettingsKeyVk(a_wp)) break;  // passthrough
				if (GetTickCount64() - g_lastRawKbd.load() > 1000)  // only if game doesn't feed raw keyboard
					QueueKey(static_cast<UINT>(a_wp), a_msg == WM_KEYDOWN || a_msg == WM_SYSKEYDOWN);
				return 0;
			case WM_CHAR:
			case WM_SYSCHAR:
			case WM_MOUSEMOVE:
			case WM_LBUTTONDOWN:
			case WM_LBUTTONUP:
			case WM_RBUTTONDOWN:
			case WM_RBUTTONUP:
			case WM_MBUTTONDOWN:
			case WM_MBUTTONUP:
			case WM_MOUSEWHEEL:
			case WM_MOUSEHWHEEL:
			case WM_XBUTTONDOWN:
			case WM_XBUTTONUP:
				return 0;
			default:
				break;
			}
		}
		return CallWindowProcW(g_origProc, a_wnd, a_msg, a_wp, a_lp);
	}

	// main thread: install subclass on the game window (once per window)
	void EnsureSubclass(HWND a_wnd)
	{
		if (!a_wnd || a_wnd == g_hookedWnd) return;
		if (g_hookedWnd && g_origProc && IsWindow(g_hookedWnd))
			SetWindowLongPtrW(g_hookedWnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(g_origProc));
		auto prev = reinterpret_cast<WNDPROC>(SetWindowLongPtrW(a_wnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(&HzWndProc)));
		if (!prev) { REX::WARN("WndProc subclass failed ({})", GetLastError()); return; }
		g_origProc = prev;
		g_hookedWnd = a_wnd;
		REX::INFO("WndProc subclassed (hwnd=0x{:X})", reinterpret_cast<std::uintptr_t>(a_wnd));
	}

	// main thread: drain queue -> HUD
	void FlushInputToHud(bool a_open)
	{
		std::vector<std::string> keys;
		double                   x, y;
		bool                     lmb, dirty;
		{
			std::lock_guard l(g_qLock);
			keys.swap(g_keyQueue);
			x = g_curX; y = g_curY; lmb = g_lmb; dirty = g_mouseDirty;
			g_mouseDirty = false;
		}
		if (!a_open) return;
		for (auto& k : keys) {
			GValue arg(k.c_str());
			HudInvoke("hzSettingsKey", nullptr, &arg, 1);
		}
		static bool sent = false;
		if (dirty || !sent) {
			GValue args[3] = { GValue(x), GValue(y), GValue(lmb) };
			HudInvoke("hzSettingsMouse", nullptr, args, 3);
			sent = true;
		}
	}

	void OnSettingsOpenChanged(bool a_open)
	{
		std::lock_guard l(g_qLock);
		g_keyQueue.clear();
		g_curX = 0.5; g_curY = 0.5; g_lmb = false; g_mouseDirty = true;
		std::memset(g_kDown, 0, sizeof(g_kDown));
		(void)a_open;
	}

	RE::BSInputEnableLayer* g_layer = nullptr;
	bool                    g_blocked = false;

	// While the settings window is open, disable camera look + fighting (so clicks don't fire).
	void SetControlsBlocked(bool a_block)
	{
		if (a_block == g_blocked) return;
		if (!a_block && !g_layer) { g_blocked = false; return; }
		if (!g_layer) {
			auto mgr = RE::BSInputEnableManager::GetSingleton();
			if (!mgr || !mgr->AllocateNewLayer(&g_layer, "HorizonUI settings") || !g_layer) { g_layer = nullptr; return; }
		}
		g_layer->EnableUserEvent(RE::USER_EVENT_FLAG::Looking | RE::USER_EVENT_FLAG::Fighting, !a_block);
		g_blocked = a_block;
		REX::INFO("settings open={} (look/fight {})", a_block, a_block ? "blocked" : "restored");
	}

	ULONGLONG g_hudSince = 0;      // when HudSafe() became continuously true (0 = not ready)
	bool      g_hudReadyLogged = false;
	bool      g_firstInvokeLogged = false;
	bool      g_open = false;
	bool      g_scanWas42 = false;   // v0.42.0: MonocleMenu was open at the last poll
	ULONGLONG g_lastOpen = 0;
	ULONGLONG g_nextOpenPoll = 0;

	void ResetSettingsState()
	{
		if (g_open) REX::INFO("settings closed (HUD not safe)");
		// final (r6 SF-1): ARRANGE keeps hzSetIsOpen; one toggle only leaves arrange and re-shows F11.
		// Toggle at most twice while hzSettingsOpen (close-only: each call runs with open==true, so never opens).
		for (int i = 0; i < 2; ++i) {
			GValue open;
			if (!(HudInvoke("hzSettingsOpen", &open) && open.IsBoolean() && open.GetBoolean()))
				break;
			HudInvoke("hzToggleSettings", nullptr, nullptr, 0, true);
		}
		g_open = false;
		g_swallow = false;
		SetControlsBlocked(false);
	}

	// ---------------- v0.37: F11 settings-file actions (presets / backup), HUD <-> DLL ----------------
	// DLL -> HUD: hzSetFileState(state) when the window opens and after every action, hzFileActionDone("<kind>|<ok>|<msg>").
	// HUD -> DLL: hzTakeFileAction() -> "restore" / "undo" / "apply|<id>" / "delete|<id>" / "save|<overwrite>|<name>\n<full ini>".
	// A HUD without these functions (older gfx) simply never answers; an older DLL never calls hzSetFileState, so the
	// HUD keeps the new rows hidden.
	std::string g_skipSig;
	bool        g_fileStateLogged = false;

	std::string Today()
	{
		SYSTEMTIME t{};
		GetLocalTime(&t);
		char b[16];
		std::snprintf(b, sizeof(b), "%04u-%02u-%02u", t.wYear, t.wMonth, t.wDay);
		return b;
	}

	void PushFileState()
	{
		std::string st;
		try {
			const auto P = FilesP();
			const auto sc = HZF::ScanPresets(P, HZF::Defaults(P));
			std::string sig;
			for (const auto& k : sc.skipped) sig += k + "\n";
			for (const auto& k : sc.deduped) sig += k + "\n";
			if (sig != g_skipSig) {
				g_skipSig = sig;
				for (const auto& k : sc.skipped) REX::WARN("preset skipped: {}", k);
				for (const auto& k : sc.deduped) REX::INFO("{}", k);
				REX::INFO("presets: {} found, {} skipped, {} duplicate names hidden", sc.list.size(), sc.skipped.size(), sc.deduped.size());
			}
			st = HZF::StateString(P, sc);
		} catch (...) {
			REX::WARN("files: preset scan failed");
			return;
		}
		GValue     arg(st.c_str());
		const bool ok = HudInvoke("hzSetFileState", nullptr, &arg, 1);
		if (!g_fileStateLogged) {
			REX::INFO("files: hzSetFileState {}", ok ? "OK" : "FAILED (HUD gfx older than 0.37?)");
			g_fileStateLogged = true;
		}
	}

	void PollFileAction()
	{
		GValue a;
		if (!HudInvoke("hzTakeFileAction", &a) || !a.IsString()) return;
		const char* s = a.GetString();
		if (!s || !*s) return;
		const std::string act(s);
		std::string       kind = "?";
		HZF::Result       r;
		try {
			r = HZF::DoAction(FilesP(), act, Today(), kind);
		} catch (...) {
			r.ok = false;
			r.msg = "error";
		}
		if (r.ok) REX::INFO("files: {} -> {}", kind, r.msg);
		else REX::WARN("files: {} FAILED: {}", kind, r.msg);
		if (r.ok && (kind == "apply" || kind == "restore" || kind == "undo")) LoadIni();
		const std::string reply = kind + "|" + (r.ok ? "1" : "0") + "|" + HZF::CleanField(r.msg, 200);
		GValue            arg(reply.c_str());
		HudInvoke("hzFileActionDone", nullptr, &arg, 1);
		PushFileState();
	}

	void FilesStartup()
	{
		HZF::g_log = [](int a_l, const std::string& a_s) {
			if (a_l) REX::WARN("{}", a_s);
			else REX::INFO("{}", a_s);
		};
		try {
			HZF::Startup(FilesP(), HZF::kVersion);
		} catch (...) {
			REX::WARN("files: startup error");
		}
	}

	void PollSettings(HWND a_wnd, ULONGLONG a_now)
	{
		if (!g_open && a_now < g_nextOpenPoll) return;
		g_nextOpenPoll = a_now + 100;

		if (!g_firstInvokeLogged) { REX::INFO("first per-frame invoke: hzSettingsOpen"); g_firstInvokeLogged = true; }
		GValue open;
		bool   isOpen = HudInvoke("hzSettingsOpen", &open) && open.IsBoolean() && open.GetBoolean();
		if (isOpen != g_open) {
			REX::INFO("settings {}", isOpen ? "opened" : "closed");
			g_open = isOpen;
			OnSettingsOpenChanged(isOpen);
			if (isOpen) PushFileState();   // v0.37: presets / backup state for the F11 rows
		}
		g_swallow = isOpen;
		if (isOpen) g_lastOpen = a_now;
		SetControlsBlocked(isOpen);

		if (!isOpen && (g_lastOpen == 0 || a_now - g_lastOpen > 2000)) { FlushInputToHud(false); return; }
		(void)a_wnd;
		FlushInputToHud(isOpen);
		PollFileAction();   // v0.37

		GValue ini;
		if (HudInvoke("hzTakeSaveIni", &ini) && ini.IsString()) {
			const char* s = ini.GetString();
			if (s && *s) {
				// v0.37: the HUD still hands over the full merged text; only what differs from HorizonUI.default.ini
				// (plus keys user.ini already had, plus other modules' sections) goes into HorizonUI.user.ini,
				// atomically. HorizonUI.default.ini and the legacy HorizonUI.ini are never written.
				HZF::Result r;
				try { r = HZF::SaveFromHud(FilesP(), s); } catch (...) { r.ok = false; r.msg = "error"; }
				if (r.ok) {
					REX::INFO("{}", r.msg);
					LoadIni();
				} else {
					REX::WARN("save FAILED: {}", r.msg);
				}
			}
		}
	}

	// v0.38: is the loaded HUDMenu Horizon's? (other HUD replacers ship their own hudmenu.gfx; the F11
	// window lives in Horizon's movie, so the warning can only be a log line.) v0.39: asks hzSettingsOpen (read-only,
	// returns a Boolean), Horizon's own HUD callback. Every Horizon HUD since v0.18 answers it, so this tells Horizon from
	// a foreign HUD, not one Horizon version from another (the F11 window shows the HUD's version). Logged when the
	// answer changes.
	int g_hudOwner = -1;   // -1 unknown, 0 foreign, 1 Horizon
	void HudOwnerCheck()
	{
		GValue q;
		const int now = (HudInvoke("hzSettingsOpen", &q) && q.IsBoolean()) ? 1 : 0;
		if (now == g_hudOwner) return;
		g_hudOwner = now;
		if (now) REX::INFO("hud: HUDMenu answers hzSettingsOpen - a Horizon UI hudmenu.gfx is loaded (any Horizon HUD since v0.18 answers; the F11 window shows its version)");
		else REX::WARN("hud: HUDMenu does not answer hzSettingsOpen - the loaded hudmenu.gfx is not a Horizon UI HUD (another HUD replacer overrides it; check the load order)");
	}

	// ---------------- v0.40.3: the game's planet location banner while the Horizon scanner is open ----------------
	// HUDMessagesMenu > Location_mc > PlanetLocationTextAnim_mc (the body name and its system / type line) shows through
	// the Horizon scanner's cards. The Comms module hides it inside its own movie. Without Comms (the game's own HUD
	// messages movie) the DLL does the same: alpha 0 while MonocleMenu is open, the alpha it had before back when the
	// scanner closes, a load / main / pause menu opens, or the movie goes away. Only with the Scanner module installed
	// (modules\scanner.marker). Nothing is removed; the game's banner queue and animation are not touched.
	bool      g_banHidden = false;
	double    g_banAlpha = 1.0;
	ULONGLONG g_banNext = 0;
	ULONGLONG g_banMarkT = 0;
	int       g_banScanMod = -1;   // scanner.marker: -1 not checked yet, 0 absent, 1 present
	bool      g_banCommsLogged = false;

	// the banner clip of the HUD messages movie; false (and a_comms = true) when that movie is Horizon's Comms movie
	bool BannerClip(GValue& a_clip, bool& a_comms)
	{
		a_comms = false;
		auto ui = RE::UI::GetSingleton();
		if (!ui) return false;
		auto menu = ui->GetMenu("HUDMessagesMenu");
		if (!menu || !menu->menuObj.IsObject()) return false;
		if (menu->menuObj.HasMember("hzcProbeDone")) { a_comms = true; return false; }
		GValue loc;
		if (!menu->menuObj.GetMember("Location_mc", &loc) || !loc.IsObject()) return false;
		if (!loc.GetMember("PlanetLocationTextAnim_mc", &a_clip) || !a_clip.IsObject()) return false;
		return true;
	}

	void BannerRestore()
	{
		if (!g_banHidden) return;
		g_banHidden = false;
		GValue clip;
		bool   comms = false;
		if (BannerClip(clip, comms) && clip.SetMember("alpha", GValue(g_banAlpha))) REX::INFO("scanner: location banner restored");
	}

	// v0.41.0 (test r2): the hand scanner state to the Horizon HUD (hz41DllScan) and the Comms HUD messages movie
	// (hzcDllScan). Only while MonocleMenu is open (every 100 ms) plus ONE "closed" push when it closes, and only with the
	// Scanner module (modules\scanner.marker). Outside a scan nothing is called. Never while a load / fader / main / pause
	// menu is up (a closed push waits until it is gone). Each movie only when it is open and its document object answers
	// (HasMember). The first push of the session and the first closed push are logged once (which movies answered).
	bool g_pushOpen = false;      // the last push said "open"
	bool g_pushLogged = false;
	bool g_pushEndLogged = false;
	void ScanPush(RE::UI* a_ui)
	{
		for (auto m : { "LoadingMenu", "FaderMenu", "MainMenu", "PauseMenu" })
			if (a_ui->IsMenuOpen(m)) return;
		const bool open = g_banScanMod == 1 && a_ui->IsMenuOpen("MonocleMenu");
		if (!open && !g_pushOpen) return;   // not scanning and the closed push was sent: nothing
		GValue arg(open);
		bool hudOk = false, msgOk = false;
		if (a_ui->IsMenuOpen("HUDMenu"))
			if (auto hud = a_ui->GetMenu("HUDMenu"); hud && hud->menuObj.IsObject() && hud->menuObj.HasMember("hz41DllScan"))
				hudOk = hud->menuObj.Invoke("hz41DllScan", nullptr, &arg, 1);
		if (a_ui->IsMenuOpen("HUDMessagesMenu"))
			if (auto msg = a_ui->GetMenu("HUDMessagesMenu"); msg && msg->menuObj.IsObject() && msg->menuObj.HasMember("hzcDllScan"))
				msgOk = msg->menuObj.Invoke("hzcDllScan", nullptr, &arg, 1);
		if (open && !g_pushLogged) {
			g_pushLogged = true;
			REX::INFO("scanner: scan state push started (HUD hz41DllScan {}, HUD messages hzcDllScan {})", hudOk ? "OK" : "not answered", msgOk ? "OK" : "not answered (no Comms module?)");
		}
		if (!open && !g_pushEndLogged) {
			g_pushEndLogged = true;
			REX::INFO("scanner: scan state push ended (closed sent once; HUD {}, HUD messages {})", hudOk ? "OK" : "not answered", msgOk ? "OK" : "not answered");
		}
		g_pushOpen = open;
	}

	void BannerPoll(ULONGLONG a_now)
	{
		if (a_now < g_banNext) return;
		g_banNext = a_now + 100;
		auto ui = RE::UI::GetSingleton();
		if (!ui) return;
		if (g_banScanMod < 0 || a_now - g_banMarkT > 10000) {
			std::error_code ec;
			g_banScanMod = std::filesystem::exists(HzDir() / "modules" / "scanner.marker", ec) ? 1 : 0;
			g_banMarkT = a_now;
		}
		ScanPush(ui);   // v0.41.0 (test r2: after the marker check; only while scanning + one closed push)
		bool scan = g_banScanMod == 1 && ui->IsMenuOpen("MonocleMenu");
		for (auto m : { "LoadingMenu", "FaderMenu", "MainMenu", "PauseMenu" })
			if (ui->IsMenuOpen(m)) scan = false;
		if (!scan) { BannerRestore(); return; }
		GValue clip;
		bool   comms = false;
		if (!BannerClip(clip, comms)) {
			if (comms && !g_banCommsLogged) { REX::INFO("scanner: location banner left to the Comms module"); g_banCommsLogged = true; }
			g_banHidden = false;   // the movie went away (or is Comms): nothing of ours to restore
			return;
		}
		if (!g_banHidden) {
			GValue a;
			g_banAlpha = (clip.GetMember("alpha", &a) && a.IsNumber()) ? a.GetNumber() : 1.0;
			if (g_banAlpha <= 0.0) g_banAlpha = 1.0;
		}
		if (clip.SetMember("alpha", GValue(0.0))) {
			if (!g_banHidden) REX::INFO("scanner: location banner hidden (no Comms module)");
			g_banHidden = true;
		}
	}

	// Purpose: read this DLL's own FileVersion string from its version resource.
	// Inputs: none (the module that contains this function). Outputs: the four-part file version, or empty on failure.
	// Dependencies: version.dll. The resource is generated from src/hz_version.h.
	// Last modified: 2026-10-20.
	std::string ReadOwnFileVersion()
	{
		HMODULE mod = nullptr;
		if (!::GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
		        reinterpret_cast<LPCWSTR>(&ReadOwnFileVersion), &mod) || !mod)
			return {};
		wchar_t path[MAX_PATH]{};
		const DWORD n = ::GetModuleFileNameW(mod, path, MAX_PATH);
		if (n == 0 || n >= MAX_PATH) return {};
		DWORD unused = 0;
		const DWORD bytes = ::GetFileVersionInfoSizeW(path, &unused);
		if (bytes == 0) return {};
		std::vector<unsigned char> buf(bytes);
		if (!::GetFileVersionInfoW(path, 0, bytes, buf.data())) return {};
		struct Tr { WORD lang; WORD cp; };
		Tr* tr = nullptr;
		UINT trBytes = 0;
		if (::VerQueryValueW(buf.data(), L"\\VarFileInfo\\Translation", reinterpret_cast<void**>(&tr), &trBytes) && tr && trBytes >= sizeof(Tr)) {
			wchar_t query[80]{};
			const wchar_t* hex = L"0123456789abcdef";
			auto hex4 = [&](WORD a_w, wchar_t* a_d) {
				a_d[0] = hex[(a_w >> 12) & 0xF];
				a_d[1] = hex[(a_w >> 8) & 0xF];
				a_d[2] = hex[(a_w >> 4) & 0xF];
				a_d[3] = hex[a_w & 0xF];
			};
			const wchar_t* pre = L"\\StringFileInfo\\";
			const wchar_t* suf = L"\\FileVersion";
			int q = 0;
			for (int i = 0; pre[i]; ++i) query[q++] = pre[i];
			hex4(tr[0].lang, query + q); q += 4;
			hex4(tr[0].cp, query + q); q += 4;
			for (int i = 0; suf[i]; ++i) query[q++] = suf[i];
			query[q] = 0;
			wchar_t* str = nullptr;
			UINT slen = 0;
			if (::VerQueryValueW(buf.data(), query, reinterpret_cast<void**>(&str), &slen) && str && slen > 0 && str[0]) {
				std::string out;
				bool ascii = true;
				// slen counts wchar_t in the version buffer, including the NUL. The index is checked
				// before the read, and the copy stops at 64 so a missing NUL cannot walk off the buffer.
				const UINT lim = slen < 64u ? slen : 64u;
				for (UINT i = 0; i < lim && str[i] != L'\0'; ++i) {
					if (str[i] > 127) { ascii = false; break; }
					out.push_back(static_cast<char>(str[i]));
				}
				while (!out.empty() && (out.back() == ' ' || out.back() == '\0')) out.pop_back();
				std::size_t b = 0;
				while (b < out.size() && out[b] == ' ') ++b;
				if (b) out.erase(0, b);
				if (!out.empty() && (out[0] == 'v' || out[0] == 'V')) out.erase(0, 1);
				if (ascii && HzFileVersionOk(out)) return out;
			}
		}
		VS_FIXEDFILEINFO* info = nullptr;
		UINT len = 0;
		if (!::VerQueryValueW(buf.data(), L"\\", reinterpret_cast<void**>(&info), &len) || !info || len < sizeof(VS_FIXEDFILEINFO))
			return {};
		char b[32];
		std::snprintf(b, sizeof(b), "%u.%u.%u.%u",
			static_cast<unsigned>(HIWORD(info->dwFileVersionMS)),
			static_cast<unsigned>(LOWORD(info->dwFileVersionMS)),
			static_cast<unsigned>(HIWORD(info->dwFileVersionLS)),
			static_cast<unsigned>(LOWORD(info->dwFileVersionLS)));
		return b;
	}

	// Purpose: the file version shown at load, in the movie-builds line, and sent to F11.
	// Inputs: none. Outputs: the version resource when it reads cleanly, otherwise HZ_FILE_VERSION_STR.
	// Dependencies: ReadOwnFileVersion, src/hz_version.h. One string, not a second hand-typed copy.
	// Last modified: 2026-10-21.
	const std::string& DllFileVersion()
	{
		static const std::string v = []() {
			std::string s = ReadOwnFileVersion();
			if (!HzFileVersionOk(s)) {
				REX::WARN("dll file version resource unreadable; using {}", HZ_FILE_VERSION_STR);
				s = HZ_FILE_VERSION_STR;
			}
			return s;
		}();
		return v;
	}

	// Purpose: give the HUD the DLL file version for the F11 header.
	// Inputs: none. Outputs: hzSetDllFileVersion on HUDMenu when that movie has the function.
	// An older HUD is left alone. Dependencies: DllFileVersion.
	// Last modified: 2026-10-20.
	bool g_dllVerLogged = false;
	void PushDllFileVersion()
	{
		auto ui = RE::UI::GetSingleton();
		if (!ui) return;
		auto menu = ui->GetMenu("HUDMenu");
		if (!menu || !menu->menuObj.IsObject() || !menu->menuObj.HasMember("hzSetDllFileVersion")) return;
		const std::string& v = DllFileVersion();
		if (!HzFileVersionOk(v)) return;
		GValue arg(v.c_str());
		if (!menu->menuObj.Invoke("hzSetDllFileVersion", nullptr, &arg, 1)) return;
		if (!g_dllVerLogged) {
			g_dllVerLogged = true;
			REX::INFO("dll file version {} sent to the F11 header", v);
		}
	}

	// v0.42.0 r3: which Horizon movie builds are loaded (HUD hzBuildId / Comms hzcBuildId), logged when it changes.
	// The DLL file version is DllFileVersion(), not a literal, so it cannot drift from the version resource.
	std::string g_buildsLogged;
	ULONGLONG   g_buildsNext = 0;
	void BuildLog(ULONGLONG a_now)
	{
		if (a_now < g_buildsNext) return;
		g_buildsNext = a_now + 5000;
		auto ui = RE::UI::GetSingleton();
		if (!ui) return;
		PushDllFileVersion();
		std::string hud = "no build id (older than r3 or not Horizon)", msg = "no build id (older than r3, no Comms module or not open)";
		GValue a;
		if (HudInvoke("hzBuildId", &a) && a.IsString() && a.GetString()) hud = a.GetString();
		if (ui->IsMenuOpen("HUDMessagesMenu"))
			if (auto m = ui->GetMenu("HUDMessagesMenu"); m && m->menuObj.IsObject() && m->menuObj.HasMember("hzcBuildId")) {
				GValue b;
				if (m->menuObj.Invoke("hzcBuildId", &b, nullptr, 0) && b.IsString() && b.GetString()) msg = b.GetString();
			}
		const std::string s = "HUD " + hud + ", Comms HUD messages " + msg;
		if (s == g_buildsLogged) return;
		g_buildsLogged = s;
		REX::INFO("movie builds: {} (DLL file version {})", s, DllFileVersion());
	}

	// Purpose: copy queued HUD message lines into HorizonUI.log.
	// Inputs: a_now, the poll clock. Outputs: "comms msg:" lines, only when the movie queued some.
	// Dependencies: HUDMessagesMenu.hzcTakeDbg. Compiled only when HZ_COMMS_MSG_LOG is 1
	// (src/hz_version.h). With the switch at 0 the function is empty, so message text is not written.
	// Last modified: 2026-10-22.
#ifndef HZ_COMMS_MSG_LOG
#define HZ_COMMS_MSG_LOG 0
#endif
#if HZ_COMMS_MSG_LOG

	// Purpose: read one ShowHUDMessageEvent without letting a bad pointer escape this function.
	// Inputs: the event. Outputs: 1 and a filled snap, or 0 when the read faulted.
	// Dependencies: RE::ShowHUDMessageEvent (text, sound, canThrottle, isWarning). The copy is bounded.
	// Last modified: 2026-10-22.
	struct HudMsgSnap
	{
		bool match;
		bool throttle;
		bool warning;
		char text[201];
		char sound[97];
	};

	static void HzCopyRaw(char* a_dst, std::size_t a_cap, const char* a_src)
	{
		if (!a_dst || a_cap == 0) return;
		a_dst[0] = '\0';
		if (!a_src) return;
		std::size_t i = 0;
		for (; a_src[i] != '\0' && i + 1 < a_cap; ++i) {
			const unsigned char c = static_cast<unsigned char>(a_src[i]);
			a_dst[i] = (c < 32 || c == 127) ? ' ' : static_cast<char>(c);
		}
		a_dst[i] = '\0';
	}

	static bool HzHasThat(const char* a_s)
	{
		if (!a_s) return false;
		const auto low = [](unsigned char c) {
			return (c >= 'A' && c <= 'Z') ? static_cast<char>(c - 'A' + 'a') : static_cast<char>(c);
		};
		for (std::size_t i = 0; a_s[i] != '\0'; ++i) {
			if (low(static_cast<unsigned char>(a_s[i])) != ' ') continue;
			const char c1 = a_s[i + 1];
			if (c1 == '\0') return false;
			if (low(static_cast<unsigned char>(c1)) != 't') continue;
			const char c2 = a_s[i + 2];
			if (c2 == '\0' || low(static_cast<unsigned char>(c2)) != 'h') continue;
			const char c3 = a_s[i + 3];
			if (c3 == '\0' || low(static_cast<unsigned char>(c3)) != 'a') continue;
			const char c4 = a_s[i + 4];
			if (c4 == '\0' || low(static_cast<unsigned char>(c4)) != 't') continue;
			return true;
		}
		return false;
	}

	static void HzHudMsgCopyCall(const RE::ShowHUDMessageEvent* a_ev, HudMsgSnap* a_out)
	{
		if (!a_ev || !a_out) return;
		HzCopyRaw(a_out->text, sizeof(a_out->text), a_ev->text.c_str());
		HzCopyRaw(a_out->sound, sizeof(a_out->sound), a_ev->sound.c_str());
		a_out->throttle = a_ev->canThrottle;
		a_out->warning = a_ev->isWarning;
	}

	static RE::BSTEventSource<RE::ShowHUDMessageEvent>* HzHudMsgSourceCall()
	{
		return RE::ShowHUDMessageEvent::GetEventSource();
	}

	static void HzHudMsgRegisterCall(RE::BSTEventSource<RE::ShowHUDMessageEvent>* a_src, RE::BSTEventSink<RE::ShowHUDMessageEvent>* a_sink)
	{
		if (a_src && a_sink) a_src->RegisterSink(a_sink);
	}

	// The SEH helpers only call through a function pointer, so an inlined Relocation cannot
	// force object unwinding inside the __try (MSVC C2712). An access fault returns a code; it does not escape.
	// A missing address id is not one of those faults: that lookup hard-exits, and SEH does not catch it.
#if defined(_MSC_VER)
	static int HzHudMsgReadSEH(const RE::ShowHUDMessageEvent* a_ev, HudMsgSnap* a_out) noexcept
	{
		if (!a_ev || !a_out) return 0;
		using Fn = void (*)(const RE::ShowHUDMessageEvent*, HudMsgSnap*);
		Fn fn = &HzHudMsgCopyCall;
		__try {
			fn(a_ev, a_out);
			return 1;
		} __except (EXCEPTION_EXECUTE_HANDLER) {
			return 0;
		}
	}
	static int HzHudMsgSourceSEH(RE::BSTEventSource<RE::ShowHUDMessageEvent>** a_out) noexcept
	{
		if (!a_out) return -1;
		*a_out = nullptr;
		using Fn = RE::BSTEventSource<RE::ShowHUDMessageEvent>* (*)();
		Fn fn = &HzHudMsgSourceCall;
		__try {
			*a_out = fn();
			return *a_out ? 1 : 0;
		} __except (EXCEPTION_EXECUTE_HANDLER) {
			return -1;
		}
	}
	static int HzHudMsgRegisterSEH(RE::BSTEventSource<RE::ShowHUDMessageEvent>* a_src, RE::BSTEventSink<RE::ShowHUDMessageEvent>* a_sink) noexcept
	{
		if (!a_src || !a_sink) return 0;
		using Fn = void (*)(RE::BSTEventSource<RE::ShowHUDMessageEvent>*, RE::BSTEventSink<RE::ShowHUDMessageEvent>*);
		Fn fn = &HzHudMsgRegisterCall;
		__try {
			fn(a_src, a_sink);
			return 1;
		} __except (EXCEPTION_EXECUTE_HANDLER) {
			return 0;
		}
	}
#else
	static int HzHudMsgReadSEH(const RE::ShowHUDMessageEvent* a_ev, HudMsgSnap* a_out) noexcept
	{
		if (!a_ev || !a_out) return 0;
		try { HzHudMsgCopyCall(a_ev, a_out); return 1; } catch (...) { return 0; }
	}
	static int HzHudMsgSourceSEH(RE::BSTEventSource<RE::ShowHUDMessageEvent>** a_out) noexcept
	{
		if (!a_out) return -1;
		*a_out = nullptr;
		try { *a_out = HzHudMsgSourceCall(); return *a_out ? 1 : 0; } catch (...) { return -1; }
	}
	static int HzHudMsgRegisterSEH(RE::BSTEventSource<RE::ShowHUDMessageEvent>* a_src, RE::BSTEventSink<RE::ShowHUDMessageEvent>* a_sink) noexcept
	{
		if (!a_src || !a_sink) return 0;
		try { HzHudMsgRegisterCall(a_src, a_sink); return 1; } catch (...) { return 0; }
	}
#endif

	void HzRxEnqueue(const char* a_text);

	class ShowHUDMessageSink final : public RE::BSTEventSink<RE::ShowHUDMessageEvent>
	{
	public:
		// Purpose: log a HUD message whose text contains " that", and never stop the game's own listeners.
		// Inputs: the event (text, sound, canThrottle, isWarning). Outputs: kContinue. A bad event is skipped.
		// Dependencies: HzHudMsgReadSEH. Last modified: 2026-10-22.
		RE::BSEventNotifyControl ProcessEvent(const RE::ShowHUDMessageEvent& a_event, RE::BSTEventSource<RE::ShowHUDMessageEvent>*) override
		{
			try {
				HudMsgSnap snap{};
				if (!HzHudMsgReadSEH(&a_event, &snap)) {
					if (!g_hudMsgReadWarned) {
						g_hudMsgReadWarned = true;
						REX::WARN("ShowHUDMessageEvent sink failed: message could not be read");
					}
					return RE::BSEventNotifyControl::kContinue;
				}
				snap.match = HzHasThat(snap.text);
				if (!snap.match) return RE::BSEventNotifyControl::kContinue;
				REX::INFO("hud message: text=\"{}\" sound=\"{}\" canThrottle={} isWarning={}",
					snap.text, snap.sound, snap.throttle ? 1 : 0, snap.warning ? 1 : 0);
				// This thread is not the UI thread. Copy the text and return. Poll invokes Scaleform.
				HzRxEnqueue(snap.text);
			} catch (const std::exception& ex) {
				if (!g_hudMsgReadWarned) {
					g_hudMsgReadWarned = true;
					REX::WARN("ShowHUDMessageEvent sink failed: {}", ex.what());
				}
			} catch (...) {
				if (!g_hudMsgReadWarned) {
					g_hudMsgReadWarned = true;
					REX::WARN("ShowHUDMessageEvent sink failed: unknown error");
				}
			}
			return RE::BSEventNotifyControl::kContinue;
		}

		bool g_hudMsgReadWarned = false;
	};

	// 0 pending, 1 registered, -1 failed and will not be tried again.
	int g_hudMsgSink = 0;

	// Purpose: register the ShowHUDMessageEvent sink (address id 86800) from kPostDataLoad.
	// RegisterSink is address id 123821.
	// A null source, or a fault caught around the source pointer or RegisterSink, is logged and ignored.
	// A missing address id still hard-exits. GetEventSource looks the id up with a call that ends the
	// process, and SEH does not catch that lookup.
	// Inputs: none. Outputs: HorizonUI.log. Dependencies: RE::ShowHUDMessageEvent::GetEventSource.
	// Last modified: 2026-10-22.
	void RegisterShowHUDMessageSink()
	{
		if (g_hudMsgSink != 0) return;
		try {
			RE::BSTEventSource<RE::ShowHUDMessageEvent>* src = nullptr;
			const int got = HzHudMsgSourceSEH(&src);
			if (got < 0) {
				g_hudMsgSink = -1;
				REX::WARN("ShowHUDMessageEvent sink failed: GetEventSource faulted (address id 86800)");
				return;
			}
			if (!src) {
				g_hudMsgSink = -1;
				REX::WARN("ShowHUDMessageEvent sink failed: event source is null (address id 86800)");
				return;
			}
			static ShowHUDMessageSink sink;
			if (!HzHudMsgRegisterSEH(src, &sink)) {
				g_hudMsgSink = -1;
				REX::WARN("ShowHUDMessageEvent sink failed: RegisterSink faulted (address id 86800)");
				return;
			}
			g_hudMsgSink = 1;
			REX::INFO("ShowHUDMessageEvent sink registered (address id 86800)");
		} catch (const std::exception& ex) {
			g_hudMsgSink = -1;
			REX::WARN("ShowHUDMessageEvent sink failed: {}", ex.what());
		} catch (...) {
			g_hudMsgSink = -1;
			REX::WARN("ShowHUDMessageEvent sink failed: unknown error");
		}
	}

	// The sink thread only pushes. The timestamp is the enqueue time, not a 30 s expiry.
	constexpr std::size_t kRxQueueMax = 8;
	struct RxNote
	{
		char      text[201];
		ULONGLONG tick;
	};
	std::mutex        g_rxMu;
	std::deque<RxNote> g_rxQ;

	void HzRxEnqueue(const char* a_text)
	{
		if (!a_text || !a_text[0]) return;
		RxNote n{};
		HzCopyRaw(n.text, sizeof(n.text), a_text);
		n.tick = GetTickCount64();
		try {
			std::lock_guard<std::mutex> lock(g_rxMu);
			if (g_rxQ.size() >= kRxQueueMax) g_rxQ.pop_front();
			g_rxQ.push_back(n);
		} catch (...) {
		}
	}

	int HzRxMessagesVisible(RE::UI* a_ui)
	{
		if (!a_ui) return -1;
		try {
			auto msg = a_ui->GetMenu("HUDMessagesMenu");
			if (!msg || !msg->menuObj.IsObject()) return -1;
			GValue mc;
			if (!msg->menuObj.GetMember("Messages_mc", &mc) || !mc.IsObject()) return -1;
			GValue v;
			if (!mc.GetMember("visible", &v) || !v.IsBoolean()) return -1;
			return v.GetBoolean() ? 1 : 0;
		} catch (...) {
			return -1;
		}
	}

	ULONGLONG g_rxWhyNext = 0;

	// Purpose: drain the reaction queue on the UI thread and log hzcRxPush's status once per reaction.
	// Skips loading and the main menu. Not gated on the 3 s HUD-ready wait. A missing hzcRxPush is skipped.
	// Last modified: 2026-10-22.
	void CommsRxPoll(ULONGLONG a_now)
	{
		auto ui = RE::UI::GetSingleton();
		if (!ui) return;
		for (auto m : { "LoadingMenu", "MainMenu" })
			if (ui->IsMenuOpen(m)) return;
		if (!ui->IsMenuOpen("HUDMessagesMenu")) return;
		auto msg = ui->GetMenu("HUDMessagesMenu");
		if (!msg || !msg->menuObj.IsObject()) return;
		try {
			if (a_now >= g_rxWhyNext && msg->menuObj.HasMember("hzcRxWhy")) {
				g_rxWhyNext = a_now + 500;
				GValue why;
				if (msg->menuObj.Invoke("hzcRxWhy", &why, nullptr, 0) && why.IsString() && why.GetString() && why.GetString()[0])
					REX::INFO("comms reaction: {}", why.GetString());
			}
		} catch (...) {
		}
		if (!msg->menuObj.HasMember("hzcRxPush")) return;
		std::deque<RxNote> batch;
		try {
			std::lock_guard<std::mutex> lock(g_rxMu);
			batch.swap(g_rxQ);
		} catch (...) {
			return;
		}
		const bool dialogue = ui->IsMenuOpen("DialogueMenu");
		const int  vis = HzRxMessagesVisible(ui);
		const char* visTx = vis < 0 ? "unknown" : (vis ? "1" : "0");
		for (const auto& n : batch) {
			std::string status = "invoke failed";
			try {
				GValue arg(n.text);
				GValue ret;
				if (msg->menuObj.Invoke("hzcRxPush", &ret, &arg, 1) && ret.IsString() && ret.GetString())
					status = ret.GetString();
			} catch (...) {
				status = "invoke failed";
			}
			REX::INFO("comms reaction: {} | messages visible={} | dialogue={}", status, visTx, dialogue ? 1 : 0);
		}
	}

	ULONGLONG g_cdbgNext = 0;
	bool      g_cdbgLogged = false;
	void CommsDbgPoll(ULONGLONG a_now)
	{
		if (a_now < g_cdbgNext) return;
		g_cdbgNext = a_now + 500;
		auto ui = RE::UI::GetSingleton();
		if (!ui) return;
		for (auto m : { "LoadingMenu", "MainMenu" })
			if (ui->IsMenuOpen(m)) return;
		if (!ui->IsMenuOpen("HUDMessagesMenu")) return;
		auto msg = ui->GetMenu("HUDMessagesMenu");
		if (!msg || !msg->menuObj.IsObject() || !msg->menuObj.HasMember("hzcTakeDbg")) return;
		GValue r;
		if (!msg->menuObj.Invoke("hzcTakeDbg", &r, nullptr, 0) || !r.IsString()) return;
		const char* s = r.GetString();
		if (!s || !*s) return;
		if (!g_cdbgLogged) { g_cdbgLogged = true; REX::INFO("comms msg: message log on (HZ_COMMS_MSG_LOG); Debug=0 in the ini stops it"); }
		const std::string all(s);
		std::size_t p = 0;
		int n = 0;
		while (p < all.size() && n < 40) {
			std::size_t e = all.find('\n', p);
			if (e == std::string::npos) e = all.size();
			const std::string line = all.substr(p, std::min<std::size_t>(e - p, 600));
			if (!line.empty()) { REX::INFO("comms msg: {}", line); n++; }
			p = e + 1;
		}
	}
#else
	void RegisterShowHUDMessageSink() {}
	void CommsDbgPoll(ULONGLONG) {}
	void CommsRxPoll(ULONGLONG) {}
#endif

	void Poll()
	{
		auto now = GetTickCount64();
		BannerPoll(now);   // v0.40.3
		CommsDbgPoll(now);   // v0.42.0.6: empty when HZ_COMMS_MSG_LOG is 0
		CommsRxPoll(now);    // v0.42.0.7: reaction backup. Before the HUD-ready return below.
		HWND wnd = GameWindow();
		bool down = wnd && (GetAsyncKeyState(g_vk) & 0x8000) != 0;
		if (down && !g_wasDown) OnSettingsKey();
		g_wasDown = down;

		if (!HudSafe()) {
			if (HudSafe(false)) {   // v0.42.0 r3: only a scope is up: F11 stays blocked, the HUD-ready time is kept
				if (g_open) ResetSettingsState();
				return;
			}
			if (g_hudSince) { REX::INFO("HUD not ready (loading/menu)"); ResetSettingsState(); }
			g_hudSince = 0;
			g_hudReadyLogged = false;
			return;
		}
		// v0.42.0: the hand scanner opened while the F11 window / ARRANGE is up: close it once (close-only, as for the
		// full-screen menus). Edge-triggered, so it runs once per scanner open; nothing happens while F11 is closed.
		{
			auto ui42 = RE::UI::GetSingleton();
			const bool scan42 = ui42 && ui42->IsMenuOpen("MonocleMenu");
			if (scan42 && !g_scanWas42 && g_open) { REX::INFO("settings closed (hand scanner opened)"); ResetSettingsState(); }
			g_scanWas42 = scan42;
		}
		if (!g_hudSince) g_hudSince = now;
		if (now - g_hudSince < 3000) return;
		if (!g_hudReadyLogged) { REX::INFO("HUD ready (stable 3s)"); g_hudReadyLogged = true; HudOwnerCheck(); }
		BuildLog(now);   // v0.42.0 r3
		EnsureSubclass(wnd);
		PollSettings(wnd, now);
	}

	void OnMessage(SFSE::MessagingInterface::Message* a_msg)
	{
		if (a_msg->type == SFSE::MessagingInterface::kPostDataLoad) {
			// The only registration. A missing address id 86800 still hard-exits in GetEventSource.
			// RegisterSink is address id 123821.
			// SEH does not catch that lookup. A null source or a caught fault is logged, and the game continues.
			RegisterShowHUDMessageSink();
			LoadIni();
			if (auto task = SFSE::GetTaskInterface()) {
				task->AddPermanentTask([]() { Poll(); });
				REX::INFO("hotkey poller registered");
			} else {
				REX::ERROR("no TaskInterface");
			}
		}
	}
}

SFSE_PLUGIN_PRELOAD(const SFSE::PreLoadInterface* a_sfse)
{
	SFSE::Init(a_sfse);
	return true;
}

SFSE_PLUGIN_LOAD(const SFSE::LoadInterface* a_sfse)
{
	SFSE::Init(a_sfse);
	// Same string as "movie builds": the version resource produced from src/hz_version.h.
	REX::INFO("HorizonUI {} loaded", HZ::DllFileVersion());
	HZ::FilesStartup();   // v0.37: update backup, migration / preset seeding - before any menu reads the settings
	if (auto msg = SFSE::GetMessagingInterface())
		msg->RegisterListener(HZ::OnMessage);
	return true;
}
