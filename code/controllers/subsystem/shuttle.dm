#define MAX_TRANSIT_REQUEST_RETRIES 10

SUBSYSTEM_DEF(shuttle)
	name = "Shuttle"
	wait = 1 SECONDS
	init_order = INIT_ORDER_SHUTTLE
	flags = SS_KEEP_TIMING
	runlevels = RUNLEVEL_SETUP | RUNLEVEL_GAME

	var/list/mobile = list()
	var/list/stationary = list()
	var/list/beacons = list()
	var/list/transit = list()

	//Now it only for ID generation
	var/list/assoc_mobile = list()
	var/list/assoc_stationary = list()

	var/list/transit_requesters = list()
	var/list/transit_request_failures = list()

		//emergency shuttle stuff
	var/obj/docking_port/mobile/emergency/emergency
	var/obj/docking_port/mobile/arrivals/arrivals
	var/obj/docking_port/mobile/emergency/backup/backup_shuttle
	var/emergency_call_time = 6000 //time taken for emergency shuttle to reach the station when called (in deciseconds)
	var/emergency_dock_time = 1800 //time taken for emergency shuttle to leave again once it has docked (in deciseconds)
	var/emergency_escape_time = 1200 //time taken for emergency shuttle to reach a safe distance after leaving station (in deciseconds)
	var/area/emergency_last_call_location
	var/emergency_call_amount = 0 //how many times the escape shuttle was called
	var/emergency_no_escape
	var/emergency_no_recall = FALSE
	var/admin_emergency_no_recall = FALSE
	var/last_mode = SHUTTLE_IDLE
	var/last_call_time = 6000
	var/list/hostile_environments = list() //Things blocking escape shuttle from leaving
	var/list/trade_blockade = list() //Things blocking cargo from leaving.
	var/supply_blocked = FALSE

		//supply shuttle stuff
	var/obj/docking_port/mobile/supply/supply
	var/ordernum = 1 //order number given to next order
	var/points = 5000 //number of trade-points we have
	var/centcom_message = "" //Remarks from CentCom on how well you checked the last order.
	var/list/discoveredPlants = list() //Typepaths for unusual plants we've already sent CentCom, associated with their potencies

	/// All of the possible supply packs that can be purchased by cargo
	var/list/supply_packs = list()

	/// Queued supplies to be purchased for the chef
	var/list/chef_groceries = list()

	/// Queued supply packs to be purchased
	var/list/shoppinglist = list()

	/// Wishlist items made by crew for cargo to purchase at their leisure
	var/list/requestlist = list()

	/// A listing of previously delivered supply packs
	var/list/orderhistory = list()

	/// A list of job accesses that are able to purchase any shuttles
	var/list/has_purchase_shuttle_access

	var/list/hidden_shuttle_turfs = list() //all turfs hidden from navigation computers associated with a list containing the image hiding them and the type of the turf they are pretending to be
	var/list/hidden_shuttle_turf_images = list() //only the images from the above list

	var/datum/round_event/shuttle_loan/shuttle_loan

	///If the event happens where the crew can purchase shuttle insurance, catastrophe can't run.
	var/shuttle_insurance = FALSE
	var/shuttle_purchased = SHUTTLEPURCHASE_PURCHASABLE //If the station has purchased a replacement escape shuttle this round
	var/list/shuttle_purchase_requirements_met = list() //For keeping track of ingame events that would unlock new shuttles, such as defeating a boss or discovering a secret item

	var/lockdown = FALSE //disallow transit after nuke goes off

	var/datum/map_template/shuttle/selected

	var/obj/docking_port/mobile/existing_shuttle

	var/obj/docking_port/mobile/preview_shuttle
	var/datum/map_template/shuttle/preview_template

	/// The mapzone that the preview shuttle is loaded into
	var/datum/map_zone/preview_mapzone

	var/shuttle_loading

	/// List of all sold shuttles for consoles to buy them
	var/list/sold_shuttles = list()
	/// Assoc list of "[dock_id]-[shuttle_types]" to a list of possible sold shuttles for those
	var/list/sold_shuttles_cache = list()

/datum/controller/subsystem/shuttle/Initialize(timeofday)
	ordernum = rand(1, 9000)

	var/list/pack_processing = subtypesof(/datum/supply_pack)
	while(length(pack_processing))
		var/datum/supply_pack/pack = pack_processing[length(pack_processing)]
		pack_processing.len--
		if(ispath(pack, /datum/supply_pack))
			pack = new pack

		var/list/generated_packs = pack.generate_supply_packs()
		if(generated_packs)
			pack_processing += generated_packs
			continue

		if(!pack.contains)
			continue

		supply_packs[pack.id] = pack

	initial_load()
	has_purchase_shuttle_access = init_has_purchase_shuttle_access()

	if(!arrivals)
		WARNING("No /obj/docking_port/mobile/arrivals placed on the map!")
	if(!emergency)
		WARNING("No /obj/docking_port/mobile/emergency placed on the map!")
	if(!backup_shuttle)
		WARNING("No /obj/docking_port/mobile/emergency/backup placed on the map!")
	if(!supply)
		WARNING("No /obj/docking_port/mobile/supply placed on the map!")

	init_sold_shuttles()
	return ..()

