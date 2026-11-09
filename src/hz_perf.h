#pragma once

// Purpose: off-by-default HUD performance aggregates for Horizon UI.
// Native buckets use a caller-supplied high-resolution tick (QueryPerformanceCounter
// in the DLL). The hooked call is ASMovieRootBase::AdvanceFrame(bool) — Scaleform
// root-maintenance, not Movie::Advance, not timeline traversal, not ENTER_FRAME.
// Public Scaleform 4.2 dispatches ENTER_FRAME before this callee; Starfield's binary
// is not verified. HUD ActionScript perf helpers use getTimer (millisecond wall time);
// splash/alerts/gameplay keep hz41Now (Date.getTime). This header never logs, never
// opens a file, and never starts a background worker. Export is one bounded dump
// string after intro-resolved + settle + PerfDumpWait. No generation-callback markers.
// Option B (private diagnostic build): two fixed 256-slot rings, one writer at a time (the
// HUD root hook; HUD advances are serialized), no allocation: rootT samples of 5 ms or more (QPC start, us), and
// process private-bytes drops above 256 KB (QPC, KB). At dump time they are merged with the
// AS event ring into "perf ring" lines. Everything stays behind PerfDiag.
// Author: Moragar.
// Last modified: 2026-11-09.

#include <algorithm>
#include <atomic>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <string>

