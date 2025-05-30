/obj/item/reverse_bear_trap
	name = "reverse bear trap"
	desc = "A horrifying set of shut metal jaws, rigged to a kitchen timer and secured by padlock to a head-mounted clamp. To apply, hit someone with it."
	icon = 'icons/obj/device.dmi'
	icon_state = "reverse_bear_trap"
	slot_flags = ITEM_SLOT_HEAD
	flags_1 = CONDUCT_1
	resistance_flags = FIRE_PROOF | UNACIDABLE
	w_class = WEIGHT_CLASS_NORMAL
	max_integrity = 300
	inhand_icon_state = "reverse_bear_trap"
	lefthand_file = 'icons/mob/inhands/items_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/items_righthand.dmi'

	var/ticking = FALSE
	var/time_left = 60 //seconds remaining until pop
	var/escape_chance = 0 //chance per "fiddle" to get the trap off your head
	var/struggling = FALSE

	var/time_since_last_beep = 0
	var/datum/looping_sound/reverse_bear_trap/soundloop
	var/datum/looping_sound/reverse_bear_trap_beep/soundloop2

/obj/item/reverse_bear_trap/Initialize()
	. = ..()
	soundloop = new(list(src))
	soundloop2 = new(list(src))

/obj/item/reverse_bear_trap/Destroy()
	QDEL_NULL(soundloop)
	QDEL_NULL(soundloop2)
	STOP_PROCESSING(SSprocessing, src)
	return ..()

/obj/item/reverse_bear_trap/process(delta_time)
	if(!ticking)
		return
	time_left -= delta_time
	soundloop2.mid_length = max(0.5, time_left - 5) //beepbeepbeepbeepbeep
	if(time_left <= 0 || !isliving(loc))
		playsound(src, 'sound/machines/microwave/microwave-end.ogg', 100, FALSE)
		soundloop.stop()
		soundloop2.stop()
		to_chat(loc, SPAN_USERDANGER("*ding*"))
		addtimer(CALLBACK(src, PROC_REF(snap)), 2)

/obj/item/reverse_bear_trap/attack_hand(mob/user, list/modifiers)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(C.get_item_by_slot(ITEM_SLOT_HEAD) == src)
			if(HAS_TRAIT_FROM(src, TRAIT_NODROP, REVERSE_BEAR_TRAP_TRAIT) && !struggling)
				struggling = TRUE
				var/fear_string
				switch(time_left)
					if(0 to 5)
						fear_string = "agonizingly"
					if(5 to 20)
						fear_string = "desperately"
					if(20 to 40)
						fear_string = "panickedly"
					if(40 to 50)
						fear_string = "shakily"
					if(50 to 60)
						fear_string = ""
				C.visible_message(SPAN_DANGER("[C] fiddles with and pulls at [src]..."), \
				SPAN_DANGER("You [fear_string] try to pull at [src]..."), "<i>You hear clicking and ticking.</i>")
				if(!do_after(user, 20, target = src))
					struggling = FALSE
					return
				if(!prob(escape_chance))
					to_chat(user, SPAN_WARNING("It doesn't budge!"))
					escape_chance++
				else
					user.visible_message(SPAN_WARNING("The lock on [user]'s [name] pops open!"), \
					SPAN_USERDANGER("You force open the padlock!"), "<i>You hear a single, pronounced click!</i>")
					REMOVE_TRAIT(src, TRAIT_NODROP, REVERSE_BEAR_TRAP_TRAIT)
				struggling = FALSE
			return
	..()

/obj/item/reverse_bear_trap/attack(mob/living/target, mob/living/user)
	if(target.get_item_by_slot(ITEM_SLOT_HEAD))
		to_chat(user, SPAN_WARNING("Remove [target.p_their()] headgear first!"))
		return
	target.visible_message(SPAN_WARNING("[user] starts forcing [src] onto [target]'s head!"), \
	SPAN_USERDANGER("[target] starts forcing [src] onto your head!"), "<i>You hear clanking.</i>")
	to_chat(user, SPAN_DANGER("You start forcing [src] onto [target]'s head..."))
	if(!do_after(user, 30, target = target) || target.get_item_by_slot(ITEM_SLOT_HEAD))
		return
	target.visible_message(SPAN_WARNING("[user] forces and locks [src] onto [target]'s head!"), \
	SPAN_USERDANGER("[target] locks [src] onto your head!"), "<i>You hear a click, and then a timer ticking down.</i>")
	to_chat(user, SPAN_DANGER("You force [src] onto [target]'s head and click the padlock shut."))
	user.dropItemToGround(src)
	target.equip_to_slot_if_possible(src, ITEM_SLOT_HEAD)
	arm()
	notify_ghosts("[user] put a reverse bear trap on [target]!", source = src, action = NOTIFY_ORBIT, flashwindow = FALSE, ghost_sound = 'sound/machines/beep.ogg', notify_volume = 75, header = "Reverse bear trap armed")

/obj/item/reverse_bear_trap/proc/snap()
	reset()
	var/mob/living/carbon/human/H = loc
	if(!istype(H) || H.get_item_by_slot(ITEM_SLOT_HEAD) != src)
		visible_message(SPAN_WARNING("[src]'s jaws snap open with an ear-piercing crack!"))
		playsound(src, 'sound/effects/snap.ogg', 75, TRUE)
	else
		var/mob/living/carbon/human/jill = loc
		jill.visible_message(SPAN_BOLDWARNING("[src] goes off in [jill]'s mouth, ripping [jill.p_their()] head apart!"), SPAN_USERDANGER("[src] goes off!"))
		jill.emote("scream")
		playsound(src, 'sound/effects/snap.ogg', 75, TRUE, frequency = 0.5)
		playsound(src, 'sound/effects/splat.ogg', 50, TRUE, frequency = 0.5)
		jill.apply_damage(9999, BRUTE, BODY_ZONE_HEAD)
		jill.death() //just in case, for some reason, they're still alive
		flash_color(jill, flash_color = "#FF0000", flash_time = 100)

/obj/item/reverse_bear_trap/proc/reset()
	ticking = FALSE
	update_appearance(UPDATE_OVERLAYS)
	REMOVE_TRAIT(src, TRAIT_NODROP, REVERSE_BEAR_TRAP_TRAIT)
	soundloop.stop()
	soundloop2.stop()
	STOP_PROCESSING(SSprocessing, src)

/obj/item/reverse_bear_trap/update_overlays()
	. = ..()
	if(ticking != TRUE)
		return
	/// note: this timer overlay increments one frame every second (to simulate a clock ticking). If you want to instead have it do a full cycle in a minute, set the 'delay' of each frame of the icon overlay to 75 rather than 10, and the worn overlay to twice that.
	. += "rbt_ticking"

/obj/item/reverse_bear_trap/proc/arm() //hulen
	ticking = TRUE
	update_appearance(UPDATE_OVERLAYS)
	escape_chance = initial(escape_chance) //we keep these vars until re-arm, for tracking purposes
	time_left = initial(time_left)
	ADD_TRAIT(src, TRAIT_NODROP, REVERSE_BEAR_TRAP_TRAIT)
	soundloop.start()
	soundloop2.mid_length = initial(soundloop2.mid_length)
	soundloop2.start()
	START_PROCESSING(SSprocessing, src)
