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

	hzperf::Agg a;
	hzperf::Add(a.b[hzperf::kMovieAdvance], 1000);
	hzperf::Add(a.b[hzperf::kMovieAdvance], 3000);
	Expect(a.b[hzperf::kMovieAdvance].calls.load() == 2, "two samples");
	Expect(a.b[hzperf::kMovieAdvance].maxv.load() == 3000, "max ticks");
	Expect(hzperf::Us(1000, 1'000'000) == 1000, "1 MHz: tick is 1 us");
	a.windowStart.store(0);
	a.frames.store(2);
	char line[hzperf::kDumpMax];
	const int n = hzperf::FormatNative(a, 1'000'000, 2'000'000, 1, 3, 1, line, hzperf::kDumpMax);
	Expect(n > 40 && n < hzperf::kDumpMax, "dump fits");
	const std::string dump(line);
	Expect(dump.find("clock=QPC") != std::string::npos, "native clock named");
	Expect(dump.find("movieAdvance=") != std::string::npos && dump.find("maxUs=3") != std::string::npos, "advance bucket");
	Expect(dump.find("mode=3(C-full)") != std::string::npos, "mode name in dump");
	hzperf::Reset(a);
	Expect(a.b[hzperf::kMovieAdvance].calls.load() == 0, "reset clears");

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
	Expect(main.find("hzPerfSnapshot") != std::string::npos, "AS snapshot Invoke on dump only");
	{
		const auto pollSf = main.find("void PollScaleform()");
		const auto dumpFn = pollSf == std::string::npos ? std::string::npos : main.find("void HzPerfDumpOnce()", pollSf);
		const auto pollMsg = main.find("void PollMessages()");
		Expect(pollSf != std::string::npos && dumpFn != std::string::npos && pollMsg > dumpFn && dumpFn > pollSf,
			"dump helper sits between PollScaleform and PollMessages");
		const auto dumpCall = pollSf == std::string::npos ? std::string::npos : main.find("try { HzPerfDumpOnce(); } catch (...) {}", pollSf);
		Expect(dumpCall != std::string::npos && dumpCall > pollSf && dumpCall < dumpFn && dumpCall < pollMsg,
			"dump is invoked from PollScaleform, not PollMessages");
	}

	const auto ini = Read("Interface/HorizonUI/HorizonUI.default.ini");
	Expect(ini.find("PerfDiag=0") != std::string::npos && ini.find("PerfMode=0") != std::string::npos
		&& ini.find("PerfDump=0") != std::string::npos && ini.find("PerfScan=1") != std::string::npos,
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
