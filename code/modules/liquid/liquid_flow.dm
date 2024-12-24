/obj/effect/abstract/liquid_flow
	name = "liquid flow creator"
	icon_state = "spawner"
	invisibility = INVISIBILITY_ABSTRACT
	var/turf/master_turf
	var/list/turf/liquid_turfs = list()
	var/list/turf/affected_turfs = list()

/obj/effect/abstract/liquid_flow/Initialize()
	. = ..()
	master_turf = get_turf(src)
	if(!(locate(/obj/effect/abstract/liquid_turf) in master_turf.contents))
		CRASH("liquid flow creator isn't in liquid.")
	return INITIALIZE_HINT_LATELOAD

/obj/effect/abstract/liquid_flow/LateInitialize()
	. = ..()
	// Let's get first iteration so while won't end
	for(var/turf/T in master_turf.GetAtmosAdjacentTurfs())
		if(!T.liquids)
			continue
		liquid_turfs += T

	for(var/turf/T in liquid_turfs)
		liquid_turfs -= T

		for(var/turf/T2 in T.GetAtmosAdjacentTurfs())
			if(T2 in liquid_turfs || T2 in affected_turfs || !T2.liquids)
				continue
			liquid_turfs += T2
		
		T.liquids.forced_flow = get_cardinal_dir(master_turf, T)
		affected_turfs += T

		