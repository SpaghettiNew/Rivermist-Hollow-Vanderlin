// ---- Global registries for slave collar phrase system ----

GLOBAL_LIST_INIT(generated_slave_phrases, list())
GLOBAL_LIST_INIT(slave_collars, list())

/// Maps internal phrase keys to human-readable display names.
GLOBAL_LIST_INIT(slave_phrases_translations, list(
	"touch_phrase" = "Touch Themself",
	"orgasm_phrase" = "Orgasm",
	"drop_phrase" = "Fall",
	"sleep_phrase" = "Sleep",
	"stop_phrase" = "Stay",
	"pleasure_phrase" = "Lust",
	"submission_phrase" = "Submit",
	"lock_phrase" = "Toggle Lock",
	"come_phrase" = "Come",
	"silence_phrase" = "Silence",
))

/// Reverse lookup: display name -> internal key.
GLOBAL_LIST_INIT(reverse_slave_phrases_translations, list(
	"Touch Themself" = "touch_phrase",
	"Orgasm" = "orgasm_phrase",
	"Fall" = "drop_phrase",
	"Sleep" = "sleep_phrase",
	"Stay" = "stop_phrase",
	"Lust" = "pleasure_phrase",
	"Submit" = "submission_phrase",
	"Toggle Lock" = "lock_phrase",
	"Come" = "come_phrase",
	"Silence" = "silence_phrase",
))

/// Generates a unique two-word arcane phrase for collar commands.
/proc/generate_slave_code()
	var/static/list/syllables1 = list("ka", "zu", "lo", "da", "ra", "ve", "so", "ti", "ma", "xi", "no", "qu", "ga", "shi", "ni", "fa", "jo", "li", "pa", "re", "sa", "do", "ke", "mi")
	var/static/list/syllables2 = list("th", "gor", "lek", "ram", "dra", "von", "nar", "zeth", "mir", "kul", "tar", "mol", "shan", "ruk", "vek", "zun", "bel", "thrall", "grim")

	var/code
	var/tries = 0
	do
		var/code1 = "[pick(syllables1)][pick(syllables2)]"
		var/code2 = "[pick(syllables1)][pick(syllables2)]"
		while(code1 == code2)
			code2 = "[pick(syllables1)][pick(syllables2)]"
		code = "[capitalize(code1)] [capitalize(code2)]"
		tries++
	while((code in GLOB.generated_slave_phrases) && tries < 100)

	GLOB.generated_slave_phrases += code
	return code

/// Normalizes text for phrase comparison: lowercase, strip HTML, strip punctuation, trim.
/proc/normalize_slave_phrase(text)
	text = LOWER_TEXT(strip_html(text))
	text = strip_punctuation(text)
	text = trim(text)
	return text

/proc/get_slave_collar_choices()
	var/list/choices = list()
	var/list/stale_keys = list()
	for(var/collar_key in GLOB.slave_collars)
		var/datum/weakref/collar_ref = GLOB.slave_collars[collar_key]
		var/obj/item/clothing/neck/slave_collar/collar = collar_ref?.resolve()
		if(!istype(collar) || !collar.get_worn_bearer())
			stale_keys += collar_key
			continue
		var/display_name = collar.get_control_display_name()
		if(display_name in choices)
			display_name = "[display_name] ([collar_key])"
		choices[display_name] = collar_ref
	for(var/stale_key in stale_keys)
		GLOB.slave_collars.Remove(stale_key)
	return choices

// ---- Slave Collar ----

