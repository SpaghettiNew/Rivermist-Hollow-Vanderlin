/// NPC reactions that used to misfire: hurt checks, ignored hits, Go Home, pauses, item searches, frozen planning.
/datum/unit_test/ai_npc_reaction
	abstract_type = /datum/unit_test/ai_npc_reaction
#ifdef FOCUS_AI_NPC_REACTION_TEST
	focus = TRUE
#endif

/// Human health started at 100 of 200, so every unhurt NPC fought hit-and-run as if badly wounded.
/datum/unit_test/ai_npc_reaction/unhurt_npc_fights_head_on

/datum/unit_test/ai_npc_reaction/unhurt_npc_fights_head_on/Run()
	var/mob/living/carbon/human/foe = allocate(/mob/living/carbon/human)
	TEST_ASSERT_EQUAL(foe.health, foe.maxHealth, "A new human should start at full health.")
	var/mob/living/carbon/human/species/skeleton/npc/skeleton = allocate(/mob/living/carbon/human/species/skeleton/npc)
	TEST_ASSERT_EQUAL(skeleton.health, skeleton.maxHealth, "A new NPC should start at full health.")
	var/datum/ai_controller/controller = skeleton.ai_controller
	var/datum/targetting_datum/targeting = controller.blackboard[BB_TARGETTING_DATUM]
	TEST_ASSERT(targeting.can_attack(skeleton, foe), "Test setup: the skeleton should be able to attack the foe.")
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, foe)

	var/datum/ai_planning_subtree/harass = GLOB.ai_subtrees[/datum/ai_planning_subtree/wounded_harass]
	harass.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(!controller.blackboard[BB_HUMAN_NPC_HARASS_MODE], "An unhurt NPC should fight head-on, not hit-and-run.")

/// Brute never lowers human health, so an NPC in heavy pain must still count as wounded.
/datum/unit_test/ai_npc_reaction/pained_npc_turns_to_hit_and_run

/datum/unit_test/ai_npc_reaction/pained_npc_turns_to_hit_and_run/Run()
	var/mob/living/carbon/human/foe = allocate(/mob/living/carbon/human)
	var/mob/living/carbon/human/species/goblin/npc/goblin = allocate(/mob/living/carbon/human/species/goblin/npc)
	var/datum/ai_controller/controller = goblin.ai_controller
	var/datum/targetting_datum/unit_test_one_target/targeting = allocate(/datum/targetting_datum/unit_test_one_target)
	targeting.allowed_target = foe
	controller.set_blackboard_key(BB_TARGETTING_DATUM, targeting)
	TEST_ASSERT(goblin.can_feel_pain(), "Test setup: goblins should feel pain.")
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, foe)
	// Life does not run in tests, so set the pain a few hard hits would leave.
	goblin.traumatic_shock = SHOCK_STAGE_2
	TEST_ASSERT_EQUAL(goblin.health, goblin.maxHealth, "Test setup: pain alone should leave health full.")

	var/datum/ai_planning_subtree/harass = GLOB.ai_subtrees[/datum/ai_planning_subtree/wounded_harass]
	harass.SelectBehaviors(controller, 0.5)
	TEST_ASSERT(controller.blackboard[BB_HUMAN_NPC_HARASS_MODE], "An NPC in heavy pain should switch to hit-and-run.")

/// Records the bonus a sneak check would get, and never spots anyone.
/mob/living/simple_animal/hostile/unit_test_sneak_probe
	var/last_sneak_bonus

/mob/living/simple_animal/hostile/unit_test_sneak_probe/npc_detect_sneak(mob/living/target, extra_prob = 0)
	last_sneak_bonus = extra_prob
	return FALSE

/// A typo gave every mob the hurt bonus for spotting sneakers, while hurt humans never earned it.
/datum/unit_test/ai_npc_reaction/hurt_mob_watches_for_sneakers

