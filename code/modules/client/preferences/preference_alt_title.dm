/// Returns the ordinary title shown for a job before a player-selected alternative is applied.
/datum/preferences/proc/get_job_display_name(datum/job/job)
	if(!job)
		return ""
	return job.get_gendered_title(
		read_preference(/datum/preference/choiced/gender),
		read_preference(/datum/preference/choiced/pronouns),
	)

/// Returns the selectable values for one job-title category. All RMH alternatives are free.
/datum/preferences/proc/get_job_alt_choices(datum/job/job, category)
	var/list/raw_values = list()
	var/is_female = read_preference(/datum/preference/choiced/pronouns) == SHE_HER

	switch(category)
		if("title")
			raw_values += list(get_job_display_name(job))
			if(is_female && job.unique_alt_titles)
				raw_values += job.alt_titles_female
			else
				raw_values += job.alt_titles
		if("honorary")
			raw_values += list((is_female && job.honorary_f) ? job.honorary_f : (job.honorary || ""))
			if(is_female && job.unique_alt_honorary)
				raw_values += job.alt_honorary_female
			else
				raw_values += job.alt_honorary
		else
			return list()

	var/list/choices = list()
	for(var/value in raw_values)
		if(!istext(value))
			continue
		var/already_added = FALSE
		for(var/list/existing in choices)
			if(existing["value"] == value)
				already_added = TRUE
				break
		if(!already_added)
			choices += list(list("value" = value))
	return choices

/datum/preferences/proc/is_allowed_alt_job_value(datum/job/job, category, value)
	if(!job || !istext(value))
		return FALSE
	for(var/list/choice in get_job_alt_choices(job, category))
		if(choice["value"] == value)
			return TRUE
	return FALSE

/datum/preferences/proc/get_selected_job_alt_value(datum/job/job, category)
	var/list/choices = get_job_alt_choices(job, category)
	if(!length(choices))
		return ""
	var/default_value = choices[1]["value"]
	var/list/job_selection = alt_job_selections?[job.title]
	var/selected_value = job_selection?[category]
	if(is_allowed_alt_job_value(job, category, selected_value))
		return selected_value
	return default_value

/datum/preferences/proc/set_job_alt_preference(datum/job/job, category, value)
	if(!is_allowed_alt_job_value(job, category, value))
		return FALSE

	var/list/choices = get_job_alt_choices(job, category)
	var/default_value = choices[1]["value"]
	var/list/job_selection = alt_job_selections[job.title]
	if(!islist(job_selection))
		job_selection = list()
		alt_job_selections[job.title] = job_selection

	if(value == default_value)
		job_selection -= category
	else
		job_selection[category] = value

	if(!length(job_selection))
		alt_job_selections -= job.title
	return TRUE

/// Drops malformed or obsolete saved alternatives without tying them to the current pronouns.
/datum/preferences/proc/sanitize_alt_job_selections()
	if(!islist(alt_job_selections))
		alt_job_selections = list()
		return
	if(!SSjob)
		return

	for(var/job_title in alt_job_selections)
		var/datum/job/job = SSjob.GetJob(job_title)
		var/list/job_selection = alt_job_selections[job_title]
		if(!job || !islist(job_selection))
			alt_job_selections -= job_title
			continue

		var/list/all_titles = list(job.title)
		if(job.m_title)
			all_titles |= job.m_title
		if(job.f_title)
			all_titles |= job.f_title
		all_titles |= job.alt_titles
		all_titles |= job.alt_titles_female

		var/list/all_honoraries = list()
		if(job.honorary)
			all_honoraries |= job.honorary
		if(job.honorary_f)
			all_honoraries |= job.honorary_f
		all_honoraries |= job.alt_honorary
		all_honoraries |= job.alt_honorary_female

		if(job_selection["title"] && !(job_selection["title"] in all_titles))
			job_selection -= "title"
		if(job_selection["honorary"] && !(job_selection["honorary"] in all_honoraries))
			job_selection -= "honorary"
		if(!length(job_selection))
			alt_job_selections -= job_title

/// Applies only values valid for the character's current pronouns.
/datum/job/proc/apply_alt_title_preferences(mob/living/character, datum/preferences/preferences)
	character.job_title_override = null
	character.job_honorary_override = null
	if(!preferences)
		return

	var/datum/job/preference_job = src
	if(parent_job?.title in preferences.alt_job_selections)
		preference_job = parent_job
	var/list/job_selection = preferences.alt_job_selections?[preference_job.title]
	if(!islist(job_selection))
		return

	var/chosen_title = job_selection["title"]
	if(preferences.is_allowed_alt_job_value(preference_job, "title", chosen_title))
		character.job_title_override = chosen_title

	var/chosen_honorary = job_selection["honorary"]
	if(preferences.is_allowed_alt_job_value(preference_job, "honorary", chosen_honorary))
		character.job_honorary_override = chosen_honorary

