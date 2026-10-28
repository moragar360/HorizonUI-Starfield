// Message Log P1: capture, ring, pins, prune, per-character files, Persist=0,
// save-line exclusion, and the F11 popup stack. No game, no CommonLibSF.
// These cases are written to fail when a rule is broken.
// Build: g++ -std=c++20 -Wall -Wextra -pthread -I src -DMSGLOG_REPO_ROOT=\"$PWD\" tests/message_log_test.cpp -o /tmp/message_log_test
// Or: MSGLOG_REPO_ROOT=$PWD /tmp/message_log_test  (relative __FILE__ still finds the repo).
// Author: Moragar
// Last modified: 2026-10-28.

#include "hz_addr_probe.h"
#include "hz_msglog.h"
#include "hz_msglog_stack.h"
#include "hz_version.h"

#include <atomic>
#include <cctype>
#include <chrono>
#include <condition_variable>
#include <cstdint>
#include <cstring>
#include <cstdlib>
#include <filesystem>
#include <fstream>
#include <iostream>
#include <limits>
#include <mutex>
#include <set>
#include <string>
#include <string_view>
#include <thread>
#include <unistd.h>
#include <vector>

#ifndef MSGLOG_REPO_ROOT
#define MSGLOG_REPO_ROOT ""
#endif

