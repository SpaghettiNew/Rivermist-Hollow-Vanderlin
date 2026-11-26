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
	var/water_overlay_min_volume = 600 // Минимальный объем который нужен для мытья в ванной. Обычно 2/3 от её объема
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
	var/mob/living/bath_trap_occupant
	var/turf/bath_trap_entry
	var/obj/item/reagent_containers/food/snacks/slime_core_egg/bath_trap_core
	var/mob/living/simple_animal/hostile/retaliate/slime_tendrils/bath_trap_proxy
	var/datum/sex_scene_controller/bath_trap_scene
	var/bath_trap_timer




// Жизненный цикл

/obj/structure/bath/Initialize()
	. = ..()
	create_reagents(max_reagent_volume, AMOUNT_VISIBLE | REFILLABLE | DRAINABLE)

/obj/structure/bath/Destroy()
	clear_bath_trap()
	stop_reagent_touch_timer()
	release_bath_trap_items(get_turf(src))
	return ..()




// Взаимодействие и мытьё

/obj/structure/bath/attack_hand(mob/living/user, list/modifiers)
	if(bath_trap_occupant)
		try_release_bath_trap(user)
		return TRUE
	if(release_bath_trap_items(get_turf(user), keep_cores = TRUE))
		return TRUE
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

/obj/structure/bath/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(istype(tool, /obj/item/reagent_containers/food/snacks/slime_core_egg))
		if(locate(/obj/item/reagent_containers/food/snacks/slime_core_egg) in contents)
			return ITEM_INTERACT_BLOCKING
		if(user.transferItemToLoc(tool, src))
			return ITEM_INTERACT_SUCCESS
		return ITEM_INTERACT_BLOCKING

	if(user.cmode || !istype(tool, /obj/item/clothing) || is_type_in_list(user.used_intent, list(INTENT_SOAK, INTENT_WRING)))
		return ..()

	var/obj/item/clothing/clothing = tool
	if(!get_wash_water_type())
		to_chat(user, span_warning("No water to wash these stains."))
		return ITEM_INTERACT_BLOCKING

	var/list/wash_sounds = list('sound/foley/waterwash (1).ogg', 'sound/foley/waterwash (2).ogg')
	user.visible_message(span_info("[user] starts to wash [clothing] in [src]."))
	playsound(user, pick_n_take(wash_sounds), 100, FALSE)
	if(!do_after(user, 3 SECONDS, src) || QDELETED(src) || QDELETED(clothing) || clothing.loc != user)
		return ITEM_INTERACT_BLOCKING

	var/water_type = get_wash_water_type()
	if(!water_type)
		to_chat(user, span_warning("No water to wash these stains."))
		return ITEM_INTERACT_BLOCKING

	var/dirty_water = !!reagents.has_reagent(/datum/reagent/water/gross)
	reagents.remove_reagent(water_type, 5)
	if(clothing.wetable)
		clothing.wet.add_water(20, dirty = dirty_water, washed_properly = TRUE)
	clothing.wash(CLEAN_WASH)
	user.nobles_seen_servant_work()
	playsound(user, pick(wash_sounds), 100, FALSE)
	return ITEM_INTERACT_SUCCESS

/obj/structure/bath/proc/get_wash_water_type()
	if(reagents?.has_reagent(/datum/reagent/water, 5))
		return /datum/reagent/water
	if(reagents?.has_reagent(/datum/reagent/water/gross, 5))
		return /datum/reagent/water/gross
	return null

/obj/structure/bath/proc/get_bath_water_volume()
	if(!reagents)
		return 0
	return reagents.get_reagent_amount(/datum/reagent/water) + reagents.get_reagent_amount(/datum/reagent/water/gross)

