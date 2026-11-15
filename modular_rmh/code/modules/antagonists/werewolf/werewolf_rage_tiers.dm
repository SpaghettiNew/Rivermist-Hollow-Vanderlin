// Rage tier effects on the beast: Restless 25, Hungry 50, Rut 75, Frenzy 100.

/// Per-life-tick beast effects driven by rage; called only while transformed and not paralysed.
/datum/antagonist/werewolf/proc/handle_beast_rage_life(mob/living/carbon/human/current_body)
	var/datum/rage/werewolf/rage = current_body.rage_datum
	if(!istype(rage))
		return
	rage.sync_beast_effects()
	if(rage.check_rage(WW_RAGE_MEDIUM) && current_body.blood_volume > BLOOD_VOLUME_SURVIVE)
		for(var/datum/wound/wound as anything in current_body.get_wounds())
			wound.heal_wound(1.2)

/// TRUE while this beast is a transformed werewolf in rut.
/mob/living/carbon/human/species/werewolf/proc/is_in_werewolf_rut()
	var/datum/antagonist/werewolf/wolf = IS_WEREWOLF(src)
	return wolf?.transformed && has_status_effect(/datum/status_effect/werewolf_rut)

/mob/living/carbon/human/species/werewolf/get_climax_cooldown_multiplier()
	if(is_in_werewolf_rut())
		return 0
	return ..()

/mob/living/carbon/human/species/werewolf/get_orgasm_speed_multiplier()
	. = ..()
	if(is_in_werewolf_rut())
		. *= WW_RUT_ORGASM_SPEED_MULT

/mob/living/carbon/human/species/werewolf/get_climax_knot_force_bonus(datum/sex_action/action)
	. = ..()
	if(is_in_werewolf_rut())
		. += WW_RUT_KNOT_FORCE_BONUS

/mob/living/carbon/human/species/werewolf/werewolf_feed(mob/living/carbon/human/target, healing_amount = 10)
	var/datum/antagonist/werewolf/wolf = IS_WEREWOLF(src)
	if(wolf?.transformed && rage_datum?.check_rage(WW_RAGE_MEDIUM))
		healing_amount *= WW_HUNGRY_FEED_MULT
	return ..(target, healing_amount)

/// Werewolf rut: seed refills several times faster.
/datum/fluid_modifier/werewolf_rut
	affected_slots = list(ORGAN_SLOT_TESTICLES)
	rate_multiplier = WW_RUT_SEED_MULT

/// Rage 25: a quicker stride and a sharper nose.
/datum/status_effect/werewolf_restless
	id = "werewolf_restless"
	alert_type = null
	tick_interval = STATUS_EFFECT_NO_TICK
	effectedstats = list(STAT_SPEED = WW_RESTLESS_SPEED_BONUS)

/datum/status_effect/werewolf_restless/on_apply()
	. = ..()
	var/datum/action/cooldown/keen_nose/nose = locate() in owner.actions
	if(nose)
		nose.cooldown_time = initial(nose.cooldown_time) * WW_RESTLESS_NOSE_COOLDOWN_MULT

/datum/status_effect/werewolf_restless/on_remove()
	var/datum/action/cooldown/keen_nose/nose = locate() in owner.actions
	if(nose)
		nose.cooldown_time = initial(nose.cooldown_time)
	return ..()

/// Rage 75: faster seed and climaxes, rut musk, and every scene partner grows hotter.
/datum/status_effect/werewolf_rut
	id = "werewolf_rut"
	alert_type = /atom/movable/screen/alert/status_effect/buff/werewolf_rut
	tick_interval = WW_RUT_TICK_INTERVAL
	/// Ticks since the last pheromone pulse.
	var/ticks_since_pulse = 0

/datum/status_effect/werewolf_rut/on_apply()
	. = ..()
	owner.add_fluid_modifier(/datum/fluid_modifier/werewolf_rut, id)

/datum/status_effect/werewolf_rut/on_remove()
	owner.remove_fluid_modifier(/datum/fluid_modifier/werewolf_rut, id)
	return ..()