/datum/controller/subsystem/shuttle/proc/init_sold_shuttles()
	for(var/type in subtypesof(/datum/sold_shuttle))
		var/datum/sold_shuttle/sold_shuttle = type
		if(initial(sold_shuttle.shuttle_id))
			sold_shuttles += new sold_shuttle()

/datum/controller/subsystem/shuttle/proc/get_sold_shuttles_cache(dock_id, shuttle_types)
	var/cache_key = "[dock_id]-[shuttle_types]"
	if(!sold_shuttles_cache[cache_key])
		var/list/new_cache_list = list()
		for(var/i in sold_shuttles)
			var/datum/sold_shuttle/sold_shuttle = i
			if(!sold_shuttle.allowed_docks[dock_id])
				continue
			if(shuttle_types & sold_shuttle.shuttle_type)
				new_cache_list += sold_shuttle
		sold_shuttles_cache[cache_key] = new_cache_list
	return sold_shuttles_cache[cache_key]

/datum/controller/subsystem/shuttle/proc/initial_load()
	for(var/s in stationary)
		var/obj/docking_port/stationary/S = s
		S.load_roundstart()
		CHECK_TICK

/datum/controller/subsystem/shuttle/fire()
	for(var/thing in mobile)
		if(!thing)
			mobile.Remove(thing)
			continue
		var/obj/docking_port/mobile/P = thing
		P.check()
	for(var/thing in transit)
		var/obj/docking_port/stationary/transit/T = thing
		if(!T.owner)
			qdel(T, force=TRUE)
		// This next one removes transit docks/zones that aren't
		// immediately being used. This will mean that the zone creation
		// code will be running a lot.
		var/obj/docking_port/mobile/owner = T.owner
		if(owner)
			var/idle = owner.mode == SHUTTLE_IDLE
			var/not_centcom_evac = owner.launch_status == NOLAUNCH
			var/not_in_use = (!T.get_docked())
			if(idle && not_centcom_evac && not_in_use)
				qdel(T, force=TRUE)
	CheckAutoEvac()

	while(transit_requesters.len)
		var/requester = popleft(transit_requesters)
		var/success = generate_transit_dock(requester)
		if(!success) // BACK OF THE QUEUE
			transit_request_failures[requester]++
			if(transit_request_failures[requester] < MAX_TRANSIT_REQUEST_RETRIES)
				transit_requesters += requester
			else
				var/obj/docking_port/mobile/M = requester
				M.transit_failure()
		if(MC_TICK_CHECK)
			break

/datum/controller/subsystem/shuttle/proc/CheckAutoEvac()
	if(emergency_no_escape || admin_emergency_no_recall || emergency_no_recall || !emergency || !SSticker.HasRoundStarted())
		return

	var/threshold = CONFIG_GET(number/emergency_shuttle_autocall_threshold)
	if(!threshold)
		return

	var/alive = 0
	for(var/I in GLOB.player_list)
		var/mob/M = I
		if(M.stat != DEAD)
			++alive

	var/total = GLOB.joined_player_list.len
	if(total <= 0)
		return //no players no autoevac

	if(alive / total <= threshold)
		var/msg = "Automatically dispatching emergency shuttle due to crew death."
		message_admins(msg)
		log_shuttle("[msg] Alive: [alive], Roundstart: [total], Threshold: [threshold]")
		emergency_no_recall = TRUE
		priority_announce("Catastrophic casualties detected: crisis shuttle protocols activated - jamming recall signals across all frequencies.")
		if(emergency.timeLeft(1) > emergency_call_time * 0.4)
			emergency.request(null, set_coefficient = 0.4)

/datum/controller/subsystem/shuttle/proc/block_recall(lockout_timer)
	if(admin_emergency_no_recall)
		priority_announce("Error!", "Emergency Shuttle Uplink Alert", 'sound/misc/announce_dig.ogg')
		addtimer(CALLBACK(src, PROC_REF(unblock_recall)), lockout_timer)
		return
	emergency_no_recall = TRUE
	addtimer(CALLBACK(src, PROC_REF(unblock_recall)), lockout_timer)

/datum/controller/subsystem/shuttle/proc/unblock_recall()
	if(admin_emergency_no_recall)
		priority_announce("Error!", "Emergency Shuttle Uplink Alert", 'sound/misc/announce_dig.ogg')
		return
	emergency_no_recall = FALSE

/datum/controller/subsystem/shuttle/proc/getShuttle(id)
	for(var/obj/docking_port/mobile/M in mobile)
		if(M.id == id)
			return M
	WARNING("couldn't find shuttle with id: [id]")

/datum/controller/subsystem/shuttle/proc/getDock(id)
	for(var/obj/docking_port/stationary/S in stationary)
		if(S.id == id)
			return S
	WARNING("couldn't find dock with id: [id]")

