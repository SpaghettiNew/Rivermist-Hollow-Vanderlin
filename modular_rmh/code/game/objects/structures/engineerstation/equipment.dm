// ============================================================================
// Technician Workshop equipment, service gates and station profiles.
// All state is owned by an individual workshop instance. This is deliberately
// separate from the customer's staged workpieces and depot resource stock.
// ============================================================================

#define TECH_STATION_SERVICE_CRAFTING "crafting"
#define TECH_STATION_SERVICE_METALWORKING "metalworking"
#define TECH_STATION_SERVICE_SMELTING "smelting"
#define TECH_STATION_SERVICE_SEWING "sewing"
#define TECH_STATION_FEE_SCOPE_SEWING_REPAIR "sewing_repair"

/// Recursively copies plain DM lists used by station profiles and JSON presets.
/// This prevents nested recipe/resource lists from leaking changes across machines.
/proc/technician_workshop_deep_copy(value)
	if(!islist(value))
		return value
	var/list/source = value
	// Copy() preserves both indexed and associative list entries. Only recurse
	// through associative values; a plain indexed list has no key/value child
	// mapping, and must remain an indexed list (e.g. list("hammer", "tongs")).
	var/list/copied = source.Copy()
	for(var/key in source)
		var/child_value = source[key]
		if(islist(child_value))
			copied[key] = technician_workshop_deep_copy(child_value)
	return copied

/// Mapper-selectable configuration. Set station_profile_type on a workstation
/// subtype to use a different profile. Each machine creates its own profile datum.
/datum/technician_station_profile
	abstract_type = /datum/technician_station_profile
	var/profile_name = "Unnamed technician station"

	/// Default service-fee switches. The "all" key is a master switch; individual
	/// service scopes can be disabled without changing recipe data or equipment.
	var/list/service_fee_enabled = list(
		"all" = TRUE,
		TECH_STATION_SERVICE_CRAFTING = TRUE,
		TECH_STATION_SERVICE_METALWORKING = TRUE,
		TECH_STATION_SERVICE_SMELTING = TRUE,
		TECH_STATION_SERVICE_SEWING = TRUE,
		TECH_STATION_FEE_SCOPE_SEWING_REPAIR = TRUE,
	)

	/// Mapper defaults applied once when the workstation is initialized.
	var/starting_budget = 0
	var/list/starting_resources = list()
	var/list/starting_equipment = list()
	var/technician_portrait_icon = ""

	/// Per-instance runtime configuration defaults. Values are serializable lists,
	/// not datums, so admins can save/load them as presets without mutating recipe
	/// definitions shared by other workstations.
	var/list/recipe_overrides = list()
	var/list/custom_recipes = list()

	/// Services which this profile permits the machine to offer at all.
	var/list/enabled_services = list(
		TECH_STATION_SERVICE_CRAFTING = TRUE,
		TECH_STATION_SERVICE_METALWORKING = TRUE,
		TECH_STATION_SERVICE_SMELTING = TRUE,
		TECH_STATION_SERVICE_SEWING = TRUE,
	)

	/// Slot availability is mapper-configurable. Installed tools in disabled slots
	/// remain physically stored but do not provide their bonuses or unlocks.
	var/list/enabled_equipment_slots = list(
		"hammer" = TRUE,
		"tongs" = TRUE,
		"crucible" = TRUE,
		"saw" = TRUE,
		"needle" = TRUE,
		"chisel" = TRUE,
	)

	/// Required installed slots for each service. Empty lists mean no tool gate.
	var/list/service_slot_requirements = list(
		TECH_STATION_SERVICE_CRAFTING = list(),
		TECH_STATION_SERVICE_METALWORKING = list("hammer", "tongs"),
		TECH_STATION_SERVICE_SMELTING = list("crucible"),
		TECH_STATION_SERVICE_SEWING = list("needle"),
	)

	/// Recipe categories can be gated without editing the UI. Specific recipes may
	/// instead set required_station_service on their recipe datum.
	var/list/recipe_category_services = list(
		"Punishment" = TECH_STATION_SERVICE_SEWING,
	)

	/// Maximum combined discount after all applicable equipment discounts multiply.
	/// The general cap is a safety net; a service-specific value takes precedence.
	var/list/fee_discount_caps = list(
		"general" = 40,
		TECH_STATION_SERVICE_CRAFTING = 40,
		TECH_STATION_SERVICE_METALWORKING = 40,
		TECH_STATION_SERVICE_SMELTING = 40,
		TECH_STATION_SERVICE_SEWING = 40,
	)

	/// Per-profile scaling for each slot's registered fee bonuses. 1 keeps the
	/// registry value; 0 disables the slot's discount; values above 1 amplify it.
	var/list/equipment_fee_discount_scales = list(
		"hammer" = 1, "tongs" = 1, "crucible" = 1,
		"saw" = 1, "needle" = 1, "chisel" = 1,
	)
	/// Per-profile scaling for deviations from a 1.0 work-time factor.
	var/list/equipment_work_time_scales = list(
		"hammer" = 1, "tongs" = 1, "crucible" = 1,
		"saw" = 1, "needle" = 1, "chisel" = 1,
	)


