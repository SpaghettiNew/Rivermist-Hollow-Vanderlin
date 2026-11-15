/obj/structure/fake_machine/technician_workshop
	name = "technician's workbench"
	desc = "A compact workshop where a dedicated technician produces practical goods for the faction."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "streetvendor0"
	density = TRUE
	anchored = TRUE
	blade_dulling = DULLING_BASH

	/// Each workstation instance owns an independent resource stock and mammon depot.
	var/list/resource_stock = list()
	/// Resource units indexed by the exact deposited item type for lossless withdrawals.
	/// resource_source_stock[resource_id]["/obj/item/path"] = resource units represented.
	var/list/resource_source_stock = list()
	var/budget = 0

	/// Mapper-selected station configuration. Each instance receives its own profile datum.
	var/datum/technician_station_profile/station_profile_type = /datum/technician_station_profile/default
	var/datum/technician_station_profile/station_profile
	/// Real tools stored inside this station, keyed by equipment slot ID.
	var/list/installed_station_equipment = list()
	/// Immutable recipe/resource metadata built once per station and rebuilt only after configuration edits.
	var/list/technician_resource_catalog = list()
	var/list/technician_recipe_catalog = list()

	/// One unattended crafting operation at a time.
	var/is_crafting = FALSE
	var/active_recipe_type
	var/active_recipe_name
	var/active_recipe_ref
	/// Snapshot of the selected craft configuration. Admin edits during an active
	/// operation must not change the output or the inputs already charged.
	var/list/active_recipe_config
	var/next_custom_recipe_id = 1
	var/craft_finish_time = 0
	var/craft_total_time = 0
	var/craft_timer_id
	var/active_operation_kind = null // "craft", "upgrade", "fix", or "smelt".

	/// Items physically staged on this workstation's tile, in entry order.
	/// The first item is always the upgrade target; later items can satisfy item inputs.
	var/list/staged_items = list()
	var/turf/staging_turf
	var/suppress_surface_registration = FALSE
	/// Batch internal item movements without broadcasting a UI payload per item.
	var/suppress_surface_updates = FALSE

	/// Items moved inside the workstation while an upgrade is running.
	var/obj/item/active_upgrade_target
	var/list/active_upgrade_ingredients = list()
	var/active_upgrade_recipe_type
	/// Original order of all staged items, restored if an upgrade transaction fails.
	var/list/active_upgrade_original_surface_order = list()
	/// Resource source allocations consumed by the active upgrade, for failure refunds.
	var/list/active_upgrade_resource_refunds = list()
	var/active_upgrade_fee_refund = 0

	/// Item currently reserved for a paid full-integrity restoration.
	var/obj/item/active_fix_target
	var/list/active_fix_original_surface_order = list()
	var/list/active_fix_resource_refunds = list()
	var/active_fix_fee_refund = 0
	var/list/active_fix_ingredients = list()

	/// Ore currently reserved for paid smelting.
	var/obj/item/active_smelt_target
	var/active_smelt_result_type
	var/active_smelt_fee_refund = 0
	var/list/active_smelt_original_surface_order = list()

	/// DMI supplied by the project. Required states: idle, crafting, upgrading, fixing, smelting.
	var/technician_portrait_icon = "modular_rmh/icons/machines/technician.dmi"

/obj/structure/fake_machine/technician_workshop/Initialize(mapload)
	. = ..()
	// Always allocate a fresh list: each spawned workstation must own its stock.
	resource_stock = list()
	resource_source_stock = list()
	installed_station_equipment = list(
		"hammer" = null,
		"tongs" = null,
		"crucible" = null,
		"saw" = null,
		"needle" = null,
		"chisel" = null,
	)
	if(!ispath(station_profile_type, /datum/technician_station_profile) || IS_ABSTRACT(station_profile_type))
		station_profile_type = /datum/technician_station_profile/default
	station_profile = new station_profile_type()
	if(station_profile.technician_portrait_icon)
		technician_portrait_icon = station_profile.technician_portrait_icon
	if(isnum(station_profile.starting_budget) && station_profile.starting_budget > 0)
		budget = round(station_profile.starting_budget)

	// Initialize every registered resource to zero on this station only.
	for(var/datum/technician_resource/resource_type as anything in subtypesof(/datum/technician_resource))
		if(IS_ABSTRACT(resource_type))
			continue
		var/datum/technician_resource/R = new resource_type()
		resource_stock[R.id] = 0
		resource_source_stock[R.id] = list()
		qdel(R)

	// Apply mapper-defined starting resources only after the resource registry
	// has been initialized. Unknown IDs and invalid amounts are ignored safely.
	if(islist(station_profile.starting_resources))
		for(var/resource_id in station_profile.starting_resources)
			var/starting_amount = station_profile.starting_resources[resource_id]
			if(!(resource_id in resource_stock) || !isnum(starting_amount) || starting_amount < 0 || round(starting_amount) != starting_amount)
				continue
			// Starting stock must retain a valid physical representation so it
			// can be withdrawn without inventing an item type or losing quantity.
			if(starting_amount <= 0)
				continue
			var/datum/technician_resource/starting_resource = get_technician_resource_definition(resource_id)
			if(starting_resource && ispath(starting_resource.icon_item_type, /obj/item) && starting_resource.can_withdraw_source_type(starting_resource.icon_item_type, starting_amount))
				resource_stock[resource_id] = starting_amount
				resource_source_stock[resource_id] = list("[starting_resource.icon_item_type]" = starting_amount)
			else
				log_game("Technician workshop [REF(src)] ignored mapper starting stock for [resource_id] because it has no valid withdrawal representation.")
			if(starting_resource)
				qdel(starting_resource)

	// Presets can contain custom IDs, while mapper profiles may define their own.
	if(islist(station_profile.custom_recipes))
		for(var/custom_id in station_profile.custom_recipes)
			var/numeric_custom_id = text2num("[custom_id]")
			if(numeric_custom_id >= next_custom_recipe_id)
				next_custom_recipe_id = numeric_custom_id + 1

	// Recipe/resource metadata is immutable between admin/profile edits. Do not
	// instantiate every recipe and resource on every TGUI data refresh.
	rebuild_technician_workshop_catalog()

	// Install mapper-defined starting tools into this instance only.
	if(islist(station_profile.starting_equipment))
		for(var/slot_id in station_profile.starting_equipment)
			var/tool_type = station_profile.starting_equipment[slot_id]
			if(!ispath(tool_type, /obj/item) || !(slot_id in installed_station_equipment) || !station_profile.enabled_equipment_slots[slot_id])
				continue
			var/obj/item/starting_tool = new tool_type(src)
			var/datum/technician_station_equipment/tool_definition = get_technician_station_equipment_definition(starting_tool)
			if(tool_definition && tool_definition.slot_id == slot_id)
				installed_station_equipment[slot_id] = starting_tool
			else
				qdel(starting_tool)
			qdel(tool_definition)

	// Listen to the actual tile contents. Unlike a table object, this fake
	// machine's "surface" is its turf, which is where table-style drops land.
	staging_turf = get_turf(src)
	staged_items = list()
	if(staging_turf)
		RegisterSignal(staging_turf, COMSIG_ATOM_ENTERED, PROC_REF(on_surface_entered))
		RegisterSignal(staging_turf, COMSIG_ATOM_EXITED, PROC_REF(on_surface_exited))
		// Account for objects already present when the workstation initializes.
		for(var/obj/item/I in staging_turf)
			var/datum/technician_station_equipment/preplaced_equipment = get_technician_station_equipment_definition(I)
			if(preplaced_equipment)
				qdel(preplaced_equipment)
				install_station_equipment_item(I, null)
			else
				register_staged_item(I, FALSE)

/obj/structure/fake_machine/technician_workshop/Destroy()
	if(craft_timer_id)
		deltimer(craft_timer_id)
		craft_timer_id = null

	if(staging_turf)
		UnregisterSignal(staging_turf, list(COMSIG_ATOM_ENTERED, COMSIG_ATOM_EXITED))
	for(var/obj/item/staged_item as anything in staged_items)
		if(staged_item && !QDELETED(staged_item))
			UnregisterSignal(staged_item, COMSIG_PARENT_QDELETING)

	// If the station is deleted mid-upgrade, do not delete the customer's
	// target or physical ingredients with the machine.
	var/turf/drop_turf = get_turf(src)
	if(active_upgrade_target && !QDELETED(active_upgrade_target) && drop_turf)
		active_upgrade_target.forceMove(drop_turf)
	if(active_fix_target && !QDELETED(active_fix_target) && drop_turf)
		active_fix_target.forceMove(drop_turf)
	for(var/obj/item/fix_ingredient as anything in active_fix_ingredients)
		if(fix_ingredient && !QDELETED(fix_ingredient) && drop_turf)
			fix_ingredient.forceMove(drop_turf)
	if(active_smelt_target && !QDELETED(active_smelt_target) && drop_turf)
		active_smelt_target.forceMove(drop_turf)
	for(var/obj/item/I as anything in active_upgrade_ingredients)
		if(I && !QDELETED(I) && drop_turf)
			I.forceMove(drop_turf)
	for(var/slot_id in installed_station_equipment)
		var/obj/item/installed_tool = installed_station_equipment[slot_id]
		if(installed_tool && !QDELETED(installed_tool) && drop_turf)
			installed_tool.forceMove(drop_turf)
	if(station_profile)
		qdel(station_profile)
		station_profile = null
	return ..()

/obj/structure/fake_machine/technician_workshop/proc/get_resource_amount(resource_id)
	var/current_amount = resource_stock[resource_id]
	if(!isnum(current_amount) || current_amount < 0)
		return 0
	return current_amount

/obj/structure/fake_machine/technician_workshop/proc/can_access_workshop(mob/user, show_message = FALSE)
	if(!user || QDELETED(user))
		return FALSE
	// A mapper can assign one or more existing faction IDs to the workstation
	// through the inherited atom faction list. Untagged workstations are public.
	if(LAZYLEN(faction) && !user.has_faction(faction))
		if(show_message)
			to_chat(user, span_warning("This workshop is reserved for members of its faction."))
		return FALSE
	return TRUE

/obj/structure/fake_machine/technician_workshop/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!tool || !user || user.cmode)
		return NONE
	if(!can_access_workshop(user, TRUE))
		return ITEM_INTERACT_BLOCKING

	// Mammons are physically deposited into this workstation, like a peddler.
	// This codebase uses /obj/item/coin (not the legacy /obj/item/roguecoin).
	if(istype(tool, /obj/item/coin))
		var/obj/item/coin/deposited_coin = tool
		var/money = deposited_coin.get_real_price()
		if(!isnum(money) || money <= 0)
			return ITEM_INTERACT_BLOCKING

		budget += money
		qdel(tool)
		to_chat(user, span_info("I deposit [money] amnas into [src]."))
		playsound(src, 'sound/misc/machinevomit.ogg', 100, TRUE, -1)
		SStgui.update_uis(src)
		attack_hand(user)
		return ITEM_INTERACT_SUCCESS

	// Station instruments are stored in independent equipment slots. They are
	// not deposited as resources and never become ordinary workpiece targets.
	var/datum/technician_station_equipment/equipment_check = get_technician_station_equipment_definition(tool)
	if(equipment_check)
		qdel(equipment_check)
		if(install_station_equipment_item(tool, user))
			attack_hand(user)
			return ITEM_INTERACT_SUCCESS
		return ITEM_INTERACT_BLOCKING

	// Resolve resource input from explicit resource definitions. Natural bundles
	// contribute their actual bundle amount, not one unit per bundle object.
	var/list/deposit = get_technician_resource_deposit(tool)
	if(deposit)
		var/resource_id = deposit["id"]
		var/deposit_amount = deposit["amount"]
		if(!istext(resource_id) || !isnum(deposit_amount) || deposit_amount <= 0)
			return ITEM_INTERACT_BLOCKING

		var/datum/technician_resource/resource_definition = get_technician_resource_definition(resource_id)
		if(!resource_definition)
			return ITEM_INTERACT_BLOCKING

		resource_stock[resource_id] = get_resource_amount(resource_id) + deposit_amount
		var/list/source_stock = resource_source_stock[resource_id]
		if(!islist(source_stock))
			source_stock = list()
		var/source_type_key = "[tool.type]"
		source_stock[source_type_key] = (source_stock[source_type_key] || 0) + deposit_amount
		resource_source_stock[resource_id] = source_stock
		var/resource_name = resource_definition.name
		qdel(resource_definition)

		qdel(tool)
		to_chat(user, span_info("I deposit [deposit_amount] [resource_name] into [src]."))
		playsound(src, 'sound/misc/machinevomit.ogg', 75, TRUE, -1)
		SStgui.update_uis(src)
		attack_hand(user)
		return ITEM_INTERACT_SUCCESS

	// Items that are not accepted as depot resources are treated as physical
	// workpieces or upgrade ingredients and placed on the workstation surface.
	if(tool.item_flags & ABSTRACT)
		return NONE
	if(!user.temporarilyRemoveItemFromInventory(tool))
		return NONE
	if(!user.transferItemToLoc(tool, drop_location(), silent = FALSE))
		return NONE

	var/icon_x = text2num(LAZYACCESS(modifiers, ICON_X))
	var/icon_y = text2num(LAZYACCESS(modifiers, ICON_Y))
	if(!icon_x || !icon_y)
		icon_x = ICON_SIZE_X / 2
		icon_y = ICON_SIZE_Y / 2
	tool.pixel_x = tool.base_pixel_x + CLAMP(icon_x - 16, -(world.icon_size / 2), world.icon_size / 2)
	tool.pixel_y = tool.base_pixel_y + CLAMP(icon_y - 16, -(world.icon_size / 2), world.icon_size / 2)
	register_staged_item(tool)
	to_chat(user, span_notice("I place [tool] on [src]."))
	SStgui.update_uis(src)
	attack_hand(user)
	return ITEM_INTERACT_SUCCESS