/datum/status_effect/werewolf_rut/tick()
	if(owner.stat == DEAD)
		return
	rouse_scene_partners()
	ticks_since_pulse++
	if(ticks_since_pulse >= WW_RUT_PULSE_TICKS)
		ticks_since_pulse = 0
		pulse_pheromones(owner, PHEROMONE_SCENT_RUT, "a rank, feral rut-musk")

/// Partners already in a scene with the beast get hotter; the scene itself is their consent.
/datum/status_effect/werewolf_rut/proc/rouse_scene_partners()
	var/datum/sex_scene/scene = owner.sex_scene
	if(!scene || QDELETED(scene))
		return
	for(var/mob/living/partner as anything in scene.participants)
		if(partner == owner || partner.stat == DEAD)
			continue
		SEND_SIGNAL(partner, COMSIG_SEX_ADJUST_AROUSAL, WW_RUT_PARTNER_AROUSAL)

/atom/movable/screen/alert/status_effect/buff/werewolf_rut
	name = "Rut"
	desc = "The beast is in rut. My seed comes fast, I climax without rest, and my knot ties rough."

/// Rage 100: a minute of mindless violence, then exhaustion.
/datum/status_effect/werewolf_frenzy
	id = "werewolf_frenzy"
	duration = WW_FRENZY_DURATION
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/buff/werewolf_frenzy
	examine_text = span_warning("SUBJECTPRONOUN froths in a mindless frenzy!")
	/// FALSE when untransforming cuts the frenzy short, so it ends without the exhaustion.
	var/aftermath = TRUE

/datum/status_effect/werewolf_frenzy/on_apply()
	. = ..()
	to_chat(owner, span_userdanger("FRENZY! The beast tears the reins from me!"))
	var/datum/action/cooldown/spell/howl = owner.get_spell(/datum/action/cooldown/spell/aoe/repulse/howl, TRUE)
	if(howl)
		howl.spell_cost = 0
		howl.StartCooldownSelf(0)
	RegisterSignal(owner, COMSIG_LIVING_COMBAT_KILL, PROC_REF(on_kill))

/datum/status_effect/werewolf_frenzy/on_remove()
	UnregisterSignal(owner, COMSIG_LIVING_COMBAT_KILL)
	var/datum/action/cooldown/spell/howl = owner.get_spell(/datum/action/cooldown/spell/aoe/repulse/howl, TRUE)
	if(howl)
		howl.spell_cost = initial(howl.spell_cost)
	if(aftermath && !QDELETED(owner) && owner.stat != DEAD)
		exhaust()
	return ..()

/datum/status_effect/werewolf_frenzy/tick()
	if(!owner.cmode && owner.stat == CONSCIOUS)
		owner.toggle_cmode()

/// The frenzy burns out: rage falls back and the beast reels.
/datum/status_effect/werewolf_frenzy/proc/exhaust()
	to_chat(owner, span_warning("The frenzy burns out and leaves me reeling."))
	var/mob/living/carbon/human/beast = owner
	var/datum/rage/beast_rage = istype(beast) ? beast.rage_datum : null
	if(beast_rage && beast_rage.rage > WW_FRENZY_AFTER_RAGE)
		beast_rage.update_rage(WW_FRENZY_AFTER_RAGE - beast_rage.rage)
	owner.Stun(WW_FRENZY_EXHAUSTION_STUN, ignore_canstun = TRUE)

/datum/status_effect/werewolf_frenzy/proc/on_kill(mob/living/source, mob/living/victim)
	SIGNAL_HANDLER
	if(victim != source)
		refresh_lunge()

/// Kills and climaxes inside make the lunge ready again.
/datum/status_effect/werewolf_frenzy/proc/refresh_lunge()
	var/datum/action/cooldown/spell/lunge = owner.get_spell(/datum/action/cooldown/spell/lunge, TRUE)
	// A zero cooldown can retrigger the spell, which may sleep; callers are signal handlers.
	if(lunge)
		INVOKE_ASYNC(lunge, TYPE_PROC_REF(/datum/action/cooldown, StartCooldownSelf), 0)

