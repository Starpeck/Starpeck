/turf/closed/wall/mineral
	name = "mineral wall"
	desc = "This shouldn't exist"
	icon_state = ""
	rcd_memory = null
	var/last_event = 0
	var/active = null

/turf/closed/wall/mineral/gold
	name = "gold wall"
	desc = "A wall with gold plating. Swag!"
	explosion_block = 0 //gold is a soft metal you dingus.
	plating_material = /datum/material/gold
	color = "#dbdd4c" //To display in mapping softwares

/turf/closed/wall/mineral/silver
	name = "silver wall"
	desc = "A wall with silver plating. Shiny!"
	plating_material = /datum/material/silver
	color = "#e3f1f8" //To display in mapping softwares

/turf/closed/wall/mineral/diamond
	name = "diamond wall"
	desc = "A wall with diamond plating. You monster."
	slicing_duration = 200   //diamond wall takes twice as much time to slice
	explosion_block = 3
	plating_material = /datum/material/diamond
	color = "#71c8f7" //To display in mapping softwares

/turf/closed/wall/mineral/diamond/hulk_recoil(obj/item/bodypart/arm, mob/living/carbon/human/hulkman, damage = 41)
	return ..()

/turf/closed/wall/mineral/bananium
	name = "bananium wall"
	desc = "A wall with bananium plating. Honk!"
	plating_material = /datum/material/bananium
	color = "#ffff00" //To display in mapping softwares

/turf/closed/wall/mineral/sandstone
	name = "sandstone wall"
	desc = "A wall with sandstone plating. Rough."
	icon = 'icons/turf/walls/stone_wall.dmi'
	explosion_block = 0
	plating_material = /datum/material/sandstone
	color = "#B77D31" //To display in mapping softwares

/turf/closed/wall/mineral/uranium
	article = "a"
	name = "uranium wall"
	desc = "A wall with uranium plating. This is probably a bad idea."
	plating_material = /datum/material/uranium
	color = "#30f71a" //To display in mapping softwares

/turf/closed/wall/mineral/uranium/proc/radiate()
	if(!active)
		if(world.time > last_event+15)
			active = 1
			radiation_pulse(src, 40)
			for(var/turf/closed/wall/mineral/uranium/T in orange(1,src))
				T.radiate()
			last_event = world.time
			active = null
			return
	return

/turf/closed/wall/mineral/uranium/attack_hand(mob/user, list/modifiers)
	radiate()
	. = ..()

/turf/closed/wall/mineral/uranium/attackby(obj/item/W, mob/user, params)
	radiate()
	..()

/turf/closed/wall/mineral/uranium/Bumped(atom/movable/AM)
	radiate()
	..()

/turf/closed/wall/mineral/uranium/hulk_recoil(obj/item/bodypart/arm, mob/living/carbon/human/hulkman, damage = 41)
	return ..()

/turf/closed/wall/mineral/plasma
	name = "plasma wall"
	desc = "A wall with plasma plating. This is definitely a bad idea."
	thermal_conductivity = 0.04
	plating_material = /datum/material/plasma
	color = "#c162ec" //To display in mapping softwares

/turf/closed/wall/mineral/plasma/attackby(obj/item/W, mob/user, params)
	if(W.get_temperature() > 300)//If the temperature of the object is over 300, then ignite
		message_admins("Plasma wall ignited by [ADMIN_LOOKUPFLW(user)] in [ADMIN_VERBOSEJMP(src)]")
		log_game("Plasma wall ignited by [key_name(user)] in [AREACOORD(src)]")
		ignite(W.get_temperature())
		return
	..()

/turf/closed/wall/mineral/plasma/proc/PlasmaBurn(temperature)
	break_wall(FALSE)
	ScrapeAway()
	var/turf/open/T = src
	T.atmos_spawn_air("plasma=400;TEMP=[temperature]")

/turf/closed/wall/mineral/plasma/temperature_expose(datum/gas_mixture/air, exposed_temperature)//Doesn't work because walls have superconduction turned off
	if(exposed_temperature > 300)
		PlasmaBurn(exposed_temperature)

/turf/closed/wall/mineral/plasma/proc/ignite(exposed_temperature)
	if(exposed_temperature > 300)
		PlasmaBurn(exposed_temperature)

/turf/closed/wall/mineral/plasma/bullet_act(obj/projectile/Proj)
	if(istype(Proj, /obj/projectile/beam))
		PlasmaBurn(2500)
	else if(istype(Proj, /obj/projectile/ion))
		PlasmaBurn(500)
	. = ..()

/turf/closed/wall/mineral/wood
	name = "wooden wall"
	desc = "A wall with wooden plating. Stiff."
	icon = 'icons/turf/walls/wood_wall.dmi'
	hardness = 70
	explosion_block = 0
	plating_material = /datum/material/wood
	color = "#bb8e53" //To display in mapping softwares

