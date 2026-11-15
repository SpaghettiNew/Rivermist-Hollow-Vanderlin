/datum/component/arousal
	/// Our arousal level
	var/arousal = 0
	/// Arousal won't change if active
	var/arousal_frozen = FALSE
	/// Orgasm progress
	var/orgasm_progress = 0
	/// Last time arousal increased
	var/last_arousal_increase_time = 0
	/// Last time orgasm prog increased
	var/last_orgasm_prog_increase_time = 0
	/// Last moan time for cooldowns
	var/last_moan = 0
	/// Last pain effect time
	var/last_pain = 0
	///our multiplier
	var/arousal_multiplier = 1
	/// Our charge gauge
	var/charge = SEX_MAX_CHARGE
	/// Last ejaculation time
	var/last_ejaculation_time = 0
	/// Last climax count reset time
	var/last_climax_reset_time = 0
	/// Our edging charge
	var/edging_charge = 0
	/// 60% arousal loss after each orgasm
	var/arousal_falloff_coeff = 0.4
	/// Level of pleasure resistance
	var/resistance_to_pleasure = RESIST_NONE
	/// Recent orgasm count
	var/recent_orgasm_count = 0
	/// How much recent orgasms have strained the body. Built by quick/intense climaxes, not ordinary ones.
	var/orgasm_strain = 0
	/// Last time orgasm strain naturally decayed
	var/last_orgasm_strain_decay_time = 0
	/// Are we edged by partner
	var/is_edged = FALSE
	/// Last time high arousal auto-flicked the mob's ears
	var/last_ear_flick_time = 0

/datum/component/arousal/Initialize(...)
	. = ..()
	START_PROCESSING(SSobj, src)

/datum/component/arousal/Destroy(force)
	QDEL_NULL(active_spurts)
	. = ..()
	STOP_PROCESSING(SSobj, src)

/datum/component/arousal/RegisterWithParent()
	. = ..()
	// A clientless mob that gains arousal (i.e. is in the horny system) becomes horny-KO-able. Scoped to
	// clientless bodies so players - who also carry arousal - are untouched and keep the full defeat flow.
	// !client alone is not enough to tell those apart: every human is given arousal in Initialize, long
	// before its client attaches at Login, so a player body looks identical to an NPC at this point.
	// An ai_controller is what actually marks a body as AI-driven - carbon NPCs declare one as an
	// initial var, player bodies never do - and non-carbons are the mob path's original audience.
	var/mob/living/horny_ko_parent = parent
	if(istype(horny_ko_parent) && !horny_ko_parent.client && (horny_ko_parent.ai_controller || !iscarbon(horny_ko_parent)))
		horny_ko_parent.mob_horny_defeat_enabled = TRUE
		horny_ko_parent.ensure_defeat_monitor()
	RegisterSignal(parent, COMSIG_SEX_ADJUST_AROUSAL, PROC_REF(adjust_arousal))
	RegisterSignal(parent, COMSIG_SEX_SET_AROUSAL, PROC_REF(set_arousal))
	RegisterSignal(parent, COMSIG_SEX_FREEZE_AROUSAL, PROC_REF(freeze_arousal))
	RegisterSignal(parent, COMSIG_SEX_GET_AROUSAL, PROC_REF(get_arousal))
	RegisterSignal(parent, COMSIG_SEX_RECEIVE_ACTION, PROC_REF(receive_sex_action))
	RegisterSignal(parent, COMSIG_SEX_GENERIC_ACTION, PROC_REF(receive_generic_sex_action))
	RegisterSignal(parent, COMSIG_SEX_ADJUST_EDGING, PROC_REF(adjust_edging))
	RegisterSignal(parent, COMSIG_SEX_SET_EDGING, PROC_REF(set_edging))
	RegisterSignal(parent, COMSIG_SEX_SET_HOLDING, PROC_REF(set_holding_pleasure))
	RegisterSignal(parent, COMSIG_SEX_HOLE_BEFORE_INSERT, PROC_REF(hole_before_insert_handle))
	RegisterSignal(parent, COMSIG_SEX_HOLE_AFTER_INSERT, PROC_REF(hole_after_insert_handle))
	RegisterSignal(parent, COMSIG_SEX_HOLE_BEFORE_REMOVE, PROC_REF(hole_before_remove_handle))
	RegisterSignal(parent, COMSIG_SEX_HOLE_AFTER_REMOVE, PROC_REF(hole_after_remove_handle))
	RegisterSignal(parent, COMSIG_SEX_ADJUST_ORGASM_PROG, PROC_REF(adjust_orgasm_prog))
	RegisterSignal(parent, COMSIG_SEX_SET_ORGASM_PROG, PROC_REF(set_orgasm_prog))
	RegisterSignal(parent, COMSIG_SEX_EDGED_BY_OTHER_STATE, PROC_REF(set_edging_state))
	RegisterSignal(parent, COMSIG_SEX_ORGASM, PROC_REF(manual_orgasm))
	if(isliving(parent) && !ishuman(parent))
		var/mob/living/living_parent = parent
		living_parent.give_genitals()

/datum/component/arousal/UnregisterFromParent()
	. = ..()
	UnregisterSignal(parent, COMSIG_SEX_ADJUST_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_SET_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_FREEZE_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_GET_AROUSAL)
	UnregisterSignal(parent, COMSIG_SEX_RECEIVE_ACTION)
	UnregisterSignal(parent, COMSIG_SEX_GENERIC_ACTION)
	UnregisterSignal(parent, COMSIG_SEX_ADJUST_EDGING)
	UnregisterSignal(parent, COMSIG_SEX_SET_EDGING)
	UnregisterSignal(parent, COMSIG_SEX_SET_HOLDING)
	UnregisterSignal(parent, COMSIG_SEX_HOLE_BEFORE_INSERT)
	UnregisterSignal(parent, COMSIG_SEX_HOLE_AFTER_INSERT)
	UnregisterSignal(parent, COMSIG_SEX_HOLE_BEFORE_REMOVE)
	UnregisterSignal(parent, COMSIG_SEX_HOLE_AFTER_REMOVE)
	UnregisterSignal(parent, COMSIG_SEX_ADJUST_ORGASM_PROG)
	UnregisterSignal(parent, COMSIG_SEX_SET_ORGASM_PROG)
	UnregisterSignal(parent, COMSIG_SEX_ORGASM)

/datum/component/arousal/process()
	handle_charge()
	handle_aroousal_cooling()
	handle_orgasm_count()
	handle_orgasm_strain()
	handle_statuses()
	handle_passive_orgasm()
	handle_orgasm_cooling()
	handle_ear_flick()

/// High arousal makes flickable ears twitch on a fixed interval.
/datum/component/arousal/proc/handle_ear_flick()
	if(arousal <= 200)
		return
	if(last_ear_flick_time + 5 SECONDS > world.time)
		return
	if(!isliving(parent))
		return
	var/mob/living/user = parent
	last_ear_flick_time = world.time
	user.try_ear_flick()

/datum/component/arousal/proc/handle_orgasm_count()
	if(!recent_orgasm_count)
		return
	if(last_climax_reset_time == 0)
		last_climax_reset_time = world.time
	if(last_climax_reset_time + ORGASM_RESET_TIME < world.time)
		recent_orgasm_count -= 1
		last_climax_reset_time = world.time

/datum/component/arousal/proc/handle_orgasm_strain()
	if(orgasm_strain <= 0)
		last_orgasm_strain_decay_time = 0
		return
	if(!last_orgasm_strain_decay_time)
		last_orgasm_strain_decay_time = world.time
		return
	var/elapsed_intervals = FLOOR((world.time - last_orgasm_strain_decay_time) / ORGASM_STRAIN_DECAY_INTERVAL, 1)
	if(elapsed_intervals <= 0)
		return
	orgasm_strain = max(0, orgasm_strain - elapsed_intervals * ORGASM_STRAIN_DECAY_AMOUNT)
	last_orgasm_strain_decay_time += elapsed_intervals * ORGASM_STRAIN_DECAY_INTERVAL