/obj/item/clothing/neck/slave_collar
	name = "slave collar"
	desc = "A sturdy leather collar with ominous arcane engravings."
	icon_state = "collar"
	item_state = "collar"
	smeltresult = /obj/item/ingot/iron
	melting_material = /datum/material/iron
	melt_amount = 100
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	max_integrity = 150
	resistance_flags = FIRE_PROOF
	slot_flags = ITEM_SLOT_NECK
	body_parts_covered = NECK
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_TWIST)
	blocksound = PLATEHIT
	flags_1 = HEAR_1
	leashable = TRUE

	/// Maps internal phrase keys to their generated arcane words.
	var/list/phrases_list = list(
		"touch_phrase" = null,
		"orgasm_phrase" = null,
		"drop_phrase" = null,
		"sleep_phrase" = null,
		"stop_phrase" = null,
		"pleasure_phrase" = null,
		"submission_phrase" = null,
		"lock_phrase" = null,
		"come_phrase" = null,
		"silence_phrase" = null,
	)
	/// Whether this collar has been bound to a control ring.
	var/collar_bound = FALSE
	/// The control ring currently bound to this collar.
	var/obj/item/clothing/ring/slave_control/bound_ring
	/// Whether the arcane lock is engaged (prevents removal).
	var/stuck = FALSE
	/// Whether the bearer is currently magically silenced by the collar.
	var/silenced = FALSE
	/// The mob currently wearing this collar.
	var/mob/living/carbon/human/bearer
	/// Stable key used in GLOB.slave_collars.
	var/list_name
	/// The rate at which the collar slowly drains the wearer's mana while equipped.
	var/mana_drain_per_second = 0
	COOLDOWN_DECLARE(collar_phrase_usage)

/obj/item/clothing/neck/slave_collar/male
	name = "Cruel slave gorget"
	icon = 'modular_rmh/icons/clothing/neck.dmi'
	desc = "A brutal-looking iron gorget inscribed with cruel arcane patterns. There's no mistaking its purpose."
	icon_state = "m_collar"
	item_state = "gorget"
	armor_type = /datum/armor/rmh/neck/slave_collar

/obj/item/clothing/neck/slave_collar/female
	name = "Elegant slave collar"
	icon = 'modular_rmh/icons/clothing/neck.dmi'
	desc = "An elegant black choker with faint arcane patterns along its trim. Beautiful, yet deeply symbolic."
	icon_state = "f_collar"
	item_state = "collar_f"

/obj/item/clothing/neck/slave_collar/draining
	name = "Mana draining slave collar"
	icon = 'modular_rmh/icons/clothing/neck.dmi'
	desc = "A sturdy leather collar with ominous arcane engravings."
	icon_state = "draincollar"
	item_state = "draincollar_m"
	smeltresult = /obj/item/ingot/iron
	melting_material = /datum/material/iron
	melt_amount = 100
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	max_integrity = 150
	resistance_flags = FIRE_PROOF
	slot_flags = ITEM_SLOT_NECK
	body_parts_covered = NECK
	prevent_crits = list(BCLASS_CUT, BCLASS_STAB, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_TWIST)
	blocksound = PLATEHIT
	flags_1 = HEAR_1
	leashable = TRUE
	mana_drain_per_second = 3

/obj/item/clothing/neck/slave_collar/draining/female
	name = "Elegant mana draining slave collar"
	icon = 'modular_rmh/icons/clothing/neck.dmi'
	desc = "An elegant black choker with faint arcane patterns along its trim. Beautiful, yet deeply symbolic."
	icon_state = "draincollar_elegant"
	item_state = "draincollar_f"
	mana_drain_per_second = 3

/obj/item/clothing/neck/slave_collar/New()
	. = ..()
	for(var/el in phrases_list)
		phrases_list[el] = generate_slave_code()

/obj/item/clothing/neck/slave_collar/Initialize(mapload)
	. = ..()
	RegisterSignal(src, COMSIG_ITEM_PRE_UNEQUIP, PROC_REF(on_pre_unequip))

// ---- Equip / Drop / Destroy ----

/obj/item/clothing/neck/slave_collar/equipped(mob/living/carbon/human/human)
	. = ..()
	if(!ishuman(human))
		return
	var/mob/living/carbon/human/wearer = loc
	if(!ismob(wearer) || wearer.wear_neck != src)
		return
	if(bearer && bearer != wearer)
		cleanup_bearer()
	RegisterSignal(human, COMSIG_MOVABLE_HEAR, PROC_REF(process_phrase), override = TRUE)
	list_name = REF(src)
	GLOB.slave_collars[list_name] = WEAKREF(src)
	bearer = wearer
	apply_collar_traits(wearer)
	START_PROCESSING(SSobj, src)

/obj/item/clothing/neck/slave_collar/dropped(mob/user)
	. = ..()
	cleanup_bearer()