/datum/technician_station_profile/New()
	. = ..()
	// Profile datums are per-workstation. Copy configuration lists so a GM
	// changing one machine never mutates another machine's profile.
	enabled_services = enabled_services.Copy()
	enabled_equipment_slots = enabled_equipment_slots.Copy()
	service_fee_enabled = service_fee_enabled.Copy()
	starting_resources = technician_workshop_deep_copy(starting_resources)
	starting_equipment = starting_equipment.Copy()
	recipe_overrides = technician_workshop_deep_copy(recipe_overrides)
	custom_recipes = technician_workshop_deep_copy(custom_recipes)
	recipe_category_services = recipe_category_services.Copy()
	fee_discount_caps = fee_discount_caps.Copy()
	equipment_fee_discount_scales = equipment_fee_discount_scales.Copy()
	equipment_work_time_scales = equipment_work_time_scales.Copy()
	var/list/copied_requirements = list()
	for(var/service_id in service_slot_requirements)
		var/list/required_slots = service_slot_requirements[service_id]
		copied_requirements[service_id] = islist(required_slots) ? required_slots.Copy() : required_slots
	service_slot_requirements = copied_requirements

/datum/technician_station_profile/default
	profile_name = "Faction workshop"

/datum/technician_station_profile/metal_shop
	profile_name = "Metalworking shop"
	enabled_services = list(
		TECH_STATION_SERVICE_CRAFTING = TRUE,
		TECH_STATION_SERVICE_METALWORKING = TRUE,
		TECH_STATION_SERVICE_SMELTING = FALSE,
		TECH_STATION_SERVICE_SEWING = FALSE,
	)
	enabled_equipment_slots = list(
		"hammer" = TRUE,
		"tongs" = TRUE,
		"crucible" = FALSE,
		"saw" = TRUE,
		"needle" = FALSE,
		"chisel" = TRUE,
	)

/datum/technician_station_profile/smelting_bench
	profile_name = "Smelting bench"
	enabled_services = list(
		TECH_STATION_SERVICE_CRAFTING = TRUE,
		TECH_STATION_SERVICE_METALWORKING = FALSE,
		TECH_STATION_SERVICE_SMELTING = TRUE,
		TECH_STATION_SERVICE_SEWING = FALSE,
	)
	enabled_equipment_slots = list(
		"hammer" = FALSE,
		"tongs" = FALSE,
		"crucible" = TRUE,
		"saw" = FALSE,
		"needle" = FALSE,
		"chisel" = FALSE,
	)

