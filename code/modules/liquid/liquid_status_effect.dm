/datum/status_effect/water_affected
	id = "wateraffected"
	alert_type = null
	duration = -1

/datum/status_effect/water_affected/on_apply()
	//We should be inside a liquid turf if this is applied
	calculate_water_slow()
	return TRUE

/datum/status_effect/water_affected/proc/calculate_water_slow()
	//Factor in swimming skill here?
	var/turf/T = get_turf(owner)
	var/slowdown_amount = T.liquids.liquid_state - owner.mind.get_skill_level(/datum/skill/misc/swimming)
	var/usedslow = T.get_slowdown(src)
	if(usedslow != 0)
		owner.add_movespeed_modifier(MOVESPEED_ID_LIVING_LIQUID_SPEEDMOD, update=TRUE, priority=100, multiplicative_slowdown = slowdown_amount, movetypes = GROUND)
	else
		owner.remove_movespeed_modifier(MOVESPEED_ID_LIVING_LIQUID_SPEEDMOD)

/datum/status_effect/water_affected/tick()
	var/turf/T = get_turf(owner)
	if(!T || !T.liquids || T.liquids.liquid_state == LIQUID_STATE_PUDDLE)
		qdel(src)
		return
	calculate_water_slow()
	//Make the reagents touch the person
	var/fraction = SUBMERGEMENT_PERCENT(owner, T.liquids)
	var/datum/reagents/tempr = T.liquids.simulate_reagents_flat(SUBMERGEMENT_REAGENTS_TOUCH_AMOUNT*fraction)
	var/vol_modifier = round(SUBMERGEMENT_REAGENTS_TOUCH_AMOUNT*fraction, 0.01)
	tempr.reaction(owner, TOUCH, vol_modifier)
	qdel(tempr)
	// Rivers
	if(T.liquids.liquid_push(owner))
		to_chat(owner, span_warning("You're getting washed by a water flow!"))
	// Swimming
	// Начинаем с простого
	// Затопленная комната = Просто медленно ходит
	// Снизу затопленной комнаты, пустота т.е. озеро к примеру = добавить шанс утонуть, резко повышать шанс если человек в доспехах или тяжёл
	// При успешной просто держим наплаву
	// При провале, добавляем плески и делей с парализом чтобы показать якобы анимацию утопа

	var/turf/below = SSmapping.get_turf_below(T)
	if(istype(T, /turf/open/transparent/openspace) && isopenturf(below) && (world.time & TICK_DROWN))
		var/drown_chance = DEFAULT_DROWN_CHANCE
		for(var/obj/item/I in owner.get_contents())
			if(istype(I.smeltresult, /obj/item/ingot))
				drown_chance += I.w_class * WEIGHT_DROWN_MULTIPLIER
		drown_chance -= owner.mind.get_skill_level(/datum/skill/misc/swimming) * SKILL_DROWN_MULTIPLIER
		drown_chance = max(drown_chance, MINIMUM_DROWN_CHANCE)
		if(prob(drown_chance)) // We going dowwnnn
			to_chat(owner, "YOU ARE DROWNING [drown_chance]%")
			addtimer(CALLBACK(T.liquids, TYPE_PROC_REF(/obj/effect/abstract/liquid_turf, liquid_fall), owner, 0, below), 1 SECONDS)
			owner.Paralyze(2 SECONDS)
			new /obj/effect/temp_visual/liquid_splash(T)
	
	return ..()

/*
/datum/status_effect/water_affected/on_remove()
	owner.remove_movespeed_modifier(/datum/movespeed_modifier/status_effect/water_slowdown)

/datum/movespeed_modifier/status_effect/water_slowdown
	variable = TRUE
	blacklisted_movetypes = (FLYING|FLOATING)
*/
