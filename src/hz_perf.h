#pragma once

// Purpose: off-by-default HUD performance aggregates for Horizon UI.
// Native buckets use a caller-supplied high-resolution tick (QueryPerformanceCounter
// in the DLL). HUD ActionScript uses hz41Now (Date.getTime), millisecond resolution;
// that clock cannot measure sub-millisecond work. This header never logs, never opens a
// file, and never starts a background worker. Export is an explicit dump string the DLL logs
// once on a PerfDump 0->1 edge.
// Inputs: diagnostic INI flags, tick deltas, an optional ActionScript snapshot.
// Outputs: average / max / calls / calls-per-second per native bucket, mode gates.
// Dependencies: none. Not CommonLib. Not a logger. Not a worker.
// Author: Moragar.
// Last modified: 2026-11-08.

#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <string>

namespace hzperf {

inline constexpr int kBucketCount = 5;
inline constexpr int kDumpMax = 1400;
inline constexpr int kModeOff = 0;
inline constexpr int kModeA = 1;
inline constexpr int kModeB = 2;
inline constexpr int kModeC = 3;
inline constexpr int kModeD = 4;
inline constexpr int kModeE = 5;
inline constexpr int kModeF = 6;
inline constexpr int kModeG = 7;

enum Bucket : int {
	kMovieAdvance = 0,
	kPollHud = 1,
	kPollMsg = 2,
	kScanPush = 3,
	kInvoke = 4
};

inline const char* BucketName(int a_i)
{
	switch (a_i) {
	case kMovieAdvance: return "movieAdvance";
	case kPollHud: return "pollHud";
	case kPollMsg: return "pollMsg";
	case kScanPush: return "scanPush";
	case kInvoke: return "invoke";
	default: return "?";
	}
}

inline const char* ModeName(int a_mode)
{
	switch (a_mode) {
	case kModeOff: return "baseline";
	case kModeA: return "A-native-no-gfx";
	case kModeB: return "B-ui-fixture";
	case kModeC: return "C-full";
	case kModeD: return "D-same-target";
	case kModeE: return "E-rapid-change";
	case kModeF: return "F-scanner";
	case kModeG: return "G-background";
	default: return "off";
	}
}

inline int ClampMode(int a_mode)
{
	if (a_mode < 0 || a_mode > kModeG) return kModeOff;
	return a_mode;
}

inline int Parse01(const std::string& a_v)
{
	return a_v == "1" ? 1 : 0;
}

inline int ParseMode(const std::string& a_v)
{
	if (a_v.empty()) return kModeOff;
	int n = 0;
	for (unsigned char c : a_v) {
		if (c < '0' || c > '9') return kModeOff;
		n = n * 10 + (c - '0');
		if (n > kModeG) return kModeOff;
	}
	return ClampMode(n);
}

// PerfDiag=0 is production: no isolation, no dump, no extra Invokes.
inline bool DiagOn(int a_diag)
{
	return a_diag == 1;
}

// Mode A / G: keep native collection, skip hover/scanner GFx updates.
inline bool SkipHoverGfx(int a_mode)
{
	return a_mode == kModeA || a_mode == kModeG;
}

// Mode B is a labeled diagnostic fixture. It is never live game / ship data.
inline bool UseFixture(int a_mode)
{
	return a_mode == kModeB;
}

inline bool SkipLiveCollect(int a_mode)
{
	return a_mode == kModeB;
}

inline bool SkipTargetTick(int a_mode)
{
	return a_mode == kModeG;
}

// Mode F uses PerfScan: 1 = scanner draw on, 0 = suppressed. A and G also skip.
inline bool SkipScannerDraw(int a_mode, int a_scanEn)
{
	if (a_mode == kModeA || a_mode == kModeG) return true;
	if (a_mode == kModeF && a_scanEn == 0) return true;
	return false;
}

inline bool SkipScanPushInvoke(int a_mode, int a_scanEn)
{
	return SkipScannerDraw(a_mode, a_scanEn);
}

struct BucketSt {
	std::atomic<std::uint64_t> calls{0};
	std::atomic<std::uint64_t> total{0};
	std::atomic<std::uint64_t> maxv{0};
};

inline void Add(BucketSt& a_b, std::uint64_t a_dt)
{
	a_b.calls.fetch_add(1, std::memory_order_relaxed);
	a_b.total.fetch_add(a_dt, std::memory_order_relaxed);
	auto cur = a_b.maxv.load(std::memory_order_relaxed);
	while (a_dt > cur && !a_b.maxv.compare_exchange_weak(cur, a_dt, std::memory_order_relaxed)) {
	}
}

struct Agg {
	BucketSt b[kBucketCount];
	std::atomic<std::uint64_t> frames{0};
	std::atomic<std::uint64_t> windowStart{0};
};

inline void Reset(Agg& a_a)
{
	for (int i = 0; i < kBucketCount; ++i) {
		a_a.b[i].calls.store(0, std::memory_order_relaxed);
		a_a.b[i].total.store(0, std::memory_order_relaxed);
		a_a.b[i].maxv.store(0, std::memory_order_relaxed);
	}
	a_a.frames.store(0, std::memory_order_relaxed);
	a_a.windowStart.store(0, std::memory_order_relaxed);
}

inline std::uint64_t Us(std::uint64_t a_ticks, std::uint64_t a_freq)
{
	if (!a_freq) return 0;
	return (a_ticks * 1000000ull) / a_freq;
}

inline double Cps(std::uint64_t a_calls, std::uint64_t a_elapsedTicks, std::uint64_t a_freq)
{
	if (!a_freq || !a_elapsedTicks) return 0;
	return (static_cast<double>(a_calls) * static_cast<double>(a_freq)) / static_cast<double>(a_elapsedTicks);
}

inline bool DumpEdge(int a_prev, int a_now)
{
	return a_prev == 0 && a_now == 1;
}

// Purpose: format one explicit dump line. Bounded to kDumpMax.
// Clock is QPC ticks / freq. Calls-per-second uses the dump window.
inline int FormatNative(const Agg& a_a, std::uint64_t a_freq, std::uint64_t a_now, int a_diag, int a_mode, int a_scanEn,
	char* a_out, int a_cap)
{
	if (!a_out || a_cap < 8) return 0;
	const auto start = a_a.windowStart.load(std::memory_order_relaxed);
	const auto elapsed = (start && a_now >= start) ? (a_now - start) : 0;
	int n = std::snprintf(a_out, static_cast<std::size_t>(a_cap),
		"perf native diag=%d mode=%d(%s) scan=%d freq=%llu winUs=%llu frames=%llu clock=QPC",
		a_diag, a_mode, ModeName(a_mode), a_scanEn,
		static_cast<unsigned long long>(a_freq),
		static_cast<unsigned long long>(Us(elapsed, a_freq)),
		static_cast<unsigned long long>(a_a.frames.load(std::memory_order_relaxed)));
	if (n < 0) {
		a_out[0] = 0;
		return 0;
	}
	if (n >= a_cap) n = a_cap - 1;
	for (int i = 0; i < kBucketCount; ++i) {
		const auto calls = a_a.b[i].calls.load(std::memory_order_relaxed);
		const auto total = a_a.b[i].total.load(std::memory_order_relaxed);
		const auto maxv = a_a.b[i].maxv.load(std::memory_order_relaxed);
		const auto avg = calls ? Us(total / calls, a_freq) : 0;
		const int left = a_cap - n;
		if (left < 48) break;
		const int add = std::snprintf(a_out + n, static_cast<std::size_t>(left),
			" %s={n=%llu avgUs=%llu maxUs=%llu cps=%.1f}",
			BucketName(i),
			static_cast<unsigned long long>(calls),
			static_cast<unsigned long long>(avg),
			static_cast<unsigned long long>(Us(maxv, a_freq)),
			Cps(calls, elapsed, a_freq));
		if (add < 0) break;
		if (add >= left) {
			n = a_cap - 1;
			break;
		}
		n += add;
	}
	a_out[n] = 0;
	return n;
}

inline bool FixtureLabelOk(const char* a_s)
{
	if (!a_s) return false;
	return std::strstr(a_s, "DIAGNOSTIC") != nullptr && std::strstr(a_s, "NOT GAME DATA") != nullptr;
}

} // namespace hzperf
