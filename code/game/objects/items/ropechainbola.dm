
/obj/item/rope
	item_weight = 300 GRAMS
	name = "rope"
	desc = "A series of threads intertwined to create a firm rope for binding, hanging and other jobs."
	gender = PLURAL
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "rope"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS|ITEM_SLOT_NECK|ITEM_SLOT_BELT
	throwforce = 3
	w_class = WEIGHT_CLASS_SMALL
	throw_speed = 1
	throw_range = 5
	breakouttime = 10 SECONDS
	slipouttime = 30 SECONDS
	possible_item_intents = list(/datum/intent/tie)
	firefuel = 5 MINUTES
	drop_sound = 'sound/foley/dropsound/cloth_drop.ogg'

	var/legcuff_multiplicative_slowdown = 3
	var/cuffing_time = 6 SECONDS
	var/tie_sound = 'modular_rmh/sound/items/ropetyingup.ogg'
	var/untie_sound = 'modular_rmh/sound/items/ropeuntying.ogg'

/obj/item/rope/spider_silk
	name = "spider silk"
	desc = "A tacky coil of fresh spider silk, spun thick enough to bind wrists."
	icon = 'icons/roguetown/misc/webbing.dmi'
	icon_state = "stickyweb3"
	breakouttime = 12 SECONDS
	slipouttime = 36 SECONDS

/obj/item/rope/mob_can_equip(mob/living/M, mob/living/equipper, slot, disable_warning, bypass_equip_delay_self)
	. = ..()
	if(.)
		if((slot & ITEM_SLOT_BELT) && !equipper)
			if(!do_after(M, 1.5 SECONDS, src))
				return FALSE

/obj/item/rope/equipped(mob/living/carbon/human/user, slot)
	. = ..()
	if(slot & ITEM_SLOT_BELT)
		user.temporarilyRemoveItemFromInventory(src)
		user.equip_to_slot_if_possible(new /obj/item/storage/belt/leather/rope(get_turf(user)), ITEM_SLOT_BELT)
		qdel(src)

/datum/intent/tie
	name = "tie"
	icon_state = "intie"
	chargetime = 0
	noaa = TRUE
	candodge = FALSE
	canparry = FALSE
	misscost = 0

/obj/item/rope/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		if(M.handcuffed == src)
			M.set_handcuffed(null)
			M.update_handcuffed()
			if(M.buckled && M.buckled.buckle_requires_restraints)
				M.buckled.unbuckle_mob(M)
		if(M.legcuffed == src)
			M.legcuffed = null
			M.update_inv_legcuffed()
			M.remove_movespeed_modifier(MOVESPEED_ID_LEGCUFF_SLOWDOWN, TRUE)
	return ..()

/obj/item/rope/attack(mob/living/carbon/C, mob/living/user, list/modifiers)
	if(user.used_intent.type != /datum/intent/tie)
		..()
		return

	if(!istype(C))
		return

	var/surrender_mod = 1
	if(C.surrendering || HAS_TRAIT(C, TRAIT_BAGGED))
		surrender_mod = 0.5

	if(user.aimheight >= 5)
		if(!C.handcuffed)
			if(C.num_hands)
				C.visible_message(span_warning("[user] is trying to tie [C]'s arms with [src.name]!"), span_danger("[user] is trying to tie my arms with [src.name]!"))
				playsound(src, tie_sound, 75, TRUE)

				if(do_after(user, cuffing_time * surrender_mod, C) && C.num_hands)
					if(apply_cuffs(C, user, leg = FALSE))
						C.visible_message(span_warning("[user] ties [C]' arms with [src.name]."), span_danger("[user] ties my arms up with [src.name]."))
						SSblackbox.record_feedback("tally", "handcuffs", 1, type)
						user.adjust_experience(/datum/attribute/skill/craft/traps, GET_MOB_ATTRIBUTE_VALUE(C, STAT_INTELLIGENCE), FALSE)
						log_combat(user, C, "handcuffed")
				else
					to_chat(user, span_warning("I fail to tie up [C]'s arms!"))
			else
				to_chat(user, span_warning("[C] is missing two or one arms."))
	else
		if(!C.legcuffed)
			if(C.num_legs)
				C.visible_message(span_warning("[user] is trying to tie [C]'s legs with [src.name]!"), span_danger("[user] is trying to tie my legs with [src.name]!"))
				playsound(src, tie_sound, 75, TRUE)

				if(do_after(user, cuffing_time * (C.surrendering ? 0.5 : 1), C) && C.num_legs)
					if(apply_cuffs(C, user, leg = TRUE))
						C.visible_message(span_warning("[user] ties [C]' legs with [src.name]."), span_danger("[user] ties my legs up with [src.name]."))
						SSblackbox.record_feedback("tally", "legcuffs", 1, type)
						user.adjust_experience(/datum/attribute/skill/craft/traps, GET_MOB_ATTRIBUTE_VALUE(C, STAT_INTELLIGENCE), FALSE)
						log_combat(user, C, "legcuffed")
				else
					to_chat(user, span_warning("I fail to tie up [C]'s legs!"))
			else
				to_chat(user, span_warning("[C] is missing two or one legs."))

