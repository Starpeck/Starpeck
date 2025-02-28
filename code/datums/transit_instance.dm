/datum/transit_instance
	var/datum/virtual_level/vlevel
	var/obj/docking_port/stationary/transit/dock
	var/datum/overmap_object/shuttle/overmap_shuttle
	//Associative for easy lookup
	var/list/affected_movables = list()

/datum/transit_instance/New(datum/virtual_level/arg_vlevel, obj/docking_port/stationary/transit/arg_dock)
	. = ..()
	vlevel = arg_vlevel
	vlevel.transit_instance = src
	dock = arg_dock
	dock.transit_instance = src
	START_PROCESSING(SSobj, src)

/datum/transit_instance/Destroy()
	strand_all()
	vlevel.transit_instance = null
	vlevel = null
	dock.transit_instance = null
	dock = null
	overmap_shuttle = null
	STOP_PROCESSING(SSobj, src)
	return ..()

// No overmap bandaid
/datum/transit_instance/process(delta_time)
	if(!dock)
		return
	ApplyVelocity(REVERSE_DIR(dock.transit_direction), 1.25)

//Apply velocity to the movables we're handling
/datum/transit_instance/proc/ApplyVelocity(dir, velocity)
	var/velocity_stage
	switch(velocity)
		if(0 to 0.5)
			velocity_stage = TRANSIT_VELOCITY_NEGLIGIBLE
		if(0.5 to 1)
			velocity_stage = TRANSIT_VELOCITY_LOW
		if(1 to 1.5)
			velocity_stage = TRANSIT_VELOCITY_MEDIUM
		if(2 to INFINITY)
			velocity_stage = TRANSIT_VELOCITY_HIGH
	if(!velocity_stage)
		return
	for(var/i in affected_movables)
		var/atom/movable/movable = i
		if(movable.anchored)
			continue
		var/turf/my_turf = get_turf(movable)
		if(!my_turf)
			continue
		var/turf/step_turf = get_step(my_turf, dir)
		//Medium velocity, and someone gets bumped against an edge turf
		if(velocity_stage >= TRANSIT_VELOCITY_MEDIUM && vlevel.on_edge_reservation(step_turf))
			strand_act(movable)
			continue
		//Huge velocity, check if we get squashed against something that blocks us
		if(velocity_stage >= TRANSIT_VELOCITY_HIGH && isliving(movable))
			var/mob/living/movable_mob = movable
			if(isclosedturf(step_turf) || step_turf.is_blocked_turf(TRUE))
				movable_mob.gib(FALSE, FALSE, FALSE)
				continue
		//If velocity is medium, mobs can still hold onto things to avoid being thrown
		if(velocity_stage <= TRANSIT_VELOCITY_MEDIUM && isliving(movable))
			if(movable.Process_Spacemove())
				continue
			for(var/cardinal in GLOB.cardinals)
				var/turf/cardinal_turf = get_step(my_turf, cardinal)
				if(!istype(cardinal_turf, /turf/open/space/transit))
					continue
		if(!isclosedturf(step_turf) && !step_turf.is_blocked_turf(TRUE))
			movable.throw_at(get_edge_target_turf(my_turf, dir), 4, 2)

/datum/transit_instance/proc/movable_hanging_onto(atom/movable/movable)
	var/turf/my_turf = get_turf(movable)
	if(!my_turf)
		return FALSE
	if(isliving(movable))
		if(movable.Process_Spacemove())
			return TRUE
		for(var/cardinal in GLOB.cardinals)
			var/turf/cardinal_turf = get_step(my_turf, cardinal)
			if(!istype(cardinal_turf, /turf/open/space/transit))
				return TRUE
	return FALSE

///Strand all movables that we're managing
/datum/transit_instance/proc/strand_all()
	for(var/movable in affected_movables)
		strand_act(movable)

/datum/transit_instance/proc/strand_act(atom/movable/strander)
	var/side = pick(GLOB.cardinals)
	var/datum/virtual_level/startsub = pick(SSmapping.virtual_levels_by_trait(ZTRAIT_SPACE_RUINS))
	var/turf/pickedstart = startsub.get_side_turf(side)
	var/turf/pickedgoal = startsub.get_side_turf(REVERSE_DIR(side))

	strander.forceMove(pickedstart)
	strander.throw_at(pickedgoal, 4, 2)

	if(ismob(strander))
		to_chat(strander, SPAN_USERDANGER("I was stranded!"))

/datum/transit_instance/proc/process_transiter(atom/movable/thing, datum/component/transit_handler/handler)
	if(!thing)
		return
	if(!thing.loc)
		return
	if(movable_hanging_onto(thing))
		handler.time_until_strand = world.time + 4 SECONDS
	else
		if(vlevel.on_edge(get_turf(thing)) && handler.time_until_strand >= world.time)
			strand_act(thing)
