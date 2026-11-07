#!/bin/sh
# Stage a Vortex-installable zip for Horizon Ship Builder alone.
# Deployment root is the game root (".").
# The archive contains one Data folder. Installing it at the game root
# yields Data/SFSE/Plugins and Data/Interface.
# This is not the combined HUD installer.
#
# Usage:
#   shipbuilder/package_vortex.sh <dll> <spaceshipeditormenu.swf> <spaceshipeditormenu_lrg.swf> <out.zip>
#
# The two movies must already be the spliced movies from the desktop builder.

set -eu

if [ "$#" -ne 4 ]; then
	echo "usage: shipbuilder/package_vortex.sh <dll> <normal.swf> <large.swf> <out.zip>" >&2
	exit 2
fi

dll=$1
normal=$2
large=$3
out=$4
case "$out" in
	/*) ;;
	*) out="$(pwd)/$out" ;;
esac

for f in "$dll" "$normal" "$large"; do
	if [ ! -f "$f" ]; then
		echo "missing file: $f" >&2
		exit 1
	fi
done

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ini="$root/shipbuilder/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini"
if [ ! -f "$ini" ]; then
	echo "missing default ini: $ini" >&2
	exit 1
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

mkdir -p "$stage/Data/SFSE/Plugins" \
	"$stage/Data/Interface/HorizonUI/shipbuilder"
cp "$dll" "$stage/Data/SFSE/Plugins/HorizonShipBuilder.dll"
cp "$normal" "$stage/Data/Interface/spaceshipeditormenu.swf"
cp "$large" "$stage/Data/Interface/spaceshipeditormenu_lrg.swf"
cp "$ini" "$stage/Data/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini"

mkdir -p "$(dirname "$out")"
rm -f "$out"
(
	cd "$stage"
	zip -r -X "$out" Data
)
echo "wrote $out"
