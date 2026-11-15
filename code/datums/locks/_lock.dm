/// A lock that is not key controlled
/datum/lock
	/// Our holder /obj
	var/obj/holder = null
	/// Are we currently locked?
	var/locked = FALSE
	/// Have we been broken?
	var/lock_broken = FALSE
	/// Do we use a key?
	var/uses_key = FALSE
	/// Have we been lockpicked open, reset when the lock is toggled
	var/tampered = FALSE

/datum/lock/New(obj/holder)
	if(!holder)
		CRASH("[type] created without a parent object.")
	src.holder = holder
	src.holder.on_lock_add()

/datum/lock/Destroy()
	src.holder = null
	return ..()

/datum/lock/proc/toggle(mob/user, obj/item, silent = FALSE)
	if(!silent && user)
		silent = user?.m_intent == MOVE_INTENT_SNEAK
	if(locked)
		unlock(user, item, silent)
	else
		lock(user, item, silent)

/datum/lock/proc/lock(user, obj/item, silent = FALSE)
	tampered = FALSE
	locked = TRUE
	if(user)
		holder?.on_lock(user, item, silent)

/datum/lock/proc/unlock(user, obj/item, silent = FALSE)
	tampered = FALSE
	locked = FALSE
	if(user)
		holder?.on_unlock(user, item, silent)

/// A keylock
/datum/lock/key
	uses_key = TRUE
	/// Lockids to use for access
	var/list/lockid_list
	/// If the master key can open this lock regardless of access
	var/master_unlockable = TRUE

	///// Lockpicking
	/// Difficulty of the lock, smaller is harder
	var/difficulty = 5
	/// Picks able to be used
	var/list/lockpicks = list(/obj/item/lockpick)
	/// Wedges able to be used
	var/list/wedges = list(/obj/item/weapon/knife, /obj/item/lockpick) //when we add more thieves tools check this
	/// Can we be picked
	var/pickable = TRUE
	/// Requires left/right inputs for key turning
	var/requires_turning = TRUE

	/// A physically broken lockpick is lodged in the keyhole. This is physical state, not expiring evidence.
	var/keyhole_obstructed = FALSE
	/// In-game absolute station-time timestamp of the latest lockpicking attempt.
	var/last_fumbled_at
	/// In-game absolute station-time timestamp of the latest successful pick.
	var/last_picked_at
	/// In-game absolute station-time timestamp of the latest physically broken pick.
	var/last_broken_at
	/// Initial alignment for rounds that start after dawn before the payroll day counter's first dawn increment.
	var/evidence_day_offset
	/// User currently extracting a broken pick, if any.
	var/mob/living/extraction_user
	/// Set when the extracting user takes damage during the timed action.
	var/extraction_interrupted = FALSE

/datum/lock/key/New(obj/holder, list/lockids)
	. = ..()
	if(lockids && islist(lockids))
		lockid_list = lockids
	RegisterSignal(holder, COMSIG_PARENT_EXAMINE, PROC_REF(examine))
	RegisterSignal(holder, COMSIG_ATOM_EXAMINE_MORE, PROC_REF(examine_more))
	RegisterSignal(holder, COMSIG_ATOM_ITEM_INTERACTION, PROC_REF(key_act_left))
	if(requires_turning)
		RegisterSignal(holder, COMSIG_ATOM_ITEM_INTERACTION_SECONDARY, PROC_REF(key_act_right))

/datum/lock/key/Destroy()
	UnregisterSignal(holder, list(COMSIG_ATOM_ITEM_INTERACTION, COMSIG_PARENT_EXAMINE, COMSIG_ATOM_EXAMINE_MORE))
	if(extraction_user)
		extraction_interrupted = TRUE
		UnregisterSignal(extraction_user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_extraction_damage))
		extraction_user = null
	if(requires_turning)
		UnregisterSignal(holder, COMSIG_ATOM_ITEM_INTERACTION_SECONDARY)
	return ..()

