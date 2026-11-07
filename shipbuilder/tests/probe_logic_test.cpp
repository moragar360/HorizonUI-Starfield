// Purpose: check the probe's read-only rules without the game.
// Author: Moragar. Last modified: 2026-11-07.

#include "hsb_arrange.h"
#include "hsb_card.h"
#include "hsb_face.h"
#include "hsb_guard.h"
#include "hsb_interior.h"
#include "hsb_version.h"

#include <algorithm>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

static int g_fails = 0;

static void Expect(bool ok, const char* text)
{
	if (ok) return;
	std::cerr << "FAIL: " << text << "\n";
	++g_fails;
}

// Allowlist checks are string checks. The prefix is the process temp directory
// so the fixture is not a profile path.
static std::string DocsTail(char sep)
{
	std::string out = fs::temp_directory_path().string();
	if (out.empty() || (out.back() != '/' && out.back() != '\\')) out.push_back(sep);
	out += "My Games";
	out.push_back(sep);
	out += "Starfield";
	out.push_back(sep);
	return out;
}

static void CheckArrangeLifecycle()
{
	hsb::ArrangePanel hidden[] = {
		{"Power", false, {100, 40, 350, 240}},
		{"Module", true, {100, 300, 350, 200}},
		{"Credits", true, {900, 40, 363, 102}},
		{"Browser", true, {1200, 40, 500, 600}},
		{"Stats", false, {400, 900, 800, 96}},
		{"Hints", true, {700, 840, 744, 48}},
		{"Cluster", true, {40, 8, 190, 40}},
	};
	const int sel = hsb::ArrangeDefault(hidden, 7);
	Expect(sel == 1 && hidden[sel].id == "Module", "default handle is the first live panel");
	Expect(hsb::ArrangeHit(hidden, 7, 120, 80) < 0, "a hidden power box is not a hit");
	Expect(hsb::ArrangeHit(hidden, 7, 950, 60) < 0, "credits are not a handle");
	Expect(hsb::ArrangeHit(hidden, 7, 760, 860) < 0, "the button bar is not a handle");
	const int mod = hsb::ArrangeHit(hidden, 7, 150, 340);
	Expect(mod == 1, "a click hits the live module");
	int next = hsb::ArrangeCycle(hidden, 7, mod, 1);
	Expect(next >= 0 && hidden[next].id == "Browser", "cycle skips credits");
	next = hsb::ArrangeCycle(hidden, 7, next, 1);
	Expect(next >= 0 && hidden[next].id == "Cluster", "cycle skips hidden stats and the button bar");
	next = hsb::ArrangeCycle(hidden, 7, next, 1);
	Expect(next == 1, "cycle wraps to the first live handle");
	Expect(hsb::ArrangeCycle(hidden, 7, -1, 1) == 1, "an invalid selection lands on the first live handle");
	const int powerX = hidden[0].bounds.x;
	Expect(!hsb::ArrangeTryMove(hidden[0], 15, 0, 0, 0, 0, 0, 1920, 1080), "a hidden panel does not move");
	Expect(hidden[0].bounds.x == powerX, "a rejected move leaves the native box");
	Expect(hsb::ArrangeTryMove(hidden[1], 15, 0, 0, 0, 0, 0, 1920, 1080), "a live panel moves in place");
	Expect(hidden[1].bounds.x == 120, "the native box snaps with the drag");
	const hsb::ArrangeBox frame = hsb::ArrangeFrame(hidden[1].bounds, 8);
	Expect(frame.x == hidden[1].bounds.x - 8 && frame.y == hidden[1].bounds.y - 8, "the frame follows the native box");

	hsb::ArrangePanel onlyGear[] = {
		{"Power", false, {100, 40, 350, 240}},
		{"Module", false, {100, 300, 350, 200}},
		{"Credits", true, {900, 40, 363, 102}},
		{"Browser", false, {1200, 40, 500, 600}},
		{"Stats", false, {400, 900, 800, 96}},
		{"Hints", true, {700, 840, 744, 48}},
		{"Cluster", true, {40, 8, 190, 40}},
	};
	Expect(hsb::ArrangeDefault(onlyGear, 7) == 6, "the gear is the handle when builder panels are hidden");

	hsb::ArrangePanel powerLive[] = {
		{"Power", true, {80, 40, 350, 240}},
		{"Module", true, {80, 300, 350, 200}},
		{"Credits", false, {0, 0, 0, 0}},
		{"Browser", false, {0, 0, 0, 0}},
		{"Stats", false, {0, 0, 0, 0}},
		{"Hints", false, {0, 0, 0, 0}},
		{"Cluster", true, {40, 8, 190, 40}},
	};
	Expect(hsb::ArrangeDefault(powerLive, 7) == 0, "a live power panel can be the default");
	Expect(hsb::ArrangeHit(powerLive, 7, 100, 60) == 0, "a live power panel can be hit");
}

static void CheckInteriorLifecycle()
{
	hsb::InteriorChild entries{"ModuleEntries_mc", true, 12, 0, 0.1f, 0.9f, 0.8f};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Browser, entries) == hsb::FadeKind::None, "the parts list is not faded");
	hsb::InteriorChild categories{"ModulePaletteCategories_mc", true, 6, 0, 0, 0.9f, 0.12f};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Browser, categories) == hsb::FadeKind::None, "category tabs are not faded");
	hsb::InteriorChild pips{"PowerPips_mc", false, 6, 0, 0, 0.9f, 0.8f};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Power, pips) == hsb::FadeKind::None, "power pips are not faded");
	hsb::InteriorChild powerShape{"", false, 0, 0, 0, 0.9f, 0.8f};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Power, powerShape) == hsb::FadeKind::None, "a power graphic is not covered by a size guess");
	Expect(!hsb::MayCoverWithPlate(hsb::InteriorPanel::Power), "power does not get an opaque plate");
	Expect(hsb::MayCoverWithPlate(hsb::InteriorPanel::Browser), "the parts browser can take a plate");
	hsb::InteriorChild background{"Background_mc", false, 0, 0, 0, 0.95f, 0.9f, false, false, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Module, background) == hsb::FadeKind::Backdrop, "a decorative background shape can be faded");
	hsb::InteriorChild holder{"ContentBackground_mc", false, 0, 0, 0, 0.95f, 0.9f, true, false, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Module, holder) == hsb::FadeKind::None, "an empty container is not faded");
	hsb::InteriorChild textBack{"Background_mc", true, 2, 0, 0, 0.9f, 0.9f, true, false, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Stats, textBack) == hsb::FadeKind::None, "a background that holds text stays");
	hsb::InteriorChild logoClip{"ManufacturerLogo_mc", false, 4, 0.1f, 0.05f, 0.4f, 0.25f, true, false, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Module, logoClip) == hsb::FadeKind::None, "a logo container is not faded");
	hsb::InteriorChild logoLeaf{"Logo_mc", false, 0, 0.1f, 0.05f, 0.4f, 0.25f, false, false, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Module, logoLeaf) == hsb::FadeKind::Logo, "a logo shape can be faded");
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Browser, logoLeaf) == hsb::FadeKind::None, "a logo shape is not faded on the parts list");
	hsb::InteriorChild wordmark{"", false, 0, 0.12f, 0.08f, 0.5f, 0.28f, false, false, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Module, wordmark) == hsb::FadeKind::None, "an unnamed shape is not treated as a logo");
	hsb::InteriorChild mask{"Background_mc", false, 0, 0, 0, 0.9f, 0.9f, false, true, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Browser, mask) == hsb::FadeKind::None, "a mask is not faded");
	hsb::InteriorChild namedMask{"BackgroundMask_mc", false, 0, 0, 0, 0.9f, 0.9f, false, false, false};
	Expect(hsb::IsProtectedName(namedMask.name), "a mask name is protected without a live link");
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Browser, namedMask) == hsb::FadeKind::None, "a mask-named shape is not faded");
	Expect(hsb::DecideFade(true, hsb::InteriorPanel::Browser, namedMask) == hsb::FadeAction::Restore, "a faded mask name is restored");
	hsb::InteriorChild hitName{"HitArea_mc", false, 0, 0, 0, 0.2f, 0.2f, false, false, false};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Module, hitName) == hsb::FadeKind::None, "a hit-area name is not faded");
	Expect(hsb::IsProtectedName("Hotspot_mc"), "a hotspot name is protected");
	Expect(!hsb::IsProtectedName("Background_mc"), "a plain background name can still fade");
	Expect(!hsb::IsProtectedName("White_mc"), "hit is not matched inside an unrelated word");
	hsb::InteriorChild hit{"Background_mc", false, 0, 0, 0, 0.4f, 0.4f, false, false, true};
	Expect(hsb::ClassifyFade(hsb::InteriorPanel::Power, hit) == hsb::FadeKind::None, "a hit target is not faded");
	hsb::InteriorChild emptyHost{"", false, 0, 0, 0, 0.2f, 0.2f, true, false, false};
	Expect(hsb::DecideFade(false, hsb::InteriorPanel::Browser, emptyHost) == hsb::FadeAction::Leave, "an empty row host is left alone");
	hsb::InteriorChild populated = emptyHost;
	populated.hasText = true;
	populated.childCount = 4;
	Expect(hsb::DecideFade(true, hsb::InteriorPanel::Browser, populated) == hsb::FadeAction::Restore, "a host that gains rows is restored");
	Expect(hsb::DecideFade(false, hsb::InteriorPanel::Module, background) == hsb::FadeAction::Fade, "a decorative shape can fade");
	hsb::InteriorChild grew = background;
	grew.canHoldContent = true;
	grew.childCount = 2;
	grew.hasText = true;
	Expect(hsb::DecideFade(true, hsb::InteriorPanel::Module, grew) == hsb::FadeAction::Restore, "a shape that later holds text is restored");
	Expect(!hsb::MayInsertInsideClip(), "the plate is not inserted into the game clip");
	Expect(!hsb::MayRemoveChild("ModuleEntries_mc"), "game rows are not removed");
	Expect(hsb::MayRemoveChild("HsbPlate"), "only our plate may be removed");

	const hsb::TextStyle selected = hsb::StyleText(0x1A1A1A, "RowText");
	Expect(selected.color == 0x1A1A1A && selected.keepFace && selected.keepEmbed, "selected row text keeps its dark color and face");
	const hsb::TextStyle row = hsb::StyleText(0xC5D0DC, "RowText");
	Expect(row.color == hsb::kOffwhite && row.keepFace && row.keepEmbed, "a light row shifts to offwhite without a new face");
	const hsb::TextStyle tab = hsb::StyleText(0xD8DEE6, "CategoryTab");
	Expect(tab.color == hsb::kGold && tab.keepEmbed, "a category label can go gold");
	const hsb::TextStyle fresh = hsb::StyleText(0xB7C3CE, "RowText");
	Expect(fresh.color == hsb::kOffwhite && selected.color == 0x1A1A1A, "a new category row is recolored and the selection stays dark");

	Expect(hsb::HeadingPx(false) >= 13 && hsb::HeadingPx(true) >= 16, "section headings meet the size floor");
	Expect(hsb::TitlePx(false) >= 13 && hsb::TitlePx(true) >= 16, "the title meets the size floor");
	Expect(!hsb::ShowBuilderTitle(false) && hsb::ShowBuilderTitle(true), "the title pill waits for the parts builder");
	Expect(!hsb::MayMoveModuleFields(), "the game card's fields stay where the menu put them");
}

