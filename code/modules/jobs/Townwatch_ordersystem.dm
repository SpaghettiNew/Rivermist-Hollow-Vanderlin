/datum/town_watch_command_definition
	var/id
	var/name
	var/description

	// Radial presentation
	var/radial_icon_file
	var/radial_icon_state

	var/range = TOWNWATCH_COMMAND_RANGE

	// Effect
	var/duration = 30 SECONDS
	var/list/stat_modifiers = list()
	var/list/granted_traits = list()

	// Command voice/emote
	var/list/text_bank = list()
	var/command_emote

	// Recipient feedback
	var/target_message

/datum/town_watch_command_definition/attack
	id = TOWNWATCH_ORDER_ATTACK
	name = "Attack"
	description = "Orders nearby Town Watch to press the attack."

	radial_icon_file = 'modular_rmh/icons/hud/townwatch_commands.dmi'
	radial_icon_state = "attack"

	duration = 30 SECONDS

	stat_modifiers = list(
		"strength" = 2,
		"endurance" = 1
	)

	text_bank = list(
		"FORWARD!",
		"PRESS THE ATTACK!",
		"ENGAGE!",
		"TO ARMS!"
	)

	command_emote = "attack"

	target_message = "Your superior orders you to attack!"

/datum/town_watch_command_definition/movement
	id = TOWNWATCH_ORDER_MOVEMENT
	name = "Move!"
	description = "Orders a Town Watch member to move quickly."

	radial_icon_file = 'modular_rmh/icons/hud/townwatch_commands.dmi'
	radial_icon_state = "movement"

	duration = 15 SECONDS

	stat_modifiers = list(
		"speed" = 2
	)

	text_bank = list(
		"WITH ME!",
		"MOVE!",
		"ADVANCE!"
	)

	command_emote = "gogogo"

	target_message = "Your superior orders you to move!"

/datum/town_watch_command_definition/defense
	id = TOWNWATCH_ORDER_DEFENSE
	name = "Defend!"
	description = "Orders Town Watch to hold their ground."

	radial_icon_file = 'modular_rmh/icons/hud/townwatch_commands.dmi'
	radial_icon_state = "defense"

	duration = 45 SECONDS

	stat_modifiers = list(
		"perception" = 2,
		"endurance" = 1
	)

	text_bank = list(
	"HOLD!",
	"HOLD THE LINE!",
	"STAND FIRM!"
	)

	command_emote = "holdposition"

	target_message = "Your superior orders you to hold the line!"

/datum/town_watch_command_trait
	var/mob/living/carbon/human/owner
	var/authority_level = TOWNWATCH_COMMAND_MEMBER

	var/list/commands = list()

	var/datum/action/cooldown/spell/undirected/town_watch_command/action
	var/datum/radial_menu/persistent/command_menu
	var/datum/town_watch_command_targeter/targeter
	var/command_mode
	var/mob/living/carbon/human/targeted_recipient

/datum/town_watch_command_trait/proc/on_owner_qdeleting(datum/source)
	SIGNAL_HANDLER
	qdel(src)

/datum/action/cooldown/spell/undirected/town_watch_command
	name = "Issue Order"
	desc = "Issue an order to the Town Watch."
	background_icon = 'icons/mob/actions/roguespells.dmi'
	background_icon_state = "spell0"
	base_background_icon_state = "spell0"
	active_background_icon_state = "spell1"
	button_icon = 'icons/mob/actions/roguespells.dmi'
	button_icon_state = "command"
	check_flags = AB_CHECK_CONSCIOUS|AB_CHECK_PHASED
	cooldown_time = TOWNWATCH_TARGETED_COMMAND_COOLDOWN
	text_cooldown = TRUE
	spell_type = SPELL_MANA
	spell_cost = 0
	charge_required = FALSE
	click_to_activate = FALSE

	var/datum/town_watch_command_trait/command_trait

/datum/action/cooldown/spell/undirected/town_watch_command/IsAvailable()
	if(!command_trait || !command_trait.owner || !HAS_TRAIT(command_trait.owner, TRAIT_TOWNWATCH_COMMAND))
		return FALSE
	return ..()

