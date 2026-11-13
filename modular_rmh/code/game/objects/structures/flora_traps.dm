/// HOSTILE CRAWLING VINES ///

/obj/structure/flora/grass/crawlvines/death_vines
	dir = SOUTH
	max_integrity = 100
	can_buckle = TRUE
	buckle_lying = 90
	buckle_dir = EAST
	buckle_prevents_pull = TRUE
	var/difficulty_class_toescape = 10 // d20+((STR+CON)/2) should be >= difficulty_class_toescape to escape
	var/difficulty_class_toevade = 20 // d20+((STR+CON)/2) should be >= required_result_toevade to evade the trap
	var/detection_range_of_victim_teammates = 3 //if any other person present around, trap remain inactive
	var/time_until_capture = 1 SECONDS //delation between entering vine's tile and capture
	var/list/capture_timers
	var/list/ties = list()

/obj/structure/flora/grass/crawlvines/death_vines/Initialize(mapload)
	. = ..()
	AddElement(/datum/element/connect_loc, list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_vines_entered),
		COMSIG_TURF_EXITED = PROC_REF(on_vines_exited),
	))


// Capturing
/obj/structure/flora/grass/crawlvines/death_vines/proc/on_vines_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	var/mob/living/carbon/victim = arrived
	if(!istype(victim) || !victim.client || victim.stat == DEAD || victim.buckled || has_buckled_mobs())
		return

	for(var/mob/living/player in range(detection_range_of_victim_teammates, src))
		if(player != victim && player.client && player.stat != DEAD)
			return

	var/timer = addtimer(CALLBACK(src, PROC_REF(capture_victim), victim), time_until_capture, TIMER_STOPPABLE | TIMER_DELETE_ME)
	LAZYSET(capture_timers, victim, timer)

/obj/structure/flora/grass/crawlvines/death_vines/proc/on_vines_exited(turf/source, atom/movable/departed)
	SIGNAL_HANDLER
	var/timer = LAZYACCESS(capture_timers, departed)
	if(timer)
		deltimer(timer)
		LAZYREMOVE(capture_timers, departed)

/obj/structure/flora/grass/crawlvines/death_vines/proc/capture_victim(mob/living/carbon/victim)
	LAZYREMOVE(capture_timers, victim)
	if(QDELETED(victim) || !victim.client || victim.stat == DEAD || !isturf(loc) || !is_buckle_possible(victim, force = TRUE))
		return

	if(test_strength(victim, difficulty_class_toevade))
		to_chat(victim, span_warning("I evaded being captured by [src]!"))
		return

	var/obj/item/rope/spider_silk/vines_ropes/r
	if(!victim.handcuffed)
		r = new(loc)
		r.apply_cuffs(victim, null)
		ties += r

	var/obj/item/clothing/face/bdsm_gag/silk/vines/gag = new(get_turf(victim))
	if(victim.equip_to_slot_if_possible(gag, ITEM_SLOT_MASK, qdel_on_fail = TRUE, disable_warning = TRUE, bypass_equip_delay_self = TRUE))
		ties += gag

	if(!buckle_mob(victim, force = TRUE))
		remove_ties(victim)
		return

	victim.felt_visible_message(span_danger("[src] wraps it tendrils around [victim]'s body."), span_userdanger("[src] captured me!"), span_hear("I hear a muffled cry."))
	victim.emote("moan")


// Interactions
/obj/structure/flora/grass/crawlvines/death_vines/attack_hand(mob/living/user, list/modifiers)
	if(user?.buckled == src)
		user.resist()
		return TRUE
	return ..()

/obj/structure/flora/grass/crawlvines/death_vines/user_buckle_mob(mob/living/victim, mob/user, check_loc = TRUE)
	return FALSE

/obj/structure/flora/grass/crawlvines/death_vines/user_unbuckle_mob(mob/living/victim, mob/user)
	if(victim != user)
		return FALSE
	if(victim?.buckled == src)
		if(!test_strength(victim, difficulty_class_toescape))
			to_chat(victim, span_warning("I fail to struggle free from [src]"))
			victim.emote("moan")
			return
	return ..()


