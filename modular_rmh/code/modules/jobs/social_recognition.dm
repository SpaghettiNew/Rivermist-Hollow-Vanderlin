/*
 * ============================================================================
 * EXAMINE SOCIAL CONTEXT
 * ============================================================================
 */

/datum/examine_social_context
	var/mob/living/carbon/observer
	var/mob/living/carbon/target

	/* Objective target information. */
	var/datum/job/target_job
	var/target_wanted = FALSE

	/* Observer-visible information. */
	var/target_face_visible = FALSE
	var/identity_known = FALSE

	/* Visible social evidence. */
	var/list/visible_items = list()
	var/list/visible_social_cues = list()

	/* Universal visual status. */
	var/prestige_appearance_score = 0


/mob/living/carbon/proc/social_identity_is_known(mob/living/carbon/user)
	if(!user?.mind || !mind)
		return FALSE

	return user.mind.do_i_know(mind, real_name)


/mob/living/carbon/proc/build_social_context(mob/living/carbon/user)
	if(!user)
		return null

	var/datum/examine_social_context/context = new

	context.observer = user
	context.target = src
	context.target_job = mind?.assigned_role

	if(real_name)
		context.target_wanted = (real_name in GLOB.outlawed_players)

	/*
	 * Face visibility is an observation property.
	 * Non-human carbons do not go through human face-part visibility logic.
	 */
	context.target_face_visible = IsAdminGhost(user)

	if(ishuman(src))
		var/mob/living/carbon/human/H = src

		if(!context.target_face_visible)
			context.target_face_visible = is_human_part_visible(H, HIDEFACE)

		context.visible_items = H.get_unobscured_social_items()

		for(var/obj/item/I as anything in context.visible_items)
			if(!I)
				continue

			var/list/item_cues = I.get_social_cues()
			if(!length(item_cues))
				continue

			for(var/cue_key in item_cues)
				var/cue_value = item_cues[cue_key]

				if(isnull(cue_value) || !isnum(cue_value))
					continue

				if(isnull(context.visible_social_cues[cue_key]))
					context.visible_social_cues[cue_key] = cue_value
				else
					context.visible_social_cues[cue_key] += cue_value

	/*
	 * Identity knowledge is deliberately separate from faction knowledge.
	 */
	context.identity_known = social_identity_is_known(user)

	/*
	 * Generic prestige is generic evidence.
	 *
	 * Elite evidence also contributes to prestige, but only through the
	 * normalized elite:* namespace.
	 */
	var/generic_prestige = context.visible_social_cues["prestige"]

	if(isnum(generic_prestige))
		context.prestige_appearance_score = generic_prestige

	for(var/cue_key in context.visible_social_cues)
		if(!istext(cue_key))
			continue

		if(findtext(cue_key, "elite:") == 1)
			var/elite_value = context.visible_social_cues[cue_key]

			if(isnum(elite_value))
				context.prestige_appearance_score += elite_value

	return context


/mob/living/carbon/human/proc/get_unobscured_social_items()
	var/list/result = list()
	var/list/unobscured = get_unobscured_items(FALSE)

	for(var/obj/item/I as anything in unobscured)
		if(I)
			result += I

	/*
	 * Headgear is intentionally retained even when it contributes to face
	 * obstruction. It remains valid social evidence.
	 */
	var/obj/item/head_item = get_item_by_slot(ITEM_SLOT_HEAD)

	if(head_item && !(head_item in result))
		result += head_item

	return result


/*
 * ============================================================================
 * SOCIAL PROFILE
 * ============================================================================
 *
 * Item social_cues use namespaces. Examples:
 *
 *     social_cues = list("faction:town_watch" = 7)
 *     social_cues = list("elite:town_watch" = 5)
 *     social_cues = list("prestige" = 3)
 *
 * The item declares evidence. The profile decides what that evidence means.
 */

/datum/social_profile
	var/id
	var/display_name

	var/recognition_trait
	var/rank_trait
	var/specialization_trait

	var/local_faction_knowledge = TRUE

	var/faction_cue_key
	var/elite_cue_key

	var/list/apparent_rank_titles = list()
	var/list/apparent_specialization_titles = list()

	var/faction_threshold = 0
	var/faction_solid_threshold = 0

	var/elite_threshold = 0
	var/elite_solid_threshold = 0

	var/rank_threshold = 0
	var/specialization_threshold = 0

	var/face_required = FALSE

	var/list/elite_job_types = list()
	var/list/elite_recognition_job_types = list()

	var/faction_flag = 0


/datum/social_profile/proc/matches_target(mob/living/carbon/target)
	if(!faction_flag)
		return FALSE

	var/datum/job/J = target.mind?.assigned_role
	if(!J)
		return FALSE

	return !!(J.get_social_faction_flag() & faction_flag)


/datum/social_profile/proc/job_matches_any_type(datum/job/J, list/job_types)
	if(!J || !length(job_types))
		return FALSE

	for(var/job_type in job_types)
		if(J.social_is_or_inherits(job_type))
			return TRUE

	return FALSE


/datum/social_profile/proc/matches_elite_target(mob/living/carbon/target)
	var/datum/job/J = target.mind?.assigned_role
	return job_matches_any_type(J, elite_job_types)


/datum/social_profile/proc/get_cue_score(datum/examine_social_context/context, cue_key)
	if(!context || !cue_key)
		return 0

	var/value = context.visible_social_cues[cue_key]

	if(!isnum(value))
		return 0

	return max(value, 0)


