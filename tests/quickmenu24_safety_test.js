// 0.43.5 Extended Quick Menu safety pins: the use path (16-byte inventory-object wrapper, agent lock, SEH-safe
// locks, vanilla use flags, ID guards), the per-frame gates, key refusal, stale requests, store-write backoff,
// load-order check, the F11 conflict lock (run as code), the 13 px text floor and the FOMOD version.
// Run: node tests/quickmenu24_safety_test.js. Author: Moragar.
"use strict";
const fs = require("fs");
const path = require("path");
const root = path.resolve(__dirname, "..");
const rd = (p) => fs.readFileSync(path.join(root, p), "utf8").replace(/\r\n/g, "\n");
let failed = 0, passed = 0;
const expect = (c, m) => { if (c) { passed++; console.log("ok  " + m); } else { failed++; console.error("FAIL " + m); } };

const game = rd("src/hz_quickslots_game.h");
const hdr = rd("src/hz_quickslots.h");
const main = rd("src/main.cpp");
const qm = rd("actionscript/favorites/hzq_main.as");
const hud = rd("actionscript/horizon_block.as");
const info = rd("fomod/info.xml");

// body of the first C++ function whose signature contains `sig` (brace matched, comments kept)
function cBody(src, sig) {
	const at = src.indexOf(sig);
	if (at < 0) throw new Error("missing " + sig);
	const open = src.indexOf("{", at);
	let d = 0;
	for (let i = open; i < src.length; i++) {
		if (src[i] === "{") d++;
		else if (src[i] === "}" && --d === 0) return src.slice(open + 1, i);
	}
	throw new Error("unbalanced " + sig);
}
const code = (s) => s.replace(/\/\/[^\n]*/g, "");

