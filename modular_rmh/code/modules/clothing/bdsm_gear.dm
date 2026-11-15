#define BDSM_GAG_DROOL_CHANCE 8
#define BDSM_SERPENT_STRUGGLE_COOLDOWN 5 SECONDS
#define BDSM_BLACK_LEATHER "#69656B"
#define BDSM_BROWN_LEATHER "#965F4B"

// The source sprites put the dyeable center behind one fixed leather and hardware overlay.
/obj/item/clothing/face/bdsm_gag
	name = "gag"
	desc = "A fitted leather gag with adjustable straps."
	icon = 'modular_rmh/icons/clothing/bdsm_gag_base_items.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/bdsm_gag_base_onmob.dmi'
	dyeable = FALSE
	modifies_speech = TRUE
	clothing_flags = BLOCKS_SPEECH
	flags_cover = MASKCOVERSMOUTH
	body_parts_covered = FACE|MOUTH
	resistance_flags = FLAMMABLE
	strip_delay = 3 SECONDS
	equip_delay_other = 3 SECONDS
	abstract_type = /obj/item/clothing/face/bdsm_gag
	var/fastened = TRUE
	var/can_lower = TRUE
	var/drool_chance = BDSM_GAG_DROOL_CHANCE

/// Concrete default gag used by the technician recipe catalogue. The DMI has
/// no generic "gag" state, so use the existing black muzzle artwork.
/obj/item/clothing/face/bdsm_gag/basic
	name = "gag"
	icon_state = "black_muzzle"

/obj/item/clothing/face/bdsm_gag/Initialize(mapload, ...)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/item/clothing/face/bdsm_gag/update_overlays()
	. = ..()
	var/mutable_appearance/fixed_details = mutable_appearance('modular_rmh/icons/clothing/bdsm_gag_fixed_items.dmi', "[icon_state]_fixed")
	fixed_details.appearance_flags = RESET_COLOR
	. += fixed_details

/obj/item/clothing/face/bdsm_gag/worn_overlays(mutable_appearance/standing, isinhands = FALSE, icon_file, dummy_block = FALSE)
	. = ..()
	if(isinhands)
		return
	var/mutable_appearance/fixed_details = mutable_appearance('modular_rmh/icons/clothing/onmob/bdsm_gag_fixed_onmob.dmi', "[standing.icon_state]_fixed")
	fixed_details.appearance_flags = RESET_COLOR
	. += fixed_details

/obj/item/clothing/face/bdsm_gag/AdjustClothes(mob/user)
	if(!can_lower || loc != user)
		return
	var/mob/living/carbon/human/wearer = user
	if(!istype(wearer) || wearer.wear_mask != src)
		return
	fastened = !fastened
	icon_state = fastened ? initial(icon_state) : "[initial(icon_state)]_r"
	if(fastened)
		clothing_flags |= BLOCKS_SPEECH
		flags_cover = initial(flags_cover)
		body_parts_covered = initial(body_parts_covered)
	else
		clothing_flags &= ~BLOCKS_SPEECH
		flags_cover &= ~MASKCOVERSMOUTH
		body_parts_covered = NECK
	to_chat(wearer, span_notice("You [fastened ? "fasten" : "lower"] [src]."))
	wearer.update_inv_wear_mask()
	update_appearance()

// Say() turns gagged speech into mumbling; the gag only adds drool.
/obj/item/clothing/face/bdsm_gag/handle_speech(mob/living/carbon/wearer, list/speech_args)
	if(!fastened || !istype(wearer) || wearer.wear_mask != src)
		return
	if(drool_chance && prob(drool_chance))
		INVOKE_ASYNC(wearer, TYPE_PROC_REF(/mob, emote), "drool")

/obj/item/clothing/face/bdsm_gag/examine(mob/user)
	. = ..()
	var/position_text = fastened ? "It is fastened over the mouth." : "It is lowered to the neck."
	. += span_notice(position_text)

