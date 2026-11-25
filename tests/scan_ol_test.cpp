// Unit tests for 0.43.3.2 [Scanner] ScanOutlineThickness (src/hz_scan_ol.h) plus source pins for its main.cpp glue,
// the HUD F11 row and the default ini. No game, no CommonLibSF. Build:
//   zig c++ -std=c++20 -Wall -Wextra -I src tests/scan_ol_test.cpp -o test_scratch/scan_ol_test   (run from the repo root)
// Proves:
//  1. Parse: "0" / "1" / "2" (spaces trimmed) map to the positions; anything else is Vanilla;
//  2. Value: Thick 1.5x / Thicker 2x of the captured game value; 0 (a kind turned off) stays 0; capped at 12;
//  3. a model of ScanOlApply over random position changes: the game only ever holds the captured originals or a
//     factor of them (never a factor of a factor), the originals are read once before the first write, a Vanilla
//     start or a Vanilla-only run never touches the game, a setting not found is never written;
//  4. mutants (factor of the current value, Thicker 3x, no restore on Vanilla, 0 scaled, a Vanilla start write) fail (3);
//  5. source pins: the apply runs only from BannerPoll right after ScanHlApply (UI thread), behind the id check and
//     SEH, steady state is one compare; LoadIni stores the key; the eleven [Monocle] names (0.43.5: + _Bounty); the F11 row; the HUD key
//     table, the writer comment and default.ini agree; no file work.
// Author: Moragar. Last modified: 2026-11-18.

#include "hz_scan_ol.h"

#include <cmath>
#include <fstream>
#include <functional>
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
bool Near(float a, float b) { return std::fabs(a - b) < 1e-5f; }

using ValueFn = std::function<float(int, float)>;
using NextFn = std::function<hzscanol::Act(int, int, const hzscanol::Orig&)>;

// model of ScanOlApply (main.cpp) on a fake game. 'cur' is what the game holds, 'base' its own values (a player
// tweak included), 'exists' which settings the game build has. Returns "" when every property holds.
std::string Model(const ValueFn& a_value, const NextFn& a_next, bool a_writeFromCurrent, unsigned a_seed)
{
	std::mt19937 rng(a_seed);
	float base[hzscanol::kN];
	bool  exists[hzscanol::kN];
	for (int i = 0; i < hzscanol::kN; ++i) {
		const float choices[] = { 0.0f, 1.0f, 1.5f, 2.0f, 3.0f, 4.0f };
		base[i] = choices[rng() % 6];
		exists[i] = (rng() % 10) != 0;
	}
	float cur[hzscanol::kN];
	for (int i = 0; i < hzscanol::kN; ++i) cur[i] = base[i];
	hzscanol::Orig orig;
	int applied = hzscanol::kVanilla;
	int reads = 0, writes = 0;
	bool everNonVanilla = false;
	for (int step = 0; step < 200; ++step) {
		const int want = static_cast<int>(rng() % 4);   // 3 = an unknown value (Vanilla)
		const int w = (want == 1 || want == 2) ? want : 0;
		if (w != 0) everNonVanilla = true;
		if (w == applied) continue;
		const auto act = a_next(w, applied, orig);
		applied = w;
		if (act != hzscanol::Act::None && !orig.have) {
			if (act == hzscanol::Act::Restore) return "a restore before any capture";
			++reads;
			orig.have = true;
			for (int i = 0; i < hzscanol::kN; ++i) { orig.ok[i] = exists[i]; orig.v[i] = exists[i] ? cur[i] : 0.0f; }
		}
		for (int i = 0; i < hzscanol::kN && act != hzscanol::Act::None; ++i) {
			if (!orig.ok[i]) continue;
			if (!exists[i]) return "wrote a setting the game does not have";
			const float from = a_writeFromCurrent ? cur[i] : orig.v[i];
			cur[i] = act == hzscanol::Act::Restore ? orig.v[i] : a_value(w, from);
			++writes;
		}
		for (int i = 0; i < hzscanol::kN; ++i) {
			if (!exists[i]) continue;
			// independent oracle: 1.5x / 2x of the game's own value, 0 stays 0, at most 12
			const float f = w == 1 ? 1.5f : (w == 2 ? 2.0f : 1.0f);
			const float expect = base[i] <= 0.0f ? base[i] : std::fmin(base[i] * f, 12.0f);
			if (!Near(cur[i], expect)) return "game value " + std::to_string(cur[i]) + " is not the factor of the game's own value " + std::to_string(base[i]);
		}
	}
	if (reads > 1) return "the originals were read more than once";
	if (!everNonVanilla && (reads || writes)) return "a Vanilla-only run touched the game";
	return "";
}

}

