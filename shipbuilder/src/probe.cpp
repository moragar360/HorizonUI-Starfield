// Purpose: read-only SFSE probe for SpaceshipEditorMenu. It writes one log
// and does not change the ship, a save, or any other file.
// The permanent task is a BSJobs worker. It flushes the log and asks the
// window thread to install or remove the hook. Scaleform runs from the
// movie AdvanceFrame hook, on the thread that advanced that movie.
// Author: Moragar. Last modified: 2026-11-04.

#include "hsb_guard.h"
#include "hsb_version.h"

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <objbase.h>
#include <shlobj.h>

#include <atomic>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <mutex>
#include <string>

void (*g_shutdownUnhook)() = nullptr;

namespace probe_impl {

std::mutex g_qMu;
std::deque<std::string> g_queue;
std::wstring g_logPath;
std::atomic<bool> g_logReady{ false };
std::atomic<bool> g_menuOpen{ false };
std::atomic<bool> g_wantHook{ false };
std::atomic<bool> g_removeSettled{ false };
std::atomic<bool> g_hooked{ false };
std::atomic<std::uintptr_t> g_prev{ 0 };
std::atomic<HWND> g_hwnd{ nullptr };
std::atomic<DWORD> g_lastMove{ 0 };
std::atomic<bool> g_hudTried{ false };
std::atomic<bool> g_hudPending{ false };
std::atomic<bool> g_sinkReady{ false };
std::atomic<int> g_winOp{ 0 };
std::atomic<RE::Scaleform::GFx::ASMovieRootBase*> g_shipRoot{ nullptr };
std::atomic<bool> g_advanceHooked{ false };
std::atomic<std::uint64_t> g_lastPoll{ 0 };
std::atomic<bool> g_resetForms{ false };
std::atomic<bool> g_pingDone{ false };
std::atomic<int> g_pingTries{ 0 };
std::atomic<bool> g_inShipPoll{ false };
std::atomic<unsigned> g_hotbits{ 0 };
std::atomic<bool> g_mapped{ false };

using AdvanceFn = void (*)(RE::Scaleform::GFx::ASMovieRootBase*, bool);
std::atomic<AdvanceFn> g_origAdvance{ nullptr };

int g_formCount = 0;
bool g_formCapped = false;
UINT g_pingMsg = 0;
constexpr int kWinInstall = 1;
constexpr int kWinRemove = 2;
constexpr int kWinConfirm = 3;
constexpr const wchar_t* kPrevProp = L"HorizonShipBuilder.PrevWndProc";
std::atomic<std::uint32_t> g_pingHits{ 0 };
std::atomic<std::uint32_t> g_pingSerial{ 0 };
std::atomic<std::uint32_t> g_pingPosted{ 0 };
std::atomic<std::uint32_t> g_pingSeen{ 0 };
std::atomic<std::uintptr_t> g_msgHook{ 0 };
std::atomic<RE::Scaleform::GFx::ASMovieRootBase*> g_hudRoot{ nullptr };

constexpr const char* kHudText =
	"Horizon Ship Builder probe: this line is only a test. Nothing was changed.";

std::string NarrowPath(const std::wstring& path)
{
	std::string out;
	out.reserve(path.size());
	for (wchar_t c : path) {
		out.push_back(c > 0 && c < 128 ? static_cast<char>(c) : '?');
	}
	return out;
}

void Enqueue(std::string line)
{
	if (line.empty()) return;
	std::lock_guard lock(g_qMu);
	if (g_queue.size() >= 1024) return;
	g_queue.push_back(std::move(line));
}

void Fact(std::string_view id, std::string_view text)
{
	Enqueue(hsb::FactLine(id, text));
}

void WriteBatch(const std::deque<std::string>& batch)
{
	if (!g_logReady.load() || g_logPath.empty() || batch.empty()) return;
	if (!hsb::ProbeMayAppend(NarrowPath(g_logPath))) return;
	FILE* file = nullptr;
	if (_wfopen_s(&file, g_logPath.c_str(), L"ab") != 0 || !file) return;
	for (const auto& line : batch) {
		fwrite(line.data(), 1, line.size(), file);
		fwrite("\n", 1, 1, file);
	}
	fclose(file);
}

void FlushLog()
{
	std::deque<std::string> batch;
	{
		std::lock_guard lock(g_qMu);
		batch.swap(g_queue);
	}
	WriteBatch(batch);
}

void PrepareLog()
{
	PWSTR docs = nullptr;
	if (FAILED(SHGetKnownFolderPath(FOLDERID_Documents, 0, nullptr, &docs)) || !docs) {
		REX::INFO("HorizonShipBuilder probe: Documents folder unavailable");
		return;
	}
	std::wstring path = docs;
	CoTaskMemFree(docs);
	path += L"\\My Games\\Starfield\\SFSE\\Logs\\HorizonShipBuilder_probe.log";
	if (!hsb::ProbeMayAppend(NarrowPath(path))) {
		REX::INFO("HorizonShipBuilder probe: log path rejected");
		return;
	}
	g_logPath = std::move(path);
	g_logReady.store(true);
	Fact("boot", "HorizonShipBuilder " HSB_FILE_VERSION_STR " read-only");
	Fact("boot", "writes this log only; does not change the ship or a save");
	Fact("boot", "keys F7=mark F8=capture F6=dump");
	FlushLog();
}

const char* KeyLabel(WPARAM vk)
{
	switch (vk) {
	case VK_LEFT: return "Left";
	case VK_RIGHT: return "Right";
	case VK_DELETE: return "Delete";
	case VK_BACK: return "Backspace";
	case VK_ESCAPE: return "Esc";
	case 'L': return "L";
	case 'R': return "R";
	case 'F': return "F";
	case 'Z': return "Z";
	case 'H': return "H";
	case VK_OEM_2: return "Slash";
	case VK_F7: return "F7";
	case VK_F8: return "F8";
	case VK_F6: return "F6";
	default: return "";
	}
}

void LogCursor(const char* when)
{
	CURSORINFO info{};
	info.cbSize = sizeof(info);
	const BOOL ok = GetCursorInfo(&info);
	char buf[160];
	snprintf(buf, sizeof(buf), "%s cursorQuery=%d flags=0x%X showing=%d",
		when, ok ? 1 : 0, ok ? info.flags : 0u,
		ok && (info.flags & CURSOR_SHOWING) ? 1 : 0);
	Fact("F16", buf);
}

LRESULT CALLBACK ProbeWnd(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
	auto chain = reinterpret_cast<WNDPROC>(g_prev.load());
	if (!hsb::ChainIsLive(chain)) {
		chain = reinterpret_cast<WNDPROC>(GetPropW(hwnd, kPrevProp));
		if (hsb::ChainIsLive(chain)) g_prev.store(reinterpret_cast<std::uintptr_t>(chain));
	}
	if (g_pingMsg != 0 && msg == g_pingMsg) {
		g_pingHits.fetch_add(1);
		g_pingSeen.store(static_cast<std::uint32_t>(wp));
	}
	const bool down = msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN;
	const bool mouse = msg == WM_LBUTTONDOWN || msg == WM_LBUTTONUP || msg == WM_RBUTTONDOWN ||
		msg == WM_RBUTTONUP || msg == WM_MBUTTONDOWN || msg == WM_MBUTTONUP || msg == WM_MOUSEWHEEL ||
		msg == WM_MOUSEMOVE;
	if (g_menuOpen.load() && (down || mouse)) {
		bool skip = false;
		if (msg == WM_MOUSEMOVE) {
			const DWORD now = GetTickCount();
			const DWORD last = g_lastMove.load();
			if (now - last < 100) skip = true;
			else g_lastMove.store(now);
		}
		if (!skip && down && (lp & 0x40000000) == 0) {
			unsigned bit = 0;
			if (wp == VK_F7) bit = 1u;
			else if (wp == VK_F8) bit = 2u;
			else if (wp == VK_F6) bit = 4u;
			if (bit != 0) g_hotbits.fetch_or(bit);
		}
		if (!skip) {
			const bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
			const short x = static_cast<short>(LOWORD(lp));
			const short y = static_cast<short>(HIWORD(lp));
			char buf[192];
			snprintf(buf, sizeof(buf),
				"msg=0x%X vk=0x%X key=%s ctrl=%d x=%d y=%d wheel=%d swallowed=0",
				msg, static_cast<unsigned>(wp), KeyLabel(wp), ctrl ? 1 : 0, x, y,
				msg == WM_MOUSEWHEEL ? GET_WHEEL_DELTA_WPARAM(wp) : 0);
			Fact(down ? "F16" : "F17", buf);
		}
	}
	if (!chain) return DefWindowProcW(hwnd, msg, wp, lp);
	return CallWindowProcW(chain, hwnd, msg, wp, lp);
}

BOOL CALLBACK FindGameWindow(HWND hwnd, LPARAM lp)
{
	auto* out = reinterpret_cast<HWND*>(lp);
	DWORD pid = 0;
	GetWindowThreadProcessId(hwnd, &pid);
	if (pid != GetCurrentProcessId() || !IsWindowVisible(hwnd)) return TRUE;
	if (GetWindow(hwnd, GW_OWNER) != nullptr) return TRUE;
	*out = hwnd;
	return FALSE;
}

HWND GameWindow()
{
	HWND hwnd = nullptr;
	EnumWindows(FindGameWindow, reinterpret_cast<LPARAM>(&hwnd));
	return hwnd;
}

void InstallOnWindowThread(HWND hwnd)
{
	if (!hwnd) return;
	if (GetWindowThreadProcessId(hwnd, nullptr) != GetCurrentThreadId()) {
		Fact("F37", "install skipped off the window thread");
		return;
	}
	if (g_hooked.load() && g_hwnd.load() == hwnd &&
		hsb::ChainIsLive(reinterpret_cast<void*>(g_prev.load()))) {
		Fact("F37", "hook already in the chain");
		return;
	}
	auto* current = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	if (current == ProbeWnd) {
		auto prev = g_prev.load();
		if (!hsb::ChainIsLive(reinterpret_cast<void*>(prev)))
			prev = reinterpret_cast<std::uintptr_t>(GetPropW(hwnd, kPrevProp));
		if (!hsb::ChainIsLive(reinterpret_cast<void*>(prev))) {
			Fact("F37", "probe procedure already installed with an empty chain");
			return;
		}
		SetPropW(hwnd, kPrevProp, reinterpret_cast<HANDLE>(prev));
		g_prev.store(prev);
		g_hwnd.store(hwnd);
		g_hooked.store(true);
		Fact("F37", "probe procedure already installed");
		return;
	}
	auto* prev = reinterpret_cast<WNDPROC>(SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(ProbeWnd)));
	auto* now = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	if (now != ProbeWnd || !hsb::ChainIsLive(prev)) {
		Fact("F37", "hook installed=0");
		return;
	}
	SetPropW(hwnd, kPrevProp, reinterpret_cast<HANDLE>(prev));
	g_prev.store(reinterpret_cast<std::uintptr_t>(prev));
	g_hwnd.store(hwnd);
	g_hooked.store(true);
	char buf[160];
	snprintf(buf, sizeof(buf), "hook installed=1 hwnd=%p previous=%p coreModule=%d",
		static_cast<void*>(hwnd), static_cast<void*>(prev),
		GetModuleHandleA("HorizonUI.dll") ? 1 : 0);
	Fact("F37", buf);
}

