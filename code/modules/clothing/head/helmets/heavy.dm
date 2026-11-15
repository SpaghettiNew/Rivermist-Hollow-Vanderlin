/obj/item/clothing/head/helmet/heavy
	item_weight = 3.7 KILOGRAMS
	name = "helmet template"
	icon_state = "barbute"
	flags_inv = HIDEEARS|HIDEFACE
	equip_sound = 'sound/foley/equip/equip_armor_plate.ogg'
	flags_cover = HEADCOVERSEYES | HEADCOVERSMOUTH
	block2add = FOV_RIGHT|FOV_LEFT
	equip_delay_self = 3 SECONDS
	unequip_delay_self = 3 SECONDS
	emote_environment = 3		// Unknown if this actually works and what it does
	melt_amount = 75
	melting_material = /datum/material/steel
	sellprice = VALUE_STEEL_HELMET

	armor_type = /datum/armor/head/plate
	body_parts_covered = FULL_HEAD
	prevent_crits = ALL_EXCEPT_STAB
	max_integrity = ARMOR_INT_HELMET_HEAVY_STEEL
	abstract_type = /obj/item/clothing/head/helmet/heavy

/obj/item/clothing/head/helmet/heavy/necked		// includes a coif or gorget part to cover neck. Why? So templars can wear their cross on their neck basically, also special thing for Temple
	name = "bastion helm"
	desc = "A modified great helm designed for Templars, this helmet with integrated neck protection serves as an unyielding bastion of protection for the devout."
	icon_state = "topfhelm"
	armor_type = /datum/armor/head/plate
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	body_parts_covered = HEAD_NECK
	prevent_crits = ALL_EXCEPT_BLUNT
	block2add = FOV_BEHIND
	social_cues = list("faction:town_watch" = 5, "rank:town_watch:sergeant" = 5, "elite:town_watch" = 3)

/obj/item/clothing/head/helmet/heavy/psydonbarbute
	name = "exotic barbute"
	desc = "A barbute styled with Aonic imagery."
	icon_state = "psydonbarbute"
	item_state = "psydonbarbute"
	block2add = FOV_BEHIND

/obj/item/clothing/head/helmet/heavy/psydonhelm
	name ="Watch darkholdian armet"
	desc = "Headwear commonly worn by Templars in service to the Oratorium Throni Vacui. This trophy now serves the garrison."
	icon_state = "psydonarmet"
	item_state = "psydonarmet"
	block2add = FOV_BEHIND
	social_cues = list("faction:town_watch" = 5, "rank:town_watch:sergant" = 5, "specialization:Charm" = 3)

//................ Iron Plate Helmet ............... //
/obj/item/clothing/head/helmet/heavy/ironplate
	name = "iron plate helmet"
	desc = "An iron masked helmet usually worn by armed men, it is a solid design yet antiquated and cheap."
	icon_state = "ironplate"
	flags_inv = HIDEEARS
	smeltresult = /obj/item/ingot/iron
	melting_material = /datum/material/iron
	sellprice = VALUE_CHEAP_IRON_HELMET
	block2add = FOV_BEHIND

	armor_type = /datum/armor/head/plate/bad
	max_integrity = ARMOR_INT_HELMET_HEAVY_IRON
	item_weight = 3.5 KILOGRAMS

//............... Rusted Barbute ............... //
/obj/item/clothing/head/helmet/heavy/rust
	name = "rusted barbute"
	desc = "A rusted barbute. Relatively fragile, and might turn your hair brown, but offers good protection."
	icon = 'icons/roguetown/clothing/special/rust_armor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/rust_armor.dmi'
	icon_state = "rusthelm"
	item_state = "rusthelm"
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	smeltresult = /obj/item/ingot/iron
	melting_material = /datum/material/iron
	sellprice = VALUE_IRON_ARMOR/2
	armor_type = /datum/armor/head/plate/bad
	max_integrity = ARMOR_INT_HELMET_HEAVY_DECREPIT
	item_weight = 2.4 KILOGRAMS

