// Per-character beast profile: name, look, eyes, descriptors and genitals of the werewolf form.

/// Saved per character slot, since the beast is that character's curse.
/datum/preference/list_type/werewolf_customization
	savefile_key = "werewolf_customization"
	savefile_identifier = PREF_CHARACTER
	category = "werewolf"
	// Only the beast body reads this; the ordinary human spawn never applies it.
	should_apply = FALSE
	var/static/list/choice_fields = list(
		"look" = "Form", "pronouns" = "Pronouns",
		"build" = "Build", "fur" = "Fur", "muzzle" = "Muzzle",
		"penis" = "Penis", "penis_scale" = "Penis size",
		"breasts" = "Breasts", "vagina" = "Vagina",
	)

/datum/preferences
	var/werewolf_customization_prompt = FALSE

/client/verb/customize_werewolf()
	set name = "Werewolf Customization"
	set category = "Preferences"
	var/datum/preference/list_type/werewolf_customization/customization = GLOB.preference_entries[/datum/preference/list_type/werewolf_customization]
	customization?.handle_link(prefs, mob)

/// Eye glow a look uses when the profile picks none.
/proc/get_werewolf_default_eye_glow(look_id)
	return look_id == WEREWOLF_LOOK_FERAL ? WW_EYE_GLOW_FERAL : WW_EYE_GLOW_DEFAULT

/// Penis organ type for a profile penis choice; null for "absent" and "inherit".
/proc/get_werewolf_profile_penis_type(choice)
	var/static/list/penis_types = list(
		"knotted" = /obj/item/organ/genitals/penis/knotted,
		"barbed" = /obj/item/organ/genitals/penis/barbed_knotted,
	)
	return penis_types[choice]

/datum/preference/list_type/werewolf_customization/create_default_value(datum/preferences/prefs)
	return list(
		// A null name rolls a fresh one each round.
		"name" = null,
		"look" = WEREWOLF_LOOK_LEAN,
		"pronouns" = "inherit",
		// A null glow follows the chosen look's default.
		"eye_glow" = null,
		"build" = /datum/mob_descriptor/body/muscular,
		"fur" = /datum/mob_descriptor/fur/shaggy,
		"muzzle" = /datum/mob_descriptor/face/werewolf/long,
		"penis" = "inherit",
		"penis_scale" = WW_PENIS_SCALE_BASE,
		"breasts" = "inherit",
		"vagina" = "inherit",
	)

/// Label to stored value for a choice field, or null for any other field.
/datum/preference/list_type/werewolf_customization/proc/get_options(field)
	var/descriptor_root
	switch(field)
		if("look")
			var/list/looks = list()
			for(var/look_id in GLOB.werewolf_form_looks)
				var/datum/werewolf_form_look/look = GLOB.werewolf_form_looks[look_id]
				looks[look.name] = look_id
			return looks
		if("pronouns")
			return list("Same as my character" = "inherit", HE_HIM = HE_HIM, SHE_HER = SHE_HER, THEY_THEM = THEY_THEM, IT_ITS = IT_ITS)
		if("penis")
			return list("Same as my character" = "inherit", "Knotted" = "knotted", "Barbed, knotted" = "barbed", "None" = "absent")
		if("penis_scale")
			return list("Base" = WW_PENIS_SCALE_BASE, "+25%" = WW_PENIS_SCALE_LARGER, "+50%" = WW_PENIS_SCALE_HUGE)
		if("breasts")
			return list("Same as my character" = "inherit", "One size larger" = "bigger", "None" = "absent")
		if("vagina")
			return list("Same as my character" = "inherit", "Present" = "present", "None" = "absent")
		if("build")
			descriptor_root = /datum/mob_descriptor/body
		if("fur")
			descriptor_root = /datum/mob_descriptor/fur
		if("muzzle")
			descriptor_root = /datum/mob_descriptor/face/werewolf
	if(!descriptor_root)
		return null
	var/list/options = list()
	for(var/descriptor_type in subtypesof(descriptor_root))
		var/datum/mob_descriptor/descriptor = MOB_DESCRIPTOR(descriptor_type)
		// Beast profiles carry no player-written text.
		if(descriptor && !descriptor.custom_index)
			options[descriptor.name] = descriptor_type
	return options