/datum/component/arousal/proc/handle_orgasm_cooling()
	if(last_orgasm_prog_increase_time >= world.time - 8 SECONDS)
		return
	var/org_rate
	switch(edging_charge)
		if(-INFINITY to 25)
			org_rate = 1
		if(25 to 40)
			org_rate = 0.5
		if(40 to INFINITY)
			org_rate = 0.3

	adjust_orgasm_prog(parent, -1 * org_rate)

/datum/component/arousal/proc/handle_aroousal_cooling()
	//if(!can_lose_arousal())
	//	return
	if(arousal_frozen)
		return
	if(!can_climax())
		adjust_arousal(parent, -1 * ARO_LOSS_COEFFICIENT * IMPOTENT_AROUSAL_LOSS_RATE)
	if(last_arousal_increase_time + AROUSAL_TIME_TO_UNHORNY >= world.time)
		return
	var/rate
	switch(arousal)
		if(-INFINITY to 25)
			rate = AROUSAL_LOW_UNHORNY_RATE
		if(25 to 40)
			rate = AROUSAL_MID_UNHORNY_RATE
		if(40 to INFINITY)
			rate = AROUSAL_HIGH_UNHORNY_RATE
	var/floor = get_arousal_floor()
	if(arousal > floor)
		adjust_arousal(parent, -min(ARO_LOSS_COEFFICIENT * rate, arousal - floor))

	adjust_edging(parent, -1 * ARO_LOSS_COEFFICIENT * 0.01)

/// Highest arousal floor any effect sets, such as heat; plain cooling stops there.
/datum/component/arousal/proc/get_arousal_floor()
	var/list/floor_data = list("floor" = 0)
	SEND_SIGNAL(parent, COMSIG_SEX_GET_AROUSAL_FLOOR, floor_data)
	return floor_data["floor"]

/datum/component/arousal/proc/handle_passive_orgasm(giving = FALSE)
	if(last_orgasm_prog_increase_time < world.time - 10 SECONDS)
		return
	if(orgasm_progress > 50)
		return
	if(arousal < 60)
		return
	adjust_orgasm_prog(parent, CLAMP(arousal / 120, 1, 2))

/datum/component/arousal/proc/set_edging_state()
	is_edged = TRUE

/datum/component/arousal/proc/can_climax()
	// Add some checks for like curses or something here.
	var/mob/living/living_parent = parent
	var/cooldown = ORGASM_COOLDOWN_TIME * (isliving(living_parent) ? living_parent.get_climax_cooldown_multiplier() : 1)
	if(cooldown <= 0)
		return TRUE
	if(last_ejaculation_time + cooldown - clamp(edging_charge, 0, max(cooldown - 10, 0)) >= world.time)
		return FALSE
	return TRUE

/datum/component/arousal/proc/can_lose_arousal()
	if(last_arousal_increase_time + 2 MINUTES > world.time)
		return FALSE
	return TRUE

/datum/component/arousal/proc/set_holding_pleasure(datum/source, level)
	resistance_to_pleasure = level
	return resistance_to_pleasure

/datum/component/arousal/proc/set_orgasm_prog(datum/source, amount)
	if(amount > orgasm_progress)
		last_orgasm_prog_increase_time = world.time
	orgasm_progress = clamp(amount, 0, MAX_ORGASM_PROG)
	update_arousal_effects()
	return orgasm_progress

/datum/component/arousal/proc/adjust_orgasm_prog(datum/source, amount)
	if(orgasm_progress > 0)
		amount *= arousal_multiplier
	if(amount > 0 && isliving(parent))
		var/mob/living/living_parent = parent
		amount *= living_parent.get_orgasm_speed_multiplier()
	return set_orgasm_prog(source, orgasm_progress + amount)

/datum/component/arousal/proc/set_arousal(datum/source, amount)
	if(amount > arousal)
		last_arousal_increase_time = world.time
	arousal = clamp(amount, 0, MAX_AROUSAL)
	update_arousal_effects()
	if(isliving(parent))
		SEND_SIGNAL(parent, COMSIG_SEX_AROUSAL_CHANGED)
	return arousal

/datum/component/arousal/proc/adjust_arousal(datum/source, amount)
	if(arousal_frozen)
		return arousal
	if(arousal > 0)
		arousal *= arousal_multiplier
	return set_arousal(source, arousal + amount)

/datum/component/arousal/proc/freeze_arousal(datum/source, freeze_state = null)
	if(freeze_state == null)
		arousal_frozen = !arousal_frozen
	else
		arousal_frozen = freeze_state
	return arousal_frozen

/datum/component/arousal/proc/get_arousal(datum/source, list/arousal_data)
	arousal_data += list(
		"arousal" = arousal,
		"frozen" = arousal_frozen,
		"last_increase" = last_arousal_increase_time,
		"arousal_multiplier" = arousal_multiplier,
		"last_ejaculation_time" = last_ejaculation_time,
		"is_spent" = is_spent(),
		"edging" = edging_charge,
		"orgasm_strain" = orgasm_strain,
		"resistance_to_pleasure" = resistance_to_pleasure,
		"orgasm_progress" = orgasm_progress
	)

/datum/component/arousal/proc/adjust_edging(datum/source, amount)
	set_edging(source, edging_charge + amount)

/datum/component/arousal/proc/set_edging(datum/source, amount)
	edging_charge = clamp(amount, 0, MAX_EDGING)

/// action_performer is whatever drove this - a mob, or a structure/item like a horse, table or whip.
/datum/component/arousal/proc/receive_generic_sex_action(datum/source, mob/living/action_target, arousal_amt, pain_amt, orgasm_prog_amt, atom/action_performer)
	var/mob/living/user = parent
	// Self-directed only when the other party is us; an external performer never counts as giving.
	var/giving = (action_target == user)
	var/datum/sex_action/generic/s_action = new()

	if(user.stat == DEAD)
		arousal_amt = 0
		pain_amt = 0
		orgasm_prog_amt = 0
	var/applied_resist = RESIST_NONE
	var/applied_force = SEX_FORCE_MID
	var/applied_speed = SEX_SPEED_MID
	// Generic sources have no force/speed controls, so they run at the mid step rather than unscaled.
	pain_amt = get_scaled_pain(pain_amt, applied_force, applied_speed)

	var/isnymph = FALSE
	if(HAS_TRAIT(user, TRAIT_NYMPHO_CURSE) || user.has_quirk(/datum/quirk/negative/addiction/lovefiend))
		isnymph = TRUE

	if(user.has_status_effect(/datum/status_effect/debuff/orgasmbroken))
		if(isnymph)
			arousal_amt *= 1.5
		else
			arousal_amt *= 1.25
		var/lovermessage = pick("This feels too good!", "I must never stop!", "I want MORE!", "I need this!")
		if(prob(15))
			to_chat(user, span_love(lovermessage))

	else if(user.has_status_effect(/datum/status_effect/debuff/cumbrained))
		var/lovermessage
		if(!isnymph)
			arousal_amt *= 0.75
			lovermessage = pick("My mind is going blank!", "I'm too spent!", "This is too much!")
		else
			lovermessage = pick("This feels too good!", "I must never stop!", "I want MORE!", "I need this!", "I LOVE this!")
		if(prob(15))
			to_chat(user, span_love(lovermessage))


	else if(user.has_status_effect(/datum/status_effect/debuff/loinspent))
		refresh_aching()
		var/lovermessage
		if(!isnymph)
			arousal_amt *= 0.9
			lovermessage = pick("This is starting to feel unpleasant...", "Maybe I should rest soon...", "My loins are starting to chafe a bit.")
		else
			lovermessage = pick("This is starting to feel interesting.", "We're getting there...", "I love this feeling.")
		if(prob(15))
			to_chat(user, span_love(lovermessage))

	if(user.has_status_effect(/datum/status_effect/edging_overstimulation))
		arousal_amt *= 1.5
		if(prob(15))
			var/stimmessage
			stimmessage = pick("I'm too sensitive!", "There's too much pleasure!")
			to_chat(user, span_love(stimmessage))

	if(arousal > 35 && applied_resist > RESIST_NONE)
		var/resmessage
		if(user.has_status_effect(/datum/status_effect/debuff/cumbrained))
			if(prob(15))
				resmessage = pick("I can't hold in the pleasure!", "My mind is blank, I can't concentrate on not cumming!")
				to_chat(user, span_love(resmessage))
		else
			arousal_amt *= get_resist_multiplier(applied_resist)
			orgasm_prog_amt *= get_resist_multiplier(applied_resist)
			if(prob(5))
				resmessage = pick("I focus on holding in the pleasure.", "I concentrate on trying not to cum...")
				to_chat(user, span_love(resmessage))

	if(arousal > AROUSAL_EDGING_THRESHOLD)
		adjust_edging(source, arousal_amt / 3)

	if(is_spent() || is_manhood_overstimulated())
		arousal_amt *= 0.8
		refresh_aching()
		if(prob(5))
			var/spentmessage = pick("I need to let my loins rest!", "I came too much too quickly!")
			to_chat(user, span_warn(spentmessage))

	if(!arousal_frozen)
		adjust_arousal(source, arousal_amt)

	orgasm_prog_amt *= CLAMP(arousal / 60, 0.3, 2)
	adjust_orgasm_prog(parent, orgasm_prog_amt)

	damage_from_pain(pain_amt)
	// The receiver is always the climaxer on this path, matching the panel path's initiator contract.
	try_ejaculate(s_action, user, action_target, giving, action_performer || user)
	try_do_moan(arousal_amt, pain_amt, applied_force, giving)
	try_do_pain_effect(pain_amt, giving, applied_force, action_target)

