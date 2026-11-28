// Unit tests for 0.43.5 [Scanner] ScanReach (src/hz_scan_reach.h) plus source pins for its main.cpp glue, the HUD
// F11 row, the default ini and the preset rule. No game, no CommonLibSF. Build (from the repo root):
//   g++ -std=c++20 -Wall -Wextra -I src tests/scan_reach_test.cpp -o test_scratch/scan_reach_test
// Proves:
//  1. Parse / Name / Mul / Value: 0 - 3, x2 / x3 / x5 of the captured game values, capped at 500 m, a game value of
//     500 m or more (a big range mod) is never shrunk, 0 stays 0;
//  2. Next: Vanilla at start writes nothing; Vanilla after a write restores; no change = nothing;
//  3. a model of ScanReachApply + ScanReachRecheck on a fake game with a range mod that sometimes changes the values
//     after Horizon wrote them: Horizon never writes over a value it did not write last unless it rebased on it
//     (a new pick before the next recheck), Vanilla gives back only values that still hold Horizon's, the skill
//     multiplier is never written, every write is base x factor, and a new factor never compounds;
//  4. source pins: the GMST ids are checked in versionlib, SEH, steady state is one compare, LoadIni stores the key,
//     the F11 row says it changes gameplay, default.ini and the HUD writer agree, presets keep it.
// Author: Moragar. Last modified: 2026-11-24.

#include "hz_scan_reach.h"

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
// Skip forward declarations (the first '{' after the signature can be a later
// function when the file is CRLF, because a pin of "fn()\n" never matches "fn()\r\n").
std::string FnBody(const std::string& a_s, const std::string& a_sig)
{
	std::size_t i = 0;
	for (;;) {
		i = a_s.find(a_sig, i);
		if (i == std::string::npos) return {};
		const auto b = a_s.find_first_of(";{", i + a_sig.size());
		if (b == std::string::npos) return {};
		if (a_s[b] == ';') { i = b + 1; continue; }
		int d = 0;
		for (auto p = b; p < a_s.size(); ++p) {
			if (a_s[p] == '{') ++d;
			else if (a_s[p] == '}' && --d == 0) return a_s.substr(b, p - b + 1);
		}
		return {};
	}
}

}

