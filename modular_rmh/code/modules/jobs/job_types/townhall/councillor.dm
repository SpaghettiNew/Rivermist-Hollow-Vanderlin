/datum/job/councilor
	title = "Councilor"
	f_title = "Councilwoman"
	var/council_title = "Councilor"
	tutorial = "You are the Burgmeister’s appointed Councilor. \
	While the Burgmeister speaks for Rivermist Hollow, you ensure that their decisions are recorded, enforced, and understood. \
	You advise policy, mediate disputes, and oversee the machinery of town governance."
	department_flag = TOWNHALL
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_COUNCILOR
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1
	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNHALL

	spells = list(/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch,
					/datum/action/cooldown/spell/undirected/list_target/convert_role/servant)

	give_bank_account = 250
	daily_salary = 10
	noble_income = 18

	advclass_cat_rolls = list(CAT_COUNCILOR = 20)

	exp_type = list(EXP_TYPE_NOBLE, EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_NOBLE)
	exp_requirements = list(
		EXP_TYPE_LIVING = 600,
		EXP_TYPE_NOBLE = 300
	)

	job_subclasses = list(
		/datum/job/advclass/councilor/adjutant,
		/datum/job/advclass/councilor/clerk,
		/datum/job/advclass/councilor/advisor,
		/datum/job/advclass/councilor/spymaster,
		/datum/job/advclass/councilor/first_mate,
	)


/datum/job/councilor/after_spawn(mob/living/spawned, client/player_client)
	. = ..()
	var/mob/living/carbon/human/human_councilor = spawned
	grant_outlaw_decree(human_councilor)
	spawned.verbs |= /mob/living/carbon/human/proc/councilor_announcement

// ─────────────────────────────
// SUBCLASSES
// ─────────────────────────────
/datum/job/advclass/councilor
	uses_parent_title = TRUE
	exp_types_granted = list(EXP_TYPE_NOBLE)


/datum/attribute_holder/sheet/job/advclass/councilor/adjutant
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_CONSTITUTION = 2,
		STAT_PERCEPTION = 3,
		STAT_INTELLIGENCE = 2,
		STAT_ENDURANCE = 2,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/job/advclass/councilor/adjutant
	title = "Adjutant"
	tutorial = "You once enforced law on the streets of Rivermist Hollow. \
	Now you serve beside the Burgmeister as an enforcer of order through administration rather than patrol. \
	You advise on security, discipline, and the practical limits of authority, ensuring that decrees can be upheld without chaos."

	outfit = /datum/outfit/councilor/adjutant
	category_tags = list(CAT_COUNCILOR)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/councilor/adjutant


	traits = list(
		TRAIT_BREADY,
		TRAIT_NOSEGRAB
	)


/datum/job/advclass/councilor/adjutant/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	var/static/list/selectable = list( \
		"Dagger" = /obj/item/weapon/knife/dagger/silver, \
		"Rapier" = /obj/item/weapon/sword/rapier/dec, \
		"Cane Blade" = /obj/item/weapon/sword/rapier/caneblade, \
		)
	var/choice = spawned.select_equippable(spawned, selectable, time_limit = 1 MINUTES, message = "Choose your weapon", title = "COUNCILOR")
	if(!choice)
		return
	switch(choice)
		if("Dagger")
			spawned.clamped_adjust_skillrank(/datum/skill/combat/knives, 2, TRUE)
			var/scabbard = new /obj/item/weapon/scabbard/knife/noble()
			if(!spawned.equip_to_appropriate_slot(scabbard))
				qdel(scabbard)
		if("Rapier")
			spawned.clamped_adjust_skillrank(/datum/skill/combat/swords, 2, TRUE)
			var/scabbard = new /obj/item/weapon/scabbard/sword/noble()
			if(!spawned.equip_to_appropriate_slot(scabbard))
				qdel(scabbard)
		if("Cane Blade")
			spawned.clamped_adjust_skillrank(/datum/skill/combat/swords, 2, TRUE)
			var/scabbard = new /obj/item/weapon/scabbard/cane()
			if(!spawned.equip_to_appropriate_slot(scabbard))
				qdel(scabbard)