/obj/structure/bath/proc/wash_occupant(mob/living/user)
	if(get_bath_water_volume() < water_overlay_min_volume)
		to_chat(user, span_warning("Bath is almost empty, you need to fill it up first for at least [water_overlay_min_volume]"))
		return

	if(!get_wash_water_type())
		to_chat(user, span_warning("No water to wash these stains."))
		return

	var/list/wash_sounds = list('sound/foley/waterwash (1).ogg', 'sound/foley/waterwash (2).ogg')
	user.visible_message(span_info("[user] starts to wash in [src]."))
	playsound(user, pick_n_take(wash_sounds), 100, FALSE)
	if(!do_after(user, 3 SECONDS, src) || QDELETED(src) || QDELETED(user))
		return
	if((user.buckled != src && has_buckled_mobs()))
		return

	user.wash(CLEAN_WASH)
	playsound(user, pick(wash_sounds), 100, FALSE)
	if(ishuman(user))
		var/mob/living/carbon/human/bather = user
		if(bather.wear_armor || bather.wear_shirt || bather.wear_pants)
			to_chat(bather, span_notice("I can't wash properly with my clothes on."))




// Посадка и выход

/obj/structure/bath/user_buckle_mob(mob/living/M, mob/user, check_loc = TRUE)
	if(bath_trap_occupant)
		return FALSE
	if(M == user && M?.m_intent == MOVE_INTENT_SNEAK && reagents?.total_volume)
		if(!is_user_buckle_possible(M, user, check_loc) || !do_after(user, sneak_buckle_delay, src, hidden = TRUE))
			return FALSE
		if(QDELETED(src) || QDELETED(M) || M.m_intent != MOVE_INTENT_SNEAK)
			return FALSE

	var/turf/entry = get_turf(M)
	. = ..()
	if(. && M == user)
		var/obj/item/reagent_containers/food/snacks/slime_core_egg/core = get_single_bath_trap_core()
		core?.on_bath_trap_capture(src, M, entry)

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
	if(ishuman(buckled_mob) && reagents?.total_volume < water_overlay_min_volume)
		to_chat(buckled_mob, span_warning("Bath is half empty, it would be good to fill it with water at least for [water_overlay_min_volume]"))
	if(buckled_mob.m_intent != MOVE_INTENT_SNEAK && reagents?.total_volume >= water_overlay_min_volume)
		playsound(src, 'sound/foley/waterenter.ogg', 40, FALSE)
	if(!reagent_touch_timer)
		reagent_touch_timer = addtimer(CALLBACK(src, PROC_REF(apply_reagent_touch_to_occupants)), reagent_touch_interval, TIMER_STOPPABLE | TIMER_LOOP)

/obj/structure/bath/post_unbuckle_mob(mob/living/unbuckled_mob)
	. = ..()
	unbuckled_mob.reset_offsets("bath")
	unbuckled_mob.remove_filter(BATH_IMMERSION_MASK)
	if(unbuckled_mob == bath_trap_occupant)
		return
	if(!QDELETED(src) && unbuckled_mob.m_intent != MOVE_INTENT_SNEAK && reagents?.total_volume >= water_overlay_min_volume)
		playsound(src, pick('sound/foley/watermove (1).ogg', 'sound/foley/watermove (2).ogg'), 40, FALSE)
	if(!has_buckled_mobs() && !bath_trap_occupant)
		stop_reagent_touch_timer()




// Применение реагентов

/obj/structure/bath/proc/stop_reagent_touch_timer()
	if(reagent_touch_timer)
		deltimer(reagent_touch_timer)
		reagent_touch_timer = null

/obj/structure/bath/proc/apply_reagent_touch_to_occupants()
	var/found_occupant = bath_trap_occupant && apply_reagent_touch(bath_trap_occupant)
	for(var/mob/living/occupant as anything in buckled_mobs?.Copy())
		if(apply_reagent_touch(occupant))
			found_occupant = TRUE
	if(!found_occupant)
		stop_reagent_touch_timer()

/obj/structure/bath/proc/is_bath_reagent_occupant(mob/living/occupant)
	if(QDELETED(occupant))
		return FALSE
	if(occupant == bath_trap_occupant)
		return occupant.loc == src
	return occupant.buckled == src && occupant.loc == loc

