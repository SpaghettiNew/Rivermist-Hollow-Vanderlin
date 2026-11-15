/client/proc/Debug2()
	set category = "Debug.Debug"
	set name = "Debug-Game"
	if(!check_rights(R_DEBUG))
		return

	if(GLOB.Debug2)
		GLOB.Debug2 = 0
		message_admins("[key_name(src)] toggled debugging off.")
		log_admin("[key_name(src)] toggled debugging off.")
	else
		GLOB.Debug2 = 1
		message_admins("[key_name(src)] toggled debugging on.")
		log_admin("[key_name(src)] toggled debugging on.")

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggle Debug Two") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/* 21st Sept 2010
Updated by Skie -- Still not perfect but better!
Stuff you can't do:
Call proc /mob/proc/Dizzy() for some player
Because if you select a player mob as owner it tries to do the proc for
/mob/living/carbon/human/ instead. And that gives a run-time error.
But you can call procs that are of type /mob/living/carbon/human/proc/ for that player.
*/

/client/proc/cmd_admin_animalize(mob/M in GLOB.mob_list)
	set category = "GameMaster.Equipping"
	set name = "Make Simple Animal"

	if(!SSticker.HasRoundStarted())
		alert("Wait until the game starts")
		return

	if(!M)
		alert("That mob doesn't seem to exist, close the panel and try again.")
		return

	if(isnewplayer(M))
		alert("The mob must not be a new_player.")
		return

	log_admin("[key_name(src)] has animalized [M.key].")
	INVOKE_ASYNC(M, TYPE_PROC_REF(/mob, Animalize))

//TODO: merge the vievars version into this or something maybe mayhaps
/client/proc/cmd_debug_del_all(object as text)
	set category = "Debug"
	set name = "Del-All"

	var/list/matches = get_fancy_list_of_atom_types()
	if (!isnull(object) && object!="")
		matches = filter_fancy_list(matches, object)

	if(matches.len==0)
		return
	var/hsbitem = input(usr, "Choose an object to delete.", "Delete:") as null|anything in sortList(matches)
	if(hsbitem)
		hsbitem = matches[hsbitem]
		var/counter = 0
		for(var/atom/O in world)
			if(istype(O, hsbitem))
				counter++
				qdel(O)
			CHECK_TICK
		log_admin("[key_name(src)] has deleted all ([counter]) instances of [hsbitem].")
		message_admins("[key_name_admin(src)] has deleted all ([counter]) instances of [hsbitem].")
		SSblackbox.record_feedback("tally", "admin_verb", 1, "Delete All") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_get_mob(mob/M in GLOB.mob_list)
	set category = "Admin"
	set name = "Get Mob"
	set desc = ""
	if(!check_rights(R_ADMIN))
		return

	if(alert(src, "Confirm?", "Message", "Yes", "No") != "Yes")
		return

	M.forceMove(get_turf(mob))

/client/proc/cmd_assume_direct_control(mob/M in GLOB.mob_list)
	set category = "Admin.Admin"
	set name = "Assume direct control"
	set desc = ""

	src.release_direct_controle()
	src.saved_ai_by_direct_control = M.ai_controller
	src.saved_ai_mob_ref = M

	if(M.ckey)
		if(alert("This mob is being controlled by [M.key]. Are you sure you wish to assume control of it? [M.key] will be made a ghost.",,"Yes","No") != "Yes")
			return
		else
			var/mob/dead/observer/ghost = new/mob/dead/observer(M,1)
			ghost.ckey = M.ckey
	message_admins("<span class='adminnotice'>[key_name_admin(usr)] assumed direct control of [M].</span>")
	log_admin("[key_name(usr)] assumed direct control of [M].")
	var/mob/adminmob = src.mob
	M.ckey = src.ckey
	if(HAS_TRAIT_FROM(M, TRAIT_NOSLEEP, "aghost"))
		REMOVE_TRAIT(M, TRAIT_NOSLEEP, "aghost")
	if(isobserver(adminmob))
		qdel(adminmob)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Assume Direct Control") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_give_control_to_player(mob/M in GLOB.mob_list, client/player in GLOB.clients)
	set category = "Admin.Admin"
	set name = "Give Control To Player"
	set desc = ""

	if(M.ckey)
		if(alert("This mob is being controlled by [key_name(M)]. Are you sure you wish to give [key_name(player)] control of it? [key_name(M)] will be made a ghost.",,"Yes","No") != "Yes")
			return
		else
			var/mob/dead/observer/ghost = new/mob/dead/observer(M,1)
			ghost.ckey = M.ckey
	message_admins(span_adminnotice("[key_name_admin(usr)] gave control of [M] to [key_name(player)]."))
	log_admin("[key_name(usr)] gave control of [M] to [key_name(player)].")
	var/mob/playermob = player.mob
	M.ckey = player.ckey
	if(isobserver(playermob))
		qdel(playermob)
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Give Control To Player") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/cmd_admin_areatest(on_station)
	set category = "Debug.Mapping"
	set name = "Test Areas"

	var/list/dat = list()
	var/list/areas_all = list()
	var/list/areas_with_APC = list()
	var/list/areas_with_multiple_APCs = list()
	var/list/areas_with_air_alarm = list()
	var/list/areas_with_RC = list()
	var/list/areas_with_light = list()
	var/list/areas_with_LS = list()
	var/list/areas_with_intercom = list()
	var/list/areas_with_camera = list()
	var/list/station_areas_blacklist = typecacheof(list())

	if(SSticker.current_state == GAME_STATE_STARTUP)
		to_chat(usr, "Game still loading, please hold!")
		return

	var/log_message
	if(on_station)
		dat += "<b>Only checking areas on station z-levels.</b><br><br>"
		log_message = "station z-levels"
	else
		log_message = "all z-levels"

	message_admins("<span class='adminnotice'>[key_name_admin(usr)] used the Test Areas debug command checking [log_message].</span>")
	log_admin("[key_name(usr)] used the Test Areas debug command checking [log_message].")

	for(var/area/A as anything in GLOB.areas)
		if(on_station)
			var/turf/picked = safepick(get_area_turfs(A.type))
			if(picked && is_station_level(picked.z))
				if(!(A.type in areas_all) && !is_type_in_typecache(A, station_areas_blacklist))
					areas_all.Add(A.type)
		else if(!(A.type in areas_all))
			areas_all.Add(A.type)
		CHECK_TICK

	for(var/obj/machinery/light/L in GLOB.machines)
		var/area/A = get_area(L)
		if(!A)
			dat += "Skipped over [L] in invalid location, [L.loc].<br>"
			continue
		if(!(A.type in areas_with_light))
			areas_with_light.Add(A.type)
		CHECK_TICK

	var/list/areas_without_APC = areas_all - areas_with_APC
	var/list/areas_without_air_alarm = areas_all - areas_with_air_alarm
	var/list/areas_without_RC = areas_all - areas_with_RC
	var/list/areas_without_light = areas_all - areas_with_light
	var/list/areas_without_LS = areas_all - areas_with_LS
	var/list/areas_without_intercom = areas_all - areas_with_intercom
	var/list/areas_without_camera = areas_all - areas_with_camera

	if(areas_without_APC.len)
		dat += "<h1>AREAS WITHOUT AN APC:</h1>"
		for(var/areatype in areas_without_APC)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_with_multiple_APCs.len)
		dat += "<h1>AREAS WITH MULTIPLE APCS:</h1>"
		for(var/areatype in areas_with_multiple_APCs)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_air_alarm.len)
		dat += "<h1>AREAS WITHOUT AN AIR ALARM:</h1>"
		for(var/areatype in areas_without_air_alarm)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_RC.len)
		dat += "<h1>AREAS WITHOUT A REQUEST CONSOLE:</h1>"
		for(var/areatype in areas_without_RC)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_light.len)
		dat += "<h1>AREAS WITHOUT ANY LIGHTS:</h1>"
		for(var/areatype in areas_without_light)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_LS.len)
		dat += "<h1>AREAS WITHOUT A LIGHT SWITCH:</h1>"
		for(var/areatype in areas_without_LS)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_intercom.len)
		dat += "<h1>AREAS WITHOUT ANY INTERCOMS:</h1>"
		for(var/areatype in areas_without_intercom)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(areas_without_camera.len)
		dat += "<h1>AREAS WITHOUT ANY CAMERAS:</h1>"
		for(var/areatype in areas_without_camera)
			dat += "[areatype]<br>"
			CHECK_TICK

	if(!(areas_with_APC.len || areas_with_multiple_APCs.len || areas_with_air_alarm.len || areas_with_RC.len || areas_with_light.len || areas_with_LS.len || areas_with_intercom.len || areas_with_camera.len))
		dat += "<b>No problem areas!</b>"

	var/datum/browser/popup = new(usr, "testareas", "Test Areas", 500, 750)
	popup.set_content(dat.Join())
	popup.open()


