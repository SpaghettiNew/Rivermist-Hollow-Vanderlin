// Disabled: made any storage a bag of holding. Keep the bag of holding unique.
/*
/datum/enchantment/pocket_dimension
	enchantment_name = "Pocket Dimension"
	examine_text = "A stable fold in space yawns beyond this container."
	essence_recipe = list(
		/datum/thaumaturgical_essence/magic = 50,
	)
	required_type = /obj/item/storage
	var/datum/component/pocket_access/pocket_access

/datum/enchantment/pocket_dimension/can_enchant(atom/item)
	return !item.GetComponent(/datum/component/pocket_access)

/datum/enchantment/pocket_dimension/register_triggers(atom/item)
	. = ..()
	pocket_access = item.AddComponent(\
		/datum/component/pocket_access,\
		/datum/map_template/pocket/bag_of_holding,\
		POCKET_ACCESS_INSTANCE_OWNER,\
		POCKET_LIFECYCLE_HIBERNATE,\
		5 MINUTES,\
		null,\
		FALSE,\
		FALSE,\
		TRUE,\
		"Enchanted Pocket",\
		"The container opens onto a private fold in space. Step through?",\
		null,\
		"The enchantment unravels, and folded space throws everything back out!"\
	)
	registered_signals += COMSIG_STORAGE_ADDED
	RegisterSignal(item, COMSIG_STORAGE_ADDED, PROC_REF(on_item_stored))

/datum/enchantment/pocket_dimension/unregister_triggers()
	if(pocket_access)
		qdel(pocket_access)
		pocket_access = null
	return ..()

/datum/enchantment/pocket_dimension/proc/on_item_stored(atom/source, obj/item/added)
	SIGNAL_HANDLER
	INVOKE_ASYNC(src, PROC_REF(store_added_item), source, added)

/datum/enchantment/pocket_dimension/proc/store_added_item(atom/source, obj/item/added)
	if(!pocket_access || !added || QDELETED(added))
		return
	if(added.loc != source)
		return
	if(added.GetComponent(/datum/component/pocket_access))
		return
	pocket_access.store_movable_for_user(null, added, get_turf(source))
*/