/obj/structure/bath/proc/apply_reagent_touch(mob/living/occupant)
	if(!is_bath_reagent_occupant(occupant))
		return FALSE
	var/datum/reagents/bath_reagents = reagents
	for(var/datum/reagent/reagent as anything in bath_reagents?.reagent_list?.Copy())
		if(QDELETED(bath_reagents) || !is_bath_reagent_occupant(occupant))
			break
		if(QDELETED(reagent) || reagent.volume <= 0)
			continue

		var/contact_amount = min(reagent.volume, reagent_touch_amount)
		var/reagent_type = reagent.type
		bath_reagents.react_single(reagent, occupant, TOUCH, contact_amount / reagent.volume)
		if(QDELETED(bath_reagents))
			break
		if(!ispath(reagent_type, /datum/reagent/water))
			bath_reagents.remove_reagent(reagent_type, contact_amount, safety = TRUE)
	return TRUE




// Внешний вид, направление и маска погружения

/obj/structure/bath/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	if(bath_trap_entry && get_turf(OldLoc) != get_turf(src))
		bath_trap_entry = null
	update_directional_appearance()

/obj/structure/bath/proc/update_directional_appearance()
	for(var/mob/living/occupant as anything in buckled_mobs)
		update_occupant_offset(occupant)
		update_immersion_mask(occupant)
	if(bath_trap_occupant || reagents?.total_volume > 0)
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

/obj/structure/bath/on_reagent_change(changetype)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
	for(var/mob/living/occupant as anything in buckled_mobs)
		update_immersion_mask(occupant)

/obj/structure/bath/proc/update_immersion_mask(mob/living/occupant)
	var/static/icon/upright_mask = icon('icons/effects/icon_cutter.dmi', "icon_cutter")
	var/liquid_volume = reagents?.total_volume
	var/fill_fraction = 1
	if(liquid_volume < water_overlay_min_volume)
		fill_fraction = (liquid_volume ? liquid_volume : 0) / water_overlay_min_volume
	var/empty_offset
	var/filled_offset
	if(dir == EAST || dir == WEST)
		empty_offset = east_west_empty_mask_y_offset
		filled_offset = east_west_filled_mask_y_offset
	else if(dir == NORTH)
		empty_offset = north_empty_mask_y_offset
		filled_offset = north_filled_mask_y_offset
	else
		empty_offset = south_empty_mask_y_offset
		filled_offset = south_filled_mask_y_offset
	var/mask_y_offset = empty_offset + (filled_offset - empty_offset) * fill_fraction
	occupant.add_filter(BATH_IMMERSION_MASK, 1, alpha_mask_filter(0, mask_y_offset, upright_mask, null, MASK_INVERSE))

/obj/structure/bath/update_overlays()
	. = ..()
	var/liquid_volume = reagents?.total_volume
	if(bath_trap_occupant)
		var/mutable_appearance/tentacle_overlay = mutable_appearance(icon, "[icon_state]_tentacle")
		tentacle_overlay.dir = dir
		tentacle_overlay.color = get_liquid_overlay_color()
		. += tentacle_overlay
	else if(liquid_volume > 0)
		var/mutable_appearance/slime_overlay = mutable_appearance(icon, "[icon_state]_slime")
		slime_overlay.dir = dir
		slime_overlay.color = get_liquid_overlay_color()
		if(liquid_volume < water_overlay_min_volume)
			slime_overlay.alpha = clamp(round(255 * liquid_volume / water_overlay_min_volume), 1, 254)
		. += slime_overlay

/obj/structure/bath/proc/get_liquid_overlay_color()
	var/red = 0
	var/green = 0
	var/blue = 0
	var/total_volume = 0
	for(var/datum/reagent/reagent as anything in reagents.reagent_list)
		var/list/channels = ReadRGB(reagent.color)
		if(!channels || reagent.volume <= 0)
			continue
		red += channels[1] * reagent.volume
		green += channels[2] * reagent.volume
		blue += channels[3] * reagent.volume
		total_volume += reagent.volume

	if(!total_volume)
		return null

	var/normalizer = 255 * total_volume
	red /= normalizer
	green /= normalizer
	blue /= normalizer
	// Tint the sprite's luminance so its original hue does not filter out the mixture color.
	return list(
		0.299 * red, 0.299 * green, 0.299 * blue, 0,
		0.587 * red, 0.587 * green, 0.587 * blue, 0,
		0.114 * red, 0.114 * green, 0.114 * blue, 0,
		0, 0, 0, 1,
		0, 0, 0, 0,
	)