/datum/component/arousal/proc/receive_sex_action(datum/source, datum/sex_action/s_action, mob/living/action_initiator, mob/living/action_target, arousal_amt, pain_amt, orgasm_prog_amt, giving, applied_force, applied_speed, applied_resist, atom/action_performer)
	var/mob/living/user = parent

	// Apply multipliers
	arousal_amt *= get_force_pleasure_multiplier(applied_force, giving)
	orgasm_prog_amt *= get_force_orgasm_multiplier(applied_force, giving)
	pain_amt = get_scaled_pain(pain_amt, applied_force, applied_speed)

	if(user.stat == DEAD)
		arousal_amt = 0
		pain_amt = 0
		orgasm_prog_amt = 0

	// Two-argument rand() rounds to whole numbers, so scale an integer roll.
	var/sexhealrand = rand(2, 4) * 0.1
	// Holy partners heal more through the Blessed Union spell.
	if(!user.cmode && prob(1)) //surprise heal burst at 1% chance
		to_chat(user, span_greentextbig("I suddenly feel much better thanks to this act..."))
		sexhealrand *= 5
	user.heal_wounds(sexhealrand)
	user.heal_overall_damage(sexhealrand, sexhealrand/2, updating_health = TRUE)

	var/isnymph = FALSE
	if(HAS_TRAIT(user, TRAIT_NYMPHO_CURSE) || user.has_quirk(/datum/quirk/negative/addiction/lovefiend))
		isnymph = TRUE
	if(user.has_status_effect(/datum/status_effect/debuff/orgasmbroken))
		if(isnymph)
			arousal_amt *= 1.5
		else
			arousal_amt *= 1.25
		var/lovermessage = pick("This feels too good!", "I must never stop!", "I want MORE!", "I need this!")
		if(prob(15))
			to_chat(user, span_love(lovermessage))
	else if(user.has_status_effect(/datum/status_effect/debuff/cumbrained))
		var/lovermessage
		if(!isnymph)
			arousal_amt *= 0.75
			lovermessage = pick("My mind is going blank!", "I'm too spent!", "This is too much!")
		else
			lovermessage = pick("This feels too good!", "I must never stop!", "I want MORE!", "I need this!", "I LOVE this!")
		if(prob(15))
			to_chat(user, span_love(lovermessage))
	else if(user.has_status_effect(/datum/status_effect/debuff/loinspent))
		refresh_aching()
		var/lovermessage
		if(!isnymph)
			arousal_amt *= 0.9
			lovermessage = pick("This is starting to feel unpleasant...", "Maybe I should rest soon...", "My loins are starting to chafe a bit.")
		else
			lovermessage = pick("This is starting to feel interesting.", "We're getting there...", "I love this feeling.")
		if(prob(15))
			to_chat(user, span_love(lovermessage))
	if(user.has_status_effect(/datum/status_effect/edging_overstimulation))
		arousal_amt *= 1.5
		if(prob(15))
			var/stimmessage
			stimmessage = pick("I'm too sensitive!", "There's too much pleasure!")
			to_chat(user, span_love(stimmessage))
	if(arousal > 35 && applied_resist > RESIST_NONE)
		var/resmessage
		if(user.has_status_effect(/datum/status_effect/debuff/cumbrained))
			if(prob(15))
				resmessage = pick("I can't hold in the pleasure!", "My mind is blank, I can't concentrate on not cumming!")
				to_chat(user, span_love(resmessage))
		else
			arousal_amt *= get_resist_multiplier(applied_resist)
			orgasm_prog_amt *= get_resist_multiplier(applied_resist)
			if(prob(5))
				resmessage = pick("I focus on holding in the pleasure.", "I concentrate on trying not to cum...")
				to_chat(user, span_love(resmessage))
	if(arousal > AROUSAL_EDGING_THRESHOLD)
		adjust_edging(source, arousal_amt / 3)
	if(is_edged)
		if(arousal <= 120)
			arousal_amt = 0.01
			orgasm_prog_amt = 0.01
		else
			arousal_amt *= 0.2
			orgasm_prog_amt *= 0.2
		if(prob(15))
			var/edgemessage = pick("They are not letting me cum!", "Please, let me cum!", "I need to cum already!")
			to_chat(user, span_love(edgemessage))
	if(is_spent() || is_manhood_overstimulated())
		arousal_amt *= 0.8
		refresh_aching()
		if(prob(5))
			var/spentmessage = pick("I need to let my loins rest!", "I came too much too quickly!")
			to_chat(user, span_warn(spentmessage))

	if(!arousal_frozen)
		adjust_arousal(source, arousal_amt)

	orgasm_prog_amt *= CLAMP(arousal / 60, 0.3, 2)
	adjust_orgasm_prog(parent, orgasm_prog_amt)

	damage_from_pain(pain_amt)
	try_ejaculate(s_action, action_initiator, action_target, giving, action_performer)
	try_do_moan(arousal_amt, pain_amt, applied_force, giving)
	try_do_pain_effect(pain_amt, giving, applied_force, action_target)

	is_edged = FALSE

/datum/component/arousal/proc/update_arousal_effects()
	update_pink_screen()
	handle_statuses()
	//update_erect_state()

/datum/component/arousal/proc/try_ejaculate(datum/sex_action/s_action, mob/living/action_initiator, mob/living/action_target, giving = FALSE, atom/action_performer)
	if(orgasm_progress < PASSIVE_EJAC_THRESHOLD)
		return
	if(!can_climax())
		return
	ejaculate(s_action, action_initiator, action_target, giving, action_performer)

/datum/component/arousal/proc/manual_orgasm(datum/source)
	ejaculate()

