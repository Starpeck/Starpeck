/datum/component/manual_breathing
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/obj/item/organ/lungs/L
	var/warn_grace = FALSE
	var/warn_dying = FALSE
	var/last_breath
	var/check_every = 12 SECONDS
	var/grace_period = 6 SECONDS
	var/damage_rate = 1 // organ damage taken per tick
	var/datum/emote/next_breath_type = /datum/emote/living/inhale

/datum/component/manual_breathing/Initialize()
	if(!iscarbon(parent))
		return COMPONENT_INCOMPATIBLE

	var/mob/living/carbon/C = parent
	L = C.getorganslot(ORGAN_SLOT_LUNGS)

	if(L)
		START_PROCESSING(SSdcs, src)
		last_breath = world.time
		to_chat(C, SPAN_NOTICE("You suddenly realize you're breathing manually."))

/datum/component/manual_breathing/Destroy(force, silent)
	L = null
	STOP_PROCESSING(SSdcs, src)
	to_chat(parent, SPAN_NOTICE("You revert back to automatic breathing."))
	return ..()

/datum/component/manual_breathing/RegisterWithParent()
	RegisterSignal(parent, COMSIG_MOB_EMOTE, PROC_REF(check_emote))
	RegisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN, PROC_REF(check_added_organ))
	RegisterSignal(parent, COMSIG_CARBON_LOSE_ORGAN, PROC_REF(check_removed_organ))
	RegisterSignal(parent, COMSIG_LIVING_REVIVE, PROC_REF(restart))
	RegisterSignal(parent, COMSIG_LIVING_DEATH, PROC_REF(pause))

/datum/component/manual_breathing/UnregisterFromParent()
	UnregisterSignal(parent, COMSIG_MOB_EMOTE)
	UnregisterSignal(parent, COMSIG_CARBON_GAIN_ORGAN)
	UnregisterSignal(parent, COMSIG_CARBON_LOSE_ORGAN)
	UnregisterSignal(parent, COMSIG_LIVING_REVIVE)
	UnregisterSignal(parent, COMSIG_LIVING_DEATH)

/datum/component/manual_breathing/proc/restart()
	SIGNAL_HANDLER

	START_PROCESSING(SSdcs, src)

/datum/component/manual_breathing/proc/pause()
	SIGNAL_HANDLER

	STOP_PROCESSING(SSdcs, src)

/datum/component/manual_breathing/process()
	var/mob/living/carbon/C = parent

	var/next_text = initial(next_breath_type.key)
	if(world.time > (last_breath + check_every + grace_period))
		if(!warn_dying)
			to_chat(C, SPAN_USERDANGER("You begin to suffocate, you need to [next_text]!"))
			warn_dying = TRUE

		L.applyOrganDamage(damage_rate)
		C.losebreath += 0.8
	else if(world.time > (last_breath + check_every))
		if(!warn_grace)
			to_chat(C, SPAN_DANGER("You feel a need to [next_text]!"))
			warn_grace = TRUE

/datum/component/manual_breathing/proc/check_added_organ(mob/who_cares, obj/item/organ/O)
	SIGNAL_HANDLER

	var/obj/item/organ/eyes/new_lungs = O

	if(istype(new_lungs,/obj/item/organ/lungs))
		L = new_lungs
		START_PROCESSING(SSdcs, src)

/datum/component/manual_breathing/proc/check_removed_organ(mob/who_cares, obj/item/organ/O)
	SIGNAL_HANDLER

	var/obj/item/organ/lungs/old_lungs = O

	if(istype(old_lungs, /obj/item/organ/lungs))
		L = null
		STOP_PROCESSING(SSdcs, src)

/datum/component/manual_breathing/proc/check_emote(mob/living/carbon/user, datum/emote/emote)
	SIGNAL_HANDLER

	if(emote.type == next_breath_type)
		if(next_breath_type == /datum/emote/living/inhale)
			next_breath_type = /datum/emote/living/exhale
		else
			next_breath_type = /datum/emote/living/inhale

		warn_grace = FALSE
		warn_dying = FALSE
		last_breath = world.time

		var/mob/living/carbon/C = parent
		C.losebreath = max(0, C.losebreath - 0.4)