/// Check if we can call the evac shuttle.
/// Returns TRUE if we can. Otherwise, returns a string detailing the problem.
/datum/controller/subsystem/shuttle/proc/canEvac(mob/user)
	var/srd = CONFIG_GET(number/shuttle_refuel_delay)
	if(world.time - SSticker.round_start_time < srd)
		return "The emergency shuttle is refueling. Please wait [DisplayTimeText(srd - (world.time - SSticker.round_start_time))] before attempting to call."

	switch(emergency.mode)
		if(SHUTTLE_RECALL)
			return "The emergency shuttle may not be called while returning to CentCom."
		if(SHUTTLE_CALL)
			return "The emergency shuttle is already on its way."
		if(SHUTTLE_DOCKED)
			return "The emergency shuttle is already here."
		if(SHUTTLE_IGNITING)
			return "The emergency shuttle is firing its engines to leave."
		if(SHUTTLE_ESCAPE)
			return "The emergency shuttle is moving away to a safe distance."
		if(SHUTTLE_STRANDED)
			return "The emergency shuttle has been disabled by CentCom."

	return TRUE

/datum/controller/subsystem/shuttle/proc/requestEvac(mob/user, call_reason)
	if(!emergency)
		WARNING("requestEvac(): There is no emergency shuttle, but the \
			shuttle was called. Using the backup shuttle instead.")
		if(!backup_shuttle)
			CRASH("requestEvac(): There is no emergency shuttle, \
			or backup shuttle! The game will be unresolvable. This is \
			possibly a mapping error, more likely a bug with the shuttle \
			manipulation system, or badminry. It is possible to manually \
			resolve this problem by loading an emergency shuttle template \
			manually, and then calling register() on the mobile docking port. \
			Good luck.")
		emergency = backup_shuttle

	var/can_evac_or_fail_reason = SSshuttle.canEvac(user)
	if(can_evac_or_fail_reason != TRUE)
		to_chat(user, SPAN_ALERT("[can_evac_or_fail_reason]"))
		return

	call_reason = trim(html_encode(call_reason))

	if(length(call_reason) < CALL_SHUTTLE_REASON_LENGTH && seclevel2num(get_security_level()) > SEC_LEVEL_GREEN)
		to_chat(user, SPAN_ALERT("You must provide a reason."))
		return

	var/area/signal_origin = get_area(user)
	var/emergency_reason = "\nNature of emergency:\n\n[call_reason]"
	var/security_num = seclevel2num(get_security_level())
	switch(security_num)
		if(SEC_LEVEL_RED,SEC_LEVEL_DELTA)
			emergency.request(null, signal_origin, html_decode(emergency_reason), 1) //There is a serious threat we gotta move no time to give them five minutes.
		else
			emergency.request(null, signal_origin, html_decode(emergency_reason), 0)

	var/datum/radio_frequency/frequency = SSradio.return_frequency(FREQ_STATUS_DISPLAYS)

	if(!frequency)
		return

	var/datum/signal/status_signal = new(list("command" = "update")) // Start processing shuttle-mode displays to display the timer
	frequency.post_signal(src, status_signal)

	var/area/A = get_area(user)

	log_shuttle("[key_name(user)] has called the emergency shuttle.")
	deadchat_broadcast(" has called the shuttle at [SPAN_NAME("[A.name]")].", SPAN_NAME("[user.real_name]"), user, message_type=DEADCHAT_ANNOUNCEMENT)
	if(call_reason)
		SSblackbox.record_feedback("text", "shuttle_reason", 1, "[call_reason]")
		log_shuttle("Shuttle call reason: [call_reason]")
		SSticker.emergency_reason = call_reason
	message_admins("[ADMIN_LOOKUPFLW(user)] has called the shuttle. (<A HREF='?_src_=holder;[HrefToken()];trigger_centcom_recall=1'>TRIGGER CENTCOM RECALL</A>)")

/datum/controller/subsystem/shuttle/proc/centcom_recall(old_timer, admiral_message)
	if(emergency.mode != SHUTTLE_CALL || emergency.timer != old_timer)
		return
	emergency.cancel()

	if(!admiral_message)
		admiral_message = pick(GLOB.admiral_messages)
	var/intercepttext = "<font size = 3><b>Nanotrasen Update</b>: Request For Shuttle.</font><hr>\
						To whom it may concern:<br><br>\
						We have taken note of the situation upon [station_name()] and have come to the \
						conclusion that it does not warrant the abandonment of the station.<br>\
						If you do not agree with our opinion we suggest that you open a direct \
						line with us and explain the nature of your crisis.<br><br>\
						<i>This message has been automatically generated based upon readings from long \
						range diagnostic tools. To assure the quality of your request every finalized report \
						is reviewed by an on-call rear admiral.<br>\
						<b>Rear Admiral's Notes:</b> \
						[admiral_message]"
	print_command_report(intercepttext, announce = TRUE)

// Called when an emergency shuttle mobile docking port is
// destroyed, which will only happen with admin intervention
/datum/controller/subsystem/shuttle/proc/emergencyDeregister()
	// When a new emergency shuttle is created, it will override the
	// backup shuttle.
	src.emergency = src.backup_shuttle

/datum/controller/subsystem/shuttle/proc/cancelEvac(mob/user)
	if(canRecall())
		emergency.cancel(get_area(user))
		log_shuttle("[key_name(user)] has recalled the shuttle.")
		message_admins("[ADMIN_LOOKUPFLW(user)] has recalled the shuttle.")
		deadchat_broadcast(" has recalled the shuttle from [SPAN_NAME("[get_area_name(user, TRUE)]")].", SPAN_NAME("[user.real_name]"), user, message_type=DEADCHAT_ANNOUNCEMENT)
		return 1

