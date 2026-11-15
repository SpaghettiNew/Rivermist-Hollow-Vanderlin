/datum/job/watch_veteran
	title = "Town Watch Veteran"
	tutorial = "You are a seasoned veteran of the Town Watch. \
	Years of patrols, riots, night watches, and close calls have hardened you. \
	You train new watchmen, steady patrols in dangerous moments, and serve as an example of discipline. \
	You are not in command — but when trouble starts, others look to you."
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_VETERAN
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1

	allowed_ages = list(AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	advclass_cat_rolls = list(CAT_VETERAN = 20)

	job_subclasses = list(
		/datum/job/advclass/watch_veteran/vanguard,
		/datum/job/advclass/watch_veteran/champion,
		/datum/job/advclass/watch_veteran/charm,
	)

	give_bank_account = 150
	daily_salary = 20

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT)
	exp_requirements = list(
		EXP_TYPE_LIVING = 500
	)

	job_bitflag = BITFLAG_GARRISON


/datum/job/watch_veteran/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	spawned.verbs |= /mob/proc/haltyell


////////////////////////////////////////
// ADVCLASS BASE – VETERAN //
////////////////////////////////////////

/datum/job/advclass/watch_veteran

////////////////////////////////////////
// Vanguard VETERAN //
////////////////////////////////////////

/datum/job/advclass/watch_veteran/vanguard
	title = "Vanguard"
	category_tags = list(CAT_VETERAN)
	outfit = /datum/outfit/watch_veteran/vanguard
	tutorial = "You are a Vanguard of the Town Watch. The first one to get in the heat of the action, the last one to leave. \
	You are the first responder to many threats that town faces. The courage and endurance you've ben given by highness being made you the first to face the dangers of the streets. \
	The heavy armor and ranged weaponry dosen't fit you, but your heart of steel and courage is what makes you a true Vanguard."

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_veteran/vanguard

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_STEELHEARTED,
		TRAIT_SHARPER_BLADES,
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS,
		TRAIT_IGNOREDAMAGESLOWDOWN,
		TRAIT_TEMPO,
		TRAIT_NOGUNS,
		TRAIT_KNEESTINGER_IMMUNITY
	)

/datum/attribute_holder/sheet/job/watch_veteran/vanguard
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 3,
		STAT_PERCEPTION = 1,
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/swords = 40,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/polearms = 20,
		/datum/attribute/skill/misc/athletics = 35,
		/datum/attribute/skill/misc/climbing = 25,
		/datum/attribute/skill/misc/swimming = 25,
		/datum/attribute/skill/misc/reading = 10
	)


/datum/outfit/watch_veteran/vanguard
	name = "Town Watch Vanguard"
	head = /obj/item/clothing/head/helmet/townwatch/gatemaster/bulwark
	mask = null
	neck = /obj/item/clothing/neck/bevor/iron
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/plate/iron
	shirt = /obj/item/clothing/armor/gambeson/heavy/inq
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/plate
	pants = /obj/item/clothing/pants/chainlegs/iron
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/sword/long
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

/datum/job/advclass/watch_veteran/champion
	title = "Champion"
	category_tags = list(CAT_VETERAN)
	outfit = /datum/outfit/watch_veteran/champion
	tutorial = "You are a Champion of the Town Watch. The job you've ben having for years made you the real jack of all trades. \
	Life were constantly throwing challenges at you, one after the other. Your ways of adapting in battle have made you a champion among the rest. \
	You can make use of everything you have in your arsenal, and you are a true master of the battlefield."

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_veteran/champion

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_STEELHEARTED,
		TRAIT_SHARPER_BLADES,
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS,
		TRAIT_HEAVYARMOR,
		TRAIT_ENGINEERING_GOGGLES,
		TRAIT_COMBAT_AWARE
	)

/datum/attribute_holder/sheet/job/watch_veteran/champion
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 1,
		STAT_PERCEPTION = 1,
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/swords = 35,
		/datum/attribute/skill/combat/shields = 25,
		/datum/attribute/skill/combat/wrestling = 25,
		/datum/attribute/skill/combat/unarmed = 25,
		/datum/attribute/skill/combat/axesmaces = 35,
		/datum/attribute/skill/combat/polearms = 35,
		/datum/attribute/skill/combat/whipsflails = 35,
		/datum/attribute/skill/combat/bows = 35,
		/datum/attribute/skill/combat/crossbows = 35,
		/datum/attribute/skill/combat/knives = 35,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/climbing = 35,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/medicine = 30,
		/datum/attribute/skill/misc/lockpicking = 15,
		/datum/attribute/skill/misc/reading = 30,
		/datum/skill/craft/crafting = 25,
		/datum/skill/craft/weaponsmithing = 25,
		/datum/skill/craft/armorsmithing = 25,
		/datum/skill/craft/blacksmithing = 25,
		/datum/skill/craft/carpentry = 25,
		/datum/skill/craft/engineering = 25
	)


