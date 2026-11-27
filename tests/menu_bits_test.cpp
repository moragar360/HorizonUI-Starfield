// Unit tests for perf round 2 Fix 2 (src/hz_menu_bits.h): the HUD menu check reads an event-kept open-menu set.
// No game, no CommonLibSF, no thread. Build:
//   g++ -std=c++20 -Wall -Wextra -Wpedantic -I src tests/menu_bits_test.cpp -o test_scratch/menu_bits_test
// Proves:
//  1. Clear / FirstBlocking give the same answers as the e4d7b75 HudMenusClear / HudBlockingMenu loops (copied
//     below over a fake menu map) for every light flag and for random and exhaustive small menu states;
//  2. the event + scan model never reports "clear" while the old per-call scan would report "covered", for random
//     sequences of opens, closes, late IsMenuOpen updates, scans and checks (it may report "covered" longer, by
//     at most one rescan);
//  3. a missed open event is caught by the next due scan (at most kHudSafeCacheMs late), and ScanDue / ScanKeep /
//     OnEvent edge cases.
// Author: Moragar. Last modified: 2026-11-14.

#include "hz_menu_bits.h"

#include <cstdint>
#include <cstring>
#include <fstream>
#include <functional>
#include <iostream>
#include <sstream>
#include <random>
#include <string>
#include <vector>