/obj/item/clothing/face/bdsm_gag/build_worn_icon(age = AGE_ADULT, default_layer = 0, default_icon_file = null, isinhands = FALSE, femaleuniform = NO_FEMALE_UNIFORM, override_state = null, coom = FALSE, customi = null, sleeveindex, breast_size = 0, icon/clip_mask = null)
	if(!isinhands)
		var/mob/living/carbon/human/wearer = loc
		if(istype(wearer))
			override_state = icon_state
			if(wearer.dna?.species?.id == SPEC_ID_DWARF)
				override_state += "_dw"
			if(wearer.gender == FEMALE)
				override_state += "_f"
	return ..(age, default_layer, default_icon_file, isinhands, femaleuniform, override_state, coom, customi, sleeveindex, breast_size, clip_mask)

/obj/item/clothing/face/bdsm_gag/muzzle
	abstract_type = /obj/item/clothing/face/bdsm_gag/muzzle

/obj/item/clothing/face/bdsm_gag/muzzle/black
	name = "black leather muzzle"
	icon_state = "black_muzzle"

/obj/item/clothing/face/bdsm_gag/muzzle/brown
	name = "brown leather muzzle"
	icon_state = "brown_muzzle"

/obj/item/clothing/face/bdsm_gag/ball
	abstract_type = /obj/item/clothing/face/bdsm_gag/ball
	dyeable = TRUE

/obj/item/clothing/face/bdsm_gag/ball/black
	name = "black ball gag"
	icon_state = "black_ballgag"
	drool_chance = 14

/obj/item/clothing/face/bdsm_gag/ball/brown
	name = "brown ball gag"
	icon_state = "brown_ballgag"
	drool_chance = 14

/obj/item/clothing/face/bdsm_gag/ring
	name = "ring gag"
	desc = "A strapped ring that leaves the mouth open while making clear speech difficult."
	flags_cover = NONE
	body_parts_covered = FACE
	drool_chance = 20
	abstract_type = /obj/item/clothing/face/bdsm_gag/ring

/obj/item/clothing/face/bdsm_gag/ring/black
	name = "black ring gag"
	icon_state = "black_ringgag"

/obj/item/clothing/face/bdsm_gag/ring/brown
	name = "brown ring gag"
	icon_state = "brown_ringgag"

/obj/item/clothing/face/bdsm_gag/harness
	name = "harness gag"
	desc = "A gag secured by a full head harness. Its straps must be removed to free the mouth."
	dyeable = TRUE
	can_lower = FALSE
	strip_delay = 6 SECONDS
	equip_delay_other = 5 SECONDS
	drool_chance = 10
	abstract_type = /obj/item/clothing/face/bdsm_gag/harness

/obj/item/clothing/face/bdsm_gag/harness/black
	name = "black harness gag"
	icon_state = "black_harnessgag"

/obj/item/clothing/face/bdsm_gag/harness/brown
	name = "brown harness gag"
	icon_state = "brown_harnessgag"

// A fastened gag still lets voice through for muffled emotes; say() mumbles it.
/mob/living/carbon/human/can_speak_vocal(message)
	var/obj/item/clothing/face/bdsm_gag/gag = wear_mask
	if(!istype(gag) || !gag.fastened)
		return ..()
	if(HAS_TRAIT(src, TRAIT_MUTE) || HAS_TRAIT(src, TRAIT_BAGGED) || !IsVocal())
		return FALSE
	if(mouth?.muteinmouth || mouth_blocked)
		return FALSE
	for(var/obj/item/grabbing/grab in grabbedby)
		if(grab.sublimb_grabbed == BODY_ZONE_PRECISE_MOUTH)
			return FALSE
	if(istype(loc, /turf/open/water) && body_position == LYING_DOWN)
		return FALSE
	for(var/obj/item/clothing/other in get_equipped_items())
		if(other != gag && (other.clothing_flags & BLOCKS_SPEECH))
			return FALSE
	return TRUE

