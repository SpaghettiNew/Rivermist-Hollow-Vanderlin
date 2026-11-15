/// Orders diagnosis consistently so automatic and test-driven treatment never depends on status-list order.
/proc/cmp_defeat_trauma_label_asc(datum/status_effect/debuff/defeat/first, datum/status_effect/debuff/defeat/second)
	return sorttext(second.trauma_label, first.trauma_label)

/// Field cures lift the heaviest burden first; equal severities fall back to the stable label order.
/proc/cmp_defeat_trauma_severity_desc(datum/status_effect/debuff/defeat/first, datum/status_effect/debuff/defeat/second)
	var/rank_difference = defeat_severity_rank(second.severity) - defeat_severity_rank(first.severity)
	if(rank_difference)
		return rank_difference
	return cmp_defeat_trauma_label_asc(first, second)

/proc/defeat_training_rank_label(rank)
	switch(rank)
		if(SKILL_RANK_NOVICE)
			return "Novice"
		if(SKILL_RANK_APPRENTICE)
			return "Apprentice"
		if(SKILL_RANK_JOURNEYMAN)
			return "Journeyman"
		if(SKILL_RANK_EXPERT)
			return "Expert"
		if(SKILL_RANK_MASTER)
			return "Master"
	return "Legendary"

/// Station rules shown on every trauma alert. Built from the station providers themselves so the
/// training, cost and time players read never drift from what the stations enforce.
/proc/defeat_station_treatment_text(datum/status_effect/debuff/defeat/trauma)
	var/static/list/station_providers
	if(!station_providers)
		station_providers = list(
			new /datum/defeat_trauma_provider/medical/machine,
			new /datum/defeat_trauma_provider/shrine/structure,
		)
	var/list/rules = list()
	for(var/datum/defeat_trauma_provider/provider as anything in station_providers)
		if(provider.can_target_trauma(trauma))
			rules += provider.station_rule_text(trauma)
	if(!length(rules))
		return "No treatment station accepts it."
	return rules.Join(" ")

/// Contract shared by clinic care, shrines, tools, spells, and reagents. A provider diagnoses all
/// compatible traumas, selects one exact status datum, validates it before and after the delay, pays
/// only after success is certain, and removes only that selected datum.
/datum/defeat_trauma_provider
	var/name = "trauma treatment"
	var/provider_tag = DEFEAT_TRAUMA_PROVIDER_UNIVERSAL
	/// Legacy treatment identifier carried by COMSIG_LIVING_DEFEAT_TREATED.
	var/treatment_type = DEFEAT_TREATMENT_UNIVERSAL
	var/list/accepted_categories = list(
		DEFEAT_TRAUMA_CATEGORY_PHYSICAL,
		DEFEAT_TRAUMA_CATEGORY_SPIRITUAL,
	)
	var/list/allowed_trauma_types
	var/requires_adjacent = FALSE
	var/required_area_type
	/// Falls back to each trauma's own skill requirement when the provider sets no training of its own.
	var/use_trauma_skill = FALSE
	/// Provider-owned training. When set it replaces the trauma's skill for every diagnosis.
	var/datum/attribute/skill/required_skill
	var/required_skill_rank = SKILL_RANK_NONE
	/// Holy devotion (TRAIT_HOLY) satisfies the training requirement on its own.
	var/holy_trait_qualifies = FALSE
	/// Stations remain usable without the listed training, but take longer.
	var/untrained_time_multiplier = 1
	/// Traumas outside this category cost and take off_specialty_multiplier times as long. Null means none.
	var/specialty_category
	var/off_specialty_multiplier = 2
	var/treatment_duration_override
	var/resource_cost_override = 0
	var/list/accepted_resource_types
	var/resource_unit_name = "resource unit"
	/// Player-facing station name used in trauma alerts; stations with a host use the host's own name.
	var/station_name
	var/datum/weakref/host_ref

/datum/defeat_trauma_provider/New(datum/host)
	. = ..()
	if(host)
		host_ref = WEAKREF(host)

/datum/defeat_trauma_provider/Destroy()
	host_ref = null
	return ..()

/datum/defeat_trauma_provider/proc/resolve_host()
	var/datum/host = host_ref?.resolve()
	if(QDELETED(host))
		return null
	return host

