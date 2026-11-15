//Returns the world time in english
/proc/worldtime2text()
	return gameTimestamp("hh:mm:ss", world.time)

/proc/time_stamp(format = "hh:mm:ss", show_ds)
	var/time_string = time2text(world.timeofday, format)
	return show_ds ? "[time_string]:[world.timeofday % 10]" : time_string

/proc/time_stamp_metric()
	var/date_portion = time2text(world.timeofday, "YYYY-MM-DD")
	var/time_portion = time2text(world.timeofday, "hh:mm:ss")
	return "[date_portion]T[time_portion]"

/proc/gameTimestamp(format = "hh:mm:ss", wtime=null)
	if(!wtime)
		wtime = world.time
	return time2text(wtime - GLOB.timezoneOffset, format)

/proc/station_time(display_only = FALSE, wtime=world.time)
	return ((((wtime - SSticker.round_start_time) * SSticker.station_time_rate_multiplier) + SSticker.gametime_offset) % 864000) - (display_only? GLOB.timezoneOffset : 0)

/proc/station_time_timestamp(format = "hh:mm:ss", wtime)
	return time2text(station_time(TRUE, wtime), format)

GLOBAL_VAR_INIT(tod, FALSE)
GLOBAL_VAR_INIT(forecast, FALSE)
GLOBAL_VAR_INIT(todoverride, FALSE)
/// The current day of the week, range from 1-7 (Moon's Dae - Sun's Dae)
GLOBAL_VAR_INIT(dayspassed, FALSE)
/// Monotonically increasing in-game day number used for payroll idempotency.
GLOBAL_VAR_INIT(payroll_day_number, 0)

/proc/settod(suppress_player_effects = FALSE)
	var/time = station_time()
	var/oldtod = GLOB.tod

	if(time >= SSnightshift.nightshift_start_time || time <= SSnightshift.nightshift_dawn_start)
		GLOB.tod = "night"
	if(time > SSnightshift.nightshift_dawn_start && time <= SSnightshift.nightshift_day_start)
		GLOB.tod = "dawn"
	if(time > SSnightshift.nightshift_day_start && time <= SSnightshift.nightshift_dusk_start)
		GLOB.tod = "day"
	if(time > SSnightshift.nightshift_dusk_start && time <= SSnightshift.nightshift_start_time)
		GLOB.tod = "dusk"
	if(GLOB.todoverride)
		GLOB.tod = GLOB.todoverride

	// Only process genuine TOD transitions during active gameplay.
	if(GLOB.tod != oldtod && !GLOB.todoverride && SSticker.current_state == GAME_STATE_PLAYING)

		// Weather has its own first-day restriction.
		// It must not block calendar or economic progression.
		if(GLOB.dayspassed > 1)
			SSParticleWeather.check_forecast(GLOB.tod)

		// Daily events execute exactly once, on dawn.
		if(GLOB.tod == "dawn")
			GLOB.dayspassed++
			if(GLOB.dayspassed == 8)
				GLOB.dayspassed = 1
			SStreasury.distribute_estate_incomes()
			GLOB.payroll_day_number++
			SStreasury.pay_daily_salaries(GLOB.payroll_day_number)

		SEND_GLOBAL_SIGNAL(COMSIG_GLOB_TIME_OF_DAY_CHANGED, GLOB.tod, oldtod)

		// During a timeskip, player-facing effects are applied only once,
		// after the final TOD has been reached.
		if(!suppress_player_effects)
			for(var/mob/living/player in GLOB.mob_list)
				if(player.stat != DEAD && player.client)
					player.do_time_change()

	if(GLOB.tod)
		return GLOB.tod

	return null