static void CheckModuleCard()
{
	const hsb::CardMetrics normal = hsb::CardSize(false);
	const hsb::CardMetrics large = hsb::CardSize(true);
	Expect(normal.width == 350 && normal.pad == 18, "the normal card is mock 1 at 1920 wide");
	Expect(large.width == 410 && large.pad == 20, "the large card is wider for the large movie");
	Expect(hsb::CardSmallestPx(normal) >= hsb::TextFloorPx(false), "normal card text is 13 px or more");
	Expect(hsb::CardSmallestPx(large) >= hsb::TextFloorPx(true), "large card text is 16 px or more");
	Expect(normal.headPx == 13 && large.headPx == 16 && normal.chipPx == 13 && large.chipPx == 16, "the smallest card text sits on each floor");
	Expect(normal.valueRight == normal.width - normal.pad - 67 && large.valueRight == large.width - large.pad - 80,
		"the value column matches the movie");

	Expect(hsb::FormatNumber(13, 2) == "13", "a whole stat has no decimals");
	Expect(hsb::FormatNumber(0.5, 2) == "0.5", "a half keeps one place");
	Expect(hsb::FormatNumber(1.23456, 2) == "1.23", "two places are kept");
	Expect(hsb::FormatNumber(2.675, 2) == "2.67", "the game cuts and does not round");
	Expect(hsb::FormatNumber(0.1 + 0.2, 2) == "0.30", "float noise is cut away");
	Expect(hsb::FormatNumber(-0.75, 2) == "-0.75", "a negative keeps its sign");
	Expect(hsb::FormatNumber(1560) == "1560", "the value has no group marks, as on the game card");
	Expect(hsb::FormatNumber(12.9) == "12", "no places cuts to the whole number");
	Expect(hsb::FormatNumber(std::numeric_limits<double>::quiet_NaN()) == "NaN", "a bad number reads as the game would show it");
	Expect(hsb::CardNumberText(true, 10) == "10" && hsb::CardNumberText(false, 10).empty(), "a missing cost or mass stays blank");
	Expect(hsb::NumberText(1.1920928955078125e-07) == "1.1920928955078125e-7" && hsb::NumberText(1e-7) == "1e-7",
		"toString writes an exponent below 1e-6");
	Expect(hsb::NumberText(0.000001) == "0.000001" && hsb::NumberText(1.5e-6) == "0.0000015", "toString keeps 1e-6 in plain digits");
	Expect(hsb::NumberText(1e21) == "1e+21" && hsb::NumberText(123456789012345680000.0) == "123456789012345680000",
		"toString writes an exponent from 1e21 up");
	Expect(hsb::NumberText(1152921504606846976.0) == "1152921504606847000" && hsb::NumberText(-0.0) == "0" && hsb::NumberText(-2.5) == "-2.5",
		"toString keeps the shortest digits");
	Expect(hsb::FormatNumber(1.1920928955078125e-07, 2) == "1.19", "a tiny stat is cut as the game card cuts it");
	Expect(hsb::FormatNumber(1e-7, 2) == "1e-7" && hsb::FormatNumber(1e21) == "1e+21", "text without a point is kept as the game keeps it");
	Expect(hsb::ChipNumber(1.1920928955078125e-07, 2) == "0" && hsb::ChipNumber(5e-9 * 100, 0) == "0", "chip float noise reads 0");
	Expect(hsb::ChipNumber(0.1 + 0.2, 2) == "0.3" && hsb::ChipNumber(0.336, 2) == "0.33" && hsb::ChipNumber(6, 2) == "6",
		"a chip cuts to the value's places and drops trailing zeros");
	Expect(hsb::ChipNumber(0.07 * 100, 0) == "7" && hsb::ChipNumber(0.29 * 100, 0) == "29", "a percent chip reads a whole percent");

	const hsb::CardStat hab[] = {
		{"$HULL", 5, 0, false},
		{"$PASSENGER_SLOTS", 0, 0, false},
		{"$CREW_STATIONS", 6, 6, false},
	};
	Expect(hsb::StatValueText(hab[0]) == "5" && hsb::StatValueText(hab[1]) == "0" && hsb::StatValueText(hab[2]) == "6",
		"hab stats read as the game card");
	Expect(hsb::DiffChipText(hab[0]).empty() && hsb::DiffChipText(hab[2]) == "+6", "only a changed hab stat gets a chip");
	Expect(hsb::ToneOf(hab[2].diff) == hsb::DiffTone::Higher, "a higher stat uses the higher tone");

	const hsb::CardStat weapon[] = {
		{"$HULL_DMG", 13, 0, false},
		{"$SHIELD_DMG", 4, 0, false},
		{"$MAX_POWER", 4, 1, false},
		{"Hull", 1, -2, false},
		{"$CREW_CAPACITY", 0.5, 0, false},
		{"$FIRE_RATE", 0.83333, -0.25, false},
	};
	Expect(hsb::StatValueText(weapon[0]) == "13" && hsb::StatValueText(weapon[4]) == "0.5" && hsb::StatValueText(weapon[5]) == "0.83",
		"weapon stats read as the game card");
	Expect(hsb::DiffChipText(weapon[2]) == "+1" && hsb::DiffChipText(weapon[3]) == "-2" && hsb::DiffChipText(weapon[5]) == "-0.25",
		"weapon diffs keep the value's places");
	Expect(hsb::ToneOf(weapon[3].diff) == hsb::DiffTone::Lower, "a lower stat uses the lower tone");

	const hsb::CardStat reactor[] = {
		{"$CLASS", 66, 1, false},
		{"$POWER", 18, 3, false},
		{"$REPAIR", 0.125, 0.05, true},
		{"$SHIELD_REGEN", 0.07, 0, true},
	};
	Expect(hsb::StatValueText(reactor[0]) == "B", "the class stat is a letter");
	Expect(hsb::DiffChipText(reactor[0]) == "+", "a class change shows its sign only");
	Expect(hsb::StatValueText(reactor[2]) == "12%" && hsb::DiffChipText(reactor[2]) == "+5%", "a percent stat is cut to a whole percent");
	Expect(hsb::StatValueText(reactor[3]) == "7%", "a percent with float noise reads as a whole percent");
	Expect(hsb::CharCodeText(77) == "M" && hsb::CharCodeText(65.9) == "A", "class letters come from the char code");
	Expect(hsb::ToneOf(std::numeric_limits<double>::quiet_NaN()) == hsb::DiffTone::Same && hsb::ToneOf(-0.0) == hsb::DiffTone::Same,
		"a missing diff is the default frame");
	Expect(hsb::DiffChipText({"$HULL", 5, 1.1920928955078125e-07, false}).empty(), "float noise in a diff gets no chip");
	Expect(hsb::DiffChipText({"$REPAIR", 0.125, 5e-9, true}).empty(), "float noise in a percent diff gets no chip");
	Expect(hsb::DiffChipText({"$MASS_LIMIT", 1, -0.004, false}).empty(), "a diff below two places gets no chip");
	Expect(hsb::DiffChipText({"$HULL", 5, 0.1 + 0.2, false}) == "+0.3", "a chip has no float tail");
	Expect(hsb::DiffChipText({"$CLASS", 67, 1e-9, false}) == "+", "a class change keeps its sign");
	Expect(hsb::ChipRoom(normal) == 59 && hsb::ChipRoom(large) == 72, "chip room ends 6 px short of the value column");
	Expect(hsb::ShortChip("+1234.56") == "+1234" && hsb::ShortChip("+9.5") == "+9", "a chip too wide drops its places");
	Expect(hsb::ShortChip("-0.25") == "-" && hsb::ShortChip("+12345%") == "+" && hsb::ShortChip("+Infinity") == "+" &&
		hsb::ShortChip("+1.5e+21") == "+", "a short chip never reads as no change or a wrong number");
	Expect(hsb::ChipNumber(1.5e21, 2) == "1.5e+21" && hsb::ChipNumber(std::numeric_limits<double>::infinity(), 2) == "Infinity",
		"a chip keeps toFixed's exponent text whole");
	{
		bool whole = true;
		for (const double size : {1e-7, 0.0049, 0.005, 0.0123, 0.1 + 0.2, 0.125, 0.5, 1.0, 1.5, 12.345, 1e19, 1.5e19})
			for (const double sign : {1.0, -1.0}) {
				const std::string chip = hsb::DiffChipText(hsb::CardStat{"50%", 0.5, sign * size, true});
				if (chip.find('.') != std::string::npos && chip.find('e') == std::string::npos) whole = false;
			}
		Expect(whole && hsb::ShortChip(hsb::DiffChipText(hsb::CardStat{"50%", 0.5, 1.5e19, true})) == "+",
			"a percent chip has places only as exponent text, so a short chip never cuts a percent number");
	}
	Expect(hsb::ChipWidth(normal, 4) == 28 && hsb::ChipWidth(normal, 30) == 44 && hsb::ChipWidth(normal, 90) == 59 && hsb::ChipWidth(large, 90) == 72,
		"a long chip is capped short of the value column");

	Expect(hsb::CardStatRows(11) == 10 && hsb::CardStatRows(3) == 3 && hsb::CardStatRows(-1) == 0, "the card shows up to ten stats");
	Expect(hsb::CardSkillRows(3) == 2 && hsb::CardSkillRows(0) == 0, "the card shows up to two skills");
	Expect(hsb::Substitute("Rank {0}", {"2"}) == "Rank 2", "the rank goes into the translated text");
	Expect(hsb::Substitute("$(Rank #)", {"2"}) == "$(Rank #)", "an untranslated key is left as it is");
	Expect(hsb::LabelKeptKey("$HULL") && !hsb::LabelKeptKey("HULL") && !hsb::LabelKeptKey(""), "a kept key is counted for the log");

	hsb::CardState state;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Face, "no proven face keeps the game card");
	state.faceProven = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Map, "the card waits for the panel map");
	state.mapped = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Clip, "the card needs the game card on the menu");
	state.nativeSeated = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Data, "the card waits for a module name");
	state.hasName = true;
	state.paintFailed = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Paint, "a failed paint keeps the game card until the next payload");
	state.paintFailed = false;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Hidden, "the card follows the show flag");
	state.showWidget = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Hidden, "the card follows the game card's visibility");
	state.nativeShown = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::On, "a shown game card with data brings ours up");
	state.arranging = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Arrange, "arrange does not bring our card up");
	state.cardUp = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::On, "a card already up stays up through arrange");
	state.showWidget = false;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Hidden, "a hidden game card drops ours even in arrange");
	state.showWidget = true;
	state.arranging = false;
	state.cardUp = false;
	state.hangarShown = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Hangar, "the hangar overview keeps the game card");
	state.hangarShown = false;
	state.conflict = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Conflict, "another builder keeps the game card");
	Expect(std::string(hsb::CardGateName(hsb::CardGate::On)) == "on" && std::string(hsb::CardGateName(hsb::CardGate::Face)) == "face",
		"gate names match the log");
	Expect(hsb::NativeCardAlpha(hsb::CardGate::On, 1.0f) == 0.0f, "the game card is hidden in place while ours is up");
	Expect(hsb::NativeCardAlpha(hsb::CardGate::Hidden, 1.0f) == 1.0f && hsb::NativeCardAlpha(hsb::CardGate::Hangar, 0.8f) == 0.8f,
		"every other state puts the game card's alpha back");
	Expect(hsb::HeldAlpha(0.0f) == 1.0f && hsb::HeldAlpha(0.6f) == 0.6f, "a zero alpha is never kept for the game card");
	Expect(hsb::CardSeatY(610, 400, 0, 1080, false) == 610, "a card that fits sits on the game card's top");
	Expect(hsb::CardSeatY(610, 660, 0, 1080, false) == 420, "a tall card is lifted to stay on screen");
	Expect(hsb::CardSeatY(610, 660, 0, 1080, true) == 610, "arrange seats the card exactly");
	Expect(hsb::CardSeatY(100, 1200, 0, 1080, false) == 0, "a card taller than the screen keeps its top on screen");

	const hsb::ArrangeView view{0, 0, 1920, 1080};
	const hsb::ArrangeBox home{34, 300, 360, 470};
	const hsb::ArrangeBox seat = hsb::CardSeat(home, normal.width, 400);
	Expect(seat.x == home.x && seat.y == home.y && seat.w == normal.width, "our card's top left is the game card's top left");
	const hsb::CardDrag moved = hsb::DragCard(home, normal.width, 400, 523, 607, view, hsb::kMarginDefault);
	Expect(moved.card.x == 520 && moved.card.y == 610, "a drag snaps our card to the grid");
	Expect(moved.native.x == moved.card.x && moved.native.y == moved.card.y, "the game card moves under ours");
	Expect(moved.ax == "C-260" && moved.ay == "B-34", "the module anchor uses the game card's size");
	const hsb::ArrangeBox back = hsb::PlaceSaved(moved.ax, moved.ay, home, view, hsb::kMarginDefault);
	Expect(back.x == moved.native.x && back.y == moved.native.y, "a saved spot reloads where it was left");
	Expect(hsb::CardSeat(back, normal.width, 400).y == moved.card.y, "our card comes back with the game card");
	const std::string cardSized = hsb::StoreAnchor(false, moved.card.y, 400, view.y, view.h, hsb::kMarginDefault);
	Expect(hsb::PlaceSaved(moved.ax, cardSized, home, view, hsb::kMarginDefault).y != moved.native.y,
		"an anchor stored with our card's size would reload somewhere else");
	const hsb::CardDrag low = hsb::DragCard(home, normal.width, 400, 40, 900, view, hsb::kMarginDefault);
	Expect(low.card.y == 610 && low.ax == "L6", "a drag keeps the taller game box on screen");
	Expect(hsb::PlaceSaved(low.ax, low.ay, home, view, hsb::kMarginDefault).y == low.native.y, "a spot at the bottom edge reloads without a clamp");
	const hsb::ArrangeBox shortHome{34, 300, 360, 300};
	const hsb::CardDrag tall = hsb::DragCard(shortHome, normal.width, 620, 40, 900, view, hsb::kMarginDefault);
	Expect(tall.card.y == 460 && tall.card.y + 620 <= view.h, "a drag keeps a card taller than the game card on screen");
	Expect(tall.ay == "C70" && hsb::PlaceSaved(tall.ax, tall.ay, shortHome, view, hsb::kMarginDefault).y == tall.native.y,
		"a taller card's spot is stored with the game card's size and reloads in place");

	const hsb::ArrangeView wide{0, 0, 2560, 1440};
	const hsb::ArrangeBox bigHome{40, 380, 420, 560};
	const hsb::CardDrag bigMove = hsb::DragCard(bigHome, large.width, 470, 1900, 120, wide, hsb::kMarginDefault);
	const hsb::ArrangeBox bigBack = hsb::PlaceSaved(bigMove.ax, bigMove.ay, bigHome, wide, hsb::kMarginDefault);
	Expect(bigBack.x == bigMove.native.x && bigBack.y == bigMove.native.y, "the large card round-trips a saved spot");
	Expect(bigMove.ax[0] == 'R' && bigMove.ay[0] == 'T', "a large card near the top right keeps those edges");
}

