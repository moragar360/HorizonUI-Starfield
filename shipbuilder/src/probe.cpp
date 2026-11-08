// Purpose: SFSE plugin for Horizon Ship Builder 0.2 (SpaceshipEditorMenu).
//    It feeds the pointer, wheel and keys to the builder movie, swallows presses over the
//    rectangles the movie publishes, merges the movie's settings into the user ini, runs the
//    movie's pill and colour scheme file requests in the builder's own folders, and keeps a
//    counts-only log. It never changes the ship or a save: ship actions are game events the
//    movie sends through the game's own data manager.
// Why the plugin feeds input: in-game logs (p5) showed the window procedure saw every click
//    over Horizon panels while Scaleform raised no mouse event for them, so no Horizon
//    control could be clicked. The movie now hit-tests the fed pointer itself.
// Threads: the window procedure runs on the window thread; Scaleform calls run from the
//    movie's AdvanceFrame hook on the thread that advanced that movie; the permanent task is
//    a BSJobs worker that flushes the log, writes files and keeps the hook installed.
// Logging: counts, ids and tokens only. No key names, typed characters, file contents or
//    pill names are logged.
// Inputs: SFSE load, SpaceshipEditorMenu open and close events, the game window's messages,
//    and what the movie hands over (log, STATE, HOT and SET lines; file requests).
// Outputs: the movie calls listed at DriveMovie, the user ini, the builder's pill and scheme
//    files, and the log. Dependencies: CommonLibSF (SFSE), Win32, and the hsb_*.h headers.
// Author: Moragar. Last modified: 2026-11-08.

#include "hsb_guard.h"
#include "hsb_arrange.h"
#include "hsb_files.h"
#include "hsb_input.h"
#include "hsb_profile.h"
#include "hsb_settings.h"
#include "hsb_version.h"
#include "hsb_win32_files.h"

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <windowsx.h>
#include <objbase.h>
#include <shlobj.h>

#include <atomic>
#include <cstdint>
#include <cstdio>
#include <deque>
#include <mutex>
#include <string>
#include <utility>
#include <vector>

void (*g_shutdownUnhook)() = nullptr;

namespace probe_impl {

using hsb::w32::EnsureDirsFor;
using hsb::w32::FileExists;
using hsb::w32::NarrowPath;
using hsb::w32::ReadCapped;
using hsb::w32::WidenAscii;
using hsb::w32::Win32ProfileDisk;
using hsb::w32::WriteNew;
using hsb::w32::WriteReplace;

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
std::atomic<bool> g_mapped{ false };
std::atomic<bool> g_probeDebug{ false };
std::atomic<int> g_movieGen{ 0 };
std::atomic<int> g_saveResult{ -1 };
std::atomic<bool> g_applyPending{ false };
std::atomic<bool> g_writeIni{ false };
std::atomic<bool> g_needApply{ false };
std::atomic<bool> g_debugSent{ false };
std::atomic<unsigned> g_invokeMiss{ 0 };

// The movie generation that speaks protocol 0.2 (hsbFeed, hsbFiles, STATE, HOT, SET).
constexpr int kMovieGen = 2;

// Input shared between the movie thread (writes STATE and HOT) and the window thread.
std::mutex g_inMu;
hsb::InputState g_in;
hsb::HotArea g_hot;

// Tokens for hsbFeed. Window thread pushes, movie thread drains every advance.
constexpr std::size_t kFeedCap = 256;
std::mutex g_feedMu;
std::deque<std::string> g_feed;

// Close summary counters (counts only).
std::atomic<unsigned> g_cPresses{ 0 };
std::atomic<unsigned> g_cEaten{ 0 };
std::atomic<unsigned> g_cWheels{ 0 };
std::atomic<unsigned> g_cKeys{ 0 };
std::atomic<unsigned> g_cChars{ 0 };
std::atomic<unsigned> g_cDropped{ 0 };
std::atomic<unsigned> g_cRaw{ 0 };

// Window thread only.
hsb::PressLedger g_keysEaten;
hsb::PressLedger g_buttonsEaten;
int g_wheelRest = 0;
bool g_eatChar = false;

// Settings from SET and ARRANGE lines, merged into the user ini by the job thread.
std::mutex g_iniMu;
std::string g_apply;
std::vector<hsb::Setting> g_updates;
unsigned g_setRejected = 0;
std::wstring g_iniPath;
std::wstring g_docsBuilder;
std::wstring g_gameBuilder;

// File requests from hsbTakeFiles and the replies for hsbFiles.
constexpr std::size_t kFileQueueCap = 64;
constexpr int kFileJobsPerTick = 8;
std::mutex g_fileMu;
std::deque<std::string> g_fileReq;
std::deque<std::string> g_fileRep;

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
		REX::INFO("HorizonShipBuilder: Documents folder unavailable");
		return;
	}
	std::wstring path = docs;
	CoTaskMemFree(docs);
	path += L"\\My Games\\Starfield\\SFSE\\Logs\\HorizonShipBuilder_probe.log";
	if (!hsb::ProbeMayAppend(NarrowPath(path))) {
		REX::INFO("HorizonShipBuilder: log path rejected");
		return;
	}
	g_logPath = std::move(path);
	g_logReady.store(true);
	Fact("boot", "HorizonShipBuilder " HSB_FILE_VERSION_STR);
	FlushLog();
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

// ---- builder input (protocol 0.2) ----------------------------------------------------------

unsigned MouseButton(UINT msg)
{
	switch (msg) {
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
	case WM_LBUTTONUP: return 1;
	case WM_RBUTTONDOWN:
	case WM_RBUTTONDBLCLK:
	case WM_RBUTTONUP: return 2;
	case WM_MBUTTONDOWN:
	case WM_MBUTTONDBLCLK:
	case WM_MBUTTONUP: return 3;
	default: return 0;
	}
}