/// Misc

/obj/structure/flora/grass/crawlvines/death_vines/proc/test_strength(mob/living/victim, dc)
	var/strength = GET_MOB_ATTRIBUTE_VALUE(victim, STAT_STRENGTH)
	var/constitution = GET_MOB_ATTRIBUTE_VALUE(victim, STAT_CONSTITUTION)
	var/result = rand(1, 20) + round((strength + constitution - 20) / 2)
	return result >= dc


/obj/structure/flora/grass/crawlvines/death_vines/post_buckle_mob(mob/living/victim)
	. = ..()
	setDir(NORTH)
	layer = ABOVE_MOB_LAYER
	plane = GAME_PLANE_UPPER
	victim.set_mob_offsets("death_vines", _y = 15)

/obj/structure/flora/grass/crawlvines/death_vines/post_unbuckle_mob(mob/living/victim)
	. = ..()
	setDir(SOUTH)
	layer = initial(layer)
	plane = initial(plane)
	victim.reset_offsets("death_vines")
	remove_ties(victim)

/obj/structure/flora/grass/crawlvines/death_vines/proc/remove_ties(mob/living/victim)
	for(var/obj/item/tie as anything in ties)
		if(QDELETED(tie))
			continue
		if(victim && tie.loc == victim)
			victim.transferItemToLoc(tie, null, force = TRUE)
		qdel(tie)
	ties.Cut()

/obj/item/rope/spider_silk/vines_ropes
	name = "vine ropes"
	desc = "A warm coil of vines, fibrous enough to bind wrists."
	color = "#4b8052"

/obj/item/clothing/face/bdsm_gag/silk/vines
	name = "vines gag"
	desc = "Vines packed into the mouth and wound around the jaw."
	color = "#4b8052"
	salvage_amount = 0

/obj/item/clothing/face/bdsm_gag/silk/vines/Initialize(mapload, ...)
	. = ..()
	qdel(GetComponent(/datum/component/spider_silk_bond))
	item_flags |= DROPDEL


/// Old maneater ///
/// Старый мэнитер ///

/obj/structure/flora/grass/maneater/real/old_maneater
	/// Detection and pull radius in tiles.
	/// Радиус обнаружения и притягивания в клетках.
	/// Use set_vine_range() to change this after initialization.
	/// После инициализации меняется через set_vine_range().
	var/vine_range = 5
	/// Speed of the outgoing vine tip, in tiles per second.
	/// Скорость полёта кончика лозы в клетках в секунду.
	var/vine_shot_speed = 10
	/// Speed of the captured target, in tiles per second.
	/// Скорость притягивания цели в клетках в секунду.
	var/vine_pull_speed = 5
	/// Direct hit damage. Zero makes the vine a grab-only projectile.
	/// Урон при прямом попадании. При нулевом уроне лоза только хватает цель.
	var/vine_shot_damage = 0
	/// Delay after a step triggers the shot. Zero defers to the next timer tick.
	/// Задержка выстрела после шага цели. Ноль откладывает выстрел до ближайшего тика таймера.
	var/vine_shot_delay = 0
	/// Time between shots, including misses.
	/// Пауза между выстрелами, в том числе после промаха.
	var/vine_cooldown_time = 5 SECONDS
	/// Delay before firing after feeding. Keep it in sync with the adult maneater's Crossed() check.
	/// Пауза перед выстрелом после кормления. Должна совпадать с паузой в Crossed() взрослого мэнитера.
	var/vine_feeding_cooldown = 5 SECONDS
	/// Tint shared by the projectile and the pull beam.
	/// Общий цвет снаряда и лозы при притягивании.
	var/vine_color = "#6b963f"
	/// Conversion factor for the projectile and throwing APIs.
	/// Коэффициент перевода секунд в децисекунды для расчёта полёта и притягивания.
	var/const/deciseconds_per_second = 1 SECONDS
	/// Block value passed by bullet_act() when a shield fully stops a shot.
	/// Значение blocked, которое bullet_act() передаёт при полном блоке щитом.
	var/const/full_projectile_block = 100
	COOLDOWN_DECLARE(vine_pull_cooldown)

