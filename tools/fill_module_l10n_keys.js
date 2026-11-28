// Purpose: add Comms / scanner / message-log chrome keys missing from the
// shipped tables. Does not overwrite a user or prior translation. UTF-8, no BOM.
// Author: Moragar. Last modified: 2026-11-27.
"use strict";
const fs = require("fs");
const path = require("path");
const dir = path.join(__dirname, "..", "Data", "SFSE", "Plugins", "HorizonUI", "Localization");

function add(obj, k, v) {
	if (obj[k] == null || String(obj[k]).length === 0) obj[k] = v;
}

function slug(s) {
	let o = "";
	let prevUs = false;
	for (let i = 0; i < s.length && o.length < 48; i++) {
		const code = s.charCodeAt(i);
		const ok = (code >= 48 && code <= 57) || (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
		if (ok) {
			o += s.charAt(i).toLowerCase();
			prevUs = false;
		} else if (o.length > 0 && !prevUs) {
			o += "_";
			prevUs = true;
		}
	}
	if (o.length > 0 && o.charAt(o.length - 1) === "_") o = o.slice(0, -1);
	return o;
}

const TABLES = {
	en: {
		dlg: { OF: "OF", ABOVE: "ABOVE" },
		comms: { "Level up! You are now level {n}.": "Level up! You are now level {n}." },
		scan: {
			"Landing zone": "Landing zone",
			Follower: "Follower",
			Discovered: "Discovered",
			"Companion ship": "Companion ship",
			"still some to find here": "still some to find here",
			"none in this biome": "none in this biome",
			"nothing left to find here": "nothing left to find here",
			"No bounty": "No bounty",
			"no social skill to use": "no social skill to use"
		},
		ui: {
			ALL: "ALL",
			PIN: "PIN",
			"HORIZON UI · MESSAGE LOG": "HORIZON UI · MESSAGE LOG",
			find_ellipsis: "Find...",
			"Find (keyboard only)": "Find (keyboard only)",
			"Clear this session?": "Clear this session?",
			"Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.": "Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.",
			"PINNED {n} / {cap}": "PINNED {n} / {cap}",
			"Today · this session": "Today · this session",
			"This session": "This session",
			"Today · earlier": "Today · earlier",
			Earlier: "Earlier",
			" min ago": " min ago",
			" h ago": " h ago",
			" d ago": " d ago",
			"No messages for the types that are shown. Stored messages stay.": "No messages for the types that are shown. Stored messages stay.",
			"Starts empty. Messages from before this log was on cannot be recovered.": "Starts empty. Messages from before this log was on cannot be recovered.",
			"from a later point": "from a later point",
			local: "local",
			"Memory only. Existing files stay on disk.": "Memory only. Existing files stay on disk.",
			"SHOW hides rows in this log. RECORD chooses what is saved.": "SHOW hides rows in this log. RECORD chooses what is saved.",
			"OLD CHARACTERS ({n} FILES)": "OLD CHARACTERS ({n} FILES)",
			"Clear all history?": "Clear all history?",
			"Removes every unpinned message for this character. Pins stay. Can't be undone.": "Removes every unpinned message for this character. Pins stay. Can't be undone.",
			"Read-only. The current character is not listed.": "Read-only. The current character is not listed.",
			"No other character files.": "No other character files.",
			messages: "messages",
			Saving: "Saving"
		}
	},
	de: {
		dlg: { of: "VON", above: "DARÜBER" },
		comms: { level_up_you_are_now_level_n: "Aufstieg! Du bist jetzt Stufe {n}." },
		scan: {
			landing_zone: "Landezone",
			follower: "Begleiter",
			discovered: "Entdeckt",
			companion_ship: "Begleiterschiff",
			still_some_to_find_here: "hier ist noch etwas zu finden",
			none_in_this_biome: "nichts in diesem Biom",
			nothing_left_to_find_here: "hier ist nichts mehr zu finden",
			no_bounty: "Kein Kopfgeld",
			no_social_skill_to_use: "keine Sozialfertigkeit nutzbar"
		},
		ui: {
			all: "ALLE",
			pin: "ANHEFTEN",
			horizon_ui_message_log: "HORIZON UI · NACHRICHTENPROTOKOLL",
			find_ellipsis: "Suchen...",
			find_keyboard_only: "Suchen (nur Tastatur)",
			clear_this_session: "Diese Sitzung leeren?",
			"Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.": "Entfernt {n} angezeigte, nicht angeheftete Nachrichten. Ausgeblendete bleiben. Das kann nicht rückgängig gemacht werden.",
			pinned_n_cap: "ANGEHEFTET {n} / {cap}",
			today_this_session: "Heute · diese Sitzung",
			this_session: "Diese Sitzung",
			today_earlier: "Heute · früher",
			earlier: "Früher",
			min_ago: " Min. her",
			h_ago: " Std. her",
			d_ago: " T. her",
			no_messages_for_the_types_that_are_shown_stored: "Keine Nachrichten für die angezeigten Arten. Gespeicherte bleiben.",
			"Starts empty. Messages from before this log was on cannot be recovered.": "Beginnt leer. Nachrichten von vor diesem Protokoll können nicht wiederhergestellt werden.",
			from_a_later_point: "von einem späteren Punkt",
			local: "lokal",
			memory_only_existing_files_stay_on_disk: "Nur Speicher. Vorhandene Dateien bleiben auf der Festplatte.",
			show_hides_rows_in_this_log_record_chooses_what: "ANZEIGEN blendet Zeilen in diesem Protokoll aus. AUFZEICHNEN wählt, was gespeichert wird.",
			old_characters_n_files: "ALTE CHARAKTERE ({n} DATEIEN)",
			clear_all_history: "Gesamten Verlauf leeren?",
			"Removes every unpinned message for this character. Pins stay. Can't be undone.": "Entfernt jede nicht angeheftete Nachricht dieses Charakters. Anheftungen bleiben. Das kann nicht rückgängig gemacht werden.",
			read_only_the_current_character_is_not_listed: "Schreibgeschützt. Der aktuelle Charakter ist nicht aufgeführt.",
			no_other_character_files: "Keine anderen Charakterdateien.",
			messages: "Nachrichten",
			saving: "Speichern"
		}
	},
	es: {
		dlg: { of: "DE", above: "ARRIBA" },
		comms: { level_up_you_are_now_level_n: "¡Subiste de nivel! Ahora eres nivel {n}." },
		scan: {
			landing_zone: "Zona de aterrizaje",
			follower: "Seguidor",
			discovered: "Descubierto",
			companion_ship: "Nave compañera",
			still_some_to_find_here: "aún queda algo por encontrar aquí",
			none_in_this_biome: "nada en este bioma",
			nothing_left_to_find_here: "no queda nada por encontrar aquí",
			no_bounty: "Sin recompensa",
			no_social_skill_to_use: "ninguna habilidad social que usar"
		},
		ui: {
			all: "TODO",
			pin: "FIJAR",
			horizon_ui_message_log: "HORIZON UI · REGISTRO DE MENSAJES",
			find_ellipsis: "Buscar...",
			find_keyboard_only: "Buscar (solo teclado)",
			clear_this_session: "¿Borrar esta sesión?",
			"Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.": "Quita {n} mensajes visibles no fijados. Los ocultos se quedan. No se puede deshacer.",
			pinned_n_cap: "FIJADOS {n} / {cap}",
			today_this_session: "Hoy · esta sesión",
			this_session: "Esta sesión",
			today_earlier: "Hoy · antes",
			earlier: "Antes",
			min_ago: " min atrás",
			h_ago: " h atrás",
			d_ago: " d atrás",
			no_messages_for_the_types_that_are_shown_stored: "No hay mensajes de los tipos que se muestran. Los guardados se quedan.",
			"Starts empty. Messages from before this log was on cannot be recovered.": "Empieza vacío. Los mensajes de antes de este registro no se pueden recuperar.",
			from_a_later_point: "desde un punto posterior",
			local: "local",
			memory_only_existing_files_stay_on_disk: "Solo memoria. Los archivos existentes se quedan en el disco.",
			show_hides_rows_in_this_log_record_chooses_what: "MOSTRAR oculta filas de este registro. GRABAR elige qué se guarda.",
			old_characters_n_files: "PERSONAJES ANTIGUOS ({n} ARCHIVOS)",
			clear_all_history: "¿Borrar todo el historial?",
			"Removes every unpinned message for this character. Pins stay. Can't be undone.": "Quita todos los mensajes no fijados de este personaje. Los fijados se quedan. No se puede deshacer.",
			read_only_the_current_character_is_not_listed: "Solo lectura. El personaje actual no aparece.",
			no_other_character_files: "No hay archivos de otros personajes.",
			messages: "mensajes",
			saving: "Guardando"
		}
	},
	"es-mx": {
		dlg: { of: "DE", above: "ARRIBA" },
		comms: { level_up_you_are_now_level_n: "¡Subiste de nivel! Ahora eres nivel {n}." },
		scan: {
			landing_zone: "Zona de aterrizaje",
			follower: "Seguidor",
			discovered: "Descubierto",
			companion_ship: "Nave compañera",
			still_some_to_find_here: "aún queda algo por encontrar aquí",
			none_in_this_biome: "nada en este bioma",
			nothing_left_to_find_here: "no queda nada por encontrar aquí",
			no_bounty: "Sin recompensa",
			no_social_skill_to_use: "ninguna habilidad social que usar"
		},
		ui: {
			all: "TODO",
			pin: "FIJAR",
			horizon_ui_message_log: "HORIZON UI · REGISTRO DE MENSAJES",
			find_ellipsis: "Buscar...",
			find_keyboard_only: "Buscar (solo teclado)",
			clear_this_session: "¿Borrar esta sesión?",
			"Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.": "Quita {n} mensajes visibles no fijados. Los ocultos se quedan. No se puede deshacer.",
			pinned_n_cap: "FIJADOS {n} / {cap}",
			today_this_session: "Hoy · esta sesión",
			this_session: "Esta sesión",
			today_earlier: "Hoy · antes",
			earlier: "Antes",
			min_ago: " min atrás",
			h_ago: " h atrás",
			d_ago: " d atrás",
			no_messages_for_the_types_that_are_shown_stored: "No hay mensajes de los tipos que se muestran. Los guardados se quedan.",
			"Starts empty. Messages from before this log was on cannot be recovered.": "Empieza vacío. Los mensajes de antes de este registro no se pueden recuperar.",
			from_a_later_point: "desde un punto posterior",
			local: "local",
			memory_only_existing_files_stay_on_disk: "Solo memoria. Los archivos existentes se quedan en el disco.",
			show_hides_rows_in_this_log_record_chooses_what: "MOSTRAR oculta filas de este registro. GRABAR elige qué se guarda.",
			old_characters_n_files: "PERSONAJES ANTIGUOS ({n} ARCHIVOS)",
			clear_all_history: "¿Borrar todo el historial?",
			"Removes every unpinned message for this character. Pins stay. Can't be undone.": "Quita todos los mensajes no fijados de este personaje. Los fijados se quedan. No se puede deshacer.",
			read_only_the_current_character_is_not_listed: "Solo lectura. El personaje actual no aparece.",
			no_other_character_files: "No hay archivos de otros personajes.",
			messages: "mensajes",
			saving: "Guardando"
		}
	},
	fr: {
		dlg: { of: "SUR", above: "AU-DESSUS" },
		comms: { level_up_you_are_now_level_n: "Niveau supérieur ! Vous êtes maintenant niveau {n}." },
		scan: {
			landing_zone: "Zone d'atterrissage",
			follower: "Suiveur",
			discovered: "Découvert",
			companion_ship: "Vaisseau compagnon",
			still_some_to_find_here: "il reste des choses ici",
			none_in_this_biome: "rien dans ce biome",
			nothing_left_to_find_here: "plus rien à trouver ici",
			no_bounty: "Aucune prime",
			no_social_skill_to_use: "aucune compétence sociale"
		},
		ui: {
			all: "TOUT",
			pin: "FIXER",
			horizon_ui_message_log: "HORIZON UI · JOURNAL",
			find_ellipsis: "Chercher...",
			find_keyboard_only: "Chercher (clavier seul)",
			clear_this_session: "Effacer cette session ?",
			"Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.": "Retire {n} messages visibles non fixés. Les messages masqués restent. Irréversible.",
			pinned_n_cap: "FIXÉS {n} / {cap}",
			today_this_session: "Aujourd'hui · cette session",
			this_session: "Cette session",
			today_earlier: "Aujourd'hui · plus tôt",
			earlier: "Plus tôt",
			min_ago: " min",
			h_ago: " h",
			d_ago: " j",
			no_messages_for_the_types_that_are_shown_stored: "Aucun message pour les types affichés. Les messages stockés restent.",
			"Starts empty. Messages from before this log was on cannot be recovered.": "Vide au départ. Les messages d'avant l'activation de ce journal ne peuvent pas être récupérés.",
			from_a_later_point: "à partir d'un moment plus tard",
			local: "local",
			memory_only_existing_files_stay_on_disk: "Mémoire seulement. Les fichiers existants restent sur le disque.",
			show_hides_rows_in_this_log_record_chooses_what: "AFFICHER masque des lignes de ce journal. ENREG. choisit ce qui est sauvé.",
			old_characters_n_files: "ANCIENS PERSONNAGES ({n} FICHIERS)",
			clear_all_history: "Effacer tout l'historique ?",
			"Removes every unpinned message for this character. Pins stay. Can't be undone.": "Retire chaque message non fixé de ce personnage. Les messages fixés restent. Irréversible.",
			read_only_the_current_character_is_not_listed: "Lecture seule. Le personnage actuel n'est pas listé.",
			no_other_character_files: "Aucun autre fichier de personnage.",
			messages: "messages",
			saving: "Enregistrement"
		}
	},
	pl: {
		dlg: { of: "Z", above: "POWYŻEJ" },
		comms: { level_up_you_are_now_level_n: "Awans! Jesteś teraz na poz. {n}." },
		scan: {
			landing_zone: "Strefa lądowania",
			follower: "Towarzysz",
			discovered: "Odkryto",
			companion_ship: "Statek towarzysza",
			still_some_to_find_here: "tu jeszcze coś zostało",
			none_in_this_biome: "brak w tym biomie",
			nothing_left_to_find_here: "tu już nic nie zostało",
			no_bounty: "Brak nagrody",
			no_social_skill_to_use: "brak umiej. społecznej"
		},
		ui: {
			all: "WSZYSTKO",
			pin: "PRZYPNIJ",
			horizon_ui_message_log: "HORIZON UI · DZIENNIK",
			find_ellipsis: "Szukaj...",
			find_keyboard_only: "Szukaj (tylko klawiatura)",
			clear_this_session: "Wyczyścić tę sesję?",
			"Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.": "Usuwa {n} pokazanych nieprzypiętych wiadomości. Ukryte zostają. Nie cofniesz.",
			pinned_n_cap: "PRZYPĘTE {n} / {cap}",
			today_this_session: "Dziś · ta sesja",
			this_session: "Ta sesja",
			today_earlier: "Dziś · wcześniej",
			earlier: "Wcześniej",
			min_ago: " min temu",
			h_ago: " godz. temu",
			d_ago: " dn. temu",
			no_messages_for_the_types_that_are_shown_stored: "Brak wiadomości dla pokazanych typów. Zapisane zostają.",
			"Starts empty. Messages from before this log was on cannot be recovered.": "Na początku pusty. Wiadomości sprzed włączenia dziennika nie da się odzyskać.",
			from_a_later_point: "od późniejszego momentu",
			local: "lokalny",
			memory_only_existing_files_stay_on_disk: "Tylko pamięć. Istniejące pliki zostają na dysku.",
			show_hides_rows_in_this_log_record_chooses_what: "POKAŻ ukrywa wiersze w tym dzienniku. ZAPISUJ wybiera, co jest zapisywane.",
			old_characters_n_files: "STARE POSTACIE ({n} PLIKÓW)",
			clear_all_history: "Wyczyścić całą historię?",
			"Removes every unpinned message for this character. Pins stay. Can't be undone.": "Usuwa każdą nieprzypiętą wiadomość tej postaci. Przypięte zostają. Nie cofniesz.",
			read_only_the_current_character_is_not_listed: "Tylko odczyt. Bieżąca postać nie jest na liście.",
			no_other_character_files: "Brak plików innych postaci.",
			messages: "wiadomości",
			saving: "Zapisywanie"
		}
	},
	"zh-cn": {
		dlg: { of: "/", above: "上方" },
		comms: { level_up_you_are_now_level_n: "升级！你现在是等级 {n}。" },
		scan: {
			landing_zone: "降落区",
			follower: "跟随者",
			discovered: "已发现",
			companion_ship: "同伴飞船",
			still_some_to_find_here: "这里还有未发现的",
			none_in_this_biome: "此生物群系中没有",
			nothing_left_to_find_here: "这里已全部发现",
			no_bounty: "无赏金",
			no_social_skill_to_use: "没有可用的社交技能"
		},
		ui: {
			all: "全部",
			pin: "固定",
			horizon_ui_message_log: "HORIZON UI · 消息日志",
			find_ellipsis: "查找...",
			find_keyboard_only: "查找（仅键盘）",
			clear_this_session: "清除本次会话？",
			"Removes {n} shown unpinned messages. Hidden messages stay. Can't be undone.": "将删除 {n} 条显示中的未固定消息。隐藏的消息会保留。无法撤销。",
			pinned_n_cap: "已固定 {n} / {cap}",
			today_this_session: "今天 · 本次会话",
			this_session: "本次会话",
			today_earlier: "今天 · 更早",
			earlier: "更早",
			min_ago: " 分钟前",
			h_ago: " 小时前",
			d_ago: " 天前",
			no_messages_for_the_types_that_are_shown_stored: "当前显示类型没有消息。已存储的消息会保留。",
			"Starts empty. Messages from before this log was on cannot be recovered.": "开始时为空。此日志开启之前的消息无法恢复。",
			from_a_later_point: "来自更晚的时间点",
			local: "本地",
			memory_only_existing_files_stay_on_disk: "仅内存。磁盘上的现有文件会保留。",
			show_hides_rows_in_this_log_record_chooses_what: "显示会隐藏此日志中的行。记录选择保存内容。",
			old_characters_n_files: "旧角色（{n} 个文件）",
			clear_all_history: "清除全部历史？",
			"Removes every unpinned message for this character. Pins stay. Can't be undone.": "将删除该角色的每条未固定消息。固定项会保留。无法撤销。",
			read_only_the_current_character_is_not_listed: "只读。当前角色不在列表中。",
			no_other_character_files: "没有其他角色文件。",
			messages: "条消息",
			saving: "正在保存"
		}
	}
};

let n = 0;
for (const code of Object.keys(TABLES)) {
	const p = path.join(dir, code + ".json");
	const j = JSON.parse(fs.readFileSync(p, "utf8"));
	const t = TABLES[code];
	if (!j.dlg) j.dlg = {};
	if (!j.dlg.hud_label) j.dlg.hud_label = {};
	if (!j.comms) j.comms = {};
	if (!j.comms.hud_label) j.comms.hud_label = {};
	if (!j.scan) j.scan = {};
	if (!j.scan.hud_label) j.scan.hud_label = {};
	if (!j.settings) j.settings = {};
	if (!j.settings.ui) j.settings.ui = {};
	for (const [k, v] of Object.entries(t.dlg)) add(j.dlg.hud_label, slug(k), v);
	for (const [k, v] of Object.entries(t.comms)) add(j.comms.hud_label, slug(k), v);
	for (const [k, v] of Object.entries(t.scan)) add(j.scan.hud_label, slug(k), v);
	for (const [k, v] of Object.entries(t.ui)) add(j.settings.ui, slug(k), v);
	const out = JSON.stringify(j, null, 2) + "\n";
	fs.writeFileSync(p, out);
	n++;
	console.log("updated " + code + ".json");
}
console.log("filled module l10n keys in " + n + " files");
