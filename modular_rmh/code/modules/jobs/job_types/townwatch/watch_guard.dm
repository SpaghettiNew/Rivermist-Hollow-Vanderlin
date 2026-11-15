/datum/job/watch_guard
	title = "Town Watch Guard"
	tutorial = "You are a member of the Town Watch. \
	You patrol streets, guard gates and buildings, respond to disturbances, \
	and uphold the laws of Rivermist Hollow."
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_GUARD
	faction = FACTION_TOWN
	total_positions = 8
	spawn_positions = 8

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	advclass_cat_rolls = list(CAT_WATCHMAN = 20)


	job_subclasses = list(
		/datum/job/advclass/watch_guard/bulwark,
		/datum/job/advclass/watch_guard/halberdier,
		/datum/job/advclass/watch_guard/sentinel,
		/datum/job/advclass/watch_guard/marine,
		/datum/job/advclass/watch_guard/disciplinary,
	)

	give_bank_account = 75
	daily_salary = 20

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT)
	exp_requirements = list(
		EXP_TYPE_LIVING = 300
	)

	job_bitflag = BITFLAG_GARRISON

/datum/job/watch_guard/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.verbs |= /mob/proc/haltyell


////////////////////////////////////////
// ADVCLASS BASE – WATCH GUARD //
////////////////////////////////////////

/datum/job/advclass/watch_guard
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT)


//////////////////////////////////
// BULWARK //
//////////////////////////////////

/datum/attribute_holder/sheet/job/advclass/watch_guard/bulwark
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 4,
		STAT_CONSTITUTION = 3,
		/datum/attribute/skill/combat/axesmaces = 40,
		/datum/attribute/skill/combat/shields = 40,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 40,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/watch_guard/bulwark
	title = "Town Watch Bulwark"
	tutorial = "You serve as the shield of the Town Watch. \
	Trained to hold chokepoints, endure riots, and protect others behind your guard, \
	you are the steady wall against chaos."

	outfit = /datum/outfit/watch_guard/bulwark
	category_tags = list(CAT_WATCHMAN)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/watch_guard/bulwark


	traits = list(
		TRAIT_HEAVYARMOR,
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS
	)
/datum/job/advclass/watch_guard/bulwark/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/weapons = list("Sword", "Axe")
	var/weapon_choice = browser_input_list(spawned, "CHOOSE YOUR WEAPON.", "TAKE UP ARMS", weapons)

	switch(weapon_choice)
		if("Sword")
			spawned.put_in_hands(new /obj/item/weapon/sword/arming(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/weapon/scabbard/sword(get_turf(spawned)), TRUE)
		if("Axe")
			spawned.put_in_hands(new /obj/item/weapon/axe/steel(get_turf(spawned)), TRUE)


/datum/outfit/watch_guard/bulwark
	name = "Town Watch Bulwark"
	head = /obj/item/clothing/head/helmet/townwatch/gatemaster/bulwark
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/leather/jacket/gatemaster_jacket/armored/bulwark
	shirt = /obj/item/clothing/armor/gambeson/heavy/colored/town_watch
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/chain
	pants = /obj/item/clothing/pants/chainlegs
	shoes = /obj/item/clothing/shoes/boots/armor/light
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/shield/heater
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
	)

//////////////////////////////////
// HALBERDIER //
//////////////////////////////////

/datum/attribute_holder/sheet/job/advclass/watch_guard/halberdier
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 2,
		STAT_CONSTITUTION = 2,
		/datum/attribute/skill/combat/polearms = 40,
		/datum/attribute/skill/combat/swords = 20,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/watch_guard/halberdier
	title = "Town Watch Halberdier"
	tutorial = "You wield long weapons to control space and repel attackers. \
	Deadly in formation, \
	you are essential at gates, bridges, and narrow streets."

	outfit = /datum/outfit/watch_guard/halberdier
	category_tags = list(CAT_WATCHMAN)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/watch_guard/halberdier


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS
	)


/datum/outfit/watch_guard/halberdier
	name = "Town Watch Halberdier"
	head = /obj/item/clothing/head/helmet/bascinet
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/cuirass
	shirt = /obj/item/clothing/armor/gambeson/colored/town_watch
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/chain
	pants = /obj/item/clothing/pants/trou/leather/splint
	shoes = /obj/item/clothing/shoes/boots/armor/light
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = null
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = /obj/item/weapon/polearm/halberd

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