/datum/defeat_trauma_provider/proc/can_target_trauma(datum/status_effect/debuff/defeat/trauma)
	if(!istype(trauma))
		return FALSE
	if(!(trauma.trauma_category in accepted_categories))
		return FALSE
	if(!(provider_tag in trauma.accepted_provider_tags))
		return FALSE
	if(length(allowed_trauma_types))
		var/type_allowed = FALSE
		for(var/trauma_type in allowed_trauma_types)
			if(istype(trauma, trauma_type))
				type_allowed = TRUE
				break
		if(!type_allowed)
			return FALSE
	return TRUE

/datum/defeat_trauma_provider/proc/diagnose(mob/living/patient)
	var/list/diagnosed = list()
	if(!patient || QDELETED(patient))
		return diagnosed
	for(var/datum/status_effect/debuff/defeat/trauma as anything in patient.status_effects)
		if(can_target_trauma(trauma))
			diagnosed += trauma
	sortTim(diagnosed, GLOBAL_PROC_REF(cmp_defeat_trauma_label_asc))
	return diagnosed

/// Every defeat trauma the patient carries, including ones this provider cannot treat, so station
/// diagnosis can explain each blocked case instead of silently hiding it.
/datum/defeat_trauma_provider/proc/all_diagnoses(mob/living/patient)
	var/list/found = list()
	if(QDELETED(patient))
		return found
	for(var/datum/status_effect/debuff/defeat/trauma in patient.status_effects)
		found += trauma
	sortTim(found, GLOBAL_PROC_REF(cmp_defeat_trauma_label_asc))
	return found

/datum/defeat_trauma_provider/proc/select_target(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/exact_target, interactive = FALSE, obj/item/reserved_resource)
	if(QDELETED(patient) || QDELETED(helper))
		return null
	var/list/diagnosed = interactive ? usable_diagnoses(patient, helper, reserved_resource) : diagnose(patient)
	if(!length(diagnosed))
		return null
	var/datum/status_effect/debuff/defeat/selected
	if(exact_target)
		selected = (exact_target in diagnosed) ? exact_target : null
	else if(!interactive || length(diagnosed) == 1)
		selected = diagnosed[1]
	else
		var/list/options = list()
		var/list/label_counts = list()
		for(var/datum/status_effect/debuff/defeat/trauma as anything in diagnosed)
			var/base_label = treatment_summary(helper, trauma)
			label_counts[base_label] = (label_counts[base_label] || 0) + 1
			var/option_name = label_counts[base_label] == 1 ? base_label : "[base_label] ([label_counts[base_label]])"
			options[option_name] = trauma
		var/choice = input(helper, "Choose the exact trauma to treat.", name) as null|anything in options
		if(QDELETED(patient) || QDELETED(helper))
			return null
		selected = options[choice]
	if(QDELETED(selected) || selected.owner != patient)
		return null
	if(!interactive)
		return selected
	if(alert(helper, treatment_summary(helper, selected), "Confirm [name]", "Begin treatment", "Cancel") != "Begin treatment")
		return null
	if(QDELETED(patient) || QDELETED(helper) || QDELETED(selected) || selected.owner != patient)
		return null
	return selected

/datum/defeat_trauma_provider/proc/provider_location_text()
	var/atom/host = resolve_host()
	if(host)
		return "[host] in [get_area(host)]"
	if(required_area_type)
		return "the required treatment area"
	return "the patient's current location"

/datum/defeat_trauma_provider/proc/resource_cost_text(datum/status_effect/debuff/defeat/target)
	var/cost = resource_cost_for(target)
	if(cost <= 0)
		return "none"
	var/suffix = cost == 1 ? "" : "s"
	return "[cost] [resource_unit_name][suffix]"

/datum/defeat_trauma_provider/proc/training_skill(datum/status_effect/debuff/defeat/target)
	if(required_skill)
		return required_skill
	if(use_trauma_skill)
		return target.treatment_skill
	return null

/datum/defeat_trauma_provider/proc/training_rank(datum/status_effect/debuff/defeat/target)
	if(required_skill)
		return required_skill_rank
	return target.treatment_skill_requirement

