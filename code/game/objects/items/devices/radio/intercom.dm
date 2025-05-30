/obj/item/radio/intercom
	name = "station intercom"
	desc = "Talk through this."
	icon_state = "intercom"
	anchored = TRUE
	w_class = WEIGHT_CLASS_BULKY
	canhear_range = 2
	dog_fashion = null
	unscrewed = FALSE
	var/wallframe_type = /obj/item/wallframe/intercom

/obj/item/radio/intercom/unscrewed
	unscrewed = TRUE

/obj/item/radio/intercom/Initialize(mapload, ndir, building)
	. = ..()
	if(building)
		setDir(ndir)
	var/area/current_area = get_area(src)
	if(!current_area)
		return
	RegisterSignal(current_area, COMSIG_AREA_POWER_CHANGE, PROC_REF(AreaPowerCheck))

/obj/item/radio/intercom/examine(mob/user)
	. = ..()
	. += SPAN_NOTICE("Use [MODE_TOKEN_INTERCOM] when nearby to speak into it.")
	if(!unscrewed)
		. += SPAN_NOTICE("It's <b>screwed</b> and secured to the wall.")
	else
		. += SPAN_NOTICE("It's <i>unscrewed</i> from the wall, and can be <b>detached</b>.")

/obj/item/radio/intercom/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_SCREWDRIVER)
		if(unscrewed)
			user.visible_message(SPAN_NOTICE("[user] starts tightening [src]'s screws..."), SPAN_NOTICE("You start screwing in [src]..."))
			if(I.use_tool(src, user, 30, volume=50))
				user.visible_message(SPAN_NOTICE("[user] tightens [src]'s screws!"), SPAN_NOTICE("You tighten [src]'s screws."))
				unscrewed = FALSE
		else
			user.visible_message(SPAN_NOTICE("[user] starts loosening [src]'s screws..."), SPAN_NOTICE("You start unscrewing [src]..."))
			if(I.use_tool(src, user, 40, volume=50))
				user.visible_message(SPAN_NOTICE("[user] loosens [src]'s screws!"), SPAN_NOTICE("You unscrew [src], loosening it from the wall."))
				unscrewed = TRUE
		return
	else if(I.tool_behaviour == TOOL_WRENCH)
		if(!unscrewed)
			to_chat(user, SPAN_WARNING("You need to unscrew [src] from the wall first!"))
			return
		user.visible_message(SPAN_NOTICE("[user] starts unsecuring [src]..."), SPAN_NOTICE("You start unsecuring [src]..."))
		I.play_tool_sound(src)
		if(I.use_tool(src, user, 80))
			user.visible_message(SPAN_NOTICE("[user] unsecures [src]!"), SPAN_NOTICE("You detach [src] from the wall."))
			playsound(src, 'sound/items/deconstruct.ogg', 50, TRUE)
			new wallframe_type(get_turf(src))
			qdel(src)
		return
	return ..()

/**
 * Override attack_tk_grab instead of attack_tk because we actually want attack_tk's
 * functionality. What we DON'T want is attack_tk_grab attempting to pick up the
 * intercom as if it was an ordinary item.
 */
/obj/item/radio/intercom/attack_tk_grab(mob/user)
	interact(user)
	return COMPONENT_CANCEL_ATTACK_CHAIN


/obj/item/radio/intercom/attack_ai(mob/user)
	interact(user)

