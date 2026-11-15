/// Upgrade recipes are intentionally separate from ordinary production recipes.
/// They transform a staged target item and may consume other physical items on
/// the workstation surface in addition to depot resources and its mammon fee.
/datum/technician_upgrade_recipe
	abstract_type = /datum/technician_upgrade_recipe

	var/name = "Unnamed upgrade"
	var/category = "Miscellaneous"
	var/desc = ""
	/// Optional station service required to offer and execute this upgrade.
	var/required_station_service = null

	/// Item type paths eligible to be the first staged item on the workstation.
	var/list/target_item_types = list()

	/// Replacement/output item type. The original target is consumed on success.
	var/obj/item/created_item
	var/output_icon_override
	var/output_icon_state_override

	/// Associative lists: item type path = count; resource ID = count.
	/// Physical item requirements must be staged after the primary target.
	var/list/required_items = list()
	var/list/resource_costs = list()

	/// Paid from the workstation's internal mammon depot.
	var/service_fee = 0
	/// Work duration in deciseconds. Uses the same unattended operation timer as crafting.
	var/craft_time = 10 SECONDS

	/// Preserve the target's current integrity percentage when replacing it.
	var/preserve_integrity = TRUE

/datum/technician_upgrade_recipe/proc/can_apply_to_target(obj/item/target)
	if(!target)
		return FALSE
	for(var/target_type as anything in target_item_types)
		if(ispath(target_type, /obj/item) && istype(target, target_type))
			return TRUE
	return FALSE

/// Default transformation creates the output on the workstation surface.
/// Custom recipes may override this to modify an item in place or preserve
/// recipe-specific state. Return the resulting item, or null on failure.
/datum/technician_upgrade_recipe/proc/apply_upgrade(obj/item/target, turf/output_turf)
	if(!target || QDELETED(target) || !output_turf || !ispath(created_item, /obj/item))
		return null

	var/obj/item/output_item = new created_item(output_turf)
	if(!output_item || QDELETED(output_item))
		return null

	if(preserve_integrity && target.uses_integrity && output_item.uses_integrity && target.max_integrity > 0 && output_item.max_integrity > 0)
		var/integrity_ratio = clamp(target.get_integrity() / target.max_integrity, 0, 1)
		output_item.update_integrity(round(output_item.max_integrity * integrity_ratio), FALSE)

	return output_item
