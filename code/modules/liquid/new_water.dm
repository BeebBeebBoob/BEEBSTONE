// Beeb: чтобы все функции сохранились и не копировать по два раза, 
// Каждый низкий пол это уникальный путь. Можно было и /roque/lowered/*
// Но не стоит. Хотя тут либо одно либо другое жертвовать.

// Crafted stone floor

/turf/open/floor/rogue/blocks/lowered
	name = "lowered floor"
	liquid_height = -300
	turf_height = -300
	icon_state = "blocks_lowered"

/// Non-craftable ones

/turf/open/floor/rogue/lowered
	name = "lowered floor"
	liquid_height = -300
	turf_height = -300
	var/immutable_type = /obj/effect/abstract/liquid_turf/immutable/grosswater
	var/init_icon_state = ""

/turf/open/floor/rogue/lowered/Initialize()
	.  = ..()
	icon_state = init_icon_state
	var/obj/effect/abstract/liquid_turf/immutable/new_immmutable = SSliquids.get_immutable(immutable_type, src)
	new_immmutable.add_turf(src)
	dir = pick(GLOB.cardinals)

// Bath
/turf/open/floor/rogue/lowered/bath
	icon_state = "bathtileW"
	init_icon_state = "bathtile"

// Sewer
/turf/open/floor/rogue/lowered/sewer
	icon_state = "pavingW"
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/sewer
	init_icon_state = "paving"

// Swamp
/turf/open/floor/rogue/lowered/swamp
	icon_state = "dirtW2"
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/swamp
	init_icon_state = "dirt"

/turf/open/floor/rogue/lowered/swamp/Entered(atom/movable/AM, atom/oldLoc)
	. = ..()
	if(isliving(AM) && !AM.throwing)
		if(!prob(3))
			return
		if(iscarbon(AM))
			var/mob/living/carbon/C = AM
			if(C.blood_volume <= 0)
				return
			var/zonee = list(BODY_ZONE_R_LEG,BODY_ZONE_L_LEG)
			for(var/X in zonee)
				var/obj/item/bodypart/BP = C.get_bodypart(X)
				if(!BP)
					continue
				if(BP.skeletonized)
					continue
				var/obj/item/natural/worms/leech/I = new(C)
				BP.add_embedded_object(I, silent = TRUE)
				return .

/turf/open/floor/rogue/lowered/swamp/deep
	liquid_height = -400
	turf_height = -400
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/swamp/deep

/turf/open/floor/rogue/lowered/swamp/deep/Entered(atom/movable/AM, atom/oldLoc)
	. = ..()
	if(isliving(AM) && !AM.throwing)
		if(!prob(8))
			return
		if(iscarbon(AM))
			var/mob/living/carbon/C = AM
			if(C.blood_volume <= 0)
				return
			var/zonee = list(BODY_ZONE_CHEST,BODY_ZONE_R_LEG,BODY_ZONE_L_LEG,BODY_ZONE_R_ARM,BODY_ZONE_L_ARM)
			for(var/X in zonee)
				var/obj/item/bodypart/BP = C.get_bodypart(X)
				if(!BP)
					continue
				if(BP.skeletonized)
					continue
				var/obj/item/natural/worms/leech/I = new(C)
				BP.add_embedded_object(I, silent = TRUE)
				return .
	
/turf/open/floor/rogue/lowered/cleanshallow
	icon_state = "rockw2"
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/cleanshallow
	init_icon_state = "rock"
	
// это river но без потока. Можно потом заменить на liquid_flow
/turf/open/floor/rogue/lowered/rock
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/grosswater/deep
	icon_state = "rockw2"
	init_icon_state = "rock"

/turf/open/floor/rogue/lowered/river
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/grosswater/deep
	icon_state = "rivermove"
	init_icon_state = "rock"

/turf/open/floor/rogue/lowered/river/Initialize()
	. = ..()
	liquids.forced_flow = dir
	
/turf/open/transparent/openspace/water
	icon_state = "water"
	//turf_height = -300 в комментах чтобы если челу не пришлось перебираться через невидимую в открытой клетке возвышенность.
	liquid_height = -300
	var/immutable_type = /obj/effect/abstract/liquid_turf/immutable/grosswater
	var/init_icon_state = "openspace"
	
/turf/open/transparent/openspace/water/Initialize()
	.  = ..()
	icon_state = init_icon_state
	var/obj/effect/abstract/liquid_turf/immutable/new_immmutable = SSliquids.get_immutable(immutable_type, src)
	new_immmutable.add_turf(src)

/turf/open/transparent/openspace/water/river
	icon_state = "openrivermove"
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/grosswater/river

/turf/open/transparent/openspace/water/river/Initialize()
	..()
	liquids.forced_flow = dir
	
/turf/open/transparent/openspace/water/river/deep
	icon_state = "openrivermove"
	immutable_type = /obj/effect/abstract/liquid_turf/immutable/grosswater/deep/river