//............... Great Helm ............... //
/obj/item/clothing/head/helmet/heavy/bucket
	name = "great helm"
	desc = "An immovable bulwark of protection for the head of the faithful. Antiquated and impractical, but offering incredible defense."
	icon_state = "topfhelm"
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR

	armor_type = /datum/armor/head/plate
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 4.3 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/bucket/gold
	icon_state = "topfhelm_gold"
	item_weight = 8.6 KILOGRAMS

// Vampire Lord is no longer as OP, but the armor should protect against dreaded stabs or it makes the vitae spent on it pointless.
/obj/item/clothing/head/helmet/heavy/vampire
	name = "savoyard"
	desc = "A terrifying yet crude helmet shaped like a human skull. Commands the inspiring terror of inhumen tyrants from yils past."
	icon_state = "savoyard"
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR

	prevent_crits = ALL_CRITICAL_HITS_VAMP
	max_integrity = INTEGRITY_STRONGEST // bespoke integrity: intentional (vampire relic)
	body_parts_covered = HEAD_NECK
	block2add = FOV_BEHIND

//............... Frog Helmet ............... //
/obj/item/clothing/head/helmet/heavy/frog
	name = "frog helmet"
	desc = "A thick, heavy helmet that severely obscures the wearer's vision. Still rather protective."
	icon_state = "froghelm"
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/64x64/head.dmi'
	worn_x_dimension = 64
	worn_y_dimension = 64
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR|HIDEFACIALHAIR

	armor_type = /datum/armor/head/plate/good
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 4.5 KILOGRAMS

//............... Black Knight Helmet ............... //
/obj/item/clothing/head/helmet/heavy/blkknight
	name = "blacksteel helmet"
	desc = "A helmet black as nite. Instills fear upon those that gaze upon it."
	icon_state = "bkhelm"
	icon = 'icons/roguetown/clothing/special/blkknight.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/blkknight.dmi'
	armor_class = AC_MEDIUM
	armor_type = /datum/armor/head/plate/good
	prevent_crits = ALL_CRITICAL_HITS
	max_integrity = ARMOR_INT_HELMET_BLACKSTEEL
	item_weight = 7.2 KILOGRAMS
	sellprice = VALUE_SILVER_ITEM * 2

//............... Zizo Frog Helmet ............... //

/obj/item/clothing/head/helmet/heavy/zizo
	name = "darksteel frog helmet"
	desc = "A darksteel frog helmet. This one has an adjustable visor. Called forth from the edge of what should be known. In Her name."
	adjustable = CAN_CADJUST
	icon_state = "zizofrogmouth"
	icon = 'icons/roguetown/clothing/special/evilarmor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	armor_type = /datum/armor/head/plate
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 4.5 KILOGRAMS
	block2add = FOV_BEHIND
	sellprice = 0 // Incredibly evil Zizoid armor, this should be burnt, nobody wants this

//............... Matthios Helmet ............... //

/obj/item/clothing/head/helmet/heavy/matthios
	name = "gilded visage"
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/64x64/head.dmi'
	desc = "A sinister visage. So that your crimes are never brought to you."
	icon_state = "matthioshelm"
	icon = 'icons/roguetown/clothing/special/evilarmor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/evilarmor64x64.dmi'
	armor_type = /datum/armor/head/plate
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 3.2 KILOGRAMS
	block2add = FOV_BEHIND
	sellprice = 0 // See above comment
	bloody_icon = 'icons/effects/blood64x64.dmi'
	bloody_icon_state = "helmetblood_big"
	worn_x_dimension = 64
	worn_y_dimension = 64

//............... Graggar Helmet ............... //

/obj/item/clothing/head/helmet/heavy/graggar
	name = "vicious helmet"
	desc = "A rugged and horrifying helmet. A violent aura emanates from it."
	icon_state = "graggarplatehelm"
	icon = 'icons/roguetown/clothing/special/evilarmor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	armor_type = /datum/armor/head/plate
	flags_cover = HEADCOVERSEYES
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 4.5 KILOGRAMS
	block2add = FOV_BEHIND
	sellprice = 0 // See above comment