/datum/action/cooldown/spell/undirected/town_watch_command/can_cast_spell(feedback = TRUE)
	if(!command_trait || !command_trait.owner || !HAS_TRAIT(command_trait.owner, TRAIT_TOWNWATCH_COMMAND))
		if(feedback && owner)
			owner.balloon_alert(owner, "I no longer have authority to issue orders.")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/undirected/town_watch_command/before_cast(atom/cast_on)
	. = ..()
	return SPELL_NO_IMMEDIATE_COOLDOWN

/datum/action/cooldown/spell/undirected/town_watch_command/cast(atom/cast_on)
	. = ..()

	if(!command_trait || !command_trait.owner || !HAS_TRAIT(command_trait.owner, TRAIT_TOWNWATCH_COMMAND))
		return FALSE

	if(command_trait.command_menu && !QDELETED(command_trait.command_menu))
		return FALSE

	command_trait.clear_pending_order()
	command_trait.open_command_mode_menu()
	return !!command_trait.command_menu

/datum/action/cooldown/spell/undirected/town_watch_command/Grant(mob/grant_to)
	. = ..()

	if(owner && !button_icon)
		button_icon = 'icons/mob/actions/roguespells.dmi'

	if(owner && !button_icon_state)
		button_icon_state = "command"

/datum/town_watch_command_trait/sergeant
	authority_level = TOWNWATCH_COMMAND_SERGEANT

/datum/town_watch_command_trait/captain
	authority_level = TOWNWATCH_COMMAND_CAPTAIN

/datum/town_watch_command_trait/New(mob/living/carbon/human/new_owner)
	. = ..()

	owner = new_owner

	if(owner)
		RegisterSignal(owner, COMSIG_PARENT_QDELETING, PROC_REF(on_owner_qdeleting))

	commands = list(
		new /datum/town_watch_command_definition/attack,
		new /datum/town_watch_command_definition/movement,
		new /datum/town_watch_command_definition/defense
	)

	action = new /datum/action/cooldown/spell/undirected/town_watch_command
	action.command_trait = src
	action.Grant(owner)


/datum/town_watch_command_trait/Destroy(force)
	close_command_menu()
	cleanup_targeter()
	if(owner)
		UnregisterSignal(owner, COMSIG_PARENT_QDELETING)
		if(action)
			action.Remove(owner)
		owner = null
	QDEL_NULL(action)
	commands = null
	command_mode = null
	targeted_recipient = null

	return ..()

/mob/living/carbon/human/proc/grant_town_watch_command(authority_level = null)
	if(isnull(authority_level))
		var/datum/job/J = mind?.assigned_role

		if(J?.parent_job)
			J = J.parent_job

		if(istype(J, /datum/job/watch_captain))
			authority_level = TOWNWATCH_COMMAND_CAPTAIN
		else if(istype(J, /datum/job/watch_sergeant))
			authority_level = TOWNWATCH_COMMAND_SERGEANT

	if(isnull(authority_level))
		return

	ADD_TRAIT(src, TRAIT_TOWNWATCH_COMMAND, TOWNWATCH_COMMAND_TRAIT_SOURCE)

	if(town_watch_command_trait)
		if(town_watch_command_trait.authority_level == authority_level)
			return town_watch_command_trait

		QDEL_NULL(town_watch_command_trait)

	var/trait_type

	if(authority_level == TOWNWATCH_COMMAND_CAPTAIN)
		trait_type = /datum/town_watch_command_trait/captain
	else if(authority_level == TOWNWATCH_COMMAND_SERGEANT)
		trait_type = /datum/town_watch_command_trait/sergeant
	else
		return

	town_watch_command_trait = new trait_type(src)
	return town_watch_command_trait

/mob/living/carbon/human/proc/remove_town_watch_command()
	if(town_watch_command_trait)
		QDEL_NULL(town_watch_command_trait)

	REMOVE_TRAIT(src, TRAIT_TOWNWATCH_COMMAND, TOWNWATCH_COMMAND_TRAIT_SOURCE)

