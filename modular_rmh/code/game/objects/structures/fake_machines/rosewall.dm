// Rosewall: a personal notes board. Idea and art from Ratwood-2.0's rosewall.dm; notes persist in a JSON file.

#define ROSEWALL_SAVE_FILE "data/rosewall.json"
#define ROSEWALL_SAVE_VERSION 1
#define ROSEWALL_MAX_POSTS 100
#define ROSEWALL_MAX_POSTS_PER_PLAYER 3
#define ROSEWALL_TEXT_MAX_LENGTH 1000
#define ROSEWALL_SEEKING_MAX_LENGTH 150
#define ROSEWALL_NAME_MAX_LENGTH MAX_NAME_LEN
#define ROSEWALL_EXPIRY_DAYS 30
#define ROSEWALL_ACTION_COOLDOWN (3 SECONDS)
#define ROSEWALL_DAY_LENGTH (24 HOURS)

GLOBAL_DATUM_INIT(rosewall, /datum/rosewall_store, new)
/// Mapped Rosewall boards, refreshed when a note changes.
GLOBAL_LIST_EMPTY(rosewall_boards)

/// One pinned note. Holds text only, never mob references.
/datum/rosewall_post
	var/id
	var/author_ckey
	var/character_name
	var/seeking
	var/text
	/// Days since 2000 at the last edit; notes older than ROSEWALL_EXPIRY_DAYS are dropped.
	var/posted_day
	var/posted_date

/datum/rosewall_post/proc/to_save_list()
	return list(
		"ckey" = author_ckey,
		"name" = character_name,
		"seeking" = seeking,
		"text" = text,
		"day" = posted_day,
		"date" = posted_date,
	)

/// Holds every Rosewall note, oldest first, and reads and writes the save file.
/datum/rosewall_store
	var/save_path = ROSEWALL_SAVE_FILE
	var/loaded = FALSE
	var/list/datum/rosewall_post/posts = list()
	var/next_id = 0

/datum/rosewall_store/New(save_path)
	if(save_path)
		src.save_path = save_path

/datum/rosewall_store/proc/current_day()
	return floor(world.realtime / ROSEWALL_DAY_LENGTH)

/// Strips HTML, caps the length and trims; returns null for empty text.
/datum/rosewall_store/proc/clean_text(text, max_length, multiline = FALSE)
	if(isnull(text))
		return null
	var/static/regex/blank_lines = regex(@"\n{3,}", "g")
	text = replacetext("[text]", ascii2text(13), "")
	if(multiline)
		text = blank_lines.Replace(text, "\n\n")
	else
		text = replacetext(text, "\n", " ")
	text = STRIP_HTML_FULL(text, max_length + 1)
	text = GLOB.angular_brackets.Replace(text, "")
	text = trim(text)
	return length(text) ? text : null

/datum/rosewall_store/proc/ensure_loaded()
	if(!loaded)
		load()

/// Reads the save file; a missing or broken file gives an empty board.
/datum/rosewall_store/proc/load()
	loaded = TRUE
	posts = list()
	if(!fexists(save_path))
		return
	var/list/root = safe_json_decode(file2text(save_path))
	if(!islist(root) || !islist(root["posts"]))
		log_game("Cupids Crossbow: [save_path] could not be read, the board starts empty.")
		return
	var/today = current_day()
	var/list/seen_notes = list()
	var/list/notes_per_player = list()
	for(var/entry in root["posts"])
		var/datum/rosewall_post/post = post_from_save(entry, today)
		if(!post)
			continue
		var/note_key = "[post.author_ckey]|[post.character_name]"
		if(seen_notes[note_key] || notes_per_player[post.author_ckey] >= ROSEWALL_MAX_POSTS_PER_PLAYER)
			continue
		seen_notes[note_key] = TRUE
		notes_per_player[post.author_ckey]++
		posts += post
	trim_to_cap()