/obj/structure/flora/grass/maneater/real/old_maneater/Initialize(mapload)
	. = ..()
	set_vine_range(vine_range)

/obj/structure/flora/grass/maneater/real/old_maneater/post_unbuckle_mob(mob/living/unbuckled_mob)
	. = ..()
	COOLDOWN_START(src, vine_pull_cooldown, vine_cooldown_time)

/obj/structure/flora/grass/maneater/real/old_maneater/proc/set_vine_range(new_range)
	if(!isnum(new_range) || new_range < 0 || new_range >= INFINITY || new_range != round(new_range))
		return FALSE

	vine_range = new_range
	var/datum/component/connect_range/vine_detection = GetComponent(/datum/component/connect_range)
	if(vine_detection && vine_detection.range == vine_range)
		return TRUE

	// Recreate the component so it subscribes to every tile in the new radius.
	// Пересоздаём компонент, чтобы подписаться на все клетки в новом радиусе.
	qdel(vine_detection)
	AddComponent(/datum/component/connect_range, src, list(
		COMSIG_ATOM_ENTERED = PROC_REF(on_vine_range_entered),
	), vine_range, works_in_containers = FALSE)
	return TRUE

/obj/structure/flora/grass/maneater/real/old_maneater/proc/on_vine_range_entered(turf/source, atom/movable/arrived)
	SIGNAL_HANDLER
	if(!ishuman(arrived) || source == loc || !COOLDOWN_FINISHED(src, vine_pull_cooldown))
		return

	// Let the victim finish moving before the projectile can hit them.
	// Даём цели завершить шаг до того, как снаряд сможет в неё попасть.
	addtimer(CALLBACK(src, PROC_REF(shoot_vine), arrived), vine_shot_delay, TIMER_UNIQUE)

/obj/structure/flora/grass/maneater/real/old_maneater/proc/shoot_vine(mob/living/carbon/human/victim)
	if(vine_shot_speed <= 0 || !COOLDOWN_FINISHED(src, vine_pull_cooldown) || !can_target_with_vine(victim))
		return

	var/obj/projectile/maneater_vine/vine = new(loc)
	vine.firer = src
	vine.color = vine_color
	vine.damage = vine_shot_damage
	vine.nodamage = !vine_shot_damage
	vine.configure_flight(vine_range, vine_shot_speed / deciseconds_per_second)
	vine.preparePixelProjectile(victim, src)
	draw_vine(vine, vine)

	COOLDOWN_START(src, vine_pull_cooldown, vine_cooldown_time)
	vine.fire()

/obj/structure/flora/grass/maneater/real/old_maneater/proc/can_target_with_vine(mob/living/carbon/human/victim)
	if(obj_broken || !isturf(loc) || has_buckled_mobs() || world.time <= last_eat + vine_feeding_cooldown)
		return FALSE
	if(QDELETED(victim) || !isturf(victim.loc) || victim.loc == loc || victim.buckled || victim.throwing)
		return FALSE
	if(victim == planter || !can_snatch(victim))
		return FALSE
	return victim in oview(vine_range, src)

/obj/structure/flora/grass/maneater/real/old_maneater/proc/reel_in_target(mob/living/carbon/human/victim)
	if(!can_target_with_vine(victim))
		return

	// Landing on the plant triggers its normal Crossed() capture.
	// Когда цель попадает на клетку растения, обычный захват срабатывает через Crossed().
	var/turf/starting_turf = victim.loc
	var/tiles_per_decisecond = vine_pull_speed / deciseconds_per_second
	if(!victim.throw_at(loc, vine_range, tiles_per_decisecond, spin = FALSE, gentle = TRUE))
		return
	if(QDELETED(src) || QDELETED(victim))
		return

	var/datum/thrownthing/pull = victim.throwing
	if(QDELETED(pull) && victim.loc == starting_turf)
		return
	if(!QDELETED(pull))
		draw_vine(victim, pull)
	visible_message(span_warning("[src] lashes out with a vine and reels [victim] in!"))
	victim.emote("scream")
	return pull

