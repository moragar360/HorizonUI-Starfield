// Purpose: host checks for Horizon Ship Builder 0.2 without the game. Part one runs the
//    plugin's pure rules (input, files, settings, log guard, face proof, number twins). Part two
//    pins the movie, the plugin, the splice notes, the README and the package to each other, so
//    a change on one side that the other side does not follow fails here.
// Inputs: the repo tree (HSB_REPO_ROOT, else this file's location).
// Outputs: one FAIL line per broken check; exit code 0 only when every check passes.
// Dependencies: shipbuilder/src headers; std::filesystem (this test only).
// Author: Moragar. Last modified: 2026-11-08.

#include "hsb_arrange.h"
#include "hsb_card.h"
#include "hsb_face.h"
#include "hsb_files.h"
#include "hsb_guard.h"
#include "hsb_input.h"
#include "hsb_profile.h"
#include "hsb_settings.h"
#include "hsb_version.h"

#include <algorithm>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <map>
#include <set>
#include <sstream>
#include <string>
#include <vector>

namespace fs = std::filesystem;

static int g_fails = 0;

static void Expect(bool ok, const std::string& text)
{
	if (ok) return;
	std::cerr << "FAIL: " << text << "\n";
	++g_fails;
}

// Path checks are string checks. The prefix is the process temp directory, so the fixture
// is not a real profile path.
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

static std::size_t CountOf(const std::string& text, const std::string& needle)
{
	std::size_t n = 0;
	for (std::size_t at = text.find(needle); at != std::string::npos; at = text.find(needle, at + needle.size())) ++n;
	return n;
}

static bool Has(const std::string& text, const std::string& needle)
{
	return text.find(needle) != std::string::npos;
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

// One plugin function, from its head through the first closing brace at column 0.
static std::string CppBody(const std::string& source, const std::string& head)
{
	const std::size_t at = source.find(head);
	if (at == std::string::npos) return {};
	const std::size_t end = source.find("\n}\n", at);
	return source.substr(at, end == std::string::npos ? std::string::npos : end + 3 - at);
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

static std::string ReadFile(const fs::path& path)
{
	std::ifstream in(path, std::ios::binary);
	return std::string(std::istreambuf_iterator<char>(in), std::istreambuf_iterator<char>());
}

static bool HasNul(const std::string& text)
{
	return text.find('\0') != std::string::npos;
}

// ---- log guard -------------------------------------------------------------------------

static void CheckGuard()
{
	const std::string docs = DocsTail('\\');
	const std::string docsSlash = DocsTail('/');
	Expect(hsb::ProbeMayAppend(docs + "SFSE\\Logs\\" + hsb::kProbeFile), "documents log is allowed");
	Expect(hsb::ProbeMayAppend(docsSlash + "SFSE/Logs/" + hsb::kProbeFile), "forward-slash log is allowed");
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
	Expect(hsb::NextFormSlot(0) == 1 && hsb::NextFormSlot(39) == 40 && hsb::NextFormSlot(40) == -1, "form lookups are capped at 40");
	Expect(hsb::ProbePollDue(1000, 0) && !hsb::ProbePollDue(100, 100), "first poll is due, the same stamp is not");
	Expect(hsb::ProbePollDue(1000, 1000 - hsb::kProbePollMs) && !hsb::ProbePollDue(1000, 999), "polls wait the modest interval");
	Expect(hsb::HookWasRipped(true, false) && !hsb::HookWasRipped(true, true) && !hsb::HookWasRipped(false, false), "a missed ping clears the hook");
	Expect(hsb::ChainIsLive(reinterpret_cast<const void*>(1)) && !hsb::ChainIsLive(nullptr), "an empty chain is not live");
	const std::string dirty = hsb::FactLine("F16", "line\r\nnext");
	Expect(!Has(dirty, "\n") && !Has(dirty, "\r"), "facts stay on one line");
	Expect(hsb::kMenuName == std::string("SpaceshipEditorMenu"), "menu name");

	const std::string iniPath = docs + "Data\\Interface\\HorizonUI\\shipbuilder\\HorizonShipBuilder.user.ini";
	Expect(hsb::IniMayWrite(iniPath), "the user ini path is allowed");
	Expect(!hsb::IniMayWrite(std::string("D:\\Steam\\steamapps\\common\\Starfield\\Data\\Interface\\HorizonUI\\shipbuilder\\") + "HorizonShipBuilder.user.ini"),
		"the game folder ini is refused");
	Expect(!hsb::IniMayWrite(docs + "Data\\Interface\\HorizonUI\\shipbuilder\\other.ini"), "another ini name is refused");
}

// ---- face proof and text size twins -----------------------------------------------------

static void CheckFace()
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
		{boxes, hsb::FaceKind::Embed, true, 1, 0},
		{grotesk, hsb::FaceKind::Embed, true, 1, 0},
		{{148, 40, 24}, hsb::FaceKind::Embed, true, 0, 0},
		{{}, hsb::FaceKind::Native, false, 0, 0},
		{grotesk, hsb::FaceKind::Device, true, 0, 0},
		{grotesk, hsb::FaceKind::Device, true, 0, 0},
		{grotesk, hsb::FaceKind::Device, true, 0, 0},
	};
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 0, "hasGlyphs picks an embedded face even when W and i share an advance");
	order[0].glyphs = 0;
	order[1].glyphs = 0;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 4, "device text is tried only after embedded faces lack the probe glyphs");
	order[3] = {boxes, hsb::FaceKind::Native, true, 0, 1};
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 4, "a native face with missing glyphs is refused even when it has ink");
	order[3].glyphs = -1;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 3, "an unlisted native face with real ink is kept");
	order[3].draw = 0;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 4, "an unlisted native face with no ink is skipped");
	order[3].draw = -1;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 4, "a zero-size native field is not ink");
	order[3].draw = -2;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 4, "a native sample that throws is not ink");
	order[3].glyphs = 1;
	order[3].draw = 0;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 3, "a native face that covers the probe is kept without ink");
	order[3].draw = -2;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == 3, "a native face that covers the probe is kept when the sample throws");
	order[3].glyphs = 0;
	order[3].draw = 1;
	for (auto& c : order) c.measure = boxes;
	Expect(hsb::PickFace(order, 7, boxes, boxes) == -1, "no proof leaves the default text path");
	Expect(hsb::PickFace(nullptr, 7, boxes, boxes) == -1, "no list is no proof");

	Expect(hsb::TextPx(13, false) == 13 && hsb::TextPx(13, true) == 16, "body text is 13 px, 16 px in the large movie");
	Expect(hsb::TextPx(12, false) == 12 && hsb::TextPx(12, true) == 15, "captions are 12 px, 15 px in the large movie");
	Expect(hsb::TextPx(10, false) == 12 && hsb::TextPx(10, true) == 15, "nothing drops below the caption floor");
	Expect(hsb::TextPx(14, true) == 17 && hsb::TextPx(21, false) == 21, "larger text scales by 1.2 with Math.round");
}

// ---- number, chip and anchor twins -------------------------------------------------------

static void CheckNumbers()
{
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
	Expect(hsb::ChipNumber(1.5e21, 2) == "1.5e+21" && hsb::ChipNumber(std::numeric_limits<double>::infinity(), 2) == "Infinity",
		"a chip keeps toFixed's exponent text whole");

	const hsb::CardStat hab[] = {{"$HULL", 5, 0, false}, {"$PASSENGER_SLOTS", 0, 0, false}, {"$CREW_STATIONS", 6, 6, false}};
	Expect(hsb::StatValueText(hab[0]) == "5" && hsb::StatValueText(hab[1]) == "0" && hsb::StatValueText(hab[2]) == "6", "hab stats read as the game card");
	Expect(hsb::DiffChipText(hab[0]).empty() && hsb::DiffChipText(hab[2]) == "+6", "only a changed hab stat gets a chip");
	Expect(hsb::ToneOf(hab[2].diff) == hsb::DiffTone::Higher, "a higher stat uses the higher tone");
	const hsb::CardStat weapon[] = {{"$HULL_DMG", 13, 0, false}, {"$MAX_POWER", 4, 1, false}, {"Hull", 1, -2, false}, {"$FIRE_RATE", 0.83333, -0.25, false}};
	Expect(hsb::StatValueText(weapon[0]) == "13" && hsb::StatValueText(weapon[3]) == "0.83", "weapon stats read as the game card");
	Expect(hsb::DiffChipText(weapon[1]) == "+1" && hsb::DiffChipText(weapon[2]) == "-2" && hsb::DiffChipText(weapon[3]) == "-0.25",
		"weapon diffs keep the value's places");
	Expect(hsb::ToneOf(weapon[2].diff) == hsb::DiffTone::Lower, "a lower stat uses the lower tone");
	const hsb::CardStat reactor[] = {{"$CLASS", 66, 1, false}, {"$REPAIR", 0.125, 0.05, true}, {"$SHIELD_REGEN", 0.07, 0, true}};
	Expect(hsb::StatValueText(reactor[0]) == "B" && hsb::DiffChipText(reactor[0]) == "+", "the class stat is a letter and its chip a sign");
	Expect(hsb::StatValueText(reactor[1]) == "12%" && hsb::DiffChipText(reactor[1]) == "+5%", "a percent stat is cut to a whole percent");
	Expect(hsb::StatValueText(reactor[2]) == "7%", "a percent with float noise reads as a whole percent");
	Expect(hsb::CharCodeText(77) == "M" && hsb::CharCodeText(65.9) == "A", "class letters come from the char code");
	Expect(hsb::ToneOf(std::numeric_limits<double>::quiet_NaN()) == hsb::DiffTone::Same && hsb::ToneOf(-0.0) == hsb::DiffTone::Same,
		"a missing diff is the default frame");
	Expect(hsb::DiffChipText({"$HULL", 5, 1.1920928955078125e-07, false}).empty() && hsb::DiffChipText({"$REPAIR", 0.125, 5e-9, true}).empty(),
		"float noise in a diff gets no chip");
	Expect(hsb::DiffChipText({"$MASS_LIMIT", 1, -0.004, false}).empty(), "a diff below two places gets no chip");
	Expect(hsb::DiffChipText({"$HULL", 5, 0.1 + 0.2, false}) == "+0.3", "a chip has no float tail");
	Expect(hsb::ShortChip("+1234.56") == "+1234" && hsb::ShortChip("+9.5") == "+9", "a chip too wide drops its places");
	Expect(hsb::ShortChip("-0.25") == "-" && hsb::ShortChip("+12345%") == "+" && hsb::ShortChip("+Infinity") == "+" && hsb::ShortChip("+1.5e+21") == "+",
		"a short chip never reads as no change or a wrong number");
	Expect(hsb::CardStatRows(11) == 10 && hsb::CardStatRows(-1) == 0 && hsb::CardSkillRows(3) == 2, "the card shows up to ten stats and two skills");
	Expect(hsb::Substitute("Rank {0}", {"2"}) == "Rank 2" && hsb::Substitute("$(Rank #)", {"2"}) == "$(Rank #)", "substitutions follow DoSubstitutions");

	// Anchors round-trip at 1080p and on a wide screen.
	const int margin = hsb::kMarginDefault;
	Expect(hsb::StoreAnchor(true, 34, 350, 0, 1920, margin) == "L0" && hsb::ResolveAnchor(true, "L0", 0, 350, 0, 1920, margin) == 34,
		"a panel at the left margin stores L0");
	Expect(hsb::StoreAnchor(true, 785, 350, 0, 1920, margin) == "C0" && hsb::ResolveAnchor(true, "C0", 0, 350, 0, 1920, margin) == 785,
		"a centred panel stores C0");
	Expect(hsb::StoreAnchor(true, 1386, 500, 0, 1920, margin) == "R0" && hsb::ResolveAnchor(true, "R0", 0, 500, 0, 1920, margin) == 1386,
		"a panel at the right margin stores R0");
	Expect(hsb::StoreAnchor(false, 900, 96, 0, 1080, margin) == "B50" && hsb::ResolveAnchor(false, "B50", 0, 96, 0, 1080, margin) == 900,
		"a footer stores its distance from the bottom");
	Expect(hsb::ResolveAnchor(true, "-1", 77, 350, 0, 1920, margin) == 77 && hsb::ResolveAnchor(true, "Q5", 77, 350, 0, 1920, margin) == 77 &&
		hsb::ResolveAnchor(true, "Lx", 77, 350, 0, 1920, margin) == 77, "a default or unreadable anchor keeps the current spot");
	for (int x : {0, 120, 700, 1200, 2100}) {
		const std::string a = hsb::StoreAnchor(true, x, 420, 0, 2560, margin);
		Expect(hsb::ResolveAnchor(true, a, -999, 420, 0, 2560, margin) == x, "a wide-screen anchor round-trips at x=" + std::to_string(x));
	}
}

// ---- window input rules (hsb_input.h) -------------------------------------------------------

static void CheckInput()
{
	hsb::HotArea area = hsb::ParseHot("all");
	Expect(area.all && hsb::HotContains(area, -5000, 9000), "HOT all swallows everywhere");
	area = hsb::ParseHot("none");
	Expect(!area.all && area.rects.empty() && !hsb::HotContains(area, 10, 10), "HOT none swallows nothing");
	Expect(hsb::ParseHot("").rects.empty(), "an empty HOT body swallows nothing");
	area = hsb::ParseHot("10,20,300,400;5,5,0,10;1,2,3;a,b,c,d;-5,-6,7,8;1,2,30000,4;");
	Expect(area.rects.size() == 2 && area.rects[1].x == -5 && area.rects[1].y == -6, "bad rectangles are skipped and good ones kept");
	Expect(hsb::HotContains(area, 10, 20) && hsb::HotContains(area, 309, 419), "a rectangle includes its top-left and last pixel");
	Expect(!hsb::HotContains(area, 310, 20) && !hsb::HotContains(area, 9, 20) && !hsb::HotContains(area, 10, 420), "a rectangle excludes its far edges");
	{
		std::string many;
		for (int i = 0; i < 40; ++i) many += (i ? ";" : "") + std::to_string(i * 10) + ",0,5,5";
		Expect(static_cast<int>(hsb::ParseHot(many).rects.size()) == hsb::kMaxHotRects, "at most 32 rectangles are kept");
	}

	int sx = 0;
	int sy = 0;
	hsb::ClientToStage(1280, 720, 2560, 1440, hsb::StageView{}, sx, sy);
	Expect(sx == 960 && sy == 540, "1440p client maps to the 1080p stage");
	hsb::ClientToStage(2559, 1439, 2560, 1440, hsb::StageView{}, sx, sy);
	Expect(sx == 1919 && sy == 1079, "the last client pixel maps inside the stage");
	hsb::ClientToStage(0, 0, 3440, 1440, hsb::StageView{-330, 0, 2580, 1080}, sx, sy);
	Expect(sx == -330 && sy == 0, "a wide view starts left of the stage");
	hsb::ClientToStage(5, 5, 0, 0, hsb::StageView{}, sx, sy);
	Expect(sx == 9600 && sy == 5400, "a zero client size does not divide by zero");

	hsb::InputState prev;
	hsb::InputState s = hsb::ParseState("STATE capture=1 text=0 arrange=0 stage=2560x1440 view=0,0,1920,1080 keys=1 hide=72 find=47", prev);
	Expect(s.capture && !s.text && !s.arrange && s.arrangeKey && s.hideChar == 72 && s.findChar == 47, "STATE flags and keys parse");
	Expect(s.stageW == 2560 && s.stageH == 1440 && s.view.w == 1920 && s.view.h == 1080, "STATE stage and view parse");
	hsb::InputState t = hsb::ParseState("STATE text=1 hide=999 find=x view=0,0,50,50", s);
	Expect(t.capture && t.text && t.hideChar == 0 && t.findChar == 47 && t.view.w == 1920, "a missing or bad field keeps or clears safely");
	Expect(!hsb::ParseState("STATE keys=0", s).arrangeKey, "keys=0 turns Ctrl+L off");

	hsb::PointerCall c = hsb::PointerEdge(true, false, false, true, false);
	Expect(c.eat && c.feed, "a press inside a Horizon panel is swallowed and fed");
	c = hsb::PointerEdge(true, false, false, false, false);
	Expect(!c.eat && c.feed, "a press outside is fed and reaches the game");
	c = hsb::PointerEdge(false, true, false, false, true);
	Expect(c.eat && c.feed, "a release follows its swallowed press, wherever it lands");
	c = hsb::PointerEdge(false, true, false, true, false);
	Expect(!c.eat && c.feed, "a release whose press the game saw reaches the game, even over a panel");
	c = hsb::PointerEdge(false, false, true, true, false);
	Expect(c.eat && c.feed, "the wheel over a panel is swallowed");
	c = hsb::PointerEdge(false, false, true, false, false);
	Expect(!c.eat && c.feed, "the wheel over the ship reaches the game");
	Expect(!hsb::PointerEdge(false, false, false, true, true).feed, "nothing else is fed");
	Expect(hsb::MoveEdge().feed && !hsb::MoveEdge().eat, "moves are fed and never swallowed");

	const struct {
		unsigned vk;
		bool shift;
		const char* token;
	} nav[] = {
		{hsb::kVkEscKey, false, "cancel"}, {hsb::kVkReturnKey, false, "ok"}, {hsb::kVkLeftKey, false, "left"}, {hsb::kVkLeftKey, true, "left40"},
		{hsb::kVkRightKey, true, "right40"}, {hsb::kVkUpKey, false, "up"}, {hsb::kVkDownKey, true, "down40"}, {hsb::kVkTabKey, false, "tab"},
		{hsb::kVkTabKey, true, "tabprev"}, {hsb::kVkPriorKey, false, "pgup"}, {hsb::kVkNextKey, false, "pgdn"}, {hsb::kVkBackKey, false, "bksp"},
		{hsb::kVkDeleteKey, false, "del"}, {'G', false, ""}, {0x70, false, ""},
	};
	for (const auto& n : nav) Expect(std::string(hsb::NavToken(n.vk, n.shift)) == n.token, std::string("nav token ") + n.token);

	hsb::InputState idle;
	idle.hideChar = 'H';
	idle.findChar = '/';
	auto press = [](unsigned vk, int ch, bool ctrl, bool alt, bool shift, bool repeat, const hsb::InputState& st) {
		return hsb::KeyPress(vk, ch, ctrl, alt, shift, repeat, st);
	};
	hsb::KeyCall k = press('H', 'H', false, false, false, false, idle);
	Expect(k.eat && std::string(k.token) == "hide", "the hide key is taken when nothing is open");
	k = press(0xBF, '/', false, false, false, false, idle);
	Expect(k.eat && std::string(k.token) == "find", "the find key is taken when nothing is open");
	k = press('G', 'G', false, false, false, false, idle);
	Expect(!k.eat && std::string(k.token).empty(), "a builder key reaches the game when nothing is open");
	k = press(hsb::kVkEscKey, 27, false, false, false, false, idle);
	Expect(!k.eat, "Esc reaches the game when nothing is open");
	k = press('L', 'L', true, false, false, false, idle);
	Expect(k.eat && std::string(k.token) == "open", "Ctrl+L opens Arrange");
	hsb::InputState noArrange = idle;
	noArrange.arrangeKey = false;
	Expect(!press('L', 'L', true, false, false, false, noArrange).eat, "Ctrl+L reaches the game when Settings turned it off");
	Expect(!press('H', 'H', true, false, false, false, idle).eat, "Ctrl+H is not the hide key");
	Expect(!press('H', 'H', false, false, false, true, idle).eat, "a held hide key does not repeat");
	Expect(!press('H', 'H', false, true, false, false, idle).eat, "Alt+H reaches the game");
	hsb::InputState off = idle;
	off.hideChar = 0;
	Expect(!press('H', 'H', false, false, false, false, off).eat, "a hide key the game uses (sent as 0) reaches the game");

	hsb::InputState cap;
	cap.capture = true;
	k = press(hsb::kVkEscKey, 27, false, false, false, false, cap);
	Expect(k.eat && std::string(k.token) == "cancel", "Esc in a popup is swallowed and cancels");
	k = press(hsb::kVkEscKey, 27, false, false, false, true, cap);
	Expect(k.eat && std::string(k.token).empty(), "a held Esc is swallowed without cancelling twice");
	k = press('G', 'G', false, false, false, false, cap);
	Expect(k.eat && std::string(k.token).empty(), "a builder key is swallowed while a popup is open");
	k = press(hsb::kVkLeftKey, 0, false, false, true, true, cap);
	Expect(k.eat && std::string(k.token) == "left40", "held arrows repeat in a popup");
	Expect(!press(0x73, 0, false, true, false, false, cap).eat, "Alt+F4 reaches Windows with a popup open");
	Expect(!press(hsb::kVkLWinKey, 0, false, false, false, false, cap).eat && !press(hsb::kVkRWinKey, 0, false, false, false, false, cap).eat,
		"the Windows keys reach Windows");
	Expect(!press(hsb::kVkSnapshotKey, 0, false, false, false, false, cap).eat, "Print Screen reaches Windows");
	Expect(!press('Q', 'Q', true, true, false, false, cap).eat, "Ctrl+Alt outside a text field is an Alt combination");
	hsb::InputState text;
	text.text = true;
	Expect(press('Q', 'Q', true, true, false, false, text).eat, "AltGr in a text field types, so it is swallowed");
	Expect(!press(0x09, 9, false, true, false, false, text).eat, "Alt+Tab reaches Windows from a text field");
	hsb::InputState arrange;
	arrange.arrange = true;
	Expect(press(hsb::kVkUpKey, 0, false, false, false, false, arrange).eat, "Arrange swallows its keys");

	Expect(hsb::CharForText('a', text) && hsb::CharForText(0xE9, text) && !hsb::CharForText(31, text) && !hsb::CharForText(127, text) &&
		!hsb::CharForText(0xD800, text), "a text field gets printable characters only");
	Expect(!hsb::CharForText('a', cap), "characters go nowhere without a text field");

	int rest = 0;
	Expect(hsb::WheelSteps(120, rest) == 1 && rest == 0, "one notch is one step");
	Expect(hsb::WheelSteps(60, rest) == 0 && rest == 60 && hsb::WheelSteps(60, rest) == 1 && rest == 0, "half notches add up");
	Expect(hsb::WheelSteps(-240, rest) == -2 && rest == 0, "two notches down are two steps");
	Expect(hsb::WheelSteps(-60, rest) == 0 && hsb::WheelSteps(-60, rest) == -1 && rest == 0, "half notches down add up");
	rest = 60;
	Expect(hsb::WheelSteps(-120, rest) == 0 && rest == -60, "a reversed wheel keeps its remainder");

	hsb::InputCounts counts{1, 2, 3, 4, 5, 6, 7};
	Expect(hsb::CountsLine(counts) == "presses=1 eaten=2 wheel=3 keys=4 chars=5 dropped=6 raw=7", "the close line is counts only");

	hsb::PressLedger ledger;
	ledger.Set(hsb::kVkEscKey, true);
	ledger.Set(300, true);
	Expect(ledger.Held(hsb::kVkEscKey) && !ledger.Held(hsb::kVkReturnKey) && !ledger.Held(300), "the ledger keeps key codes only");
	ledger.Set(hsb::kVkEscKey, false);
	Expect(!ledger.Held(hsb::kVkEscKey), "a release clears its key");
	ledger.Set(hsb::kVkLeftKey, true);
	ledger.Clear();
	Expect(!ledger.Held(hsb::kVkLeftKey), "clearing forgets every key");
	Expect(!hsb::IsProbeHotkey(false, hsb::kVkF6) && hsb::IsProbeHotkey(true, hsb::kVkF7) && !hsb::IsProbeHotkey(true, 0x78),
		"probe keys exist only with Probe=1, and F9 is never one");
}