/client/proc/cmd_admin_areatest_station()
	set category = "Debug.Mapping"
	set name = "Test Areas (STATION Z)"
	cmd_admin_areatest(TRUE)

/client/proc/cmd_admin_areatest_all()
	set category = "Debug.Mapping"
	set name = "Test Areas (ALL)"
	cmd_admin_areatest(FALSE)

/client/proc/cmd_admin_dress(mob/M in GLOB.mob_list)
	set category = "GameMaster.Equipping"
	set name = "Select Equipment"

	if(!(ishuman(M) || isobserver(M)))
		return

	var/answer = browser_alert(src, "Apply an outfit or a full job? (Does not consume slots or change job)", "Admin Dress", list("Outfit", "Job", "Cancel"))
	if(!answer || QDELETED(src))
		return
	switch(answer)
		if("Job")
			job_selector(M)
		if("Outfit")
			outfit_selector(M)
		if("Cancel")
			return

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Admin Dress") //If you are copy-pasting this, ensure the 2nd parameter is unique to the new proc!

/client/proc/outfit_selector(mob/to_dress)
	var/dresscode = robust_dress_shop()

	if(!dresscode)
		return

	var/mob/living/carbon/human/H
	if(!ishuman(to_dress))
		H = to_dress.change_mob_type(/mob/living/carbon/human, null, null, TRUE)
	else
		H = to_dress

	for(var/obj/item/I in H.get_all_gear())
		qdel(I)

	if(dresscode != "Naked")
		H.equipOutfit(dresscode)

	log_admin("[key_name(usr)] changed the outfit of [key_name(H)] to [dresscode].")
	message_admins(span_adminnotice("[key_name_admin(usr)] changed the outfit of [ADMIN_LOOKUPFLW(H)] to [dresscode]."))

/client/proc/job_selector(mob/to_dress)
	var/list/basejobs = list("Custom")
	var/list/jobs = subtypesof(/datum/job)
	var/list/selection = list()
	for(var/datum/job/job as anything in jobs)
		if(IS_ABSTRACT(job))
			continue
		selection[job.title] = job

	var/datum/job/selected = browser_input_list(src, "Select Job", "Job selection", basejobs + selection)
	if(!selected || QDELETED(src))
		return

	if(selected == "Custom")
		var/list/custom_jobs = list()
		for(var/id in GLOB.custom_jobs)
			var/datum/job/custom_job/J = GLOB.custom_jobs[id]
			custom_jobs[J.id] = J
		var/selected_name = browser_input_list(src, "Select Job", "Custom Job Selector", sortList(custom_jobs))
		if(!selected_name)
			return
		selected = GLOB.custom_jobs[selected_name]
	else
		selected = SSjob.GetJobType(selection[selected])
		if(!istype(selected))
			return

	var/mob/living/carbon/human/dressed_human
	if(!ishuman(to_dress))
		dressed_human = to_dress.change_mob_type(/mob/living/carbon/human, null, null, TRUE)
	else
		dressed_human = to_dress

	for(var/obj/item/I in dressed_human.get_all_gear())
		qdel(I)

	SSjob.EquipRank(dressed_human, selected, dressed_human.client)
	log_admin("[key_name(src)] changed the job of [key_name(dressed_human)] to [selected].")
	message_admins(span_adminnotice("[key_name_admin(src)] changed the job of [ADMIN_LOOKUPFLW(dressed_human)] to [selected]."))

/client/proc/robust_dress_shop()
	var/list/baseoutfits = list("Naked", "Custom")
	var/list/outfits = list()
	var/list/paths = subtypesof(/datum/outfit)

	for(var/datum/outfit/O as anything in paths) //not much to initalize here but whatever
		if(IS_ABSTRACT(O))
			continue
		if(initial(O.can_be_admin_equipped))
			outfits += O

	var/dresscode = browser_input_list(src, "Select outfit", "Robust quick dress shop", baseoutfits + sortList(outfits))
	if(isnull(dresscode))
		return

	if(outfits[dresscode])
		dresscode = outfits[dresscode]

	if(dresscode == "Custom")
		var/list/custom_names = list()
		for(var/id in GLOB.custom_outfits)
			var/datum/outfit/D = GLOB.custom_outfits[id]
			if(!D)
				continue
			custom_names[D.name] = D
		var/selected_name = browser_input_list(src, "Select outfit", "Robust quick dress shop", sortList(custom_names))
		dresscode = custom_names[selected_name]
		if(isnull(dresscode))
			return

	return dresscode

