# Building HorizonUI.dll without build-machine paths

The DLL must not name the folder it was built in (that folder usually holds the Windows user name).
Two strings did in 0.43.2.0: a CommonLibSF header path (`__FILE__` / `source_location`) and the PDB path
in the debug directory. `xmake.lua` now sets, for every target (Horizon, CommonLibSF, commonlib-shared):

| What | MSVC (cl / link) | clang-cl / lld-link |
| --- | --- | --- |
| `__FILE__` prefix | `/d1trimfile:$(projectdir)` | `/clang:-ffile-prefix-map=$(projectdir)=.` |
| PDB path | `/PDBALTPATH:%_PDB%` | `/PDBALTPATH:%_PDB%` |

## Steps (Windows, x64 Native Tools prompt or a shell with xmake 3.x on PATH)

1. Get the sources with the pinned submodule:
   `git clone --recurse-submodules <repo> C:\b\HorizonUI` then `git -C C:\b\HorizonUI checkout perf/arch-fixes`
   and `git -C C:\b\HorizonUI submodule update --init --recursive` (CommonLibSF at 9d090c4).
   A short neutral folder such as `C:\b\HorizonUI` is the fallback if a toolchain ignores the flags above.
2. `cd C:\b\HorizonUI`
3. `xmake f -p windows -a x64 -m releasedbg -y`
4. `xmake -r -y`
5. The DLL is `build\windows\x64\releasedbg\HorizonUI.dll`.
6. Check it (Node.js 18+): `node tests\dll_paths_check.js build\windows\x64\releasedbg\HorizonUI.dll <your user name>`.
   It scans ASCII and UTF-16LE strings and must print `0 hit(s)` (exit code 0).
   With Sysinternals strings: `strings -a HorizonUI.dll | findstr /i "Users <your user name>"` and
   `strings -a -u HorizonUI.dll | findstr /i "Users <your user name>"` must print nothing.
7. Put the DLL in `00 Core\SFSE\Plugins\HorizonUI.dll` of the FOMOD and check the copy inside the zip again.