/obj/item/clothing/neck/slave_collar/Destroy()
	cleanup_bearer()
	clear_bound_ring()
	UnregisterSignal(src, COMSIG_ITEM_PRE_UNEQUIP)
	stuck = FALSE
	return ..()

/// Shared cleanup: unregister signals, remove from global list, clear traits.
/obj/item/clothing/neck/slave_collar/proc/cleanup_bearer()
	if(!bearer)
		return
	GLOB.slave_collars.Remove(list_name)
	UnregisterSignal(bearer, COMSIG_MOVABLE_HEAR)
	if(silenced)
		REMOVE_TRAIT(bearer, TRAIT_MUTE, "slave_collar")
		silenced = FALSE
	remove_collar_traits(bearer)
	STOP_PROCESSING(SSobj, src)
	bearer = null

/obj/item/clothing/neck/slave_collar/process(delta_time)
	if(!bearer || QDELETED(bearer) || bearer != get_worn_bearer())
		STOP_PROCESSING(SSobj, src)
		return
	if(!bearer.mana_pool)
		STOP_PROCESSING(SSobj, src)
		return
	if(bearer.mana_pool.amount <= 0)
		return
	var/drain_amount = mana_drain_per_second * delta_time
	if(drain_amount <= 0)
		STOP_PROCESSING(SSobj, src)
		return
	bearer.mana_pool.adjust_mana(-drain_amount)
	// Keep processing active while empty so mana regeneration does not disable draining permanently.
	if(bearer.mana_pool.amount <= 0)
		return

/obj/item/clothing/neck/slave_collar/proc/apply_collar_traits(mob/living/carbon/human/wearer)
	ADD_TRAIT(wearer, TRAIT_ANTIMAGIC, "slave_collar")
	ADD_TRAIT(wearer, TRAIT_NO_SELF_MAGIC, "slave_collar")
	wearer.update_action_buttons()

/obj/item/clothing/neck/slave_collar/proc/remove_collar_traits(mob/living/carbon/human/wearer)
	REMOVE_TRAIT(wearer, TRAIT_ANTIMAGIC, "slave_collar")
	REMOVE_TRAIT(wearer, TRAIT_NO_SELF_MAGIC, "slave_collar")
	wearer.update_action_buttons()

/obj/item/clothing/neck/slave_collar/proc/get_worn_bearer()
	var/mob/living/carbon/human/wearer = loc
	if(istype(wearer) && wearer.wear_neck == src)
		return wearer
	return null

/obj/item/clothing/neck/slave_collar/proc/get_control_display_name()
	var/mob/living/carbon/human/wearer = get_worn_bearer()
	var/display_name = wearer ? wearer.name : name
	if(wearer?.job)
		display_name += " the [wearer.job]"
	var/list/state_text = list(stuck ? "locked" : "unlocked")
	if(silenced)
		state_text += "silenced"
	var/state_description = jointext(state_text, ", ")
	return "[display_name] ([state_description])"

/obj/item/clothing/neck/slave_collar/proc/get_command_key_from_phrase(msg)
	for(var/command_key in phrases_list)
		if(normalize_slave_phrase(phrases_list[command_key]) == msg)
			return command_key
	return null

/obj/item/clothing/neck/slave_collar/proc/get_radial_command_options()
	var/list/options = list()
	for(var/command_key in GLOB.slave_phrases_translations)
		if(command_key == "lock_phrase")
			options[stuck ? "Unlock" : "Lock"] = stuck ? "unlock_command" : "lock_command"
			continue
		if(command_key == "silence_phrase")
			options[silenced ? "Unsilence" : "Silence"] = silenced ? "unsilence_command" : "silence_command"
			continue
		options[GLOB.slave_phrases_translations[command_key]] = command_key
	return options

/obj/item/clothing/neck/slave_collar/proc/is_valid_command_key(command_key)
	if(command_key in phrases_list)
		return TRUE
	switch(command_key)
		if("lock_command", "unlock_command", "silence_command", "unsilence_command")
			return TRUE
	return FALSE

/obj/item/clothing/neck/slave_collar/proc/controller_has_bound_ring(mob/living/controller)
	if(!bound_ring || !ishuman(controller))
		return FALSE
	var/mob/living/carbon/human/human_controller = controller
	return (human_controller.get_item_by_slot(ITEM_SLOT_RING) == bound_ring) || human_controller.is_holding(bound_ring)