// General speech checks and voice packs see a gagged person as unable to speak clearly.
/mob/living/carbon/human/can_speak(message)
	var/obj/item/clothing/face/bdsm_gag/gag = wear_mask
	if(istype(gag) && gag.fastened)
		return FALSE
	return ..()

/mob/living/carbon/human/var/tmp/bdsm_gag_emote_range

/mob/living/carbon/human/audible_message(message, deaf_message, hearing_distance = DEFAULT_MESSAGE_RANGE, self_message, runechat_message = null)
	if(bdsm_gag_emote_range)
		hearing_distance = min(hearing_distance, bdsm_gag_emote_range)
	return ..(message, deaf_message, hearing_distance, self_message, runechat_message)

/datum/emote/living/run_emote(mob/user, params, type_override, intentional, targetted)
	var/mob/living/carbon/human/wearer = user
	if(!istype(wearer) || !(emote_type & EMOTE_AUDIBLE) || targetted || only_forced_audio)
		return ..()
	var/obj/item/clothing/face/bdsm_gag/gag = wearer.wear_mask
	if(!istype(gag) || !gag.fastened || istype(gag, /obj/item/clothing/face/bdsm_gag/ring) || (key == "scream" && !intentional))
		return ..()
	var/old_sound_range = snd_range
	var/old_message_range = wearer.bdsm_gag_emote_range
	var/nearby_range = istype(gag, /obj/item/clothing/face/bdsm_gag/harness) ? 2 : 3
	snd_range = nearby_range - SOUND_RANGE
	wearer.bdsm_gag_emote_range = nearby_range
	. = ..()
	snd_range = old_sound_range
	wearer.bdsm_gag_emote_range = old_message_range
	return .

/datum/emote/living/select_message_type(mob/user, intentional)
	. = ..()
	if(!(emote_type & EMOTE_AUDIBLE) || only_forced_audio)
		return
	var/mob/living/carbon/human/wearer = user
	if(!istype(wearer))
		return
	var/obj/item/clothing/face/bdsm_gag/gag = wearer.wear_mask
	if(!istype(gag) || !gag.fastened || (key == "scream" && !intentional))
		return
	if(istype(gag, /obj/item/clothing/face/bdsm_gag/ring))
		if(key in list("whimper", "gnarl", "alarm", "alert", "notice", "sigh", "chuckle", "moan", "groan", "yawn", "cry"))
			return
		. = "moans indistinctly through the ring."
	else
		if(key in list("whimper", "gnarl", "alarm", "alert", "notice", "chuckle", "mumble", "grumble"))
			return
		. = message_muffled || "makes a muffled noise."

/obj/item/clothing/neck/leathercollar/bdsm
	name = "leashed leather collar"
	desc = "A leather collar with a reinforced ring for a leash."
	icon = 'modular_rmh/icons/clothing/bdsm_leather_items.dmi'
	icon_state = null
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/bdsm_leather_onmob.dmi'
	dyeable = TRUE
	leashable = TRUE
	abstract_type = /obj/item/clothing/neck/leathercollar/bdsm
	var/leash_side

/obj/item/clothing/neck/leathercollar/bdsm/Initialize(mapload, ...)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)

/obj/item/clothing/neck/leathercollar/bdsm/update_overlays()
	. = ..()
	var/mutable_appearance/fixed_details = mutable_appearance('modular_rmh/icons/clothing/bdsm_fixed_items.dmi', "[icon_state]_fixed")
	fixed_details.appearance_flags = RESET_COLOR
	. += fixed_details

/obj/item/clothing/neck/leathercollar/bdsm/worn_overlays(mutable_appearance/standing, isinhands = FALSE, icon_file, dummy_block = FALSE)
	. = ..()
	if(isinhands)
		return
	var/mutable_appearance/fixed_details = mutable_appearance('modular_rmh/icons/clothing/onmob/bdsm_fixed_onmob.dmi', "[standing.icon_state]_fixed")
	fixed_details.appearance_flags = RESET_COLOR
	. += fixed_details