/mob/living/carbon/human/proc/sync_town_watch_command()
	if(HAS_TRAIT(src, TRAIT_TOWNWATCH_COMMAND))
		if(!town_watch_command_trait)
			grant_town_watch_command()
		return

	if(town_watch_command_trait)
		QDEL_NULL(town_watch_command_trait)

/mob/living/carbon/human/proc/is_town_watch_member()
	if(!mind)
		return FALSE

	var/datum/job/J = mind.assigned_role
	if(!J)
		return FALSE

	if(J.parent_job)
		J = J.parent_job

	if(!(J.department_flag & TOWNWATCH))
		return FALSE

	return stat != DEAD

/mob/living/carbon/human/proc/get_town_watch_command_authority()
	if(!town_watch_command_trait)
		return TOWNWATCH_COMMAND_MEMBER

	return town_watch_command_trait.authority_level

/datum/town_watch_command_trait/proc/can_target(mob/living/carbon/human/target)
	if(!target || QDELETED(target) || target == owner)
		return FALSE

	if(!target.is_town_watch_member())
		return FALSE

	var/target_authority = target.get_town_watch_command_authority()

	// You may command people below your rank.
	if(target_authority >= authority_level)
		return FALSE

	return TRUE

/datum/town_watch_command_trait/proc/open_command_mode_menu()
	if(!owner || !owner.client)
		return

	if(command_menu && !QDELETED(command_menu))
		return

	command_menu = null

	var/list/choices = list()

	var/datum/radial_menu_choice/targeted = new
	targeted.name = "Targeted"
	targeted.info = "Issue an order to one Town Watch member."
	targeted.image = image('modular_rmh/icons/hud/townwatch_commands.dmi', "targeted")
	choices[TOWNWATCH_COMMAND_MODE_TARGETED] = targeted

	var/datum/radial_menu_choice/global_choice = new
	global_choice.name = "Global"
	global_choice.info = "Issue an order to nearby Town Watch members."
	global_choice.image = image('modular_rmh/icons/hud/townwatch_commands.dmi', "radial")
	choices[TOWNWATCH_COMMAND_MODE_GLOBAL] = global_choice

	var/menu_id = "townwatch_command_mode_[REF(owner)]"
	command_menu = show_radial_menu_persistent(owner, owner, choices, CALLBACK(src, TYPE_PROC_REF(/datum/town_watch_command_trait, command_mode_selected)), menu_id, 48, TRUE, "radial_slice")

/datum/town_watch_command_trait/proc/command_mode_selected(selected_mode, params)
	close_command_menu()

	if(!owner || !HAS_TRAIT(owner, TRAIT_TOWNWATCH_COMMAND))
		return

	if(!owner.is_town_watch_member())
		return

	switch(selected_mode)
		if(TOWNWATCH_COMMAND_MODE_TARGETED)
			command_mode = TOWNWATCH_COMMAND_MODE_TARGETED
			start_target_selection()

		if(TOWNWATCH_COMMAND_MODE_GLOBAL)
			command_mode = TOWNWATCH_COMMAND_MODE_GLOBAL
			open_command_menu()

/datum/town_watch_command_trait/proc/open_command_menu()
	if(!owner || !owner.client)
		return

	if(command_menu && !QDELETED(command_menu))
		return

	command_menu = null

	var/list/choices = list()

	for(var/datum/town_watch_command_definition/command as anything in commands)
		var/datum/radial_menu_choice/choice = new

		choice.name = command.name
		choice.info = command.description

		if(command.radial_icon_file && command.radial_icon_state)
			choice.image = image(command.radial_icon_file, command.radial_icon_state)

		choices[command] = choice

	var/menu_id = "townwatch_command_[REF(owner)]"
	command_menu = show_radial_menu_persistent(owner, owner, choices, CALLBACK(src, TYPE_PROC_REF(/datum/town_watch_command_trait, command_selected)), menu_id, 48, TRUE, "radial_slice")