/obj/item/rope/proc/apply_cuffs(mob/living/carbon/target, mob/user, leg = FALSE)
	if(!leg)
		if(target.handcuffed)
			return

		if(user && !user.temporarilyRemoveItemFromInventory(src) )
			return

		var/obj/item/cuffs = src

		cuffs.forceMove(target)
		target.set_handcuffed(cuffs)

		target.update_handcuffed()
		return TRUE
	else
		if(target.legcuffed)
			return FALSE

		if(user && !user.temporarilyRemoveItemFromInventory(src))
			return

	var/obj/item/cuffs = src

	cuffs.forceMove(target)
	if(leg)
		target.legcuffed = cuffs
		target.add_movespeed_modifier(MOVESPEED_ID_LEGCUFF_SLOWDOWN, multiplicative_slowdown = legcuff_multiplicative_slowdown)
		target.update_inv_legcuffed()
		return TRUE

/obj/item/rope/chain
	item_weight = 1.2 KILOGRAMS
	name = "chain"
	desc = "Metal chains designed to interlock and apply the harshest confinement on the villainous."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "chain"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	force = DAMAGE_WHIP - 10
	throwforce = DAMAGE_WHIP - 15
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 30 SECONDS
	slipouttime = 1 MINUTES
	melting_material = /datum/material/iron
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'
	tie_sound = 'modular_rmh/sound/items/Chainrattle.ogg'
	untie_sound = 'modular_rmh/sound/items/Chainrattle.ogg'
	cuffing_time = 7 SECONDS

/obj/item/rope/chain/steel
	item_weight = 1.1 KILOGRAMS
	name = "Steel chain"
	desc = "Metal chains designed to interlock and apply the harshest confinement on the villainous."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "steelchain"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	force = DAMAGE_WHIP - 25
	throwforce = DAMAGE_WHIP - 20
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 50 SECONDS
	slipouttime = 1 MINUTES
	melting_material = /datum/material/steel
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'
	cuffing_time = 8 SECONDS

/obj/item/rope/chain/gold
	item_weight = 1.6 KILOGRAMS
	name = "Gold chain"
	desc = "Metal chains designed to interlock and apply the harshest confinement on the villainous."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "goldchain"
	grid_width = 32
	grid_height = 32
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	force = DAMAGE_WHIP - 25
	throwforce = DAMAGE_WHIP - 20
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 25 SECONDS
	slipouttime = 45 SECONDS
	melting_material = /datum/material/gold
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'
	cuffing_time = 5 SECONDS

/obj/item/rope/chain/silver
	item_weight = 1.1 KILOGRAMS
	name = "Silver chain"
	desc = "A heavy chain forged from silver. Those afflicted by silver's bane weaken merely from being restrained by it."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "silverchain"

	force = DAMAGE_WHIP - 10
	throwforce = DAMAGE_WHIP - 15
	wdefense = MEDIOCRE_PARRY
	possible_item_intents = list(/datum/intent/tie, WHIP_LASH)
	blade_dulling = DULLING_BASHCHOP
	parrysound = list('sound/combat/parry/parrygen.ogg')
	swingsound = WHIPWOOSH
	w_class = WEIGHT_CLASS_SMALL
	associated_skill = /datum/attribute/skill/combat/whipsflails
	throw_speed = 1
	throw_range = 3
	breakouttime = 40 SECONDS
	slipouttime = 1 MINUTES
	cuffing_time = 9 SECONDS
	melting_material = /datum/material/silver
	melt_amount = 40
	firefuel = null
	drop_sound = 'sound/foley/dropsound/chain_drop.ogg'

/obj/item/rope/chain/silver/proc/get_silver_bane_modifier_id()
	return "silver_chain_[REF(src)]"

/obj/item/rope/chain/silver/proc/is_silver_bane_target(mob/living/carbon/target)
	if(!ishuman(target) || !target.mind)
		return FALSE

	var/datum/antagonist/vampire/vamp_datum = target.mind.has_antag_datum(/datum/antagonist/vampire)
	var/datum/antagonist/werewolf/wolf_datum = target.mind.has_antag_datum(/datum/antagonist/werewolf)

	// Ascended vampire lords are immune to silver's bane.
	if(istype(vamp_datum, /datum/antagonist/vampire/lord))
		var/datum/antagonist/vampire/lord/lord_datum = vamp_datum
		return !lord_datum.ascended

	// Vampires are always affected; werewolves only while transformed.
	if(vamp_datum || wolf_datum?.transformed)
		return TRUE
	return FALSE