/datum/outfit/councilor/adjutant
	name = "Councilor Adjutant"
	head = null
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/half/duelcape/townhall
	armor = /obj/item/clothing/suit/roguetown/armor/leather/adjutant
	shirt = null
	wrists = null
	gloves = /obj/item/clothing/gloves/leather/duelgloves/townhall
	pants = /obj/item/clothing/pants/trou/leather/advanced/colored/duelpants/townhall
	shoes = /obj/item/clothing/shoes/nobleboot/duelboots/townhall
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/plaquesilver
	beltr = /obj/item/storage/belt/pouch/coins/rich
	beltl = /obj/item/storage/keyring/rmh_councilor
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar
	)

// ─────────────────────────────

/datum/attribute_holder/sheet/job/advclass/councilor/clerk
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 4,
		STAT_PERCEPTION = 3,
		STAT_FORTUNE = 1,
		/datum/attribute/skill/misc/reading = 50,
		/datum/attribute/skill/labor/mathematics = 40,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/misc/lockpicking = 20,
		/datum/attribute/skill/combat/unarmed = 10
	)

/datum/job/advclass/councilor/clerk
	title = "Clerk"
	tutorial = "You are the keeper of records, taxes, decrees, and civic correspondence. \
	As Clerk to the Burgmeister, you ensure that Rivermist Hollow runs on ink, seal, and ledger. \
	Your authority is quiet but absolute — a decision not written may as well never have existed."

	outfit = /datum/outfit/councilor/clerk
	category_tags = list(CAT_COUNCILOR)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/councilor/clerk


	traits = list(
		TRAIT_SEEPRICES,
		TRAIT_TUTELAGE
	)

/datum/outfit/councilor/clerk
	name = "Councilor Clerk"
	head = /obj/item/clothing/head/stewardtophat
	mask = /obj/item/clothing/face/spectacles
	neck = null
	cloak = /obj/item/clothing/cloak/cape/puritan/townhall
	armor = /obj/item/clothing/armor/gambeson/steward/townhall
	shirt = null
	pants = null
	wrists = null
	gloves = null
	shoes = /obj/item/clothing/shoes/nobleboot
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/plaquegold
	beltr = /obj/item/storage/belt/pouch/coins/rich
	beltl = /obj/item/storage/keyring/rmh_councilor
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/mace/cane/noble
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar
	)

/datum/outfit/councilor/clerk/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()
	if(equipped_human.gender == MALE)
		shirt = /obj/item/clothing/shirt/undershirt/fancy
		pants = /obj/item/clothing/pants/tights/colored/black
	else
		shirt = /obj/item/clothing/shirt/dress/stewarddress/townhall


// ─────────────────────────────

/datum/attribute_holder/sheet/job/advclass/councilor/advisor
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 4,
		STAT_PERCEPTION = 3,
		STAT_FORTUNE = 2,
		/datum/attribute/skill/misc/reading = 50,
		/datum/attribute/skill/labor/mathematics = 30,
		/datum/attribute/skill/misc/medicine = 30,
		/datum/attribute/skill/misc/lockpicking = 30,
		/datum/attribute/skill/combat/wrestling = 20,
		/datum/attribute/skill/combat/unarmed = 20
	)

/datum/job/advclass/councilor/advisor
	title = "Advisor"
	tutorial = "You serve as the Burgmeister’s counselor, strategist, and interpreter of consequence. \
	You weigh guild pressure, public unrest, and expectations before decisions are ever announced. \
	Though you hold no elected mandate, your counsel shapes the fate of Rivermist Hollow."

	outfit = /datum/outfit/councilor/advisor
	category_tags = list(CAT_COUNCILOR)


	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/councilor/advisor


	traits = list(
		TRAIT_EMPATH,
		TRAIT_DECEIVING_MEEKNESS
	)

/datum/outfit/councilor/advisor
	name = "Advisor Councilor"
	head = /obj/item/clothing/head/chaperon/colored/greyscale/townhall
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/cape/colored/townhall
	armor = /obj/item/clothing/suit/roguetown/armor/councillor
	shirt = /obj/item/clothing/shirt/undershirt/fancy
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/tights/colored/black
	shoes = /obj/item/clothing/shoes/nobleboot
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/plaquesilver
	beltr = /obj/item/storage/belt/pouch/coins/rich
	beltl = /obj/item/storage/keyring/rmh_councilor
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar
	)


