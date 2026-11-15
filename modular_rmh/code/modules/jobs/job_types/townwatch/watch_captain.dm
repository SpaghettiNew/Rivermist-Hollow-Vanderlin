/datum/job/watch_captain
	title = "Town Watch Captain"
	tutorial = "You are the Captain of the Town Watch of Rivermist Hollow. \
	You are responsible for organizing patrols, maintaining order, and coordinating the defense of the town. \
	You command the city watchmen, veterans, militia, and any hired auxiliaries. \
	You answer directly to the Burgmeister and guard them with your life."
	department_flag = TOWNWATCH
	job_flags = (JOB_ANNOUNCE_ARRIVAL | JOB_SHOW_IN_CREDITS | JOB_EQUIP_RANK | JOB_NEW_PLAYER_JOINABLE)
	display_order = JDO_WATCH_CAPTAIN
	faction = FACTION_TOWN
	total_positions = 1
	spawn_positions = 1

	allowed_ages = list(AGE_ADULT, AGE_MIDDLEAGED, AGE_OLD, AGE_IMMORTAL)
	allowed_races = ALL_RACES_LIST
	selection_color = JCOLOR_TOWNWATCH

	advclass_cat_rolls = list(CAT_CAPTAIN = 20)

	job_subclasses = list(
		/datum/job/advclass/watch_captain/marshall,
		/datum/job/advclass/watch_captain/sharpshooter,
		/datum/job/advclass/watch_captain/royalguard,
	)

	give_bank_account = 350
	daily_salary = 30

	exp_type = list(EXP_TYPE_LIVING)
	exp_types_granted = list(EXP_TYPE_GARRISON, EXP_TYPE_COMBAT, EXP_TYPE_LEADERSHIP)
	exp_requirements = list(
		EXP_TYPE_LIVING = 600
	)


	job_bitflag = BITFLAG_GARRISON

////////////////////////////////////////
// ADVCLASS BASE – CAPTAIN //
////////////////////////////////////////

/datum/job/advclass/watch_captain

	spells = list(/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch)

/datum/job/watch_captain/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()

	spawned.grant_town_watch_command(TOWNWATCH_COMMAND_CAPTAIN)
	spawned.verbs |= /mob/proc/haltyell
	grant_outlaw_decree(spawned)

	sync_town_watch_sergeant_commands()


////////////////////////////////////////
// Marhall CAPTAIN //
////////////////////////////////////////

/datum/job/advclass/watch_captain/marshall
	title = "Town Watch Marshall"
	tutorial = "You are the Marshall, a captain that lived his live in neverending patrols and shifts. Sometimes the best way to keep everything in control is being on the field personally. \
	Being the best dosen't mean that you need to wait for the results, when you can manage your team in the backline or fight amongst your people."
	category_tags = list(CAT_CAPTAIN)

	traits = list(
		TRAIT_TOWNWATCH_COMMAND,
		TRAIT_KNOWBANDITS,
		TRAIT_RECOGNIZED,
		TRAIT_KNOW_WATCH,
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_HEAVYARMOR,
		TRAIT_MEDIUMARMOR,
		TRAIT_TUTELAGE,
		TRAIT_BREADY,
		TRAIT_DODGEEXPERT,
		TRAIT_NUTCRACKER,
		TRAIT_CRITICAL_RESISTANCE
	)

	outfit = /datum/outfit/watch_captain/marshall
	attribute_sheet = /datum/attribute_holder/sheet/job/watch_captain/marshall

