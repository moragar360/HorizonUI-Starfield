#pragma once

// Single source for the HorizonUI.dll file version and product version.
// res/HorizonUI.rc.in includes this header, and the plugin logs and sends the same
// string (or the version resource that this header produced). Do not copy the
// numbers into the resource script or into a log line.
// Product version matches the file version (0.42.0.4). The settings-schema string
// in the plugin (HZF::kVersion, "0.42.0") is a different value: preset age and the
// update backup compare against that, not against this file version.
// Last modified: 2026-10-20.

#define HZ_FILE_VERSION_MAJOR 0
#define HZ_FILE_VERSION_MINOR 42
#define HZ_FILE_VERSION_PATCH 0
#define HZ_FILE_VERSION_BUILD 4
#define HZ_FILE_VERSION_STR "0.42.0.4"

// The resource compiler defines RC_INVOKED. Keep this header free of C++ there.
#if !defined(RC_INVOKED) && defined(__cplusplus)
#include <string>

// Purpose: accept a 4-part numeric file version such as 0.42.0.4.
// Inputs: a version string with no leading v. Outputs: true when it is four
// numeric parts. Dependencies: none.
// Last modified: 2026-10-20.
inline bool HzFileVersionOk(const std::string& a_s)
{
	if (a_s.size() < 7 || a_s.size() > 32) return false;
	int dots = 0;
	bool digit = false;
	for (unsigned char c : a_s) {
		if (c >= '0' && c <= '9') { digit = true; continue; }
		if (c == '.' && digit) { ++dots; digit = false; continue; }
		return false;
	}
	return digit && dots == 3;
}
#endif