// ---- user ini whitelist and merge (hsb_settings.h) ---------------------------------------

static bool Accepts(const char* section, const char* key, const char* value, const char* canon = nullptr, int isDefault = -1)
{
	hsb::Setting s;
	if (!hsb::CheckSetting(section, key, value, s)) return false;
	if (canon && s.value != canon) return false;
	if (isDefault >= 0 && s.isDefault != (isDefault == 1)) return false;
	return true;
}

static void CheckSettings()
{
	Expect(Accepts("Style", "AccentColor", "9", "9", 1) && Accepts("style", "accentcolor", " 3 ", "3", 0) && Accepts("Style", "AccentColor", "-1", "-1", 0),
		"AccentColor takes -1 to 13, 9 is the default");
	Expect(!Accepts("Style", "AccentColor", "14") && !Accepts("Style", "AccentColor", "-2") && !Accepts("Style", "AccentColor", "x"), "AccentColor refuses others");
	Expect(Accepts("Style", "AccentHex", "", "", 1) && Accepts("Style", "AccentHex", "#a1b2c3", "A1B2C3", 0), "AccentHex is empty or six hex digits");
	Expect(!Accepts("Style", "AccentHex", "zzzzzz") && !Accepts("Style", "AccentHex", "12345"), "AccentHex refuses others");
	Expect(Accepts("Style", "CardOpacity", "1", "1.00", 1) && Accepts("Style", "CardOpacity", "0.85", "0.85", 0) && Accepts("Style", "CardOpacity", "0.4", "0.40", 0),
		"CardOpacity is 0.40 to 1.00 with two places");
	Expect(!Accepts("Style", "CardOpacity", "0.39") && !Accepts("Style", "CardOpacity", "1.01") && !Accepts("Style", "CardOpacity", "0.855") &&
		!Accepts("Style", "CardOpacity", "-1") && !Accepts("Style", "CardOpacity", "."), "CardOpacity refuses others");
	Expect(Accepts("Layout", "ScreenMargin", "34", "34", 1) && Accepts("Layout", "ScreenMargin", "0") && Accepts("Layout", "ScreenMargin", "120"),
		"ScreenMargin is 0 to 120");
	Expect(!Accepts("Layout", "ScreenMargin", "121") && !Accepts("Layout", "ScreenMargin", "-1"), "ScreenMargin refuses others");
	Expect(Accepts("Layout", "UiScale", "1.00", "1.00", 1) && Accepts("Layout", "UiScale", "0.8", "0.80", 0) && Accepts("Layout", "UiScale", "1.3", "1.30", 0),
		"UiScale is 0.80 to 1.30");
	Expect(!Accepts("Layout", "UiScale", "1.31") && !Accepts("Layout", "UiScale", "0.79"), "UiScale refuses others");
	Expect(Accepts("Layout", "Density", "compact", "compact", 1) && Accepts("Layout", "Density", "Detailed", "detailed", 0) && !Accepts("Layout", "Density", "big"),
		"Density is compact or detailed");
	Expect(Accepts("Layout", "GroupByMaker", "0", "0", 1) && Accepts("Layout", "GroupByMaker", "1", "1", 0) && !Accepts("Layout", "GroupByMaker", "2") &&
		Accepts("Layout", "RememberLayout", "1", "1", 1) && Accepts("Layout", "RememberLayout", "0", "0", 0), "flags are 0 or 1");
	Expect(Accepts("Panels", "power", "0", "0", 0) && Accepts("Panels", "Cluster", "1", "1", 1) && !Accepts("Panels", "Colors", "0") && !Accepts("Panels", "Power", "yes"),
		"Panels holds the seven panel ids as 0 or 1");
	{
		hsb::Setting p;
		Expect(hsb::CheckSetting("Panels", "power", "0", p) && p.key == "Power", "panel ids are written in canonical case");
	}
	Expect(Accepts("Notices", "ShowConflictNotice", "1", "1", 1) && Accepts("Notices", "ShowConflictNotice", "0", "0", 0) && !Accepts("Notices", "Other", "0"),
		"Notices holds the StarUI notice only");
	Expect(Accepts("Keys", "Arrange", "l", "L", 1) && Accepts("Keys", "Arrange", "0", "0", 0) && !Accepts("Keys", "Arrange", "K"), "Arrange is L or 0");
	Expect(Accepts("Keys", "HideAll", "h", "H", 1) && Accepts("Keys", "HideAll", "J", "J", 0) && Accepts("Keys", "HideAll", "0", "0", 0) &&
		Accepts("Keys", "Find", "/", "/", 1) && Accepts("Keys", "Find", "\\", "\\", 0) && Accepts("Keys", "Find", "=", "=", 0), "hotkeys are one bindable key or 0");
	Expect(!Accepts("Keys", "HideAll", ";") && !Accepts("Keys", "HideAll", "#") && !Accepts("Keys", "HideAll", "HH") && !Accepts("Keys", "Other", "J"),
		"hotkeys refuse ini comment characters, words and other names");
	Expect(Accepts("Columns", "Habs", "", "", 1) && Accepts("Columns", "Habs", "Value,Mass", "Value,Mass", 0) && Accepts("Columns", "HabsSort", "Value-", "Value-", 0),
		"Columns holds column lists and sorts");
	Expect(!Accepts("Columns", "Habs", "Value,,Mass") && !Accepts("Columns", "Habs", "a,b,c,d,e,f,g,h,i") && !Accepts("Columns", "HabsSort", "Value--") &&
		!Accepts("Columns", "Grav Drives", "Value") && !Accepts("Columns", std::string(37, 'a').c_str(), "Value"), "Columns refuses bad ids and keys");
	Expect(!Accepts("Columns", "hasOwnProperty", "Value") && !Accepts("Columns", "toString", "Value") && !Accepts("Columns", "valueOf", "") &&
			!Accepts("Columns", "constructor", "Value") && Accepts("Columns", "HasOwnProperty", "Value", "Value", 0) && Accepts("Columns", "Tostring", "", "", 1),
		"Columns refuses the names AS3's Object defines, which the movie cannot use as keys");
	Expect(Accepts("Debug", "Probe", "0", "0", 1) && Accepts("Debug", "Probe", "1", "1", 0) && !Accepts("Debug", "Other", "1"), "Debug holds Probe only");
	Expect(Accepts("Arrange", "PowerX", "l10", "L10", 0) && Accepts("Arrange", "PowerY", "T-5", "T-5", 0) && Accepts("Arrange", "PowerX", "-1", "-1", 1) &&
		Accepts("Arrange", "ArrangeBarX", "0", "0", 1) && Accepts("Arrange", "ArrangeBarY", "-12", "-12", 0), "Arrange holds anchors and the bar offset");
	Expect(!Accepts("Arrange", "PowerX", "X10") && !Accepts("Arrange", "PowerY", "B4001") && !Accepts("Arrange", "ColorsX", "L0") && !Accepts("Foo", "Bar", "1"),
		"Arrange and unknown sections refuse the rest");

	hsb::Setting s;
	Expect(hsb::ParseSetBody("Style.AccentColor=3", s) && s.section == "Style" && s.key == "AccentColor" && s.value == "3", "a SET body parses");
	Expect(hsb::ParseSetBody("Style.CardOpacity=0.85", s) && s.value == "0.85", "a SET value may hold a dot");
	Expect(hsb::ParseSetBody("Keys.HideAll==", s) && s.value == "=" && hsb::ParseSetBody("Keys.Find=.", s) && s.value == ".", "a key binding may be = or .");
	Expect(hsb::ParseSetBody("Style.AccentHex=", s) && s.isDefault, "an empty SET value is the default");
	Expect(!hsb::ParseSetBody("StyleAccentColor=3", s) && !hsb::ParseSetBody(".AccentColor=3", s) && !hsb::ParseSetBody("Style.=3", s) &&
		!hsb::ParseSetBody("Columns.Habs.x=Value", s), "malformed SET bodies are refused");
	Expect(hsb::ParseArrangeBody("PowerX=L10", s) && s.section == "Arrange" && hsb::ParseArrangeBody("ArrangeBarY=-12", s), "ARRANGE bodies parse");
	Expect(!hsb::ParseArrangeBody("=L10", s) && !hsb::ParseArrangeBody("PowerX", s), "malformed ARRANGE bodies are refused");

	auto set = [](const char* section, const char* key, const char* value) {
		hsb::Setting out;
		hsb::CheckSetting(section, key, value, out);
		return out;
	};
	Expect(hsb::MergeSettings("", {set("Style", "AccentColor", "3")}) == "[Style]\nAccentColor=3\n", "a new file gets the section and key");
	Expect(hsb::MergeSettings("", {set("Style", "AccentColor", "9")}).empty(), "a default never creates a line");
	Expect(hsb::MergeSettings("", {set("Style", "AccentColor", "3"), set("Style", "AccentColor", "4")}) == "[Style]\nAccentColor=4\n", "a later update wins");
	const std::string notes = "; my notes\n[Style]\nAccentColor=3 ; old\nCardOpacity=0.85\n\n[Layout]\nScreenMargin=50\n";
	Expect(hsb::MergeSettings(notes, {set("Style", "AccentColor", "5")}) == "; my notes\n[Style]\nAccentColor=5\nCardOpacity=0.85\n\n[Layout]\nScreenMargin=50\n",
		"a key is edited in place and comments elsewhere stay");
	Expect(hsb::MergeSettings(notes, {set("Style", "AccentColor", "9")}) == "; my notes\n[Style]\nCardOpacity=0.85\n\n[Layout]\nScreenMargin=50\n",
		"a default removes the key");
	Expect(hsb::MergeSettings("[Style]\nAccentColor=3\n\n[Layout]\nScreenMargin=50\n", {set("Style", "CardOpacity", "0.85")}) ==
		"[Style]\nAccentColor=3\nCardOpacity=0.85\n\n[Layout]\nScreenMargin=50\n", "a missing key goes after its section's last entry");
	Expect(hsb::MergeSettings("[Style]\nAccentColor=3\nAccentColor=4\n", {set("Style", "AccentColor", "5")}) == "[Style]\nAccentColor=5\n",
		"a key listed twice is kept once");
	Expect(hsb::MergeSettings("[Style]\nAccentColor=3\n[Layout]\nScreenMargin=50\n[Style]\nAccentColor=4\n", {set("Style", "AccentColor", "6")}) ==
		"[Style]\nAccentColor=6\n[Layout]\nScreenMargin=50\n[Style]\n", "a key in a repeated section is kept once, at its first spot");
	Expect(hsb::MergeSettings("[Style]\nFoo=bar\n", {set("Style", "AccentColor", "3")}) == "[Style]\nFoo=bar\nAccentColor=3\n", "unknown lines stay");
	Expect(hsb::MergeSettings("[Style]\r\nAccentColor=3\r\n", {set("Style", "CardOpacity", "0.85")}) == "[Style]\nAccentColor=3\nCardOpacity=0.85\n",
		"CRLF files are rewritten with plain line ends");
	Expect(hsb::MergeSettings("[Style]\nAccentColor=3\n", {set("Layout", "ScreenMargin", "50")}) == "[Style]\nAccentColor=3\n\n[Layout]\nScreenMargin=50\n",
		"a missing section is added at the end");
	Expect(hsb::MergeSettings("[style]\naccentcolor=3\n", {set("Style", "AccentColor", "4")}) == "[style]\nAccentColor=4\n", "keys and sections match without case");
	Expect(hsb::MergeSettings("[Style]\n;AccentColor=3\n", {set("Style", "AccentColor", "4")}) == "[Style]\n;AccentColor=3\nAccentColor=4\n",
		"a commented-out key is not edited");

	// A save never merges over a user file it could not read, and a skipped save is retried.
	Expect(hsb::UserReadAllowsWrite(false, false) && hsb::UserReadAllowsWrite(true, true) && !hsb::UserReadAllowsWrite(true, false),
		"an existing user ini that could not be read is never merged over");
	{
		std::vector<hsb::Setting> queue = {set("Style", "AccentColor", "5")};
		hsb::RequeueSettings(queue, {set("Style", "AccentColor", "3"), set("Layout", "ScreenMargin", "50")});
		Expect(queue.size() == 2 && queue[0].key == "ScreenMargin" && queue[1].key == "AccentColor" && queue[1].value == "5",
			"a failed batch goes back in front, and a newer value for the same key wins");
		std::vector<hsb::Setting> full(hsb::kMaxSettingUpdates, set("Layout", "ScreenMargin", "40"));
		hsb::RequeueSettings(full, {set("Style", "AccentColor", "3")});
		Expect(full.size() == hsb::kMaxSettingUpdates && full.front().key == "AccentColor", "the requeued queue stays within its cap");
	}

	// The HUD accent is read as the HUD reads it: its own folder, user over default, default 0.
	{
		const hsb::HudAccent none = hsb::LayerHudAccent("", "");
		Expect(hsb::kHudAccentDefault == 0 && none.color == 0 && none.hex.empty(), "with no HUD ini values the HUD's own default accent applies");
		const hsb::HudAccent def = hsb::LayerHudAccent("", "[Style]\nAccentColor=4\nAccentHex=#a1b2c3\n");
		Expect(def.color == 4 && def.hex == "A1B2C3", "the HUD default file is read");
		const hsb::HudAccent user = hsb::LayerHudAccent("[Style]\nAccentColor=7\n", "[Style]\nAccentColor=4\nAccentHex=A1B2C3\n");
		Expect(user.color == 7 && user.hex == "A1B2C3", "the HUD user file wins key by key");
		const hsb::HudAccent other = hsb::LayerHudAccent("[Style]\nAccentHex=zz\n[Layout]\nAccentColor=3\n", "");
		Expect(other.color == 0 && other.hex.empty(), "only [Style] counts and a bad hex is dropped");
		const std::string hud = "D:\\Games\\Starfield\\Data\\Interface\\HorizonUI\\";
		Expect(hsb::HudIniMayRead(hud + "HorizonUI.user.ini", hud) && hsb::HudIniMayRead(hud + "horizonui.DEFAULT.ini", hud), "the HUD's two ini files may be read");
		Expect(!hsb::HudIniMayRead(hud + "HorizonUI.ini", hud) && !hsb::HudIniMayRead(hud + "shipbuilder\\HorizonUI.user.ini", hud) &&
			!hsb::HudIniMayRead(hud + "..\\HorizonUI.user.ini", hud) && !hsb::HudIniMayRead("D:\\Other\\HorizonUI.user.ini", hud) &&
			!hsb::HudIniMayRead(hud + "HorizonUI.user.ini", "D:\\Games\\Starfield\\Data\\") && !hsb::HudIniMayRead("", hud),
			"nothing else outside the builder's folders is read");
	}

	bool found = false;
	const std::string ini = "[Style]\nAccentColor=3 ; note\n[Layout]\nScreenMargin=500\nUiScale=1.2\n[Panels]\nPower=0\nStats=1\nBogus=0\nCredits=0\n"
		"[Columns]\nHabs=Value,Mass\nHabsSort=Value-\nBad Key=Value\n";
	Expect(hsb::IniValue(ini, "Style", "AccentColor", found) == "3" && found, "IniValue reads a value without its comment");
	hsb::IniValue(ini, "Layout", "AccentColor", found);
	Expect(!found, "IniValue reads only the named section");
	Expect(hsb::SectionSettings(ini, "Panels").size() == 2 && hsb::SectionSettings(ini, "Columns").size() == 2, "SectionSettings keeps valid changed keys only");
	Expect(hsb::SettingOr(ini, "Layout", "ScreenMargin", "34") == "34" && hsb::SettingOr(ini, "Layout", "UiScale", "1.00") == "1.20" &&
		hsb::SettingOr(ini, "Layout", "Density", "compact") == "compact", "SettingOr falls back on bad or missing values");
	Expect(hsb::SettingOr("[Style]\nAccentHex=\n", "Style", "AccentHex", "-") == "-", "an empty hex falls back");
}

// ---- builder files (hsb_files.h) --------------------------------------------------------------

