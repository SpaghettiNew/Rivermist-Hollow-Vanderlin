/datum/examine_panel
	/// Mob that the examine panel belongs to.
	var/mob/living/carbon/human/holder
	/// The screen containing the appearance of the mob
	var/atom/movable/screen/map_view/examine_panel_screen/examine_panel_screen

	var/datum/preferences/pref = null

	var/is_playing = FALSE

	var/mob/viewing

	/// Current direction of the character preview doll
	var/preview_dir = SOUTH
	/// Whether the viewer has opened the character preview (so we only flatten icons on demand)
	var/preview_requested = FALSE

/datum/examine_panel/New(mob/holder_mob)
	if(holder_mob)
		holder = holder_mob

/datum/examine_panel/Destroy(force)
	if(holder && viewing)
		LAZYREMOVE(holder.examine_panels, REF(viewing))
	holder = null
	viewing = null
	return ..()

/// Returns the base64 preview of the holder facing preview_dir, served from the mob-level cache.
/datum/examine_panel/proc/get_preview_image()
	var/mob/living/carbon/human/preview_mob = holder
	if(!ishuman(preview_mob))
		return ""
	return preview_mob.get_examine_preview(preview_dir)

// -------------------------------------------------------------------------
// Mob-level preview cache (SNAPSHOT MODEL).
// Flattened doll previews are stored on the human itself, keyed by direction.
// They are built on demand when a viewer examines the mob, reused for the life
// of that examine session, and wiped on a fresh examine (reset_examine_preview)
// so re-examining reflects the mob's current state. No live/per-tick updating.
// -------------------------------------------------------------------------

/// Throwaway render proxy for flattening examine previews, mirroring the
/// contract ledger's preview proxy. Exists only for the duration of one
/// getFlatIcon call.
/obj/effect/abstract/examine_preview_proxy
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	anchored = TRUE

/mob
	/// Open examine panels for this mob, indexed by REF of the viewing mob.
	/// Lets repeat "Examine Closer" clicks refocus the existing window.
	/// Lives on /mob (not /mob/living/carbon/human) because the examine panel
	/// can be opened on a /mob/dead/new_player for the lobby character preview.
	var/list/examine_panels

/mob/living/carbon
	/// Emergency sergeant recruitment action granted when there is no Town Watch captain on duty.
	var/datum/action/cooldown/spell/undirected/list_target/convert_role/town_watch/town_watch_recruit_action

/mob/living/carbon/human
	/// Cached base64 examine preview snapshots, indexed by "[dir]". Wiped on a
	/// fresh examine (reset_examine_preview) so re-examining shows current state.
	var/list/examine_preview_cache
	/// Command trait for town watch authority granted to a human captain/sergeant.
	var/datum/town_watch_command_trait/town_watch_command_trait

/**
 * Returns a base64 data URL of this human flattened via getFlatIcon in the wanted direction.
 * getFlatIcon ignores the mob's transform (so resize/height scaling and lying rotation are
 * stripped) and expands the canvas to fit every overlay, so oversized taur sprites
 * (64px icons with offset_x/body_offset_y) are included whole.
 *
 * When the appearance changed, the whole cache is wiped and directions are rebuilt lazily,
 * but no more than once per second - spam clicking or rapid re-equipping serves the
 * slightly stale image instead of hammering the icon blender.
 */
/// Fixed canvas size (px) for examine previews. Big enough for 64px taur
/// sprites with body offsets, and keeps the on-screen scale constant no matter
/// how far blood splatter or held items stretch the flattened bounding box.
#define EXAMINE_PREVIEW_CANVAS 96

/**
 * Builds a base64 PNG snapshot of this human flattened in wanted_dir and caches
 * it per direction. SNAPSHOT MODEL: there is no live updating - the preview
 * reflects the moment the viewer examined the mob. The cache is reused for the
 * life of the open panel; a fresh examine (reopen) wipes it via
 * reset_examine_preview() and rebuilds. Rotation builds the new direction on
 * demand and caches it too.
 *
 * getFlatIcon is expensive (dozens of blends for a geared character), but here
 * it runs only on explicit examine/rotate - never on a poll - so it never
 * touches the SStgui tick.
 */
