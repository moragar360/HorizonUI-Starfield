#pragma once

// Horizon Message Log P1: capture, ring buffer, per-character JSON, Persist.
// Planned, not released. Game-free so the harness can fail the rules without
// CommonLibSF. The DLL (src/main.cpp) supplies engine pointers, the worker
// thread, and the HUD-ready / SaveLoad flush.
// Author: Moragar
// Last modified: 2026-10-27.

#include "hz_msg_match.h"
#include "hz_version.h"
#include "preset_dedupe.h"

#include <algorithm>
#include <atomic>
#include <cctype>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <ctime>
#include <filesystem>
#include <fstream>
#include <functional>
#include <iterator>
#include <memory>
#include <mutex>
#include <string>
#include <string_view>
#include <system_error>
#include <thread>
#include <utility>
#include <vector>

namespace hzlog {

inline constexpr int kHistoryMin = 100;
inline constexpr int kHistoryMax = 1000;
inline constexpr int kHistoryDefault = 500;
inline constexpr int kHistoryStep = 100;
inline constexpr int kPinCap = 50;
inline constexpr int kTextCap = 256;
inline constexpr int kLocCap = 64;
inline constexpr int kRepeatCap = 999;
inline constexpr int kDedupeMs = 3000;
inline constexpr int kBusyDedupeMs = 10000;
inline constexpr int kFileReadMaxBytes = 4 * 1024 * 1024;
inline constexpr int kFileWriteMaxBytes = 3 * 1024 * 1024;
inline constexpr int kFileMaxBytes = kFileReadMaxBytes;
inline constexpr std::int64_t kLastPlayedEpochMin = 1000000000;
inline constexpr int kJsonVersion = 1;
inline constexpr const char* kJsonType = "horizon.messagelog";
inline constexpr int kDebounceMsMin = 10000;
inline constexpr int kDebounceMsMax = 30000;
inline constexpr int kDebounceMs = 15000;
inline constexpr int kJsonMaxDepth = 32;
inline constexpr int kLoadEntryCap = kHistoryMax + kPinCap;
inline constexpr int kWriterJoinMs = 2000;
inline constexpr int kRetryMsMin = 1000;
inline constexpr int kRetryMsMax = 60000;
inline constexpr int kWriteRetryMs = kRetryMsMin;
inline constexpr int kBakFailGiveUp = 3;
inline constexpr int kKeptHeldCap = kHistoryMax;
// F11 and the log open from the keyboard only. The HUD "Open in F11" hint
// shows this key, never a pad button or combo.
inline constexpr const char* kOpenHint = "F11";

enum class Kind : std::uint8_t {
	Medical = 0,
	Crew,
	Busy,
	Crime,
	Credits,
	Quest,
	Location,
	Xp,
	Game,
	Reaction
};

inline constexpr std::uint32_t kTypeMedical = 1u << 0;
inline constexpr std::uint32_t kTypeCrew = 1u << 1;
inline constexpr std::uint32_t kTypeBusy = 1u << 2;
inline constexpr std::uint32_t kTypeCrime = 1u << 3;
inline constexpr std::uint32_t kTypeCredits = 1u << 4;
inline constexpr std::uint32_t kTypeQuest = 1u << 5;
inline constexpr std::uint32_t kTypeLocation = 1u << 6;
inline constexpr std::uint32_t kTypeXp = 1u << 7;
inline constexpr std::uint32_t kTypeGame = 1u << 8;
inline constexpr std::uint32_t kTypeReaction = 1u << 9;
inline constexpr std::uint32_t kTypeAll = 0x3FFu;

enum class OfferResult : std::uint8_t {
	Stored = 0,
	Deduped,
	Rejected,
	SaveSignal
};

struct Settings {
	bool         record{true};
	bool         persist{true};
	bool         modulePresent{true}; // P1 ships in this build; tests may clear it
	bool         missedBadge{true};
	int          historySize{kHistoryDefault};
	std::uint32_t logTypes{kTypeAll};
};

struct Entry {
	std::uint64_t id{0};
	Kind          kind{Kind::Game};
	std::string   text;
	std::string   title;
	std::string   tag;
	double        gt{0};
	double        ut{-1};
	double        lt{-1};
	std::int64_t  ts{0};
	std::string   loc;
	int           sess{0};
	int           n{1};
	int           missed{0};
	int           pin{0};
	std::string   norm; // cached NormalizeText(text); not written to JSON
};

struct Session {
	int          id{0};
	std::int64_t startTs{0};
};

struct Character {
	std::string              key;
	std::string              keySource; // "playerId" or "nameHash"
	std::vector<std::string> names;
};

struct Capture {
	Kind         kind{Kind::Game};
	std::string  text;
	std::string  title;
	std::string  tag;
	double       gt{0};
	double       ut{-1};
	double       lt{-1};
	std::int64_t ts{0};
	std::string  loc;
	int          missed{0};
	std::uint64_t nowMs{0};
};

struct LogState {
	Character            character;
	std::int64_t         lastPlayedTs{0};
	int                  cap{kHistoryDefault};
	int                  pinCap{kPinCap};
	std::uint64_t        nextId{1};
	int                  nextSess{1};
	std::vector<Session> sessions;
	std::vector<Entry>   entries; // oldest -> newest
};

// Purpose: map a Kind to the JSON "k" token.
// Inputs: kind. Outputs: lowercase token. Dependencies: none.
inline const char* KindKey(Kind a_k)
{
	switch (a_k) {
	case Kind::Medical: return "medical";
	case Kind::Crew: return "crew";
	case Kind::Reaction: return "reaction";
	case Kind::Busy: return "busy";
	case Kind::Crime: return "crime";
	case Kind::Credits: return "credits";
	case Kind::Quest: return "quest";
	case Kind::Location: return "location";
	case Kind::Xp: return "xp";
	case Kind::Game: return "game";
	}
	return "game";
}

// Purpose: parse a JSON "k" token. Unknown tokens become Game.
// Inputs: token. Outputs: Kind. Dependencies: none.
inline Kind KindFromKey(std::string_view a_k)
{
	if (a_k == "medical") return Kind::Medical;
	if (a_k == "crew") return Kind::Crew;
	if (a_k == "reaction") return Kind::Reaction;
	if (a_k == "busy") return Kind::Busy;
	if (a_k == "crime") return Kind::Crime;
	if (a_k == "credits") return Kind::Credits;
	if (a_k == "quest") return Kind::Quest;
	if (a_k == "location") return Kind::Location;
	if (a_k == "xp") return Kind::Xp;
	return Kind::Game;
}

inline std::uint32_t TypeBit(Kind a_k)
{
	switch (a_k) {
	case Kind::Medical: return kTypeMedical;
	case Kind::Crew: return kTypeCrew;
	case Kind::Reaction: return kTypeReaction;
	case Kind::Busy: return kTypeBusy;
	case Kind::Crime: return kTypeCrime;
	case Kind::Credits: return kTypeCredits;
	case Kind::Quest: return kTypeQuest;
	case Kind::Location: return kTypeLocation;
	case Kind::Xp: return kTypeXp;
	case Kind::Game: return kTypeGame;
	}
	return kTypeGame;
}

// Purpose: clamp HistorySize to 100-1000 in steps of 100.
// Inputs: requested size. Outputs: clamped size. Dependencies: none.
inline int ClampHistory(int a_n)
{
	if (a_n < kHistoryMin) a_n = kHistoryMin;
	if (a_n > kHistoryMax) a_n = kHistoryMax;
	a_n = (a_n / kHistoryStep) * kHistoryStep;
	if (a_n < kHistoryMin) a_n = kHistoryMin;
	return a_n;
}

// Purpose: parse LogTypes=medical,crew,... All-on is the default when empty.
// Inputs: comma list. Outputs: bit mask. Dependencies: KindFromKey.
inline std::uint32_t ParseLogTypes(std::string_view a_s)
{
	std::uint32_t bits = 0;
	std::string cur;
	auto flush = [&]() {
		std::string t;
		for (unsigned char c : cur) {
			if (c == ' ' || c == '\t') continue;
			t.push_back(static_cast<char>(std::tolower(c)));
		}
		cur.clear();
		if (t.empty()) return;
		bits |= TypeBit(KindFromKey(t));
	};
	for (char c : a_s) {
		if (c == ',') flush();
		else cur.push_back(c);
	}
	flush();
	return bits ? bits : kTypeAll;
}

// Purpose: old P1 files stored companion reactions as crew + LIKED/LOVED/
// DISLIKED/HATED. Promote those rows to Kind::Reaction on load. No affinity
// value is read. Approved 2026-10-26.
inline bool IsLegacyReactionTag(std::string_view a_tag)
{
	return a_tag == "LIKED" || a_tag == "LOVED" || a_tag == "DISLIKED" || a_tag == "HATED";
}

inline void PromoteLegacyReaction(Entry& a_e)
{
	if (a_e.kind == Kind::Crew && IsLegacyReactionTag(a_e.tag))
		a_e.kind = Kind::Reaction;
}

inline std::string LogTypesText(std::uint32_t a_bits)
{
	std::string o;
	const Kind order[] = {Kind::Medical, Kind::Crew, Kind::Reaction, Kind::Busy, Kind::Crime,
		Kind::Credits, Kind::Quest, Kind::Location, Kind::Xp, Kind::Game};
	for (auto k : order) {
		if (!(a_bits & TypeBit(k))) continue;
		if (!o.empty()) o += ',';
		o += KindKey(k);
	}
	return o;
}

// Purpose: trim, collapse whitespace, case-fold. The dedupe key uses this.
// Inputs: raw text. Outputs: normalized key. Dependencies: hzpreset::IsNbsp.
inline std::string NormalizeText(std::string_view a_s)
{
	std::string t(a_s.begin(), a_s.end());
	t = hzpreset::Trim(t);
	std::string o;
	bool sp = false;
	for (std::size_t i = 0; i < t.size();) {
		std::size_t step = 0;
		const auto c = static_cast<unsigned char>(t[i]);
		if (hzpreset::IsNbsp(t, i, step) || hzpreset::IsWs(c)) {
			if (!o.empty()) sp = true;
			i += step ? step : 1;
			continue;
		}
		if (sp) {
			o += ' ';
			sp = false;
		}
		o += static_cast<char>(std::tolower(c));
		++i;
	}
	return o;
}

inline std::string CapText(std::string_view a_s, std::size_t a_max)
{
	return hzpreset::Utf8Prefix(std::string(a_s.begin(), a_s.end()), a_max);
}

inline bool StartsFold(std::string_view a_s, std::string_view a_pre)
{
	if (a_s.size() < a_pre.size()) return false;
	for (std::size_t i = 0; i < a_pre.size(); ++i) {
		const auto a = static_cast<unsigned char>(a_s[i]);
		const auto b = static_cast<unsigned char>(a_pre[i]);
		if (std::tolower(a) != std::tolower(b)) return false;
	}
	return true;
}

// Purpose: true for untranslated "$..." Scaleform keys. Those are never stored.
// Inputs: raw HUD text. Outputs: true when the trimmed line starts with $.
inline bool IsDollarKey(std::string_view a_s)
{
	auto t = hzmsg::Trim(a_s);
	return !t.empty() && t.front() == '$';
}

inline bool ExactFold(std::string_view a_s, std::string_view a_want)
{
	return a_s.size() == a_want.size() && StartsFold(a_s, a_want);
}

// Purpose: exact save / autosave / quicksave HUD strings and their $...Msg keys.
// Never logged. A quest line such as "Saving the colony" is not a save notice.
// Inputs: raw HUD text. Outputs: true only for the known save notices.
inline bool IsSaveLine(std::string_view a_s)
{
	auto t = hzmsg::Trim(a_s);
	if (t.empty()) return false;
	if (ExactFold(t, "$ManualSaveMsg") || ExactFold(t, "$AutosavingMsg")
		|| ExactFold(t, "$QuickSaveMsg") || ExactFold(t, "$QuicksaveMsg")
		|| ExactFold(t, "$SavingMsg"))
		return true;
	if (IsDollarKey(t)) return false;
	// Exact English GMST text. Ellipsis is ASCII "..." or UTF-8 U+2026 (E2 80 A6).
	if (ExactFold(t, "Saving...") || ExactFold(t, "Saving\xE2\x80\xA6")) return true;
	if (ExactFold(t, "Autosaving...") || ExactFold(t, "Autosaving\xE2\x80\xA6")) return true;
	if (ExactFold(t, "Quicksave...") || ExactFold(t, "Quicksave\xE2\x80\xA6")) return true;
	if (ExactFold(t, "QuickSave...") || ExactFold(t, "QuickSave\xE2\x80\xA6")) return true;
	return false;
}

// Purpose: a real BGSSaveLoadManager::currentPlayerID is required before any
// file is created. A zero id / name-hash key stays memory-only so two new
// characters with the same default name cannot share one file.
// Inputs: character key fields. Outputs: true when disk is allowed.
inline bool PersistAllowed(const Character& a_ch)
{
	return a_ch.keySource == "playerId" && !a_ch.key.empty();
}

inline constexpr int kNameHashSkipLogMs = 10000;

// Purpose: one warning when a write is skipped because the key is still a
// name hash. Rate-limited so Poll does not log every frame.
inline bool NoteNameHashSkip(const Character& a_ch, std::uint64_t a_nowMs, std::uint64_t& a_lastLogMs, int a_gapMs = kNameHashSkipLogMs)
{
	if (PersistAllowed(a_ch)) return false;
	if (a_ch.keySource != "nameHash") return false;
	if (a_lastLogMs && a_nowMs >= a_lastLogMs
		&& (a_nowMs - a_lastLogMs) < static_cast<std::uint64_t>(a_gapMs))
		return false;
	a_lastLogMs = a_nowMs;
	return true;
}

// Purpose: true for "<NPC> CALMED" / creature-calmed HUD lines. Those are
// never stored: no row, no repeat count, no pin. Match sub "calmed", or a
// suffix of the game phrase or the English phrase, ignoring PlainNameOk.
// "is no longer angry" (CALM) and "has already caught you" (CAUGHT) stay.
inline bool IsCalmedLine(std::string_view a_text, const hzmsg::Templates& a_phrases)
{
	const auto line = hzmsg::Trim(a_text);
	if (line.empty()) return false;
	const auto hit = hzmsg::Match(a_text, a_phrases);
	if (hit.ok && hit.sub == "calmed") return true;
	const auto en = hzmsg::English();
	if (hzmsg::EqFold(line, hzmsg::Trim(a_phrases.creature))) return true;
	if (hzmsg::EqFold(line, hzmsg::Trim(en.creature))) return true;
	if (hzmsg::EndsPhrase(line, a_phrases.npcCalmed)) return true;
	if (hzmsg::EndsPhrase(line, en.npcCalmed)) return true;
	return false;
}

// Purpose: classify a HUD sink line with hz_msg_match, including credits.
// Quest / location / XP never come from this path (the movie owns those).
// Companion reactions ("Sam Coe liked that.") are Kind::Reaction: on-screen
// text match only, no affinity or actor values. Approved 2026-10-26.
// Inputs: text and GMST phrases. Outputs: kind, title, tag. Unmatched -> Game.
inline Kind ClassifyHud(std::string_view a_text, const hzmsg::Templates& a_phrases, std::string& a_title, std::string& a_tag)
{
	a_title.clear();
	a_tag.clear();
	const auto hit = hzmsg::Match(a_text, a_phrases);
	if (!hit.ok) {
		a_title = "GAME";
		return Kind::Game;
	}
	a_tag = hit.value;
	if (hit.kind == "medical") {
		a_title = hit.name.empty() ? "MEDICAL" : hit.name;
		return Kind::Medical;
	}
	if (hit.kind == "crew") {
		a_title = hit.name.empty() ? "CREW" : hit.name;
		return Kind::Crew;
	}
	if (hit.kind == "reaction") {
		a_title = hit.name.empty() ? "CREW" : hit.name;
		return Kind::Reaction;
	}
	if (hit.kind == "unavailable" && hit.sub == "busy") {
		a_title = "BUSY";
		return Kind::Busy;
	}
	if (hit.kind == "crime") {
		a_title = "CRIME";
		return Kind::Crime;
	}
	if (hit.kind == "credits") {
		a_title = hit.sub == "kid" ? "KID STUFF" : "CREDITS";
		return Kind::Credits;
	}
	a_title = hit.name.empty() ? "GAME" : hit.name;
	return Kind::Game;
}

// Purpose: hex key from BGSSaveLoadManager::currentPlayerID.
// Inputs: the u64 id. Outputs: uppercase hex, up to 16 digits. 8 digits when
// the id fits in 32 bits; 16 digits when it exceeds 32 bits.
inline std::string HexPlayerId(std::uint64_t a_id)
{
	char b[17];
	if (a_id <= 0xFFFFFFFFull)
		std::snprintf(b, sizeof b, "%08X", static_cast<unsigned>(a_id));
	else
		std::snprintf(b, sizeof b, "%016llX", static_cast<unsigned long long>(a_id));
	return b;
}

// Purpose: FNV-1a of the player name, marked as the fallback key.
// Inputs: display name. Outputs: "<8 hex>-n". Dependencies: none.
inline std::string NameHashKey(std::string_view a_name)
{
	std::uint32_t h = 2166136261u;
	for (unsigned char c : a_name) {
		h ^= static_cast<std::uint32_t>(std::tolower(c));
		h *= 16777619u;
	}
	char b[16];
	std::snprintf(b, sizeof b, "%08X-n", h);
	return b;
}

// Purpose: pick the character file key. A non-zero player id wins. NG+ that
// changes the id starts a new log. A zero id uses a name-hash key in memory
// only; PersistAllowed is false until the first real id.
// Inputs: currentPlayerID and the display name. Outputs: key and keySource.
inline Character MakeCharacter(std::uint64_t a_playerId, std::string_view a_name)
{
	Character c;
	if (a_playerId != 0) {
		c.key = HexPlayerId(a_playerId);
		c.keySource = "playerId";
	} else {
		c.key = NameHashKey(a_name);
		c.keySource = "nameHash";
	}
	const auto n = hzpreset::Trim(std::string(a_name.begin(), a_name.end()));
	if (!n.empty()) c.names.push_back(n);
	return c;
}

inline bool FromLaterPoint(const Entry& a_e, double a_gtNow)
{
	return a_gtNow > 0 && a_e.gt > a_gtNow;
}

// Purpose: join a worker or detach it if it does not finish in a_ms. Used on
// plugin shutdown so ~thread() never calls std::terminate.
// Inputs: joinable thread, the done flag the worker sets, the cv/mutex it
// notifies, timeout in milliseconds.
// Outputs: true when joined, false when detached after the wait.
// Dependencies: the worker must set a_done and notify before it returns.
inline bool JoinOrDetach(std::thread& a_th, std::atomic<bool>& a_done,
	std::condition_variable& a_cv, std::mutex& a_mu, int a_ms)
{
	if (!a_th.joinable()) return true;
	{
		std::unique_lock lk(a_mu);
		if (!a_cv.wait_for(lk, std::chrono::milliseconds(a_ms), [&] { return a_done.load(); })) {
			a_th.detach();
			return false;
		}
	}
	if (a_th.joinable()) a_th.join();
	return true;
}

// Purpose: a live or already-started worker must not be replaced by a second thread.
inline bool WriterStartAllowed(bool a_live, bool a_started)
{
	return !a_live && !a_started;
}

// Purpose: quit flush only queues a last write. AtExit stops the worker.
inline bool ShutdownWriterSetsStop()
{
	return false;
}

// Purpose: a finished joinable worker must be joined before a new thread is
// assigned. Never waits: if done is false the caller must not rebind.
inline bool RebindDoneWriter(std::thread& a_th, bool a_done)
{
	if (!a_th.joinable()) return true;
	if (!a_done) return false;
	try { a_th.join(); } catch (...) { return false; }
	return true;
}

// Purpose: 1 s, 2 s, 4 s … capped at 60 s. Same curve for write, read, and
// promotion retries. Normal writes stay on the 10–15 s debounce.
inline int NextRetryMs(int a_prevMs)
{
	if (a_prevMs < kRetryMsMin) return kRetryMsMin;
	if (a_prevMs >= kRetryMsMax / 2) return kRetryMsMax;
	return a_prevMs * 2;
}

inline bool RetryDue(std::uint64_t a_retryAt, std::uint64_t a_nowMs)
{
	return a_retryAt == 0 || a_nowMs >= a_retryAt;
}

// Purpose: atexit joins only when the worker already set done. Otherwise
// detach. Never take a mutex and never wait: the worker may already be dead.
inline bool AtExitShouldJoin(bool a_done)
{
	return a_done;
}

// Purpose: queue a write when dirty, or when force asks to retry. After a
// failed attempt, wait a_backoffMs unless force is set.
inline bool WriteAllowed(bool a_dirty, bool a_force, std::uint64_t a_lastAttemptMs, std::uint64_t a_nowMs, int a_backoffMs = kRetryMsMin)
{
	if (a_force) return true;
	if (!a_dirty) return false;
	const auto back = a_backoffMs > 0 ? a_backoffMs : kRetryMsMin;
	if (a_lastAttemptMs && a_nowMs >= a_lastAttemptMs
		&& (a_nowMs - a_lastAttemptMs) < static_cast<std::uint64_t>(back))
		return false;
	return true;
}

inline void NoteWriteFailure(bool& a_dirty)
{
	a_dirty = true;
}

inline void NoteWorkerSave(bool a_ok, bool& a_failed)
{
	if (!a_ok) a_failed = true;
}

inline void NoteLoadResult(bool a_ok, bool& a_hold)
{
	a_hold = !a_ok;
}

// Purpose: a successful write clears the write backoff and failure streak.
// Does not touch persistHold: that flag is only for a failed read.
inline void NoteWriteSuccess(int& a_backoffMs, std::uint64_t& a_retryAt)
{
	a_backoffMs = 0;
	a_retryAt = 0;
}

inline bool WriteRecoveredResetsBackoff(bool a_persistHold)
{
	return !a_persistHold;
}

// Purpose: a recover/promote that finishes after BeginLoad belongs to the
// old generation. Discard it so capture does not reopen for the old character.
inline bool LoadResultStale(std::uint64_t a_jobGen, std::uint64_t a_curGen)
{
	return a_jobGen != a_curGen;
}

// Purpose: compare the buffer key captured at queue time, never the
// result's target key. Promotion loads a player-id file into a name-hash
// buffer; those keys differ by design.
inline bool LoadJobBufMismatch(const std::string& a_jobBufKey, const std::string& a_curBufKey)
{
	return !a_jobBufKey.empty() && !a_curBufKey.empty() && a_jobBufKey != a_curBufKey;
}

inline bool LoadApplyStale(std::uint64_t a_jobGen, std::uint64_t a_curGen,
	const std::string& a_jobBufKey, const std::string& a_curBufKey)
{
	return LoadResultStale(a_jobGen, a_curGen) || LoadJobBufMismatch(a_jobBufKey, a_curBufKey);
}

inline void CopyLoadJobTag(std::uint64_t a_jobGen, const std::string& a_jobBufKey,
	std::uint64_t& a_outGen, std::string& a_outBufKey)
{
	a_outGen = a_jobGen;
	a_outBufKey = a_jobBufKey;
}

inline bool ShouldClearRecoverBusy(std::uint64_t a_jobGen, std::uint64_t a_inFlightGen)
{
	return a_jobGen == a_inFlightGen;
}

inline bool ApplyReopensCapture(bool a_jobHoldFlush, bool a_holdFlush)
{
	return !a_jobHoldFlush && !a_holdFlush;
}

inline bool MergeKeptKeyOk(const std::string& a_key, const std::string& a_parked)
{
	return !a_key.empty() && !a_parked.empty() && a_key == a_parked;
}

inline bool ShouldKeepHeldRows(bool a_hold, std::size_t a_count)
{
	return a_hold && a_count > 0;
}

inline bool ShouldParkDirtyRows(bool a_dirty, bool a_allowed, std::size_t a_count)
{
	return a_dirty && a_allowed && a_count > 0;
}

// Purpose: RequestWrite clears dirty before the worker finishes. HUD-ready
// treats an in-flight save as dirty so those rows are parked.
inline bool PendingCountsAsDirty(bool a_dirty, bool a_pending)
{
	return a_dirty || a_pending;
}

// Purpose: a failed save for another character parks that job. Same-key
// failures stay on the live buffer. Never park an empty key.
inline bool WriteFailParksJob(const std::string& a_jobKey, const std::string& a_curKey)
{
	return !a_jobKey.empty() && a_jobKey != a_curKey;
}

// Purpose: the same parked event is the same kind, normalized text, and
// exact timestamp. Ids are unused: a held or name-hash session restarts
// nextId at 1, so those ids are unrelated to the file.
inline bool SameParkedRow(const Entry& a_a, const Entry& a_b)
{
	if (a_a.kind != a_b.kind)
		return false;
	if (a_a.ts != a_b.ts)
		return false;
	const auto na = a_a.norm.empty() ? NormalizeText(a_a.text) : a_a.norm;
	const auto nb = a_b.norm.empty() ? NormalizeText(a_b.text) : a_b.norm;
	return na == nb;
}

inline bool HasSameParkedRow(const std::vector<Entry>& a_rows, const Entry& a_in)
{
	for (const auto& e : a_rows) {
		if (SameParkedRow(e, a_in))
			return true;
	}
	return false;
}

// Purpose: same kind + normalized text + exact timestamp keeps the larger n
// so a same-second repeat is not lost after a load or merge.
inline bool KeepLargerParkedN(Entry& a_have, const Entry& a_in)
{
	if (a_in.n > a_have.n) {
		a_have.n = a_in.n;
		return true;
	}
	return false;
}

// Purpose: dirty-park merge skips rows already in the file (same kind,
// normalized text, and timestamp). Larger n is applied by the caller.
inline std::vector<Entry> ExactParkedNew(const std::vector<Entry>& a_have, const std::vector<Entry>& a_in)
{
	std::vector<Entry> out;
	out.reserve(a_in.size());
	for (const auto& in : a_in) {
		if (!HasSameParkedRow(a_have, in))
			out.push_back(in);
	}
	return out;
}

inline bool WritePendingClears(std::uint64_t a_doneSeq, std::uint64_t a_pendingSeq)
{
	return a_doneSeq != 0 && a_doneSeq == a_pendingSeq;
}

inline bool WriteJobStillCurrent(std::uint64_t a_jobSeq, std::uint64_t a_liveSeq)
{
	return a_jobSeq != 0 && a_jobSeq == a_liveSeq;
}

inline void InvalidateInFlightWrite(std::uint64_t& a_liveSeq, bool& a_pending, std::uint64_t& a_pendingSeq)
{
	++a_liveSeq;
	a_pending = false;
	a_pendingSeq = 0;
}

inline bool LastPlayedKnown(std::int64_t a_ts)
{
	return a_ts >= kLastPlayedEpochMin;
}

inline std::int64_t LastPlayedDisplay(std::int64_t a_ts, std::int64_t a_fileMtime)
{
	return LastPlayedKnown(a_ts) ? a_ts : a_fileMtime;
}

inline std::int64_t EpochSeconds()
{
	return static_cast<std::int64_t>(std::time(nullptr));
}

// Purpose: a failed promote/recover for a name-hash buffer parks under the
// player-id target. Other buffers keep their own key.
inline std::string ParkHeldKey(const Character& a_ch, const std::string& a_holdTarget)
{
	if (a_ch.keySource == "nameHash" && !a_holdTarget.empty())
		return a_holdTarget;
	return a_ch.key;
}

// Purpose: drop the oldest unpinned rows. Pins and the newest rows stay.
inline void CapKeptHeld(std::vector<Entry>& a_rows, std::size_t a_cap)
{
	if (a_rows.size() <= a_cap) return;
	std::vector<Entry> pins;
	std::vector<Entry> rest;
	pins.reserve(a_rows.size());
	rest.reserve(a_rows.size());
	for (auto& e : a_rows) {
		if (e.pin) pins.push_back(std::move(e));
		else rest.push_back(std::move(e));
	}
	const auto keepRest = a_cap > pins.size() ? a_cap - pins.size() : 0;
	if (rest.size() > keepRest) {
		const auto drop = rest.size() - keepRest;
		rest.erase(rest.begin(), rest.begin() + drop);
	}
	a_rows.clear();
	a_rows.reserve(pins.size() + rest.size());
	for (auto& e : pins) a_rows.push_back(std::move(e));
	for (auto& e : rest) a_rows.push_back(std::move(e));
}

// Purpose: append parked rows, keep the larger n on an exact match, then cap.
inline void AppendParkedRows(std::vector<Entry>& a_dst, const std::vector<Entry>& a_src)
{
	for (const auto& in : a_src) {
		bool found = false;
		for (auto& e : a_dst) {
			if (!SameParkedRow(e, in)) continue;
			KeepLargerParkedN(e, in);
			found = true;
			break;
		}
		if (!found)
			a_dst.push_back(in);
	}
	CapKeptHeld(a_dst, static_cast<std::size_t>(kKeptHeldCap));
}

// Purpose: first promote/recover may run immediately. After a hold, wait
// until retryAt. Used so the game thread never re-reads every frame.
inline bool HoldRetryDue(bool a_hold, std::uint64_t a_retryAt, std::uint64_t a_nowMs)
{
	if (!a_hold) return true;
	return RetryDue(a_retryAt, a_nowMs);
}

inline bool WithinDedupeWindow(std::int64_t a_dtMs, int a_winMs)
{
	const auto dt = a_dtMs < 0 ? -a_dtMs : a_dtMs;
	return dt <= static_cast<std::int64_t>(a_winMs);
}

// Purpose: one transient .bak copy failure still aborts the save. After
// kBakFailGiveUp consecutive failures, the atomic replace may proceed.
inline bool BakCopyBlocksReplace(int a_fails, int a_giveUp = kBakFailGiveUp)
{
	return a_fails > 0 && a_fails < a_giveUp;
}

struct FileRead {
	bool        tooLarge{false};
	bool        missing{false};
	bool        ok{false};
	std::string body;
	std::string notice;
};

// Purpose: .bad is only for a too-large file or a parse failure (depth, type,
// truncated JSON). A sharing violation or a transient open/stat/read error
// leaves the original file so the next load can retry.
inline bool ShouldQuarantine(const FileRead& a_rd, bool a_parseCorrupt)
{
	return a_rd.tooLarge || a_parseCorrupt;
}

// Purpose: stat the log file first and refuse anything over 4 MiB without reading.
// Inputs: path. Outputs: FileRead (body stays empty when tooLarge).
inline FileRead ReadLogFile(const std::filesystem::path& a_path)
{
	FileRead r;
	std::error_code ec;
	if (!std::filesystem::is_regular_file(a_path, ec)) {
		r.missing = true;
		r.ok = true;
		return r;
	}
	const auto sz = std::filesystem::file_size(a_path, ec);
	if (ec) {
		r.notice = "stat failed";
		return r;
	}
	if (sz > static_cast<std::uintmax_t>(kFileMaxBytes)) {
		r.tooLarge = true;
		r.notice = "file too large";
		return r;
	}
	std::ifstream f(a_path, std::ios::binary);
	if (!f) {
		r.notice = "open failed";
		return r;
	}
	r.body.resize(static_cast<std::size_t>(sz));
	if (sz != 0 && !f.read(r.body.data(), static_cast<std::streamsize>(sz))) {
		r.body.clear();
		r.notice = "read failed";
		return r;
	}
	r.ok = true;
	return r;
}

// Purpose: next launch session id. Persist nextSess, then take the max of
// that value, max(entry sess)+1, and max(session id)+1 so old all-1 files
// also get a new id.
inline int ResolveNextSess(int a_nextSess, const std::vector<Session>& a_sessions, const std::vector<Entry>& a_entries)
{
	int n = a_nextSess > 0 ? a_nextSess : 1;
	for (const auto& e : a_entries)
		if (e.sess + 1 > n) n = e.sess + 1;
	for (const auto& s : a_sessions)
		if (s.id + 1 > n) n = s.id + 1;
	return n;
}

// ---------------------------------------------------------------------------
// In-memory ring + pins
// ---------------------------------------------------------------------------

class Buffer {
public:
	Settings  settings;
	Character character;
	std::int64_t lastPlayedTs{0};
	std::uint64_t nextId{1};
	int       sess{1};
	std::int64_t sessStartTs{0};
	std::vector<Session> sessions;
	std::vector<Entry> entries; // oldest -> newest

