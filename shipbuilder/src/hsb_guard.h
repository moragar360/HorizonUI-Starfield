#pragma once

// Purpose: pure rules for the read-only probe. No game calls.
// The plugin may append one log file. It may restore a window
// procedure only when that procedure is still the probe's own.
// Author: Moragar. Last modified: 2026-11-04.

#include <cstdint>
#include <string>
#include <string_view>

namespace hsb {

inline constexpr const char* kProbeFile = "HorizonShipBuilder_probe.log";
inline constexpr const char* kMenuName = "SpaceshipEditorMenu";
inline constexpr int kFormCap = 40;
inline constexpr std::size_t kFactCap = 480;
inline constexpr std::uint64_t kProbePollMs = 250;

inline bool ProbePollDue(std::uint64_t now, std::uint64_t last)
{
	if (last == 0) return true;
	return now >= last && now - last >= kProbePollMs;
}

// A ping that does not reach the probe means a newer subclass restored
// over it. The hook flag must clear so the next pass can install again.
inline bool HookWasRipped(bool wasHooked, bool pingReachedProbe)
{
	return wasHooked && !pingReachedProbe;
}

// An installed probe must call the previous procedure. An empty chain
// would drop input on the default procedure and never reach the game.
inline bool ChainIsLive(const void* previous)
{
	return previous != nullptr;
}

inline bool IsSep(char c)
{
	return c == '/' || c == '\\';
}

inline char Fold(char c)
{
	if (c >= 'A' && c <= 'Z') return static_cast<char>(c - 'A' + 'a');
	return c;
}

inline bool HasDotDot(std::string_view path)
{
	std::size_t i = 0;
	while (i < path.size()) {
		while (i < path.size() && IsSep(path[i])) ++i;
		const std::size_t start = i;
		while (i < path.size() && !IsSep(path[i])) ++i;
		if (path.substr(start, i - start) == "..") return true;
	}
	return false;
}

inline bool EndsWithFold(std::string_view text, std::string_view suffix)
{
	if (text.size() < suffix.size()) return false;
	const std::size_t off = text.size() - suffix.size();
	for (std::size_t i = 0; i < suffix.size(); ++i) {
		if (Fold(text[off + i]) != Fold(suffix[i])) return false;
	}
	return true;
}

inline bool ContainsFold(std::string_view text, std::string_view needle)
{
	if (needle.empty() || text.size() < needle.size()) return false;
	for (std::size_t i = 0; i + needle.size() <= text.size(); ++i) {
		bool match = true;
		for (std::size_t j = 0; j < needle.size(); ++j) {
			if (Fold(text[i + j]) != Fold(needle[j])) {
				match = false;
				break;
			}
		}
		if (match) return true;
	}
	return false;
}

// True only for the probe log under Documents\...\SFSE\Logs.
inline bool ProbeMayAppend(std::string_view path)
{
	if (path.empty() || HasDotDot(path)) return false;
	const auto slash = path.find_last_of("/\\");
	if (slash == std::string_view::npos) return false;
	if (path.substr(slash + 1) != kProbeFile) return false;
	const auto parent = path.substr(0, slash);
	if (!EndsWithFold(parent, "SFSE\\Logs") && !EndsWithFold(parent, "SFSE/Logs")) return false;
	if (!ContainsFold(path, "My Games")) return false;
	if (!ContainsFold(path, "Starfield")) return false;
	return true;
}

inline std::string SanitizeFact(std::string_view text)
{
	std::string out;
	out.reserve(text.size() < kFactCap ? text.size() : kFactCap);
	for (unsigned char c : text) {
		if (out.size() >= kFactCap) break;
		if (c == '\n' || c == '\r' || c == '\t') out.push_back(' ');
		else if (c < 32) continue;
		else out.push_back(static_cast<char>(c));
	}
	return out;
}

inline std::string FactLine(std::string_view id, std::string_view text)
{
	return std::string("FACT ") + std::string(id) + " | " + SanitizeFact(text);
}

// Restore the previous procedure only when the probe still owns the hook.
inline bool ShouldRestoreWndProc(const void* current, const void* ours)
{
	return current != nullptr && ours != nullptr && current == ours;
}

inline int NextFormSlot(int count)
{
	if (count < 0 || count >= kFormCap) return -1;
	return count + 1;
}

inline int HexValue(char c)
{
	if (c >= '0' && c <= '9') return c - '0';
	if (c >= 'a' && c <= 'f') return c - 'a' + 10;
	if (c >= 'A' && c <= 'F') return c - 'A' + 10;
	return -1;
}

// "FORM" plus one space plus 1 to 8 hex digits. Nothing else is a lookup.
inline bool ParseFormLine(std::string_view line, std::uint32_t& id)
{
	constexpr std::string_view kHead = "FORM ";
	if (line.size() < kHead.size() + 1) return false;
	if (line.substr(0, kHead.size()) != kHead) return false;
	std::uint32_t value = 0;
	int digits = 0;
	for (std::size_t i = kHead.size(); i < line.size(); ++i) {
		const int nibble = HexValue(line[i]);
		if (nibble < 0) return false;
		if (digits == 8) return false;
		value = (value << 4) | static_cast<std::uint32_t>(nibble);
		++digits;
	}
	if (digits < 1) return false;
	id = value;
	return true;
}

}  // namespace hsb
