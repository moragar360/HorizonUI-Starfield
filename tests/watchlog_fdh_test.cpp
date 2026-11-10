// watchlog frame-delta histogram (hz_wl.h) host test.
//   zig c++ -std=c++20 -Wall -Wextra -Wpedantic -I src tests/watchlog_fdh_test.cpp -o /tmp/watchlog_fdh_test
// Author: Moragar. Last modified: 2026-11-10.
#include "hz_wl.h"

#include <cmath>
#include <cstdlib>
#include <cstring>
#include <iostream>
#include <string>

static int g_fail = 0;
static void Expect(bool a_ok, const char* a_msg)
{
	if (a_ok) { std::cout << "ok  " << a_msg << "\n"; return; }
	++g_fail;
	std::cout << "FAIL " << a_msg << "\n";
}
static bool Near(double a, double b) { return std::fabs(a - b) < 1e-6; }

int main()
{
	static hzwl::Fdh h;
	// 990 x 20 ms, 9 x 40 ms, 1 x 250 ms (the director's ONE_PERCENT_LOWS case)
	for (int i = 0; i < 990; ++i) hzwl::FdhAddUs(h, 20000);
	for (int i = 0; i < 9; ++i) hzwl::FdhAddUs(h, 40000);
	hzwl::FdhAddUs(h, 250000);
	const auto s = hzwl::FdhCompute(h);
	Expect(s.n == 1000, "n counts every frame");
	Expect(Near(s.p50Ms, 21) && Near(s.p95Ms, 21) && Near(s.p99Ms, 21), "p50 = p95 = p99 = 21 (nearest rank, bin upper edge)");
	Expect(Near(s.p999Ms, 41), "p99.9 = 41 (the 999th frame is a 40 ms frame)");
	Expect(Near(s.low1Ms, 61.45), "1% low = mean of the worst 10 = (250 + 9 x 40.5) / 10 = 61.45 ms");
	Expect(Near(s.low01Ms, 250), "0.1% low = the worst 1 frame, exact from the overflow sum");
	Expect(s.c33 == 10 && s.c50 == 1 && s.c100 == 1, "c33 = 10, c50 = 1, c100 = 1");
	Expect(std::fabs(s.avgFps - 1000.0 * 1000000.0 / (990 * 20000.0 + 9 * 40000.0 + 250000.0)) < 1e-9, "avg fps = frames / summed frame time");
	Expect(Near(s.maxMs, 250), "max is exact");
	char line[hzwl::kLineMax * 2];
	const int n = hzwl::FdhFormat(h, line, static_cast<int>(sizeof(line)), "perf ft");
	const std::string L(line, static_cast<std::size_t>(n));
	Expect(L.rfind("perf ft n=1000 avgFps=", 0) == 0 && L.find(" p99Ms=21 p999Ms=41 low1Ms=61.5 ") != std::string::npos && L.find("tail=40:9,200+:1") != std::string::npos,
		"line: tag, fields and the tail bins");
	// 33 ms boundary: bins are whole ms, 33.000 and 33.999 both land in bin 33 (counted in c33), 32.999 does not
	static hzwl::Fdh b;
	hzwl::FdhAddUs(b, 32999);
	hzwl::FdhAddUs(b, 33000);
	hzwl::FdhAddUs(b, 33999);
	Expect(hzwl::FdhCompute(b).c33 == 2, "c33 boundary: 33.000 ms counts, 32.999 ms does not");
	// QPC path: deltas between starts; the first start only sets 'last'
	static hzwl::Fdh q;
	hzwl::FdhAdd(q, 1000, 1000000);
	hzwl::FdhAdd(q, 17667, 1000000);
	hzwl::FdhAdd(q, 17667, 1000000);   // equal start: ignored
	Expect(hzwl::FdhCompute(q).n == 1 && q.b[16].load() == 1, "QPC deltas: first start sets the base, equal starts are ignored");
	hzwl::FdhReset(q, true);
	hzwl::FdhAdd(q, 34000, 1000000);
	Expect(hzwl::FdhCompute(q).n == 1 && q.b[16].load() == 1, "reset keeping last: the first frame of the next window is not lost");
	hzwl::FdhReset(q, false);
	hzwl::FdhAdd(q, 50000, 1000000);
	Expect(hzwl::FdhCompute(q).n == 0, "full reset: the next start only sets the base");
	static hzwl::Fdh e;
	const auto z = hzwl::FdhCompute(e);
	Expect(z.n == 0 && z.avgFps == 0 && z.low1Ms == 0, "empty window: all zero, no divide by zero");
	char md[256];
	hzwl::MaskDiff(0u, 1u | (1u << 13), md, static_cast<int>(sizeof(md)));
	Expect(std::string(md) == "+MonocleMenu +HUDMenu ", "menu mask diff names the opened menus");
	hzwl::MaskDiff(1u, 0u, md, static_cast<int>(sizeof(md)));
	Expect(std::string(md) == "-MonocleMenu ", "menu mask diff names the closed menus");
	Expect(hzwl::kMenuCount == 14 && hzwl::kMenuCount <= 32, "menu list fits one 32-bit mask");
	if (g_fail) { std::cout << g_fail << " FAILED\n"; return 1; }
	std::cout << "ok watchlog_fdh_test\n";
	return 0;
}