/datum/social_profile/proc/get_best_mapped_cue(datum/examine_social_context/context, list/cue_titles)
	var/list/result = list("score" = 0, "title" = null, "key" = null, "conflict" = FALSE)

	if(!length(cue_titles))
		return result

	for(var/cue_key in cue_titles)
		var/cue_score = get_cue_score(context, cue_key)

		if(cue_score <= 0)
			continue

		if(cue_score > result["score"])
			result["score"] = cue_score
			result["title"] = cue_titles[cue_key]
			result["key"] = cue_key
			result["conflict"] = FALSE
			continue

		if(cue_score == result["score"] && cue_key != result["key"])
			result["conflict"] = TRUE

	return result


/datum/social_profile/proc/get_faction_appearance_score(datum/examine_social_context/context)
	if(!context || !faction_cue_key)
		return 0

	return get_cue_score(context, faction_cue_key)


/datum/social_profile/proc/get_elite_appearance_score(datum/examine_social_context/context)
	if(!context || !elite_cue_key)
		return 0

	return get_cue_score(context, elite_cue_key)


/datum/social_profile/proc/get_faction_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/datum/social_profile/proc/get_elite_appearance_modifier(datum/examine_social_context/context, datum/social_recognition/recognition)
	return 0


/datum/social_profile/proc/get_rank_appearance_score(datum/examine_social_context/context)
	var/list/result = get_best_mapped_cue(context, apparent_rank_titles)

	return result["score"]


/datum/social_profile/proc/get_specialization_appearance_score(datum/examine_social_context/context)
	var/list/result = get_best_mapped_cue(context, apparent_specialization_titles)

	return result["score"]


/datum/social_profile/proc/get_rank_appearance(datum/examine_social_context/context)
	return get_best_mapped_cue(context, apparent_rank_titles)


/datum/social_profile/proc/get_specialization_appearance(datum/examine_social_context/context)
	return get_best_mapped_cue(context, apparent_specialization_titles)


/datum/social_profile/proc/get_presentation_state(appearance_score)
	if(faction_solid_threshold > 0 && appearance_score >= faction_solid_threshold)
		return SOCIAL_PRESENTATION_CONVINCING

	if(faction_threshold > 0 && appearance_score >= faction_threshold)
		return SOCIAL_PRESENTATION_RECOGNIZABLE

	return SOCIAL_PRESENTATION_INSUFFICIENT


/datum/social_recognition
	var/datum/social_profile/profile

	/*
	 * Objective truth.
	 * These fields are INTERNAL ONLY.
	 * Description/reaction code must not reveal them directly.
	 */
	var/actual_faction = FALSE
	var/actual_elite = FALSE

	/*
	 * Observer knowledge.
	 */
	var/identity_recognized = FALSE
	var/known_faction = FALSE
	var/known_elite = FALSE
	var/known_rank = FALSE
	var/known_specialization = FALSE

	/*
	 * Visible inference.
	 */
	var/apparent_faction = FALSE
	var/apparent_elite_member = FALSE
	var/apparent_rank = FALSE
	var/apparent_specialization = FALSE
	var/elite_equipment_recognized = FALSE

	/*
	 * Selected visual candidates.
	 */
	var/apparent_rank_title
	var/apparent_specialization_title

	var/rank_presentation_conflict = FALSE
	var/specialization_presentation_conflict = FALSE

	/*
	 * Experienced observer contradictions.
	 */
	var/personnel_recognized = FALSE
	var/personnel_mismatch = FALSE
	var/elite_personnel_mismatch = FALSE

	/*
	 * Presentation.
	 */
	var/presentation_state = SOCIAL_PRESENTATION_INSUFFICIENT
	var/solid_faction = FALSE
	var/social_legitimacy = SOCIAL_LEGITIMACY_UNKNOWN

	/*
	 * Evidence scores.
	 */
	var/faction_appearance_score = 0
	var/elite_appearance_score = 0
	var/rank_appearance_score = 0
	var/specialization_appearance_score = 0
	var/prestige_appearance_score = 0

	/*
	 * Diagnostic/source bookkeeping.
	 */
	var/source = 0
	var/score = 0

	/*
	 * Compatibility flags.
	 *
	 * Keep these during migration. They should eventually become derived
	 * accessors or be deleted after the debug code has been migrated.
	 */
	var/faction_recognized = FALSE
	var/rank_recognized = FALSE
	var/specialization_recognized = FALSE

