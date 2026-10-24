// Unit tests for preset dedupe, the shared preset-name character set, and the
// single file-version header. No game, no CommonLibSF.
// Build: g++ -std=c++20 -Wall -Wextra -I src tests/preset_list_test.cpp -o /tmp/preset_list_test

#include "hz_addr_probe.h"
#include "hz_msg_match.h"
#include "hz_rx_queue.h"
#include "hz_version.h"
#include "preset_dedupe.h"

#include <cstdint>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

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

	Expect(std::string(HZ_FILE_VERSION_STR) == "0.42.0.10", "file version string");
	Expect(HZ_FILE_VERSION_MAJOR == 0 && HZ_FILE_VERSION_MINOR == 42 && HZ_FILE_VERSION_PATCH == 0 && HZ_FILE_VERSION_BUILD == 10, "file version numbers");
	Expect(HZ_COMMS_MSG_LOG == 1, "verbose reaction trace is on for this test build");
	Expect(HZ_HUD_MSG_CAPTURE == 1, "unfiltered HUD capture is on for this test build");
	Expect(HzFileVersionOk("0.42.0.10"), "4-part version ok");
	Expect(!HzFileVersionOk("0.42.0"), "3-part version is not the file version");
	Expect(!HzFileVersionOk("v0.42.0.6"), "leading v is not accepted");
	Expect(!HzFileVersionOk("0.42.0.6 "), "trailing space rejected");

	{
		const auto en = hzmsg::English();
		auto hit = [&](const char* text, const hzmsg::Templates& phrases) { return hzmsg::Match(text, phrases); };
		auto ok = [&](const hzmsg::Hit& h, const char* kind, const char* sub, const char* name, const char* value, char tier, const char* what) {
			if (!h.ok || h.kind != kind || h.sub != sub || h.name != name || h.value != value || h.tier != tier) {
				std::cerr << "FAIL: " << what << "\n  got: ok=" << h.ok << " " << h.kind << "/" << h.sub
					<< " name=[" << h.name << "] value=[" << h.value << "] tier=" << h.tier << "\n";
				++g_fails;
			}
		};
		auto miss = [&](const char* text, const hzmsg::Templates& phrases, const char* what) {
			const auto h = hit(text, phrases);
			if (h.ok) {
				std::cerr << "FAIL: " << what << " matched " << h.kind << "/" << h.sub << " [" << h.name << "]\n";
				++g_fails;
			}
		};
		ok(hit("Sam Coe liked that.", en), "reaction", "liked", "Sam Coe", "LIKED", 'C', "Sam Coe liked that");
		ok(hit("SAM COE LIKED THAT.", en), "reaction", "liked", "SAM COE", "LIKED", 'C', "upper case liked");
		ok(hit("Sam Coe loved that.", en), "reaction", "loved", "Sam Coe", "LOVED", 'C', "loved");
		ok(hit("Sam Coe disliked that.", en), "reaction", "disliked", "Sam Coe", "DISLIKED", 'C', "disliked is not liked");
		ok(hit("Sam Coe hated that.", en), "reaction", "hated", "Sam Coe", "HATED", 'C', "hated");
		ok(hit("Sam Coe likes that", en), "reaction", "liked", "Sam Coe", "LIKED", 'C', "present likes");
		ok(hit("  Sam Coe liked that.  ", en), "reaction", "liked", "Sam Coe", "LIKED", 'C', "trimmed reaction");
		miss("I liked that.", en, "pronoun");
		miss("No one liked that.", en, "no one");
		miss("Dr. liked that.", en, "bare title");
		miss("Added.", en, "loot line");
		miss("", en, "empty");
		miss(" cured.", en, "empty affliction name");
		miss("<Alias=TextReplacementRefAlias> gained.", en, "unresolved alias");
		miss("Sam Coe lik", en, "cut-off reaction");
		auto de = en;
		de.likes = "das gefiel.";
		de.dislikes = "das missfiel.";
		ok(hit("Sam Coe das gefiel.", de), "reaction", "liked", "Sam Coe", "LIKED", 'A', "localized likes suffix");
		miss("Sam Coe liked that.", de, "English likes is not used once the GMST differs");
		miss("Sam Coe likes that.", de, "present tense stays English-only");
		auto mixed = en;
		mixed.dislikes = "mochte das nicht.";
		ok(hit("Sam Coe mochte das nicht.", mixed), "reaction", "disliked", "Sam Coe", "DISLIKED", 'A', "localized dislikes");
		miss("Sam Coe disliked that.", mixed, "English liked does not claim a disliked line");
		ok(hit("This individual is busy.", en), "unavailable", "busy", "", "BUSY", 'C', "busy");
		auto busy = en;
		busy.busy = "Esta persona esta ocupada.";
		ok(hit("Esta persona esta ocupada.", busy), "unavailable", "busy", "", "BUSY", 'A', "localized busy");
		ok(hit("Contusions cured.", en), "medical", "cured", "Contusions", "CURED", 'C', "cured");
		ok(hit("Prognosis improved (Contusions).", en), "medical", "improved", "Contusions", "IMPROVED", 'C', "prognosis");
		ok(hit("Severity improved (Poisoning).", en), "medical", "severity", "Poisoning", "LESS SEVERE", 'C', "severity");
		ok(hit("Attempted to cure Burns.", en), "medical", "attempted", "Burns", "ATTEMPTED", 'C', "attempted");
		ok(hit("Fractured Limb gained.", en), "medical", "gained", "Fractured Limb", "GAINED", 'C', "gained");
		ok(hit("Lung Damage became worse.", en), "medical", "worse", "Lung Damage", "WORSE", 'C', "worse");
		ok(hit("500 credits have been sent home to your parents.", en), "credits", "kid", "", "-500", 'C', "kid stuff 500");
		ok(hit("1,500 credits have been sent home to your parents.", en), "credits", "kid", "", "-1500", 'C', "kid stuff 1500");
		miss("about 500 credits have been sent home to your parents.", en, "junk before the amount");
		ok(hit("Andreja is now following you.", en), "crew", "follow", "Andreja", "FOLLOWING", 'C', "following");
		ok(hit("Andreja is no longer following you.", en), "crew", "unfollow", "Andreja", "FOLLOWING", 'C', "unfollow");
		ok(hit("Andreja is no longer your Active Companion", en), "crew", "uncompanion", "Andreja", "COMPANION", 'C', "uncompanion without a period");
		ok(hit("Andreja is now your Active Companion.", en), "crew", "companion", "Andreja", "COMPANION", 'C', "companion");
		ok(hit("Andreja is available to be your Companion", en), "crew", "companion-available", "Andreja", "AVAILABLE", 'C', "companion available");
		ok(hit("Andreja is no longer available to be your companion.", en), "crew", "companion-unavailable", "Andreja", "AVAILABLE", 'C', "longer unavailable suffix wins");
		ok(hit("Sarah Morgan considers you a friend.", en), "crew", "friend", "Sarah Morgan", "FRIEND", 'C', "friend");
		ok(hit("Sam Coe is furious with you and will no longer be your companion.", en), "crew", "furious", "Sam Coe", "FURIOUS", 'C', "furious");
		ok(hit("Sam Coe is no longer angry with you.", en), "crew", "calm", "Sam Coe", "CALM", 'C', "calm is not angry");
		ok(hit("Sam Coe is angry with you.", en), "crew", "angry", "Sam Coe", "ANGRY", 'C', "angry");
		ok(hit("Sarah Morgan has already caught you.", en), "unavailable", "caught", "Sarah Morgan", "CAUGHT", 'C', "caught");
		ok(hit("The creature is calmed and cannot respond.", en), "unavailable", "calmed", "Creature", "CALMED", 'C', "creature");
		ok(hit("Sam Coe is calmed and cannot respond.", en), "unavailable", "calmed", "Sam Coe", "CALMED", 'C', "npc calmed");
		ok(hit("You've been caught pickpocketing.", en), "unavailable", "caught", "", "CAUGHT", 'C', "pickpocket fail");
		ok(hit("The owner caught you stealing.", en), "crime", "takeback", "", "CAUGHT", 'C', "steal take-back");
		ok(hit("THE OWNER CAUGHT YOU STEALING.", en), "crime", "takeback", "", "CAUGHT", 'C', "steal take-back folded");
		ok(hit("You've been caught stealing and the alarm has been raised.", en), "crime", "alarm", "", "ALARM", 'C', "steal alarm");
		ok(hit("You've been caught tampering with a lock.", en), "crime", "lock", "", "CAUGHT", 'C', "lockpick caught");
		ok(hit("You're currently trespassing. Residents will become hostile if you stay.", en), "crime", "trespass", "", "TRESPASS", 'C', "trespass");
		ok(hit("Last witness killed.", en), "crime", "witness", "", "WITNESS", 'C', "witness");
		miss("The owner caught you stealing a cup.", en, "steal take-back is exact");
		miss("caught you stealing", en, "steal fragment is not enough");
		ok(hit("500 bounty added to United Colonies", en), "credits", "bounty-add", "United Colonies", "+500", 'C', "bounty added");
		ok(hit("1,500 bounty removed from United Colonies", en), "credits", "bounty", "United Colonies", "-1,500", 'C', "bounty paid");
		miss("bounty added to United Colonies", en, "bounty without an amount");
		ok(hit("500 Credits Added.", en), "credits", "gain", "", "+500", 'C', "credits added");
		ok(hit("1,500 Credits Added.", en), "credits", "gain", "", "+1,500", 'C', "credits added grouped");
		ok(hit("Credits (500) Added.", en), "credits", "gain", "", "+500", 'C', "credits added paren");
		ok(hit("Credits x500 Added.", en), "credits", "gain", "", "+500", 'C', "credits added times");
		ok(hit("200 Credits Removed.", en), "credits", "loss", "", "-200", 'C', "credits removed");
		miss("Credits Card Added.", en, "other item with Credits in the name");
		miss("Added.", en, "generic added without the Credits name or amount");
		{
			const auto kid = hzmsg::MatchTemplate("500 credits have been sent home to your parents.", en.kidTpl);
			Expect(kid.ok && kid.amount == "500", "Kid Stuff template 500");
			const auto kid15 = hzmsg::MatchTemplate("1,500 credits have been sent home to your parents.", en.kidTpl);
			Expect(kid15.ok && kid15.amount == "1500", "Kid Stuff template 1500");
			const auto named = hzmsg::MatchTemplate("Sam Coe liked that.", "%s liked that.");
			Expect(named.ok, "percent-s template");
			const auto num = hzmsg::MatchTemplate("Pay 40 credits.", "Pay %d credits.");
			Expect(num.ok && num.amount == "40", "percent-d template");
			const auto frac = hzmsg::MatchTemplate("12.0 credits due.", "%.1f credits due.");
			Expect(frac.ok && frac.amount == "120", "percent-dot-Nf treats the period as a group separator");
			const auto glob = hzmsg::MatchTemplate("Interest is 250 credits.", "Interest is <Global=Trait_StarterHome_Interest> credits.");
			Expect(glob.ok && glob.amount == "250", "Global wildcard template");
			Expect(!hzmsg::MatchTemplate("Added.", "%.0f credits have been sent home to your parents.").ok, "Added. is not Kid Stuff");
		}
		ok(hit("500 credits have been sent home to your parents.", en), "credits", "kid", "", "-500", 'C', "kid stuff still 500 after tokenizer");
		ok(hit("1,500 credits have been sent home to your parents.", en), "credits", "kid", "", "-1500", 'C', "kid stuff still 1500 after tokenizer");
		{
			auto deKid = en;
			deKid.kidTpl = "%.0f Credits wurden nach Hause geschickt.";
			deKid.credits = "Credits wurden nach Hause geschickt.";
			ok(hit("750 Credits wurden nach Hause geschickt.", deKid), "credits", "kid", "", "-750", 'C', "localized Kid Stuff template");
		}
		miss(std::string(201, 'A').c_str(), en, "over the 200 byte cap");
		Expect(!hzmsg::UsablePhrase(""), "blank phrase");
		Expect(!hzmsg::UsablePhrase("<ID=123>"), "stub phrase");
		Expect(hzmsg::UsablePhrase("liked that."), "English phrase");
		auto applied = en;
		hzmsg::ApplyPhrase(applied.likes, "<ID=1>");
		Expect(applied.likes == "liked that.", "a stub does not replace English");
		hzmsg::ApplyPhrase(applied.likes, "  das gefiel.  ");
		Expect(applied.likes == "das gefiel.", "a real phrase replaces English");
	}

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
		std::string gmst(158, 'a');
		gmst += "\xF0\x9F\x8C\x8D";
		ExpectEq(Utf8Prefix(gmst, 160), std::string(158, 'a'), "a GMST cut of 160 does not split a 4-byte character");
		std::string gmst159(159, 'b');
		gmst159 += "\xF0\x9F\x8C\x8D";
		ExpectEq(Utf8Prefix(gmst159, 160), std::string(159, 'b'), "a GMST cut keeps 159 bytes when a 4-byte character would cross 160");
	}

	{
		struct Note
		{
			char text[201];
			unsigned long long tick;
		};
		std::deque<Note> q;
		Expect(!hzrx::Enqueue(q, nullptr, 1), "a null HUD line is dropped");
		Expect(!hzrx::Enqueue(q, "", 1), "an empty HUD line is dropped");
		Expect(q.empty(), "a dropped line is not stored");
		Expect(hzrx::Enqueue(q, "Sam Coe liked that.", 10), "the first line is stored");
		Expect(!hzrx::Enqueue(q, "Sam Coe liked that.", 11), "an exact duplicate is dropped");
		Expect(q.size() == 1 && q.front().tick == 10, "the first copy of a duplicate stays");
		const std::string longA(250, 'a');
		const std::string longB = longA + "XYZ";
		std::deque<Note> cut;
		Expect(hzrx::Enqueue(cut, longA.c_str(), 1), "a long line is stored");
		Expect(!hzrx::Enqueue(cut, longB.c_str(), 2), "two lines that truncate to the same 200 bytes dedupe");
		Expect(cut.size() == 1 && std::strlen(cut.front().text) == 200, "the stored line is 200 bytes");
		Expect(std::string(cut.front().text) == std::string(200, 'a'), "the stored line is not split");
		std::deque<Note> cap;
		for (int i = 0; i < 8; ++i) {
			const std::string line = "line " + std::to_string(i);
			Expect(hzrx::Enqueue(cap, line.c_str(), static_cast<unsigned long long>(i)), "a queue slot is stored");
		}
		Expect(hzrx::Enqueue(cap, "line 8", 8), "the ninth line is stored");
		Expect(cap.size() == 8 && std::string(cap.front().text) == "line 1" && std::string(cap.back().text) == "line 8", "the ninth line drops the oldest");
	}

	{
		auto blob = [](std::uint32_t a_format, std::int32_t a_count, const std::vector<std::uint32_t>& a_slots) {
			std::vector<unsigned char> b(hzaddr::kV5HeaderBytes + a_slots.size() * 4u, 0);
			std::memcpy(b.data(), &a_format, sizeof a_format);
			std::memcpy(b.data() + 92, &a_count, sizeof a_count);
			for (std::size_t i = 0; i < a_slots.size(); ++i)
				std::memcpy(b.data() + hzaddr::kV5HeaderBytes + i * 4u, &a_slots[i], sizeof a_slots[i]);
			return b;
		};
		const auto ok = blob(5, 3, { 0x1000u, 0u, 0x20u });
		Expect(hzaddr::V5Slot(ok.data(), ok.size(), 0) == 1, "a non-zero v5 slot resolves");
		Expect(hzaddr::V5Slot(ok.data(), ok.size(), 1) == 0, "a zero v5 slot does not resolve");
		Expect(hzaddr::V5Slot(ok.data(), ok.size(), 2) == 1, "a later non-zero v5 slot resolves");
		Expect(hzaddr::V5Slot(ok.data(), ok.size(), 3) == 0, "an id past the table does not resolve");
		Expect(hzaddr::V5Slot(ok.data(), ok.size(), 938225) == 0, "a high id past a short table does not resolve");
		const auto bad = blob(2, 3, { 0x1000u, 0u, 0x20u });
		Expect(hzaddr::V5Slot(bad.data(), bad.size(), 0) == -1, "a non-v5 table is not used");
		Expect(hzaddr::V5Slot(ok.data(), 10, 0) == -1, "a short image is not used");
		const auto chopped = blob(5, 3, { 0x1000u });
		Expect(hzaddr::V5Slot(chopped.data(), chopped.size(), 0) == -1, "a table that does not fit is not used");
	}

	{
		char buf[201];
		std::string past(199, 'a');
		past += "\xC3\xA9";
		CopyHudText(buf, sizeof(buf), past.c_str());
		ExpectEq(buf, std::string(199, 'a'), "a character past 200 bytes is dropped");
		std::string fit(198, 'a');
		fit += "\xC3\xA9";
		CopyHudText(buf, sizeof(buf), fit.c_str());
		ExpectEq(buf, fit, "a complete character at 200 bytes stays");
		std::string wide(197, 'b');
		wide += "\xF0\x9F\x8C\x8D";
		CopyHudText(buf, sizeof(buf), wide.c_str());
		ExpectEq(buf, std::string(197, 'b'), "a 4-byte character that crosses 200 bytes is dropped");
		CopyHudText(buf, sizeof(buf), "A\x01" "B\x7f" "C");
		ExpectEq(buf, "A B C", "controls and DEL become spaces");
		CopyHudText(buf, sizeof(buf), "Hi\xC3");
		ExpectEq(buf, "Hi", "an incomplete UTF-8 sequence is dropped");
		CopyHudText(buf, 0, "Sam");
		CopyHudText(nullptr, 4, "Sam");
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
		Expect(src.find("void HzRxEnqueue(const char* a_text);") != std::string::npos, "the sink thread only enqueues");
		Expect(src.find("std::lock_guard<std::mutex> lock(g_rxMu);") != std::string::npos, "the reaction queue is mutex locked");
		Expect(src.find("kRxQueueMax") != std::string::npos, "the reaction queue is bounded");
		Expect(src.find("HasMember(\"hzcCardPush\")") != std::string::npos, "Poll invokes hzcCardPush only when the movie defines it");
		Expect(src.find("kRxQueueMax = 8") != std::string::npos, "the HUD message queue holds 8");
		Expect(src.find("hzrx::Enqueue(g_rxQ, a_text, GetTickCount64(), kRxQueueMax)") != std::string::npos, "the HUD queue uses the shared policy");
		Expect(src.find("hud gmst: address id {} does not resolve, English fallback") != std::string::npos, "a missing settings id is logged and skipped");
		Expect(src.find("hud form: address id {} does not resolve") != std::string::npos, "a missing form id is logged and skipped");
		Expect(src.find("if (g_iniDebug) REX::INFO(\"hud gmst: address id {} does not resolve, English fallback\"") != std::string::npos, "the settings id line is behind Debug");
		Expect(src.find("if (g_iniDebug) REX::INFO(\"hud form: address id {} does not resolve\"") != std::string::npos, "the form id line is behind Debug");
		Expect(src.find("if (g_iniDebug) REX::INFO(\"hud address:") != std::string::npos, "the address line is behind Debug");
		Expect(src.find("if (get(\"debug\", v) && v == \"1\") g_iniDebug = true;") != std::string::npos, "Debug=1 is the only debug gate");
		{
			const auto prep = src.find("void HzMsgPrepare()");
			const auto prepEnd = src.find("static std::string HzCrossName()", prep);
			Expect(prep != std::string::npos && prepEnd > prep, "the address reads are bounded");
			const auto body = src.substr(prep, prepEnd - prep);
			const auto rel = body.find("g_addrBytes.clear();");
			const auto fit = body.find("g_addrBytes.shrink_to_fit();");
			const auto both = body.find("if (g_msgGmstDone && g_msgFormDone)");
			Expect(both != std::string::npos && rel != std::string::npos && fit != std::string::npos && both < rel && rel < fit, "the versionlib image is freed after both reads");
		}
		{
			const auto fill = src.find("static void HzGmstFillCall");
			const auto fillEnd = src.find("struct HzFormRaw", fill);
			Expect(fill != std::string::npos && fillEnd > fill, "the settings read is bounded");
			const auto body = src.substr(fill, fillEnd - fill);
			const auto probe = body.find("HzAddrSlot");
			const auto call = body.find("GetSingleton()");
			Expect(probe != std::string::npos && call != std::string::npos && probe < call, "settings are not read until the address resolves");
		}
		{
			const auto fill = src.find("static void HzFormFillCall");
			const auto fillEnd = src.find("#if defined(_MSC_VER)", fill);
			Expect(fill != std::string::npos && fillEnd > fill, "the form read is bounded");
			const auto body = src.substr(fill, fillEnd - fill);
			const auto probe = body.find("HzAddrSlot");
			const auto call = body.find("LookupByID(id)");
			Expect(probe != std::string::npos && call != std::string::npos && probe < call, "forms are not looked up until the address resolves");
		}
		Expect(src.find("hud capture: text=") != std::string::npos, "the unfiltered capture line is present");
		Expect(src.find("RE::ID::GameSettingCollection::Singleton.id() == 0") != std::string::npos, "a zero settings address id is not called");
		Expect(src.find("RE::ID::TESForm::LookupByID.id() == 0") != std::string::npos, "a zero form lookup id is not called");
		Expect(src.find("HzCopySetting(col, \"sStealTakeBack\"") != std::string::npos, "sStealTakeBack is loaded");
		Expect(src.find("HzCopySetting(col, \"sStealAttack\"") != std::string::npos, "sStealAttack is loaded");
		Expect(src.find("HzCopySetting(col, \"sLockpickingCaught\"") != std::string::npos, "sLockpickingCaught is loaded");
		Expect(src.find("HzCopySetting(col, \"sTrespassing\"") != std::string::npos, "sTrespassing is loaded");
		Expect(src.find("HzCopySetting(col, \"sWitnessKilled\"") != std::string::npos, "sWitnessKilled is loaded");
		Expect(src.find("HzCopySetting(col, \"sAddCrimeGold\"") != std::string::npos, "sAddCrimeGold is loaded");
		Expect(src.find("HzCopySetting(col, \"sRemoveCrimeGold\"") != std::string::npos, "sRemoveCrimeGold is loaded");
		Expect(src.find("HzCopySetting(col, \"sAddItemtoInventory\"") != std::string::npos, "sAddItemtoInventory is loaded");
		Expect(src.find("HzCopySetting(col, \"sRemoveItemfromInventory\"") != std::string::npos, "sRemoveItemfromInventory is loaded");
		Expect(src.find("LookupByID(0x0000000F)") != std::string::npos, "Credits form 0xF is looked up through the guarded path");
		Expect(src.find("TESPickpocketFailedEvent") == std::string::npos, "pickpocket event sink stays out");
		Expect(src.find("PlayerCrimeGoldEvent") == std::string::npos, "crime-gold event sink stays out");
		Expect(src.find("TESContainerChangedEvent") == std::string::npos, "container-changed event sink stays out");
		Expect(src.find("crew card: path=dll-match") != std::string::npos, "crew cards log their DLL path");
		Expect(src.find("hzmsg::Match(") != std::string::npos, "classification runs through the pure matcher");
		Expect(src.find("comms reaction: {} | messages visible={} | dialogue={}") != std::string::npos, "each reaction logs one status");
		Expect(src.find("void CommsRxPoll(ULONGLONG) {}") == std::string::npos, "the reaction drain is not compiled out");
		Expect(src.find("void CommsDbgPoll(ULONGLONG) {}") != std::string::npos, "the verbose poll is the only empty stub");
		Expect(src.find("std::atomic<bool> g_hudMsgReadWarned{false};") != std::string::npos, "the sink warning flag is atomic");
		Expect(src.find("constexpr ULONGLONG kRxMaxAge = 3000;") != std::string::npos, "a queued reaction expires after 3 s");
		Expect(src.find("a_now - n.tick > kRxMaxAge") != std::string::npos, "Poll drops a note older than 3 s");
		{
			const auto cap = src.find("REX::INFO(\"hud capture: text=");
			const auto capGate = src.rfind("#if HZ_HUD_MSG_CAPTURE", cap);
			const auto capEnd = src.find("#endif", cap);
			const auto push = src.find("HzRxEnqueue(snap.text)", capEnd);
			Expect(cap != std::string::npos && capGate != std::string::npos && capEnd != std::string::npos && push != std::string::npos, "the capture line is gated and the enqueue is not");
			Expect(capGate < cap && cap < capEnd && push > capEnd, "only the capture line is behind its flag");
			const auto hud = src.find("REX::INFO(\"hud message: text=");
			const auto gate = src.rfind("#if HZ_COMMS_MSG_LOG", hud);
			const auto endGate = src.find("#endif", hud);
			Expect(hud != std::string::npos && gate != std::string::npos && endGate != std::string::npos && gate < hud && hud < endGate, "the verbose HUD line stays behind its own flag");
			const auto drain = src.find("void CommsRxPoll(ULONGLONG a_now)");
			const auto dbg = src.find("void CommsDbgPoll(ULONGLONG a_now)", drain);
			Expect(drain != std::string::npos && dbg != std::string::npos && drain < dbg, "Poll stays compiled ahead of the verbose stub");
			const auto proc = src.find("ProcessEvent(const RE::ShowHUDMessageEvent&");
			const auto procEnd = src.find("g_hudMsgSink", proc);
			Expect(proc != std::string::npos && procEnd > proc, "the sink method is bounded");
			const auto body = src.substr(proc, procEnd - proc);
			Expect(body.find("GetSetting") == std::string::npos, "the sink does not read a setting");
			Expect(body.find("LookupByID") == std::string::npos, "the sink does not look up a form");
			Expect(body.find("Invoke") == std::string::npos, "the sink thread does not touch Scaleform");
		}
		Expect(src.find("for (auto m : { \"LoadingMenu\", \"MainMenu\" })") != std::string::npos, "the reaction drain skips loading and the main menu");
		const auto rxPoll = src.find("CommsRxPoll(now);");
		const auto hudWait = src.find("if (now - g_hudSince < 3000) return;");
		Expect(rxPoll != std::string::npos && hudWait != std::string::npos && rxPoll < hudWait, "the reaction drain is not gated on HUD ready");
		const auto proc = src.find("ProcessEvent(const RE::ShowHUDMessageEvent&");
		const auto procEnd = src.find("g_hudMsgSink", proc);
		Expect(proc != std::string::npos && procEnd != std::string::npos && procEnd > proc, "the sink method is present");
		Expect(src.substr(proc, procEnd - proc).find("Invoke") == std::string::npos, "the sink thread does not touch Scaleform");
		Expect(src.substr(proc, procEnd - proc).find("HzRxEnqueue") != std::string::npos, "the sink pushes the reaction text");
	}

	{
		std::ifstream in("preset/HorizonUI.moragars-choice-0.42.0.ini");
		Expect(static_cast<bool>(in), "preset ini opens");
		std::string ini((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		Expect(ini.find("Version=0.42.0") != std::string::npos, "preset Version stays 0.42.0");
		Expect(ini.find("test DLL") == std::string::npos, "preset Debug note does not call this a test DLL");
		Expect(ini.find("The comms message log is only in debug builds.") != std::string::npos, "release Debug note");
		Expect(ini.find("VehicleExitPill") == std::string::npos, "the preset does not mirror the vehicle exit default");
		Expect(ini.find("DlgPersuasionMeter") == std::string::npos, "the preset does not mirror the persuasion meter default");
	}

	{
		std::ifstream in("Interface/HorizonUI/HorizonUI.default.ini");
		Expect(static_cast<bool>(in), "default.ini opens");
		std::string ini((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		Expect(ini.find("\r\n") != std::string::npos, "default.ini stays CRLF");
		const auto cards = ini.find("[Cards]");
		const auto compass = ini.find("[Compass]");
		const auto veh = ini.find("VehicleExitPill=1");
		Expect(cards != std::string::npos && compass != std::string::npos && veh != std::string::npos && cards < veh && veh < compass, "VehicleExitPill defaults on under Cards");
		Expect(ini.find("; Vehicle exit prompt: 1 = Horizon pill") != std::string::npos, "VehicleExitPill has its comment");
		Expect(ini.find("F11 opens from the main HUD only (not while the scanner or a full-screen menu is open).") != std::string::npos, "the settings key comment keeps the F11 hint");
		Expect(ini.find("set in F11 > SCANNER from the main HUD (F11 does not open inside the scanner).") != std::string::npos, "the scanner comment keeps the F11 hint");
		const auto comms = ini.find("[Comms]");
		const auto scanner = ini.find("[Scanner]");
		const auto meter = ini.find("DlgPersuasionMeter=1");
		Expect(comms != std::string::npos && scanner != std::string::npos && meter != std::string::npos && comms < meter && meter < scanner, "DlgPersuasionMeter defaults on under Comms");
		Expect(ini.find("; 1 = Horizon persuasion meter (score, the highlighted reply, turns). 0 = the game's meter") != std::string::npos, "DlgPersuasionMeter has its comment");
		Expect(ini.find("ReactionCard=1") != std::string::npos, "ReactionCard defaults on");
		Expect(ini.find("VitalsLayout=0") != std::string::npos, "VitalsLayout keeps its default");
		Expect(ini.find("[Scope]") != std::string::npos && ini.find("ScopeHoldBreathChip=1") != std::string::npos, "the scope block is in the defaults");
		Expect(ini.find("TempUnit=0") != std::string::npos, "temperature units default to Celsius");
	}

	{
		std::ifstream in("xmake.lua");
		Expect(static_cast<bool>(in), "xmake.lua opens");
		std::string lua((std::istreambuf_iterator<char>(in)), std::istreambuf_iterator<char>());
		Expect(lua.find("set_version(\"0.42.0.10\")") != std::string::npos, "xmake version is the 4-part file version");
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
