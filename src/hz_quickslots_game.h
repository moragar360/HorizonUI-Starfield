// Horizon UI 0.43.5: game wrappers and FavoritesMenu wiring for Extended Quick Menu.
// Original Horizon code. Public Address Library IDs only. Fail safe if an ID
// does not resolve. Author: Moragar.
#pragma once

#include "hz_quickslots.h"

// Included from main.cpp inside namespace HZ. Do not wrap in namespace HZ.
	std::mutex              g_qmMu;
	hzqs::Settings          g_qmSet{};
	hzqs::Store             g_qmStore{};
	hzqs::ParkedSet         g_qmParked{};       // one parked store per character, cleared by generation (S-F)
	std::uint64_t           g_qmLoadGen = 0;    // bumped when a load is requested or cancelled; job thread + HUD under g_qmMu
	std::atomic<bool>       g_qmConflict{false};
	std::atomic<bool>       g_qmModule{true};
	std::atomic<bool>       g_qmMenuOpen{false};
	std::atomic<bool>       g_qmBound{false};       // hzqExtCmd attached this open
	std::atomic<bool>       g_qmHudPush{false};
	std::atomic<std::uint64_t> g_qmUseReq{0};       // hzqs::PackUseReq(slot | kQmFromMenu, tick), processed on the HUD advance path
	constexpr int           kQmFromMenu = hzqs::kReqFromMenu;  // request came from a click in the open quick menu
	std::atomic<std::uint32_t> g_qmSetGen{1};       // bumped when settings change (key refusal recompute)
	std::uint32_t           g_qmBlockGen = 0;       // HUD thread only
	std::atomic<std::uint32_t> g_qmKeyBlock{0};     // bit i = slot 13+i key refused (game-bound, F11 or duplicate)
	std::uint64_t           g_qmStoreTry = 0;       // HUD thread only: lazy per-character store load
	bool                    g_qmNoHandleLogged = false;
	bool                    g_qmCtlMissLogged = false;
	// Hot-path caches (performance standards 3/4/5): written only when settings change, read lock-free per poll.
	std::atomic<bool>       g_qmExtOn{false};       // Extended Mode on
	std::atomic<int>        g_qmVisCount{12};       // clamped slot count
	std::atomic<int>        g_qmVk[12]{};           // virtual-key per slot 13-24, 0 = none
	int                     g_qmLastResult[13]{};   // HUD thread: last logged use result per slot (log changes only)
	std::atomic<std::uint32_t> g_qmPendingForm{0};
	std::atomic<bool>       g_qmStoreDirty{false};
	std::string             g_qmStoreLast;
	std::atomic<RE::Scaleform::GFx::ASMovieRootBase*> g_favRoot{nullptr};
	std::atomic<bool>       g_inFavPoll{false};
	bool                    g_qmConflictLogged = false;
	bool                    g_qmUseMissLogged = false;
	bool                    g_qmLateLogged = false;  // HUD thread: one line the first time a late key press is dropped
	bool                    g_qmKeyDown[12]{};

	// N-6: the quick menu's name as one pool string, built on first use and never destroyed (no pool release at exit).
	const RE::BSFixedString& QmFavName()
	{
		static const RE::BSFixedString* const s_name = new RE::BSFixedString("FavoritesMenu");
		return *s_name;
	}

	std::filesystem::path QmDir()
	{
		return MsglogHorizonDir();
	}

	bool QmMarkerPresent()
	{
		std::error_code ec;
		return std::filesystem::exists(HzDir() / "modules" / "quickmenu.marker", ec);
	}

	bool QmConflictPresent()
	{
		for (int i = 0; hzqs::ConflictDllNames[i]; ++i) {
			if (::GetModuleHandleA(hzqs::ConflictDllNames[i])) return true;
		}
		return false;
	}

	void QmDetectOnce()
	{
		const bool conf = QmConflictPresent();
		const bool mod = QmMarkerPresent();
		g_qmConflict.store(conf, std::memory_order_release);
		g_qmModule.store(mod, std::memory_order_release);
		if (conf && !g_qmConflictLogged) {
			g_qmConflictLogged = true;
			REX::INFO("quick menu: Extended Mode locked, another extended-favorites plugin is loaded");
		}
		g_qmHudPush.store(true, std::memory_order_release);
	}

	int QmVkOf(const std::string& a_name);

	// Settings change only (ini load, F11 save, ADD SLOT): resolve keys to VK codes once.
	void QmCacheSettings(const hzqs::Settings& a_set)
	{
		for (int i = 0; i < 12; ++i)
			g_qmVk[i].store(a_set.key[i].empty() ? 0 : QmVkOf(a_set.key[i]), std::memory_order_relaxed);
		g_qmVisCount.store(hzqs::ClampCount(a_set.slotCount), std::memory_order_relaxed);
		g_qmExtOn.store(a_set.extended, std::memory_order_release);
	}

	void QmLoadSettingsFromText(const std::string& a_text)
	{
		hzqs::Settings set;
		{
			std::lock_guard lk(g_qmMu);
			g_qmSet = hzqs::ParseIniText(a_text);
			set = g_qmSet;
		}
		QmCacheSettings(set);
		g_qmSetGen.fetch_add(1, std::memory_order_acq_rel);
		g_qmHudPush.store(true, std::memory_order_release);
	}

	// Any thread, no file I/O: records the character. The file read happens on the job thread (QmFlushStore).
	hzlog::Character        g_qmLoadChar{};
	std::atomic<bool>       g_qmLoadReq{false};

	void QmLoadStoreFor(const hzlog::Character& a_ch)
	{
		std::lock_guard lk(g_qmMu);
		if (!hzqs::CanWriteStore(a_ch)) {
			// player ID unknown: never bind, never write. A store already bound to a real
			// character is handed to the job thread for a final write, and the live store
			// starts empty and memory-only so the next character cannot see or edit those slots.
			if (hzqs::MustParkBoundStore(g_qmStore)) {
				if (g_qmStoreDirty.load(std::memory_order_relaxed)) {
					g_qmParked.Park(g_qmStore);
					g_qmStoreDirty.store(false, std::memory_order_release);
				}
				hzqs::ResetToUnknownCharacter(g_qmStore, a_ch);
				g_qmStoreLast.clear();
			} else {
				hzqs::ApplyUnknownCharacter(g_qmStore, a_ch);
			}
			// Cancel an in-flight file load (unknown-ID during a pending read of another character).
			g_qmLoadReq.store(false, std::memory_order_release);
			++g_qmLoadGen;
			return;
		}
		if (g_qmStore.character.key == a_ch.key && !g_qmLoadReq.load(std::memory_order_acquire)) {
			return;  // same character, already loaded (or loading)
		}
		g_qmLoadChar = a_ch;
		++g_qmLoadGen;
		g_qmLoadReq.store(true, std::memory_order_release);
	}

	// g_qmStoreLast is shared by the UI (assign) and job (flush / load) threads: always under g_qmMu.
	void QmMarkStoreDirty()
	{
		std::lock_guard lk(g_qmMu);
		auto now = hzqs::WriteStore(g_qmStore);
		if (now == g_qmStoreLast) return;
		g_qmStoreLast = std::move(now);
		g_qmStoreDirty.store(true, std::memory_order_release);
	}

	// Job thread: absorb a dirty live store into the per-character park set, write pending parks
	// (cleared by generation), then read a requested character's file.
	// S-6: a failed write is retried after a capped backoff (2 s doubling to 30 s), logged once, never per poll.
	// N-9: slots assigned while the store was memory-only fill the empty slots of the character's file.
	// S-D / N-g / S-F: every outgoing bound store is parked (one entry per character). A failed write is
	// re-parked. A load uses a same-character parked copy instead of a stale file. An in-flight load is
	// applied only when its generation still matches.
	void QmFlushStore()
	{
		static std::uint64_t s_backoff = 0;    // job thread only
		static std::uint64_t s_nextTry = 0;
		static bool s_failLogged = false;
		std::uint64_t ignoreBackoffUntilGen = 0;
		{
			std::lock_guard lk(g_qmMu);
			if (g_qmStoreDirty.load(std::memory_order_relaxed) && hzqs::CanWriteStore(g_qmStore.character)) {
				const bool switchOut = g_qmLoadReq.load(std::memory_order_relaxed)
					&& hzqs::MustFlushBeforeLoad(g_qmStore.character, g_qmLoadChar);
				const auto gen = g_qmParked.Park(g_qmStore);
				g_qmStoreDirty.store(false, std::memory_order_release);
				if (switchOut) ignoreBackoffUntilGen = gen;
			}
		}
		auto pending = []() {
			std::lock_guard lk(g_qmMu);
			return g_qmParked.Pending();
		}();
		if (!pending.empty()) {
			const auto now = GetTickCount64();
			for (const auto& item : pending) {
				const bool ignore = ignoreBackoffUntilGen && item.gen == ignoreBackoffUntilGen;
				if (now >= s_nextTry || ignore) {
				{
					std::lock_guard lk(g_qmMu);
					if (!g_qmParked.ShouldWrite(item.store.character.key, item.gen)) continue;
				}
				if (!hzqs::CanWriteStore(item.store.character)) {
					std::lock_guard lk(g_qmMu);
					g_qmParked.ClearGen(item.store.character.key, item.gen);
					continue;
				}
				if (hzqs::WriteStoreFile(QmDir(), item.store, HzfReplace)) {
					std::lock_guard lk(g_qmMu);
					g_qmParked.ClearGen(item.store.character.key, item.gen);
					if (s_failLogged) REX::INFO("quick menu: slot file write recovered");
					s_backoff = 0;
					s_nextTry = 0;
					s_failLogged = false;
				} else {
					{
						std::lock_guard lk(g_qmMu);
						g_qmParked.ReparkFailed(item.store, item.gen);
					}
					s_backoff = hzqs::NextWriteBackoffMs(s_backoff);
					s_nextTry = now + s_backoff;
					if (!s_failLogged) {
						s_failLogged = true;
						REX::WARN("quick menu: slot file write failed, retrying with a backoff up to 30 s");
					}
					break;
				}
				}
			}
		}
		if (g_qmLoadReq.load(std::memory_order_acquire)) {
			hzlog::Character ch;
			std::uint64_t gen = 0;
			{
				std::lock_guard lk(g_qmMu);
				ch = g_qmLoadChar;
				gen = g_qmLoadGen;
			}
			auto st = hzqs::ReadStoreFile(QmDir(), ch.key);  // outside the lock
			st.character = ch;
			const auto body = hzqs::WriteStore(st);
			bool merged = false;
			bool overlaid = false;
			{
				std::lock_guard lk(g_qmMu);
				if (hzqs::ShouldApplyLoad(ch, gen, g_qmLoadChar, g_qmLoadGen, g_qmLoadReq.load(std::memory_order_relaxed))) {
					overlaid = g_qmParked.OverlayFile(st, ch);
					if (hzqs::ShouldMergeMemorySlots(g_qmStore)) merged = hzqs::MergeMemorySlots(st, g_qmStore);
					g_qmStore = std::move(st);
					g_qmStoreLast = (merged || overlaid) ? hzqs::WriteStore(g_qmStore) : body;
					g_qmLoadReq.store(false, std::memory_order_release);
					if (merged && hzqs::CanWriteStore(g_qmStore.character)) {
						g_qmParked.Park(g_qmStore);
						g_qmStoreDirty.store(false, std::memory_order_release);
					}
				}
			}
		}
	}

	int QmVkOf(const std::string& a_name)
	{
		const auto sc = KeyNameToScan(a_name);
		if (!sc) return 0;
		return static_cast<int>(MapVirtualKeyW(sc > 0x7F ? (0xE000 | (sc & 0x7F)) : sc, MAPVK_VSC_TO_VK_EX));
	}

	// 1 = every ID resolves, 0 = address library still loading (try later), -1 = an ID is missing.
	static int QmIdsReady(std::initializer_list<std::uint64_t> a_ids)
	{
		for (const auto id : a_ids) {
			if (id == 0) return -1;
			const int slot = HzAddrSlot(id);
			if (hzaddr::AddrSlotRetry(slot)) return 0;
			if (hzaddr::AddrSlotMiss(slot)) return -1;
		}
		return 1;
	}

	// Game-thread read of the keyboard keys mapped in the main gameplay context (virtual-key codes).
	struct QmCtlIo
	{
		int           ok = 0;
		std::uint32_t vk[8]{};  // 256-bit set
	};

	static void QmCtlCall(QmCtlIo* io)
	{
		if (!io) return;
		io->ok = 0;
		auto* cm = RE::ControlMap::GetSingleton();
		if (!cm) { io->ok = -1; return; }
		const auto maps = cm->GetMappings(RE::UserEvents::INPUT_CONTEXT_ID::kMainGameplay, RE::InputEvent::DeviceType::kKeyboard);
		for (const auto& m : maps) {
			if (m.keyCode > 0 && m.keyCode < 256) io->vk[m.keyCode >> 5] |= 1u << (m.keyCode & 31);
		}
		io->ok = 1;
	}