/datum/social_profile/proc/evaluate(mob/living/carbon/user, datum/examine_social_context/context)
	if(!user || !context || !context.target)
		return null

	var/datum/social_recognition/recognition = new
	recognition.profile = src

	/*
	 * ========================================================================
	 * OBJECTIVE TRUTH
	 * ========================================================================
	 */

	recognition.actual_faction = matches_target(context.target)
	recognition.actual_elite = matches_elite_target(context.target)

	/*
	 * ========================================================================
	 * IDENTITY
	 * ========================================================================
	 */

	if(context.identity_known)
		recognition.identity_recognized = TRUE
		recognition.source |= SOCIAL_SOURCE_IDENTITY

	/*
	 * ========================================================================
	 * APPEARANCE SCORES
	 * ========================================================================
	 */

	var/faction_modifier = get_faction_appearance_modifier(context, recognition)

	recognition.faction_appearance_score = max(get_faction_appearance_score(context) + faction_modifier, 0)

	var/elite_modifier = get_elite_appearance_modifier(context, recognition)

	recognition.elite_appearance_score = max(get_elite_appearance_score(context) + elite_modifier, 0)

	var/list/rank_appearance = get_rank_appearance(context)

	recognition.rank_appearance_score = rank_appearance["score"]
	recognition.apparent_rank_title = rank_appearance["title"]
	recognition.rank_presentation_conflict = rank_appearance["conflict"]

	var/list/specialization_appearance = get_specialization_appearance(context)

	recognition.specialization_appearance_score = specialization_appearance["score"]
	recognition.apparent_specialization_title = specialization_appearance["title"]
	recognition.specialization_presentation_conflict = specialization_appearance["conflict"]

	recognition.prestige_appearance_score = context.prestige_appearance_score

	/*
	 * ========================================================================
	 * FACTION PRESENTATION
	 * ========================================================================
	 */

	recognition.presentation_state = get_presentation_state(recognition.faction_appearance_score)

	recognition.solid_faction = (recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)

	if(local_faction_knowledge && faction_threshold > 0 && recognition.faction_appearance_score >= faction_threshold)
		recognition.apparent_faction = TRUE
		recognition.source |= SOCIAL_SOURCE_COSMETIC

	/*
	 * ========================================================================
	 * ELITE EQUIPMENT
	 * ========================================================================
	 */

	if(elite_threshold > 0 && recognition.elite_appearance_score >= elite_threshold)
		recognition.elite_equipment_recognized = TRUE
		recognition.source |= SOCIAL_SOURCE_ELITE | SOCIAL_SOURCE_COSMETIC

	/*
	 * ========================================================================
	 * PERSONNEL KNOWLEDGE
	 * ========================================================================
	 *
	 * A personnel trait identifies actual faction members.
	 *
	 * Face visibility is required for direct visual personnel identification.
	 * Known identity can independently establish the identity path.
	 */

	var/knows_personnel = (recognition_trait && HAS_CHARACTER_TRAIT(user, recognition_trait))

	if(knows_personnel)
		if(context.target_face_visible && recognition.actual_faction)
			recognition.personnel_recognized = TRUE
			recognition.known_faction = TRUE
			recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE

		else if(context.target_face_visible && recognition.apparent_faction && !recognition.actual_faction)
			recognition.personnel_mismatch = TRUE

	/*
	 * Identity-based faction knowledge.
	 *
	 * face_required applies here, not to the entire profile.
	 */
	var/identity_path_allowed = (!face_required || context.target_face_visible)

	if(identity_path_allowed && recognition.identity_recognized && recognition.actual_faction && knows_personnel)
		recognition.known_faction = TRUE
		recognition.personnel_recognized = TRUE
		recognition.source |= SOCIAL_SOURCE_PERSONNEL | SOCIAL_SOURCE_KNOWLEDGE

	/*
	 * Hidden/secret faction recognition.
	 *
	 * Wanted status is intentionally usable here because the observer's
	 * relevant knowledge represents recognition of the outlaw list.
	 */
	if(!local_faction_knowledge && knows_personnel && identity_path_allowed)
		if(recognition.actual_faction && (context.target_wanted || recognition.identity_recognized))
			recognition.known_faction = TRUE
			recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/*
	 * ========================================================================
	 * KNOWN RANK
	 * ========================================================================
	 */

	if(rank_trait && HAS_CHARACTER_TRAIT(user, rank_trait) && context.target_job && recognition.actual_faction && (recognition.identity_recognized || recognition.known_faction))
		recognition.known_rank = TRUE
		recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/*
	 * ========================================================================
	 * APPARENT RANK
	 * ========================================================================
	 *
	 * Rank is visual evidence. It does NOT require rank knowledge.
	 *
	 * The observer must either know the faction or have enough faction
	 * presentation to interpret the insignia.
	 */

	if((recognition.known_faction || recognition.apparent_faction) && rank_threshold > 0 && recognition.rank_appearance_score >= rank_threshold)
		if(!recognition.rank_presentation_conflict)
			recognition.apparent_rank = TRUE
			recognition.source |= SOCIAL_SOURCE_COSMETIC

	/*
	 * ========================================================================
	 * KNOWN SPECIALIZATION
	 * ========================================================================
	 */

	if(specialization_trait && HAS_CHARACTER_TRAIT(user, specialization_trait) && recognition.actual_faction && context.target.get_social_specialization() && (recognition.identity_recognized || recognition.known_faction))
		recognition.known_specialization = TRUE
		recognition.source |= SOCIAL_SOURCE_KNOWLEDGE

	/*
	 * ========================================================================
	 * APPARENT SPECIALIZATION
	 * ========================================================================
	 *
	 * Same principle as rank: it is visible evidence, not privileged
	 * knowledge.
	 */

	if(
		(recognition.known_faction || recognition.apparent_faction) && specialization_threshold > 0 && recognition.specialization_appearance_score >= specialization_threshold)
		if(!recognition.specialization_presentation_conflict)
			recognition.apparent_specialization = TRUE
			recognition.source |= SOCIAL_SOURCE_COSMETIC

	/*
	 * ========================================================================
	 * APPARENT ELITE MEMBER
	 * ========================================================================
	 *
	 * Elite equipment alone does not identify the wearer as elite.
	 */

	if(recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING && recognition.elite_equipment_recognized)
		if(elite_solid_threshold <= 0 || recognition.elite_appearance_score >= elite_solid_threshold)
			recognition.apparent_elite_member = TRUE

	/*
	 * ========================================================================
	 * ELITE PERSONNEL KNOWLEDGE
	 * ========================================================================
	 */

	var/datum/job/observer_job = user.mind?.assigned_role

	if(context.target_face_visible && job_matches_any_type(observer_job, elite_recognition_job_types))
		if(recognition.actual_elite)
			recognition.known_elite = TRUE
			recognition.known_faction = TRUE
			recognition.personnel_recognized = TRUE
			recognition.source |= \
				SOCIAL_SOURCE_PERSONNEL | \
				SOCIAL_SOURCE_KNOWLEDGE
		else if(recognition.apparent_elite_member)
			recognition.elite_personnel_mismatch = TRUE

	/*
	 * ========================================================================
	 * UNIVERSAL PRESTIGE
	 * ========================================================================
	 */

	if(recognition.prestige_appearance_score >= SOCIAL_PRESTIGE_THRESHOLD)
		recognition.source |= SOCIAL_SOURCE_PRESTIGE

	/*
	 * ========================================================================
	 * PRESENTATION LEGITIMACY
	 * ========================================================================
	 *
	 * This is INTERNAL evaluation only.
	 */

	recognition.social_legitimacy = SOCIAL_LEGITIMACY_UNKNOWN

	switch(recognition.presentation_state)
		if(SOCIAL_PRESENTATION_CONVINCING)
			if(recognition.actual_faction)
				recognition.social_legitimacy = SOCIAL_LEGITIMACY_SOLID
			else if(recognition.apparent_faction)
				recognition.social_legitimacy = SOCIAL_LEGITIMACY_DISGUISED

		if(SOCIAL_PRESENTATION_RECOGNIZABLE)
			if(recognition.actual_faction)
				recognition.social_legitimacy = SOCIAL_LEGITIMACY_PARTIAL
			else if(recognition.apparent_faction)
				recognition.social_legitimacy = SOCIAL_LEGITIMACY_SUSPICIOUS

	/*
	 * ========================================================================
	 * DEBUG / COMPATIBILITY SCORE
	 * ========================================================================
	 */

	recognition.score = max(recognition.faction_appearance_score, recognition.elite_appearance_score, recognition.rank_appearance_score, recognition.specialization_appearance_score, recognition.prestige_appearance_score)

	if(recognition.known_faction)
		recognition.score = max(recognition.score, 100)

	if(recognition.identity_recognized)
		recognition.score = max(recognition.score, 150)

	/*
	 * ========================================================================
	 * FINAL DERIVED FLAGS
	 * ========================================================================
	 */

	recognition.faction_recognized = (recognition.known_faction || recognition.apparent_faction)

	recognition.rank_recognized = (recognition.known_rank || recognition.apparent_rank)

	recognition.specialization_recognized = (recognition.known_specialization || recognition.apparent_specialization)

	/*
	 * ========================================================================
	 * KEEP / DISCARD
	 * ========================================================================
	 *
	 * Generic prestige is intentionally NOT enough to create a profile
	 * recognition. get_examine_social() handles generic prestige separately.
	 */

	if(!recognition.faction_recognized && !recognition.rank_recognized && !recognition.specialization_recognized && !recognition.elite_equipment_recognized && !recognition.apparent_elite_member && !recognition.personnel_mismatch && !recognition.elite_personnel_mismatch)
		qdel(recognition)
		return null

	return recognition


