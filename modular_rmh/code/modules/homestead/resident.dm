#define RESIDENT_BALANCE_MIN 50
#define RESIDENT_BALANCE_MAX 150
#define RESIDENT_COST -4

/*
#define RESIDENT_ALLOWED_JOB_TYPES list( \
	/datum/job/roguetown/adventurer, \
	/datum/job/roguetown/mercenary, \
	/datum/job/roguetown/court_agent \
)
*/
/datum/quirk/positive/resident
	name = "Resident"
	desc = "I'm a resident of Rivermist Hollow. I have an account in the city's treasury and a home in the city."
	point_value = RESIDENT_COST
//	mob_trait = TRAIT_RESIDENT //If the quirk system is removed, replace it with traits.
	gain_text = span_notice("I feel at home in Rivermist Hollow.")
	lose_text = span_danger("I no longer feel like a local resident.")

	var/money_given = FALSE

/datum/quirk/positive/resident/on_spawn()
	if(gain_text && owner)
		to_chat(owner, gain_text)

/datum/quirk/positive/resident/on_remove()
	if(lose_text && owner)
		to_chat(owner, lose_text)

/datum/quirk/positive/resident/after_job_spawn(datum/job/job)
	apply_starting_money()

/datum/quirk/positive/resident/proc/apply_starting_money()
	if(money_given)
		return
	if(!owner || QDELETED(owner))
		return
	if(!ishuman(owner))
		return
	if(!SStreasury)
		return

	var/mob/living/carbon/human/H = owner
	var/starting_balance = rand(RESIDENT_BALANCE_MIN, RESIDENT_BALANCE_MAX)

	if(H in SStreasury.bank_accounts)
		SStreasury.generate_money_account(starting_balance, H)
	else
		SStreasury.create_bank_account(H, starting_balance)

	to_chat(H, span_notice("As a citizen of Rivermist Hollow, you receive [starting_balance] coins from the city treasury."))

	money_given = TRUE

/datum/job/towner/after_spawn(mob/living/carbon/human/spawned, client/player_client)
	. = ..()
	if(!spawned || QDELETED(spawned))
		return

	if(!spawned.has_quirk(/datum/quirk/positive/resident))
		spawned.add_quirk(/datum/quirk/positive/resident)

#undef RESIDENT_BALANCE_MIN
#undef RESIDENT_BALANCE_MAX
#undef RESIDENT_COST
