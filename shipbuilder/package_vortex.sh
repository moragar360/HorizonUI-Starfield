#!/bin/sh
# Stage a Vortex FOMOD for Horizon Ship Builder alone.
# The installer places one folder into the Data folder of the game root.
# It installs the builder DLL, both editor movies, and the default ini.
# It does not install HUD files. There is no component picker.
#
# Usage:
#   shipbuilder/package_vortex.sh <dll> <spaceshipeditormenu.swf> <spaceshipeditormenu_lrg.swf> <out.zip>
#
# The two movies must already be the spliced movies from the desktop builder.
# This script refuses a stock hash and a movie with no HorizonShipBuilder marker.
# Run shipbuilder/font_marker_gate.py on each spliced movie before this script.

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

# Stock spaceshipeditormenu.swf and spaceshipeditormenu_lrg.swf for game 1.16.244.
# A match means the desktop builder did not splice the movie.
stock_normal=6A66089EE9410ECB126B4BEDE8BED81551E5661555AA1F50FA217C495404C2EC
stock_large=3457A49CF9B79A346C4B3FCFA7EF360B10CCC86D41899B6D8004DF12E90F2C67

require_spliced() {
	file=$1
	stock=$2
	label=$3
	if ! command -v sha256sum >/dev/null 2>&1; then
		echo "sha256sum is required to check that the movies are spliced" >&2
		exit 1
	fi
	sum=$(sha256sum "$file" | awk '{print $1}' | tr 'a-f' 'A-F')
	if [ "$sum" = "$stock" ]; then
		echo "$label matches the stock movie hash, not a spliced builder movie" >&2
		exit 1
	fi
	if ! grep -a -q -F 'HorizonShipBuilder' "$file"; then
		echo "$label has no HorizonShipBuilder splice marker" >&2
		exit 1
	fi
}

require_spliced "$normal" "$stock_normal" "spaceshipeditormenu.swf"
require_spliced "$large" "$stock_large" "spaceshipeditormenu_lrg.swf"

root=$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)
ini="$root/shipbuilder/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini"
info="$root/shipbuilder/fomod/info.xml"
module="$root/shipbuilder/fomod/ModuleConfig.xml"
ver=$(sed -n 's/^#define HSB_FILE_VERSION_STR "\([^"]*\)".*/\1/p' "$root/shipbuilder/src/hsb_version.h")
if [ ! -f "$ini" ]; then
	echo "missing default ini: $ini" >&2
	exit 1
fi
if [ ! -f "$info" ] || [ ! -f "$module" ]; then
	echo "missing fomod/info.xml or fomod/ModuleConfig.xml" >&2
	exit 1
fi
if [ -z "$ver" ]; then
	echo "missing plugin version" >&2
	exit 1
fi

stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT

payload="$stage/00 Ship Builder"
mkdir -p "$payload/SFSE/Plugins" \
	"$payload/Interface/HorizonUI/shipbuilder" \
	"$stage/fomod"
cp "$dll" "$payload/SFSE/Plugins/HorizonShipBuilder.dll"
cp "$normal" "$payload/Interface/spaceshipeditormenu.swf"
cp "$large" "$payload/Interface/spaceshipeditormenu_lrg.swf"
cp "$ini" "$payload/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini"
cp "$info" "$stage/fomod/info.xml"
cp "$module" "$stage/fomod/ModuleConfig.xml"

# Installed paths, relative to the Data folder of the game root:
# 00 Ship Builder/SFSE/Plugins/HorizonShipBuilder.dll
# 00 Ship Builder/Interface/spaceshipeditormenu.swf
# 00 Ship Builder/Interface/spaceshipeditormenu_lrg.swf
# 00 Ship Builder/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini
# fomod/info.xml
# fomod/ModuleConfig.xml
expected="00 Ship Builder/Interface/HorizonUI/shipbuilder/HorizonShipBuilder.default.ini
00 Ship Builder/Interface/spaceshipeditormenu.swf
00 Ship Builder/Interface/spaceshipeditormenu_lrg.swf
00 Ship Builder/SFSE/Plugins/HorizonShipBuilder.dll
fomod/ModuleConfig.xml
fomod/info.xml"
files=$(find "$stage" -type f | sed "s|^$stage/||" | LC_ALL=C sort)
if [ "$files" != "$expected" ]; then
	echo "FOMOD file list does not match the builder-only package" >&2
	printf '%s\n' "$files" >&2
	exit 1
fi

author='<Author>Moragar</Author>'
if ! grep -F -q "$author" "$stage/fomod/info.xml"; then
	echo "fomod/info.xml author is not Moragar" >&2
	exit 1
fi
if ! grep -F -q "<Version>${ver}</Version>" "$stage/fomod/info.xml"; then
	echo "fomod/info.xml version is not ${ver}" >&2
	exit 1
fi
if ! grep -F -q 'source="00 Ship Builder"' "$stage/fomod/ModuleConfig.xml"; then
	echo "fomod/ModuleConfig.xml does not install the builder folder" >&2
	exit 1
fi
if ! grep -F -q '<requiredInstallFiles>' "$stage/fomod/ModuleConfig.xml"; then
	echo "fomod/ModuleConfig.xml has no required install" >&2
	exit 1
fi

mkdir -p "$(dirname "$out")"
rm -f "$out"
(
	cd "$stage"
	zip -r -X "$out" "00 Ship Builder" fomod
)
echo "wrote $out"
