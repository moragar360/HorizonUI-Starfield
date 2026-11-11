#pragma once

// Purpose: pure input rules for the 0.2 builder. The window procedure in probe.cpp asks these
//    functions whether to swallow a window message and which token to feed the movie.
// Why: in-game logs (p5) showed presses over the ship view reach the editor before Scaleform,
//    so Scaleform mouse events never fired on Horizon controls. The plugin therefore feeds the
//    pointer to the movie itself and swallows presses over the rectangles the movie publishes.
// Inputs: window message facts (button, wheel, key, client size) and the movie's STATE and HOT
//    lines. Outputs: eat/feed decisions, stage coordinates, token text.
// Dependencies: none (no game or Windows calls), so the logic test can run them.
// Author: Moragar. Last modified: 2026-11-07.

#include <cstddef>
#include <cstdint>
#include <string>
#include <string_view>
#include <vector>

namespace hsb {

inline constexpr int kMaxHotRects = 32;
inline constexpr int kHotLimit = 20000;

struct HotRect {
	int x = 0;
	int y = 0;
	int w = 0;
	int h = 0;
};

// The movie's swallow area: nothing, everything (a popup, text field, the category grid or
// Arrange is open), or a list of rectangles in stage units.
struct HotArea {
	bool all = false;
	std::vector<HotRect> rects;
};

inline bool ParseSmallInt(std::string_view text, int& out)
{
	if (text.empty() || text.size() > 7) return false;
	std::size_t i = 0;
	int sign = 1;
	if (text[0] == '-') {
		sign = -1;
		i = 1;
		if (text.size() == 1) return false;
	}
	int value = 0;
	for (; i < text.size(); ++i) {
		if (text[i] < '0' || text[i] > '9') return false;
		value = value * 10 + (text[i] - '0');
	}
	out = sign * value;
	return true;
}

// Purpose: read the body of a "HOT ..." line. Inputs: "none", "all", or "x,y,w,h;x,y,w,h".
// Outputs: the area; a bad rectangle is skipped, and at most kMaxHotRects are kept.
inline HotArea ParseHot(std::string_view body)
{
	HotArea area;
	if (body == "all") {
		area.all = true;
		return area;
	}
	if (body == "none" || body.empty()) return area;
	std::size_t at = 0;
	while (at <= body.size() && static_cast<int>(area.rects.size()) < kMaxHotRects) {
		const auto semi = body.find(';', at);
		const std::string_view one = body.substr(at, semi == std::string_view::npos ? std::string_view::npos : semi - at);
		int v[4] = {0, 0, 0, 0};
		int n = 0;
		std::size_t p = 0;
		bool ok = true;
		while (n < 4 && ok) {
			const auto comma = one.find(',', p);
			const std::string_view part = one.substr(p, comma == std::string_view::npos ? std::string_view::npos : comma - p);
			ok = ParseSmallInt(part, v[n]);
			++n;
			if (comma == std::string_view::npos) break;
			p = comma + 1;
		}
		if (ok && n == 4 && v[2] > 0 && v[3] > 0 && v[2] <= kHotLimit && v[3] <= kHotLimit &&
			v[0] > -kHotLimit && v[0] < kHotLimit && v[1] > -kHotLimit && v[1] < kHotLimit) {
			area.rects.push_back(HotRect{v[0], v[1], v[2], v[3]});
		}
		if (semi == std::string_view::npos) break;
		at = semi + 1;
	}
	return area;
}

inline bool HotContains(const HotArea& area, int x, int y)
{
	if (area.all) return true;
	for (const auto& r : area.rects) {
		if (x >= r.x && x < r.x + r.w && y >= r.y && y < r.y + r.h) return true;
	}
	return false;
}

// The part of the stage the window shows, in stage units (Scaleform's visibleRect).
struct StageView {
	int x = 0;
	int y = 0;
	int w = 1920;
	int h = 1080;
};

// Purpose: window client pixel to stage units. The client area shows exactly the view.
inline void ClientToStage(int cx, int cy, int clientW, int clientH, const StageView& view, int& sx, int& sy)
{
	const int cw = clientW > 0 ? clientW : 1;
	const int ch = clientH > 0 ? clientH : 1;
	sx = view.x + static_cast<int>(static_cast<long long>(cx) * view.w / cw);
	sy = view.y + static_cast<int>(static_cast<long long>(cy) * view.h / ch);
}

// What the movie told the plugin in its last STATE line.
struct InputState {
	bool capture = false;
	bool text = false;
	bool arrange = false;
	bool arrangeKey = true;
	int hideChar = 0;
	int findChar = 0;
	StageView view{};
	int stageW = 1920;
	int stageH = 1080;
};

inline int StateInt(std::string_view line, std::string_view key, int fallback)
{
	const std::string needle = " " + std::string(key) + "=";
	const auto at = line.find(needle);
	if (at == std::string_view::npos) return fallback;
	const auto start = at + needle.size();
	auto end = line.find(' ', start);
	int v = 0;
	if (!ParseSmallInt(line.substr(start, end == std::string_view::npos ? std::string_view::npos : end - start), v)) return fallback;
	return v;
}

// Purpose: read "STATE capture=0 text=0 arrange=0 stage=WxH view=x,y,w,h keys=1 hide=72 find=47".
// Outputs: the state; a missing or bad field keeps the previous value.
// Purpose: whether the plugin writes its log to disk right before it hands this feed to the
//    movie (and again once the movie's lines for the frame are in): an Enter ("K ok"), or,
//    while a Horizon text field is active, a Tab or a press that can commit the field.
//    Typed characters and every other token never flush, so the cost stays at those events.
inline bool FeedWantsSync(std::string_view feed, bool textActive)
{
	std::size_t at = 0;
	while (at < feed.size()) {
		const auto next = feed.find('\n', at);
		const std::string_view line = feed.substr(at, next == std::string_view::npos ? std::string_view::npos : next - at);
		at = next == std::string_view::npos ? feed.size() : next + 1;
		if (line == "K ok") return true;
		if (textActive && (line == "K tab" || line.rfind("M D ", 0) == 0)) return true;
	}
	return false;
}

// Purpose: a movie line "SYNC <tag>" asks for the log on disk now. Outputs: true and the tag
//    (at most 24 characters) for such a line.
inline bool SyncLine(std::string_view line, std::string& tag)
{
	if (line.rfind("SYNC ", 0) != 0) return false;
	tag = std::string(line.substr(5, 24));
	return true;
}

inline InputState ParseState(std::string_view line, InputState prev)
{
	InputState s = prev;
	s.capture = StateInt(line, "capture", prev.capture ? 1 : 0) == 1;
	s.text = StateInt(line, "text", prev.text ? 1 : 0) == 1;
	s.arrange = StateInt(line, "arrange", prev.arrange ? 1 : 0) == 1;
	s.arrangeKey = StateInt(line, "keys", prev.arrangeKey ? 1 : 0) == 1;
	const int hide = StateInt(line, "hide", prev.hideChar);
	const int find = StateInt(line, "find", prev.findChar);
	s.hideChar = hide >= 0 && hide < 128 ? hide : 0;
	s.findChar = find >= 0 && find < 128 ? find : 0;
	const auto st = line.find(" stage=");
	if (st != std::string_view::npos) {
		const auto start = st + 7;
		const auto end = line.find(' ', start);
		const std::string_view dims = line.substr(start, end == std::string_view::npos ? std::string_view::npos : end - start);
		const auto x = dims.find('x');
		int w = 0, h = 0;
		if (x != std::string_view::npos && ParseSmallInt(dims.substr(0, x), w) && ParseSmallInt(dims.substr(x + 1), h) && w > 0 && h > 0) {
			s.stageW = w;
			s.stageH = h;
		}
	}
	const auto vw = line.find(" view=");
	if (vw != std::string_view::npos) {
		const auto start = vw + 6;
		const auto end = line.find(' ', start);
		HotArea one = ParseHot(line.substr(start, end == std::string_view::npos ? std::string_view::npos : end - start));
		if (one.rects.size() == 1 && one.rects[0].w > 100 && one.rects[0].h > 100) {
			s.view = StageView{one.rects[0].x, one.rects[0].y, one.rects[0].w, one.rects[0].h};
		}
	}
	return s;
}

struct PointerCall {
	bool eat = false;
	bool feed = false;
};

// Purpose: a mouse button press or release, or a wheel step.
// Inputs: whether it is a press, a release or a wheel step, whether the point is inside the
//    movie's swallow area, and whether the hook ate this button's press.
// Rules: the game gets both halves of a click or neither. A press is swallowed inside the area
//    (all of it while capturing). A release follows its press. The wheel is swallowed inside
//    the area. Every press, release and step is fed, marked eaten or not, so the movie can see
//    a press outside a popup; it acts only on eaten ones.
inline PointerCall PointerEdge(bool press, bool release, bool wheel, bool inside, bool pressEaten)
{
	PointerCall call;
	if (release) call.eat = pressEaten;
	else if (press || wheel) call.eat = inside;
	call.feed = press || release || wheel;
	return call;
}

// Moves are never swallowed: the game never saw a press we took, so a move cannot drag the
// ship, and the camera keeps its normal feel. They are fed while the menu is open.
inline PointerCall MoveEdge()
{
	PointerCall call;
	call.feed = true;
	return call;
}

inline constexpr unsigned kVkBackKey = 0x08;
inline constexpr unsigned kVkTabKey = 0x09;
inline constexpr unsigned kVkReturnKey = 0x0D;
inline constexpr unsigned kVkEscKey = 0x1B;
inline constexpr unsigned kVkPriorKey = 0x21;
inline constexpr unsigned kVkNextKey = 0x22;
inline constexpr unsigned kVkLeftKey = 0x25;
inline constexpr unsigned kVkUpKey = 0x26;
inline constexpr unsigned kVkRightKey = 0x27;
inline constexpr unsigned kVkDownKey = 0x28;
inline constexpr unsigned kVkDeleteKey = 0x2E;
inline constexpr unsigned kVkSnapshotKey = 0x2C;
inline constexpr unsigned kVkLWinKey = 0x5B;
inline constexpr unsigned kVkRWinKey = 0x5C;
inline constexpr unsigned kVkLKey = 'L';

// Purpose: the movie token for a key the movie navigates with. Outputs: "" for other keys.
inline const char* NavToken(unsigned vk, bool shift)
{
	switch (vk) {
	case kVkEscKey: return "cancel";
	case kVkReturnKey: return "ok";
	case kVkLeftKey: return shift ? "left40" : "left";
	case kVkRightKey: return shift ? "right40" : "right";
	case kVkUpKey: return shift ? "up40" : "up";
	case kVkDownKey: return shift ? "down40" : "down";
	case kVkTabKey: return shift ? "tabprev" : "tab";
	case kVkPriorKey: return "pgup";
	case kVkNextKey: return "pgdn";
	case kVkBackKey: return "bksp";
	case kVkDeleteKey: return "del";
	default: return "";
	}
}

struct KeyCall {
	bool eat = false;
	const char* token = "";
};

// Purpose: decide one key press (not a release).
// Inputs: the virtual key, its character on the active layout (uppercase, 0 when none),
//    modifiers, whether it repeats, and the movie state.
// Rules: Alt combinations, the Windows keys and Print Screen always reach the game and
//    Windows, so Alt+F4 and Alt+Tab keep working. While a popup, text field, the category grid
//    or Arrange is open every other key is swallowed and navigation keys become tokens (a text
//    field gets its letters as characters, not here). Otherwise only Horizon's own keys are
//    taken: Ctrl+L for Arrange (when enabled), and the hide and find keys the movie names in
//    STATE (0 when off or when the game maps the same key).
inline KeyCall KeyPress(unsigned vk, int ch, bool ctrl, bool alt, bool shift, bool repeat, const InputState& s)
{
	KeyCall call;
	// AltGr arrives as Ctrl+Alt. In a text field it types a character (@ or { on many
	// layouts), so there it is not an Alt combination.
	const bool altGr = alt && ctrl && s.text;
	if ((alt && !altGr) || vk == kVkLWinKey || vk == kVkRWinKey || vk == kVkSnapshotKey) return call;
	if (s.capture || s.text || s.arrange) {
		call.eat = true;
		call.token = NavToken(vk, shift);
		if (repeat && (vk == kVkEscKey || vk == kVkReturnKey)) call.token = "";
		return call;
	}
	if (repeat) return call;
	if (ctrl) {
		if (vk == kVkLKey && s.arrangeKey) {
			call.eat = true;
			call.token = "open";
		}
		return call;
	}
	if (ch > 32 && ch < 127) {
		if (s.hideChar != 0 && ch == s.hideChar) {
			call.eat = true;
			call.token = "hide";
		} else if (s.findChar != 0 && ch == s.findChar) {
			call.eat = true;
			call.token = "find";
		}
	}
	return call;
}

// Raw input (WM_INPUT). The game reads its keys and mouse buttons from raw input, not from
// the WM_KEYDOWN and WM_LBUTTONDOWN messages the hook swallows (the close line's raw count is
// in the thousands), so a swallowed key could still reach the editor: Enter in Find could
// place the highlighted part and close the palette, and letters typed in a name field could
// act as the editor's own keys. Raw records get the same rules as the messages.
enum class RawHeld : unsigned char { none, eaten, passed };

// Purpose: one raw key record. Inputs: whether it is the release, the key's ledger entry and
//    whether KeyPress would swallow the press now. Rules: the press decides for the whole
//    press: its auto-repeats and its release follow it, so the game sees both halves or
//    neither, even when capture starts or ends while the key is down.
inline bool RawKeyEdge(bool release, RawHeld& held, bool pressEats)
{
	if (release) {
		const bool eat = held == RawHeld::eaten;
		held = RawHeld::none;
		return eat;
	}
	if (held == RawHeld::none) held = pressEats ? RawHeld::eaten : RawHeld::passed;
	return held == RawHeld::eaten;
}

// v7f: the ledger also runs while Horizon handles no input (the menu closed, or open before
// the movie's handshake), so a key that went down then is known to be the game's. There every
// make marks the key passed (the game saw it go down) and every break clears it. Nothing is
// eaten there.
inline void RawKeySeen(bool release, RawHeld& held)
{
	held = release ? RawHeld::none : RawHeld::passed;
}

// Purpose: the raw key ledger at a menu open (and when the game window gets focus back).
// Inputs: the ledger (n keys) and which keys are down now (down may be null). Rules: only
//    keys we ate are forgotten; a key the game saw go down stays the game's until its
//    release, so its auto-repeats and release keep reaching the game. A key that is down but
//    unknown (its press came before the window was watched) is the game's too. So a release
//    is never eaten for a key whose press reached the game.
inline void RawLedgerOpen(RawHeld* keys, std::size_t n, const bool* down)
{
	for (std::size_t vk = 0; vk < n; ++vk) {
		if (keys[vk] == RawHeld::eaten) keys[vk] = RawHeld::none;
		if (down != nullptr && down[vk] && keys[vk] == RawHeld::none) keys[vk] = RawHeld::passed;
	}
}

// Focus loss: breaks can go to another window, so every entry is cleared. No release is left
// waiting to be eaten, and a stale entry cannot decide a later press (RawLedgerOpen marks the
// keys still down when focus comes back).
inline void RawLedgerFocusLost(RawHeld* keys, std::size_t n)
{
	for (std::size_t vk = 0; vk < n; ++vk) keys[vk] = RawHeld::none;
}

// Shift, Ctrl, Alt (either side) and Caps Lock reach the game raw, as their messages do (an
// Alt press arrives as WM_SYSKEYDOWN, which KeyPress passes), so the game's modifier state
// never sticks.
inline bool RawKeyPasses(unsigned vk)
{
	return (vk >= 0x10 && vk <= 0x12) || vk == 0x14 || (vk >= 0xA0 && vk <= 0xA5);
}

inline constexpr unsigned kRawWheelFlags = 0x0400u | 0x0800u;

struct RawMouseCall {
	bool eat = false;
	unsigned held = 0;
};

// Purpose: one raw mouse record with button or wheel flags.
// Inputs: the record's button flags (two bits per button: press, then release, for five
//    buttons; then the wheels), whether a popup, text field or Arrange holds every press,
//    whether the pointer is in the swallow area, and the buttons whose raw press was eaten
//    (bit per button). Rules: while Horizon holds every press, a press or wheel step in the
//    area is kept from the game; a release follows its press. A record that mixes kept and
//    passed edges goes to the game whole, and its presses count as the game's.
inline RawMouseCall RawMouseEdge(unsigned flags, bool modal, bool inside, unsigned held)
{
	RawMouseCall call;
	call.held = held;
	bool keep = false;
	bool pass = false;
	unsigned downs = 0;
	for (unsigned b = 0; b < 5; ++b) {
		const unsigned bit = 1u << b;
		if ((flags & (1u << (2 * b))) != 0) {
			downs |= bit;
			if (modal && inside) keep = true;
			else pass = true;
		}
		if ((flags & (2u << (2 * b))) != 0) {
			if ((held & bit) != 0) keep = true;
			else pass = true;
			call.held &= ~bit;
		}
	}
	if ((flags & kRawWheelFlags) != 0) {
		if (modal && inside) keep = true;
		else pass = true;
	}
	call.eat = keep && !pass;
	if (call.eat) call.held |= downs;
	else call.held &= ~downs;
	return call;
}

// A typed character goes to the movie's text field: printable only, never logged.
inline bool CharForText(unsigned code, const InputState& s)
{
	return s.text && code >= 32 && code != 127 && code < 0xD800;
}

// Counters for the close summary line. Counts only: no keys, characters or positions.
// raw counts WM_INPUT messages: if the game reads buttons through raw input, a swallowed
// button message would not stop the editor, and this number shows whether that path exists.
struct InputCounts {
	unsigned presses = 0;
	unsigned eaten = 0;
	unsigned wheels = 0;
	unsigned keys = 0;
	unsigned chars = 0;
	unsigned dropped = 0;
	unsigned raw = 0;
	unsigned rawEaten = 0;
};

inline std::string CountsLine(const InputCounts& c)
{
	return "presses=" + std::to_string(c.presses) + " eaten=" + std::to_string(c.eaten) + " wheel=" + std::to_string(c.wheels) +
		" keys=" + std::to_string(c.keys) + " chars=" + std::to_string(c.chars) + " dropped=" + std::to_string(c.dropped) +
		" raw=" + std::to_string(c.raw) + " rawEaten=" + std::to_string(c.rawEaten);
}

// Wheel deltas arrive in 120ths. Fine-grained wheels and touchpads send less, so the rest
// carries to the next message. Outputs: whole steps now; rest keeps the remainder.
inline int WheelSteps(int delta, int& rest)
{
	rest += delta;
	const int steps = rest / 120;
	rest -= steps * 120;
	return steps;
}

}  // namespace hsb