#if defined(_MSC_VER)
	static int QmCtlSEH(QmCtlIo* io) noexcept
	{
		if (!io) return 0;
		using Fn = void (*)(QmCtlIo*);
		Fn fn = &QmCtlCall;
		__try { fn(io); return 1; }
		__except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
	}
#else
	static int QmCtlSEH(QmCtlIo* io) noexcept
	{
		if (!io) return 0;
		try { QmCtlCall(io); return 1; } catch (...) { return 0; }
	}
#endif

	// Returns false when the control map could not be read (caller keeps the conservative set).
	static bool QmGameVks(QmCtlIo& a_out)
	{
		if (QmIdsReady({ RE::ID::ControlMap::Singleton.id() }) != 1) return false;
		if (!QmCtlSEH(&a_out) || a_out.ok != 1) return false;
		return true;
	}

	static bool QmVkIn(const QmCtlIo& a_set, int a_vk)
	{
		return a_vk > 0 && a_vk < 256 && (a_set.vk[a_vk >> 5] & (1u << (a_vk & 31))) != 0;
	}

	// UseHooks::keyBoundByGame. Game thread (HUD / menu advance). The F11 settings key always counts.
	bool QmKeyBoundByGame(std::string_view a_key, void*)
	{
		const auto k = hzqs::CanonKey(a_key);
		if (k.empty()) return false;
		const int vk = QmVkOf(std::string(k));
		if (!vk) return false;
		if (vk == g_vk.load()) return true;
		QmCtlIo io{};
		if (QmGameVks(io)) return QmVkIn(io, vk);
		// control map unreadable: conservative reserved set (movement / action keys, F5, F9 and every F-key)
		return hzqs::FallbackReservedKey(k);
	}

	// HUD thread, once per settings change: decide which slot keys are refused, log each refusal once.
	void QmRecomputeKeyBlock()
	{
		const auto gen = g_qmSetGen.load(std::memory_order_acquire);
		if (gen == g_qmBlockGen) return;
		hzqs::Settings set;
		{
			std::lock_guard lk(g_qmMu);
			set = g_qmSet;
		}
		QmCtlIo io{};
		const bool haveMap = QmGameVks(io);
		if (!haveMap && QmIdsReady({ RE::ID::ControlMap::Singleton.id() }) == 0) return;  // address library loading
		if (!haveMap && !g_qmCtlMissLogged) {
			g_qmCtlMissLogged = true;
			REX::INFO("quick menu: control map not readable, slot keys checked against a reserved list");
		}
		std::uint32_t mask = 0;
		for (int i = 0; i < 12; ++i) {
			const auto& name = set.key[i];
			if (name.empty()) continue;
			const int vk = QmVkOf(name);
			const char* why = nullptr;
			if (!vk) why = "unknown key";
			else if (vk == g_vk.load()) why = "the Horizon settings key";
			else if (haveMap ? QmVkIn(io, vk) : QmKeyBoundByGame(name, nullptr)) why = "bound in the game's controls";
			else {
				for (int j = 0; j < i; ++j) {
					if (set.key[j] == name) { why = "already used by another extended slot"; break; }
				}
			}
			if (why) {
				mask |= 1u << i;
				REX::INFO("quick menu: slot {} key {} ignored ({})", hzqs::kExtFirst + i, name, why);
			}
		}
		g_qmKeyBlock.store(mask, std::memory_order_release);
		g_qmBlockGen = gen;
	}

	// ---- equip / use wrappers (Address Library IDs, SEH, fail safe) ----
	struct QmUseIo
	{
		int             ok = 0;
		std::uint32_t   formId = 0;
		int             kind = 0;     // 0 inventory, 1 power, 2 essence
		int             has = 0;
		int             used = 0;
	};

	static std::uint32_t QmFormIdOf(RE::TESForm* a_form)
	{
		return a_form ? static_cast<std::uint32_t>(a_form->GetFormID()) : 0;
	}

	// N-12: the RTTI IDs starfield_cast needs, checked once (they resolve on 1.16.244).
	static bool QmRttiOk()
	{
		static std::atomic<int> s_ok{0};  // 0 unknown, 1 ok, -1 missing
		const int v = s_ok.load(std::memory_order_relaxed);
		if (v != 0) return v > 0;
		const int rd = QmIdsReady({ hzqs::kIdRttiTESForm, hzqs::kIdRttiTESFullName });
		if (rd != 0) s_ok.store(rd > 0 ? 1 : -1, std::memory_order_relaxed);
		return rd > 0;
	}

	// Display name (what the quick menu and inventory show), editor ID only as a last resort.
	static const char* QmFormName(RE::TESForm* a_form)
	{
		if (!a_form) return "";
		if (QmRttiOk()) {
			if (auto* full = starfield_cast<RE::TESFullName*>(a_form)) {
				const char* n = full->GetFullName();
				if (n && n[0]) return n;
			}
		}
		const char* ed = a_form->GetFormEditorID();
		return ed ? ed : "";
	}

	// ---- S-5 / S-C: inventory access. The player's list lock is the game's own RAII guard, taken in a plain
	// C++ function. The walk runs inside an SEH-only thunk (no C++ objects), so a fault is caught inside it and
	// the guard still unlocks on the normal return. Only plain fields are read under the lock (no virtual calls).
	struct QmInvEntry
	{
		RE::TESBoundObject* obj = nullptr;
		std::uint32_t       formId = 0;
		std::uint32_t       idx = 0;     // index in the player's inventory list (the agent's listIndex)
		std::int32_t        count = 0;
	};
	constexpr int kQmInvCap = 1024;  // default reserved heap capacity; not a TLS array
	struct QmInvSnap
	{
		int           n = 0;
		std::uint32_t owner = 0;
		QmInvEntry*   e = nullptr;
	};
	struct QmInvCopyIo
	{
		QmInvEntry*   dst = nullptr;
		int           cap = 0;
		int           n = 0;
		bool          more = false;
		std::uint32_t owner = 0;
	};

	static void QmInvCopy(const RE::BGSInventoryList* a_list, QmInvCopyIo* a_io)
	{
		a_io->n = 0;
		a_io->more = false;
		a_io->owner = a_list->ownerHandle;
		std::uint32_t i = 0;
		for (auto& it : a_list->data) {
			const std::uint32_t idx = i++;
			if (!it.object) continue;
			if (a_io->n >= a_io->cap) { a_io->more = true; break; }
			std::int32_t c = 0;
			for (auto& stk : it.stacks) c += static_cast<std::int32_t>(stk.count);
			auto& e = a_io->dst[a_io->n++];
			e.obj = it.object;
			e.formId = QmFormIdOf(it.object);
			e.idx = idx;
			e.count = c;
		}
	}

