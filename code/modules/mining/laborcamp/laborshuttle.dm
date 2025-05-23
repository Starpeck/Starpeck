/obj/machinery/computer/shuttle/labor
	name = "labor shuttle console"
	desc = "Used to call and send the labor camp shuttle."
	circuit = /obj/item/circuitboard/computer/labor_shuttle
	shuttleId = "laborcamp"
	restricted_destinations = "laborcamp_home;laborcamp_away"
	possible_destinations = "laborcamp_home;laborcamp_away;mediumdock;largedock;hugedock"
	req_access = list(ACCESS_BRIG)
	uses_overmap = FALSE

/obj/machinery/computer/shuttle/labor/one_way
	name = "prisoner shuttle console"
	desc = "A one-way shuttle console, used to summon the shuttle to the labor camp."
	possible_destinations = "laborcamp_away"
	circuit = /obj/item/circuitboard/computer/labor_shuttle/one_way
	req_access = list()

/obj/machinery/computer/shuttle/labor/one_way/launch_check(mob/user)
	. = ..()
	if(!.)
		return FALSE
	var/obj/docking_port/mobile/M = SSshuttle.getShuttle("laborcamp")
	if(!M)
		to_chat(user, SPAN_WARNING("Cannot locate shuttle!"))
		return FALSE
	var/obj/docking_port/stationary/S = M.get_docked()
	if(S?.name == "laborcamp_away")
		to_chat(user, SPAN_WARNING("Shuttle is already at the outpost!"))
		return FALSE
	return TRUE