/datum/controller/subsystem/shuttle/proc/canRecall()
	if(!emergency || emergency.mode != SHUTTLE_CALL || admin_emergency_no_recall || emergency_no_recall)
		return
	var/security_num = seclevel2num(get_security_level())
	switch(security_num)
		if(SEC_LEVEL_GREEN)
			if(emergency.timeLeft(1) < emergency_call_time)
				return
		if(SEC_LEVEL_BLUE)
			if(emergency.timeLeft(1) < emergency_call_time * 0.5)
				return
		else
			if(emergency.timeLeft(1) < emergency_call_time * 0.25)
				return
	return 1

/datum/controller/subsystem/shuttle/proc/autoEvac()
	if (!SSticker.IsRoundInProgress())
		return

	var/callShuttle = TRUE

	for(var/thing in GLOB.shuttle_caller_list)
		if(isAI(thing))
			var/mob/living/silicon/ai/AI = thing
			if(AI.deployed_shell && !AI.deployed_shell.client)
				continue
			if(AI.stat || !AI.client)
				continue
		else if(istype(thing, /obj/machinery/computer/communications))
			var/obj/machinery/computer/communications/C = thing
			if(C.machine_stat & BROKEN)
				continue

		var/turf/T = get_turf(thing)
		if(T && is_station_level(T))
			callShuttle = FALSE
			break

	if(callShuttle)
		if(EMERGENCY_IDLE_OR_RECALLED)
			emergency.request(null, set_coefficient = 2.5)
			log_shuttle("There is no means of calling the emergency shuttle anymore. Shuttle automatically called.")
			message_admins("All the communications consoles were destroyed and all AIs are inactive. Shuttle called.")

/datum/controller/subsystem/shuttle/proc/registerHostileEnvironment(datum/bad)
	hostile_environments[bad] = TRUE
	checkHostileEnvironment()

/datum/controller/subsystem/shuttle/proc/clearHostileEnvironment(datum/bad)
	hostile_environments -= bad
	checkHostileEnvironment()


/datum/controller/subsystem/shuttle/proc/registerTradeBlockade(datum/bad)
	trade_blockade[bad] = TRUE
	checkTradeBlockade()

/datum/controller/subsystem/shuttle/proc/clearTradeBlockade(datum/bad)
	trade_blockade -= bad
	checkTradeBlockade()


/datum/controller/subsystem/shuttle/proc/checkTradeBlockade()
	for(var/datum/d in trade_blockade)
		if(!istype(d) || QDELETED(d))
			trade_blockade -= d
	supply_blocked = trade_blockade.len

	if(supply_blocked && (supply.mode == SHUTTLE_IGNITING))
		supply.mode = SHUTTLE_STRANDED
		supply.timer = null
		//Make all cargo consoles speak up
	if(!supply_blocked && (supply.mode == SHUTTLE_STRANDED))
		supply.mode = SHUTTLE_DOCKED
		//Make all cargo consoles speak up

/datum/controller/subsystem/shuttle/proc/checkHostileEnvironment()
	for(var/datum/d in hostile_environments)
		if(!istype(d) || QDELETED(d))
			hostile_environments -= d
	emergency_no_escape = hostile_environments.len

	if(emergency_no_escape && (emergency.mode == SHUTTLE_IGNITING))
		emergency.mode = SHUTTLE_STRANDED
		emergency.timer = null
		emergency.sound_played = FALSE
		priority_announce("Hostile environment detected. \
			Departure has been postponed indefinitely pending \
			conflict resolution.", null, 'sound/misc/notice1.ogg', "Priority")
	if(!emergency_no_escape && (emergency.mode == SHUTTLE_STRANDED))
		emergency.mode = SHUTTLE_DOCKED
		emergency.setTimer(emergency_dock_time)
		priority_announce("Hostile environment resolved. \
			You have 3 minutes to board the Emergency Shuttle.",
			null, ANNOUNCER_SHUTTLEDOCK, "Priority")

//try to move/request to dockHome if possible, otherwise dockAway. Mainly used for admin buttons
/datum/controller/subsystem/shuttle/proc/toggleShuttle(shuttleId, dockHome, dockAway, timed)
	var/obj/docking_port/mobile/M = getShuttle(shuttleId)
	if(!M)
		return 1
	var/obj/docking_port/stationary/dockedAt = M.get_docked()
	var/destination = dockHome
	if(dockedAt && dockedAt.id == dockHome)
		destination = dockAway
	if(timed)
		if(M.request(getDock(destination)))
			return 2
	else
		if(M.initiate_docking(getDock(destination)) != DOCKING_SUCCESS)
			return 2
	return 0 //dock successful


/datum/controller/subsystem/shuttle/proc/moveShuttle(shuttleId, dockId, timed)
	var/obj/docking_port/mobile/M = getShuttle(shuttleId)
	var/obj/docking_port/stationary/D = getDock(dockId)

	if(!M)
		return 1
	if(timed)
		if(M.request(D))
			return 2
	else
		if(M.initiate_docking(D) != DOCKING_SUCCESS)
			return 2
	return 0 //dock successful