//............... Baothan Helmet ............... //

/obj/item/clothing/head/helmet/heavy/baotha
	name = "willful helmet"
	desc = "Baothan knights are an antithesis : the tiefling queen preaches self preservation at the cost of even family or friend. Choosing to embark on a quest to knightlyhood means facing peril at the forefront. \
	Indeed, many are the upstarts who understood the folly of their journey, and either turned back to the warmth of ozium and wine or died in the process. \
	The original wearer of this helmet is no such pushover : they do not have the might of Gruumsh nor the magick of Lolth, and instead rely on their wits and grit to proclaim their unicity in the face of this cold, uncaring world. \
	It is rumoured that Blissara offers this baroque piece in person, as a reward for the knight's unflinching will in the face of sheer terror, minute after minute, hour after hour. \
	Fashioned in steel and petals, it has no viewport, the wearer instead having their senses heightened to preternatural levels." // yes, this is a long item description, but it's the only piece of armour unique to Baotha.
	icon_state = "baothahelm"
	icon = 'icons/roguetown/clothing/special/baothanknight.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/evilarmor64x64.dmi'
	worn_x_dimension = 64
	worn_y_dimension = 64
	bloody_icon = 'icons/effects/blood64x64.dmi'
	bloody_icon_state = "helmetblood_big"
	armor_type = /datum/armor/head/plate
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 4.5 KILOGRAMS
	block2add = FOV_BEHIND
	sellprice = 0 // See above comment

//............... Spangenhelm ............... //
/obj/item/clothing/head/helmet/heavy/viking
	name = "spangenhelm"
	desc = "A steel helmet with built in eye and nose protection, commonly used by warriors of the north."
	icon_state = "viking_H_gold"
	item_state = "viking_H_gold"
	icon = 'modular_rmh/icons/clothing/viking_helmet.dmi'
	mob_overlay_icon = 'modular_rmh/icons/clothing/onmob/viking_helmet.dmi'
	body_parts_covered = HEAD|NOSE|EYES
	slot_flags = ITEM_SLOT_HEAD
	flags_inv = HIDEFACE|HIDEHAIR
	armor_type = /datum/armor/head/plate
	resistance_flags = FIRE_PROOF
	blocksound = PLATEHIT
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 2.6 KILOGRAMS
	clothing_flags = CANT_SLEEP_IN
	max_integrity = ARMOR_INT_HELMET_HEAVY_STEEL
	block2add = FOV_BEHIND

//............... Temple heavy helmets ......................//
//............... Astrata Helmet ............... //
/obj/item/clothing/head/helmet/heavy/necked/astrata
	name = "sun helmet"
	desc = "A great helmet decorated with a golden sigil of the solar order and a maille neck cover.."
	icon_state = "astratahelm"
	item_weight = 5.5 KILOGRAMS

//............... Noc Helmet ............... //
/obj/item/clothing/head/helmet/heavy/necked/noc
	name = "night helmet"
	desc = "A sleek and rounded heavy helmet with a maille neck cover. Its unique craft is said to allow holy warriors of Mystra additional insight before battle."
	icon_state = "nochelm"
	item_weight = 6 KILOGRAMS
	flags_inv = HIDEEARS

/obj/item/clothing/head/helmet/heavy/necked/noc/Initialize(mapload)
	. = ..()
	enchant(/datum/enchantment/silver)

//............... Necra Helmet ............... //
/obj/item/clothing/head/helmet/heavy/necked/necra
	name = "dark helmet"
	desc = "A reinforced helmet shaped into the visage of a skull with a maille neck cover under the cloth.."
	icon_state = "necrahelm"
	item_weight = 4.5 KILOGRAMS