/*
 * ============================================================================
 * SOCIAL ADAPTERS
 * ============================================================================
 */

/mob/living/carbon/proc/get_social_specialization()
	if(!mind?.assigned_role)
		return null

	var/datum/job/job = mind.assigned_role
	var/title = job.get_informed_title(src)

	if(!title || title == "Unassigned")
		return null

	return title

/datum/job/proc/get_social_faction_flag()
	var/datum/job/J = src

	while(J)
		if(J.department_flag)
			return J.department_flag

		J = J.parent_job

	return 0

/mob/living/carbon/proc/get_social_base_job()
	var/datum/job/J = mind?.assigned_role

	while(J?.parent_job)
		J = J.parent_job

	return J

/datum/job/proc/social_is_or_inherits(typepath)
	var/datum/job/J = src

	while(J)
		if(istype(J, typepath))
			return TRUE

		J = J.parent_job

	return FALSE

/*
 * ============================================================================
 * PROFILE DESCRIPTION
 * ============================================================================
 */

/datum/social_profile/proc/get_elite_equipment_phrase()
	return "elite equipment associated with [display_name]"


/datum/social_profile/proc/get_description(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/P)
	var/primary_statement
	var/list/secondary_statements = list()
	var/datum/job/J = context.target_job
	var/rank_title
	var/specialization_title
	var/pl = p_s()

	/* Known information takes precedence over appearance. */
	if(recognition.known_faction)
		if(recognition.known_elite)
			if(recognition.known_rank && J)
				rank_title = J.get_informed_title(context.target)

			if(rank_title)
				primary_statement = "[P[THEYRE]] the [rank_title] of [display_name], one of the faction's elite"
			else
				primary_statement = "[P[THEYRE]] an elite member of [display_name]"

		else if(recognition.known_rank && J)
			rank_title = J.get_informed_title(context.target)

			if(rank_title)
				primary_statement = "[P[THEYRE]] the [rank_title] of [display_name]"
			else
				primary_statement = "[P[THEYRE]] a member of [display_name]"

		else
			primary_statement = "[P[THEYRE]] a member of [display_name]"

		/* Visible clothing can still be notably incomplete. */
		if(recognition.faction_appearance_score > 0 && recognition.presentation_state != SOCIAL_PRESENTATION_CONVINCING && !recognition.elite_equipment_recognized)
			secondary_statements += "[P[THEIR]] current attire is incomplete"

	/* Convincing visual faction presentation. */
	else if(recognition.apparent_faction && recognition.presentation_state == SOCIAL_PRESENTATION_CONVINCING)
		if(recognition.apparent_elite_member)
			primary_statement = "[P[THEY]] appear[pl] to be an elite member of [display_name]"
		else
			primary_statement = "[P[THEY]] appear[pl] to be a member of [display_name]"

	/* Recognizable but incomplete presentation. */
	else if(recognition.apparent_faction && recognition.presentation_state == SOCIAL_PRESENTATION_RECOGNIZABLE)
		primary_statement = "[P[THEYRE]] wearing [display_name] garb, but the presentation looks incomplete"

	/* Elite equipment remains independently visible. */
	if(recognition.elite_equipment_recognized && !recognition.apparent_elite_member)
		secondary_statements += "[P[THEYRE]] wearing [get_elite_equipment_phrase()]"

	/* Rank. */
	if(recognition.known_rank && !recognition.known_faction)
		rank_title = J?.get_informed_title(context.target)

		if(rank_title)
			secondary_statements += "[P[THEIR]] rank is known to be [rank_title]"

	else if(recognition.apparent_rank)
		if(recognition.apparent_rank_title)
			secondary_statements += \
				"[P[THEY]] appear[pl] to hold the rank of [recognition.apparent_rank_title]"

	else if(recognition.rank_presentation_conflict)
		secondary_statements += \
			"[P[THEIR]] rank insignia is contradictory"

	/* Specialization. */
	if(recognition.known_specialization)
		specialization_title = context.target.get_social_specialization()

		if(specialization_title)
			secondary_statements += \
				"[P[THEYRE]] known to specialize as [specialization_title]"

	else if(recognition.apparent_specialization)
		if(recognition.apparent_specialization_title)
			secondary_statements += \
				"[P[THEY]] appear[pl] to specialize as [recognition.apparent_specialization_title]"

	else if(recognition.specialization_presentation_conflict)
		secondary_statements += \
			"[P[THEIR]] specialization markings are contradictory"

	/* Experienced personnel contradiction overrides lesser secondary details. */
	if(recognition.elite_personnel_mismatch)
		secondary_statements = list("I don't recognize [P[THEM]] as one of the [display_name] elite")
	else if(recognition.personnel_mismatch)
		secondary_statements = list("I don't recognize [P[THEM]] as one of [display_name]")

	/* Universal prestige when no faction-specific statement explains it. */
	if(!primary_statement && !length(secondary_statements))
		if(context.prestige_appearance_score >= SOCIAL_PRESTIGE_THRESHOLD)
			primary_statement = "[P[THEY]] look[pl] unusually well-equipped"

	if(!primary_statement && !length(secondary_statements))
		return null

	/* Collapse all ordinary secondary observations into one response. */
	var/secondary_statement
	if(length(secondary_statements))
		secondary_statement = jointext(secondary_statements, " ")

	if(!secondary_statement)
		return "[primary_statement]."

	if(!primary_statement)
		return "[secondary_statement]."

	return "[primary_statement]. [secondary_statement]."
