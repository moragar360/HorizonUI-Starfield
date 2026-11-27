#pragma once

// Purpose: map Starfield "weapon out" values for the Equipment card rule WEAPON DRAWN ONLY.
// Evidence (public, not a guess):
//   Papyrus / console player.IsWeaponOut (Creation Kit wiki; Starfield Community Patch issue 866):
//     0 = holstered, 1 = fists only, 2 = a weapon in either hand. Spells do not count.
//   A check of == 1 misses a drawn gun (that is the Community Patch dialog bug). Horizon must treat 1 and 2 as out.
//   TES WEAPON_STATE (CommonLibSSE ActorState / CommonLibF4 ActorState):
//     0 sheathed, 1 want-to-draw, 2 drawing, 3 drawn, 4 want-to-sheathe, 5 sheathing.
//   Papyrus 2 is NOT WEAPON_STATE::kDrawing. Mixing the two enums is how a "drawn == 2" check can fail.
//   CommonLibSF's PlayerSetWeaponStateEvent has no members and GetEventSource is REL::ID{0}
//   (comment 138719 is an old Address Library slot; v5 remaps, so 138719 is not this function).
//   Calling GetEventSource with id 0 hard-exits IDDB. The plugin must skip that lookup.
// FO4 packs weaponState as 3 bits at actorState2 bit 1; Skyrim used bit 5. Starfield's ActorState in
// CommonLibSF is two opaque uint32s, so this header does not read live actor memory. The HUD fallback
// (hzWeaponOut) uses the weapon-reticle feed until a published GetEventSource id exists.
// Pure logic: no game, no CommonLibSF (tests/weapon_out_test.cpp). Author: Moragar. Last modified: 2026-11-27.

namespace hzwpnout {

inline constexpr int kHolstered = 0;
inline constexpr int kFists = 1;
inline constexpr int kWeapon = 2;

enum class WeaponState : int
{
	kSheathed = 0,
	kWantToDraw = 1,
	kDrawing = 2,
	kDrawn = 3,
	kWantToSheathe = 4,
	kSheathing = 5
};

// Papyrus / console IsWeaponOut. 1 (fists) and 2 (weapon) are out; 0 is holstered.
// Never `== 1` only: a drawn gun returns 2.
inline bool OutFromPapyrus(int a_v)
{
	return a_v == kFists || a_v == kWeapon;
}

// TES WEAPON_STATE: anything except sheathed counts as out (drawing and sheathing included).
inline bool OutFromWeaponState(int a_s)
{
	return a_s >= static_cast<int>(WeaponState::kWantToDraw) && a_s <= static_cast<int>(WeaponState::kSheathing);
}

// FO4 ActorState2 packing (bit 1, 3 bits). Not used to read live memory here.
inline int StateFromActorState2Fo4(unsigned a_as2)
{
	return static_cast<int>((a_as2 >> 1) & 7u);
}

// Skyrim ActorState2 packing (bit 5, 3 bits). Kept so a mixed-enum test can fail it.
inline int StateFromActorState2Skyrim(unsigned a_as2)
{
	return static_cast<int>((a_as2 >> 5) & 7u);
}

}
