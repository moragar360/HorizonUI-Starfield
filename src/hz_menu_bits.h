#pragma once

// Purpose: perf round 2 Fix 2. The blocking-menu check (HudMenusClear / HudBlockingMenu) reads one 64-bit set
// of open menus instead of ~83 IsMenuOpen lookups on every movie advance (about twice per frame, each lookup
// building a temporary BSFixedString). Bit 0 is HUDMenu, then the HUD block list, then the v0.42.0 deny list,
// in the order main.cpp lists them, so the first set bit is the menu the old loops named.
// The set is kept conservative, so the HUD is never treated as uncovered earlier than the old full scan would:
//  - blocker bits (1 .. 63) err toward "covered": an open event sets its bit at once and holds it as "pending"
//    through the scans until IsMenuOpen agrees (an open event can arrive before IsMenuOpen turns true), for at
//    most kPendHoldMs; a close event drops the hold and only asks for a rescan, so IsMenuOpen stays the
//    authority for "closed", exactly as before;
//  - bit 0 (HUDMenu) errs toward "closed" (that is the covered side for bit 0): an open event never sets it, it
//    only asks for a rescan on every check until the scan shows the HUD; a close event clears it at once and
//    asks for the same rescans until the scan no longer shows the HUD. Bit 0 is never held pending;
//  - a full scan (cached name strings) seeds the set, and runs again whenever the set is older than
//    hzlog::kHudSafeCacheMs (the existing HudSafe 150 ms cadence), so an event that never arrives costs at
//    most 150 ms;
//  - a scan that raced an event is not stored (the next check scans again), and an event that lands between
//    that check and the store is put back right after the store (the start / done counters are read again).
// Check and EventStep below are the reader and the sink themselves; main.cpp runs them on its atomics, the
// tests run them on a model that can inject an event before any shared read or write.
// No game, no CommonLibSF, no thread of its own (tests/menu_bits_test.cpp).
// Author: Moragar. Last modified: 2026-11-14.

#include <cstdint>

