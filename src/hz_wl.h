#pragma once
// hz_wl.h: watchlog, a private diagnostic (default off). Active only with [Debug] PerfDiag=1 and WatchLog=1.
// What the native side owns:
//  - Fdh: a fixed frame-delta histogram. One sample per HUD AdvanceFrame, start to start (the same cadence as
//    the perf gap ring, i.e. the game frame). 1 ms bins from 0 to 199 ms, plus an overflow bin with an exact
//    sum. At each watchlog window close, FdhFormat prints the average fps, p50, p99 (nearest rank, bin upper
//    edge), p95, p99.9 and the 1% and 0.1% lows (the mean of the worst ceil(n/100) and ceil(n/1000) frames; bin
//    midpoints, overflow at its exact mean). The same type also backs the "perf ft" line of the PerfDiag dump.
//    No allocation. Fixed storage. Relaxed atomics, because add and format both run on the HUD advance path.
//  - Menu context: a fixed list of menu names whose open state is packed into one mask (WlMenuMask in main.cpp).
// No disk I/O here: the caller logs the formatted line at window close (every 20 s or on the hotkey).
// Author: Moragar. Last modified: 2026-11-10.

#include <atomic>
#include <cstdint>
#include <cstdio>

namespace hzwl {

inline constexpr int kFdhBins = 200;           // 1 ms bins, 0..199 ms
inline constexpr int kWindowMs = 20000;        // window length (a hotkey press also closes one)
inline constexpr int kFlushMs = 5000;          // entry flush period (only when entries are queued)
inline constexpr int kLineMax = 768;
inline constexpr int kFlushMax = 65536;        // one flush is capped at this many chars

struct Fdh {
	std::atomic<std::uint32_t> b[kFdhBins];
	std::atomic<std::uint64_t> n{0};
	std::atomic<std::uint64_t> sumUs{0};
	std::atomic<std::uint64_t> maxUs{0};
	std::atomic<std::uint64_t> overN{0};
	std::atomic<std::uint64_t> overSumUs{0};
	std::atomic<std::uint64_t> last{0};      // QPC start of the previous advance (0: none yet)
	Fdh() { for (auto& x : b) x.store(0, std::memory_order_relaxed); }
};

// Clears the counts. Keeps 'last' when a_keepLast, so the first frame of the next window is not lost.
inline void FdhReset(Fdh& a_h, bool a_keepLast)
{
	for (auto& x : a_h.b) x.store(0, std::memory_order_relaxed);
	a_h.n.store(0, std::memory_order_relaxed);
	a_h.sumUs.store(0, std::memory_order_relaxed);
	a_h.maxUs.store(0, std::memory_order_relaxed);
	a_h.overN.store(0, std::memory_order_relaxed);
	a_h.overSumUs.store(0, std::memory_order_relaxed);
	if (!a_keepLast) a_h.last.store(0, std::memory_order_relaxed);
}

inline void FdhAddUs(Fdh& a_h, std::uint64_t a_us)
{
	a_h.n.fetch_add(1, std::memory_order_relaxed);
	a_h.sumUs.fetch_add(a_us, std::memory_order_relaxed);
	if (a_us > a_h.maxUs.load(std::memory_order_relaxed)) a_h.maxUs.store(a_us, std::memory_order_relaxed);
	const std::uint64_t ms = a_us / 1000;
	if (ms >= static_cast<std::uint64_t>(kFdhBins)) {
		a_h.overN.fetch_add(1, std::memory_order_relaxed);
		a_h.overSumUs.fetch_add(a_us, std::memory_order_relaxed);
	} else {
		a_h.b[ms].fetch_add(1, std::memory_order_relaxed);
	}
}

// One HUD advance start (QPC ticks). The delta to the previous start is one frame time.
inline void FdhAdd(Fdh& a_h, std::uint64_t a_t0, std::uint64_t a_freq)
{
	const auto last = a_h.last.load(std::memory_order_relaxed);
	a_h.last.store(a_t0, std::memory_order_relaxed);
	if (!last || !a_freq || a_t0 <= last) return;
	FdhAddUs(a_h, ((a_t0 - last) * 1000000ull) / a_freq);
}

struct FdhStats {
	std::uint64_t n = 0;
	double avgFps = 0;
	double p50Ms = 0;
	double p95Ms = 0;
	double p99Ms = 0;
	double p999Ms = 0;
	double low1Ms = 0;     // mean of the worst ceil(n/100) frames
	double low1Fps = 0;
	double low01Ms = 0;    // mean of the worst ceil(n/1000) frames
	double maxMs = 0;
	std::uint64_t c33 = 0; // frames of 33 ms or more
	std::uint64_t c50 = 0; // 50 ms or more (the perf ring's G threshold)
	std::uint64_t c100 = 0;
};

// Nearest-rank percentile over the bins: the smallest bin whose cumulative count reaches ceil(p * n).
// Reported as the bin's upper edge (k + 1 ms); the overflow bin reports its exact mean.
inline FdhStats FdhCompute(const Fdh& a_h)
{
	FdhStats s{};
	s.n = a_h.n.load(std::memory_order_relaxed);
	if (!s.n) return s;
	const auto sum = a_h.sumUs.load(std::memory_order_relaxed);
	const auto overN = a_h.overN.load(std::memory_order_relaxed);
	const auto overSum = a_h.overSumUs.load(std::memory_order_relaxed);
	const double overMean = overN ? static_cast<double>(overSum) / static_cast<double>(overN) / 1000.0 : 0;
	s.avgFps = sum ? static_cast<double>(s.n) * 1000000.0 / static_cast<double>(sum) : 0;
	s.maxMs = static_cast<double>(a_h.maxUs.load(std::memory_order_relaxed)) / 1000.0;
	auto rankMs = [&](std::uint64_t a_rank) {
		std::uint64_t c = 0;
		for (int k = 0; k < kFdhBins; ++k) {
			c += a_h.b[k].load(std::memory_order_relaxed);
			if (c >= a_rank) return static_cast<double>(k + 1);
		}
		return overMean;
	};
	s.p50Ms = rankMs((s.n * 50 + 99) / 100);
	s.p95Ms = rankMs((s.n * 95 + 99) / 100);
	s.p99Ms = rankMs((s.n * 99 + 99) / 100);
	s.p999Ms = rankMs((s.n * 999 + 999) / 1000);
	// mean of the worst a_want frames, from the top: overflow first (exact mean), then bins at their midpoints
	auto worstMean = [&](std::uint64_t a_want) {
		double acc = 0;
		std::uint64_t got = 0;
		if (overN) {
			const auto take = overN < a_want ? overN : a_want;
			acc += overMean * static_cast<double>(take);
			got += take;
		}
		for (int k = kFdhBins - 1; k >= 0 && got < a_want; --k) {
			const std::uint64_t c = a_h.b[k].load(std::memory_order_relaxed);
			if (!c) continue;
			const auto take = c < (a_want - got) ? c : (a_want - got);
			acc += (static_cast<double>(k) + 0.5) * static_cast<double>(take);
			got += take;
		}
		return got ? acc / static_cast<double>(got) : 0.0;
	};
	s.low1Ms = worstMean((s.n + 99) / 100);
	s.low1Fps = s.low1Ms > 0 ? 1000.0 / s.low1Ms : 0;
	s.low01Ms = worstMean((s.n + 999) / 1000);
	for (int k = 33; k < kFdhBins; ++k) {
		const std::uint64_t c = a_h.b[k].load(std::memory_order_relaxed);
		s.c33 += c;
		if (k >= 50) s.c50 += c;
		if (k >= 100) s.c100 += c;
	}
	s.c33 += overN;
	s.c50 += overN;
	s.c100 += overN;
	return s;
}

// "<tag> n= avgFps= p50Ms= p95Ms= p99Ms= p999Ms= low1Ms= low1Fps= low01Ms= maxMs= c33= c50= c100= tail=<ms:count,...>"
// tail lists every non-empty bin of 33 ms or more (at most 167 bins plus overflow), for an audit by hand.
inline int FdhFormat(const Fdh& a_h, char* a_out, int a_cap, const char* a_tag = "fdh")
{
	if (!a_out || a_cap < 16) return 0;
	const FdhStats s = FdhCompute(a_h);
	int n = std::snprintf(a_out, static_cast<std::size_t>(a_cap),
		"%s n=%llu avgFps=%.1f p50Ms=%.0f p95Ms=%.0f p99Ms=%.0f p999Ms=%.0f low1Ms=%.1f low1Fps=%.1f low01Ms=%.1f maxMs=%.1f c33=%llu c50=%llu c100=%llu tail=",
		a_tag ? a_tag : "fdh", static_cast<unsigned long long>(s.n), s.avgFps, s.p50Ms, s.p95Ms, s.p99Ms, s.p999Ms, s.low1Ms, s.low1Fps, s.low01Ms, s.maxMs,
		static_cast<unsigned long long>(s.c33), static_cast<unsigned long long>(s.c50), static_cast<unsigned long long>(s.c100));
	if (n < 0) { a_out[0] = 0; return 0; }
	if (n >= a_cap) return a_cap - 1;
	for (int k = 33; k < kFdhBins; ++k) {
		const std::uint32_t c = a_h.b[k].load(std::memory_order_relaxed);
		if (!c) continue;
		const int left = a_cap - n;
		if (left < 16) break;
		const int add = std::snprintf(a_out + n, static_cast<std::size_t>(left), "%d:%u,", k, c);
		if (add < 0 || add >= left) break;
		n += add;
	}
	const auto overN = a_h.overN.load(std::memory_order_relaxed);
	if (overN) {
		const int left = a_cap - n;
		if (left > 24) {
			const int add = std::snprintf(a_out + n, static_cast<std::size_t>(left), "200+:%llu",
				static_cast<unsigned long long>(overN));
			if (add > 0 && add < left) n += add;
		}
	}
	return n;
}

// Menus whose open state goes into the context mask, bit i = kMenus[i]. Registered menu names (the same names
// main.cpp already checks for the HUD-ready and F11 gates). Order is the log's bit order; append only.
inline constexpr const char* kMenus[] = {
	"MonocleMenu", "PhotoModeMenu", "LoadingMenu", "PauseMenu", "FaderMenu", "DataMenu", "InventoryMenu",
	"GalaxyStarMapMenu", "DialogueMenu", "SpaceshipHudMenu", "ContainerMenu", "MainMenu", "ScopeMenu", "HUDMenu"
};
inline constexpr int kMenuCount = static_cast<int>(sizeof(kMenus) / sizeof(kMenus[0]));

// "+Name -Name" for the bits that changed, into a fixed buffer.
inline int MaskDiff(std::uint32_t a_old, std::uint32_t a_new, char* a_out, int a_cap)
{
	if (!a_out || a_cap < 2) return 0;
	int n = 0;
	a_out[0] = 0;
	for (int i = 0; i < kMenuCount; ++i) {
		const std::uint32_t bit = 1u << i;
		if ((a_old & bit) == (a_new & bit)) continue;
		const int left = a_cap - n;
		const int add = std::snprintf(a_out + n, static_cast<std::size_t>(left), "%s%s ", (a_new & bit) ? "+" : "-", kMenus[i]);
		if (add < 0 || add >= left) break;
		n += add;
	}
	return n;
}

}  // namespace hzwl
