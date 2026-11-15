// Coin base_type identifiers.
#define CTYPE_GUILD "t"

// Smallclothes preference save keys.
#define SMALCLOTHES_RANDOM_PREFERENCES "Random Preferences"
#define SMALCLOTHES_UNDIE_PREFERENCES "Undies Preferences"
#define SMALCLOTHES_UNDIE_COLOR_PREFERENCES "Undies Color"
#define SMALCLOTHES_LEGWEAR_PREFERENCES "Legwear Preferences"
#define SMALCLOTHES_LEGWEAR_COLOR_PREFERENCES "Legwear Color"
#define SMALCLOTHES_BRA_PREFERENCES "Bra Preferences"
#define SMALCLOTHES_BRA_COLOR_PREFERENCES "Bra Color"
#define SMALCLOTHES_GARTER_PREFERENCES "Garter Preferences"
#define SMALCLOTHES_GARTER_COLOR_PREFERENCES "Garter Color"
#define SMALCLOTHES_UNDERSHIRT_PREFERENCES "Undershirt Preferences"
#define SMALCLOTHES_UNDERSHIRT_COLOR_PREFERENCES "Undershirt Color"
#define SMALCLOTHES_ARMSLEEVE_PREFERENCES "Armsleeve Preferences"
#define SMALCLOTHES_ARMSLEEVE_COLOR_PREFERENCES "Armsleeve Color"

// Arousal component tuning.
#define ARO_LOSS_COEFFICIENT 10

// Body storage layer identifiers.
#define STORAGE_LAYER_OUTER "layer_outer"
#define STORAGE_LAYER_INNER "layer_inner"
#define STORAGE_LAYER_DEEP "layer_deep"

// Body storage insertion feedback codes.
#define INSERT_FEEDBACK_OK "feedback_ok"
#define INSERT_FEEDBACK_OK_FORCE "feedback_ok_force"
#define INSERT_FEEDBACK_OK_OVERRIDE "feedback_override"
#define INSERT_FEEDBACK_ALMOST_FULL "feedback_almost"
#define INSERT_FEEDBACK_STUFFED "feedback_stuffed"
#define INSERT_FEEDBACK_TRY_FORCE "feedback_try_force"
#define INSERT_FEEDBACK_BLOCKED "feedback_blocked"

// Body storage default capacity tuning.
#define OUTER_LAYER_DEFAULT_BULK 1
#define INNER_LAYER_DEFAULT_BULK 8
#define DEEP_LAYER_DEFAULT_BULK 15

#define HOLE_MAX_BULK_INSERT 10 //we want to have it possible that a sufficiently big insertible will trigger stretching on it's own

// RMH object smoothing groups. S_OBJ(1-7) are occupied by core structures.
#define SMOOTH_GROUP_TENTACLE_GROWTH S_OBJ(8)

// Gradient-map palettes for the greyscale tentacle sheets. Colours are in GLOB.tentacle_palettes.
#define TENTACLE_PALETTE_PINK "pink"
#define TENTACLE_PALETTE_CAVE "cave"
#define TENTACLE_PALETTE_GROUND "ground"
#define TENTACLE_PALETTE_GRASS "grass"
#define TENTACLE_PALETTE_COLONY "colony"
#define TENTACLE_PALETTE_VINE "vine"

// Oviposition egg type identifiers.
#define OVI_EGG_NORMAL "normal_ovi"
#define OVI_EGG_AVIAN "avian_ovi"
#define OVI_EGG_SOFTSHELL "softshell_ovi"
#define OVI_EGG_PARASITIC "parasitic_ovi"
#define OVI_EGG_SPIDER "spider_ovi"
#define OVI_EGG_BOG_BUG "bog_bug_ovi"
#define OVI_EGG_HARPY "harpy_ovi"
#define OVI_EGG_EMBRYO "embryo_ovi"
#define OVI_EGG_LEECH "leech_ovi"
#define OVI_EGG_TENTACLE "tentacle_ovi"
#define OVI_EGG_MANEATER "maneater_ovi"
#define OVI_EGG_MOTHBUG "mothbug_ovi"