/mob/living/carbon/human/proc/get_examine_preview(wanted_dir = SOUTH)
	if(!examine_preview_cache)
		examine_preview_cache = list()
	var/dir_key = "[wanted_dir]"
	if(examine_preview_cache[dir_key])
		return examine_preview_cache[dir_key]
	// Flatten through a throwaway obj proxy (same recipe as the contract ledger's
	// target previews) rather than the mob or an appearance copy:
	// - the proxy's dir is fully ours, so the preview doesn't follow the mob's
	//   in-game facing and the rotate buttons work for all four sides;
	// - /mutable_appearance/New() stomps plane to FLOAT_PLANE, which made
	//   getFlatIcon's plane filter skip overlays with an explicit plane;
	// - transform is deliberately not copied, stripping resize/height scaling.
	var/obj/effect/abstract/examine_preview_proxy/render_proxy = new()
	render_proxy.icon = icon
	render_proxy.icon_state = icon_state
	render_proxy.dir = wanted_dir
	render_proxy.color = color
	render_proxy.alpha = alpha
	if(length(overlays))
		render_proxy.overlays = overlays.Copy()
	if(length(underlays))
		render_proxy.underlays = underlays.Copy()
	var/icon/flat_icon = getFlatIcon(render_proxy, wanted_dir, no_anim = TRUE)
	qdel(render_proxy)
	if(!flat_icon)
		return ""
	// Normalize to a fixed, centered canvas so the doll renders at a constant scale.
	var/flat_width = flat_icon.Width()
	var/flat_height = flat_icon.Height()
	if(flat_width != EXAMINE_PREVIEW_CANVAS || flat_height != EXAMINE_PREVIEW_CANVAS)
		var/crop_x1 = round((flat_width - EXAMINE_PREVIEW_CANVAS) / 2) + 1
		var/crop_y1 = round((flat_height - EXAMINE_PREVIEW_CANVAS) / 2) + 1
		flat_icon.Crop(crop_x1, crop_y1, crop_x1 + EXAMINE_PREVIEW_CANVAS - 1, crop_y1 + EXAMINE_PREVIEW_CANVAS - 1)
	var/encoded = icon2base64(flat_icon)
	if(!encoded)
		return ""
	examine_preview_cache[dir_key] = "data:image/png;base64,[encoded]"
	return examine_preview_cache[dir_key]

/// Wipes the cached doll snapshots so the next examine rebuilds them fresh.
/mob/living/carbon/human/proc/reset_examine_preview()
	examine_preview_cache = null

//RMH EDITED START - snapshot invalidation was only driven by Topic(), so a doll
// cached while the mob was dressed survived undressing, re-examining and even a
// panel reopen (the fresh-panel branch never wiped it). Every worn-item overlay
// change funnels through apply_overlay/remove_overlay, so hook both: nulling one
// var is free next to the icon work these procs already do, and it guarantees the
// next flatten reflects the mob as it is now, in every direction.
/mob/living/carbon/human/apply_overlay(cache_index)
	if(examine_preview_cache)
		examine_preview_cache = null
	return ..()

/mob/living/carbon/human/remove_overlay(cache_index)
	if(examine_preview_cache)
		examine_preview_cache = null
	return ..()
//RMH EDITED END

#undef EXAMINE_PREVIEW_CANVAS

// -------------------------------------------------------------------------
// Worn equipment slots shown around the character preview.
// Mirrors exactly what Examine prints to chat: get_unobscured_items()
// (so armor/cloaks hiding a slot hide it here) plus held items.
// -------------------------------------------------------------------------

/// Item sprites encoded once per icon+state+color, shared server-wide
GLOBAL_LIST_EMPTY(examine_item_icon_cache)