void RemoveOnWindowThread(HWND hwnd)
{
	if (!hwnd) return;
	if (GetWindowThreadProcessId(hwnd, nullptr) != GetCurrentThreadId()) {
		Fact("F37", "remove skipped off the window thread");
		return;
	}
	auto* current = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	const auto chain = reinterpret_cast<WNDPROC>(g_prev.load());
	if (!hsb::ChainIsLive(chain)) {
		Fact("F37", "probe procedure already installed with an empty chain");
		return;
	}
	if (!hsb::ShouldRestoreWndProc(current, reinterpret_cast<void*>(ProbeWnd))) {
		g_removeSettled.store(true);
		Fact("F37", "left a newer window procedure in place; probe stays next and stops logging");
		return;
	}
	auto* swapped = reinterpret_cast<WNDPROC>(SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(chain)));
	if (swapped != ProbeWnd) {
		SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(swapped));
		Fact("F37", "left a newer window procedure in place; probe stays next and stops logging");
		return;
	}
	RemovePropW(hwnd, kPrevProp);
	g_hooked.store(false);
	g_hwnd.store(nullptr);
	g_prev.store(0);
	Fact("F37", "restored the previous window procedure");
}

void ConfirmOrReinstall(HWND hwnd)
{
	if (!hwnd) return;
	if (GetWindowThreadProcessId(hwnd, nullptr) != GetCurrentThreadId()) return;
	auto* current = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	if (current == ProbeWnd) return;
	const auto before = g_pingHits.load();
	if (current) CallWindowProcW(current, hwnd, g_pingMsg, 0, 0);
	if (g_pingHits.load() != before) return;
	g_hooked.store(false);
	Fact("F37", "hook missing after a newer restore; will reinstall");
	InstallOnWindowThread(hwnd);
}

