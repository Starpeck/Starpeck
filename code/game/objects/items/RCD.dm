#define GLOW_MODE 3
#define LIGHT_MODE 2
#define REMOVE_MODE 1

/*
CONTAINS:
RCD
ARCD
RLD
*/

/obj/item/construction
	name = "not for ingame use"
	desc = "A device used to rapidly build and deconstruct. Reload with iron, plasteel, glass or compressed matter cartridges."
	opacity = FALSE
	density = FALSE
	anchored = FALSE
	flags_1 = CONDUCT_1
	item_flags = NOBLUDGEON
	force = 0
	throwforce = 10
	throw_speed = 3
	throw_range = 5
	w_class = WEIGHT_CLASS_NORMAL
	custom_materials = list(/datum/material/iron=100000)
	req_access_txt = "11"
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 100, ACID = 50)
	resistance_flags = FIRE_PROOF
	var/datum/effect_system/spark_spread/spark_system
	var/matter = 0
	var/max_matter = 100
	var/no_ammo_message = SPAN_WARNING("The \'Low Ammo\' light on the device blinks yellow.")
	var/has_ammobar = FALSE //controls whether or not does update_icon apply ammo indicator overlays
	var/ammo_sections = 10 //amount of divisions in the ammo indicator overlay/number of ammo indicator states
	/// Bitflags for upgrades
	var/upgrade = NONE
	/// Bitflags for banned upgrades
	var/banned_upgrades = NONE
	var/datum/component/remote_materials/silo_mats //remote connection to the silo
	var/silo_link = FALSE //switch to use internal or remote storage

/obj/item/construction/Initialize(mapload)
	. = ..()
	spark_system = new /datum/effect_system/spark_spread
	spark_system.set_up(5, 0, src)
	spark_system.attach(src)
	if(upgrade & RCD_UPGRADE_SILO_LINK)
		silo_mats = AddComponent(/datum/component/remote_materials, "RCD", mapload, FALSE)

/obj/item/construction/examine(mob/user)
	. = ..()
	. += "It currently holds [matter]/[max_matter] matter-units."
	if(upgrade & RCD_UPGRADE_SILO_LINK)
		. += "Remote storage link state: [silo_link ? "[silo_mats.on_hold() ? "ON HOLD" : "ON"]" : "OFF"]."
		if(silo_link && silo_mats.mat_container && !silo_mats.on_hold())
			. += "Remote connection has iron in equivalent to [silo_mats.mat_container.get_material_amount(/datum/material/iron)/500] RCD unit\s." //1 matter for 1 floor tile, as 4 tiles are produced from 1 iron

/obj/item/construction/Destroy()
	QDEL_NULL(spark_system)
	silo_mats = null
	return ..()

/obj/item/construction/pre_attack(atom/target, mob/user, params)
	if(istype(target, /obj/item/rcd_upgrade))
		install_upgrade(target, user)
		return TRUE
	if(insert_matter(target, user))
		return TRUE
	return ..()

/obj/item/construction/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/rcd_upgrade))
		install_upgrade(W, user)
		return TRUE
	if(insert_matter(W, user))
		return TRUE
	return ..()

/// Installs an upgrade into the RCD checking if it is already installed, or if it is a banned upgrade
/obj/item/construction/proc/install_upgrade(obj/item/rcd_upgrade/rcd_up, mob/user)
	if(rcd_up.upgrade & upgrade)
		to_chat(user, SPAN_WARNING("[src] has already installed this upgrade!"))
		return
	if(rcd_up.upgrade & banned_upgrades)
		to_chat(user, SPAN_WARNING("[src] can't install this upgrade!"))
		return
	upgrade |= rcd_up.upgrade
	if((rcd_up.upgrade & RCD_UPGRADE_SILO_LINK) && !silo_mats)
		silo_mats = AddComponent(/datum/component/remote_materials, "RCD", FALSE, FALSE)
	playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
	qdel(rcd_up)

/// Inserts matter into the RCD allowing it to build
/obj/item/construction/proc/insert_matter(obj/O, mob/user)
	if(iscyborg(user))
		return FALSE
	var/loaded = FALSE
	if(istype(O, /obj/item/rcd_ammo))
		var/obj/item/rcd_ammo/R = O
		var/load = min(R.ammoamt, max_matter - matter)
		if(load <= 0)
			to_chat(user, SPAN_WARNING("[src] can't hold any more matter-units!"))
			return FALSE
		R.ammoamt -= load
		if(R.ammoamt <= 0)
			qdel(R)
		matter += load
		playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
		loaded = TRUE
	else if(istype(O, /obj/item/stack))
		loaded = loadwithsheets(O, user)
	if(loaded)
		to_chat(user, SPAN_NOTICE("[src] now holds [matter]/[max_matter] matter-units."))
		update_appearance() //ensures that ammo counters (if present) get updated
	return loaded

/obj/item/construction/proc/loadwithsheets(obj/item/stack/S, mob/user)
	var/value = S.matter_amount
	if(value <= 0)
		to_chat(user, SPAN_NOTICE("You can't insert [S.name] into [src]!"))
		return FALSE
	var/maxsheets = round((max_matter-matter)/value)    //calculate the max number of sheets that will fit in RCD
	if(maxsheets > 0)
		var/amount_to_use = min(S.amount, maxsheets)
		S.use(amount_to_use)
		matter += value*amount_to_use
		playsound(src.loc, 'sound/machines/click.ogg', 50, TRUE)
		to_chat(user, SPAN_NOTICE("You insert [amount_to_use] [S.name] sheets into [src]. "))
		return TRUE
	to_chat(user, SPAN_WARNING("You can't insert any more [S.name] sheets into [src]!"))
	return FALSE

/obj/item/construction/proc/activate()
	playsound(loc, 'sound/items/deconstruct.ogg', 50, TRUE)

/obj/item/construction/attack_self(mob/user)
	playsound(loc, 'sound/effects/pop.ogg', 50, FALSE)
	if(prob(20))
		spark_system.start()

/obj/item/construction/proc/useResource(amount, mob/user)
	if(!silo_mats || !silo_link)
		if(matter < amount)
			if(user)
				to_chat(user, no_ammo_message)
			return FALSE
		matter -= amount
		update_appearance()
		return TRUE
	else
		if(silo_mats.on_hold())
			if(user)
				to_chat(user, SPAN_ALERT("Mineral access is on hold, please contact the quartermaster."))
			return FALSE
		if(!silo_mats.mat_container)
			to_chat(user, SPAN_ALERT("No silo link detected. Connect to silo via multitool."))
			return FALSE
		if(!silo_mats.mat_container.has_materials(list(/datum/material/iron = 500), amount))
			if(user)
				to_chat(user, no_ammo_message)
			return FALSE

		var/list/materials = list()
		materials[GET_MATERIAL_REF(/datum/material/iron)] = 500
		silo_mats.mat_container.use_materials(materials, amount)
		silo_mats.silo_log(src, "consume", -amount, "build", materials)
		return TRUE