/datum/lock/key/proc/examine(obj/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	cleanup_lock_evidence()
	examine_list += span_notice("I notice that it is [locked ? "locked" : "unlocked"].")
	if(keyhole_obstructed)
		examine_list += span_warning("A broken piece of metal is wedged inside the keyhole.")
	if(tampered && isnull(last_fumbled_at))
		// Preserve the old flag's examination text for any legacy code still setting it.
		examine_list += span_notice("[source] has been tampered with.")

/// Extended examination is triggered by the existing double-examination flow in mob.dm.
/datum/lock/key/proc/examine_more(obj/source, mob/user, list/examine_list)
	SIGNAL_HANDLER

	cleanup_lock_evidence()
	var/perception = GET_MOB_ATTRIBUTE_VALUE(user, STAT_PERCEPTION)
	if(isnull(perception))
		perception = 0
	if(perception < 7)
		return

	var/list/obvious_facts = list()
	var/list/detailed_facts = list()
	if(!isnull(last_fumbled_at))
		obvious_facts += span_notice("There are signs that someone has been working at this lock.")
		var/fumbled_details = get_evidence_age_description(last_fumbled_at, perception, "the signs of tampering")
		if(fumbled_details)
			if(perception >= 10)
				detailed_facts += span_notice(fumbled_details)

	if(!isnull(last_picked_at) && perception >= 13)
		var/picked_details = get_evidence_age_description(last_picked_at, perception, "the marks left by lockpicking")
		if(picked_details)
			detailed_facts += span_notice(picked_details)

	if(!isnull(last_broken_at) && perception >= 15)
		var/broken_details = get_evidence_age_description(last_broken_at, perception, "the marks left by a broken pick")
		if(broken_details)
			detailed_facts += span_notice(broken_details)

	if(length(obvious_facts))
		examine_list += span_notice("<b>Obiviously...</b>")
		examine_list += obvious_facts
	if(length(detailed_facts))
		examine_list += span_notice("<b>By carefully looking at the lock, i can see...</b>")
		examine_list += detailed_facts

/// Absolute in-game station time. Unlike station_time(), this does not wrap at midnight.
/datum/lock/key/proc/get_lock_evidence_time()
	// payroll_day_number advances at dawn, so rotate station_time() to that same boundary before composing a monotonic timestamp.
	var/current_station_time = station_time()
	var/day_start = SSnightshift.nightshift_dawn_start + 1
	if(isnull(evidence_day_offset))
		// A round can begin after dawn while payroll_day_number is still zero. Seed from the round's initial station clock.
		var/round_start_station_time = SSticker.gametime_offset % MIDNIGHT_ROLLOVER
		evidence_day_offset = (!GLOB.payroll_day_number && round_start_station_time >= day_start) ? 1 : 0
	var/evidence_day = GLOB.payroll_day_number + evidence_day_offset
	// payroll_day_number increments at dawn. After dawn, the current value belongs to the day that just began.
	// Before dawn, it still belongs to the previous day; this keeps the timestamp continuous across that boundary.
	if(current_station_time >= day_start)
		evidence_day--
	return (evidence_day * MIDNIGHT_ROLLOVER) + current_station_time - day_start

/// Historical lock evidence expires after one in-game day. Physical obstruction is deliberately untouched.
/datum/lock/key/proc/cleanup_lock_evidence()
	var/current_time = get_lock_evidence_time()
	if(!isnull(last_fumbled_at) && current_time - last_fumbled_at >= 24 HOURS)
		last_fumbled_at = null
	if(!isnull(last_picked_at) && current_time - last_picked_at >= 24 HOURS)
		last_picked_at = null
	if(!isnull(last_broken_at) && current_time - last_broken_at >= 24 HOURS)
		last_broken_at = null

/// Return the detail appropriate for the examiner's Perception.
/datum/lock/key/proc/get_evidence_age_description(timestamp, perception, evidence_name)
	var/evidence_age = max(0, get_lock_evidence_time() - timestamp)
	var/freshness = evidence_age < 10 MINUTES ? "fresh" : "old"
	if(perception < 10)
		return null
	if(perception < 20)
		return "[capitalize(evidence_name)] appear [freshness]."
	var/age_text = evidence_age < 10 MINUTES ? "less than ten minutes ago" : DisplayTimeText(evidence_age, perception >= 30 ? 60 : 600)
	return "[capitalize(evidence_name)] appear [freshness]; they suggest this happened approximately [age_text]."

/// Called when a lockpicking attempt actually begins, after all tool/lock validation succeeds.
/datum/lock/key/proc/record_lockpicking_attempt()
	cleanup_lock_evidence()
	last_fumbled_at = get_lock_evidence_time()

/// Called only when the lockpick item is physically destroyed, not merely damaged.
/datum/lock/key/proc/handle_lockpick_broken(mob/living/user)
	if(!user || QDELETED(src))
		return
	cleanup_lock_evidence()
	last_broken_at = get_lock_evidence_time()
	var/lockpicking_skill = GET_MOB_SKILL_VALUE(user, /datum/attribute/skill/misc/lockpicking)
	if(isnull(lockpicking_skill))
		lockpicking_skill = 0
	// Lower difficulty numbers are harder. Skilled lockpickers are substantially less likely to jam the keyhole.
	var/obstruction_chance = clamp(50 + (5 * (6 - difficulty)) - (0.75 * lockpicking_skill), 0, 75)
	if(prob(obstruction_chance))
		keyhole_obstructed = TRUE
		to_chat(user, span_warning("A broken fragment lodges in [holder]'s keyhole! It prevents the key from fitting in!"))
	else
		to_chat(user, span_notice("The lockpick breaks, and metal fragments fall on the ground."))
	if(user.client?.prefs.read_preference(/datum/preference/toggle/showrolls))
		to_chat(user, span_notice("The chance of obstructing the keyhole was [round(obstruction_chance, 0.1)]%."))

/// Signal handler: any applied damage interrupts the careful extraction action.
/datum/lock/key/proc/on_extraction_damage(mob/living/source, damage, damagetype, def_zone)
	SIGNAL_HANDLER

	if(source == extraction_user)
		extraction_interrupted = TRUE

/// Extra do_after validation for an extraction attempt.
/datum/lock/key/proc/can_continue_extraction(mob/living/user, obj/item/weapon/knife/knife, obj/lock_holder)
	if(QDELETED(src) || extraction_interrupted || QDELETED(user) || QDELETED(knife) || QDELETED(lock_holder))
		return FALSE
	if(!keyhole_obstructed || lock_holder.lock != src)
		return FALSE
	return user.get_active_held_item() == knife && user.Adjacent(lock_holder) && lock_holder.pre_lock_interact(user)

/// Try to remove an obstructing pick with a knife held in the active hand.
/datum/lock/key/proc/extract_broken_pick(mob/living/user, obj/item/weapon/knife/knife)
	var/obj/lock_holder = holder
	if(!user || !knife || QDELETED(src) || QDELETED(lock_holder) || !keyhole_obstructed)
		return
	if(user.get_active_held_item() != knife || !user.Adjacent(lock_holder) || !lock_holder.pre_lock_interact(user))
		return
	if(extraction_user)
		to_chat(user, span_notice("Someone is already trying to clear this keyhole."))
		return

	extraction_user = user
	extraction_interrupted = FALSE
	RegisterSignal(user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_extraction_damage))
	to_chat(user, span_notice("I begin carefully prying the broken fragment out of [lock_holder]'s keyhole..."))
	var/action_completed = do_after(user, 10 SECONDS, lock_holder, IGNORE_SLOWDOWNS, TRUE, CALLBACK(src, PROC_REF(can_continue_extraction), user, knife, lock_holder))
	if(!QDELETED(user))
		UnregisterSignal(user, COMSIG_MOB_APPLY_DAMAGE, PROC_REF(on_extraction_damage))
	if(QDELETED(src))
		return
	var/took_damage = extraction_interrupted
	extraction_user = null
	extraction_interrupted = FALSE
	if(took_damage)
		action_completed = FALSE
	if(!action_completed)
		if(!QDELETED(user))
			if(took_damage)
				to_chat(user, span_warning("A blow interrupts my work on the keyhole."))
			else
				to_chat(user, span_warning("I stop trying to remove the broken fragment."))
		return

	if(QDELETED(lock_holder) || lock_holder.lock != src || !keyhole_obstructed || QDELETED(knife))
		return
	if(user.get_active_held_item() != knife || !user.Adjacent(lock_holder) || !lock_holder.pre_lock_interact(user))
		return

	// Use the explicitly trained skill value: an untrained character starts at 50%, reaching 85% at skill 40.
	var/knife_skill = nulltozero(user.attributes?.raw_attribute_list[/datum/attribute/skill/combat/knives])
	var/extraction_chance = clamp(50 + (knife_skill * 0.875), 50, 85)
	if(!prob(extraction_chance))
		to_chat(user, span_warning("The fragment refuses to come loose. The keyhole remains obstructed."))
		if(user.client?.prefs.read_preference(/datum/preference/toggle/showrolls))
			to_chat(user, span_notice("The chance of extracting the fragment was [round(extraction_chance, 0.1)]%."))
		return

	keyhole_obstructed = FALSE
	to_chat(user, span_notice("I carefully pull the broken fragment free. The keyhole is clear again."))
	knife.take_damage(max(1, round(knife.max_integrity * 0.1)))
	if(user.client?.prefs.read_preference(/datum/preference/toggle/showrolls))
		to_chat(user, span_notice("The chance of extracting the fragment was [round(extraction_chance, 0.1)]%."))

