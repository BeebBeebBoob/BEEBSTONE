// This is liquid_effect.dm but it's main code

/obj/effect/abstract/liquid_turf
	name = "water"
	icon = 'icons/turf/water.dmi'
	icon_state = "water"
	anchored = TRUE
	plane = FLOOR_PLANE
	layer = ABOVE_OPEN_TURF_LAYER
	appearance_flags = TILE_BOUND
	color = "#6a9295"

	smooth = SMOOTH_MORE|SMOOTH_DIAGONAL
	canSmoothWith = list(/obj/effect/abstract/liquid_turf, /turf/closed/wall, /obj/structure/falsewall, /obj/structure/roguewindow)
	//obj_flags = BLOCK_Z_OUT_DOWN если бы это работало... КОРОЧ, из-за нюансов immutable, этот эффект ОДИН объект на все турфы и распространяется через vis_content
	// поэтому мне надо добавить особую проверку на падение в turf.dm 
	// Я просто захардкодил на проверку turf.liquids, Но рекомендую через vis_content
	// тут мало вещей с флагами блокировок поэтому это будет логичнее чем мой подход на данный момент

	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	var/height = 1
	var/turf/my_turf
	var/liquid_state = LIQUID_STATE_PUDDLE
	var/has_cached_share = FALSE
	var/mutable_appearance/water_overlay
	var/mutable_appearance/water_top_overlay

	var/forced_flow = NONE // direction of flow to push, forced by liquid_flow

	var/attrition = 0

	var/immutable = FALSE

	var/list/reagent_list = list()
	var/total_reagents = 0
	var/temp = T20C

	/// State-specific message chunks for examine_turf()
	var/static/list/liquid_state_messages = list(
		"[LIQUID_STATE_PUDDLE]" = "a puddle of water",
		"[LIQUID_STATE_ANKLES]" = "water going [span_warning("up to your ankles")]",
		"[LIQUID_STATE_WAIST]" = "water going [span_warning("up to your waist")]",
		"[LIQUID_STATE_SHOULDERS]" = "water going [span_warning("up to your shoulders")]",
		"[LIQUID_STATE_FULLTILE]" = "water going [span_danger("over your head")]",
	)

// Это так упорото, но исследование сигналов не завершено (p.s. COMSIG_ATOM_EXAMINE)
/turf/examine(mob/user)
	. = ..()
	if(liquids)
		. += span_info("\nThere is [liquids.liquid_state_messages["[liquids.liquid_state]"]] here.")

/obj/effect/abstract/liquid_turf/proc/evaporate()
	//See if any of our reagents evaporates
	var/any_change = FALSE
	for(var/reagent_type in reagent_list)
		//We evaporate. bye bye
		total_reagents -= reagent_list[reagent_type]
		reagent_list -= reagent_type
		any_change = TRUE
	if(!any_change)
		return
	//No total reagents. Commit death
	if(reagent_list.len == 0)
		qdel(src, TRUE)
	//Reagents still left. Recalculte height and color and remove us from the queue
	else
		has_cached_share = FALSE
		calculate_height()
		set_reagent_color_for_liquid()


/obj/effect/abstract/liquid_turf/forceMove(atom/destination, no_tp=FALSE, harderforce = FALSE)
	if(harderforce)
		. = ..()

/obj/effect/abstract/liquid_turf/proc/set_new_liquid_state(new_state)
	liquid_state = new_state
	if(!isnull(my_turf))
		my_turf.liquids_change(new_state)
	update_icon()