	int Cap() const { return ClampHistory(settings.historySize); }

	int UnpinnedCount() const
	{
		int n = 0;
		for (const auto& e : entries)
			if (!e.pin) ++n;
		return n;
	}

	int PinCount() const
	{
		int n = 0;
		for (const auto& e : entries)
			if (e.pin) ++n;
		return n;
	}

	const Entry* FindId(std::uint64_t a_id) const
	{
		for (const auto& e : entries)
			if (e.id == a_id) return &e;
		return nullptr;
	}

	Entry* FindIdMut(std::uint64_t a_id)
	{
		for (auto& e : entries)
			if (e.id == a_id) return &e;
		return nullptr;
	}

	void StartSession(std::int64_t a_ts)
	{
		sessStartTs = a_ts;
		sessions.push_back(Session{sess, a_ts});
	}

	// Purpose: apply a capture. Saving lines return SaveSignal and are not stored.
	// Record=0, a type that is off, or a missing module reject the line.
	// A match inside the dedupe window increments n (cap 999) and moves the row.
	// Inputs: capture (text, kind, times, location). Outputs: OfferResult.
	OfferResult Offer(Capture a)
	{
		if (IsSaveLine(a.text) || IsDollarKey(a.text)) {
			if (IsSaveLine(a.text)) return OfferResult::SaveSignal;
			return OfferResult::Rejected;
		}
		if (!settings.record || !settings.modulePresent) return OfferResult::Rejected;
		if (!(settings.logTypes & TypeBit(a.kind))) return OfferResult::Rejected;
		a.text = CapText(hzpreset::Trim(a.text), kTextCap);
		if (a.text.empty()) return OfferResult::Rejected;
		if (a.kind == Kind::Location && suppressFirstLoc_) {
			suppressFirstLoc_ = false;
			const auto key = NormalizeText(a.text);
			if (!lastLocNorm_.empty() && key == lastLocNorm_)
				return OfferResult::Rejected;
		}
		a.loc = CapText(a.loc, kLocCap);
		a.title = CapText(a.title, 64);
		a.tag = CapText(a.tag, 32);
		const auto key = NormalizeText(a.text);
		const int win = a.kind == Kind::Busy ? kBusyDedupeMs : kDedupeMs;
		return OfferDedupe(a, key, win);
	}