/datum/lock/key/proc/key_act_left(obj/source, mob/living/user, obj/item/tool, list/modifiers)
	SIGNAL_HANDLER

	if(user.cmode)
		return NONE

	return interact_wrap(source, user, tool, modifiers)

/datum/lock/key/proc/key_act_right(obj/source, mob/living/user, obj/item/tool, list/modifiers)
	SIGNAL_HANDLER

	if(user.cmode)
		return NONE

	return interact_wrap(source, user, tool, modifiers)

/datum/lock/key/proc/interact_wrap(obj/source, mob/living/user, obj/item/tool, list/modifiers)
	var/is_right = text2num(LAZYACCESS(modifiers, RIGHT_CLICK))
	if(keyhole_obstructed)
		if(!source.pre_lock_interact(user))
			return NONE
		if(istype(tool, /obj/item/weapon/knife) && user.get_active_held_item() == tool)
			INVOKE_ASYNC(src, PROC_REF(extract_broken_pick), user, tool)
			return ITEM_INTERACT_SUCCESS
		if(istype(tool, /obj/item/key) || tool.can_lock_interact() || is_type_in_list(tool, lockpicks))
			to_chat(user, span_warning("The keyhole is obstructed by a broken lockpick. No key can operate it, and another lockpick cannot be inserted."))
			return ITEM_INTERACT_SUCCESS
		return NONE

	if(tool.can_lock_interact() && source.pre_lock_interact(user))
		try_toggle(user, tool, is_right)
		return ITEM_INTERACT_SUCCESS

	if(is_type_in_list(tool, lockpicks))
		if(source.pre_lock_interact(user) && user.try_pick(source, tool, lockpicks, wedges, difficulty))
			return ITEM_INTERACT_SUCCESS