/datum/controller/subsystem/shuttle/proc/request_transit_dock(obj/docking_port/mobile/M)
	if(!istype(M))
		CRASH("[M] is not a mobile docking port")

	if(M.assigned_transit)
		return
	else
		if(!(M in transit_requesters))
			transit_requesters += M

/datum/controller/subsystem/shuttle/proc/generate_transit_dock(obj/docking_port/mobile/M)
	// First, determine the size of the needed zone
	// Because of shuttle rotation, the "width" of the shuttle is not
	// always x.
	var/travel_dir = M.preferred_direction
	// Remember, the direction is the direction we appear to be
	// coming from
	var/dock_angle = dir2angle(M.preferred_direction) + dir2angle(M.port_direction) + 180
	var/dock_dir = angle2dir(dock_angle)

	var/transit_width = SHUTTLE_TRANSIT_BORDER * 2
	var/transit_height = SHUTTLE_TRANSIT_BORDER * 2

	// Shuttles travelling on their side have their dimensions swapped
	// from our perspective
	switch(dock_dir)
		if(NORTH, SOUTH)
			transit_width += M.width
			transit_height += M.height
		if(EAST, WEST)
			transit_width += M.height
			transit_height += M.width

/*
	to_chat(world, "The attempted transit dock will be [transit_width] width, and \)
		[transit_height] in height. The travel dir is [travel_dir]."
*/

	var/transit_path = /turf/open/space/transit
	switch(travel_dir)
		if(NORTH)
			transit_path = /turf/open/space/transit/north
		if(SOUTH)
			transit_path = /turf/open/space/transit/south
		if(EAST)
			transit_path = /turf/open/space/transit/east
		if(WEST)
			transit_path = /turf/open/space/transit/west

	var/transit_name = "Transit Map Zone"
	var/datum/map_zone/mapzone = SSmapping.create_map_zone(transit_name)
	var/datum/virtual_level/vlevel = SSmapping.create_virtual_level(transit_name, list(ZTRAIT_RESERVED = TRUE), mapzone, transit_width, transit_height, ALLOCATION_FREE)

	vlevel.reserve_margin(TRANSIT_SIZE_BORDER)

	mapzone.parallax_movedir = travel_dir

	var/area/shuttle/transit/transit_area = new()
	transit_area.parallax_movedir = travel_dir

	vlevel.fill_in(transit_path, transit_area)

	var/turf/bottomleft = locate(
		vlevel.low_x,
		vlevel.low_y,
		vlevel.z_value
		)

	// Then create a transit docking port in the middle
	var/coords = M.return_coords(0, 0, dock_dir)
	/*  0------2
	*   |      |
	*   |      |
	*   |  x   |
	*   3------1
	*/

	var/x0 = coords[1]
	var/y0 = coords[2]
	var/x1 = coords[3]
	var/y1 = coords[4]
	// Then we want the point closest to -infinity,-infinity
	var/x2 = min(x0, x1)
	var/y2 = min(y0, y1)

	// Then invert the numbers
	var/transit_x = bottomleft.x + SHUTTLE_TRANSIT_BORDER + abs(x2)
	var/transit_y = bottomleft.y + SHUTTLE_TRANSIT_BORDER + abs(y2)

	var/turf/midpoint = locate(transit_x, transit_y, bottomleft.z)
	if(!midpoint)
		return FALSE

	var/obj/docking_port/stationary/transit/new_transit_dock = new(midpoint)
	new_transit_dock.reserved_mapzone = mapzone
	new_transit_dock.name = "Transit for [M.id]/[M.name]"
	new_transit_dock.owner = M
	new_transit_dock.assigned_area = transit_area
	new_transit_dock.transit_direction = travel_dir

	// Add 180, because ports point inwards, rather than outwards
	new_transit_dock.setDir(angle2dir(dock_angle))

	M.assigned_transit = new_transit_dock
	vlevel.add_transit_instance(new_transit_dock)
	return new_transit_dock

/datum/controller/subsystem/shuttle/Recover()
	if (istype(SSshuttle.mobile))
		mobile = SSshuttle.mobile
	if (istype(SSshuttle.stationary))
		stationary = SSshuttle.stationary
	if (istype(SSshuttle.transit))
		transit = SSshuttle.transit
	if (istype(SSshuttle.transit_requesters))
		transit_requesters = SSshuttle.transit_requesters
	if (istype(SSshuttle.transit_request_failures))
		transit_request_failures = SSshuttle.transit_request_failures

	if (istype(SSshuttle.emergency))
		emergency = SSshuttle.emergency
	if (istype(SSshuttle.arrivals))
		arrivals = SSshuttle.arrivals
	if (istype(SSshuttle.backup_shuttle))
		backup_shuttle = SSshuttle.backup_shuttle

	if (istype(SSshuttle.emergency_last_call_location))
		emergency_last_call_location = SSshuttle.emergency_last_call_location

	if (istype(SSshuttle.hostile_environments))
		hostile_environments = SSshuttle.hostile_environments

	if (istype(SSshuttle.supply))
		supply = SSshuttle.supply

	if (istype(SSshuttle.discoveredPlants))
		discoveredPlants = SSshuttle.discoveredPlants

	if (istype(SSshuttle.shoppinglist))
		shoppinglist = SSshuttle.shoppinglist
	if (istype(SSshuttle.requestlist))
		requestlist = SSshuttle.requestlist
	if (istype(SSshuttle.orderhistory))
		orderhistory = SSshuttle.orderhistory

	if (istype(SSshuttle.shuttle_loan))
		shuttle_loan = SSshuttle.shuttle_loan

	if (istype(SSshuttle.shuttle_purchase_requirements_met))
		shuttle_purchase_requirements_met = SSshuttle.shuttle_purchase_requirements_met

	var/datum/bank_account/D = SSeconomy.get_dep_account(ACCOUNT_CAR)
	centcom_message = SSshuttle.centcom_message
	ordernum = SSshuttle.ordernum
	points = D.account_balance
	emergency_no_escape = SSshuttle.emergency_no_escape
	emergency_call_amount = SSshuttle.emergency_call_amount
	shuttle_purchased = SSshuttle.shuttle_purchased
	lockdown = SSshuttle.lockdown

	selected = SSshuttle.selected

	existing_shuttle = SSshuttle.existing_shuttle

	preview_shuttle = SSshuttle.preview_shuttle
	preview_template = SSshuttle.preview_template

	preview_mapzone = SSshuttle.preview_mapzone