/proc/examine_item_icon_b64(obj/item/item)
	// Use the item's ground/world sprite (icon + icon_state), NOT any worn
	// mob_overlay or in-hand icon. These vars already hold the on-floor sprite.
	var/ground_icon = item.icon
	var/ground_state = item.icon_state
	if(!ground_icon || !ground_state)
		return ""
	var/cache_key = "[ground_icon]-[ground_state]-[item.color]"
	if(GLOB.examine_item_icon_cache[cache_key])
		return GLOB.examine_item_icon_cache[cache_key]
	var/icon/item_icon = icon(ground_icon, ground_state, SOUTH, 1)
	if(!item_icon)
		return ""
	if(istext(item.color))
		item_icon.Blend(item.color, ICON_MULTIPLY)
	var/encoded = icon2base64(item_icon)
	if(!encoded)
		return ""
	GLOB.examine_item_icon_cache[cache_key] = "data:image/png;base64,[encoded]"
	return GLOB.examine_item_icon_cache[cache_key]

/// Fixed slot layout: ordered list of (UI position id -> slot flag + label).
/// The UI renders these at fixed coordinates; order here is just for iteration.
GLOBAL_LIST_INIT(examine_panel_slot_layout, list(
	// left column, top->bottom
	"head"     = list("flag" = ITEM_SLOT_HEAD,   "label" = "Head"),
	"shirt"    = list("flag" = ITEM_SLOT_SHIRT,  "label" = "Shirt"),
	"gloves"   = list("flag" = ITEM_SLOT_GLOVES, "label" = "Hands"),
	"belt"     = list("flag" = ITEM_SLOT_BELT,   "label" = "Belt"),
	"pants"    = list("flag" = ITEM_SLOT_PANTS,  "label" = "Pants"),
	"shoes"    = list("flag" = ITEM_SLOT_SHOES,  "label" = "Shoes"),
	// right column, top->bottom
	"mouth"    = list("flag" = ITEM_SLOT_MOUTH,  "label" = "Mouth"),
	"mask"     = list("flag" = ITEM_SLOT_MASK,   "label" = "Face"),
	"armor"    = list("flag" = ITEM_SLOT_ARMOR,  "label" = "Armor"),
	"neck"     = list("flag" = ITEM_SLOT_NECK,   "label" = "Neck"),
	"cloak"    = list("flag" = ITEM_SLOT_CLOAK,  "label" = "Cape"),
	"ring"     = list("flag" = ITEM_SLOT_RING,   "label" = "Finger"),
	"wrists"   = list("flag" = ITEM_SLOT_WRISTS, "label" = "Wrists"),
	// bottom corners
	"backr"    = list("flag" = ITEM_SLOT_BACK_R, "label" = "Right shoulder"),
	"beltr"    = list("flag" = ITEM_SLOT_BELT_R, "label" = "Right hip"),
	"beltl"    = list("flag" = ITEM_SLOT_BELT_L, "label" = "Left hip"),
	"backl"    = list("flag" = ITEM_SLOT_BACK_L, "label" = "Left shoulder"),
))

/**
 * Normalizes an item's stamped quality tier (base craft scale, QUALITY_LEVEL_*:
 * -10 ruined .. 8 masterwork) into a 0..6 frame index the UI maps to a color.
 * Null tier (item never crafted through the quality system) returns -1 = no
 * special frame, so spawned/admin items just get the neutral default border.
 */
/datum/examine_panel/proc/quality_frame_index(obj/item/item)
	var/tier = item.examine_quality_tier
	if(isnull(tier))
		return -1
	switch(tier)
		if(-INFINITY to -6)
			return 0 // ruined
		if(-5 to -3)
			return 1 // awful
		if(-2 to -1)
			return 2 // crude/rough
		if(0 to 1)
			return 3 // competent
		if(2 to 4)
			return 4 // fine
		if(5 to 7)
			return 5 // flawless
		else
			return 6 // masterwork / legendary

/// Strips real HTML tags (not just the < > chars) and collapses the runs of
/// newlines that span macros like span_info() leave behind, so dynamic descs
/// (keyrings, anything using update_desc with markup) render as clean text.
/datum/examine_panel/proc/sanitize_examine_text(text)
	if(!text)
		return ""
	// GLOB.html_tags = regex(@"<.*?>", "g") - removes whole <...> tags, unlike
	// STRIP_HTML_SIMPLE which only deletes the angle brackets and leaves the
	// "span class='info'" guts behind.
	var/clean = GLOB.html_tags.Replace("[text]", "")
	// collapse 3+ newlines to a single break, trim edges
	clean = replacetext(clean, "\n\n\n", "\n")
	return trim(clean)

