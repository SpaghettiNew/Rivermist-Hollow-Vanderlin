/datum/job/watch_warden
	title = "Town Watch Warden"
	tutorial = "You are a Warden of the Town Watch. \
	You oversee prisoners, guard the town gates, and ensure that sentences are carried out lawfully. \
	High pain tolerance and experise in hand-to-hand combat are the things that make you stand out from the rest of the Watch. \
	In the other hand, some parts of the training were osolette, and you are not as skilled with ranged weapons enough as the others"
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_WARDEN
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	advclass_cat_rolls = list(CAT_WARDEN = 20)

	job_subclasses = list(
		/datum/job/advclass/watch_warden/executioner,
		/datum/job/advclass/watch_warden/prosecutor,
		/datum/job/advclass/watch_warden/juggernaut,
	)

	give_bank_account = 125
	daily_salary = 20

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT)
	exp_requirements = list(
		EXP_TYPE_LIVING = 450
	)

	job_bitflag = BITFLAG_GARRISON

/datum/job/watch_warden/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.verbs |= /mob/proc/haltyell

////////////////////////////////////////
// ADVCLASS BASE – WARDEN //
////////////////////////////////////////

/datum/job/advclass/watch_warden

////////////////////////////////////////
// prosecutor WARDEN //
////////////////////////////////////////
/datum/job/advclass/watch_warden/prosecutor
	title = "Prosecutor"
	tutorial = "Your specialty is prosecution. \
	While being the most mobile, than the other wardens, you are compitent enough to use the crossbows. Pistols, bows and muskets are not your style. \
	Your duty is vigilance, containment, and control — not mercy, not glory. \
	Additional training in various methods of restraint makes you profficent, even though lack of heavy armor training you make stand out from others..."

	outfit = /datum/outfit/watch_warden/prosecutor
	category_tags = list(CAT_WARDEN = 20)

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_warden/prosecutor

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_CHUNKYFINGERS,
		TRAIT_STRONG_GRABBER,
		TRAIT_CRATEMOVER,
		TRAIT_TUTELAGE,
		TRAIT_KNOWBANDITS,
		TRAIT_MEDIUMARMOR,
		TRAIT_TRUE_GRIT,
		TRAIT_BLACKBAGGER
	)

/datum/attribute_holder/sheet/job/watch_warden/prosecutor
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_CONSTITUTION = 2,
		STAT_ENDURANCE = 2,
		STAT_PERCEPTION = 1,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/wrestling = 35,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/whipsflails = 40,
		/datum/attribute/skill/combat/swords = 10,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/misc/athletics = 25,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/craft/traps = 30
	)

/datum/outfit/watch_warden/prosecutor
	name = "Town Watch Prosecutor"
	head = /obj/item/clothing/head/helmet/townwatch/town_warden
	mask = null
	neck = /obj/item/clothing/neck/coif
	cloak = /obj/item/clothing/cloak/wardencloak
	armor = /obj/item/clothing/armor/gambeson/arming
	shirt = /obj/item/clothing/shirt/undershirt/formal
	wrists = /obj/item/clothing/wrists/bracers/leather
	gloves = /obj/item/clothing/gloves/bandages/weighted
	pants = /obj/item/clothing/pants/grenzelpants
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = /obj/item/weapon/whip/nagaika
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
		/obj/item/clothing/head/inqarticles/blackbag
	)

////////////////////////////////////////
// Executioner WARDEN //
////////////////////////////////////////
/datum/job/advclass/watch_warden/executioner

	title = "Executioner"
	tutorial = "You are a Executioner of the Town Watch. \
	You oversee prisoners, wait for the execution of sentences, and ensure that the captives are properly punished. \
	The training you received made you a formidable opponent in point-blank combat. The poleaxe is your weapon of choice, and you are trained to use it with deadly efficiency. \
	However, your lack of training in ranged combat makes you less effective at a distance."

	outfit = /datum/outfit/watch_warden/executioner
	category_tags = list(CAT_WARDEN = 20)

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_warden/executioner

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_CHUNKYFINGERS,
		TRAIT_STRONG_GRABBER,
		TRAIT_CRATEMOVER,
		TRAIT_TUTELAGE,
		TRAIT_KNOWBANDITS,
		TRAIT_MEDIUMARMOR,
		TRAIT_TRUE_GRIT,
		TRAIT_NOSEGRAB,
		TRAIT_NOGUNS,
		TRAIT_UNDODGING,
	)

