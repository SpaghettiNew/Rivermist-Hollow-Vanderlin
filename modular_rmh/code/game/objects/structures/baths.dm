#define BATH_IMMERSION_MASK "bath_immersion_mask"

/obj/structure/bath
	name = "bath"
	icon = 'modular_rmh/icons/obj/structures/baths.dmi'
	icon_state = "bath_wooden"
	density = FALSE
	anchored = FALSE
	move_resist = MOVE_FORCE_NORMAL
	drag_slowdown = 6
	var/max_reagent_volume = 900 // Ёмкость ванны. Initialize()
	var/water_overlay_min_volume = 600 // Обычно 1/3 ванны. При таком объеме начинают работать механики ванной связанные с водой
	var/north_south_occupant_y_offset = 2
	var/west_occupant_x_offset = 6
	var/east_occupant_x_offset = -6
	var/north_empty_mask_y_offset = -2
	var/south_empty_mask_y_offset = -9
	var/east_west_empty_mask_y_offset = -6
	var/north_filled_mask_y_offset = -2
	var/south_filled_mask_y_offset = -2
	var/east_west_filled_mask_y_offset = -4
	var/reagent_touch_amount = 5 // Максимальная контактная доза. apply_reagent_touch()
	var/reagent_touch_interval = 10 SECONDS // Интервал контакта. add_occupant_appearance()
	var/reagent_touch_timer // ID таймера контакта. add_occupant_appearance(), stop_reagent_touch_timer()
	var/turf/occupant_turf // Отслеживаемый тайл ванны. update_occupant_turf(), on_occupant_moved(), apply_reagent_touch_to_occupants(), is_bath_reagent_occupant(), update_directional_appearance(), on_reagent_change()
	var/entry_delay = 1 SECONDS // Задержка захода в ванну. Cross(), try_enter_bath()
	var/list/entry_attempts // Попытки входа по персонажам. Cross(), try_enter_bath()




// Жизненный цикл

/obj/structure/bath/Initialize()
	. = ..()
	create_reagents(max_reagent_volume, AMOUNT_VISIBLE | REFILLABLE | DRAINABLE)
	update_occupant_turf(isturf(loc) ? loc : null)
	return INITIALIZE_HINT_LATELOAD

/obj/structure/bath/LateInitialize()
	. = ..()
	break_overlapping_baths()

/obj/structure/bath/Destroy()
	update_occupant_turf(null)
	stop_reagent_touch_timer()
	return ..()




// Взаимодействие и мытьё

/obj/structure/bath/attack_hand(mob/living/user, list/modifiers)
	if(!is_bath_reagent_occupant(user))
		if(has_occupants())
			return ..()
		if(..())
			return TRUE
	else
		add_fingerprint(user)

	if(!user.cmode)
		wash_occupant(user)
	return TRUE

/obj/structure/bath/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
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

/obj/structure/bath/proc/has_water_for_washing(mob/living/user)
	if(get_bath_water_volume() < water_overlay_min_volume)
		to_chat(user, span_warning("Bath is almost empty, you need to fill it up first for at least [water_overlay_min_volume]"))
		return FALSE

	if(!get_wash_water_type())
		to_chat(user, span_warning("No water to wash these stains."))
		return FALSE
	return TRUE

/obj/structure/bath/proc/wash_occupant(mob/living/user)
	if(!has_water_for_washing(user))
		return

	var/list/wash_sounds = list('sound/foley/waterwash (1).ogg', 'sound/foley/waterwash (2).ogg')
	user.visible_message(span_info("[user] starts to wash in [src]."))
	playsound(user, pick_n_take(wash_sounds), 100, FALSE)
	if(!do_after(user, 3 SECONDS, src) || QDELETED(src) || QDELETED(user))
		return
	if(!is_bath_reagent_occupant(user) && has_occupants())
		return
	if(!has_water_for_washing(user))
		return

	user.wash(CLEAN_WASH)
	playsound(user, pick(wash_sounds), 100, FALSE)
	if(ishuman(user))
		var/mob/living/carbon/human/bather = user
		if(bather.wear_armor || bather.wear_shirt || bather.wear_pants)
			to_chat(bather, span_notice("I can't wash properly with my clothes on."))




// Занятость ванны

/obj/structure/bath/Cross(atom/movable/mover)
	if(istype(mover, /obj/structure/bath) && mover.loc != loc)
		return FALSE
	. = ..()
	if(!. || entry_delay <= 0 || !isliving(mover) || !isturf(mover.loc) || !isturf(loc) || mover.loc == loc || mover.throwing || (mover.movement_type & PHASING))
		return
	if(LAZYACCESS(entry_attempts, mover) == loc)
		return
	if(!LAZYACCESS(entry_attempts, mover))
		LAZYSET(entry_attempts, mover, TRUE)
		INVOKE_ASYNC(src, PROC_REF(try_enter_bath), mover, mover.loc, loc)
	return FALSE

/obj/structure/bath/proc/try_enter_bath(mob/living/entrant, turf/start, turf/destination)
	var/show_progress = !(locate(/mob/living/carbon/human) in destination)
	if(!QDELETED(entrant) && entrant.loc == start && loc == destination && do_after(entrant, entry_delay, src, timed_action_flags = IGNORE_SLOWDOWNS, progress = show_progress, hidden = !show_progress))
		if(!QDELETED(src) && !QDELETED(entrant) && entrant.loc == start && loc == destination)
			LAZYSET(entry_attempts, entrant, destination)
			entrant.Move(destination, get_dir(start, destination))
	LAZYREMOVE(entry_attempts, entrant)

