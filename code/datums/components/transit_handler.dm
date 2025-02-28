/datum/component/transit_handler
	/// Our transit instance
	var/datum/transit_instance/transit_instance
	/// Time until we'll consider stranding a thing, they need to be in transit for some time until we delete them
	var/time_until_strand = 0

/datum/component/transit_handler/Initialize(datum/transit_instance/transit_instance_)
	if(!ismovable(parent))
		return COMPONENT_INCOMPATIBLE
	transit_instance = transit_instance_
	time_until_strand = world.time + 4 SECONDS
	transit_instance.affected_movables[parent] = TRUE
	START_PROCESSING(SSobj, src)

/datum/component/transit_handler/process(delta_time)
	if(!parent)
		qdel(src)
		return
	var/turf/new_location = get_turf(parent)
	if(!istype(new_location, /turf/open/space/transit))
		qdel(src)
	transit_instance.process_transiter(parent)

/datum/component/transit_handler/UnregisterFromParent()
	STOP_PROCESSING(SSobj, src)
	transit_instance.affected_movables -= parent