static void CheckFiles()
{
	const std::string raw = "line one\nline\ttwo \\ end\r\n";
	Expect(hsb::EscapeText(raw) == "line one\\nline\\ttwo \\\\ end\\n", "escaping keeps one line and drops CR");
	Expect(hsb::UnescapeText(hsb::EscapeText(raw)) == "line one\nline\ttwo \\ end\n", "unescaping restores the text");

	hsb::FileRequest r;
	Expect(hsb::ParseFileRequest("a1\tPILLS\tREAD\tpacks\tExplorer pack.json\t", r) && r.id == "a1" && r.kind == "PILLS" && r.verb == "READ" &&
		r.args.size() == 2 && r.args[1] == "Explorer pack.json" && r.body.empty(), "a read request parses");
	Expect(hsb::ParseFileRequest("7\tPROFILE\tWRITE\t{\\n}", r) && r.args.empty() && r.body == "{\\n}", "the body is the last field");
	Expect(!hsb::ParseFileRequest("A1\tPILLS\tLIST\t", r) && !hsb::ParseFileRequest("1\tPILLS", r) && !hsb::ParseFileRequest("", r) &&
		!hsb::ParseFileRequest("1234567890123\tPILLS\tLIST\t", r), "ids are short lowercase tokens and requests have four fields");

	Expect(hsb::SafeShareName("My crew habs.json", "PILLS") && hsb::SafeShareName("gold_scheme-2.ini", "SCHEMES"), "plain names are allowed");
	Expect(!hsb::SafeShareName("..\\x.json", "PILLS") && !hsb::SafeShareName("a/b.json", "PILLS") && !hsb::SafeShareName("x.ini", "PILLS") &&
		!hsb::SafeShareName(" x.json", "PILLS") && !hsb::SafeShareName(".json", "PILLS") && !hsb::SafeShareName(std::string(41, 'a') + ".json", "PILLS") &&
		!hsb::SafeShareName("x.json", "PROFILE") && !hsb::SafeShareName("c\xC3\xA9.json", "PILLS"), "names cannot leave their folder or kind");

	auto verb = [](const std::string& line) {
		hsb::FileRequest q;
		if (!hsb::ParseFileRequest(line, q)) return hsb::FileVerb::kBad;
		return hsb::CheckRequest(q);
	};
	Expect(verb("1\tPROFILE\tREAD\t") == hsb::FileVerb::kProfileRead && verb("2\tPROFILE\tWRITE\t{}") == hsb::FileVerb::kProfileWrite &&
		verb("3\tPROFILE\tBAD\t") == hsb::FileVerb::kProfileBad, "profile verbs");
	Expect(verb("4\tPROFILE\tREAD\tuser\t") == hsb::FileVerb::kBad && verb("5\tPROFILE\tDELETE\t") == hsb::FileVerb::kBad, "the profile takes no names and no delete");
	Expect(verb("6\tPILLS\tLIST\t") == hsb::FileVerb::kList && verb("7\tSCHEMES\tLIST\t") == hsb::FileVerb::kList && verb("8\tPILLS\tLIST\tuser\t") == hsb::FileVerb::kBad,
		"LIST takes no arguments");
	Expect(verb("9\tPILLS\tREAD\tpacks\ta.json\t") == hsb::FileVerb::kRead && verb("10\tSCHEMES\tREAD\tuser\tb.ini\t") == hsb::FileVerb::kRead, "reads use either folder");
	Expect(verb("11\tPILLS\tWRITE\tuser\ta.json\t{}") == hsb::FileVerb::kWrite && verb("12\tPILLS\tWRITE\tpacks\ta.json\t{}") == hsb::FileVerb::kBad,
		"writes go to user only");
	Expect(verb("13\tPILLS\tREAD\tsaves\ta.json\t") == hsb::FileVerb::kBad && verb("14\tOTHER\tREAD\tuser\ta.json\t") == hsb::FileVerb::kBad &&
		verb("15\tPILLS\tDELETE\tuser\ta.json\t") == hsb::FileVerb::kBad, "other folders, kinds and verbs are refused");
	Expect(verb("16\tPILLS\tWRITE\tuser\ta.json\t" + std::string(hsb::kMaxShareBytes * 2 + 1, 'x')) == hsb::FileVerb::kBad, "share writes are capped");
	{
		hsb::FileRequest big;
		big.id = "17";
		big.kind = "PROFILE";
		big.verb = "WRITE";
		big.body = std::string(hsb::kMaxProfileBytes * 2 + 1, 'x');
		const bool over = hsb::CheckRequest(big) == hsb::FileVerb::kBad;
		big.body.pop_back();
		Expect(over && hsb::CheckRequest(big) == hsb::FileVerb::kProfileWrite && verb("18\tPROFILE\tWRITE\t" + std::string(hsb::kMaxRequestBytes, 'x')) == hsb::FileVerb::kBad,
			"an escaped profile body is capped at twice the profile cap, and a request line at the request cap");
	}
	Expect(hsb::FileReply("a1", true, "x\ny") == "a1\t1\tx\\ny" && hsb::FileReply("a2", false, "") == "a2\t0\t", "replies escape their payload");
	Expect(hsb::RequestId("a1\tPILLS") == "a1" && hsb::RequestId("123456789012\tX") == "123456789012" && hsb::RequestId("a1").empty() &&
		hsb::RequestId("A1\tX").empty() && hsb::RequestId("\tX").empty() && hsb::RequestId("1234567890123\tX").empty(),
		"a request that does not parse still gets a failure reply when its id is valid");
	Expect(hsb::kReadMissing == "missing" && hsb::kReadUnreadable == "unreadable" && hsb::kReadDamaged == "damaged", "a failed profile read says why");
	Expect(hsb::FileReply("a3", true, std::string("{\"a\":1}\0junk", 12)) == "a3\t0\t" && hsb::FileReply("a4", false, std::string(3, '\0')) == "a4\t0\t" &&
			hsb::HasNul(std::string(1, '\0')) && !hsb::HasNul("{}"),
		"a payload with a NUL byte becomes a failure with no payload, so it cannot cut off the replies after it");
	Expect(!hsb::SafeShareName("Con.json", "PILLS") && !hsb::SafeShareName("nul.ini", "SCHEMES") && !hsb::SafeShareName("COM1.json", "PILLS") &&
		!hsb::SafeShareName("lpt9.json", "PILLS") && !hsb::SafeShareName("AUX.json", "PILLS") && hsb::SafeShareName("Cone.json", "PILLS") &&
		hsb::SafeShareName("COM.json", "PILLS") && hsb::SafeShareName("com10.json", "PILLS"), "Windows device names are refused");
	Expect(hsb::ListRow("user", "a.json", 12) == "user\ta.json\t12", "list rows are folder, name, bytes");

	const std::string docs = DocsTail('\\') + "Data\\Interface\\HorizonUI\\shipbuilder\\";
	const std::string game = "D:\\Steam\\steamapps\\common\\Starfield\\Data\\Interface\\HorizonUI\\shipbuilder\\";
	Expect(hsb::BuilderFileMayTouch(docs + "ShipBuilderPills.json", true) && hsb::BuilderFileMayTouch(docs + "ShipBuilderPills.json.tmp", true) &&
		hsb::BuilderFileMayTouch(docs + "ShipBuilderPills.bak", true) && hsb::BuilderFileMayTouch(docs + "ShipBuilderPills.bad.json", true),
		"the profile, its temp, backup and bad copy may be written in Documents");
	Expect(hsb::BuilderFileMayTouch(docs + "pills\\user\\a.json", true) && hsb::BuilderFileMayTouch(docs + "schemes\\user\\b.ini", true),
		"user shares may be written in Documents");
	Expect(!hsb::BuilderFileMayTouch(docs + "pills\\packs\\a.json", true) && hsb::BuilderFileMayTouch(docs + "pills\\packs\\a.json", false),
		"packs are read only");
	Expect(!hsb::BuilderFileMayTouch(game + "pills\\user\\a.json", true) && hsb::BuilderFileMayTouch(game + "pills\\packs\\a.json", false),
		"the game folder is never written and its packs may be read");
	Expect(!hsb::BuilderFileMayTouch(docs + "pills\\user\\..\\..\\x.json", true) && !hsb::BuilderFileMayTouch(docs + "pills\\user\\a.ini", true) &&
		!hsb::BuilderFileMayTouch(docs + "schemes\\user\\a.json", false) && !hsb::BuilderFileMayTouch(docs + "pills\\ShipBuilderPills.json", true) &&
		!hsb::BuilderFileMayTouch(DocsTail('\\') + "Saves\\Interface\\HorizonUI\\shipbuilder\\ShipBuilderPills.json", true) &&
		!hsb::BuilderFileMayTouch(docs + "HorizonShipBuilder.user.ini", true) && !hsb::BuilderFileMayTouch("", false),
		"anything else is refused");
	Expect(std::string(hsb::KindFolder("PILLS")) == "pills" && std::string(hsb::KindFolder("SCHEMES")) == "schemes" && std::string(hsb::KindFolder("X")).empty(),
		"each kind has its own folder");
}

// ---- pill profile rules on a failing disk (hsb_profile.h) ----------------------------------

// A disk whose every step can fail on purpose. A missing key in files is a missing file.
struct FakeDisk final : hsb::ProfileDisk {
	std::map<hsb::ProfileFile, std::string> files;
	std::set<hsb::ProfileFile> gated;       // MayTouch refuses
	std::set<hsb::ProfileFile> unreadable;  // present, but a read fails (locked, I/O error)
	std::set<hsb::ProfileFile> unwritable;  // the write or its rename fails; the file is unchanged
	std::set<hsb::ProfileFile> unknown;     // the system cannot say whether it is there
	bool moveFails = false;                 // the rename fails for another reason (locked, read only)
	bool noDir = false;                     // the folder is not there until EnsureDir makes it
	int writes = 0;
	int moves = 0;

	bool MayTouch(hsb::ProfileFile file, bool) override { return gated.count(file) == 0; }
	bool Exists(hsb::ProfileFile file) override { return files.count(file) > 0 || unknown.count(file) > 0; }
	bool Read(hsb::ProfileFile file, std::size_t cap, std::string& out) override
	{
		out.clear();
		const auto at = files.find(file);
		if (at == files.end() || unreadable.count(file) > 0 || at->second.size() > cap) return false;
		out = at->second;
		return true;
	}
	bool WriteReplace(hsb::ProfileFile file, std::string_view text) override
	{
		if (unwritable.count(file) > 0 || noDir) return false;
		files[file] = std::string(text);
		++writes;
		return true;
	}
	hsb::MoveResult MoveNoReplace(hsb::ProfileFile from, hsb::ProfileFile to) override
	{
		if (files.count(to) > 0) return hsb::MoveResult::kExists;
		if (moveFails || files.count(from) == 0) return hsb::MoveResult::kFailed;
		files[to] = files[from];
		files.erase(from);
		++moves;
		return hsb::MoveResult::kOk;
	}
	void EnsureDir() override { noDir = false; }

	std::string At(hsb::ProfileFile file) const
	{
		const auto at = files.find(file);
		return at == files.end() ? std::string("<none>") : at->second;
	}
};

static void CheckProfile()
{
	using hsb::ProfileFile;
	const ProfileFile P = ProfileFile::kProfile, B = ProfileFile::kBackup, X = ProfileFile::kBad;
	const std::string good = "{\"type\":\"HorizonShipBuilderPills\",\"version\":1,\"pills\":[]}";
	const std::string damaged = "{\"type\":\"HorizonShipBuilderPills\",\"version\":1,\"pills\":[";
	const std::string zeros(4096, '\0');
	const std::string embedded = std::string("{\"type\":\"Horizon") + '\0' + "ShipBuilderPills\"}";

	Expect(hsb::ProfileFileName(P) == "ShipBuilderPills.json" && hsb::ProfileFileName(B) == "ShipBuilderPills.bak" &&
			hsb::ProfileFileName(X) == "ShipBuilderPills.bad.json",
		"names: the profile, its backup and its bad copy each have their own file");

	// PROFILE READ
	{
		FakeDisk d;
		hsb::ProfileState s;
		auto r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadMissing, "READ: no profile is missing, so the movie may start fresh");
		d.files[P] = good;
		r = hsb::ProfileRead(d, s);
		Expect(r.ok && r.payload == good, "READ: a profile is returned whole");
		d.unreadable.insert(P);
		r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadUnreadable && d.At(P) == good, "READ: a profile that cannot be read is unreadable and left alone");
		d.unreadable.clear();
		d.gated.insert(P);
		r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadUnreadable, "READ: a profile the gate refuses is unreadable, never missing");
		d.gated.clear();
		d.files.erase(P);
		d.unknown.insert(P);
		r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadUnreadable, "READ: a profile the system cannot confirm missing is unreadable");
		d.unknown.clear();
		d.files[P] = std::string(hsb::kMaxProfileBytes + 1, ' ');
		r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadUnreadable, "READ: a profile over the cap is unreadable");
		d.files[P] = std::string(hsb::kMaxProfileBytes, ' ');
		r = hsb::ProfileRead(d, s);
		Expect(r.ok && r.payload.size() == hsb::kMaxProfileBytes && hsb::kMaxProfileBytes > hsb::kMaxShareBytes,
			"READ: a profile at the profile cap reads whole, larger than any share file");
		for (const std::string* nul : {&zeros, &embedded}) {
			d.files[P] = *nul;
			r = hsb::ProfileRead(d, s);
			Expect(!r.ok && r.payload == hsb::kReadDamaged && d.At(P) == *nul && d.writes == 0 && d.moves == 0,
				"READ: a profile with a NUL byte (zero-filled, or one inside) is damaged, not empty, and left alone");
		}
		s.held = true;
		d.files[P] = good;
		r = hsb::ProfileRead(d, s);
		Expect(r.ok && !s.held, "READ: a new visit clears the hold");
		s.held = true;
		d.files.erase(P);
		r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadMissing && !s.held, "READ: a new visit with no profile clears an earlier visit's hold, so it can start fresh");
	}

	// PROFILE WRITE
	{
		FakeDisk d;
		hsb::ProfileState s;
		d.noDir = true;
		auto r = hsb::ProfileWrite(d, s, good);
		Expect(r.ok && d.At(P) == good && d.files.count(B) == 0, "WRITE: the folder is made first, and a first profile needs no backup");
		r = hsb::ProfileWrite(d, s, "second");
		Expect(r.ok && d.At(P) == "second" && d.At(B) == good, "WRITE: the old profile goes to the backup first");

		d.unwritable.insert(B);
		r = hsb::ProfileWrite(d, s, "third");
		Expect(!r.ok && r.payload == hsb::kProfileBackupFailed && d.At(P) == "second" && d.At(B) == good,
			"WRITE: when the backup fails, nothing is written");
		d.unwritable = {P};
		r = hsb::ProfileWrite(d, s, "third");
		Expect(!r.ok && r.payload == hsb::kProfileFailed && d.At(P) == "second" && d.At(B) == "second",
			"WRITE: when the profile write fails, the profile is as it was and the backup holds it too");
		d.unwritable.clear();

		const int before = d.writes;
		d.files[P] = "second";
		d.files[B] = good;
		d.unreadable.insert(P);
		r = hsb::ProfileWrite(d, s, "third");
		Expect(!r.ok && r.payload == hsb::kReadUnreadable && d.At(P) == "second" && d.At(B) == good && d.writes == before,
			"WRITE: a profile that cannot be read whole is never backed up or replaced");
		d.unreadable.clear();
		d.unknown.insert(P);
		d.files.erase(P);
		r = hsb::ProfileWrite(d, s, "third");
		Expect(!r.ok && r.payload == hsb::kReadUnreadable && d.files.count(P) == 0 && d.At(B) == good && d.writes == before,
			"WRITE: a profile the system cannot confirm missing is never written over");
		d.unknown.clear();
		for (const std::string* nul : {&zeros, &embedded}) {
			d.files[P] = *nul;
			r = hsb::ProfileWrite(d, s, "third");
			Expect(!r.ok && r.payload == hsb::kReadDamaged && d.At(P) == *nul && d.At(B) == good && d.writes == before,
				"WRITE: a profile with a NUL byte is never copied over the good backup or saved over");
		}
		d.files[P] = good;
		for (const ProfileFile gate : {P, B}) {
			d.gated = {gate};
			r = hsb::ProfileWrite(d, s, "third");
			Expect(!r.ok && d.At(P) == good && d.writes == before, "WRITE: a file the gate refuses is never written");
		}
		d.gated.clear();
		r = hsb::ProfileWrite(d, s, std::string(hsb::kMaxProfileBytes + 1, ' '));
		Expect(!r.ok && d.At(P) == good && d.writes == before, "WRITE: a profile over the cap is refused");
		{
			FakeDisk c;
			hsb::ProfileState cs;
			const std::string full(hsb::kMaxProfileBytes, 'a');
			c.files[P] = full;
			r = hsb::ProfileWrite(c, cs, std::string(hsb::kMaxProfileBytes, 'b'));
			Expect(r.ok && c.At(B) == full && c.At(P) == std::string(hsb::kMaxProfileBytes, 'b'),
				"WRITE: a profile at the cap is written, and an old one at the cap is backed up");
		}
		s.held = true;
		r = hsb::ProfileWrite(d, s, "third");
		Expect(!r.ok && r.payload == hsb::kProfileHeld && d.At(P) == good && d.At(B) == good && d.writes == before,
			"WRITE: after a failed set-aside nothing is written");
	}

	// PROFILE BAD
	{
		FakeDisk d;
		hsb::ProfileState s;
		auto r = hsb::ProfileSetAside(d, s);
		Expect(r.ok && !s.held && d.moves == 0, "BAD: with no profile there is nothing to set aside");
		d.files[P] = damaged;
		r = hsb::ProfileSetAside(d, s);
		Expect(r.ok && !s.held && d.files.count(P) == 0 && d.At(X) == damaged, "BAD: the damaged profile becomes the bad copy");

		d.files[P] = "damaged again";
		r = hsb::ProfileSetAside(d, s);
		Expect(!r.ok && r.payload == hsb::kProfileBadExists && s.held && d.At(X) == damaged && d.At(P) == "damaged again",
			"BAD: an earlier bad copy is never replaced, and the new damaged profile stays where it is");

		FakeDisk f;
		hsb::ProfileState t;
		f.files[P] = damaged;
		f.moveFails = true;
		r = hsb::ProfileSetAside(f, t);
		Expect(!r.ok && r.payload == hsb::kProfileFailed && t.held && f.At(P) == damaged && f.files.count(X) == 0,
			"BAD: a rename that fails leaves the profile in place and holds writes");
		f.moveFails = false;
		r = hsb::ProfileSetAside(f, t);
		Expect(r.ok && !t.held && f.At(X) == damaged, "BAD: a set-aside that works clears the hold");

		for (const ProfileFile gate : {P, X}) {
			FakeDisk g;
			hsb::ProfileState u;
			g.files[P] = damaged;
			g.gated = {gate};
			r = hsb::ProfileSetAside(g, u);
			Expect(!r.ok && r.payload == hsb::kProfileFailed && u.held && g.At(P) == damaged && g.moves == 0, "BAD: a file the gate refuses is never moved");
		}
		FakeDisk h;
		hsb::ProfileState v;
		h.unknown.insert(P);
		h.moveFails = true;
		r = hsb::ProfileSetAside(h, v);
		Expect(!r.ok && v.held, "BAD: a profile the system cannot confirm missing must move before writes go on");
	}

	// Review A3's case: a damaged profile, a good backup, and a set-aside that fails because a
	// bad copy is already there or the rename fails. No save may touch any of the three files.
	for (const bool exists : {true, false}) {
		FakeDisk d;
		hsb::ProfileState s;
		d.files[P] = damaged;
		d.files[B] = good;
		if (exists) d.files[X] = "older damaged";
		else d.moveFails = true;
		auto r = hsb::ProfileRead(d, s);
		Expect(r.ok && r.payload == damaged, "A3: the damaged profile reads (the movie finds it does not parse)");
		r = hsb::ProfileSetAside(d, s);
		Expect(!r.ok && r.payload == (exists ? hsb::kProfileBadExists : hsb::kProfileFailed), "A3: the set-aside fails and says why");
		for (int save = 0; save < 2; ++save) {
			r = hsb::ProfileWrite(d, s, "starter pills plus one change");
			Expect(!r.ok && r.payload == hsb::kProfileHeld, "A3: every save in that visit is refused");
		}
		Expect(d.At(P) == damaged && d.At(B) == good && d.At(X) == (exists ? "older damaged" : "<none>") && d.writes == 0,
			"A3: the damaged profile, the good backup and the earlier bad copy are all unchanged");
		r = hsb::ProfileRead(d, s);
		Expect(r.ok && r.payload == damaged && !s.held, "A3: the next visit reads the same damaged profile and tries again");
		d.files.erase(X);
		d.moveFails = false;
		r = hsb::ProfileSetAside(d, s);
		Expect(r.ok && d.At(X) == damaged && d.files.count(P) == 0, "A3: once the way is clear, the damaged profile is set aside");
		r = hsb::ProfileWrite(d, s, "fresh");
		Expect(r.ok && d.At(P) == "fresh" && d.At(B) == good && d.At(X) == damaged, "A3: then saving starts fresh and the good backup is still there");
	}

	// A zero-filled profile after a power loss: it is damaged, set aside, and the good backup stays.
	{
		FakeDisk d;
		hsb::ProfileState s;
		d.files[P] = zeros;
		d.files[B] = good;
		auto r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadDamaged, "zeros: the profile reads as damaged, not as no profile");
		r = hsb::ProfileWrite(d, s, "fresh");
		Expect(!r.ok && d.At(P) == zeros && d.At(B) == good, "zeros: a save before the set-aside is refused and the backup stays");
		r = hsb::ProfileSetAside(d, s);
		Expect(r.ok && d.At(X) == zeros, "zeros: the zero-filled file is kept as the bad copy");
		r = hsb::ProfileWrite(d, s, "fresh");
		Expect(r.ok && d.At(P) == "fresh" && d.At(B) == good, "zeros: the first save after it needs no backup and keeps the good one");
		r = hsb::ProfileWrite(d, s, "fresh again");
		Expect(r.ok && d.At(P) == "fresh again" && d.At(B) == good && d.At(X) == zeros, "zeros: so does every later save in that visit");
	}

	// Review A4: an empty or blank profile (a crash between truncate and write, a sync conflict,
	// a hand edit) is a fresh start. It is never copied over the backup, and no save in that
	// visit rotates the last good copy out of it.
	Expect(hsb::ProfileBlank("") && hsb::ProfileBlank(" \t\r\n") && !hsb::ProfileBlank(" {") && !hsb::ProfileBlank("\v") && !hsb::ProfileBlank(zeros),
		"blank: only JSON whitespace is blank, and a NUL byte is not");
	for (const std::string& blank : {std::string(), std::string(" \t\r\n \r\n")}) {
		FakeDisk d;
		hsb::ProfileState s;
		d.files[P] = blank;
		d.files[B] = good;
		auto r = hsb::ProfileRead(d, s);
		Expect(r.ok && r.payload == blank && s.keepBackup && !s.held, "blank: the profile reads, and the visit keeps the backup");
		for (const char* save : {"first", "second", "third"}) {
			r = hsb::ProfileWrite(d, s, save);
			Expect(r.ok && d.At(P) == save && d.At(B) == good && d.files.count(X) == 0, "blank: every save in that visit keeps the good backup");
		}
		r = hsb::ProfileRead(d, s);
		Expect(r.ok && r.payload == "third" && !s.keepBackup, "blank: the next visit loads the saved pills");
		r = hsb::ProfileWrite(d, s, "fourth");
		Expect(r.ok && d.At(P) == "fourth" && d.At(B) == "third", "blank: and backs them up as usual");
	}
	{
		FakeDisk d;
		hsb::ProfileState s;
		d.files[P] = "";
		auto r = hsb::ProfileWrite(d, s, "first");
		Expect(r.ok && d.At(P) == "first" && d.files.count(B) == 0, "blank: an empty old profile is never copied to the backup");
		d.files[P] = " \r\n";
		d.files[B] = good;
		r = hsb::ProfileWrite(d, s, "second");
		Expect(r.ok && d.At(P) == "second" && d.At(B) == good, "blank: a blank old profile never replaces a good backup");
	}

	// A missing profile with a backup there (removed by hand or by a tool): the backup stays for
	// the visit. A first visit has none, so its second save makes one as before.
	{
		FakeDisk d;
		hsb::ProfileState s;
		d.files[B] = good;
		auto r = hsb::ProfileRead(d, s);
		Expect(!r.ok && r.payload == hsb::kReadMissing && s.keepBackup, "missing: a visit with no profile and a backup keeps it");
		for (const char* save : {"first", "second"}) {
			r = hsb::ProfileWrite(d, s, save);
			Expect(r.ok && d.At(P) == save && d.At(B) == good, "missing: each save in that visit keeps the good backup");
		}
		FakeDisk e;
		hsb::ProfileState t;
		r = hsb::ProfileRead(e, t);
		Expect(!r.ok && r.payload == hsb::kReadMissing && !t.keepBackup, "missing: a first visit has no backup to keep");
		r = hsb::ProfileWrite(e, t, "first");
		Expect(r.ok && e.files.count(B) == 0, "missing: its first save needs no backup");
		r = hsb::ProfileWrite(e, t, "second");
		Expect(r.ok && e.At(P) == "second" && e.At(B) == "first", "missing: its second save backs up the first");
		FakeDisk f;
		hsb::ProfileState u;
		f.unknown.insert(B);
		r = hsb::ProfileRead(f, u);
		r = hsb::ProfileWrite(f, u, "first");
		r = hsb::ProfileWrite(f, u, "second");
		Expect(r.ok && u.keepBackup && f.files.count(B) == 0 && f.At(P) == "second",
			"missing: a backup the system cannot confirm missing is kept, never written over");
	}

	// After a set-aside the backup may hold the player's last good pills: the visit keeps it,
	// whether the damaged profile had a NUL byte or did not parse.
	for (const std::string* bad : {&damaged, &zeros}) {
		FakeDisk d;
		hsb::ProfileState s;
		d.files[P] = *bad;
		d.files[B] = good;
		auto r = hsb::ProfileRead(d, s);
		r = hsb::ProfileSetAside(d, s);
		Expect(r.ok && s.keepBackup && !s.held && d.At(X) == *bad, "set aside: the visit keeps the backup");
		for (const char* save : {"first", "second", "third"}) {
			r = hsb::ProfileWrite(d, s, save);
			Expect(r.ok && d.At(P) == save && d.At(B) == good && d.At(X) == *bad, "set aside: each save keeps the good backup and the bad copy");
		}
		FakeDisk e;
		hsb::ProfileState t;
		e.files[P] = *bad;
		r = hsb::ProfileRead(e, t);
		r = hsb::ProfileSetAside(e, t);
		Expect(r.ok && !t.keepBackup, "set aside: with no backup there is none to keep");
		r = hsb::ProfileWrite(e, t, "first");
		r = hsb::ProfileWrite(e, t, "second");
		Expect(r.ok && e.At(B) == "first" && e.At(X) == *bad, "set aside: so the second save backs up the first");
	}

	// The plugin holds writes on its own after a read that failed or found a NUL byte, so a
	// save the movie should never send still changes nothing.
	for (int how = 0; how < 3; ++how) {
		FakeDisk d;
		hsb::ProfileState s;
		const std::string old = how == 2 ? zeros : good;
		d.files[P] = old;
		d.files[B] = good;
		if (how == 0) d.unreadable.insert(P);
		if (how == 1) d.gated.insert(P);
		auto r = hsb::ProfileRead(d, s);
		Expect(!r.ok && s.held && !s.keepBackup, "held: a read that fails, is gated or finds a NUL byte holds writes");
		d.unreadable.clear();
		d.gated.clear();
		r = hsb::ProfileWrite(d, s, "starter pills");
		Expect(!r.ok && r.payload == hsb::kProfileHeld && d.At(P) == old && d.At(B) == good && d.writes == 0 && d.moves == 0,
			"held: a save after it changes nothing, even once the profile could be read");
	}
}