/datum/rosewall_store/proc/post_from_save(list/entry, today)
	if(!islist(entry))
		return null
	var/author = ckey("[entry["ckey"]]")
	var/name = clean_text(entry["name"], ROSEWALL_NAME_MAX_LENGTH)
	var/body = clean_text(entry["text"], ROSEWALL_TEXT_MAX_LENGTH, TRUE)
	var/day = entry["day"]
	if(!length(author) || !name || !body || !isnum(day))
		return null
	if(today - day > ROSEWALL_EXPIRY_DAYS || day > today + 1)
		return null
	var/datum/rosewall_post/post = new
	post.id = "[++next_id]"
	post.author_ckey = author
	post.character_name = name
	post.seeking = clean_text(entry["seeking"], ROSEWALL_SEEKING_MAX_LENGTH)
	post.text = body
	post.posted_day = day
	post.posted_date = clean_text(entry["date"], 16) || ""
	return post

/datum/rosewall_store/proc/save()
	var/list/entries = list()
	for(var/datum/rosewall_post/post as anything in posts)
		entries += list(post.to_save_list())
	fdel(save_path)
	text2file(json_encode(list("version" = ROSEWALL_SAVE_VERSION, "posts" = entries)), save_path)

/datum/rosewall_store/proc/find_post(id)
	ensure_loaded()
	for(var/datum/rosewall_post/post as anything in posts)
		if(post.id == id)
			return post
	return null

/datum/rosewall_store/proc/find_own_post(author_ckey, character_name)
	ensure_loaded()
	if(!author_ckey || !character_name)
		return null
	for(var/datum/rosewall_post/post as anything in posts)
		if(post.author_ckey == author_ckey && post.character_name == character_name)
			return post
	return null

/datum/rosewall_store/proc/count_posts_by(author_ckey)
	ensure_loaded()
	. = 0
	for(var/datum/rosewall_post/post as anything in posts)
		if(post.author_ckey == author_ckey)
			.++

/// Creates or replaces the note of one character; returns null when refused.
/datum/rosewall_store/proc/set_post(author_ckey, character_name, seeking, text)
	ensure_loaded()
	author_ckey = ckey("[author_ckey]")
	character_name = clean_text(character_name, ROSEWALL_NAME_MAX_LENGTH)
	text = clean_text(text, ROSEWALL_TEXT_MAX_LENGTH, TRUE)
	if(!length(author_ckey) || !character_name || !text)
		return null
	var/datum/rosewall_post/post = find_own_post(author_ckey, character_name)
	if(post)
		posts -= post
	else
		if(count_posts_by(author_ckey) >= ROSEWALL_MAX_POSTS_PER_PLAYER)
			return null
		post = new
		post.id = "[++next_id]"
		post.author_ckey = author_ckey
		post.character_name = character_name
	post.seeking = clean_text(seeking, ROSEWALL_SEEKING_MAX_LENGTH)
	post.text = text
	post.posted_day = current_day()
	post.posted_date = time2text(world.realtime, "YYYY-MM-DD")
	posts += post
	prune_expired()
	trim_to_cap()
	changed()
	return post

/datum/rosewall_store/proc/remove_post(datum/rosewall_post/post)
	ensure_loaded()
	if(!(post in posts))
		return FALSE
	posts -= post
	changed()
	return TRUE

/datum/rosewall_store/proc/prune_expired()
	var/today = current_day()
	for(var/datum/rosewall_post/post as anything in posts.Copy())
		if(today - post.posted_day > ROSEWALL_EXPIRY_DAYS)
			posts -= post

/// Drops the oldest notes past the board cap.
/datum/rosewall_store/proc/trim_to_cap()
	if(length(posts) > ROSEWALL_MAX_POSTS)
		posts.Cut(1, length(posts) - ROSEWALL_MAX_POSTS + 1)

/datum/rosewall_store/proc/changed()
	save()
	for(var/obj/structure/fake_machine/rosewall/board as anything in GLOB.rosewall_boards)
		board.update_appearance(UPDATE_ICON_STATE)
		SStgui.update_uis(board)