/obj/item/construction/proc/checkResource(amount, mob/user)
	if(!silo_mats || !silo_mats.mat_container)
		if(silo_link)
			to_chat(user, SPAN_ALERT("Connected silo link is invalid. Reconnect to silo via multitool."))
			return FALSE
		else
			. = matter >= amount
	else
		if(silo_mats.on_hold())
			if(user)
				to_chat(user, SPAN_ALERT("Mineral access is on hold, please contact the quartermaster."))
			return FALSE
		. = silo_mats.mat_container.has_materials(list(/datum/material/iron = 500), amount)
	if(!. && user)
		to_chat(user, no_ammo_message)
		if(has_ammobar)
			flick("[icon_state]_empty", src) //somewhat hacky thing to make RCDs with ammo counters actually have a blinking yellow light
	return .

/obj/item/construction/proc/range_check(atom/A, mob/user)
	if(!(A in view(7, get_turf(user))))
		to_chat(user, SPAN_WARNING("The \'Out of Range\' light on [src] blinks red."))
		return FALSE
	else
		return TRUE

/obj/item/construction/proc/prox_check(proximity)
	if(proximity)
		return TRUE
	else
		return FALSE

/**
 * Checks if we are allowed to interact with a radial menu
 *
 * Arguments:
 * * user The living mob interacting with the menu
 * * remote_anchor The remote anchor for the menu
 */
/obj/item/construction/proc/check_menu(mob/living/user, remote_anchor)
	if(!istype(user))
		return FALSE
	if(user.incapacitated())
		return FALSE
	if(remote_anchor && user.remote_control != remote_anchor)
		return FALSE
	return TRUE

#define RCD_DESTRUCTIVE_SCAN_RANGE 10
#define RCD_HOLOGRAM_FADE_TIME (15 SECONDS)
#define RCD_DESTRUCTIVE_SCAN_COOLDOWN (RCD_HOLOGRAM_FADE_TIME + 1 SECONDS)

/obj/item/construction/rcd
	name = "rapid-construction-device (RCD)"
	icon = 'icons/obj/tools.dmi'
	icon_state = "rcd"
	worn_icon_state = "RCD"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_premium_price = PAYCHECK_HARD * 10
	max_matter = 160
	slot_flags = ITEM_SLOT_BELT
	item_flags = NO_MAT_REDEMPTION | NOBLUDGEON
	has_ammobar = TRUE
	actions_types = list(/datum/action/item_action/rcd_scan)
	var/mode = RCD_FLOORWALL
	var/construction_mode = RCD_FLOORWALL
	var/ranged = FALSE
	var/computer_dir = 1
	var/airlock_type = /obj/machinery/door/airlock
	var/airlock_glass = FALSE // So the floor's rcd_act knows how much ammo to use
	var/window_type = /obj/structure/window/fulltile
	var/window_glass = RCD_WINDOW_NORMAL
	var/window_size = RCD_WINDOW_FULLTILE
	var/furnish_type = /obj/structure/chair
	var/furnish_cost = 8
	var/furnish_delay = 10
	var/advanced_airlock_setting = 1 //Set to 1 if you want more paintjobs available
	var/delay_mod = 1
	var/canRturf = FALSE //Variable for R walls to deconstruct them
	/// Integrated airlock electronics for setting access to a newly built airlocks
	var/obj/item/electronics/airlock/airlock_electronics

	COOLDOWN_DECLARE(destructive_scan_cooldown)

GLOBAL_VAR_INIT(icon_holographic_wall, init_holographic_wall())
GLOBAL_VAR_INIT(icon_holographic_window, init_holographic_window())

// `initial` does not work here. Neither does instantiating a wall/whatever
// and referencing that. I don't know why.
/proc/init_holographic_wall()
	return getHologramIcon(
		icon('icons/turf/walls/wall.dmi', "wall-0"),
		opacity = 1,
	)

/proc/init_holographic_window()
	var/icon/grille_icon = icon('icons/obj/structures.dmi', "grille")
	var/icon/window_icon = icon('icons/obj/smooth_structures/window.dmi', "window-0")

	grille_icon.Blend(window_icon, ICON_OVERLAY)

	return getHologramIcon(grille_icon)

/obj/item/construction/rcd/ui_action_click(mob/user, actiontype)
	if (!COOLDOWN_FINISHED(src, destructive_scan_cooldown))
		to_chat(user, SPAN_WARNING("[src] lets out a low buzz."))
		return

	COOLDOWN_START(src, destructive_scan_cooldown, RCD_DESTRUCTIVE_SCAN_COOLDOWN)

	playsound(src, 'sound/items/rcdscan.ogg', 50, vary = TRUE, pressure_affected = FALSE)

	var/turf/source_turf = get_turf(src)
	for (var/turf/open/surrounding_turf in RANGE_TURFS(RCD_DESTRUCTIVE_SCAN_RANGE, source_turf))
		var/rcd_memory = surrounding_turf.rcd_memory
		if (!rcd_memory)
			continue

		var/skip_to_next_turf = FALSE

		for (var/atom/content_of_turf as anything in surrounding_turf.contents)
			if (content_of_turf.density)
				skip_to_next_turf = TRUE
				break

		if (skip_to_next_turf)
			continue

		var/hologram_icon
		switch (rcd_memory)
			if (RCD_MEMORY_WALL)
				hologram_icon = GLOB.icon_holographic_wall
			if (RCD_MEMORY_WINDOWGRILLE)
				hologram_icon = GLOB.icon_holographic_window

		var/obj/effect/rcd_hologram/hologram = new (surrounding_turf)
		hologram.icon = hologram_icon
		animate(hologram, alpha = 0, time = RCD_HOLOGRAM_FADE_TIME, easing = CIRCULAR_EASING | EASE_IN)

/obj/effect/rcd_hologram
	name = "hologram"
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT

/obj/effect/rcd_hologram/Initialize(mapload)
	. = ..()
	QDEL_IN(src, RCD_HOLOGRAM_FADE_TIME)

#undef RCD_DESTRUCTIVE_SCAN_COOLDOWN
#undef RCD_DESTRUCTIVE_SCAN_RANGE
#undef RCD_HOLOGRAM_FADE_TIME

/obj/item/construction/rcd/suicide_act(mob/living/user)
	var/turf/T = get_turf(user)

	if(!isopenturf(T)) // Oh fuck
		user.visible_message(SPAN_SUICIDE("[user] is beating [user.p_them()]self to death with [src]! It looks like [user.p_theyre()] trying to commit suicide!"))
		return BRUTELOSS

	mode = RCD_FLOORWALL
	user.visible_message(SPAN_SUICIDE("[user] sets the RCD to 'Wall' and points it down [user.p_their()] throat! It looks like [user.p_theyre()] trying to commit suicide!"))
	if(checkResource(16, user)) // It takes 16 resources to construct a wall
		var/success = T.rcd_act(user, src, RCD_FLOORWALL)
		T = get_turf(user)
		// If the RCD placed a floor instead of a wall, having a wall without plating under it is cursed
		// There isn't an easy programmatical way to check if rcd_act will place a floor or a wall, so just repeat using it for free
		if(success && isopenturf(T))
			T.rcd_act(user, src, RCD_FLOORWALL)
		useResource(16, user)
		activate()
		playsound(loc, 'sound/machines/click.ogg', 50, 1)
		user.gib()
		return MANUAL_SUICIDE

	user.visible_message(SPAN_SUICIDE("[user] pulls the trigger... But there is not enough ammo!"))
	return SHAME