/datum/preference/list_type/werewolf_customization/deserialize(list/input, datum/preferences/prefs)
	var/list/profile = create_default_value(prefs)
	if(!islist(input))
		return profile
	if(istext(input["name"]))
		profile["name"] = reject_bad_name(input["name"])
	var/glow = input["eye_glow"]
	if(istext(glow) && findtext(glow, GLOB.is_color))
		profile["eye_glow"] = sanitize_hexcolor(glow, 6, TRUE)
	for(var/field in choice_fields)
		var/list/options = get_options(field)
		for(var/label in options)
			if(options[label] == input[field])
				profile[field] = input[field]
				break
	return profile

/// The viewer's werewolf datum once a transformation has fixed its beast, else null.
/datum/preference/list_type/werewolf_customization/proc/get_locked_beast_antag(mob/user)
	RETURN_TYPE(/datum/antagonist/werewolf)
	var/datum/antagonist/werewolf/werewolf_antag = user?.mind?.has_antag_datum(/datum/antagonist/werewolf)
	return werewolf_antag?.beast_profile_locked ? werewolf_antag : null

/datum/preference/list_type/werewolf_customization/handle_link(datum/preferences/prefs, mob/user)
	if(!prefs || user?.client?.prefs != prefs)
		return
	// A fixed beast shows the shape it wears, not whatever the slot saves now.
	var/datum/antagonist/werewolf/locked_antag = get_locked_beast_antag(user)
	var/list/profile = locked_antag ? locked_antag.beast_profile : prefs.read_preference(type)
	var/character_name = html_encode(prefs.read_preference(/datum/preference/text/real_name))
	var/list/page = list("<h2>The Beast Within</h2>")
	if(locked_antag)
		page += "<p><b>The beast has taken its shape; it is set for this life.</b> Edits open again for this character's next life.</p>"
		page += "<b>Name:</b> [html_encode(locked_antag.get_beast_name())]<br>"
	else
		page += "<p>Saved with [character_name]. These choices shape your beast at its first transformation; after that it is set for that life.</p>"
		var/name_text = profile["name"] ? html_encode(profile["name"]) : "<i>random each round</i>"
		page += "<b>Name:</b> [name_text] <a href='byond://?src=[REF(src)];field=name'>Change</a> &middot; <a href='byond://?src=[REF(src)];field=random_name'>Randomize</a> &middot; <a href='byond://?src=[REF(src)];field=clear_name'>Random each round</a><br>"
	var/glow = profile["eye_glow"] || get_werewolf_default_eye_glow(profile["look"])
	page += "<b>Eye glow:</b> <span style='color:[glow]'>&#9679;</span> "
	if(locked_antag)
		page += profile["eye_glow"] ? "[glow]<br>" : "[glow] (form default)<br>"
	else
		page += "<a href='byond://?src=[REF(src)];field=eye_glow'>[glow]</a>"
		page += profile["eye_glow"] ? " &middot; <a href='byond://?src=[REF(src)];field=clear_eye_glow'>Use form default</a><br>" : " (form default)<br>"
	for(var/field in choice_fields)
		var/list/options = get_options(field)
		var/current_label
		for(var/label in options)
			if(options[label] == profile[field])
				current_label = label
				break
		var/label_text = html_encode(current_label)
		page += "<b>[choice_fields[field]]:</b> [locked_antag ? label_text : "<a href='byond://?src=[REF(src)];field=[field]'>[label_text]</a>"]<br>"
	page += "<p>Penis size scales the beast's base length, never below [WW_BEAST_MIN_PENIS_LENGTH] cm and never above [PENIS_LENGTH_MAX] cm.</p>"
	page += "<h3>Form previews</h3><table><tr>"
	for(var/look_id in GLOB.werewolf_form_looks)
		var/datum/werewolf_form_look/look = GLOB.werewolf_form_looks[look_id]
		var/icon/look_icon = icon(look.icon, look.get_body_state(MALE), SOUTH)
		page += "<td align='center'>[icon2html(look_icon, user.client)]<br>[look.name]</td>"
	page += "</tr></table><p>Your choices save with this character. Open this menu through Preferences &rarr; Werewolf Customization.</p>"
	var/datum/browser/popup = new(user, "werewolf_customization", "Werewolf Customization", 560, 640)
	popup.set_content(page.Join())
	popup.open()

