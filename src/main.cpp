// HorizonUI SFSE plugin v0.42.0 - drop-in src\main.cpp (CommonLibSF libxse 9d090c4)
// v0.42.0.4: F11 lists each shipped preset name once. Saved presets are never hidden.
// Same settings keep the installer copy; different settings keep the newer shipped file.
// The F11 header, the load line, and the "movie builds" line use the DLL file version (src/hz_version.h, also the version resource).
// v0.42.0.6: ShowHUDMessageEvent (address id 86800) feeds the reaction backup. The verbose trace
// (the "hud message:" line and "comms msg:" lines) is compiled only when HZ_COMMS_MSG_LOG is 1
// (src/hz_version.h). The queue, Poll, hzcCardPush, the one-line "comms reaction:" status, and the
// one-time "comms reaction selftest:" lines stay on when that flag is 0. HZ_HUD_MSG_CAPTURE logs
// every HUD message with no text filter. The release checklist in README.md turns both traces off.
// The settings schema stays 0.42.0. hzcRxPush remains on the movie. The DLL calls hzcCardPush.
// Saved preset names drop the same characters as the HUD: '=' '+' '[' ']' ';' '#' '"' '\' '|' and control characters.
// v0.42.0 r3 (file version 0.42.0.3): a scope (ScopeMenu) still blocks F11 but no longer restarts the 3 s "HUD ready" wait,
// so F11 works right after leaving the scope. The 0.42.0.4 no-debug build compiled this log out. In 0.42.0.6 it is on
// when HZ_COMMS_MSG_LOG is 1 (Debug=0 in the ini still stops the movie queue): every 500 ms hzcTakeDbg goes to the log as
// "comms msg:" lines. The reaction backup is separate and stays compiled. "movie builds:" logs
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
#include <Xinput.h>
#include <ShlObj.h>
#pragma comment(lib, "version.lib")
#pragma comment(lib, "shell32.lib")
#pragma comment(lib, "ole32.lib")
#undef GetObject
#undef ERROR
#undef PostMessage
#undef SendMessage
#include <cctype>
#include <cstdlib>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <atomic>
#include <mutex>
#include <deque>
#include <vector>
#include <string>
#include <string_view>
#include <cstdio>
#include <exception>
#include <algorithm>
#include <cmath>
#include <ctime>
#include <utility>
#include <map>
#include <iterator>
#include <thread>
#include <condition_variable>
#include <chrono>
#include <memory>
#include "hz_version.h"
#include "hz_msg_match.h"
#include "hz_addr_probe.h"
#include "hz_rx_queue.h"
#include "hz_msglog.h"
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
	bool          g_iniDebug = false;   // [Debug] Debug=1. Gates the one-time hud form, gmst, address, and hold-breath lines.

	std::filesystem::path IniPath()
	{
		wchar_t exe[MAX_PATH]{};
		GetModuleFileNameW(nullptr, exe, MAX_PATH);
		return std::filesystem::path(exe).parent_path() / "Data" / "Interface" / "HorizonUI" / "HorizonUI.ini";
	}
	// v0.37: the folder (HorizonUI.ini above is the legacy file: read for migration only, never written)
	std::filesystem::path HzDir() { return IniPath().parent_path(); }
}

// ==== HZF BEGIN: v0.37 settings files (plain std + one Win32 call through HzfReplace; unit-tested on the box) ====
// Data\Interface\HorizonUI\:
//   HorizonUI.default.ini   shipped, replaced by every update, never written here
//   HorizonUI.user.ini      the player's settings: only what differs from the defaults (+ keys the file already had)
//   HorizonUI.user.bak.ini  copy of user.ini made once per update (state.ini LastVersion != this DLL)
//   HorizonUI.user.preapply.ini  user.ini as it was before the last preset was applied (one-step undo)
//   HorizonUI.state.ini     [State] LastVersion / LegacyImported / PresetSeeded
//   HorizonUI.ini           legacy (v0.36 and older): read for migration only, never written, never deleted
//   presets\*.ini           shipped presets (moragars_choice.ini from the installer); presets\user\*.ini saved in game
// HZF lives at file scope (not inside namespace HZ). hz_ini_diff.h is self-contained.
namespace HZF
{
	inline const char* kVersion = "0.42.0";
}

#include "hz_ini_diff.h"

