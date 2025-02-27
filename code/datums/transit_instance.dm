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

/datum/transit_instance/Destroy()
	strand_all()
	vlevel.transit_instance = null
	vlevel = null
	dock.transit_instance = null
	dock = null
	overmap_shuttle = null
	return ..()

//Movable moved in transit
/datum/transit_instance/proc/movable_moved(atom/movable/moved, time_until_strand)
	if(!moved)
		stack_trace("null movable on Movable Moved in Transit Instance")
		return
	if(!moved.loc || !isturf(moved.loc))
		return
	if(time_until_strand > world.time)
		return
	var/turf/my_turf = moved.loc
	if(!vlevel.on_edge(my_turf))
		return
	//We've moved to be adjacent to edge or out of bounds
	//Check for things that should just disappear as they bump into the edges of the map
	//Maybe listening for this event could be done in a better way?
	if(ishuman(moved)) //Humans could disconnect and not have a client, we dont want to get them stranded
		return
	if(ismob(moved))
		var/mob/moved_mob = moved
		if(moved_mob.client) //Client things never voluntairly get stranded
			return
	strand_act(moved)

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

///Strand all movables that we're managing
/datum/transit_instance/proc/strand_all()
	for(var/movable in affected_movables)
		strand_act(movable)

/// Strand the mob in some space ruin level and throw them
/datum/transit_instance/proc/strand_act(atom/movable/strander)
	var/side = pick(GLOB.cardinals)
	var/datum/virtual_level/startsub = pick(SSmapping.virtual_levels_by_trait(ZTRAIT_SPACE_RUINS))
	var/turf/pickedstart = startsub.get_side_turf(side)
	var/turf/pickedgoal = startsub.get_side_turf(REVERSE_DIR(side))

	strander.forceMove(pickedstart)
	strander.throw_at(pickedgoal, 4, 2)
