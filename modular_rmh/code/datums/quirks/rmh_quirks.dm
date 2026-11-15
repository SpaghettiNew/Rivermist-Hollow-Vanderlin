/datum/quirk/positive/restored
	abstract_type = /datum/quirk/positive/restored
	/// Restored boons should guarantee their bonuses after job loadout and skill setup.
	var/list/minimum_skill_ranks = list()
	var/list/stashed_items = list()
	var/list/granted_traits = list()
	var/list/granted_languages = list()
	var/list/granted_spells = list()
	var/list/stat_changes = list()
	var/human_only = TRUE

/datum/quirk/positive/restored/on_spawn()
	. = ..()
	if(!owner)
		return
	if(human_only && !ishuman(owner))
		return

	for(var/trait_id in granted_traits)
		ADD_TRAIT(owner, trait_id, "[type]")

	if(LAZYLEN(stat_changes))
		owner.set_stat_modifier("[type]", stat_changes)

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner
	for(var/language_type in granted_languages)
		human_owner.grant_language(language_type)

/datum/quirk/positive/restored/on_remove()
	. = ..()
	if(!owner)
		return
	if(human_only && !ishuman(owner))
		return

	for(var/trait_id in granted_traits)
		REMOVE_TRAIT(owner, trait_id, "[type]")

	if(LAZYLEN(stat_changes))
		owner.remove_stat_modifier("[type]")

	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner
	remove_stashed_items(human_owner, stashed_items)

