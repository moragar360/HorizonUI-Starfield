// Unit tests for 0.43.3.1 [Scanner] ScanHighlightArea (src/hz_scan_hl.h) plus source pins for its main.cpp glue,
// the HUD F11 row and the default ini. No game, no CommonLibSF. Build:
//   zig c++ -std=c++20 -Wall -Wextra -I src tests/scan_hl_test.cpp -o /tmp/scan_hl_test   (run from the repo root)
// Proves:
//  1. Parse: "0" / "1" / "2" / "3" (spaces trimmed) map to the four positions; anything else is Vanilla;
//  2. Next: Vanilla at start writes nothing; a change to Horizon dot / Full screen / Max writes the documented values;
//     back to Vanilla writes the captured game values (never 0.92 / 0.8 / 0.25 by itself); no change = nothing;
//     Full screen covers the corners of 16:9, 21:9 and 32:9 screens at common FOVs (cone geometry, 0.43.3.2);
//  3. a model of ScanHlApply over random position changes: the game values only ever hold the captured originals,
//     the dot set, the full set or the max set (Horizon dot with the game's own fade), the originals are read once before the first write, and a Vanilla start or a
//     Vanilla-only run never touches the game;
//  4. source pins: the apply runs only from BannerPoll (UI thread), behind the id check and SEH; LoadIni stores the
//     key; the F11 row shows labels; HZ40_SCAN_KEYS, the writer comment and default.ini agree.
// Author: Moragar. Last modified: 2026-11-18.

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
	// 1. Parse
	Expect(Parse("0") == kDot && Parse("1") == kVanilla && Parse("2") == kFull && Parse(" 2 ") == kFull && Parse("0\r") == kDot && Parse("3") == kMax && Parse(" 3\r") == kMax, "Parse: 0 / 1 / 2 / 3 with spaces trimmed");
	Expect(Parse("") == kVanilla && Parse("4") == kVanilla && Parse("-1") == kVanilla && Parse("12") == kVanilla && Parse("x") == kVanilla, "Parse: anything else is Vanilla");
	Expect(std::string(Name(kDot)) == "Horizon dot" && std::string(Name(kVanilla)) == "Vanilla" && std::string(Name(kFull)) == "Full screen" && std::string(Name(kMax)) == "Max", "Name: the four labels");

	// 2. Next
	Orig none;
	Expect(Next(kVanilla, kVanilla, none).act == Act::None, "Vanilla at start: nothing written");
	auto p = Next(kFull, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == 0.45f && p.decal == 4.0f && p.wFall && p.fall == 1.0f, "Full screen writes 0.45 / 4.0 / fade 1.0");
	p = Next(kMax, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == 0.2f && p.decal == 10.0f && p.wFall && p.fall == 10.0f, "Max writes the published whole-screen values 0.2 / 10 / fade 10");
	{
		// the screen corner angle at horizontal FOV h and aspect a: atan(tan(h/2) * sqrt(1 + 1/a^2)); the cone is acos(dot)
		auto corner = [](double h, double a) { return std::cos(std::atan(std::tan(h * 3.14159265358979 / 360.0) * std::sqrt(1.0 + 1.0 / (a * a)))); };
		Expect(kFullAngleDot < corner(90, 16.0 / 9.0) && kFullAngleDot < corner(110, 21.0 / 9.0) && kFullAngleDot < corner(120, 32.0 / 9.0), "Full screen cone reaches the corners of 16:9 at 90, 21:9 at 110 and 32:9 at 120 FOV");
		Expect(kFullAngleDot < 0.59f && kMaxAngleDot < kFullAngleDot && kFullDecal > 2.6f && kMaxDecal >= kFullDecal && kMaxFall >= kFullFall, "Full screen is wider than the old 0.59 / 2.6; Max is wider still");
		Expect(std::fabs(std::acos(0.45) * 180.0 / 3.14159265358979 - 63.3) < 0.1 && std::fabs(std::acos(0.2) * 180.0 / 3.14159265358979 - 78.5) < 0.1, "a dot product: 0.45 is about 63 degrees and 0.2 about 78 degrees from the center");
	}
	p = Next(kDot, kVanilla, none);
	Expect(p.act == Act::Write && !p.wFall, "Horizon dot before any capture leaves the fade alone");
	p = Next(kDot, kVanilla, none);
	Expect(p.act == Act::Write && p.dot == 0.98f && p.decal == 0.4f, "Horizon dot writes 0.98 / 0.4");
	Expect(std::fabs(std::acos(0.98) * 2.0 - std::acos(0.92)) < 0.02, "Horizon dot cone is half the vanilla 0.92 cone angle (about 11.5 vs 23 degrees)");
	Expect(Next(kDot, kFull, none).act == Act::Write && Next(kFull, kDot, none).dot == kFullAngleDot, "dot <-> full writes the other pair");
	Orig o; o.have = true; o.dotOk = true; o.decalOk = true; o.fallOk = true; o.dot = 0.85f; o.decal = 1.3f; o.fall = 0.3f;
	p = Next(kVanilla, kFull, o);
	Expect(p.act == Act::Restore && p.dot == 0.85f && p.decal == 1.3f && p.wFall && p.fall == 0.3f, "back to Vanilla restores the captured game values, the fade too (a user INI tweak survives)");
	p = Next(kDot, kMax, o);
	Expect(p.act == Act::Write && p.dot == kDotAngleDot && p.wFall && p.fall == 0.3f, "Horizon dot after Max gives the captured fade back");
	Orig nf = o; nf.fallOk = false;
	Expect(!Next(kVanilla, kMax, nf).wFall && !Next(kDot, kMax, nf).wFall, "a fade that was not found is never written back");
	Expect(Next(kVanilla, kFull, none).act == Act::None, "Vanilla with nothing captured writes nothing");
	Expect(Next(kFull, kFull, o).act == Act::None && Next(kDot, kDot, o).act == Act::None && Next(kMax, kMax, o).act == Act::None, "no change = nothing");
	Expect(Next(7, kFull, o).act == Act::Restore && Next(-3, kVanilla, o).act == Act::None, "an out-of-range want counts as Vanilla");

	// 3. model of ScanHlApply (capture before the first write, one attempt per change)
	{
		std::mt19937 rng(4331);
		int bad = 0, reads = 0, writesFromVanillaOnly = 0;
		for (int run = 0; run < 2000; ++run) {
			const float gameDot = 0.80f + 0.01f * static_cast<float>(rng() % 15);
			const float gameDecal = 0.5f + 0.1f * static_cast<float>(rng() % 20);
			const float gameFall = 0.1f + 0.05f * static_cast<float>(rng() % 10);
			float curDot = gameDot, curDecal = gameDecal, curFall = gameFall;
			int applied = kVanilla;
			Orig og;
			bool vanillaOnly = (run % 5) == 0;
			int writes = 0;
			for (int step = 0; step < 30; ++step) {
				const int want = vanillaOnly ? kVanilla : static_cast<int>(rng() % 4);
				if (want == applied) continue;
				const auto pl = Next(want, applied, og);
				applied = want;
				if (pl.act == Act::None) continue;
				if (!og.have) { og.have = og.dotOk = og.decalOk = og.fallOk = true; og.dot = curDot; og.decal = curDecal; og.fall = curFall; ++reads; }
				curDot = pl.dot; curDecal = pl.decal; if (pl.wFall) curFall = pl.fall; ++writes;
				const bool okSet = (curDot == gameDot && curDecal == gameDecal && curFall == gameFall) || (curDot == kDotAngleDot && curDecal == kDotDecal && curFall == gameFall) || (curDot == kFullAngleDot && curDecal == kFullDecal && curFall == kFullFall) || (curDot == kMaxAngleDot && curDecal == kMaxDecal && curFall == kMaxFall);
				if (!okSet) ++bad;
				if (applied == kVanilla && (curDot != gameDot || curDecal != gameDecal || curFall != gameFall)) ++bad;
			}
			if (og.have && (og.dot != gameDot || og.decal != gameDecal || og.fall != gameFall)) ++bad;
			if (vanillaOnly && writes) ++writesFromVanillaOnly;
		}
		Expect(bad == 0, "model: the game only ever holds its own set, the dot set (own fade), the full set or the max set; Vanilla always gives the own set back");
		Expect(writesFromVanillaOnly == 0, "model: a Vanilla-only player never gets a write");
		Expect(reads > 0 && reads <= 1600, "model: the game values are read at most once per session (" + std::to_string(reads) + " reads over 1600 changing sessions)");
	}

	// 4. source pins
	const auto cpp = ReadAll("src/main.cpp");
	const auto as = ReadAll("actionscript/horizon_block.as");
	const auto ini = ReadAll("Interface/HorizonUI/HorizonUI.default.ini");
	const auto apply = FnBody(cpp, "void ScanHlApply()\n");
	Expect(!cpp.empty() && Count(cpp, "ScanHlApply();") == 2 && Has(FnBody(cpp, "void BannerPoll(ULONGLONG a_now)"), "ScanHlApply();"), "ScanHlApply is called once, from BannerPoll (the HUD messages advance, UI thread); plus its forward declaration");
	Expect(Has(apply, "if (want == g_scanHlApplied) return;") && apply.find("if (want == g_scanHlApplied) return;") < apply.find("HzAddrSlot"), "steady state returns before any game call (one atomic load and a compare)");
	Expect(Has(apply, "HzAddrSlot(id)") && Has(apply, "AddrSlotMiss(slot)") && Has(apply, "HzScanHlSEH(&io)") && apply.find("HzAddrSlot(id)") < apply.find("HzScanHlSEH(&io)"), "the INISettingCollection id is checked in versionlib before the singleton is touched; the call runs under SEH");
	Expect(Has(FnBody(cpp, "static void HzScanHlCall(HzScanHlRaw* a_io)"), "if (sf && a_io->writeFall) sf->SetFloat(a_io->fall);") && Has(FnBody(cpp, "static void HzScanHlCall(HzScanHlRaw* a_io)"), "if (sf) a_io->fallWas = sf->GetFloat();") && Has(apply, "io.writeFall = plan.wFall ? 1 : 0;") && Has(apply, "g_scanHlOrig.fall = io.fallWas;"), "the fade is captured once with the other two and written only when the plan says so");
	Expect(Has(FnBody(cpp, "static void HzScanHlCall(HzScanHlRaw* a_io)"), "if (!col) return;") && Has(FnBody(cpp, "static RE::Setting* HzScanHlFind(RE::INISettingCollection* a_col, const char* a_key)"), "if (!s || !s->Is<float>()) return nullptr;"), "null checks on the collection and both settings (float only)");
	Expect(Count(apply, "g_scanHlMissLogged = true") >= 2 && !Has(cpp, "remove(") && !Has(apply, "std::filesystem"), "a missing id / setting is logged once; no file work");
	Expect(Has(FnBody(cpp, "void LoadIni(bool a_reloadMsglog = true)"), "if (get(\"scanhighlightarea\", v)) scanHl = hzscanhl::Parse(v);") && Has(FnBody(cpp, "void LoadIni(bool a_reloadMsglog = true)"), "g_scanHlWant.store(scanHl"), "LoadIni (load and every save / apply) stores the wanted position");
	Expect(Has(as, "[\"ScanNearestUnscanned\",\"b\",1,0,1],[\"ScanHighlightArea\",\"i\",1,0,3],[\"ScanOutlineThickness\",\"i\",0,0,2],[\"HideMainHudWhileScanning\""), "HZ40_SCAN_KEYS: ScanHighlightArea, int 0 - 3, default 1, saved / loaded / reset by the generic [Scanner] list");
	Expect(Has(as, "{\"k\":\"ScanHighlightArea\",\"l\":\"HIGHLIGHT AREA\",\"t\":\"r\",\"opts\":[\"HORIZON DOT\",\"VANILLA\",\"FULL SCREEN\",\"MAX\"],\"ids\":[0,1,2,3]"), "F11 SCANNER row shows labels, not numbers");
	// 0.43.3.2: the row note says what the setting changes (the pick-up area and the outlines), not only "cone"
	Expect(Has(as, "\"ids\":[0,1,2,3],\"note\":\"How much of the screen the scanner picks up and outlines (minerals, flora, fauna, items). HORIZON DOT: smaller. VANILLA: the game's own. FULL SCREEN: the whole screen, wide screens and a high FOV too. MAX: the widest, past every screen edge. Applies the next time you open the scanner\"}"), "F11 HIGHLIGHT AREA note: what it changes, the four positions, when it applies");
	const auto iniKey = ini.find("\r\nScanHighlightArea=1\r\n");
	Expect(iniKey != std::string::npos && ini.find("ScanNearestUnscanned=1\r\n") < iniKey && iniKey < ini.find("HideMainHudWhileScanning=1"), "default.ini: ScanHighlightArea=1 under [Scanner], in the HZ40_SCAN_KEYS order");
	const std::string c1 = "Highlight area of the hand scanner (the game's own pick-up cone and outline radius, set by the DLL): 0 = Horizon dot (smaller than the game),";
	const std::string c2 = "1 = Vanilla (default: the game's own values, nothing is changed), 2 = Full screen (wide screens too), 3 = Max. Applies the next time you open the scanner";
	Expect(Has(ini, "; " + c1 + "\r\n; " + c2 + "\r\nScanHighlightArea=1") && Has(as, "\"ScanHighlightArea\":[\"" + c1 + "\",\"" + c2 + "\"]"), "the default.ini comment equals the HUD writer's comment");

	std::cout << (g_fail ? "FAILED " : "PASSED ") << g_ok << " ok, " << g_fail << " FAIL\n";
	return g_fail ? 1 : 0;
}
