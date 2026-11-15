/*
 * Anti-Magic Fields
 *
 * Shared, event-driven field registry and the two field entities.
 * The spatial footprint is an XY rectangle whose lower-left tile is the
 * device's own turf. Z coverage is the anchor Z plus/minus one level.
 */

#define ANTI_MAGIC_FIELD_MAX_ACTIVE 15
#define ANTI_MAGIC_FIELD_STATIONARY_WIDTH 8
#define ANTI_MAGIC_FIELD_STATIONARY_HEIGHT 8
#define ANTI_MAGIC_FIELD_THROWABLE_WIDTH 4
#define ANTI_MAGIC_FIELD_THROWABLE_HEIGHT 4
#define ANTI_MAGIC_FIELD_THROWABLE_BUILD_TIME (5 SECONDS)
#define ANTI_MAGIC_FIELD_THROWABLE_LIFETIME (8 MINUTES)
#define ANTI_MAGIC_FIELD_THROWABLE_WATER_LIFETIME (4 MINUTES)
#define ANTI_MAGIC_FIELD_RECOVERY_TIME (5 SECONDS)

GLOBAL_DATUM_INIT(anti_magic_field_manager, /datum/anti_magic_field_manager, new)

/// Server-side registry and the single source of truth for field permission checks.
/datum/anti_magic_field_manager
	var/list/fields = list()
	var/list/active_fields = list()
	/// Global allowlist. Entries are stable DM type paths stored as text.
	/// Parent paths also permit their subtypes. This default list deliberately
	/// contains role-conversion spells plus restorative and non-hostile utility spells.
	var/list/global_whitelist = list(
		// Role conversion / recruitment.
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/servant",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/retainer",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/chapel_acolyte",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/forest_ranger",
		"/datum/action/cooldown/spell/undirected/list_target/convert_role/adventurers_guild",

		// Healing, restoration, medicine, and repair.
		"/datum/action/cooldown/spell/healing",
		"/datum/action/cooldown/spell/defeat_absolution",
		"/datum/action/cooldown/spell/revive",
		"/datum/action/cooldown/spell/cure_rot",
		"/datum/action/cooldown/spell/attach_bodypart",
		"/datum/action/cooldown/spell/ocean_embrace",
		"/datum/action/cooldown/spell/mend_item",
		"/datum/action/cooldown/spell/undirected/psydonrespite",
		"/datum/action/cooldown/spell/undirected/regenerate",
		"/datum/action/cooldown/spell/seelie_kiss",
		"/datum/action/cooldown/spell/undirected/song/rejuvenation_song",
		"/datum/action/cooldown/spell/undirected/song/recovery_song",
		"/datum/action/cooldown/spell/undirected/conjure_item/summon_leech/pestra",

		// Medical and information utility.
		"/datum/action/cooldown/spell/diagnose",
		"/datum/action/cooldown/spell/appraise",
		"/datum/action/cooldown/spell/find_flaw",
		"/datum/action/cooldown/spell/detect_singles",
		"/datum/action/cooldown/spell/undirected/locate_dead",
		"/datum/action/cooldown/spell/undirected/arcyne_eye",
		"/datum/action/cooldown/spell/undirected/secondsight",
		"/datum/action/cooldown/spell/undirected/beast_sense",
		"/datum/action/cooldown/spell/eoran_bloom",

		// Non-hostile support buffs.
		"/datum/action/cooldown/spell/undirected/blade_ward",
		"/datum/action/cooldown/spell/undirected/protection_evil_good",
		"/datum/action/cooldown/spell/undirected/call_to_arms",
		"/datum/action/cooldown/spell/undirected/call_to_slaughter",
		"/datum/action/cooldown/spell/undirected/battle_song",
		"/datum/action/cooldown/spell/status/guidance",
		"/datum/action/cooldown/spell/status/haste",
		"/datum/action/cooldown/spell/status/vigorous_craft",
		"/datum/action/cooldown/spell/status/invisibility",
		"/datum/action/cooldown/spell/undirected/song/fervor_song",
		"/datum/action/cooldown/spell/undirected/song/accelakathist",
		"/datum/action/cooldown/spell/undirected/song/furtive_fortissimo",
		"/datum/action/cooldown/spell/undirected/song/intellectual_interval",

		// Communication, harmless tricks, and practical utility.
		"/datum/action/cooldown/spell/undirected/message",
		"/datum/action/cooldown/spell/undirected/personality_commune",
		"/datum/action/cooldown/spell/undirected/soul_speak",
		"/datum/action/cooldown/spell/undirected/howl/call_of_the_moon",
		"/datum/action/cooldown/spell/undirected/call_bird",
		"/datum/action/cooldown/spell/undirected/joke",
		"/datum/action/cooldown/spell/undirected/tragedy",
		"/datum/action/cooldown/spell/undirected/bless_crops",
		"/datum/action/cooldown/spell/undirected/longstrider",
		"/datum/action/cooldown/spell/undirected/feather_falling",
		"/datum/action/cooldown/spell/undirected/touch/darkvision",
		"/datum/action/cooldown/spell/undirected/touch/non_detection",
		"/datum/action/cooldown/spell/undirected/touch/prestidigitation",
		"/datum/action/cooldown/spell/undirected/touch/orison",
		"/datum/action/cooldown/spell/undirected/conjure_item/light",
		"/datum/action/cooldown/spell/undirected/conjure_item/summon_lockpick",
		"/datum/action/cooldown/spell/undirected/conjure_item/calling_card",
		"/datum/action/cooldown/spell/undirected/jaunt/illusory_prop",
		"/datum/action/cooldown/spell/undirected/jaunt/bush_jaunt",
		"/datum/action/cooldown/spell/aoe/knock",
		"/datum/action/cooldown/spell/seelie_replenish",
	)

