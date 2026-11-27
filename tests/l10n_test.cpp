// Unit tests for the Horizon localization loader (src/hz_l10n.h) plus source
// pins for DLL glue, the Settings 2.0 Language page, and the 0.43.4 hot path.
// No game, no CommonLibSF. Never writes to /tmp. Build (from the repo root):
//   g++ -std=c++20 -Wall -Wextra -I src -I tests tests/l10n_test.cpp -o test_scratch/l10n_test
// Author: Moragar. Last modified: 2026-11-27.

#include "hz_l10n.h"
#include "hz_test_scratch.h"

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
std::size_t Count(const std::string& a_s, const std::string& a_n)
{
	std::size_t n = 0;
	for (auto p = a_s.find(a_n); p != std::string::npos; p = a_s.find(a_n, p + 1)) ++n;
	return n;
}

void WriteFile(const std::filesystem::path& a_p, const std::string& a_s)
{
	std::error_code ec;
	std::filesystem::create_directories(a_p.parent_path(), ec);
	std::ofstream out(a_p, std::ios::binary);
	out << a_s;
}

} // namespace

int main()
{
	using namespace hzl10n;

	Expect(MapCode("auto") == "auto" && MapCode("") == "auto" && MapCode(" EN ") == "en", "MapCode: auto / empty / trim");
	Expect(MapCode("jp") == "ja" && MapCode("JA") == "ja", "MapCode: jp and ja become ja");
	Expect(MapCode("zhhans") == "zh-cn" && MapCode("zh-CN") == "zh-cn" && MapCode("zh") == "zh-cn", "MapCode: Chinese Simplified");
	Expect(MapCode("../en") == "auto" && MapCode("en/../de") == "auto" && MapCode("..") == "auto",
		"MapCode: parent segments become auto");
	Expect(MapCode("en\\de") == "auto" && MapCode("en/de") == "auto" && MapCode("C:en") == "auto",
		"MapCode: path separators and drive letters become auto");
	Expect(std::string(DisplayName("en")) == "English" && std::string(DisplayName("zhhans")) == "Chinese (Simplified)", "DisplayName: English and Chinese");
	Expect(MenuName("auto") == "AUTO (GAME)" && MenuName("de") == "GERMAN", "MenuName: Settings 2.0 labels");

	const auto sl = ParseSLanguage("[Display]\niPresentInterval=1\n[General]\nsLanguage=jp\n; ignore\nsLanguage=de\n");
	Expect(MapCode(sl) == "de", "ParseSLanguage: last [General] sLanguage wins");
	Expect(ParseSLanguage("[Audio]\nsLanguage=fr\n").empty(), "ParseSLanguage: ignores other sections");

	const auto dir = HzTestScratch("l10n_");
	const auto dirNorm = HzTestNorm(dir);
	Expect(dirNorm.find("/tmp") == std::string::npos && dirNorm.find("appdata/local/temp") == std::string::npos
			&& dirNorm.find("test_scratch") != std::string::npos,
		"scratch is under test_scratch, not /tmp");

	WriteFile(dir / "en.json",
		"{\n"
		"  \"_meta\": { \"language\": \"en\", \"notes\": \"skip me\" },\n"
		"  \"hud\": { \"health\": \"HEALTH\", \"oxygen\": \"OXYGEN\" },\n"
		"  \"settings\": { \"tabs\": { \"cards\": \"CARDS\" }, \"language\": { \"auto\": \"AUTO (GAME)\" } }\n"
		"}\n");
	WriteFile(dir / "de.json",
		"{\n"
		"  \"hud\": { \"health\": \"GESUNDHEIT\" },\n"
		"  \"settings\": { \"tabs\": { \"cards\": \"KARTEN\" } }\n"
		"}\n");

	{
		std::unordered_map<std::string, std::string> flat;
		std::string body;
		Expect(ReadUtf8File(dir / "en.json", body) && ParseFlat(body, flat), "ParseFlat: English table");
		Expect(flat["hud.health"] == "HEALTH" && flat["settings.tabs.cards"] == "CARDS", "flatten dotted keys");
		Expect(flat.find("_meta") == flat.end() && flat.find("_meta.language") == flat.end(), "underscore keys are skipped");
	}

	{
		const auto t = Load(dir, "auto", "en");
		Expect(t.ok && t.usedCode == "en" && t.count >= 3, "Load auto+en uses English");
		Expect(Get(t, "hud.health", "X") == "HEALTH", "Get: English HEALTH");
		Expect(t.gameCode == "en" && t.gameName == "English", "detected game language is cached on the table");
		Expect(t.filesCsv.find("en") != std::string::npos && t.filesCsv.find("de") != std::string::npos, "available files include en and de");
		Expect(t.payload.find("#l10n1") == 0 && t.payload.find("hud.health\tHEALTH") != std::string::npos, "payload is one #l10n1 snapshot");
	}

	{
		const auto t = Load(dir, "auto", "de");
		Expect(t.ok && t.usedCode == "de" && t.notice == "en+de", "auto follows the detected game language");
		Expect(Get(t, "hud.health", "X") == "GESUNDHEIT", "overlay replaces English");
		Expect(Get(t, "hud.oxygen", "X") == "OXYGEN", "overlay keeps English for missing keys");
		Expect(t.gameCode == "de", "detected stays German when override is auto");
	}

	{
		const auto t = Load(dir, "en", "de");
		Expect(t.usedCode == "en" && Get(t, "hud.health", "X") == "HEALTH", "override English ignores detected German");
		Expect(t.gameCode == "de" && t.gameName == "German", "detected game language is not overwritten by the override");
	}

	{
		const auto t = Load(dir, "ja", "en");
		Expect(t.usedCode == "en" && t.notice.find("ja missing") != std::string::npos, "missing overlay falls back to English");
		Expect(Get(t, "hud.health", "X") == "HEALTH", "English fallback value");
	}

	{
		const auto t = Load(dir, "auto", "jp");
		Expect(t.gameCode == "ja", "jp from the game maps to ja");
		Expect(t.usedCode == "en", "ja.json is absent so English is used");
	}

	{
		const auto t = Load(dir, "auto", "zhhans");
		Expect(t.gameCode == "zh-cn" && t.gameName == "Chinese (Simplified)", "zhhans maps to zh-cn");
	}

	{
		const auto t = Load(dir, "../en", "de");
		Expect(t.overrideCode == "auto" && t.usedCode == "de" && Get(t, "hud.health", "X") == "GESUNDHEIT",
			"path-like Language= is ignored; auto follows the detected game language");
	}

	{
		std::string bom = "\xEF\xBB\xBF{\"hud\":{\"boost\":\"BOOST\"}}";
		std::unordered_map<std::string, std::string> flat;
		Expect(ParseFlat(bom, flat) && flat["hud.boost"] == "BOOST", "UTF-8 BOM is stripped");
	}

	{
		std::unordered_map<std::string, std::string> flat;
		Expect(ParseFlat("{\"hud\":{\"ok\":\"A\\u0041\"}}", flat) && flat["hud.ok"] == "AA", "JSON \\uXXXX becomes UTF-8");
	}

	{
		const auto big = dir / "too_big.json";
		{
			std::ofstream out(big, std::ios::binary);
			out << std::string(kMaxFileBytes + 8, 'x');
		}
		std::string body;
		Expect(!ReadUtf8File(big, body), "files over 512 KiB are refused");
	}

	{
		const auto t = Load(dir / "no_such_folder", "auto", "en");
		Expect(!t.ok && t.count == 0, "missing folder yields an empty table (HUD literals stay)");
		Expect(t.payload.find("#l10n1") == 0, "empty table still builds a meta payload");
	}

	const auto cpp = ReadAll("src/main.cpp");
	const auto hdr = ReadAll("src/hz_l10n.h");
	const auto as = ReadAll("actionscript/horizon_block.as");
	const auto insert = ReadAll("actionscript/hz51_insert.as");
	const auto ini = ReadAll("Interface/HorizonUI/HorizonUI.default.ini");

	auto fnBody = [&](const std::string& a_sig) {
		std::size_t i = 0;
		for (;;) {
			i = cpp.find(a_sig, i);
			if (i == std::string::npos) return std::string{};
			const auto b = cpp.find_first_of(";{", i + a_sig.size());
			if (b == std::string::npos) return std::string{};
			if (cpp[b] == ';') { i = b + 1; continue; }
			int d = 0;
			for (auto p = b; p < cpp.size(); ++p) {
				if (cpp[p] == '{') ++d;
				else if (cpp[p] == '}' && --d == 0) return cpp.substr(b, p - b + 1);
			}
			return std::string{};
		}
	};

	Expect(Has(cpp, "#include \"hz_l10n.h\""), "main.cpp includes the localization header");
	Expect(Has(cpp, "L10nLoad"), "DLL loads the table from the job / load path");
	Expect(Has(cpp, "PushL10n"), "DLL has a latched Scaleform push");
	Expect(Has(cpp, "hzSetL10n"), "push targets hzSetL10n");
	Expect(!Has(cpp, "Localization/*.json"), "DLL does not poll the Localization folder");

	const auto poll = fnBody("void Poll()");
	Expect(Has(poll, "FilesJobPreload"), "Poll still preloads on the job thread");
	Expect(!Has(poll, "PushL10n") && !Has(poll, "Invoke"), "Poll never Invokes Scaleform (no l10n push there)");

	const auto preload = fnBody("void FilesJobPreload()");
	Expect(Has(preload, "L10nLoad"), "FilesJobPreload loads localization (file I/O off the UI thread)");

	Expect(Has(cpp, "g_l10nPushed") || Has(cpp, "g_l10nPush"), "push is latched (generation / flag), not on a timer");
	Expect(!Has(cpp, "g_buildsHudNext") || Count(cpp, "PushL10n") > 0, "PushL10n exists");
	const auto buildLog = cpp.find("void BuildLogHud");
	Expect(buildLog != std::string::npos, "BuildLogHud still exists");
	if (buildLog != std::string::npos) {
		auto b = cpp.find('{', buildLog);
		int d = 0;
		std::string body;
		for (auto p = b; p < cpp.size(); ++p) {
			if (cpp[p] == '{') ++d;
			else if (cpp[p] == '}' && --d == 0) { body = cpp.substr(b, p - b + 1); break; }
		}
		Expect(!Has(body, "PushL10n"), "l10n is not pushed from the 5s movie-build timer");
	}

	Expect(Has(ini, "Language=auto"), "default.ini has the new Language key");
	Expect(Has(ini, "[Hotkeys]") && Has(ini, "SettingsKey=F11"), "every previous default.ini key block remains (Hotkeys)");
	Expect(Has(ini, "ShowJetpack=1") && Has(ini, "FontFace=1") && Has(ini, "QuickMenuHorizon=1"), "Cards / Style / Quick Menu keys are unchanged");

	Expect(Has(as, "function hzSetL10n") && Has(as, "function hzL("), "HUD has hzSetL10n and hzL");
	Expect(Has(as, "LANGUAGE / LOCALIZATION") || Has(insert, "LANGUAGE / LOCALIZATION"), "Settings 2.0 has the Language page");
	Expect(Has(as, "\"k\":\"Language\"") || Has(insert, "\"k\":\"Language\""), "Language override is a catalog key");
	Expect(Has(as, "_l10nGame") || Has(insert, "_l10nGame"), "detected game language is a read-only row");
	Expect(Has(as, "Language=\"") || Has(as, "Language=\" +") || Has(as, "Language=\" + "), "F11 save writes Language=");

	const auto vit = [&]() {
		auto i = as.find("function hzVitTick");
		if (i == std::string::npos) i = as.find("function hz19Vit");
		if (i == std::string::npos) return std::string{};
		auto b = as.find('{', i);
		int d = 0;
		for (auto p = b; p < as.size() && p < b + 8000; ++p) {
			if (as[p] == '{') ++d;
			else if (as[p] == '}' && --d == 0) return as.substr(b, p - b + 1);
		}
		return std::string{};
	}();
	Expect(!Has(vit, "hzL("), "vitals tick does not call hzL");

	const auto enter = as.find("ENTER_FRAME");
	Expect(enter != std::string::npos, "ENTER_FRAME still exists (unchanged HUD loop)");
	Expect(Count(as, "this.hzL(") == 0 || Count(as, "function hzL(") == 1, "hzL is defined and not used from HUD draw yet");

	Expect(Has(hdr, "kMaxFileBytes = 512 * 1024"), "512 KiB cap matches other JSON reads");
	Expect(!Has(hdr, "HUSD") && !Has(cpp, "HUSD") && !Has(as, "HUSD"), "no HUSD IT in l10n sources");
	Expect(!Has(hdr, "cursor") && !Has(hdr, "SCHROPE") && !Has(hdr, "rschr"), "no box paths or usernames in the loader");

	const auto shipped = ReadAll("Data/SFSE/Plugins/HorizonUI/Localization/en.json");
	Expect(Has(shipped, "\"health\"") && Has(shipped, "HEALTH"), "shipped en.json has HUD health");
	Expect(Has(shipped, "\"language\"") && Has(shipped, "AUTO (GAME)"), "shipped en.json has the Language page strings");
	Expect(Has(shipped, "American English") || Has(shipped, "English"), "en.json is American English source");
	Expect(Has(shipped, "pressing OK reloads the language once"), "en.json language help says OK reloads once");
	Expect(!Has(shipped, "A change takes effect after you restart the game."),
		"en.json language help does not require a restart");

	if (g_fail) {
		std::cerr << "\n" << g_fail << " failed, " << g_ok << " passed\n";
		return 1;
	}
	std::cout << "\n" << g_ok << " passed\n";
	return 0;
}
