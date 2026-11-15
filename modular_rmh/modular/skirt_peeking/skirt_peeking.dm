/**
 * ## Skirt peeking
 *
 * Lets an adjacent player peek under a skirt, kilt, loincloth or dress.
 *
 * A first examine adds a hint that peeking is possible. To actually peek, the
 * peeker must have the groin selected in their HUD and take a second, closer
 * look (examine_more) at the same target while still adjacent. Anything else
 * worn that covers the groin blocks the peek; an apron never does.
 *
 * Reveals underwear, otherwise the target's genital descriptors, plus any
 * stockings or garter that a normal look would not already show. Penis and
 * vagina text is tinted from the target's body color toward a flushed tone as
 * arousal rises, and pulses at maximum arousal.
 */
/datum/element/skirt_peeking
	element_flags = ELEMENT_DETACH

/datum/element/skirt_peeking/Attach(datum/peeked)
	. = ..()
	if(!ishuman(peeked))
		return ELEMENT_INCOMPATIBLE

	RegisterSignal(peeked, COMSIG_PARENT_EXAMINE, PROC_REF(on_examine))
	RegisterSignal(peeked, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(on_examine_more))

/datum/element/skirt_peeking/Detach(datum/source, force)
	UnregisterSignal(source, list(COMSIG_PARENT_EXAMINE, COMSIG_ATOM_EXAMINE_MORE))
	return ..()

/datum/element/skirt_peeking/proc/get_peekable_garment(mob/living/carbon/human/peeked, mob/living/peeker, announce_blockers = FALSE)
	var/list/worn_layers = list(peeked.wear_pants, peeked.wear_armor, peeked.wear_shirt, peeked.cloak)

	var/obj/item/clothing/garment
	for(var/obj/item/clothing/candidate in worn_layers)
		if(is_type_in_typecache(candidate.type, GLOB.skirt_peekable_garments))
			garment = candidate
			break

	if(!garment)
		return null

	var/sneaking_peeker = announce_blockers && istype(peeker) && peeker.m_intent == MOVE_INTENT_SNEAK
	for(var/obj/item/worn in worn_layers)
		if(worn == garment || istype(worn, /obj/item/clothing/cloak/apron))
			continue
		if(!CHECK_BITFIELD(worn.body_parts_covered, GROIN))
			continue
		if(sneaking_peeker)
			to_chat(peeker, span_notice("([peeked]'s [worn.name] is blocking your view.)"))
		return null

	return garment

/datum/element/skirt_peeking/proc/on_examine(mob/living/carbon/human/peeked, mob/user, list/examine_list, list/P)
	SIGNAL_HANDLER

	if(user == peeked)
		return

	var/mob/living/maybe_peeker = isliving(user) ? user : null
	var/obj/item/clothing/garment = get_peekable_garment(peeked, maybe_peeker, announce_blockers = TRUE)
	if(!garment)
		return

	var/peek_word = span_tooltip("Target the groin, stand right next to [P[THEM]] and examine [P[THEM]] again.", "<b>peek</b>")
	LAZYADDASSOCLIST(examine_list, EXAMINE_SECT_BODY, span_purple("[capitalize(P[THEY])] [P[ARE]] wearing [garment.name]! You could probably [peek_word] underneath..."))

/datum/element/skirt_peeking/proc/color_by_arousal(text, mob/living/carbon/human/peeked, arousal)
	if(!text)
		return text

	var/weight
	var/pulsing = FALSE
	switch(arousal)
		if(80 to INFINITY)
			weight = 0.75
			pulsing = TRUE
		if(50 to 80)
			weight = 0.5
		if(20 to 50)
			weight = 0.25
		else
			return text

	var/base_hex = (peeked.dna?.species) ? peeked.dna.species.get_body_color(peeked) : null
	var/list/base_rgb = base_hex ? ReadRGB(base_hex) : null
	if(!base_rgb)
		base_rgb = list(255, 255, 255)

	var/r = round(base_rgb[1] * (1 - weight) + 235 * weight)
	var/g = round(base_rgb[2] * (1 - weight) + 30 * weight)
	var/b = round(base_rgb[3] * (1 - weight) + 60 * weight)

	. = "<font color='[rgb(r, g, b)]'>[text]</font>"
	if(pulsing)
		. = "<style>@keyframes skirt_peek_pulse{0%{opacity:1}50%{opacity:0.4}100%{opacity:1}}</style><span style='animation:skirt_peek_pulse 0.4s ease-in-out infinite'>[.]</span>"

