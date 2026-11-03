#pragma once

// Single source for the HorizonUI.dll file version and product version.
// res/HorizonUI.rc.in includes this header, and the plugin logs and sends the same
// string (or the version resource that this header produced). Do not copy the
// numbers into the resource script or into a log line.
// Product version matches the file version (0.43.0.19). The settings-schema string
// in the plugin (HZF::kVersion, "0.42.0") is a different value: preset age and the
// update backup compare against that, not against this file version.
// 0.43.0.19 is a pre-release dev build. HUDMenu invokes stay on the first HUD
// advance thread. Cards build one per frame. BuildCards defaults on. EnemyCard
// defaults off. The startup intro defaults to off. EnemyCard and BuildCards
// accept only 1, true, on, and yes, in any case. Any other value is off.
// Boot fills one field at a time. Vanilla hides at ctor. F11 does not set
// gridFitType, sharpness, or thickness. A stalled HUD releases look and fight.
// Last modified: 2026-11-02.

#define HZ_FILE_VERSION_MAJOR 0
#define HZ_FILE_VERSION_MINOR 43
#define HZ_FILE_VERSION_PATCH 0
#define HZ_FILE_VERSION_BUILD 19
#define HZ_FILE_VERSION_STR "0.43.0.19"

// TEST_NOTE 0.43.0.19: first pass. HUD invokes stay on the recorded UI thread.
// Cards build one per frame. EnemyCard=0 logs HUD card skipped enemy.
// BuildCards=0 logs cards skipped. Startup intro stays off.
// EnemyCard and BuildCards treat only 1, true, on, and yes as on.
// Not approved. Long "..." notices still need an in-game look.
// VORTEX_INSTALL 0.43.0.19: keep 0.43.0.7 in Vortex until this 0.43.0.19
// build is installed over it. Back up settings first. Do not delete files.

// 0.43.0.9: 0 is the release state. 1 writes the verbose HUD-message trace (the
// "hud message:" line and the Comms movie queue as "comms msg:" lines). The card
// backup (the queue, Poll, hzcCardPush, and the one-line "comms reaction:" status)
// stays compiled either way. The settings schema above is not this switch.
#define HZ_COMMS_MSG_LOG 0

// 0.43.0.9: 0 is the release state. 1 logs every ShowHUDMessageEvent as
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