// ─────────────────────────────

/datum/attribute_holder/sheet/job/advclass/councilor/spymaster
	raw_attribute_list = list(
		STAT_INTELLIGENCE = 4,
		STAT_PERCEPTION = 4,
		STAT_FORTUNE = 2,
		STAT_STRENGTH = -1,
		/datum/attribute/skill/misc/reading = 50,
		/datum/attribute/skill/misc/sneaking = 30,
		/datum/attribute/skill/misc/stealing = 30,
		/datum/attribute/skill/misc/lockpicking = 30,
		/datum/attribute/skill/misc/athletics = 20,
		/datum/attribute/skill/misc/medicine = 20,
		/datum/attribute/skill/labor/mathematics = 20,
		/datum/attribute/skill/combat/unarmed = 20,
		/datum/attribute/skill/combat/knives = 20
	)

/datum/job/advclass/councilor/spymaster
	title = "Spymaster Councilor"
	tutorial = "You are the keeper of secrets, informants, and quiet truths. \
	From tavern whispers to sealed correspondence, nothing of importance moves in Rivermist Hollow without your notice. \
	You advise the Burgmeister not with speeches, but with leverage — knowing who lies, who plots, and who can be turned."

	outfit = /datum/outfit/councilor/spymaster
	category_tags = list(CAT_COUNCILOR)

	attribute_sheet = /datum/attribute_holder/sheet/job/advclass/councilor/spymaster


	traits = list(
		TRAIT_DECEIVING_MEEKNESS,
		TRAIT_EMPATH,
		TRAIT_LIGHT_STEP,
		TRAIT_THIEVESGUILD,
	)

	languages = list(/datum/language/thievescant)

/datum/outfit/councilor/spymaster
	name = "Spymaster Councilor"
	head = /obj/item/clothing/head/chaperon/colored/greyscale/townhall
	mask = null
	neck = null
	cloak = /obj/item/clothing/cloak/raincloak/colored/mortus
	armor = /obj/item/clothing/armor/leather/splint
	shirt = /obj/item/clothing/shirt/undershirt/colored/black
	wrists = null
	gloves = null
	pants = /obj/item/clothing/pants/trou/leather
	shoes = /obj/item/clothing/shoes/boots
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/plaquesilver
	beltr = /obj/item/storage/belt/pouch/coins/rich
	beltl = /obj/item/storage/keyring/rmh_councilor
	ring = /obj/item/clothing/ring/slave_control
	l_hand = null
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/lockpick = 1,
		/obj/item/weapon/knife/dagger/steel = 1,
		/obj/item/clothing/face/shepherd/rag = 1,
	)

//ANNOUNCEMENT SYSTEM

/mob/living/carbon/human/proc/councilor_announcement()
	set name = "Announcement"
	set category = "Councilor"
	if(stat)
		return

	var/static/last_announcement_time = 0

	if(world.time < last_announcement_time + 1 MINUTES)
		var/time_left = round((last_announcement_time + 1 MINUTES - world.time) / 10)
		to_chat(src, "<span class='warning'>You must wait [time_left] more seconds before making another announcement.</span>")
		return

	var/inputty = input("Make an announcement", "RIVERMIST HOLLOW") as text|null
	if(inputty)
		var/area/A = get_area(src)
		if(!(istype(A, /area/indoors/town/rmh/town_hall) || istype(A, /area/outdoors/town)))
			to_chat(src, "<span class='warning'>I need to do this from the Town Hall or the Town Square.</span>")
			return FALSE

		priority_announce(
			"[inputty]",
			title = "[src.real_name], the Councilor of Rivermist Hollow",
			sound = 'sound/misc/bell.ogg'
		)

		src.log_talk(
			"[TIMETOTEXT4LOGS] [inputty]",
			LOG_SAY,
			tag = "Councilor announcement"
		)

		last_announcement_time = world.time