#undef BATH_IMMERSION_MASK



// Типы ванн
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



// Рецепты
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







///
// Ловушка ванны

// Запуск и захват

/obj/structure/bath/proc/get_single_bath_trap_core()
	var/obj/item/reagent_containers/food/snacks/slime_core_egg/selected_core
	for(var/obj/item/reagent_containers/food/snacks/slime_core_egg/core in contents)
		if(QDELETED(core))
			continue
		if(selected_core)
			return null
		selected_core = core
	return selected_core

/obj/structure/bath/proc/begin_bath_trap(mob/living/victim, turf/entry, obj/item/reagent_containers/food/snacks/slime_core_egg/core)
	if(bath_trap_occupant || QDELETED(core) || core.loc != src)
		return
	if(get_bath_water_volume() < water_overlay_min_volume)
		return
	if(QDELETED(victim) || victim.buckled != src || !victim.client || !ishuman(victim) || victim.stat == DEAD || (victim.status_flags & GODMODE))
		return
	if(HAS_TRAIT(victim, TRAIT_DEFEAT_REFUSE_ADVANCES) || !(victim.get_cached_horny_mob_family_flags() & HORNY_MOB_TYPE_TENTACLES) || !victim.get_cached_horny_mob_pref_flags())
		return

	bath_trap_proxy = new(get_turf(src))
	bath_trap_scene = bath_trap_proxy.open_sex_scene(victim, FALSE)
	if(!bath_trap_scene || !start_bath_trap_action(victim))
		clear_bath_trap()
		return

	bath_trap_occupant = victim
	bath_trap_entry = entry
	bath_trap_core = core
	unbuckle_mob(victim, force = TRUE, can_fall = FALSE)
	victim.forceMove(src)
	bath_trap_proxy.forceMove(src)
	victim.add_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_MUTE, TRAIT_SPELLBLOCK), REF(src))
	victim.become_blind(REF(src))
	RegisterSignal(victim, COMSIG_MOB_ABILITY_STARTED, PROC_REF(block_bath_trap_ability))
	RegisterSignal(victim, list(COMSIG_MOB_BEFORE_SPELL_CAST, COMSIG_MOB_SPELL_ACTIVATED), PROC_REF(block_bath_trap_spell))
	bath_trap_scene.set_current_force(rand(SEX_FORCE_MID, SEX_FORCE_EXTREME))
	bath_trap_scene.set_current_speed(rand(SEX_SPEED_MID, SEX_SPEED_EXTREME))
	collect_bath_trap_items(victim)
	update_appearance(UPDATE_OVERLAYS)
	bath_trap_timer = addtimer(CALLBACK(src, PROC_REF(check_bath_trap)), 1 SECONDS, TIMER_STOPPABLE | TIMER_LOOP)

/obj/structure/bath/proc/start_bath_trap_action(mob/living/victim)
	var/list/actions = list(
		/datum/sex_action/npc/npc_anal_sex/tentacle/maneater/bath,
		/datum/sex_action/npc/npc_throat_sex/tentacle/maneater/bath,
		/datum/sex_action/maneater_vine_caress/bath,
	)
	if(victim.getorganslot(ORGAN_SLOT_VAGINA))
		actions += /datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater/bath
	if(victim.getorganslot(ORGAN_SLOT_PENIS))
		actions += /datum/sex_action/tentacle_jerk/maneater/bath
	while(length(actions))
		if(bath_trap_scene.try_start_action(pick_n_take(actions), "ai"))
			break
	return length(bath_trap_scene.get_active_actions()) > 0

/obj/structure/bath/proc/collect_bath_trap_items(mob/living/victim)
	var/list/items = victim.get_equipped_items(TRUE) | victim.held_items
	for(var/obj/item/item as anything in items)
		if(item?.loc == victim)
			victim.transferItemToLoc(item, src, force = TRUE, silent = TRUE)
	var/turf/bath_turf = get_turf(src)
	for(var/obj/item/item in bath_turf)
		if(item.anchored || QDELETED(item))
			continue
		item.forceMove(src)

// Ограничения внутри ловушки

/obj/structure/bath/proc/block_bath_trap_ability()
	SIGNAL_HANDLER
	return COMPONENT_BLOCK_ABILITY_START