/datum/defeat_trauma_provider/proc/has_training(mob/living/helper, datum/status_effect/debuff/defeat/target)
	var/skill = training_skill(target)
	if(!skill)
		return TRUE
	if(holy_trait_qualifies && HAS_TRAIT(helper, TRAIT_HOLY))
		return TRUE
	return GET_MOB_SKILL_VALUE_OLD(helper, skill) >= training_rank(target)

/datum/defeat_trauma_provider/proc/training_text(datum/status_effect/debuff/defeat/target)
	var/datum/attribute/skill/skill = training_skill(target)
	if(!skill)
		return "none"
	var/text = "[defeat_training_rank_label(training_rank(target))] [initial(skill.name)]"
	if(holy_trait_qualifies)
		text += " or holy devotion"
	if(untrained_time_multiplier > 1)
		text += " (without it, [untrained_time_multiplier]x treatment time)"
	return text

/datum/defeat_trauma_provider/proc/is_off_specialty(datum/status_effect/debuff/defeat/target)
	return specialty_category && target.trauma_category != specialty_category

/// Complete pre-channel disclosure used by the diagnosis list, the selection list and final confirmation.
/datum/defeat_trauma_provider/proc/treatment_summary(mob/living/helper, datum/status_effect/debuff/defeat/target)
	var/specialty_note = is_off_specialty(target) ? " Outside this provider's specialty: longer treatment and extra supplies." : ""
	var/remaining = target.duration == STATUS_EFFECT_PERMANENT ? "requires treatment" : DisplayTimeText(max(0, target.duration - world.time))
	return "[target.trauma_label] ([defeat_severity_label(target.severity)]) - [target.treatment_description][specialty_note] Natural recovery remaining: [remaining]. Treatment duration: [DisplayTimeText(treatment_time(helper, target))]. Cost: [resource_cost_text(target)]. Training: [training_text(target)]. Provider: [name] at [provider_location_text()]."

/// One line for trauma alerts and the recovery guide; the time shown is before any skill reduction.
/datum/defeat_trauma_provider/proc/station_rule_text(datum/status_effect/debuff/defeat/target)
	var/specialty_note = is_off_specialty(target) ? ", outside its specialty" : ""
	return "[capitalize(station_name || name)]: [training_text(target)], [resource_cost_text(target)], base [DisplayTimeText(treatment_time(null, target))][specialty_note]."

/// Candidates a specific provider can actually begin with right now. Used when several nearby
/// stations exist so callers never select an unusable first match.
/datum/defeat_trauma_provider/proc/usable_diagnoses(mob/living/patient, mob/living/helper, obj/item/reserved_resource)
	var/list/usable = list()
	for(var/datum/status_effect/debuff/defeat/trauma as anything in diagnose(patient))
		if(validate(patient, helper, trauma, reserved_resource))
			usable += trauma
	return usable

/// The first unmet requirement for treating target right now, as player-facing text, or null when
/// treatment can begin. validate() is exactly "no blocker".
/datum/defeat_trauma_provider/proc/treatment_blocker(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/target, obj/item/reserved_resource)
	if(QDELETED(patient) || patient.stat == DEAD)
		return "The patient cannot be treated."
	if(QDELETED(helper) || helper.stat == DEAD)
		return "The helper cannot give treatment."
	if(QDELETED(target) || target.owner != patient || !(target in patient.status_effects))
		return "This trauma is no longer present."
	if(!can_target_trauma(target))
		return "This provider cannot treat it."
	var/atom/host = resolve_host()
	if(host_ref && !host)
		return "The treatment station is gone."
	if(host)
		if(!helper.Adjacent(host))
			return "Positioning: stand beside [host]."
		if(!patient.Adjacent(host))
			return "Positioning: the patient must be beside [host]."
	else if(requires_adjacent && helper != patient && !helper.Adjacent(patient))
		return "Positioning: stand beside the patient."
	if(required_area_type && !istype(get_area(patient), required_area_type))
		return "Positioning: the patient must be in the required treatment area."
	if(untrained_time_multiplier <= 1 && !has_training(helper, target))
		return "Training: requires [training_text(target)]."
	if(reserved_resource && (QDELETED(reserved_resource) || helper.get_active_held_item() != reserved_resource))
		return "Supplies: keep the offering in my active hand."
	var/cost = resource_cost_for(target)
	if(cost <= 0)
		return null
	if(!reserved_resource)
		return "Supplies: hold [resource_cost_text(target)] in my active hand."
	if(!accepts_resource(reserved_resource))
		return "Supplies: [reserved_resource] is not accepted; hold [resource_cost_text(target)]."
	var/held_amount = resource_value(reserved_resource)
	if(held_amount < cost)
		return "Supplies: needs [resource_cost_text(target)], holding only [held_amount]."
	return null