/// Plain lock data for the integrated TGUI job tab.
/datum/preferences/proc/get_job_lock_data(datum/job/job, mob/user)
	if(!job || !user?.client)
		return list("label" = "UNAVAILABLE", "detail" = list("This role is unavailable."))

	if(!job.player_old_enough(user.client))
		var/days_left = job.available_in_days(user.client)
		return list(
			"label" = "ACCOUNT AGE",
			"detail" = list("Available in [days_left] day\s."),
		)

	if(CONFIG_GET(flag/usewhitelist) && job.whitelist_req && !user.client.whitelisted())
		return list(
			"label" = "SERVER WHITELIST",
			"detail" = list("This role requires the server whitelist."),
		)

	if(job.required_playtime_remaining(user.client))
		var/list/requirements = list()
		for(var/experience_type in job.exp_requirements)
			var/needed = job.exp_requirements[experience_type]
			var/have = user.client.calc_exp_type(experience_type)
			requirements += "[experience_type]: [get_exp_format(have)] / [get_exp_format(needed)]"
		return list("label" = "TIME LOCK", "detail" = requirements)

	if(!job.prefs_species_check(src) && !user.client.has_triumph_buy(TRIUMPH_BUY_RACE_ALL))
		var/list/allowed_races = job.allowed_races?.Copy() || list()
		for(var/blocked_race in job.blacklisted_species)
			allowed_races -= blocked_race
		return list(
			"label" = "SPECIES LOCK",
			"detail" = list("Species needed: [jointext(allowed_races, ", ")]."),
		)

	if(length(job.allowed_ages) && !(read_preference(/datum/preference/choiced/age) in job.allowed_ages))
		return list(
			"label" = "AGE LOCK",
			"detail" = list("Ages needed: [jointext(job.allowed_ages, ", ")]."),
		)

	if(length(job.allowed_sexes) && !(read_preference(/datum/preference/choiced/gender) in job.allowed_sexes))
		return list(
			"label" = "SEX LOCK",
			"detail" = list("Body types needed: [jointext(job.allowed_sexes, ", ")]."),
		)

	var/datum/patron/selected_patron = read_preference(/datum/preference/choiced/patron)
	if(length(job.allowed_patrons) && !(selected_patron?.type in job.allowed_patrons))
		var/list/patron_names = list()
		for(var/patron_type in job.allowed_patrons)
			var/datum/patron/patron = new patron_type
			patron_names += patron.display_name || patron.name
			qdel(patron)
		return list(
			"label" = "PATRON LOCK",
			"detail" = list("Patron needed: [jointext(patron_names, ", ")]."),
		)

	if(job.requires_job_whitelist() && !job.player_has_job_whitelist(user.client))
		return list(
			"label" = "ROLE WHITELIST",
			"detail" = list("This role requires its own whitelist."),
		)

	return null

/datum/preferences/proc/job_is_available(datum/job/job, mob/user)
	if(!job || !job.enabled || !(job.job_flags & JOB_NEW_PLAYER_JOINABLE))
		return FALSE
	if(job.spawn_positions <= 0)
		return FALSE
	if(is_race_banned(user.ckey, pref_species.id))
		return FALSE
	if(is_role_banned(user.ckey, job.title))
		return FALSE
	return !get_job_lock_data(job, user)

/// Job categories rarely change; they are sent as static data with the rest of character setup.
/datum/preferences/proc/character_setup_job_categories(mob/user)
	if(!SSjob)
		return list()

	var/list/category_sources = list(
		list("name" = "Lords", "jobs" = GLOB.lords_positions),
		list("name" = "The Keep", "jobs" = GLOB.keep_positions),
		list("name" = "Town Hall", "jobs" = GLOB.townhall_positions),
		list("name" = "Town Watch", "jobs" = GLOB.townwatch_positions),
		list("name" = "Chapel", "jobs" = GLOB.chapel_positions),
		list("name" = "Scholars", "jobs" = GLOB.scholars_positions),
		list("name" = "Traders", "jobs" = GLOB.traders_positions),
		list("name" = "Tavern", "jobs" = GLOB.tavern_positions),
		list("name" = "Towners", "jobs" = GLOB.town_positions),
		list("name" = "Outsiders", "jobs" = GLOB.outsiders_positions),
		list("name" = "Adventurers", "jobs" = GLOB.adventurers_positions),
		list("name" = "Villains", "jobs" = GLOB.villains_positions),
	)

	var/list/categories = list()
	for(var/list/category_source in category_sources)
		var/list/job_entries = list()
		var/category_color = "#dbdce3"
		for(var/job_title in category_source["jobs"])
			var/datum/job/job = SSjob.GetJob(job_title)
			if(!job || !job.enabled || !(job.job_flags & JOB_NEW_PLAYER_JOINABLE))
				continue
			if(job.spawn_positions <= 0)
				continue
			if(!length(job_entries))
				category_color = job.selection_color
			job_entries += list(list(
				"title" = job.title,
				"tutorial" = character_setup_chargen_clean_text(job.tutorial),
				"slots" = job.get_total_positions(),
				"title_choices" = get_job_alt_choices(job, "title"),
				"honorary_choices" = get_job_alt_choices(job, "honorary"),
				"has_info" = !!job.class_setup_examine,
				"details" = character_setup_job_details(job),
				"required_jobs" = job.get_required_job_titles(),
			))
		if(length(job_entries))
			categories += list(list(
				"name" = category_source["name"],
				"color" = category_color,
				"jobs" = job_entries,
			))
	return categories