namespace HZF
	{
		using LogFn = void (*)(int, const std::string&);   // 0 info, 1 warn
		inline LogFn g_log = nullptr;
		inline void Log(int a_lvl, const std::string& a_s) { if (g_log) g_log(a_lvl, a_s); }

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

namespace HZ
{
	HZF::Paths FilesP() { return HZF::MakePaths(HzDir()); }

	void MsglogLoadSettings(const HZF::Doc& a_d);
	void MsglogEnsureInit();

	void LoadIni()
	{
		std::string key = "F11";
		g_iniDebug = false;
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
			if (get("debug", v) && v == "1") g_iniDebug = true;
			if (get("settingskey", v) && !v.empty()) key = v;
			MsglogLoadSettings(d);
		}
		MsglogEnsureInit();
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
		} else if (a_vk == VK_OEM_2) {
			return shift ? std::string("ch:?") : std::string("ch:/");   // 0.43.0.1: Find is keyboard-only
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
		// 0.43.0.1: close every F11 layer in one call. The older toggle-twice loop
		// left a deeper stack (log / settings / confirm) stuck and could freeze input.
		const bool closed = HudInvoke("hzSettingsCloseAll", nullptr, nullptr, 0, true);
		if (!closed) {
			// Older or overridden HUD gfx: the 0.42 toggle-twice path.
			for (int attempt = 0; attempt < 2; ++attempt) {
				GValue open;
				if (!(HudInvoke("hzSettingsOpen", &open) && open.IsBoolean() && open.GetBoolean()))
					break;
				HudInvoke("hzToggleSettings", nullptr, nullptr, 0, true);
			}
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

	// Purpose: the reaction backup is always compiled. HZ_COMMS_MSG_LOG gates only the verbose trace
	// (the "hud message:" line on the task thread, and CommsDbgPoll). The one-line status stays.
	// HZ_HUD_MSG_CAPTURE is a separate switch for the unfiltered "hud capture:" line.
	// Last modified: 2026-10-23.
#ifndef HZ_COMMS_MSG_LOG
#define HZ_COMMS_MSG_LOG 0
#endif

	// Purpose: read one ShowHUDMessageEvent without letting a bad pointer escape this function.
	// Inputs: the event. Outputs: 1 and a filled snap, or 0 when the read faulted.
	// Dependencies: RE::ShowHUDMessageEvent (text, sound, canThrottle, isWarning). The copy is bounded.
	// Last modified: 2026-10-22.
	struct HudMsgSnap
	{
		bool throttle;
		bool warning;
		char text[201];
		char sound[97];
	};

	static void HzCopyRaw(char* a_dst, std::size_t a_cap, const char* a_src)
	{
		hzpreset::CopyHudText(a_dst, a_cap, a_src);
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
		// Purpose: copy one HUD message and return. No settings, no forms, no Scaleform.
		// Inputs: the event (text, sound, canThrottle, isWarning). Outputs: kContinue. A bad event is skipped.
		// The unfiltered "hud capture:" line is HZ_HUD_MSG_CAPTURE. Classification happens on the task thread.
		// Dependencies: HzHudMsgReadSEH. Last modified: 2026-10-23.
		RE::BSEventNotifyControl ProcessEvent(const RE::ShowHUDMessageEvent& a_event, RE::BSTEventSource<RE::ShowHUDMessageEvent>*) override
		{
			try {
				HudMsgSnap snap{};
				if (!HzHudMsgReadSEH(&a_event, &snap)) {
					if (!g_hudMsgReadWarned.exchange(true, std::memory_order_relaxed))
						REX::WARN("ShowHUDMessageEvent sink failed: message could not be read");
					return RE::BSEventNotifyControl::kContinue;
				}
#if HZ_HUD_MSG_CAPTURE
				REX::INFO("hud capture: text=\"{}\" sound=\"{}\" canThrottle={} isWarning={}",
					snap.text, snap.sound, snap.throttle ? 1 : 0, snap.warning ? 1 : 0);
#endif
				// This thread is not the UI thread. Copy the text and return. Poll classifies and invokes Scaleform.
				HzRxEnqueue(snap.text);
			} catch (const std::exception& ex) {
				if (!g_hudMsgReadWarned.exchange(true, std::memory_order_relaxed))
					REX::WARN("ShowHUDMessageEvent sink failed: {}", ex.what());
			} catch (...) {
				if (!g_hudMsgReadWarned.exchange(true, std::memory_order_relaxed))
					REX::WARN("ShowHUDMessageEvent sink failed: unknown error");
			}
			return RE::BSEventNotifyControl::kContinue;
		}

		std::atomic<bool> g_hudMsgReadWarned{false};
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

	// The sink thread only pushes. The timestamp is the enqueue time. Poll drops a note older than kRxMaxAge.
	constexpr std::size_t kRxQueueMax = 8;
	constexpr ULONGLONG kRxMaxAge = 3000;
	struct RxNote
	{
		char      text[201];
		ULONGLONG tick;
	};
	std::mutex        g_rxMu;
	std::deque<RxNote> g_rxQ;

	void MsglogEnqueueHud(const char* a_text);

	void HzRxEnqueue(const char* a_text)
	{
		if (!a_text || !a_text[0]) return;
		try {
			std::lock_guard<std::mutex> lock(g_rxMu);
			// 0.42.0.9: empty, duplicate, and over-cap notes are dropped in hzrx::Enqueue. The cap stays 8.
			hzrx::Enqueue(g_rxQ, a_text, GetTickCount64(), kRxQueueMax);
		} catch (...) {
		}
		MsglogEnqueueHud(a_text);
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
	bool      g_rxSelfLogged = false;
	bool      g_hzpClipLogged = false;
	ULONGLONG g_hzpClipNext = 0;
	bool      g_hzCardWarned = false;
	bool      g_msgGmstDone = false;
	bool      g_msgGmstWait = false;
	bool      g_msgFormDone = false;
	hzmsg::Templates g_msgPhrases = hzmsg::English();

	// Starfield.esm message form ids. Lookup confirms the form loaded. The description is only a string id,
	// so the matcher keeps the English text from the 0.42.0.9 research note.
	constexpr std::uint32_t kHzMsgForms[] = {
		0x002F443D, 0x002F443E, 0x000295FD, 0x00205AA3, 0x002EDFF6, 0x002F4434, 0x00236F3C,
		0x002A6C4D, 0x002A6C4E, 0x0000D8A3, 0x002A6C4C, 0x002A6C4F, 0x002A6C51, 0x002A6C50, 0x002A6C52,
		0x002BFDCA, 0x0027072C, 0x0027072E, 0x0027072D, 0x002BCB8C, 0x002BCB8D, 0x002BCB8E,
		0x002C8FF6, 0x002C8FF7, 0x002C8FF5, 0x000C6587
	};

	struct HzGmstRaw
	{
		char likes[161];
		char loves[161];
		char dislikes[161];
		char hates[161];
		char busy[161];
		char calmed[161];
		char creature[161];
		char caught[161];
		char pick[161];
		char stealTake[161];
		char stealAttack[161];
		char lockCaught[161];
		char trespass[161];
		char witness[161];
		char addCrime[161];
		char remCrime[161];
		char added[161];
		char removed[161];
		int  ok;
		std::uint64_t miss;
	};

	// The versionlib image, read once. A slot of 0, a short file, or anything other than v5
	// means that id is not called. IDDB::offset would end the process, and SEH cannot catch that.
	static int g_addrState = 0;
	static std::vector<unsigned char> g_addrBytes;
	static std::string g_addrWhy;

	static void HzAddrLoad() noexcept
	{
		if (g_addrState != 0) return;
		g_addrState = -1;
		try {
			const auto ver = REX::FModule::GetExecutingModule().GetFileVersion().wstring(L"-");
			if (ver.empty()) {
				g_addrWhy = "game version could not be read";
				return;
			}
			for (wchar_t c : ver) {
				if (!((c >= L'0' && c <= L'9') || c == L'-')) {
					g_addrWhy = "game version could not be read";
					return;
				}
			}
			HMODULE mod = nullptr;
			if (!::GetModuleHandleExW(GET_MODULE_HANDLE_EX_FLAG_FROM_ADDRESS | GET_MODULE_HANDLE_EX_FLAG_UNCHANGED_REFCOUNT,
			        reinterpret_cast<LPCWSTR>(&HzAddrLoad), &mod) || !mod) {
				g_addrWhy = "plugin path could not be read";
				return;
			}
			wchar_t path[MAX_PATH]{};
			const DWORD n = ::GetModuleFileNameW(mod, path, MAX_PATH);
			if (n == 0 || n >= MAX_PATH) {
				g_addrWhy = "plugin path could not be read";
				return;
			}
			const auto file = std::filesystem::path(path).parent_path() / (std::wstring(L"versionlib-") + std::wstring(ver) + L".bin");
			std::ifstream in(file, std::ios::binary);
			if (!in) {
				g_addrWhy = "versionlib file was not found";
				return;
			}
			in.seekg(0, std::ios::end);
			const auto end = in.tellg();
			if (end < static_cast<std::streamoff>(hzaddr::kV5HeaderBytes) || end > static_cast<std::streamoff>(32 * 1024 * 1024)) {
				g_addrWhy = "versionlib is not a v5 table";
				return;
			}
			in.seekg(0, std::ios::beg);
			g_addrBytes.resize(static_cast<std::size_t>(end));
			in.read(reinterpret_cast<char*>(g_addrBytes.data()), static_cast<std::streamsize>(end));
			if (!in) {
				g_addrBytes.clear();
				g_addrWhy = "versionlib could not be read";
				return;
			}
			std::uint32_t format = 0;
			std::memcpy(&format, g_addrBytes.data(), sizeof format);
			if (format != 5u) {
				g_addrBytes.clear();
				g_addrWhy = "versionlib is not a v5 table";
				return;
			}
			g_addrState = 1;
			g_addrWhy.clear();
		} catch (...) {
			g_addrBytes.clear();
			g_addrState = -1;
			if (g_addrWhy.empty()) g_addrWhy = "versionlib could not be read";
		}
	}

	static int HzAddrSlot(std::uint64_t a_id)
	{
		HzAddrLoad();
		if (!hzaddr::AddrSlotReady(g_addrState, g_addrBytes.size())) return -1;
		const int slot = hzaddr::V5Slot(g_addrBytes.data(), g_addrBytes.size(), a_id);
		if (slot < 0 && g_addrWhy.empty()) g_addrWhy = "versionlib is not a v5 table";
		return slot;
	}

	static void HzAddrLogOnce()
	{
		static bool once = false;
		if (once || g_addrWhy.empty()) return;
		once = true;
		if (g_iniDebug) REX::INFO("hud address: {}", g_addrWhy);
	}

	static void HzCopySetting(RE::GameSettingCollection* a_col, const char* a_key, char* a_dst, std::size_t a_cap)
	{
		if (!a_dst || a_cap == 0) return;
		a_dst[0] = '\0';
		if (!a_col || !a_key || RE::ID::GameSettingCollection::GetSetting.id() == 0) return;
		auto* setting = a_col->GetSetting(a_key);
		if (!setting || setting->GetType() != RE::Setting::Type::kString) return;
		const auto view = setting->GetString();
		const auto cut = hzpreset::Utf8Prefix(std::string(view), a_cap - 1);
		for (std::size_t i = 0; i < cut.size(); ++i) a_dst[i] = cut[i];
		a_dst[cut.size()] = '\0';
	}

	static void HzGmstFillCall(HzGmstRaw* a_out)
	{
		if (!a_out) return;
		a_out->ok = 0;
		a_out->miss = 0;
		if (RE::ID::GameSettingCollection::Singleton.id() == 0 || RE::ID::GameSettingCollection::GetSetting.id() == 0) {
			a_out->ok = -1;
			return;
		}
		const auto sid = RE::ID::GameSettingCollection::Singleton.id();
		const auto gid = RE::ID::GameSettingCollection::GetSetting.id();
		const int ss = HzAddrSlot(sid);
		const int gs = HzAddrSlot(gid);
		if (ss != 1 || gs != 1) {
			a_out->ok = -2;
			a_out->miss = ss != 1 ? sid : gid;
			return;
		}
		auto* col = RE::GameSettingCollection::GetSingleton();
		if (!col) return;
		HzCopySetting(col, "sAffinityEventLikes", a_out->likes, sizeof a_out->likes);
		HzCopySetting(col, "sAffinityEventLoves", a_out->loves, sizeof a_out->loves);
		HzCopySetting(col, "sAffinityEventDislikes", a_out->dislikes, sizeof a_out->dislikes);
		HzCopySetting(col, "sAffinityEventHates", a_out->hates, sizeof a_out->hates);
		HzCopySetting(col, "sSceneBlockingActorActivation", a_out->busy, sizeof a_out->busy);
		HzCopySetting(col, "sActivateNPCCalmed", a_out->calmed, sizeof a_out->calmed);
		HzCopySetting(col, "sActivateCreatureCalmed", a_out->creature, sizeof a_out->creature);
		HzCopySetting(col, "sNoPickPocketAgain", a_out->caught, sizeof a_out->caught);
		HzCopySetting(col, "sPickpocketFail", a_out->pick, sizeof a_out->pick);
		HzCopySetting(col, "sStealTakeBack", a_out->stealTake, sizeof a_out->stealTake);
		HzCopySetting(col, "sStealAttack", a_out->stealAttack, sizeof a_out->stealAttack);
		HzCopySetting(col, "sLockpickingCaught", a_out->lockCaught, sizeof a_out->lockCaught);
		HzCopySetting(col, "sTrespassing", a_out->trespass, sizeof a_out->trespass);
		HzCopySetting(col, "sWitnessKilled", a_out->witness, sizeof a_out->witness);
		HzCopySetting(col, "sAddCrimeGold", a_out->addCrime, sizeof a_out->addCrime);
		HzCopySetting(col, "sRemoveCrimeGold", a_out->remCrime, sizeof a_out->remCrime);
		HzCopySetting(col, "sAddItemtoInventory", a_out->added, sizeof a_out->added);
		HzCopySetting(col, "sRemoveItemfromInventory", a_out->removed, sizeof a_out->removed);
		a_out->ok = 1;
	}

	struct HzFormRaw
	{
		int loaded[32];
		int n;
		int ok;
		std::uint64_t miss;
		char credits[161];
	};

	static void HzFormFillCall(HzFormRaw* a_out)
	{
		if (!a_out) return;
		a_out->n = static_cast<int>(std::size(kHzMsgForms));
		a_out->ok = 0;
		a_out->miss = 0;
		a_out->credits[0] = '\0';
		if (RE::ID::TESForm::LookupByID.id() == 0) {
			a_out->ok = -1;
			return;
		}
		const auto lid = RE::ID::TESForm::LookupByID.id();
		if (HzAddrSlot(lid) != 1) {
			a_out->ok = -2;
			a_out->miss = lid;
			return;
		}
		for (int i = 0; i < a_out->n && i < 32; ++i) {
			const auto id = kHzMsgForms[i];
			if (id == 0) { a_out->loaded[i] = -1; continue; }
			auto* form = RE::TESForm::LookupByID(id);
			a_out->loaded[i] = form ? 1 : 0;
		}
		// Credits is MISC 0000000F. Same guarded LookupByID as the message-form audit.
		// The full name is copied into a fixed buffer; a miss keeps the English fallback.
		if (auto* credits = RE::TESForm::LookupByID(0x0000000F)) {
			if (credits->IsCredits()) {
				if (auto* misc = credits->As<RE::TESObjectMISC>()) {
					const char* name = misc->GetFullName();
					if (name && name[0]) {
						const auto cut = hzpreset::Utf8Prefix(std::string(name), sizeof a_out->credits - 1);
						for (std::size_t i = 0; i < cut.size(); ++i) a_out->credits[i] = cut[i];
						a_out->credits[cut.size()] = '\0';
					}
				}
			}
		}
		a_out->ok = 1;
	}

#if defined(_MSC_VER)
	static int HzGmstFillSEH(HzGmstRaw* a_out) noexcept
	{
		if (!a_out) return 0;
		using Fn = void (*)(HzGmstRaw*);
		Fn fn = &HzGmstFillCall;
		__try {
			fn(a_out);
			return 1;
		} __except (EXCEPTION_EXECUTE_HANDLER) {
			return 0;
		}
	}
	static int HzFormFillSEH(HzFormRaw* a_out) noexcept
	{
		if (!a_out) return 0;
		using Fn = void (*)(HzFormRaw*);
		Fn fn = &HzFormFillCall;
		__try {
			fn(a_out);
			return 1;
		} __except (EXCEPTION_EXECUTE_HANDLER) {
			return 0;
		}
	}
#else
	static int HzGmstFillSEH(HzGmstRaw* a_out) noexcept
	{
		if (!a_out) return 0;
		try { HzGmstFillCall(a_out); return 1; } catch (...) { return 0; }
	}
	static int HzFormFillSEH(HzFormRaw* a_out) noexcept
	{
		if (!a_out) return 0;
		try { HzFormFillCall(a_out); return 1; } catch (...) { return 0; }
	}
#endif

	// Purpose: location, player name, currentPlayerID, and Calendar. ID-gated
	// (63412 / 883588 / 937673 / PlayerCharacter singleton) then the same
	// __try/SEH pattern as the HUD-message and GMST readers.
	// Inputs: output buffer. Outputs: ok=1 on a completed walk.
	// Dependencies: HzAddrSlot. Last modified: 2026-10-25.
	struct HzMlEngineRaw
	{
		int           ok;
		std::uint64_t miss;
		char          loc[65];
		char          name[129];
		std::uint64_t playerId;
		double        gt;
	};

	static void HzMlEngineFillCall(HzMlEngineRaw* a_out)
	{
		if (!a_out) return;
		a_out->ok = 0;
		a_out->miss = 0;
		a_out->loc[0] = '\0';
		a_out->name[0] = '\0';
		a_out->playerId = 0;
		a_out->gt = 0;
		const auto locId = RE::ID::TESObjectREFR::GetCurrentLocation.id();
		const auto slmId = RE::ID::BGSSaveLoadManager::Singleton.id();
		const auto calId = RE::ID::Calendar::Singleton.id();
		const auto pcId = RE::ID::PlayerCharacter::Singleton.id();
		if (locId == 0 || slmId == 0 || calId == 0 || pcId == 0) {
			a_out->ok = -1;
			a_out->miss = hzaddr::EngineZeroMiss(locId, slmId, calId, pcId);
			return;
		}
		if (HzAddrSlot(locId) != 1) { a_out->ok = -2; a_out->miss = locId; return; }
		if (HzAddrSlot(slmId) != 1) { a_out->ok = -2; a_out->miss = slmId; return; }
		if (HzAddrSlot(calId) != 1) { a_out->ok = -2; a_out->miss = calId; return; }
		if (HzAddrSlot(pcId) != 1) { a_out->ok = -2; a_out->miss = pcId; return; }
		if (auto pc = RE::PlayerCharacter::GetSingleton()) {
			if (auto loc = pc->GetCurrentLocation(); loc) {
				if (const char* n = loc->GetFullName(); n && n[0])
					HzCopyRaw(a_out->loc, sizeof a_out->loc, n);
			}
			if (const char* n = pc->GetDisplayFullName(); n && n[0])
				HzCopyRaw(a_out->name, sizeof a_out->name, n);
		}
		if (auto mgr = RE::BGSSaveLoadManager::GetSingleton())
			a_out->playerId = mgr->currentPlayerID;
		if (auto cal = RE::Calendar::GetSingleton())
			a_out->gt = cal->GetDaysPassedExact();
		a_out->ok = 1;
	}

#if defined(_MSC_VER)
	static int HzMlEngineFillSEH(HzMlEngineRaw* a_out) noexcept
	{
		if (!a_out) return 0;
		using Fn = void (*)(HzMlEngineRaw*);
		Fn fn = &HzMlEngineFillCall;
		__try {
			fn(a_out);
			return 1;
		} __except (EXCEPTION_EXECUTE_HANDLER) {
			return 0;
		}
	}
#else
	static int HzMlEngineFillSEH(HzMlEngineRaw* a_out) noexcept
	{
		if (!a_out) return 0;
		try { HzMlEngineFillCall(a_out); return 1; } catch (...) { return 0; }
	}
#endif

	static void HzLogPhrase(const char* a_key, const char* a_text)
	{
		const char* status = "empty";
		if (a_text && a_text[0]) status = (a_text[0] == '<' && (a_text[1] == 'I' || a_text[1] == 'i')) ? "stub" : "text";
		char show[61] = {};
		if (a_text) hzpreset::CopyHudText(show, sizeof show, a_text);
		if (g_iniDebug) REX::INFO("hud gmst {}: {} \"{}\"", a_key, status, show);
	}

	// Purpose: read the localized GMST phrases once, on the task thread, after data has loaded.
	// A zero address id is not called. An id that is not in the loaded v5 address library is not called either.
	// An empty phrase or an "<ID=" stub keeps the English fallback. The reads still run when Debug=0.
	// The one-time hud form, hud gmst, and hud address lines are logged only when Debug=1.
	// The versionlib image stays loaded so later HzAddrSlot lookups
	// (message-log engine walk) still resolve. Reloading would be file I/O
	// on the game thread.
	// Last modified: 2026-10-26.
	void HzMsgPrepare()
	{
		if (!g_msgGmstDone) {
			HzGmstRaw raw{};
			const int ran = HzGmstFillSEH(&raw);
			if (!ran) {
				g_msgGmstDone = true;
				if (g_iniDebug) REX::INFO("hud gmst: read failed, English fallback");
			} else if (raw.ok == -2) {
				g_msgGmstDone = true;
				HzAddrLogOnce();
				if (g_iniDebug) REX::INFO("hud gmst: address id {} does not resolve, English fallback", raw.miss);
			} else if (raw.ok < 0) {
				g_msgGmstDone = true;
				if (g_iniDebug) REX::INFO("hud gmst: address id is 0, English fallback");
			} else if (raw.ok == 0) {
				if (!g_msgGmstWait) {
					g_msgGmstWait = true;
					if (g_iniDebug) REX::INFO("hud gmst: settings not ready");
				}
			} else {
				hzmsg::ApplyPhrase(g_msgPhrases.likes, raw.likes);
				hzmsg::ApplyPhrase(g_msgPhrases.loves, raw.loves);
				hzmsg::ApplyPhrase(g_msgPhrases.dislikes, raw.dislikes);
				hzmsg::ApplyPhrase(g_msgPhrases.hates, raw.hates);
				hzmsg::ApplyPhrase(g_msgPhrases.busy, raw.busy);
				hzmsg::ApplyPhrase(g_msgPhrases.npcCalmed, raw.calmed);
				hzmsg::ApplyPhrase(g_msgPhrases.creature, raw.creature);
				hzmsg::ApplyPhrase(g_msgPhrases.caught, raw.caught);
				hzmsg::ApplyPhrase(g_msgPhrases.pickFail, raw.pick);
				hzmsg::ApplyPhrase(g_msgPhrases.stealTake, raw.stealTake);
				hzmsg::ApplyPhrase(g_msgPhrases.stealAttack, raw.stealAttack);
				hzmsg::ApplyPhrase(g_msgPhrases.lockCaught, raw.lockCaught);
				hzmsg::ApplyPhrase(g_msgPhrases.trespass, raw.trespass);
				hzmsg::ApplyPhrase(g_msgPhrases.witness, raw.witness);
				hzmsg::ApplyPhrase(g_msgPhrases.addCrime, raw.addCrime);
				hzmsg::ApplyPhrase(g_msgPhrases.remCrime, raw.remCrime);
				hzmsg::ApplyPhrase(g_msgPhrases.added, raw.added);
				hzmsg::ApplyPhrase(g_msgPhrases.removed, raw.removed);
				HzLogPhrase("sAffinityEventLikes", raw.likes);
				HzLogPhrase("sAffinityEventLoves", raw.loves);
				HzLogPhrase("sAffinityEventDislikes", raw.dislikes);
				HzLogPhrase("sAffinityEventHates", raw.hates);
				HzLogPhrase("sSceneBlockingActorActivation", raw.busy);
				HzLogPhrase("sActivateNPCCalmed", raw.calmed);
				HzLogPhrase("sActivateCreatureCalmed", raw.creature);
				HzLogPhrase("sNoPickPocketAgain", raw.caught);
				HzLogPhrase("sPickpocketFail", raw.pick);
				HzLogPhrase("sStealTakeBack", raw.stealTake);
				HzLogPhrase("sStealAttack", raw.stealAttack);
				HzLogPhrase("sLockpickingCaught", raw.lockCaught);
				HzLogPhrase("sTrespassing", raw.trespass);
				HzLogPhrase("sWitnessKilled", raw.witness);
				HzLogPhrase("sAddCrimeGold", raw.addCrime);
				HzLogPhrase("sRemoveCrimeGold", raw.remCrime);
				HzLogPhrase("sAddItemtoInventory", raw.added);
				HzLogPhrase("sRemoveItemfromInventory", raw.removed);
				g_msgGmstDone = true;
			}
		}
		if (!g_msgFormDone) {
			HzFormRaw raw{};
			const int ran = HzFormFillSEH(&raw);
			if (!ran) {
				g_msgFormDone = true;
				if (g_iniDebug) REX::INFO("hud form: read failed");
			} else if (raw.ok == -2) {
				g_msgFormDone = true;
				HzAddrLogOnce();
				if (g_iniDebug) REX::INFO("hud form: address id {} does not resolve", raw.miss);
			} else if (raw.ok < 0) {
				g_msgFormDone = true;
				if (g_iniDebug) REX::INFO("hud form: address id is 0");
			} else if (raw.ok > 0) {
				for (int i = 0; i < raw.n && i < 32; ++i) {
					const char* state = raw.loaded[i] < 0 ? "skipped" : (raw.loaded[i] ? "loaded" : "missing");
					if (g_iniDebug) REX::INFO("hud form {:08X}: {}", kHzMsgForms[i], state);
				}
				hzmsg::ApplyPhrase(g_msgPhrases.creditsName, raw.credits);
				if (g_iniDebug) {
					const char* state = raw.credits[0] ? "loaded" : "missing";
					REX::INFO("hud form {:08X}: {} credits name", 0x0000000Fu, state);
					HzLogPhrase("Credits", raw.credits);
				}
				g_msgFormDone = true;
			}
		}
	}

	static std::string HzCrossName()
	{
		try {
			auto ui = RE::UI::GetSingleton();
			if (!ui) return {};
			auto menu = ui->GetMenu("HUDMenu");
			if (!menu || !menu->menuObj.IsObject() || !menu->menuObj.HasMember("hzCrossName")) return {};
			GValue r;
			if (!menu->menuObj.Invoke("hzCrossName", &r, nullptr, 0) || !r.IsString() || !r.GetString()) return {};
			const auto view = hzmsg::Trim(r.GetString());
			if (view.empty() || view.find('<') != std::string_view::npos) return {};
			return hzpreset::Utf8Prefix(std::string(view), 80);
		} catch (...) {
			return {};
		}
	}

	// Purpose: drain the HUD-message queue on the UI thread and log hzcCardPush's status once per card.
	// Also logs hzcRxSelfTest once (pass or fail, plus the three regex probes). That line is not gated on
	// Debug or HZ_COMMS_MSG_LOG. A missing hzcRxSelfTest is retried until it returns a non-empty string.
	// Skips loading and the main menu. Not gated on the 3 s HUD-ready wait. A missing hzcCardPush is logged once.
	// Last modified: 2026-10-23.
	void CommsRxPoll(ULONGLONG a_now)
	{
		auto ui = RE::UI::GetSingleton();
		if (!ui) return;
		for (auto m : { "LoadingMenu", "MainMenu" })
			if (ui->IsMenuOpen(m)) return;
		if (!ui->IsMenuOpen("HUDMessagesMenu")) return;
		auto msg = ui->GetMenu("HUDMessagesMenu");
		if (!msg || !msg->menuObj.IsObject()) return;
		try { HzMsgPrepare(); } catch (...) {}
		if (!g_rxSelfLogged && msg->menuObj.HasMember("hzcRxSelfTest")) {
			try {
				GValue self;
				if (msg->menuObj.Invoke("hzcRxSelfTest", &self, nullptr, 0) && self.IsString() && self.GetString() && self.GetString()[0]) {
					const std::string all = self.GetString();
					std::size_t i = 0;
					while (i < all.size()) {
						const auto j = all.find('\n', i);
						std::string line = all.substr(i, j == std::string::npos ? std::string::npos : j - i);
						if (!line.empty() && line.back() == '\r') line.pop_back();
						if (!line.empty())
							REX::INFO("comms reaction selftest: {}", line);
						if (j == std::string::npos) break;
						i = j + 1;
					}
					g_rxSelfLogged = true;
				}
			} catch (...) {
			}
		}
		try {
			if (a_now >= g_rxWhyNext && msg->menuObj.HasMember("hzcRxWhy")) {
				g_rxWhyNext = a_now + 500;
				GValue why;
				if (msg->menuObj.Invoke("hzcRxWhy", &why, nullptr, 0) && why.IsString() && why.GetString() && why.GetString()[0])
					REX::INFO("comms reaction: {}", why.GetString());
			}
		} catch (...) {
		}
		if (!msg->menuObj.HasMember("hzcCardPush")) {
			if (!g_hzCardWarned) {
				g_hzCardWarned = true;
				REX::INFO("Horizon messages movie is not active");
			}
			return;
		}
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
			if (n.tick == 0 || a_now < n.tick || a_now - n.tick > kRxMaxAge) continue;
			hzmsg::Hit hit;
			try { hit = hzmsg::Match(n.text, g_msgPhrases); } catch (...) { hit = {}; }
			if (!hit.ok) continue;
			if (hit.kind == "unavailable" && hit.sub == "busy" && hit.name.empty()) {
				const auto who = HzCrossName();
				if (!who.empty()) hit.name = who;
			}
			if (g_iniDebug && hit.kind == "crew")
				REX::INFO("crew card: path=dll-match sub={} name=\"{}\" text=\"{}\"", hit.sub, hit.name, n.text);
			std::string status = "invoke failed";
			try {
				const std::string kind = hit.kind;
				const std::string sub = hit.sub;
				const std::string name = hit.name;
				const std::string value = hit.value;
				GValue args[5] = {
					GValue(kind.c_str()),
					GValue(sub.c_str()),
					GValue(name.c_str()),
					GValue(value.c_str()),
					GValue(n.text)
				};
				GValue ret;
				if (msg->menuObj.Invoke("hzcCardPush", &ret, args, 5) && ret.IsString() && ret.GetString())
					status = ret.GetString();
			} catch (...) {
				status = "invoke failed";
			}
#if HZ_COMMS_MSG_LOG
			REX::INFO("hud message: text=\"{}\" kind={} sub={} tier={}", n.text, hit.kind, hit.sub, hit.tier);
#endif
			REX::INFO("comms reaction: {} | messages visible={} | dialogue={}", status, visTx, dialogue ? 1 : 0);
		}
	}

#if HZ_COMMS_MSG_LOG
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
	void CommsDbgPoll(ULONGLONG) {}
#endif

	// Purpose: log the hold-breath clip geometry once per session, the first time HOLDING BREATH is on screen.
	// The movie fills hzpClipDiag. Debug=0 returns before any menu lookup and does not latch, so turning
	// Debug on later still logs once. This is not behind HZ_COMMS_MSG_LOG. A missing member is retried.
	// An empty string means that state has not been shown yet, so the latch stays open.
	// The menu check runs at most every 500 ms while the scope is open.
	// Last modified: 2026-10-23.
	void ScopeClipPoll(ULONGLONG a_now)
	{
		if (!g_iniDebug) return;
		if (g_hzpClipLogged) return;
		if (a_now < g_hzpClipNext) return;
		g_hzpClipNext = a_now + 500;
		auto ui = RE::UI::GetSingleton();
		if (!ui || !ui->IsMenuOpen("ScopeMenu")) return;
		auto menu = ui->GetMenu("ScopeMenu");
		if (!menu || !menu->menuObj.IsObject() || !menu->menuObj.HasMember("hzpClipDiag")) return;
		try {
			GValue self;
			if (menu->menuObj.Invoke("hzpClipDiag", &self, nullptr, 0) && self.IsString() && self.GetString() && self.GetString()[0]) {
				const std::string all = self.GetString();
				std::size_t i = 0;
				while (i < all.size()) {
					const auto j = all.find('\n', i);
					std::string line = all.substr(i, j == std::string::npos ? std::string::npos : j - i);
					if (!line.empty() && line.back() == '\r') line.pop_back();
					if (!line.empty() && g_iniDebug)
						REX::INFO("scope holdbreath diag: {}", line);
					if (j == std::string::npos) break;
					i = j + 1;
				}
				g_hzpClipLogged = true;
			}
		} catch (...) {
		}
	}

	// ---------------- 0.43.0.1 Message Log P1: capture + storage (no log UI) ----------------
	// F11 still opens from the keyboard only. Pad input is applied only while F11 is already open.
	hzlog::Log              g_ml;
	std::mutex              g_mlMu;  // buf, replace, horizonDir, persist copies
	std::mutex              g_mlQMu;
	struct MlNote
	{
		char      text[257];
		char      title[65];
		char      src; // H = HUD sink, Q/L/X = movie
		ULONGLONG tick;
	};
	std::deque<MlNote>      g_mlQ;
	std::mutex              g_mlWMu;
	std::condition_variable g_mlWCv;
	std::atomic<bool>       g_mlWStop{false};
	std::atomic<bool>       g_mlWDone{false};
	std::atomic<bool>       g_mlWReq{false};
	std::atomic<bool>       g_mlLoadJobReq{false};
	std::atomic<bool>       g_mlLoadReady{false};
	std::atomic<bool>       g_mlSaveReq{false};
	std::atomic<bool>       g_mlLoadReq{false};
	std::atomic<bool>       g_mlQuitReq{false};
	std::atomic<bool>       g_mlCapture{false};
	std::atomic<bool>       g_mlHadSession{false};
	struct MlWriteJob
	{
		hzlog::LogState         snap;
		std::filesystem::path   dir;
		hzlog::ReplaceFn        replace;
		bool                    persist{false};
		std::string             key;
		std::uint64_t           gen{0};
	};
	struct MlLoadJob
	{
		hzlog::Character        ch;
		std::filesystem::path   dir;
		hzlog::ReplaceFn        replace;
		bool                    persist{false};
		double                  gt{0};
		std::int64_t            ts{0};
		std::uint64_t           gen{0};
		std::string             bufKey;
		bool                    holdFlush{false};
	};
	MlWriteJob              g_mlWJob;
	hzlog::LogState         g_mlWFailSnap;
	std::string             g_mlWFailKey;
	MlLoadJob               g_mlLJob;
	hzlog::LogState         g_mlLResult;
	hzlog::Character        g_mlLCh;
	std::string             g_mlLNotice;
	double                  g_mlLGt{0};
	std::int64_t            g_mlLTs{0};
	bool                    g_mlLOk{true};
	std::uint64_t           g_mlLGen{0};
	std::string             g_mlLBufKey;
	bool                    g_mlLHoldFlush{false};
	std::uint64_t           g_mlLoadGen{0};
	std::uint64_t           g_mlInFlightGen{0};
	std::thread             g_mlWThread;
	std::atomic<bool>       g_mlWLive{false};
	std::atomic<bool>       g_mlWFailed{false};
	std::atomic<bool>       g_mlWRecovered{false};
	std::atomic<ULONGLONG>  g_mlWRetryAt{0};
	std::atomic<bool>       g_mlRecoverBusy{false};
	bool                    g_mlHoldFlush = false;
	bool                    g_mlPendingHud = false;
	bool                    g_mlFailNoted = false;
	int                     g_mlBakFails = 0;
	bool                    g_mlBakBypassLogged = false;
	std::uint64_t           g_mlNameHashSkipMs{0};
	std::atomic<bool>       g_mlShutdownReq{false};
	bool                    g_mlWStarted = false;
	bool                    g_mlAtExit = false;
	bool                    g_mlInited = false;
	bool                    g_mlMarker = false;
	WORD                    g_mlPadLast = 0;
	ULONGLONG               g_mlPadNext[16]{};
	using XInputGetStateFn = DWORD (WINAPI*)(DWORD, XINPUT_STATE*);
	HMODULE                 g_xiMod = nullptr;
	XInputGetStateFn        g_xiGetState = nullptr;
	bool                    g_xiTried = false;
	ULONGLONG               g_xiNext = 0;
	struct MlEngineCache
	{
		std::string   loc;
		std::string   name;
		std::string   body;
		std::uint64_t playerId{0};
		double        gt{0};
		double        ut{-1};
		double        lt{-1};
	};
	MlEngineCache           g_mlEng;

	std::filesystem::path MsglogHorizonDir()
	{
		PWSTR docs = nullptr;
		if (FAILED(::SHGetKnownFolderPath(FOLDERID_Documents, KF_FLAG_DONT_VERIFY, nullptr, &docs)) || !docs)
			return HzDir();
		std::filesystem::path p(docs);
		::CoTaskMemFree(docs);
		return p / L"My Games" / L"Starfield" / L"SFSE" / L"HorizonUI";
	}

	void MsglogAtExit()
	{
		try {
			g_mlWStop.store(true);
			g_mlWCv.notify_all();
			if (!g_mlWThread.joinable()) return;
			if (hzlog::AtExitShouldJoin(g_mlWDone.load())) {
				try { g_mlWThread.join(); } catch (...) {}
			} else {
				try { g_mlWThread.detach(); } catch (...) {}
			}
		} catch (...) {
		}
	}

	void MsglogWriter()
	{
		try {
			for (;;) {
				std::unique_lock lk(g_mlWMu);
				g_mlWCv.wait_for(lk, std::chrono::milliseconds(500), [] {
					return g_mlWStop.load() || g_mlWReq.load() || g_mlLoadJobReq.load();
				});
				const bool stop = g_mlWStop.load();
				const bool wr = g_mlWReq.load();
				const bool ld = g_mlLoadJobReq.load();
				MlWriteJob wjob;
				MlLoadJob ljob;
				if (wr) {
					wjob = std::move(g_mlWJob);
					g_mlWReq.store(false);
				}
				if (ld) {
					ljob = std::move(g_mlLJob);
					g_mlLoadJobReq.store(false);
				}
				lk.unlock();
				if (wr) {
					bool ok = true;
					try {
						if (wjob.persist && hzlog::PersistAllowed(wjob.snap.character)) {
							hzlog::FileStore fs(wjob.dir / "MessageLog", wjob.replace);
							fs.bakFails = g_mlBakFails;
							ok = fs.Save(wjob.snap);
							g_mlBakFails = fs.bakFails;
							if (fs.bakBypassed && !g_mlBakBypassLogged) {
								g_mlBakBypassLogged = true;
								REX::WARN("message log: bak copy failed {} times; wrote the main file", fs.bakFails);
							}
						}
					} catch (...) {
						ok = false;
					}
					bool failed = false;
					hzlog::NoteWorkerSave(ok, failed);
					if (failed) {
						std::lock_guard wlk(g_mlWMu);
						g_mlWFailSnap = std::move(wjob.snap);
						g_mlWFailKey = std::move(wjob.key);
						g_mlWFailed.store(true);
					} else
						g_mlWRecovered.store(true);
				}
				if (ld) {
					const auto jobGen = ljob.gen;
					const auto jobBufKey = ljob.bufKey;
					const bool jobHold = ljob.holdFlush;
					try {
						hzlog::LogState st;
						std::string notice;
						bool ok = true;
						if (ljob.persist && hzlog::PersistAllowed(ljob.ch)) {
							hzlog::FileStore fs(ljob.dir / "MessageLog", ljob.replace);
							ok = fs.Load(ljob.ch.key, st, notice);
						}
						std::lock_guard rlk(g_mlWMu);
						g_mlLResult = std::move(st);
						g_mlLNotice = std::move(notice);
						g_mlLCh = std::move(ljob.ch);
						g_mlLGt = ljob.gt;
						g_mlLTs = ljob.ts;
						g_mlLOk = ok;
						hzlog::CopyLoadJobTag(jobGen, jobBufKey, g_mlLGen, g_mlLBufKey);
						g_mlLHoldFlush = jobHold;
						g_mlLoadReady.store(true);
					} catch (...) {
						std::lock_guard rlk(g_mlWMu);
						g_mlLOk = false;
						hzlog::CopyLoadJobTag(jobGen, jobBufKey, g_mlLGen, g_mlLBufKey);
						g_mlLHoldFlush = jobHold;
						g_mlLoadReady.store(true);
					}
				}
				if (stop && !g_mlWReq.load() && !g_mlLoadJobReq.load()) break;
			}
		} catch (...) {
		}
		{
			std::lock_guard lk(g_mlWMu);
			g_mlWDone.store(true);
			g_mlWLive.store(false);
			g_mlWStarted = false;
		}
		g_mlWCv.notify_all();
	}

	void MsglogEnsureWriter()
	{
		bool persist = false;
		{
			std::lock_guard lk(g_mlMu);
			persist = g_ml.buf.settings.persist;
		}
		if (!hzlog::WriterStartAllowed(g_mlWLive.load(), g_mlWStarted) || !persist) return;
		g_mlWStarted = true;
		g_mlWLive.store(true);
		g_mlWStop.store(false);
		g_mlWDone.store(false);
		try {
			g_mlWThread = std::thread(MsglogWriter);
			if (!g_mlAtExit) {
				g_mlAtExit = true;
				std::atexit(MsglogAtExit);
			}
		} catch (...) {
			g_mlWStarted = false;
			g_mlWLive.store(false);
		}
	}

	// Purpose: snapshot the buffer under g_mlMu, copy dir/replace/persist into
	// the write job, and wake the worker. Does not skip when loadBusy: the
	// snapshot belongs to the character that just left.
	void MsglogRequestWrite(bool a_force)
	{
		try {
			MlWriteJob job;
			{
				std::lock_guard lk(g_mlMu);
				if (!g_ml.buf.settings.persist) return;
				if (g_ml.persistHold) return;
				if (!hzlog::WriteAllowed(g_ml.dirty, a_force, g_ml.lastWriteMs, GetTickCount64(), g_ml.retryBackoffMs))
					return;
				if (!hzlog::PersistAllowed(g_ml.buf.character)) {
					if (hzlog::NoteNameHashSkip(g_ml.buf.character, GetTickCount64(), g_mlNameHashSkipMs))
						REX::WARN("message log: persist skipped; character key is still a name hash");
					return;
				}
				g_ml.buf.lastPlayedTs = static_cast<std::int64_t>(GetTickCount64() / 1000);
				job.snap = g_ml.buf.Snapshot();
				job.key = g_ml.buf.character.key;
				job.gen = g_mlLoadGen;
				job.dir = g_ml.horizonDir;
				job.replace = g_ml.replace;
				job.persist = true;
				g_ml.dirty = false;
				g_ml.writePending = true;
				g_ml.lastWriteMs = GetTickCount64();
			}
			MsglogEnsureWriter();
			{
				std::lock_guard lk(g_mlWMu);
				g_mlWJob = std::move(job);
				g_mlWReq.store(true);
			}
			g_mlWCv.notify_one();
		} catch (...) {
		}
	}

	// Purpose: queue a last write and ask the worker to stop. Does not join:
	// atexit joins only when the worker is already done, so exit cannot hang.
	void MsglogShutdownWriter()
	{
		try {
			MsglogRequestWrite(true);
			g_mlWStop.store(true);
			g_mlWCv.notify_all();
		} catch (...) {
		}
	}

	void MsglogQueueLoad(const hzlog::Character& a_ch, double a_gt, std::int64_t a_ts, bool a_holdFlush = false)
	{
		try {
			MlLoadJob job;
			{
				std::lock_guard lk(g_mlMu);
				job.ch = a_ch;
				job.dir = g_ml.horizonDir;
				job.replace = g_ml.replace;
				job.persist = g_ml.buf.settings.persist;
				job.gt = a_gt;
				job.ts = a_ts;
				job.gen = g_mlLoadGen;
				job.bufKey = g_ml.buf.character.key;
				job.holdFlush = a_holdFlush;
				if (job.persist && hzlog::PersistAllowed(a_ch))
					g_mlInFlightGen = job.gen;
			}
			if (!job.persist || !hzlog::PersistAllowed(a_ch)) {
				g_mlRecoverBusy.store(false);
				return;
			}
			MsglogEnsureWriter();
			{
				std::lock_guard lk(g_mlWMu);
				g_mlLJob = std::move(job);
				g_mlLoadReady.store(false);
				g_mlLoadJobReq.store(true);
			}
			g_mlWCv.notify_one();
		} catch (...) {
		}
	}

	// Purpose: read [MessageLog] from the merged INI. Record, LogTypes, HistorySize,
	// MissedBadge, Persist. P1 keeps capture in this build behind Record.
	// Inputs: parsed settings document. Outputs: g_ml configured. Dependencies: HzfReplace.
	// Author: Moragar. Last modified: 2026-10-25.
	void MsglogLoadSettings(const HZF::Doc& a_d)
	{
		auto getSec = [&](const char* a_sec, const char* a_k, std::string& a_v) {
			for (const auto& sec : a_d.secs) {
				if (sec.name != a_sec) continue;
				if (auto it = sec.kv.find(a_k); it != sec.kv.end()) {
					a_v = it->second.second;
					return true;
				}
			}
			return false;
		};
		hzlog::Settings s;
		std::string v;
		if (getSec("messagelog", "record", v)) s.record = v != "0";
		if (getSec("messagelog", "persist", v)) s.persist = v != "0";
		if (getSec("messagelog", "missedbadge", v)) s.missedBadge = v != "0";
		if (getSec("messagelog", "historysize", v)) {
			try { s.historySize = hzlog::ClampHistory(std::stoi(v)); } catch (...) {}
		}
		if (getSec("messagelog", "logtypes", v)) s.logTypes = hzlog::ParseLogTypes(v);
		std::error_code ec;
		g_mlMarker = std::filesystem::is_regular_file(HzDir() / "modules" / "notifications.marker", ec);
		// P1 ships in this build: Record is the capture gate. The marker is the F11 row flag.
		s.modulePresent = true;
		auto rep = [](const std::filesystem::path& a_tmp, const std::filesystem::path& a_dst) {
			return HzfReplace(a_tmp, a_dst);
		};
		const auto dir = MsglogHorizonDir();
		{
			std::lock_guard lk(g_mlMu);
			g_ml.replace = std::move(rep);
			g_ml.Configure(s, dir);
			g_mlInited = true;
		}
		REX::INFO("message log: Record={} Persist={} HistorySize={} module marker={}",
			s.record ? 1 : 0, s.persist ? 1 : 0, s.historySize, g_mlMarker ? 1 : 0);
	}

	void MsglogEnsureInit()
	{
		if (g_mlInited) return;
		hzlog::Settings s;
		auto rep = [](const std::filesystem::path& a_tmp, const std::filesystem::path& a_dst) {
			return HzfReplace(a_tmp, a_dst);
		};
		const auto dir = MsglogHorizonDir();
		std::lock_guard lk(g_mlMu);
		g_ml.replace = std::move(rep);
		g_ml.Configure(s, dir);
		g_mlInited = true;
	}

	void MsglogEnqueueHud(const char* a_text)
	{
		if (!a_text || !a_text[0] || !g_mlInited) return;
		try {
			MlNote n{};
			hzpreset::CopyHudText(n.text, sizeof n.text, a_text);
			if (!n.text[0]) return;
			n.src = 'H';
			n.tick = GetTickCount64();
			std::lock_guard lock(g_mlQMu);
			if (g_mlQ.size() >= 256) g_mlQ.pop_front();
			g_mlQ.push_back(n);
		} catch (...) {
		}
	}

	void MsglogEnqueueFwd(char a_src, const char* a_title, const char* a_text)
	{
		if (!a_text || !a_text[0]) return;
		try {
			MlNote n{};
			hzpreset::CopyHudText(n.text, sizeof n.text, a_text);
			if (a_title) hzpreset::CopyHudText(n.title, sizeof n.title, a_title);
			n.src = a_src;
			n.tick = GetTickCount64();
			std::lock_guard lock(g_mlQMu);
			if (g_mlQ.size() >= 256) g_mlQ.pop_front();
			g_mlQ.push_back(n);
		} catch (...) {
		}
	}

	void MsglogClock(double& a_ut, double& a_lt, std::string& a_body)
	{
		a_ut = -1;
		a_lt = -1;
		a_body.clear();
		GValue r;
		if (!HudInvoke("hzMsglogClock", &r) || !r.IsString() || !r.GetString()) return;
		const std::string s = r.GetString();
		const auto p1 = s.find('|');
		const auto p2 = p1 == std::string::npos ? std::string::npos : s.find('|', p1 + 1);
		if (p1 == std::string::npos || p2 == std::string::npos) return;
		try { a_ut = std::stod(s.substr(0, p1)); } catch (...) { a_ut = -1; }
		try { a_lt = std::stod(s.substr(p1 + 1, p2 - p1 - 1)); } catch (...) { a_lt = -1; }
		a_body = s.substr(p2 + 1);
	}

	// Purpose: one engine walk per poll while the HUD is up and we are not
	// loading. Never per message, never during menus.
	void MsglogRefreshEngine(bool a_switch)
	{
		if (!a_switch) {
			if (!HudSafe()) return;
			if (g_ml.loadBusy.load()) return;
			if (!g_hudReadyLogged) return;
		}
		HzMlEngineRaw raw{};
		if (!HzMlEngineFillSEH(&raw) || raw.ok != 1) {
			if (raw.ok == -1 || raw.ok == -2) {
				static bool once = false;
				if (!once) {
					once = true;
					REX::WARN("message log: engine address id {} missing from the address library; capture stays memory-only", raw.miss);
				}
			}
			return;
		}
		g_mlEng.loc = raw.loc;
		g_mlEng.name = raw.name;
		g_mlEng.playerId = raw.playerId;
		g_mlEng.gt = raw.gt;
		if (a_switch || (g_mlCapture.load() && HudSafe()))
			MsglogClock(g_mlEng.ut, g_mlEng.lt, g_mlEng.body);
		if (g_mlEng.loc.empty()) g_mlEng.loc = g_mlEng.body;
	}

	void MsglogOfferNote(const MlNote& a_n)
	{
		try {
			if (!g_mlInited) return;
			if (!g_mlCapture.load()) return;
			if (a_n.src == 'H' && hzlog::IsSaveLine(a_n.text)) {
				MsglogRequestWrite(true);
				return;
			}
			hzlog::Capture c;
			c.nowMs = a_n.tick;
			c.ts = static_cast<std::int64_t>(std::time(nullptr));
			c.gt = g_mlEng.gt;
			c.ut = g_mlEng.ut;
			c.lt = g_mlEng.lt;
			c.loc = g_mlEng.loc;
			c.text = a_n.text;
			c.title = a_n.title;
			if (a_n.src == 'H') {
				c.kind = hzlog::ClassifyHud(a_n.text, g_msgPhrases, c.title, c.tag);
			} else if (a_n.src == 'Q') {
				c.kind = hzlog::Kind::Quest;
				if (c.title.empty()) c.title = "QUEST";
			} else if (a_n.src == 'L') {
				c.kind = hzlog::Kind::Location;
				if (c.title.empty()) c.title = "LOCATION";
			} else if (a_n.src == 'X') {
				c.kind = hzlog::Kind::Xp;
				if (c.title.empty()) c.title = "XP";
			} else {
				return;
			}
			hzlog::OfferResult r = hzlog::OfferResult::Rejected;
			{
				std::lock_guard lk(g_mlMu);
				r = g_ml.Offer(std::move(c));
			}
			if (r == hzlog::OfferResult::SaveSignal)
				MsglogRequestWrite(true);
			else if ((r == hzlog::OfferResult::Stored || r == hzlog::OfferResult::Deduped) && g_ml.ShouldFlush(a_n.tick, false))
				MsglogRequestWrite(false);
		} catch (...) {
		}
	}

	void MsglogTakeMovie()
	{
		auto ui = RE::UI::GetSingleton();
		if (!ui || !ui->IsMenuOpen("HUDMessagesMenu")) return;
		auto msg = ui->GetMenu("HUDMessagesMenu");
		if (!msg || !msg->menuObj.IsObject() || !msg->menuObj.HasMember("hzcTakeLog")) return;
		GValue r;
		if (!msg->menuObj.Invoke("hzcTakeLog", &r, nullptr, 0) || !r.IsString()) return;
		const char* s = r.GetString();
		if (!s || !*s) return;
		std::string all(s);
		std::size_t p = 0;
		while (p < all.size()) {
			auto e = all.find('\n', p);
			if (e == std::string::npos) e = all.size();
			const auto line = all.substr(p, e - p);
			p = e + 1;
			hzlog::Kind k;
			std::string title, text;
			if (!hzlog::ParseForward(line, k, title, text)) continue;
			char src = k == hzlog::Kind::Quest ? 'Q' : (k == hzlog::Kind::Location ? 'L' : 'X');
			MsglogEnqueueFwd(src, title.c_str(), text.c_str());
		}
	}

	void MsglogPromoteId()
	{
		try {
			if (!g_mlCapture.load() || g_ml.loadBusy.load()) return;
			if (g_mlRecoverBusy.load()) return;
			if (g_mlEng.playerId == 0) return;
			const auto ch = hzlog::MakeCharacter(g_mlEng.playerId, g_mlEng.name);
			const auto now = GetTickCount64();
			bool queue = false;
			{
				std::lock_guard lk(g_mlMu);
				if (g_ml.buf.character.keySource != "nameHash") return;
				if (!hzlog::PersistAllowed(ch)) return;
				if (!hzlog::HoldRetryDue(g_ml.persistHold, g_ml.retryAt, now)) return;
				g_mlRecoverBusy.store(true);
				queue = true;
			}
			if (queue)
				MsglogQueueLoad(ch, g_mlEng.gt, static_cast<std::int64_t>(std::time(nullptr)));
		} catch (...) {
		}
	}

	void MsglogQueueRecover(bool a_force, bool a_holdFlush = false)
	{
		try {
			if (g_mlRecoverBusy.load() && !a_force) return;
			hzlog::Character ch;
			double gt = 0;
			std::int64_t ts = 0;
			{
				std::lock_guard lk(g_mlMu);
				if (g_mlEng.playerId)
					ch = hzlog::MakeCharacter(g_mlEng.playerId, g_mlEng.name);
				else
					ch = g_ml.buf.character;
				if (!hzlog::PersistAllowed(ch)) return;
				if (!a_force && !hzlog::HoldRetryDue(g_ml.persistHold, g_ml.retryAt, GetTickCount64()))
					return;
				if (a_force)
					g_ml.retryAt = 0;
				gt = g_mlEng.gt;
				ts = static_cast<std::int64_t>(std::time(nullptr));
				g_mlRecoverBusy.store(true);
			}
			MsglogQueueLoad(ch, gt, ts, a_holdFlush);
		} catch (...) {
		}
	}

	void MsglogParkHeldIfNeeded()
	{
		if (!hzlog::ShouldKeepHeldRows(g_ml.persistHold, g_ml.buf.entries.size())
			&& !hzlog::ShouldParkDirtyRows(
				hzlog::PendingCountsAsDirty(g_ml.dirty, g_ml.writePending),
				hzlog::PersistAllowed(g_ml.buf.character), g_ml.buf.entries.size()))
			return;
		REX::WARN("message log: keeping {} held rows for {}", g_ml.buf.entries.size(), g_ml.buf.character.key);
		g_ml.ParkHeldRows();
	}

	void MsglogNotePersistLog(bool a_ok)
	{
		if (!a_ok) {
			if (!g_mlFailNoted) {
				g_mlFailNoted = true;
				REX::WARN("message log: persist failed; retrying with backoff");
			}
			return;
		}
		if (g_mlFailNoted) {
			g_mlFailNoted = false;
			REX::INFO("message log: persist recovered");
		}
	}

	void MsglogOnHudReady()
	{
		try {
			if (!g_mlInited) return;
			MsglogRefreshEngine(true);
			const auto ch = hzlog::MakeCharacter(g_mlEng.playerId, g_mlEng.name);
			const auto ts = static_cast<std::int64_t>(std::time(nullptr));
			const auto now = GetTickCount64();
			const bool afterLoad = g_ml.loadBusy.load();
			bool needLoad = false;
			{
				std::lock_guard lk(g_mlMu);
				if (afterLoad && g_mlRecoverBusy.load()) {
					g_mlPendingHud = true;
					return;
				}
				const bool forceFresh = !hzlog::PersistAllowed(ch);
				if (forceFresh || (afterLoad && !hzlog::PersistAllowed(g_ml.buf.character) && !hzlog::PersistAllowed(ch))) {
					MsglogParkHeldIfNeeded();
					g_mlHoldFlush = false;
					g_ml.NoteRetrySuccess();
					g_ml.buf.ResetMemory();
					g_ml.dirty = false;
					g_ml.buf.character = ch;
					g_ml.lastNotice.clear();
					g_ml.buf.StartSession(ts);
					g_ml.buf.Prune(g_mlEng.gt);
					g_ml.loadBusy.store(false);
					g_mlCapture.store(true);
					g_mlHadSession.store(true);
				} else if (afterLoad) {
					MsglogParkHeldIfNeeded();
					g_mlHoldFlush = false;
					g_ml.NoteRetrySuccess();
					g_ml.buf.ResetMemory();
					g_ml.dirty = false;
					g_ml.buf.character = ch;
					g_ml.lastNotice.clear();
					needLoad = g_ml.buf.settings.persist && hzlog::PersistAllowed(ch);
					if (!needLoad) {
						g_ml.buf.StartSession(ts);
						g_ml.buf.Prune(g_mlEng.gt);
						g_ml.loadBusy.store(false);
						g_mlCapture.store(true);
						g_mlHadSession.store(true);
					}
				} else {
					g_ml.OnHudReady(ch, g_mlEng.gt, ts, now, false);
					needLoad = g_ml.buf.settings.persist && hzlog::PersistAllowed(ch)
						&& g_ml.buf.entries.empty();
					if (!needLoad) {
						g_ml.loadBusy.store(false);
						g_mlCapture.store(true);
						g_mlHadSession.store(true);
					}
				}
			}
			if (needLoad)
				MsglogQueueLoad(ch, g_mlEng.gt, ts);
		} catch (...) {
		}
	}

	void MsglogApplyLoad()
	{
		try {
			if (!g_mlLoadReady.exchange(false)) return;
			hzlog::LogState st;
			hzlog::Character ch;
			std::string notice;
			double gt = 0;
			std::int64_t ts = 0;
			bool ok = true;
			std::uint64_t jobGen = 0;
			std::string jobBufKey;
			bool jobHoldFlush = false;
			{
				std::lock_guard lk(g_mlWMu);
				st = std::move(g_mlLResult);
				ch = std::move(g_mlLCh);
				notice = std::move(g_mlLNotice);
				gt = g_mlLGt;
				ts = g_mlLTs;
				ok = g_mlLOk;
				jobGen = g_mlLGen;
				jobBufKey = std::move(g_mlLBufKey);
				jobHoldFlush = g_mlLHoldFlush;
			}
			bool needWrite = false;
			bool runPending = false;
			{
				std::lock_guard lk(g_mlMu);
				const auto now = GetTickCount64();
				if (hzlog::ShouldClearRecoverBusy(jobGen, g_mlInFlightGen))
					g_mlRecoverBusy.store(false);
				const bool stale = hzlog::LoadApplyStale(jobGen, g_mlLoadGen, jobBufKey, g_ml.buf.character.key);
				if (stale) {
					runPending = g_mlPendingHud;
				} else if (!ok) {
					hzlog::NoteLoadResult(false, g_ml.persistHold);
					if (g_ml.buf.character.keySource == "nameHash")
						g_ml.holdTargetKey = ch.key;
					g_ml.NoteRetryFailure(now);
					if (!notice.empty())
						g_ml.lastNotice = std::move(notice);
					MsglogNotePersistLog(false);
					if (hzlog::ApplyReopensCapture(jobHoldFlush, g_mlHoldFlush)) {
						g_ml.loadBusy.store(false);
						g_mlCapture.store(true);
						g_mlHadSession.store(true);
					}
					runPending = g_mlPendingHud;
				} else {
					const bool merge = g_ml.persistHold || g_ml.buf.character.keySource == "nameHash";
					if (merge) {
						g_ml.ApplyRecoveredFile(std::move(st), ch);
						needWrite = true;
					} else {
						hzlog::NoteLoadResult(true, g_ml.persistHold);
						g_ml.NoteRetrySuccess();
						if (!ch.key.empty())
							g_ml.buf.character = ch;
						if (!st.character.key.empty() || !st.entries.empty())
							g_ml.buf.LoadState(std::move(st));
					}
					g_ml.MergeKeptHeldIfMatch(ch.key);
					g_ml.lastNotice = std::move(notice);
					g_ml.buf.StartSession(ts);
					g_ml.buf.Prune(gt);
					MsglogNotePersistLog(true);
					if (hzlog::ApplyReopensCapture(jobHoldFlush, g_mlHoldFlush)) {
						g_mlHoldFlush = false;
						g_ml.loadBusy.store(false);
						g_mlCapture.store(true);
						g_mlHadSession.store(true);
					} else {
						g_mlHoldFlush = false;
					}
					runPending = g_mlPendingHud;
				}
			}
			if (needWrite)
				MsglogRequestWrite(jobHoldFlush);
			if (runPending) {
				g_mlPendingHud = false;
				g_ml.loadBusy.store(true);
				MsglogOnHudReady();
			}
		} catch (...) {
		}
	}

	void MsglogBeginLoad()
	{
		try {
			if (g_ml.loadBusy.load() && !g_mlCapture.load()) return;
			std::deque<MlNote> leftover;
			{
				std::lock_guard lock(g_mlQMu);
				leftover.swap(g_mlQ);
			}
			if (g_mlCapture.load()) {
				for (const auto& n : leftover)
					MsglogOfferNote(n);
			}
			bool held = false;
			{
				std::lock_guard lk(g_mlMu);
				++g_mlLoadGen;
				held = g_ml.persistHold;
			}
			if (held) {
				g_mlHoldFlush = true;
				MsglogQueueRecover(true, true);
				g_ml.loadBusy.store(true);
				g_mlCapture.store(false);
				return;
			}
			MsglogRequestWrite(true);
			g_ml.loadBusy.store(true);
			g_mlCapture.store(false);
		} catch (...) {
		}
	}

	// Purpose: pad navigation only after F11 is already open. Never opens F11, the log, or any Horizon menu.
	// Inputs: none. Outputs: queued hzSettingsKey codes. Dependencies: XInputGetState, QueueKey path.
	void MsglogXInputEnsure()
	{
		if (g_xiTried) return;
		g_xiTried = true;
		g_xiMod = ::LoadLibraryW(L"xinput1_4.dll");
		if (!g_xiMod) g_xiMod = ::LoadLibraryW(L"xinput9_1_0.dll");
		if (g_xiMod)
			g_xiGetState = reinterpret_cast<XInputGetStateFn>(::GetProcAddress(g_xiMod, "XInputGetState"));
	}

	void MsglogPadPoll()
	{
		if (!g_open) return;
		MsglogXInputEnsure();
		if (!g_xiGetState) return;
		const ULONGLONG now = GetTickCount64();
		if (now < g_xiNext) return;
		XINPUT_STATE st{};
		const auto err = g_xiGetState(0, &st);
		if (err == ERROR_DEVICE_NOT_CONNECTED) {
			g_xiNext = now + 1000;
			g_mlPadLast = 0;
			return;
		}
		if (err != ERROR_SUCCESS) return;
		const WORD b = st.Gamepad.wButtons;
		const WORD edge = static_cast<WORD>(b & ~g_mlPadLast);
		g_mlPadLast = b;
		auto fire = [&](const char* code) {
			std::lock_guard l(g_qLock);
			if (g_keyQueue.size() < 64) g_keyQueue.emplace_back(code);
		};
		struct Map { WORD mask; const char* code; int slot; bool repeat; };
		const Map maps[] = {
			{XINPUT_GAMEPAD_DPAD_UP, "up", 0, true},
			{XINPUT_GAMEPAD_DPAD_DOWN, "down", 1, true},
			{XINPUT_GAMEPAD_DPAD_LEFT, "left", 2, true},
			{XINPUT_GAMEPAD_DPAD_RIGHT, "right", 3, true},
			{XINPUT_GAMEPAD_A, "ok", 4, false},
			{XINPUT_GAMEPAD_B, "cancel", 5, false},
			{XINPUT_GAMEPAD_X, "padx", 6, false},
			{XINPUT_GAMEPAD_Y, "pady", 7, false},
			{XINPUT_GAMEPAD_LEFT_SHOULDER, "tabprev", 8, false},
			{XINPUT_GAMEPAD_RIGHT_SHOULDER, "tabnext", 9, false},
		};
		for (const auto& m : maps) {
			if (edge & m.mask) {
				fire(m.code);
				g_mlPadNext[m.slot] = now + 400;
				continue;
			}
			if (m.repeat && (b & m.mask) && now >= g_mlPadNext[m.slot]) {
				fire(m.code);
				g_mlPadNext[m.slot] = now + 150;
			}
		}
	}

	void MsglogPoll(ULONGLONG a_now)
	{
		try {
			if (!g_mlInited) return;
			if (g_mlWFailed.exchange(false)) {
				hzlog::LogState failSnap;
				std::string failKey;
				{
					std::lock_guard wlk(g_mlWMu);
					failSnap = std::move(g_mlWFailSnap);
					failKey = std::move(g_mlWFailKey);
				}
				std::lock_guard lk(g_mlMu);
				g_ml.writePending = false;
				if (hzlog::WriteFailParksJob(failKey, g_ml.buf.character.key)) {
					g_ml.ParkWriteFailure(failKey, failSnap.entries);
				} else {
					hzlog::NoteWriteFailure(g_ml.dirty);
					g_ml.NoteRetryFailure(a_now);
					g_mlWRetryAt.store(g_ml.retryAt);
				}
				MsglogNotePersistLog(false);
			}
			if (g_mlWRecovered.exchange(false)) {
				std::lock_guard lk(g_mlMu);
				g_ml.writePending = false;
				if (hzlog::WriteRecoveredResetsBackoff(g_ml.persistHold)) {
					hzlog::NoteWriteSuccess(g_ml.retryBackoffMs, g_ml.retryAt);
					g_mlWRetryAt.store(0);
				}
				MsglogNotePersistLog(true);
			}
			bool holdDue = false;
			{
				std::lock_guard lk(g_mlMu);
				holdDue = g_ml.persistHold && hzlog::RetryDue(g_ml.retryAt, a_now);
			}
			if (holdDue)
				MsglogQueueRecover(false);
			else if (g_mlWRetryAt.load() && a_now >= g_mlWRetryAt.load()) {
				g_mlWRetryAt.store(0);
				MsglogRequestWrite(false);
			}
			if (g_mlSaveReq.exchange(false)) {
				if (g_mlCapture.load() && HudSafe()) {
					MsglogRefreshEngine(true);
					MsglogPromoteId();
				}
				bool held = false;
				{
					std::lock_guard lk(g_mlMu);
					held = g_ml.persistHold;
				}
				if (held)
					MsglogQueueRecover(true);
				else
					MsglogRequestWrite(true);
			}
			if (g_mlLoadReq.exchange(false))
				MsglogBeginLoad();
			if (g_mlQuitReq.exchange(false)) {
				bool held = false;
				{
					std::lock_guard lk(g_mlMu);
					held = g_ml.persistHold;
				}
				if (held)
					MsglogQueueRecover(true);
				else
					MsglogRequestWrite(true);
			}
			if (g_mlShutdownReq.exchange(false))
				MsglogShutdownWriter();
			MsglogApplyLoad();
			MsglogPadPoll();
			try { MsglogTakeMovie(); } catch (...) {}
			if (g_mlCapture.load()) {
				MsglogRefreshEngine(false);
				MsglogPromoteId();
			}
			if (!g_mlCapture.load()) return;
			std::deque<MlNote> batch;
			{
				std::lock_guard lock(g_mlQMu);
				batch.swap(g_mlQ);
			}
			for (const auto& n : batch)
				MsglogOfferNote(n);
			if (g_ml.ShouldFlush(a_now, false))
				MsglogRequestWrite(false);
		} catch (...) {
		}
	}

	class SaveLoadSink final : public RE::BSTEventSink<RE::SaveLoadEvent>
	{
	public:
		// Purpose: flush the message log on save. Character switch waits for the HUD-ready edge.
		// Inputs: SaveLoadEvent. Outputs: kContinue. Dependencies: MsglogRequestWrite.
		RE::BSEventNotifyControl ProcessEvent(const RE::SaveLoadEvent& a_ev, RE::BSTEventSource<RE::SaveLoadEvent>*) override
		{
			try {
				using Op = RE::SaveLoadEvent::OpType;
				using St = RE::SaveLoadEvent::Status;
				const auto op = a_ev.opType;
				const auto st = a_ev.status;
				const bool saving = op == Op::kAutosave || op == Op::kQuicksave || op == Op::kManualSave
					|| op == Op::kExitSaveToMainMenu || op == Op::kExitSaveToDesktop;
				const bool loading = op == Op::kLoad || op == Op::kQuickload || op == Op::kLoadMostRecent || op == Op::kLoadNamedFile;
				if (loading && st == St::kBegin)
					g_mlLoadReq.store(true);
				if (saving && (st == St::kSaveCompleted || st == St::kBegin))
					g_mlSaveReq.store(true);
				if ((op == Op::kExitSaveToMainMenu || op == Op::kExitSaveToDesktop)
					&& (st == St::kSaveCompleted || st == St::kBegin))
					g_mlQuitReq.store(true);
				if (op == Op::kExitSaveToDesktop && (st == St::kSaveCompleted || st == St::kBegin))
					g_mlShutdownReq.store(true);
			} catch (...) {
			}
			return RE::BSEventNotifyControl::kContinue;
		}
	};

	void RegisterSaveLoadSink()
	{
		try {
			auto src = RE::SaveLoadEvent::GetEventSource();
			if (!src) {
				REX::WARN("SaveLoadEvent source is null; message log will flush on debounce and save HUD lines");
				return;
			}
			static SaveLoadSink sink;
			src->RegisterSink(&sink);
			REX::INFO("SaveLoadEvent sink registered (message log flush)");
		} catch (const std::exception& ex) {
			REX::WARN("SaveLoadEvent sink failed: {}", ex.what());
		} catch (...) {
			REX::WARN("SaveLoadEvent sink failed: unknown error");
		}
	}

	void Poll()
	{
		auto now = GetTickCount64();
		BannerPoll(now);   // v0.40.3
		CommsDbgPoll(now);   // v0.42.0.6: empty when HZ_COMMS_MSG_LOG is 0
		CommsRxPoll(now);    // v0.42.0.7: reaction backup. Before the HUD-ready return below.
		ScopeClipPoll(now);     // v0.42.0.8: hold-breath clip line. Before the HUD-ready return, so a scope still logs it.
		MsglogPoll(now);        // 0.43.0.1: capture during menus too; writes stay off while a load is in progress.
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
			{
				auto uiLoad = RE::UI::GetSingleton();
				if (uiLoad) {
					const bool loading = uiLoad->IsMenuOpen("LoadingMenu");
					const bool menu = uiLoad->IsMenuOpen("MainMenu");
					if (loading || (menu && g_mlCapture.load()))
						g_mlLoadReq.store(true);
					if (menu && !loading && g_mlHadSession.exchange(false))
						g_mlQuitReq.store(true);
				}
			}
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
		if (!g_hudReadyLogged) { REX::INFO("HUD ready (stable 3s)"); g_hudReadyLogged = true; HudOwnerCheck(); MsglogOnHudReady(); }
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
			RegisterSaveLoadSink();
			LoadIni();
			if (auto task = SFSE::GetTaskInterface()) {
				task->AddPermanentTask([]() { try { Poll(); } catch (...) {} });
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