/obj/item/clothing/neck/leathercollar/bdsm/black
	name = "black leashed collar"
	icon_state = "black_leashed_collar"
	item_state = "black_leashed_collar"
	color = BDSM_BLACK_LEATHER

/obj/item/clothing/neck/leathercollar/bdsm/brown
	name = "brown leashed collar"
	icon_state = "brown_leashed_collar"
	item_state = "brown_leashed_collar"
	color = BDSM_BROWN_LEATHER

/obj/item/clothing/neck/leathercollar/bdsm/build_worn_icon(age = AGE_ADULT, default_layer = 0, default_icon_file = null, isinhands = FALSE, femaleuniform = NO_FEMALE_UNIFORM, override_state = null, coom = FALSE, customi = null, sleeveindex, breast_size = 0, icon/clip_mask = null)
	if(!isinhands)
		var/mob/living/carbon/human/wearer = loc
		var/female = istype(wearer) && wearer.gender == FEMALE
		if(leash_side)
			override_state = "[icon_state]_[leash_side]_[female ? "f" : "default"]"
		else
			override_state = "[icon_state]_[female ? "f" : "default"]"
	return ..(age, default_layer, default_icon_file, isinhands, femaleuniform, override_state, coom, customi, sleeveindex, breast_size, clip_mask)

/obj/item/leash/chain/bdsm
	name = "collar chain leash"
	desc = "A chain with a clasp sized for a leather collar or body harness."
	icon = 'modular_rmh/icons/clothing/bdsm_items.dmi'
	// The custom DMI has black_chain_leash and brown_chain_leash, not "chain".
	// The base item defaults to the black variant; the brown subtype overrides it.
	icon_state = "black_chain_leash"

/obj/item/leash/chain/bdsm/black
	name = "black collar chain leash"
	icon_state = "black_chain_leash"
	item_state = "black_chain_leash"

/obj/item/leash/chain/bdsm/brown
	name = "brown collar chain leash"
	icon_state = "brown_chain_leash"
	item_state = "brown_chain_leash"

/obj/item/leash/chain/bdsm/attach_pet(mob/living/target, mob/living/holder)
	. = ..()
	var/mob/living/carbon/human/wearer = target
	if(!istype(wearer))
		return
	var/obj/item/clothing/neck/leathercollar/bdsm/collar = wearer.wear_neck
	if(!istype(collar))
		return
	collar.leash_side = holder.x >= wearer.x ? "r" : "l"
	wearer.update_inv_neck()

/obj/item/leash/chain/bdsm/detach_pet(silent = FALSE)
	var/mob/living/carbon/human/wearer = leash_pet
	if(istype(wearer))
		var/obj/item/clothing/neck/leathercollar/bdsm/collar = wearer.wear_neck
		if(istype(collar))
			collar.leash_side = null
			wearer.update_inv_neck()
	return ..()

// A body harness is an alternative attachment point for this chain only.
/obj/item/leash/chain/bdsm/attack(mob/living/target, mob/living/user)
	var/mob/living/carbon/human/wearer = target
	if(!istype(wearer) || (!istype(wearer.wear_shirt, /obj/item/clothing/shirt/undershirt/bdsm_halfsuit) && !istype(wearer.undershirt, /obj/item/clothing/shirt/undershirt/bdsm_halfsuit)))
		return ..()
	if(leash_pet == target || target.GetComponent(/datum/component/leash) || leash_pet)
		return ..()
	if(wearer.wear_neck?.leashable)
		return ..()
	if(wearer.cmode && (wearer.mobility_flags & MOBILITY_STAND))
		to_chat(user, span_warning("[wearer] is too tense to leash."))
		return
	user.visible_message(span_notice("[user] reaches for [wearer]'s harness clasp."))
	if(!do_after(user, wearer.handcuffed ? 1 SECONDS : 5 SECONDS, target))
		return
	if(QDELETED(src) || QDELETED(wearer) || leash_pet || target.GetComponent(/datum/component/leash) || (!istype(wearer.wear_shirt, /obj/item/clothing/shirt/undershirt/bdsm_halfsuit) && !istype(wearer.undershirt, /obj/item/clothing/shirt/undershirt/bdsm_halfsuit)))
		return
	attach_pet(wearer, user)
	log_combat(user, wearer, "leashed to harness")
	wearer.visible_message(span_warning("[user] clips [src] to [wearer]'s harness."))

