#pragma once

// Purpose: tell whether an Address Library v5 id has a real offset, without calling REL.
// IDDB::offset ends the process when the slot is missing. This only reads bytes.
// Inputs: the versionlib file image and an id. Outputs: 1 when that slot is non-zero,
// 0 when the id is past the table or the slot is 0, -1 when the bytes are not a usable v5 table.
// The image matches commonlib-shared IDDB::HEADER_V5: 96 bytes, then one uint32 per id.
// Dependencies: none. The bytes are little-endian, which is the platform this plugin runs on.
// Last modified: 2026-10-23.

#include <cstddef>
#include <cstdint>
#include <cstring>

namespace hzaddr {

constexpr std::size_t kV5HeaderBytes = 96;

inline int V5Slot(const unsigned char* a_data, std::size_t a_size, std::uint64_t a_id)
{
	if (!a_data || a_size < kV5HeaderBytes) return -1;
	std::uint32_t format = 0;
	std::memcpy(&format, a_data, sizeof format);
	if (format != 5u) return -1;
	std::int32_t count = 0;
	std::memcpy(&count, a_data + 92, sizeof count);
	if (count < 0) return -1;
	const auto n = static_cast<std::uint64_t>(count);
	if (n > (a_size - kV5HeaderBytes) / 4u) return -1;
	if (a_id >= n) return 0;
	const auto at = kV5HeaderBytes + static_cast<std::size_t>(a_id) * 4u;
	if (at + 4u > a_size) return -1;
	std::uint32_t off = 0;
	std::memcpy(&off, a_data + at, sizeof off);
	return off != 0u ? 1 : 0;
}

// Purpose: a later HzAddrSlot needs the same v5 image prepare loaded.
// State 1 with a freed (empty) buffer is not ready; V5Slot then returns -1.
inline bool AddrSlotReady(int a_state, std::size_t a_size)
{
	return a_state == 1 && a_size >= kV5HeaderBytes;
}

// Purpose: when a CommonLib id is 0, name the published id that failed.
// Slot misses use the live id; this is only the zero-id fallback.
inline std::uint64_t EngineZeroMiss(
	std::uint64_t a_locId, std::uint64_t a_slmId, std::uint64_t a_calId, std::uint64_t a_pcId)
{
	if (a_locId == 0) return 63412ull;
	if (a_slmId == 0) return 883588ull;
	if (a_calId == 0) return 937673ull;
	if (a_pcId == 0) return 922868ull;
	return 0;
}

}