/// Stat, trait and subclass facts for the role window, from the same sources as show_explain().
/datum/preferences/proc/character_setup_job_details(datum/job/job)
	var/list/details = list(
		"stats" = character_setup_stat_lines(job.jobstats),
		"stat_limits" = character_setup_stat_lines(job.stat_ceilings),
		"spell_points" = job.spell_points || 0,
		"traits" = character_setup_trait_lines(job.traits),
		"subclasses" = list(),
	)
	for(var/subclass_type in job.job_subclasses)
		var/datum/job/advclass/subclass_path = subclass_type
		var/datum/job/advclass/subclass = SSrole_class_handler?.get_advclass_by_name(initial(subclass_path.title))
		if(!subclass)
			continue
		var/list/languages = list()
		for(var/datum/language/language as anything in subclass.languages)
			languages += initial(language.name)
		details["subclasses"] += list(list(
			"title" = subclass.title,
			"tutorial" = character_setup_chargen_clean_text(subclass.tutorial, 700),
			"stats" = character_setup_stat_lines(subclass.jobstats),
			"spell_points" = subclass.spell_points || 0,
			"languages" = languages,
			"traits" = character_setup_trait_lines(length(subclass.traits) ? subclass.traits : job.traits),
			"skills" = character_setup_notable_skills(subclass.skills),
		))
	return details

/datum/preferences/proc/character_setup_stat_lines(list/stats)
	. = list()
	for(var/stat in stats)
		. += list(list("name" = capitalize(stat), "value" = stats[stat]))

/datum/preferences/proc/character_setup_trait_lines(list/traits)
	. = list()
	for(var/trait in traits)
		. += list(list("name" = trait, "desc" = character_setup_chargen_clean_text(GLOB.roguetraits[trait] || "", 400)))

/// The five best skills past journeyman plus every combat skill, as the old popup listed them.
/datum/preferences/proc/character_setup_notable_skills(list/skills)
	. = list()
	var/list/notable = list()
	for(var/skill_type in skills)
		if(skills[skill_type] > SKILL_LEVEL_JOURNEYMAN || ispath(skill_type, /datum/skill/combat))
			notable[skill_type] = skills[skill_type]
	notable = sortTim(notable, /proc/cmp_numeric_dsc, TRUE)
	var/shown = 0
	for(var/datum/skill/skill_type as anything in notable)
		if(shown++ >= 5)
			break
		. += list(list("name" = initial(skill_type.name), "level" = SSskills.level_names[notable[skill_type]]))

/datum/preferences/proc/character_setup_job_data(mob/user)
	var/list/data = list(
		"jobless_role" = read_preference(/datum/preference/choiced/joblessrole),
		"last_class" = lastclass,
		"job_changes_locked" = !!SSticker?.job_change_locked,
		"race_banned" = FALSE,
		"job_states" = list(),
	)
	if(!SSjob || !user?.client)
		return data

	data["race_banned"] = is_race_banned(user.ckey, pref_species.id)
	data["race_banned_name"] = pref_species.id
	if(data["race_banned"])
		return data

	var/list/job_states = list()
	for(var/job_title in get_job_assignment_order())
		var/datum/job/job = SSjob.GetJob(job_title)
		if(!job)
			continue

		var/list/job_state = list(
			"display_name" = get_job_display_name(job),
			"pref_level" = job_preferences[job.title],
			"current_title" = get_selected_job_alt_value(job, "title"),
			"current_honorary" = get_selected_job_alt_value(job, "honorary"),
		)
		if(is_role_banned(user.ckey, job.title))
			job_state["status"] = "banned"
		else
			var/list/lock_data = get_job_lock_data(job, user)
			if(lock_data)
				job_state["status"] = "locked"
				job_state["lock_label"] = lock_data["label"]
				job_state["lock_detail"] = lock_data["detail"]
			else
				job_state["status"] = "available"
		job_states[job.title] = job_state

	data["job_states"] = job_states
	return data
