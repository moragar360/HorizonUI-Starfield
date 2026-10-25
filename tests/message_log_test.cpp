// Message Log P1: capture, ring, pins, prune, per-character files, Persist=0,
// save-line exclusion, and the F11 popup stack. No game, no CommonLibSF.
// These cases are written to fail when a rule is broken.
// Build: g++ -std=c++20 -Wall -Wextra -pthread -I src -DMSGLOG_REPO_ROOT=\"$PWD\" tests/message_log_test.cpp -o /tmp/message_log_test
// Or: MSGLOG_REPO_ROOT=$PWD /tmp/message_log_test  (relative __FILE__ still finds the repo).
// Author: Moragar
// Last modified: 2026-10-25.

#include "hz_msglog.h"
#include "hz_msglog_stack.h"
#include "hz_version.h"

#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <mutex>
#include <set>
#include <string>
#include <thread>
#include <unistd.h>
#include <vector>

#ifndef MSGLOG_REPO_ROOT
#define MSGLOG_REPO_ROOT ""
#endif

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

std::filesystem::path RepoRoot()
{
	std::error_code ec;
	std::vector<std::filesystem::path> seeds;
	if (const char* env = std::getenv("MSGLOG_REPO_ROOT"); env && env[0])
		seeds.emplace_back(env);
	if (MSGLOG_REPO_ROOT[0])
		seeds.emplace_back(MSGLOG_REPO_ROOT);
	auto src = std::filesystem::path(__FILE__);
	if (src.is_relative())
		seeds.push_back(std::filesystem::current_path(ec) / src);
	else
		seeds.push_back(src);
	seeds.push_back(std::filesystem::current_path(ec));
#ifdef __linux__
	char exe[4096]{};
	const auto n = ::readlink("/proc/self/exe", exe, sizeof exe - 1);
	if (n > 0)
		seeds.emplace_back(std::filesystem::path(std::string(exe, static_cast<std::size_t>(n))).parent_path());
#endif
	for (auto seed : seeds) {
		auto p = std::filesystem::weakly_canonical(seed, ec);
		for (int i = 0; i < 8; ++i) {
			if (std::filesystem::is_regular_file(p / "src" / "main.cpp", ec)
				&& std::filesystem::is_regular_file(p / "actionscript" / "horizon_block.as", ec))
				return p;
			if (!p.has_parent_path() || p.parent_path() == p) break;
			p = p.parent_path();
		}
	}
	return std::filesystem::current_path();
}

bool HaveRepo()
{
	std::error_code ec;
	const auto p = RepoRoot();
	return std::filesystem::is_regular_file(p / "src" / "main.cpp", ec)
		&& std::filesystem::is_regular_file(p / "actionscript" / "horizon_block.as", ec);
}

