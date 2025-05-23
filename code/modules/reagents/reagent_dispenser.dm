/obj/structure/reagent_dispensers
	name = "Dispenser"
	desc = "..."
	icon = 'icons/obj/chemical_tanks.dmi'
	icon_state = "water"
	density = TRUE
	anchored = FALSE
	pressure_resistance = 2*ONE_ATMOSPHERE
	max_integrity = 300
	///In units, how much the dispenser can hold
	var/tank_volume = 1000
	/// If defined, this will be the starting volume, otherwise it'll be full tank volume
	var/starting_volume = null
	///The ID of the reagent that the dispenser uses
	var/reagent_id = /datum/reagent/water
	///Can you turn this into a plumbing tank?
	var/can_be_tanked = TRUE
	///Is this source self-replenishing?
	var/refilling = FALSE

/obj/structure/reagent_dispensers/examine(mob/user)
	. = ..()
	if(can_be_tanked)
		. += SPAN_NOTICE("Use a sheet of iron to convert this into a plumbing-compatible tank.")

/obj/structure/reagent_dispensers/take_damage(damage_amount, damage_type = BRUTE, damage_flag = 0, sound_effect = 1, attack_dir)
	. = ..()
	if(. && obj_integrity > 0)
		if(tank_volume && (damage_flag == BULLET || damage_flag == LASER))
			boom()

/obj/structure/reagent_dispensers/attackby(obj/item/W, mob/user, params)
	if(W.is_refillable())
		return FALSE //so we can refill them via their afterattack.
	if(istype(W, /obj/item/stack/sheet/iron) && can_be_tanked)
		var/obj/item/stack/sheet/iron/metal_stack = W
		metal_stack.use(1)
		var/obj/structure/reagent_dispensers/plumbed/storage/new_tank = new /obj/structure/reagent_dispensers/plumbed/storage(drop_location())
		new_tank.reagents.maximum_volume = reagents.maximum_volume
		reagents.trans_to(new_tank, reagents.total_volume)
		new_tank.name = "stationary [name]"
		new_tank.update_appearance(UPDATE_OVERLAYS)
		new_tank.set_anchored(anchored)
		qdel(src)
		return FALSE
	else
		return ..()

/obj/structure/reagent_dispensers/Initialize()
	create_reagents(tank_volume, DRAINABLE | AMOUNT_VISIBLE)
	if(reagent_id)
		var/start_vol = tank_volume
		if(!isnull(starting_volume))
			start_vol = starting_volume
		reagents.add_reagent(reagent_id, start_vol)
	. = ..()

/obj/structure/reagent_dispensers/proc/boom()
	visible_message(SPAN_DANGER("\The [src] ruptures!"))
	chem_splash(loc, 5, list(reagents))
	qdel(src)

/obj/structure/reagent_dispensers/deconstruct(disassembled = TRUE)
	if(!(flags_1 & NODECONSTRUCT_1))
		if(!disassembled)
			boom()
	else
		qdel(src)

/obj/structure/reagent_dispensers/watertank
	name = "water tank"
	desc = "A water tank."
	icon_state = "water"

/obj/structure/reagent_dispensers/watertank/high
	name = "high-capacity water tank"
	desc = "A highly pressurized water tank made to hold gargantuan amounts of water."
	icon_state = "water_high" //I was gonna clean my room...
	tank_volume = 100000

/obj/structure/reagent_dispensers/foamtank
	name = "firefighting foam tank"
	desc = "A tank full of firefighting foam."
	icon_state = "foam"
	reagent_id = /datum/reagent/firefighting_foam
	tank_volume = 500

/obj/structure/reagent_dispensers/fueltank
	name = "fuel tank"
	desc = "A tank full of industrial welding fuel. Do not consume."
	icon_state = "fuel"
	reagent_id = /datum/reagent/fuel

/obj/structure/reagent_dispensers/fueltank/boom()
	explosion(src, heavy_impact_range = 1, light_impact_range = 5, flame_range = 5)
	qdel(src)

/obj/structure/reagent_dispensers/fueltank/blob_act(obj/structure/blob/B)
	boom()

/obj/structure/reagent_dispensers/fueltank/ex_act()
	boom()

/obj/structure/reagent_dispensers/fueltank/fire_act(exposed_temperature, exposed_volume)
	boom()

/obj/structure/reagent_dispensers/fueltank/zap_act(power, zap_flags)
	. = ..() //extend the zap
	if(ZAP_OBJ_DAMAGE & zap_flags)
		boom()

/obj/structure/reagent_dispensers/fueltank/bullet_act(obj/projectile/P)
	. = ..()
	if(!QDELETED(src)) //wasn't deleted by the projectile's effects.
		if(!P.nodamage && ((P.damage_type == BURN) || (P.damage_type == BRUTE)))
			log_bomber(P.firer, "detonated a", src, "via projectile")
			boom()