namespace hzperf {

inline constexpr int kBucketCount = 5;
inline constexpr int kDumpMax = 1400;
inline constexpr int kDumpAsMax = 1400;
inline constexpr int kIntroPendingMaxMs = 15000;
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
inline constexpr int kSettleDefault = 2000;
inline constexpr int kSettleMin = 0;
inline constexpr int kSettleMax = 10000;
inline constexpr int kRingSlots = 256;
inline constexpr std::uint64_t kSpikeUs = 5000;
inline constexpr std::uint64_t kMemDropBytes = 262144;
inline constexpr int kRingAsMax = 16384;
inline constexpr int kRingEvMax = kRingSlots * 3;
inline constexpr int kRingLineMax = 192;

enum Bucket : int {
	kMovieAdvance = 0,
	kPollHud = 1,
	kPollMsg = 2,
	kScanPush = 3,
	kInvoke = 4
};

enum ArmKind : int {
	kArmNone = 0,
	kArmReady = 1,
	kArmIntro = 2,
	kArmSkip = 3,
	kArmTimeout = 4,
	kArmExhausted = 5,
	kArmNoarm = 6
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

inline const char* ArmName(int a_k)
{
	switch (a_k) {
	case kArmReady: return "ready";
	case kArmIntro: return "intro";
	case kArmSkip: return "skip";
	case kArmTimeout: return "timeout";
	case kArmExhausted: return "exhausted";
	case kArmNoarm: return "noarm";
	default: return "?";
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

inline int ClampSettleMs(int a_n)
{
	if (a_n < kSettleMin) return kSettleMin;
	if (a_n > kSettleMax) return kSettleMax;
	return a_n;
}

inline int ParseSettleMs(const std::string& a_v)
{
	if (a_v.empty()) return kSettleDefault;
	int n = 0;
	for (unsigned char c : a_v) {
		if (c < '0' || c > '9') return kSettleDefault;
		n = n * 10 + (c - '0');
		if (n > kSettleMax) return kSettleMax;
	}
	return ClampSettleMs(n);
}

inline bool DiagOn(int a_diag)
{
	return a_diag == 1;
}

inline bool SkipHoverGfx(int a_mode)
{
	return a_mode == kModeA || a_mode == kModeG;
}

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

inline void BucketReset(BucketSt& a_b)
{
	a_b.calls.store(0, std::memory_order_relaxed);
	a_b.total.store(0, std::memory_order_relaxed);
	a_b.maxv.store(0, std::memory_order_relaxed);
}

struct HistSt {
	std::atomic<std::uint64_t> h1{0};
	std::atomic<std::uint64_t> h2{0};
	std::atomic<std::uint64_t> h5{0};
	std::atomic<std::uint64_t> h10{0};
	std::atomic<std::uint64_t> h10p{0};
};

inline void HistReset(HistSt& a_h)
{
	a_h.h1.store(0, std::memory_order_relaxed);
	a_h.h2.store(0, std::memory_order_relaxed);
	a_h.h5.store(0, std::memory_order_relaxed);
	a_h.h10.store(0, std::memory_order_relaxed);
	a_h.h10p.store(0, std::memory_order_relaxed);
}

// Fixed ring. One writer at a time; HUD advances are serialized. Read only inside BeginDump/EndDump.
// If two writers ever overlapped, the worst case is a lost or torn diagnostic slot (index is % 256).
struct Ring {
	std::atomic<std::uint32_t> w{0};
	std::uint64_t q[kRingSlots]{};
	std::uint32_t v[kRingSlots]{};
};

inline void RingReset(Ring& a_r)
{
	a_r.w.store(0, std::memory_order_relaxed);
}

inline void RingPush(Ring& a_r, std::uint64_t a_q, std::uint32_t a_v)
{
	const auto w = a_r.w.load(std::memory_order_relaxed);
	const auto s = w % static_cast<std::uint32_t>(kRingSlots);
	a_r.q[s] = a_q;
	a_r.v[s] = a_v;
	a_r.w.store(w + 1, std::memory_order_release);
}

inline std::uint32_t RingCount(const Ring& a_r)
{
	const auto w = a_r.w.load(std::memory_order_acquire);
	return w < static_cast<std::uint32_t>(kRingSlots) ? w : static_cast<std::uint32_t>(kRingSlots);
}

inline std::uint32_t RingLost(const Ring& a_r)
{
	return a_r.w.load(std::memory_order_acquire) - RingCount(a_r);
}

struct Agg {
	BucketSt b[kBucketCount];
	BucketSt rootT{};
	BucketSt rootF{};
	std::atomic<std::uint64_t> frames{0};
	std::atomic<std::uint64_t> windowStart{0};
	HistSt hist{};
	HistSt histT{};
	HistSt histF{};
	std::atomic<std::uint64_t> waitUs{0};
	std::atomic<int> settleMs{0};
	std::atomic<int> armKind{0};
	std::atomic<std::uint32_t> dumping{0};
	std::atomic<std::uint32_t> inflight{0};
	Ring spike{};
	Ring pdrop{};
	std::atomic<std::uint64_t> pmemN{0};
	std::atomic<std::uint64_t> pmemLast{0};
	std::atomic<std::uint64_t> pmemMin{0};
	std::atomic<std::uint64_t> pmemMax{0};
	std::atomic<std::uint64_t> pmemDrops{0};
};

inline void Reset(Agg& a_a)
{
	for (int i = 0; i < kBucketCount; ++i)
		BucketReset(a_a.b[i]);
	BucketReset(a_a.rootT);
	BucketReset(a_a.rootF);
	a_a.frames.store(0, std::memory_order_relaxed);
	a_a.windowStart.store(0, std::memory_order_relaxed);
	HistReset(a_a.hist);
	HistReset(a_a.histT);
	HistReset(a_a.histF);
	a_a.waitUs.store(0, std::memory_order_relaxed);
	a_a.settleMs.store(0, std::memory_order_relaxed);
	a_a.armKind.store(0, std::memory_order_relaxed);
	RingReset(a_a.spike);
	RingReset(a_a.pdrop);
	a_a.pmemN.store(0, std::memory_order_relaxed);
	a_a.pmemLast.store(0, std::memory_order_relaxed);
	a_a.pmemMin.store(0, std::memory_order_relaxed);
	a_a.pmemMax.store(0, std::memory_order_relaxed);
	a_a.pmemDrops.store(0, std::memory_order_relaxed);
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

inline int HistBucketUs(std::uint64_t a_us)
{
	if (a_us < 1000) return 1;
	if (a_us < 2000) return 2;
	if (a_us < 5000) return 5;
	if (a_us <= 10000) return 10;
	return 11;
}

inline void HistInc(HistSt& a_h, std::uint64_t a_us)
{
	switch (HistBucketUs(a_us)) {
	case 1: a_h.h1.fetch_add(1, std::memory_order_relaxed); break;
	case 2: a_h.h2.fetch_add(1, std::memory_order_relaxed); break;
	case 5: a_h.h5.fetch_add(1, std::memory_order_relaxed); break;
	case 10: a_h.h10.fetch_add(1, std::memory_order_relaxed); break;
	default: a_h.h10p.fetch_add(1, std::memory_order_relaxed); break;
	}
}

inline void AddBucket(Agg& a_a, int a_bucket, std::uint64_t a_dt)
{
	if (a_bucket < 0 || a_bucket >= kBucketCount) return;
	if (!TryBeginSample(a_a)) return;
	Add(a_a.b[a_bucket], a_dt);
	EndSample(a_a);
}

// Combined movieAdvance stays as a compatibility total. Histogram splits by a_next.
inline void AddRoot(Agg& a_a, std::uint64_t a_dt, std::uint64_t a_freq, bool a_next)
{
	if (!TryBeginSample(a_a)) return;
	const auto us = Us(a_dt, a_freq);
	Add(a_a.b[kMovieAdvance], a_dt);
	HistInc(a_a.hist, us);
	if (a_next) {
		Add(a_a.rootT, a_dt);
		HistInc(a_a.histT, us);
	} else {
		Add(a_a.rootF, a_dt);
		HistInc(a_a.histF, us);
	}
	EndSample(a_a);
}

// Option B: rootT (a_next) samples of kSpikeUs or more go to the spike ring, stamped with
// the hook's own QPC start tick. No allocation. Caller already checked PerfDiag.
inline void NoteSpike(Agg& a_a, std::uint64_t a_t0, std::uint64_t a_dt, std::uint64_t a_freq, bool a_next)
{
	if (!a_next) return;
	const auto us = Us(a_dt, a_freq);
	if (us < kSpikeUs) return;
	if (!TryBeginSample(a_a)) return;
	RingPush(a_a.spike, a_t0, us > 0xFFFFFFFFull ? 0xFFFFFFFFu : static_cast<std::uint32_t>(us));
	EndSample(a_a);
}

// Option B: process private bytes, one sample per rootT. A fall of more than kMemDropBytes
// is a drop (GC proxy, process-wide). Stands in when AS System.totalMemory is unsupported.
inline void NoteProcMem(Agg& a_a, std::uint64_t a_q, std::uint64_t a_bytes)
{
	if (!a_bytes) return;
	if (!TryBeginSample(a_a)) return;
	const auto last = a_a.pmemLast.load(std::memory_order_relaxed);
	a_a.pmemN.fetch_add(1, std::memory_order_relaxed);
	if (last && a_bytes + kMemDropBytes < last) {
		a_a.pmemDrops.fetch_add(1, std::memory_order_relaxed);
		const auto kb = (last - a_bytes) / 1024ull;
		RingPush(a_a.pdrop, a_q, kb > 0xFFFFFFFFull ? 0xFFFFFFFFu : static_cast<std::uint32_t>(kb));
	}
	const auto mn = a_a.pmemMin.load(std::memory_order_relaxed);
	if (!mn || a_bytes < mn) a_a.pmemMin.store(a_bytes, std::memory_order_relaxed);
	if (a_bytes > a_a.pmemMax.load(std::memory_order_relaxed)) a_a.pmemMax.store(a_bytes, std::memory_order_relaxed);
	a_a.pmemLast.store(a_bytes, std::memory_order_relaxed);
	EndSample(a_a);
}

inline void AddMovie(Agg& a_a, std::uint64_t a_dt, std::uint64_t a_freq)
{
	AddRoot(a_a, a_dt, a_freq, true);
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

struct DumpCtl {
	std::atomic<int> req{0};
	std::atomic<int> windowArmed{0};
	std::atomic<int> skipPoll{0};
	std::atomic<int> waitSec{kWaitDefault};
	std::atomic<int> settleMs{kSettleDefault};
	std::atomic<int> armKind{0};
	std::atomic<int> postCover{0};
	std::atomic<std::uint32_t> epoch{0};
	std::atomic<std::uint32_t> armEpoch{0};
	std::atomic<std::uint64_t> dumpAtMs{0};
	std::atomic<std::uint64_t> readyMs{0};
};

inline void ArmDump(DumpCtl& a_c, int a_waitSec, int a_settleMs = kSettleDefault)
{
	a_c.waitSec.store(ClampWaitSec(a_waitSec), std::memory_order_relaxed);
	a_c.settleMs.store(ClampSettleMs(a_settleMs), std::memory_order_relaxed);
	a_c.epoch.fetch_add(1, std::memory_order_acq_rel);
	a_c.windowArmed.store(0, std::memory_order_relaxed);
	a_c.skipPoll.store(0, std::memory_order_relaxed);
	a_c.postCover.store(0, std::memory_order_relaxed);
	a_c.dumpAtMs.store(0, std::memory_order_relaxed);
	a_c.readyMs.store(0, std::memory_order_relaxed);
	a_c.armKind.store(0, std::memory_order_relaxed);
	a_c.armEpoch.store(0, std::memory_order_relaxed);
	a_c.req.store(1, std::memory_order_release);
}

inline void UnarmWindow(DumpCtl& a_c)
{
	a_c.epoch.fetch_add(1, std::memory_order_acq_rel);
	a_c.windowArmed.store(0, std::memory_order_relaxed);
	a_c.skipPoll.store(0, std::memory_order_relaxed);
	a_c.postCover.store(0, std::memory_order_relaxed);
	a_c.dumpAtMs.store(0, std::memory_order_relaxed);
	a_c.readyMs.store(0, std::memory_order_relaxed);
	a_c.armKind.store(0, std::memory_order_relaxed);
}

inline bool EpochMatches(const DumpCtl& a_c)
{
	return a_c.epoch.load(std::memory_order_acquire) == a_c.armEpoch.load(std::memory_order_acquire);
}

inline void NoteCovered(DumpCtl& a_c)
{
	a_c.postCover.store(1, std::memory_order_release);
}

inline bool TakePostCover(DumpCtl& a_c)
{
	return a_c.postCover.exchange(0, std::memory_order_acq_rel) != 0;
}

inline void NoteHudReady(DumpCtl& a_c, std::uint64_t a_nowMs)
{
	std::uint64_t z = 0;
	a_c.readyMs.compare_exchange_strong(z, a_nowMs, std::memory_order_relaxed, std::memory_order_relaxed);
}

inline std::uint64_t ArmAtMs(std::uint64_t a_readyMs, std::uint64_t a_introResolvedMs, bool a_introPending,
	std::uint64_t a_nowMs, int a_settleMs)
{
	if (!a_readyMs) return 0;
	bool pending = a_introPending;
	if (pending && a_nowMs >= a_readyMs + static_cast<std::uint64_t>(kIntroPendingMaxMs))
		pending = false;
	if (pending) return 0;
	const auto intro = a_introResolvedMs ? a_introResolvedMs : a_readyMs;
	const auto base = a_readyMs > intro ? a_readyMs : intro;
	return base + static_cast<std::uint64_t>(ClampSettleMs(a_settleMs));
}

inline int PickArmKind(std::uint64_t a_readyMs, std::uint64_t a_introResolvedMs, int a_introKind)
{
	if (!a_introResolvedMs) return kArmNoarm;
	if (a_readyMs >= a_introResolvedMs) return kArmReady;
	if (a_introKind >= kArmIntro && a_introKind <= kArmExhausted) return a_introKind;
	return kArmIntro;
}

enum class ReadyOp : int { None = 0, ResetWindow = 1 };

inline ReadyOp OnHudArmPoll(DumpCtl& a_c, bool a_diagOn, std::uint64_t a_nowMs,
	std::uint64_t a_introResolvedMs, bool a_introPending, int a_introKind)
{
	if (!a_diagOn || a_c.req.load(std::memory_order_acquire) == 0) return ReadyOp::None;
	if (a_c.windowArmed.load(std::memory_order_acquire) != 0) return ReadyOp::None;
	const auto ready = a_c.readyMs.load(std::memory_order_relaxed);
	const auto at = ArmAtMs(ready, a_introResolvedMs, a_introPending, a_nowMs,
		a_c.settleMs.load(std::memory_order_relaxed));
	if (!at || a_nowMs < at) return ReadyOp::None;
	const auto epoch = a_c.epoch.load(std::memory_order_acquire);
	int armed = 0;
	if (!a_c.windowArmed.compare_exchange_strong(armed, 1, std::memory_order_acq_rel, std::memory_order_acquire))
		return ReadyOp::None;
	if (a_c.epoch.load(std::memory_order_acquire) != epoch) {
		a_c.windowArmed.store(0, std::memory_order_release);
		return ReadyOp::None;
	}
	a_c.armEpoch.store(epoch, std::memory_order_release);
	const auto wait = static_cast<std::uint64_t>(a_c.waitSec.load(std::memory_order_relaxed));
	a_c.dumpAtMs.store(a_nowMs + wait * 1000ull, std::memory_order_relaxed);
	a_c.armKind.store(PickArmKind(ready, a_introResolvedMs, a_introKind), std::memory_order_relaxed);
	a_c.skipPoll.store(1, std::memory_order_release);
	return ReadyOp::ResetWindow;
}

enum class DumpOp : int { Skip = 0, Fire = 1 };

inline DumpOp OnHudSafePoll(DumpCtl& a_c, bool a_hudSafe, bool a_diagOn, std::uint64_t a_nowMs)
{
	if (!a_diagOn || a_c.req.load(std::memory_order_acquire) == 0) return DumpOp::Skip;
	if (a_c.windowArmed.load(std::memory_order_acquire) == 0) return DumpOp::Skip;
	if (!EpochMatches(a_c)) return DumpOp::Skip;
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

inline int AppendBucket(char* a_out, int a_n, int a_cap, const char* a_name, const BucketSt& a_b,
	std::uint64_t a_elapsed, std::uint64_t a_freq)
{
	const auto calls = a_b.calls.load(std::memory_order_relaxed);
	const auto total = a_b.total.load(std::memory_order_relaxed);
	const auto maxv = a_b.maxv.load(std::memory_order_relaxed);
	const auto avg = calls ? Us(total / calls, a_freq) : 0;
	const int left = a_cap - a_n;
	if (left < 48) return a_n;
	const int add = std::snprintf(a_out + a_n, static_cast<std::size_t>(left),
		" %s={n=%llu avgUs=%llu maxUs=%llu cps=%.1f}",
		a_name,
		static_cast<unsigned long long>(calls),
		static_cast<unsigned long long>(avg),
		static_cast<unsigned long long>(Us(maxv, a_freq)),
		Cps(calls, a_elapsed, a_freq));
	if (add < 0) return a_n;
	if (add >= left) return a_cap - 1;
	return a_n + add;
}

inline int AppendRoot(char* a_out, int a_n, int a_cap, const char* a_name, const BucketSt& a_b, const HistSt& a_h,
	std::uint64_t a_elapsed, std::uint64_t a_freq)
{
	const auto calls = a_b.calls.load(std::memory_order_relaxed);
	const auto total = a_b.total.load(std::memory_order_relaxed);
	const auto maxv = a_b.maxv.load(std::memory_order_relaxed);
	const auto avg = calls ? Us(total / calls, a_freq) : 0;
	const int left = a_cap - a_n;
	if (left < 64) return a_n;
	const int add = std::snprintf(a_out + a_n, static_cast<std::size_t>(left),
		" %s={n=%llu avgUs=%llu maxUs=%llu cps=%.1f h1=%llu h2=%llu h5=%llu h10=%llu h10p=%llu}",
		a_name,
		static_cast<unsigned long long>(calls),
		static_cast<unsigned long long>(avg),
		static_cast<unsigned long long>(Us(maxv, a_freq)),
		Cps(calls, a_elapsed, a_freq),
		static_cast<unsigned long long>(a_h.h1.load(std::memory_order_relaxed)),
		static_cast<unsigned long long>(a_h.h2.load(std::memory_order_relaxed)),
		static_cast<unsigned long long>(a_h.h5.load(std::memory_order_relaxed)),
		static_cast<unsigned long long>(a_h.h10.load(std::memory_order_relaxed)),
		static_cast<unsigned long long>(a_h.h10p.load(std::memory_order_relaxed)));
	if (add < 0) return a_n;
	if (add >= left) return a_cap - 1;
	return a_n + add;
}

inline int FormatNative(const Agg& a_a, std::uint64_t a_freq, std::uint64_t a_now, int a_diag, int a_mode, int a_scanEn,
	char* a_out, int a_cap)
{
	if (!a_out || a_cap < 8) return 0;
	const auto start = a_a.windowStart.load(std::memory_order_relaxed);
	const auto elapsed = (start && a_now >= start) ? (a_now - start) : 0;
	int n = std::snprintf(a_out, static_cast<std::size_t>(a_cap),
		"perf native diag=%d mode=%d(%s) scan=%d freq=%llu winUs=%llu frames=%llu clock=QPC scope=asRootMaint",
		a_diag, a_mode, ModeName(a_mode), a_scanEn,
		static_cast<unsigned long long>(a_freq),
		static_cast<unsigned long long>(Us(elapsed, a_freq)),
		static_cast<unsigned long long>(a_a.frames.load(std::memory_order_relaxed)));
	if (n < 0) {
		a_out[0] = 0;
		return 0;
	}
	if (n >= a_cap) n = a_cap - 1;
	for (int i = 0; i < kBucketCount; ++i)
		n = AppendBucket(a_out, n, a_cap, BucketName(i), a_a.b[i], elapsed, a_freq);
	n = AppendRoot(a_out, n, a_cap, "rootT", a_a.rootT, a_a.histT, elapsed, a_freq);
	n = AppendRoot(a_out, n, a_cap, "rootF", a_a.rootF, a_a.histF, elapsed, a_freq);
	{
		const int left = a_cap - n;
		if (left >= 48) {
			const int add = std::snprintf(a_out + n, static_cast<std::size_t>(left),
				" h1=%llu h2=%llu h5=%llu h10=%llu h10p=%llu waitUs=%llu settleMs=%d arm=%s",
				static_cast<unsigned long long>(a_a.hist.h1.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.hist.h2.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.hist.h5.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.hist.h10.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.hist.h10p.load(std::memory_order_relaxed)),
				static_cast<unsigned long long>(a_a.waitUs.load(std::memory_order_relaxed)),
				a_a.settleMs.load(std::memory_order_relaxed),
				ArmName(a_a.armKind.load(std::memory_order_relaxed)));
			if (add > 0 && add < left) n += add;
			else if (add >= left) n = a_cap - 1;
		}
	}
	a_out[n] = 0;
	return n;
}

// ---- Option B merged ring (dump time only; the caller holds BeginDump) ----

struct RingEv {
	double tMs = 0;       // ms since the dump window start, QPC clock
	char src = 'N';       // 'N' native, 'A' ActionScript
	char type = '?';      // R spike, P private-bytes drop, T target change, C compass, M AS memory drop, Q quest sync
	double v = 0;
	std::uint32_t n = 1;  // events folded into this slot (C/Q runs)
	double spanMs = 0;
};

struct AsRingHead {
	int ok = 0;
	double now = 0;
	int n = 0;
	int lost = 0;
	int memUnsupported = -1;
	int timerUnsupported = -1;
};

inline double QpcMs(std::uint64_t a_q, std::uint64_t a_freq)
{
	if (!a_freq) return 0;
	return static_cast<double>(a_q) * 1000.0 / static_cast<double>(a_freq);
}

inline int CollectNative(const Agg& a_a, std::uint64_t a_freq, RingEv* a_out, int a_cap)
{
	if (!a_out || a_cap <= 0) return 0;
	const double w0 = QpcMs(a_a.windowStart.load(std::memory_order_relaxed), a_freq);
	int k = 0;
	const Ring* rings[2] = { &a_a.spike, &a_a.pdrop };
	const char types[2] = { 'R', 'P' };
	for (int r = 0; r < 2; ++r) {
		const auto w = rings[r]->w.load(std::memory_order_acquire);
		const auto n = RingCount(*rings[r]);
		for (auto i = w - n; i != w && k < a_cap; ++i) {
			const auto s = i % static_cast<std::uint32_t>(kRingSlots);
			RingEv e{};
			e.src = 'N';
			e.type = types[r];
			e.tMs = QpcMs(rings[r]->q[s], a_freq) - w0;
			e.v = static_cast<double>(rings[r]->v[s]);
			a_out[k++] = e;
		}
	}
	return k;
}

inline const char* SkipTo(const char* a_s, char a_c)
{
	while (*a_s && *a_s != a_c) ++a_s;
	return a_s;
}

inline bool HeadNum(const std::string& a_s, const char* a_key, double& a_out)
{
	const auto p = a_s.find(a_key);
	if (p == std::string::npos) return false;
	a_out = std::strtod(a_s.c_str() + p + std::strlen(a_key), nullptr);
	return true;
}

// AS format: "ring now=<ms> n=<n> lost=<n> memUnsupported=<0|1>|ty,t0,t1,v,c;..."
// ty: 1=T 2=C 3=M 4=Q. a_offMs = qpcMs(at invoke) - now; a_w0Ms = qpcMs(window start).
inline int ParseAsRing(const char* a_s, double a_offMs, double a_w0Ms, RingEv* a_out, int a_cap, AsRingHead& a_head)
{
	a_head = AsRingHead{};
	if (!a_s || std::strncmp(a_s, "ring now=", 9) != 0) return 0;
	const char* bar = SkipTo(a_s, '|');
	if (*bar != '|') return 0;
	const std::string head(a_s, static_cast<std::size_t>(bar - a_s));
	double d = 0;
	if (HeadNum(head, "now=", d)) a_head.now = d;
	if (HeadNum(head, " n=", d)) a_head.n = static_cast<int>(d);
	if (HeadNum(head, " lost=", d)) a_head.lost = static_cast<int>(d);
	if (HeadNum(head, " memUnsupported=", d)) a_head.memUnsupported = static_cast<int>(d);
	if (HeadNum(head, " timerUnsupported=", d)) a_head.timerUnsupported = static_cast<int>(d);
	a_head.ok = 1;
	int k = 0;
	const char* p = bar + 1;
	while (*p && k < a_cap) {
		const char* end = SkipTo(p, ';');
		if (*end != ';') break;  // truncated tail
		double f[5] = { 0, 0, 0, 0, 0 };
		int nf = 0;
		const char* q = p;
		while (q < end && nf < 5) {
			char* e2 = nullptr;
			const double x = std::strtod(q, &e2);
			if (!e2 || e2 == q || e2 > end) break;
			f[nf++] = x;
			q = e2;
			if (q < end && *q == ',') ++q;
		}
		p = end + 1;
		if (nf != 5) continue;
		RingEv e{};
		e.src = 'A';
		switch (static_cast<int>(f[0])) {
		case 1: e.type = 'T'; break;
		case 2: e.type = 'C'; break;
		case 3: e.type = 'M'; break;
		case 4: e.type = 'Q'; break;
		default: continue;
		}
		e.tMs = f[1] + a_offMs - a_w0Ms;
		e.spanMs = f[2] >= f[1] ? f[2] - f[1] : 0;
		e.v = f[3];
		e.n = f[4] > 0 ? static_cast<std::uint32_t>(f[4]) : 1;
		a_out[k++] = e;
	}
	return k;
}

inline void SortRing(RingEv* a_ev, int a_n)
{
	if (!a_ev || a_n <= 1) return;
	std::stable_sort(a_ev, a_ev + a_n, [](const RingEv& a, const RingEv& b) { return a.tMs < b.tMs; });
}

inline const char* RingUnit(char a_type)
{
	switch (a_type) {
	case 'R': return "us";
	case 'P':
	case 'M': return "KB";
	case 'C': return "ms";
	default: return "";
	}
}

inline int FormatRingEv(const RingEv& a_e, char* a_out, int a_cap)
{
	if (!a_out || a_cap < 8) return 0;
	int n = 0;
	if (a_e.type == 'C' || a_e.type == 'Q')
		n = std::snprintf(a_out, static_cast<std::size_t>(a_cap), "perf ring t=%.1f src=%s type=%c v=%.0f%s n=%u span=%.0f",
			a_e.tMs, a_e.src == 'A' ? "AS" : "N", a_e.type, a_e.v, RingUnit(a_e.type), a_e.n, a_e.spanMs);
	else
		n = std::snprintf(a_out, static_cast<std::size_t>(a_cap), "perf ring t=%.1f src=%s type=%c v=%.0f%s",
			a_e.tMs, a_e.src == 'A' ? "AS" : "N", a_e.type, a_e.v, RingUnit(a_e.type));
	if (n < 0) {
		a_out[0] = 0;
		return 0;
	}
	return n >= a_cap ? a_cap - 1 : n;
}

inline int FormatRingSum(const Agg& a_a, const AsRingHead& a_h, double a_offMs, int a_events, char* a_out, int a_cap)
{
	if (!a_out || a_cap < 8) return 0;
	const int n = std::snprintf(a_out, static_cast<std::size_t>(a_cap),
		"perf ring sum events=%d spikes=%u spikeLost=%u spikeMinUs=%llu pmemN=%llu pmemMinKB=%llu pmemMaxKB=%llu pmemDrops=%llu pdropLost=%u as=%s asN=%d asLost=%d memUnsupported=%d timerUnsupported=%d offMs=%.1f clock=QPC_ms_since_window",
		a_events, RingCount(a_a.spike), RingLost(a_a.spike),
		static_cast<unsigned long long>(kSpikeUs),
		static_cast<unsigned long long>(a_a.pmemN.load(std::memory_order_relaxed)),
		static_cast<unsigned long long>(a_a.pmemMin.load(std::memory_order_relaxed) / 1024ull),
		static_cast<unsigned long long>(a_a.pmemMax.load(std::memory_order_relaxed) / 1024ull),
		static_cast<unsigned long long>(a_a.pmemDrops.load(std::memory_order_relaxed)),
		RingLost(a_a.pdrop),
		a_h.ok ? "ok" : "missing", a_h.n, a_h.lost, a_h.memUnsupported, a_h.timerUnsupported, a_offMs);
	if (n < 0) {
		a_out[0] = 0;
		return 0;
	}
	return n >= a_cap ? a_cap - 1 : n;
}

inline bool FixtureLabelOk(const char* a_s)
{
	if (!a_s) return false;
	return std::strstr(a_s, "DIAGNOSTIC") != nullptr && std::strstr(a_s, "NOT GAME DATA") != nullptr;
}

} // namespace hzperf