/*
 * ============================================================================
 * SOCIAL REACTIONS
 * ============================================================================
 */

/datum/examine_social_reaction
	var/stress_type
	var/list/phrases = list()


/datum/examine_social_reaction/proc/get_phrase()
	if(!length(phrases))
		return null
	return pick(phrases)


/*
 * ============================================================================
 * FACTION RELATIONSHIP DETERMINATION
 * ============================================================================

 *
 * Directional by design.
 */

/mob/living/carbon/proc/get_faction_relationship(mob/living/carbon/user, mob/living/carbon/target, user_faction, target_faction, datum/social_recognition/recognition = null)
	/* Directional faction rules must precede generic shared-bit alliance. */
	if((user_faction & TOWNWATCH) && (target_faction & VILLAINS))
		return SOCIAL_RELATION_HOSTILE

	if((user_faction & TOWNWATCH) && (target_faction & TOWNHALL))
		var/datum/job/target_authority = target?.mind?.assigned_role
		if(target_authority?.social_is_or_inherits(/datum/job/burgmeister))
			return SOCIAL_RELATION_LOYAL
		return SOCIAL_RELATION_PROTECT_DUTY

	if((user_faction & TOWNHALL) && (target_faction & VILLAINS))
		return SOCIAL_RELATION_DIPLOMATIC_HOSTILE

	if((user_faction & VILLAINS) && (target_faction & TOWNWATCH))
		return SOCIAL_RELATION_HOSTILE_TO_WATCH

	/* Civic administration and the Watch cooperate, but hold distinct authority. */
	if((user_faction & TOWNHALL) && (target_faction & TOWNWATCH))
		return SOCIAL_RELATION_SEPARATED_AUTHORITY

	/* Trade interests benefit from cooperation with the town's civic authority. */
	if((user_faction & TRADERS) && (target_faction & TOWNHALL))
		return SOCIAL_RELATION_COOPERATIVE

	if((user_faction & SCHOLARS) && (target_faction & CHAPEL))
		return SOCIAL_RELATION_TENSE

	if((user_faction & CHAPEL) && (target_faction & SCHOLARS))
		return SOCIAL_RELATION_DISAGREEING

	if((user_faction & TRADERS) && (target_faction & TAVERN))
		return SOCIAL_RELATION_TENSE

	/* Town Watch rank is directional: only a junior observer gets HIGHER_RANK. */
	if((user_faction & TOWNWATCH) && (target_faction & TOWNWATCH))
		var/datum/job/user_role = user?.mind?.assigned_role

		var/target_rank_title
		if(recognition?.known_rank)
			target_rank_title = recognition.known_rank
		else
			target_rank_title = recognition?.apparent_rank_title

		if(user_role)
			var/user_is_lower_watch = (
				user_role.social_is_or_inherits(/datum/job/watch_guard) \
				|| user_role.social_is_or_inherits(/datum/job/watch_veteran) \
				|| user_role.social_is_or_inherits(/datum/job/watch_warden))

			var/target_is_command_watch = target_rank_title in list("Town Watch Sergeant", "Town Watch Captain",)

			if(user_is_lower_watch && target_is_command_watch)
				return SOCIAL_RELATION_HIGHER_RANK

		return SOCIAL_RELATION_ALLIED

	/* Unknown-to-authority factions react fearfully to a recognized outlaw. */
	if((target_faction & VILLAINS) && !(user_faction & (TOWNWATCH | TOWNHALL | VILLAINS)))
		return SOCIAL_RELATION_FEARFUL

	if(user_faction & target_faction)
		return SOCIAL_RELATION_ALLIED

	return SOCIAL_RELATION_NEUTRAL


