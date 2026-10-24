#pragma once

// HUD message classification for the 0.42.0.9 cards. Pure string work: no forms,
// no game settings, and no address lookups. The DLL fills the GMST phrases after
// data has loaded and calls Match on the task thread. English is the fallback.
// A line that does not match is left as the game's own message.
// Last modified: 2026-10-23.

#include <cstddef>
#include <string>
#include <string_view>

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
	std::string credits{"credits have been sent home to your parents."}; // Trait_KidStuff_Msg_SentCredits, after %.0f
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

// "500 credits have been sent…" and "1,500 credits…". The chip is the amount
// sent home, so the value is negative. A cut-off line does not match.
inline Hit MatchCredits(std::string_view line, std::string_view tail)
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
	if (auto h = MatchCredits(line, phrases.credits); h.ok) return h;
	if (auto h = MatchMedical(line); h.ok) return h;
	if (auto h = MatchCrew(line); h.ok) return h;
	return Miss();
}

} // namespace hzmsg