/obj/item/leash/chain/bdsm/on_pet_unequipped(mob/living/source, obj/item/item, force, newloc, no_move, invdrop, silent)
	var/mob/living/carbon/human/wearer = leash_pet
	if(istype(wearer) && (istype(wearer.wear_shirt, /obj/item/clothing/shirt/undershirt/bdsm_halfsuit) || istype(wearer.undershirt, /obj/item/clothing/shirt/undershirt/bdsm_halfsuit)))
		return
	return ..()

/obj/item/rope/bdsm_shackles
	name = "leather shackles"
	desc = "Adjustable restraints for wrists or ankles. In front, the wearer can handle only tiny objects."
	icon = 'modular_rmh/icons/clothing/bdsm_items.dmi'
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	possible_item_intents = list(/datum/intent/tie)
	breakouttime = 12 SECONDS
	slipouttime = 35 SECONDS
	legcuff_multiplicative_slowdown = 2
	var/front_bound = FALSE
	var/worn_state

/obj/item/rope/bdsm_shackles/Initialize(mapload, ...)
	. = ..()
	if(dyeable)
		update_appearance(UPDATE_OVERLAYS)

/obj/item/rope/bdsm_shackles/black
	name = "black leather shackles"
	icon_state = "black_shackles"
	worn_state = "black_shackles"
	icon = 'modular_rmh/icons/clothing/bdsm_leather_items.dmi'
	color = BDSM_BLACK_LEATHER
	dyeable = TRUE

/obj/item/rope/bdsm_shackles/brown
	name = "brown leather shackles"
	icon_state = "brown_shackles"
	worn_state = "brown_shackles"
	icon = 'modular_rmh/icons/clothing/bdsm_leather_items.dmi'
	color = BDSM_BROWN_LEATHER
	dyeable = TRUE

/obj/item/rope/bdsm_shackles/update_overlays()
	. = ..()
	if(!dyeable)
		return
	var/mutable_appearance/fixed_details = mutable_appearance('modular_rmh/icons/clothing/bdsm_fixed_items.dmi', "[icon_state]_fixed")
	fixed_details.appearance_flags = RESET_COLOR
	. += fixed_details

/obj/item/rope/bdsm_shackles/iron
	name = "iron shackles"
	desc = "Heavy iron restraints whose links announce every step."
	icon_state = "shackles_iron"
	worn_state = "shackles_iron"
	breakouttime = 30 SECONDS
	slipouttime = 1 MINUTES
	legcuff_multiplicative_slowdown = 3
	front_bound = FALSE

/obj/item/rope/bdsm_shackles/serpent
	name = "serpent shackles"
	desc = "Ornate serpent-shaped restraints. Their clasps resist frantic escape attempts."
	icon_state = "shackles_serpent"
	worn_state = "shackles_serpent"
	breakouttime = 22 SECONDS
	slipouttime = 45 SECONDS
	legcuff_multiplicative_slowdown = 2.5
	var/last_struggle

/obj/item/rope/bdsm_shackles/attack_self(mob/user)
	if(loc != user)
		return
	front_bound = !front_bound
	to_chat(user, span_notice("You set [src] for [front_bound ? "front" : "back"] wrist binding."))

/obj/item/rope/bdsm_shackles/examine(mob/user)
	. = ..()
	. += span_notice("The wrist clasp is set for [front_bound ? "front" : "back"] binding.")

/obj/item/rope/bdsm_shackles/apply_cuffs(mob/living/carbon/target, mob/user, leg = FALSE)
	. = ..()
	if(!. || leg || !front_bound)
		return
	for(var/obj/item/held in target.held_items)
		if(held.w_class > WEIGHT_CLASS_TINY || held.force > 0)
			target.dropItemToGround(held)

