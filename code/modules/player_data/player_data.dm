/datum/player_data
	var/ckey
	var/inspirations = 0
	var/tier = 1
	var/active_donator = FALSE
	var/donator_tier = 0
	var/whitelisted = FALSE
	var/playtime = 0
	var/age_id_verified = FALSE
	var/did_required_reading = FALSE
	var/discord_id = ""
	var/last_pin_commends = 0
	var/last_pin_complaints = 0
	var/list/notes = list()

/datum/player_data/proc/save_to_json_list()
	var/list/json = list()
	json["inspirations"] = inspirations
	json["tier"] = tier
	json["discord_id"] = discord_id
	json["whitelisted"] = whitelisted
	json["playtime"] = playtime
	json["age_id_verified"] = age_id_verified
	json["did_required_reading"] = did_required_reading
	json["last_pin_commends"] = last_pin_commends
	json["last_pin_complaints"] = last_pin_complaints
	json["active_donator"] = active_donator
	json["donator_tier"] = donator_tier
	json["notes"] = list()
	var/list/note_list = json["notes"]
	for(var/datum/player_note/instance as anything in notes)
		note_list.len++
		note_list[note_list.len] = instance.save_to_json_list()
	return json

/datum/player_data/proc/load_from_json_list(list/json)
	inspirations = json["inspirations"]
	tier = json["tier"]
	discord_id = json["discord_id"]
	whitelisted = json["whitelisted"]
	playtime = json["playtime"]
	age_id_verified = json["age_id_verified"]
	did_required_reading = json["did_required_reading"]
	last_pin_commends = json["last_pin_commends"]
	last_pin_complaints = json["last_pin_complaints"]
	active_donator = json["active_donator"]
	active_donator = sanitize_integer(active_donator, FALSE, TRUE, FALSE)
	donator_tier = json["donator_tier"]
	donator_tier = sanitize_integer(donator_tier, 0, MAX_DONATOR_TIER, 0)
	notes = list()
	for(var/list/list as anything in json["notes"])
		var/datum/player_note/instance = new /datum/player_note()
		instance.load_from_json_list(list)
		notes += instance

/datum/player_data/proc/get_all_notes_of_type(note_type)
	var/list/total_notes = list()
	for(var/datum/player_note/instance as anything in notes)
		if(instance.note_type != note_type)
			continue
		total_notes += instance
	return reverseList(total_notes)

/datum/player_data/proc/set_tier(new_tier)
	if(IsAdminAdvancedProcCall())
		return
	tier = new_tier
	save_player_data_for_ckey(ckey)

/datum/player_data/proc/set_discord_id(new_id)
	if(IsAdminAdvancedProcCall())
		return
	discord_id = new_id
	save_player_data_for_ckey(ckey)

/datum/player_data/proc/set_id_verification(new_status)
	if(IsAdminAdvancedProcCall())
		return
	age_id_verified = new_status
	save_player_data_for_ckey(ckey)

/datum/player_data/proc/set_active_donator_status(new_status)
	if(IsAdminAdvancedProcCall())
		return
	active_donator = new_status
	active_donator = sanitize_integer(active_donator, FALSE, TRUE, FALSE)
	save_player_data_for_ckey(ckey)

/datum/player_data/proc/set_donator_tier(new_tier)
	if(IsAdminAdvancedProcCall())
		return
	donator_tier = new_tier
	donator_tier = sanitize_integer(donator_tier, 0, MAX_DONATOR_TIER, 0)
	save_player_data_for_ckey(ckey)

/datum/player_data/proc/add_note(label, user_label, reason, note_type)
	if(IsAdminAdvancedProcCall())
		return
	var/datum/player_note/instance = new /datum/player_note()
	instance.label = label
	instance.user_label = user_label
	instance.content = reason
	instance.note_type = note_type
	instance.playtime_during_apply = playtime
	instance.apply_date = world.realtime
	instance.round_id = GLOB.round_id
	notes += instance
	save_player_data_for_ckey(ckey)
	consider_pin()