/obj/item/construction/rcd/verb/toggle_window_glass_verb()
	set name = "RCD : Toggle Window Glass"
	set category = "Object"
	set src in view(1)

	if(!usr.canUseTopic(src, BE_CLOSE))
		return

	toggle_window_glass(usr)

/obj/item/construction/rcd/verb/toggle_window_size_verb()
	set name = "RCD : Toggle Window Size"
	set category = "Object"
	set src in view(1)

	if(!usr.canUseTopic(src, BE_CLOSE))
		return

	toggle_window_size(usr)

/// Toggles the usage of reinforced or normal glass
/obj/item/construction/rcd/proc/toggle_window_glass(mob/user)
	if (window_glass != RCD_WINDOW_REINFORCED)
		set_window_type(user, RCD_WINDOW_REINFORCED, window_size)
		return
	set_window_type(user, RCD_WINDOW_NORMAL, window_size)

/// Toggles the usage of directional or full tile windows
/obj/item/construction/rcd/proc/toggle_window_size(mob/user)
	if (window_size != RCD_WINDOW_DIRECTIONAL)
		set_window_type(user, window_glass, RCD_WINDOW_DIRECTIONAL)
		return
	set_window_type(user, window_glass, RCD_WINDOW_FULLTILE)

/// Sets the window type to be created based on parameters
/obj/item/construction/rcd/proc/set_window_type(mob/user, glass, size)
	window_glass = glass
	window_size = size
	if(window_glass == RCD_WINDOW_REINFORCED)
		if(window_size == RCD_WINDOW_DIRECTIONAL)
			window_type = /obj/structure/window/reinforced
		else
			window_type = /obj/structure/window/reinforced/fulltile
	else
		if(window_size == RCD_WINDOW_DIRECTIONAL)
			window_type = /obj/structure/window
		else
			window_type = /obj/structure/window/fulltile

	to_chat(user, SPAN_NOTICE("You change \the [src]'s window mode to [window_size] [window_glass] window."))

/obj/item/construction/rcd/proc/toggle_silo_link(mob/user)
	if(silo_mats)
		if(!silo_mats.mat_container && !silo_link) // Allow them to turn off an invalid link
			to_chat(user, SPAN_ALERT("No silo link detected. Connect to silo via multitool."))
			return FALSE
		silo_link = !silo_link
		to_chat(user, SPAN_NOTICE("You change \the [src]'s storage link state: [silo_link ? "ON" : "OFF"]."))
	else
		to_chat(user, SPAN_WARNING("\the [src] doesn't have remote storage connection."))

/obj/item/construction/rcd/proc/get_airlock_image(airlock_type)
	var/obj/machinery/door/airlock/proto = airlock_type
	var/ic = initial(proto.icon)
	var/mutable_appearance/MA = mutable_appearance(ic, "closed")
	if(!initial(proto.glass))
		MA.overlays += "fill_closed"
	//Not scaling these down to button size because they look horrible then, instead just bumping up radius.
	return MA