/datum/unit_test/ai_npc_reaction/hurt_mob_watches_for_sneakers/Run()
	var/mob/living/carbon/human/sneaker = allocate(/mob/living/carbon/human)
	sneaker.alpha = 50
	var/mob/living/simple_animal/hostile/unit_test_sneak_probe/probe = allocate(/mob/living/simple_animal/hostile/unit_test_sneak_probe)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller/unit_test_one_finder, probe)
	var/datum/targetting_datum/unit_test_one_target/targeting = allocate(/datum/targetting_datum/unit_test_one_target)
	targeting.allowed_target = sneaker
	controller.set_blackboard_key(BB_TARGETTING_DATUM, targeting)
	var/datum/ai_behavior/finder = GET_AI_BEHAVIOR(/datum/ai_behavior/find_potential_targets)

	finder.perform(0.1, controller, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(probe.last_sneak_bonus, 0, "An unhurt mob should get no extra chance to spot a sneaker.")

	probe.health = probe.maxHealth * 0.4
	qdel(controller.blackboard[BB_FIND_TARGETS_FIELD(/datum/ai_behavior/find_potential_targets)]) // a live field skips the scan
	finder.perform(0.1, controller, BB_BASIC_MOB_CURRENT_TARGET, BB_TARGETTING_DATUM, BB_BASIC_MOB_CURRENT_TARGET_HIDING_LOCATION)
	TEST_ASSERT_EQUAL(probe.last_sneak_bonus, 30, "A badly hurt mob should watch harder for sneakers.")

	var/mob/living/carbon/human/species/goblin/npc/goblin = allocate(/mob/living/carbon/human/species/goblin/npc)
	TEST_ASSERT_EQUAL(goblin.get_npc_sneak_alert_bonus(), 0, "An unhurt human NPC should get no sneak bonus.")
	goblin.traumatic_shock = SHOCK_STAGE_2 // brute shows up as pain, not lost health
	TEST_ASSERT_EQUAL(goblin.get_npc_sneak_alert_bonus(), 30, "A human NPC in heavy pain should watch harder for sneakers.")

/// PauseAi(0) never ended a pause, so a fisher hit mid-cast stayed frozen for the whole cast.
/datum/unit_test/ai_npc_reaction/resume_ends_a_pause_early

/datum/unit_test/ai_npc_reaction/resume_ends_a_pause_early/Run()
	var/mob/living/simple_animal/hostile/pawn = allocate(/mob/living/simple_animal/hostile)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller/unit_test_one_finder, pawn)
	controller.PauseAi(30 SECONDS)
	TEST_ASSERT(!controller.able_to_run, "Test setup: a paused AI should not run.")
	controller.PauseAi(0)
	TEST_ASSERT(!controller.able_to_run, "A shorter pause must not cut a running one.")
	controller.ResumeAi()
	TEST_ASSERT(controller.able_to_run, "ResumeAi should end the pause at once.")

/// Two weapon search copies existed; the one that runs keeps a two-shield NPC from taking a weapon.
/datum/unit_test/ai_npc_reaction/two_shields_skip_weapons

/datum/unit_test/ai_npc_reaction/two_shields_skip_weapons/Run()
	var/obj/item/weapon/sword/iron/sword = allocate(/obj/item/weapon/sword/iron)
	var/mob/living/carbon/human/species/skeleton/npc/skeleton = allocate(/mob/living/carbon/human/species/skeleton/npc)
	var/datum/ai_behavior/find_and_set/search = GET_AI_BEHAVIOR(/datum/ai_behavior/find_and_set/better_weapon)
	TEST_ASSERT(skeleton.put_in_hands(allocate(/obj/item/weapon/shield/wood)), "Test setup: the skeleton should hold a shield.")
	TEST_ASSERT(search.atom_allowed(sword, null, skeleton), "With a free hand, a shield bearer should still want a weapon.")
	TEST_ASSERT(skeleton.put_in_hands(allocate(/obj/item/weapon/shield/wood)), "Test setup: the skeleton should hold a second shield.")
	TEST_ASSERT(!search.atom_allowed(sword, null, skeleton), "With a shield in each hand, the skeleton should leave the weapon.")