/turf/closed/wall/mineral/wood/attackby(obj/item/W, mob/user)
	if(W.get_sharpness() && W.force)
		var/duration = (48/W.force) * 2 //In seconds, for now.
		if(istype(W, /obj/item/hatchet) || istype(W, /obj/item/fireaxe))
			duration /= 4 //Much better with hatchets and axes.
		if(do_after(user, duration*10, target=src)) //Into deciseconds.
			dismantle_wall(FALSE,FALSE)
			return
	return ..()

/turf/closed/wall/mineral/hulk_recoil(obj/item/bodypart/arm, mob/living/carbon/human/hulkman, damage = 0)
	return ..() //No recoil damage, wood is weak

/turf/closed/wall/mineral/wood/nonmetal
	desc = "A solidly wooden wall. It's a bit weaker than a wall made with metal."
	hardness = 50

/turf/closed/wall/mineral/iron
	name = "rough iron wall"
	desc = "A wall with rough iron plating."
	icon = 'icons/turf/walls/stone_wall.dmi'

/turf/closed/wall/mineral/snow
	name = "packed snow wall"
	desc = "A wall made of densely packed snow blocks."
	icon = 'icons/turf/walls/stone_wall.dmi'
	hardness = 80
	explosion_block = 0
	slicing_duration = 30
	bullet_sizzle = TRUE
	bullet_bounce_sound = null
	plating_material = /datum/material/snow

/turf/closed/wall/mineral/snow/hulk_recoil(obj/item/bodypart/arm, mob/living/carbon/human/hulkman, damage = 0)
	return ..() //No recoil damage, snow is weak

/turf/closed/wall/mineral/abductor
	name = "alien wall"
	desc = "A wall with alien alloy plating."
	slicing_duration = 200   //alien wall takes twice as much time to slice
	explosion_block = 3
	plating_material = /datum/material/alloy/alien
	color = "#6041aa" //To display in mapping softwares

/////////////////////Titanium walls/////////////////////

/turf/closed/wall/mineral/titanium //has to use this path due to how building walls works
	name = "wall"
	desc = "A light-weight titanium wall used in shuttles."
	icon = 'icons/turf/walls/metal_wall.dmi'
	explosion_block = 3
	flags_1 = CAN_BE_DIRTY_1
	flags_ricochet = RICOCHET_SHINY | RICOCHET_HARD
	smoothing_groups = list(SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_SHUTTERS_BLASTDOORS, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_AIRLOCK, SMOOTH_GROUP_WINDOW_FULLTILE, SMOOTH_GROUP_SHUTTLE_PARTS)
	plating_material = /datum/material/titanium
	color = "#b3c0c7" //To display in mapping softwares

/turf/closed/wall/mineral/titanium/rust_heretic_act()
	return // titanium does not rust

/turf/closed/wall/mineral/titanium/nodiagonal

/turf/closed/wall/mineral/titanium/nosmooth

/turf/closed/wall/mineral/titanium/overspace

/turf/closed/wall/mineral/titanium/interior

/turf/closed/wall/mineral/titanium/survival
	name = "pod wall"
	desc = "An easily-compressable wall used for temporary shelter."
	smoothing_groups = list(SMOOTH_GROUP_CLOSED_TURFS, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_SURVIVAL_TIANIUM_POD)
	canSmoothWith = list(SMOOTH_GROUP_SURVIVAL_TIANIUM_POD)
	color = "#242424" //To display in mapping softwares
	wall_paint = "#444444"
	stripe_paint = "#BB774D"

/turf/closed/wall/mineral/titanium/survival/nodiagonal

/turf/closed/wall/mineral/titanium/survival/pod

/////////////////////Plastitanium walls/////////////////////

/turf/closed/wall/mineral/plastitanium
	name = "wall"
	desc = "A durable wall made of an alloy of plasma and titanium."
	icon = 'icons/turf/walls/metal_wall.dmi'
	explosion_block = 4
	smoothing_groups = list(SMOOTH_GROUP_WALLS)
	canSmoothWith = list(SMOOTH_GROUP_SHUTTERS_BLASTDOORS, SMOOTH_GROUP_WALLS, SMOOTH_GROUP_AIRLOCK, SMOOTH_GROUP_WINDOW_FULLTILE, SMOOTH_GROUP_SHUTTLE_PARTS)
	plating_material = /datum/material/alloy/plastitanium
	color = "#3a313a" //To display in mapping softwares

/turf/closed/wall/mineral/plastitanium/rust_heretic_act()
	return // plastitanium does not rust

/turf/closed/wall/mineral/plastitanium/nodiagonal

/turf/closed/wall/mineral/plastitanium/nosmooth

/turf/closed/wall/mineral/plastitanium/overspace

/turf/closed/wall/mineral/plastitanium/explosive/ex_act(severity)
	var/obj/item/bombcore/large/bombcore = new(get_turf(src))
	bombcore.detonate()
	return ..()

/turf/closed/wall/mineral/plastitanium/interior