/datum/element/skirt_peeking/proc/on_examine_more(mob/living/carbon/human/peeked, mob/user, list/examine_list)
	SIGNAL_HANDLER

	if(!isliving(user) || user == peeked)
		return
	var/mob/living/peeker = user

	if(peeker.zone_selected != BODY_ZONE_PRECISE_GROIN)
		return

	var/obj/item/clothing/garment = get_peekable_garment(peeked, peeker)
	if(!garment)
		return
	if(!peeker.Adjacent(peeked))
		examine_list += span_notice("I would need to be right next to [peeked] to peek under [garment.name].")
		return

	var/obj/item/clothing/undies/undies = peeked.underwear

	var/list/arousal_data = list()
	SEND_SIGNAL(peeked, COMSIG_SEX_GET_AROUSAL, arousal_data)
	var/arousal = arousal_data["arousal"]

	var/their = peeked.p_their()
	var/list/seen = list()

	if(undies)
		var/undies_display = undies.color ? "<font color='[undies.color]'>[undies.name]</font>" : undies.name
		seen += undies_display

		if(arousal > VISIBLE_AROUSAL_THRESHOLD)
			if(peeked.getorganslot(ORGAN_SLOT_PENIS))
				seen += color_by_arousal("[capitalize(peeked.p_theyre())] pitching a tent in [their] [undies_display]", peeked, arousal)
			else if(peeked.getorganslot(ORGAN_SLOT_VAGINA))
				seen += color_by_arousal("[capitalize(peeked.p_theyve())] a wet spot on [their] [undies_display]", peeked, arousal)
	else
		if(peeked.getorganslot(ORGAN_SLOT_BUTT))
			var/datum/mob_descriptor/butt/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/butt)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += text

		if(peeked.getorganslot(ORGAN_SLOT_PENIS))
			var/datum/mob_descriptor/penis/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/penis)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += color_by_arousal(text, peeked, arousal)

		if(peeked.getorganslot(ORGAN_SLOT_TESTICLES))
			var/datum/mob_descriptor/testicles/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/testicles)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += text

		if(peeked.getorganslot(ORGAN_SLOT_VAGINA))
			var/datum/mob_descriptor/vagina/descriptor = MOB_DESCRIPTOR(/datum/mob_descriptor/vagina)
			var/text = descriptor.get_description(peeked)
			if(text)
				seen += color_by_arousal(text, peeked, arousal)

		if(!length(seen))
			seen += "nothing in particular"

	var/list/obscured_slots = peeked.check_obscured_slots()

	var/obj/item/clothing/legwears/socks = peeked.legwear_socks
	if(socks && CHECK_MULTIPLE_BITFIELDS(obscured_slots[SLOT_CHECK_EXTRA], ITEM_SLOT_SOCKS))
		seen += socks.color ? "<font color='[socks.color]'>[socks.name]</font>" : socks.name

	var/obj/item/clothing/garter/garter_worn = peeked.garter
	if(garter_worn && CHECK_MULTIPLE_BITFIELDS(obscured_slots[SLOT_CHECK_EXTRA], ITEM_SLOT_GARTER))
		seen += garter_worn.color ? "<font color='[garter_worn.color]'>[garter_worn.name]</font>" : garter_worn.name

	examine_list += span_purple("You peek under [garment.name] at [peeked]. You see [english_list(seen, and_text = " and ")].")

GLOBAL_LIST_EMPTY(skirt_peekable_garments)

#define SKIRT_PEEKABLE_KEYWORDS list("skirt", "kilt", "loincloth", "dress")

/proc/register_skirt_peekable(obj/item/clothing/garment)
	if(is_type_in_typecache(garment.type, GLOB.skirt_peekable_garments))
		return
	var/type_path_text = "[garment.type]"
	for(var/keyword in SKIRT_PEEKABLE_KEYWORDS)
		if(findtext(type_path_text, keyword))
			GLOB.skirt_peekable_garments[garment.type] = TRUE
			return

#undef SKIRT_PEEKABLE_KEYWORDS

/obj/item/clothing/pants/Initialize(mapload)
	. = ..()
	register_skirt_peekable(src)

/obj/item/clothing/shirt/Initialize(mapload)
	. = ..()
	register_skirt_peekable(src)

GLOBAL_DATUM_INIT(skirt_peeking_glue, /datum/skirt_peeking_glue, new)

/datum/skirt_peeking_glue

/datum/skirt_peeking_glue/New()
	. = ..()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))

/datum/skirt_peeking_glue/proc/on_mob_created(datum/source, mob/new_mob)
	SIGNAL_HANDLER

	if(ishuman(new_mob))
		new_mob.AddElement(/datum/element/skirt_peeking)

/// Returns the first worn layer over the groin that stops a hand reaching the underwear; skirts and aprons let it through.
/mob/living/carbon/human/proc/get_underwear_blocker()
	for(var/obj/item/worn in list(wear_pants, wear_armor, wear_shirt, cloak))
		if(!CHECK_BITFIELD(worn.body_parts_covered, GROIN))
			continue
		if(istype(worn, /obj/item/clothing/cloak/apron) || is_type_in_typecache(worn.type, GLOB.skirt_peekable_garments))
			continue
		return worn
	return null