/datum/anti_magic_field_manager/proc/register_field(obj/structure/anti_magic_field/field)
	if(!field || QDELETED(field))
		return FALSE
	if(!(field in fields))
		fields += field
	return TRUE

/datum/anti_magic_field_manager/proc/activate_field(obj/structure/anti_magic_field/field)
	if(!field || QDELETED(field) || field.obj_broken || !field.is_built)
		return FALSE
	if(field.is_active)
		return TRUE
	if(length(active_fields) >= ANTI_MAGIC_FIELD_MAX_ACTIVE)
		return FALSE

	active_fields += field
	field.is_active = TRUE
	field.waiting_for_slot = FALSE
	field.on_field_activated()
	return TRUE

/datum/anti_magic_field_manager/proc/deactivate_field(obj/structure/anti_magic_field/field)
	if(!field || QDELETED(field) || !field.is_active)
		return FALSE

	active_fields -= field
	field.is_active = FALSE
	field.on_field_deactivated()
	promote_waiting_throwables()
	return TRUE

/datum/anti_magic_field_manager/proc/unregister_field(obj/structure/anti_magic_field/field)
	if(!field)
		return
	var/was_active = field.is_active
	active_fields -= field
	fields -= field
	if(was_active)
		field.is_active = FALSE
		field.on_field_deactivated()
		promote_waiting_throwables()

/// Throwable fields that reached the active-device cap activate automatically when a slot opens.
/// Stationary fields never auto-activate; a player must toggle those back ON.
/datum/anti_magic_field_manager/proc/promote_waiting_throwables()
	if(length(active_fields) >= ANTI_MAGIC_FIELD_MAX_ACTIVE)
		return
	for(var/obj/structure/anti_magic_field/field as anything in fields)
		if(!field.waiting_for_slot || !field.auto_activate_when_slot_available || !field.is_built || field.is_active || QDELETED(field))
			continue
		if(activate_field(field))
			field.visible_message(span_notice("[field] powers up as an anti-magic field slot becomes available."))
			break

/datum/anti_magic_field_manager/proc/is_globally_whitelisted(action_id)
	if(!istext(action_id) || !length(action_id))
		return FALSE
	for(var/allowed_action_id as anything in global_whitelist)
		if(action_id == allowed_action_id || findtext(action_id, "[allowed_action_id]/") == 1)
			return TRUE
	return FALSE

/datum/anti_magic_field_manager/proc/turf_is_covered(turf/test_turf)
	if(!test_turf)
		return FALSE
	for(var/obj/structure/anti_magic_field/field as anything in active_fields)
		if(!QDELETED(field) && field.covers_turf(test_turf))
			return TRUE
	return FALSE