/datum/controller/subsystem/shuttle/proc/is_in_shuttle_bounds(atom/A)
	var/area/current = get_area(A)
	if(istype(current, /area/shuttle) && !istype(current, /area/shuttle/transit))
		return TRUE
	for(var/obj/docking_port/mobile/M in mobile)
		if(M.is_in_shuttle_bounds(A))
			return TRUE

/datum/controller/subsystem/shuttle/proc/get_containing_shuttle(atom/A)
	var/list/mobile_cache = mobile
	for(var/i in 1 to mobile_cache.len)
		var/obj/docking_port/port = mobile_cache[i]
		if(port.is_in_shuttle_bounds(A))
			return port

/datum/controller/subsystem/shuttle/proc/get_containing_dock(atom/A)
	. = list()
	var/list/stationary_cache = stationary
	for(var/i in 1 to stationary_cache.len)
		var/obj/docking_port/port = stationary_cache[i]
		if(port.is_in_shuttle_bounds(A))
			. += port

/datum/controller/subsystem/shuttle/proc/get_dock_overlap(x0, y0, x1, y1, z)
	. = list()
	var/list/stationary_cache = stationary
	for(var/i in 1 to stationary_cache.len)
		var/obj/docking_port/port = stationary_cache[i]
		if(!port || port.z != z)
			continue
		var/list/bounds = port.return_coords()
		var/list/overlap = get_overlap(x0, y0, x1, y1, bounds[1], bounds[2], bounds[3], bounds[4])
		var/list/xs = overlap[1]
		var/list/ys = overlap[2]
		if(xs.len && ys.len)
			.[port] = overlap

/datum/controller/subsystem/shuttle/proc/update_hidden_docking_ports(list/remove_turfs, list/add_turfs)
	var/list/remove_images = list()
	var/list/add_images = list()

	if(remove_turfs)
		for(var/T in remove_turfs)
			var/list/L = hidden_shuttle_turfs[T]
			if(L)
				remove_images += L[1]
		hidden_shuttle_turfs -= remove_turfs

	if(add_turfs)
		for(var/V in add_turfs)
			var/turf/T = V
			var/image/I
			if(remove_images.len)
				//we can just reuse any images we are about to delete instead of making new ones
				I = remove_images[1]
				remove_images.Cut(1, 2)
				I.loc = T
			else
				I = image(loc = T)
				add_images += I
			I.appearance = T.appearance
			I.override = TRUE
			hidden_shuttle_turfs[T] = list(I, T.type)

	hidden_shuttle_turf_images -= remove_images
	hidden_shuttle_turf_images += add_images

	for(var/V in GLOB.navigation_computers)
		var/obj/machinery/computer/camera_advanced/shuttle_docker/C = V
		C.update_hidden_docking_ports(remove_images, add_images)

	QDEL_LIST(remove_images)


