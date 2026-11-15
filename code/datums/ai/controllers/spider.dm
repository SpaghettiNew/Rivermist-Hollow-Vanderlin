/// Every spider kind shares these habits, in this order; each kind adds its own around them.
/datum/ai_controller/spider_base
	movement_delay = 0.4 SECONDS

	ai_movement = /datum/ai_movement/hybrid_pathing
	horny_pref_family_flag = HORNY_MOB_TYPE_SPIDERS

	blackboard = list(
		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/spider()
	)

	idle_behavior = /datum/idle_behavior/idle_random_walk

	/// Kind-only subtrees planned before the shared habits.
	var/list/lead_subtrees
	/// How this kind picks a fight, right after retaliation.
	var/target_finder = /datum/ai_planning_subtree/aggro_find_target
	/// Kind-only attacks tried before the shared melee.
	var/list/attack_subtrees
	/// How this kind forages, after the melee.
	var/food_finder = /datum/ai_planning_subtree/find_food
	/// Kind-only subtrees planned last.
	var/list/tail_subtrees

/datum/ai_controller/spider_base/New(atom/new_pawn)
	planning_subtrees = build_spider_subtrees()
	return ..()

/// The kind's lead, the shared habits, its attacks, melee, healing, leaving cocoons, food, then its tail.
/datum/ai_controller/spider_base/proc/build_spider_subtrees()
	var/list/subtrees = list()
	if(lead_subtrees)
		subtrees += lead_subtrees
	subtrees += list(
		/datum/ai_planning_subtree/target_retaliate,
		target_finder,
		/datum/ai_planning_subtree/simple_find_horny,
		/datum/ai_planning_subtree/horny,
		/datum/ai_planning_subtree/spider_brood,
		/datum/ai_planning_subtree/find_cocoon_target,
		/datum/ai_planning_subtree/cocoon_target,
	)
	if(attack_subtrees)
		subtrees += attack_subtrees
	subtrees += /datum/ai_planning_subtree/basic_melee_attack_subtree/agile
	// After the fight, so a foe in reach always gets the melee first.
	subtrees += /datum/ai_planning_subtree/simple_self_recovery
	// Nothing better to do: walk away from an occupied cocoon before foraging.
	subtrees += /datum/ai_planning_subtree/spider_disperse
	subtrees += food_finder
	if(tail_subtrees)
		subtrees += tail_subtrees
	return subtrees

/// Beespiders: pets, a nest and carrion on top of the shared habits.
/datum/ai_controller/spider
	parent_type = /datum/ai_controller/spider_base
	blackboard = list(
		BB_HOME_PATH = /obj/structure/spider/nest,
		BB_TARGET_HELD_ITEM = /obj/item/reagent_containers/food/snacks/meat,

		BB_TARGETTING_DATUM = new /datum/targetting_datum/basic/allow_items/not_holding_item/spider(),
		BB_PET_TARGETING_DATUM = new /datum/targetting_datum/basic/not_friends(),
	)

	lead_subtrees = list(
		/datum/ai_planning_subtree/pet_planning,
		/datum/ai_planning_subtree/flee_target,
	)
	target_finder = /datum/ai_planning_subtree/simple_find_target/spider
	food_finder = /datum/ai_planning_subtree/find_food/spider
	// Last, so a fight, a horny scene or a meal ends planning before the nest roll.
	tail_subtrees = list(
		/datum/ai_planning_subtree/find_dead_bodies,
		/datum/ai_planning_subtree/eat_dead_body,
		/datum/ai_planning_subtree/find_valid_home,
		/datum/ai_planning_subtree/enter_exit_home,
	)

/// Spiders leave a cocooned victim, and one who just got out, alone.
/datum/targetting_datum/basic/spider

/datum/targetting_datum/basic/spider/can_horny(mob/living/living_mob, atom/the_target)
	if(spider_hunt_spares(the_target))
		return FALSE
	return ..()

/datum/targetting_datum/basic/allow_items/not_holding_item/spider

/datum/targetting_datum/basic/allow_items/not_holding_item/spider/can_horny(mob/living/living_mob, atom/the_target)
	if(spider_hunt_spares(the_target))
		return FALSE
	return ..()