/mob/living/carbon/human/set_handcuffed(new_value)
	. = ..()
	var/obj/item/rope/bdsm_shackles/cuffs = handcuffed
	if(istype(cuffs) && cuffs.front_bound)
		REMOVE_TRAIT(src, TRAIT_RESTRAINED, HANDCUFFED_TRAIT)
	return .

/mob/living/carbon/human/put_in_hand_check(obj/item/thing)
	var/obj/item/rope/bdsm_shackles/cuffs = handcuffed
	if(istype(cuffs) && cuffs.front_bound && thing && (thing.w_class > WEIGHT_CLASS_TINY || thing.force > 0))
		to_chat(src, span_warning("Your front-bound wrists cannot manage [thing]."))
		return FALSE
	return ..()

/mob/living/carbon/human/UnarmedAttack(atom/target, proximity, list/modifiers, atom/source)
	var/obj/item/rope/bdsm_shackles/cuffs = handcuffed
	if(istype(cuffs) && cuffs.front_bound && isliving(target) && used_intent.type != INTENT_HELP)
		to_chat(src, span_warning("Your front-bound wrists cannot manage a fight."))
		return FALSE
	return ..()

/mob/living/carbon/human/cuff_resist(obj/item/restraint, breakouttime = 1 MINUTES, cuff_break = 0, instant = FALSE)
	var/obj/item/rope/bdsm_shackles/serpent/serpent_cuffs = restraint
	if(istype(serpent_cuffs) && !instant)
		if(serpent_cuffs.last_struggle && world.time < serpent_cuffs.last_struggle + BDSM_SERPENT_STRUGGLE_COOLDOWN)
			to_chat(src, span_warning("The serpent clasps tighten. Let them settle before trying again."))
			return
		serpent_cuffs.last_struggle = world.time
	return ..()

/mob/living/carbon/human/proc/bdsm_restraint_state(obj/item/rope/bdsm_shackles/cuffs)
	var/state = cuffs.worn_state
	if(dna?.species?.id == SPEC_ID_DWARF)
		state += "_dw"
	if(gender == FEMALE)
		state += "_f"
	return state

/mob/living/carbon/human/update_inv_handcuffed()
	. = ..()
	var/obj/item/rope/bdsm_shackles/cuffs = handcuffed
	if(!istype(cuffs))
		return
	var/mutable_appearance/old_overlay = overlays_standing[HANDCUFF_LAYER]
	remove_overlay(HANDCUFF_LAYER)
	var/state = bdsm_restraint_state(cuffs)
	var/icon_file = cuffs.dyeable ? 'modular_rmh/icons/clothing/onmob/bdsm_leather_onmob.dmi' : 'modular_rmh/icons/clothing/onmob/bdsm_onmob.dmi'
	var/mutable_appearance/new_overlay = mutable_appearance(icon_file, state, -HANDCUFF_LAYER)
	new_overlay.pixel_x = old_overlay?.pixel_x
	new_overlay.pixel_y = old_overlay?.pixel_y
	if(cuffs.dyeable)
		new_overlay.color = cuffs.color
		var/mutable_appearance/fixed_details = mutable_appearance('modular_rmh/icons/clothing/onmob/bdsm_fixed_onmob.dmi', "[state]_fixed")
		fixed_details.appearance_flags = RESET_COLOR
		new_overlay.overlays.Add(fixed_details)
	overlays_standing[HANDCUFF_LAYER] = new_overlay
	apply_overlay(HANDCUFF_LAYER)