/obj/item/rope/chain/silver/proc/apply_silver_bane(mob/living/carbon/target)
	if(!target || !is_silver_bane_target(target))
		return

	target.set_stat_modifier(
		get_silver_bane_modifier_id(),
		list(
			STAT_STRENGTH = -2,
			STAT_PERCEPTION = -2,
			STAT_ENDURANCE = -2,
			STAT_SPEED = -2,
		))

/obj/item/rope/chain/silver/proc/remove_silver_bane(mob/living/carbon/target)
	if(!target)
		return

	target.remove_stat_modifier(get_silver_bane_modifier_id())

/obj/item/rope/chain/silver/apply_cuffs(mob/living/carbon/target, mob/user, leg = FALSE)
	. = ..()

	if(.)
		apply_silver_bane(target)

/obj/item/rope/chain/silver/dropped(mob/user, silent = FALSE)
	var/mob/living/carbon/target

	if(iscarbon(loc))
		target = loc
	else if(iscarbon(user))
		target = user

	if(target)
		remove_silver_bane(target)

	return ..()

/obj/item/rope/chain/silver/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/target = loc
		remove_silver_bane(target)

	return ..()

/obj/item/rope/net
	item_weight = 500 GRAMS
	name = "rope net"
	desc = "A rope mesh of designed to slow a person down."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "net"
	slot_flags = ITEM_SLOT_HIP|ITEM_SLOT_WRISTS
	w_class = WEIGHT_CLASS_SMALL
	grid_width = 64
	grid_height = 64
	icon_state = "net"
	throw_speed = 0.5
	breakouttime = 3.5 SECONDS //easy to apply, easy to break out of
	gender = NEUTER
	var/knockdown = 2 SECONDS
	legcuff_multiplicative_slowdown = 2

/obj/item/rope/net/throw_at(atom/target, range, speed, mob/thrower, spin=1, diagonals_first = 0, datum/callback/callback, force, gentle = FALSE)
	. = ..()
	if(.)
		playsound(src,'sound/combat/wooshes/flail_swing.ogg', 75, TRUE)

/obj/item/rope/net/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(..() || !iscarbon(hit_atom))//if it gets caught or the target can't be cuffed,
		return//abort
	var/mob/thrower = throwingdatum?.get_thrower()
	var/trapping_skill = istype(thrower) ? GET_MOB_SKILL_VALUE_OLD(thrower, /datum/attribute/skill/craft/traps) : 0
	if(prob(100 * (trapping_skill || 1) / 3))
		ensnare(hit_atom)

/obj/item/rope/net/proc/ensnare(mob/living/carbon/C)
	if(C.num_legs >= 2 && apply_cuffs(C, leg = TRUE))
		C.visible_message(span_danger("[src] ensnares [C]!"), span_userdanger("[src] entraps you!!"))
		SSblackbox.record_feedback("tally", "handcuffs", 1, type)
		C.apply_status_effect(/datum/status_effect/debuff/netted)
		playsound(src, 'sound/combat/hits/nodmg (2).ogg', 100, TRUE)
		if((C.m_intent == MOVE_INTENT_RUN || HAS_TRAIT(C, TRAIT_STUMBLE)) && C.body_position == STANDING_UP && C.sprinted_tiles > 0)
			C.Knockdown(knockdown)

// Failsafe in case the item somehow ends up being destroyed
/obj/item/rope/net/Destroy()
	if(iscarbon(loc))
		var/mob/living/carbon/M = loc
		if(M.legcuffed == src)
			M.remove_status_effect(/datum/status_effect/debuff/netted)
	return ..()

/obj/item/rope/net/bola
	item_weight = 800 GRAMS
	name = "bola"
	desc = "A clever but simple bundle of rope and stones used to catch criminals"
	icon = 'modular_rmh/icons/obj/items/weapons/ranged/bola.dmi'
	icon_state = "bola"
	grid_width = 64
	grid_height = 64
	throw_range = 6
	throw_speed = 1.5
	ignore_throw_armor = TRUE
	breakouttime = 6 SECONDS
	knockdown = 3 SECONDS
	legcuff_multiplicative_slowdown = 2.5

	var/bola_throw_sound = 'modular_rmh/sound/items/bolathrow.ogg'

	/// Icon used while the player is winding up this bola.
	var/windup_icon_state = "spinbola"
	var/windup_item_state = "spinbola"
	var/windup_original_icon_state
	var/windup_original_item_state
	var/windup_started_at = 0
	var/last_completed_windup_duration = 0
	var/mob/living/carbon/windup_user
	var/windup_active = FALSE

	/// A bola must be wound up for at least this long before it can be thrown.
	var/minimum_windup_time = 1 SECONDS

