// Unit tests for off-by-default HUD performance diagnostics.
// No game, no CommonLibSF, no thread. Build:
//   g++ -std=c++20 -Wall -Wextra -Wpedantic -I src tests/perf_diag_test.cpp -o /tmp/perf_diag_test
// Author: Moragar. Last modified: 2026-11-08.

#include "hz_perf.h"
#include "hz_version.h"

#include <fstream>
#include <iostream>
#include <sstream>
#include <string>

namespace {

int g_fails = 0;

void Expect(bool a_ok, const char* a_what)
{
	if (a_ok) return;
	std::cerr << "FAIL: " << a_what << "\n";
	++g_fails;
}

std::string Read(const char* a_path)
{
	std::ifstream in(a_path);
	std::ostringstream s;
	s << in.rdbuf();
	return s.str();
}

} // namespace

int main()
{
	Expect(std::string(HZ_FILE_VERSION_STR) == "0.43.1.0", "file version stays 0.43.1.0");
	Expect(HZ_COMMS_MSG_LOG == 0 && HZ_HUD_MSG_CAPTURE == 0, "verbose traces stay off");

	Expect(hzperf::ParseMode("0") == 0 && hzperf::ParseMode("7") == 7, "mode 0-7 parse");
	Expect(hzperf::ParseMode("8") == 0 && hzperf::ParseMode("A") == 0, "invalid mode is off");
	Expect(hzperf::Parse01("1") == 1 && hzperf::Parse01("0") == 0 && hzperf::Parse01("yes") == 0, "01 parse");
	Expect(hzperf::DumpEdge(0, 1) && !hzperf::DumpEdge(1, 1) && !hzperf::DumpEdge(1, 0), "dump is 0->1 only");

	Expect(!hzperf::DiagOn(0), "production diag off");
	Expect(!hzperf::SkipHoverGfx(0) && !hzperf::UseFixture(0), "baseline does not isolate");
	Expect(hzperf::SkipHoverGfx(hzperf::kModeA) && hzperf::SkipScannerDraw(hzperf::kModeA, 1), "A skips hover and scanner GFx");
	Expect(hzperf::UseFixture(hzperf::kModeB) && hzperf::SkipLiveCollect(hzperf::kModeB), "B is fixture-only");
	Expect(hzperf::FixtureLabelOk("HZ PERF FIXTURE DIAGNOSTIC NOT GAME DATA"), "B fixture label");
	Expect(!hzperf::FixtureLabelOk("Crate"), "live names are not the fixture");
	Expect(!hzperf::SkipHoverGfx(hzperf::kModeC) && !hzperf::SkipHoverGfx(hzperf::kModeD) && !hzperf::SkipHoverGfx(hzperf::kModeE),
		"C/D/E keep the live pipeline");
	Expect(!hzperf::SkipScannerDraw(hzperf::kModeF, 1) && hzperf::SkipScannerDraw(hzperf::kModeF, 0), "F follows PerfScan");
	Expect(hzperf::SkipTargetTick(hzperf::kModeG) && hzperf::SkipHoverGfx(hzperf::kModeG), "G is background HUD");

	Expect(hzperf::ParseWaitSec("") == 12 && hzperf::ParseWaitSec("12") == 12, "wait default 12");
	Expect(hzperf::ParseWaitSec("1") == 1 && hzperf::ParseWaitSec("60") == 60, "wait 1 and 60");
	Expect(hzperf::ClampWaitSec(0) == 1 && hzperf::ParseWaitSec("0") == 1, "wait 0 clamps to 1");
	Expect(hzperf::ClampWaitSec(61) == 60 && hzperf::ParseWaitSec("61") == 60, "wait 61 clamps to 60");
	Expect(hzperf::ParseWaitSec("no") == 12 && hzperf::ParseWaitSec("-3") == 12, "junk wait is default");
	Expect(hzperf::WaitUsFromSec(12) == 12000000ull, "12s waitUs");
	Expect(hzperf::HistBucketUs(0) == 1 && hzperf::HistBucketUs(999) == 1, "h1 <1ms");
	Expect(hzperf::HistBucketUs(1000) == 2 && hzperf::HistBucketUs(1999) == 2, "h2 1-2ms");
	Expect(hzperf::HistBucketUs(2000) == 5 && hzperf::HistBucketUs(4999) == 5, "h5 2-5ms");
	Expect(hzperf::HistBucketUs(5000) == 10 && hzperf::HistBucketUs(10000) == 10, "h10 5-10ms");
	Expect(hzperf::HistBucketUs(10001) == 11, "h10p >10ms");

	hzperf::Agg a;
	hzperf::AddMovie(a, 500, 1'000'000);
	hzperf::AddMovie(a, 1500, 1'000'000);
	hzperf::AddMovie(a, 3000, 1'000'000);
	hzperf::AddMovie(a, 7500, 1'000'000);
	hzperf::AddMovie(a, 12000, 1'000'000);
	Expect(a.b[hzperf::kMovieAdvance].calls.load() == 5, "five movie samples");
	Expect(a.h1.load() == 1 && a.h2.load() == 1 && a.h5.load() == 1 && a.h10.load() == 1 && a.h10p.load() == 1,
		"movieAdvance histogram buckets");
	Expect(a.b[hzperf::kMovieAdvance].maxv.load() == 12000, "max ticks");
	Expect(hzperf::Us(1000, 1'000'000) == 1000, "1 MHz: tick is 1 us");
	a.windowStart.store(0);
	a.frames.store(5);
	a.waitUs.store(12000000);
	char line[hzperf::kDumpMax];
	const int n = hzperf::FormatNative(a, 1'000'000, 2'000'000, 1, 3, 1, line, hzperf::kDumpMax);
	Expect(n > 40 && n < hzperf::kDumpMax, "dump fits");
	const std::string dump(line);
	Expect(dump.find("clock=QPC") != std::string::npos, "native clock named");
	auto maxUsAt = [&](const std::string& a_dump, const char* a_bucket) -> unsigned long long {
		const auto b = a_dump.find(std::string(a_bucket) + "={");
		if (b == std::string::npos) return 0;
		const auto brace = a_dump.find('}', b);
		const auto m = a_dump.find("maxUs=", b);
		if (m == std::string::npos || (brace != std::string::npos && m > brace)) return 0;
		const auto start = m + 6;
		const auto end = a_dump.find_first_not_of("0123456789", start);
		if (end == start) return 0;
		return std::stoull(a_dump.substr(start, end - start));
	};
	Expect(maxUsAt(dump, "movieAdvance") == 12000ull, "maxUs is 12000 us at 1 MHz (numeric, not substring)");
	Expect(dump.find("maxUs=3 cps=") == std::string::npos, "dump does not emit a maxUs=3 token for this sample");
	Expect(dump.find("mode=3(C-full)") != std::string::npos, "mode name in dump");
	Expect(dump.find("h1=1") != std::string::npos && dump.find("h2=1") != std::string::npos
		&& dump.find("h5=1") != std::string::npos && dump.find("h10=1") != std::string::npos
		&& dump.find("h10p=1") != std::string::npos, "histogram tokens on dump line");
	Expect(dump.find("waitUs=12000000") != std::string::npos, "waitUs on dump line");
	hzperf::Reset(a);
	Expect(a.b[hzperf::kMovieAdvance].calls.load() == 0 && a.h10p.load() == 0, "reset clears");

	{
		hzperf::Agg lockA;
		hzperf::BeginDump(lockA);
		hzperf::AddMovie(lockA, 5000, 1'000'000);
		Expect(lockA.b[hzperf::kMovieAdvance].calls.load() == 0 && lockA.h10.load() == 0,
			"Format+Reset hold skips concurrent Add");
		hzperf::EndDump(lockA);
		hzperf::AddMovie(lockA, 5000, 1'000'000);
		Expect(lockA.h10.load() == 1, "Add resumes after dump hold");
		hzperf::NoteWindowStart(lockA, 42);
		Expect(lockA.windowStart.load() == 42, "windowStart first-store is CAS");
		hzperf::NoteWindowStart(lockA, 99);
		Expect(lockA.windowStart.load() == 42, "second windowStart store does not win");
	}

	{
		hzperf::DumpCtl c;
		hzperf::ArmDump(c, 12);
		Expect(c.req.load() == 1 && c.windowArmed.load() == 0, "arm sets req, not window");
		Expect(hzperf::OnHudFirstReady(c, false, 1000) == hzperf::ReadyOp::None, "diag off does not reset");
		Expect(hzperf::OnHudFirstReady(c, true, 1000) == hzperf::ReadyOp::ResetWindow, "first ready resets");
		Expect(c.windowArmed.load() == 1 && c.dumpAtMs.load() == 13000, "dump-at is ready+12s");
		Expect(c.skipPoll.load() == 1, "ready poll is excluded from the new window");
		Expect(hzperf::OnHudFirstReady(c, true, 1000) == hzperf::ReadyOp::None, "no re-reset");
		Expect(hzperf::OnHudSafePoll(c, true, true, 5000) == hzperf::DumpOp::Skip, "wait not elapsed");
		Expect(hzperf::OnHudSafePoll(c, false, true, 20000) == hzperf::DumpOp::Skip, "no dump in pause");
		Expect(c.req.load() == 1 && c.windowArmed.load() == 1, "pause does not drop request or latch");
		Expect(hzperf::OnHudFirstReady(c, true, 21000) == hzperf::ReadyOp::None, "re-ready after pause does not re-reset");
		Expect(hzperf::OnHudSafePoll(c, true, true, 21000) == hzperf::DumpOp::Fire, "next HudSafe after elapsed dumps");
		hzperf::ConsumeDump(c);
		Expect(c.req.load() == 0 && hzperf::TakeSkipPoll(c), "dump frame skipPoll");
		Expect(!hzperf::TakeSkipPoll(c), "skipPoll is one-shot");
		Expect(hzperf::OnHudSafePoll(c, true, true, 30000) == hzperf::DumpOp::Skip, "consumed dump does not fire again");
	}

	const auto perfH = Read("src/hz_perf.h");
		Expect(perfH.find("std::thr") == std::string::npos && perfH.find("detach(") == std::string::npos
		&& perfH.find("spdlog") == std::string::npos && perfH.find("ofstream") == std::string::npos,
		"perf header has no worker, spdlog, or file IO");

	const auto main = Read("src/main.cpp");
	Expect(main.find("#include \"hz_perf.h\"") != std::string::npos, "DLL includes hz_perf.h");
	Expect(main.find("if (get(\"debug\", v) && v == \"1\") g_iniDebug = true;") != std::string::npos,
		"Debug=1 remains the overlay gate");
	Expect(main.find("get(\"perfdiag\"") != std::string::npos, "PerfDiag is a separate INI key");
	Expect(main.find("g_iniDebug = hzperf") == std::string::npos, "PerfDiag does not set g_iniDebug");
	Expect(main.find("std::thread") != std::string::npos, "existing message-log thread stays in main.cpp");
	Expect(main.find("MsglogWriter") != std::string::npos && main.find("g_mlWThread") != std::string::npos,
		"no new worker: message-log thread is the existing one");
	Expect(main.find("HzPerfDumpOnce") != std::string::npos, "explicit dump helper");
	Expect(main.find("HzPerfArmWindow") != std::string::npos, "first-ready window arm");
	Expect(main.find("hzPerfSnapshot") != std::string::npos, "AS snapshot Invoke on dump only");
	Expect(main.find("hzPerfReset") != std::string::npos, "AS reset Invoke at first ready");
	Expect(main.find("get(\"perfdumpwait\"") != std::string::npos, "PerfDumpWait is a separate INI key");
	{
		const auto pollSf = main.find("void PollScaleform()");
		const auto armFn = pollSf == std::string::npos ? std::string::npos : main.find("void HzPerfArmWindow()", pollSf);
		const auto dumpFn = pollSf == std::string::npos ? std::string::npos : main.find("void HzPerfDumpOnce()", pollSf);
		const auto pollMsg = main.find("void PollMessages()");
		Expect(pollSf != std::string::npos && armFn != std::string::npos && dumpFn != std::string::npos
			&& pollMsg > dumpFn && dumpFn > armFn && armFn > pollSf,
			"arm and dump helpers sit between PollScaleform and PollMessages");
		const auto dumpCall = pollSf == std::string::npos ? std::string::npos : main.find("try { HzPerfDumpOnce(); } catch (...) {}", pollSf);
		Expect(dumpCall != std::string::npos && dumpCall > pollSf && dumpCall < dumpFn && dumpCall < pollMsg,
			"dump is invoked from PollScaleform, not PollMessages");
		const auto earlyWait = main.find("if (now - g_hudSince < 3000)", pollSf);
		Expect(earlyWait != std::string::npos && dumpCall > earlyWait && dumpCall < armFn,
			"post-pause HudSafe poll can dump before a new 3s stable");
		const auto coverRet = main.find("g_hudSince = 0;", pollSf);
		const auto coverEnd = main.find("const bool hudSafe = HudSafe();", pollSf);
		const auto coverBlk = (coverRet != std::string::npos && coverEnd > coverRet)
			? main.substr(pollSf, coverEnd - pollSf) : std::string();
		Expect(coverBlk.find("g_perfCtl") == std::string::npos && coverBlk.find("HzPerfDumpOnce") == std::string::npos,
			"covering menu does not drop dump latch or dump");
		Expect(main.find("HzPerfNote(hzperf::kInvoke") == std::string::npos, "dump frame does not note invoke into max");
	}

	const auto ini = Read("Interface/HorizonUI/HorizonUI.default.ini");
	Expect(ini.find("PerfDiag=0") != std::string::npos && ini.find("PerfMode=0") != std::string::npos
		&& ini.find("PerfDump=0") != std::string::npos && ini.find("PerfDumpWait=12") != std::string::npos
		&& ini.find("PerfScan=1") != std::string::npos,
		"production defaults");
	Expect(ini.find("NOT GAME DATA") != std::string::npos || ini.find("diagnostic fixture") != std::string::npos,
		"Mode B is documented as diagnostic");

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "ok perf_diag_test\n";
	return 0;
}