int main()
{
	using namespace hzscanreach;
	// 1
	Expect(Parse("0") == kVanilla && Parse("1") == kX2 && Parse(" 2 ") == kX3 && Parse("3\r") == kX5, "Parse: 0 - 3 with spaces trimmed");
	Expect(Parse("") == kVanilla && Parse("4") == kVanilla && Parse("-1") == kVanilla && Parse("x") == kVanilla && Parse("10") == kVanilla, "Parse: anything else is Vanilla");
	Expect(std::string(Name(kVanilla)) == "Vanilla" && std::string(Name(kX2)) == "x2" && std::string(Name(kX3)) == "x3" && std::string(Name(kX5)) == "x5", "Name: the four labels");
	Expect(Value(kX2, 50.0f) == 100.0f && Value(kX3, 50.0f) == 150.0f && Value(kX5, 50.0f) == 250.0f && Value(kX2, 10.0f) == 20.0f && Value(kX3, 10.0f) == 30.0f && Value(kX5, 10.0f) == 50.0f, "vanilla game values: highlight 100 / 150 / 250 m, scan 20 / 30 / 50 m (each step a visible difference)");
	Expect(Value(kX5, 150.0f) == kMaxRange && Value(kX3, 200.0f) == kMaxRange && Value(kX5, 600.0f) == 600.0f && Value(kX5, 1000.0f) == 1000.0f, "capped at 500 m (lag reports past it); a range mod's 500 m+ is kept, never shrunk");
	Expect(Value(kX5, 0.0f) == 0.0f && Value(kX2, -5.0f) == -5.0f && Value(kVanilla, 42.0f) == 42.0f, "0 or less stays as it is; Vanilla gives the value back");
	Expect(std::string(kKeys[kBase]) == "fHandScannerBaseRange" && std::string(kKeys[kScan]) == "fHandScannerScanRange" && kN == 2, "the two GMSTs by their game names (highlight distance, scan distance)");
	// 2
	Orig none;
	Expect(Next(kVanilla, kVanilla, none) == Act::None && Next(kX2, kVanilla, none) == Act::Write && Next(kX5, kX2, none) == Act::Write, "Vanilla at start writes nothing; a pick writes");
	Orig o; o.have = true;
	Expect(Next(kVanilla, kX3, o) == Act::Restore && Next(kVanilla, kX3, none) == Act::None && Next(kX3, kX3, o) == Act::None && Next(9, kX2, o) == Act::Restore, "back to Vanilla restores (only with a capture); no change = nothing; out of range = Vanilla");
	Expect(!Drifted(100.0f, 100.0f) && !Drifted(100.001f, 100.0f) && Drifted(150.0f, 100.0f), "Drifted: a real change only");

	// 3. the shared state machine (Settled / Pick / Recheck in hz_scan_reach.h, the same code main.cpp runs) on a fake game
	//    that tracks who owns each value. The checks are on the OUTCOME (what is left in the game), not on a copy of
	//    main.cpp's order, so they catch the yield/restore cases (a one-setting outside change, and Vanilla then the same level) and any like them.
	struct Fake
	{
		float cur[kN]; bool ours[kN]; float base[kN];
		bool found[kN] = { true, true };
		void Set(const Plan& p) { for (int i = 0; i < kN; ++i) if (p.w[i]) { cur[i] = p.val[i]; ours[i] = !(p.restore || p.yielded); } }   // a give-back is the game's own value again, not Horizon's
		void Outside(int i, float v) { cur[i] = v; ours[i] = false; }
	};
	auto start = [](float a_base, float a_scan) { Fake f; f.cur[0] = f.base[0] = a_base; f.cur[1] = f.base[1] = a_scan; f.ours[0] = f.ours[1] = false; return f; };
	auto pick = [](State& st, Fake& f, int want) { if (Settled(st, want)) return Plan{}; const auto p = Pick(st, want, f.cur, f.found); f.Set(p); return p; };
	auto recheck = [](State& st, Fake& f) { const auto p = Recheck(st, f.cur, f.found); f.Set(p); return p; };
	{   // M-1 (probe C): x5, then only the scan distance is changed outside: Horizon yields, and VANILLA must not leave 250 m
		State st; Fake f = start(50.0f, 10.0f);
		pick(st, f, kX5);
		Expect(f.cur[0] == 250.0f && f.cur[1] == 50.0f, "x5 of 50 / 10 writes 250 / 50");
		f.Outside(kScan, 20.0f);
		const auto y = recheck(st, f);
		Expect(y.yielded && y.driftKey == kScan && y.w[kBase] && !y.w[kScan], "a one-setting outside change: Horizon yields and gives back the OTHER setting");
		Expect(f.cur[kBase] == 50.0f && f.cur[kScan] == 20.0f, "after the yield the highlight distance is back at 50 m and the other mod's 20 m is untouched (M-1)");
		pick(st, f, kVanilla);
		Expect(f.cur[kBase] == 50.0f && f.cur[kScan] == 20.0f, "VANILLA after the yield leaves nothing of Horizon behind (M-1)");
	}
	{   // M-2 (probe D): yield at x3, VANILLA, then x3 again must apply again
		State st; Fake f = start(50.0f, 10.0f);
		pick(st, f, kX3);
		f.Outside(kBase, 80.0f);
		recheck(st, f);
		Expect(st.applied == kVanilla && st.yielded == kX3, "yielded at x3");
		Expect(Settled(st, kX3), "picking x3 again right after the yield is ignored (wait for a new pick)");
		pick(st, f, kVanilla);
		Expect(st.yielded == -1, "picking VANILLA clears the yield (M-2)");
		const auto p = pick(st, f, kX3);
		Expect(p.act && st.applied == kX3 && f.cur[kBase] == 240.0f && f.cur[kScan] == 30.0f, "x3 after VANILLA applies again on top of the game's values at that moment: 80 -> 240 m, 10 -> 30 m (M-2)");
	}
	{   // both settings changed outside: nothing is written back, the yield is clean
		State st; Fake f = start(50.0f, 10.0f);
		pick(st, f, kX2);
		f.Outside(kBase, 60.0f); f.Outside(kScan, 15.0f);
		const auto y = recheck(st, f);
		Expect(y.yielded && !y.w[0] && !y.w[1] && f.cur[0] == 60.0f && f.cur[1] == 15.0f, "both changed outside: Horizon writes nothing");
		const auto none = recheck(st, f);
		Expect(!none.act, "after a yield there is nothing more to recheck");
	}
	{   // Vanilla only, and a pick while nothing is captured, write nothing
		State st; Fake f = start(50.0f, 10.0f);
		const auto p = pick(st, f, kVanilla);
		Expect(!p.act && f.cur[0] == 50.0f && f.cur[1] == 10.0f, "Vanilla at start writes nothing");
		State st2; Fake g = start(50.0f, 10.0f); g.found[0] = g.found[1] = false;
		const auto q = pick(st2, g, kX2);
		Expect(q.noKeys && !q.act && st2.applied == kX2 && !st2.orig.have, "neither setting found: nothing is written (and no base is kept)");
		State st3; Fake h = start(50.0f, 10.0f); h.found[kScan] = false;
		const auto r = pick(st3, h, kX2);
		Expect(r.act && r.w[kBase] && !r.w[kScan] && h.cur[kBase] == 100.0f && h.cur[kScan] == 10.0f, "one setting missing: only the found one is written");
		State st4; Fake k = start(600.0f, 30.0f);
		pick(st4, k, kX5);
		Expect(k.cur[0] == 600.0f && k.cur[1] == 150.0f, "a range mod's 600 m is kept (never shrunk), 30 m x5 = 150 m");
	}
	{   // x2 then x3 must not compound (the recapture case): the base stays the first capture, not the already-multiplied value
		State st; Fake f = start(50.0f, 10.0f);
		pick(st, f, kX2);
		Expect(f.cur[0] == 100.0f && f.cur[1] == 20.0f, "x2 of 50 / 10 writes 100 / 20");
		pick(st, f, kX3);
		Expect(f.cur[0] == 150.0f && f.cur[1] == 30.0f && st.orig.v[0] == 50.0f && st.orig.v[1] == 10.0f, "x2 then x3 writes 150 / 30 (3 x the first capture, never 300 / 60)");
	}
	{   // VANILLA must not overwrite another mod's value (the no-drift-check case)
		State st; Fake f = start(50.0f, 10.0f);
		pick(st, f, kX5);
		f.Outside(kBase, 80.0f);
		pick(st, f, kVanilla);
		Expect(f.cur[0] == 80.0f && f.cur[1] == 10.0f, "VANILLA leaves a drifted highlight at 80 m and restores the scan distance that still holds Horizon's value");
	}
	{   // a new level before the next recheck: rebase the drifted key, never overwrite it with the old base x new factor
		State st; Fake f = start(50.0f, 10.0f);
		pick(st, f, kX2);
		f.Outside(kBase, 80.0f);
		const auto p = pick(st, f, kX3);
		Expect(p.act && st.orig.v[kBase] == 80.0f && st.orig.v[kScan] == 10.0f && f.cur[kBase] == 240.0f && f.cur[kScan] == 30.0f,
			"x2, an outside 80 m, then x3 before a recheck: the drifted highlight is rebased (80 x 3 = 240 m) and the undrifted scan stays 10 x 3 = 30 m (never 150 m over the 80 m)");
	}
	{   // randomized: every step is a F11 pick, an outside write or a recheck; the outcome rules must hold after each
		std::mt19937 rng(4351);
		int bad = 0, yields = 0, restores = 0, vanillaWrites = 0, steps = 0;
		for (int run = 0; run < 4000; ++run) {
			const bool mod = rng() % 3 == 0;
			State st; Fake f = start(mod ? 150.0f : 50.0f, mod ? 30.0f : 10.0f);
			const bool vanillaOnly = run % 7 == 0;
			for (int step = 0; step < 40; ++step, ++steps) {
				const unsigned r = rng() % 6;
				if (r == 0 && !vanillaOnly) { const int i = static_cast<int>(rng() % 2); f.Outside(i, 20.0f + static_cast<float>(rng() % 20) * 10.0f); }
				else if (r <= 2) { const auto p = recheck(st, f); if (p.yielded) ++yields; }
				else {
					const int want = vanillaOnly ? kVanilla : static_cast<int>(rng() % 4);
					float before[kN]; bool bOurs[kN]; float prevWrote[kN];
					for (int i = 0; i < kN; ++i) { before[i] = f.cur[i]; bOurs[i] = f.ours[i]; prevWrote[i] = st.wrote[i]; }
					const auto p = pick(st, f, want);
					if (p.restore) ++restores;
					if (p.act && vanillaOnly) ++vanillaWrites;
					for (int i = 0; i < kN; ++i) {
						if (!p.w[i] || p.restore) continue;
						// a pick never writes over a value Horizon did not write unless it rebased on it
						if (!bOurs[i] && Drifted(before[i], prevWrote[i]) && !(st.orig.have && st.orig.v[i] == before[i] && p.val[i] == Value(want, before[i]))) ++bad;
					}
				}
				// outcome rules
				for (int i = 0; i < kN; ++i) {
					if (st.applied == kVanilla && f.ours[i] && f.cur[i] != f.base[i] && !st.orig.have) { ++bad; }   // nothing of Horizon may be left once it claims Vanilla
					if (st.applied != kVanilla && st.orig.ok[i] && f.ours[i] && f.cur[i] != Value(st.applied, st.orig.v[i])) ++bad;   // what it holds is base x factor
					if (f.cur[i] > 1000.0f) ++bad;
				}
			}
		}
		Expect(bad == 0, "randomized (" + std::to_string(steps) + " steps): Horizon never leaves its own value in the game once it says Vanilla, and every value it holds is base x factor");
		Expect(vanillaWrites == 0, "randomized: a Vanilla-only player never gets a write");
		Expect(yields > 0 && restores > 0, "randomized: yields (" + std::to_string(yields) + ") and restores (" + std::to_string(restores) + ") both happen");
	}

	// 4. source pins
	const auto cpp = ReadAll("src/main.cpp");
	const auto as = ReadAll("actionscript/horizon_block.as");
	const auto ini = ReadAll("Interface/HorizonUI/HorizonUI.default.ini");
	const auto hdr = ReadAll("src/hz_scan_reach.h");
	const auto apply = FnBody(cpp, "void ScanReachApply()");
	const auto call = FnBody(cpp, "static void HzScanReachCall(HzScanReachRaw* a_io)");
	const auto ids = FnBody(cpp, "static int HzScanReachIds()");
	const auto rec = FnBody(cpp, "void ScanReachRecheck()");
	Expect(Count(cpp, "ScanReachApply();") == 2 && Has(FnBody(cpp, "void BannerPoll(ULONGLONG a_now)"), "ScanReachApply();"), "ScanReachApply is called once, from BannerPoll (UI thread, 100 ms gate); plus its forward declaration");
	Expect(Has(apply, "if (hzscanreach::Settled(g_scanReach, want)) return;") && apply.find("hzscanreach::Settled(") < apply.find("HzScanReachIds()"), "steady state returns before any game call (one atomic load and a compare)");
	Expect(Has(apply, "hzscanreach::Pick(g_scanReach, want, cur, found)") && Has(rec, "hzscanreach::Recheck(g_scanReach, cur, found)"), "main.cpp runs the shared state machine (no private copy of the yield order)");
	Expect(Has(hdr, "if (Drifted(a_cur[i], a_s.wrote[i])) a_s.orig.v[i] = a_cur[i];"), "Pick rebases a drifted key on a new level so the new factor is applied to the current value");
	Expect(Has(apply, "keep applied as it is") && Count(apply, "g_scanReach.applied = hzscanreach::Norm(want)") == 1, "a failed read on a Vanilla pick leaves applied unchanged, so the restore can still run on the next poll");
	Expect(Has(call, "s_looked[i] = true") && Has(call, "static bool s_looked[hzscanreach::kN] = {};"), "a missing scan-reach setting is looked up once per session");
	Expect(Has(ids, "GameSettingCollection::Singleton.id()") && Has(ids, "GameSettingCollection::GetSetting.id()") && Has(ids, "AddrSlotMiss(ss) || hzaddr::AddrSlotMiss(gs)"), "both GameSettingCollection ids are checked in versionlib first");
	Expect(Has(FnBody(cpp, "static bool HzScanReachWrite(const hzscanreach::Plan& a_p)"), "HzScanReachSEH(&io)") && Has(call, "if (!col) return;") && Has(call, "f->GetType() == RE::Setting::Type::kFloat"), "SEH, null and float checks");
	Expect(Has(rec, "HzScanReachWrite(p);") && !Has(rec, "SetFloat") && Has(rec, "Horizon put back only the values it set") && Has(rec, "a startup bat"), "recheck: a yield writes only what the plan says (the other setting, if it is still Horizon's) and logs once");
	Expect(!Has(cpp, "fHandScannerScanRangeSkillMult\"") && !Has(hdr, "\"fHandScannerScanRangeSkillMult\""), "the Surveying skill multiplier is never written");
	Expect(Count(apply, "g_scanReachMissLogged = true") >= 3, "a miss is logged once");
	const auto load = FnBody(cpp, "void LoadIni(bool a_reloadMsglog = true)");
	Expect(Has(load, "if (get(\"scanreach\", v)) scanReach = hzscanreach::Parse(v);") && Has(load, "g_scanReachWant.store(scanReach"), "LoadIni (load and every save / apply) stores the wanted position");
	Expect(Has(as, "{\"k\":\"ScanReach\",\"l\":\"SCAN REACH\",\"t\":\"r\",\"opts\":[\"VANILLA\",\"2X\",\"3X\",\"5X\"],\"ids\":[0,1,2,3],\"note\":\"Changes gameplay: "), "F11 SCAN REACH row: labels, and the note starts with 'Changes gameplay'");
	Expect(as.find("{\"k\":\"ScanOutlineThickness\"") < as.find("{\"k\":\"ScanReach\""), "SCAN REACH sits right under OUTLINE THICKNESS");
	const auto iniKey = ini.find("\r\nScanReach=0\r\n");
	Expect(iniKey != std::string::npos && ini.find("\r\nScanOutlineThickness=0\r\n") < iniKey && iniKey < ini.find("HideMainHudWhileScanning=1"), "default.ini: ScanReach=0 under [Scanner], in the HZ40_SCAN_KEYS order");
	const std::string r1 = "Scan reach (changes gameplay; the game's own hand scanner range settings, set by the DLL): 0 = Vanilla (default: nothing is changed, range mods keep theirs),";
	const std::string r2 = "1 = x2, 2 = x3, 3 = x5 of the game's highlight distance (50 m) and scan distance (10 m); the Surveying bonus still adds on top; never more than 500 m. Applies the next time you open the scanner";
	Expect(Has(ini, "; " + r1 + "\r\n; " + r2 + "\r\nScanReach=0") && Has(as, "\"ScanReach\":[\"" + r1 + "\",\"" + r2 + "\"]"), "the default.ini comment equals the HUD writer's comment");
	Expect(Has(ReadAll("src/hz_preset_apply.h"), "a_kl == \"scanreach\""), "a preset Apply keeps the player's own SCAN REACH");

	std::cout << (g_fail ? "FAILED " : "PASSED ") << g_ok << " ok, " << g_fail << " FAIL\n";
	return g_fail ? 1 : 0;
}
