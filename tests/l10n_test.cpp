// Unit tests for the Horizon localization loader (src/hz_l10n.h) plus source
// pins for DLL glue, the Settings 2.0 Language page, and the 0.43.4 hot path.
// No game, no CommonLibSF. Never writes under the system temp folder. Build (from the repo root):
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
	Expect(MapCode("ptbr") == "pt-br" && MapCode("pt-BR") == "pt-br" && MapCode("brazilian") == "pt-br",
		"MapCode: Portuguese Brazil becomes pt-br");
	Expect(MapCode("esmx") == "es-mx" && MapCode("latam") == "es-mx" && MapCode("es-mx") == "es-mx",
		"MapCode: Latin American Spanish becomes es-mx");
	Expect(MapCode("es") == "es" && MapCode("spanish") == "es", "MapCode: Spain Spanish stays es");
	Expect(MapCode("../en") == "auto" && MapCode("en/../de") == "auto" && MapCode("..") == "auto",
		"MapCode: parent segments become auto");
	Expect(MapCode("en\\de") == "auto" && MapCode("en/de") == "auto" && MapCode("C:en") == "auto",
		"MapCode: path separators and drive letters become auto");
	Expect(std::string(DisplayName("en")) == "English"
			&& std::string(DisplayName("de")) == "Deutsch (German)"
			&& std::string(DisplayName("esmx")).find("Latinoam") != std::string::npos
			&& std::string(DisplayName("esmx")).find("Spanish, Latin America") == std::string::npos
			&& std::string(DisplayName("ptbr")) == "Portugu\xC3\xAA" "s (Brasil)"
			&& std::string(DisplayName("zhhans")) == "Simplified Chinese"
			&& std::string(DisplayName("ja")) == "Japanese",
		"DisplayName: Exo 2 native names; CJK stems are English-only");
	Expect(MenuName("auto") == "Auto (game)" && MenuName("de") == "Deutsch (German)", "MenuName matches DisplayName");
	Expect(Exo2Can("Deutsch (German)") && Exo2Can("Espa\xC3\xB1" "ol (Spanish)") && Exo2Can("Pols" "\xC5\x82" "i")
			&& Exo2Can("Fran\xC3\xA7" "ais") && Exo2Can("Portugu\xC3\xAA" "s"),
		"Exo2Can: Latin / Latin-1 / Polish l-stroke");
	Expect(!Exo2Can("\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E (Japanese)")
			&& !Exo2Can("\xE7\xAE\x80\xE4\xBD\x93\xE4\xB8\xAD\xE6\x96\x87")
			&& !Exo2Can("\xED\x95\x9C\xEA\xB5\xAD\xEC\x96\xB4 (Korean)")
			&& !Exo2Can("\xE0\xB9\x84\xE0\xB8\x97\xE0\xB8\xA2 (Thai)"),
		"Exo2Can: CJK / Hangul / Thai are not in Exo 2");
	Expect(Exo2Text("\xE6\x97\xA5\xE6\x9C\xAC\xE8\xAA\x9E (Japanese)", "Japanese") == "Japanese"
			&& Exo2Text("\xE7\xAE\x80\xE4\xBD\x93\xE4\xB8\xAD\xE6\x96\x87 (Simplified Chinese)", "X") == "Simplified Chinese"
			&& Exo2Text("\xED\x95\x9C\xEA\xB5\xAD\xEC\x96\xB4 (Korean)", "Korean") == "Korean"
			&& Exo2Text("Deutsch (German)", "German") == "Deutsch (German)",
		"Exo2Text: parenthetical English when the native script is not Exo 2");
	Expect(std::string(FallbackStem("es-mx")) == "es" && FallbackStem("de") == nullptr, "es-mx falls back through es");

	const auto sl = ParseSLanguage("[Display]\niPresentInterval=1\n[General]\nsLanguage=jp\n; ignore\nsLanguage=de\n");
	Expect(MapCode(sl) == "de", "ParseSLanguage: last [General] sLanguage wins");
	Expect(ParseSLanguage("[Audio]\nsLanguage=fr\n").empty(), "ParseSLanguage: ignores other sections");

	Expect(LanguageIniName("german") == "Starfield_de.ini" && LanguageIniName("de") == "Starfield_de.ini",
		"LanguageIniName: Steam german / sLanguage de -> Starfield_de.ini");
	Expect(LanguageIniName("schinese") == "Starfield_zhhans.ini" && LanguageIniName("ja") == "Starfield_ja.ini"
			&& LanguageIniName("brazilian") == "Starfield_ptbr.ini" && LanguageIniName("latam") == "Starfield_es.ini",
		"LanguageIniName: zhhans / ja / ptbr / es stems match the game-folder files");
	{
		const auto acf =
			"\"AppState\"\n{\n\t\"appid\"\t\t\"1716740\"\n"
			"\t\"UserConfig\"\n\t{\n\t\t\"language\"\t\t\"german\"\n\t}\n"
			"\t\"MountedConfig\"\n\t{\n\t\t\"language\"\t\t\"german\"\n\t}\n}\n";
		Expect(ParseSteamAcfLanguage(acf) == "german", "ParseSteamAcfLanguage reads UserConfig.language");
		std::unordered_map<std::string, std::string> langIni;
		langIni["Starfield_de.ini"] = "[General]\nsLanguage=de\n";
		const auto emptyIni = "[General]\nsStartingConsoleCommand=foo\n";
		Expect(DetectGameLanguage(acf, emptyIni, langIni, emptyIni, "") == "de",
			"Steam german + Starfield_de.ini is de when Prefs/Custom have no sLanguage");
		Expect(DetectGameLanguage(acf, emptyIni, langIni, emptyIni, "[General]\nsLanguage=en\n") == "en",
			"StarfieldCustom.ini sLanguage last-wins over Starfield_de.ini");
		Expect(DetectGameLanguage(acf, emptyIni, {}, emptyIni, "") == "de",
			"Steam ACF german is de when no INI sets sLanguage");
		Expect(DetectGameLanguage("", emptyIni, {}, emptyIni, "") == "en",
			"empty stack with no Steam language stays English");
		Expect(DetectGameLanguage(acf, emptyIni, langIni, "[General]\nsLanguage=fr\n", "") == "fr",
			"StarfieldPrefs.ini sLanguage wins over Starfield_de.ini");
	}

	const auto dir = HzTestScratch("l10n_");
	const auto dirNorm = HzTestNorm(dir);
	const auto tmpNeedle = std::string("/") + "tmp";
	Expect(dirNorm.find(tmpNeedle) == std::string::npos && dirNorm.find("appdata/local/temp") == std::string::npos
			&& dirNorm.find("test_scratch") != std::string::npos,
		"scratch is under test_scratch, not the system temp folder");

	WriteFile(dir / "en.json",
		"{\n"
		"  \"_meta\": { \"language\": \"en\", \"notes\": \"skip me\" },\n"
		"  \"hud\": { \"health\": \"HEALTH\", \"oxygen\": \"OXYGEN\" },\n"
		"  \"settings\": { \"tabs\": { \"cards\": \"CARDS\" }, \"language\": { \"auto\": \"AUTO (GAME)\" },\n"
		"    \"details\": { \"_l10nGame\": \"cached at start\" } }\n"
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
		Expect(flat.find("_meta") == flat.end() && flat.find("_meta.language") == flat.end(), "_meta keys are skipped");
		Expect(flat["settings.details._l10nGame"] == "cached at start", "setting ids that start with _ are kept");
	}

	{
		const auto t = Load(dir, "auto", "en");
		Expect(t.ok && t.usedCode == "en" && t.count >= 3, "Load auto+en uses English");
		Expect(Get(t, "hud.health", "X") == "HEALTH", "Get: English HEALTH");
		Expect(t.gameCode == "en" && t.gameName == "English", "detected game language is cached on the table");
		Expect(t.filesCsv.find("en") != std::string::npos && t.filesCsv.find("de") != std::string::npos, "available files include en and de");
		Expect(t.filesCsv.find("es-mx") != std::string::npos && t.filesCsv.find("pt-br") != std::string::npos
				&& t.filesCsv.find("ko") == std::string::npos,
			"dropdown lists Steam stems including es-mx and pt-br, not Korean");
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
		Expect(t.gameCode == "de" && t.gameName == "Deutsch (German)", "detected game language is not overwritten by the override");
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
		Expect(t.gameCode == "zh-cn" && t.gameName.find("Simplified Chinese") != std::string::npos, "zhhans maps to zh-cn");

	{
		WriteFile(dir / "es.json", "{\"hud\":{\"health\":\"SALUD\"}}\n");
		const auto t = Load(dir, "auto", "esmx");
		Expect(t.gameCode == "es-mx" && t.usedCode == "es" && Get(t, "hud.health", "X") == "SALUD",
			"es-mx without es-mx.json overlays es.json then English");
		Expect(t.notice.find("es-mx missing") != std::string::npos, "notice says es-mx file was missing");
		WriteFile(dir / "es-mx.json", "{\"hud\":{\"health\":\"SALUD MX\"}}\n");
		const auto t2 = Load(dir, "auto", "latam");
		Expect(t2.usedCode == "es-mx" && Get(t2, "hud.health", "X") == "SALUD MX",
			"es-mx.json wins over es.json");
	}
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
	const auto qm = ReadAll("actionscript/favorites/hzq_main.as");
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

	const auto detect = fnBody("std::string L10nDetectGame()");
	Expect(Has(detect, "DetectGameLanguage") && Has(detect, "appmanifest_1716740") && Has(detect, "sLanguage:General"),
		"L10nDetectGame uses live sLanguage:General then the game INI stack + Steam ACF");
	Expect(!Has(detect, "StarfieldCustom.ini\", L\"StarfieldPrefs.ini\""),
		"L10nDetectGame no longer stops at the first Documents INI");
	Expect(Has(cpp, "L10nReadLiveSLanguage") && Has(cpp, "HzL10nLangSEH"),
		"live sLanguage:General is one SEH read, not a poll");
	Expect(!Has(poll, "L10nDetectGame") && !Has(poll, "ParseSteamAcfLanguage"),
		"Poll does not re-detect the game language");

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
	Expect(Count(as, "function hzL(") == 1 && (Has(as, "function hzLt(") || Has(insert, "function hzLt(")),
		"hzL is defined once; P1 slug lookup exists");
	Expect(Has(as, "function hzL10nApplyHud") || Has(insert, "function hzL10nApplyHud"),
		"language change refreshes HUD chrome once, not per tick");
	Expect(Has(cpp, "PushL10nFavorites") && Has(qm, "function hzqSetL10n"),
		"FavoritesMenu gets its own l10n push on open");
	Expect(Has(cpp, "hzcSetL10n") && Has(cpp, "hzdSetL10n") && Has(cpp, "hzsSetL10n"),
		"Comms, Dialogue, and Scanner movies get the same l10n payload");
	Expect(Has(cpp, "PushL10nModules") && Has(cpp, "PushL10nForMenu"),
		"module movies are pushed on language apply and on menu open");

	Expect(Has(hdr, "kMaxFileBytes = 512 * 1024"), "512 KiB cap matches other JSON reads");
	Expect(!Has(hdr, "HUSD") && !Has(cpp, "HUSD") && !Has(as, "HUSD"), "no HUSD IT in l10n sources");
	Expect(!Has(hdr, "cursor") && !Has(hdr, "SCHROPE") && !Has(hdr, "rschr"), "no box paths or usernames in the loader");

	const auto shipped = ReadAll("Data/SFSE/Plugins/HorizonUI/Localization/en.json");
	Expect(Has(shipped, "\"health\"") && Has(shipped, "HEALTH"), "shipped en.json has HUD health");
	Expect(Has(shipped, "\"language\"") && Has(shipped, "Auto (game)"), "shipped en.json has the Language page strings");
	Expect(Has(shipped, "Deutsch (German)") && Has(shipped, "es-mx") && Has(shipped, "pt-br"),
		"en.json lists Steam language names including es-mx and pt-br");
	Expect(!Has(shipped, "\"ko\""), "en.json does not ship Korean");
	Expect(Has(shipped, "American English") || Has(shipped, "English"), "en.json is American English source");
	Expect(Has(shipped, "pressing OK reloads the language once"), "en.json language help says OK reloads once");
	Expect(!Has(shipped, "A change takes effect after you restart the game."),
		"en.json language help does not require a restart");

	const auto zhcn = ReadAll("Data/SFSE/Plugins/HorizonUI/Localization/zh-cn.json");
	Expect(!zhcn.empty() && Has(zhcn, "\"language\": \"zh-cn\"") && Has(zhcn, "简体中文"),
		"shipped zh-cn.json is Simplified Chinese (MapCode stem for sLanguage zhhans)");
	Expect(!(zhcn.size() >= 3 && static_cast<unsigned char>(zhcn[0]) == 0xEF
			&& static_cast<unsigned char>(zhcn[1]) == 0xBB && static_cast<unsigned char>(zhcn[2]) == 0xBF),
		"zh-cn.json is UTF-8 with no BOM");
	{
		const auto files = ListLangFiles(std::filesystem::path("Data/SFSE/Plugins/HorizonUI/Localization"));
		bool hasZh = false, hasEn = false;
		for (const auto& f : files) {
			if (f == "zh-cn") hasZh = true;
			if (f == "en") hasEn = true;
		}
		Expect(hasEn && hasZh && !files.empty() && files.front() == "en",
			"shipped Localization files are English first and include zh-cn");
		const auto drop = DropdownCodes(std::filesystem::path("Data/SFSE/Plugins/HorizonUI/Localization"));
		bool hasMx = false, hasPt = false, hasKo = false;
		for (const auto& f : drop) {
			if (f == "es-mx") hasMx = true;
			if (f == "pt-br") hasPt = true;
			if (f == "ko") hasKo = true;
		}
		Expect(!drop.empty() && drop.front() == "en" && hasMx && hasPt && !hasKo,
			"Language dropdown is Steam langs (en first, es-mx, pt-br) without Korean");
		Expect(drop.size() == 10, "dropdown is the ten Steam languages once");
		int nMx = 0;
		for (const auto& f : drop) if (f == "es-mx") ++nMx;
		Expect(nMx == 1, "es-mx appears once among shipped files");
	}
	{
		const auto tmp = HzTestScratch("l10n_drop_alias");
		WriteFile(tmp / "en.json", "{\"hud\":{\"health\":\"HEALTH\"}}\n");
		WriteFile(tmp / "es-mx.json", "{\"hud\":{\"health\":\"SALUD MX\"}}\n");
		WriteFile(tmp / "es-419.json", "{\"hud\":{\"health\":\"SALUD 419\"}}\n");
		WriteFile(tmp / "esmx.json", "{\"hud\":{\"health\":\"SALUD MX2\"}}\n");
		const auto drop = DropdownCodes(tmp);
		int nMx = 0, n419 = 0, nEsmx = 0;
		for (const auto& f : drop) {
			if (f == "es-mx") ++nMx;
			if (f == "es-419") ++n419;
			if (f == "esmx") ++nEsmx;
		}
		Expect(nMx == 1 && n419 == 0 && nEsmx == 0,
			"es-419.json / esmx.json MapCode to es-mx and do not add a second Latinoamerica row");
	}

	const auto de = ReadAll("Data/SFSE/Plugins/HorizonUI/Localization/de.json");
	Expect(!de.empty() && Has(de, "\"language\": \"de\"") && Has(de, "GESUNDHEIT") && Has(de, "SPRACHE"),
		"shipped de.json is German");
	Expect(!(de.size() >= 3 && static_cast<unsigned char>(de[0]) == 0xEF
			&& static_cast<unsigned char>(de[1]) == 0xBB && static_cast<unsigned char>(de[2]) == 0xBF),
		"de.json is UTF-8 with no BOM");

	const auto es = ReadAll("Data/SFSE/Plugins/HorizonUI/Localization/es.json");
	Expect(!es.empty() && Has(es, "\"language\": \"es\"") && Has(es, "SALUD") && Has(es, "Espa"),
		"shipped es.json is Spain Spanish");
	Expect(!(es.size() >= 3 && static_cast<unsigned char>(es[0]) == 0xEF
			&& static_cast<unsigned char>(es[1]) == 0xBB && static_cast<unsigned char>(es[2]) == 0xBF),
		"es.json is UTF-8 with no BOM");

	const auto esmx = ReadAll("Data/SFSE/Plugins/HorizonUI/Localization/es-mx.json");
	Expect(!esmx.empty() && Has(esmx, "\"language\": \"es-mx\"") && Has(esmx, "SALUD") && Has(esmx, "Latinoam"),
		"shipped es-mx.json is Latin American Spanish");
	Expect(!(esmx.size() >= 3 && static_cast<unsigned char>(esmx[0]) == 0xEF
			&& static_cast<unsigned char>(esmx[1]) == 0xBB && static_cast<unsigned char>(esmx[2]) == 0xBF),
		"es-mx.json is UTF-8 with no BOM");
	{
		const auto shippedDir = std::filesystem::path("Data/SFSE/Plugins/HorizonUI/Localization");
		const auto tes = Load(shippedDir, "es", "en");
		Expect(tes.usedCode == "es" && Get(tes, "hud.health", "X") == "SALUD",
			"shipped es.json overlays English");
		const auto tmx = Load(shippedDir, "es-mx", "en");
		Expect(tmx.usedCode == "es-mx" && Get(tmx, "hud.health", "X") == "SALUD",
			"shipped es-mx.json loads through the es then es-mx overlay chain");
		Expect(Get(tes, "hud.hud_label.press", "X") == "PULSA" && Get(tmx, "hud.hud_label.press", "X") == "PRESIONA",
			"es-mx overlay wins over es for Latin American wording");
	}

	if (g_fail) {
		std::cerr << "\n" << g_fail << " failed, " << g_ok << " passed\n";
		return 1;
	}
	std::cout << "\n" << g_ok << " passed\n";
	return 0;
}
