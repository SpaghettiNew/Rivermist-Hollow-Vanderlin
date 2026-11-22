#define BATH_IMMERSION_MASK "bath_immersion_mask"

/obj/structure/bath
	name = "bath"
	icon = 'modular_rmh/icons/obj/structures/baths.dmi'
	icon_state = "bath_wooden"
	density = TRUE
	anchored = FALSE
	move_resist = MOVE_FORCE_NORMAL
	drag_slowdown = 6
	can_buckle = TRUE
	buckle_lying = 0
	var/max_reagent_volume = 900
	var/water_overlay_min_volume = 600
	var/north_south_occupant_y_offset = 2
	var/west_occupant_x_offset = 6
	var/east_occupant_x_offset = -6
	var/north_empty_mask_y_offset = -2
	var/south_empty_mask_y_offset = -9
	var/east_west_empty_mask_y_offset = -6
	var/north_filled_mask_y_offset = -2
	var/south_filled_mask_y_offset = -2
	var/east_west_filled_mask_y_offset = -2
	var/reagent_touch_amount = 5
	var/reagent_touch_interval = 30 SECONDS
	var/reagent_touch_timer
	var/sneak_buckle_delay = 5 SECONDS

/obj/structure/bath/Initialize()
	. = ..()
	create_reagents(max_reagent_volume, NO_REACT | AMOUNT_VISIBLE | REFILLABLE | DRAINABLE)

// Изменение положения игрока, ванной и оверлея воды после изменения направления ванной
/obj/structure/bath/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	update_directional_appearance()

/obj/structure/bath/proc/update_directional_appearance()
	for(var/mob/living/occupant as anything in buckled_mobs)
		update_occupant_offset(occupant)
		update_immersion_mask(occupant)
	if(reagents?.total_volume >= water_overlay_min_volume)
		update_appearance(UPDATE_OVERLAYS)

/obj/structure/bath/proc/update_occupant_offset(mob/living/occupant)
	var/x_offset = 0
	var/y_offset = 0
	switch(dir)
		if(NORTH, SOUTH)
			y_offset = north_south_occupant_y_offset
		if(WEST)
			x_offset = west_occupant_x_offset
		if(EAST)
			x_offset = east_occupant_x_offset
	occupant.set_mob_offsets("bath", _x = x_offset, _y = y_offset)

/obj/structure/bath/setDir(newdir)
	. = ..()
	update_directional_appearance()


// Умывание и бакливание
/obj/structure/bath/attack_hand(mob/living/user, list/modifiers)
	if(user.buckled == src)
		add_fingerprint(user)
	else
		if(has_buckled_mobs())
			return ..()
		if(..())
			return TRUE

	if(!user.cmode)
		wash_occupant(user)
	return TRUE

/obj/structure/bath/proc/wash_occupant(mob/living/user)
	var/water_type = /datum/reagent/water
	if(!reagents?.has_reagent(water_type, 5))
		water_type = /datum/reagent/water/gross
		if(!reagents?.has_reagent(water_type, 5))
			to_chat(user, span_warning("No water to wash these stains."))
			return

	var/list/wash_sounds = list('sound/foley/waterwash (1).ogg', 'sound/foley/waterwash (2).ogg')
	user.visible_message(span_info("[user] starts to wash in [src]."))
	playsound(user, pick_n_take(wash_sounds), 100, FALSE)
	if(!do_after(user, 3 SECONDS, src) || QDELETED(src) || QDELETED(user))
		return
	if((user.buckled != src && has_buckled_mobs()) || !reagents?.has_reagent(water_type, 5))
		return

	reagents.remove_reagent(water_type, 5)
	user.wash(CLEAN_WASH)
	playsound(user, pick(wash_sounds), 100, FALSE)
	if(ishuman(user))
		var/mob/living/carbon/human/bather = user
		if(bather.wear_armor || bather.wear_shirt || bather.wear_pants)
			to_chat(bather, span_notice("I can't wash properly with my clothes on."))
		else
			bather.add_stress(/datum/stress_event/bathwater)

	var/clean_water_volume = reagents.get_reagent_amount(/datum/reagent/water)
	if(clean_water_volume >= 5)
		reagents.remove_reagent(/datum/reagent/water, clean_water_volume)
		reagents.add_reagent(/datum/reagent/water/gross, clean_water_volume)