/obj/item/construction/rcd/proc/change_computer_dir(mob/user)
	if(!user)
		return
	var/list/computer_dirs = list(
		"NORTH" = image(icon = 'icons/hud/radial.dmi', icon_state = "cnorth"),
		"EAST" = image(icon = 'icons/hud/radial.dmi', icon_state = "ceast"),
		"SOUTH" = image(icon = 'icons/hud/radial.dmi', icon_state = "csouth"),
		"WEST" = image(icon = 'icons/hud/radial.dmi', icon_state = "cwest")
		)
	var/computerdirs = show_radial_menu(user, src, computer_dirs, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(computerdirs)
		if("NORTH")
			computer_dir = 1
		if("EAST")
			computer_dir = 4
		if("SOUTH")
			computer_dir = 2
		if("WEST")
			computer_dir = 8

/**
 * Customizes RCD's airlock settings based on user's choices
 *
 * Arguments:
 * * user The mob that is choosing airlock settings
 * * remote_anchor The remote anchor for radial menus. If set, it will also remove proximity restrictions from the menus
 */
/obj/item/construction/rcd/proc/change_airlock_setting(mob/user, remote_anchor)
	if(!user)
		return

	var/list/solid_or_glass_choices = list(
		"Solid" = get_airlock_image(/obj/machinery/door/airlock),
		"Glass" = get_airlock_image(/obj/machinery/door/airlock/glass),
		"Windoor" = image(icon = 'icons/hud/radial.dmi', icon_state = "windoor"),
		"Secure Windoor" = image(icon = 'icons/hud/radial.dmi', icon_state = "secure_windoor")
	)

	var/list/solid_choices = list(
		"Standard" = get_airlock_image(/obj/machinery/door/airlock),
		"Public" = get_airlock_image(/obj/machinery/door/airlock/public),
		"Engineering" = get_airlock_image(/obj/machinery/door/airlock/engineering),
		"Atmospherics" = get_airlock_image(/obj/machinery/door/airlock/atmos),
		"Security" = get_airlock_image(/obj/machinery/door/airlock/security),
		"Command" = get_airlock_image(/obj/machinery/door/airlock/command),
		"Medical" = get_airlock_image(/obj/machinery/door/airlock/medical),
		"Research" = get_airlock_image(/obj/machinery/door/airlock/research),
		"Freezer" = get_airlock_image(/obj/machinery/door/airlock/freezer),
		"Virology" = get_airlock_image(/obj/machinery/door/airlock/virology),
		"Mining" = get_airlock_image(/obj/machinery/door/airlock/mining),
		"Maintenance" = get_airlock_image(/obj/machinery/door/airlock/maintenance),
		"External" = get_airlock_image(/obj/machinery/door/airlock/external),
		"External Maintenance" = get_airlock_image(/obj/machinery/door/airlock/maintenance/external),
		"Airtight Hatch" = get_airlock_image(/obj/machinery/door/airlock/hatch),
		"Maintenance Hatch" = get_airlock_image(/obj/machinery/door/airlock/maintenance_hatch)
	)

	var/list/glass_choices = list(
		"Standard" = get_airlock_image(/obj/machinery/door/airlock/glass),
		"Public" = get_airlock_image(/obj/machinery/door/airlock/public/glass),
		"Engineering" = get_airlock_image(/obj/machinery/door/airlock/engineering/glass),
		"Atmospherics" = get_airlock_image(/obj/machinery/door/airlock/atmos/glass),
		"Security" = get_airlock_image(/obj/machinery/door/airlock/security/glass),
		"Command" = get_airlock_image(/obj/machinery/door/airlock/command/glass),
		"Medical" = get_airlock_image(/obj/machinery/door/airlock/medical/glass),
		"Research" = get_airlock_image(/obj/machinery/door/airlock/research/glass),
		"Virology" = get_airlock_image(/obj/machinery/door/airlock/virology/glass),
		"Mining" = get_airlock_image(/obj/machinery/door/airlock/mining/glass),
		"Maintenance" = get_airlock_image(/obj/machinery/door/airlock/maintenance/glass),
		"External" = get_airlock_image(/obj/machinery/door/airlock/external/glass),
		"External Maintenance" = get_airlock_image(/obj/machinery/door/airlock/maintenance/external/glass)
	)

	var/airlockcat = show_radial_menu(user, remote_anchor || src, solid_or_glass_choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user, remote_anchor), require_near = remote_anchor ? FALSE : TRUE, tooltips = TRUE)
	switch(airlockcat)
		if("Solid")
			if(advanced_airlock_setting == 1)
				var/airlockpaint = show_radial_menu(user, remote_anchor || src, solid_choices, radius = 42, custom_check = CALLBACK(src, PROC_REF(check_menu), user, remote_anchor), require_near = remote_anchor ? FALSE : TRUE, tooltips = TRUE)
				switch(airlockpaint)
					if("Standard")
						airlock_type = /obj/machinery/door/airlock
					if("Public")
						airlock_type = /obj/machinery/door/airlock/public
					if("Engineering")
						airlock_type = /obj/machinery/door/airlock/engineering
					if("Atmospherics")
						airlock_type = /obj/machinery/door/airlock/atmos
					if("Security")
						airlock_type = /obj/machinery/door/airlock/security
					if("Command")
						airlock_type = /obj/machinery/door/airlock/command
					if("Medical")
						airlock_type = /obj/machinery/door/airlock/medical
					if("Research")
						airlock_type = /obj/machinery/door/airlock/research
					if("Freezer")
						airlock_type = /obj/machinery/door/airlock/freezer
					if("Virology")
						airlock_type = /obj/machinery/door/airlock/virology
					if("Mining")
						airlock_type = /obj/machinery/door/airlock/mining
					if("Maintenance")
						airlock_type = /obj/machinery/door/airlock/maintenance
					if("External")
						airlock_type = /obj/machinery/door/airlock/external
					if("External Maintenance")
						airlock_type = /obj/machinery/door/airlock/maintenance/external
					if("Airtight Hatch")
						airlock_type = /obj/machinery/door/airlock/hatch
					if("Maintenance Hatch")
						airlock_type = /obj/machinery/door/airlock/maintenance_hatch
				airlock_glass = FALSE
			else
				airlock_type = /obj/machinery/door/airlock
				airlock_glass = FALSE

		if("Glass")
			if(advanced_airlock_setting == 1)
				var/airlockpaint = show_radial_menu(user, remote_anchor || src, glass_choices, radius = 42, custom_check = CALLBACK(src, PROC_REF(check_menu), user, remote_anchor), require_near = remote_anchor ? FALSE : TRUE, tooltips = TRUE)
				switch(airlockpaint)
					if("Standard")
						airlock_type = /obj/machinery/door/airlock/glass
					if("Public")
						airlock_type = /obj/machinery/door/airlock/public/glass
					if("Engineering")
						airlock_type = /obj/machinery/door/airlock/engineering/glass
					if("Atmospherics")
						airlock_type = /obj/machinery/door/airlock/atmos/glass
					if("Security")
						airlock_type = /obj/machinery/door/airlock/security/glass
					if("Command")
						airlock_type = /obj/machinery/door/airlock/command/glass
					if("Medical")
						airlock_type = /obj/machinery/door/airlock/medical/glass
					if("Research")
						airlock_type = /obj/machinery/door/airlock/research/glass
					if("Virology")
						airlock_type = /obj/machinery/door/airlock/virology/glass
					if("Mining")
						airlock_type = /obj/machinery/door/airlock/mining/glass
					if("Maintenance")
						airlock_type = /obj/machinery/door/airlock/maintenance/glass
					if("External")
						airlock_type = /obj/machinery/door/airlock/external/glass
					if("External Maintenance")
						airlock_type = /obj/machinery/door/airlock/maintenance/external/glass
				airlock_glass = TRUE
			else
				airlock_type = /obj/machinery/door/airlock/glass
				airlock_glass = TRUE
		if("Windoor")
			airlock_type = /obj/machinery/door/window
			airlock_glass = TRUE
		if("Secure Windoor")
			airlock_type = /obj/machinery/door/window/brigdoor
			airlock_glass = TRUE
		else
			airlock_type = /obj/machinery/door/airlock
			airlock_glass = FALSE

/// Radial menu for choosing the object you want to be created with the furnishing mode
/obj/item/construction/rcd/proc/change_furnishing_type(mob/user)
	if(!user)
		return
	var/static/list/choices = list(
		"Chair" = image(icon = 'icons/hud/radial.dmi', icon_state = "chair"),
		"Stool" = image(icon = 'icons/hud/radial.dmi', icon_state = "stool"),
		"Table" = image(icon = 'icons/hud/radial.dmi', icon_state = "table"),
		"Glass Table" = image(icon = 'icons/hud/radial.dmi', icon_state = "glass_table")
		)
	var/choice = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(choice)
		if("Chair")
			furnish_type = /obj/structure/chair
			furnish_cost = 8
			furnish_delay = 10
		if("Stool")
			furnish_type = /obj/structure/chair/stool
			furnish_cost = 8
			furnish_delay = 10
		if("Table")
			furnish_type = /obj/structure/table
			furnish_cost = 16
			furnish_delay = 20
		if("Glass Table")
			furnish_type = /obj/structure/table/glass
			furnish_cost = 16
			furnish_delay = 20

/obj/item/construction/rcd/proc/rcd_create(atom/A, mob/user)
	var/list/rcd_results = A.rcd_vals(user, src)
	if(!rcd_results)
		return FALSE
	var/delay = rcd_results["delay"] * delay_mod
	var/obj/effect/constructing_effect/rcd_effect = new(get_turf(A), delay, src.mode)
	if(!checkResource(rcd_results["cost"], user))
		qdel(rcd_effect)
		return FALSE
	if(rcd_results["mode"] == RCD_MACHINE || rcd_results["mode"] == RCD_COMPUTER || rcd_results["mode"] == RCD_FURNISHING)
		var/turf/target_turf = get_turf(A)
		if(target_turf.is_blocked_turf(exclude_mobs = TRUE))
			playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
			qdel(rcd_effect)
			return FALSE
	if(!do_after(user, delay, target = A))
		qdel(rcd_effect)
		return FALSE
	if(!checkResource(rcd_results["cost"], user))
		qdel(rcd_effect)
		return FALSE
	if(!A.rcd_act(user, src, rcd_results["mode"]))
		qdel(rcd_effect)
		return FALSE
	rcd_effect.end_animation()
	useResource(rcd_results["cost"], user)
	activate()
	playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
	return TRUE

