/obj/item/clothing/shoes/boots
	name = "dark boots"
	//dropshrink = 0.75
	color = "#d5c2aa"
	desc = "Boots made out of darker materials. Offers light protection against melee attacks."
	gender = PLURAL
	icon_state = "blackboots"
	item_state = "blackboots"
	armor_type = /datum/armor/boots
	sellprice = 10
	salvage_result = /obj/item/natural/hide/cured
	salvage_amount = 1
	max_integrity = ARMOR_INT_SIDE_LEATHER

/obj/item/clothing/shoes/boots/apply_components()
	. = ..()
	AddComponent(/datum/component/storage/concrete/boots)

/obj/item/clothing/shoes/boots/armor
	name = "plated boots"
	desc = "Armored boots made from steel offering heavy protection against both melee and ranged attacks."
	body_parts_covered = FEET
	icon_state = "armorboots"
	item_state = "armorboots"
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_CUT, BCLASS_CHOP, BCLASS_BLUNT, BCLASS_TWIST)
	color = null
	blocksound = PLATEHIT
	armor_type = /datum/armor/boots/plate
	max_integrity = ARMOR_INT_SIDE_STEEL
	armor_class = AC_HEAVY
	clothing_flags = CANT_SLEEP_IN
	anvilrepair = /datum/attribute/skill/craft/armor_repair
	resistance_flags = FIRE_PROOF
	pickup_sound = "rustle"
	equip_sound = 'sound/foley/equip/equip_armor_plate.ogg'
	drop_sound = 'sound/foley/dropsound/armor_drop.ogg'
	break_sound = 'sound/foley/breaksound.ogg'
	sellprice = 25
	item_weight = 2.1 KILOGRAMS

	material_category = ARMOR_MAT_PLATE

/obj/item/clothing/shoes/boots/armor/light
	name = "light plate boots"
	icon_state = "soldierboots"
	item_state = "soldierboots"
	desc = "Lightly armored boots made from iron offering protection against both melee and ranged attacks."
	armor_type = /datum/armor/boots/brigandine
	max_integrity = ARMOR_INT_SIDE_IRON
	armor_class = AC_MEDIUM
	sellprice = 20
	item_weight = 1.4 KILOGRAMS

/obj/item/clothing/shoes/boots/armor/ironmaille
	name = "chainmail boots"
	icon_state = "mailleboots"
	item_state = "mailleboots"
	desc = "Chainmail boots made from iron and cured leather, they offer a good protection for their cheap cost."
	armor_type = /datum/armor/boots/maille/iron
	max_integrity = ARMOR_INT_SIDE_DECREPIT //meant to be weaker than iron plated boots, better options are out there waiting at the smith
	armor_class = AC_LIGHT
	sellprice = VALUE_IRON_ARMOR
	item_weight = 2.7 KILOGRAMS
	smeltresult = /obj/item/fertilizer/ash //we avoid melting one piece for one bar
	melting_material = /datum/material/iron // we get one bar per two pieces of the item recovered and smelted
	melt_amount = 75

/obj/item/clothing/shoes/boots/armor/light/rust
	name = "rusted light plate boots"
	desc = "Rusted armored boots made from iron offering protection against both melee and ranged attacks. They smell stained of blood and urine."
	icon_state = "rustboots"
	icon = 'icons/roguetown/clothing/special/rust_armor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/rust_armor.dmi'
	sleeved = 'icons/roguetown/clothing/special/onmob/rust_armor.dmi'
	smeltresult = /obj/item/ingot/iron
	melting_material = /datum/material/iron
	melt_amount = 100
	sellprice = VALUE_IRON_ARMOR/2
	armor_type = /datum/armor/boots/plate/bad
	max_integrity = ARMOR_INT_SIDE_DECREPIT

/obj/item/clothing/shoes/boots/armor/blkknight
	name = "blacksteel boots"
	desc = "Boots forged from blacksteel, light yet strong, perfect for a fearless stride."
	icon_state = "bkboots"
	icon = 'icons/roguetown/clothing/special/blkknight.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/blkknight.dmi'
	sleeved = 'icons/roguetown/clothing/special/onmob/blkknight.dmi'
	anvilrepair = /datum/attribute/skill/craft/blacksmithing
	smeltresult = /obj/item/ingot/blacksteel
	melting_material = /datum/material/blacksteel
	melt_amount = 100
	armor_class = AC_MEDIUM
	armor_type = /datum/armor/boots/plate/blacksteel
	item_weight = 2.1 KILOGRAMS
	sellprice = VALUE_SILVER_ITEM * 2

/obj/item/clothing/shoes/boots/leather
	name = "leather boots"
	//dropshrink = 0.75
	desc = "Boots made out of sturdy leather. Providing light protection against melee attacks."
	prevent_crits = list(BCLASS_LASHING, BCLASS_BITE, BCLASS_TWIST)
	gender = PLURAL
	icon_state = "leatherboots"
	item_state = "leatherboots"
	armor_type = /datum/armor/boots/leather
	resistance_flags = FLAMMABLE
	sellprice = 10
	salvage_result = /obj/item/natural/hide/cured
	salvage_amount = 1
	item_weight = 1.4 KILOGRAMS
	max_integrity = ARMOR_INT_SIDE_LEATHER
	wetable = FALSE

//THE ARMOUR VALUES OF ADVANCED AND MASTERWORK BOOTS ARE INTENDED
//KEEP THIS IN MIND