/datum/social_profile/proc/get_profile_faction_flag()
	return faction_flag

/*
 * ============================================================================
 * REACTION GENERATION
 * ============================================================================
 */

/datum/social_profile/proc/get_reactions(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/reactions)
	if(!recognition)
		return

	if(recognition.elite_personnel_mismatch || recognition.personnel_mismatch)
		var/datum/examine_social_reaction/wary_impostor = new
		wary_impostor.stress_type = /datum/stress_event/paranoia

		if(recognition.elite_personnel_mismatch)
			wary_impostor.phrases = list(
				"That's elite gear, but they're not one of the people who should be wearing it.",
				"I know who is supposed to hold that standing. This isn't one of them.",
				"Those are the marks of one of our elites. The person wearing them is not."
			)
		else
			wary_impostor.phrases = list(
				"I know my people. This isn't one of them.",
				"Something is wrong. I don't recognize this person as one of ours.",
				"That's our uniform, but not one of our people."
			)

		reactions += wary_impostor
		return

	if(recognition.social_legitimacy == SOCIAL_LEGITIMACY_SUSPICIOUS)
		var/datum/examine_social_reaction/suspicious_presentation = new
		suspicious_presentation.stress_type = /datum/stress_event/paranoia
		suspicious_presentation.phrases = list(
			"Something about their presentation doesn't add up.",
			"Something is wrong with the way they're presenting themselves.",
			"That isn't how this should look."
		)

		reactions += suspicious_presentation
		return

	/*
	 * Known outlaw identification is a phrase-only fallback. Do not return
	 * here: the observer's faction must still determine the directional
	 * reaction (e.g. Town Watch hostility or Town Hall diplomatic hostility).
	 */
	if(id == "outlaw" && recognition.known_faction)
		var/datum/examine_social_reaction/known_outlaw = new
		known_outlaw.phrases = list(
			"I'm certain they're an outlaw.",
			"I know what they are. An outlaw.",
			"That's an outlaw. I recognize them.",
			"There's no mistaking it. They're an outlaw."
		)
		reactions += known_outlaw

	if(!recognition.faction_recognized)
		return

	var/datum/job/user_role = user?.mind?.assigned_role
	var/user_faction = user_role?.get_social_faction_flag()
	var/target_faction = get_profile_faction_flag()

	if(!user_faction || !target_faction)
		return

	var/relationship = user.get_faction_relationship(user, src, user_faction, target_faction, recognition)

	/* Only relationships returned by get_faction_relationship have handlers. */
	switch(relationship)
		if(SOCIAL_RELATION_ALLIED)
			var/datum/examine_social_reaction/allied = new
			allied.stress_type = /datum/stress_event/fellow
			allied.phrases = list(
				"Good. I'm not the one here.",
				"It's always nice to feel that I have someone to rely on.",
				"Staying together is always better than working on my own here."
			)
			reactions += allied

		if(SOCIAL_RELATION_COOPERATIVE)
			var/datum/examine_social_reaction/cooperative = new
			cooperative.stress_type = /datum/stress_event/rely_on
			cooperative.phrases = list(
				"Better to work with them for my own interests.",
				"They'll protect me if we are on good terms, right?",
				"Great, someone who will help me if things get ugly."
			)
			reactions += cooperative

		if(SOCIAL_RELATION_PROTECT_DUTY)
			var/datum/examine_social_reaction/protect_duty = new
			protect_duty.phrases = list(
				"My job is to keep them safe.",
				"I'm paid to protect them.",
				"Best to be nearby in case of emergency."
			)
			reactions += protect_duty

		if(SOCIAL_RELATION_LOYAL)
			var/datum/examine_social_reaction/loyal = new
			loyal.phrases = list(
				"My job is to serve them.",
				"I should be ready to assist, if necessary.",
				"Should be ready to serve; that's why I'm here."
			)
			reactions += loyal

		if(SOCIAL_RELATION_HIGHER_RANK)
			var/datum/examine_social_reaction/higher_rank = new
			higher_rank.stress_type = /datum/stress_event/highrank_respect
			higher_rank.phrases = list(
				"At least someone to rely on.",
				"Better obey their orders; their rank is higher than mine.",
				"Good, someone actually viable here."
			)
			reactions += higher_rank

		if(SOCIAL_RELATION_SEPARATED_AUTHORITY)
			var/datum/examine_social_reaction/separated_authority = new
			separated_authority.phrases = list(
				"We have the same interests, but not jurisdictions.",
				"Someone has to keep an eye on the town, and someone stays in the dark forest.",
				"Only if we weren't separated..."
			)
			reactions += separated_authority

		if(SOCIAL_RELATION_TENSE)
			var/datum/examine_social_reaction/tense = new
			tense.stress_type = /datum/stress_event/tense
			tense.phrases = list(
				"We have different interests.",
				"I should be careful around them.",
				"Best to keep distance."
			)
			reactions += tense

		if(SOCIAL_RELATION_DIPLOMATIC_HOSTILE)
			var/datum/examine_social_reaction/diplomatic_hostile = new
			diplomatic_hostile.stress_type = /datum/stress_event/unease
			diplomatic_hostile.phrases = list(
				"Not a place for THEM.",
				"Better call someone who can get rid of this person.",
				"Best to stay aware with THOSE walking here."
			)
			reactions += diplomatic_hostile

		if(SOCIAL_RELATION_HOSTILE)
			var/datum/examine_social_reaction/hostile = new
			hostile.stress_type = /datum/stress_event/fearful
			hostile.phrases = list(
				"Trouble. I don't want them near me.",
				"I should keep my distance from them.",
				"Best not to draw their attention."
			)
			reactions += hostile

		if(SOCIAL_RELATION_HOSTILE_TO_WATCH)
			var/datum/examine_social_reaction/hostile_to_watch = new
			hostile_to_watch.stress_type = /datum/stress_event/outlaw_near_watch
			hostile_to_watch.phrases = list(
				"A lawman... What a day to live.",
				"I should be careful around those bastards.",
				"Better prepare myself if they are upon my track."
			)
			reactions += hostile_to_watch

		if(SOCIAL_RELATION_FEARFUL)
			var/datum/examine_social_reaction/fearful = new
			fearful.stress_type = /datum/stress_event/fearful
			fearful.phrases = list(
				"Damn it, don't wanna fall in their hands!",
				"What?! How did this person manage to GET here!?",
				"No, no, no, no, please tell me it's not them!"
			)
			reactions += fearful

		if(SOCIAL_RELATION_DISAGREEING)
			var/datum/examine_social_reaction/disagreeing = new
			disagreeing.phrases = list(
				"We have different ways to live this life.",
				"It's annoying to stay with someone who devoted their life to this.",
				"Why won't we get along?"
			)
			reactions += disagreeing

		if(SOCIAL_RELATION_NEUTRAL)
			return