/*
/obj/effect/fluid/on_update_icon()

	overlays.Cut()

	if(fluid_amount > FLUID_OVER_MOB_HEAD)
		layer = DEEP_FLUID_LAYER
	else
		layer = SHALLOW_FLUID_LAYER

	if(fluid_amount > FLUID_DEEP)
		alpha = FLUID_MAX_ALPHA
	else
		alpha = min(FLUID_MAX_ALPHA,max(FLUID_MIN_ALPHA,ceil(255*(fluid_amount/FLUID_DEEP))))

	var/icon_state_liquid = ""
	if(fluid_amount > FLUID_DELETING && fluid_amount <= FLUID_EVAPORATION_POINT)
		icon_state_liquid = "shallow_still"
	else if(fluid_amount > FLUID_EVAPORATION_POINT && fluid_amount < FLUID_SHALLOW)
		icon_state_liquid = "mid_still"
	else if(fluid_amount >= FLUID_SHALLOW && fluid_amount < (FLUID_DEEP*2))
		icon_state_liquid = "deep_still"
	else if(fluid_amount >= (FLUID_DEEP*2))
		icon_state_liquid = "ocean"
*/ 

/obj/effect/abstract/liquid_turf/update_icon()
	. = ..()
	cut_overlay(water_overlay)
	water_overlay = mutable_appearance(icon, "bottom[liquid_state]", ABOVE_MOB_LAYER, GAME_PLANE)
	add_overlay(water_overlay)
	
	cut_overlay(water_top_overlay)
	if(liquid_state != LIQUID_STATE_FULLTILE)
		water_top_overlay = mutable_appearance(icon, "top[liquid_state]", TABLE_LAYER + 0.05, GAME_PLANE)
		add_overlay(water_top_overlay)

//Takes a flat of our reagents and returns it, possibly qdeling our liquids
/obj/effect/abstract/liquid_turf/proc/take_reagents_flat(flat_amount)
	var/datum/reagents/tempr = new(10000)
	if(flat_amount >= total_reagents)
		tempr.add_reagent_list(reagent_list)
		qdel(src, TRUE)
	else
		var/fraction = flat_amount/total_reagents
		var/passed_list = list()
		for(var/reagent_type in reagent_list)
			var/amount = fraction * reagent_list[reagent_type]
			reagent_list[reagent_type] -= amount
			total_reagents -= amount
			passed_list[reagent_type] = amount
		tempr.add_reagent_list(passed_list)
		has_cached_share = FALSE
	tempr.chem_temp = temp
	return tempr

/obj/effect/abstract/liquid_turf/immutable/take_reagents_flat(flat_amount)
	return simulate_reagents_flat(flat_amount)

//Returns a reagents holder with all the reagents with a higher volume than the threshold
/obj/effect/abstract/liquid_turf/proc/simulate_reagents_threshold(amount_threshold)
	var/datum/reagents/tempr = new(10000)
	var/passed_list = list()
	for(var/reagent_type in reagent_list)
		var/amount = reagent_list[reagent_type]
		if(amount_threshold && amount < amount_threshold)
			continue
		passed_list[reagent_type] = amount
	tempr.add_reagent_list(passed_list)
	tempr.chem_temp = temp
	return tempr

//Returns a flat of our reagents without any effects on the liquids
/obj/effect/abstract/liquid_turf/proc/simulate_reagents_flat(flat_amount)
	var/datum/reagents/tempr = new(10000)
	if(flat_amount >= total_reagents)
		tempr.add_reagent_list(reagent_list)
	else
		var/fraction = flat_amount/total_reagents
		var/passed_list = list()
		for(var/reagent_type in reagent_list)
			var/amount = fraction * reagent_list[reagent_type]
			passed_list[reagent_type] = amount
		tempr.add_reagent_list(passed_list)
	tempr.chem_temp = temp
	return tempr

/obj/effect/abstract/liquid_turf/proc/set_reagent_color_for_liquid()
	color = mix_color_from_reagents(reagent_list)

