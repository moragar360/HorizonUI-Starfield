// 0.43.5 Extended Quick Menu: F11 rows, movie hooks, and source rules.
const fs = require("fs");
const path = require("path");
const root = path.resolve(__dirname, "..");
const read = (p) => fs.readFileSync(path.join(root, p), "utf8");
let failed = 0;
const expect = (c, m) => { if (!c) { console.error("FAIL " + m); failed++; } };

const as = read("actionscript/horizon_block.as");
const qm = read("actionscript/favorites/hzq_main.as");
const hdr = read("src/hz_quickslots.h");
const ini = read("Interface/HorizonUI/HorizonUI.default.ini");
const ver = read("src/hz_version.h");
const game = read("src/hz_quickslots_game.h");

expect(/private static const HZ_VERSION:String = "0\.43\.5\.0"/.test(as), "settings schema HZ_VERSION is 0.43.5.0 (SCAN REACH)");
expect(/#define HZ_FILE_VERSION_STR "0\.43\.5\.0"/.test(ver), "file version is 0.43.5.0");
expect(/QuickMenuExtended=0/.test(ini) && /QuickMenuSlotCount=24/.test(ini) && /QuickMenuSlotsPerRow=6/.test(ini) && /QuickMenuExtendedLayout=0/.test(ini), "default.ini has Extended Mode off, 24 slots, 6 per row, CROSS+BARS");
expect(/QuickMenuKey13=\r?\n/.test(ini) && /QuickMenuKey24=\r?\n/.test(ini), "default.ini leaves keys 13-24 empty");

for (const k of ["QuickMenuExtended","QuickMenuSlotCount","QuickMenuSlotsPerRow","QuickMenuExtendedLayout","QuickMenuKey13","QuickMenuKey24"]) {
	expect(as.indexOf('"k":"' + k + '"') >= 0, "F11 row " + k);
}
expect(/"k":"QuickMenuExtendedLayout".*"opts":\["CROSS \+ BARS","BARS"\]/.test(as), "EXTENDED LAYOUT options are CROSS + BARS and BARS");
expect(/"k":"QuickMenuSlotsPerRow".*"opts":\["4","6","8"\]/.test(as), "SLOTS PER ROW is 4/6/8");
expect(/"k":"QuickMenuKey13".*"t":"k"/.test(as), "slot keys use type k (includes NONE)");
expect(as.indexOf("HZ_QM_NAMED") >= 0 && as.indexOf("hzQmCapBegin") >= 0 && as.indexOf("PRESS A KEY") >= 0, "type k captures the next key (rebind prompt), not a preset list");
expect(as.indexOf("Favorites Menu Extended") >= 0 && as.indexOf("Favorites Banks") >= 0, "F11 lock note names the conflicting mods");
expect(as.indexOf("hzQmSetConflict") >= 0 && as.indexOf("hzQmSetSlotCount") >= 0, "HUD has conflict and slot-count setters");

expect(qm.indexOf("hzqExtPrepare") >= 0 && qm.indexOf("hzqExtPlace") >= 0 && qm.indexOf("hzqExtCmd") >= 0, "quick menu movie has Extended Mode hooks");
expect(qm.indexOf("HZQ_PITCH:Number = 70") >= 0, "slot pitch is 70 (58 box + 12 gap)");
expect(qm.indexOf("selectedIndex = 12") >= 0, "extended selection uses FS_NONE, never a vanilla index past 12");
expect(qm.indexOf("hzqExt_") >= 0 && qm.indexOf("hzqExtAdd") >= 0, "extended clips and ADD SLOT tile exist");
// must not dispatch vanilla use/assign with an index past 11
expect(!/uQuickkeyIndex["']?\s*:\s*this\.hzqExt/.test(qm), "does not send extended indexes on FavoritesMenu_UseQuickkey");

expect(hdr.indexOf("kIdUseInventoryItem = 101954") >= 0 && hdr.indexOf("kIdUseSpell = 101916") >= 0, "public use IDs are pinned");
expect(hdr.indexOf("FavoritesMenuExtended.dll") >= 0 && hdr.indexOf("FavoritesBanks.dll") >= 0, "conflict DLL names listed");
expect(game.indexOf("UseInventoryItem") >= 0 && game.indexOf("kIdUseSpell") >= 0, "DLL wrappers call the public use path");
expect(game.indexOf("WriteSafeData") < 0 && game.indexOf("write_call") < 0, "no code hooks or patches in the use wrappers");

const blob = as + "\n" + qm + "\n" + hdr + "\n" + game + "\n" + ini;
// Private words (owner, account and computer names) come from HZ_PATH_WORDS (comma-separated, never committed),
// the same as dll_paths_check.js. With none set, only the generic Windows user-folder check runs.
const privWords = (process.env.HZ_PATH_WORDS || "").split(",").map((w) => w.trim().toLowerCase()).filter((w) => w.length >= 3);
const blobL = blob.toLowerCase();
for (const w of privWords) expect(blobL.indexOf(w) < 0, "no private word (HZ_PATH_WORDS entry " + (privWords.indexOf(w) + 1) + ") in Quick Menu sources");
expect(!/[a-z]:\\users\\/i.test(blob), "no Windows user folder path in Quick Menu sources");

if (failed) { console.error(failed + " failed"); process.exit(1); }
console.log("quickmenu24_test ok");