/obj/structure/bath/proc/block_bath_trap_spell()
	SIGNAL_HANDLER
	return SPELL_CANCEL_CAST | SPELL_NO_FEEDBACK

// Сопротивление, завершение и освобождение

/obj/structure/bath/Exited(atom/movable/gone, direction)
	. = ..()
	if(gone == bath_trap_occupant)
		clear_bath_trap()

/obj/structure/bath/container_resist(mob/living/user)
	if(user == bath_trap_occupant)
		try_release_bath_trap(user)
		return
	return ..()

/obj/structure/bath/proc/try_release_bath_trap(mob/living/escaper)
	var/mob/living/victim = bath_trap_occupant
	var/break_factor = 1
	while(victim == bath_trap_occupant && !QDELETED(escaper) && !QDELETED(victim) && victim.loc == src)
		var/escape_chance = clamp(escaper.STASTR * 2 * break_factor, 1, 99)
		escaper.changeNext_move(CLICK_CD_FAST, override = TRUE)
		if(!do_after(escaper, 1.5 SECONDS, src))
			return
		if(victim == bath_trap_occupant && victim.loc == src && prob(escape_chance))
			clear_bath_trap()
			return
		break_factor *= 1.5

/obj/structure/bath/proc/check_bath_trap()
	var/mob/living/victim = bath_trap_occupant
	if(QDELETED(victim) || victim.loc != src)
		clear_bath_trap()
		return
	if(victim.stat == DEAD || !victim.client)
		clear_bath_trap()
		return
	if(QDELETED(bath_trap_scene) || !length(bath_trap_scene.get_active_actions()))
		if(!QDELETED(bath_trap_core) && bath_trap_core.loc == src)
			qdel(bath_trap_core)
		clear_bath_trap()
		inject_bath_trap_reagents(victim)

/obj/structure/bath/proc/inject_bath_trap_reagents(mob/living/victim)
	var/datum/reagents/bath_reagents = reagents
	for(var/datum/reagent/reagent as anything in bath_reagents?.reagent_list?.Copy())
		if(QDELETED(victim) || QDELETED(bath_reagents) || !victim.reagents || victim.reagents.holder_full())
			break
		if(QDELETED(reagent) || reagent.volume <= 0 || ispath(reagent.type, /datum/reagent/water))
			continue
		var/dose = min(30, victim.reagents.maximum_volume - victim.reagents.total_volume)
		var/reagent_type = reagent.type
		var/list/reagent_data = bath_reagents.copy_data(reagent)
		bath_reagents.react_single(reagent, victim, INJECT, dose / reagent.volume, show_message = FALSE)
		if(!QDELETED(victim))
			victim.reagents?.add_reagent(reagent_type, dose, reagent_data)

/obj/structure/bath/proc/clear_bath_trap()
	var/mob/living/victim = bath_trap_occupant
	var/turf/entry = bath_trap_entry
	bath_trap_occupant = null
	bath_trap_entry = null
	bath_trap_core = null
	if(victim)
		UnregisterSignal(victim, list(COMSIG_MOB_ABILITY_STARTED, COMSIG_MOB_BEFORE_SPELL_CAST, COMSIG_MOB_SPELL_ACTIVATED))
		if(!QDELETED(victim))
			victim.remove_traits(list(TRAIT_IMMOBILIZED, TRAIT_HANDS_BLOCKED, TRAIT_MUTE, TRAIT_SPELLBLOCK), REF(src))
			victim.cure_blind(REF(src))
	if(bath_trap_timer)
		deltimer(bath_trap_timer)
		bath_trap_timer = null
	bath_trap_scene = null
	QDEL_NULL(bath_trap_proxy)
	if(!QDELETED(victim) && victim.loc == src)
		var/turf/destination = get_turf(src)
		if(entry && !entry.is_blocked_turf(source_atom = victim))
			destination = entry
		victim.forceMove(destination)
		if(!QDELETED(src) && victim.m_intent != MOVE_INTENT_SNEAK && reagents?.total_volume >= water_overlay_min_volume)
			playsound(src, pick('sound/foley/watermove (1).ogg', 'sound/foley/watermove (2).ogg'), 40, FALSE)
	if(!has_buckled_mobs())
		stop_reagent_touch_timer()
	if(!QDELETED(src))
		update_appearance(UPDATE_OVERLAYS)