/// Attack intents across every grip, tagged with which grip supplies them.
/// update_a_intents() swaps possible_item_intents for gripped_intents while
/// wielded, so a gripped-only attack is invisible without this. First list to
/// name an intent owns it, so only genuinely grip-exclusive attacks get tagged.
/obj/item/proc/get_weapon_intent_names()
	var/list/result = list()
	var/list/seen = list()
	for(var/intent_type in possible_item_intents)
		var/iname = initial(intent_type:name)
		if(iname && !seen[iname])
			seen[iname] = TRUE
			result += list(list("name" = iname, "grip" = "normal"))
	for(var/intent_type in (gripped_intents || list()))
		var/iname = initial(intent_type:name)
		if(iname && !seen[iname])
			seen[iname] = TRUE
			result += list(list("name" = iname, "grip" = "gripped"))
	for(var/intent_type in (alt_intents || list()))
		var/iname = initial(intent_type:name)
		if(iname && !seen[iname])
			seen[iname] = TRUE
			result += list(list("name" = iname, "grip" = "alt"))
	return result

/// Longest tile reach among this weapon's intents, across every grip.
/obj/item/proc/get_weapon_max_reach()
	var/best = 1
	var/list/all_intents = possible_item_intents + (gripped_intents || list()) + (alt_intents || list())
	for(var/intent_type in all_intents)
		var/intent_reach = initial(intent_type:reach)
		if(isnum(intent_reach) && intent_reach > best)
			best = intent_reach
	return best

/// Property badges. "Extra Reach" is the intents' tile reach, not wlength -
/// wlength only controls which bodyparts a downed target exposes.
/obj/item/proc/get_weapon_tag_badges()
	var/list/tags = list()
	if(w_class <= WEIGHT_CLASS_SMALL)
		tags += "Light"
	if(get_weapon_max_reach() > 1)
		tags += "Extra Reach"
	var/datum/component/two_handed/twohand = GetComponent(/datum/component/two_handed)
	if(twohand)
		tags += twohand.require_twohands ? "Two-Handed" : "Versatile"
	return tags

/// Packs one item for the Examine Closer tooltip. Text is stripped of chat
/// markup; price follows the same gating as get_displayed_price().
/datum/examine_panel/proc/pack_examine_item(obj/item/item)
	var/list/packed = list(
		"name" = sanitize_examine_text(item.name),
		"desc" = sanitize_examine_text(item.desc),
		"icon" = examine_item_icon_b64(item),
		"quality" = quality_frame_index(item),
		"weight" = item.item_weight,
	)

	var/real_price = item.get_real_price()
	if(real_price > 0 && (HAS_TRAIT(viewing, TRAIT_SEEPRICES) || item.simpleton_price))
		packed["price"] = real_price

	// Weight class only; the full ABSORB/REDUCE/BLOCK breakdown lives on the
	// chat-side tooltip and the {?} popup instead.
	if(istype(item, /obj/item/clothing))
		var/obj/item/clothing/clothing_item = item
		if(clothing_item.armor_class)
			packed["armorClassLabel"] = armor_class_to_label(clothing_item.armor_class)

	if(item.force)
		packed["weaponDamage"] = list("force" = item.force)
		packed["weaponCategory"] = item.get_weapon_category()

	if(item.force || item.associated_skill)
		packed["intents"] = item.get_weapon_intent_names()

	// The weapon's "Strong" RMB-stance attack.
	if(isweapon(item))
		var/obj/item/weapon/weap = item
		if(weap.weapon_special)
			packed["specialAttack"] = list(
				"name" = initial(weap.weapon_special:name),
				"desc" = initial(weap.weapon_special:desc),
			)

	var/list/tag_badges = item.get_weapon_tag_badges()
	if(length(tag_badges))
		packed["tags"] = tag_badges

	return packed

/**
 * Builds the fixed-slot equipment payload for the examine panel.
 * Every layout slot is always returned with a status so the UI can draw it at a
 * fixed position:
 *   "item"   - occupied and visible to examine (full data + quality frame)
 *   "hidden" - occupied but obscured (armor/cloak hides it) -> hatched frame
 *   "empty"  - nothing equipped -> hatched/dim frame
 * Held items are returned separately for the two hand slots under the doll.
 */