// ---- tree scan ----------------------------------------------------------------------------

static const std::set<std::string>& VanillaEvents()
{
	// Every name is sent by the vanilla spaceship editor scripts with the same parameters.
	static const std::set<std::string> names = {
		"ShipEditor_ChangeModuleCategory", "ShipEditor_OnColorPickerControlChanged", "ShipEditor_OnColorPickerTabChanged",
		"ShipEditor_OnColorSliderMouseInput", "ShipEditor_OnFlightCheckTabChanged", "ShipEditor_OnHintButtonActivated",
		"ShipEditor_OnRecentColorSwatchClicked", "ShipEditor_PreviewShipPart", "ShipEditor_SelectedShipPart",
	};
	return names;
}

static void ScanTree(const fs::path& root)
{
	const std::string retiredA = std::string("HU") + "SD";
	const std::string retiredB = std::string("rs") + "chr";
	const std::string userDir = std::string("C:") + "\\Users";
	const std::string timer = std::string("get") + "Timer";
	const std::string glow = std::string("Glow") + "Filter";
	const std::string shipEdit = std::string("Ship") + "Editor_";
	const std::string shipBuild = std::string("Ship") + "Builder_";
	const std::string dispatch = std::string("dispatch") + "Event";
	const std::string del = std::string("Delete") + "File";
	const std::string move = std::string("Move") + "File";
	const std::string copy = std::string("Copy") + "File";
	const std::string rmdir = std::string("Remove") + "Directory";
	const std::string files = std::string("std::") + "filesystem";
	const std::string wideOpen = std::string("_wf") + "open_s";
	const std::string stream = std::string("of") + "stream";
	const std::string mouseListen = std::string("addEventListener(") + "MouseEvent";
	const std::string mojibake = std::string("\xC3\xA2\xE2\x82\xAC");
	std::error_code err;
	if (!fs::exists(root, err)) {
		Expect(false, "scan root exists");
		return;
	}
	std::size_t scanned = 0;
	for (auto it = fs::recursive_directory_iterator(root, fs::directory_options::skip_permission_denied, err);
		it != fs::recursive_directory_iterator(); it.increment(err)) {
		if (err) break;
		if (!it->is_regular_file()) continue;
		const std::string body = ReadFile(it->path());
		if (HasNul(body)) continue;
		++scanned;
		const std::string rel = it->path().lexically_normal().generic_string();
		const std::string name = it->path().filename().string();
		const bool test = Has(rel, "/tests/");
		const bool plugin = name == "probe.cpp" || name == "hsb_win32_files.h";
		// Its setup writes and clears files in its own temp folder (checked in CheckPlugin).
		const bool diskTest = test && name == "profile_disk_test.cpp";
		const bool horizonMovie = name.size() > 3 && name.substr(name.size() - 3) == ".as" && name != "document_splice.as" &&
			name != "HorizonShipBuilderProbe.as";
		auto fail = [&](const std::string& why) { Expect(false, rel + ": " + why); };
		if (Has(body, retiredA) || Has(body, retiredB)) fail("retired name");
		if (Has(body, userDir)) fail("a private user folder path");
		if (Has(body, mojibake)) fail("mojibake");
		if (body.size() >= 3 && body.compare(0, 3, "\xEF\xBB\xBF") == 0) fail("a UTF-8 byte order mark");
		if (Has(body, timer)) fail("a timer call");
		if (Has(body, glow)) fail("a glow filter");
		for (std::size_t at = body.find(shipEdit); at != std::string::npos; at = body.find(shipEdit, at + 1)) {
			std::size_t end = at + shipEdit.size();
			while (end < body.size() && ((body[end] >= 'A' && body[end] <= 'Z') || (body[end] >= 'a' && body[end] <= 'z'))) ++end;
			const std::string event = body.substr(at, end - at);
			if (!horizonMovie && !test && name != "README_P0.md") fail("an editor event name outside the movie");
			else if (!test && !VanillaEvents().count(event)) fail("an editor event the vanilla menu does not send: " + event);
		}
		for (std::size_t at = body.find(shipBuild); at != std::string::npos; at = body.find(shipBuild, at + shipBuild.size())) {
			const bool logName = at >= 7 && body.compare(at - 7, 7, "Horizon") == 0;
			if (!logName && !test) fail("a builder event name");
		}
		if (Has(body, dispatch) && name != "HorizonShipBuilder.as" && !test) fail("an event dispatch outside the hub");
		if ((Has(body, del) || Has(body, rmdir)) && !diskTest) fail("a delete call");
		if ((Has(body, move) || Has(body, copy)) && !plugin && !test) fail("a file move or copy outside the plugin");
		if (Has(body, files) && !test) fail("std::filesystem outside the test");
		if ((Has(body, wideOpen) || Has(body, stream)) && !plugin && !diskTest) fail("a file writer outside the plugin");
		if (horizonMovie && Has(body, mouseListen)) fail("a Scaleform mouse listener on a Horizon control");
	}
	Expect(scanned > 30, "the scan reads the tree");
}