bool IsButtonRelease(UINT msg)
{
	return msg == WM_LBUTTONUP || msg == WM_RBUTTONUP || msg == WM_MBUTTONUP;
}

void ToStage(HWND hwnd, int cx, int cy, const hsb::InputState& in, int& sx, int& sy)
{
	RECT rc{};
	int cw = 1;
	int ch = 1;
	if (GetClientRect(hwnd, &rc)) {
		cw = rc.right - rc.left;
		ch = rc.bottom - rc.top;
	}
	hsb::ClientToStage(cx, cy, cw, ch, in.view, sx, sy);
}

// Consecutive moves collapse into the newest one, so a fast mouse never fills the queue.
void Feed(std::string token, bool move)
{
	std::lock_guard lock(g_feedMu);
	if (move && !g_feed.empty() && g_feed.back().rfind("M M ", 0) == 0) {
		g_feed.back() = std::move(token);
		return;
	}
	if (g_feed.size() >= kFeedCap) {
		g_cDropped.fetch_add(1);
		return;
	}
	g_feed.push_back(std::move(token));
}

std::string TakeFeed()
{
	std::deque<std::string> batch;
	{
		std::lock_guard lock(g_feedMu);
		batch.swap(g_feed);
	}
	std::string out;
	for (const auto& token : batch) {
		out += token;
		out += '\n';
	}
	return out;
}

void ResetInput()
{
	{
		std::lock_guard lock(g_inMu);
		g_in = hsb::InputState{};
		g_hot = hsb::HotArea{};
	}
	{
		std::lock_guard lock(g_feedMu);
		g_feed.clear();
	}
	g_cPresses.store(0);
	g_cEaten.store(0);
	g_cWheels.store(0);
	g_cKeys.store(0);
	g_cChars.store(0);
	g_cDropped.store(0);
	g_cRaw.store(0);
}

std::string CountsNow()
{
	hsb::InputCounts c;
	c.presses = g_cPresses.load();
	c.eaten = g_cEaten.load();
	c.wheels = g_cWheels.load();
	c.keys = g_cKeys.load();
	c.chars = g_cChars.load();
	c.dropped = g_cDropped.load();
	c.raw = g_cRaw.load();
	return hsb::CountsLine(c);
}

// The character a key types on the active layout without Shift, uppercase; 0 for none or a
// dead key. Hotkeys compare against this, the same way the movie names them.
int KeyChar(unsigned vk)
{
	const UINT mapped = MapVirtualKeyW(vk, MAPVK_VK_TO_CHAR);
	if (mapped == 0 || (mapped & 0x80000000u) != 0) return 0;
	unsigned c = mapped & 0xFFFFu;
	if (c >= 'a' && c <= 'z') c = c - 'a' + 'A';
	return c < 128 ? static_cast<int>(c) : 0;
}

// Text fields get characters from the key press itself, so typing works whether or not the
// game's message loop translates keys. Flag 4 leaves the keyboard's dead-key state alone.
void FeedTypedChars(unsigned vk, LPARAM lp, const hsb::InputState& in)
{
	BYTE state[256] = {};
	if (!GetKeyboardState(state)) return;
	wchar_t buf[4] = {};
	const UINT scan = static_cast<UINT>((lp >> 16) & 0xFF);
	const int n = ToUnicodeEx(vk, scan, state, buf, 4, 4, GetKeyboardLayout(0));
	for (int i = 0; i < n && i < 4; ++i) {
		const unsigned code = static_cast<unsigned>(buf[i]);
		if (!hsb::CharForText(code, in)) continue;
		Feed("C " + std::to_string(code), false);
		g_cChars.fetch_add(1);
	}
}

