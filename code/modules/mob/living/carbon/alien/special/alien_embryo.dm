// This is to replace the previous datum/disease/alien_embryo for slightly improved handling and maintainability
// It functions almost identically (see code/datums/diseases/alien_embryo.dm)
/obj/item/organ/body_egg/alien_embryo
	name = "alien embryo"
	icon = 'icons/mob/alien.dmi'
	icon_state = "larva0_dead"
	food_reagents = list(/datum/reagent/consumable/nutriment = 5, /datum/reagent/toxin/acid = 10)
	///What stage of growth the embryo is at. Developed embryos give the host symptoms suggesting that an embryo is inside them.
	var/stage = 0
	/// Are we bursting out of the poor sucker who's the xeno mom?
	var/bursting = FALSE
	/// How long does it take to advance one stage? Growth time * 5 = how long till we make a Larva!
	var/growth_time = 60 SECONDS

/obj/item/organ/body_egg/alien_embryo/Initialize()
	. = ..()
	advance_embryo_stage()

/obj/item/organ/body_egg/alien_embryo/on_find(mob/living/finder)
	..()
	if(stage < 5)
		to_chat(finder, SPAN_NOTICE("It's small and weak, barely the size of a foetus."))
	else
		to_chat(finder, SPAN_NOTICE("It's grown quite large, and writhes slightly as you look at it."))
		if(prob(10))
			AttemptGrow(FALSE)

/obj/item/organ/body_egg/alien_embryo/on_life(delta_time, times_fired)
	. = ..()
	switch(stage)
		if(3, 4)
			if(DT_PROB(1, delta_time))
				owner.emote("sneeze")
			if(DT_PROB(1, delta_time))
				owner.emote("cough")
			if(DT_PROB(1, delta_time))
				to_chat(owner, SPAN_DANGER("Your throat feels sore."))
			if(DT_PROB(1, delta_time))
				to_chat(owner, SPAN_DANGER("Mucous runs down the back of your throat."))
		if(5)
			if(DT_PROB(1, delta_time))
				owner.emote("sneeze")
			if(DT_PROB(1, delta_time))
				owner.emote("cough")
			if(DT_PROB(2, delta_time))
				to_chat(owner, SPAN_DANGER("Your muscles ache."))
				if(prob(20))
					owner.take_bodypart_damage(1)
			if(DT_PROB(2, delta_time))
				to_chat(owner, SPAN_DANGER("Your stomach hurts."))
				if(prob(20))
					owner.adjustToxLoss(1)
		if(6)
			to_chat(owner, SPAN_DANGER("You feel something tearing its way out of your chest..."))
			owner.adjustToxLoss(5 * delta_time) // Why is this [TOX]?

/// Controls Xenomorph Embryo growth. If embryo is fully grown (or overgrown), stop the proc. If not, increase the stage by one and if it's not fully grown (stage 6), add a timer to do this proc again after however long the growth time variable is.
/obj/item/organ/body_egg/alien_embryo/proc/advance_embryo_stage()
	if(stage >= 6)
		return
	if(++stage < 6)
		INVOKE_ASYNC(src, PROC_REF(RefreshInfectionImage))
		addtimer(CALLBACK(src, PROC_REF(advance_embryo_stage)), growth_time)

/obj/item/organ/body_egg/alien_embryo/egg_process()
	if(stage == 6 && prob(50))
		for(var/datum/surgery/S in owner.surgeries)
			if(S.location == BODY_ZONE_CHEST && istype(S.get_surgery_step(), /datum/surgery_step/manipulate_organs))
				AttemptGrow(FALSE)
				return
		AttemptGrow()


/obj/item/organ/body_egg/alien_embryo/proc/AttemptGrow(violent = TRUE)
	if(!owner || bursting)
		return

	bursting = TRUE

	var/list/candidates = pollGhostCandidates("Do you want to play as an alien larva that will burst out of [owner.real_name]?", ROLE_ALIEN, ROLE_ALIEN, 100, POLL_IGNORE_ALIEN_LARVA)

	if(QDELETED(src) || QDELETED(owner))
		return

	if(!candidates.len || !owner)
		bursting = FALSE
		stage = 5 // If no ghosts sign up for the Larva, let's regress our growth by one minute, we will try again!
		addtimer(CALLBACK(src, PROC_REF(advance_embryo_stage)), growth_time)
		return

	var/mob/dead/observer/ghost = pick(candidates)

	var/mutable_appearance/overlay = mutable_appearance('icons/mob/alien.dmi', "burst_lie")
	owner.add_overlay(overlay)

	var/atom/xeno_loc = get_turf(owner)
	var/mob/living/carbon/alien/larva/new_xeno = new(xeno_loc)
	new_xeno.key = ghost.key
	SEND_SOUND(new_xeno, sound('sound/voice/hiss5.ogg',0,0,0,100)) //To get the player's attention
	ADD_TRAIT(new_xeno, TRAIT_IMMOBILIZED, type) //so we don't move during the bursting animation
	ADD_TRAIT(new_xeno, TRAIT_HANDS_BLOCKED, type)
	new_xeno.notransform = 1
	new_xeno.invisibility = INVISIBILITY_MAXIMUM

	sleep(6)

	if(QDELETED(src) || QDELETED(owner))
		qdel(new_xeno)
		CRASH("AttemptGrow failed due to the early qdeletion of source or owner.")

	if(new_xeno)
		REMOVE_TRAIT(new_xeno, TRAIT_IMMOBILIZED, type)
		REMOVE_TRAIT(new_xeno, TRAIT_HANDS_BLOCKED, type)
		new_xeno.notransform = 0
		new_xeno.invisibility = 0

	var/obj/item/bodypart/affecting = owner.get_bodypart(BODY_ZONE_CHEST)
	if(violent)
		new_xeno.visible_message(SPAN_DANGER("[new_xeno] bursts out of [owner] in a shower of gore!"), SPAN_USERDANGER("You exit [owner], your previous host."), SPAN_HEAR("You hear organic matter ripping and tearing!"))
		to_chat(owner, SPAN_DANGER("The shock sends you unconscious!"))
		affecting.receive_damage(brute = 60, wound_bonus = 10)
		owner.AdjustUnconscious(10 SECONDS)
	else
		new_xeno.visible_message(SPAN_DANGER("[new_xeno] wriggles out of [owner]!"), SPAN_USERDANGER("You exit [owner], your previous host."))
		affecting.receive_damage(brute = 40)
	owner.cut_overlay(overlay)
	qdel(src)


/*----------------------------------------
Proc: AddInfectionImages(C)
Des: Adds the infection image to all aliens for this embryo
----------------------------------------*/
/obj/item/organ/body_egg/alien_embryo/AddInfectionImages()
	for(var/mob/living/carbon/alien/alien in GLOB.player_list)
		var/I = image('icons/mob/alien.dmi', loc = owner, icon_state = "infected[stage]")
		alien.client.images += I

/*----------------------------------------
Proc: RemoveInfectionImage(C)
Des: Removes all images from the mob infected by this embryo
----------------------------------------*/
/obj/item/organ/body_egg/alien_embryo/RemoveInfectionImages()
	for(var/mob/living/carbon/alien/alien in GLOB.player_list)
		for(var/image/I in alien.client.images)
			var/searchfor = "infected"
			if(I.loc == owner && findtext(I.icon_state, searchfor, 1, length(searchfor) + 1))
				qdel(I)