/obj/structure/flora/grass/maneater/real/old_maneater/proc/draw_vine(atom/endpoint, datum/lifetime)
	var/datum/beam/maneater_vine/trail = new(src, endpoint, icon_state = "meat", time = INFINITY, max_distance = INFINITY, beam_color = vine_color, emissive = FALSE, render_on_z_levels = FALSE)
	trail.follow_lifetime(lifetime)
	INVOKE_ASYNC(trail, TYPE_PROC_REF(/datum/beam, Start))

/datum/beam/maneater_vine/proc/follow_lifetime(datum/lifetime)
	RegisterSignal(origin, COMSIG_PARENT_QDELETING, PROC_REF(on_vine_ended))
	RegisterSignal(lifetime, COMSIG_PARENT_QDELETING, PROC_REF(on_vine_ended))

/datum/beam/maneater_vine/proc/on_vine_ended()
	SIGNAL_HANDLER
	qdel(src)

/datum/maneater_vine_pull
	var/obj/structure/flora/grass/maneater/real/old_maneater/maneater
	var/mob/living/carbon/human/victim

/datum/maneater_vine_pull/New(obj/structure/flora/grass/maneater/real/old_maneater/maneater, mob/living/carbon/human/victim)
	. = ..()
	src.maneater = maneater
	src.victim = victim
	RegisterSignal(victim, COMSIG_MOB_CLIENT_PRE_MOVE, PROC_REF(block_client_move))
	RegisterSignal(victim, COMSIG_MOVABLE_MOVED, PROC_REF(check_arrival))
	RegisterSignal(victim, COMSIG_PARENT_QDELETING, PROC_REF(finish_pull))
	RegisterSignal(maneater, COMSIG_PARENT_QDELETING, PROC_REF(finish_pull))

	// Lock input on impact, but let the current step finish before starting the throw.
	// Блокируем ввод при попадании, но начинаем бросок после завершения текущего шага.
	addtimer(CALLBACK(src, PROC_REF(start_pull)))

/datum/maneater_vine_pull/proc/start_pull()
	var/datum/thrownthing/pull = maneater.reel_in_target(victim)
	if(QDELETED(src))
		return
	if(QDELETED(pull))
		qdel(src)
		return
	RegisterSignal(pull, COMSIG_PARENT_QDELETING, PROC_REF(finish_pull))

/datum/maneater_vine_pull/proc/block_client_move()
	SIGNAL_HANDLER
	return COMSIG_MOB_CLIENT_BLOCK_PRE_MOVE

/datum/maneater_vine_pull/proc/check_arrival()
	SIGNAL_HANDLER
	if(victim.loc == maneater.loc)
		qdel(src)

/datum/maneater_vine_pull/proc/finish_pull()
	SIGNAL_HANDLER
	qdel(src)

/obj/projectile/maneater_vine
	name = "grasping vine"
	icon_state = "tentacle_end"

/obj/projectile/maneater_vine/proc/configure_flight(detection_radius, tiles_per_decisecond)
	var/pixels_per_move = SSprojectiles.global_pixel_speed * SSprojectiles.global_iterations_per_move
	var/tiles_per_move = pixels_per_move / ICON_SIZE_X
	// Range counts moves. Allow enough to reach the corner of the detection area.
	// Дальность измеряется шагами снаряда. Их должно хватить до угла зоны обнаружения.
	var/radius_squared = detection_radius * detection_radius
	var/corner_distance = sqrt(radius_squared + radius_squared)
	range = ROUND_UP(corner_distance / tiles_per_move)
	// Speed is the delay between moves, in deciseconds.
	// В поле speed хранится задержка между шагами снаряда в децисекундах.
	speed = tiles_per_move / tiles_per_decisecond

/obj/projectile/maneater_vine/on_hit(atom/target, blocked = FALSE, pierce_hit)
	. = ..()
	if(. != BULLET_ACT_HIT || target != original || QDELETED(target) || !ishuman(target))
		return

	var/obj/structure/flora/grass/maneater/real/old_maneater/maneater = firer
	if(istype(maneater) && !QDELETED(maneater) && blocked < maneater.full_projectile_block)
		new /datum/maneater_vine_pull(maneater, target)
