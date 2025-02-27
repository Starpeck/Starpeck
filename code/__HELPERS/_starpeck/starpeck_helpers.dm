
/proc/set_lightswitch_in_atom_room(atom/thing, target_state)
	var/area/area = get_area(thing)
	if(!area)
		return
	area.set_lights(target_state)