/datum/town_watch_command_trait/proc/command_selected(datum/town_watch_command_definition/command, params)
	close_command_menu()

	if(!command)
		return

	if(!owner || !HAS_TRAIT(owner, TRAIT_TOWNWATCH_COMMAND))
		return

	if(!owner.is_town_watch_member())
		return

	switch(command_mode)
		if(TOWNWATCH_COMMAND_MODE_TARGETED)
			var/mob/living/carbon/human/chosen_target = targeted_recipient
			clear_pending_order()
			issue_command(command, chosen_target)

		if(TOWNWATCH_COMMAND_MODE_GLOBAL)
			clear_pending_order()
			issue_area_command(command)

		else
			clear_pending_order()

/datum/town_watch_command_targeter
	var/client/owner
	var/datum/town_watch_command_trait/command_trait

/datum/town_watch_command_targeter/New(client/new_owner, datum/town_watch_command_trait/new_trait)
	owner = new_owner
	command_trait = new_trait

	owner.mouse_pointer_icon = null
	owner.click_intercept = src

/datum/town_watch_command_targeter/proc/InterceptClickOn(mob/living/carbon/human/user, params, atom/target)
	if(!owner || !command_trait)
		cleanup()
		return TRUE

	var/list/modifiers = params2list(params)

	if(modifiers["right"])
		cleanup()
		return TRUE

	if(istype(target, /atom/movable/screen))
		cleanup()
		return TRUE

	if(!istype(target, /mob/living/carbon/human))
		cleanup()
		return TRUE

	var/mob/living/carbon/human/H = target
	if(H == user)
		cleanup()
		return TRUE

	var/datum/town_watch_command_trait/selected_trait = command_trait

	cleanup()
	selected_trait.command_target_selected(H)

	return TRUE

/datum/town_watch_command_targeter/proc/cleanup()
	if(owner)
		if(owner.click_intercept == src)
			owner.click_intercept = null

		owner.mouse_pointer_icon = null
		owner.mob?.update_mouse_pointer()

	owner = null
	command_trait = null

/datum/town_watch_command_trait/proc/can_replace_order(mob/living/carbon/human/target)
	var/datum/status_effect/buff/town_watch_order/current = target.has_status_effect(/datum/status_effect/buff/town_watch_order)

	if(!current)
		return TRUE

	return authority_level >= current.authority_level

/datum/town_watch_command_trait/proc/clear_pending_order()
	command_mode = null
	targeted_recipient = null
	cleanup_targeter()

/datum/town_watch_command_trait/proc/command_target_selected(mob/living/carbon/human/target)
	if(command_mode != TOWNWATCH_COMMAND_MODE_TARGETED)
		return FALSE

	if(!owner || !target)
		clear_pending_order()
		return TRUE

	if(!HAS_TRAIT(owner, TRAIT_TOWNWATCH_COMMAND) || !owner.is_town_watch_member())
		clear_pending_order()
		return TRUE

	if(!can_target(target))
		to_chat(owner, span_warning("I cannot give orders to that person."))
		clear_pending_order()
		return TRUE

	if(get_dist(owner, target) > TOWNWATCH_COMMAND_RANGE)
		to_chat(owner, span_warning("That person is too far away to hear my order."))
		clear_pending_order()
		return TRUE

	targeted_recipient = target
	open_command_menu()
	return TRUE

/datum/town_watch_command_trait/proc/issue_command(datum/town_watch_command_definition/command, mob/living/carbon/human/target)
	if(!owner || !command || !target)
		return FALSE

	if(!HAS_TRAIT(owner, TRAIT_TOWNWATCH_COMMAND))
		return FALSE

	if(!owner.is_town_watch_member())
		return FALSE

	if(!owner.can_speak_vocal())
		to_chat(owner, span_warning("I cannot give orders without being able to speak."))
		return FALSE

	if(!can_target(target))
		to_chat(owner, span_warning("I cannot give orders to that person."))
		return FALSE

	if(!can_replace_order(target))
		to_chat(owner, span_warning("A superior's order is already in effect."))
		return FALSE

	if(get_dist(owner, target) > command.range)
		to_chat(owner, span_warning("That person is too far away to hear my order."))
		return FALSE

	var/datum/status_effect/buff/town_watch_order/effect = target.apply_status_effect(/datum/status_effect/buff/town_watch_order,src, command)

	if(!effect)
		return FALSE

	announce_command(command)
	action.StartCooldown(TOWNWATCH_TARGETED_COMMAND_COOLDOWN)
	return TRUE

