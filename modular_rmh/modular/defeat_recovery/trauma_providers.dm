/// A resource-backed trauma station. It is intentionally not mapped here: mappers can place it
/// wherever it fits, and tune the provider datum without changing the interaction contract.
/// Physical aftermath is its specialty; it also treats spiritual aftermath and Convalescence.
/obj/machinery/defeat_medical_machine
	name = "trauma treatment apparatus"
	desc = "A compact medical frame for diagnosing and treating one defeat aftermath at a time, including Convalescence. Without Apprentice Medicine, treatment takes twice as long. Physical aftermath costs one to three bandages by severity; spiritual aftermath needs one extra bandage and takes twice as long. Click to diagnose a patient beside it, or use bandages on it to treat."
	icon = 'icons/roguetown/misc/machines.dmi'
	icon_state = "lottery"
	density = TRUE
	var/datum/defeat_trauma_provider/medical/machine/treatment_provider

/obj/machinery/defeat_medical_machine/Initialize(mapload)
	. = ..()
	treatment_provider = new(src)

/obj/machinery/defeat_medical_machine/Destroy()
	QDEL_NULL(treatment_provider)
	return ..()

/obj/machinery/defeat_medical_machine/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(. || QDELETED(treatment_provider))
		return
	treatment_provider.station_interact(user, user.get_active_held_item())
	return TRUE

/obj/machinery/defeat_medical_machine/attackby(obj/item/offering, mob/living/user, list/modifiers)
	if(QDELETED(user) || QDELETED(offering) || QDELETED(treatment_provider) || !treatment_provider.accepts_resource(offering))
		return ..()
	treatment_provider.station_interact(user, offering)
	return TRUE

/// A resource-backed trauma shrine. Silver remains in the user's hand throughout diagnosis and the
/// rite, and is debited only once the selected trauma has passed its final validation. Spiritual
/// aftermath is its specialty; it also treats physical aftermath and Convalescence.
/obj/structure/defeat_trauma_shrine
	name = "shrine of solace"
	desc = "A small shrine for soothing one defeat aftermath at a time. Without Novice Miracles or holy devotion, treatment takes twice as long. Spiritual aftermath costs one to three silver coins by severity; physical aftermath costs and takes twice as long. Click it to diagnose a patient beside it, or offer silver to begin a rite."
	icon = 'modular_rmh/icons/obj/structures/statues/shrine_of_solace.dmi'
	icon_state = "statue"
	pixel_x = -16
	base_pixel_x = -16
	density = TRUE
	anchored = TRUE
	var/datum/defeat_trauma_provider/shrine/structure/treatment_provider
	/// Seven one-decisecond frames of the "effect" state: one full play.
	var/activation_duration = 0.7 SECONDS

/obj/structure/defeat_trauma_shrine/Initialize(mapload)
	. = ..()
	treatment_provider = new(src)

/obj/structure/defeat_trauma_shrine/Destroy()
	QDEL_NULL(treatment_provider)
	return ..()

/obj/structure/defeat_trauma_shrine/attack_hand(mob/living/user, list/modifiers)
	. = ..()
	if(. || QDELETED(treatment_provider))
		return
	treatment_provider.station_interact(user, user.get_active_held_item())
	return TRUE

/obj/structure/defeat_trauma_shrine/attackby(obj/item/offering, mob/living/user, list/modifiers)
	if(QDELETED(user) || QDELETED(offering) || QDELETED(treatment_provider) || !treatment_provider.accepts_resource(offering))
		return ..()
	treatment_provider.station_interact(user, offering)
	return TRUE

/// Plays the "effect" overlay once over the statue.
/obj/structure/defeat_trauma_shrine/proc/play_activation()
	flick_overlay_view(mutable_appearance(icon, "effect"), activation_duration)

/datum/defeat_trauma_provider/shrine/structure/on_treatment_complete(mob/living/patient, mob/living/helper)
	var/obj/structure/defeat_trauma_shrine/shrine = resolve_host()
	if(istype(shrine))
		shrine.play_activation()

/// Both providers are ordinary blueprint constructions and therefore appear in the existing globally
/// reachable construction browser. They require no map placement or special roundstart grant.
/datum/blueprint_recipe/engineering/defeat_medical_machine
	name = "trauma treatment apparatus"
	desc = "A bandage-fed station that diagnoses and treats one defeat aftermath or Convalescence, specializing in physical harm."
	result_type = /obj/machinery/defeat_medical_machine
	required_materials = list(
		/obj/item/ingot/iron = 2,
		/obj/item/natural/wood/plank = 2,
		/obj/item/natural/glass = 1,
	)
	supports_directions = TRUE
	craftdiff = 2
	build_time = 8 SECONDS

/datum/blueprint_recipe/masonry/defeat_trauma_shrine
	name = "shrine of solace"
	desc = "A silver-fed shrine that diagnoses and soothes one defeat aftermath or Convalescence, specializing in spiritual harm."
	result_type = /obj/structure/defeat_trauma_shrine
	required_materials = list(
		/obj/item/natural/stone = 4,
		/obj/item/ingot/silver = 1,
	)
	supports_directions = TRUE
	craftdiff = 1
	build_time = 6 SECONDS
