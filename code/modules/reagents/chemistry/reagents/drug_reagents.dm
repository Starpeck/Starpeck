/datum/reagent/drug
	name = "Drug"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	taste_description = "bitterness"
	var/trippy = TRUE //Does this drug make you trip?

/datum/reagent/drug/on_mob_end_metabolize(mob/living/M)
	if(trippy)
		SEND_SIGNAL(M, COMSIG_CLEAR_MOOD_EVENT, "[type]_high")

/datum/reagent/drug/space_drugs
	name = "Space drugs"
	description = "An illegal chemical compound used as drug."
	color = "#60A584" // rgb: 96, 165, 132
	overdose_threshold = 30
	ph = 9
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/hallucinogens = 10) //4 per 2 seconds

/datum/reagent/drug/space_drugs/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.set_drugginess(15 * REM * delta_time)
	if(isturf(M.loc) && !isspaceturf(M.loc) && !HAS_TRAIT(M, TRAIT_IMMOBILIZED) && DT_PROB(5, delta_time))
		step(M, pick(GLOB.cardinals))
	if(DT_PROB(3.5, delta_time))
		M.emote(pick("twitch","drool","moan","giggle"))
	..()

/datum/reagent/drug/space_drugs/overdose_start(mob/living/M)
	to_chat(M, SPAN_USERDANGER("You start tripping hard!"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "[type]_overdose", /datum/mood_event/overdose, name)

/datum/reagent/drug/space_drugs/overdose_process(mob/living/M, delta_time, times_fired)
	if(M.hallucination < volume && DT_PROB(10, delta_time))
		M.hallucination += 5
	..()

/datum/reagent/drug/cannabis
	name = "Cannabis"
	description = "A psychoactive drug from the Cannabis plant used for recreational purposes."
	color = "#059033"
	overdose_threshold = INFINITY
	ph = 6
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	metabolization_rate = 0.125 * REAGENTS_METABOLISM

/datum/reagent/drug/cannabis/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.apply_status_effect(/datum/status_effect/stoned)
	if(DT_PROB(1, delta_time))
		var/smoke_message = pick("You feel relaxed.","You feel calmed.","Your mouth feels dry.","You could use some water.","Your heart beats quickly.","You feel clumsy.","You crave junk food.")
		to_chat(M, SPAN_NOTICE(smoke_message))
	if(DT_PROB(2, delta_time))
		M.emote(pick("smile","laugh","giggle"))
	M.adjust_nutrition(-1 * REM * delta_time) //munchies
	if(DT_PROB(4, delta_time) && M.body_position == LYING_DOWN && !M.IsSleeping()) //chance to fall asleep if lying down
		to_chat(M, SPAN_WARNING("You doze off..."))
		M.Sleeping(10 SECONDS)
	if(DT_PROB(4, delta_time) && M.buckled && M.body_position != LYING_DOWN && !M.IsParalyzed()) //chance to be couchlocked if sitting
		to_chat(M, SPAN_WARNING("It's too comfy to move..."))
		M.Paralyze(10 SECONDS)
	return ..()

/datum/reagent/drug/nicotine
	name = "Nicotine"
	description = "Slightly reduces stun times. If overdosed it will deal toxin and oxygen damage."
	reagent_state = LIQUID
	color = "#60A584" // rgb: 96, 165, 132
	taste_description = "smoke"
	trippy = FALSE
	overdose_threshold=15
	metabolization_rate = 0.125 * REAGENTS_METABOLISM
	ph = 8
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/nicotine = 18) // 7.2 per 2 seconds

	//Nicotine is used as a pesticide IRL.
/datum/reagent/drug/nicotine/on_hydroponics_apply(obj/item/seeds/myseed, datum/reagents/chems, obj/machinery/hydroponics/mytray, mob/user)
	. = ..()
	if(chems.has_reagent(type, 1))
		mytray.adjust_toxic(round(chems.get_reagent_amount(type)))
		mytray.adjust_pestlevel(-rand(1,2))