/datum/player_data/proc/consider_pin()
	var/req_complaint_amt = 2
	var/req_commend_amt = 2
	switch(tier)
		if(1)
			req_commend_amt = 2
		if(2)
			req_commend_amt = 3
		if(3)
			req_commend_amt = 5
	var/new_complaints = length(get_all_notes_of_type(NOTE_TYPE_COMPLAINT)) - last_pin_complaints
	var/new_commends = length(get_all_notes_of_type(NOTE_TYPE_COMMEND)) - last_pin_commends
	var/pass_pin = FALSE
	if(new_complaints >= req_complaint_amt)
		pass_pin = TRUE
	if(new_commends >= req_commend_amt)
		pass_pin = TRUE
	if(!pass_pin)
		return
	add_evaluation_pin(ckey, "Tier:[tier]. NEW: [new_commends] commends; [new_complaints] complaints")

/datum/player_data/proc/after_unpin()
	last_pin_complaints = length(get_all_notes_of_type(NOTE_TYPE_COMPLAINT))
	last_pin_commends = length(get_all_notes_of_type(NOTE_TYPE_COMMEND))
	save_player_data_for_ckey(ckey)

/proc/get_player_data_for_ckey(passed_ckey)
	if(IsAdminAdvancedProcCall())
		return
	passed_ckey = ckey(passed_ckey)
	if(!GLOB.ckey_player_data[passed_ckey])
		load_player_data_for_ckey(passed_ckey)
	return GLOB.ckey_player_data[passed_ckey]

/proc/load_player_data_for_ckey(passed_ckey)
	if(IsAdminAdvancedProcCall())
		return
	if(GLOB.ckey_player_data[passed_ckey])
		return
	var/target_file = file("data/player_saves/[passed_ckey[1]]/[passed_ckey]/player_data.json")
	var/datum/player_data/pdata = new /datum/player_data()
	pdata.ckey = passed_ckey
	if(fexists(target_file))
		pdata.load_from_json_list(json_decode(file2text(target_file)))
	GLOB.ckey_player_data[passed_ckey] = pdata
	pdata.consider_pin()

/proc/save_player_data_for_ckey(passed_ckey)
	if(IsAdminAdvancedProcCall())
		return
	if(!GLOB.ckey_player_data[passed_ckey])
		load_player_data_for_ckey(passed_ckey)
	var/target_file = file("data/player_saves/[passed_ckey[1]]/[passed_ckey]/player_data.json")
	if(fexists(target_file))
		fdel(target_file)
	var/datum/player_data/pdata = GLOB.ckey_player_data[passed_ckey]
	WRITE_FILE(target_file, json_encode(pdata.save_to_json_list()))

/proc/save_all_player_data()
	for(var/ckey in GLOB.ckey_player_data)
		save_player_data_for_ckey(ckey)

/proc/get_player_tier_by_ckey(ckey)
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	return pdata.tier

/mob/proc/get_player_tier()
	if(!ckey)
		return 1
	if(!client)
		return 1
	if(client.holder || GLOB.deadmins[ckey])
		return PLAYER_TIER_MAX
	return get_player_tier_by_ckey(ckey)

/proc/player_tier_to_label(tier)
	switch(tier)
		if(1)
			return "Carrion"
		if(2)
			return "Meat"
		if(3)
			return "Vulture"
	return "Something"

/proc/donator_tier_to_label(tier)
	switch(tier)
		if(0)
			return "None"
		if(1)
			return "Migrant"
		if(2)
			return "Dweller"
		if(3)
			return "Pecker"
	return "None"

/mob/proc/is_active_donator()
	if(!ckey)
		return FALSE
	if((client && client.holder) || GLOB.deadmins[ckey])
		return TRUE
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	return pdata.active_donator

/mob/proc/get_donator_tier()
	if(!ckey)
		return 0
	if((client && client.holder) || GLOB.deadmins[ckey])
		return MAX_DONATOR_TIER
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	return pdata.donator_tier

/mob/proc/get_inspiration_amount()
	if(!ckey)
		return 0
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	return pdata.inspirations

/mob/proc/has_inspiration_amount(amount)
	var/insp_amt = get_inspiration_amount()
	if(insp_amt < amount)
		return FALSE
	return TRUE

/mob/proc/adjust_inspiration(amount, silent = FALSE)
	if(!ckey)
		return
	if(amount == 0)
		return
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	var/pre_amount = pdata.inspirations
	var/post_amount = clamp(pre_amount + amount, 0, INSPIRATION_MAX)
	if(pre_amount == post_amount)
		return
	pdata.inspirations = post_amount
	if(!silent)
		if(amount > 0)
			to_chat(src, SPAN_NOTICE("I feel INSPIRED!"))
		else
			to_chat(src, SPAN_BOLDWARNING("I loose inspiration..."))
	save_player_data_for_ckey(ckey)
