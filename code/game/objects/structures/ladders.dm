// Basic ladder. By default links to the z-level above/below.
/obj/structure/ladder
	name = "ladder"
	desc = "A sturdy metal ladder."
	icon = 'icons/obj/structures.dmi'
	icon_state = "ladder11"
	anchored = TRUE
	obj_flags = CAN_BE_HIT | BLOCK_Z_OUT_DOWN
	var/obj/structure/ladder/down   //the ladder below this one
	var/obj/structure/ladder/up     //the ladder above this one
	var/crafted = FALSE
	/// Optional travel time for ladder in deciseconds
	var/travel_time = 1.5 SECONDS
	var/static/list/climbsounds = list('sound/effects/ladder.ogg','sound/effects/ladder2.ogg','sound/effects/ladder3.ogg','sound/effects/ladder4.ogg')

/obj/structure/ladder/Initialize(mapload, obj/structure/ladder/up, obj/structure/ladder/down)
	..()
	if (up)
		src.up = up
		up.down = src
		up.update_appearance()
	if (down)
		src.down = down
		down.up = src
		down.update_appearance()
	return INITIALIZE_HINT_LATELOAD

/obj/structure/ladder/Destroy(force)
	if ((resistance_flags & INDESTRUCTIBLE) && !force)
		return QDEL_HINT_LETMELIVE
	disconnect()
	return ..()

/obj/structure/ladder/LateInitialize()
	// By default, discover ladders above and below us vertically
	var/turf/T = get_turf(src)
	var/obj/structure/ladder/L

	if (!down)
		L = locate() in T.below()
		if (L)
			if(crafted == L.crafted)
				down = L
				L.up = src  // Don't waste effort looping the other way
				L.update_appearance()
	if (!up)
		L = locate() in T.above()
		if (L)
			if(crafted == L.crafted)
				up = L
				L.down = src  // Don't waste effort looping the other way
				L.update_appearance()

	update_appearance()

/obj/structure/ladder/proc/disconnect()
	if(up && up.down == src)
		up.down = null
		up.update_appearance()
	if(down && down.up == src)
		down.up = null
		down.update_appearance()
	up = down = null

/obj/structure/ladder/update_icon_state()
	icon_state = "ladder[up ? 1 : 0][down ? 1 : 0]"
	return ..()

/obj/structure/ladder/singularity_pull()
	if (!(resistance_flags & INDESTRUCTIBLE))
		visible_message(SPAN_DANGER("[src] is torn to pieces by the gravitational pull!"))
		qdel(src)

/obj/structure/ladder/proc/travel(going_up, mob/user, is_ghost, obj/structure/ladder/ladder)
	if(!is_ghost)
		var/mob/living/living_user = user
		if(user.loc != loc) //If not at the ladder location, attempt to move in
			var/can_move = user.Move(get_turf(src), get_dir(user,src))
			if(!can_move)
				to_chat(user, SPAN_WARNING("You can't step in!"))
				return
		if(!(living_user.mobility_flags & MOBILITY_USE))
			to_chat(user, SPAN_WARNING("You can't reach out!"))
			return
		var/direction = going_up ? "up" : "down"
		user.visible_message(SPAN_NOTICE("[user] begins to climb [direction] [src]."), SPAN_NOTICE("You begin to climb [direction] [src]."))
		ladder.audible_message(SPAN_NOTICE("You hear something coming [direction] \the [src]."))
		ladder.add_fingerprint(user)
		playsound(src, pick(climbsounds), 50) //Here
		playsound(ladder, pick(climbsounds), 50) //And at the destination
		if(!do_after(user, travel_time, target = src))
			return
		show_fluff_message(going_up, user)


	var/turf/T = get_turf(ladder)
	var/atom/movable/AM
	if(user.pulling)
		AM = user.pulling
		AM.forceMove(T)
	user.forceMove(T)
	if(AM)
		user.start_pulling(AM)

/obj/structure/ladder/proc/use(mob/user, is_ghost=FALSE)
	if (!is_ghost && !in_range(src, user))
		return

	var/list/tool_list = list()
	if (up)
		tool_list["Up"] = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = NORTH)
	if (down)
		tool_list["Down"] = image(icon = 'icons/testing/turf_analysis.dmi', icon_state = "red_arrow", dir = SOUTH)
	if (!length(tool_list))
		to_chat(user, SPAN_WARNING("[src] doesn't seem to lead anywhere!"))
		return

	var/result = show_radial_menu(user, src, tool_list, custom_check = CALLBACK(src, PROC_REF(check_menu), user, is_ghost), require_near = !is_ghost, tooltips = TRUE)
	if (!is_ghost && !in_range(src, user))
		return  // nice try
	switch(result)
		if("Up")
			travel(TRUE, user, is_ghost, up)
		if("Down")
			travel(FALSE, user, is_ghost, down)
		if("Cancel")
			return

	if(!is_ghost)
		add_fingerprint(user)

/obj/structure/ladder/proc/check_menu(mob/user, is_ghost)
	if(user.incapacitated() || (!user.Adjacent(src) && !is_ghost))
		return FALSE
	return TRUE

/obj/structure/ladder/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	use(user)

/obj/structure/ladder/attack_paw(mob/user, list/modifiers)
	return use(user)

/obj/structure/ladder/attack_alien(mob/user, list/modifiers)
	return use(user)

/obj/structure/ladder/attack_larva(mob/user)
	return use(user)

/obj/structure/ladder/attack_animal(mob/user)
	return use(user)

/obj/structure/ladder/attack_slime(mob/user)
	return use(user)

/obj/structure/ladder/attackby(obj/item/W, mob/user, params)
	return use(user)

/obj/structure/ladder/attack_robot(mob/living/silicon/robot/R)
	if(R.Adjacent(src))
		return use(R)

//ATTACK GHOST IGNORING PARENT RETURN VALUE
/obj/structure/ladder/attack_ghost(mob/dead/observer/user)
	use(user, TRUE)
	return ..()

/obj/structure/ladder/proc/show_fluff_message(going_up, mob/user)
	if(going_up)
		user.visible_message(SPAN_NOTICE("[user] climbs up [src]."), SPAN_NOTICE("You climb up [src]."))
	else
		user.visible_message(SPAN_NOTICE("[user] climbs down [src]."), SPAN_NOTICE("You climb down [src]."))


// Indestructible away mission ladders which link based on a mapped ID and height value rather than X/Y/Z.
/obj/structure/ladder/unbreakable
	name = "sturdy ladder"
	desc = "An extremely sturdy metal ladder."
	resistance_flags = INDESTRUCTIBLE
	var/id
	var/height = 0  // higher numbers are considered physically higher

/obj/structure/ladder/unbreakable/Initialize()
	GLOB.ladders += src
	return ..()

/obj/structure/ladder/unbreakable/Destroy()
	. = ..()
	if (. != QDEL_HINT_LETMELIVE)
		GLOB.ladders -= src

/obj/structure/ladder/unbreakable/LateInitialize()
	// Override the parent to find ladders based on being height-linked
	if (!id || (up && down))
		update_appearance()
		return

	for (var/O in GLOB.ladders)
		var/obj/structure/ladder/unbreakable/L = O
		if (L.id != id)
			continue  // not one of our pals
		if (!down && L.height == height - 1)
			down = L
			L.up = src
			L.update_appearance()
			if (up)
				break  // break if both our connections are filled
		else if (!up && L.height == height + 1)
			up = L
			L.down = src
			L.update_appearance()
			if (down)
				break  // break if both our connections are filled

	update_appearance()

/obj/structure/ladder/crafted
	crafted = TRUE