/// Returns TRUE when an action must be stopped by at least one active field.
/// Both the source/caster turf and the target/effect turf are checked.
/// A local override replaces the global default for that field only; any other
/// overlapping field that denies the action still blocks it.
/datum/anti_magic_field_manager/proc/is_action_blocked(atom/source, action_id, atom/target)
	if(!istext(action_id) || !length(action_id))
		return FALSE

	var/turf/source_turf = get_turf(source)
	var/turf/target_turf = get_turf(target)
	if(!source_turf && !target_turf)
		return FALSE

	for(var/obj/structure/anti_magic_field/field as anything in active_fields)
		if(QDELETED(field))
			continue
		if(!field.covers_turf(source_turf) && !field.covers_turf(target_turf))
			continue
		if(!field.permits_action(action_id))
			return TRUE
	return FALSE

/datum/anti_magic_field_manager/proc/notify_blocked(mob/caster)
	if(!caster || QDELETED(caster))
		return
	if(world.time < caster.anti_magic_field_message_cooldown)
		return
	caster.anti_magic_field_message_cooldown = world.time + (1.5 SECONDS)
	to_chat(caster, span_warning("Something outside is blocking my powers."))
	playsound('sound/magic/antimagic.ogg', caster, 50, 1.0)

/mob
	/// Anti-magic rejection feedback throttle; avoids chat spam from repeated button presses.
	var/tmp/anti_magic_field_message_cooldown = 0

/datum/looping_sound/anti_magic_field
	mid_sounds = list('sound/misc/loops/LightCrystal1.ogg')
	mid_length = 145
	volume = 35
	extra_range = 2
	falloff_distance = 2
	vary = TRUE

/// Base type shared by stationary and deployed field entities.
/obj/structure/anti_magic_field
	name = "anti-magic field generator"
	desc = "A device that suppresses unauthorized magical effects within a fixed area."
	icon = 'modular_rmh/icons/obj/structures/antimagicfield.dmi'
	icon_state = "antimagicstationary"
	SET_BASE_PIXEL(-16, -12)
	anchored = TRUE
	density = FALSE
	max_integrity = 200
	integrity_failure = 0.5
	break_sound = 'sound/combat/hits/onmetal/metalimpact (1).ogg'
	attacked_sound = list('sound/combat/hits/onmetal/metalimpact (1).ogg', 'sound/combat/hits/onmetal/metalimpact (2).ogg')

	/// Width and height in tiles. The object turf is the first (south-west) tile.
	var/field_width = ANTI_MAGIC_FIELD_STATIONARY_WIDTH
	var/field_height = ANTI_MAGIC_FIELD_STATIONARY_HEIGHT
	var/is_active = FALSE
	var/is_built = TRUE
	var/waiting_for_slot = FALSE
	/// TRUE only for a throwable device that is waiting for a registry slot.
	var/auto_activate_when_slot_available = FALSE
	/// Associative list: action identifier => TRUE (allow) / FALSE (deny).
	var/list/whitelist_overrides = list()
	var/datum/looping_sound/humming_sound

/obj/structure/anti_magic_field/Initialize(mapload)
	. = ..()
	GLOB.anti_magic_field_manager.register_field(src)

/obj/structure/anti_magic_field/Destroy()
	GLOB.anti_magic_field_manager.unregister_field(src)
	QDEL_NULL(humming_sound)
	return ..()

/obj/structure/anti_magic_field/proc/covers_turf(turf/test_turf)
	if(!test_turf || !is_active)
		return FALSE
	var/turf/anchor = get_turf(src)
	if(!anchor)
		return FALSE
	if(test_turf.z < anchor.z - 1 || test_turf.z > anchor.z + 1)
		return FALSE
	return test_turf.x >= anchor.x && test_turf.x < anchor.x + field_width \
		&& test_turf.y >= anchor.y && test_turf.y < anchor.y + field_height

/obj/structure/anti_magic_field/proc/permits_action(action_id)
	if(!istext(action_id) || !length(action_id))
		return FALSE
	if(action_id in whitelist_overrides)
		return whitelist_overrides[action_id]
	return GLOB.anti_magic_field_manager.is_globally_whitelisted(action_id)

/obj/structure/anti_magic_field/proc/activate_field(mob/user)
	if(obj_broken || !is_built)
		return FALSE
	if(GLOB.anti_magic_field_manager.activate_field(src))
		return TRUE
	if(user)
		to_chat(user, span_warning("The field remains OFF: all [ANTI_MAGIC_FIELD_MAX_ACTIVE] anti-magic field slots are occupied."))
	return FALSE

