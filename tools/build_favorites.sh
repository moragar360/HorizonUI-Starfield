#!/bin/bash
# Horizon UI quick menu build (0.43.3.0, batch f) = the Scope build (build_scope042014.sh) retargeted to the quick menu:
# builds favoritesmenu.swf / favoritesmenu_lrg.swf into $1 (a NEW folder) from the player's vanilla 1.16.244 movies
# in $V (read only): fresh class export, hook (tools/apply_fav_hooks.py), ffdec -importScript into the full vanilla
# movie, then decompile the result (script + p-code) and the vanilla p-code for the checks. Nothing is deleted or
# overwritten: the output folder must not exist.
#   tools/build_favorites.sh OUT_DIR [VANILLA_DIR]
# Needs: java (FFDec 26.x) and python3. Vanilla movies come from $2, HZ_VANILLA_FAV, or HORIZON_VANILLA_FAVORITES.
# FFDEC_JAR, or a ffdec.jar under tools/. Optional HZ_JAVA_BIN or JAVA_HOME. Stops when less than 5.5 GB would be left on the output disk.
set -u
O=$1; [ -e "$O" ] && { echo "$O exists"; exit 1; }
R=$(cd "$(dirname "$0")/.." && pwd)
V=${2:-${HZ_VANILLA_FAV:-${HORIZON_VANILLA_FAVORITES:-}}}
[ -n "$V" ] || { echo "give VANILLA_DIR (or set HZ_VANILLA_FAV / HORIZON_VANILLA_FAVORITES)"; exit 1; }
F=${FFDEC_JAR:-}
if [ -z "$F" ]; then
  for c in "$R/tools/ffdec/ffdec.jar" "$R/../tools/ffdec/ffdec.jar"; do
    [ -f "$c" ] && F=$c && break
  done
fi
[ -n "$F" ] && [ -f "$F" ] || { echo "set FFDEC_JAR to the FFDec jar"; exit 1; }
[ -n "${HZ_JAVA_BIN:-}" ] && export PATH=$HZ_JAVA_BIN:$PATH
[ -n "${JAVA_HOME:-}" ] && export PATH="$JAVA_HOME/bin:$PATH"
mkdir -p "$O"
free_kb=$(df -Pk "$O" | awk 'NR==2 {print $4}')
if [ "$free_kb" -lt 6291456 ]; then echo "STOP: under 6 GB free on the output disk ($free_kb KB)"; exit 1; fi
mkdir -p $O/gfx $O/imp $O/verify
bad=0
for M in favoritesmenu favoritesmenu_lrg; do
  L=""; [ "$M" = "favoritesmenu_lrg" ] && L="--lrg"
  java -jar $F -selectclass FavoritesMenu -export script $O/imp/van_$M $V/$M.swf > $O/imp/van_$M.log 2>&1
  python3 $R/tools/apply_fav_hooks.py $O/imp/van_$M/scripts/FavoritesMenu.as $R/actionscript/favorites $O/imp/pimp_$M/FavoritesMenu.as $L || { bad=1; continue; }
  timeout 300 java -jar $F -importScript $V/$M.swf $O/gfx/$M.swf $O/imp/pimp_$M > $O/imp/fav_$M.log 2>&1
  if grep -v "^\s*at " $O/imp/fav_$M.log | grep -iq "severe\|error\|exception"; then echo "FAIL compile $M"; grep -v "^\s*at " $O/imp/fav_$M.log | grep -i "severe\|error\|exception" | head -8; bad=1; else echo "compile $M: no errors"; fi
  [ -s $O/gfx/$M.swf ] || { echo "FAIL no output $M"; bad=1; continue; }
  java -jar $F -selectclass FavoritesMenu -export script $O/verify/$M $O/gfx/$M.swf > /dev/null 2>&1
  java -jar $F -selectclass FavoritesMenu -format script:pcode -export script $O/verify/pc_$M $O/gfx/$M.swf > /dev/null 2>&1
  java -jar $F -selectclass FavoritesMenu -format script:pcode -export script $O/verify/pc_van_$M $V/$M.swf > /dev/null 2>&1
  ls -la $O/gfx/$M.swf
done
exit $bad
