/datum/attribute_holder/sheet/job/forest_warden
	raw_attribute_list = list(
		/datum/attribute/skill/misc/hunting = 40,
		/datum/attribute/skill/misc/tracking = 40,
		STAT_STRENGTH = 2,
		STAT_PERCEPTION = 1,
		STAT_INTELLIGENCE = 1,
		STAT_ENDURANCE = 3,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/axesmaces = 40,
		/datum/attribute/skill/combat/bows = 40,
		/datum/attribute/skill/combat/crossbows = 20,
		/datum/attribute/skill/combat/wrestling = 40,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/knives = 30,
		/datum/attribute/skill/misc/swimming = 30,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/misc/riding = 30,
		/datum/attribute/skill/craft/crafting = 20,
		/datum/attribute/skill/labor/lumberjacking = 10,
		/datum/attribute/skill/craft/carpentry = 10,
		/datum/attribute/skill/misc/sewing = 10,
		/datum/attribute/skill/craft/tanning = 20
	)

/datum/job/forest_warden
	title = "Forest Warden"
	tutorial = "Raised among trees and mist, you know the forests and swamps around Rivermist Hollow better than any map. \
	Appointed by the Council, you lead the Forest Rangers in guarding the wild borders, guiding travelers, and keeping old dangers in check."
	department_flag = OUTSIDERS
	faction = FACTION_NEUTRAL
	total_positions = 1
	spawn_positions = 1
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_FOREST_WARDEN

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST

	selection_color = JCOLOR_OUTSIDERS
	outfit = /datum/outfit/forest_warden

	give_bank_account = 45
	daily_salary = 10

	exp_type = list(EXP_TYPE_GARRISON)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT, EXP_TYPE_LEADERSHIP)
	exp_requirements = list(
		EXP_TYPE_GARRISON = 900
	)

	outfit = /datum/outfit/forest_warden
	spells = list(/datum/action/cooldown/spell/undirected/list_target/convert_role/forest_ranger)

	job_bitflag = BITFLAG_GARRISON
	honorary = "Warden"

	attribute_sheet = /datum/attribute_holder/sheet/job/forest_warden


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_HEAVYARMOR,
		TRAIT_NOBLE,
		TRAIT_FORAGER,
		TRAIT_SEEDKNOW,
		TRAIT_OLDPARTY,
		TRAIT_DEADNOSE,
		TRAIT_BESTIALSENSE,
	)

/datum/job/forest_warden/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.update_sight()
	add_verb(spawned, /mob/proc/haltyell)

/datum/outfit/forest_warden
	name = "Forest Warden"
	head = /obj/item/clothing/head/helmet/visored/warden
	mask = null
	neck = /obj/item/clothing/neck/bevor
	cloak = /obj/item/clothing/cloak/wardencloak
	armor = /obj/item/clothing/armor/plate
	shirt = /obj/item/clothing/armor/chainmail
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/leather
	pants = /obj/item/clothing/pants/platelegs
	shoes = /obj/item/clothing/shoes/boots
	backr = /obj/item/weapon/greataxe
	backl = /obj/item/storage/backpack/backpack/longhike
	belt = /obj/item/storage/belt/leather/fgarrison
	beltl = /obj/item/weapon/axe/iron
	beltr = /obj/item/storage/belt/pouch/cloth/coins/mid
	ring = null
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/weapon/knife/hunting = 1,
		/obj/item/rope/chain = 1,
		/obj/item/signal_horn = 1
	)

//CONVERSION
/datum/action/cooldown/spell/undirected/list_target/convert_role/forest_ranger
	name = "Recruit Forest Ranger"

	new_role = "Forest Rangers Recruit"
	recruitment_faction = "Forest Rangers"
	recruitment_message = "Join the Forest Rangers, %RECRUIT!"
	accept_message = "I swear to protect the forest!"