//////////////////////////////
// SENTINEL //
//////////////////////////////

/datum/attribute_holder/sheet/job/advclass/watch_guard/sentinel
	raw_attribute_list = list(
		STAT_PERCEPTION = 2,
		STAT_ENDURANCE = 3,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/swords = 10,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 40,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/misc/reading = 10
	)

/datum/job/advclass/watch_guard/sentinel
	title = "Town Watch Sentinel"
	tutorial = "You are trained to watch from above. \
	From walls, towers, and rooftops, you provide overwatch, \
	early warning, and ranged suppression during unrest or attacks."

	outfit = /datum/outfit/watch_guard/sentinel
	category_tags = list(CAT_WATCHMAN)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/watch_guard/sentinel


	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS
	)

/datum/job/advclass/watch_guard/sentinel/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/weapons = list("Longbow", "Crossbow")
	var/weapon_choice = browser_input_list(spawned, "CHOOSE YOUR WEAPON.", "TAKE UP ARMS", weapons)

	switch(weapon_choice)
		if("Longbow")
			spawned.put_in_hands(new /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/ammo_holder/quiver/arrows(get_turf(spawned)), TRUE)
		if("Crossbow")
			spawned.put_in_hands(new /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/ammo_holder/quiver/bolts(get_turf(spawned)), TRUE)

/datum/outfit/watch_guard/sentinel
	name = "Town Watch Sentinel"
	head = /obj/item/clothing/head/helmet/kettle
	mask = null
	neck = /obj/item/clothing/neck/coif/cloth
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/brigandine/light
	shirt = /obj/item/clothing/armor/gambeson/colored/town_watch
	wrists = /obj/item/clothing/wrists/bracers/leather/advanced
	gloves = /obj/item/clothing/gloves/leather/advanced
	pants = /obj/item/clothing/pants/trou/leather/splint
	shoes = /obj/item/clothing/shoes/boots/leather/advanced
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
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
	)

//////////////////////////////////
// DISCIPLINARY //
//////////////////////////////////

/datum/job/advclass/watch_guard/disciplinary
	title = "Town watch Disciplinary Guard"
	tutorial = "You are responsible the nominee for the warden's place, but something got wrong very quickly. Being stuck in your position, now you are obliged to relive your collegues and being of service. \
	After a few months, you've ben designated for the Rivermist Hollow. On your way, while packing stuff you've lost your boots! How unfortunate!"

	outfit =/datum/outfit/watch_guard/disciplinary
	allowed_sexes = list(FEMALE)
	category_tags = list(CAT_WATCHMAN)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/watch_guard/disciplinary

	traits = list(
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS
	)

/datum/attribute_holder/sheet/job/advclass/watch_guard/disciplinary
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_ENDURANCE = 3,
		STAT_CONSTITUTION = 2,
		STAT_INTELLIGENCE = 1,
		/datum/attribute/skill/combat/axesmaces = 40,
		/datum/attribute/skill/combat/shields = 40,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/knives = 20,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 40,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/sneaking = 20,
		/datum/attribute/skill/misc/reading = 30
	)

/datum/job/advclass/watch_guard/sentinel/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/weapons = list("Longbow", "Crossbow")
	var/weapon_choice = browser_input_list(spawned, "CHOOSE YOUR WEAPON.", "TAKE UP ARMS", weapons)

	switch(weapon_choice)
		if("Longbow")
			spawned.put_in_hands(new /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/ammo_holder/quiver/arrows(get_turf(spawned)), TRUE)
		if("Crossbow")
			spawned.put_in_hands(new /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/ammo_holder/quiver/bolts(get_turf(spawned)), TRUE)

/datum/outfit/watch_guard/disciplinary
	name = "Town Watch Disciplinary Guard"
	head = /obj/item/clothing/head/helmet/townwatch/gatemaster
	mask = null
	neck = /obj/item/clothing/neck/coif/cloth
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/medium/scale/bikini/bra
	shirt = /obj/item/clothing/armor/gambeson/colored/town_watch
	wrists = /obj/item/clothing/wrists/bracers/leather/advanced
	gloves = /obj/item/clothing/gloves/leather/advanced
	pants = /obj/item/clothing/pants/trou/leather/splint
	shoes = null
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = null
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/clothing/face/bdsm_gag/ball/black,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)