/datum/quirk/positive/restored/after_job_spawn(datum/job/job)
	. = ..()
	if(!owner)
		return
	if(human_only && !ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner
	apply_minimum_skill_ranks(human_owner, minimum_skill_ranks)
	grant_stashed_items(human_owner, stashed_items)

	for(var/spell_type in granted_spells)
		human_owner.add_spell(spell_type, source = src)

/datum/quirk/positive/proc/apply_minimum_skill_ranks(mob/living/carbon/human/human_owner, list/skill_rank_minima)
	if(!ishuman(human_owner))
		return
	if(!LAZYLEN(skill_rank_minima))
		return

	for(var/skill_type in skill_rank_minima)
		human_owner.adjust_skillrank_up_to(skill_type, skill_rank_minima[skill_type], TRUE)

/datum/quirk/positive/proc/grant_stashed_items(mob/living/carbon/human/human_owner, list/item_map)
	if(!ishuman(human_owner))
		return
	if(!human_owner.mind)
		return
	if(!LAZYLEN(item_map))
		return

	for(var/item_name in item_map)
		human_owner.mind.special_items[item_name] = item_map[item_name]

/datum/quirk/positive/proc/remove_stashed_items(mob/living/carbon/human/human_owner, list/item_map)
	if(!ishuman(human_owner))
		return
	if(!human_owner.mind)
		return
	if(!LAZYLEN(item_map))
		return

	for(var/item_name in item_map)
		if(human_owner.mind.special_items[item_name] == item_map[item_name])
			human_owner.mind.special_items -= item_name

/datum/quirk/positive/value
	parent_type = /datum/quirk/positive/restored
	name = "Skilled Appraiser"
	desc = "I know how to estimate an item's value, more or less."
	point_value = -2
	granted_traits = list(TRAIT_SEEPRICES)

/datum/quirk/positive/night_owl
	parent_type = /datum/quirk/positive/restored
	name = "Night Owl"
	desc = "I've always preferred Lune over Elysius. I am no longer fatigued by being tired."
	point_value = -3
	granted_traits = list(TRAIT_NIGHT_OWL)

/datum/quirk/positive/duelist
	parent_type = /datum/quirk/positive/restored
	name = "Sword Training"
	desc = "I have sword training and a short sword stashed nearby."
	point_value = -2
	minimum_skill_ranks = list(/datum/skill/combat/swords = 30)
	stashed_items = list(
		"Short Sword" = /obj/item/weapon/sword/short,
	)

/datum/quirk/positive/fence
	parent_type = /datum/quirk/positive/restored
	name = "Fencer"
	desc = "I have trained in agile sword fighting. I dodge more easily without heavy protection and have a rapier stashed nearby."
	point_value = -4
	minimum_skill_ranks = list(/datum/skill/combat/swords = 30)
	stashed_items = list(
		"Rapier" = /obj/item/weapon/sword/rapier,
	)
	granted_traits = list(TRAIT_DODGEEXPERT)

/datum/quirk/positive/training2
	parent_type = /datum/quirk/positive/restored
	name = "Mace Training"
	desc = "I have mace training and a mace stashed nearby."
	point_value = -3
	minimum_skill_ranks = list(/datum/skill/combat/axesmaces = 30)
	stashed_items = list(
		"Mace" = /obj/item/weapon/mace/spiked,
	)

/datum/quirk/positive/training4
	parent_type = /datum/quirk/positive/restored
	name = "Polearms Training"
	desc = "I have polearm training and a spear stashed nearby."
	point_value = -3
	minimum_skill_ranks = list(/datum/skill/combat/polearms = 30)
	stashed_items = list(
		"Spear" = /obj/item/weapon/polearm/spear,
	)

/datum/quirk/positive/training5
	parent_type = /datum/quirk/positive/restored
	name = "Knife Training"
	desc = "I have knife training and a parrying dagger stashed nearby."
	point_value = -3
	minimum_skill_ranks = list(/datum/skill/combat/knives = 30)
	stashed_items = list(
		"Dagger" = /obj/item/weapon/knife/dagger/steel,
	)

/datum/quirk/positive/training6
	parent_type = /datum/quirk/positive/restored
	name = "Axe Training"
	desc = "I have trained with axes, and I'm a capable lumberjack. I've also stashed a copper axe."
	point_value = -3
	minimum_skill_ranks = list(
		/datum/skill/combat/axesmaces = 30,
		/datum/skill/labor/lumberjacking = 30,
	)
	stashed_items = list(
		"Axe" = /obj/item/weapon/axe/copper,
	)

/datum/quirk/positive/training8
	parent_type = /datum/quirk/positive/restored
	name = "Shield Training"
	desc = "I have shield training and a shield stashed nearby. As long as I have a shield in one hand, I can catch arrows with ease."
	point_value = -3
	minimum_skill_ranks = list(/datum/skill/combat/shields = 30)
	stashed_items = list(
		"Shield" = /obj/item/weapon/shield/wood,
	)

/datum/quirk/positive/training9
	parent_type = /datum/quirk/positive/restored
	name = "Unarmed Training"
	desc = "I have journeyman unarmed training and know how to wrestle barehanded."
	point_value = -3
	minimum_skill_ranks = list(
		/datum/skill/combat/unarmed = 30,
		/datum/skill/combat/wrestling = 30,
	)

/datum/quirk/positive/mtraining1
	parent_type = /datum/quirk/positive/restored
	name = "Medical Training"
	desc = "I have basic medical training and some medical supplies stashed nearby."
	point_value = -2
	minimum_skill_ranks = list(/datum/skill/misc/medicine = 40)
	stashed_items = list(
		"Patch Kit" = /obj/item/storage/fancy/ifak,
		"Surgery Kit" = /obj/item/storage/backpack/satchel/surgbag,
	)
	granted_spells = list(/datum/action/cooldown/spell/diagnose)

/datum/quirk/positive/greenthumb
	parent_type = /datum/quirk/positive/restored
	name = "Green Thumb"
	desc = "I've always been rather good at tending plants, and I have some powerful fertilizer stashed away, plus a hoe of ill repute."
	point_value = -2
	minimum_skill_ranks = list(/datum/skill/labor/farming = 40)
	stashed_items = list(
		"Fertilizer 1" = /obj/item/fertilizer,
		"Fertilizer 2" = /obj/item/fertilizer,
		"Fertilizer 3" = /obj/item/fertilizer,
		"Hoe" = /obj/item/weapon/hoe,
	)

/datum/quirk/positive/eagle_eyed
	parent_type = /datum/quirk/positive/restored
	name = "Eagle Eyed"
	desc = "I was always good at spotting distant things."
	point_value = -2
	stat_changes = list(
		(STAT_PERCEPTION) = 2,
	)

/datum/quirk/positive/training10
	parent_type = /datum/quirk/positive/restored
	name = "Bow Training"
	desc = "I have journeyman bow training and a bow stashed nearby."
	point_value = -3
	minimum_skill_ranks = list(/datum/skill/combat/bows = 30)
	stashed_items = list(
		"Bow" = /obj/item/gun/ballistic/revolver/grenadelauncher/bow/long,
		"Quiver" = /obj/item/ammo_holder/quiver/arrows,
	)

/datum/quirk/positive/bookworm
	parent_type = /datum/quirk/positive/restored
	name = "Bookworm"
	desc = "I love books and became quite skilled at reading and writing. What's more, my mind is sharper for the experience."
	point_value = -2
	minimum_skill_ranks = list(/datum/skill/misc/reading = 40)
	stat_changes = list(
		(STAT_INTELLIGENCE) = 2,
	)

/datum/quirk/positive/thief
	parent_type = /datum/quirk/positive/restored
	name = "Thief"
	desc = "Life's not easy around here, but I've made mine a little easier by taking from others. I'm great at picking pockets and locks, and I have some picks stashed nearby."
	point_value = -4
	minimum_skill_ranks = list(
		/datum/skill/misc/stealing = 40,
		/datum/skill/misc/lockpicking = 40,
	)
	stashed_items = list(
		"Lockpicks" = /obj/item/lockpickring/mundane,
	)

/datum/quirk/positive/languagesavant
	parent_type = /datum/quirk/positive/restored
	name = "Polyglot"
	desc = "I have always picked up languages easily. I know the tongues of the peoples found in this land, and my flexible tongue is certainly useful in the bedchamber."
	point_value = -2
	granted_traits = list(TRAIT_GOODLOVER)
	granted_languages = list(
		/datum/language/dwarvish,
		/datum/language/elvish,
		/datum/language/hellspeak,
		/datum/language/celestial,
		/datum/language/orcish,
		/datum/language/beast,
		/datum/language/thievescant,
	)

/datum/quirk/positive/mastercraftsmen
	parent_type = /datum/quirk/positive/restored
	name = "Jack of All Trades"
	desc = "I've always had steady hands. I'm experienced enough in most fine craftsmanship to make a career out of it, if I can procure my own tools."
	point_value = -4
	minimum_skill_ranks = list(
		/datum/skill/craft/crafting = 30,
		/datum/skill/craft/blacksmithing = 30,
		/datum/skill/craft/carpentry = 30,
		/datum/skill/craft/masonry = 30,
		/datum/skill/craft/cooking = 30,
		/datum/skill/craft/engineering = 30,
		/datum/skill/misc/sewing = 30,
		/datum/skill/craft/tanning = 30,
		/datum/skill/craft/smelting = 30,
	)

/datum/quirk/positive/masterbuilder
	parent_type = /datum/quirk/positive/restored
	name = "Practiced Builder"
	desc = "I have experience in putting up large structures and foundations for buildings. I can even use a sawmill if I can find one, and I have a handcart and two sacks hidden away for transporting my construction materials."
	point_value = -2
	preview_render = FALSE
	minimum_skill_ranks = list(
		/datum/skill/craft/carpentry = 40,
		/datum/skill/craft/masonry = 40,
		/datum/skill/craft/engineering = 40,
		/datum/skill/craft/crafting = 30,
	)
	stashed_items = list(
		"Sack 1" = /obj/item/storage/sack,
		"Sack 2" = /obj/item/storage/sack,
	)

/datum/quirk/positive/masterbuilder/after_job_spawn(datum/job/job)
	. = ..()
	if(!ishuman(owner))
		return

	var/turf/owner_turf = get_turf(owner)
	if(!owner_turf)
		return

	new /obj/structure/handcart(owner_turf)

/datum/quirk/positive/mastersmith
	parent_type = /datum/quirk/positive/restored
	name = "Practiced Smith"
	desc = "I am a metalworker by trade, and I have the tools for my practice stashed away."
	point_value = -4
	minimum_skill_ranks = list(
		/datum/skill/craft/blacksmithing = 40,
		/datum/skill/craft/engineering = 40,
		/datum/skill/craft/smelting = 40,
		/datum/skill/craft/crafting = 30,
	)
	stashed_items = list(
		"Hammer" = /obj/item/weapon/hammer,
		"Tongs" = /obj/item/weapon/tongs,
		"Coal" = /obj/item/ore/coal,
	)

/datum/quirk/positive/mastertailor
	parent_type = /datum/quirk/positive/restored
	name = "Practiced Tailor"
	desc = "I'm particularly skilled with needle, thread, and loom. I also have a needle, thread, and scissors hidden away."
	point_value = -4
	minimum_skill_ranks = list(
		/datum/skill/misc/sewing = 40,
		/datum/skill/craft/crafting = 40,
		/datum/skill/misc/medicine = 30,
	)
	stashed_items = list(
		"Scissors" = /obj/item/weapon/knife/scissors/steel,
		"Needle" = /obj/item/needle,
		"Thread" = /obj/item/natural/bundle/fibers/full,
	)

/datum/quirk/positive/bleublood
	parent_type = /datum/quirk/positive/restored
	name = "Noble Lineage"
	desc = "I am of noble blood."
	point_value = -3
	granted_traits = list(TRAIT_NOBLE)
	minimum_skill_ranks = list(/datum/skill/misc/reading = 20)

/datum/quirk/positive/richpouch
	parent_type = /datum/quirk/positive/restored
	name = "Rich Pouch"
	desc = "I have a pouch full of amnas."
	point_value = -2
	preview_render = FALSE

/datum/quirk/positive/richpouch/after_job_spawn(datum/job/job)
	. = ..()
	if(!ishuman(owner))
		return

	var/mob/living/carbon/human/human_owner = owner
	var/turf/owner_turf = get_turf(human_owner)
	if(!owner_turf)
		return

	var/obj/item/storage/belt/pouch/coins/rich/pouch = new(owner_turf)
	if(!human_owner.equip_to_appropriate_slot(pouch))
		human_owner.put_in_hands(pouch, forced = TRUE)

/datum/quirk/positive/nasty_eater
	parent_type = /datum/quirk/positive/restored
	name = "Not a Picky Eater"
	desc = "I can eat even the most spoiled, raw, or toxic food and water as if they were delicacies. I'm even immune to the berry poison some folk like to coat their arrows with."
	point_value = -2
	granted_traits = list(TRAIT_NASTY_EATER)

/datum/quirk/positive/alcohol_tolerance
	parent_type = /datum/quirk/positive/restored
	name = "Alcohol Tolerance"
	desc = "Alcohol doesn't affect me much."
	point_value = -1
	gain_text = span_notice("I feel like you could drink a whole keg!")
	lose_text = span_danger("I don't feel as resistant to alcohol anymore. Somehow.")
	granted_traits = list(TRAIT_LIGHT_DRINKER)

/datum/quirk/positive/empath
	parent_type = /datum/quirk/positive/restored
	name = "Empath"
	desc = "I can better tell the mood of those around me."
	point_value = -4
	gain_text = span_notice("I feel in tune with those around you.")
	lose_text = span_danger("I feel isolated from others.")
	granted_traits = list(TRAIT_EMPATH)

/datum/quirk/positive/musician
	parent_type = /datum/quirk/positive/restored
	name = "Musician"
	desc = "I am good at playing music, and I have a lute hidden away."
	point_value = -1
	gain_text = span_notice("I know everything about musical instruments.")
	lose_text = span_danger("I forget how musical instruments work.")
	granted_traits = list(TRAIT_MUSICIAN)
	stashed_items = list(
		"Lute" = /obj/item/instrument/lute,
	)

/datum/quirk/positive/selfaware
	parent_type = /datum/quirk/positive/restored
	name = "Self-Aware"
	desc = "I know the extent of my wounds to a terrifying scale."
	point_value = -2
	granted_traits = list(TRAIT_SELF_AWARE)
