/datum/attribute_holder/sheet/job/advclass/burgmeister/lord_captain
	raw_attribute_list = list(
		STAT_STRENGTH = 3,
		STAT_ENDURANCE = 3,
		STAT_CONSTITUTION = 2,
		STAT_PERCEPTION = 3,
		STAT_SPEED = 2,
		STAT_INTELLIGENCE = 2,
		STAT_FORTUNE = 1,

		/datum/attribute/skill/combat/swords = 35,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/shields = 25,
		/datum/attribute/skill/combat/bows = 20,
		/datum/attribute/skill/combat/crossbows = 20,
		/datum/attribute/skill/combat/wrestling = 25,

		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/swimming = 30,
		/datum/attribute/skill/misc/climbing = 25,
		/datum/attribute/skill/misc/reading = 20,
		/datum/attribute/skill/misc/sneaking = 10
	)

/datum/job/advclass/burgmeister/lord_captain
	title = "Lord Captain"
	tutorial = "You are the master of a vessel, a commander of men upon the open waters. Your authority is absolute aboard your ship."

	outfit = /datum/outfit/burgmeister/lord_captain
	category_tags = list(CAT_BURGMESITER)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/burgmeister/lord_captain

	traits = list(
		TRAIT_KNOW_WATCH,
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_CAN_STEER_SHIP,
		TRAIT_MEDIUMARMOR,
		TRAIT_DODGEEXPERT,
		TRAIT_BREADY,
		TRAIT_EMPATH,
		TRAIT_KEENEARS,
		TRAIT_SEEPRICES
	)

// OUTFIT

/datum/outfit/burgmeister/lord_captain
	name = "Lord Captain"
	head = /obj/item/clothing/head/helmet/leather/tricorn/treasure_island
	mask = /obj/item/clothing/head/wig
	neck = /obj/item/clothing/neck/formal
	cloak = /obj/item/clothing/cloak/ordinatorcape/townhall
	armor = /obj/item/clothing/armor/gambeson/treasure_island/blue
	shirt = /obj/item/clothing/shirt/undershirt/fancy
	wrists = /obj/item/storage/keyring/rmh_burgmeister
	gloves = null
	pants = /obj/item/clothing/pants/trou/leather/advanced/colored/duelpants/townhall
	shoes = /obj/item/clothing/shoes/simpleshoes/buckle
	backr = /obj/item/storage/backpack/satchel
	backl = null
	belt = /obj/item/storage/belt/leather/plaquegold
	beltr = /obj/item/storage/belt/pouch/coins/veryrich
	beltl = /obj/item/weapon/scabbard/sword/noble
	ring = /obj/item/clothing/ring/slave_control/master
	l_hand = /obj/item/weapon/lordscepter
	r_hand = /obj/item/weapon/sword/sabre

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/bullets,
		/obj/item/reagent_containers/glass/bottle/aflask,
		/obj/item/gun/ballistic/revolver/grenadelauncher/pistol,
		/obj/item/clothing/neck/slave_collar,
	)