/datum/examine_panel/proc/get_worn_items_data()
	var/list/slots = list()
	var/list/hands = list()
	var/mob/living/carbon/human/human_holder = holder
	if(!ishuman(human_holder))
		return list("slots" = slots, "hands" = hands)

	// Items examine is willing to show (obscured ones are absent from this list)
	var/list/unobscured = human_holder.get_unobscured_items(FALSE)

	for(var/slot_id in GLOB.examine_panel_slot_layout)
		var/list/layout = GLOB.examine_panel_slot_layout[slot_id]
		var/slot_flag = layout["flag"]
		var/obj/item/equipped = human_holder.get_item_by_slot(slot_flag)
		var/list/entry = list("label" = layout["label"])
		if(!equipped || (equipped.item_flags & ABSTRACT))
			entry["status"] = "empty"
		else if(equipped in unobscured)
			entry["status"] = "item"
			entry["item"] = pack_examine_item(equipped)
		else
			// worn but examine won't reveal it (hidden under other gear)
			entry["status"] = "hidden"
		slots[slot_id] = entry

	// held_items: odd index = left hand, even index = right hand.
	// get_held_items_for_side returns the item (or null) for that side.
	// NOTE: a `for(var/obj/item in list(a, b))` loop silently drops null
	// entries, which shifts a one-handed item into the wrong slot - so build
	// the list by explicit index instead.
	var/obj/item/left_item = human_holder.get_held_items_for_side(LEFT_HANDS)
	var/obj/item/right_item = human_holder.get_held_items_for_side(RIGHT_HANDS)
	// hands[1] = LEFT slot, hands[2] = RIGHT slot (frame order swapped per design)
	hands = list(pack_hand_item(left_item), pack_hand_item(right_item))

	return list("slots" = slots, "hands" = hands)

/// Packs a held item for a hand slot, or null for an empty/abstract hand.
/datum/examine_panel/proc/pack_hand_item(obj/item/item)
	if(!item || (item.item_flags & ABSTRACT))
		return null
	var/list/packed = pack_examine_item(item)
	packed["wielded"] = item.is_wielded()
	return packed

/// Whether the viewer is still close enough to inspect gear, like in-world examine
/datum/examine_panel/proc/viewer_in_range()
	if(!viewing || !holder)
		return FALSE
	if(isobserver(viewing) || IsAdminGhost(viewing))
		return TRUE
	if(viewing == holder)
		return TRUE
	if(viewing.z != holder.z)
		return FALSE
	return get_dist(viewing, holder) <= 4

/datum/examine_panel/ui_state(mob/user)
	return GLOB.always_state

/atom/movable/screen/map_view/examine_panel_screen
	name = "examine panel screen"

/datum/examine_panel/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if(!ui)
		ui = new(user, src, "ExaminePanel")
		// Snapshot model: the panel is NOT autoupdated. Everything (text, doll,
		// gear) is gathered once on open and re-gathered only when the player
		// examines again (reopen). This means an open panel costs the server
		// nothing while idle - no per-tick polling, no signature compares.
		ui.set_autoupdate(FALSE)
		ui.open()

/**
 * With autoupdate disabled this runs only on open and on explicit user actions
 * (rotate, or a fresh examine that reopens the panel). It returns the doll
 * snapshot for the current direction plus the worn-item slots as seen right now.
 */
/datum/examine_panel/ui_data(mob/user)
	. = list()
	//RMH EDITED START - the doll used to be built and sent unconditionally while
	// only the gear slots respected the examine radius, so a viewer across the
	// room still got a full-detail render. Both now sit behind the same gate, and
	// the UI is told why it has nothing to draw instead of showing an endless
	// "Loading character..." spinner.
	// NB: do not name a local "in_range" - is_helpers.dm defines it as a
	// function-like macro, and DM's preprocessor chokes on the bare identifier.
	var/is_human_holder = ishuman(holder)
	var/in_preview_range = viewer_in_range()
	.["preview_available"] = is_human_holder
	.["preview_in_range"] = in_preview_range
	if(!preview_requested || !is_human_holder || !in_preview_range)
		return
	var/mob/living/carbon/human/human_holder = holder
	.["preview_image"] = human_holder.get_examine_preview(preview_dir)
	.["worn_items"] = get_worn_items_data()
	//RMH EDITED END