/obj/structure/fake_machine/technician_workshop/proc/on_surface_entered(datum/source, atom/movable/arrived, atom/old_loc)
	SIGNAL_HANDLER
	if(suppress_surface_registration || !isitem(arrived))
		return
	var/obj/item/arrived_item = arrived
	var/datum/technician_station_equipment/equipment_check = get_technician_station_equipment_definition(arrived_item)
	if(equipment_check)
		// Equipment must be handed directly to the workstation through
		// item_interaction(), where faction access can be checked. A raw turf
		// drop has no actor context and must never install a station tool.
		qdel(equipment_check)
		return
	register_staged_item(arrived_item, !suppress_surface_updates)

/obj/structure/fake_machine/technician_workshop/proc/on_surface_exited(datum/source, atom/movable/exiting, atom/new_loc)
	SIGNAL_HANDLER
	if(!(exiting in staged_items))
		return
	UnregisterSignal(exiting, COMSIG_PARENT_QDELETING)
	staged_items -= exiting
	if(!suppress_surface_updates)
		SStgui.update_uis(src)

/obj/structure/fake_machine/technician_workshop/proc/on_staged_item_deleting(datum/source, force)
	SIGNAL_HANDLER
	if(source in staged_items)
		staged_items -= source
		if(!suppress_surface_updates)
			SStgui.update_uis(src)

/obj/structure/fake_machine/technician_workshop/proc/register_staged_item(obj/item/I, update_ui = TRUE)
	if(!I || QDELETED(I) || I.loc != staging_turf || (I in staged_items))
		return FALSE
	var/datum/technician_station_equipment/equipment_check = get_technician_station_equipment_definition(I)
	if(equipment_check)
		qdel(equipment_check)
		return FALSE
	staged_items += I
	RegisterSignal(I, COMSIG_PARENT_QDELETING, PROC_REF(on_staged_item_deleting))
	if(update_ui)
		SStgui.update_uis(src)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/get_staged_items()
	var/list/current_items = list()
	if(!staging_turf)
		return current_items
	for(var/obj/item/I as anything in staged_items)
		if(I && !QDELETED(I) && I.loc == staging_turf)
			current_items += I
	staged_items = current_items
	return current_items

/obj/structure/fake_machine/technician_workshop/proc/get_primary_staged_item()
	var/list/current_items = get_staged_items()
	if(!length(current_items))
		return null
	return current_items[1]

/obj/structure/fake_machine/technician_workshop/attack_hand(mob/living/user)
	if(!can_access_workshop(user, TRUE))
		return
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return

	user.changeNext_move(CLICK_CD_MELEE)
	playsound(src, 'sound/misc/beep.ogg', 75, FALSE, -1)
	ui_interact(user)

/obj/structure/fake_machine/technician_workshop/ui_state(mob/user)
	return GLOB.physical_state

/obj/structure/fake_machine/technician_workshop/ui_interact(mob/user, datum/tgui/ui)
	if(!can_access_workshop(user, TRUE))
		return
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "TechnicianWorkshop", name, 900, 650)
		ui.open()
	// Every state-changing path explicitly updates this UI. Polling is wasteful
	// because the catalogue is cached and the countdown is client-local.
	ui.set_autoupdate(FALSE)

/obj/structure/fake_machine/technician_workshop/proc/get_effective_recipe_config(recipe_type)
	if(!ispath(recipe_type, /datum/technician_recipe))
		return null
	var/datum/technician_recipe/R = new recipe_type()
	if(R.abstract_type == recipe_type)
		qdel(R)
		return null
	if(!ispath(R.created_item, /obj/item))
		qdel(R)
		return null
	var/list/config = list(
		"name" = R.name,
		"category" = R.category ? R.category : "Miscellaneous",
		"desc" = R.desc,
		"output_item_type" = "[R.created_item]",
		"output_name" = "[initial(R.created_item:name)]",
		"output_desc" = "[initial(R.created_item:desc)]",
		"output_icon" = R.output_icon_override ? R.output_icon_override : "[initial(R.created_item:icon)]",
		"output_state" = R.output_icon_state_override ? R.output_icon_state_override : "[initial(R.created_item:icon_state)]",
		"output_amount" = R.output_amount,
		"resource_costs" = technician_workshop_deep_copy(R.resource_costs),
		"service_fee" = R.service_fee,
		"craft_time" = R.craft_time,
		"required_service" = R.required_station_service,
		"enabled" = TRUE,
		"custom" = FALSE,
		"output_properties" = list(),
	)
	config["required_service"] = R.required_station_service ? R.required_station_service : get_recipe_required_service(R, config["category"])
	if(station_profile && islist(station_profile.recipe_overrides))
		var/list/override = station_profile.recipe_overrides["[recipe_type]"]
		if(islist(override))
			for(var/config_key in override)
				config[config_key] = technician_workshop_deep_copy(override[config_key])
	qdel(R)
	return config

/obj/structure/fake_machine/technician_workshop/proc/get_custom_recipe_config(custom_id)
	if(!station_profile || !islist(station_profile.custom_recipes) || !istext(custom_id))
		return null
	var/list/saved_config = station_profile.custom_recipes[custom_id]
	if(!islist(saved_config))
		return null
	var/list/config = technician_workshop_deep_copy(saved_config)
	config["custom"] = TRUE
	config["enabled"] = isnull(config["enabled"]) ? TRUE : !!config["enabled"]
	return config

/obj/structure/fake_machine/technician_workshop/proc/get_recipe_config_by_ref(recipe_ref)
	if(!istext(recipe_ref) || !length(recipe_ref))
		return null
	if(copytext(recipe_ref, 1, 8) == "custom:")
		return get_custom_recipe_config(copytext(recipe_ref, 8))
	var/recipe_type = text2path(recipe_ref)
	return get_effective_recipe_config(recipe_type)

/obj/structure/fake_machine/technician_workshop/proc/format_technician_resource_costs(list/resource_costs)
	if(!islist(resource_costs) || !length(resource_costs))
		return ""
	var/list/entries = list()
	for(var/resource_id in resource_costs)
		entries += "[resource_id]=[resource_costs[resource_id]]"
	return jointext(entries, ", ")

/obj/structure/fake_machine/technician_workshop/proc/parse_technician_resource_costs(cost_text)
	if(!istext(cost_text))
		return null
	var/list/costs = list()
	var/clean_text = trim(cost_text)
	if(!length(clean_text))
		return costs
	for(var/entry as anything in splittext(clean_text, ","))
		var/list/pair = splittext(trim(entry), "=")
		if(length(pair) != 2)
			return null
		var/resource_id = trim(pair[1])
		var/amount = text2num(trim(pair[2]))
		if(!length(resource_id) || !isnum(amount) || amount <= 0 || round(amount) != amount || (resource_id in costs))
			return null
		var/datum/technician_resource/definition = get_technician_resource_definition(resource_id)
		if(!definition)
			return null
		qdel(definition)
		costs[resource_id] = amount
	return costs

/obj/structure/fake_machine/technician_workshop/proc/get_admin_recipe_ui_data()
	var/list/result = list()
	for(var/datum/technician_recipe/recipe_type as anything in subtypesof(/datum/technician_recipe))
		if(IS_ABSTRACT(recipe_type))
			continue
		var/list/config = get_effective_recipe_config(recipe_type)
		if(!islist(config))
			continue
		var/output_type = text2path(config["output_item_type"])
		if(!ispath(output_type, /obj/item))
			continue
		var/recipe_service = config["required_service"] ? config["required_service"] : TECH_STATION_SERVICE_CRAFTING
		var/list/properties = islist(config["output_properties"]) ? config["output_properties"] : list()
		result += list(list(
			"ref" = "[recipe_type]",
			"name" = config["name"],
			"category" = config["category"],
			"desc" = config["desc"],
			"output_item_type" = config["output_item_type"],
			"output_name" = config["output_name"],
			"output_desc" = config["output_desc"],
			"output_icon" = config["output_icon"],
			"output_state" = config["output_state"],
			"output_amount" = config["output_amount"],
			"resource_costs_text" = format_technician_resource_costs(config["resource_costs"]),
			"service_fee" = config["service_fee"],
			"craft_time" = round(config["craft_time"] / 10),
			"required_service" = recipe_service,
			"enabled" = config["enabled"] ? TRUE : FALSE,
			"custom" = FALSE,
			"force" = isnull(properties["force"]) ? initial(output_type:force) : properties["force"],
			"throwforce" = isnull(properties["throwforce"]) ? initial(output_type:throwforce) : properties["throwforce"],
			"weight_class" = isnull(properties["weight_class"]) ? initial(output_type:w_class) : properties["weight_class"],
			"max_integrity" = isnull(properties["max_integrity"]) ? initial(output_type:max_integrity) : properties["max_integrity"],
			"slowdown" = isnull(properties["slowdown"]) ? initial(output_type:slowdown) : properties["slowdown"],
			"armor_penetration" = isnull(properties["armor_penetration"]) ? initial(output_type:armor_penetration) : properties["armor_penetration"],
		))

	if(station_profile && islist(station_profile.custom_recipes))
		for(var/custom_id in station_profile.custom_recipes)
			var/list/config = get_custom_recipe_config("[custom_id]")
			if(!islist(config))
				continue
			var/output_type = text2path(config["output_item_type"])
			if(!ispath(output_type, /obj/item))
				continue
			var/list/properties = islist(config["output_properties"]) ? config["output_properties"] : list()
			result += list(list(
				"ref" = "custom:[custom_id]",
				"name" = config["name"],
				"category" = config["category"],
				"desc" = config["desc"],
				"output_item_type" = config["output_item_type"],
				"output_name" = isnull(config["output_name"]) ? initial(output_type:name) : config["output_name"],
				"output_desc" = isnull(config["output_desc"]) ? initial(output_type:desc) : config["output_desc"],
				"output_icon" = isnull(config["output_icon"]) ? "[initial(output_type:icon)]" : config["output_icon"],
				"output_state" = isnull(config["output_state"]) ? "[initial(output_type:icon_state)]" : config["output_state"],
				"output_amount" = config["output_amount"],
				"resource_costs_text" = format_technician_resource_costs(config["resource_costs"]),
				"service_fee" = config["service_fee"],
				"craft_time" = round(config["craft_time"] / 10),
				"required_service" = config["required_service"],
				"enabled" = config["enabled"] ? TRUE : FALSE,
				"custom" = TRUE,
				"force" = isnull(properties["force"]) ? initial(output_type:force) : properties["force"],
				"throwforce" = isnull(properties["throwforce"]) ? initial(output_type:throwforce) : properties["throwforce"],
				"weight_class" = isnull(properties["weight_class"]) ? initial(output_type:w_class) : properties["weight_class"],
				"max_integrity" = isnull(properties["max_integrity"]) ? initial(output_type:max_integrity) : properties["max_integrity"],
				"slowdown" = isnull(properties["slowdown"]) ? initial(output_type:slowdown) : properties["slowdown"],
				"armor_penetration" = isnull(properties["armor_penetration"]) ? initial(output_type:armor_penetration) : properties["armor_penetration"],
			))
	return result

/proc/get_technician_workshop_presets()
	var/save_file = file("data/technician_workshop_presets.json")
	if(!fexists(save_file))
		return list()
	var/list/file_data = json_decode(file2text(save_file))
	if(!islist(file_data) || !islist(file_data["presets"]))
		return list()
	return file_data["presets"]

/proc/save_technician_workshop_presets(list/presets)
	if(!islist(presets))
		return FALSE
	var/save_file = file("data/technician_workshop_presets.json")
	if(fexists(save_file))
		fdel(save_file)
	WRITE_FILE(save_file, json_encode(list("version" = 1, "presets" = presets)))
	return fexists(save_file)

/obj/structure/fake_machine/technician_workshop/proc/is_workshop_admin(mob/user)
	return user && user.client && check_rights_for(user.client, R_ADMIN)

