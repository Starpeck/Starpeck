
/proc/set_lightswitch_in_atom_room(atom/thing, target_state)
	var/area/area = get_area(thing)
	if(!area)
		return
	area.set_lights(target_state)

/atom/proc/do_jiggle(targetangle = 25, timer = 20)
	var/matrix/OM = matrix(transform)
	var/matrix/M = matrix(transform)
	M.Turn(pick(-targetangle, targetangle))
	animate(src, transform = M, time = timer * 0.1, easing = BACK_EASING | EASE_IN)
	animate(transform = OM, time = timer * 0.4, easing = ELASTIC_EASING)

/atom/proc/do_squish(squishx = 1.2, squishy = 0.6, timer = 20)
	var/matrix/OM = matrix(transform)
	var/matrix/M = matrix(transform)
	M.Scale(squishx, squishy)
	animate(src, transform = M, time = timer * 0.5, easing = ELASTIC_EASING)
	animate(transform = OM, time = timer * 0.5, easing = BOUNCE_EASING, flags = ANIMATION_PARALLEL)


/proc/GenerateLandingPads(datum/map_zone/mapzone)
	var/datum/virtual_level/vlevel = mapzone.virtual_levels[1]
	for(var/path in SSmapping.landing_pad_templates)
		var/start_x = 0
		var/start_y = 0
		var/datum/map_template/ruin/landing_pad/pad = SSmapping.landing_pad_templates[path]
		var/half_height = CEILING((pad.height / 2), 1)
		var/half_width = CEILING((pad.width / 2), 1)
		switch(pad.spawn_position)
			if(LANDING_PAD_NE)
				start_x = vlevel.high_x - vlevel.reserved_margin - half_width
				start_y = vlevel.high_y - vlevel.reserved_margin - half_height
			if(LANDING_PAD_NW)
				start_x = vlevel.low_x + vlevel.reserved_margin + half_width
				start_y = vlevel.high_y - vlevel.reserved_margin - half_height
			if(LANDING_PAD_SE)
				start_x = vlevel.high_x - vlevel.reserved_margin - half_width
				start_y = vlevel.low_y + vlevel.reserved_margin + half_height
			if(LANDING_PAD_SW)
				start_x = vlevel.low_x + vlevel.reserved_margin + half_width
				start_y = vlevel.low_y + vlevel.reserved_margin + half_height
		pad.try_to_place(vlevel, list(), locate(start_x, start_y, vlevel.z_value), TRUE)

/proc/loop_map_zones(list/map_zones)
	var/list/vlevels = list()
	for(var/datum/map_zone/zone as anything in map_zones)
		if(length(zone.virtual_levels))
			vlevels += zone.virtual_levels[1]
	loop_vlevels(vlevels)

/proc/loop_vlevels(list/vlevel_list)
	if(!length(vlevel_list))
		return
	var/horizontal_layout = FALSE
	if(prob(50))
		horizontal_layout = TRUE

	vlevel_list = shuffle(vlevel_list)

	var/i = 0
	for(var/datum/virtual_level/vlevel as anything in vlevel_list)
		i++

		var/next_index = i + 1
		if(next_index > length(vlevel_list))
			next_index = 1
		var/prev_index = i - 1
		if(prev_index <= 0)
			prev_index = length(vlevel_list)

		var/datum/virtual_level/next = vlevel_list[next_index]
		var/datum/virtual_level/prev = vlevel_list[prev_index]

		if(horizontal_layout)
			vlevel.link_with(NORTH, vlevel)

			vlevel.link_with(WEST, next)
			vlevel.link_with(EAST, prev)
		else
			vlevel.link_with(WEST, vlevel)

			vlevel.link_with(NORTH, next)
			vlevel.link_with(SOUTH, prev)