/obj/effect/abstract/liquid_turf/proc/calculate_height()
	var/new_height = CEILING(total_reagents, 1)
	set_height(new_height)
	var/determined_new_state
	//We add the turf height if it's positive to state calculations
	if(my_turf.turf_height > 0)
		new_height += my_turf.turf_height
	switch(new_height)
		if(0 to LIQUID_HEIGHT_ANKLES-1)
			determined_new_state = LIQUID_STATE_PUDDLE
		if(LIQUID_HEIGHT_ANKLES to LIQUID_HEIGHT_WAIST-1)
			determined_new_state = LIQUID_STATE_ANKLES
		if(LIQUID_HEIGHT_WAIST to LIQUID_HEIGHT_SHOULDERS-1)
			determined_new_state = LIQUID_STATE_WAIST
		if(LIQUID_HEIGHT_SHOULDERS to LIQUID_HEIGHT_FULLTILE-1)
			determined_new_state = LIQUID_STATE_SHOULDERS
		if(LIQUID_HEIGHT_FULLTILE to INFINITY)
			determined_new_state = LIQUID_STATE_FULLTILE
	if(determined_new_state != liquid_state)
		set_new_liquid_state(determined_new_state)

/obj/effect/abstract/liquid_turf/immutable/calculate_height()
	var/new_height = CEILING(total_reagents, 1)
	set_height(new_height)
	var/determined_new_state
	switch(new_height)
		if(0 to LIQUID_HEIGHT_ANKLES-1)
			determined_new_state = LIQUID_STATE_PUDDLE
		if(LIQUID_HEIGHT_ANKLES to LIQUID_HEIGHT_WAIST-1)
			determined_new_state = LIQUID_STATE_ANKLES
		if(LIQUID_HEIGHT_WAIST to LIQUID_HEIGHT_SHOULDERS-1)
			determined_new_state = LIQUID_STATE_WAIST
		if(LIQUID_HEIGHT_SHOULDERS to LIQUID_HEIGHT_FULLTILE-1)
			determined_new_state = LIQUID_STATE_SHOULDERS
		if(LIQUID_HEIGHT_FULLTILE to INFINITY)
			determined_new_state = LIQUID_STATE_FULLTILE
	if(determined_new_state != liquid_state)
		set_new_liquid_state(determined_new_state)

/obj/effect/abstract/liquid_turf/proc/set_height(new_height)
	var/prev_height = height
	height = new_height
	if(abs(height - prev_height) > WATER_HEIGH_DIFFERENCE_DELTA_SPLASH)
		//Splash
		if(prob(WATER_HEIGH_DIFFERENCE_SOUND_CHANCE))
			var/sound_to_play = pick(list(
				'sound/effects/water_wade1.ogg',
				'sound/effects/water_wade2.ogg',
				'sound/effects/water_wade3.ogg',
				'sound/effects/water_wade4.ogg'
				))
			playsound(my_turf, sound_to_play, 60, 0)
		var/obj/splashy = new /obj/effect/temp_visual/liquid_splash(my_turf)
		splashy.color = color
		if(height >= LIQUID_HEIGHT_WAIST)
			//Push things into some direction, like space wind
			var/turf/dest_turf
			var/last_height = height
			for(var/turf in my_turf.atmos_adjacent_turfs)
				var/turf/T = turf
				if(T.z != my_turf.z)
					continue
				if(!T.liquids) //Automatic winner
					dest_turf = T
					break
				if(T.liquids.height < last_height)
					dest_turf = T
					last_height = T.liquids.height
			if(dest_turf)
				var/dir = get_dir(my_turf, dest_turf)
				var/atom/movable/AM
				for(var/thing in my_turf)
					AM = thing
					if(!AM.anchored && !AM.pulledby && !isobserver(AM) && (AM.move_resist < INFINITY))
						if(iscarbon(AM))
							var/mob/living/carbon/C = AM
							if(!(C.shoes && C.shoes.clothing_flags))
								step(C, dir)
								if(prob(60) && !(C.mobility_flags & MOBILITY_STAND))
									to_chat(C, span_userdanger("The flow knocks you down!"))
									C.Paralyze(60)
						else
							step(AM, dir)

/obj/effect/abstract/liquid_turf/immutable/set_height(new_height)
	height = new_height

