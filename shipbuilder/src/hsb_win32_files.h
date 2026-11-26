#pragma once

// Purpose: the plugin's Win32 file calls: capped whole-file reads, flushed write-and-rename,
//    folder creation, and the pill profile's disk for hsb_profile.h's rules. In one header so
//    the plugin and tests/profile_disk_test.cpp run the same code on a real disk.
// Inputs: wide paths the caller built from its own folders. Outputs: file text and success
//    flags. Rules: nothing is deleted; a new file (WriteNew) and a set-aside never replace
//    what is already there; every profile file is gated by hsb::BuilderFileMayTouch before it
//    is opened.
// Dependencies: Win32 and the CRT (_wfopen_s, _commit); hsb_files.h; hsb_profile.h.
// Author: Moragar. Last modified: 2026-11-08.

#include "hsb_files.h"
#include "hsb_profile.h"

#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <io.h>

#include <cstdio>
#include <string>
#include <string_view>
#include <utility>

namespace hsb::w32 {

// For the gates and the log: non-ASCII becomes '?', so Documents folders with such names
// still pass the gates' ASCII checks.
inline std::string NarrowPath(const std::wstring& path)
{
	std::string out;
	out.reserve(path.size());
	for (wchar_t c : path) {
		out.push_back(c > 0 && c < 128 ? static_cast<char>(c) : '?');
	}
	return out;
}

// Names reaching here passed SafeShareName, so they are ASCII.
inline std::wstring WidenAscii(std::string_view text)
{
	std::wstring out;
	out.reserve(text.size());
	for (const char c : text) out.push_back(static_cast<wchar_t>(static_cast<unsigned char>(c)));
	return out;
}

// Reads at most cap bytes. Returns false when the file is missing, unreadable, fails partway
// (a cut-short read must never pass for the whole file) or is larger.
inline bool ReadCapped(const std::wstring& path, std::size_t cap, std::string& out)
{
	out.clear();
	FILE* file = nullptr;
	if (_wfopen_s(&file, path.c_str(), L"rb") != 0 || !file) return false;
	char buf[4096];
	size_t n = 0;
	bool fits = true;
	while ((n = fread(buf, 1, sizeof(buf), file)) > 0) {
		if (out.size() + n > cap) {
			fits = false;
			break;
		}
		out.append(buf, n);
	}
	const bool failed = ferror(file) != 0;
	fclose(file);
	if (!fits || failed) out.clear();
	return fits && !failed;
}

// Makes each folder on the way to filePath; folders already there are left as they are.
inline void EnsureDirsFor(const std::wstring& filePath)
{
	std::wstring dir = filePath;
	const auto slash = dir.find_last_of(L"\\/");
	if (slash == std::wstring::npos) return;
	dir.resize(slash);
	std::wstring built;
	for (wchar_t c : dir) {
		built.push_back(c);
		if (c == L'\\' || c == L'/') CreateDirectoryW(built.c_str(), nullptr);
	}
	CreateDirectoryW(dir.c_str(), nullptr);
}

// Writes text to path and flushes it to disk. False when any step fails.
inline bool WriteFlushed(const std::wstring& path, const std::string& text)
{
	FILE* file = nullptr;
	if (_wfopen_s(&file, path.c_str(), L"wb") != 0 || !file) return false;
	const bool wrote = fwrite(text.data(), 1, text.size(), file) == text.size();
	const bool flushed = wrote && fflush(file) == 0 && _commit(_fileno(file)) == 0;
	const bool closed = fclose(file) == 0;
	return flushed && closed;
}

// Writes a .tmp twin, flushes it to disk and renames it over the target, so a crash or power
// loss mid-write never leaves a half or zero-filled file where the player's data was.
inline bool WriteReplace(const std::wstring& path, const std::string& text)
{
	const std::wstring temp = path + L".tmp";
	if (!WriteFlushed(temp, text)) return false;
	return MoveFileExW(temp.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH) != 0;
}

// Renames from to a name nothing holds: kExists when a file or folder already holds it, and
// then both stay as they are.
inline MoveResult RenameNew(const std::wstring& from, const std::wstring& to)
{
	if (MoveFileExW(from.c_str(), to.c_str(), MOVEFILE_WRITE_THROUGH)) return MoveResult::kOk;
	const DWORD err = GetLastError();
	return err == ERROR_ALREADY_EXISTS || err == ERROR_FILE_EXISTS ? MoveResult::kExists : MoveResult::kFailed;
}

// Writes a new file as WriteReplace does, but never over anything: kExists when something
// holds path already, or takes it before the rename. A .tmp twin left by that race stays, as
// nothing is deleted.
inline MoveResult WriteNew(const std::wstring& path, const std::string& text)
{
	if (GetFileAttributesW(path.c_str()) != INVALID_FILE_ATTRIBUTES) return MoveResult::kExists;
	const std::wstring temp = path + L".tmp";
	if (!WriteFlushed(temp, text)) return MoveResult::kFailed;
	return RenameNew(temp, path);
}

// A file, not a folder, is at path.
inline bool FileExists(const std::wstring& path)
{
	const DWORD attrs = GetFileAttributesW(path.c_str());
	return attrs != INVALID_FILE_ATTRIBUTES && (attrs & FILE_ATTRIBUTE_DIRECTORY) == 0;
}

// The pill profile, its backup and its bad copy in one folder (the plugin's Documents
// shipbuilder folder), each gated by hsb::BuilderFileMayTouch before it is opened.
class Win32ProfileDisk final : public ProfileDisk {
public:
	explicit Win32ProfileDisk(std::wstring folder) : folder_(std::move(folder)) {}

	bool MayTouch(ProfileFile file, bool write) override { return BuilderFileMayTouch(NarrowPath(PathOf(file)), write); }

	bool Exists(ProfileFile file) override
	{
		if (GetFileAttributesW(PathOf(file).c_str()) != INVALID_FILE_ATTRIBUTES) return true;
		const DWORD err = GetLastError();
		return err != ERROR_FILE_NOT_FOUND && err != ERROR_PATH_NOT_FOUND;
	}

	bool Read(ProfileFile file, std::size_t cap, std::string& out) override { return ReadCapped(PathOf(file), cap, out); }

	bool WriteReplace(ProfileFile file, std::string_view text) override { return w32::WriteReplace(PathOf(file), std::string(text)); }

	MoveResult MoveNoReplace(ProfileFile from, ProfileFile to) override { return RenameNew(PathOf(from), PathOf(to)); }

	void EnsureDir() override { EnsureDirsFor(PathOf(ProfileFile::kProfile)); }

	std::wstring PathOf(ProfileFile file) const { return folder_ + WidenAscii(ProfileFileName(file)); }

private:
	std::wstring folder_;
};

}  // namespace hsb::w32