// Oviposition customization and balance limits.
#define OVI_EGG_MAX_CLUTCH 30
#define OVI_EGG_DEFAULT_SCALE 1
#define OVI_EGG_MIN_SCALE 0.5
#define OVI_EGG_MAX_SCALE 2
/// Width in centimetres a ripe egg passes the opening with at scale one, unless its profile says otherwise.
#define OVI_EGG_DEFAULT_BIRTH_GIRTH 15
/// Residue units a trait adds to what a birth leaves in the canal, and the sting venom leaves.
#define OVI_EGG_RESIDUE_APHRODISIAC 2
#define OVI_EGG_RESIDUE_VENOM 0.5
#define OVI_EGG_RESIDUE_VENOM_SORENESS 5
/// Aphrodisiac units a laced egg holds and leaves behind.
#define OVI_EGG_LACE_UNITS 2
/// Share of the birth residue an egg leaves in the canal on the way in.
#define OVI_EGG_DEPOSIT_RESIDUE_SHARE 0.5
/// A fresh egg passes the opening at this share of its ripe width.
#define OVI_EGG_LAY_GIRTH_SHARE 0.5
/// Act cycles per egg in a lay act; speed shortens the cycles, not the count.
#define LAY_EGG_CYCLES_PER_EGG 4
/// Eggs one lay act lays before it ends spent for now.
#define LAY_EGG_ACT_CAP 3
/// Eggs a climax rush pushes at most, and after an act that laid its cap.
#define LAY_EGG_RUSH_CAP 2
#define LAY_EGG_RUSH_CAP_AFTER_CAP 1
/// Creature ovipositors regrow eggs this many times slower than a player's.
#define OVI_CREATURE_STAGE_TIME_MULTIPLIER 2
/// Chance per minute that a ripe egg starts labour, for kinds without a fixed delay.
#define OVI_EGG_LABOUR_CHANCE 10
// How an egg kind hatches: on the floor once laid, inside its host, or either by a roll.
#define OVI_HATCH_OUTSIDE 1
#define OVI_HATCH_INSIDE 2
#define OVI_HATCH_EITHER 3
/// Points the host's fill adds to an either-roll, for fluid and for stored bulk, and the roll's cap.
#define OVI_HATCH_FILL_FLUID_POINTS 40
#define OVI_HATCH_FILL_BULK_POINTS 20
#define OVI_HATCH_CHANCE_CAP 95
/// A ripe outside egg that cannot be laid for this long hatches inside after all.
#define OVI_HATCH_BLOCKED_GRACE (5 MINUTES)
/// Throat width a stomach passenger must fit to be brought up by the mouth.
#define OVI_RETCH_MAX_GIRTH 15
// How a hatchling inside leaves on its own.
#define HATCHLING_LEAVE_NEVER 0
#define HATCHLING_LEAVE_AFTER_DELAY 1
#define HATCHLING_LEAVE_WHEN_GROWN 2
#define OVI_EGG_MAX_CUSTOM_NAME_LENGTH 96
#define OVI_EGG_MAX_CUSTOM_DESC_LENGTH 512
#define OVI_EGG_STAGE_TIME 1 MINUTES
/// Creatures one body may hatch from eggs and embryos in the window; growing creature eggs hold slots too.
#define OVIPOSITION_BIRTH_LIMIT 6
#define OVIPOSITION_BIRTH_LIMIT_WINDOW (30 MINUTES)
/// How often a body with eggs held by the limit checks for a free slot, at most.
#define OVIPOSITION_HELD_EGG_RECHECK (1 MINUTES)
// What start_oviposition_egg_growth() did; HELD is truthy: the egg landed and lies dormant.
#define OVI_EGG_GROWTH_STARTED 1
#define OVI_EGG_GROWTH_HELD 2

// Oviposition egg modifier flags.
#define OVI_EGG_TRAIT_APHRODISIAC "aphrodisiac"
#define OVI_EGG_TRAIT_POISON "poison"
#define OVI_EGG_TRAIT_PARASITE "parasite"
#define OVI_EGG_TRAIT_FAST_GROWTH "fast_growth"

//Social stealth related defines including factions
//
#define SOCIAL_RELATION_ALLIED             "allied"
#define SOCIAL_RELATION_HOSTILE            "hostile"
#define SOCIAL_RELATION_PROTECT_DUTY       "protect_duty"
#define SOCIAL_RELATION_DIPLOMATIC_HOSTILE "diplomatic_hostile"
#define SOCIAL_RELATION_HOSTILE_TO_WATCH   "hostile_to_watch"
#define SOCIAL_RELATION_TENSE              "tense"
#define SOCIAL_RELATION_NEUTRAL            "neutral"
#define SOCIAL_RELATION_COOPERATIVE       "cooperative"
#define SOCIAL_RELATION_HIGHER_RANK       "higher_rank"
#define SOCIAL_RELATION_LOYAL              "loyal"
#define SOCIAL_RELATION_FEARFUL	    		"fearful"
#define SOCIAL_RELATION_SEPARATED_AUTHORITY "separated_authority"
#define SOCIAL_RELATION_DISAGREEING         "disagreeing"