/obj/structure/fake_machine/technician_workshop/proc/get_admin_workshop_data(mob/user)
	var/list/admin_data = list("can_edit" = is_workshop_admin(user) ? TRUE : FALSE)
	if(!is_workshop_admin(user) || !station_profile)
		return admin_data

	admin_data["recipes"] = get_admin_recipe_ui_data()
	var/list/services = list()
	for(var/service_id in list(TECH_STATION_SERVICE_CRAFTING, TECH_STATION_SERVICE_METALWORKING, TECH_STATION_SERVICE_SMELTING, TECH_STATION_SERVICE_SEWING))
		var/list/required_slots = station_profile.service_slot_requirements[service_id]
		var/list/missing = list()
		if(islist(required_slots))
			for(var/slot_id in required_slots)
				var/obj/item/installed_item = installed_station_equipment[slot_id]
				if(!station_profile.enabled_equipment_slots[slot_id] || !installed_item || QDELETED(installed_item))
					missing += get_technician_equipment_slot_name(slot_id)
		services += list(list(
			"id" = service_id,
			"name" = get_technician_service_name(service_id),
			"enabled" = station_profile.enabled_services[service_id] ? TRUE : FALSE,
				"available" = has_station_service(service_id) ? TRUE : FALSE,
			"missing" = missing,
		))
	admin_data["services"] = services

	var/list/slots = list()
	for(var/slot_id in installed_station_equipment)
		slots += list(list(
			"id" = slot_id,
			"name" = get_technician_equipment_slot_name(slot_id),
			"enabled" = station_profile.enabled_equipment_slots[slot_id] ? TRUE : FALSE,
		))
	admin_data["equipment_slots"] = slots

	var/list/fee_scopes = list()
	for(var/scope_id in list("all", TECH_STATION_SERVICE_CRAFTING, TECH_STATION_SERVICE_METALWORKING, TECH_STATION_SERVICE_SMELTING, TECH_STATION_SERVICE_SEWING, TECH_STATION_FEE_SCOPE_SEWING_REPAIR))
		var/scope_name = "All services"
		switch(scope_id)
			if(TECH_STATION_SERVICE_CRAFTING)
				scope_name = "General crafting"
			if(TECH_STATION_SERVICE_METALWORKING)
				scope_name = "Metalworking"
			if(TECH_STATION_SERVICE_SMELTING)
				scope_name = "Smelting"
			if(TECH_STATION_SERVICE_SEWING)
				scope_name = "Sewing and crafting"
			if(TECH_STATION_FEE_SCOPE_SEWING_REPAIR)
				scope_name = "Sewing repairs"
		var/fee_scope_enabled = station_profile.service_fee_enabled[scope_id]
		// An omitted fee-scope key means the default behavior: charge the fee.
		fee_scopes += list(list(
			"id" = scope_id,
			"name" = scope_name,
			"enabled" = (isnull(fee_scope_enabled) || fee_scope_enabled) ? TRUE : FALSE,
		))
	admin_data["fee_scopes"] = fee_scopes
	admin_data["technician_icon"] = technician_portrait_icon
	var/list/presets = get_technician_workshop_presets()
	var/list/preset_names = list()
	for(var/preset_name in presets)
		preset_names += list(list("name" = preset_name))
	admin_data["presets"] = preset_names
	admin_data["profile_name"] = station_profile.profile_name
	return admin_data

/obj/structure/fake_machine/technician_workshop/proc/rebuild_technician_workshop_catalog()
	technician_resource_catalog = list()
	technician_recipe_catalog = list()

	// Resource metadata is constant; only its stock count changes during play.
	for(var/datum/technician_resource/resource_type as anything in subtypesof(/datum/technician_resource))
		if(IS_ABSTRACT(resource_type))
			continue
		var/datum/technician_resource/R = new resource_type()
		var/resource_icon = ""
		var/resource_icon_state = ""
		if(ispath(R.icon_item_type, /obj/item))
			resource_icon = "[initial(R.icon_item_type:icon)]"
			resource_icon_state = R.icon_state_override ? R.icon_state_override : "[initial(R.icon_item_type:icon_state)]"
		technician_resource_catalog += list(list(
			"id" = R.id,
			"name" = R.name,
			"icon" = resource_icon,
			"icon_state" = resource_icon_state,
		))
		qdel(R)

	// Build the immutable part of each built-in recipe once. Resource IDs are
	// resolved here once, rather than re-enumerating all resource subtypes for
	// every requirement on every TGUI refresh.
	for(var/datum/technician_recipe/recipe_type as anything in subtypesof(/datum/technician_recipe))
		if(IS_ABSTRACT(recipe_type))
			continue
		var/list/config = get_effective_recipe_config(recipe_type)
		if(!islist(config) || !config["enabled"])
			continue
		var/output_type = text2path(config["output_item_type"])
		if(!config["name"] || !ispath(output_type, /obj/item))
			continue
		var/category_name = config["category"] ? config["category"] : "Miscellaneous"
		var/recipe_service = config["required_service"] ? config["required_service"] : TECH_STATION_SERVICE_CRAFTING
		var/list/resource_costs = config["resource_costs"]
		var/list/requirements = list()
		var/resource_costs_valid = islist(resource_costs)
		if(resource_costs_valid)
			for(var/resource_id in resource_costs)
				var/required_amount = resource_costs[resource_id]
				if(!istext(resource_id) || !length(resource_id) || !isnum(required_amount) || required_amount <= 0 || round(required_amount) != required_amount)
					resource_costs_valid = FALSE
					continue
				var/datum/technician_resource/required_resource = get_technician_resource_definition(resource_id)
				if(!required_resource)
					resource_costs_valid = FALSE
					requirements += list(list("id" = resource_id, "name" = resource_id, "required" = required_amount, "icon" = "", "icon_state" = ""))
					continue
				var/resource_icon = ""
				var/resource_icon_state = ""
				if(ispath(required_resource.icon_item_type, /obj/item))
					resource_icon = "[initial(required_resource.icon_item_type:icon)]"
					resource_icon_state = required_resource.icon_state_override ? required_resource.icon_state_override : "[initial(required_resource.icon_item_type:icon_state)]"
				requirements += list(list(
					"id" = resource_id,
					"name" = required_resource.name,
					"required" = required_amount,
					"icon" = resource_icon,
					"icon_state" = resource_icon_state,
				))
				qdel(required_resource)
		var/output_amount = config["output_amount"]
		var/output_valid = isnum(output_amount) && round(output_amount) == output_amount && output_amount >= 1 && output_amount <= 20
		var/base_fee = config["service_fee"]
		var/fee_valid = isnum(base_fee) && base_fee >= 0 && round(base_fee) == base_fee
		var/base_time = config["craft_time"]
		var/time_valid = isnum(base_time) && base_time > 0 && round(base_time) == base_time
		technician_recipe_catalog += list(list(
			"ref" = "[recipe_type]",
			"name" = config["name"],
			"category" = category_name,
			"desc" = config["desc"],
			"output_name" = config["output_name"] ? config["output_name"] : initial(output_type:name),
			"output_icon" = config["output_icon"] ? config["output_icon"] : "[initial(output_type:icon)]",
			"output_state" = config["output_state"] ? config["output_state"] : "[initial(output_type:icon_state)]",
			"output_amount" = output_valid ? output_amount : 1,
			"requirements" = requirements,
			"base_service_fee" = base_fee,
			"base_craft_time" = base_time,
			"required_service" = recipe_service,
			"resource_costs_valid" = resource_costs_valid,
			"fee_valid" = fee_valid,
			"time_valid" = time_valid,
			"output_valid" = output_valid,
		))

	// Custom recipes use the same cached representation as built-in recipes.
	if(station_profile && islist(station_profile.custom_recipes))
		for(var/custom_id in station_profile.custom_recipes)
			var/list/config = get_custom_recipe_config("[custom_id]")
			if(!islist(config) || !config["enabled"])
				continue
			var/output_type = text2path(config["output_item_type"])
			if(!config["name"] || !ispath(output_type, /obj/item))
				continue
			var/category_name = config["category"] ? config["category"] : "Miscellaneous"
			var/recipe_service = config["required_service"] ? config["required_service"] : TECH_STATION_SERVICE_CRAFTING
			var/list/resource_costs = config["resource_costs"]
			var/list/requirements = list()
			var/resource_costs_valid = islist(resource_costs)
			if(resource_costs_valid)
				for(var/resource_id in resource_costs)
					var/required_amount = resource_costs[resource_id]
					if(!istext(resource_id) || !length(resource_id) || !isnum(required_amount) || required_amount <= 0 || round(required_amount) != required_amount)
						resource_costs_valid = FALSE
						continue
					var/datum/technician_resource/required_resource = get_technician_resource_definition(resource_id)
					if(!required_resource)
						resource_costs_valid = FALSE
						requirements += list(list("id" = resource_id, "name" = resource_id, "required" = required_amount, "icon" = "", "icon_state" = ""))
						continue
					var/resource_icon = ""
					var/resource_icon_state = ""
					if(ispath(required_resource.icon_item_type, /obj/item))
						resource_icon = "[initial(required_resource.icon_item_type:icon)]"
						resource_icon_state = required_resource.icon_state_override ? required_resource.icon_state_override : "[initial(required_resource.icon_item_type:icon_state)]"
					requirements += list(list("id" = resource_id, "name" = required_resource.name, "required" = required_amount, "icon" = resource_icon, "icon_state" = resource_icon_state))
					qdel(required_resource)
			var/output_amount = config["output_amount"]
			var/output_valid = isnum(output_amount) && round(output_amount) == output_amount && output_amount >= 1 && output_amount <= 20
			var/base_fee = config["service_fee"]
			var/fee_valid = isnum(base_fee) && base_fee >= 0 && round(base_fee) == base_fee
			var/base_time = config["craft_time"]
			var/time_valid = isnum(base_time) && base_time > 0 && round(base_time) == base_time
			technician_recipe_catalog += list(list(
				"ref" = "custom:[custom_id]",
				"name" = config["name"],
				"category" = category_name,
				"desc" = config["desc"],
				"output_name" = config["output_name"] ? config["output_name"] : initial(output_type:name),
				"output_icon" = config["output_icon"] ? config["output_icon"] : "[initial(output_type:icon)]",
				"output_state" = config["output_state"] ? config["output_state"] : "[initial(output_type:icon_state)]",
				"output_amount" = output_valid ? output_amount : 1,
				"requirements" = requirements,
				"base_service_fee" = base_fee,
				"base_craft_time" = base_time,
				"required_service" = recipe_service,
				"resource_costs_valid" = resource_costs_valid,
				"fee_valid" = fee_valid,
				"time_valid" = time_valid,
				"output_valid" = output_valid,
			))