/obj/structure/anti_magic_field/proc/deactivate_field()
	return GLOB.anti_magic_field_manager.deactivate_field(src)

/obj/structure/anti_magic_field/proc/on_field_activated()
	if(!humming_sound)
		humming_sound = new /datum/looping_sound/anti_magic_field(src, FALSE)
	humming_sound.start()
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/proc/on_field_deactivated()
	QDEL_NULL(humming_sound)
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/examine(mob/user)
	. = ..()
	. += span_notice("Field coverage: [field_width]x[field_height].")
	if(is_active)
		. += span_notice("The anti-magic field is active.")
	else
		. += span_warning("The anti-magic field is OFF.")
	. += span_info("Integrity: [get_integrity()]/[max_integrity].")

/// Mirrors the door's unarmed-claw damage route. Without this, the field's
/// hand interaction (toggle/recover) consumes the click before damage is applied.
/obj/structure/anti_magic_field/proc/try_unarmed_damage(mob/user)
	if(!user || obj_broken || user.used_intent?.type != /datum/intent/unarmed/claw)
		return FALSE
	user.changeNext_move(CLICK_CD_MELEE)
	to_chat(user, span_warning("I claw at [src]."))
	take_damage(40, BRUTE, BCLASS_CUT, TRUE)
	return TRUE

/obj/structure/anti_magic_field/stationary
	name = "stationary anti-magic field generator"
	desc = "A heavy field generator. It can be toggled by anyone and repaired like an iron door."
	max_integrity = 200
	// The repairable component requires a non-zero break threshold. 1% keeps
	// the requested effectively-zero-HP break point while using the door lifecycle.
	integrity_failure = 0.01
	field_width = ANTI_MAGIC_FIELD_STATIONARY_WIDTH
	field_height = ANTI_MAGIC_FIELD_STATIONARY_HEIGHT
	var/list/repair_thresholds = list(/obj/item/ingot/iron = 1)
	var/obj/item/broken_repair = /obj/item/ingot/iron
	var/repair_skill = /datum/attribute/skill/craft/blacksmithing

/obj/structure/anti_magic_field/stationary/Initialize(mapload)
	. = ..()
	AddComponent(/datum/component/repairable, repair_thresholds, broken_repair, 'sound/misc/wood_saw.ogg', repair_skill)
	activate_field()

/obj/structure/anti_magic_field/stationary/attack_hand(mob/user)
	. = ..()
	if(. || !user)
		return
	if(try_unarmed_damage(user))
		return ITEM_INTERACT_SUCCESS
	if(obj_broken)
		to_chat(user, span_warning("The generator is broken and must be repaired first."))
		return ITEM_INTERACT_SUCCESS
	if(is_active)
		deactivate_field()
		user.visible_message(span_notice("[user] switches [src] OFF."), span_notice("I switch [src] OFF."))
		return ITEM_INTERACT_SUCCESS
	if(activate_field(user))
		user.visible_message(span_notice("[user] switches [src] ON."), span_notice("I switch [src] ON."))
	return ITEM_INTERACT_SUCCESS

/obj/structure/anti_magic_field/stationary/attack_paw(mob/user)
	return attack_hand(user)

/obj/structure/anti_magic_field/stationary/atom_break(damage_flag, silent)
	// Same lifecycle as /obj/structure/door: parent sets obj_broken and emits
	// COMSIG_ATOM_BREAK so the repairable component records the broken state.
	. = ..()
	deactivate_field()
	update_appearance(UPDATE_ICON_STATE)

/// Keep the broken structure in-world for the door-style broken-item repair.
/// The 1% threshold guarantees atom_break() has set obj_broken before this runs.
/obj/structure/anti_magic_field/stationary/atom_destruction(damage_flag)
	if(!obj_broken)
		return ..()
	update_integrity(1, FALSE, damage_flag)
	deactivate_field()
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/stationary/atom_fix()
	. = ..()
	// Same as a door: fixing clears obj_broken via the parent, but does not
	// automatically reactivate the device.
	deactivate_field()
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/anti_magic_field/stationary/update_icon_state()
	. = ..()
	if(obj_broken)
		icon_state = "antimagicstationarybroken"
	else
		icon_state = initial(icon_state)