#define SOCIAL_SOURCE_KNOWLEDGE   (1 << 0)
#define SOCIAL_SOURCE_COSMETIC    (1 << 1)
#define SOCIAL_SOURCE_IDENTITY    (1 << 2)
#define SOCIAL_SOURCE_PERSONNEL   (1 << 3)
#define SOCIAL_SOURCE_STATUS      (1 << 4)
#define SOCIAL_SOURCE_ELITE       (1 << 5)
#define SOCIAL_SOURCE_PRESTIGE    (1 << 6)

#define SOCIAL_LEVEL_UNKNOWN      0
#define SOCIAL_LEVEL_APPARENT     1
#define SOCIAL_LEVEL_KNOWN        2

#define SOCIAL_PRESENTATION_INSUFFICIENT 0
#define SOCIAL_PRESENTATION_RECOGNIZABLE 1
#define SOCIAL_PRESENTATION_CONVINCING   2

#define SOCIAL_LEGITIMACY_UNKNOWN       "unknown"
#define SOCIAL_LEGITIMACY_PARTIAL       "partial"
#define SOCIAL_LEGITIMACY_SOLID         "solid"
#define SOCIAL_LEGITIMACY_SUSPICIOUS    "suspicious"
#define SOCIAL_LEGITIMACY_DISGUISED     "disguised"

#define SOCIAL_PRESTIGE_THRESHOLD 5

#define TOWNWATCH_COMMAND_MEMBER 0
#define TOWNWATCH_COMMAND_SERGEANT 1
#define TOWNWATCH_COMMAND_CAPTAIN 2

#define TOWNWATCH_ORDER_ATTACK "attack"
#define TOWNWATCH_ORDER_MOVEMENT "movement"
#define TOWNWATCH_ORDER_DEFENSE "defense"

#define TOWNWATCH_COMMAND_MODE_TARGETED "targeted"
#define TOWNWATCH_COMMAND_MODE_GLOBAL "global"

#define TOWNWATCH_COMMAND_RANGE 7
#define TOWNWATCH_TARGETED_COMMAND_COOLDOWN (20 SECONDS)
#define TOWNWATCH_GLOBAL_COMMAND_COOLDOWN (60 SECONDS)
/// What kind of part a slot takes. Prosthetic options and implants list the kinds they fit.
#define PROSTHETIC_KIND_ARM "arm"
#define PROSTHETIC_KIND_LEG "leg"
#define PROSTHETIC_KIND_EYE "eye"
#define PROSTHETIC_KIND_HEART "heart"
#define PROSTHETIC_KIND_LUNGS "lungs"
#define PROSTHETIC_KIND_TONGUE "tongue"
// Hypnosis
#define HYPNOSIS_RANGE 2
#define HYPNOSIS_PENDING_TIME (10 MINUTES)
#define HYPNOSIS_REMINDER_TIME (20 MINUTES)
#define HYPNOSIS_MAX_DURATION (90 MINUTES)
#define HYPNOSIS_PROMPT_TIMEOUT (15 SECONDS)
#define HYPNOSIS_SELF_RELEASE_TIME (15 SECONDS)
#define HYPNOSIS_DAZE_DURATION (30 SECONDS)
#define HYPNOSIS_TRIGGER_COOLDOWN (1 MINUTES)
#define HYPNOSIS_TRIGGER_MAX_LENGTH 60
#define HYPNOSIS_EXAMINE_MAX_LENGTH 100
/// Willpower at which a target may refuse each trance.
#define HYPNOSIS_WILL_PROMPT 13
/// Willpower at which a hypnotized person may break free alone.
#define HYPNOSIS_WILL_SELF_RELEASE 15
#define HYPNOSIS_MODE_SUGGESTION "suggestion"
#define HYPNOSIS_MODE_TRIGGER "trigger"
#ifndef HEARING_RADIO_FREQ
#define HEARING_RADIO_FREQ 5
#endif
#ifndef HEARING_MESSAGE_MODE
#define HEARING_MESSAGE_MODE 7
#endif

/// Added to the victim's perception when a sneaking thief goes for their underwear.
#define UNDERWEAR_STEAL_PERCEPTION_BONUS 3
/// Multiplies pickpocket time for underwear theft.
#define UNDERWEAR_STEAL_TIME_MULT 2