/*
 * ============================================================================
 * GLOBAL PROFILE REGISTRY
 * ============================================================================
 */

GLOBAL_LIST_INIT(social_profiles, list(
	new /datum/social_profile/town_watch,
	new /datum/social_profile/town_hall,
	new /datum/social_profile/chapel,
	new /datum/social_profile/scholars,
	new /datum/social_profile/tavern,
	new /datum/social_profile/outlaw
))


/*
 * ============================================================================
 * RESOLVE ALL SOCIAL PROFILES
 * ============================================================================
 */

/mob/living/carbon/proc/resolve_social_profile(mob/living/carbon/user, datum/examine_social_context/context, datum/social_profile/profile)
	if(!profile)
		return null

	return profile.evaluate(user, context)

/mob/living/carbon/proc/get_social_recognitions(mob/living/carbon/user, datum/examine_social_context/context)
	var/list/recognitions = list()

	if(!user || !context)
		return recognitions

	for(var/datum/social_profile/profile as anything in GLOB.social_profiles)
		if(!profile)
			continue

		var/datum/social_recognition/recognition = \
			profile.evaluate(user, context)

		if(recognition)
			recognitions += recognition

	return recognitions


/*
 * ============================================================================
 * TOWN WATCH
 * ============================================================================
 */

/datum/social_profile/town_watch
	id = "town_watch"
	display_name = "the Town Watch"
	faction_flag = TOWNWATCH

	faction_cue_key = "faction:town_watch"
	elite_cue_key = "elite:town_watch"

	recognition_trait = TRAIT_KNOW_WATCH
	rank_trait = TRAIT_KNOW_WATCH_RANK
	specialization_trait = TRAIT_KNOW_WATCH_SPECIALIZATION

	faction_threshold = 10
	faction_solid_threshold = 15

	elite_threshold = 3
	elite_solid_threshold = 5

	rank_threshold = 3
	specialization_threshold = 3

	apparent_rank_titles = list(
		"rank:town_watch:captain" = "Town Watch Captain",
		"rank:town_watch:sergeant" = "Town Watch Sergeant",
		"rank:town_watch:warden" = "Town Watch Warden",
		"rank:town_watch:guard" = "Town Watch Guard"
	)

	apparent_specialization_titles = list(
		"specialization:prosecutor" = "Prosecutor",
		"specialization:executioner" = "Executioner",
		"specialization:Juggernaut" = "Juggernaut",
		"specialization:Charm" = "Charm of the corps"
	)

	elite_job_types = list(
		/datum/job/watch_captain,
		/datum/job/watch_sergeant,
		/datum/job/watch_warden
	)

	elite_recognition_job_types = list(
		/datum/job/burgmeister,
		/datum/job/watch_captain,
		/datum/job/watch_sergeant,
		/datum/job/watch_warden
	)

