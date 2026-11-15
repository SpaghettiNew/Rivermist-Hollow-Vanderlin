
/*
* I think this is placed here because its
* used to tell people what their income is
* in a non fantasy tone. This is used here
* and in the drugmachine.dm.
*/
/proc/send_ooc_note(msg, name, job)
	var/list/names_to = list()
	if(name)
		names_to += name
	if(job)
		var/list/L = list()
		if(islist(job))
			L = job
		else
			L += job
		for(var/J in L)
			for(var/mob/living/carbon/human/X in GLOB.human_list)
				if(X.job == J)
					names_to |= X.real_name
	if(names_to.len)
		for(var/mob/living/carbon/human/X in GLOB.human_list)
			if(X.real_name in names_to)
				if(!X.stat)
					to_chat(X, "<span class='info'>[msg]</span>")

/*
* The Treasury system is the ocean
* in which the steward sails.
*/
SUBSYSTEM_DEF(treasury)
	name = "Treasury"
	wait = 1
	init_order = INIT_ORDER_TREASURY
	priority = FIRE_PRIORITY_WATER_LEVEL
	var/tax_value = 0.1
	var/queens_tax = 0.15
	var/treasury_value = 0
	var/list/bank_accounts = list()
	var/list/untaxed_deposits = list()
	var/list/noble_incomes = list()
	var/list/stockpile_datums = list()
	var/multiple_item_penalty = 0.7
	var/interest_rate = 0.15
	var/next_treasury_check = 0
	var/list/log_entries = list()
	var/list/vault_accounting = list() //used for the vault count, cleared every fire()

/// Maps a stable mind to its existing Treasury account key.
	var/list/bank_account_owner_by_mind = list()

/// Structured audit trail for transfers, deposits, withdrawals and payroll.
	var/list/finance_ledger = list()

/// Per-day payroll results, keyed by stable mind identity.
	var/list/payroll_ledger = list()

/// Day keys whose payroll processing has completed.
	var/list/payroll_completed_days = list()

/// Payroll notifications waiting for a disconnected character to return.
	var/list/pending_payroll_notifications = list()

