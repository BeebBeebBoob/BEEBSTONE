SUBSYSTEM_DEF(liquids)
	name = "Liquid Turfs"
	wait = 1 SECONDS
	flags = SS_KEEP_TIMING | SS_NO_INIT
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME

	var/list/active_turfs = list()
	var/list/currentrun_active_turfs = list()

	var/list/active_groups = list()

	var/list/active_immutables = list()

	// format: list[path, list[str, instance]]
	var/list/singleton_immutables = list()

	var/run_type = SSLIQUIDS_RUN_TYPE_TURFS

/datum/controller/subsystem/liquids/proc/get_immutable(type, turf/reference_turf)
	if(isnull(singleton_immutables[type]))
		singleton_immutables[type] = list()

	var/direction = reference_turf.dir

	if(!("[direction]" in singleton_immutables[type]))
		var/obj/effect/abstract/liquid_turf/immutable/new_one = new type(null, direction)
		singleton_immutables[type]["[direction]"] = new_one

	return singleton_immutables[type]["[direction]"]


/datum/controller/subsystem/liquids/stat_entry(msg)
	msg += "AT:[active_turfs.len]|AG:[active_groups.len]|AIM:[active_immutables.len]"
	return ..()


/datum/controller/subsystem/liquids/fire(resumed = FALSE)
	if(run_type == SSLIQUIDS_RUN_TYPE_TURFS)
		if(!resumed)
			src.currentrun_active_turfs = active_turfs.Copy()
		// cache for speed
		var/list/currentrun_active_turfs = src.currentrun_active_turfs
		while(currentrun_active_turfs.len)
			var/turf/turf = currentrun_active_turfs[currentrun_active_turfs.len]
			turf.process_liquid_cell()
			currentrun_active_turfs.Remove(turf)
			if(MC_TICK_CHECK)
				break
		resumed = FALSE
		if(!currentrun_active_turfs.len)
			run_type = SSLIQUIDS_RUN_TYPE_GROUPS
	if (run_type == SSLIQUIDS_RUN_TYPE_GROUPS)
		for(var/g in active_groups)
			var/datum/liquid_group/LG = g
			if(LG.dirty)
				LG.share()
				LG.dirty = FALSE
			else if(!LG.amount_of_active_turfs)
				LG.decay_counter++
				if(LG.decay_counter >= LIQUID_GROUP_DECAY_TIME)
					//Perhaps check if any turfs in here can spread before removing it? It's not unlikely they would
					LG.break_group()
			if(MC_TICK_CHECK)
				run_type = SSLIQUIDS_RUN_TYPE_IMMUTABLES //No currentrun here for now
				break
		resumed = FALSE
		run_type = SSLIQUIDS_RUN_TYPE_IMMUTABLES
	if(run_type == SSLIQUIDS_RUN_TYPE_IMMUTABLES)
		for(var/t in active_immutables)
			var/turf/T = t
			T.process_immutable_liquid()
			/*
			if(MC_TICK_CHECK)
				break
			*/
		resumed = FALSE
		run_type = SSLIQUIDS_RUN_TYPE_TURFS

/datum/controller/subsystem/liquids/proc/add_active_turf(turf/T)
	if(can_fire && !active_turfs[T])
		active_turfs[T] = TRUE
		if(T.lgroup)
			T.lgroup.amount_of_active_turfs++

/datum/controller/subsystem/liquids/proc/remove_active_turf(turf/T)
	if(active_turfs[T])
		active_turfs -= T
		if(T.lgroup)
			T.lgroup.amount_of_active_turfs--

/client/proc/spawn_liquid()
	set name = "Spawn Water"
	set desc = "Flood the turf you are standing on."
	set category = "Debug"

	if(!check_rights(R_SPAWN))
		return
	var/mob/user = usr
	if(istype(user) && user.client)
		for(var/turf/T in range(1, get_turf(user)))
			T.add_liquid(/datum/reagent/water, 2000)
