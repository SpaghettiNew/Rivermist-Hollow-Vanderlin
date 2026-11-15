GLOBAL_LIST_INIT(lords_positions, list(
	/datum/job/lord::title,
))
GLOBAL_PROTECT(lords_positions)



GLOBAL_LIST_INIT(keep_positions, list(
	/datum/job/captain::title,
))
GLOBAL_PROTECT(keep_positions)



GLOBAL_LIST_INIT(townhall_positions, list(
	/datum/job/burgmeister::title,
	/datum/job/councilor::title,
	/datum/job/navigator::title,
	/datum/job/servant::title,
))
GLOBAL_PROTECT(townhall_positions)



GLOBAL_LIST_INIT(townwatch_positions, list(
	/datum/job/watch_captain::title,
	/datum/job/watch_sergeant::title,
	/datum/job/watch_veteran::title,
	/datum/job/watch_warden::title,
	/datum/job/watch_guard::title,

))

GLOBAL_PROTECT(townwatch_positions)




GLOBAL_LIST_INIT(chapel_positions, list(
	/datum/job/moon_priest::title,
	/datum/job/heart_priest::title,
	/datum/job/acolyte::title,
))

GLOBAL_PROTECT(chapel_positions)



GLOBAL_LIST_INIT(scholars_positions, list(
	/datum/job/guild_master_wizard::title,
	/datum/job/guild_wizard::title,
	/datum/job/guild_wizard_apprentice::title,
	/datum/job/town_scholar::title,
	/datum/job/town_scholar_apprentice::title,
))
GLOBAL_PROTECT(scholars_positions)



GLOBAL_LIST_INIT(traders_positions, list(
	/datum/job/waterdeep_merchant::title,
	/datum/job/waterdeep_banker::title,
	/datum/job/waterdeep_guild_guard::title,
	/datum/job/waterdeep_guild_assistant::title,
))
GLOBAL_PROTECT(traders_positions)



GLOBAL_LIST_INIT(tavern_positions, list(
	/datum/job/adventurers_guildmaster::title,
	/datum/job/adventurers_assistant::title,
	/datum/job/innkeep::title,
	/datum/job/cook::title,
	/datum/job/matron::title,
	/datum/job/tavern_wench::title,
))
GLOBAL_PROTECT(tavern_positions)



GLOBAL_LIST_INIT(town_positions, list(
	/datum/job/towner::title,
	/datum/job/seelie::title,
	/datum/job/artisan::title,
	/datum/job/artisan_apprentice::title,
))
GLOBAL_PROTECT(town_positions)



GLOBAL_LIST_INIT(outsiders_positions, list(
	/datum/job/forest_warden::title,
	/datum/job/forest_ranger::title,
	/datum/job/grove_druid::title,
	/datum/job/swamp_witch::title,
	/datum/job/ogre::title,
))
GLOBAL_PROTECT(outsiders_positions)



GLOBAL_LIST_INIT(adventurers_positions, list(
	/datum/job/adventurer_barbarian::title,
	/datum/job/adventurer_bard::title,
	/datum/job/adventurer_cleric::title,
	/datum/job/adventurer_druid::title,
	/datum/job/adventurer_fighter::title,
	/datum/job/adventurer_monk::title,
	/datum/job/adventurer_paladin::title,
	/datum/job/adventurer_ranger::title,
	/datum/job/adventurer_rogue::title,
	/datum/job/adventurer_sorcerer::title,
	/datum/job/adventurer_warlock::title,
	/datum/job/adventurer_wizard::title,
))
GLOBAL_PROTECT(adventurers_positions)

GLOBAL_LIST_INIT(villains_positions, list(
	/datum/job/bandit::title,
	/datum/job/werewolf::title,
	/datum/job/succubus::title,
	/datum/job/gnoll::title,
))
GLOBAL_PROTECT(villains_positions)

GLOBAL_LIST_INIT(roguewar_positions, list(
	"Adventurer",
	))

GLOBAL_LIST_INIT(test_positions, list(
	"Tester",
	))

GLOBAL_LIST_EMPTY(job_assignment_order)

/proc/get_job_assignment_order()
	var/list/sorting_order = list()
	sorting_order += GLOB.lords_positions
	sorting_order += GLOB.keep_positions
	sorting_order += GLOB.townhall_positions
	sorting_order += GLOB.townwatch_positions
	GLOB.townwatch_positions += "Town Watch Militia" // Resolving new militia class
	sorting_order += GLOB.chapel_positions
	sorting_order += GLOB.scholars_positions
	sorting_order += GLOB.traders_positions
	sorting_order += GLOB.tavern_positions
	sorting_order += GLOB.town_positions
	sorting_order += GLOB.outsiders_positions
	sorting_order += GLOB.adventurers_positions
	sorting_order += GLOB.villains_positions
	return sorting_order

GLOBAL_LIST_INIT(exp_specialmap, list(
	EXP_TYPE_LIVING = list(), // all living mobs
	EXP_TYPE_ANTAG = list(),
	EXP_TYPE_GHOST = list(), // dead people, observers
))
GLOBAL_PROTECT(exp_specialmap)