	bool Pin(std::uint64_t a_id)
	{
		for (auto& e : entries) {
			if (e.id != a_id) continue;
			if (e.pin) return true;
			if (PinCount() >= kPinCap) return false;
			e.pin = 1;
			return true;
		}
		return false;
	}

	bool Unpin(std::uint64_t a_id)
	{
		for (auto& e : entries) {
			if (e.id != a_id) continue;
			e.pin = 0;
			Evict();
			return true;
		}
		return false;
	}

	// Purpose: drop unpinned rows whose in-game time is later than now.
	// Pins stay and are flagged by FromLaterPoint. A null/zero clock is a no-op.
	// Inputs: Calendar::GetDaysPassedExact(). Outputs: number of dropped rows.
	int Prune(double a_gtNow)
	{
		if (a_gtNow <= 0) return 0;
		double newest = 0;
		for (const auto& e : entries)
			if (e.gt > newest) newest = e.gt;
		if (newest <= a_gtNow) return 0;
		const auto before = entries.size();
		std::vector<Entry> keep;
		keep.reserve(entries.size());
		for (auto& e : entries) {
			if (e.pin || e.gt <= a_gtNow) keep.push_back(std::move(e));
		}
		entries.swap(keep);
		return static_cast<int>(before - entries.size());
	}