namespace {

int g_fails = 0;

void Expect(bool a_ok, const char* a_what)
{
	if (a_ok) return;
	std::cerr << "FAIL: " << a_what << "\n";
	++g_fails;
}

void ExpectEq(const std::string& a_got, const std::string& a_want, const char* a_what)
{
	if (a_got == a_want) return;
	std::cerr << "FAIL: " << a_what << "\n  got:  [" << a_got << "]\n  want: [" << a_want << "]\n";
	++g_fails;
}

void ExpectEqI(int a_got, int a_want, const char* a_what)
{
	if (a_got == a_want) return;
	std::cerr << "FAIL: " << a_what << "\n  got:  " << a_got << "\n  want: " << a_want << "\n";
	++g_fails;
}

hzlog::Capture Cap(hzlog::Kind a_k, const char* a_text, std::uint64_t a_now, double a_gt = 10.0, const char* a_loc = "Akila City")
{
	hzlog::Capture c;
	c.kind = a_k;
	c.text = a_text;
	c.title = hzlog::KindKey(a_k);
	c.ts = static_cast<std::int64_t>(a_now / 1000);
	c.nowMs = a_now;
	c.gt = a_gt;
	c.ut = 14.5;
	c.lt = 0.3;
	c.loc = a_loc;
	return c;
}

std::filesystem::path TmpRoot()
{
	auto p = std::filesystem::temp_directory_path() / ("hz-msglog-" + std::to_string(::getpid()));
	std::error_code ec;
	std::filesystem::remove_all(p, ec);
	std::filesystem::create_directories(p, ec);
	return p;
}

std::string ReadFile(const std::filesystem::path& a_p)
{
	std::ifstream f(a_p, std::ios::binary);
	return std::string((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

int CountNeedle(const std::string& a_hay, const std::string& a_needle)
{
	int n = 0;
	for (std::size_t p = 0; (p = a_hay.find(a_needle, p)) != std::string::npos; p += a_needle.size())
		++n;
	return n;
}

void WriteFile(const std::filesystem::path& a_p, const std::string& a_s)
{
	std::error_code ec;
	std::filesystem::create_directories(a_p.parent_path(), ec);
	std::ofstream o(a_p, std::ios::binary | std::ios::trunc);
	o << a_s;
}

void CollectSrcFiles(const std::filesystem::path& a_dir, std::vector<std::filesystem::path>& a_out)
{
	std::error_code ec;
	if (!std::filesystem::is_directory(a_dir, ec)) return;
	for (std::filesystem::directory_iterator it(a_dir, ec), end; !ec && it != end; it.increment(ec)) {
		const auto name = it->path().filename().string();
		if (it->is_directory(ec)) {
			if (name == "commonlibsf" || name == ".git") continue;
			CollectSrcFiles(it->path(), a_out);
			continue;
		}
		const auto ext = it->path().extension().string();
		if (ext == ".h" || ext == ".hpp" || ext == ".cpp" || ext == ".c")
			a_out.push_back(it->path());
	}
}

bool IdentChar(char a_c)
{
	return std::isalnum(static_cast<unsigned char>(a_c)) || a_c == '_';
}

bool IdentStart(char a_c)
{
	return std::isalpha(static_cast<unsigned char>(a_c)) || a_c == '_';
}

std::string LowerCopy(std::string a_s)
{
	for (char& c : a_s)
		c = static_cast<char>(std::tolower(static_cast<unsigned char>(c)));
	return a_s;
}

bool SameIdent(std::string_view a_a, std::string_view a_b)
{
	if (a_a.size() != a_b.size()) return false;
	for (std::size_t i = 0; i < a_a.size(); ++i) {
		if (std::tolower(static_cast<unsigned char>(a_a[i]))
			!= std::tolower(static_cast<unsigned char>(a_b[i])))
			return false;
	}
	return true;
}

bool StartsIdent(std::string_view a_ident, std::string_view a_prefix)
{
	if (a_ident.size() < a_prefix.size()) return false;
	return SameIdent(a_ident.substr(0, a_prefix.size()), a_prefix);
}

bool IsRemoveAlgorithm(std::string_view a_ident)
{
	return SameIdent(a_ident, "remove_if")
		|| SameIdent(a_ident, "remove_copy")
		|| SameIdent(a_ident, "remove_copy_if")
		|| SameIdent(a_ident, "remove_prefix")
		|| SameIdent(a_ident, "remove_suffix");
}

// Purpose: drop comments and string/char literals so the no-delete scan
// does not match prose or "Remove from list" text. Newlines stay so
// #define / using lines can still be read. Inputs: source text.
// Outputs: the same length-ish text with comments and strings blanked.
std::string StripCommentsAndStrings(const std::string& a_text)
{
	std::string o;
	o.reserve(a_text.size());
	const std::size_t n = a_text.size();
	std::size_t i = 0;
	auto blank = [&](std::size_t a_from, std::size_t a_to) {
		for (std::size_t k = a_from; k < a_to && k < n; ++k)
			o.push_back(a_text[k] == '\n' ? '\n' : ' ');
	};
	while (i < n) {
		if (a_text[i] == 'R' && i + 1 < n && a_text[i + 1] == '"') {
			std::size_t d = i + 2;
			while (d < n && a_text[d] != '(' && a_text[d] != '"' && a_text[d] != '\n')
				++d;
			if (d < n && a_text[d] == '(') {
				const std::string delim = a_text.substr(i + 2, d - (i + 2));
				const std::string end = ")" + delim + "\"";
				const auto close = a_text.find(end, d + 1);
				const auto stop = close == std::string::npos ? n : close + end.size();
				blank(i, stop);
				i = stop;
				continue;
			}
		}
		if (a_text[i] == '"' || ((a_text[i] == 'L' || a_text[i] == 'u' || a_text[i] == 'U')
			&& i + 1 < n && a_text[i + 1] == '"')) {
			std::size_t k = a_text[i] == '"' ? i + 1 : i + 2;
			while (k < n && a_text[k] != '"' && a_text[k] != '\n') {
				if (a_text[k] == '\\' && k + 1 < n) k += 2;
				else ++k;
			}
			if (k < n && a_text[k] == '"') ++k;
			blank(i, k);
			i = k;
			continue;
		}
		if (a_text[i] == '\'') {
			std::size_t k = i + 1;
			while (k < n && a_text[k] != '\'' && a_text[k] != '\n') {
				if (a_text[k] == '\\' && k + 1 < n) k += 2;
				else ++k;
			}
			if (k < n && a_text[k] == '\'') ++k;
			blank(i, k);
			i = k;
			continue;
		}
		if (a_text[i] == '/' && i + 1 < n && a_text[i + 1] == '/') {
			std::size_t k = i + 2;
			while (k < n && a_text[k] != '\n') ++k;
			blank(i, k);
			i = k;
			continue;
		}
		if (a_text[i] == '/' && i + 1 < n && a_text[i + 1] == '*') {
			const auto close = a_text.find("*/", i + 2);
			const auto stop = close == std::string::npos ? n : close + 2;
			blank(i, stop);
			i = stop;
			continue;
		}
		o.push_back(a_text[i]);
		++i;
	}
	return o;
}

bool SkipWs(const std::string& a_s, std::size_t& a_i)
{
	while (a_i < a_s.size() && std::isspace(static_cast<unsigned char>(a_s[a_i])))
		++a_i;
	return a_i < a_s.size();
}

bool MatchWord(const std::string& a_s, std::size_t a_i, std::string_view a_word)
{
	if (a_i + a_word.size() > a_s.size()) return false;
	if (!SameIdent(std::string_view(a_s).substr(a_i, a_word.size()), a_word))
		return false;
	const auto after = a_i + a_word.size();
	if (after < a_s.size() && IdentChar(a_s[after])) return false;
	if (a_i > 0 && IdentChar(a_s[a_i - 1])) return false;
	return true;
}

struct DeleteHit {
	std::string token;
};

bool IdentIsBanned(std::string_view a_ident)
{
	if (a_ident.empty() || IsRemoveAlgorithm(a_ident)) return false;
	static const char* exact[] = {
		"remove_all", "unlink", "_unlink", "_wunlink", "rmdir", "_rmdir", "_wrmdir",
		"_wremove", "_remove", "IFileOperation", "FO_DELETE",
		"DELETE_ON_CLOSE", "NtDeleteFile", "SetFileInformationByHandle",
		"FileDispositionInfoEx", "FILE_DISPOSITION_INFO_EX", "ZwDeleteFile",
		"NtSetInformationFile", "ZwSetInformationFile", "CLSID_FileOperation"
	};
	for (const char* t : exact)
		if (SameIdent(a_ident, t)) return true;
	static const char* prefix[] = {
		"DeleteFile", "RemoveDirectory", "SHFileOperation", "FILE_DISPOSITION",
		"ReplaceFile", "FileDispositionInfo"
	};
	for (const char* t : prefix)
		if (StartsIdent(a_ident, t)) return true;
	const auto low = LowerCopy(std::string(a_ident));
	if (low.find("delete_on_close") != std::string::npos) return true;
	return false;
}

bool StringNamesBannedApi(std::string_view a_lit)
{
	std::size_t i = 0;
	while (i < a_lit.size()) {
		if (!IdentStart(a_lit[i])) {
			++i;
			continue;
		}
		std::size_t e = i + 1;
		while (e < a_lit.size() && IdentChar(a_lit[e])) ++e;
		if (IdentIsBanned(a_lit.substr(i, e - i)))
			return true;
		i = e;
	}
	return false;
}

bool ShellDeleteCmd(std::string_view a_lit)
{
	const auto low = LowerCopy(std::string(a_lit));
	auto word = [&](std::string_view a_w) {
		std::size_t p = 0;
		while ((p = low.find(a_w, p)) != std::string::npos) {
			const bool left = p == 0 || !IdentChar(low[p - 1]);
			const bool right = p + a_w.size() == low.size() || !IdentChar(low[p + a_w.size()]);
			if (left && right) return true;
			++p;
		}
		return false;
	};
	return word("del") || word("erase") || word("rmdir") || word("rd") || word("remove-item");
}

bool IsShellSpawnName(std::string_view a_id)
{
	return SameIdent(a_id, "system") || SameIdent(a_id, "_wsystem")
		|| SameIdent(a_id, "_popen") || SameIdent(a_id, "popen")
		|| StartsIdent(a_id, "ShellExecute") || StartsIdent(a_id, "CreateProcess");
}

bool IsGetProcName(std::string_view a_id)
{
	return StartsIdent(a_id, "GetProcAddress");
}

std::size_t SkipStringLit(const std::string& a_s, std::size_t a_i, std::string* a_out)
{
	if (a_i >= a_s.size()) return a_i;
	std::size_t i = a_i;
	if (a_s[i] == 'L' || a_s[i] == 'u' || a_s[i] == 'U') ++i;
	if (i >= a_s.size() || (a_s[i] != '"' && a_s[i] != '\'')) return a_i;
	const char q = a_s[i++];
	std::string v;
	while (i < a_s.size() && a_s[i] != q && a_s[i] != '\n') {
		if (a_s[i] == '\\' && i + 1 < a_s.size()) {
			v.push_back(a_s[i + 1]);
			i += 2;
			continue;
		}
		v.push_back(a_s[i++]);
	}
	if (i < a_s.size() && a_s[i] == q) ++i;
	if (a_out) *a_out = std::move(v);
	return i;
}

std::size_t SkipBalanced(const std::string& a_s, std::size_t a_open)
{
	if (a_open >= a_s.size() || a_s[a_open] != '(') return a_open;
	int depth = 0;
	std::size_t i = a_open;
	while (i < a_s.size()) {
		if (a_s[i] == '"' || a_s[i] == '\'' || ((a_s[i] == 'L' || a_s[i] == 'u' || a_s[i] == 'U')
			&& i + 1 < a_s.size() && (a_s[i + 1] == '"' || a_s[i + 1] == '\''))) {
			i = SkipStringLit(a_s, i, nullptr);
			continue;
		}
		if (a_s[i] == '(') ++depth;
		else if (a_s[i] == ')') {
			--depth;
			++i;
			if (depth == 0) return i;
			continue;
		}
		++i;
	}
	return i;
}

bool MoveFileExNullDest(const std::string& a_s, std::size_t a_name)
{
	std::size_t i = a_name + 10; // MoveFileEx
	while (i < a_s.size() && IdentChar(a_s[i])) ++i;
	SkipWs(a_s, i);
	if (i >= a_s.size() || a_s[i] != '(') return false;
	++i;
	int depth = 0;
	while (i < a_s.size()) {
		if (a_s[i] == '"' || a_s[i] == '\'' || ((a_s[i] == 'L' || a_s[i] == 'u' || a_s[i] == 'U')
			&& i + 1 < a_s.size() && (a_s[i + 1] == '"' || a_s[i + 1] == '\''))) {
			i = SkipStringLit(a_s, i, nullptr);
			continue;
		}
		if (a_s[i] == '(') {
			++depth;
			++i;
			continue;
		}
		if (a_s[i] == ')') {
			if (depth == 0) return false;
			--depth;
			++i;
			continue;
		}
		if (a_s[i] == ',' && depth == 0) {
			++i;
			SkipWs(a_s, i);
			return a_s.compare(i, 7, "nullptr") == 0 || a_s.compare(i, 4, "NULL") == 0
				|| (i < a_s.size() && a_s[i] == '0'
					&& (i + 1 == a_s.size() || !IdentChar(a_s[i + 1])));
		}
		++i;
	}
	return false;
}

void CollectCallStrings(const std::string& a_s, std::size_t a_open, std::vector<std::string>& a_out)
{
	if (a_open >= a_s.size() || a_s[a_open] != '(') return;
	const auto end = SkipBalanced(a_s, a_open);
	std::size_t i = a_open + 1;
	while (i < end) {
		if (a_s[i] == '"' || a_s[i] == '\'' || ((a_s[i] == 'L' || a_s[i] == 'u' || a_s[i] == 'U')
			&& i + 1 < a_s.size() && (a_s[i + 1] == '"' || a_s[i + 1] == '\''))) {
			std::string v;
			i = SkipStringLit(a_s, i, &v);
			if (!v.empty()) a_out.push_back(std::move(v));
			continue;
		}
		++i;
	}
}

bool RemoveIsQualified(const std::string& a_s, std::size_t a_identAt)
{
	std::size_t i = a_identAt;
	while (i > 0 && std::isspace(static_cast<unsigned char>(a_s[i - 1])))
		--i;
	if (i >= 2 && a_s[i - 1] == ':' && a_s[i - 2] == ':') {
		std::size_t q = i - 2;
		while (q > 0 && std::isspace(static_cast<unsigned char>(a_s[q - 1])))
			--q;
		if (q >= 3 && SameIdent(std::string_view(a_s).substr(q - 3, 3), "std"))
			return true;
		if (q >= 2 && SameIdent(std::string_view(a_s).substr(q - 2, 2), "fs"))
			return true;
		std::size_t b = q;
		while (b > 0 && IdentChar(a_s[b - 1]))
			--b;
		if (b < q && SameIdent(std::string_view(a_s).substr(b, q - b), "filesystem"))
			return true;
		return true; // ::remove
	}
	return false;
}

bool FollowedByCall(const std::string& a_s, std::size_t a_afterIdent)
{
	std::size_t i = a_afterIdent;
	SkipWs(a_s, i);
	return i < a_s.size() && a_s[i] == '(';
}

// Purpose: find file-erase APIs after comments and strings are stripped.
// Whole banned identifiers, optional whitespace before '(', and any
// #define / using that names a banned identifier. std::remove is only
// allowed when it is clearly remove_if (or another iterator algorithm).
// Inputs: source text. Outputs: one hit per banned use.
std::vector<DeleteHit> FindDeleteCalls(const std::string& a_text)
{
	const auto s = StripCommentsAndStrings(a_text);
	std::vector<DeleteHit> hits;
	auto add = [&](std::string a_tok) {
		for (const auto& h : hits)
			if (h.token == a_tok) return;
		hits.push_back(DeleteHit{std::move(a_tok)});
	};
	bool usingStd = false;
	bool usingFs = false;
	std::size_t i = 0;
	while (i < s.size()) {
		if (s[i] == '#' ) {
			std::size_t k = i + 1;
			SkipWs(s, k);
			if (MatchWord(s, k, "define")) {
				k += 6;
				const auto eol = s.find('\n', k);
				const auto line = s.substr(k, (eol == std::string::npos ? s.size() : eol) - k);
				std::size_t p = 0;
				while (p < line.size()) {
					if (!IdentStart(line[p])) {
						++p;
						continue;
					}
					std::size_t e = p + 1;
					while (e < line.size() && IdentChar(line[e])) ++e;
					const auto id = std::string_view(line).substr(p, e - p);
					if (IdentIsBanned(id) || SameIdent(id, "remove"))
						add(std::string("#define ") + std::string(id));
					p = e;
				}
				i = eol == std::string::npos ? s.size() : eol;
				continue;
			}
		}
		if (MatchWord(s, i, "using")) {
			std::size_t k = i + 5;
			const auto semi = s.find(';', k);
			const auto eol = s.find('\n', k);
			const auto stop = std::min(
				semi == std::string::npos ? s.size() : semi,
				eol == std::string::npos ? s.size() : eol);
			const auto clause = s.substr(k, stop - k);
			if (clause.find("namespace") != std::string::npos) {
				const auto low = LowerCopy(clause);
				if (low.find("filesystem") != std::string::npos)
					usingFs = true;
				else if (low.find("std") != std::string::npos)
					usingStd = true;
			}
			std::size_t p = 0;
			while (p < clause.size()) {
				if (!IdentStart(clause[p])) {
					++p;
					continue;
				}
				std::size_t e = p + 1;
				while (e < clause.size() && IdentChar(clause[e])) ++e;
				const auto id = std::string_view(clause).substr(p, e - p);
				if (IdentIsBanned(id) || SameIdent(id, "remove"))
					add(std::string("using ") + std::string(id));
				p = e;
			}
			i += 5;
			continue;
		}
		if (IdentStart(s[i]) && (i == 0 || !IdentChar(s[i - 1]))) {
			std::size_t e = i + 1;
			while (e < s.size() && IdentChar(s[e])) ++e;
			const auto id = std::string_view(s).substr(i, e - i);
			if (IdentIsBanned(id)) {
				add(std::string(id));
			} else if (SameIdent(id, "remove") && !IsRemoveAlgorithm(id)) {
				const bool call = FollowedByCall(s, e);
				const bool qual = RemoveIsQualified(s, i);
				if (qual || call || usingStd || usingFs)
					add("remove");
			}
			i = e;
			continue;
		}
		++i;
	}
	std::size_t p = 0;
	while (p < a_text.size()) {
		if (a_text[p] == '"' || a_text[p] == '\'' || ((a_text[p] == 'L' || a_text[p] == 'u' || a_text[p] == 'U')
			&& p + 1 < a_text.size() && (a_text[p + 1] == '"' || a_text[p + 1] == '\''))) {
			std::string lit;
			p = SkipStringLit(a_text, p, &lit);
			if (StringNamesBannedApi(lit))
				add(std::string("string ") + lit);
			continue;
		}
		if (a_text[p] == '/' && p + 1 < a_text.size() && a_text[p + 1] == '/') {
			while (p < a_text.size() && a_text[p] != '\n') ++p;
			continue;
		}
		if (a_text[p] == '/' && p + 1 < a_text.size() && a_text[p + 1] == '*') {
			const auto close = a_text.find("*/", p + 2);
			p = close == std::string::npos ? a_text.size() : close + 2;
			continue;
		}
		if (IdentStart(a_text[p]) && (p == 0 || !IdentChar(a_text[p - 1]))) {
			std::size_t e = p + 1;
			while (e < a_text.size() && IdentChar(a_text[e])) ++e;
			const auto id = std::string_view(a_text).substr(p, e - p);
			std::size_t k = e;
			SkipWs(a_text, k);
			if (k < a_text.size() && a_text[k] == '(') {
				std::vector<std::string> args;
				CollectCallStrings(a_text, k, args);
				if (IsGetProcName(id)) {
					for (const auto& a : args) {
						if (StringNamesBannedApi(a) || SameIdent(a, "remove"))
							add(std::string("GetProcAddress ") + a);
					}
				} else if (IsShellSpawnName(id)) {
					for (const auto& a : args) {
						if (ShellDeleteCmd(a))
							add(std::string(id) + " " + a);
					}
				}
			}
			if (StartsIdent(id, "MoveFileEx") && MoveFileExNullDest(a_text, p))
				add("MoveFileEx null dest");
			p = e;
			continue;
		}
		++p;
	}
	return hits;
}

void ExpectNoDeleteCalls(const std::string& a_text, const std::string& a_file)
{
	for (const auto& h : FindDeleteCalls(a_text))
		Expect(false, (a_file + " must not call " + h.token).c_str());
}

// Purpose: prove the no-delete scanner catches every known bypass and
// ignores remove_if, comments, strings, and "Remove from list".
void TestNoDeleteScannerSelf()
{
	const char* seeds[] = {
		"#define HZ_DEL ::remove",
		"fs::remove_all(p)",
		"using namespace std;\nremove(path);",
		"using namespace std::filesystem;\nremove(path);",
		"::remove (path)",
		"unlink(path)",
		"rmdir(path)",
		"_rmdir(path)",
		"_wrmdir(path)",
		"IFileOperation* op",
		"FileDispositionInfo info",
		"FILE_DISPOSITION_INFO d",
		"FO_DELETE",
		"ReplaceFileW(a,b,c,d,e,f)",
		"SetFileInformationByHandle(h,c,p,n)",
		"DeleteFileW(path)",
		"DeleteFileA(path)",
		"RemoveDirectoryW(path)",
		"RemoveDirectoryA(path)",
		"FILE_FLAG_DELETE_ON_CLOSE",
		"SHFileOperationW(&op)",
		"NtDeleteFile(&oa)",
		"std::filesystem::remove(p)",
		"std::remove(path)",
		"using std::remove;",
		"FileDispositionInfoEx x",
		"FILE_DISPOSITION_INFO_EX d",
		"ZwDeleteFile(&oa)",
		"NtSetInformationFile(h, ios, p, n, c)",
		"ZwSetInformationFile(h, ios, p, n, c)",
		"CLSID_FileOperation",
		"GetProcAddress(m, \"DeleteFileW\")",
		"GetProcAddress(m, \"NtDeleteFile\")",
		"system(\"del /q file\")",
		"_wsystem(L\"erase file\")",
		"_popen(\"rmdir dir\", \"r\")",
		"ShellExecuteW(0,0,L\"cmd\",L\"/c rd /s dir\",0,0)",
		"CreateProcessW(0, L\"powershell Remove-Item x\", 0,0,0,0,0,0,0,0)",
		"const char* n = \"DeleteFileW\";",
		"MoveFileEx(foo(a, b), nullptr, flags)",
		"MoveFileExW(bar(1,2), NULL, 0)",
		"MoveFileEx(x, 0, flags)",
	};
	for (const char* seed : seeds) {
		const auto hits = FindDeleteCalls(seed);
		Expect(!hits.empty(), (std::string("scanner catches: ") + seed).c_str());
	}
	const char* negatives[] = {
		"v.erase(std::remove_if(v.begin(), v.end(), pred), v.end());",
		"// please remove this file with DeleteFile later",
		"const char* s = \"please remove the file\";",
		"rows.push({\"l\":\"Remove from list\"});",
		"first.remove_suffix(1);",
		"phrase.remove_prefix(1);",
		"std::string removed = \"Removed.\";",
		"system(\"echo hello\");",
		"CreateProcessW(0, L\"game.exe\", 0,0,0,0,0,0,0,0);",
		"GetProcAddress(m, \"XInputGetState\");",
		"MoveFileExW(tmp, dst, MOVEFILE_REPLACE_EXISTING);",
	};
	for (const char* seed : negatives) {
		const auto hits = FindDeleteCalls(seed);
		Expect(hits.empty(), (std::string("scanner allows: ") + seed).c_str());
	}
}

std::filesystem::path RepoRoot()
{
	std::error_code ec;
	std::vector<std::filesystem::path> seeds;
	if (const char* env = std::getenv("MSGLOG_REPO_ROOT"); env && env[0])
		seeds.emplace_back(env);
	if (MSGLOG_REPO_ROOT[0])
		seeds.emplace_back(MSGLOG_REPO_ROOT);
	auto src = std::filesystem::path(__FILE__);
	if (src.is_relative())
		seeds.push_back(std::filesystem::current_path(ec) / src);
	else
		seeds.push_back(src);
	seeds.push_back(std::filesystem::current_path(ec));
#ifdef __linux__
	char exe[4096]{};
	const auto n = ::readlink("/proc/self/exe", exe, sizeof exe - 1);
	if (n > 0)
		seeds.emplace_back(std::filesystem::path(std::string(exe, static_cast<std::size_t>(n))).parent_path());
#endif
	for (auto seed : seeds) {
		auto p = std::filesystem::weakly_canonical(seed, ec);
		for (int i = 0; i < 8; ++i) {
			if (std::filesystem::is_regular_file(p / "src" / "main.cpp", ec)
				&& std::filesystem::is_regular_file(p / "actionscript" / "horizon_block.as", ec))
				return p;
			if (!p.has_parent_path() || p.parent_path() == p) break;
			p = p.parent_path();
		}
	}
	return std::filesystem::current_path();
}

bool HaveRepo()
{
	std::error_code ec;
	const auto p = RepoRoot();
	return std::filesystem::is_regular_file(p / "src" / "main.cpp", ec)
		&& std::filesystem::is_regular_file(p / "actionscript" / "horizon_block.as", ec);
}

std::string Slurp(const char* a_path)
{
	auto p = std::filesystem::path(a_path);
	if (p.is_relative())
		p = RepoRoot() / p;
	std::ifstream f(p, std::ios::binary);
	return std::string((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
}

} // namespace

int main()
{
	using namespace hzlog;

	Expect(std::string(HZ_FILE_VERSION_STR) == "0.43.0.4", "file version is 0.43.0.4");
	Expect(HZ_FILE_VERSION_MAJOR == 0 && HZ_FILE_VERSION_MINOR == 43 && HZ_FILE_VERSION_PATCH == 0 && HZ_FILE_VERSION_BUILD == 4, "file version numbers");
	Expect(HZ_COMMS_MSG_LOG == 0, "probe log is off");
	Expect(HZ_HUD_MSG_CAPTURE == 0, "hud capture probe is off");
	ExpectEq(kOpenHint, "F11", "HUD open hint is the F11 key only");

	// ---- save lines excluded ----
	{
		Buffer b;
		Expect(b.Offer(Cap(Kind::Game, "Saving...", 1000)) == OfferResult::SaveSignal, "Saving... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "Autosaving...", 1001)) == OfferResult::SaveSignal, "Autosaving... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "Saving…", 1002)) == OfferResult::SaveSignal, "Saving ellipsis is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$ManualSaveMsg", 1003)) == OfferResult::SaveSignal, "$ManualSaveMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$AutosavingMsg", 1004)) == OfferResult::SaveSignal, "$AutosavingMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$QuickSaveMsg", 1004)) == OfferResult::SaveSignal, "$QuickSaveMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$SavingMsg", 1004)) == OfferResult::SaveSignal, "$SavingMsg is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "Quicksave...", 1004)) == OfferResult::SaveSignal, "Quicksave... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "QuickSave...", 1004)) == OfferResult::SaveSignal, "QuickSave... is a save signal");
		Expect(b.Offer(Cap(Kind::Game, "$SomeOtherKey", 1005)) == OfferResult::Rejected, "$ keys that are not save lines are rejected");
		ExpectEqI(static_cast<int>(b.entries.size()), 0, "save and $ keys never become rows");
		Expect(b.Offer(Cap(Kind::Game, "Saving the colony", 1005)) == OfferResult::Stored, "Saving the colony is not a save line");
		Expect(b.Offer(Cap(Kind::Game, "Saving... the colony", 1005)) == OfferResult::Stored, "Saving... prefix is not a save line");
		Expect(b.Offer(Cap(Kind::Quest, "Saving the colony", 1006)) == OfferResult::Stored, "quest Saving the colony is stored");
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 1007)) == OfferResult::Stored, "an ordinary line is stored");
		ExpectEqI(static_cast<int>(b.entries.size()), 4, "colony lines, prefix, and one ordinary row");
	}

	// ---- Record=0 and type gates ----
	{
		Buffer b;
		b.settings.record = false;
		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 2000)) == OfferResult::Rejected, "Record=0 stores nothing");
		b.settings.record = true;
		b.settings.logTypes = kTypeAll & ~kTypeBusy;
		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 2001)) == OfferResult::Rejected, "Busy off stores nothing");
		Expect(b.Offer(Cap(Kind::Medical, "Contusions cured.", 2002)) == OfferResult::Stored, "other types still store");
		b.settings.modulePresent = false;
		Expect(b.Offer(Cap(Kind::Medical, "Contusions gained.", 2003)) == OfferResult::Rejected, "module off stores nothing");
	}

	// ---- classification including credits ----
	{
		const auto en = hzmsg::English();
		std::string title, tag;
		Expect(ClassifyHud("This individual is busy.", en, title, tag) == Kind::Busy, "busy classifies as busy");
		Expect(ClassifyHud("The owner caught you stealing.", en, title, tag) == Kind::Crime, "caught stealing classifies as crime if it reaches the sink");
		Expect(ClassifyHud("500 credits have been sent home to your parents.", en, title, tag) == Kind::Credits, "Kid Stuff is credits");
		Expect(ClassifyHud("-1890 Credits", en, title, tag) == Kind::Credits, "signed credits use the same matcher");
		Expect(ClassifyHud("Prognosis improved (Contusions)", en, title, tag) == Kind::Medical, "affliction is medical");
		Expect(ClassifyHud("Sarah Morgan considers you a friend.", en, title, tag) == Kind::Crew, "crew line");
		Expect(ClassifyHud("No direct path seen.", en, title, tag) == Kind::Game, "unmatched is game");
		Expect(ClassifyHud("Sam Coe liked that.", en, title, tag) == Kind::Reaction, "liked that is a reaction");
		ExpectEq(title, "Sam Coe", "reaction title is the companion name");
		ExpectEq(tag, "LIKED", "liked tag");
		Expect(ClassifyHud("Andreja loved that.", en, title, tag) == Kind::Reaction, "loved that is a reaction");
		ExpectEq(title, "Andreja", "loved title is the companion name");
		ExpectEq(tag, "LOVED", "loved tag");
		Expect(ClassifyHud("Barrett disliked that.", en, title, tag) == Kind::Reaction, "disliked that is a reaction");
		ExpectEq(tag, "DISLIKED", "disliked tag");
		Expect(ClassifyHud("Sarah Morgan hated that.", en, title, tag) == Kind::Reaction, "hated that is a reaction");
		ExpectEq(tag, "HATED", "hated tag");
	}

	// ---- LOCATION / XP / reaction capture ----
	{
		Buffer b;
		Expect(b.Offer(Cap(Kind::Location, "Akila City", 3'000)) == OfferResult::Stored, "LOCATION row is stored");
		Expect(b.entries.back().kind == Kind::Location, "LOCATION kind");
		Expect(b.Offer(Cap(Kind::Xp, "You gained 50 XP.", 7'000)) == OfferResult::Stored, "XP row is stored");
		Expect(b.entries.back().kind == Kind::Xp, "XP kind");
		auto rx = Cap(Kind::Reaction, "Sam Coe liked that.", 11'000);
		rx.title = "Sam Coe";
		rx.tag = "LIKED";
		Expect(b.Offer(rx) == OfferResult::Stored, "reaction row is stored");
		Expect(b.entries.back().kind == Kind::Reaction, "reaction kind");
		ExpectEq(b.entries.back().title, "Sam Coe", "stored reaction keeps the companion name");
		ExpectEq(b.entries.back().tag, "LIKED", "stored reaction keeps LIKED");
		b.settings.logTypes = kTypeAll & ~kTypeReaction;
		auto rxOff = Cap(Kind::Reaction, "Andreja loved that.", 15'000);
		rxOff.title = "Andreja";
		rxOff.tag = "LOVED";
		Expect(b.Offer(rxOff) == OfferResult::Rejected, "reaction off stores nothing");
		ExpectEqI(static_cast<int>(b.entries.size()), 3, "off reaction does not add a row");

		Kind fk = Kind::Game;
		std::string ft, ftext;
		Expect(ParseForward("location|LOCATION|Akila City", fk, ft, ftext), "movie location line parses");
		Expect(fk == Kind::Location && ftext == "Akila City", "forwarded LOCATION");
		Expect(ParseForward("xp|XP|You gained 50 XP.", fk, ft, ftext), "movie XP line parses");
		Expect(fk == Kind::Xp && ftext == "You gained 50 XP.", "forwarded XP");

		const char* tags[] = {"LIKED", "LOVED", "DISLIKED", "HATED"};
		for (const char* tag : tags) {
			std::string body = "{\"type\":\"horizon.messagelog\",\"version\":1,\"entries\":["
				"{\"id\":1,\"k\":\"crew\",\"t\":\"Sam Coe liked that.\",\"title\":\"Sam Coe\",\"tag\":\"";
			body += tag;
			body += "\"}]}";
			auto old = FromJson(body);
			Expect(old.ok && !old.state.entries.empty(), "old crew reaction file loads");
			Expect(old.state.entries.front().kind == Kind::Reaction, "old crew + reaction tag promotes");
			ExpectEq(old.state.entries.front().tag, tag, "promoted tag is kept");
		}
		auto stay = FromJson(std::string(
			"{\"type\":\"horizon.messagelog\",\"version\":1,\"entries\":["
			"{\"id\":1,\"k\":\"crew\",\"t\":\"Sarah Morgan considers you a friend.\",\"title\":\"Sarah Morgan\",\"tag\":\"FRIEND\"}]}"));
		Expect(stay.ok && stay.state.entries.front().kind == Kind::Crew, "ordinary crew rows stay crew");
	}

	// ---- CALMED lines are never stored ----
	{
		const auto en = hzmsg::English();
		Expect(IsCalmedLine("Andreja is calmed and cannot respond.", en), "named calmed line");
		Expect(IsCalmedLine("The creature is calmed and cannot respond.", en), "creature calmed line");
		Expect(IsCalmedLine("ANDREJA IS CALMED AND CANNOT RESPOND.", en), "named calmed folded");
		hzmsg::Templates loc = en;
		loc.npcCalmed = "est calme et ne peut pas repondre.";
		loc.creature = "La creature est calme et ne peut pas repondre.";
		Expect(IsCalmedLine("Andreja est calme et ne peut pas repondre.", loc), "localized named calmed");
		Expect(IsCalmedLine("La creature est calme et ne peut pas repondre.", loc), "localized creature calmed");
		Expect(IsCalmedLine("Andreja is calmed and cannot respond.", loc), "English fallback when the GMST differs");
		Expect(IsCalmedLine("The creature is calmed and cannot respond.", loc), "English creature fallback");
		Expect(IsCalmedLine("A B C D E F G H I is calmed and cannot respond.", en),
			"calmed skip ignores PlainNameOk");
		Expect(IsCalmedLine("Name <bad> is calmed and cannot respond.", en),
			"calmed skip ignores angle brackets in the name");
		Expect(!IsCalmedLine("Andreja is no longer angry with you.", en), "CALM is not skipped");
		Expect(!IsCalmedLine("Andreja has already caught you.", en), "CAUGHT is not skipped");
		Expect(!IsCalmedLine("This individual is busy.", en), "Busy is not skipped");

		Buffer b;
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 30'000)) == OfferResult::Stored, "real row before calmed");
		ExpectEqI(b.entries.front().n, 1, "seed n is 1");
		const auto before = static_cast<int>(b.entries.size());
		const auto n0 = b.entries.front().n;
		for (int i = 0; i < 5; ++i) {
			const char* line = "Andreja is calmed and cannot respond.";
			Expect(IsCalmedLine(line, en), "calmed five times is still calmed");
			if (!IsCalmedLine(line, en))
				b.Offer(Cap(Kind::Game, line, 30'100 + static_cast<std::uint64_t>(i) * 10));
		}
		ExpectEqI(static_cast<int>(b.entries.size()), before, "five calmed lines create no row");
		ExpectEqI(b.entries.front().n, n0, "a calmed line after a real entry does not change n");
		const std::uint64_t missing = 999999;
		Expect(b.FindId(missing) == nullptr, "no calmed row exists to pin");
		Expect(!b.Pin(missing), "a calmed line cannot be pinned");

		std::string title, tag;
		Expect(ClassifyHud("This individual is busy.", en, title, tag) == Kind::Busy, "busy still classifies");
		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 40'000)) == OfferResult::Stored, "busy still stores");
		auto calm = Cap(Kind::Crew, "Andreja is no longer angry with you.", 41'000);
		calm.tag = "CALM";
		Expect(b.Offer(calm) == OfferResult::Stored, "no longer angry is stored");
		auto caught = Cap(Kind::Game, "Andreja has already caught you.", 42'000);
		caught.tag = "CAUGHT";
		Expect(b.Offer(caught) == OfferResult::Stored, "has already caught you is stored");
	}

	// ---- two launches get distinct session ids ----
	{
		const auto root = TmpRoot();
		Settings s;
		const auto ch = MakeCharacter(0xABCDu, "Sam");
		Log first;
		first.Configure(s, root);
		first.buf.character = ch;
		first.buf.StartSession(100);
		ExpectEqI(first.buf.sess, 1, "first launch session is 1");
		Expect(first.Offer(Cap(Kind::Game, "launch1 a", 50'000)) == OfferResult::Stored, "launch 1 row a");
		Expect(first.Offer(Cap(Kind::Game, "launch1 b", 54'000)) == OfferResult::Stored, "launch 1 row b");
		Expect(first.Offer(Cap(Kind::Game, "launch1 c", 58'000)) == OfferResult::Stored, "launch 1 row c");
		Expect(first.Flush(59'000), "first launch flush");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto body1 = ReadFile(path);
		Expect(body1.find("\"nextSess\"") != std::string::npos, "file writes nextSess");
		auto parsed1 = FromJson(body1);
		Expect(parsed1.ok && parsed1.state.nextSess >= 2, "nextSess is persisted");

		Log second;
		second.Configure(s, root);
		second.buf.character = ch;
		second.LoadCurrent();
		ExpectEqI(second.buf.sess, 2, "second launch session is 2");
		second.buf.StartSession(200);
		Expect(second.Offer(Cap(Kind::Game, "launch2 a", 70'000)) == OfferResult::Stored, "launch 2 row a");
		Expect(second.Offer(Cap(Kind::Game, "launch2 b", 74'000)) == OfferResult::Stored, "launch 2 row b");
		ExpectEqI(second.buf.entries.back().sess, 2, "new rows use session 2");
		Expect(second.Flush(75'000), "second launch flush");

		int n1 = 0, n2 = 0;
		std::set<int> sessIds;
		for (const auto& e : second.buf.entries) {
			sessIds.insert(e.sess);
			if (e.sess == 1) ++n1;
			if (e.sess == 2) ++n2;
		}
		ExpectEqI(n1, 3, "first launch rows survive");
		ExpectEqI(n2, 2, "second launch rows are stored");
		ExpectEqI(static_cast<int>(sessIds.size()), 2, "two launches have two session ids");
		std::set<int> recIds;
		for (const auto& rec : second.buf.sessions)
			recIds.insert(rec.id);
		ExpectEqI(static_cast<int>(recIds.size()), static_cast<int>(second.buf.sessions.size()),
			"sessions list ids are unique");

		second.buf.ClearSession();
		int after1 = 0, after2 = 0;
		for (const auto& e : second.buf.entries) {
			if (e.sess == 1) ++after1;
			if (e.sess == 2) ++after2;
		}
		ExpectEqI(after1, 3, "Clear session leaves the earlier launch");
		ExpectEqI(after2, 0, "Clear session removes only the current launch");

		{
			const auto rootAB = TmpRoot();
			const auto chA = MakeCharacter(0xAAAAu, "Sam");
			const auto chB = MakeCharacter(0xBBBBu, "Barrett");
			FileStore seed(rootAB / "MessageLog");
			LogState stA;
			stA.character = chA;
			stA.nextSess = 3;
			stA.nextId = 3;
			stA.sessions = { Session{1, 1}, Session{2, 2} };
			Entry a1;
			a1.id = 1;
			a1.kind = Kind::Game;
			a1.text = "A launch 1";
			a1.sess = 1;
			a1.ts = 1;
			Entry a2 = a1;
			a2.id = 2;
			a2.text = "A launch 2";
			a2.sess = 2;
			a2.ts = 2;
			stA.entries = { a1, a2 };
			Expect(seed.Save(stA), "seed A at nextSess 3");
			LogState stB;
			stB.character = chB;
			stB.nextSess = 5;
			stB.nextId = 2;
			stB.sessions = { Session{3, 3} };
			Entry b3;
			b3.id = 1;
			b3.kind = Kind::Game;
			b3.text = "B launch-3";
			b3.sess = 3;
			b3.ts = 3;
			stB.entries = { b3 };
			Expect(seed.Save(stB), "seed B with launch-3 rows and nextSess 5");

			Log proc;
			proc.Configure(s, rootAB);
			Expect(proc.OnHudReady(chA, 1.0, 100, 1), "launch on A");
			ExpectEqI(proc.buf.sess, 3, "A takes max(file nextSess, entries, sessions) = 3");
			Expect(proc.Offer(Cap(Kind::Game, "A this launch", 80'000)) == OfferResult::Stored, "A new row");
			ExpectEqI(proc.buf.entries.back().sess, 3, "A new rows use A's launch session");

			Expect(proc.OnHudReady(chB, 2.0, 200, 2), "switch to B");
			ExpectEqI(proc.buf.sess, 5, "B does not inherit A's launch session");
			Expect(proc.Offer(Cap(Kind::Game, "B this launch", 90'000)) == OfferResult::Stored, "B new row");
			ExpectEqI(proc.buf.entries.back().sess, 5, "B new rows use B's launch session");
			int bOld = 0, bNew = 0;
			for (const auto& e : proc.buf.entries) {
				if (e.text == "B launch-3") ++bOld;
				if (e.sess == 5) ++bNew;
			}
			ExpectEqI(bOld, 1, "B loaded its earlier-launch rows");
			ExpectEqI(bNew, 1, "B has this-launch rows");
			proc.buf.ClearSession();
			bool keptOld = false, hasNew = false;
			for (const auto& e : proc.buf.entries) {
				if (e.text == "B launch-3") keptOld = true;
				if (e.sess == 5) hasNew = true;
			}
			Expect(keptOld, "Clear session on B leaves earlier-launch rows");
			Expect(!hasNew, "Clear session on B drops this-launch rows");

			Expect(proc.OnHudReady(chA, 3.0, 300, 3), "switch back to A");
			ExpectEqI(proc.buf.sess, 3, "A launch session survives the switch");
			ExpectEqI(proc.buf.LaunchPinFor(chB.key), 5, "B's pin is still 5 after leaving B");
			std::error_code ecAB;
			std::filesystem::remove_all(rootAB, ecAB);
		}

		const char* oldJson =
			"{\"type\":\"horizon.messagelog\",\"version\":1,\"sessions\":["
			"{\"id\":1,\"startTs\":1},{\"id\":1,\"startTs\":2}],\"entries\":["
			"{\"id\":1,\"k\":\"game\",\"t\":\"old a\",\"sess\":1},"
			"{\"id\":2,\"k\":\"game\",\"t\":\"old b\",\"sess\":1}]}";
		auto old = FromJson(oldJson);
		Expect(old.ok, "old file without nextSess still loads");
		Buffer oldb;
		oldb.LoadState(std::move(old.state));
		ExpectEqI(oldb.sess, 2, "old all-1 file gets a new session id");

		auto view = BuildView(second.buf, 10.0, ViewStatus::Ok);
		{
			const auto packed = PackView(view);
			Expect(packed.find("v1|") == 0, "packed view starts with v1");
			Expect(packed.find('|') != std::string::npos, "packed view is pipe-separated");
			Expect(packed.find('\n') != std::string::npos || view.entries.empty(),
				"packed rows are newline-separated");
		}
		ExpectEqI(view.sess, second.buf.sess, "view session matches");
		ExpectEqI(view.pinCap, kPinCap, "view pin cap");
		ExpectEqI(static_cast<int>(view.entries.size()), static_cast<int>(second.buf.entries.size()),
			"view copies current rows");
		Expect(view.entries.size() <= static_cast<std::size_t>(kViewEntryCap), "view is capped");
		Expect(ClassifyViewStatus(second.buf.settings, second.buf.character, false, false) == ViewStatus::Ok,
			"player-id persist view is ok");
		Character hashCh;
		hashCh.keySource = "nameHash";
		Expect(ClassifyViewStatus(second.buf.settings, hashCh, false, false) == ViewStatus::KeyFallback,
			"name-hash status is the fallback");
		Settings mem = second.buf.settings;
		mem.persist = false;
		Expect(ClassifyViewStatus(mem, second.buf.character, false, false) == ViewStatus::MemoryOnly,
			"Persist off is memory only");
		Expect(ClassifyViewStatus(second.buf.settings, second.buf.character, true, false) == ViewStatus::Saving,
			"pending write is saving");
		Expect(ClassifyViewStatus(second.buf.settings, second.buf.character, false, true) == ViewStatus::Paused,
			"persist hold is paused");
		{
			Buffer capv;
			capv.entries.resize(static_cast<std::size_t>(kViewEntryCap) + 20);
			for (int i = 0; i < kViewEntryCap + 20; ++i) {
				capv.entries[static_cast<std::size_t>(i)].id = static_cast<std::uint64_t>(i + 1);
				capv.entries[static_cast<std::size_t>(i)].text = "x";
			}
			const auto clipped = BuildView(capv, 0, ViewStatus::Ok);
			ExpectEqI(static_cast<int>(clipped.entries.size()), kViewEntryCap, "view drops oldest overflow");
			ExpectEqI(static_cast<int>(clipped.entries.front().id), 21, "view keeps the newest cap rows");
		}
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	// ---- P2 storage fixes the UI exposes ----
	{
		{
			Buffer stamped;
			stamped.lastPlayedTs = 0;
			StampLastPlayed(stamped.lastPlayedTs, 0);
			ExpectEqI(static_cast<int>(stamped.lastPlayedTs), 0, "a 0 stamp is ignored");
			StampLastPlayed(stamped.lastPlayedTs, 1'700'000'123);
			Expect(stamped.lastPlayedTs == 1'700'000'123, "stamp writes epoch seconds");
			const auto snap = stamped.Snapshot();
			Expect(snap.lastPlayedTs == 1'700'000'123, "Snapshot carries the stamped lastPlayedTs");
			StampLastPlayed(stamped.lastPlayedTs, 0);
			Expect(stamped.lastPlayedTs == 1'700'000'123, "a later 0 stamp does not wipe lastPlayedTs");
		}
		Expect(!LastPlayedKnown(726), "legacy uptime lastPlayedTs is unknown");
		Expect(!LastPlayedKnown(999999999), "just below 1e9 is unknown");
		Expect(LastPlayedKnown(1000000000), "epoch seconds are known");
		ExpectEqI(static_cast<int>(LastPlayedDisplay(726, 1720000000)), 1720000000,
			"unknown lastPlayed uses the file mtime");
		ExpectEqI(static_cast<int>(LastPlayedDisplay(1720000001, 1)), 1720000001,
			"known lastPlayed is kept");
		Expect(!WritePendingClears(0, 1), "zero done seq does not clear pending");
		Expect(!WritePendingClears(1, 2), "a stale write does not clear a newer pending");
		Expect(WritePendingClears(3, 3), "matching seq clears pending");
		Expect(!WriteJobStillCurrent(0, 1), "zero job seq is not current");
		Expect(!WriteJobStillCurrent(1, 2), "canceled job is not current");
		Expect(WriteJobStillCurrent(4, 4), "live job is current");

		const auto root = TmpRoot();
		Settings s;
		Log loc;
		loc.Configure(s, root);
		LogState st;
		Entry locRow;
		locRow.id = 1;
		locRow.kind = Kind::Location;
		locRow.text = "Akila City";
		locRow.norm = NormalizeText(locRow.text);
		locRow.ts = 10;
		st.entries.push_back(locRow);
		st.nextId = 2;
		loc.buf.LoadState(st);
		Expect(loc.Offer(Cap(Kind::Location, "Akila City", 80'000)) == OfferResult::Rejected,
			"first LOCATION after load matching the last row is suppressed");
		ExpectEqI(static_cast<int>(loc.buf.entries.size()), 1, "suppressed LOCATION adds no row");
		Expect(loc.Offer(Cap(Kind::Location, "New Atlantis", 84'000)) == OfferResult::Stored,
			"a new LOCATION after load is stored");
		Expect(loc.Offer(Cap(Kind::Xp, "You gained 25 XP.", 88'000)) == OfferResult::Stored, "XP still stores");

		Log nlog;
		nlog.Configure(s, root);
		nlog.buf.character = MakeCharacter(0xABCDu, "Sam");
		nlog.Offer(Cap(Kind::Game, "n seed", 90'000));
		Expect(nlog.Flush(91'000), "flush writes epoch lastPlayedTs");
		Expect(LastPlayedKnown(nlog.buf.lastPlayedTs), "Flush writes epoch seconds");

		Log parkN;
		parkN.Configure(s, root);
		parkN.buf.character = MakeCharacter(0xABCDu, "Sam");
		Entry have;
		have.kind = Kind::Game;
		have.text = "same second";
		have.norm = NormalizeText(have.text);
		have.ts = 500;
		have.n = 2;
		parkN.buf.entries.push_back(have);
		Entry bigger = have;
		bigger.n = 5;
		parkN.ParkWriteFailure("0000ABCD", std::vector<Entry>{bigger});
		parkN.MergeKeptHeldIfMatch("0000ABCD");
		ExpectEqI(parkN.buf.entries.front().n, 5, "exact park keeps the larger n");
		Entry smaller = have;
		smaller.n = 1;
		parkN.ParkWriteFailure("0000ABCD", std::vector<Entry>{smaller});
		parkN.MergeKeptHeldIfMatch("0000ABCD");
		ExpectEqI(parkN.buf.entries.front().n, 5, "exact park does not shrink n");

		Log twoA;
		twoA.Configure(s, root);
		twoA.buf.character = MakeCharacter(0x1111u, "Sam Coe");
		twoA.Offer(Cap(Kind::Game, "sam only", 100'000));
		Expect(twoA.Flush(101'000), "character A flush");
		Log twoB;
		twoB.Configure(s, root);
		twoB.buf.character = MakeCharacter(0x2222u, "Barrett");
		twoB.Offer(Cap(Kind::Credits, "barrett only", 102'000));
		Expect(twoB.Flush(103'000), "character B flush");
		const auto others = ListOtherCharacters(root / "MessageLog", "00001111");
		bool sawCurrent = false, sawB = false;
		std::string bName;
		int bCount = 0;
		std::int64_t bPlayed = 0;
		for (const auto& oc : others) {
			if (oc.key == "00001111") sawCurrent = true;
			if (oc.key == "00002222") {
				sawB = true;
				bName = oc.name;
				bCount = oc.entryCount;
				bPlayed = oc.lastPlayedTs;
			}
		}
		Expect(!sawCurrent, "cleanup list excludes the current key");
		Expect(sawB, "cleanup list has the other character");
		ExpectEq(bName, "Barrett", "cleanup list uses the saved name");
		ExpectEqI(bCount, 1, "cleanup list entry count");
		Expect(bPlayed >= 0, "cleanup list last played");
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_00002222.json"),
			"other character file stays; the list has no hide/erase action");
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_00001111.json"),
			"current file stays");
		Expect(ReadFile(root / "MessageLog" / "MessageLog_00001111.json").find("sam only") != std::string::npos,
			"no cross-bleed between character files");
		Expect(ReadFile(root / "MessageLog" / "MessageLog_00001111.json").find("barrett only") == std::string::npos,
			"other character text is not in the current file");

		Log noName;
		noName.Configure(s, root);
		noName.buf.character = MakeCharacter(0x3333u, "");
		noName.buf.character.names.clear();
		noName.Offer(Cap(Kind::Game, "anon", 104'000));
		Expect(noName.Flush(105'000), "nameless character flush");
		const auto anon = ListOtherCharacters(root / "MessageLog", "00001111");
		bool foundAnon = false;
		for (const auto& oc : anon)
			if (oc.key == "00003333" && oc.name.find("Character ") == 0) foundAnon = true;
		Expect(foundAnon, "missing name uses Character N");

		Log clear;
		clear.Configure(s, root);
		clear.buf.character = MakeCharacter(0xABCDu, "Sam");
		clear.Offer(Cap(Kind::Game, "must go", 110'000));
		Expect(clear.Flush(111'000), "seed before clear");
		const auto clearPath = root / "MessageLog" / "MessageLog_0000ABCD.json";
		Expect(std::filesystem::is_regular_file(clearPath), "file exists before clear");
		auto staleSnap = clear.buf.Snapshot();
		clear.writePending = true;
		const std::uint64_t jobCancel = clear.fileGate.LoadCancel("0000ABCD");
		Expect(clear.ClearHistoryNow(), "Clear history");
		Expect(clear.buf.entries.empty(), "Clear history empties memory");
		Expect(!clear.writePending, "Clear history clears pending");
		Expect(std::filesystem::is_regular_file(clearPath), "Clear history keeps the file");
		Expect(ReadFile(clearPath).find("must go") == std::string::npos, "Clear history empties the file");
		const auto clearBak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		Expect(std::filesystem::is_regular_file(clearBak), "Clear history keeps the bak");
		Expect(ReadFile(clearBak).find("must go") == std::string::npos, "Clear history empties the bak");
		auto parsedClear = FromJson(ReadFile(clearPath));
		Expect(parsedClear.ok && parsedClear.state.nextSess >= 2, "Clear history keeps nextSess");
		const auto staleRun = OrderedSave(clear.fileGate, jobCancel, "0000ABCD", [&] {
			return clear.store->Save(staleSnap);
		});
		Expect(staleRun == WriteRun::Skipped, "Clear history cancels the in-flight write");
		Expect(ReadFile(clearPath).find("must go") == std::string::npos,
			"a stale write cannot put old rows back");
		Expect(ReadFile(clearBak).find("must go") == std::string::npos,
			"a stale write cannot restore old rows through bak");

		Log persistOff;
		Settings off;
		off.persist = false;
		persistOff.Configure(off, root / "no-persist");
		persistOff.buf.character = MakeCharacter(0x5555u, "Sam");
		persistOff.Offer(Cap(Kind::Game, "memory", 114'000));
		Expect(persistOff.Flush(115'000), "Persist=0 flush");
		Expect(!std::filesystem::exists(root / "no-persist" / "MessageLog"),
			"Persist=0 still creates no folder");
		Expect(persistOff.ClearHistoryNow(), "Persist=0 Clear history");
		Expect(persistOff.buf.entries.empty(), "Persist=0 Clear empties memory");
		Expect(!std::filesystem::exists(root / "no-persist" / "MessageLog"),
			"Persist=0 Clear does not create the folder");
		Expect(!std::filesystem::exists(root / "no-persist" / "MessageLog" / "MessageLog_00005555.json"),
			"Persist=0 Clear does not write the main file");
		Expect(!std::filesystem::exists(root / "no-persist" / "MessageLog" / "MessageLog_00005555.json.bak"),
			"Persist=0 Clear does not write the bak");

		Log heavy;
		heavy.Configure(s, root);
		heavy.buf.SetHistorySize(1000);
		heavy.buf.character = MakeCharacter(0x6666u, "Sam");
		for (int i = 0; i < 1000; ++i) {
			std::string t = "quote \"heavy\" line ";
			t += std::to_string(i);
			t += " and more \"text\".";
			heavy.Offer(Cap(Kind::Game, t.c_str(), 200'000 + static_cast<std::uint64_t>(i) * 4000));
		}
		ExpectEqI(heavy.buf.UnpinnedCount(), 1000, "1,000-row log is filled");
		Expect(heavy.Flush(210'000), "1,000-row flush");
		const auto heavyPath = root / "MessageLog" / "MessageLog_00006666.json";
		Expect(!std::filesystem::exists(std::filesystem::path(heavyPath.string() + ".bad")),
			"1,000-row log does not become .bad");
		Log reload;
		reload.Configure(s, root);
		reload.buf.character = MakeCharacter(0x6666u, "Sam");
		reload.LoadCurrent();
		ExpectEqI(static_cast<int>(reload.buf.entries.size()), 1000, "1,000-row log reloads");

		LogState huge;
		huge.character = MakeCharacter(0x7777u, "Sam");
		for (int i = 0; i < 4; ++i) {
			Entry e;
			e.id = static_cast<std::uint64_t>(i + 1);
			e.kind = Kind::Game;
			e.text.assign(900 * 1024, i == 0 ? 'A' : 'B');
			e.ts = i;
			e.pin = i == 3 ? 1 : 0;
			huge.entries.push_back(std::move(e));
		}
		const auto plugin = std::string("HorizonUI ") + HZ_FILE_VERSION_STR;
		Expect(ToJson(huge, plugin).size() > static_cast<std::size_t>(kFileWriteMaxBytes),
			"fixture is over the 3 MiB write cap");
		FileStore fs(root / "MessageLog");
		Expect(fs.Save(huge), "writer saves an oversize snapshot");
		LogState loaded;
		std::string notice;
		Expect(fs.Load("00007777", loaded, notice), "oversize write reloads");
		bool pinKept = false;
		for (const auto& e : loaded.entries)
			if (e.pin) pinKept = true;
		Expect(pinKept, "writer evicts unpinned rows and keeps the pin");
		Expect(ToJson(loaded, plugin).size() <= static_cast<std::size_t>(kFileWriteMaxBytes)
			|| loaded.entries.size() < huge.entries.size(),
			"writer dropped oldest unpinned rows");

		std::error_code ec2;
		std::filesystem::remove_all(root, ec2);
	}

	// ---- dedupe 3 s / Busy 10 s ----
	{
		Buffer b;
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 10'000)) == OfferResult::Stored, "first path line");
		Expect(b.Offer(Cap(Kind::Game, "  NO   direct PATH seen. ", 12'000)) == OfferResult::Deduped, "normalized match inside 3 s");
		ExpectEqI(static_cast<int>(b.entries.size()), 1, "dedupe keeps one row");
		ExpectEqI(b.entries[0].n, 2, "n is 2 after one repeat");
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 14'000)) == OfferResult::Deduped, "still inside 3 s of last");
		ExpectEqI(b.entries[0].n, 3, "window slides from the last occurrence");
		Expect(b.Offer(Cap(Kind::Game, "No direct path seen.", 18'000)) == OfferResult::Stored, "outside 3 s is a new row");
		ExpectEqI(static_cast<int>(b.entries.size()), 2, "new row after the window");

		Buffer edge;
		Expect(edge.Offer(Cap(Kind::Game, "edge", 10'000)) == OfferResult::Stored, "edge first row");
		Expect(edge.Offer(Cap(Kind::Game, "edge", 13'000)) == OfferResult::Deduped, "exact 3000 ms is still inside the window");
		ExpectEqI(static_cast<int>(edge.entries.size()), 1, "exact 3000 ms keeps one row");
		Expect(edge.Offer(Cap(Kind::Game, "edge", 16'001)) == OfferResult::Stored, "3001 ms from last is a new row");
		ExpectEqI(static_cast<int>(edge.entries.size()), 2, "one millisecond past the window is a new row");

		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 20'000)) == OfferResult::Stored, "first busy");
		Expect(b.Offer(Cap(Kind::Busy, "this individual is busy.", 28'000)) == OfferResult::Deduped, "Busy window is 10 s");
		ExpectEqI(b.entries.back().n, 2, "busy n is 2");
		Expect(b.Offer(Cap(Kind::Busy, "This individual is busy.", 39'000)) == OfferResult::Stored, "Busy outside 10 s is new");

		for (int i = 0; i < 20; ++i)
			b.Offer(Cap(Kind::Medical, "Contusions cured.", 40'000 + static_cast<std::uint64_t>(i) * 10));
		Expect(b.entries.back().n <= kRepeatCap, "n never exceeds 999");
	}

	// ---- viewGen bumps on Offer / Pin / Unpin / ClearSession ----
	{
		Buffer b;
		const auto g0 = b.viewGen;
		Expect(b.Offer(Cap(Kind::Game, "view gen row", 10'000)) == OfferResult::Stored, "viewGen offer stores");
		Expect(b.viewGen > g0, "Offer bumps viewGen");
		const auto g1 = b.viewGen;
		Expect(b.Offer(Cap(Kind::Game, "Saving...", 10'100)) == OfferResult::SaveSignal, "viewGen save signal");
		ExpectEqI(static_cast<int>(b.viewGen), static_cast<int>(g1), "a save signal does not bump viewGen");
		const auto id = b.entries.front().id;
		Expect(b.Pin(id), "viewGen pin");
		Expect(b.viewGen > g1, "Pin bumps viewGen");
		const auto g2 = b.viewGen;
		Expect(b.Unpin(id), "viewGen unpin");
		Expect(b.viewGen > g2, "Unpin bumps viewGen");
		const auto g3 = b.viewGen;
		b.ClearSession();
		Expect(b.viewGen > g3, "ClearSession bumps viewGen");
		Expect(b.Offer(Cap(Kind::Game, "view gen row", 10'500)) == OfferResult::Deduped
			|| b.Offer(Cap(Kind::Game, "view gen row two", 20'000)) == OfferResult::Stored,
			"viewGen fixture still stores");
		{
			Buffer d;
			Expect(d.Offer(Cap(Kind::Game, "dedupe gen", 30'000)) == OfferResult::Stored, "dedupe viewGen first");
			const auto gd = d.viewGen;
			Expect(d.Offer(Cap(Kind::Game, "dedupe gen", 31'000)) == OfferResult::Deduped, "dedupe viewGen second");
			Expect(d.viewGen > gd, "Deduped bumps viewGen");
			const auto gh = d.viewGen;
			d.ClearHistory();
			Expect(d.viewGen > gh, "ClearHistory bumps viewGen");
		}
		{
			Buffer s;
			s.character = MakeCharacter(0x11u, "Gen");
			const auto gs = s.viewGen;
			s.StartSession(1'700'000'000);
			Expect(s.viewGen > gs, "StartSession bumps viewGen");
			s.Offer(Cap(Kind::Game, "later row", 40'000, 20.0));
			const auto gp = s.viewGen;
			Expect(s.Prune(10.0) > 0, "Prune flags a later-point row");
			Expect(s.viewGen > gp, "Prune bumps viewGen");
			const auto snap = s.Snapshot();
			Buffer loaded;
			const auto gl = loaded.viewGen;
			loaded.LoadState(snap);
			Expect(loaded.viewGen > gl, "LoadState bumps viewGen");
			const auto gr = loaded.viewGen;
			loaded.ResetMemory();
			Expect(loaded.viewGen > gr, "ResetMemory bumps viewGen");
			Buffer merge;
			merge.Offer(Cap(Kind::Game, "merge base", 50'000));
			const auto gm = merge.viewGen;
			merge.MergeSession(s.Snapshot().entries);
			Expect(merge.viewGen > gm, "MergeSession bumps viewGen");
		}
	}

	// ---- ring buffer and pin cap (500 + 50 on top) ----
	{
		Buffer b;
		b.SetHistorySize(100);
		for (int i = 0; i < 120; ++i) {
			auto c = Cap(Kind::Game, ("line " + std::to_string(i)).c_str(), 100'000 + static_cast<std::uint64_t>(i) * 4000);
			Expect(b.Offer(c) == OfferResult::Stored, "fill ring");
		}
		ExpectEqI(static_cast<int>(b.entries.size()), 100, "unpinned cap is HistorySize");
		ExpectEq(b.entries.front().text, "line 20", "oldest unpinned is evicted");

		const auto firstId = b.entries.front().id;
		Expect(b.Pin(firstId), "pin oldest remaining");
		for (int i = 120; i < 230; ++i) {
			b.Offer(Cap(Kind::Game, ("line " + std::to_string(i)).c_str(), 200'000 + static_cast<std::uint64_t>(i) * 4000));
		}
		bool pinLived = false;
		for (const auto& e : b.entries)
			if (e.id == firstId && e.pin) pinLived = true;
		Expect(pinLived, "eviction never removes a pin");
		Expect(static_cast<int>(b.entries.size()) == 101, "pins sit on top of HistorySize");

		int pinned = 0;
		for (auto& e : b.entries) {
			if (e.pin) continue;
			if (b.Pin(e.id)) ++pinned;
			if (b.PinCount() >= kPinCap) break;
		}
		Expect(pinned > 0, "the pin loop actually pinned rows");
		ExpectEqI(b.PinCount(), kPinCap, "pin cap is 50");
		std::uint64_t extra = 0;
		for (auto& e : b.entries) {
			if (!e.pin) {
				extra = e.id;
				break;
			}
		}
		Expect(extra != 0 && !b.Pin(extra), "a 51st pin is refused");
		ExpectEqI(b.PinCount(), kPinCap, "pin count stays 50 after the refused pin");
	}

	// ---- prune (Decision A 2026-10-27: keep every later-point row) ----
	{
		Buffer b;
		b.Offer(Cap(Kind::Game, "old", 1'000, 10.0));
		b.Offer(Cap(Kind::Game, "mid", 2'000, 20.0));
		b.Offer(Cap(Kind::Game, "future", 3'000, 30.0));
		const auto futureId = b.entries.back().id;
		const auto midId = b.entries[1].id;
		const auto nextBefore = b.nextId;
		Expect(b.Pin(futureId), "pin the future row");
		ExpectEqI(b.Prune(0.0), 0, "gt 0 never prunes");
		ExpectEqI(static_cast<int>(b.entries.size()), 3, "gt 0 keeps every row");
		ExpectEqI(b.Prune(15.0), 2, "later-point rows are flagged, not dropped");
		ExpectEqI(static_cast<int>(b.entries.size()), 3, "Decision A: every later-point row stays");
		Expect(b.nextId == nextBefore, "id counter does not rewind");
		bool midLater = false, futureLater = false;
		for (const auto& e : b.entries) {
			if (e.id == midId && FromLaterPoint(e, 15.0) && e.fromLater && !e.pin) midLater = true;
			if (e.id == futureId && FromLaterPoint(e, 15.0) && e.fromLater && e.pin) futureLater = true;
		}
		Expect(midLater, "unpinned later-point row is flagged fromLater");
		Expect(futureLater, "pinned later-point row is flagged fromLater");

		b.Offer(Cap(Kind::Game, "new after reload", 4'000, 15.0));
		ExpectEqI(static_cast<int>(b.entries.size()), 4, "a new capture after reload keeps later rows");
		bool stillMid = false, stillFuture = false;
		for (const auto& e : b.entries) {
			if (e.id == midId && e.fromLater) stillMid = true;
			if (e.id == futureId && e.fromLater) stillFuture = true;
		}
		Expect(stillMid && stillFuture, "later-point flags survive a new capture");
		Expect(b.nextId > futureId, "new rows take ids after the later-point rows");

		const auto json = ToJson(b.Snapshot(), "HorizonUI 0.43.0.4");
		auto parsed = FromJson(json);
		Expect(parsed.ok, "later-point flags round-trip through JSON");
		Buffer restarted;
		restarted.LoadState(std::move(parsed.state));
		bool restartMid = false, restartFuture = false;
		for (const auto& e : restarted.entries) {
			if (e.id == midId && e.fromLater) restartMid = true;
			if (e.id == futureId && e.fromLater) restartFuture = true;
		}
		Expect(restartMid && restartFuture, "a restart keeps fromLater flags");
		const auto view = BuildView(restarted, 15.0, ViewStatus::Ok);
		int viewLater = 0;
		for (const auto& row : view.entries)
			if (row.fromLater) ++viewLater;
		Expect(viewLater >= 2, "the view dims later-point rows after a restart");

		Buffer cap;
		cap.SetHistorySize(100);
		for (int i = 0; i < 120; ++i) {
			auto c = Cap(Kind::Game, "cap row", 10'000 + i, 40.0);
			c.text += std::to_string(i);
			cap.Offer(c);
		}
		ExpectEqI(static_cast<int>(cap.entries.size()), 100, "history-size cap still evicts during offer");
		Expect(cap.Pin(cap.entries.front().id), "pin the oldest remaining row");
		const auto pinId = cap.entries.front().id;
		for (int i = 0; i < 10; ++i) {
			auto c = Cap(Kind::Game, "more cap", 20'000 + i, 41.0);
			c.text += std::to_string(i);
			cap.Offer(c);
		}
		ExpectEqI(static_cast<int>(cap.entries.size()), 101, "pins sit on top of HistorySize after later-point rows");
		bool pinLived = false;
		for (const auto& e : cap.entries)
			if (e.id == pinId && e.pin) pinLived = true;
		Expect(pinLived, "cap eviction never removes a pin");
		const int flagged = cap.Prune(1.0);
		Expect(flagged > 0, "later-point rows are flagged after the cap");
		ExpectEqI(static_cast<int>(cap.entries.size()), 101, "flagging later-point rows does not evict");
	}

	// ---- persisted nextId (empty file and LoadState) ----
	{
		LogState held;
		held.nextId = 42;
		held.character = MakeCharacter(0x60C0u, "Sam");
		Buffer loaded;
		loaded.LoadState(held);
		ExpectEqI(static_cast<int>(loaded.nextId), 42, "LoadState keeps the persisted nextId");
		const auto json = ToJson(loaded.Snapshot(), "HorizonUI 0.43.0.4");
		Expect(json.find("\"nextId\": 42") != std::string::npos, "ToJson writes nextId");
		auto parsed = FromJson(json);
		Expect(parsed.ok && parsed.state.nextId == 42, "FromJson reads the persisted nextId");
		Buffer again;
		again.LoadState(std::move(parsed.state));
		ExpectEqI(static_cast<int>(again.nextId), 42, "a restart keeps nextId when the file has no rows");
		again.Offer(Cap(Kind::Game, "after empty persist", 8'000));
		ExpectEqI(static_cast<int>(again.entries.back().id), 42, "the next row uses the persisted counter");
	}

	// ---- Clear session that empties the buffer must persist empty ----
	{
		const auto root = TmpRoot();
		Settings s;
		const auto ch = MakeCharacter(0x60C1u, "Sam");
		Log first;
		first.Configure(s, root);
		first.buf.character = ch;
		first.buf.StartSession(100);
		Expect(first.Offer(Cap(Kind::Game, "only this launch a", 10'000)) == OfferResult::Stored,
			"seed this-launch row a");
		Expect(first.Offer(Cap(Kind::Game, "only this launch b", 11'000)) == OfferResult::Stored,
			"seed this-launch row b");
		Expect(first.Flush(12'000), "seed this-launch rows on disk");
		ExpectEqI(static_cast<int>(first.buf.entries.size()), 2, "two this-launch rows");
		const auto nextBefore = first.buf.nextId;
		first.buf.ClearSession();
		Expect(first.buf.entries.empty(), "Clear session emptied the buffer");
		Expect(first.buf.nextId == nextBefore, "Clear session does not rewind nextId");
		MsglogWriteCoordinator coord;
		auto d = coord.OnClear(ch.key, first.buf.Snapshot());
		Expect(d.queue && d.emit.emptyClear, "emptied Clear session is an explicit Clear");
		FileStore fs(root / "MessageLog");
		Expect(ApplyDiskWrite(fs, d.emit.snap, d.emit.persist, d.emit.emptyClear, d.emit.clearFirst),
			"emptied Clear session writes empty main and bak");
		Log restart;
		restart.Configure(s, root);
		restart.buf.character = ch;
		restart.LoadCurrent();
		Expect(restart.buf.entries.empty(), "restart after emptied Clear session has no rows");
		Expect(restart.buf.nextId == nextBefore, "restart keeps nextId after emptied Clear session");
		Log reload;
		reload.Configure(s, root);
		reload.buf.character = ch;
		reload.LoadCurrent();
		Expect(reload.buf.entries.empty(), "reload after emptied Clear session has no rows");
		Expect(!ShouldQueueWrite(false, true, false, ch.key, ch.key),
			"an automatic empty snapshot is still not a write");
		std::error_code ecClear;
		std::filesystem::remove_all(root, ecClear);
	}

	// ---- per-character switch / NG+ ----
	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.replace = DefaultReplace;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xD6B6EAFA, "Sam");
		log.Offer(Cap(Kind::Game, "sam line", 5'000, 5.0));
		Expect(log.Flush(5'000), "flush character A");
		const auto aFile = root / "MessageLog" / "MessageLog_D6B6EAFA.json";
		Expect(std::filesystem::is_regular_file(aFile), "character A file exists");

		const auto ng = MakeCharacter(0xAABBCCDD, "Sam");
		Expect(log.OnHudReady(ng, 1.0, 6, 6'000), "NG+ key change switches");
		ExpectEqI(static_cast<int>(log.buf.entries.size()), 0, "NG+ starts a new empty log");
		ExpectEq(log.buf.character.key, "AABBCCDD", "new key is the new player id");
		log.Offer(Cap(Kind::Game, "ng line", 7'000, 2.0));
		log.Flush(7'000);
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_AABBCCDD.json"), "NG+ wrote its own file");
		Expect(ReadFile(aFile).find("sam line") != std::string::npos, "old character file is unchanged");

		const auto back = MakeCharacter(0xD6B6EAFA, "Sam");
		Expect(log.OnHudReady(back, 5.0, 8, 8'000), "switch back to A");
		bool found = false;
		for (const auto& e : log.buf.entries)
			if (e.text == "sam line") found = true;
		Expect(found, "loading A does not mix B's rows");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	// ---- Persist=0 writes nothing ----
	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		s.persist = false;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(1, "Sam");
		log.Offer(Cap(Kind::Game, "memory only", 9'000));
		Expect(log.Flush(9'000), "Persist=0 flush is a no-op success");
		Expect(!std::filesystem::exists(root / "MessageLog"), "Persist=0 never creates the folder");
		Expect(!log.FolderExists(), "store reports no folder");
		Expect(!log.store->TouchesDisk(), "null backend does not touch disk");

		// Switching 1 -> 0 stops writes and does not delete.
		Log on;
		Settings s1;
		on.Configure(s1, root);
		on.buf.character = MakeCharacter(1, "Sam");
		on.Offer(Cap(Kind::Game, "on disk", 10'000));
		on.Flush(10'000);
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_00000001.json"), "Persist=1 wrote");
		on.ApplyPersist(false);
		on.Offer(Cap(Kind::Game, "after off", 11'000));
		on.Flush(11'000);
		Expect(ReadFile(root / "MessageLog" / "MessageLog_00000001.json").find("after off") == std::string::npos,
			"Persist 1->0 does not write the new row");
		Expect(ReadFile(root / "MessageLog" / "MessageLog_00000001.json").find("on disk") != std::string::npos,
			"INI Persist=0 leaves the existing file");
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_00000001.json"),
			"Persist-off does not erase the file");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	// ---- JSON round trip, corrupt, oversized, too-new ----
	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Renamed");
		log.buf.RememberName("Second Name");
		log.Offer(Cap(Kind::Quest, "Talk to Daniel Blake", 12'000, 213.1, "Akila City"));
		log.buf.entries.back().title = "JOB GONE WRONG";
		log.Flush(12'000);
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto body = ReadFile(path);
		Expect(body.find("horizon.messagelog") != std::string::npos, "type token");
		Expect(body.find("Talk to Daniel Blake") != std::string::npos, "text survived");
		auto parsed = FromJson(body);
		Expect(parsed.ok && !parsed.corrupt, "round trip parses");
		ExpectEqI(static_cast<int>(parsed.state.entries.size()), 1, "one entry round trips");
		ExpectEq(parsed.state.character.names.back(), "Second Name", "names are stored for the cleanup list");

		WriteFile(path, "{not json");
		std::error_code ecBak;
		std::filesystem::remove(root / "MessageLog" / "MessageLog_0000ABCD.json.bak", ecBak);
		LogState st;
		std::string notice;
		FileStore fs(root / "MessageLog");
		fs.Load("0000ABCD", st, notice);
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_0000ABCD.json.bad"), "corrupt file is renamed .bad");
		Expect(st.entries.empty(), "corrupt without bak starts empty");

		const auto good = ToJson(parsed.state, "HorizonUI 0.43.0.1");
		WriteFile(path, good);
		fs.Save(parsed.state);
		WriteFile(path, std::string("{\"type\":\"horizon.messagelog\",\"version\":99,\"entries\":[]}"));
		st = {};
		fs.Load("0000ABCD", st, notice);
		Expect(notice.find("too new") != std::string::npos || st.entries.empty() || parsed.state.entries.size() == st.entries.size(),
			"too-new file is not trusted as-is");

		std::string huge(static_cast<std::size_t>(kFileMaxBytes) + 8, 'x');
		auto big = FromJson(huge);
		Expect(big.corrupt, "oversized file is corrupt");

		auto skip = FromJson(std::string("{\"type\":\"horizon.messagelog\",\"version\":1,\"entries\":[{\"id\":1},{\"id\":2,\"k\":\"game\",\"t\":\"ok\"}]}"));
		Expect(skip.ok, "malformed entries do not fail the file");
		ExpectEqI(static_cast<int>(skip.state.entries.size()), 1, "only the good entry loads");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	// ---- popup stack closes every layer ----
	{
		PopStack st;
		Expect(st.Push("f11"), "push f11");
		Expect(st.Push("log"), "push log");
		Expect(st.Push("logset"), "push settings");
		Expect(st.Push("confirm"), "push confirm");
		ExpectEqI(st.Size(), 4, "four layers");
		ExpectEq(st.Pop(), "confirm", "ESC/B closes one layer");
		ExpectEqI(st.Size(), 3, "three remain after one pop");
		ExpectEqI(st.CloseAll(), 3, "forced close closes every remaining layer");
		Expect(st.Empty(), "stack is empty after close-all");
		ExpectEqI(st.CloseAll(), 0, "close-all on empty is safe");
	}

	// ---- wiring contracts that used to freeze F11 ----
	if (!HaveRepo()) {
		std::cerr << "SKIP: source-pin fixture checks (repo not found from this cwd; "
			"set MSGLOG_REPO_ROOT or rebuild with -DMSGLOG_REPO_ROOT)\n";
	} else {
		const auto main = Slurp("src/main.cpp");
		const auto as = Slurp("actionscript/horizon_block.as");
		const auto hzc = Slurp("actionscript/comms/hzc_block.as");
		Expect(as.find("function hzSettingsCloseAll") != std::string::npos, "AS3 has hzSettingsCloseAll");
		Expect(main.find("hzSettingsCloseAll") != std::string::npos, "DLL forced close calls hzSettingsCloseAll");
		Expect(main.find("for (int i = 0; i < 2; ++i)") == std::string::npos, "forced close no longer toggles at most twice");
		Expect(main.find("attempt < 2") != std::string::npos && main.find("hzToggleSettings") != std::string::npos,
			"close-all falls back to the old toggle loop");
		Expect(main.find("VK_OEM_2") != std::string::npos && main.find("ch:/") != std::string::npos, "slash reaches F11 for Find");
		Expect(main.find("USER_EVENT_FLAG::Looking | RE::USER_EVENT_FLAG::Fighting") != std::string::npos, "only Looking+Fighting stay blocked");
		Expect(main.find("XInputGetState") != std::string::npos, "pad path exists for in-menu navigation");
		Expect(main.find("LoadLibraryW(L\"xinput1_4.dll\")") != std::string::npos
			&& main.find("xinput9_1_0.dll") != std::string::npos, "XInput is loaded dynamically");
		Expect(main.find("pragma comment(lib, \"xinput.lib\")") == std::string::npos, "XInput is not a static import");
		Expect(main.find("\"padx\"") != std::string::npos && main.find("\"pady\"") != std::string::npos, "pad X/Y are actions");
		Expect(main.find("ch:s") == std::string::npos && main.find("ch:y") == std::string::npos, "pad X/Y do not type s or y");
		Expect(main.find("HzMlEngineFillSEH") != std::string::npos && main.find("HzAddrSlot") != std::string::npos,
			"engine reads use HzAddrSlot plus SEH");
		Expect(main.find("AddrSlotReady") != std::string::npos,
			"later slot lookups require the loaded address image");
		Expect(main.find("EngineZeroMiss") != std::string::npos,
			"a zero engine id names the published address id");
		Expect(main.find("engine address id {} missing") != std::string::npos,
			"the engine warning names the id that failed");
		Expect(main.find("persist skipped; character key is still a name hash") != std::string::npos,
			"a name-hash write skip is logged");
		Expect(main.find("MsglogShutdownWriter();") != std::string::npos,
			"quit to desktop queues a last flush");
		{
			const auto prep = main.find("void HzMsgPrepare()");
			const auto prepEnd = main.find("static std::string HzCrossName()", prep);
			const auto body = prep != std::string::npos && prepEnd > prep ? main.substr(prep, prepEnd - prep) : std::string();
			Expect(body.find("g_addrBytes.clear();") == std::string::npos,
				"prepare does not free the address image");
		}
		Expect(main.find("try { Poll(); }") != std::string::npos, "the task lambda swallows exceptions");
		Expect(main.find("void PollScaleform()") != std::string::npos, "Scaleform has its own UI-thread poll");
		Expect(main.find("OnMenuMovie") != std::string::npos && main.find("InstallAdvanceHook") != std::string::npos,
			"MenuMovieCreated hooks HUD AdvanceFrame");
		Expect(main.find("thread: load tid=") != std::string::npos
			&& main.find("thread: ui poll tid=") != std::string::npos
			&& main.find("thread: job poll tid=") != std::string::npos,
			"startup, first UI poll, and first job poll log the thread id");
		Expect(main.find("RecordUiTidOnce") != std::string::npos
			&& main.find("compare_exchange_strong(expected, a_tid") != std::string::npos
			&& main.find("source=hud-root-advance") != std::string::npos
			&& main.find("AdoptHudAdvanceTid") != std::string::npos,
			"the UI tid is recorded once from the HUD root advance");
		Expect(main.find("g_uiTid.store(::GetCurrentThreadId()") == std::string::npos,
			"the hook does not overwrite the UI tid on every advance");
		{
			const auto om = main.find("void OnMenuMovie");
			const auto next = main.find("void OnMessage", om);
			const auto body = om != std::string::npos && next > om ? main.substr(om, next - om) : std::string();
			Expect(body.find("RecordUiTidOnce") == std::string::npos
				&& body.find("g_hudRoot.store") != std::string::npos
				&& body.find("g_hudMsgRoot.store") != std::string::npos
				&& body.find("hint only") != std::string::npos,
				"OnMenuMovie stores the HUD root and does not adopt the tid");
		}
		{
			const auto hook = main.find("void HookedAdvanceFrame");
			const auto next = main.find("void InstallAdvanceHook", hook);
			const auto body = hook != std::string::npos && next > hook ? main.substr(hook, next - hook) : std::string();
			Expect(body.find("HookTidAllowsPoll(ui, tid)") != std::string::npos,
				"the hook compares the recorded tid to this advance");
			Expect(body.find("AdoptHudAdvanceTid(tid)") != std::string::npos
				&& body.find("IsStoredHudRoot") != std::string::npos,
				"the hook adopts only the stored HUD root's tid");
		}
		{
			const auto inst = main.find("void InstallAdvanceHook");
			const auto next = main.find("void OnMenuMovie", inst);
			const auto body = inst != std::string::npos && next > inst ? main.substr(inst, next - inst) : std::string();
			Expect(body.find("g_origAdvance.store(orig") != std::string::npos
				&& body.find("HookOrigStored") != std::string::npos,
				"the hook stores the original AdvanceFrame pointer");
		}
		Expect(main.find("skip PollScaleform") != std::string::npos
			&& main.find("AdvanceFrame on other thread") != std::string::npos,
			"the hook skips PollScaleform on a non-UI tid");
		Expect(main.find("scaleform: hook alive") != std::string::npos
			&& main.find("kHookAliveFirstN") != std::string::npos,
			"the hook logs an alive counter");
		Expect(main.find("AdvanceFrame orig=") != std::string::npos
			&& main.find("rva=0x") != std::string::npos,
			"the hook logs the original AdvanceFrame address");
		Expect(main.find("MenuMovieCreated name=") != std::string::npos
			&& main.find("live root") != std::string::npos,
			"MenuMovieCreated logs a live root");
		Expect(main.find("REX::ERROR(\"scaleform: AdvanceFrame hook failed\")") != std::string::npos,
			"a failed AdvanceFrame patch logs at ERROR");
		Expect(main.find("orig == &HookedAdvanceFrame") != std::string::npos
			&& main.find("g_advanceHooked.exchange(true)") != std::string::npos
			&& main.find("HookOnceFlagBlocksRetry") != std::string::npos,
			"the hook has a once-flag and a self-recursion guard");
		Expect(main.find("thread_local bool inPoll") != std::string::npos,
			"PollScaleform has a reentrancy guard");
		Expect(main.find("g_mlWStartMu") != std::string::npos
			&& main.find("lock_guard start(g_mlWStartMu)") != std::string::npos,
			"EnsureWriter starts the writer under one mutex");
		Expect(main.find("g_phraseMu") != std::string::npos
			&& main.find("MsgPhrasesSnap") != std::string::npos,
			"the phrase table is published under a lock");
		{
			const auto prep = main.find("void HzMsgPrepare()");
			const auto prepEnd = main.find("static std::string HzCrossName()", prep);
			const auto body = prep != std::string::npos && prepEnd > prep ? main.substr(prep, prepEnd - prep) : std::string();
			Expect(body.find("lock_guard lk(g_phraseMu)") != std::string::npos
				&& body.find("g_msgPhrases = std::move(next)") != std::string::npos,
				"HzMsgPrepare publishes phrases under g_phraseMu");
		}
		{
			const auto offer = main.find("void MsglogOfferNote");
			const auto take = main.find("void MsglogTakeMovie");
			const auto body = offer != std::string::npos && take > offer ? main.substr(offer, take - offer) : std::string();
			Expect(body.find("MsgPhrasesSnap()") != std::string::npos, "OfferNote snapshots phrases under the lock");
			const auto lock = body.find("lock_guard lk(g_mlMu)");
			const auto flush = body.find("ShouldFlush");
			const auto save = body.find("SaveSignal");
			Expect(lock != std::string::npos && flush != std::string::npos && save != std::string::npos
				&& lock < flush && flush < save,
				"ShouldFlush runs under g_mlMu");
		}
		Expect(main.find("FilesJobPreload") != std::string::npos
			&& main.find("PreloadDllFileVersion") != std::string::npos,
			"versionlib and the DLL file version preload on the job thread");
		Expect(main.find("g_mlEngMu") != std::string::npos
			&& main.find("std::mutex") != std::string::npos,
			"the engine cache has a mutex");
		{
			int engLocks = 0;
			for (std::size_t p = 0; (p = main.find("lock_guard lk(g_mlEngMu)", p)) != std::string::npos; ++p)
				++engLocks;
			Expect(engLocks >= 2, "engine cache reads and writes take g_mlEngMu");
		}
		{
			const auto promo = main.find("void MsglogPromoteId()");
			const auto next = main.find("void MsglogQueueRecover", promo);
			const auto body = promo != std::string::npos && next > promo ? main.substr(promo, next - promo) : std::string();
			Expect(body.find("PromoteIdShouldQueue") != std::string::npos
				&& body.find("g_mlRecoverBusy") != std::string::npos
				&& body.find("lock_guard lk(g_mlMu)") != std::string::npos,
				"PromoteId checks recoverBusy inside the lock");
		}
		{
			const auto rx = main.find("void CommsRxPoll(ULONGLONG a_now)");
			const auto rxEnd = main.find("#if HZ_COMMS_MSG_LOG", rx);
			const auto body = rx != std::string::npos && rxEnd > rx ? main.substr(rx, rxEnd - rx) : std::string();
			Expect(body.find("FaderMenu") != std::string::npos
				&& body.find("MsglogTakeMovieAllowed") != std::string::npos,
				"CommsRx skips Fader through MsglogTakeMovieAllowed");
		}
		{
			const auto dbg = main.find("void CommsDbgPoll(ULONGLONG a_now)");
			const auto dbgEnd = main.find("#else", dbg);
			const auto body = dbg != std::string::npos && dbgEnd > dbg ? main.substr(dbg, dbgEnd - dbg) : std::string();
			Expect(body.find("FaderMenu") != std::string::npos
				&& body.find("MsglogTakeMovieAllowed") != std::string::npos,
				"CommsDbg skips Fader through MsglogTakeMovieAllowed");
		}
		Expect(main.find("HzNoteScaleformThread") != std::string::npos
			&& main.find("#ifndef NDEBUG") != std::string::npos,
			"off-UI Scaleform check is debug-only");
		Expect(main.find("MenuLive") != std::string::npos && main.find("MenuMovie") != std::string::npos,
			"each Scaleform call re-fetches the menu");
		Expect(main.find("kTakeLogMinMs") != std::string::npos
			&& main.find("MsglogTakeMovieAllowed") != std::string::npos,
			"hzcTakeLog is gated and rate-limited");
		{
			const auto poll = main.find("void Poll()");
			const auto next = main.find("void PollScaleform()", poll);
			const auto body = poll != std::string::npos && next > poll ? main.substr(poll, next - poll) : std::string();
			Expect(body.find("GetMenu") == std::string::npos && body.find("menuObj") == std::string::npos
				&& body.find("HudInvoke") == std::string::npos && body.find("HudSafe") == std::string::npos
				&& body.find("MsglogTakeMovie") == std::string::npos && body.find("BannerPoll(") == std::string::npos,
				"job-thread Poll never touches Scaleform");
			Expect(body.find("BannerPollWork") != std::string::npos && body.find("FilesPollWork") != std::string::npos
				&& body.find("MsglogPoll") != std::string::npos,
				"job-thread Poll keeps capture, files, and the writer");
			Expect(body.find("RecordUiTidOnce") == std::string::npos
				&& body.find("TryRecordUiTidFromWindow") == std::string::npos
				&& body.find("HintWindowOwnerTid") != std::string::npos,
				"job-thread Poll only hints the window-owner tid");
		}
		{
			const auto ui = main.find("void PollScaleform()");
			const auto next = main.find("using AdvanceFn", ui);
			const auto body = ui != std::string::npos && next > ui ? main.substr(ui, next - ui) : std::string();
			Expect(body.find("BannerPoll(now)") != std::string::npos && body.find("CommsRxPoll(now)") != std::string::npos
				&& body.find("ScopeClipPoll(now)") != std::string::npos && body.find("MsglogTakeMovie") != std::string::npos
				&& body.find("MsglogPollUi") != std::string::npos && body.find("HudSafe") != std::string::npos
				&& body.find("OnSettingsKey") != std::string::npos && body.find("PollSettings") != std::string::npos
				&& body.find("MsglogRefreshEngine") != std::string::npos,
				"UI poll owns banners, cards, F11, the log take, and engine reads");
			Expect(body.find("SaveFromHud") == std::string::npos && body.find("DoAction") == std::string::npos
				&& body.find("filesystem::exists") == std::string::npos
				&& body.find("HzAddrLoad") == std::string::npos
				&& body.find("ReadOwnFileVersion") == std::string::npos,
				"UI poll does no file I/O");
		}
		{
			const auto slot = main.find("static int HzAddrSlot");
			const auto next = main.find("static void HzAddrLogOnce", slot);
			const auto body = slot != std::string::npos && next > slot ? main.substr(slot, next - slot) : std::string();
			Expect(body.find("HzAddrLoad") == std::string::npos,
				"HzAddrSlot only reads the cached address image");
			Expect(body.find("kSlotPending") != std::string::npos
				&& body.find("AddrImagePending") != std::string::npos,
				"HzAddrSlot returns pending before the preload");
		}
		Expect(main.find("g_addrWhyMu") != std::string::npos
			&& main.find("void AddrWhySet") != std::string::npos
			&& main.find("AddrWhyGet") != std::string::npos,
			"g_addrWhy is a locked string");
		{
			const auto log = main.find("void LogAdvanceTid");
			const auto next = main.find("void HookedAdvanceFrame", log);
			const auto body = log != std::string::npos && next > log ? main.substr(log, next - log) : std::string();
			Expect(body.find("thread_local bool seen") != std::string::npos
				&& body.find("g_advTidMu") == std::string::npos
				&& body.find("g_advTids") != std::string::npos,
				"LogAdvanceTid is lock-free on the hot path");
		}
		{
			const auto ver = main.find("const std::string& DllFileVersion()");
			const auto next = main.find("void PushDllFileVersion", ver);
			const auto body = ver != std::string::npos && next > ver ? main.substr(ver, next - ver) : std::string();
			Expect(body.find("ReadOwnFileVersion") == std::string::npos,
				"DllFileVersion on the UI path does not open the version resource");
		}
		Expect(main.find("GetMenuInterface") != std::string::npos
			&& main.find("AddPermanentTask") != std::string::npos,
			"MenuInterface registers the UI hook; TaskInterface still runs Poll");
		{
			const auto script = RepoRoot() / "tools" / "callgraph_scaleform.py";
			Expect(std::filesystem::is_regular_file(script), "Scaleform call-graph script is in the repo");
			const auto cmd = std::string("python3 \"") + script.string() + "\"";
			Expect(std::system(cmd.c_str()) == 0,
				"callgraph: no Scaleform from Poll() and no file I/O on the UI path");
		}
		{
			const auto shut = main.find("void MsglogShutdownWriter()");
			const auto next = main.find("void MsglogQueueLoad", shut);
			const auto body = shut != std::string::npos && next > shut ? main.substr(shut, next - shut) : std::string();
			Expect(body.find("MsglogRequestWrite(true") != std::string::npos,
				"shutdown queues a last write");
			Expect(body.find("g_mlWStop") == std::string::npos,
				"Y14 shutdown does not stop the worker");
		}
		Expect(main.find("if (g_mlWThread.joinable())") != std::string::npos
			&& main.find("if (!g_mlWDone.load()) return;") != std::string::npos,
			"EnsureWriter joins only a finished worker before rebind");
		Expect(main.find("hzlog::JoinOrDetach") == std::string::npos,
			"shutdown does not join on the game thread");
		Expect(main.find("AtExitShouldJoin") != std::string::npos && main.find("g_mlWThread.detach()") != std::string::npos,
			"atexit joins only when done, otherwise detaches");
		Expect(main.find("g_mlHadSession.exchange(false)") != std::string::npos, "quit flush is edge-triggered");
		Expect(main.find("WriterStartAllowed") != std::string::npos, "detached writer blocks a second thread");
		Expect(main.find("ApplyRecoveredFile") != std::string::npos && main.find("HoldRetryDue") != std::string::npos,
			"DLL promotion merges on the worker and is throttled");
		Expect(main.find("NoteWorkerSave") != std::string::npos,
			"the worker records save failure");
		Expect(main.find("g_mlWFailed") == std::string::npos
			&& main.find("g_mlWRecovered") == std::string::npos
			&& main.find("g_mlWRetryAt") == std::string::npos,
			"unused worker fail/retry globals are gone");
		Expect(main.find("g_mlWrites.OnWriteResult") != std::string::npos, "write results go to the coordinator");
		Expect(main.find("NoteWriteFailure") != std::string::npos, "a failed write is retried");
		Expect(main.find("WriteAllowed") != std::string::npos, "force can retry a write");
		Expect(main.find("std::atomic<bool>       g_mlWStarted{false}") != std::string::npos
			&& main.find("g_mlWStarted.store(false)") != std::string::npos
			&& main.find("g_mlWLive.store(false)") != std::string::npos,
			"g_mlWStarted is atomic and the outer catch re-enables a later start");
		Expect(main.find("hzlog::NoteLoadResult(false, g_ml.persistHold);") != std::string::npos,
			"ApplyLoad holds persist after a transient read");
		{
			const auto rec = main.find("g_mlWrites.OnWriteResult");
			Expect(rec != std::string::npos, "Poll drains write results into the coordinator");
			const auto win = rec == std::string::npos ? std::string() : main.substr(rec, 900);
			Expect(win.find("NoteWriteSuccess") != std::string::npos,
				"a successful write resets the write backoff");
			Expect(win.find("WriteRecoveredResetsBackoff") != std::string::npos,
				"a hold does not reset the write backoff");
			Expect(win.find("g_mlWrites.Poll") != std::string::npos
				|| main.find("g_mlWrites.Poll") != std::string::npos,
				"retries use the coordinator's per-key backoff");
		}
		Expect(main.find("++g_mlLoadGen") != std::string::npos && main.find("LoadApplyStale") != std::string::npos,
			"worker reads are tagged with the load generation");
		{
			int gens = 0;
			for (std::size_t p = 0; (p = main.find("job.gen = g_mlLoadGen", p)) != std::string::npos; ++p)
				++gens;
			ExpectEqI(gens, 2, "load and save jobs each carry the load generation");
		}
		Expect(main.find("job.bufKey = g_ml.buf.character.key") != std::string::npos,
			"each load job is tagged with the buffer key at queue time");
		Expect(main.find("CopyLoadJobTag") != std::string::npos, "the worker copies the load-generation tag");
		Expect(main.find("LoadApplyStale(jobGen, g_mlLoadGen, jobBufKey, g_ml.buf.character.key)") != std::string::npos,
			"ApplyLoad compares the queued buffer key, not the result key");
		Expect(main.find("LoadResultKeyMismatch") == std::string::npos,
			"ApplyLoad does not compare the promotion target key");
		Expect(main.find("ShouldClearRecoverBusy(jobGen, g_mlInFlightGen)") != std::string::npos,
			"a stale result does not clear busy for a queued flush");
		Expect(main.find("ApplyReopensCapture") != std::string::npos, "hold-flush apply keeps capture closed");
		{
			int parks = 0;
			for (std::size_t p = 0; (p = main.find("MsglogParkHeldIfNeeded();", p)) != std::string::npos; ++p)
				++parks;
			ExpectEqI(parks, 2, "both HUD-ready resets park held rows");
			int clears = 0;
			const auto hud = main.find("void MsglogOnHudReady()");
			const auto apply = main.find("void MsglogApplyLoad()");
			const auto hudBody = hud != std::string::npos && apply > hud ? main.substr(hud, apply - hud) : std::string();
			for (std::size_t p = 0; (p = hudBody.find("g_mlHoldFlush = false;", p)) != std::string::npos; ++p)
				++clears;
			ExpectEqI(clears, 2, "both HUD-ready resets clear the hold-flush flag");
			int clearsHold = 0;
			const char* holdClear = "g_mlHoldFlush = false;\n\t\t\t\t\tg_ml.NoteRetrySuccess();";
			for (std::size_t p = 0; (p = hudBody.find(holdClear, p)) != std::string::npos; ++p)
				++clearsHold;
			ExpectEqI(clearsHold, 2, "both HUD-ready resets clear persistHold and holdTargetKey");
		}
		Expect(main.find("ParkHeldRows") != std::string::npos && main.find("keeping {} held rows") != std::string::npos,
			"unrecovered held rows are logged and parked");
		Expect(main.find("ShouldParkDirtyRows") != std::string::npos,
			"HUD-ready parks dirty unsaved rows before ResetMemory");
		Expect(main.find("PendingCountsAsDirty") != std::string::npos,
			"HUD-ready treats a pending save as dirty");
		Expect(main.find("g_mlWrites.RequestWrite") != std::string::npos,
			"RequestWrite asks the coordinator");
		Expect(main.find("g_ml.loadBusy.store(true)") == std::string::npos
			&& main.find("g_ml.loadBusy.store(false)") == std::string::npos,
			"loadBusy is mirrored from the coordinator only");
		Expect(main.find("OnBufferEmptied") == std::string::npos,
			"a prune does not queue a Clear");
		Expect(main.find("AssignEmitFlags") != std::string::npos,
			"PushDecision copies emit flags through AssignEmitFlags");
		Expect(main.find("g_mlWrites.OnRow") != std::string::npos,
			"Offer reports OnRow to the coordinator");
		Expect(main.find("g_mlWrites.OnLoadStart") != std::string::npos,
			"loads start through the coordinator");
		Expect(main.find("g_ml.writePending = g_mlWrites.AnyWritePending()") != std::string::npos,
			"writePending is mirrored from the coordinator");
		Expect(main.find("g_mlWrites.Poll") != std::string::npos,
			"Poll retries through the coordinator");
		Expect(main.find("WriteFailParksJob") != std::string::npos,
			"a failed save for another key parks that job");
		Expect(main.find("ParkWriteFailure(r.key") != std::string::npos
			|| main.find("ParkWriteFailure(failKey") != std::string::npos,
			"a failed save parks under the job key, not the current key");
		Expect(main.find("g_mlWFailGen") == std::string::npos,
			"unused write-fail generation is gone");
		{
			const auto hdr = Slurp("src/hz_msglog.h");
			const auto sameAt = hdr.find("inline bool SameParkedRow");
			const auto nextAt = hdr.find("inline bool HasSameParkedRow");
			const auto sameFn = sameAt != std::string::npos && nextAt > sameAt
				? hdr.substr(sameAt, nextAt - sameAt) : std::string();
			Expect(sameFn.find(".id") == std::string::npos, "SameParkedRow does not match on id");
			Expect(sameFn.find("kind") != std::string::npos && sameFn.find(".ts") != std::string::npos,
				"SameParkedRow matches kind and timestamp");
			Expect(sameFn.find("NormalizeText") != std::string::npos,
				"SameParkedRow matches normalized text");
		}
		Expect(main.find("MergeKeptHeldIfMatch") != std::string::npos, "parked rows merge when that character loads");
		Expect(Slurp("src/hz_msglog.h").find("MergeKeptKeyOk") != std::string::npos,
			"parked rows merge only when the character key matches");
		Expect(main.find("g_ml.holdTargetKey = ch.key") != std::string::npos,
			"a failed name-hash promote records the player-id target");
		Expect(main.find("g_mlInFlightGen = job.gen") != std::string::npos,
			"the in-flight generation is recorded when a load is queued");
		Expect(Slurp("src/hz_msglog.h").find("RekeyKeptHeld") == std::string::npos,
			"RekeyKeptHeld is gone");
		Expect(main.find("NoteRetryFailure") != std::string::npos, "retries use exponential backoff");
		Expect(main.find("MsglogQueueRecover") != std::string::npos, "held rows retry on the worker");
		Expect(as.find("padx") != std::string::npos && as.find("pady") != std::string::npos, "AS3 treats padx/pady as actions");
		Expect(main.find("OnSettingsKey") != std::string::npos && main.find("g_vk") != std::string::npos, "F11 still opens from the keyboard");
		Expect(as.find("hzMsglogOpenHint") != std::string::npos && as.find("return \"F11\"") != std::string::npos,
			"HUD open hint is the F11 key");
		Expect(as.find("notifications") != std::string::npos, "F11 probes the Notifications marker");
		Expect(as.find("MESSAGE LOG") != std::string::npos, "F11 has a MESSAGE LOG row");
		Expect(as.find("needs Notifications") != std::string::npos, "the row is gated on the Notifications marker");
		Expect(as.find("HORIZON UI · MESSAGE LOG") != std::string::npos, "the log shell title is present");
		Expect(as.find("HZ_ML_W") != std::string::npos && as.find("860") != std::string::npos,
			"the log popup is 860 wide");
		Expect(as.find("HZ_ML_H") != std::string::npos && as.find("620") != std::string::npos,
			"the log popup is 620 tall");
		Expect(as.find("HZ_ML_VIS") != std::string::npos && as.find("HZ_ML_ROW") != std::string::npos,
			"the log shows about 10 rows at 28 px");
		Expect(as.find("Starts empty") != std::string::npos, "the empty log has a starts-empty note");
		Expect(as.find("from a later point") != std::string::npos, "later-point rows are labeled");
		Expect(as.find("Clear this session?") != std::string::npos, "Clear session asks for a confirm");
		Expect(as.find("REACTIONS") != std::string::npos && as.find("ALL TIME") != std::string::npos,
			"type chips and All time are drawn");
		Expect(as.find("Find (keyboard only)") != std::string::npos, "Find shows a keyboard-only note on a pad");
		Expect(as.find("function hzMsglogNeed") != std::string::npos && as.find("function hzSetMsglogView") != std::string::npos,
			"the movie exposes the view poll pair");
		Expect(as.find("HZ_BUILD:String = \"0.43.0.4\"") != std::string::npos, "HUD movie build id is 0.43.0.4");
		Expect(as.find("F12") == std::string::npos || as.find("SETTINGS MENU KEY") != std::string::npos,
			"no new F key is added for the log");
		Expect(main.find("void MsglogPollUi()") != std::string::npos, "DLL pushes the view while the log is open");
		Expect(main.find("void MsglogClearSession()") != std::string::npos, "DLL Clear session");
		Expect(main.find("void MsglogTogglePin(") != std::string::npos, "DLL pin toggle");
		Expect(Slurp("src/hz_msglog.h").find("PackView") != std::string::npos, "the view is packed for the movie");
		{
			const auto clr = main.find("void MsglogClearSession()");
			const auto next = main.find("void MsglogTogglePin(", clr);
			const auto body = clr != std::string::npos && next > clr ? main.substr(clr, next - clr) : std::string();
			Expect(body.find("OnClear") != std::string::npos, "emptied Clear session uses OnClear");
			Expect(body.find("entries.empty()") != std::string::npos, "Clear session checks whether the buffer emptied");
			Expect(body.find("StampLastPlayed") != std::string::npos, "emptied Clear stamps lastPlayed");
			Expect(body.find("ClearSessionWrites") != std::string::npos
				&& body.find("persistHold") != std::string::npos,
				"emptied Clear respects persistHold");
			Expect(body.find("MsglogRequestWrite(true)") != std::string::npos,
				"Clear session still rewrites when earlier rows remain");
		}
		{
			const auto poll = main.find("void MsglogPollUi()");
			const auto next = main.find("void MsglogOfferNote", poll);
			const auto body = poll != std::string::npos && next > poll ? main.substr(poll, next - poll) : std::string();
			Expect(body.find("viewGen") != std::string::npos, "PollUi reads the buffer generation");
			Expect(body.find("g_mlUiPacked && !acted && gen == g_mlUiPackGen") != std::string::npos,
				"PollUi skips a pack when the generation is unchanged");
			Expect(body.find("g_mlUiPacked = true") != std::string::npos
				&& body.find("g_mlUiPackGen = gen") != std::string::npos,
				"PollUi stores the packed generation");
			Expect(body.find("acted = true") != std::string::npos, "an act forces a pack");
			Expect(body.find("g_mlUiPacked = false") != std::string::npos, "closing the log resets the pack flag");
		}
		Expect(main.find("pruneEmpty") == std::string::npos
			&& main.find("PruneEmptiedBuffer") == std::string::npos,
			"dead pruneEmpty wiring is gone from the DLL");
		Expect(as.find("this.hzMlAct = \"\"") != std::string::npos, "ForceClose clears a pending action");
		{
			const auto fc = as.find("function hzMsglogForceClose");
			const auto next = as.find("function hzMsglogEnsure", fc);
			const auto body = fc != std::string::npos && next > fc ? as.substr(fc, next - fc) : std::string();
			Expect(body.find("this.hzMlAct = \"\"") != std::string::npos,
				"ForceClose clears hzMlAct so nothing runs the next open");
		}
		Expect(as.find("hzMsglogChipKeepVisible") != std::string::npos
			&& as.find("strip.mask = clip") != std::string::npos,
			"the chip row scrolls sideways and clips to the popup");
		{
			const auto chip = as.find("function hzMsglogChipKeepVisible");
			const auto next = as.find("function hzMsglogKindIcon", chip);
			const auto body = chip != std::string::npos && next > chip ? as.substr(chip, next - chip) : std::string();
			Expect(body.find("if(activeLeft < this.hzMlChipX)") != std::string::npos
				&& body.find("if(activeLeft + activeW > this.hzMlChipX + chipInner)") != std::string::npos
				&& body.find("if(this.hzMlChipX > maxX)") != std::string::npos
				&& body.find("if(this.hzMlChipX < 0)") != std::string::npos,
				"chip keep-visible scrolls and clamps the strip");
		}
		Expect(as.find("hzMsglogKindIcon") != std::string::npos, "rows draw a type icon");
		Expect(as.find("minPx:int = 0) : Number") != std::string::npos, "hzSetKey and hzSetBtn accept minPx");
		Expect(as.find("if(minPx > sz) { sz = minPx; }") != std::string::npos,
			"hzWT applies the minPx floor");
		Expect(as.find("hzSetKey(b,g,ox + 22,fy + 4,\"/\",uint(T.mut),24,13,13)") != std::string::npos,
			"the Find keycap passes minPx 13");
		Expect(as.find("hzSetBtn(b,g,bxr,by,\"BACK\",false,false,this.hzMlHover == \"back\",T,\"mlback\",13,13)") != std::string::npos,
			"log buttons pass minPx 13");
		Expect(as.find("hzSetBtn(b,g,br,cy + 120,\"CLEAR\",true,false,this.hzMlHover == \"cfok\",T,\"cfok\",13,13)") != std::string::npos,
			"the confirm CLEAR button passes minPx 13");
		ExpectEqI(TextScaleFloorPx(13, 13), 13, "TextScale 0.90 on a 13 px face stays 13");
		ExpectEqI(TextScaleFloorPx(13, 0), 12, "without minPx, TextScale 0.90 drops 13 to 12");
		Expect(as.find("this.hzMsglogChipKeepVisible(chipW, chipInner, actL, actW)") != std::string::npos,
			"the chip row calls keep-visible");
		{
			const auto ini = Slurp("Interface/HorizonUI/HorizonUI.default.ini");
			Expect(ini.find("offers to delete") == std::string::npos, "Persist comment does not offer a delete");
			Expect(ini.find("only stops writing") != std::string::npos, "Persist off only stops writing");
			Expect(ini.find("settings popup") == std::string::npos
				&& ini.find("settings folder") == std::string::npos,
				"Persist comment does not mention a settings popup");
		}
		Expect(hzc.find("function hzcTakeLog") != std::string::npos, "movie exposes hzcTakeLog");
		Expect(hzc.find("function hzcTakeLog") != std::string::npos && hzc.find("HUDMessageData stays with the DLL sink") != std::string::npos,
			"take-log is separate from HUDMessageData");
		Expect(hzc.find("this.hzcLogQ.slice(0, n)") != std::string::npos
			&& hzc.find("this.hzcLogQ.slice(n)") != std::string::npos,
			"take-log keeps the remainder instead of dropping the oldest");
		Expect(hzc.find("length >= 500") != std::string::npos && hzc.find("hzcLogDropped") != std::string::npos,
			"take-log bounds the queue at 500 and counts drops");
		{
			const auto copy = Slurp("actionscript/imp/imp/scripts/HUDMessagesMenu.as");
			const auto lrg = Slurp("actionscript/imp/imp-Lrg/scripts/HUDMessagesMenu.as");
			Expect(copy.find("this.hzcLogQ.slice(0, n)") != std::string::npos
				&& copy.find("length >= 500") != std::string::npos,
				"the shipped HUDMessages take-log keeps remainder and the 500 cap");
			Expect(lrg.find("this.hzcLogQ.slice(0, n)") != std::string::npos
				&& lrg.find("length >= 500") != std::string::npos,
				"the large HUDMessages take-log keeps remainder and the 500 cap");
		}
		Expect(hzc.find("hzcLogPush") != std::string::npos && hzc.find("QuestUpdateData") != std::string::npos, "quests are forwarded");
		Expect(hzc.find("HUDLocationData") != std::string::npos && hzc.find("XPData") != std::string::npos, "location and XP are forwarded");
		Expect(main.find("kMsglogOpenWithPad") == std::string::npos, "no pad combo opens F11");
		{
			const auto offer = main.find("void MsglogOfferNote");
			const auto take = main.find("void MsglogTakeMovie");
			const auto body = offer != std::string::npos && take > offer ? main.substr(offer, take - offer) : std::string();
			const auto skipAt = body.find("IsCalmedLine");
			const auto offerAt = body.find("g_ml.Offer");
			Expect(skipAt != std::string::npos && offerAt != std::string::npos && skipAt < offerAt,
				"calmed lines are skipped before Offer and before dedupe");
		}
		{
			const auto copy = main.find("hzlog::ViewSnap MsglogCopyView");
			Expect(copy != std::string::npos, "DLL exposes the view snapshot getter");
			const auto next = main.find("void MsglogQueueListRefresh", copy);
			const auto body = copy != std::string::npos && next > copy ? main.substr(copy, next - copy) : std::string();
			Expect(body.find("g_mlMu") != std::string::npos, "the getter takes the buffer lock");
			Expect(body.find("FileStore") == std::string::npos && body.find("Load(") == std::string::npos
				&& body.find("Save(") == std::string::npos,
				"the getter never blocks the game thread on disk");
			Expect(body.find("BuildView") != std::string::npos, "the getter copies a capped view");
		}
		Expect(main.find("OrderedSave") != std::string::npos,
			"the writer skips a canceled in-flight save");
		Expect(Slurp("src/hz_msglog.h").find("WriteIsCanceled") != std::string::npos,
			"canceled writes are keyed so the leaving snapshot is kept");
		Expect(Slurp("src/hz_msglog.h").find("WritePendingClears") != std::string::npos,
			"writePending is scoped by the job write sequence");
		Expect(main.find("GetTickCount64() / 1000") == std::string::npos,
			"lastPlayedTs is not PC uptime");
		Expect(main.find("std::time(nullptr)") != std::string::npos,
			"lastPlayedTs writes epoch seconds");
		Expect(main.find("rows from a later point") != std::string::npos,
			"HUD-ready logs the later-point flag count");
		Expect(Slurp("src/hz_msglog.h").find("Decision A") != std::string::npos
			&& Slurp("src/hz_msglog.h").find("must not drop any rows") != std::string::npos,
			"Prune comments match Decision A");
		{
			const auto stale = main.find("const bool stale = hzlog::LoadApplyStale");
			Expect(stale != std::string::npos, "ApplyLoad detects a stale load result");
			const auto win = stale == std::string::npos ? std::string() : main.substr(stale, 500);
			Expect(win.find("OnLoadApplied") != std::string::npos && win.find("jobGen") != std::string::npos,
				"a stale load result still releases loadBusy for that gen");
		}
		Expect(main.find("void MsglogClearHistory()") != std::string::npos, "DLL Clear history");
		Expect(main.find("MsglogDeleteCurrentFileUi") == std::string::npos, "no DLL erase-current-file call");
		Expect(main.find("MsglogListOthers()") != std::string::npos, "DLL list other characters");
		Expect(main.find("MsglogDeleteSelected") == std::string::npos, "no DLL erase-selected call");
		Expect(main.find("std::string MsglogFolderPath()") != std::string::npos, "DLL folder path getter");
		{
			const auto get = main.find("std::string MsglogFolderPath()");
			const auto next = main.find("void MsglogOfferNote", get);
			const auto body = get != std::string::npos && next > get ? main.substr(get, next - get) : std::string();
			Expect(body.find("FolderPathDisplay") != std::string::npos, "folder path is a display string");
			Expect(body.find("create_directories") == std::string::npos, "folder path getter does not create the folder");
			Expect(body.find("ofstream") == std::string::npos && body.find("FileStore") == std::string::npos,
				"folder path getter does not open or change files");
		}
	}

	// ---- settings parse ----
	{
		Expect(ClampHistory(50) == 100, "history floors at 100");
		Expect(ClampHistory(1000) == 1000, "history caps at 1000");
		Expect(ClampHistory(550) == 500, "history steps of 100");
		const auto bits = ParseLogTypes("medical,crew,reaction,busy,crime,credits,quest,location,xp,game");
		Expect(bits == kTypeAll, "default type list is every type");
		ExpectEqI(static_cast<int>(kTypeAll), 0x3FF, "kTypeAll includes the reaction bit");
		Expect((ParseLogTypes("busy") & kTypeBusy) != 0, "Busy is a real type");
		const auto noRx = ParseLogTypes("medical,crew,busy,crime,credits,quest,location,xp,game");
		Expect((noRx & kTypeReaction) == 0, "a user INI that lacks reaction keeps it off");
		Expect((noRx & kTypeCrew) != 0, "that INI still has crew");
		ExpectEq(LogTypesText(kTypeAll),
			"medical,crew,reaction,busy,crime,credits,quest,location,xp,game",
			"LogTypesText puts reaction after crew");
		if (HaveRepo()) {
			const auto ini = Slurp("Interface/HorizonUI/HorizonUI.default.ini");
			Expect(ini.find("LogTypes=medical,crew,reaction,busy,crime,credits,quest,location,xp,game") != std::string::npos,
				"default.ini LogTypes includes reaction after crew");
			const auto readme = Slurp("README.md");
			Expect(readme.find("settings popup") == std::string::npos
				&& readme.find("settings folder") == std::string::npos,
				"README does not mention a settings popup");
		}
	}

	// ---- character key fallback ----
	{
		const auto id = MakeCharacter(0, "Sam Coe");
		Expect(id.keySource == "nameHash" && id.key.find("-n") != std::string::npos, "zero player id uses the name-hash fallback");
		Expect(!PersistAllowed(id), "name-hash is memory-only until a real player id");
		const auto keep = MakeCharacter(0x11, "Old");
		Expect(keep.key == "00000011" && keep.keySource == "playerId", "rename keeps the player-id key");
		Expect(PersistAllowed(keep), "a real player id may persist");
		const auto wide = MakeCharacter(0x1E82D83B2ull, "Robert");
		ExpectEq(wide.key, "00000001E82D83B2", "player id over 32 bits uses 16 hex digits");
		Expect(PersistAllowed(wide), "a 16-hex player id may persist");
		std::uint64_t last = 0;
		Expect(NoteNameHashSkip(id, 1'000, last), "first name-hash skip is logged");
		Expect(!NoteNameHashSkip(id, 2'000, last), "name-hash skip is rate-limited");
		Expect(NoteNameHashSkip(id, 1'000 + static_cast<std::uint64_t>(kNameHashSkipLogMs), last),
			"name-hash skip logs again after the gap");
		Expect(!NoteNameHashSkip(keep, 20'000, last), "a player-id key is not a name-hash skip");
		{
			std::vector<unsigned char> img(96 + 63413ull * 4u, 0);
			const std::uint32_t fmt = 5;
			std::memcpy(img.data(), &fmt, 4);
			const std::int32_t count = 63413;
			std::memcpy(img.data() + 92, &count, 4);
			const std::uint32_t off = 0x100;
			std::memcpy(img.data() + 96 + 63412ull * 4u, &off, 4);
			Expect(hzaddr::V5Slot(img.data(), img.size(), 63412ull) == 1,
				"address lookup works before prepare-free");
			img.clear();
			img.shrink_to_fit();
			Expect(hzaddr::V5Slot(img.data(), img.size(), 63412ull) == -1,
				"a freed address image fails a later slot lookup");
			Expect(!hzaddr::AddrSlotReady(1, img.size()),
				"state 1 with a freed buffer fails a later lookup");
		}
	}

	// ---- crash-safety: depth, 4 MiB pre-read, pins, bak, type, writer join ----
	{
		std::string deep = "{\"type\":\"horizon.messagelog\",\"version\":1,\"x\":";
		for (int i = 0; i < 40; ++i) deep += '[';
		for (int i = 0; i < 40; ++i) deep += ']';
		deep += "}";
		auto nest = FromJson(deep);
		Expect(nest.corrupt, "deep nesting is corrupt");
		ExpectEqI(static_cast<int>(kJsonMaxDepth), 32, "JSON skip depth cap is 32");
	}

	{
		const auto root = TmpRoot();
		const auto path = root / "MessageLog" / "MessageLog_0000BIG1.json";
		WriteFile(path, std::string(static_cast<std::size_t>(kFileMaxBytes) + 8, 'x'));
		auto rd = ReadLogFile(path);
		Expect(rd.tooLarge && rd.body.empty(), "4 MiB is rejected before the file is read");
		ExpectEq(rd.notice, "file too large", "oversize notice");
		LogState st;
		std::string notice;
		FileStore fs(root / "MessageLog");
		fs.Load("0000BIG1", st, notice);
		Expect(st.entries.empty(), "oversize load starts empty");
		Expect(notice.find("too large") != std::string::npos, "oversize load reports too large");
		Expect(std::filesystem::is_regular_file(root / "MessageLog" / "MessageLog_0000BIG1.json.bad"),
			"oversize file is renamed .bad");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		LogState st;
		st.cap = 100;
		for (int i = 0; i < 60; ++i) {
			Entry e;
			e.id = static_cast<std::uint64_t>(i + 1);
			e.kind = Kind::Game;
			e.text = "pin " + std::to_string(i);
			e.pin = 1;
			st.entries.push_back(std::move(e));
		}
		Buffer b;
		b.LoadState(st);
		ExpectEqI(b.PinCount(), kPinCap, "load demotes pins above 50");
		Expect(static_cast<int>(b.entries.size()) <= b.Cap() + kPinCap, "load respects HistorySize plus 50 pins");
	}

	{
		std::string many = "{\"type\":\"horizon.messagelog\",\"version\":1,\"entries\":[";
		for (int i = 0; i < 1100; ++i) {
			if (i) many += ',';
			many += "{\"id\":";
			many += std::to_string(i + 1);
			many += ",\"k\":\"game\",\"t\":\"e";
			many += std::to_string(i);
			many += "\"}";
		}
		many += "]}";
		auto capped = FromJson(many);
		Expect(capped.ok, "a large valid file still parses");
		Expect(static_cast<int>(capped.state.entries.size()) <= kLoadEntryCap, "FromJson caps at HistorySize plus 50 pins");
	}

	{
		auto wrong = FromJson(std::string("{\"type\":\"not-a-log\",\"version\":1,\"entries\":[]}"));
		Expect(wrong.corrupt, "wrong type is corrupt");
		Expect(wrong.notice.find("wrong") != std::string::npos, "wrong type notice");
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "first line", 20'000));
		Expect(log.Flush(20'000), "first flush");
		log.Offer(Cap(Kind::Game, "second line", 40'000));
		Expect(log.Flush(40'000), "second flush writes bak");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		Expect(std::filesystem::is_regular_file(bak), "Save writes a .bak");
		Expect(ReadFile(bak).find("first line") != std::string::npos, ".bak keeps the previous file");
		WriteFile(path, "{not json");
		LogState st;
		std::string notice;
		FileStore fs(root / "MessageLog");
		fs.Load("0000ABCD", st, notice);
		bool recovered = false;
		for (const auto& e : st.entries)
			if (e.text == "first line" || e.text == "second line") recovered = true;
		Expect(recovered, "corrupt file recovers from .bak");
		Expect(notice.find("bak") != std::string::npos || recovered, "bak recovery notice");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0, "Sam Coe");
		log.Offer(Cap(Kind::Game, "new character", 21'000));
		Expect(log.Flush(21'000), "name-hash flush is a memory-only success");
		Expect(!std::filesystem::exists(root / "MessageLog"), "name-hash never creates a shared file");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		FileRead rd;
		rd.ok = false;
		rd.notice = "open failed";
		Expect(!ShouldQuarantine(rd, false), "a transient read error is not .bad");
		rd.tooLarge = true;
		Expect(ShouldQuarantine(rd, false), "oversize is .bad");
		rd.tooLarge = false;
		Expect(ShouldQuarantine(rd, true), "parse failure is .bad");
	}

	{
		const auto root = TmpRoot();
		Settings s;
		s.historySize = 100;
		Log disk;
		disk.Configure(s, root);
		disk.buf.character = MakeCharacter(0xABCDu, "Sam");
		disk.Offer(Cap(Kind::Game, "disk old", 10'000, 10.0, "New Atlantis"));
		disk.Offer(Cap(Kind::Game, "disk shared", 14'000, 11.0, "Akila City"));
		disk.Offer(Cap(Kind::Game, "near shared", 16'000, 11.0, "Akila City"));
		for (int i = 0; i < 50; ++i) {
			disk.Offer(Cap(Kind::Game, ("disk pin " + std::to_string(i)).c_str(),
				20'000 + static_cast<std::uint64_t>(i) * 4000, 12.0));
			disk.buf.Pin(disk.buf.entries.back().id);
		}
		Expect(disk.Flush(40'000), "seed the existing id file");

		Log live;
		live.Configure(s, root);
		live.buf.character = MakeCharacter(0, "Sam");
		live.Offer(Cap(Kind::Game, "session new", 50'000, 13.0, "Cydonia"));
		live.Offer(Cap(Kind::Game, "disk shared", 50'100, 13.0, "Cydonia"));
		live.Offer(Cap(Kind::Game, "near shared", 18'000, 11.2, "Akila City"));
		live.Offer(Cap(Kind::Medical, "session medical", 51'000, 13.0));
		auto sessPin = Cap(Kind::Crew, "session pin", 52'000, 13.0);
		live.Offer(sessPin);
		const auto sessPinId = live.buf.entries.back().id;
		Expect(live.buf.Pin(sessPinId), "session pin before promote");
		for (int i = 0; i < 3; ++i) {
			live.Offer(Cap(Kind::Game, ("extra pin " + std::to_string(i)).c_str(), 53'000 + static_cast<std::uint64_t>(i) * 4000, 13.0));
			live.buf.Pin(live.buf.entries.back().id);
		}
		Expect(!PersistAllowed(live.buf.character), "session is still name-hash");
		Expect(live.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam")), "promote merges the existing file");
		ExpectEq(live.buf.character.key, "0000ABCD", "promotion uses the player id");
		Expect(live.buf.character.keySource == "playerId", "promotion keySource is playerId");

		int oldN = 0, sharedCount = 0, sessionN = 0, medicalN = 0, nearN = 0, nearCount = 0;
		int filePins = 0, sessionPins = 0;
		std::set<std::uint64_t> ids;
		std::int64_t lastTs = -1;
		bool sorted = true;
		for (const auto& e : live.buf.entries) {
			if (!ids.insert(e.id).second)
				Expect(false, "merge IDs are unique");
			if (lastTs >= 0 && e.ts < lastTs) sorted = false;
			lastTs = e.ts;
			if (e.text == "disk old") ++oldN;
			if (e.text == "disk shared") ++sharedCount;
			if (e.text == "session new") ++sessionN;
			if (e.text == "session medical") ++medicalN;
			if (e.text == "near shared") { ++nearCount; nearN = e.n; }
			if (e.pin && e.text.rfind("disk pin ", 0) == 0) ++filePins;
			if (e.pin && (e.text == "session pin" || e.text.rfind("extra pin ", 0) == 0)) ++sessionPins;
		}
		ExpectEqI(oldN, 1, "promotion keeps the existing file history");
		ExpectEqI(sessionN, 1, "promotion keeps the in-memory session");
		ExpectEqI(medicalN, 1, "promotion keeps other session kinds");
		ExpectEqI(sharedCount, 2, "rows more than 3 s apart are not folded");
		ExpectEqI(nearCount, 1, "rows inside 3 s fold");
		Expect(nearN >= 2, "in-window fold increments n");
		Expect(sorted, "merge sorts by time");
		ExpectEqI(static_cast<int>(ids.size()), static_cast<int>(live.buf.entries.size()), "every merge id is unique");
		ExpectEqI(live.buf.PinCount(), kPinCap, "merge pin cap is 50 and file pins win");
		ExpectEqI(filePins, kPinCap, "all 50 pins after merge are the file pins");
		ExpectEqI(sessionPins, 0, "session pins beyond 50 are dropped");
		Expect(live.buf.UnpinnedCount() <= live.buf.Cap(), "promotion respects HistorySize");
		bool sessionPinKept = false;
		for (const auto& e : live.buf.entries)
			if (e.text == "session pin") sessionPinKept = true;
		Expect(sessionPinKept, "session pin text is kept as an unpinned row");

		Log hud;
		hud.Configure(s, root);
		hud.buf.character = MakeCharacter(0, "Sam");
		hud.Offer(Cap(Kind::Game, "hud session", 60'000, 14.0));
		Expect(hud.OnHudReady(MakeCharacter(0xABCDu, "Sam"), 14.0, 9, 9'000), "HUD-ready promotion merges");
		bool hudKept = false, diskKept = false;
		for (const auto& e : hud.buf.entries) {
			if (e.text == "hud session") hudKept = true;
			if (e.text == "disk old") diskKept = true;
		}
		Expect(hudKept && diskKept, "HUD-ready migrate keeps both file and session rows");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		Buffer b;
		b.SetHistorySize(100);
		LogState file;
		file.cap = 100;
		for (int i = 0; i < 100; ++i) {
			Entry e;
			e.id = static_cast<std::uint64_t>(i + 1);
			e.kind = Kind::Game;
			e.text = "old " + std::to_string(i);
			e.ts = i;
			e.gt = static_cast<double>(i);
			file.entries.push_back(std::move(e));
		}
		b.LoadState(file);
		std::vector<Entry> sess;
		for (int i = 0; i < 20; ++i) {
			Entry e;
			e.id = static_cast<std::uint64_t>(i + 1);
			e.kind = Kind::Game;
			e.text = "new " + std::to_string(i);
			e.ts = 1000 + i;
			e.gt = 100.0;
			sess.push_back(std::move(e));
		}
		b.MergeSession(sess);
		ExpectEqI(b.UnpinnedCount(), 100, "merge evicts down to HistorySize");
		bool oldestDropped = true, newestKept = false;
		for (const auto& e : b.entries) {
			if (e.text == "old 0") oldestDropped = false;
			if (e.text == "new 19") newestKept = true;
		}
		Expect(oldestDropped && newestKept, "merge evicts the oldest unpinned rows");
	}

	{
		Buffer b;
		LogState file;
		Entry fe;
		fe.id = 1;
		fe.kind = Kind::Game;
		fe.text = "file row";
		fe.ts = 20;
		file.entries.push_back(fe);
		b.LoadState(file);
		Entry se;
		se.id = 1;
		se.kind = Kind::Crew;
		se.text = "session pin";
		se.ts = 5;
		se.pin = 1;
		b.MergeSession({se});
		ExpectEqI(static_cast<int>(b.entries.size()), 2, "merge keeps both rows");
		Expect(b.entries.front().text == "session pin" && b.entries.front().ts == 5, "earlier session row sorts first");
		Expect(b.entries.front().id != 1 || b.entries.back().id != b.entries.front().id, "appended row is re-ided");
		Expect(b.entries.front().pin == 1, "session pin is carried onto the new id");
		Expect(b.FindId(b.entries.front().id) == &b.entries.front(), "FindId hits the re-ided pin");
		Expect(b.FindId(1) == &b.entries.back() || b.entries.back().id == 1, "file id 1 still finds the file row");
	}

	{
		Buffer b;
		LogState file;
		Entry fe;
		fe.id = 1;
		fe.kind = Kind::Game;
		fe.text = "fold pin";
		fe.norm = NormalizeText("fold pin");
		fe.ts = 100;
		file.entries.push_back(fe);
		b.LoadState(file);
		Entry se;
		se.id = 1;
		se.kind = Kind::Game;
		se.text = "fold pin";
		se.norm = fe.norm;
		se.ts = 103;
		se.pin = 1;
		b.MergeSession({se});
		ExpectEqI(static_cast<int>(b.entries.size()), 1, "exact 3000 ms folds");
		Expect(b.entries.front().pin == 1, "folded row carries the session pin");
		Expect(b.entries.front().n >= 2, "in-window fold increments n");
		Entry late;
		late.kind = Kind::Game;
		late.text = "fold pin";
		late.norm = fe.norm;
		late.ts = 104;
		late.id = 9;
		Buffer b2;
		b2.LoadState(file);
		b2.MergeSession({late});
		ExpectEqI(static_cast<int>(b2.entries.size()), 2, "3001 ms does not fold");
	}

	{
		Buffer b;
		LogState file;
		Entry fe;
		fe.id = 1;
		fe.kind = Kind::Busy;
		fe.text = "This individual is busy.";
		fe.norm = NormalizeText(fe.text);
		fe.ts = 100;
		file.entries.push_back(fe);
		b.LoadState(file);
		Entry se;
		se.kind = Kind::Busy;
		se.text = fe.text;
		se.norm = fe.norm;
		se.ts = 110;
		b.MergeSession({se});
		ExpectEqI(static_cast<int>(b.entries.size()), 1, "Busy 10 s window folds");
		Buffer b2;
		b2.LoadState(file);
		se.ts = 111;
		b2.MergeSession({se});
		ExpectEqI(static_cast<int>(b2.entries.size()), 2, "Busy outside 10 s does not fold");
	}

	{
		Buffer b;
		Expect(b.DedupeClockClear(), "empty buffer clock is clear");
		b.Offer(Cap(Kind::Game, "clock row", 100'000));
		Expect(!b.DedupeClockClear(), "offer arms the dedupe clock");
		auto snap = b.Snapshot();
		b.LoadState(snap);
		Expect(b.DedupeClockClear(), "load clears the dedupe clock");
		b.Offer(Cap(Kind::Game, "clock row", 101'000));
		ExpectEqI(static_cast<int>(b.entries.size()), 2, "cleared clock does not fold across a load");
		b.SortByTime();
		Expect(b.DedupeClockClear(), "sort clears the dedupe clock");
	}

	{
		Expect(WriterStartAllowed(false, false), "a stopped writer may start");
		Expect(!WriterStartAllowed(true, false), "a live detached writer blocks a second start");
		Expect(!WriterStartAllowed(false, true), "a started writer blocks a second start");
		Expect(!ShutdownWriterSetsStop(), "Y14 shutdown does not set stop");
		Expect(WriteAllowed(false, true, 1000, 1001), "force bypasses the dirty early return");
		Expect(!WriteAllowed(false, false, 0, 1000), "clean buffer does not write");
		Expect(!WriteAllowed(true, false, 1000, 1500), "retry waits the backoff");
		Expect(WriteAllowed(true, false, 1000, 2000), "retry after the backoff");
		ExpectEqI(NextRetryMs(0), kRetryMsMin, "first backoff is 1 s");
		ExpectEqI(NextRetryMs(1000), 2000, "backoff doubles");
		ExpectEqI(NextRetryMs(2000), 4000, "backoff doubles again");
		ExpectEqI(NextRetryMs(32000), kRetryMsMax, "backoff caps at 60 s");
		ExpectEqI(NextRetryMs(kRetryMsMax), kRetryMsMax, "cap stays at 60 s");
		Expect(!WriteAllowed(true, false, 1000, 2500, 2000), "grown backoff waits");
		Expect(WriteAllowed(true, false, 1000, 3000, 2000), "grown backoff is due");
		Expect(HoldRetryDue(false, 5000, 1000), "first promote is not throttled");
		Expect(!HoldRetryDue(true, 5000, 1001), "held promote waits the backoff");
		Expect(HoldRetryDue(true, 5000, 5000), "held promote runs when due");
		Expect(WithinDedupeWindow(3000, kDedupeMs), "3000 ms folds");
		Expect(!WithinDedupeWindow(3001, kDedupeMs), "3001 ms does not fold");
		Expect(WithinDedupeWindow(10000, kBusyDedupeMs), "Busy 10 s folds");
		Expect(!WithinDedupeWindow(10001, kBusyDedupeMs), "Busy 10.001 s does not fold");
		Expect(BakCopyBlocksReplace(1), "the first bak failure still blocks replace");
		Expect(!BakCopyBlocksReplace(3), "the third bak failure allows replace");
		Expect(AtExitShouldJoin(true), "atexit joins a finished worker");
		Expect(!AtExitShouldJoin(false), "atexit detaches a live-or-killed worker");
		bool dirty = false;
		NoteWriteFailure(dirty);
		Expect(dirty, "a failed write marks dirty so it is retried");
		bool failed = false;
		NoteWorkerSave(false, failed);
		Expect(failed, "the worker failure flag is set on Save false");
		bool hold = false;
		NoteLoadResult(false, hold);
		Expect(hold, "ApplyLoad hold is set on a failed load");
		NoteLoadResult(true, hold);
		Expect(!hold, "a successful load clears the hold");
		Expect(LoadResultStale(1, 2), "a recover from the previous load generation is stale");
		Expect(!LoadResultStale(3, 3), "a matching load generation is current");
		Expect(!LoadApplyStale(1, 1, "DD1C9DDC-n", "DD1C9DDC-n"),
			"a promote tagged with the name-hash buffer key is current");
		Expect(LoadApplyStale(1, 1, "DD1C9DDC-n", "0000AAAA"),
			"after the buffer key changes the old tag is stale");
		Expect(LoadJobBufMismatch("0000AAAA", "DD1C9DDC-n"),
			"the player-id result key is not the buffer tag");
		Expect(!LoadJobBufMismatch("DD1C9DDC-n", "DD1C9DDC-n"), "the queued buffer key matches itself");
		Expect(!LoadJobBufMismatch("", "0000AAAA"), "an empty job tag is not a mismatch");
		{
			std::uint64_t copiedGen = 0;
			std::string copiedKey;
			CopyLoadJobTag(7, "buf-key", copiedGen, copiedKey);
			ExpectEqI(static_cast<int>(copiedGen), 7, "the worker copies the load generation");
			ExpectEq(copiedKey, "buf-key", "the worker copies the buffer key");
		}
		Expect(ShouldClearRecoverBusy(2, 2), "the in-flight job may clear busy");
		Expect(!ShouldClearRecoverBusy(1, 2), "a stale result does not clear busy for the queued flush");
		Expect(!ApplyReopensCapture(true, false), "a hold-flush apply keeps capture closed");
		Expect(!ApplyReopensCapture(false, true), "a leftover hold-flush flag keeps capture closed");
		Expect(ApplyReopensCapture(false, false), "the new character reopens capture");
		Expect(WriteRecoveredResetsBackoff(false), "a successful write resets backoff");
		Expect(!WriteRecoveredResetsBackoff(true), "a hold does not reset the write backoff");
		Expect(MergeKeptKeyOk("0000ABCD", "0000ABCD"), "the same character key may merge");
		Expect(!MergeKeptKeyOk("0000BBBB", "0000ABCD"), "A's parked rows do not match B");
		Expect(!MergeKeptKeyOk("", "0000ABCD"), "an empty merge key is rejected");
		Expect(!MergeKeptKeyOk("", ""), "two empty keys do not merge");
		Expect(ShouldKeepHeldRows(true, 2), "a hold with rows is parked");
		Expect(!ShouldKeepHeldRows(false, 2), "a recovered session is not parked");
		Expect(!ShouldKeepHeldRows(true, 0), "an empty hold is not parked");
		Expect(ShouldParkDirtyRows(true, true, 1), "a dirty persist-allowed buffer is parked");
		Expect(!ShouldParkDirtyRows(false, true, 1), "a clean buffer is not parked as dirty");
		Expect(!ShouldParkDirtyRows(true, false, 1), "a name-hash dirty buffer is not parked");
		Expect(!ShouldParkDirtyRows(true, true, 0), "an empty dirty buffer is not parked");
		Expect(PendingCountsAsDirty(false, true), "a pending save counts as dirty");
		Expect(PendingCountsAsDirty(true, false), "a dirty buffer still counts as dirty");
		Expect(!PendingCountsAsDirty(false, false), "idle is not dirty");
		Expect(WriteFailParksJob("0000ABCD", "0000BBBB"), "a failed save for another key parks that job");
		Expect(!WriteFailParksJob("0000ABCD", "0000ABCD"), "a failed save for the current key stays on the buffer");
		Expect(!WriteFailParksJob("", "0000BBBB"), "an empty job key is not parked");
		Expect(ShouldParkDirtyRows(PendingCountsAsDirty(false, true), true, 1),
			"a pending persist-allowed save is parked");
		{
			Entry fileInv;
			fileInv.id = 1;
			fileInv.kind = Kind::Game;
			fileInv.text = "Inventory full";
			fileInv.ts = 5;
			Entry parkedInv;
			parkedInv.id = 1;
			parkedInv.kind = Kind::Game;
			parkedInv.text = "Inventory full";
			parkedInv.ts = 700;
			Expect(!SameParkedRow(fileInv, parkedInv),
				"same text and id at different times are two events");
			parkedInv.ts = 5;
			Expect(SameParkedRow(fileInv, parkedInv),
				"S26/S28 same kind, text, and timestamp match");
			fileInv.id = 99;
			Expect(SameParkedRow(fileInv, parkedInv),
				"S26/S28 same-ts re-park does not use id");
			parkedInv.kind = Kind::Medical;
			Expect(!SameParkedRow(fileInv, parkedInv),
				"the same text at the same time is not a match across kinds");
			parkedInv.kind = Kind::Game;
			parkedInv.text = "INVENTORY   FULL";
			Expect(SameParkedRow(fileInv, parkedInv),
				"parked rows compare normalized text");
		}
		{
			Log w15;
			w15.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			w15.retryBackoffMs = 0;
			w15.retryAt = 0;
			w15.persistHold = false;
			Entry oldRow;
			oldRow.kind = Kind::Game;
			oldRow.text = "A W15";
			oldRow.ts = 1;
			if (WriteFailParksJob("0000ABCD", w15.buf.character.key))
				w15.ParkWriteFailure("0000ABCD", std::vector<Entry>{oldRow});
			else {
				NoteWriteFailure(w15.dirty);
				w15.NoteRetryFailure(50'000);
			}
			ExpectEqI(w15.retryBackoffMs, 0, "W15 old-key fail does not back off B");
			Expect(w15.retryAt == 0, "W15 old-key fail does not set B's retry timer");
			Expect(!w15.persistHold, "W15 old-key fail is not a hold");
		}
		{
			Log w17;
			w17.dirty = false;
			w17.writePending = true;
			w17.persistHold = false;
			w17.buf.character = MakeCharacter(0xABCDu, "Sam");
			w17.buf.entries.resize(1);
			w17.buf.entries.front().kind = Kind::Game;
			w17.buf.entries.front().text = "W17 pending";
			w17.ParkHeldRows();
			ExpectEqI(static_cast<int>(w17.keptHeld.size()), 1, "W17 reset park honors the pending flag");
			Expect(w17.keptHeld.front().entries.front().text == "W17 pending", "W17 parks the pending row");
			Log idle;
			idle.dirty = false;
			idle.writePending = false;
			idle.persistHold = false;
			idle.buf.character = MakeCharacter(0xABCDu, "Sam");
			idle.buf.entries.resize(1);
			idle.buf.entries.front().text = "W17 idle";
			idle.ParkHeldRows();
			Expect(idle.keptHeld.empty(), "W17 idle is not parked");
		}
		{
			Character nh = MakeCharacter(0, "Sam");
			Character pid = MakeCharacter(0xABCDu, "Sam");
			ExpectEq(ParkHeldKey(nh, "0000ABCD"), "0000ABCD", "a name-hash hold parks under the player-id target");
			ExpectEq(ParkHeldKey(nh, ""), nh.key, "a name-hash hold without a target keeps its own key");
			ExpectEq(ParkHeldKey(pid, "0000FFFF"), "0000ABCD", "a player-id hold keeps its own key");
		}
		{
			int backoff = 0;
			std::uint64_t retryAt = 0;
			backoff = NextRetryMs(backoff);
			ExpectEqI(backoff, 1000, "first write failure starts at 1 s");
			backoff = NextRetryMs(backoff);
			ExpectEqI(backoff, 2000, "second write failure is 2 s");
			retryAt = 10'000 + static_cast<std::uint64_t>(backoff);
			NoteWriteSuccess(backoff, retryAt);
			ExpectEqI(backoff, 0, "successful write resets the backoff");
			Expect(retryAt == 0, "successful write clears retryAt");
			Expect(WriteAllowed(true, false, 10'000, 25'000, backoff),
				"after success the next write is allowed at normal cadence");
			ExpectEqI(NextRetryMs(backoff), 1000, "a new failure streak starts at 1 s");
			int grown = 0;
			for (int i = 0; i < 7; ++i)
				grown = NextRetryMs(grown);
			ExpectEqI(grown, kRetryMsMax, "seven failures cap at 60 s");
			Expect(!WriteAllowed(true, false, 10'000, 25'000, grown),
				"60 s backoff blocks a 15 s gap");
			std::uint64_t at = 1;
			NoteWriteSuccess(grown, at);
			ExpectEqI(grown, 0, "success after a long streak still resets backoff");
			Expect(WriteAllowed(true, false, 10'000, 25'000, grown),
				"after that reset a 15 s gap is allowed");
			ExpectEqI(NextRetryMs(grown), 1000, "the next failure after a reset starts at 1 s");
		}
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		int fails = 0;
		log.replace = [&](const std::filesystem::path&, const std::filesystem::path&) {
			++fails;
			return false;
		};
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "retry me", 20'000));
		Expect(log.dirty, "offer dirties the buffer");
		Expect(!log.Flush(20'000), "a failing replace fails the save");
		Expect(fails >= 1, "Save used the failing replace");
		Expect(log.dirty, "failed save stays dirty for a retry");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		Expect(!std::filesystem::is_regular_file(path), "failed replace leaves no main file");
		log.replace = DefaultReplace;
		log.ApplyPersist(true);
		Expect(log.Flush(21'000), "retry save succeeds");
		Expect(!log.dirty, "successful retry clears dirty");
		Expect(ReadFile(path).find("retry me") != std::string::npos, "retry wrote the row");
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "keep original", 20'000));
		Expect(log.Flush(20'000), "seed the main file");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		std::error_code ec;
		std::filesystem::remove(bak, ec);
		std::filesystem::create_directory(bak, ec);
		log.Offer(Cap(Kind::Game, "must not replace", 40'000));
		Expect(!log.Flush(40'000), "a failed bak copy fails the save");
		Expect(ReadFile(path).find("keep original") != std::string::npos, "main file is not replaced after bak failure");
		Expect(ReadFile(path).find("must not replace") == std::string::npos, "new row is not in the main file");
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log log;
		Settings s;
		log.Configure(s, root);
		log.buf.character = MakeCharacter(0xABCDu, "Sam");
		log.Offer(Cap(Kind::Game, "keep original", 20'000));
		Expect(log.Flush(20'000), "seed the main file for bak give-up");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		std::error_code ec;
		std::filesystem::remove(bak, ec);
		std::filesystem::create_directory(bak, ec);
		WriteFile(bak / "lock", "held");
		auto* fs = dynamic_cast<FileStore*>(log.store.get());
		Expect(fs != nullptr, "persist store is FileStore");
		if (fs) fs->bakFailGiveUp = 3;
		log.Offer(Cap(Kind::Game, "third try writes", 40'000));
		Expect(!log.Flush(41'000), "first bak failure still blocks");
		Expect(!log.Flush(42'000), "second bak failure still blocks");
		Expect(log.Flush(43'000), "third bak failure writes the main file");
		Expect(ReadFile(path).find("third try writes") != std::string::npos, "give-up replace updated the main file");
		Expect(std::filesystem::is_directory(bak), "locked bak path is left in place");
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Log seed;
		Settings s;
		seed.Configure(s, root);
		seed.buf.character = MakeCharacter(0xABCDu, "Sam");
		seed.Offer(Cap(Kind::Game, "newer file", 20'000));
		Expect(seed.Flush(20'000), "write the first generation");
		seed.Offer(Cap(Kind::Game, "second generation", 40'000));
		Expect(seed.Flush(40'000), "write the newer main file");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		Expect(ReadFile(path).find("second generation") != std::string::npos, "main file is the newer generation");
		Expect(ReadFile(bak).find("newer file") != std::string::npos, "bak holds the older generation");

		auto transientMain = [](const std::filesystem::path& a_p) {
			FileRead rd;
			const auto name = a_p.filename().string();
			if (name.size() < 4 || name.substr(name.size() - 4) != ".bak") {
				rd.ok = false;
				rd.notice = "sharing violation";
				return rd;
			}
			return ReadLogFile(a_p);
		};

		FileStore fs(root / "MessageLog");
		fs.readHook = transientMain;
		LogState st;
		std::string notice;
		Expect(!fs.Load("0000ABCD", st, notice), "transient read fails the load");
		Expect(st.entries.empty(), "transient read does not fall back to bak");
		Expect(notice.find("sharing") != std::string::npos || notice.find("transient") != std::string::npos
			|| notice.find("read") != std::string::npos, "transient notice");

		Log live;
		live.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(live.store.get()))
			p->readHook = transientMain;
		live.buf.character = MakeCharacter(0xABCDu, "Sam");
		live.LoadCurrent();
		Expect(live.persistHold, "HUD load hold after transient");
		Expect(live.buf.entries.empty(), "memory stays empty until the real file loads");
		live.Offer(Cap(Kind::Game, "session only", 80'000));
		Expect(!live.ShouldFlush(100'000, true), "hold blocks a flush");
		Expect(!live.Flush(100'000), "hold does not overwrite the newer file");
		Expect(ReadFile(path).find("second generation") != std::string::npos, "newer main file is left in place");

		Log promo;
		promo.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(promo.store.get()))
			p->readHook = transientMain;
		promo.buf.character = MakeCharacter(0, "Sam");
		promo.Offer(Cap(Kind::Game, "namehash row", 90'000));
		Expect(!promo.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam")), "transient promote retries later");
		Expect(promo.buf.character.keySource == "nameHash", "transient promote keeps name-hash");
		Expect(promo.persistHold, "promote hold after transient");
		Expect(promo.buf.entries.size() == 1 && promo.buf.entries.front().text == "namehash row",
			"transient promote keeps the session in memory");

		int reads = 0;
		auto countFail = [&](const std::filesystem::path&) {
			++reads;
			FileRead rd;
			rd.ok = false;
			rd.notice = "sharing violation";
			return rd;
		};
		Log throttle;
		throttle.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(throttle.store.get()))
			p->readHook = countFail;
		throttle.buf.character = MakeCharacter(0, "Sam");
		throttle.Offer(Cap(Kind::Game, "throttle row", 10'000));
		Expect(!throttle.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 1'000), "first promote reads once");
		ExpectEqI(reads, 1, "first promote does one read");
		Expect(!throttle.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 1'001), "promote is throttled");
		ExpectEqI(reads, 1, "throttled promote does not read again");
		Expect(!throttle.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), throttle.retryAt), "promote retries when due");
		ExpectEqI(reads, 2, "due promote reads once more");

		if (auto* p = dynamic_cast<FileStore*>(live.store.get()))
			p->readHook = nullptr;
		Expect(live.RetryHeld(MakeCharacter(0xABCDu, "Sam"), 200'000, true), "held session merges after the read recovers");
		Expect(!live.persistHold, "recover clears the hold");
		bool gotNewer = false, gotSession = false;
		for (const auto& e : live.buf.entries) {
			if (e.text == "second generation") gotNewer = true;
			if (e.text == "session only") gotSession = true;
		}
		Expect(gotNewer && gotSession, "recover merges the held rows into the file");
		Expect(live.Flush(210'000), "recover then writes");

		Log held;
		held.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(held.store.get()))
			p->readHook = transientMain;
		held.buf.character = MakeCharacter(0, "Sam");
		held.Offer(Cap(Kind::Game, "must survive", 220'000));
		Expect(!held.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 221'000), "quit path tries recover once");
		ExpectEqI(static_cast<int>(held.buf.entries.size()), 1, "held rows survive a failed quit/load attempt");
		Expect(held.buf.entries.front().text == "must survive", "held text is still in memory");
		Expect(held.RetryHeld(MakeCharacter(0xABCDu, "Sam"), 221'000, true) == false, "forced recover still fails");
		Expect(held.buf.entries.front().text == "must survive", "forced recover does not discard held rows");

		Log park;
		park.Configure(s, root);
		if (auto* p = dynamic_cast<FileStore*>(park.store.get()))
			p->readHook = transientMain;
		park.buf.character = MakeCharacter(0xABCDu, "Sam");
		park.LoadCurrent();
		Expect(park.persistHold, "park fixture is held");
		park.Offer(Cap(Kind::Game, "parked row", 230'000));
		park.ParkHeldRows();
		ExpectEqI(static_cast<int>(park.keptHeld.size()), 1, "one parked slot");
		ExpectEq(park.keptHeld.front().key, "0000ABCD", "parked rows keep the character key");
		ExpectEqI(static_cast<int>(park.keptHeld.front().entries.size()), 1, "parked row count");
		Expect(park.keptHeld.front().entries.front().text == "parked row", "parked text is kept");
		park.buf.ResetMemory();
		Expect(park.buf.entries.empty(), "reset drops the live held rows");
		if (auto* p = dynamic_cast<FileStore*>(park.store.get()))
			p->readHook = nullptr;
		park.LoadCurrent();
		park.dirty = false;
		park.MergeKeptHeldIfMatch("0000BBBB");
		bool leakB = false;
		for (const auto& e : park.buf.entries)
			if (e.text == "parked row") leakB = true;
		Expect(!leakB, "A's held row must never land in B's file");
		ExpectEqI(static_cast<int>(park.keptHeld.size()), 1, "B's key leaves A's parked slot");
		Expect(!park.dirty, "a key mismatch does not dirty the buffer");
		park.MergeKeptHeldIfMatch("");
		ExpectEqI(static_cast<int>(park.keptHeld.size()), 1, "an empty key does not merge parked rows");
		park.MergeKeptHeldIfMatch("0000ABCD");
		bool gotFile = false, gotParked = false;
		for (const auto& e : park.buf.entries) {
			if (e.text == "second generation") gotFile = true;
			if (e.text == "parked row") gotParked = true;
		}
		Expect(gotFile && gotParked, "a later load of that character merges the parked rows");
		Expect(park.keptHeld.empty(), "merged parked rows are cleared");
		Expect(park.dirty, "a matched merge dirties the buffer");
		{
			Log two;
			two.persistHold = true;
			two.buf.character = MakeCharacter(0xABCDu, "Sam");
			two.Offer(Cap(Kind::Game, "A held", 240'000));
			two.ParkHeldRows();
			two.buf.ResetMemory();
			two.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			two.Offer(Cap(Kind::Game, "B held", 250'000));
			two.ParkHeldRows();
			ExpectEqI(static_cast<int>(two.keptHeld.size()), 2, "each character keeps its own parked slot");
			two.buf.ResetMemory();
			two.dirty = false;
			two.MergeKeptHeldIfMatch("0000BBBB");
			ExpectEqI(static_cast<int>(two.buf.entries.size()), 1, "B merge takes only B's slot");
			Expect(two.buf.entries.front().text == "B held", "B merge has B's row");
			bool aInB = false;
			for (const auto& e : two.buf.entries)
				if (e.text == "A held") aInB = true;
			Expect(!aInB, "A's held row is not in B after B's merge");
			ExpectEqI(static_cast<int>(two.keptHeld.size()), 1, "A's slot remains after B merges");
		}
		{
			Log promo;
			promo.Configure(s, root);
			if (auto* p = dynamic_cast<FileStore*>(promo.store.get()))
				p->readHook = transientMain;
			promo.buf.character = MakeCharacter(0, "Sam");
			promo.Offer(Cap(Kind::Game, "namehash held", 260'000));
			Expect(!promo.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 261'000),
				"the real promote path fails the read");
			Expect(promo.persistHold, "failed promote holds the session");
			ExpectEq(promo.holdTargetKey, "0000ABCD", "failed promote records the player-id target");
			promo.ParkHeldRows();
			ExpectEqI(static_cast<int>(promo.keptHeld.size()), 1, "failed promote parks one slot");
			ExpectEq(promo.keptHeld.front().key, "0000ABCD", "name-hash rows park under the player-id target");
			const auto parked = promo.keptHeld;

			Log other;
			other.Configure(s, root);
			other.buf.character = MakeCharacter(0xBBBBu, "Sam");
			other.keptHeld = parked;
			other.ApplyRecoveredFile({}, MakeCharacter(0xBBBBu, "Sam"));
			other.MergeKeptHeldIfMatch(other.buf.character.key);
			bool leakSameName = false;
			for (const auto& e : other.buf.entries)
				if (e.text == "namehash held") leakSameName = true;
			Expect(!leakSameName, "a different character with the same name gets none of the held rows");
			ExpectEqI(static_cast<int>(other.keptHeld.size()), 1, "the parked slot stays for the target character");

			Log later;
			later.Configure(s, root);
			later.keptHeld = parked;
			LogState aFile;
			std::string notice;
			Expect(dynamic_cast<FileStore*>(later.store.get())->Load("0000ABCD", aFile, notice),
				"A's file loads for ApplyRecoveredFile");
			later.ApplyRecoveredFile(std::move(aFile), MakeCharacter(0xABCDu, "Sam"));
			later.MergeKeptHeldIfMatch("0000ABCD");
			bool gotNh = false, gotFileRow = false;
			for (const auto& e : later.buf.entries) {
				if (e.text == "namehash held") gotNh = true;
				if (e.text == "second generation") gotFileRow = true;
			}
			Expect(gotNh && gotFileRow, "held name-hash rows merge into that character's file only");
			Expect(later.Flush(270'000), "the recovered session writes");
			Expect(ReadFile(path).find("namehash held") != std::string::npos,
				"A's file on disk has the held name-hash row");
			Expect(ReadFile(path).find("second generation") != std::string::npos,
				"A's file still has its own rows");
		}
		{
			Log again;
			again.Configure(s, root);
			again.persistHold = true;
			again.buf.character = MakeCharacter(0xABCDu, "Sam");
			again.Offer(Cap(Kind::Game, "A1", 280'000));
			again.ParkHeldRows();
			again.buf.ResetMemory();
			again.buf.character = MakeCharacter(0xABCDu, "Sam");
			again.persistHold = true;
			again.Offer(Cap(Kind::Game, "A2", 284'000));
			again.ParkHeldRows();
			ExpectEqI(static_cast<int>(again.keptHeld.size()), 1, "a second park for the same key stays one slot");
			ExpectEqI(static_cast<int>(again.keptHeld.front().entries.size()), 2, "the second park appends");
			bool gotA1 = false, gotA2 = false;
			for (const auto& e : again.keptHeld.front().entries) {
				if (e.text == "A1") gotA1 = true;
				if (e.text == "A2") gotA2 = true;
			}
			Expect(gotA1 && gotA2, "park A1 then park A2 keeps both rows");
			again.LoadCurrent();
			again.MergeKeptHeldIfMatch("0000ABCD");
			Expect(again.Flush(290'000), "appended parked rows write to A's file");
			const auto body = ReadFile(path);
			Expect(body.find("A1") != std::string::npos && body.find("A2") != std::string::npos,
				"both parked rows reach A's file");
		}
		{
			Log cap;
			cap.persistHold = true;
			cap.buf.character = MakeCharacter(0xABCDu, "Sam");
			cap.buf.entries.resize(static_cast<std::size_t>(1008));
			for (int i = 0; i < 1008; ++i) {
				auto& e = cap.buf.entries[static_cast<std::size_t>(i)];
				e.text = "cap " + std::to_string(i);
				e.ts = i;
				e.pin = (i == 0) ? 1 : 0;
			}
			cap.ParkHeldRows();
			ExpectEqI(static_cast<int>(cap.keptHeld.front().entries.size()), 1000, "parked rows cap at 1000");
			bool gotNewest = false, gotOldestPin = false, gotOldestUnpinned = false;
			for (const auto& e : cap.keptHeld.front().entries) {
				if (e.text == "cap 1007") gotNewest = true;
				if (e.text == "cap 0") gotOldestPin = true;
				if (e.text == "cap 1") gotOldestUnpinned = true;
			}
			Expect(gotNewest, "the cap keeps the newest rows");
			Expect(gotOldestPin, "the cap keeps pins");
			Expect(!gotOldestUnpinned, "the cap drops the oldest unpinned rows");
		}
		{
			Log s19;
			s19.Configure(s, root);
			if (auto* p = dynamic_cast<FileStore*>(s19.store.get()))
				p->readHook = transientMain;
			s19.buf.character = MakeCharacter(0, "Sam");
			s19.Offer(Cap(Kind::Game, "A S19 held", 300'000));
			Expect(!s19.PromoteToCharacter(MakeCharacter(0xABCDu, "Sam"), 301'000),
				"S19 A promote read fails");
			s19.ParkHeldRows();
			s19.NoteRetrySuccess();
			Expect(!s19.persistHold, "S19 HUD-ready clear drops the hold");
			Expect(s19.holdTargetKey.empty(), "S19 HUD-ready clear drops the stale target");
			s19.buf.ResetMemory();
			s19.buf.character = MakeCharacter(0, "Barrett");
			s19.Offer(Cap(Kind::Game, "B S19 row", 310'000));
			s19.ParkHeldRows();
			s19.NoteRetrySuccess();
			s19.buf.ResetMemory();
			s19.buf.character = MakeCharacter(0xCCCCu, "Cora");
			s19.Offer(Cap(Kind::Game, "C S19 row", 320'000));
			s19.ParkHeldRows();
			s19.NoteRetrySuccess();
			s19.buf.ResetMemory();
			if (auto* p = dynamic_cast<FileStore*>(s19.store.get()))
				p->readHook = nullptr;
			s19.buf.character = MakeCharacter(0xABCDu, "Sam");
			s19.LoadCurrent();
			s19.MergeKeptHeldIfMatch("0000ABCD");
			Expect(s19.Flush(330'000), "S19 A load writes");
			const auto s19Body = ReadFile(path);
			Expect(s19Body.find("B S19 row") == std::string::npos, "S19 A's file contains none of B's rows");
			Expect(s19Body.find("C S19 row") == std::string::npos, "S19 A's file contains none of C's rows");
			Expect(s19Body.find("A S19 held") != std::string::npos, "S19 A's parked row reaches A's file");
		}
		{
			Log ap;
			ap.persistHold = true;
			ap.buf.character = MakeCharacter(0xABCDu, "Sam");
			ap.buf.entries.resize(700);
			for (int i = 0; i < 700; ++i) {
				auto& e = ap.buf.entries[static_cast<std::size_t>(i)];
				e.text = "a1-" + std::to_string(i);
				e.ts = i;
				e.pin = i < 28 ? 1 : 0;
			}
			ap.ParkHeldRows();
			ap.buf.ResetMemory();
			ap.buf.character = MakeCharacter(0xABCDu, "Sam");
			ap.persistHold = true;
			ap.buf.entries.resize(700);
			for (int i = 0; i < 700; ++i) {
				auto& e = ap.buf.entries[static_cast<std::size_t>(i)];
				e.text = "a2-" + std::to_string(i);
				e.ts = 1000 + i;
				e.pin = i < 28 ? 1 : 0;
			}
			ap.ParkHeldRows();
			ExpectEqI(static_cast<int>(ap.keptHeld.size()), 1, "append-path cap stays one slot");
			const auto& rows = ap.keptHeld.front().entries;
			ExpectEqI(static_cast<int>(rows.size()), 1000, "append-path cap is 1000 rows");
			int pins = 0, a1pin = 0, a2pin = 0, lastA1Pin = -1, firstA2Pin = -1;
			int lastA1Rest = -1, firstA2Rest = -1;
			bool gotNewest = false;
			for (int i = 0; i < static_cast<int>(rows.size()); ++i) {
				const auto& e = rows[static_cast<std::size_t>(i)];
				const bool a1 = e.text.rfind("a1-", 0) == 0;
				const bool a2 = e.text.rfind("a2-", 0) == 0;
				if (e.text == "a2-699") gotNewest = true;
				if (e.pin) {
					++pins;
					if (a1) { ++a1pin; lastA1Pin = i; }
					if (a2) { ++a2pin; if (firstA2Pin < 0) firstA2Pin = i; }
				} else {
					if (a1) lastA1Rest = i;
					if (a2 && firstA2Rest < 0) firstA2Rest = i;
				}
			}
			ExpectEqI(pins, 56, "append-path cap keeps all 56 pins");
			ExpectEqI(a1pin, 28, "append-path cap keeps the A1 pins");
			ExpectEqI(a2pin, 28, "append-path cap keeps the A2 pins");
			Expect(gotNewest, "append-path cap keeps the newest A2 rows");
			Expect(lastA1Pin >= 0 && firstA2Pin > lastA1Pin, "A1 pins stay before A2 pins");
			Expect(lastA1Rest >= 0 && firstA2Rest > lastA1Rest, "A1 rows stay before A2 rows");
		}
		{
			Log empty;
			empty.persistHold = true;
			empty.buf.character.key.clear();
			empty.buf.character.keySource.clear();
			empty.holdTargetKey.clear();
			empty.buf.entries.resize(1);
			empty.buf.entries.front().text = "no key";
			empty.ParkHeldRows();
			Expect(empty.keptHeld.empty(), "an empty key is not parked");
		}
		{
			Log dirtyEmpty;
			dirtyEmpty.dirty = true;
			dirtyEmpty.persistHold = false;
			dirtyEmpty.buf.character.key.clear();
			dirtyEmpty.buf.character.keySource = "playerId";
			dirtyEmpty.buf.entries.resize(1);
			dirtyEmpty.buf.entries.front().text = "dirty no key";
			dirtyEmpty.ParkHeldRows();
			Expect(dirtyEmpty.keptHeld.empty(), "a dirty park never uses an empty key");
		}
		{
			Log mfd;
			Settings failS;
			mfd.Configure(failS, root);
			mfd.replace = [&](const std::filesystem::path&, const std::filesystem::path&) { return false; };
			mfd.ApplyPersist(true);
			mfd.buf.character = MakeCharacter(0xABCDu, "Sam");
			mfd.Offer(Cap(Kind::Game, "A unsaved write", 400'000));
			Expect(!mfd.Flush(401'000), "A's save fails while a load is starting");
			Expect(mfd.dirty, "the failed save stays dirty");
			Expect(!mfd.persistHold, "a failed write is not a read hold");
			mfd.ParkHeldRows();
			mfd.NoteRetrySuccess();
			mfd.buf.ResetMemory();
			mfd.dirty = false;
			mfd.replace = DefaultReplace;
			mfd.ApplyPersist(true);
			mfd.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			mfd.Offer(Cap(Kind::Game, "B session", 410'000));
			Expect(mfd.Flush(411'000), "B writes after the switch");
			const auto bPath = root / "MessageLog" / "MessageLog_0000BBBB.json";
			Expect(ReadFile(bPath).find("B session") != std::string::npos, "B's file has B's row");
			Expect(ReadFile(bPath).find("A unsaved write") == std::string::npos, "B's file has none of A's unsaved rows");
			mfd.buf.ResetMemory();
			mfd.dirty = false;
			mfd.buf.character = MakeCharacter(0xABCDu, "Sam");
			mfd.LoadCurrent();
			mfd.dirty = false;
			mfd.MergeKeptHeldIfMatch("0000ABCD");
			Expect(mfd.dirty, "merging parked write-fail rows dirties the buffer");
			Expect(mfd.Flush(420'000), "A writes after the switch back");
			Expect(ReadFile(path).find("A unsaved write") != std::string::npos, "A's row ends up in A's file");
			Expect(ReadFile(bPath).find("A unsaved write") == std::string::npos, "A's row is not in B's file");
		}
		{
			Log thru;
			Settings failS;
			thru.Configure(failS, root);
			thru.replace = [&](const std::filesystem::path&, const std::filesystem::path&) { return false; };
			thru.ApplyPersist(true);
			thru.buf.character = MakeCharacter(0xABCDu, "Sam");
			thru.Offer(Cap(Kind::Game, "A failthru", 430'000));
			Expect(!thru.Flush(431'000), "A's write keeps failing");
			thru.ParkHeldRows();
			thru.NoteRetrySuccess();
			thru.buf.ResetMemory();
			thru.dirty = false;
			thru.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			thru.Offer(Cap(Kind::Game, "B failthru", 440'000));
			Expect(!thru.Flush(441'000), "B's write keeps failing through the switch");
			thru.ParkHeldRows();
			thru.NoteRetrySuccess();
			thru.buf.ResetMemory();
			thru.dirty = false;
			thru.replace = DefaultReplace;
			thru.ApplyPersist(true);
			thru.buf.character = MakeCharacter(0xABCDu, "Sam");
			thru.LoadCurrent();
			thru.MergeKeptHeldIfMatch("0000ABCD");
			Expect(thru.Flush(450'000), "A writes after writes recover");
			Expect(ReadFile(path).find("A failthru") != std::string::npos, "A's fail-through row is in A's file");
			Expect(ReadFile(path).find("B failthru") == std::string::npos, "B's fail-through row is not in A's file");
			thru.buf.ResetMemory();
			thru.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			thru.LoadCurrent();
			thru.MergeKeptHeldIfMatch("0000BBBB");
			Expect(thru.Flush(451'000), "B writes after writes recover");
			const auto bPath = root / "MessageLog" / "MessageLog_0000BBBB.json";
			Expect(ReadFile(bPath).find("B failthru") != std::string::npos, "B's fail-through row is in B's file");
			Expect(ReadFile(bPath).find("A failthru") == std::string::npos, "A's fail-through row is not in B's file");
		}
		{
			Log p2;
			Settings p2s;
			p2.Configure(p2s, root);
			p2.ApplyPersist(true);
			p2.buf.character = MakeCharacter(0xABCDu, "Sam");
			p2.Offer(Cap(Kind::Game, "exact park", 500'000));
			Expect(p2.Flush(501'000), "seed the file for exact-match park");
			ExpectEqI(p2.buf.entries.front().n, 1, "seed n is 1");
			p2.dirty = true;
			p2.ParkHeldRows();
			p2.dirty = false;
			p2.MergeKeptHeldIfMatch("0000ABCD");
			ExpectEqI(static_cast<int>(p2.buf.entries.size()), 1, "exact park stays one row");
			ExpectEqI(p2.buf.entries.front().n, 1, "S26/S28 exact same-ts re-park gives n=1");
			Expect(!p2.dirty, "exact park merge does not dirty a file that already has the row");
			Entry copy = p2.buf.entries.front();
			copy.id = 99999;
			p2.ParkWriteFailure("0000ABCD", std::vector<Entry>{copy});
			p2.MergeKeptHeldIfMatch("0000ABCD");
			ExpectEqI(p2.buf.entries.front().n, 1, "S26/S28 same-ts re-park does not bump n");
		}
		{
			Log inv;
			inv.Configure(s, root);
			inv.ApplyPersist(true);
			inv.buf.character = MakeCharacter(0xABCDu, "Sam");
			Entry fileInv;
			fileInv.id = 1;
			fileInv.kind = Kind::Game;
			fileInv.text = "Inventory full";
			fileInv.ts = 5;
			fileInv.n = 1;
			inv.buf.entries.push_back(fileInv);
			inv.buf.nextId = 2;
			Entry parkedInv;
			parkedInv.id = 1;
			parkedInv.kind = Kind::Game;
			parkedInv.text = "Inventory full";
			parkedInv.ts = 700;
			parkedInv.n = 1;
			inv.ParkWriteFailure("0000ABCD", std::vector<Entry>{parkedInv});
			inv.MergeKeptHeldIfMatch("0000ABCD");
			ExpectEqI(static_cast<int>(inv.buf.entries.size()), 2,
				"Inventory full at ts 5 and ts 700 are both kept");
			bool got5 = false, got700 = false;
			int n5 = 0, n700 = 0;
			for (const auto& e : inv.buf.entries) {
				if (e.text == "Inventory full" && e.ts == 5) { got5 = true; n5 = e.n; }
				if (e.text == "Inventory full" && e.ts == 700) { got700 = true; n700 = e.n; }
			}
			Expect(got5 && got700, "file id 1 ts 5 and parked id 1 ts 700 both survive the merge");
			ExpectEqI(n5, 1, "the file Inventory full row stays n=1");
			ExpectEqI(n700, 1, "the later Inventory full row stays n=1");
		}
		{
			Log w7;
			w7.Configure(s, root);
			w7.ApplyPersist(true);
			w7.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			Entry aRow;
			aRow.id = 1;
			aRow.kind = Kind::Game;
			aRow.text = "A old-key fail";
			aRow.ts = 800;
			Expect(WriteFailParksJob("0000ABCD", w7.buf.character.key),
				"W7 a failure for an old key is not the current key");
			w7.ParkWriteFailure("0000ABCD", std::vector<Entry>{aRow});
			ExpectEqI(static_cast<int>(w7.keptHeld.size()), 1, "W7 parks one slot");
			ExpectEq(w7.keptHeld.front().key, "0000ABCD", "W7 parks under the job key");
			Expect(w7.keptHeld.front().key != w7.buf.character.key,
				"W7 is never parked under the current key");
			w7.Offer(Cap(Kind::Game, "B after W7", 820'000));
			w7.MergeKeptHeldIfMatch(w7.buf.character.key);
			bool aInB = false;
			for (const auto& e : w7.buf.entries)
				if (e.text == "A old-key fail") aInB = true;
			Expect(!aInB, "W7 A's row is not merged into B");
			Expect(w7.Flush(821'000), "W7 B writes");
			const auto bW7 = root / "MessageLog" / "MessageLog_0000BBBB.json";
			Expect(ReadFile(bW7).find("B after W7") != std::string::npos, "W7 B's file has B's row");
			Expect(ReadFile(bW7).find("A old-key fail") == std::string::npos,
				"W7 A's row never ends up in B");
		}
		{
			Log queued;
			queued.Configure(s, root);
			queued.ApplyPersist(true);
			queued.buf.character = MakeCharacter(0xABCDu, "Sam");
			queued.Offer(Cap(Kind::Game, "A queued save", 600'000));
			Expect(queued.dirty, "queued save starts dirty");
			const auto snap = queued.buf.Snapshot();
			const auto jobKey = queued.buf.character.key;
			queued.dirty = false;
			queued.writePending = true;
			Expect(PendingCountsAsDirty(queued.dirty, queued.writePending),
				"a queued save is pending at HUD-ready");
			queued.ParkHeldRows();
			queued.NoteRetrySuccess();
			queued.buf.ResetMemory();
			queued.dirty = false;
			queued.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			Expect(WriteFailParksJob(jobKey, queued.buf.character.key),
				"queued fail parks under A");
			queued.ParkWriteFailure(jobKey, snap.entries);
			queued.writePending = false;
			queued.ParkWriteFailure("", snap.entries);
			ExpectEqI(static_cast<int>(queued.keptHeld.size()), 1, "queued fail never parks an empty key");
			ExpectEqI(static_cast<int>(queued.keptHeld.front().entries.size()), 1,
				"queued fail does not double-park the same snap");
			queued.Offer(Cap(Kind::Game, "B after queued", 610'000));
			Expect(queued.Flush(611'000), "B writes after the queued fail");
			const auto bQueued = root / "MessageLog" / "MessageLog_0000BBBB.json";
			Expect(ReadFile(bQueued).find("B after queued") != std::string::npos, "B's file has B's queued-test row");
			Expect(ReadFile(bQueued).find("A queued save") == std::string::npos, "B's file has none of the queued A row");
			queued.buf.ResetMemory();
			queued.dirty = false;
			queued.buf.character = MakeCharacter(0xABCDu, "Sam");
			queued.LoadCurrent();
			queued.dirty = false;
			queued.MergeKeptHeldIfMatch("0000ABCD");
			Expect(queued.Flush(620'000), "A writes after the queued fail");
			ExpectEqI(CountNeedle(ReadFile(path), "A queued save"), 1, "A's queued row is in A's file exactly once");
			Expect(ReadFile(bQueued).find("A queued save") == std::string::npos, "A's queued row is not in B's file");
		}
		{
			Log running;
			running.Configure(s, root);
			running.ApplyPersist(true);
			running.buf.character = MakeCharacter(0xABCDu, "Sam");
			running.Offer(Cap(Kind::Game, "A running save", 700'000));
			Expect(running.dirty, "running save starts dirty");
			const auto snap = running.buf.Snapshot();
			const auto jobKey = running.buf.character.key;
			running.dirty = false;
			running.writePending = true;
			Expect(PendingCountsAsDirty(running.dirty, running.writePending),
				"a running save is pending at HUD-ready");
			running.ParkHeldRows();
			running.NoteRetrySuccess();
			running.buf.ResetMemory();
			running.dirty = false;
			running.buf.character = MakeCharacter(0xBBBBu, "Barrett");
			Expect(WriteFailParksJob(jobKey, running.buf.character.key),
				"running fail parks under A");
			running.ParkWriteFailure(jobKey, snap.entries);
			running.writePending = false;
			ExpectEqI(static_cast<int>(running.keptHeld.size()), 1, "running fail parks one slot");
			ExpectEqI(static_cast<int>(running.keptHeld.front().entries.size()), 1,
				"running fail does not double-park the worker snap");
			running.Offer(Cap(Kind::Game, "B after running", 710'000));
			Expect(running.Flush(711'000), "B writes after the running fail");
			const auto bRunning = root / "MessageLog" / "MessageLog_0000BBBB.json";
			Expect(ReadFile(bRunning).find("B after running") != std::string::npos, "B's file has B's running-test row");
			Expect(ReadFile(bRunning).find("A running save") == std::string::npos, "B's file has none of the running A row");
			running.buf.ResetMemory();
			running.dirty = false;
			running.buf.character = MakeCharacter(0xABCDu, "Sam");
			running.LoadCurrent();
			running.dirty = false;
			running.MergeKeptHeldIfMatch("0000ABCD");
			Expect(running.Flush(720'000), "A writes after the running fail");
			ExpectEqI(CountNeedle(ReadFile(path), "A running save"), 1, "A's running row is in A's file exactly once");
			Expect(ReadFile(bRunning).find("A running save") == std::string::npos, "A's running row is not in B's file");
		}
		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		std::atomic<bool> stop{false};
		std::atomic<bool> done{false};
		std::mutex mu;
		std::condition_variable cv;
		std::thread th([&] {
			std::unique_lock lk(mu);
			cv.wait(lk, [&] { return stop.load(); });
			done.store(true);
			lk.unlock();
			cv.notify_all();
		});
		stop.store(true);
		cv.notify_all();
		Expect(JoinOrDetach(th, done, cv, mu, kWriterJoinMs), "writer join succeeds when the worker stops");
		Expect(!th.joinable(), "joined thread is not joinable");

		std::atomic<bool> done2{false};
		std::mutex mu2;
		std::condition_variable cv2;
		std::thread stuck([] { std::this_thread::sleep_for(std::chrono::seconds(2)); });
		const auto t0 = std::chrono::steady_clock::now();
		Expect(!JoinOrDetach(stuck, done2, cv2, mu2, 50), "writer join detaches after the bounded wait");
		const auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
			std::chrono::steady_clock::now() - t0).count();
		Expect(ms < 400, "timeout detaches instead of joining the stuck worker");
		Expect(!stuck.joinable(), "timed-out worker is detached");

		std::atomic<bool> finished{false};
		std::thread doneTh([&] { finished.store(true); });
		while (!finished.load())
			std::this_thread::sleep_for(std::chrono::milliseconds(1));
		Expect(doneTh.joinable(), "a finished worker stays joinable");
		Expect(RebindDoneWriter(doneTh, true), "EnsureWriter joins a finished worker");
		Expect(!doneTh.joinable(), "the finished worker is not joinable after rebind");
		std::thread liveTh([] { std::this_thread::sleep_for(std::chrono::milliseconds(200)); });
		Expect(!RebindDoneWriter(liveTh, false), "EnsureWriter does not join a live worker");
		liveTh.join();
	}

	{
		struct WriterHarness {
			std::thread th;
			std::atomic<bool> live{false};
			std::atomic<bool> started{false};
			std::atomic<bool> stop{false};
			std::atomic<bool> done{false};
			std::atomic<bool> req{false};
			std::atomic<int> writes{0};
			std::mutex mu;
			std::condition_variable cv;

			void Worker()
			{
				try {
					for (;;) {
						std::unique_lock lk(mu);
						cv.wait_for(lk, std::chrono::milliseconds(50), [&] {
							return stop.load() || req.load();
						});
						const bool st = stop.load();
						const bool wr = req.load();
						if (wr) {
							req.store(false);
							writes.fetch_add(1);
						}
						lk.unlock();
						if (st && !req.load()) break;
					}
				} catch (...) {
				}
				done.store(true);
				live.store(false);
				started.store(false);
				cv.notify_all();
			}

			bool Ensure()
			{
				if (!WriterStartAllowed(live.load(), started.load())) return false;
				if (!RebindDoneWriter(th, done.load())) return false;
				started.store(true);
				live.store(true);
				stop.store(false);
				done.store(false);
				try {
					th = std::thread([this] { Worker(); });
				} catch (...) {
					started.store(false);
					live.store(false);
					return false;
				}
				return true;
			}

			void RequestWrite()
			{
				Ensure();
				{
					std::lock_guard lk(mu);
					req.store(true);
				}
				cv.notify_one();
			}

			void Shutdown()
			{
				RequestWrite();
				if (ShutdownWriterSetsStop()) {
					stop.store(true);
					cv.notify_all();
				}
			}

			bool WaitWrites(int a_n, int a_ms)
			{
				const auto t0 = std::chrono::steady_clock::now();
				while (writes.load() < a_n) {
					if (std::chrono::duration_cast<std::chrono::milliseconds>(
							std::chrono::steady_clock::now() - t0).count() > a_ms)
						return false;
					std::this_thread::sleep_for(std::chrono::milliseconds(5));
				}
				return true;
			}

			~WriterHarness()
			{
				stop.store(true);
				cv.notify_all();
				if (th.joinable()) {
					if (done.load()) {
						try { th.join(); } catch (...) {}
					} else {
						try { th.detach(); } catch (...) {}
					}
				}
			}
		};

		{
			WriterHarness rt3;
			rt3.RequestWrite();
			Expect(rt3.WaitWrites(1, 1000), "RT3 first write runs");
			rt3.Shutdown();
			Expect(rt3.live.load() || !rt3.stop.load(), "Y14 shutdown leaves the worker running");
			Expect(!rt3.stop.load(), "Y14 shutdown does not set stop");
			rt3.RequestWrite();
			Expect(rt3.WaitWrites(2, 1000), "RT3 a write after shutdown does not terminate");
			Expect(rt3.live.load(), "RT3 worker is still live after the follow-up write");
		}
		{
			WriterHarness rt4;
			rt4.RequestWrite();
			Expect(rt4.WaitWrites(1, 1000), "RT4 first write runs");
			rt4.Shutdown();
			rt4.Shutdown();
			Expect(rt4.WaitWrites(2, 1000), "RT4 two shutdowns (kBegin then kSaveCompleted) do not terminate");
			Expect(!rt4.stop.load(), "RT4 two shutdowns do not stop the worker");
			Expect(rt4.live.load(), "RT4 worker is still live after two shutdowns");
		}
		{
			WriterHarness rt5;
			rt5.RequestWrite();
			Expect(rt5.WaitWrites(1, 1000), "RT5 first write runs");
			rt5.stop.store(true);
			rt5.cv.notify_all();
			const auto t0 = std::chrono::steady_clock::now();
			while (!rt5.done.load()) {
				if (std::chrono::duration_cast<std::chrono::milliseconds>(
						std::chrono::steady_clock::now() - t0).count() > 1000)
					break;
				std::this_thread::sleep_for(std::chrono::milliseconds(5));
			}
			Expect(rt5.done.load(), "RT5 worker finished");
			Expect(rt5.th.joinable(), "RT5 finished worker stays joinable");
			rt5.RequestWrite();
			Expect(rt5.WaitWrites(2, 1000), "RT5 rebind after a finished joinable worker does not terminate");
		}
	}

	{
		TestNoDeleteScannerSelf();
		const auto root = RepoRoot();
		std::vector<std::filesystem::path> srcs;
		CollectSrcFiles(root / "src", srcs);
		CollectSrcFiles(root / "include", srcs);
		Expect(!srcs.empty(), "scanned src/ for file-erase APIs");
		for (const auto& p : srcs) {
			std::ifstream f(p, std::ios::binary);
			std::string t((std::istreambuf_iterator<char>(f)), std::istreambuf_iterator<char>());
			ExpectNoDeleteCalls(t, p.lexically_relative(root).generic_string());
		}
		if (HaveRepo()) {
			const auto hdr = Slurp("src/hz_msglog.h");
			const auto main = Slurp("src/main.cpp");
			const auto as = Slurp("actionscript/horizon_block.as");
			Expect(hdr.find("cancelled") == std::string::npos, "Message Log uses canceled spelling");
			Expect(hdr.find("SaveEmptyBoth") != std::string::npos, "Clear history writes empty main and bak");
			Expect(hdr.find("FolderPathDisplay") != std::string::npos, "Log exposes a display folder path");
			Expect(main.find("HidePreset") != std::string::npos, "F11 hides a saved preset instead of erasing it");
			Expect(main.find("FormatHiddenPresetLines") != std::string::npos,
				"hidden preset ids are one encoded key each");
			Expect(main.find("UndoReady=") != std::string::npos, "undo ready is stored in state.ini");
			{
				const auto wa = main.find("inline bool WriteAtomic");
				const auto next = main.find("inline bool Compose", wa);
				const auto body = wa != std::string::npos && next > wa ? main.substr(wa, next - wa) : std::string();
				Expect(body.find("ios::trunc") != std::string::npos, "settings writer overwrites a leftover tmp");
				Expect(body.find("HzfReplace") != std::string::npos, "settings writer uses MoveFileExW replace");
			}
			Expect(main.find("MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH") != std::string::npos,
				"atomic replace uses REPLACE_EXISTING and WRITE_THROUGH");
			Expect(main.find("g_mlWSkipped") != std::string::npos, "stale skips are tracked separately");
			{
				const auto wr = main.find("void MsglogWriter()");
				const auto ens = main.find("void MsglogEnsureWriter()", wr);
				const auto body = wr != std::string::npos && ens > wr ? main.substr(wr, ens - wr) : std::string();
				const auto skipAt = body.find("WriteRun::Skipped");
				const auto noteAt = body.find("NoteWorkerSave");
				Expect(skipAt != std::string::npos && noteAt != std::string::npos && skipAt < noteAt,
					"a skipped write is not reported as a successful save");
				Expect(body.find("g_mlWSkipped.store(true)") != std::string::npos,
					"a skipped write sets the skip flag");
			}
			Expect(as.find("REMOVE FROM LIST") != std::string::npos, "F11 button hides a saved preset");
			Expect(as.find("pdir") != std::string::npos, "F11 can show the preset folder path");
			{
				const auto emptyAt = hdr.find("bool SaveEmptyBoth");
				const auto next = hdr.find("private:", emptyAt);
				const auto body = emptyAt != std::string::npos && next > emptyAt
					? hdr.substr(emptyAt, next - emptyAt) : std::string();
				const auto mainAt = body.find("WriteAtomicKeepTmp(path, body)");
				const auto bakAt = body.find("WriteAtomicKeepTmp(bak, body)");
				Expect(mainAt != std::string::npos && bakAt != std::string::npos && mainAt < bakAt,
					"Clear writes the empty main file before the bak");
			}
			{
				const auto clr = main.find("void MsglogClearHistory()");
				const auto next = main.find("std::vector<hzlog::OtherCharacter> MsglogListOthers()", clr);
				const auto body = clr != std::string::npos && next > clr
					? main.substr(clr, next - clr) : std::string();
				Expect(body.find("FileStore") == std::string::npos
					&& body.find("SaveEmptyBoth") == std::string::npos
					&& body.find("fileGate.mu") == std::string::npos,
					"DLL Clear history does not write or wait on the game thread");
				Expect(body.find("BumpCancel") != std::string::npos, "DLL Clear bumps the cancel seq first");
				Expect(body.find("g_mlWrites.OnClear") != std::string::npos,
					"DLL Clear goes through the coordinator");
				Expect(body.find("persist") != std::string::npos, "DLL Clear checks Persist before queueing");
			}
			{
				const auto wr = main.find("void MsglogRequestWrite(");
				const auto next = main.find("bool MsglogQueueWriteJob", wr);
				const auto body = wr != std::string::npos && next > wr
					? main.substr(wr, next - wr) : std::string();
				Expect(body.find("fileGate.mu") == std::string::npos,
					"RequestWrite never takes fileGate.mu");
				Expect(body.find("g_mlWrites.RequestWrite") != std::string::npos
					|| body.find("g_mlWrites.OnQuit") != std::string::npos,
					"RequestWrite asks the coordinator");
				Expect(body.find("job.emptyClear = job.snap.entries.empty()") == std::string::npos,
					"emptyClear is not assigned from a bare empty snapshot");
				Expect(body.find("ShouldQueueWrite(false, false, false") == std::string::npos,
					"RequestWrite does not call the guard with constants");
				Expect(body.find("RequestWrite(key, snap, a_force,") == std::string::npos
					&& body.find("a_holdFlush") == std::string::npos,
					"holdFlush is not a RequestWrite caller literal");
				Expect(body.find("StampLastPlayed") != std::string::npos, "lastPlayedTs is stamped on write");
				const auto stampAt = body.find("StampLastPlayed");
				const auto snapAt = body.find("Snapshot()");
				Expect(stampAt != std::string::npos && snapAt != std::string::npos && stampAt < snapAt,
					"lastPlayedTs is set before Snapshot");
				const auto holdAt = body.find("if (g_ml.persistHold) return;");
				const auto quitAt = body.find("OnQuit");
				Expect(holdAt != std::string::npos && quitAt != std::string::npos && holdAt < quitAt,
					"persistHold guards the quit write too");
				Expect(body.find("GetTickCount64(), 0)") == std::string::npos
					&& body.find("RetryBackoffMs") != std::string::npos,
					"RequestWrite uses the per-key backoff, not 0");
			}
			{
				const auto wr = main.find("void MsglogWriter()");
				const auto ens = main.find("void MsglogEnsureWriter()", wr);
				const auto body = wr != std::string::npos && ens > wr
					? main.substr(wr, ens - wr) : std::string();
				Expect(body.find("ApplyDiskWrite") != std::string::npos,
					"the writer uses ApplyDiskWrite");
			}
			{
				const auto q = main.rfind("bool MsglogQueueWriteJob(MlWriteJob a_job)");
				const auto next = main.find("void MsglogShutdownWriter()", q);
				const auto body = q != std::string::npos && next > q
					? main.substr(q, next - q) : std::string();
				Expect(body.find("DecideQueuedWrite") == std::string::npos,
					"the queue helper does not re-decide; the coordinator already did");
				Expect(body.find("clearFirst") == std::string::npos,
					"QueueWriteJob does not rewrite clearFirst");
				Expect(body.find("KeepQueuedClear") == std::string::npos,
					"the queue helper does not use KeepQueuedClear");
			}
			{
				const auto rs = main.find("inline State ReadState");
				const auto ws = main.find("inline bool WriteState", rs);
				const auto body = rs != std::string::npos && ws > rs
					? main.substr(rs, ws - rs) : std::string();
				Expect(body.find("MergeHiddenPresetState") != std::string::npos,
					"ReadState merges HiddenN with legacy HiddenPresets");
				Expect(body.find("if (s.hiddenPresets.empty())") == std::string::npos,
					"ReadState does not drop legacy ids when HiddenN exists");
			}
			{
				const auto saveAt = hdr.find("bool Save(const LogState& a_state)");
				const auto emptyFn = hdr.find("bool SaveEmptyBoth");
				const auto body = saveAt != std::string::npos && emptyFn > saveAt
					? hdr.substr(saveAt, emptyFn - saveAt) : std::string();
				Expect(body.find("SaveEmptyBoth") == std::string::npos,
					"Save does not treat every empty snapshot as a Clear");
			}
			Expect(hdr.find("TakeLaunchSess") != std::string::npos,
				"launch session is pinned per character key");
			Expect(hdr.find("DecideQueuedWrite") != std::string::npos,
				"queue decisions live in the header");
			Expect(hdr.find("class MsglogWriteCoordinator") != std::string::npos,
				"writer-side state lives in MsglogWriteCoordinator");
			Expect(hdr.find("PollSkipsRetry") != std::string::npos,
				"Poll halves live in PollSkipsRetry");
			{
				const auto pollAt = hdr.find("std::vector<WriteDecision> Poll(");
				const auto nextAt = hdr.find("const std::vector<QueuedWrite>& PendingJobs()");
				const auto body = pollAt != std::string::npos && nextAt > pollAt
					? hdr.substr(pollAt, nextAt - pollAt) : std::string();
				Expect(body.find("PollSkipsRetry") != std::string::npos,
					"Poll uses PollSkipsRetry for both halves");
			}
			Expect(hdr.find("std::map<std::string, int> launchPins") != std::string::npos,
				"launchPins is a map");
			Expect(main.find("g_mlWrites.OnClear") != std::string::npos
				&& main.find("g_mlWrites.OnLoadStart") != std::string::npos
				&& main.find("g_mlWrites.OnHoldFlush") != std::string::npos
				&& main.find("g_mlWrites.OnQuit") != std::string::npos,
				"DLL write path calls coordinator methods");
			Expect(main.find("MsglogQueueWriteJob") != std::string::npos,
				"DLL write jobs go through one queue helper");
			Expect(main.find("killed within a few ms") != std::string::npos,
				"async Clear kill is documented without a join");
		}
	}

	{
		const auto root = TmpRoot();
		Settings s;
		Log log;
		log.Configure(s, root);
		const auto ch = MakeCharacter(0xABCDu, "Sam");
		log.buf.character = ch;
		log.buf.StartSession(100);
		ExpectEqI(log.buf.sess, 1, "first session id is 1");
		ExpectEqI(log.buf.launchSess, 1, "launch session is pinned");
		log.buf.StartSession(200);
		ExpectEqI(log.buf.sess, 1, "session id bumps only once per launch");
		log.Offer(Cap(Kind::Game, "launch row", 50'000));
		Expect(log.Flush(51'000), "seed before mid-launch load");
		LogState loaded;
		std::string notice;
		Expect(log.store->Load(ch.key, loaded, notice), "mid-launch load reads the file");
		loaded.nextSess = 9;
		log.buf.LoadState(std::move(loaded));
		ExpectEqI(log.buf.sess, 1, "a mid-launch load keeps the launch session id");
		log.buf.ResetMemory();
		ExpectEqI(log.buf.launchSess, 1, "ResetMemory keeps the launch session pin");
		ExpectEqI(log.buf.sess, 1, "ResetMemory restores the launch session id");
		LogState afterReset;
		afterReset.nextSess = 9;
		afterReset.character = ch;
		log.buf.LoadState(std::move(afterReset));
		ExpectEqI(log.buf.sess, 1, "a load after ResetMemory still keeps the launch session id");
		ExpectEqI(log.buf.launchSess, 1, "launch session survives every load");

		Entry parked;
		parked.kind = Kind::Game;
		parked.text = "parked before clear";
		parked.ts = 5;
		log.ParkWriteFailure(ch.key, std::vector<Entry>{parked});
		ExpectEqI(static_cast<int>(log.keptHeld.size()), 1, "parked row is held");
		const auto oldGen = log.loadGen;
		Expect(log.ClearHistoryNow(), "Clear history after a park");
		Expect(log.keptHeld.empty(), "Clear history drops parked rows");
		Expect(!log.AcceptLoad(oldGen), "Clear history invalidates an in-flight load");
		log.MergeKeptHeldIfMatch(ch.key);
		Expect(log.buf.entries.empty(), "an in-flight load cannot restore parked rows");
		const auto path = root / "MessageLog" / "MessageLog_0000ABCD.json";
		const auto bak = root / "MessageLog" / "MessageLog_0000ABCD.json.bak";
		Expect(ReadFile(path).find("launch row") == std::string::npos, "Clear emptied the file");
		Expect(ReadFile(bak).find("launch row") == std::string::npos, "Clear emptied the bak");
		auto quitSnap = log.buf.Snapshot();
		FileStore fs(root / "MessageLog");
		Expect(fs.Save(quitSnap), "quit after Clear writes the empty snapshot");
		Expect(ReadFile(path).find("launch row") == std::string::npos, "quit after Clear does not restore old rows");
		Expect(ReadFile(path).find("parked before clear") == std::string::npos,
			"quit after Clear does not restore parked rows");
		Expect(std::filesystem::is_regular_file(path), "quit after Clear may leave an empty file");

		const auto never = root / "no-folder";
		Log getter;
		Settings off;
		off.persist = false;
		getter.Configure(off, never);
		const auto shown = getter.FolderPathDisplay();
		Expect(shown.find("MessageLog") != std::string::npos, "folder path names MessageLog");
		Expect(!std::filesystem::exists(never / "MessageLog"), "folder path getter does not create the folder");

		Log tmpLog;
		tmpLog.Configure(s, root);
		tmpLog.buf.character = MakeCharacter(0xBBBBu, "Barrett");
		const auto tmpPath = root / "MessageLog" / "MessageLog_0000BBBB.json.tmp";
		WriteFile(tmpPath, "STALE_TMP_BODY");
		tmpLog.Offer(Cap(Kind::Game, "fresh row", 80'000));
		Expect(tmpLog.Flush(81'000), "save overwrites a leftover tmp");
		const auto written = ReadFile(root / "MessageLog" / "MessageLog_0000BBBB.json");
		Expect(written.find("STALE_TMP_BODY") == std::string::npos, "stale tmp bytes do not land in the main file");
		Expect(written.find("fresh row") != std::string::npos, "overwrite wrote the new body");

		WriteGate race;
		bool saved = false;
		race.afterCheck = [&] {
			race.BumpCancel("0000ABCD");
		};
		const auto raced = OrderedSave(race, 0, "0000ABCD", [&] {
			saved = true;
			return true;
		});
		Expect(raced == WriteRun::Skipped && !saved, "a cancel between the two checks skips the save");

		WriteGate keys;
		const auto aSeq = keys.LoadCancel("0000AAAA");
		keys.BumpCancel("0000BBBB");
		Expect(!WriteIsCanceled(aSeq, "0000AAAA", keys), "canceling B does not cancel A");
		Expect(WriteIsCanceled(0, "0000BBBB", keys), "B is canceled on its own key");
		bool savedA = false;
		Expect(OrderedSave(keys, aSeq, "0000AAAA", [&] {
			savedA = true;
			return true;
		}) == WriteRun::Saved && savedA, "A still writes after B is canceled");

		std::vector<std::string> emptyOrder;
		Log emptyOrderLog;
		emptyOrderLog.replace = [&](const std::filesystem::path& a_tmp, const std::filesystem::path& a_dst) {
			emptyOrder.push_back(a_dst.filename().string());
			return DefaultReplace(a_tmp, a_dst);
		};
		emptyOrderLog.Configure(s, root);
		emptyOrderLog.buf.character = MakeCharacter(0xCCCCu, "Sam");
		emptyOrderLog.Offer(Cap(Kind::Game, "before empty", 90'000));
		Expect(emptyOrderLog.Flush(91'000), "seed before empty-order clear");
		emptyOrder.clear();
		Expect(emptyOrderLog.ClearHistoryNow(), "Clear history records write order");
		Expect(emptyOrder.size() >= 2, "Clear history writes main and bak");
		if (emptyOrder.size() >= 2) {
			Expect(emptyOrder[0] == "MessageLog_0000CCCC.json", "Clear writes the main file first");
			Expect(emptyOrder[1] == "MessageLog_0000CCCC.json.bak", "Clear writes the bak second");
		}

		Log leave;
		leave.Configure(s, root);
		leave.buf.character = MakeCharacter(0xDDDDu, "Sam");
		leave.Offer(Cap(Kind::Game, "leave on disk", 92'000));
		Expect(leave.Flush(93'000), "seed before persist-off clear");
		const auto leavePath = root / "MessageLog" / "MessageLog_0000DDDD.json";
		const auto leaveBody = ReadFile(leavePath);
		leave.ApplyPersist(false);
		Expect(leave.ClearHistoryNow(), "Persist=0 Clear after a saved file");
		Expect(leave.buf.entries.empty(), "Persist=0 Clear still empties memory");
		Expect(ReadFile(leavePath) == leaveBody, "Persist=0 Clear does not touch the existing file");

		Expect(!DecideWriteEmptyClear(false), "a non-Clear write is not emptyClear");
		Expect(DecideWriteEmptyClear(true), "an explicit Clear is emptyClear");
		Expect(SkipEmptyNonClearWrite(false, true), "an empty non-Clear snapshot is skipped");
		Expect(!SkipEmptyNonClearWrite(true, true), "an explicit Clear is not skipped as empty");
		Expect(RequestWriteBlockedByLoad(true, "0000ABCD", "0000ABCD"),
			"a write is blocked while that key is loading");
		Expect(!RequestWriteBlockedByLoad(true, "0000AAAA", "0000BBBB"),
			"a write for another key is not blocked by a load");
		Expect(!RequestWriteBlockedByLoad(false, "0000ABCD", "0000ABCD"),
			"a write is not blocked when no load is in flight");
		Expect(!ShouldQueueWrite(false, true, true, "0000ABCD", "0000ABCD"),
			"quit during a load is not queued");
		Expect(ShouldQueueWrite(false, false, false, "0000ABCD", ""),
			"a write with rows is queued");
		Expect(ShouldQueueWrite(false, true, false, "0000ABCD", "", true),
			"clearPending allows an empty retry");
		Expect(ShouldQueueWrite(false, false, true, "0000ABCD", "0000ABCD", false, true),
			"a hold-flush write is not blocked by the load guard");

		std::vector<QueuedWrite> q;
		QueuedWrite clearJob;
		clearJob.key = "0000EEEE";
		clearJob.emptyClear = true;
		clearJob.writeSeq = 1;
		ApplyQueuedWrite(q, clearJob);
		QueuedWrite rowJob;
		rowJob.key = "0000EEEE";
		rowJob.hasRows = true;
		rowJob.writeSeq = 2;
		ApplyQueuedWrite(q, rowJob);
		Expect(q.size() == 1 && q[0].hasRows && q[0].clearFirst && q[0].writeSeq == 2,
			"a row job replaces a queued Clear and sets clearFirst");
		QueuedWrite other;
		other.key = "0000FFFF";
		other.emptyClear = true;
		other.writeSeq = 3;
		ApplyQueuedWrite(q, other);
		Expect(q.size() == 2, "a different key keeps its own Clear slot");
		QueuedWrite emptyQuit;
		emptyQuit.key = "0000EEEE";
		emptyQuit.writeSeq = 4;
		ApplyQueuedWrite(q, emptyQuit);
		Expect(q.size() == 2 && q[0].hasRows && q[0].writeSeq == 2,
			"an empty quit does not drop the row job");

		Log quitOver;
		quitOver.Configure(s, root);
		quitOver.buf.character = MakeCharacter(0xEEEEu, "Sam");
		quitOver.Offer(Cap(Kind::Game, "pre-clear rows", 94'000));
		Expect(quitOver.Flush(95'000), "seed before quit-over-clear");
		const auto quitPath = root / "MessageLog" / "MessageLog_0000EEEE.json";
		const auto quitBak = root / "MessageLog" / "MessageLog_0000EEEE.json.bak";
		Expect(ReadFile(quitPath).find("pre-clear rows") != std::string::npos, "main has rows before the quit write");
		auto afterClear = quitOver.buf.Snapshot();
		afterClear.entries.clear();
		Entry kept;
		kept.id = 9;
		kept.kind = Kind::Game;
		kept.text = "row after clear";
		kept.sess = quitOver.buf.sess;
		kept.ts = 96;
		auto rowSnap = afterClear;
		rowSnap.entries.push_back(kept);
		FileStore quitFs(root / "MessageLog", quitOver.replace);
		Expect(ApplyDiskWrite(quitFs, rowSnap, true, false, true),
			"clearFirst then Save writes the new row");
		Expect(ReadFile(quitPath).find("row after clear") != std::string::npos,
			"a row after a queued Clear is on disk");
		Expect(ReadFile(quitPath).find("pre-clear rows") == std::string::npos,
			"pre-clear rows are gone from main");
		Expect(ReadFile(quitBak).find("pre-clear rows") == std::string::npos,
			"bak has no pre-clear rows after clearFirst");
		Expect(ReadFile(quitBak).find("row after clear") == std::string::npos,
			"bak is the emptied file, not the new row");

		const auto loadMain = ReadFile(quitPath);
		const auto loadBak = ReadFile(quitBak);
		auto emptyQuitSnap = afterClear;
		Expect(ApplyDiskWrite(quitFs, emptyQuitSnap, true, false, false),
			"an empty non-Clear write is a no-op");
		Expect(ReadFile(quitPath) == loadMain && ReadFile(quitBak) == loadBak,
			"quit during a load leaves main and bak byte-identical");

		Log restamp;
		restamp.Configure(s, root);
		restamp.buf.character = MakeCharacter(0xFFFFu, "Sam");
		restamp.buf.StartSession(1);
		restamp.buf.sess = 7;
		Entry held;
		held.kind = Kind::Game;
		held.text = "held across switch";
		held.sess = 2;
		held.ts = 1;
		restamp.buf.MergeSession(std::vector<Entry>{held});
		ExpectEqI(restamp.buf.entries.back().sess, 7, "merged rows take the key's launch pin");

		ExpectEqI(NextSessId((std::numeric_limits<int>::max)()), (std::numeric_limits<int>::max)(),
			"session ids clamp at INT_MAX");
		Entry maxE;
		maxE.sess = (std::numeric_limits<int>::max)();
		ExpectEqI(ResolveNextSess((std::numeric_limits<int>::max)(), {}, {maxE}),
			(std::numeric_limits<int>::max)(), "ResolveNextSess does not overflow");

		Log ident;
		ident.Configure(s, root);
		ident.buf.character = MakeCharacter(0x1212u, "Sam");
		ident.Offer(Cap(Kind::Game, "load-file rows", 97'000));
		Expect(ident.Flush(98'000), "seed files before a load-quit");
		ident.Offer(Cap(Kind::Game, "second flush", 99'000));
		Expect(ident.Flush(100'000), "second flush writes bak");
		const auto identPath = root / "MessageLog" / "MessageLog_00001212.json";
		const auto identBak = root / "MessageLog" / "MessageLog_00001212.json.bak";
		WriteFile(identBak, ReadFile(identPath));
		const auto identMain = ReadFile(identPath);
		const auto identBakBody = ReadFile(identBak);
		Expect(identMain == identBakBody, "main and bak start byte-identical");
		auto loadEmpty = ident.buf.Snapshot();
		loadEmpty.entries.clear();
		FileStore identFs(root / "MessageLog", ident.replace);
		ident.loadBusy.store(true);
		Expect(!ShouldQueueWrite(false, true, ident.loadBusy.load(), ident.buf.character.key, ident.buf.character.key),
			"quit during that key's load is not queued");
		Expect(ApplyDiskWrite(identFs, loadEmpty, true, false, false),
			"empty non-Clear during load does not write");
		Expect(ReadFile(identPath) == identMain && ReadFile(identBak) == identBakBody,
			"quit during a load leaves main and bak byte-identical");

		{
			Buffer pinBuf;
			pinBuf.character = MakeCharacter(0x3333u, "Sam");
			pinBuf.StartSession(1);
			ExpectEqI(pinBuf.LaunchPinFor(pinBuf.character.key), 1, "empty first session pins 1");
			LogState later;
			later.character = pinBuf.character;
			later.nextSess = 4;
			Entry late;
			late.id = 10;
			late.kind = Kind::Game;
			late.text = "later-read";
			late.sess = 3;
			later.entries = { late };
			pinBuf.LoadState(std::move(later));
			ExpectEqI(pinBuf.sess, 4, "an unreadable-first pin bumps past later-read ids");
			ExpectEqI(pinBuf.LaunchPinFor(pinBuf.character.key), 4, "the bumped pin is remembered");
		}

		{
			Buffer pruneBuf;
			pruneBuf.character = MakeCharacter(0x4444u, "Sam");
			pruneBuf.StartSession(1);
			Entry future;
			future.id = 1;
			future.kind = Kind::Game;
			future.text = "future row";
			future.gt = 50.0;
			future.sess = 1;
			pruneBuf.entries.push_back(future);
			const int flagged = pruneBuf.Prune(1.0);
			ExpectEqI(flagged, 1, "Decision A: the later-point row is flagged");
			ExpectEqI(static_cast<int>(pruneBuf.entries.size()), 1,
				"Decision A: prune does not drop the later-point row");
			Expect(pruneBuf.entries[0].fromLater, "the kept row is fromLater");
			Expect(!hzlog::PruneEmptiedBuffer(0, pruneBuf.entries.empty()),
				"a later-point mark is not an emptying prune");
			Expect(hzlog::PruneEmptiedBuffer(1, true),
				"the emptying-trim helper still detects a true empty trim");
			MsglogWriteCoordinator pruneCoord;
			pruneCoord.OnPruneEmpty(pruneBuf.character.key);
			Expect(!pruneCoord.ClearPending(pruneBuf.character.key),
				"OnPruneEmpty does not set clearPending");
		}

		std::error_code ec;
		std::filesystem::remove_all(root, ec);
	}

	{
		const auto root = TmpRoot();
		Settings s;
		struct FailNth {
			int failAt = -1;
			int n = 0;
			bool operator()(const std::filesystem::path& a_tmp, const std::filesystem::path& a_dst)
			{
				++n;
				if (failAt > 0 && n == failAt) return false;
				return DefaultReplace(a_tmp, a_dst);
			}
		};

		auto apply = [](FileStore& fs, const WriteDecision& d) {
			if (!d.queue) return false;
			return ApplyDiskWrite(fs, d.emit.snap, d.emit.persist, d.emit.emptyClear, d.emit.clearFirst);
		};

		auto seedRows = [&](const Character& ch, const char* text) {
			Log seed;
			seed.Configure(s, root);
			seed.buf.character = ch;
			seed.Offer(Cap(Kind::Game, text, 110'000));
			Expect(seed.Flush(111'000), "seed rows before coordinator case");
		};

		{
			const auto ch = MakeCharacter(0x6001u, "Sam");
			seedRows(ch, "old clear rows");
			FailNth fail;
			fail.failAt = 1;
			FileStore fs(root / "MessageLog", [&](const auto& t, const auto& d) { return fail(t, d); });
			MsglogWriteCoordinator coord;
			LogState empty;
			empty.character = ch;
			auto d = coord.OnClear(ch.key, empty);
			Expect(d.queue && d.emit.emptyClear, "Clear is queued as emptyClear");
			Expect(coord.ClearPending(ch.key), "clearPending is set when Clear is queued");
			Expect(!apply(fs, d), "Clear replace fails");
			coord.OnWriteResult(ch.key, d.emit.writeSeq, false, &d.emit.snap);
			Expect(coord.ClearPending(ch.key), "clearPending stays until main and bak succeed");
			Expect(!coord.WritePending(ch.key), "writePending clears for the failed Clear seq");
			fail.failAt = -1;
			auto retries = coord.Poll();
			ExpectEqI(static_cast<int>(retries.size()), 1, "failed Clear is retried");
			Expect(retries[0].emit.emptyClear, "retry of a failed Clear is emptyClear");
			Expect(apply(fs, retries[0]), "Clear retry succeeds");
			coord.OnWriteResult(ch.key, retries[0].emit.writeSeq, true);
			Expect(!coord.ClearPending(ch.key), "clearPending clears only after a full success");
			LogState loaded;
			std::string notice;
			FileStore loadFs(root / "MessageLog");
			Expect(loadFs.Load(ch.key, loaded, notice), "restart load after failed-then-retried Clear");
			Expect(loaded.entries.empty(), "restart after a retried Clear has no old rows");
		}

		{
			const auto ch = MakeCharacter(0x6002u, "Sam");
			seedRows(ch, "pre-clearFirst rows");
			FailNth fail;
			fail.failAt = 1;
			FileStore fs(root / "MessageLog", [&](const auto& t, const auto& d) { return fail(t, d); });
			MsglogWriteCoordinator coord;
			LogState empty;
			empty.character = ch;
			auto clr = coord.OnClear(ch.key, empty);
			Expect(clr.queue, "KQ2 Clear is queued");
			LogState rows;
			rows.character = ch;
			Entry kept;
			kept.id = 2;
			kept.kind = Kind::Game;
			kept.text = "row after clear";
			kept.sess = 1;
			rows.entries.push_back(kept);
			auto row = coord.RequestWrite(ch.key, rows, true);
			Expect(row.queue && row.emit.clearFirst && !row.emit.snap.entries.empty(),
				"KQ2: a row job after Clear sets clearFirst");
			Expect(!apply(fs, row), "clearFirst replace fails");
			coord.OnWriteResult(ch.key, row.emit.writeSeq, false, &row.emit.snap);
			fail.failAt = -1;
			auto retries = coord.Poll();
			ExpectEqI(static_cast<int>(retries.size()), 1, "failed clearFirst is retried");
			Expect(retries[0].emit.clearFirst, "retry keeps clearFirst so Save cannot copy old rows to bak");
			Expect(apply(fs, retries[0]), "clearFirst retry succeeds");
			coord.OnWriteResult(ch.key, retries[0].emit.writeSeq, true);
			const auto path = root / "MessageLog" / "MessageLog_00006002.json";
			const auto bak = root / "MessageLog" / "MessageLog_00006002.json.bak";
			Expect(ReadFile(path).find("pre-clearFirst rows") == std::string::npos,
				"clearFirst retry emptied the old main rows");
			Expect(ReadFile(bak).find("pre-clearFirst rows") == std::string::npos,
				"clearFirst retry emptied bak; old rows are not copied");
			WriteFile(path, "CORRUPT{");
			LogState recovered;
			std::string notice;
			FileStore loadFs(root / "MessageLog");
			Expect(loadFs.Load(ch.key, recovered, notice), "restart from bak after clearFirst");
			bool oldBack = false;
			for (const auto& e : recovered.entries)
				if (e.text == "pre-clearFirst rows") oldBack = true;
			Expect(!oldBack, "restart after a failed clearFirst does not bring old rows back");
		}

		{
			const auto ch = MakeCharacter(0x6003u, "Sam");
			seedRows(ch, "load-file rows");
			FileStore fs(root / "MessageLog");
			const auto path = root / "MessageLog" / "MessageLog_00006003.json";
			const auto bak = root / "MessageLog" / "MessageLog_00006003.json.bak";
			WriteFile(bak, ReadFile(path));
			const auto mainBody = ReadFile(path);
			const auto bakBody = ReadFile(bak);
			MsglogWriteCoordinator coord;
			coord.OnLoadStart(ch.key);
			Expect(coord.LoadKey() == ch.key, "OnLoadStart assigns the load key");
			LogState rows;
			rows.character = ch;
			Entry leftover;
			leftover.text = "quit-during-load rows";
			leftover.kind = Kind::Game;
			rows.entries.push_back(leftover);
			auto quit = coord.OnQuit(ch.key, rows);
			Expect(quit.empty(), "a quit during a load is not queued");
			Expect(!coord.WritePending(ch.key), "a skipped quit does not set writePending");
			Expect(ReadFile(path) == mainBody && ReadFile(bak) == bakBody,
				"quit during a load leaves main and bak byte-identical");
		}

		{
			const auto ch = MakeCharacter(0x6004u, "Sam");
			seedRows(ch, "on-disk before hold");
			FileStore fs(root / "MessageLog");
			MsglogWriteCoordinator coord;
			coord.OnLoadStart(ch.key);
			LogState held;
			held.character = ch;
			Entry h;
			h.id = 3;
			h.kind = Kind::Game;
			h.text = "held across load";
			h.sess = 1;
			held.entries.push_back(h);
			coord.OnHoldFlush(ch.key);
			Expect(!coord.LoadBusy(), "OnHoldFlush clears loadBusy before the write");
			auto wr = coord.RequestWrite(ch.key, held, true);
			Expect(wr.queue, "hold-flush write is queued");
			Expect(apply(fs, wr), "hold-flush write lands");
			coord.OnWriteResult(ch.key, wr.emit.writeSeq, true);
			auto quit = coord.OnQuit(ch.key, held);
			if (!quit.empty()) {
				apply(fs, quit[0]);
				coord.OnWriteResult(ch.key, quit[0].emit.writeSeq, true);
			}
			LogState loaded;
			std::string notice;
			Expect(fs.Load(ch.key, loaded, notice), "restart after hold-flush");
			bool found = false;
			for (const auto& e : loaded.entries)
				if (e.text == "held across load") found = true;
			Expect(found, "hold-flush then quit leaves held rows on disk");
		}

		{
			const auto chA = MakeCharacter(0x6005u, "Sam");
			const auto chB = MakeCharacter(0x6006u, "Barrett");
			seedRows(chA, "A rows");
			seedRows(chB, "B rows");
			FailNth fail;
			fail.failAt = 1;
			int writes = 0;
			FileStore fs(root / "MessageLog", [&](const auto& t, const auto& d) {
				++writes;
				if (writes <= 2) return false;
				return DefaultReplace(t, d);
			});
			MsglogWriteCoordinator coord;
			LogState aSnap;
			aSnap.character = chA;
			Entry ae;
			ae.text = "A retry row";
			ae.kind = Kind::Game;
			aSnap.entries.push_back(ae);
			LogState bSnap;
			bSnap.character = chB;
			Entry be;
			be.text = "B retry row";
			be.kind = Kind::Game;
			bSnap.entries.push_back(be);
			auto da = coord.RequestWrite(chA.key, aSnap, true);
			auto db = coord.RequestWrite(chB.key, bSnap, true);
			Expect(da.queue && db.queue, "two keys queue two writes");
			Expect(!apply(fs, da) && !apply(fs, db), "both keys fail");
			coord.OnWriteResult(chA.key, da.emit.writeSeq, false, &da.emit.snap);
			coord.OnWriteResult(chB.key, db.emit.writeSeq, false, &db.emit.snap);
			Expect(!coord.WritePending(chA.key) && !coord.WritePending(chB.key),
				"writePending clears for each failed key");
			Expect(coord.DoneSeq(chA.key) == da.emit.writeSeq
				&& coord.DoneSeq(chB.key) == db.emit.writeSeq,
				"each key keeps its own done-seq");
			auto retries = coord.Poll();
			ExpectEqI(static_cast<int>(retries.size()), 2, "both failed keys are retried");
			bool gotA = false, gotB = false;
			for (const auto& r : retries) {
				if (SameLogKey(r.emit.key, chA.key)) gotA = true;
				if (SameLogKey(r.emit.key, chB.key)) gotB = true;
				Expect(apply(fs, r), "multi-key retry succeeds");
				coord.OnWriteResult(r.emit.key, r.emit.writeSeq, true);
			}
			Expect(gotA && gotB, "retries include both keys");
		}

		{
			const auto chA = MakeCharacter(0x6007u, "Sam");
			const auto chB = MakeCharacter(0x6008u, "Barrett");
			MsglogWriteCoordinator coord;
			LogState a1;
			a1.character = chA;
			a1.nextSess = 3;
			Buffer buf;
			buf.character = chA;
			buf.LoadState(a1);
			buf.StartSession(10);
			const int pinA = buf.sess;
			buf.ResetMemory();
			buf.character = chB;
			LogState b1;
			b1.character = chB;
			b1.nextSess = 5;
			buf.LoadState(b1);
			buf.StartSession(20);
			const int pinB = buf.sess;
			buf.ResetMemory();
			buf.character = chA;
			buf.LoadState(a1);
			buf.StartSession(30);
			ExpectEqI(buf.sess, pinA, "A/B/A keeps A's launch pin");
			ExpectEqI(buf.LaunchPinFor(chB.key), pinB, "A/B/A keeps B's launch pin");
		}

		{
			MsglogWriteCoordinator coord;
			coord.SetPersist(false);
			const auto ch = MakeCharacter(0x6009u, "Sam");
			LogState rows;
			rows.character = ch;
			Entry e;
			e.text = "persist off";
			e.kind = Kind::Game;
			rows.entries.push_back(e);
			Expect(!coord.RequestWrite(ch.key, rows, true).queue, "Persist off writes nothing");
			Expect(!coord.OnClear(ch.key, rows).queue, "Persist off Clear writes nothing");
			Expect(coord.OnQuit(ch.key, rows).empty(), "Persist off quit writes nothing");
		}

		{
			const auto ch = MakeCharacter(0x600Au, "Sam");
			MsglogWriteCoordinator coord;
			LogState rows;
			rows.character = ch;
			Entry e;
			e.text = "queued rows";
			e.kind = Kind::Game;
			rows.entries.push_back(e);
			auto queued = coord.RequestWrite(ch.key, rows, true);
			Expect(queued.queue && coord.WritePending(ch.key),
				"a row write sets writePending from the queue result");
			LogState emptyQuit;
			emptyQuit.character = ch;
			auto skipped = coord.OnQuit(ch.key, emptyQuit);
			Expect(skipped.empty(), "an empty quit does not replace a queued row job");
			Expect(coord.WritePendingSeq(ch.key) == queued.emit.writeSeq,
				"writePending seq stays the queued job, not the skipped quit");
		}

		{
			const auto ch = MakeCharacter(0x600Bu, "Sam");
			seedRows(ch, "R5 old rows");
			FailNth fail;
			fail.failAt = 1;
			FileStore fs(root / "MessageLog", [&](const auto& t, const auto& d) { return fail(t, d); });
			MsglogWriteCoordinator coord;
			LogState live;
			live.character = ch;
			Entry w0e;
			w0e.text = "W0 in flight";
			w0e.kind = Kind::Game;
			live.entries.push_back(w0e);
			auto w0 = coord.RequestWrite(ch.key, live, true);
			Expect(w0.queue && w0.emit.writeSeq == 1, "R5 W0 is seq 1");
			LogState empty;
			empty.character = ch;
			auto clr = coord.OnClear(ch.key, empty);
			Expect(clr.queue && clr.emit.writeSeq == 2 && clr.emit.emptyClear, "R5 Clear is seq 2");
			Expect(coord.ClearSeq(ch.key) == 2, "R5 clearSeq is the Clear");
			coord.OnWriteResult(ch.key, w0.emit.writeSeq, true);
			Expect(coord.ClearPending(ch.key), "N17: W0 OK does not drop clearPending");
			Expect(!apply(fs, clr), "R5 Clear replace fails");
			coord.OnWriteResult(ch.key, clr.emit.writeSeq, false, &clr.emit.snap);
			fail.failAt = -1;
			auto retries = coord.Poll();
			ExpectEqI(static_cast<int>(retries.size()), 1, "R5 failed Clear is retried");
			Expect(retries[0].emit.emptyClear, "R5 retry is emptyClear, not a dropped empty snap");
			Expect(apply(fs, retries[0]), "R5 Clear retry succeeds");
			coord.OnWriteResult(ch.key, retries[0].emit.writeSeq, true);
			LogState loaded;
			std::string notice;
			FileStore loadFs(root / "MessageLog");
			Expect(loadFs.Load(ch.key, loaded, notice), "R5 restart after Clear");
			Expect(loaded.entries.empty(), "R5 restart has no old rows");
		}

		{
			const auto ch = MakeCharacter(0x600Cu, "Sam");
			seedRows(ch, "R5cf old rows");
			FailNth fail;
			fail.failAt = 1;
			FileStore fs(root / "MessageLog", [&](const auto& t, const auto& d) { return fail(t, d); });
			MsglogWriteCoordinator coord;
			LogState live;
			live.character = ch;
			Entry w0e;
			w0e.text = "W0 in flight";
			w0e.kind = Kind::Game;
			live.entries.push_back(w0e);
			auto w0 = coord.RequestWrite(ch.key, live, true);
			LogState empty;
			empty.character = ch;
			(void)coord.OnClear(ch.key, empty);
			LogState rows;
			rows.character = ch;
			Entry kept;
			kept.text = "after clear";
			kept.kind = Kind::Game;
			rows.entries.push_back(kept);
			auto cf = coord.RequestWrite(ch.key, rows, true);
			Expect(cf.queue && cf.emit.clearFirst, "R5 clearFirst job is queued");
			coord.OnWriteResult(ch.key, w0.emit.writeSeq, true);
			Expect(coord.ClearPending(ch.key), "N17: W0 OK keeps clearPending for clearFirst");
			Expect(!apply(fs, cf), "R5 clearFirst replace fails");
			coord.OnWriteResult(ch.key, cf.emit.writeSeq, false, &cf.emit.snap, false, true);
			fail.failAt = -1;
			auto retries = coord.Poll();
			ExpectEqI(static_cast<int>(retries.size()), 1, "R5 clearFirst is retried");
			Expect(retries[0].emit.clearFirst, "R5 retry keeps clearFirst");
			Expect(apply(fs, retries[0]), "R5 clearFirst retry succeeds");
			coord.OnWriteResult(ch.key, retries[0].emit.writeSeq, true);
			const auto bak = root / "MessageLog" / "MessageLog_0000600C.json.bak";
			Expect(ReadFile(bak).find("R5cf old rows") == std::string::npos,
				"R5 clearFirst retry does not copy old main to bak");
		}

		{
			WriteEmit e;
			e.emptyClear = false;
			e.clearFirst = true;
			bool emptyClear = false;
			bool clearFirst = false;
			AssignEmitFlags(emptyClear, clearFirst, e);
			Expect(clearFirst && !emptyClear, "P1d: AssignEmitFlags keeps clearFirst");
			std::vector<QueuedWrite> q;
			QueuedWrite neu;
			neu.key = "0000600D";
			neu.hasRows = true;
			neu.clearFirst = true;
			neu.writeSeq = 1;
			ApplyQueuedWrite(q, neu);
			Expect(q.size() == 1 && q[0].clearFirst, "P1a: incoming clearFirst survives an empty pending queue");
		}

		{
			const auto ch = MakeCharacter(0x600Eu, "Sam");
			MsglogWriteCoordinator coord;
			coord.OnLoadStart(ch.key);
			LogState rows;
			rows.character = ch;
			Entry e;
			e.text = "held";
			e.kind = Kind::Game;
			rows.entries.push_back(e);
			coord.OnHoldFlush(ch.key);
			auto wr = coord.RequestWrite(ch.key, rows, true);
			Expect(wr.queue, "W1/W2: holdFlush is coordinator state, not a caller literal");
		}

		{
			const auto chA = MakeCharacter(0x600Fu, "Sam");
			const auto chB = MakeCharacter(0x6010u, "Barrett");
			MsglogWriteCoordinator coord;
			coord.OnLoadStart(chB.key);
			Expect(coord.LoadBusy() && coord.LoadKey() == chB.key, "W7: OnLoadStart assigns loadBusy and loadKey");
			coord.OnHoldFlush(chA.key);
			Expect(coord.LoadBusy() && coord.LoadKey() == chB.key,
				"P2-A: hold-flush of A does not clear B's in-flight load");
			LogState rows;
			rows.character = chB;
			Entry e;
			e.text = "B rows";
			e.kind = Kind::Game;
			rows.entries.push_back(e);
			Expect(coord.OnQuit(chB.key, rows).empty(), "W8: quit during B's load is skipped");
		}

		{
			const auto ch = MakeCharacter(0x6011u, "Sam");
			MsglogWriteCoordinator coord;
			LogState rows;
			rows.character = ch;
			Entry e;
			e.text = "row";
			e.kind = Kind::Game;
			rows.entries.push_back(e);
			Expect(!coord.RequestWrite(ch.key, rows, false).queue,
				"W9/W12: RequestWrite without OnRow does not queue a non-force write");
			coord.OnRow(ch.key);
			Expect(coord.RequestWrite(ch.key, rows, false).queue,
				"W9/W12: OnRow plus a write is accepted");
		}

		{
			MsglogWriteCoordinator coord;
			LogState empty;
			empty.character.key = "DD1C9DDC-n";
			auto d = coord.OnClear(empty.character.key, empty);
			Expect(!d.queue && !coord.ClearPending(empty.character.key),
				"N10: Clear is never queued for a key that fails ValidLogKey");
		}

		{
			const auto ch = MakeCharacter(0x6012u, "Sam");
			MsglogWriteCoordinator coord;
			LogState rows;
			rows.character = ch;
			Entry e;
			e.text = "pending";
			e.kind = Kind::Game;
			rows.entries.push_back(e);
			auto w = coord.RequestWrite(ch.key, rows, true);
			Expect(coord.WritePending(ch.key), "P2-E: queued job is pending");
			coord.OnWriteResult(ch.key, w.emit.writeSeq, false, nullptr, true);
			Expect(!coord.WritePending(ch.key), "P2-E: a canceled job clears writePending");
		}

		{
			const auto chA = MakeCharacter(0x6013u, "Sam");
			const auto chB = MakeCharacter(0x6014u, "Barrett");
			MsglogWriteCoordinator coord;
			LogState emptyA;
			emptyA.character = chA;
			LogState emptyB;
			emptyB.character = chB;
			Expect(coord.OnClear(chA.key, emptyA).queue, "P2-F Clear A");
			Expect(coord.OnClear(chB.key, emptyB).queue, "P2-F Clear B");
			LogState cur;
			cur.character = chA;
			auto quits = coord.OnQuit(chA.key, cur);
			bool gotA = false, gotB = false;
			for (const auto& q : quits) {
				if (SameLogKey(q.emit.key, chA.key) && q.emit.emptyClear) gotA = true;
				if (SameLogKey(q.emit.key, chB.key) && q.emit.emptyClear) gotB = true;
			}
			Expect(gotA && gotB, "P2-F: quit flushes a pending Clear for every key");
		}

		{
			const auto chA = MakeCharacter(0x6015u, "Sam");
			const auto chB = MakeCharacter(0x6016u, "Barrett");
			MsglogWriteCoordinator coord;
			LogState aSnap;
			aSnap.character = chA;
			Entry ae;
			ae.text = "A";
			ae.kind = Kind::Game;
			aSnap.entries.push_back(ae);
			LogState bSnap;
			bSnap.character = chB;
			Entry be;
			be.text = "B";
			be.kind = Kind::Game;
			bSnap.entries.push_back(be);
			auto da = coord.RequestWrite(chA.key, aSnap, true);
			coord.OnWriteResult(chA.key, da.emit.writeSeq, false, &da.emit.snap, false, false, 0);
			Expect(coord.RetryBackoffMs(chA.key) >= kRetryMsMin, "A has its own backoff");
			auto db = coord.RequestWrite(chB.key, bSnap, true);
			Expect(db.queue, "one key's failure does not block another key's write");
			Expect(coord.RetryBackoffMs(chB.key) == 0, "B's backoff stays 0");
			Expect(coord.Poll(0).empty(), "A is not retried before its backoff");
			ExpectEqI(static_cast<int>(coord.Poll(static_cast<std::uint64_t>(kRetryMsMin)).size()), 1,
				"A retries on its own timer");
		}

		{
			const auto ch = MakeCharacter(0x6017u, "Sam");
			MsglogWriteCoordinator coord;
			LogState oldSnap;
			oldSnap.character = ch;
			Entry oldE;
			oldE.text = "older fail snap";
			oldE.kind = Kind::Game;
			oldSnap.entries.push_back(oldE);
			auto failed = coord.RequestWrite(ch.key, oldSnap, true);
			Expect(failed.queue, "P2-H first write queues");
			coord.OnWriteResult(ch.key, failed.emit.writeSeq, false, &failed.emit.snap);
			LogState newSnap;
			newSnap.character = ch;
			Entry newE;
			newE.text = "newer queued rows";
			newE.kind = Kind::Game;
			newSnap.entries.push_back(newE);
			auto newer = coord.RequestWrite(ch.key, newSnap, true);
			Expect(newer.queue, "P2-H a newer write queues after the fail");
			Expect(coord.WritePending(ch.key), "P2-H newer job is pending");
			auto retries = coord.Poll();
			Expect(retries.empty(), "P2-H Poll does not replace a newer queued job with failSnap");
			Expect(coord.WritePendingSeq(ch.key) == newer.emit.writeSeq,
				"P2-H the newer write seq stays queued");
		}

		{
			Expect(PollSkipsRetry(true, false), "writePending alone skips a Poll retry");
			Expect(PollSkipsRetry(false, true), "a queued job alone skips a Poll retry");
			Expect(!PollSkipsRetry(false, false), "Poll retries when neither half is set");
			Expect(PollSkipsRetry(true, true), "both Poll guard halves together still skip");
		}

		{
			Expect(ScaleformThreadOk(0, 99), "unknown UI tid allows the call");
			Expect(ScaleformThreadOk(7, 7), "matching UI tid is allowed");
			Expect(!ScaleformThreadOk(7, 8), "a job tid is not the UI tid");
			Expect(MsglogTakeMovieAllowed(false, false, true), "take-log runs when messages are up");
			Expect(!MsglogTakeMovieAllowed(true, false, true), "take-log skips LoadingMenu");
			Expect(!MsglogTakeMovieAllowed(false, true, true), "take-log skips MainMenu");
			Expect(!MsglogTakeMovieAllowed(false, false, false), "take-log skips a missing movie");
			Expect(kTakeLogMinMs == 250, "take-log waits 250 ms");
			Expect(MsglogTakeMovieDue(250, 250), "take-log is due at the next tick");
			Expect(!MsglogTakeMovieDue(249, 250), "take-log waits out the interval");
			{
				int loadingRoot = 11;
				int overlayWnd = 22;
				int hudRoot = 33;
				int otherMovie = 44;
				UiTidRecorder rec;
				rec.HintWindowOwner(static_cast<std::uint32_t>(overlayWnd));
				rec.OnMenuCreated("LoadingMenu", &loadingRoot, static_cast<std::uint32_t>(overlayWnd));
				rec.OnAdvance(&loadingRoot, static_cast<std::uint32_t>(overlayWnd));
				ExpectEqI(static_cast<int>(rec.tid), 0, "a non-HUD menu create does not record the tid");
				rec.OnMenuCreated("HUDMenu", &hudRoot, static_cast<std::uint32_t>(overlayWnd));
				rec.OnAdvance(&otherMovie, static_cast<std::uint32_t>(overlayWnd));
				ExpectEqI(static_cast<int>(rec.tid), 0, "a foreign window owner does not record the tid");
				rec.OnAdvance(&hudRoot, static_cast<std::uint32_t>(hudRoot));
				ExpectEqI(static_cast<int>(rec.tid), hudRoot, "the HUD root advance records the tid");
				ExpectEq(rec.source ? rec.source : "", kUiTidSourceHudRoot, "the record source is hud-root-advance");
				rec.OnAdvance(&hudRoot, 99);
				ExpectEqI(static_cast<int>(rec.tid), 99, "a later HUD-root tid self-heals");
				Expect(rec.healed, "self-heal latches");
			}
			Expect(!UiTidHintAdopts(UiTidHint::WindowOwner, false), "window owner never adopts");
			Expect(!UiTidHintAdopts(UiTidHint::AnyMenu, true), "any-menu never adopts even with a stored root");
			Expect(UiTidHintAdopts(UiTidHint::HudRootAdvance, true), "HUD root advance adopts");
			Expect(!UiTidHintAdopts(UiTidHint::HudRootAdvance, false), "a non-HUD advance does not adopt");
			Expect(HookTidAllowsPoll(7, 7), "matching tid may poll");
			Expect(!HookTidAllowsPoll(0, 7), "unknown tid may not poll");
			Expect(!HookTidAllowsPoll(7, 8), "a mismatched tid may not poll");
			Expect(HookOrigStored(reinterpret_cast<const void*>(1), reinterpret_cast<const void*>(2)),
				"a real original is stored");
			Expect(!HookOrigStored(nullptr, reinterpret_cast<const void*>(2)), "a null original is rejected");
			Expect(!HookOrigStored(reinterpret_cast<const void*>(2), reinterpret_cast<const void*>(2)),
				"a self original is rejected");
			Expect(hzaddr::AddrSlotRetry(hzaddr::kSlotPending), "preload-pending is not a miss");
			Expect(!hzaddr::AddrSlotMiss(hzaddr::kSlotPending), "pending does not latch missing");
			Expect(hzaddr::AddrSlotMiss(-1), "a real miss still latches");
			ExpectEqI(TakeLogDroppedCount("drop|12"), 12, "take-log drop marker parses");
			ExpectEqI(TakeLogDroppedCount("quest|Q|Go"), -1, "a forward line is not a drop marker");
			ExpectEqI(kTakeLogHardCap, 500, "take-log hard cap is 500");
			ExpectEqI(kTakeLogCap, 40, "take-log cap is 40");
			ExpectEqI(TakeLogBatchCount(0), 0, "an empty take-log queue takes nothing");
			ExpectEqI(TakeLogBatchCount(12), 12, "a short take-log queue is taken whole");
			ExpectEqI(TakeLogBatchCount(40), 40, "a full take-log queue takes the cap");
			ExpectEqI(TakeLogBatchCount(55), 40, "a long take-log queue takes the cap");
			Expect(TakeLogHasRemainder(55, 40), "lines past the cap stay for the next take");
			Expect(!TakeLogHasRemainder(40, 40), "a full take with no extra has no remainder");
			{
				std::vector<int> q;
				for (int i = 0; i < 55; ++i) q.push_back(i);
				const auto first = TakeLogBatch(q);
				ExpectEqI(static_cast<int>(first.size()), 40, "first take-log batch is 40");
				ExpectEqI(static_cast<int>(q.size()), 15, "take-log remainder stays on the queue");
				ExpectEqI(first.front(), 0, "take-log keeps oldest first");
				ExpectEqI(q.front(), 40, "take-log remainder starts after the cap");
				const auto second = TakeLogBatch(q);
				ExpectEqI(static_cast<int>(second.size()), 15, "second take-log batch is the remainder");
				Expect(q.empty(), "the last take-log remainder drains");
			}
			Expect(ClearSessionWrites(true, true, false, true), "emptied Clear writes when Persist is on");
			Expect(!ClearSessionWrites(true, true, true, true), "emptied Clear skips write while persistHold");
			Expect(!ClearSessionWrites(true, false, false, true), "emptied Clear skips write when Persist is off");
			Expect(!ClearSessionWrites(false, true, false, true), "a non-empty Clear is not an OnClear write");
			Expect(PromoteIdShouldQueue(false, true, true, true), "PromoteId queues when idle");
			Expect(!PromoteIdShouldQueue(true, true, true, true), "PromoteId dedupes while recoverBusy");
			ExpectEqI(FloorTextPx(12, kMinTextPx), 13, "TextScale 0.90 cannot drop 13 to 12");
			ExpectEqI(FloorTextPx(14, kMinTextPx), 14, "a size already above the floor stays");
			ExpectEqI(kMinTextPx, 13, "the text floor is 13 px");
			ExpectEqI(ChipScrollX(0, 400, 200, 250, 40), 90, "chip scroll brings a right-hand chip into view");
			ExpectEqI(ChipScrollX(80, 400, 200, 10, 40), 10, "chip scroll brings a left-hand chip into view");
			ExpectEqI(ChipScrollX(0, 100, 200, 0, 40), 0, "chip scroll does not go negative");
			Expect(HookOnceFlagBlocksRetry(true), "a second hook install is skipped");
			Expect(!HookOnceFlagBlocksRetry(false), "the first hook install runs");
			Expect(EngineCacheNeedsMutex(true), "the engine cache is locked across threads");
			Expect(!EngineCacheNeedsMutex(false), "a single-thread cache would not need the mutex");
			Expect(kEngineRefreshMinMs >= 100 && kEngineRefreshMinMs <= 250, "engine refresh is throttled 100-250 ms");
			Expect(kHudSafeCacheMs >= 100 && kHudSafeCacheMs <= 250, "HudSafe is cached 100-250 ms");
		}

		{
			MsglogWriteCoordinator coord;
			const auto ch = MakeCharacter(0x6018u, "Sam");
			coord.OnLoadStart(ch.key);
			Expect(coord.LoadBusy(), "loadBusy is set on start");
			coord.OnLoadStart(ch.key);
			coord.OnLoadApplied(ch.key, 1);
			Expect(coord.LoadBusy(), "a stale load result does not clear a newer load");
			coord.OnLoadApplied(ch.key, 2);
			Expect(!coord.LoadBusy(), "the matching load gen clears loadBusy");
		}

		std::error_code ec2;
		std::filesystem::remove_all(root, ec2);
	}

	if (g_fails) {
		std::cerr << g_fails << " failed\n";
		return 1;
	}
	std::cout << "message log tests passed\n";
	return 0;
}