/datum/reagent/drug/nicotine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(0.5, delta_time))
		var/smoke_message = pick("You feel relaxed.", "You feel calmed.","You feel alert.","You feel rugged.")
		to_chat(M, SPAN_NOTICE("[smoke_message]"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "smoked", /datum/mood_event/smoked, name)
	M.Jitter(0) //calms down any withdrawal jitters
	M.AdjustStun(-50  * REM * delta_time)
	M.AdjustKnockdown(-50 * REM * delta_time)
	M.AdjustUnconscious(-50 * REM * delta_time)
	M.AdjustParalyzed(-50 * REM * delta_time)
	M.AdjustImmobilized(-50 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/drug/nicotine/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustToxLoss(0.1 * REM * delta_time, 0)
	M.adjustOxyLoss(1.1 * REM * delta_time, 0)
	..()
	. = TRUE

/datum/reagent/drug/crank
	name = "Crank"
	description = "Reduces stun times by about 200%. If overdosed it will deal significant Toxin, Brute and Brain damage."
	reagent_state = LIQUID
	color = "#FA00C8"
	overdose_threshold = 20
	ph = 10
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/stimulants = 14) //5.6 per 2 seconds

/datum/reagent/drug/crank/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(DT_PROB(2.5, delta_time))
		var/high_message = pick("You feel jittery.", "You feel like you gotta go fast.", "You feel like you need to step it up.")
		to_chat(M, SPAN_NOTICE("[high_message]"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "tweaking", /datum/mood_event/stimulant_medium, name)
	M.AdjustStun(-20 * REM * delta_time)
	M.AdjustKnockdown(-20 * REM * delta_time)
	M.AdjustUnconscious(-20 * REM * delta_time)
	M.AdjustImmobilized(-20 * REM * delta_time)
	M.AdjustParalyzed(-20 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/drug/crank/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 2 * REM * delta_time)
	M.adjustToxLoss(2 * REM * delta_time, 0)
	M.adjustBruteLoss(2 * REM * delta_time, FALSE, FALSE, BODYPART_ORGANIC)
	..()
	. = TRUE

/datum/reagent/drug/krokodil
	name = "Krokodil"
	description = "Cools and calms you down. If overdosed it will deal significant Brain and Toxin damage."
	reagent_state = LIQUID
	color = "#0064B4"
	overdose_threshold = 20
	ph = 9
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/opiods = 18) //7.2 per 2 seconds


/datum/reagent/drug/krokodil/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/high_message = pick("You feel calm.", "You feel collected.", "You feel like you need to relax.")
	if(DT_PROB(2.5, delta_time))
		to_chat(M, SPAN_NOTICE("[high_message]"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "smacked out", /datum/mood_event/narcotic_heavy, name)
	if(current_cycle == 35 && creation_purity <= 0.6)
		if(!istype(M.dna.species, /datum/species/krokodil_addict))
			to_chat(M, SPAN_USERDANGER("Your skin falls off easily!"))
			M.adjustBruteLoss(50*REM, 0) // holy shit your skin just FELL THE FUCK OFF
			M.set_species(/datum/species/krokodil_addict)
	..()

/datum/reagent/drug/krokodil/overdose_process(mob/living/M, delta_time, times_fired)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.25 * REM * delta_time)
	M.adjustToxLoss(0.25 * REM * delta_time, 0)
	..()
	. = TRUE



/datum/reagent/drug/methamphetamine
	name = "Methamphetamine"
	description = "Reduces stun times by about 300%, speeds the user up, and allows the user to quickly recover stamina while dealing a small amount of Brain damage. If overdosed the subject will move randomly, laugh randomly, drop items and suffer from Toxin and Brain damage. If addicted the subject will constantly jitter and drool, before becoming dizzy and losing motor control and eventually suffer heavy toxin damage."
	reagent_state = LIQUID
	color = "#FAFAFA"
	overdose_threshold = 20
	metabolization_rate = 0.75 * REAGENTS_METABOLISM
	ph = 5
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/stimulants = 12) //4.8 per 2 seconds

/datum/reagent/drug/methamphetamine/on_mob_metabolize(mob/living/L)
	..()
	L.add_movespeed_modifier(/datum/movespeed_modifier/reagent/methamphetamine)

/datum/reagent/drug/methamphetamine/on_mob_end_metabolize(mob/living/L)
	L.remove_movespeed_modifier(/datum/movespeed_modifier/reagent/methamphetamine)
	..()

