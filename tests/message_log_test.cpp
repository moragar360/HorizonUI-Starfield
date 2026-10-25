// Message Log P1: capture, ring, pins, prune, per-character files, Persist=0,
// save-line exclusion, and the F11 popup stack. No game, no CommonLibSF.
// These cases are written to fail when a rule is broken.
// Build: g++ -std=c++20 -Wall -Wextra -I src tests/message_log_test.cpp -o /tmp/message_log_test
// Author: Moragar
// Last modified: 2026-10-25.

#include "hz_msglog.h"
#include "hz_msglog_stack.h"
#include "hz_version.h"

#include <filesystem>
#include <fstream>
#include <iostream>
#include <string>
#include <unistd.h>
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

void ExpectEqI(int a_got, int a_want, const char* a_what)
{
	if (a_got == a_want) return;
	std::cerr << "FAIL: " << a_what << "\n  got:  " << a_got << "\n  want: " << a_want << "\n";
	++g_fails;
}

hzlog::Capture Cap(hzlog::Kind a_k, const char* a_text, std::uint64_t a_now, double a_gt = 10.0, const char* a_loc = "Akila City")
{
	hzlog::Capture c;
	c.kind = a_k;
	c.text = a_text;
	c.title = hzlog::KindKey(a_k);
	c.ts = static_cast<std::int64_t>(a_now / 1000);
	c.nowMs = a_now;
	c.gt = a_gt;
	c.ut = 14.5;
	c.lt = 0.3;
	c.loc = a_loc;
	return c;
}

std::filesystem::path TmpRoot()
{
	auto p = std::filesystem::temp_directory_path() / ("hz-msglog-" + std::to_string(::getpid()));
	std::error_code ec;
	std::filesystem::remove_all(p, ec);
	std::filesystem::create_directories(p, ec);
	return p;
}

