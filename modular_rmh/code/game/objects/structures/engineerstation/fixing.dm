// ---------------------------------------------------------------------------
// Technician workstation repair pricing and material classification.
// This deliberately follows Vanderlin's player-facing repair capabilities:
//   - sewrepair = sewing / patching path used by repair kits
//   - anvilrepair = item is repairable through the metal / smithing path
// `armor_type` is NOT used as a material identifier; it describes protection.
// ---------------------------------------------------------------------------

#define TECH_FIX_CLOTH "cloth"
#define TECH_FIX_LEATHER "leather"
#define TECH_FIX_IRON "iron"
#define TECH_FIX_STEEL "steel"
#define TECH_FIX_PRECIOUS "precious"
#define TECH_FIX_DARKSTEEL "darksteel"

/// Amnas charged for each 5 percentage points of missing integrity.
/// Change these values here to rebalance workstation fixing.
GLOBAL_LIST_INIT(technician_fix_fee_per_five_percent, list(
	TECH_FIX_CLOTH = 1,
	TECH_FIX_LEATHER = 3,
	TECH_FIX_IRON = 5,
	TECH_FIX_STEEL = 10,
	TECH_FIX_PRECIOUS = 15,
	TECH_FIX_DARKSTEEL = 15,
))

/// A fully destroyed but recoverable item needs one unit of its matching stock.
/// This amount is configurable independently from the amna rates above.
GLOBAL_VAR_INIT(technician_fix_zero_integrity_material_cost, 1)

/// Hard maximum charge for one fixing operation, regardless of item material or damage.
GLOBAL_VAR_INIT(technician_fix_max_service_fee, 50)

/// Fixing uses the same unattended station operation system as crafting/upgrading.
GLOBAL_VAR_INIT(technician_fix_work_time, 20 SECONDS)

/// Resolve the base material through the item's own melt metadata, not its path.
/// The smeltresult fallback mirrors the anvil's expected-ingot resolution.
/proc/get_technician_fix_material_type(obj/item/I)
	if(!I)
		return null
	if(ispath(I.melting_material, /datum/material))
		return I.melting_material

	var/obj/item/smelt_result = I.smeltresult
	if(!ispath(smelt_result, /obj/item/ingot))
		return null
	if(ispath(smelt_result, /obj/item/ingot/steel_slag))
		return /datum/material/steel
	if(ispath(smelt_result, /obj/item/ingot/iron))
		return /datum/material/iron
	if(ispath(smelt_result, /obj/item/ingot/steel))
		return /datum/material/steel
	if(ispath(smelt_result, /obj/item/ingot/gold))
		return /datum/material/gold
	if(ispath(smelt_result, /obj/item/ingot/silver))
		return /datum/material/silver
	if(ispath(smelt_result, /obj/item/ingot/blacksteel))
		return /datum/material/blacksteel
	return null

/// Returns the repair category, fee rate, and material stock required at 0%.
/// Follows Vanderlin repair-kit precedence: anvilrepair + melting material first,
/// then sewrepair (patching skill -> leather; other sewrepair -> cloth).
/proc/get_technician_fix_material_profile(obj/item/I)
	if(!I)
		return null

	// Match Vanderlin's repair-kit precedence: metal repair is checked before
	// sewing. This matters for hybrid items that expose both repair paths.
	if(I.anvilrepair)
		var/material_type = get_technician_fix_material_type(I)
		if(!material_type)
			return list(
				"unsupported" = TRUE,
				"repair_method" = "Metal repair",
				"material_name" = "Unclassified metal",
				"reason" = "This item's melting material has no technician repair price configured.",
			)

		if(material_type == /datum/material/iron)
			return list(
				"repair_method" = "Ironworking",
				"price_key" = TECH_FIX_IRON,
				"material_name" = "Iron",
				"resource_id" = "iron",
			)
		if(material_type == /datum/material/steel)
			return list(
				"repair_method" = "Metalworking",
				"price_key" = TECH_FIX_STEEL,
				"material_name" = "Steel",
				"resource_id" = "steel",
			)
		if(material_type == /datum/material/gold)
			return list(
				"repair_method" = "Precious metalworking",
				"price_key" = TECH_FIX_PRECIOUS,
				"material_name" = "Gold",
				"resource_id" = "gold",
			)
		if(material_type == /datum/material/silver)
			return list(
				"repair_method" = "Precious metalworking",
				"price_key" = TECH_FIX_PRECIOUS,
				"material_name" = "Silver",
				"resource_id" = "silver",
			)
		if(material_type == /datum/material/blacksteel)
			return list(
				"repair_method" = "Darksteel working",
				"price_key" = TECH_FIX_DARKSTEEL,
				"material_name" = "Blacksteel",
				"physical_item_type" = /obj/item/ingot/blacksteel,
			)
		// Bronze, copper, tin and other metals have no agreed repair rate yet.
		return list(
			"unsupported" = TRUE,
			"repair_method" = "Metal repair",
			"material_name" = initial(material_type:name),
			"reason" = "No technician fixing price is configured for [initial(material_type:name)].",
		)

	// Items without an anvil repair path use the existing sewing / patching
	// path. These inherited fields handle colored and faction-specific subtypes.
	if(I.sewrepair)
		if(ispath(I.sewrepair, /datum/attribute/skill/craft/tanning/patching))
			return list(
				"repair_method" = "Leather patching",
				"price_key" = TECH_FIX_LEATHER,
				"material_name" = "Cured leather",
				"resource_id" = "cured",
			)
		return list(
			"repair_method" = "Sewing",
			"price_key" = TECH_FIX_CLOTH,
			"material_name" = "Fiber",
			"resource_id" = "fiber",
		)

	return null

