/obj/item/bodypart/grabbedintents(mob/living/user, atom/grabbed, precise)
	return list(/datum/intent/grab/move, /datum/intent/grab/twist, /datum/intent/grab/smash)

/obj/item/bodypart/proc/has_grab_tackle(mob/living/user, atom/grabbed)
	if(!iscarbon(user) || !grabbed)
		return FALSE

	var/list/grabs = list(user.l_grab, user.r_grab)
	for(var/obj/item/grabbing/grab as anything in grabs)
		if(grab && grab.grabbed == grabbed && grab.grab_state >= GRAB_AGGRESSIVE)
			return TRUE
	return FALSE

/obj/item/bodypart/l_arm/grabbedintents(mob/living/user, atom/grabbed, precise)
	var/used_limb = precise
	var/list/intents = list(/datum/intent/grab/move, /datum/intent/grab/twist, /datum/intent/grab/smash)
	if(user == grabbed)
		return intents
	if(has_grab_tackle(user, grabbed))
		intents += /datum/intent/grab/shove
	if(used_limb == BODY_ZONE_PRECISE_L_HAND)
		intents += /datum/intent/grab/disarm
	else
		intents += /datum/intent/grab/armdrag
	return intents

/obj/item/bodypart/r_arm/grabbedintents(mob/living/user, atom/grabbed, precise)
	var/used_limb = precise
	var/list/intents = list(/datum/intent/grab/move, /datum/intent/grab/twist, /datum/intent/grab/smash)
	if(user == grabbed)
		return intents
	if(has_grab_tackle(user, grabbed))
		intents += /datum/intent/grab/shove
	if(used_limb == BODY_ZONE_PRECISE_R_HAND)
		intents += /datum/intent/grab/disarm
	else
		intents += /datum/intent/grab/armdrag
	return intents

/obj/item/bodypart/chest/grabbedintents(mob/living/user, atom/grabbed, precise)
	if(precise == BODY_ZONE_PRECISE_GROIN)
		if(user == grabbed)
			return list(/datum/intent/grab/move, /datum/intent/grab/twist)
		else
			return list(/datum/intent/grab/move, /datum/intent/grab/twist, /datum/intent/grab/shove)
	if(user == grabbed)
		return list(/datum/intent/grab/move)
	else
		return list(/datum/intent/grab/move, /datum/intent/grab/shove)
