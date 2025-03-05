/datum/player_data_panel
	var/datum/admins/holder
	var/selected_ckey
	var/chosen_note_category = NOTE_TYPE_NOTE

/datum/player_data_panel/New(datum/admins/passed_holder)
	holder = passed_holder
	return ..()

/datum/player_data_panel/Topic(href, list/href_list)
	. = ..()
	if(!holder)
		return
	var/mob/user = usr
	if(holder.owner != user.client)
		return
	if(!check_rights_for(user.client, R_BAN))
		to_chat(user, SPAN_BOLDWARNING("No +BAN permission"))
		return
	if(!selected_ckey)
		return
	var/datum/player_data/pdata = get_player_data_for_ckey(selected_ckey)
	if(!pdata)
		return
	switch(href_list["task"])
		if("change_tier")
			var/old_tier = pdata.tier
			old_tier = trunc(clamp(old_tier, PLAYER_TIER_MIN, PLAYER_TIER_MAX))
			var/old_tier_text = LAZYACCESS(GLOB.tiers_list, old_tier)  // for preselecting the existing rank
			var/new_tier_text = input(user, "What is [selected_ckey]'s new rank?", "Adjust Player Tier", old_tier_text) as null|anything in GLOB.tiers_list
			if(!new_tier_text || (new_tier_text == old_tier_text))
				to_chat(user, SPAN_WARNING("Tier unchanged. Key [selected_ckey] remains at rank [old_tier]: [player_tier_to_label(old_tier)]."))
				return
			var/new_tier = GLOB.tiers_list[new_tier_text]
			to_chat(user, SPAN_BOLDANNOUNCE("Remember to mirror this change on the Discord."))
			message_admins("[key_name_admin(user)] changed player tier for ckey [selected_ckey] from [player_tier_to_label(old_tier)] to [player_tier_to_label(new_tier)]")
			log_admin("[key_name_admin(user)] changed player tier for ckey [selected_ckey] from [player_tier_to_label(old_tier)] to [player_tier_to_label(new_tier)]")
			pdata.set_tier(new_tier)
		if("change_discord_id")
			var/new_id = input(user, "Set associated discord ID for [selected_ckey]", "Set Discord ID") as text|null
			if(!new_id)
				return
			message_admins("[key_name_admin(user)] set player discord ID for ckey [selected_ckey] to [new_id]")
			log_admin("[key_name_admin(user)] set player discord ID for ckey [selected_ckey] to [new_id]")
			pdata.set_discord_id(new_id)
		if("toggle_id_verification")
			var/old_id_status = pdata.age_id_verified
			var/confirm = alert("Set [selected_ckey]'s age verification status to [old_id_status ? "UNVERIFIED" : "AGE VERIFIED"]?", "Toggle Age - ID Verification", "Yes", "No")
			if(confirm == "Yes")
				var/new_id_status = (old_id_status ? FALSE : TRUE)
				pdata.set_id_verification(new_id_status)
				message_admins("[key_name_admin(user)] set player ID age-verification status for ckey [selected_ckey] to [new_id_status ? "AGE VERIFIED" : "UNVERIFIED"]")
				log_admin("[key_name_admin(user)] set player ID age-verification status for ckey [selected_ckey] to [new_id_status ? "AGE VERIFIED" : "UNVERIFIED"]")
		if("add_to_whitelist")
			var/confirm = alert("Add this ckey to the bunker whitelist?", "Add to Whitelist", "Yes", "No")
			if(confirm == "Yes")
				add_ckey_whitelist_pd(selected_ckey, user.ckey)
		if("remove_pin")
			var/alert = alert(user, "Remove the pin for ckey: [selected_ckey]?", "REMOVE PIN", "Yes", "No")
			if(alert != "Yes")
				return
			remove_evaluation_pin(selected_ckey)
			message_admins("[key_name_admin(user)] removed evaluation pin for ckey [selected_ckey]")
		if("add_note")
			var/chosen_label = input(user, "Input label", "Label", "") as text|null
			if(!chosen_label)
				return
			var/chosen_reason = input(user, "Input reason", "Reason", "") as message|null
			if(!chosen_reason)
				return
			var/treated_label = "\n[chosen_label]\n - [user.ckey]"
			pdata.add_note(treated_label, treated_label, chosen_reason, NOTE_TYPE_NOTE)
			message_admins("[key_name_admin(user)] Applied a note for ckey: [selected_ckey] \n[chosen_label] - [chosen_reason]")
		if("choose_note_cat")
			var/note_cat = href_list["note_cat"]
			chosen_note_category = note_cat
		if("change_donator_status")
			if(pdata.active_donator)
				var/alert = alert(user, "Remove donator status for ckey: [selected_ckey]?\n(Don't lower their tier)", "DONATOR", "Yes", "No")
				if(alert != "Yes")
					return
				pdata.set_active_donator_status(FALSE)
				message_admins("[key_name_admin(user)] removed donator status for [selected_ckey]")
			else
				var/alert = alert(user, "Activate donator status for ckey: [selected_ckey]?", "DONATOR", "Yes", "No")
				if(alert != "Yes")
					return
				pdata.set_active_donator_status(TRUE)
				message_admins("[key_name_admin(user)] activated donator status for [selected_ckey]")
		if("change_donator_tier")
			var/list/translation_list = list()
			for(var/i in 0 to 3)
				translation_list[donator_tier_to_label(i)] = i
			var/old_name_tier = donator_tier_to_label(pdata.donator_tier)
			var/selected_name_tier = input(user, "What is [selected_ckey]'s new donator tier?", "Adjust Donator Tier", old_name_tier) as null|anything in translation_list
			if(!selected_name_tier)
				return
			var/selected_tier = translation_list[selected_name_tier]
			pdata.set_donator_tier(selected_tier)
			message_admins("[key_name_admin(user)] set new donator tier for [selected_ckey] to [donator_tier_to_label(selected_tier)]")

	show_ui(user)


