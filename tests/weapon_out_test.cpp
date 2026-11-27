// Purpose: pin Starfield "weapon out" mapping for Equipment WEAPON DRAWN ONLY, and the plugin's no-lookup rule.
// Inputs: src/hz_weapon_out.h, src/main.cpp (source pins only).
// Outputs: pass/fail on stdout. No game, no CommonLibSF.
// Evidence (public): Creation Kit wiki / Starfield Community Patch issue 866: IsWeaponOut 0 holstered, 1 fists, 2 weapon.
// CommonLibSF PlayerSetWeaponStateEvent::GetEventSource is REL::ID{0}; calling it hard-exits IDDB.
// Address Library v5 remaps; slot 138719 is not this function.
// Author: Moragar. Last modified: 2026-11-27.
#include "hz_weapon_out.h"

#include <fstream>
#include <iostream>
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

}

int main()
{
	using namespace hzwpnout;
	Expect(!OutFromPapyrus(kHolstered) && !OutFromPapyrus(kFists) && OutFromPapyrus(kWeapon),
		"Papyrus helper matches the HUD: 0 holstered and 1 fists are not out; 2 weapon is out");
	Expect(!OutFromPapyrus(1) && OutFromPapyrus(2), "a drawn gun (2) is out; fists (1) are not");
	Expect(!OutFromPapyrus(-1) && !OutFromPapyrus(3) && !OutFromPapyrus(5), "unknown Papyrus values are not out");

	Expect(!OutFromWeaponState(static_cast<int>(WeaponState::kSheathed)), "TES sheathed is not out");
	Expect(OutFromWeaponState(static_cast<int>(WeaponState::kWantToDraw)) && OutFromWeaponState(static_cast<int>(WeaponState::kDrawing)) && OutFromWeaponState(static_cast<int>(WeaponState::kDrawn)),
		"TES drawing and drawn are out");
	Expect(OutFromWeaponState(static_cast<int>(WeaponState::kWantToSheathe)) && OutFromWeaponState(static_cast<int>(WeaponState::kSheathing)),
		"TES sheathing is still out (the weapon is in hand)");

	// Mixing the enums is the Community Patch class of bug: Papyrus 2 is a weapon, TES 2 is kDrawing.
	Expect(OutFromPapyrus(2) && OutFromWeaponState(2), "both 2s are out, but they are different enums");
	Expect(kWeapon == 2 && static_cast<int>(WeaponState::kDrawing) == 2, "the numeric 2 collision is why a mixed check is unsafe");
	Expect(!OutFromPapyrus(static_cast<int>(WeaponState::kDrawn)), "TES kDrawn (3) is not a Papyrus IsWeaponOut value");

	Expect(StateFromActorState2Fo4(0u) == 0 && StateFromActorState2Fo4(2u << 1) == 2 && StateFromActorState2Fo4(3u << 1) == 3,
		"FO4 pack: weaponState at actorState2 bit 1, 3 bits");
	Expect(StateFromActorState2Skyrim(3u << 5) == 3 && StateFromActorState2Fo4(3u << 5) != 3,
		"Skyrim pack is bit 5; using it on FO4 bits does not yield kDrawn");

	const auto cpp = ReadAll("src/main.cpp");
	const auto as = ReadAll("actionscript/horizon_block.as");
	Expect(!cpp.empty() && !as.empty(), "main.cpp and horizon_block.as are readable from the repo root");
	Expect(!Has(cpp, "PlayerSetWeaponStateEvent::GetEventSource"),
		"the plugin never looks up PlayerSetWeaponStateEvent (CommonLibSF GetEventSource id 0 hard-exits)");
	Expect(!Has(cpp, "REL::ID(138719)") && !Has(cpp, "ID(138719)"),
		"Address Library slot 138719 is not called (v5 remaps; that slot is not GetEventSource)");
	Expect(!Has(cpp, "IsWeaponOut"), "the plugin does not poll Papyrus IsWeaponOut");
	Expect(Has(as, "this.hzPlugActive ? this.hzPlugDrawn : this.hzWpnRet"),
		"without a plugin feed, Equipment uses the weapon reticle (not the HUD crosshair on flag)");
	Expect(!Has(as, "this.hzAmmoDrawn && this.hzCrossOn && this.hzWpnRet"),
		"the old fallback that required the HUD crosshair on is gone");
	Expect(Has(as, "hzSetWeaponDrawn") && Has(as, "hzPlugActive"),
		"hzSetWeaponDrawn remains the override if a later published event id can call it");

	std::cout << (g_fail ? "FAILED " : "PASSED ") << g_ok << " ok, " << g_fail << " FAIL\n";
	return g_fail ? 1 : 0;
}