/obj/item/clothing/neck/slave_collar/proc/fail_command(mob/living/controller, message)
	if(controller && message)
		to_chat(controller, span_warning(message))
	return FALSE

/obj/item/clothing/neck/slave_collar/proc/can_invoke_command(command_key, mob/living/controller, atom/source_item, command_source)
	if(!is_valid_command_key(command_key))
		return fail_command(controller, "The collar does not recognize that command.")
	if(!get_worn_bearer())
		return fail_command(controller, "The collar is not being worn.")
	if(command_source != "leash")
		if(!bound_ring)
			return fail_command(controller, "The collar is not bound to a ring.")
		if(source_item && source_item != bound_ring)
			return fail_command(controller, "That ring is not bound to this collar.")
		if(!controller_has_bound_ring(controller))
			return fail_command(controller, "You must hold or wear the bound ring to command this collar.")
	if(!COOLDOWN_FINISHED(src, collar_phrase_usage))
		return fail_command(controller, "The collar is still resonating for [DisplayTimeText(COOLDOWN_TIMELEFT(src, collar_phrase_usage))].")
	return TRUE

// ---- Ring Binding ----

/obj/item/clothing/neck/slave_collar/attackby(obj/item/I, mob/living/user)
	if(!ismob(user))
		return ..()
	if(istype(I, /obj/item/clothing/ring/slave_control))
		bind_collar(I, user, istype(I, /obj/item/clothing/ring/slave_control/master))
		return
	return ..()

/// Bind a control ring to this collar, transferring phrase codes.
/obj/item/clothing/neck/slave_collar/proc/bind_collar(obj/item/clothing/ring/slave_control/ring, mob/living/user, master_ring = FALSE)
	if(!istype(ring))
		return FALSE
	if(collar_bound && bound_ring && !QDELETED(bound_ring) && !master_ring)
		to_chat(user, span_warning("The collar is already bound."))
		return FALSE

	to_chat(user, span_info("You bind the ring to the collar, transferring the control words."))
	if(!master_ring)
		user.visible_message(span_info("<b>[user] touches the ring and collar together, producing a dull chime.</b>"))
	else if(bearer)
		to_chat(bearer, span_info("<b>Some unknown force seems to *yank* you by your collar.</b>"))

	// Unbind old ring if one exists — clear its data safely.
	if(bound_ring && bound_ring != ring)
		bound_ring.clear_bound_collar(FALSE)
	if(ring.bound_collar && ring.bound_collar != src)
		ring.clear_bound_collar(FALSE)
	collar_bound = TRUE
	bound_ring = ring

	ring.phrases_list = phrases_list.Copy()
	ring.ring_bound = TRUE
	ring.bound_collar = src
	return TRUE

/obj/item/clothing/neck/slave_collar/proc/clear_bound_ring()
	var/obj/item/clothing/ring/slave_control/old_ring = bound_ring
	bound_ring = null
	collar_bound = FALSE
	if(old_ring)
		old_ring.bound_collar = null
		old_ring.ring_bound = FALSE
		old_ring.phrases_list = list()

// ---- Voice Phrase Processing ----

/// Called via COMSIG_MOVABLE_HEAR when the bearer hears speech. Checks if a command phrase was spoken.
/obj/item/clothing/neck/slave_collar/proc/process_phrase(datum/source, list/hear_args)
	SIGNAL_HANDLER

	var/raw_message = hear_args[HEARING_RAW_MESSAGE]
	var/atom/movable/speaker = hear_args[HEARING_SPEAKER]

	if(!ismob(speaker))
		return

	var/mob/living/carbon/human/H = src.loc
	if(!ismob(H))
		return

	var/msg = normalize_slave_phrase(raw_message)

	var/command_key = get_command_key_from_phrase(msg)
	if(!command_key)
		return

	// Validate that the speaker has the bound ring equipped.
	var/ring_found = FALSE
	if(ishuman(speaker))
		ring_found = controller_has_bound_ring(speaker)

	// Self-punishment: bearer says a command phrase without wearing the ring — mute them.
	if(H == speaker && !ring_found)
		H.visible_message(span_warning("<b>The collar around [H]'s neck flashes brightly, muting the wearer in punishment.</b>"))
		ADD_TRAIT(H, TRAIT_MUTE, "rune")
		addtimer(CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(remove_mute), H), 30 SECONDS)
		return

	if(!ring_found)
		return

	INVOKE_ASYNC(src, PROC_REF(perform_command), command_key, speaker, bound_ring, "voice")