/datum/technician_station_profile/tailor
	profile_name = "Tailor's workshop"
	enabled_services = list(
		TECH_STATION_SERVICE_CRAFTING = TRUE,
		TECH_STATION_SERVICE_METALWORKING = FALSE,
		TECH_STATION_SERVICE_SMELTING = FALSE,
		TECH_STATION_SERVICE_SEWING = TRUE,
	)
	enabled_equipment_slots = list(
		"hammer" = FALSE,
		"tongs" = FALSE,
		"crucible" = FALSE,
		"saw" = TRUE,
		"needle" = TRUE,
		"chisel" = FALSE,
	)

/// Registry entry for one exact tool tier. Add subtypes to extend the system
/// without editing workstation logic. Exact item paths prevent parent-type
/// matching from incorrectly giving an inferior tool a superior tier.
/datum/technician_station_equipment
	abstract_type = /datum/technician_station_equipment
	var/slot_id
	var/item_type
	var/display_name
	var/tier = 1
	/// Percent discount before multiplicative stacking; e.g. 8 means 8%.
	var/fee_discount_percent = 0
	/// "all" or a list of service IDs receiving this discount.
	var/list/fee_discount_services = list()
	/// Independent work-time factor. Factors from all applicable installed tools
	/// are multiplied together, never overwritten by the last equipment slot.
	var/work_time_multiplier = 1
	/// "all" or service IDs receiving this time factor.
	var/list/work_time_services = list()

/datum/technician_station_equipment/hammer/wood
	slot_id = "hammer"
	item_type = /obj/item/weapon/hammer/wood
	display_name = "Wooden mallet"
	tier = 1
	fee_discount_percent = 2
	fee_discount_services = list(TECH_STATION_SERVICE_METALWORKING)
	// Workshop-specific modifier; deliberately independent of the hammer's
	// original click/use delay multiplier. Higher tiers are faster.
	work_time_multiplier = 1.04
	work_time_services = list(TECH_STATION_SERVICE_METALWORKING)

/datum/technician_station_equipment/hammer/copper
	slot_id = "hammer"
	item_type = /obj/item/weapon/hammer/copper
	display_name = "Copper hammer"
	tier = 2
	fee_discount_percent = 4
	fee_discount_services = list(TECH_STATION_SERVICE_METALWORKING)
	work_time_multiplier = 1.02
	work_time_services = list(TECH_STATION_SERVICE_METALWORKING)

/datum/technician_station_equipment/hammer/iron
	slot_id = "hammer"
	item_type = /obj/item/weapon/hammer/iron
	display_name = "Iron hammer"
	tier = 3
	fee_discount_percent = 6
	fee_discount_services = list(TECH_STATION_SERVICE_METALWORKING)
	work_time_multiplier = 1.0
	work_time_services = list(TECH_STATION_SERVICE_METALWORKING)

/datum/technician_station_equipment/hammer/steel
	slot_id = "hammer"
	item_type = /obj/item/weapon/hammer/steel
	display_name = "Steel claw hammer"
	tier = 4
	fee_discount_percent = 8
	fee_discount_services = list(TECH_STATION_SERVICE_METALWORKING)
	work_time_multiplier = 0.98
	work_time_services = list(TECH_STATION_SERVICE_METALWORKING)

/datum/technician_station_equipment/tongs/stone
	slot_id = "tongs"
	item_type = /obj/item/weapon/tongs/stone
	display_name = "Stone tongs"
	tier = 1

/datum/technician_station_equipment/tongs/iron
	slot_id = "tongs"
	item_type = /obj/item/weapon/tongs
	display_name = "Iron tongs"
	tier = 2

/datum/technician_station_equipment/crucible/basic
	slot_id = "crucible"
	item_type = /obj/item/storage/crucible
	display_name = "Crucible"
	tier = 1

/datum/technician_station_equipment/saw/improvised
	slot_id = "saw"
	item_type = /obj/item/weapon/surgery/saw/improv
	display_name = "Improvised saw"
	tier = 1
	work_time_multiplier = 0.98
	work_time_services = list("all")