/datum/attribute_holder/sheet/job/watch_captain/marshall
	raw_attribute_list = list(
		STAT_STRENGTH = 3,
		STAT_PERCEPTION = 3,
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 3,
		STAT_ENDURANCE = 3,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/swords = 40,
		/datum/attribute/skill/combat/shields = 40,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/riding = 35,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/outfit/watch_captain/marshall
	name = "Town Watch Marshall"
	head = /obj/item/clothing/head/helmet/sargebarbute/town_watch
	mask = null
	neck = /obj/item/clothing/neck/highcollier
	cloak = /obj/item/clothing/cloak/captain/town_watch
	armor = /obj/item/clothing/armor/plate/full/matthios
	shirt = /obj/item/clothing/shirt/undershirt/fancy
	wrists = /obj/item/clothing/wrists/bracers/jackchain
	gloves = /obj/item/clothing/gloves/plate
	pants = /obj/item/clothing/pants/chainlegs
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/shield/tower/metal
	belt = /obj/item/storage/belt/leather/steel/watch_captain
	beltr = /obj/item/weapon/scabbard/sword/royal
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/sword/decorated
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

////////////////////////////////////////
// Sharpshooter CAPTAIN //
////////////////////////////////////////

/datum/job/advclass/watch_captain/sharpshooter
	title = "Sharpshooter Captain"
	tutorial = "You are a high-ranked sharpshooter of the Townwatch. When first time you've discovered the power of powder, the feeling of power changed your way to approach the battle \
	All this scum is fleeing back into the shadow, when see a guard. Why won't we adapt to fight to those freaks? That's what you've questioned first, when acquired a peace of foreign technology. \
	Maybe you are not the most powerful among else in a fistfight, this is your way. Being mediocore in all those martial arts only proves how you rely on gunpowder. Only one laughs, who is alive to do that, right?"
	category_tags = list(CAT_CAPTAIN)

	traits = list(
		TRAIT_TOWNWATCH_COMMAND,
		TRAIT_KNOWBANDITS,
		TRAIT_RECOGNIZED,
		TRAIT_KNOW_WATCH,
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_HEAVYARMOR,
		TRAIT_MEDIUMARMOR,
		TRAIT_TUTELAGE,
		TRAIT_BREADY,
		TRAIT_CRITICAL_WEAKNESS,
		TRAIT_TOWNWATCH_COMMAND,
		TRAIT_SHOCKIMMUNE,
		TRAIT_NIGHT_OWL
	)

	outfit = /datum/outfit/watch_captain/sharpshooter
	attribute_sheet = /datum/attribute_holder/sheet/job/watch_captain/sharpshooter

/datum/attribute_holder/sheet/job/watch_captain/sharpshooter
	raw_attribute_list = list(
		STAT_STRENGTH = 1,
		STAT_PERCEPTION = 3,
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 3,
		STAT_ENDURANCE = 3,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/swords = 25,
		/datum/attribute/skill/combat/shields = 25,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 25,
		/datum/attribute/skill/combat/polearms = 25,
		/datum/attribute/skill/combat/bows = 35,
		/datum/attribute/skill/combat/crossbows = 35,
		/datum/attribute/skill/combat/firearms = 35,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/swimming = 25,
		/datum/attribute/skill/misc/climbing = 25,
		/datum/attribute/skill/misc/riding = 20,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/outfit/watch_captain/sharpshooter
	name = "Sharpshooter Captain"
	head = /obj/item/clothing/head/roguehood/colored/townhall
	mask = /obj/item/clothing/face/facemask/silverveil
	neck = /obj/item/clothing/neck/mercmedal/boltslinger
	cloak = /obj/item/clothing/cloak/captain/town_watch
	armor = /obj/item/clothing/armor/basiceast/captainrobe
	shirt = /obj/item/clothing/armor/gambeson/heavy/inq
	wrists = /obj/item/weapon/scabbard/knife/royal
	gloves = /obj/item/clothing/gloves/fingerless/shadowgloves
	pants = /obj/item/clothing/pants/platelegs/captain
	shoes = /obj/item/clothing/shoes/boots/leather/advanced/watch
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/gun/ballistic/revolver/grenadelauncher/pistol/musket
	belt = /obj/item/storage/belt/leather/steel/watch_captain
	beltr = /obj/item/weapon/knife/dagger/bayonet
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/knife/dagger/steel/royal
	r_hand = null

	backpack_contents = list(
		/obj/item/storage/belt/pouch/cloth/bullets,
		/obj/item/reagent_containers/glass/bottle/aflask,
		/obj/item/gun/ballistic/revolver/grenadelauncher/pistol,
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)

////////////////////////////////////////
// Royal guard CAPTAIN //
////////////////////////////////////////

/datum/job/advclass/watch_captain/royalguard
	title = "Royal Guard Captain"
	tutorial = "The way those scum was munching your people frustrated you for years. One day you've clenched your teeth and swear to be always help in battle, leading people into battles without hesitation. \
	And that's how it begun. Now, you are retired, after many bloodbaths you've made out alive. Proficient. Better. Always assisting your own. Not because you are noble, because of fear of loss."
	category_tags = list(CAT_CAPTAIN)

	traits = list(
		TRAIT_TOWNWATCH_COMMAND,
		TRAIT_KNOWBANDITS,
		TRAIT_RECOGNIZED,
		TRAIT_KNOW_WATCH,
		TRAIT_KNOW_WATCH_RANK,
		TRAIT_KNOW_WATCH_SPECIALIZATION,
		TRAIT_HEAVYARMOR,
		TRAIT_MEDIUMARMOR,
		TRAIT_TUTELAGE,
		TRAIT_BREADY,
		TRAIT_SHARPER_BLADES,
		TRAIT_IGNOREDAMAGESLOWDOWN,
		TRAIT_TRUE_GRIT
	)

	outfit = /datum/outfit/watch_captain/royalguard
	attribute_sheet = /datum/attribute_holder/sheet/job/watch_captain/royalguard

/datum/attribute_holder/sheet/job/watch_captain/royalguard
	raw_attribute_list = list(
		STAT_STRENGTH = 3,
		STAT_PERCEPTION = 3,
		STAT_INTELLIGENCE = 2,
		STAT_CONSTITUTION = 3,
		STAT_ENDURANCE = 3,
		STAT_SPEED = 2,
		/datum/attribute/skill/combat/swords = 40,
		/datum/attribute/skill/combat/shields = 40,
		/datum/attribute/skill/combat/wrestling = 30,
		/datum/attribute/skill/combat/unarmed = 30,
		/datum/attribute/skill/combat/axesmaces = 30,
		/datum/attribute/skill/combat/polearms = 30,
		/datum/attribute/skill/combat/bows = 30,
		/datum/attribute/skill/combat/crossbows = 30,
		/datum/attribute/skill/combat/firearms = 30,
		/datum/attribute/skill/misc/athletics = 30,
		/datum/attribute/skill/misc/swimming = 20,
		/datum/attribute/skill/misc/climbing = 20,
		/datum/attribute/skill/misc/riding = 20,
		/datum/attribute/skill/misc/reading = 30,
		/datum/attribute/skill/labor/mathematics = 20
	)

/datum/outfit/watch_captain/royalguard
	name = "Royal Guard Captain"
	head = /obj/item/clothing/head/helmet/visored/captain
	mask = null
	neck = /obj/item/clothing/neck/chaincoif
	cloak = /obj/item/clothing/cloak/captain/town_watch
	armor = /obj/item/clothing/armor/plate
	shirt = /obj/item/clothing/armor/gambeson/heavy/colored/town_watch
	wrists = /obj/item/clothing/wrists/royalsleeves
	gloves = /obj/item/clothing/gloves/angle/atgervi
	pants = /obj/item/clothing/pants/platelegs/captain
	shoes = /obj/item/clothing/shoes/boots/armor/light
	backr = /obj/item/storage/backpack/satchel/black
	backl = /obj/item/weapon/shield/tower/metal
	belt = /obj/item/storage/belt/leather/steel/watch_captain
	beltr = /obj/item/weapon/scabbard/sword/noble
	beltl = /obj/item/weapon/mace/stunmace
	ring = /obj/item/clothing/ring/slave_control
	l_hand = /obj/item/weapon/sword/long/judgement
	r_hand = null

	backpack_contents = list(
		/obj/item/clothing/neck/slave_collar,
		/obj/item/reagent_containers/glass/bottle/stronghealthpot,
		/obj/item/flashlight/flare/torch/lantern,
	)



/datum/outfit/watch_captain/pre_equip(mob/living/carbon/human/equipped_human, visuals_only)
	. = ..()


//CONVERSION

/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch
	name = "Recruit Town Watch"
	button_icon_state = "recruit_guard"

	new_role = "Town Watch Militia"
	recruitment_faction = "Town Watch"
	recruitment_message = "Join the Town Watch, %RECRUIT!"
	accept_message = "I swear fealty to the Burgmeister and the Town Watch!"
	refuse_message = "I refuse."

/datum/job/watch_guard/militia
	title = "Town Watch Militia"
	department_flag = TOWNWATCH
	faction = FACTION_TOWN
	job_flags = 0
	display_order = JDO_WATCH_MILITIA
	total_positions = 0
	spawn_positions = 0
	give_bank_account = 0
	exp_requirements = 0

/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch/on_conversion(mob/living/cast_on)
	. = ..()
	cast_on.verbs |= /mob/proc/haltyell

/mob/proc/haltyell()
	set name = "HALT!"
	set category = "Emotes.Noises"
	emote("haltyell")
///Emegency authonomy system. When captain is absent, it's ability to recruit is given to the sergeant.
/proc/town_watch_captain_available()
	for (var/mob/living/carbon/human/H in GLOB.player_list)
		if (QDELETED(H))
			continue
		if (!H.client)
			continue
		if (H.stat == DEAD)
			continue
		if (!H.mind)
			continue
		if (H.mind.assigned_role != "Town Watch Captain")
			continue
		return TRUE

	return FALSE


/mob/living/carbon/human/proc/sync_town_watch_sergeant_command_state()
	if(!mind)
		return

	var/datum/job/J = mind.assigned_role
	if(!J)
		return

	if(J.parent_job)
		J = J.parent_job

	if(!istype(J, /datum/job/watch_sergeant))
		return

	if(town_watch_captain_available())
		remove_town_watch_sergeant_command()
	else
		grant_town_watch_sergeant_command()

/datum/job/watch_captain/proc/update_town_watch_sergeants()
	var/captain_available = town_watch_captain_available()

	for(var/mob/living/carbon/human/H in GLOB.player_list)
		if(!H.mind)
			continue

		var/datum/job/J = H.mind.assigned_role
		if(J?.parent_job)
			J = J.parent_job

		if(!istype(J, /datum/job/watch_sergeant))
			continue

		if(captain_available)
			H.remove_town_watch_sergeant_command()
		else
			H.grant_town_watch_sergeant_command()