/obj/structure/fake_machine/technician_workshop/ui_data(mob/user)
	if(!can_access_workshop(user, FALSE))
		return list("access_denied" = TRUE)
	var/list/data = list()
	data["budget"] = budget
	data["is_crafting"] = is_crafting ? TRUE : FALSE
	data["active_recipe_name"] = active_recipe_name ? active_recipe_name : ""
	data["active_recipe_ref"] = (active_operation_kind == "upgrade" && active_upgrade_recipe_type) ? "[active_upgrade_recipe_type]" : (active_recipe_ref ? active_recipe_ref : (active_recipe_type ? "[active_recipe_type]" : ""))
	data["craft_time_remaining"] = is_crafting ? max(0, round((craft_finish_time - world.time) / 10)) : 0
	data["craft_total_time"] = is_crafting ? max(1, round(craft_total_time / 10)) : 0
	// Snapshot marker resets the leaf-level client countdown after explicit server updates.
	data["craft_time_snapshot"] = world.time
	data["technician_icon"] = technician_portrait_icon
	data["technician_state"] = "idle"
	if(is_crafting)
		switch(active_operation_kind)
			if("craft")
				data["technician_state"] = "crafting"
			if("upgrade")
				data["technician_state"] = "upgrading"
			if("fix")
				data["technician_state"] = "fixing"
			if("smelt")
				data["technician_state"] = "smelting"
	data["active_operation_kind"] = active_operation_kind ? active_operation_kind : ""
	data["station_equipment"] = get_station_equipment_ui_data()
	data["station_services"] = get_station_services_ui_data()

	var/list/current_staged_items = get_staged_items()
	var/obj/item/primary_target = length(current_staged_items) ? current_staged_items[1] : null
	if(is_crafting && active_operation_kind == "upgrade" && active_upgrade_target && !QDELETED(active_upgrade_target))
		primary_target = active_upgrade_target
	else if(is_crafting && active_operation_kind == "fix" && active_fix_target && !QDELETED(active_fix_target))
		primary_target = active_fix_target
	else if(is_crafting && active_operation_kind == "smelt" && active_smelt_target && !QDELETED(active_smelt_target))
		primary_target = active_smelt_target

	var/list/smelt_profile = primary_target ? get_technician_smelt_profile(primary_target) : null
	if(smelt_profile)
		var/base_smelt_fee = smelt_profile["service_fee"]
		smelt_profile["base_service_fee"] = base_smelt_fee
		smelt_profile["service_fee"] = get_station_service_fee(base_smelt_fee, "smelting")
		if(isnum(smelt_profile["work_time"]) && smelt_profile["work_time"] > 0)
			smelt_profile["work_time"] = get_adjusted_work_time(smelt_profile["work_time"], "smelting")
		if(!has_station_service("smelting"))
			smelt_profile["supported"] = FALSE
			smelt_profile["reason"] = "The workstation needs an installed crucible before it can smelt ore."
	data["mode"] = is_crafting ? "busy" : (smelt_profile ? "smelt" : (primary_target ? "upgrade" : "craft"))
	var/list/target_item_data = null
	if(primary_target)
		target_item_data = list(
			"name" = primary_target.name,
			"desc" = primary_target.desc,
			"icon" = "[primary_target.icon]",
			"icon_state" = primary_target.icon_state,
			"type" = "[primary_target.type]",
		)
	data["target_item"] = target_item_data
	data["staged_item_count"] = length(current_staged_items)
	var/list/surface_items_data = list()
	for(var/obj/item/staged_item as anything in current_staged_items)
		surface_items_data += list(list(
			"name" = staged_item.name,
			"icon" = "[staged_item.icon]",
			"icon_state" = staged_item.icon_state,
			"type" = "[staged_item.type]",
		))
	data["surface_items"] = surface_items_data
	var/list/smelt_ui_data = null
	if(smelt_profile)
		smelt_ui_data = smelt_profile.Copy()
		smelt_ui_data -= "result_type" // Keep DM typepaths server-side; the UI only needs display metadata.
		smelt_ui_data["can_smelt"] = (!is_crafting && smelt_profile["supported"] && budget >= smelt_profile["service_fee"]) ? TRUE : FALSE
		if(smelt_profile["supported"] && budget < smelt_profile["service_fee"])
			smelt_ui_data["reason"] = "Insufficient amnas in the workshop depot."
	data["smelting"] = smelt_ui_data

	var/list/resources = list()
	for(var/list/resource_definition as anything in technician_resource_catalog)
		var/resource_id = resource_definition["id"]
		var/amount = get_resource_amount(resource_id)
		var/list/resource_row = resource_definition.Copy()
		resource_row["amount"] = amount
		resource_row["can_withdraw"] = amount > 0 ? TRUE : FALSE
		resources += list(resource_row)
	data["mammon_icon"] = "icons/roguetown/items/valuable.dmi"
	data["mammon_icon_state"] = "c1"
	data["can_withdraw_mammons"] = budget > 0 ? TRUE : FALSE
	data["resources"] = resources

	var/list/categories = list()
	var/list/recipes = list()
	for(var/list/cached_recipe as anything in technician_recipe_catalog)
		var/recipe_service = cached_recipe["required_service"]
		if(!has_station_service(recipe_service))
			continue
		var/list/recipe_row = technician_workshop_deep_copy(cached_recipe)
		var/list/requirements = recipe_row["requirements"]
		var/resources_sufficient = recipe_row["resource_costs_valid"]
		for(var/list/requirement as anything in requirements)
			var/available_amount = get_resource_amount(requirement["id"])
			var/missing_amount = max(0, requirement["required"] - available_amount)
			requirement["available"] = available_amount
			requirement["missing"] = missing_amount
			if(missing_amount)
				resources_sufficient = FALSE
		var/base_fee = recipe_row["base_service_fee"]
		var/fee_valid = recipe_row["fee_valid"]
		var/effective_fee = fee_valid ? get_station_service_fee(base_fee, recipe_service) : 0
		var/base_time = recipe_row["base_craft_time"]
		var/time_valid = recipe_row["time_valid"]
		recipe_row["service_fee"] = effective_fee
		recipe_row["craft_time"] = time_valid ? round(get_adjusted_work_time(base_time, recipe_service) / 10) : 0
		recipe_row["resources_sufficient"] = resources_sufficient ? TRUE : FALSE
		recipe_row["can_craft"] = (!is_crafting && resources_sufficient && fee_valid && time_valid && recipe_row["output_valid"] && budget >= effective_fee) ? TRUE : FALSE
		recipe_row -= "base_service_fee"
		recipe_row -= "base_craft_time"
		recipe_row -= "resource_costs_valid"
		recipe_row -= "fee_valid"
		recipe_row -= "time_valid"
		recipe_row -= "output_valid"
		if(!(recipe_row["category"] in categories))
			categories += recipe_row["category"]
		recipes += list(recipe_row)
	data["categories"] = categories
	data["recipes"] = recipes

	var/list/upgrade_categories = list()
	var/list/upgrade_recipes = list()
	if(primary_target && !is_crafting)
		for(var/datum/technician_upgrade_recipe/upgrade_type as anything in subtypesof(/datum/technician_upgrade_recipe))
			if(IS_ABSTRACT(upgrade_type))
				continue
			var/datum/technician_upgrade_recipe/U = new upgrade_type()
			if(!U.name || !ispath(U.created_item, /obj/item) || !U.can_apply_to_target(primary_target))
				qdel(U)
				continue
			var/upgrade_service = U.required_station_service ? U.required_station_service : "crafting"
			if(!has_station_service(upgrade_service))
				qdel(U)
				continue
			var/category_name = U.category ? U.category : "Miscellaneous"
			if(!(category_name in upgrade_categories))
				upgrade_categories += category_name
			var/fee_is_valid = isnum(U.service_fee) && U.service_fee >= 0 && round(U.service_fee) == U.service_fee
			var/effective_upgrade_fee = get_station_service_fee(U.service_fee, upgrade_service)
			var/time_is_valid = isnum(U.craft_time) && U.craft_time > 0 && round(U.craft_time) == U.craft_time
			var/list/requirement_state = get_upgrade_requirement_state(U, primary_target, current_staged_items)
			var/upgrade_recipe_is_valid = requirement_state["valid"] && fee_is_valid && time_is_valid
			var/list/upgrade_data = list(
				"ref" = "[U.type]",
				"name" = U.name,
				"category" = category_name,
				"desc" = U.desc,
				"output_name" = "[initial(U.created_item:name)]",
				"output_icon" = U.output_icon_override ? U.output_icon_override : "[initial(U.created_item:icon)]",
				"output_state" = U.output_icon_state_override ? U.output_icon_state_override : "[initial(U.created_item:icon_state)]",
				"item_requirements" = requirement_state["item_requirements"],
				"resource_requirements" = requirement_state["resource_requirements"],
				"items_sufficient" = requirement_state["items_sufficient"],
				"resources_sufficient" = requirement_state["resources_sufficient"],
				"service_fee" = fee_is_valid ? effective_upgrade_fee : 0,
				"craft_time" = time_is_valid ? round(get_adjusted_work_time(U.craft_time, upgrade_service) / 10) : 0,
				"required_service" = upgrade_service,
				"can_upgrade" = (!is_crafting && upgrade_recipe_is_valid && requirement_state["items_sufficient"] && requirement_state["resources_sufficient"] && budget >= effective_upgrade_fee) ? TRUE : FALSE,
			)
			upgrade_recipes += list(upgrade_data)
			qdel(U)
	data["upgrade_categories"] = upgrade_categories
	data["upgrade_recipes"] = upgrade_recipes

	// Fixing is separate from upgrades but uses the same target item, depot,
	// fee display, and unattended station operation.
	var/list/fixing_data = null
	if(primary_target && !is_crafting)
		fixing_data = get_technician_fix_profile(primary_target)
	else if(is_crafting && active_operation_kind == "fix" && active_fix_target && !QDELETED(active_fix_target))
		fixing_data = get_technician_fix_profile(active_fix_target)
	if(fixing_data && fixing_data["eligible"])
		var/fixing_service = (fixing_data["price_key"] == "cloth" || fixing_data["price_key"] == "leather") ? "sewing" : "metalworking"
		var/fixing_fee_scope = (fixing_service == "sewing") ? "sewing_repair" : fixing_service
		fixing_data["required_service"] = fixing_service
		var/base_fix_fee = fixing_data["service_fee"]
		fixing_data["base_service_fee"] = base_fix_fee
		fixing_data["service_fee"] = get_station_service_fee(base_fix_fee, fixing_fee_scope)
		fixing_data["show_tab"] = has_station_service(fixing_service) ? TRUE : FALSE
		if(!fixing_data["show_tab"])
			fixing_data["fix_reason"] = (fixing_service == "sewing") ? "Install a needle to unlock sewing and leather patching." : "Install a hammer and tongs to unlock metalworking repairs."
		var/resources_sufficient = TRUE
		for(var/list/requirement as anything in fixing_data["resource_requirements"])
			var/resource_id = requirement["id"]
			var/required_amount = requirement["required"]
			var/available_amount = get_resource_amount(resource_id)
			requirement["available"] = available_amount
			requirement["missing"] = max(0, required_amount - available_amount)
			if(requirement["missing"] > 0)
				resources_sufficient = FALSE
		fixing_data["resources_sufficient"] = resources_sufficient

		var/items_sufficient = TRUE
		var/list/fix_item_requirements = fixing_data["item_requirements"] || list()
		for(var/list/requirement as anything in fix_item_requirements)
			var/item_type = text2path(requirement["id"])
			var/required_amount = requirement["required"]
			var/available_amount = 0
			if(ispath(item_type, /obj/item) && isnum(required_amount) && required_amount > 0)
				for(var/obj/item/candidate as anything in current_staged_items)
					if(candidate == primary_target)
						continue
					if(!QDELETED(candidate) && istype(candidate, item_type))
						available_amount++
			requirement["available"] = available_amount
			requirement["missing"] = max(0, required_amount - available_amount)
			if(requirement["missing"] > 0)
				items_sufficient = FALSE
		fixing_data["item_requirements"] = fix_item_requirements
		fixing_data["items_sufficient"] = items_sufficient
		fixing_data["can_fix"] = (!is_crafting && fixing_data["show_tab"] && fixing_data["supported"] && fixing_data["missing_percent"] > 0 && resources_sufficient && items_sufficient && budget >= fixing_data["service_fee"]) ? TRUE : FALSE
		fixing_data["has_damage"] = fixing_data["missing_percent"] > 0 ? TRUE : FALSE
		if(!fixing_data["supported"])
			fixing_data["fix_reason"] = fixing_data["reason"]
		else if(!fixing_data["has_damage"])
			fixing_data["fix_reason"] = "This item is already at maximum integrity."
		else if(!resources_sufficient)
			fixing_data["fix_reason"] = "The required repair material is missing from the depot."
		else if(!items_sufficient)
			fixing_data["fix_reason"] = "The required rare ingot must be placed on the workbench."
		else if(budget < fixing_data["service_fee"])
			fixing_data["fix_reason"] = "Insufficient amnas in the depot."
	if(fixing_data)
		var/list/fixing_ui_data = fixing_data.Copy()
		fixing_ui_data -= "resource_costs"
		fixing_ui_data -= "physical_item_requirements"
		data["fixing"] = fixing_ui_data
	else
		data["fixing"] = null
	data["admin"] = get_admin_workshop_data(user)

	return data

/obj/structure/fake_machine/technician_workshop/proc/get_upgrade_requirement_state(datum/technician_upgrade_recipe/U, obj/item/target, list/surface_items)
	var/list/result = list(
		"valid" = TRUE,
		"items_sufficient" = TRUE,
		"resources_sufficient" = TRUE,
		"item_requirements" = list(),
		"resource_requirements" = list(),
		"consumed_items" = list(),
	)
	if(!U || !target || !islist(U.required_items) || !islist(U.resource_costs))
		result["valid"] = FALSE
		result["items_sufficient"] = FALSE
		result["resources_sufficient"] = FALSE
		return result

	var/list/unallocated_surface_items = surface_items ? surface_items.Copy() : list()
	unallocated_surface_items -= target
	var/list/consumed_items = list()
	var/list/item_requirements = list()
	for(var/obj/item/item_type as anything in U.required_items)
		var/required_amount = U.required_items[item_type]
		if(!ispath(item_type, /obj/item) || !isnum(required_amount) || required_amount <= 0 || round(required_amount) != required_amount)
			result["valid"] = FALSE
			result["items_sufficient"] = FALSE
			continue
		var/available_amount = 0
		for(var/obj/item/candidate as anything in unallocated_surface_items.Copy())
			if(available_amount >= required_amount)
				break
			if(!QDELETED(candidate) && candidate.loc == staging_turf && istype(candidate, item_type))
				available_amount++
				consumed_items += candidate
				unallocated_surface_items -= candidate
		var/missing_amount = max(0, required_amount - available_amount)
		if(missing_amount)
			result["items_sufficient"] = FALSE
		item_requirements += list(list(
			"id" = "[item_type]",
			"name" = "[initial(item_type:name)]",
			"required" = required_amount,
			"available" = available_amount,
			"missing" = missing_amount,
			"icon" = "[initial(item_type:icon)]",
			"icon_state" = "[initial(item_type:icon_state)]",
		))
	result["item_requirements"] = item_requirements
	result["consumed_items"] = consumed_items

	var/list/resource_requirements = list()
	for(var/resource_id in U.resource_costs)
		var/required_amount = U.resource_costs[resource_id]
		if(!istext(resource_id) || !length(resource_id) || !isnum(required_amount) || required_amount <= 0 || round(required_amount) != required_amount)
			result["valid"] = FALSE
			result["resources_sufficient"] = FALSE
			continue
		var/datum/technician_resource/required_resource = get_technician_resource_definition(resource_id)
		var/available_amount = get_resource_amount(resource_id)
		var/missing_amount = max(0, required_amount - available_amount)
		if(!required_resource)
			result["valid"] = FALSE
			result["resources_sufficient"] = FALSE
		else if(missing_amount)
			result["resources_sufficient"] = FALSE
		var/resource_icon = ""
		var/resource_icon_state = ""
		var/resource_name = resource_id
		if(required_resource)
			resource_name = required_resource.name
			if(ispath(required_resource.icon_item_type, /obj/item))
				resource_icon = "[initial(required_resource.icon_item_type:icon)]"
				resource_icon_state = required_resource.icon_state_override ? required_resource.icon_state_override : "[initial(required_resource.icon_item_type:icon_state)]"
			qdel(required_resource)
		resource_requirements += list(list(
			"id" = resource_id,
			"name" = resource_name,
			"required" = required_amount,
			"available" = available_amount,
			"missing" = missing_amount,
			"icon" = resource_icon,
			"icon_state" = resource_icon_state,
		))
	result["resource_requirements"] = resource_requirements
	return result