/datum/component/arousal/proc/ejaculate(datum/sex_action/s_action, mob/living/action_initiator, mob/living/action_target, giving = FALSE, atom/action_performer)

	var/mob/living/mob = parent
	var/datum/sex_action/action = s_action

	if(!action_initiator)
		action_initiator = parent
	if(!action_performer)
		action_performer = action_initiator

	var/mob/living/target
	if(parent == action_initiator)
		target = action_target
	else if(parent != action_target)
		target = action_initiator
	var/must_flip = !giving

	mob.sex_scene?.handle_pattern_climax(mob, action)
	apply_orifice_climax_moods(mob, action)
	playsound(parent, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)
	// Special cases for when the user has a penis but no testicles & for eunuchs
	if(mob.climaxes_dry())
		mob.visible_message(span_love(mob.get_dry_climax_message()))
		after_ejaculation(FALSE, parent, null, action, action_initiator, action_target, action_performer)
		return
	// The act's own climax lines would spill from the strapon, so only the wearer's vagina climaxes.
	if(target && mob.climaxes_behind_strapon(action))
		mob.visible_message(span_love("[mob] shudders and climaxes, [mob.p_their()] hips bucking behind [mob.p_their()] strapon!"), span_love("I shudder and climax, my hips bucking behind my strapon!"))
		var/obj/item/organ/genitals/filling_organ/vagina/strapon_vag = mob.getorganslot(ORGAN_SLOT_VAGINA)
		if(strapon_vag?.reagents)
			strapon_vag.produce_climax_fluid()
		// A worn harness may empty its bulb, or pump the release, through the toy.
		mob.on_strapon_climax(action, target)
		after_ejaculation(FALSE, parent, target, action, action_initiator, action_target, action_performer)
		return
	var/obj/item/organ/genitals/filling_organ/testicles/climax_testes = mob.getorganslot(ORGAN_SLOT_TESTICLES)
	if(climax_testes?.is_pent_up() && mob.getorganslot(ORGAN_SLOT_PENIS))
		to_chat(mob, span_love("A pent-up load surges out of me!"))
		mob.add_stress(/datum/stress_event/pent_up_release)
	// An aim on the cock, from a hand or an NPC, decides where a hand-driven climax lands.
	var/datum/climax_aim/steering_aim = get_steering_aim(action)
	if(steering_aim && climax_at_aim(steering_aim, action, action_initiator, action_target, action_performer))
		return
	if(!action || !target)
		mob.visible_message(span_love("[mob] orgasms!"))
		var/turf/turf = get_turf(mob)
		if(mob.getorganslot(ORGAN_SLOT_TESTICLES) && mob.getorganslot(ORGAN_SLOT_PENIS))
			var/obj/item/organ/genitals/filling_organ/testicles/testes = mob.getorganslot(ORGAN_SLOT_TESTICLES)
			if(testes)
				if(testes.reagents)
					var/cum_to_take = testes.get_climax_release()
					// Routed so worn catchers (pumps, condom leeches) get a chance before the floor.
					begin_spurts(new /datum/climax_spurts/floor(src, cum_to_take, action, action_initiator, action_target, action_performer, target, turf))
		// Female climax fills the vagina rather than spawning a puddle; the organ's drip system handles leakage.
		if(mob.getorganslot(ORGAN_SLOT_VAGINA))
			var/obj/item/organ/genitals/filling_organ/vagina/vag = mob.getorganslot(ORGAN_SLOT_VAGINA)
			if(vag?.reagents)
				vag.produce_climax_fluid()
		after_ejaculation(FALSE, mob, null, action, action_initiator, action_target, action_performer)
	else
		// Still pressing at the opening, or a successful pull-out to finish outside, lands the climax outside.
		var/knot_force_bonus = mob.get_climax_knot_force_bonus(action)
		var/wants_out = wants_to_finish_outside(action, mob)
		// A knot force bonus means the climax always knots, so it cannot pull out.
		if(wants_out && knot_force_bonus > 0)
			wants_out = FALSE
			to_chat(mob, span_love("I can't make myself pull out!"))
		var/pulled_out = action.orifice_pressing || (wants_out && try_pull_out(mob, target))
		var/return_type = pulled_out ? pull_out_for_climax(action, mob, target) : action.handle_climax_message(mob, target, must_flip)
		if(!return_type)
			var/turf/turf = get_turf(mob)
			if(mob.getorganslot(ORGAN_SLOT_TESTICLES) && mob.getorganslot(ORGAN_SLOT_PENIS))
				var/obj/item/organ/genitals/filling_organ/testicles/testes = mob.getorganslot(ORGAN_SLOT_TESTICLES)
				if(testes)
					if(testes.reagents)
						var/cum_to_take = testes.get_climax_release()
						begin_spurts(new /datum/climax_spurts/floor(src, cum_to_take, action, action_initiator, action_target, action_performer, target, turf))
			// Female climax fills the vagina rather than spawning a puddle; the organ's drip system handles leakage.
			if(mob.getorganslot(ORGAN_SLOT_VAGINA))
				var/obj/item/organ/genitals/filling_organ/vagina/vag = mob.getorganslot(ORGAN_SLOT_VAGINA)
				if(vag?.reagents)
					vag.produce_climax_fluid()
			after_ejaculation(FALSE, mob, target, action, action_initiator, action_target, action_performer)
		else
			handle_climax(action, return_type, mob, target, giving, action_initiator, action_target, action_performer)

		var/knot_finished = FALSE
		if(action.knot_on_finish && !pulled_out) //no idea how to stop other partner from triggering the knotting yet sorry
			knot_finished = try_climax_knot(action, mob, target, knot_force_bonus)

		if(return_type == ORGASM_LOCATION_INTO && ishuman(mob) && ishuman(target))
			var/mob/living/carbon/human/source_human = mob
			var/mob/living/carbon/human/target_human = target
			target_human.handle_werewolf_creampie_conversion(source_human, knot_finished)

/// Ties the climax knot; a force bonus roughens the action's force for this one synchronous call.
/datum/component/arousal/proc/try_climax_knot(datum/sex_action/action, mob/living/climaxer, mob/living/partner, force_bonus = 0)
	if(force_bonus <= 0)
		return action.try_knot_on_climax(climaxer, partner)
	var/base_force = action.force
	action.force = clamp(base_force + force_bonus, SEX_FORCE_MIN, SEX_FORCE_MAX)
	. = action.try_knot_on_climax(climaxer, partner)
	action.force = base_force

