#pragma once

// HZF ini overlay and Diff (F11 SaveFromHud / presets). No files and no Win32.
// HZF::kVersion must be declared before this header is included.

#include <cctype>
#include <cmath>
#include <cstdlib>
#include <map>
#include <string>
#include <vector>

namespace HZF {

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

		// Purpose: persist hidden saved-preset ids in HorizonUI.state.ini.
		// Inputs: one id to hide/unhide, or a legacy csv for migration.
		// Outputs: HiddenN= encoded lines (one key per id, no list cap).
		// Files stay on disk.
		inline bool SamePresetId(const std::string& a_a, const std::string& a_b)
		{
			if (a_a.size() != a_b.size()) return false;
			for (std::size_t i = 0; i < a_a.size(); ++i) {
				const auto a = static_cast<unsigned char>(a_a[i]);
				const auto b = static_cast<unsigned char>(a_b[i]);
				if (std::tolower(a) != std::tolower(b)) return false;
			}
			return true;
		}

		inline std::vector<std::string> SplitPresetIds(const std::string& a_csv)
		{
			std::vector<std::string> out;
			std::size_t i = 0;
			while (i < a_csv.size()) {
				const auto j = a_csv.find(',', i);
				const auto part = Trim(a_csv.substr(i, j == std::string::npos ? std::string::npos : j - i));
				if (!part.empty()) out.push_back(part);
				if (j == std::string::npos) break;
				i = j + 1;
			}
			return out;
		}

		inline std::string JoinPresetIds(const std::vector<std::string>& a_ids)
		{
			std::string o;
			for (const auto& id : a_ids) {
				if (id.empty()) continue;
				if (!o.empty()) o += ',';
				o += id;
			}
			return o;
		}

		inline bool PresetIdHidden(const std::vector<std::string>& a_hidden, const std::string& a_id)
		{
			for (const auto& h : a_hidden)
				if (SamePresetId(h, a_id)) return true;
			return false;
		}

		inline void HidePresetId(std::vector<std::string>& a_hidden, const std::string& a_id)
		{
			if (a_id.empty() || PresetIdHidden(a_hidden, a_id)) return;
			a_hidden.push_back(a_id);
		}

		inline void UnhidePresetId(std::vector<std::string>& a_hidden, const std::string& a_id)
		{
			std::vector<std::string> keep;
			keep.reserve(a_hidden.size());
			for (const auto& h : a_hidden)
				if (!SamePresetId(h, a_id)) keep.push_back(h);
			a_hidden.swap(keep);
		}

		inline bool IsHiddenPresetKey(const std::string& a_kl)
		{
			if (a_kl.size() < 7 || a_kl.compare(0, 6, "hidden") != 0) return false;
			for (std::size_t i = 6; i < a_kl.size(); ++i)
				if (a_kl[i] < '0' || a_kl[i] > '9') return false;
			return true;
		}

		// Purpose: encode one hidden-preset id so KeyOf can round-trip it.
		// Inputs: the raw id (may contain ',' or ';'). Outputs: percent-encoded
		// text. ';' would otherwise be treated as an INI comment.
		// Dependencies: none.
		inline std::string EncodeHiddenPresetId(const std::string& a_id)
		{
			std::string o;
			o.reserve(a_id.size());
			static const char kHex[] = "0123456789ABCDEF";
			for (unsigned char c : a_id) {
				if (c == '%' || c == ';' || c == '\r' || c == '\n') {
					o += '%';
					o += kHex[c >> 4];
					o += kHex[c & 15];
				} else {
					o += static_cast<char>(c);
				}
			}
			return o;
		}

		// Purpose: decode a HiddenN value written by EncodeHiddenPresetId.
		// Inputs: the stored value. Outputs: the original id.
		// Dependencies: EncodeHiddenPresetId.
		inline std::string DecodeHiddenPresetId(const std::string& a_s)
		{
			std::string o;
			o.reserve(a_s.size());
			auto hex = [](char c) -> int {
				if (c >= '0' && c <= '9') return c - '0';
				if (c >= 'A' && c <= 'F') return c - 'A' + 10;
				if (c >= 'a' && c <= 'f') return c - 'a' + 10;
				return -1;
			};
			for (std::size_t i = 0; i < a_s.size(); ) {
				if (a_s[i] == '%' && i + 2 < a_s.size()) {
					const int hi = hex(a_s[i + 1]);
					const int lo = hex(a_s[i + 2]);
					if (hi >= 0 && lo >= 0) {
						o += static_cast<char>((hi << 4) | lo);
						i += 3;
						continue;
					}
				}
				o += a_s[i];
				++i;
			}
			return o;
		}

		inline std::string FormatHiddenPresetLines(const std::vector<std::string>& a_ids)
		{
			std::string t;
			for (std::size_t i = 0; i < a_ids.size(); ++i) {
				if (a_ids[i].empty()) continue;
				t += "Hidden";
				t += std::to_string(i);
				t += "=";
				t += EncodeHiddenPresetId(a_ids[i]);
				t += "\r\n";
			}
			return t;
		}

		inline void CollectHiddenPresetIds(const std::map<std::string, std::pair<std::string, std::string>>& a_kv,
			std::vector<std::string>& a_out)
		{
			for (const auto& [kl, kv] : a_kv) {
				if (!IsHiddenPresetKey(kl)) continue;
				if (!kv.second.empty())
					HidePresetId(a_out, DecodeHiddenPresetId(kv.second));
			}
		}

} // namespace HZF