/// Hits reach the AI only through relay_attackers, which pawns without an aggro board never had.
/datum/unit_test/ai_npc_reaction/controller_relays_attacks

/datum/unit_test/ai_npc_reaction/controller_relays_attacks/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/weapon/sword/iron/sword = allocate(/obj/item/weapon/sword/iron)
	var/mob/living/carbon/human/pawn = allocate(/mob/living/carbon/human)
	var/datum/ai_controller/controller = allocate(/datum/ai_controller/unit_test_one_finder, pawn)
	TEST_ASSERT(HAS_TRAIT(pawn, TRAIT_RELAYING_ATTACKER), "Every AI pawn should relay attacks to its controller.")

	SEND_SIGNAL(pawn, COMSIG_ATOM_ATTACKBY, sword, attacker, list())
	TEST_ASSERT(controller.blackboard[BB_AI_ALERT_MODE_UNTIL] > world.time, "A melee hit should reach the AI and put it on alert.")

/// Beespiders had no aggro board, so a hit never made the attacker their target.
/datum/unit_test/ai_npc_reaction/beespider_fights_back

/datum/unit_test/ai_npc_reaction/beespider_fights_back/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human)
	var/obj/item/weapon/sword/iron/sword = allocate(/obj/item/weapon/sword/iron)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = allocate(/mob/living/simple_animal/hostile/retaliate/spider)
	var/datum/ai_controller/controller = spider.ai_controller

	SEND_SIGNAL(spider, COMSIG_ATOM_ATTACKBY, sword, attacker, list())
	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], attacker, "A beespider that is hit should target its attacker.")

/// Go Home queued its walk without the home key, so the walk never started and the command was dropped.
/datum/unit_test/ai_npc_reaction/go_home_reaches_nest

/datum/unit_test/ai_npc_reaction/go_home_reaches_nest/Run()
	var/mob/living/carbon/human/owner = allocate(/mob/living/carbon/human)
	owner.moveToNullspace()
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = allocate(/mob/living/simple_animal/hostile/retaliate/spider)
	var/obj/structure/spider/nest/nest = allocate(/obj/structure/spider/nest, get_step(spider, EAST))
	var/datum/ai_controller/controller = spider.ai_controller
	controller.idle_behavior = null
	controller.set_blackboard_key(BB_TARGETTING_DATUM, allocate(/datum/targetting_datum/unit_test_one_target))
	controller.set_blackboard_key(BB_CURRENT_HOME, nest)
	// As if it just left the nest, so only the command can send it back.
	controller.modify_cooldown(GET_AI_BEHAVIOR(/datum/ai_behavior/enter_exit_home), world.time + 1 MINUTES)
	var/datum/component/obeys_commands/obedience = spider.GetComponent(/datum/component/obeys_commands)
	var/datum/pet_command/go_home = obedience?.available_commands["Go Home"]
	TEST_ASSERT_NOTNULL(go_home, "Beespiders should know the Go Home command.")

	go_home.set_command_active(spider, owner)
	ai_test_plan(controller)
	// A second plan before the pet arrives, as on any walk longer than half a second.
	ai_test_plan(controller)
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/enter_exit_home/no_cooldown)), "The walk home must stay planned until the pet is inside.")
	ai_test_ticks(controller, 2)
	TEST_ASSERT_EQUAL(spider.loc, nest, "A pet told to go home should walk into its nest.")
	ai_test_plan(controller)
	TEST_ASSERT_NULL(controller.blackboard[BB_ACTIVE_PET_COMMAND], "Go Home should end once the pet is inside.")

/// A bandage on its 30 second cooldown sat in the queue and blocked all planning until it was ready.
/datum/unit_test/ai_npc_reaction/bandage_waits_without_blocking