/// Returns TRUE if the speaker is wearing or holding the bound ring.
/obj/item/clothing/neck/slave_collar/proc/speaker_has_ring(mob/living/carbon/human/speaker)
	return controller_has_bound_ring(speaker)

// ---- Command Execution ----

/// Execute a collar command. Returns TRUE on success.
/obj/item/clothing/neck/slave_collar/proc/perform_command(command_key, mob/living/controller = null, atom/source_item = null, command_source = "direct")
	if(!can_invoke_command(command_key, controller, source_item, command_source))
		return FALSE

	var/mob/living/carbon/human/H = get_worn_bearer()

	if(command_key == "lock_command" && stuck)
		return fail_command(controller, "The collar is already locked.")
	if(command_key == "unlock_command" && !stuck)
		return fail_command(controller, "The collar is already unlocked.")
	if(command_key == "silence_command" && silenced)
		return fail_command(controller, "The collar is already silenced.")
	if(command_key == "unsilence_command" && !silenced)
		return fail_command(controller, "The collar is not silencing its bearer.")
	if(command_key == "come_phrase" && (!controller || QDELETED(controller) || controller == H))
		return fail_command(controller, "The collar needs a separate controller to call its bearer.")

	COOLDOWN_START(src, collar_phrase_usage, 10 SECONDS)

	// Notify the bearer that the collar is activating.
	to_chat(H, span_userdanger("Your collar compels you!"))

	// Touch — forced masturbation.
	if(command_key == "touch_phrase")
		H.visible_message(span_danger("<b>[H] starts masturbating uncontrollably!</b>"))
		H.emote("moan")
		var/datum/sex_scene_controller/scene_controller = H.open_sex_scene(H, FALSE)
		if(!scene_controller)
			return FALSE
		var/action_type = /datum/sex_action/masturbate/anus
		if(H.getorganslot(ORGAN_SLOT_VAGINA))
			action_type = /datum/sex_action/masturbate/vagina
		else if(H.getorganslot(ORGAN_SLOT_PENIS))
			action_type = /datum/sex_action/masturbate/penis
		scene_controller.try_start_action(action_type)
		scene_controller.set_current_force(SEX_FORCE_HIGH)
		scene_controller.set_current_speed(SEX_SPEED_EXTREME)
		return TRUE

	// Orgasm — forced climax.
	if(command_key == "orgasm_phrase")
		H.visible_message(span_danger("<b>[H] convulses in a sudden orgasm!</b>"))
		var/datum/component/arousal/aro = H.GetComponent(/datum/component/arousal)
		if(aro)
			aro.ejaculate(null, H, null, FALSE)
			SEND_SIGNAL(H, COMSIG_SEX_ADJUST_AROUSAL, 60)
			SEND_SIGNAL(H, COMSIG_SEX_ADJUST_EDGING, 15)
			SEND_SIGNAL(H, COMSIG_SEX_ADJUST_ORGASM_PROG, 10)
			COOLDOWN_START(src, collar_phrase_usage, 30 SECONDS)
		return TRUE

	// Fall — knockdown.
	if(command_key == "drop_phrase")
		H.visible_message(span_danger("<b>[H] falls prone!</b>"))
		H.Knockdown(10 SECONDS)
		return TRUE

	// Sleep — forced unconsciousness.
	if(command_key == "sleep_phrase")
		H.visible_message(span_danger("<b>[H] has their eyes shut — falling asleep instantly!</b>"))
		H.Sleeping(15 SECONDS)
		return TRUE

	// Stay — immobilize.
	if(command_key == "stop_phrase")
		H.visible_message(span_danger("<b>[H] freezes in place, unable to move!</b>"))
		H.apply_status_effect(/datum/status_effect/collar_stun)
		return TRUE

	// Lust — forced arousal.
	if(command_key == "pleasure_phrase")
		H.visible_message(span_danger("<b>[H] shivers, pleasure forced upon them!</b>"))
		H.emote("moan")
		SEND_SIGNAL(H, COMSIG_SEX_ADJUST_AROUSAL, 120)
		SEND_SIGNAL(H, COMSIG_SEX_ADJUST_EDGING, 30)
		SEND_SIGNAL(H, COMSIG_SEX_ADJUST_ORGASM_PROG, 50)
		return TRUE

	// Submit — shock and choke with spark VFX. Oxyloss capped at 45 to prevent death.
	if(command_key == "submission_phrase")
		H.visible_message(span_warning("<b>[H] is shocked, the collar tightening!</b>"))
		do_sparks(2, FALSE, get_turf(H))
		playsound(H, 'sound/effects/sparks1.ogg', 50, TRUE)
		H.electrocute_act(5, src)
		H.emote("choke")
		var/oxy_to_apply = min(15, max(0, 45 - H.getOxyLoss()))
		if(oxy_to_apply > 0)
			H.adjustOxyLoss(oxy_to_apply)
		COOLDOWN_START(src, collar_phrase_usage, 15 SECONDS)
		return TRUE

	// Toggle Lock — engage/disengage arcane lock.
	if(command_key == "lock_phrase")
		set_lock_state(H, !stuck)
		return TRUE

	if(command_key == "lock_command")
		set_lock_state(H, TRUE)
		return TRUE

	if(command_key == "unlock_command")
		set_lock_state(H, FALSE)
		return TRUE

	// Come — force the bearer to walk toward the ring-holder.
	if(command_key == "come_phrase")
		H.visible_message(span_danger("<b>[H]'s legs move on their own, compelled toward [controller]!</b>"))
		come_to_master(H, controller)
		return TRUE

	// Silence — toggle mute on the bearer.
	if(command_key == "silence_phrase")
		set_silence_state(H, !silenced)
		return TRUE

	if(command_key == "silence_command")
		set_silence_state(H, TRUE)
		return TRUE

	if(command_key == "unsilence_command")
		set_silence_state(H, FALSE)
		return TRUE

	return FALSE

