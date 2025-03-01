/datum/component/scon_hud
	var/atom/movable/screen/arousal/screen_obj

/datum/component/scon_hud/Initialize()
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE

	START_PROCESSING(SSobj, src)

	RegisterSignal(parent, COMSIG_MOB_HUD_CREATED, PROC_REF(modify_hud))

	var/mob/living/owner = parent
	if(owner.hud_used)
		modify_hud()
		var/datum/hud/hud = owner.hud_used
		hud.show_hud(hud.hud_version)

/datum/component/scon_hud/Destroy()
	STOP_PROCESSING(SSobj, src)
	unmodify_hud()
	return ..()

/datum/component/scon_hud/proc/print_arousal(mob/user)
	var/target_state = 0
	var/mob/living/owner = parent
	if(owner.sexcon)
		target_state = round((owner.sexcon.arousal / ACTIVE_EJAC_THRESHOLD) * 4)
	target_state = clamp(target_state, 0, 4)
	switch(target_state)
		if(0)
			to_chat(user, SPAN_NOTICE("I am not aroused."))
		if(1)
			to_chat(user, SPAN_LOVE("I am feeling a little frisky..."))
		if(2)
			to_chat(user, SPAN_LOVE("I could use some relief..."))
		if(3)
			to_chat(user, SPAN_LOVEBOLD("I need some relief!"))
		if(4)
			to_chat(user, SPAN_LOVEBOLD("GOD I NEED TO GO DOWN!!"))


/datum/component/scon_hud/proc/update_hud_icon()
	if(!screen_obj)
		return
	var/mob/living/owner = parent
	if(!(owner.client || owner.hud_used))
		return
	var/target_state = 0
	if(owner.sexcon)
		target_state = round((owner.sexcon.arousal / ACTIVE_EJAC_THRESHOLD) * 10)

	target_state = clamp(target_state, 0, 10)
	screen_obj.icon_state = "arousal[target_state]"

/datum/component/scon_hud/process(delta_time)
	update_hud_icon()

/datum/component/scon_hud/proc/modify_hud(datum/source)
	SIGNAL_HANDLER

	var/mob/living/owner = parent
	var/datum/hud/hud = owner.hud_used
	screen_obj = new
	hud.infodisplay += screen_obj
	RegisterSignal(hud, COMSIG_PARENT_QDELETING, PROC_REF(unmodify_hud))
	RegisterSignal(screen_obj, COMSIG_CLICK, PROC_REF(hud_click))

/datum/component/scon_hud/proc/unmodify_hud(datum/source)
	SIGNAL_HANDLER

	if(!screen_obj)
		return
	var/mob/living/owner = parent
	var/datum/hud/hud = owner.hud_used
	if(hud?.infodisplay)
		hud.infodisplay -= screen_obj
	QDEL_NULL(screen_obj)

/datum/component/scon_hud/proc/hud_click(datum/source, location, control, params, mob/user)
	SIGNAL_HANDLER

	if(user != parent)
		return
	var/mob/living/owner = parent
	var/list/modifiers = params2list(params)
	if(LAZYACCESS(modifiers, RIGHT_CLICK))
		if(owner.sexcon)
			owner.sexcon.start(owner)
	else
		print_arousal(user)

/atom/movable/screen/arousal
	name = "arousal"
	icon = 'icons/hud/screen_arousal.dmi'
	icon_state = "arousal0"
	screen_loc = ui_mood

/atom/movable/screen/arousal/attack_tk()
	return