/datum/unit_test/ai_npc_reaction/bandage_waits_without_blocking/Run()
	var/mob/living/carbon/human/species/goblin/npc/goblin = allocate(/mob/living/carbon/human/species/goblin/npc)
	var/datum/ai_controller/controller = goblin.ai_controller
	var/datum/component/ai_inventory_manager/inventory = controller.get_inventory()
	TEST_ASSERT_NOTNULL(inventory, "Human NPCs should track their inventory for the AI.")
	var/obj/item/natural/cloth/cloth = allocate(/obj/item/natural/cloth)
	// Cloth worn as the belt turns into a cloth belt, so hang it at the hip instead.
	if(!goblin.belt)
		goblin.equip_to_slot_if_possible(allocate(/obj/item/storage/belt/leather), ITEM_SLOT_BELT, disable_warning = TRUE, bypass_equip_delay_self = TRUE)
	for(var/slot in list(ITEM_SLOT_BELT_L, ITEM_SLOT_BELT_R))
		if(goblin.equip_to_slot_if_possible(cloth, slot, disable_warning = TRUE, bypass_equip_delay_self = TRUE))
			break
	TEST_ASSERT_NOTNULL(inventory.get_item(AI_ITEM_BANDAGE), "Test setup: the NPC should carry a bandage.")
	var/obj/item/bodypart/arm = goblin.get_bodypart(BODY_ZONE_L_ARM)
	TEST_ASSERT_NOTNULL(arm.add_wound(/datum/wound/slash, silent = TRUE), "Test setup: the NPC should have a wound to dress.")
	var/datum/ai_planning_subtree/bandage_planner = GLOB.ai_subtrees[/datum/ai_planning_subtree/use_bandage]
	var/datum/ai_behavior/bandage = GET_AI_BEHAVIOR(/datum/ai_behavior/apply_bandage)

	TEST_ASSERT_EQUAL(bandage_planner.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "A wounded NPC with a bandage should plan to use it.")
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, bandage), "Test setup: the bandage should be queued.")
	TEST_ASSERT(controller.able_to_plan(), "A queued bandage must not block planning.")

	controller.CancelActions()
	controller.modify_cooldown(bandage, world.time + 30 SECONDS) // as if one was just applied
	TEST_ASSERT_NULL(bandage_planner.SelectBehaviors(controller, 0.5), "A bandage on cooldown should not be planned.")
	TEST_ASSERT(!LAZYACCESS(controller.current_behaviors, bandage), "A bandage on cooldown must not wait in the queue.")

/// Starts a beespider chewing a body; its fields see nobody, so only a hit can bring a foe.
/datum/unit_test/ai_npc_reaction/proc/start_corpse_meal(datum/targetting_datum/unit_test_one_target/targeting)
	var/mob/living/carbon/human/corpse = allocate(/mob/living/carbon/human)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = allocate(/mob/living/simple_animal/hostile/retaliate/spider)
	var/datum/ai_controller/controller = spider.ai_controller
	controller.idle_behavior = null
	controller.set_blackboard_key(BB_TARGETTING_DATUM, targeting)
	corpse.death()
	controller.set_blackboard_key(BB_BASIC_MOB_FOOD_TARGET, corpse)
	ai_test_plan(controller)
	// One behavior runs per tick, and the finders queued ahead of the meal come first.
	for(var/i in 1 to 12)
		ai_test_ticks(controller, 1)
		if(spider.doing())
			break
	return spider

/// Planning now runs mid-chew, so the meal must stay planned while nothing outranks it.
/datum/unit_test/ai_npc_reaction/meal_survives_quiet_plans

/datum/unit_test/ai_npc_reaction/meal_survives_quiet_plans/Run()
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = start_corpse_meal(allocate(/datum/targetting_datum/unit_test_one_target))
	var/datum/ai_controller/controller = spider.ai_controller
	TEST_ASSERT(spider.doing(), "Test setup: the beespider should be chewing on the body.")

	for(var/i in 1 to 3)
		ai_test_plan(controller)
		ai_test_ticks(controller, 1)
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/eat_dead_body)), "With nothing more urgent, plans mid-chew must keep the meal.")
	TEST_ASSERT(spider.doing(), "With nothing more urgent, the beespider should keep chewing.")
	controller.CancelActions()
	sleep(2) // lets the cancelled chew return before teardown deletes the spider

