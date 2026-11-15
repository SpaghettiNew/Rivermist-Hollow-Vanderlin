#define FACELESS_ONE_JOB_TITLE "Faceless One"
#define OUTLAW_DECREE_COOLDOWN (5 MINUTES)

/proc/grant_outlaw_decree(mob/living/carbon/human/recipient)
	if(!istype(recipient))
		return

	var/datum/action/cooldown/outlaw_decree/existing_action = locate(/datum/action/cooldown/outlaw_decree) in recipient.actions
	if(existing_action)
		return

	var/datum/action/cooldown/outlaw_decree/outlaw_decree = new(recipient)
	outlaw_decree.Grant(recipient)

/proc/find_outlaw_target_by_name(target_name)
	for(var/mob/living/carbon/human/possible_target in GLOB.player_list)
		if(possible_target.real_name != target_name)
			continue
		return possible_target

/proc/is_exempt_from_outlaw_decree(mob/living/carbon/human/target_human)
	if(!istype(target_human))
		return FALSE

	return !!(locate(/datum/action/cooldown/outlaw_decree) in target_human.actions)

/proc/show_outlaw_status_failure(atom/feedback_source, failure_text)
	if(!feedback_source || !failure_text)
		return

	if(istype(feedback_source, /obj/structure/fake_machine/titan))
		var/obj/structure/fake_machine/titan/titan_machine = feedback_source
		titan_machine.say(failure_text)
		playsound(titan_machine, 'sound/misc/machineno.ogg', 100, FALSE, -1)
		return

	to_chat(feedback_source, span_warning(failure_text))

/proc/announce_outlaw_status_change(mob/living/carbon/human/authority, target_name, should_declare)
	if(!istype(authority))
		return

	if(should_declare)
		priority_announce("[target_name] has been declared an outlaw and must be captured or bred.", "[authority.real_name], The [authority.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")
		return

	priority_announce("[target_name] is no longer an outlaw in Rivermist Hollow lands.", "[authority.real_name], The [authority.get_role_title()] Decrees", 'sound/misc/alert.ogg', "Captain")

/proc/declare_outlaw_by_name(mob/living/carbon/human/authority, target_name, atom/feedback_source = authority)
	if(!istype(authority))
		return FALSE

	if(target_name in GLOB.outlawed_players)
		show_outlaw_status_failure(feedback_source, "That person is already an outlaw!")
		return FALSE

	var/mob/living/carbon/human/outlaw_target = find_outlaw_target_by_name(target_name)
	if(!istype(outlaw_target))
		show_outlaw_status_failure(feedback_source, "That person doesn't exist!")
		return FALSE

	if(outlaw_target.job == FACELESS_ONE_JOB_TITLE)
		show_outlaw_status_failure(feedback_source, "Who? That person doesn't exist!")
		return FALSE

	if(is_exempt_from_outlaw_decree(outlaw_target))
		show_outlaw_status_failure(feedback_source, "That person is exempt from outlaw decrees!")
		return FALSE

	GLOB.outlawed_players |= target_name
	announce_outlaw_status_change(authority, target_name, TRUE)
	return TRUE

/proc/pardon_outlaw_by_name(mob/living/carbon/human/authority, target_name, atom/feedback_source = authority)
	if(!istype(authority))
		return FALSE

	var/mob/living/carbon/human/outlaw_target = find_outlaw_target_by_name(target_name)
	if(is_exempt_from_outlaw_decree(outlaw_target))
		show_outlaw_status_failure(feedback_source, "That person is exempt from outlaw decrees!")
		return FALSE

	if(!(target_name in GLOB.outlawed_players))
		show_outlaw_status_failure(feedback_source, "That person is not an outlaw!")
		return FALSE

	GLOB.outlawed_players -= target_name
	announce_outlaw_status_change(authority, target_name, FALSE)
	return TRUE

/proc/toggle_outlaw_status_for_target(mob/living/carbon/human/authority, mob/living/carbon/human/target_human, atom/feedback_source = authority)
	if(!istype(authority))
		return FALSE

	if(!istype(target_human))
		show_outlaw_status_failure(feedback_source, "That person doesn't exist!")
		return FALSE

	if(is_exempt_from_outlaw_decree(target_human))
		show_outlaw_status_failure(feedback_source, "That person is exempt from outlaw decrees!")
		return FALSE

	var/target_name = target_human.real_name
	if(target_name in GLOB.outlawed_players)
		return pardon_outlaw_by_name(authority, target_name, feedback_source)

	if(!(target_human in GLOB.player_list))
		show_outlaw_status_failure(feedback_source, "That person doesn't exist!")
		return FALSE

	return declare_outlaw_by_name(authority, target_name, feedback_source)

/datum/action/cooldown/outlaw_decree
	name = "Outlaw Decree"
	desc = "Point at someone to declare them an outlaw, or pardon them if they already are one."
	button_icon_state = "recruit_bog"
	check_flags = AB_CHECK_CONSCIOUS
	click_to_activate = TRUE
	cooldown_time = OUTLAW_DECREE_COOLDOWN
	retrigger_after_cooldown = FALSE
	ranged_mousepointer = 'icons/effects/mousemice/human_looking.dmi'

/datum/action/cooldown/outlaw_decree/IsAvailable()
	. = ..()
	if(!.)
		return FALSE

	return ishuman(owner)

/datum/action/cooldown/outlaw_decree/Trigger(trigger_flags, atom/target)
	if(next_use_time > world.time)
		var/seconds_left = round((next_use_time - world.time) / 10)
		to_chat(owner, span_warning("You must wait [seconds_left] more seconds before issuing another outlaw decree."))
		return FALSE

	return ..()

/datum/action/cooldown/outlaw_decree/set_click_ability(mob/on_who)
	. = ..()
	if(!.)
		return FALSE

	to_chat(on_who, span_notice("Point at someone to decree their outlaw status."))
	return TRUE

/datum/action/cooldown/outlaw_decree/unset_click_ability(mob/on_who, refund_cooldown = TRUE)
	. = ..()
	if(!.)
		return FALSE

	if(refund_cooldown)
		to_chat(on_who, span_notice("You lower your hand."))

	return TRUE

/datum/action/cooldown/outlaw_decree/InterceptClickOn(mob/living/clicker, list/modifiers, atom/target)
	if(!IsAvailable())
		return FALSE
	if(!target)
		return FALSE
	if(!PreActivate(target))
		return FALSE

	if(unset_after_click)
		unset_click_ability(clicker, refund_cooldown = FALSE)
	clicker.next_click = world.time + click_cd_override
	return TRUE

/datum/action/cooldown/outlaw_decree/Activate(atom/target)
	if(!ishuman(owner))
		return FALSE

	if(!ishuman(target))
		to_chat(owner, span_warning("You can only decree the status of a person."))
		return FALSE

	var/mob/living/carbon/human/authority = owner
	var/mob/living/carbon/human/target_human = target
	if(!toggle_outlaw_status_for_target(authority, target_human, owner))
		return FALSE

	StartCooldown()
	return TRUE

#undef OUTLAW_DECREE_COOLDOWN
#undef FACELESS_ONE_JOB_TITLE