/datum/controller/subsystem/shuttle/proc/action_load(datum/map_template/shuttle/loading_template, obj/docking_port/stationary/destination_port, replace = FALSE)
	// Check for an existing preview
	if(preview_shuttle && (loading_template != preview_template))
		preview_shuttle.jumpToNullSpace()
		preview_shuttle = null
		preview_template = null
		QDEL_NULL(preview_mapzone)

	if(!preview_shuttle)
		load_template(loading_template)
		preview_template = loading_template

	// get the existing shuttle information, if any
	var/timer = 0
	var/mode = SHUTTLE_IDLE
	var/generated_transit
	var/obj/docking_port/stationary/D

	if(istype(destination_port))
		D = destination_port
	else if(existing_shuttle && replace)
		timer = existing_shuttle.timer
		mode = existing_shuttle.mode
		D = existing_shuttle.get_docked()

	if(!D)
		D = generate_transit_dock(preview_shuttle)
		generated_transit = TRUE

	if(!D)
		CRASH("No dock found for preview shuttle ([preview_template.name]), aborting.")

	var/result = preview_shuttle.canDock(D)
	// truthy value means that it cannot dock for some reason
	// but we can ignore the someone else docked error because we'll
	// be moving into their place shortly
	if((result != SHUTTLE_CAN_DOCK) && (result != SHUTTLE_SOMEONE_ELSE_DOCKED))
		WARNING("Template shuttle [preview_shuttle] cannot dock at [D] ([result]).")
		return

	if(existing_shuttle && replace)
		existing_shuttle.jumpToNullSpace()

	var/list/force_memory = preview_shuttle.movement_force
	preview_shuttle.movement_force = list("KNOCKDOWN" = 0, "THROW" = 0)
	preview_shuttle.mode = SHUTTLE_PREARRIVAL//No idle shuttle moving. Transit dock get removed if shuttle moves too long.
	if(generated_transit)
		preview_shuttle.destination = "overmap"
		preview_shuttle.enterTransit()
	else
		preview_shuttle.initiate_docking(D)
		// Shuttle state involves a mode and a timer based on world.time, so
		// plugging the existing shuttles old values in works fine.
		preview_shuttle.timer = timer
		preview_shuttle.mode = mode

	preview_shuttle.movement_force = force_memory

	. = preview_shuttle


	preview_shuttle.register(replace)

	// TODO indicate to the user that success happened, rather than just
	// blanking the modification tab
	preview_shuttle = null
	preview_template = null
	existing_shuttle = null
	selected = null

	preview_mapzone.clear_reservation() //Is this safe? Docking CHECK_TICK's and this should happen on the same thread, so theoritically this wouldn't happen until docking has been finished? Maybe?
	QDEL_NULL(preview_mapzone)

/datum/controller/subsystem/shuttle/proc/load_template(datum/map_template/shuttle/S)
	. = FALSE
	// Load shuttle template to a fresh block reservation.
	var/width = S.width
	var/height = S.height

	var/mapzone_name = "Preview Shuttle Zone"
	preview_mapzone = SSmapping.create_map_zone(mapzone_name)
	var/datum/virtual_level/vlevel = SSmapping.create_virtual_level(mapzone_name, list(ZTRAIT_RESERVED = TRUE), preview_mapzone, width, height, ALLOCATION_FREE)

	if(!preview_mapzone) ///Shouldn't ever happen
		CRASH("failed to reserve an area for shuttle template loading")

	vlevel.fill_in(/turf/open/space/transit/south)

	var/turf/BL = locate(vlevel.low_x, vlevel.low_y, vlevel.z_value)
	S.load(BL, centered = FALSE, register = FALSE)

	var/affected = S.get_affected_turfs(BL, centered=FALSE)

	var/found = 0
	// Search the turfs for docking ports
	// - We need to find the mobile docking port because that is the heart of
	//   the shuttle.
	// - We need to check that no additional ports have slipped in from the
	//   template, because that causes unintended behaviour.
	for(var/T in affected)
		for(var/obj/docking_port/P in T)
			if(istype(P, /obj/docking_port/mobile))
				found++
				if(found > 1)
					qdel(P, force=TRUE)
					log_world("Map warning: Shuttle Template [S.mappath] has multiple mobile docking ports.")
				else
					preview_shuttle = P
			if(istype(P, /obj/docking_port/stationary))
				log_world("Map warning: Shuttle Template [S.mappath] has a stationary docking port.")
	if(!found)
		var/msg = "load_template(): Shuttle Template [S.mappath] has no mobile docking port. Aborting import."
		for(var/T in affected)
			var/turf/T0 = T
			T0.empty()

		message_admins(msg)
		WARNING(msg)
		return
	//Everything fine
	S.post_load(preview_shuttle)
	return TRUE

/datum/controller/subsystem/shuttle/proc/unload_preview()
	if(preview_shuttle)
		preview_shuttle.jumpToNullSpace()
	preview_shuttle = null

/datum/controller/subsystem/shuttle/ui_state(mob/user)
	return GLOB.admin_state

/datum/controller/subsystem/shuttle/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ShuttleManipulator")
		ui.open()

/datum/controller/subsystem/shuttle/ui_data(mob/user)
	var/list/data = list()
	data["tabs"] = list("Status", "Templates", "Modification")

	// Templates panel
	data["templates"] = list()
	var/list/templates = data["templates"]
	data["templates_tabs"] = list()
	data["selected"] = list()

	for(var/shuttle_id in SSmapping.shuttle_templates)
		var/datum/map_template/shuttle/S = SSmapping.shuttle_templates[shuttle_id]

		if(!templates[S.port_id])
			data["templates_tabs"] += S.port_id
			templates[S.port_id] = list(
				"port_id" = S.port_id,
				"templates" = list())

		var/list/L = list()
		L["name"] = S.name
		L["shuttle_id"] = S.shuttle_id
		L["port_id"] = S.port_id
		L["description"] = S.description
		L["admin_notes"] = S.admin_notes

		if(selected == S)
			data["selected"] = L

		templates[S.port_id]["templates"] += list(L)

	data["templates_tabs"] = sortList(data["templates_tabs"])

	data["existing_shuttle"] = null

	// Status panel
	data["shuttles"] = list()
	for(var/i in mobile)
		var/obj/docking_port/mobile/M = i
		var/timeleft = M.timeLeft(1)
		var/list/L = list()
		L["name"] = M.name
		L["id"] = M.id
		L["timer"] = M.timer
		L["timeleft"] = M.getTimerStr()
		if (timeleft > 1 HOURS)
			L["timeleft"] = "Infinity"
		L["can_fast_travel"] = M.timer && timeleft >= 50
		L["can_fly"] = TRUE
		if(istype(M, /obj/docking_port/mobile/emergency))
			L["can_fly"] = FALSE
		else if(!M.destination)
			L["can_fast_travel"] = FALSE
		if (M.mode != SHUTTLE_IDLE)
			L["mode"] = capitalize(M.mode)
		L["status"] = M.getDbgStatusText()
		if(M == existing_shuttle)
			data["existing_shuttle"] = L

		data["shuttles"] += list(L)

	return data