/mob/living/carbon/human/update_inv_legcuffed()
	. = ..()
	var/obj/item/rope/bdsm_shackles/cuffs = legcuffed
	if(!istype(cuffs))
		return
	remove_overlay(LEGCUFF_LAYER)
	var/state = bdsm_restraint_state(cuffs)
	var/icon_file = cuffs.dyeable ? 'modular_rmh/icons/clothing/onmob/bdsm_leather_onmob.dmi' : 'modular_rmh/icons/clothing/onmob/bdsm_onmob.dmi'
	var/mutable_appearance/new_overlay = mutable_appearance(icon_file, state, -LEGCUFF_LAYER)
	if(cuffs.dyeable)
		new_overlay.color = cuffs.color
		var/mutable_appearance/fixed_details = mutable_appearance('modular_rmh/icons/clothing/onmob/bdsm_fixed_onmob.dmi', "[state]_fixed")
		fixed_details.appearance_flags = RESET_COLOR
		new_overlay.overlays.Add(fixed_details)
	overlays_standing[LEGCUFF_LAYER] = new_overlay
	apply_overlay(LEGCUFF_LAYER)

/obj/item/clothing/shirt/undershirt/bdsm_nundorei
	name = "penitent nun outfit"
	desc = "A severe ceremonial outfit whose fitted straps make every bow deliberate."
	icon = 'modular_rmh/icons/clothing/bdsm_items.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/bdsm_onmob.dmi'
	icon_state = "nundorei"
	item_state = "nundorei"
	sleeved = null
	allowed_race = SPECIES_BASE_BODY

/obj/item/clothing/shirt/undershirt/bdsm_nundorei/attack_self(mob/living/user)
	if(loc == user)
		user.emote("pray", intentional = TRUE)

/obj/item/clothing/shirt/undershirt/bdsm_halfsuit
	name = "leather halfsuit"
	desc = "A close-fitted leather harness with a reinforced leash clasp."
	icon = 'modular_rmh/icons/clothing/bdsm_gor_leather_items.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/bdsm_gor_leather_onmob.dmi'
	icon_state = "leatherhalfsuit"
	item_state = "leatherhalfsuit"
	detail_tag = "_glare"
	detail_color = "#FFFFFF"
	sleeved = null
	boobed = FALSE
	allowed_race = SPECIES_BASE_BODY
	color = CLOTHING_BLACK
	dyeable = TRUE

/obj/item/clothing/legwears/bdsm_leather
	name = "leather stockings"
	desc = "Fitted leather stockings, cut to be worn beneath other clothing."
	icon = 'modular_rmh/icons/clothing/bdsm_gor_leather_items.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/bdsm_gor_leather_onmob.dmi'
	icon_state = "leatherstockings"
	item_state = "leatherstockings"
	detail_tag = "_glare"
	detail_color = "#FFFFFF"
	slot_flags = ITEM_SLOT_SOCKS
	muteinmouth = FALSE
	damaged_icon = null
	damaged_overlay_icon = null
	color = CLOTHING_BLACK
	dyeable = TRUE

/obj/item/clothing/gloves/bdsm_leather
	name = "leather gloves"
	desc = "Fitted gloves with a crisp snap at the wrist."
	icon = 'modular_rmh/icons/clothing/bdsm_gor_leather_items.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/bdsm_gor_leather_onmob.dmi'
	icon_state = "leathergloves"
	item_state = "leathergloves"
	detail_tag = "_glare"
	detail_color = "#FFFFFF"
	sleeved = 'modular_rmh/icons/clothing/onmob/bdsm_glove_sleeves.dmi'
	resistance_flags = FLAMMABLE
	color = CLOTHING_BLACK
	dyeable = TRUE

/obj/item/clothing/gloves/bdsm_leather/attack_self(mob/living/user)
	if(loc != user)
		return
	user.visible_message(span_notice("[user] snaps [src] against [user.p_their()] wrist."), span_notice("You snap [src] against your wrist."))
	playsound(user, 'sound/foley/equip/cloak_equip.ogg', 35, TRUE)

#undef BDSM_GAG_DROOL_CHANCE
#undef BDSM_SERPENT_STRUGGLE_COOLDOWN
#undef BDSM_BLACK_LEATHER
#undef BDSM_BROWN_LEATHER