/datum/technician_station_equipment/saw/basic
	slot_id = "saw"
	item_type = /obj/item/weapon/surgery/saw
	display_name = "Saw"
	tier = 2
	work_time_multiplier = 0.96
	work_time_services = list("all")

/datum/technician_station_equipment/needle/thorn
	slot_id = "needle"
	item_type = /obj/item/needle/thorn
	display_name = "Thorn needle"
	tier = 1
	fee_discount_percent = 2
	fee_discount_services = list(TECH_STATION_FEE_SCOPE_SEWING_REPAIR)

/datum/technician_station_equipment/needle/basic
	slot_id = "needle"
	item_type = /obj/item/needle
	display_name = "Needle"
	tier = 2
	fee_discount_percent = 4
	fee_discount_services = list(TECH_STATION_FEE_SCOPE_SEWING_REPAIR)

/datum/technician_station_equipment/needle/blessed
	slot_id = "needle"
	item_type = /obj/item/needle/blessed
	display_name = "Blessed needle"
	tier = 3
	fee_discount_percent = 6
	fee_discount_services = list(TECH_STATION_FEE_SCOPE_SEWING_REPAIR)

/datum/technician_station_equipment/chisel/basic
	slot_id = "chisel"
	item_type = /obj/item/weapon/chisel
	display_name = "Chisel"
	tier = 1
	fee_discount_percent = 2
	fee_discount_services = list("all")
	work_time_multiplier = 1
	work_time_services = list()

/datum/technician_station_equipment/chisel/iron
	slot_id = "chisel"
	item_type = /obj/item/weapon/chisel/iron
	display_name = "Iron chisel"
	tier = 2
	fee_discount_percent = 3
	fee_discount_services = list("all")
	work_time_multiplier = 1
	work_time_services = list()

/datum/technician_station_equipment/chisel/bronze
	slot_id = "chisel"
	item_type = /obj/item/weapon/chisel/bronze
	display_name = "Bronze chisel"
	tier = 3
	fee_discount_percent = 4
	fee_discount_services = list("all")
	work_time_multiplier = 1
	work_time_services = list()

/// Returns the most specific registered equipment definition matching an item.
/// The exact item path is preferred; more specific subtypes beat parent paths.
/proc/get_technician_station_equipment_definition(obj/item/I)
	if(!I)
		return null

	var/best_path_length = 0
	var/datum/technician_station_equipment/best_match
	for(var/datum/technician_station_equipment/equipment_type as anything in subtypesof(/datum/technician_station_equipment))
		if(IS_ABSTRACT(equipment_type))
			continue
		var/datum/technician_station_equipment/E = new equipment_type()
		if(!ispath(E.item_type, /obj/item) || !ispath(I.type, E.item_type))
			qdel(E)
			continue
		var/path_length = length("[E.item_type]")
		if(path_length > best_path_length)
			if(best_match)
				qdel(best_match)
			best_match = E
			best_path_length = path_length
		else
			qdel(E)
	return best_match

/proc/get_technician_equipment_slot_name(slot_id)
	switch(slot_id)
		if("hammer")
			return "Hammer"
		if("tongs")
			return "Tongs"
		if("crucible")
			return "Crucible"
		if("saw")
			return "Saw"
		if("needle")
			return "Needle"
		if("chisel")
			return "Chisel"
	return capitalize("[slot_id]")

/proc/get_technician_service_name(service_id)
	switch(service_id)
		if(TECH_STATION_SERVICE_CRAFTING)
			return "General crafting"
		if(TECH_STATION_SERVICE_METALWORKING)
			return "Metalworking"
		if(TECH_STATION_SERVICE_SMELTING)
			return "Smelting"
		if(TECH_STATION_SERVICE_SEWING)
			return "Sewing and patching"
	return capitalize("[service_id]")

// ---------------------------------------------------------------------------
// Per-workstation equipment handling and modifier helpers.
// These procs are kept on the workstation so map variants can override them.
// ---------------------------------------------------------------------------

