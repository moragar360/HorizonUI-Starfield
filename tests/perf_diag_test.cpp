// Unit tests for off-by-default HUD performance diagnostics.
// No game, no CommonLibSF, no thread. Build:
//   g++ -std=c++20 -Wall -Wextra -Wpedantic -I src tests/perf_diag_test.cpp -o /tmp/perf_diag_test
// Author: Moragar. Last modified: 2026-11-09.

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
	Expect(hzperf::ParseSettleMs("") == 2000 && hzperf::ParseSettleMs("2000") == 2000, "settle default 2000");
	Expect(hzperf::ClampSettleMs(0) == 0 && hzperf::ParseSettleMs("0") == 0, "settle 0 allowed");
	Expect(hzperf::ClampSettleMs(10000) == 10000 && hzperf::ParseSettleMs("10000") == 10000, "settle 10000");
	Expect(hzperf::ClampSettleMs(10001) == 10000 && hzperf::ParseSettleMs("10001") == 10000, "settle clamps to 10000");
	Expect(hzperf::ParseSettleMs("no") == 2000, "junk settle is default");
	Expect(hzperf::kIntroPendingMaxMs == 15000, "pending intro timeout is 15s after ready");
	Expect(hzperf::kDumpAsMax == 1400 && hzperf::kDumpMax == 1400, "native and AS dump parts are 1400");
	Expect(hzperf::HistBucketUs(0) == 1 && hzperf::HistBucketUs(999) == 1, "h1 <1ms");
	Expect(hzperf::HistBucketUs(1000) == 2 && hzperf::HistBucketUs(1999) == 2, "h2 1-2ms");
	Expect(hzperf::HistBucketUs(2000) == 5 && hzperf::HistBucketUs(4999) == 5, "h5 2-5ms");
	Expect(hzperf::HistBucketUs(5000) == 10 && hzperf::HistBucketUs(10000) == 10, "h10 5-10ms");
	Expect(hzperf::HistBucketUs(10001) == 11, "h10p >10ms");

	hzperf::Agg a;
	hzperf::AddRoot(a, 500, 1'000'000, true);
	hzperf::AddRoot(a, 1500, 1'000'000, true);
	hzperf::AddRoot(a, 3000, 1'000'000, false);
	hzperf::AddRoot(a, 7500, 1'000'000, false);
	hzperf::AddRoot(a, 12000, 1'000'000, true);
	Expect(a.b[hzperf::kMovieAdvance].calls.load() == 5, "five movie samples combined");
	Expect(a.rootT.calls.load() == 3 && a.rootF.calls.load() == 2, "true/false call split");
	Expect(a.hist.h1.load() == 1 && a.hist.h2.load() == 1 && a.hist.h5.load() == 1 && a.hist.h10.load() == 1
		&& a.hist.h10p.load() == 1, "combined histogram buckets");
	Expect(a.histT.h1.load() == 1 && a.histT.h2.load() == 1 && a.histT.h10p.load() == 1, "true hist buckets");
	Expect(a.histF.h5.load() == 1 && a.histF.h10.load() == 1, "false hist buckets");
	Expect(a.histT.h1.load() + a.histF.h1.load() == a.hist.h1.load(), "h1 T+F sums to combined");
	Expect(a.histT.h2.load() + a.histF.h2.load() == a.hist.h2.load(), "h2 T+F sums to combined");
	Expect(a.histT.h5.load() + a.histF.h5.load() == a.hist.h5.load(), "h5 T+F sums to combined");
	Expect(a.histT.h10.load() + a.histF.h10.load() == a.hist.h10.load(), "h10 T+F sums to combined");
	Expect(a.histT.h10p.load() + a.histF.h10p.load() == a.hist.h10p.load(), "h10p T+F sums to combined");
	Expect(a.rootT.maxv.load() == 12000 && a.rootF.maxv.load() == 7500, "true/false max split");
	Expect(hzperf::Us(1000, 1'000'000) == 1000, "1 MHz: tick is 1 us");
	a.windowStart.store(0);
	a.frames.store(5);
	a.waitUs.store(12000000);
	a.settleMs.store(2000);
	a.armKind.store(hzperf::kArmSkip);
	char line[hzperf::kDumpMax];
	const int n = hzperf::FormatNative(a, 1'000'000, 2'000'000, 1, 3, 1, line, hzperf::kDumpMax);
	Expect(n > 40 && n < hzperf::kDumpMax, "dump fits");
	Expect(n <= hzperf::kDumpMax - 1, "dump is bounded");
	const std::string dump(line);
	Expect(dump.find("clock=QPC") != std::string::npos, "native clock named");
	Expect(dump.find("scope=asRootMaint") != std::string::npos, "narrow root-maintenance scope");
	Expect(dump.find("rootT=") != std::string::npos && dump.find("rootF=") != std::string::npos, "true/false dump fields");
	Expect(dump.find("settleMs=2000") != std::string::npos && dump.find("arm=skip") != std::string::npos,
		"settle and arm tokens");
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
	{
		char tiny[16];
		const int tn = hzperf::FormatNative(a, 1'000'000, 2'000'000, 1, 3, 1, tiny, 16);
		Expect(tn >= 0 && tn < 16 && tiny[tn] == 0, "tiny dump stays bounded and NUL-terminated");
	}
	hzperf::Reset(a);
	Expect(a.b[hzperf::kMovieAdvance].calls.load() == 0 && a.hist.h10p.load() == 0 && a.rootT.calls.load() == 0,
		"reset clears");

	{
		hzperf::Agg lockA;
		hzperf::BeginDump(lockA);
		hzperf::AddMovie(lockA, 5000, 1'000'000);
		Expect(lockA.b[hzperf::kMovieAdvance].calls.load() == 0 && lockA.hist.h10.load() == 0,
			"Format+Reset hold skips concurrent Add");
		hzperf::EndDump(lockA);
		hzperf::AddMovie(lockA, 5000, 1'000'000);
		Expect(lockA.hist.h10.load() == 1, "Add resumes after dump hold");
		hzperf::NoteWindowStart(lockA, 42);
		Expect(lockA.windowStart.load() == 42, "windowStart first-store is CAS");
		hzperf::NoteWindowStart(lockA, 99);
		Expect(lockA.windowStart.load() == 42, "second windowStart store does not win");
	}

	{
		Expect(hzperf::ArmAtMs(0, 0, false, 1000, 2000) == 0, "no ready means not yet");
		Expect(hzperf::ArmAtMs(11000, 8000, false, 11000, 2000) == 13000, "intro before ready: ready+settle");
		Expect(hzperf::ArmAtMs(11000, 14000, false, 14000, 2000) == 16000, "intro after ready: intro+settle");
		Expect(hzperf::ArmAtMs(11000, 0, true, 11000, 2000) == 0, "pending intro does not arm");
		Expect(hzperf::ArmAtMs(11000, 0, false, 11000, 2000) == 13000, "noarm uses ready+settle");
		Expect(hzperf::ArmAtMs(11000, 0, false, 15000, 2000) == 13000, "noarm stays on HUD-ready, not now");
		Expect(hzperf::ArmAtMs(11000, 0, true, 25000, 2000) == 0, "pending still blocked before intro timeout");
		Expect(hzperf::ArmAtMs(11000, 0, true, 26000, 2000) == 13000, "pending intro timeout falls back to HUD-ready");
		Expect(hzperf::ArmAtMs(11000, 8000, false, 11000, 0) == 11000, "settle 0");
		Expect(hzperf::PickArmKind(11000, 8000, hzperf::kArmIntro) == hzperf::kArmReady, "ready after intro");
		Expect(hzperf::PickArmKind(11000, 14000, hzperf::kArmSkip) == hzperf::kArmSkip, "intro-exit kind when intro later");
		Expect(hzperf::PickArmKind(11000, 0, 0) == hzperf::kArmNoarm, "noarm");
	}
	{
		hzperf::DumpCtl c;
		hzperf::ArmDump(c, 12, 2000);
		Expect(c.req.load() == 1 && c.windowArmed.load() == 0, "arm sets req, not window");
		Expect(hzperf::OnHudArmPoll(c, false, 13000, 8000, false, hzperf::kArmIntro) == hzperf::ReadyOp::None,
			"diag off does not reset");
		hzperf::NoteHudReady(c, 11000);
		Expect(hzperf::OnHudArmPoll(c, true, 12000, 8000, false, hzperf::kArmIntro) == hzperf::ReadyOp::None,
			"settle not elapsed");
		Expect(hzperf::OnHudArmPoll(c, true, 13000, 8000, false, hzperf::kArmIntro) == hzperf::ReadyOp::ResetWindow,
			"ready+settle arms");
		Expect(c.windowArmed.load() == 1 && c.dumpAtMs.load() == 25000, "dump-at is arm+12s");
		Expect(c.armKind.load() == hzperf::kArmReady, "arm=ready when intro first");
		Expect(c.skipPoll.load() == 1, "arm poll is excluded from the new window");
		Expect(hzperf::OnHudArmPoll(c, true, 13000, 8000, false, hzperf::kArmIntro) == hzperf::ReadyOp::None, "no re-reset");
		Expect(hzperf::OnHudSafePoll(c, true, true, 20000) == hzperf::DumpOp::Skip, "wait not elapsed");
		Expect(hzperf::OnHudSafePoll(c, false, true, 30000) == hzperf::DumpOp::Skip, "no dump in pause");
		Expect(c.req.load() == 1 && c.windowArmed.load() == 1, "pause does not drop request or latch");
		Expect(hzperf::OnHudArmPoll(c, true, 30000, 8000, false, hzperf::kArmIntro) == hzperf::ReadyOp::None,
			"re-ready after pause does not re-reset");
		Expect(hzperf::OnHudSafePoll(c, true, true, 25000) == hzperf::DumpOp::Fire, "next HudSafe after elapsed dumps");
		hzperf::ConsumeDump(c);
		Expect(c.req.load() == 0 && hzperf::TakeSkipPoll(c), "dump frame skipPoll");
		Expect(!hzperf::TakeSkipPoll(c), "skipPoll is one-shot");
		Expect(hzperf::OnHudSafePoll(c, true, true, 40000) == hzperf::DumpOp::Skip, "consumed dump does not fire again");
		hzperf::DumpCtl off;
		hzperf::ArmDump(off, 12, 2000);
		off.windowArmed.store(1);
		off.dumpAtMs.store(1);
		Expect(hzperf::OnHudSafePoll(off, true, false, 99999) == hzperf::DumpOp::Skip, "diag off bypasses dump");
	}
	{
		hzperf::DumpCtl c;
		hzperf::ArmDump(c, 12, 2000);
		hzperf::NoteHudReady(c, 11000);
		Expect(hzperf::OnHudArmPoll(c, true, 20000, 0, true, 0) == hzperf::ReadyOp::None, "pending intro blocks arm");
		Expect(hzperf::OnHudArmPoll(c, true, 16000, 14000, false, hzperf::kArmTimeout) == hzperf::ReadyOp::ResetWindow,
			"timeout intro after ready arms");
		Expect(c.armKind.load() == hzperf::kArmTimeout, "arm=timeout");
		hzperf::UnarmWindow(c);
		Expect(c.windowArmed.load() == 0 && c.req.load() == 1 && c.readyMs.load() == 0, "unarm keeps req");
		hzperf::NoteHudReady(c, 30000);
		Expect(hzperf::OnHudArmPoll(c, true, 33000, 31000, false, hzperf::kArmSkip) == hzperf::ReadyOp::ResetWindow,
			"re-arm after load/root");
		Expect(c.armKind.load() == hzperf::kArmSkip, "re-arm records skip");
	}
	{
		for (int kind : {hzperf::kArmIntro, hzperf::kArmSkip, hzperf::kArmTimeout, hzperf::kArmExhausted, hzperf::kArmNoarm}) {
			hzperf::DumpCtl c;
			hzperf::ArmDump(c, 12, 2000);
			hzperf::NoteHudReady(c, 5000);
			const std::uint64_t introMs = (kind == hzperf::kArmNoarm) ? 0 : 6000;
			const std::uint64_t now = introMs ? 8000 : 7000;
			Expect(hzperf::OnHudArmPoll(c, true, now, introMs, false, kind) == hzperf::ReadyOp::ResetWindow,
				"every intro exit can arm at settle 2000");
		}
	}
	{
		hzperf::DumpCtl c;
		hzperf::ArmDump(c, 12, 2000);
		hzperf::NoteHudReady(c, 11000);
		Expect(hzperf::OnHudArmPoll(c, true, 20000, 0, true, 0) == hzperf::ReadyOp::None,
			"pending intro still blocks before 15s timeout");
		Expect(hzperf::OnHudArmPoll(c, true, 26000, 0, true, 0) == hzperf::ReadyOp::ResetWindow,
			"pending intro timeout arms from HUD-ready");
		Expect(c.armKind.load() == hzperf::kArmNoarm, "timeout-pending arm is noarm");
	}
	{
		hzperf::DumpCtl c;
		hzperf::NoteCovered(c);
		Expect(hzperf::TakePostCover(c) && !hzperf::TakePostCover(c), "post-cover skip is one frame");
	}
	{
		hzperf::DumpCtl c;
		hzperf::ArmDump(c, 12, 2000);
		hzperf::NoteHudReady(c, 11000);
		Expect(hzperf::OnHudArmPoll(c, true, 13000, 8000, false, hzperf::kArmIntro) == hzperf::ReadyOp::ResetWindow,
			"arm records epoch");
		Expect(hzperf::EpochMatches(c), "arm epoch matches");
		c.epoch.fetch_add(1, std::memory_order_relaxed);
		Expect(!hzperf::EpochMatches(c), "save-load epoch bump mismatches");
		Expect(hzperf::OnHudSafePoll(c, true, true, 30000) == hzperf::DumpOp::Skip, "epoch mismatch does not dump");
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
	Expect(main.find("get(\"perfsettlems\"") != std::string::npos, "PerfSettleMs is a separate INI key");
	Expect(main.find("HzPerfNoteRoot(tAdv0, a_next)") != std::string::npos, "hook splits a_next");
	Expect(main.find("HzIntroResolved") != std::string::npos, "intro exits latch");
	Expect(main.find("UnarmWindow") != std::string::npos, "load/root unarm the window");
	Expect(perfH.find("class FunctionHandler") == std::string::npos && perfH.find("CreateFunction(") == std::string::npos,
		"no FunctionHandler/CreateFunction types in perf header");
	Expect(main.find("void HzPerfMark") == std::string::npos && main.find("HzPerfDoActions") == std::string::npos,
		"no QPC marker helpers");
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
		Expect(coverBlk.find("HzPerfDumpOnce") == std::string::npos && coverBlk.find("ConsumeDump") == std::string::npos,
			"covering menu does not dump");
		Expect(coverBlk.find("req.store") == std::string::npos, "covering menu does not drop dump request");
		Expect(main.find("NoteCovered") != std::string::npos && main.find("TakePostCover") != std::string::npos,
			"pause requires a post-cover frame before arm/dump");
		Expect(main.find("if (HzPerfOn())") != std::string::npos
			&& main.find("hzperf::NoteHudReady") != std::string::npos,
			"HUD-ready CAS is gated on PerfDiag");
		Expect(main.find("fromNullHud") != std::string::npos, "adopting a HUD root from null un-arms");
		Expect(main.find("kDumpAsMax") != std::string::npos, "AS dump part uses kDumpAsMax");
		Expect(main.find("HzPerfNote(hzperf::kInvoke") == std::string::npos, "dump frame does not note invoke into max");
	}

	const auto ini = Read("Interface/HorizonUI/HorizonUI.default.ini");
	Expect(ini.find("PerfDiag=0") != std::string::npos && ini.find("PerfMode=0") != std::string::npos
		&& ini.find("PerfDump=0") != std::string::npos && ini.find("PerfDumpWait=12") != std::string::npos
		&& ini.find("PerfSettleMs=2000") != std::string::npos && ini.find("PerfScan=1") != std::string::npos,
		"production defaults");
	Expect(ini.find("NOT GAME DATA") != std::string::npos || ini.find("diagnostic fixture") != std::string::npos,
		"Mode B is documented as diagnostic");

	// ---- Option B: native spike / process-memory rings and the merged ring ----
	{
		static hzperf::Agg a{};
		hzperf::Reset(a);
		const std::uint64_t f = 1000000;  // 1 tick = 1 us
		a.windowStart.store(1000000, std::memory_order_relaxed);
		hzperf::NoteSpike(a, 1100000, 4999, f, true);
		Expect(hzperf::RingCount(a.spike) == 0, "rootT under 5 ms is not a spike");
		hzperf::NoteSpike(a, 1200000, 7000, f, false);
		Expect(hzperf::RingCount(a.spike) == 0, "rootF is not in the spike ring");
		hzperf::NoteSpike(a, 1300000, 5000, f, true);
		Expect(hzperf::RingCount(a.spike) == 1 && a.spike.q[0] == 1300000 && a.spike.v[0] == 5000,
			"rootT of 5 ms is stamped with the hook QPC start");
		for (int i = 0; i < 300; ++i)
			hzperf::NoteSpike(a, 1400000 + static_cast<std::uint64_t>(i), 6000, f, true);
		Expect(hzperf::RingCount(a.spike) == 256 && hzperf::RingLost(a.spike) == 45, "spike ring keeps 256, counts lost");
		hzperf::NoteProcMem(a, 1500000, 100ull << 20);
		hzperf::NoteProcMem(a, 1500100, (100ull << 20) - 200 * 1024);
		Expect(a.pmemDrops.load() == 0, "a 200 KB fall is not a drop");
		hzperf::NoteProcMem(a, 1500200, (100ull << 20) - 2048 * 1024);
		Expect(a.pmemDrops.load() == 1 && hzperf::RingCount(a.pdrop) == 1 && a.pdrop.v[0] == 1848,
			"a fall over 256 KB is a drop in KB");
		Expect(a.pmemMin.load() == (100ull << 20) - 2048 * 1024 && a.pmemMax.load() == (100ull << 20) && a.pmemN.load() == 3,
			"process memory min/max/count");
		a.dumping.store(1);
		hzperf::NoteSpike(a, 1600000, 9000, f, true);
		Expect(hzperf::RingLost(a.spike) == 45, "no ring write while dumping");
		a.dumping.store(0);

		static hzperf::RingEv ev[hzperf::kRingEvMax];
		hzperf::Reset(a);
		a.windowStart.store(1000000, std::memory_order_relaxed);
		hzperf::NoteSpike(a, 1050000, 8000, f, true);  // 50 ms into the window
		int n = hzperf::CollectNative(a, f, ev, hzperf::kRingEvMax);
		Expect(n == 1 && ev[0].type == 'R' && ev[0].src == 'N' && ev[0].tMs > 49.9 && ev[0].tMs < 50.1, "native R at window ms");
		hzperf::AsRingHead h{};
		const char* asRing = "ring now=5000 n=3 lost=2 memUnsupported=1|2,4040,4090,3,6;1,4048,4048,0,1;3,4049,4049,700,1;4,999";
		const int an = hzperf::ParseAsRing(asRing, 0, 0, ev + n, hzperf::kRingEvMax - n, h);
		Expect(h.ok == 1 && h.now == 5000 && h.n == 3 && h.lost == 2 && h.memUnsupported == 1, "AS ring header");
		Expect(an == 3, "AS ring parses whole slots and drops a truncated tail");
		// QPC ms at invoke 1960 -> offset = 1960 - 5000; window start = 1000 ms.
		const double off = hzperf::QpcMs(1960000, f) - h.now;
		for (int i = n; i < n + an; ++i) ev[i].tMs += off - hzperf::QpcMs(1000000, f);
		n += an;
		hzperf::SortRing(ev, n);
		Expect(ev[0].type == 'C' && ev[0].n == 6 && ev[0].spanMs == 50 && ev[0].tMs == 0, "C run starts at window ms 0");
		Expect(ev[1].type == 'T' && ev[2].type == 'M' && ev[3].type == 'R', "merged events sort by shared clock");
		char line[hzperf::kRingLineMax];
		hzperf::FormatRingEv(ev[0], line, hzperf::kRingLineMax);
		Expect(std::string(line) == "perf ring t=0.0 src=AS type=C v=3ms n=6 span=50", "C line format");
		hzperf::FormatRingEv(ev[3], line, hzperf::kRingLineMax);
		Expect(std::string(line) == "perf ring t=50.0 src=N type=R v=8000us", "R line format");
		char sum[hzperf::kDumpMax];
		hzperf::FormatRingSum(a, h, off, n, sum, hzperf::kDumpMax);
		Expect(std::string(sum).find("perf ring sum events=4 spikes=1 spikeLost=0") == 0
			&& std::string(sum).find("memUnsupported=1") != std::string::npos, "ring summary fields");
		Expect(std::string(sum).find("timerUnsupported=-1") != std::string::npos, "an old AS ring without the field reads -1");
		{
			hzperf::AsRingHead h2{};
			hzperf::ParseAsRing("ring now=1 n=0 lost=0 memUnsupported=0 timerUnsupported=1|", 0, 0, ev, 4, h2);
			char sum2[hzperf::kDumpMax];
			hzperf::FormatRingSum(a, h2, 0, 0, sum2, hzperf::kDumpMax);
			Expect(h2.ok == 1 && h2.timerUnsupported == 1 && std::string(sum2).find("timerUnsupported=1") != std::string::npos,
				"S1: timerUnsupported reaches the ring summary");
		}
		Expect(hzperf::ParseAsRing("ring diag=0", 0, 0, ev, 4, h) == 0 && h.ok == 0, "diag-off AS ring is ignored");
		Expect(hzperf::ParseAsRing(nullptr, 0, 0, ev, 4, h) == 0, "missing AS ring is safe");
		hzperf::Reset(a);
		Expect(hzperf::RingCount(a.spike) == 0 && hzperf::RingCount(a.pdrop) == 0 && a.pmemN.load() == 0, "Reset clears rings");
	}
	{
		const auto mainB = Read("src/main.cpp");
		Expect(mainB.find("hzperf::NoteSpike(g_perfAgg, a_t0, t1 - a_t0, HzQpcFreq(), a_next);") != std::string::npos,
			"spike ring is fed from the existing hook QPC");
		Expect(mainB.find("HudInvoke(\"hzPerfRing\"") < mainB.find("HudInvoke(\"hzPerfSnapshot\""),
			"AS ring is read before the snapshot resets it");
	}

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "ok perf_diag_test\n";
	return 0;
}
