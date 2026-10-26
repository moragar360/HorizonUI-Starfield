#pragma once

// F11 popup stack for Message Log P1 (input routing only, no log drawing).
// Only the top layer receives input. ESC/B pops one layer. A forced close
// (full-screen menu) must close every layer. A stuck layer is the freeze risk.
// F11 itself still opens from the keyboard only.
// Author: Moragar
// Last modified: 2026-10-25.

#include <string>
#include <vector>

namespace hzlog {

inline constexpr int kPopMax = 8;

class PopStack {
public:
	std::vector<std::string> layers; // bottom -> top. "f11", "arrange", "log", "logset", "confirm"

	// Purpose: push a layer. The new top is the only one that receives input.
	// Inputs: layer id. Outputs: true when pushed. A full stack is refused.
	bool Push(std::string a_id)
	{
		if (a_id.empty() || layers.size() >= static_cast<std::size_t>(kPopMax)) return false;
		layers.push_back(std::move(a_id));
		return true;
	}

	// Purpose: ESC/B. Close only the top layer.
	// Inputs: none. Outputs: the closed id, or empty when the stack is already empty.
	std::string Pop()
	{
		if (layers.empty()) return {};
		auto s = std::move(layers.back());
		layers.pop_back();
		return s;
	}

	// Purpose: forced close when a full-screen menu opens. Every layer goes.
	// Today's F11 path toggled at most twice, which leaves a deeper stack stuck.
	// Inputs: none. Outputs: how many layers were closed.
	int CloseAll()
	{
		const int n = static_cast<int>(layers.size());
		layers.clear();
		return n;
	}

	const std::string& Top() const
	{
		static const std::string empty;
		return layers.empty() ? empty : layers.back();
	}

	bool Empty() const { return layers.empty(); }
	int  Size() const { return static_cast<int>(layers.size()); }
	bool Open() const { return !layers.empty(); }
};

} // namespace hzlog