/datum/component/arousal/proc/handle_climax(datum/sex_action/action, climax_type, mob/living/user, mob/living/target, giving, mob/living/action_initiator, mob/living/action_target, atom/action_performer)
	var/obj/item/organ/genitals/filling_organ/testicles/testes
	var/obj/item/organ/genitals/filling_organ/vagina/vag
	var/climax_fluid_transferred = FALSE
	if(user.getorganslot(ORGAN_SLOT_TESTICLES) && user.getorganslot(ORGAN_SLOT_PENIS))
		testes = user.getorganslot(ORGAN_SLOT_TESTICLES)
	if(user.getorganslot(ORGAN_SLOT_VAGINA))
		vag = user.getorganslot(ORGAN_SLOT_VAGINA)
	/*if(issimple(user))
		log_combat(user, user, "Ejaculated")
		user.visible_message(span_love("[user] makes a mess!"))
		playsound(user, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)
		var/turf/turf = get_turf(target)
		turf.add_liquid(/datum/reagent/consumable/cum, 5)
		after_ejaculation(climax_type == ORGASM_LOCATION_INTO || climax_type == ORGASM_LOCATION_ORAL, user, target)
		return*/

	var/is_oral = FALSE
	if(action)
		if(action.hole_id == BODY_ZONE_PRECISE_MOUTH || istype(action, /datum/sex_action/cunnilingus))
			is_oral = TRUE

	switch(climax_type)
		if(ORGASM_LOCATION_ONTO)
			log_combat(user, target, "Came onto the target")
			playsound(target, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)
			var/coat_zone = climax_zone_override || (action ? action.get_climax_coat_zone(user) : FLUID_COAT_CHEST)
			climax_zone_override = null
			if(testes)
				if(testes.reagents)
					var/cum_to_take = testes.get_climax_release(ORGASM_LOCATION_ONTO)
					var/mob/living/spurt_target = target
					var/spurt_zone = coat_zone
					// Lying under a partner who is inside them, the cock spurts back over its own body.
					if(spurts_over_own_body(action, user))
						spurt_target = user
						spurt_zone = FLUID_COAT_CHEST
					// Spurts drift down the body from the zone the climax starts at.
					if(spurt_onto(spurt_target, spurt_zone, cum_to_take, action, action_initiator, action_target, action_performer))
						climax_fluid_transferred = TRUE
			if(vag)
				if(vag.reagents)
					var/femcum_to_take = vag.get_climax_release(climax_type)
					if(coat_climax_onto(vag.reagents, femcum_to_take, user, target, action, climax_type, coat_zone, action_initiator, action_target, action_performer) > 0)
						climax_fluid_transferred = TRUE

		if(ORGASM_LOCATION_INTO)
			log_combat(user, target, "Came inside the target")
			var/mob/living/played_on = target ? target : user
			playsound(played_on, 'sound/misc/mat/endin.ogg', 50, TRUE, ignore_walls = FALSE)
			if(testes && testes.reagents)
				var/obj/item/organ/genitals/filling_organ/cameloc
				if(target && action)
					switch(action.hole_id)
						if(ORGAN_SLOT_VAGINA)
							cameloc = target.getorganslot(ORGAN_SLOT_VAGINA)
						if(ORGAN_SLOT_ANUS)
							cameloc = target.getorganslot(ORGAN_SLOT_ANUS)
				if(cameloc && cameloc.reagents)
					// The whole load comes; what the hole cannot take overflows out of it.
					var/cum_to_take = testes.get_climax_release(ORGASM_LOCATION_INTO)
					if(begin_spurts(new /datum/climax_spurts/inside(src, cum_to_take, action, action_initiator, action_target, action_performer, target, cameloc)) > 0)
						climax_fluid_transferred = TRUE
				else if(target)
					var/cum_to_take = testes.get_climax_release(ORGASM_LOCATION_INTO)
					if(begin_spurts(new /datum/climax_spurts/inside(src, cum_to_take, action, action_initiator, action_target, action_performer, target, null)) > 0)
						climax_fluid_transferred = TRUE
			if(target && climax_fluid_transferred)
				apply_creampie_effect(target)

		if(ORGASM_LOCATION_ORAL)
			log_combat(user, target, "Came inside the mouth of the target")
			var/mob/living/played_on = target ? target : user
			playsound(played_on, 'sound/misc/mat/endin.ogg', 50, TRUE, ignore_walls = FALSE)
			if(target && action)
				if(user.getorganslot(ORGAN_SLOT_PENIS) && action.check_sex_lock(user, ORGAN_SLOT_PENIS))
					if(testes && testes.reagents)
						var/cum_to_take = testes.get_climax_release(ORGASM_LOCATION_ORAL)
						if(begin_spurts(new /datum/climax_spurts/inside/oral(src, cum_to_take, action, action_initiator, action_target, action_performer, target)) > 0)
							climax_fluid_transferred = TRUE
				if(user.getorganslot(ORGAN_SLOT_VAGINA) && action.check_sex_lock(user, ORGAN_SLOT_VAGINA))
					if(vag && vag.reagents)
						var/femcum_to_take = vag.get_climax_release(climax_type)
						if(route_climax_reagents(vag.reagents, femcum_to_take, user, target, action, climax_type, target, INGEST, action_initiator, action_target, action_performer) > 0)
							climax_fluid_transferred = TRUE
			if(target && climax_fluid_transferred)
				if(is_oral)
					spill_climax_on_face(target, testes, vag)
				else
					apply_creampie_effect(target)

		if(ORGASM_LOCATION_SELF)
			log_combat(user, user, "Ejaculated")
			user.visible_message(span_love("[user] makes a mess!"))
			playsound(user, 'sound/misc/mat/endout.ogg', 50, TRUE, ignore_walls = FALSE)
			var/turf/turf = get_turf(target)
			if(testes)
				if(testes.reagents)
					var/cum_to_take = testes.get_climax_release(ORGASM_LOCATION_SELF)
					begin_spurts(new /datum/climax_spurts/floor(src, cum_to_take, action, action_initiator, action_target, action_performer, target, turf))
			// Female climax fills the vagina rather than spawning a puddle; the organ's drip system handles leakage.
			if(vag?.reagents)
				vag.produce_climax_fluid()

		if(ORGASM_LOCATION_CONTAINER)
			var/obj/item/container = action?.get_climax_container(user, target, action_initiator, action_target, action_performer)
			if(!container || !container.reagents)
				// container is gone (dropped/swapped/full-removed); don't silently eat the climax, spill it like SELF.
				var/turf/turf = get_turf(user)
				if(testes?.reagents)
					var/cum_to_take = testes.get_climax_release(ORGASM_LOCATION_SELF)
					begin_spurts(new /datum/climax_spurts/floor(src, cum_to_take, action, action_initiator, action_target, action_performer, target, turf))
				// Female climax fills the vagina rather than spawning a puddle; the organ's drip system handles leakage.
				if(vag?.reagents)
					vag.produce_climax_fluid()
			else
				log_combat(user, user, "Ejaculated into [container]")
				playsound(container, 'sound/misc/mat/endin.ogg', 50, TRUE, ignore_walls = FALSE)
				var/free_space = container.reagents.maximum_volume - container.reagents.total_volume
				if(testes?.reagents && free_space > 0)
					var/cum_to_take = testes.get_climax_release(ORGASM_LOCATION_CONTAINER, free_space)
					if(cum_to_take > 0 && begin_spurts(new /datum/climax_spurts/container(src, cum_to_take, action, action_initiator, action_target, action_performer, target, container)) > 0)
						climax_fluid_transferred = TRUE
						free_space = container.reagents.maximum_volume - container.reagents.total_volume
				if(vag?.reagents && free_space > 0)
					var/femcum_to_take = vag.get_climax_release(ORGASM_LOCATION_CONTAINER, free_space)
					if(femcum_to_take > 0 && route_climax_reagents(vag.reagents, femcum_to_take, user, target, action, climax_type, container, INJECT, action_initiator, action_target, action_performer) > 0)
						climax_fluid_transferred = TRUE
				if(!climax_fluid_transferred)
					to_chat(user, span_warning("Nothing comes out into \the [container]."))
	if(testes)
		if(testes.reagents)
			if(testes.reagents.total_volume <= testes.reagents.maximum_volume / 4)
				to_chat(user, span_info("Damn, my [pick(testes.altnames)] are pretty dry now."))
	after_ejaculation(climax_type == ORGASM_LOCATION_INTO || climax_type == ORGASM_LOCATION_ORAL, user, target, action, action_initiator, action_target, action_performer)

/datum/component/arousal/proc/route_climax_reagents(datum/reagents/source_reagents, amount, mob/living/user, mob/living/target, datum/sex_action/action, climax_type, atom/destination, transfer_method, mob/living/action_initiator, mob/living/action_target, atom/action_performer, use_fluid_decal = FALSE, follow_up = FALSE)
	if(!source_reagents || amount <= 0)
		return 0
	var/remaining = apply_sex_action_climax_effects(user, target, action, climax_type, source_reagents, amount, destination, transfer_method, action_initiator, action_target, action_performer, follow_up)
	if(remaining <= 0)
		return 0
	if(isturf(destination))
		var/turf/destination_turf = destination
		leave_fluid_scent(destination_turf, user, get_fluid_scent_kind(source_reagents.get_master_reagent()))
		if(use_fluid_decal) //spilled ejaculate forms a drip/puddle decal instead of a raw liquid puddle.
			deposit_cum_on_turf(destination_turf, source_reagents, remaining)
		else
			destination_turf.add_liquid_from_reagents(source_reagents, amount = remaining)
	else if(destination)
		source_reagents.trans_to(destination, remaining, transfered_by = user, method = transfer_method)
	return remaining

/// A climax onto a partner: worn catchers first, then their clothes or bare skin at the zone, the rest to the floor.
/datum/component/arousal/proc/coat_climax_onto(datum/reagents/source_reagents, amount, mob/living/user, mob/living/target, datum/sex_action/action, climax_type, coat_zone, mob/living/action_initiator, mob/living/action_target, atom/action_performer, follow_up = FALSE)
	if(!source_reagents || amount <= 0)
		return 0
	var/remaining = apply_sex_action_climax_effects(user, target, action, climax_type, source_reagents, amount, target, null, action_initiator, action_target, action_performer, follow_up)
	if(remaining <= 0)
		return 0
	var/leftover = remaining
	if(ishuman(target))
		var/mob/living/carbon/human/human_target = target
		leftover = human_target.coat_with_fluid(coat_zone, source_reagents, remaining)
	if(leftover > 0)
		deposit_cum_on_turf(get_turf(target || user), source_reagents, leftover)
	return remaining