/obj/structure/bath/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(M != user || M?.m_intent != MOVE_INTENT_SNEAK || !reagents?.total_volume)
		return ..()
	if(!is_user_buckle_possible(M, user, check_loc) || !do_after(user, sneak_buckle_delay, src, hidden = TRUE))
		return FALSE
	if(QDELETED(src) || QDELETED(M) || M.m_intent != MOVE_INTENT_SNEAK)
		return FALSE

	return ..()

/obj/structure/bath/user_unbuckle_mob(mob/living/buckled_mob, mob/user)
	if(buckled_mob != user || buckled_mob?.m_intent != MOVE_INTENT_SNEAK || !reagents?.total_volume)
		return ..()
	if(buckled_mob.buckled != src || !do_after(user, sneak_buckle_delay, src, hidden = TRUE))
		return
	if(QDELETED(src) || QDELETED(buckled_mob) || buckled_mob.m_intent != MOVE_INTENT_SNEAK)
		return

	return ..()

/obj/structure/bath/post_buckle_mob(mob/living/buckled_mob)
	. = ..()
	update_occupant_offset(buckled_mob)
	update_immersion_mask(buckled_mob)
	if(buckled_mob.m_intent != MOVE_INTENT_SNEAK && reagents?.total_volume >= water_overlay_min_volume)
		playsound(src, 'sound/foley/waterenter.ogg', 40, FALSE)
	if(!reagent_touch_timer)
		reagent_touch_timer = addtimer(CALLBACK(src, PROC_REF(apply_reagent_touch_to_occupants)), reagent_touch_interval, TIMER_STOPPABLE | TIMER_LOOP)

/obj/structure/bath/post_unbuckle_mob(mob/living/unbuckled_mob)
	. = ..()
	unbuckled_mob.reset_offsets("bath")
	unbuckled_mob.remove_filter(BATH_IMMERSION_MASK)
	if(!QDELETED(src) && unbuckled_mob.m_intent != MOVE_INTENT_SNEAK && reagents?.total_volume >= water_overlay_min_volume)
		playsound(src, pick('sound/foley/watermove (1).ogg', 'sound/foley/watermove (2).ogg'), 40, FALSE)
	if(!has_buckled_mobs())
		stop_reagent_touch_timer()


// Применение реагентов
/obj/structure/bath/proc/stop_reagent_touch_timer()
	if(reagent_touch_timer)
		deltimer(reagent_touch_timer)
		reagent_touch_timer = null

/obj/structure/bath/proc/apply_reagent_touch_to_occupants()
	var/found_occupant = FALSE
	for(var/mob/living/occupant as anything in buckled_mobs?.Copy())
		if(apply_reagent_touch(occupant))
			found_occupant = TRUE
	if(!found_occupant)
		stop_reagent_touch_timer()

/obj/structure/bath/proc/apply_reagent_touch(mob/living/occupant)
	if(QDELETED(occupant) || occupant.buckled != src || occupant.loc != loc)
		return FALSE
	var/datum/reagents/bath_reagents = reagents
	for(var/datum/reagent/reagent as anything in bath_reagents?.reagent_list?.Copy())
		if(QDELETED(bath_reagents) || QDELETED(occupant) || occupant.buckled != src || occupant.loc != loc)
			break
		if(QDELETED(reagent) || reagent.volume <= 0)
			continue

		var/contact_amount = min(reagent.volume, reagent_touch_amount)
		var/reagent_type = reagent.type
		bath_reagents.react_single(reagent, occupant, TOUCH, contact_amount / reagent.volume)
		if(!ispath(reagent_type, /datum/reagent/water) && !QDELETED(bath_reagents))
			bath_reagents.remove_reagent(reagent_type, contact_amount, safety = TRUE)
	return TRUE


// Оверлеи воды
/obj/structure/bath/on_reagent_change(changetype)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
	for(var/mob/living/occupant as anything in buckled_mobs)
		update_immersion_mask(occupant)