/datum/preference/list_type/werewolf_customization/Topic(href, list/href_list)
	var/mob/user = usr
	var/datum/preferences/prefs = user?.client?.prefs
	if(!prefs || prefs.werewolf_customization_prompt)
		return
	if(get_locked_beast_antag(user))
		to_chat(user, span_warning(WW_BEAST_PROFILE_LOCKED_TEXT))
		handle_link(prefs, user)
		return
	var/field = href_list["field"]
	var/list/profile = prefs.read_preference(type)
	var/new_value
	var/changed = FALSE
	prefs.werewolf_customization_prompt = TRUE
	switch(field)
		if("random_name")
			field = "name"
			new_value = random_werewolf_name()
			changed = TRUE
		if("clear_name")
			field = "name"
			changed = TRUE
		if("clear_eye_glow")
			field = "eye_glow"
			changed = TRUE
		if("name")
			var/entered = browser_input_text(user, "Choose your beast's name.", "Werewolf Customization", profile["name"], MAX_NAME_LEN, encode = FALSE)
			new_value = reject_bad_name(entered)
			changed = !isnull(new_value)
			if(entered && !changed)
				to_chat(user, span_warning("That name will not do for a beast."))
		if("eye_glow")
			var/entered = input(user, "Choose your beast's eye glow.", "Werewolf Customization", profile["eye_glow"] || get_werewolf_default_eye_glow(profile["look"])) as color|null
			if(entered)
				new_value = sanitize_hexcolor(entered, 6, TRUE)
				changed = TRUE
		else
			if(field in choice_fields)
				var/list/options = get_options(field)
				var/chosen = browser_input_list(user, "Choose your beast's [LOWER_TEXT(choice_fields[field])].", "Werewolf Customization", options)
				if(chosen in options)
					new_value = options[chosen]
					changed = TRUE
	if(QDELETED(prefs))
		return
	prefs.werewolf_customization_prompt = FALSE
	if(user?.client?.prefs != prefs)
		return
	// The first transformation can land while a prompt is open.
	if(changed && get_locked_beast_antag(user))
		changed = FALSE
		to_chat(user, span_warning(WW_BEAST_PROFILE_LOCKED_TEXT))
	if(changed)
		profile = deepCopyList(prefs.read_preference(type))
		profile[field] = new_value
		prefs.write_preference(type, profile)
		prefs.save_character()
		var/datum/antagonist/werewolf/werewolf_antag = user.mind?.has_antag_datum(/datum/antagonist/werewolf)
		werewolf_antag?.reapply_beast_profile()
	handle_link(prefs, user)

/datum/antagonist/werewolf
	/// Validated beast profile, read at gain and refreshed by menu edits until the lock.
	var/list/beast_profile
	/// Name rolled at gain, used while the profile leaves the name blank.
	var/random_wolfname
	/// Whether gaining the curse opens the profile menu; lesser kin have no beast to shape.
	var/opens_beast_customization = TRUE
	/// Set by the first transformation; profile, look and name then stay fixed for this datum.
	var/beast_profile_locked = FALSE

/datum/antagonist/werewolf/lesser
	opens_beast_customization = FALSE

/mob/living/carbon/human/species/werewolf
	/// Genitals as apply_beast_anatomy built them; profile choices are deltas on this.
	var/list/beast_anatomy_baseline
	/// Anatomy choices last applied, so a repeat apply leaves the organs alone.
	var/applied_anatomy_key

/// Reads the saved profile at gain and opens the menu once for a connected player.
/datum/antagonist/werewolf/proc/load_beast_profile()
	read_beast_profile()
	if(opens_beast_customization && owner?.current?.client)
		addtimer(CALLBACK(src, PROC_REF(open_beast_customization)), WW_CUSTOMIZATION_OPEN_DELAY)

/// Validates [profile], else the owner's saved one, into the cache; keeps the cache when neither exists or locked.
/datum/antagonist/werewolf/proc/read_beast_profile(list/profile)
	if(beast_profile_locked)
		return
	if(isnull(profile))
		var/datum/preferences/owner_prefs = get_owner_prefs()
		profile = owner_prefs?.read_preference(/datum/preference/list_type/werewolf_customization)
		if(isnull(profile) && beast_profile)
			return
	var/datum/preference/list_type/werewolf_customization/customization = GLOB.preference_entries[/datum/preference/list_type/werewolf_customization]
	beast_profile = customization.deserialize(profile)
	form_look_id = beast_profile["look"]
	random_wolfname ||= wolfname
	// The howl reads wolfname, so it follows the profile name too.
	wolfname = beast_profile["name"] || random_wolfname