void UnhookIfTop()
{
	HWND hwnd = g_hwnd.load();
	const auto chain = reinterpret_cast<WNDPROC>(g_prev.load());
	if (!hwnd || !chain) return;
	auto* current = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	if (!hsb::ShouldRestoreWndProc(current, reinterpret_cast<void*>(ProbeWnd))) return;
	SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(chain));
	g_hooked.store(false);
	g_hwnd.store(nullptr);
	g_prev.store(0);
}

struct ArmShutdown
{
	ArmShutdown() { g_shutdownUnhook = &UnhookIfTop; }
};

ArmShutdown g_armShutdown;

void DispatchWindowOp(int op, HWND hwnd)
{
	if (op == kWinInstall) InstallOnWindowThread(hwnd);
	else if (op == kWinRemove) RemoveOnWindowThread(hwnd);
	else if (op == kWinConfirm) ConfirmOrReinstall(hwnd);
}

LRESULT CALLBACK GetMsgThunk(int code, WPARAM wp, LPARAM lp)
{
	if (code >= 0 && g_winOp.load() != 0) {
		const int op = g_winOp.exchange(0);
		HWND hwnd = g_hwnd.load();
		if (!hwnd) hwnd = GameWindow();
		DispatchWindowOp(op, hwnd);
		const auto hook = reinterpret_cast<HHOOK>(g_msgHook.exchange(0));
		if (hook) UnhookWindowsHookEx(hook);
	}
	(void)wp;
	(void)lp;
	return CallNextHookEx(nullptr, code, wp, lp);
}

