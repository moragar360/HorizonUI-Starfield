#pragma once

// Purpose: the HUD-message queue policy, with no lock and no game types, so a harness can run it.
// Inputs: a deque of notes (a char text[257], a tick, a truncated flag, and an artifact flag),
// the raw line, the time, the cap, an optional already-cut flag, and an optional artifact flag
// from the full event text (so "artifact" past byte 256 still titles ARTIFACT).
// Outputs: true when the note was stored. Empty text is dropped. An exact duplicate of a stored
// note is dropped. The copy is at most 256 bytes and does not split a UTF-8 character. The oldest
// note is dropped when the cap is full. truncated is set when the source was longer than the copy.
// artifact is set from the full source line or a_artifact. The card still ellipsizes to 200 bytes later.
// Dependencies: hzpreset::CopyHudText.
// Last modified: 2026-11-01.

#include "preset_dedupe.h"

#include <cstddef>
#include <cstring>

namespace hzrx {

inline bool LineHasArtifact(const char* a_s)
{
	if (!a_s) return false;
	static constexpr char kNeedle[] = "artifact";
	for (std::size_t i = 0; a_s[i] != '\0'; ++i) {
		std::size_t j = 0;
		for (; kNeedle[j] != '\0'; ++j) {
			char c = a_s[i + j];
			if (c == '\0') return false;
			if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
			if (c != kNeedle[j]) break;
		}
		if (kNeedle[j] == '\0') return true;
	}
	return false;
}

template <class Queue>
inline bool Enqueue(Queue& a_q, const char* a_text, unsigned long long a_now, std::size_t a_cap = 8,
	bool a_truncated = false, bool a_artifact = false)
{
	if (!a_text || !a_text[0] || a_cap == 0) return false;
	char buf[257];
	const bool cut = hzpreset::CopyHudText(buf, sizeof buf, a_text);
	if (buf[0] == '\0') return false;
	for (const auto& q : a_q) {
		if (std::strcmp(q.text, buf) == 0) return false;
	}
	if (a_q.size() >= a_cap) a_q.pop_front();
	using Note = typename Queue::value_type;
	Note n{};
	std::size_t i = 0;
	for (; i + 1 < sizeof n.text && buf[i] != '\0'; ++i) n.text[i] = buf[i];
	n.text[i] = '\0';
	n.tick = a_now;
	n.truncated = cut || a_truncated;
	n.artifact = a_artifact || LineHasArtifact(a_text);
	a_q.push_back(n);
	return true;
}

}