	void ClearSession()
	{
		std::vector<Entry> keep;
		for (auto& e : entries) {
			if (e.sess != sess || e.pin) keep.push_back(std::move(e));
		}
		entries.swap(keep);
	}

	void ClearHistory()
	{
		entries.clear();
	}

	void SetHistorySize(int a_n)
	{
		settings.historySize = ClampHistory(a_n);
		Evict();
	}

	void RememberName(std::string_view a_name)
	{
		const auto n = hzpreset::Trim(std::string(a_name.begin(), a_name.end()));
		if (n.empty()) return;
		for (const auto& have : character.names)
			if (have == n) return;
		character.names.push_back(n);
	}

	LogState Snapshot() const
	{
		LogState s;
		s.character = character;
		s.lastPlayedTs = lastPlayedTs;
		s.cap = Cap();
		s.pinCap = kPinCap;
		s.nextId = nextId;
		s.nextSess = sess + 1;
		s.sessions = sessions;
		s.entries = entries;
		return s;
	}

	void LoadState(LogState s)
	{
		character = std::move(s.character);
		lastPlayedTs = s.lastPlayedTs;
		settings.historySize = ClampHistory(s.cap > 0 ? s.cap : settings.historySize);
		nextId = s.nextId ? s.nextId : 1;
		sessions = std::move(s.sessions);
		entries = std::move(s.entries);
		sess = ResolveNextSess(s.nextSess, sessions, entries);
		NoteLocationLoad();
		int pins = 0;
		for (auto& e : entries) {
			if (e.norm.empty()) e.norm = NormalizeText(e.text);
			if (e.pin) {
				++pins;
				if (pins > kPinCap) e.pin = 0;
			}
			if (e.id >= nextId) nextId = e.id + 1;
		}
		Evict();
		ClearDedupeClock();
	}

	void ResetMemory()
	{
		entries.clear();
		sessions.clear();
		nextId = 1;
		sess = 1;
		sessStartTs = 0;
		lastPlayedTs = 0;
		suppressFirstLoc_ = false;
		lastLocNorm_.clear();
		ClearDedupeClock();
	}

	void SortByTime()
	{
		std::sort(entries.begin(), entries.end(), [](const Entry& a, const Entry& b) {
			if (a.ts != b.ts) return a.ts < b.ts;
			if (a.gt != b.gt) return a.gt < b.gt;
			return a.id < b.id;
		});
		ClearDedupeClock();
	}

	bool DedupeClockClear() const
	{
		if (lastMs_.size() != entries.size()) return false;
		for (auto t : lastMs_)
			if (t) return false;
		return true;
	}

	// Purpose: fold a name-hash session into a loaded player-id file.
	// Same kind + normalized text fold only when |dt| <= the 3 s window
	// (Busy 10 s). Appended rows get nextId++ and keep their pin. File pins
	// are counted first so they win the 50-pin cap. Then sort and evict.
	// Inputs: in-memory session rows. Outputs: this buffer.
	void MergeSession(const std::vector<Entry>& a_session)
	{
		for (const auto& in : a_session) {
			const auto key = in.norm.empty() ? NormalizeText(in.text) : in.norm;
			const int win = in.kind == Kind::Busy ? kBusyDedupeMs : kDedupeMs;
			Entry* hit = nullptr;
			for (std::size_t i = entries.size(); i-- > 0;) {
				auto& e = entries[i];
				if (e.kind != in.kind) continue;
				if (e.norm.empty()) e.norm = NormalizeText(e.text);
				if (e.norm != key) continue;
				const auto dt = in.ts >= e.ts ? (in.ts - e.ts) : (e.ts - in.ts);
				if (WithinDedupeWindow(dt * 1000, win)) {
					hit = &e;
					break;
				}
			}
			if (hit) {
				hit->n += in.n > 0 ? in.n : 1;
				if (hit->n > kRepeatCap) hit->n = kRepeatCap;
				if (in.ts >= hit->ts) {
					hit->ts = in.ts;
					hit->gt = in.gt;
					hit->ut = in.ut;
					hit->lt = in.lt;
					if (!in.loc.empty()) hit->loc = in.loc;
				}
				if (in.pin) hit->pin = 1;
			} else {
				Entry e = in;
				if (e.norm.empty()) e.norm = key;
				e.id = nextId++;
				e.pin = in.pin ? 1 : 0;
				entries.push_back(std::move(e));
			}
		}
		int pins = 0;
		for (auto& e : entries) {
			if (!e.pin) continue;
			++pins;
			if (pins > kPinCap) e.pin = 0;
		}
		SortByTime();
		Evict();
		ClearDedupeClock();
	}

private:
	std::vector<std::uint64_t> lastMs_;
	bool        suppressFirstLoc_{false};
	std::string lastLocNorm_;

	void NoteLocationLoad()
	{
		suppressFirstLoc_ = false;
		lastLocNorm_.clear();
		for (auto it = entries.rbegin(); it != entries.rend(); ++it) {
			if (it->kind != Kind::Location) continue;
			lastLocNorm_ = it->norm.empty() ? NormalizeText(it->text) : it->norm;
			suppressFirstLoc_ = !lastLocNorm_.empty();
			return;
		}
	}

	void ClearDedupeClock()
	{
		lastMs_.assign(entries.size(), 0);
	}

	OfferResult OfferDedupe(Capture& a, const std::string& a_key, int a_win)
	{
		if (lastMs_.size() != entries.size()) lastMs_.resize(entries.size(), 0);
		const auto now = a.nowMs ? a.nowMs : static_cast<std::uint64_t>(a.ts);
		for (std::size_t i = entries.size(); i-- > 0;) {
			auto& e = entries[i];
			if (e.kind != a.kind) continue;
			const auto seen = lastMs_[i] ? lastMs_[i] : 0;
			if (seen && now >= seen && (now - seen) > static_cast<std::uint64_t>(a_win))
				break;
			if (e.norm.empty()) e.norm = NormalizeText(e.text);
			if (e.norm != a_key) continue;
			if (now >= seen && (now - seen) <= static_cast<std::uint64_t>(a_win)) {
				if (e.n < kRepeatCap) ++e.n;
				e.ts = a.ts;
				e.gt = a.gt;
				e.ut = a.ut;
				e.lt = a.lt;
				if (!a.loc.empty()) e.loc = a.loc;
				lastMs_[i] = now;
				if (i + 1 != entries.size()) {
					auto moved = std::move(e);
					const auto ms = lastMs_[i];
					entries.erase(entries.begin() + static_cast<std::ptrdiff_t>(i));
					lastMs_.erase(lastMs_.begin() + static_cast<std::ptrdiff_t>(i));
					entries.push_back(std::move(moved));
					lastMs_.push_back(ms);
				}
				return OfferResult::Deduped;
			}
			break;
		}
		Entry e;
		e.id = nextId++;
		e.kind = a.kind;
		e.text = std::move(a.text);
		e.title = std::move(a.title);
		e.tag = std::move(a.tag);
		e.gt = a.gt;
		e.ut = a.ut;
		e.lt = a.lt;
		e.ts = a.ts;
		e.loc = std::move(a.loc);
		e.sess = sess;
		e.n = 1;
		e.missed = a.missed;
		e.pin = 0;
		e.norm = a_key;
		entries.push_back(std::move(e));
		lastMs_.push_back(a.nowMs ? a.nowMs : static_cast<std::uint64_t>(a.ts));
		Evict();
		return OfferResult::Stored;
	}

