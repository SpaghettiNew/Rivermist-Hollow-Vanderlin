/// A resource accepted by a technician workshop.
/// Aggregate quantities are stored per workstation; source types are tracked so
/// withdrawal cannot turn raw ore into ingots (or otherwise upgrade materials).
/datum/technician_resource
	abstract_type = /datum/technician_resource
	var/id = ""
	var/name = "Unknown resource"
	/// Individual item types accepted as one resource unit each.
	var/list/accepted_item_types = list()
	/// If set, natural bundles with this stacktype are accepted by their amount.
	var/bundle_stacktype
	/// Number of resource units represented by one individual accepted item.
	var/units_per_item = 1
	/// Item whose icon is displayed beside the stock count in TGUI.
	var/obj/item/icon_item_type
	/// Optional override for the icon state shown in TGUI.
	var/icon_state_override

/datum/technician_resource/proc/get_deposit_amount(obj/item/I)
	if(!I)
		return 0
	if(!isnum(units_per_item) || units_per_item <= 0 || round(units_per_item) != units_per_item)
		return 0

	// Bundles contribute their real contents, not one unit per bundle object.
	if(bundle_stacktype && istype(I, /obj/item/natural/bundle))
		var/obj/item/natural/bundle/B = I
		if(B.stacktype != bundle_stacktype || !isnum(B.amount) || B.amount <= 0 || round(B.amount) != B.amount)
			return 0
		return B.amount

	for(var/accepted_type as anything in accepted_item_types)
		if(istype(I, accepted_type))
			return units_per_item

	return 0

/// Validates that a previously deposited representation can be recreated.
/datum/technician_resource/proc/can_withdraw_source_type(source_item_type, resource_amount)
	if(!ispath(source_item_type, /obj/item) || !isnum(resource_amount) || resource_amount <= 0)
		return FALSE

	if(ispath(source_item_type, /obj/item/natural/bundle))
		return !!bundle_stacktype

	if(!isnum(units_per_item) || units_per_item <= 0 || round(units_per_item) != units_per_item)
		return FALSE
	if(resource_amount % units_per_item)
		return FALSE

	for(var/accepted_type as anything in accepted_item_types)
		if(ispath(source_item_type, accepted_type))
			return TRUE
	return FALSE

/// Recreates the deposited item form on the workstation's turf.
/// Bundles are repacked up to their normal maxamount.
/datum/technician_resource/proc/create_withdrawal(turf/drop_turf, source_item_type, resource_amount)
	if(!drop_turf || !can_withdraw_source_type(source_item_type, resource_amount))
		return FALSE

	if(ispath(source_item_type, /obj/item/natural/bundle))
		var/remaining = resource_amount
		while(remaining > 0)
			var/obj/item/natural/bundle/B = new source_item_type(drop_turf)
			if(!B.maxamount || B.maxamount <= 0)
				qdel(B)
				return FALSE
			B.stacktype = bundle_stacktype
			B.amount = min(remaining, B.maxamount)
			B.update_bundle()
			remaining -= B.amount
		return TRUE

	var/item_count = resource_amount / units_per_item
	for(var/i in 1 to item_count)
		new source_item_type(drop_turf)
	return TRUE

/// Returns a temporary definition datum for an ID. The caller must qdel it.
/proc/get_technician_resource_definition(resource_id)
	if(!istext(resource_id) || !length(resource_id))
		return null

	for(var/datum/technician_resource/resource_type as anything in subtypesof(/datum/technician_resource))
		if(IS_ABSTRACT(resource_type))
			continue
		var/datum/technician_resource/R = new resource_type()
		if(R.id == resource_id)
			return R
		qdel(R)
	return null

/// Resolves a deposited item to a resource ID and quantity.
/// Returns null when the item is not an accepted resource.
/proc/get_technician_resource_deposit(obj/item/I)
	if(!I)
		return null

	for(var/datum/technician_resource/resource_type as anything in subtypesof(/datum/technician_resource))
		if(IS_ABSTRACT(resource_type))
			continue
		var/datum/technician_resource/R = new resource_type()
		var/deposit_amount = R.get_deposit_amount(I)
		if(deposit_amount > 0)
			var/list/result = list(
				"id" = R.id,
				"name" = R.name,
				"amount" = deposit_amount,
			)
			qdel(R)
			return result
		qdel(R)
	return null

// ---------------------------------------------------------------------------
// Prototype resources. Expand this list as the faction recipe catalogue grows.
// ---------------------------------------------------------------------------

/datum/technician_resource/iron
	id = "iron"
	name = "Iron"
	icon_item_type = /obj/item/ingot/iron
	accepted_item_types = list(
		/obj/item/ingot/iron,
	)

/datum/technician_resource/silver
	id = "silver"
	name = "Silver"
	icon_item_type = /obj/item/ingot/silver
	accepted_item_types = list(
		/obj/item/ingot/silver,
	)

/datum/technician_resource/gold
	id = "gold"
	name = "Gold"
	icon_item_type = /obj/item/ingot/gold
	accepted_item_types = list(
		/obj/item/ingot/gold,
	)

/datum/technician_resource/thaumic_iron
	id = "thaumic_iron"
	name = "Thaumic Iron"
	icon_item_type = /obj/item/ingot/thaumic
	accepted_item_types = list(
		/obj/item/ingot/thaumic,
	)

/datum/technician_resource/steel
	id = "steel"
	name = "Steel"
	icon_item_type = /obj/item/ingot/steel
	accepted_item_types = list(
		/obj/item/ingot/steel,
		/obj/item/ingot/steel_slag,
	)

/datum/technician_resource/tin
	id = "tin"
	name = "Tin"
	icon_item_type = /obj/item/ingot/tin
	accepted_item_types = list(
		/obj/item/ingot/tin,
	)

/datum/technician_resource/blastpowder
	id = "blastpowder"
	name = "Blastpowder"
	icon_item_type = /obj/item/reagent_containers/powder/blastpowder
	accepted_item_types = list(
		/obj/item/reagent_containers/powder/blastpowder,
	)

/datum/technician_resource/fiber
	id = "fiber"
	name = "Fiber"
	icon_item_type = /obj/item/natural/fibers
	accepted_item_types = list(
		/obj/item/natural/fibers,
	)
	bundle_stacktype = /obj/item/natural/fibers


/datum/technician_resource/stone
	id = "stone"
	name = "Stone"
	icon_item_type = /obj/item/natural/stone
	accepted_item_types = list(
		/obj/item/natural/stone,
	)

/datum/technician_resource/wood
	id = "wood"
	name = "Wood planks"
	icon_item_type = /obj/item/natural/wood/plank
	accepted_item_types = list(
		/obj/item/natural/wood/plank,
	)
	bundle_stacktype = /obj/item/natural/wood/plank

/datum/technician_resource/cured
	id = "cured"
	name = "Cured Leather"
	icon_item_type = /obj/item/natural/hide/cured
	accepted_item_types = list(
		/obj/item/natural/hide/cured,
	)
	bundle_stacktype = /obj/item/natural/hide/cured