/obj/item/construction/rcd/Initialize()
	. = ..()
	airlock_electronics = new(src)
	airlock_electronics.name = "Access Control"
	airlock_electronics.holder = src
	GLOB.rcd_list += src

/obj/item/construction/rcd/Destroy()
	QDEL_NULL(airlock_electronics)
	GLOB.rcd_list -= src
	. = ..()

/obj/item/construction/rcd/attack_self(mob/user)
	..()
	var/list/choices = list(
		"Airlock" = image(icon = 'icons/hud/radial.dmi', icon_state = "airlock"),
		"Grilles & Windows" = image(icon = 'icons/hud/radial.dmi', icon_state = "grillewindow"),
		"Floors & Walls" = image(icon = 'icons/hud/radial.dmi', icon_state = "wallfloor")
	)
	if(upgrade & RCD_UPGRADE_FRAMES)
		choices += list(
		"Machine Frames" = image(icon = 'icons/hud/radial.dmi', icon_state = "machine"),
		"Computer Frames" = image(icon = 'icons/hud/radial.dmi', icon_state = "computer_dir"),
		)
	if(upgrade & RCD_UPGRADE_SILO_LINK)
		choices += list(
		"Silo Link" = image(icon = 'icons/obj/mining.dmi', icon_state = "silo"),
		)
	if(upgrade & RCD_UPGRADE_FURNISHING)
		choices += list(
		"Furnishing" = image(icon = 'icons/hud/radial.dmi', icon_state = "chair")
		)
	switch(construction_mode)
		if(RCD_AIRLOCK)
			choices += list(
			"Change Access" = image(icon = 'icons/hud/radial.dmi', icon_state = "access"),
			"Change Airlock Type" = image(icon = 'icons/hud/radial.dmi', icon_state = "airlocktype")
			)
		if(RCD_WINDOWGRILLE)
			choices += list(
			"Change Window Glass" = image(icon = 'icons/hud/radial.dmi', icon_state = "windowtype"),
			"Change Window Size" = image(icon = 'icons/hud/radial.dmi', icon_state = "windowsize")
			)
		if(RCD_FURNISHING)
			choices += list(
			"Change Furnishing Type" = image(icon = 'icons/hud/radial.dmi', icon_state = "chair")
			)
	var/choice = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return
	switch(choice)
		if("Floors & Walls")
			construction_mode = RCD_FLOORWALL
		if("Airlock")
			construction_mode = RCD_AIRLOCK
		if("Grilles & Windows")
			construction_mode = RCD_WINDOWGRILLE
		if("Machine Frames")
			construction_mode = RCD_MACHINE
		if("Furnishing")
			construction_mode = RCD_FURNISHING
		if("Computer Frames")
			construction_mode = RCD_COMPUTER
			change_computer_dir(user)
			return
		if("Change Access")
			airlock_electronics.ui_interact(user)
			return
		if("Change Airlock Type")
			change_airlock_setting(user)
			return
		if("Change Window Glass")
			toggle_window_glass(user)
			return
		if("Change Window Size")
			toggle_window_size(user)
			return
		if("Change Furnishing Type")
			change_furnishing_type(user)
			return
		if("Silo Link")
			toggle_silo_link(user)
			return
		else
			return
	playsound(src, 'sound/effects/pop.ogg', 50, FALSE)
	to_chat(user, SPAN_NOTICE("You change RCD's mode to '[choice]'."))

/obj/item/construction/rcd/proc/target_check(atom/A, mob/user) // only returns true for stuff the device can actually work with
	if((isturf(A) && A.density && mode==RCD_DECONSTRUCT) || (isturf(A) && !A.density) || (istype(A, /obj/machinery/door/airlock) && mode==RCD_DECONSTRUCT) || istype(A, /obj/structure/grille) || (istype(A, /obj/structure/window) && mode==RCD_DECONSTRUCT) || istype(A, /obj/structure/girder))
		return TRUE
	else
		return FALSE

/obj/item/construction/rcd/pre_attack(atom/A, mob/user, params)
	. = ..()
	mode = construction_mode
	rcd_create(A, user)
	return FALSE