/obj/structure/reagent_dispensers/fueltank/attackby(obj/item/I, mob/living/user, params)
	if(I.tool_behaviour == TOOL_WELDER)
		if(!reagents.has_reagent(/datum/reagent/fuel))
			to_chat(user, SPAN_WARNING("[src] is out of fuel!"))
			return
		var/obj/item/weldingtool/W = I
		if(istype(W) && !W.welding)
			if(W.reagents.has_reagent(/datum/reagent/fuel, W.max_fuel))
				to_chat(user, SPAN_WARNING("Your [W.name] is already full!"))
				return
			reagents.trans_to(W, W.max_fuel, transfered_by = user)
			user.visible_message(SPAN_NOTICE("[user] refills [user.p_their()] [W.name]."), SPAN_NOTICE("You refill [W]."))
			playsound(src, 'sound/effects/refill.ogg', 50, TRUE)
			W.update_appearance()
		else
			user.visible_message(SPAN_DANGER("[user] catastrophically fails at refilling [user.p_their()] [I.name]!"), SPAN_USERDANGER("That was stupid of you."))
			log_bomber(user, "detonated a", src, "via welding tool")
			boom()
		return
	return ..()

/obj/structure/reagent_dispensers/fueltank/large
	name = "high capacity fuel tank"
	desc = "A tank full of a high quantity of welding fuel. Keep away from open flames."
	icon_state = "fuel_high"
	tank_volume = 5000

/obj/structure/reagent_dispensers/fueltank/large/boom()
	explosion(src, devastation_range = 1, heavy_impact_range = 2, light_impact_range = 7, flame_range = 12)
	qdel(src)

/obj/structure/reagent_dispensers/peppertank
	name = "pepper spray refiller"
	desc = "Contains condensed capsaicin for use in law \"enforcement.\""
	icon_state = "pepper"
	anchored = TRUE
	density = FALSE
	reagent_id = /datum/reagent/consumable/condensedcapsaicin

/obj/structure/reagent_dispensers/peppertank/directional/north
	dir = SOUTH
	pixel_y = 30

/obj/structure/reagent_dispensers/peppertank/directional/south
	dir = NORTH
	pixel_y = -30

/obj/structure/reagent_dispensers/peppertank/directional/east
	dir = WEST
	pixel_x = 30

/obj/structure/reagent_dispensers/peppertank/directional/west
	dir = EAST
	pixel_x = -30

/obj/structure/reagent_dispensers/peppertank/Initialize()
	. = ..()
	if(prob(1))
		desc = "IT'S PEPPER TIME, BITCH!"

/obj/structure/reagent_dispensers/water_cooler
	name = "liquid cooler"
	desc = "A machine that dispenses liquid to drink."
	icon = 'icons/obj/vending.dmi'
	icon_state = "water_cooler"
	anchored = TRUE
	tank_volume = 500
	var/paper_cups = 25 //Paper cups left from the cooler

/obj/structure/reagent_dispensers/water_cooler/examine(mob/user)
	. = ..()
	if (paper_cups > 1)
		. += "There are [paper_cups] paper cups left."
	else if (paper_cups == 1)
		. += "There is one paper cup left."
	else
		. += "There are no paper cups left."

/obj/structure/reagent_dispensers/water_cooler/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!paper_cups)
		to_chat(user, SPAN_WARNING("There aren't any cups left!"))
		return
	user.visible_message(SPAN_NOTICE("[user] takes a cup from [src]."), SPAN_NOTICE("You take a paper cup from [src]."))
	var/obj/item/reagent_containers/food/drinks/sillycup/S = new(get_turf(src))
	user.put_in_hands(S)
	paper_cups--

/obj/structure/reagent_dispensers/beerkeg
	name = "beer keg"
	desc = "Beer is liquid bread, it's good for you..."
	icon_state = "beer"
	reagent_id = /datum/reagent/consumable/ethanol/beer

/obj/structure/reagent_dispensers/beerkeg/blob_act(obj/structure/blob/B)
	explosion(src, heavy_impact_range = 3, light_impact_range = 5, flame_range = 10, flash_range = 7)
	if(!QDELETED(src))
		qdel(src)

/obj/effect/spawner/lootdrop/keg
	name = "keg spawner"
	lootdoubles = FALSE

	loot = list(
			/obj/structure/reagent_dispensers/keg/mead = 1,
			/obj/structure/reagent_dispensers/keg/milk = 1,
			/obj/structure/reagent_dispensers/keg/gargle = 1,
			/obj/structure/reagent_dispensers/keg/aphro = 1,
			/obj/structure/reagent_dispensers/keg/aphro/strong = 1,
			/obj/structure/reagent_dispensers/keg/semen = 1,
		)

/obj/structure/reagent_dispensers/keg
	name = "keg"
	desc = "A keg."
	icon_state = "keg"