/obj/item/rope/net/bola/proc/start_windup(mob/living/carbon/user)
	if(windup_active || !user || user.get_active_held_item() != src)
		return FALSE

	windup_user = user
	windup_started_at = world.time
	windup_original_icon_state = icon_state
	windup_original_item_state = item_state
	windup_active = TRUE

	icon_state = windup_icon_state
	item_state = windup_item_state
	update_appearance(UPDATE_ICON_STATE)
	user.update_inv_hands()
	user.add_movespeed_modifier("bola_windup_[REF(src)]", multiplicative_slowdown = 1)
	RegisterSignal(user, COMSIG_MOB_SWAPPING_HANDS, PROC_REF(on_windup_hand_swap))
	RegisterSignal(user, COMSIG_MOB_UNEQUIPPED_ITEM, PROC_REF(on_windup_unequipped))
	playsound(src, 'modular_rmh/sound/items/bolaspin.ogg', 75, TRUE)
	last_completed_windup_duration = 0
	user.visible_message(
		span_notice("[user] begins winding up [src]."),
		span_notice("I begin winding up [src]."))
	return TRUE

/obj/item/rope/net/bola/proc/finish_windup(mob/living/carbon/user)
	if(!windup_active || windup_user != user)
		return null

	var/windup_duration = world.time - windup_started_at
	var/throw_range_bonus = 0
	var/throw_speed_bonus = 0
	if(windup_duration >= 5 SECONDS)
		throw_range_bonus = 3
		throw_speed_bonus = 2
	else if(windup_duration >= 2 SECONDS)
		throw_range_bonus = 2
		throw_speed_bonus = 1

	var/list/throw_stats = list(
		"range" = throw_range + throw_range_bonus,
		"speed" = throw_speed + throw_speed_bonus,)

	last_completed_windup_duration = windup_duration

	cancel_windup(FALSE)
	return throw_stats

/obj/item/rope/net/bola/proc/cancel_windup(show_feedback = TRUE)
	if(!windup_active && !windup_user)
		return

	var/mob/living/carbon/old_user = windup_user
	if(old_user)
		UnregisterSignal(old_user, COMSIG_MOB_SWAPPING_HANDS)
		UnregisterSignal(old_user, COMSIG_MOB_UNEQUIPPED_ITEM)
		old_user.remove_movespeed_modifier("bola_windup_[REF(src)]")

	icon_state = windup_original_icon_state ? windup_original_icon_state : initial(icon_state)
	item_state = windup_original_item_state
	update_appearance(UPDATE_ICON_STATE)
	if(old_user && !QDELETED(old_user))
		old_user.update_inv_hands()
		if(show_feedback)
			old_user.visible_message(
				span_notice("[old_user] stops winding up [src]."),
				span_notice("I stop winding up [src]."))

	windup_user = null
	windup_started_at = 0
	windup_original_icon_state = null
	windup_original_item_state = null
	windup_active = FALSE

/obj/item/rope/net/bola/proc/on_windup_hand_swap(mob/living/carbon/source, obj/item/currently_held_item)
	SIGNAL_HANDLER
	if(source == windup_user)
		cancel_windup()

/obj/item/rope/net/bola/proc/on_windup_unequipped(mob/living/source, obj/item/unequipped_item, force, atom/newloc, no_move, invdrop, silent)
	SIGNAL_HANDLER
	if(source == windup_user && unequipped_item == src)
		cancel_windup()

/obj/item/rope/net/bola/dropped(mob/user)
	. = ..()
	cancel_windup()

/obj/item/rope/net/bola/Destroy()
	cancel_windup(FALSE)
	return ..()

/obj/item/rope/net/bola/proc/on_bola_impact(mob/living/C, datum/thrownthing/throwingdatum)
	// Base bola has no special damage effect.
	return

/obj/item/rope/net/bola/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
    // Run the normal thrown-item impact handling.
    // Intentionally ignore its return value: a TRUE result can mean
    // that armour or a shield blocked the ordinary thrown-item impact.
    // That must not cancel the bola's special effects.
    ..()

    if(QDELETED(src) || !hit_atom || QDELETED(hit_atom) || !isliving(hit_atom))
        return

    var/mob/living/target = hit_atom

    // Visual feedback for any living target, including simplemobs.
    if(target.client)
        shake_camera(target, 1, 1)

    // Carbon mobs use the existing restraint mechanic when the bola catches them.
    // Other living mobs receive a timed movement debuff.
    var/successfully_ensnared = FALSE
    if(iscarbon(target))
        var/mob/living/carbon/carbon_target = target
        successfully_ensnared = (carbon_target.legcuffed == src)

    if(!successfully_ensnared)
        target.apply_status_effect(/datum/status_effect/debuff/bola_slow)

    // Variant effects must execute even when the normal impact was blocked.
    on_bola_impact(target, throwingdatum)

    // If the bola attached as a legcuff, the target now owns it.
    if(successfully_ensnared)
        return