/obj/structure/anti_magic_field/stationary/OnCrafted(dirin, mob/user)
	. = ..()
	if(user && !is_active && !obj_broken && length(GLOB.anti_magic_field_manager.active_fields) >= ANTI_MAGIC_FIELD_MAX_ACTIVE)
		to_chat(user, span_warning("The generator is built, but remains OFF because all anti-magic field slots are occupied."))

/obj/structure/anti_magic_field/throwable
	name = "deployed anti-magic field generator"
	desc = "A compact throwable generator that unfolds, activates, and eventually burns out."
	icon = 'modular_rmh/icons/obj/structures/antimagicfield.dmi'
	icon_state = "antimagicthrowabletile"
	max_integrity = 100
	// Deployed generators have no broken/repairable state. They are destroyed at 0 HP.
	integrity_failure = 0
	field_width = ANTI_MAGIC_FIELD_THROWABLE_WIDTH
	field_height = ANTI_MAGIC_FIELD_THROWABLE_HEIGHT
	is_built = FALSE
	auto_activate_when_slot_available = TRUE
	var/construction_timer
	var/lifetime_timer
	var/is_constructing = TRUE
	var/field_lifetime = ANTI_MAGIC_FIELD_THROWABLE_LIFETIME

/obj/structure/anti_magic_field/throwable/Initialize(mapload)
	. = ..()
	if(istype(get_turf(src), /turf/open/water))
		field_lifetime = ANTI_MAGIC_FIELD_THROWABLE_WATER_LIFETIME
	construction_timer = addtimer(CALLBACK(src, PROC_REF(finish_construction)), ANTI_MAGIC_FIELD_THROWABLE_BUILD_TIME, TIMER_STOPPABLE)
	update_icon_state()

/// Start the energy drain only while the deployed field is actively working.
/obj/structure/anti_magic_field/throwable/on_field_activated()
	. = ..()
	START_PROCESSING(SSmagic, src)

/obj/structure/anti_magic_field/throwable/on_field_deactivated()
	STOP_PROCESSING(SSmagic, src)
	return ..()

/// SSmagic fires once per second. A working deployed generator loses exactly 2 HP per SSmagic tick.
/// Integrity is updated without the normal break callback so obj_broken is never set.
/obj/structure/anti_magic_field/throwable/process(delta_time)
	if(!is_active || is_constructing || !is_built)
		return PROCESS_KILL

	var/remaining_integrity = max(get_integrity() - 2, 0)
	update_integrity(remaining_integrity, FALSE)
	if(!remaining_integrity)
		// Call the normal destruction path directly, deliberately skipping atom_break().
		atom_destruction("anti_magic_field_depleted")
		return PROCESS_KILL
	return TRUE

/obj/structure/anti_magic_field/throwable/Destroy()
	if(construction_timer)
		deltimer(construction_timer)
		construction_timer = null
	if(lifetime_timer)
		deltimer(lifetime_timer)
		lifetime_timer = null
	return ..()

/// Any successful damage during deployment interrupts and destroys the device.
/obj/structure/anti_magic_field/throwable/take_damage(damage_amount, damage_type = BRUTE, damage_flag = "", sound_effect = TRUE, attack_dir, armour_penetration = 0)
	. = ..()
	if(is_constructing && . && !QDELETED(src))
		visible_message(span_warning("[src] is struck during deployment and breaks apart before it can activate!"))
		playsound('sound/magic/crystal.ogg', src, 50, 1.0)
		qdel(src)

/obj/structure/anti_magic_field/throwable/proc/finish_construction()
	construction_timer = null
	if(QDELETED(src))
		return
	is_constructing = FALSE
	is_built = TRUE
	update_integrity(max_integrity, FALSE)
	visible_message(span_notice("[src] finishes unfolding and activates."))
	if(!activate_field())
		waiting_for_slot = TRUE
		visible_message(span_warning("[src] remains dormant until an anti-magic field slot becomes available."))
	lifetime_timer = addtimer(CALLBACK(src, PROC_REF(expire_field)), field_lifetime, TIMER_STOPPABLE)
	update_icon_state()

/obj/structure/anti_magic_field/throwable/proc/expire_field()
	lifetime_timer = null
	if(QDELETED(src))
		return
	visible_message(span_warning("[src] sputters, collapses, and destroys itself as its charge expires!"))
	playsound('sound/magic/crystal.ogg', src, 50, 1.0)
	qdel(src)