/obj/item/clothing/neck/slave_collar/proc/set_lock_state(mob/living/carbon/human/H, locked)
	stuck = locked
	if(stuck)
		H.visible_message(span_notice("<b>The collar around [H]'s neck engages its arcane lock.</b>"))
	else
		H.visible_message(span_notice("<b>The collar around [H]'s neck releases its arcane lock.</b>"))

/obj/item/clothing/neck/slave_collar/proc/set_silence_state(mob/living/carbon/human/H, mute_state)
	silenced = mute_state
	if(silenced)
		H.visible_message(span_warning("<b>The collar around [H]'s neck glows faintly — [H] has been silenced.</b>"))
		ADD_TRAIT(H, TRAIT_MUTE, "slave_collar")
	else
		H.visible_message(span_notice("<b>The collar around [H]'s neck dims — [H] may speak again.</b>"))
		REMOVE_TRAIT(H, TRAIT_MUTE, "slave_collar")

// ---- Come Command Helper ----

/// Async proc: steps the bearer toward the master over a short period.
/obj/item/clothing/neck/slave_collar/proc/come_to_master(mob/living/carbon/human/target, mob/living/master)
	set waitfor = FALSE
	for(var/i in 1 to 6)
		if(QDELETED(target) || QDELETED(master))
			return
		if(get_dist(target, master) <= 1)
			return
		step_towards(target, master)
		sleep(3)

// ---- Stuck / Lock Checks ----

/obj/item/clothing/neck/slave_collar/proc/on_pre_unequip(datum/source, force, atom/newloc, no_move, invdrop, silent)
	SIGNAL_HANDLER

	if(force || !stuck)
		return

	if(!iscarbon(loc))
		return

	var/mob/living/carbon/wearer = loc
	if(src != wearer.get_item_by_slot(ITEM_SLOT_NECK))
		return

	if(!silent)
		to_chat(wearer, span_userdanger("The collar's arcane lock refuses to release!"))
	return COMPONENT_ITEM_BLOCK_UNEQUIP