void RunOnWindowThread(HWND hwnd, int op)
{
	if (!hwnd || op == 0) return;
	const DWORD tid = GetWindowThreadProcessId(hwnd, nullptr);
	if (tid == 0) return;
	if (tid == GetCurrentThreadId()) {
		DispatchWindowOp(op, hwnd);
		return;
	}
	int idle = 0;
	if (!g_winOp.compare_exchange_strong(idle, op)) return;
	g_hwnd.store(hwnd);
	HHOOK hook = SetWindowsHookExW(WH_GETMESSAGE, GetMsgThunk, nullptr, tid);
	if (!hook) {
		g_winOp.store(0);
		Fact("F37", "window-thread hook could not be scheduled");
		return;
	}
	g_msgHook.store(reinterpret_cast<std::uintptr_t>(hook));
	if (!PostMessageW(hwnd, WM_NULL, 0, 0)) {
		UnhookWindowsHookEx(hook);
		g_msgHook.store(0);
		g_winOp.store(0);
		Fact("F37", "window-thread request was not posted");
	}
}

std::string InvokeString(RE::Scaleform::GFx::Value& result)
{
	if (result.IsString() && result.GetString()) return result.GetString();
	return {};
}

struct FormRead
{
	RE::TESForm* form;
	const char* editor;
	unsigned type;
	int fault;
};