/obj/structure/bath/proc/has_occupants()
	return isturf(loc) && (locate(/mob/living) in loc)

/obj/structure/bath/can_be_pulled(user, grab_state, force)
	return !has_occupants() && ..()

/obj/structure/bath/Move(atom/newloc, direct, glide_size_override = 0, update_dir = TRUE)
	if(newloc != loc)
		if(has_occupants() || (isturf(newloc) && (locate(/mob/living/carbon/human) in newloc)))
			return FALSE
	return ..()

/obj/structure/bath/proc/break_overlapping_baths() // Предохраняемся от рантаймов
	if(!isturf(loc) || QDELETED(src))
		return FALSE
	var/turf/bath_turf = loc
	var/list/overlapping_baths = list()
	for(var/obj/structure/bath/bath in bath_turf)
		if(!QDELETED(bath))
			overlapping_baths += bath
	if(length(overlapping_baths) < 2)
		return FALSE

	for(var/obj/structure/bath/bath as anything in overlapping_baths)
		if(!QDELETED(bath) && bath.loc == bath_turf)
			bath.atom_destruction()
	return TRUE

/obj/structure/bath/proc/update_occupant_turf(turf/new_turf)
	if(occupant_turf == new_turf)
		return
	if(occupant_turf)
		UnregisterSignal(occupant_turf, COMSIG_ATOM_ENTERED)
		for(var/mob/living/occupant in occupant_turf)
			remove_occupant_appearance(occupant)
	occupant_turf = new_turf
	if(!occupant_turf)
		return
	RegisterSignal(occupant_turf, COMSIG_ATOM_ENTERED, PROC_REF(on_occupant_entered))
	for(var/mob/living/occupant in occupant_turf)
		add_occupant_appearance(occupant)

/obj/structure/bath/proc/on_occupant_entered(turf/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER
	if(!isliving(arrived) || old_loc == source)
		return
	var/mob/living/occupant = arrived
	add_occupant_appearance(occupant)
	if(ishuman(occupant) && reagents?.total_volume < water_overlay_min_volume)
		to_chat(occupant, span_warning("Bath is half empty, it would be good to fill it with water at least for [water_overlay_min_volume]"))
	if(occupant.m_intent != MOVE_INTENT_SNEAK && reagents?.total_volume >= water_overlay_min_volume)
		playsound(src, 'sound/foley/waterenter.ogg', 40, FALSE)

/obj/structure/bath/proc/on_occupant_moved(mob/living/occupant)
	SIGNAL_HANDLER
	if(occupant.loc == occupant_turf)
		return
	remove_occupant_appearance(occupant)
	if(occupant.m_intent != MOVE_INTENT_SNEAK && reagents?.total_volume >= water_overlay_min_volume)
		playsound(src, pick('sound/foley/watermove (1).ogg', 'sound/foley/watermove (2).ogg'), 40, FALSE)
	if(!has_occupants())
		stop_reagent_touch_timer()

/obj/structure/bath/proc/add_occupant_appearance(mob/living/occupant)
	RegisterSignal(occupant, COMSIG_MOVABLE_MOVED, PROC_REF(on_occupant_moved), override = TRUE)
	update_occupant_offset(occupant)
	update_immersion_mask(occupant)
	if(!reagent_touch_timer)
		reagent_touch_timer = addtimer(CALLBACK(src, PROC_REF(apply_reagent_touch_to_occupants)), reagent_touch_interval, TIMER_STOPPABLE | TIMER_LOOP)

/obj/structure/bath/proc/remove_occupant_appearance(mob/living/occupant)
	UnregisterSignal(occupant, COMSIG_MOVABLE_MOVED)
	if(QDELETED(occupant))
		return
	occupant.reset_offsets(REF(src))
	occupant.remove_filter("[BATH_IMMERSION_MASK]-[REF(src)]")


// Применение реагентов

/obj/structure/bath/proc/stop_reagent_touch_timer()
	if(reagent_touch_timer)
		deltimer(reagent_touch_timer)
		reagent_touch_timer = null

/obj/structure/bath/proc/apply_reagent_touch_to_occupants()
	var/found_occupant = FALSE
	for(var/mob/living/occupant in occupant_turf?.contents.Copy())
		if(apply_reagent_touch(occupant))
			found_occupant = TRUE
	if(!found_occupant)
		stop_reagent_touch_timer()

/obj/structure/bath/proc/is_bath_reagent_occupant(mob/living/occupant)
	if(QDELETED(occupant))
		return FALSE
	return occupant_turf && occupant.loc == occupant_turf

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
	if((flags_1 & INITIALIZED_1) && break_overlapping_baths())
		return
	update_occupant_turf(isturf(loc) ? loc : null)
	update_directional_appearance()

/obj/structure/bath/proc/update_directional_appearance()
	for(var/mob/living/occupant in occupant_turf)
		update_occupant_offset(occupant)
		update_immersion_mask(occupant)
	if(reagents?.total_volume > 0)
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
	occupant.set_mob_offsets(REF(src), _x = x_offset, _y = y_offset)

/obj/structure/bath/setDir(newdir)
	. = ..()
	update_directional_appearance()

/obj/structure/bath/on_reagent_change(changetype)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
	for(var/mob/living/occupant in occupant_turf)
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
	occupant.add_filter("[BATH_IMMERSION_MASK]-[REF(src)]", 1, alpha_mask_filter(0, mask_y_offset, upright_mask, null, MASK_INVERSE))

/obj/structure/bath/update_overlays()
	. = ..()
	var/liquid_volume = reagents?.total_volume
	if(liquid_volume > 0)
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
	east_west_filled_mask_y_offset = -2



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
