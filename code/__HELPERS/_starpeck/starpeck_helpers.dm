
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