FormRead ReadForm(std::uint32_t formId)
{
	FormRead out{};
	__try {
		out.form = RE::TESForm::LookupByID(static_cast<RE::TESFormID>(formId));
		if (out.form) {
			out.editor = out.form->GetFormEditorID();
			out.type = static_cast<unsigned>(out.form->GetFormType());
		}
	} __except (EXCEPTION_EXECUTE_HANDLER) {
		out.fault = 1;
	}
	return out;
}

void NoteMovieLine(const std::string& clean)
{
	std::uint32_t formId = 0;
	if (hsb::ParseFormLine(clean, formId)) {
		const int slot = hsb::NextFormSlot(g_formCount);
		if (slot < 0) {
			if (!g_formCapped) {
				g_formCapped = true;
				Fact("F2a", "form lookup cap reached");
			}
			return;
		}
		g_formCount = slot;
		const FormRead read = ReadForm(formId);
		const char* editor = read.editor;
		char buf[320];
		snprintf(buf, sizeof(buf),
			"id=%08X found=%d type=%u editor=%s maker=not-exposed class=not-exposed size=not-exposed fault=%d",
			formId, read.form ? 1 : 0, read.type,
			editor && editor[0] ? editor : "(empty)", read.fault);
		Fact("F2a", buf);
		return;
	}
	if (clean.rfind("PARTS ", 0) == 0) {
		g_formCount = 0;
		g_formCapped = false;
	}
	if (clean.rfind("CAPTURE ", 0) == 0) LogCursor(clean.c_str());
	Fact("movie", clean);
}

void NoteWindowMap(RE::IMenu* menu)
{
	HWND hwnd = g_hwnd.load();
	if (!hwnd) hwnd = GameWindow();
	RECT rc{};
	int cw = 0;
	int ch = 0;
	if (hwnd && GetClientRect(hwnd, &rc)) {
		cw = rc.right - rc.left;
		ch = rc.bottom - rc.top;
	}
	std::string stage = "stage=unknown";
	if (menu && menu->menuObj.IsObject()) {
		RE::Scaleform::GFx::Value result;
		if (menu->menuObj.Invoke("hsbProbeStage", &result)) {
			const std::string got = InvokeString(result);
			if (!got.empty()) stage = got;
		}
	}
	char buf[220];
	snprintf(buf, sizeof(buf), "client=%dx%d %s", cw, ch, stage.c_str());
	Fact("map", buf);
}

