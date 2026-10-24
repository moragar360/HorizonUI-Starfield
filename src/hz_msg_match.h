#pragma once

// HUD message classification for the 0.42.0.10 cards. Pure string work: no forms,
// no game settings, and no address lookups. The DLL fills the GMST phrases after
// data has loaded and calls Match on the task thread. English is the fallback.
// A line that does not match is left as the game's own message.
// Last modified: 2026-10-24.

#include <cstddef>
#include <string>
#include <string_view>
#include <vector>

namespace hzmsg {

inline constexpr char kTierEnglish = 'C';
inline constexpr char kTierGmst = 'A';

struct Hit
{
	bool        ok{false};
	std::string kind;
	std::string sub;
	std::string name;
	std::string value;
	char        tier{kTierEnglish};
};

// Phrases the game localizes as GMSTs. Medical, crew, and Kid Stuff stay the
// English Message text, because a message description is only a string id here.
struct Templates
{
	std::string likes{"liked that."};                              // sAffinityEventLikes
	std::string loves{"loved that."};                              // sAffinityEventLoves
	std::string dislikes{"disliked that."};                        // sAffinityEventDislikes
	std::string hates{"hated that."};                              // sAffinityEventHates
	std::string busy{"This individual is busy."};                  // sSceneBlockingActorActivation
	std::string npcCalmed{"is calmed and cannot respond."};        // sActivateNPCCalmed
	std::string creature{"The creature is calmed and cannot respond."}; // sActivateCreatureCalmed
	std::string caught{"has already caught you."};                 // sNoPickPocketAgain (leading space trimmed)
	std::string pickFail{"You've been caught pickpocketing."};     // sPickpocketFail
	std::string stealTake{"The owner caught you stealing."};       // sStealTakeBack
	std::string stealAttack{"You've been caught stealing and the alarm has been raised."}; // sStealAttack
	std::string lockCaught{"You've been caught tampering with a lock."}; // sLockpickingCaught
	std::string trespass{"You're currently trespassing. Residents will become hostile if you stay."}; // sTrespassing
	std::string witness{"Last witness killed."};                   // sWitnessKilled
	std::string addCrime{"bounty added to"};                        // sAddCrimeGold (fragment)
	std::string remCrime{"bounty removed from"};                    // sRemoveCrimeGold (fragment)
	std::string added{"Added."};                                    // sAddItemtoInventory
	std::string removed{"Removed."};                                // sRemoveItemfromInventory
	std::string creditsName{"Credits"};                             // TESObjectMISC 0000000F full name
	std::string credits{"credits have been sent home to your parents."}; // Trait_KidStuff_Msg_SentCredits, after %.0f
	std::string kidTpl{"%.0f credits have been sent home to your parents."}; // full Kid Stuff template
};

inline Templates English()
{
	return {};
}

inline bool IsWs(unsigned char c)
{
	return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\v' || c == '\f';
}

inline std::string_view Trim(std::string_view s)
{
	while (!s.empty() && IsWs(static_cast<unsigned char>(s.front()))) s.remove_prefix(1);
	while (!s.empty() && IsWs(static_cast<unsigned char>(s.back()))) s.remove_suffix(1);
	return s;
}

inline char Fold(char c)
{
	const auto u = static_cast<unsigned char>(c);
	if (u >= 'A' && u <= 'Z') return static_cast<char>(u - 'A' + 'a');
	return c;
}

inline bool EqFold(std::string_view a, std::string_view b)
{
	if (a.size() != b.size()) return false;
	for (std::size_t i = 0; i < a.size(); ++i)
		if (Fold(a[i]) != Fold(b[i])) return false;
	return true;
}

inline bool EndsFold(std::string_view s, std::string_view suf)
{
	if (suf.empty() || s.size() < suf.size()) return false;
	return EqFold(s.substr(s.size() - suf.size()), suf);
}

inline bool StartsFold(std::string_view s, std::string_view pre)
{
	if (pre.empty() || s.size() < pre.size()) return false;
	return EqFold(s.substr(0, pre.size()), pre);
}

// Empty, or an unresolved "<ID=…>" stub, is not a phrase we can match.
inline bool UsablePhrase(std::string_view s)
{
	s = Trim(s);
	if (s.empty()) return false;
	if (s.size() >= 4 && (s[0] == '<') && (s[1] == 'I' || s[1] == 'i') && (s[2] == 'D' || s[2] == 'd') && s[3] == '=')
		return false;
	return true;
}

inline void ApplyPhrase(std::string& slot, std::string_view got)
{
	const auto t = Trim(got);
	if (!UsablePhrase(t)) return;
	slot.assign(t.begin(), t.end());
}

inline bool SamePhrase(std::string_view got, std::string_view english)
{
	return EqFold(Trim(got), Trim(english));
}

inline char TierOf(std::string_view got, std::string_view english)
{
	return SamePhrase(got, english) ? kTierEnglish : kTierGmst;
}

inline Hit Miss()
{
	return {};
}

inline Hit Make(const char* kind, const char* sub, std::string name, const char* value, char tier)
{
	Hit h;
	h.ok = true;
	h.kind = kind;
	h.sub = sub;
	h.name = std::move(name);
	h.value = value ? value : "";
	h.tier = tier;
	return h;
}

inline std::string Slice(std::string_view s)
{
	return std::string(s.begin(), s.end());
}

inline int Words(std::string_view s)
{
	int n = 0;
	bool in = false;
	for (char c : s) {
		if (c == ' ') { in = false; continue; }
		if (!in) { in = true; ++n; }
	}
	return n;
}

inline bool IsTitle(std::string_view w)
{
	static constexpr const char* kTitles[] = {
		"dr", "mr", "mrs", "ms", "jr", "sr", "st", "lt", "capt", "sgt", "prof"
	};
	for (const char* t : kTitles)
		if (EqFold(w, t)) return true;
	return false;
}

inline bool IsPronoun(std::string_view w)
{
	static constexpr const char* kNo[] = {
		"i", "you", "we", "they", "he", "she", "it", "your", "my", "our", "their",
		"his", "her", "nobody", "everyone", "everybody", "someone", "somebody",
		"none", "all", "some", "the", "a", "an", "crew", "who", "not", "people",
		"this", "that", "many", "most", "each", "several", "both", "what"
	};
	for (const char* t : kNo)
		if (EqFold(w, t)) return true;
	return false;
}

// A reaction name is the prefix in front of the GMST. English keeps the old
// pronoun and bare-title rejects. Any other language accepts a non-empty prefix.
inline bool ReactionNameOk(std::string_view name, bool english)
{
	name = Trim(name);
	if (name.empty() || name.size() > 80) return false;
	if (name.find('<') != std::string_view::npos || name.find('>') != std::string_view::npos) return false;
	if (!english) return Words(name) >= 1 && Words(name) <= 8;
	if (Words(name) < 1 || Words(name) > 4) return false;
	const auto sp = name.find(' ');
	auto first = sp == std::string_view::npos ? name : name.substr(0, sp);
	while (!first.empty() && first.back() == '.') first.remove_suffix(1);
	if (first.empty() || IsPronoun(first)) return false;
	if (Words(name) == 1 && IsTitle(first)) return false;
	if (sp != std::string_view::npos) {
		auto rest = Trim(name.substr(sp + 1));
		const auto sp2 = rest.find(' ');
		auto second = sp2 == std::string_view::npos ? rest : rest.substr(0, sp2);
		while (!second.empty() && second.back() == '.') second.remove_suffix(1);
		if (EqFold(first, "no") && EqFold(second, "one")) return false;
	}
	return true;
}

inline bool PlainNameOk(std::string_view name)
{
	name = Trim(name);
	if (name.empty() || name.size() > 80) return false;
	if (name.find('<') != std::string_view::npos || name.find('>') != std::string_view::npos) return false;
	const int n = Words(name);
	return n >= 1 && n <= 8;
}

inline std::string_view DropOnePeriod(std::string_view s)
{
	if (!s.empty() && s.back() == '.') s.remove_suffix(1);
	return s;
}

// Suffix, and the same suffix with one optional final period on either side.
inline bool EndsPhrase(std::string_view line, std::string_view phrase)
{
	phrase = Trim(phrase);
	if (phrase.empty()) return false;
	if (EndsFold(line, phrase)) return true;
	if (!phrase.empty() && phrase.back() == '.') {
		phrase.remove_suffix(1);
		if (!phrase.empty() && EndsFold(line, phrase)) return true;
	} else if (EndsFold(DropOnePeriod(line), phrase)) {
		return true;
	}
	return false;
}

inline std::string PrefixOf(std::string_view line, std::string_view phrase)
{
	phrase = Trim(phrase);
	auto take = [&](std::string_view suf) -> std::string {
		if (!EndsFold(line, suf)) return {};
		auto head = Trim(line.substr(0, line.size() - suf.size()));
		return Slice(head);
	};
	if (EndsFold(line, phrase)) return take(phrase);
	if (!phrase.empty() && phrase.back() == '.') {
		auto bare = phrase.substr(0, phrase.size() - 1);
		if (EndsFold(line, bare)) return take(bare);
	} else if (EndsFold(DropOnePeriod(line), phrase)) {
		auto cut = DropOnePeriod(line);
		if (EndsFold(cut, phrase)) return Slice(Trim(cut.substr(0, cut.size() - phrase.size())));
	}
	return {};
}

// "disliked that." ends with "liked that." A localized dislikes phrase must not
// leave the shorter English likes phrase to claim that line.
inline bool ShadowedByLonger(std::string_view line, std::string_view phrase)
{
	phrase = Trim(phrase);
	const auto bare = DropOnePeriod(phrase);
	if (!EqFold(bare, "liked that") && !EqFold(bare, "likes that")) return false;
	const char* longer[] = {"disliked that.", "dislikes that."};
	for (const char* item : longer) {
		const auto full = std::string_view(item);
		if (EqFold(Trim(full), phrase)) continue;
		if (!EndsPhrase(full, phrase)) continue;
		if (EndsPhrase(line, full)) return true;
	}
	return false;
}

struct RxSlot
{
	const char* phrase;
	const char* sub;
	const char* value;
	bool        english;
};

inline Hit MatchReaction(std::string_view line, const Templates& t, const Templates& en)
{
	// disliked before liked: "disliked that." ends with "liked that."
	const RxSlot slots[] = {
		{t.dislikes.c_str(), "disliked", "DISLIKED", SamePhrase(t.dislikes, en.dislikes)},
		{t.hates.c_str(), "hated", "HATED", SamePhrase(t.hates, en.hates)},
		{t.loves.c_str(), "loved", "LOVED", SamePhrase(t.loves, en.loves)},
		{t.likes.c_str(), "liked", "LIKED", SamePhrase(t.likes, en.likes)},
	};
	for (const auto& s : slots) {
		if (!EndsPhrase(line, s.phrase) || ShadowedByLonger(line, s.phrase)) continue;
		const auto name = PrefixOf(line, s.phrase);
		if (!ReactionNameOk(name, s.english)) return Miss();
		return Make("reaction", s.sub, name, s.value, s.english ? kTierEnglish : kTierGmst);
	}
	// Present tense is English-only. A localized GMST does not use these words.
	if (SamePhrase(t.likes, en.likes)) {
		const RxSlot now[] = {
			{"dislikes that.", "disliked", "DISLIKED", true},
			{"hates that.", "hated", "HATED", true},
			{"loves that.", "loved", "LOVED", true},
			{"likes that.", "liked", "LIKED", true},
		};
		for (const auto& s : now) {
			if (!EndsPhrase(line, s.phrase) || ShadowedByLonger(line, s.phrase)) continue;
			const auto name = PrefixOf(line, s.phrase);
			if (!ReactionNameOk(name, true)) return Miss();
			return Make("reaction", s.sub, name, s.value, kTierEnglish);
		}
	}
	return Miss();
}

inline bool DigitsOnly(std::string_view s)
{
	if (s.empty() || s.size() > 9) return false;
	for (char c : s)
		if (c < '0' || c > '9') return false;
	return true;
}

inline bool IsWordChar(unsigned char c)
{
	return (c >= '0' && c <= '9') || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z');
}

inline bool EqLine(std::string_view line, std::string_view phrase)
{
	line = Trim(line);
	phrase = Trim(phrase);
	if (!UsablePhrase(phrase)) return false;
	if (EqFold(line, phrase)) return true;
	return EqFold(DropOnePeriod(line), DropOnePeriod(phrase));
}

// Locale group separators between digit groups: comma, period, apostrophe, space, NBSP, NNBSP.
inline bool GroupSepAt(std::string_view s, std::size_t i, std::size_t& adv)
{
	if (i >= s.size()) return false;
	const auto c = static_cast<unsigned char>(s[i]);
	if (c == ',' || c == '.' || c == '\'' || c == ' ') {
		adv = 1;
		return true;
	}
	if (c == 0xC2 && i + 1 < s.size() && static_cast<unsigned char>(s[i + 1]) == 0xA0) {
		adv = 2;
		return true;
	}
	if (c == 0xE2 && i + 2 < s.size()
		&& static_cast<unsigned char>(s[i + 1]) == 0x80
		&& static_cast<unsigned char>(s[i + 2]) == 0xAF) {
		adv = 3;
		return true;
	}
	return false;
}

inline bool SpaceSep(std::string_view s, std::size_t i, std::size_t adv)
{
	if (adv >= 2) return true;
	return adv == 1 && i < s.size() && s[i] == ' ';
}

// Exactly three digits at i, and not the start of a longer run.
inline bool TakeGroup3(std::string_view s, std::size_t i, std::string& digits, std::size_t& out)
{
	if (i + 3 > s.size()) return false;
	for (std::size_t k = 0; k < 3; ++k) {
		if (s[i + k] < '0' || s[i + k] > '9') return false;
	}
	if (i + 3 < s.size() && s[i + 3] >= '0' && s[i + 3] <= '9') return false;
	if (digits.size() + 3 > 9) return false;
	digits.append(s.substr(i, 3));
	out = i + 3;
	return true;
}

// First run of digits, allowing locale separators between groups. A separator
// must be followed by exactly three digits. Space and NBSP do not join two
// already-complete 3-digit amounts ("500 500" fails closed; "1 500" is 1500).
inline bool TakeAmount(std::string_view s, std::size_t from, std::string& digits, std::size_t& begin, std::size_t& end)
{
	digits.clear();
	std::size_t i = from;
	while (i < s.size() && (s[i] < '0' || s[i] > '9')) ++i;
	if (i >= s.size()) return false;
	begin = i;
	bool usedSpace = false;
	while (i < s.size()) {
		const char c = s[i];
		if (c >= '0' && c <= '9') {
			if (digits.size() >= 9) return false;
			digits.push_back(c);
			++i;
			continue;
		}
		std::size_t adv = 0;
		if (GroupSepAt(s, i, adv) && i + adv < s.size() && s[i + adv] >= '0' && s[i + adv] <= '9') {
			const bool space = SpaceSep(s, i, adv);
			if (space && !usedSpace && digits.size() >= 3) return false;
			std::size_t after = 0;
			if (!TakeGroup3(s, i + adv, digits, after)) return false;
			usedSpace = usedSpace || space;
			i = after;
			continue;
		}
		break;
	}
	end = i;
	return DigitsOnly(digits);
}

inline std::string GroupDigits(std::string_view digits)
{
	std::string out;
	const auto n = digits.size();
	for (std::size_t i = 0; i < n; ++i) {
		if (i && ((n - i) % 3) == 0) out.push_back(',');
		out.push_back(digits[i]);
	}
	return out;
}

inline std::string SignedChip(bool plus, std::string_view digits)
{
	return (plus ? "+" : "-") + GroupDigits(digits);
}

inline bool ContainsWord(std::string_view hay, std::string_view needle, std::size_t& at)
{
	needle = Trim(needle);
	if (needle.empty()) return false;
	for (std::size_t i = 0; i + needle.size() <= hay.size(); ++i) {
		if (!EqFold(hay.substr(i, needle.size()), needle)) continue;
		const bool left = i == 0 || !IsWordChar(static_cast<unsigned char>(hay[i - 1]));
		const bool right = i + needle.size() == hay.size()
			|| !IsWordChar(static_cast<unsigned char>(hay[i + needle.size()]));
		if (!left || !right) continue;
		at = i;
		return true;
	}
	return false;
}

// Leftover credits text may only keep spaces, x/X, parentheses, and a multiply sign.
inline bool CreditsRestOk(std::string_view rest)
{
	for (std::size_t i = 0; i < rest.size();) {
		const auto c = static_cast<unsigned char>(rest[i]);
		if (c == ' ' || c == '\t' || c == '(' || c == ')' || c == 'x' || c == 'X' || c == '*' || c == '-') {
			++i;
			continue;
		}
		if (c == 0xC3 && i + 1 < rest.size() && static_cast<unsigned char>(rest[i + 1]) == 0x97) {
			i += 2;
			continue;
		}
		if (c == 0xC2 && i + 1 < rest.size() && static_cast<unsigned char>(rest[i + 1]) == 0xA0) {
			i += 2;
			continue;
		}
		return false;
	}
	return true;
}

enum class Tk : unsigned char { Lit, Str, Num };

struct Token
{
	Tk          kind{Tk::Lit};
	std::string lit;
};

// Purpose: turn a GMST or MESG template into literals plus wildcards.
// Inputs: a template with %s, %d, %i, %f, %.Nf, and/or <Global=...>.
// Outputs: tokens in order. A lone % or an unknown % code fails closed (empty list).
// Last modified: 2026-10-24.
inline std::vector<Token> Tokenize(std::string_view tpl)
{
	std::vector<Token> out;
	std::size_t i = 0;
	while (i < tpl.size()) {
		if (tpl[i] == '<' && i + 8 <= tpl.size() && EqFold(tpl.substr(i, 8), "<global=")) {
			const auto close = tpl.find('>', i + 8);
			if (close == std::string_view::npos) return {};
			out.push_back({Tk::Num, {}});
			i = close + 1;
			continue;
		}
		if (tpl[i] == '%') {
			if (i + 1 >= tpl.size()) return {};
			const char n = Fold(tpl[i + 1]);
			if (n == '%') {
				if (out.empty() || out.back().kind != Tk::Lit) out.push_back({Tk::Lit, {}});
				out.back().lit.push_back('%');
				i += 2;
				continue;
			}
			if (n == 's') {
				out.push_back({Tk::Str, {}});
				i += 2;
				continue;
			}
			if (n == 'd' || n == 'i' || n == 'u' || n == 'f') {
				out.push_back({Tk::Num, {}});
				i += 2;
				continue;
			}
			if (n == '.' ) {
				std::size_t j = i + 2;
				while (j < tpl.size() && tpl[j] >= '0' && tpl[j] <= '9') ++j;
				if (j < tpl.size() && (Fold(tpl[j]) == 'f' || Fold(tpl[j]) == 'g')) {
					out.push_back({Tk::Num, {}});
					i = j + 1;
					continue;
				}
				return {};
			}
			return {};
		}
		if (out.empty() || out.back().kind != Tk::Lit) out.push_back({Tk::Lit, {}});
		out.back().lit.push_back(tpl[i]);
		++i;
	}
	return out;
}

struct TplHit
{
	bool        ok{false};
	std::string amount;
};

// Purpose: match a HUD line to a tokenized template. Fail closed.
// Inputs: the trimmed line and the original template.
// Outputs: ok plus the first numeric wildcard as digits (locale separators stripped).
// Last modified: 2026-10-24.
inline TplHit MatchTemplate(std::string_view line, std::string_view tpl)
{
	TplHit miss;
	tpl = Trim(tpl);
	line = Trim(line);
	if (!UsablePhrase(tpl) || line.empty()) return miss;
	const auto toks = Tokenize(tpl);
	if (toks.empty()) return miss;
	std::size_t pos = 0;
	std::string amount;
	for (std::size_t t = 0; t < toks.size(); ++t) {
		const auto& tok = toks[t];
		if (tok.kind == Tk::Lit) {
			auto lit = std::string_view(tok.lit);
			if (lit.empty()) continue;
			if (pos + lit.size() > line.size() || !EqFold(line.substr(pos, lit.size()), lit)) {
				if (t + 1 == toks.size() && !lit.empty() && lit.back() == '.') {
					auto bare = lit.substr(0, lit.size() - 1);
					if (!bare.empty() && pos + bare.size() <= line.size() && EqFold(line.substr(pos, bare.size()), bare)) {
						pos += bare.size();
						continue;
					}
				}
				if (t + 1 == toks.size() && pos < line.size() && line.back() == '.'
					&& pos + lit.size() + 1 == line.size() && EqFold(line.substr(pos, lit.size()), lit)) {
					pos = line.size();
					continue;
				}
				return miss;
			}
			pos += lit.size();
			continue;
		}
		if (tok.kind == Tk::Num) {
			std::string digits;
			std::size_t b = 0, e = 0;
			if (!TakeAmount(line, pos, digits, b, e) || b != pos) return miss;
			if (amount.empty()) amount = digits;
			pos = e;
			continue;
		}
		// %s: consume until the next literal, or the rest of the line.
		std::string_view stop;
		for (std::size_t u = t + 1; u < toks.size(); ++u) {
			if (toks[u].kind == Tk::Lit && !toks[u].lit.empty()) {
				stop = toks[u].lit;
				break;
			}
		}
		if (stop.empty()) {
			if (pos >= line.size()) return miss;
			pos = line.size();
			continue;
		}
		bool found = false;
		for (std::size_t j = pos; j + stop.size() <= line.size(); ++j) {
			if (EqFold(line.substr(j, stop.size()), stop)) {
				if (j == pos) return miss;
				pos = j;
				found = true;
				break;
			}
		}
		if (!found) return miss;
	}
	if (pos < line.size()) {
		auto rest = Trim(line.substr(pos));
		if (!rest.empty() && !(rest.size() == 1 && rest[0] == '.')) return miss;
	}
	TplHit hit;
	hit.ok = true;
	hit.amount = std::move(amount);
	return hit;
}

// "500 credits have been sent…" and "1,500 credits…". The chip is the amount
// sent home, so the value is negative. A cut-off line does not match.
// The tokenizer is the shared path; the tail rule stays so 0.42.0.9 Kid Stuff is unchanged.
inline Hit MatchCreditsTail(std::string_view line, std::string_view tail)
{
	tail = Trim(tail);
	if (tail.empty()) return Miss();
	std::string_view s = line;
	if (!EndsPhrase(s, tail)) return Miss();
	if (EndsFold(s, tail)) {
		/* keep s */
	} else if (!tail.empty() && tail.back() == '.' && EndsFold(s, tail.substr(0, tail.size() - 1))) {
		/* keep s; the period was optional */
	} else {
		s = DropOnePeriod(s);
	}
	if (!EndsFold(s, tail) && !(tail.back() == '.' && EndsFold(s, tail.substr(0, tail.size() - 1))))
		return Miss();
	const auto suf = EndsFold(s, tail) ? tail : tail.substr(0, tail.size() - 1);
	if (s.size() < suf.size() + 2) return Miss();
	auto head = Trim(s.substr(0, s.size() - suf.size()));
	if (head.empty()) return Miss();
	std::string digits;
	std::size_t i = 0;
	while (i < head.size()) {
		const char c = head[i];
		if (c >= '0' && c <= '9') { digits.push_back(c); ++i; continue; }
		if (c == ',' && !digits.empty() && i + 1 < head.size() && head[i + 1] >= '0' && head[i + 1] <= '9') {
			++i;
			continue;
		}
		break;
	}
	if (i == 0 || i != head.size()) return Miss();
	if (!DigitsOnly(digits)) return Miss();
	return Make("credits", "kid", "", ("-" + digits).c_str(), kTierEnglish);
}

inline Hit MatchCreditsKid(std::string_view line, const Templates& t)
{
	if (UsablePhrase(t.kidTpl)) {
		const auto h = MatchTemplate(line, t.kidTpl);
		if (h.ok && !h.amount.empty()) return Make("credits", "kid", "", ("-" + h.amount).c_str(), kTierEnglish);
	}
	return MatchCreditsTail(line, t.credits);
}

// Generic inventory line for the Credits item: the line ends with Added./Removed.,
// the rest contains the Credits name as a whole word, and the first digit run is
// the amount. Any other item text fails closed.
inline Hit MatchCreditsGeneric(std::string_view line, const Templates& t, const Templates& en)
{
	const bool add = EndsPhrase(line, t.added);
	const bool rem = !add && EndsPhrase(line, t.removed);
	if (!add && !rem) return Miss();
	const auto phrase = add ? std::string_view(t.added) : std::string_view(t.removed);
	auto head = PrefixOf(line, phrase);
	if (head.empty()) return Miss();
	std::size_t nameAt = 0;
	if (!ContainsWord(head, t.creditsName, nameAt)) return Miss();
	std::string digits;
	std::size_t b = 0, e = 0;
	if (!TakeAmount(head, 0, digits, b, e)) return Miss();
	std::string rest;
	rest.append(head.substr(0, b));
	rest.append(head.substr(e));
	std::size_t nameAt2 = 0;
	if (!ContainsWord(rest, t.creditsName, nameAt2)) return Miss();
	rest.erase(nameAt2, t.creditsName.size());
	if (!CreditsRestOk(rest)) return Miss();
	const char tier = (SamePhrase(t.added, en.added) && SamePhrase(t.removed, en.removed)
		&& SamePhrase(t.creditsName, en.creditsName)) ? kTierEnglish : kTierGmst;
	return Make("credits", add ? "gain" : "loss", "", SignedChip(add, digits).c_str(), tier);
}

// "<amount> bounty added to <faction>" is a crime penalty (BOUNTY, no credit
// sign). "bounty removed from" is credits leaving the player (BOUNTY PAID, -).
// Fail closed: a digit run, the fragment as a whole phrase, and a non-empty faction.
inline Hit MatchBounty(std::string_view line, const Templates& t, const Templates& en)
{
	struct Row {
		std::string_view phrase;
		const char*      kind;
		const char*      sub;
		bool             paid;
		std::string_view english;
	};
	const Row rows[] = {
		{t.remCrime, "credits", "bounty", true, en.remCrime},
		{t.addCrime, "crime", "bounty-add", false, en.addCrime},
	};
	for (const auto& r : rows) {
		const auto phrase = Trim(r.phrase);
		if (!UsablePhrase(phrase)) continue;
		std::size_t at = 0;
		if (!ContainsWord(line, phrase, at)) continue;
		auto head = Trim(line.substr(0, at));
		auto tail = Trim(line.substr(at + phrase.size()));
		if (tail.empty() || !PlainNameOk(tail)) continue;
		std::string digits;
		std::size_t b = 0, e = 0;
		if (!TakeAmount(head, 0, digits, b, e)) continue;
		auto leftover = Trim(std::string(head.substr(0, b)) + std::string(head.substr(e)));
		if (!leftover.empty()) continue;
		const char tier = SamePhrase(r.phrase, r.english) ? kTierEnglish : kTierGmst;
		if (r.paid) return Make(r.kind, r.sub, Slice(tail), SignedChip(false, digits).c_str(), tier);
		return Make(r.kind, r.sub, Slice(tail), "BOUNTY", tier);
	}
	return Miss();
}

inline Hit MatchCredits(std::string_view line, const Templates& t, const Templates& en)
{
	if (auto h = MatchCreditsKid(line, t); h.ok) return h;
	if (auto h = MatchCreditsGeneric(line, t, en); h.ok) return h;
	if (auto h = MatchBounty(line, t, en); h.ok) return h;
	return Miss();
}

struct Hole
{
	const char* prefix;
	const char* suffix;
	const char* sub;
	const char* value;
};

// English Message text. The alias is already replaced by the time the line arrives.
// Form ids (Starfield.esm): gained 002F443D, worse 002F443E, improved 000295FD,
// severity 00205AA3, attempted 002EDFF6, cured 002F4434.
inline Hit MatchMedical(std::string_view line)
{
	const Hole holes[] = {
		{"Prognosis improved (", ")", "improved", "IMPROVED"},
		{"Severity improved (", ")", "severity", "LESS SEVERE"},
		{"Attempted to cure ", ".", "attempted", "ATTEMPTED"},
		{"", " became worse.", "worse", "WORSE"},
		{"", " gained.", "gained", "GAINED"},
		{"", " cured.", "cured", "CURED"},
	};
	for (const auto& h : holes) {
		std::string_view s = line;
		const bool paren = h.suffix[0] == ')' && h.suffix[1] == '\0';
		if (paren && !s.empty() && s.back() == '.' && !EndsFold(s, h.suffix)) s = DropOnePeriod(s);
		if (h.prefix[0] != '\0' && !StartsFold(s, h.prefix)) continue;
		if (!EndsPhrase(s, h.suffix) && !EndsFold(s, h.suffix)) continue;
		if (!EndsFold(s, h.suffix)) {
			if (!h.suffix[0] || h.suffix[std::char_traits<char>::length(h.suffix) - 1] != '.') continue;
			auto bare = std::string_view(h.suffix, std::char_traits<char>::length(h.suffix) - 1);
			if (!EndsFold(s, bare)) continue;
			const auto preN = std::char_traits<char>::length(h.prefix);
			if (s.size() < preN + bare.size()) continue;
			auto mid = Trim(s.substr(preN, s.size() - preN - bare.size()));
			if (!PlainNameOk(mid)) continue;
			return Make("medical", h.sub, Slice(mid), h.value, kTierEnglish);
		}
		const auto preN = std::char_traits<char>::length(h.prefix);
		const auto sufN = std::char_traits<char>::length(h.suffix);
		if (s.size() < preN + sufN) continue;
		auto mid = Trim(s.substr(preN, s.size() - preN - sufN));
		if (!PlainNameOk(mid)) continue;
		return Make("medical", h.sub, Slice(mid), h.value, kTierEnglish);
	}
	return Miss();
}

struct Crew
{
	const char* suffix;
	const char* sub;
	const char* value;
};

// Longer suffixes first. "is no longer angry" must win over "is angry".
// Form ids are the English Message records in Starfield.esm (see the 0.42.0.9 note).
inline Hit MatchCrew(std::string_view line)
{
	const Crew rows[] = {
		{"is furious with you and will no longer be your companion.", "furious", "FURIOUS"},
		{"is no longer available to be your companion.", "companion-unavailable", "AVAILABLE"},
		{"is no longer available to be your follower.", "follow-unavailable", "AVAILABLE"},
		{"is no longer available for your Crew.", "crew-unavailable", "CREW"},
		{"is no longer an Active Crew Member.", "uncrew", "CREW"},
		{"is no longer your Active Companion", "uncompanion", "COMPANION"},
		{"is no longer following you.", "unfollow", "FOLLOWING"},
		{"is no longer angry with you.", "calm", "CALM"},
		{"is now your Active Companion.", "companion", "COMPANION"},
		{"is available to be your Companion", "companion-available", "AVAILABLE"},
		{"is available to be your follower.", "follow-available", "AVAILABLE"},
		{"is now an Active Crew Member.", "crew", "CREW"},
		{"is available for your Crew.", "crew-available", "AVAILABLE"},
		{"is now following you.", "follow", "FOLLOWING"},
		{"considers you a committed partner.", "partner", "PARTNER"},
		{"considers you a friend.", "friend", "FRIEND"},
		{"considers you an ally.", "ally", "ALLY"},
		{"is angry with you.", "angry", "ANGRY"},
	};
	for (const auto& r : rows) {
		if (!EndsPhrase(line, r.suffix)) continue;
		const auto name = PrefixOf(line, r.suffix);
		if (!PlainNameOk(name)) continue;
		return Make("crew", r.sub, name, r.value, kTierEnglish);
	}
	return Miss();
}

inline Hit MatchUnavailable(std::string_view line, const Templates& t, const Templates& en)
{
	if (EqFold(line, Trim(t.busy)))
		return Make("unavailable", "busy", "", "BUSY", TierOf(t.busy, en.busy));
	if (EqFold(line, Trim(t.creature)))
		return Make("unavailable", "calmed", "Creature", "CALMED", TierOf(t.creature, en.creature));
	if (EqFold(line, Trim(t.pickFail)))
		return Make("unavailable", "caught", "", "CAUGHT", TierOf(t.pickFail, en.pickFail));
	if (EqLine(line, t.stealTake))
		return Make("crime", "takeback", "", "CAUGHT", TierOf(t.stealTake, en.stealTake));
	if (EqLine(line, t.stealAttack))
		return Make("crime", "alarm", "", "ALARM", TierOf(t.stealAttack, en.stealAttack));
	if (EqLine(line, t.lockCaught))
		return Make("crime", "lock", "", "CAUGHT", TierOf(t.lockCaught, en.lockCaught));
	if (EqLine(line, t.trespass))
		return Make("crime", "trespass", "", "TRESPASS", TierOf(t.trespass, en.trespass));
	if (EqLine(line, t.witness))
		return Make("crime", "witness", "", "WITNESS", TierOf(t.witness, en.witness));
	if (EndsPhrase(line, t.npcCalmed)) {
		const auto name = PrefixOf(line, t.npcCalmed);
		if (!PlainNameOk(name)) return Miss();
		return Make("unavailable", "calmed", name, "CALMED", TierOf(t.npcCalmed, en.npcCalmed));
	}
	if (EndsPhrase(line, t.caught)) {
		const auto name = PrefixOf(line, t.caught);
		if (!PlainNameOk(name)) return Miss();
		return Make("unavailable", "caught", name, "CAUGHT", TierOf(t.caught, en.caught));
	}
	return Miss();
}

// First match wins. Unknown text, a cut-off sentence, and an empty name fail closed.
inline Hit Match(std::string_view text, const Templates& phrases)
{
	const auto en = English();
	auto line = Trim(text);
	if (line.empty() || line.size() > 200) return Miss();
	if (line.find('\n') != std::string_view::npos || line.find('\r') != std::string_view::npos) return Miss();
	if (auto h = MatchReaction(line, phrases, en); h.ok) return h;
	if (auto h = MatchUnavailable(line, phrases, en); h.ok) return h;
	if (auto h = MatchCredits(line, phrases, en); h.ok) return h;
	if (auto h = MatchMedical(line); h.ok) return h;
	if (auto h = MatchCrew(line); h.ok) return h;
	return Miss();
}

} // namespace hzmsg
