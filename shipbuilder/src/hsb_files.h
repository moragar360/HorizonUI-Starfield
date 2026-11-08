#pragma once

// Purpose: pure rules for the builder's own files: the pill profile, shared pill files and
//    colour scheme files. probe.cpp opens files only after these rules accept the request.
// Inputs: request lines from the movie ("id<TAB>KIND<TAB>VERB<TAB>args...<TAB>body").
// Outputs: parsed requests, accepted file names, escaped reply payloads.
// Rules: kinds PROFILE, PILLS, SCHEMES only; folders "packs" and "user" only; writes go to
//    "user" only; names are letters, digits, space, dash and underscore with the kind's
//    extension; sizes are capped. Nothing is ever deleted; a profile write keeps a .bak copy
//    (see hsb_profile.h). No reply carries a NUL byte.
// Dependencies: hsb_guard.h (path folding); no game or Windows calls.
// Author: Moragar. Last modified: 2026-11-08.

#include "hsb_guard.h"

#include <string>
#include <string_view>
#include <vector>

namespace hsb {

inline constexpr std::size_t kMaxShareBytes = 64 * 1024;
inline constexpr std::size_t kMaxProfileBytes = 256 * 1024;
inline constexpr std::size_t kMaxListFiles = 64;
inline constexpr std::size_t kMaxFileStem = 40;
inline constexpr std::size_t kMaxRequestBytes = 300 * 1024;

// The movie receives replies as one C string, so a NUL byte would cut off its reply and every
// reply after it in that frame. No JSON or ini text the builder reads holds one.
inline bool HasNul(std::string_view text)
{
	return text.find('\0') != std::string_view::npos;
}

inline std::string EscapeText(std::string_view text)
{
	std::string out;
	out.reserve(text.size());
	for (char c : text) {
		if (c == '\\') out += "\\\\";
		else if (c == '\n') out += "\\n";
		else if (c == '\t') out += "\\t";
		else if (c == '\r') continue;
		else out.push_back(c);
	}
	return out;
}

inline std::string UnescapeText(std::string_view text)
{
	std::string out;
	out.reserve(text.size());
	for (std::size_t i = 0; i < text.size(); ++i) {
		const char c = text[i];
		if (c == '\\' && i + 1 < text.size()) {
			const char n = text[i + 1];
			out.push_back(n == 'n' ? '\n' : (n == 't' ? '\t' : n));
			++i;
			continue;
		}
		out.push_back(c);
	}
	return out;
}

struct FileRequest {
	std::string id;
	std::string kind;
	std::string verb;
	std::vector<std::string> args;
	std::string body;
};

// Purpose: split one request line. The body is always the last field (escaped, maybe empty).
inline bool ParseFileRequest(std::string_view line, FileRequest& out)
{
	out = FileRequest{};
	if (line.empty() || line.size() > kMaxRequestBytes) return false;
	std::vector<std::string> parts;
	std::size_t at = 0;
	while (true) {
		const auto tab = line.find('\t', at);
		parts.emplace_back(line.substr(at, tab == std::string_view::npos ? std::string_view::npos : tab - at));
		if (tab == std::string_view::npos) break;
		at = tab + 1;
	}
	if (parts.size() < 4) return false;
	out.id = parts[0];
	out.kind = parts[1];
	out.verb = parts[2];
	for (std::size_t i = 3; i + 1 < parts.size(); ++i) out.args.push_back(parts[i]);
	out.body = parts.back();
	if (out.id.empty() || out.id.size() > 12) return false;
	for (char c : out.id) {
		const bool ok = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'z');
		if (!ok) return false;
	}
	return true;
}

inline const char* KindExtension(std::string_view kind)
{
	if (kind == "PILLS") return ".json";
	if (kind == "SCHEMES") return ".ini";
	return "";
}

// The id of a request line that did not parse, so the movie still gets a failure reply and
// its callback runs. Empty when the line does not start with a valid id and a tab.
inline std::string RequestId(std::string_view line)
{
	const auto tab = line.find('\t');
	if (tab == std::string_view::npos || tab == 0 || tab > 12) return {};
	for (std::size_t i = 0; i < tab; ++i) {
		const char c = line[i];
		if (!((c >= '0' && c <= '9') || (c >= 'a' && c <= 'z'))) return {};
	}
	return std::string(line.substr(0, tab));
}

// A failed PROFILE READ says why: with "missing" the movie may start from its defaults; with
// "unreadable" a profile exists that could not be read, and the movie must not save over it;
// with "damaged" the profile holds a NUL byte, and the movie sets it aside as it does a
// profile that does not parse.
inline constexpr std::string_view kReadMissing = "missing";
inline constexpr std::string_view kReadUnreadable = "unreadable";
inline constexpr std::string_view kReadDamaged = "damaged";

inline bool FolderOk(std::string_view folder)
{
	return folder == "packs" || folder == "user";
}

// Windows opens CON, PRN, AUX, NUL, COM0-COM9 and LPT0-LPT9 as devices whatever the extension,
// so "Con.json" would never reach the disk.
inline bool ReservedDeviceName(std::string_view stem)
{
	auto startsFold = [&](std::string_view name) {
		if (stem.size() < name.size()) return false;
		for (std::size_t i = 0; i < name.size(); ++i) {
			if (Fold(stem[i]) != name[i]) return false;
		}
		return true;
	};
	if (stem.size() == 3) return startsFold("con") || startsFold("prn") || startsFold("aux") || startsFold("nul");
	if (stem.size() == 4 && stem[3] >= '0' && stem[3] <= '9') return startsFold("com") || startsFold("lpt");
	return false;
}

