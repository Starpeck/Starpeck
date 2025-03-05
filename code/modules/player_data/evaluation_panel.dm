/datum/admins
	var/datum/evaluation_panel/evaluation_panel
	var/datum/player_data_panel/player_data_panel

/datum/evaluation_panel
	var/datum/admins/holder

/datum/evaluation_panel/New(datum/admins/passed_holder)
	holder = passed_holder
	return ..()

/datum/evaluation_panel/Topic(href, list/href_list)
	. = ..()
	if(!holder)
		return
	var/mob/user = usr
	if(holder.owner != user.client)
		return
	if(!check_rights_for(user.client, R_BAN))
		to_chat(user, SPAN_BOLDWARNING("No +BAN permission"))
		return
	switch(href_list["task"])
		if("ckey_input")
			var/chosen_ckey = input(user, "Choose ckey", "CKEY", "") as text|null
			if(!chosen_ckey)
				return
			chosen_ckey = ckey(chosen_ckey)
			holder.player_data_panel.show_ckey_ui(user, chosen_ckey)
			return
		if("open_pin")
			var/chosen_ckey = href_list["ckey"]
			if(!chosen_ckey)
				return
			chosen_ckey = ckey(chosen_ckey)
			holder.player_data_panel.show_ckey_ui(user, chosen_ckey)
			message_admins("[key_name_admin(user)] opened evaluation for ckey [chosen_ckey]")
			return
		if("clear_pin")
			var/chosen_ckey = href_list["ckey"]
			if(!chosen_ckey)
				return
			chosen_ckey = ckey(chosen_ckey)
			var/alert = alert(user, "Remove the pin for ckey: [chosen_ckey]?", "REMOVE PIN", "Yes", "No")
			if(alert != "Yes")
				return
			remove_evaluation_pin(chosen_ckey)
			message_admins("[key_name_admin(user)] removed evaluation pin for ckey [chosen_ckey]")
	show_ui(user)

/datum/evaluation_panel/proc/show_ui(mob/user)
	var/list/dat = list()
	dat += "<a href='?src=[REF(src)];task=refresh'>Refresh</a>"
	dat += "<br><b>Show ckey player data:</b> <a href='?src=[REF(src)];task=ckey_input'>Input</a>"
	dat += "<HR>"
	var/datum/server_data/sdata = get_server_data()
	for(var/datum/evaluation_pin/pin as anything in sdata.evaluation_pins)
		dat += "<b>[pin.ckey]</b> - [pin.label] <a href='?src=[REF(src)];task=clear_pin;ckey=[pin.ckey]'>Remove</a> <a href='?src=[REF(src)];task=open_pin;ckey=[pin.ckey]'>Show</a><br>"
	var/datum/browser/popup = new(user, "evaluation_panel", "Evaluation Panel", 550, 500)
	popup.set_content(dat.Join())
	popup.open()