/obj/item/construction/rcd/pre_attack_secondary(atom/target, mob/living/user, params)
	. = ..()
	mode = RCD_DECONSTRUCT
	rcd_create(target, user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN


/obj/item/construction/rcd/proc/detonate_pulse()
	audible_message("<span class='danger'><b>[src] begins to vibrate and \
		buzz loudly!</b></span>","<span class='danger'><b>[src] begins \
		vibrating violently!</b></span>")
	// 5 seconds to get rid of it
	addtimer(CALLBACK(src, PROC_REF(detonate_pulse_explode)), 50)

/obj/item/construction/rcd/proc/detonate_pulse_explode()
	explosion(src, light_impact_range = 3, flame_range = 1, flash_range = 1)
	qdel(src)

/obj/item/construction/rcd/update_overlays()
	. = ..()
	if(has_ammobar)
		var/ratio = CEILING((matter / max_matter) * ammo_sections, 1)
		if(ratio > 0)
			. += "[icon_state]_charge[ratio]"

/obj/item/construction/rcd/Initialize()
	. = ..()
	update_appearance()

/obj/item/construction/rcd/borg
	no_ammo_message = SPAN_WARNING("Insufficient charge.")
	desc = "A device used to rapidly build walls and floors."
	canRturf = TRUE
	banned_upgrades = RCD_UPGRADE_SILO_LINK
	var/energyfactor = 72


/obj/item/construction/rcd/borg/useResource(amount, mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		if(user)
			to_chat(user, no_ammo_message)
		return 0
	. = borgy.cell.use(amount * energyfactor) //borgs get 1.3x the use of their RCDs
	if(!. && user)
		to_chat(user, no_ammo_message)
	return .

/obj/item/construction/rcd/borg/checkResource(amount, mob/user)
	if(!iscyborg(user))
		return 0
	var/mob/living/silicon/robot/borgy = user
	if(!borgy.cell)
		if(user)
			to_chat(user, no_ammo_message)
		return 0
	. = borgy.cell.charge >= (amount * energyfactor)
	if(!. && user)
		to_chat(user, no_ammo_message)
	return .

/obj/item/construction/rcd/borg/syndicate
	icon_state = "ircd"
	inhand_icon_state = "ircd"
	energyfactor = 66

/obj/item/construction/rcd/loaded
	matter = 160

/obj/item/construction/rcd/loaded/upgraded
	upgrade = RCD_UPGRADE_FRAMES | RCD_UPGRADE_SIMPLE_CIRCUITS | RCD_UPGRADE_FURNISHING

/obj/item/construction/rcd/combat
	name = "industrial RCD"
	icon_state = "ircd"
	inhand_icon_state = "ircd"
	max_matter = 500
	matter = 500
	canRturf = TRUE
	upgrade = RCD_UPGRADE_FRAMES | RCD_UPGRADE_SIMPLE_CIRCUITS | RCD_UPGRADE_FURNISHING

/obj/item/rcd_ammo
	name = "compressed matter cartridge"
	desc = "Highly compressed matter for the RCD."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rcdammo"
	w_class = WEIGHT_CLASS_TINY
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	custom_materials = list(/datum/material/iron=12000, /datum/material/glass=8000)
	var/ammoamt = 40

/obj/item/rcd_ammo/large
	custom_materials = list(/datum/material/iron=48000, /datum/material/glass=32000)
	ammoamt = 160


/obj/item/construction/rcd/combat/admin
	name = "admin RCD"
	max_matter = INFINITY
	matter = INFINITY
	upgrade = RCD_UPGRADE_FRAMES | RCD_UPGRADE_SIMPLE_CIRCUITS | RCD_UPGRADE_FURNISHING


// Ranged RCD


/obj/item/construction/rcd/arcd
	name = "advanced rapid-construction-device (ARCD)"
	desc = "A prototype RCD with ranged capability and extended capacity. Reload with iron, plasteel, glass or compressed matter cartridges."
	max_matter = 300
	matter = 300
	delay_mod = 0.6
	ranged = TRUE
	icon_state = "arcd"
	inhand_icon_state = "oldrcd"
	has_ammobar = FALSE

/obj/item/construction/rcd/arcd/afterattack(atom/A, mob/user)
	. = ..()
	if(range_check(A,user))
		pre_attack(A, user)

/obj/item/construction/rcd/arcd/afterattack_secondary(atom/target, mob/user, proximity_flag, click_parameters)
	if(range_check(target,user))
		pre_attack_secondary(target, user)
	return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN


/obj/item/construction/rcd/arcd/rcd_create(atom/A, mob/user)
	. = ..()
	if(.)
		user.Beam(A,icon_state="rped_upgrade", time = 3 SECONDS)



// RAPID LIGHTING DEVICE



/obj/item/construction/rld
	name = "Rapid Lighting Device (RLD)"
	desc = "A device used to rapidly provide lighting sources to an area. Reload with iron, plasteel, glass or compressed matter cartridges."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rld-5"
	worn_icon_state = "RPD"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	matter = 200
	max_matter = 200
	var/matter_divisor = 35
	var/mode = LIGHT_MODE
	slot_flags = ITEM_SLOT_BELT
	actions_types = list(/datum/action/item_action/pick_color)

	var/wallcost = 10
	var/floorcost = 15
	var/launchcost = 5
	var/deconcost = 10

	var/walldelay = 10
	var/floordelay = 10
	var/decondelay = 15

	var/color_choice = null


/obj/item/construction/rld/ui_action_click(mob/user, datum/action/A)
	if(istype(A, /datum/action/item_action/pick_color))
		color_choice = input(user,"","Choose Color",color_choice) as color
	else
		..()

/obj/item/construction/rld/update_icon_state()
	icon_state = "rld-[round(matter/matter_divisor)]"
	return ..()

/obj/item/construction/rld/attack_self(mob/user)
	..()
	switch(mode)
		if(REMOVE_MODE)
			mode = LIGHT_MODE
			to_chat(user, SPAN_NOTICE("You change RLD's mode to 'Permanent Light Construction'."))
		if(LIGHT_MODE)
			mode = GLOW_MODE
			to_chat(user, SPAN_NOTICE("You change RLD's mode to 'Light Launcher'."))
		if(GLOW_MODE)
			mode = REMOVE_MODE
			to_chat(user, SPAN_NOTICE("You change RLD's mode to 'Deconstruct'."))


/obj/item/construction/rld/proc/checkdupes(target)
	. = list()
	var/turf/checking = get_turf(target)
	for(var/obj/machinery/light/dupe in checking)
		if(istype(dupe, /obj/machinery/light))
			. |= dupe


/obj/item/construction/rld/afterattack(atom/A, mob/user)
	. = ..()
	if(!range_check(A,user))
		return
	var/turf/start = get_turf(src)
	switch(mode)
		if(REMOVE_MODE)
			if(istype(A, /obj/machinery/light/))
				if(checkResource(deconcost, user))
					to_chat(user, SPAN_NOTICE("You start deconstructing [A]..."))
					user.Beam(A,icon_state="light_beam", time = 15)
					playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
					if(do_after(user, decondelay, target = A))
						if(!useResource(deconcost, user))
							return FALSE
						activate()
						qdel(A)
						return TRUE
				return FALSE
		if(LIGHT_MODE)
			if(iswallturf(A))
				var/turf/closed/wall/W = A
				if(checkResource(floorcost, user))
					to_chat(user, SPAN_NOTICE("You start building a wall light..."))
					user.Beam(A,icon_state="light_beam", time = 15)
					playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
					playsound(loc, 'sound/effects/light_flicker.ogg', 50, FALSE)
					if(do_after(user, floordelay, target = A))
						if(!istype(W))
							return FALSE
						var/list/candidates = list()
						var/turf/open/winner = null
						var/winning_dist = null
						for(var/direction in GLOB.cardinals)
							var/turf/C = get_step(W, direction)
							var/list/dupes = checkdupes(C)
							if((isspaceturf(C) || TURF_SHARES(C)) && !dupes.len)
								candidates += C
						if(!candidates.len)
							to_chat(user, SPAN_WARNING("Valid target not found..."))
							playsound(src.loc, 'sound/misc/compiler-failure.ogg', 30, TRUE)
							return FALSE
						for(var/turf/open/O in candidates)
							if(istype(O))
								var/x0 = O.x
								var/y0 = O.y
								var/contender = cheap_hypotenuse(start.x, start.y, x0, y0)
								if(!winner)
									winner = O
									winning_dist = contender
								else
									if(contender < winning_dist) // lower is better
										winner = O
										winning_dist = contender
						activate()
						if(!useResource(wallcost, user))
							return FALSE
						var/light = get_turf(winner)
						var/align = get_dir(winner, A)
						var/obj/machinery/light/L = new /obj/machinery/light(light)
						L.setDir(align)
						L.color = color_choice
						L.set_light_color(L.color)
						return TRUE
				return FALSE

			if(isfloorturf(A))
				var/turf/open/floor/F = A
				if(checkResource(floorcost, user))
					to_chat(user, SPAN_NOTICE("You start building a floor light..."))
					user.Beam(A,icon_state="light_beam", time = 15)
					playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
					playsound(loc, 'sound/effects/light_flicker.ogg', 50, TRUE)
					if(do_after(user, floordelay, target = A))
						if(!istype(F))
							return FALSE
						if(!useResource(floorcost, user))
							return FALSE
						activate()
						var/destination = get_turf(A)
						var/obj/machinery/light/floor/FL = new /obj/machinery/light/floor(destination)
						FL.color = color_choice
						FL.set_light_color(FL.color)
						return TRUE
				return FALSE

		if(GLOW_MODE)
			if(useResource(launchcost, user))
				activate()
				to_chat(user, SPAN_NOTICE("You fire a glowstick!"))
				var/obj/item/flashlight/glowstick/G  = new /obj/item/flashlight/glowstick(start)
				G.color = color_choice
				G.set_light_color(G.color)
				G.throw_at(A, 9, 3, user)
				G.on = TRUE
				G.update_brightness()
				return TRUE
			return FALSE

/obj/item/construction/rld/mini
	name = "mini-rapid-light-device (MRLD)"
	desc = "A device used to rapidly provide lighting sources to an area. Reload with iron, plasteel, glass or compressed matter cartridges."
	icon = 'icons/obj/tools.dmi'
	icon_state = "rld-5"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	matter = 100
	max_matter = 100
	matter_divisor = 20

///The plumbing RCD. All the blueprints are located in _globalvars > lists > construction.dm
/obj/item/construction/plumbing
	name = "Plumbing Constructor"
	desc = "An expertly modified RCD outfitted to construct plumbing machinery."
	icon_state = "plumberer2"
	inhand_icon_state = "plumberer"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	worn_icon_state = "plumbing"
	icon = 'icons/obj/tools.dmi'
	slot_flags = ITEM_SLOT_BELT

	matter = 200
	max_matter = 200

	///type of the plumbing machine
	var/blueprint = null
	///index, used in the attack self to get the type. stored here since it doesnt change
	var/list/choices = list()
	///index, used in the attack self to get the type. stored here since it doesnt change
	var/list/name_to_type = list()
	///All info for construction
	var/list/machinery_data = list("cost" = list())
	///This list that holds all the plumbing design types the plumberer can construct. Its purpose is to make it easy to make new plumberer subtypes with a different selection of machines.
	var/list/plumbing_design_types
	///Current selected layer
	var/current_layer = "Default Layer"
	///Current selected color, for ducts
	var/current_color = "omni"

/obj/item/construction/plumbing/Initialize(mapload)
	. = ..()
	set_plumbing_designs()

/obj/item/construction/plumbing/examine(mob/user)
	. = ..()
	. += SPAN_NOTICE("Alt-Click to change layer and duct color.")

/obj/item/construction/plumbing/equipped(mob/user, slot, initial)
	. = ..()
	if(slot == ITEM_SLOT_HANDS)
		RegisterSignal(user, COMSIG_MOUSE_SCROLL_ON, PROC_REF(mouse_wheeled))
	else
		UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)

/obj/item/construction/plumbing/dropped(mob/user, silent)
	UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)
	return ..()