/obj/item/rope/net/bola/electro
	name = "Shock bola"
	desc = "A reinforced bola charged with stored electricity. It releases its charge once when it strikes a living target."
	icon = 'modular_rmh/icons/obj/items/weapons/ranged/bola.dmi'
	icon_state = "shockbola"
	windup_icon_state = "spinelectrobola"
	bola_throw_sound = 'modular_rmh/sound/items/bolathrowelectro.ogg'
	var/electrocuted = FALSE
	var/electrocute_damage = 20


/obj/item/rope/net/bola/electro/on_bola_impact(mob/living/C, datum/thrownthing/throwingdatum)
	if(electrocuted)
		return

	electrocuted = TRUE

	if(C.electrocute_act(electrocute_damage, src))
		if(iscarbon(C))
			C.emote("painscream")
			C.update_sneak_invis(TRUE)

		if(C.throwing)
			C.throwing.finalize(FALSE)

/obj/item/rope/net/bola/chain
	name = "chain bola"
	desc = "A heavy bola fashioned from short lengths of steel chain. The impact is brutal."
	icon = 'modular_rmh/icons/obj/items/weapons/ranged/bola.dmi'
	bola_throw_sound = 'modular_rmh/sound/items/bolathrowheavy.ogg'
	icon_state = "chainbola"
	windup_icon_state = "spinchainbola"
	throwforce = 10

/obj/item/rope/net/bola/chain/on_bola_impact(mob/living/C, datum/thrownthing/throwingdatum)
	var/damage = rand(20, 30)

	// Direct damage. Armor does not reduce this.
	C.adjustBruteLoss(damage)

	C.visible_message(span_danger("[src] slams violently into [C]!"), span_userdanger("The chain bola slams into me!"))

/obj/item/rope/net/bola/thaum
	name = "thaumaturgic bola"
	desc = "A mystically charged bola that tears arcane energy from whoever it catches."
	icon = 'modular_rmh/icons/obj/items/weapons/ranged/bola.dmi'
	bola_throw_sound = 'modular_rmh/sound/items/bolathrowheavy.ogg'
	icon_state = "thaumicbola"
	windup_icon_state = "spinthaumbola"

/obj/item/rope/net/bola/thaum/on_bola_impact(mob/living/C, datum/thrownthing/throwingdatum)
	if(C.mana_pool)
		var/datum/mana_pool/target_mana_pool = C.mana_pool
		for(var/i in 1 to 10)
			var/amount = rand(10, 15)
			addtimer(CALLBACK(target_mana_pool, TYPE_PROC_REF(/datum/mana_pool, adjust_mana), -amount), i SECONDS)

	to_chat(C, span_userdanger("Arcane energy is ripped from me by the thaumaturgic bola!"))

/obj/item/rope/net/bola/silver
	name = "silver bola"
	desc = "A bola fashioned with silver weights, deadly to creatures cursed by the night."
	icon = 'modular_rmh/icons/obj/items/weapons/ranged/bola.dmi'
	bola_throw_sound = 'modular_rmh/sound/items/bolathrowheavy.ogg'
	icon_state = "silverbola"
	windup_icon_state = "spinsilverbola"

/obj/item/rope/net/bola/silver/on_bola_impact(mob/living/C, datum/thrownthing/throwingdatum)
	if(!ishuman(C) || !C.mind)
		return

	var/mob/living/carbon/human/human_target = C
	var/datum/material_trait/silver_bane/bane = new
	bane.touch_bane(human_target)
	qdel(bane)

/// Briefly slows living non-carbon targets hit by a bola, which cannot be legcuffed.
/datum/status_effect/debuff/bola_slow
	id = "bola_slow"
	status_type = STATUS_EFFECT_REFRESH
	duration = 1 MINUTES
	tick_interval = -1
	effectedstats = list(STAT_SPEED = -2)

/obj/item/rope/net/bola/mantrap
	name = "throwing mantrap"
	desc = "A compact spring-loaded mantrap attached to a weighted throwing frame. A fully wound throw can snap shut around an opponent's leg."
	icon = 'modular_rmh/icons/obj/items/weapons/ranged/bola.dmi'
	icon_state = "mantrapbola"

	windup_icon_state = "spinmantrapbola"
	windup_item_state = "spinmantrapbola"
	bola_throw_sound = 'modular_rmh/sound/items/bolathrowheavy.ogg'

	throw_range = 6
	throw_speed = 1.5
	throwforce = 0

	var/leg_damage = 120
	var/catch_damage = 90
	var/activation_stun = 80
	var/activation_knockdown = 80