/datum/player_data_panel/proc/show_ui(mob/user)
	if(!selected_ckey)
		return
	var/datum/player_data/pdata = get_player_data_for_ckey(selected_ckey)
	if(!pdata)
		return
	var/whitelist_check = ckey_whitelist_check(selected_ckey)
	var/list/dat = list()
	dat += "<center><b>[selected_ckey]</b> (Playtime: [round(pdata.playtime / (1 HOURS))] hrs, 0 rounds)</center>"
	dat += "<br><b>Tier:</b><u><a href='?src=[REF(src)];task=change_tier'>[player_tier_to_label(pdata.tier)]</a></u>"
	dat += "<br><b>Discord User ID:</b> <a href='?src=[REF(src)];task=change_discord_id'>[length(pdata.discord_id) ? pdata.discord_id : "<u>NOT SET</u>"]</a>"
	dat += "<br><b>ID Age-Verification:</b> <u><a href='?src=[REF(src)];task=toggle_id_verification'>[pdata.age_id_verified ? "AGE VERIFIED" : "Unverified"]</a></u>"
	dat += "<br><b>Donator:</b> <a href='?src=[REF(src)];task=change_donator_status'>[pdata.active_donator ? "ACTIVE" : "INACTIVE"]</a> | Tier: <a a href='?src=[REF(src)];task=change_donator_tier'>[donator_tier_to_label(pdata.donator_tier)]</a>"
	dat += "<br><b>[whitelist_check ? "Whitelisted" : "<a href='?src=[REF(src)];task=add_to_whitelist'><u>Player is not whitelisted</u></a>"]</b>"
	if(has_evaluation_pin(selected_ckey))
		dat += " - <a href='?src=[REF(src)];task=remove_pin'>Remove Evaluation Pin</a>"
	dat += "<br><br><b>Notes:</b> <u><a href='?src=[REF(src)];task=add_note'>Add Note</a></u>"
	dat += "<HR>"
	var/static/list/all_note_types = NOTE_TYPES
	for(var/note_type in all_note_types)
		var/list/notes = pdata.get_all_notes_of_type(note_type)
		var/link = ""
		if(note_type == chosen_note_category)
			link = "linkOn"
		dat += "<a class='[link]' href='?src=[REF(src)];task=choose_note_cat;note_cat=[note_type]'>[note_type] ([length(notes)])</a>"
	dat += "<HR>"
	var/list/notes = pdata.get_all_notes_of_type(chosen_note_category)
	for(var/datum/player_note/instance as anything in notes)
		dat += "<b>[instance.label]</b> - [instance.round_id] [time2text(instance.apply_date, "DD.MM.YYYY")] (p. [round(instance.playtime_during_apply / (1 HOURS))] hr)"
		dat += "<br>[instance.content]"
		dat += "<HR>"
	var/datum/browser/popup = new(user, "player_data_panel", "Player Data Panel", 750, 800)
	popup.set_content(dat.Join())
	popup.open()

/datum/player_data_panel/proc/show_ckey_ui(mob/user, chosen_ckey)
	selected_ckey = chosen_ckey
	show_ui(user)