/datum/reagent/drug/methamphetamine/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/high_message = pick("You feel hyper.", "You feel like you need to go faster.", "You feel like you can run the world.")
	if(DT_PROB(2.5, delta_time))
		to_chat(M, SPAN_NOTICE("[high_message]"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "tweaking", /datum/mood_event/stimulant_medium, name)
	M.AdjustStun(-40 * REM * delta_time)
	M.AdjustKnockdown(-40 * REM * delta_time)
	M.AdjustUnconscious(-40 * REM * delta_time)
	M.AdjustParalyzed(-40 * REM * delta_time)
	M.AdjustImmobilized(-40 * REM * delta_time)
	M.adjustStaminaLoss(-2 * REM * delta_time, 0)
	M.Jitter(2 * REM * delta_time)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, rand(1, 4) * REM * delta_time)
	if(DT_PROB(2.5, delta_time))
		M.emote(pick("twitch", "shiver"))
	..()
	. = TRUE

/datum/reagent/drug/methamphetamine/overdose_process(mob/living/M, delta_time, times_fired)
	if(!HAS_TRAIT(M, TRAIT_IMMOBILIZED) && !ismovable(M.loc))
		for(var/i in 1 to round(4 * REM * delta_time, 1))
			step(M, pick(GLOB.cardinals))
	if(DT_PROB(10, delta_time))
		M.emote("laugh")
	if(DT_PROB(18, delta_time))
		M.visible_message(SPAN_DANGER("[M]'s hands flip out and flail everywhere!"))
		M.drop_all_held_items()
	..()
	M.adjustToxLoss(1 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, (rand(5, 10) / 10) * REM * delta_time)
	. = TRUE

/datum/reagent/drug/bath_salts
	name = "Bath Salts"
	description = "Makes you impervious to stuns and grants a stamina regeneration buff, but you will be a nearly uncontrollable tramp-bearded raving lunatic."
	reagent_state = LIQUID
	color = "#FAFAFA"
	overdose_threshold = 20
	taste_description = "salt" // because they're bathsalts?
	addiction_types = list(/datum/addiction/stimulants = 25)  //8 per 2 seconds
	var/datum/brain_trauma/special/psychotic_brawling/bath_salts/rage
	ph = 8.2
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED

/datum/reagent/drug/bath_salts/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_STUNIMMUNE, type)
	ADD_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	if(iscarbon(L))
		var/mob/living/carbon/C = L
		rage = new()
		C.gain_trauma(rage, TRAUMA_RESILIENCE_ABSOLUTE)

/datum/reagent/drug/bath_salts/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_STUNIMMUNE, type)
	REMOVE_TRAIT(L, TRAIT_SLEEPIMMUNE, type)
	if(rage)
		QDEL_NULL(rage)
	..()

/datum/reagent/drug/bath_salts/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(DT_PROB(2.5, delta_time))
		to_chat(M, SPAN_NOTICE("[high_message]"))
	SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "salted", /datum/mood_event/stimulant_heavy, name)
	M.adjustStaminaLoss(-5 * REM * delta_time, 0)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 4 * REM * delta_time)
	M.hallucination += 5 * REM * delta_time
	if(!HAS_TRAIT(M, TRAIT_IMMOBILIZED) && !ismovable(M.loc))
		step(M, pick(GLOB.cardinals))
		step(M, pick(GLOB.cardinals))
	..()
	. = TRUE

/datum/reagent/drug/bath_salts/overdose_process(mob/living/M, delta_time, times_fired)
	M.hallucination += 5 * REM * delta_time
	if(!HAS_TRAIT(M, TRAIT_IMMOBILIZED) && !ismovable(M.loc))
		for(var/i in 1 to round(8 * REM * delta_time, 1))
			step(M, pick(GLOB.cardinals))
	if(DT_PROB(10, delta_time))
		M.emote(pick("twitch","drool","moan"))
	if(DT_PROB(28, delta_time))
		M.drop_all_held_items()
	..()

/datum/reagent/drug/aranesp
	name = "Aranesp"
	description = "Amps you up, gets you going, and rapidly restores stamina damage. Side effects include breathlessness and toxicity."
	reagent_state = LIQUID
	color = "#78FFF0"
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/stimulants = 8)