/datum/attribute_holder/sheet/job/watch_warden/executioner
	raw_attribute_list = list(
		STAT_STRENGTH = 3,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 2,
		STAT_PERCEPTION = 1,
		/datum/attribute/skill/combat/wrestling = 35,
		/datum/attribute/skill/combat/unarmed = 35,
		/datum/attribute/skill/combat/whipsflails = 5,
		/datum/attribute/skill/combat/swords = 15,
		/datum/attribute/skill/combat/axesmaces = 50,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 10,
		/datum/attribute/skill/craft/traps = 20
	)

/datum/outfit/watch_warden/executioner
	name = "Town Watch Executioner"
	head = /obj/item/clothing/head/helmet/decorativecoppergate
	mask = /obj/item/clothing/face/facemask/silver
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/cloak/wardencloak
	armor = /obj/item/clothing/armor/leather/jacket/gatemaster_jacket
	shirt = /obj/item/clothing/armor/gambeson/arming
	wrists = /obj/item/clothing/wrists/bracers/iron
	gloves = /obj/item/clothing/gloves/chain/psydon
	pants = /obj/item/clothing/pants/tights/colored/guardsecond
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/greataxe/steel
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = null
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
		/obj/item/clothing/head/menacing
	)

////////////////////////////////////////
// Juggernaut WARDEN //
////////////////////////////////////////
/datum/job/advclass/watch_warden/juggernaut
	title = "Iron Clad Watch"
	tutorial = "You are a Juggernaut of the Town Watch. \
	As the other wardens, you are responsible for prisoners, and ensure that sentences are carried out lawfully. \
	Your way is one of brute force and unwavering determination. No one is a match for you in hand-to-hand combat. Heavy armor training made you stronger than the others in the corps."

	outfit = /datum/outfit/watch_warden/juggernaut
	category_tags = list(CAT_WARDEN = 20)

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_warden/juggernaut

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_CHUNKYFINGERS,
		TRAIT_STRONG_GRABBER,
		TRAIT_CRATEMOVER,
		TRAIT_TUTELAGE,
		TRAIT_KNOWBANDITS,
		TRAIT_HEAVYARMOR,
		TRAIT_NOSEGRAB,
		TRAIT_EARGRAB,
		TRAIT_NOGUNS,
		TRAIT_UNDODGING,
		TRAIT_AMAZING_BACK
	)

/datum/attribute_holder/sheet/job/watch_warden/juggernaut
	raw_attribute_list = list(
		STAT_STRENGTH = 4,
		STAT_CONSTITUTION = 2,
		STAT_ENDURANCE = 2,
		STAT_PERCEPTION = 1,
		STAT_SPEED = -1,
		/datum/attribute/skill/combat/wrestling = 45,
		/datum/attribute/skill/combat/unarmed = 45,
		/datum/attribute/skill/combat/whipsflails = 15,
		/datum/attribute/skill/combat/swords = 15,
		/datum/attribute/skill/combat/axesmaces = 25,
		/datum/attribute/skill/misc/athletics = 35,
	)

/datum/outfit/watch_warden/juggernaut
	name = "Town Watch Jugguernaut"
	head = /obj/item/clothing/head/helmet/visored/warden
	mask = /obj/item/clothing/face/skullmask
	neck = /obj/item/clothing/neck/highcollier
	cloak = /obj/item/clothing/cloak/wardencloak
	armor = /obj/item/clothing/armor/plate/decorated
	shirt = /obj/item/clothing/shirt/robe/faceless
	wrists = /obj/item/clothing/wrists/bracers/iron
	gloves = /obj/item/clothing/gloves/plate
	pants = /obj/item/clothing/pants/trou/leather/splint
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = null
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /datum/supply_pack/weapons/steel/knuckles
	r_hand = /datum/supply_pack/weapons/steel/knuckles

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/rope/net/bola,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern
	)