/obj/structure/fake_machine/technician_workshop/proc/has_station_service(service_id)
	if(!station_profile || !istext(service_id) || !length(service_id))
		return FALSE
	if(!station_profile.enabled_services[service_id])
		return FALSE

	var/list/required_slots = station_profile.service_slot_requirements[service_id]
	if(!islist(required_slots))
		return TRUE
	for(var/slot_id in required_slots)
		if(!station_profile.enabled_equipment_slots[slot_id])
			return FALSE
		var/obj/item/installed_item = installed_station_equipment[slot_id]
		if(!installed_item || QDELETED(installed_item) || installed_item.loc != src)
			return FALSE
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/get_recipe_required_service(datum/technician_recipe/R, category_override)
	if(!R)
		return TECH_STATION_SERVICE_CRAFTING
	if(R.required_station_service)
		return R.required_station_service
	var/category_name = category_override ? category_override : R.category
	if(station_profile && station_profile.recipe_category_services[category_name])
		return station_profile.recipe_category_services[category_name]
	return TECH_STATION_SERVICE_CRAFTING

/obj/structure/fake_machine/technician_workshop/proc/get_equipment_fee_multiplier(service_id)
	var/combined_multiplier = 1
	if(!station_profile)
		return 1
	for(var/slot_id in installed_station_equipment)
		if(!station_profile.enabled_equipment_slots[slot_id])
			continue
		var/obj/item/I = installed_station_equipment[slot_id]
		if(!I || QDELETED(I))
			continue
		var/datum/technician_station_equipment/E = get_technician_station_equipment_definition(I)
		if(!E)
			continue
		var/list/applies_to = E.fee_discount_services
		if(islist(applies_to) && (("all" in applies_to) || (service_id in applies_to)))
			var/slot_scale = station_profile.equipment_fee_discount_scales[slot_id]
			if(!isnum(slot_scale))
				slot_scale = 1
			var/discount = clamp(E.fee_discount_percent * slot_scale, 0, 90)
			combined_multiplier *= (1 - (discount / 100))
		qdel(E)

	var/combined_discount = 1 - combined_multiplier
	var/cap = station_profile.fee_discount_caps[service_id]
	if(!isnum(cap))
		cap = station_profile.fee_discount_caps["general"]
	if(!isnum(cap))
		cap = 40
	cap = clamp(cap, 0, 90)
	combined_discount = min(combined_discount, cap / 100)
	return 1 - combined_discount

/obj/structure/fake_machine/technician_workshop/proc/get_station_service_fee(base_fee, service_id)
	if(!isnum(base_fee) || base_fee < 0)
		return 0
	if(station_profile && islist(station_profile.service_fee_enabled))
		var/list/fee_switches = station_profile.service_fee_enabled
		if(("all" in fee_switches) && !fee_switches["all"])
			return 0
		if((service_id in fee_switches) && !fee_switches[service_id])
			return 0
	return max(0, round(base_fee * get_equipment_fee_multiplier(service_id)))

/obj/structure/fake_machine/technician_workshop/proc/get_equipment_work_time_multiplier(service_id)
	var/combined_multiplier = 1
	if(!station_profile)
		return combined_multiplier
	for(var/slot_id in installed_station_equipment)
		if(!station_profile.enabled_equipment_slots[slot_id])
			continue
		var/obj/item/I = installed_station_equipment[slot_id]
		if(!I || QDELETED(I))
			continue
		var/datum/technician_station_equipment/E = get_technician_station_equipment_definition(I)
		if(!E)
			continue
		var/list/applies_to = E.work_time_services
		if(islist(applies_to) && (("all" in applies_to) || (service_id in applies_to)))
			if(isnum(E.work_time_multiplier) && E.work_time_multiplier > 0)
				var/slot_scale = station_profile.equipment_work_time_scales[slot_id]
				if(!isnum(slot_scale))
					slot_scale = 1
				var/scaled_factor = 1 + ((E.work_time_multiplier - 1) * clamp(slot_scale, 0, 3))
				combined_multiplier *= scaled_factor
		qdel(E)
	return clamp(combined_multiplier, 0.5, 1.5)