#if defined(_MSC_VER)
	static int QmInvCopySEH(const RE::BGSInventoryList* a_list, QmInvCopyIo* a_io) noexcept
	{
		using Fn = void (*)(const RE::BGSInventoryList*, QmInvCopyIo*);
		Fn fn = &QmInvCopy;
		__try { fn(a_list, a_io); return 1; }
		__except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
	}
#else
	static int QmInvCopySEH(const RE::BGSInventoryList* a_list, QmInvCopyIo* a_io) noexcept
	{
		try { QmInvCopy(a_list, a_io); return 1; } catch (...) { return 0; }
	}
#endif

	// Match-mode walk (S-C): compare form IDs only, exit on the first match, no stack sum, no cap.
	// Used on the key-press / click use path. Same lock pattern as the snapshot.
	struct QmInvFindIo
	{
		std::uint32_t formId = 0;
		std::uint32_t owner = 0;
		int           listIdx = -1;
		bool          found = false;
	};

	static void QmInvFindWalk(const RE::BGSInventoryList* a_list, QmInvFindIo* a_io)
	{
		a_io->owner = a_list->ownerHandle;
		a_io->found = false;
		a_io->listIdx = -1;
		std::uint32_t i = 0;
		for (auto& it : a_list->data) {
			const std::uint32_t idx = i++;
			if (!it.object) continue;
			if (QmFormIdOf(it.object) == a_io->formId) {
				a_io->listIdx = static_cast<int>(idx);
				a_io->found = true;
				return;
			}
		}
	}

#if defined(_MSC_VER)
	static int QmInvFindSEH(const RE::BGSInventoryList* a_list, QmInvFindIo* a_io) noexcept
	{
		using Fn = void (*)(const RE::BGSInventoryList*, QmInvFindIo*);
		Fn fn = &QmInvFindWalk;
		__try { fn(a_list, a_io); return 1; }
		__except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
	}
#else
	static int QmInvFindSEH(const RE::BGSInventoryList* a_list, QmInvFindIo* a_io) noexcept
	{
		try { QmInvFindWalk(a_list, a_io); return 1; } catch (...) { return 0; }
	}