/// An oral climax leaves a little on the partner's face.
/datum/component/arousal/proc/spill_climax_on_face(mob/living/target, obj/item/organ/genitals/filling_organ/testes, obj/item/organ/genitals/filling_organ/vag)
	if(!ishuman(target))
		return
	var/mob/living/carbon/human/human_target = target
	for(var/obj/item/organ/genitals/filling_organ/source_organ in list(testes, vag))
		if(source_organ.reagents?.total_volume)
			human_target.coat_with_fluid(FLUID_COAT_FACE, source_organ.reagents, FLUID_COAT_ORAL_SPILL)
			return

/datum/component/arousal/proc/apply_creampie_effect(mob/living/recipient)
	if(!recipient)
		return
	var/datum/status_effect/facial/internal/creampie_effect = recipient.has_status_effect(/datum/status_effect/facial/internal)
	if(creampie_effect)
		creampie_effect.refresh_cum()
	else
		recipient.apply_status_effect(/datum/status_effect/facial/internal)

/datum/component/arousal/proc/add_orgasm_strain(mob/living/user)
	if(!user)
		return
	var/strain_to_add = 0
	if(last_ejaculation_time)
		var/time_since_last = world.time - last_ejaculation_time
		if(time_since_last <= 45 SECONDS)
			strain_to_add += 20
		else if(time_since_last <= 2 MINUTES)
			strain_to_add += 14
		else if(time_since_last <= 4 MINUTES)
			strain_to_add += 8
		else if(time_since_last <= 6 MINUTES)
			strain_to_add += 4

	switch(edging_charge)
		if(30 to 50)
			strain_to_add += 4
		if(51 to 70)
			strain_to_add += 8
		if(71 to INFINITY)
			strain_to_add += 14

	switch(arousal)
		if(160 to 239)
			strain_to_add += 4
		if(240 to INFINITY)
			strain_to_add += 8

	if(charge <= CHARGE_FOR_CLIMAX)
		strain_to_add += 10
	if(user.has_status_effect(/datum/status_effect/edging_overstimulation))
		strain_to_add += 8
	if(strain_to_add <= 0)
		return

	orgasm_strain = clamp(orgasm_strain + strain_to_add, 0, ORGASM_STRAIN_MAX)
	last_orgasm_strain_decay_time = world.time

/datum/component/arousal/proc/after_ejaculation(intimate = FALSE, mob/living/user, mob/living/target, datum/sex_action/action, mob/living/action_initiator, mob/living/action_target, atom/action_performer)
	switch(edging_charge)
		if(10 to 20)
			to_chat(user, span_love("Feels good to finally cum!"))
		if(21 to 50)
			to_chat(user, span_love("Oh gods, I came!"))
		if(51 to MAX_EDGING)
			to_chat(user, span_love("Finally finally finally!"))

	add_orgasm_strain(user)

	// A worn strapon is no penis, so its wearer follows the edging rules for a vagina.
	if(user.has_real_penis())
		if(is_spent())
			to_chat(user, span_warn("This is really starting to hurt my dick!"))
			user.apply_status_effect(/datum/status_effect/edged_penis_cooldown)
			set_edging(parent, edging_charge * 0.40)
		else
			set_edging(parent, 0)

	else
		set_edging(parent, edging_charge * 0.70)

	set_arousal(parent, arousal * (arousal_falloff_coeff + edging_charge / MAX_EDGING))
	set_orgasm_prog(parent, 0)
	// The trailing intimate flag marks a climax inside or in the mouth; older handlers ignore it.
	SEND_SIGNAL(user, COMSIG_SEX_CLIMAX, action, action_initiator, action_target, action_performer, intimate)
	if(arousal > MAX_AROUSAL / 4)
		user.play_climax_motion()

	if(user.has_quirk(/datum/quirk/negative/addiction/lovefiend))
		user.sate_addiction(/datum/quirk/negative/addiction/lovefiend)

	if(!user.rogue_sneaking && user.alpha > 100) //stealth sex, keep your voice down.
		if(!user.can_speak())
			user.emote("sexmoangag_org", forced = TRUE)
		else
			user.emote("sexmoanhvy", forced = TRUE)

	user.try_ear_flick()

	charge = max(0, charge - CHARGE_FOR_CLIMAX)

	is_edged = FALSE

	user.add_stress(/datum/stress_event/cumok)
	user.playsound_local(user, 'sound/misc/mat/end.ogg', 100)
	last_ejaculation_time = world.time
	recent_orgasm_count += 1
	if(intimate)
		if(target)
			after_intimate_climax(user, target)

/datum/component/arousal/proc/after_intimate_climax(mob/living/user, mob/living/target)
	if(user == target)
		return
	if(HAS_TRAIT(target, TRAIT_GOODLOVER))
		if(!MOBTIMER_FINISHED(user, "cumtri", 5 MINUTES)) //this isn't how mob timers work
			return

		MOBTIMER_SET(user, "cumtri")
		user.adjust_triumphs(1)
		user.add_stress(/datum/stress_event/cummax)
		to_chat(user, span_love("Our loving is a true TRIUMPH!"))
	if(HAS_TRAIT(user, TRAIT_GOODLOVER))
		if(!MOBTIMER_FINISHED(user, "cumtri", 5 MINUTES)) //this isn't how mob timers work
			return

		MOBTIMER_SET(user, "cumtri")
		target.adjust_triumphs(1)
		user.add_stress(/datum/stress_event/cummax)
		to_chat(target, span_love("Our loving is a true TRIUMPH!"))

/datum/component/arousal/proc/set_charge(parent, amount)
	var/empty = (charge < CHARGE_FOR_CLIMAX)
	charge = clamp(amount, 0, SEX_MAX_CHARGE)
	var/after_empty = (charge < CHARGE_FOR_CLIMAX)
	if(empty && !after_empty)
		to_chat(parent, span_notice("I feel like I'm not so spent anymore"))
	if(!empty && after_empty)
		to_chat(parent, span_notice("I'm spent!"))

/datum/component/arousal/proc/adjust_charge(parent, amount)
	set_charge(parent, charge + amount)

/datum/component/arousal/proc/handle_charge()
	var/mob/living/user = parent
	adjust_charge(parent, ARO_LOSS_COEFFICIENT * CHARGE_RECHARGE_RATE)
	if(is_spent())
		if(arousal > 60)
			if(!MOBTIMER_FINISHED(user, "sex_charge_msg", rand(20,40)SECONDS))
				return
			MOBTIMER_SET(user, "sex_charge_msg")
			to_chat(parent, span_warning("I've came too much recently."))
			return
		adjust_arousal(parent, -1 * ARO_LOSS_COEFFICIENT * SPENT_AROUSAL_RATE)

/datum/component/arousal/proc/is_spent()
	if(charge < CHARGE_FOR_CLIMAX)
		return TRUE
	return FALSE

/datum/component/arousal/proc/is_manhood_overstimulated()
	var/mob/living/user = parent
	if(user.has_status_effect(/datum/status_effect/edged_penis_cooldown))
		return TRUE
	return FALSE

/datum/component/arousal/proc/update_pink_screen()
	var/mob/living/user = parent
	var/severity = 0
	switch(arousal)
		if(1 to 20)
			severity = 1
		if(20 to 40)
			severity = 2
		if(40 to 60)
			severity = 3
		if(60 to 80)
			severity = 4
		if(80 to 100)
			severity = 5
		if(100 to 120)
			severity = 6
		if(120 to 140)
			severity = 7
		if(140 to 160)
			severity = 8
		if(160 to 180)
			severity = 9
		if(180 to INFINITY)
			severity = 10
	if(severity > 0)
		user.overlay_fullscreen("horny", /atom/movable/screen/fullscreen/love, severity)
	else
		user.clear_fullscreen("horny")