/client/proc/cmd_debug_mob_lists()
	set category = "Debug.Debug"
	set name = "Debug Mob Lists"
	set desc = ""

	switch(input("Which list?") in list("Players","Admins","Mobs","Living Mobs","Dead Mobs","Clients","Joined Clients"))
		if("Players")
			to_chat(usr, jointext(GLOB.player_list,","))
		if("Admins")
			to_chat(usr, jointext(GLOB.admins,","))
		if("Mobs")
			to_chat(usr, jointext(GLOB.mob_list,","))
		if("Living Mobs")
			to_chat(usr, jointext(GLOB.alive_mob_list,","))
		if("Dead Mobs")
			to_chat(usr, jointext(GLOB.dead_mob_list,","))
		if("Clients")
			to_chat(usr, jointext(GLOB.clients,","))
		if("Joined Clients")
			to_chat(usr, jointext(GLOB.joined_player_list,","))

/client/proc/cmd_display_del_log()
	set category = "Debug.Debug"
	set name = "Display del() Log"
	set desc = ""

	var/list/dellog = list("<B>List of things that have gone through qdel this round</B><BR><BR><ol>")
	sortTim(SSgarbage.items, cmp = GLOBAL_PROC_REF(cmp_qdel_item_time), associative = TRUE)
	for(var/path in SSgarbage.items)
		var/datum/qdel_item/I = SSgarbage.items[path]
		dellog += "<li><u>[path]</u><ul>"
		if(I.qdel_flags & QDEL_ITEM_SUSPENDED_FOR_LAG)

			dellog += "<li>SUSPENDED FOR LAG</li>"
		if(I.failures)
			dellog += "<li>Failures: [I.failures]</li>"
		dellog += "<li>qdel() Count: [I.qdels]</li>"
		dellog += "<li>Destroy() Cost: [I.destroy_time]ms</li>"
		if(I.hard_deletes)
			dellog += "<li>Total Hard Deletes [I.hard_deletes]</li>"
			dellog += "<li>Time Spent Hard Deleting: [I.hard_delete_time]ms</li>"
			dellog += "<li>Highest Time Spent Hard Deleting: [I.hard_delete_max]ms</li>"
			if (I.hard_deletes_over_threshold)
				dellog += "<li>Hard Deletes Over Threshold: [I.hard_deletes_over_threshold]</li>"
		if(I.slept_destroy)
			dellog += "<li>Sleeps: [I.slept_destroy]</li>"
		if(I.no_respect_force)
			dellog += "<li>Ignored force: [I.no_respect_force]</li>"
		if(I.no_hint)
			dellog += "<li>No hint: [I.no_hint]</li>"
		if(LAZYLEN(I.extra_details))
			var/details = I.extra_details.Join("</li><li>")
			dellog += "<li>Extra Info: <ul><li>[details]</li></ul>"
		dellog += "</ul></li>"

	dellog += "</ol>"

	usr << browse(dellog.Join(), "window=dellog")

/client/proc/cmd_display_overlay_log()
	set category = "Debug.Debug"
	set name = "Display overlay Log"
	set desc = ""

	render_stats(SSoverlays.stats, src)

/client/proc/cmd_display_init_log()
	set category = "Debug.Debug"
	set name = "Display Initialize() Log"
	set desc = ""

	usr << browse(replacetext(SSatoms.InitLog(), "\n", "<br>"), "window=initlog")

/client/proc/debug_huds(i as num)
	set category = "Debug.Debug"
	set name = "Debug HUDs"
	set desc = ""

	if(!holder)
		return
	debug_variables(GLOB.huds[i])

/client/proc/jump_to_ruin()
	set category = "Debug"
	set name = "Jump to Ruin"
	set desc = ""
	if(!holder)
		return
	var/list/names = list()
	for(var/obj/effect/landmark/ruin/ruin_landmark as anything in GLOB.ruin_landmarks)
		var/datum/map_template/ruin/template = ruin_landmark.ruin_template

		var/count = 1
		var/name = template.name
		var/original_name = name

		while(name in names)
			count++
			name = "[original_name] ([count])"

		names[name] = ruin_landmark

	var/ruinname = input("Select ruin", "Jump to Ruin") as null|anything in sortList(names)


	var/obj/effect/landmark/ruin/landmark = names[ruinname]

	if(istype(landmark))
		var/datum/map_template/ruin/template = landmark.ruin_template
		usr.forceMove(get_turf(landmark))
		to_chat(usr, "<span class='name'>[template.name]</span>")
		to_chat(usr, "<span class='italics'>[template.description]</span>")
		//this goes after it's logged, incase something horrible happens.

/client/proc/toggle_medal_disable()
	set category = "Debug"
	set name = "Toggle Medal Disable"
	set desc = "Toggles the safety lock on trying to contact the medal hub."

	if(!check_rights(R_DEBUG))
		return

	SSachievements.achievements_enabled = !SSachievements.achievements_enabled

	message_admins(span_adminnotice("[key_name_admin(src)] [SSachievements.achievements_enabled ? "disabled" : "enabled"] the medal hub lockout."))
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Toggle Medal Disable") // If...
	log_admin("[key_name(src)] [SSachievements.achievements_enabled ? "disabled" : "enabled"] the medal hub lockout.")

/client/proc/view_runtimes()
	set category = "Debug.Core"
	set name = "View Runtimes"
	set desc = ""

	if(!holder)
		return

	GLOB.error_cache.show_to(src)

/client/proc/pump_random_event()
	set category = "Debug"
	set name = "Pump Random Event"
	set desc = ""
	if(!holder)
		return

	SSevents.scheduled = world.time

	message_admins("<span class='adminnotice'>[key_name_admin(src)] pumped a random event.</span>")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Pump Random Event")
	log_admin("[key_name(src)] pumped a random event.")

/client/proc/start_line_profiling()
	set category = "Debug.Profiler"
	set name = "Start Line Profiling"
	set desc = ""

	LINE_PROFILE_START

	message_admins("<span class='adminnotice'>[key_name_admin(src)] started line by line profiling.</span>")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Start Line Profiling")
	log_admin("[key_name(src)] started line by line profiling.")

/client/proc/stop_line_profiling()
	set category = "Debug.Profiler"
	set name = "Stops Line Profiling"
	set desc = ""

	LINE_PROFILE_STOP

	message_admins("<span class='adminnotice'>[key_name_admin(src)] stopped line by line profiling.</span>")
	SSblackbox.record_feedback("tally", "admin_verb", 1, "Stop Line Profiling")
	log_admin("[key_name(src)] stopped line by line profiling.")

/client/proc/show_line_profiling()
	set category = "Debug.Profiler"
	set name = "Show Line Profiling"
	set desc = ""

	var/sortlist = list(
		"Avg time"		=	GLOBAL_PROC_REF(cmp_profile_avg_time_dsc),
		"Total Time"	=	GLOBAL_PROC_REF(cmp_profile_time_dsc),
		"Call Count"	=	GLOBAL_PROC_REF(cmp_profile_count_dsc)
	)
	var/sort = input(src, "Sort type?", "Sort Type", "Avg time") as null|anything in sortlist
	if (!sort)
		return
	sort = sortlist[sort]
	profile_show(src, sort)

