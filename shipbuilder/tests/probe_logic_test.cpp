// Purpose: check the probe's read-only rules without the game.
// Author: Moragar. Last modified: 2026-11-04.

#include "hsb_guard.h"

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
		Expect(body.find(move) == std::string::npos, "no file move");
		Expect(body.find(rmdir) == std::string::npos, "no directory remove");
		Expect(body.find(files) == std::string::npos || rel.find("/tests/") != std::string::npos,
			"filesystem only in the test");
		const bool writer = body.find(wideOpen) != std::string::npos || body.find(stream) != std::string::npos;
		if (writer) Expect(rel.find("probe.cpp") != std::string::npos, "only the plugin opens a file");
	}
}

int main()
{
	const std::string good = std::string("C:\\Users\\A\\Documents\\My Games\\Starfield\\SFSE\\Logs\\") + hsb::kProbeFile;
	const std::string goodSlash = std::string("C:/Users/A/Documents/My Games/Starfield/SFSE/Logs/") + hsb::kProbeFile;
	Expect(hsb::ProbeMayAppend(good), "documents log is allowed");
	Expect(hsb::ProbeMayAppend(goodSlash), "forward-slash log is allowed");
	Expect(!hsb::ProbeMayAppend(std::string("D:\\Steam\\steamapps\\common\\Starfield\\Data\\") + hsb::kProbeFile), "game data is refused");
	Expect(!hsb::ProbeMayAppend(std::string("C:\\Users\\A\\Documents\\My Games\\Starfield\\Saves\\") + hsb::kProbeFile), "saves are refused");
	Expect(!hsb::ProbeMayAppend(std::string("C:\\Users\\A\\Documents\\My Games\\Starfield\\SFSE\\Logs\\other.log")), "other names are refused");
	Expect(!hsb::ProbeMayAppend(std::string("C:\\Users\\A\\Documents\\My Games\\Starfield\\SFSE\\Logs\\..\\") + hsb::kProbeFile), "dot-dot is refused");

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

	const std::string dirty = hsb::FactLine("F16", "line\r\nnext");
	Expect(dirty.find('\n') == std::string::npos && dirty.find('\r') == std::string::npos, "facts stay on one line");
	Expect(hsb::kMenuName == std::string("SpaceshipEditorMenu"), "menu name");

	const fs::path root = fs::path(HSB_REPO_ROOT) / "shipbuilder";
	const std::string retiredA = std::string("HU") + "SD";
	const std::string retiredB = std::string("rs") + "chr";
	ScanTree(root);

	const std::string probe = ReadFile(root / "actionscript" / "HorizonShipBuilderProbe.as");
	Expect(probe.find("captureOn = false") != std::string::npos, "capture starts off");
	Expect(probe.find("label.size = 13") != std::string::npos, "overlay is 13 px");
	Expect(probe.find("spaceshipeditormenu") == std::string::npos, "the class does not name a replacement movie");

	const std::string splice = ReadFile(root / "actionscript" / "document_splice.as");
	Expect(splice.find("spaceshipeditormenu.swf") != std::string::npos, "normal movie is named");
	Expect(splice.find("spaceshipeditormenu_lrg.swf") != std::string::npos, "large movie is named");
	Expect(splice.find("hsbProbePing") != std::string::npos, "ping splice");
	Expect(splice.find("ProcessUserEvent") != std::string::npos, "user-event splice");

	const std::string readme = ReadFile(root / "README_P0.md");
	Expect(readme.find("xmake build -y HorizonShipBuilder") != std::string::npos, "build step");
	Expect(readme.find("F.1") != std::string::npos, "readme lists the live tests");
	Expect(readme.find("#16") != std::string::npos && readme.find("#17") != std::string::npos && readme.find("#18") != std::string::npos,
		"arrange tests are in the readme");

	const std::string lua = ReadFile(fs::path(HSB_REPO_ROOT) / "xmake.lua");
	Expect(lua.find("target(\"HorizonShipBuilder\")") != std::string::npos, "probe target");
	Expect(lua.find("set_version(\"0.43.0.33\")") != std::string::npos, "core version stays");
	Expect(lua.find(retiredA) == std::string::npos && lua.find(retiredB) == std::string::npos, "xmake has no retired names");

	const std::string plugin = ReadFile(root / "src" / "probe.cpp");
	Expect(plugin.find("ProbeMayAppend") != std::string::npos, "plugin checks the log path");
	Expect(plugin.find("ShouldRestoreWndProc") != std::string::npos, "plugin uses the unhook rule");
	Expect(plugin.find(std::string("swallowed") + "=0") != std::string::npos, "the hook does not swallow");

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "probe_logic_test passed\n";
	return 0;
}
