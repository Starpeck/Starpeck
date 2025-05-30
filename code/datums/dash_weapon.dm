/datum/action/innate/dash
	name = "Dash"
	desc = "Teleport to the targeted location."
	icon_icon = 'icons/mob/actions/actions_items.dmi'
	button_icon_state = "jetboot"
	var/current_charges = 1
	var/max_charges = 1
	var/charge_rate = 250
	var/obj/item/dashing_item
	var/dash_sound = 'sound/magic/blink.ogg'
	var/recharge_sound = 'sound/magic/charge.ogg'
	var/beam_effect = "blur"
	var/phasein = /obj/effect/temp_visual/dir_setting/ninja/phase
	var/phaseout = /obj/effect/temp_visual/dir_setting/ninja/phase/out

/datum/action/innate/dash/Grant(mob/user, obj/dasher)
	. = ..()
	dashing_item = dasher

/datum/action/innate/dash/Destroy()
	dashing_item = null
	return ..()

/datum/action/innate/dash/IsAvailable()
	if(current_charges > 0)
		return TRUE
	else
		return FALSE

/datum/action/innate/dash/Activate()
	dashing_item.attack_self(owner) //Used to toggle dash behavior in the dashing item

/datum/action/innate/dash/proc/Teleport(mob/user, atom/target)
	if(!IsAvailable())
		return
	var/turf/T = get_turf(target)
	if(target in view(user.client.view, user))
		var/obj/spot1 = new phaseout(get_turf(user), user.dir)
		user.forceMove(T)
		playsound(T, dash_sound, 25, TRUE)
		var/obj/spot2 = new phasein(get_turf(user), user.dir)
		spot1.Beam(spot2,beam_effect,time=2 SECONDS)
		current_charges--
		owner.update_action_buttons_icon()
		addtimer(CALLBACK(src, PROC_REF(charge)), charge_rate)

/datum/action/innate/dash/proc/charge()
	current_charges = clamp(current_charges + 1, 0, max_charges)
	owner.update_action_buttons_icon()
	if(recharge_sound)
		playsound(dashing_item, recharge_sound, 50, TRUE)
	to_chat(owner, SPAN_NOTICE("[src] now has [current_charges]/[max_charges] charges."))