/// Complete current fixing quote. Missing integrity is priced in 5% increments;
/// fractional increments round up because mammons are integer-valued.
/proc/get_technician_fix_profile(obj/item/I)
	if(!I || !I.uses_integrity || I.max_integrity <= 0)
		return null

	var/list/material_profile = get_technician_fix_material_profile(I)
	if(!material_profile)
		return null

	var/list/result = material_profile.Copy()
	result["eligible"] = TRUE
	result["supported"] = !material_profile["unsupported"]
	result["current_integrity"] = I.get_integrity()
	result["max_integrity"] = I.max_integrity
	var/integrity_percent_exact = (I.get_integrity() / I.max_integrity) * 100
	var/missing_percent_exact = ((I.max_integrity - I.get_integrity()) / I.max_integrity) * 100
	result["integrity_percent"] = round(integrity_percent_exact, 0.01)
	result["missing_percent"] = round(missing_percent_exact, 0.01)
	result["service_fee"] = 0
	result["resource_costs"] = list()
	result["resource_requirements"] = list()
	result["physical_item_requirements"] = list()

	if(!result["supported"])
		return result

	var/price_per_five = GLOB.technician_fix_fee_per_five_percent[result["price_key"]]
	if(!isnum(price_per_five) || price_per_five < 0 || round(price_per_five) != price_per_five)
		result["supported"] = FALSE
		result["reason"] = "The fixing price for this repair category is not configured correctly."
		return result

	if(missing_percent_exact > 0)
		// Charge for every started 5% band, including small damage values that
		// would otherwise be rounded away by the UI percentage display.
		var/price_steps = floor((missing_percent_exact / 5) + 0.999999)
		var/raw_service_fee = price_steps * price_per_five
		var/max_service_fee = GLOB.technician_fix_max_service_fee
		if(!isnum(max_service_fee) || max_service_fee < 0 || round(max_service_fee) != max_service_fee)
			max_service_fee = 50
		result["service_fee"] = min(raw_service_fee, max_service_fee)

	// Rebuilding an item displayed at 0% integrity requires one unit of its associated
	// material. Partial repairs do not consume this additional material.
	// Only truly zero-integrity items require this extra material. Items held
	// at 1 integrity by ITEM_ONLY_BREAK are still priced by their missing integrity.
	if(I.get_integrity() <= 0 && GLOB.technician_fix_zero_integrity_material_cost > 0)
		var/required_amount = GLOB.technician_fix_zero_integrity_material_cost
		var/physical_item_type = result["physical_item_type"]
		if(ispath(physical_item_type, /obj/item))
			// Rare bars are intentionally staged as physical inputs. They are not
			// deposited into the generic depot and cannot be fabricated from a counter.
			result["physical_item_requirements"][physical_item_type] = required_amount
			result["item_requirements"] = list(list(
				"id" = "[physical_item_type]",
				"name" = "[initial(physical_item_type:name)]",
				"required" = required_amount,
				"available" = 0,
				"missing" = required_amount,
				"icon" = "[initial(physical_item_type:icon)]",
				"icon_state" = "[initial(physical_item_type:icon_state)]",
			))
		else
			var/resource_id = result["resource_id"]
			var/datum/technician_resource/R = get_technician_resource_definition(resource_id)
			if(!R)
				result["supported"] = FALSE
				result["reason"] = "The required [result["material_name"]] resource is not registered with this workstation."
				return result
			// The per-station stock value is supplied by the caller in the UI layer.
			var/available_amount = 0
			result["resource_costs"][resource_id] = required_amount
			result["resource_requirements"] += list(list(
				"id" = resource_id,
				"name" = R.name,
				"required" = required_amount,
				"available" = available_amount,
				"missing" = required_amount,
				"icon" = ispath(R.icon_item_type, /obj/item) ? "[initial(R.icon_item_type:icon)]" : "",
				"icon_state" = ispath(R.icon_item_type, /obj/item) ? (R.icon_state_override ? R.icon_state_override : "[initial(R.icon_item_type:icon_state)]") : "",
			))
			qdel(R)

	return result

#undef TECH_FIX_CLOTH
#undef TECH_FIX_LEATHER
#undef TECH_FIX_IRON
#undef TECH_FIX_STEEL
#undef TECH_FIX_PRECIOUS
#undef TECH_FIX_DARKSTEEL
