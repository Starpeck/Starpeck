/datum/round_event_control/pirates
	name = "Space Pirates"
	typepath = /datum/round_event/pirates
	weight = 8
	max_occurrences = 1
	min_players = 10
	earliest_start = 30 MINUTES

	track = EVENT_TRACK_ROLESET
	tags = list(TAG_COMBAT, TAG_DESTRUCTIVE)

#define PIRATES_ROGUES "Rogues"
#define PIRATES_SILVERSCALES "Silverscales"
#define PIRATES_DUTCHMAN "Flying Dutchman"

/datum/round_event/pirates
	startWhen = 60 //2 minutes to answer
	var/datum/comm_message/threat
	var/payoff = 0
	var/payoff_min = 20000
	var/paid_off = FALSE
	var/pirate_type
	var/ship_template
	var/ship_name = "Space Privateers Association"
	var/shuttle_spawned = FALSE

/datum/round_event/pirates/setup()
	pirate_type = pick(PIRATES_ROGUES, PIRATES_SILVERSCALES, PIRATES_DUTCHMAN)
	switch(pirate_type)
		if(PIRATES_ROGUES)
			ship_name = pick(strings(PIRATE_NAMES_FILE, "rogue_names"))
		if(PIRATES_SILVERSCALES)
			ship_name = pick(strings(PIRATE_NAMES_FILE, "silverscale_names"))
		if(PIRATES_DUTCHMAN)
			ship_name = "Flying Dutchman"

/datum/round_event/pirates/announce(fake)
	priority_announce("Incoming subspace communication. Secure channel opened at all communication consoles.", "Incoming Message", SSstation.announcer.get_rand_report_sound())
	if(fake)
		return
	threat = new
	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	if(D)
		payoff = max(payoff_min, FLOOR(D.account_balance * 0.80, 1000))
	switch(pirate_type)
		if(PIRATES_ROGUES)
			ship_template = /datum/map_template/shuttle/pirate/default
			threat.title = "Sector protection offer"
			threat.content = "Hey, pal, this is the [ship_name]. Can't help but notice you're rocking a wild and crazy shuttle there with NO INSURANCE! Crazy. What if something happened to it, huh?! We've done a quick evaluation on your rates in this sector and we're offering [payoff] to cover for your shuttle in case of any disaster."
			threat.possible_answers = list("Purchase Insurance.","Reject Offer.")
		if(PIRATES_SILVERSCALES)
			ship_template = /datum/map_template/shuttle/pirate/silverscale
			threat.title = "Tribute to high society"
			threat.content = "This is the [ship_name]. The Silver Scales wish for some tribute from your plebeian lizards. [payoff] credits should do the trick."
			threat.possible_answers = list("We'll pay.","Tribute? Really? Go away.")
		if(PIRATES_DUTCHMAN)
			ship_template = /datum/map_template/shuttle/pirate/dutchman
			threat.title = "Business proposition"
			threat.content = "Ahoy! This be the [ship_name]. Cough up [payoff] credits or you'll walk the plank."
			threat.possible_answers = list("We'll pay.","We will not be extorted.")
	threat.answer_callback = CALLBACK(src,PROC_REF(answered))
	SScommunications.send_message(threat,unique = TRUE)

/datum/round_event/pirates/proc/answered()
	if(threat && threat.answered == 1)
		var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
		if(D)
			if(D.adjust_money(-payoff))
				priority_announce("Thanks for the credits, landlubbers.",sender_override = ship_name)
				paid_off = TRUE
				return
			else
				priority_announce("Trying to cheat us? You'll regret this!",sender_override = ship_name)
	if(!shuttle_spawned)
		spawn_shuttle()
	else
		priority_announce("Too late to beg for mercy!",sender_override = ship_name)

/datum/round_event/pirates/start()
	if(threat && !threat.answered)
		threat.possible_answers = list("Too late")
		threat.answered = 1
	if(!paid_off && !shuttle_spawned)
		spawn_shuttle()

