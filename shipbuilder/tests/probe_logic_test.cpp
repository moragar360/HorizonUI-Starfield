// Purpose: check the probe's read-only rules without the game.
// Author: Moragar. Last modified: 2026-11-07.

#include "hsb_arrange.h"
#include "hsb_card.h"
#include "hsb_face.h"
#include "hsb_guard.h"
#include "hsb_interior.h"
#include "hsb_version.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <sstream>
#include <string>

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
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Hidden, "the card follows the show flag");
	state.showWidget = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::Hidden, "the card follows the game card's visibility");
	state.nativeShown = true;
	Expect(hsb::ModuleCardGate(state) == hsb::CardGate::On, "a shown game card with data brings ours up");
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
	Expect(hsb::CardSeat(home, normal.width, 400).x == home.x, "reset and cancel put our card back on the game card's home");

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

// Lines that build log text may carry candidate tags and metrics, never a face name.
static bool NotesHideFaces(const std::string& source)
{
	std::istringstream in(source);
	std::string line;
	while (std::getline(in, line)) {
		const bool logs = line.find("this.note(") != std::string::npos || line.find("report +=") != std::string::npos
			|| line.find("line +=") != std::string::npos || line.find("var report") != std::string::npos
			|| line.find("var line") != std::string::npos;
		if (!logs) continue;
		if (line.find("FACES[") != std::string::npos || line.find("names[") != std::string::npos
			|| line.find("labelFace") != std::string::npos || line.find("fieldFace(") != std::string::npos)
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
	Expect(gold.find("param1.alpha = 0;") != std::string::npos && gold.find("this.modNative.alpha = this.modAlpha;") != std::string::npos,
		"the game card is hidden in place and its alpha comes back");
	Expect(gold.find("modNative.visible") == std::string::npos, "the game card's visible flag is left to the menu");
	Expect(gold.find("parent.addChildAt(this.modCard,at + 1);") != std::string::npos, "our card sits right above the game card");
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
	Expect(gold.find("return this.lrg ? 410 : 350;") != std::string::npos && gold.find("return this.lrg ? 20 : 18;") != std::string::npos,
		"card width and padding match the twin");
	Expect(gold.find("var pitch:Number = this.lrg ? 34 : 30;") != std::string::npos && gold.find("var chipH:Number = this.lrg ? 26 : 22;") != std::string::npos &&
		gold.find("var barH:Number = this.lrg ? 28 : 24;") != std::string::npos && gold.find("var right:Number = w - pad - (this.lrg ? 80 : 67);") != std::string::npos &&
		gold.find("this.cardText(this.lrg ? 24 : 21,true)") != std::string::npos, "card metrics match the twin");
	Expect(gold.find("stackModule") == std::string::npos && gold.find("placeSlot") == std::string::npos && gold.find("this.moved") == std::string::npos,
		"the game card's fields are not moved");
	Expect(gold.find("return this.modCard.getBounds(this);") != std::string::npos, "arrange outlines our card");
	Expect(gold.find("return this.modNative.getBounds(this);") != std::string::npos, "module anchors use the game card's size");
	Expect(gold.find("Math.max(live.height,size.height)") != std::string::npos, "a drag keeps both boxes on screen");
	Expect(CountOf(gold, "if(this.modOn) { this.seatModule(this.modNative); }") >= 3, "arrange, reset, and cancel bring our card back with the game card");
	Expect(gold.find("Swap cost") == std::string::npos && gold.find("Hab 2x2") == std::string::npos, "the card prints no mock-only text");
	Expect(readme.find("MODCARD on") != std::string::npos && readme.find("FONT try=") != std::string::npos, "the readme names the card and face log lines");
	Expect(readme.find("_lrg") != std::string::npos && readme.find("ModuleInfo") != std::string::npos, "the readme covers the large movie and the card's data");

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