// Purpose: apply the 0.2 input rules (hsb_input.h) to one window message.
// Inputs: the message, the movie's last STATE and HOT. Outputs: true when the game must not
//    see the message. Dependencies: Feed (tokens for the movie), the press ledgers.
bool HandleBuilderInput(HWND hwnd, UINT msg, WPARAM wp, LPARAM lp)
{
	hsb::InputState in;
	hsb::HotArea hot;
	{
		std::lock_guard lock(g_inMu);
		in = g_in;
		hot = g_hot;
	}
	switch (msg) {
	case WM_INPUT:
		g_cRaw.fetch_add(1);
		return false;
	case WM_MOUSEMOVE: {
		int sx = 0;
		int sy = 0;
		ToStage(hwnd, GET_X_LPARAM(lp), GET_Y_LPARAM(lp), in, sx, sy);
		if (hsb::MoveEdge().feed) Feed("M M " + std::to_string(sx) + " " + std::to_string(sy), true);
		return false;
	}
	case WM_LBUTTONDOWN:
	case WM_LBUTTONDBLCLK:
	case WM_LBUTTONUP:
	case WM_RBUTTONDOWN:
	case WM_RBUTTONDBLCLK:
	case WM_RBUTTONUP:
	case WM_MBUTTONDOWN:
	case WM_MBUTTONDBLCLK:
	case WM_MBUTTONUP: {
		const unsigned button = MouseButton(msg);
		const bool release = IsButtonRelease(msg);
		int sx = 0;
		int sy = 0;
		ToStage(hwnd, GET_X_LPARAM(lp), GET_Y_LPARAM(lp), in, sx, sy);
		const hsb::PointerCall call = hsb::PointerEdge(!release, release, false, hsb::HotContains(hot, sx, sy), g_buttonsEaten.Held(button));
		g_buttonsEaten.Set(button, !release && call.eat);
		if (!release) {
			g_cPresses.fetch_add(1);
			if (call.eat) g_cEaten.fetch_add(1);
		}
		// Horizon controls answer the left button only; the others are only kept from the game.
		if (button == 1 && call.feed) {
			Feed(std::string(release ? "M U " : "M D ") + std::to_string(sx) + " " + std::to_string(sy) + (call.eat ? " 1" : " 0"), false);
		}
		return call.eat;
	}
	case WM_MOUSEWHEEL: {
		POINT pt{ GET_X_LPARAM(lp), GET_Y_LPARAM(lp) };
		ScreenToClient(hwnd, &pt);
		int sx = 0;
		int sy = 0;
		ToStage(hwnd, pt.x, pt.y, in, sx, sy);
		const hsb::PointerCall call = hsb::PointerEdge(false, false, true, hsb::HotContains(hot, sx, sy), false);
		const int steps = hsb::WheelSteps(GET_WHEEL_DELTA_WPARAM(wp), g_wheelRest);
		g_cWheels.fetch_add(1);
		if (call.feed && steps != 0) {
			Feed("W " + std::to_string(steps) + " " + std::to_string(sx) + " " + std::to_string(sy) + (call.eat ? " 1" : " 0"), false);
		}
		return call.eat;
	}
	case WM_KEYDOWN:
	case WM_SYSKEYDOWN: {
		const unsigned vk = static_cast<unsigned>(wp) & 0xFFu;
		const bool repeat = (lp & 0x40000000) != 0;
		const bool ctrl = (GetKeyState(VK_CONTROL) & 0x8000) != 0;
		const bool shift = (GetKeyState(VK_SHIFT) & 0x8000) != 0;
		const bool alt = msg == WM_SYSKEYDOWN || (GetKeyState(VK_MENU) & 0x8000) != 0;
		const hsb::KeyCall call = hsb::KeyPress(vk, KeyChar(vk), ctrl, alt, shift, repeat, in);
		if (!repeat) g_keysEaten.Set(vk, call.eat);
		// The auto-repeats of a press Horizon took stay Horizon's until the release, even after
		// that press closed the last popup: the game sees both halves of a key press or neither.
		const bool eat = call.eat || (repeat && g_keysEaten.Held(vk));
		if (call.token[0] != '\0') Feed(std::string("K ") + call.token, false);
		// A translated WM_CHAR follows its key press before the next press, so it goes with
		// the press: the game never gets a character for a key it did not see.
		g_eatChar = eat;
		if (eat) {
			g_cKeys.fetch_add(1);
			if (in.text && call.eat) FeedTypedChars(vk, lp, in);
		}
		return eat;
	}
	case WM_KEYUP:
	case WM_SYSKEYUP: {
		const unsigned vk = static_cast<unsigned>(wp) & 0xFFu;
		const bool held = g_keysEaten.Held(vk);
		g_keysEaten.Set(vk, false);
		return held;
	}
	case WM_CHAR:
	case WM_DEADCHAR: {
		const bool eat = g_eatChar || in.capture || in.text || in.arrange;
		g_eatChar = false;
		return eat;
	}
	default:
		return false;
	}
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
	if (g_menuOpen.load() && g_movieGen.load() == kMovieGen) {
		if (HandleBuilderInput(hwnd, msg, wp, lp)) return 0;
	} else if (msg == WM_KEYDOWN || msg == WM_LBUTTONDOWN || msg == WM_RBUTTONDOWN || msg == WM_MBUTTONDOWN) {
		g_keysEaten.Clear();
		g_buttonsEaten.Clear();
		g_eatChar = false;
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

// Later values for the same key replace earlier ones; the first position is kept.
void QueueSetting(const hsb::Setting& s)
{
	std::lock_guard lock(g_iniMu);
	for (auto& row : g_updates) {
		if (hsb::EqualsFold(row.section, s.section) && hsb::EqualsFold(row.key, s.key)) {
			row = s;
			return;
		}
	}
	if (g_updates.size() < hsb::kMaxSettingUpdates) g_updates.push_back(s);
}

// Purpose: act on one line from hsbTakeLines.
// Inputs: the raw line (protocol lines are parsed before any log trimming) and its log-safe copy.
// Outputs: input state, swallow rectangles, queued settings, or one log fact.
// Dependencies: hsb_input.h (STATE, HOT), hsb_settings.h (SET, ARRANGE whitelist).
void NoteMovieLine(const std::string& raw, const std::string& clean)
{
	if (raw.rfind("STATE ", 0) == 0) {
		std::lock_guard lock(g_inMu);
		g_in = hsb::ParseState(raw, g_in);
		return;
	}
	if (raw.rfind("HOT ", 0) == 0) {
		hsb::HotArea area = hsb::ParseHot(std::string_view(raw).substr(4));
		std::lock_guard lock(g_inMu);
		g_hot = std::move(area);
		return;
	}
	if (raw.rfind("SET ", 0) == 0 || raw.rfind("ARRANGE ", 0) == 0) {
		const bool set = raw[0] == 'S';
		const std::string_view body = std::string_view(raw).substr(set ? 4 : 8);
		if (body == "END") {
			g_writeIni.store(true);
			return;
		}
		if (!set && (body == "open" || body == "saved" || body == "cancel")) {
			Fact("movie", clean);
			return;
		}
		hsb::Setting s;
		if (set ? hsb::ParseSetBody(body, s) : hsb::ParseArrangeBody(body, s)) {
			QueueSetting(s);
		} else {
			std::lock_guard lock(g_iniMu);
			++g_setRejected;
		}
		return;
	}
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

// A splice that lacks a method would fail every frame, so each method's failure is logged
// once per visit (missBit is that method's bit in g_invokeMiss).
void InvokeText(RE::IMenu* menu, const char* name, unsigned missBit, const std::string& text)
{
	if (!menu || text.empty()) return;
	RE::Scaleform::GFx::Value arg;
	arg = text.c_str();
	if (menu->menuObj.Invoke(name, nullptr, &arg, 1)) return;
	if ((g_invokeMiss.fetch_or(missBit) & missBit) == 0) Fact("movie", std::string("invoke failed ") + name);
}

std::string TakeReplies()
{
	std::deque<std::string> batch;
	{
		std::lock_guard lock(g_fileMu);
		batch.swap(g_fileRep);
	}
	std::string out;
	for (const auto& line : batch) {
		if (!out.empty()) out += '\n';
		out += line;
	}
	return out;
}

// Purpose: hand the movie what the plugin collected since the last frame.
// Inputs: the open menu. Outputs: hsbApply (settings), hsbSetDebug, hsbFeed (input tokens),
//    hsbSaved (ini write result), hsbFiles (file replies). Runs on the movie's thread.
void DriveMovie(RE::IMenu* menu)
{
	if (!menu) return;
	if (g_applyPending.exchange(false)) {
		std::string blob;
		{
			std::lock_guard lock(g_iniMu);
			blob = g_apply;
		}
		InvokeText(menu, "hsbApply", 1u, blob);
	}
	if (g_probeDebug.load() && !g_debugSent.exchange(true)) {
		RE::Scaleform::GFx::Value arg;
		arg = 1.0;
		menu->menuObj.Invoke("hsbSetDebug", nullptr, &arg, 1);
	}
	InvokeText(menu, "hsbFeed", 2u, TakeFeed());
	const int saved = g_saveResult.exchange(-1);
	if (saved >= 0) {
		RE::Scaleform::GFx::Value arg;
		arg = static_cast<double>(saved);
		menu->menuObj.Invoke("hsbSaved", nullptr, &arg, 1);
	}
	InvokeText(menu, "hsbFiles", 4u, TakeReplies());
}

// Requests beyond the queue cap fail at once, so the movie never waits on a lost request.
void QueueFileRequests(const std::string& blob)
{
	std::size_t at = 0;
	unsigned refused = 0;
	while (at < blob.size()) {
		const auto next = blob.find('\n', at);
		std::string line = blob.substr(at, next == std::string::npos ? std::string::npos : next - at);
		at = next == std::string::npos ? blob.size() : next + 1;
		if (line.empty()) continue;
		std::lock_guard lock(g_fileMu);
		if (g_fileReq.size() < kFileQueueCap) {
			g_fileReq.push_back(std::move(line));
			continue;
		}
		hsb::FileRequest r;
		if (hsb::ParseFileRequest(line, r)) g_fileRep.push_back(hsb::FileReply(r.id, false, ""));
		++refused;
	}
	if (refused > 0) Fact("files", "queue full refused=" + std::to_string(refused));
}

// Purpose: one poll of the builder movie. HsbAdvance runs it from the movie's AdvanceFrame,
//    so every Scaleform call happens on the thread that advances the movie.
// Inputs: none; reads the open SpaceshipEditorMenu. Outputs: until the movie answers, the
//    hsbProbePing handshake (only a 0.2 movie gets fed input); then DriveMovie's calls, the
//    movie's log lines (NoteMovieLine) and its file requests (QueueFileRequests).
// Dependencies: RE::UI, DriveMovie, NoteMovieLine, QueueFileRequests. g_inShipPoll refuses
//    re-entry.
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
		// Only a 0.2 movie takes fed input. Any other movie keeps the game's own input.
		if (invoked && ping.rfind("0.2", 0) == 0) g_movieGen.store(kMovieGen);
		if (invoked && !ping.empty()) g_pingDone.store(true);
		else if (g_pingTries.fetch_add(1) > 40) {
			g_pingDone.store(true);
			Fact("F19", "invoke still false after retries");
		}
	}
	if (!menu->menuObj.IsObject()) return;
	if (!g_mapped.exchange(true)) NoteWindowMap(menu.get());
	if (g_movieGen.load() == kMovieGen) DriveMovie(menu.get());
	RE::Scaleform::GFx::Value lines;
	if (menu->menuObj.Invoke("hsbTakeLines", &lines)) {
		const std::string blob = InvokeString(lines);
		std::size_t at = 0;
		while (at < blob.size()) {
			const auto next = blob.find('\n', at);
			std::string raw = blob.substr(at, next == std::string::npos ? std::string::npos : next - at);
			at = next == std::string::npos ? blob.size() : next + 1;
			if (!raw.empty() && raw.back() == '\r') raw.pop_back();
			const std::string clean = hsb::SanitizeFact(raw);
			if (!clean.empty()) NoteMovieLine(raw, clean);
		}
	}
	if (g_movieGen.load() != kMovieGen) return;
	RE::Scaleform::GFx::Value files;
	if (menu->menuObj.Invoke("hsbTakeFiles", &files)) {
		const std::string blob = InvokeString(files);
		if (!blob.empty()) QueueFileRequests(blob);
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
	if (!g_probeDebug.load()) {
		g_hudPending.store(false);
		return;
	}
	if (!g_hudPending.exchange(false)) return;
	TryHudOnce(onShip ? "ship-advance" : "hud-advance");
}

// Purpose: the AdvanceFrame hook. Runs the game's original first, then, while the builder
//    is open and this is its movie, polls it: every frame for a 0.2 movie, otherwise at the
//    probe's poll interval. MaybeHudOnThisAdvance posts the debug HUD line ([Debug] Probe=1).
// Inputs: the advancing movie root and the game's flag. Outputs: none.
// Dependencies: g_origAdvance (InstallAdvanceHook), PollShipOnAdvance. A C++ exception from
//    the poll is logged (F19) and dropped so the game's frame always completes.
void HsbAdvance(RE::Scaleform::GFx::ASMovieRootBase* self, bool next)
{
	const auto orig = g_origAdvance.load();
	if (orig && orig != &HsbAdvance) orig(self, next);
	MaybeHudOnThisAdvance(self);
	auto* ship = g_shipRoot.load();
	if (!self || !ship || self != ship || !g_menuOpen.load()) return;
	const auto now = GetTickCount64();
	const auto last = g_lastPoll.load();
	if (g_movieGen.load() != kMovieGen && !hsb::ProbePollDue(now, last)) return;
	g_lastPoll.store(now);
	try { PollShipOnAdvance(); } catch (...) {
		Fact("F19", "movie poll faulted");
	}
}

// Purpose: chain HsbAdvance into the movie root's AdvanceFrame (vtable slot 2), once.
// Inputs: the builder movie's root. Outputs: g_shipRoot always; g_origAdvance and
//    g_advanceHooked when the slot is written. A slot that already holds HsbAdvance counts as
//    hooked. Dependencies: REL::WriteSafeData. Every movie root of that class shares the
//    vtable, so HsbAdvance checks which root is advancing before it polls.
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
	// Purpose: track SpaceshipEditorMenu opening and closing. Inputs: the menu event.
	// Outputs: on open, a fresh visit: input, file queues, handshake and poll state reset, and
	//    the settings rebuilt on the next job tick (g_needApply). On close, the visit's input
	//    counts are logged and the debug HUD line is armed. Other sinks always see the event.
	// Dependencies: ResetInput, CountsNow, g_fileMu.
	RE::BSEventNotifyControl ProcessEvent(const RE::MenuOpenCloseEvent& event, RE::BSTEventSource<RE::MenuOpenCloseEvent>*) override
	{
		if (event.menuName == hsb::kMenuName) {
			if (!event.opening && g_movieGen.load() == kMovieGen) Fact("input", CountsNow());
			g_menuOpen.store(event.opening);
			g_wantHook.store(event.opening);
			g_movieGen.store(0);
			if (event.opening) {
				ResetInput();
				{
					std::lock_guard lock(g_fileMu);
					g_fileReq.clear();
					g_fileRep.clear();
				}
				g_pingDone.store(false);
				g_pingTries.store(0);
				g_lastPoll.store(0);
				g_resetForms.store(true);
				g_removeSettled.store(false);
				g_mapped.store(false);
				g_debugSent.store(false);
				g_invokeMiss.store(0);
				g_needApply.store(true);
				Fact("F19", "builder opened");
				Fact("F37", GetModuleHandleA("HorizonUI.dll") ? "HorizonUI.dll is loaded" : "HorizonUI.dll is not loaded");
				LogCursor("open");
			} else {
				Fact("F19", "builder closed");
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

// The HUD's own folder, built the way the HUD builds it (src/main.cpp IniPath): the game
// executable's folder plus Data\Interface\HorizonUI\. Empty when the path is not known.
std::wstring HudIniDir()
{
	wchar_t exe[MAX_PATH] = {};
	const DWORD n = GetModuleFileNameW(nullptr, exe, MAX_PATH);
	if (n == 0 || n >= MAX_PATH) return {};
	std::wstring dir(exe, n);
	const auto slash = dir.find_last_of(L"\\/");
	if (slash == std::wstring::npos) return {};
	dir.resize(slash);
	return dir + L"\\Data\\Interface\\HorizonUI\\";
}

bool CoreIniMayRead(const std::wstring& path)
{
	return hsb::HudIniMayRead(NarrowPath(path), NarrowPath(HudIniDir()));
}

// The largest ini (ours or the HUD's) the plugin reads in full.
constexpr std::size_t kUserIniCap = 200000;

std::string ReadTextFile(const std::wstring& path, bool iniUser)
{
	const std::string narrow = NarrowPath(path);
	if (iniUser) {
		if (!hsb::IniMayWrite(narrow)) return {};
	} else if (!CoreIniMayRead(path)) {
		return {};
	}
	std::string out;
	if (!ReadCapped(path, kUserIniCap, out)) return {};
	return out;
}

// The folders a share file can live in. Packs installed by a mod manager are in the game's
// Data folder; packs and exports in Documents\My Games\Starfield\Data are checked first.
std::vector<std::wstring> ShareDirs(std::string_view kind, std::string_view folder)
{
	std::vector<std::wstring> dirs;
	const std::wstring tail = WidenAscii(hsb::KindFolder(kind)) + L"\\" + WidenAscii(folder) + L"\\";
	if (!g_docsBuilder.empty()) dirs.push_back(g_docsBuilder + tail);
	if (folder == "packs" && !g_gameBuilder.empty()) dirs.push_back(g_gameBuilder + tail);
	return dirs;
}

std::string NarrowName(const wchar_t* name)
{
	std::string out;
	for (const wchar_t* p = name; *p; ++p) {
		if (*p <= 0 || *p >= 128) return {};
		out.push_back(static_cast<char>(*p));
	}
	return out;
}

// Purpose: list the pill or scheme files the movie may read. Inputs: the kind (PILLS or
//    SCHEMES). Outputs: one hsb::ListRow per file, user files before packs and Documents
//    before the game's Data folder, at most kMaxListFiles. Names that are not plain ASCII or
//    not safe, files over kMaxShareBytes and case-insensitive duplicates are skipped.
// Dependencies: ShareDirs, hsb::SafeShareName.
std::string ListShares(std::string_view kind)
{
	std::vector<std::string> rows;
	std::vector<std::string> seen;
	for (const char* folder : { "user", "packs" }) {
		for (const auto& dir : ShareDirs(kind, folder)) {
			WIN32_FIND_DATAW found{};
			const std::wstring pattern = dir + L"*" + WidenAscii(hsb::KindExtension(kind));
			HANDLE find = FindFirstFileW(pattern.c_str(), &found);
			if (find == INVALID_HANDLE_VALUE) continue;
			do {
				if ((found.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0) continue;
				const std::string name = NarrowName(found.cFileName);
				if (!hsb::SafeShareName(name, kind)) continue;
				const unsigned long long bytes = (static_cast<unsigned long long>(found.nFileSizeHigh) << 32) | found.nFileSizeLow;
				if (bytes > hsb::kMaxShareBytes) continue;
				const std::string key = std::string(folder) + "/" + name;
				bool dup = false;
				for (const auto& s : seen) dup = dup || hsb::EqualsFold(s, key);
				if (dup) continue;
				seen.push_back(key);
				rows.push_back(hsb::ListRow(folder, name, bytes));
			} while (rows.size() < hsb::kMaxListFiles && FindNextFileW(find, &found));
			FindClose(find);
			if (rows.size() >= hsb::kMaxListFiles) break;
		}
	}
	std::string out;
	for (const auto& row : rows) {
		if (!out.empty()) out += '\n';
		out += row;
	}
	return out;
}

// Job thread only.
hsb::ProfileState g_profileState;

// Purpose: run one file request from the movie.
// Inputs: one request line (see hsb_files.h). Outputs: the reply line for hsbFiles; a line
//    that does not parse still gets a failure reply when it starts with a request id.
// Rules: hsb::CheckRequest decides what may happen; hsb::BuilderFileMayTouch gates every path
//    before it is opened. Nothing is deleted. The profile follows hsb_profile.h on the
//    Documents shipbuilder folder: a read says why it failed ("missing", "damaged" or
//    "unreadable") so the movie never saves over a profile it could not use; a write first
//    backs up the old profile, read whole, to ShipBuilderPills.bak, unless it is blank or the
//    visit started without a loaded profile (that visit keeps the backup as it was); a
//    damaged profile is renamed to ShipBuilderPills.bad.json, never over an earlier one, and
//    when that fails, writes are refused for the rest of the visit. A share file with a NUL
//    byte is refused, as no reply may carry one. A share write makes a new file and never
//    replaces one: a name already taken fails with "exists" (hsb::kShareExists).
// Logging: kind, verb and result only.
std::string RunFileRequest(const std::string& line)
{
	hsb::FileRequest r;
	if (!hsb::ParseFileRequest(line, r)) {
		Fact("files", "request unreadable");
		const std::string id = hsb::RequestId(line);
		return id.empty() ? std::string() : hsb::FileReply(id, false, "");
	}
	const hsb::FileVerb verb = hsb::CheckRequest(r);
	bool ok = false;
	std::string payload;
	std::string failReason;
	Win32ProfileDisk disk(g_docsBuilder);
	switch (verb) {
	case hsb::FileVerb::kProfileRead: {
		hsb::ProfileResult result = hsb::ProfileRead(disk, g_profileState);
		ok = result.ok;
		if (ok) payload = std::move(result.payload);
		else failReason = std::move(result.payload);
		break;
	}
	case hsb::FileVerb::kProfileWrite: {
		hsb::ProfileResult result = hsb::ProfileWrite(disk, g_profileState, hsb::UnescapeText(r.body));
		ok = result.ok;
		failReason = std::move(result.payload);
		break;
	}
	case hsb::FileVerb::kProfileBad: {
		hsb::ProfileResult result = hsb::ProfileSetAside(disk, g_profileState);
		ok = result.ok;
		failReason = std::move(result.payload);
		break;
	}
	case hsb::FileVerb::kList:
		payload = ListShares(r.kind);
		ok = true;
		break;
	case hsb::FileVerb::kRead:
		for (const auto& dir : ShareDirs(r.kind, r.args[0])) {
			const std::wstring path = dir + WidenAscii(r.args[1]);
			if (!hsb::BuilderFileMayTouch(NarrowPath(path), false) || !FileExists(path)) continue;
			ok = ReadCapped(path, hsb::kMaxShareBytes, payload) && !hsb::HasNul(payload);
			break;
		}
		break;
	case hsb::FileVerb::kWrite: {
		const std::string body = hsb::UnescapeText(r.body);
		const auto dirs = ShareDirs(r.kind, "user");
		if (dirs.empty() || body.size() > hsb::kMaxShareBytes) break;
		const std::wstring path = dirs.front() + WidenAscii(r.args[1]);
		if (!hsb::BuilderFileMayTouch(NarrowPath(path), true)) break;
		EnsureDirsFor(path);
		const hsb::MoveResult wrote = WriteNew(path, body);
		ok = wrote == hsb::MoveResult::kOk;
		if (ok) payload = r.args[1];
		else if (wrote == hsb::MoveResult::kExists) failReason = std::string(hsb::kShareExists);
		break;
	}
	case hsb::FileVerb::kBad:
		break;
	}
	if (!ok) payload = failReason;
	Fact("files", r.kind.substr(0, 8) + " " + r.verb.substr(0, 8) + (verb == hsb::FileVerb::kBad ? " refused" : (ok ? " ok" : " failed")) +
		(failReason.empty() ? std::string() : " " + failReason));
	return hsb::FileReply(r.id, ok, payload);
}

// Purpose: run up to kFileJobsPerTick queued file requests on the job thread.
// Inputs: g_fileReq (QueueFileRequests). Outputs: reply lines in g_fileRep, which DriveMovie
//    hands to the movie through hsbFiles. Dependencies: RunFileRequest; g_fileMu guards both
//    queues.
void RunFileJobs()
{
	for (int i = 0; i < kFileJobsPerTick; ++i) {
		std::string line;
		{
			std::lock_guard lock(g_fileMu);
			if (g_fileReq.empty()) return;
			line = std::move(g_fileReq.front());
			g_fileReq.pop_front();
		}
		std::string reply = RunFileRequest(line);
		if (reply.empty()) continue;
		std::lock_guard lock(g_fileMu);
		g_fileRep.push_back(std::move(reply));
	}
}

std::wstring GameDataBuilderDir()
{
	wchar_t exe[MAX_PATH] = {};
	const DWORD n = GetModuleFileNameW(nullptr, exe, MAX_PATH);
	if (n == 0 || n >= MAX_PATH) return {};
	std::wstring dir(exe, n);
	const auto slash = dir.find_last_of(L"\\/");
	if (slash == std::wstring::npos) return {};
	dir.resize(slash);
	return dir + L"\\Data\\Interface\\HorizonUI\\shipbuilder\\";
}

bool AnyFile(const std::wstring& pattern)
{
	WIN32_FIND_DATAW found{};
	HANDLE find = FindFirstFileW(pattern.c_str(), &found);
	if (find == INVALID_HANDLE_VALUE) return false;
	FindClose(find);
	return true;
}

// StarUI Ship Builder files on disk while Horizon runs: the movie shows the mock 11 notice.
// A loaded StarUI module is a conflict, and the movie stands down (mock 10). Both are name
// checks; StarUI's full file list is not verified, so README_P0.md lists them as unknowns.
bool StarUiFilesPresent(const std::wstring& docsRoot)
{
	wchar_t exe[MAX_PATH] = {};
	const DWORD n = GetModuleFileNameW(nullptr, exe, MAX_PATH);
	if (n == 0 || n >= MAX_PATH) return false;
	std::wstring game(exe, n);
	const auto slash = game.find_last_of(L"\\/");
	if (slash == std::wstring::npos) return false;
	game.resize(slash);
	const std::wstring docsData = docsRoot + L"\\My Games\\Starfield\\Data";
	for (const std::wstring& data : { game + L"\\Data", docsData }) {
		if (AnyFile(data + L"\\SFSE\\Plugins\\StarUI*") || AnyFile(data + L"\\Interface\\StarUI*") || AnyFile(data + L"\\StarUI*Ship*"))
			return true;
	}
	return false;
}

// Purpose: build the hsbApply text from the user ini and the HUD's accent.
// Inputs: HorizonShipBuilder.user.ini (whitelisted values only); the HUD's HorizonUI.user.ini
//    and HorizonUI.default.ini from the HUD's own folder (read only, for "follow the HUD"),
//    layered the way the HUD layers them.
// Outputs: g_apply, one key=value per line, and g_applyPending for the movie thread.
// Dependencies: hsb_settings.h (whitelist, LayerHudAccent, HudIniMayRead).
void BuildApply()
{
	PWSTR docs = nullptr;
	if (FAILED(SHGetKnownFolderPath(FOLDERID_Documents, 0, nullptr, &docs)) || !docs) return;
	std::wstring root = docs;
	CoTaskMemFree(docs);
	g_docsBuilder = root + L"\\My Games\\Starfield\\Data\\Interface\\HorizonUI\\shipbuilder\\";
	g_gameBuilder = GameDataBuilderDir();
	g_iniPath = g_docsBuilder + L"HorizonShipBuilder.user.ini";
	const std::string ini = ReadTextFile(g_iniPath, true);
	const std::wstring hudDir = HudIniDir();
	const bool hudUserFound = !hudDir.empty() && FileExists(hudDir + L"HorizonUI.user.ini");
	const bool hudDefaultFound = !hudDir.empty() && FileExists(hudDir + L"HorizonUI.default.ini");
	const std::string coreUser = hudUserFound ? ReadTextFile(hudDir + L"HorizonUI.user.ini", false) : std::string();
	const std::string coreDefault = hudDefaultFound ? ReadTextFile(hudDir + L"HorizonUI.default.ini", false) : std::string();
	const bool coreFound = hudUserFound || hudDefaultFound;
	const hsb::HudAccent hud = hsb::LayerHudAccent(coreUser, coreDefault);
	const std::string coreHex = hud.hex;
	const int coreAccent = coreFound ? hsb::ResolveAccent(hud.color, coreHex, false, 0, "") : -1;
	const std::string hex = hsb::SettingOr(ini, "Style", "AccentHex", "");
	const bool probe = hsb::SettingOr(ini, "Debug", "Probe", "0") == "1";
	g_probeDebug.store(probe);
	const bool conflict = GetModuleHandleA("StarUIShipBuilder.dll") != nullptr;
	std::string blob;
	blob += "accent=" + hsb::SettingOr(ini, "Style", "AccentColor", std::to_string(hsb::kAccentDefault)) + "\n";
	blob += "hex=" + (hex.empty() ? std::string("-") : hex) + "\n";
	blob += std::string("core=") + (coreFound ? "1" : "0") + "\n";
	blob += "coreaccent=" + std::to_string(coreAccent) + "\n";
	blob += "corehex=" + (coreAccent == 13 && !coreHex.empty() ? coreHex : std::string("-")) + "\n";
	blob += std::string("probe=") + (probe ? "1" : "0") + "\n";
	blob += "margin=" + hsb::SettingOr(ini, "Layout", "ScreenMargin", std::to_string(hsb::kMarginDefault)) + "\n";
	blob += std::string("conflict=") + (conflict ? "1" : "0") + "\n";
	blob += std::string("starfiles=") + (!conflict && StarUiFilesPresent(root) ? "1" : "0") + "\n";
	blob += std::string("keys=") + (hsb::SettingOr(ini, "Keys", "Arrange", "L") == "0" ? "0" : "1") + "\n";
	blob += "opacity=" + hsb::SettingOr(ini, "Style", "CardOpacity", "1.00") + "\n";
	blob += "scale=" + hsb::SettingOr(ini, "Layout", "UiScale", "1.00") + "\n";
	blob += "density=" + hsb::SettingOr(ini, "Layout", "Density", "compact") + "\n";
	blob += "bymaker=" + hsb::SettingOr(ini, "Layout", "GroupByMaker", "0") + "\n";
	blob += "remember=" + hsb::SettingOr(ini, "Layout", "RememberLayout", "1") + "\n";
	blob += "notice=" + hsb::SettingOr(ini, "Notices", "ShowConflictNotice", "1") + "\n";
	blob += "keyhide=" + hsb::SettingOr(ini, "Keys", "HideAll", "H") + "\n";
	blob += "keyfind=" + hsb::SettingOr(ini, "Keys", "Find", "/") + "\n";
	for (const auto& s : hsb::SectionSettings(ini, "Panels")) blob += "panel." + s.key + "=" + s.value + "\n";
	for (const auto& s : hsb::SectionSettings(ini, "Columns")) blob += "col." + s.key + "=" + s.value + "\n";
	const char* panels[] = { "Power", "Module", "Credits", "Browser", "Stats", "Hints", "Cluster" };
	for (const char* name : panels) {
		for (const char* axis : { "X", "Y" }) {
			const std::string key = std::string(name) + axis;
			blob += key + "=" + hsb::SettingOr(ini, "Arrange", key, "-1") + "\n";
		}
	}
	blob += "ArrangeBarX=" + hsb::SettingOr(ini, "Arrange", "ArrangeBarX", "0") + "\n";
	blob += "ArrangeBarY=" + hsb::SettingOr(ini, "Arrange", "ArrangeBarY", "0") + "\n";
	{
		std::lock_guard lock(g_iniMu);
		g_apply = blob;
	}
	g_applyPending.store(true);
}

// Settings that could not be written go back in the queue for the next SET END.
void RequeueUpdates(const std::vector<hsb::Setting>& failed)
{
	std::lock_guard lock(g_iniMu);
	hsb::RequeueSettings(g_updates, failed);
}

// Purpose: merge the queued settings into HorizonShipBuilder.user.ini (on the job thread,
//    after the movie's SET END). Inputs: g_updates and the file on disk. Outputs: the merged
//    file, g_saveResult (1 saved, 0 not saved) for the movie, and one log fact.
// Rules: an existing file that cannot be read in full is never merged as if it were empty
//    (hsb::UserReadAllowsWrite); a skipped or failed write puts the batch back in the queue.
// Dependencies: hsb_settings.h (whitelist, merge, requeue), ReadCapped, WriteReplace.
void WriteIniNow()
{
	if (g_iniPath.empty()) BuildApply();
	if (!hsb::IniMayWrite(NarrowPath(g_iniPath))) {
		g_saveResult.store(0);
		return;
	}
	std::vector<hsb::Setting> updates;
	unsigned rejected = 0;
	{
		std::lock_guard lock(g_iniMu);
		updates.swap(g_updates);
		rejected = g_setRejected;
		g_setRejected = 0;
	}
	if (rejected > 0) Fact("ini", "settings refused n=" + std::to_string(rejected));
	if (updates.empty()) {
		g_saveResult.store(1);
		return;
	}
	EnsureDirsFor(g_iniPath);
	std::string existing;
	const bool exists = FileExists(g_iniPath);
	const bool readOk = exists && ReadCapped(g_iniPath, kUserIniCap, existing);
	if (!hsb::UserReadAllowsWrite(exists, readOk)) {
		RequeueUpdates(updates);
		g_saveResult.store(0);
		Fact("ini", "user file unreadable; write skipped n=" + std::to_string(updates.size()));
		return;
	}
	const std::string merged = hsb::MergeSettings(existing, updates);
	if (!WriteReplace(g_iniPath, merged)) {
		RequeueUpdates(updates);
		g_saveResult.store(0);
		Fact("ini", "user file write failed n=" + std::to_string(updates.size()));
		return;
	}
	g_saveResult.store(1);
	Fact("ini", "user file merged n=" + std::to_string(updates.size()));
}

// Purpose: the permanent SFSE task, run on a BSJobs worker every tick. It flushes the log,
//    rebuilds the settings when a visit starts, merges a pending ini save and runs file jobs.
//    While the builder is open it keeps the window hook installed: a posted ping that never
//    reaches the hook makes the window thread confirm or reinstall it. After close it removes
//    the hook. Inputs: the flags the menu sink and the movie poll set. Outputs: none.
// Dependencies: FlushLog, BuildApply, WriteIniNow, RunFileJobs, RunOnWindowThread. The tick
//    makes no Scaleform call and opens no file itself (the logic test checks its body).
// JOBTICK-BEGIN
void JobTick()
{
	FlushLog();
	if (g_needApply.exchange(false)) BuildApply();
	if (g_writeIni.exchange(false)) WriteIniNow();
	RunFileJobs();
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
	REX::INFO("HorizonShipBuilder {}", HSB_FILE_VERSION_STR);
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
