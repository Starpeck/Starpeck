/obj/item/electropack
	name = "electropack"
	desc = "Dance my monkeys! DANCE!!!"
	icon = 'icons/obj/radio.dmi'
	icon_state = "electropack0"
	inhand_icon_state = "electropack"
	lefthand_file = 'icons/mob/inhands/misc/devices_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/devices_righthand.dmi'
	flags_1 = CONDUCT_1
	slot_flags = ITEM_SLOT_BACK
	w_class = WEIGHT_CLASS_HUGE
	custom_materials = list(/datum/material/iron=10000, /datum/material/glass=2500)

	var/on = TRUE
	var/code = 2
	var/frequency = FREQ_ELECTROPACK
	var/shock_cooldown = FALSE

/obj/item/electropack/Initialize()
	. = ..()
	set_frequency(frequency)

/obj/item/electropack/Destroy()
	SSradio.remove_object(src, frequency)
	return ..()

/obj/item/electropack/suicide_act(mob/user)
	user.visible_message(SPAN_SUICIDE("[user] hooks [user.p_them()]self to the electropack and spams the trigger! It looks like [user.p_theyre()] trying to commit suicide!"))
	return (FIRELOSS)

//ATTACK HAND IGNORING PARENT RETURN VALUE
/obj/item/electropack/attack_hand(mob/user, list/modifiers)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(src == C.back)
			to_chat(user, SPAN_WARNING("You need help taking this off!"))
			return
	return ..()

/obj/item/electropack/attackby(obj/item/W, mob/user, params)
	if(istype(W, /obj/item/clothing/head/helmet))
		var/obj/item/assembly/shock_kit/A = new /obj/item/assembly/shock_kit(user)
		A.icon = 'icons/obj/assemblies.dmi'

		if(!user.transferItemToLoc(W, A))
			to_chat(user, SPAN_WARNING("[W] is stuck to your hand, you cannot attach it to [src]!"))
			return
		W.master = A
		A.helmet_part = W

		user.transferItemToLoc(src, A, TRUE)
		master = A
		A.electropack_part = src

		user.put_in_hands(A)
		A.add_fingerprint(user)
	else
		return ..()

/obj/item/electropack/receive_signal(datum/signal/signal)
	if(!signal || signal.data["code"] != code)
		return
	if(isliving(loc) && on)
		if(shock_cooldown)
			return
		shock_cooldown = TRUE
		addtimer(VARSET_CALLBACK(src, shock_cooldown, FALSE), 100)
		var/mob/living/L = loc
		step(L, pick(GLOB.cardinals))

		to_chat(L, SPAN_DANGER("You feel a sharp shock!"))
		var/datum/effect_system/spark_spread/s = new /datum/effect_system/spark_spread
		s.set_up(3, 1, L)
		s.start()

		L.Paralyze(100)

	if(master)
		if(isassembly(master))
			var/obj/item/assembly/master_as_assembly = master
			master_as_assembly.pulsed()
		master.receive_signal()

/obj/item/electropack/proc/set_frequency(new_frequency)
	SSradio.remove_object(src, frequency)
	frequency = new_frequency
	SSradio.add_object(src, frequency, RADIO_SIGNALER)

/obj/item/electropack/ui_state(mob/user)
	return GLOB.hands_state

/obj/item/electropack/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Electropack", name)
		ui.open()

/obj/item/electropack/ui_data(mob/user)
	var/list/data = list()
	data["power"] = on
	data["frequency"] = frequency
	data["code"] = code
	data["minFrequency"] = MIN_FREE_FREQ
	data["maxFrequency"] = MAX_FREE_FREQ
	return data

/obj/item/electropack/ui_act(action, params)
	. = ..()
	if(.)
		return

	switch(action)
		if("power")
			on = !on
			icon_state = "electropack[on]"
			. = TRUE
		if("freq")
			var/value = unformat_frequency(params["freq"])
			if(value)
				frequency = sanitize_frequency(value, TRUE)
				set_frequency(frequency)
				. = TRUE
		if("code")
			var/value = text2num(params["code"])
			if(value)
				value = round(value)
				code = clamp(value, 1, 100)
				. = TRUE
		if("reset")
			if(params["reset"] == "freq")
				frequency = initial(frequency)
				. = TRUE
			else if(params["reset"] == "code")
				code = initial(code)
				. = TRUE

/obj/item/electropack/shockcollar
	name = "shock collar"
	desc = "A reinforced metal collar. It seems to have some form of wiring near the front. Strange.."
	icon = 'icons/obj/clothing/neck.dmi'
	icon_state = "shockcollar"
	inhand_icon_state = "shockcollar"
	body_parts_covered = NECK
	slot_flags = ITEM_SLOT_NECK //no more pocket shockers. Now done without lazyness
	w_class = WEIGHT_CLASS_SMALL
	strip_delay = 60
	equip_delay_other = 60
	custom_materials = list(/datum/material/iron = 5000, /datum/material/glass = 2000)
	var/tagname = null

/obj/item/electropack/shockcollar/attack_hand(mob/user, list/modifiers)
	if(loc == user && user.get_item_by_slot(ITEM_SLOT_NECK))
		to_chat(user, "<span class='warning'>The collar is fastened tight! You'll need help taking this off!</span>")
		return
	return ..()

/obj/item/electropack/shockcollar/receive_signal(datum/signal/signal) //we have to override this because of text
	if(!signal || signal.data["code"] != code)
		return

	if(isliving(loc) && on) //the "on" arg is currently useless
		var/mob/living/L = loc
		if(!L.get_item_by_slot(ITEM_SLOT_NECK)) //**properly** stops pocket shockers
			return
		if(shock_cooldown == TRUE)
			return
		shock_cooldown = TRUE
		addtimer(VARSET_CALLBACK(src, shock_cooldown, FALSE), 100)
		step(L, pick(GLOB.cardinals))

		to_chat(L, SPAN_DANGER("You feel a sharp shock from the collar!"))

		do_sparks(3, FALSE, L)

		L.Knockdown(20)

	if(master)
		master.receive_signal()
	return

/obj/item/electropack/shockcollar/attackby(obj/item/W, mob/user, params) //moves it here because on_click is being bad
	if(istype(W, /obj/item/pen))
		var/t = stripped_input(user, "Would you like to change the name on the tag?", "Name your new pet", tagname ? tagname : "Spot", MAX_NAME_LEN)
		if(t)
			tagname = t
			name = "[initial(name)] - [t]"
		return
	if(istype(W, /obj/item/clothing/head/helmet)) //lazy method of denying this
		return
	else
		return ..()