/obj/item/rope/net/bola/mantrap/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(QDELETED(src) || !hit_atom || QDELETED(hit_atom))
		return

	var/turf/landing_turf = get_turf(hit_atom)
	if(!landing_turf)
		qdel(src)
		return

	// PRIORITY 1:
	// Attempting to catch the projectile triggers the hand punishment.
	if(iscarbon(hit_atom))
		var/mob/living/carbon/victim = hit_atom

		if(victim.in_throw_mode)
			if(activate_on_hand(victim, landing_turf))
				victim.throw_mode_off()
				qdel(src)
				return

	// PRIORITY 2:
	// A completed wind-up of at least five seconds activates on the leg.
	if(iscarbon(hit_atom) && last_completed_windup_duration >= 5 SECONDS)
		var/mob/living/carbon/victim = hit_atom

		if(activate_on_leg(victim, landing_turf))
			qdel(src)
			return

	// PRIORITY 3:
	// All other impacts deploy an armed trap.
	// Do not deploy directly beneath a living target.
	if(isliving(hit_atom))
		var/impact_dir = throwingdatum?.init_dir

		if(!impact_dir)
			impact_dir = dir

		if(!impact_dir)
			qdel(src)
			return

		landing_turf = get_step(landing_turf, impact_dir)

	if(landing_turf)
		deploy_beartrap(landing_turf)

	qdel(src)


/// Punishment for attempting to catch the mantrap.
/obj/item/rope/net/bola/mantrap/proc/activate_on_hand(mob/living/carbon/victim, turf/landing_turf)
	if(!victim || !landing_turf)
		return FALSE

	var/def_zone = (victim.active_hand_index == 2) ? BODY_ZONE_R_ARM : BODY_ZONE_L_ARM
	var/obj/item/bodypart/BP = victim.get_bodypart(def_zone)

	if(!BP)
		return FALSE

	var/obj/item/restraints/legcuffs/beartrap/armed/trap = new(landing_turf)

	trap.add_mob_blood(victim)

	if(!BP.add_embedded_object(trap))
		qdel(trap)
		return FALSE

	trap.close_trap()

	victim.visible_message(
		span_boldwarning("[victim] tries to catch [src], but the mantrap snaps shut around [victim.p_their()] hand!"),
		span_userdanger("I try to catch [src], but the mantrap snaps shut around my hand!")
	)

	victim.emote("agony")
	victim.Stun(activation_stun)
	victim.Knockdown(activation_knockdown)

	BP.add_wound(/datum/wound/fracture)
	BP.update_disabled()

	victim.apply_damage(catch_damage, BRUTE, def_zone)

	victim.update_sneak_invis(TRUE)

	return TRUE


/// Artificially activates the mantrap on one of the victim's legs.
/obj/item/rope/net/bola/mantrap/proc/activate_on_leg(mob/living/carbon/victim, turf/landing_turf)
	if(!victim || !landing_turf)
		return FALSE

	// Choose an available foot/leg, preferring precise foot zones.
	var/list/available_leg_zones = list()

	if(victim.get_bodypart(BODY_ZONE_PRECISE_L_FOOT))
		available_leg_zones += BODY_ZONE_PRECISE_L_FOOT
	else if(victim.get_bodypart(BODY_ZONE_L_LEG))
		available_leg_zones += BODY_ZONE_L_LEG

	if(victim.get_bodypart(BODY_ZONE_PRECISE_R_FOOT))
		available_leg_zones += BODY_ZONE_PRECISE_R_FOOT
	else if(victim.get_bodypart(BODY_ZONE_R_LEG))
		available_leg_zones += BODY_ZONE_R_LEG

	if(!length(available_leg_zones))
		return FALSE

	var/def_zone = pick(available_leg_zones)
	var/obj/item/bodypart/BP = victim.get_bodypart(def_zone)

	if(!BP)
		return FALSE

	// Create the trap at the victim's location and embed it in the selected leg.
	var/obj/item/restraints/legcuffs/beartrap/armed/trap = new(landing_turf)

	trap.add_mob_blood(victim)

	if(!BP.add_embedded_object(trap))
		qdel(trap)
		return FALSE

	trap.close_trap()

	victim.visible_message(
		span_boldwarning("[src] snaps shut violently around [victim]'s [BP.name]!"),
		span_userdanger("The mantrap snaps shut violently around my [BP.name]!")
	)

	victim.emote("agony")
	victim.Stun(activation_stun)

	// Guaranteed fracture and direct brute damage.
	BP.add_wound(/datum/wound/fracture)
	victim.apply_damage(leg_damage, BRUTE, def_zone)

	BP.update_disabled()
	victim.update_sneak_invis(TRUE)

	return TRUE