//............... Dendor Helmet ............... //	This one seems a bit out of place
/obj/item/clothing/head/helmet/heavy/necked/dendorhelm
	name = "beastly helmet"
	desc = "A great helmet with twisted metalwork that imitates the twisting of bark, or the horns of a beast."
	icon_state = "dendorhelm"
	prevent_crits = ALL_EXCEPT_BLUNT
	item_weight = 4.5 KILOGRAMS

//............... Eora Helmet ............... //
/obj/item/clothing/head/helmet/sallet/eoran
	name = "alluring helmet"
	desc = "A simple yet practical protective piece of equipment. Upon it lays several laurels of flowers and other colorful ornaments, followed by several symbols and standards of the user's chapter, accomplishments or even punishment"
	icon_state = "eorahelm"
	item_state = "eorahelm"
	item_weight = 3.2 KILOGRAMS


//............... Pestra Helmet ............... //
/obj/item/clothing/head/helmet/heavy/necked/pestrahelm
	name = "coarse helmet"
	desc = "A great helmet made of coarse, tainted steel."
	icon_state = "pestrahelm"
	item_state = "pestrahelm"
	item_weight = 4.5 KILOGRAMS

//................ Malum Helmet ............. //
/obj/item/clothing/head/helmet/heavy/necked/malumhelm
	name = "sturdy helmet"
	desc = "A great helmet of sturdy dark steel."
	icon_state = "malumhelm"
	item_state = "malumhelm"
	item_weight = 4.5 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/necked/ravox
	name = "sallet"
	desc = "Resembles a heavily-adorned visored sallet."
	icon_state = "ravoxhelm"
	item_state = "ravoxhelm"
	item_weight = 4.5 KILOGRAMS

//................ Xylix Helmet ............. //
/obj/item/clothing/head/helmet/heavy/necked/xylix
	name = "jester helmet"
	desc = "A great helmet forged from steel, and fashioned in the visage of a jester, jingling bells and all."
	icon_state = "xylixhelm"
	item_state = "xylixhelm"
	item_weight = 4.5 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/necked/xylix/Initialize()
	. = ..()
	AddComponent(/datum/component/item_equipped_movement_rustle, custom_sounds = list(SFX_JINGLE_BELLS))

//................ Abyssor Helmet ............. //
/obj/item/clothing/head/helmet/heavy/necked/abyssor
	name = "ridged helmet"
	desc = "A great helmet crafted from bronze. The visor is slitted and ridged, evoking the gills of a great sea-beast."
	icon_state = "abyssorhelm"
	item_state = "abyssorhelm"
	item_weight = 5.5 KILOGRAMS

//............... Sinistar (Graggar) Helmet ............... //
/obj/item/clothing/head/helmet/heavy/sinistar
	name = "howling helmet"
	desc = "Glorious star, smeared in guts and greeted with a chorus of howls."
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/64x64/head.dmi'
	bloody_icon = 'icons/effects/blood64x64.dmi'
	bloody_icon_state = "helmetblood_big"
	worn_x_dimension = 64
	worn_y_dimension = 64
	icon_state = "sinistarhelm"
	dropshrink = 0.9
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	melt_amount = 75
	melting_material = /datum/material/steel
	item_weight = 4.45 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/decorated	// template
	name = "a template"
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/64x64/head.dmi'
	bloody_icon = 'icons/effects/blood64x64.dmi'
	bloody_icon_state = "helmetblood_big"
	worn_x_dimension = 64
	worn_y_dimension = 64
	flags_inv = HIDEEARS|HIDEHAIR|HIDEFACIALHAIR|HIDEFACE
	sellprice = VALUE_STEEL_HELMET+BONUS_VALUE_TINY
	var/picked = FALSE

	prevent_crits = ALL_CRITICAL_HITS
	abstract_type = /obj/item/clothing/head/helmet/heavy/decorated

/obj/item/clothing/head/helmet/heavy/decorated/update_overlays()
	. = ..()
	if(!get_detail_tag())
		return
	var/mutable_appearance/pic = mutable_appearance(icon, "[icon_state][detail_tag]")
	pic.appearance_flags = RESET_COLOR
	if(get_detail_color())
		pic.color = get_detail_color()
	. += pic