/obj/structure/anti_magic_field/throwable/attack_hand(mob/user)
	if(!user)
		return ..()
	if(try_unarmed_damage(user))
		return ITEM_INTERACT_SUCCESS
	if(is_constructing || !is_active || user.cmode)
		return ..()
	user.visible_message(span_notice("[user] begins recovering [src]."), span_notice("I begin recovering [src]."))
	if(!do_after(user, ANTI_MAGIC_FIELD_RECOVERY_TIME, src))
		return ITEM_INTERACT_SUCCESS
	if(QDELETED(src) || !is_active || is_constructing)
		return ITEM_INTERACT_SUCCESS
	var/turf/recovery_turf = get_turf(src)
	if(!recovery_turf)
		return ITEM_INTERACT_SUCCESS
	new /obj/item/rope/net/bola/mantrap/anti_magic_field(recovery_turf)
	visible_message(span_notice("[user] folds [src] back into its throwable frame."))
	qdel(src)
	return ITEM_INTERACT_SUCCESS

/obj/structure/anti_magic_field/throwable/atom_destruction(damage_flag)
	if(damage_flag == "anti_magic_field_depleted")
		visible_message(span_warning("[src] sputters, loses its remaining charge, and breaks down completely!"))
	else
		visible_message(span_warning("[src] is destroyed in a burst of sparks!"))
	return ..()

/obj/structure/anti_magic_field/throwable/update_icon_state()
	. = ..()
	if(is_constructing)
		icon_state = "antimagicdeploy"
		return
	if(obj_broken)
		icon_state = "clockcrystal_broken"
	else
		icon_state = initial(icon_state)

/// Floor and water tiles are valid landing surfaces; openspace and hazardous open turfs are not.
/proc/is_valid_anti_magic_field_landing_turf(turf/candidate)
	return isfloorturf(candidate) || istype(candidate, /turf/open/water)

/// Find the nearest adjacent valid turf that is not occupied by a living mob or a dense anchored object.
/proc/find_anti_magic_field_landing_turf(turf/origin, atom/impact_atom)
	if(!origin)
		return null
	var/list/directions = list(NORTH, EAST, SOUTH, WEST, NORTHEAST, NORTHWEST, SOUTHEAST, SOUTHWEST)
	for(var/direction in directions)
		var/turf/candidate = get_step(origin, direction)
		if(!is_valid_anti_magic_field_landing_turf(candidate))
			continue
		if(locate(/mob/living) in candidate)
			continue
		var/occupied = FALSE
		for(var/atom/movable/movable_atom in candidate)
			if(movable_atom == impact_atom)
				continue
			if(movable_atom.anchored && movable_atom.density)
				occupied = TRUE
				break
		if(occupied)
			continue
		return candidate
	return null

#undef ANTI_MAGIC_FIELD_MAX_ACTIVE
#undef ANTI_MAGIC_FIELD_STATIONARY_WIDTH
#undef ANTI_MAGIC_FIELD_STATIONARY_HEIGHT
#undef ANTI_MAGIC_FIELD_THROWABLE_WIDTH
#undef ANTI_MAGIC_FIELD_THROWABLE_HEIGHT
#undef ANTI_MAGIC_FIELD_THROWABLE_BUILD_TIME
#undef ANTI_MAGIC_FIELD_THROWABLE_LIFETIME
#undef ANTI_MAGIC_FIELD_THROWABLE_WATER_LIFETIME
#undef ANTI_MAGIC_FIELD_RECOVERY_TIME

/// If set by a spell action, this is the whitelist ID used for the projectile's entire flight.
/obj/projectile/magic
	var/anti_magic_action_id

/obj/projectile/magic/Moved(atom/OldLoc, Dir)
	// Check before the parent scans the destination turf for impact targets.
	if(fired)
		var/turf/current_turf = get_turf(src)
		var/action_id = anti_magic_action_id
		if(!action_id)
			action_id = "[type]"
		if(GLOB.anti_magic_field_manager.is_action_blocked(firer, action_id, current_turf))
			if(ismob(firer))
				GLOB.anti_magic_field_manager.notify_blocked(firer)
			visible_message(span_warning("[src] fizzles and is destroyed as it enters an anti-magic field!"))
			qdel(src)
			return
	. = ..()
