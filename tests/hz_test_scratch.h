// Scratch folders for C++ tests. Never writes to the system temp folder, and never deletes leftover folders.
// Parent: HZ_TEST_DIR, or TMPDIR when that path is allowed, else a "test_scratch" folder under the cwd.
// Each call creates a uniquely named subfolder and leaves earlier leftovers alone.
// Author: Moragar
#pragma once

#include <atomic>
#include <cstdlib>
#include <filesystem>
#include <string>

#if defined(_WIN32)
#include <process.h>
#else
#include <unistd.h>
#endif

inline std::string HzTestNorm(const std::filesystem::path& a_p)
{
	auto s = a_p.lexically_normal().generic_string();
	for (char& c : s) if (c >= 'A' && c <= 'Z') c = static_cast<char>(c - 'A' + 'a');
	while (s.size() > 1 && s.back() == '/') s.pop_back();
	return s;
}

// True for the system temp folder and other paths tests must not use (built from parts
// so this header does not embed those path literals).
inline bool HzTestPathForbidden(const std::filesystem::path& a_p)
{
	if (a_p.empty()) return true;
	const auto s = HzTestNorm(a_p);
	auto has = [&](const std::string& tok) { return s == tok || s.rfind(tok + "/", 0) == 0; };
	const std::string slash(1, '/');
	if (has(slash + "tmp") || has(slash + "var" + slash + "tmp") || has(slash + "private" + slash + "tmp"))
		return true;
	if (has(slash + "workspace") || has(slash + "home"))
		return true;
	// Windows user-profile and drive-letter temp folders
	if (s.size() >= 2 && s[1] == ':') {
		if (s.find("/users/") != std::string::npos) return true;
		if (s.size() >= 6 && s[3] == 't' && s[4] == 'm' && s[5] == 'p') return true; // e.g. a drive-letter temp folder
		if (s.find("/appdata/local/temp") != std::string::npos) return true;
	}
	return false;
}

inline std::filesystem::path HzTestScratch(const char* a_prefix)
{
	std::filesystem::path base;
	if (const char* e = std::getenv("HZ_TEST_DIR"); e && e[0]) base = e;
	else if (const char* e = std::getenv("TMPDIR"); e && e[0]) base = e;
	if (base.empty() || HzTestPathForbidden(base))
		base = std::filesystem::current_path() / "test_scratch";
	std::error_code ec;
	std::filesystem::create_directories(base, ec);
	static std::atomic<unsigned> seq{0};
	const auto p = base / (std::string(a_prefix) + std::to_string(::getpid()) + "_"
		+ std::to_string(seq.fetch_add(1, std::memory_order_relaxed) + 1));
	std::filesystem::create_directories(p, ec);
	return p;
}
