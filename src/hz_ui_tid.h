#pragma once

// Purpose: poll follows the stored HUD / HUDMessages movie, not a
// recorded thread. PollScaleform runs only on the stored HUDMenu
// root's own AdvanceFrame. HUDMessagesMenu Invokes run only on that
// movie's own advance. A reused movie-root address is cleared on
// MenuMovieCreated (ABA). g_uiTid is a log hint only. Author: Moragar.
// Last modified: 2026-10-28.

#include <cstdint>
#include <cstring>

namespace hzlog {

inline constexpr std::uint64_t kPollHeartbeatMs = 30000;
inline constexpr std::uint64_t kUiTidSkipLogMs = 1000;
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

enum class PollMovie : std::uint8_t { None = 0, Hud, HudMessages };

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

// Purpose: an Invoke must target the movie whose AdvanceFrame is
// running. Inputs: the advancing stored movie and the Invoke target.
// Outputs: true when they match.
inline bool InvokeOnAdvancingMovie(PollMovie a_advancing, InvokeMovie a_target)
{
	if (a_advancing == PollMovie::Hud) return a_target == InvokeMovie::Hud;
	if (a_advancing == PollMovie::HudMessages) return a_target == InvokeMovie::HudMessages;
	return false;
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

inline bool PollHeartbeatDue(std::uint64_t a_lastMs, std::uint64_t a_nowMs,
	std::uint64_t a_periodMs = kPollHeartbeatMs)
{
	return a_lastMs == 0 || a_nowMs < a_lastMs || (a_nowMs - a_lastMs) >= a_periodMs;
}

// Purpose: the same movie-follow / ABA / F11-latch rules the DLL uses.
// Tests drive this type so a mutant that gates on tid, heals, or
// Invokes a foreign movie is caught. Author: Moragar.
// Last modified: 2026-10-28.
struct PollGate
{
	const void*   hudRoot{nullptr};
	const void*   hudMsgRoot{nullptr};
	std::uint32_t uiTidHint{0};
	std::uint32_t lastHudPollTid{0};
	std::uint32_t lastMsgPollTid{0};
	const void*   lastHudRoot{nullptr};
	std::uint64_t hudPolls{0};
	std::uint64_t msgPolls{0};
	bool          settingsKeyReq{false};
	bool          wasDownJob{false};
	int           settingsOpens{0};
	bool          inHudPoll{false};
	bool          inMsgPoll{false};
	std::uint64_t lastHeartbeatMs{0};
	int           heartbeats{0};
	bool          hudSafe{false};

	void OnMenuCreated(const char* a_name, const void* a_root, std::uint32_t = 0)
	{
		if (!a_root) return;
		if (ShouldClearReusedHudRoot(hudRoot, a_root, MenuIsHud(a_name)))
			hudRoot = nullptr;
		if (ShouldClearReusedHudRoot(hudMsgRoot, a_root, MenuIsHudMessages(a_name)))
			hudMsgRoot = nullptr;
		if (MenuIsHud(a_name))
			hudRoot = a_root;
		else if (MenuIsHudMessages(a_name))
			hudMsgRoot = a_root;
	}

	bool IsStoredHudRoot(const void* a_root) const
	{
		return hzlog::IsStoredHudRoot(a_root, hudRoot, hudMsgRoot);
	}

	void JobKey(bool a_down)
	{
		if (SettingsKeyEdge(a_down, wasDownJob))
			settingsKeyReq = true;
		wasDownJob = a_down;
	}

	bool ConsumeSettingsKey()
	{
		const bool had = settingsKeyReq;
		settingsKeyReq = false;
		return had;
	}

	PollMovie OnAdvance(const void* a_root, std::uint32_t a_tid, std::uint64_t a_nowMs = 0)
	{
		const auto kind = PollMovieForRoot(a_root, hudRoot, hudMsgRoot);
		if (kind == PollMovie::Hud) {
			if (UiTidRecordFirst(uiTidHint, a_tid))
				uiTidHint = a_tid;
			if (PollAlreadyIn(inHudPoll))
				return kind;
			inHudPoll = true;
			lastHudPollTid = a_tid;
			lastHudRoot = a_root;
			++hudPolls;
			if (ConsumeSettingsKey())
				++settingsOpens;
			if (PollHeartbeatDue(lastHeartbeatMs, a_nowMs)) {
				++heartbeats;
				lastHeartbeatMs = a_nowMs;
			}
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
