// ---------------------------------------------------------------------------
// Technician workstation paid smelting.
// Only ore that resolves directly to an ingot is accepted. The same
// smeltresult + recipe_quality contract used by Vanderlin's smelter is reused.
// ---------------------------------------------------------------------------

/// Fee charged by the technician for converting one ore object into its ingot.
GLOBAL_LIST_INIT(technician_smelt_fee_by_result, list(
	/obj/item/ingot/iron = 2,
	/obj/item/ingot/gold = 5,
	/obj/item/ingot/silver = 5,
	/obj/item/ingot/copper = 2,
	/obj/item/ingot/tin = 2,
))

/// Duration of a single unattended smelting operation.
GLOBAL_VAR_INIT(technician_smelt_work_time, 20 SECONDS)

/proc/get_technician_smelt_profile(obj/item/I)
	if(!istype(I, /obj/item/ore))
		return null

	var/result_type = I.smeltresult
	if(!ispath(result_type, /obj/item/ingot))
		return list(
			"supported" = FALSE,
			"reason" = "[I.name] does not produce an ingot when smelted.",
		)

	var/service_fee = GLOB.technician_smelt_fee_by_result[result_type]
	if(!isnum(service_fee) || service_fee < 0 || round(service_fee) != service_fee)
		return list(
			"supported" = FALSE,
			"reason" = "No technician smelting fee is configured for [initial(result_type:name)].",
		)

	return list(
		"supported" = TRUE,
		"reason" = "",
		"result_type" = result_type,
		"output_name" = initial(result_type:name),
		"output_icon" = "[initial(result_type:icon)]",
		"output_state" = "[initial(result_type:icon_state)]",
		"service_fee" = service_fee,
		"work_time" = GLOB.technician_smelt_work_time,
	)