/client/proc/reload_configuration()
	set category = "Debug"
	set name = "Reload Configuration"
	set desc = ""
	if(!check_rights(R_DEBUG))
		return
	if(alert(usr, "Are you absolutely sure you want to reload the configuration from the default path on the disk, wiping any in-round modificatoins?", "Really reset?", "No", "Yes") == "Yes")
		config.admin_reload()

/// A debug verb to check the sources of currently running timers
/client/proc/check_timer_sources()
	set category = "Debug"
	set name = "Check Timer Sources"
	set desc = "Checks the sources of the running timers"
	if (!check_rights(R_DEBUG))
		return

	var/bucket_list_output = generate_timer_source_output(SStimer.bucket_list)
	var/second_queue = generate_timer_source_output(SStimer.second_queue)
	var/datum/browser/browser = new(usr, "check_timer_sources", "Timer Sources", 700, 700)
	browser.set_content({"
		<h3>bucket_list</h3>
		[bucket_list_output]

		<h3>second_queue</h3>
		[second_queue]
	"})
	browser.open()

/proc/generate_timer_source_output(list/datum/timedevent/events)
	var/list/per_source = list()

	// Collate all events and figure out what sources are creating the most
	for (var/_event in events)
		if (!_event)
			continue
		var/datum/timedevent/event = _event

		do
			if (event.source)
				if (per_source[event.source] == null)
					per_source[event.source] = 1
				else
					per_source[event.source] += 1
			event = event.next
		while (event && event != _event)

	// Now, sort them in order
	var/list/sorted = list()
	for (var/source in per_source)
		sorted += list(list("source" = source, "count" = per_source[source]))
	sortTim(sorted, GLOBAL_PROC_REF(cmp_timer_data))

	// Now that everything is sorted, compile them into an HTML output
	var/output = "<table border='1'>"

	for (var/_timer_data in sorted)
		var/list/timer_data = _timer_data
		output += {"<tr>
			<td><b>[timer_data["source"]]</b></td>
			<td>[timer_data["count"]]</td>
		</tr>"}

	output += "</table>"

	return output

/proc/cmp_timer_data(list/a, list/b)
	return b["count"] - a["count"]

/client/proc/cmd_regenerate_asset_cache()
	set category = "Debug"
	set name = "Regenerate Asset Cache"
	set desc = "Clears the asset cache and regenerates it immediately."
	if(!CONFIG_GET(flag/cache_assets))
		to_chat(usr, "<span class='warning'>Asset caching is disabled in the config!</span>")
		return
	var/regenerated = 0
	for(var/datum/asset/A as anything in subtypesof(/datum/asset))
		if(!initial(A.cross_round_cachable))
			continue
		if(IS_ABSTRACT(A))
			continue
		var/datum/asset/asset_datum = GLOB.asset_datums[A]
		asset_datum.regenerate()
		regenerated++
	to_chat(usr, "<span class='notice'>Regenerated [regenerated] asset\s.</span>")

/client/proc/cmd_clear_smart_asset_cache()
	set category = "Debug"
	set name = "Clear Smart Asset Cache"
	set desc = "Clears the smart asset cache."
	if(!CONFIG_GET(flag/smart_cache_assets))
		to_chat(usr, "<span class='warning'>Smart asset caching is disabled in the config!</span>")
		return
	var/cleared = 0
	for(var/datum/asset/spritesheet_batched/A as anything in subtypesof(/datum/asset/spritesheet_batched))
		if(IS_ABSTRACT(A))
			continue
		fdel("[ASSET_CROSS_ROUND_SMART_CACHE_DIRECTORY]/spritesheet_cache.[initial(A.name)].json")
		cleared++
	to_chat(usr, "<span class='notice'>Cleared [cleared] asset\s.</span>")

/client/proc/select_job_pack_debug()
	set category = "Debug"
	set name = "Select Jobpack"

	if(!check_rights(R_DEBUG))
		return

	var/pack = browser_input_list(usr, "Select a pack", "Job Packs", GLOB.job_pack_singletons)
	if(!pack)
		return

	var/datum/job_pack/real_pack = GLOB.job_pack_singletons[pack]

	real_pack.pick_pack(usr)

/client/proc/debugdailysalarypayroll()
	set category = "Debug.Debug"
	set name = "SALARY DEBUG"
	set desc = "Displays salary configuration, payroll eligibility, Treasury accounts, and payroll readiness."

	if(!check_rights(R_DEBUG))
		return

	if(!SStreasury)
		to_chat(src, span_warning("Treasury subsystem is unavailable."))
		return

	var/list/report = list()
	var/list/seen_minds = list()

	var/configured_jobs = 0
	var/active_workers = 0
	var/active_salary_workers = 0
	var/missing_accounts = 0
	var/total_due = 0

	var/day_key = "day-[GLOB.payroll_day_number]"
	var/day_completed = !!SStreasury.payroll_completed_days[day_key]

	report += "PAYROLL DEBUG | day=[GLOB.payroll_day_number] | tod=[GLOB.tod] | dayspassed=[GLOB.dayspassed] | state=[SSticker.current_state]"
	report += "Treasury=[SStreasury.treasury_value] | completed_today=[day_completed]"

	// Show configured root roles, not advanced classes.
	for(var/datum/job/configured_job as anything in SSjob.all_occupations)
		if(configured_job.parent_job)
			continue

		if(isnum(configured_job.daily_salary) && configured_job.daily_salary > 0)
			configured_jobs++
			report += "CONFIGURED ROLE: [configured_job.title] | salary=[configured_job.daily_salary]"

	if(!configured_jobs)
		report += "CONFIG ERROR: No root role has a positive daily_salary."

	// Inspect currently active human workers.
	for(var/mob/living/carbon/human/employee in GLOB.human_list)
		if(QDELETED(employee))
			continue

		var/datum/mind/employee_mind = employee.mind

		if(!employee_mind || employee_mind.current != employee)
			continue

		if(employee_mind in seen_minds)
			continue

		seen_minds += employee_mind
		active_workers++

		// Preserve the actual assigned role.
		var/datum/job/assigned_job = employee_mind.assigned_role

		if(!istype(assigned_job, /datum/job))
			report += "SKIP [employee.real_name] | reason=invalid assigned role"
			continue

		// Resolve the original/root role for salary purposes.
		var/datum/job/payroll_job = assigned_job
		var/list/visited_jobs = list()

		while(payroll_job.parent_job)
			if(payroll_job in visited_jobs)
				payroll_job = null
				break

			visited_jobs += payroll_job
			payroll_job = payroll_job.parent_job

		if(!payroll_job)
			report += "SKIP [employee.real_name] | assigned_job=[assigned_job.title] | reason=invalid parent_job chain"
			continue

		if(!isnum(payroll_job.daily_salary) || payroll_job.daily_salary <= 0)
			report += "SKIP [employee.real_name] | assigned_job=[assigned_job.title] | payroll_role=[payroll_job.title] | salary=[payroll_job.daily_salary] (not configured)"
			continue

		active_salary_workers++

		var/salary = floor(payroll_job.daily_salary)
		total_due += salary

		// Resolve the existing Treasury account.
		var/account_key = SStreasury.resolve_bank_account_key(employee)

		if(!account_key || !(account_key in SStreasury.bank_accounts))
			missing_accounts++

			report += "BLOCKED [employee.real_name] | assigned_job=[assigned_job.title] | payroll_role=[payroll_job.title] | salary=[salary] | reason=missing Treasury account"
			continue

		var/account_balance = SStreasury.bank_accounts[account_key]

		if(!isnum(account_balance) || account_balance < 0)
			report += "BLOCKED [employee.real_name] | assigned_job=[assigned_job.title] | payroll_role=[payroll_job.title] | salary=[salary] | reason=invalid account balance"
			continue

		report += "ELIGIBLE [employee.real_name] | assigned_job=[assigned_job.title] | payroll_role=[payroll_job.title] | salary=[salary] | balance=[account_balance]"

	// Final diagnostic summary.
	report += "SUMMARY | active=[active_workers] | active_with_salary=[active_salary_workers] | missing_accounts=[missing_accounts] | estimated_payroll=[total_due] | treasury_can_cover=[SStreasury.treasury_value >= total_due]"

	to_chat(src, span_notice(jointext(report, "\n")))

	log_admin("[key_name_admin(src)] generated a daily salary payroll diagnostic.")

/client/proc/DebugSocialRecognition()
	set category = "Debug.Debug"
	set name = "Debug SOCIAL RECOGNITION"

	var/mob/living/carbon/observer = input(usr, "Select the observer.", "Social Recognition Debug") as null|mob in GLOB.player_list

	if(!observer)
		return

	if(!iscarbon(observer))
		to_chat(usr, span_warning("Selected observer is not a carbon mob."))
		return

	var/mob/living/carbon/target = input(usr, "Select the target.", "Social Recognition Debug") as null|mob in GLOB.player_list

	if(!target)
		return

	if(!iscarbon(target))
		to_chat(usr, span_warning("Selected target is not a carbon mob."))
		return

	/*
	 * ========================================================================
	 * ROOT DEBUG HEADER
	 * ========================================================================
	 */

	to_chat(usr, span_boldnotice("===================================================================="))
	to_chat(usr, span_boldnotice("                SOCIAL RECOGNITION TRACE DEBUG"))
	to_chat(usr, span_boldnotice("===================================================================="))

	/*
	 * ========================================================================
	 * OBSERVER
	 * ========================================================================
	 */

	to_chat(usr, span_boldnotice("--- OBSERVER ---"))
	to_chat(usr, "Name: [observer.real_name]")
	to_chat(usr, "Type: [observer.type]")
	to_chat(usr, "Mind: [observer.mind ? "YES" : "NO"]")

	var/datum/job/observer_raw_job = observer.mind?.assigned_role

	to_chat(usr, "Raw assigned job: [observer_raw_job ? observer_raw_job.title : "NONE"]")
	to_chat(usr, "Raw assigned job type: [observer_raw_job ? "[observer_raw_job.type]" : "NONE"]")
	to_chat(usr, "Raw department_flag: [observer_raw_job ? observer_raw_job.department_flag : "NONE"]")

	/*
	 * Walk the actual parent_job chain.
	 *
	 * IMPORTANT:
	 * This deliberately does not call a helper from the social system.
	 * The debug must independently show what the job hierarchy actually is.
	 */

	var/datum/job/observer_base_job = observer_raw_job
	var/observer_parent_depth = 0

	if(observer_base_job)
		while(observer_base_job.parent_job)
			observer_parent_depth++
			to_chat(usr, "Parent #[observer_parent_depth]: [observer_base_job.parent_job.title] ([observer_base_job.parent_job.type])")
			observer_base_job = observer_base_job.parent_job

	to_chat(usr, "Base/root job: [observer_base_job ? observer_base_job.title : "NONE"]")

	to_chat(usr, "Base/root job type: [observer_base_job ? "[observer_base_job.type]" : "NONE"]")

	to_chat(usr, "Base/root department_flag: [observer_base_job ? observer_base_job.department_flag : "NONE"]")

	if(observer_base_job)
		to_chat(
			usr,
			"Base job classification: \
				[istype(observer_base_job, /datum/job/watch_captain) ? "TOWN WATCH CAPTAIN" : \
				istype(observer_base_job, /datum/job/watch_sergeant) ? "TOWN WATCH SERGEANT" : \
				istype(observer_base_job, /datum/job/watch_warden) ? "TOWN WATCH WARDEN" : \
				istype(observer_base_job, /datum/job/watch_veteran) ? "TOWN WATCH VETERAN" : \
				istype(observer_base_job, /datum/job/watch_guard) ? "TOWN WATCH GUARD" : \
				"OTHER / UNKNOWN"]"
		)

	/*
	 * ========================================================================
	 * TARGET
	 * ========================================================================
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- TARGET ---"))
	to_chat(usr, "Name: [target.real_name]")
	to_chat(usr, "Type: [target.type]")
	to_chat(usr, "Mind: [target.mind ? "YES" : "NO"]")

	var/datum/job/target_raw_job = target.mind?.assigned_role

	to_chat(usr, "Raw assigned job: [target_raw_job ? target_raw_job.title : "NONE"]")
	to_chat(usr, "Raw assigned job type: [target_raw_job ? "[target_raw_job.type]" : "NONE"]")
	to_chat(usr, "Raw department_flag: [target_raw_job ? target_raw_job.department_flag : "NONE"]")

	var/datum/job/target_base_job = target_raw_job
	var/target_parent_depth = 0

	if(target_base_job)
		while(target_base_job.parent_job)
			target_parent_depth++
			to_chat(usr, "Parent #[target_parent_depth]: [target_base_job.parent_job.title] ([target_base_job.parent_job.type])")
			target_base_job = target_base_job.parent_job

	to_chat(usr, "Base/root job: [target_base_job ? target_base_job.title : "NONE"]")

	to_chat(usr, "Base/root job type: [target_base_job ? "[target_base_job.type]" : "NONE"]")

	to_chat(usr, "Base/root department_flag: [target_base_job ? target_base_job.department_flag : "NONE"]")

	if(target_base_job)
		to_chat(
			usr,
			"Base job classification: \
				[istype(target_base_job, /datum/job/watch_captain) ? "TOWN WATCH CAPTAIN" : \
				istype(target_base_job, /datum/job/watch_sergeant) ? "TOWN WATCH SERGEANT" : \
				istype(target_base_job, /datum/job/watch_warden) ? "TOWN WATCH WARDEN" : \
				istype(target_base_job, /datum/job/watch_veteran) ? "TOWN WATCH VETERAN" : \
				istype(target_base_job, /datum/job/watch_guard) ? "TOWN WATCH GUARD" : \
				"OTHER / UNKNOWN"]")

	/*
	 * ========================================================================
	 * BASIC OBSERVER/TARGET COMPARISON
	 * ========================================================================
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- ROLE COMPARISON ---"))

	var/observer_is_townwatch = FALSE
	var/target_is_townwatch = FALSE

	if(observer_base_job)
		observer_is_townwatch = !!(observer_base_job.department_flag & TOWNWATCH)

	if(target_base_job)
		target_is_townwatch = !!(target_base_job.department_flag & TOWNWATCH)

	to_chat(
		usr,
		"Observer is Town Watch: [observer_is_townwatch ? "YES" : "NO"]"
	)

	to_chat(
		usr,
		"Target is Town Watch: [target_is_townwatch ? "YES" : "NO"]"
	)

	var/observer_is_lower_watch = FALSE
	var/observer_is_command_watch = FALSE
	var/target_is_lower_watch = FALSE
	var/target_is_command_watch = FALSE

	if(observer_base_job)
		observer_is_lower_watch = (istype(observer_base_job, /datum/job/watch_guard) || istype(observer_base_job, /datum/job/watch_veteran) || istype(observer_base_job, /datum/job/watch_warden))

		observer_is_command_watch = (istype(observer_base_job, /datum/job/watch_sergeant) || istype(observer_base_job, /datum/job/watch_captain))

	if(target_base_job)
		target_is_lower_watch = (istype(target_base_job, /datum/job/watch_guard) || istype(target_base_job, /datum/job/watch_veteran) || istype(target_base_job, /datum/job/watch_warden))

		target_is_command_watch = (istype(target_base_job, /datum/job/watch_sergeant) || istype(target_base_job, /datum/job/watch_captain))

	to_chat(usr, "Observer lower-watch: [observer_is_lower_watch ? "YES" : "NO"]")

	to_chat(usr, "Observer command-watch: [observer_is_command_watch ? "YES" : "NO"]")

	to_chat(usr, "Target lower-watch: [target_is_lower_watch ? "YES" : "NO"]")

	to_chat(usr, "Target command-watch: [target_is_command_watch ? "YES" : "NO"]")

	/*
	 * This is the relationship the intended Town Watch hierarchy SHOULD
	 * produce, independently of the reaction system.
	 */

	var/expected_relationship = SOCIAL_RELATION_NEUTRAL

	if(observer_is_townwatch && target_is_townwatch)
		if(observer_is_lower_watch && target_is_command_watch)
			expected_relationship = SOCIAL_RELATION_HIGHER_RANK
		else
			expected_relationship = SOCIAL_RELATION_ALLIED

	to_chat(usr, "Expected Town Watch relationship: [expected_relationship]")

	/*
	 * ========================================================================
	 * SOCIAL CONTEXT
	 * ========================================================================
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- SOCIAL CONTEXT ---"))

	var/datum/examine_social_context/context = target.build_social_context(observer)

	if(!context)
		to_chat(usr, span_warning("FAILED: build_social_context() returned NULL."))
		return

	to_chat(usr, "Context observer: [context.observer ? context.observer.real_name : "NONE"]")
	to_chat(usr, "Context target: [context.target ? context.target.real_name : "NONE"]")
	to_chat(usr, "Context target job: [context.target_job ? context.target_job.title : "NONE"]")
	to_chat(usr, "Target wanted: [context.target_wanted ? "YES" : "NO"]")
	to_chat(usr, "Face visible: [context.target_face_visible ? "YES" : "NO"]")
	to_chat(usr, "Identity known: [context.identity_known ? "YES" : "NO"]")
	to_chat(usr, "Visible items: [length(context.visible_items)]")

	/*
	 * ========================================================================
	 * SOCIAL CUES
	 * ========================================================================
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- VISIBLE SOCIAL CUES ---"))

	if(length(context.visible_social_cues))
		for(var/cue_key in context.visible_social_cues)
			to_chat(usr, "[cue_key] = [context.visible_social_cues[cue_key]]")
	else
		to_chat(usr, "  NONE")

	/*
	 * ========================================================================
	 * SOCIAL PROFILES
	 * ========================================================================
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- PROFILE EVALUATION ---"))

	var/list/recognitions = list()

	for(var/datum/social_profile/profile as anything in GLOB.social_profiles)
		if(!profile)
			continue

		to_chat(usr, "")
		to_chat(usr, span_boldnotice("PROFILE: [profile.id]"))
		to_chat(usr, "Display name: [profile.display_name]")
		to_chat(usr, "Faction flag: [profile.faction_flag]")
		to_chat(usr, "Recognition trait: [profile.recognition_trait ? "[profile.recognition_trait]" : "NONE"]")
		to_chat(usr, "Rank trait: [profile.rank_trait ? "[profile.rank_trait]" : "NONE"]")
		to_chat(usr, "Specialization trait: [profile.specialization_trait ? "[profile.specialization_trait]" : "NONE"]")

		var/datum/social_recognition/recognition = profile.evaluate(observer, context)

		if(!recognition)
			to_chat(usr, "RESULT: NOT RECOGNIZED")
			continue

		recognitions += recognition

		to_chat(usr, "RESULT: RECOGNIZED")
		to_chat(usr, "Actual faction: [recognition.actual_faction ? "YES" : "NO"]")
		to_chat(usr, "Actual elite: [recognition.actual_elite ? "YES" : "NO"]")
		to_chat(usr, "Identity recognized: [recognition.identity_recognized ? "YES" : "NO"]")
		to_chat(usr, "Known faction: [recognition.known_faction ? "YES" : "NO"]")
		to_chat(usr, "Apparent faction: [recognition.apparent_faction ? "YES" : "NO"]")
		to_chat(usr, "Known rank: [recognition.known_rank ? "YES" : "NO"]")
		to_chat(usr, "Apparent rank: [recognition.apparent_rank ? "YES" : "NO"]")
		to_chat(usr, "Known specialization: [recognition.known_specialization ? "YES" : "NO"]")
		to_chat(usr, "Apparent specialization: [recognition.apparent_specialization ? "YES" : "NO"]")
		to_chat(usr, "Elite equipment recognized: [recognition.elite_equipment_recognized ? "YES" : "NO"]")
		to_chat(usr, "Apparent elite member: [recognition.apparent_elite_member ? "YES" : "NO"]")
		to_chat(usr, "Personnel recognized: [recognition.personnel_recognized ? "YES" : "NO"]")
		to_chat(usr, "Personnel mismatch: [recognition.personnel_mismatch ? "YES" : "NO"]")
		to_chat(usr, "Elite personnel mismatch: [recognition.elite_personnel_mismatch ? "YES" : "NO"]")
		to_chat(usr, "Presentation state: [recognition.presentation_state]")
		to_chat(usr, "Solid faction: [recognition.solid_faction ? "YES" : "NO"]")
		to_chat(usr, "Social legitimacy: [recognition.social_legitimacy]")
		to_chat(usr, "Faction appearance score: [recognition.faction_appearance_score]")
		to_chat(usr, "Elite appearance score: [recognition.elite_appearance_score]")
		to_chat(usr, "Rank appearance score: [recognition.rank_appearance_score]")
		to_chat(usr, "Specialization appearance score: [recognition.specialization_appearance_score]")
		to_chat(usr, "Prestige appearance score: [recognition.prestige_appearance_score]")
		to_chat(usr, "Source flags: [recognition.source]")
		to_chat(usr, "Final recognition score: [recognition.score]")

		to_chat(usr, "Apparent rank title: [recognition.apparent_rank_title ? recognition.apparent_rank_title : "NONE"]")

		to_chat(usr, "Apparent specialization title: [recognition.apparent_specialization_title ? recognition.apparent_specialization_title : "NONE"]")

		/*
		 * Show exactly what the current reaction function sees.
		 */

		to_chat(usr, "")
		to_chat(usr, span_boldnotice("REACTION PRECONDITIONS"))

		to_chat(usr, "recognition.faction_recognized: [recognition.faction_recognized ? "YES" : "NO"]")

		to_chat(usr, "user.mind.assigned_role exists: [observer.mind?.assigned_role ? "YES" : "NO"]")

		var/raw_observer_faction = observer.mind?.assigned_role?.department_flag
		var/profile_faction = profile.get_profile_faction_flag()

		to_chat(usr, "Current code raw observer department_flag: [raw_observer_faction]")

		to_chat(usr, "Current profile faction flag: [profile_faction]")

		to_chat(usr, "Normalized observer faction: [observer_base_job?.department_flag]")

		to_chat(usr, "Normalized target faction: [target_base_job?.department_flag]")

		/*
		 * IMPORTANT:
		 * Current get_reactions() uses the observer's RAW assigned_role
		 * department_flag. This line explicitly exposes the value it will
		 * currently receive.
		 */

		if(!recognition.faction_recognized)
			to_chat(usr, span_warning("REACTION STOP: faction_recognized == FALSE."))
		else if(!observer.mind?.assigned_role)
			to_chat(usr, span_warning("REACTION STOP: observer has no assigned_role."))
		else if(!profile_faction)
			to_chat(usr, span_warning("REACTION STOP: profile returned no faction flag."))
		else
			to_chat(usr, "Current raw relationship input: [raw_observer_faction] -> [profile_faction]")

			if(!raw_observer_faction)
				to_chat(usr, span_warning("LIKELY FAILURE: observer's assigned_role.department_flag is ZERO."))

				to_chat(usr, span_warning("Use the parent/base job department_flag for hierarchy-aware reactions."))

	/*
	 * ========================================================================
	 * ACTUAL REACTION GENERATION
	 * ========================================================================
	 *
	 * This invokes the real profile reaction generator.
	 * No simulation here.
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- ACTUAL REACTION GENERATION ---"))

	var/list/all_reactions = list()

	for(var/datum/social_recognition/recognition as anything in recognitions)
		if(!recognition?.profile)
			continue

		var/before_count = length(all_reactions)

		recognition.profile.get_reactions(observer, context, recognition, all_reactions)

		var/after_count = length(all_reactions)
		var/generated = after_count - before_count

		to_chat(usr, "Profile '[recognition.profile.id]' generated [generated] reaction(s).")

		if(generated)
			for(var/i in (before_count + 1) to after_count)
				var/datum/examine_social_reaction/reaction = all_reactions[i]

				to_chat(usr, "  Reaction #[i - before_count]")
				to_chat(usr, "    Datum: [reaction.type]")
				to_chat(usr, "    Stress type: [reaction.stress_type ? "[reaction.stress_type]" : "NONE"]")
				to_chat(usr, "    Phrase count: [length(reaction.phrases)]")

				for(var/phrase in reaction.phrases)
					to_chat(usr, "      - [phrase]")

	/*
	 * ========================================================================
	 * FINAL REACTION RESOLUTION
	 * ========================================================================
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- FINAL REACTION RESOLUTION ---"))

	to_chat(usr, "Total generated reactions: [length(all_reactions)]")

	if(!length(all_reactions))
		to_chat(usr, span_warning("No reactions were generated."))
		to_chat(usr, span_warning("Failure is upstream of resolve_strongest_social_reaction()."))
	else
		for(var/datum/examine_social_reaction/reaction as anything in all_reactions)
			to_chat(usr, "Candidate: [reaction.type] | Stress: [reaction.stress_type ? "[reaction.stress_type]" : "NONE"]")

			if(reaction.stress_type)
				to_chat(usr, "  Already has stress: [observer.has_stress_type(reaction.stress_type) ? "YES" : "NO"]")

				var/datum/stress_event/event = new reaction.stress_type

				if(event)
					to_chat(usr, "  can_apply(): [event.can_apply(observer) ? "YES" : "NO"]")

					if(event.can_apply(observer))
						to_chat(usr, "  get_stress(): [event.get_stress(observer)]")

					qdel(event)

	var/datum/examine_social_reaction/strongest = \
		observer.resolve_strongest_social_reaction(observer, all_reactions)

	if(!strongest)
		to_chat(usr, span_warning("STRONGEST REACTION: NONE"))
	else
		to_chat(usr, span_notice("STRONGEST REACTION: [strongest.type]"))

		to_chat(usr, "Stress type: [strongest.stress_type ? "[strongest.stress_type]" : "NONE"]")

		to_chat(usr, "Selected phrase: [strongest.get_phrase()]")

	/*
	 * ========================================================================
	 * EXPECTED VS ACTUAL
	 * ========================================================================
	 */

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("--- EXPECTED VS ACTUAL ---"))

	if(observer_is_townwatch && target_is_townwatch)
		to_chat(usr, "Expected relationship from normalized jobs: [expected_relationship]")
	else
		to_chat(usr, "Expected relationship from normalized jobs: not a Town Watch-vs-Town Watch case.")

	if(!length(all_reactions))
		to_chat(usr, span_warning("RESULT: Expected relationship exists, but actual reaction generator produced NOTHING."))

		if(observer_is_townwatch && target_is_townwatch)
			if(observer_base_job && observer_base_job.department_flag & TOWNWATCH)
				if(observer_raw_job && !(observer_raw_job.department_flag & TOWNWATCH))
					to_chat(usr, span_warning("DIAGNOSIS: observer raw job lost the Town Watch department flag."))
					to_chat(usr, span_warning("DIAGNOSIS: parent/base job contains the faction information."))

	to_chat(usr, "")
	to_chat(usr, span_boldnotice("===================================================================="))
	to_chat(usr, span_boldnotice("                    END SOCIAL TRACE"))
	to_chat(usr, span_boldnotice("===================================================================="))


/client/proc/timeskip_to()
	set category = "Debug"
	set name = "Timeskip To"
	set desc = "Simulates TOD transitions and daily events until the selected in-game time."

	if(!check_rights(R_DEBUG))
		return

	if(SSticker.current_state != GAME_STATE_PLAYING)
		to_chat(src, span_warning("Timeskip is only available during active gameplay."))
		return

	if(GLOB.todoverride)
		to_chat(src, span_warning("Disable SetTODOverride before using Timeskip To."))
		return

	var/list/TODs = list("dawn", "day", "dusk", "night")
	var/target_tod = input(src, "Select the target time of day.", "Timeskip To") as null|anything in TODs

	if(!target_tod)
		return

	var/days_to_advance = input(
		src,
		"How many dawn transitions should occur before reaching the selected TOD? (1-7)",
		"Timeskip To",
		1
	) as null|num

	if(isnull(days_to_advance))
		return

	days_to_advance = round(days_to_advance)

	if(days_to_advance < 1 || days_to_advance > 7)
		to_chat(src, span_warning("Choose between 1 and 7 days."))
		return

	if(alert(
		src,
		"This will process [days_to_advance] dawn transitions, including daily Treasury payments and other TOD-dependent events. Continue?",
		"Confirm Timeskip",
		"Yes",
		"No"
	) != "Yes")
		return

	// Synchronize any natural transition that has not yet been processed.
	settod()

	var/target_day_number = GLOB.payroll_day_number + days_to_advance
	var/max_transitions = (days_to_advance * 4) + 4
	var/transitions_processed = 0
	var/failed = FALSE

	while(GLOB.payroll_day_number < target_day_number || GLOB.tod != target_tod)
		if(transitions_processed >= max_transitions)
			failed = TRUE
			break

		if(!advance_station_time_to_next_tod_boundary())
			failed = TRUE
			break

		transitions_processed++

	// Apply player-facing effects only for the final TOD.
	for(var/mob/living/player in GLOB.mob_list)
		if(player.stat != DEAD && player.client)
			player.do_time_change()

	if(failed)
		to_chat(src, span_warning("Timeskip stopped early. Current TOD: [GLOB.tod]. Processed transitions: [transitions_processed]."))
		log_admin("[key_name_admin(src)] attempted a timeskip to [target_tod], but it stopped early.")
		return

	message_admins("[key_name_admin(src)] timeskipped [days_to_advance] dawn transitions to [target_tod].")
	log_admin("[key_name_admin(src)] timeskipped [days_to_advance] dawn transitions to [target_tod].")

	to_chat(src, span_notice("Timeskip complete. Current TOD: [GLOB.tod]. Payroll day: [GLOB.payroll_day_number]."))

	SSblackbox.record_feedback("tally", "admin_verb", 1, "Timeskip To")

/// Admin: add a globally permitted magical action identifier.
/client/proc/anti_magic_add_global_whitelist()
	set name = "Add Anti-Magic Whitelist Entry"
	set category = "Admin.Anti-Magic"
	if(!check_rights(R_ADMIN))
		return
	var/action_id = input(src, "Enter a stable action ID (normally the full DM type path).", "Global Anti-Magic Whitelist") as text|null
	if(!action_id)
		return
	action_id = trim(action_id)
	if(!length(action_id))
		return
	if(!(action_id in GLOB.anti_magic_field_manager.global_whitelist))
		GLOB.anti_magic_field_manager.global_whitelist += action_id
	message_admins("[key_name_admin(src)] added [action_id] to the global Anti-Magic whitelist.")
	to_chat(src, span_notice("Global Anti-Magic whitelist updated."))

/// Admin: remove a globally permitted magical action identifier.
/client/proc/anti_magic_remove_global_whitelist()
	set name = "Remove Anti-Magic Whitelist Entry"
	set category = "Admin.Anti-Magic"
	if(!check_rights(R_ADMIN))
		return
	var/list/entries = GLOB.anti_magic_field_manager.global_whitelist.Copy()
	if(!length(entries))
		to_chat(src, span_notice("The global Anti-Magic whitelist is empty."))
		return
	var/action_id = input(src, "Choose an action ID to remove.", "Global Anti-Magic Whitelist") as null|anything in entries
	if(!action_id)
		return
	GLOB.anti_magic_field_manager.global_whitelist -= action_id
	message_admins("[key_name_admin(src)] removed [action_id] from the global Anti-Magic whitelist.")
	to_chat(src, span_notice("Global Anti-Magic whitelist updated."))

/// Admin: change a specific field's AoE and/or its local whitelist overrides.
/client/proc/anti_magic_edit_field()
	set name = "Configure Anti-Magic Field"
	set category = "Admin.Anti-Magic"
	if(!check_rights(R_ADMIN))
		return
	var/list/available_fields = list()
	for(var/obj/structure/anti_magic_field/field as anything in GLOB.anti_magic_field_manager.fields)
		if(!QDELETED(field))
			available_fields += field
	if(!length(available_fields))
		to_chat(src, span_notice("There are no Anti-Magic field devices to configure."))
		return
	var/obj/structure/anti_magic_field/selected_field = input(src, "Choose a field device.", "Configure Anti-Magic Field") as null|anything in available_fields
	if(!selected_field || QDELETED(selected_field))
		return
	var/choice = input(src, "Choose a configuration action.", "Configure Anti-Magic Field") as null|anything in list("Set width", "Set height", "Reset default AoE", "Allow action locally", "Deny action locally", "Clear local action override")
	if(!choice || QDELETED(selected_field))
		return
	switch(choice)
		if("Set width")
			var/new_width = input(src, "New AoE width (1-32).", "Anti-Magic AoE", selected_field.field_width) as num|null
			if(isnull(new_width) || QDELETED(selected_field))
				return
			selected_field.field_width = clamp(round(new_width), 1, 32)
		if("Set height")
			var/new_height = input(src, "New AoE height (1-32).", "Anti-Magic AoE", selected_field.field_height) as num|null
			if(isnull(new_height) || QDELETED(selected_field))
				return
			selected_field.field_height = clamp(round(new_height), 1, 32)
		if("Reset default AoE")
			selected_field.field_width = initial(selected_field.field_width)
			selected_field.field_height = initial(selected_field.field_height)
		if("Allow action locally", "Deny action locally", "Clear local action override")
			var/action_id = input(src, "Enter the exact action identifier.", "Field Whitelist Override") as text|null
			if(!action_id || QDELETED(selected_field))
				return
			action_id = trim(action_id)
			if(!length(action_id))
				return
			if(choice == "Allow action locally")
				selected_field.whitelist_overrides[action_id] = TRUE
			else if(choice == "Deny action locally")
				selected_field.whitelist_overrides[action_id] = FALSE
			else
				selected_field.whitelist_overrides -= action_id
	selected_field.update_appearance(UPDATE_ICON_STATE)
	message_admins("[key_name_admin(src)] configured [selected_field] at [AREACOORD(selected_field)]: [choice].")
	to_chat(src, span_notice("Anti-Magic field configuration updated."))