/atom/movable/screen/alert/status_effect/buff/werewolf_frenzy
	name = "Frenzy"
	desc = "Mindless fury. My terrifying howl is free, and every kill or breeding readies my lunge."

/// Rut quick-sex: mounts an adjacent partner through the scene controller, so every preference gate still applies.
/datum/action/cooldown/spell/werewolf_take
	name = "Take"
	desc = "Mount an adjacent partner from behind and take them roughly. Their preferences and body still decide."
	button_icon_state = "wolf_head"
	active_msg = "I pick a mate to take."
	deactive_msg = "I let the urge pass."

	spell_type = SPELL_RAGE
	associated_skill = null
	antimagic_flags = NONE
	spell_flags = SPELL_IGNORE_SPELLBLOCK
	has_visual_effects = FALSE
	charge_required = FALSE
	cooldown_time = WW_TAKE_COOLDOWN
	self_cast_possible = FALSE
	cast_range = 1

/datum/action/cooldown/spell/werewolf_take/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	return isliving(cast_on)

/datum/action/cooldown/spell/werewolf_take/before_cast(atom/cast_on)
	. = ..()
	if(. & SPELL_CANCEL_CAST)
		return
	// The cooldown only starts once a mount actually began.
	return . | SPELL_NO_IMMEDIATE_COOLDOWN

/datum/action/cooldown/spell/werewolf_take/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/beast = owner
	if(istype(beast) && beast.try_werewolf_take(cast_on))
		StartCooldown()

/// Mount actions to try on the target, best first.
/proc/get_werewolf_take_actions(mob/living/target)
	. = list()
	if(target.getorganslot(ORGAN_SLOT_VAGINA))
		. += /datum/sex_action/sex/vaginal
	. += /datum/sex_action/sex/anal

/// Why this mob cannot Take the target right now, or null when it may try.
/mob/living/carbon/human/proc/get_werewolf_take_refusal(mob/living/target)
	var/datum/antagonist/werewolf/wolf = IS_WEREWOLF(src)
	if(!wolf?.transformed)
		return "Only the beast can take a mate like this."
	if(!isliving(target) || target == src)
		return "There is no one to take."
	if(target.stat == DEAD)
		return "[target] is dead."
	if(!Adjacent(target))
		return "[target] is out of reach."
	if(!can_do_sex())
		return "I can't do this."
	if(!target.allows_player_erp_while_disconnected())
		return "[target] is away and does not allow this while disconnected."
	if(!target_allows_mob_erp_action(src, target, /datum/erp_preference/boolean/allow_mob_breeding))
		return "[target] does not want to be bred by beasts."
	return null

/// Starts a rough mount from behind on the target; returns the running action, or null when refused.
/mob/living/carbon/human/proc/try_werewolf_take(mob/living/target)
	var/refusal = get_werewolf_take_refusal(target)
	if(refusal)
		to_chat(src, span_warning(refusal))
		return null
	var/datum/sex_scene_controller/existing_controller = sex_scene?.get_controller(src)
	var/datum/sex_scene_controller/controller = open_sex_scene(target, FALSE)
	if(!controller)
		to_chat(src, span_warning(get_sex_scene_refusal(target)))
		return null
	var/previous_force = controller.force
	controller.set_current_force(max(previous_force, SEX_FORCE_HIGH))
	for(var/action_type in get_werewolf_take_actions(target))
		var/datum/sex_action/running = controller.get_active_action(action_type)
		if(running)
			to_chat(src, span_warning("I am already taking [target]."))
			return running
		var/datum/sex_action_proposal/proposal = controller.create_action_proposal(action_type, "werewolf_take")
		var/can_start = proposal?.can_start()
		qdel(proposal)
		if(!can_start)
			continue
		face_atom(target)
		visible_message(span_danger("[src] mounts [target] from behind!"), span_danger("I mount [target] from behind!"))
		var/datum/sex_action/started = controller.try_start_action(action_type, "werewolf_take")
		if(started)
			return started
	// Nothing would start: leave the scene as it was before the attempt.
	if(controller == existing_controller)
		controller.set_current_force(previous_force)
	else
		qdel(controller)
	to_chat(src, span_warning("I can't take [target] like this."))
	return null
