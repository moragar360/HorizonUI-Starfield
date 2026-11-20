# Building HorizonUI.dll without build-machine paths

The DLL must not name the folder it was built in (that folder usually holds the Windows user name).
Two strings did in 0.43.2.0: a CommonLibSF header path (`__FILE__` / `source_location`) and the PDB path
in the debug directory. `xmake.lua` now sets, for every target (Horizon, CommonLibSF, commonlib-shared):

| What | MSVC (cl / link) | clang-cl / lld-link |
| --- | --- | --- |
| `__FILE__` prefix | `/d1trimfile:$(projectdir)` | `/clang:-ffile-prefix-map=$(projectdir)=.` |
| PDB path | `/PDBALTPATH:%_PDB%` | `/PDBALTPATH:%_PDB%` |

Build from a short neutral folder, `C:\b\HorizonUI`, as well: it also covers a toolchain or a `source_location`
path the flags above might miss.

## What the PC needs

- Visual Studio 2022 (or Build Tools) with "Desktop development with C++" (MSVC x64, Windows SDK). CMake: the
  "C++ CMake tools for Windows" component, or xmake fetches its own CMake package.
- xmake 3.0 or newer.
- Node.js 18+ for the check in step 6 (optional; Sysinternals `strings` works too).
- Network on the first configure, unless the package cache already has it: xmake reads its package index
  (xmake-repo, a git clone from GitHub) and installs `spdlog v1.16.0` (source archive
  `https://github.com/gabime/spdlog/archive/refs/tags/v1.16.0.zip`, sha256
  `3d25808d2fc4db86621a46855800c99ab5734999b61c4cbf9470edf631555397`, built with CMake as a static library).
  CommonLibSF's other packages (simpleini, glaze, toml11, xbyak, xoshiro-cpp) are off by default and not needed.
  Offline: put that archive in a folder as `spdlog-v1.16.0.zip` and run `xmake g --pkg_searchdirs=<that folder>`
  (the package index is still needed once).

## Steps

The branch is not pushed. Build from the source zip (preferred) or from the git bundle.

From the source zip `HorizonUI-src-<commit>.zip` (no `.git`; CommonLibSF and commonlib-shared are included at
their pinned commits, so there is no submodule step):
1. Extract it into `C:\b` so that `C:\b\HorizonUI\xmake.lua` exists.
2. `cd /d C:\b\HorizonUI`
3. Optional, keeps the spdlog build out of the user profile too: `set XMAKE_GLOBALDIR=C:\b\xg`
   (a fresh package cache, so this needs the network or the offline archive above).
4. `xmake f -p windows -a x64 -m releasedbg -y`
5. `xmake -r -y`
   The DLL is `build\windows\x64\releasedbg\HorizonUI.dll`.

From the git bundle `perf-arch-fixes-<commit>.bundle` (needs git; the submodules are not in the bundle):
1. `git clone -b perf/arch-fixes perf-arch-fixes-<commit>.bundle C:\b\HorizonUI`
2. Copy `lib\commonlibsf` from the source zip into `C:\b\HorizonUI\lib\commonlibsf` (or, with network,
   `git -C C:\b\HorizonUI submodule update --init --recursive`; CommonLibSF 9d090c4, commonlib-shared 9fbb74d).
3. Continue with steps 2 to 5 above.

## Check (both ways)

6. `node tests\dll_paths_check.js build\windows\x64\releasedbg\HorizonUI.dll <PC-USER>`
   It scans ASCII and UTF-16LE strings and must print `0 hit(s)` (exit code 0). Extra words can also go in the
   `HZ_PATH_WORDS` environment variable. With Sysinternals strings:
   `strings -a HorizonUI.dll | findstr /i "Users <PC-USER>"` and
   `strings -a -u HorizonUI.dll | findstr /i "Users <PC-USER>"` must print nothing.
7. Put the DLL in `00 Core\SFSE\Plugins\HorizonUI.dll` of the FOMOD, zip it under a new name, take the DLL back out
   of that zip and run step 6 on it again.
