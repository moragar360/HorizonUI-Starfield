#pragma once

// Purpose: the HUD-message queue policy, with no lock and no game types, so a harness can run it.
// Inputs: a deque of notes (a char text[201], a tick, and a truncated flag), the raw line, the
// time, the cap, and an optional already-cut flag from a prior 200-byte snap.
// Outputs: true when the note was stored. Empty text is dropped. An exact duplicate of a stored
// note is dropped. The copy is at most 200 bytes and does not split a UTF-8 character. The oldest
// note is dropped when the cap is full. truncated is set when the source was longer than the copy
// so GameNotice can skip a cut-off line (the game's own line then shows alone).
// Dependencies: hzpreset::CopyHudText.
// Last modified: 2026-11-01.

#include "preset_dedupe.h"

#include <cstddef>
#include <cstring>

namespace hzrx {

template <class Queue>
inline bool Enqueue(Queue& a_q, const char* a_text, unsigned long long a_now, std::size_t a_cap = 8,
	bool a_truncated = false)
{
	if (!a_text || !a_text[0] || a_cap == 0) return false;
	char buf[201];
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
	a_q.push_back(n);
	return true;
}

}