/// Admins, the Town Mouth and the burgmeister may take down any note.
/proc/rosewall_can_moderate(mob/user)
	if(!user)
		return FALSE
	if(user.client && check_rights_for(user.client, R_ADMIN))
		return TRUE
	var/datum/job/job = user.mind?.assigned_role
	return istype(job, /datum/job/advclass/towner/town_mouth) || istype(job, /datum/job/burgmeister) || istype(job, /datum/job/advclass/burgmeister)

/obj/structure/fake_machine/rosewall
	name = "Cupid's Crossbow"
	desc = "A board for your hopes and dreams. Shoot your shot: leave a note with your description, whom you wish to meet, and hope your second half finds you."
	icon = 'modular_rmh/icons/obj/structures/rosewall.dmi'
	icon_state = "noticeboardbh0"
	density = FALSE
	layer = ABOVE_MOB_LAYER
	blade_dulling = DULLING_BASH
	SET_BASE_PIXEL(0, 32)
	/// Player ckey to world.time of their next allowed change; stale entries are cleared as it grows.
	var/static/list/next_action_at = list()

/obj/structure/fake_machine/rosewall/Initialize(mapload)
	. = ..()
	GLOB.rosewall_boards += src
	GLOB.rosewall.ensure_loaded()
	update_appearance(UPDATE_ICON_STATE)

/obj/structure/fake_machine/rosewall/Destroy()
	GLOB.rosewall_boards -= src
	return ..()

/obj/structure/fake_machine/rosewall/update_icon_state()
	. = ..()
	switch(length(GLOB.rosewall.posts))
		if(0)
			icon_state = "noticeboardbh0"
		if(1 to 5)
			icon_state = "noticeboardbh1"
		if(6 to 20)
			icon_state = "noticeboardbh2"
		else
			icon_state = "noticeboardbh3"

/obj/structure/fake_machine/rosewall/ui_state(mob/user)
	return GLOB.human_adjacent_state

/obj/structure/fake_machine/rosewall/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "Rosewall", name)
		ui.open()

/obj/structure/fake_machine/rosewall/ui_data(mob/user)
	var/datum/rosewall_store/store = GLOB.rosewall
	store.ensure_loaded()
	var/viewer_ckey = author_key(user)
	var/character_name = ishuman(user) ? user.real_name : null
	var/moderator = rosewall_can_moderate(user)
	var/list/entries = list()
	for(var/i in length(store.posts) to 1 step -1)
		var/datum/rosewall_post/post = store.posts[i]
		var/is_own = viewer_ckey && post.author_ckey == viewer_ckey
		entries += list(list(
			"id" = post.id,
			"name" = post.character_name,
			"seeking" = post.seeking || "",
			"text" = post.text,
			"date" = post.posted_date,
			"is_own" = is_own ? TRUE : FALSE,
			"can_remove" = (is_own || moderator) ? TRUE : FALSE,
		))
	var/datum/rosewall_post/own_post = store.find_own_post(viewer_ckey, character_name)
	var/list/data = list()
	data["posts"] = entries
	data["character_name"] = character_name || ""
	data["can_post"] = (character_name && viewer_ckey) ? TRUE : FALSE
	data["own_post"] = own_post ? list("id" = own_post.id, "seeking" = own_post.seeking || "", "text" = own_post.text) : null
	data["own_count"] = viewer_ckey ? store.count_posts_by(viewer_ckey) : 0
	data["own_cap"] = ROSEWALL_MAX_POSTS_PER_PLAYER
	data["text_limit"] = ROSEWALL_TEXT_MAX_LENGTH
	data["seeking_limit"] = ROSEWALL_SEEKING_MAX_LENGTH
	return data

/obj/structure/fake_machine/rosewall/ui_act(action, list/params)
	. = ..()
	if(.)
		return
	var/mob/living/carbon/human/user = usr
	if(!istype(user) || !author_key(user))
		return TRUE
	if(!user.can_perform_action(src, NEED_DEXTERITY|FORBID_TELEKINESIS_REACH))
		return TRUE
	switch(action)
		if("save_post")
			save_post(user, params)
			return TRUE
		if("remove_post")
			remove_post(user, params)
			return TRUE

