/**
 * ## Hand-poked tattoo system
 *
 * Self-applied tattoos written by the player: either lettering ("ACAB") or a
 * described design (a wolf's head). Stored on the bodypart, shown on examine,
 * saved between rounds. Coal and paint leave temporary writing on the skin,
 * which water smudges and a damp rag or soap wipes off.
 *
 * Deliberately separate from GLOB.body_markings ("Markings" in the character
 * creator), which is premade sprite patterns rather than player-written text.
 *
 * Brands (iron, flame or magic) and lipstick or quill writing are media of
 * the same entry list. Defines live in _tattoo_defines.dm.
 */

/*
 * ZONE TABLE
 *
 * Tattoo zones are finer-grained than bodyparts: "forehead", "left thigh" and
 * "belly" all live on a bodypart that covers much more than themselves. Each
 * zone therefore declares:
 *   "name"    - display name, used in chat and examine
 *   "limb"    - which bodypart actually stores the entry
 *   "organ"   - optional ORGAN_SLOT_* that must exist for the zone to be valid
 *               (this is what stops you tattooing wings you don't have)
 *   "cover"   - which clothing check hides it, see is_tattoo_zone_visible()
 *
 * Ordered head -> feet: examine output walks this list in order, so the listing
 * always reads top-down regardless of what order tattoos were applied in.
 *
 * Intimate zones use the same preference checks for tattoos and body writing.
 */
GLOBAL_LIST_INIT(tattoo_zone_data, list(
	TATTOO_ZONE_FOREHEAD = list("name" = "forehead", "limb" = BODY_ZONE_HEAD, "cover" = BODY_ZONE_HEAD),
	TATTOO_ZONE_CHEEKS = list("name" = "cheeks", "limb" = BODY_ZONE_HEAD, "cover" = BODY_ZONE_HEAD),
	TATTOO_ZONE_CHIN = list("name" = "chin", "limb" = BODY_ZONE_HEAD, "cover" = BODY_ZONE_HEAD),
	TATTOO_ZONE_LIPS = list("name" = "lips", "limb" = BODY_ZONE_HEAD, "cover" = BODY_ZONE_PRECISE_MOUTH),
	BODY_ZONE_HEAD = list("name" = "head", "limb" = BODY_ZONE_HEAD, "cover" = BODY_ZONE_HEAD),
	TATTOO_ZONE_EARS = list("name" = "ears", "limb" = BODY_ZONE_HEAD, "organ" = ORGAN_SLOT_EARS, "cover" = BODY_ZONE_PRECISE_EARS),
	TATTOO_ZONE_HORNS = list("name" = "horns", "limb" = BODY_ZONE_HEAD, "organ" = ORGAN_SLOT_HORNS, "cover" = BODY_ZONE_PRECISE_SKULL),
	TATTOO_ZONE_NECK = list("name" = "neck", "limb" = BODY_ZONE_CHEST, "cover" = BODY_ZONE_PRECISE_NECK),
	BODY_ZONE_CHEST = list("name" = "torso", "limb" = BODY_ZONE_CHEST, "cover" = BODY_ZONE_CHEST),
	TATTOO_ZONE_BACK = list("name" = "back", "limb" = BODY_ZONE_CHEST, "cover" = BODY_ZONE_CHEST),
	TATTOO_ZONE_BREASTS = list("name" = "breasts", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_BREASTS, "customizer" = /datum/customizer_entry/organ/genitals/breasts, "cover" = BODY_ZONE_CHEST, "intimate" = TRUE),
	TATTOO_ZONE_BELLY = list("name" = "belly", "limb" = BODY_ZONE_CHEST, "cover" = BODY_ZONE_PRECISE_STOMACH),
	TATTOO_ZONE_WINGS = list("name" = "wings", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_WINGS, "cover" = BODY_ZONE_CHEST),
	BODY_ZONE_L_ARM = list("name" = "left arm", "limb" = BODY_ZONE_L_ARM, "cover" = BODY_ZONE_L_ARM),
	BODY_ZONE_R_ARM = list("name" = "right arm", "limb" = BODY_ZONE_R_ARM, "cover" = BODY_ZONE_R_ARM),
	BODY_ZONE_PRECISE_L_HAND = list("name" = "left hand", "limb" = BODY_ZONE_L_ARM, "cover" = BODY_ZONE_PRECISE_L_HAND),
	BODY_ZONE_PRECISE_R_HAND = list("name" = "right hand", "limb" = BODY_ZONE_R_ARM, "cover" = BODY_ZONE_PRECISE_R_HAND),
	TATTOO_ZONE_GROIN = list("name" = "groin", "limb" = BODY_ZONE_CHEST, "cover" = BODY_ZONE_PRECISE_GROIN, "intimate" = TRUE),
	TATTOO_ZONE_PENIS = list("name" = "cock", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_PENIS, "customizer" = /datum/customizer_entry/organ/genitals/penis, "cover" = BODY_ZONE_PRECISE_GROIN, "intimate" = TRUE),
	TATTOO_ZONE_VAGINA = list("name" = "cunt", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_VAGINA, "customizer" = /datum/customizer_entry/organ/genitals/vagina, "cover" = BODY_ZONE_PRECISE_GROIN, "intimate" = TRUE),
	TATTOO_ZONE_BUTTOCKS = list("name" = "buttocks", "limb" = BODY_ZONE_CHEST, "cover" = BODY_ZONE_PRECISE_GROIN, "intimate" = TRUE),
	TATTOO_ZONE_TAIL = list("name" = "tail", "limb" = BODY_ZONE_CHEST, "organ" = ORGAN_SLOT_TAIL, "cover" = BODY_ZONE_PRECISE_GROIN),
	BODY_ZONE_L_LEG = list("name" = "left leg", "limb" = BODY_ZONE_L_LEG, "cover" = BODY_ZONE_L_LEG),
	BODY_ZONE_R_LEG = list("name" = "right leg", "limb" = BODY_ZONE_R_LEG, "cover" = BODY_ZONE_R_LEG),
	TATTOO_ZONE_L_THIGH = list("name" = "left thigh", "limb" = BODY_ZONE_L_LEG, "cover" = BODY_ZONE_L_LEG),
	TATTOO_ZONE_R_THIGH = list("name" = "right thigh", "limb" = BODY_ZONE_R_LEG, "cover" = BODY_ZONE_R_LEG),
	TATTOO_ZONE_L_FOOT = list("name" = "left foot", "limb" = BODY_ZONE_L_LEG, "cover" = BODY_ZONE_PRECISE_L_FOOT),
	TATTOO_ZONE_R_FOOT = list("name" = "right foot", "limb" = BODY_ZONE_R_LEG, "cover" = BODY_ZONE_PRECISE_R_FOOT),
))

/// Maps a targeted body zone (the doll in the player's HUD) to the tattoo zones
/// that live on it, so picking "head" on the doll offers forehead/cheeks/etc.
GLOBAL_LIST_INIT(tattoo_zones_by_limb, build_tattoo_zones_by_limb())

/proc/build_tattoo_zones_by_limb()
	var/list/result = list()
	for(var/zone in GLOB.tattoo_zone_data)
		var/list/zone_data = GLOB.tattoo_zone_data[zone]
		var/limb = zone_data["limb"]
		if(!result[limb])
			result[limb] = list()
		result[limb] += zone
	return result

/// Natural pigments a tattoo needle can be inked with (name = hex colour).
/// Deliberately no modern inks - soot, ash, ochre clay, madder root and woad.
GLOBAL_LIST_INIT(tattoo_ink_colors, list(
	"Charcoal Black" = "#2B2B2B",
	"Soot Grey" = "#4A4A4A",
	"Ash Grey" = "#8A8A8A",
	"Ochre Brown" = "#7A4A2B",
	"Madder Red" = "#7C1F1F",
	"Woad Blue" = "#2B3F6E",
))

