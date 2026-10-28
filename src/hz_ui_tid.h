#pragma once

// Purpose: poll follows the stored HUD / HUDMessages movie, not a
// recorded thread. PollScaleform runs only on the stored HUDMenu
// root's own AdvanceFrame. HUDMessagesMenu Invokes run only on that
// movie's own advance. A reused movie-root address is cleared on
// MenuMovieCreated (ABA). F11 is latched on the job poll and consumed
// only from that latch. g_uiTid is a log hint only. Author: Moragar.
// Last modified: 2026-10-28.

#include <cstdint>
#include <cstring>

namespace hzlog {

inline constexpr std::uint64_t kPollHeartbeatMs = 30000;
inline constexpr std::uint64_t kUiTidSkipLogMs = 1000;
inline constexpr std::uint64_t kSettingsKeyLatchMs = 2000;
inline constexpr std::uint64_t kStaleHudAdoptMs = 5000;
inline constexpr const char* kUiTidSourceHudRoot = "hud-root-advance";

inline bool MenuIsHud(const char* a_name)
{
	return a_name && std::strcmp(a_name, "HUDMenu") == 0;
}

inline bool MenuIsHudMessages(const char* a_name)
{
	return a_name && std::strcmp(a_name, "HUDMessagesMenu") == 0;
}

inline bool MenuIsScope(const char* a_name)
{
	return a_name && std::strcmp(a_name, "ScopeMenu") == 0;
}

inline bool MenuStoresHudRoot(const char* a_name)
{
	return MenuIsHud(a_name) || MenuIsHudMessages(a_name);
}

inline const char* UiTidRootMenuName(const void* a_root, const void* a_hudRoot, const void* a_hudMsgRoot)
{
	if (a_root && a_root == a_hudRoot) return "HUDMenu";
	if (a_root && a_root == a_hudMsgRoot) return "HUDMessagesMenu";
	return "?";
}

// Purpose: a new movie at a stored HUD root address is not that HUD.
// Null the stored pointer so AdvanceFrame cannot treat a reused
// Pause/Map/loading root as the HUD (ABA). Inputs: stored pointer,
// the new root, whether this create is that HUD menu.
inline bool ShouldClearReusedHudRoot(const void* a_stored, const void* a_newRoot, bool a_thisIsThatHud)
{
	return a_newRoot && a_stored && a_stored == a_newRoot && !a_thisIsThatHud;
}

inline bool IsHudMenuRoot(const void* a_root, const void* a_hudRoot)
{
	return a_root && a_hudRoot && a_root == a_hudRoot;
}

inline bool IsHudMsgRoot(const void* a_root, const void* a_hudMsgRoot)
{
	return a_root && a_hudMsgRoot && a_root == a_hudMsgRoot;
}

inline bool IsStoredHudRoot(const void* a_root, const void* a_hudRoot, const void* a_hudMsgRoot)
{
	return IsHudMenuRoot(a_root, a_hudRoot) || IsHudMsgRoot(a_root, a_hudMsgRoot);
}

enum class PollMovie : std::uint8_t { None = 0, Hud, HudMessages, Scope };

inline PollMovie PollMovieForRoot(const void* a_root, const void* a_hudRoot, const void* a_hudMsgRoot)
{
	if (IsHudMenuRoot(a_root, a_hudRoot)) return PollMovie::Hud;
	if (IsHudMsgRoot(a_root, a_hudMsgRoot)) return PollMovie::HudMessages;
	return PollMovie::None;
}

inline bool PollHudOnThisAdvance(PollMovie a_movie)
{
	return a_movie == PollMovie::Hud;
}

inline bool PollMsgOnThisAdvance(PollMovie a_movie)
{
	return a_movie == PollMovie::HudMessages;
}

enum class InvokeMovie : std::uint8_t { Hud = 0, HudMessages, Scope, Other };

inline InvokeMovie InvokeMovieForMenu(const char* a_name)
{
	if (MenuIsHud(a_name)) return InvokeMovie::Hud;
	if (MenuIsHudMessages(a_name)) return InvokeMovie::HudMessages;
	if (MenuIsScope(a_name)) return InvokeMovie::Scope;
	return InvokeMovie::Other;
}

// Purpose: an Invoke must target the movie whose AdvanceFrame is
// running. Inputs: the advancing stored movie and the Invoke target.
// Outputs: true when they match.
inline bool InvokeOnAdvancingMovie(PollMovie a_advancing, InvokeMovie a_target)
{
	if (a_advancing == PollMovie::Hud) return a_target == InvokeMovie::Hud;
	if (a_advancing == PollMovie::HudMessages) return a_target == InvokeMovie::HudMessages;
	if (a_advancing == PollMovie::Scope) return a_target == InvokeMovie::Scope;
	return false;
}

inline bool InvokeRootMatches(const void* a_advancing, const void* a_resolved)
{
	return a_advancing && a_resolved && a_advancing == a_resolved;
}

// Purpose: adopt a_this when it is the live menu root and the stored
// pointer is stale or null. Inputs: this AdvanceFrame, stored, live
// GetMenu root. Outputs: true when the store must change.
inline bool ShouldAdoptLiveRoot(const void* a_this, const void* a_stored, const void* a_live)
{
	return a_this && a_live && a_this == a_live && a_this != a_stored;
}

inline bool StaleHudAdoptDue(std::uint64_t a_lastHudPollMs, std::uint64_t a_nowMs,
	std::uint64_t a_gapMs = kStaleHudAdoptMs)
{
	if (a_lastHudPollMs == 0) return true;
	return a_nowMs < a_lastHudPollMs || (a_nowMs - a_lastHudPollMs) >= a_gapMs;
}

// Purpose: first HUD-root advance records a log hint. Later tids do
// not replace it. Not a poll gate. Inputs: recorded hint and this tid.
inline bool UiTidRecordFirst(std::uint32_t a_recorded, std::uint32_t a_tid)
{
	return a_recorded == 0 && a_tid != 0;
}

inline bool UiTidSwitchLogDue(std::uint64_t a_lastLogMs, std::uint64_t a_nowMs,
	std::uint64_t a_gapMs = kUiTidSkipLogMs)
{
	return a_lastLogMs == 0 || a_nowMs < a_lastLogMs || (a_nowMs - a_lastLogMs) >= a_gapMs;
}

inline bool PollAlreadyIn(bool a_previous)
{
	return a_previous;
}

inline bool SettingsKeyEdge(bool a_down, bool a_wasDown)
{
	return a_down && !a_wasDown;
}

// Purpose: job-thread rising edge. Always updates was-down so a held
// key cannot auto-repeat. Inputs: down, last down. Outputs: edge.
inline bool SettingsKeyJobEdge(bool a_down, bool& a_wasDown)
{
	const bool edge = SettingsKeyEdge(a_down, a_wasDown);
	a_wasDown = a_down;
	return edge;
}

inline bool SettingsKeyLatchFresh(std::uint64_t a_atMs, std::uint64_t a_nowMs,
	std::uint64_t a_maxAgeMs = kSettingsKeyLatchMs)
{
	if (a_nowMs < a_atMs) return false;
	return (a_nowMs - a_atMs) <= a_maxAgeMs;
}

// Purpose: HUD poll consumes only the job latch. No key-state edge.
// Inputs: exchange(false) result, latch stamp, now. Outputs: fire?
inline bool SettingsKeyHudTake(bool a_exchanged, std::uint64_t a_atMs, std::uint64_t a_nowMs,
	std::uint64_t a_maxAgeMs = kSettingsKeyLatchMs)
{
	return a_exchanged && SettingsKeyLatchFresh(a_atMs, a_nowMs, a_maxAgeMs);
}

inline bool PollHeartbeatDue(std::uint64_t a_lastMs, std::uint64_t a_nowMs,
	std::uint64_t a_periodMs = kPollHeartbeatMs)
{
	return a_lastMs == 0 || a_nowMs < a_lastMs || (a_nowMs - a_lastMs) >= a_periodMs;
}

inline thread_local const void* g_advancingRoot = nullptr;
inline thread_local PollMovie g_advancingMovie = PollMovie::None;

// Purpose: the same movie-follow / ABA / F11-latch functions the DLL
// calls. Tests drive this type so a mutant that gates on tid, heals,
// double-fires F11, or Invokes a foreign movie is caught.
// Author: Moragar. Last modified: 2026-10-28.
struct PollGate
{
	const void*   hudRoot{nullptr};
	const void*   hudMsgRoot{nullptr};
	const void*   scopeRoot{nullptr};
	std::uint32_t uiTidHint{0};
	std::uint32_t lastHudPollTid{0};
	std::uint32_t lastMsgPollTid{0};
	const void*   lastHudRoot{nullptr};
	std::uint64_t hudPolls{0};
	std::uint64_t msgPolls{0};
	bool          settingsKeyReq{false};
	std::uint64_t settingsKeyAt{0};
	bool          wasDownJob{false};
	int           settingsOpens{0};
	bool          inHudPoll{false};
	bool          inMsgPoll{false};
	std::uint64_t lastHeartbeatMs{0};
	int           heartbeats{0};
	bool          hudSafe{false};