/obj/effect/abstract/liquid_turf/proc/movable_entered(datum/source, atom/movable/AM)
	SIGNAL_HANDLER
	var/turf/T = source
	if(isobserver(AM))
		return //ghosts, camera eyes, etc. don't make water splashy splashy
	
	if(liquid_state >= LIQUID_STATE_ANKLES)
		if(prob(30))
			var/sound_to_play = pick(list(
				'sound/effects/water_wade1.ogg',
				'sound/effects/water_wade2.ogg',
				'sound/effects/water_wade3.ogg',
				'sound/effects/water_wade4.ogg'
				))
			playsound(T, sound_to_play, 50, 0)
		if(iscarbon(AM))
			var/mob/living/carbon/C = AM
			C.apply_status_effect(/datum/status_effect/water_affected)
		if(isobj(AM))
			var/datum/reagents/tempr = simulate_reagents_flat(total_reagents)
			var/vol_modifier = round(sqrt(total_reagents) / total_reagents, 0.01)
			tempr.reaction(AM, TOUCH, vol_modifier)
			qdel(tempr)
			if(forced_flow) // Я думал сюда добавить проверку на w_class но нюанс что эт переменная у /item, а не /obj (проверка по health, integrity?)
				addtimer(CALLBACK(src, PROC_REF(liquid_push), AM), 1 SECONDS)
	else if (isliving(AM)) // пудель воды. подскольз при беге или просто ходьбе, уточнить
		var/mob/living/L = AM
		if(prob(7) && !(L.movement_type & FLYING))
			L.slip(60, T, NO_SLIP_WHEN_WALKING, 20, TRUE)

// Used by forced_flow to simulate flow in rivers and by possibly-immutable liquids
/obj/effect/abstract/liquid_turf/proc/liquid_push(atom/movable/AM)
	if(!forced_flow && !AM.anchored)
		return FALSE
	step(AM, forced_flow)
	return TRUE


/* Будет хорошо использовать если упал в воду на одном и том же уровне и не так тяжёлый
/obj/machinery/power/supermatter_crystal/intercept_zImpact(atom/movable/AM, levels)
	. = ..()
	Bumped(AM)
	. |= FALL_STOP_INTERCEPTING | FALL_INTERCEPTED
*/

// if TRUE, intercepts zFall
/obj/effect/abstract/liquid_turf/proc/liquid_fall(atom/movable/AM, levels, below)
	var/turf/T = my_turf
	if(liquid_state >= LIQUID_STATE_ANKLES)
		var/drown_chance = FIRST_DROWN_CHANCE
		if(isliving(AM))
			var/mob/living/L = AM
			for(var/obj/item/I in L.get_contents())
				if(istype(I.smeltresult, /obj/item/ingot))
					drown_chance += I.w_class * WEIGHT_DROWN_MULTIPLIER
			drown_chance -= L.mind.get_skill_level(/datum/skill/misc/swimming) * SKILL_DROWN_MULTIPLIER
			drown_chance += levels * LEVEL_FALL_DROWN_MULTIPLIER
		if(isobj(AM))
			drown_chance = INFINITY
		drown_chance = max(drown_chance, MINIMUM_DROWN_CHANCE)
		if(!prob(drown_chance)) // no go down
			return TRUE
		playsound(T, pick('sound/effects/splash1.ogg', 'sound/effects/splash2.ogg', 'sound/effects/splash3.ogg'), 50, 0)
		if(iscarbon(AM))
			var/mob/living/carbon/falling_carbon = AM

			// No point in giving reagents to the deceased. It can cause some runtimes.
			if(falling_carbon.stat >= DEAD)
				AM.zfalling = TRUE
				AM.forceMove(below)
				AM.zfalling = FALSE
				return TRUE // But no fall damage into water

			if(falling_carbon.wear_mask && falling_carbon.wear_mask.flags_cover & MASKCOVERSMOUTH)
				to_chat(falling_carbon, span_userdanger("You fall in the water!"))
			else
				var/datum/reagents/tempr = take_reagents_flat(CHOKE_REAGENTS_INGEST_ON_FALL_AMOUNT)
				tempr.trans_to(falling_carbon, tempr.total_volume, method = INGEST)
				qdel(tempr)
				falling_carbon.adjustOxyLoss(15)
				falling_carbon.emote("cough")
				to_chat(falling_carbon, span_userdanger("You fall in and swallow some water!"))
		else
			to_chat(AM, span_userdanger("You fall in the water!"))
		
		//zFall part without zImpact
		AM.zfalling = TRUE
		AM.forceMove(below)
		AM.zfalling = FALSE
		return TRUE
	return