// True when the line uses the field itself, not a longer name such as this.faceTries.
static bool UsesField(const std::string& line, const std::string& field)
{
	for (std::size_t at = line.find(field); at != std::string::npos; at = line.find(field, at + 1)) {
		const std::size_t next = at + field.size();
		const char c = next < line.size() ? line[next] : ' ';
		const bool ident = (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9') || c == '_';
		if (!ident) return true;
	}
	return false;
}

// Lines that build log text may carry candidate tags and metrics, never a face name.
static bool NotesHideFaces(const std::string& source)
{
	std::istringstream in(source);
	std::string line;
	while (std::getline(in, line)) {
		const bool logs = Has(line, "note(") || Has(line, "report +=") || Has(line, "var report") || Has(line, "lines.push(");
		if (!logs) continue;
		if (Has(line, "FACES") || Has(line, "names[") || Has(line, "labelFace") || Has(line, "fieldFace(") || Has(line, ".font") ||
			UsesField(line, "kit.face") || UsesField(line, "this.face") || UsesField(line, "kit.boldFace"))
			return false;
	}
	return true;
}

// ---- movie pins ---------------------------------------------------------------------------------

static void CheckMovie(const fs::path& root)
{
	const fs::path as = root / "actionscript";
	const std::string hub = ReadFile(as / "HorizonShipBuilder.as");
	const std::string box = ReadFile(as / "HsbBox.as");
	const std::string browser = ReadFile(as / "HsbBrowser.as");
	const std::string settings = ReadFile(as / "HsbSettings.as");
	const std::string colors = ReadFile(as / "HsbColors.as");
	const std::string editor = ReadFile(as / "HsbPillEditor.as");
	const std::string kit = ReadFile(as / "HsbKit.as");
	const std::string splice = ReadFile(as / "document_splice.as");
	Expect(!hub.empty() && !box.empty() && !browser.empty() && !settings.empty() && !colors.empty() && !kit.empty() && !splice.empty(), "movie sources read");

	Expect(Has(hub, "internal static const VERSION:String = \"0.2.0.0\";") && Has(hub, "this.note(\"BUILDER \" + VERSION"), "the movie is 0.2.0.0");
	Expect(!Has(hub, "\"0.1.1.0\"") && !Has(hub, "\"0.1.0.0\""), "no stale movie version");

	// The p5 fix: no Horizon control waits for a Scaleform mouse event. Boxes take Scaleform hit
	// tests (so the engine sees UI under the cursor) and the hub hit-tests fed points itself.
	Expect(InOrder(box, {"this.mouseEnabled = true;", "this.mouseChildren = false;"}), "a Horizon box is one hit target");
	Expect(InOrder(hub, {"this.mouseEnabled = false;", "this.mouseChildren = true;"}), "the hub itself takes no hits");
	Expect(Has(FunctionBody(hub, "onToken"), "if(kind == \"M\" && bits.length >= 4)") && Has(FunctionBody(hub, "onToken"), "if(kind == \"W\" && bits.length >= 4)") &&
		Has(FunctionBody(hub, "onToken"), "if(kind == \"K\") { this.onKey(param1.substring(2)); return; }") &&
		Has(FunctionBody(hub, "onToken"), "if(kind == \"C\" && bits.length >= 2) { this.onChar(int(bits[1])); return; }"),
		"the movie reads every feed token the plugin writes");
	Expect(Has(FunctionBody(hub, "pushState"),
			R"AS("STATE capture=" + (this.capturing() ? 1 : 0) + " text=" + (this.textOwner != null ? 1 : 0) + " arrange=" + (arranging ? 1 : 0) + " stage=" + w + "x" + h + " view=" + this.viewText() + " keys=" + (hotkeys && this.keyArrange != "0" ? 1 : 0) + " hide=" + (hotkeys ? this.keyCode(this.keyHide) : 0) + " find=" + (hotkeys ? this.keyCode(this.keyFind) : 0))AS"),
		"STATE carries every field the plugin reads");
	{
		// Horizon's hotkeys stand aside while the player types a ship name or Horizon is not drawn.
		Expect(Has(FunctionBody(hub, "pushState"), "var hotkeys:Boolean = this.hotkeysAllowed();") &&
			FunctionBody(hub, "hotkeysAllowed") == R"AS(private function hotkeysAllowed():Boolean
      {
         if(this.conflict || this.kit == null) { return false; }
         if(this.nativeOn("ShipRename_mc") || this.nativeOn("HangarInfoPanel_mc")) { return false; }
         var focus:InteractiveObject = stage != null ? stage.focus : null;
         var field:TextField = focus as TextField;
         if(field != null && field.type == TextFieldType.INPUT && !this.contains(field)) { return false; }
         return true;
      }
)AS",
			"hide, find and Arrange keys reach the game while a vanilla text field or the rename screen is up");
		Expect(InOrder(FunctionBody(hub, "onKey"), {"if(!this.hotkeysAllowed()) { return; }", "if(param1 == \"open\")", "if(param1 == \"hide\")", "if(param1 == \"find\""}),
			"a hotkey token that arrives late is ignored when hotkeys stand aside");
	}
	Expect(FunctionBody(hub, "wantsStick", "public") == R"AS(public function wantsStick():Boolean
      {
         return this.capturing();
      }
)AS", "the stick is consumed only while Horizon captures");
	{
		hsb::InputState st = hsb::ParseState("STATE capture=0 text=1 arrange=1 stage=1920x1080 view=0,0,1920,1080 keys=0 hide=72 find=0", hsb::InputState{});
		Expect(!st.capture && st.text && st.arrange && !st.arrangeKey && st.hideChar == 72 && st.findChar == 0, "the plugin reads the movie's STATE format");
	}
	const std::string hot = FunctionBody(hub, "hotText");
	Expect(Has(hot, "if(this.conflict || this.kit == null) { return \"none\"; }") && Has(hot, "if(this.capturing()) { return \"all\"; }") &&
		Has(hot, "out.join(\";\")"), "HOT is none when stood down, all while capturing, else the shown boxes");
	Expect(Has(FunctionBody(hub, "capturing", "internal"), "this.gridOpen()") && Has(FunctionBody(hub, "gridOpen"), "this.browser.gridOpen && this.shown(\"Browser\")"),
		"the category grid captures input");
	Expect(FunctionBody(hub, "wantsEvent", "public") == R"AS(public function wantsEvent(param1:String, param2:Boolean):Boolean
      {
         var open:Boolean = this.capturing();
         if(param2)
         {
            this.heldEvents[param1] = open ? this.frameN : -1;
            if(open) { this.padEvent(param1); }
            return open;
         }
         var pressed:int = this.heldEvents[param1] != null ? int(this.heldEvents[param1]) : -1;
         delete this.heldEvents[param1];
         var held:Boolean = pressed >= 0;
         if(!open || !held) { return held || open; }
         // The same key press may also have arrived as a DLL key token (cancelTop/acceptTop
         // stamp the frame), so a release acts only when nothing acted since its press.
         if(param1 == "Escape" || param1 == "Cancel") { if(this.lastCancel < pressed) { this.cancelTop("pad"); } return true; }
         if(param1 == "Accept" || param1 == "Enter") { if(this.lastOk < pressed) { this.acceptTop("pad"); } return true; }
         return true;
      }
)AS", "controller events are consumed only while Horizon captures, Accept and Cancel act once on release");
	Expect(Has(FunctionBody(hub, "cancelTop", "internal"), "if(this.frameN - this.lastCancel < DOUBLE_FRAMES) { return; }") &&
		Has(FunctionBody(hub, "acceptTop", "internal"), "if(this.frameN - this.lastOk < DOUBLE_FRAMES) { return; }"), "a cancel or accept acts once per press");
	Expect(Has(FunctionBody(hub, "cancelTop", "internal"), "if(this.gridOpen()) { this.browser.closeGrid(); }"), "Esc closes the category grid");
	// Find makes the movie capture every press and key, so it may never outlive its field on
	// screen: folding or hiding the browser, opening a popup or pressing elsewhere ends it.
	Expect(Has(FunctionBody(browser, "endFind", "internal"), "if(this.findOn) { this.stopFind(); }") &&
			Has(FunctionBody(hub, "paint"), "if(!this.browser.visible || this.browser.collapsed) { this.browser.endFind(); }") &&
			InOrder(FunctionBody(hub, "openPop", "internal"), {"if(this.browser != null) { this.browser.endFind(); }", "this.pops.push(param1);"}) &&
			InOrder(FunctionBody(hub, "onPointer"), {"this.browser.closeGrid();",
				"if(top == null && this.textOwner == this.browser && !this.browser.contains2(param2,param3)) { this.browser.endFind(); }",
				"var target:HsbBox = this.boxAt(param2,param3);"}),
		"Find ends when the browser folds or hides, a popup opens or a press lands outside the browser");

	// Vanilla panels stay alive: alpha 0 and no mouse, never invisible, moved or reparented.
	const std::string cover = FunctionBody(hub, "cover");
	Expect(Has(cover, "if(c.alpha != 0) { c.alpha = 0; }") && Has(cover, "(c as DisplayObjectContainer).mouseChildren = false;") &&
		Has(cover, "c.alpha = Number(row.alpha);") && !Has(cover, "visible") && !Has(cover, "removeChild") && !Has(cover, "addChild") &&
		!Has(cover, ".x =") && !Has(cover, ".y ="), "game panels are hidden by alpha only and restored as found");
	for (const char* clip : {"ModulePalette_mc", "ModuleInfoCard_mc", "CostSummary_mc", "PowerAllocation_mc", "ColorPicker_mc", "FlightCheck_mc"}) {
		Expect(!Has(hub, std::string(clip) + "\"].visible") && !Has(hub, std::string(clip) + ".visible"), std::string("the movie never hides ") + clip);
	}
	Expect(!Has(hub, "aPartList") && !Has(browser, "aPartList = "), "the movie never writes the parts array");
	Expect(CountOf(hub, "BSUIDataManager.dispatchEvent(") == 1 && Has(FunctionBody(hub, "send", "internal"), "BSUIDataManager.dispatchEvent(new CustomEvent(param1,param2));"),
		"every game action goes through one send");
	Expect(Has(FunctionBody(hub, "send", "internal"), "if(this.debugOn) { this.note(\"SEND \" + param1); }"), "sent events are logged only with Probe=1");

	// Backend gaps are marked in the UI.
	Expect(Has(colors, "\"Not in the game: colors go to the parts you selected before Colors\""), "the colour target gap is shown");
	Expect(Has(colors, "\"~#\" + HsbKit.hex6("), "a worked-out hex is marked with ~");
	Expect(CountOf(editor, "\"note\":\"No game data\"") == 2, "pill rules without game data are marked");
	Expect(Has(settings, "\"Open Flight Check on errors\",\"autoflight\",false,false,\"No game signal\""), "the Flight Check setting is marked");

	// Settings and files agree with the plugin.
	{
		const std::string head = "private static const BINDABLE:String = \"";
		const std::size_t at = settings.find(head);
		std::string bindable;
		if (at != std::string::npos) {
			for (std::size_t i = at + head.size(); i < settings.size() && settings[i] != '"'; ++i) {
				if (settings[i] == '\\' && i + 1 < settings.size()) ++i;
				bindable.push_back(settings[i]);
			}
		}
		Expect(bindable == hsb::kBindableKeys, "the movie's key picker binds exactly the keys the plugin accepts");
	}
	Expect(Has(hub, "internal static const PANELS:Array = [\"Power\",\"Module\",\"Credits\",\"Browser\",\"Stats\",\"Hints\",\"Cluster\"];"),
		"the movie's panel ids are the plugin's");
	{
		// Every literal setting the movie writes passes the whitelist with a value of its kind.
		const std::vector<std::string> sources = {hub, browser, settings, ReadFile(as / "HsbPillImport.as")};
		std::size_t literal = 0;
		for (const std::string& src : sources) {
			for (std::size_t at = src.find("setSetting(\""); at != std::string::npos; at = src.find("setSetting(\"", at + 1)) {
				const std::size_t s1 = at + 12;
				const std::size_t e1 = src.find('"', s1);
				if (e1 == std::string::npos || src.compare(e1, 3, "\",\"") != 0) continue;
				const std::size_t e2 = src.find('"', e1 + 3);
				if (e2 == std::string::npos) continue;
				const std::string section = src.substr(s1, e1 - s1);
				const std::string key = src.substr(e1 + 3, e2 - e1 - 3);
				std::string sample = "1";
				if (key == "AccentColor") sample = "3";
				else if (key == "AccentHex") sample = "A1B2C3";
				else if (key == "CardOpacity") sample = "0.85";
				else if (key == "ScreenMargin") sample = "40";
				else if (key == "UiScale") sample = "1.10";
				else if (key == "Density") sample = "detailed";
				else if (key == "HideAll" || key == "Find") sample = "J";
				hsb::Setting out;
				Expect(hsb::CheckSetting(section, key, sample, out), "the plugin accepts the movie's setting " + section + "." + key);
				++literal;
			}
		}
		Expect(literal >= 20, "the movie's literal settings were found");
	}
	{
		// The Settings reset writes exactly the whitelist defaults.
		const std::string reset = FunctionBody(settings, "resetAll");
		const std::size_t at = reset.find("var pairs:Array = [");
		std::size_t pairs = 0;
		if (at != std::string::npos) {
			const std::string list = reset.substr(at, reset.find(";\n", at) - at);
			for (std::size_t p = list.find("[\""); p != std::string::npos; p = list.find("[\"", p + 1)) {
				const std::size_t end = list.find("\"]", p);
				if (end == std::string::npos) break;
				std::vector<std::string> parts;
				std::string cell;
				for (std::size_t i = p + 2; i < end; ++i) {
					if (list.compare(i, 3, "\",\"") == 0) {
						parts.push_back(cell);
						cell.clear();
						i += 2;
						continue;
					}
					cell.push_back(list[i]);
				}
				parts.push_back(cell);
				hsb::Setting out;
				Expect(parts.size() == 3 && hsb::CheckSetting(parts[0], parts[1], parts[2], out) && out.isDefault,
					"Settings reset writes the default for " + (parts.size() > 1 ? parts[0] + "." + parts[1] : std::string("?")));
				++pairs;
			}
		}
		Expect(pairs == 11, "Settings reset covers every fixed setting");
	}
	Expect(Has(hub, "private static const FILE_QUEUE_MAX:int = 64;"), "the movie's file queue matches the plugin's cap");
	Expect(Has(FunctionBody(hub, "applyKey"), "case \"keyhide\": this.keyHide = v; break;") && Has(FunctionBody(hub, "applyKey"), "case \"starfiles\":") &&
		Has(FunctionBody(hub, "applyKey"), "if(param1.indexOf(\"panel.\") == 0)") && Has(FunctionBody(hub, "applyKey"), "else if(param1.indexOf(\"col.\") == 0)"),
		"the movie reads the keys the plugin applies");

	// Face proof: mapped names first, measured against a name that cannot exist.
	Expect(Has(hub, "FACES:Array = [\"$NB_Grotesk_Semibold\",\"$MAIN_Font_Bold\",\"$MAIN_Font\"];") &&
		Has(hub, "NO_FACE:String = \"$Horizon_NoSuchFace_x\";") && CountOf(hub, "$Horizon_") == 1, "face candidates are the stock mapped names");
	Expect(Has(hub, "meter.text = \"WWWWWWWW\";") && Has(hub, "meter.text = \"iiiiiiii\";") && Has(hub, "if(wide < narrow * 1.6) { return false; }") &&
		Has(hub, "Math.abs(wide - missWide) < 0.5"), "the movie's face rule matches the twin");
	Expect(Has(hub, "this.pathField([\"ModuleInfoCard_mc\",\"ModuleLabel_mc\",\"text_tf\"])"), "the fallback face is the module name field");
	Expect(Has(FunctionBody(hub, "glyphsOf"), "font.hasGlyphs(GLYPH_PROBE)") && Has(FunctionBody(hub, "embeddedFonts"), "Font.enumerateFonts(false)") &&
		!Has(FunctionBody(hub, "glyphsOf"), "enumerateFonts(true)") &&
		!Has(FunctionBody(hub, "proveFace"), "if(drew)") &&
		Has(FunctionBody(hub, "proveFace"), "this.kit.nativeDraws(label)") &&
		Has(FunctionBody(hub, "proveFace"), "draw = err.errorID == 2077 ? -4 : -2;") &&
		Has(FunctionBody(hub, "chooseListed"), "return {name:name,why:\"glyphs\"};") &&
		Has(FunctionBody(hub, "chooseListed"), "return {name:listed,why:\"glyphs\"};") &&
		Has(FunctionBody(hub, "chooseListed"), "return {name:wide,why:\"width\"};") &&
		!Has(FunctionBody(hub, "chooseListed"), "why:\"listed\"") &&
		Has(FunctionBody(hub, "chooseBold"), "this.styleIsBold(this.styleOfListed(name,param1))") &&
		Has(FunctionBody(hub, "chooseBold"), "this.styleIsBold(style)") &&
		Has(FunctionBody(hub, "styleIsBold"), "param1.toLowerCase().indexOf(\"bold\") >= 0") &&
		Has(FunctionBody(kit, "nativeDraws", "internal"), "return -1;") &&
		Has(FunctionBody(kit, "nativeDraws", "internal"), "return -2;") &&
		!Has(FunctionBody(kit, "nativeDraws", "internal"), "return true;"),
		"a listed face is ranked by hasGlyphs or width, and draw error 2077 does not count");
	Expect(Has(FunctionBody(kit, "turnUp", "internal"), "if(this.embed)") && Has(FunctionBody(kit, "turnUp", "internal"), "param1.rotation = -90;") &&
		Has(FunctionBody(kit, "turnUp", "internal"), "new BitmapData(") && Has(FunctionBody(kit, "turnUp", "internal"), "this.inked(pixels,INK_COUNT,INK_ALPHA)") &&
		Has(FunctionBody(kit, "turnUp", "internal"), "param1.rotation = 0;") &&
		Has(FunctionBody(kit, "inked", "internal"), "param1.getPixel32(x,y)") &&
		Has(browser, "k.turnUp(label)") && Has(browser, "k.turnUp(count)") &&
		!Has(browser, "label.rotation") && !Has(browser, "count.rotation"),
		"a blank turned-tab picture falls back to an upright label");
	Expect(Has(hub, "this.note(\"FONT try=\" + this.faceTries + \" pick=\" + pick + \" bold=\" + boldOk + \" fallback=\" + fallback + \" list=\" + list + \" body=\" + bodyName + \" why=\" + bodyWhy + \" head=\" + headName + \" headWhy=\" + headWhy + \" draw=\" + this.drawMark(draw));") &&
		Has(FunctionBody(hub, "noteFontList"), "this.note(line);") &&
		Has(FunctionBody(hub, "noteFontList"), "\"FONT list[\" + n + \"]=\" + name + \" type=\" + kind + \" style=\" + style") &&
		Has(FunctionBody(hub, "noteFontList"), "if(line.length > 400)") &&
		Has(FunctionBody(hub, "drawMark"), "return \"empty\";") && Has(FunctionBody(hub, "drawMark"), "return \"err\";") &&
		Has(FunctionBody(hub, "drawMark"), "return \"skip\";"),
		"the FONT lines name every embedded face and the chosen body and bold");
	Expect(Has(FunctionBody(hub, "onStage"), "this.note(\"INIT kit begin\");") && Has(FunctionBody(hub, "onStage"), "this.note(\"INIT kit end\");") &&
		Has(FunctionBody(hub, "onStage"), "this.note(\"INIT face begin\");") && Has(FunctionBody(hub, "onStage"), "this.note(\"INIT face end\");") &&
		Has(FunctionBody(hub, "onStage"), "this.note(\"INIT build begin\");") && Has(FunctionBody(hub, "onStage"), "this.note(\"INIT build end\");") &&
		Has(FunctionBody(hub, "onStage"), "this.note(\"FONT err=\" + this.errText(err));") &&
		Has(FunctionBody(hub, "proveFace"), "this.note(\"FONT phase=list begin\");") &&
		Has(FunctionBody(hub, "proveFace"), "this.note(\"FONT phase=glyphs begin\");") &&
		Has(FunctionBody(hub, "proveFace"), "this.note(\"FONT phase=width begin\");") &&
		Has(FunctionBody(hub, "proveFace"), "this.note(\"FONT phase=draw begin\");") &&
		Has(FunctionBody(hub, "proveFace"), "this.note(\"FONT phase=pick begin\");") &&
		Has(FunctionBody(hub, "proveFace"), "this.note(\"FONT err=\" + fault);") &&
		Has(FunctionBody(hub, "proveFaceWidth"), "embeds.push(true);") &&
		Has(FunctionBody(hub, "proveFaceWidth"), "if(candidate.charAt(0) == \"$\") { k++; continue; }") &&
		Has(FunctionBody(hub, "proveFaceWidth"), "boldPick.charAt(0) != \"$\"") &&
		!Has(FunctionBody(hub, "proveFaceWidth"), "nativeDraws") &&
		!Has(FunctionBody(hub, "proveFaceWidth"), "enumerateFonts") &&
		!Has(FunctionBody(hub, "proveFaceWidth"), "hasGlyphs") &&
		Has(hub, "BODY_FACES:Array = [\"NB Grotesk R Semibold\",\"NB Architekt\",\"NB Architekt Light\",\"Roboto Regular\",\"Exo 2 Regular\"];") &&
		Has(hub, "BOLD_FACES:Array = [\"NB Grotesk R Bold\",\"Roboto Bold\",\"Exo 2 Bold\"];") &&
		Has(FunctionBody(hub, "proveFace"), "if(fault.length > 0 && listed == 0)") &&
		Has(FunctionBody(hub, "proveFace"), "this.kit.embed = true;") &&
		Has(FunctionBody(hub, "proveFace"), "var head:Object = this.chooseBold(fonts,noneEmbed);") &&
		Has(FunctionBody(kit, "text", "internal"), "tf.embedFonts = this.face.length > 0 || this.boldFace.length > 0 || this.embed;") &&
		Has(FunctionBody(kit, "refreshFaces", "internal"), "tf.embedFonts = this.face.length > 0 || this.boldFace.length > 0 || this.embed;") &&
		Has(FunctionBody(kit, "fieldReport", "internal"), "\"FONT field kind=\" + kind + \" font=\" + shown + \" embed=\"") &&
		Has(FunctionBody(hub, "noteFields"), "this.note(\"FONT vanilla font=\" + shown + \" embed=\" + embedBit + \" w=\" + wide + \" n=\" + count);") &&
		InOrder(FunctionBody(hub, "fontProbe"), {"tf.embedFonts = embedOn;", "tf.defaultTextFormat = fmt;", "tf.text = \"Ab12 \" + String(PROBE_TAGS[n]);"}) &&
		Has(FunctionBody(hub, "fontProbe"), "this.note(\"FONT probe ask=\" + asked + \" embed=\" + bit + \" font=\" + shown + \" w=\" + int(tf.textWidth) + \" n=\" + tf.text.length);") &&
		Has(FunctionBody(hub, "onStage"), "this.noteFields(); this.fontProbe();") &&
		Has(FunctionBody(kit, "button", "internal"), "this.retag(t,\"button\");") &&
		Has(browser, "k.retag(tab,\"tab\");") &&
		Has(FunctionBody(hub, "proveFace"), "if(pick != \"0\") { fallback = 1; }") &&
		InOrder(FunctionBody(hub, "proveFace"), {"this.note(\"FONT err=width \" + this.errText(err));", "pick = \"0\";", "this.kit.face = \"\";", "this.kit.boldFace = \"\";", "this.kit.embed = false;"}) &&
		InOrder(FunctionBody(hub, "onStage"), {"this.note(\"FONT err=width \" + this.errText(err2));", "saved = \"0\";", "this.kit.face = \"\";", "this.kit.boldFace = \"\";", "this.kit.embed = false;"}) &&
		Has(FunctionBody(hub, "onStage"), "var savedFallback:int = saved != \"0\" ? 1 : 0;") &&
		Has(FunctionBody(hub, "onStage"), "this.note(\"BUILDER \" + VERSION + \" gold lrg=0 built=0\");") &&
		Has(FunctionBody(hub, "onStage"), "built = 1;") &&
		Has(FunctionBody(hub, "onStage"), "\" built=\" + built"),
		"a font-proof failure is logged and the builder still starts from the width check");
	Expect(Has(FunctionBody(hub, "hotText"), "if(b == null) { i++; continue; }") &&
		Has(FunctionBody(hub, "takeLines", "public"), "try { this.pushState(); }") &&
		Has(FunctionBody(hub, "takeLines", "public"), "if(!this.stateNoted)") &&
		Has(FunctionBody(hub, "takeLines", "public"), "this.note(\"INIT err=state \" + err.errorID);") &&
		Has(FunctionBody(hub, "takeLines", "public"), "this.lines.join(\"\\n\")") &&
		Has(hub, "private var stateNoted:Boolean = false;"),
		"a missing panel or a failed state push still flushes the queued lines");
	for (const auto& entry : fs::directory_iterator(as)) {
		if (entry.path().extension() != ".as") continue;
		Expect(NotesHideFaces(ReadFile(entry.path())), entry.path().filename().string() + ": log lines name faces by index only");
	}
	Expect(!NotesHideFaces("         this.note(\"FONT face=\" + this.kit.face);") && !NotesHideFaces("         this.note(\"FONT list=\" + FACES.join(\",\"));") &&
		NotesHideFaces("         this.note(\"FONT try=\" + this.faceTries);"), "the face scan catches a face name in a log line");
	Expect(Has(kit, "var n:Number = this.lrg ? Math.round(param1 * 1.2) : param1;") && Has(kit, "var floor:Number = this.lrg ? 15 : 12;"),
		"the movie's text sizes match the twin");
	Expect(!Has(hub, "fonts_horizon") && !Has(kit, "Exo") && !Has(kit, "Roboto"), "the movie names no Horizon font");

	// Number twins: the movie code that runs in game.
	Expect(FunctionBody(hub, "statText", "internal static") == R"AS(internal static function statText(param1:Object):String
      {
         if(String(param1.text) == "$CLASS") { return String.fromCharCode(param1.fValue); }
         if(param1.bPercentage) { return GlobalFunc.FormatNumberToString(Number(param1.fValue) * 100) + "%"; }
         return GlobalFunc.FormatNumberToString(Number(param1.fValue),2);
      }
)AS", "stat text follows the game card, as the twin does");
	// The list prints a part stat as the card does, so a fire rate of 0.67 does not read "0" in
	// its column: up to 2 places, none for percentages and the game's whole numbers.
	Expect(Has(FunctionBody(browser, "cellText"), "return HsbKit.num(param1,this.placesOf(param2)) + this.unitOf(param2);") &&
			Has(FunctionBody(browser, "rangeText"), "HsbKit.range(lo,hi,this.placesOf(param2)) + this.unitOf(param2)") &&
			Has(FunctionBody(browser, "placesOf"), "if(param1 == this.statId || param1 == \"value\" || param1 == \"mass\" || param1 == \"variants\") { return 0; }") &&
			Has(FunctionBody(browser, "placesOf"), "return this.statPct[param1] === true ? 0 : 2;") &&
			Has(FunctionBody(kit, "num", "internal static"), "return GlobalFunc.FormatNumberToString(n,param2);") &&
			Has(FunctionBody(kit, "range", "internal static"), "return lo == hi ? lo : lo + \"\\u2013\" + hi;") &&
			Has(editor, "HsbKit.num(rule.value,2)"),
		"list cells, group ranges and rule values show part stats to the card's places");
	Expect(Has(FunctionBody(browser, "cellValue", "internal"), "if(param2 == \"name\") { return String(param1.name); }") &&
			Has(FunctionBody(browser, "columnLabel", "internal"), "{\"name\":\"Name\",") &&
			Has(FunctionBody(browser, "openSort"), "self.setSort(String(param2),false);") && !Has(FunctionBody(browser, "openSort"), "self.sortCol =") &&
			InOrder(FunctionBody(browser, "setSort"), {"this.sortCol = param1;", "this.hsb.setSetting(\"Columns\",this.tabId + \"Sort\",", "this.hsb.saveSettings();", "this.afterFilter();"}),
		"sorting by name orders the rows by name, and every sort choice is saved so the next PartEntries keeps it");
	Expect(Has(colors, "var below:Boolean = gap.x + gap.width > w - pad;") && Has(colors, "if(below) { gap.x = bx; gap.y = y + k.u(26) + 4; }"),
		"the Colours gap marker moves under its button rather than cross the card's edge");
	// The plugin refuses a profile write it cannot back up; the player must see that, and the
	// next change must still be allowed to save.
	Expect(InOrder(FunctionBody(hub, "savePills", "internal"), {"note(\"PILLS save \" + (param1 ? \"ok\" : \"failed\")",
				"pillsSaveFailed = !param1;", "if(browser != null && pillsWarning() != was) { browser.invalidate(); }"}) &&
			Has(FunctionBody(hub, "pillsWarning", "internal"), "if(this.pillsSaveFailed) { return \"Pill changes are not saved: the pills file could not be written\"; }") &&
			[&] {
				const std::string body = FunctionBody(hub, "savePills", "internal");
				const std::size_t write = body.find("this.fileOp(\"PROFILE\",[\"WRITE\"]");
				return write != std::string::npos && !Has(body.substr(write), "lockPills(");
			}(),
		"a failed pill save is shown on screen and clears on the next save that succeeds");
	// The browser (and the Colours card, which shares its height) ends 10 px above the hints bar
	// on both movies: the large movie's bars are taller than the normal movie's.
	const std::string fit = FunctionBody(browser, "fitHeight", "internal");
	Expect(Has(fit, "var bars:Number = this.kit.u(HorizonShipBuilder.STATS_HEIGHT) + this.kit.u(HorizonShipBuilder.HINTS_HEIGHT);") &&
			Has(fit, "var room:Number = (r.height - edge * 2 - HorizonShipBuilder.BAR_GAP - 10) / sc - bars;") &&
			Has(hub, "var h:Number = k.u(STATS_HEIGHT);") && Has(hub, "var h:Number = k.u(HINTS_HEIGHT);") &&
			Has(FunctionBody(hub, "place", "internal"), "this.stats.y - BAR_GAP - this.hints.boxH * sc"),
		"the browser keeps clear of the hints and stats bars on both movies");
	Expect(Has(FunctionBody(ReadFile(as / "HsbArrange.as"), "paintBar"), "var w:Number = Math.max(k.u(680),30 + how.width + 6 + bw * 3 + 16 + 14);"),
		"the Arrange bar grows so its how-to line never runs under RESET");
	Expect(Has(FunctionBody(hub, "diffText", "internal static"), "var size:String = param1.bPercentage ? chipNumber(Math.abs(diff) * 100,0) : chipNumber(Math.abs(diff),2);") &&
		Has(FunctionBody(hub, "diffText", "internal static"), "if(size == \"0\") { return \"\"; }"), "chips follow the twin");
	{
		const auto dragRow = FunctionBody(ReadFile(as / "HsbColumns.as"), "paint", "internal");
		Expect(InOrder(dragRow, {"if(dragging)", "k.fill(g,inset,ry,w - inset * 2,rowH,7,HsbKit.SELECT,1);",
					"k.fill(g,inset + 1,ry + 9,3,rowH - 18,1.5,k.accent,1);"}) &&
				!Has(dragRow, "k.accentDim(0.6)"),
			"the dragged column row is a filled row with its accent stripe inside, without an outline");
	}
	Expect(InOrder(FunctionBody(browser, "applyColumnDefaults"), {"if(raw.length > 0)", "this.sortCol = HsbPillModel.columnId(raw);",
				"else", "this.sortCol = \"\";", "this.sortDesc = false;"}),
		"a tab with no saved sort, or Game order saved, shows the game's order rather than the last tab's sort");
	Expect(Has(FunctionBody(hub, "shortChip", "internal static"), "if(dot < 0 || param1.indexOf(\"e\") >= 0) { return param1.charAt(0); }") &&
		Has(FunctionBody(hub, "shortChip", "internal static"), "return whole.length == 2 && whole.charAt(1) == \"0\" ? param1.charAt(0) : whole;"),
		"short chips follow the twin");
	Expect(Has(FunctionBody(hub, "chipNumber", "internal static"), "var text:String = param1.toFixed(6);") &&
		Has(FunctionBody(hub, "chipNumber", "internal static"), "if(dot < 0 || text.indexOf(\"e\") >= 0) { return text; }"), "chip numbers follow the twin");
	const std::string anchor = FunctionBody(hub, "storeAnchor", "internal");
	Expect(Has(anchor, "if(Math.abs(midX - cx) >= r.width / 6)") && Has(anchor, "dx = Math.round(param2 - (r.x + this.margin));") &&
		Has(anchor, "dx = Math.round(r.x + r.width - this.margin - param4 - param2);") && Has(anchor, "var dx:Number = Math.round(param2 - (cx - param4 / 2));"),
		"anchors are stored as the twin stores them");
	const std::string resolve = FunctionBody(hub, "resolve");
	Expect(Has(resolve, "if(edge == param6) { return param4 + this.margin + off; }") && Has(resolve, "if(edge == param7) { return param4 + param5 - this.margin - param3 - off; }") &&
		Has(resolve, "if(edge == \"C\") { return param4 + (param5 - param3) / 2 + off; }"), "anchors resolve as the twin resolves them");

	// Splice notes name every method the plugin invokes.
	for (const char* method : {"hsbProbePing", "hsbTakeLines", "hsbProbeStage", "hsbSetDebug", "hsbApply", "hsbFeed", "hsbSaved", "hsbTakeFiles", "hsbFiles"}) {
		Expect(Has(splice, std::string("public function ") + method + "("), std::string("the splice adds ") + method);
	}
	Expect(Has(splice, "if(this.hsb != null && this.hsb.wantsEvent(param1, param2))") && Has(splice, "Do not return early") &&
		Has(splice, "the category grid or Arrange is open"), "the splice consumes controller events only while Horizon captures");
	Expect(Has(splice, "has no onAddedToStage") && Has(splice, "import HorizonShipBuilder;") && Has(splice, "Do not construct HorizonShipBuilderProbe here."),
		"the splice builds the hub and leaves the probe to Probe=1");
	Expect(Has(splice, "public function OnLeftStickInput(param1:Number, param2:Number, param3:Number, param4:Boolean, param5:Boolean, param6:uint):Boolean") &&
		Has(splice, "if(this.hsb != null && this.hsb.wantsStick())"), "the splice keeps the stick off the hidden lists while Horizon captures");

	// Pill profile safety: never save over a file the movie could not use, never write what it
	// could not read back, and never save before the profile reply.
	{
		const std::string profile = FunctionBody(hub, "onProfile");
		const std::string save = FunctionBody(hub, "savePills", "internal");
		const std::string json = ReadFile(as / "HsbJson.as");
		const std::string model = ReadFile(as / "HsbPillModel.as");
		Expect(Has(hub, "internal var pillsLock:String = \"loading\";"), "pill saves wait for the profile reply");
		Expect(Has(profile, "this.lockPills(param2 == \"missing\" ? \"\" : \"unreadable\");") &&
			Has(profile, "this.lockPills(count == HsbPillModel.LOAD_NEWER ? \"newer\" : \"toolong\");") &&
			InOrder(profile, {"if(param2 == \"damaged\") { this.setAsideProfile(); }", "else if(count == HsbPillModel.LOAD_BAD) { this.setAsideProfile(); }",
				"else if(count == HsbPillModel.LOAD_FAILED)", "this.lockPills(\"loadfailed\");"}) &&
			!Has(hub, "this.fileOp(\"PROFILE\",[\"BAD\"],\"\",null);"),
			"only a missing or damaged profile may be replaced, and a profile the model fails to take in is left alone");
		// Review A3: a set-aside that fails must not let the next save replace the damaged profile.
		Expect(InOrder(FunctionBody(hub, "setAsideProfile"), {"this.lockPills(\"setaside\");", "this.fileOp(\"PROFILE\",[\"BAD\"],\"\",this.onSetAside);"}),
			"saving stays locked until the plugin answers the set-aside");
		const std::string aside = FunctionBody(hub, "onSetAside");
		Expect(InOrder(aside, {"if(!param1)", "this.lockPills(param2 == \"exists\" ? \"badexists\" : \"badfailed\");", "return;",
				   "this.pillsSetAside = true;", "this.pillsBakKept = true;", "this.lockPills(\"\");", "this.runWaitingSave();"}) &&
				InOrder(FunctionBody(hub, "runWaitingSave"), {"if(!this.pillsWaiting) { return; }", "this.pillsWaiting = false;", "this.savePills();"}),
			"a failed set-aside keeps saving locked; one that works opens it and runs the save that waited");
		// Review A4: an empty or blank profile starts fresh with a line on screen, and a visit that
		// starts without a loaded profile never claims the backup holds the list just replaced.
		Expect(InOrder(profile, {"this.pillsBakKept = param2 == \"missing\";", "this.lockPills(param2 == \"missing\" ? \"\" : \"unreadable\");",
				   "if(param2 == \"missing\") { this.runWaitingSave(); }", "return;", "if(isBlank(param2))", "this.pillsEmpty = true;", "this.pillsBakKept = true;",
				   "this.lockPills(\"\");", "this.note(\"PILLS profile empty\");", "this.runWaitingSave();", "return;", "var count:int = this.pills.load(param2);"}) &&
				!Has(profile, "param2.length == 0"),
			"an empty or blank profile is a fresh start that says so, and the visit keeps the backup");
		// Review A4 NIT 3 and Review B4 NIT 1: a change made before the profile reply is saved once
		// saving opens on the pills on screen, or dropped with a line when a profile loads over it.
		Expect(InOrder(profile, {"if(count >= 0)", "this.pillsLock = \"\";", "this.pillsDropped = this.pillsWaiting;", "this.pillsWaiting = false;"}) &&
				CountOf(profile, "this.runWaitingSave();") == 2 && CountOf(hub, "this.runWaitingSave();") == 3,
			"a save refused while loading runs when saving opens on the pills shown, and is dropped with a line when a profile loads");
		Expect(Has(FunctionBody(hub, "isBlank", "internal static"), "return param1 == null || /^[ \\t\\r\\n]*$/.test(param1);") &&
				Has(ReadFile(root / "src" / "hsb_profile.h"), "return text.find_first_not_of(\" \\t\\r\\n\") == std::string_view::npos;"),
			"the movie and the plugin agree on what a blank profile is");
		Expect(InOrder(FunctionBody(ReadFile(as / "HsbPillEditor.as"), "askDelete"),
				   {"var bakLine:String = this.hsb.pillsBakKept ? \"An earlier list may be kept as a .bak backup.\" : \"Your previous list is kept as a .bak backup.\";",
					   "[\"This removes the pill from your list.\",bakLine,\"Horizon never deletes pill files you exported or imported.\"]"}),
			"the remove dialog promises the previous list only when the backup holds it");
		Expect(InOrder(save, {"if(this.pillsLock.length > 0 && !retry)", "if((this.pillsLock == \"loading\" || this.pillsLock == \"setaside\") && !this.pillsWaiting)",
				   "this.pillsWaiting = true;", "return;"}),
			"a save refused while the profile loads or is set aside waits for it");
		// Review A4 NIT 4: the plugin answers a request refused by its full queue ahead of older
		// queued ones, so an older save's reply never decides whether the pills shown are on disk.
		Expect(InOrder(save, {"var seq:int = ++this.pillsSaveSeq;", "this.fileOp(\"PROFILE\",[\"WRITE\"],text,function(param1:Boolean, param2:String):void",
				   "if(seq != pillsSaveSeq) { return; }", "var was:String = pillsWarning();", "pillsSaveFailed = !param1;", "if(param1) { pillsDropped = false; }",
				   "if(browser != null && pillsWarning() != was) { browser.invalidate(); }"}) &&
				CountOf(hub, "pillsSaveFailed = ") == 1 && CountOf(hub, "++this.pillsSaveSeq") == 1,
			"only the latest pill save's reply sets or clears the could-not-be-written line");
		const std::string warn = FunctionBody(hub, "pillsWarning", "internal");
		Expect(Has(warn, "case \"setaside\": return \"Pill changes wait: the damaged pills file is being set aside\";") &&
				Has(warn, "case \"badexists\": return \"Pill changes are not saved: the pills file is damaged\\nMove ShipBuilderPills.bad.json away, then reopen the builder"
						  "\\nIt is in Data\\\\Interface\\\\HorizonUI\\\\shipbuilder\\\\\";") &&
				Has(warn, "case \"badfailed\": return \"Pill changes are not saved: the pills file is damaged\\nIt could not be renamed to ShipBuilderPills.bad.json"
						  "\\nClose programs using the pills file, then reopen the builder\";") &&
				Has(warn, "case \"loading\": return this.pillsWaiting ? \"Pill changes wait: the pills file is still loading\" : \"\";") &&
				Has(warn, "case \"loadfailed\": return \"Pill changes are not saved: the pills file could not be loaded\";") &&
				InOrder(warn, {"if(this.pillsSaveFailed) { return \"Pill changes are not saved: the pills file could not be written\"; }",
								  "if(this.pillsDropped) { return \"Pill changes made while the pills file loaded were not kept\"; }",
								  "if(this.pillsSetAside) { return \"The damaged pills file is kept as ShipBuilderPills.bad.json\\nAn older copy may be in ShipBuilderPills.bak\"; }",
								  "if(this.pillsEmpty) { return \"The pills file was empty, so the starter pills are shown\\nAn older copy may be in ShipBuilderPills.bak\"; }"}),
			"every set-aside outcome, an empty profile and an early save are explained on screen");
		{
			// Every lock the movie sets has its own line, so saving never stops without one.
			std::set<std::string> locks;
			for (std::size_t at = hub.find("lockPills("); at != std::string::npos; at = hub.find("lockPills(", at + 1)) {
				const std::size_t end = hub.find(')', at);
				const std::string call = hub.substr(at, end == std::string::npos ? std::string::npos : end - at);
				for (const char* lead : {"lockPills(\"", "? \"", ": \""}) {
					for (std::size_t q = call.find(lead); q != std::string::npos; q = call.find(lead, q + 1)) {
						const std::size_t from = q + std::string(lead).size();
						const std::size_t close = call.find('"', from);
						if (close != std::string::npos && close > from) locks.insert(call.substr(from, close - from));
					}
				}
			}
			bool lined = locks.size() >= 9;
			for (const auto& lock : locks) lined = lined && Has(warn, "case \"" + lock + "\": return \"");
			Expect(lined, "every pill lock the movie sets has its own line on screen");
		}
		Expect(InOrder(browser, {"var pillsWarn:String = this.hsb.pillsWarning();", "var warnLines:Array = pillsWarn.split(\"\\n\");",
				   "y = this.paintNoteLine(w,pad,y,String(warnLines[wl]),HsbKit.ORANGE);"}),
			"each warning line gets its own row");
		// Review B4 SHOULD-FIX 2: Import, Export and Manage open only from the More menu, so its
		// chip is drawn even when every pill of the tab is in the row.
		{
			const std::string pillRow = FunctionBody(browser, "paintPills");
			Expect(InOrder(pillRow, {"var moreW:Number = this.pillWidth(last ? \"More\" : (more + row.length - i) + \" More\",PILL_BUTTON);",
					   "if(x + pw + gap + moreW + gap + newW > limit)", "var moreText:String = more > 0 ? more + \" More\" : \"More\";",
					   "this.hit(x,param3,mw,ph,\"more\");", "this.hit(x,param3,newW,ph,\"newpill\");"}) &&
					CountOf(pillRow, "\"more\")") == 1 && !Has(pillRow, "if(more > 0)") &&
					InOrder(FunctionBody(browser, "openMore"), {"items.push({\"label\":\"Import pills\\u2026\",\"id\":\"import\",\"accent\":true});",
								     "items.push({\"label\":\"Export / Share\\u2026\",\"id\":\"export\",\"accent\":true});",
								     "items.push({\"label\":\"Manage pills\\u2026\",\"id\":\"manage\",\"accent\":true});"}),
				"the More chip, the only way to Import, Export and Manage, is always in the pill row");
		}
		// Review B3 SHOULD-FIX 1: vanilla hides only the palette clip, so a re-feed while the game
		// hides it must not call the list's selection handler, which would send a part preview.
		Expect(InOrder(FunctionBody(browser, "refeed"), {"var was:Boolean = Boolean(list.visible);", "list.visible = false;", "list.InitializeEntries(entries);",
				   "list.visible = was;", "if(want != this.previewId && was && this.data != null && Boolean(this.data.bShowWidget))",
				   "this.previewId = want;", "this.palette().onListSelectionChanged();"}) &&
				CountOf(browser, "onListSelectionChanged()") == 1 &&
				InOrder(FunctionBody(browser, "onParts", "internal"), {"this.data = param1;", "if(!Boolean(param1.bShowWidget))", "this.previewId = \"\";", "return;"}),
			"a re-feed while the game hides the palette sends no part preview");
		// Review B4 NIT 4: a pack with many column sets keeps its list and switch inside the dialog.
		{
			const std::string importBox = ReadFile(as / "HsbPillImport.as");
			const std::string right = FunctionBody(importBox, "paintRight");
			Expect(Has(importBox, "private static const MAX_SET_LINES:int = 6;") &&
					InOrder(right, {"var colsH:Number = setCount > 0 ? k.u(26) + Math.min(setCount,MAX_SET_LINES) * k.u(19) + k.u(34) : 0;",
							   "var limit:Number = bottom - colsH;", "var setLines:int = 0;", "for(key in e.columnSets)",
							   "if(setCount > MAX_SET_LINES && setLines == MAX_SET_LINES - 1)",
							   "k.label(this,param1,y,\"+\" + (setCount - setLines) + \" more column sets\",13,HsbKit.MUTED,false,0,param3);", "break;",
							   "setLines++;", "k.toggle(g,param1,y + 2,this.useColumns);"}),
				"the Import preview lists at most six column-set lines, so its switch stays inside the dialog");
		}
		// Review A4 SHOULD-FIX 2: the lines that keep a damaged, newer or unreadable profile from
		// being saved over, each pinned so a one-character slip fails here.
		Expect(InOrder(profile, {"var count:int = this.pills.load(param2);", "if(count >= 0)", "this.pillsLock = \"\";",
				   "else if(count == HsbPillModel.LOAD_BAD) { this.setAsideProfile(); }", "else if(count == HsbPillModel.LOAD_FAILED)", "else",
				   "this.lockPills(count == HsbPillModel.LOAD_NEWER ? \"newer\" : \"toolong\");"}) &&
				CountOf(profile, "if(count >= 0)") == 1 && CountOf(profile, "this.pillsLock = \"\";") == 1,
			"only a profile that loads opens saving; a damaged one is set aside and every other result stays locked");
		const std::string loadBody = FunctionBody(model, "load", "internal");
		Expect(InOrder(loadBody, {"if(param1.length > HsbJson.MAX_CHARS) { return LOAD_TOO_BIG; }", "var data:* = HsbJson.parse(param1);",
				   "if(data == null || typeof data != \"object\" || String(data.type) != PROFILE_TYPE) { return LOAD_BAD; }",
				   "if(Number(data.version) > VERSION) { return LOAD_NEWER; }", "if(!(data.pills is Array)) { return LOAD_BAD; }", "var next:Array = [];"}) &&
				CountOf(loadBody, "return LOAD_BAD;") == 2,
			"load calls a file of the wrong type or without a pills array damaged, and a newer one newer");
		{
			std::map<std::string, long> codes;
			for (const char* name : {"LOAD_BAD", "LOAD_TOO_BIG", "LOAD_NEWER", "LOAD_FAILED"}) {
				const std::string head = std::string("internal static const ") + name + ":int = ";
				const std::size_t at = model.find(head);
				codes[name] = at == std::string::npos ? 0 : std::strtol(model.c_str() + at + head.size(), nullptr, 10);
			}
			std::set<long> distinct;
			bool negative = true;
			for (const auto& code : codes) {
				distinct.insert(code.second);
				negative = negative && code.second < 0;
			}
			Expect(negative && distinct.size() == 4, "load's four failure results are below zero and distinct, so none reads as a pill count or as another");
		}
		Expect(Has(warn, "case \"unreadable\": return \"Pill changes are not saved: the pills file could not be read\";") &&
				Has(warn, "case \"newer\": return \"Pill changes are not saved: the pills file is from a newer version\";") &&
				Has(warn, "case \"toolong\": return \"Pill changes are not saved: the pills file is too long to read\";"),
			"an unreadable, newer or too long profile is explained on screen");
		Expect(InOrder(FunctionBody(hub, "fileOp", "internal"), {"if(this.fileOut.length > FILE_QUEUE_MAX)", "var dropped:String = String(this.fileOut.shift());",
				   "var dropCb:Function = this.fileWait[dropId] as Function;", "delete this.fileWait[dropId];", "try { dropCb(false,\"\"); }",
				   "catch(err:Error) { this.note(\"FILE reply failed \" + err.errorID); }"}),
			"a request dropped from a full queue answers its caller with a failure, so a dropped READ never leaves saving waiting");
		Expect(InOrder(FunctionBody(hub, "files", "public"), {"var cb:Function = this.fileWait[id] as Function;", "delete this.fileWait[id];",
				   "try { cb(String(parts[1]) == \"1\",parts.length > 2 ? unescapeText(String(parts.slice(2).join(\"\\t\"))) : \"\"); }",
				   "catch(err:Error) { this.note(\"FILE reply failed \" + err.errorID); }"}),
			"a file reply whose callback throws is noted, and the replies after it still run");
		{
			const std::string import = ReadFile(as / "HsbPillImport.as");
			Expect(Has(import, "var usable:Boolean = e.loading != true && e.bad != true && list != null && list.length > 0;") &&
					Has(FunctionBody(import, "readOne"), "if(data != null && data.pills is Array && (data.pills as Array).length > 0)"),
				"an import entry with no pills is never usable or taken in");
		}
		// Review A3: crafted JSON never throws. Object's own member names are never keys, and the
		// parser, the model and the readers each end in a catch.
		Expect(InOrder(json, {"private static const RESERVED:Array = [\"constructor\",\"hasOwnProperty\",\"isPrototypeOf\",\"propertyIsEnumerable\","
				   "\"setPropertyIsEnumerable\",\"toLocaleString\",\"toString\",\"valueOf\"];"}) &&
				Has(FunctionBody(json, "safeKey", "internal static"), "return RESERVED.indexOf(param1) < 0;"),
			"the reserved names are Object's own members");
		for (const char* name : {"constructor", "hasOwnProperty", "isPrototypeOf", "propertyIsEnumerable", "setPropertyIsEnumerable", "toLocaleString", "toString",
				 "valueOf"}) {
			Expect(hsb::ObjectMemberName(name) && Has(json, std::string("\"") + name + "\""), std::string("the movie and the plugin both refuse ") + name);
		}
		Expect(InOrder(FunctionBody(json, "parse", "internal static"), {"try", "var p:HsbJson = new HsbJson();", "return out;", "catch(err:Error) { }", "return null;"}),
			"parse returns null instead of throwing");
		Expect(Has(FunctionBody(json, "object"), "if(this.bad || !safeKey(key)) { this.bad = true; return null; }"), "a JSON key naming an Object member makes the file invalid");
		const std::string load = FunctionBody(model, "load", "internal");
		Expect(InOrder(load, {"try", "var kept:Object = {};", "this.pills = next;", "this.keep = kept;", "return next.length;", "catch(err:Error) { }",
				   "return LOAD_FAILED;"}) && CountOf(load, "this.pills = ") == 1 && CountOf(load, "this.keep") == 1,
			"load takes a file in whole or not at all, and never throws");
		Expect(InOrder(FunctionBody(model, "readShared", "internal static"), {"try { return readSharedText(param1); }", "catch(err:Error) { }", "return null;"}),
			"readShared returns null instead of throwing");
		Expect(Has(FunctionBody(model, "tabKey", "internal static"), "return out.length > 0 && HsbJson.safeKey(out) ? out : \"Tab\";") &&
				InOrder(FunctionBody(model, "columnId", "internal static"), {"if(!HsbJson.safeKey(id)) { return \"\"; }", "spoken"}) &&
				Has(FunctionBody(model, "clean", "internal static"), "var out:Object = {\"id\":HsbJson.safeKey(id) ? id : \"\",\"name\":name};"),
			"tab keys, column ids and pill ids from files never name an Object member");
		const std::string readOne = FunctionBody(ReadFile(as / "HsbPillImport.as"), "readOne");
		Expect(InOrder(readOne, {"entry.loading = false;", "entry.bad = true;", "HsbPillModel.readShared(param4)", "entry.pills = data.pills;", "entry.bad = false;"}),
			"an import entry is bad until its file is taken in");
		Expect(InOrder(FunctionBody(hub, "apply", "public"), {"try { this.applyKey(line.substring(0,eq),line.substring(eq + 1)); }",
				   "catch(err:Error) { this.note(\"SETTINGS fault \" + err.errorID); }"}) &&
				Has(FunctionBody(hub, "applyKey"), "if(HsbJson.safeKey(param1.substring(4))) { this.columnSets[param1.substring(4)] = v; }"),
			"a settings line that fails is skipped, and a column key never names an Object member");
		Expect(InOrder(save, {"var retry:Boolean = this.pillsLock == \"full\" || this.pillsLock == \"unsavable\";", "if(this.pillsLock.length > 0 && !retry)",
				   "return;", "if(text.length > HsbJson.MAX_CHARS)", "this.lockPills(\"full\");", "return;", "if(HsbJson.parse(text) == null)",
				   "this.lockPills(\"unsavable\");", "return;", "if(retry) { this.lockPills(\"\"); }", "this.fileOp(\"PROFILE\",[\"WRITE\"],text,"}),
			"the movie never writes a profile it could not read back");
		Expect(Has(FunctionBody(hub, "pillsWarning", "internal"), "case \"unsavable\": return \"Pill changes are not saved: a pill holds data the file cannot keep\";"),
			"a profile the reader would refuse is explained on screen");
		const std::string clean = FunctionBody(model, "clean", "internal static");
		Expect(InOrder(clean, {"var extra:* = param1[key];", "var plain:Boolean = extra == null || extra is String || extra is Number || extra is Boolean;",
				   "if(plain && out[key] === undefined && "}),
			"a pill keeps only plain unknown values, so a single-pill import cannot nest the profile past the reader's depth");
		Expect(InOrder(FunctionBody(json, "parse", "internal static"), {"if(param1.length > 0 && param1.charCodeAt(0) == 0xFEFF) { param1 = param1.substring(1); }",
				   "if(param1.length > MAX_CHARS) { return null; }"}),
			"a file saved with a byte-order mark still reads");
		Expect(Has(model, "if(param1.length > HsbJson.MAX_CHARS) { return LOAD_TOO_BIG; }"), "a profile too long to parse is reported as such");
		Expect(Has(browser, "var pillsWarn:String = this.hsb.pillsWarning();"), "the browser says when pill changes are not saved");
		// Scaleform may count a character outside the Basic Multilingual Plane as one character,
		// and UTF-8 stores it in 4 bytes.
		const std::string head = "internal static const MAX_CHARS:int = ";
		const std::size_t at = json.find(head);
		const long maxChars = at == std::string::npos ? -1 : std::strtol(json.c_str() + at + head.size(), nullptr, 10);
		Expect(maxChars > 0 && static_cast<std::size_t>(maxChars) * 4 <= hsb::kMaxProfileBytes &&
			static_cast<std::size_t>(maxChars) * 4 + 64 <= hsb::kMaxRequestBytes, "the movie's largest profile fits the plugin's read and request caps");
	}

	// Card numbers are cached only for the previewed part while the palette and card are shown.
	{
		const std::string learn = FunctionBody(browser, "learn", "internal");
		Expect(InOrder(learn, {"if(param1 == null || !Boolean(param1.bShowWidget)) { return; }", "if(this.data == null || !Boolean(this.data.bShowWidget)) { return; }",
				   "if(this.cleanText(param1.sModuleName).toLowerCase() != this.cleanText(r.name).toLowerCase()) { return; }", "row.stats = {};"}),
			"ModuleInfo for another module never lands on the previewed row");
		Expect(InOrder(FunctionBody(browser, "onParts", "internal"), {"if(!Boolean(param1.bShowWidget))", "this.previewId = \"\";", "this.nativeSel = \"\";"}),
			"a closed palette forgets its preview");
		Expect(Has(browser, "private var pending:int = -1;"), "a category jump starts with nothing pending");
		Expect(Has(FunctionBody(browser, "goCategory"), "this.changeCategory(offset > 0 ? 1 : -1);") &&
			Has(FunctionBody(browser, "stepPending"), "this.changeCategory(dir);"), "category jumps move one step per event, as LB and RB do");
		Expect(Has(FunctionBody(browser, "gridKey"), "if(this.discover == null) { this.pick(int(keys[this.gridFocus])); }"),
			"the category grid takes no pick while it is still reading the ring");
		Expect(Has(learn, "row.stats[sid] = pct ? Number(s.fValue) * 100 : Number(s.fValue);") &&
			Has(FunctionBody(browser, "unitOf"), "return param1 != this.statId && this.statPct[param1] === true ? \"%\" : \"\";"),
			"percentage stats are cached, compared and shown in percent, as the game card shows them");
	}

	Expect(Has(colors, "if(!isNaN(hsbNow[0]) && !isNaN(hsbNow[1]) && !isNaN(hsbNow[2])) { this.slots[tab] = hsbNow; }") &&
		Has(FunctionBody(colors, "clamp01", "private static"), "if(isNaN(param1)) { return 0; }"), "a slot colour is never NaN");
	// While a scheme walk runs, sel is the slot the walk is on: a walk started then (another
	// preview, or Export ending the preview) must still return to the player's slot and control.
	Expect(Has(FunctionBody(colors, "walking"), "return this.steps.length > 0 || this.waitTab >= 0;") &&
			InOrder(FunctionBody(colors, "applySlots"), {"if(!this.walking())", "this.walkHome = this.sel != null ? int(this.sel.iSelectedTab) : 0;",
				"this.walkCtl = this.sel != null ? int(this.sel.iSelectedControl) : HUE;", "var home:int = this.walkHome;", "var ctl:int = this.walkCtl;",
				"this.steps.push({\"kind\":\"tab\",\"v\":home});", "this.steps.push({\"kind\":\"ctl\",\"v\":ctl});"}) &&
			InOrder(FunctionBody(colors, "discover"), {"if(!this.walking()) { this.walkHome =", "var home:int = this.walkHome;"}) &&
			InOrder(FunctionBody(colors, "onAct", "override internal"), {"case \"slot\":", "this.walkHome = at;", "this.steps.push({\"kind\":\"tab\",\"v\":at});"}) &&
			Has(FunctionBody(colors, "onPress", "override internal"), "this.walkCtl = this.sliderKind;"),
		"a colour walk started while another runs returns to the player's slot and control, not the walk's");
	Expect(Has(FunctionBody(ReadFile(as / "HsbDialog.as"), "safeFileName", "internal static"), "return device ? out + \"_\" : out;"),
		"an exported name is never a Windows device name");
	// Review B3: an export or a saved scheme never replaces a player's file of the same name.
	{
		const std::string dialog = ReadFile(as / "HsbDialog.as");
		std::size_t writes = 0;
		std::size_t shareWrites = 0;
		for (const auto& entry : fs::directory_iterator(as)) {
			if (entry.path().extension() != ".as") continue;
			const std::string text = ReadFile(entry.path());
			writes += CountOf(text, "\"WRITE\"");
			shareWrites += CountOf(text, "[\"WRITE\",\"user\",");
		}
		const std::string share = FunctionBody(hub, "writeShare", "internal");
		Expect(writes == 2 && shareWrites == 1 &&
				Has(share, "self.fileOp(param1,[\"WRITE\",\"user\",file],String(param5(n)),function(param7:Boolean, param8:String):void") &&
				Has(FunctionBody(hub, "savePills", "internal"), "this.fileOp(\"PROFILE\",[\"WRITE\"],text,"),
			"the movie writes in two places only: the pills profile, and new shared files through writeShare");
		Expect(InOrder(share, {"var n:int = param3;", "var file:String = String(param4(n)) + param2;", "self.fileOp(param1,[\"WRITE\",\"user\",file],String(param5(n)),",
					   "if(!param7 && param8 == \"exists\" && n < SHARE_TRIES)", "n++;", "attempt();", "return;",
					   "param6(param7,param7 && param8.length > 0 ? param8 : file,param7 ? n : (param8 == \"exists\" ? -1 : 0));"}) &&
				Has(hub, "internal static const SHARE_TRIES:int = 9;"),
			"a shared file whose name is taken goes to the next free number, up to nine tries, and the caller learns the name written");
		Expect(InOrder(FunctionBody(hub, "numberedName", "internal static"), {"if(param2 <= 1) { return param1.substring(0,param3); }",
					   "var tail:String = \" \" + param2;", "return HsbPillModel.trim(param1.substring(0,param3 - tail.length)) + tail;"}),
			"a numbered name keeps its number within the length cap");
		const std::string exportPill = FunctionBody(dialog, "exportPill", "internal static");
		Expect(InOrder(exportPill, {"var stem:String = safeFileName(String(param3.name));", "var text:String = HsbPillModel.pillFile(param3);",
					   "param2.writeShare(\"PILLS\",\".json\",1,function(param4:int):String { return HorizonShipBuilder.numberedName(stem,param4,MAX_STEM); },",
					   "function(param4:int):String { return text; }", "d.state = param4 ? \"ok\" : (param6 < 0 ? \"taken\" : \"fail\");",
					   "if(param4) { d.fileName = param5; }"}) &&
				!Has(exportPill, "fileOp(") && Has(dialog, "internal static const MAX_STEM:int = 40;") && hsb::kMaxFileStem == 40 &&
				Has(FunctionBody(dialog, "safeFileName", "internal static"), "out.length < MAX_STEM") &&
				InOrder(FunctionBody(dialog, "paintExport"), {"var failed:Boolean = this.state == \"fail\" || this.state == \"taken\";",
							"k.label(this,pad,y,failed ? \"Not saved to\" : \"Saved to\",12,HsbKit.MUTED);",
							"msg = this.state == \"taken\" ? \"Not saved: \" + HorizonShipBuilder.SHARE_TRIES + \" files already use this name\" : \"Could not save the file\";"}),
			"a pill export never replaces an earlier file: it takes the next free name and shows it, or says every name is taken");
		const std::string writeScheme = FunctionBody(colors, "writeScheme");
		Expect(InOrder(writeScheme, {"var nameFor:Function = function(param3:int):String { return HorizonShipBuilder.numberedName(base,param3,NAME_MAX); };",
					   "while(param2 && first < HorizonShipBuilder.SHARE_TRIES && this.schemeByName(nameFor(first)) >= 0) { first++; }",
					   "this.hsb.writeShare(\"SCHEMES\",\".ini\",first,function(param3:int):String { return HsbDialog.safeFileName(nameFor(param3)); },",
					   "return schemeText({\"name\":nameFor(param3),\"author\":param1.author,\"slots\":param1.slots});",
					   "self.note1 = param5 < 0 ? \"Not saved: \" + HorizonShipBuilder.SHARE_TRIES + \" scheme files already use this name\" : \"Could not save the scheme file\";",
					   "var written:String = nameFor(param5);", "if(param2)", "param1.name = written;", "param1.file = param4;",
					   "self.exported = {\"name\":written,\"file\":param4};"}) &&
				!Has(writeScheme, "fileOp(") && Has(colors, "private static const NAME_MAX:int = 32;") &&
				Has(FunctionBody(colors, "parseScheme", "internal static"), "if(key == \"name\") { out.name = val.substring(0,NAME_MAX); }") &&
				Has(FunctionBody(colors, "saveScheme"), "\"file\":\"\""),
			"a saved or exported scheme never replaces a file: the file and the scheme take the next free name together");
		Expect(InOrder(FunctionBody(colors, "onAct", "override internal"), {"case \"export\":",
					   "if(s != null && String(s.source) == \"user\" && String(s.file).length > 0)",
					   "this.exported = {\"name\":String(s.name),\"file\":String(s.file)};", "else if(s != null) { this.writeScheme(s,String(s.source) == \"user\"); }"}),
			"exporting a scheme of the player's own names its file and writes nothing");
	}
	// Flight Check tabs click the game's own tab bar, which selects and reports the tab itself.
	{
		const std::string flight = ReadFile(as / "HsbFlight.as");
		const std::string act = FunctionBody(flight, "onAct", "override internal");
		Expect(InOrder(act, {"entry = bar != null ? bar.GetClipByIndex(index) as EventDispatcher : null;",
				   "if(!this.hsb.clickNative(entry) && index >= 0 && index < this.tabTypes.length)",
				   "this.hsb.send(\"ShipEditor_OnFlightCheckTabChanged\",{\"tabType\":int(this.tabTypes[index])});"}),
			"a Flight Check tab click goes through the game's tab bar");
		Expect(Has(FunctionBody(hub, "clickNative", "internal"), "param1.dispatchEvent(new MouseEvent(MouseEvent.CLICK));"),
			"the hub presses the vanilla control with a plain click");
		Expect(Has(FunctionBody(flight, "nativeTabs"), "return host.FlightCheck_mc.FlightCheckCategories_mc;") &&
			Has(FunctionBody(flight, "selectedTab"), "var n:int = int(bar.selectedIndex);"), "the highlighted tab is the game's selected tab");
		const std::string readOnly = FunctionBody(browser, "setReadOnly", "internal");
		Expect(Has(hub, "this.browser.setReadOnly(flightOn);") && !Has(hub, "this.browser.readOnly =") &&
				InOrder(readOnly, {"if(this.readOnly == param1) { return; }", "this.endFind();", "this.closeGrid();", "this.invalidate();"}),
			"opening or closing Flight Check repaints the list in its read-only view");
		// Leaving Flight Check, the game refills its hidden list in game order (PartEntries, then the
		// palette's Update) while Horizon's list is still read-only; without a fresh feed a hover or
		// click would pick the part at that row of the game's order.
		Expect(InOrder(readOnly, {"if(param1)", "else", "this.rebuild();", "this.refeed();", "this.ensureVisible(this.selId);", "this.invalidate();"}),
			"leaving Flight Check rebuilds the grouped rows and feeds the hidden list again");
		Expect(Has(FunctionBody(browser, "paint", "internal"), "if(!this.readOnly) { y = this.paintStrip(w,pad,y); }") &&
				Has(FunctionBody(browser, "paintStripTop"), "if(!this.upgrade && live) { this.hit(param2,y,title.width + 6,k.u(32),\"grid\"); }") &&
				Has(FunctionBody(browser, "findBox"), "if(live) { this.hit(param1,param2,param3,param4,\"find\"); }"),
			"the read-only list offers no pills, sort, columns, category steps or Find");
	}

	// Hide all folds the tabbed panels to their tabs (mockup 12), and opening any tab shows all.
	{
		Expect(Has(FunctionBody(hub, "shown"), "return !this.hideAll || TABBED[param1] == true;") &&
				Has(FunctionBody(hub, "folded"), "return this.collapsed[param1] == true || this.hideAll;") &&
				!Has(hub, "this.collapsed[\"Browser\"] == true") && Has(hub, "this.browser.collapsed = this.folded(\"Browser\");"),
			"Hide all leaves each panel's tab on screen");
		Expect(InOrder(FunctionBody(hub, "setCollapsed", "internal"), {"if(!param2 && this.hideAll) { this.toggleHide(); }", "if(param2) { this.collapsed[param1] = true; }"}),
			"opening a tab while everything is folded brings every panel back");
	}

	const std::string probe = ReadFile(as / "HorizonShipBuilderProbe.as");
	Expect(Has(probe, "captureOn = false") && Has(probe, "enumerateFonts(false)") && !Has(probe, "enumerateFonts(true)") && !Has(probe, "stopPropagation") &&
		!Has(probe, "Keyboard.F9") && Has(probe, "PROBE off"), "the debug probe stays quiet and swallows nothing");
}