/datum/round_event/pirates/proc/spawn_shuttle()
	shuttle_spawned = TRUE

	var/list/candidates = pollGhostCandidates("Do you wish to be considered for pirate crew?", ROLE_TRAITOR)
	shuffle_inplace(candidates)

	var/datum/map_template/shuttle/pirate/ship = new ship_template

	var/obj/docking_port/mobile/loaded_ship = SSshuttle.action_load(ship)
	if(!loaded_ship)
		CRASH("Loading pirate ship failed!")

	var/list/shuttle_coords = loaded_ship.return_coords()

	for(var/turf/A in block(locate(shuttle_coords[1], shuttle_coords[2], loaded_ship.z), locate(shuttle_coords[3], shuttle_coords[4], loaded_ship.z)))
		for(var/obj/effect/mob_spawn/human/pirate/spawner in A)
			if(candidates.len > 0)
				var/mob/M = candidates[1]
				spawner.create(M.ckey)
				candidates -= M
				announce_to_ghosts(M)
			else
				announce_to_ghosts(spawner)

	priority_announce("Unidentified armed ship detected near the station.")

//Shuttle equipment

/obj/machinery/shuttle_scrambler
	name = "Data Siphon"
	desc = "This heap of machinery steals credits and data from unprotected systems and locks down cargo shuttles."
	icon = 'icons/obj/machines/dominator.dmi'
	icon_state = "dominator"
	density = TRUE
	var/active = FALSE
	var/credits_stored = 0
	var/siphon_per_tick = 5

/obj/machinery/shuttle_scrambler/Initialize(mapload)
	. = ..()
	update_appearance()

/obj/machinery/shuttle_scrambler/process()
	if(active)
		if(is_station_level(src))
			var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
			if(D)
				var/siphoned = min(D.account_balance,siphon_per_tick)
				D.adjust_money(-siphoned)
				credits_stored += siphoned
			interrupt_research()
		else
			return
	else
		STOP_PROCESSING(SSobj,src)

/obj/machinery/shuttle_scrambler/proc/toggle_on(mob/user)
	SSshuttle.registerTradeBlockade(src)
	AddComponent(/datum/component/gps, "Nautical Signal")
	active = TRUE
	to_chat(user,SPAN_NOTICE("You toggle [src] [active ? "on":"off"]."))
	to_chat(user,SPAN_WARNING("The scrambling signal can be now tracked by GPS."))
	START_PROCESSING(SSobj,src)

/obj/machinery/shuttle_scrambler/interact(mob/user)
	if(!active)
		if(tgui_alert(user, "Turning the scrambler on will make the shuttle trackable by GPS. Are you sure you want to do it?", "Scrambler", list("Yes", "Cancel")) == "Cancel")
			return
		if(active || !user.canUseTopic(src, BE_CLOSE))
			return
		toggle_on(user)
		update_appearance()
		send_notification()
	else
		dump_loot(user)

//interrupt_research
/obj/machinery/shuttle_scrambler/proc/interrupt_research()
	for(var/obj/machinery/rnd/server/S in GLOB.machines)
		if(S.machine_stat & (NOPOWER|BROKEN))
			continue
		S.emp_act(1)
		new /obj/effect/temp_visual/emp(get_turf(S))

/obj/machinery/shuttle_scrambler/proc/dump_loot(mob/user)
	if(credits_stored) // Prevents spamming empty holochips
		new /obj/item/holochip(drop_location(), credits_stored)
		to_chat(user,SPAN_NOTICE("You retrieve the siphoned credits!"))
		credits_stored = 0
	else
		to_chat(user,SPAN_NOTICE("There's nothing to withdraw."))

/obj/machinery/shuttle_scrambler/proc/send_notification()
	priority_announce("Data theft signal detected, source registered on local gps units.")

/obj/machinery/shuttle_scrambler/proc/toggle_off(mob/user)
	SSshuttle.clearTradeBlockade(src)
	active = FALSE
	STOP_PROCESSING(SSobj,src)

/obj/machinery/shuttle_scrambler/update_icon_state()
	icon_state = active ? "dominator-Blue" : "dominator"
	return ..()

/obj/machinery/shuttle_scrambler/Destroy()
	toggle_off()
	return ..()

/obj/machinery/computer/shuttle/pirate
	name = "pirate shuttle console"
	shuttleId = "pirateship"
	icon_screen = "syndishuttle"
	icon_keyboard = "syndie_key"
	light_color = COLOR_SOFT_RED
	possible_destinations = "pirateship_away;pirateship_home;pirateship_custom"

/obj/machinery/computer/camera_advanced/shuttle_docker/syndicate/pirate
	name = "pirate shuttle navigation computer"
	desc = "Used to designate a precise transit location for the pirate shuttle."
	shuttleId = "pirateship"
	trait_lock = ZTRAIT_STATION
	shuttlePortId = "pirateship_custom"
	x_offset = 9
	y_offset = 0
	see_hidden = FALSE