/obj/item/radio/intercom/attack_hand(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	interact(user)

/obj/item/radio/intercom/ui_state(mob/user)
	return GLOB.default_state

/obj/item/radio/intercom/can_receive(freq, map_zones)
	if(!on)
		return FALSE
	if(wires.is_cut(WIRE_RX))
		return FALSE
	if(!(0 in map_zones))
		var/turf/position = get_turf(src)
		var/datum/map_zone/mapzone = position.get_map_zone()
		if(!position || !(mapzone in map_zones))
			return FALSE
	if(!listening)
		return FALSE
	if(freq == FREQ_SYNDICATE)
		if(!(syndie))
			return FALSE//Prevents broadcast of messages over devices lacking the encryption

	return TRUE


/obj/item/radio/intercom/Hear(message, atom/movable/speaker, message_langs, raw_message, radio_freq, list/spans, list/message_mods = list())
	if(message_mods[RADIO_EXTENSION] == MODE_INTERCOM)
		return  // Avoid hearing the same thing twice
	return ..()

/obj/item/radio/intercom/emp_act(severity)
	. = ..() // Parent call here will set `on` to FALSE.
	update_appearance()

/obj/item/radio/intercom/end_emp_effect(curremp)
	. = ..()
	AreaPowerCheck() // Make sure the area/local APC is powered first before we actually turn back on.

/obj/item/radio/intercom/update_icon_state()
	icon_state = on ? initial(icon_state) : "intercom-p"
	return ..()

/**
 * Proc called whenever the intercom's area loses or gains power. Responsible for setting the `on` variable and calling `update_icon()`.
 *
 * Normally called after the intercom's area recieves the `COMSIG_AREA_POWER_CHANGE` signal, but it can also be called directly.
 * Arguments:
 * * source - the area that just had a power change.
 */
/obj/item/radio/intercom/proc/AreaPowerCheck(datum/source)
	SIGNAL_HANDLER
	var/area/current_area = get_area(src)
	if(!current_area)
		on = FALSE
	else
		on = current_area.powered(AREA_USAGE_EQUIP) // set "on" to the equipment power status of our area.
	update_appearance()

/obj/item/radio/intercom/add_blood_DNA(list/blood_dna)
	return FALSE

//Created through the autolathe or through deconstructing intercoms. Can be applied to wall to make a new intercom on it!
/obj/item/wallframe/intercom
	name = "intercom frame"
	desc = "A ready-to-go intercom. Just slap it on a wall and screw it in!"
	icon_state = "intercom"
	result_path = /obj/item/radio/intercom/unscrewed
	pixel_shift = 29
	inverse = TRUE
	custom_materials = list(/datum/material/iron = 75, /datum/material/glass = 25)

/obj/item/radio/intercom/chapel
	name = "Confessional intercom"
	anonymize = TRUE
	frequency = 1481
	broadcasting = TRUE

/obj/item/radio/intercom/directional/north
	pixel_y = 22

/obj/item/radio/intercom/directional/south
	pixel_y = -28

/obj/item/radio/intercom/directional/east
	pixel_x = 28

/obj/item/radio/intercom/directional/west
	pixel_x = -28

/obj/item/radio/intercom/wideband
	name = "wideband relay"
	desc = "A low-gain reciever capable of sending and recieving wideband subspace messages."
	icon_state = "intercom-wideband"
	canhear_range = 3
	keyslot = new /obj/item/encryptionkey/wideband
	independent = TRUE
	freqlock = TRUE
	wallframe_type = /obj/item/wallframe/intercom/wideband

/obj/item/radio/intercom/wideband/unscrewed
	unscrewed = TRUE

/obj/item/radio/intercom/wideband/Initialize(mapload, ndir, building)
	. = ..()
	set_frequency(FREQ_WIDEBAND)

/obj/item/radio/intercom/wideband/recalculateChannels()
	. = ..()
	independent = TRUE

/obj/item/wallframe/intercom/wideband
	name = "wideband relay frame"
	desc = "A detached wideband relay. Attach to a wall and screw it in to use."
	result_path = /obj/item/radio/intercom/wideband/unscrewed

/obj/item/radio/intercom/wideband/directional/north
	pixel_y = 22

/obj/item/radio/intercom/wideband/directional/south
	pixel_y = -28

/obj/item/radio/intercom/wideband/directional/east
	pixel_x = 28

/obj/item/radio/intercom/wideband/directional/west
	pixel_x = -28