/obj/structure/bath/proc/update_immersion_mask(mob/living/occupant)
	var/static/icon/upright_mask = icon('icons/effects/icon_cutter.dmi', "icon_cutter")
	var/is_filled = reagents?.total_volume >= water_overlay_min_volume
	var/mask_y_offset
	if(dir == EAST || dir == WEST)
		mask_y_offset = is_filled ? east_west_filled_mask_y_offset : east_west_empty_mask_y_offset
	else if(dir == NORTH)
		mask_y_offset = is_filled ? north_filled_mask_y_offset : north_empty_mask_y_offset
	else
		mask_y_offset = is_filled ? south_filled_mask_y_offset : south_empty_mask_y_offset
	occupant.add_filter(BATH_IMMERSION_MASK, 1, alpha_mask_filter(0, mask_y_offset, upright_mask, null, MASK_INVERSE))

/obj/structure/bath/update_overlays()
	. = ..()
	if(reagents?.total_volume >= water_overlay_min_volume)
		var/mutable_appearance/slime_overlay = mutable_appearance(icon, "[icon_state]_slime")
		slime_overlay.dir = dir
		. += slime_overlay


#undef BATH_IMMERSION_MASK


// Подтипы
/obj/structure/bath/wooden
	name = "wooden bath"

/obj/structure/bath/steel
	name = "steel bath"
	icon_state = "bath_steel"

/obj/structure/bath/marble
	name = "marble bath"
	icon_state = "bath_marble"

/obj/structure/bath/barrel
	name = "barrel bath"
	icon_state = "bath_barrel"
	north_empty_mask_y_offset = -2
	south_empty_mask_y_offset = -2
	east_west_empty_mask_y_offset = -2


// Крафты
/datum/blueprint_recipe/carpentry/barrel/bath
	name = "barrel bath"
	desc = "A wooden barrel made for bathing."
	result_type = /obj/structure/bath/barrel
	supports_directions = TRUE

/datum/blueprint_recipe/carpentry/wooden_bath
	name = "wooden bath"
	desc = "A wooden tub for bathing."
	result_type = /obj/structure/bath/wooden
	required_materials = list(/obj/item/grown/log/tree/small = 2)
	supports_directions = TRUE
	craftdiff = SKILL_RANK_NOVICE

/datum/blueprint_recipe/carpentry/wooden_bath/check_craft_requirements(mob/user, turf/T, obj/structure/blueprint/blueprint)
	if(GET_MOB_SKILL_VALUE(user, skillcraft) < SKILL_LEVEL_NOVICE)
		to_chat(user, span_warning("I need basic carpentry skill to build this."))
		return FALSE
	return ..()

/datum/blueprint_recipe/engineering/steel_bath
	name = "steel bath"
	desc = "A steel tub for bathing."
	result_type = /obj/structure/bath/steel
	required_materials = list(/obj/item/ingot/steel = 3)
	supports_directions = TRUE
	craftdiff = SKILL_RANK_APPRENTICE

/datum/blueprint_recipe/engineering/steel_bath/check_craft_requirements(mob/user, turf/T, obj/structure/blueprint/blueprint)
	if(GET_MOB_SKILL_VALUE(user, skillcraft) < SKILL_LEVEL_JOURNEYMAN)
		to_chat(user, span_warning("I need novice engineering skill to build this."))
		return FALSE
	return ..()

/datum/blueprint_recipe/masonry/marble_bath
	name = "marble bath"
	desc = "A bathing tub carved from stone."
	result_type = /obj/structure/bath/marble
	required_materials = list(/obj/item/natural/stone = 4)
	supports_directions = TRUE
	craftdiff = SKILL_RANK_MASTER

/datum/blueprint_recipe/masonry/marble_bath/check_craft_requirements(mob/user, turf/T, obj/structure/blueprint/blueprint)
	if(GET_MOB_SKILL_VALUE(user, skillcraft) < SKILL_LEVEL_MASTER)
		to_chat(user, span_warning("I need master masonry skill to build this."))
		return FALSE
	return ..()
