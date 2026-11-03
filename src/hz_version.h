#pragma once

// Single source for the HorizonUI.dll file version and product version.
// res/HorizonUI.rc.in includes this header, and the plugin logs and sends the same
// string (or the version resource that this header produced). Do not copy the
// numbers into the resource script or into a log line.
// Product version matches the file version (0.43.0.26). The settings-schema string
// in the plugin (HZF::kVersion, "0.42.0") is a different value: preset age and the
// update backup compare against that, not against this file version.
// 0.43.0.26 is a pre-release dev build for Message Log P2 (F11 log UI and settings).
// The default name hover changed to Compact (one line). Full is in F11, CARDS.
// VitalsBars compact uses the COMPACT MODE card (boost, health, and oxygen). Full stays the default.
// A listed session clear that matches nothing leaves every stored row intact.
// Last modified: 2026-11-03.

#define HZ_FILE_VERSION_MAJOR 0
#define HZ_FILE_VERSION_MINOR 43
#define HZ_FILE_VERSION_PATCH 0
#define HZ_FILE_VERSION_BUILD 26
#define HZ_FILE_VERSION_STR "0.43.0.26"

// 0.43.0.26: 0 is the release state. 1 writes the verbose HUD-message trace (the
// "hud message:" line and the Comms movie queue as "comms msg:" lines). The card
// backup (the queue, Poll, hzcCardPush, and the one-line "comms reaction:" status)
// stays compiled either way. The settings schema above is not this switch.
#define HZ_COMMS_MSG_LOG 0

// 0.43.0.26: 0 is the release state. 1 logs every ShowHUDMessageEvent as
// "hud capture:" with no text filter. It is independent of HZ_COMMS_MSG_LOG.
#define HZ_HUD_MSG_CAPTURE 0

// The resource compiler defines RC_INVOKED. Keep this header free of C++ there.
#if !defined(RC_INVOKED) && defined(__cplusplus)
#include <string>

// Purpose: accept a 4-part numeric file version (major.minor.patch.build).
// Inputs: a version string with no leading v. Outputs: true when it is four
// numeric parts. Dependencies: none.
// Last modified: 2026-10-24.
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