/obj/structure/bath/proc/release_bath_trap_items(turf/drop_turf, keep_cores = FALSE)
	if(!drop_turf)
		return FALSE
	. = FALSE
	for(var/obj/item/item in contents.Copy())
		if(QDELETED(item) || item.loc != src)
			continue
		if(keep_cores && istype(item, /obj/item/reagent_containers/food/snacks/slime_core_egg))
			continue
		item.forceMove(drop_turf)
		. = TRUE

// Эффекты ядер при захвате

/obj/item/reagent_containers/food/snacks/slime_core_egg/proc/on_bath_trap_capture(obj/structure/bath/bath, mob/living/victim, turf/entry)
	if(type == /obj/item/reagent_containers/food/snacks/slime_core_egg)
		bath.begin_bath_trap(victim, entry, src)

/obj/item/reagent_containers/food/snacks/slime_core_egg/black/on_bath_trap_capture(obj/structure/bath/bath, mob/living/victim, turf/entry)
	return

/obj/item/reagent_containers/food/snacks/slime_core_egg/green/on_bath_trap_capture(obj/structure/bath/bath, mob/living/victim, turf/entry)
	return

/obj/item/reagent_containers/food/snacks/slime_core_egg/gray/on_bath_trap_capture(obj/structure/bath/bath, mob/living/victim, turf/entry)
	return

/obj/item/reagent_containers/food/snacks/slime_core_egg/red/on_bath_trap_capture(obj/structure/bath/bath, mob/living/victim, turf/entry)
	return

/obj/item/reagent_containers/food/snacks/slime_core_egg/blue/on_bath_trap_capture(obj/structure/bath/bath, mob/living/victim, turf/entry)
	return

// Прокси ловушки

/mob/living/simple_animal/hostile/retaliate/slime_tendrils
	name = "slime tendrils"
	desc = "Gelatinous tendrils that rise from the bath."
	icon = 'modular_rmh/icons/mob/monster/tentacles_grey.dmi'
	icon_state = "vine_medium"
	icon_living = "vine_medium"
	icon_dead = "vine_medium"
	faction = list("slime")
	gender = PLURAL
	ai_controller = null
	move_resist = INFINITY
	density = FALSE
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	invisibility = INVISIBILITY_ABSTRACT
	health = 100
	maxHealth = 100

/mob/living/simple_animal/hostile/retaliate/slime_tendrils/Initialize(mapload)
	. = ..()
	apply_tentacle_palette(TENTACLE_PALETTE_VINE)
	var/obj/item/organ/genitals/penis/ovipositor/ovipositor = ensure_tentacle_ovipositor(src)
	if(ovipositor)
		ovipositor.name = "gelatinous tendril"
		ovipositor.desc = "A flexible strand of slime."

// Действия прокси

/proc/can_perform_bath_trap_action(mob/living/user, mob/living/target)
	return istype(user, /mob/living/simple_animal/hostile/retaliate/slime_tendrils) && user != target

/datum/sex_action/npc/npc_vaginal_sex/tentacle/maneater/bath/shows_on_menu(mob/living/user, mob/living/target)
	return can_perform_bath_trap_action(user, target)

/datum/sex_action/npc/npc_anal_sex/tentacle/maneater/bath/shows_on_menu(mob/living/user, mob/living/target)
	return can_perform_bath_trap_action(user, target)

/datum/sex_action/npc/npc_throat_sex/tentacle/maneater/bath/shows_on_menu(mob/living/user, mob/living/target)
	return can_perform_bath_trap_action(user, target)

/datum/sex_action/tentacle_jerk/maneater/bath/shows_on_menu(mob/living/user, mob/living/target)
	return can_perform_bath_trap_action(user, target) && !!target.getorganslot(ORGAN_SLOT_PENIS)

/datum/sex_action/maneater_vine_caress/bath/shows_on_menu(mob/living/user, mob/living/target)
	return can_perform_bath_trap_action(user, target)
///