//............... Decorated Knight Helmet ............... //
/obj/item/clothing/head/helmet/heavy/decorated/knight
	name = "knights helmet"
	desc = "A lavish knights helmet which allows a crest to be mounted on top."
	icon_state = "decorated_knight"
	item_weight = 4.45 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/decorated/knight/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!picked)
		var/list/icons = HELMET_KNIGHT_DECORATIONS
		var/choice = input(user, "Choose a crest.", "Knightly crests") in icons
		var/playerchoice = icons[choice]
		picked = TRUE
		icon_state = playerchoice
		item_state = playerchoice
		update_appearance(UPDATE_ICON)
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

//............... Decorated Hounskull ............... //
/obj/item/clothing/head/helmet/heavy/decorated/hounskull
	name = "hounskull"
	desc = "A lavish hounskull which allows a crest to be mounted on top."
	icon_state = "decorated_hounskull"
	armor_type = /datum/armor/head/plate/good
	max_integrity = ARMOR_INT_HELMET_HEAVY_STEEL
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 4.45 KILOGRAMS


/obj/item/clothing/head/helmet/heavy/decorated/hounskull/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!picked)
		var/list/icons = HELMET_HOUNSKULL_DECORATIONS
		var/choice = input(user, "Choose a crest.", "Knightly crests") in icons
		var/playerchoice = icons[choice]
		picked = TRUE
		icon_state = playerchoice
		item_state = playerchoice
		update_appearance(UPDATE_ICON)
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

//............... Decorated Great Helm ............... //
/obj/item/clothing/head/helmet/heavy/decorated/bucket
	name = "great helm"
	desc = "A lavish great helm which allows a crest to be mounted on top."
	icon_state = "decorated_bucket"
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 3.5 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/decorated/bucket/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!picked)
		var/list/icons = HELMET_BUCKET_DECORATIONS
		var/choice = input(user, "Choose a crest.", "Knightly crests") in icons
		var/playerchoice = icons[choice]
		picked = TRUE
		icon_state = playerchoice
		item_state = playerchoice
		update_appearance(UPDATE_ICON)
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

//............... Decorated Gold Helm ............... //
/obj/item/clothing/head/helmet/heavy/decorated/golden
	name = "gold helm"
	desc = "A lavish gold-trimmed greathelm which allows a crest to be mounted on top."
	icon_state = "decorated_gbucket"
	prevent_crits = ALL_CRITICAL_HITS
	item_weight = 4 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/decorated/golden/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!picked)
		var/list/icons = HELMET_GOLD_DECORATIONS
		var/choice = input(user, "Choose a crest.", "Knightly crests") in icons
		var/playerchoice = icons[choice]
		picked = TRUE
		icon_state = playerchoice
		item_state = playerchoice
		update_appearance(UPDATE_ICON)
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/head/helmet/heavy/decorated/bascinet
	name = "bascinet"
	desc = "A simple steel helmet that can be decorated with a crest. Somewhat basic, but you'll be the envy of those who cannot afford such a fancy helmet."
	icon_state = "decorated_bascinet"
	flags_inv = HIDEEARS
	sellprice = VALUE_STEEL_HELMET
	equip_delay_self = 2 SECONDS
	unequip_delay_self = 2 SECONDS
	block2add = null

	body_parts_covered = HEAD|HAIR|EARS
	item_weight = 3.25 KILOGRAMS

/obj/item/clothing/head/helmet/heavy/decorated/bascinet/attack_hand_secondary(mob/user, list/modifiers)
	. = ..()
	if(. == SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN)
		return
	if(!picked)
		var/list/icons = BASCINET_DECORATIONS
		var/choice = input(user, "Choose a crest.", "Knightly crests") in icons
		var/playerchoice = icons[choice]
		picked = TRUE
		icon_state = playerchoice
		item_state = playerchoice
		update_appearance(UPDATE_OVERLAYS)
		if(loc == user && ishuman(user))
			var/mob/living/carbon/H = user
			H.update_inv_head()
		return SECONDARY_ATTACK_CANCEL_ATTACK_CHAIN

