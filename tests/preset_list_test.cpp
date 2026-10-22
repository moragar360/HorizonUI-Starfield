// Unit tests for preset dedupe, the shared preset-name character set, and the
// single file-version header. No game, no CommonLibSF.
// Build: g++ -std=c++20 -Wall -Wextra -I src tests/preset_list_test.cpp -o /tmp/preset_list_test

#include "hz_version.h"
#include "preset_dedupe.h"

#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>

namespace {

int g_fails = 0;

void Expect(bool a_ok, const char* a_what)
{
	if (a_ok) return;
	std::cerr << "FAIL: " << a_what << "\n";
	++g_fails;
}

void ExpectEq(const std::string& a_got, const std::string& a_want, const char* a_what)
{
	if (a_got == a_want) return;
	std::cerr << "FAIL: " << a_what << "\n  got:  [" << a_got << "]\n  want: [" << a_want << "]\n";
	++g_fails;
}

hzpreset::Candidate C(const char* a_id, bool a_user, const char* a_name, const char* a_file, const char* a_body, std::int64_t a_mtime)
{
	hzpreset::Candidate c;
	c.id = a_id;
	c.user = a_user;
	c.name = a_name;
	c.fileName = a_file;
	c.contentKey = a_body;
	c.mtime = a_mtime;
	return c;
}

} // namespace