/datum/examine_panel/ui_static_data(mob/user)
	return collect_examine_data(user)

/// Collects the STATIC examine payload (text, headshots). Heavy markdown parsing
/// runs here, but only on open / explicit static refresh - never per tick.
/datum/examine_panel/proc/collect_examine_data(mob/user)

	var/flavor_text = ""
	var/flavor_text_nsfw = ""
	var/obscured = FALSE
	var/ooc_notes = ""
	var/ooc_notes_nsfw = ""
	var/headshot = ""
	var/nsfw_headshot = ""
	var/list/img_gallery = list()
	var/list/nsfw_img_gallery = list()
	var/char_name = ""
	var/song_url = ""
	var/has_song = FALSE
	var/is_naked = FALSE
	var/has_headshot = FALSE
	var/has_nsfw_headshot = FALSE

	if(ishuman(holder))
		var/mob/living/carbon/human/holder_human = holder
		if(!(holder.wear_armor && holder.wear_armor.flags_inv) && !(holder.wear_shirt && holder.wear_shirt.flags_inv) && !(holder_human.underwear) || holder_human.get_erp_pref(/datum/erp_preference/boolean/always_show_nsfw_flavor))
			is_naked = TRUE
		obscured = ((!isobserver(user))) && ((holder_human.wear_mask && (holder_human.wear_mask.flags_inv & HIDEFACE)) || (holder_human.head && (holder_human.head.flags_inv & HIDEFACE))) // ((!isobserver(user)) && !holder_human.client?.prefs?.masked_examine)
		flavor_text = obscured ? "Obscured" : (holder.flavortext || "")
		flavor_text_nsfw = obscured ? "Obscured" : (holder.nsfwflavortext || "")
		ooc_notes = holder.ooc_notes || ""
		ooc_notes_nsfw = holder.erpprefs_flavor || ""
		char_name = holder.name || ""
		song_url = holder.song_link || ""
		if(!obscured)
			headshot = holder.headshot_link || ""
			nsfw_headshot = holder.nsfw_headshot_link || ""
			img_gallery = holder.img_gallery ? holder.img_gallery.Copy() : list()
			nsfw_img_gallery = holder.nsfw_img_gallery ? holder.nsfw_img_gallery.Copy() : list()
			has_headshot = !!holder.headshot_link
			has_nsfw_headshot = !!holder.nsfw_headshot_link
		if(!holder.headshot_link)
			headshot = "headshot_red.png"
		if(!holder.nsfw_headshot_link)
			nsfw_headshot = "headshot_red.png"

	else if(pref)
		is_naked = TRUE
		obscured = FALSE
		flavor_text = pref.read_preference(/datum/preference/text/flavortext) || ""
		flavor_text_nsfw = pref.read_preference(/datum/preference/text/nsfwflavortext) || ""
		ooc_notes = pref.read_preference(/datum/preference/text/ooc_notes) || ""
		ooc_notes_nsfw = pref.read_preference(/datum/preference/text/erpprefs_flavor) || ""
		headshot = pref.read_preference(/datum/preference/text/headshot_link) || ""
		nsfw_headshot = pref.read_preference(/datum/preference/text/nsfw_headshot_link) || ""
		has_headshot = !!headshot
		has_nsfw_headshot = !!nsfw_headshot
		var/list/regular_gallery = pref.read_preference(/datum/preference/list_type/profile_gallery/images)
		var/list/adult_gallery = pref.read_preference(/datum/preference/list_type/profile_gallery/nsfw_images)
		img_gallery = regular_gallery ? regular_gallery.Copy() : list()
		nsfw_img_gallery = adult_gallery ? adult_gallery.Copy() : list()
		char_name = pref.read_preference(/datum/preference/text/real_name) || ""
		song_url = pref.read_preference(/datum/preference/text/song_link) || ""
		if(!headshot)
			headshot = "headshot_red.png"
		if(!nsfw_headshot)
			nsfw_headshot = "headshot_red.png"

	if(song_url)
		has_song = TRUE

	ooc_notes = html_encode(ooc_notes)
	ooc_notes = parsemarkdown_basic(ooc_notes, hyperlink=TRUE)
	ooc_notes_nsfw = html_encode(ooc_notes_nsfw)
	ooc_notes_nsfw = parsemarkdown_basic(ooc_notes_nsfw, hyperlink=TRUE)
	flavor_text = html_encode(flavor_text)
	flavor_text = parsemarkdown_basic(flavor_text, hyperlink=TRUE)
	flavor_text_nsfw = html_encode(flavor_text_nsfw)
	flavor_text_nsfw = parsemarkdown_basic(flavor_text_nsfw, hyperlink=TRUE)

	var/list/data = list(
		// Identity
		"character_name" = obscured ? (holder?.name || "Unknown") : char_name,
		"headshot" = headshot,
		"nsfw_headshot" = nsfw_headshot,
		"obscured" = obscured ? TRUE : FALSE,
		// Descriptions
		"flavor_text" = flavor_text,
		"ooc_notes" = ooc_notes,
		// Descriptions, but requiring manual input to see
		"flavor_text_nsfw" = flavor_text_nsfw,
		"ooc_notes_nsfw" = ooc_notes_nsfw,
		"img_gallery" = img_gallery,
		"nsfw_img_gallery" = nsfw_img_gallery,
		"is_playing" = is_playing,
		"has_song" = has_song,
		"is_naked" = is_naked,
		"has_headshot" = has_headshot,
		"has_nsfw_headshot" = has_nsfw_headshot,
	)
	return data

