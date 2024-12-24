#define LIQUID_STATE_PUDDLE 1 // A puddle. goblets or bucket.
#define LIQUID_STATE_ANKLES 2 // Shoe-deep, wet shoes. Room spilled with couple of barrels.
#define LIQUID_STATE_WAIST 3 // Knee-deep, slowdown by 1?
#define LIQUID_STATE_SHOULDERS 4 // Body-deep, slowdown by 3?
#define LIQUID_STATE_FULLTILE 5 // Full, risk drowning?

#define LIQUID_HEIGHT_ANKLES 100
#define LIQUID_HEIGHT_WAIST 200
#define LIQUID_HEIGHT_SHOULDERS 300
#define LIQUID_HEIGHT_FULLTILE 400
#define TOTAL_LIQUID_STATES 5

// скайратовские дефайны
#define WATER_HEIGH_DIFFERENCE_SOUND_CHANCE 50
#define WATER_HEIGH_DIFFERENCE_DELTA_SPLASH 7 //Delta needed for the splash effect to be made in 1 go

#define PARTIAL_TRANSFER_AMOUNT 0.3

#define LIQUID_MUTUAL_SHARE 1
#define LIQUID_NOT_MUTUAL_SHARE 2

#define LIQUID_GIVER 1
#define LIQUID_TAKER 2

//Required amount of a reagent to be simulated on turf exposures from liquids (to prevent gaming the system with cheap dillutions)
#define LIQUID_REAGENT_THRESHOLD_TURF_EXPOSURE 5

//Threshold at which the difference of height makes us need to climb/blocks movement/allows to fall down
#define TURF_HEIGHT_BLOCK_THRESHOLD 20

#define LIQUID_ATTRITION_TO_STOP_ACTIVITY 2

//Perceived heat capacity for calculations with atmos sharing
#define REAGENT_HEAT_CAPACITY 5

#define LYING_DOWN_SUBMERGEMENT_STATE_BONUS 2

//Threshold at which we "choke" on the water, instead of holding our breath
#define OXYGEN_DAMAGE_CHOKING_THRESHOLD 15

#define IMMUTABLE_LIQUID_SHARE 1

#define LIQUID_RECURSIVE_LOOP_SAFETY 100 //Hundred loops at maximum for adjacency checking

//Height at which we consider the tile "full" and dont drop liquids on it from the upper Z level
#define LIQUID_HEIGHT_CONSIDER_FULL_TILE 800

#define SSLIQUIDS_RUN_TYPE_TURFS 1
#define SSLIQUIDS_RUN_TYPE_GROUPS 2
#define SSLIQUIDS_RUN_TYPE_IMMUTABLES 3

#define LIQUID_GROUP_DECAY_TIME 3

//Scaled with how much a person is submerged
#define SUBMERGEMENT_REAGENTS_TOUCH_AMOUNT 0.6 //60%

#define CHOKE_REAGENTS_INGEST_ON_FALL_AMOUNT 4

#define CHOKE_REAGENTS_INGEST_ON_BREATH_AMOUNT 2

#define TICK_DROWN 3 SECONDS
#define FIRST_DROWN_CHANCE 10
#define DEFAULT_DROWN_CHANCE 10

#define LEVEL_FALL_DROWN_MULTIPLIER 10
#define WEIGHT_DROWN_MULTIPLIER 20
#define SKILL_DROWN_MULTIPLIER 15

#define MINIMUM_DROWN_CHANCE 5 // % every tick

// carbon, liquids
#define SUBMERGEMENT_PERCENT(C, L) min(1,((C.mobility_flags & MOBILITY_STAND) ? L.liquid_state+LYING_DOWN_SUBMERGEMENT_STATE_BONUS : L.liquid_state) / TOTAL_LIQUID_STATES)

#define BREATHE_UNDERWATER_CHECK(C, L) ((!(C.mobility_flags & MOBILITY_STAND) && L.liquid_state >= LIQUID_STATE_WAIST) || ((C.mobility_flags & MOBILITY_STAND) && L.liquid_state >= LIQUID_STATE_FULLTILE))