std::string Slurp(const char* a_path)
{
	auto p = std::filesystem::path(a_path);
	if (p.is_relative())
		p = RepoRoot() / p;
	std::ifstream f(p, std::ios::binary);
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
		Expect(b.Offer(Cap(Kind::Game, "$QuickSaveMsg", 1004)) == OfferResult::SaveSignal, "$QuickSaveMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$SavingMsg", 1004)) == OfferResult::SaveSignal, "$SavingMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "Quicksave...", 1004)) == OfferResult::SaveSignal, "Quicksave... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "QuickSave...", 1004)) == OfferResult::SaveSignal, "QuickSave... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$SomeOtherKey", 1005)) == OfferResult::Rejected, "$ keys that are not save lines are rejected");
		ExpectEqI(static_cast<int>(b.entries.size()), 0, "save and $ keys never become rows");
		Expect(b.Offer(Cap(Kind::Game, "Saving the colony", 1005)) == OfferResult::Stored, "Saving the colony is not a save line");
		Expect(b.Offer(Cap(Kind::Game, "Saving... the colony", 1005)) == OfferResult::Stored, "Saving... prefix is not a save line");
		Expect(b.Offer(Cap(Kind::Quest, "Saving the colony", 1006)) == OfferResult::Stored, "quest Saving the colony is stored");
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 1007)) == OfferResult::Stored, "an ordinary line is stored");
		ExpectEqI(static_cast<int>(b.entries.size()), 4, "colony lines, prefix, and one ordinary row");
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

		Buffer edge;
		Expect(edge.Offer(Cap(Kind::Game, "edge", 10'000)) == OfferResult::Stored, "edge first row");
		Expect(edge.Offer(Cap(Kind::Game, "edge", 13'000)) == OfferResult::Deduped, "exact 3000 ms is still inside the window");
		ExpectEqI(static_cast<int>(edge.entries.size()), 1, "exact 3000 ms keeps one row");
		Expect(edge.Offer(Cap(Kind::Game, "edge", 16'001)) == OfferResult::Stored, "3001 ms from last is a new row");
		ExpectEqI(static_cast<int>(edge.entries.size()), 2, "one millisecond past the window is a new row");

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
		Expect(pinned > 0, "the pin loop actually pinned rows");
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
	if (!HaveRepo()) {
		std::cerr << "SKIP: source-pin fixture checks (repo not found from this cwd; "
			"set MSGLOG_REPO_ROOT or rebuild with -DMSGLOG_REPO_ROOT)\n";
	} else {
		const auto main = Slurp("src/main.cpp");
		const auto as = Slurp("actionscript/horizon_block.as");
		const auto hzc = Slurp("actionscript/comms/hzc_block.as");
		Expect(as.find("function hzSettingsCloseAll") != std::string::npos, "AS3 has hzSettingsCloseAll");
		Expect(main.find("hzSettingsCloseAll") != std::string::npos, "DLL forced close calls hzSettingsCloseAll");
		Expect(main.find("for (int i = 0; i < 2; ++i)") == std::string::npos, "forced close no longer toggles at most twice");
		Expect(main.find("attempt < 2") != std::string::npos && main.find("hzToggleSettings") != std::string::npos,
			"close-all falls back to the old toggle loop");
		Expect(main.find("VK_OEM_2") != std::string::npos && main.find("ch:/") != std::string::npos, "slash reaches F11 for Find");
		Expect(main.find("USER_EVENT_FLAG::Looking | RE::USER_EVENT_FLAG::Fighting") != std::string::npos, "only Looking+Fighting stay blocked");
		Expect(main.find("XInputGetState") != std::string::npos, "pad path exists for in-menu navigation");
		Expect(main.find("LoadLibraryW(L\"xinput1_4.dll\")") != std::string::npos
			&& main.find("xinput9_1_0.dll") != std::string::npos, "XInput is loaded dynamically");
		Expect(main.find("pragma comment(lib, \"xinput.lib\")") == std::string::npos, "XInput is not a static import");
		Expect(main.find("\"padx\"") != std::string::npos && main.find("\"pady\"") != std::string::npos, "pad X/Y are actions");
		Expect(main.find("ch:s") == std::string::npos && main.find("ch:y") == std::string::npos, "pad X/Y do not type s or y");
		Expect(main.find("HzMlEngineFillSEH") != std::string::npos && main.find("HzAddrSlot") != std::string::npos,
			"engine reads use HzAddrSlot plus SEH");
		Expect(main.find("try { Poll(); }") != std::string::npos, "the task lambda swallows exceptions");
		Expect(main.find("JoinOrDetach") != std::string::npos && main.find("g_mlWStop") != std::string::npos,
			"writer is stopped and joined");
		Expect(main.find("AtExitShouldJoin") != std::string::npos && main.find("g_mlWThread.detach()") != std::string::npos,
			"atexit joins only when done, otherwise detaches");
		Expect(main.find("g_mlHadSession.exchange(false)") != std::string::npos, "quit flush is edge-triggered");
		Expect(main.find("WriterStartAllowed") != std::string::npos, "detached writer blocks a second thread");
		Expect(main.find("ApplyRecoveredFile") != std::string::npos && main.find("HoldRetryDue") != std::string::npos,
			"DLL promotion merges on the worker and is throttled");
		Expect(main.find("g_mlWFailed.store(true)") != std::string::npos && main.find("NoteWorkerSave") != std::string::npos,
			"the worker sets the failure flag");
		Expect(main.find("NoteWriteFailure") != std::string::npos, "a failed write is retried");
		Expect(main.find("WriteAllowed") != std::string::npos, "force can retry a write");
		Expect(main.find("g_mlWStarted = false") != std::string::npos && main.find("g_mlWLive.store(false)") != std::string::npos,
			"the writer outer catch re-enables a later start");
		Expect(main.find("NoteLoadResult") != std::string::npos && main.find("g_ml.persistHold") != std::string::npos,
			"ApplyLoad holds persist after a transient read");
		Expect(main.find("NoteRetryFailure") != std::string::npos, "retries use exponential backoff");
		Expect(main.find("MsglogQueueRecover") != std::string::npos, "held rows retry on the worker");
		Expect(as.find("padx") != std::string::npos && as.find("pady") != std::string::npos, "AS3 treats padx/pady as actions");
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
		Expect(!PersistAllowed(id), "name-hash is memory-only until a real player id");
		const auto keep = MakeCharacter(0x11, "Old");
		Expect(keep.key == "00000011" && keep.keySource == "playerId", "rename keeps the player-id key");
		Expect(PersistAllowed(keep), "a real player id may persist");
	}

	// ---- crash-safety: depth, 1 MB pre-read, pins, bak, type, writer join ----
	{
		std::string deep = "{\"type\":\"horizon.messagelog\",\"version\":1,\"x\":";
		for (int i = 0; i < 40; ++i) deep += '[';
		for (int i = 0; i < 40; ++i) deep += ']';
		deep += "}";
		auto nest = FromJson(deep);
		Expect(nest.corrupt, "deep nesting is corrupt");
		ExpectEqI(static_cast<int>(kJsonMaxDepth), 32, "JSON skip depth cap is 32");
	}

	{
		const auto root = TmpRoot();
		const auto path = root / "MessageLog" / "MessageLog_0000BIG1.json";
		WriteFile(path, std::string(static_cast<std::size_t>(kFileMaxBytes) + 8, 'x'));
		auto rd = ReadLogFile(path);
		Expect(rd.tooLarge && rd.body.empty(), "1 MB is rejected before the file is read");
		ExpectEq(rd.notice, "file too large", "oversize notice");
		LogState st;
		std::string notice;
		FileStore fs(root / "MessageLog");
		fs.Load("0000BIG1", st, notice);
		Expect(st.entries.empty(), "oversize load starts empty");
		Expect(notice.find("too large") != std::string::npos, "oversize load reports too large");
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_0000BIG1.json.bad"),
			"oversize file is renamed .bad");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		LogState st;
		st.cap = 100;
		for (int i = 0; i < 60; ++i) {
			Entry e;
			e.id = static_cast<std::uint64_t>(i + 1);
			e.kind = Kind::Game;
			e.text = "pin " + std::to_string(i);
			e.pin = 1;
			st.entries.push_back(std::move(e));
		}
		Buffer b;
		b.LoadState(st);
		ExpectEqI(b.PinCount(), kPinCap, "load demotes pins above 50");
		Expect(static_cast<int>(b.entries.size()) <= b.Cap() + kPinCap, "load respects HistorySize plus 50 pins");
	}

	{
		std::string many = "{\"type\":\"horizon.messagelog\",\"version\":1,\"entries\":[";
		for (int i = 0; i < 1100; ++i) {
			if (i) many += ',';
			many += "{\"id\":";
			many += std::to_string(i + 1);
			many += ",\"k\":\"game\",\"t\":\"e";
			many += std::to_string(i);
			many += "\"}";
		}
		many += "]}";
		auto capped = FromJson(many);
		Expect(capped.ok, "a large valid file still parses");
		Expect(static_cast<int>(capped.state.entries.size()) <= kLoadEntryCap, "FromJson caps at HistorySize plus 50 pins");
	}

	{
		auto wrong = FromJson(std::string("{\"type\":\"not-a-log\",\"version\":1,\"entries\":[]}"));
		Expect(wrong.corrupt, "wrong type is corrupt");
		Expect(wrong.notice.find("wrong") != std::string::npos, "wrong type notice");
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "first line", 20'000));
		Expect(log.Flush(20'000), "first flush");
		log.Offer(Cap(Kind::Game, "second line", 40'000));
		Expect(log.Flush(40'000), "second flush writes bak");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		Expect(std::filesystem::is_regular_file(bak), "Save writes a .bak");
		Expect(ReadFile(bak).find("first line") != std::string::npos, ".bak keeps the previous file");
		WriteFile(path, "{not json");
		LogState st;
		std::string notice;
		FileStore fs(root / "MessageLog");
		fs.Load("0000ABCD", st, notice);
		bool recovered = false;
		for (const auto& e : st.entries)
			if (e.text == "first line" || e.text == "second line") recovered = true;
		Expect(recovered, "corrupt file recovers from .bak");
		Expect(notice.find("bak") != std::string::npos || recovered, "bak recovery notice");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0, "Sam Coe");
		log.Offer(Cap(Kind::Game, "new character", 21'000));
		Expect(log.Flush(21'000), "name-hash flush is a memory-only success");
		Expect(!std::filesystem::exists(root / "MessageLog"), "name-hash never creates a shared file");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		FileRead rd;
		rd.ok = false;
		rd.notice = "open failed";
		Expect(!ShouldQuarantine(rd, false), "a transient read error is not .bad");
		rd.tooLarge = true;
		Expect(ShouldQuarantine(rd, false), "oversize is .bad");
		rd.tooLarge = false;
		Expect(ShouldQuarantine(rd, true), "parse failure is .bad");
	}

	{
		const auto root = TmpRoot();
		Settings s;
		s.historySize = 100;
		Log disk;
		disk.Configure(s, root);
		disk.buf.character = MakeCharacter(0xABCDu, "Sam");
		disk.Offer(Cap(Kind::Game, "disk old", 10'000, 10.0, "New Atlantis"));
		disk.Offer(Cap(Kind::Game, "disk shared", 14'000, 11.0, "Akila City"));
		disk.Offer(Cap(Kind::Game, "near shared", 16'000, 11.0, "Akila City"));
		for (int i = 0; i < 50; ++i) {
			disk.Offer(Cap(Kind::Game, ("disk pin " + std::to_string(i)).c_str(),
				20'000 + static_cast<std::uint64_t>(i) * 4000, 12.0));
			disk.buf.Pin(disk.buf.entries.back().id);
		}
		Expect(disk.Flush(40'000), "seed the existing id file");

		Log live;
		live.Configure(s, root);
		live.buf.character = MakeCharacter(0, "Sam");
		live.Offer(Cap(Kind::Game, "session new", 50'000, 13.0, "Cydonia"));
		live.Offer(Cap(Kind::Game, "disk shared", 50'100, 13.0, "Cydonia"));
		live.Offer(Cap(Kind::Game, "near shared", 18'000, 11.2, "Akila City"));
		live.Offer(Cap(Kind::Medical, "session medical", 51'000, 13.0));
		auto sessPin = Cap(Kind::Crew, "session pin", 52'000, 13.0);
		live.Offer(sessPin);
		const auto sessPinId = live.buf.entries.back().id;
		Expect(live.buf.Pin(sessPinId), "session pin before promote");
		for (int i = 0; i < 3; ++i) {
			live.Offer(Cap(Kind::Game, ("extra pin " + std::to_string(i)).c_str(), 53'000 + static_cast<std::uint64_t>(i) * 4000, 13.0));
			live.buf.Pin(live.buf.entries.back().id);
		}
		Expect(!PersistAllowed(live.buf.character), "session is still name-hash");
		Expect(live.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam")), "promote merges the existing file");
		ExpectEq(live.buf.character.key, "0000ABCD", "promotion uses the player id");
		Expect(live.buf.character.keySource == "playerId", "promotion keySource is playerId");

		int oldN = 0, sharedCount = 0, sessionN = 0, medicalN = 0, nearN = 0, nearCount = 0;
		int filePins = 0, sessionPins = 0;
		std::set<std::uint64_t> ids;
		std::int64_t lastTs = -1;
		bool sorted = true;
		for (const auto& e : live.buf.entries) {
			if (!ids.insert(e.id).second)
				Expect(false, "merge IDs are unique");
			if (lastTs >= 0 && e.ts < lastTs) sorted = false;
			lastTs = e.ts;
			if (e.text == "disk old") ++oldN;
			if (e.text == "disk shared") ++sharedCount;
			if (e.text == "session new") ++sessionN;
			if (e.text == "session medical") ++medicalN;
			if (e.text == "near shared") { ++nearCount; nearN = e.n; }
			if (e.pin && e.text.rfind("disk pin ", 0) == 0) ++filePins;
			if (e.pin && (e.text == "session pin" || e.text.rfind("extra pin ", 0) == 0)) ++sessionPins;
		}
		ExpectEqI(oldN, 1, "promotion keeps the existing file history");
		ExpectEqI(sessionN, 1, "promotion keeps the in-memory session");
		ExpectEqI(medicalN, 1, "promotion keeps other session kinds");
		ExpectEqI(sharedCount, 2, "rows more than 3 s apart are not folded");
		ExpectEqI(nearCount, 1, "rows inside 3 s fold");
		Expect(nearN >= 2, "in-window fold increments n");
		Expect(sorted, "merge sorts by time");
		ExpectEqI(static_cast<int>(ids.size()), static_cast<int>(live.buf.entries.size()), "every merge id is unique");
		ExpectEqI(live.buf.PinCount(), kPinCap, "merge pin cap is 50 and file pins win");
		ExpectEqI(filePins, kPinCap, "all 50 pins after merge are the file pins");
		ExpectEqI(sessionPins, 0, "session pins beyond 50 are dropped");
		Expect(live.buf.UnpinnedCount() <= live.buf.Cap(), "promotion respects HistorySize");
		bool sessionPinKept = false;
		for (const auto& e : live.buf.entries)
			if (e.text == "session pin") sessionPinKept = true;
		Expect(sessionPinKept, "session pin text is kept as an unpinned row");

		Log hud;
		hud.Configure(s, root);
		hud.buf.character = MakeCharacter(0, "Sam");
		hud.Offer(Cap(Kind::Game, "hud session", 60'000, 14.0));
		Expect(hud.OnHudReady(MakeCharacter(0xABCDu, "Sam"), 14.0, 9, 9'000), "HUD-ready promotion merges");
		bool hudKept = false, diskKept = false;
		for (const auto& e : hud.buf.entries) {
			if (e.text == "hud session") hudKept = true;
			if (e.text == "disk old") diskKept = true;
		}
		Expect(hudKept && diskKept, "HUD-ready migrate keeps both file and session rows");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		Buffer b;
		b.SetHistorySize(100);
		LogState file;
		file.cap = 100;
		for (int i = 0; i < 100; ++i) {
			Entry e;
			e.id = static_cast<std::uint64_t>(i + 1);
			e.kind = Kind::Game;
			e.text = "old " + std::to_string(i);
			e.ts = i;
			e.gt = static_cast<double>(i);
			file.entries.push_back(std::move(e));
		}
		b.LoadState(file);
		std::vector<Entry> sess;
		for (int i = 0; i < 20; ++i) {
			Entry e;
			e.id = static_cast<std::uint64_t>(i + 1);
			e.kind = Kind::Game;
			e.text = "new " + std::to_string(i);
			e.ts = 1000 + i;
			e.gt = 100.0;
			sess.push_back(std::move(e));
		}
		b.MergeSession(sess);
		ExpectEqI(b.UnpinnedCount(), 100, "merge evicts down to HistorySize");
		bool oldestDropped = true, newestKept = false;
		for (const auto& e : b.entries) {
			if (e.text == "old 0") oldestDropped = false;
			if (e.text == "new 19") newestKept = true;
		}
		Expect(oldestDropped && newestKept, "merge evicts the oldest unpinned rows");
	}

	{
		Buffer b;
		LogState file;
		Entry fe;
		fe.id = 1;
		fe.kind = Kind::Game;
		fe.text = "file row";
		fe.ts = 20;
		file.entries.push_back(fe);
		b.LoadState(file);
		Entry se;
		se.id = 1;
		se.kind = Kind::Crew;
		se.text = "session pin";
		se.ts = 5;
		se.pin = 1;
		b.MergeSession({se});
		ExpectEqI(static_cast<int>(b.entries.size()), 2, "merge keeps both rows");
		Expect(b.entries.front().text == "session pin" && b.entries.front().ts == 5, "earlier session row sorts first");
		Expect(b.entries.front().id != 1 || b.entries.back().id != b.entries.front().id, "appended row is re-ided");
		Expect(b.entries.front().pin == 1, "session pin is carried onto the new id");
		Expect(b.FindId(b.entries.front().id) == &b.entries.front(), "FindId hits the re-ided pin");
		Expect(b.FindId(1) == &b.entries.back() || b.entries.back().id == 1, "file id 1 still finds the file row");
	}

	{
		Buffer b;
		LogState file;
		Entry fe;
		fe.id = 1;
		fe.kind = Kind::Game;
		fe.text = "fold pin";
		fe.norm = NormalizeText("fold pin");
		fe.ts = 100;
		file.entries.push_back(fe);
		b.LoadState(file);
		Entry se;
		se.id = 1;
		se.kind = Kind::Game;
		se.text = "fold pin";
		se.norm = fe.norm;
		se.ts = 103;
		se.pin = 1;
		b.MergeSession({se});
		ExpectEqI(static_cast<int>(b.entries.size()), 1, "exact 3000 ms folds");
		Expect(b.entries.front().pin == 1, "folded row carries the session pin");
		Expect(b.entries.front().n >= 2, "in-window fold increments n");
		Entry late;
		late.kind = Kind::Game;
		late.text = "fold pin";
		late.norm = fe.norm;
		late.ts = 104;
		late.id = 9;
		Buffer b2;
		b2.LoadState(file);
		b2.MergeSession({late});
		ExpectEqI(static_cast<int>(b2.entries.size()), 2, "3001 ms does not fold");
	}

	{
		Buffer b;
		LogState file;
		Entry fe;
		fe.id = 1;
		fe.kind = Kind::Busy;
		fe.text = "This individual is busy.";
		fe.norm = NormalizeText(fe.text);
		fe.ts = 100;
		file.entries.push_back(fe);
		b.LoadState(file);
		Entry se;
		se.kind = Kind::Busy;
		se.text = fe.text;
		se.norm = fe.norm;
		se.ts = 110;
		b.MergeSession({se});
		ExpectEqI(static_cast<int>(b.entries.size()), 1, "Busy 10 s window folds");
		Buffer b2;
		b2.LoadState(file);
		se.ts = 111;
		b2.MergeSession({se});
		ExpectEqI(static_cast<int>(b2.entries.size()), 2, "Busy outside 10 s does not fold");
	}

	{
		Buffer b;
		Expect(b.DedupeClockClear(), "empty buffer clock is clear");
		b.Offer(Cap(Kind::Game, "clock row", 100'000));
		Expect(!b.DedupeClockClear(), "offer arms the dedupe clock");
		auto snap = b.Snapshot();
		b.LoadState(snap);
		Expect(b.DedupeClockClear(), "load clears the dedupe clock");
		b.Offer(Cap(Kind::Game, "clock row", 101'000));
		ExpectEqI(static_cast<int>(b.entries.size()), 2, "cleared clock does not fold across a load");
		b.SortByTime();
		Expect(b.DedupeClockClear(), "sort clears the dedupe clock");
	}

	{
		Expect(WriterStartAllowed(false, false), "a stopped writer may start");
		Expect(!WriterStartAllowed(true, false), "a live detached writer blocks a second start");
		Expect(!WriterStartAllowed(false, true), "a started writer blocks a second start");
		Expect(WriteAllowed(false, true, 1000, 1001), "force bypasses the dirty early return");
		Expect(!WriteAllowed(false, false, 0, 1000), "clean buffer does not write");
		Expect(!WriteAllowed(true, false, 1000, 1500), "retry waits the backoff");
		Expect(WriteAllowed(true, false, 1000, 2000), "retry after the backoff");
		ExpectEqI(NextRetryMs(0), kRetryMsMin, "first backoff is 1 s");
		ExpectEqI(NextRetryMs(1000), 2000, "backoff doubles");
		ExpectEqI(NextRetryMs(2000), 4000, "backoff doubles again");
		ExpectEqI(NextRetryMs(32000), kRetryMsMax, "backoff caps at 60 s");
		ExpectEqI(NextRetryMs(kRetryMsMax), kRetryMsMax, "cap stays at 60 s");
		Expect(!WriteAllowed(true, false, 1000, 2500, 2000), "grown backoff waits");
		Expect(WriteAllowed(true, false, 1000, 3000, 2000), "grown backoff is due");
		Expect(HoldRetryDue(false, 5000, 1000), "first promote is not throttled");
		Expect(!HoldRetryDue(true, 5000, 1001), "held promote waits the backoff");
		Expect(HoldRetryDue(true, 5000, 5000), "held promote runs when due");
		Expect(WithinDedupeWindow(3000, kDedupeMs), "3000 ms folds");
		Expect(!WithinDedupeWindow(3001, kDedupeMs), "3001 ms does not fold");
		Expect(WithinDedupeWindow(10000, kBusyDedupeMs), "Busy 10 s folds");
		Expect(!WithinDedupeWindow(10001, kBusyDedupeMs), "Busy 10.001 s does not fold");
		Expect(BakCopyBlocksReplace(1), "the first bak failure still blocks replace");
		Expect(!BakCopyBlocksReplace(3), "the third bak failure allows replace");
		Expect(AtExitShouldJoin(true), "atexit joins a finished worker");
		Expect(!AtExitShouldJoin(false), "atexit detaches a live-or-killed worker");
		bool dirty = false;
		NoteWriteFailure(dirty);
		Expect(dirty, "a failed write marks dirty so it is retried");
		bool failed = false;
		NoteWorkerSave(false, failed);
		Expect(failed, "the worker failure flag is set on Save false");
		bool hold = false;
		NoteLoadResult(false, hold);
		Expect(hold, "ApplyLoad hold is set on a failed load");
		NoteLoadResult(true, hold);
		Expect(!hold, "a successful load clears the hold");
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		int fails = 0;
		log.replace = [&](const std::filesystem::path&, const std::filesystem::path&) {
			++fails;
			return false;
		};
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "retry me", 20'000));
		Expect(log.dirty, "offer dirties the buffer");
		Expect(!log.Flush(20'000), "a failing replace fails the save");
		Expect(fails >= 1, "Save used the failing replace");
		Expect(log.dirty, "failed save stays dirty for a retry");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		Expect(!std::filesystem::is_regular_file(path), "failed replace leaves no main file");
		log.replace = DefaultReplace;
		log.ApplyPersist(true);
		Expect(log.Flush(21'000), "retry save succeeds");
		Expect(!log.dirty, "successful retry clears dirty");
		Expect(ReadFile(path).find("retry me") != std::string::npos, "retry wrote the row");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "keep original", 20'000));
		Expect(log.Flush(20'000), "seed the main file");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		std::error_code ec;
		std::filesystem::remove(bak, ec);
		std::filesystem::create_directory(bak, ec);
		log.Offer(Cap(Kind::Game, "must not replace", 40'000));
		Expect(!log.Flush(40'000), "a failed bak copy fails the save");
		Expect(ReadFile(path).find("keep original") != std::string::npos, "main file is not replaced after bak failure");
		Expect(ReadFile(path).find("must not replace") == std::string::npos, "new row is not in the main file");
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "keep original", 20'000));
		Expect(log.Flush(20'000), "seed the main file for bak give-up");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		std::error_code ec;
		std::filesystem::remove(bak, ec);
		std::filesystem::create_directory(bak, ec);
		WriteFile(bak / "lock", "held");
		auto* fs = dynamic_cast<FileStore*>(log.store.get());
		Expect(fs != nullptr, "persist store is FileStore");
		if (fs) fs->bakFailGiveUp = 3;
		log.Offer(Cap(Kind::Game, "third try writes", 40'000));
		Expect(!log.Flush(41'000), "first bak failure still blocks");
		Expect(!log.Flush(42'000), "second bak failure still blocks");
		Expect(log.Flush(43'000), "third bak failure writes the main file");
		Expect(ReadFile(path).find("third try writes") != std::string::npos, "give-up replace updated the main file");
		Expect(std::filesystem::is_directory(bak), "locked bak path is left in place");
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log seed;
		Settings s;
		seed.Configure(s, root);
		seed.buf.character = MakeCharacter(0xABCDu, "Sam");
		seed.Offer(Cap(Kind::Game, "newer file", 20'000));
		Expect(seed.Flush(20'000), "write the first generation");
		seed.Offer(Cap(Kind::Game, "second generation", 40'000));
		Expect(seed.Flush(40'000), "write the newer main file");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		Expect(ReadFile(path).find("second generation") != std::string::npos, "main file is the newer generation");
		Expect(ReadFile(bak).find("newer file") != std::string::npos, "bak holds the older generation");

		auto transientMain = [](const std::filesystem::path& a_p) {
			FileRead rd;
			const auto name = a_p.filename().string();
			if (name.size() < 4 || name.substr(name.size() - 4) != ".bak") {
				rd.ok = false;
				rd.notice = "sharing violation";
				return rd;
			}
			return ReadLogFile(a_p);
		};

		FileStore fs(root / "MessageLog");
		fs.readHook = transientMain;
		LogState st;
		std::string notice;
		Expect(!fs.Load("0000ABCD", st, notice), "transient read fails the load");
		Expect(st.entries.empty(), "transient read does not fall back to bak");
		Expect(notice.find("sharing") != std::string::npos || notice.find("transient") != std::string::npos
			|| notice.find("read") != std::string::npos, "transient notice");

		Log live;
		live.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(live.store.get()))
			p->readHook = transientMain;
		live.buf.character = MakeCharacter(0xABCDu, "Sam");
		live.LoadCurrent();
		Expect(live.persistHold, "HUD load hold after transient");
		Expect(live.buf.entries.empty(), "memory stays empty until the real file loads");
		live.Offer(Cap(Kind::Game, "session only", 80'000));
		Expect(!live.ShouldFlush(100'000, true), "hold blocks a flush");
		Expect(!live.Flush(100'000), "hold does not overwrite the newer file");
		Expect(ReadFile(path).find("second generation") != std::string::npos, "newer main file is left in place");

		Log promo;
		promo.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(promo.store.get()))
			p->readHook = transientMain;
		promo.buf.character = MakeCharacter(0, "Sam");
		promo.Offer(Cap(Kind::Game, "namehash row", 90'000));
		Expect(!promo.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam")), "transient promote retries later");
		Expect(promo.buf.character.keySource == "nameHash", "transient promote keeps name-hash");
		Expect(promo.persistHold, "promote hold after transient");
		Expect(promo.buf.entries.size() == 1 && promo.buf.entries.front().text == "namehash row",
			"transient promote keeps the session in memory");

		int reads = 0;
		auto countFail = [&](const std::filesystem::path&) {
			++reads;
			FileRead rd;
			rd.ok = false;
			rd.notice = "sharing violation";
			return rd;
		};
		Log throttle;
		throttle.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(throttle.store.get()))
			p->readHook = countFail;
		throttle.buf.character = MakeCharacter(0, "Sam");
		throttle.Offer(Cap(Kind::Game, "throttle row", 10'000));
		Expect(!throttle.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 1'000), "first promote reads once");
		ExpectEqI(reads, 1, "first promote does one read");
		Expect(!throttle.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 1'001), "promote is throttled");
		ExpectEqI(reads, 1, "throttled promote does not read again");
		Expect(!throttle.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), throttle.retryAt), "promote retries when due");
		ExpectEqI(reads, 2, "due promote reads once more");

		if (auto* p = dynamic_cast<FileStore*>(live.store.get()))
			p->readHook = nullptr;
		Expect(live.RetryHeld(MakeCharacter(0xABCDu, "Sam"), 200'000, true), "held session merges after the read recovers");
		Expect(!live.persistHold, "recover clears the hold");
		bool gotNewer = false, gotSession = false;
		for (const auto& e : live.buf.entries) {
			if (e.text == "second generation") gotNewer = true;
			if (e.text == "session only") gotSession = true;
		}
		Expect(gotNewer && gotSession, "recover merges the held rows into the file");
		Expect(live.Flush(210'000), "recover then writes");

		Log held;
		held.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(held.store.get()))
			p->readHook = transientMain;
		held.buf.character = MakeCharacter(0, "Sam");
		held.Offer(Cap(Kind::Game, "must survive", 220'000));
		Expect(!held.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 221'000), "quit path tries recover once");
		ExpectEqI(static_cast<int>(held.buf.entries.size()), 1, "held rows survive a failed quit/load attempt");
		Expect(held.buf.entries.front().text == "must survive", "held text is still in memory");
		Expect(held.RetryHeld(MakeCharacter(0xABCDu, "Sam"), 221'000, true) == false, "forced recover still fails");
		Expect(held.buf.entries.front().text == "must survive", "forced recover does not discard held rows");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		std::atomic<bool> stop{false};
		std::atomic<bool> done{false};
		std::mutex mu;
		std::condition_variable cv;
		std::thread th([&] {
			std::unique_lock lk(mu);
			cv.wait(lk, [&] { return stop.load(); });
			done.store(true);
			lk.unlock();
			cv.notify_all();
		});
		stop.store(true);
		cv.notify_all();
		Expect(JoinOrDetach(th, done, cv, mu, kWriterJoinMs), "writer join succeeds when the worker stops");
		Expect(!th.joinable(), "joined thread is not joinable");

		std::atomic<bool> done2{false};
		std::mutex mu2;
		std::condition_variable cv2;
		std::thread stuck([] { std::this_thread::sleep_for(std::chrono::seconds(2)); });
		const auto t0 = std::chrono::steady_clock::now();
		Expect(!JoinOrDetach(stuck, done2, cv2, mu2, 50), "writer join detaches after the bounded wait");
		const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
			std::chrono::steady_clock::now() - t0).count();
		Expect(ms < 400, "timeout detaches instead of joining the stuck worker");
		Expect(!stuck.joinable(), "timed-out worker is detached");
	}

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "message log tests passed\n";
	return 0;
}