/datum/outfit/watch_veteran/champion
	name = "Town Watch Champion"
	head = /obj/item/clothing/head/helmet/townbarbute
	mask = null
	neck = /obj/item/clothing/neck/chaincoif/iron
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/leather/jacket/gatemaster_jacket/armored
	shirt = /obj/item/clothing/armor/chainmail/hauberk
	wrists = /obj/item/weapon/scabbard/knife
	gloves = /obj/item/clothing/gloves/fingerless
	pants = /obj/item/clothing/pants/trou/leather/guard
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
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

/datum/job/advclass/watch_veteran/champion/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/weapons = list("Sword + Shield", "Sword + Longbow", "Sword + Crossbow", "Zweihander", "Halberd")
	var/weapon_choice = browser_input_list(spawned, "CHOOSE YOUR WEAPON, CHAMPION.", "TAKE UP ARMS", weapons)

	switch(weapon_choice)
		if("Sword + Shield")
			spawned.put_in_hands(new /obj/item/weapon/sword/arming(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/weapon/scabbard/sword(get_turf(spawned)), TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/weapon/shield/heater, ITEM_SLOT_BACK_L, TRUE)
		if("Sword + Longbow")
			spawned.put_in_hands(new /obj/item/weapon/sword/arming(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/weapon/scabbard/sword(get_turf(spawned)), TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/ammo_holder/quiver/arrows, ITEM_SLOT_BELT_L, TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long, ITEM_SLOT_BACK_L, TRUE)
		if("Sword + Crossbow")
			spawned.put_in_hands(new /obj/item/weapon/sword/arming(get_turf(spawned)), TRUE)
			spawned.put_in_hands(new /obj/item/weapon/scabbard/sword(get_turf(spawned)), TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow, ITEM_SLOT_BACK_L, TRUE)
			spawned.equip_to_slot_or_del(new /obj/item/ammo_holder/quiver/bolts, ITEM_SLOT_BELT_L, TRUE)
		if("Zweihander")
			spawned.put_in_hands(new /obj/item/weapon/sword/long/greatsword/zwei(get_turf(spawned)), TRUE)
		if("Halberd")
			spawned.put_in_hands(new /obj/item/weapon/polearm/halberd(get_turf(spawned)), TRUE)

/datum/job/advclass/watch_veteran/charm
	title = "Charm of the Corps"
	category_tags = list(CAT_VETERAN)
	outfit = /datum/outfit/watch_veteran/charm
	tutorial = "You are a Lucky Charm of the Town Watch. The one who brings luck to the corps. \
	You're a supportive one, a person the first to go in negotiation and resolve matters with less bloodshed. \
	Your presence boosts the team's morale, and the flag on your halberd waves proudly. Look after your squad and stand by them."

	attribute_sheet = /datum/attribute_holder/sheet/job/watch_veteran/charm

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_STEELHEARTED,
		TRAIT_SHARPER_BLADES,
		TRAIT_MEDIUMARMOR,
		TRAIT_KNOWBANDITS,
		TRAIT_TUTELAGE,
		TRAIT_BREADY,
	)

/datum/attribute_holder/sheet/job/watch_veteran/charm
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 3,
		STAT_PERCEPTION = 1,
		STAT_INTELLIGENCE = 1,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/swords = 35,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 10,
		/datum/attribute/skill/combat/axesmaces = 20,
		/datum/attribute/skill/combat/polearms = 40,
		/datum/attribute/skill/misc/athletics = 35,
		/datum/attribute/skill/misc/climbing = 25,
		/datum/attribute/skill/misc/swimming = 25,
		/datum/attribute/skill/misc/reading = 30
	)


/datum/outfit/watch_veteran/charm
	name = "Town Watch Charm of the Corps"
	head = /obj/item/clothing/head/helmet/heavy/psydonhelm
	mask = null
	neck = /obj/item/clothing/neck/psycross/silver/ravox
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/brigandine
	shirt = /obj/item/clothing/armor/gambeson/heavy
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/leather/black
	pants = /obj/item/clothing/pants/platelegs/matthios
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/polearm/halberd/watch_charm
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