/datum/reagent/drug/aranesp/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	var/high_message = pick("You feel amped up.", "You feel ready.", "You feel like you can push it to the limit.")
	if(DT_PROB(2.5, delta_time))
		to_chat(M, SPAN_NOTICE("[high_message]"))
	M.adjustStaminaLoss(-18 * REM * delta_time, 0)
	M.adjustToxLoss(0.5 * REM * delta_time, 0)
	if(DT_PROB(30, delta_time))
		M.losebreath++
		M.adjustOxyLoss(1, 0)
	..()
	. = TRUE

/datum/reagent/drug/happiness
	name = "Happiness"
	description = "Fills you with ecstasic numbness and causes minor brain damage. Highly addictive. If overdosed causes sudden mood swings."
	reagent_state = LIQUID
	color = "#EE35FF"
	overdose_threshold = 20
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	taste_description = "paint thinner"
	addiction_types = list(/datum/addiction/hallucinogens = 18)

/datum/reagent/drug/happiness/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_FEARLESS, type)
	SEND_SIGNAL(L, COMSIG_ADD_MOOD_EVENT, "happiness_drug", /datum/mood_event/happiness_drug)

/datum/reagent/drug/happiness/on_mob_delete(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_FEARLESS, type)
	SEND_SIGNAL(L, COMSIG_CLEAR_MOOD_EVENT, "happiness_drug")
	..()

/datum/reagent/drug/happiness/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.jitteriness = 0
	M.set_confusion(0)
	M.disgust = 0
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.2 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/drug/happiness/overdose_process(mob/living/M, delta_time, times_fired)
	if(DT_PROB(16, delta_time))
		var/reaction = rand(1,3)
		switch(reaction)
			if(1)
				M.emote("laugh")
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "happiness_drug", /datum/mood_event/happiness_drug_good_od)
			if(2)
				M.emote("sway")
				M.Dizzy(25)
			if(3)
				M.emote("frown")
				SEND_SIGNAL(M, COMSIG_ADD_MOOD_EVENT, "happiness_drug", /datum/mood_event/happiness_drug_bad_od)
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.5 * REM * delta_time)
	..()
	. = TRUE

/datum/reagent/drug/pumpup
	name = "Pump-Up"
	description = "Take on the world! A fast acting, hard hitting drug that pushes the limit on what you can handle."
	reagent_state = LIQUID
	color = "#e38e44"
	metabolization_rate = 2 * REAGENTS_METABOLISM
	overdose_threshold = 30
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/stimulants = 6) //2.6 per 2 seconds

/datum/reagent/drug/pumpup/on_mob_metabolize(mob/living/L)
	..()
	ADD_TRAIT(L, TRAIT_STUNRESISTANCE, type)

/datum/reagent/drug/pumpup/on_mob_end_metabolize(mob/living/L)
	REMOVE_TRAIT(L, TRAIT_STUNRESISTANCE, type)
	..()

/datum/reagent/drug/pumpup/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	M.Jitter(5 * REM * delta_time)

	if(DT_PROB(2.5, delta_time))
		to_chat(M, SPAN_NOTICE("[pick("Go! Go! GO!", "You feel ready...", "You feel invincible...")]"))
	if(DT_PROB(7.5, delta_time))
		M.losebreath++
		M.adjustToxLoss(2, 0)
	..()
	. = TRUE

/datum/reagent/drug/pumpup/overdose_start(mob/living/M)
	to_chat(M, SPAN_USERDANGER("You can't stop shaking, your heart beats faster and faster..."))

/datum/reagent/drug/pumpup/overdose_process(mob/living/M, delta_time, times_fired)
	M.Jitter(5 * REM * delta_time)
	if(DT_PROB(2.5, delta_time))
		M.drop_all_held_items()
	if(DT_PROB(7.5, delta_time))
		M.emote(pick("twitch","drool"))
	if(DT_PROB(10, delta_time))
		M.losebreath++
		M.adjustStaminaLoss(4, 0)
	if(DT_PROB(7.5, delta_time))
		M.adjustToxLoss(2, 0)
	..()