static std::size_t CountOf(const std::string& text, const std::string& needle)
{
	std::size_t n = 0;
	for (std::size_t at = text.find(needle); at != std::string::npos; at = text.find(needle, at + needle.size())) ++n;
	return n;
}

// One movie function, through its closing brace at member indent.
static std::string FunctionBody(const std::string& source, const std::string& name, const std::string& access = "private")
{
	const std::string head = access + " function " + name + "(";
	const std::size_t at = source.find(head);
	if (at == std::string::npos) return {};
	const std::string close = "\n      }\n";
	const std::size_t end = source.find(close, at + head.size());
	return source.substr(at, end == std::string::npos ? std::string::npos : end + close.size() - at);
}

static bool InOrder(const std::string& text, const std::vector<std::string>& parts)
{
	std::size_t at = 0;
	for (const std::string& part : parts) {
		const std::size_t hit = text.find(part, at);
		if (hit == std::string::npos) return false;
		at = hit + part.size();
	}
	return true;
}

static std::string Pick(const hsb::CardMetrics& large, const hsb::CardMetrics& normal, int hsb::CardMetrics::*field)
{
	return "this.lrg ? " + std::to_string(large.*field) + " : " + std::to_string(normal.*field);
}

static void CheckFaceProof()
{
	const hsb::FaceMeasure boxes{96, 96, 24};
	const hsb::FaceMeasure grotesk{152, 43, 24};
	const hsb::FaceMeasure none{};
	Expect(!hsb::FaceProven(boxes, none), "box glyphs with one advance are not a face");
	Expect(hsb::FaceProven(grotesk, boxes), "proportional letters prove a face");
	Expect(!hsb::FaceProven(grotesk, grotesk), "a face that measures like a missing name is not proven");
	Expect(!hsb::FaceProven(none, boxes), "an empty measure is not proven");
	Expect(!hsb::FaceProven({std::numeric_limits<float>::quiet_NaN(), 43, 24}, boxes), "a bad measure is not proven");
	Expect(!hsb::FaceProven({152, 43, 3}, boxes), "a field with no height is not proven");
	Expect(!hsb::FaceProven({60, 40, 24}, boxes), "a narrow W is not proven");

	hsb::FaceCandidate order[7] = {
		{boxes, true, true},
		{grotesk, true, true},
		{{148, 40, 24}, true, true},
		{{}, true, false},
		{grotesk, false, true},
		{grotesk, false, true},
		{grotesk, false, true},
	};
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 1, "the first proven mapped name wins");
	order[1].measure = boxes;
	order[2].measure = boxes;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 4, "device text is tried only after every embedded name fails");
	order[3] = {{150, 41, 24}, true, true};
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 3, "the module-name face comes before device text");
	for (auto& c : order) c.measure = boxes;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == -1, "no proof leaves the earlier text path");
	Expect(hsb::PickFace(nullptr, 7, boxes, boxes) == -1, "no list is no proof");
	Expect(hsb::TextPx(11, false) == 13 && hsb::TextPx(13, true) == 16 && hsb::TextPx(21, false) == 21,
		"text keeps the 13 and 16 px floors");
}

