#pragma once

// HZF preset apply: a preset -> HorizonUI.user.ini (PresetToUser) and its helpers. No files and no Win32.
// r7 (S-4): moved here from main.cpp unchanged, so tests/preset_list_test.cpp calls the real function.
// HZF::kVersion must be declared before hz_ini_diff.h is included (main.cpp and the tests do that).

#include <string>
#include <vector>

#include "hz_ini_diff.h"

namespace HZF {

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
			return Diff(p, a_defs, OnlySection(a_oldUser, "debug"), o);   // r6: the player's own [Debug] keys (WatchLog) stay
		}

} // namespace HZF