// Purpose: accept a shared file name: 1..40 safe characters plus the kind's extension, so a
//    name can never leave its folder or name another kind of file.
inline bool SafeShareName(std::string_view name, std::string_view kind)
{
	const std::string_view ext = KindExtension(kind);
	if (ext.empty() || name.size() <= ext.size()) return false;
	if (name.substr(name.size() - ext.size()) != ext) return false;
	const std::string_view stem = name.substr(0, name.size() - ext.size());
	if (stem.empty() || stem.size() > kMaxFileStem) return false;
	if (stem.front() == ' ' || stem.back() == ' ') return false;
	if (ReservedDeviceName(stem)) return false;
	for (char c : stem) {
		const bool ok = (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c == ' ' || c == '-' || c == '_';
		if (!ok) return false;
	}
	return true;
}

enum class FileVerb { kBad, kProfileRead, kProfileWrite, kProfileBad, kList, kRead, kWrite };

// Purpose: check a request against the rules above. Outputs: what to do, or kBad.
inline FileVerb CheckRequest(const FileRequest& r)
{
	if (r.kind == "PROFILE") {
		if (!r.args.empty()) return FileVerb::kBad;
		if (r.verb == "READ") return FileVerb::kProfileRead;
		if (r.verb == "WRITE") return r.body.size() <= kMaxProfileBytes * 2 ? FileVerb::kProfileWrite : FileVerb::kBad;
		if (r.verb == "BAD") return FileVerb::kProfileBad;
		return FileVerb::kBad;
	}
	if (r.kind != "PILLS" && r.kind != "SCHEMES") return FileVerb::kBad;
	if (r.verb == "LIST") return r.args.empty() ? FileVerb::kList : FileVerb::kBad;
	if (r.args.size() != 2 || !FolderOk(r.args[0]) || !SafeShareName(r.args[1], r.kind)) return FileVerb::kBad;
	if (r.verb == "READ") return FileVerb::kRead;
	if (r.verb == "WRITE") {
		if (r.args[0] != "user") return FileVerb::kBad;
		return r.body.size() <= kMaxShareBytes * 2 ? FileVerb::kWrite : FileVerb::kBad;
	}
	return FileVerb::kBad;
}

// Purpose: the reply line the movie expects: "id<TAB>1|0<TAB>escaped payload". A payload with
//    a NUL byte (see HasNul) becomes a failure with no payload.
inline std::string FileReply(std::string_view id, bool ok, std::string_view payload)
{
	const bool nul = HasNul(payload);
	std::string out(id);
	out += ok && !nul ? "\t1\t" : "\t0\t";
	if (!nul) out += EscapeText(payload);
	return out;
}

// One LIST row: "folder<TAB>name<TAB>bytes". A listed name must pass SafeShareName.
inline std::string ListRow(std::string_view folder, std::string_view name, unsigned long long bytes)
{
	return std::string(folder) + "\t" + std::string(name) + "\t" + std::to_string(bytes);
}

inline constexpr std::string_view kProfileName = "ShipBuilderPills.json";
inline constexpr std::string_view kProfileBackup = "ShipBuilderPills.bak";
inline constexpr std::string_view kProfileBad = "ShipBuilderPills.bad.json";

// The sub-folder of shipbuilder\ that holds one kind's shared files.
inline const char* KindFolder(std::string_view kind)
{
	if (kind == "PILLS") return "pills";
	if (kind == "SCHEMES") return "schemes";
	return "";
}

// Purpose: last gate before probe.cpp opens a builder file. Inputs: the full path, and whether
//    it is a write. Rules: the path is inside Interface\HorizonUI\shipbuilder, has no "..", and
//    names the profile, its backup or bad copy, or a .json or .ini share file in a packs or
//    user folder. Writes go only under My Games\Starfield (never the game install). A .tmp
//    twin of an allowed write is allowed, for the replace-by-rename.
inline bool BuilderFileMayTouch(std::string_view path, bool write)
{
	if (path.empty() || HasDotDot(path)) return false;
	if (!ContainsFold(path, "\\Interface\\HorizonUI\\shipbuilder\\")) return false;
	if (ContainsFold(path, "\\Saves\\")) return false;
	if (write && (!ContainsFold(path, "\\My Games\\Starfield\\") || ContainsFold(path, "steamapps"))) return false;
	const auto slash = path.find_last_of("/\\");
	if (slash == std::string_view::npos) return false;
	const std::string_view dir = path.substr(0, slash + 1);
	std::string_view name = path.substr(slash + 1);
	if (write && name.size() > 4 && EndsWithFold(name, ".tmp")) name.remove_suffix(4);
	if (name == kProfileName || name == kProfileBackup || name == kProfileBad) return EndsWithFold(dir, "\\shipbuilder\\");
	const bool pills = EndsWithFold(name, ".json") && (EndsWithFold(dir, "\\shipbuilder\\pills\\user\\") ||
		(!write && EndsWithFold(dir, "\\shipbuilder\\pills\\packs\\")));
	const bool schemes = EndsWithFold(name, ".ini") && (EndsWithFold(dir, "\\shipbuilder\\schemes\\user\\") ||
		(!write && EndsWithFold(dir, "\\shipbuilder\\schemes\\packs\\")));
	return pills || schemes;
}

}  // namespace hsb