namespace {

int g_fail = 0, g_ok = 0;
void Expect(bool a_cond, const std::string& a_msg)
{
	if (a_cond) { ++g_ok; return; }
	++g_fail;
	std::cout << "FAIL " << a_msg << "\n";
}

// The lists exactly as main.cpp has them (order matters: the first set bit names the menu).
const char* const kBlock[] = {
	"LoadingMenu", "FaderMenu", "MainMenu", "PauseMenu", "Console",
	"SpaceshipEditorMenu", "WorkshopMenu", "WorkshopBuilderMenu", "InventoryMenu",
	"PhotoModeMenu", "GalaxyStarMapMenu", "DataMenu", "ShipCrewMenu", "ShipCrewAssignMenu",
	"SpaceshipInfoMenu",
	"SkillsMenu", "BSMissionMenu", "PowersMenu", "StatusMenu", "ResearchMenu",
	"ArmorCraftingMenu", "WeaponsCraftingMenu", "DrugsCraftingMenu", "FoodCraftingMenu",
	"IndustrialCraftingMenu", "ContainerMenu", "BarterMenu", "GenesisTerminalMenu",
	"SecurityMenu", "ChargenMenu", "PhotoGalleryMenu", "Workshop_BlueprintMenu"
};
const char* const kDeny[] = {
	"PickpocketMenu", "MissionBoard", "WorkshopTargetMenu", "WorkshopQuickMenu",
	"ShipRefuelMenu", "SleepWaitMenu", "SitWaitMenu", "BookMenu", "DataSlateMenu", "MessageBoxMenu",
	"PlayBinkMenu", "CreditsMenu", "EndGameCreditsMenu", "TitleSequenceMenu", "WeaponGroupAssignmentMenu",
	"TakeoffMenu", "FavoritesMenu", "MarketplaceMenu", "AlmanacMenu", "DialogueMenu",
	"DocAcceptMenu", "StreamingInstallMenu", "TestMenu", "ScopeMenu", "InspectMenu"
};
const char* const kLight[] = { "ScopeMenu" };
constexpr std::size_t kBlockN = sizeof(kBlock) / sizeof(kBlock[0]);
constexpr std::size_t kDenyN = sizeof(kDeny) / sizeof(kDeny[0]);
constexpr std::size_t kN = 1 + kBlockN + kDenyN;

const char* Raw(std::size_t i) { return i == 0 ? "HUDMenu" : (i <= kBlockN ? kBlock[i - 1] : kDeny[i - 1 - kBlockN]); }
std::uint64_t LightBits()
{
	std::uint64_t b = 0;
	for (std::size_t i = 0; i < kDenyN; ++i)
		for (auto l : kLight)
			if (std::strcmp(kDeny[i], l) == 0) b |= std::uint64_t{ 1 } << (1 + kBlockN + i);
	return b;
}

// Fake menu map: IsMenuOpen(name) reads the "truth" bits.
struct FakeUi
{
	std::uint64_t truth = 0;
	int lookups = 0;
	bool IsMenuOpen(const char* a_name)
	{
		++lookups;
		for (std::size_t i = 0; i < kN; ++i)
			if (std::strcmp(Raw(i), a_name) == 0) return ((truth >> i) & 1u) != 0;
		return false;
	}
};

// e4d7b75 bodies (types adapted to FakeUi).
bool LightMenuOpenOld(FakeUi* a_ui) { for (auto m : kLight) if (a_ui->IsMenuOpen(m)) return true; return false; }
bool HudMenusClearOld(FakeUi* a_ui, bool a_light)
{
	if (!a_ui->IsMenuOpen("HUDMenu")) return false;
	for (auto m : kBlock)
		if (a_ui->IsMenuOpen(m)) return false;
	for (auto m : kDeny)
		if ((a_light || !LightMenuOpenOld(a_ui) || std::strcmp(m, "ScopeMenu") != 0) && a_ui->IsMenuOpen(m)) return false;
	return true;
}
const char* HudBlockingMenuOld(FakeUi* a_ui)
{
	if (!a_ui->IsMenuOpen("HUDMenu")) return "HUDMenu";
	for (auto m : kBlock)
		if (a_ui->IsMenuOpen(m)) return m;
	for (auto m : kDeny)
		if (a_ui->IsMenuOpen(m)) return m;
	return "menu";
}
const char* HudBlockingMenuNew(std::uint64_t a_bits)
{
	const int i = hzmenu::FirstBlocking(a_bits);
	if (i < 0 || static_cast<std::size_t>(i) >= kN) return "menu";
	return Raw(static_cast<std::size_t>(i));
}

// The shared state hzmenu::Check / hzmenu::EventStep run on (main.cpp runs the same two templates on its
// atomics). Every shared read / write calls Hook() first, so a test can run sink steps before any of them.
struct Model
{
	std::uint64_t bits = 0, at = 0, pend = 0, pendAt = 0, clock = 0;
	bool dirty = false, busy = false;
	std::uint32_t gen = 0, done = 0, hudGen = 0;
	int hudWant = hzmenu::kHudWatchNone;
	int scans = 0;
	FakeUi* ui = nullptr;
	std::function<void()> hook;   // runs before every shared access of the reader (not of the sink)
	bool inSink = false;
	int ops = 0;                  // reader shared accesses so far
	bool midPending = false;      // the old "event during the scan" switch
	int midIdx = 0;
	void Hook() { if (inSink) return; ++ops; if (hook) hook(); }
	std::uint64_t At() { Hook(); return at; }
	void SetAt(std::uint64_t v) { Hook(); at = v; }
	int HudWant() { Hook(); return hudWant; }
	void SetHudWant(int v) { Hook(); hudWant = v; }
	void HudWantSwap(int f, int t) { Hook(); if (hudWant == f) hudWant = t; }
	bool Dirty() { Hook(); return dirty; }
	void SetDirty(bool v) { Hook(); dirty = v; }
	std::uint64_t Bits() { Hook(); return bits; }
	std::uint64_t BitsSwap(std::uint64_t v) { Hook(); const auto o = bits; bits = v; return o; }
	void BitsOr(std::uint64_t v) { Hook(); bits |= v; }
	void BitsAnd(std::uint64_t v) { Hook(); bits &= v; }
	std::uint32_t Gen() { Hook(); return gen; }
	void GenInc() { Hook(); ++gen; }
	std::uint32_t Done() { Hook(); return done; }
	void DoneInc() { Hook(); ++done; }
	std::uint32_t HudGen() { Hook(); return hudGen; }
	void HudGenInc() { Hook(); ++hudGen; }
	std::uint64_t Pend() { Hook(); return pend; }
	void PendSwap(std::uint64_t f, std::uint64_t t) { Hook(); if (pend == f) pend = t; }
	void PendOr(std::uint64_t v) { Hook(); pend |= v; }
	void PendAnd(std::uint64_t v) { Hook(); pend &= v; }
	std::uint64_t PendAt() { Hook(); return pendAt; }
	void SetPendAt(std::uint64_t v) { Hook(); pendAt = v; }
	bool BusyTake() { Hook(); const bool o = busy; busy = true; return o; }
	void BusyDrop() { Hook(); busy = false; }
	std::uint64_t Scan()
	{
		Hook();
		std::uint64_t s = 0;
		for (std::size_t i = 0; i < kN; ++i) if (ui->IsMenuOpen(Raw(i))) s |= std::uint64_t{ 1 } << i;
		++scans;
		if (midPending) { midPending = false; ui->truth |= std::uint64_t{ 1 } << midIdx; Event(midIdx, true); }
		return s;
	}
	void Step(int a_step, int a_idx, bool a_opening)
	{
		inSink = true;
		hzmenu::EventStep(*this, a_step, a_idx, a_opening, clock);
		inSink = false;
	}
	void Event(int a_idx, bool a_opening) { for (int k = 0; k < hzmenu::kEventSteps; ++k) Step(k, a_idx, a_opening); }
	std::uint64_t Check(FakeUi& a_ui, std::uint64_t a_now, std::uint64_t a_maxAge, bool a_eventMidScan = false, int a_midIdx = 0)
	{
		clock = a_now;
		ui = &a_ui;
		midPending = a_eventMidScan;
		midIdx = a_midIdx;
		const auto r = hzmenu::Check(*this, a_now, a_maxAge);
		midPending = false;
		return r.bits;
	}
};

}  // namespace

