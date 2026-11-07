// Purpose: check the probe's read-only rules without the game.
// Author: Moragar. Last modified: 2026-11-06.

#include "hsb_arrange.h"
#include "hsb_guard.h"
#include "hsb_version.h"

#include <filesystem>
#include <fstream>
#include <iostream>
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
	Expect(std::string(HSB_FILE_VERSION_STR) == "0.1.0.0", "plugin version is 0.1.0.0");

	const std::string gold = ReadFile(root / "actionscript" / "HorizonShipBuilder.as");
	Expect(gold.find("0.1.0.0") != std::string::npos, "gold movie version");
	Expect(gold.find("E8C547") != std::string::npos, "gold accent number");
	Expect(gold.find("ARRANGE PANELS") != std::string::npos, "arrange entry button");
	Expect(gold.find("COVERS THE SHIP VIEW") != std::string::npos, "overlap chip");
	Expect(gold.find("SELECTED MODULE") != std::string::npos, "module label");
	Expect(gold.find("PARTS BROWSER") != std::string::npos, "browser label");
	Expect(gold.find("ModulePalette_mc") != std::string::npos, "parts list uses the game clip");
	Expect(gold.find("HangarInfoPanel_mc") != std::string::npos, "hangar overview is recognized");
	Expect(gold.find("assignSpots") == std::string::npos, "hidden panels are not grabbed by proximity");
	Expect(gold.find("sample.embedFonts") == std::string::npos, "embed flag is not copied from the first field");
	Expect(gold.find("embedFonts = false") != std::string::npos, "horizon text does not embed a subset face");
	Expect(gold.find("findLatinField") != std::string::npos, "horizon text looks for a latin face");
	Expect(gold.find("param1 == \"Browser\"") != std::string::npos, "parts list stays on the menu");
	Expect(gold.find("param1 == \"Power\"") != std::string::npos && gold.find("param1 == \"Stats\"") != std::string::npos,
		"power and the footer stay on the menu");
	Expect(gold.find("r.y + 180") != std::string::npos, "settings sits below the credit strip");
	Expect(gold.find("700 * r.width") == std::string::npos, "settings is not parked on the credits");
	Expect(gold.find("this.sel = \"Power\"") == std::string::npos, "arrange does not start on power");
	Expect(gold.find("defaultSel") != std::string::npos, "selection starts at the first live handle");
	Expect(gold.find("moveNative") != std::string::npos, "a drag translates the game clip");
	Expect(gold.find("panelMovable") != std::string::npos, "only safe panels are handles");
	Expect(gold.find("param1.embedFonts") != std::string::npos, "an embedded face name is skipped");
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
	Expect(gold.find("BSUIDataManager") == std::string::npos, "gold movie does not subscribe");

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