/obj/item/clothing/shoes/boots/leather/advanced
	name = "hardened leather boots"
	desc = "Sturdy, durable, flexible. A marvel of the dark ages that exists solely to protect your toes."
	max_integrity = ARMOR_INT_SIDE_HARDLEATHER
	prevent_crits = list(BCLASS_CUT, BCLASS_BLUNT, BCLASS_TWIST)
	armor_type = /datum/armor/boots/leather/advanced

/obj/item/clothing/shoes/boots/leather/advanced/watch
	name = "watch boots"
	color = "#d5c2aa"
	desc = "These boots are reinforced with iron padding, designed not just for protection but for presence, announcing the approach of the city watch long before they're seen."
	icon_state = "nobleboots"
	item_state = "nobleboots"
	social_cues = list("faction:town_watch" = 5)

/obj/item/clothing/shoes/boots/leather/advanced/watch/Initialize()
	. = ..()
	AddComponent(/datum/component/squeak, custom_sounds = list(SFX_WATCH_BOOT_STEP))

/obj/item/clothing/shoes/boots/leather/masterwork
	name = "masterwork leather boots"
	desc = "These boots are a craftsmanship marvel. Made with the finest leather. Strong, nimble, reliable."
	max_integrity = ARMOR_INT_SIDE_STEEL // masterwork leather = steel-grade integrity, intended
	prevent_crits = list(BCLASS_CUT, BCLASS_BLUNT, BCLASS_TWIST, BCLASS_CHOP) //we're adding chop here!
	armor_type = /datum/armor/boots/leather/master

/obj/item/clothing/shoes/boots/leather/masterwork/Initialize()
	. = ..()
	filters += filter(type="drop_shadow", x=0, y=0, size=0.5, offset=1, color=rgb(218, 165, 32))

/obj/item/clothing/shoes/boots/furlinedboots
	name = "fur lined boots"
	desc = "Leather boots lined with fur."
	gender = PLURAL
	icon_state = "furlinedboots"
	item_state = "furlinedboots"
	sewrepair = /datum/attribute/skill/craft/tanning/patching
	armor_type = /datum/armor/boots/leather/fur
	salvage_result = /obj/item/natural/fur
	salvage_amount = 1
	item_weight = 0.9 KILOGRAMS
	min_cold_protection_temperature = -20
	wetable = FALSE

/obj/item/clothing/shoes/boots/furlinedanklets
	name = "fur lined anklets"
	desc = "Leather anklets lined with fur, foot remains bare."
	gender = PLURAL
	icon_state = "furlinedanklets"
	item_state = "furlinedanklets"
	sewrepair = /datum/attribute/skill/craft/tanning/patching
	armor_type = /datum/armor/boots/leather/fur
	is_barefoot = TRUE
	salvage_amount = 1
	salvage_result = /obj/item/natural/fur
	min_cold_protection_temperature = -20

/obj/item/clothing/shoes/boots/clothlinedanklets
	name = "cloth lined anklets"
	desc = "Cloth anklets lined with fibers, foot remains bare."
	gender = PLURAL
	icon_state = "clothlinedanklets"
	item_state = "furlinedanklets"
	is_barefoot = TRUE
	sewrepair = /datum/attribute/skill/misc/sewing/mending
	armor_type = /datum/armor/boots/anklet/cloth //Thinks its fair for a piece of cloth and fiber.
	salvage_result = /obj/item/natural/cloth
	salvage_amount = 1
	item_weight = 125 GRAMS

/obj/item/clothing/shoes/boots/armor/silver
	name = "silver boots"
	desc = "Finely forged boots made out of silver."
	icon_state = "silverboots"
	armor_type = /datum/armor/boots/plate/silver
	smeltresult = /obj/item/ingot/silver
	melting_material = /datum/material/silver
	melt_amount = 100
	item_weight = 3.4 KILOGRAMS
	sellprice = VALUE_SILVER_ITEM

/obj/item/clothing/shoes/boots/armor/silver/Initialize(mapload)
	. = ..()
	enchant(/datum/enchantment/silver)

//............... Evil Boots ............... //

/obj/item/clothing/shoes/boots/armor/zizo
	name = "darksteel boots"
	desc = "Plate boots. Called forth from the edge of what should be known. In Her name."
	icon_state = "zizoboots"
	item_state = "zizoboots"
	icon = 'icons/roguetown/clothing/special/evilarmor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	sleeved = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	sellprice = 0 // Incredibly evil Zizoid armor, this should be burnt, nobody wants this

/obj/item/clothing/shoes/boots/armor/matthios
	name = "gilded boots"
	desc = "Plate boots. A door kicked in, treasures to behold inside."
	icon_state = "matthiosboots"
	item_state = "matthiosboots"
	icon = 'icons/roguetown/clothing/special/evilarmor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	sleeved = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	sellprice = 0 // See above comment

/obj/item/clothing/shoes/boots/armor/graggar
	name = "vicious boots"
	desc = "A menacing pair of plate boots, caked in blood and brain matter. Known for crushing skulls."
	icon_state = "graggarplateboots"
	item_state = "graggarplateboots"
	icon = 'icons/roguetown/clothing/special/evilarmor.dmi'
	mob_overlay_icon = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	sleeved = 'icons/roguetown/clothing/special/onmob/evilarmor.dmi'
	sellprice = 0 // See above comment