// ---- plugin pins --------------------------------------------------------------------------------

static void CheckPlugin(const fs::path& root)
{
	const std::string plugin = ReadFile(root / "src" / "probe.cpp");
	Expect(!plugin.empty(), "plugin source read");
	Expect(Has(plugin, "ProbeMayAppend") && Has(plugin, "ShouldRestoreWndProc") && Has(plugin, "DllMain") && Has(plugin, "AdvanceFrame"),
		"the plugin keeps its log guard, unhook rule and movie hook");
	Expect(!Has(plugin, "SendMessage") && Has(plugin, "PostMessageW"), "the job side never waits on the window");
	Expect(Has(plugin, "if (invoked && ping.rfind(\"0.2\", 0) == 0) g_movieGen.store(kMovieGen);"), "only a 0.2 movie gets fed input");
	Expect(Has(plugin, "constexpr std::size_t kFileQueueCap = 64;"), "the plugin's file queue matches the movie's cap");

	const auto jobA = plugin.find("JOBTICK-BEGIN");
	const auto jobB = plugin.find("JOBTICK-END");
	Expect(jobA != std::string::npos && jobB != std::string::npos && jobB > jobA, "job tick is marked");
	if (jobA != std::string::npos && jobB != std::string::npos && jobB > jobA) {
		const std::string job = plugin.substr(jobA, jobB - jobA);
		Expect(!Has(job, "Invoke") && !Has(job, "SetWindowLongPtr") && !Has(job, "_wfopen"), "the job tick neither calls Scaleform nor opens files itself");
		Expect(Has(job, "RunFileJobs()"), "file requests run on the job tick");
	}

	const std::string wnd = CppBody(plugin, "LRESULT CALLBACK ProbeWnd(");
	const std::string input = CppBody(plugin, "bool HandleBuilderInput(");
	const std::string typed = CppBody(plugin, "void FeedTypedChars(");
	Expect(!wnd.empty() && !input.empty() && !typed.empty(), "the window procedure and input path are present");
	Expect(Has(wnd, "if (g_menuOpen.load() && g_movieGen.load() == kMovieGen) {\n\t\tif (HandleBuilderInput(hwnd, msg, wp, lp)) return 0;"),
		"input is handled only while a 0.2 builder is open");
	for (const std::string* body : {&wnd, &input, &typed}) {
		Expect(!Has(*body, "Fact(") && !Has(*body, "_wfopen") && !Has(*body, "Invoke") && !Has(*body, "SetWindowLongPtr"),
			"the window thread logs nothing per message, opens no file and never calls Scaleform");
	}
	Expect(Has(input, "hsb::PointerEdge(!release, release, false, hsb::HotContains(hot, sx, sy), g_buttonsEaten.Held(button));") &&
		Has(input, "g_buttonsEaten.Set(button, !release && call.eat);"), "buttons follow PointerEdge, and a release follows its press");
	Expect(Has(input, "hsb::PointerEdge(false, false, true, hsb::HotContains(hot, sx, sy), false);") && Has(input, "hsb::WheelSteps(GET_WHEEL_DELTA_WPARAM(wp), g_wheelRest);"),
		"the wheel follows PointerEdge and keeps fine-wheel remainders");
	Expect(Has(input, "const hsb::KeyCall call = hsb::KeyPress(vk, KeyChar(vk), ctrl, alt, shift, repeat, in);") && Has(input, "if (!repeat) g_keysEaten.Set(vk, call.eat);") &&
		Has(input, "g_eatChar = eat;"), "keys follow KeyPress, and a character goes with its key");
	Expect(InOrder(input, {"if (!repeat) g_keysEaten.Set(vk, call.eat);", "const bool eat = call.eat || (repeat && g_keysEaten.Held(vk));", "return eat;"}),
		"the repeats of a key Horizon took stay Horizon's until its release");
	Expect(Has(input, "case WM_INPUT:\n\t\tg_cRaw.fetch_add(1);\n\t\treturn false;"), "raw input is counted and passed on");
	Expect(Has(input, "case WM_MOUSEMOVE:") && Has(input, "if (hsb::MoveEdge().feed) Feed(\"M M \"") && Has(input, "return false;\n\t}\n\tcase WM_LBUTTONDOWN:"),
		"moves are fed and never swallowed");
	Expect(Has(plugin, "// Window thread only.\nhsb::PressLedger g_keysEaten;\nhsb::PressLedger g_buttonsEaten;\n") &&
		CountOf(plugin, "g_keysEaten.") == CountOf(input, "g_keysEaten.") + CountOf(wnd, "g_keysEaten.") &&
		CountOf(plugin, "g_buttonsEaten.") == CountOf(input, "g_buttonsEaten.") + CountOf(wnd, "g_buttonsEaten."), "only the window thread touches the press ledgers");
	Expect(Has(typed, "ToUnicodeEx(vk, scan, state, buf, 4, 4, GetKeyboardLayout(0));") && Has(typed, "if (!hsb::CharForText(code, in)) continue;"),
		"typed characters keep the dead-key state and pass CharForText");
	Expect(Has(plugin, "Fact(\"input\", CountsNow());"), "the close line holds counts only");

	// The Win32 file code lives in hsb_win32_files.h, so tests/profile_disk_test.cpp runs the
	// same code on a real disk; probe.cpp keeps no copy of its own.
	const std::string w32 = ReadFile(root / "src" / "hsb_win32_files.h");
	Expect(Has(plugin, "#include \"hsb_win32_files.h\"") && Has(plugin, "using hsb::w32::Win32ProfileDisk;") && Has(plugin, "using hsb::w32::ReadCapped;") &&
			Has(plugin, "using hsb::w32::WriteReplace;") && !Has(plugin, "bool ReadCapped(") && !Has(plugin, "bool WriteReplace(") &&
			!Has(plugin, "class Win32ProfileDisk") && !Has(plugin, "std::string NarrowPath("),
		"the plugin uses the shared Win32 file code");
	{
		const std::string diskTest = ReadFile(root / "tests" / "profile_disk_test.cpp");
		Expect(Has(diskTest, "#include \"hsb_win32_files.h\""), "the Windows disk test runs the plugin's own file code");
		std::size_t calls = 0;
		std::size_t inFolder = 0;
		for (const std::string& call : {std::string("Delete") + "FileW(", std::string("Remove") + "DirectoryW("}) {
			for (std::size_t at = diskTest.find(call); at != std::string::npos; at = diskTest.find(call, at + call.size())) {
				++calls;
				const std::string arg = diskTest.substr(at + call.size(), 12);
				if (arg.rfind("PathOf(", 0) == 0 || arg.rfind("dir.c_str()", 0) == 0 || arg.rfind("base.c_str()", 0) == 0) ++inFolder;
			}
		}
		Expect(calls > 0 && calls == inFolder && Has(diskTest, "const std::wstring base = std::wstring(tmp) + L\"hsb-profile-test-\" + std::to_wstring(GetCurrentProcessId()) + L\"\\\\\";") &&
				Has(diskTest, "g_folder = base + L\"My Games\\\\Starfield\\\\Data\\\\Interface\\\\HorizonUI\\\\shipbuilder\\\\\";"),
			"the Windows disk test clears files only in its own temp folder");
	}
	const std::string runFile = CppBody(plugin, "std::string RunFileRequest(");
	const auto diskAt = w32.find("class Win32ProfileDisk final : public ProfileDisk {");
	const auto diskEnd = diskAt == std::string::npos ? std::string::npos : w32.find("\n};\n", diskAt);
	const std::string disk = diskEnd == std::string::npos ? std::string() : w32.substr(diskAt, diskEnd - diskAt);
	Expect(!runFile.empty() && CountOf(runFile, "BuilderFileMayTouch(") >= 2 &&
			Has(disk, "bool MayTouch(ProfileFile file, bool write) override { return BuilderFileMayTouch(NarrowPath(PathOf(file)), write); }"),
		"every builder file goes through BuilderFileMayTouch");
	Expect(Has(runFile, "Win32ProfileDisk disk(g_docsBuilder);") && Has(runFile, "hsb::ProfileResult result = hsb::ProfileRead(disk, g_profileState);") &&
			Has(runFile, "hsb::ProfileResult result = hsb::ProfileWrite(disk, g_profileState, hsb::UnescapeText(r.body));") &&
			Has(runFile, "hsb::ProfileResult result = hsb::ProfileSetAside(disk, g_profileState);") && !Has(plugin, "CopyFileW(") && !Has(w32, "CopyFileW("),
		"the profile's read, write and set-aside follow hsb_profile.h in the Documents shipbuilder folder");
	Expect(Has(plugin, "// Job thread only.\nhsb::ProfileState g_profileState;\n") && CountOf(plugin, "g_profileState") == CountOf(runFile, "g_profileState") + 1,
		"only the file jobs touch the profile hold");
	// Review A4: each line of the profile disk, so a slip in one is not passed by every check.
	Expect(Has(disk, "std::wstring PathOf(ProfileFile file) const { return folder_ + WidenAscii(ProfileFileName(file)); }"),
		"each profile file has its own path (names checked in CheckProfile)");
	Expect(InOrder(disk, {"bool Exists(ProfileFile file) override", "if (GetFileAttributesW(PathOf(file).c_str()) != INVALID_FILE_ATTRIBUTES) return true;",
				   "const DWORD err = GetLastError();", "return err != ERROR_FILE_NOT_FOUND && err != ERROR_PATH_NOT_FOUND;"}),
		"a profile file counts as missing only when the system says so");
	Expect(Has(disk, "bool Read(ProfileFile file, std::size_t cap, std::string& out) override { return ReadCapped(PathOf(file), cap, out); }") &&
			Has(disk, "bool WriteReplace(ProfileFile file, std::string_view text) override { return w32::WriteReplace(PathOf(file), std::string(text)); }") &&
			Has(disk, "void EnsureDir() override { EnsureDirsFor(PathOf(ProfileFile::kProfile)); }"),
		"the profile disk reads with the cap it is given, writes the file it is given, and makes the profile's folder");
	const std::string renameNew = CppBody(w32, "inline MoveResult RenameNew(");
	Expect(Has(disk, "MoveResult MoveNoReplace(ProfileFile from, ProfileFile to) override { return RenameNew(PathOf(from), PathOf(to)); }") &&
			InOrder(renameNew, {"if (MoveFileExW(from.c_str(), to.c_str(), MOVEFILE_WRITE_THROUGH)) return MoveResult::kOk;", "const DWORD err = GetLastError();",
						   "return err == ERROR_ALREADY_EXISTS || err == ERROR_FILE_EXISTS ? MoveResult::kExists : MoveResult::kFailed;"}) &&
			!Has(disk, "MOVEFILE_REPLACE_EXISTING") && !Has(renameNew, "MOVEFILE_REPLACE_EXISTING") && CountOf(w32, "MOVEFILE_REPLACE_EXISTING") == 1 &&
			!Has(plugin, "MOVEFILE_REPLACE_EXISTING") && !Has(plugin, "MoveFileExW("),
		"a set-aside never replaces an earlier bad copy");
	Expect(InOrder(runFile, {"if (ok) payload = std::move(result.payload);", "else failReason = std::move(result.payload);"}) &&
			Has(runFile, "if (!ok) payload = failReason;"),
		"a failed profile request tells the movie why");
	Expect(Has(runFile, "ok = ReadCapped(path, hsb::kMaxShareBytes, payload) && !hsb::HasNul(payload);") &&
			Has(runFile, "if (dirs.empty() || body.size() > hsb::kMaxShareBytes) break;"),
		"a share file with a NUL byte is refused, and share files are read and written within their cap");
	Expect(InOrder(CppBody(w32, "inline bool WriteFlushed("), {std::string("_wf") + "open_s(&file, path.c_str(), L\"wb\")",
				   "const bool wrote = fwrite(text.data(), 1, text.size(), file) == text.size();",
				   "const bool flushed = wrote && fflush(file) == 0 && _commit(_fileno(file)) == 0;", "const bool closed = fclose(file) == 0;",
				   "return flushed && closed;"}),
		"a file is written whole and flushed to disk, or the write fails");
	const std::string writeReplace = CppBody(w32, "inline bool WriteReplace(");
	Expect(InOrder(writeReplace, {"const std::wstring temp = path + L\".tmp\";", "if (!WriteFlushed(temp, text)) return false;",
				   "MoveFileExW(temp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH)"}),
		"a write goes to a .tmp twin, is flushed to disk, then renamed over the file");
	// Review B3: an export or a saved scheme never replaces a player's file of the same name.
	const std::string writeNew = CppBody(w32, "inline MoveResult WriteNew(");
	Expect(InOrder(writeNew, {"if (GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES) return MoveResult::kExists;",
				   "const std::wstring temp = path + L\".tmp\";", "if (!WriteFlushed(temp, text)) return MoveResult::kFailed;", "return RenameNew(temp, path);"}) &&
			!Has(writeNew, "MOVEFILE_REPLACE_EXISTING") && !Has(writeNew, "MoveFileExW("),
		"a new file goes to a .tmp twin, flushed, and is renamed only to a name no file or folder holds");
	Expect(InOrder(runFile, {"if (dirs.empty() || body.size() > hsb::kMaxShareBytes) break;", "EnsureDirsFor(path);",
				   "const hsb::MoveResult wrote = WriteNew(path, body);", "ok = wrote == hsb::MoveResult::kOk;", "if (ok) payload = r.args[1];",
				   "else if (wrote == hsb::MoveResult::kExists) failReason = std::string(hsb::kShareExists);"}) &&
			!Has(runFile, "WriteReplace(") && Has(plugin, "using hsb::w32::WriteNew;") && hsb::kShareExists == "exists",
		"a share write makes a new file and never replaces one; a name already taken fails with exists");
	Expect(InOrder(CppBody(w32, "inline bool ReadCapped("), {"if (out.size() + n > cap) {", "fits = false;", "out.append(buf, n);",
				   "const bool failed = ferror(file) != 0;", "fclose(file);", "if (!fits || failed) out.clear();", "return fits && !failed;"}),
		"a read over its cap, or one that fails partway, never passes for the whole file");
	Expect(InOrder(CppBody(w32, "inline void EnsureDirsFor("), {"for (wchar_t c : dir) {", "built.push_back(c);",
				   "if (c == L'\\\\' || c == L'/') CreateDirectoryW(built.c_str(), nullptr);", "CreateDirectoryW(dir.c_str(), nullptr);"}),
		"a write first makes every folder on its way");
	Expect(InOrder(runFile, {"if (!hsb::ParseFileRequest(line, r)) {", "const std::string id = hsb::RequestId(line);",
			   "return id.empty() ? std::string() : hsb::FileReply(id, false, \"\");"}), "a request that does not parse is answered");
	const std::string writeIni = CppBody(plugin, "void WriteIniNow(");
	Expect(InOrder(writeIni, {"const bool exists = FileExists(g_iniPath);", "const bool readOk = exists && ReadCapped(g_iniPath, kUserIniCap, existing);",
			   "if (!hsb::UserReadAllowsWrite(exists, readOk)) {",
			   "RequeueUpdates(updates);", "hsb::MergeSettings(existing, updates);", "if (!WriteReplace(g_iniPath, merged)) {", "RequeueUpdates(updates);"}),
		"the user ini is merged only after a full read, and a skipped or failed save is retried");
	Expect(Has(CppBody(plugin, "bool CoreIniMayRead("), "return hsb::HudIniMayRead(NarrowPath(path), NarrowPath(HudIniDir()));") &&
		Has(CppBody(plugin, "std::wstring HudIniDir("), R"CPP(return dir + L"\\Data\\Interface\\HorizonUI\\";)CPP"),
		"the HUD ini is read from the HUD's own folder only");
	for (const std::string* code : {&plugin, &w32}) {
		Expect(!Has(*code, std::string("Delete") + "File") && !Has(*code, "_wremove") && !Has(*code, "_wunlink") && !Has(*code, std::string("Remove") + "Directory"),
			"a bad profile is renamed, never deleted");
	}
	Expect(Has(plugin, "Fact(\"files\""), "file jobs are logged");
	const std::string apply = CppBody(plugin, "void BuildApply(");
	Expect(Has(apply, "const std::wstring hudDir = HudIniDir();") && Has(apply, "FileExists(hudDir + L\"HorizonUI.user.ini\")") &&
		Has(apply, "FileExists(hudDir + L\"HorizonUI.default.ini\")"), "the HUD ini files are looked up in the HUD's folder");
	Expect(InOrder(CppBody(plugin, "void NoteMovieLine("), {"if (!set && (body == \"open\" || body == \"saved\" || body == \"cancel\")) {",
			   "Fact(\"movie\", clean);", "return;", "++g_setRejected;"}),
		"Arrange open, saved and cancel notes are logged, not counted as refused settings");
	Expect(Has(apply, "const hsb::HudAccent hud = hsb::LayerHudAccent(coreUser, coreDefault);") &&
		Has(apply, "const int coreAccent = coreFound ? hsb::ResolveAccent(hud.color, coreHex, false, 0, \"\") : -1;"),
		"the HUD accent is layered as the HUD layers it");
	for (const char* key : {"accent=", "hex=", "core=", "coreaccent=", "corehex=", "probe=", "margin=", "conflict=", "starfiles=", "keys=", "opacity=", "scale=",
			 "density=", "bymaker=", "remember=", "notice=", "keyhide=", "keyfind=", "panel.", "col.", "ArrangeBarX=", "ArrangeBarY="}) {
		Expect(Has(apply, std::string("\"") + key), std::string("the plugin applies ") + key);
	}
	Expect(Has(plugin, "hsb::MergeSettings(") && Has(plugin, "Fact(\"ini\", \"user file merged n=\""), "the user ini is merged through the whitelist");
	Expect(!Has(plugin, "VK_F9"), "F9 is never a plugin key");
}

