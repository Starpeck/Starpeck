//banana flavored chaos and horror ahead

/obj/item/clothing/shoes/clown_shoes/banana_shoes
	name = "mk-honk prototype shoes"
	desc = "Lost prototype of advanced clown tech. Powered by bananium, these shoes leave a trail of chaos in their wake."
	icon_state = "clown_prototype_off"
	actions_types = list(/datum/action/item_action/toggle)
	var/on = FALSE
	var/always_noslip = FALSE

/obj/item/clothing/shoes/clown_shoes/banana_shoes/Initialize()
	. = ..()
	if(always_noslip)
		clothing_flags |= NOSLIP

/obj/item/clothing/shoes/clown_shoes/banana_shoes/ComponentInitialize()
	. = ..()
	AddElement(/datum/element/update_icon_updates_onmob)
	AddComponent(/datum/component/material_container, list(/datum/material/bananium), 100 * MINERAL_MATERIAL_AMOUNT, MATCONTAINER_EXAMINE|MATCONTAINER_ANY_INTENT|MATCONTAINER_SILENT, allowed_items=/obj/item/stack)
	AddComponent(/datum/component/squeak, list('sound/items/bikehorn.ogg'=1), 75, falloff_exponent = 20)
	RegisterSignal(src, COMSIG_SHOES_STEP_ACTION, PROC_REF(on_step))

/obj/item/clothing/shoes/clown_shoes/banana_shoes/proc/on_step()
	SIGNAL_HANDLER

	var/mob/wearer = loc
	var/datum/component/material_container/bananium = GetComponent(/datum/component/material_container)
	if(on && istype(wearer))
		if(bananium.get_material_amount(/datum/material/bananium) < 100)
			on = !on
			if(!always_noslip)
				clothing_flags &= ~NOSLIP
			update_appearance()
			to_chat(loc, SPAN_WARNING("You ran out of bananium!"))
		else
			new /obj/item/grown/bananapeel/specialpeel(get_step(src,turn(wearer.dir, 180))) //honk
			bananium.use_amount_mat(100, /datum/material/bananium)

/obj/item/clothing/shoes/clown_shoes/banana_shoes/attack_self(mob/user)
	var/datum/component/material_container/bananium = GetComponent(/datum/component/material_container)
	var/sheet_amount = bananium.retrieve_all()
	if(sheet_amount)
		to_chat(user, SPAN_NOTICE("You retrieve [sheet_amount] sheets of bananium from the prototype shoes."))
	else
		to_chat(user, SPAN_WARNING("You cannot retrieve any bananium from the prototype shoes!"))

/obj/item/clothing/shoes/clown_shoes/banana_shoes/examine(mob/user)
	. = ..()
	. += SPAN_NOTICE("The shoes are [on ? "enabled" : "disabled"].")

/obj/item/clothing/shoes/clown_shoes/banana_shoes/ui_action_click(mob/user)
	var/datum/component/material_container/bananium = GetComponent(/datum/component/material_container)
	if(bananium.get_material_amount(/datum/material/bananium))
		on = !on
		update_appearance()
		to_chat(user, SPAN_NOTICE("You [on ? "activate" : "deactivate"] the prototype shoes."))
		if(!always_noslip)
			if(on)
				clothing_flags |= NOSLIP
			else
				clothing_flags &= ~NOSLIP
	else
		to_chat(user, SPAN_WARNING("You need bananium to turn the prototype shoes on!"))

/obj/item/clothing/shoes/clown_shoes/banana_shoes/update_icon_state()
	icon_state = "clown_prototype_[on ? "on" : "off"]"
	return ..()