void PollShipOnAdvance()
{
	if (g_inShipPoll.exchange(true)) return;
	struct Clear
	{
		~Clear() { g_inShipPoll.store(false); }
	} clear;
	if (g_resetForms.exchange(false)) {
		g_formCount = 0;
		g_formCapped = false;
	}
	auto* ui = RE::UI::GetSingleton();
	if (!ui) return;
	auto menu = ui->GetMenu(hsb::kMenuName);
	const bool open = ui->IsMenuOpen(hsb::kMenuName);
	if (!g_pingDone.load()) {
		char head[192];
		snprintf(head, sizeof(head), "menu=%s isOpen=%d menuPtr=%d menuObj=%d movie=%d",
			hsb::kMenuName, open ? 1 : 0, static_cast<bool>(menu) ? 1 : 0,
			menu && menu->menuObj.IsObject() ? 1 : 0,
			menu && menu->uiMovie ? 1 : 0);
		Fact("F19", head);
	}
	if (!menu) return;
	if (!g_pingDone.load()) {
		bool invoked = false;
		std::string ping;
		if (menu->menuObj.IsObject()) {
			RE::Scaleform::GFx::Value result;
			invoked = menu->menuObj.Invoke("hsbProbePing", &result);
			ping = InvokeString(result);
		}
		if (!invoked && menu->uiMovie && menu->uiMovie->asMovieRoot) {
			RE::Scaleform::GFx::Value result;
			invoked = menu->uiMovie->asMovieRoot->Invoke("root.hsbProbePing", &result, nullptr, 0);
			ping = InvokeString(result);
		}
		Fact("F19", std::string(invoked ? "invoke=1" : "invoke=0") + " ping=" + hsb::SanitizeFact(ping));
		if (invoked && !ping.empty()) g_pingDone.store(true);
		else if (g_pingTries.fetch_add(1) > 40) {
			g_pingDone.store(true);
			Fact("F19", "invoke still false after retries");
		}
	}
	if (!menu->menuObj.IsObject()) return;
	if (!g_mapped.exchange(true)) NoteWindowMap(menu.get());
	const unsigned bits = g_hotbits.exchange(0);
	if (bits != 0) {
		RE::Scaleform::GFx::Value arg;
		arg = static_cast<double>(bits);
		if (!menu->menuObj.Invoke("hsbProbeHotkey", nullptr, &arg, 1))
			Fact("movie", "hotkey invoke failed");
	}
	RE::Scaleform::GFx::Value lines;
	if (!menu->menuObj.Invoke("hsbTakeLines", &lines)) return;
	const std::string blob = InvokeString(lines);
	if (blob.empty()) return;
	std::size_t at = 0;
	while (at < blob.size()) {
		const auto next = blob.find('\n', at);
		const auto piece = blob.substr(at, next == std::string::npos ? std::string::npos : next - at);
		at = next == std::string::npos ? blob.size() : next + 1;
		const std::string clean = hsb::SanitizeFact(piece);
		if (!clean.empty()) NoteMovieLine(clean);
	}
}

RE::BSTEventSource<RE::ShowHUDMessageEvent>* HudSource(int* fault)
{
	__try {
		return RE::ShowHUDMessageEvent::GetEventSource();
	} __except (EXCEPTION_EXECUTE_HANDLER) {
		*fault = 1;
		return nullptr;
	}
}

int HudNotify(RE::BSTEventSource<RE::ShowHUDMessageEvent>* source, RE::ShowHUDMessageEvent* event)
{
	__try {
		source->Notify(*event);
		return 1;
	} __except (EXCEPTION_EXECUTE_HANDLER) {
		return -1;
	}
}

void TryHudOnce(const char* which)
{
	bool expected = false;
	if (!g_hudTried.compare_exchange_strong(expected, true)) return;
	Fact("F31", std::string("begin one HUD notify on ") + which);
	int fault = 0;
	auto* source = HudSource(&fault);
	if (fault || !source) {
		Fact("F31", fault ? "GetEventSource faulted" : "GetEventSource returned null");
		return;
	}
	RE::ShowHUDMessageEvent event{};
	event.text = kHudText;
	event.sound = "";
	event.canThrottle = false;
	event.isWarning = false;
	const int notified = HudNotify(source, &event);
	char buf[96];
	snprintf(buf, sizeof(buf), "notify=%d textChars=%d thread=%s",
		notified, static_cast<int>(std::char_traits<char>::length(kHudText)), which);
	Fact("F31", buf);
}