/datum/reagent/drug/maint
	name = "Maintenance Drugs"
	chemical_flags = NONE

/datum/reagent/drug/maint/powder
	name = "Maintenance Powder"
	description = "An unknown powder that you most likely gotten from an assistant, a bored chemist... or cooked yourself. It is a refined form of tar that enhances your mental ability, making you learn stuff a lot faster."
	reagent_state = SOLID
	color = "#ffffff"
	metabolization_rate = 0.5 * REAGENTS_METABOLISM
	overdose_threshold = 15
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/maintenance_drugs = 14)

/datum/reagent/drug/maint/powder/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	. = ..()
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 0.1 * REM * delta_time)
	// 5x if you want to OD, you can potentially go higher, but good luck managing the brain damage.
	var/amt = max(round(volume/3, 0.1), 1)
	M?.mind?.experience_multiplier_reasons |= type
	M?.mind?.experience_multiplier_reasons[type] = amt * REM * delta_time

/datum/reagent/drug/maint/powder/on_mob_end_metabolize(mob/living/M)
	. = ..()
	M?.mind?.experience_multiplier_reasons[type] = null
	M?.mind?.experience_multiplier_reasons -= type

/datum/reagent/drug/maint/powder/overdose_process(mob/living/M, delta_time, times_fired)
	. = ..()
	M.adjustOrganLoss(ORGAN_SLOT_BRAIN, 6 * REM * delta_time)

/datum/reagent/drug/maint/sludge
	name = "Maintenance Sludge"
	description = "An unknown sludge that you most likely gotten from an assistant, a bored chemist... or cooked yourself. Half refined, it fills your body with itself, making it more resistant to wounds, but causes toxins to accumulate."
	reagent_state = LIQUID
	color = "#203d2c"
	metabolization_rate = 2 * REAGENTS_METABOLISM
	overdose_threshold = 25
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/maintenance_drugs = 8)

/datum/reagent/drug/maint/sludge/on_mob_metabolize(mob/living/L)

	. = ..()
	ADD_TRAIT(L,TRAIT_HARDLY_WOUNDED,type)

/datum/reagent/drug/maint/sludge/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	. = ..()
	M.adjustToxLoss(0.5 * REM * delta_time)

/datum/reagent/drug/maint/sludge/on_mob_end_metabolize(mob/living/M)
	. = ..()
	REMOVE_TRAIT(M,TRAIT_HARDLY_WOUNDED,type)

/datum/reagent/drug/maint/sludge/overdose_process(mob/living/M, delta_time, times_fired)
	. = ..()
	if(!iscarbon(M))
		return
	var/mob/living/carbon/carbie = M
	//You will be vomiting so the damage is really for a few ticks before you flush it out of your system
	carbie.adjustToxLoss(1 * REM * delta_time)
	if(DT_PROB(5, delta_time))
		carbie.adjustToxLoss(5)
		carbie.vomit()

/datum/reagent/drug/maint/tar
	name = "Maintenance Tar"
	description = "An unknown tar that you most likely gotten from an assistant, a bored chemist... or cooked yourself. Raw tar, straight from the floor. It can help you with escaping bad situations at the cost of liver damage."
	reagent_state = LIQUID
	color = "#000000"
	overdose_threshold = 30
	chemical_flags = REAGENT_CAN_BE_SYNTHESIZED
	addiction_types = list(/datum/addiction/maintenance_drugs = 5)

/datum/reagent/drug/maint/tar/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	. = ..()

	M.AdjustStun(-10 * REM * delta_time)
	M.AdjustKnockdown(-10 * REM * delta_time)
	M.AdjustUnconscious(-10 * REM * delta_time)
	M.AdjustParalyzed(-10 * REM * delta_time)
	M.AdjustImmobilized(-10 * REM * delta_time)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 1.5 * REM * delta_time)

/datum/reagent/drug/maint/tar/overdose_process(mob/living/M, delta_time, times_fired)
	. = ..()

	M.adjustToxLoss(5 * REM * delta_time)
	M.adjustOrganLoss(ORGAN_SLOT_LIVER, 3 * REM * delta_time)

//aphrodisiac & anaphrodisiac

