// ---------------------------------------------------------------------------
// Technician upgrade recipes.
// These datums are independent from /datum/technician_recipe and
// /datum/anvil_recipe. They transform an existing staged workpiece.
// ---------------------------------------------------------------------------

/// Attach a chain to an existing unarmed mantrap to make the throwable variant.
/datum/technician_upgrade_recipe/mantrap_throwable
	required_station_service = "metalworking"
	name = "Convert mantrap into throwing mantrap"
	category = "Weapons"
	desc = "Attach a chain to an unarmed mantrap, converting it into a weighted throwing weapon."
	target_item_types = list(/obj/item/restraints/legcuffs/beartrap)
	created_item = /obj/item/rope/net/bola/mantrap
	required_items = list(
		/obj/item/rope/chain = 1,
	)
	resource_costs = list()
	service_fee = 5
	craft_time = 20 SECONDS

/datum/technician_upgrade_recipe/mantrap_throwable/can_apply_to_target(obj/item/target)
	if(!..())
		return FALSE
	var/obj/item/restraints/legcuffs/beartrap/trap = target
	return !trap.armed