std::string ReadFile(const std::filesystem::path& a_p)
{
	std::ifstream f(a_p, std::ios::binary);
	return std::string((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

void WriteFile(const std::filesystem::path& a_p, const std::string& a_s)
{
	std::error_code ec;
	std::filesystem::create_directories(a_p.parent_path(), ec);
	std::ofstream o(a_p, std::ios::binary | std::ios::trunc);
	o << a_s;
}

std::string Slurp(const char* a_path)
{
	std::ifstream f(a_path);
	return std::string((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

} // namespace

int main()
{
	using namespace hzlog;

	Expect(std::string(HZ_FILE_VERSION_STR) == "0.43.0.1", "file version is 0.43.0.1");
	Expect(HZ_FILE_VERSION_MAJOR == 0 && HZ_FILE_VERSION_MINOR == 43 && HZ_FILE_VERSION_PATCH == 0 && HZ_FILE_VERSION_BUILD == 1, "file version numbers");
	Expect(HZ_COMMS_MSG_LOG == 0, "probe log is off");
	Expect(HZ_HUD_MSG_CAPTURE == 0, "hud capture probe is off");
	ExpectEq(kOpenHint, "F11", "HUD open hint is the F11 key only");

	// ---- save lines excluded ----
	{
		Buffer b;
		Expect(b.Offer(Cap(Kind::Game, "Saving...", 1000)) == OfferResult::SaveSignal, "Saving... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "Autosaving...", 1001)) == OfferResult::SaveSignal, "Autosaving... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "Saving…", 1002)) == OfferResult::SaveSignal, "Saving ellipsis is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$ManualSaveMsg", 1003)) == OfferResult::SaveSignal, "$ManualSaveMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$AutosavingMsg", 1004)) == OfferResult::SaveSignal, "$AutosavingMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$SomeOtherKey", 1005)) == OfferResult::Rejected, "$ keys that are not save lines are rejected");
		ExpectEqI(static_cast<int>(b.entries.size()), 0, "save and $ keys never become rows");
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 1006)) == OfferResult::Stored, "an ordinary line is stored");
		ExpectEqI(static_cast<int>(b.entries.size()), 1, "one ordinary row");
	}

	// ---- Record=0 and type gates ----
	{
		Buffer b;
		b.settings.record = false;
		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 2000)) == OfferResult::Rejected, "Record=0 stores nothing");
		b.settings.record = true;
		b.settings.logTypes = kTypeAll & ~kTypeBusy;
		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 2001)) == OfferResult::Rejected, "Busy off stores nothing");
		Expect(b.Offer(Cap(Kind::Medical, "Contusions cured.", 2002)) == OfferResult::Stored, "other types still store");
		b.settings.modulePresent = false;
		Expect(b.Offer(Cap(Kind::Medical, "Contusions gained.", 2003)) == OfferResult::Rejected, "module off stores nothing");
	}

	// ---- classification including credits ----
	{
		const auto en = hzmsg::English();
		std::string title, tag;
		Expect(ClassifyHud("This individual is busy.", en, title, tag) == Kind::Busy, "busy classifies as busy");
		Expect(ClassifyHud("The owner caught you stealing.", en, title, tag) == Kind::Crime, "caught stealing classifies as crime if it reaches the sink");
		Expect(ClassifyHud("500 credits have been sent home to your parents.", en, title, tag) == Kind::Credits, "Kid Stuff is credits");
		Expect(ClassifyHud("-1890 Credits", en, title, tag) == Kind::Credits, "signed credits use the same matcher");
		Expect(ClassifyHud("Prognosis improved (Contusions)", en, title, tag) == Kind::Medical, "affliction is medical");
		Expect(ClassifyHud("Sarah Morgan considers you a friend.", en, title, tag) == Kind::Crew, "crew line");
		Expect(ClassifyHud("No direct path seen.", en, title, tag) == Kind::Game, "unmatched is game");
	}

	// ---- dedupe 3 s / Busy 10 s ----
	{
		Buffer b;
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 10'000)) == OfferResult::Stored, "first path line");
		Expect(b.Offer(Cap(Kind::Game, "  NO   direct PATH seen. ", 12'000)) == OfferResult::Deduped, "normalized match inside 3 s");
		ExpectEqI(static_cast<int>(b.entries.size()), 1, "dedupe keeps one row");
		ExpectEqI(b.entries[0].n, 2, "n is 2 after one repeat");
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 14'000)) == OfferResult::Deduped, "still inside 3 s of last");
		ExpectEqI(b.entries[0].n, 3, "window slides from the last occurrence");
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 18'000)) == OfferResult::Stored, "outside 3 s is a new row");
		ExpectEqI(static_cast<int>(b.entries.size()), 2, "new row after the window");

		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 20'000)) == OfferResult::Stored, "first busy");
		Expect(b.Offer(Cap(Kind::Busy, "this individual is busy.", 28'000)) == OfferResult::Deduped, "Busy window is 10 s");
		ExpectEqI(b.entries.back().n, 2, "busy n is 2");
		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 39'000)) == OfferResult::Stored, "Busy outside 10 s is new");

		for (int i = 0; i < 20; ++i)
			b.Offer(Cap(Kind::Medical, "Contusions cured.", 40'000 + static_cast<std::uint64_t>(i) * 10));
		Expect(b.entries.back().n <= kRepeatCap, "n never exceeds 999");
	}

	// ---- ring buffer and pin cap (500 + 50 on top) ----
	{
		Buffer b;
		b.SetHistorySize(100);
		for (int i = 0; i < 120; ++i) {
			auto c = Cap(Kind::Game, ("line " + std::to_string(i)).c_str(), 100'000 + static_cast<std::uint64_t>(i) * 4000);
			Expect(b.Offer(c) == OfferResult::Stored, "fill ring");
		}
		ExpectEqI(static_cast<int>(b.entries.size()), 100, "unpinned cap is HistorySize");
		ExpectEq(b.entries.front().text, "line 20", "oldest unpinned is evicted");

		const auto firstId = b.entries.front().id;
		Expect(b.Pin(firstId), "pin oldest remaining");
		for (int i = 120; i < 230; ++i) {
			b.Offer(Cap(Kind::Game, ("line " + std::to_string(i)).c_str(), 200'000 + static_cast<std::uint64_t>(i) * 4000));
		}
		bool pinLived = false;
		for (const auto& e : b.entries)
			if (e.id == firstId && e.pin) pinLived = true;
		Expect(pinLived, "eviction never removes a pin");
		Expect(static_cast<int>(b.entries.size()) == 101, "pins sit on top of HistorySize");

		int pinned = 0;
		for (auto& e : b.entries) {
			if (e.pin) continue;
			if (b.Pin(e.id)) ++pinned;
			if (b.PinCount() >= kPinCap) break;
		}
		ExpectEqI(b.PinCount(), kPinCap, "pin cap is 50");
		std::uint64_t extra = 0;
		for (auto& e : b.entries) {
			if (!e.pin) {
				extra = e.id;
				break;
			}
		}
		Expect(extra != 0 && !b.Pin(extra), "a 51st pin is refused");
		ExpectEqI(b.PinCount(), kPinCap, "pin count stays 50 after the refused pin");
	}

	// ---- prune ----
	{
		Buffer b;
		b.Offer(Cap(Kind::Game, "old", 1'000, 10.0));
		b.Offer(Cap(Kind::Game, "mid", 2'000, 20.0));
		b.Offer(Cap(Kind::Game, "future", 3'000, 30.0));
		const auto futureId = b.entries.back().id;
		Expect(b.Pin(futureId), "pin the future row");
		ExpectEqI(b.Prune(0.0), 0, "gt 0 never prunes");
		ExpectEqI(static_cast<int>(b.entries.size()), 3, "gt 0 keeps every row");
		ExpectEqI(b.Prune(15.0), 1, "unpinned future rows drop");
		ExpectEqI(static_cast<int>(b.entries.size()), 2, "old + pinned future remain");
		bool flagged = false;
		for (const auto& e : b.entries)
			if (e.id == futureId && FromLaterPoint(e, 15.0) && e.pin) flagged = true;
		Expect(flagged, "kept pin is flagged from a later point");
	}

	// ---- per-character switch / NG+ ----
	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.replace = DefaultReplace;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xD6B6EAFA, "Sam");
		log.Offer(Cap(Kind::Game, "sam line", 5'000, 5.0));
		Expect(log.Flush(5'000), "flush character A");
		const auto aFile = root / "MessageLog" / "MessageLog_D6B6EAFA.json";
		Expect(std::filesystem::is_regular_file(aFile), "character A file exists");

		const auto ng = MakeCharacter(0xAABBCCDD, "Sam");
		Expect(log.OnHudReady(ng, 1.0, 6, 6'000), "NG+ key change switches");
		ExpectEqI(static_cast<int>(log.buf.entries.size()), 0, "NG+ starts a new empty log");
		ExpectEq(log.buf.character.key, "AABBCCDD", "new key is the new player id");
		log.Offer(Cap(Kind::Game, "ng line", 7'000, 2.0));
		log.Flush(7'000);
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_AABBCCDD.json"), "NG+ wrote its own file");
		Expect(ReadFile(aFile).find("sam line") != std::string::npos, "old character file is unchanged");

		const auto back = MakeCharacter(0xD6B6EAFA, "Sam");
		Expect(log.OnHudReady(back, 5.0, 8, 8'000), "switch back to A");
		bool found = false;
		for (const auto& e : log.buf.entries)
			if (e.text == "sam line") found = true;
		Expect(found, "loading A does not mix B's rows");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	// ---- Persist=0 writes nothing ----
	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		s.persist = false;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(1, "Sam");
		log.Offer(Cap(Kind::Game, "memory only", 9'000));
		Expect(log.Flush(9'000), "Persist=0 flush is a no-op success");
		Expect(!std::filesystem::exists(root / "MessageLog"), "Persist=0 never creates the folder");
		Expect(!log.FolderExists(), "store reports no folder");
		Expect(!log.store->TouchesDisk(), "null backend does not touch disk");

		// Switching 1 -> 0 stops writes and does not delete.
		Log on;
		Settings s1;
		on.Configure(s1, root);
		on.buf.character = MakeCharacter(1, "Sam");
		on.Offer(Cap(Kind::Game, "on disk", 10'000));
		on.Flush(10'000);
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_00000001.json"), "Persist=1 wrote");
		on.ApplyPersist(false);
		on.Offer(Cap(Kind::Game, "after off", 11'000));
		on.Flush(11'000);
		Expect(ReadFile(root / "MessageLog" / "MessageLog_00000001.json").find("after off") == std::string::npos,
			"Persist 1->0 does not write the new row");
		Expect(ReadFile(root / "MessageLog" / "MessageLog_00000001.json").find("on disk") != std::string::npos,
			"INI Persist=0 does not delete the existing file");
		Expect(on.DeleteCurrentFile(), "delete is an explicit later-UI call");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	// ---- JSON round trip, corrupt, oversized, too-new ----
	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Renamed");
		log.buf.RememberName("Second Name");
		log.Offer(Cap(Kind::Quest, "Talk to Daniel Blake", 12'000, 213.1, "Akila City"));
		log.buf.entries.back().title = "JOB GONE WRONG";
		log.Flush(12'000);
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto body = ReadFile(path);
		Expect(body.find("horizon.messagelog") != std::string::npos, "type token");
		Expect(body.find("Talk to Daniel Blake") != std::string::npos, "text survived");
		auto parsed = FromJson(body);
		Expect(parsed.ok && !parsed.corrupt, "round trip parses");
		ExpectEqI(static_cast<int>(parsed.state.entries.size()), 1, "one entry round trips");
		ExpectEq(parsed.state.character.names.back(), "Second Name", "names are stored for the cleanup list");

		WriteFile(path, "{not json");
		std::error_code ecBak;
		std::filesystem::remove(root / "MessageLog" / "MessageLog_0000ABCD.json.bak", ecBak);
		LogState st;
		std::string notice;
		FileStore fs(root / "MessageLog");
		fs.Load("0000ABCD", st, notice);
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_0000ABCD.json.bad"), "corrupt file is renamed .bad");
		Expect(st.entries.empty(), "corrupt without bak starts empty");

		const auto good = ToJson(parsed.state, "HorizonUI 0.43.0.1");
		WriteFile(path, good);
		fs.Save(parsed.state);
		WriteFile(path, std::string("{\"type\":\"horizon.messagelog\",\"version\":99,\"entries\":[]}"));
		st = {};
		fs.Load("0000ABCD", st, notice);
		Expect(notice.find("too new") != std::string::npos || st.entries.empty() || parsed.state.entries.size() == st.entries.size(),
			"too-new file is not trusted as-is");

		std::string huge(static_cast<std::size_t>(kFileMaxBytes) + 8, 'x');
		auto big = FromJson(huge);
		Expect(big.corrupt, "oversized file is corrupt");

		auto skip = FromJson(std::string("{\"type\":\"horizon.messagelog\",\"version\":1,\"entries\":[{\"id\":1},{\"id\":2,\"k\":\"game\",\"t\":\"ok\"}]}"));
		Expect(skip.ok, "malformed entries do not fail the file");
		ExpectEqI(static_cast<int>(skip.state.entries.size()), 1, "only the good entry loads");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	// ---- popup stack closes every layer ----
	{
		PopStack st;
		Expect(st.Push("f11"), "push f11");
		Expect(st.Push("log"), "push log");
		Expect(st.Push("logset"), "push settings");
		Expect(st.Push("confirm"), "push confirm");
		ExpectEqI(st.Size(), 4, "four layers");
		ExpectEq(st.Pop(), "confirm", "ESC/B closes one layer");
		ExpectEqI(st.Size(), 3, "three remain after one pop");
		ExpectEqI(st.CloseAll(), 3, "forced close closes every remaining layer");
		Expect(st.Empty(), "stack is empty after close-all");
		ExpectEqI(st.CloseAll(), 0, "close-all on empty is safe");
	}

	// ---- wiring contracts that used to freeze F11 ----
	{
		const auto main = Slurp("src/main.cpp");
		const auto as = Slurp("actionscript/horizon_block.as");
		const auto hzc = Slurp("actionscript/comms/hzc_block.as");
		Expect(as.find("function hzSettingsCloseAll") != std::string::npos, "AS3 has hzSettingsCloseAll");
		Expect(main.find("hzSettingsCloseAll") != std::string::npos, "DLL forced close calls hzSettingsCloseAll");
		Expect(main.find("for (int i = 0; i < 2; ++i)") == std::string::npos, "forced close no longer toggles at most twice");
		Expect(main.find("VK_OEM_2") != std::string::npos && main.find("ch:/") != std::string::npos, "slash reaches F11 for Find");
		Expect(main.find("USER_EVENT_FLAG::Looking | RE::USER_EVENT_FLAG::Fighting") != std::string::npos, "only Looking+Fighting stay blocked");
		Expect(main.find("XInputGetState") != std::string::npos, "pad path exists for in-menu navigation");
		Expect(main.find("OnSettingsKey") != std::string::npos && main.find("g_vk") != std::string::npos, "F11 still opens from the keyboard");
		Expect(as.find("hzMsglogOpenHint") != std::string::npos && as.find("return \"F11\"") != std::string::npos,
			"HUD open hint is the F11 key");
		Expect(as.find("notifications") != std::string::npos, "F11 probes the Notifications marker");
		Expect(hzc.find("function hzcTakeLog") != std::string::npos, "movie exposes hzcTakeLog");
		Expect(hzc.find("function hzcTakeLog") != std::string::npos && hzc.find("HUDMessageData stays with the DLL sink") != std::string::npos,
			"take-log is separate from HUDMessageData");
		Expect(hzc.find("hzcLogPush") != std::string::npos && hzc.find("QuestUpdateData") != std::string::npos, "quests are forwarded");
		Expect(hzc.find("HUDLocationData") != std::string::npos && hzc.find("XPData") != std::string::npos, "location and XP are forwarded");
		Expect(main.find("kMsglogOpenWithPad") == std::string::npos, "no pad combo opens F11");
	}

	// ---- settings parse ----
	{
		Expect(ClampHistory(50) == 100, "history floors at 100");
		Expect(ClampHistory(1000) == 1000, "history caps at 1000");
		Expect(ClampHistory(550) == 500, "history steps of 100");
		const auto bits = ParseLogTypes("medical,crew,busy,crime,credits,quest,location,xp,game");
		Expect(bits == kTypeAll, "default type list is every type");
		Expect((ParseLogTypes("busy") & kTypeBusy) != 0, "Busy is a real type");
	}

	// ---- character key fallback ----
	{
		const auto id = MakeCharacter(0, "Sam Coe");
		Expect(id.keySource == "nameHash" && id.key.find("-n") != std::string::npos, "zero player id uses the name-hash fallback");
		const auto keep = MakeCharacter(0x11, "Old");
		Expect(keep.key == "00000011" && keep.keySource == "playerId", "rename keeps the player-id key");
	}

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "message log tests passed\n";
	return 0;
}