/obj/item/construction/plumbing/cyborg_unequip(mob/user)
	UnregisterSignal(user, COMSIG_MOUSE_SCROLL_ON)
	return ..()

/obj/item/construction/plumbing/attack_self(mob/user)
	..()
	if(!choices.len)
		for(var/obj/machinery/plumbing/plumbing_type as anything in plumbing_design_types)
			choices += list(initial(plumbing_type.name) = image(initial(plumbing_type.icon), icon_state = initial(plumbing_type.icon_state)))
			name_to_type[initial(plumbing_type.name)] = plumbing_type
			machinery_data["cost"][plumbing_type] = plumbing_design_types[plumbing_type]

	// Update duct icon
	var/image/duct_image = choices["fluid duct"]
	duct_image.color = current_color

	var/choice = show_radial_menu(user, src, choices, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!choice || !check_menu(user))
		return

	blueprint = name_to_type[choice]
	playsound(src, 'sound/effects/pop.ogg', 50, FALSE)
	to_chat(user, SPAN_NOTICE("You change [name]s blueprint to '[choice]'."))

/**
 * Set the list of designs this plumbing rcd can make
 */
/obj/item/construction/plumbing/proc/set_plumbing_designs()
	plumbing_design_types = list(
	// Note that the list MUST include fluid ducts.
	/obj/machinery/duct = 1,
	/obj/machinery/plumbing/input = 5,
	/obj/machinery/plumbing/output = 5,
	/obj/machinery/plumbing/tank = 20,
	/obj/machinery/plumbing/synthesizer = 15,
	/obj/machinery/plumbing/reaction_chamber = 15,
	/obj/machinery/plumbing/buffer = 10,
	//Above are the most common machinery which is shown on the first cycle. Keep new additions below THIS line, unless they're probably gonna be needed alot
	/obj/machinery/plumbing/layer_manifold = 5,
	/obj/machinery/plumbing/pill_press = 20,
	/obj/machinery/plumbing/acclimator = 10,
	/obj/machinery/plumbing/bottler = 50,
	/obj/machinery/plumbing/disposer = 10,
	/obj/machinery/plumbing/fermenter = 30,
	/obj/machinery/plumbing/filter = 5,
	/obj/machinery/plumbing/grinder_chemical = 30,
	/obj/machinery/plumbing/liquid_pump = 35,
	/obj/machinery/plumbing/splitter = 5,
	/obj/machinery/plumbing/sender = 20,
	/obj/machinery/iv_drip/plumbing = 20
)

///pretty much rcd_create, but named differently to make myself feel less bad for copypasting from a sibling-type
/obj/item/construction/plumbing/proc/create_machine(atom/destination, mob/user)
	if(!machinery_data || !isopenturf(destination))
		return FALSE

	if(!canPlace(destination))
		var/obj/blueprint_type = blueprint
		to_chat(user, SPAN_NOTICE("There is something blocking you from placing a [initial(blueprint_type.name)] there."))
		return
	if(checkResource(machinery_data["cost"][blueprint], user) && blueprint)
		//"cost" is relative to delay at a rate of 10 matter/second  (1matter/decisecond) rather than playing with 2 different variables since everyone set it to this rate anyways.
		if(do_after(user, machinery_data["cost"][blueprint], target = destination))
			if(checkResource(machinery_data["cost"][blueprint], user) && canPlace(destination))
				useResource(machinery_data["cost"][blueprint], user)
				activate()
				playsound(loc, 'sound/machines/click.ogg', 50, TRUE)
				if(ispath(blueprint, /obj/machinery/duct))
					var/is_omni = current_color == DUCT_COLOR_OMNI
					new blueprint(destination, FALSE, GLOB.pipe_paint_colors[current_color], GLOB.plumbing_layers[current_layer], null, is_omni)
				else
					new blueprint(destination, FALSE, GLOB.plumbing_layers[current_layer])
				return TRUE

