/**
 * # cursed item ai!
 *
 * Haunted AI tries to not be interacted with, and will attack people who do.
 * Cursed AI instead tries to be interacted with, and will attempt to equip itself onto people.
 * Added by /datum/element/cursed, and as such will try to remove this element and go dormant when it finds a victim to curse
 */
/datum/ai_controller/cursed
	movement_delay = 0.4 SECONDS
	blackboard = list(
		BB_CURSE_TARGET,
		BB_TARGET_SLOT,
		BB_CURSED_THROW_ATTEMPT_COUNT
	)

/datum/ai_controller/cursed/TryPossessPawn(atom/new_pawn)
	if(!isitem(new_pawn))
		return AI_CONTROLLER_INCOMPATIBLE
	RegisterSignal(new_pawn, COMSIG_MOVABLE_IMPACT, PROC_REF(on_throw_hit))
	RegisterSignal(new_pawn, COMSIG_ITEM_EQUIPPED, PROC_REF(on_equip))
	return ..() //Run parent at end

/datum/ai_controller/cursed/UnpossessPawn()
	UnregisterSignal(pawn, list(COMSIG_MOVABLE_IMPACT, COMSIG_ITEM_EQUIPPED))
	return ..() //Run parent at end

/datum/ai_controller/cursed/SelectBehaviors(delta_time)
	current_behaviors = list()
	var/obj/item/item_pawn = pawn


	//make sure we have a target
	var/mob/living/carbon/curse_target = blackboard[BB_CURSE_TARGET]
	if(!curse_target)
		current_behaviors += GET_AI_BEHAVIOR(/datum/ai_behavior/find_and_set/cursed)
		return
	//make sure attack is valid
	if(get_dist(curse_target, item_pawn) > CURSED_VIEW_RANGE)
		blackboard[BB_CURSE_TARGET] = null
		return
	current_movement_target = curse_target
	current_behaviors += GET_AI_BEHAVIOR(/datum/ai_behavior/item_move_close_and_attack/cursed)

/datum/ai_controller/cursed/PerformIdleBehavior(delta_time)
	var/obj/item/item_pawn = pawn
	if(ismob(item_pawn.loc)) //Being held. dont teleport
		return
	if(DT_PROB(CURSED_ITEM_TELEPORT_CHANCE, delta_time))
		playsound(item_pawn.loc, 'sound/items/haunted/ghostitemattack.ogg', 100, TRUE)
		do_teleport(pawn, get_turf(pawn), 4, channel = TELEPORT_CHANNEL_MAGIC)

///signal called by the pawn hitting something after a throw
/datum/ai_controller/cursed/proc/on_throw_hit(datum/source, atom/hit_atom, datum/thrownthing/throwingdatum)
	SIGNAL_HANDLER
	if(!iscarbon(hit_atom))
		return
	//equipcode has sleeps all over it.
	INVOKE_ASYNC(src, PROC_REF(try_equipping_to_target_slot), hit_atom)

///signal called by picking up the pawn, will try to equip to where it should actually be and start the curse
/datum/ai_controller/cursed/proc/on_equip(datum/source, mob/equipper, slot)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(try_equipping_to_target_slot), equipper, slot)

/**
 * curse of hunger component; for very hungry items.
 *
 * called when someone grabs the cursed item or the cursed item impacts with a mob it's throwing itself at
 * arguments:
 * * curse_victim: whomever we're attaching this to
 * * slot_already_in: the slot the item is already in before this was called, possibly null but at least in hands if picked up
 */
/datum/ai_controller/cursed/proc/try_equipping_to_target_slot(mob/living/carbon/curse_victim, slot_already_in)
	var/obj/item/item_pawn = pawn
	var/attempted_slot = blackboard[BB_TARGET_SLOT]
	if(slot_already_in && attempted_slot == slot_already_in) //thanks for making it easy
		what_a_horrible_night_to_have_a_curse()
		return
	if(attempted_slot == ITEM_SLOT_HANDS) //hands needs some different checks
		curse_victim.drop_all_held_items()
		if(curse_victim.put_in_hands(item_pawn, del_on_fail = FALSE))
			to_chat(curse_victim, SPAN_DANGER("[item_pawn] leaps into your hands!"))
			what_a_horrible_night_to_have_a_curse()
		return
	var/obj/item/blocking = curse_victim.get_item_by_slot(attempted_slot)
	if(!curse_victim.dropItemToGround(blocking, silent = TRUE))
		return //cannot equip to this person so whatever just keep whacking them until they die or fugg off
	curse_victim.equip_to_slot_if_possible(item_pawn, attempted_slot, qdel_on_fail = FALSE, disable_warning = FALSE)
	to_chat(curse_victim, SPAN_DANGER("[item_pawn] equips [item_pawn.p_them()]self onto you!"))
	what_a_horrible_night_to_have_a_curse()

///proc called when the cursed object successfully attaches itself to someone, removing the cursed element and by extension the ai itself
/datum/ai_controller/cursed/proc/what_a_horrible_night_to_have_a_curse()
	var/obj/item/item_pawn = pawn
	item_pawn.RemoveElement(/datum/element/cursed)
