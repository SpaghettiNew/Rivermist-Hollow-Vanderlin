#define BATH_IMMERSION_MASK "bath_immersion_mask"

/obj/structure/bath
	name = "bath"
	icon = 'modular_rmh/icons/obj/structures/baths.dmi'
	icon_state = "bath_wooden"
	density = TRUE
	anchored = FALSE
	can_buckle = TRUE
	buckle_lying = 0
	var/max_reagent_volume = 900
	var/water_overlay_min_volume = 600
	var/north_south_occupant_y_offset = 2
	var/west_occupant_x_offset = 6
	var/east_occupant_x_offset = -6
	/// Volume multiplier passed to the reagent contact reaction.
	var/reagent_touch_volume_multiplier = 5
	var/reagent_touch_interval = 5 SECONDS
	var/reagent_touch_timer

/obj/structure/bath/Initialize()
	. = ..()
	create_reagents(max_reagent_volume, NO_REACT | AMOUNT_VISIBLE | REFILLABLE | DRAINABLE)
	reagents.add_reagent(/datum/reagent/water, water_overlay_min_volume)

// Изменение положения игрока, ванной и оверлея воды после изменения направления ванной
/obj/structure/bath/Moved(atom/OldLoc, Dir, Forced = FALSE)
	. = ..()
	update_occupant_offsets()
	if(reagents?.total_volume >= water_overlay_min_volume)
		update_appearance(UPDATE_OVERLAYS)

/obj/structure/bath/proc/update_occupant_offsets()
	for(var/mob/living/occupant as anything in buckled_mobs)
		update_occupant_offset(occupant)
		update_immersion_mask(occupant)

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
	update_occupant_offsets()
	if(reagents?.total_volume >= water_overlay_min_volume)
		update_appearance(UPDATE_OVERLAYS)


// бакливание
/obj/structure/bath/post_buckle_mob(mob/living/buckled_mob)
	. = ..()
	update_occupant_offset(buckled_mob)
	update_immersion_mask(buckled_mob)
	if(!reagent_touch_timer)
		reagent_touch_timer = addtimer(CALLBACK(src, PROC_REF(apply_reagent_touch_to_occupants)), reagent_touch_interval, TIMER_STOPPABLE | TIMER_LOOP)
	apply_reagent_touch(buckled_mob)

/obj/structure/bath/post_unbuckle_mob(mob/living/unbuckled_mob)
	. = ..()
	unbuckled_mob.reset_offsets("bath")
	unbuckled_mob.remove_filter(BATH_IMMERSION_MASK)
	if(reagent_touch_timer && !has_buckled_mobs())
		deltimer(reagent_touch_timer)
		reagent_touch_timer = null

/obj/structure/bath/proc/apply_reagent_touch_to_occupants()
	var/found_occupant = FALSE
	for(var/mob/living/occupant as anything in buckled_mobs?.Copy())
		if(QDELETED(occupant) || occupant.buckled != src || occupant.loc != loc)
			continue
		found_occupant = TRUE
		apply_reagent_touch(occupant)
	if(!found_occupant && reagent_touch_timer)
		deltimer(reagent_touch_timer)
		reagent_touch_timer = null

/obj/structure/bath/proc/apply_reagent_touch(mob/living/occupant)
	if(!QDELETED(occupant) && occupant.buckled == src && reagents?.total_volume > 0)
		reagents.reaction(occupant, TOUCH, reagent_touch_volume_multiplier)


// Оверлеи воды
/obj/structure/bath/on_reagent_change(changetype)
	. = ..()
	update_appearance(UPDATE_OVERLAYS)
	for(var/mob/living/occupant as anything in buckled_mobs)
		update_immersion_mask(occupant)

/obj/structure/bath/proc/update_immersion_mask(mob/living/occupant)
	var/static/icon/upright_mask = icon('icons/effects/icon_cutter.dmi', "icon_cutter")
	var/mask_y_offset = -9
	if(reagents?.total_volume >= water_overlay_min_volume)
		mask_y_offset = -2
	else if(dir == EAST || dir == WEST)
		mask_y_offset = -6
	occupant.add_filter(BATH_IMMERSION_MASK, 1, alpha_mask_filter(0, mask_y_offset, upright_mask, null, MASK_INVERSE))

/obj/structure/bath/update_overlays()
	. = ..()
	if(reagents?.total_volume >= water_overlay_min_volume)
		var/mutable_appearance/full_overlay = mutable_appearance(icon, "[icon_state]_full")
		full_overlay.dir = dir
		. += full_overlay


//
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