/obj/structure/fake_machine/technician_workshop/proc/get_adjusted_work_time(base_time, service_id)
	if(!isnum(base_time) || base_time <= 0)
		return 1
	return max(1, round(base_time * get_equipment_work_time_multiplier(service_id)))

/// Installs a supplied tool if it is a better tier than the currently installed
/// tool in that slot. Tools remain real objects inside the station and are dropped
/// if the workstation is destroyed or the slot is replaced.
/obj/structure/fake_machine/technician_workshop/proc/install_station_equipment_item(obj/item/I, mob/living/user)
	if(!I || QDELETED(I))
		return FALSE
	var/datum/technician_station_equipment/E = get_technician_station_equipment_definition(I)
	if(!E)
		return FALSE
	var/slot_id = E.slot_id
	if(!station_profile || !station_profile.enabled_equipment_slots[slot_id])
		if(user)
			to_chat(user, span_warning("[src] is not configured to accept [E.display_name]."))
		qdel(E)
		return FALSE

	var/obj/item/current_item = installed_station_equipment[slot_id]
	if(current_item && !QDELETED(current_item))
		var/datum/technician_station_equipment/current_definition = get_technician_station_equipment_definition(current_item)
		var/current_tier = current_definition ? current_definition.tier : 0
		qdel(current_definition)
		if(E.tier <= current_tier)
			if(user)
				to_chat(user, span_warning("[src] already has an equal or better [get_technician_equipment_slot_name(slot_id)] installed."))
			qdel(E)
			return FALSE

	if(user && !user.temporarilyRemoveItemFromInventory(I))
		qdel(E)
		return FALSE
	if(!I.forceMove(src))
		if(user)
			user.put_in_hands(I)
		qdel(E)
		return FALSE

	if(current_item && !QDELETED(current_item))
		current_item.forceMove(staging_turf || get_turf(src))
		visible_message(span_notice("[src] ejects its old [get_technician_equipment_slot_name(slot_id)] as a replacement is installed."))

	installed_station_equipment[slot_id] = I
	visible_message(span_notice("[src] accepts [E.display_name] as its new [get_technician_equipment_slot_name(slot_id)] equipment."))
	playsound(src, 'sound/misc/machinevomit.ogg', 75, TRUE, -1)
	qdel(E)
	SStgui.update_uis(src)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/eject_station_equipment()
	var/turf/drop_turf = staging_turf || get_turf(src)
	if(!drop_turf)
		return FALSE
	for(var/slot_id in installed_station_equipment)
		var/obj/item/I = installed_station_equipment[slot_id]
		if(I && !QDELETED(I) && I.loc == src)
			I.forceMove(drop_turf)
		installed_station_equipment[slot_id] = null
	SStgui.update_uis(src)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/get_station_equipment_ui_data()
	var/list/result = list()
	for(var/slot_id in installed_station_equipment)
		var/obj/item/I = installed_station_equipment[slot_id]
		var/datum/technician_station_equipment/E = (I && !QDELETED(I)) ? get_technician_station_equipment_definition(I) : null
		result += list(list(
			"id" = slot_id,
			"name" = get_technician_equipment_slot_name(slot_id),
			"installed" = (I && !QDELETED(I)) ? TRUE : FALSE,
			"item_name" = (I && !QDELETED(I)) ? I.name : "Not installed",
			"tier" = E ? E.tier : 0,
			"icon" = (I && !QDELETED(I)) ? "[I.icon]" : "",
			"icon_state" = (I && !QDELETED(I)) ? I.icon_state : "",
			"enabled" = station_profile.enabled_equipment_slots[slot_id] ? TRUE : FALSE,
		))
		qdel(E)
	return result