/datum/reagent/drug/aphrodisiac
	name = "Crocin"
	description = "Naturally found in the crocus and gardenia flowers, this drug acts as a natural and safe aphrodisiac."
	taste_description = "strawberries"
	color = "#FFADFF"//PINK, rgb(255, 173, 255)

/datum/reagent/drug/aphrodisiac/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(!HAS_TRAIT(M, TRAIT_CROCIN_IMMUNITY) && M.sexcon)
		M.sexcon.adjust_arousal(2, 50)
	..()

/datum/reagent/drug/aphrodisiacplus
	name = "Hexacrocin"
	description = "Chemically condensed form of basic crocin. This aphrodisiac is extremely powerful and addictive in most animals.\
					Addiction withdrawals can cause brain damage and shortness of breath. Overdosage can lead to brain damage and a \
					permanent increase in libido (commonly referred to as 'bimbofication')."
	taste_description = "liquid desire"
	color = "#FF2BFF"//dark pink
	overdose_threshold = 20
	// TODO ADDICTION

/datum/reagent/drug/aphrodisiacplus/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(!HAS_TRAIT(M, TRAIT_CROCIN_IMMUNITY) && M.sexcon)
		M.sexcon.adjust_arousal(6, 80)
	..()


/datum/reagent/drug/aphrodisiacplus/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()

/datum/reagent/drug/anaphrodisiac
	name = "Camphor"
	description = "Naturally found in some species of evergreen trees, camphor is a waxy substance. When injested by most animals, it acts as an anaphrodisiac\
					, reducing libido and calming them. Non-habit forming and not addictive."
	taste_description = "dull bitterness"
	taste_mult = 2
	color = "#D9D9D9"//rgb(217, 217, 217)
	reagent_state = SOLID

/datum/reagent/drug/anaphrodisiac/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.sexcon)
		M.sexcon.adjust_arousal(-2)
	..()

/datum/reagent/drug/anaphrodisiacplus
	name = "Hexacamphor"
	description = "Chemically condensed camphor. Causes an extreme reduction in libido and a permanent one if overdosed. Non-addictive."
	taste_description = "tranquil celibacy"
	color = "#D9D9D9"//rgb(217, 217, 217)
	reagent_state = SOLID
	overdose_threshold = 20

/datum/reagent/drug/anaphrodisiacplus/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	if(M.sexcon)
		M.sexcon.adjust_arousal(-6)
	..()

/datum/reagent/drug/anaphrodisiacplus/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()

/// Enlarger stuff
/datum/reagent/drug/penis_enlarger
	name = "Incubus Draft"
	description = "A volatile collodial mixture derived from various masculine solutions that encourages a larger gentleman's package via a potent testosterone mix, formula derived from a collaboration from Fermichem  and Doctor Ronald Hyatt, who is well known for his phallus palace." //The toxic masculinity thing is a joke because I
	taste_description = "chinese dragon powder"
	taste_mult = 2
	color = "#888888" // This is greyish..?
	reagent_state = SOLID
	overdose_threshold = 20

/datum/reagent/drug/penis_enlarger/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()

/datum/reagent/drug/penis_enlarger/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()

/datum/reagent/drug/breast_enlarger
	name = "Succubus Milk"
	description = "A volatile collodial mixture derived from milk that encourages mammary production via a potent estrogen mix."
	color = "#E60584" // rgb: 96, 0, 255
	taste_description = "a milky ice cream like flavour"
	taste_mult = 2
	reagent_state = SOLID
	overdose_threshold = 20

/datum/reagent/drug/breast_enlarger/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()

/datum/reagent/drug/breast_enlarger/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()

/datum/reagent/drug/butt_enlarger
	name = "Denbu Tincture"
	description = "A mixture of natural vitamins and valentines plant extract, causing butt enlargement in humanoids."
	color = "#e8ff1b"
	taste_description = "butter with a sweet aftertaste" //pass me the butter, OM NOM
	taste_mult = 2
	reagent_state = SOLID
	overdose_threshold = 20

/datum/reagent/drug/butt_enlarger/on_mob_life(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()

/datum/reagent/drug/butt_enlarger/overdose_process(mob/living/carbon/M, delta_time, times_fired)
	// TODO
	..()
