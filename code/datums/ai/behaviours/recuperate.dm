#define DEFAULT_BLEED_CLOT 0.02
#define DEFAULT_BRUTE_HEAL 0.10
#define DEFAULT_FIRE_HEAL 1
#define DEFAULT_BLOOD_RECOVERY 5

/**
 * Behavior for mob sitting and healing bleed/brute. This does not recover blood, the mobs will still be vulnerable to being bled out.
 * todo: crix check heal_wounds, see if applicable
 */
/datum/ai_behavior/simple_rest_and_recuperate
	action_cooldown = 2 SECONDS
	behavior_flags = AI_BEHAVIOR_KEEP_MOVING_TOWARDS_TARGET_ON_FINISH


/datum/ai_behavior/simple_rest_and_recuperate/perform(seconds_per_tick, datum/ai_controller/controller, heal_message, bleed_clot, brute_heal)
	. = ..()
	var/mob/living/simple_animal/pawn = controller.pawn
	if(QDELETED(pawn) || pawn.doing()) //if doing something then skip
		return
	if(controller.is_in_combat())
		finish_action(controller, FALSE)
		return

	bleed_clot = isnum(bleed_clot) ? bleed_clot : DEFAULT_BLEED_CLOT
	brute_heal = isnum(brute_heal) ? brute_heal : DEFAULT_BRUTE_HEAL

	var/max_hp = pawn.maxHealth

	pawn.visible_message(span_danger("[pawn]"+heal_message))
	// A hit or a foe in reach stops the heal at once.
	var/healed = do_after(pawn, 8 SECONDS, target = pawn, extra_checks = CALLBACK(src, PROC_REF(is_calm), controller))
	if(QDELETED(controller))
		return
	if(healed)
		pawn.bleed_rate = pawn.bleed_rate - (max_hp * bleed_clot)
		pawn.bleed_rate = clamp(pawn.bleed_rate, 0, max_hp)
		pawn.adjustBruteLoss( (max_hp * -brute_heal) )
		pawn.health = clamp(pawn.health, 0, max_hp)
		pawn.adjust_fire_stacks(-DEFAULT_FIRE_HEAL)
		pawn.blood_volume += DEFAULT_BLOOD_RECOVERY
		pawn.blood_volume = clamp(pawn.blood_volume, 0, BLOOD_VOLUME_NORMAL)

	finish_action(controller, healed)

/datum/ai_behavior/simple_rest_and_recuperate/proc/is_calm(datum/ai_controller/controller)
	return !QDELETED(controller) && !controller.is_in_combat()

#undef DEFAULT_BLEED_CLOT
#undef DEFAULT_BRUTE_HEAL
#undef DEFAULT_FIRE_HEAL
#undef DEFAULT_BLOOD_RECOVERY