// ---- docs, package and versions ---------------------------------------------------------------

static void CheckDocs(const fs::path& repo, const fs::path& root)
{
	const std::string readme = ReadFile(root / "README_P0.md");
	const std::string lua = ReadFile(repo / "xmake.lua");
	const std::string rc = ReadFile(root / "res" / "HorizonShipBuilder.rc.in");
	const std::string vortex = ReadFile(root / "package_vortex.sh");
	const std::string defaults = ReadFile(root / "Interface" / "HorizonUI" / "shipbuilder" / "HorizonShipBuilder.default.ini");

	Expect(std::string(HSB_FILE_VERSION_STR) == "0.2.0.0", "plugin version is 0.2.0.0");
	Expect(Has(lua, "set_version(\"0.2.0\")") && Has(lua, "set_version(\"0.43.0.33\")"), "the builder target is 0.2.0 and the core version stays");
	Expect(Has(lua, "target(\"HorizonShipBuilder\")") && Has(lua, "target(\"probe_logic_test\")") && Has(lua, "set_default(false)") &&
			InOrder(lua, {"target(\"profile_disk_test\")", "set_default(false)", "add_files(\"shipbuilder/tests/profile_disk_test.cpp\")"}) &&
			Has(readme, "xmake build profile_disk_test"),
		"xmake targets, and the readme says how to run the Windows disk test");
	Expect(Has(rc, "Horizon Ship Builder") && !Has(rc, "0.43"), "the resource names the builder and not the HUD version");

	Expect(Has(readme, "# Horizon Ship Builder 0.2.0.0") && Has(readme, "HorizonShipBuilder-0.2.0.0.zip"), "the readme names 0.2.0.0");
	Expect(Has(readme, "xmake build -y HorizonShipBuilder") && Has(readme, "Data\\Interface\\spaceshipeditormenu.swf") &&
		Has(readme, "Data\\Interface\\spaceshipeditormenu_lrg.swf") && Has(readme, "Starfield - Interface.ba2") && Has(readme, "spaceshipeditormenu*.swf") &&
		Has(readme, "HorizonShipBuilder_vanilla_backup") && Has(readme, "throwaway save") && Has(readme, "game root"), "the readme keeps build, install and restore");
	Expect(Has(readme, "copy /Y shipbuilder\\actionscript\\Hsb*.as shipbuilder\\work\\normal\\") && Has(readme, "copy /Y shipbuilder\\actionscript\\Hsb*.as shipbuilder\\work\\lrg\\"),
		"the readme copies every Horizon class into both movies");
	Expect(Has(readme, "\n- `spaceshipeditormenu.swf`, 260994 bytes: `6A66089EE9410ECB126B4BEDE8BED81551E5661555AA1F50FA217C495404C2EC`\n") &&
		Has(readme, "\n- `spaceshipeditormenu_lrg.swf`, 260965 bytes: `3457A49CF9B79A346C4B3FCFA7EF360B10CCC86D41899B6D8004DF12E90F2C67`\n") &&
		Has(readme, "\n- `spaceshipeditormenu_assetlibrary2.swf`, 151358 bytes: `2B6D854C3C66973C2948246D1D1DA21A3ADA314B5FDD1899DA375FBCCB8052BC`\n") &&
		Has(readme, "Stop and report it rather than splicing."), "the readme checks the splice source against the stock movies");
	Expect(Has(readme, "interface/spaceshipeditormenu_lrg.swf") && Has(readme, "Creations included") && Has(readme, "another mod adds") &&
		Has(readme, "Do not enable StarUI Ship Builder with this mod."), "the readme keeps the conflict checks");
	Expect(Has(readme, "## Why the 0.1 buttons were dead (p5)") && Has(readme, "23 left-button press and release pairs") && Has(readme, "MouseEvent.CLICK"),
		"the readme explains the dead-button mechanism");
	Expect(Has(readme, "`FACT input | presses=N eaten=M ... raw=R`") && Has(readme, "`CATEGORIES read total=`") && Has(readme, "FONT try=") &&
		Has(readme, "ping=0.2.0.0") && Has(readme, "thread=hud-advance"), "the readme names the log lines the gates read");
	Expect(Has(readme, "## Backend gaps, shown in the UI") && Has(readme, "No game data") && Has(readme, "No game signal") &&
		Has(readme, "Not in the game: colors go to the parts you selected before Colors"), "the readme lists the marked backend gaps");
	Expect(Has(readme, "## Unknowns") && Has(readme, "Every stock language config maps all three") && Has(readme, "needs no other Horizon mod"),
		"the readme lists the unknowns and stands alone");
	for (const auto& event : VanillaEvents()) Expect(Has(readme, "`" + event + "`"), "the readme lists " + event);
	Expect(!Has(readme, "Data folder as the mod root"), "the readme does not call Data the mod root");
	Expect(Has(readme, "The rename never replaces an existing `ShipBuilderPills.bad.json`") && Has(readme, "is never replaced") &&
		Has(readme, "flushed to disk") && Has(readme, "holds a NUL byte, or cannot be copied to `.bak`") &&
		Has(readme, "`Move ShipBuilderPills.bad.json away, then reopen the builder`") && !Has(readme, "renamed to `ShipBuilderPills.bad.json`, so it is kept"),
		"the readme says how a damaged profile is set aside and when a profile save is skipped");
	Expect(Has(readme, "unless the old profile is empty or blank") && Has(readme, "A profile that is not valid pill JSON, or holds NUL bytes, is renamed") &&
			Has(readme, "keeps `ShipBuilderPills.bak` as it was until the builder closes") && Has(readme, "then copy `ShipBuilderPills.bak` over it") &&
			Has(readme, "`The pills file was empty, so the starter pills are shown`") && !Has(readme, "the second save replaces it") &&
			!Has(readme, "A profile the movie cannot read, including one holding NUL bytes, is renamed"),
		"the readme says which profiles are renamed, when the backup is kept, and how to restore it");
	Expect(Has(readme, "exported pills and color schemes. A file already there is never replaced.") &&
			Has(readme, "gets the next free number, up to 9 (`Desert 2.ini`, holding `Name=Desert 2`)") &&
			Has(readme, "never over any file for an export or a scheme") && Has(readme, "the second export is `<name> 2.json`, and the first file is unchanged") &&
			!Has(readme, "renamed over the old one."),
		"the readme says an export or a saved scheme never replaces a file, and the gates check it");

	Expect(Has(vortex, "00 Ship Builder/SFSE/Plugins/HorizonShipBuilder.dll") && Has(vortex, "00 Ship Builder/Interface/spaceshipeditormenu.swf") &&
		Has(vortex, "00 Ship Builder/Interface/spaceshipeditormenu_lrg.swf") && Has(vortex, "HorizonShipBuilder.default.ini") &&
		Has(vortex, "fomod/info.xml") && Has(vortex, "fomod/ModuleConfig.xml") && Has(vortex, "<Author>Moragar</Author>") &&
		Has(vortex, "game root") && !Has(vortex, "Data/Data"),
		"the package is a FOMOD of the plugin, both movies and the default ini");
	Expect(Has(readme, "fomod/info.xml") && Has(readme, "fomod/ModuleConfig.xml") && Has(readme, "font_marker_gate.py") &&
		!Has(readme, "font_export_gate.py") && Has(readme, "00 Ship Builder"),
		"the readme tells the Windows build to produce the FOMOD and to run the font marker gate");
	Expect(Has(vortex, "6A66089EE9410ECB126B4BEDE8BED81551E5661555AA1F50FA217C495404C2EC") &&
		Has(vortex, "3457A49CF9B79A346C4B3FCFA7EF360B10CCC86D41899B6D8004DF12E90F2C67") &&
		Has(vortex, "grep -a -q -F 'HorizonShipBuilder'"),
		"the packager rejects a stock movie and a movie with no splice marker");

	// Every key in the shipped defaults is whitelisted and is its own default.
	std::string section;
	std::size_t keys = 0;
	std::istringstream in(defaults);
	std::string line;
	while (std::getline(in, line)) {
		const std::string name = hsb::SectionName(line);
		if (!name.empty()) {
			section = name;
			continue;
		}
		std::string k, v;
		if (!hsb::SplitKey(line, k, v)) continue;
		hsb::Setting out;
		Expect(hsb::CheckSetting(section, k, v, out) && out.isDefault, "default ini " + section + "." + k + " is a whitelisted default");
		++keys;
	}
	Expect(keys >= 35, "the default ini lists every setting");
	Expect(Has(defaults, "AccentColor=9") && Has(defaults, "Probe=0") && Has(defaults, "HideAll=H") && Has(defaults, "Find=/"), "default accent, probe and keys");
}

int main()
{
	CheckGuard();
	CheckFace();
	CheckNumbers();
	CheckInput();
	CheckSettings();
	CheckFiles();
	CheckProfile();
	Expect(hsb::kAccentGold == 0xE8C547, "default accent is gold");
	Expect(hsb::ResolveAccent(-1, "", false, 3, "") == hsb::kAccentDefault && hsb::ResolveAccent(-1, "", true, 3, "") == 3,
		"follow uses the HUD accent only when the HUD ini is found");
	Expect(hsb::ResolveAccent(13, "E8C547", false, 3, "") == 13 && hsb::ResolveAccent(13, "zz", false, 3, "") == hsb::kAccentDefault, "a bad custom hex falls back to gold");

	fs::path repo = fs::path(__FILE__).parent_path().parent_path().parent_path();
#ifdef HSB_REPO_ROOT
	if (std::string(HSB_REPO_ROOT).size() > 0) repo = fs::path(HSB_REPO_ROOT);
#endif
	const fs::path root = repo / "shipbuilder";
	ScanTree(root);
	CheckMovie(root);
	CheckPlugin(root);
	CheckDocs(repo, root);

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "probe_logic_test passed\n";
	return 0;
}