/obj/item/construction/plumbing/proc/canPlace(turf/destination)
	if(!isopenturf(destination))
		return FALSE
	. = TRUE

	var/obj/blueprint_template = blueprint
	var/layer_id = GLOB.plumbing_layers[current_layer]

	for(var/obj/content_obj in destination.contents)
		// Let's not built ontop of dense stuff, if this is also dense.
		if(initial(blueprint_template.density) && content_obj.density)
			return FALSE

		// Ducts can overlap other plumbing objects IF the layers are different

		// make sure plumbling isn't overlapping.
		for(var/datum/component/plumbing/plumber as anything in content_obj.GetComponents(/datum/component/plumbing))
			if(plumber.ducting_layer & layer_id)
				return FALSE

		if(istype(content_obj, /obj/machinery/duct))
			// Make sure ducts aren't overlapping.
			var/obj/machinery/duct/duct_machine = content_obj
			if(duct_machine.duct_layer & layer_id)
				return FALSE

/obj/item/construction/plumbing/afterattack(atom/target, mob/user, proximity)
	. = ..()
	if(!prox_check(proximity))
		return
	if(istype(target, /obj/machinery/plumbing))
		var/obj/machinery/machine_target = target
		if(machine_target.anchored)
			to_chat(user, SPAN_WARNING("The [target.name] needs to be unanchored!"))
			return
		if(do_after(user, 20, target = target))
			machine_target.deconstruct() //Let's not substract matter
			playsound(get_turf(src), 'sound/machines/click.ogg', 50, TRUE) //this is just such a great sound effect
	else
		create_machine(target, user)

/obj/item/construction/plumbing/AltClick(mob/user)
	// give a menu to pick layers or colors
	var/list/options_menu = list(
		"Current Layer" = image('icons/hud/radial.dmi', icon_state = "plumbing_layer[GLOB.plumbing_layers[current_layer]]"),
		"Current Color" = image('icons/hud/radial.dmi', icon_state = current_color),
	)

	playsound(loc, 'sound/effects/pop.ogg', 50, FALSE)
	var/choice = show_radial_menu(user, src, options_menu, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user))
		return

	switch(choice)
		if("Current Layer")
			choose_layer_menu(user)
		if("Current Color")
			choose_color_menu(user)

/**
 * Choose the current layer via radial menu.
 *
 * Arguments:
 * * user - current user.
 */
/obj/item/construction/plumbing/proc/choose_layer_menu(mob/user)
	if(!GLOB.plumbing_layer_menu_options.len)
		for(var/layer_name in GLOB.plumbing_layers)
			GLOB.plumbing_layer_menu_options += list((layer_name) = image('icons/hud/radial.dmi', icon_state = "plumbing_layer[GLOB.plumbing_layers[layer_name]]"))

	playsound(loc, 'sound/effects/pop.ogg', 50, FALSE)
	var/new_layer = show_radial_menu(user, src, GLOB.plumbing_layer_menu_options, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!new_layer || !check_menu(user))
		return

	current_layer = new_layer
	to_chat(user, SPAN_NOTICE("You set the layer to [new_layer]."))

/**
 * Choose the current color via radial menu.
 *
 * Arguments:
 * * user - current user.
 */
/obj/item/construction/plumbing/proc/choose_color_menu(mob/user)
	if(!GLOB.plumbing_color_menu_options.len)
		for(var/color_name in GLOB.pipe_paint_colors)
			GLOB.plumbing_color_menu_options += list((color_name) = image('icons/hud/radial.dmi', icon_state = color_name))

	playsound(loc, 'sound/effects/pop.ogg', 50, FALSE)
	var/new_color = show_radial_menu(user, src, GLOB.plumbing_color_menu_options, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!new_color || !check_menu(user))
		return

	current_color = new_color
	to_chat(user, SPAN_NOTICE("You set the color to [new_color]."))

/**
 * Choose layer via mouse wheel, like an RPD
 *
 * Arguments:
 * * source - the user
 * * A - the atom being selected, unused.
 * * delta_x - X scroll delta
 * * delta_y - Y scroll delta
 */
/obj/item/construction/plumbing/proc/mouse_wheeled(mob/source, atom/A, delta_x, delta_y, params)
	SIGNAL_HANDLER
	if(source.incapacitated(ignore_restraints = TRUE, ignore_stasis = TRUE))
		return
	if(delta_y == 0)
		return

	if(delta_y < 0)
		var/current_loc = GLOB.plumbing_layers.Find(current_layer) + 1
		if(current_loc > GLOB.plumbing_layers.len)
			current_loc = 1
		current_layer = GLOB.plumbing_layers[current_loc]
	else
		var/current_loc = GLOB.plumbing_layers.Find(current_layer) - 1
		if(current_loc < 1)
			current_loc = GLOB.plumbing_layers.len
		current_layer = GLOB.plumbing_layers[current_loc]
	to_chat(source, SPAN_NOTICE("You set the layer to [current_layer]."))

/obj/item/construction/plumbing/research
	name = "research plumbing constructor"
	desc = "A type of plumbing constructor designed to rapidly deploy the machines needed to conduct cytological research."
	icon_state = "plumberer_sci"
	inhand_icon_state = "plumberer_sci"
	lefthand_file = 'icons/mob/inhands/equipment/tools_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/equipment/tools_righthand.dmi'
	has_ammobar = TRUE

/obj/item/construction/plumbing/research/set_plumbing_designs()
	plumbing_design_types = list(
		/obj/machinery/duct = 1,
		/obj/machinery/plumbing/input = 5,
		/obj/machinery/plumbing/output = 5,
		/obj/machinery/plumbing/tank = 20,
		/obj/machinery/plumbing/acclimator = 10,
		/obj/machinery/plumbing/filter = 5,
		/obj/machinery/plumbing/reaction_chamber = 15,
		/obj/machinery/plumbing/grinder_chemical = 30,
		/obj/machinery/plumbing/splitter = 5,
		/obj/machinery/plumbing/disposer = 10,
		/obj/machinery/plumbing/growing_vat = 20
	)


/obj/item/rcd_upgrade
	name = "RCD advanced design disk"
	desc = "It seems to be empty."
	icon = 'icons/obj/module.dmi'
	icon_state = "datadisk3"
	var/upgrade

/obj/item/rcd_upgrade/frames
	desc = "It contains the design for machine frames and computer frames."
	upgrade = RCD_UPGRADE_FRAMES

/obj/item/rcd_upgrade/simple_circuits
	desc = "It contains the design for firelock, air alarm, fire alarm, apc circuits and crap power cells."
	upgrade = RCD_UPGRADE_SIMPLE_CIRCUITS

/obj/item/rcd_upgrade/silo_link
	desc = "It contains direct silo connection RCD upgrade."
	upgrade = RCD_UPGRADE_SILO_LINK
/obj/item/rcd_upgrade/furnishing
	desc = "It contains the design for chairs, stools, tables, and glass tables."
	upgrade = RCD_UPGRADE_FURNISHING

/datum/action/item_action/rcd_scan
	name = "Destruction Scan"
	desc = "Scans the surrounding area for destruction. Scanned structures will rebuild significantly faster."

#undef GLOW_MODE
#undef LIGHT_MODE
#undef REMOVE_MODE