// ---- M-1: the 16-byte GetInventoryObject result ----
expect(!/->\s*GetInventoryObject\s*\(/.test(code(game)), "M-1: the pinned 8-byte GetInventoryObject wrapper is never called");
expect(/RE::TESBoundObject\*\s+object\{\};\s*\n\s*RE::BSTSmartPointer<RE::TBO_InstanceData>\s+instanceData\{\};/.test(game)
	&& /static_assert\(sizeof\(QmInvObject\) == 0x10\);/.test(game), "M-1: local result = {object, BSTSmartPointer<TBO_InstanceData>} (16 bytes, the reference is released by the smart pointer)");
{
	const b = code(cBody(game, "static std::uint32_t QmInvObjectFormId("));
	expect(/QmInvObjectResult res\{ &obj, 0 \};/.test(b) && /fn\(a_inv, &handle, &resPtr\);/.test(b) && /kIdInventoryGetObjectSub/.test(b) && /return QmFormIdOf\(obj\.object\);/.test(b),
		"M-1: GetInventoryObjectSub gets a pointer to the full 16-byte object; only the form ID leaves the function");
}

// ---- use path (mutants m01 / m02) ----
const use = code(cBody(game, "static void QmUseCall(QmUseIo* io)"));
expect((use.match(/useFn\(/g) || []).length === 1 && use.indexOf("useFn(mgr, pc, &handle, 0, false, false, true)") >= 0,
	"m01: UseInventoryItem flags are the vanilla quick-key ones (0, allowUnequip false, false, true)");
{
	const inv = use.slice(use.indexOf("kIdUseInventoryItem"));
	const guard = inv.indexOf("if (rd < 0) { io->ok = -3; return; }");
	const retry = inv.indexOf("if (rd == 0) { io->ok = 0; return; }");
	const first = Math.min(...["GetSingleton()", "QmInvFind(", "QmAgentCollect(", "useFn("].map((s) => { const i = inv.indexOf(s); return i < 0 ? 1e9 : i; }));
	expect(guard > 0 && retry > 0 && guard < first && retry < first, "m02: inventory use returns on a missing ID (-3) and on loading (0) before any game call");
	const pw = use.slice(use.indexOf("kIdUseSpell"), use.indexOf("func(pc, spell)"));
	expect(/if \(rd < 0\) \{ io->ok = -3; return; \}/.test(pw) && /if \(rd == 0\) \{ io->ok = 0; return; \}/.test(pw), "m02: the power path has the same ID guard");
	expect(/const int rdLock = QmIdsReady\(\{ hzqs::kIdInventoryAgentLock \}\);\s*\n\s*if \(rdLock == 0\) \{ io->ok = 0; return; \}/.test(use)
		&& /QmAgentCollect\(inv, ag, rdLock == 1\)/.test(use), "S-1: the agent lock ID is guarded; the lock is used whenever it resolves");
}

// ---- S-1: agent list under the game's critical section, copy only ----
expect(/kIdInventoryAgentLock = 888731;/.test(hdr), "S-1: agent lock is address-library ID 888731");
{
	const b = code(cBody(game, "static bool QmAgentCollect("));
	const enter = b.indexOf("::EnterCriticalSection(cs)"), leave = b.indexOf("::LeaveCriticalSection(cs)");
	const span = b.slice(enter, leave);
	expect(enter > 0 && leave > enter && /QmAgentCopySEH\(a_inv, &a_io\)/.test(span) && !/QmInvObjectFormId|useFn|GetSingleton|return/.test(span),
		"S-1: only the SEH-wrapped copy runs inside Enter/LeaveCriticalSection (no game call, no early return)");
	const c = code(cBody(game, "static void QmAgentCopy("));
	expect(/const auto n = arr\.size\(\);/.test(c) && /arr\.data\(\)/.test(c) && /a_io->n < 8/.test(c) && !/arr\[/.test(c), "S-1: size and data read once, at most 8 handles copied");
}

// ---- S-5: locks are released on a fault ----
{
	const lockOwners = [];
	for (const sig of ["static bool QmInvFind(", "static bool QmInvSnapshot("]) {
		const b = cBody(game, sig);
		expect(/auto listG = a_pc->inventoryList\.LockRead\(\);/.test(b) && !/__try/.test(b), "S-5: " + sig.replace(/\($/, "") + " takes the RAII lock outside any __try");
		lockOwners.push(b);
	}
	const lockSrc = code(game);
	const lockCount = (lockSrc.match(/LockRead\(\)/g) || []).length;
	const inKnown = lockOwners.reduce((n, b) => n + (code(b).match(/LockRead\(\)/g) || []).length, 0);
	expect(lockCount > 0 && lockCount === inKnown, "S-5: every inventory LockRead is in QmInvFind or QmInvSnapshot (" + lockCount + ")");
	const seh = cBody(game, "static int QmInvCopySEH(");
	expect(/__try \{ fn\(a_list, a_io\); return 1; \}/.test(seh) && /__except \(EXCEPTION_EXECUTE_HANDLER\)/.test(seh), "S-5: the inventory copy is SEH-wrapped");
	const findSeh = cBody(game, "static int QmInvFindSEH(");
	expect(/__try \{ fn\(a_list, a_io\); return 1; \}/.test(findSeh) && /__except \(EXCEPTION_EXECUTE_HANDLER\)/.test(findSeh), "S-5: the match walk is SEH-wrapped");
	const cp = code(cBody(game, "static void QmInvCopy(")) + code(cBody(game, "static void QmInvFindWalk("));
	expect(!/QmFormName|starfield_cast|GetFullName|As<|IsBoundObject/.test(cp), "S-5: no virtual calls under the inventory lock");
	for (const f of ["std::uint32_t QmFormByName(", "void QmCountMany("])
		expect(/QmInvSnapshot\(pc, snap\)/.test(cBody(game, f)) && !/LockRead/.test(cBody(game, f)), "S-5: " + f.replace(/\($/, "") + " reads a snapshot, not the locked list");
	expect(/QmInvFind\(pc, io->formId, found\)/.test(cBody(game, "static void QmHasCall(")) && !/LockRead|QmInvSnapshot/.test(cBody(game, "static void QmHasCall(")),
		"S-C: QmHasCall uses the early-exit find, not a full snapshot");
}

// ---- S-C: one early-exit walk per press, no 1,024 cap on the use path ----
{
	const use = code(cBody(game, "static void QmUseCall(QmUseIo* io)"));
	expect(/QmInvFind\(pc, io->formId, found\)/.test(use) && !/QmInvSnapshot/.test(use), "S-C: the use path finds the first match; it does not copy the whole inventory");
	const walk = code(cBody(game, "static void QmInvFindWalk("));
	expect(/return;/.test(walk) && /QmFormIdOf\(it\.object\) == a_io->formId/.test(walk) && !/stacks|kQmInvCap|a_io->cap/.test(walk),
		"S-C: the match walk exits on the first hit, sums no stacks, and has no cap");
	expect(/tls\.findOk && tls\.find\.formId == a_formId/.test(cBody(game, "static bool QmInvFind(")) && /QmInvFindReset\(\);/.test(cBody(game, "static void QmHasCall(")),
		"S-C: hasItem and use share one walk via a same-thread cache, reset at the start of has");
	const useCall = code(cBody(game, "static void QmUseCall(QmUseIo* io)"));
	expect(/QmInvFindScopeGuard guard;/.test(useCall) && !/QmInvFindReset\(\);/.test(useCall),
		"N-j: QmUseCall resets the cache with a scope guard on every C++ exit");
	expect(/QmInvFindReset\(\); return 0;/.test(cBody(game, "static int QmUseSEH(")),
		"N-j: an SEH fault in the use path also resets the cache (C++ destructors do not run)");
	const snap = code(cBody(game, "static bool QmInvSnapshot("));
	expect(/QmSnapVec\(\)/.test(snap) && /extra\.reserve\(need \+ 64\)/.test(snap) && /io\.more/.test(snap) && !/s_fixed|QmSnapFixed|thread_local QmInvEntry s_/.test(snap),
		"S-E / S-C: the snapshot uses a lazily reserved heap vector, not a thread_local 1,024-entry array");
	expect((() => {
		const b = code(snap);
		let i = 0, bad = false;
		while (i < b.length) {
			const at = b.indexOf("LockRead()", i);
			if (at < 0) break;
			let open = at, depth = 0;
			while (open >= 0) {
				if (b[open] === "}") depth++;
				else if (b[open] === "{") { if (depth === 0) break; depth--; }
				open--;
			}
			if (open < 0) break;
			let d = 0, end = open;
			for (let j = open; j < b.length; j++) {
				if (b[j] === "{") d++;
				else if (b[j] === "}" && --d === 0) { end = j; break; }
			}
			const scope = b.slice(open, end + 1);
			if (/extra\s*\.(reserve|resize)\s*\(/.test(scope)) bad = true;
			i = at + 1;
		}
		const sawReserve = /extra\.reserve\(need \+ 64\)/.test(b) && /need = list->data\.size\(\);/.test(b);
		return sawReserve && !bad;
	})(), "N-k c06: reserve and resize never run inside a LockRead scope");
	expect(/if \(!io\.more\)/.test(snap), "N-k: the copy is kept when the buffer held every entry (no silent 1,024 cap)");
	expect(/attempt < 4/.test(snap), "N-k c08: overflow recopies are capped at 4");
	expect(/need = list->data\.size\(\);/.test(snap), "N-k c09: the overflow size is the live list length");
}

// ---- m03: the per-frame bind gate ----
{
	const poll = code(cBody(game, "void PollFavorites(RE::Scaleform::GFx::ASMovieRootBase* a_this)"));
	const b = poll.trim().split("\n").map((l) => l.trim()).filter(Boolean);
	expect(b[0] === "if (!a_this) return;" && /g_qmExtOn/.test(b[1]) && /g_qmBound/.test(b[2])
		&& /if \(!ext && !hold\) return;/.test(poll)
		&& /QmClearPending\(\);/.test(poll)
		&& /if \(g_qmBound\.load/.test(poll),
		"m03 / N-f: PollFavorites returns immediately when Extended is off with nothing to clear; close clears pending; bound+open does no bind");
}
expect(!/IsMenuOpen\("FavoritesMenu"\)|GetMenu\("FavoritesMenu"\)/.test(game), "N-6: no BSFixedString built per frame for the quick menu name");

// ---- m08 / S-4: job-thread keys ----
{
	const b = code(cBody(game, "void QmJobKeys(HWND a_wnd)"));
	expect(/const auto block = g_qmKeyBlock\.load\(std::memory_order_acquire\);/.test(b) && /if \(!vk \|\| \(block & \(1u << i\)\)\) \{ g_qmKeyDown\[i\] = false; continue; \}/.test(b),
		"m08: refused keys (the refusal mask) never queue a use");
	expect(/g_qmMenuOpen\.load[\s\S]*g_swallow\.load[\s\S]*g_uiLoading\.load[\s\S]*for \(bool& d : g_qmKeyDown\) d = true;\s*\n\s*QmDropKeyReq\(\);\s*\n\s*return;/.test(b),
		"S-4: during a menu / loading screen keys count as held and a queued key press is dropped");
	expect(/!a_wnd/.test(b) && !/GameWindow\(/.test(b) && /hzqs::PackUseReq\(slot, GetTickCount64\(\)\)/.test(b) && !/GetSingleton|Invoke|WriteStoreFile/.test(b),
		"N-c / S-4: the job poll passes its HWND in (no second GameWindow); a key press carries its time; no game calls or file I/O");
	expect(/QmJobKeys\(w\)/.test(main), "N-k n07: the job poll passes its HWND into QmJobKeys");
	const h = code(cBody(game, "void QmHudTick()"));
	expect(/if \(!hzqs::UseReqFresh\(req, GetTickCount64\(\)\)\)/.test(h) && !/WriteStoreFile|ReadStoreFile|ofstream/.test(h), "S-4: the HUD drops a late request; no file I/O on the HUD path");
}

// ---- S-6: store write backoff ----
{
	const b = code(cBody(game, "void QmFlushStore()"));
	expect(/if \(now >= s_nextTry \|\| ignore\)/.test(b) && /s_backoff = hzqs::NextWriteBackoffMs\(s_backoff\);/.test(b) && /s_nextTry = now \+ s_backoff;/.test(b) && /if \(!s_failLogged\)/.test(b),
		"S-6: a failed write waits a capped backoff and logs once (never a retry per poll)");
}

// ---- S-8 ----
expect(/return hzqs::FallbackReservedKey\(k\);/.test(game) && /"F5","F9"/.test(cBody(hdr, "inline bool FallbackReservedKey(")), "S-8: the fallback reserved list has F5 and F9 (and the other F-keys)");

// ---- S-3 ----
{
	const u = cBody(hdr, "inline UseResult UseExtendedSlot(");
	expect(u.indexOf("hooks.formStale") > 0 && u.indexOf("hooks.formStale") < u.indexOf("hooks.hasItem") && /return UseResult::Stale;/.test(u), "S-3: a stale form ID is refused before any use");
	expect(/h\.formStale = &QmHookStale;/.test(game) && /QmHookClears\(\*a, nullptr\)/.test(cBody(game, "void QmRunUse(")) && /AssignmentCheck\(\*a, QmFormName\(form\), form->IsBoundObject\(\)\)/.test(cBody(game, "std::string QmPayload()")),
		"S-B: the slot is refused on a stale check; it is cleared only when the form is no longer an inventory object");
	expect(/AssignmentClears/.test(cBody(game, "bool QmHookClears(")) && /AssignmentStale/.test(cBody(game, "bool QmHookStale(")),
		"S-B: refuse and clear are separate hooks");
	expect(/a_curName\.empty\(\)/.test(cBody(hdr, "inline SlotCheck AssignmentCheck(")), "S-B: an empty current name is unknown, not stale");
}

// ---- S-A: a second character must not inherit the first character's slots ----
{
	const load = code(cBody(game, "void QmLoadStoreFor("));
	const flush = code(cBody(game, "void QmFlushStore("));
	expect(/if \(hzqs::MustParkBoundStore\(g_qmStore\)\)/.test(load) && /ResetToUnknownCharacter\(g_qmStore, a_ch\)/.test(load) && /g_qmParked\.Park\(g_qmStore\)/.test(load),
		"S-D: an unknown player ID parks a bound store and starts empty and memory-only");
	expect(/ApplyUnknownCharacter\(g_qmStore, a_ch\)/.test(load) && /MustParkBoundStore/.test(load),
		"S-A / S-D: already memory-only stores still go through ApplyUnknownCharacter");
	expect(/ShouldMergeMemorySlots\(g_qmStore\)/.test(flush),
		"S-A: the job thread merges only memory-only assignments, never a bound character's slots");
	expect(/MustFlushBeforeLoad\(g_qmStore\.character, g_qmLoadChar\)/.test(flush) && /g_qmParked\.Park\(g_qmStore\)/.test(flush) && /ShouldWrite\(item\.store\.character\.key, item\.gen\)/.test(flush) && /ClearGen\(item\.store\.character\.key, item\.gen\)/.test(flush),
		"N-g / S-D / S-F: a different character's dirty store is parked by generation and written before the load replaces it");
	expect(/need = !hzqs::CanWriteStore\(g_qmStore\.character\);/.test(cBody(game, "void QmLazyStore(")),
		"S-D: the 2 s lazy retry keeps running while the store is memory-only");
	expect(/inline void ApplyUnknownCharacter/.test(hdr) && /inline bool ShouldMergeMemorySlots/.test(hdr) && /inline bool MustParkBoundStore/.test(hdr) && /inline void ResetToUnknownCharacter/.test(hdr) && /inline bool MustFlushBeforeLoad/.test(hdr),
		"S-A / S-D: the bind, park, reset and merge gates are in the pure header (unit-tested)");
}


// ---- m09: the F11 conflict lock, run as code ----
{
	const s = hud.indexOf("var qmi:int = 0;");
	const e = hud.indexOf("qmi++;", s);
	const end = hud.indexOf("}", e) + 1;
	const js = hud.slice(s, end).replace(/:(int|Boolean|String)\b/g, "");
	const run = new Function("rows", js + "\nreturn rows;");
	const mk = () => [{ k: "QuickMenuHorizon", t: "b" }, { k: "QuickMenuExtended", t: "b" }, { k: "QuickMenuSlotCount", t: "c" }, { k: "QuickMenuKey13", t: "k" }, { k: "XpToastScale", t: "z" }];
	const conf = run.call({ hz30Mod: { quickmenu: 1 }, hzQmConflict: true }, mk());
	expect(!conf[0].dis && conf[1].dis && conf[1].dv === false && conf[2].dis && conf[3].dis && !conf[4].dis && /Favorites Menu Extended/.test(conf[1].note),
		"m09: with another extended-favorites mod, every Extended row locks (HORIZON STYLE and other rows stay editable)");
	const free = run.call({ hz30Mod: { quickmenu: 1 }, hzQmConflict: false }, mk());
	expect(free.every((r) => !r.dis), "m09: without a conflict nothing locks");
	const off = run.call({ hz30Mod: {}, hzQmConflict: false }, mk());
	expect(off[0].dis && off[1].dis && off[3].dis && !off[4].dis, "module unticked: every Quick Menu row locks");
	const van = run.call({ hz30Mod: { quickmenu: 1 }, hzQmConflict: false, hzQmOn: false }, mk());
	expect(!van[0].dis && van[1].dis && van[1].dv === false && van[2].dis && van[3].dis && !van[4].dis && /HORIZON STYLE/.test(van[1].note),
		"m09: HORIZON STYLE off greys Extended rows (looks off) and leaves HORIZON STYLE editable");
	const hz = run.call({ hz30Mod: { quickmenu: 1 }, hzQmConflict: false, hzQmOn: true }, mk());
	expect(hz.every((r) => !r.dis), "m09: HORIZON STYLE on leaves Extended rows editable");
	const pendOff = run.call({ hz30Mod: { quickmenu: 1 }, hzQmConflict: false, hzQmOn: true, hzSetPend: { QuickMenuHorizon: false, QuickMenuExtended: true } }, mk());
	expect(!pendOff[0].dis && pendOff[1].dis && pendOff[1].dv === false && pendOff[2].dis && pendOff[3].dis,
		"m09: pending HORIZON STYLE off greys Extended rows at once");
	expect(pendOff[1].note && /HORIZON STYLE/.test(pendOff[1].note),
		"m09: the pending lock keeps the saved-setting note");
	const pendOn = run.call({ hz30Mod: { quickmenu: 1 }, hzQmConflict: false, hzQmOn: false, hzSetPend: { QuickMenuHorizon: true, QuickMenuExtended: true } }, mk());
	expect(pendOn.every((r) => !r.dis), "m09: pending HORIZON STYLE on unlocks Extended rows at once");
}

// ---- M-3: 13 px floor ----
expect(/return Math\.max\(13,Math\.round\(size \* ts \* 10\) \/ 10\);/.test(cBody(qm, "private function hzqFs(")), "M-3: hzqFs never returns under 13 px");
{
	const ext = qm.slice(qm.indexOf("// ---------- 0.43.5 Extended Mode"));
	const sizes = [];
	const re = /this\.hzqSet\([^,]+,[^;]*?,(\d+(?:\.\d+)?),/g;
	let m;
	while ((m = re.exec(ext))) sizes.push(Number(m[1]));
	expect(sizes.length >= 3 && sizes.every((v) => v >= 13), "M-3: every Extended text size is 13 or more (" + sizes.join(", ") + ")");
	expect(!/this\.hzqExtFit\(o\.n/.test(ext) && /this\.hzqExtChipTune\(o\.k,klab,boxN,kcol\)/.test(ext)
		&& /this\.hzqSprite\(this, -1\)/.test(qm),
		"M-3: extra cards have no name field; the name is the center-right info panel");
	expect(/hzqExtKeyShort/.test(ext) && /PAGEDOWN/.test(cBody(qm, "private function hzqExtKeyShort("))
		&& /this\.hzqExtChipTune\(o\.k,klab,boxN,kcol\);/.test(ext)
		&& /HZQ_CHIP_MIN/.test(ext) && /Math\.max\(13,Math\.round\(size \* ts \* 10\) \/ 10\)/.test(cBody(qm, "private function hzqFs(")),
		"N-a: long key names use a short form (PGDN) then shrink the extra chip font to the scaled slot; hzqFs stays 13 px for other text");
}
expect(/this\.hzqSet\(k,kt,13,/.test(qm) && /this\.hzqSet\(this\.hzqHdrT,this\.hzqUC\(this\.hzqLt\("Quick Menu"\)\),13,/.test(qm)
	&& /this\.hzqSet\(this\.hzqHdrK,kt,13,/.test(qm) && /this\.hzqSet\(lt,this\.hzqUC\(String\(rows\[j\]\[0\]\)\),13,/.test(qm)
	&& !/this\.hzqSet\([^;]+,(?:11|12|10\.5),/.test(qm), "N-b: every hzqSet size is written as 13 or larger (none rely on the floor alone)");

// ---- N-4 / N-5 ----
expect(/if\(\(this\.hzqExtMask >> i\) & 1\) \{ return; \}/.test(qm) && /o \+= "m\|" \+ std::to_string\(g_qmKeyBlock/.test(game), "N-4: the in-menu key path skips keys the DLL refused");
expect(/this\.hzqS\.SlotCount = dc;/.test(qm) && /o \+= ";c\|" \+ std::to_string\(n\);/.test(game), "N-5: the movie takes the DLL's slot count from the ready payload");

// ---- N-d: ABI and index pins (probes that previously survived) ----
{
	const wrap = cBody(game, "static std::uint32_t QmInvObjectFormId(");
	expect(/QmInvObjectResult\* resPtr = &res;/.test(wrap), "N-d k02: resPtr is QmInvObjectResult* to the 16-byte Result, not a shallower indirection");
	expect(!/\.reset\(/.test(wrap), "N-d k03: QmInvObjectFormId does not double-release instanceData with .reset(");
	const ag = cBody(game, "static void QmAgentCopy(");
	expect(/if \(ag\.handleID == 0 \|\| ag\.itemOwner != a_io->owner \|\| static_cast<int>\(ag\.listIndex\) != a_io->listIdx\) continue;/.test(ag),
		"N-d k05: the agent copy keeps the listIndex filter");
	for (const sig of ["static void QmInvCopy(", "static void QmInvFindWalk("]) {
		const w = cBody(game, sig);
		const idx = w.indexOf("const std::uint32_t idx = i++;");
		const nul = w.indexOf("if (!it.object) continue;");
		expect(idx >= 0 && nul > idx, "N-d k09/k10: " + sig.replace(/\($/, "") + " counts null entries in idx before the continue");
	}
	expect(/listIdx = found\.listIdx/.test(cBody(game, "static void QmUseCall(QmUseIo* io)")) && !/listIdx = .*snap\.e/.test(cBody(game, "static void QmUseCall(QmUseIo* io)")),
		"N-d k09: the use path takes the inventory list index, not a packed snapshot position");
	expect(/a && a->formId == a_formId/.test(cBody(game, "void QmClearStale(")), "N-d k12: QmClearStale only erases the slot if it still holds that form ID");
	expect(/chk == hzqs::SlotCheck::Clear/.test(cBody(game, "std::string QmPayload()")) && /if \(stale\[k\]\) QmClearStale/.test(cBody(game, "std::string QmPayload()")),
		"N-d k11: QmPayload still clears slots, but only the ones AssignmentCheck marked Clear");
	expect(/chk == hzqs::SlotCheck::Refuse/.test(cBody(game, "std::string QmPayload()")) && /refuse\[i - hzqs::kExtFirst\] \? "1" : "0"/.test(cBody(game, "std::string QmPayload()")),
		"N-i: the payload sends a refuse flag for a name-only mismatch");
	expect(/d\.refuse === true/.test(qm) && /var dim:Boolean = empty \|\| refuse;/.test(qm) && /this\.hzqExtSlotArt\(g,boxN,sel,dim\)/.test(qm) && /"refuse":f\.length > 5 && String\(f\[5\]\) == "1"/.test(qm),
		"N-i: a refused slot is drawn with the unavailable look (dim extra card); name is the info panel only");
	expect(/function hzqAccentRing/.test(qm) && /function hzqFilledBorder/.test(qm)
		&& /function hzqRingDraw/.test(qm) && /this\.hzqAccentRing\(g,x,y,box\)/.test(qm)
		&& !/lineStyle\(2,acc,1,true,"normal"\)/.test(qm),
		"N-i: hover/focus uses a filled overlay ring (same construction as the keycap, all four sides)");
	const name = cBody(game, "static const char* QmFormName(");
	expect(/QmRttiOk\(\)/.test(name) && name.indexOf("QmRttiOk()") < name.indexOf("starfield_cast"), "N-d k23: QmFormName does not call starfield_cast unless the RTTI IDs resolved");
}

// ---- N-l: one lazily created per-thread pointer, no large TLS objects ----
{
	const gcode = code(game);
	const tlsDecls = gcode.match(/thread_local\s+\w+/g) || [];
	expect(tlsDecls.length === 1 && /static thread_local QmTlsOwner t_qmTls;/.test(gcode),
		"N-l: the only thread_local in the game header is the QmTlsOwner pointer");
	expect(/if \(!t_qmTls\.p\) t_qmTls\.p = new QmThreadState\(\);/.test(gcode) && /~QmTlsOwner\(\) \{ delete p; \}/.test(gcode),
		"N-l: the per-thread state is allocated once and deleted when the thread exits");
	expect(/std::string\s+ret;/.test(cBody(game, "struct QmThreadState")) && /auto& ret = QmTls\(\)\.ret;/.test(cBody(game, "void Call(const Params& a)")),
		"N-l: the Scaleform reply string lives in the same per-thread object");
	expect(/if \(auto\* s = QmTlsPtr\(\)\) s->findOk = false;/.test(cBody(game, "static void QmInvFindReset(")) && !/new QmThreadState/.test(cBody(game, "static void QmInvFindReset(")),
		"N-l / N-j: the cache reset writes only when the pointer already exists (no allocation in the fault path)");
	expect(!/thread_local\s+QmInvEntry/.test(gcode) && !/thread_local\s+std::vector/.test(gcode) && !/thread_local\s+std::string/.test(gcode) && !/thread_local\s+QmInvSnap/.test(gcode) && !/thread_local\s+bool/.test(gcode),
		"N-o: no thread_local array, vector, string, snapshot, or flag remains outside the owner pointer");
}

// ---- N-n: one AssignmentCheck per open, no duplicate refuse pass ----
{
	const pay = code(cBody(game, "std::string QmPayload()"));
	expect((pay.match(/AssignmentCheck\(/g) || []).length === 1 && !/QmHookRefuses\(/.test(pay) && !/QmHookClears\(/.test(pay),
		"N-n: QmPayload runs AssignmentCheck once per slot and does not call the refuse or clear hooks");
}

// ---- S-F: per-character parked stores, cleared by generation ----
{
	const load = code(cBody(game, "void QmLoadStoreFor("));
	const flush = code(cBody(game, "void QmFlushStore("));
	expect(/struct ParkedSet/.test(hdr) && /ClearGen\(/.test(hdr) && /ReparkFailed\(/.test(hdr) && /ShouldWrite\(/.test(hdr) && /OverlayFile\(/.test(hdr) && /ShouldApplyLoad\(/.test(hdr),
		"S-F: the parked-set API lives in the pure header");
	expect(/g_qmParked\.Park\(g_qmStore\)/.test(load) && /g_qmLoadReq\.store\(false/.test(load) && /\+\+g_qmLoadGen/.test(load),
		"S-F: an unknown player ID parks the outgoing store, cancels an in-flight load, and bumps the load generation");
	expect(/ReparkFailed\(item\.store, item\.gen\)/.test(flush) && /OverlayFile\(st, ch\)/.test(flush) && /ShouldApplyLoad\(ch, gen, g_qmLoadChar, g_qmLoadGen/.test(flush),
		"S-F: a failed write is re-parked, a parked copy replaces a stale file, and a superseded load is not applied");
	expect(!/g_qmParkedDirty/.test(game) && !/g_qmParked = /.test(game),
		"S-F: the single parked-store and clear-by-key flag are gone");
}

// ---- N-p / S-G: scratch helper, no shipping path literals, no test-made deletes ----
{
	const scratch = rd("tests/hz_test_scratch.h");
	const log = rd("tests/message_log_test.cpp");
	expect(/#include <unistd.h>/.test(scratch) && /#include <process.h>/.test(scratch) && /getpid\(\)/.test(scratch),
		"N-p: the scratch helper includes the header that declares getpid");
	expect(/HZ_TEST_DIR/.test(scratch) && /TMPDIR/.test(scratch) && /"test_scratch"/.test(scratch) && !/remove_all/.test(scratch) && !/temp_directory_path/.test(scratch),
		"N-p / S-G: scratch folders come from HZ_TEST_DIR, an allowed TMPDIR, or cwd/test_scratch, and are never deleted");
	const liveRemove = log.split("\n").filter((l) => /std::filesystem::remove\s*\(/.test(l) && !/^\s*\/\//.test(l) && !/"/.test(l.split("std::filesystem::remove")[0]));
	expect(liveRemove.length === 0, "N-p: message log tests never delete a test-made backup");
	const walk = (dir, acc) => {
		for (const name of fs.readdirSync(dir)) {
			if (name === ".git" || name === "commonlibsf") continue;
			const p = path.join(dir, name);
			const rel = path.relative(root, p).replace(/\\/g, "/");
			if (rel === "lib/commonlibsf" || rel.startsWith("lib/commonlibsf/")) continue;
			if (fs.statSync(p).isDirectory()) walk(p, acc);
			else acc.push(p);
		}
		return acc;
	};
	const needle = (parts) => parts.join("");
	const banned = [needle(["/", "workspace"]), needle(["/", "tmp"]), needle(["/", "home"]), needle(["C:", "\\", "Users"])];
	let hits = 0;
	for (const f of walk(root, [])) {
		const rel = path.relative(root, f).replace(/\\/g, "/");
		if (rel.startsWith("lib/commonlibsf/")) continue;
		if (!/\.(h|hpp|c|cpp|cc|js|as|lua|xml|md|txt|ini|json|py|sh)$/i.test(rel) && !/^(src|tests|actionscript|fomod|tools)\//.test(rel)) continue;
		let text;
		try { text = fs.readFileSync(f, "utf8"); } catch (e) { continue; }
		for (const n of banned) if (text.indexOf(n) >= 0) hits++;
	}
	expect(hits === 0, "S-G: shipping sources contain no box, temp, or user-profile path literals");
}

// ---- S-9 ----
expect(/<Version MachineVersion="0\.43\.5">0\.43\.5<\/Version>/.test(info), "S-9: fomod/info.xml is 0.43.5");

console.log(passed + " passed, " + failed + " failed");
if (failed) process.exit(1);
