/datum/action/cooldown/spell/undirected/blessed_union
	name = "Blessed Union"
	desc = "Toggle. While active, each beat of an intimate act heals your partner's wounds and costs mana. Stops when your mana runs out or you enter combat mode."
	button_icon_state = "lesserheal"
	sound = 'sound/magic/heal.ogg'

	spell_type = SPELL_MANA
	associated_skill = /datum/attribute/skill/magic/holy
	antimagic_flags = MAGIC_RESISTANCE_HOLY
	has_visual_effects = FALSE

	charge_required = FALSE
	cooldown_time = 3 SECONDS
	// Paid per healing beat, not on toggle.
	spell_cost = 5

	/// Brute healed per beat before the holy skill bonus. Burn and wounds heal half.
	var/base_heal = 1
	/// Extra brute healed per beat for each holy skill rank.
	var/heal_per_rank = 1

/datum/action/cooldown/spell/undirected/blessed_union/Remove(mob/living/remove_from)
	if(istype(remove_from))
		remove_from.remove_status_effect(/datum/status_effect/blessed_union)
	return ..()

/datum/action/cooldown/spell/undirected/blessed_union/is_action_active(atom/movable/screen/movable/action_button/current_button)
	var/mob/living/caster = owner
	return istype(caster) && caster.has_status_effect(/datum/status_effect/blessed_union)

/datum/action/cooldown/spell/undirected/blessed_union/check_cost(cost_override, feedback = TRUE)
	// Toggle calls pass no override, so turning off is free; beats pass spell_cost and pay.
	var/mob/living/caster = owner
	if(isnull(cost_override) && istype(caster) && caster.has_status_effect(/datum/status_effect/blessed_union))
		return TRUE
	return ..()

/datum/action/cooldown/spell/undirected/blessed_union/before_cast(atom/cast_on)
	. = ..()
	. |= SPELL_NO_IMMEDIATE_COST
	var/mob/living/caster = owner
	if(caster.has_status_effect(/datum/status_effect/blessed_union))
		. |= SPELL_NO_FEEDBACK

/datum/action/cooldown/spell/undirected/blessed_union/cast(atom/cast_on)
	. = ..()
	var/mob/living/caster = owner
	if(caster.has_status_effect(/datum/status_effect/blessed_union))
		caster.remove_status_effect(/datum/status_effect/blessed_union)
		to_chat(caster, span_notice("I stop Blessed Union."))
		return
	caster.apply_status_effect(/datum/status_effect/blessed_union, null, src)
	to_chat(caster, span_notice("I start Blessed Union. My partners heal while we are intimate."))

/// Brute healed per beat for the current caster.
/datum/action/cooldown/spell/undirected/blessed_union/proc/get_beat_heal()
	var/mob/living/caster = owner
	return base_heal + heal_per_rank * floor(caster.get_skill_level(associated_skill))

/datum/status_effect/blessed_union
	id = "blessed_union"
	duration = STATUS_EFFECT_PERMANENT
	tick_interval = STATUS_EFFECT_NO_TICK
	alert_type = null
	/// The spell that started this effect; it sets the heal and mana cost.
	var/datum/weakref/spell_ref

/datum/status_effect/blessed_union/on_creation(mob/living/new_owner, duration_override, datum/action/cooldown/spell/undirected/blessed_union/source_spell)
	spell_ref = WEAKREF(source_spell)
	return ..()

/datum/status_effect/blessed_union/on_apply()
	if(!spell_ref?.resolve())
		return FALSE
	. = ..()
	RegisterSignal(owner, COMSIG_SEX_ACTION_TICK, PROC_REF(on_beat))

/datum/status_effect/blessed_union/on_remove()
	UnregisterSignal(owner, COMSIG_SEX_ACTION_TICK)
	var/datum/action/cooldown/spell/undirected/blessed_union/spell = spell_ref?.resolve()
	spell_ref = null
	spell?.build_all_button_icons()
	return ..()

/// Heals the partner of each act beat and pays the spell's mana cost. Must not sleep.
/datum/status_effect/blessed_union/proc/on_beat(datum/source, datum/sex_action/action, mob/living/action_user, mob/living/action_target)
	SIGNAL_HANDLER

	var/datum/action/cooldown/spell/undirected/blessed_union/spell = spell_ref?.resolve()
	if(!spell || spell.owner != owner)
		owner.remove_status_effect(type)
		return
	if(owner.cmode)
		to_chat(owner, span_warning("I ready for a fight and Blessed Union stops."))
		owner.remove_status_effect(type)
		return

	var/mob/living/partner = (action_user == owner) ? action_target : action_user
	if(!isliving(partner) || partner == owner || partner.stat == DEAD)
		return
	if(partner.mob_biotypes & MOB_UNDEAD)
		return
	if(partner.getBruteLoss() <= 0 && partner.getFireLoss() <= 0 && !length(partner.get_wounds()))
		return
	if(!spell.check_cost(spell.spell_cost, FALSE))
		to_chat(owner, span_warning("My mana runs out and Blessed Union stops."))
		owner.remove_status_effect(type)
		return

	var/heal = spell.get_beat_heal()
	partner.heal_wounds(heal * 0.5)
	partner.heal_overall_damage(heal, heal * 0.5, updating_health = TRUE)
	spell.invoke_cost()
	if(prob(10))
		to_chat(partner, span_green("A gentle warmth from [owner] eases my wounds."))
