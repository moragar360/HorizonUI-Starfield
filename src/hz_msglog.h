#pragma once

// Horizon Message Log P1: capture, ring buffer, per-character JSON, Persist.
// Planned, not released. Game-free so the harness can fail the rules without
// CommonLibSF. The DLL (src/main.cpp) supplies engine pointers, the worker
// thread, and the HUD-ready / SaveLoad flush.
// Author: Moragar
// Last modified: 2026-10-28.

#include "hz_msg_match.h"
#include "hz_ui_tid.h"
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
#include <limits>
#include <map>
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
	int           fromLater{0}; // Decision A (2026-10-27): later-point rows stay
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

// Purpose: a row whose in-game time is after now is from a later point
// (reload of an earlier save). Decision A (2026-10-27): those rows stay.
// Inputs: entry and Calendar::GetDaysPassedExact(). Outputs: true when later.
inline bool FromLaterPoint(const Entry& a_e, double a_gtNow)
{
	return a_e.fromLater != 0 || (a_gtNow > 0 && a_e.gt > a_gtNow);
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

inline std::string FoldLogKey(std::string_view a_key)
{
	std::string o;
	o.reserve(a_key.size());
	for (unsigned char c : a_key)
		o.push_back(static_cast<char>(std::toupper(c)));
	return o;
}

inline bool ValidLogKey(std::string_view a_key)
{
	if (a_key.empty() || a_key.size() > 16) return false;
	for (unsigned char c : a_key) {
		if (!std::isalnum(c)) return false;
	}
	return true;
}

inline bool SameLogKey(std::string_view a_a, std::string_view a_b)
{
	if (a_a.size() != a_b.size()) return false;
	for (std::size_t i = 0; i < a_a.size(); ++i) {
		const auto a = static_cast<unsigned char>(a_a[i]);
		const auto b = static_cast<unsigned char>(a_b[i]);
		if (std::tolower(a) != std::tolower(b)) return false;
	}
	return true;
}

enum class WriteRun : std::uint8_t { Saved = 0, Skipped, Failed };

// Purpose: per-key cancel generations. Each character has its own atomic
// seq so canceling A cannot mark B stale. The game thread only bumps or
// loads a seq; it never takes mu and never waits on disk.
// Inputs: folded character key. Outputs: the live seq for that key.
struct WriteGate {
	std::mutex            mu; // worker / tests only. Game thread never takes this.
	std::function<void()> afterCheck;

	struct Slot {
		std::string               key;
		std::atomic<std::uint64_t> seq{0};
	};

	std::uint64_t LoadCancel(std::string_view a_key) const
	{
		return SlotFor(a_key)->seq.load(std::memory_order_acquire);
	}

	// Purpose: bump one character's cancel seq. Inputs: character key.
	// Outputs: the new seq. Dependencies: SlotFor.
	std::uint64_t BumpCancel(std::string_view a_key)
	{
		return SlotFor(a_key)->seq.fetch_add(1, std::memory_order_acq_rel) + 1;
	}

private:
	mutable std::mutex                         mapMu;
	mutable std::vector<std::unique_ptr<Slot>> slots;

	Slot* SlotFor(std::string_view a_key) const
	{
		const auto folded = FoldLogKey(a_key);
		std::lock_guard lk(mapMu);
		for (auto& s : slots)
			if (s->key == folded) return s.get();
		auto p = std::make_unique<Slot>();
		p->key = folded;
		auto* r = p.get();
		slots.push_back(std::move(p));
		return r;
	}
};

// Purpose: a job is canceled only when its own key's seq moved.
inline bool WriteIsCanceled(std::uint64_t a_jobCancel, std::string_view a_jobKey, const WriteGate& a_g)
{
	return a_jobCancel != a_g.LoadCancel(a_jobKey);
}

inline WriteRun OrderedSave(WriteGate& a_g, std::uint64_t a_jobCancel, const std::string& a_jobKey,
	const std::function<bool()>& a_save)
{
	if (WriteIsCanceled(a_jobCancel, a_jobKey, a_g))
		return WriteRun::Skipped;
	if (a_g.afterCheck) a_g.afterCheck();
	if (WriteIsCanceled(a_jobCancel, a_jobKey, a_g))
		return WriteRun::Skipped;
	if (!a_save) return WriteRun::Failed;
	return a_save() ? WriteRun::Saved : WriteRun::Failed;
}

// Purpose: bump one key's cancel seq. No disk and no fileGate.mu.
inline std::uint64_t OrderedCancel(WriteGate& a_g, const std::string& a_key)
{
	return a_g.BumpCancel(a_key);
}

// Purpose: one pending write slot per character key. A newer job that
// has rows always replaces the slot and sets clearFirst when a Clear
// was pending, so the worker empties both files then saves the rows.
// A different key inserts; an empty non-Clear never drops a Clear or rows.
// Inputs: the live queue and the new job. Outputs: insert / replace / skip.
enum class QueueOp : std::uint8_t { Insert = 0, Replace, Skip };

struct QueuedWrite {
	std::string   key;
	bool          emptyClear{false};
	bool          clearFirst{false};
	bool          hasRows{false};
	std::uint64_t writeSeq{0};
};

struct QueueDecision {
	QueueOp     op{QueueOp::Insert};
	std::size_t index{0};
	bool        clearFirst{false};
};

inline QueueDecision DecideQueuedWrite(const std::vector<QueuedWrite>& a_pending, const QueuedWrite& a_new)
{
	for (std::size_t i = 0; i < a_pending.size(); ++i) {
		if (!SameLogKey(a_pending[i].key, a_new.key)) continue;
		QueueDecision d;
		d.index = i;
		if (a_new.hasRows) {
			d.op = QueueOp::Replace;
			d.clearFirst = a_pending[i].emptyClear || a_pending[i].clearFirst;
			return d;
		}
		if (a_new.emptyClear) {
			d.op = QueueOp::Replace;
			d.clearFirst = false;
			return d;
		}
		if (a_pending[i].emptyClear || a_pending[i].clearFirst || a_pending[i].hasRows) {
			d.op = QueueOp::Skip;
			d.clearFirst = a_pending[i].clearFirst;
			return d;
		}
		d.op = QueueOp::Replace;
		return d;
	}
	return {};
}

inline void ApplyQueuedWrite(std::vector<QueuedWrite>& a_pending, QueuedWrite a_new)
{
	const auto d = DecideQueuedWrite(a_pending, a_new);
	if (d.op == QueueOp::Skip) return;
	a_new.clearFirst = a_new.clearFirst || d.clearFirst;
	if (d.op == QueueOp::Replace && d.index < a_pending.size())
		a_pending[d.index] = std::move(a_new);
	else
		a_pending.push_back(std::move(a_new));
}

// Purpose: emptyClear is only an explicit Clear, never "the snapshot is empty".
inline bool DecideWriteEmptyClear(bool a_explicitClear)
{
	return a_explicitClear;
}

// Purpose: skip a write while a load is in flight for that key so a quit
// between ResetMemory and the load result cannot wipe the file.
inline bool RequestWriteBlockedByLoad(bool a_loadBusy, std::string_view a_jobKey, std::string_view a_loadKey)
{
	return a_loadBusy && !a_jobKey.empty() && SameLogKey(a_jobKey, a_loadKey);
}

// Purpose: an empty non-Clear snapshot is not a write. Inputs: whether
// this is MsglogClearHistory and whether the snapshot has rows.
inline bool SkipEmptyNonClearWrite(bool a_explicitClear, bool a_snapEmpty)
{
	return a_snapEmpty && !a_explicitClear;
}

inline bool ShouldQueueWrite(bool a_explicitClear, bool a_snapEmpty, bool a_loadBusy,
	std::string_view a_jobKey, std::string_view a_loadKey,
	bool a_clearPending = false, bool a_holdFlush = false)
{
	if (!a_holdFlush && RequestWriteBlockedByLoad(a_loadBusy, a_jobKey, a_loadKey))
		return false;
	if (SkipEmptyNonClearWrite(a_explicitClear || a_clearPending, a_snapEmpty))
		return false;
	return true;
}

inline bool PruneEmptiedBuffer(int a_dropped, bool a_nowEmpty)
{
	return a_dropped > 0 && a_nowEmpty;
}

// Purpose: Poll must not rebuild a retry from failSnap when a newer
// job is already in flight (writePending) or still queued. Each half
// is tested on its own. Inputs: writePending and HasPendingFor.
// Outputs: true when Poll must skip this key.
inline bool PollSkipsRetry(bool a_writePending, bool a_hasQueued)
{
	return a_writePending || a_hasQueued;
}

// Purpose: debug check for Scaleform thread affinity. uiTid 0 means
// the UI thread is not known yet (skip). Inputs: recorded UI tid and
// the caller's tid. Outputs: true when the call is allowed.
// Author: Moragar. Last modified: 2026-10-28.
inline bool ScaleformThreadOk(std::uint32_t a_uiTid, std::uint32_t a_curTid)
{
	return a_uiTid == 0 || a_uiTid == a_curTid;
}

// Purpose: hzcTakeLog must not run during load or the main menu.
// Those transitions recreate HUDMessagesMenu. Inputs: menu-open
// flags. Outputs: true when a take is allowed. Author: Moragar.
// Last modified: 2026-10-28.
inline bool MsglogTakeMovieAllowed(bool a_loading, bool a_mainMenu, bool a_messagesOpen)
{
	return !a_loading && !a_mainMenu && a_messagesOpen;
}

inline constexpr std::uint64_t kTakeLogMinMs = 250;
inline constexpr int kTakeLogCap = 40;
inline constexpr std::uint64_t kEngineRefreshMinMs = 200;
inline constexpr std::uint64_t kHudSafeCacheMs = 150;
inline constexpr int kHookAliveFirstN = 60;
inline constexpr std::uint64_t kHookAlivePeriodMs = 60000;
inline constexpr int kMinTextPx = 13;

// Purpose: rate-limit hzcTakeLog. Inputs: now and the next-allowed
// tick. Outputs: true when a take may run. Author: Moragar.
// Last modified: 2026-10-28.
inline bool MsglogTakeMovieDue(std::uint64_t a_now, std::uint64_t a_next)
{
	return a_now >= a_next;
}

// Purpose: how many queued take-log lines go out this take. The rest
// stay for the next take so a loading skip cannot drop them.
// Inputs: queued count and cap. Outputs: lines to join this take.
// Author: Moragar. Last modified: 2026-10-28.
inline int TakeLogBatchCount(int a_queued, int a_cap = kTakeLogCap)
{
	if (a_queued <= 0 || a_cap <= 0) return 0;
	return a_queued < a_cap ? a_queued : a_cap;
}

// Purpose: true when this take hit the cap and more lines remain.
// Inputs: queued count and how many were taken. Outputs: retake now.
// Author: Moragar. Last modified: 2026-10-28.
inline bool TakeLogHasRemainder(int a_queued, int a_taken)
{
	return a_queued > a_taken && a_taken > 0;
}

// Purpose: move up to a_cap lines off the front of a_q. Remainder
// stays. Inputs: queue and cap. Outputs: this take's lines.
// Author: Moragar. Last modified: 2026-10-28.
template <typename T>
inline std::vector<T> TakeLogBatch(std::vector<T>& a_q, int a_cap = kTakeLogCap)
{
	const int n = TakeLogBatchCount(static_cast<int>(a_q.size()), a_cap);
	std::vector<T> out;
	out.reserve(static_cast<std::size_t>(n));
	for (int i = 0; i < n; ++i)
		out.push_back(std::move(a_q[static_cast<std::size_t>(i)]));
	a_q.erase(a_q.begin(), a_q.begin() + n);
	return out;
}

// Purpose: an emptied user Clear writes only when Persist is on, the
// key is valid, and persistHold is off. persistHold is a failed read;
// writing empty then would wipe the file we could not load.
// Inputs: emptied, persist, persistHold, valid key. Outputs: write?
// Author: Moragar. Last modified: 2026-10-28.
inline bool ClearSessionWrites(bool a_emptied, bool a_persist, bool a_persistHold, bool a_validKey)
{
	return a_emptied && a_persist && a_validKey && !a_persistHold;
}

// Purpose: PromoteId queues one recovery load. The recoverBusy check
// belongs inside the same lock as the store so two threads cannot both
// queue. Inputs: busy, name-hash, persist-ok, hold due. Outputs: queue?
// Author: Moragar. Last modified: 2026-10-28.
inline bool PromoteIdShouldQueue(bool a_recoverBusy, bool a_nameHash, bool a_persistOk, bool a_holdDue)
{
	return !a_recoverBusy && a_nameHash && a_persistOk && a_holdDue;
}

// Purpose: TextScale 0.90 can round 13 to 12. The AS floor is this
// same rule (if minPx > sz then sz = minPx). Inputs: rounded size and
// the caller floor. Outputs: size used. Author: Moragar.
// Last modified: 2026-10-28.
inline int FloorTextPx(int a_sz, int a_minPx)
{
	return a_minPx > a_sz ? a_minPx : a_sz;
}

// Purpose: chip-row scroll that keeps the active chip in the clip.
// Mirrors hzMsglogChipKeepVisible. Inputs: current x, strip width,
// clip width, active chip left and width. Outputs: clamped x.
// Author: Moragar. Last modified: 2026-10-28.
inline int ChipScrollX(int a_chipX, int a_chipW, int a_chipInner, int a_activeLeft, int a_activeW)
{
	int maxX = a_chipW - a_chipInner;
	if (maxX < 0) maxX = 0;
	int x = a_chipX;
	if (a_activeLeft < x) x = a_activeLeft;
	if (a_activeLeft + a_activeW > x + a_chipInner)
		x = a_activeLeft + a_activeW - a_chipInner;
	if (x > maxX) x = maxX;
	if (x < 0) x = 0;
	return x;
}

// Purpose: the AdvanceFrame vtable patch installs once. A second HUD
// recreate must not read the hook as the original.
// Inputs: exchange result (already hooked). Outputs: skip install.
// Author: Moragar. Last modified: 2026-10-28.
inline bool HookOnceFlagBlocksRetry(bool a_alreadyHooked)
{
	return a_alreadyHooked;
}

// Purpose: g_mlEng is written on the UI thread and read on the job
// thread. A mutex (or equivalent) is required whenever both happen.
// Inputs: whether the cache is shared across threads. Outputs: lock?
// Author: Moragar. Last modified: 2026-10-28.
inline bool EngineCacheNeedsMutex(bool a_crossThread)
{
	return a_crossThread;
}

inline constexpr int kTakeLogHardCap = 500;

inline bool HookOrigStored(const void* a_orig, const void* a_hook)
{
	return a_orig != nullptr && a_orig != a_hook;
}

// Purpose: TextScale 0.90 on a 13 px face rounds to 12; the AS floor
// then lifts it back. Inputs: face size and minPx. Outputs: size used.
// Author: Moragar. Last modified: 2026-10-28.
inline int TextScaleFloorPx(int a_fs, int a_minPx)
{
	int sz = (a_fs * 9 + 5) / 10;
	if (sz < 9) sz = 9;
	return FloorTextPx(sz, a_minPx);
}

// Purpose: parse a take-log drop marker (`drop|N`). Inputs: one
// line. Outputs: dropped count, or -1 if this is not a drop line.
// Author: Moragar. Last modified: 2026-10-28.
inline int TakeLogDroppedCount(std::string_view a_line)
{
	if (a_line.size() < 6 || a_line.substr(0, 5) != "drop|") return -1;
	int n = 0;
	for (std::size_t i = 5; i < a_line.size(); ++i) {
		const char c = a_line[i];
		if (c == '|') break;
		if (c < '0' || c > '9') return -1;
		n = n * 10 + (c - '0');
	}
	return n;
}

// Purpose: the same 500-cap / drop|N / 40-per-take rules as
// hzcLogPush / hzcTakeLog in the Comms movie. Inputs: kind|title|text
// lines. Outputs: a take string that may start with drop|N.
// Author: Moragar. Last modified: 2026-10-28.
struct TakeLogMovieQueue
{
	std::vector<std::string> q;
	int dropped{0};

	void Push(std::string a_line)
	{
		if (static_cast<int>(q.size()) >= kTakeLogHardCap) {
			q.erase(q.begin());
			++dropped;
		}
		q.push_back(std::move(a_line));
	}

	std::string Take()
	{
		if (q.empty() && dropped == 0) return {};
		int n = static_cast<int>(q.size());
		if (n > kTakeLogCap) n = kTakeLogCap;
		std::string o;
		for (int i = 0; i < n; ++i) {
			if (i) o += '\n';
			o += q[static_cast<std::size_t>(i)];
		}
		q.erase(q.begin(), q.begin() + n);
		if (dropped > 0) {
			o = o.empty() ? ("drop|" + std::to_string(dropped))
				: ("drop|" + std::to_string(dropped) + "\n" + o);
			dropped = 0;
		}
		return o;
	}
};

// Purpose: all writer-side state and decisions. The DLL only calls methods.
// Per-key slots hold clearPending (set on an explicit user Clear, cleared
// only when ok && seq >= clearSeq), write seqs, last-failed snap, and
// per-key retry backoff. Hold-flush is slot state, not a caller literal.
// A prune that empties memory marks the key clean and does not write.
struct WriteEmit {
	std::string   key;
	LogState      snap;
	bool          emptyClear{false};
	bool          clearFirst{false};
	std::uint64_t writeSeq{0};
	bool          persist{true};
};

struct WriteDecision {
	bool      queue{false};
	WriteEmit emit;
};

// Purpose: copy emit flags onto a worker job. A literal false here
// drops clearFirst (P1d). Inputs: dest flags and the coordinator emit.
inline void AssignEmitFlags(bool& a_emptyClear, bool& a_clearFirst, const WriteEmit& a_e)
{
	a_emptyClear = a_e.emptyClear;
	a_clearFirst = a_e.clearFirst;
}

class MsglogWriteCoordinator {
public:
	struct Slot {
		std::string   key;
		bool          clearPending{false};
		std::uint64_t clearSeq{0};
		bool          writePending{false};
		std::uint64_t writePendingSeq{0};
		std::uint64_t doneSeq{0};
		LogState      failSnap;
		bool          failClearFirst{false};
		bool          hasFail{false};
		bool          retryDue{false};
		int           retryBackoffMs{0};
		std::uint64_t retryAt{0};
		bool          dirty{false};
		bool          holdFlush{false};
	};

	void SetPersist(bool a_on) { persist_ = a_on; }
	bool Persist() const { return persist_; }

	bool LoadBusy() const { return loadBusy_; }
	std::string LoadKey() const { return loadKey_; }
	std::uint64_t LoadGen() const { return loadGen_; }

	bool ClearPending(std::string_view a_key) const
	{
		if (const auto* s = FindSlot(a_key)) return s->clearPending;
		return false;
	}

	std::uint64_t ClearSeq(std::string_view a_key) const
	{
		if (const auto* s = FindSlot(a_key)) return s->clearSeq;
		return 0;
	}

	bool WritePending(std::string_view a_key) const
	{
		if (const auto* s = FindSlot(a_key)) return s->writePending;
		return false;
	}

	bool AnyWritePending() const
	{
		for (const auto& s : slots_)
			if (s.writePending) return true;
		return false;
	}

	bool AnyClearPending() const
	{
		for (const auto& s : slots_)
			if (s.clearPending) return true;
		return false;
	}

	std::uint64_t WritePendingSeq(std::string_view a_key) const
	{
		if (const auto* s = FindSlot(a_key)) return s->writePendingSeq;
		return 0;
	}

	std::uint64_t DoneSeq(std::string_view a_key) const
	{
		if (const auto* s = FindSlot(a_key)) return s->doneSeq;
		return 0;
	}

	int RetryBackoffMs(std::string_view a_key) const
	{
		if (const auto* s = FindSlot(a_key)) return s->retryBackoffMs;
		return 0;
	}

	void OnRow(std::string_view a_key)
	{
		if (a_key.empty()) return;
		SlotFor(a_key).dirty = true;
	}

	// holdFlush is slot state set by OnHoldFlush. Callers must not pass it.
	WriteDecision RequestWrite(std::string_view a_key, const LogState& a_snap, bool a_force)
	{
		if (!a_force && !a_key.empty()) {
			const auto* s = FindSlot(a_key);
			const bool dirty = s && s->dirty;
			const bool pendingClear = s && s->clearPending;
			const bool hold = s && s->holdFlush;
			if (!dirty && !pendingClear && !hold) return {};
		}
		return DecideAndQueue(a_key, a_snap, false);
	}

	WriteDecision OnClear(std::string_view a_key, const LogState& a_emptySnap)
	{
		if (!persist_ || !ValidLogKey(a_key)) return {};
		return DecideAndQueue(a_key, a_emptySnap, true);
	}

	// Purpose: a prune that emptied memory is not a Clear. Mark clean and
	// skip disk so a bad clock cannot wipe main and bak.
	void OnPruneEmpty(std::string_view a_key)
	{
		if (a_key.empty()) return;
		auto& s = SlotFor(a_key);
		s.dirty = false;
	}

	void OnLoadStart(std::string_view a_key)
	{
		loadBusy_ = true;
		loadKey_.assign(a_key.begin(), a_key.end());
		++loadGen_;
	}

	// Purpose: release the load guard. a_jobGen skips a stale result when
	// a newer load for the same key is already in flight.
	void OnLoadApplied(std::string_view a_key, std::uint64_t a_jobGen = 0)
	{
		if (a_key.empty()) return;
		if (a_jobGen && a_jobGen != loadGen_) return;
		if (!SameLogKey(loadKey_, a_key)) return;
		loadBusy_ = false;
		loadKey_.clear();
	}

	// Purpose: release the load guard only for this key's in-flight load.
	// A hold-flush for A must not clear a real load of B (P2-A).
	void OnHoldFlush(std::string_view a_key, std::uint64_t a_jobGen = 0)
	{
		if (a_key.empty()) return;
		if (!SameLogKey(loadKey_, a_key)) return;
		if (a_jobGen && a_jobGen != loadGen_) return;
		SlotFor(a_key).holdFlush = true;
		loadBusy_ = false;
		loadKey_.clear();
	}

	void OnWriteResult(std::string_view a_key, std::uint64_t a_seq, bool a_ok,
		const LogState* a_failSnap = nullptr, bool a_skipped = false, bool a_jobClearFirst = false,
		std::uint64_t a_nowMs = 0)
	{
		auto& s = SlotFor(a_key);
		s.doneSeq = a_seq;
		if (WritePendingClears(a_seq, s.writePendingSeq))
			s.writePending = false;
		pending_.erase(std::remove_if(pending_.begin(), pending_.end(),
			[&](const QueuedWrite& q) {
				return SameLogKey(q.key, a_key) && q.writeSeq == a_seq;
			}), pending_.end());
		if (a_skipped) {
			if (s.clearPending) s.retryDue = true;
			return;
		}
		if (a_ok) {
			if (a_seq >= s.clearSeq) {
				s.clearPending = false;
				s.clearSeq = 0;
				s.failClearFirst = false;
			}
			s.hasFail = false;
			s.retryDue = false;
			s.failSnap = {};
			s.retryBackoffMs = 0;
			s.retryAt = 0;
			s.holdFlush = false;
			return;
		}
		if (a_failSnap) {
			s.failSnap = *a_failSnap;
			s.hasFail = true;
		}
		s.failClearFirst = a_jobClearFirst
			|| s.failClearFirst
			|| (s.clearPending && a_failSnap && !a_failSnap->entries.empty());
		s.retryBackoffMs = NextRetryMs(s.retryBackoffMs);
		s.retryAt = a_nowMs + static_cast<std::uint64_t>(s.retryBackoffMs);
		s.retryDue = true;
	}

	std::vector<WriteDecision> OnQuit(std::string_view a_key, const LogState& a_snap)
	{
		std::vector<WriteDecision> out;
		auto cur = RequestWrite(a_key, a_snap, true);
		if (cur.queue) out.push_back(std::move(cur));
		for (auto& s : slots_) {
			if (!s.clearPending) continue;
			if (!a_key.empty() && SameLogKey(s.key, a_key)) continue;
			LogState snap = s.hasFail ? s.failSnap : LogState{};
			if (snap.character.key.empty())
				snap.character.key = s.key;
			auto d = DecideAndQueue(s.key, snap, true);
			if (d.queue) out.push_back(std::move(d));
		}
		return out;
	}

	// Purpose: retry due slots from failSnap. P2-H: never rebuild a retry
	// from an older snapshot when a newer job is already queued or in flight.
	std::vector<WriteDecision> Poll(std::uint64_t a_nowMs = ~std::uint64_t{0})
	{
		std::vector<WriteDecision> out;
		std::vector<std::string> keys;
		for (auto& s : slots_) {
			if (!s.retryDue) continue;
			if (a_nowMs < s.retryAt) continue;
			s.retryDue = false;
			keys.push_back(s.key);
		}
		for (const auto& k : keys) {
			auto& s = SlotFor(k);
			if (PollSkipsRetry(s.writePending, HasPendingFor(k)))
				continue;
			LogState snap = s.hasFail ? s.failSnap : LogState{};
			if (snap.character.key.empty())
				snap.character.key = k;
			auto d = DecideAndQueue(k, snap, false);
			if (d.queue) out.push_back(std::move(d));
		}
		return out;
	}

	const std::vector<QueuedWrite>& PendingJobs() const { return pending_; }

private:
	bool          persist_{true};
	bool          loadBusy_{false};
	std::string   loadKey_;
	std::uint64_t loadGen_{0};
	std::uint64_t nextWriteSeq_{0};
	std::vector<Slot>        slots_;
	std::vector<QueuedWrite> pending_;

	Slot& SlotFor(std::string_view a_key)
	{
		const auto folded = FoldLogKey(a_key);
		for (auto& s : slots_)
			if (s.key == folded) return s;
		Slot n;
		n.key = folded;
		slots_.push_back(std::move(n));
		return slots_.back();
	}

	const Slot* FindSlot(std::string_view a_key) const
	{
		const auto folded = FoldLogKey(a_key);
		for (const auto& s : slots_)
			if (s.key == folded) return &s;
		return nullptr;
	}

	bool HasPendingFor(std::string_view a_key) const
	{
		for (const auto& q : pending_)
			if (SameLogKey(q.key, a_key)) return true;
		return false;
	}

	WriteDecision DecideAndQueue(std::string_view a_key, const LogState& a_snap,
		bool a_explicitClear)
	{
		WriteDecision d;
		d.emit.key.assign(a_key.begin(), a_key.end());
		d.emit.snap = a_snap;
		d.emit.persist = persist_;
		if (!persist_ || a_key.empty()) return d;
		if (a_explicitClear && !ValidLogKey(a_key)) return d;
		auto& s = SlotFor(a_key);
		if (a_explicitClear) {
			s.clearPending = true;
			if (s.clearSeq == 0)
				s.clearSeq = nextWriteSeq_ + 1;
		}
		const bool snapEmpty = a_snap.entries.empty();
		const bool explicitClear = a_explicitClear || (s.clearPending && snapEmpty);
		const bool holdFlush = s.holdFlush;
		const bool clearFirst = (s.clearPending && !snapEmpty) || s.failClearFirst;
		if (!ShouldQueueWrite(explicitClear, snapEmpty, loadBusy_, a_key, loadKey_,
				s.clearPending, holdFlush))
			return d;
		d.emit.emptyClear = DecideWriteEmptyClear(explicitClear);
		d.emit.clearFirst = clearFirst;
		d.emit.writeSeq = ++nextWriteSeq_;
		if (a_explicitClear || d.emit.emptyClear)
			s.clearSeq = d.emit.writeSeq;
		QueuedWrite q;
		q.key = d.emit.key;
		q.emptyClear = d.emit.emptyClear;
		q.clearFirst = d.emit.clearFirst;
		q.hasRows = !snapEmpty;
		q.writeSeq = d.emit.writeSeq;
		const auto qd = DecideQueuedWrite(pending_, q);
		if (qd.op == QueueOp::Skip) return d;
		d.emit.clearFirst = clearFirst || qd.clearFirst;
		q.clearFirst = d.emit.clearFirst;
		if (qd.op == QueueOp::Replace && qd.index < pending_.size())
			pending_[qd.index] = std::move(q);
		else
			pending_.push_back(std::move(q));
		s.writePending = true;
		s.writePendingSeq = d.emit.writeSeq;
		s.dirty = false;
		d.queue = true;
		return d;
	}
};

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

// Purpose: stamp lastPlayedTs before Snapshot so a write carries this
// session (normal and quit). A 0 ts is ignored so a bad clock cannot wipe
// a known value. Inputs: lastPlayedTs field and epoch seconds. Outputs: none.
// Last modified: 2026-10-28.
inline void StampLastPlayed(std::int64_t& a_lastPlayedTs, std::int64_t a_ts)
{
	if (a_ts > 0)
		a_lastPlayedTs = a_ts;
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
inline int NextSessId(int a_sess)
{
	if (a_sess >= (std::numeric_limits<int>::max)()) return (std::numeric_limits<int>::max)();
	if (a_sess < 1) return 1;
	return a_sess + 1;
}

inline int ClampSessId(int a_sess)
{
	if (a_sess < 1) return 1;
	return a_sess;
}

inline int ResolveNextSess(int a_nextSess, const std::vector<Session>& a_sessions, const std::vector<Entry>& a_entries)
{
	int n = a_nextSess > 0 ? a_nextSess : 1;
	for (const auto& e : a_entries)
		if (e.sess >= n) n = NextSessId(e.sess);
	for (const auto& s : a_sessions)
		if (s.id >= n) n = NextSessId(s.id);
	return n;
}

inline void RestampLaunchSess(std::vector<Entry>& a_rows, int a_pin)
{
	if (a_pin <= 0) return;
	for (auto& e : a_rows)
		e.sess = a_pin;
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
	// Bumped on every visible-row change so the HUD packs once, not
	// every tick. The game thread only copies when this moves.
	std::uint64_t viewGen{0};
	int       sess{1};
	int       launchSess{0}; // current key's process-lifetime pin; 0 if none
	std::int64_t sessStartTs{0};
	std::vector<Session> sessions;
	std::vector<Entry> entries; // oldest -> newest
	// Per-character launch session for this process. Never cleared on
	// ResetMemory / LoadState: A and B must not share one id.
	std::map<std::string, int> launchPins;

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

	int LaunchPinFor(std::string_view a_key) const
	{
		if (a_key.empty()) return 0;
		const auto it = launchPins.find(FoldLogKey(a_key));
		return it == launchPins.end() ? 0 : it->second;
	}

	void RememberLaunchPin(std::string_view a_key, int a_sess)
	{
		if (a_key.empty() || a_sess <= 0) return;
		launchPins[FoldLogKey(a_key)] = ClampSessId(a_sess);
	}

	// Purpose: first use of a key in this process takes
	// max(file nextSess, max entry sess+1, max sessions id+1). Later
	// loads bump the pin past any later-read ids so an unreadable first
	// load cannot collide. Switches back to that key reuse the pin.
	// Inputs: character key and the file's nextSess (0 if none).
	// Outputs: the launch session id for this key.
	int TakeLaunchSess(std::string_view a_key, int a_fileNext)
	{
		if (const int pinned = LaunchPinFor(a_key)) {
			int maxRead = 0;
			for (const auto& e : entries)
				if (e.sess > maxRead) maxRead = e.sess;
			for (const auto& s : sessions)
				if (s.id > maxRead) maxRead = s.id;
			if (maxRead > pinned) {
				const int n = NextSessId(maxRead);
				RememberLaunchPin(a_key, n);
				return n;
			}
			return pinned;
		}
		const int n = ResolveNextSess(a_fileNext, sessions, entries);
		RememberLaunchPin(a_key, n);
		return n;
	}

	void StartSession(std::int64_t a_ts)
	{
		if (!character.key.empty()) {
			sess = ClampSessId(TakeLaunchSess(character.key, sess <= 0 ? 1 : sess));
			launchSess = sess;
		} else if (launchSess != 0) {
			sess = ClampSessId(launchSess);
		} else {
			sess = ClampSessId(sess);
			launchSess = sess;
		}
		sessStartTs = a_ts;
		for (const auto& s : sessions)
			if (s.id == sess) {
				BumpView();
				return;
			}
		sessions.push_back(Session{sess, a_ts});
		BumpView();
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
		const auto r = OfferDedupe(a, key, win);
		if (r == OfferResult::Stored || r == OfferResult::Deduped)
			BumpView();
		return r;
	}

	bool Pin(std::uint64_t a_id)
	{
		for (auto& e : entries) {
			if (e.id != a_id) continue;
			if (e.pin) return true;
			if (PinCount() >= kPinCap) return false;
			e.pin = 1;
			BumpView();
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
			BumpView();
			return true;
		}
		return false;
	}

	// Purpose: after a reload, mark rows from a later point. Decision A
	// (2026-10-27): loading an earlier save must not drop any rows. Every
	// later-point row, pinned or not, stays and is flagged fromLater (the
	// view dims it and labels it "from a later point"). The history-size
	// cap still evicts the oldest unpinned rows. A null/zero clock is a
	// no-op. An automatic trim never writes an empty file or touches .bak.
	// The id counter is not rewound.
	// Inputs: Calendar::GetDaysPassedExact() at the HUD-ready edge.
	// Outputs: number of rows newly flagged. Never a drop count.
	// Dependencies: FromLaterPoint. Last modified: 2026-10-28.
	int Prune(double a_gtNow)
	{
		if (a_gtNow <= 0) return 0;
		int flagged = 0;
		for (auto& e : entries) {
			if (e.fromLater) continue;
			if (a_gtNow > 0 && e.gt > a_gtNow) {
				e.fromLater = 1;
				++flagged;
			}
		}
		if (flagged) BumpView();
		return flagged;
	}

	void ClearSession()
	{
		std::vector<Entry> keep;
		for (auto& e : entries) {
			if (e.sess != sess || e.pin) keep.push_back(std::move(e));
		}
		entries.swap(keep);
		BumpView();
	}

	void ClearHistory()
	{
		entries.clear();
		BumpView();
	}

	void SetHistorySize(int a_n)
	{
		settings.historySize = ClampHistory(a_n);
		Evict();
		BumpView();
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
		s.nextSess = NextSessId(sess);
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
		sess = ClampSessId(TakeLaunchSess(character.key, s.nextSess));
		launchSess = sess;
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
		BumpView();
	}

	void ResetMemory()
	{
		entries.clear();
		sessions.clear();
		nextId = 1;
		// Look up this key's pin. Do not apply another character's id.
		launchSess = LaunchPinFor(character.key);
		sess = launchSess != 0 ? launchSess : 1;
		sessStartTs = 0;
		lastPlayedTs = 0;
		suppressFirstLoc_ = false;
		lastLocNorm_.clear();
		ClearDedupeClock();
		BumpView();
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
		auto incoming = a_session;
		RestampLaunchSess(incoming, sess);
		for (const auto& in : incoming) {
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
		BumpView();
	}

private:
	void BumpView() { ++viewGen; }
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
		row.fromLater = e.fromLater != 0 || FromLaterPoint(e, a_gtNow);
		v.entries.push_back(std::move(row));
	}
	return v;
}

// Purpose: pack a view snapshot for the HUD movie. No IO. Pipes and
// newlines in fields become spaces so the movie can split on '|'.
// Inputs: ViewSnap. Outputs: one string. Last modified: 2026-10-28.
inline std::string PackViewField(std::string_view a_s)
{
	std::string o;
	o.reserve(a_s.size());
	for (unsigned char c : a_s) {
		if (c == '|' || c == '\n' || c == '\r')
			o.push_back(' ');
		else
			o.push_back(static_cast<char>(c));
	}
	return o;
}

inline const char* ViewStatusKey(ViewStatus a_s)
{
	switch (a_s) {
	case ViewStatus::Saving: return "saving";
	case ViewStatus::MemoryOnly: return "memory";
	case ViewStatus::Paused: return "paused";
	case ViewStatus::KeyFallback: return "fallback";
	default: return "ok";
	}
}

inline std::string PackView(const ViewSnap& a_v)
{
	std::string o;
	o += "v1|";
	o += ViewStatusKey(a_v.status);
	o += '|';
	o += std::to_string(a_v.sess);
	o += '|';
	o += std::to_string(a_v.pinCount);
	o += '|';
	o += std::to_string(a_v.pinCap);
	o += '|';
	o += std::to_string(a_v.sessStartTs);
	o += '|';
	o += std::to_string(a_v.entries.size());
	for (const auto& e : a_v.entries) {
		o += '\n';
		o += std::to_string(e.id);
		o += '|';
		o += KindKey(e.kind);
		o += '|';
		o += PackViewField(e.title);
		o += '|';
		o += PackViewField(e.text);
		o += '|';
		o += PackViewField(e.tag);
		o += '|';
		o += PackViewField(e.loc);
		o += '|';
		o += std::to_string(e.n);
		o += '|';
		o += std::to_string(e.pin);
		o += '|';
		o += std::to_string(e.missed);
		o += '|';
		o += std::to_string(e.sess);
		o += '|';
		o += std::to_string(e.ts);
		o += '|';
		o += std::to_string(e.gt);
		o += '|';
		o += std::to_string(e.ut);
		o += '|';
		o += std::to_string(e.lt);
		o += '|';
		o += e.fromLater ? '1' : '0';
	}
	return o;
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
	o += ", \"nextId\": ";
	o += std::to_string(a_s.nextId ? a_s.nextId : 1);
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
		o += ", \"later\": ";
		o += std::to_string(e.fromLater ? 1 : 0);
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
		} else if (key == "later") {
			std::int64_t v = 0;
			if (!JsonIntTok(a_t, v)) return false;
			a_e.fromLater = v ? 1 : 0;
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
		} else if (key == "nextId") {
			std::int64_t v = 0;
			if (!JsonIntTok(t, v)) {
				r.corrupt = true;
				r.notice = "bad json";
				return r;
			}
			if (v > 0 && static_cast<std::uint64_t>(v) > r.state.nextId)
				r.state.nextId = static_cast<std::uint64_t>(v);
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
	return ValidLogKey(a_key);
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
	for (const auto& ent : std::filesystem::directory_iterator(a_dir, ec)) {
		if (!ent.is_regular_file(ec)) continue;
		std::string key;
		if (!LogFileKey(ent.path().filename().string(), key)) continue;
		if (SameLogKey(key, a_currentKey)) continue;
		OtherCharacter oc;
		oc.key = std::move(key);
		oc.fileMtime = FileMtimeSeconds(ent.path());
		const auto rd = ReadLogFile(ent.path());
		if (rd.ok && !rd.missing) {
			auto parsed = FromJson(rd.body);
			if (parsed.ok) {
				if (!parsed.state.character.names.empty())
					oc.name = parsed.state.character.names.back();
				oc.entryCount = static_cast<int>(parsed.state.entries.size());
				oc.lastPlayedTs = LastPlayedDisplay(parsed.state.lastPlayedTs, oc.fileMtime);
			}
		}
		out.push_back(std::move(oc));
	}
	std::sort(out.begin(), out.end(), [](const OtherCharacter& a, const OtherCharacter& b) {
		return FoldLogKey(a.key) < FoldLogKey(b.key);
	});
	int nameless = 1;
	for (auto& oc : out) {
		if (oc.name.empty())
			oc.name = OtherCharacterName({}, nameless++);
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
	bool TouchesDisk() const override { return false; }
	bool FolderExists() const override { return false; }
};

using ReplaceFn = std::function<bool(const std::filesystem::path&, const std::filesystem::path&)>;

// Purpose: atomic tmp -> dest replace. The DLL injects MoveFileExW with
// MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH. This fallback is
// POSIX rename, which replaces dest in place. A leftover tmp is left for
// the next trunc write. Inputs: tmp and dest paths. Outputs: true on
// replace. Dependencies: none.
inline bool DefaultReplace(const std::filesystem::path& a_tmp, const std::filesystem::path& a_dst)
{
	std::error_code ec;
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
		return dir / ("MessageLog_" + FoldLogKey(a_key) + ".json");
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

	// Purpose: write JSON through a leftover-safe tmp, then replace dest.
	// Inputs: dest path and body. Outputs: true after a successful replace.
	// A failed write or replace leaves the leftover tmp for the next trunc.
	// Dependencies: replace callback (MoveFileExW REPLACE_EXISTING in the DLL).
	bool WriteAtomicKeepTmp(const std::filesystem::path& a_dest, const std::string& a_body)
	{
		auto tmp = a_dest;
		tmp += ".tmp";
		{
			std::ofstream o(tmp, std::ios::binary | std::ios::trunc);
			if (!o) return false;
			o.write(a_body.data(), static_cast<std::streamsize>(a_body.size()));
			o.flush();
			if (!o) return false;
		}
		return replace(tmp, a_dest);
	}

	bool FileHasRows(const std::string& a_key) const
	{
		if (a_key.empty()) return false;
		std::error_code ec;
		const auto path = FileFor(a_key);
		if (!std::filesystem::is_regular_file(path, ec)) return false;
		const auto rd = readHook ? readHook(path) : ReadLogFile(path);
		if (!rd.ok || rd.missing) return false;
		const auto parsed = FromJson(rd.body);
		return parsed.ok && !parsed.state.entries.empty();
	}

	bool Save(const LogState& a_state) override
	{
		if (!ValidLogKey(a_state.character.key)) return false;
		// Empty snapshots are not a Clear. Only an explicit emptyClear
		// or clearFirst job empties both files.
		if (a_state.entries.empty())
			return true;
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
			if (!o) return false;
		}
		if (std::filesystem::is_regular_file(path, ec)) {
			auto bak = path;
			bak += ".bak";
			std::filesystem::copy_file(path, bak, std::filesystem::copy_options::overwrite_existing, ec);
			if (ec) {
				++bakFails;
				if (BakCopyBlocksReplace(bakFails, bakFailGiveUp))
					return false;
				bakBypassed = true;
			} else {
				bakFails = 0;
			}
		}
		return replace(tmp, path);
	}

	// Purpose: Clear history writes the empty snapshot to the main file
	// first, then .bak. The loader prefers main, so a crash in between
	// cannot bring old rows back. Inputs: empty LogState with nextSess
	// kept. Outputs: true when both files hold that body.
	// Dependencies: WriteAtomicKeepTmp.
	bool SaveEmptyBoth(const LogState& a_state)
	{
		if (!ValidLogKey(a_state.character.key)) return false;
		std::error_code ec;
		std::filesystem::create_directories(dir, ec);
		if (ec) return false;
		const auto path = FileFor(a_state.character.key);
		const auto plugin = std::string("HorizonUI ") + HZ_FILE_VERSION_STR;
		const auto body = ToJson(a_state, plugin);
		if (!WriteAtomicKeepTmp(path, body)) return false;
		auto bak = path;
		bak += ".bak";
		return WriteAtomicKeepTmp(bak, body);
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

// Purpose: run one writer job. SaveEmptyBoth only when emptyClear or
// clearFirst is set. An empty non-Clear snapshot does not touch disk.
// clearFirst writes the empty files first so .bak cannot keep pre-clear
// rows, then Save writes the new rows.
inline bool ApplyDiskWrite(FileStore& a_fs, const LogState& a_snap, bool a_persist,
	bool a_emptyClear, bool a_clearFirst)
{
	if (!a_persist) return true;
	if (!a_emptyClear && !a_clearFirst && !PersistAllowed(a_snap.character))
		return true;
	if (a_emptyClear || a_clearFirst) {
		LogState empty = a_snap;
		empty.entries.clear();
		if (!a_fs.SaveEmptyBoth(empty)) return false;
		if (a_emptyClear && !a_clearFirst) return true;
	}
	if (a_snap.entries.empty()) return true;
	return a_fs.Save(a_snap);
}

// Purpose: Persist=0 uses NullStore and never creates the MessageLog folder.
// Persist=1 uses FileStore under <horizonDir>/MessageLog.
// Switching 1->0 stops writes and leaves existing files in place.
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
	WriteGate                 fileGate;
	std::uint64_t             loadGen{0};
	std::vector<OtherCharacter> otherCache;
	std::uint64_t             otherCacheGen{0};
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
		if (!a_persist) {
			store = std::make_unique<NullStore>();
			dirty = false;
			writePending = false;
			writePendingSeq = 0;
			fileGate.BumpCancel(buf.character.key);
		} else {
			store = std::make_unique<FileStore>(horizonDir / "MessageLog", replace);
		}
	}

	bool FolderExists() const { return store && store->FolderExists(); }

	// Purpose: display-only MessageLog folder path. Inputs: none.
	// Outputs: a string. Never creates the folder and never opens a file.
	std::string FolderPathDisplay() const
	{
		if (horizonDir.empty()) return {};
		return (horizonDir / "MessageLog").generic_string();
	}

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
		StampLastPlayed(buf.lastPlayedTs, EpochSeconds());
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

	void DropParked(const std::string& a_key)
	{
		keptHeld.erase(std::remove_if(keptHeld.begin(), keptHeld.end(),
			[&](const KeptHeld& s) { return SameLogKey(s.key, a_key); }),
			keptHeld.end());
	}

	KeptHeld* KeptHeldSlot(const std::string& a_key)
	{
		for (auto& s : keptHeld)
			if (SameLogKey(s.key, a_key)) return &s;
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

	bool AcceptLoad(std::uint64_t a_jobGen) const
	{
		return a_jobGen == loadGen;
	}

	void RefreshOthers()
	{
		otherCache = ListOtherCharacters(horizonDir / "MessageLog", buf.character.key);
		++otherCacheGen;
	}

	std::vector<OtherCharacter> ListOthers() const
	{
		return otherCache;
	}

	void ClearHistoryMemory()
	{
		++loadGen;
		buf.ClearHistory();
		dirty = false;
		lastChangeMs = 0;
		writePending = false;
		writePendingSeq = 0;
		DropParked(buf.character.key);
	}

	// Purpose: Clear history. Always empties memory, drops parked rows,
	// and bumps the per-key cancel seq. Persist=1 writes the empty
	// snapshot (tests). Persist=0 does not create or touch any file.
	// Inputs: none. Outputs: true when memory is clear and, if Persist
	// is on, both files hold the empty body.
	// Dependencies: FileStore::SaveEmptyBoth.
	bool ClearHistoryNow()
	{
		ClearHistoryMemory();
		const auto key = buf.character.key;
		fileGate.BumpCancel(key);
		if (!buf.settings.persist) return true;
		if (!ValidLogKey(key)) return true;
		const auto snap = buf.Snapshot();
		FileStore fs(horizonDir / "MessageLog", replace);
		return fs.SaveEmptyBoth(snap);
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