/datum/defeat_trauma_provider/proc/validate(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/target, obj/item/reserved_resource)
	return !treatment_blocker(patient, helper, target, reserved_resource)

/// Helper may be null for the skill-free baseline shown in alerts and the recovery guide.
/datum/defeat_trauma_provider/proc/treatment_time(mob/living/helper, datum/status_effect/debuff/defeat/target)
	if(!isnull(treatment_duration_override))
		return treatment_duration_override
	var/duration = target.treatment_duration
	var/skill = training_skill(target)
	if(helper && skill)
		duration -= GET_MOB_SKILL_VALUE_OLD(helper, skill) * 0.5 SECONDS
	duration = max(2 SECONDS, duration)
	if(is_off_specialty(target))
		duration *= off_specialty_multiplier
	if(helper && untrained_time_multiplier > 1 && !has_training(helper, target))
		duration *= untrained_time_multiplier
	return duration

/datum/defeat_trauma_provider/proc/resource_cost_for(datum/status_effect/debuff/defeat/target)
	if(!isnull(resource_cost_override))
		return resource_cost_override
	var/cost = target.treatment_resource_cost * defeat_severity_rank(target.severity)
	if(is_off_specialty(target))
		cost *= off_specialty_multiplier
	return cost

/datum/defeat_trauma_provider/proc/has_resources_for(datum/status_effect/debuff/defeat/target, obj/item/reserved_resource)
	var/cost = resource_cost_for(target)
	if(cost <= 0)
		return TRUE
	if(reserved_resource)
		return accepts_resource(reserved_resource) && resource_value(reserved_resource) >= cost
	return FALSE

/datum/defeat_trauma_provider/proc/consume_resources(datum/status_effect/debuff/defeat/target, obj/item/reserved_resource)
	var/cost = resource_cost_for(target)
	if(cost <= 0)
		return TRUE
	if(reserved_resource)
		if(!accepts_resource(reserved_resource) || resource_value(reserved_resource) < cost)
			return FALSE
		if(istype(reserved_resource, /obj/item/coin))
			var/obj/item/coin/coins = reserved_resource
			if(coins.quantity == cost)
				qdel(coins)
			else
				coins.set_quantity(coins.quantity - cost)
			return TRUE
		if(istype(reserved_resource, /obj/item/natural/bundle/cloth/bandage))
			var/obj/item/natural/bundle/cloth/bandage/bandages = reserved_resource
			if(bandages.amount == cost)
				qdel(bandages)
			else
				bandages.amount -= cost
				bandages.update_bundle()
			return TRUE
		if(cost == 1)
			qdel(reserved_resource)
			return TRUE
		return FALSE
	return FALSE

/datum/defeat_trauma_provider/proc/perform_treatment_delay(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/target)
	var/duration = treatment_time(helper, target)
	if(duration <= 0)
		return TRUE
	return do_after(helper, duration, target = patient)

/datum/defeat_trauma_provider/proc/treat(mob/living/patient, mob/living/helper, datum/status_effect/debuff/defeat/exact_target, interactive = FALSE, skip_delay = FALSE, obj/item/reserved_resource)
	if(QDELETED(patient) || QDELETED(helper) || (reserved_resource && QDELETED(reserved_resource)))
		return FALSE
	var/datum/status_effect/debuff/defeat/target = select_target(patient, helper, exact_target, interactive, reserved_resource)
	if(!validate(patient, helper, target, reserved_resource))
		return FALSE
	if(!skip_delay && !perform_treatment_delay(patient, helper, target))
		return FALSE
	if(!validate(patient, helper, target, reserved_resource))
		return FALSE
	if(!consume_resources(target, reserved_resource))
		return FALSE
	qdel(target)
	SEND_SIGNAL(patient, COMSIG_LIVING_DEFEAT_TREATED, helper, treatment_type)
	on_treatment_complete(patient, helper)
	return TRUE

