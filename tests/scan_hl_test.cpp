// Unit tests for 0.43.3.1 [Scanner] ScanHighlightArea (src/hz_scan_hl.h; 0.43.5: five visible levels SMALL / VANILLA /
// LARGE / WIDE / FULL SCREEN, the retired MAX read as FULL SCREEN, the recheck and the load line) plus source pins for its main.cpp glue,
// the HUD F11 row and the default ini. No game, no CommonLibSF. Build:
//   zig c++ -std=c++20 -Wall -Wextra -I src tests/scan_hl_test.cpp -o test_scratch/scan_hl_test   (run from the repo root)
// Proves:
//  1. Parse: "0" / "1" / "2" / "3" (spaces trimmed) map to the four positions; anything else is Vanilla;
//  2. Next: Vanilla writes the game default cone 0.92 / 0.8 / 0.25 once (from kUnset or from another level);
//     already-applied Vanilla writes nothing; a change to Small / Large / Wide / Full / old Max writes the documented
//     values; no change = nothing; Full screen covers the corners of 16:9, 21:9 and 32:9 screens at common FOVs;
//  3. a model of ScanHlApply over random position changes: Horizon only writes the five documented sets (including
//     Vanilla = game defaults), never 0.2 / 10 / 10; a Vanilla-only run writes once then stops; Vanilla never leaves
//     wrote.on so the scanner-open recheck does not rewrite;
//  4. source pins: the apply runs only from BannerPoll (UI thread), behind the id check and SEH; LoadIni stores the
//     key; the F11 row shows labels in size order with ids 0 / 1 / 4 / 5 / 2; HZ40_SCAN_KEYS, the writer comment and
//     default.ini agree. Old saved ids keep their meaning (3 reads as 2).
// Author: Moragar. Last modified: 2026-11-27.

#include "hz_scan_hl.h"

#include <cmath>
#include <fstream>
#include <iostream>
#include <random>
#include <sstream>
#include <string>

namespace {

int g_fail = 0, g_ok = 0;
void Expect(bool a_cond, const std::string& a_msg)
{
	if (a_cond) { ++g_ok; std::cout << "ok  " << a_msg << "\n"; }
	else { ++g_fail; std::cerr << "FAIL " << a_msg << "\n"; }
}
std::string ReadAll(const char* a_p)
{
	std::ifstream in(a_p, std::ios::binary);
	std::stringstream ss;
	ss << in.rdbuf();
	return ss.str();
}
bool Has(const std::string& a_s, const std::string& a_n) { return a_s.find(a_n) != std::string::npos; }
std::size_t Count(const std::string& a_s, const std::string& a_n)
{
	std::size_t n = 0;
	for (auto p = a_s.find(a_n); p != std::string::npos; p = a_s.find(a_n, p + 1)) ++n;
	return n;
}
std::string FnBody(const std::string& a_s, const std::string& a_sig)
{
	const auto i = a_s.find(a_sig);
	if (i == std::string::npos) return {};
	const auto b = a_s.find('{', i);
	int d = 0;
	for (auto p = b; p < a_s.size(); ++p) {
		if (a_s[p] == '{') ++d;
		else if (a_s[p] == '}' && --d == 0) return a_s.substr(b, p - b + 1);
	}
	return {};
}

}