/*/datum/component/arousal/proc/update_blueballs()
	var/mob/living/user = parent
	if(last_arousal_increase_time + 30 SECONDS > world.time)
		return
	if(arousal >= BLUEBALLS_GAIN_THRESHOLD)
		user.add_stress(/datum/stress_event/blue_balls)
	else if(arousal <= BLUEBALLS_LOOSE_THRESHOLD)
		user.remove_stress(/datum/stress_event/blue_balls)

/datum/component/arousal/proc/update_erect_state()
	var/mob/living/user = parent
	var/obj/item/organ/genitals/penis/penis = user.getorganslot(ORGAN_SLOT_PENIS)

	if(user.mind)
		var/datum/antagonist/werewolf/W = user.mind.has_antag_datum(/datum/antagonist/werewolf/)
		if(W && W.transformed == TRUE)
			user.regenerate_icons()

	if(penis && hascall(penis, "update_erect_state"))// && !istype(penis, /obj/item/organ/genitals/penis/internal))//if(penis && hascall(penis, "update_erect_state"))
		penis.update_erect_state()*/


/// Scales an action's declared pain by force, speed and receiver arousal. Floored at zero.
/datum/component/arousal/proc/get_scaled_pain(pain_amt, applied_force, applied_speed)
	if(pain_amt <= 0)
		return 0
	pain_amt *= get_force_pain_multiplier(applied_force)
	pain_amt *= get_speed_pain_multiplier(applied_speed)
	pain_amt *= get_readiness_pain_multiplier()
	return max(pain_amt, 0)

/// Feeds ERP pain into the body pain system, so it reaches shock, painkillers and the masochist craving.
/datum/component/arousal/proc/damage_from_pain(pain_amt)
	if(pain_amt < PAIN_MINIMUM_FOR_DAMAGE)
		return
	update_aching(pain_amt)

	var/mob/living/user = parent
	var/obj/item/bodypart/part = user.get_bodypart(BODY_ZONE_CHEST)
	if(!part)
		return
	// add_pain() already honours can_feel_pain(), painkillers and the limb's own pain ceiling.
	part.add_pain(pain_amt / PAIN_DAMAGE_DIVISOR)

/datum/component/arousal/proc/try_do_moan(arousal_amt, pain_amt, applied_force, giving)
	var/mob/living/user = parent
	// Pain is its own reason to make a noise, not just arousal.
	if(arousal_amt < 1.5 && pain_amt < PAIN_MILD_EFFECT)
		return
	if(user.stat != CONSCIOUS)
		return
	if(last_moan + MOAN_COOLDOWN >= world.time)
		return
	if(prob(50))
		return
	var/chosen_emote
	switch(arousal_amt)
		if(0 to 40)
			if(!user.can_speak())
				chosen_emote = "sexmoangag"
			else
				chosen_emote = "sexmoanlight"
		if(40 to 75)
			if(!user.can_speak())
				chosen_emote = "sexmoangag"
			else
				chosen_emote = "sexmoanmed"
		if(75 to INFINITY)
			if(!user.can_speak())
				chosen_emote = "sexmoangag"
			else
				chosen_emote = "sexmoanhvy"
	if(pain_amt >= PAIN_MILD_EFFECT)
		if(!user.can_speak())
			chosen_emote = "sexmoangag"
		else
			if(prob(15))
				chosen_emote = "sexmoanhvy"
			else
				chosen_emote = "sexmoanmed"
	if(pain_amt >= PAIN_MED_EFFECT)
		if(giving)
			if(!user.can_speak())
				chosen_emote = "sexmoangag"
			else
				if(prob(20))
					chosen_emote = "sexmoanhvy"
				else
					chosen_emote = "sexmoanmed"
		else
			if(!user.can_speak())
				chosen_emote = "sexmoangag"
			else
				if(prob(60))
					// Because males have atrocious whimper noise
					if(user.gender == FEMALE && prob(15))
						chosen_emote = "whimper"
					else
						chosen_emote = "sexmoanhvy"

	last_moan = world.time
	user.emote(chosen_emote, forced = TRUE)

/// Harder settings earn feedback more often, so the top steps read as continuous rather than occasional.
/datum/component/arousal/proc/get_pain_cooldown(applied_force)
	switch(applied_force)
		if(SEX_FORCE_HIGH)
			return PAIN_COOLDOWN_HIGH
		if(SEX_FORCE_EXTREME)
			return PAIN_COOLDOWN_EXTREME
		if(SEX_FORCE_UNRELENTING)
			return PAIN_COOLDOWN_UNRELENTING
	return PAIN_COOLDOWN

/// Receiver is always told. Only the room line and partner cue are probability-gated, against spam.
/datum/component/arousal/proc/try_do_pain_effect(pain_amt, giving, applied_force = SEX_FORCE_MID, mob/living/partner)
	var/mob/living/user = parent
	if(pain_amt < PAIN_MILD_EFFECT)
		return
	if(last_pain + get_pain_cooldown(applied_force) >= world.time)
		return
	last_pain = world.time

	var/masochist = user.has_quirk(/datum/quirk/negative/addiction/masochist)
	var/self_msg
	var/observed_msg
	var/partner_msg
	var/flash

	if(pain_amt >= PAIN_HIGH_EFFECT)
		self_msg = masochist \
			? pick("IT HURTS, DON'T STOP!!!", "DON'T STOP!!!", "MORE, MORE!!!") \
			: pick("IT HURTS!!!", "IT NEEDS TO STOP!!!", "I CAN'T TAKE IT ANYMORE!!!")
		observed_msg = pick("[user] convulses in pain!", "[user] jerks hard, [user.p_their()] face contorted!", "[user] shudders violently in pain!")
		partner_msg = pick("[user] is being torn up by this.", "[user] can barely take what I am doing to [user.p_them()].", "I am hurting [user] badly.")
		flash = "redflash2"
	else if(pain_amt >= PAIN_MED_EFFECT)
		self_msg = pick("It hurts!", "It pains me!")
		observed_msg = pick("[user] shudders in pain!", "[user] winces sharply!")
		partner_msg = pick("[user] winces under me.", "I can feel [user] flinching.", "This is hurting [user].")
		flash = "redflash1"
	else
		self_msg = pick("It hurts a little...", "It stings...", "I'm aching...")
		observed_msg = pick("[user] winces.", "[user] tenses up for a moment.")

	to_chat(user, masochist ? span_boldgreen(self_msg) : (pain_amt >= PAIN_MED_EFFECT ? span_boldwarning(self_msg) : span_warning(self_msg)))
	if(flash)
		user.flash_fullscreen(flash)

	if(user.stat != CONSCIOUS)
		return
	if(observed_msg && prob(pain_amt >= PAIN_HIGH_EFFECT ? 70 : 40))
		user.visible_message(span_warning(observed_msg), ignored_mobs = list(user, partner))
	if(partner_msg && partner && partner != user && !QDELETED(partner) && prob(50))
		to_chat(partner, span_warning(partner_msg))

/// Refreshes the ache only when this hit was hard enough to earn it.
/datum/component/arousal/proc/update_aching(pain_amt)
	if(pain_amt < LOINHURT_GAIN_THRESHOLD)
		return
	refresh_aching()

/// Never cancel the ache early; add_stress resets its timer and it expires on its own.
/datum/component/arousal/proc/refresh_aching()
	var/mob/living/user = parent
	if(user.has_quirk(/datum/quirk/negative/addiction/masochist))
		user.sate_addiction(/datum/quirk/negative/addiction/masochist)
		user.add_stress(/datum/stress_event/loinachegood)
		return
	if(user.has_quirk(/datum/quirk/negative/addiction/lovefiend))
		user.add_stress(/datum/stress_event/loinachegood)
		return
	user.add_stress(/datum/stress_event/loinache)

/datum/component/arousal/proc/get_force_pleasure_multiplier(passed_force, giving)
	switch(passed_force)
		if(SEX_FORCE_LOW)
			if(giving)
				return 0.8
			else
				return 0.8
		if(SEX_FORCE_MID)
			if(giving)
				return 1.2
			else
				return 1.2
		if(SEX_FORCE_HIGH)
			if(giving)
				return 1.6
			else
				return 1.2
		if(SEX_FORCE_EXTREME)
			if(giving)
				return 2.0
			else
				return 0.8
		if(SEX_FORCE_UNRELENTING)
			if(giving)
				return 2.4
			else
				return 0.6
	return 1.2