/mob/living/proc/do_time_change()
	if(!mind)
		return
	if(GLOB.tod == "dawn")
		var/text_to_show
		switch(GLOB.dayspassed)
			if(1)
				text_to_show = "DAWN OF THE FIRST DAE\nMOON'S DAE"
			if(2)
				text_to_show = "DAWN OF THE SECOND DAE\nTIW'S DAE"
			if(3)
				text_to_show = "DAWN OF THE THIRD DAE\nWEDDING'S DAE"
			if(4)
				text_to_show = "DAWN OF THE FOURTH DAE\nTHULE'S DAE"
			if(5)
				text_to_show = "DAWN OF THE FIFTH DAE\nFREYJA'S DAE"
			if(6)
				text_to_show = "DAWN OF THE SIXTH DAE\nSATURN'S DAE"
			if(7)
				text_to_show = "DAWN OF THE SEVENTH DAE\nSUN'S DAE"

		// Show the dawn announcement and play its sound only once per weekday per mind.
		if(text_to_show && !(text_to_show in mind.areas_entered))
			mind.areas_entered += text_to_show

			var/atom/movable/screen/area_text/T = new()
			client.screen += T
			T.maptext = MAPTEXT_CENTER({"<span style='vertical-align:top;color: #7c5b10; font-size: 150%;
					text-shadow: 1px 1px 2px black, 0 0 1em black, 0 0 0.2em black;'>[text_to_show]</span>"})
			T.maptext_width = 205
			T.maptext_height = 209
			T.maptext_x = 12
			T.maptext_y = -120
			playsound_local(src, 'sound/misc/newday.ogg', 60, FALSE)
			animate(T, alpha = 255, time = 10, easing = EASE_IN)
			addtimer(CALLBACK(src, PROC_REF(clear_area_text), T), 35)

	else if(GLOB.tod == "day")
		playsound_local(src, 'sound/misc/midday.ogg', 100, FALSE)
	else if(GLOB.tod == "night")
		playsound_local(src, 'sound/misc/nightfall.ogg', 100, FALSE)

	var/atom/movable/screen/daynight/D = new()
	D.alpha = 0
	client.screen += D
	animate(D, alpha = 255, time = 20, easing = EASE_IN)
	addtimer(CALLBACK(src, PROC_REF(clear_time_icon), D), 30)


/// Advances station time to the next real TOD boundary.
/// Executes the normal TOD transition and its associated world updates.
/proc/advance_station_time_to_next_tod_boundary()
	var/current_station_time = station_time()

	// Exact transition points:
	// Dawn, Day and Dusk begin immediately AFTER their configured boundary.
	// Night begins AT its configured boundary.
	var/list/tod_boundaries = list(
		SSnightshift.nightshift_dawn_start + 1,
		SSnightshift.nightshift_day_start + 1,
		SSnightshift.nightshift_dusk_start + 1,
		SSnightshift.nightshift_start_time,
	)

	var/next_delta = 864000

	for(var/boundary_time as anything in tod_boundaries)
		var/delta = boundary_time - current_station_time

		// Select the next occurrence, not the previous one.
		if(delta <= 0)
			delta += 864000

		if(delta < next_delta)
			next_delta = delta

	if(next_delta <= 0 || next_delta >= 864000)
		return FALSE

	var/old_tod = GLOB.tod

	// Advance station time without changing actual world.time.
	SSticker.gametime_offset = (SSticker.gametime_offset + next_delta) % 864000

	// Execute the normal transition logic without intermediate player effects.
	var/new_tod = settod(TRUE)

	if(new_tod == old_tod)
		return FALSE

	// Apply TOD-dependent ambience, weather temperature and entity updates.
	if(SSParticleWeather.selected_forecast)
		SSParticleWeather.selected_forecast.set_ambient_temperature(new_tod)

	SSnightshift.current_tod = new_tod
	SSnightshift.update_nightshift(new_tod)

	return TRUE

/proc/station_time_debug(force_set)
	if(isnum(force_set))
		SSticker.gametime_offset = force_set
		return
	SSticker.gametime_offset = rand(0, 864000)		//hours in day * minutes in hour * seconds in minute * deciseconds in second
	if(prob(50))
		SSticker.gametime_offset = FLOOR(SSticker.gametime_offset, 3600)
	else
		SSticker.gametime_offset = CEILING(SSticker.gametime_offset, 3600)

//returns timestamp in a sql and a not-quite-compliant ISO 8601 friendly format
/proc/SQLtime(timevar)
	return time2text(timevar || world.timeofday, "YYYY-MM-DD hh:mm:ss")


GLOBAL_VAR_INIT(midnight_rollovers, 0)
GLOBAL_VAR_INIT(rollovercheck_last_timeofday, 0)
/proc/update_midnight_rollover()
	if(world.timeofday < GLOB.rollovercheck_last_timeofday)
		GLOB.midnight_rollovers++

	GLOB.rollovercheck_last_timeofday = world.timeofday
	return GLOB.midnight_rollovers

/proc/weekdayofthemonth()
	var/DD = text2num(time2text(world.timeofday, "DD")) 	// get the current day
	switch(DD)
		if(8 to 13)
			return 2
		if(14 to 20)
			return 3
		if(21 to 27)
			return 4
		if(28 to INFINITY)
			return 5
		else
			return 1

//Takes a value of time in deciseconds.
//Returns a text value of that number in hours, minutes, or seconds.
/proc/DisplayTimeText(time_value, round_seconds_to = 0.1)
	var/second = FLOOR(time_value * 0.1, round_seconds_to)
	if(!second)
		return "right now"
	if(second < 60)
		return "[second] second[(second != 1)? "s":""]"
	var/minute = FLOOR(second / 60, 1)
	second = FLOOR(MODULUS(second, 60), round_seconds_to)
	var/secondT
	if(second)
		secondT = " and [second] second[(second != 1)? "s":""]"
	if(minute < 60)
		return "[minute] minute[(minute != 1)? "s":""][secondT]"
	var/hour = FLOOR(minute / 60, 1)
	minute = MODULUS(minute, 60)
	var/minuteT
	if(minute)
		minuteT = " and [minute] minute[(minute != 1)? "s":""]"
	if(hour < 24)
		return "[hour] hour[(hour != 1)? "s":""][minuteT][secondT]"
	var/day = FLOOR(hour / 24, 1)
	hour = MODULUS(hour, 24)
	var/hourT
	if(hour)
		hourT = " and [hour] hour[(hour != 1)? "s":""]"
	return "[day] day[(day != 1)? "s":""][hourT][minuteT][secondT]"

/proc/daysSince(realtimev)
	return round((world.realtime - realtimev) / (24 HOURS))

//returns time diff of two times normalized to time_rate_multiplier
/proc/daytimeDiff(timeA, timeB)

	//if the time is less than station time, add 24 hours (MIDNIGHT_ROLLOVER)
	var/time_diff = timeA > timeB ? (timeB + 24 HOURS) - timeA : timeB - timeA
	return time_diff / SSticker.station_time_rate_multiplier // normalise with the time rate multiplier

/// Until a condition is true, sleep, or until a certain amount of time has passed.
/// Basically, UNTIL() but with a timeout.
#define UNTIL_OR_TIMEOUT(Condition, Timeout) \
	do { \
		var/__end_time = REALTIMEOFDAY + (Timeout); \
		UNTIL((Condition) || (REALTIMEOFDAY > __end_time)); \
	} while(0)

///displays the current time into the round, with a lot of extra code just there for ensuring it looks okay after an entire day passes
#define ROUND_TIME(...) ( "[world.time - SSticker.round_start_time > MIDNIGHT_ROLLOVER ? "[round((world.time - SSticker.round_start_time)/MIDNIGHT_ROLLOVER)]:[worldtime2text()]" : worldtime2text()]" )