/*
 * ============================================================================
 * PUBLIC FACTIONS USED BY DIRECTIONAL RELATIONSHIP RULES
 * ============================================================================
 *
 * These profiles only become recognizable when visible equipment supplies the
 * matching faction cue. Add faction:<key> cues to the relevant items; objective
 * job assignment alone must not reveal faction membership.
 */

/datum/social_profile/town_hall
	id = "town_hall"
	display_name = "the Town Hall"
	faction_flag = TOWNHALL
	faction_cue_key = "faction:town_hall"
	faction_threshold = 10
	faction_solid_threshold = 15

/datum/social_profile/chapel
	id = "chapel"
	display_name = "the Chapel"
	faction_flag = CHAPEL
	faction_cue_key = "faction:chapel"
	faction_threshold = 10
	faction_solid_threshold = 15

/datum/social_profile/scholars
	id = "scholars"
	display_name = "the Scholars"
	faction_flag = SCHOLARS
	faction_cue_key = "faction:scholars"
	faction_threshold = 10
	faction_solid_threshold = 15

/datum/social_profile/tavern
	id = "tavern"
	display_name = "the Tavern"
	faction_flag = TAVERN
	faction_cue_key = "faction:tavern"
	faction_threshold = 10
	faction_solid_threshold = 15


/*
 * ============================================================================
 * OUTLAW
 * ============================================================================
 */

/datum/social_profile/outlaw
	id = "outlaw"
	display_name = "an outlaw"
	faction_flag = VILLAINS
	local_faction_knowledge = FALSE
	recognition_trait = TRAIT_KNOWBANDITS
	face_required = TRUE


/datum/social_profile/outlaw/matches_target(mob/living/carbon/target)
	return target.real_name in GLOB.outlawed_players


/datum/social_profile/outlaw/get_description(mob/living/carbon/user, datum/examine_social_context/context, datum/social_recognition/recognition, list/P)
	if(recognition.known_faction)
		return "[P[THEYRE]] an outlaw."

	return null

/*
 * ============================================================================
 * REACTION RESOLUTION
 * ============================================================================
 */

/mob/living/carbon/proc/resolve_strongest_social_reaction(mob/living/carbon/user, list/reactions)
	var/datum/examine_social_reaction/best_reaction
	var/best_strength = -INFINITY
	var/datum/examine_social_reaction/first_phrase_only

	for(var/datum/examine_social_reaction/reaction as anything in reactions)
		if(!reaction)
			continue

		if(!reaction.stress_type)
			if(!first_phrase_only)
				first_phrase_only = reaction
			continue

		if(user.has_stress_type(reaction.stress_type))
			continue

		var/datum/stress_event/event = new reaction.stress_type
		if(!event.can_apply(user))
			qdel(event)
			continue

		var/stress_value = event.get_stress(user)
		var/strength = abs(stress_value)
		if(strength > best_strength)
			best_strength = strength
			best_reaction = reaction

		qdel(event)

	if(best_reaction)
		return best_reaction

	return first_phrase_only


/*
 * ============================================================================
 * SOCIAL EXAMINE ENTRY POINT
 * ============================================================================
 */

/mob/living/carbon/proc/get_examine_social(mob/living/carbon/user, list/P, list/examine_list)
	. = list()

	if(user == src)
		return
	if(!isliving(user))
		return

	var/datum/examine_social_context/context = build_social_context(user)
	if(!context)
		return

	var/list/recognitions = get_social_recognitions(user, context)
	var/list/descriptions = list()

	for(var/datum/social_recognition/recognition as anything in recognitions)
		var/description = recognition.profile.get_description(user, context, recognition, P)
		if(description)
			descriptions += description

	/* Universal prestige, unless already expressed through elite equipment. */
	if(context.prestige_appearance_score >= SOCIAL_PRESTIGE_THRESHOLD)
		var/show_generic_prestige = TRUE
		for(var/datum/social_recognition/recognition as anything in recognitions)
			if(recognition.elite_equipment_recognized || recognition.apparent_elite_member)
				show_generic_prestige = FALSE
				break

		if(show_generic_prestige)
			descriptions += "[P[THEY]] look unusually well-equipped."

	/* De-duplicate descriptions. */
	for(var/description in descriptions)
		if(!description)
			continue
		if(description in .)
			continue
		. += description

	/* Reactions remain independent from recognition descriptions. */
	var/list/reactions = list()
	for(var/datum/social_recognition/recognition as anything in recognitions)
		recognition.profile.get_reactions(user, context, recognition, reactions)

	var/datum/examine_social_reaction/best_reaction = \
		resolve_strongest_social_reaction(user, reactions)

	if(best_reaction)
		var/phrase = best_reaction.get_phrase()
		if(phrase)
			. += phrase

		if(best_reaction.stress_type)
			user.add_stress(best_reaction.stress_type)