int main()
{
	using namespace hzpreset;

	Expect(std::string(HZ_FILE_VERSION_STR) == "0.42.0.7", "file version string");
	Expect(HZ_FILE_VERSION_MAJOR == 0 && HZ_FILE_VERSION_MINOR == 42 && HZ_FILE_VERSION_PATCH == 0 && HZ_FILE_VERSION_BUILD == 7, "file version numbers");
	Expect(HZ_COMMS_MSG_LOG == 1, "reaction diagnostic is on for this test build");
	Expect(HzFileVersionOk("0.42.0.7"), "4-part version ok");
	Expect(!HzFileVersionOk("0.42.0"), "3-part version is not the file version");
	Expect(!HzFileVersionOk("v0.42.0.6"), "leading v is not accepted");
	Expect(!HzFileVersionOk("0.42.0.6 "), "trailing space rejected");

	ExpectEq(CleanPresetName("Moragar's Choice"), "Moragar's Choice", "apostrophe stays");
	ExpectEq(CleanPresetName("A=B+C[D]E;F#G\"H\\I|J"), "ABCDEFGHIJ", "same drop set as the HUD");
	ExpectEq(CleanPresetName(std::string("\x01Name\x7f")), "Name", "controls and DEL drop");
	ExpectEq(CleanPresetName("  Hello  "), "Hello", "trim");
	ExpectEq(CleanPresetName("|only|"), "only", "pipe is removed, not turned into a space");
	Expect(std::strchr(kPresetNameDrop, '|') != nullptr, "pipe is in the shared set");
	Expect(std::strchr(kPresetNameDrop, '=') != nullptr && std::strchr(kPresetNameDrop, '+') != nullptr, "equals and plus stay in the set");

	const std::string bodyA =
		"[Preset]\r\nName=Moragar's Choice\r\nVersion=0.42.0\r\n\r\n[Style]\r\nAccentColor=9\r\n";
	const std::string bodyB =
		"[preset]\nName=Moragar's Choice\nVersion=0.41.0\nDescription=older header\n\n[Style]\nAccentColor = 9\n";
	const std::string bodyC =
		"[Preset]\nName=Moragar's Choice\n\n[Style]\nAccentColor=1\n";
	ExpectEq(PresetContentKey(bodyA), PresetContentKey(bodyB), "header and line endings do not count as different settings");
	Expect(PresetContentKey(bodyA) != PresetContentKey(bodyC), "a different setting counts as different");

	Expect(IsInstallerPresetFile(false, "moragars_choice.ini"), "installer file");
	Expect(!IsInstallerPresetFile(false, "HorizonUI.moragars-choice-0.42.0.ini"), "standalone package file");
	Expect(!IsInstallerPresetFile(true, "moragars_choice.ini"), "a saved copy is not the installer file");
	ExpectEq(NormalizePresetName("  Moragar's   Choice\t"), "moragar's choice", "name key folds case and space");
	ExpectEq(NormalizePresetName("Moragar's" "\xC2\xA0" "Choice"), "moragar's choice", "UTF-8 NBSP folds to a space");
	ExpectEq(NormalizePresetName("\xC2\xA0" "Moragar's Choice" "\xC2\xA0"), "moragar's choice", "leading and trailing NBSP fold away");
	ExpectEq(NormalizePresetName("Caf" "\xC3\xA0"), std::string("caf") + "\xC3\xA0", "a-grave stays in the name key");
	Expect(NormalizePresetName("Caf" "\xC3\xA0") != "caf", "a-grave is not dropped");
	Expect(NormalizePresetName("Caf" "\xC3\xA0") != "caf ", "a-grave is not folded into a space");

	{
		std::string cut(47, 'a');
		cut += "\xC3\xA9";
		ExpectEq(CleanPresetName(cut), std::string(47, 'a'), "a 48-byte cut does not keep a split UTF-8 lead");
		std::string fit(46, 'a');
		fit += "\xC3\xA9";
		ExpectEq(CleanPresetName(fit), fit, "a complete UTF-8 character at 48 bytes stays");
		std::string wide(45, 'b');
		wide += "\xF0\x9F\x8C\x8D";
		wide += "Z";
		ExpectEq(CleanPresetName(wide), std::string(45, 'b'), "a 4-byte character that crosses 48 bytes is dropped whole");
		ExpectEq(Utf8Prefix(std::string(46, 'a') + "\xC3\xA9" + "Z", 48), std::string(46, 'a') + "\xC3\xA9", "a character that ends on the cut stays");
	}

	const std::string same = PresetContentKey(bodyA);
	const std::string other = PresetContentKey(bodyC);
	std::vector<Drop> drops;

	// Same name, same settings: the loose file is newer, the installer copy stays.
	{
		std::vector<Candidate> items = {
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 10),
			C("s:HorizonUI.moragars-choice-0.42.0.ini", false, "moragar's   choice", "HorizonUI.moragars-choice-0.42.0.ini", same.c_str(), 99),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 1 && keep[0] == 0, "same settings keep the installer copy");
		Expect(drops.size() == 1 && drops[0].line.find("same settings, kept the installer copy") != std::string::npos, "installer reason");
		Expect(drops[0].line.find("s:HorizonUI.moragars-choice-0.42.0.ini") != std::string::npos, "standalone id is the one hidden");
	}

	// Same name, different settings: the newer file wins, even when it is the loose copy.
	{
		std::vector<Candidate> items = {
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 10),
			C("s:HorizonUI.moragars-choice-0.42.0.ini", false, "Moragar's Choice", "HorizonUI.moragars-choice-0.42.0.ini", other.c_str(), 50),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 1 && keep[0] == 1, "different settings keep the newer file");
		Expect(drops.size() == 1 && drops[0].line.find("settings differ, kept the newer file") != std::string::npos, "newer reason");
	}

	// Different settings, same timestamp: installer copy, then the smaller id.
	{
		std::vector<Candidate> items = {
			C("s:HorizonUI.moragars-choice-0.42.0.ini", false, "Moragar's Choice", "HorizonUI.moragars-choice-0.42.0.ini", other.c_str(), 7),
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 7),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 1 && keep[0] == 1, "time tie keeps the installer copy");
		Expect(drops[0].line.find("kept the installer copy") != std::string::npos, "time-tie installer reason");
	}

	// A saved preset that reuses a shipped name stays, even when the settings match.
	{
		std::vector<Candidate> items = {
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 10),
			C("u:moragars_choice.ini", true, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 80),
			C("u:my_preset.ini", true, "My preset", "my_preset.ini", other.c_str(), 80),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 3 && keep[0] == 0 && keep[1] == 1 && keep[2] == 2, "saved presets stay beside the shipped name");
		Expect(drops.empty(), "a saved copy is not a shipped duplicate");
	}

	// The review case: after a mod update the shipped file is newer, and the player's saved
	// preset has the same name but different settings. The saved preset must stay listable.
	{
		std::vector<Candidate> items = {
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 500),
			C("s:HorizonUI.moragars-choice-0.42.0.ini", false, "Moragar's Choice", "HorizonUI.moragars-choice-0.42.0.ini", same.c_str(), 400),
			C("u:my_look.ini", true, "Moragar's Choice", "my_look.ini", other.c_str(), 20),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 2 && keep[0] == 0 && keep[1] == 2, "newer shipped file does not hide a different saved preset");
		Expect(drops.size() == 1 && drops[0].line.find("u:") == std::string::npos, "the hide log does not name a saved preset");
		Expect(drops[0].line.find("s:HorizonUI.moragars-choice-0.42.0.ini") != std::string::npos, "the loose shipped copy is the one hidden");
	}

	// Two saved presets with one name are both shown. Dedupe does not apply to presets\\user.
	{
		std::vector<Candidate> items = {
			C("u:one.ini", true, "Moragar's Choice", "one.ini", same.c_str(), 10),
			C("u:two.ini", true, "Moragar's Choice", "two.ini", other.c_str(), 90),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 2 && keep[0] == 0 && keep[1] == 1 && drops.empty(), "saved presets are never hidden from each other");
	}

	// A non-breaking space does not split one shipped name into two list rows.
	{
		std::vector<Candidate> items = {
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 10),
			C("s:HorizonUI.moragars-choice-0.42.0.ini", false, "Moragar's" "\xC2\xA0" "Choice", "HorizonUI.moragars-choice-0.42.0.ini", same.c_str(), 99),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 1 && keep[0] == 0, "NBSP still matches the shipped name");
	}

	{
		std::ifstream in("res/HorizonUI.rc.in");
		Expect(static_cast<bool>(in), "version resource template opens");
		std::string rc((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		Expect(rc.find("#include \"hz_version.h\"") != std::string::npos, "resource includes the version header");
		Expect(rc.find("FILEVERSION HZ_FILE_VERSION_MAJOR") != std::string::npos, "file version uses the header");
		Expect(rc.find("PRODUCTVERSION HZ_FILE_VERSION_MAJOR") != std::string::npos, "product version uses the header");
		Expect(rc.find("VALUE \"FileVersion\", HZ_FILE_VERSION_STR") != std::string::npos, "file version string uses the header");
		Expect(rc.find("VALUE \"ProductVersion\", HZ_FILE_VERSION_STR") != std::string::npos, "product version string uses the header");
		Expect(rc.find("0.42.0.3") == std::string::npos, "old file version is gone");
		Expect(rc.find(", 3") == std::string::npos && rc.find(".3\"") == std::string::npos, "build number is not typed in the resource");
	}

	{
		std::ifstream in("src/main.cpp");
		Expect(static_cast<bool>(in), "main.cpp opens");
		std::string src((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		const auto load = src.find("SFSE_PLUGIN_LOAD");
		Expect(load != std::string::npos, "plugin load function is present");
		Expect(src.find("REX::INFO(\"HorizonUI {} loaded\", HZ::DllFileVersion());", load) != std::string::npos, "load line prints DllFileVersion");
		Expect(src.find("HorizonUI 0.42.0 loaded") == std::string::npos, "load line is not a typed schema version");
		Expect(src.find("inline const char* kVersion = \"0.42.0\"") != std::string::npos, "settings schema stays 0.42.0");
		Expect(src.find("ShowHUDMessageEvent sink registered (address id 86800)") != std::string::npos, "sink registration is logged");
		Expect(src.find("ShowHUDMessageEvent sink failed:") != std::string::npos, "sink failure is logged");
		Expect(src.find("hud message: text=") != std::string::npos, "matching HUD text is logged");
		Expect(src.find("A missing address id still hard-exits.") != std::string::npos, "a missing address id is documented as a hard exit");
		Expect(src.find("SEH does not catch that lookup.") != std::string::npos, "SEH does not catch a missing address id");
		Expect(src.find("RegisterSink is address id 123821.") != std::string::npos, "the sink comment names RegisterSink id 123821");
		const auto post = src.rfind("kPostDataLoad", load);
		Expect(post != std::string::npos, "post-data-load handler is present");
		const auto postCall = src.find("RegisterShowHUDMessageSink();", post);
		Expect(postCall != std::string::npos && postCall < load, "sink is registered after data load");
		const auto loadEnd = src.find("return true;", load);
		Expect(loadEnd != std::string::npos, "plugin load returns");
		Expect(src.substr(load, loadEnd - load).find("RegisterShowHUDMessageSink") == std::string::npos, "sink is not registered at plugin load");
	}

	{
		std::ifstream in("preset/HorizonUI.moragars-choice-0.42.0.ini");
		Expect(static_cast<bool>(in), "preset ini opens");
		std::string ini((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		Expect(ini.find("Version=0.42.0") != std::string::npos, "preset Version stays 0.42.0");
		Expect(ini.find("test DLL") == std::string::npos, "preset Debug note does not call this a test DLL");
		Expect(ini.find("The comms message log is only in debug builds.") != std::string::npos, "release Debug note");
	}

	{
		std::ifstream in("xmake.lua");
		Expect(static_cast<bool>(in), "xmake.lua opens");
		std::string lua((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		Expect(lua.find("set_version(\"0.42.0.7\")") != std::string::npos, "xmake version is the 4-part file version");
		Expect(lua.find("set_version(\"0.42.0\")") == std::string::npos, "xmake version is not the 3-part schema");
		std::ifstream cpp("res/horizonui-plugin.cpp.in");
		Expect(static_cast<bool>(cpp), "plugin version template opens");
		std::string plugin((std::istreambuf_iterator<char>(cpp)), std::istreambuf_iterator<char>());
		Expect(plugin.find("v.PluginVersion({ ${COMMONLIB_PLUGIN_VERSION_MAJOR}, ${COMMONLIB_PLUGIN_VERSION_MINOR}, ${COMMONLIB_PLUGIN_VERSION_PATCH}, ${HZ_FILE_VERSION_BUILD} });") != std::string::npos, "SFSE plugin version uses the file-version build");
	}

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "preset list tests passed\n";
	return 0;
}