/obj/structure/reagent_dispensers/keg/mead
	name = "keg of mead"
	desc = "A keg of mead."
	icon_state = "orangekeg"
	reagent_id = /datum/reagent/consumable/ethanol/mead
	starting_volume = 150

/obj/structure/reagent_dispensers/keg/milk
	name = "keg of milk"
	desc = "A keg of pasteurised, homogenised, filtered and semi-skimmed space milk."
	icon_state = "whitekeg"
	reagent_id = /datum/reagent/consumable/milk
	starting_volume = 150

/obj/structure/reagent_dispensers/keg/gargle
	name = "keg of pan galactic gargleblaster"
	desc = "A keg of... wow that's a long name."
	icon_state = "bluekeg"
	reagent_id = /datum/reagent/consumable/ethanol/gargle_blaster
	starting_volume = 150

/obj/structure/reagent_dispensers/keg/aphro
	name = "keg of aphrodisiac"
	desc = "A keg of aphrodisiac."
	icon_state = "pinkkeg"
	reagent_id = /datum/reagent/drug/aphrodisiac
	starting_volume = 150

/obj/structure/reagent_dispensers/keg/aphro/strong
	name = "keg of strong aphrodisiac"
	desc = "A keg of strong and addictive aphrodisiac."
	reagent_id = /datum/reagent/drug/aphrodisiacplus
	starting_volume = 120

/obj/structure/reagent_dispensers/keg/semen
	name = "keg of semen"
	desc = "Dear lord, where did this even come from?"
	icon_state = "whitekeg"
	reagent_id = /datum/reagent/semen
	starting_volume = 150


/obj/structure/reagent_dispensers/virusfood
	name = "virus food dispenser"
	desc = "A dispenser of low-potency virus mutagenic."
	icon_state = "virus_food"
	anchored = TRUE
	density = FALSE
	reagent_id = /datum/reagent/consumable/virus_food

/obj/structure/reagent_dispensers/virusfood/directional/north
	dir = SOUTH
	pixel_y = 30

/obj/structure/reagent_dispensers/virusfood/directional/south
	dir = NORTH
	pixel_y = -30

/obj/structure/reagent_dispensers/virusfood/directional/east
	dir = WEST
	pixel_x = 30

/obj/structure/reagent_dispensers/virusfood/directional/west
	dir = EAST
	pixel_x = -30

/obj/structure/reagent_dispensers/cooking_oil
	name = "vat of cooking oil"
	desc = "A huge metal vat with a tap on the front. Filled with cooking oil for use in frying food."
	icon_state = "vat"
	anchored = TRUE
	reagent_id = /datum/reagent/consumable/cooking_oil

/obj/structure/reagent_dispensers/servingdish
	name = "serving dish"
	desc = "A dish full of food slop for your bowl."
	icon = 'icons/obj/kitchen.dmi'
	icon_state = "serving"
	anchored = TRUE
	reagent_id = /datum/reagent/consumable/nutraslop

/obj/structure/reagent_dispensers/plumbed
	name = "stationary water tank"
	anchored = TRUE
	icon_state = "water_stationary"
	desc = "A stationary, plumbed, water tank."
	can_be_tanked = FALSE

/obj/structure/reagent_dispensers/plumbed/wrench_act(mob/living/user, obj/item/I)
	..()
	default_unfasten_wrench(user, I)
	return TRUE

/obj/structure/reagent_dispensers/plumbed/ComponentInitialize()
	AddComponent(/datum/component/plumbing/simple_supply)

/obj/structure/reagent_dispensers/plumbed/storage
	name = "stationary storage tank"
	icon_state = "tank_stationary"
	reagent_id = null //start empty

/obj/structure/reagent_dispensers/plumbed/storage/ComponentInitialize()
	. = ..()
	AddComponent(/datum/component/simple_rotation, ROTATION_ALTCLICK | ROTATION_CLOCKWISE | ROTATION_COUNTERCLOCKWISE | ROTATION_VERBS, null, CALLBACK(src, PROC_REF(can_be_rotated)))

/obj/structure/reagent_dispensers/plumbed/storage/update_overlays()
	. = ..()
	if(!reagents)
		return

	if(!reagents.total_volume)
		return

	var/mutable_appearance/tank_color = mutable_appearance('icons/obj/chemical_tanks.dmi', "tank_chem_overlay")
	tank_color.color = mix_color_from_reagents(reagents.reagent_list)
	. += tank_color

/obj/structure/reagent_dispensers/plumbed/storage/proc/can_be_rotated(mob/user, rotation_type)
	if(anchored)
		to_chat(user, SPAN_WARNING("It is fastened to the floor!"))
	return !anchored

/obj/structure/reagent_dispensers/plumbed/fuel
	name = "stationary fuel tank"
	icon_state = "fuel_stationary"
	desc = "A stationary, plumbed, fuel tank."
	reagent_id = /datum/reagent/fuel