void NoteHudRoot()
{
	if (g_hudRoot.load()) return;
	auto* ui = RE::UI::GetSingleton();
	if (!ui) return;
	auto menu = ui->GetMenu("HUDMenu");
	if (menu && menu->uiMovie && menu->uiMovie->asMovieRoot)
		g_hudRoot.store(menu->uiMovie->asMovieRoot.get());
}

// The one test line posts from the ship builder movie's AdvanceFrame when
// that movie advances after it closes. HUDMenu's AdvanceFrame is the
// fallback when the ship movie is not the one advancing.
void MaybeHudOnThisAdvance(RE::Scaleform::GFx::ASMovieRootBase* self)
{
	if (!g_hudPending.load() || !self) return;
	NoteHudRoot();
	const bool onShip = self == g_shipRoot.load() && !g_menuOpen.load();
	const bool onHud = g_hudRoot.load() && self == g_hudRoot.load();
	if (!onShip && !onHud) return;
	if (!g_hudPending.exchange(false)) return;
	TryHudOnce(onShip ? "ship-advance" : "hud-advance");
}

void HsbAdvance(RE::Scaleform::GFx::ASMovieRootBase* self, bool next)
{
	const auto orig = g_origAdvance.load();
	if (orig && orig != &HsbAdvance) orig(self, next);
	MaybeHudOnThisAdvance(self);
	auto* ship = g_shipRoot.load();
	if (!self || !ship || self != ship || !g_menuOpen.load()) return;
	const auto now = GetTickCount64();
	const auto last = g_lastPoll.load();
	if (!hsb::ProbePollDue(now, last)) return;
	g_lastPoll.store(now);
	try { PollShipOnAdvance(); } catch (...) {
		Fact("F19", "movie poll faulted");
	}
}

void InstallAdvanceHook(RE::Scaleform::GFx::ASMovieRootBase* root)
{
	if (!root) return;
	g_shipRoot.store(root);
	if (g_advanceHooked.load()) return;
	void** vtbl = *reinterpret_cast<void***>(root);
	if (!vtbl) return;
	auto* orig = reinterpret_cast<AdvanceFn>(vtbl[2]);
	if (!orig || orig == &HsbAdvance) {
		g_advanceHooked.store(orig == &HsbAdvance);
		return;
	}
	g_origAdvance.store(orig);
	const auto addr = reinterpret_cast<std::uintptr_t>(&vtbl[2]);
	if (!REL::WriteSafeData(addr, reinterpret_cast<std::uintptr_t>(&HsbAdvance))) {
		Fact("F19", "AdvanceFrame hook failed");
		return;
	}
	g_advanceHooked.store(true);
	Fact("F19", "AdvanceFrame hook chained");
}

class MenuSink : public RE::BSTEventSink<RE::MenuOpenCloseEvent>
{
public:
	RE::BSEventNotifyControl ProcessEvent(const RE::MenuOpenCloseEvent& event, RE::BSTEventSource<RE::MenuOpenCloseEvent>*) override
	{
		if (event.menuName == hsb::kMenuName) {
			g_menuOpen.store(event.opening);
			g_wantHook.store(event.opening);
			if (event.opening) {
				g_pingDone.store(false);
				g_pingTries.store(0);
				g_lastPoll.store(0);
				g_resetForms.store(true);
				g_removeSettled.store(false);
				g_mapped.store(false);
				g_hotbits.store(0);
				Fact("F19", "builder opened");
				Fact("F37", GetModuleHandleA("HorizonUI.dll") ? "HorizonUI.dll is loaded" : "HorizonUI.dll is not loaded");
				LogCursor("open");
			} else {
				Fact("F19", "builder closed");
				g_hotbits.store(0);
				g_hudPending.store(true);
			}
			Fact("F19", event.opening ? "closeEvent opening=1" : "closeEvent opening=0");
		}
		return RE::BSEventNotifyControl::kContinue;
	}
};

MenuSink g_sink;