int main()
{
	using namespace hzscanol;
	// 1. Parse
	Expect(Parse("0") == kVanilla && Parse("1") == kThick && Parse("2") == kThicker && Parse(" 2\r") == kThicker, "Parse: 0 / 1 / 2, spaces and CR trimmed");
	Expect(Parse("") == kVanilla && Parse("3") == kVanilla && Parse("12") == kVanilla && Parse("x") == kVanilla && Parse("-1") == kVanilla, "Parse: anything else is Vanilla (writes nothing)");
	// 2. Value
	Expect(Near(Value(kThick, 2.0f), 3.0f) && Near(Value(kThicker, 2.0f), 4.0f) && Near(Value(kThick, 1.0f), 1.5f) && Near(Value(kThicker, 3.0f), 6.0f), "Thick 1.5x, Thicker 2x of the game value");
	Expect(Near(Value(kVanilla, 2.5f), 2.5f), "Vanilla gives the game value back");
	Expect(Value(kThicker, 0.0f) == 0.0f && Value(kThick, -1.0f) == -1.0f, "a kind turned off (0) stays off");
	Expect(Near(Value(kThicker, 8.0f), kMax) && Near(Value(kThicker, 20.0f), 20.0f), "capped at 12; a game value already above 12 is kept");
	Expect(Next(kVanilla, kVanilla, Orig{}) == Act::None, "Vanilla at start: nothing written");
	Orig none;
	Expect(Next(kVanilla, kThick, none) == Act::None, "Vanilla with nothing captured: nothing to give back");
	Orig have; have.have = true;
	Expect(Next(kVanilla, kThicker, have) == Act::Restore && Next(kThick, kVanilla, none) == Act::Write && Next(kThick, kThick, have) == Act::None, "Next: restore / write / none");
	Expect(Next(7, kThick, have) == Act::Restore, "an unknown position is Vanilla");
	// 3. model
	const ValueFn value = [](int p, float v) { return Value(p, v); };
	const NextFn next = [](int w, int a, const Orig& o) { return Next(w, a, o); };
	std::string err;
	for (unsigned seed = 1; seed <= 300 && err.empty(); ++seed) err = Model(value, next, false, seed);
	Expect(err.empty(), "model over 300 random runs: the game holds only its own values or one factor of them, originals read once, missing settings never written" + (err.empty() ? std::string() : " (" + err + ")"));
	// 4. mutants
	struct Mut { const char* name; ValueFn v; NextFn n; bool fromCur; };
	const Mut muts[] = {
		{ "factor applied to the current value (Thick then Thicker compounds)", value, next, true },
		{ "Thicker is 3x", [](int p, float v) { return p == kThicker && v > 0.0f ? std::fmin(v * 3.0f, kMax) : Value(p, v); }, next, false },
		{ "Vanilla does not give the values back", value, [](int w, int a, const Orig& o) { return w == kVanilla ? Act::None : Next(w, a, o); }, false },
		{ "a kind turned off is scaled", [](int p, float v) { return v <= 0.0f ? 1.0f * Mul(p) : Value(p, v); }, next, false },
		{ "Vanilla start writes", value, [](int w, int a, const Orig& o) { return (w == kVanilla && a == kVanilla) ? Act::Write : Next(w, a, o); }, false },
	};
	for (const auto& m : muts) {
		std::string e;
		for (unsigned seed = 1; seed <= 300 && e.empty(); ++seed) e = Model(m.v, m.n, m.fromCur, seed);
		// "Vanilla start writes" can only show when the model asks for a no-change Vanilla: check that directly too
		const bool direct = std::string(m.name) == "Vanilla start writes" && m.n(kVanilla, kVanilla, Orig{}) != Act::None;
		Expect(!e.empty() || direct, std::string("mutant caught: ") + m.name);
	}
	Expect(!Near(kMulThick * 3.0f, 3.0f) && kMax >= 6.0f, "the factors move every vanilla default and the cap leaves 2x of 3 alone");

	// 5. source pins
	const auto cpp = ReadAll("src/main.cpp");
	const auto as = ReadAll("actionscript/horizon_block.as");
	const auto ini = ReadAll("Interface/HorizonUI/HorizonUI.default.ini");
	const auto apply = FnBody(cpp, "void ScanOlApply()\n");
	const auto poll = FnBody(cpp, "void BannerPoll(ULONGLONG a_now)");
	Expect(Count(cpp, "ScanOlApply();") == 2 && Has(poll, "ScanHlApply();") && poll.find("ScanOlApply();") == poll.find("ScanHlApply();") + std::string("ScanHlApply();").size() + std::string("         // 0.43.3.1: scanner highlight area (one atomic load and a compare unless it changed)\n\t\t").size(), "ScanOlApply is called once, from BannerPoll right after ScanHlApply (UI thread, 100 ms gate); plus its forward declaration");
	Expect(Has(apply, "if (want == g_scanOlApplied) return;") && apply.find("if (want == g_scanOlApplied) return;") < apply.find("HzAddrSlot"), "steady state returns before any game call (one atomic load and a compare)");
	Expect(Has(apply, "HzAddrSlot(id)") && Has(apply, "AddrSlotMiss(slot)") && Has(apply, "HzScanOlSEH(&io)") && apply.find("AddrSlotMiss(slot)") < apply.find("HzScanOlSEH(&io)"), "the INISettingCollection id is checked before the singleton is touched; the calls run under SEH");
	const auto call = FnBody(cpp, "static void HzScanOlCall(HzScanOlRaw* a_io)");
	Expect(Has(call, "if (!col) return;") && Has(call, "HzScanHlFind(col, hzscanol::kKeys[i])") && Has(call, "if (!s) continue;"), "null checks on the collection and each setting; float type check through HzScanHlFind");
	Expect(Has(apply, "hzscanol::Value(want, g_scanOlOrig.v[i])") && Has(apply, "restore ? g_scanOlOrig.v[i]"), "writes are computed from the captured originals, never from the current value");
	Expect(Has(apply, "if (!g_scanOlOrig.ok[i]) continue;"), "a setting not found at capture is never written");
	Expect(!Has(apply, "std::filesystem") && !Has(cpp, "remove(") && Count(apply, "g_scanOlMissLogged = true") >= 3, "no file work; a miss is logged once");
	const auto load = FnBody(cpp, "void LoadIni(bool a_reloadMsglog = true)");
	Expect(Has(load, "if (get(\"scanoutlinethickness\", v)) scanOl = hzscanol::Parse(v);") && Has(load, "g_scanOlWant.store(scanOl"), "LoadIni (load and every save / apply) stores the wanted position");
	const auto hdr = ReadAll("src/hz_scan_ol.h");
	const char* names[] = { "", "_FullyScanned", "_Generic", "_Scanned", "_Social", "_TargetFullyScanned", "_TargetGeneric", "_TargetScannable", "_TargetScanned", "_Tracked", "_Bounty" };
	bool allNames = true;
	for (const char* n : names) allNames = allNames && Has(hdr, std::string("\"fHighlightScannableOutlineThickness") + n + ":Monocle\"");
	Expect(allNames && kN == 11, "the eleven [Monocle] outline settings, by their game names (0.43.5: + _Bounty, bounty targets)");
	Expect(Has(as, "[\"ScanHighlightArea\",\"i\",1,0,5],[\"ScanOutlineThickness\",\"i\",0,0,2],"), "HZ40_SCAN_KEYS: ScanOutlineThickness, int 0 - 2, default 0 (Vanilla)");
	Expect(Has(as, "{\"k\":\"ScanOutlineThickness\",\"l\":\"OUTLINE THICKNESS\",\"t\":\"r\",\"opts\":[\"VANILLA\",\"THICK\",\"THICKER\"],\"ids\":[0,1,2],\"note\":\""), "F11 SCANNER row shows labels, not numbers");
	const auto iniKey = ini.find("\r\nScanOutlineThickness=0\r\n");
	Expect(iniKey != std::string::npos && ini.find("\r\nScanHighlightArea=1\r\n") < iniKey && iniKey < ini.find("HideMainHudWhileScanning=1"), "default.ini: ScanOutlineThickness=0 under [Scanner], in the HZ40_SCAN_KEYS order");
	const std::string c1 = "Outline thickness of the hand scanner highlight (the game's own [Monocle] outline settings, set by the DLL): 0 = Vanilla";
	const std::string c2 = "(default: the game's own values, nothing is changed), 1 = Thick (1.5x), 2 = Thicker (2x). Applies the next time you open the scanner";
	Expect(Has(ini, "; " + c1 + "\r\n; " + c2 + "\r\nScanOutlineThickness=0") && Has(as, "\"ScanOutlineThickness\":[\"" + c1 + "\",\"" + c2 + "\"]"), "the default.ini comment equals the HUD writer's comment");

	std::cout << (g_fail ? "FAILED " : "PASSED ") << g_ok << " ok, " << g_fail << " FAIL\n";
	return g_fail ? 1 : 0;
}
