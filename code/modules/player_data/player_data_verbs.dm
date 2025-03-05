/client/proc/evaluation_panel()
	set name = "Evaluation Panel"
	set category = "Admin"
	if(!check_rights(R_BAN))
		return
	if(IsAdminAdvancedProcCall())
		return
	holder.evaluation_panel.show_ui(usr)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Evaluation Panel") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/player_data_whitelist()
	set name = "Whitelist CKEY"
	set category = "Admin"
	var/mob/user = usr
	if(!check_rights(R_BAN))
		return
	if(IsAdminAdvancedProcCall())
		return
	var/input_ckey = input(user,"Input CKEY to whitelist","Whitelist CKEY") as text|null
	if(!input_ckey)
		return
	var/passed_ckey = ckey(input_ckey)

	add_ckey_whitelist_pd(passed_ckey, user.ckey)

	message_admins("[key_name_admin(user)] whitelisted [passed_ckey]")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Player Data Whitelist") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/proc/add_ckey_whitelist_pd(target_ckey, admin_ckey = "SYSTEM")
	if(IsAdminAdvancedProcCall())
		return
	if(!target_ckey)
		return
	target_ckey = ckey(target_ckey)
	var/datum/player_data/pdata = get_player_data_for_ckey(target_ckey)
	pdata.whitelisted = TRUE
	save_player_data_for_ckey(target_ckey)

/proc/ckey_whitelist_check_pd(ckey)
	ckey = ckey(ckey)
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	return pdata.whitelisted