/// Called once after a successful treatment. Hosts override it for feedback such as visuals.
/datum/defeat_trauma_provider/proc/on_treatment_complete(mob/living/patient, mob/living/helper)
	return

/// Station click flow: pick an adjacent patient, report every trauma they carry (with the exact unmet
/// requirement for blocked ones), then treat the chosen one. offering is the active-hand item, if any;
/// it is only reserved, never spent, until treat() has passed its final validation.
/datum/defeat_trauma_provider/proc/station_interact(mob/living/helper, obj/item/offering)
	var/atom/host = resolve_host()
	if(!host || QDELETED(helper))
		return FALSE
	var/list/candidates = list()
	for(var/mob/living/candidate in view(1, host))
		if(candidate.stat != DEAD)
			candidates += candidate
	if(!length(candidates))
		to_chat(helper, span_warning("No living patient is beside [host]."))
		return FALSE
	var/mob/living/patient = candidates[1]
	if(length(candidates) > 1)
		patient = input(helper, "Who should [host] diagnose?", host.name) as null|anything in candidates
	host = resolve_host()
	if(!host || QDELETED(patient) || QDELETED(helper) || (offering && QDELETED(offering)))
		return FALSE
	var/list/traumas = all_diagnoses(patient)
	if(!length(traumas))
		to_chat(helper, span_notice("[host] finds no defeat aftermath on [patient]. It does not heal ordinary wounds or wake the defeated."))
		return FALSE
	var/list/report = list()
	var/list/options = list()
	for(var/datum/status_effect/debuff/defeat/trauma as anything in traumas)
		var/blocker = treatment_blocker(patient, helper, trauma, offering)
		report += "[treatment_summary(helper, trauma)] <b>[blocker ? "Blocked: [blocker]" : "Ready."]</b>"
		var/option_name = "[trauma.trauma_label] ([defeat_severity_label(trauma.severity)]) - [blocker ? "blocked" : "ready"]"
		if(options[option_name])
			option_name = "[option_name] ([length(options) + 1])"
		options[option_name] = trauma
	to_chat(helper, span_notice("<b>[host] diagnosis for [patient]:</b><br>[report.Join("<br>")]"))
	var/choice = input(helper, "Choose the exact trauma to treat. Blocked entries explain what is missing.", host.name) as null|anything in options
	if(!choice || QDELETED(patient) || QDELETED(helper) || !resolve_host())
		return FALSE
	var/datum/status_effect/debuff/defeat/selected = options[choice]
	var/blocker = treatment_blocker(patient, helper, selected, offering)
	if(blocker)
		to_chat(helper, span_warning("That treatment cannot begin. [blocker]"))
		return FALSE
	if(!treat(patient, helper, selected, interactive = TRUE, reserved_resource = offering))
		to_chat(helper, span_warning("The treatment was not completed. Nothing was consumed."))
		return FALSE
	helper.visible_message(span_notice("[helper] completes a focused treatment for [patient] at [host]."), span_notice("I ease one defeat trauma from [patient] at [host]."))
	return TRUE

/datum/defeat_trauma_provider/proc/accepts_resource(obj/item/resource)
	if(!resource)
		return FALSE
	for(var/resource_type in accepted_resource_types)
		if(istype(resource, resource_type))
			return TRUE
	return FALSE

/datum/defeat_trauma_provider/proc/resource_value(obj/item/resource)
	if(istype(resource, /obj/item/coin))
		var/obj/item/coin/coins = resource
		return coins.quantity
	if(istype(resource, /obj/item/natural/bundle/cloth/bandage))
		var/obj/item/natural/bundle/cloth/bandage/bandages = resource
		return bandages.amount
	return 1

/datum/defeat_trauma_provider/medical
	name = "medical trauma treatment"
	provider_tag = DEFEAT_TRAUMA_PROVIDER_MEDICAL
	treatment_type = DEFEAT_TREATMENT_MEDICAL
	accepted_categories = list(DEFEAT_TRAUMA_CATEGORY_PHYSICAL)
	requires_adjacent = TRUE
	use_trauma_skill = TRUE