void EnsureSink()
{
	if (g_sinkReady.load()) return;
	auto* ui = RE::UI::GetSingleton();
	if (!ui) return;
	ui->GetEventSource<RE::MenuOpenCloseEvent>()->RegisterSink(&g_sink);
	g_sinkReady.store(true);
}

void OnMenuMovie(RE::IMenu* menu)
{
	if (!menu) return;
	EnsureSink();
	if (menu->menuName == "HUDMenu" && menu->uiMovie && menu->uiMovie->asMovieRoot)
		g_hudRoot.store(menu->uiMovie->asMovieRoot.get());
	const char* raw = menu->menuName.c_str();
	const std::string name = raw ? raw : "";
	if (name.find("Ship") == std::string::npos && name.find("Space") == std::string::npos &&
		name.find("Hangar") == std::string::npos) {
		return;
	}
	Fact("F19", "movie created " + name);
	if (menu->menuName == hsb::kMenuName && menu->uiMovie && menu->uiMovie->asMovieRoot)
		InstallAdvanceHook(menu->uiMovie->asMovieRoot.get());
}

void PostProbePing(HWND hwnd)
{
	if (!hwnd || g_pingMsg == 0 || g_pingPosted.load() != 0) return;
	const auto serial = g_pingSerial.fetch_add(1) + 1;
	if (PostMessageW(hwnd, g_pingMsg, static_cast<WPARAM>(serial), 0))
		g_pingPosted.store(serial);
	else
		RunOnWindowThread(hwnd, kWinConfirm);
}

// JOBTICK-BEGIN
void JobTick()
{
	FlushLog();
	HWND hwnd = g_hooked.load() ? g_hwnd.load() : nullptr;
	if (!hwnd) hwnd = GameWindow();
	const auto now = GetTickCount64();
	static std::uint64_t lastHook = 0;
	if (g_wantHook.load()) {
		if (!g_hooked.load()) {
			if (hsb::ProbePollDue(now, lastHook)) {
				lastHook = now;
				RunOnWindowThread(hwnd, kWinInstall);
			}
		} else if (hsb::ProbePollDue(now, lastHook)) {
			lastHook = now;
			const auto posted = g_pingPosted.load();
			if (posted != 0) {
				const bool reached = g_pingSeen.load() == posted;
				g_pingPosted.store(0);
				if (hsb::HookWasRipped(true, reached))
					RunOnWindowThread(hwnd, kWinConfirm);
			}
			if (g_hooked.load() && g_pingPosted.load() == 0)
				PostProbePing(hwnd);
		}
	} else if (g_hooked.load() && !g_removeSettled.load()) {
		RunOnWindowThread(hwnd, kWinRemove);
	}
}
// JOBTICK-END

bool Boot()
{
	g_pingMsg = RegisterWindowMessageW(L"HorizonShipBuilder.ProbePing");
	PrepareLog();
	REX::INFO("HorizonShipBuilder {} read-only probe", HSB_FILE_VERSION_STR);
	EnsureSink();
	if (!g_sinkReady.load()) Fact("F19", "UI singleton missing at load; sink retries on movie create");
	if (auto* menus = SFSE::GetMenuInterface()) menus->Register(&OnMenuMovie);
	if (auto* tasks = SFSE::GetTaskInterface()) {
		tasks->AddPermanentTask([] { JobTick(); });
		Fact("boot", "job flush armed");
	} else {
		Fact("boot", "no task interface");
	}
	FlushLog();
	return true;
}

}  // namespace probe_impl

extern "C" BOOL WINAPI DllMain(HINSTANCE, DWORD reason, LPVOID)
{
	if (reason == DLL_PROCESS_DETACH && g_shutdownUnhook) g_shutdownUnhook();
	return TRUE;
}

SFSE_PLUGIN_LOAD(const SFSE::LoadInterface* a_sfse)
{
	SFSE::Init(a_sfse);
	return probe_impl::Boot();
}