	void OnMenuCreated(const char* a_name, const void* a_root, std::uint32_t = 0)
	{
		if (ShouldClearReusedHudRoot(hudRoot, a_root, MenuIsHud(a_name)))
			hudRoot = nullptr;
		if (ShouldClearReusedHudRoot(hudMsgRoot, a_root, MenuIsHudMessages(a_name)))
			hudMsgRoot = nullptr;
		if (ShouldClearReusedHudRoot(scopeRoot, a_root, MenuIsScope(a_name)))
			scopeRoot = nullptr;
		if (!a_root) return;
		if (MenuIsHud(a_name))
			hudRoot = a_root;
		else if (MenuIsHudMessages(a_name))
			hudMsgRoot = a_root;
		else if (MenuIsScope(a_name))
			scopeRoot = a_root;
	}

	bool IsStoredHudRoot(const void* a_root) const
	{
		return hzlog::IsStoredHudRoot(a_root, hudRoot, hudMsgRoot);
	}

	void JobKey(bool a_down, std::uint64_t a_nowMs = 0)
	{
		if (SettingsKeyJobEdge(a_down, wasDownJob)) {
			settingsKeyReq = true;
			settingsKeyAt = a_nowMs;
		}
	}

	bool ConsumeSettingsKey(std::uint64_t a_nowMs)
	{
		const bool had = settingsKeyReq;
		settingsKeyReq = false;
		return SettingsKeyHudTake(had, settingsKeyAt, a_nowMs);
	}

	PollMovie OnAdvance(const void* a_root, std::uint32_t a_tid, std::uint64_t a_nowMs = 0)
	{
		const auto kind = PollMovieForRoot(a_root, hudRoot, hudMsgRoot);
		if (PollHeartbeatDue(lastHeartbeatMs, a_nowMs)) {
			++heartbeats;
			lastHeartbeatMs = a_nowMs;
		}
		if (kind == PollMovie::Hud) {
			if (UiTidRecordFirst(uiTidHint, a_tid))
				uiTidHint = a_tid;
			if (PollAlreadyIn(inHudPoll))
				return kind;
			inHudPoll = true;
			lastHudPollTid = a_tid;
			lastHudRoot = a_root;
			++hudPolls;
			if (ConsumeSettingsKey(a_nowMs))
				++settingsOpens;
			inHudPoll = false;
		} else if (kind == PollMovie::HudMessages) {
			if (PollAlreadyIn(inMsgPoll))
				return kind;
			inMsgPoll = true;
			lastMsgPollTid = a_tid;
			++msgPolls;
			inMsgPoll = false;
		}
		return kind;
	}
};

}