	void Evict()
	{
		const int cap = Cap();
		while (UnpinnedCount() > cap) {
			for (std::size_t i = 0; i < entries.size(); ++i) {
				if (entries[i].pin) continue;
				entries.erase(entries.begin() + static_cast<std::ptrdiff_t>(i));
				if (i < lastMs_.size()) lastMs_.erase(lastMs_.begin() + static_cast<std::ptrdiff_t>(i));
				break;
			}
		}
		if (lastMs_.size() != entries.size()) lastMs_.resize(entries.size(), 0);
	}
};

// P2 data link: the movie polls this snapshot. No IO. Size is capped.
enum class ViewStatus : std::uint8_t {
	Ok = 0,
	Saving,
	MemoryOnly,
	Paused,
	KeyFallback
};

struct ViewEntry {
	std::uint64_t id{0};
	Kind          kind{Kind::Game};
	std::string   title;
	std::string   text;
	std::string   tag;
	std::string   loc;
	int           n{1};
	int           pin{0};
	int           missed{0};
	int           sess{0};
	std::int64_t  ts{0};
	double        gt{0};
	double        ut{-1};
	double        lt{-1};
	bool          fromLater{false};
};

struct ViewSnap {
	std::vector<ViewEntry> entries;
	int                    pinCount{0};
	int                    pinCap{kPinCap};
	int                    sess{0};
	std::int64_t           sessStartTs{0};
	ViewStatus             status{ViewStatus::Ok};
};

inline constexpr int kViewEntryCap = kLoadEntryCap;

inline ViewStatus ClassifyViewStatus(const Settings& a_s, const Character& a_ch, bool a_saving, bool a_paused)
{
	if (a_ch.keySource == "nameHash") return ViewStatus::KeyFallback;
	if (!a_s.persist) return ViewStatus::MemoryOnly;
	if (!a_s.record || a_paused) return ViewStatus::Paused;
	if (a_saving) return ViewStatus::Saving;
	return ViewStatus::Ok;
}

// Purpose: copy a capped view of the buffer for the movie. Never reads disk.
// Inputs: buffer, current game time, status. Outputs: ViewSnap.
inline ViewSnap BuildView(const Buffer& a_buf, double a_gtNow, ViewStatus a_status)
{
	ViewSnap v;
	v.pinCount = a_buf.PinCount();
	v.pinCap = kPinCap;
	v.sess = a_buf.sess;
	v.sessStartTs = a_buf.sessStartTs;
	v.status = a_status;
	const auto n = a_buf.entries.size();
	const auto start = n > static_cast<std::size_t>(kViewEntryCap)
		? n - static_cast<std::size_t>(kViewEntryCap) : 0;
	v.entries.reserve(n - start);
	for (std::size_t i = start; i < n; ++i) {
		const auto& e = a_buf.entries[i];
		ViewEntry row;
		row.id = e.id;
		row.kind = e.kind;
		row.title = e.title;
		row.text = e.text;
		row.tag = e.tag;
		row.loc = e.loc;
		row.n = e.n;
		row.pin = e.pin;
		row.missed = e.missed;
		row.sess = e.sess;
		row.ts = e.ts;
		row.gt = e.gt;
		row.ut = e.ut;
		row.lt = e.lt;
		row.fromLater = FromLaterPoint(e, a_gtNow);
		v.entries.push_back(std::move(row));
	}
	return v;
}

// ---------------------------------------------------------------------------
// JSON
// ---------------------------------------------------------------------------

inline void JsonEsc(std::string& a_o, std::string_view a_s)
{
	a_o.push_back('"');
	for (unsigned char c : a_s) {
		if (c == '"' || c == '\\') {
			a_o.push_back('\\');
			a_o.push_back(static_cast<char>(c));
		} else if (c == '\n') {
			a_o += "\\n";
		} else if (c == '\r') {
			a_o += "\\r";
		} else if (c == '\t') {
			a_o += "\\t";
		} else if (c < 32) {
			char b[8];
			std::snprintf(b, sizeof b, "\\u%04X", c);
			a_o += b;
		} else {
			a_o.push_back(static_cast<char>(c));
		}
	}
	a_o.push_back('"');
}

inline std::string JsonNumber(double a_v)
{
	char b[64];
	std::snprintf(b, sizeof b, "%.6g", a_v);
	return b;
}

// Purpose: write one log file body, oldest -> newest, already trimmed.
// Inputs: state and the plugin version string. Outputs: JSON text.
inline std::string ToJson(const LogState& a_s, std::string_view a_plugin)
{
	std::string o;
	o += "{\n  \"type\": ";
	JsonEsc(o, kJsonType);
	o += ", \"version\": ";
	o += std::to_string(kJsonVersion);
	o += ", \"plugin\": ";
	JsonEsc(o, a_plugin);
	o += ",\n  \"character\": { \"key\": ";
	JsonEsc(o, a_s.character.key);
	o += ", \"keySource\": ";
	JsonEsc(o, a_s.character.keySource);
	o += ", \"names\": [";
	for (std::size_t i = 0; i < a_s.character.names.size(); ++i) {
		if (i) o += ", ";
		JsonEsc(o, a_s.character.names[i]);
	}
	o += "] },\n  \"lastPlayedTs\": ";
	o += std::to_string(a_s.lastPlayedTs);
	o += ", \"cap\": ";
	o += std::to_string(a_s.cap);
	o += ", \"pinCap\": ";
	o += std::to_string(a_s.pinCap);
	o += ", \"nextSess\": ";
	o += std::to_string(a_s.nextSess);
	o += ",\n  \"sessions\": [";
	for (std::size_t i = 0; i < a_s.sessions.size(); ++i) {
		if (i) o += ", ";
		o += "{ \"id\": ";
		o += std::to_string(a_s.sessions[i].id);
		o += ", \"startTs\": ";
		o += std::to_string(a_s.sessions[i].startTs);
		o += " }";
	}
	o += "],\n  \"entries\": [\n";
	for (std::size_t i = 0; i < a_s.entries.size(); ++i) {
		const auto& e = a_s.entries[i];
		o += "    { \"id\": ";
		o += std::to_string(e.id);
		o += ", \"k\": ";
		JsonEsc(o, KindKey(e.kind));
		o += ", \"t\": ";
		JsonEsc(o, e.text);
		o += ", \"title\": ";
		JsonEsc(o, e.title);
		o += ", \"tag\": ";
		JsonEsc(o, e.tag);
		o += ", \"gt\": ";
		o += JsonNumber(e.gt);
		o += ", \"ut\": ";
		o += JsonNumber(e.ut);
		o += ", \"lt\": ";
		o += JsonNumber(e.lt);
		o += ", \"ts\": ";
		o += std::to_string(e.ts);
		o += ", \"loc\": ";
		JsonEsc(o, e.loc);
		o += ", \"sess\": ";
		o += std::to_string(e.sess);
		o += ", \"n\": ";
		o += std::to_string(e.n);
		o += ", \"missed\": ";
		o += std::to_string(e.missed);
		o += ", \"pin\": ";
		o += std::to_string(e.pin);
		o += " }";
		if (i + 1 < a_s.entries.size()) o += ",";
		o += "\n";
	}
	o += "  ]\n}\n";
	return o;
}

// Purpose: writer cap. Drop the oldest unpinned rows until ToJson is at most
// 3 MiB. Pins stay even if the file is still over the cap.
inline void EvictUnpinnedToBytes(LogState& a_s, std::size_t a_max, std::string_view a_plugin)
{
	for (;;) {
		if (ToJson(a_s, a_plugin).size() <= a_max) return;
		bool dropped = false;
		for (auto it = a_s.entries.begin(); it != a_s.entries.end(); ++it) {
			if (it->pin) continue;
			a_s.entries.erase(it);
			dropped = true;
			break;
		}
		if (!dropped) return;
	}
}

struct JsonTok {
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
	bool Peek(char c)
	{
		Skip();
		return p < e && *p == c;
	}
};

inline bool JsonString(JsonTok& a_t, std::string& a_o)
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
				a_t.p += 4;
				a_o += '?';
			} else
				a_o += c;
		} else {
			a_o += c;
		}
	}
	return false;
}

inline bool JsonNumberTok(JsonTok& a_t, double& a_o)
{
	a_t.Skip();
	char* end = nullptr;
	a_o = std::strtod(a_t.p, &end);
	if (end == a_t.p) return false;
	a_t.p = end;
	return true;
}

inline bool JsonIntTok(JsonTok& a_t, std::int64_t& a_o)
{
	double d = 0;
	if (!JsonNumberTok(a_t, d)) return false;
	a_o = static_cast<std::int64_t>(d);
	return true;
}

inline bool JsonSkipValue(JsonTok& a_t, int a_depth);

inline bool JsonSkipObject(JsonTok& a_t, int a_depth)
{
	if (a_depth > kJsonMaxDepth) return false;
	if (!a_t.Eat('{')) return false;
	if (a_t.Eat('}')) return true;
	for (;;) {
		std::string k;
		if (!JsonString(a_t, k) || !a_t.Eat(':') || !JsonSkipValue(a_t, a_depth + 1)) return false;
		if (a_t.Eat('}')) return true;
		if (!a_t.Eat(',')) return false;
	}
}

inline bool JsonSkipArray(JsonTok& a_t, int a_depth)
{
	if (a_depth > kJsonMaxDepth) return false;
	if (!a_t.Eat('[')) return false;
	if (a_t.Eat(']')) return true;
	for (;;) {
		if (!JsonSkipValue(a_t, a_depth + 1)) return false;
		if (a_t.Eat(']')) return true;
		if (!a_t.Eat(',')) return false;
	}
}