/// Glow colours an arcane brand can take (name = hex colour). Amber comes first as the default.
GLOBAL_LIST_INIT(arcane_brand_glows, list(
	"Amber" = ARCANE_BRAND_DEFAULT_GLOW,
	"Ember Orange" = "#ff6a1f",
	"Witchfire Green" = "#5dff7a",
	"Arcane Violet" = "#b46bff",
	"Frost Blue" = "#6fd3ff",
	"Blood Red" = "#ff3b3b",
	"Holy Gold" = "#ffe36b",
))

/// Display name for a tattoo zone.
/proc/tattoo_zone_name(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	return zone_data ? zone_data["name"] : zone

/// Which bodypart stores entries for this tattoo zone.
/proc/tattoo_zone_limb(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	return zone_data ? zone_data["limb"] : null

/// Is this an intimate zone? Tattooing someone else there needs their consent.
/proc/tattoo_zone_is_intimate(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	return zone_data ? !!zone_data["intimate"] : FALSE

/**
 * Pigment colour adjusted for chat legibility.
 *
 * Most players run a near-black chat background, where charcoal and soot are
 * effectively invisible. This lifts any pigment that is too dark to read
 * without changing its hue, so a "Charcoal Black" tattoo still reads as the
 * darkest of the greys rather than vanishing into the background.
 * The character sheet preview shows the true pigment on parchment instead.
 */
/proc/tattoo_chat_color(color)
	var/list/rgb_list = ReadRGB(color)
	if(!length(rgb_list))
		return "#d8cf9f"
	var/red = rgb_list[1]
	var/green = rgb_list[2]
	var/blue = rgb_list[3]
	// Rec. 601 luma, the usual cheap brightness approximation
	var/luma = (0.299 * red) + (0.587 * green) + (0.114 * blue)
	var/minimum_luma = 110
	if(luma >= minimum_luma)
		return color
	// Pure black has no hue to preserve, so give it a legible warm grey
	if(luma <= 1)
		return "#9a9a9a"
	var/scale = minimum_luma / luma
	red = min(255, round(red * scale))
	green = min(255, round(green * scale))
	blue = min(255, round(blue * scale))
	return rgb(red, green, blue)

/*
 * BODYPART STORAGE
 *
 * Each entry is an assoc list:
 *   list("zone" = BODY_ZONE_*, "text" = "...", "style" = TATTOO_STYLE_*, "color" = "#hex", "medium" = TATTOO_MEDIUM_*, "state" = TATTOO_STATE_*)
 * The entry carries its own zone because precise zones (hands) are NOT separate
 * bodyparts - BODY_ZONE_PRECISE_L_HAND is a subtarget of the arm - so one
 * bodypart can hold entries for several tattoo zones at once.
 * Plain nested lists (not a datum) because savefiles serialize them natively.
 */

/obj/item/bodypart
	/// List of tattoo entries on this bodypart. See the header above for the format.
	var/list/tattoos

/// Returns a deep copy of a tattoo entry, so mutating the copy never touches the original.
/proc/copy_tattoo_entry(list/entry)
	return list(
		"zone" = entry["zone"],
		"text" = entry["text"],
		"style" = entry["style"],
		"color" = entry["color"],
		"medium" = entry["medium"],
		"state" = entry["state"],
	)

/// Is this a washable mark on top of the skin?
/proc/is_surface_body_mark(medium)
	return medium == TATTOO_MEDIUM_CHARCOAL || medium == TATTOO_MEDIUM_PAINT || medium == TATTOO_MEDIUM_LIPSTICK || medium == TATTOO_MEDIUM_QUILL

/// Is this a burned brand, plain or arcane?
/proc/is_brand_mark(medium)
	return medium == TATTOO_MEDIUM_BRAND || medium == TATTOO_MEDIUM_ARCANE

/proc/is_known_skin_medium(medium)
	return medium == TATTOO_MEDIUM_INK || is_brand_mark(medium) || is_surface_body_mark(medium)

/// What a surface mark is written in, for examine text.
/proc/surface_mark_material(medium)
	switch(medium)
		if(TATTOO_MEDIUM_PAINT)
			return "paint"
		if(TATTOO_MEDIUM_LIPSTICK)
			return "lipstick"
		if(TATTOO_MEDIUM_QUILL)
			return "ink"
	return "charcoal"

/// Offered hex from a name = hex list, matched case-insensitively, or null.
/proc/skin_mark_offered_color(list/offered, color)
	if(!istext(color))
		return null
	for(var/offered_name in offered)
		if(cmptext(offered[offered_name], color))
			return offered[offered_name]
	return null

/// Display name of an arcane glow colour.
/proc/arcane_glow_name(color)
	for(var/glow_name in GLOB.arcane_brand_glows)
		if(cmptext(GLOB.arcane_brand_glows[glow_name], color))
			return glow_name
	return "Amber"

/// Lipstick shades as name = hex, the same shades the lipstick items use.
/proc/lipstick_skin_shades()
	var/static/list/shades
	if(!shades)
		shades = list()
		for(var/hex in GLOB.lipstick_shades)
			var/shade_name = capitalize(GLOB.lipstick_shades[hex])
			if(shades[shade_name])
				shade_name = "Deep [shade_name]"
			shades[shade_name] = hex
	return shades

/// The only colours a medium may carry; anything else falls back to that medium's default.
/proc/sanitize_skin_mark_color(medium, color)
	switch(medium)
		if(TATTOO_MEDIUM_CHARCOAL)
			return TATTOO_CHARCOAL_COLOR
		if(TATTOO_MEDIUM_QUILL)
			return TATTOO_QUILL_COLOR
		if(TATTOO_MEDIUM_BRAND)
			return TATTOO_BRAND_COLOR
		if(TATTOO_MEDIUM_ARCANE)
			return skin_mark_offered_color(GLOB.arcane_brand_glows, color) || ARCANE_BRAND_DEFAULT_GLOW
		if(TATTOO_MEDIUM_LIPSTICK)
			var/list/shades = lipstick_skin_shades()
			return skin_mark_offered_color(shades, color) || shades[shades[1]]
	return sanitize_hexcolor(color, 6, TRUE, TATTOO_CHARCOAL_COLOR)

/// How many permanent tattoos this bodypart holds for one specific zone.
/obj/item/bodypart/proc/count_tattoos_on_zone(zone)
	. = 0
	for(var/list/entry in tattoos)
		if(entry["zone"] == zone && entry["medium"] == TATTOO_MEDIUM_INK)
			.++

/// How many brands, plain or arcane, this bodypart holds for one zone.
/obj/item/bodypart/proc/count_brands_on_zone(zone)
	. = 0
	for(var/list/entry in tattoos)
		if(entry["zone"] == zone && is_brand_mark(entry["medium"]))
			.++

/// Adds a tattoo or brand, or replaces the temporary inscription at this spot.
/obj/item/bodypart/proc/add_tattoo(zone, text, style, color, medium = TATTOO_MEDIUM_INK)
	LAZYINITLIST(tattoos)
	if(medium == TATTOO_MEDIUM_INK && count_tattoos_on_zone(zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		return FALSE
	if(is_brand_mark(medium) && count_brands_on_zone(zone) >= MAXIMUM_BRANDS_PER_ZONE)
		return FALSE
	if(is_surface_body_mark(medium))
		for(var/list/entry in tattoos.Copy())
			if(entry["zone"] == zone && is_surface_body_mark(entry["medium"]))
				tattoos -= list(entry)
	tattoos += list(list(
		"zone" = zone,
		"text" = text,
		"style" = style,
		"color" = color,
		"medium" = medium,
		"state" = TATTOO_STATE_FRESH,
	))
	return TRUE

/*
 * VISIBILITY AND EXAMINE OUTPUT
 *
 * Coverage is checked per zone using the outer layer that would hide it.
 * This intentionally does not use the full flags_inv/HIDE* occlusion system
 * clothing uses for sprites - it is good enough for "can an onlooker read this
 * tattoo" and is cheap to run.
 */

/**
 * Is the skin at this tattoo zone actually exposed?
 *
 * Delegates to the codebase's own coverage check rather than testing single
 * slots: a dress or robe covers the groin and legs from the shirt slot, and
 * "is wear_pants empty" would call those tattoos visible. skipundies is FALSE
 * so smallclothes count as cover for the intimate zones.
 */
/mob/living/carbon/human/proc/is_tattoo_zone_visible(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(!zone_data)
		return FALSE
	var/cover_zone = zone_data["cover"]
	if(!cover_zone)
		return TRUE
	return get_location_accessible(src, cover_zone, grabs = FALSE, skipundies = FALSE)

/// Does this character have the body part a zone needs? Wings zones need wings.
/mob/living/carbon/human/proc/has_tattoo_zone(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(!zone_data)
		return FALSE
	if(!get_bodypart(zone_data["limb"]))
		return FALSE
	var/needed_organ = zone_data["organ"]
	if(needed_organ && !getorganslot(needed_organ))
		return FALSE
	return TRUE

/// Display name of the pigment a tattoo was inked with, matched back from its hex.
/proc/tattoo_pigment_name(color)
	// Loaded colours are lowercased by validate_tattoos(), so the match ignores case.
	for(var/pigment_name in GLOB.tattoo_ink_colors)
		if(cmptext(GLOB.tattoo_ink_colors[pigment_name], color))
			return pigment_name
	return "unknown pigment"

/// Hover text naming what a mark is made of.
/proc/tattoo_mark_tooltip(list/entry)
	switch(entry["medium"])
		if(TATTOO_MEDIUM_PAINT)
			return "Paint ([entry["color"]])"
		if(TATTOO_MEDIUM_LIPSTICK)
			var/shade = LAZYACCESS(GLOB.lipstick_shades, LOWER_TEXT(entry["color"]))
			return shade ? "[capitalize(shade)] lipstick" : "Lipstick"
		if(TATTOO_MEDIUM_QUILL)
			return "Quill ink"
		if(TATTOO_MEDIUM_CHARCOAL)
			return "Charcoal"
		if(TATTOO_MEDIUM_BRAND)
			return "Burned scar"
		if(TATTOO_MEDIUM_ARCANE)
			return "[arcane_glow_name(entry["color"])] glow"
	return tattoo_pigment_name(entry["color"])

/**
 * The mark itself, as it appears in chat.
 *
 * Dotted underline marks it as the inked part of the sentence, and hovering it
 * names the material. Arcane brands glow instead. Quotes for lettering sit
 * outside the span: they are punctuation, not ink.
 */
/proc/format_tattoo_entry_text(list/entry)
	var/is_design = entry["style"] == TATTOO_STYLE_DESIGN
	var/text_style
	if(entry["medium"] == TATTOO_MEDIUM_ARCANE)
		var/glow = entry["color"]
		text_style = "color: [glow]; text-shadow: 0 0 3px [glow], 0 0 7px [glow];"
	else
		text_style = "color: [tattoo_chat_color(entry["color"])]; text-decoration: underline dotted;"
	var/inner = "<span style='[text_style]' title='[tattoo_mark_tooltip(entry)]'>[entry["text"]]</span>"
	return is_design ? inner : "\"[inner]\""

/// One Look at Features line for a mark on a zone.
/proc/tattoo_description_line(list/entry, zone)
	var/zone_name = tattoo_zone_name(zone)
	var/mark_text = format_tattoo_entry_text(entry)
	var/medium = entry["medium"]
	var/faded = entry["state"] == TATTOO_STATE_FADED
	switch(medium)
		if(TATTOO_MEDIUM_BRAND)
			return "On the [zone_name], burned into the skin: [mark_text]"
		if(TATTOO_MEDIUM_ARCANE)
			return "On the [zone_name], a sigil glows [LOWER_TEXT(arcane_glow_name(entry["color"]))]: [mark_text]"
	if(is_surface_body_mark(medium))
		return "On the [zone_name], written in [surface_mark_material(medium)]: [mark_text][faded ? " (smudged)" : ""]"
	var/faded_note = faded ? " (faded)" : ""
	if(entry["style"] == TATTOO_STYLE_DESIGN)
		return "On the [zone_name] [mark_text][faded_note]"
	return "On the [zone_name] is written: [mark_text][faded_note]"

/**
 * Builds the mark lines shown at the end of the Look at Features text.
 *
 * Walks GLOB.tattoo_zone_data in declaration order, which runs head -> feet,
 * so the listing always reads top-down. Zones hidden by clothing are skipped.
 */
/mob/living/carbon/human/proc/get_tattoo_description_lines()
	var/list/lines = list()
	for(var/zone in GLOB.tattoo_zone_data)
		var/obj/item/bodypart/BP = get_bodypart(tattoo_zone_limb(zone))
		if(!BP || !length(BP.tattoos))
			continue
		if(!is_tattoo_zone_visible(zone))
			continue
		for(var/list/entry as anything in BP.tattoos)
			if(entry["zone"] == zone)
				lines += tattoo_description_line(entry, zone)
	return lines

/*
 * PERSISTENCE
 *
 * prefs.tattoos[zone] = list(entry, entry, ...)
 */

/datum/preferences
	/// Saved tattoos, keyed by body zone. See the bodypart storage header for the entry format.
	var/list/tattoos = list()

/// Hard validation of everything loaded from the savefile: unknown zones,
/// malformed entries, oversized text, bad colours, out-of-range enums and
/// over-cap zones are all dropped or clamped.
/datum/preferences/proc/validate_tattoos()
	if(!islist(tattoos))
		tattoos = list()
		return
	var/static/list/valid_styles = list(TATTOO_STYLE_LETTERING, TATTOO_STYLE_DESIGN)
	for(var/zone in tattoos.Copy())
		if(!(zone in GLOB.tattoo_zone_data))
			tattoos -= zone
			continue
		var/list/entries = tattoos[zone]
		if(!islist(entries))
			tattoos -= zone
			continue
		var/ink_count = 0
		var/brand_count = 0
		var/surface_count = 0
		for(var/list/entry in entries.Copy())
			if(!islist(entry) || !istext(entry["text"]) || !length(entry["text"]))
				// list(entry), not entry: subtracting a bare list removes its
				// *contents* from the target rather than the nested entry itself
				entries -= list(entry)
				continue
			// Anything saved before media existed is needle work.
			var/medium = is_known_skin_medium(entry["medium"]) ? entry["medium"] : TATTOO_MEDIUM_INK
			var/max_length = TATTOO_TEXT_MAX_LENGTH
			var/over_cap
			if(is_brand_mark(medium))
				max_length = BRAND_TEXT_MAX_LENGTH
				over_cap = ++brand_count > MAXIMUM_BRANDS_PER_ZONE
			else if(is_surface_body_mark(medium))
				over_cap = ++surface_count > 1
			else
				over_cap = ++ink_count > MAXIMUM_TATTOOS_PER_ZONE
			if(over_cap)
				entries -= list(entry)
				continue
			entry["zone"] = zone
			entry["medium"] = medium
			entry["text"] = copytext(entry["text"], 1, max_length * 2) // *2: html entities from encoding inflate length
			entry["color"] = sanitize_skin_mark_color(medium, entry["color"])
			if(!(entry["style"] in valid_styles))
				entry["style"] = TATTOO_STYLE_DESIGN
			// Writing from the editor goes on fresh every round.
			if(is_surface_body_mark(medium) || (entry["state"] != TATTOO_STATE_FRESH && entry["state"] != TATTOO_STATE_FADED))
				entry["state"] = TATTOO_STATE_FRESH
		if(!length(entries))
			tattoos -= zone

/// Turns a saved Branded quirk (zone + text) into a saved brand entry.
/datum/preferences/proc/migrate_branded_quirk_save(savefile/S, quirk_zone, list/extra)
	var/static/list/quirk_zone_to_mark_zone = list(
		BODY_ZONE_PRECISE_SKULL = TATTOO_ZONE_FOREHEAD,
		BODY_ZONE_PRECISE_NECK = TATTOO_ZONE_NECK,
		BODY_ZONE_PRECISE_STOMACH = TATTOO_ZONE_BELLY,
		BODY_ZONE_PRECISE_GROIN = TATTOO_ZONE_GROIN,
	)
	var/zone = quirk_zone_to_mark_zone[quirk_zone] || quirk_zone
	if(!(zone in GLOB.tattoo_zone_data))
		zone = BODY_ZONE_CHEST
	var/brand_text = islist(extra) ? extra["brand_text"] : null
	if(!istext(brand_text) || !length(trimtext(brand_text)))
		brand_text = "X"
	brand_text = uppertext(sanitize(copytext_char(trimtext(html_decode(brand_text)), 1, 11)))

	var/list/saved
	S["tattoos"] >> saved
	if(!islist(saved))
		saved = list()
	var/list/entries = saved[zone]
	if(!islist(entries))
		entries = list()
		saved[zone] = entries
	for(var/list/entry in entries)
		if(islist(entry) && is_brand_mark(entry["medium"]))
			return
	entries += list(list(
		"zone" = zone,
		"text" = brand_text,
		"style" = TATTOO_STYLE_LETTERING,
		"color" = TATTOO_BRAND_COLOR,
		"medium" = TATTOO_MEDIUM_BRAND,
		"state" = TATTOO_STATE_FRESH,
	))
	WRITE_FILE(S["tattoos"], saved)

/// Copies the saved tattoos onto a freshly spawned human. Call from apply_prefs_to()
/// AFTER set_species()/bodypart setup, or the new bodyparts will wipe them.
/datum/preferences/proc/apply_tattoos_to_human(mob/living/carbon/human/character)
	if(!ishuman(character))
		return
	// Remember which slot this body came from - see save_tattoos_now()
	character.tattoo_savefile_slot = default_slot
	for(var/zone in tattoos)
		// Tattoo zones are finer-grained than bodyparts ("lips" lives on the
		// head), so resolve the owning limb rather than looking the zone up
		// as a bodypart - get_bodypart("tattoo_lips") is always null.
		var/limb_zone = tattoo_zone_limb(zone)
		if(!limb_zone)
			continue
		var/obj/item/bodypart/BP = character.get_bodypart(limb_zone)
		if(!BP)
			continue
		LAZYINITLIST(BP.tattoos)
		for(var/list/entry in tattoos[zone])
			var/list/copied = copy_tattoo_entry(entry)
			copied["zone"] = zone // savefiles from before zones were stored per-entry
			BP.tattoos += list(copied)

/// Savefile slot this body's tattoos belong to, so in-round changes can never
/// be written into whichever character the player has selected in the editor.
/mob/living/carbon/human
	var/tattoo_savefile_slot = 0

/**
 * Persists the ink tattoos currently on this body back to the savefile.
 *
 * Only ink is written. Saved brands and writing come from the editor and stay
 * as saved; marks made in the round last the round. Writes just our own key,
 * into the slot this body came from, never via save_character().
 */
/mob/living/carbon/human/proc/save_tattoos_now()
	var/datum/preferences/prefs = client?.prefs
	if(!prefs?.path || !tattoo_savefile_slot)
		return FALSE

	var/list/body_ink = list()
	for(var/obj/item/bodypart/BP as anything in bodyparts)
		for(var/list/entry in BP.tattoos)
			if(entry["medium"] != TATTOO_MEDIUM_INK)
				continue
			var/zone = entry["zone"]
			if(!(zone in GLOB.tattoo_zone_data))
				continue
			if(!body_ink[zone])
				body_ink[zone] = list()
			body_ink[zone] += list(copy_tattoo_entry(entry))

	var/savefile/save_file = new /savefile(prefs.path)
	if(!save_file)
		return FALSE
	save_file.cd = "/character[tattoo_savefile_slot]"
	var/list/saved
	save_file["tattoos"] >> saved
	WRITE_FILE(save_file["tattoos"], merge_saved_ink(saved, body_ink))

	// Only touch the in-memory copy when the editor is sitting on this same
	// character, or we would show one character's tattoos while editing another.
	if(prefs.default_slot == tattoo_savefile_slot)
		prefs.tattoos = merge_saved_ink(prefs.tattoos, body_ink)
	return TRUE

/// Saved marks with every ink entry replaced by the body's ink. Brands and writing stay as saved.
/proc/merge_saved_ink(list/saved, list/body_ink)
	var/list/merged = list()
	for(var/zone in GLOB.tattoo_zone_data)
		var/list/zone_entries = list()
		var/list/saved_entries = islist(saved) ? saved[zone] : null
		if(islist(saved_entries))
			for(var/list/entry in saved_entries)
				if(islist(entry) && is_known_skin_medium(entry["medium"]) && entry["medium"] != TATTOO_MEDIUM_INK)
					zone_entries += list(copy_tattoo_entry(entry))
		for(var/list/entry in body_ink[zone])
			zone_entries += list(entry)
		if(length(zone_entries))
			merged[zone] = zone_entries
	return merged

/*
 * WASHING
 *
 * Plain washing smudges exposed surface writing. Scrubbing removes it in one
 * pass, whether fresh or smudged. Permanent tattoos are unaffected.
 */

/mob/living/carbon/human/proc/process_tattoo_wash(clean_types)
	if(!(clean_types & CLEAN_WASH))
		return FALSE
	var/is_scrub = clean_types & (CLEAN_TYPE_FINGERPRINTS | CLEAN_TYPE_FIBERS)
	var/faded_any = FALSE
	var/removed_any = FALSE

	for(var/obj/item/bodypart/BP as anything in bodyparts)
		if(!length(BP.tattoos))
			continue
		for(var/list/entry in BP.tattoos.Copy())
			if(!is_surface_body_mark(entry["medium"]))
				continue
			if(!has_tattoo_zone(entry["zone"]) || !is_tattoo_zone_visible(entry["zone"]))
				continue
			if(is_scrub)
				BP.tattoos -= list(entry)
				removed_any = TRUE
			else if(entry["state"] == TATTOO_STATE_FRESH)
				entry["state"] = TATTOO_STATE_FADED
				faded_any = TRUE

	if(!faded_any && !removed_any)
		return FALSE

	if(removed_any)
		to_chat(src, span_notice("The writing scrubs off your skin."))
	else
		to_chat(src, span_notice("The writing on your skin smudges and runs."))
	return TRUE

/*
 * THE NEEDLE
 *
 * Applied by clicking a person with the needle in hand - yourself or someone
 * else. The spot comes from the body zone targeted on the HUD doll, exactly
 * like every other targeted interaction. If a limb hosts several tattoo spots
 * (the head has forehead, cheeks, chin and so on) a short list asks which.
 *
 * Tattooing someone else takes longer and needs them to hold still - walking
 * away cancels it, which is the consent mechanic for ordinary spots. Intimate
 * spots additionally require the target to have enabled the matching ERP
 * preference, so nobody gets written on where they didn't agree to.
 */

/datum/erp_preference/boolean/allow_intimate_tattoos
	name = "Intimate Tattoos"
	description = "Whether others may tattoo your intimate areas (breasts, groin, buttocks, genitals)"
	default_value = FALSE
	category = "General"

/obj/item/tattoo_machine
	name = "tattoo machine"
	desc = "A bronze-framed contraption with a needle driven by a treadle spring, fed from a sealed alchemical vial. It drives pigment under the skin far more evenly than a hand-held needle ever could."
	icon = 'modular_rmh/icons/obj/items/tattoomachine.dmi'
	icon_state = "tattoo_machine"
	item_weight = 1.2 KILOGRAMS
	w_class = WEIGHT_CLASS_SMALL
	force = 0
	throwforce = 0
	item_flags = NOBLUDGEON
	max_integrity = 100
	grid_width = 32
	grid_height = 32

	/// Hex colour of the pigment currently loaded in the inkwell
	var/ink_color = "#2B2B2B"
	/// Display name of the current pigment
	var/ink_style = "Charcoal Black"

/obj/item/tattoo_machine/examine(mob/user)
	. = ..()
	. += span_notice("The inkwell holds [ink_style] pigment.")
	. += span_notice("Alt-click to swap the pigment.")
	. += span_info("Target a body zone, then click yourself to tattoo it. To tattoo someone else, grab them first and keep hold.")
	. += span_warning("Ink driven by this sits under the skin: washing does nothing, and only a surgeon's blade takes it off. For something temporary, draw with a lump of charcoal instead.")

/obj/item/tattoo_machine/AltClick(mob/user, list/modifiers)
	. = ..()
	if(!user.can_perform_action(src, NEED_DEXTERITY))
		return
	var/choice = input(user, "Choose a pigment to load:", "Tattoo Pigment") as null|anything in GLOB.tattoo_ink_colors
	if(!choice || !user.can_perform_action(src, NEED_DEXTERITY))
		return
	ink_color = GLOB.tattoo_ink_colors[choice]
	ink_style = choice
	to_chat(user, span_notice("You load [src] with [ink_style] pigment."))

/// Clicking a person - self or otherwise - is the way tattoos get applied.
/obj/item/tattoo_machine/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!ishuman(target) || !ishuman(user))
		return ..()
	try_tattoo(target, user, TATTOO_MEDIUM_INK, ink_color)
	return TRUE

/// Using it in hand tattoos yourself, as a convenience for the common case.
/obj/item/tattoo_machine/attack_self(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		to_chat(user, span_warning("You don't have the right kind of skin for this!"))
		return
	try_tattoo(user, user, TATTOO_MEDIUM_INK, ink_color)

/**
 * Shared application flow for anything that puts marks on skin.
 *
 * medium decides permanence: TATTOO_MEDIUM_INK survives washing and needs
 * surgery; charcoal and paint smudge in water and wipe off again.
 */
/obj/item/proc/try_tattoo(mob/living/carbon/human/patient, mob/living/carbon/human/artist, medium = TATTOO_MEDIUM_INK, mark_color = TATTOO_CHARCOAL_COLOR)
	if(!istype(patient) || !istype(artist))
		return
	if(QDELETED(src) || !artist.is_holding(src) || !artist.can_perform_action(src, NEED_DEXTERITY))
		return

	var/is_self = (patient == artist)
	var/is_surface = is_surface_body_mark(medium)

	if(!is_self && !tattoo_has_grab_on(artist, patient))
		to_chat(artist, span_warning("I need to grab [patient] and hold them still first."))
		return

	var/selected_zone = pick_tattoo_zone_for_target(patient, artist, is_self)
	if(!selected_zone || QDELETED(patient) || QDELETED(artist) || QDELETED(src))
		return

	var/zone_name = tattoo_zone_name(selected_zone)
	var/obj/item/bodypart/BP = patient.get_bodypart(tattoo_zone_limb(selected_zone))
	if(!BP)
		to_chat(artist, span_warning("[is_self ? "You don't" : "[patient] doesn't"] have that body part!"))
		return

	if(!patient.is_tattoo_zone_visible(selected_zone))
		to_chat(artist, span_warning("[is_self ? "Your" : "[patient]'s"] clothes are in the way there!"))
		return

	if(!is_surface && BP.count_tattoos_on_zone(selected_zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		to_chat(artist, span_warning("There's no room left on [is_self ? "your" : "[patient]'s"] [zone_name] for another mark!"))
		return

	var/mark_word = is_surface ? "writing" : "tattoo"
	var/prompt = is_surface ? "What do you want to write" : "Describe the tattoo"

	var/tattoo_text = tgui_input_text(artist, "[prompt] (max [TATTOO_TEXT_MAX_LENGTH] characters)?", "[capitalize(mark_word)] - [zone_name]", max_length = TATTOO_TEXT_MAX_LENGTH, encode = FALSE)
	if(!tattoo_text || QDELETED(artist) || QDELETED(src))
		return
	tattoo_text = html_encode(trimtext(copytext_char(tattoo_text, 1, TATTOO_TEXT_MAX_LENGTH + 1)))
	if(!length(tattoo_text))
		return

	var/style_choice = "Lettering"
	if(!is_surface)
		style_choice = tgui_alert(artist, "Is this lettering (shown in quotes, e.g. \"ACAB\") or a design (shown plain, e.g. a wolf's head)?", "Tattoo Style", list("Lettering", "Design"))
		if(!style_choice || QDELETED(artist) || QDELETED(src))
			return

	// Input stalling: the prompts above can be held open indefinitely, so
	// re-validate everything that could have changed meanwhile. do_after()
	// only notices movement that happens after it starts, so the reach and
	// clothing checks have to be repeated here rather than trusted from above.
	if(QDELETED(BP) || BP.owner != patient || QDELETED(patient))
		return
	if(!still_in_reach(patient, artist, selected_zone, is_self))
		return
	if(!can_use_tattoo_zone(patient, artist, selected_zone, is_self))
		return
	if(!is_surface && BP.count_tattoos_on_zone(selected_zone) >= MAXIMUM_TATTOOS_PER_ZONE)
		to_chat(artist, span_warning("There's no room left on [is_self ? "your" : "[patient]'s"] [zone_name] for another mark!"))
		return

	// Surface writing is quick and painless.
	var/tattoo_time
	if(is_surface)
		tattoo_time = is_self ? 3 SECONDS : 5 SECONDS
	else
		tattoo_time = is_self ? 8 SECONDS : 12 SECONDS

	var/verb_phrase = is_surface ? "writing on" : "poking a tattoo into"

	if(is_self)
		to_chat(artist, span_notice("You begin [verb_phrase] your [zone_name]..."))
	else
		artist.visible_message(
			span_notice("[artist] begins [verb_phrase] [patient]'s [zone_name]..."),
			span_notice("You begin [verb_phrase] [patient]'s [zone_name]..."),
		)
		to_chat(patient, span_warning("[artist] begins [verb_phrase] your [zone_name]!"))

	if(!is_surface)
		patient.adjust_jitter(10 SECONDS)
		artist.add_movespeed_modifier(MOVESPEED_ID_TATTOO_PAIN, multiplicative_slowdown = 0.3)

	var/success = do_after(artist, tattoo_time, patient, interaction_key = "tattoo_marking")

	if(!is_surface && !QDELETED(artist))
		artist.remove_movespeed_modifier(MOVESPEED_ID_TATTOO_PAIN)

	if(QDELETED(artist))
		return
	if(!success || QDELETED(patient) || QDELETED(src))
		to_chat(artist, span_warning("You stop before finishing the [mark_word]."))
		return

	// The limb may have been lost or swapped during the do_after
	if(QDELETED(BP) || BP.owner != patient)
		to_chat(artist, span_warning("You stop before finishing the [mark_word]."))
		return

	// ...and the tool may have been moved into the very arm being worked on
	if(is_self && get_wielding_arm(artist) == tattoo_zone_limb(selected_zone))
		to_chat(artist, span_warning("You can't work on the very arm that's holding [src]."))
		return

	if(!still_in_reach(patient, artist, selected_zone, is_self))
		return
	if(!can_use_tattoo_zone(patient, artist, selected_zone, is_self))
		return

	if(medium == TATTOO_MEDIUM_PAINT)
		var/obj/item/paint_brush/brush = src
		if(brush.current_color != mark_color)
			to_chat(artist, span_warning("The paint on the brush has changed. I need to start again."))
			return

	if(!BP.add_tattoo(selected_zone, tattoo_text, (style_choice == "Lettering") ? TATTOO_STYLE_LETTERING : TATTOO_STYLE_DESIGN, mark_color, medium))
		to_chat(artist, span_warning("There's no room left on [is_self ? "your" : "[patient]'s"] [zone_name] for another [mark_word]!"))
		return

	var/finish_phrase = is_surface ? "the writing on" : "the tattoo on"
	if(is_self)
		to_chat(artist, span_notice("You finish [finish_phrase] your [zone_name]."))
	else
		artist.visible_message(
			span_notice("[artist] finishes [finish_phrase] [patient]'s [zone_name]."),
			span_notice("You finish [finish_phrase] [patient]'s [zone_name]."),
		)

	if(!is_surface)
		patient.apply_damage(2, BRUTE, tattoo_zone_limb(selected_zone))
		patient.save_tattoos_now()

/**
 * Is the artist holding the patient in a grab?
 *
 * Working on someone else needs a free hand on them - it keeps a lump of
 * charcoal from being scrawled across strangers in passing, and means the
 * subject of a real tattoo has to be held (or willingly let themselves be).
 */
/proc/tattoo_has_grab_on(mob/living/carbon/human/artist, mob/living/carbon/human/patient)
	for(var/obj/item/grabbing/grab in artist.held_items)
		if(grab.grabbed == patient)
			return TRUE
	return FALSE

/**
 * Is the patient still close enough, still held, and is the spot still bare?
 * Called before do_after() and again before the tattoo lands.
 */
/obj/item/proc/still_in_reach(mob/living/carbon/human/patient, mob/living/carbon/human/artist, zone, is_self)
	if(QDELETED(src) || QDELETED(patient) || QDELETED(artist) || !artist.is_holding(src))
		return FALSE
	if(!is_self)
		if(!artist.Adjacent(patient))
			to_chat(artist, span_warning("[patient] is too far away."))
			return FALSE
		if(!tattoo_has_grab_on(artist, patient))
			to_chat(artist, span_warning("I need to keep a hold of [patient] to work on them."))
			return FALSE
	if(!artist.can_perform_action(src, NEED_DEXTERITY))
		return FALSE
	if(!patient.is_tattoo_zone_visible(zone))
		to_chat(artist, span_warning("[is_self ? "Your" : "[patient]'s"] clothes are in the way there!"))
		return FALSE
	return TRUE

/**
 * Shared gate for a zone: does the body part exist, and is the artist allowed
 * to work there? Intimate spots on someone else need that person's consent.
 */
/obj/item/proc/can_use_tattoo_zone(mob/living/carbon/human/patient, mob/living/carbon/human/artist, zone, is_self, quiet = FALSE)
	if(!patient.has_tattoo_zone(zone))
		return FALSE
	if(is_self || !tattoo_zone_is_intimate(zone))
		return TRUE
	if(patient.get_erp_pref(/datum/erp_preference/boolean/allow_intimate_tattoos))
		return TRUE
	if(!quiet)
		to_chat(artist, span_warning("[patient] isn't willing to have that area marked or cleaned."))
	return FALSE

/**
 * Which arm is holding this needle? Returns a BODY_ZONE_*_ARM or null.
 * Odd held indexes are left hands, even ones are right - same convention the
 * rest of the codebase uses (see /mob/proc/held_index_to_dir).
 */
/obj/item/proc/get_wielding_arm(mob/living/carbon/human/user)
	var/index = user.get_held_index_of_item(src)
	if(!index)
		return null
	return (index % 2 == 0) ? BODY_ZONE_R_ARM : BODY_ZONE_L_ARM

/obj/item/proc/pick_tattoo_zone_for_target(mob/living/carbon/human/patient, mob/living/carbon/human/artist, is_self)
	var/targeted = artist.zone_selected
	var/list/candidates = GLOB.tattoo_zones_by_limb[targeted]

	// Precise zones (hands) target their own limb, so fall back to the limb itself
	if(!candidates)
		candidates = GLOB.tattoo_zones_by_limb[deprecise_zone(targeted)]

	// You can't poke a tattoo into the very arm that's holding the needle
	var/busy_arm = is_self ? get_wielding_arm(artist) : null

	var/list/valid = list()
	var/blocked_by_hand = FALSE
	var/blocked_by_consent = FALSE
	for(var/zone in candidates)
		if(!patient.has_tattoo_zone(zone))
			continue
		if(busy_arm && tattoo_zone_limb(zone) == busy_arm)
			blocked_by_hand = TRUE
			continue
		if(!can_use_tattoo_zone(patient, artist, zone, is_self, quiet = TRUE))
			blocked_by_consent = TRUE
			continue
		valid += zone

	if(!length(valid))
		if(blocked_by_hand)
			to_chat(artist, span_warning("You can't work on the very arm that's holding [src] - switch hands first."))
		else if(blocked_by_consent)
			to_chat(artist, span_warning("[patient] isn't willing to have that area marked or cleaned."))
		else
			to_chat(artist, span_warning("There's nowhere to put a mark there."))
		return null

	if(length(valid) == 1)
		return valid[1]

	var/list/by_name = list()
	for(var/zone in valid)
		by_name[capitalize(tattoo_zone_name(zone))] = zone

	var/choice = input(artist, "Where exactly?", "Body Mark Placement") as null|anything in by_name
	if(!choice)
		return null
	return by_name[choice]

/*
 * SURFACE WRITING
 *
 * A lump of charcoal draws on skin rather than under it: same placement rules
 * and the same zones, but the mark is always charcoal-coloured, goes on fast,
 * hurts no one, and washes off again. Ink from the needle is the permanent
 * version and only surgery removes it.
 */

/obj/item/ore/coal/examine(mob/user)
	. = ..()
	. += span_notice("Target a body zone and click yourself to write on it, or grab someone and keep hold to write on them. New writing replaces the old inscription at that spot. A damp rag or soap wipes it off.")

/obj/item/ore/coal/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!ishuman(target) || !ishuman(user))
		return ..()
	try_tattoo(target, user, TATTOO_MEDIUM_CHARCOAL, TATTOO_CHARCOAL_COLOR)
	return TRUE

/obj/item/ore/coal/attack_self(mob/user, list/modifiers)
	. = ..()
	if(.)
		return
	if(!ishuman(user))
		return
	try_tattoo(user, user, TATTOO_MEDIUM_CHARCOAL, TATTOO_CHARCOAL_COLOR)

/obj/item/paint_brush/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!ishuman(target) || !ishuman(user))
		return ..()
	if(!current_color)
		to_chat(user, span_warning("I need to load some paint onto the brush first."))
		return TRUE
	try_tattoo(target, user, TATTOO_MEDIUM_PAINT, current_color)
	return TRUE

/obj/item/lipstick/examine(mob/user)
	. = ..()
	. += span_notice("Target the mouth to do lips. Any other zone writes on the skin; a damp rag or soap wipes it off.")

/// Lipstick writing on any zone but the mouth.
/obj/item/lipstick/proc/write_on_skin(mob/living/carbon/human/target, mob/living/user)
	if(!ishuman(user))
		return ITEM_INTERACT_BLOCKING
	try_tattoo(target, user, TATTOO_MEDIUM_LIPSTICK, colour)
	return ITEM_INTERACT_SUCCESS

/obj/item/natural/feather/examine(mob/user)
	. = ..()
	. += span_notice("Target a body zone and click yourself or a held person to write on the skin in ink. A damp rag or soap wipes it off.")

/obj/item/natural/feather/attack(mob/living/target, mob/living/user, list/modifiers)
	if(!ishuman(target) || !ishuman(user))
		return ..()
	try_tattoo(target, user, TATTOO_MEDIUM_QUILL, TATTOO_QUILL_COLOR)
	return TRUE

/// Wipe one existing inscription. NONE lets the item's normal interaction run.
/obj/item/proc/try_wipe_body_writing(atom/target, mob/living/user)
	if(QDELETED(src) || QDELETED(target) || QDELETED(user) || !ishuman(target) || !ishuman(user) || user.used_intent?.type == INTENT_HARM)
		return NONE
	var/mob/living/carbon/human/patient = target
	var/mob/living/carbon/human/cleaner = user
	var/list/candidates = GLOB.tattoo_zones_by_limb[cleaner.zone_selected]
	if(!candidates)
		candidates = GLOB.tattoo_zones_by_limb[deprecise_zone(cleaner.zone_selected)]
	var/list/by_name = list()
	for(var/zone in candidates)
		var/obj/item/bodypart/part = patient.get_bodypart(tattoo_zone_limb(zone))
		if(!part || !patient.has_tattoo_zone(zone))
			continue
		for(var/list/entry in part.tattoos)
			if(entry["zone"] == zone && is_surface_body_mark(entry["medium"]))
				by_name[capitalize(tattoo_zone_name(zone))] = zone
				break
	if(!length(by_name))
		return NONE

	var/obj/item/soap/soap = istype(src, /obj/item/soap) ? src : null
	var/cleaning_reagent
	if(soap)
		if(soap.uses <= 0)
			return ITEM_INTERACT_BLOCKING
	else
		cleaning_reagent = /datum/reagent/water
		if(!reagents?.has_reagent(cleaning_reagent, BODY_WRITING_WIPE_REAGENT_AMOUNT))
			cleaning_reagent = /datum/reagent/soap
			if(!reagents?.has_reagent(cleaning_reagent, BODY_WRITING_WIPE_REAGENT_AMOUNT))
				to_chat(cleaner, span_warning("I need to dampen the rag with water or soap first."))
				return ITEM_INTERACT_BLOCKING

	var/is_self = patient == cleaner
	if(QDELETED(src) || !cleaner.is_holding(src) || !cleaner.can_perform_action(src, NEED_DEXTERITY))
		return ITEM_INTERACT_BLOCKING
	if(!is_self && !tattoo_has_grab_on(cleaner, patient))
		to_chat(cleaner, span_warning("I need to grab [patient] and hold them still first."))
		return ITEM_INTERACT_BLOCKING

	var/selected_zone = by_name[by_name[1]]
	if(length(by_name) > 1)
		var/choice = input(cleaner, "Which inscription should I wipe off?", "Wipe Body Writing") as null|anything in by_name
		if(!choice)
			return ITEM_INTERACT_BLOCKING
		selected_zone = by_name[choice]
	if(!still_in_reach(patient, cleaner, selected_zone, is_self) || !can_use_tattoo_zone(patient, cleaner, selected_zone, is_self))
		return ITEM_INTERACT_BLOCKING
	if(is_self && get_wielding_arm(cleaner) == tattoo_zone_limb(selected_zone))
		to_chat(cleaner, span_warning("I need to switch hands to wipe that arm."))
		return ITEM_INTERACT_BLOCKING

	var/obj/item/bodypart/part = patient.get_bodypart(tattoo_zone_limb(selected_zone))
	var/zone_name = tattoo_zone_name(selected_zone)
	cleaner.visible_message(span_notice("[cleaner] begins wiping the writing from [patient]'s [zone_name]."), span_notice("I begin wiping the writing from [is_self ? "my" : "[patient]'s"] [zone_name]."))
	if(!do_after(cleaner, 2 SECONDS, patient, interaction_key = "body_writing_wipe"))
		return ITEM_INTERACT_BLOCKING
	if(QDELETED(part) || QDELETED(patient) || part.owner != patient)
		return ITEM_INTERACT_BLOCKING
	if(!still_in_reach(patient, cleaner, selected_zone, is_self) || !can_use_tattoo_zone(patient, cleaner, selected_zone, is_self))
		return ITEM_INTERACT_BLOCKING
	if(is_self && get_wielding_arm(cleaner) == tattoo_zone_limb(selected_zone))
		return ITEM_INTERACT_BLOCKING
	if(soap)
		if(soap.uses <= 0)
			return ITEM_INTERACT_BLOCKING
	else if(!reagents?.has_reagent(cleaning_reagent, BODY_WRITING_WIPE_REAGENT_AMOUNT))
		return ITEM_INTERACT_BLOCKING

	var/removed_any = FALSE
	for(var/list/entry in part.tattoos.Copy())
		if(entry["zone"] == selected_zone && is_surface_body_mark(entry["medium"]))
			part.tattoos -= list(entry)
			removed_any = TRUE
	if(!removed_any)
		return ITEM_INTERACT_BLOCKING
	cleaner.visible_message(span_notice("[cleaner] wipes the writing from [patient]'s [zone_name]."), span_notice("I wipe the writing from [is_self ? "my" : "[patient]'s"] [zone_name]."))
	if(soap)
		soap.decreaseUses(cleaner, 5)
	else
		reagents.remove_reagent(cleaning_reagent, BODY_WRITING_WIPE_REAGENT_AMOUNT)
	return ITEM_INTERACT_SUCCESS

/**
 * Crafting: forged on an anvil from a bronze bar, then fitted with an
 * alchemical vial for the pigment and a needle for the business end.
 */
/datum/anvil_recipe/tools/tattoo_machine
	name = "Tattoo Machine (+Alchemical Vial, +Needle)"
	recipe_name = "a tattoo machine"
	req_bar = /obj/item/ingot/bronze
	additional_items = list(
		/obj/item/reagent_containers/glass/alchemical,
		/obj/item/needle,
	)
	created_item = /obj/item/tattoo_machine
	craftdiff = 2

/*
 * SURGERY
 *
 * Scrapes one tattoo out of the limb. OPERATION_LOOPING lets the surgeon keep
 * going until the limb is clean.
 */

/datum/surgery_operation/limb/scrape_tattoo
	name = "Scrape Away Tattoo"
	desc = "Scrape an unwanted tattoo out of a patient's skin. \
		Requires the skin to be open."

	implements = list(
		TOOL_SCALPEL = 1,
		TOOL_IMPROVISED_SCALPEL = 2,
	)

	time = 7 SECONDS

	skill_min = SKILL_LEVEL_APPRENTICE
	skill_median = SKILL_LEVEL_JOURNEYMAN

	operation_flags = OPERATION_LOOPING

	all_surgery_states_required = SURGERY_SKIN_OPEN

/datum/surgery_operation/limb/scrape_tattoo/all_required_strings()
	. = ..()
	. += "the limb must have a tattoo"

/datum/surgery_operation/limb/scrape_tattoo/state_check(obj/item/bodypart/limb)
	for(var/list/entry in limb.tattoos)
		if(entry["medium"] == TATTOO_MEDIUM_INK)
			return TRUE
	return FALSE

/datum/surgery_operation/limb/scrape_tattoo/on_preop(obj/item/bodypart/limb, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		limb.owner,
		span_notice("I begin scraping the tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]..."),
		span_notice("[surgeon] begins scraping a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]."),
		span_notice("[surgeon] begins scraping a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]."),
	)
	display_pain(limb.owner, "My [parse_zone(limb.body_zone)] burns as the ink is scraped out!")

/datum/surgery_operation/limb/scrape_tattoo/on_success(obj/item/bodypart/limb, mob/living/surgeon, obj/item/tool, list/operation_args)
	display_results(
		surgeon,
		limb.owner,
		span_notice("I scrape the tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)], leaving raw skin behind."),
		span_notice("[surgeon] scrapes a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]!"),
		span_notice("[surgeon] scrapes a tattoo out of [limb.owner]'s [parse_zone(limb.body_zone)]!"),
	)

	// Take the oldest inked tattoo. Charcoal drawings aren't worth a scalpel -
	// they wash off - so surgery ignores them.
	for(var/list/entry in limb.tattoos)
		if(entry["medium"] != TATTOO_MEDIUM_INK)
			continue
		limb.tattoos -= list(entry)
		break

	limb.receive_damage(6, flashes = TRUE)

	var/mob/living/carbon/human/patient = limb.owner
	if(ishuman(patient))
		patient.save_tattoos_now()

/datum/surgery_operation/limb/scrape_tattoo/on_failure(obj/item/bodypart/limb, mob/living/surgeon, tool, list/operation_args)
	display_results(
		surgeon,
		limb.owner,
		span_warning("I slip, gouging [limb.owner]'s [parse_zone(limb.body_zone)] without touching the ink!"),
		span_warning("[surgeon] slips, gouging [limb.owner]'s [parse_zone(limb.body_zone)]!"),
		span_warning("[surgeon] slips, gouging [limb.owner]'s [parse_zone(limb.body_zone)]!"),
	)
	display_pain(limb.owner, "I feel the blade dig into my [parse_zone(limb.body_zone)]!")

	limb.receive_damage(15, flashes = TRUE)

/*
 * CHARACTER CREATOR PAGE
 *
 * Reached from Character Setup -> Body -> Tattoos. Lists every zone grouped
 * head -> feet, with what is already inked there and an Add link per zone.
 *
 * Zones the character can't have are still listed but refuse to be used - the
 * preview mob is consulted for wings/horns/tail/ears, and picking one you
 * don't have explains why instead of silently doing nothing.
 */

/// Does the character being edited have what this zone needs?
/// Checked against the selected species' organ list, so a race without wings
/// can't pre-write wing tattoos. Optional organ slots (hollowkin horns and the
/// like) are allowed - the needle re-checks for real in-round anyway.
/datum/preferences/proc/preview_has_tattoo_zone(zone)
	var/list/zone_data = GLOB.tattoo_zone_data[zone]
	if(!zone_data)
		return FALSE
	// Genitals and breasts aren't species organs on this fork - they're
	// per-character customizer entries toggled On/Off in the editor, so ask
	// the customizer rather than the species organ list.
	var/customizer_entry_type = zone_data["customizer"]
	if(customizer_entry_type)
		return has_enabled_customizer_entry_type(customizer_entry_type)

	var/needed_organ = zone_data["organ"]
	if(!needed_organ)
		return TRUE
	var/datum/species/species = pref_species
	if(!species)
		return TRUE
	if(needed_organ in species.organs)
		return TRUE
	if(needed_organ in species.optional_organ_slots)
		return TRUE
	return FALSE

/**
 * TGUI window datum. One per open window, disposed on close.
 * Follows the /datum/gossip_prefs pattern used by the other prefs sub-windows.
 */
/datum/tattoo_prefs
	var/mob/holder

/datum/tattoo_prefs/New(mob/user)
	holder = user

/datum/tattoo_prefs/Destroy()
	holder = null
	return ..()

/datum/tattoo_prefs/ui_close(mob/user)
	qdel(src)

/datum/tattoo_prefs/ui_state(mob/user)
	return GLOB.always_state

/datum/tattoo_prefs/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new /datum/tgui(user, src, "TattooManagement", "Tattoo Management")
		ui.open()

/datum/tattoo_prefs/ui_data(mob/user)
	var/list/entries = list()
	var/list/zones = list()
	var/list/pigments = list()

	var/datum/preferences/prefs = holder?.client?.prefs
	if(user == holder && prefs)
		// Walk the zone table rather than the saved list, so the listing always
		// reads head -> feet regardless of the order tattoos were added in.
		for(var/zone in GLOB.tattoo_zone_data)
			var/list/zone_entries = LAZYACCESS(prefs.tattoos, zone)
			for(var/i in 1 to length(zone_entries))
				var/list/entry = zone_entries[i]
				entries += list(list(
					"zone" = zone,
					"zone_name" = capitalize(tattoo_zone_name(zone)),
					"sentence_name" = tattoo_zone_name(zone),
					"text" = entry["text"],
					"style" = entry["style"],
					"color" = entry["color"],
					"pigment" = tattoo_pigment_name(entry["color"]),
					"state" = entry["state"],
					"index" = i,
				))
			zones += list(list(
				"key" = zone,
				"name" = capitalize(tattoo_zone_name(zone)),
				"sentence_name" = tattoo_zone_name(zone),
				"intimate" = tattoo_zone_is_intimate(zone),
				"present" = prefs.preview_has_tattoo_zone(zone),
				"count" = length(zone_entries),
			))

		for(var/pigment_name in GLOB.tattoo_ink_colors)
			pigments += list(list(
				"name" = pigment_name,
				"color" = GLOB.tattoo_ink_colors[pigment_name],
			))

	return list(
		"tattoos" = entries,
		"zones" = zones,
		"pigments" = pigments,
		"max_length" = TATTOO_TEXT_MAX_LENGTH,
		"max_per_zone" = MAXIMUM_TATTOOS_PER_ZONE,
	)

/datum/tattoo_prefs/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()
	if(.)
		return TRUE

	if(ui.user != holder || !holder?.client?.prefs)
		return FALSE
	var/datum/preferences/prefs = holder.client.prefs

	switch(action)
		if("add_tattoo")
			var/zone = params["zone"]
			if(!(zone in GLOB.tattoo_zone_data))
				return FALSE
			if(!prefs.preview_has_tattoo_zone(zone))
				tgui_alert(holder, "Your character doesn't have [tattoo_zone_name(zone)] to tattoo.", "No Such Body Part", list("OK"))
				return FALSE

			var/list/entries = LAZYACCESS(prefs.tattoos, zone)
			if(length(entries) >= MAXIMUM_TATTOOS_PER_ZONE)
				return FALSE

			// Client-supplied, so sanitize everything rather than trusting the UI
			var/text = trim(sanitize(params["text"]), TATTOO_TEXT_MAX_LENGTH)
			if(!length(text))
				return FALSE

			var/style = (params["style"] == TATTOO_STYLE_LETTERING) ? TATTOO_STYLE_LETTERING : TATTOO_STYLE_DESIGN

			// Only accept colours we actually offer - no arbitrary hex from the client
			var/color = null
			for(var/pigment_name in GLOB.tattoo_ink_colors)
				if(GLOB.tattoo_ink_colors[pigment_name] == params["color"])
					color = GLOB.tattoo_ink_colors[pigment_name]
					break
			if(!color)
				return FALSE

			LAZYINITLIST(prefs.tattoos)
			if(!prefs.tattoos[zone])
				prefs.tattoos[zone] = list()
			prefs.tattoos[zone] += list(list(
				"zone" = zone,
				"text" = text,
				"style" = style,
				"color" = color,
				"medium" = TATTOO_MEDIUM_INK,
				"state" = TATTOO_STATE_FRESH,
			))
			prefs.save_character()
			prefs.mark_preview_appearance_dirty()
			return TRUE

		if("remove_tattoo")
			var/zone = params["zone"]
			var/index = text2num(params["index"])
			var/list/entries = LAZYACCESS(prefs.tattoos, zone)
			if(!entries || !index || index < 1 || index > length(entries))
				return FALSE
			entries.Cut(index, index + 1)
			if(!length(entries))
				prefs.tattoos -= zone
			prefs.save_character()
			prefs.mark_preview_appearance_dirty()
			return TRUE

	return FALSE

/datum/preferences/proc/ShowTattoos(mob/user)
	var/datum/tattoo_prefs/window = new(user)
	window.ui_interact(user)