/// The player key a note belongs to.
/obj/structure/fake_machine/rosewall/proc/author_key(mob/user)
	return user.ckey

/obj/structure/fake_machine/rosewall/proc/on_cooldown(mob/user)
	var/key = author_key(user)
	if(length(next_action_at) > 50)
		for(var/stale_key in next_action_at)
			if(next_action_at[stale_key] <= world.time)
				next_action_at -= stale_key
	if(next_action_at[key] > world.time)
		to_chat(user, span_warning("Wait a moment before changing the Cupid's Crossbow again."))
		return TRUE
	next_action_at[key] = world.time + ROSEWALL_ACTION_COOLDOWN
	return FALSE

/obj/structure/fake_machine/rosewall/proc/save_post(mob/living/carbon/human/user, list/params)
	var/datum/rosewall_store/store = GLOB.rosewall
	var/key = author_key(user)
	if(!store.clean_text(params["text"], ROSEWALL_TEXT_MAX_LENGTH, TRUE))
		to_chat(user, span_warning("My note is empty."))
		return
	if(!store.find_own_post(key, user.real_name) && store.count_posts_by(key) >= ROSEWALL_MAX_POSTS_PER_PLAYER)
		to_chat(user, span_warning("I already have [ROSEWALL_MAX_POSTS_PER_PLAYER] notes on the Cupid's Crossbow. Take one down first."))
		return
	if(on_cooldown(user))
		return
	var/datum/rosewall_post/post = store.set_post(key, user.real_name, params["seeking"], params["text"])
	if(!post)
		to_chat(user, span_warning("The note could not be pinned."))
		return
	to_chat(user, span_notice("I pin my note to the Cupid's Crossbow."))
	playsound(loc, 'sound/foley/dropsound/paper_drop.ogg', 50, FALSE, -1)
	log_paper("[key_name(user)] pinned a Cupids Crossbow note as [post.character_name]. Looking for: [post.seeking]. Note: [post.text]")
	message_admins("[ADMIN_LOOKUPFLW(user)] pinned a Cupids Crossbow note as [html_encode(post.character_name)].")

/obj/structure/fake_machine/rosewall/proc/remove_post(mob/living/carbon/human/user, list/params)
	var/datum/rosewall_store/store = GLOB.rosewall
	var/datum/rosewall_post/post = store.find_post("[params["id"]]")
	if(!post)
		return
	var/is_own = post.author_ckey == author_key(user)
	if(!is_own && !rosewall_can_moderate(user))
		to_chat(user, span_warning("Only the writer, the Town Mouth, the burgmeister or higher forces can take this note down."))
		return
	if(on_cooldown(user))
		return
	store.remove_post(post)
	playsound(loc, 'sound/foley/dropsound/paper_drop.ogg', 50, FALSE, -1)
	if(is_own)
		to_chat(user, span_notice("I take my note down from the Cupid's Crossbow."))
		log_paper("[key_name(user)] took down their Cupids Crossbow note as [post.character_name].")
		return
	to_chat(user, span_notice("I take down the note of [post.character_name]."))
	log_paper("[key_name(user)] took down the Cupids Crossbow note of [post.character_name] ([post.author_ckey]).")
	message_admins("[ADMIN_LOOKUPFLW(user)] took down the Cupids Crossbow note of [html_encode(post.character_name)] ([post.author_ckey]).")

#undef ROSEWALL_SAVE_FILE
#undef ROSEWALL_SAVE_VERSION
#undef ROSEWALL_MAX_POSTS
#undef ROSEWALL_MAX_POSTS_PER_PLAYER
#undef ROSEWALL_TEXT_MAX_LENGTH
#undef ROSEWALL_SEEKING_MAX_LENGTH
#undef ROSEWALL_NAME_MAX_LENGTH
#undef ROSEWALL_EXPIRY_DAYS
#undef ROSEWALL_ACTION_COOLDOWN
#undef ROSEWALL_DAY_LENGTH
