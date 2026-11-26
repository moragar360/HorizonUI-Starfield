// Purpose: Windows check of the plugin's own file code (hsb_win32_files.h) under the pill
//    profile rules (hsb_profile.h), on a real disk: a temp folder shaped like the player's
//    Documents shipbuilder folder. It covers what the logic test's fake disk cannot: the real
//    rename that never replaces, sharing locks, read-only files, a folder where a file should
//    be, the names and caps the Win32 code passes on, and shared files written only as new.
// Inputs: none (the folder is made under GetTempPathW). Outputs: one FAIL line per broken
//    check; exit code 0 only when every check passes.
// How to run: xmake build profile_disk_test, then run it on Windows. Or build it with
//    mingw-w64 (x86_64-w64-mingw32-g++ -std=c++20 -static -Ishipbuilder/src) and run it under
//    wine, which is not Windows.
// Rules: only the test's own setup writes or deletes files directly, and only in its temp
//    folder; the plugin never deletes.
// Dependencies: hsb_win32_files.h, hsb_profile.h.
// Author: Moragar. Last modified: 2026-11-08.

#include "hsb_profile.h"
#include "hsb_win32_files.h"

#include <cstdio>
#include <iostream>
#include <string>

using hsb::ProfileFile;
using hsb::w32::Win32ProfileDisk;

static int g_fails = 0;
static int g_checks = 0;
static std::wstring g_folder;

static void Expect(bool ok, const std::string& text)
{
	++g_checks;
	if (ok) return;
	std::cerr << "FAIL: " << text << "\n";
	++g_fails;
}

static const char* const kJson = "ShipBuilderPills.json";
static const char* const kBak = "ShipBuilderPills.bak";
static const char* const kBad = "ShipBuilderPills.bad.json";
static const char* const kShare = "pills\\user\\Rust bucket.json";
static const char* const kShareTmp = "pills\\user\\Rust bucket.json.tmp";
static const char* const kShareFolder = "pills\\user\\Night run.json";
static const char* const kShareFrom = "pills\\user\\From.json";
static const char* const kShareFree = "pills\\user\\Free.json";

static std::wstring PathOf(const char* name)
{
	return g_folder + hsb::w32::WidenAscii(name);
}

// The file's bytes, or "<none>" when it cannot be read.
static std::string Bytes(const char* name)
{
	std::string out;
	return hsb::w32::ReadCapped(PathOf(name), 1 << 20, out) ? out : std::string("<none>");
}

static bool Present(const char* name)
{
	return GetFileAttributesW(PathOf(name).c_str()) != INVALID_FILE_ATTRIBUTES;
}

// Test setup only.
static void Put(const char* name, const std::string& text)
{
	FILE* file = nullptr;
	if (_wfopen_s(&file, PathOf(name).c_str(), L"wb") != 0 || !file) {
		Expect(false, std::string("setup: write ") + name);
		return;
	}
	fwrite(text.data(), 1, text.size(), file);
	fclose(file);
}

// Test setup only: the plugin never deletes.
static void Clear()
{
	for (const char* name : {kJson, kBak, kBad, "ShipBuilderPills.json.tmp", "ShipBuilderPills.bak.tmp", kShare, kShareTmp, kShareFolder,
			 "pills\\user\\Night run.json.tmp", kShareFrom, kShareFree, "pills\\user", "pills"}) {
		SetFileAttributesW(PathOf(name).c_str(), FILE_ATTRIBUTE_NORMAL);
		DeleteFileW(PathOf(name).c_str());
		RemoveDirectoryW(PathOf(name).c_str());
	}
}

// Test setup only: empties the test's folder and removes it, up to base. Run first as well,
// as a run cut short leaves its folder, and process ids come round again.
static void RemoveAll(const std::wstring& base)
{
	Clear();
	for (std::wstring dir = g_folder; dir.size() > base.size();) {
		dir.pop_back();
		RemoveDirectoryW(dir.c_str());
		dir.resize(dir.find_last_of(L'\\') + 1);
	}
	RemoveDirectoryW(base.c_str());
}

// Test setup only: another program holding the file open.
static HANDLE Hold(const char* name, DWORD share)
{
	HANDLE h = CreateFileW(PathOf(name).c_str(), GENERIC_READ, share, nullptr, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, nullptr);
	Expect(h != INVALID_HANDLE_VALUE, std::string("setup: open ") + name);
	return h;
}