/// Returns TRUE if the collar is locked and worn by the user (blocks removal).
/obj/item/clothing/neck/slave_collar/proc/stuck_check(mob/living/user)
	if(iscarbon(user))
		var/mob/living/carbon/C = user
		if(src == C.get_item_by_slot(ITEM_SLOT_NECK) && stuck)
			to_chat(user, span_userdanger("I can't take it off!"))
			return TRUE
	return FALSE

/obj/item/clothing/neck/slave_collar/canStrip(mob/stripper, mob/owner)
	if(stuck && get_worn_bearer())
		return FALSE
	return ..()

/obj/item/clothing/neck/slave_collar/doStrip(mob/stripper, mob/owner)
	if(stuck && get_worn_bearer())
		if(stripper)
			to_chat(stripper, span_userdanger("The collar's arcane lock refuses to release."))
		if(owner && owner != stripper)
			to_chat(owner, span_userdanger("The collar tightens as [stripper] tries to remove it."))
		return FALSE
	return ..()

/obj/item/clothing/neck/slave_collar/attack_hand(mob/user)
	if(!stuck_check(user))
		return ..()

/obj/item/clothing/neck/slave_collar/MouseDrop(atom/over_object)
	if(!stuck_check(usr))
		return ..()

// ---- Examine ----

/obj/item/clothing/neck/slave_collar/get_examine_string(mob/user, thats = FALSE, use_examine_name = FALSE)
	. = ..()
	if(!ishuman(user))
		return
	var/mob/living/carbon/human/h_user = user
	var/lock_state = stuck ? "engaged" : "released"
	// The ring holder and certain authority figures can read the phrases.
	var/can_read = FALSE
	if(bound_ring && controller_has_bound_ring(h_user))
		can_read = TRUE
	if(!can_read)
		var/job_lower = LOWER_TEXT(h_user.job)
		if(job_lower == "town master" || job_lower == "consort")
			can_read = TRUE
	if(can_read)
		. += span_notice("The arcane lock is [lock_state]. ")
		if(!COOLDOWN_FINISHED(src, collar_phrase_usage))
			. += span_warning("The collar is still resonating for [DisplayTimeText(COOLDOWN_TIMELEFT(src, collar_phrase_usage))].")
		. += span_userdanger("You notice engraved phrases on the collar:")
		for(var/el in phrases_list)
			. += "<br><b>[GLOB.slave_phrases_translations[el]]:</b> \"[phrases_list[el]]\""

// ---- Collar Stun Status Effect ----

/datum/status_effect/collar_stun
	id = "stun_collar"
	alert_type = /atom/movable/screen/alert/status_effect/collar_stun
	status_type = STATUS_EFFECT_REPLACE
	tick_interval = 10
	duration = 20 SECONDS

/atom/movable/screen/alert/status_effect/collar_stun
	name = "Stunned"
	desc = ""
	icon_state = "stun"

/datum/status_effect/collar_stun/on_apply()
	. = ..()
	if(!.)
		return
	ADD_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	ADD_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))

/datum/status_effect/collar_stun/on_remove()
	REMOVE_TRAIT(owner, TRAIT_INCAPACITATED, TRAIT_STATUS_EFFECT(id))
	REMOVE_TRAIT(owner, TRAIT_IMMOBILIZED, TRAIT_STATUS_EFFECT(id))
	return ..()

// ---- Crafting Recipes ----

/datum/repeatable_crafting_recipe/arcyne/slavecollar
	name = "slave collar"
	reagent_requirements = list()
	tool_usage = list()
	requirements = list(
		/obj/item/natural/hide/cured = 1,
		/obj/item/gem/red = 1,
		/obj/item/gem/blue = 1,
		/obj/item/gem/diamond = 1,
	)
	output = /obj/item/clothing/neck/slave_collar
	starting_atom = /obj/item/gem/diamond
	attacked_atom = /obj/item/natural/hide/cured
	craftdiff = 4

/datum/repeatable_crafting_recipe/arcyne/slavecollar/cruel
	name = "cruel slave collar"
	output = /obj/item/clothing/neck/slave_collar/male

/datum/repeatable_crafting_recipe/arcyne/slavecollar/elegant
	name = "elegant slave collar"
	output = /obj/item/clothing/neck/slave_collar/female