/obj/item/clothing/head/helmet/heavy/ordinatorhelm
	name = "inquisitorial ordinator's helmet"
	desc = "A design suggested by a Darkholdian smith, inspired by an eccentric count who insisted on sleeping in a coffin. A steel casket with thin slits that allow for deceptively clear vision. The tainted will drown in the blood you bring their way, while this high helm keeps it out of your face."
	icon_state = "ordinatorhelm"
	item_state = "ordinatorhelm"
	worn_x_dimension = 64
	worn_y_dimension = 64
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/64x64/head.dmi'
	bloody_icon = 'icons/effects/blood64x64.dmi'
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	adjustable = CAN_CADJUST
	block2add = FOV_BEHIND
	max_integrity = ARMOR_INT_HELMET_HEAVY_STEEL - ARMOR_INT_HELMET_HEAVY_ADJUSTABLE_PENALTY
	var/plumed = FALSE

/obj/item/clothing/head/helmet/heavy/ordinatorhelm/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	if(!istype(tool, /obj/item/natural/feather))
		return NONE

	user.visible_message(span_warning("[user] starts to fashion plumage using [tool] for [src]."))
	if(do_after(user, 4 SECONDS))
		var/obj/item/clothing/head/helmet/heavy/ordinatorhelm/plume/P = new(get_turf(user))
		if(user.is_holding(src))
			user.dropItemToGround(src)
			user.put_in_hands(P)
		P.update_integrity(get_integrity())
		qdel(src)
		qdel(tool)

	return ITEM_INTERACT_SUCCESS

/obj/item/clothing/head/helmet/heavy/ordinatorhelm/plume
	icon_state = "ordinatorhelmplume"
	item_state = "ordinatorhelmplume"

/obj/item/clothing/head/helmet/heavy/ordinatorhelm/plume/item_interaction(mob/living/user, obj/item/tool, list/modifiers)
	return NONE

/obj/item/clothing/head/helmet/heavy/absolver
	name = "exotic conical helm"
	desc = "Its shape confounds and confuses the enemies of Ao. Offering unfound protection in its visage, the gaze is horrific to those without understanding."
	icon_state = "absolutionisthelm"
	item_state = "absolutionisthelm"
	emote_environment = 3
	block2add = null
	body_parts_covered = FULL_HEAD|NECK
	max_integrity = 450 // bespoke integrity: intentional (special item)
	worn_x_dimension = 64
	worn_y_dimension = 64
	mob_overlay_icon = 'icons/roguetown/clothing/onmob/64x64/head.dmi'
	bloody_icon = 'icons/effects/blood64x64.dmi'
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	clothing_flags = NONE

/obj/item/clothing/head/helmet/heavy/psybucket
	name = "exotic bucket helmet"
	desc = "Originally just a bucket with a psycross nailed on, it proved surprisingly effective, making its way into common use for inquisitorial templars. Steel encapsulates your head, and His cross facing enemies reminds them that you will endure until they meet oblivion. Only then may you rest."
	icon_state = "psybucket"
	item_state = "psybucket"
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	adjustable = CAN_CADJUST
	block2add = FOV_BEHIND
	max_integrity = ARMOR_INT_HELMET_HEAVY_STEEL

/obj/item/clothing/head/helmet/heavy/psysallet
	name = "exotic sallet"
	desc = "A boiled leather cap, crowned with steel and veiled with His cross. Fear not - He will show you the way, and He will see your blows well-struck."
	icon_state = "psysallet"
	item_state = "psysallet"
	flags_inv = HIDEEARS|HIDEFACE|HIDEHAIR
	adjustable = CAN_CADJUST
	block2add = FOV_BEHIND
	max_integrity = ARMOR_INT_HELMET_HEAVY_STEEL