int main()
{
	const auto lightBits = LightBits();
	Expect(kN == 58, "58 watched names (1 + 32 + 25), one 64-bit word");
	Expect(lightBits == (std::uint64_t{ 1 } << (1 + kBlockN + 23)), "ScopeMenu is the only light bit");

	// ---- 1. same answers as the old loops ----
	{
		std::mt19937_64 rng(1114);
		int same = 0, total = 0;
		std::vector<std::uint64_t> states;
		for (std::size_t i = 0; i < kN; ++i) {   // HUD open + each single menu, HUD closed + each single menu
			states.push_back(1 | (std::uint64_t{ 1 } << i));
			states.push_back(std::uint64_t{ 1 } << i);
		}
		states.push_back(0);
		states.push_back(1);
		for (int k = 0; k < 20000; ++k) {
			std::uint64_t t = 1;   // HUD mostly open
			const int n = static_cast<int>(rng() % 4);
			for (int j = 0; j < n; ++j) t |= std::uint64_t{ 1 } << (rng() % kN);
			if (rng() % 8 == 0) t &= ~std::uint64_t{ 1 };
			states.push_back(t);
		}
		for (auto t : states) {
			FakeUi ui;
			ui.truth = t;
			for (bool light : { true, false }) {
				++total;
				if (HudMenusClearOld(&ui, light) == hzmenu::Clear(t, light, lightBits)) ++same;
			}
			++total;
			if (std::strcmp(HudBlockingMenuOld(&ui), HudBlockingMenuNew(t)) == 0) ++same;
		}
		Expect(same == total, "Clear / FirstBlocking equal the e4d7b75 loops on " + std::to_string(total) + " cases (" + std::to_string(same) + " same)");
		FakeUi ui;
		ui.truth = 1;
		ui.lookups = 0;
		HudMenusClearOld(&ui, false);
		Expect(ui.lookups == 83, "old HudMenusClear(false) with nothing open: 83 lookups (got " + std::to_string(ui.lookups) + ")");
		ui.truth = 1 | lightBits;
		Expect(hzmenu::Clear(ui.truth, false, lightBits) && !hzmenu::Clear(ui.truth, true, lightBits), "scope only: clear for the HUD check, blocked for F11");
	}

	// ---- 2. never "clear" while the old scan says "covered" ----
	{
		for (bool allowMissed : { false, true }) {
		std::mt19937_64 rng(allowMissed ? 4242 : 4343);
		int unsafe = 0, early = 0, checks = 0, laterCovered = 0, maxScans = 0, hudEvents = 0;
		for (int run = 0; run < 400; ++run) {
			FakeUi ui;
			ui.truth = 1;
			Model m;
			std::uint64_t now = 1000;
			std::vector<int> pendingOpen;   // menus whose open event fired before IsMenuOpen turned true
			std::vector<int> pendingClose;  // HUDMenu: close event fired before the map dropped it
			for (int step = 0; step < 3000; ++step) {
				now += 1 + rng() % 12;   // 1-12 ms per check (several checks per frame, uneven)
				m.clock = now;           // event time (the sink reads GetTickCount64)
				const int r = static_cast<int>(rng() % 100);
				const int idx = 1 + static_cast<int>(rng() % (kN - 1));
				if (r < 3) {   // open: event first, IsMenuOpen now or one check later
					m.Event(idx, true);
					if (rng() % 2) ui.truth |= std::uint64_t{ 1 } << idx; else pendingOpen.push_back(idx);
				} else if (r < 6) {   // close: IsMenuOpen false now or one check later, then the event
					const bool late = rng() % 2;
					for (auto& p : pendingOpen) if (p == idx) p = -1;   // a close cancels its own late open
					if (!late) ui.truth &= ~(std::uint64_t{ 1 } << idx);
					m.Event(idx, false);
					if (late) ui.truth &= ~(std::uint64_t{ 1 } << idx);
				} else if (r < 7 && allowMissed) {   // open with no event at all (a missed event)
					ui.truth |= std::uint64_t{ 1 } << idx;
				} else if (r == 8 && (ui.truth & 1u)) {   // HUDMenu close: map updated before the event or a check later
					const bool late = rng() % 2;
					if (!late) ui.truth &= ~std::uint64_t{ 1 };
					m.Event(0, false);
					if (late) pendingClose.push_back(0);
					++hudEvents;
				} else if ((r == 9 || r == 10) && !(ui.truth & 1u)) {   // HUDMenu open: map now or a check later
					m.Event(0, true);
					if (rng() % 2) ui.truth |= 1u; else pendingOpen.push_back(0);
					++hudEvents;
				}
				const bool mid = rng() % 50 == 0;
				const auto got = m.Check(ui, now, 150, mid, idx);
				const bool oldClear = hzmenu::Clear(ui.truth, false, lightBits);
				const bool newClear = hzmenu::Clear(got, false, lightBits);
				++checks;
				if (newClear && !oldClear) {
					++early;
					// allowed only for an open with no event at all, and only until the next due scan
					if (!(m.at && now - m.at < 150)) ++unsafe;
				}
				if (!newClear && oldClear) ++laterCovered;
				for (int p : pendingOpen) if (p >= 0) ui.truth |= std::uint64_t{ 1 } << p;
				for (int p : pendingClose) ui.truth &= ~(std::uint64_t{ 1 } << p);
				pendingOpen.clear();
				pendingClose.clear();
			}
			if (m.scans > maxScans) maxScans = m.scans;
		}
		if (!allowMissed)
			Expect(early == 0, "every open has its event: never clear while the old scan is covered (" + std::to_string(checks) + " checks, " + std::to_string(early) + " early)");
		else
			Expect(unsafe == 0, "with missed open events: clear-while-covered only inside the 150 ms window before the next scan (" + std::to_string(checks) + " checks, " + std::to_string(early) + " in-window, " + std::to_string(unsafe) + " beyond)");
		Expect(laterCovered > 0, "the model can stay covered a little longer than the old scan (conservative), as designed: " + std::to_string(laterCovered) + " checks");
		Expect(hudEvents > 100, "the random runs include HUDMenu opens and closes (" + std::to_string(hudEvents) + ")");
		Expect(maxScans < 3000, "scans happen far less often than checks (max " + std::to_string(maxScans) + " of 3000 checks in one run)");
		}
	}

	// ---- 0. the lists above are the ones in src/main.cpp (run from the repo root) ----
	{
		std::ifstream f("src/main.cpp");
		std::stringstream ss;
		ss << f.rdbuf();
		const std::string src = ss.str();
		auto listOf = [&](const char* a_decl) {
			std::vector<std::string> out;
			const auto at = src.find(a_decl);
			if (at == std::string::npos) return out;
			const auto open = src.find('{', at), close = src.find("};", at);
			for (auto p = src.find('"', open); p != std::string::npos && p < close; ) {
				const auto q = src.find('"', p + 1);
				out.push_back(src.substr(p + 1, q - p - 1));
				p = src.find('"', q + 1);
			}
			return out;
		};
		const auto b = listOf("const char* const kHudBlockMenus[]");
		const auto d = listOf("constexpr const char* kDenyMenus42[]");
		bool same = b.size() == kBlockN && d.size() == kDenyN;
		for (std::size_t i = 0; same && i < kBlockN; ++i) same = b[i] == kBlock[i];
		for (std::size_t i = 0; same && i < kDenyN; ++i) same = d[i] == kDeny[i];
		Expect(!src.empty() && same, "the block and deny lists here match src/main.cpp, in order (" + std::to_string(b.size()) + " + " + std::to_string(d.size()) + ")");
	}

	// ---- 2b. without any event an event-free session scans once per 150 ms, not per check ----
	{
		FakeUi ui;
		ui.truth = 1;
		Model m;
		std::uint64_t now = 5000;
		for (int i = 0; i < 2000; ++i) { now += 3; m.Check(ui, now, 150); }   // 2000 checks over 6 s
		Expect(m.scans >= 39 && m.scans <= 42, "steady HUD: about one scan per 150 ms (" + std::to_string(m.scans) + " scans for 2000 checks over 6 s)");
		Expect(ui.lookups == m.scans * static_cast<int>(kN), "each scan is one pass over the 58 names; checks in between do no lookup");
	}

	// ---- 3. missed open caught by the next due scan; edge cases ----
	{
		FakeUi ui;
		ui.truth = 1;
		Model m;
		m.Check(ui, 1000, 150);
		ui.truth |= std::uint64_t{ 1 } << 9;   // InventoryMenu opens, no event
		Expect(hzmenu::Clear(m.Check(ui, 1100, 150), false, lightBits), "missed open: still clear before the scan is due (the stated risk)");
		Expect(!hzmenu::Clear(m.Check(ui, 1150, 150), false, lightBits), "missed open: covered by the scan at 150 ms");
		m.Event(9, false);
		ui.truth &= ~(std::uint64_t{ 1 } << 9);
		Expect(hzmenu::Clear(m.Check(ui, 1151, 150), false, lightBits), "a close event rescans on the very next check");
		Expect(hzmenu::ScanDue(0, false, 5, 150) && hzmenu::ScanDue(10, true, 11, 150) && hzmenu::ScanDue(100, false, 50, 150), "ScanDue: unseeded, dirty, clock went back");
		Expect(!hzmenu::ScanDue(100, false, 249, 150) && hzmenu::ScanDue(100, false, 250, 150), "ScanDue: fresh below 150 ms, due at 150 ms");
		Expect(hzmenu::ScanKeep(7, 7) && !hzmenu::ScanKeep(7, 8), "ScanKeep: a scan that raced an event is not stored");
		Expect(hzmenu::OnEvent(0, 5, true) == 32 && hzmenu::OnEvent(32, 5, false) == 32, "OnEvent: open sets, close leaves the bit for the rescan");
		Expect(hzmenu::OnEvent(1, 64, true) == 1 && hzmenu::OnEvent(1, -1, true) == 1, "OnEvent: out-of-range index ignored");
		Expect(hzmenu::FirstBlocking(0) == 0 && hzmenu::FirstBlocking(1) == -1 && hzmenu::FirstBlocking(1 | (std::uint64_t{ 1 } << 63)) == 63, "FirstBlocking: HUD closed, nothing, bit 63");
		{
			const auto a = hzmenu::MergeScan(1, 32, 1000, 1100, 300);
			const auto b = hzmenu::MergeScan(33, 32, 1000, 1100, 300);
			const auto c = hzmenu::MergeScan(1, 32, 1000, 1300, 300);
			const auto d = hzmenu::MergeScan(1, 32, 1000, 900, 300);
			Expect(a.bits == 33 && a.pend == 32, "MergeScan: an open IsMenuOpen does not show yet is held");
			Expect(b.bits == 33 && b.pend == 0, "MergeScan: confirmed by the scan, no longer pending");
			Expect(c.bits == 1 && c.pend == 0 && d.bits == 1, "MergeScan: dropped after 300 ms or when the clock went back");
			FakeUi u;
			u.truth = 1;
			Model h;
			h.Check(u, 1000, 150);
			h.clock = 1010;
			h.Event(9, true);   // open event, IsMenuOpen still false
			h.Event(3, false);  // an unrelated close forces a rescan
			Expect(!hzmenu::Clear(h.Check(u, 1011, 150), false, lightBits), "an open event survives a rescan that runs before IsMenuOpen turns true");
			Expect(hzmenu::Clear(h.Check(u, 1400, 150), false, lightBits), "an open IsMenuOpen never shows is dropped after the hold (not covered forever)");
		}
		Model r;
		FakeUi u2;
		u2.truth = 1;
		const auto got = r.Check(u2, 2000, 150, true, 12);
		Expect((got >> 12 & 1u) && r.dirty && r.at == 0, "an open event during the seed scan: answer covered, scan not stored, rescanned next check");
	}


	// ---- 4. every interleaving of one event's steps with the reader's shared accesses (review MF-1 / MF-2) ----
	{
		struct Scn { const char* name; int idx; bool opening; int mode; };
		// mode, open: 0 IsMenuOpen turns true with the event's first step, 1 only after the reader returns,
		//             2 never (held pending); close: 0 the map drops it with the first step, 1 after the reader
		const Scn scns[] = {
			{ "blocker open, map at once", 9, true, 0 }, { "blocker open, map late", 9, true, 1 }, { "blocker open, map never", 9, true, 2 },
			{ "blocker close, map at once", 9, false, 0 }, { "blocker close, map late", 9, false, 1 },
			{ "HUD open, map at once", 0, true, 0 }, { "HUD open, map late", 0, true, 1 }, { "HUD open, map never yet", 0, true, 2 },
			{ "HUD close, map at once", 0, false, 0 }, { "HUD close, map late", 0, false, 1 },
		};
		int runs = 0, retBad = 0, keptBad = 0, nextBad = 0, laterBad = 0, maxOps = 0;
		std::string firstBad;
		for (const auto& sc : scns) {
			for (int pre = 0; pre < 2; ++pre)        // 1: another menu's open event (never shown) expires in this scan
			for (int due = 0; due < 2; ++due) {   // the reader's scan is due by age, or by a dirty flag from earlier
				const std::uint64_t bit = std::uint64_t{ 1 } << sc.idx;
				auto start = [&](FakeUi& u, Model& m) {
					u.truth = (sc.idx == 0) ? (sc.opening ? 0 : 1) : (1 | (sc.opening ? 0 : bit));
					if (pre) { m.clock = 700; m.Event(12, true); }   // held pending from 700 ms, dropped by a scan at >= 1000
					m.Check(u, 1000, 150);
					m.Check(u, 1001, 150);   // a HUD watch from the seed state settles here
					if (pre) { m.clock = 840; m.Event(12, true); }   // held again: dropped by the reader's scan at 1150 (310 ms), kept at 1010
					m.clock = due ? 1010 : 1150;
					if (due) m.dirty = true;
				};
				const std::uint64_t now = due ? 1010 : 1150;
				int R = 0;
				{
					FakeUi u; Model m; start(u, m);
					m.ops = 0; m.Check(u, now, 150); R = m.ops;
				}
				if (R > maxOps) maxOps = R;
				int pl[hzmenu::kEventSteps];
				for (pl[0] = 1; pl[0] <= R + 1; ++pl[0])
				for (pl[1] = pl[0]; pl[1] <= R + 1; ++pl[1])
				for (pl[2] = pl[1]; pl[2] <= R + 1; ++pl[2])
				for (pl[3] = pl[2]; pl[3] <= R + 1; ++pl[3])
				for (pl[4] = pl[3]; pl[4] <= R + 1; ++pl[4]) {
					FakeUi u; Model m; start(u, m);
					std::uint64_t truthAtScan = u.truth;
					int done = 0;
					auto runStep = [&]() {
						if (done == 0 && sc.mode == 0) { if (sc.opening) u.truth |= bit; else u.truth &= ~bit; }
						m.Step(done, sc.idx, sc.opening);
						++done;
					};
					m.ops = 0;
					m.hook = [&]() {
						while (done < hzmenu::kEventSteps && pl[done] == m.ops) runStep();
					};
					m.clock = now;
					m.ui = &u;
					// the scan's moment: record the map the old full scan would have read
					const auto r = hzmenu::Check(m, now, 150);
					truthAtScan = u.truth;   // conservative: also compare with the map at return (see below)
					m.hook = nullptr;
					while (done < hzmenu::kEventSteps) runStep();
					if (sc.mode == 1) { if (sc.opening) u.truth |= bit; else u.truth &= ~bit; }
					++runs;
					// (a) the reader's own answer is never "clear" when the scan it made was covered: its blocker
					// bits include the scan's, its bit 0 is at most the scan's (checked by rescanning the map now
					// only when no step changed the map during the reader)
					if (sc.mode != 0 && hzmenu::Clear(r.bits, false, 0) && !hzmenu::Clear(truthAtScan, false, 0)) { ++retBad; if (firstBad.empty()) firstBad = std::string(sc.name) + " (answer)"; }
					// (a2) the kept set itself, before any further check (what a busy-path check would read):
					// a finished blocker open is in it; a finished HUD open never set bit 0; after a HUD close
					// with the map already dropped, bit 0 is clear
					bool keptOk = true;
					if (sc.idx != 0 && sc.opening) keptOk = (m.bits & bit) != 0;
					if (sc.idx == 0 && sc.opening) keptOk = !(m.bits & 1u) || (truthAtScan & 1u);
					if (sc.idx == 0 && !sc.opening && sc.mode == 0) keptOk = !(m.bits & 1u);
					if (!keptOk) { ++keptBad; if (firstBad.empty()) firstBad = std::string(sc.name) + " (kept set) at " + std::to_string(pl[0]) + "," + std::to_string(pl[1]) + "," + std::to_string(pl[2]) + "," + std::to_string(pl[3]) + "," + std::to_string(pl[4]) + " pre " + std::to_string(pre) + " due " + std::to_string(due); }
					// (b) the very next check, 1 ms later, agrees with the event
					const auto n1 = m.Check(u, now + 1, 150);
					bool ok = true;
					if (sc.idx != 0 && sc.opening) ok = (n1 & bit) != 0;                     // MF-2: the open is never lost
					if (sc.idx == 0 && !sc.opening) ok = (n1 & 1u) == 0;                      // MF-1: closed at once
					if (sc.idx == 0 && sc.opening) ok = ((n1 & 1u) != 0) == ((u.truth & 1u) != 0);   // MF-1: open only once the map shows it
					if (hzmenu::Clear(n1, false, 0) && !hzmenu::Clear(u.truth, false, 0)) ok = false;
					if (!ok) { ++nextBad; if (firstBad.empty()) firstBad = std::string(sc.name) + " (next check) at " + std::to_string(pl[0]) + "," + std::to_string(pl[1]) + "," + std::to_string(pl[2]) + "," + std::to_string(pl[3]) + "," + std::to_string(pl[4]); }
					// (c) later: the map is the authority again (a blocker close within one cadence, a HUD open
					// that the map finally shows on the next check)
					if (sc.idx == 0 && sc.opening && sc.mode == 2) u.truth |= 1u;
					const auto n2 = m.Check(u, now + 2, 150);
					const auto n3 = m.Check(u, now + 160, 150);
					const std::uint64_t preBit = pre ? (std::uint64_t{ 1 } << 12) : 0;   // may still be held (pendAt is the last open's time)
					bool ok2 = ((n3 & ~preBit) == (u.truth & ~preBit));
					if (sc.idx == 0 && sc.opening && sc.mode == 2) ok2 = ok2 && (n2 & 1u);
					if (sc.idx != 0 && sc.opening && sc.mode == 2) ok2 = (n3 & bit) == 0 || now + 160 - m.pendAt < hzmenu::kPendHoldMs;
					if (!ok2) { ++laterBad; if (firstBad.empty()) firstBad = std::string(sc.name) + " (later)"; }
				}
			}
		}
		Expect(runs > 10000, "interleavings: every placement of the 5 event steps among the reader's " + std::to_string(maxOps) + " shared accesses, 10 events x 2 due reasons x 2 pending states (" + std::to_string(runs) + " runs)");
		Expect(retBad == 0, "interleavings: the reader's answer is never clear while the map it scanned was covered (" + std::to_string(retBad) + " bad)" + (firstBad.empty() ? "" : "; first: " + firstBad));
		Expect(keptBad == 0, "interleavings: the kept set after the event and the reader: a blocker open is in it (MF-2), a HUD open did not set bit 0, a HUD close cleared it (" + std::to_string(keptBad) + " bad)" + (firstBad.empty() ? "" : "; first: " + firstBad));
		Expect(nextBad == 0, "interleavings: the next check keeps every open event, shows a HUD close at once and a HUD open only once the map does (" + std::to_string(nextBad) + " bad)" + (firstBad.empty() ? "" : "; first: " + firstBad));
		Expect(laterBad == 0, "interleavings: afterwards the set matches the map again (" + std::to_string(laterBad) + " bad)" + (firstBad.empty() ? "" : "; first: " + firstBad));
	}

	// ---- 5. the reviewer's three cases, on the real reader and sink ----
	{
		// A: an open event lands after the "no event during the scan" check and before the store
		{
			FakeUi u; u.truth = 1; Model m; m.Check(u, 1000, 150);
			// accesses: At, HudWant, Dirty, BusyTake, SetDirty, Gen, Done, HudGen, Scan, Gen (the scan check),
			// then Pend: inject the whole event right before that Pend read, i.e. after the check, before the store
			m.clock = 1200;
			m.ops = 0;
			bool injected = false;
			m.hook = [&]() {
				if (!injected && m.ops == 11) { injected = true; m.Event(9, true); }
			};
			hzmenu::Check(m, 1200, 150);
			m.hook = nullptr;
			const auto n = m.Check(u, 1300, 150);
			Expect(injected && (n >> 9 & 1u) && !hzmenu::Clear(n, true, 0), "review case A: an open event between the scan check and the store stays covered 100 ms later");
		}
		// B: HUDMenu close while IsMenuOpen("HUDMenu") is still true
		{
			FakeUi u; u.truth = 1; Model m; m.Check(u, 1000, 150);
			m.clock = 1050; m.Event(0, false);
			Expect(!hzmenu::Clear(m.bits, false, 0), "review case B: a HUD close clears bit 0 at once");
			const auto a = m.Check(u, 1050, 150);   // the map still shows the HUD: same answer as the old full scan
			u.truth = 0;
			const auto b = m.Check(u, 1060, 150);   // the map dropped it: the watch rescans at once
			Expect((a & 1u) && !(b & 1u) && !hzmenu::Clear(b, false, 0) && m.hudWant == hzmenu::kHudWatchNone,
				"review case B: while the map shows the HUD the answer equals the old scan; once it drops, the next check is closed (not 140 ms later)");
		}
		// C: HUDMenu open event before IsMenuOpen("HUDMenu") is true
		{
			FakeUi u; u.truth = 0; Model m; m.Check(u, 1000, 150);
			m.clock = 1100; m.Event(0, true);
			const auto a = m.Check(u, 1100, 150);
			const auto b = m.Check(u, 1260, 150);
			Expect(!(a & 1u) && !(b & 1u) && m.pend == 0 && !(m.bits & 1u), "review case C: a HUD open is never held pending; bit 0 stays clear until the map shows the HUD");
			u.truth = 1;
			const auto c = m.Check(u, 1261, 150);
			Expect((c & 1u) && m.hudWant == hzmenu::kHudWatchNone, "review case C: the map shows the HUD -> bit 0 on the next check, watch settled");
		}
		// a check while another thread stores a scan reads the kept set: a HUD open must not show there yet, a HUD
		// close must show at once, a blocker open must show at once
		{
			FakeUi u; u.truth = 0; Model m; m.Check(u, 1000, 150);
			m.clock = 1010; m.Event(0, true);
			m.busy = true;
			const auto a = m.Check(u, 1011, 150);
			m.busy = false;
			u.truth = 1; m.Check(u, 1012, 150);
			m.clock = 1020; m.Event(0, false);
			m.busy = true;
			const auto b = m.Check(u, 1021, 150);
			m.Event(9, true);
			const auto c = m.Check(u, 1022, 150);
			m.busy = false;
			Expect(!(a & 1u) && !(b & 1u) && (c >> 9 & 1u), "busy path: a HUD open does not show before the map, a HUD close shows at once, a blocker open shows at once");
		}
		Expect(hzmenu::Combine(1 | 4, 2) == (4 | 2) && hzmenu::Combine(1, 1) == 1 && hzmenu::Combine(0, 1 | 8) == 8, "Combine: blockers OR, HUD AND");
	}

	std::cout << (g_fail ? "FAILED " : "ok ") << "menu_bits_test (" << g_ok << " ok, " << g_fail << " failed)\n";
	return g_fail ? 1 : 0;
}
