/datum/job/watch_sergeant
	title = "Town Watch Sergeant"
	tutorial = "You are a Sergeant of the Town Watch of Rivermist Hollow. \
	You lead patrols, enforce discipline among the watchmen, and act as the Captain’s right hand in the streets. \
	You are responsible for training recruits, responding to disturbances, and ensuring the Captain’s orders are followed. \
	While there's no captain in the streets, your job is to lead the garrison."
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_SERGEANT
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	advclass_cat_rolls = list(CAT_SERGEANT = 20)

	job_subclasses = list(
		/datum/job/advclass/watch_sergeant/bountyhunter,
		/datum/job/advclass/watch_sergeant/pathfinder,
		/datum/job/advclass/watch_sergeant/faithful,
	)

	give_bank_account = 200
	daily_salary = 20

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT)
	exp_requirements = list(EXP_TYPE_LIVING = 450)

	job_bitflag = BITFLAG_GARRISON

/datum/job/watch_sergeant/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	grant_outlaw_decree(spawned)
	spawned.verbs |= /mob/proc/haltyell

	// Sergeants always have their own command authority.
	spawned.grant_town_watch_command(TOWNWATCH_COMMAND_SERGEANT)
	// Emergency recruitment authority is separate.
	if(town_watch_captain_available())
		spawned.remove_town_watch_sergeant_command()
	else
		spawned.grant_town_watch_sergeant_command()
	// Refresh emergency recruitment state for all sergeants.
	sync_town_watch_sergeant_commands()

////////////////////////////////////////
// ADVCLASS BASE – SEREGANT //
////////////////////////////////////////

/datum/job/advclass/watch_sergeant

////////////////////////////////////////
// Bounty hunter SEREGANT //
////////////////////////////////////////

/datum/job/advclass/watch_sergeant/bountyhunter

	title = "Town Watch Bounty Hunter"
	tutorial = "You are a Bounty Hunter of the Town Watch of Rivermist Hollow. \
	The life you lived was always shadowed by thieves and rouges. Wherever you went, they were near. The hatred for those rats only can be compared to the inquisitors loathing for the undead. \
	That's why when you've got the status and means, you've dedicated your life fighting them."
	category_tags = list(CAT_SERGEANT)
	outfit = /datum/outfit/watch_sergeant/bountyhunter
	attribute_sheet = /datum/attribute_holder/sheet/job/watch_sergeant/bountyhunter

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_TOWNWATCH_COMMAND,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_KNOW_WATCH,
		TRAIT_KNOWBANDITS,
		TRAIT_MEDIUMARMOR,
		TRAIT_TUTELAGE,
		TRAIT_POISON_RESILIENCE,
		TRAIT_RECOGNIZED,
		TRAIT_TRUE_GRIT,
		TRAIT_NOFALLDAMAGE1,
		TRAIT_LIGHT_STEP,
		TRAIT_DUALWIELDER
	)

/datum/attribute_holder/sheet/job/watch_sergeant/bountyhunter
	raw_attribute_list = list(
		STAT_PERCEPTION = 2,
		STAT_INTELLIGENCE = 1,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 2,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/swords = 10,
		/datum/attribute/skill/combat/shields = 10,
		/datum/attribute/skill/combat/wrestling = 25,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 35,
		/datum/attribute/skill/combat/polearms = 10,
		/datum/attribute/skill/combat/knives = 35,
		/datum/attribute/skill/combat/bows = 25,
		/datum/attribute/skill/combat/crossbows = 25,
		/datum/attribute/skill/combat/firearms = 25,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/swimming = 30,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/craft/traps = 30,
		/datum/attribute/skill/misc/reading = 20
	)

/datum/outfit/watch_sergeant/bountyhunter
	name = "Town Watch Bounty Hunter"
	head = /obj/item/clothing/head/helmet/heavy/volfplate/puritan
	mask = null
	neck = /obj/item/clothing/neck/bevor/iron
	cloak = /obj/item/clothing/cloak/cape/guard
	armor = /obj/item/clothing/armor/leather/jacket/leathercoat/confessor
	shirt = /obj/item/clothing/armor/gambeson/heavy/otavan/inq
	wrists = /obj/item/clothing/wrists/bracers/ironjackchain
	gloves = /obj/item/clothing/gloves/plate
	pants = /obj/item/clothing/pants/grenzelpants
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = /obj/item/weapon/scabbard/knife/noble
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/knife/dagger/steel/hand/parry
	r_hand = /obj/item/weapon/knife/dagger/steel/hand

	backpack_contents = list(
		/obj/item/smokebomb,
		/obj/item/reagent_containers/glass/bottle/vial/sleep_potion,
		/obj/item/reagent_containers/glass/bottle/vial/paralyze_potion,
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

////////////////////////////////////////
// Pathfinder SERGEANT //
////////////////////////////////////////

/datum/job/advclass/watch_sergeant/pathfinder
	title = "Town Watch Bounty Pathfinder"
	tutorial = "You are a Bounty Hunter of the Town Watch of Rivermist Hollow. \
	Life in big city changed your approach to the way you act. While everyone else are unleasing their blades upon danger, you start thinking how to pacify them. \
	Your hesitation to kill became a weapon. The ways to take care of their will to bloodshed made you fight harder. But still, this was enough to ditch the ranged weaponry whatsoever."
	category_tags = list(CAT_SERGEANT)
	outfit = /datum/outfit/watch_sergeant/pathfinder
	attribute_sheet = /datum/attribute_holder/sheet/job/watch_sergeant/pathfinder

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_TOWNWATCH_COMMAND,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_KNOW_WATCH,
		TRAIT_KNOWBANDITS,
		TRAIT_MEDIUMARMOR,
		TRAIT_TUTELAGE,
		TRAIT_POISON_RESILIENCE,
		TRAIT_HEAVYARMOR,
		TRAIT_RECOGNIZED,
		TRAIT_NOGUNS,
		TRAIT_TRUE_GRIT,
		TRAIT_BREADY
	)