int main()
{
	wchar_t tmp[MAX_PATH] = {};
	const DWORD n = GetTempPathW(MAX_PATH, tmp);
	if (n == 0 || n >= MAX_PATH) {
		std::cerr << "FAIL: no temp folder\n";
		return 1;
	}
	const std::wstring base = std::wstring(tmp) + L"hsb-profile-test-" + std::to_wstring(GetCurrentProcessId()) + L"\\";
	g_folder = base + L"My Games\\Starfield\\Data\\Interface\\HorizonUI\\shipbuilder\\";
	RemoveAll(base);
	Win32ProfileDisk disk(g_folder);
	hsb::ProfileState s;
	const std::string good = "{\"type\":\"horizon.shipbuilder\",\"version\":2,\"pills\":[]}";
	const std::string damaged = "{\"type\":\"horizon.shipbuilder\",\"version\":2,\"pills\":[";

	// Names, the folder, and the first saves.
	Expect(disk.PathOf(ProfileFile::kProfile) == PathOf(kJson) && disk.PathOf(ProfileFile::kBackup) == PathOf(kBak) &&
			disk.PathOf(ProfileFile::kBad) == PathOf(kBad),
		"the profile, its backup and its bad copy each have their own name in the folder");
	Expect(!disk.Exists(ProfileFile::kProfile), "a profile whose folder is not there yet is missing (path not found)");
	auto r = hsb::ProfileRead(disk, s);
	Expect(!r.ok && r.payload == hsb::kReadMissing, "READ before the folder exists: missing");
	r = hsb::ProfileWrite(disk, s, good);
	Expect(r.ok && Bytes(kJson) == good && !Present(kBak), "WRITE makes the folder and writes the first profile, with no backup");
	Expect(disk.Exists(ProfileFile::kProfile) && !disk.Exists(ProfileFile::kBackup), "Exists: the profile is there, the backup is not (file not found)");
	r = hsb::ProfileWrite(disk, s, "second");
	Expect(r.ok && Bytes(kJson) == "second" && Bytes(kBak) == good, "WRITE copies the old profile to .bak, then replaces it");
	Expect(!Present("ShipBuilderPills.json.tmp") && !Present("ShipBuilderPills.bak.tmp"), "WRITE leaves no .tmp after the rename");

	// Caps: a profile larger than any share file reads and writes whole; one over the cap does not.
	const std::string big(hsb::kMaxShareBytes * 2, 'x');
	r = hsb::ProfileWrite(disk, s, big);
	Expect(r.ok && Bytes(kJson) == big, "a profile twice the share cap is written whole");
	r = hsb::ProfileRead(disk, s);
	Expect(r.ok && r.payload == big, "and read whole");
	const std::string over(hsb::kMaxProfileBytes + 1, 'x');
	Put(kJson, over);
	r = hsb::ProfileRead(disk, s);
	Expect(!r.ok && r.payload == hsb::kReadUnreadable && s.held, "a profile over the cap is unreadable, never missing, and holds writes");
	r = hsb::ProfileWrite(disk, s, good);
	Expect(!r.ok && r.payload == hsb::kProfileHeld, "WRITE in that visit is held");
	{
		hsb::ProfileState unread;
		r = hsb::ProfileWrite(disk, unread, good);
	}
	Expect(!r.ok && r.payload == hsb::kReadUnreadable && Bytes(kJson) == over && Bytes(kBak) == "second",
		"WRITE's own read finds it over the cap too: never backed up or replaced");

	// A damaged profile, and an earlier bad copy in the way: the real rename never replaces it.
	Clear();
	Put(kJson, damaged);
	Put(kBak, good);
	Put(kBad, "older damaged");
	r = hsb::ProfileRead(disk, s);
	Expect(r.ok && r.payload == damaged, "READ returns damaged JSON for the movie to judge");
	r = hsb::ProfileSetAside(disk, s);
	Expect(!r.ok && r.payload == hsb::kProfileBadExists && s.held, "BAD with a .bad.json there: exists, and writes are held");
	r = hsb::ProfileWrite(disk, s, "starters");
	Expect(!r.ok && r.payload == hsb::kProfileHeld, "WRITE while held is refused");
	Expect(Bytes(kJson) == damaged && Bytes(kBak) == good && Bytes(kBad) == "older damaged",
		"the damaged profile, the good .bak and the earlier .bad.json are all unchanged");

	// The rename fails because another program has the profile open.
	DeleteFileW(PathOf(kBad).c_str());
	HANDLE shared = Hold(kJson, FILE_SHARE_READ);
	r = hsb::ProfileRead(disk, s);
	Expect(r.ok && r.payload == damaged && !s.held, "READ works alongside a reader; a new visit clears the hold");
	r = hsb::ProfileSetAside(disk, s);
	Expect(!r.ok && r.payload == hsb::kProfileFailed && s.held, "BAD while the profile is open elsewhere: failed, and writes are held");
	r = hsb::ProfileWrite(disk, s, "starters");
	Expect(!r.ok && r.payload == hsb::kProfileHeld && Bytes(kJson) == damaged && Bytes(kBak) == good && !Present(kBad),
		"WRITE after that failure is refused, and nothing changed");
	CloseHandle(shared);

	// A profile locked with no sharing is unreadable, never missing, and never saved over.
	HANDLE locked = Hold(kJson, 0);
	r = hsb::ProfileRead(disk, s);
	Expect(!r.ok && r.payload == hsb::kReadUnreadable && s.held, "READ of a profile locked with no sharing: unreadable, and writes are held");
	r = hsb::ProfileWrite(disk, s, "starters");
	Expect(!r.ok && r.payload == hsb::kProfileHeld, "WRITE in that visit is held");
	{
		hsb::ProfileState unread;
		r = hsb::ProfileWrite(disk, unread, "starters");
	}
	Expect(!r.ok && r.payload == hsb::kReadUnreadable, "WRITE's own read cannot read the old profile for its backup, so it is refused");
	CloseHandle(locked);
	Expect(Bytes(kJson) == damaged && Bytes(kBak) == good, "the locked profile and the good .bak are unchanged");

	// Once the way is clear, the set-aside works and saving starts fresh.
	r = hsb::ProfileRead(disk, s);
	Expect(r.ok && r.payload == damaged && !s.held, "the next visit reads the damaged profile again");
	r = hsb::ProfileSetAside(disk, s);
	Expect(r.ok && !s.held && s.keepBackup && Bytes(kBad) == damaged && !Present(kJson), "BAD moves the damaged profile to .bad.json, and the visit keeps .bak");
	r = hsb::ProfileWrite(disk, s, "fresh");
	Expect(r.ok && Bytes(kJson) == "fresh" && Bytes(kBak) == good, "the first save after it keeps the good .bak");
	r = hsb::ProfileWrite(disk, s, "fresh again");
	Expect(r.ok && Bytes(kJson) == "fresh again" && Bytes(kBak) == good, "and so does the second");
	r = hsb::ProfileRead(disk, s);
	Expect(r.ok && r.payload == "fresh again" && !s.keepBackup, "the next visit loads the new profile");
	r = hsb::ProfileWrite(disk, s, "next visit");
	Expect(r.ok && Bytes(kJson) == "next visit" && Bytes(kBak) == "fresh again" && Bytes(kBad) == damaged, "and backs it up as usual");

	// A second damaged profile never replaces the first bad copy.
	Put(kJson, "damaged again");
	r = hsb::ProfileSetAside(disk, s);
	Expect(!r.ok && r.payload == hsb::kProfileBadExists && Bytes(kBad) == damaged && Bytes(kJson) == "damaged again",
		"a second damaged profile never replaces the first .bad.json");

	// A zero-filled profile after a power loss.
	const std::string zeros(4096, '\0');
	Clear();
	Put(kBak, good);
	Put(kJson, zeros);
	r = hsb::ProfileRead(disk, s);
	Expect(!r.ok && r.payload == hsb::kReadDamaged && s.held, "READ of a zero-filled profile: damaged, not empty, and writes are held");
	r = hsb::ProfileWrite(disk, s, "fresh");
	Expect(!r.ok && r.payload == hsb::kProfileHeld && Bytes(kBak) == good, "WRITE before the set-aside is held");
	{
		hsb::ProfileState unread;
		r = hsb::ProfileWrite(disk, unread, "fresh");
	}
	Expect(!r.ok && r.payload == hsb::kReadDamaged && Bytes(kBak) == good && Bytes(kJson) == zeros, "WRITE's own read never copies zeros over the good .bak");
	r = hsb::ProfileSetAside(disk, s);
	Expect(r.ok && s.keepBackup && Bytes(kBad) == zeros, "BAD keeps the zeros as .bad.json");
	for (const char* save : {"fresh", "fresh again"}) {
		r = hsb::ProfileWrite(disk, s, save);
		Expect(r.ok && Bytes(kJson) == save && Bytes(kBak) == good, "each save after it keeps the good .bak");
	}

	// Review A4: an empty or blank profile is a fresh start that never costs the good .bak.
	for (const std::string& blank : {std::string(), std::string(" \r\n\t \r\n")}) {
		Clear();
		Put(kJson, blank);
		Put(kBak, good);
		r = hsb::ProfileRead(disk, s);
		Expect(r.ok && r.payload == blank && s.keepBackup && !s.held, "READ of an empty or blank profile: ok, and the visit keeps .bak");
		for (const char* save : {"first", "second"}) {
			r = hsb::ProfileWrite(disk, s, save);
			Expect(r.ok && Bytes(kJson) == save && Bytes(kBak) == good && !Present(kBad), "each save in that visit keeps the good .bak");
		}
		r = hsb::ProfileRead(disk, s);
		r = hsb::ProfileWrite(disk, s, "third");
		Expect(r.ok && Bytes(kJson) == "third" && Bytes(kBak) == "second", "the next visit backs up what it loaded");
		Clear();
		Put(kJson, blank);
		Put(kBak, good);
		hsb::ProfileState unread;
		r = hsb::ProfileWrite(disk, unread, "first");
		Expect(r.ok && Bytes(kJson) == "first" && Bytes(kBak) == good, "an empty or blank old profile is never copied over .bak");
	}

	// No profile but a .bak (removed by hand or by a tool): the visit keeps .bak, even one that
	// another program holds open.
	Clear();
	Put(kBak, good);
	HANDLE bakLocked = Hold(kBak, 0);
	r = hsb::ProfileRead(disk, s);
	Expect(!r.ok && r.payload == hsb::kReadMissing && s.keepBackup, "READ with no profile and a .bak: missing, and the visit keeps .bak");
	for (const char* save : {"first", "second"}) {
		r = hsb::ProfileWrite(disk, s, save);
		Expect(r.ok && Bytes(kJson) == save, "each save in that visit works without touching .bak");
	}
	CloseHandle(bakLocked);
	Expect(Bytes(kBak) == good, "and .bak is unchanged");

	// Read-only files are never replaced.
	Clear();
	Put(kJson, good);
	Put(kBak, "old backup");
	SetFileAttributesW(PathOf(kBak).c_str(), FILE_ATTRIBUTE_READONLY);
	r = hsb::ProfileRead(disk, s);
	Expect(r.ok && r.payload == good && !s.keepBackup, "READ of a good profile: the visit backs it up");
	r = hsb::ProfileWrite(disk, s, "new");
	Expect(!r.ok && r.payload == hsb::kProfileBackupFailed && Bytes(kJson) == good && Bytes(kBak) == "old backup",
		"a read-only .bak: the backup fails, so the profile is not replaced");
	SetFileAttributesW(PathOf(kBak).c_str(), FILE_ATTRIBUTE_NORMAL);
	SetFileAttributesW(PathOf(kJson).c_str(), FILE_ATTRIBUTE_READONLY);
	r = hsb::ProfileWrite(disk, s, "new");
	Expect(!r.ok && r.payload == hsb::kProfileFailed && Bytes(kJson) == good && Bytes(kBak) == good,
		"a read-only profile is never replaced, and .bak holds the same profile");
	SetFileAttributesW(PathOf(kJson).c_str(), FILE_ATTRIBUTE_NORMAL);

	// Folders where files should be.
	Clear();
	CreateDirectoryW(PathOf(kJson).c_str(), nullptr);
	r = hsb::ProfileRead(disk, s);
	Expect(!r.ok && r.payload == hsb::kReadUnreadable && s.held, "a folder named ShipBuilderPills.json reads as unreadable, never missing");
	{
		hsb::ProfileState unread;
		r = hsb::ProfileWrite(disk, unread, "new");
	}
	Expect(!r.ok && r.payload == hsb::kReadUnreadable && !Present(kBak), "and is never written over");
	Clear();
	Put(kJson, damaged);
	CreateDirectoryW(PathOf(kBad).c_str(), nullptr);
	r = hsb::ProfileSetAside(disk, s);
	Expect(!r.ok && s.held && Bytes(kJson) == damaged, "a folder named ShipBuilderPills.bad.json blocks the set-aside; the profile stays, and writes are held");

	// Shared files (exports and schemes) are written new, never over a file or folder.
	Clear();
	hsb::w32::EnsureDirsFor(PathOf(kShare));
	Expect(hsb::w32::WriteNew(PathOf(kShare), "first") == hsb::MoveResult::kOk && Bytes(kShare) == "first" && !Present(kShareTmp),
		"WriteNew writes a free name whole, through a .tmp it renames");
	Expect(hsb::w32::WriteNew(PathOf(kShare), "second") == hsb::MoveResult::kExists && Bytes(kShare) == "first" && !Present(kShareTmp),
		"WriteNew to a name a file holds: exists, the file is unchanged and no .tmp is made");
	Expect(hsb::w32::WriteNew(PathOf("pills\\user\\RUST BUCKET.json"), "second") == hsb::MoveResult::kExists && Bytes(kShare) == "first",
		"a name that differs only in case is the same file, and is not replaced");
	SetFileAttributesW(PathOf(kShare).c_str(), FILE_ATTRIBUTE_READONLY);
	Expect(hsb::w32::WriteNew(PathOf(kShare), "second") == hsb::MoveResult::kExists && Bytes(kShare) == "first", "a read-only file is not replaced");
	SetFileAttributesW(PathOf(kShare).c_str(), FILE_ATTRIBUTE_NORMAL);
	{
		HANDLE held = Hold(kShare, 0);
		Expect(hsb::w32::WriteNew(PathOf(kShare), "second") == hsb::MoveResult::kExists, "a file another program holds open is not replaced");
		CloseHandle(held);
	}
	Expect(Bytes(kShare) == "first", "and is unchanged once it is closed");
	CreateDirectoryW(PathOf(kShareFolder).c_str(), nullptr);
	Expect(hsb::w32::WriteNew(PathOf(kShareFolder), "x") == hsb::MoveResult::kExists && !Present("pills\\user\\Night run.json.tmp"),
		"a folder holding the name is never written over");
	// The rename itself, for a file that takes the name after WriteNew looked.
	Put(kShareFrom, "late");
	Expect(hsb::w32::RenameNew(PathOf(kShareFrom), PathOf(kShare)) == hsb::MoveResult::kExists && Bytes(kShare) == "first" &&
			Bytes(kShareFrom) == "late",
		"RenameNew onto a name a file holds: exists, and both files stay as they were");
	Expect(hsb::w32::RenameNew(PathOf(kShareFrom), PathOf(kShareFree)) == hsb::MoveResult::kOk && Bytes(kShareFree) == "late" && !Present(kShareFrom),
		"RenameNew onto a free name moves the file");
	Expect(hsb::w32::WriteNew(PathOf("pills\\none\\Lost.json"), "x") == hsb::MoveResult::kFailed && !Present("pills\\none"),
		"WriteNew into a folder that is not there fails and makes nothing");

	// The gate: without a Documents folder nothing is opened.
	Clear();
	Win32ProfileDisk nowhere(L"");
	hsb::ProfileState t;
	r = hsb::ProfileRead(nowhere, t);
	Expect(!r.ok && r.payload == hsb::kReadUnreadable, "no Documents folder: READ is refused by BuilderFileMayTouch, so unreadable");
	r = hsb::ProfileWrite(nowhere, t, good);
	Expect(!r.ok, "no Documents folder: WRITE is refused");
	r = hsb::ProfileSetAside(nowhere, t);
	Expect(!r.ok && t.held, "no Documents folder: BAD is refused, and writes are held");

	RemoveAll(base);
	if (g_fails) {
		std::cerr << g_fails << " of " << g_checks << " failed\n";
		return 1;
	}
	std::cout << "profile_disk_test passed " << g_checks << " checks\n";
	return 0;
}
