#pragma once

// Purpose: adopt g_uiTid only from a stored HUD / HUDMessages root
// AdvanceFrame. Window-owner and any-menu tids are hints. A reused
// movie-root address is cleared on MenuMovieCreated. A later HUD-root
// tid is adopted only after ~500 ms of sustained HUD-root advances on
// the new tid and none on the recorded one.
// Inputs: menu name / root pointer / tid / now-ms. Outputs: first
// record or a hysteresis switch. Author: Moragar.
// Last modified: 2026-10-28.

#include <cstdint>
#include <cstring>

namespace hzlog {

inline constexpr std::uint64_t kUiTidHysteresisMs = 500;
inline constexpr std::uint64_t kUiTidSwitchLogMs = 1000;
inline constexpr const char* kUiTidSourceHudRoot = "hud-root-advance";

inline bool MenuIsHud(const char* a_name)
{
	return a_name && std::strcmp(a_name, "HUDMenu") == 0;
}

inline bool MenuIsHudMessages(const char* a_name)
{
	return a_name && std::strcmp(a_name, "HUDMessagesMenu") == 0;
}

inline bool MenuStoresHudRoot(const char* a_name)
{
	return MenuIsHud(a_name) || MenuIsHudMessages(a_name);
}

// Purpose: a new movie at a stored HUD root address is not that HUD.
// Null the stored pointer so AdvanceFrame cannot treat a reused
// Pause/Map/loading root as the HUD (ABA). Inputs: stored pointer,
// the new root, whether this create is that HUD menu.
inline bool ShouldClearReusedHudRoot(const void* a_stored, const void* a_newRoot, bool a_thisIsThatHud)
{
	return a_newRoot && a_stored && a_stored == a_newRoot && !a_thisIsThatHud;
}

inline bool IsStoredHudRoot(const void* a_root, const void* a_hudRoot, const void* a_hudMsgRoot)
{
	return a_root && (a_root == a_hudRoot || a_root == a_hudMsgRoot);
}

enum class UiTidHint : std::uint8_t { WindowOwner = 0, AnyMenu, HudRootAdvance };

inline bool UiTidHintAdopts(UiTidHint a_hint, bool a_isStoredHudRoot)
{
	return a_hint == UiTidHint::HudRootAdvance && a_isStoredHudRoot;
}

enum class UiTidAction : std::uint8_t { None = 0, RecordFirst, Switch };

struct UiTidDecision
{
	UiTidAction   action{UiTidAction::None};
	std::uint32_t from{0};
	std::uint32_t to{0};
};

inline bool UiTidSwitchLogDue(std::uint64_t a_lastLogMs, std::uint64_t a_nowMs,
	std::uint64_t a_gapMs = kUiTidSwitchLogMs)
{
	return a_lastLogMs == 0 || a_nowMs < a_lastLogMs || (a_nowMs - a_lastLogMs) >= a_gapMs;
}

// Purpose: first HUD-root advance records at once. A later tid is
// adopted only after kUiTidHysteresisMs of stored-HUD-root advances
// on that tid and none on the recorded tid. Inputs: recorded tid,
// this advance, now-ms, last recorded HUD ms, candidate tid/since
// (in-out). Outputs: none / first record / switch.
inline UiTidDecision UiTidOnHudAdvance(std::uint32_t a_recorded, std::uint32_t a_tid,
	std::uint64_t a_nowMs, std::uint64_t& a_lastRecordedHudMs,
	std::uint32_t& a_candTid, std::uint64_t& a_candSinceMs)
{
	if (!a_tid) return {};
	if (a_recorded == 0) {
		a_lastRecordedHudMs = a_nowMs;
		a_candTid = 0;
		a_candSinceMs = 0;
		return {UiTidAction::RecordFirst, 0, a_tid};
	}
	if (a_tid == a_recorded) {
		a_lastRecordedHudMs = a_nowMs;
		a_candTid = 0;
		a_candSinceMs = 0;
		return {};
	}
	if (a_candTid != a_tid) {
		a_candTid = a_tid;
		a_candSinceMs = a_nowMs;
		return {};
	}
	const bool neu = a_nowMs >= a_candSinceMs
		&& (a_nowMs - a_candSinceMs) >= kUiTidHysteresisMs;
	const bool quiet = a_nowMs >= a_lastRecordedHudMs
		&& (a_nowMs - a_lastRecordedHudMs) >= kUiTidHysteresisMs;
	if (!neu || !quiet) return {};
	a_lastRecordedHudMs = a_nowMs;
	a_candTid = 0;
	a_candSinceMs = 0;
	return {UiTidAction::Switch, a_recorded, a_tid};
}

inline bool PollAlreadyIn(bool a_previous)
{
	return a_previous;
}

// Purpose: the same adopt / ABA / hysteresis rules the DLL uses.
// Tests drive this type so a mutant of IsStoredHudRoot, the heal
// store, or a one-shot latch is caught. Author: Moragar.
// Last modified: 2026-10-28.
struct UiTidRecorder
{
	std::uint32_t tid{0};
	const char*   source{nullptr};
	bool          healed{false};
	int           switchCount{0};
	int           switchLogs{0};
	const void*   hudRoot{nullptr};
	const void*   hudMsgRoot{nullptr};
	std::uint64_t lastRecordedHudMs{0};
	std::uint32_t candTid{0};
	std::uint64_t candSinceMs{0};
	std::uint64_t lastSwitchLogMs{0};

	void HintWindowOwner(std::uint32_t)
	{
	}

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

	void OnAdvance(const void* a_root, std::uint32_t a_tid, std::uint64_t a_nowMs = 0)
	{
		if (!UiTidHintAdopts(UiTidHint::HudRootAdvance, IsStoredHudRoot(a_root)) || !a_tid)
			return;
		const auto d = UiTidOnHudAdvance(tid, a_tid, a_nowMs, lastRecordedHudMs, candTid, candSinceMs);
		if (d.action == UiTidAction::RecordFirst) {
			tid = d.to;
			source = kUiTidSourceHudRoot;
			return;
		}
		if (d.action != UiTidAction::Switch)
			return;
		healed = true;
		++switchCount;
		tid = d.to;
		source = kUiTidSourceHudRoot;
		if (UiTidSwitchLogDue(lastSwitchLogMs, a_nowMs)) {
			++switchLogs;
			lastSwitchLogMs = a_nowMs;
		}
	}
};

}