/obj/structure/fake_machine/technician_workshop/proc/validate_technician_output_path(path_text)
	if(!istext(path_text) || !length(path_text) || length(path_text) > 180)
		return null
	var/output_type = text2path(path_text)
	if(!ispath(output_type, /obj/item))
		return null
	return output_type

/obj/structure/fake_machine/technician_workshop/proc/build_admin_recipe_config(list/params, list/previous_config = null, is_custom = FALSE)
	if(!islist(params))
		return null
	var/recipe_name = trim(params["name"])
	var/category_name = trim(params["category"])
	var/recipe_desc = params["desc"]
	var/output_type = validate_technician_output_path(params["output_item_type"])
	var/output_name = trim(params["output_name"])
	var/output_desc = params["output_desc"]
	var/output_state = trim(params["output_state"])
	var/resource_costs = parse_technician_resource_costs(params["resource_costs_text"])
	var/output_amount = text2num(params["output_amount"])
	var/service_fee = text2num(params["service_fee"])
	var/craft_seconds = text2num(params["craft_time"])
	var/required_service = params["required_service"]
	if(!length(recipe_name) || length(recipe_name) > 64 || !length(category_name) || length(category_name) > 40)
		return null
	if(!istext(recipe_desc) || length(recipe_desc) > 512 || !istext(output_desc) || length(output_desc) > 1024)
		return null
	if(!output_type || !length(output_name) || length(output_name) > 64 || length(output_state) > 64)
		return null
	if(!islist(resource_costs) || !isnum(output_amount) || round(output_amount) != output_amount || output_amount < 1 || output_amount > 20)
		return null
	if(!isnum(service_fee) || round(service_fee) != service_fee || service_fee < 0 || service_fee > 100000)
		return null
	if(!isnum(craft_seconds) || round(craft_seconds) != craft_seconds || craft_seconds < 1 || craft_seconds > 3600)
		return null
	if(!(required_service in list(TECH_STATION_SERVICE_CRAFTING, TECH_STATION_SERVICE_METALWORKING, TECH_STATION_SERVICE_SMELTING, TECH_STATION_SERVICE_SEWING)))
		return null

	var/list/properties = list()
	var/force_value = text2num(params["force"])
	var/throwforce_value = text2num(params["throwforce"])
	var/weight_value = text2num(params["weight_class"])
	var/integrity_value = text2num(params["max_integrity"])
	var/slowdown_value = text2num(params["slowdown"])
	var/penetration_value = text2num(params["armor_penetration"])
	if(!isnull(params["force"]) && length("[params["force"]]") && (!isnum(force_value) || force_value < 0 || force_value > 150))
		return null
	if(!isnull(params["throwforce"]) && length("[params["throwforce"]]") && (!isnum(throwforce_value) || throwforce_value < 0 || throwforce_value > 150))
		return null
	if(!isnull(params["weight_class"]) && length("[params["weight_class"]]") && (!isnum(weight_value) || round(weight_value) != weight_value || weight_value < WEIGHT_CLASS_TINY || weight_value > WEIGHT_CLASS_GIGANTIC))
		return null
	if(!isnull(params["max_integrity"]) && length("[params["max_integrity"]]") && (!isnum(integrity_value) || round(integrity_value) != integrity_value || integrity_value < 1 || integrity_value > 5000))
		return null
	if(!isnull(params["slowdown"]) && length("[params["slowdown"]]") && (!isnum(slowdown_value) || slowdown_value < -5 || slowdown_value > 10))
		return null
	if(!isnull(params["armor_penetration"]) && length("[params["armor_penetration"]]") && (!isnum(penetration_value) || penetration_value < 0 || penetration_value > 100))
		return null
	if(length("[params["force"]]")) properties["force"] = force_value
	if(length("[params["throwforce"]]")) properties["throwforce"] = throwforce_value
	if(length("[params["weight_class"]]")) properties["weight_class"] = weight_value
	if(length("[params["max_integrity"]]")) properties["max_integrity"] = integrity_value
	if(length("[params["slowdown"]]")) properties["slowdown"] = slowdown_value
	if(length("[params["armor_penetration"]]")) properties["armor_penetration"] = penetration_value

	var/list/config = islist(previous_config) ? technician_workshop_deep_copy(previous_config) : list()
	config["name"] = recipe_name
	config["category"] = category_name
	config["desc"] = recipe_desc
	config["output_item_type"] = "[output_type]"
	config["output_name"] = output_name
	config["output_desc"] = output_desc
	config["output_icon"] = "[initial(output_type:icon)]"
	config["output_state"] = length(output_state) ? output_state : "[initial(output_type:icon_state)]"
	config["output_amount"] = output_amount
	config["resource_costs"] = resource_costs
	config["service_fee"] = service_fee
	config["craft_time"] = craft_seconds * 10
	config["required_service"] = required_service
	config["output_properties"] = properties
	config["enabled"] = TRUE
	config["custom"] = is_custom
	return config

/proc/apply_technician_workshop_output_properties(obj/item/output_item, list/properties)
	if(!output_item || QDELETED(output_item) || !islist(properties))
		return
	if(isnum(properties["force"]))
		output_item.force = clamp(properties["force"], 0, 150)
	if(isnum(properties["throwforce"]))
		output_item.throwforce = clamp(properties["throwforce"], 0, 150)
	if(isnum(properties["weight_class"]))
		output_item.w_class = clamp(round(properties["weight_class"]), WEIGHT_CLASS_TINY, WEIGHT_CLASS_GIGANTIC)
	if(isnum(properties["slowdown"]))
		output_item.slowdown = clamp(properties["slowdown"], -5, 10)
	if(isnum(properties["armor_penetration"]))
		output_item.armor_penetration = clamp(properties["armor_penetration"], 0, 100)
	if(isnum(properties["max_integrity"]) && output_item.uses_integrity)
		output_item.max_integrity = clamp(round(properties["max_integrity"]), 1, 5000)
		output_item.update_integrity(output_item.max_integrity, FALSE)

/obj/structure/fake_machine/technician_workshop/proc/save_workshop_preset(preset_name, mob/user)
	if(!is_workshop_admin(user) || !station_profile || !istext(preset_name))
		return FALSE
	preset_name = trim(preset_name)
	if(!length(preset_name) || length(preset_name) > 48 || findtext(preset_name, "..") || findtext(preset_name, "/") || findtext(preset_name, "\\"))
		return FALSE
	var/list/all_presets = get_technician_workshop_presets()
	if(!islist(all_presets))
		all_presets = list()
	if(!(preset_name in all_presets) && length(all_presets) >= 100)
		return FALSE
	var/list/preset = list(
		"profile_name" = station_profile.profile_name,
		"enabled_services" = technician_workshop_deep_copy(station_profile.enabled_services),
		"enabled_equipment_slots" = technician_workshop_deep_copy(station_profile.enabled_equipment_slots),
		"service_fee_enabled" = technician_workshop_deep_copy(station_profile.service_fee_enabled),
		"service_slot_requirements" = technician_workshop_deep_copy(station_profile.service_slot_requirements),
		"recipe_category_services" = technician_workshop_deep_copy(station_profile.recipe_category_services),
		"fee_discount_caps" = technician_workshop_deep_copy(station_profile.fee_discount_caps),
		"equipment_fee_discount_scales" = technician_workshop_deep_copy(station_profile.equipment_fee_discount_scales),
		"equipment_work_time_scales" = technician_workshop_deep_copy(station_profile.equipment_work_time_scales),
		"recipe_overrides" = technician_workshop_deep_copy(station_profile.recipe_overrides),
		"custom_recipes" = technician_workshop_deep_copy(station_profile.custom_recipes),
		"technician_portrait_icon" = technician_portrait_icon,
	)
	all_presets[preset_name] = preset
	return save_technician_workshop_presets(all_presets)

/obj/structure/fake_machine/technician_workshop/proc/load_workshop_preset(preset_name, mob/user)
	if(!is_workshop_admin(user) || !station_profile || !istext(preset_name))
		return FALSE
	var/list/all_presets = get_technician_workshop_presets()
	var/list/preset = all_presets[preset_name]
	if(!islist(preset))
		return FALSE
	var/list/required_profile_fields = list("enabled_services", "enabled_equipment_slots", "service_fee_enabled", "service_slot_requirements", "recipe_category_services", "fee_discount_caps", "equipment_fee_discount_scales", "equipment_work_time_scales", "recipe_overrides", "custom_recipes")
	for(var/field_name in required_profile_fields)
		if(!islist(preset[field_name]))
			return FALSE
	var/saved_icon_path = preset["technician_portrait_icon"]
	if(istext(saved_icon_path) && length(saved_icon_path) && !is_valid_technician_portrait_icon_path(saved_icon_path))
		return FALSE
	station_profile.profile_name = istext(preset["profile_name"]) ? copytext(preset["profile_name"], 1, 65) : "Loaded preset: [preset_name]"
	station_profile.enabled_services = technician_workshop_deep_copy(preset["enabled_services"])
	station_profile.enabled_equipment_slots = technician_workshop_deep_copy(preset["enabled_equipment_slots"])
	station_profile.service_fee_enabled = technician_workshop_deep_copy(preset["service_fee_enabled"])
	station_profile.service_slot_requirements = technician_workshop_deep_copy(preset["service_slot_requirements"])
	station_profile.recipe_category_services = technician_workshop_deep_copy(preset["recipe_category_services"])
	station_profile.fee_discount_caps = technician_workshop_deep_copy(preset["fee_discount_caps"])
	station_profile.equipment_fee_discount_scales = technician_workshop_deep_copy(preset["equipment_fee_discount_scales"])
	station_profile.equipment_work_time_scales = technician_workshop_deep_copy(preset["equipment_work_time_scales"])
	station_profile.recipe_overrides = technician_workshop_deep_copy(preset["recipe_overrides"])
	station_profile.custom_recipes = technician_workshop_deep_copy(preset["custom_recipes"])
	if(istext(saved_icon_path) && length(saved_icon_path))
		technician_portrait_icon = saved_icon_path
		station_profile.technician_portrait_icon = saved_icon_path
	for(var/custom_id in station_profile.custom_recipes)
		var/custom_numeric_id = text2num("[custom_id]")
		if(custom_numeric_id >= next_custom_recipe_id)
			next_custom_recipe_id = custom_numeric_id + 1
	return TRUE

/proc/is_valid_technician_portrait_icon_path(icon_path)
	if(!istext(icon_path) || length(icon_path) < 5 || length(icon_path) > 160)
		return FALSE
	if(copytext(icon_path, length(icon_path) - 3) != ".dmi" || findtext(icon_path, "..") || findtext(icon_path, "\\"))
		return FALSE
	return copytext(icon_path, 1, 7) == "icons/" || copytext(icon_path, 1, 13) == "modular_rmh/"

/obj/structure/fake_machine/technician_workshop/proc/admin_set_portrait_icon(icon_path, mob/user)
	if(!is_workshop_admin(user) || !istext(icon_path))
		return FALSE
	icon_path = trim(icon_path)
	if(!is_valid_technician_portrait_icon_path(icon_path))
		return FALSE
	technician_portrait_icon = icon_path
	station_profile.technician_portrait_icon = icon_path
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/admin_action(action, list/params, mob/user)
	if(!is_workshop_admin(user) || !station_profile)
		return FALSE
	switch(action)
		if("admin_toggle_recipe")
			var/recipe_ref = params["recipe"]
			var/list/config = get_recipe_config_by_ref(recipe_ref)
			if(!islist(config)) return FALSE
			config["enabled"] = !config["enabled"]
			if(copytext(recipe_ref, 1, 8) == "custom:")
				station_profile.custom_recipes[copytext(recipe_ref, 8)] = config
			else
				station_profile.recipe_overrides[recipe_ref] = list("enabled" = config["enabled"])
			return TRUE
		if("admin_save_recipe")
			var/recipe_ref = params["recipe"]
			var/list/previous_config = get_recipe_config_by_ref(recipe_ref)
			if(!islist(previous_config)) return FALSE
			var/is_custom = copytext(recipe_ref, 1, 8) == "custom:"
			var/list/new_config = build_admin_recipe_config(params, previous_config, is_custom)
			if(!islist(new_config)) return FALSE
			if(is_custom)
				station_profile.custom_recipes[copytext(recipe_ref, 8)] = new_config
			else
				station_profile.recipe_overrides[recipe_ref] = new_config
			return TRUE
		if("admin_add_custom_recipe")
			if(length(station_profile.custom_recipes) >= 100)
				return FALSE
			var/list/new_custom_config = build_admin_recipe_config(params, null, TRUE)
			if(!islist(new_custom_config)) return FALSE
			var/new_id = "[next_custom_recipe_id++]"
			station_profile.custom_recipes[new_id] = new_custom_config
			return TRUE
		if("admin_delete_custom_recipe")
			var/custom_ref = params["recipe"]
			if(!istext(custom_ref) || copytext(custom_ref, 1, 8) != "custom:") return FALSE
			station_profile.custom_recipes -= copytext(custom_ref, 8)
			return TRUE
		if("admin_toggle_service")
			var/service_id = params["service"]
			if(!(service_id in list(TECH_STATION_SERVICE_CRAFTING, TECH_STATION_SERVICE_METALWORKING, TECH_STATION_SERVICE_SMELTING, TECH_STATION_SERVICE_SEWING))) return FALSE
			station_profile.enabled_services[service_id] = !station_profile.enabled_services[service_id]
			return TRUE
		if("admin_toggle_equipment_slot")
			var/slot_id = params["slot"]
			if(!(slot_id in installed_station_equipment)) return FALSE
			station_profile.enabled_equipment_slots[slot_id] = !station_profile.enabled_equipment_slots[slot_id]
			return TRUE
		if("admin_toggle_fee_scope")
			var/scope_id = params["scope"]
			if(!(scope_id in list("all", TECH_STATION_SERVICE_CRAFTING, TECH_STATION_SERVICE_METALWORKING, TECH_STATION_SERVICE_SMELTING, TECH_STATION_SERVICE_SEWING, TECH_STATION_FEE_SCOPE_SEWING_REPAIR))) return FALSE
			station_profile.service_fee_enabled[scope_id] = !station_profile.service_fee_enabled[scope_id]
			return TRUE
		if("admin_set_technician_icon")
			return admin_set_portrait_icon(params["icon_path"], user)
		if("admin_save_preset")
			return save_workshop_preset(params["name"], user)
		if("admin_load_preset")
			return load_workshop_preset(params["name"], user)
		if("admin_delete_preset")
			var/preset_name = params["name"]
			if(!istext(preset_name)) return FALSE
			var/list/all_presets = get_technician_workshop_presets()
			if(!(preset_name in all_presets)) return FALSE
			all_presets -= preset_name
			return save_technician_workshop_presets(all_presets)
	return FALSE