int main()
{
	using namespace hzscanhl;
	const double kPi = 3.14159265358979;
	auto deg = [&](double c) { return std::acos(c) * 180.0 / kPi; };
	// 1. Parse / Name
	Expect(Parse("0") == kDot && Parse("1") == kVanilla && Parse("2") == kFull && Parse(" 2 ") == kFull && Parse("0\r") == kDot && Parse("4") == kLarge && Parse(" 5\r") == kWide, "Parse: 0 / 1 / 2 / 4 / 5 with spaces trimmed");
	Expect(Parse("3") == kFull && Parse(" 3\r") == kFull, "Parse: 3 (the retired MAX) reads as Full screen, so a saved MAX keeps a full-screen scanner");
	Expect(Parse("") == kVanilla && Parse("6") == kVanilla && Parse("-1") == kVanilla && Parse("12") == kVanilla && Parse("x") == kVanilla, "Parse: anything else is Vanilla");
	Expect(std::string(Name(kDot)) == "Small" && std::string(Name(kVanilla)) == "Vanilla" && std::string(Name(kLarge)) == "Large" && std::string(Name(kWide)) == "Wide" && std::string(Name(kFull)) == "Full screen", "Name: the five labels");

	// 2. Next and the level values
	Orig none;
	Expect(Next(kVanilla, kVanilla, none).act == Act::None, "Vanilla already applied: nothing written");
	Plan p = Next(kVanilla, kUnset, none);
	Expect(p.act == Act::Write && p.dot == kGameDot && p.decal == kGameDecal && p.wFall && p.fall == kGameFall, "first Vanilla (applied unset) writes the game default 0.92 / 0.8 / fade 0.25");
	p = Next(kFull, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == 0.45f && p.decal == 4.0f && p.wFall && p.fall == 1.0f, "Full screen writes 0.45 / 4.0 / fade 1.0");
	p = Next(kMax, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == kFullAngleDot && p.decal == kFullDecal && p.fall == kFullFall, "a want of 3 (old MAX) writes the Full screen set, never 0.2 / 10 / 10");
	Expect(Next(kFull, kMax, none).act == Act::None && Next(kMax, kFull, none).act == Act::None, "3 and 2 are the same position (no write between them)");
	p = Next(kLarge, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == 0.82f && p.decal == 1.4f && !p.wFall, "Large writes 0.82 / 1.4 and leaves the fade to the game");
	p = Next(kWide, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == 0.735f && p.decal == 1.8f && !p.wFall, "Wide writes 0.735 / 1.8 and leaves the fade to the game");
	p = Next(kDot, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == 0.98f && p.decal == 0.4f && !p.wFall, "Small writes 0.98 / 0.4 and leaves the fade to the game");
	{
		// every step visibly bigger: the half angle grows by at least 5 degrees per step, in F11 order
		const float order[] = { kDotAngleDot, kGameDot, kLargeAngleDot, kWideAngleDot, kFullAngleDot };
		bool grow = true;
		for (int i = 1; i < 5; ++i) grow = grow && deg(order[i]) - deg(order[i - 1]) >= 5.0;
		Expect(grow, "each level is at least 5 degrees wider than the one before (11.5 / 23 / 35 / 42 / 63)");
		const float rad[] = { kDotDecal, kGameDecal, kLargeDecal, kWideDecal, kFullDecal };
		bool rgrow = true;
		for (int i = 1; i < 5; ++i) rgrow = rgrow && rad[i] > rad[i - 1] * 1.2f;
		Expect(rgrow, "the outline radius grows at every step too (0.4 / 0.8 / 1.4 / 1.8 / 4.0)");
		// on-screen reach at 16:9, horizontal FOV 85: half width tan(42.5), half height tan(27.3)
		const double hw = std::tan(42.5 * kPi / 180.0), hh = hw * 9.0 / 16.0;
		auto reach = [&](float c) { return std::tan(std::acos(static_cast<double>(c))); };
		Expect(reach(kLargeAngleDot) > hh && reach(kLargeAngleDot) < hw, "Large reaches the top and bottom of a 16:9 FOV 85 screen, not the sides");
		Expect(reach(kWideAngleDot) >= hw && reach(kWideAngleDot) < hw * std::sqrt(1.0 + 81.0 / 256.0), "Wide reaches the left and right edges; the corners stay out");
		// the radius rule: about the circle's reach in half screen heights
		Expect(std::fabs(reach(kLargeAngleDot) / hh - kLargeDecal) < 0.1 && std::fabs(reach(kWideAngleDot) / hh - kWideDecal) < 0.1 && std::fabs(reach(kGameDot) / hh - kGameDecal) < 0.1, "Large / Wide radius follow the published radius rule (reach in half heights), like the game's 0.92 / 0.8");
		// Full screen corner coverage (unchanged)
		auto corner = [&](double h, double a) { return std::cos(std::atan(std::tan(h * kPi / 360.0) * std::sqrt(1.0 + 1.0 / (a * a)))); };
		Expect(kFullAngleDot < corner(110, 16.0 / 9.0) && kFullAngleDot < corner(100, 21.0 / 9.0) && kFullAngleDot < corner(85, 32.0 / 9.0), "Full screen cone reaches the corners of 16:9 at 110, 21:9 at 100 and 32:9 at 85 FOV");
	}
	Expect(std::fabs(std::acos(0.98) * 2.0 - std::acos(0.92)) < 0.02, "Small cone is half the vanilla 0.92 cone angle (about 11.5 vs 23 degrees)");
	Expect(Next(kDot, kFull, none).act == Act::Write && Next(kFull, kDot, none).dot == kFullAngleDot && Next(kLarge, kWide, none).dot == kLargeAngleDot, "a change between two levels writes the new set");
	Orig o; o.have = true; o.dotOk = true; o.decalOk = true; o.fallOk = true; o.dot = 0.85f; o.decal = 1.3f; o.fall = 0.3f;
	p = Next(kVanilla, kFull, o);
	Expect(p.act == Act::Write && p.dot == kGameDot && p.decal == kGameDecal && p.wFall && p.fall == kGameFall, "back to Vanilla writes the game default cone, not a captured / widened INI");
	p = Next(kWide, kFull, o);
	Expect(p.act == Act::Write && p.dot == kWideAngleDot && p.wFall && p.fall == 0.3f, "Wide after Full screen gives the captured fade back");
	Orig nf = o; nf.fallOk = false;
	Expect(Next(kVanilla, kFull, nf).wFall && Next(kVanilla, kFull, nf).fall == kGameFall && !Next(kLarge, kFull, nf).wFall, "Vanilla always writes the game fade; Large does not write a fade that was not found");
	Expect(Next(kVanilla, kFull, none).act == Act::Write && Next(kVanilla, kFull, none).dot == kGameDot, "Vanilla with nothing captured still writes the game default cone");
	Expect(Next(kFull, kFull, o).act == Act::None && Next(kDot, kDot, o).act == Act::None && Next(kLarge, kLarge, o).act == Act::None && Next(kWide, kWide, o).act == Act::None, "no change = nothing");
	Expect(Next(7, kFull, o).act == Act::Write && Next(7, kFull, o).dot == kGameDot && Next(-3, kVanilla, o).act == Act::None, "an out-of-range want counts as Vanilla (writes the game default cone unless Vanilla is already applied)");
	// Drifted / WidenedByOther
	Expect(!Drifted(0.82f, 0.82f) && !Drifted(0.8201f, 0.82f) && Drifted(0.2f, 0.82f) && Drifted(0.83f, 0.82f), "Drifted: only a real change counts (float noise does not)");
	Expect(!WidenedByOther(true, 0.92f, true, 0.8f) && WidenedByOther(true, 0.2f, true, 10.0f) && WidenedByOther(true, 0.59f, true, 0.8f) && WidenedByOther(true, 0.92f, true, 2.6f) && !WidenedByOther(true, 0.98f, true, 0.4f) && !WidenedByOther(false, 0.0f, false, 0.0f), "WidenedByOther: flags a wider game value (Fullscran 0.2 / 10, the 0.59 guide), not the defaults or a smaller cone");

	// 0.43.5 re-review (S-2): Guard / Recheck / GiveBack
	{
		Guard g; Wrote w; w.on = true; w.dot = 0.82f; w.decal = 1.4f; w.wFall = false;
		Now n; n.dotFound = n.decalFound = n.fallFound = true; n.dot = 0.82f; n.decal = 1.4f; n.fall = 0.25f;
		Expect(Recheck(g, w, n) == Re::None, "Recheck: nothing drifted = nothing");
		n.dot = 0.2f;
		Expect(Recheck(g, w, n) == Re::Reapply && Recheck(g, w, n) == Re::Reapply && Recheck(g, w, n) == Re::Reapply && Recheck(g, w, n) == Re::Yield && Recheck(g, w, n) == Re::Yield, "Recheck: three reapplies per pick, then Yield (no tug-of-war forever)");
		Wrote off; Expect(Recheck(g, off, n) == Re::None, "Recheck: nothing is checked unless a level is in the game");
		// Settled: a yield at Wide ignores Wide, any other pick clears it first (the M-2 order), and the count restarts
		g.yielded = kWide;
		Expect(Settled(g, kWide, kVanilla) && g.yielded == kWide, "Settled: the yielded position is ignored");
		Expect(Settled(g, kVanilla, kVanilla) && g.yielded == -1 && g.reapplied == 0, "Settled: Vanilla after a yield is 'no change' but clears the yield and the count");
		Expect(!Settled(g, kWide, kVanilla), "Settled: the same level picked again applies again");
		// GiveBack: only what still holds Horizon's value
		Orig og; og.have = og.dotOk = og.decalOk = og.fallOk = true; og.dot = 0.92f; og.decal = 0.8f; og.fall = 0.25f;
		Wrote ww; ww.on = true; ww.dot = 0.45f; ww.decal = 4.0f; ww.wFall = true; ww.fall = 1.0f;
		Now nn; nn.dotFound = nn.decalFound = nn.fallFound = true; nn.dot = 0.3f; nn.decal = 4.0f; nn.fall = 1.0f;
		auto gv = GiveBack(ww, og, nn);
		Expect(!gv.dot && gv.decal && gv.fall, "GiveBack: the drifted dot is left alone, the decal and fade that still hold Horizon's values are given back");
		Orig none2; Expect(!GiveBack(ww, none2, nn).decal, "GiveBack: nothing without a captured base");
		Expect(AnyDrift(ww, nn) && !AnyDrift(ww, Now{ true, true, true, 0.45f, 4.0f, 1.0f }), "AnyDrift: a changed value, not a matching one");
	}

	// S-2 glue: Recheck(State) returns the write plan and does the yield bookkeeping (the same code main.cpp runs)
	{
		State st;
		st.applied = kLarge;
		st.orig.have = st.orig.dotOk = st.orig.decalOk = st.orig.fallOk = true;
		st.orig.dot = 0.92f; st.orig.decal = 0.8f; st.orig.fall = 0.25f;
		st.wrote.on = true; st.wrote.dot = 0.82f; st.wrote.decal = 1.4f; st.wrote.wFall = false;
		float curDot = 0.82f, curDecal = 1.4f, curFall = 0.25f;
		auto applyNow = [&](Now& n) { n.dotFound = n.decalFound = n.fallFound = true; n.dot = curDot; n.decal = curDecal; n.fall = curFall; };
		std::string seq;
		for (int k = 0; k < 6; ++k) {
			curDot = 0.2f;
			Now n; applyNow(n);
			const auto p = Recheck(st, n);
			if (p.re == Re::Reapply) { if (p.writeDot) curDot = p.dot; if (p.writeDecal) curDecal = p.decal; if (p.writeFall) curFall = p.fall; seq += seq.empty() ? "Reapply" : ",Reapply"; }
			else if (p.re == Re::Yield) { if (p.writeDot) curDot = p.dot; if (p.writeDecal) curDecal = p.decal; if (p.writeFall) curFall = p.fall; seq += seq.empty() ? "Yield" : ",Yield"; }
			else seq += seq.empty() ? "off" : ",off";
		}
		Expect(seq == "Reapply,Reapply,Reapply,Yield,off,off" && curDecal == 0.8f && curDot == 0.2f && !st.wrote.on && st.applied == kVanilla && st.guard.yielded == kLarge && !st.orig.have,
			"Recheck(State): a fighting mod gets 3 reapplies, then a yield that gives back only what Horizon still holds (decal 0.8, the mod's 0.2 is kept) and forgets the base");
		Expect(Settled(st, kLarge), "Recheck(State): LARGE again after the yield is ignored");
		Expect(Settled(st, kVanilla) && st.guard.yielded == -1 && st.guard.reapplied == 0, "Recheck(State): Vanilla after the yield clears the yield and the count");
		Expect(!Settled(st, kLarge), "Recheck(State): Vanilla then LARGE applies again");
	}

	// 3. model of ScanHlApply plus ScanHlRecheck, driven by the shared State / Next / Recheck (the same code main.cpp runs)
	{
		std::mt19937 rng(4335);
		int bad = 0, reads = 0, vanillaOnlyBad = 0, reapplies = 0, yields = 0;
		const int pos[] = { kDot, kVanilla, kFull, kMax, kLarge, kWide };
		for (int run = 0; run < 2000; ++run) {
			const float gameDot = 0.80f + 0.01f * static_cast<float>(rng() % 15);
			const float gameDecal = 0.5f + 0.1f * static_cast<float>(rng() % 20);
			const float gameFall = 0.1f + 0.05f * static_cast<float>(rng() % 10);
			float curDot = gameDot, curDecal = gameDecal, curFall = gameFall;
			State st;
			bool vanillaOnly = (run % 5) == 0;
			const bool hold = (run % 5) == 1;   // stay on Large so a fighting mod can reach the 3-then-yield
			int writes = 0;
			for (int step = 0; step < 30; ++step) {
				if (!vanillaOnly && (rng() % 7) == 0) { curDot = 0.2f; curDecal = 10.0f; }
				if (st.wrote.on) {
					Now n; n.dotFound = n.decalFound = n.fallFound = true; n.dot = curDot; n.decal = curDecal; n.fall = curFall;
					const auto rp = Recheck(st, n);
					if (rp.re == Re::Reapply) { if (rp.writeDot) curDot = rp.dot; if (rp.writeDecal) curDecal = rp.decal; if (rp.writeFall) curFall = rp.fall; ++reapplies; }
					else if (rp.re == Re::Yield) { if (rp.writeDot) curDot = rp.dot; if (rp.writeDecal) curDecal = rp.decal; if (rp.writeFall) curFall = rp.fall; ++yields; }
				}
				const int want = vanillaOnly ? kVanilla : (hold ? kLarge : pos[rng() % 6]);
				if (Settled(st, want)) continue;
				const auto pl = Next(want, st.applied, st.orig);
				st.applied = want;
				if (pl.act == Act::None) continue;
				if (!st.orig.have) { st.orig.have = st.orig.dotOk = st.orig.decalOk = st.orig.fallOk = true; st.orig.dot = curDot; st.orig.decal = curDecal; st.orig.fall = curFall; ++reads; }
				curDot = pl.dot; curDecal = pl.decal; if (pl.wFall) curFall = pl.fall; ++writes;
				st.wrote.on = pl.act == Act::Write && want != kVanilla;
				st.wrote.dot = pl.dot; st.wrote.decal = pl.decal; st.wrote.wFall = pl.wFall; st.wrote.fall = pl.fall;
				const bool okSet = (curDot == kGameDot && curDecal == kGameDecal) || (curDot == kDotAngleDot && curDecal == kDotDecal) || (curDot == kLargeAngleDot && curDecal == kLargeDecal) || (curDot == kWideAngleDot && curDecal == kWideDecal) || (curDot == kFullAngleDot && curDecal == kFullDecal && curFall == kFullFall);
				if (!okSet) ++bad;
				if (curDot == 0.2f && pl.act == Act::Write) ++bad;   // Horizon never writes the old Max set
				if (st.applied == kVanilla && st.wrote.on) ++bad;     // Vanilla never leaves a recheck write in the state
			}
			if (vanillaOnly && (writes != 1 || curDot != kGameDot || curDecal != kGameDecal)) ++vanillaOnlyBad;
		}
		Expect(bad == 0, "model: Horizon only ever writes the Small / Large / Wide / Full screen / Vanilla-default sets (never 0.2), and Vanilla never leaves a recheck write in the state");
		Expect(vanillaOnlyBad == 0, "model: a Vanilla-only player gets exactly one write of 0.92 / 0.8");
		Expect(reads > 0 && reads <= 2000, "model: the game values are read at most once per session (" + std::to_string(reads) + " reads)");
		Expect(reapplies > 0 && yields > 0, "model: an outside change is written back at most 3 times per pick, then Horizon yields (" + std::to_string(reapplies) + " reapplies, " + std::to_string(yields) + " yields)");
	}

	// 4. source pins
	const auto cpp = ReadAll("src/main.cpp");
	const auto as = ReadAll("actionscript/horizon_block.as");
	const auto ini = ReadAll("Interface/HorizonUI/HorizonUI.default.ini");
	const auto pa = ReadAll("src/hz_preset_apply.h");
	const auto apply = FnBody(cpp, "void ScanHlApply()\n");
	Expect(!cpp.empty() && Count(cpp, "ScanHlApply();") == 2 && Has(FnBody(cpp, "void BannerPoll(ULONGLONG a_now)"), "ScanHlApply();"), "ScanHlApply is called once, from BannerPoll (the HUD messages advance, UI thread); plus its forward declaration");
	Expect(Has(apply, "if (hzscanhl::Settled(g_scanHl, want)) return;") && apply.find("hzscanhl::Settled(") < apply.find("HzAddrSlot"), "steady state returns before any game call (a bool test, one atomic load and a compare)");
	Expect(Has(apply, "if (!g_scanHlPeeked) ScanHlPeekOnce();") && apply.find("ScanHlPeekOnce();") < apply.find("const int want"), "0.43.5: the read-only load line runs once, before the first apply can write");
	Expect(Has(apply, "HzAddrSlot(id)") && Has(apply, "AddrSlotMiss(slot)") && Has(apply, "HzScanHlSEH(&io)") && apply.find("HzAddrSlot(id)") < apply.find("HzScanHlSEH(&io)"), "the INISettingCollection id is checked in versionlib before the singleton is touched; the call runs under SEH");
	const auto call = FnBody(cpp, "static void HzScanHlCall(HzScanHlRaw* a_io)");
	Expect(Has(call, "if (sf && a_io->writeFall) sf->SetFloat(a_io->fall);") && Has(call, "if (sf) a_io->fallWas = sf->GetFloat();") && Has(apply, "io.writeFall = plan.wFall ? 1 : 0;") && Has(apply, "g_scanHl.orig.fall = io.fallWas;"), "the fade is captured once with the other two and written only when the plan says so");
	Expect(Has(call, "if (!col) return;") && Has(call, "if (!s_sdLooked) { s_sd = HzScanHlFind(col, hzscanhl::kKeyDot); s_sdLooked = true; }") && Has(FnBody(cpp, "static RE::Setting* HzScanHlFind(RE::INISettingCollection* a_col, const char* a_key)"), "if (!s || !s->Is<float>()) return nullptr;"), "null checks on the collection and the settings (float only); 0.43.5: each setting is looked up once per session, including a miss");
	Expect(Count(apply, "g_scanHlMissLogged = true") >= 2 && !Has(cpp, "remove(") && !Has(apply, "std::filesystem"), "a missing id / setting is logged once; no file work");
	const auto load = FnBody(cpp, "void LoadIni(bool a_reloadMsglog = true)");
	Expect(Has(load, "if (get(\"scanhighlightarea\", v)) scanHl = hzscanhl::Parse(v);") && Has(load, "g_scanHlWant.store(scanHl"), "LoadIni (load and every save / apply) stores the wanted position");
	// 0.43.5 peek / recheck
	const auto peek = FnBody(cpp, "static void ScanHlPeekOnce()\n");
	Expect(Has(peek, "if (hzaddr::AddrSlotRetry(slot)) return;") && Has(peek, "g_scanHlPeeked = true;") && Has(peek, "HzScanHlRead(io)") && Has(peek, "WidenedByOther(") && Has(peek, "already widens the scanner") && !Has(peek, "SetFloat"), "load line: read only, after versionlib is read, once, and it flags an outside widening");
	const auto rd = FnBody(cpp, "static bool HzScanHlRead(HzScanHlRaw& a_io)");
	Expect(Has(rd, "a_io.capture = 1;") && !Has(rd, "writeDot = 1") && Has(rd, "AddrSlotMiss(slot)") && Has(rd, "HzScanHlSEH(&a_io)"), "HzScanHlRead reads under the id check and SEH with every write flag 0");
	const auto re = FnBody(cpp, "static void ScanHlRecheck(bool a_openEdge)");
	Expect(Has(re, "if (!g_scanHl.wrote.on) {") && re.find("SetFloat") == std::string::npos && Has(re, "hzscanhl::Recheck(g_scanHl, now)") && Has(re, "if (p.re == hzscanhl::Re::Reapply) {") && Has(re, "w.dot = p.dot;") && Has(re, "if (!g_scanHlReLogged) {"), "recheck: Vanilla never writes; after a Horizon write a drifted value is written back (at most 3 times per pick), logged once per session");
	Expect(!Has(re, "g_scanHl.guard.yielded") && !Has(re, "g_scanHl.applied = hzscanhl::kVanilla") && !Has(re, "g_scanHl.wrote = hzscanhl::Wrote{}") && Has(ReadAll("src/hz_scan_hl.h"), "a_s.guard.yielded = a_s.applied;") && Has(re, "put back only the values it set"), "S-2: after 3 reapplies Horizon yields; the bookkeeping lives in hz_scan_hl.h (gives back only what still holds its value, forgets the base), one log line");
	const auto rc = FnBody(cpp, "void ScanRecheck(RE::UI*, ULONGLONG a_now)\n");
	Expect(!Has(rc, "IsMenuOpen") && Has(rc, "g_scanOpenEdge.exchange(false") && Has(rc, "if (g_scanOpen.load(std::memory_order_acquire)) return;") && Has(rc, "if (a_now < g_scanReNext) return;") && Has(rc, "g_scanReNext = a_now + 2000;") && Has(rc, "if (!g_scanHl.wrote.on && g_scanReach.applied == hzscanreach::kVanilla) return;") && Has(FnBody(cpp, "void BannerPoll(ULONGLONG a_now)"), "ScanRecheck(ui, a_now);"), "S-1 / N-8: no IsMenuOpen polling; the open edge comes from the menu sink; the 2 s read runs only after a Horizon write and is skipped while the scanner is open");
	Expect(Has(FnBody(cpp, "ProcessEvent(const RE::MenuOpenCloseEvent& a_event"), "g_scanOpenEdge.store(true, std::memory_order_release);") && Has(cpp, "std::atomic<bool>          g_scanOpenEdge{false};") && Has(cpp, "std::atomic<bool>          g_scanOpen{false};") && Has(FnBody(cpp, "ProcessEvent(const RE::MenuOpenCloseEvent& a_event"), "g_scanOpen.store(a_event.opening, std::memory_order_release);"), "the MenuOpenCloseEvent sink sets the scanner open edge and the open flag (one string compare per event, one lazy one-time allocation for the name)");
	Expect(Has(apply, "g_scanHl.wrote.on = !restore && !vanilla && io.dotFound != 0;"), "a Vanilla write turns the recheck off (never rewritten on scanner open)");
	Expect(Has(apply, "const bool vanilla = want == hzscanhl::kVanilla;") && Has(peek, "VANILLA writes the game default 0.92 / 0.8"), "Vanilla is a one-shot write of the game default cone, logged on the load line");
	Expect(Has(ReadAll("src/hz_scan_hl.h"), "int   applied = kUnset;") && Has(ReadAll("src/hz_scan_hl.h"), "inline constexpr int kUnset = -1;"), "applied starts unset so the first BannerPoll can write default Vanilla once");
	// presets keep the player's own choice
	Expect(Has(pa, "a_sec == \"scanner\" && (a_kl == \"scanhighlightarea\" || a_kl == \"scanoutlinethickness\" || a_kl == \"scanreach\")"), "0.43.5: ScanHighlightArea / ScanOutlineThickness / ScanReach are personal keys (a preset Apply keeps the player's own)");
	// F11 / ini
	Expect(Has(as, "[\"ScanNearestUnscanned\",\"b\",1,0,1],[\"ScanHighlightArea\",\"i\",1,0,5],[\"ScanOutlineThickness\",\"i\",0,0,2],[\"ScanReach\",\"i\",0,0,3],[\"HideMainHudWhileScanning\""), "HZ40_SCAN_KEYS: ScanHighlightArea int 0 - 5 default 1, then ScanOutlineThickness, then ScanReach");
	Expect(Has(as, "{\"k\":\"ScanHighlightArea\",\"l\":\"HIGHLIGHT AREA\",\"t\":\"r\",\"opts\":[\"SMALL\",\"VANILLA\",\"LARGE\",\"WIDE\",\"FULL SCREEN\"],\"ids\":[0,1,4,5,2]"), "F11 SCANNER row: five labels in size order, ids 0 / 1 / 4 / 5 / 2");
	Expect(Has(as, "\"ids\":[0,1,4,5,2],\"note\":\"How far from the screen center the scanner picks up and outlines things. It doesn't change how far away you can scan (that's SCAN REACH). SMALL: about half the game's circle. VANILLA: the game's default cone (about 23 degrees); Horizon writes that once when you pick it. LARGE: reaches the top and bottom of the screen. WIDE: reaches the left and right edges. FULL SCREEN: the whole screen, corners too. A change writes once; it is not rewritten when you open the scanner\"}"), "F11 HIGHLIGHT AREA note: Vanilla writes the game default cone once, not on scanner open");
	Expect(Has(FnBody(as, "private function hz40Fix(c:Object) : void"), "if(int(c.ScanHighlightArea) == 3) { c.ScanHighlightArea = 2; }"), "the HUD shows and saves a stored 3 (old MAX) as FULL SCREEN (2)");
	const auto iniKey = ini.find("\r\nScanHighlightArea=1\r\n");
	Expect(iniKey != std::string::npos && ini.find("ScanNearestUnscanned=1\r\n") < iniKey && iniKey < ini.find("HideMainHudWhileScanning=1"), "default.ini: ScanHighlightArea=1 under [Scanner], in the HZ40_SCAN_KEYS order");
	const std::string c1 = "Highlight area of the hand scanner (the game's own pick-up cone and outline radius, set by the DLL; not the scan distance): 0 = Small (half the game's circle),";
	const std::string c2 = "1 = Vanilla (default: writes the game 0.92 / 0.8 cone, about 23 degrees, once when picked), 4 = Large, 5 = Wide, 2 = Full screen (3, the old Max, reads as 2). A change writes once; not on scanner open";
	Expect(Has(ini, "; " + c1 + "\r\n; " + c2 + "\r\nScanHighlightArea=1") && Has(as, "\"ScanHighlightArea\":[\"" + c1 + "\",\"" + c2 + "\"]"), "the default.ini comment equals the HUD writer's comment");

	std::cout << (g_fail ? "FAILED " : "PASSED ") << g_ok << " ok, " << g_fail << " FAIL\n";
	return g_fail ? 1 : 0;
}