/// Try to toggle the lock with a tool
/datum/lock/key/proc/try_toggle(mob/living/user, obj/item/tool, is_right)
	var/silent = user?.m_intent == MOVE_INTENT_SNEAK

	if(keyhole_obstructed)
		holder?.lock_failed(user, silent, "The keyhole is obstructed by a broken lockpick.")
		return

	if(!check_access(tool))
		holder?.lock_failed(user, silent)
		return

	if(requires_turning)
		if(locked && is_right)
			holder?.lock_failed(user, silent, "It won't turn this way, try turning it to the left.")
			return
		if(!locked && !is_right)
			holder?.lock_failed(user, silent, "It won't turn this way, try turning it to the right.")
			return

	toggle(user, tool, silent)

/datum/lock/key/proc/set_pick_difficulty(difficulty)
	src.difficulty = CLAMP(difficulty, 1, 6)

/datum/lock/key/proc/get_string_difficulty()
	switch(difficulty)
		if(1)
			return "LEGENDARY"
		if(2)
			return "MASTER"
		if(3)
			return "EXPERT"
		if(4)
			return "SKILLED"
		if(5)
			return "NOVICE"
		if(6)
			return "BASIC"

/// Check if an item has access to this lock
/datum/lock/key/proc/check_access(obj/item/I)
	return check_access_list(I ? I.get_access() : null)

/// Check a list of accesses for one of the required accesses
/datum/lock/key/proc/check_access_list(list/access_list)
	if(!LAZYLEN(lockid_list) || !islist(lockid_list))
		return FALSE
	if(!LAZYLEN(access_list) || !islist(access_list))
		return FALSE
	if(master_unlockable && (ACCESS_LORD in access_list))
		return TRUE
	for(var/id in lockid_list)
		if(id in access_list)
			return TRUE
	return FALSE

/datum/lock/key/proc/set_access(list/access)
	if(!LAZYLEN(access) || !islist(access))
		return
	lockid_list = access