/// Chewing a body blocked planning for 10 seconds, so a hit from outside the field went unanswered.
/datum/unit_test/ai_npc_reaction/hit_interrupts_corpse_meal

/datum/unit_test/ai_npc_reaction/hit_interrupts_corpse_meal/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/targetting_datum/unit_test_one_target/targeting = allocate(/datum/targetting_datum/unit_test_one_target)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = start_corpse_meal(targeting)
	var/datum/ai_controller/controller = spider.ai_controller
	TEST_ASSERT(spider.doing(), "Test setup: the beespider should be chewing on the body.")
	TEST_ASSERT(controller.able_to_plan(), "A chewing beespider must keep planning.")

	// A hit from someone its fields never saw arrive, like a thrown rock.
	targeting.allowed_target = attacker
	SEND_SIGNAL(spider, COMSIG_ATOM_WAS_ATTACKED, attacker, 10)
	TEST_ASSERT_EQUAL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], attacker, "Test setup: the hit should make the attacker the target.")

	ai_test_plan(controller)
	TEST_ASSERT(!LAZYACCESS(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/eat_dead_body)), "A fight should cancel the meal at the next plan.")
	TEST_ASSERT(!spider.doing(), "Cancelling the meal should end the chewing at once.")
	sleep(2) // lets the cancelled chew return before teardown deletes the spider

/// A bleeding, bruised beespider with no foe; its targeting accepts nobody until a test says so.
/datum/unit_test/ai_npc_reaction/proc/make_hurt_spider(datum/targetting_datum/unit_test_one_target/targeting)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = allocate(/mob/living/simple_animal/hostile/retaliate/spider)
	var/datum/ai_controller/controller = spider.ai_controller
	controller.idle_behavior = null
	controller.set_blackboard_key(BB_TARGETTING_DATUM, targeting)
	spider.simple_add_wound(/datum/wound/puncture, silent = TRUE)
	// Stays above retreat_health, so the flee element does not take over.
	spider.adjustBruteLoss(spider.maxHealth * 0.3)
	return spider

/// The heal came before the melee and ended planning, so a hurt beespider stood still beside its foe.
/datum/unit_test/ai_npc_reaction/hurt_spider_fights_before_healing

/datum/unit_test/ai_npc_reaction/hurt_spider_fights_before_healing/Run()
	var/mob/living/carbon/human/foe = allocate(/mob/living/carbon/human)
	var/datum/targetting_datum/unit_test_one_target/targeting = allocate(/datum/targetting_datum/unit_test_one_target)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = make_hurt_spider(targeting)
	var/datum/ai_controller/controller = spider.ai_controller
	TEST_ASSERT(spider.get_bleed_rate() > 0 && spider.getBruteLoss() > 0, "Test setup: the beespider should bleed and be bruised.")
	TEST_ASSERT(!controller.blackboard[BB_BASIC_MOB_FLEEING], "Test setup: the beespider should not be fleeing.")
	targeting.allowed_target = foe
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, foe)

	ai_test_plan(controller)
	TEST_ASSERT(!LAZYACCESS(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/simple_rest_and_recuperate)), "A beespider with a live foe beside it must not plan to heal.")
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/basic_melee_attack/agile)), "A hurt beespider should attack the foe beside it.")
	controller.CancelActions()

/// A hit from a mob it does not target still means a fight; the heal waits for the calm time.
/datum/unit_test/ai_npc_reaction/hit_spider_heals_once_calm