/datum/attribute_holder/sheet/job/watch_sergeant/pathfinder
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_PERCEPTION = 1,
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 2,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/combat/wrestling = 40,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/reading = 20
	)

/datum/outfit/watch_sergeant/pathfinder
	name = "Town Watch Pathfinder"
	head = /obj/item/clothing/head/helmet/heavy/dendorhelm
	mask = null
	neck = /obj/item/clothing/neck/gorget
	cloak = /obj/item/clothing/cloak/half/guard
	armor = /obj/item/clothing/armor/cuirass
	shirt = /obj/item/clothing/armor/gambeson/heavy/inq
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/plate/blk
	pants = /obj/item/clothing/pants/trou/leather/advanced
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/shield/tower/metal/psy
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = null
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/knuckles
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/rope/net/bola,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

////////////////////////////////////////
// Faithful SERGEANT //
////////////////////////////////////////

/datum/job/advclass/watch_sergeant/faithful

	title = "Town Watch Faithful"
	tutorial = "You are a Faithful one of the Town Watch of Rivermist Hollow. \
	Once upon a time, when a frail body was at the heavens door, a small church taken care of it. With no way to go, and pay for their kindness in this bitter times, you've joined them. \
	Now you are a part of inquisitors representatives. Your job is to protect the holy lands of Selune from any undead, bloodsuckers and imps. They imprisoned you in a silver shell, so do what you do best. \
	Feel of that Rivermist needs in you, burgmeister wanted to cover the price of the equipment, but you refused. Rip and Tear, untill it is done."
	category_tags = list(CAT_SERGEANT)
	outfit = /datum/outfit/watch_sergeant/faithful
	attribute_sheet = /datum/attribute_holder/sheet/job/watch_sergeant/faithful

	traits = list(
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_TOWNWATCH_COMMAND,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_KNOW_WATCH,
		TRAIT_KNOWBANDITS,
		TRAIT_MEDIUMARMOR,
		TRAIT_TUTELAGE,
		TRAIT_POISON_RESILIENCE,
		TRAIT_HEAVYARMOR,
		TRAIT_RECOGNIZED,
		TRAIT_INQUISITION,
		TRAIT_SILVER_BLESSED,
		TRAIT_ANTIMAGIC,
		TRAIT_BREADY
	)

/datum/attribute_holder/sheet/job/watch_sergeant/faithful
	raw_attribute_list = list(
		STAT_STRENGTH = 2,
		STAT_PERCEPTION = 2,
		STAT_INTELLIGENCE = 1,
		STAT_CONSTITUTION = 1,
		STAT_ENDURANCE = 2,
		STAT_SPEED = 1,
		/datum/attribute/skill/combat/swords = 30,
		/datum/attribute/skill/combat/shields = 30,
		/datum/attribute/skill/combat/wrestling = 40,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/misc/athletics = 40,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 30,
		/datum/attribute/skill/misc/reading = 20
	)

/datum/outfit/watch_sergeant/faithful
	name = "Town Watch Faithful"
	head = /obj/item/clothing/head/helmet/heavy/necked
	mask = /obj/item/clothing/face/spectacles/inq
	neck = /obj/item/clothing/neck/psycross/silver/holy
	cloak = /obj/item/clothing/cloak/cape/inquisitor
	armor = /obj/item/clothing/armor/cuirass
	shirt = /obj/item/clothing/shirt/undershirt/formal
	wrists = /obj/item/weapon/scabbard/knife/noble
	gloves = /obj/item/clothing/gloves/leather/otavan/inqgloves
	pants = /obj/item/clothing/pants/platelegs/silver
	shoes = /obj/item/clothing/shoes/otavan/inqboots
	backr = /obj/item/storage/backpack/satchel/black
	backl = null
	belt = /obj/item/storage/belt/leather/town_watch
	beltr = /obj/item/weapon/scabbard/sword
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/sword/silver
	r_hand = /obj/item/weapon/knife/dagger/silver

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/alchemical/blessedwater,
		/obj/item/reagent_containers/glass/bottle/alchemical/blessedwater,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

///Emergency authonomy system. If captain is absent (Does not exist in round), sergeant gets his specials till someone joins the game as the role

/mob/living/carbon/human/proc/grant_town_watch_sergeant_command()
	if(town_watch_recruit_action)
		return

	town_watch_recruit_action = new /datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch
	town_watch_recruit_action.Grant(src)



/mob/living/carbon/human/proc/remove_town_watch_sergeant_command()
	if(!town_watch_recruit_action)
		return

	town_watch_recruit_action.Remove(src)
	QDEL_NULL(town_watch_recruit_action)

/proc/sync_town_watch_sergeant_commands()
	var/captain_present = town_watch_captain_available()

	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(QDELETED(H))
			continue

		var/datum/job/J = H.mind?.assigned_role
		if(!J)
			continue

		if(J.parent_job)
			J = J.parent_job

		if(!istype(J, /datum/job/watch_sergeant))
			continue

		// Sergeants always retain their own order authority.
		H.grant_town_watch_command(TOWNWATCH_COMMAND_SERGEANT)

		// Emergency recruitment authority is conditional.
		if(captain_present)
			H.remove_town_watch_sergeant_command()
		else
			H.grant_town_watch_sergeant_command()