/// Deploys an ordinary armed beartrap on the landing turf.
/obj/item/rope/net/bola/mantrap/proc/deploy_beartrap(turf/landing_turf)
	if(!landing_turf)
		return FALSE

	new /obj/item/restraints/legcuffs/beartrap/armed(landing_turf)

	visible_message(
		span_notice("[src] lands and unfolds into a mantrap!")
	)

	return TRUE

/obj/item/rope/net/bola/mantrap/anti_magic_field
	name = "throwable anti-magic field"
	icon = 'modular_rmh/icons/obj/structures/antimagicfield.dmi'
	icon_state = "antimagicthrowable"
	desc = "A compact deployable anti-magic field generator attached to a weighted throwing frame."
	throw_range = 4
	throw_speed = 1.5
	throwforce = 3

/obj/item/rope/net/bola/mantrap/anti_magic_field/throw_impact(atom/hit_atom, datum/thrownthing/throwingdatum)
	if(QDELETED(src) || !hit_atom || QDELETED(hit_atom))
		return

	var/turf/impact_turf = get_turf(hit_atom)
	if(!impact_turf)
		visible_message(span_warning("[src] fails to find a valid landing location and remains intact."))
		return

	var/turf/landing_turf
	if(isclosedturf(hit_atom) || ismovable(hit_atom))
		landing_turf = find_anti_magic_field_landing_turf(impact_turf, hit_atom)
	else if(is_valid_anti_magic_field_landing_turf(impact_turf))
		landing_turf = impact_turf
	else
		landing_turf = find_anti_magic_field_landing_turf(impact_turf, hit_atom)

	if(!landing_turf)
		visible_message(span_warning("[src] strikes an invalid surface; no clear tile is nearby, so it is not deployed."))
		var/mob/thrower = throwingdatum?.get_thrower()
		var/turf/return_turf = get_turf(thrower)
		if(!return_turf)
			return_turf = impact_turf
		forceMove(return_turf)
		return

	if(deploy_anti_magic_field(landing_turf))
		qdel(src)
		return

	visible_message(span_warning("[src] fails to deploy and remains intact."))
	var/mob/thrower = throwingdatum?.get_thrower()
	var/turf/return_turf = get_turf(thrower)
	if(!return_turf)
		return_turf = impact_turf
	forceMove(return_turf)

/// Deploys the anti-magic generator using the same explicit pattern as the mantrap deploy_beartrap().
/obj/item/rope/net/bola/mantrap/anti_magic_field/proc/deploy_anti_magic_field(turf/landing_turf)
	if(!landing_turf)
		return FALSE

	new /obj/structure/anti_magic_field/throwable(landing_turf)
	visible_message(span_notice("[src] lands and unfolds into an anti-magic field generator!"))
	return TRUE

/obj/structure/noose
	name = "noose"
	desc = "Abandon all hope."
	icon = 'icons/roguetown/misc/tallstructure.dmi'
	SET_BASE_PIXEL(0, 10)
	icon_state = "noose"
	can_buckle = 1
	layer = 4.26
	max_integrity = 10
	buckle_lying = FALSE
	buckle_prevents_pull = TRUE
	max_buckled_mobs = 1
	anchored = TRUE
	density = FALSE
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER
	static_debris = list(/obj/item/rope = 1)
	breakoutextra = 10 MINUTES
	buckleverb = "tie"

/obj/structure/noose/gallows
	name = "gallows"
	desc = "Read through six lines written by the most honest man in the world, and one will find enough in them to hang him."
	icon_state = "gallows"
	SET_BASE_PIXEL(0, 0)
	max_integrity = 100

/obj/structure/noose/Destroy()
	STOP_PROCESSING(SSobj, src)
	if(has_buckled_mobs())
		for(var/mob/living/buckled_mob as anything in buckled_mobs)
			buckled_mob.visible_message("<span class='danger'>[buckled_mob] falls over and hits the ground!</span>")
			to_chat(buckled_mob, "<span class='userdanger'>You fall over and hit the ground!</span>")
			buckled_mob.adjustBruteLoss(10, damage_type = BCLASS_BLUNT)
			buckled_mob.Knockdown(60)
	return ..()

