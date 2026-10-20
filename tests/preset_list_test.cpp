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

	Expect(std::string(HZ_FILE_VERSION_STR) == "0.42.0.4", "file version string");
	Expect(HZ_FILE_VERSION_MAJOR == 0 && HZ_FILE_VERSION_MINOR == 42 && HZ_FILE_VERSION_PATCH == 0 && HZ_FILE_VERSION_BUILD == 4, "file version numbers");
	Expect(HzFileVersionOk("0.42.0.4"), "4-part version ok");
	Expect(!HzFileVersionOk("0.42.0"), "3-part version is not the file version");
	Expect(!HzFileVersionOk("v0.42.0.4"), "leading v is not accepted");
	Expect(!HzFileVersionOk("0.42.0.4 "), "trailing space rejected");

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

	// A saved preset with the same settings loses to the installer copy. A different name stays.
	{
		std::vector<Candidate> items = {
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 10),
			C("u:moragars_choice.ini", true, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 80),
			C("u:my_preset.ini", true, "My preset", "my_preset.ini", other.c_str(), 80),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 2 && keep[0] == 0 && keep[1] == 2, "saved duplicate hidden, other name kept, order unchanged");
	}

	// Newer saved preset whose settings differ replaces the installer copy in the list.
	{
		std::vector<Candidate> items = {
			C("s:moragars_choice.ini", false, "Moragar's Choice", "moragars_choice.ini", same.c_str(), 10),
			C("u:custom.ini", true, "Moragar's Choice", "custom.ini", other.c_str(), 90),
		};
		const auto keep = DedupePresetIndices(items, drops);
		Expect(keep.size() == 1 && keep[0] == 1, "newer different saved preset is the one listed");
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

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "preset list tests passed\n";
	return 0;
}