/datum/controller/subsystem/treasury/proc/resolve_bank_account_key(owner)
	if(!owner)
		return null

	if(istype(owner, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = owner

		if(H.mind)
			var/existing_key = bank_account_owner_by_mind[H.mind]
			if(existing_key && (existing_key in bank_accounts))
				return existing_key

		if(owner in bank_accounts)
			if(H.mind)
				bank_account_owner_by_mind[H.mind] = owner
			return owner

	return owner


/datum/controller/subsystem/treasury/proc/record_financial_transaction(list/entry)
	if(!islist(entry))
		return FALSE

	var/list/stored_entry = entry.Copy()
	stored_entry["world_time"] = world.time
	finance_ledger += list(stored_entry)

	return TRUE


/datum/controller/subsystem/treasury/proc/notify_payroll_mind(datum/mind/recipient_mind, message)
	if(!recipient_mind || !message)
		return FALSE

	var/mob/recipient = recipient_mind.current
	if(recipient?.client)
		to_chat(recipient, message)
		return TRUE

	var/list/pending = pending_payroll_notifications[recipient_mind]
	if(!islist(pending))
		pending = list()
		pending_payroll_notifications[recipient_mind] = pending

	pending += message
	return FALSE


/datum/controller/subsystem/treasury/proc/deliver_pending_payroll_notifications(datum/mind/recipient_mind)
	if(!recipient_mind)
		return FALSE

	var/mob/recipient = recipient_mind.current
	if(!recipient?.client)
		return FALSE

	var/list/pending = pending_payroll_notifications[recipient_mind]
	if(!islist(pending) || !length(pending))
		return FALSE

	for(var/message in pending)
		to_chat(recipient, message)

	pending_payroll_notifications -= recipient_mind
	return TRUE

/datum/controller/subsystem/treasury/Initialize()
	//Randomizes the roundstart amount of money and the queens tax.
	treasury_value = rand(800,1200)
	force_set_round_statistic(STATS_STARTING_TREASURY, treasury_value)
	queens_tax = pick(0.09, 0.15, 0.21, 0.30)

	//For the merchants import and export.
	for(var/path in subtypesof(/datum/stock/bounty))
		var/datum/D = new path
		stockpile_datums += D
	for(var/path in subtypesof(/datum/stock/stockpile))
		var/datum/D = new path
		if(istype(D, /datum/stock/stockpile/custom))
			continue
		stockpile_datums += D
	for(var/path in subtypesof(/datum/stock/import))
		var/datum/D = new path
		stockpile_datums += D
	return ..()

/datum/controller/subsystem/treasury/fire(resumed = 0)
	if(world.time > next_treasury_check)
		//I dont know why the treasury check is randomized
		next_treasury_check = world.time + rand(8 MINUTES, 12 MINUTES)
		if(SSticker.current_state == GAME_STATE_PLAYING)
			//Stock price updated based on demand variable.
			for(var/datum/stock/X in stockpile_datums)
				if(!X.stable_price && !X.transport_item)
					if(X.demand < initial(X.demand))
						X.demand += rand(5,15)
					if(X.demand > initial(X.demand))
						X.demand -= rand(5,15)

		//Checks all items in the vault.
		var/amt_to_generate = CalcVaultIncome()

		/*
		* This is the final calculations of how
		* much passive income the kingdom makes.
		* exsample: 4 items worth 100 mammon
		* individually will produce (productprice*0.25)
		* before the total suffers from the queens tax
		* which ranges from 9% to 30%. Some rounds
		* will just be harder for the Steward than others.
		*/
		amt_to_generate = amt_to_generate - (amt_to_generate * queens_tax)
		amt_to_generate = round(amt_to_generate)
		give_money_treasury(amt_to_generate, "Wealth Hoard")
		force_set_round_statistic(STATS_REGULAR_VAULT_INCOME, amt_to_generate)
		record_round_statistic(STATS_VAULT_TOTAL_REVENUE, amt_to_generate)
		for(var/mob/living/carbon/human/X in GLOB.human_list)
			if(!X.mind)
				continue
			if(is_burgmeister_job(X.mind.assigned_role) || is_banker_job(X.mind.assigned_role))
				send_ooc_note("Income from wealth horde: +[amt_to_generate]", name = X.real_name)
				return

/*
* Calculates Passive income based
* on the items that are placed within
* the vault. Resets vault tracking of duplicate items
*/
/datum/controller/subsystem/treasury/proc/CalcVaultIncome()
	vault_accounting = list()
	var/area/A = GLOB.areas_by_type[/area/indoors/town/vault]
	var/passive_income = 0
	for(var/obj/I in A)
		if(!isturf(I.loc))
			continue
		if(isitem(I))
			passive_income += add_to_vault(I)
		else if(istype(I, /obj/structure/closet))
			for(var/obj/item/item in I.contents)
				passive_income += add_to_vault(item)

	return passive_income

/datum/controller/subsystem/treasury/proc/add_to_vault(obj/item/item)
	var/list/objects_to_search = list(item)
	var/datum/component/storage/storage = item.GetComponent(/datum/component/storage)
	if(storage)
		objects_to_search |= storage.contents()
	var/total_value = 0
	for(var/atom/movable/movable_atom in objects_to_search)
		if(is_type_in_typecache(movable_atom, GLOB.ITEM_DOES_NOT_GENERATE_VAULT_RENT))
			continue
		if(movable_atom.get_real_price() <= 0)
			continue
		//Passive income is 15% of the items worth.
		var/item_value = movable_atom.get_real_price() * interest_rate
		vault_accounting[movable_atom.type] += 1
		if(vault_accounting[movable_atom.type] > 1)
			item_value *= (multiple_item_penalty ** (vault_accounting[movable_atom.type]-1))
		total_value += item_value
	return total_value

/*
* These procs are all called directly from
* things outside of the system.
*/
/datum/controller/subsystem/treasury/proc/create_bank_account(name, initial_deposit)
	if(!name)
		return FALSE

	var/account_key = resolve_bank_account_key(name)
	if(!account_key || (account_key in bank_accounts))
		return FALSE

	var/starting_balance = 0
	if(isnum(initial_deposit))
		starting_balance = max(0, floor(initial_deposit))

	bank_accounts[account_key] = starting_balance

	var/datum/mind/account_mind
	var/account_name = "[name]"

	if(istype(name, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = name
		account_mind = H.mind
		account_name = H.real_name

		if(account_mind)
			bank_account_owner_by_mind[account_mind] = account_key

	record_financial_transaction(list("transaction_type" = "account_creation", "recipient_identity" = account_mind ? REF(account_mind) : null, "recipient_label" = account_name, "initial_balance" = starting_balance, "status" = "completed",))

	return TRUE

//increments the treasury directly (tax collection)
/datum/controller/subsystem/treasury/proc/give_money_treasury(amt, source, silent = FALSE)
	if(!isnum(amt) || !amt)
		return FALSE

	var/treasury_before = treasury_value
	treasury_value += amt

	var/transaction_type = "treasury_credit"
	if(amt < 0)
		transaction_type = "treasury_debit"

	record_financial_transaction(list("transaction_type" = transaction_type, "source" = source, "amount" = abs(amt), "status" = "completed", "treasury_before" = treasury_before, "treasury_after" = treasury_value,))

	if(silent)
		return TRUE

	if(source)
		log_to_steward("[amt] to Treasury ([source])")
	else
		log_to_steward("[amt] to Treasury")

	return TRUE

//pays to account (if it exists) from treasury (payroll). Not taxed
/datum/controller/subsystem/treasury/proc/give_money_account(amt, target, source, notify = TRUE, transaction_type = "transfer", day_number = null)
	if(!isnum(amt) || !target)
		return FALSE

	amt = floor(amt)
	if(!amt)
		return FALSE

	var/target_name = "[target]"
	var/datum/mind/target_mind

	if(istype(target, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = target
		target_name = H.real_name
		target_mind = H.mind

	// Positive payments transfer money from the city Treasury.
	if(amt > 0)
		var/list/result = transfer_treasury_batch(
			list(list("target" = target, "amount" = amt, )), source, transaction_type, day_number,)

		if(!result["success"])
			var/failure_reason = result["reason"]

			record_financial_transaction(list(
				"transaction_type" = transaction_type,
				"day_number" = day_number,
				"source" = source,
				"amount" = amt,
				"recipient_identity" = target_mind ? REF(target_mind) : null,
				"recipient_label" = target_name,
				"status" = failure_reason,
				"treasury_balance" = treasury_value,
			))

			log_to_steward("Transfer failed to [target_name]: [failure_reason], [amt] amna requested from Treasury.")

			if(notify)
				if(failure_reason == "insufficient_treasury")
					send_ooc_note("<b>MEISTER:</b> Error: Insufficient treasury funds to transfer [amt] amna.", name = target_name,)
				else
					send_ooc_note(
						"<b>MEISTER:</b> Error: Account transfer failed ([failure_reason]).", name = target_name,)

			return FALSE

		if(notify)
			if(source)
				send_ooc_note("<b>MEISTER:</b> Your account has received [amt] amna. ([source])", name = target_name,)
			else
				send_ooc_note("<b>MEISTER:</b> Your account has received [amt] amna.", name = target_name,)

		return TRUE

	// Preserve the existing fine behavior for negative amounts.
	var/account_key = resolve_bank_account_key(target)
	if(!account_key || !(account_key in bank_accounts))
		record_financial_transaction(list(
			"transaction_type" = "fine",
			"source" = source,
			"amount" = abs(amt),
			"recipient_identity" = target_mind ? REF(target_mind) : null,
			"recipient_label" = target_name,
			"status" = "missing_account",
			"treasury_balance" = treasury_value,))
		return FALSE

	var/account_balance = bank_accounts[account_key]
	if(!isnum(account_balance) || account_balance < 0)
		return FALSE

	var/fine_amount = min(abs(amt), account_balance)
	if(fine_amount <= 0)
		return FALSE

	var/balance_before = account_balance
	bank_accounts[account_key] = balance_before - fine_amount

	record_financial_transaction(list(
		"transaction_type" = "fine",
		"source" = source,
		"amount" = fine_amount,
		"recipient_identity" = target_mind ? REF(target_mind) : null,
		"recipient_label" = target_name,
		"status" = "completed",
		"treasury_before" = treasury_value,
		"treasury_after" = treasury_value,
		"account_before" = balance_before,
		"account_after" = bank_accounts[account_key],))

	if(notify)
		if(source)
			send_ooc_note("<b>MEISTER:</b> Your account was fined [fine_amount] amna. ([source])", name = target_name,)
		else
			send_ooc_note("<b>MEISTER:</b> Your account was fined [fine_amount] amna.", name = target_name,)

	log_to_steward("[fine_amount] was fined from [target_name] ([source])")
	return TRUE

///Deposits money into a character's bank account. Taxes are deducted from the deposit and added to the treasury.
///@param amt: The amount of money to deposit.
///@param character: The character making the deposit.
///@return a list(original deposit, taxed amount) if the money was successfully deposited, FALSE otherwise.
/// Deposits existing cash into a character account.
/// Treasury receives the gross deposit; the account receives the net deposit.
/// The tax and account changes are committed only after the account validates.
/datum/controller/subsystem/treasury/proc/generate_money_account(amt, mob/living/carbon/human/character)
	if(!isnum(amt) || amt <= 0 || !character)
		return FALSE

	amt = floor(amt)
	if(amt <= 0)
		return FALSE

	var/account_key = resolve_bank_account_key(character)
	if(!account_key || !(account_key in bank_accounts))
		return FALSE

	var/account_balance = bank_accounts[account_key]
	if(!isnum(account_balance) || account_balance < 0)
		return FALSE

	var/taxed_amount = 0
	var/net_deposit = amt
	var/previous_untaxed = untaxed_deposits[account_key]
	if(!isnum(previous_untaxed))
		previous_untaxed = 0

	var/remaining_untaxed = previous_untaxed

	if(!HAS_TRAIT(character, TRAIT_NOBLE))
		var/taxable_amount = previous_untaxed + amt
		var/potential_tax = round(taxable_amount * tax_value)
		remaining_untaxed = taxable_amount

		if(potential_tax >= 1)
			taxed_amount = potential_tax
			var/taxed_portion = round(taxed_amount / tax_value)
			net_deposit = (taxable_amount - taxed_amount) - previous_untaxed
			remaining_untaxed = taxable_amount - taxed_portion

	if(net_deposit < 0)
		return FALSE

	var/treasury_before = treasury_value

	// All checks completed: deposit the gross amount and credit the net amount.
	treasury_value += amt
	bank_accounts[account_key] = account_balance + net_deposit

	if(!HAS_TRAIT(character, TRAIT_NOBLE))
		untaxed_deposits[account_key] = remaining_untaxed

	record_financial_transaction(list("transaction_type" = "cash_deposit",
		"amount" = amt,
		"tax_amount" = taxed_amount,
		"credited_amount" = net_deposit,
		"recipient_identity" = character.mind ? REF(character.mind) : null,
		"recipient_label" = character.real_name,
		"status" = "completed",
		"treasury_before" = treasury_before,
		"treasury_after" = treasury_value,
		"account_before" = account_balance,
		"account_after" = bank_accounts[account_key],))

	log_to_steward("+[amt] deposited by [character.real_name] of which taxed [taxed_amount]")

	return list(amt, taxed_amount)

/datum/controller/subsystem/treasury/proc/withdraw_money_account(amt, target)
	if(!isnum(amt) || amt <= 0 || !target)
		return FALSE

	amt = floor(amt)
	if(amt <= 0)
		return FALSE

	var/target_name = "[target]"
	var/datum/mind/target_mind

	if(istype(target, /mob/living/carbon/human))
		var/mob/living/carbon/human/H = target
		target_name = H.real_name
		target_mind = H.mind

	var/account_key = resolve_bank_account_key(target)
	if(!account_key || !(account_key in bank_accounts))
		return FALSE

	var/account_balance = bank_accounts[account_key]
	if(!isnum(account_balance) || account_balance < amt)
		send_ooc_note("<b>MEISTER:</b> Error: Insufficient funds in the account to complete the withdrawal.", name = target_name,)
		return FALSE

	if(treasury_value < amt)
		send_ooc_note("<b>MEISTER:</b> Error: Insufficient funds in the treasury to complete the transaction.", name = target_name,)
		return FALSE

	var/treasury_before = treasury_value

	bank_accounts[account_key] = account_balance - amt
	treasury_value -= amt

	record_financial_transaction(list("transaction_type" = "cash_withdrawal",
		"amount" = amt,
		"recipient_identity" = target_mind ? REF(target_mind) : null,
		"recipient_label" = target_name,
		"status" = "completed",
		"treasury_before" = treasury_before,
		"treasury_after" = treasury_value,
		"account_before" = account_balance,
		"account_after" = bank_accounts[account_key],))

	log_to_steward("-[amt] withdrawn by [target_name]")
	return TRUE

/datum/controller/subsystem/treasury/proc/log_to_steward(log)
	log_entries += log
	return

/datum/controller/subsystem/treasury/proc/distribute_estate_incomes()
	for(var/mob/living/welfare_dependant in noble_incomes)
		var/how_much = noble_incomes[welfare_dependant]
		record_round_statistic(STATS_NOBLE_INCOME_TOTAL, how_much)
		give_money_treasury(how_much, silent = TRUE)
		give_money_account(how_much, welfare_dependant, "Dusk Spire Noble Estate")

/// Atomically transfers money from the city Treasury to one or more
/// existing character accounts. Every transaction must have a target and
/// a positive integer amount. No funds move when validation fails.
/datum/controller/subsystem/treasury/proc/transfer_treasury_batch(list/transactions, source, transaction_type = "transfer", day_number = null)
	if(!islist(transactions) || !length(transactions))
		return list(
			"success" = FALSE,
			"reason" = "empty_batch",
		)

	var/list/validated = list()
	var/list/seen_account_keys = list()
	var/total_amount = 0

	for(var/list/request in transactions)
		var/target = request["target"]
		var/amount = request["amount"]

		if(!target || !isnum(amount) || amount <= 0)
			return list(
				"success" = FALSE,
				"reason" = "invalid_request",
			)

		amount = floor(amount)
		if(amount <= 0)
			return list(
				"success" = FALSE,
				"reason" = "invalid_amount",
			)

		var/account_key = resolve_bank_account_key(target)
		if(!account_key || !(account_key in bank_accounts))
			return list(
				"success" = FALSE,
				"reason" = "missing_account",
				"target" = target,)

		if(account_key in seen_account_keys)
			return list(
				"success" = FALSE,
				"reason" = "duplicate_account",)

		seen_account_keys += account_key

		var/account_balance = bank_accounts[account_key]
		if(!isnum(account_balance) || account_balance < 0)
			return list(
				"success" = FALSE,
				"reason" = "invalid_account_balance",
				"target" = target,)

		var/datum/mind/target_mind
		var/target_name = "[target]"
		var/target_job_title = request["job_title"]

		if(istype(target, /mob/living/carbon/human))
			var/mob/living/carbon/human/H = target
			target_mind = H.mind
			target_name = H.real_name

			if(!target_job_title && target_mind?.assigned_role)
				var/datum/job/J = target_mind.assigned_role
				target_job_title = J.title

		validated += list(list(
			"target" = target,
			"account_key" = account_key,
			"mind" = target_mind,
			"identity" = target_mind ? REF(target_mind) : null,
			"target_name" = target_name,
			"job_title" = target_job_title,
			"amount" = amount,
			"balance_before" = account_balance,))

		total_amount += amount

	var/treasury_before = treasury_value

	// Whole-batch affordability check: no account changes have happened yet.
	if(treasury_before < total_amount)
		return list(
			"success" = FALSE,
			"reason" = "insufficient_treasury",
			"required" = total_amount,
			"available" = treasury_before,
			"shortfall" = total_amount - treasury_before,)

	// Revalidate account keys and balances immediately before commitment.
	for(var/list/payment in validated)
		var/target = payment["target"]
		var/account_key = payment["account_key"]
		var/balance_before = payment["balance_before"]

		if(resolve_bank_account_key(target) != account_key)
			return list(
				"success" = FALSE,
				"reason" = "account_changed",
			)

		if(!(account_key in bank_accounts) || bank_accounts[account_key] != balance_before)
			return list(
				"success" = FALSE,
				"reason" = "balance_changed",)

	// Commit: all validation has passed, and no yielding operation occurred.
	treasury_value -= total_amount

	for(var/list/payment in validated)
		var/account_key = payment["account_key"]
		var/amount = payment["amount"]
		var/balance_before = payment["balance_before"]
		var/balance_after = balance_before + amount

		bank_accounts[account_key] = balance_after

		record_financial_transaction(list(
			"transaction_type" = transaction_type,
			"day_number" = day_number,
			"source" = source,
			"amount" = amount,
			"recipient_identity" = payment["identity"],
			"recipient_label" = payment["target_name"],
			"job_title" = payment["job_title"],
			"status" = "completed",
			"treasury_before" = treasury_before,
			"treasury_after" = treasury_value,
			"batch_total" = total_amount,
			"account_before" = balance_before,
			"account_after" = balance_after,))

		log_to_steward("+[amount] from Treasury to [payment["target_name"]] ([source])")

	return list(
		"success" = TRUE,
		"total_amount" = total_amount,
		"treasury_before" = treasury_before,
		"treasury_after" = treasury_value,)

/// Resolves the original role behind an advanced class.
/// Payroll is always based on the root role, never on a subclass.
/datum/controller/subsystem/treasury/proc/get_payroll_base_job(datum/job/assigned_job)
	if(!istype(assigned_job, /datum/job))
		return null

	var/datum/job/base_job = assigned_job
	var/list/visited_jobs = list()

	while(base_job.parent_job)
		// Prevent an accidental parent_job loop.
		if(base_job in visited_jobs)
			return null

		visited_jobs += base_job
		base_job = base_job.parent_job

	return base_job

/datum/controller/subsystem/treasury/proc/pay_daily_salaries(day_number)
	if(!isnum(day_number) || day_number < 1)
		log_to_steward("Payroll rejected: invalid day number.")
		return FALSE

	day_number = floor(day_number)
	var/day_key = "day-[day_number]"

	// Idempotency: one completed payroll batch per in-game day.
	if(payroll_completed_days[day_key])
		return FALSE

	var/list/day_entries = payroll_ledger[day_key]
	if(!islist(day_entries))
		day_entries = list()
		payroll_ledger[day_key] = day_entries

	var/list/eligible_payments = list()
	var/list/transfer_requests = list()
	var/list/seen_minds = list()
	var/total_due = 0

	for(var/mob/living/carbon/human/employee in GLOB.human_list)
		if(QDELETED(employee))
			continue

		var/datum/mind/employee_mind = employee.mind
		if(!employee_mind || employee_mind.current != employee)
			continue

		if(employee_mind in seen_minds)
			continue
		seen_minds += employee_mind


		// Keep the real assigned job separate from the role used for payroll.
		var/datum/job/assigned_job = employee_mind.assigned_role
		if(!istype(assigned_job, /datum/job))
			continue

		// Salary is determined exclusively by the original/root role.
		var/datum/job/employee_job = get_payroll_base_job(assigned_job)
		if(!employee_job)
			continue

		if(!isnum(employee_job.daily_salary))
			continue

		if(!isnum(employee_job.daily_salary))
			continue

		var/salary = floor(employee_job.daily_salary)
		if(salary <= 0)
			continue

		// A previous success or failure for this identity/day must not be retried.
		if(day_entries[employee_mind])
			continue

		var/account_key = resolve_bank_account_key(employee)
		if(!account_key || !(account_key in bank_accounts))
			var/list/missing_account_record = list(
				"day_number" = day_number,
				"character_identity" = REF(employee_mind),
				"character_name" = employee.real_name,
				"job_title" = employee_job.title,
				"amount" = salary,
				"status" = "missing_account",
			)

			day_entries[employee_mind] = missing_account_record

			record_financial_transaction(list(
				"transaction_type" = "salary",
				"day_number" = day_number,
				"amount" = salary,
				"recipient_identity" = REF(employee_mind),
				"recipient_label" = employee.real_name,
				"job_title" = employee_job.title,
				"status" = "missing_account",
			))

			log_to_steward(
				"PAYROLL ERROR: [employee_job.title] ([employee.real_name]) has salary configured but no Treasury account."
			)

			notify_payroll_mind(
				employee_mind,
				"<span class='warning'>Your daily salary of [salary] amna for [employee_job.title] could not be paid because no Treasury bank account is registered. Please report this issue to staff.</span>",
			)
			continue

		var/account_balance = bank_accounts[account_key]
		if(!isnum(account_balance) || account_balance < 0)
			var/list/invalid_account_record = list(
				"day_number" = day_number,
				"character_identity" = REF(employee_mind),
				"character_name" = employee.real_name,
				"job_title" = employee_job.title,
				"amount" = salary,
				"status" = "invalid_account_balance",
			)

			day_entries[employee_mind] = invalid_account_record

			log_to_steward(
				"PAYROLL ERROR: invalid account balance for [employee.real_name] ([employee_job.title])."
			)

			notify_payroll_mind(
				employee_mind,
				"<span class='warning'>Your daily salary for [employee_job.title] could not be processed because your bank account has an invalid balance. Please report this issue to staff.</span>",
			)
			continue

		eligible_payments += list(list(
			"employee" = employee,
			"mind" = employee_mind,
			"job" = employee_job,
			"assigned_job" = assigned_job,
			"salary" = salary,
			"account_key" = account_key,
			"balance_before" = account_balance,
		))

		transfer_requests += list(list(
			"target" = employee,
			"amount" = salary,
			"job_title" = employee_job.title,
		))

		total_due += salary

	if(!length(eligible_payments))
		payroll_completed_days[day_key] = TRUE
		log_to_steward("Payroll completed for day [day_number]: no payable salaries.")
		return TRUE

	// Recheck the full roster and current balances immediately before committing.
	var/roster_changed = FALSE

	for(var/list/payment in eligible_payments)
		var/mob/living/carbon/human/employee = payment["employee"]
		var/datum/mind/employee_mind = payment["mind"]
		var/datum/job/employee_job = payment["job"]
		var/datum/job/assigned_job = payment["assigned_job"]
		var/salary = payment["salary"]
		var/account_key = payment["account_key"]
		var/balance_before = payment["balance_before"]

		if(QDELETED(employee) || employee_mind.current != employee)
			roster_changed = TRUE
			break

		// The actual assigned class must not have changed.
		if(employee_mind.assigned_role != assigned_job)
			roster_changed = TRUE
			break

		// Its original/root role must still be the same.
		if(get_payroll_base_job(assigned_job) != employee_job)
			roster_changed = TRUE
			break

		// The root role's salary must still match the amount prepared.
		if(!isnum(employee_job.daily_salary) || floor(employee_job.daily_salary) != salary)
			roster_changed = TRUE
			break

		if(resolve_bank_account_key(employee) != account_key)
			roster_changed = TRUE
			break

		if(!(account_key in bank_accounts) || bank_accounts[account_key] != balance_before)
			roster_changed = TRUE
			break

	if(roster_changed)
		for(var/list/payment in eligible_payments)
			var/mob/living/carbon/human/employee = payment["employee"]
			var/datum/mind/employee_mind = payment["mind"]
			var/datum/job/employee_job = payment["job"]
			var/salary = payment["salary"]

			day_entries[employee_mind] = list(
				"day_number" = day_number,
				"character_identity" = REF(employee_mind),
				"character_name" = employee.real_name,
				"job_title" = employee_job.title,
				"amount" = salary,
				"status" = "roster_changed",
			)

			notify_payroll_mind(
				employee_mind,
				"<span class='warning'>Your daily salary transaction for [employee_job.title] was cancelled because your job or account changed during payroll validation. No salary was paid.</span>",
			)

		payroll_completed_days[day_key] = TRUE
		log_to_steward("Payroll aborted for day [day_number]: roster or account changed during validation.")
		return FALSE

	var/list/transfer_result = transfer_treasury_batch(
		transfer_requests,
		"Daily salary, day [day_number]",
		"salary",
		day_number,
	)

	if(!transfer_result["success"])
		var/failure_reason = transfer_result["reason"]
		var/shortfall = transfer_result["shortfall"]
		var/available = transfer_result["available"]

		if(failure_reason == "insufficient_treasury")
			log_to_steward(
				"PAYROLL FAILED: day [day_number], total wage bill [total_due], Treasury available [available], shortfall [shortfall]."
			)

			record_financial_transaction(list(
				"transaction_type" = "salary_batch",
				"day_number" = day_number,
				"required" = total_due,
				"available" = available,
				"shortfall" = shortfall,
				"status" = "insufficient_treasury",
			))

			for(var/list/payment in eligible_payments)
				var/mob/living/carbon/human/employee = payment["employee"]
				var/datum/mind/employee_mind = payment["mind"]
				var/datum/job/employee_job = payment["job"]
				var/salary = payment["salary"]

				day_entries[employee_mind] = list(
					"day_number" = day_number,
					"character_identity" = REF(employee_mind),
					"character_name" = employee.real_name,
					"job_title" = employee_job.title,
					"amount" = salary,
					"status" = "insufficient_treasury",
					"shortfall" = shortfall,
				)

				record_financial_transaction(list(
					"transaction_type" = "salary",
					"day_number" = day_number,
					"amount" = salary,
					"recipient_identity" = REF(employee_mind),
					"recipient_label" = employee.real_name,
					"job_title" = employee_job.title,
					"status" = "insufficient_treasury",
					"shortfall" = shortfall,
				))

				notify_payroll_mind(
					employee_mind,
					"<span class='warning'>Your daily salary of [salary] amna for [employee_job.title] was not paid because the city treasury cannot cover today's full payroll. No money was deposited on your account.</span>",
				)

			// Notify all current and disconnected Burgomeister characters.
			for(var/mob/living/carbon/human/official in GLOB.human_list)
				if(QDELETED(official) || !official.mind)
					continue
				if(official.mind.current != official)
					continue
				if(!is_burgmeister_job(official.mind.assigned_role))
					continue

				notify_payroll_mind(
					official.mind,
					"<span class='warning'>Daily payroll failed for in-game day [day_number]. Required: [total_due] amna; available: [available] amna; shortfall: [shortfall] amna.</span>",
				)

		else
			log_to_steward(
				"PAYROLL FAILED: day [day_number], transaction validation error: [failure_reason]. No salaries were paid."
			)

			for(var/list/payment in eligible_payments)
				var/mob/living/carbon/human/employee = payment["employee"]
				var/datum/mind/employee_mind = payment["mind"]
				var/datum/job/employee_job = payment["job"]
				var/salary = payment["salary"]

				day_entries[employee_mind] = list(
					"day_number" = day_number,
					"character_identity" = REF(employee_mind),
					"character_name" = employee.real_name,
					"job_title" = employee_job.title,
					"amount" = salary,
					"status" = "transaction_failed",
					"reason" = failure_reason,
				)

				notify_payroll_mind(
					employee_mind,
					"<span class='warning'>Your daily salary transaction for [employee_job.title] failed validation. No money was deposited. Please report this issue to staff.</span>",
				)

		payroll_completed_days[day_key] = TRUE
		return FALSE

	// The transfer helper has committed the entire payroll batch.
	for(var/list/payment in eligible_payments)
		var/mob/living/carbon/human/employee = payment["employee"]
		var/datum/mind/employee_mind = payment["mind"]
		var/datum/job/employee_job = payment["job"]
		var/salary = payment["salary"]
		var/account_key = payment["account_key"]
		var/balance_before = payment["balance_before"]
		var/balance_after = bank_accounts[account_key]

		day_entries[employee_mind] = list(
			"day_number" = day_number,
			"character_identity" = REF(employee_mind),
			"character_name" = employee.real_name,
			"job_title" = employee_job.title,
			"amount" = salary,
			"balance_before" = balance_before,
			"balance_after" = balance_after,
			"status" = "paid",)

		notify_payroll_mind(employee_mind, "<span class='info'>Daily salary: [salary] amna for [employee_job.title] has been deposited. Your new balance is [balance_after] amna.</span>",)

	payroll_completed_days[day_key] = TRUE
	log_to_steward("Payroll completed for day [day_number]: [length(eligible_payments)] character accounts paid [total_due] amna.")
	return TRUE