/datum/antagonist/werewolf/proc/get_owner_prefs()
	RETURN_TYPE(/datum/preferences)
	var/client/owner_client = owner?.current?.client
	if(owner_client)
		return owner_client.prefs
	if(owner?.key)
		return GLOB.preferences_datums[ckey(owner.key)]

/datum/antagonist/werewolf/proc/open_beast_customization()
	var/mob/body = owner?.current
	if(!body?.client?.prefs)
		return
	var/datum/preference/list_type/werewolf_customization/customization = GLOB.preference_entries[/datum/preference/list_type/werewolf_customization]
	customization.handle_link(body.client.prefs, body)

/// The beast's display name; the profile overrides the random wolfname.
/datum/antagonist/werewolf/proc/get_beast_name()
	return beast_profile?["name"] || wolfname

/// Applies the profile after apply_beast_anatomy, then locks it; an unlocked explicit [profile] replaces the cache first.
/datum/antagonist/werewolf/proc/apply_beast_profile(mob/living/carbon/human/human_user, mob/living/carbon/human/species/werewolf/new_werewolf, list/profile)
	if(QDELETED(new_werewolf))
		return FALSE
	if(profile || !beast_profile)
		read_beast_profile(profile)
	var/beast_name = get_beast_name()
	if(new_werewolf.real_name != beast_name)
		new_werewolf.real_name = beast_name
		new_werewolf.name = beast_name
	if(beast_profile["pronouns"] != "inherit")
		new_werewolf.pronouns = beast_profile["pronouns"]
	else if(human_user)
		new_werewolf.pronouns = human_user.pronouns
	new_werewolf.clear_mob_descriptors()
	new_werewolf.add_mob_descriptor(/datum/mob_descriptor/stature/werewolf)
	for(var/field in list("build", "fur", "muzzle"))
		new_werewolf.add_mob_descriptor(beast_profile[field])
	apply_profile_anatomy(new_werewolf)
	// Later changes this life reuse the cached profile and never read preferences again.
	beast_profile_locked = TRUE
	var/datum/species/werewolf/beast_species = new_werewolf.dna?.species
	if(!istype(beast_species))
		new_werewolf.regenerate_icons()
		return TRUE
	beast_species.eye_glow = beast_profile["eye_glow"]
	var/datum/werewolf_form_look/look = get_form_look()
	if(beast_species.get_form_look(new_werewolf) != look)
		beast_species.apply_form_look(new_werewolf, look)
	else
		new_werewolf.regenerate_icons()
	return TRUE

/// Re-reads the saved or given profile into the cache; refused once the first transformation locked it.
/datum/antagonist/werewolf/proc/reapply_beast_profile(list/profile)
	if(beast_profile_locked)
		to_chat(owner?.current, span_warning(WW_BEAST_PROFILE_LOCKED_TEXT))
		return FALSE
	read_beast_profile(profile)
	return TRUE

/// Moves the beast's genitals from the anatomy baseline to the profile's choices.
/datum/antagonist/werewolf/proc/apply_profile_anatomy(mob/living/carbon/human/species/werewolf/beast)
	if(!beast.beast_anatomy_baseline)
		beast.beast_anatomy_baseline = snapshot_werewolf_anatomy(beast)
	var/anatomy_key = "[beast_profile["penis"]]|[beast_profile["penis_scale"]]|[beast_profile["breasts"]]|[beast_profile["vagina"]]"
	if(beast.applied_anatomy_key == anatomy_key)
		return
	beast.applied_anatomy_key = anatomy_key
	var/list/baseline = beast.beast_anatomy_baseline

	var/penis_choice = beast_profile["penis"]
	var/penis_type = penis_choice == "inherit" ? baseline["penis_type"] : get_werewolf_profile_penis_type(penis_choice)
	if(penis_type)
		var/base_length = baseline["penis_type"] ? baseline["penis_length"] : WW_BEAST_MIN_PENIS_LENGTH
		// Scaling never shrinks the base and never passes the orifice length cap.
		var/length = max(base_length, min(round(base_length * beast_profile["penis_scale"] / 100, 1), PENIS_LENGTH_MAX))
		shape_beast_penis(beast, penis_type, length, max(nulltozero(baseline["penis_size"]), get_penis_visual_size(length)))
	else
		shape_beast_penis(beast, null)

	var/testicles_present = penis_choice == "inherit" ? !isnull(baseline["testicles"]) : !!penis_type
	shape_beast_filling_organ(beast, ORGAN_SLOT_TESTICLES, /obj/item/organ/genitals/filling_organ/testicles/internal, testicles_present, baseline["testicles"])

	var/breasts_size = baseline["breasts"]
	var/breasts_present = beast_profile["breasts"] != "absent" && !isnull(breasts_size)
	if(breasts_present && beast_profile["breasts"] == "bigger")
		breasts_size = max(breasts_size, min(breasts_size + 1, MAX_BREASTS_SIZE))
	shape_beast_filling_organ(beast, ORGAN_SLOT_BREASTS, /obj/item/organ/genitals/filling_organ/breasts, breasts_present, breasts_size)

	var/vagina_choice = beast_profile["vagina"]
	var/vagina_present = vagina_choice == "inherit" ? !isnull(baseline["vagina"]) : vagina_choice == "present"
	shape_beast_filling_organ(beast, ORGAN_SLOT_VAGINA, /obj/item/organ/genitals/filling_organ/vagina, vagina_present, baseline["vagina"])