/datum/unit_test/ai_npc_reaction/hit_spider_heals_once_calm/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = make_hurt_spider(allocate(/datum/targetting_datum/unit_test_one_target))
	var/datum/ai_controller/controller = spider.ai_controller
	var/datum/ai_planning_subtree/recovery = GLOB.ai_subtrees[/datum/ai_planning_subtree/simple_self_recovery]
	var/datum/ai_behavior/heal = GET_AI_BEHAVIOR(/datum/ai_behavior/simple_rest_and_recuperate)

	SEND_SIGNAL(spider, COMSIG_ATOM_WAS_ATTACKED, attacker, 10)
	TEST_ASSERT_NULL(controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET], "Test setup: the attacker should not become the target.")
	TEST_ASSERT_NULL(recovery.SelectBehaviors(controller, 0.5), "A beespider hit moments ago must not plan to heal.")
	TEST_ASSERT(!LAZYACCESS(controller.current_behaviors, heal), "A beespider hit moments ago must not queue a heal.")

	controller.set_blackboard_key(BB_LAST_ATTACKED_AT, world.time - AI_COMBAT_CALM_TIME - 1)
	TEST_ASSERT_EQUAL(recovery.SelectBehaviors(controller, 0.5), SUBTREE_RETURN_FINISH_PLANNING, "Once calm, a hurt beespider should plan to heal.")
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, heal), "Once calm, the heal should be queued.")
	controller.CancelActions()

/// The 8 second heal ran to the end even while something bit the beespider.
/datum/unit_test/ai_npc_reaction/hit_stops_spider_heal

/datum/unit_test/ai_npc_reaction/hit_stops_spider_heal/Run()
	var/mob/living/carbon/human/attacker = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = make_hurt_spider(allocate(/datum/targetting_datum/unit_test_one_target))
	var/datum/ai_controller/controller = spider.ai_controller
	var/datum/ai_planning_subtree/recovery = GLOB.ai_subtrees[/datum/ai_planning_subtree/simple_self_recovery]
	recovery.SelectBehaviors(controller, 0.5)
	for(var/i in 1 to 5)
		ai_test_ticks(controller, 1)
		if(spider.doing())
			break
	TEST_ASSERT(spider.doing(), "Test setup: the beespider should be healing.")
	var/brute_before = spider.getBruteLoss()

	SEND_SIGNAL(spider, COMSIG_ATOM_WAS_ATTACKED, attacker, 10)
	sleep(3)
	TEST_ASSERT(!spider.doing(), "A hit should stop the heal at once.")
	TEST_ASSERT_EQUAL(spider.getBruteLoss(), brute_before, "A stopped heal should not heal.")
	TEST_ASSERT(!LAZYACCESS(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/simple_rest_and_recuperate)), "A stopped heal should leave the queue.")
	controller.CancelActions()
	sleep(2) // lets a running heal return before teardown deletes the spider

/// A badly hurt beespider runs first; the heal waits until the run ends and the calm time passes.
/datum/unit_test/ai_npc_reaction/fleeing_spider_heals_after_escape

/datum/unit_test/ai_npc_reaction/fleeing_spider_heals_after_escape/Run()
	var/mob/living/carbon/human/foe = allocate(/mob/living/carbon/human, run_loc_floor_top_right)
	var/datum/targetting_datum/unit_test_one_target/targeting = allocate(/datum/targetting_datum/unit_test_one_target)
	var/mob/living/simple_animal/hostile/retaliate/spider/spider = make_hurt_spider(targeting)
	var/datum/ai_controller/controller = spider.ai_controller
	var/datum/ai_behavior/heal = GET_AI_BEHAVIOR(/datum/ai_behavior/simple_rest_and_recuperate)
	targeting.allowed_target = foe
	controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, foe)
	controller.set_blackboard_key(BB_BASIC_MOB_FLEEING, TRUE)

	ai_test_plan(controller)
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, GET_AI_BEHAVIOR(/datum/ai_behavior/run_away_from_target)), "A fleeing beespider should run from its foe.")
	TEST_ASSERT(!LAZYACCESS(controller.current_behaviors, heal), "A fleeing beespider must not stop to heal.")

	// As if it got away: the run clears the target, and the last hit is old.
	controller.CancelActions()
	controller.set_blackboard_key(BB_BASIC_MOB_FLEEING, FALSE)
	controller.clear_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET)
	targeting.allowed_target = null
	controller.set_blackboard_key(BB_LAST_ATTACKED_AT, world.time - AI_COMBAT_CALM_TIME - 1)
	ai_test_plan(controller)
	TEST_ASSERT(LAZYACCESS(controller.current_behaviors, heal), "A beespider that got away should heal.")
	controller.CancelActions()