/datum/defeat_trauma_provider/medical/clinic
	required_area_type = /area/indoors/town/clinic_large
	resource_cost_override = 0

/datum/defeat_trauma_provider/medical/tool
	resource_cost_override = 0
	treatment_duration_override = 0
	requires_adjacent = FALSE

/datum/defeat_trauma_provider/medical/compatibility
	resource_cost_override = 0
	treatment_duration_override = 0
	requires_adjacent = FALSE

/// The apparatus treats every trauma, including Convalescence. Physical aftermath is its specialty;
/// spiritual aftermath needs one extra bandage and takes twice as long. A full roll holds four.
/datum/defeat_trauma_provider/medical/machine
	station_name = "trauma treatment apparatus"
	accepted_categories = list(
		DEFEAT_TRAUMA_CATEGORY_PHYSICAL,
		DEFEAT_TRAUMA_CATEGORY_SPIRITUAL,
	)
	specialty_category = DEFEAT_TRAUMA_CATEGORY_PHYSICAL
	use_trauma_skill = FALSE
	required_skill = /datum/attribute/skill/misc/medicine
	required_skill_rank = SKILL_RANK_APPRENTICE
	untrained_time_multiplier = 2
	accepted_resource_types = list(/obj/item/natural/cloth/bandage, /obj/item/natural/bundle/cloth/bandage)
	resource_unit_name = "bandage"
	resource_cost_override = null

/datum/defeat_trauma_provider/medical/machine/resource_cost_for(datum/status_effect/debuff/defeat/target)
	if(!isnull(resource_cost_override))
		return resource_cost_override
	return target.treatment_resource_cost * defeat_severity_rank(target.severity) + (is_off_specialty(target) ? 1 : 0)

/datum/defeat_trauma_provider/shrine
	name = "spiritual trauma treatment"
	provider_tag = DEFEAT_TRAUMA_PROVIDER_SHRINE
	treatment_type = DEFEAT_TREATMENT_SPIRITUAL
	accepted_categories = list(DEFEAT_TRAUMA_CATEGORY_SPIRITUAL)
	requires_adjacent = TRUE
	use_trauma_skill = TRUE
	holy_trait_qualifies = TRUE

/datum/defeat_trauma_provider/shrine/church
	required_area_type = /area/indoors/town/church
	resource_cost_override = 0

/datum/defeat_trauma_provider/shrine/compatibility
	resource_cost_override = 0
	treatment_duration_override = 0
	requires_adjacent = FALSE

/// The shrine treats every trauma, including Convalescence. Spiritual aftermath is its specialty;
/// physical aftermath costs and takes twice as long. Novice Miracles or holy devotion is always required.
/datum/defeat_trauma_provider/shrine/structure
	station_name = "shrine of solace"
	accepted_categories = list(
		DEFEAT_TRAUMA_CATEGORY_PHYSICAL,
		DEFEAT_TRAUMA_CATEGORY_SPIRITUAL,
	)
	specialty_category = DEFEAT_TRAUMA_CATEGORY_SPIRITUAL
	use_trauma_skill = FALSE
	required_skill = /datum/attribute/skill/magic/holy
	required_skill_rank = SKILL_RANK_NOVICE
	untrained_time_multiplier = 2
	accepted_resource_types = list(/obj/item/coin/silver)
	resource_unit_name = "silver coin"
	resource_cost_override = null

/// Field cures: Mercy Draught doses and Bear Their Burden. Convalescence deliberately omits the
/// universal tag, so these never reach it. Automatic selection lifts the most severe trauma first.
/datum/defeat_trauma_provider/universal
	name = "universal trauma treatment"
	provider_tag = DEFEAT_TRAUMA_PROVIDER_UNIVERSAL
	resource_cost_override = 0
	treatment_duration_override = 0

/datum/defeat_trauma_provider/universal/diagnose(mob/living/patient)
	var/list/diagnosed = ..()
	sortTim(diagnosed, GLOBAL_PROC_REF(cmp_defeat_trauma_severity_desc))
	return diagnosed