/datum/town_watch_command_trait/proc/issue_area_command(datum/town_watch_command_definition/command)
	if(!owner || !command)
		return FALSE

	if(!HAS_TRAIT(owner, TRAIT_TOWNWATCH_COMMAND))
		return FALSE

	if(!owner.is_town_watch_member())
		return FALSE

	if(!owner.can_speak_vocal())
		to_chat(owner, span_warning("I cannot give orders without being able to speak."))
		return FALSE

	var/list/targets = list()

	for(var/mob/living/carbon/human/H in view(command.range, owner))
		if(!can_target(H))
			continue

		if(!can_replace_order(H))
			continue

		targets += H

	if(!length(targets))
		to_chat(owner, span_warning("There is nobody under my command nearby."))
		return FALSE

	var/applied = 0

	for(var/mob/living/carbon/human/H in targets)
		var/datum/status_effect/buff/town_watch_order/effect = H.apply_status_effect(/datum/status_effect/buff/town_watch_order, src, command)

		if(effect)
			applied++

	if(!applied)
		return FALSE

	announce_command(command)
	action.StartCooldown(TOWNWATCH_GLOBAL_COMMAND_COOLDOWN)

	return TRUE

/datum/town_watch_command_trait/proc/announce_command(datum/town_watch_command_definition/command)
	if(!owner || !command)
		return

	if(length(command.text_bank))
		owner.say(pick(command.text_bank))

	if(command.command_emote)
		owner.emote(command.command_emote)

/datum/status_effect/buff/town_watch_order
	id = "town_watch_order"
	status_type = STATUS_EFFECT_REPLACE
	alert_type = /atom/movable/screen/alert/status_effect/town_watch_order

	var/datum/town_watch_command_trait/issuer_trait
	var/mob/living/carbon/human/issuer
	var/datum/town_watch_command_definition/command
	var/authority_level

/datum/status_effect/buff/town_watch_order/on_creation(mob/living/carbon/human/new_owner, datum/town_watch_command_trait/new_issuer_trait, datum/town_watch_command_definition/new_command)
	issuer_trait = new_issuer_trait
	issuer = new_issuer_trait?.owner
	command = new_command

	if(issuer_trait)
		authority_level = issuer_trait.authority_level

	if(command)
		effectedstats = command.stat_modifiers.Copy()
		duration = command.duration

	. = ..()

	if(linked_alert && command)
		linked_alert.name = command.name
		linked_alert.desc = command.description

/datum/status_effect/buff/town_watch_order/on_apply()
	. = ..()

	if(!.)
		return FALSE

	if(command)
		for(var/trait in command.granted_traits)
			ADD_TRAIT(owner, trait, REF(src))

		if(command.target_message)
			to_chat(owner, span_blue(command.target_message))

	return TRUE

/datum/status_effect/buff/town_watch_order/on_remove()
	if(command)
		for(var/trait in command.granted_traits)
			REMOVE_TRAIT(owner, trait, REF(src))

	. = ..()

/atom/movable/screen/alert/status_effect/town_watch_order
	name = "Under Orders"
	desc = "A Town Watch superior has issued you an order."
	icon_state = "buff"

/datum/town_watch_command_trait/proc/close_command_menu()
	if(command_menu)
		if(!QDELETED(command_menu))
			qdel(command_menu)

	command_menu = null

/datum/town_watch_command_trait/proc/cleanup_targeter()
	if(targeter)
		targeter.cleanup()
		QDEL_NULL(targeter)

/datum/town_watch_command_trait/proc/start_target_selection()
	if(!owner?.client)
		return

	if(owner.client.click_intercept)
		to_chat(owner, span_warning("I am already selecting a target."))
		return

	cleanup_targeter()
	targeter = new /datum/town_watch_command_targeter(owner.client, src)

	to_chat(
		owner,
		span_notice("Select a Town Watch member to receive an order. Right click to cancel."))