/obj/docking_port/mobile/pirate
	name = "pirate shuttle"
	id = "pirateship"
	rechargeTime = 3 MINUTES

/obj/machinery/suit_storage_unit/pirate
	suit_type = /obj/item/clothing/suit/space
	helmet_type = /obj/item/clothing/head/helmet/space
	mask_type = /obj/item/clothing/mask/breath
	storage_type = /obj/item/tank/internals/oxygen

/obj/machinery/loot_locator
	name = "Booty Locator"
	desc = "This sophisticated machine scans the nearby space for items of value."
	icon = 'icons/obj/machines/research.dmi'
	icon_state = "tdoppler"
	density = TRUE
	var/cooldown = 300
	var/next_use = 0

/obj/machinery/loot_locator/interact(mob/user)
	if(world.time <= next_use)
		to_chat(user,SPAN_WARNING("[src] is recharging."))
		return
	next_use = world.time + cooldown
	var/atom/movable/AM = find_random_loot()
	if(!AM)
		say("No valuables located. Try again later.")
	else
		say("Located: [AM.name] at [get_area_name(AM)]")

/obj/machinery/loot_locator/proc/find_random_loot()
	if(!GLOB.exports_list.len)
		setupExports()
	var/list/possible_loot = list()
	for(var/datum/export/pirate/E in GLOB.exports_list)
		possible_loot += E
	var/datum/export/pirate/P
	var/atom/movable/AM
	while(!AM && possible_loot.len)
		P = pick_n_take(possible_loot)
		AM = P.find_loot()
	return AM

//Pad & Pad Terminal
/obj/machinery/piratepad
	name = "cargo hold pad"
	icon = 'icons/obj/telescience.dmi'
	icon_state = "lpad-idle-o"
	var/idle_state = "lpad-idle-o"
	var/warmup_state = "lpad-idle"
	var/sending_state = "lpad-beam"
	var/cargo_hold_id

/obj/machinery/piratepad/multitool_act(mob/living/user, obj/item/multitool/I)
	. = ..()
	if (istype(I))
		to_chat(user, SPAN_NOTICE("You register [src] in [I]s buffer."))
		I.buffer = src
		return TRUE

/obj/machinery/computer/piratepad_control
	name = "cargo hold control terminal"
	var/status_report = "Ready for delivery."
	var/obj/machinery/piratepad/pad
	var/warmup_time = 100
	var/sending = FALSE
	var/points = 0
	var/datum/export_report/total_report
	var/sending_timer
	var/cargo_hold_id

/obj/machinery/computer/piratepad_control/Initialize()
	..()
	return INITIALIZE_HINT_LATELOAD

/obj/machinery/computer/piratepad_control/multitool_act(mob/living/user, obj/item/multitool/I)
	. = ..()
	if (istype(I) && istype(I.buffer,/obj/machinery/piratepad))
		to_chat(user, SPAN_NOTICE("You link [src] with [I.buffer] in [I] buffer."))
		pad = I.buffer
		return TRUE

/obj/machinery/computer/piratepad_control/LateInitialize()
	. = ..()
	if(cargo_hold_id)
		for(var/obj/machinery/piratepad/P in GLOB.machines)
			if(P.cargo_hold_id == cargo_hold_id)
				pad = P
				return
	else
		pad = locate() in range(4,src)

/obj/machinery/computer/piratepad_control/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "CargoHoldTerminal", name)
		ui.open()

/obj/machinery/computer/piratepad_control/ui_data(mob/user)
	var/list/data = list()
	data["points"] = points
	data["pad"] = pad ? TRUE : FALSE
	data["sending"] = sending
	data["status_report"] = status_report
	return data

/obj/machinery/computer/piratepad_control/ui_act(action, params)
	. = ..()
	if(.)
		return
	if(!pad)
		return

	switch(action)
		if("recalc")
			recalc()
			. = TRUE
		if("send")
			start_sending()
			. = TRUE
		if("stop")
			stop_sending()
			. = TRUE