/obj/structure/fake_machine/technician_workshop/proc/get_station_services_ui_data()
	var/list/result = list()
	if(!station_profile)
		return result
	for(var/service_id in station_profile.enabled_services)
		var/list/requirements = station_profile.service_slot_requirements[service_id]
		var/list/missing = list()
		var/list/required_names = list()
		if(islist(requirements))
			for(var/slot_id in requirements)
				required_names += get_technician_equipment_slot_name(slot_id)
				var/obj/item/I = installed_station_equipment[slot_id]
				if(!station_profile.enabled_equipment_slots[slot_id] || !I || QDELETED(I))
					missing += get_technician_equipment_slot_name(slot_id)
		result += list(list(
			"id" = service_id,
			"name" = get_technician_service_name(service_id),
			"enabled" = station_profile.enabled_services[service_id] ? TRUE : FALSE,
			"available" = has_station_service(service_id) ? TRUE : FALSE,
			"required" = required_names,
			"missing" = missing,
		))
	return result

// ---------------------------------------------------------------------------
// Debug-admin configuration. Register this proc in world/AVerbsDebug() in
// code/modules/admin/admin_verbs.dm so only R_DEBUG admins receive the verb.
// ---------------------------------------------------------------------------

/client/proc/debug_technician_workshop_equipment()
	set category = "Debug"
	set name = "Configure Technician Workshop"
	if(!check_rights(R_DEBUG))
		return

	var/list/workshop_choices = list()
	for(var/obj/structure/fake_machine/technician_workshop/W in world)
		workshop_choices["[W.name] ([REF(W)])"] = W
	if(!length(workshop_choices))
		to_chat(src, span_warning("No Technician Workshops exist on the map."))
		return

	var/selected_workshop = input(src, "Choose a workstation to inspect or configure.", "Technician Workshop") as null|anything in workshop_choices
	var/obj/structure/fake_machine/technician_workshop/W = workshop_choices[selected_workshop]
	if(!W || QDELETED(W))
		return

	var/action = input(src, "Configure [W] ([W.station_profile.profile_name]).", "Technician Workshop") as null|anything in list("View status", "Toggle service", "Toggle equipment slot", "Toggle service requirement", "Set discount cap", "Set equipment effect scale", "Change profile", "Eject installed tools")
	if(!action || QDELETED(W))
		return

	switch(action)
		if("View status")
			var/list/status_lines = list("Profile: [W.station_profile.profile_name]")
			for(var/slot_id in W.installed_station_equipment)
				var/obj/item/I = W.installed_station_equipment[slot_id]
				status_lines += "[get_technician_equipment_slot_name(slot_id)]: [I && !QDELETED(I) ? I.name : "Not installed"]"
			for(var/service_id in W.station_profile.enabled_services)
				status_lines += "[get_technician_service_name(service_id)]: [W.has_station_service(service_id) ? "Available" : "Locked / disabled"] (discount cap [W.station_profile.fee_discount_caps[service_id]]%)"
			for(var/slot_id in W.station_profile.enabled_equipment_slots)
				status_lines += "[get_technician_equipment_slot_name(slot_id)] scales: fee [W.station_profile.equipment_fee_discount_scales[slot_id]], work time [W.station_profile.equipment_work_time_scales[slot_id]]"
			to_chat(src, span_notice(status_lines.Join("<br>")))
			return

		if("Toggle service")
			var/service_id = input(src, "Select a service.", "Technician Workshop") as null|anything in W.station_profile.enabled_services
			if(!service_id || QDELETED(W))
				return
			W.station_profile.enabled_services[service_id] = !W.station_profile.enabled_services[service_id]
			log_admin("[key_name(src)] toggled [service_id] on [W] to [W.station_profile.enabled_services[service_id]].")

		if("Toggle equipment slot")
			var/slot_id = input(src, "Select an equipment slot.", "Technician Workshop") as null|anything in W.station_profile.enabled_equipment_slots
			if(!slot_id || QDELETED(W))
				return
			W.station_profile.enabled_equipment_slots[slot_id] = !W.station_profile.enabled_equipment_slots[slot_id]
			log_admin("[key_name(src)] toggled [slot_id] slot on [W] to [W.station_profile.enabled_equipment_slots[slot_id]].")

		if("Toggle service requirement")
			var/service_id = input(src, "Choose the service to edit.", "Technician Workshop") as null|anything in W.station_profile.enabled_services
			if(!service_id || QDELETED(W))
				return
			var/slot_id = input(src, "Choose an equipment slot to add/remove as a requirement.", "Technician Workshop") as null|anything in W.station_profile.enabled_equipment_slots
			if(!slot_id || QDELETED(W))
				return
			var/list/requirements = W.station_profile.service_slot_requirements[service_id]
			if(!islist(requirements))
				requirements = list()
			if(slot_id in requirements)
				requirements -= slot_id
			else
				requirements += slot_id
			W.station_profile.service_slot_requirements[service_id] = requirements
			log_admin("[key_name(src)] changed [service_id] equipment requirements on [W]: [requirements.Join(", ")].")

		if("Set discount cap")
			var/service_id = input(src, "Select the service whose maximum equipment discount should change.", "Technician Workshop") as null|anything in W.station_profile.fee_discount_caps
			if(!service_id || QDELETED(W))
				return
			var/new_cap = input(src, "Enter a maximum combined discount (0-90%).", "Technician Workshop", W.station_profile.fee_discount_caps[service_id]) as null|num
			if(isnull(new_cap) || QDELETED(W))
				return
			W.station_profile.fee_discount_caps[service_id] = clamp(round(new_cap), 0, 90)
			log_admin("[key_name(src)] set [service_id] equipment discount cap on [W] to [W.station_profile.fee_discount_caps[service_id]]%.")

		if("Set equipment effect scale")
			var/slot_id = input(src, "Choose an equipment slot.", "Technician Workshop") as null|anything in W.station_profile.enabled_equipment_slots
			if(!slot_id || QDELETED(W))
				return
			var/effect_type = input(src, "Choose which equipment effect to scale.", "Technician Workshop") as null|anything in list("Fee discount", "Work time")
			if(!effect_type || QDELETED(W))
				return
			var/list/scales = (effect_type == "Fee discount") ? W.station_profile.equipment_fee_discount_scales : W.station_profile.equipment_work_time_scales
			var/current_scale = scales[slot_id]
			if(!isnum(current_scale))
				current_scale = 1
			var/new_scale = input(src, "Set the effect scale (0 disables, 1 uses the registered value, 2 doubles it). Range: 0-3.", "Technician Workshop", current_scale) as null|num
			if(isnull(new_scale) || QDELETED(W))
				return
			scales[slot_id] = clamp(new_scale, 0, 3)
			log_admin("[key_name(src)] set [effect_type] scale for [slot_id] on [W] to [scales[slot_id]].")

		if("Change profile")
			var/list/profile_choices = list()
			for(var/datum/technician_station_profile/profile_type as anything in typesof(/datum/technician_station_profile))
				if(profile_type == /datum/technician_station_profile || IS_ABSTRACT(profile_type))
					continue
				var/datum/technician_station_profile/P = new profile_type()
				profile_choices["[P.profile_name] ([profile_type])"] = profile_type
				qdel(P)
			var/profile_choice = input(src, "Select a station profile. Installed items are preserved.", "Technician Workshop") as null|anything in profile_choices
			var/profile_path = profile_choices[profile_choice]
			if(!ispath(profile_path, /datum/technician_station_profile) || QDELETED(W))
				return
			var/datum/technician_station_profile/new_profile = new profile_path()
			if(W.station_profile)
				qdel(W.station_profile)
			W.station_profile = new_profile
			W.station_profile_type = profile_path
			log_admin("[key_name(src)] changed [W] to station profile [profile_path].")

		if("Eject installed tools")
			W.eject_station_equipment()
			log_admin("[key_name(src)] ejected all installed equipment from [W].")

	SStgui.update_uis(W)
	to_chat(src, span_notice("Technician Workshop configuration updated."))

