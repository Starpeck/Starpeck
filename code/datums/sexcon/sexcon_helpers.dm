/mob/living
	var/can_do_sex = TRUE
	var/virginity = FALSE
	var/datum/sex_controller/sexcon

/mob/living/carbon/human/MouseDrop_T(mob/living/target, mob/living/user)
	if(!istype(target))
		return
	if(target != user)
		return
	if(!user.can_do_sex())
		to_chat(user, "<span class='warning'>I can't do this.</span>")
		return
	user.sexcon.start(src)

/mob/living/proc/can_do_sex()
	return TRUE

/mob/living/carbon/human/proc/make_sucking_noise()
	if(gender == FEMALE)
		playsound(src, pick('sound/misc/mat/girlmouth (1).ogg','sound/misc/mat/girlmouth (2).ogg'), 25, TRUE, ignore_walls = FALSE)
	else
		playsound(src, pick('sound/misc/mat/guymouth (1).ogg','sound/misc/mat/guymouth (2).ogg','sound/misc/mat/guymouth (3).ogg','sound/misc/mat/guymouth (4).ogg','sound/misc/mat/guymouth (5).ogg'), 35, TRUE, ignore_walls = FALSE)

/mob/living/carbon/human/proc/try_impregnate(mob/living/carbon/human/wife)
	var/obj/item/organ/genital/testicles/testes = getorganslot(ORGAN_SLOT_TESTICLES)
	if(!testes)
		return
	var/obj/item/organ/genital/vagina/vag = wife.getorganslot(ORGAN_SLOT_VAGINA)
	if(!vag)
		return
	if(prob(25))
		vag.be_impregnated(src)

/mob/living/carbon/human/proc/get_highest_grab_state_on(mob/living/carbon/human/victim)
	if(pulling != victim)
		return 0
	return grab_state

/proc/add_cum_floor(turf/location, fem = FALSE)
	if(!location|| !isturf(location))
		return
	if(fem)
		new /obj/effect/decal/cleanable/semen/femcum(location)
	else
		new /obj/effect/decal/cleanable/semen(location)