namespace hzmenu {

inline constexpr std::uint64_t kHudBit = 1;   // bit 0: HUDMenu must be open

// True when HUDMenu is open and no blocking menu is. a_light = false ignores the light menus (ScopeMenu).
inline bool Clear(std::uint64_t a_bits, bool a_light, std::uint64_t a_lightBits)
{
	if ((a_bits & kHudBit) == 0) return false;
	std::uint64_t block = a_bits & ~kHudBit;
	if (!a_light) block &= ~a_lightBits;
	return block == 0;
}

// The menu the old HudBlockingMenu named: 0 (HUDMenu) when the HUD is closed, else the lowest set bit >= 1,
// or -1 when nothing blocks.
inline int FirstBlocking(std::uint64_t a_bits)
{
	if ((a_bits & kHudBit) == 0) return 0;
	const std::uint64_t block = a_bits & ~kHudBit;
	if (block == 0) return -1;
	int i = 1;
	while (((block >> i) & 1u) == 0) ++i;
	return i;
}

// One blocker open / close event for list index a_idx (1 .. 63) on a plain set. Opening sets the bit. Closing
// leaves it (the rescan it requests decides). (HUDMenu, index 0, goes through EventStep instead.)
inline std::uint64_t OnEvent(std::uint64_t a_bits, int a_idx, bool a_opening)
{
	if (a_idx < 0 || a_idx > 63) return a_bits;
	return a_opening ? (a_bits | (std::uint64_t{ 1 } << a_idx)) : a_bits;
}

// How long an open event is held while IsMenuOpen does not show that menu yet (two HudSafe periods).
inline constexpr std::uint64_t kPendHoldMs = 300;

struct Merged
{
	std::uint64_t bits;   // the set to store: the scan plus the still-pending opens
	std::uint64_t pend;   // opens still waiting for IsMenuOpen
};

// Store step of a scan: opens the scan confirms leave "pending"; the rest stay while younger than a_holdMs
// (a_pendAt is the last open event's time; a clock that went back drops them).
inline Merged MergeScan(std::uint64_t a_scan, std::uint64_t a_pend, std::uint64_t a_pendAt, std::uint64_t a_now, std::uint64_t a_holdMs)
{
	std::uint64_t pend = a_pend & ~a_scan;
	if (pend != 0 && (a_now < a_pendAt || (a_now - a_pendAt) >= a_holdMs)) pend = 0;
	return { a_scan | pend, pend };
}

// True when the set must be scanned again: never seeded (a_at == 0), a close asked for it, the clock went
// back, or it is older than a_maxAgeMs.
inline bool ScanDue(std::uint64_t a_at, bool a_dirty, std::uint64_t a_now, std::uint64_t a_maxAgeMs)
{
	if (a_at == 0 || a_dirty) return true;
	if (a_now < a_at) return true;
	return (a_now - a_at) >= a_maxAgeMs;
}

// A finished scan is stored only when no event landed while it ran (event generation unchanged).
inline bool ScanKeep(std::uint32_t a_genBefore, std::uint32_t a_genAfter)
{
	return a_genBefore == a_genAfter;
}

// The answer for a check whose scan was not stored: blockers covered if either side says so, the HUD open only
// if both say so.
inline std::uint64_t Combine(std::uint64_t a_scan, std::uint64_t a_kept)
{
	return ((a_scan | a_kept) & ~kHudBit) | (a_scan & a_kept & kHudBit);
}

// HUD watch states (a HUDMenu event asks for a rescan on every check until the scan agrees with it).
inline constexpr int kHudWatchNone = -1;
inline constexpr int kHudWatchClosed = 0;
inline constexpr int kHudWatchOpen = 1;

// True when a scan settles the HUD watch (the scan shows the HUD state the last HUDMenu event named).
inline bool HudWatchDone(int a_want, std::uint64_t a_scan)
{
	return a_want == kHudWatchNone || ((a_scan & kHudBit) != 0) == (a_want == kHudWatchOpen);
}

struct CheckOut
{
	std::uint64_t bits;    // the answer for this check
	bool stored;           // a scan was stored
	std::uint64_t unseen;  // blocker bits a stored scan found that the kept set did not have (missed open events)
};

// The reader (HzMenuBits). A is the shared state: main.cpp's atomics, or the test model. Every shared read or
// write is one call on A (the model can inject an event before any of them). Order matters, see the comments.
template <class A>
CheckOut Check(A& a, std::uint64_t a_now, std::uint64_t a_maxAgeMs)
{
	const std::uint64_t at = a.At();
	const int want = a.HudWant();
	if (want == kHudWatchNone && !ScanDue(at, a.Dirty(), a_now, a_maxAgeMs))
		return { a.Bits(), false, 0 };
	if (a.BusyTake()) {
		// another thread is storing a scan: until the first seed, scan here too (not stored); after it, the kept
		// set (blocker bits only leave on a scan, so they err toward covered; a HUD close clears bit 0 at once
		// and a HUD open never sets it, so bit 0 errs toward closed)
		return { at ? a.Bits() : a.Scan(), false, 0 };
	}
	struct Release { A& r; ~Release() { r.BusyDrop(); } } release{ a };
	a.SetDirty(false);
	const std::uint32_t gen0 = a.Gen();
	const std::uint32_t done0 = a.Done();   // != gen0: an event is still writing
	const std::uint32_t hud0 = a.HudGen();
	const std::uint64_t scan = a.Scan();
	if (!ScanKeep(gen0, a.Gen())) {
		// an event landed during the scan: not stored, scanned again on the next check
		a.SetDirty(true);
		return { Combine(scan, a.Bits()), false, 0 };
	}
	const std::uint64_t pend0 = a.Pend();
	const Merged mg = MergeScan(scan, pend0 & ~kHudBit, a.PendAt(), a_now, kPendHoldMs);
	if (mg.pend != pend0) a.PendSwap(pend0, mg.pend);   // only if no open event changed it meanwhile
	const std::uint64_t old = a.BitsSwap(mg.bits);
	a.SetAt(a_now ? a_now : 1);
	std::uint64_t out = mg.bits;
	if (a.Gen() != gen0 || a.Done() != done0 || gen0 != done0) {
		// an event started, finished or was still writing around the store: its bits write may have been
		// overwritten. Put its opens back (the sink writes pend before bits, so pend has them by now), and for a
		// HUD event (or one we cannot name) clear bit 0 until the rescan; both err toward covered
		const std::uint64_t back = a.Pend() & ~kHudBit;
		if (back) { a.BitsOr(back); out |= back; }
		if (a.HudGen() != hud0 || gen0 != done0) { a.BitsAnd(~kHudBit); out &= ~kHudBit; }
		a.SetDirty(true);
	} else if (want != kHudWatchNone && HudWatchDone(want, scan)) {
		a.HudWantSwap(want, kHudWatchNone);   // only if no new HUD event changed it meanwhile
	}
	return { out, true, at ? (scan & ~old & ~kHudBit) : 0 };
}

// The sink (MenuOpenCloseEvent), split into steps so the tests can put a reader step between any two of them;
// main.cpp runs all kEventSteps steps in order. The start counter goes first and the done counter last, so a
// reader can tell an event started, finished or is still writing around its store.
inline constexpr int kEventSteps = 5;
template <class A>
void EventStep(A& a, int a_step, int a_idx, bool a_opening, std::uint64_t a_now)
{
	if (a_idx < 0 || a_idx > 63) return;
	const std::uint64_t bit = std::uint64_t{ 1 } << a_idx;
	if (a_idx == 0) {   // HUDMenu: never pending, never set by an event
		switch (a_step) {
		case 0: a.HudGenInc(); break;
		case 1: a.GenInc(); break;
		case 2: if (!a_opening) a.BitsAnd(~kHudBit); break;
		case 3: a.SetHudWant(a_opening ? kHudWatchOpen : kHudWatchClosed); break;
		case 4: a.DoneInc(); break;
		default: break;
		}
		return;
	}
	switch (a_step) {
	case 0: a.GenInc(); break;
	case 1: if (a_opening) a.SetPendAt(a_now); else a.PendAnd(~bit); break;
	case 2: if (a_opening) a.PendOr(bit); else a.SetDirty(true); break;
	case 3: if (a_opening) a.BitsOr(bit); break;
	case 4: a.DoneInc(); break;
	default: break;
	}
}
template <class A>
void Event(A& a, int a_idx, bool a_opening, std::uint64_t a_now)
{
	for (int s = 0; s < kEventSteps; ++s) EventStep(a, s, a_idx, a_opening, a_now);
}

}  // namespace hzmenu
