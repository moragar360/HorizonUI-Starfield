#pragma once

// Purpose: off-by-default HUD performance aggregates for Horizon UI.
// Native buckets use a caller-supplied high-resolution tick (QueryPerformanceCounter
// in the DLL). HUD ActionScript uses hz41Now (Date.getTime), millisecond resolution;
// that clock cannot measure sub-millisecond work. This header never logs, never opens a
// file, and never starts a background worker. Export is an explicit dump string the DLL logs
// once on a PerfDump 0->1 edge, after first HUD-ready + PerfDumpWait seconds.
// Inputs: diagnostic INI flags, tick deltas, an optional ActionScript snapshot.
// Outputs: average / max / calls / calls-per-second per native bucket, movieAdvance
// histogram, mode gates, dump-window latch. Dependencies: none. Not CommonLib.
// Not a logger. Not a worker.
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
inline constexpr int kWaitDefault = 12;
inline constexpr int kWaitMin = 1;
inline constexpr int kWaitMax = 60;

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

inline int ClampWaitSec(int a_n)
{
	if (a_n < kWaitMin) return kWaitMin;
	if (a_n > kWaitMax) return kWaitMax;
	return a_n;
}

// PerfDumpWait. Digits only. Empty or junk -> 12. Then clamp 1-60.
inline int ParseWaitSec(const std::string& a_v)
{
	if (a_v.empty()) return kWaitDefault;
	int n = 0;
	for (unsigned char c : a_v) {
		if (c < '0' || c > '9') return kWaitDefault;
		n = n * 10 + (c - '0');
		if (n > kWaitMax) return kWaitMax;
	}
	return ClampWaitSec(n);
}

inline std::uint64_t WaitUsFromSec(int a_sec)
{
	return static_cast<std::uint64_t>(ClampWaitSec(a_sec)) * 1000000ull;
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
	std::atomic<std::uint64_t> h1{0};
	std::atomic<std::uint64_t> h2{0};
	std::atomic<std::uint64_t> h5{0};
	std::atomic<std::uint64_t> h10{0};
	std::atomic<std::uint64_t> h10p{0};
	std::atomic<std::uint64_t> waitUs{0};
	std::atomic<std::uint32_t> dumping{0};
	std::atomic<std::uint32_t> inflight{0};
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
	a_a.h1.store(0, std::memory_order_relaxed);
	a_a.h2.store(0, std::memory_order_relaxed);
	a_a.h5.store(0, std::memory_order_relaxed);
	a_a.h10.store(0, std::memory_order_relaxed);
	a_a.h10p.store(0, std::memory_order_relaxed);
	a_a.waitUs.store(0, std::memory_order_relaxed);
}

inline void BeginDump(Agg& a_a)
{
	a_a.dumping.store(1, std::memory_order_release);
	while (a_a.inflight.load(std::memory_order_acquire) != 0) {
	}
}

inline void EndDump(Agg& a_a)
{
	a_a.dumping.store(0, std::memory_order_release);
}

inline bool TryBeginSample(Agg& a_a)
{
	if (a_a.dumping.load(std::memory_order_acquire) != 0) return false;
	a_a.inflight.fetch_add(1, std::memory_order_acq_rel);
	if (a_a.dumping.load(std::memory_order_acquire) != 0) {
		a_a.inflight.fetch_sub(1, std::memory_order_release);
		return false;
	}
	return true;
}