// Every line that uses the picked face name itself, trimmed and sorted. A log line can
// carry the name through a temp, so the gold movie's uses are checked against a fixed list.
static std::vector<std::string> FaceUses(const std::string& source)
{
	std::vector<std::string> uses;
	std::istringstream in(source);
	std::string line;
	while (std::getline(in, line)) {
		for (std::size_t at = line.find("this.face"); at != std::string::npos; at = line.find("this.face", at + 1)) {
			const std::size_t next = at + 9;
			const char c = next < line.size() ? line[next] : ' ';
			const bool ident = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_';
			if (ident) continue;
			const auto first = line.find_first_not_of(" \t");
			const auto last = line.find_last_not_of(" \t\r");
			uses.push_back(first == std::string::npos ? std::string() : line.substr(first, last - first + 1));
			break;
		}
	}
	std::sort(uses.begin(), uses.end());
	return uses;
}

// Lines that build log text may carry candidate tags and metrics, never a face name.
static bool NotesHideFaces(const std::string& source)
{
	std::istringstream in(source);
	std::string line;
	while (std::getline(in, line)) {
		const bool logs = line.find("this.note(") != std::string::npos || line.find("report +=") != std::string::npos
			|| line.find("line +=") != std::string::npos || line.find("var report") != std::string::npos
			|| line.find("var line") != std::string::npos || line.find("lines.push(") != std::string::npos;
		if (!logs) continue;
		if (line.find("FACES") != std::string::npos || line.find("names[") != std::string::npos
			|| line.find("labelFace") != std::string::npos || line.find("fieldFace(") != std::string::npos
			|| line.find(".font") != std::string::npos)
			return false;
		for (std::size_t at = line.find("this.face"); at != std::string::npos; at = line.find("this.face", at + 1)) {
			const std::size_t next = at + 9;
			const char c = next < line.size() ? line[next] : ' ';
			const bool ident = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_';
			if (!ident) return false;
		}
	}
	return true;
}