/obj/machinery/computer/piratepad_control/proc/recalc()
	if(sending)
		return

	status_report = "Predicted value: "
	var/value = 0
	var/datum/export_report/ex = new
	for(var/atom/movable/AM in get_turf(pad))
		if(AM == pad)
			continue
		export_item_and_contents(AM, apply_elastic = FALSE, dry_run = TRUE, external_report = ex)

	for(var/datum/export/E in ex.total_amount)
		status_report += E.total_printout(ex,notes = FALSE)
		status_report += " "
		value += ex.total_value[E]

	if(!value)
		status_report += "0"

/obj/machinery/computer/piratepad_control/proc/send()
	if(!sending)
		return

	var/datum/export_report/ex = new

	for(var/atom/movable/AM in get_turf(pad))
		if(AM == pad)
			continue
		export_item_and_contents(AM, EXPORT_PIRATE | EXPORT_CARGO | EXPORT_CONTRABAND | EXPORT_EMAG, apply_elastic = FALSE, delete_unsold = FALSE, external_report = ex)

	status_report = "Sold: "
	var/value = 0
	for(var/datum/export/E in ex.total_amount)
		var/export_text = E.total_printout(ex,notes = FALSE) //Don't want nanotrasen messages, makes no sense here.
		if(!export_text)
			continue

		status_report += export_text
		status_report += " "
		value += ex.total_value[E]

	if(!total_report)
		total_report = ex
	else
		total_report.exported_atoms += ex.exported_atoms
		for(var/datum/export/E in ex.total_amount)
			total_report.total_amount[E] += ex.total_amount[E]
			total_report.total_value[E] += ex.total_value[E]
		playsound(loc, 'sound/machines/wewewew.ogg', 70, TRUE)

	points += value

	if(!value)
		status_report += "Nothing"

	pad.visible_message(SPAN_NOTICE("[pad] activates!"))
	flick(pad.sending_state,pad)
	pad.icon_state = pad.idle_state
	sending = FALSE

/obj/machinery/computer/piratepad_control/proc/start_sending()
	if(sending)
		return
	sending = TRUE
	status_report = "Sending... "
	pad.visible_message(SPAN_NOTICE("[pad] starts charging up."))
	pad.icon_state = pad.warmup_state
	sending_timer = addtimer(CALLBACK(src,PROC_REF(send)),warmup_time, TIMER_STOPPABLE)

/obj/machinery/computer/piratepad_control/proc/stop_sending(custom_report)
	if(!sending)
		return
	sending = FALSE
	status_report = "Ready for delivery."
	if(custom_report)
		status_report = custom_report
	pad.icon_state = pad.idle_state
	deltimer(sending_timer)

//Attempts to find the thing on station
/datum/export/pirate/proc/find_loot()
	return

/datum/export/pirate/ransom
	cost = 3000
	unit_name = "hostage"
	export_types = list(/mob/living/carbon/human)

/datum/export/pirate/ransom/find_loot()
	var/list/head_minds = SSjob.get_living_heads()
	var/list/head_mobs = list()
	for(var/datum/mind/M in head_minds)
		head_mobs += M.current
	if(head_mobs.len)
		return pick(head_mobs)

/datum/export/pirate/ransom/get_cost(atom/movable/AM)
	var/mob/living/carbon/human/H = AM
	if(H.stat != CONSCIOUS || !H.mind) //mint condition only
		return 0
	else if("pirate" in H.faction) //can't ransom your fellow pirates to CentCom!
		return 0
	else if(H.mind.assigned_role.departments_bitflags & DEPARTMENT_BITFLAG_COMMAND)
		return 3000
	else
		return 1000

/datum/export/pirate/parrot
	cost = 2000
	unit_name = "alive parrot"
	export_types = list(/mob/living/simple_animal/parrot)

/datum/export/pirate/parrot/find_loot()
	for(var/mob/living/simple_animal/parrot/P in GLOB.alive_mob_list)
		var/turf/T = get_turf(P)
		if(T && is_station_level(T))
			return P

/datum/export/pirate/cash
	cost = 1
	unit_name = "bills"
	export_types = list(/obj/item/stack/spacecash)

/datum/export/pirate/cash/get_amount(obj/O)
	var/obj/item/stack/spacecash/C = O
	return ..() * C.amount * C.value

/datum/export/pirate/holochip
	cost = 1
	unit_name = "holochip"
	export_types = list(/obj/item/holochip)

/datum/export/pirate/holochip/get_cost(atom/movable/AM)
	var/obj/item/holochip/H = AM
	return H.credits
