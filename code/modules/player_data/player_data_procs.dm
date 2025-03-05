/proc/ckey_whitelist_check(ckey)
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	if(!pdata)
		return FALSE
	/// Players with already 1 hour playtime get to bypass bunker
	if(pdata.playtime >= (1 HOURS))
		return TRUE
	if(pdata.whitelisted)
		return TRUE
	if(ckey_whitelist_check_pd(ckey))
		pdata.whitelisted = TRUE
		save_player_data_for_ckey(ckey)
		return TRUE
	return FALSE

/datum/controller/subsystem/blackbox/proc/update_player_data_exp(mins)
	for(var/client/L as anything in GLOB.clients)
		if(L.is_afk())
			continue
		if(!isliving(L.mob))
			continue
		L.player_data_update_exp(mins)

/client/proc/player_data_update_exp(mins)
	if(IsAdminAdvancedProcCall())
		return
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	pdata.playtime += mins * (1 MINUTES)
	save_player_data_for_ckey(ckey)