/obj/structure/fake_machine/technician_workshop/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	if(!ishuman(usr))
		return
	if(!usr.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
		return
	if(!can_access_workshop(usr, TRUE))
		return FALSE

	switch(action)
		if("start_craft")
			return start_craft(params["recipe"], usr)
		if("start_upgrade")
			return start_upgrade(params["recipe"], usr)
		if("start_fix")
			return start_fix(usr)
		if("start_smelt")
			return start_smelt(usr)
		if("withdraw_resource")
			return withdraw_resource(params["resource_id"], usr)
		if("withdraw_mammons")
			return withdraw_mammons(usr)
		if("admin_toggle_recipe", "admin_save_recipe", "admin_add_custom_recipe", "admin_delete_custom_recipe", "admin_toggle_service", "admin_toggle_equipment_slot", "admin_toggle_fee_scope", "admin_set_technician_icon", "admin_save_preset", "admin_load_preset", "admin_delete_preset")
			if(!admin_action(action, params, usr))
				to_chat(usr, span_warning("The workstation rejected that change. Check the fields, item path, resource IDs, and preset name."))
				return FALSE
			rebuild_technician_workshop_catalog()
			return TRUE

/obj/structure/fake_machine/technician_workshop/proc/can_consume_resource_source_stock(resource_id, amount)
	if(!isnum(amount) || amount < 0)
		return FALSE
	if(!amount)
		return TRUE
	var/list/source_stock = resource_source_stock[resource_id]
	if(!islist(source_stock))
		return FALSE
	var/available_total = 0
	for(var/source_key as anything in source_stock)
		var/source_amount = source_stock[source_key]
		if(!isnum(source_amount) || source_amount < 0)
			return FALSE
		available_total += source_amount
	return available_total >= amount

/obj/structure/fake_machine/technician_workshop/proc/consume_resource_source_stock(resource_id, amount)
	var/list/source_stock = resource_source_stock[resource_id]
	var/list/consumed_sources = list()
	if(!islist(source_stock) || amount <= 0)
		return consumed_sources

	var/remaining = amount
	var/list/source_keys = source_stock.Copy()
	for(var/source_key as anything in source_keys)
		if(remaining <= 0)
			break
		var/available = source_stock[source_key]
		var/taken = min(available, remaining)
		if(taken <= 0)
			continue
		consumed_sources[source_key] = taken
		available -= taken
		remaining -= taken
		if(available <= 0)
			source_stock -= source_key
		else
			source_stock[source_key] = available
	resource_source_stock[resource_id] = source_stock
	return consumed_sources

/obj/structure/fake_machine/technician_workshop/proc/refund_active_upgrade_depot()
	for(var/resource_id in active_upgrade_resource_refunds)
		var/list/refund_sources = active_upgrade_resource_refunds[resource_id]
		if(!islist(refund_sources))
			continue
		var/refunded_amount = 0
		var/list/source_stock = resource_source_stock[resource_id]
		if(!islist(source_stock))
			source_stock = list()
		for(var/source_key as anything in refund_sources)
			var/source_amount = refund_sources[source_key]
			if(!isnum(source_amount) || source_amount <= 0)
				continue
			source_stock[source_key] = (source_stock[source_key] || 0) + source_amount
			refunded_amount += source_amount
		resource_source_stock[resource_id] = source_stock
		resource_stock[resource_id] = get_resource_amount(resource_id) + refunded_amount
	budget += active_upgrade_fee_refund
	active_upgrade_resource_refunds = list()
	active_upgrade_fee_refund = 0

/obj/structure/fake_machine/technician_workshop/proc/withdraw_resource(resource_id, mob/living/user)
	if(!user || QDELETED(user) || !user.Adjacent(src) || !istext(resource_id))
		return FALSE

	var/amount = get_resource_amount(resource_id)
	if(amount <= 0)
		return FALSE

	var/datum/technician_resource/R = get_technician_resource_definition(resource_id)
	if(!R)
		return FALSE

	var/list/source_stock = resource_source_stock[resource_id]
	if(!islist(source_stock) || !length(source_stock))
		log_game("Technician workshop [REF(src)] has [amount] [resource_id] but no source-stock record; refusing withdrawal to prevent material creation.")
		qdel(R)
		return FALSE

	// Validate all output representations before spawning any of them.
	for(var/source_key as anything in source_stock)
		var/source_type = text2path(source_key)
		if(!R.can_withdraw_source_type(source_type, source_stock[source_key]))
			log_game("Technician workshop [REF(src)] has invalid withdrawal source [source_key] for resource [resource_id].")
			qdel(R)
			return FALSE

	var/turf/drop_turf = get_turf(src)
	if(!drop_turf)
		qdel(R)
		return FALSE

	suppress_surface_registration = TRUE
	var/withdrawal_succeeded = TRUE
	for(var/source_key as anything in source_stock.Copy())
		var/source_type = text2path(source_key)
		if(!R.create_withdrawal(drop_turf, source_type, source_stock[source_key]))
			// The source type was validated above; this is a defensive fallback.
			log_game("Technician workshop [REF(src)] failed to recreate [source_key] while withdrawing [resource_id].")
			withdrawal_succeeded = FALSE
			break
	suppress_surface_registration = FALSE
	if(!withdrawal_succeeded)
		qdel(R)
		return FALSE

	resource_stock[resource_id] = 0
	source_stock.Cut()
	resource_source_stock[resource_id] = source_stock
	to_chat(user, span_notice("I withdraw [amount] [R.name] from [src]."))
	playsound(src, 'sound/misc/machinevomit.ogg', 75, TRUE, -1)
	qdel(R)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/dispense_mammon_change(amount, mob/living/user)
	// Mirrors the peddler's budget2change() payout pattern, using the current
	// /obj/item/coin denominations from Coin.dm and the 20-coin stack limit.
	// Change is dispensed beside the player; the final stack of each denomination
	// is offered to their hands, matching the peddler behavior.
	if(!isnum(amount) || amount <= 0 || round(amount) != amount)
		return FALSE

	var/turf/drop_turf = user ? get_turf(user) : get_turf(src)
	if(!drop_turf)
		return FALSE

	var/remaining = amount
	var/list/coin_denominations = list(
		/obj/item/coin/platinum = 1000,
		/obj/item/coin/gold = 100,
		/obj/item/coin/electrum = 50,
		/obj/item/coin/silver = 10,
		/obj/item/coin/copper = 1,
	)

	for(var/coin_type as anything in coin_denominations)
		var/coin_value = coin_denominations[coin_type]
		var/coin_count = floor(remaining / coin_value)
		if(coin_count <= 0)
			continue
		remaining -= coin_count * coin_value
		while(coin_count > 0)
			var/stack_size = min(coin_count, 20)
			var/obj/item/coin/coin_stack = new coin_type(drop_turf, stack_size)
			if(user && coin_count == stack_size)
				user.put_in_hands(coin_stack)
			coin_count -= stack_size

	playsound(drop_turf, 'sound/misc/coindispense.ogg', 100, FALSE, -1)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/withdraw_mammons(mob/living/user)
	if(!user || QDELETED(user) || !user.Adjacent(src) || budget <= 0)
		return FALSE

	var/withdrawal_amount = budget
	if(!dispense_mammon_change(withdrawal_amount, user))
		return FALSE

	budget = 0
	to_chat(user, span_notice("The workshop dispenses [withdrawal_amount] amnas in change."))
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/start_upgrade(recipe_ref, mob/living/user)
	if(!user || QDELETED(user) || !user.Adjacent(src))
		return FALSE
	if(is_crafting)
		to_chat(user, span_warning("The technician is already working on an item."))
		return FALSE
	if(!istext(recipe_ref))
		return FALSE

	var/list/current_items = get_staged_items()
	if(!length(current_items))
		to_chat(user, span_warning("Place an item on the workstation first."))
		return FALSE
	var/obj/item/target = current_items[1]

	var/datum/technician_upgrade_recipe/recipe_type = text2path(recipe_ref)
	if(!ispath(recipe_type, /datum/technician_upgrade_recipe) || IS_ABSTRACT(recipe_type))
		log_admin("Invalid technician upgrade request from [key_name(user)]: [recipe_ref]")
		return FALSE

	var/datum/technician_upgrade_recipe/U = new recipe_type()
	if(!ispath(U.created_item, /obj/item) || !U.can_apply_to_target(target) || !islist(U.required_items) || !islist(U.resource_costs) || !isnum(U.service_fee) || U.service_fee < 0 || round(U.service_fee) != U.service_fee || !isnum(U.craft_time) || U.craft_time <= 0 || round(U.craft_time) != U.craft_time)
		qdel(U)
		return FALSE
	var/upgrade_service = U.required_station_service ? U.required_station_service : "crafting"
	if(!has_station_service(upgrade_service))
		to_chat(user, span_warning("This workstation does not have the equipment required for that upgrade service."))
		qdel(U)
		return FALSE
	var/service_fee = get_station_service_fee(U.service_fee, upgrade_service)
	var/work_time = get_adjusted_work_time(U.craft_time, upgrade_service)

	var/list/requirement_state = get_upgrade_requirement_state(U, target, current_items)
	if(!requirement_state["valid"] || !requirement_state["items_sufficient"])
		to_chat(user, span_warning("The required physical components are not all on the workbench."))
		qdel(U)
		return FALSE
	if(!requirement_state["resources_sufficient"])
		to_chat(user, span_warning("The workshop does not have enough deposited resources."))
		qdel(U)
		return FALSE
	for(var/resource_id in U.resource_costs)
		if(!can_consume_resource_source_stock(resource_id, U.resource_costs[resource_id]))
			log_game("Technician workshop [REF(src)] has inconsistent source stock for upgrade resource [resource_id]; refusing upgrade.")
			qdel(U)
			return FALSE
	if(budget < service_fee)
		to_chat(user, span_warning("The workshop does not have enough amnas in its depot to pay the service fee."))
		qdel(U)
		return FALSE

	// Reserve the target and exactly the staged item inputs selected by the
	// recipe. Extra surface items remain in place and keep their relative order.
	var/list/items_to_reserve = list(target)
	for(var/obj/item/ingredient as anything in requirement_state["consumed_items"])
		if(!(ingredient in items_to_reserve))
			items_to_reserve += ingredient
	var/list/original_surface_order = current_items.Copy()
	var/list/reserved_items = list()
	var/previous_surface_update_suppression = suppress_surface_updates
	suppress_surface_updates = TRUE
	var/reservation_failed = FALSE
	for(var/obj/item/I as anything in items_to_reserve)
		if(QDELETED(I) || I.loc != staging_turf || !I.forceMove(src))
			for(var/obj/item/reserved as anything in reserved_items)
				if(reserved && !QDELETED(reserved))
					reserved.forceMove(staging_turf)
			staged_items = original_surface_order
			reservation_failed = TRUE
			break
		reserved_items += I
	suppress_surface_updates = previous_surface_update_suppression
	if(reservation_failed)
		qdel(U)
		return FALSE

	// Commit depot resources and the service fee only after physical inputs are
	// safely reserved inside the workstation. Keep exact source allocations so a
	// failed completion can refund without changing the deposited item forms.
	var/list/resource_refunds = list()
	for(var/resource_id in U.resource_costs)
		var/required_amount = U.resource_costs[resource_id]
		var/list/consumed_sources = consume_resource_source_stock(resource_id, required_amount)
		resource_refunds[resource_id] = consumed_sources
		resource_stock[resource_id] = get_resource_amount(resource_id) - required_amount
	budget -= service_fee

	active_upgrade_target = target
	var/list/consumed_items = requirement_state["consumed_items"]
	active_upgrade_ingredients = consumed_items.Copy()
	active_upgrade_original_surface_order = original_surface_order
	active_upgrade_resource_refunds = resource_refunds
	active_upgrade_fee_refund = service_fee
	active_upgrade_recipe_type = recipe_type
	active_recipe_type = null
	active_operation_kind = "upgrade"
	active_recipe_name = U.name
	is_crafting = TRUE
	craft_total_time = work_time
	craft_finish_time = world.time + craft_total_time
	craft_timer_id = addtimer(CALLBACK(src, PROC_REF(complete_craft)), craft_total_time, TIMER_STOPPABLE)

	visible_message(span_notice("[src] begins modifying [target]. The technician begins working at the bench."))
	playsound(src, 'sound/misc/beep.ogg', 75, FALSE, -1)
	qdel(U)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/restore_active_upgrade_items(turf/drop_turf)
	if(!drop_turf)
		return
	if(active_upgrade_target && !QDELETED(active_upgrade_target) && active_upgrade_target.loc == src)
		active_upgrade_target.forceMove(drop_turf)
	for(var/obj/item/I as anything in active_upgrade_ingredients)
		if(I && !QDELETED(I) && I.loc == src)
			I.forceMove(drop_turf)

	// Movement signals append restored items to the surface list. Rebuild it
	// from the saved pre-operation order so the first workpiece stays first.
	var/list/restored_order = list()
	for(var/obj/item/original_item as anything in active_upgrade_original_surface_order)
		if(original_item && !QDELETED(original_item) && original_item.loc == staging_turf)
			restored_order += original_item
	staged_items = restored_order

/obj/structure/fake_machine/technician_workshop/proc/complete_upgrade()
	var/turf/output_turf = get_turf(src)
	var/datum/technician_upgrade_recipe/U
	var/datum/technician_upgrade_recipe/recipe_type = active_upgrade_recipe_type
	if(ispath(recipe_type, /datum/technician_upgrade_recipe) && !IS_ABSTRACT(recipe_type))
		U = new recipe_type()

	var/operation_succeeded = FALSE
	var/previous_surface_update_suppression = suppress_surface_updates
	suppress_surface_updates = TRUE
	if(output_turf && U && active_upgrade_target && !QDELETED(active_upgrade_target) && active_upgrade_target.loc == src)
		var/all_inputs_reserved = TRUE
		for(var/obj/item/I as anything in active_upgrade_ingredients)
			if(!I || QDELETED(I) || I.loc != src)
				all_inputs_reserved = FALSE
				break
		if(all_inputs_reserved)
			var/obj/item/output_item = U.apply_upgrade(active_upgrade_target, output_turf)
			if(output_item && !QDELETED(output_item))
				// Recipe overrides may either create a replacement or modify the
				// existing target in place. Do not delete the returned item.
				if(output_item == active_upgrade_target || (output_item in active_upgrade_ingredients))
					if(output_item.loc != output_turf)
						output_item.forceMove(output_turf)
				else if(active_upgrade_target && !QDELETED(active_upgrade_target))
					qdel(active_upgrade_target)
				for(var/obj/item/ingredient as anything in active_upgrade_ingredients)
					if(ingredient && !QDELETED(ingredient) && ingredient != output_item)
						qdel(ingredient)
				// The replacement occupies the original workpiece's first position.
				// Do not append it after unconsumed staged items: the first staged
				// item controls the next available upgrade catalogue.
				var/list/successful_surface_order = list()
				if(output_item.loc == staging_turf)
					successful_surface_order += output_item
				for(var/obj/item/original_item as anything in active_upgrade_original_surface_order)
					if(!original_item || QDELETED(original_item) || original_item == active_upgrade_target || original_item == output_item || (original_item in active_upgrade_ingredients))
						continue
					if(original_item.loc == staging_turf)
						successful_surface_order += original_item
				staged_items = successful_surface_order
				visible_message(span_notice("[src] finishes [U.name]. The upgraded item is left on the workbench."))
				playsound(src, 'sound/items/bsmith3.ogg', 75, TRUE)
				operation_succeeded = TRUE

	if(!operation_succeeded)
		log_game("Technician workshop at [AREACOORD(src)] failed upgrade [active_upgrade_recipe_type]; restoring reserved physical inputs and refunding its depot transaction.")
		restore_active_upgrade_items(output_turf)
		refund_active_upgrade_depot()

	if(U)
		qdel(U)
	active_upgrade_target = null
	active_upgrade_ingredients = list()
	active_upgrade_recipe_type = null
	active_upgrade_original_surface_order = list()
	active_upgrade_resource_refunds = list()
	active_upgrade_fee_refund = 0
	active_recipe_type = null
	active_recipe_ref = null
	active_recipe_config = null
	active_recipe_name = null
	active_operation_kind = null
	is_crafting = FALSE
	craft_finish_time = 0
	craft_total_time = 0
	suppress_surface_updates = previous_surface_update_suppression
	SStgui.update_uis(src)
	return operation_succeeded

/obj/structure/fake_machine/technician_workshop/proc/refund_active_fix_depot()
	for(var/resource_id in active_fix_resource_refunds)
		var/list/refund_sources = active_fix_resource_refunds[resource_id]
		if(!islist(refund_sources))
			continue
		var/refunded_amount = 0
		var/list/source_stock = resource_source_stock[resource_id]
		if(!islist(source_stock))
			source_stock = list()
		for(var/source_key as anything in refund_sources)
			var/source_amount = refund_sources[source_key]
			if(!isnum(source_amount) || source_amount <= 0)
				continue
			source_stock[source_key] = (source_stock[source_key] || 0) + source_amount
			refunded_amount += source_amount
		resource_source_stock[resource_id] = source_stock
		resource_stock[resource_id] = get_resource_amount(resource_id) + refunded_amount
	budget += active_fix_fee_refund
	active_fix_resource_refunds = list()
	active_fix_fee_refund = 0

/obj/structure/fake_machine/technician_workshop/proc/restore_active_fix_target(turf/drop_turf)
	if(active_fix_target && !QDELETED(active_fix_target) && active_fix_target.loc == src && drop_turf)
		active_fix_target.forceMove(drop_turf)
	for(var/obj/item/fix_ingredient as anything in active_fix_ingredients)
		if(fix_ingredient && !QDELETED(fix_ingredient) && fix_ingredient.loc == src && drop_turf)
			fix_ingredient.forceMove(drop_turf)
	var/list/restored_order = list()
	for(var/obj/item/original_item as anything in active_fix_original_surface_order)
		if(original_item && !QDELETED(original_item) && original_item.loc == staging_turf)
			restored_order += original_item
	staged_items = restored_order

/obj/structure/fake_machine/technician_workshop/proc/start_fix(mob/living/user)
	if(!user || QDELETED(user) || !user.Adjacent(src))
		return FALSE
	if(is_crafting)
		to_chat(user, span_warning("The technician is already working on an item."))
		return FALSE

	var/list/current_items = get_staged_items()
	if(!length(current_items))
		to_chat(user, span_warning("Place an item on the workstation first."))
		return FALSE
	var/obj/item/target = current_items[1]
	var/list/fix_profile = get_technician_fix_profile(target)
	if(!fix_profile || !fix_profile["eligible"] || !fix_profile["supported"])
		to_chat(user, span_warning(fix_profile ? fix_profile["reason"] : "This item cannot be repaired through the workstation's supported repair methods."))
		return FALSE
	var/fixing_service = (fix_profile["price_key"] == "cloth" || fix_profile["price_key"] == "leather") ? "sewing" : "metalworking"
	if(!has_station_service(fixing_service))
		to_chat(user, span_warning((fixing_service == "sewing") ? "Install a needle to unlock sewing and leather patching." : "Install a hammer and tongs to unlock metalworking repairs."))
		return FALSE
	if(fix_profile["missing_percent"] <= 0)
		to_chat(user, span_notice("[target] is already at maximum integrity."))
		return FALSE

	var/fixing_fee_scope = (fixing_service == "sewing") ? "sewing_repair" : fixing_service
	var/service_fee = get_station_service_fee(fix_profile["service_fee"], fixing_fee_scope)
	if(!isnum(service_fee) || service_fee < 0 || round(service_fee) != service_fee)
		return FALSE
	if(budget < service_fee)
		to_chat(user, span_warning("The workshop does not have enough amnas in its depot to pay the fixing fee."))
		return FALSE

	var/list/resource_costs = fix_profile["resource_costs"]
	if(!islist(resource_costs))
		return FALSE
	for(var/resource_id in resource_costs)
		var/required_amount = resource_costs[resource_id]
		if(!isnum(required_amount) || required_amount <= 0 || round(required_amount) != required_amount || get_resource_amount(resource_id) < required_amount || !can_consume_resource_source_stock(resource_id, required_amount))
			to_chat(user, span_warning("The workshop does not have the material required to restore an item from 0% integrity."))
			return FALSE

	var/list/items_to_reserve = list()
	var/list/physical_requirements = fix_profile["physical_item_requirements"] || list()
	for(var/obj/item/item_type as anything in physical_requirements)
		var/required_amount = physical_requirements[item_type]
		if(!ispath(item_type, /obj/item) || !isnum(required_amount) || required_amount <= 0 || round(required_amount) != required_amount)
			return FALSE
		var/found_amount = 0
		for(var/obj/item/candidate as anything in current_items)
			if(candidate == target || QDELETED(candidate) || candidate.loc != staging_turf)
				continue
			if(istype(candidate, item_type))
				items_to_reserve += candidate
				found_amount++
				if(found_amount >= required_amount)
					break
		if(found_amount < required_amount)
			to_chat(user, span_warning("Place [initial(item_type:name)] on the workbench to restore this item."))
			return FALSE

	var/list/original_surface_order = current_items.Copy()
	var/list/reserved_fix_items = list()
	var/previous_surface_update_suppression = suppress_surface_updates
	suppress_surface_updates = TRUE
	if(QDELETED(target) || target.loc != staging_turf || !target.forceMove(src))
		suppress_surface_updates = previous_surface_update_suppression
		return FALSE
	reserved_fix_items += target
	for(var/obj/item/fix_ingredient as anything in items_to_reserve)
		if(QDELETED(fix_ingredient) || fix_ingredient.loc != staging_turf || !fix_ingredient.forceMove(src))
			for(var/obj/item/reserved_item as anything in reserved_fix_items)
				if(reserved_item && !QDELETED(reserved_item))
					reserved_item.forceMove(staging_turf)
			suppress_surface_updates = previous_surface_update_suppression
			staged_items = original_surface_order
			return FALSE
		reserved_fix_items += fix_ingredient
	suppress_surface_updates = previous_surface_update_suppression

	var/list/resource_refunds = list()
	for(var/resource_id in resource_costs)
		var/required_amount = resource_costs[resource_id]
		resource_refunds[resource_id] = consume_resource_source_stock(resource_id, required_amount)
		resource_stock[resource_id] = get_resource_amount(resource_id) - required_amount
	budget -= service_fee

	active_fix_target = target
	active_fix_ingredients = items_to_reserve.Copy()
	active_fix_original_surface_order = original_surface_order
	active_fix_resource_refunds = resource_refunds
	active_fix_fee_refund = service_fee
	active_recipe_type = null
	active_upgrade_recipe_type = null
	active_recipe_name = "Fixing [target.name]"
	active_operation_kind = "fix"
	is_crafting = TRUE
	var/base_fix_time = GLOB.technician_fix_work_time
	if(!isnum(base_fix_time) || base_fix_time <= 0)
		base_fix_time = 20 SECONDS
	craft_total_time = get_adjusted_work_time(base_fix_time, fixing_service)
	craft_finish_time = world.time + craft_total_time
	craft_timer_id = addtimer(CALLBACK(src, PROC_REF(complete_craft)), craft_total_time, TIMER_STOPPABLE)

	visible_message(span_notice("[src] begins restoring [target]. The technician begins working at the bench."))
	playsound(src, 'sound/misc/beep.ogg', 75, FALSE, -1)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/complete_fix()
	var/turf/output_turf = staging_turf || get_turf(src)
	var/operation_succeeded = FALSE
	var/previous_surface_update_suppression = suppress_surface_updates
	suppress_surface_updates = TRUE

	var/inputs_still_reserved = TRUE
	for(var/obj/item/fix_ingredient as anything in active_fix_ingredients)
		if(!fix_ingredient || QDELETED(fix_ingredient) || fix_ingredient.loc != src)
			inputs_still_reserved = FALSE
			break

	if(output_turf && inputs_still_reserved && active_fix_target && !QDELETED(active_fix_target) && active_fix_target.loc == src && active_fix_target.uses_integrity && active_fix_target.max_integrity > 0)
		var/repair_amount = active_fix_target.max_integrity - active_fix_target.get_integrity()
		if(repair_amount > 0)
			active_fix_target.repair_damage(repair_amount)
			// In this fork /obj/atom_fix() clears obj_broken. repair_damage()
			// normally invokes it when the integrity threshold is crossed; this
			// fallback covers repairable items with a zero integrity_failure value.
			if(active_fix_target.obj_broken)
				active_fix_target.atom_fix()
			active_fix_target.forceMove(output_turf)
			for(var/obj/item/fix_ingredient as anything in active_fix_ingredients)
				if(fix_ingredient && !QDELETED(fix_ingredient) && fix_ingredient.loc == src)
					qdel(fix_ingredient)
			var/list/restored_order = list()
			for(var/obj/item/original_item as anything in active_fix_original_surface_order)
				if(original_item && !QDELETED(original_item) && original_item.loc == staging_turf)
					restored_order += original_item
			staged_items = restored_order
			visible_message(span_notice("[src] finishes restoring [active_fix_target]. It is returned to the workbench."))
			playsound(src, 'sound/items/bsmith3.ogg', 75, TRUE)
			operation_succeeded = TRUE

	if(!operation_succeeded)
		log_game("Technician workshop at [AREACOORD(src)] failed fixing operation; restoring the staged item and refunding the depot transaction.")
		restore_active_fix_target(output_turf)
		refund_active_fix_depot()

	active_fix_target = null
	active_fix_ingredients = list()
	active_fix_original_surface_order = list()
	active_fix_resource_refunds = list()
	active_fix_fee_refund = 0
	active_recipe_type = null
	active_recipe_ref = null
	active_recipe_config = null
	active_recipe_name = null
	active_operation_kind = null
	is_crafting = FALSE
	craft_finish_time = 0
	craft_total_time = 0
	suppress_surface_updates = previous_surface_update_suppression
	SStgui.update_uis(src)
	return operation_succeeded


/obj/structure/fake_machine/technician_workshop/proc/start_smelt(mob/living/user)
	if(!user || QDELETED(user) || !user.Adjacent(src))
		return FALSE
	if(is_crafting)
		to_chat(user, span_warning("The technician is already working on an item."))
		return FALSE

	var/list/current_items = get_staged_items()
	if(!length(current_items))
		to_chat(user, span_warning("Place ore on the workbench first."))
		return FALSE

	var/obj/item/ore/target = current_items[1]
	var/list/smelt_profile = get_technician_smelt_profile(target)
	if(!smelt_profile || !smelt_profile["supported"])
		to_chat(user, span_warning(smelt_profile ? smelt_profile["reason"] : "The first item on the workbench is not smeltable ore."))
		return FALSE
	if(!has_station_service("smelting"))
		to_chat(user, span_warning("Install a crucible to unlock ore smelting."))
		return FALSE

	var/service_fee = get_station_service_fee(smelt_profile["service_fee"], "smelting")
	if(!isnum(service_fee) || service_fee < 0 || round(service_fee) != service_fee || budget < service_fee)
		to_chat(user, span_warning("The workshop does not have enough amnas to smelt this ore."))
		return FALSE

	var/list/original_surface_order = current_items.Copy()
	var/previous_surface_update_suppression = suppress_surface_updates
	suppress_surface_updates = TRUE
	var/target_reserved = !QDELETED(target) && target.loc == staging_turf && target.forceMove(src)
	suppress_surface_updates = previous_surface_update_suppression
	if(!target_reserved)
		return FALSE

	budget -= service_fee
	active_smelt_target = target
	active_smelt_result_type = smelt_profile["result_type"]
	active_smelt_fee_refund = service_fee
	active_smelt_original_surface_order = original_surface_order
	active_recipe_type = null
	active_upgrade_recipe_type = null
	active_recipe_name = "Smelting [target.name]"
	active_operation_kind = "smelt"
	is_crafting = TRUE
	var/base_smelt_time = GLOB.technician_smelt_work_time
	if(!isnum(base_smelt_time) || base_smelt_time <= 0)
		base_smelt_time = 20 SECONDS
	craft_total_time = get_adjusted_work_time(base_smelt_time, "smelting")
	craft_finish_time = world.time + craft_total_time
	craft_timer_id = addtimer(CALLBACK(src, PROC_REF(complete_craft)), craft_total_time, TIMER_STOPPABLE)

	visible_message(span_notice("[src] begins smelting [target]. The technician begins working at the bench."))
	playsound(src, 'sound/misc/beep.ogg', 75, FALSE, -1)
	return TRUE


/obj/structure/fake_machine/technician_workshop/proc/restore_active_smelt_target(turf/drop_turf)
	if(!active_smelt_target || QDELETED(active_smelt_target) || !drop_turf)
		return
	if(active_smelt_target.loc == src)
		active_smelt_target.forceMove(drop_turf)
	var/list/restored_order = list()
	for(var/obj/item/original_item as anything in active_smelt_original_surface_order)
		if(original_item && !QDELETED(original_item) && original_item.loc == staging_turf)
			restored_order += original_item
	staged_items = restored_order


/obj/structure/fake_machine/technician_workshop/proc/complete_smelt()
	var/turf/output_turf = get_turf(src)
	var/operation_succeeded = FALSE
	var/obj/item/ore/ore_target = active_smelt_target
	var/ore_name = (ore_target && !QDELETED(ore_target)) ? ore_target.name : "ore"
	var/result_type = active_smelt_result_type
	var/previous_surface_update_suppression = suppress_surface_updates
	suppress_surface_updates = TRUE

	if(output_turf && ore_target && !QDELETED(ore_target) && ore_target.loc == src && ispath(result_type, /obj/item/ingot))
		var/obj/item/output_item = new result_type(output_turf)
		if(output_item && !QDELETED(output_item))
			qdel(ore_target)
			// The ingot replaces the consumed ore at the head of the staged list.
			// Remaining staged items retain their previous relative order.
			var/list/successful_surface_order = list()
			if(output_item.loc == staging_turf)
				successful_surface_order += output_item
			for(var/obj/item/original_item as anything in active_smelt_original_surface_order)
				if(!original_item || QDELETED(original_item) || original_item == ore_target || original_item == output_item)
					continue
				if(original_item.loc == staging_turf)
					successful_surface_order += original_item
			staged_items = successful_surface_order
			visible_message(span_notice("[src] finishes smelting [ore_name]. The ingot is left on the workbench."))
			playsound(src, 'sound/misc/smelter_fin.ogg', 90, FALSE)
			operation_succeeded = TRUE

	if(!operation_succeeded)
		log_game("Technician workshop at [AREACOORD(src)] failed smelting operation; restoring ore and refunding the service fee.")
		restore_active_smelt_target(output_turf)
		budget += active_smelt_fee_refund

	active_smelt_target = null
	active_smelt_result_type = null
	active_smelt_fee_refund = 0
	active_smelt_original_surface_order = list()
	active_recipe_type = null
	active_recipe_ref = null
	active_recipe_config = null
	active_recipe_name = null
	active_operation_kind = null
	is_crafting = FALSE
	craft_finish_time = 0
	craft_total_time = 0
	suppress_surface_updates = previous_surface_update_suppression
	SStgui.update_uis(src)
	return operation_succeeded

/obj/structure/fake_machine/technician_workshop/proc/start_craft(recipe_ref, mob/living/user)
	if(!user || QDELETED(user))
		return FALSE
	if(is_crafting)
		to_chat(user, span_warning("The technician is already working on an item."))
		return FALSE
	if(get_primary_staged_item())
		to_chat(user, span_warning("A workpiece is on the table. Use the upgrade catalogue or remove it before ordinary crafting."))
		return FALSE
	var/list/config = get_recipe_config_by_ref(recipe_ref)
	if(!islist(config) || !config["enabled"])
		return FALSE
	var/output_type = validate_technician_output_path(config["output_item_type"])
	var/list/resource_costs = config["resource_costs"]
	var/output_amount = config["output_amount"]
	var/base_fee = config["service_fee"]
	var/base_time = config["craft_time"]
	var/recipe_service = config["required_service"] ? config["required_service"] : TECH_STATION_SERVICE_CRAFTING
	if(!output_type || !islist(resource_costs) || !isnum(base_fee) || base_fee < 0 || round(base_fee) != base_fee || !isnum(base_time) || base_time <= 0 || round(base_time) != base_time || !isnum(output_amount) || round(output_amount) != output_amount || output_amount < 1 || output_amount > 20)
		return FALSE
	if(!(recipe_service in list(TECH_STATION_SERVICE_CRAFTING, TECH_STATION_SERVICE_METALWORKING, TECH_STATION_SERVICE_SMELTING, TECH_STATION_SERVICE_SEWING)) || !has_station_service(recipe_service))
		to_chat(user, span_warning("The workstation lacks the equipment required for this service."))
		return FALSE
	var/service_fee = get_station_service_fee(base_fee, recipe_service)
	var/work_time = get_adjusted_work_time(base_time, recipe_service)

	// Validate every requirement before modifying any stock or budget.
	for(var/resource_id in resource_costs)
		var/required_amount = resource_costs[resource_id]
		if(!istext(resource_id) || !length(resource_id) || !isnum(required_amount) || required_amount <= 0 || round(required_amount) != required_amount)
			return FALSE
		var/datum/technician_resource/required_resource = get_technician_resource_definition(resource_id)
		if(!required_resource)
			log_game("Technician recipe [recipe_ref] references unknown resource ID [resource_id].")
			return FALSE
		qdel(required_resource)
		if(get_resource_amount(resource_id) < required_amount)
			to_chat(user, span_warning("The workshop does not have enough [resource_id]."))
			return FALSE
		if(!can_consume_resource_source_stock(resource_id, required_amount))
			log_game("Technician workshop [REF(src)] has inconsistent source stock for craft resource [resource_id]; refusing craft.")
			to_chat(user, span_warning("The workshop's stored [resource_id] record is inconsistent. Contact an administrator."))
			return FALSE

	if(budget < service_fee)
		to_chat(user, span_warning("The workshop does not have enough amnas in its depot to pay the service fee."))
		return FALSE

	for(var/resource_id in resource_costs)
		var/required_amount = resource_costs[resource_id]
		resource_stock[resource_id] = get_resource_amount(resource_id) - required_amount
		consume_resource_source_stock(resource_id, required_amount)
	budget -= service_fee

	is_crafting = TRUE
	active_operation_kind = "craft"
	active_upgrade_recipe_type = null
	active_upgrade_target = null
	active_upgrade_ingredients = list()
	active_recipe_type = copytext(recipe_ref, 1, 8) == "custom:" ? null : text2path(recipe_ref)
	active_recipe_ref = recipe_ref
	active_recipe_config = technician_workshop_deep_copy(config)
	active_recipe_name = config["name"]
	craft_total_time = work_time
	craft_finish_time = world.time + craft_total_time
	craft_timer_id = addtimer(CALLBACK(src, PROC_REF(complete_craft)), craft_total_time, TIMER_STOPPABLE)

	visible_message(span_notice("[src] begins working. The technician begins working at the bench."))
	playsound(src, 'sound/misc/beep.ogg', 75, FALSE, -1)
	return TRUE

/obj/structure/fake_machine/technician_workshop/proc/complete_craft()
	craft_timer_id = null
	if(!is_crafting)
		return
	if(active_operation_kind == "upgrade")
		return complete_upgrade()
	if(active_operation_kind == "fix")
		return complete_fix()
	if(active_operation_kind == "smelt")
		return complete_smelt()

	var/turf/output_turf = get_turf(src)
	var/list/completion_config = active_recipe_config
	var/output_type = islist(completion_config) ? validate_technician_output_path(completion_config["output_item_type"]) : null
	var/output_count = islist(completion_config) ? completion_config["output_amount"] : 0
	var/list/output_properties = islist(completion_config) ? completion_config["output_properties"] : null
	var/completed_name = islist(completion_config) ? completion_config["name"] : active_recipe_name
	var/operation_succeeded = FALSE
	var/previous_surface_update_suppression = suppress_surface_updates
	suppress_surface_updates = TRUE
	if(output_turf && output_type && isnum(output_count) && round(output_count) == output_count && output_count >= 1 && output_count <= 20)
		for(var/i in 1 to output_count)
			var/obj/item/output_item = new output_type(output_turf)
			if(output_item && !QDELETED(output_item))
				if(islist(completion_config))
					if(istext(completion_config["output_name"]) && length(completion_config["output_name"]))
						output_item.name = completion_config["output_name"]
					if(istext(completion_config["output_desc"]))
						output_item.desc = completion_config["output_desc"]
					if(istext(completion_config["output_state"]) && length(completion_config["output_state"]))
						output_item.icon_state = completion_config["output_state"]
				apply_technician_workshop_output_properties(output_item, output_properties)
				operation_succeeded = TRUE
	if(operation_succeeded)
		visible_message(span_notice("[src] finishes crafting [completed_name]. The finished goods are left on the workbench."))
		playsound(src, 'sound/items/bsmith3.ogg', 75, TRUE)
	else
		log_game("Technician workshop at [AREACOORD(src)] could not finish recipe [active_recipe_ref]. Check the recipe's output type and quantity.")

	active_recipe_type = null
	active_recipe_ref = null
	active_recipe_config = null
	active_recipe_name = null
	active_operation_kind = null
	is_crafting = FALSE
	craft_finish_time = 0
	craft_total_time = 0
	suppress_surface_updates = previous_surface_update_suppression
	SStgui.update_uis(src)
	return operation_succeeded


// Mapper-friendly workstation variants. Every instance still owns its own
// station profile, resources, installed equipment and mammon depot.
/obj/structure/fake_machine/technician_workshop/metal_shop
	name = "metalworking technician's workbench"
	station_profile_type = /datum/technician_station_profile/metal_shop

/obj/structure/fake_machine/technician_workshop/smelting_bench
	name = "smelting technician's workbench"
	station_profile_type = /datum/technician_station_profile/smelting_bench

/obj/structure/fake_machine/technician_workshop/tailor
	name = "tailor's technician workbench"
	station_profile_type = /datum/technician_station_profile/tailor