/// Types and sizes of the beast's real genitals; null marks an absent organ.
/proc/snapshot_werewolf_anatomy(mob/living/carbon/human/beast)
	var/obj/item/organ/genitals/penis/penis = get_real_organ(beast, ORGAN_SLOT_PENIS)
	var/obj/item/organ/genitals/testicles = get_real_organ(beast, ORGAN_SLOT_TESTICLES)
	var/obj/item/organ/genitals/breasts = get_real_organ(beast, ORGAN_SLOT_BREASTS)
	var/obj/item/organ/genitals/vagina = get_real_organ(beast, ORGAN_SLOT_VAGINA)
	return list(
		"penis_type" = penis?.type,
		"penis_length" = penis?.get_length_cm(),
		"penis_size" = penis?.organ_size,
		"testicles" = testicles?.organ_size,
		"breasts" = breasts?.organ_size,
		"vagina" = vagina?.organ_size,
	)

/// Gives the beast a [penis_type] penis at [length] and [size]; a null type removes it.
/datum/antagonist/werewolf/proc/shape_beast_penis(mob/living/carbon/human/beast, penis_type, length, size)
	var/obj/item/organ/genitals/penis/penis = get_real_organ(beast, ORGAN_SLOT_PENIS)
	if(penis && penis.type != penis_type)
		remove_beast_organ(beast, penis)
		penis = null
	if(!penis_type)
		return
	var/fresh = !penis
	if(fresh)
		penis = new penis_type
	penis.length_cm = length
	penis.organ_size = size
	if(fresh)
		penis.Insert(beast, TRUE, FALSE)

/// Keeps, resizes, adds or removes the organ in [slot]; a null [size] keeps the organ's own size.
/datum/antagonist/werewolf/proc/shape_beast_filling_organ(mob/living/carbon/human/beast, slot, organ_type, present, size)
	var/obj/item/organ/genitals/filling_organ/organ = get_real_organ(beast, slot)
	if(!present)
		if(organ)
			remove_beast_organ(beast, organ)
		return
	if(!organ)
		organ = new organ_type
		if(!isnull(size))
			organ.organ_size = size
		organ.Insert(beast, TRUE, FALSE)
		return
	if(isnull(size) || organ.organ_size == size)
		return
	organ.organ_size = size
	organ.spill_excess_reagents()

/// Removes a beast organ; a vagina carrying a pregnancy stays, and the womb leaves with its vagina.
/datum/antagonist/werewolf/proc/remove_beast_organ(mob/living/carbon/human/beast, obj/item/organ/organ)
	if(organ.slot == ORGAN_SLOT_VAGINA)
		var/obj/item/organ/genitals/filling_organ/vagina/hole = organ
		var/obj/item/organ/genitals/filling_organ/womb/womb = beast.get_womb()
		if(beast.GetComponent(/datum/component/pregnancy) || organ.GetComponent(/datum/component/pregnancy) || (istype(hole) && hole.carries_pregnancy()) || womb?.carries_pregnancy())
			return FALSE
		if(womb)
			womb.Remove(beast)
			qdel(womb)
	organ.Remove(beast)
	qdel(organ)
	return TRUE