#endif

	// hasItem then useInventory run back-to-back on the HUD thread: the first fill is reused by the second,
	// so a press does one walk, not two. Invalidated at the start of has and at the end of use.
	// N-l: every per-thread buffer lives behind one lazily created heap object, so the DLL's static TLS
	// stays close to the 0.43.4 size. The pointer is freed when the thread exits.
	struct QmThreadState
	{
		QmInvFindIo                find{};
		bool                       findOk = false;
		QmInvSnap                  snap{};
		std::vector<QmInvEntry>    extra;  // reserved, reused; never shrinks
		std::string                ret;
	};
	struct QmTlsOwner
	{
		QmThreadState* p = nullptr;
		~QmTlsOwner() { delete p; }
	};
	static thread_local QmTlsOwner t_qmTls;

	static QmThreadState* QmTlsPtr() { return t_qmTls.p; }

	static QmThreadState& QmTls()
	{
		if (!t_qmTls.p) t_qmTls.p = new QmThreadState();
		return *t_qmTls.p;
	}

	static void QmInvFindReset()
	{
		if (auto* s = QmTlsPtr()) s->findOk = false;
	}

	// N-j: reset the same-thread cache on every exit of QmUseCall, including early returns.
	// An SEH fault does not unwind C++ objects, so QmUseSEH also resets in its handler.
	struct QmInvFindScopeGuard
	{
		~QmInvFindScopeGuard() { QmInvFindReset(); }
	};

	static bool QmInvFind(RE::PlayerCharacter* a_pc, std::uint32_t a_formId, QmInvFindIo& a_out)
	{
		auto& tls = QmTls();
		if (tls.findOk && tls.find.formId == a_formId) {
			a_out = tls.find;
			return true;
		}
		a_out = {};
		a_out.formId = a_formId;
		if (!a_pc) return false;
		{
			auto listG = a_pc->inventoryList.LockRead();
			const RE::BGSInventoryList* list = *listG;
			if (!list) { tls.find = a_out; tls.findOk = true; return true; }
			if (QmInvFindSEH(list, &a_out) != 1) { tls.findOk = false; return false; }
		}
		tls.find = a_out;
		tls.findOk = true;
		return true;
	}

	// Open / assign path: one snapshot of every stack (counts included). The buffer is a lazily
	// created heap-backed vector on the calling thread (S-E: no 1,024-entry TLS array). Size is
	// read under a short lock, the vector is reserved outside it, then the list is copied once
	// (N-h: no discarded first pass). If the list grows mid-copy, up to 4 retries. Never shrinks.
	static QmInvSnap& QmSnapBuf() { return QmTls().snap; }
	static std::vector<QmInvEntry>& QmSnapVec() { return QmTls().extra; }

	static bool QmInvSnapshot(RE::PlayerCharacter* a_pc, QmInvSnap& a_out)
	{
		a_out.n = 0;
		a_out.owner = 0;
		a_out.e = nullptr;
		if (!a_pc) return false;
		auto& extra = QmSnapVec();
		QmInvCopyIo io{};
		for (int attempt = 0; attempt < 4; ++attempt) {
			std::uint32_t need = 0;
			{
				auto listG = a_pc->inventoryList.LockRead();
				const RE::BGSInventoryList* list = *listG;
				if (!list) return true;
				need = list->data.size();
			}
			if (need < static_cast<std::uint32_t>(kQmInvCap))
				need = static_cast<std::uint32_t>(kQmInvCap);
			if (extra.capacity() < need) extra.reserve(need + 64);
			extra.resize(extra.capacity());
			io = {};
			io.dst = extra.data();
			io.cap = static_cast<int>(extra.size());
			{
				auto listG = a_pc->inventoryList.LockRead();
				const RE::BGSInventoryList* list = *listG;
				if (!list) { a_out.n = 0; a_out.e = extra.data(); return true; }
				if (QmInvCopySEH(list, &io) != 1) return false;
				a_out.owner = io.owner;
			}
			if (!io.more) {
				a_out.e = extra.data();
				a_out.n = io.n;
				return true;
			}
		}
		static bool s_snapCapLogged = false;
		if (!s_snapCapLogged) {
			s_snapCapLogged = true;
			REX::WARN("quick menu: inventory snapshot reached its retry limit, some items may not show");
		}
		a_out.e = extra.data();
		a_out.n = io.n;
		return true;
	}

	// ---- S-1: the inventory agent list is guarded by the game's critical section (ID 888731). Copy at most 8
	// matching handle IDs under it, release it, and only then call into the game. Never call the game while
	// holding it (the game leaves it before taking a ref's inventory lock).
	struct QmAgentIo
	{
		std::uint32_t owner = 0;
		int           listIdx = -1;
		int           n = 0;
		std::uint32_t ids[8]{};
	};

	static void QmAgentCopy(const RE::BGSInventoryInterface* a_inv, QmAgentIo* a_io)
	{
		a_io->n = 0;
		const auto& arr = a_inv->agentArray;
		const auto n = arr.size();          // size and data read once
		const auto* d = n ? arr.data() : nullptr;
		for (std::uint32_t i = 0; d && i < n && a_io->n < 8; ++i) {
			const auto& ag = d[i];
			if (ag.handleID == 0 || ag.itemOwner != a_io->owner || static_cast<int>(ag.listIndex) != a_io->listIdx) continue;
			a_io->ids[a_io->n++] = ag.handleID;
		}
	}

#if defined(_MSC_VER)
	static int QmAgentCopySEH(const RE::BGSInventoryInterface* a_inv, QmAgentIo* a_io) noexcept
	{
		using Fn = void (*)(const RE::BGSInventoryInterface*, QmAgentIo*);
		Fn fn = &QmAgentCopy;
		__try { fn(a_inv, a_io); return 1; }
		__except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
	}
#else
	static int QmAgentCopySEH(const RE::BGSInventoryInterface* a_inv, QmAgentIo* a_io) noexcept
	{
		try { QmAgentCopy(a_inv, a_io); return 1; } catch (...) { return 0; }
	}