/datum/examine_panel/ui_act(action, list/params, datum/tgui/ui, datum/ui_state/state)
	. = ..()

	if(.)
		return

	if(action == "generate_preview")
		preview_requested = TRUE
		// Snapshot model: ui_data builds the doll on demand (cached per dir).
		// update_uis triggers a one-off ui_data refresh with no Loading flash.
		SStgui.update_uis(src)
		return TRUE

	if(action == "rotate")
		preview_requested = TRUE
		// turn() with a positive angle is counterclockwise in BYOND
		preview_dir = turn(preview_dir, params["clockwise"] ? -90 : 90)
		// get_examine_preview() in the resulting ui_data builds+caches this dir
		// on demand (one flatten per direction, per examine session).
		SStgui.update_uis(src)
		return TRUE

	if(!viewing)
		return

	var/client/C
	var/web_sound_url
	var/artist_name = "Song Artist Hidden"
	var/song_title
	var/list/music_extra_data = list()

	C = viewing.client

	if(ishuman(holder))
		web_sound_url = holder.song_link
		if(holder.song_artist)
			artist_name = holder.song_artist
		song_title = holder.song_title

	else if(pref)
		web_sound_url = pref.read_preference(/datum/preference/text/song_link)
		var/preferred_artist = pref.read_preference(/datum/preference/text/song_artist)
		if(preferred_artist)
			artist_name = preferred_artist
		song_title = pref.read_preference(/datum/preference/text/song_title)

	if(!C || !web_sound_url)
		return

	if(!web_sound_url)
		return

	switch(action)
		if("toggle")
			if(!is_playing)
				is_playing = TRUE
				music_extra_data["link"] = web_sound_url
				music_extra_data["title"] = song_title
				music_extra_data["duration"] = "Song Duration Hidden"
				music_extra_data["artist"] = artist_name
				C.tgui_panel?.play_music(web_sound_url, music_extra_data)
			else
				is_playing = FALSE
				C.tgui_panel?.stop_music()
			return TRUE

/datum/examine_panel/ui_close()
	viewing?.client?.tgui_panel?.stop_music()
	QDEL_NULL(src)

/datum/examine_panel/ui_assets(mob/user)
	return list(
		get_asset_datum(/datum/asset/simple/headshot_imgs),
	)

/datum/asset/simple/headshot_imgs
	assets = list(
		"headshot_background.png" = 'icons/tgui/headshot_background.png',
		"headshot_red.png" = 'icons/tgui/headshot_red.png',
		)