/obj/structure/noose/attackby(obj/item/W, mob/user, list/modifiers)
	if(!W.get_sharpness())
		return ..()

	if(do_after(user, 1 SECONDS, src))
		new /obj/item/rope(loc)
		playsound(src, 'sound/foley/dropsound/cloth_drop.ogg', 50, TRUE)
		if (istype(src, /obj/structure/noose/gallows))
			new /obj/machinery/light/fueled/lanternpost/unfixed(loc)
			user.visible_message(span_notice("[user] cuts the noose down from the gallows."), span_notice("I cut the noose down from the gallows."), span_hear("I hear something snap."))
		else
			user.visible_message(span_notice("[user] cuts down the noose."), span_notice("I cut down the noose."), span_hear("I hear something snap."))
		qdel(src)

/obj/structure/noose/bullet_act(obj/projectile/P, def_zone, piercing_hit = FALSE)
	. = ..()
	new /obj/item/rope(loc)
	playsound(src, 'sound/foley/dropsound/cloth_drop.ogg', 50, TRUE)
	if(istype(src, /obj/structure/noose/gallows))
		new /obj/machinery/light/fueled/lanternpost/unfixed(loc)
		visible_message(span_danger("The noose is shot down from the gallows!"))
	else
		visible_message(span_danger("The noose is shot down!"))
	qdel(src)

/obj/structure/noose/user_buckle_mob(mob/living/M, mob/user, check_loc)
	if(!in_range(user, src) || user.stat != CONSCIOUS || HAS_TRAIT(user, TRAIT_RESTRAINED) || !iscarbon(M))
		return FALSE

	if (!M.get_bodypart("head"))
		to_chat(user, "<span class='warning'>[M] has no head!</span>")
		return FALSE

	M.visible_message("<span class='danger'>[user] attempts to tie \the [src] over [M]'s neck!</span>")
	if(do_after(user, (user == M ? 0 : 5 SECONDS), M))
		if(buckle_mob(M))
			user.visible_message("<span class='warning'>[user] ties \the [src] over [M]'s neck!</span>")
			if(user == M)
				to_chat(M, "<span class='userdanger'>I tie \the [src] over my neck...</span>")
			else
				to_chat(M, "<span class='userdanger'>[user] ties \the [src] over my neck!</span>")
			playsound(user, 'sound/foley/noosed.ogg', 50, 1, -1)
			return TRUE
	user.visible_message("<span class='warning'>[user] fails to tie \the [src] over [M]'s neck!</span>")
	to_chat(user, "<span class='warning'>I fail to tie \the [src] over [M]'s neck.</span>")
	return FALSE

/obj/structure/noose/post_buckle_mob(mob/living/M)
	if(has_buckled_mobs())
		START_PROCESSING(SSobj, src)
		M.set_mob_offsets("bed_buckle", _x = 0, _y = 10)

/obj/structure/noose/gallows/post_buckle_mob(mob/living/M)
	if(has_buckled_mobs())
		START_PROCESSING(SSobj, src)
		M.set_mob_offsets("bed_buckle", _x = 6, _y = 16)

/obj/structure/noose/post_unbuckle_mob(mob/living/M)
	STOP_PROCESSING(SSobj, src)
	M.reset_offsets("bed_buckle")

/obj/structure/noose/process()
	if(!has_buckled_mobs())
		STOP_PROCESSING(SSobj, src)
		return
	for(var/mob/living/buckled_mob as anything in buckled_mobs)
		if(buckled_mob.get_bodypart("head"))
			if(buckled_mob.stat != DEAD)
				if(locate(/obj/structure/chair) in get_turf(src)) // So you can kick down the chair and make them hang, and stuff.
					return
				if(!HAS_TRAIT(buckled_mob, TRAIT_NOBREATH))
					buckled_mob.adjustOxyLoss(10)
					if(prob(20))
						buckled_mob.emote("gasp")
				if(prob(25))
					var/flavor_text = list("<span class='danger'>[buckled_mob]'s legs flail for anything to stand on.</span>",\
											"<span class='danger'>[buckled_mob]'s hands are desperately clutching the noose.</span>",\
											"<span class='danger'>[buckled_mob]'s limbs sway back and forth with diminishing strength.</span>")
					buckled_mob.visible_message(pick(flavor_text))
				playsound(buckled_mob, 'sound/foley/noose_idle.ogg', 30, 1, -3)
			else
				if(prob(1))
					var/obj/item/bodypart/head/head = buckled_mob.get_bodypart("head")
					if(head.brute_dam >= 50)
						if(head.dismemberable)
							head.dismember()
		else
			buckled_mob.visible_message("<span class='danger'>[buckled_mob] drops from the noose!</span>")
			buckled_mob.Knockdown(60)
			buckled_mob.pixel_y = buckled_mob.base_pixel_y
			buckled_mob.pixel_x = buckled_mob.base_pixel_x
			unbuckle_all_mobs(force=1)