#endif

	// a_locked: ID 888731 resolved. Otherwise the copy runs unlocked (one read of size and data) inside SEH.
	static bool QmAgentCollect(const RE::BGSInventoryInterface* a_inv, QmAgentIo& a_io, bool a_locked)
	{
		CRITICAL_SECTION* cs = nullptr;
		if (a_locked) {
			static const std::uintptr_t s_cs = REL::ID(hzqs::kIdInventoryAgentLock).address();
			cs = reinterpret_cast<CRITICAL_SECTION*>(s_cs);
		}
		if (cs) ::EnterCriticalSection(cs);
		const int ok = QmAgentCopySEH(a_inv, &a_io);   // the fault (if any) is caught inside: Leave always runs
		if (cs) ::LeaveCriticalSection(cs);
		return ok == 1;
	}

	// ---- M-1: GetInventoryObjectSub (ID 63846) writes 16 bytes: the object pointer and a ref-counted
	// instance-data smart pointer. The pinned BGSInventoryInterface::GetInventoryObject gives it an 8-byte slot.
	// This local wrapper (same shape as the QTR-Modding fork's fix, d3f4950) gives it the full 16 bytes and
	// releases the instance-data reference when `obj` leaves scope.
	struct QmInvObject
	{
		RE::TESBoundObject*                      object{};
		RE::BSTSmartPointer<RE::TBO_InstanceData> instanceData{};
	};
	static_assert(sizeof(QmInvObject) == 0x10);
	struct QmInvObjectResult
	{
		QmInvObject*  object;
		std::uint64_t unk08;
	};

	static std::uint32_t QmInvObjectFormId(const RE::BGSInventoryInterface* a_inv, std::uint32_t a_handleID)
	{
		std::uint32_t handle = a_handleID;
		QmInvObject obj;
		QmInvObjectResult res{ &obj, 0 };
		QmInvObjectResult* resPtr = &res;
		using Fn = bool (*)(const RE::BGSInventoryInterface*, const std::uint32_t*, QmInvObjectResult**);
		static REL::Relocation<Fn> fn{ REL::ID(static_cast<std::uint64_t>(hzqs::kIdInventoryGetObjectSub)) };
		fn(a_inv, &handle, &resPtr);
		return QmFormIdOf(obj.object);  // copied before obj (and its instance-data reference) is released
	}

	static void QmUseCall(QmUseIo* io)
	{
		if (!io) return;
		QmInvFindScopeGuard guard;
		io->ok = 0;
		io->has = 0;
		io->used = 0;
		auto* pc = RE::PlayerCharacter::GetSingleton();
		if (!pc) { io->ok = -1; return; }
		auto* form = RE::TESForm::LookupByID(io->formId);
		if (!form) { io->ok = -2; return; }

		if (io->kind == 1) {
			const int rd = QmIdsReady({ hzqs::kIdUseSpell });
			if (rd == 0) { io->ok = 0; return; }
			if (rd < 0) { io->ok = -3; return; }
			auto* spell = form->As<RE::SpellItem>();
			if (!spell) { io->ok = -4; return; }
			io->has = 1;
			using Fn = void (*)(RE::Actor*, RE::SpellItem*);
			static REL::Relocation<Fn> func{ REL::ID(static_cast<std::uint64_t>(hzqs::kIdUseSpell)) };
			func(pc, spell);
			io->used = 1;
			io->ok = 1;
			return;
		}

		// inventory (and essence fallback into inventory)
		const int rd = QmIdsReady({ hzqs::kIdUseInventoryItem, hzqs::kIdInventorySingleton, hzqs::kIdInventoryGetObjectSub,
			RE::ID::ActorEquipManager::Singleton.id() });
		if (rd == 0) { io->ok = 0; return; }
		if (rd < 0) { io->ok = -3; return; }
		const int rdLock = QmIdsReady({ hzqs::kIdInventoryAgentLock });
		if (rdLock == 0) { io->ok = 0; return; }   // address library still loading
		auto* inv = RE::BGSInventoryInterface::GetSingleton();
		if (!inv) { io->ok = -5; return; }

		// The player's own stack: first match only (S-C), lock released before anything else runs.
		// UseInventoryItem takes the list lock itself. Reuses the hasItem walk when it just ran.
		QmInvFindIo found{};
		if (!QmInvFind(pc, io->formId, found)) { io->ok = -9; return; }
		if (!found.found) { io->ok = 2; return; }  // missing
		io->has = 1;

		// The live handle the game made for that stack (same owner, same list index, same base object).
		// No handle = the game has not opened an agent for it yet; leave it unused (never guess another owner's).
		QmAgentIo ag;
		ag.owner = found.owner;
		ag.listIdx = found.listIdx;
		if (!QmAgentCollect(inv, ag, rdLock == 1)) { io->ok = -10; return; }
		RE::InventoryInterface::Handle handle{};
		bool haveHandle = false;
		for (int k = 0; k < ag.n && !haveHandle; ++k) {
			if (QmInvObjectFormId(inv, ag.ids[k]) == io->formId) {   // re-resolved under the game's own lock
				handle.id = ag.ids[k];
				haveHandle = true;
			}
		}
		if (!haveHandle) { io->ok = -6; return; }

		using UseFn = bool (*)(RE::ActorEquipManager*, RE::Actor*, const RE::InventoryInterface::Handle*, std::uint8_t, bool, bool, bool);
		static REL::Relocation<UseFn> useFn{ REL::ID(static_cast<std::uint64_t>(hzqs::kIdUseInventoryItem)) };
		auto* mgr = RE::ActorEquipManager::GetSingleton();
		if (!mgr) { io->ok = -7; return; }
		// Arguments match vanilla FavoritesManager::UseQuickkey (1.16.244, call at RVA 0x1EBF655): 4th = 0 (unused by
		// the callee, its home slot holds the function's own result), allowUnequip = false (no unequip toggle),
		// then false, true.
		const bool ok = useFn(mgr, pc, &handle, 0, false, false, true);
		io->used = ok ? 1 : 0;
		io->ok = ok ? 1 : -8;
	}

#if defined(_MSC_VER)
	// A fault inside a game function that already holds 888731 or the inventory lock is caught here
	// and that game lock stays held (the same residual as every other SEH-wrapped game call).
	static int QmUseSEH(QmUseIo* io) noexcept
	{
		if (!io) return 0;
		using Fn = void (*)(QmUseIo*);
		Fn fn = &QmUseCall;
		__try { fn(io); return 1; }
		__except (EXCEPTION_EXECUTE_HANDLER) { QmInvFindReset(); return 0; }
	}
#else
	static int QmUseSEH(QmUseIo* io) noexcept
	{
		if (!io) return 0;
		try { QmUseCall(io); return 1; } catch (...) { QmInvFindReset(); return 0; }
	}
#endif

	static void QmHasCall(QmUseIo* io)
	{
		if (!io) return;
		io->ok = 0;
		io->has = 0;
		auto* pc = RE::PlayerCharacter::GetSingleton();
		if (!pc) { io->ok = -1; return; }
		if (io->kind == 1) {
			auto* form = RE::TESForm::LookupByID(io->formId);
			io->has = form && form->As<RE::SpellItem>() ? 1 : 0;
			io->ok = 1;
			return;
		}
		QmInvFindReset();  // start of the has+use pair: one walk, reused by QmUseCall
		QmInvFindIo found{};
		if (!QmInvFind(pc, io->formId, found)) return;  // ok stays 0
		io->has = found.found ? 1 : 0;
		io->ok = 1;
	}

#if defined(_MSC_VER)
	static int QmHasSEH(QmUseIo* io) noexcept
	{
		if (!io) return 0;
		using Fn = void (*)(QmUseIo*);
		Fn fn = &QmHasCall;
		__try { fn(io); return 1; }
		__except (EXCEPTION_EXECUTE_HANDLER) { return 0; }
	}
#else
	static int QmHasSEH(QmUseIo* io) noexcept
	{
		if (!io) return 0;
		try { QmHasCall(io); return 1; } catch (...) { return 0; }
	}