static std::string ReadFile(const fs::path& path)
{
	std::ifstream in(path, std::ios::binary);
	return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

static bool HasNul(const std::string& text)
{
	return text.find('\0') != std::string::npos;
}

static void ScanTree(const fs::path& root)
{
	const std::string retiredA = std::string("HU") + "SD";
	const std::string retiredB = std::string("rs") + "chr";
	const std::string timer = std::string("get") + "Timer";
	const std::string glow = std::string("Glow") + "Filter";
	const std::string shipEdit = std::string("Ship") + "Editor_";
	const std::string shipBuild = std::string("Ship") + "Builder_";
	const std::string dispatch = std::string("dispatch") + "Event";
	const std::string del = std::string("Delete") + "File";
	const std::string move = std::string("Move") + "File";
	const std::string rmdir = std::string("Remove") + "Directory";
	const std::string files = std::string("std::") + "filesystem";
	const std::string wideOpen = std::string("_wf") + "open_s";
	const std::string stream = std::string("of") + "stream";
	std::error_code err;
	if (!fs::exists(root, err)) {
		Expect(false, "scan root exists");
		return;
	}
	for (auto it = fs::recursive_directory_iterator(root, fs::directory_options::skip_permission_denied, err);
		it != fs::recursive_directory_iterator(); it.increment(err)) {
		if (err) break;
		if (!it->is_regular_file()) continue;
		const std::string body = ReadFile(it->path());
		if (HasNul(body)) continue;
		const auto rel = it->path().lexically_normal().generic_string();
		Expect(body.find(retiredA) == std::string::npos, "retired name A");
		Expect(body.find(retiredB) == std::string::npos, "retired name B");
		Expect(body.find(timer) == std::string::npos, "no timer call");
		Expect(body.find(glow) == std::string::npos, "no glow");
		Expect(body.find(shipEdit) == std::string::npos, "no editor event name");
		{
			bool shipHit = false;
			for (std::size_t at = 0; (at = body.find(shipBuild, at)) != std::string::npos; at += shipBuild.size()) {
				const bool logName = at >= 7 && body.compare(at - 7, 7, "Horizon") == 0;
				if (!logName) shipHit = true;
			}
			if (shipHit) {
				std::cerr << "FAIL: " << rel << " builder event name\n";
				++g_fails;
			}
		}
		Expect(body.find(dispatch) == std::string::npos, "no event dispatch");
		Expect(body.find(del) == std::string::npos, "no file delete");
		if (body.find(move) != std::string::npos)
			Expect(rel.find("probe.cpp") != std::string::npos, "file replace stays in the plugin");
		Expect(body.find(rmdir) == std::string::npos, "no directory remove");
		Expect(body.find(files) == std::string::npos || rel.find("/tests/") != std::string::npos,
			"filesystem only in the test");
		const bool writer = body.find(wideOpen) != std::string::npos || body.find(stream) != std::string::npos;
		if (writer) Expect(rel.find("probe.cpp") != std::string::npos, "only the plugin opens a file");
	}
}

int main()
{
	const std::string docs = DocsTail('\\');
	const std::string docsSlash = DocsTail('/');
	const std::string good = docs + "SFSE\\Logs\\" + hsb::kProbeFile;
	const std::string goodSlash = docsSlash + "SFSE/Logs/" + hsb::kProbeFile;
	Expect(hsb::ProbeMayAppend(good), "documents log is allowed");
	Expect(hsb::ProbeMayAppend(goodSlash), "forward-slash log is allowed");
	Expect(!hsb::ProbeMayAppend(std::string("D:\\Steam\\steamapps\\common\\Starfield\\Data\\") + hsb::kProbeFile), "game data is refused");
	Expect(!hsb::ProbeMayAppend(docs + "Saves\\" + hsb::kProbeFile), "saves are refused");
	Expect(!hsb::ProbeMayAppend(docs + "SFSE\\Logs\\other.log"), "other names are refused");
	Expect(!hsb::ProbeMayAppend(docs + "SFSE\\Logs\\..\\" + hsb::kProbeFile), "dot-dot is refused");

	Expect(hsb::ShouldRestoreWndProc(reinterpret_cast<void*>(1), reinterpret_cast<void*>(1)), "restore when we still own the hook");
	Expect(!hsb::ShouldRestoreWndProc(reinterpret_cast<void*>(2), reinterpret_cast<void*>(1)), "leave a newer procedure");
	Expect(!hsb::ShouldRestoreWndProc(nullptr, reinterpret_cast<void*>(1)), "do not restore a null procedure");

	std::uint32_t id = 0;
	Expect(hsb::ParseFormLine("FORM 00000014", id) && id == 0x14u, "form line parses");
	Expect(hsb::ParseFormLine("FORM 0000abcd", id) && id == 0xABCDu, "form hex folds");
	Expect(!hsb::ParseFormLine("FORM 000000014", id), "nine digits are refused");
	Expect(!hsb::ParseFormLine("FORM note", id), "words are not form ids");
	Expect(!hsb::ParseFormLine("CAPTURE on", id), "capture is not a lookup");
	Expect(hsb::NextFormSlot(0) == 1, "first form slot");
	Expect(hsb::NextFormSlot(39) == 40, "last form slot");
	Expect(hsb::NextFormSlot(40) == -1, "form cap");
	Expect(hsb::ProbePollDue(1000, 0), "first poll is due");
	Expect(!hsb::ProbePollDue(100, 100), "same stamp is not due");
	Expect(hsb::ProbePollDue(1000, 1000 - hsb::kProbePollMs), "modest interval elapsed");
	Expect(!hsb::ProbePollDue(1000, 1000 - 1), "shorter than the modest interval waits");
	Expect(hsb::HookWasRipped(true, false), "a missed ping clears the hook");
	Expect(!hsb::HookWasRipped(true, true), "a live ping keeps the hook");
	Expect(!hsb::HookWasRipped(false, false), "an absent hook is not a rip");
	Expect(hsb::ChainIsLive(reinterpret_cast<const void*>(1)), "a stored procedure can be called");
	Expect(!hsb::ChainIsLive(nullptr), "an empty chain is not live");

	const std::string dirty = hsb::FactLine("F16", "line\r\nnext");
	Expect(dirty.find('\n') == std::string::npos && dirty.find('\r') == std::string::npos, "facts stay on one line");
	Expect(hsb::kMenuName == std::string("SpaceshipEditorMenu"), "menu name");

	fs::path repo = fs::path(__FILE__).parent_path().parent_path().parent_path();
#ifdef HSB_REPO_ROOT
	if (std::string(HSB_REPO_ROOT).size() > 0) repo = fs::path(HSB_REPO_ROOT);
#endif
	const fs::path root = repo / "shipbuilder";
	const std::string retiredA = std::string("HU") + "SD";
	const std::string retiredB = std::string("rs") + "chr";
	ScanTree(root);

	const std::string probe = ReadFile(root / "actionscript" / "HorizonShipBuilderProbe.as");
	Expect(probe.find("captureOn = false") != std::string::npos, "capture starts off");
	Expect(probe.find("fmt.size = 13") != std::string::npos, "overlay is 13 px");
	Expect(probe.find("import Shared.AS3.Data.BSUIDataManager;") != std::string::npos, "data manager import");
	Expect(probe.find("embedFonts") != std::string::npos, "overlay uses the embedded face");
	Expect(probe.find("defaultTextFormat") != std::string::npos, "overlay copies a vanilla text format");
	Expect(probe.find("$MAIN_Font") == std::string::npos, "the face name is not written out");
	Expect(probe.find("Keyboard.F7") != std::string::npos && probe.find("Keyboard.F8") != std::string::npos && probe.find("Keyboard.F6") != std::string::npos, "F7 F8 F6 are the probe keys");
	Expect(probe.find("Keyboard.F9") == std::string::npos, "F9 is not a probe key");
	Expect(probe.find("enumerateFonts(false)") != std::string::npos, "the font fallback is embedded faces only");
	Expect(probe.find("enumerateFonts(true)") == std::string::npos, "the font fallback does not include device faces");
	Expect(probe.find("stopPropagation") == std::string::npos, "probe keys are not swallowed");
	Expect(probe.find("PANEL ") != std::string::npos, "panel mouse is logged");
	Expect(probe.find("noteHelp") != std::string::npos, "help list is logged");
	Expect(probe.find("0.0.2.0") != std::string::npos, "probe movie version");
	Expect(probe.find("spaceshipeditormenu") == std::string::npos, "the class does not name a replacement movie");

	const std::string splice = ReadFile(root / "actionscript" / "document_splice.as");
	Expect(splice.find("spaceshipeditormenu.swf") != std::string::npos, "normal movie is named");
	Expect(splice.find("spaceshipeditormenu_lrg.swf") != std::string::npos, "large movie is named");
	Expect(splice.find("import HorizonShipBuilderProbe;") != std::string::npos, "probe import");
	Expect(splice.find("has no onAddedToStage") != std::string::npos, "missing stage handler is covered");
	Expect(splice.find("hsbProbePing") != std::string::npos, "ping splice");
	Expect(splice.find("ProcessUserEvent") != std::string::npos, "user-event splice");
	Expect(splice.find("hsbProbeHotkey") != std::string::npos, "hotkey splice");
	Expect(splice.find("hsbProbeStage") != std::string::npos, "stage-size splice");
	Expect(splice.find("Do not return") != std::string::npos, "user events are not swallowed");

	const std::string readme = ReadFile(root / "README_P0.md");
	Expect(readme.find("xmake build -y HorizonShipBuilder") != std::string::npos, "build step");
	Expect(readme.find("F.1") != std::string::npos, "readme lists the live tests");
	Expect(readme.find("#16") != std::string::npos && readme.find("#17") != std::string::npos && readme.find("#18") != std::string::npos,
		"arrange tests are in the readme");
	Expect(readme.find("Data\\Interface\\spaceshipeditormenu.swf") != std::string::npos, "normal movie path");
	Expect(readme.find("Data\\Interface\\spaceshipeditormenu_lrg.swf") != std::string::npos, "large movie path");
	Expect(readme.find("Starfield - Interface.ba2") != std::string::npos, "archive source");
	Expect(readme.find("spaceshipeditormenu*.swf") != std::string::npos, "loose movie check");
	Expect(readme.find("HorizonShipBuilder_vanilla_backup") != std::string::npos, "named backup");
	Expect(readme.find("throwaway save") != std::string::npos, "throwaway save warning");
	Expect(readme.find("hud-advance") != std::string::npos, "HUD advance is the documented post");
	Expect(readme.find("0.0.2.0") != std::string::npos, "readme names the probe version");
	Expect(readme.find("P0.1") != std::string::npos, "readme has the P0.1 pass");
	Expect(readme.find("F7") != std::string::npos && readme.find("F8") != std::string::npos && readme.find("F6=dump") != std::string::npos, "readme names the probe keys");

	const std::string lua = ReadFile(repo / "xmake.lua");
	Expect(lua.find("target(\"HorizonShipBuilder\")") != std::string::npos, "probe target");
	Expect(lua.find("target(\"probe_logic_test\")") != std::string::npos, "logic test target");
	Expect(lua.find("set_default(false)") != std::string::npos, "logic test is not a default build");
	Expect(lua.find("set_version(\"0.43.0.33\")") != std::string::npos, "core version stays");
	Expect(lua.find(retiredA) == std::string::npos && lua.find(retiredB) == std::string::npos, "xmake has no retired names");

	const std::string plugin = ReadFile(root / "src" / "probe.cpp");
	Expect(plugin.find("ProbeMayAppend") != std::string::npos, "plugin checks the log path");
	Expect(plugin.find("ShouldRestoreWndProc") != std::string::npos, "plugin uses the unhook rule");
	Expect(plugin.find(std::string("swallowed") + "=0") != std::string::npos, "the hook does not swallow");
	Expect(plugin.find("VK_F7") != std::string::npos && plugin.find("VK_F6") != std::string::npos, "F7 and F6 are recognized at the window");
	Expect(plugin.find("VK_F9") == std::string::npos, "F9 is not recognized as the dump key");
	Expect(plugin.find("hsbProbeHotkey") != std::string::npos, "hotkey is delivered on the movie thread");
	Expect(plugin.find("GetClientRect") != std::string::npos, "client size is read for the map");
	Expect(plugin.find("keys F7=mark") != std::string::npos, "boot logs the key map");
	Expect(plugin.find("SendMessage") == std::string::npos, "the job side does not wait on the window");
	Expect(plugin.find("PostMessageW") != std::string::npos, "the job side posts to the window");
	Expect(plugin.find("DllMain") != std::string::npos, "unload unhook");
	Expect(plugin.find("AdvanceFrame") != std::string::npos, "movie advance hook");
	const auto jobA = plugin.find("JOBTICK-BEGIN");
	const auto jobB = plugin.find("JOBTICK-END");
	Expect(jobA != std::string::npos && jobB != std::string::npos && jobB > jobA, "job tick is marked");
	if (jobA != std::string::npos && jobB > jobA) {
		const auto job = plugin.substr(jobA, jobB - jobA);
		Expect(job.find("Invoke") == std::string::npos, "job tick does not call into Scaleform");
		Expect(job.find("SetWindowLongPtr") == std::string::npos, "job tick does not change the window procedure");
		Expect(job.find("_wfopen") == std::string::npos, "job tick does not open the log itself");
	}
	const auto wnd = plugin.find("CALLBACK ProbeWnd");
	const auto afterWnd = plugin.find("FindGameWindow", wnd == std::string::npos ? 0 : wnd);
	Expect(wnd != std::string::npos && afterWnd != std::string::npos, "window procedure is present");
	if (wnd != std::string::npos && afterWnd > wnd) {
		const auto body = plugin.substr(wnd, afterWnd - wnd);
		Expect(body.find("_wfopen") == std::string::npos, "window procedure does not touch the log file");
		Expect(body.find("SetWindowLongPtr") == std::string::npos, "window procedure does not reinstall itself");
		Expect(body.find("Invoke") == std::string::npos, "window procedure does not call into Scaleform");
	}

	Expect(!hsb::IsProbeHotkey(false, hsb::kVkF6), "probe keys stay off");
	Expect(hsb::IsProbeHotkey(true, hsb::kVkF7), "probe keys exist when debug is on");
	Expect(hsb::IsArrangeEntry(false, true, hsb::kVkL), "ctrl L opens arrange");
	Expect(!hsb::IsArrangeEntry(false, false, hsb::kVkL), "bare L is not an arrange key");
	Expect(!hsb::IsArrangeEntry(true, true, hsb::kVkL), "arrange entry waits until capture ends");
	Expect(hsb::EatKey(true) && !hsb::EatKey(false), "keys are eaten only while captured");
	Expect(hsb::EatMouse(true) && !hsb::EatMouse(false), "mouse is eaten only in arrange");
	Expect(std::string(hsb::ArrangeKeyToken(hsb::kVkDelete, false)) == "noop", "delete stays unbound");
	Expect(std::string(hsb::ArrangeKeyToken(hsb::kVkBack, false)) == "noop", "backspace stays unbound");
	Expect(std::string(hsb::ArrangeKeyToken(hsb::kVkEsc, false)) == "cancel", "escape cancels");
	Expect(std::string(hsb::ArrangeKeyToken(hsb::kVkLeft, true)) == "left40", "shift arrow is the long nudge");
	CheckArrangeLifecycle();
	CheckInteriorLifecycle();
	CheckFaceProof();
	CheckModuleCard();
	Expect(hsb::kAccentGold == 0xE8C547, "default accent is gold");
	Expect(hsb::ResolveAccent(-1, "", false, 3, "") == hsb::kAccentDefault, "missing hud accent stays gold");
	Expect(hsb::ResolveAccent(4, "", false, 3, "") == 4, "a swatch is kept");
	Expect(hsb::ResolveAccent(13, "E8C547", false, 3, "") == 13, "custom hex is kept");
	Expect(hsb::ResolveAccent(13, "zz", false, 3, "") == hsb::kAccentDefault, "bad hex falls back to gold");
	Expect(hsb::ValidArrangeValue("PowerX", "L10"), "left anchor is valid");
	Expect(!hsb::ValidArrangeValue("PowerX", "nope"), "bad anchor is ignored");
	Expect(hsb::IsDefaultArrange("PowerX", "-1"), "default spots are not saved");
	const std::string merged = hsb::MergeUserIni("[Notes]\nKeep=1\n", {{"PowerX", "-1"}, {"BrowserX", "R20"}, {"AccentColor", "9"}});
	Expect(merged.find("Keep=1") != std::string::npos, "other ini sections stay");
	Expect(merged.find("PowerX=") == std::string::npos, "default positions are dropped");
	Expect(merged.find("BrowserX=R20") != std::string::npos, "a moved panel is kept");
	Expect(merged.find("AccentColor=") == std::string::npos, "the default accent is dropped");
	const std::string iniPath = DocsTail('\\') + "Data\\Interface\\HorizonUI\\shipbuilder\\HorizonShipBuilder.user.ini";
	Expect(hsb::IniMayWrite(iniPath), "the user ini path is allowed");
	Expect(!hsb::IniMayWrite(std::string("D:\\Steam\\steamapps\\common\\Starfield\\") + "HorizonShipBuilder.user.ini"), "the game folder is refused");
	Expect(std::string(HSB_FILE_VERSION_STR) == "0.1.1.0", "plugin version is 0.1.1.0");
	Expect(lua.find("set_version(\"0.1.1\")") != std::string::npos, "the builder target version matches the plugin");

	const std::string gold = ReadFile(root / "actionscript" / "HorizonShipBuilder.as");
	Expect(gold.find("return \"0.1.1.0\"") != std::string::npos && gold.find("BUILDER 0.1.1.0") != std::string::npos,
		"gold movie version");
	Expect(gold.find("0.1.0.0") == std::string::npos, "no stale gold version");
	Expect(gold.find("\"$NB_Grotesk_Semibold\",\"$MAIN_Font_Bold\",\"$MAIN_Font\"") != std::string::npos,
		"mapped candidates are tried in order");
	Expect(gold.find("$Horizon_NoSuchFace_x") != std::string::npos, "a face is compared with a name that cannot exist");
	Expect(gold.find("\"WWWWWWWW\"") != std::string::npos && gold.find("\"iiiiiiii\"") != std::string::npos,
		"wide and narrow letters are measured");
	Expect(gold.find("wide < narrow * 1.6") != std::string::npos, "the movie ratio matches the twin");
	Expect(gold.find("Math.abs(wide - missWide) < 0.5") != std::string::npos, "the movie closeness matches the twin");
	Expect(gold.find("\"ModuleInfoCard_mc\",\"ModuleLabel_mc\",\"text_tf\"") != std::string::npos,
		"the fallback face is the module name field, not the first field");
	Expect(gold.find("\"FONT try=\"") != std::string::npos && gold.find("\"FONTSRC \"") != std::string::npos,
		"the face proof is logged");
	Expect(NotesHideFaces(gold), "log lines name candidates by index only");
	{
		std::vector<std::string> allowed = {
			"this.face = \"\";",
			"this.face = \"\";",
			"this.face = String(names[k]);",
			"if(this.face.length == 0 && this.faceTries < 3 && (this.frameN == 30 || this.frameN == 120))",
			"if(this.face.length > 0) { this.refreshFaces(); }",
			"fmt.font = this.face;",
			"if(this.face.length == 0) { return \"face\"; }",
			"if(this.face.length > 0) { fmt.font = this.face; }",
		};
		std::sort(allowed.begin(), allowed.end());
		Expect(FaceUses(gold) == allowed, "the picked face name only sets and tests faces, so no temp can carry it to a log");
	}
	Expect(gold.find("box.embedFonts = this.faceEmbed") != std::string::npos, "horizon text uses the proven embed flag");
	Expect(gold.find("this.hexBox.embedFonts = this.faceEmbed") != std::string::npos, "the hex field uses the proven face");
	Expect(gold.find("this.hexBox.type = TextFieldType.INPUT") != std::string::npos, "the hex field stays editable");
	Expect(gold.find("var floor:int = this.lrg ? 16 : 13;") != std::string::npos, "text floors are 13 and 16 px");
	Expect(gold.find("findLatinField") == std::string::npos, "the face is not taken from the first text field");
	Expect(gold.find("enumerateFonts") == std::string::npos, "the face is not the first enumerated font");
	Expect(gold.find("E8C547") != std::string::npos, "gold accent number");
	Expect(gold.find("ARRANGE PANELS") != std::string::npos, "arrange entry button");
	Expect(gold.find("COVERS THE SHIP VIEW") != std::string::npos, "overlap chip");
	Expect(gold.find("SELECTED MODULE") != std::string::npos, "module label");
	Expect(gold.find("PARTS BROWSER") != std::string::npos, "browser label");
	Expect(gold.find("ModulePalette_mc") != std::string::npos, "parts list uses the game clip");
	Expect(gold.find("HangarInfoPanel_mc") != std::string::npos, "hangar overview is recognized");
	Expect(gold.find("assignSpots") == std::string::npos, "hidden panels are not grabbed by proximity");
	Expect(gold.find("sample.embedFonts") == std::string::npos, "embed flag is not copied from the first field");
	Expect(gold.find("param1 == \"Browser\"") != std::string::npos, "parts list stays on the menu");
	Expect(gold.find("param1 == \"Power\"") != std::string::npos && gold.find("param1 == \"Stats\"") != std::string::npos,
		"power and the footer stay on the menu");
	Expect(gold.find("r.y + 180") != std::string::npos, "settings sits below the credit strip");
	Expect(gold.find("700 * r.width") == std::string::npos, "settings is not parked on the credits");
	Expect(gold.find("this.sel = \"Power\"") == std::string::npos, "arrange does not start on power");
	Expect(gold.find("defaultSel") != std::string::npos, "selection starts at the first live handle");
	Expect(gold.find("moveNative") != std::string::npos, "a drag translates the game clip");
	Expect(gold.find("revalidateFades") != std::string::npos, "fades are checked again each pass");
	Expect(gold.find("hitArea") != std::string::npos && gold.find(".mask") != std::string::npos, "masks and hit targets are inspected");
	Expect(gold.find("canHoldContent") != std::string::npos, "containers are not treated as decoration");
	Expect(gold.find("boundHas(param1,\"mask\")") != std::string::npos, "the movie protects mask names");
	Expect(gold.find("boundHas(param1,\"hitarea\")") != std::string::npos, "the movie protects hit area names");
	Expect(gold.find("boundHas(param1,\"hit\")") != std::string::npos, "the movie protects hit names");
	Expect(gold.find("addChildAt(plate") == std::string::npos, "the plate is not inserted into the clip");
	Expect(gold.find("panelMovable") != std::string::npos, "only safe panels are handles");
	Expect(gold.find("parent.removeChild") == std::string::npos, "game clips are not taken off the menu");
	Expect(readme.find("game root") != std::string::npos, "the readme names the game root");
	Expect(readme.find("Data folder as the mod root") == std::string::npos, "the readme does not call Data the mod root");
	const std::string vortex = ReadFile(root / "package_vortex.sh");
	Expect(vortex.find("Data/SFSE/Plugins/HorizonShipBuilder.dll") != std::string::npos, "vortex zip has the plugin path");
	Expect(vortex.find("Data/Interface/spaceshipeditormenu.swf") != std::string::npos, "vortex zip has the normal movie");
	Expect(vortex.find("Data/Interface/spaceshipeditormenu_lrg.swf") != std::string::npos, "vortex zip has the large movie");
	Expect(vortex.find("HorizonShipBuilder.default.ini") != std::string::npos, "vortex zip has the default ini");
	Expect(vortex.find("game root") != std::string::npos, "the package script names the game root");
	Expect(vortex.find("Data/Data") == std::string::npos, "the package script does not nest Data");
	Expect(gold.find(std::string("get") + "Timer") == std::string::npos, "gold movie has no timer");
	Expect(gold.find(std::string("Glow") + "Filter") == std::string::npos, "gold movie has no glow");
	Expect(gold.find("Keyboard.F") == std::string::npos, "gold movie has no probe keys");
	Expect(gold.find("aPartList") == std::string::npos, "gold movie does not touch the parts array");
	Expect(gold.find("SetCategory") == std::string::npos && gold.find("CategoryName") == std::string::npos && gold.find("iCategoryIndex") == std::string::npos,
		"the gold movie neither reads nor writes categories, so another mod's categories pass through untouched");
	Expect(CountOf(gold, "ModuleEntries_mc") == 2 && FunctionBody(gold, "noteFaces").find("[\"ModuleEntries_mc\"]") != std::string::npos &&
		FunctionBody(gold, "nativeList").find("list = this.host[\"ModulePalette_mc\"][\"ModuleEntries_mc\"] as InteractiveObject;") != std::string::npos,
		"the parts list is read for the face log and named as the focus target, never changed");
	const std::string give = FunctionBody(gold, "giveFocus");
	Expect(CountOf(gold, ".focus = ") == 2 && CountOf(give, "stage.focus = param1;") == 2 &&
		InOrder(give, {"stage.focus = param1;", "if(stage.focus != param1) { stage.focus = param1; }"}),
		"focus moves only through giveFocus, which assigns once more if the menu put it back");
	Expect(CountOf(gold, "this.giveFocus(") == 2 && CountOf(gold, "giveFocus(this.hexBox)") == 1 && CountOf(gold, "giveFocus(list)") == 1,
		"the movie gives focus only to its hex field and back to the game list");
	const std::string hexField = FunctionBody(gold, "onHexField");
	Expect(CountOf(gold, "this.onHexField") == 1 && gold.find("this.hexBox.addEventListener(MouseEvent.CLICK,this.onHexField);") != std::string::npos &&
		InOrder(hexField, {"if(stage == null || !this.setOpen) { return; }", "if(stage.focus != this.hexBox)", "this.giveFocus(this.hexBox);",
			"this.hexBox.setSelection(0,this.hexBox.text.length);", "this.note(\"SETTINGS hex focus=\" + this.focusName(stage.focus));"}),
		"a click on the hex field gives it focus with the code selected, as the game's rename field does");
	const std::string closing = FunctionBody(gold, "closeSettings");
	Expect(InOrder(closing, {"var was:Boolean = this.setOpen;", "this.setOpen = false;", "if(stage == null) { return; }",
			"var held:String = this.focusName(stage.focus);", "if(held == \"hex\" || held == \"ours\")",
			"var list:InteractiveObject = this.nativeList();", "if(list != null && !this.chainShown(list)) { list = null; }", "this.giveFocus(list);",
			"if(was || held == \"hex\" || held == \"ours\") { this.note(\"SETTINGS close focus=\" + held + \">\" + this.focusName(stage.focus)); }"}),
		"closing Settings hands focus from our layer to the game list while it shows, else to nothing, and logs both holders");
	Expect(CountOf(closing, "giveFocus") == 1 && CountOf(closing, "held == \"hex\"") == 2, "Settings moves focus only when our layer holds it");
	const std::string holder = FunctionBody(gold, "focusName");
	Expect(InOrder(holder, {"if(param1 == null) { return \"none\"; }", "if(param1 == this.hexBox) { return \"hex\"; }",
			"if(this.contains(param1)) { return \"ours\"; }", "var list:DisplayObjectContainer = this.nativeList() as DisplayObjectContainer;",
			"if(list != null && list.contains(param1)) { return \"list\"; }", "return \"other\";"}) && CountOf(holder, "return") == 5,
		"the focus log names a kind, never a clip");
	const std::string wants = FunctionBody(gold, "wantsEvent", "public");
	Expect(InOrder(wants, {"if(!this.arranging && !this.setOpen) { return false; }", "if(param2) { return true; }",
			"if(param1 == \"Escape\" || param1 == \"Cancel\") { this.cancelTop(); return true; }",
			"if(param1 == \"Accept\" || param1 == \"Enter\") { if(this.arranging) { this.okArrange(); } return true; }"}) &&
		wants.find("!param2") == std::string::npos && CountOf(wants, "return false;") == 1,
		"Settings and Arrange swallow the press and act on the release, as the game's buttons do");
	const std::string guard = FunctionBody(gold, "isProtectedName");
	Expect(guard.find("\"categor\"") != std::string::npos && guard.find("\"list\"") != std::string::npos && guard.find("\"entry\"") != std::string::npos &&
		guard.find("\"scroll\"") != std::string::npos && guard.find("\"tab\"") != std::string::npos && guard.find("\"select\"") != std::string::npos &&
		guard.find("\"input\"") != std::string::npos && guard.find("\"button\"") != std::string::npos,
		"category, list, scroll, and input art is never faded");
	Expect(CountOf(gold, "BSUIDataManager.Subscribe(") == 1 && gold.find("BSUIDataManager.Subscribe(\"ModuleInfo\",this.onModuleInfo)") != std::string::npos,
		"the gold movie subscribes to ModuleInfo only");
	Expect(gold.find("BSUIDataManager.Unsubscribe") == std::string::npos && gold.find("BSUIDataManager.Flush") == std::string::npos,
		"the gold movie leaves the game's subscriptions alone");
	Expect(gold.find("data.aStats") != std::string::npos && gold.find("data.iModuleCost") != std::string::npos &&
		gold.find("data.iModuleMass") != std::string::npos && gold.find("data.sDescription") != std::string::npos &&
		gold.find("data.aRequiredAttributes") != std::string::npos, "the card reads the payload fields");
	Expect(gold.find("\"HsbModuleCard\"") != std::string::npos, "our card is a named Horizon node");
	Expect(gold.find("this.modCard.mouseEnabled = false;") != std::string::npos && gold.find("this.modCard.mouseChildren = false;") != std::string::npos,
		"our card takes no mouse");
	const std::string hold = FunctionBody(gold, "holdModule");
	const std::string seat = FunctionBody(gold, "seatModule");
	const std::string drop = FunctionBody(gold, "dropModule");
	Expect(hold.find("if(!this.paintSafe()) { return; }") < hold.find("param1.alpha = 0;") && hold.find("param1.alpha = 0;") != std::string::npos,
		"our card is painted before the game card is hidden");
	Expect(hold.find("this.modAlpha = param1.alpha > 0 ? param1.alpha : 1;") != std::string::npos, "a zero alpha is never kept");
	Expect(seat.find("if(param1.alpha != 0) { param1.alpha = 0; }") != std::string::npos && seat.find("param1 != this.modNative") != std::string::npos,
		"only the held game card is kept at alpha 0");
	Expect(drop.find("this.modNative.alpha = this.modAlpha;") != std::string::npos, "a drop puts the game card's alpha back");
	for (const std::string* body : {&hold, &seat, &drop}) {
		Expect(!body->empty() && body->find("param1.visible") == std::string::npos && body->find("modNative.visible") == std::string::npos &&
			body->find("removeChild") == std::string::npos && body->find("addChild(param1") == std::string::npos &&
			body->find("addChildAt(param1") == std::string::npos &&
			CountOf(*body, ".x =") == CountOf(*body, "this.modCard.x =") && CountOf(*body, ".y =") == CountOf(*body, "this.modCard.y =") &&
			body->find("param1.x") == std::string::npos && body->find("param1.y") == std::string::npos &&
			body->find("moveNative(") == std::string::npos && body->find("setChildIndex(param1") == std::string::npos,
			"the game card is hidden by alpha only and never moved or reparented");
	}
	Expect(gold.find("modNative.visible") == std::string::npos && gold.find("removeChild(this.modNative") == std::string::npos,
		"the game card's visible flag and parent are left to the menu");
	Expect(seat.find("parent.addChildAt(this.modCard,at + 1);") != std::string::npos, "our card sits right above the game card");
	Expect(seat.find("this.modCard.y = Math.round(y);\n         this.modCard.visible = true;") != std::string::npos &&
		seat.find("if(mine != at + 1) { parent.setChildIndex(this.modCard,mine > at ? at + 1 : at); }") != std::string::npos &&
		CountOf(seat, "setChildIndex(") == 1 && CountOf(seat, "addChildAt(") == 1,
		"a seat shows our card and keeps it right above the game card");
	Expect(FunctionBody(gold, "paintModule").find("g.drawRoundRect(1,1,w - 2,y - 2,12,12);\n         g.endFill();\n         this.modHigh = y;") != std::string::npos &&
		CountOf(gold, "this.modHigh = ") == 2, "the lift height is the painted background's full height");
	const std::string lift = FunctionBody(gold, "liftModule");
	Expect(lift.find("this.liftTop = param1.globalToLocal(this.localToGlobal(new Point(r.x,r.y))).y;") != std::string::npos &&
		lift.find("this.liftLow = param1.globalToLocal(this.localToGlobal(new Point(r.x,r.y + r.height))).y;") != std::string::npos,
		"the cached edges are the view's top and bottom in the card's parent");
	Expect(seat.find("this.arranging ? box.y : this.liftModule(parent,box.y,this.modHigh)") != std::string::npos &&
		gold.find("this.modView = r;") != std::string::npos && gold.find("this.modHigh = y;") != std::string::npos,
		"outside arrange a tall card is lifted onto the screen");
	Expect(lift.find("if(param2 + param3 <= this.liftLow) { return param2; }") != std::string::npos &&
		lift.find("return Math.max(this.liftTop,this.liftLow - param3);") != std::string::npos && CountOf(lift, "return") == 3 &&
		CountOf(lift, "return param2;") == 2, "the lift matches the twin");
	Expect(lift.find("this.view()") == std::string::npos && lift.find("if(r != this.liftView || param1 != this.liftParent)") != std::string::npos,
		"the per-frame lift reuses the cached view edges");
	Expect(FunctionBody(gold, "openArrange").find("this.arranging = true;\n         if(this.modOn) { this.seatModule(this.modNative); }") != std::string::npos,
		"arrange outlines our card where it will sit");
	Expect(FunctionBody(gold, "placeNative").find("this.seatModule(this.modNative)") != std::string::npos &&
		FunctionBody(gold, "moveLive").find("this.seatModule(this.modNative)") != std::string::npos &&
		FunctionBody(gold, "resetArrange").find("if(this.modOn) { this.seatModule(this.modNative); }") != std::string::npos &&
		FunctionBody(gold, "cancelArrange").find("if(this.modOn) { this.seatModule(this.modNative); }") != std::string::npos,
		"a saved spot, a drag, reset, and cancel bring our card back with the game card");
	Expect(FunctionBody(gold, "paintSafe").find("catch(err:Error)") != std::string::npos && FunctionBody(gold, "paintSafe").find("this.dropModule();") != std::string::npos,
		"a paint that throws drops our card");
	const std::string payload = FunctionBody(gold, "onModuleInfo");
	Expect(payload.find("this.syncModule();") != std::string::npos &&
		payload.find("if(was && this.modOn && this.paintSafe()) { this.seatModule(this.modNative); }") != std::string::npos,
		"a payload is shown or dropped at once and seated with its new height");
	Expect(payload.find("this.modFailed = false;") != std::string::npos && FunctionBody(gold, "moduleGate").find("if(this.modFailed) { return \"paint\"; }") != std::string::npos,
		"a failed paint holds the game card until the next payload");
	Expect(FunctionBody(gold, "moduleGate").find("if(this.arranging && !this.modOn) { return \"arrange\"; }") != std::string::npos,
		"arrange does not bring our card up");
	const std::string chipBody = FunctionBody(gold, "paintChip");
	const std::string putTag = "\n            this.put(tag,text,up ? 0x69FEB3 : 0xFF6868);";
	Expect(CountOf(chipBody, "if(tag.textWidth + " + std::to_string(hsb::kChipPadPx) + " > room)") == 2 &&
		chipBody.find("text = this.shortChip(text);" + putTag) != std::string::npos && chipBody.find("text = text.charAt(0);" + putTag) != std::string::npos,
		"a chip too wide for its room is shortened, never clipped");
	const std::string shortBody = FunctionBody(gold, "shortChip");
	Expect(shortBody.find("if(dot < 0 || param1.indexOf(\"e\") >= 0) { return param1.charAt(0); }") != std::string::npos &&
		shortBody.find("return whole.length == 2 && whole.charAt(1) == \"0\" ? param1.charAt(0) : whole;") != std::string::npos &&
		CountOf(shortBody, "return") == 2, "the movie shortens a chip as the twin does");
	Expect(FunctionBody(gold, "chipNumber").find("if(dot < 0 || text.indexOf(\"e\") >= 0) { return text; }") != std::string::npos,
		"the movie keeps toFixed's exponent text whole, as the twin does");
	Expect(gold.find("if(this.face.length == 0) { return \"face\"; }") != std::string::npos, "the card waits for a proven face");
	Expect(gold.find("Boolean(data.bShowWidget)") != std::string::npos && gold.find("this.chainShown(param1)") != std::string::npos,
		"the card follows the game card's visibility");
	Expect(gold.find("if(this.hangarShown()) { return \"hangar\"; }") != std::string::npos, "the hangar overview keeps the game card");
	Expect(gold.find("\"MODCARD \"") != std::string::npos && gold.find("\" keys=\"") != std::string::npos, "the card state is logged");
	Expect(gold.find("GlobalFunc.FormatNumberToString(Number(param1.fValue),2)") != std::string::npos, "stats use the game's two-place rule");
	Expect(gold.find("GlobalFunc.FormatNumberToString(Number(param1.fValue) * 100) + \"%\"") != std::string::npos, "percent stats match the game");
	Expect(gold.find("String.fromCharCode(param1.fValue)") != std::string::npos && gold.find("== \"$CLASS\"") != std::string::npos,
		"the class stat is a letter");
	Expect(gold.find("this.put(rank,\"$(Rank #)\"") != std::string::npos && gold.find("GlobalFunc.DoSubstitutions(rank.text,[param2.uRank])") != std::string::npos,
		"the rank is translated as the game writes it");
	Expect(gold.find("Math.min(stats.length,10)") != std::string::npos && gold.find("Math.min(skills.length,2)") != std::string::npos,
		"ten stats and two skills");
	const hsb::CardMetrics lrgCard = hsb::CardSize(true);
	const hsb::CardMetrics nrmCard = hsb::CardSize(false);
	using M = hsb::CardMetrics;
	Expect(gold.find("return " + Pick(lrgCard, nrmCard, &M::width) + ";") != std::string::npos &&
		gold.find("return " + Pick(lrgCard, nrmCard, &M::pad) + ";") != std::string::npos, "card width and padding come from the twin");
	Expect(gold.find("var pitch:Number = " + Pick(lrgCard, nrmCard, &M::rowPitch) + ";") != std::string::npos &&
		gold.find("var chipH:Number = " + Pick(lrgCard, nrmCard, &M::chipH) + ";") != std::string::npos &&
		gold.find("var barH:Number = " + Pick(lrgCard, nrmCard, &M::barH) + ";") != std::string::npos &&
		gold.find("var big:Number = " + Pick(lrgCard, nrmCard, &M::bigPx) + ";") != std::string::npos &&
		gold.find("this.cardText(" + Pick(lrgCard, nrmCard, &M::namePx) + ",true)") != std::string::npos &&
		gold.find("var head:int = " + Pick(lrgCard, nrmCard, &M::headPx) + ";") != std::string::npos &&
		gold.find("var body:int = " + Pick(lrgCard, nrmCard, &M::bodyPx) + ";") != std::string::npos &&
		gold.find("var small:int = " + Pick(lrgCard, nrmCard, &M::chipPx) + ";") != std::string::npos,
		"card text sizes and rows come from the twin");
	const std::string column = "this.lrg ? " + std::to_string(lrgCard.width - lrgCard.pad - lrgCard.valueRight) + " : " +
		std::to_string(nrmCard.width - nrmCard.pad - nrmCard.valueRight);
	Expect(gold.find("var right:Number = w - pad - (" + column + ");") != std::string::npos &&
		gold.find("var room:Number = (" + column + ") - " + std::to_string(hsb::kChipGapPx) + ";") != std::string::npos,
		"the value column and chip room come from the twin");
	Expect(gold.find("var chipW:Number = Math.min(Math.max(" + std::to_string(hsb::kChipMinPx) + ",tag.textWidth + " +
		std::to_string(hsb::kChipPadPx) + "),room);") != std::string::npos, "the chip width matches the twin");
	Expect(FunctionBody(gold, "diffText").find(
		"var size:String = param1.bPercentage ? this.chipNumber(Math.abs(diff) * 100,0) : this.chipNumber(Math.abs(diff),2);") != std::string::npos,
		"a percent chip is a whole percent and other chips keep two places, as in the twin");
	Expect(FunctionBody(gold, "chipNumber").find("param1.toFixed(6)") != std::string::npos && FunctionBody(gold, "diffText").find("if(size == \"0\") { return \"\"; }") != std::string::npos,
		"a chip never prints float noise");
	Expect(FunctionBody(gold, "diffText").find("FormatNumberToString") == std::string::npos, "the chip does not cut an exponent's digits");
	Expect(gold.find("this.putKey(this.modValueL,\"$VALUE\",\"VALUE\",") != std::string::npos && gold.find("this.putKey(this.modMassL,\"$MASS\",\"MASS\",") != std::string::npos,
		"value and mass use the game's label keys");
	Expect(gold.find("stackModule") == std::string::npos && gold.find("placeSlot") == std::string::npos && gold.find("this.moved") == std::string::npos,
		"the game card's fields are not moved");
	Expect(gold.find("return this.modCard.getBounds(this);") != std::string::npos, "arrange outlines our card");
	Expect(gold.find("return this.modNative.getBounds(this);") != std::string::npos, "module anchors use the game card's size");
	Expect(gold.find("Math.max(live.height,size.height)") != std::string::npos, "a drag keeps both boxes on screen");
	Expect(gold.find("Swap cost") == std::string::npos && gold.find("Hab 2x2") == std::string::npos, "the card prints no mock-only text");
	Expect(readme.find("MODCARD on") != std::string::npos && readme.find("FONT try=") != std::string::npos, "the readme names the card and face log lines");
	Expect(readme.find("_lrg") != std::string::npos && readme.find("ModuleInfo") != std::string::npos, "the readme covers the large movie and the card's data");
	Expect(readme.find("MODCARD listen ok") != std::string::npos && readme.find("`paint`") != std::string::npos && readme.find("`arrange`") != std::string::npos,
		"the readme lists every card state");
	Expect(readme.find("`MODVALS`") != std::string::npos && readme.find("this mod removed") != std::string::npos,
		"the readme says how to compare the card with the payload");
	Expect(readme.find("interface/spaceshipeditormenu_lrg.swf") != std::string::npos && readme.find("Creations included") != std::string::npos &&
		readme.find("another mod adds") != std::string::npos && readme.find("arrow keys still move the parts list") != std::string::npos,
		"the readme checks other plugins' movies, keeps other mods for the comparison, and checks list keys after the hex field");
	Expect(readme.find("`SETTINGS hex focus=hex`") != std::string::npos && readme.find("`SETTINGS close focus=`") != std::string::npos &&
		readme.find("after must read `list`") != std::string::npos && readme.find("It never reads `hex` or `ours`.") != std::string::npos,
		"the readme gates the focus hand-back on log lines");
	Expect(readme.find("act when the button is released") != std::string::npos, "the readme checks that Esc and B close our panels and do nothing else");
	Expect(gold.find("this.note(\"MODVALS \" + this.modVals[v]);") != std::string::npos && gold.find("this.modValsLeft = 24;") != std::string::npos,
		"payload numbers and shown text are logged for a bounded number of modules");
	Expect(!NotesHideFaces("         this.note(\"FONT face=\" + fmt.font);") && !NotesHideFaces("         this.note(\"FONT list=\" + FACES.join(\",\"));") &&
		!NotesHideFaces("         this.lines.push(\"FONT \" + this.face);") && NotesHideFaces("         this.note(\"FONT try=\" + this.faceTries);"),
		"the face scan catches a face name in a log line");

	Expect(probe.find("enableDebug") != std::string::npos, "probe can be turned on");
	Expect(probe.find("PROBE off") != std::string::npos, "probe stays quiet by default");
	Expect(splice.find("import HorizonShipBuilder;") != std::string::npos, "gold import");
	Expect(splice.find("hsbApply") != std::string::npos, "apply splice");
	Expect(splice.find("hsbFeed") != std::string::npos, "feed splice");

	const std::string rc = ReadFile(root / "res" / "HorizonShipBuilder.rc.in");
	Expect(rc.find("Horizon Ship Builder") != std::string::npos, "product name is the builder");
	Expect(rc.find("0.43") == std::string::npos, "the builder resource does not inherit the hud version");

	const std::string defaults = ReadFile(root / "Interface" / "HorizonUI" / "shipbuilder" / "HorizonShipBuilder.default.ini");
	Expect(defaults.find("AccentColor=9") != std::string::npos, "default accent index");
	Expect(defaults.find("Probe=0") != std::string::npos, "probe defaults off");

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "probe_logic_test passed\n";
	return 0;
}
