/datum/player_note
	var/note_type = NOTE_TYPE_NOTE
	var/apply_date = 0
	var/playtime_during_apply = 0
	var/round_id = ""
	var/label = ""
	var/user_label = ""
	var/content = ""

/datum/player_note/proc/is_removable()
	if(note_type == NOTE_TYPE_NOTE)
		return TRUE
	return FALSE

/datum/player_note/proc/save_to_json_list()
	var/list/json = list()
	json["note_type"] = note_type
	json["apply_date"] = apply_date
	json["playtime_during_apply"] = playtime_during_apply
	json["round_id"] = round_id
	json["label"] = label
	json["user_label"] = user_label
	json["content"] = content
	return json

/datum/player_note/proc/load_from_json_list(list/json)
	note_type = json["note_type"]
	apply_date = json["apply_date"]
	playtime_during_apply = json["playtime_during_apply"]
	round_id = json["round_id"]
	label = json["label"]
	if(json["user_label"])
		user_label = json["user_label"]
	content = json["content"]
