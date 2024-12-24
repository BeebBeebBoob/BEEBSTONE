/* Example
/obj/effect/abstract/liquid_turf/immutable/ocean
	smoothing_flags = NONE
	icon_state = "ocean"
	base_icon_state = "ocean"
	layer = FLY_LAYER
	plane = ABOVE_GAME_PLANE
	starting_temp = T20C-150
	no_effects = TRUE
	vis_flags = NONE

/obj/effect/abstract/liquid_turf/immutable/ocean/warm
	starting_temp = T20C+20
*/

// LIQUID_HEIGHT_CONSIDER_FULL_TILE дефайн максимум воды. 800
/obj/effect/abstract/liquid_turf/immutable/grosswater
	starting_mixture = list(/datum/reagent/water/gross = 300)
	starting_temp = T0C

/obj/effect/abstract/liquid_turf/immutable/grosswater/river
	
/obj/effect/abstract/liquid_turf/immutable/grosswater/deep
	starting_mixture = list(/datum/reagent/water/gross = 800)

/obj/effect/abstract/liquid_turf/immutable/grosswater/deep/river

/obj/effect/abstract/liquid_turf/immutable/sewer
	starting_mixture = list(/datum/reagent/water/gross/muddy = 150)
	starting_temp = T20C-50

/obj/effect/abstract/liquid_turf/immutable/swamp
	starting_mixture = list(/datum/reagent/water/gross/muddy = 250)
	starting_temp = T20C-50

/obj/effect/abstract/liquid_turf/immutable/swamp/deep
	starting_mixture = list(/datum/reagent/water/gross/muddy = 800)

/obj/effect/abstract/liquid_turf/immutable/cleanshallow
	starting_mixture = list(/datum/reagent/water = 250)
	starting_temp = T0C+10
