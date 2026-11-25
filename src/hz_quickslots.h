// Horizon UI Extended Quick Menu (0.43.5): settings, per-character slot files,
// layout math, and the equip/use dispatch. No CommonLibSF. The game wrappers
// live in the DLL (main.cpp). Author: Moragar.
#pragma once

#include "hz_msglog.h"

#include <algorithm>
#include <cctype>
#include <cstdint>
#include <cstdio>
#include <cstring>
#include <filesystem>
#include <fstream>
#include <optional>
#include <string>
#include <string_view>
#include <vector>

#ifdef min
#undef min
#endif
#ifdef max
#undef max
#endif

namespace hzqs {

inline constexpr int kVanillaSlots = 12;
inline constexpr int kMinSlots = 12;
inline constexpr int kMaxSlots = 24;
inline constexpr int kDefaultCount = 24;     // when Extended Mode is first turned on
inline constexpr int kDefaultPerRow = 6;
inline constexpr int kExtFirst = 13;         // first Horizon slot (1-based)
inline constexpr float kBox = 58.f;
inline constexpr float kGap = 12.f;
inline constexpr float kPitch = kBox + kGap;

enum class Layout : int
{
	CrossBars = 0,  // T for 1-12, bars under it for 13-N (default)
	Bars = 1        // every slot in rows
};

enum class Kind : int
{
	Inventory = 0,
	Power = 1,
	Essence = 2
};

enum class UseResult : int
{
	Ok = 0,
	Empty = 1,       // no assignment in that slot
	Missing = 2,     // assigned, but the character does not have the item
	Blocked = 3,     // a menu, console, or text entry is open
	NoModule = 4,    // Quick Menu module is not installed
	Conflict = 5,    // another extended-favorites mod is present
	Disabled = 6,    // Extended Mode is off
	BadSlot = 7,
	Error = 8,
	Stale = 9        // the stored form ID now names a different item (load-order change): slot is cleared
};

struct Settings
{
	bool        extended = false;
	int         slotCount = kDefaultCount;
	int         slotsPerRow = kDefaultPerRow;
	Layout      layout = Layout::CrossBars;
	std::string key[12]{};  // slots 13-24, empty = no bind
};

struct Assignment
{
	int         index = 0;  // 13-24
	std::uint32_t formId = 0;
	std::string formHex;
	std::string name;
	Kind        kind = Kind::Inventory;
	std::string base;       // the form's own display name at assign time (load-order check, S-3); last, so
	                        // aggregate initializers that stop at kind keep working
};

struct Store
{
	int                  version = 1;
	hzlog::Character     character{};
	std::vector<Assignment> slots;  // kept even when hidden by a lower slotCount
};

struct SlotPos
{
	int   index = 0;   // 1-24, or 0 for the + ADD SLOT tile
	float x = 0;       // center
	float y = 0;
	bool  native = false;  // leave the vanilla Entry_N where the movie put it
};

struct UseHooks
{
	bool (*moduleInstalled)(void* ctx) = nullptr;
	bool (*conflictModFound)(void* ctx) = nullptr;
	bool (*inputBlocked)(void* ctx) = nullptr;
	bool (*hasItem)(std::uint32_t formId, Kind kind, void* ctx) = nullptr;
	bool (*useInventory)(std::uint32_t formId, void* ctx) = nullptr;
	bool (*usePower)(std::uint32_t formId, void* ctx) = nullptr;
	bool (*useEssence)(std::uint32_t formId, void* ctx) = nullptr;
	bool (*keyBoundByGame)(std::string_view key, void* ctx) = nullptr;
	// true when the stored form ID no longer names the stored item (different name or not an item)
	bool (*formStale)(const Assignment& a, void* ctx) = nullptr;
	void* ctx = nullptr;
};

inline std::string Lower(std::string s)
{
	for (char& c : s) c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
	return s;
}

// True when a and b name the same item: case-insensitive equality, or one is the other
// with an instance prefix ("Modified Razorback" vs "Razorback"). A short suffix of 4
// letters or fewer is not treated as the same item ("Med Pack" vs "Pack").
// Empty names are not a match (callers treat empty as unknown separately).
inline bool NamesMatch(std::string_view a, std::string_view b)
{
	if (a.empty() || b.empty()) return false;
	auto la = Lower(std::string(a));
	auto lb = Lower(std::string(b));
	if (la == lb) return true;
	auto prefixed = [](const std::string& longn, const std::string& shortn) {
		if (shortn.size() < 5 || longn.size() <= shortn.size()) return false;
		if (longn.compare(longn.size() - shortn.size(), shortn.size(), shortn) != 0) return false;
		return longn[longn.size() - shortn.size() - 1] == ' ';
	};
	return prefixed(la, lb) || prefixed(lb, la);
}

// Keep a LookupByID result only when its TESFullName is the item the movie named.
// Empty sentName: the movie sent an ID only; keep it if the form has a name.
// Empty formName: LookupByID did not yield a named form (a miss, so the caller can name-walk).
inline bool AssignIdMatchesName(std::string_view sentName, std::string_view formName)
{
	if (formName.empty()) return false;
	if (sentName.empty()) return true;
	return NamesMatch(sentName, formName);
}

// One inventory row for PickFormByDisplayName (TESFullName + form ID).
struct NameId
{
	std::string_view name;
	std::uint32_t    id = 0;
};

// Prefer an exact TESFullName, then a case-insensitive exact, then the shortest
// NamesMatch prefix (never the longest). "Razorback" must not resolve to
// "Heavy Modified Razorback" when a shorter match exists.
inline std::uint32_t PickFormByDisplayName(std::string_view want, const NameId* rows, int n)
{
	if (want.empty() || !rows || n <= 0) return 0;
	std::uint32_t found = 0;
	std::uint32_t foundCi = 0;
	std::uint32_t foundPx = 0;
	std::size_t pxLen = static_cast<std::size_t>(-1);
	const auto wantL = Lower(std::string(want));
	for (int i = 0; i < n; ++i) {
		const auto nm = rows[i].name;
		if (nm.empty() || !rows[i].id) continue;
		if (want == nm) { found = rows[i].id; break; }
		if (!foundCi && Lower(std::string(nm)) == wantL) foundCi = rows[i].id;
		if (NamesMatch(want, nm) && nm.size() < pxLen) {
			foundPx = rows[i].id;
			pxLen = nm.size();
		}
	}
	if (found) return found;
	if (foundCi) return foundCi;
	return foundPx;
}

inline std::string Trim(std::string_view a)
{
	std::size_t i = 0, j = a.size();
	while (i < j && std::isspace(static_cast<unsigned char>(a[i]))) ++i;
	while (j > i && std::isspace(static_cast<unsigned char>(a[j - 1]))) --j;
	return std::string(a.substr(i, j - i));
}

inline int ClampCount(int n)
{
	if (n < kMinSlots) return kMinSlots;
	if (n > kMaxSlots) return kMaxSlots;
	return n;
}

inline int ClampPerRow(int n)
{
	if (n <= 4) return 4;
	if (n >= 8) return 8;
	return 6;
}

inline Layout ParseLayout(std::string_view v)
{
	const auto s = Lower(Trim(v));
	if (s == "1" || s == "bars" || s == "bar") return Layout::Bars;
	return Layout::CrossBars;
}

inline const char* LayoutName(Layout a)
{
	return a == Layout::Bars ? "BARS" : "CROSS+BARS";
}

inline Kind ParseKind(std::string_view v)
{
	const auto s = Lower(Trim(v));
	if (s == "power" || s == "spell" || s == "1") return Kind::Power;
	if (s == "essence" || s == "quantum" || s == "2") return Kind::Essence;
	return Kind::Inventory;
}

inline const char* KindName(Kind a)
{
	if (a == Kind::Power) return "power";
	if (a == Kind::Essence) return "essence";
	return "inventory";
}

inline bool ParseBool01(std::string_view v, bool def = false)
{
	const auto s = Lower(Trim(v));
	if (s == "1" || s == "true" || s == "on" || s == "yes") return true;
	if (s == "0" || s == "false" || s == "off" || s == "no" || s.empty()) return false;
	return def;
}

// Form IDs are a 0x/0X prefix, then 1-8 hex digits, fully consumed. No minus,
// no '#', no 64-bit truncation. "Dead Drop" is a name, not 0xDEAD.
inline std::uint32_t ParseFormId(std::string_view raw)
{
	const auto t = Trim(raw);
	if (t.size() < 3) return 0;
	if (t[0] != '0' || (t[1] != 'x' && t[1] != 'X')) return 0;
	const auto hex = t.substr(2);
	if (hex.empty() || hex.size() > 8) return 0;
	std::uint32_t v = 0;
	for (unsigned char c : hex) {
		std::uint32_t d = 0;
		if (c >= '0' && c <= '9') d = static_cast<std::uint32_t>(c - '0');
		else if (c >= 'a' && c <= 'f') d = 10u + static_cast<std::uint32_t>(c - 'a');
		else if (c >= 'A' && c <= 'F') d = 10u + static_cast<std::uint32_t>(c - 'A');
		else return 0;
		v = (v << 4) | d;
	}
	return v;
}

inline std::string FormHex(std::uint32_t id)
{
	char b[16];
	std::snprintf(b, sizeof(b), "0x%08X", id);
	return b;
}

inline bool ValidKeyName(std::string_view raw)
{
	const auto s = Trim(raw);
	if (s.empty()) return true;
	if (s.size() == 1) {
		const char c = static_cast<char>(std::toupper(static_cast<unsigned char>(s[0])));
		return (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9');
	}
	auto u = s;
	for (char& c : u) c = static_cast<char>(std::toupper(static_cast<unsigned char>(c)));
	static const char* kOk[] = {
		"F1","F2","F3","F4","F5","F6","F7","F8","F9","F10","F11","F12",
		"INSERT","HOME","END","PAGEUP","PAGEDOWN",nullptr  // only names KeyNameToScan maps
	};
	for (int i = 0; kOk[i]; ++i) if (u == kOk[i]) return true;
	return false;
}

inline std::string CanonKey(std::string_view raw)
{
	auto s = Trim(raw);
	if (s.empty() || !ValidKeyName(s)) return {};
	if (s.size() == 1) {
		s[0] = static_cast<char>(std::toupper(static_cast<unsigned char>(s[0])));
		return s;
	}
	if (s.size() >= 2 && (s[0] == 'F' || s[0] == 'f') && std::isdigit(static_cast<unsigned char>(s[1]))) {
		const int n = std::atoi(s.c_str() + 1);
		if (n >= 1 && n <= 12) return "F" + std::to_string(n);
	}
	std::string out;
	out.reserve(s.size());
	for (std::size_t i = 0; i < s.size(); ++i) {
		const char c = s[i];
		out.push_back(i == 0 ? static_cast<char>(std::toupper(static_cast<unsigned char>(c)))
		                     : static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
	}
	if (Lower(out) == "pageup") return "PageUp";
	if (Lower(out) == "pagedown") return "PageDown";
	return out;
}

// S-8: used only while the game's control map cannot be read. Refuses the movement / action defaults and
// every function key the F11 key list offers (F5 quicksave and F9 quickload included), since any of them may
// be bound by the game. Takes CanonKey output.
inline bool FallbackReservedKey(std::string_view canon)
{
	static const char* kReserved[] = {
		"W","A","S","D","Q","E",
		"F5","F9",
		"F1","F2","F3","F4","F6","F7","F8","F10","F11","F12",
		nullptr
	};
	for (int i = 0; kReserved[i]; ++i) {
		if (canon == kReserved[i]) return true;
	}
	return false;
}

inline void ApplyKey(Settings& s, int slot /*13-24*/, std::string_view raw)
{
	if (slot < kExtFirst || slot > kMaxSlots) return;
	s.key[slot - kExtFirst] = CanonKey(raw);
}

inline const std::string& KeyOf(const Settings& s, int slot)
{
	static const std::string empty;
	if (slot < kExtFirst || slot > kMaxSlots) return empty;
	return s.key[slot - kExtFirst];
}

// Last occurrence of each known key wins (any section). Unknown keys are ignored.
inline void ApplyIniPair(Settings& s, std::string_view key, std::string_view val)
{
	const auto k = Lower(Trim(key));
	const auto v = Trim(val);
	if (k == "quickmenuextended" || k == "extended") s.extended = ParseBool01(v, s.extended);
	else if (k == "quickmenuslotcount" || k == "slotcount") s.slotCount = ClampCount(std::atoi(v.c_str()));
	else if (k == "quickmenuslotsperrow" || k == "slotsperrow") s.slotsPerRow = ClampPerRow(std::atoi(v.c_str()));
	else if (k == "quickmenuextendedlayout" || k == "extendedlayout") s.layout = ParseLayout(v);
	else if (k.rfind("quickmenukey", 0) == 0 && k.size() > 12) {
		const int slot = std::atoi(k.c_str() + 12);
		ApplyKey(s, slot, v);
	}
}

inline Settings ParseIniText(std::string_view text)
{
	Settings s;
	std::string line;
	for (std::size_t i = 0, n = text.size(); i <= n; ++i) {
		if (i == n || text[i] == '\n') {
			auto t = Trim(line);
			line.clear();
			if (t.empty() || t[0] == ';' || t[0] == '#' || t[0] == '[') { continue; }
			const auto eq = t.find('=');
			if (eq == std::string::npos) continue;
			ApplyIniPair(s, t.substr(0, eq), t.substr(eq + 1));
			continue;
		}
		if (text[i] != '\r') line.push_back(text[i]);
	}
	return s;
}

// A hide (lower slotCount) keeps the assignment. An empty form clears it.
inline const Assignment* FindSlot(const Store& st, int index)
{
	for (const auto& a : st.slots) if (a.index == index) return &a;
	return nullptr;
}

inline Assignment* FindSlot(Store& st, int index)
{
	for (auto& a : st.slots) if (a.index == index) return &a;
	return nullptr;
}

inline void SetSlot(Store& st, Assignment a)
{
	if (a.index < kExtFirst || a.index > kMaxSlots) return;
	if (a.formId && a.formHex.empty()) a.formHex = FormHex(a.formId);
	if (!a.formId && !a.formHex.empty()) a.formId = ParseFormId(a.formHex);
	if (auto* e = FindSlot(st, a.index)) { *e = std::move(a); return; }
	st.slots.push_back(std::move(a));
}

inline void ClearSlot(Store& st, int index)
{
	st.slots.erase(std::remove_if(st.slots.begin(), st.slots.end(),
		[index](const Assignment& a) { return a.index == index; }), st.slots.end());
}

inline bool SlotVisible(const Settings& s, int index)
{
	return s.extended && index >= kExtFirst && index <= ClampCount(s.slotCount);
}

inline const Assignment* VisibleAssignment(const Settings& s, const Store& st, int index)
{
	if (!SlotVisible(s, index)) return nullptr;
	return FindSlot(st, index);
}

inline std::string JsonEscape(std::string_view s)
{
	std::string o;
	o.reserve(s.size());
	for (char c : s) {
		if (c == '\\' || c == '"') { o.push_back('\\'); o.push_back(c); }
		else if (c == '\n') o += "\\n";
		else if (c == '\r') o += "\\r";
		else if (c == '\t') o += "\\t";
		else o.push_back(c);
	}
	return o;
}

inline std::string WriteStore(const Store& st)
{
	std::string o = "{\n  \"type\": \"horizon.quickslots\",\n  \"v\": 1,\n  \"character\": {";
	o += "\"key\":\"" + JsonEscape(st.character.key) + "\"";
	o += ",\"keySource\":\"" + JsonEscape(st.character.keySource) + "\"";
	if (!st.character.names.empty()) o += ",\"name\":\"" + JsonEscape(st.character.names.front()) + "\"";
	o += "},\n  \"slots\": [\n";
	bool first = true;
	for (const auto& a : st.slots) {
		if (a.index < kExtFirst || a.index > kMaxSlots) continue;
		if (!first) o += ",\n";
		first = false;
		o += "    {\"i\":" + std::to_string(a.index);
		o += ",\"form\":\"" + JsonEscape(a.formHex.empty() ? FormHex(a.formId) : a.formHex) + "\"";
		o += ",\"name\":\"" + JsonEscape(a.name) + "\"";
		if (!a.base.empty()) o += ",\"base\":\"" + JsonEscape(a.base) + "\"";
		o += ",\"kind\":\"" + std::string(KindName(a.kind)) + "\"}";
	}
	o += "\n  ]\n}\n";
	return o;
}

inline std::string Unescape(std::string_view s)
{
	std::string o;
	for (std::size_t i = 0; i < s.size(); ++i) {
		if (s[i] == '\\' && i + 1 < s.size()) {
			const char n = s[++i];
			if (n == 'n') o.push_back('\n');
			else if (n == 'r') o.push_back('\r');
			else if (n == 't') o.push_back('\t');
			else o.push_back(n);
		} else o.push_back(s[i]);
	}
	return o;
}

inline std::string JsonStr(std::string_view obj, std::string_view key)
{
	const std::string pat = "\"" + std::string(key) + "\"";
	auto p = obj.find(pat);
	if (p == std::string_view::npos) return {};
	p = obj.find(':', p + pat.size());
	if (p == std::string_view::npos) return {};
	p = obj.find_first_not_of(" \t\r\n", p + 1);
	if (p == std::string_view::npos || obj[p] != '"') return {};
	++p;
	std::string raw;
	for (; p < obj.size(); ++p) {
		if (obj[p] == '\\' && p + 1 < obj.size()) { raw.push_back(obj[p]); raw.push_back(obj[++p]); continue; }
		if (obj[p] == '"') break;
		raw.push_back(obj[p]);
	}
	return Unescape(raw);
}

inline std::int64_t JsonInt(std::string_view obj, std::string_view key, std::int64_t def = 0)
{
	const std::string pat = "\"" + std::string(key) + "\"";
	auto p = obj.find(pat);
	if (p == std::string_view::npos) return def;
	p = obj.find(':', p + pat.size());
	if (p == std::string_view::npos) return def;
	p = obj.find_first_not_of(" \t\r\n", p + 1);
	if (p == std::string_view::npos) return def;
	char* end = nullptr;
	const auto n = std::strtoll(std::string(obj.substr(p, 24)).c_str(), &end, 10);
	if (end && end != std::string(obj.substr(p, 24)).c_str()) return n;
	return def;
}

// End of the JSON object that starts at a_open ('{'), skipping braces inside strings (N-8). npos if unterminated.
inline std::size_t ObjEnd(std::string_view text, std::size_t a_open)
{
	bool inStr = false;
	for (std::size_t i = a_open + 1; i < text.size(); ++i) {
		const char c = text[i];
		if (inStr) {
			if (c == '\\') { ++i; continue; }
			if (c == '"') inStr = false;
			continue;
		}
		if (c == '"') inStr = true;
		else if (c == '}') return i;
	}
	return std::string_view::npos;
}

inline Store ParseStore(std::string_view text)
{
	Store st;
	st.version = 1;
	const auto typ = JsonStr(text, "type");
	if (!typ.empty() && typ != "horizon.quickslots") return st;
	// character block
	const auto c0 = text.find("\"character\"");
	if (c0 != std::string_view::npos) {
		const auto b = text.find('{', c0);
		const auto e = b == std::string_view::npos ? std::string_view::npos : ObjEnd(text, b);
		if (b != std::string_view::npos && e != std::string_view::npos) {
			const auto blk = text.substr(b, e - b + 1);
			st.character.key = JsonStr(blk, "key");
			st.character.keySource = JsonStr(blk, "keySource");
			const auto nm = JsonStr(blk, "name");
			if (!nm.empty()) st.character.names = { nm };
			if (st.character.keySource.empty()) st.character.keySource = "playerId";
		}
	}
	auto pos = text.find("\"slots\"");
	if (pos == std::string_view::npos) return st;
	pos = text.find('[', pos);
	if (pos == std::string_view::npos) return st;
	for (;;) {
		const auto b = text.find('{', pos);
		if (b == std::string_view::npos) break;
		const auto e = ObjEnd(text, b);
		if (e == std::string_view::npos) break;
		const auto obj = text.substr(b, e - b + 1);
		Assignment a;
		a.index = static_cast<int>(JsonInt(obj, "i"));
		a.formHex = JsonStr(obj, "form");
		a.formId = ParseFormId(a.formHex);
		a.name = JsonStr(obj, "name");
		a.base = JsonStr(obj, "base");
		a.kind = ParseKind(JsonStr(obj, "kind"));
		if (a.index >= kExtFirst && a.index <= kMaxSlots) SetSlot(st, a);
		pos = e + 1;
		if (pos < text.size() && text[pos] == ']') break;
	}
	return st;
}

inline std::filesystem::path StoreDir(const std::filesystem::path& horizonDir)
{
	return horizonDir / "QuickSlots";
}

inline std::filesystem::path StorePath(const std::filesystem::path& horizonDir, std::string_view key)
{
	return StoreDir(horizonDir) / ("QuickSlots_" + hzlog::FoldLogKey(key) + ".json");
}

// Zero player ID: keep the store in memory only (same rule as the message log).
inline bool CanWriteStore(const hzlog::Character& ch)
{
	return hzlog::PersistAllowed(ch);
}

inline bool WriteStoreFile(const std::filesystem::path& horizonDir, const Store& st, hzlog::ReplaceFn replace = hzlog::DefaultReplace)
{
	if (!CanWriteStore(st.character)) return false;
	std::error_code ec;
	const auto dir = StoreDir(horizonDir);
	std::filesystem::create_directories(dir, ec);
	if (ec) return false;
	const auto dst = StorePath(horizonDir, st.character.key);
	const auto tmp = dst.string() + ".tmp";
	{
		std::ofstream f(tmp, std::ios::binary | std::ios::trunc);
		if (!f) return false;
		const auto body = WriteStore(st);
		f.write(body.data(), static_cast<std::streamsize>(body.size()));
		if (!f) return false;
	}
	return replace(tmp, dst);
}

inline Store ReadStoreFile(const std::filesystem::path& horizonDir, std::string_view key)
{
	Store st;
	const auto p = StorePath(horizonDir, key);
	std::ifstream f(p, std::ios::binary);
	if (!f) return st;
	std::string body((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
	st = ParseStore(body);
	if (st.character.key.empty()) st.character.key = std::string(key);
	return st;
}

// N-9: assignments made while the store was memory-only (player ID unknown) go into the slots the
// character's file leaves empty. Returns true when anything was added (the caller writes the file).
inline bool MergeMemorySlots(Store& a_file, const Store& a_mem)
{
	bool added = false;
	for (const auto& m : a_mem.slots) {
		if (m.index < kExtFirst || m.index > kMaxSlots || !m.formId) continue;
		if (FindSlot(a_file, m.index)) continue;
		SetSlot(a_file, m);
		added = true;
	}
	return added;
}

// S-A: only merge assignments made while the store was memory-only (player ID unknown). A store
// that is already bound to a real character must not be merged into another character's file.
inline bool ShouldMergeMemorySlots(const Store& a_mem)
{
	return !CanWriteStore(a_mem.character);
}

// S-A / S-D: a HUD-ready or load event with player ID 0. A store already bound to a real
// character must be parked for a final write and replaced with an empty memory-only store
// (MustParkBoundStore / ResetToUnknownCharacter in the game layer). This helper only records
// the unknown id on a store that is already memory-only, keeping its in-session assignments.
inline void ApplyUnknownCharacter(Store& a_st, const hzlog::Character& a_unknown)
{
	if (!CanWriteStore(a_st.character))
		a_st.character = a_unknown;
}

// S-D: the live store belongs to a real character, so an unknown player ID ends that session.
inline bool MustParkBoundStore(const Store& a_st)
{
	return CanWriteStore(a_st.character);
}

// S-D: replace the live store with an empty memory-only store for the still-unknown character.
inline void ResetToUnknownCharacter(Store& a_st, const hzlog::Character& a_unknown)
{
	a_st = Store{};
	a_st.character = a_unknown;
}

// N-g: a load of a different real character must flush the outgoing bound store first.
inline bool MustFlushBeforeLoad(const hzlog::Character& a_current, const hzlog::Character& a_incoming)
{
	return CanWriteStore(a_current) && a_current.key != a_incoming.key;
}

// S-F: one parked store per character, cleared by generation (not by character key).
// A failed write is re-parked unless a newer generation for that character already exists.
// A same-character parked copy replaces a stale file read on load.
struct ParkedSnap
{
	Store         store;
	std::uint64_t gen = 0;
};

struct ParkedSet
{
	std::vector<ParkedSnap> entries;
	std::uint64_t           nextGen = 1;

	const ParkedSnap* Find(std::string_view a_key) const
	{
		for (const auto& e : entries)
			if (e.store.character.key == a_key) return &e;
		return nullptr;
	}

	ParkedSnap* Find(std::string_view a_key)
	{
		return const_cast<ParkedSnap*>(static_cast<const ParkedSet*>(this)->Find(a_key));
	}

	// Park a bound store. Returns the new generation, or 0 if the store is not writable.
	std::uint64_t Park(const Store& a_st)
	{
		if (!CanWriteStore(a_st.character)) return 0;
		if (auto* e = Find(a_st.character.key)) {
			e->store = a_st;
			e->gen = nextGen++;
			return e->gen;
		}
		ParkedSnap e;
		e.store = a_st;
		e.gen = nextGen++;
		entries.push_back(std::move(e));
		return entries.back().gen;
	}

	// Clear only this generation. A newer park for the same character is left alone.
	bool ClearGen(std::string_view a_key, std::uint64_t a_gen)
	{
		for (std::size_t i = 0; i < entries.size(); ++i) {
			if (entries[i].store.character.key == a_key && entries[i].gen == a_gen) {
				entries[i] = std::move(entries.back());
				entries.pop_back();
				return true;
			}
		}
		return false;
	}

	bool ShouldWrite(std::string_view a_key, std::uint64_t a_gen) const
	{
		const auto* e = Find(a_key);
		return e && e->gen == a_gen;
	}

	// Re-park a failed write unless a newer generation already exists for that character.
	std::uint64_t ReparkFailed(const Store& a_snap, std::uint64_t a_gen)
	{
		if (!CanWriteStore(a_snap.character)) return 0;
		if (const auto* e = Find(a_snap.character.key)) {
			if (e->gen > a_gen) return e->gen;
			if (e->gen == a_gen) return a_gen;
		}
		return Park(a_snap);
	}

	// If a parked copy exists, it replaces the stale file. Returns true when it did.
	bool OverlayFile(Store& a_file, const hzlog::Character& a_ch) const
	{
		const auto* e = Find(a_ch.key);
		if (!e) return false;
		a_file = e->store;
		a_file.character = a_ch;
		return true;
	}

	std::vector<ParkedSnap> Pending() const { return entries; }
};

// S-F: drop an in-flight file load when a later event (an unknown player ID) superseded it.
inline bool ShouldApplyLoad(const hzlog::Character& a_req, std::uint64_t a_reqGen,
	const hzlog::Character& a_cur, std::uint64_t a_curGen, bool a_loadReq)
{
	return a_loadReq && a_reqGen == a_curGen && a_req.key == a_cur.key;
}

// S-6: store write retry delay. 0 (first failure) -> 2 s, then doubling, capped at 30 s.
inline std::uint64_t NextWriteBackoffMs(std::uint64_t a_prev)
{
	if (a_prev < 2000) return 2000;
	const auto n = a_prev * 2;
	return n > 30000 ? 30000 : n;
}

// S-4: a queued use request is one 64-bit word: (tick ms << 16) | slot (| kReqFromMenu). A key press older than
// 250 ms (a covering menu, loading screen or pause kept the HUD from advancing) is dropped instead of firing late.
// A click in the quick menu gets 2 s (the menu's close animation runs before the HUD advances again).
inline constexpr int kReqFromMenu = 0x100;
inline constexpr std::uint64_t kKeyReqMaxAgeMs = 250;
inline constexpr std::uint64_t kMenuReqMaxAgeMs = 2000;

inline std::uint64_t PackUseReq(int a_req, std::uint64_t a_nowMs)
{
	return (a_nowMs << 16) | static_cast<std::uint64_t>(a_req & 0xFFFF);
}

inline int UseReqCode(std::uint64_t a_v) { return static_cast<int>(a_v & 0xFFFF); }

inline bool UseReqFresh(std::uint64_t a_v, std::uint64_t a_nowMs)
{
	if (!a_v) return false;
	const auto at = a_v >> 16;
	const auto age = a_nowMs >= at ? a_nowMs - at : 0;
	return age <= ((UseReqCode(a_v) & kReqFromMenu) ? kMenuReqMaxAgeMs : kKeyReqMaxAgeMs);
}

// S-3 / S-B: check a stored assignment against the form that ID now names.
// Clear only when the form exists and is no longer an inventory object (a load-order change
// pointed the ID at a different kind of form). A name-only mismatch (language switch, a rename
// mod, or an unreadable name) refuses the use but does not clear the slot. An empty current name
// is unknown, not stale.
enum class SlotCheck : int { Ok = 0, Refuse = 1, Clear = 2 };

inline SlotCheck AssignmentCheck(const Assignment& a, std::string_view a_curName, bool a_isItem)
{
	if (!a_isItem && a.kind == Kind::Inventory) return SlotCheck::Clear;
	if (a_curName.empty()) return SlotCheck::Ok;
	if (!a.base.empty() && NamesMatch(a.base, a_curName)) return SlotCheck::Ok;
	if (!a.name.empty() && NamesMatch(a.name, a_curName)) return SlotCheck::Ok;
	if (a.base.empty() && a.name.empty()) return SlotCheck::Ok;
	return SlotCheck::Refuse;
}

inline bool AssignmentStale(const Assignment& a, std::string_view a_curName, bool a_isItem)
{
	return AssignmentCheck(a, a_curName, a_isItem) != SlotCheck::Ok;
}

inline bool AssignmentClears(const Assignment& a, std::string_view a_curName, bool a_isItem)
{
	return AssignmentCheck(a, a_curName, a_isItem) == SlotCheck::Clear;
}

// Layout: centers of each visible slot, plus an ADD SLOT tile when count < 24.
// For CROSS+BARS, slots 1-12 are marked native (the movie keeps the vanilla T).
// tLeft/tRight/tBottom/tCx are the bounding box of the vanilla T, in the same units.
inline std::vector<SlotPos> PlaceSlots(const Settings& s, float tLeft, float tRight, float tBottom, float tCx, float screenCx, float screenCy)
{
	std::vector<SlotPos> out;
	const int n = s.extended ? ClampCount(s.slotCount) : kVanillaSlots;
	const int per = ClampPerRow(s.slotsPerRow);
	const float pitch = kPitch;

	auto pushRow = [&](int first /*1-based*/, int count, float y) {
		const float width = (count - 1) * pitch;
		const float x0 = (s.layout == Layout::CrossBars && first >= kExtFirst)
			? tCx - width * 0.5f
			: screenCx - width * 0.5f;
		for (int i = 0; i < count; ++i) {
			SlotPos p;
			p.index = first + i;
			p.x = x0 + i * pitch;
			p.y = y;
			p.native = false;
			out.push_back(p);
		}
	};

	if (!s.extended || s.layout == Layout::CrossBars) {
		for (int i = 1; i <= (std::min)(n, kVanillaSlots); ++i) {
			SlotPos p;
			p.index = i;
			p.native = true;
			out.push_back(p);
		}
		if (s.extended && n > kVanillaSlots) {
			int left = n - kVanillaSlots;
			int start = kExtFirst;
			int row = 0;
			while (left > 0) {
				const int take = (std::min)(per, left);
				const float y = tBottom + kGap + kBox * 0.5f + row * pitch;
				pushRow(start, take, y);
				start += take;
				left -= take;
				++row;
			}
		}
	} else {
		int left = n;
		int start = 1;
		const int rows = (n + per - 1) / per;
		const float y0 = screenCy - (rows - 1) * pitch * 0.5f;
		int row = 0;
		while (left > 0) {
			const int take = (std::min)(per, left);
			pushRow(start, take, y0 + row * pitch);
			start += take;
			left -= take;
			++row;
		}
		(void)tLeft;
		(void)tRight;
	}

	if (s.extended && n < kMaxSlots) {
		SlotPos add;
		add.index = 0;
		if (out.empty()) {
			add.x = screenCx;
			add.y = tBottom + kGap + kBox * 0.5f;
		} else {
			const auto& last = out.back();
			if (last.native) {
				add.x = tCx - (((std::min)(per, kMaxSlots - kVanillaSlots) - 1) * pitch) * 0.5f;
				add.y = tBottom + kGap + kBox * 0.5f;
			} else {
				const int extUsed = (std::max)(0, n - (s.layout == Layout::Bars ? 0 : kVanillaSlots));
				const int col = extUsed % per;
				if (col == 0) {
					const int take = (std::min)(per, kMaxSlots - n);
					const float width = (take - 1) * pitch;
					const float x0 = (s.layout == Layout::CrossBars) ? tCx - width * 0.5f : screenCx - width * 0.5f;
					add.x = x0;
					add.y = last.y + pitch;
				} else {
					add.x = last.x + pitch;
					add.y = last.y;
				}
			}
		}
		out.push_back(add);
	}
	(void)tLeft;
	(void)tRight;
	return out;
}

inline int SlotForKey(const Settings& s, std::string_view keyName)
{
	const auto want = CanonKey(keyName);
	if (want.empty() || !s.extended) return 0;
	for (int i = 0; i < 12; ++i) {
		if (s.key[i] == want && SlotVisible(s, kExtFirst + i)) return kExtFirst + i;
	}
	return 0;
}

// Refuse a bind already used by another extended slot, or already used by the game (hook).
inline bool CanBind(const Settings& s, int slot, std::string_view raw, const UseHooks& hooks, std::string* why)
{
	const auto k = CanonKey(raw);
	if (k.empty()) return true;
	if (!ValidKeyName(k)) { if (why) *why = "unknown key"; return false; }
	for (int i = 0; i < 12; ++i) {
		if (kExtFirst + i == slot) continue;
		if (s.key[i] == k) { if (why) *why = "already bound to another extended slot"; return false; }
	}
	if (hooks.keyBoundByGame && hooks.keyBoundByGame(k, hooks.ctx)) {
		if (why) *why = "already bound in the game's control map";
		return false;
	}
	return true;
}

// Movie assign payload: "P|name" (power), "I|name" (inventory), "I|0xFORM|name" (inventory with
// the item's form ID from the assign click), or a bare name (older movie = inventory).
struct AssignExtra
{
	bool          power = false;
	std::string   name;
	std::uint32_t formId = 0;
};

inline AssignExtra ParseAssignExtra(std::string_view raw)
{
	AssignExtra o;
	if (raw.size() >= 2 && raw[1] == '|' && (raw[0] == 'P' || raw[0] == 'I')) {
		o.power = raw[0] == 'P';
		raw.remove_prefix(2);
	}
	if (!o.power) {
		const auto bar = raw.find('|');
		if (bar != std::string_view::npos && bar > 0) {
			const auto id = ParseFormId(raw.substr(0, bar));
			if (id) {
				o.formId = id;
				raw.remove_prefix(bar + 1);
			}
		}
	}
	o.name = std::string(raw);
	return o;
}

// TESTONLY rule: slots 13-24 take inventory items only. Powers and Quantum Essence stay on 1-12
// until the in-game spike confirms UseSpell / essence activation from a non-vanilla slot.
inline bool IsEssenceName(std::string_view name)
{
	return Lower(std::string(name)).find("quantum essence") != std::string::npos;
}

// Payload records are "slot|name|count|kind|empty" joined by ';'. Keep names from breaking the split.
inline std::string PayloadSafe(std::string_view name)
{
	std::string o(name);
	for (auto& c : o) {
		if (c == '|' || c == ';') c = '/';
	}
	return o;
}

inline UseResult UseExtendedSlot(const Settings& s, const Store& st, int slot, const UseHooks& hooks)
{
	if (slot < kExtFirst || slot > kMaxSlots) return UseResult::BadSlot;
	if (!s.extended) return UseResult::Disabled;
	if (hooks.conflictModFound && hooks.conflictModFound(hooks.ctx)) return UseResult::Conflict;
	if (hooks.moduleInstalled && !hooks.moduleInstalled(hooks.ctx)) return UseResult::NoModule;
	if (!SlotVisible(s, slot)) return UseResult::BadSlot;
	if (hooks.inputBlocked && hooks.inputBlocked(hooks.ctx)) return UseResult::Blocked;
	const auto* a = FindSlot(st, slot);
	if (!a || a->formId == 0) return UseResult::Empty;
	if (hooks.formStale && hooks.formStale(*a, hooks.ctx)) return UseResult::Stale;  // never use a different item
	if (hooks.hasItem && !hooks.hasItem(a->formId, a->kind, hooks.ctx)) return UseResult::Missing;
	bool ok = false;
	if (a->kind == Kind::Power) {
		ok = hooks.usePower ? hooks.usePower(a->formId, hooks.ctx) : false;
	} else if (a->kind == Kind::Essence) {
		if (hooks.useEssence) ok = hooks.useEssence(a->formId, hooks.ctx);
		if (!ok && hooks.useInventory) ok = hooks.useInventory(a->formId, hooks.ctx);
		if (!ok && hooks.usePower) ok = hooks.usePower(a->formId, hooks.ctx);
	} else {
		ok = hooks.useInventory ? hooks.useInventory(a->formId, hooks.ctx) : false;
	}
	return ok ? UseResult::Ok : UseResult::Error;
}

inline const char* ResultName(UseResult r)
{
	switch (r) {
	case UseResult::Ok: return "ok";
	case UseResult::Empty: return "empty";
	case UseResult::Missing: return "missing";
	case UseResult::Blocked: return "blocked";
	case UseResult::NoModule: return "no-module";
	case UseResult::Conflict: return "conflict";
	case UseResult::Disabled: return "disabled";
	case UseResult::BadSlot: return "bad-slot";
	case UseResult::Stale: return "stale (item changed after a load-order change)";
	default: return "error";
	}
}

// Address Library IDs (1.16.244) as named by the QTR-Modding CommonLibSF fork (commit f672881).
// Horizon's pinned headers do not name them; the DLL looks them up through REL::ID.
// kIdInventoryAgentLock: the critical section the game holds around BGSInventoryInterface::agentArray
// (taken by GetInventoryObjectSub, the UseInventoryItem resolver and FavoritesManager::UseQuickkey).
inline constexpr std::uint64_t kIdUseInventoryItem = 101954;
inline constexpr std::uint64_t kIdUseSpell = 101916;
inline constexpr std::uint64_t kIdGetEquippedSpell = 116694;
inline constexpr std::uint64_t kIdPlayPowerSelectionSound = 113904;
inline constexpr std::uint64_t kIdFavoritesManagerUseQuickkey = 113918;  // not called; documented only
inline constexpr std::uint64_t kIdInventoryGetObjectSub = 63846;
inline constexpr std::uint64_t kIdInventorySingleton = 883301;
inline constexpr std::uint64_t kIdPlayerSingleton = 922868;
inline constexpr std::uint64_t kIdInventoryAgentLock = 888731;
inline constexpr std::uint64_t kIdRttiTESForm = 843049;
inline constexpr std::uint64_t kIdRttiTESFullName = 843072;

inline const char* ConflictDllNames[] = {
	"FavoritesMenuExtended.dll",
	"FavoritesBanks.dll",
	nullptr
};

}  // namespace hzqs