inline bool JsonSkipValue(JsonTok& a_t, int a_depth)
{
	if (a_depth > kJsonMaxDepth) return false;
	a_t.Skip();
	if (a_t.p >= a_t.e) return false;
	if (*a_t.p == '"') {
		std::string s;
		return JsonString(a_t, s);
	}
	if (*a_t.p == '{') return JsonSkipObject(a_t, a_depth);
	if (*a_t.p == '[') return JsonSkipArray(a_t, a_depth);
	if (std::strncmp(a_t.p, "true", 4) == 0) {
		a_t.p += 4;
		return true;
	}
	if (std::strncmp(a_t.p, "false", 5) == 0) {
		a_t.p += 5;
		return true;
	}
	if (std::strncmp(a_t.p, "null", 4) == 0) {
		a_t.p += 4;
		return true;
	}
	double d = 0;
	return JsonNumberTok(a_t, d);
}

inline bool ParseEntry(JsonTok& a_t, Entry& a_e, bool& a_usable)
{
	a_usable = false;
	if (!a_t.Eat('{')) return false;
	bool haveT = false, haveK = false;
	if (a_t.Eat('}')) return true;
	for (;;) {
		std::string key;
		if (!JsonString(a_t, key) || !a_t.Eat(':')) return false;
		if (key == "id") {
			std::int64_t v = 0;
			if (!JsonIntTok(a_t, v)) return false;
			a_e.id = static_cast<std::uint64_t>(v);
		} else if (key == "k") {
			std::string v;
			if (!JsonString(a_t, v)) return false;
			a_e.kind = KindFromKey(v);
			haveK = true;
		} else if (key == "t") {
			if (!JsonString(a_t, a_e.text)) return false;
			haveT = true;
		} else if (key == "title") {
			if (!JsonString(a_t, a_e.title)) return false;
		} else if (key == "tag") {
			if (!JsonString(a_t, a_e.tag)) return false;
		} else if (key == "gt") {
			if (!JsonNumberTok(a_t, a_e.gt)) return false;
		} else if (key == "ut") {
			if (!JsonNumberTok(a_t, a_e.ut)) return false;
		} else if (key == "lt") {
			if (!JsonNumberTok(a_t, a_e.lt)) return false;
		} else if (key == "ts") {
			if (!JsonIntTok(a_t, a_e.ts)) return false;
		} else if (key == "loc") {
			if (!JsonString(a_t, a_e.loc)) return false;
		} else if (key == "sess") {
			std::int64_t v = 0;
			if (!JsonIntTok(a_t, v)) return false;
			a_e.sess = static_cast<int>(v);
		} else if (key == "n") {
			std::int64_t v = 0;
			if (!JsonIntTok(a_t, v)) return false;
			a_e.n = static_cast<int>(v);
			if (a_e.n < 1) a_e.n = 1;
			if (a_e.n > kRepeatCap) a_e.n = kRepeatCap;
		} else if (key == "missed") {
			std::int64_t v = 0;
			if (!JsonIntTok(a_t, v)) return false;
			a_e.missed = static_cast<int>(v);
		} else if (key == "pin") {
			std::int64_t v = 0;
			if (!JsonIntTok(a_t, v)) return false;
			a_e.pin = v ? 1 : 0;
		} else if (!JsonSkipValue(a_t, 1)) {
			return false;
		}
		if (a_t.Eat('}')) break;
		if (!a_t.Eat(',')) return false;
	}
	if (!haveT || !haveK || a_e.text.empty()) return true;
	a_e.text = CapText(a_e.text, kTextCap);
	a_e.loc = CapText(a_e.loc, kLocCap);
	PromoteLegacyReaction(a_e);
	a_usable = true;
	return true;
}

struct ParseResult {
	bool        ok{false};
	bool        corrupt{false};
	std::string notice;
	LogState    state;
};