#endif

	bool QmHookModule(void*) { return g_qmModule.load(std::memory_order_acquire); }
	bool QmHookConflict(void*) { return g_qmConflict.load(std::memory_order_acquire); }
	bool QmHookBlocked(void* a_ctx)
	{
		if (g_swallow.load(std::memory_order_acquire)) return true;
		if (a_ctx) return false;  // a click in the quick menu: the menu itself was the gate
		auto ui = RE::UI::GetSingleton();
		if (!ui) return true;
		if (TextMenuOpen(ui)) return true;
		if (!HudMenusClear(ui, false)) return true;
		return false;
	}
	bool QmHookHas(std::uint32_t formId, hzqs::Kind kind, void*)
	{
		QmUseIo io{};
		io.formId = formId;
		io.kind = static_cast<int>(kind);
		if (!QmHasSEH(&io) || io.ok != 1) return false;
		return io.has == 1;
	}
	bool QmHookUseInv(std::uint32_t formId, void*)
	{
		QmUseIo io{};
		io.formId = formId;
		io.kind = 0;
		if (!QmUseSEH(&io)) {
			if (!g_qmUseMissLogged) {
				g_qmUseMissLogged = true;
				REX::WARN("quick menu: UseInventoryItem failed, left unused");
			}
			return false;
		}
		if (io.ok == -6 && !g_qmNoHandleLogged) {
			g_qmNoHandleLogged = true;
			REX::INFO("quick menu: no live inventory handle for {:08X}, left unused", formId);
		}
		return io.ok == 1 && io.used == 1;
	}
	bool QmHookUsePower(std::uint32_t formId, void*)
	{
		QmUseIo io{};
		io.formId = formId;
		io.kind = 1;
		if (!QmUseSEH(&io)) {
			if (!g_qmUseMissLogged) {
				g_qmUseMissLogged = true;
				REX::WARN("quick menu: UseSpell failed, left unused");
			}
			return false;
		}
		return io.ok == 1 && io.used == 1;
	}
	// S-3: the stored form ID must still name the stored item (a load-order change can point it at another form).
	// A form that no longer exists is left to hasItem (Missing, slot kept: the plugin may come back).
	bool QmHookStale(const hzqs::Assignment& a, void*)
	{
		auto* form = RE::TESForm::LookupByID(a.formId);
		if (!form) return false;
		return hzqs::AssignmentStale(a, QmFormName(form), form->IsBoundObject());
	}
	// S-B: clear only when the form is no longer an inventory object, never on a name-only mismatch.
	bool QmHookClears(const hzqs::Assignment& a, void*)
	{
		auto* form = RE::TESForm::LookupByID(a.formId);
		if (!form) return false;
		return hzqs::AssignmentClears(a, QmFormName(form), form->IsBoundObject());
	}
	// N-i: a name-only mismatch (the slot is kept). Used by the payload to mark the tile refused.
	bool QmHookRefuses(const hzqs::Assignment& a, void*)
	{
		auto* form = RE::TESForm::LookupByID(a.formId);
		if (!form) return false;
		return hzqs::AssignmentCheck(a, QmFormName(form), form->IsBoundObject()) == hzqs::SlotCheck::Refuse;
	}
	bool QmHookUseEssence(std::uint32_t formId, void*)
	{
		// No public ActivateEssence ID in the pin. Try inventory, then power, in UseExtendedSlot.
		(void)formId;
		return false;
	}

	hzqs::UseHooks QmHooks()
	{
		hzqs::UseHooks h;
		h.moduleInstalled = &QmHookModule;
		h.conflictModFound = &QmHookConflict;
		h.inputBlocked = &QmHookBlocked;
		h.hasItem = &QmHookHas;
		h.useInventory = &QmHookUseInv;
		h.usePower = &QmHookUsePower;
		h.useEssence = &QmHookUseEssence;
		h.keyBoundByGame = &QmKeyBoundByGame;
		h.formStale = &QmHookStale;
		return h;
	}

	// S-3: clear a slot whose form ID now names a different item (only if it still holds that form ID).
	void QmClearStale(int a_slot, std::uint32_t a_formId)
	{
		bool cleared = false;
		{
			std::lock_guard lk(g_qmMu);
			if (const auto* a = hzqs::FindSlot(g_qmStore, a_slot); a && a->formId == a_formId) {
				hzqs::ClearSlot(g_qmStore, a_slot);
				cleared = true;
			}
		}
		if (cleared) {
			REX::INFO("quick menu: slot {} cleared, its item changed after a load-order change", a_slot);
			QmMarkStoreDirty();
		}
	}

	void QmRunUse(int a_slot, bool a_fromMenu)
	{
		hzqs::Settings set;
		hzqs::Store st;
		{
			std::lock_guard lk(g_qmMu);
			set = g_qmSet;
			st = g_qmStore;
		}
		auto hooks = QmHooks();
		static int s_menuTag = 1;
		hooks.ctx = a_fromMenu ? static_cast<void*>(&s_menuTag) : nullptr;
		const auto r = hzqs::UseExtendedSlot(set, st, a_slot, hooks);
		if (r == hzqs::UseResult::Stale) {
			if (const auto* a = hzqs::FindSlot(st, a_slot); a && QmHookClears(*a, nullptr))
				QmClearStale(a_slot, a->formId);
		}
		// log a slot's result only when it changes (no line per key press)
		auto& last = g_qmLastResult[a_slot - hzqs::kExtFirst];
		const int code = static_cast<int>(r) + 1;
		if (code != last) {
			last = code;
			if (r != hzqs::UseResult::Ok)
				REX::INFO("quick menu: use slot {} {}", a_slot, hzqs::ResultName(r));
		}
	}

	// HUD thread: when the store is still memory-only (player ID unknown at HUD ready, message log off),
	// retry the per-character load every 2 s. Only while Extended Mode is on.
	void QmLazyStore()
	{
		if (!g_qmExtOn.load(std::memory_order_acquire) || g_qmLoadReq.load(std::memory_order_acquire)) return;
		const auto now = GetTickCount64();
		if (now - g_qmStoreTry < 2000) return;  // time gate first: no lock on ordinary frames
		g_qmStoreTry = now;
		bool need = false;
		{
			std::lock_guard lk(g_qmMu);
			need = !hzqs::CanWriteStore(g_qmStore.character);
		}
		if (!need) return;
		MsglogRefreshEngine(false);
		const auto eng = MsglogEngSnap();
		if (eng.playerId == 0) return;
		QmLoadStoreFor(hzlog::MakeCharacter(eng.playerId, eng.name));
	}

	// Called from the HUD AdvanceFrame so UseInventoryItem / UseSpell run on that path.
	void QmHudTick()
	{
		if (g_qmHudPush.exchange(false, std::memory_order_acq_rel)) {
			GValue arg(g_qmConflict.load(std::memory_order_acquire) ? 1.0 : 0.0);
			HudInvoke("hzQmSetConflict", nullptr, &arg, 1, true);
			int count = 24;
			{
				std::lock_guard lk(g_qmMu);
				count = hzqs::ClampCount(g_qmSet.slotCount);
			}
			GValue c(static_cast<double>(count));
			HudInvoke("hzQmSetSlotCount", nullptr, &c, 1, true);
		}
		if (g_qmMenuOpen.load(std::memory_order_acquire)) {
			// the menu's own advance stops when it closes: one menu-map lookup per HUD frame, only while flagged open
			if (auto ui = RE::UI::GetSingleton(); ui && !ui->IsMenuOpen(QmFavName())) {
				g_qmMenuOpen.store(false, std::memory_order_release);
				g_qmBound.store(false, std::memory_order_release);
			}
		}
		QmRecomputeKeyBlock();
		QmLazyStore();
		const auto req = g_qmUseReq.exchange(0, std::memory_order_acq_rel);
		if (!req) return;
		// S-4: a key press the HUD could not run in time (covering menu, loading screen, pause) is dropped.
		if (!hzqs::UseReqFresh(req, GetTickCount64())) {
			if (!g_qmLateLogged) {
				g_qmLateLogged = true;
				REX::INFO("quick menu: a late slot request was dropped (the HUD was not advancing)");
			}
			return;
		}
		const int code = hzqs::UseReqCode(req);
		const int slot = code & 0xFF;
		if (slot >= hzqs::kExtFirst && slot <= hzqs::kMaxSlots)
			QmRunUse(slot, (code & kQmFromMenu) != 0);
	}

	// Job thread: edge-detect bound keys, queue a use for the HUD path. No Scaleform.
	// S-4: drop a queued key press (not a menu click) while input is blocked.
	static void QmDropKeyReq()
	{
		auto v = g_qmUseReq.load(std::memory_order_acquire);
		if (v && !(hzqs::UseReqCode(v) & kQmFromMenu)) g_qmUseReq.compare_exchange_strong(v, 0, std::memory_order_acq_rel);
	}

	void QmJobKeys(HWND a_wnd)
	{
		if (!g_qmModule.load(std::memory_order_acquire) || g_qmConflict.load(std::memory_order_acquire)) return;
		if (!g_qmExtOn.load(std::memory_order_acquire)) return;
		// S-4: a menu, the loading screen, text entry or an unfocused window: treat every key as held (it must be
		// released and pressed again afterwards) and drop a queued key press. Atomics only, no game calls.
		// N-c: the job poll already called GameWindow(); reuse that HWND (no second user32 round trip).
		if (!a_wnd || g_qmMenuOpen.load(std::memory_order_acquire) || g_swallow.load(std::memory_order_acquire)
			|| g_uiLoading.load(std::memory_order_relaxed)) {
			for (bool& d : g_qmKeyDown) d = true;
			QmDropKeyReq();
			return;
		}
		const int visCount = g_qmVisCount.load(std::memory_order_relaxed);
		const auto block = g_qmKeyBlock.load(std::memory_order_acquire);
		for (int i = 0; i < 12; ++i) {
			const int vk = g_qmVk[i].load(std::memory_order_relaxed);
			if (!vk || (block & (1u << i))) { g_qmKeyDown[i] = false; continue; }
			const bool down = (GetAsyncKeyState(vk) & 0x8000) != 0;
			const bool edge = down && !g_qmKeyDown[i];
			g_qmKeyDown[i] = down;
			if (!edge) continue;
			const int slot = hzqs::kExtFirst + i;
			if (slot > visCount) continue;
			std::uint64_t expected = 0;
			g_qmUseReq.compare_exchange_strong(expected, hzqs::PackUseReq(slot, GetTickCount64()), std::memory_order_acq_rel);
		}
	}

	// UI thread, on an assign click only. S-5: the lock covers a plain copy; names are read after it is released.
	std::uint32_t QmFormByName(const std::string& a_name, hzqs::Kind* a_kind)
	{
		if (a_name.empty() || !a_kind) return 0;
		auto* pc = RE::PlayerCharacter::GetSingleton();
		if (!pc) return 0;
		auto& snap = QmSnapBuf();
		if (!QmInvSnapshot(pc, snap)) return 0;
		std::vector<hzqs::NameId> hits;
		hits.reserve(snap.n > 0 ? static_cast<std::size_t>(snap.n) : 0);
		for (int i = 0; i < snap.n; ++i) {
			const char* n = QmFormName(snap.e[i].obj);
			if (!n || !n[0] || !snap.e[i].formId) continue;
			hits.push_back({ n, snap.e[i].formId });
		}
		const auto found = hzqs::PickFormByDisplayName(a_name, hits.data(), static_cast<int>(hits.size()));
		if (!found) return 0;
		*a_kind = hzqs::Lower(a_name).find("quantum essence") != std::string::npos ? hzqs::Kind::Essence : hzqs::Kind::Inventory;
		return found;
	}

	hzqs::Kind QmKindOfForm(RE::TESForm* a_form)
	{
		if (!a_form) return hzqs::Kind::Inventory;
		if (a_form->As<RE::SpellItem>()) return hzqs::Kind::Power;
		const char* n = QmFormName(a_form);
		if (n && hzqs::Lower(n).find("quantum essence") != std::string::npos) return hzqs::Kind::Essence;
		return hzqs::Kind::Inventory;
	}

	// counts[i] = stack total for ids[i] (0 = skip), from one snapshot (S-5: plain copy under the lock).
	void QmCountMany(const std::uint32_t (&a_ids)[12], std::int32_t (&a_counts)[12])
	{
		auto* pc = RE::PlayerCharacter::GetSingleton();
		if (!pc) return;
		auto& snap = QmSnapBuf();
		if (!QmInvSnapshot(pc, snap)) return;
		for (int i = 0; i < snap.n; ++i) {
			const auto id = snap.e[i].formId;
			for (int k = 0; k < 12; ++k) {
				if (a_ids[k] == id) a_counts[k] += snap.e[i].count;
			}
		}
	}

	std::string QmPayload()
	{
		hzqs::Settings set;
		hzqs::Store st;
		{
			std::lock_guard lk(g_qmMu);
			set = g_qmSet;
			st = g_qmStore;
		}
		std::string o;
		const int n = hzqs::ClampCount(set.slotCount);
		// S-3 / S-B: clear (and show empty) only when the form is no longer an inventory object.
		// N-i: a name-only refuse is sent as a 6th field so the menu can draw the unavailable look.
		bool stale[12]{};
		bool refuse[12]{};
		std::uint32_t staleId[12]{};
		bool anyStale = false;
		for (int i = hzqs::kExtFirst; i <= n; ++i) {
			const auto* a = hzqs::FindSlot(st, i);
			if (!a || !a->formId) continue;
			// N-n: one form lookup / AssignmentCheck per slot (not a separate refuse pass).
			auto* form = RE::TESForm::LookupByID(a->formId);
			if (!form) continue;
			const auto chk = hzqs::AssignmentCheck(*a, QmFormName(form), form->IsBoundObject());
			if (chk == hzqs::SlotCheck::Clear) {
				stale[i - hzqs::kExtFirst] = true;
				staleId[i - hzqs::kExtFirst] = a->formId;
				anyStale = true;
			} else if (chk == hzqs::SlotCheck::Refuse) {
				refuse[i - hzqs::kExtFirst] = true;
			}
		}
		// One inventory snapshot for every assigned slot.
		std::uint32_t ids[12]{};
		std::int32_t counts[12]{};
		for (int i = hzqs::kExtFirst; i <= n; ++i) {
			const auto* a = hzqs::FindSlot(st, i);
			ids[i - hzqs::kExtFirst] = (a && !stale[i - hzqs::kExtFirst] && a->kind == hzqs::Kind::Inventory) ? a->formId : 0;
		}
		QmCountMany(ids, counts);
		o.reserve(static_cast<std::size_t>(n) * 24 + 24);
		// N-4 / N-5 header records: m|<refused key mask>;c|<slot count the DLL uses>
		o += "m|" + std::to_string(g_qmKeyBlock.load(std::memory_order_acquire));
		o += ";c|" + std::to_string(n);
		for (int i = hzqs::kExtFirst; i <= n; ++i) {
			const auto* a = hzqs::FindSlot(st, i);
			o.push_back(';');
			o += std::to_string(i);
			o.push_back('|');
			if (!a || !a->formId || stale[i - hzqs::kExtFirst]) {
				o += "||inventory|1";
				continue;
			}
			const auto c = counts[i - hzqs::kExtFirst];
			const bool has = a->kind == hzqs::Kind::Inventory ? c > 0 : QmHookHas(a->formId, a->kind, nullptr);
			o += hzqs::PayloadSafe(a->name);
			o.push_back('|');
			o += std::to_string(c);
			o.push_back('|');
			o += hzqs::KindName(a->kind);
			o.push_back('|');
			o += has ? "0" : "1";
			o.push_back('|');
			o += refuse[i - hzqs::kExtFirst] ? "1" : "0";
		}
		QmInvFindReset();  // N-j: QmHookHas above may have filled the cache on the UI thread
		if (anyStale) {
			for (int k = 0; k < 12; ++k) {
				if (stale[k]) QmClearStale(hzqs::kExtFirst + k, staleId[k]);
			}
		}
		return o;
	}

	// Returns "ok", "power-later", "essence-later", "missing" or "bad".
	std::string QmAssign(int a_slot, const std::string& a_extra)
	{
		if (a_slot < hzqs::kExtFirst || a_slot > hzqs::kMaxSlots) return "bad";
		const auto ex = hzqs::ParseAssignExtra(a_extra);
		// TESTONLY: 13-24 take inventory items only (powers / Quantum Essence are spike-dependent).
		if (ex.power) return "power-later";
		if (hzqs::IsEssenceName(ex.name)) return "essence-later";
		// The movie may send I|<formId>|<displayName>. Inventory items name uFormID and
		// uHandleID as separate fields; FavoritesMenu never reads either, so the extra ID
		// may be missing, a real form ID, or (if the engine reused a field) a handle.
		// Keep LookupByID only when QmFormName NamesMatch the sent name; otherwise walk
		// by name. Return missing if that lookup fails. g_qmPendingForm is never written;
		// consume it so a stale value cannot stick.
		std::uint32_t form = ex.formId;
		if (form)
			g_qmPendingForm.store(0, std::memory_order_release);
		else
			form = g_qmPendingForm.exchange(0, std::memory_order_acq_rel);
		hzqs::Kind kind = hzqs::Kind::Inventory;
		std::string name = ex.name;
		bool usedId = false;
		if (form) {
			if (auto* f = RE::TESForm::LookupByID(form)) {
				const char* fn = QmFormName(f);
				if (hzqs::AssignIdMatchesName(ex.name, fn ? fn : "")) {
					usedId = true;
					kind = QmKindOfForm(f);
					if (name.empty()) name = fn ? fn : "";
				}
			}
		}
		if (!usedId) form = 0;
		if (!form && !ex.name.empty()) {
			form = QmFormByName(ex.name, &kind);
			if (!form) return "missing";
		}
		if (!form) {
			if (ex.formId || !ex.name.empty()) return "missing";
		}
		if (kind != hzqs::Kind::Inventory) return kind == hzqs::Kind::Power ? "power-later" : "essence-later";
		std::string base;   // S-3: the form's own name, checked again on every use and open
		if (form) {
			if (auto* f = RE::TESForm::LookupByID(form)) base = QmFormName(f);
		}
		{
			std::lock_guard lk(g_qmMu);
			if (!form) hzqs::ClearSlot(g_qmStore, a_slot);
			else {
				hzqs::Assignment a;
				a.index = a_slot;
				a.formId = form;
				a.formHex = hzqs::FormHex(form);
				a.name = name;
				a.base = base;
				a.kind = kind;
				hzqs::SetSlot(g_qmStore, a);
			}
		}
		QmMarkStoreDirty();
		return "ok";
	}

	std::string QmHandleCmd(const std::string& op, int slot, const std::string& extra)
	{
		if (op == "ready") return QmPayload();
		if (op == "count") {
			std::lock_guard lk(g_qmMu);
			g_qmSet.slotCount = hzqs::ClampCount(slot);
			g_qmVisCount.store(g_qmSet.slotCount, std::memory_order_relaxed);
			g_qmHudPush.store(true, std::memory_order_release);
			g_qmSetGen.fetch_add(1, std::memory_order_acq_rel);
			return "ok";
		}
		if (op == "use") {
			if (slot < hzqs::kExtFirst || slot > hzqs::kMaxSlots) return "bad";
			g_qmUseReq.store(hzqs::PackUseReq(slot | kQmFromMenu, GetTickCount64()), std::memory_order_release);
			return "ok";
		}
		if (op == "assign") return QmAssign(slot, extra);
		return "";
	}

	class HzqExtFn final : public RE::Scaleform::GFx::FunctionHandler
	{
	public:
		void Call(const Params& a) override
		{
			try {
				std::string op, extra;
				int slot = 0;
				if (a.argCount >= 1 && a.args && a.args[0].IsString() && a.args[0].GetString())
					op = a.args[0].GetString();
				if (a.argCount >= 2 && a.args) {
					if (a.args[1].IsNumber()) slot = static_cast<int>(a.args[1].GetNumber());
					else if (a.args[1].IsString() && a.args[1].GetString()) slot = std::atoi(a.args[1].GetString());
				}
				if (a.argCount >= 3 && a.args && a.args[2].IsString() && a.args[2].GetString())
					extra = a.args[2].GetString();
				const auto out = QmHandleCmd(op, slot, extra);
				auto& ret = QmTls().ret;
				ret = out;
				if (a.ret) *a.ret = ret.c_str();
			} catch (...) {
				if (a.ret) *a.ret = "";
			}
		}
	};

	HzqExtFn g_qmFn{};

	void PollFavorites(RE::Scaleform::GFx::ASMovieRootBase* a_this)
	{
		if (!a_this) return;
		if (!g_qmExtOn.load(std::memory_order_acquire)) return;  // Extended off: no bind, no kick (same open cost as 0.43.4)
		if (g_qmBound.load(std::memory_order_acquire)) return;  // bound for this open: no per-frame work (HUD tick clears on close)
		auto ui = RE::UI::GetSingleton();
		if (!ui || !ui->IsMenuOpen(QmFavName())) {
			g_qmMenuOpen.store(false, std::memory_order_release);
			g_qmBound.store(false, std::memory_order_release);
			return;
		}
		auto menu = ui->GetMenu(QmFavName());
		if (!menu || !menu->uiMovie || !menu->uiMovie->asMovieRoot) return;
		if (menu->uiMovie->asMovieRoot.get() != a_this) return;
		g_qmMenuOpen.store(true, std::memory_order_release);
		if (g_qmBound.exchange(true, std::memory_order_acq_rel)) return;
		if (!menu->menuObj.IsObject()) { g_qmBound.store(false, std::memory_order_release); return; }
		GValue fn;
		a_this->CreateFunction(&fn, &g_qmFn);
		if (!menu->menuObj.SetMember("hzqExtCmd", fn)) {
			static bool once = false;
			if (!once) { once = true; REX::WARN("quick menu: could not attach hzqExtCmd, extended slots stay idle"); }
			return;
		}
		menu->menuObj.Invoke("hzqExtKick", nullptr, nullptr, 0);
	}

	void QmOnFavoritesMovie(RE::IMenu* a_menu)
	{
		if (!a_menu || !(a_menu->menuName == "FavoritesMenu")) return;
		auto* root = (a_menu->uiMovie && a_menu->uiMovie->asMovieRoot)
			? a_menu->uiMovie->asMovieRoot.get() : nullptr;
		g_favRoot.store(root, std::memory_order_release);
		g_qmBound.store(false, std::memory_order_release);
		g_qmMenuOpen.store(root != nullptr, std::memory_order_release);
	}