inline void EndSample(Agg& a_a)
{
	a_a.inflight.fetch_sub(1, std::memory_order_release);
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

// movieAdvance us: h1 <1ms, h2 1-2, h5 2-5, h10 5-10, h10p >10.
inline int HistBucketUs(std::uint64_t a_us)
{
	if (a_us < 1000) return 1;
	if (a_us < 2000) return 2;
	if (a_us < 5000) return 5;
	if (a_us <= 10000) return 10;
	return 11;
}

inline void HistInc(Agg& a_a, std::uint64_t a_us)
{
	switch (HistBucketUs(a_us)) {
	case 1: a_a.h1.fetch_add(1, std::memory_order_relaxed); break;
	case 2: a_a.h2.fetch_add(1, std::memory_order_relaxed); break;
	case 5: a_a.h5.fetch_add(1, std::memory_order_relaxed); break;
	case 10: a_a.h10.fetch_add(1, std::memory_order_relaxed); break;
	default: a_a.h10p.fetch_add(1, std::memory_order_relaxed); break;
	}
}

inline void AddBucket(Agg& a_a, int a_bucket, std::uint64_t a_dt)
{
	if (a_bucket < 0 || a_bucket >= kBucketCount) return;
	if (!TryBeginSample(a_a)) return;
	Add(a_a.b[a_bucket], a_dt);
	EndSample(a_a);
}

inline void AddMovie(Agg& a_a, std::uint64_t a_dt, std::uint64_t a_freq)
{
	if (!TryBeginSample(a_a)) return;
	Add(a_a.b[kMovieAdvance], a_dt);
	HistInc(a_a, Us(a_dt, a_freq));
	EndSample(a_a);
}

inline void NoteWindowStart(Agg& a_a, std::uint64_t a_t)
{
	std::uint64_t z = 0;
	a_a.windowStart.compare_exchange_strong(z, a_t, std::memory_order_relaxed, std::memory_order_relaxed);
}

inline bool DumpEdge(int a_prev, int a_now)
{
	return a_prev == 0 && a_now == 1;
}

// Delayed dump latch. Pause/menus must not clear req or windowArmed.
struct DumpCtl {
	std::atomic<int> req{0};
	std::atomic<int> windowArmed{0};
	std::atomic<int> skipPoll{0};
	std::atomic<int> waitSec{kWaitDefault};
	std::atomic<std::uint64_t> dumpAtMs{0};
};

inline void ArmDump(DumpCtl& a_c, int a_waitSec)
{
	a_c.waitSec.store(ClampWaitSec(a_waitSec), std::memory_order_relaxed);
	a_c.windowArmed.store(0, std::memory_order_relaxed);
	a_c.skipPoll.store(0, std::memory_order_relaxed);
	a_c.dumpAtMs.store(0, std::memory_order_relaxed);
	a_c.req.store(1, std::memory_order_release);
}

enum class ReadyOp : int { None = 0, ResetWindow = 1 };

// First HUD-ready (3s stable) only. Later PauseMenu re-ready does not re-reset.
inline ReadyOp OnHudFirstReady(DumpCtl& a_c, bool a_diagOn, std::uint64_t a_nowMs)
{
	if (!a_diagOn || a_c.req.load(std::memory_order_acquire) == 0) return ReadyOp::None;
	int armed = 0;
	if (!a_c.windowArmed.compare_exchange_strong(armed, 1, std::memory_order_acq_rel, std::memory_order_acquire))
		return ReadyOp::None;
	const auto wait = static_cast<std::uint64_t>(a_c.waitSec.load(std::memory_order_relaxed));
	a_c.dumpAtMs.store(a_nowMs + wait * 1000ull, std::memory_order_relaxed);
	a_c.skipPoll.store(1, std::memory_order_release);
	return ReadyOp::ResetWindow;
}

enum class DumpOp : int { Skip = 0, Fire = 1 };

// HudSafe poll. Pause/menus: hudSafe false -> Skip, req and counters stay.
inline DumpOp OnHudSafePoll(DumpCtl& a_c, bool a_hudSafe, bool a_diagOn, std::uint64_t a_nowMs)
{
	if (!a_diagOn || a_c.req.load(std::memory_order_acquire) == 0) return DumpOp::Skip;
	if (a_c.windowArmed.load(std::memory_order_acquire) == 0) return DumpOp::Skip;
	if (!a_hudSafe) return DumpOp::Skip;
	if (a_nowMs < a_c.dumpAtMs.load(std::memory_order_relaxed)) return DumpOp::Skip;
	return DumpOp::Fire;
}

inline void ConsumeDump(DumpCtl& a_c)
{
	a_c.req.store(0, std::memory_order_release);
	a_c.skipPoll.store(1, std::memory_order_release);
}

inline bool TakeSkipPoll(DumpCtl& a_c)
{
	return a_c.skipPoll.exchange(0, std::memory_order_acq_rel) != 0;
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
	{
		const int left = a_cap - n;
		if (left >= 48) {
			const int add = std::snprintf(a_out + n, static_cast<std::size_t>(left),
				" h1=%llu h2=%llu h5=%llu h10=%llu h10p=%llu waitUs=%llu",
				static_cast<unsigned long long>(a_a.h1.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.h2.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.h5.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.h10.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.h10p.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.waitUs.load(std::memory_order_relaxed)));
			if (add > 0 && add < left) n += add;
			else if (add >= left) n = a_cap - 1;
		}
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