/datum/component/arousal/proc/get_force_pain_multiplier(passed_force)
	switch(passed_force)
		if(SEX_FORCE_LOW)
			return SEX_FORCE_PAIN_MULT_LOW
		if(SEX_FORCE_MID)
			return SEX_FORCE_PAIN_MULT_MID
		if(SEX_FORCE_HIGH)
			return SEX_FORCE_PAIN_MULT_HIGH
		if(SEX_FORCE_EXTREME)
			return SEX_FORCE_PAIN_MULT_EXTREME
		if(SEX_FORCE_UNRELENTING)
			return SEX_FORCE_PAIN_MULT_UNRELENTING
	return SEX_FORCE_PAIN_MULT_MID

/datum/component/arousal/proc/get_speed_pain_multiplier(passed_speed)
	switch(passed_speed)
		if(SEX_SPEED_LOW)
			return SEX_SPEED_PAIN_MULT_LOW
		if(SEX_SPEED_MID)
			return SEX_SPEED_PAIN_MULT_MID
		if(SEX_SPEED_HIGH)
			return SEX_SPEED_PAIN_MULT_HIGH
		if(SEX_SPEED_EXTREME)
			return SEX_SPEED_PAIN_MULT_EXTREME
		if(SEX_SPEED_UNRELENTING)
			return SEX_SPEED_PAIN_MULT_UNRELENTING
	return SEX_SPEED_PAIN_MULT_MID

/// An aroused body takes the same act far better than a cold one. Applied to the receiver's own arousal.
/datum/component/arousal/proc/get_readiness_pain_multiplier()
	if(arousal < SEX_PAIN_READINESS_WARMING_THRESHOLD)
		return SEX_PAIN_READINESS_UNAROUSED
	if(arousal < SEX_PAIN_READINESS_READY_THRESHOLD)
		return SEX_PAIN_READINESS_WARMING
	if(arousal < SEX_PAIN_READINESS_LOST_THRESHOLD)
		return SEX_PAIN_READINESS_READY
	return SEX_PAIN_READINESS_LOST

/datum/component/arousal/proc/get_resist_multiplier(passed_res)
	switch(passed_res)
		if(RESIST_NONE)
			return 1
		if(RESIST_LOW)
			return 0.7
		if(RESIST_MEDIUM)
			return 0.4
		if(RESIST_HIGH)
			return 0.2
	return 1

/datum/component/arousal/proc/get_force_orgasm_multiplier(passed_force, giving)
	switch(passed_force)
		if(SEX_FORCE_LOW)
			if(giving)
				return 0.4
			else
				return 0.4
		if(SEX_FORCE_MID)
			if(giving)
				return 0.8
			else
				return 0.6
		if(SEX_FORCE_HIGH)
			if(giving)
				return 1
			else
				return 0.8
		if(SEX_FORCE_EXTREME)
			if(giving)
				return 1.5
			else
				return 1
		if(SEX_FORCE_UNRELENTING)
			if(giving)
				return 2.0
			else
				return 1.2
	return 0.8

/datum/component/arousal/proc/handle_statuses()
	var/mob/living/user = parent
	var/nymph_mod = 0
	if(HAS_TRAIT(user, TRAIT_NYMPHO_CURSE) || user.has_quirk(/datum/quirk/negative/addiction/lovefiend))
		nymph_mod = ORGASM_STRAIN_NYMPH_THRESHOLD_MOD

	if(user.has_status_effect(/datum/status_effect/debuff/loinspent))
		if(orgasm_strain <= LOW_ORGASM_STRAIN_LOSS + nymph_mod)
			user.remove_status_effect(/datum/status_effect/debuff/loinspent)
	else
		if(orgasm_strain >= LOW_ORGASM_STRAIN_GAIN + nymph_mod)
			user.apply_status_effect(/datum/status_effect/debuff/loinspent)

	if(user.has_status_effect(/datum/status_effect/debuff/cumbrained))
		if(orgasm_strain <= MED_ORGASM_STRAIN_LOSS + nymph_mod)
			user.remove_status_effect(/datum/status_effect/debuff/cumbrained)
	else
		if(orgasm_strain >= MED_ORGASM_STRAIN_GAIN + nymph_mod)
			user.apply_status_effect(/datum/status_effect/debuff/cumbrained)

	if(user.has_status_effect(/datum/status_effect/debuff/orgasmbroken))
		if(orgasm_strain <= HIGH_ORGASM_STRAIN_LOSS + nymph_mod)
			user.remove_status_effect(/datum/status_effect/debuff/orgasmbroken)
	else
		if(orgasm_strain >= HIGH_ORGASM_STRAIN_GAIN + nymph_mod)
			user.apply_status_effect(/datum/status_effect/debuff/orgasmbroken)

	if(user.has_status_effect(/datum/status_effect/debuff/nympho_addiction))
		if(orgasm_strain <= OVER_THE_TOP_ORGASM_STRAIN_LOSS + nymph_mod)
			user.remove_status_effect(/datum/status_effect/debuff/nympho_addiction)
	else
		if(orgasm_strain >= OVER_THE_TOP_ORGASM_STRAIN_GAIN + nymph_mod)
			user.apply_status_effect(/datum/status_effect/debuff/nympho_addiction)

	if(user.has_real_penis())
		if(user.has_status_effect(/datum/status_effect/blue_balls))
			if(edging_charge <= 20)
				user.remove_status_effect(/datum/status_effect/blue_balls)
		else
			if(edging_charge >= 35)
				user.apply_status_effect(/datum/status_effect/blue_balls)
	if(user.has_vagina())
		if(user.has_status_effect(/datum/status_effect/blue_bean))
			if(edging_charge <= 20)
				user.remove_status_effect(/datum/status_effect/blue_bean)
		else
			if(edging_charge >= 35)
				user.apply_status_effect(/datum/status_effect/blue_bean)
	if(edging_charge > 75 && MOBTIMER_FINISHED(user, "edging_overstimulation", 5 MINUTES)) //this isn't how mob timers work
		MOBTIMER_SET(user, "edging_overstimulation")
		user.apply_status_effect(/datum/status_effect/edging_overstimulation)

	if(orgasm_progress > 85)
		if(!user.has_status_effect(/datum/status_effect/close_to_orgasm))
			user.apply_status_effect(/datum/status_effect/close_to_orgasm)
	else
		user.remove_status_effect(/datum/status_effect/close_to_orgasm)


/datum/component/arousal/proc/hole_before_insert_handle(datum/source, obj/item/item, hole_id, mob/living/inserter)
	//var/mob/living/user = parent
	if(istype(item, /obj/item/penis_fake)) //this is silly yes
		return
	adjust_arousal(source, 2)

/datum/component/arousal/proc/hole_before_remove_handle(datum/source, obj/item/item, hole_id, mob/living/inserter)
	//var/mob/living/user = parent
	if(istype(item, /obj/item/penis_fake)) //it's because of the hole system
		return
	adjust_arousal(source, 2)

/datum/component/arousal/proc/hole_after_insert_handle(datum/source, obj/item/item, hole_id, mob/living/inserter)
	//var/mob/living/user = parent
	if(istype(item, /obj/item/penis_fake)) //this is silly yes
		return
	adjust_arousal(source, 1)

/datum/component/arousal/proc/hole_after_remove_handle(datum/source, obj/item/item, hole_id, mob/living/inserter)
	//var/mob/living/user = parent
	if(istype(item, /obj/item/penis_fake)) //it's because of the hole system
		return
	adjust_arousal(source, 1)

/// Scales this mob's climax cooldown; 0 or less removes it.
/mob/living/proc/get_climax_cooldown_multiplier()
	return 1

/// Scales the orgasm progress this mob gains.
/mob/living/proc/get_orgasm_speed_multiplier()
	return 1

/// Force levels added to this mob's climax knot; above 0 the climax also cannot pull out.
/mob/living/proc/get_climax_knot_force_bonus(datum/sex_action/action)
	return 0

/datum/stress_event/blue_balls
	timer = 1.5 MINUTES
	stress_change = 2
	desc = span_red("My manhood aches!")

/datum/stress_event/blue_bean
	timer = 1 MINUTES
	stress_change = 2
	desc = span_red("My loins ache!")
