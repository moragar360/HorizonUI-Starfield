#pragma once

// Purpose: the pill profile's read, write and set-aside rules (PROFILE READ, WRITE and BAD),
//    on a disk the caller supplies, so the same rules run in the plugin and in tests whose
//    disk fails on purpose.
// Inputs: a ProfileDisk (hsb_win32_files.h's Win32ProfileDisk, or a test fake); the visit's
//    ProfileState; the movie's text for a write.
// Outputs: a ProfileResult: ok and the profile text, or a failure and its reason.
// Rules: nothing is deleted, and no file is replaced from bytes that were not read whole and
//    checked first. A profile with a NUL byte is damaged: JSON text never holds one, a crash
//    can leave a file of zeros, and the movie receives replies as one C string, so it would
//    see such a file cut short or empty. The backup is written only from a profile read whole,
//    without a NUL and not blank. A visit that starts without a loaded profile (none, a blank
//    one, or one set aside) while a backup is there never replaces that backup: it may hold
//    the player's last good pills. A set-aside never replaces an earlier
//    ShipBuilderPills.bad.json. Writes are held, so the profile is never saved over even if
//    the movie asks: until it is set aside when it holds a NUL byte, and until the next read
//    (the next visit) when it could not be read or a set-aside failed.
// Dependencies: hsb_files.h (file names, read reasons, caps); no game or Windows calls.
// Author: Moragar. Last modified: 2026-11-08.

#include "hsb_files.h"

#include <string>
#include <string_view>
#include <utility>

