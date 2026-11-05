// Purpose: read-only SFSE probe for SpaceshipEditorMenu. It writes one log
// and does not change the ship, a save, or any other file.
// Inputs: menu open and close, window messages, movie lines, form ids.
// Outputs: Documents\My Games\Starfield\SFSE\Logs\HorizonShipBuilder_probe.log
// Author: Moragar. Last modified: 2026-11-04.

#include "hsb_guard.h"
#include "hsb_version.h"

#define WIN32_LEAN_AND_MEAN
#include <Windows.h>
#include <objbase.h>
#include <shlobj.h>

#include <atomic>
#include <cstdio>
#include <mutex>
#include <string>

namespace {

std::mutex g_mu;
std::wstring g_logPath;
bool g_logReady = false;
std::atomic<bool> g_open{ false };
bool g_hooked = false;
bool g_pingDone = false;
bool g_hudTried = false;
bool g_formCapped = false;
int g_formCount = 0;
int g_pingTries = 0;
HWND g_hwnd = nullptr;
WNDPROC g_prev = nullptr;
std::atomic<DWORD> g_lastMove{ 0 };

std::string NarrowPath(const std::wstring& path)
{
	std::string out;
	out.reserve(path.size());
	for (wchar_t c : path) {
		out.push_back(c > 0 && c < 128 ? static_cast<char>(c) : '?');
	}
	return out;
}

constexpr const char* kHudText =
	"Horizon Ship Builder probe: this line is only a test. Nothing was changed.";

void AppendUnlocked(const std::string& line)
{
	if (!g_logReady || g_logPath.empty()) return;
	if (!hsb::ProbeMayAppend(NarrowPath(g_logPath))) return;
	FILE* file = nullptr;
	if (_wfopen_s(&file, g_logPath.c_str(), L"ab") != 0 || !file) return;
	fwrite(line.data(), 1, line.size(), file);
	fwrite("\n", 1, 1, file);
	fclose(file);
}

void Fact(std::string_view id, std::string_view text)
{
	std::lock_guard lock(g_mu);
	AppendUnlocked(hsb::FactLine(id, text));
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
	const std::string narrow = NarrowPath(path);
	if (!hsb::ProbeMayAppend(narrow)) {
		REX::INFO("HorizonShipBuilder probe: log path rejected");
		return;
	}
	std::lock_guard lock(g_mu);
	g_logPath = path;
	g_logReady = true;
	AppendUnlocked(hsb::FactLine("boot", "HorizonShipBuilder " HSB_FILE_VERSION_STR " read-only"));
	AppendUnlocked(hsb::FactLine("boot", "writes this log only; does not change the ship or a save"));
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
	WNDPROC chain = nullptr;
	bool logging = false;
	{
		std::lock_guard lock(g_mu);
		chain = g_prev;
		logging = g_open.load();
	}
	const bool down = msg == WM_KEYDOWN || msg == WM_SYSKEYDOWN;
	const bool mouse = msg == WM_LBUTTONDOWN || msg == WM_LBUTTONUP || msg == WM_RBUTTONDOWN ||
		msg == WM_RBUTTONUP || msg == WM_MBUTTONDOWN || msg == WM_MBUTTONUP || msg == WM_MOUSEWHEEL ||
		msg == WM_MOUSEMOVE;
	if (logging && (down || mouse)) {
		bool skip = false;
		if (msg == WM_MOUSEMOVE) {
			const DWORD now = GetTickCount();
			const DWORD last = g_lastMove.load();
			if (now - last < 100) skip = true;
			else g_lastMove.store(now);
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

void InstallHook()
{
	HWND hwnd = nullptr;
	EnumWindows(FindGameWindow, reinterpret_cast<LPARAM>(&hwnd));
	if (!hwnd) {
		Fact("F37", "window not found; hook not installed");
		return;
	}
	std::lock_guard lock(g_mu);
	if (g_hooked) {
		AppendUnlocked(hsb::FactLine("F37", "hook already in the chain"));
		return;
	}
	auto* current = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	if (current == ProbeWnd) {
		g_hooked = true;
		g_hwnd = hwnd;
		Fact("F37", "probe procedure already installed");
		return;
	}
	g_prev = reinterpret_cast<WNDPROC>(SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(ProbeWnd)));
	g_hwnd = hwnd;
	auto* now = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	if (now != ProbeWnd) {
		g_prev = nullptr;
		g_hwnd = nullptr;
		AppendUnlocked(hsb::FactLine("F37", "hook installed=0"));
		return;
	}
	g_hooked = true;
	char buf[160];
	snprintf(buf, sizeof(buf), "hook installed=1 hwnd=%p previous=%p coreModule=%d",
		static_cast<void*>(hwnd), reinterpret_cast<void*>(g_prev),
		GetModuleHandleA("HorizonUI.dll") ? 1 : 0);
	AppendUnlocked(hsb::FactLine("F37", buf));
}

void RemoveHook()
{
	HWND hwnd = nullptr;
	WNDPROC chain = nullptr;
	{
		std::lock_guard lock(g_mu);
		if (!g_hooked) return;
		hwnd = g_hwnd;
		chain = g_prev;
	}
	if (!hwnd) return;
	auto* current = reinterpret_cast<WNDPROC>(GetWindowLongPtrW(hwnd, GWLP_WNDPROC));
	if (!hsb::ShouldRestoreWndProc(current, reinterpret_cast<void*>(ProbeWnd))) {
		Fact("F37", "left a newer window procedure in place; probe stays next and stops logging");
		return;
	}
	auto* swapped = reinterpret_cast<WNDPROC>(SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(chain)));
	if (swapped != ProbeWnd) {
		SetWindowLongPtrW(hwnd, GWLP_WNDPROC, reinterpret_cast<LONG_PTR>(swapped));
		Fact("F37", "left a newer window procedure in place; probe stays next and stops logging");
		return;
	}
	{
		std::lock_guard lock(g_mu);
		g_hooked = false;
		g_hwnd = nullptr;
		g_prev = nullptr;
	}
	Fact("F37", "restored the previous window procedure");
}

std::string InvokeString(RE::Scaleform::GFx::Value& result)
{
	if (result.IsString() && result.GetString()) return result.GetString();
	return {};
}

void ProbeMovie()
{
	auto* ui = RE::UI::GetSingleton();
	if (!ui) {
		Fact("F19", "UI singleton missing");
		return;
	}
	const bool open = ui->IsMenuOpen(hsb::kMenuName);
	auto menu = ui->GetMenu(hsb::kMenuName);
	char head[192];
	snprintf(head, sizeof(head), "menu=%s isOpen=%d menuPtr=%d menuObj=%d movie=%d",
		hsb::kMenuName, open ? 1 : 0, menu ? 1 : 0,
		menu && menu->menuObj.IsObject() ? 1 : 0,
		menu && menu->uiMovie ? 1 : 0);
	Fact("F19", head);
	if (!menu) return;

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
	g_pingDone = invoked && !ping.empty();
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

void DrainLines()
{
	auto* ui = RE::UI::GetSingleton();
	if (!ui) return;
	auto menu = ui->GetMenu(hsb::kMenuName);
	if (!menu || !menu->menuObj.IsObject()) return;
	RE::Scaleform::GFx::Value result;
	if (!menu->menuObj.Invoke("hsbTakeLines", &result)) return;
	const std::string blob = InvokeString(result);
	if (blob.empty()) return;
	std::size_t at = 0;
	while (at < blob.size()) {
		const auto next = blob.find('\n', at);
		const auto piece = blob.substr(at, next == std::string::npos ? std::string::npos : next - at);
		at = next == std::string::npos ? blob.size() : next + 1;
		const std::string clean = hsb::SanitizeFact(piece);
		if (clean.empty()) continue;
		std::uint32_t formId = 0;
		if (hsb::ParseFormLine(clean, formId)) {
			int slot = 0;
			{
				std::lock_guard lock(g_mu);
				slot = hsb::NextFormSlot(g_formCount);
				if (slot < 0) {
					if (!g_formCapped) {
						g_formCapped = true;
						AppendUnlocked(hsb::FactLine("F2a", "form lookup cap reached"));
					}
					continue;
				}
				g_formCount = slot;
			}
			const FormRead read = ReadForm(formId);
			const char* editor = read.editor;
			char buf[320];
			snprintf(buf, sizeof(buf),
				"id=%08X found=%d type=%u editor=%s maker=not-exposed class=not-exposed size=not-exposed fault=%d",
				formId, read.form ? 1 : 0, read.type,
				editor && editor[0] ? editor : "(empty)", read.fault);
			Fact("F2a", buf);
			continue;
		}
		if (clean.rfind("PARTS ", 0) == 0) {
			std::lock_guard lock(g_mu);
			g_formCount = 0;
			g_formCapped = false;
		}
		if (clean.rfind("CAPTURE ", 0) == 0) LogCursor(clean.c_str());
		Fact("movie", clean);
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

void TryHudOnce()
{
	{
		std::lock_guard lock(g_mu);
		if (g_hudTried) return;
		g_hudTried = true;
	}
	Fact("F31", "begin one HUD notify after the builder closes");
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
	snprintf(buf, sizeof(buf), "notify=%d textChars=%d", notified, static_cast<int>(std::char_traits<char>::length(kHudText)));
	Fact("F31", buf);
}

void OnOpen()
{
	g_open.store(true);
	g_pingDone = false;
	g_pingTries = 0;
	{
		std::lock_guard lock(g_mu);
		g_formCount = 0;
		g_formCapped = false;
	}
	Fact("F19", "builder opened");
	Fact("F37", GetModuleHandleA("HorizonUI.dll") ? "HorizonUI.dll is loaded" : "HorizonUI.dll is not loaded");
	LogCursor("open");
	InstallHook();
	ProbeMovie();
}

void OnClose()
{
	g_open.store(false);
	Fact("F19", "builder closed");
	RemoveHook();
	TryHudOnce();
}

void Tick()
{
	static int idle = 0;
	if (!g_open.load()) {
		if (++idle < 20) return;
		idle = 0;
	}
	auto* ui = RE::UI::GetSingleton();
	const bool now = ui && ui->IsMenuOpen(hsb::kMenuName);
	if (now && !g_open.load()) OnOpen();
	if (!now && g_open.load()) OnClose();
	if (!g_open.load()) return;
	if (!g_pingDone && g_pingTries < 300) {
		++g_pingTries;
		if (g_pingTries == 1 || g_pingTries % 30 == 0) ProbeMovie();
		if (g_pingTries == 300 && !g_pingDone) Fact("F19", "invoke still false after retries");
	}
	DrainLines();
}

class MenuSink : public RE::BSTEventSink<RE::MenuOpenCloseEvent>
{
public:
	RE::BSEventNotifyControl ProcessEvent(const RE::MenuOpenCloseEvent& event, RE::BSTEventSource<RE::MenuOpenCloseEvent>*) override
	{
		if (event.menuName == hsb::kMenuName) {
			Fact("F19", event.opening ? "closeEvent opening=1" : "closeEvent opening=0");
		}
		return RE::BSEventNotifyControl::kContinue;
	}
};

MenuSink g_sink;

void OnMenuMovie(RE::IMenu* menu)
{
	if (!menu) return;
	const std::string name = menu->menuName.c_str() ? menu->menuName.c_str() : "";
	if (name.find("Ship") == std::string::npos && name.find("Space") == std::string::npos &&
		name.find("Hangar") == std::string::npos) {
		return;
	}
	Fact("F19", "movie created " + name);
}

}  // namespace

SFSE_PLUGIN_LOAD(const SFSE::LoadInterface* a_sfse)
{
	SFSE::Init(a_sfse);
	PrepareLog();
	REX::INFO("HorizonShipBuilder {} read-only probe", HSB_FILE_VERSION_STR);
	if (auto* ui = RE::UI::GetSingleton()) ui->GetEventSource<RE::MenuOpenCloseEvent>()->RegisterSink(&g_sink);
	else Fact("F19", "UI singleton missing at load; open and close still polled");
	if (auto* menus = SFSE::GetMenuInterface()) menus->Register(OnMenuMovie);
	if (auto* tasks = SFSE::GetTaskInterface()) {
		tasks->AddPermanentTask([] { Tick(); });
		Fact("boot", "menu poll armed");
	} else {
		Fact("boot", "no task interface");
	}
	return true;
}