/obj/effect/abstract/liquid_turf/Initialize(mapload)
	. = ..()
	if(!SSliquids)
		CRASH("Liquid Turf created with the liquids sybsystem not yet initialized!")
	if(!immutable)
		my_turf = loc
		RegisterSignal(my_turf, COMSIG_ATOM_ENTERED, PROC_REF(movable_entered))
		SSliquids.add_active_turf(my_turf)

	update_icon()

/obj/effect/abstract/liquid_turf/Destroy(force)
	if(force)
		UnregisterSignal(my_turf, COMSIG_ATOM_ENTERED)
		if(my_turf.lgroup)
			my_turf.lgroup.remove_from_group(my_turf)
		//Is added because it could invoke a change to neighboring liquids
		SSliquids.add_active_turf(my_turf)
		my_turf.liquids = null
		my_turf = null
	else
		return QDEL_HINT_LETMELIVE
	return ..()

/obj/effect/abstract/liquid_turf/immutable/Destroy(force)
	if(force)
		stack_trace("Something tried to hard destroy an immutable liquid.")
	return ..()

//Exposes my turf with simulated reagents
/obj/effect/abstract/liquid_turf/proc/ExposeMyTurf()
	var/datum/reagents/tempr = simulate_reagents_flat(total_reagents)
	var/vol_modifier = round(sqrt(total_reagents) / total_reagents, 0.01)
	tempr.reaction(src, TOUCH, vol_modifier)
	qdel(tempr)

/obj/effect/abstract/liquid_turf/proc/ChangeToNewTurf(turf/NewT)
	if(NewT.liquids)
		stack_trace("Liquids tried to change to a new turf, that already had liquids on it!")

	UnregisterSignal(my_turf, COMSIG_ATOM_ENTERED)
	if(SSliquids.active_turfs[my_turf])
		SSliquids.active_turfs -= my_turf
		SSliquids.active_turfs[NewT] = TRUE
	my_turf.liquids = null
	my_turf = NewT
	NewT.liquids = src
	loc = NewT
	RegisterSignal(my_turf, COMSIG_ATOM_ENTERED, PROC_REF(movable_entered))

/obj/effect/temp_visual/liquid_splash
	icon = 'icons/turf/water.dmi'
	icon_state = "splash"
	layer = FLY_LAYER
	randomdir = FALSE
	
/obj/effect/abstract/liquid_turf/immutable
	immutable = TRUE
	var/list/starting_mixture = list(/datum/reagent/water = 600)
	var/starting_temp = T20C
	
/obj/effect/abstract/liquid_turf/immutable/Initialize(mapload, plane_offset)
	. = ..()
	reagent_list = starting_mixture.Copy()
	total_reagents = 0
	for(var/key in reagent_list)
		total_reagents += reagent_list[key]
	temp = starting_temp
	calculate_height()
	set_reagent_color_for_liquid()

//STRICTLY FOR IMMUTABLES DESPITE NOT BEING /immutable
/obj/effect/abstract/liquid_turf/proc/add_turf(turf/T)
	T.liquids = src
	T.vis_contents += src
	SSliquids.active_immutables[T] = TRUE
	RegisterSignal(T, COMSIG_ATOM_ENTERED, PROC_REF(movable_entered))

/obj/effect/abstract/liquid_turf/proc/remove_turf(turf/T)
	SSliquids.active_immutables -= T
	T.liquids = null
	T.vis_contents -= src
	UnregisterSignal(T, COMSIG_ATOM_ENTERED)
