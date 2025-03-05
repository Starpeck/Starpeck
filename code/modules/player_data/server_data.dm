/datum/server_data
	var/list/evaluation_pins = list()

/datum/server_data/proc/save_to_json_list()
	var/list/json = list()
	json["evaluation_pins"] = list()
	var/list/pin_list = json["evaluation_pins"]
	for(var/datum/evaluation_pin/instance as anything in evaluation_pins)
		pin_list.len++
		pin_list[pin_list.len] = instance.save_to_json_list()
	return json

/datum/server_data/proc/load_from_json_list(list/json)
	evaluation_pins = list()
	for(var/list/list as anything in json["evaluation_pins"])
		var/datum/evaluation_pin/instance = new /datum/evaluation_pin()
		instance.load_from_json_list(list)
		evaluation_pins += instance

/datum/evaluation_pin
	var/ckey
	var/label

/datum/evaluation_pin/proc/save_to_json_list()
	var/list/json = list()
	json["ckey"] = ckey
	json["label"] = label
	return json

/datum/evaluation_pin/proc/load_from_json_list(list/json)
	ckey = json["ckey"]
	label = json["label"]

/proc/get_server_data()
	if(IsAdminAdvancedProcCall())
		return
	if(!GLOB.server_data)
		load_server_data()
	return GLOB.server_data

/proc/load_server_data()
	if(IsAdminAdvancedProcCall())
		return
	if(GLOB.server_data)
		return
	var/target_file = file("data/server_data.json")
	var/datum/server_data/sdata = new /datum/server_data()
	if(fexists(target_file))
		sdata.load_from_json_list(json_decode(file2text(target_file)))
	GLOB.server_data = sdata

/proc/save_server_data()
	if(IsAdminAdvancedProcCall())
		return
	if(!GLOB.server_data)
		load_server_data()
	var/target_file = file("data/server_data.json")
	if(fexists(target_file))
		fdel(target_file)
	var/datum/server_data/sdata = GLOB.server_data
	WRITE_FILE(target_file, json_encode(sdata.save_to_json_list()))

/proc/has_evaluation_pin(ckey)
	var/datum/server_data/sdata = get_server_data()
	for(var/datum/evaluation_pin/instance as anything in sdata.evaluation_pins)
		if(instance.ckey != ckey)
			continue
		return TRUE
	return FALSE

/proc/remove_evaluation_pin(ckey)
	var/datum/server_data/sdata = get_server_data()
	for(var/datum/evaluation_pin/instance as anything in sdata.evaluation_pins)
		if(instance.ckey != ckey)
			continue
		sdata.evaluation_pins -= instance
		save_server_data()
		break
	var/datum/player_data/pdata = get_player_data_for_ckey(ckey)
	if(pdata)
		pdata.after_unpin()

/proc/add_evaluation_pin(ckey, label)
	var/datum/server_data/sdata = get_server_data()
	var/datum/evaluation_pin/pin
	for(var/datum/evaluation_pin/instance as anything in sdata.evaluation_pins)
		if(instance.ckey != ckey)
			continue
		pin = instance
		break
	if(!pin)
		pin = new /datum/evaluation_pin()
		pin.ckey = ckey
		sdata.evaluation_pins += pin
	pin.label = label
	save_server_data()

/datum/admins/proc/pins_notice()
	var/datum/server_data/sdata = get_server_data()
	var/pin_len = length(sdata.evaluation_pins)
	if(pin_len > 0)
		to_chat(owner, SPAN_ADMINNOTICE("<b>NOTICE: There are [pin_len] evaluation pins.</b>"))