// Purpose: parse a log file. Bad JSON, the wrong type, a too-new version, or
// a file over 4 MiB is corrupt. Malformed entries are skipped.
// Inputs: file bytes. Outputs: ParseResult. Dependencies: none.
inline ParseResult FromJson(std::string_view a_text)
{
	ParseResult r;
	if (a_text.size() > static_cast<std::size_t>(kFileMaxBytes)) {
		r.corrupt = true;
		r.notice = "file too large";
		return r;
	}
	JsonTok t{a_text.data(), a_text.data() + a_text.size()};
	if (!t.Eat('{')) {
		r.corrupt = true;
		r.notice = "bad json";
		return r;
	}
	std::string type;
	int version = 0;
	bool haveType = false, haveVer = false;
	r.state.cap = kHistoryDefault;
	r.state.pinCap = kPinCap;
	r.state.nextId = 1;
	if (t.Eat('}')) {
		r.corrupt = true;
		r.notice = "empty object";
		return r;
	}
	for (;;) {
		std::string key;
		if (!JsonString(t, key) || !t.Eat(':')) {
			r.corrupt = true;
			r.notice = "bad json";
			return r;
		}
		if (key == "type") {
			if (!JsonString(t, type)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			haveType = true;
		} else if (key == "version") {
			std::int64_t v = 0;
			if (!JsonIntTok(t, v)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			version = static_cast<int>(v);
			haveVer = true;
		} else if (key == "plugin") {
			std::string s;
			if (!JsonString(t, s)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
		} else if (key == "character") {
			if (!t.Eat('{')) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			if (!t.Eat('}')) {
				for (;;) {
					std::string ck;
					if (!JsonString(t, ck) || !t.Eat(':')) {
						r.corrupt = true;
						r.notice = "bad json";
						return r;
					}
					if (ck == "key") {
						if (!JsonString(t, r.state.character.key)) {
							r.corrupt = true;
							r.notice = "bad json";
							return r;
						}
					} else if (ck == "keySource") {
						if (!JsonString(t, r.state.character.keySource)) {
							r.corrupt = true;
							r.notice = "bad json";
							return r;
						}
					} else if (ck == "names") {
						if (!t.Eat('[')) {
							r.corrupt = true;
							r.notice = "bad json";
							return r;
						}
						if (!t.Eat(']')) {
							for (;;) {
								std::string nm;
								if (!JsonString(t, nm)) {
									r.corrupt = true;
									r.notice = "bad json";
									return r;
								}
								if (!nm.empty()) r.state.character.names.push_back(nm);
								if (t.Eat(']')) break;
								if (!t.Eat(',')) {
									r.corrupt = true;
									r.notice = "bad json";
									return r;
								}
							}
						}
					} else if (!JsonSkipValue(t, 1)) {
						r.corrupt = true;
						r.notice = "bad json";
						return r;
					}
					if (t.Eat('}')) break;
					if (!t.Eat(',')) {
						r.corrupt = true;
						r.notice = "bad json";
						return r;
					}
				}
			}
		} else if (key == "lastPlayedTs") {
			if (!JsonIntTok(t, r.state.lastPlayedTs)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
		} else if (key == "cap") {
			std::int64_t v = 0;
			if (!JsonIntTok(t, v)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			r.state.cap = ClampHistory(static_cast<int>(v));
		} else if (key == "pinCap") {
			std::int64_t v = 0;
			if (!JsonIntTok(t, v)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			r.state.pinCap = static_cast<int>(v);
		} else if (key == "nextSess") {
			std::int64_t v = 0;
			if (!JsonIntTok(t, v)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			r.state.nextSess = static_cast<int>(v);
		} else if (key == "sessions") {
			if (!t.Eat('[')) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			if (!t.Eat(']')) {
				for (;;) {
					if (!t.Eat('{')) {
						r.corrupt = true;
						r.notice = "bad json";
						return r;
					}
					Session s;
					if (!t.Eat('}')) {
						for (;;) {
							std::string sk;
							if (!JsonString(t, sk) || !t.Eat(':')) {
								r.corrupt = true;
								r.notice = "bad json";
								return r;
							}
							if (sk == "id") {
								std::int64_t v = 0;
								if (!JsonIntTok(t, v)) {
									r.corrupt = true;
									r.notice = "bad json";
									return r;
								}
								s.id = static_cast<int>(v);
							} else if (sk == "startTs") {
								if (!JsonIntTok(t, s.startTs)) {
									r.corrupt = true;
									r.notice = "bad json";
									return r;
								}
							} else if (!JsonSkipValue(t, 1)) {
								r.corrupt = true;
								r.notice = "bad json";
								return r;
							}
							if (t.Eat('}')) break;
							if (!t.Eat(',')) {
								r.corrupt = true;
								r.notice = "bad json";
								return r;
							}
						}
					}
					r.state.sessions.push_back(s);
					if (t.Eat(']')) break;
					if (!t.Eat(',')) {
						r.corrupt = true;
						r.notice = "bad json";
						return r;
					}
				}
			}
		} else if (key == "entries") {
			if (!t.Eat('[')) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			if (!t.Eat(']')) {
				for (;;) {
					t.Skip();
					if (t.Peek('{')) {
						Entry e;
						bool usable = false;
						if (!ParseEntry(t, e, usable)) {
							r.corrupt = true;
							r.notice = "bad json";
							return r;
						}
						if (usable) {
							if (e.id >= r.state.nextId) r.state.nextId = e.id + 1;
							r.state.entries.push_back(std::move(e));
						} else {
							r.notice = "skipped malformed entries";
						}
					} else if (!JsonSkipValue(t, 1)) {
						r.corrupt = true;
						r.notice = "bad json";
						return r;
					}
					if (t.Eat(']')) break;
					if (!t.Eat(',')) {
						r.corrupt = true;
						r.notice = "bad json";
						return r;
					}
				}
			}
		} else if (!JsonSkipValue(t, 1)) {
			r.corrupt = true;
			r.notice = "bad json";
			return r;
		}
		if (t.Eat('}')) break;
		if (!t.Eat(',')) {
			r.corrupt = true;
			r.notice = "bad json";
			return r;
		}
	}
	if (!haveType || type != kJsonType) {
		r.corrupt = true;
		r.notice = "wrong type";
		return r;
	}
	if (!haveVer || version > kJsonVersion) {
		r.corrupt = true;
		r.notice = "too new";
		return r;
	}
	if (r.state.entries.size() > static_cast<std::size_t>(kLoadEntryCap)) {
		const auto drop = r.state.entries.size() - static_cast<std::size_t>(kLoadEntryCap);
		r.state.entries.erase(r.state.entries.begin(),
			r.state.entries.begin() + static_cast<std::ptrdiff_t>(drop));
	}
	r.ok = true;
	return r;
}

struct OtherCharacter {
	std::string  key;
	std::string  name;
	int          entryCount{0};
	std::int64_t lastPlayedTs{0};
	std::int64_t fileMtime{0};
};

inline bool LogFileKey(std::string_view a_name, std::string& a_key)
{
	static constexpr std::string_view pre = "MessageLog_";
	static constexpr std::string_view suf = ".json";
	if (a_name.size() <= pre.size() + suf.size()) return false;
	if (a_name.substr(0, pre.size()) != pre) return false;
	if (a_name.substr(a_name.size() - suf.size()) != suf) return false;
	a_key.assign(a_name.substr(pre.size(), a_name.size() - pre.size() - suf.size()));
	return !a_key.empty() && a_key.find('.') == std::string::npos;
}

inline std::string OtherCharacterName(const Character& a_ch, int a_index)
{
	if (!a_ch.names.empty() && !a_ch.names.back().empty())
		return a_ch.names.back();
	return "Character " + std::to_string(a_index);
}

inline std::int64_t FileMtimeSeconds(const std::filesystem::path& a_path)
{
	std::error_code ec;
	const auto ft = std::filesystem::last_write_time(a_path, ec);
	if (ec) return 0;
	using namespace std::chrono;
	const auto sys = clock_cast<system_clock>(ft);
	return static_cast<std::int64_t>(duration_cast<seconds>(sys.time_since_epoch()).count());
}

inline std::vector<OtherCharacter> ListOtherCharacters(const std::filesystem::path& a_dir, const std::string& a_currentKey)
{
	std::vector<OtherCharacter> out;
	std::error_code ec;
	if (!std::filesystem::is_directory(a_dir, ec)) return out;
	int idx = 1;
	for (const auto& ent : std::filesystem::directory_iterator(a_dir, ec)) {
		if (!ent.is_regular_file(ec)) continue;
		std::string key;
		if (!LogFileKey(ent.path().filename().string(), key)) continue;
		if (key == a_currentKey) continue;
		OtherCharacter oc;
		oc.key = std::move(key);
		oc.fileMtime = FileMtimeSeconds(ent.path());
		const auto rd = ReadLogFile(ent.path());
		if (rd.ok && !rd.missing) {
			auto parsed = FromJson(rd.body);
			if (parsed.ok) {
				oc.name = OtherCharacterName(parsed.state.character, idx);
				oc.entryCount = static_cast<int>(parsed.state.entries.size());
				oc.lastPlayedTs = LastPlayedDisplay(parsed.state.lastPlayedTs, oc.fileMtime);
			}
		}
		if (oc.name.empty())
			oc.name = OtherCharacterName({}, idx);
		++idx;
		out.push_back(std::move(oc));
	}
	return out;
}

// ---------------------------------------------------------------------------
// Storage backends
// ---------------------------------------------------------------------------

class IMessageStore {
public:
	virtual ~IMessageStore() = default;
	virtual bool Load(const std::string& a_key, LogState& a_out, std::string& a_notice) = 0;
	virtual bool Save(const LogState& a_state) = 0;
	// Called only after the later UI confirm. Never silent.
	virtual bool DeleteCurrent(const std::string& a_key) = 0;
	virtual bool TouchesDisk() const = 0;
	virtual bool FolderExists() const = 0;
};

class NullStore final : public IMessageStore {
public:
	bool Load(const std::string&, LogState& a_out, std::string& a_notice) override
	{
		a_out = {};
		a_notice.clear();
		return true;
	}
	bool Save(const LogState&) override { return true; }
	bool DeleteCurrent(const std::string&) override { return true; }
	bool TouchesDisk() const override { return false; }
	bool FolderExists() const override { return false; }
};

using ReplaceFn = std::function<bool(const std::filesystem::path&, const std::filesystem::path&)>;

inline bool DefaultReplace(const std::filesystem::path& a_tmp, const std::filesystem::path& a_dst)
{
	std::error_code ec;
	std::filesystem::rename(a_tmp, a_dst, ec);
	if (!ec) return true;
	std::filesystem::remove(a_dst, ec);
	std::filesystem::rename(a_tmp, a_dst, ec);
	return !ec;
}

class FileStore final : public IMessageStore {
public:
	std::filesystem::path dir; // .../HorizonUI/MessageLog
	ReplaceFn             replace{DefaultReplace};
	std::function<FileRead(const std::filesystem::path&)> readHook;
	int                   bakFails{0};
	int                   bakFailGiveUp{kBakFailGiveUp};
	bool                  bakBypassed{false};

	explicit FileStore(std::filesystem::path a_dir, ReplaceFn a_rep = DefaultReplace)
		: dir(std::move(a_dir)), replace(std::move(a_rep))
	{
	}

	std::filesystem::path FileFor(const std::string& a_key) const
	{
		return dir / ("MessageLog_" + a_key + ".json");
	}

	bool TouchesDisk() const override { return true; }

	bool FolderExists() const override
	{
		std::error_code ec;
		return std::filesystem::is_directory(dir, ec);
	}

	bool Load(const std::string& a_key, LogState& a_out, std::string& a_notice) override
	{
		a_out = {};
		a_notice.clear();
		if (a_key.empty()) return true;
		std::error_code ec;
		if (!std::filesystem::is_directory(dir, ec)) return true;
		auto path = FileFor(a_key);
		bool transient = false;
		if (!TryLoad(path, a_out, a_notice, &transient)) {
			if (transient) {
				a_out = {};
				if (a_notice.empty()) a_notice = "transient read";
				return false;
			}
			auto bak = path;
			bak += ".bak";
			if (TryLoad(bak, a_out, a_notice, nullptr)) {
				if (a_notice.empty()) a_notice = "recovered from bak";
				return true;
			}
			a_out = {};
			if (a_notice.empty()) a_notice = "empty after corrupt file";
		}
		return true;
	}

	bool Save(const LogState& a_state) override
	{
		if (a_state.character.key.empty()) return false;
		std::error_code ec;
		std::filesystem::create_directories(dir, ec);
		if (ec) return false;
		const auto path = FileFor(a_state.character.key);
		LogState writable = a_state;
		const auto plugin = std::string("HorizonUI ") + HZ_FILE_VERSION_STR;
		EvictUnpinnedToBytes(writable, static_cast<std::size_t>(kFileWriteMaxBytes), plugin);
		const auto body = ToJson(writable, plugin);
		auto tmp = path;
		tmp += ".tmp";
		{
			std::ofstream o(tmp, std::ios::binary | std::ios::trunc);
			if (!o) return false;
			o.write(body.data(), static_cast<std::streamsize>(body.size()));
			o.flush();
			if (!o) {
				o.close();
				std::filesystem::remove(tmp, ec);
				return false;
			}
		}
		if (std::filesystem::is_regular_file(path, ec)) {
			auto bak = path;
			bak += ".bak";
			std::filesystem::copy_file(path, bak, std::filesystem::copy_options::overwrite_existing, ec);
			if (ec) {
				++bakFails;
				std::filesystem::remove(bak, ec);
				if (BakCopyBlocksReplace(bakFails, bakFailGiveUp)) {
					std::filesystem::remove(tmp, ec);
					return false;
				}
				bakBypassed = true;
			} else {
				bakFails = 0;
			}
		}
		if (!replace(tmp, path)) {
			std::filesystem::remove(tmp, ec);
			return false;
		}
		return true;
	}

	bool DeleteCurrent(const std::string& a_key) override
	{
		if (a_key.empty()) return false;
		std::error_code ec;
		auto path = FileFor(a_key);
		std::filesystem::remove(path, ec);
		auto bak = path;
		bak += ".bak";
		std::filesystem::remove(bak, ec);
		auto bad = path;
		bad += ".bad";
		std::filesystem::remove(bad, ec);
		auto tmp = path;
		tmp += ".tmp";
		std::filesystem::remove(tmp, ec);
		return true;
	}

private:
	bool TryLoad(const std::filesystem::path& a_path, LogState& a_out, std::string& a_notice, bool* a_transient)
	{
		std::error_code ec;
		if (a_transient) *a_transient = false;
		auto rd = readHook ? readHook(a_path) : ReadLogFile(a_path);
		if (rd.missing) return true;
		if (ShouldQuarantine(rd, false)) {
			if (a_path.extension() != ".bak") {
				auto bad = a_path;
				bad += ".bad";
				std::filesystem::rename(a_path, bad, ec);
			}
			a_notice = rd.notice.empty() ? "file too large" : rd.notice;
			return false;
		}
		if (!rd.ok) {
			if (a_transient) *a_transient = true;
			a_notice = rd.notice.empty() ? "read failed" : rd.notice;
			return false;
		}
		auto parsed = FromJson(rd.body);
		if (parsed.corrupt || ShouldQuarantine(rd, parsed.corrupt)) {
			if (a_path.extension() != ".bak") {
				auto bad = a_path;
				bad += ".bad";
				std::filesystem::rename(a_path, bad, ec);
			}
			a_notice = parsed.notice;
			return false;
		}
		a_out = std::move(parsed.state);
		if (!parsed.notice.empty()) a_notice = parsed.notice;
		return parsed.ok;
	}
};

// Purpose: Persist=0 uses NullStore and never creates the MessageLog folder.
// Persist=1 uses FileStore under <horizonDir>/MessageLog.
// Switching 1->0 stops writes and keeps memory. DeleteCurrent is the later UI call.
class Log {
public:
	Buffer                    buf;
	std::unique_ptr<IMessageStore> store;
	std::filesystem::path     horizonDir;
	ReplaceFn                 replace{DefaultReplace};
	std::atomic<bool>         loadBusy{false};
	std::uint64_t             lastChangeMs{0};
	std::uint64_t             lastWriteMs{0};
	bool                      dirty{false};
	bool                      writePending{false};
	std::uint64_t             writeSeq{0};
	std::uint64_t             writePendingSeq{0};
	bool                      persistHold{false};
	std::string               holdTargetKey;
	int                       retryBackoffMs{0};
	std::uint64_t             retryAt{0};
	std::string               lastNotice;

	Log() { store = std::make_unique<NullStore>(); }

	void Configure(const Settings& a_s, std::filesystem::path a_horizonDir)
	{
		buf.settings = a_s;
		buf.settings.historySize = ClampHistory(a_s.historySize);
		horizonDir = std::move(a_horizonDir);
		ApplyPersist(a_s.persist);
	}

	void ApplyPersist(bool a_persist)
	{
		buf.settings.persist = a_persist;
		if (!a_persist)
			store = std::make_unique<NullStore>();
		else
			store = std::make_unique<FileStore>(horizonDir / "MessageLog", replace);
	}

	bool FolderExists() const { return store && store->FolderExists(); }

	OfferResult Offer(Capture a)
	{
		const auto r = buf.Offer(std::move(a));
		if (r == OfferResult::Stored || r == OfferResult::Deduped) {
			dirty = true;
			lastChangeMs = a.nowMs;
		}
		return r;
	}

	bool ShouldFlush(std::uint64_t a_nowMs, bool a_force) const
	{
		if (!buf.settings.persist || !store || !store->TouchesDisk()) return false;
		if (!PersistAllowed(buf.character)) return false;
		if (persistHold) return false;
		if (loadBusy.load()) return false;
		if (!dirty) return false;
		if (a_force) return true;
		if (lastWriteMs && a_nowMs >= lastWriteMs && (a_nowMs - lastWriteMs) < static_cast<std::uint64_t>(kDebounceMsMin))
			return false;
		if (!lastChangeMs) return false;
		return a_nowMs >= lastChangeMs && (a_nowMs - lastChangeMs) >= static_cast<std::uint64_t>(kDebounceMs);
	}

	bool Flush(std::uint64_t a_nowMs)
	{
		if (!store) return false;
		if (!buf.settings.persist) return true;
		if (!PersistAllowed(buf.character)) return true;
		if (persistHold) return false;
		if (loadBusy.load()) return false;
		buf.lastPlayedTs = EpochSeconds();
		if (buf.character.key.empty()) return false;
		const bool ok = store->Save(buf.Snapshot());
		if (ok) {
			dirty = false;
			lastWriteMs = a_nowMs;
		}
		return ok;
	}

	void NoteRetryFailure(std::uint64_t a_nowMs)
	{
		retryBackoffMs = NextRetryMs(retryBackoffMs);
		retryAt = a_nowMs + static_cast<std::uint64_t>(retryBackoffMs);
	}

	// Read and write share retryBackoffMs / retryAt. This reset covers both.
	void NoteRetrySuccess()
	{
		persistHold = false;
		holdTargetKey.clear();
		retryBackoffMs = 0;
		retryAt = 0;
	}

	struct KeptHeld
	{
		std::string        key;
		std::vector<Entry> entries;
	};
	std::vector<KeptHeld> keptHeld;

	KeptHeld* KeptHeldSlot(const std::string& a_key)
	{
		for (auto& s : keptHeld)
			if (s.key == a_key) return &s;
		return nullptr;
	}

	// Purpose: park held rows when a load resets memory before the read
	// recovers. One slot per character key. Merge when that file next loads.
	// A name-hash hold parks under holdTargetKey (the player-id from the
	// failed promote). A second park for the same key appends, then caps.
	void ParkHeldRows()
	{
		const bool readHold = ShouldKeepHeldRows(persistHold, buf.entries.size());
		const bool writeHold = ShouldParkDirtyRows(
			PendingCountsAsDirty(dirty, writePending), PersistAllowed(buf.character), buf.entries.size());
		if (!readHold && !writeHold) return;
		const auto key = readHold ? ParkHeldKey(buf.character, holdTargetKey) : buf.character.key;
		if (key.empty()) return;
		if (auto* s = KeptHeldSlot(key)) {
			AppendParkedRows(s->entries, buf.entries);
			return;
		}
		auto rows = buf.entries;
		CapKeptHeld(rows, static_cast<std::size_t>(kKeptHeldCap));
		keptHeld.push_back({key, std::move(rows)});
	}

	// Purpose: a failed save for another character parks that job's
	// snapshot under the job key. Append, then cap. Never an empty key.
	void ParkWriteFailure(const std::string& a_key, const std::vector<Entry>& a_rows)
	{
		if (a_key.empty() || a_rows.empty()) return;
		if (auto* s = KeptHeldSlot(a_key)) {
			AppendParkedRows(s->entries, a_rows);
			return;
		}
		auto rows = a_rows;
		CapKeptHeld(rows, static_cast<std::size_t>(kKeptHeldCap));
		keptHeld.push_back({a_key, std::move(rows)});
	}

	void MergeKeptHeldIfMatch(const std::string& a_key)
	{
		for (auto it = keptHeld.begin(); it != keptHeld.end(); ++it) {
			if (!MergeKeptKeyOk(a_key, it->key)) continue;
			bool grew = false;
			std::vector<Entry> add;
			add.reserve(it->entries.size());
			for (const auto& in : it->entries) {
				bool found = false;
				for (auto& e : buf.entries) {
					if (!SameParkedRow(e, in)) continue;
					if (KeepLargerParkedN(e, in)) grew = true;
					found = true;
					break;
				}
				if (!found) add.push_back(in);
			}
			if (!add.empty()) {
				buf.MergeSession(add);
				dirty = true;
			} else if (grew) {
				dirty = true;
			}
			keptHeld.erase(it);
			return;
		}
	}

	// Purpose: merge a just-read file with the in-memory session. File pins
	// win, appended rows get new IDs. Clears the persist hold.
	// Inputs: loaded file state and the player-id character.
	void ApplyRecoveredFile(LogState a_file, Character a_ch)
	{
		auto session = buf.entries;
		const auto names = buf.character.names;
		const bool haveFile = !a_file.entries.empty() || !a_file.character.key.empty();
		if (haveFile) {
			buf.LoadState(std::move(a_file));
			buf.MergeSession(session);
		}
		if (PersistAllowed(a_ch)) {
			buf.character = std::move(a_ch);
			for (const auto& n : names)
				buf.RememberName(n);
		}
		NoteRetrySuccess();
		dirty = true;
	}

	// Purpose: re-read the target file on a timer, merge the held session,
	// then allow a write. a_force ignores the backoff (quit / next load).
	// Inputs: player-id character, now, force. Outputs: true when merged.
	bool RetryHeld(Character a_ch, std::uint64_t a_nowMs, bool a_force)
	{
		const auto target = PersistAllowed(a_ch) ? a_ch : buf.character;
		if (!PersistAllowed(target)) return false;
		if (persistHold && !a_force && !RetryDue(retryAt, a_nowMs))
			return false;
		LogState file;
		lastNotice.clear();
		if (store && buf.settings.persist) {
			if (!store->Load(target.key, file, lastNotice)) {
				persistHold = true;
				dirty = false;
				if (buf.character.keySource == "nameHash")
					holdTargetKey = target.key;
				NoteRetryFailure(a_nowMs);
				return false;
			}
		}
		ApplyRecoveredFile(std::move(file), target);
		return true;
	}

	// Purpose: name-hash session becomes a real currentPlayerID. Tests may
	// load here. The DLL queues the read on the worker and calls
	// ApplyRecoveredFile. a_nowMs 0 forces the first attempt.
	// Inputs: the player-id character and optional now. Outputs: true when the key changed.
	bool PromoteToCharacter(Character a_ch, std::uint64_t a_nowMs = 0)
	{
		if (!PersistAllowed(a_ch)) return false;
		if (buf.character.keySource != "nameHash") return false;
		const bool force = a_nowMs == 0 && !persistHold;
		if (!HoldRetryDue(persistHold, retryAt, a_nowMs) && !force)
			return false;
		return RetryHeld(std::move(a_ch), a_nowMs, force);
	}

	// Purpose: HUD-ready edge. A new key flushes the old file and loads the new
	// one (NG+ starts empty). Persist=0 and name-hash keys stay memory-only.
	// a_loadNow is for tests; the DLL loads on the worker instead.
	// Inputs: new character, current gt, now, whether to read the file here.
	// Outputs: true when the key changed.
	bool OnHudReady(Character a_ch, double a_gtNow, std::int64_t a_ts, std::uint64_t a_nowMs, bool a_loadNow = true)
	{
		bool changed = false;
		if (a_ch.key.empty()) return false;
		const bool canLoad = a_loadNow && buf.settings.persist && PersistAllowed(a_ch);
		if (buf.character.key.empty()) {
			buf.character = std::move(a_ch);
			if (canLoad)
				LoadCurrent();
			else
				lastNotice.clear();
			changed = true;
		} else if (buf.character.key != a_ch.key) {
			// Caller flushes the old file on a worker first. Never write here.
			(void)a_nowMs;
			const bool migrate = buf.character.keySource == "nameHash" && a_ch.keySource == "playerId";
			if (migrate) {
				if (canLoad)
					PromoteToCharacter(std::move(a_ch));
			} else {
				buf.ResetMemory();
				dirty = false;
				buf.character = std::move(a_ch);
				if (canLoad)
					LoadCurrent();
				else
					lastNotice.clear();
			}
			changed = true;
		} else {
			buf.RememberName(a_ch.names.empty() ? "" : a_ch.names.back());
		}
		buf.sess = buf.sess <= 0 ? 1 : buf.sess;
		if (changed || buf.sessions.empty()) {
			buf.StartSession(a_ts);
		}
		buf.Prune(a_gtNow);
		return changed;
	}

	void LoadCurrent()
	{
		LogState st;
		lastNotice.clear();
		persistHold = false;
		if (store) {
			if (!store->Load(buf.character.key, st, lastNotice)) {
				persistHold = true;
				dirty = false;
				return;
			}
		}
		if (!st.character.key.empty() || !st.entries.empty())
			buf.LoadState(std::move(st));
	}

	// Purpose: later UI confirm after Save to disk is turned off. Never silent.
	bool DeleteCurrentFile()
	{
		if (!store || buf.character.key.empty()) return false;
		return store->DeleteCurrent(buf.character.key);
	}

	// Purpose: Clear history. Cancels an in-flight write so it cannot recreate
	// the file. Called only after the later UI confirm.
	bool ClearHistoryNow()
	{
		buf.ClearHistory();
		dirty = false;
		lastChangeMs = 0;
		InvalidateInFlightWrite(writeSeq, writePending, writePendingSeq);
		if (store && PersistAllowed(buf.character))
			store->DeleteCurrent(buf.character.key);
		return true;
	}

	bool DeleteCurrentNow()
	{
		InvalidateInFlightWrite(writeSeq, writePending, writePendingSeq);
		return DeleteCurrentFile();
	}

	std::vector<OtherCharacter> ListOthers() const
	{
		return ListOtherCharacters(horizonDir / "MessageLog", buf.character.key);
	}

	bool DeleteSelected(const std::string& a_key)
	{
		if (a_key.empty() || a_key == buf.character.key) return false;
		if (!store) return false;
		return store->DeleteCurrent(a_key);
	}
};

// Purpose: parse a movie take-queue line "kind|title|text".
// Inputs: one forwarded line. Outputs: kind/title/text. Bad lines are rejected.
inline bool ParseForward(std::string_view a_line, Kind& a_kind, std::string& a_title, std::string& a_text)
{
	const auto p1 = a_line.find('|');
	if (p1 == std::string_view::npos) return false;
	const auto p2 = a_line.find('|', p1 + 1);
	if (p2 == std::string_view::npos) return false;
	a_kind = KindFromKey(a_line.substr(0, p1));
	a_title.assign(a_line.substr(p1 + 1, p2 - p1 - 1));
	a_text.assign(a_line.substr(p2 + 1));
	return !a_text.empty() && (a_kind == Kind::Quest || a_kind == Kind::Location || a_kind == Kind::Xp);
}

} // namespace hzlog
