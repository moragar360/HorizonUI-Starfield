// Extended Quick Menu data layer, layout math, and use dispatch. No game.
// Build (from the repo root; write the binary to a scratch folder, not the system temp folder or the source tree):
//   g++ -std=c++20 -Wall -Wextra -pthread -I src tests/quickslots_test.cpp -o test_scratch/quickslots_test.bin
// Author: Moragar

#include "hz_quickslots.h"
#include "hz_test_scratch.h"

#include <filesystem>
#include <iostream>
#include <string>
#include <vector>

namespace {

int g_fails = 0;
void Expect(bool ok, const char* w)
{
	if (ok) return;
	std::cerr << "FAIL: " << w << "\n";
	++g_fails;
}
void ExpectEqI(int got, int want, const char* w)
{
	if (got == want) return;
	std::cerr << "FAIL: " << w << "\n  got:  " << got << "\n  want: " << want << "\n";
	++g_fails;
}
void ExpectEqS(const std::string& got, const std::string& want, const char* w)
{
	if (got == want) return;
	std::cerr << "FAIL: " << w << "\n  got:  [" << got << "]\n  want: [" << want << "]\n";
	++g_fails;
}

}  // namespace

int main()
{
	using namespace hzqs;

	// defaults
	{
		const auto s = ParseIniText("");
		Expect(!s.extended, "default Extended Mode off");
		ExpectEqI(s.slotCount, 24, "default slot count 24");
		ExpectEqI(s.slotsPerRow, 6, "default slots per row 6");
		Expect(s.layout == Layout::CrossBars, "default layout CROSS+BARS");
		for (int i = 0; i < 12; ++i) Expect(s.key[i].empty(), "no default keys");
	}

	// ini parse, last key wins, any section
	{
		const auto s = ParseIniText(
			"[Cards Extra]\nQuickMenuHorizon=1\nQuickMenuExtended=1\n"
			"QuickMenuSlotCount=18\nQuickMenuSlotsPerRow=4\n"
			"QuickMenuExtendedLayout=BARS\nQuickMenuKey13=F3\n"
			"[QuickMenu]\nQuickMenuSlotCount=20\nQuickMenuKey13=F4\nQuickMenuKey24=Home\n");
		Expect(s.extended, "extended on");
		ExpectEqI(s.slotCount, 20, "last slot count wins");
		ExpectEqI(s.slotsPerRow, 4, "per row 4");
		Expect(s.layout == Layout::Bars, "layout bars");
		ExpectEqS(KeyOf(s, 13), "F4", "key 13 last wins");
		ExpectEqS(KeyOf(s, 24), "Home", "key 24 Home");
		Expect(KeyOf(s, 14).empty(), "unbound 14");
	}

	// clamp
	ExpectEqI(ClampCount(11), 12, "clamp lo");
	ExpectEqI(ClampCount(25), 24, "clamp hi");
	ExpectEqI(ClampPerRow(5), 6, "per row 5 -> 6");
	ExpectEqI(ClampPerRow(9), 8, "per row 9 -> 8");

	// hide keeps assignment
	{
		Store st;
		SetSlot(st, Assignment{13, 0xABC, "0x00000ABC", "Med Pack", Kind::Inventory, ""});
		SetSlot(st, Assignment{18, 0xDEF, "0x00000DEF", "Rifle", Kind::Inventory, ""});
		Settings s;
		s.extended = true;
		s.slotCount = 16;  // hides 18
		Expect(VisibleAssignment(s, st, 13) != nullptr, "13 visible at 16");
		Expect(VisibleAssignment(s, st, 18) == nullptr, "18 hidden at 16");
		Expect(FindSlot(st, 18) != nullptr && FindSlot(st, 18)->formId == 0xDEF, "18 kept while hidden");
		s.slotCount = 24;
		Expect(VisibleAssignment(s, st, 18) != nullptr, "18 returns when added back");
	}

	// inventory assign to 13 and 18 persists after a reopen (write then parse)
	{
		Store st;
		st.character = hzlog::MakeCharacter(0xABCDu, "Sam");
		SetSlot(st, Assignment{13, 0xAAA, "0x00000AAA", "Med Pack", Kind::Inventory, "Med Pack"});
		SetSlot(st, Assignment{18, 0xBBB, "0x00000BBB", "Razorback", Kind::Inventory, "Razorback"});
		const auto body = WriteStore(st);
		const auto back = ParseStore(body);
		Expect(FindSlot(back, 13) && FindSlot(back, 13)->formId == 0xAAA, "reopen: slot 13 FormID kept");
		Expect(FindSlot(back, 18) && FindSlot(back, 18)->formId == 0xBBB, "reopen: slot 18 FormID kept");
		ExpectEqS(FindSlot(back, 13)->name, "Med Pack", "reopen: slot 13 name kept");
		ExpectEqS(FindSlot(back, 18)->name, "Razorback", "reopen: slot 18 name kept");
	}

	// json round trip
	{
		Store st;
		st.character = hzlog::MakeCharacter(0xABCDu, "Sam");
		SetSlot(st, Assignment{13, 0x11, "", "Med Pack", Kind::Inventory, ""});
		SetSlot(st, Assignment{20, 0x22, "", "Void Form", Kind::Power, ""});
		SetSlot(st, Assignment{24, 0x33, "", "Quantum Essence", Kind::Essence, ""});
		Assignment ic;
		ic.index = 14;
		ic.formId = 0x44;
		ic.name = "Digipick";
		ic.kind = Kind::Inventory;
		ic.iconType = 1;
		ic.iconDir = "Data";
		ic.iconName = "Icons/digi";
		SetSlot(st, ic);
		const auto body = WriteStore(st);
		Expect(body.find("horizon.quickslots") != std::string::npos, "type tag");
		const auto back = ParseStore(body);
		ExpectEqS(back.character.key, st.character.key, "character key");
		Expect(FindSlot(back, 13) && FindSlot(back, 13)->formId == 0x11, "slot 13 form");
		Expect(FindSlot(back, 20) && FindSlot(back, 20)->kind == Kind::Power, "slot 20 power");
		Expect(FindSlot(back, 24) && FindSlot(back, 24)->kind == Kind::Essence, "slot 24 essence");
		ExpectEqS(FindSlot(back, 13)->name, "Med Pack", "name");
		Expect(FindSlot(back, 14) && FindSlot(back, 14)->iconType == 1
			&& FindSlot(back, 14)->iconDir == "Data" && FindSlot(back, 14)->iconName == "Icons/digi",
			"icon fixture path round-trips in the store");
		Expect(FindSlot(back, 13)->iconType == -1, "slots without an icon keep iconType -1");
	}

	// zero player id: memory only
	{
		Store st;
		st.character = hzlog::MakeCharacter(0, "Sam");
		SetSlot(st, Assignment{13, 1, "0x1", "X", Kind::Inventory, ""});
		Expect(!CanWriteStore(st.character), "name-hash key is not written");
		st.character = hzlog::MakeCharacter(0xABCDu, "Sam");
		Expect(CanWriteStore(st.character), "real id is written");
	}

	// file store tmp-then-replace
	{
		const auto dir = HzTestScratch("hzqs_");
		Store st;
		st.character = hzlog::MakeCharacter(0xABCDu, "Sam");
		SetSlot(st, Assignment{13, 0x99, "", "Frag", Kind::Inventory, ""});
		Expect(WriteStoreFile(dir, st), "write store");
		const auto path = StorePath(dir, st.character.key);
		Expect(std::filesystem::exists(path), "store file exists");
		Expect(path.filename().string().find("QuickSlots_") == 0, "filename prefix");
		const auto back = ReadStoreFile(dir, st.character.key);
		Expect(FindSlot(back, 13) && FindSlot(back, 13)->formId == 0x99, "reload form");
	}

	// layout CROSS+BARS: 1-12 native, 13-24 in bars of 6 under the T
	{
		Settings s;
		s.extended = true;
		s.slotCount = 24;
		s.slotsPerRow = 6;
		s.layout = Layout::CrossBars;
		const auto p = PlaceSlots(s, 100, 500, 400, 300, 960, 540);
		int native = 0, ext = 0, add = 0;
		for (const auto& x : p) {
			if (x.index == 0) ++add;
			else if (x.native) ++native;
			else ++ext;
		}
		ExpectEqI(native, 12, "12 native T slots");
		ExpectEqI(ext, 12, "12 extended");
		ExpectEqI(add, 0, "no add tile at 24");
		// first extended bar centered on tCx=300, 6 slots: first x = 300 - 2.5 * kExtPitch
		const auto* e13 = &*std::find_if(p.begin(), p.end(), [](const SlotPos& q) { return q.index == 13; });
		Expect(!e13->native, "13 is not native");
		Expect(std::abs(e13->x - (300.f - 2.5f * kExtPitch)) < 0.5f, "bar 1 centered on T");
		Expect(std::abs(e13->y - (400.f + 12.f + kExtFramePad + kExtFrameTitle + kExtBox * 0.5f)) < 0.5f, "bar 1 under T, below the frame title");
		const auto* e19 = &*std::find_if(p.begin(), p.end(), [](const SlotPos& q) { return q.index == 19; });
		Expect(std::abs(e19->y - e13->y - kExtPitch) < 0.5f, "bar 2 under bar 1");
	}

	// add tile and 18 slots / 4 per row
	{
		Settings s;
		s.extended = true;
		s.slotCount = 18;
		s.slotsPerRow = 4;
		s.layout = Layout::CrossBars;
		const auto p = PlaceSlots(s, 100, 500, 400, 300, 960, 540);
		int ext = 0, add = 0;
		float addx = 0, addy = 0, lastx = 0, lasty = 0;
		for (const auto& x : p) {
			if (x.index == 0) { ++add; addx = x.x; addy = x.y; }
			else if (!x.native) { ++ext; lastx = x.x; lasty = x.y; }
		}
		ExpectEqI(ext, 6, "18 slots => 6 extended");
		ExpectEqI(add, 1, "add tile when under 24");
		// 6 extended with 4 per row: row1 has 4, row2 has 2, add sits next to the 2nd of row2
		Expect(std::abs(addy - lasty) < 0.5f, "add tile on the last bar");
		Expect(addx > lastx, "add tile to the right of last slot");
	}

	// BARS layout: nothing native, all computed, 24 / 8 = 3 rows
	{
		Settings s;
		s.extended = true;
		s.slotCount = 24;
		s.slotsPerRow = 8;
		s.layout = Layout::Bars;
		const auto p = PlaceSlots(s, 0, 0, 0, 0, 960, 540);
		int native = 0;
		for (const auto& x : p) if (x.native) ++native;
		ExpectEqI(native, 0, "BARS has no native T");
		ExpectEqI(static_cast<int>(p.size()), 24, "24 computed slots");
		Expect(std::abs(p[0].y - p[7].y) < 0.5f, "first row of 8 is level");
		Expect(p[8].y > p[0].y, "second row below first");
	}

	// Extended off: only the 12 native slots
	{
		Settings s;
		const auto p = PlaceSlots(s, 0, 0, 0, 0, 960, 540);
		ExpectEqI(static_cast<int>(p.size()), 12, "off => 12");
		Expect(p[0].native && p[11].native, "all native");
	}

	// use dispatch
	{
		struct Ctx {
			bool module = true, conflict = false, blocked = false, has = true;
			int inv = 0, pow = 0, ess = 0;
			std::uint32_t last = 0;
		} ctx;
		UseHooks h;
		h.ctx = &ctx;
		h.moduleInstalled = [](void* c) { return static_cast<Ctx*>(c)->module; };
		h.conflictModFound = [](void* c) { return static_cast<Ctx*>(c)->conflict; };
		h.inputBlocked = [](void* c) { return static_cast<Ctx*>(c)->blocked; };
		h.hasItem = [](std::uint32_t, Kind, void* c) { return static_cast<Ctx*>(c)->has; };
		h.useInventory = [](std::uint32_t id, void* c) { auto* x = static_cast<Ctx*>(c); ++x->inv; x->last = id; return true; };
		h.usePower = [](std::uint32_t id, void* c) { auto* x = static_cast<Ctx*>(c); ++x->pow; x->last = id; return true; };
		h.useEssence = [](std::uint32_t id, void* c) { auto* x = static_cast<Ctx*>(c); ++x->ess; x->last = id; return true; };

		Settings s;
		s.extended = true;
		Store st;
		SetSlot(st, Assignment{13, 0x11, "", "Med", Kind::Inventory, ""});
		SetSlot(st, Assignment{14, 0x22, "", "Power", Kind::Power, ""});
		SetSlot(st, Assignment{15, 0x33, "", "Essence", Kind::Essence, ""});

		Expect(UseExtendedSlot(s, st, 13, h) == UseResult::Ok && ctx.inv == 1 && ctx.last == 0x11, "inventory use");
		Expect(UseExtendedSlot(s, st, 14, h) == UseResult::Ok && ctx.pow == 1, "power use");
		Expect(UseExtendedSlot(s, st, 15, h) == UseResult::Ok && ctx.ess == 1, "essence use");
		Expect(UseExtendedSlot(s, st, 16, h) == UseResult::Empty, "empty slot");
		s.extended = false;
		Expect(UseExtendedSlot(s, st, 13, h) == UseResult::Disabled, "disabled");
		s.extended = true;
		ctx.has = false;
		Expect(UseExtendedSlot(s, st, 13, h) == UseResult::Missing, "missing item, not auto-replaced");
		Expect(FindSlot(st, 13) && FindSlot(st, 13)->formId == 0x11, "missing keeps assignment");
		ctx.has = true;
		ctx.blocked = true;
		Expect(UseExtendedSlot(s, st, 13, h) == UseResult::Blocked, "blocked in menu");
		ctx.blocked = false;
		ctx.module = false;
		Expect(UseExtendedSlot(s, st, 13, h) == UseResult::NoModule, "no module");
		ctx.module = true;
		ctx.conflict = true;
		Expect(UseExtendedSlot(s, st, 13, h) == UseResult::Conflict, "conflict");
		ctx.conflict = false;
		s.slotCount = 13;  // 14 hidden
		Expect(UseExtendedSlot(s, st, 14, h) == UseResult::BadSlot, "hidden slot not usable");
	}

	// key binds
	{
		Settings s;
		s.extended = true;
		ApplyKey(s, 13, "f3");
		ApplyKey(s, 14, "Home");
		ExpectEqS(KeyOf(s, 13), "F3", "canon F3");
		ExpectEqI(SlotForKey(s, "F3"), 13, "F3 -> 13");
		ExpectEqI(SlotForKey(s, "home"), 14, "home -> 14");
		std::string why;
		UseHooks h;
		h.keyBoundByGame = [](std::string_view k, void*) { return k == "Q"; };
		h.ctx = nullptr;
		ApplyKey(s, 15, "F3");
		Expect(!CanBind(s, 15, "F3", h, &why), "duplicate extended key refused");
		Expect(!CanBind(s, 16, "Q", h, &why), "game bind refused");
		Expect(CanBind(s, 16, "F5", h, &why), "free key allowed");
		Expect(CanBind(s, 13, "", h, &why), "empty key allowed");
	}

	// public IDs stay pinned (so a typo in the wrapper is caught)
	Expect(kIdUseInventoryItem == 101954, "UseInventoryItem id");
	Expect(kIdUseSpell == 101916, "UseSpell id");

	// assign payload from the movie
	{
		auto a1 = ParseAssignExtra("P|Personal Atmosphere");
		Expect(a1.power, "P| prefix is a power");
		ExpectEqS(a1.name, "Personal Atmosphere", "P| name");
		auto a2 = ParseAssignExtra("I|Med Pack");
		Expect(!a2.power, "I| prefix is inventory");
		ExpectEqS(a2.name, "Med Pack", "I| name");
		Expect(a2.formId == 0, "I|name has no form ID");
		auto a3 = ParseAssignExtra("Med Pack");
		Expect(!a3.power, "bare name is inventory");
		ExpectEqS(a3.name, "Med Pack", "bare name kept");
		auto a4 = ParseAssignExtra("X|odd");
		ExpectEqS(a4.name, "X|odd", "unknown prefix kept as name");
		auto a5 = ParseAssignExtra("I|0x0002A04A|Modified Razorback");
		Expect(!a5.power && a5.formId == 0x0002A04Au && a5.name == "Modified Razorback", "I|0xFORM|name keeps the form ID and display name");
		auto a6 = ParseAssignExtra("I|0xABC|");
		Expect(a6.formId == 0xABCu && a6.name.empty(), "I|0xFORM| with an empty name still carries the form ID");
		auto a7 = ParseAssignExtra("I|Dead Drop|X");
		Expect(a7.formId == 0 && a7.name == "Dead Drop|X", "Dead Drop|X is not a form ID");
		auto a8 = ParseAssignExtra("I|0x0002A04A|h40821|Med Pack");
		Expect(a8.formId == 0x0002A04Au && a8.handle == 40821u && a8.name == "Med Pack",
			"I|0xFORM|hHANDLE|name keeps uint inventory IDs");
		auto a9 = ParseAssignExtra("I|h0xABC|Med Pack");
		Expect(a9.formId == 0 && a9.handle == 0xABCu && a9.name == "Med Pack",
			"I|h0xHANDLE|name is a handle-only hint");
		auto a10 = ParseAssignExtra("I|0x0002A04A|h40821|Med Pack\tICON\t1\tData\tIcons/med");
		Expect(a10.formId == 0x0002A04Au && a10.handle == 40821u && a10.name == "Med Pack"
			&& a10.iconType == 1 && a10.iconDir == "Data" && a10.iconName == "Icons/med",
			"ICON trailer after the name is the vanilla ImageFixture path");
		auto a11 = ParseAssignExtra("I|Med Pack");
		Expect(a11.iconType == -1 && a11.iconName.empty(), "no ICON trailer leaves icon unset");
		Expect(GfxU32(GfxScalar::Number, 0, 0, 0x0002A04Au) == 0,
			"kNumber-only read drops InventoryMenu uint IDs");
		Expect(GfxU32(GfxScalar::UInt, 0, 0, 0x0002A04Au) == 0x0002A04Au
			&& GfxU32(GfxScalar::Int, 0, 0x1234, 0) == 0x1234u,
			"kUInt/kInt are the inventory uFormID/uHandleID types");
		{
			Store st;
			Assignment a;
			a.index = 13;
			a.formId = GfxU32(GfxScalar::UInt, 0, 0, 0x0002A04Au);
			a.formHex = FormHex(a.formId);
			a.name = "Med Pack";
			a.base = "Med Pack";
			a.kind = Kind::Inventory;
			SetSlot(st, a);
			Expect(FindSlot(st, 13) && FindSlot(st, 13)->formId == 0x0002A04Au
				&& FindSlot(st, 13)->name == "Med Pack",
				"inventory-open assign to slot 13 commits and persists by FormID");
			Assignment b = a;
			b.index = 18;
			b.formId = GfxU32(GfxScalar::UInt, 0, 0, 0x0002B00Bu);
			b.formHex = FormHex(b.formId);
			b.name = "Digipick";
			b.base = "Digipick";
			SetSlot(st, b);
			Expect(FindSlot(st, 18) && FindSlot(st, 18)->formId == 0x0002B00Bu
				&& FindSlot(st, 13)->formId == 0x0002A04Au,
				"inventory-open assign to slot 18 persists without clearing 13");
		}
		{
			Settings s;
			s.extended = true;
			s.slotCount = 24;
			s.slotsPerRow = 6;
			s.layout = Layout::CrossBars;
			const auto p = PlaceSlots(s, -267.75f, 268.8f, 268.75f, 0.f, 0.f, 0.f);
			const SlotPos* lastCol = nullptr;
			for (const auto& x : p) if (x.index == 18) lastCol = &x;
			Expect(lastCol != nullptr, "CROSS+BARS slot 18 is the last column of the first extra row");
			Expect(AccentRingInside(lastCol->x, lastCol->y, -960.f, 960.f, -540.f, 540.f, kExtBox),
				"last-column extra ring stays inside the visible area");
			Expect(AccentRingInside(0.f, 0.f, -29.f, 29.f, -29.f, 29.f, kBox),
				"vanilla 58 px filled ring fits inside the 58 px card on every T slot");
			Expect(!AccentRingInside(0.f, 0.f, -28.f, 28.f, -28.f, 28.f, kBox),
				"a 56 px clip still cuts the right edge of a 58 px filled ring");
			s.slotsPerRow = 8;
			const auto p8 = PlaceSlots(s, -267.75f, 268.8f, 268.75f, 0.f, 0.f, 0.f);
			const SlotPos* last8 = nullptr;
			for (const auto& x : p8) if (x.index == 20) last8 = &x;
			Expect(last8 != nullptr, "8-per-row extra last column exists");
			Expect(!AccentRingInside(last8->x, last8->y, -267.75f, 268.8f, -400.f, 800.f, kExtBox),
				"T AABB does not contain an 8-per-row extra last-column ring (previous clip theory)");
			Expect(AccentRingInside(last8->x, last8->y, -960.f, 960.f, -540.f, 540.f, kExtBox),
				"8-per-row extra last-column ring stays inside the visible area");
			const auto inf1080 = PlaceInfoPanel(960.f, -540.f, 540.f, kInfoW, 120.f);
			Expect(inf1080.x == 960.f - kSafeM - kInfoW && inf1080.y == -60.f,
				"info panel sits at center-right on 1920x1080");
			Expect(InfoClearsLayout(inf1080, p, -267.75f, 268.8f, -267.65f, 268.75f),
				"info panel does not overlap the T or extra slots (6 per row, 1920x1080)");
			Expect(InfoClearsLayout(inf1080, p8, -267.75f, 268.8f, -267.65f, 268.75f),
				"info panel does not overlap the T or extra slots (8 per row, 1920x1080)");
			Expect(!RectsOverlap(inf1080.x, inf1080.y, inf1080.w, inf1080.h,
					960.f - kHudCardW, 540.f - kEqReserve, kHudCardW, kEqReserve),
				"center-right info does not overlap the HUD equipment card at 1920x1080");
			Expect(!RectsOverlap(inf1080.x, inf1080.y, inf1080.w, inf1080.h,
					960.f - kHudCardW, -540.f, kHudCardW, kHudQuestH),
				"center-right info does not overlap the HUD quest card at 1920x1080");
			const auto inf1440 = PlaceInfoPanel(1280.f, -720.f, 720.f, kInfoW, 120.f);
			Expect(inf1440.x == 1280.f - kSafeM - kInfoW && inf1440.y == -60.f,
				"info panel sits at center-right on 2560x1440");
			Expect(InfoClearsLayout(inf1440, p, -267.75f, 268.8f, -267.65f, 268.75f),
				"info panel does not overlap the T or extra slots (2560x1440)");
			Expect(!RectsOverlap(inf1440.x, inf1440.y, inf1440.w, inf1440.h,
					1280.f - kHudCardW, 720.f - kEqReserve, kHudCardW, kEqReserve),
				"center-right info does not overlap the HUD equipment card at 2560x1440");
			const auto infUw = PlaceInfoPanel(1720.f, -720.f, 720.f, kInfoW, 120.f);
			Expect(infUw.x == 1720.f - kSafeM - kInfoW && infUw.y == -60.f,
				"info panel sits at center-right on 3440x1440 ultrawide");
			Expect(InfoClearsLayout(infUw, p, -267.75f, 268.8f, -267.65f, 268.75f),
				"info panel does not overlap the T or extra slots (ultrawide)");
			Expect(!RectsOverlap(infUw.x, infUw.y, infUw.w, infUw.h,
					1720.f - kHudCardW, 720.f - kEqReserve, kHudCardW, kEqReserve),
				"center-right info does not overlap the HUD equipment card on ultrawide");
			{
				const float kb = 24.f;
				const auto tiny = FitExtraIcon(-10.f, -10.f, 20.f, 20.f, kb);
				Expect(tiny.scale == 1.f, "a small extra icon is never enlarged");
				const auto huge = FitExtraIcon(0.f, 0.f, 256.f, 256.f, kb);
				Expect(huge.scale < 1.f && ExtraIconInsideCard(huge, 0.f, 0.f, 256.f, 256.f, kb),
					"a 256 px extra icon is scaled into the extra card below the keychip");
				const auto wide = FitExtraIcon(0.f, 0.f, 400.f, 160.f, kb);
				Expect(wide.scale < 1.f && ExtraIconInsideCard(wide, 0.f, 0.f, 400.f, 160.f, kb),
					"a wide extra icon stays inside the padded extra card (one scale on both axes)");
				const auto again = FitExtraIcon(0.f, 0.f, 256.f, 256.f, kb);
				Expect(again.scale == huge.scale && again.x == huge.x && again.y == huge.y,
					"extra icon fit from identity does not compound");
				Expect(kIcBound == 60.f, "vanilla BoundClip_mc target is 60 x 60");
			}
		}
		Expect(IsEssenceName("Quantum Essence"), "essence name");
		Expect(!IsEssenceName("Med Pack"), "not essence");
		ExpectEqS(PayloadSafe("a|b;c"), "a/b/c", "payload separators replaced");
	}

	// 0.43.5 fix round: S-8 fallback keys, N-3 key names, S-4 request age, S-6 backoff, S-3 load-order check,
	// N-8 braces in names, N-9 memory-only merge
	{
		Expect(FallbackReservedKey("F5") && FallbackReservedKey("F9"), "S-8: F5 / F9 reserved while the control map is unreadable");
		Expect(FallbackReservedKey("F1") && FallbackReservedKey("F12") && FallbackReservedKey("W"), "S-8: every F-key and movement key reserved in the fallback");
		Expect(!FallbackReservedKey("Insert") && !FallbackReservedKey("PageDown") && !FallbackReservedKey("7"), "S-8: navigation keys and digits stay usable");
		Expect(!FallbackReservedKey("TAB") && !FallbackReservedKey("ESCAPE"), "S-8: names CanonKey never produces are gone from the list");
		Expect(!ValidKeyName("MINUS") && !ValidKeyName("LBRACKET") && ValidKeyName("PageUp"), "N-3: only key names the DLL can map are valid");

		const auto k = PackUseReq(13, 100000);
		Expect(UseReqCode(k) == 13 && UseReqFresh(k, 100000) && UseReqFresh(k, 100250), "S-4: a key press is fresh for 250 ms");
		Expect(!UseReqFresh(k, 100251) && !UseReqFresh(k, 105000), "S-4: an older key press is dropped");
		const auto m = PackUseReq(14 | kReqFromMenu, 100000);
		Expect((UseReqCode(m) & 0xFF) == 14 && (UseReqCode(m) & kReqFromMenu) && UseReqFresh(m, 101900) && !UseReqFresh(m, 102001), "S-4: a menu click gets 2 s");
		Expect(!UseReqFresh(0, 5), "S-4: no request");

		ExpectEqI(static_cast<int>(NextWriteBackoffMs(0)), 2000, "S-6: first retry after 2 s");
		ExpectEqI(static_cast<int>(NextWriteBackoffMs(2000)), 4000, "S-6: doubles");
		ExpectEqI(static_cast<int>(NextWriteBackoffMs(16000)), 30000, "S-6: capped at 30 s");
		ExpectEqI(static_cast<int>(NextWriteBackoffMs(30000)), 30000, "S-6: stays at 30 s");

		Assignment a;
		a.index = 13; a.formId = 0x1234; a.name = "Med Pack"; a.base = "Med Pack"; a.kind = Kind::Inventory;
		Expect(!AssignmentStale(a, "med pack", true), "S-3: same item (case-insensitive) is not stale");
		Expect(AssignmentStale(a, "Frag Grenade", true) && !AssignmentClears(a, "Frag Grenade", true), "S-B: a name-only mismatch is refused, not cleared");
		Expect(AssignmentStale(a, "Med Pack", false) && AssignmentClears(a, "Med Pack", false), "S-B: no longer an inventory object is refused and cleared");
		Expect(!AssignmentStale(a, "", true) && !AssignmentClears(a, "", true), "S-B: an unreadable (empty) name is unknown, not stale");
		Expect(AssignmentCheck(a, "Frag Grenade", true) == SlotCheck::Refuse && AssignmentCheck(a, "Med Pack", false) == SlotCheck::Clear && AssignmentCheck(a, "", true) == SlotCheck::Ok, "S-B: AssignmentCheck distinguishes refuse vs clear vs ok");
		Assignment b = a; b.base.clear(); b.name = "Advanced Grendel";
		Expect(!AssignmentStale(b, "Advanced Grendel", true) && !AssignmentStale(b, "Grendel", true) && !AssignmentClears(b, "Grendel", true), "instance prefix matches the base name and is not refused");
		Expect(AssignmentCheck(b, "Frag Grenade", true) == SlotCheck::Refuse, "a different item is still refused");
		Assignment inst = a; inst.base = "Razorback"; inst.name = "Modified Razorback";
		Expect(!AssignmentStale(inst, "Razorback", true) && !AssignmentStale(inst, "Modified Razorback", true) && !AssignmentClears(inst, "Razorback", true), "instance display vs TESFullName is the same item");
		Expect(NamesMatch("Modified Razorback", "Razorback") && NamesMatch("Razorback", "modified razorback"), "NamesMatch: instance prefix, case-insensitive");
		Expect(KeepPendingForAssigned("Med Pack", "Med Pack") && KeepPendingForAssigned("Modified Razorback", "Razorback"),
			"pending A matches AssignedItem A");
		Expect(!KeepPendingForAssigned("Med Pack", "Razorback") && !KeepPendingForAssigned("Item A", "Item B"),
			"pending A does not keep when AssignedItem is B");
		Expect(KeepPendingForAssigned("", "Med Pack") && KeepPendingForAssigned("Med Pack", "") && KeepPendingForAssigned("", ""),
			"empty pending or AssignedItem name cannot cross-check (ordinary open relies on ClearPending)");

		Expect(ParseFormId("0x0002A04A") == 0x0002A04Au && ParseFormId("0xABC") == 0xABCu && ParseFormId("0X2a") == 0x2Au, "ParseFormId: 0x + 1-8 hex digits");
		Expect(ParseFormId("Dead Drop") == 0 && ParseFormId("Dead Drop|X") == 0 && ParseFormId("2A04A") == 0, "ParseFormId: no 0x prefix is not a form ID");
		Expect(ParseFormId("#2A04A") == 0 && ParseFormId("0x") == 0 && ParseFormId("0x123456789") == 0, "ParseFormId: hash, empty, and 9 hex digits refuse");
		Expect(ParseFormId("0x-1") == 0 && ParseFormId("0x2A04Axyz") == 0 && ParseFormId("  0xFF  ") == 0xFFu, "ParseFormId: no minus, fully consumed, trim");
		Expect(AssignIdMatchesName("Modified Razorback", "Razorback") && AssignIdMatchesName("", "Razorback"), "AssignIdMatchesName: instance prefix and ID-only extra");
		Expect(!AssignIdMatchesName("Med Pack", "Frag Grenade") && !AssignIdMatchesName("Razorback", "") && !AssignIdMatchesName("Med Pack", "Pack"), "AssignIdMatchesName: wrong item, empty lookup, short suffix");
		{
			const NameId rows[] = {
				{ "Heavy Modified Razorback", 1 },
				{ "Razorback", 2 },
				{ "Modified Razorback", 3 }
			};
			Expect(PickFormByDisplayName("Razorback", rows, 3) == 2, "PickFormByDisplayName: exact Razorback, not Heavy Modified Razorback");
			Expect(PickFormByDisplayName("razorback", rows, 3) == 2, "PickFormByDisplayName: case-insensitive exact");
			const NameId noExact[] = {
				{ "Heavy Modified Razorback", 1 },
				{ "Modified Razorback", 3 }
			};
			Expect(PickFormByDisplayName("Razorback", noExact, 2) == 3, "PickFormByDisplayName: shortest prefix, never the longest");
			Expect(PickFormByDisplayName("No Such Gun", rows, 3) == 0, "PickFormByDisplayName: missing");
		}
		Expect(!NamesMatch("Med Pack", "Pack") && !NamesMatch("Pack", "Med Pack"), "NamesMatch: a short suffix is not the same item");
		Expect(!NamesMatch("", "Razorback") && !NamesMatch("Razorback", ""), "NamesMatch: empty is not a match");
		Assignment c = a; c.base.clear(); c.name.clear();
		Expect(!AssignmentStale(c, "Anything", true), "S-3: nothing stored to compare: not stale");

		Settings s; s.extended = true; s.slotCount = 24;
		Store st; SetSlot(st, a);
		UseHooks h;
		h.formStale = [](const Assignment&, void*) { return true; };
		h.useInventory = [](std::uint32_t, void*) { return true; };
		Expect(UseExtendedSlot(s, st, 13, h) == UseResult::Stale, "S-3: a stale slot is refused, never used");
		ExpectEqS(ResultName(UseResult::Stale), "stale (item changed after a load-order change)", "S-3: result name");

		Store w; w.character = hzlog::MakeCharacter(0x1234, "Tester");
		Assignment d = a; d.name = "Odd } name {x}"; d.base = "Odd } name {x}";
		SetSlot(w, d);
		Assignment e = a; e.index = 14; e.formId = 0x99; e.formHex.clear(); e.name = "Second"; e.base = "Second";
		SetSlot(w, e);
		const auto back = ParseStore(WriteStore(w));
		Expect(back.slots.size() == 2, "N-8: a name with braces does not cut the slot list");
		const auto* b13 = FindSlot(back, 13);
		Expect(b13 && b13->name == "Odd } name {x}" && b13->base == "Odd } name {x}" && b13->formId == 0x1234, "N-8 / S-3: name and base name round-trip");
		const auto* b14 = FindSlot(back, 14);
		Expect(b14 && b14->formId == 0x99 && b14->name == "Second", "N-8: the next slot parses");

		Store file; Assignment f = a; f.index = 13; f.name = "From File"; SetSlot(file, f);
		Store mem; Assignment g1 = a; g1.index = 13; g1.name = "Mem 13"; SetSlot(mem, g1);
		Assignment g2 = a; g2.index = 15; g2.name = "Mem 15"; SetSlot(mem, g2);
		Expect(MergeMemorySlots(file, mem), "N-9: a memory-only slot is merged");
		Expect(FindSlot(file, 13)->name == "From File" && FindSlot(file, 15) && FindSlot(file, 15)->name == "Mem 15", "N-9: file slots win, empty slots take memory entries");
		Expect(!MergeMemorySlots(file, mem), "N-9: nothing new the second time");

		// S-A / S-D: a second character in the same session must not inherit the first character's slots
		{
			Store bound;
			bound.character = hzlog::MakeCharacter(0xA, "A");
			Assignment sa = a; sa.index = 13; sa.name = "From A"; sa.base = "From A";
			SetSlot(bound, sa);
			Expect(MustParkBoundStore(bound), "S-D: a bound store is parked when the player ID is not yet known");
			Store parked = bound;
			hzqs::ResetToUnknownCharacter(bound, hzlog::MakeCharacter(0, "Loading"));
			Expect(!CanWriteStore(bound.character) && !FindSlot(bound, 13),
				"S-D: the live store starts empty and memory-only");
			Expect(CanWriteStore(parked.character) && FindSlot(parked, 13) && FindSlot(parked, 13)->name == "From A",
				"S-D: A's slots stay in the parked copy for a final write");
			Expect(!ShouldMergeMemorySlots(parked), "S-A: the parked bound store is not merged into the next character's file");
			Store bFile; bFile.character = hzlog::MakeCharacter(0xB, "B");
			Expect(!ShouldMergeMemorySlots(parked), "S-A: load of B does not merge A's slots (gate is off)");
			// if the gate were skipped, Merge would copy A into B; pin that the helper would copy, so the gate matters
			Store bCopy = bFile;
			Expect(MergeMemorySlots(bCopy, parked) && FindSlot(bCopy, 13), "S-A: without the gate, A's slots would land in B (the helper itself still merges)");

			Store memOnly;
			memOnly.character = hzlog::MakeCharacter(0, "Unknown");
			Assignment sm = a; sm.index = 15; sm.name = "Mem only"; sm.base = "Mem only";
			SetSlot(memOnly, sm);
			Expect(ShouldMergeMemorySlots(memOnly), "S-A: memory-only assignments do merge once the ID is known");
			Expect(!MustParkBoundStore(memOnly), "S-D: an already memory-only store is not parked");
			ApplyUnknownCharacter(memOnly, hzlog::MakeCharacter(0, "Still unknown"));
			Expect(ShouldMergeMemorySlots(memOnly) && FindSlot(memOnly, 15) && FindSlot(memOnly, 15)->name == "Mem only",
				"S-A: already memory-only slots are kept across another unknown-ID event");
			Expect(MustFlushBeforeLoad(parked.character, bFile.character),
				"N-g: a load of B must flush A's bound store first");
			Expect(!MustFlushBeforeLoad(bound.character, bFile.character),
				"N-g: a memory-only store has nothing to flush before B's load");
		}

		// S-D: bound A, unknown ID, a slot assigned in the window, then load B:
		// A's file is unchanged and B's file gets the window assignment.
		{
			const auto dir = HzTestScratch("hzqs_sd_");
			Store aStore;
			aStore.character = hzlog::MakeCharacter(0xA, "A");
			Assignment sa = a; sa.index = 13; sa.name = "From A"; sa.base = "From A"; sa.formId = 0x11; sa.formHex = "0x11";
			SetSlot(aStore, sa);
			Expect(WriteStoreFile(dir, aStore), "S-D: write A's file");
			Expect(MustParkBoundStore(aStore), "S-D: A is parked");
			Store parked = aStore;
			Store live = aStore;
			ResetToUnknownCharacter(live, hzlog::MakeCharacter(0, "Loading"));
			Assignment sb = a; sb.index = 14; sb.name = "From B window"; sb.base = "From B window"; sb.formId = 0x22; sb.formHex = "0x22";
			SetSlot(live, sb);
			Expect(ShouldMergeMemorySlots(live) && FindSlot(live, 14) && !FindSlot(live, 13),
				"S-D: the window assignment is memory-only and A's slots are gone from the live store");
			// A's pending write (if dirty) would use the parked copy; here A is already on disk.
			Expect(WriteStoreFile(dir, parked), "S-D: parked A can be written");
			Store bFile;
			bFile.character = hzlog::MakeCharacter(0xB, "B");
			Expect(MergeMemorySlots(bFile, live), "S-D: the window assignment merges into B");
			bFile.character = hzlog::MakeCharacter(0xB, "B");
			Expect(WriteStoreFile(dir, bFile), "S-D: write B's file");
			const auto aDisk = ReadStoreFile(dir, aStore.character.key);
			const auto bDisk = ReadStoreFile(dir, bFile.character.key);
			Expect(FindSlot(aDisk, 13) && FindSlot(aDisk, 13)->name == "From A" && !FindSlot(aDisk, 14),
				"S-D: A's file is unchanged and does not contain B's window assignment");
			Expect(FindSlot(bDisk, 14) && FindSlot(bDisk, 14)->name == "From B window" && !FindSlot(bDisk, 13),
				"S-D: B's file contains the window assignment and not A's slots");
		}

		// S-F: parked-store model (one entry per character, cleared by generation).
		// Mirrors QmFlushStore / QmLoadStoreFor so the four write-failure interleavings
		// and the unknown-ID-during-read case are checked in this unit test.
		{
			struct Model
			{
				ParkedSet             parked;
				Store                 live;
				bool                  liveDirty = false;
				bool                  loadReq = false;
				std::uint64_t         loadGen = 0;
				hzlog::Character      loadChar{};
				std::filesystem::path dir;
				int                   failLeft = 0;
				std::uint64_t         ignoreBackoffUntilGen = 0;

				void Bind(const hzlog::Character& a_ch) { live.character = a_ch; }

				void Assign(int a_index, const char* a_name, std::uint32_t a_id)
				{
					Assignment s;
					s.index = a_index;
					s.formId = a_id;
					s.formHex = "0x" + std::to_string(a_id);
					s.name = a_name;
					s.base = a_name;
					s.kind = Kind::Inventory;
					SetSlot(live, s);
					liveDirty = true;
				}

				bool Write(const Store& a_st)
				{
					if (failLeft > 0) { --failLeft; return false; }
					return WriteStoreFile(dir, a_st);
				}

				void AbsorbLive()
				{
					if (liveDirty && CanWriteStore(live.character)) {
						parked.Park(live);
						liveDirty = false;
					}
				}

				void UnknownId(const hzlog::Character& a_ch)
				{
					if (MustParkBoundStore(live) && liveDirty) {
						parked.Park(live);
						liveDirty = false;
					}
					if (MustParkBoundStore(live) || !CanWriteStore(live.character))
						ResetToUnknownCharacter(live, a_ch);
					else
						ApplyUnknownCharacter(live, a_ch);
					loadReq = false;
					++loadGen;
				}

				void RequestLoad(const hzlog::Character& a_ch)
				{
					if (liveDirty && MustFlushBeforeLoad(live.character, a_ch)) {
						ignoreBackoffUntilGen = parked.Park(live);
						liveDirty = false;
					} else {
						AbsorbLive();
					}
					loadChar = a_ch;
					++loadGen;
					loadReq = true;
				}

				void FlushWrites()
				{
					AbsorbLive();
					auto pending = parked.Pending();
					for (const auto& item : pending) {
						if (!parked.ShouldWrite(item.store.character.key, item.gen)) continue;
						if (!CanWriteStore(item.store.character)) {
							parked.ClearGen(item.store.character.key, item.gen);
							continue;
						}
						if (Write(item.store))
							parked.ClearGen(item.store.character.key, item.gen);
						else {
							parked.ReparkFailed(item.store, item.gen);
							break;
						}
					}
				}

				void ApplyLoad()
				{
					if (!loadReq) return;
					const auto ch = loadChar;
					const auto gen = loadGen;
					auto st = ReadStoreFile(dir, ch.key);
					st.character = ch;
					if (!ShouldApplyLoad(ch, gen, loadChar, loadGen, loadReq)) return;
					parked.OverlayFile(st, ch);
					if (ShouldMergeMemorySlots(live)) MergeMemorySlots(st, live);
					live = std::move(st);
					loadReq = false;
					if (ShouldMergeMemorySlots(live) && CanWriteStore(live.character)) {
						// merge already applied; nothing memory-only remains
					}
				}

				Store FileOf(const hzlog::Character& a_ch) const { return ReadStoreFile(dir, a_ch.key); }
			};

			const auto chA = hzlog::MakeCharacter(0xA, "A");
			const auto chB = hzlog::MakeCharacter(0xB, "B");
			const auto unknown = hzlog::MakeCharacter(0, "Loading");

			// 1. Success: normal A -> unknown -> B
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf1_");
				m.Bind(chA);
				m.Assign(13, "From A", 0x11);
				m.UnknownId(unknown);
				m.FlushWrites();
				m.RequestLoad(chB);
				m.ApplyLoad();
				Expect(!FindSlot(m.live, 13) && m.parked.Pending().empty() && FindSlot(m.FileOf(chA), 13) && FindSlot(m.FileOf(chA), 13)->name == "From A",
					"S-F 1: a normal A-to-B switch writes A and leaves B empty");
			}

			// 2. Success: switch during backoff (A's write failed once, B is requested, A is retried)
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf2_");
				m.Bind(chA);
				m.Assign(13, "From A", 0x11);
				m.failLeft = 1;
				m.FlushWrites();
				Expect(m.parked.Find(chA.key) != nullptr, "S-F 2: a failed write stays parked");
				m.RequestLoad(chB);
				m.failLeft = 0;
				m.FlushWrites();
				m.ApplyLoad();
				Expect(FindSlot(m.FileOf(chA), 13) && FindSlot(m.FileOf(chA), 13)->name == "From A" && !FindSlot(m.live, 13) && m.parked.Pending().empty(),
					"S-F 2: a switch during backoff still writes A, then loads B");
			}

			// 3. Success: quick A -> B -> A
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf3_");
				m.Bind(chA);
				m.Assign(13, "From A", 0x11);
				m.RequestLoad(chB);
				m.FlushWrites();
				m.ApplyLoad();
				m.Bind(chB);
				m.Assign(14, "From B", 0x22);
				m.RequestLoad(chA);
				m.FlushWrites();
				m.ApplyLoad();
				Expect(FindSlot(m.live, 13) && FindSlot(m.live, 13)->name == "From A" && !FindSlot(m.live, 14)
					&& FindSlot(m.FileOf(chA), 13) && FindSlot(m.FileOf(chB), 14) && m.parked.Pending().empty(),
					"S-F 3: a quick A-to-B-to-A switch keeps each character's slots in that character's file");
			}

			// 4. Failure: a second outgoing store is not dropped while the first is pending
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf4_");
				m.Bind(chA);
				m.Assign(13, "From A", 0x11);
				m.failLeft = 2;  // first flush fails A; B is then parked beside it
				m.FlushWrites();
				m.RequestLoad(chB);
				m.ApplyLoad();
				m.Bind(chB);
				m.Assign(14, "From B", 0x22);
				m.FlushWrites();  // still failing: B is parked, A stays parked
				Expect(m.parked.Find(chA.key) && m.parked.Find(chB.key),
					"S-F 4: both characters stay parked while writes fail");
				m.failLeft = 0;
				m.FlushWrites();
				Expect(FindSlot(m.FileOf(chA), 13) && FindSlot(m.FileOf(chA), 13)->name == "From A"
					&& FindSlot(m.FileOf(chB), 14) && FindSlot(m.FileOf(chB), 14)->name == "From B"
					&& m.parked.Pending().empty(),
					"S-F 4: both pending stores are written once writes succeed");
			}

			// 5. Failure: reloading A uses the parked copy, not the stale file; an older in-flight write cannot overwrite newer data
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf5_");
				m.Bind(chA);
				m.Assign(13, "A v1", 0x11);
				m.FlushWrites();
				m.Assign(13, "A v2", 0x11);
				const auto gen1 = m.parked.Park(m.live);
				m.liveDirty = false;
				const auto snapV2 = m.parked.Find(chA.key)->store;
				m.Assign(13, "A v3", 0x11);
				m.AbsorbLive();  // gen2 = v3
				Expect(m.parked.Find(chA.key) && m.parked.Find(chA.key)->gen != gen1,
					"S-F 5: a later park is a new generation");
				// The stale in-flight snap (v2) must not write or clear v3.
				Expect(!m.parked.ShouldWrite(chA.key, gen1), "S-F 5: an older generation is no longer writable");
				m.parked.ReparkFailed(snapV2, gen1);
				Expect(m.parked.Find(chA.key) && FindSlot(m.parked.Find(chA.key)->store, 13)->name == "A v3",
					"S-F 5: ReparkFailed leaves a newer generation in place");
				m.RequestLoad(chA);
				m.ApplyLoad();
				Expect(FindSlot(m.live, 13) && FindSlot(m.live, 13)->name == "A v3",
					"S-F 5: a reload of A uses the parked v3 copy, not the stale v1 file");
				m.FlushWrites();
				Expect(FindSlot(m.FileOf(chA), 13) && FindSlot(m.FileOf(chA), 13)->name == "A v3" && m.parked.Pending().empty(),
					"S-F 5: the file ends as v3; the older snap never overwrites it");
			}

			// 6. Failure: a same-character re-park is not cleared when an older write succeeds
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf6_");
				m.Bind(chA);
				m.Assign(13, "A v1", 0x11);
				m.AbsorbLive();
				const auto gen1 = m.parked.Find(chA.key)->gen;
				const auto snapV1 = m.parked.Find(chA.key)->store;
				m.Assign(13, "A v2", 0x11);
				m.AbsorbLive();
				const auto gen2 = m.parked.Find(chA.key)->gen;
				Expect(gen2 != gen1, "S-F 6: re-parking A is a new generation");
				// The older snap writes successfully; only gen1 is cleared.
				Expect(WriteStoreFile(m.dir, snapV1), "S-F 6: the older snap writes");
				m.parked.ClearGen(chA.key, gen1);
				Expect(m.parked.Find(chA.key) && m.parked.Find(chA.key)->gen == gen2
					&& FindSlot(m.parked.Find(chA.key)->store, 13)->name == "A v2",
					"S-F 6: clearing the older generation leaves the unwritten re-park in place");
				m.FlushWrites();
				Expect(FindSlot(m.FileOf(chA), 13) && FindSlot(m.FileOf(chA), 13)->name == "A v2" && m.parked.Pending().empty(),
					"S-F 6: the re-parked v2 is written after the older snap");
			}

			// 7. Failure: a failed write is re-parked, not orphaned when the live store is reset
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf7_");
				m.Bind(chA);
				m.Assign(13, "From A", 0x11);
				m.failLeft = 1;
				m.FlushWrites();
				m.UnknownId(unknown);
				Expect(m.parked.Find(chA.key) && FindSlot(m.parked.Find(chA.key)->store, 13)
					&& !FindSlot(m.live, 13) && !m.liveDirty,
					"S-F 7: after a failed write and an unknown-ID reset, A stays parked and the live store is not re-dirtied");
				m.failLeft = 0;
				m.FlushWrites();
				Expect(FindSlot(m.FileOf(chA), 13) && FindSlot(m.FileOf(chA), 13)->name == "From A" && m.parked.Pending().empty(),
					"S-F 7: the re-parked write is not orphaned; A's file is written after the reset");
			}

			// 8. Nit: an unknown-ID event during B's file read discards the in-flight apply
			{
				Model m;
				m.dir = HzTestScratch("hzqs_sf8_");
				Store seed;
				seed.character = chB;
				Assignment sb;
				sb.index = 14; sb.formId = 0x22; sb.formHex = "0x22"; sb.name = "From B"; sb.base = "From B"; sb.kind = Kind::Inventory;
				SetSlot(seed, sb);
				Expect(WriteStoreFile(m.dir, seed), "S-F 8: seed B's file");
				m.Bind(chA);
				m.Assign(13, "From A", 0x11);
				m.RequestLoad(chB);
				m.FlushWrites();
				// Capture the in-flight read, then an unknown ID supersedes it.
				auto stale = ReadStoreFile(m.dir, chB.key);
				stale.character = chB;
				const auto staleGen = m.loadGen;
				const auto staleCh = m.loadChar;
				m.UnknownId(unknown);
				Expect(!ShouldApplyLoad(staleCh, staleGen, m.loadChar, m.loadGen, m.loadReq),
					"S-F 8: ShouldApplyLoad rejects a load that an unknown-ID event superseded");
				if (ShouldApplyLoad(staleCh, staleGen, m.loadChar, m.loadGen, m.loadReq)) {
					m.parked.OverlayFile(stale, staleCh);
					m.live = std::move(stale);
				}
				Expect(!FindSlot(m.live, 13) && !FindSlot(m.live, 14) && !CanWriteStore(m.live.character),
					"S-F 8: the live store stays empty and memory-only; B's file is not applied");
			}

			// Direct API pins used by the model
			{
				ParkedSet set;
				Store aStore;
				aStore.character = chA;
				Assignment sa;
				sa.index = 13; sa.formId = 0x11; sa.formHex = "0x11"; sa.name = "A"; sa.base = "A"; sa.kind = Kind::Inventory;
				SetSlot(aStore, sa);
				const auto g1 = set.Park(aStore);
				Store a2 = aStore;
				FindSlot(a2, 13)->name = "A2";
				FindSlot(a2, 13)->base = "A2";
				const auto g2 = set.Park(a2);
				Expect(g1 && g2 && g2 != g1 && set.ShouldWrite(chA.key, g2) && !set.ShouldWrite(chA.key, g1),
					"S-F: ShouldWrite is true only for the latest generation of a character");
				Store file;
				file.character = chA;
				Expect(set.OverlayFile(file, chA) && FindSlot(file, 13)->name == "A2",
					"S-F: OverlayFile replaces a stale file with the parked copy");
				Expect(set.ReparkFailed(aStore, g1) == g2 && FindSlot(set.Find(chA.key)->store, 13)->name == "A2",
					"S-F: ReparkFailed does not clobber a newer generation");
			}
		}
	}

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "quickslots_test ok\n";
	return 0;
}