/datum/controller/subsystem/shuttle/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/user = usr

	// Preload some common parameters
	var/shuttle_id = params["shuttle_id"]
	var/datum/map_template/shuttle/S = SSmapping.shuttle_templates[shuttle_id]

	switch(action)
		if("select_template")
			if(S)
				existing_shuttle = getShuttle(S.port_id)
				selected = S
				. = TRUE
		if("jump_to")
			if(params["type"] == "mobile")
				for(var/i in mobile)
					var/obj/docking_port/mobile/M = i
					if(M.id == params["id"])
						user.forceMove(get_turf(M))
						. = TRUE
						break

		if("fly")
			for(var/i in mobile)
				var/obj/docking_port/mobile/M = i
				if(M.id == params["id"])
					. = TRUE
					M.admin_fly_shuttle(user)
					break

		if("fast_travel")
			for(var/i in mobile)
				var/obj/docking_port/mobile/M = i
				if(M.id == params["id"] && M.timer && M.timeLeft(1) >= 50)
					M.setTimer(50)
					. = TRUE
					message_admins("[key_name_admin(usr)] fast travelled [M]")
					log_admin("[key_name(usr)] fast travelled [M]")
					SSblackbox.record_feedback("text", "shuttle_manipulator", 1, "[M.name]")
					break

		if("load")
			if(S && !shuttle_loading)
				. = TRUE
				shuttle_loading = TRUE
				// If successful, returns the mobile docking port
				var/obj/docking_port/mobile/mdp = action_load(S)
				if(mdp)
					user.forceMove(get_turf(mdp))
					message_admins("[key_name_admin(usr)] loaded [mdp] with the shuttle manipulator.")
					log_admin("[key_name(usr)] loaded [mdp] with the shuttle manipulator.</span>")
					SSblackbox.record_feedback("text", "shuttle_manipulator", 1, "[mdp.name]")
				shuttle_loading = FALSE

		if("preview")
			//if(preview_shuttle && (loading_template != preview_template))
			if(S && !shuttle_loading)
				. = TRUE
				shuttle_loading = TRUE
				unload_preview()
				load_template(S)
				if(preview_shuttle)
					preview_template = S
					user.forceMove(get_turf(preview_shuttle))
				shuttle_loading = FALSE

		if("replace")
			if(existing_shuttle == backup_shuttle)
				// TODO make the load button disabled
				WARNING("The shuttle that the selected shuttle will replace \
					is the backup shuttle. Backup shuttle is required to be \
					intact for round sanity.")
			else if(S && !shuttle_loading)
				. = TRUE
				shuttle_loading = TRUE
				// If successful, returns the mobile docking port
				var/obj/docking_port/mobile/mdp = action_load(S, replace = TRUE)
				if(mdp)
					user.forceMove(get_turf(mdp))
					message_admins("[key_name_admin(usr)] load/replaced [mdp] with the shuttle manipulator.")
					log_admin("[key_name(usr)] load/replaced [mdp] with the shuttle manipulator.</span>")
					SSblackbox.record_feedback("text", "shuttle_manipulator", 1, "[mdp.name]")
				shuttle_loading = FALSE
				if(emergency == mdp) //you just changed the emergency shuttle, there are events in game + captains that can change your snowflake choice.
					var/set_purchase = tgui_alert(usr, "Do you want to also disable shuttle purchases/random events that would change the shuttle?", "Butthurt Admin Prevention", list("Yes, disable purchases/events", "No, I want to possibly get owned"))
					if(set_purchase == "Yes, disable purchases/events")
						SSshuttle.shuttle_purchased = SHUTTLEPURCHASE_FORCED

/datum/controller/subsystem/shuttle/proc/init_has_purchase_shuttle_access()
	var/list/has_purchase_shuttle_access = list()

	for (var/shuttle_id in SSmapping.shuttle_templates)
		var/datum/map_template/shuttle/shuttle_template = SSmapping.shuttle_templates[shuttle_id]
		if (!isnull(shuttle_template.who_can_purchase))
			has_purchase_shuttle_access |= shuttle_template.who_can_purchase

	return has_purchase_shuttle_access

/datum/controller/subsystem/shuttle/proc/auto_transfer()
	if(EMERGENCY_IDLE_OR_RECALLED)
		SSshuttle.emergency.request(silent = TRUE)
		var/ic_message = "The current shift is about to end. A transfer shuttle has been dispatched."
		priority_announce(ic_message)
		var/log_message = "Transfer vote passed. Shuttle has been auto-called."
		log_game(log_message)
		message_admins(log_message)
	emergency_no_recall = TRUE