namespace hsb {

enum class ProfileFile { kProfile, kBackup, kBad };

enum class MoveResult { kOk, kExists, kFailed };

// Why a write or set-aside failed. The movie shows its own line for each set-aside reason.
inline constexpr std::string_view kProfileHeld = "held";
inline constexpr std::string_view kProfileBackupFailed = "backup";
inline constexpr std::string_view kProfileFailed = "failed";
inline constexpr std::string_view kProfileBadExists = "exists";

// The file's name in the builder folder.
inline constexpr std::string_view ProfileFileName(ProfileFile file)
{
	return file == ProfileFile::kBackup ? kProfileBackup : (file == ProfileFile::kBad ? kProfileBad : kProfileName);
}

// Empty, or only spaces, tabs and line breaks: such a profile holds no pills.
inline bool ProfileBlank(std::string_view text)
{
	return text.find_first_not_of(" \t\r\n") == std::string_view::npos;
}

class ProfileDisk {
public:
	virtual ~ProfileDisk() = default;
	// Whether the rules may open the file (hsb::BuilderFileMayTouch in the plugin).
	virtual bool MayTouch(ProfileFile file, bool write) = 0;
	// False only when the system says nothing is there; an error that leaves it unknown is true.
	virtual bool Exists(ProfileFile file) = 0;
	// The whole file, at most cap bytes. False when it cannot be opened, fails partway or is larger.
	virtual bool Read(ProfileFile file, std::size_t cap, std::string& out) = 0;
	// Writes a .tmp twin, flushes it to disk and renames it over the file. On false the file is
	// as it was.
	virtual bool WriteReplace(ProfileFile file, std::string_view text) = 0;
	// Renames from to to, never replacing a file already at to.
	virtual MoveResult MoveNoReplace(ProfileFile from, ProfileFile to) = 0;
	virtual void EnsureDir() = 0;
};

// One visit's memory, kept by the plugin's job thread. ProfileRead starts a visit.
struct ProfileState {
	// Writes are refused this visit: the profile could not be read, holds a NUL byte and is not
	// set aside yet, or a set-aside failed. Each leaves it where a write would go.
	bool held = false;
	// The visit started without a loaded profile while a backup was there, so no write this
	// visit replaces the backup.
	bool keepBackup = false;
};

struct ProfileResult {
	bool ok = false;
	// The profile text for a read that worked; otherwise the reason, or empty.
	std::string payload;
};

// Purpose: PROFILE READ, the movie's first request each visit.
// Outputs: ok and the text (empty or blank text: the movie starts fresh); or a failure with
//    kReadMissing (no profile: the movie may start fresh), kReadDamaged (a NUL byte: the movie
//    sets it aside) or kReadUnreadable (it could not be read or checked: the movie must not
//    save over it). Starts the visit's state: held after kReadDamaged or kReadUnreadable, and
//    keepBackup when no profile is loaded and a backup is there.
inline ProfileResult ProfileRead(ProfileDisk& disk, ProfileState& state)
{
	state.held = false;
	state.keepBackup = false;
	ProfileResult r;
	if (!disk.MayTouch(ProfileFile::kProfile, false)) {
		state.held = true;
		r.payload = kReadUnreadable;
		return r;
	}
	std::string text;
	if (!disk.Read(ProfileFile::kProfile, kMaxProfileBytes, text)) {
		if (disk.Exists(ProfileFile::kProfile)) {
			state.held = true;
			r.payload = kReadUnreadable;
			return r;
		}
		state.keepBackup = disk.Exists(ProfileFile::kBackup);
		r.payload = kReadMissing;
		return r;
	}
	if (HasNul(text)) {
		state.held = true;
		r.payload = kReadDamaged;
		return r;
	}
	if (ProfileBlank(text)) state.keepBackup = disk.Exists(ProfileFile::kBackup);
	r.ok = true;
	r.payload = std::move(text);
	return r;
}

// Purpose: PROFILE WRITE. Inputs: the movie's profile text (unescaped).
// Outputs: ok; or a failure with kProfileHeld (writes are held this visit, see ProfileState),
//    kReadUnreadable (the old profile could not be read whole), kReadDamaged (the old profile
//    has a NUL byte), kProfileBackupFailed or kProfileFailed. Empty when refused.
// Rules: the old profile is read whole and checked before it is replaced. It goes to the
//    backup first, from the bytes read here, unless it is blank or the visit keeps the backup;
//    the new profile is written only when that worked. A missing profile needs no backup.
inline ProfileResult ProfileWrite(ProfileDisk& disk, const ProfileState& state, std::string_view text)
{
	ProfileResult r;
	if (state.held) {
		r.payload = kProfileHeld;
		return r;
	}
	if (text.size() > kMaxProfileBytes || !disk.MayTouch(ProfileFile::kProfile, true) || !disk.MayTouch(ProfileFile::kBackup, true)) return r;
	disk.EnsureDir();
	if (disk.Exists(ProfileFile::kProfile)) {
		std::string old;
		if (!disk.MayTouch(ProfileFile::kProfile, false) || !disk.Read(ProfileFile::kProfile, kMaxProfileBytes, old)) {
			r.payload = kReadUnreadable;
			return r;
		}
		if (HasNul(old)) {
			r.payload = kReadDamaged;
			return r;
		}
		if (!state.keepBackup && !ProfileBlank(old) && !disk.WriteReplace(ProfileFile::kBackup, old)) {
			r.payload = kProfileBackupFailed;
			return r;
		}
	}
	if (!disk.WriteReplace(ProfileFile::kProfile, text)) {
		r.payload = kProfileFailed;
		return r;
	}
	r.ok = true;
	return r;
}

// Purpose: PROFILE BAD: move the damaged profile to ShipBuilderPills.bad.json.
// Outputs: ok when it moved, or when there is no profile to move, and then keepBackup is set
//    when a backup is there; otherwise a failure with kProfileBadExists (a bad copy is already
//    there and is never replaced) or kProfileFailed, and writes are refused until the next
//    read.
inline ProfileResult ProfileSetAside(ProfileDisk& disk, ProfileState& state)
{
	ProfileResult r;
	if (!disk.MayTouch(ProfileFile::kProfile, true) || !disk.MayTouch(ProfileFile::kBad, true)) {
		state.held = true;
		r.payload = kProfileFailed;
		return r;
	}
	const MoveResult moved = disk.Exists(ProfileFile::kProfile) ? disk.MoveNoReplace(ProfileFile::kProfile, ProfileFile::kBad) : MoveResult::kOk;
	if (moved == MoveResult::kOk) {
		state.held = false;
		state.keepBackup = disk.Exists(ProfileFile::kBackup);
		r.ok = true;
		return r;
	}
	state.held = true;
	r.payload = moved == MoveResult::kExists ? kProfileBadExists : kProfileFailed;
	return r;
}

}  // namespace hsb
