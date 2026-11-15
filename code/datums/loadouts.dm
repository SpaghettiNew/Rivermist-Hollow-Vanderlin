GLOBAL_LIST_EMPTY(loadout_items)

/datum/loadout_item
	abstract_type = /datum/loadout_item
	/// Visible name for selection
	var/name = "Parent loadout datum"
	/// Visible description for item
	var/description
	/// Path to the item to spawn
	var/item_path
	/// Typepath of a /datum/award that must be unlocked to use this loadout item. Null = no requirement.
	var/required_award = null
	var/point_cost = 0
	var/keep_loadout_stats = FALSE	// If TRUE, item keeps default values (not nerfed)


/// Returns TRUE if the given client has satisfied this loadout item's award requirement.
/datum/loadout_item/proc/is_unlocked_for(client/C)
	if(!required_award)
		return TRUE
	if(!C?.player_details?.achievements)
		return FALSE
	var/datum/award/A = SSachievements.awards[required_award]
	if(!A)
		return FALSE
	if(istype(A, /datum/award/achievement/progress))
		var/datum/award/achievement/progress/PA = A
		return C.player_details.achievements.get_achievement_status(required_award) >= PA.required_progress
	if(istype(A, /datum/award/achievement))
		return C.player_details.achievements.get_achievement_status(required_award) == TRUE
	if(istype(A, /datum/award/score))
		return C.player_details.achievements.get_achievement_status(required_award) > 0
	return FALSE


/datum/loadout_item/New()
	if (point_cost)
		description += "Costs [point_cost] Points."

/datum/loadout_item/proc/nobility_check(mob/C)
	// Override this in subtypes that require nobility
	return TRUE
//Miscellaneous

/datum/loadout_item/card_deck
	name = "Card Deck"
	item_path = /obj/item/toy/cards/deck

/datum/loadout_item/rosa_bouquet
	name = "Rosa Bouquet"
	item_path = /obj/item/bouquet/rosa

/datum/loadout_item/salvia_bouquet
	name = "Salvia Bouquet"
	item_path = /obj/item/bouquet/salvia

/datum/loadout_item/matricaria_bouquet
	name = "Matricaria Bouquet"
	item_path = /obj/item/bouquet/matricaria

/datum/loadout_item/calendula_bouquet
	name = "Calendula Bouquet"
	item_path = /obj/item/bouquet/calendula

/datum/loadout_item/cane
	name = "Wooden Cane"
	item_path = /obj/item/weapon/mace/cane
	point_cost = 1

/datum/loadout_item/natural_cane
	name = "Natural Wooden Cane"
	item_path = /obj/item/weapon/mace/cane/natural
	point_cost = 1

/datum/loadout_item/keyring
	name = "Key Ring"
	item_path = /obj/item/storage/keyring
	point_cost = 3

/datum/loadout_item/wooden_bowl
	name = "bowl"
	item_path = /obj/item/reagent_containers/glass/bowl
	point_cost = 1

/datum/loadout_item/wooden_cup
	name = "cup"
	item_path = /obj/item/reagent_containers/glass/cup/wooden
	point_cost = 1

/datum/loadout_item/bottle
	name = "bottle"
	item_path = /obj/item/reagent_containers/glass/bottle
	point_cost = 1

/datum/loadout_item/waterskin
	name = "Waterskin"
	item_path = /obj/item/reagent_containers/glass/bottle/waterskin
	point_cost = 2

/datum/loadout_item/flint
	name = "Flint"
	item_path = /obj/item/flint
	point_cost = 2

/datum/loadout_item/bandage_roll
	name = "Roll of Bandages"
	item_path = /obj/item/natural/bundle/cloth/bandage/full
	point_cost = 3

/datum/loadout_item/sack
	name = "Sack"
	item_path = /obj/item/storage/sack
	point_cost = 2

/datum/loadout_item/soap
	name = "Bar of Soap"
	item_path = /obj/item/soap
	point_cost = 1

//HATS
/datum/loadout_item/zalad
	name = "Keffiyeh"
	item_path = /obj/item/clothing/neck/keffiyeh

/datum/loadout_item/turban
	name = "Turban"
	item_path = /obj/item/clothing/head/turban

/datum/loadout_item/rosa_flower_crown
	name = "Rosa Flower Crown"
	item_path = /obj/item/clothing/head/flowercrown/rosa

/datum/loadout_item/salvia_flower_crown
	name = "Salvia Flower Crown"
	item_path = /obj/item/clothing/head/flowercrown/salvia

/datum/loadout_item/strawhat
	name = "Straw Hat"
	item_path = /obj/item/clothing/head/strawhat

/datum/loadout_item/witchhat
	name = "Witch Hat"
	item_path = /obj/item/clothing/head/wizhat/witch

/datum/loadout_item/bardhat
	name = "Bard Hat"
	item_path = /obj/item/clothing/head/bardhat

/datum/loadout_item/fancyhat
	name = "Fancy Hat"
	item_path = /obj/item/clothing/head/fancyhat

/datum/loadout_item/furhat
	name = "Fur Hat"
	item_path = /obj/item/clothing/head/hatfur


/datum/loadout_item/headband
	name = "Headband"
	item_path = /obj/item/clothing/head/headband

/datum/loadout_item/nunveil
	name = "Nun Veil"
	item_path = /obj/item/clothing/head/nun

/datum/loadout_item/papakha
	name = "Papakha"
	item_path = /obj/item/clothing/head/papakha

//CLOAKS
/datum/loadout_item/tabard
	name = "Tabard"
	item_path = /obj/item/clothing/cloak/tabard

/datum/loadout_item/surcoat
	name = "Surcoat"
	item_path = /obj/item/clothing/cloak/stabard

/datum/loadout_item/jupon
	name = "Jupon"
	item_path = /obj/item/clothing/cloak/stabard/jupon

/datum/loadout_item/cape
	name = "Cape"
	item_path = /obj/item/clothing/cloak/cape

/datum/loadout_item/halfcloak
	name = "Halfcloak"
	item_path = /obj/item/clothing/cloak/half

/datum/loadout_item/volfmantle
	name = "Wolf Mantle"
	item_path = /obj/item/clothing/cloak/volfmantle

/datum/loadout_item/sash
	name = "Cloth Sash"
	item_path = /obj/item/clothing/shirt/undershirt/sash/colored/random

/datum/loadout_item/poncho
	name = "Cloth Poncho"
	item_path = /obj/item/clothing/cloak/poncho

/datum/loadout_item/vest
	name = "Cloth Vest"
	item_path = /obj/item/clothing/shirt/clothvest/colored

/datum/loadout_item/wicker
	name = "Wicker Cloak"
	item_path = /obj/item/clothing/cloak/wickercloak

/datum/loadout_item/shredded
	name = "Shredded Cloak"
	item_path = /obj/item/clothing/cloak/shredded

//SHOES

/datum/loadout_item/babouche
	name = "Babouche"
	item_path = /obj/item/clothing/shoes/shalal

/datum/loadout_item/sandals
	name = "Sandals"
	item_path = /obj/item/clothing/shoes/sandals

/datum/loadout_item/gladsandals
	name = "Gladiatorial Sandals"
	item_path = /obj/item/clothing/shoes/gladiator

/datum/loadout_item/ankletscloth
	name = "Cloth Anklets"
	item_path = /obj/item/clothing/shoes/boots/clothlinedanklets

//SHIRTS

/datum/loadout_item/robe
	name = "Robe"
	item_path = /obj/item/clothing/shirt/robe

/datum/loadout_item/shortshirt
	name = "Short-sleeved Shirt"
	item_path = /obj/item/clothing/shirt/shortshirt

/datum/loadout_item/sailorshirt
	name = "Striped Shirt"
	item_path = /obj/item/clothing/shirt/undershirt/sailor

/datum/loadout_item/bottomtunic
	name = "Low-cut Tunic"
	item_path = /obj/item/clothing/shirt/undershirt/lowcut

/datum/loadout_item/tunic
	name = "Tunic"
	item_path = /obj/item/clothing/shirt/tunic/colored/random

/datum/loadout_item/dress
	name = "Dress"
	item_path = /obj/item/clothing/shirt/dress/gen

/datum/loadout_item/bardress
	name = "Bar Dress"
	item_path = /obj/item/clothing/shirt/dress

/datum/loadout_item/nun_habit
	name = "Nun Habit"
	item_path = /obj/item/clothing/shirt/robe/nun

//PANTS
/datum/loadout_item/tights
	name = "Cloth Tights"
	item_path = /obj/item/clothing/pants/tights

/datum/loadout_item/sailorpants
	name = "Seafaring Pants"
	item_path = /obj/item/clothing/pants/tights/sailor

/datum/loadout_item/skirt
	name = "Skirt"
	item_path = /obj/item/clothing/pants/skirt

//ACCESSORIES

/datum/loadout_item/wrappings
	name = "Handwraps"
	item_path = /obj/item/clothing/wrists/wrappings

/datum/loadout_item/loincloth
	name = "Loincloth"
	item_path = /obj/item/clothing/pants/loincloth

/datum/loadout_item/fingerless
	name = "Fingerless Gloves"
	item_path = /obj/item/clothing/gloves/fingerless

/datum/loadout_item/feather
	name = "Feather"
	item_path = /obj/item/natural/feather

/datum/loadout_item/collar
	name = "Collar"
	item_path = /obj/item/clothing/neck/leathercollar

/datum/loadout_item/bell_collar
	name = "Bell Collar"
	item_path = /obj/item/clothing/neck/bellcollar

/datum/loadout_item/chaperon
	name = "Chaperon (Normal)"
	item_path = /obj/item/clothing/head/chaperon

/datum/loadout_item/jesterhat
	name = "Jester's Hat"
	item_path = /obj/item/clothing/head/jester

/datum/loadout_item/jestertunick
	name = "Jester's Tunick"
	item_path = /obj/item/clothing/shirt/jester

/datum/loadout_item/jestershoes
	name = "Jester's Shoes"
	item_path = /obj/item/clothing/shoes/jester

/datum/loadout_item/leash
	name = "Leash"
	item_path = /obj/item/leash/leather
	point_cost = 2

/datum/loadout_item/catbell
	name = "Catbell"
	item_path = /obj/item/catbell

/datum/loadout_item/cowbell
	name = "Cowbell"
	item_path = /obj/item/catbell/cow

/datum/loadout_item/bellyriding_harness
	name = "Bellyriding Harness"
	item_path = /obj/item/clothing/armor/bellyriding_harness

//FACE

/datum/loadout_item/ragmask
	name = "Halfmask"
	item_path = /obj/item/clothing/face/shepherd/rag

/datum/loadout_item/fancy_spectacles
	name = "Fancy Spectacles"
	item_path = /obj/item/clothing/face/spectacles/fancy
	point_cost = 3

/datum/loadout_item/fancy_spectacles_d
	name = "Fancy Spectacles (Dark)"
	item_path = /obj/item/clothing/face/spectacles/fancy_dark
	point_cost = 3

// CLOTHING - DRESSES & ROBES
/datum/loadout_item/tri_ornate_dress
	name = "Ornate Dress"
	item_path = /obj/item/clothing/shirt/dress/silkdress/colored
	point_cost = 3

/datum/loadout_item/tri_princess_dress/nobility_check(mob/C)
	var/datum/preferences/P = C?.client?.prefs
	if(!P)
		return FALSE
	// Check if user selected Nobility virtue
	if(HAS_TRAIT(P, TRAIT_NOBLE))
		return TRUE
	// Check if user has high priority for any noble, courtier, or yeoman job
	for(var/job_title in GLOB.lords_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	for(var/job_title in GLOB.keep_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	for(var/job_title in GLOB.townhall_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	return FALSE

/datum/loadout_item/tri_ornate_tunic
	name = "Ornate Tunic"
	item_path = /obj/item/clothing/shirt/tunic/silktunic
	point_cost = 3

/datum/loadout_item/tri_lady_cloak
	name = "Lady's Cloak"
	item_path = /obj/item/clothing/cloak/lordcloak/ladycloak
	point_cost = 3

/datum/loadout_item/tri_lady_cloak/nobility_check(mob/C)
	var/datum/preferences/P = C?.client?.prefs
	if(!P)
		return FALSE
	// Check if user selected Nobility virtue
	if(HAS_TRAIT(P, TRAIT_NOBLE))
		return TRUE
	// Check if user has high priority for any noble, courtier, or yeoman job
	for(var/job_title in GLOB.lords_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	for(var/job_title in GLOB.keep_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	for(var/job_title in GLOB.townhall_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	return FALSE

// CLOTHING - HEADWEAR
/datum/loadout_item/tri_circlet
	name = "Circlet"
	item_path = /obj/item/clothing/head/crown/circlet
	point_cost = 3

/datum/loadout_item/tri_circlet/nobility_check(mob/C)
	var/datum/preferences/P = C?.client?.prefs
	if(!P)
		return FALSE
	// Check if user selected Nobility virtue
	if(HAS_TRAIT(P, TRAIT_NOBLE))
		return TRUE
	// Check if user has high priority for any noble, courtier, or yeoman job
	for(var/job_title in GLOB.lords_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	for(var/job_title in GLOB.keep_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	for(var/job_title in GLOB.townhall_positions)
		if(P.job_preferences[job_title] == JP_HIGH)
			return TRUE
	return FALSE

// GUIDES

/datum/loadout_item/alch_recipes
	name = "Guide to Alchemy"
	item_path = /obj/item/recipe_book/alchemy

/datum/loadout_item/leather_recipes
	name = "Guide to Leatherworking"
	item_path = /obj/item/recipe_book/leatherworking

/datum/loadout_item/sewing_recipes
	name = "Guide to Tailoring"
	item_path = /obj/item/recipe_book/sewing

/datum/loadout_item/smith_recipes
	name = "Guide to Smithing"
	item_path = /obj/item/recipe_book/blacksmithing

/datum/loadout_item/engi_recipes
	name = "Guide to Engineering"
	item_path = /obj/item/recipe_book/engineering

/datum/loadout_item/survival_recipes
	name = "Guide to Survival"
	item_path = /obj/item/recipe_book/survival

/datum/loadout_item/cooking_recipes
	name = "Guide to Cooking"
	item_path = /obj/item/recipe_book/cooking

//COSMETICS (Perfumes & Lipsticks)

/datum/loadout_item/perfume_lavender
	name = "Lavender Perfume"
	item_path = /obj/item/perfume/lavender
	point_cost = 2

/datum/loadout_item/perfume_cherry
	name = "Cherry Perfume"
	item_path = /obj/item/perfume/cherry
	point_cost = 2

/datum/loadout_item/perfume_rose
	name = "Rose Perfume"
	item_path = /obj/item/perfume/rose
	point_cost = 2

/datum/loadout_item/perfume_jasmine
	name = "Jasmine Perfume"
	item_path = /obj/item/perfume/jasmine
	point_cost = 2

/datum/loadout_item/perfume_mint
	name = "Mint Perfume"
	item_path = /obj/item/perfume/mint
	point_cost = 2

/datum/loadout_item/perfume_vanilla
	name = "Vanilla Perfume"
	item_path = /obj/item/perfume/vanilla
	point_cost = 2

/datum/loadout_item/perfume_strawberry
	name = "Strawberry Perfume"
	item_path = /obj/item/perfume/strawberry
	point_cost = 2

/datum/loadout_item/lipstick_red
	name = "Red Lipstick"
	item_path = /obj/item/lipstick
	point_cost = 2

/datum/loadout_item/lipstick_jade
	name = "Jade Lipstick"
	item_path = /obj/item/lipstick/jade
	point_cost = 2

/datum/loadout_item/lipstick_purple
	name = "Purple Lipstick"
	item_path = /obj/item/lipstick/purple
	point_cost = 2

/datum/loadout_item/lipstick_black
	name = "Black Lipstick"
	item_path = /obj/item/lipstick/black
	point_cost = 2

/datum/loadout_item/hair_dye
	name = "Hair Dye Cream"
	item_path = /obj/item/hair_dye_cream
	point_cost = 2

//ADDITIONAL ITEMS
/datum/loadout_item/accordion
	name = "Accordion"
	item_path = /obj/item/instrument/accord
	point_cost = 1

/datum/loadout_item/drum
	name = "Drum"
	item_path = /obj/item/instrument/drum
	point_cost = 1

/datum/loadout_item/flute
	name = "Flute"
	item_path = /obj/item/instrument/flute
	point_cost = 1

/datum/loadout_item/guitar
	name = "Guitar"
	item_path = /obj/item/instrument/guitar
	point_cost = 1

/datum/loadout_item/harp
	name = "Harp"
	item_path = /obj/item/instrument/harp
	point_cost = 1

/datum/loadout_item/hurdygurdy
	name = "Hurdy-Gurdy"
	item_path = /obj/item/instrument/hurdygurdy
	point_cost = 1

/datum/loadout_item/lute
	name = "Lute"
	item_path = /obj/item/instrument/lute
	point_cost = 1

/datum/loadout_item/psyaltery
	name = "Psyaltery"
	item_path = /obj/item/instrument/psyaltery
	point_cost = 1

/datum/loadout_item/viola
	name = "Viola"
	item_path = /obj/item/instrument/viola
	point_cost = 1

/datum/loadout_item/vocaltalisman
	name = "Vocal Talisman"
	item_path = /obj/item/instrument/vocals
	point_cost = 1


// RMH

/datum/loadout_item/thaumgloves
	name = "Alchemist Gloves"
	item_path = /obj/item/clothing/gloves/leather/thaumgloves

/datum/loadout_item/bagpack
	name = "Bagpack"
	item_path = /obj/item/storage/backpack/backpack/bagpack

/datum/loadout_item/silktunic
	name = "Ornate Silk Tunic"
	item_path = /obj/item/clothing/shirt/tunic/silktunic

/datum/loadout_item/silktunicdress
	name = "Ornate Silk Dress"
	item_path = /obj/item/clothing/shirt/tunic/silktunicdress

/datum/loadout_item/exoticsilkbra
	name = "Exotic Silk Bra"
	item_path = /obj/item/clothing/bra/exoticsilkbra

/datum/loadout_item/eastshirt1
	name = "Black Foreign Shirt"
	item_path = /obj/item/clothing/shirt/undershirt/eastshirt1

/datum/loadout_item/eastshirt2
	name = "White Foreign Shirt"
	item_path = /obj/item/clothing/shirt/undershirt/eastshirt2

/datum/loadout_item/sexy_nun_robe
	name = "Sexy Nun Robe"
	item_path = /obj/item/clothing/shirt/undershirt/sexy_nun_robe

/datum/loadout_item/sexy_nun_hat
	name = "Sexy Nun Hat"
	item_path = /obj/item/clothing/head/sexy_nun_hat

/datum/loadout_item/exoticsilkbelt
	name = "Exotic Silk Belt"
	item_path = /obj/item/storage/belt/leather/exoticsilkbelt

/datum/loadout_item/heels
	name = "High Heels"
	item_path = /obj/item/clothing/shoes/heels

/datum/loadout_item/leo_robe
	name = "Leopard Print Robe"
	item_path = /obj/item/clothing/shirt/leo_robe

/datum/loadout_item/maid_dress
	name = "Maid's Dress"
	item_path = /obj/item/clothing/shirt/maid_dress

/datum/loadout_item/nightgown
	name = "Nightgown"
	item_path = /obj/item/clothing/shirt/nightgown

/datum/loadout_item/winter_coat
	name = "Winter Coat"
	item_path = /obj/item/clothing/armor/gambeson/winter_coat

/datum/loadout_item/sophisticated_jacket
	name = "Sophisticated Jacket"
	item_path = /obj/item/clothing/armor/gambeson/sophisticated_jacket
	point_cost = 3

/datum/loadout_item/sophisticated_coat
	name = "Sophisticated Coat"
	item_path = /obj/item/clothing/armor/gambeson/sophisticated_coat
	point_cost = 3

/datum/loadout_item/corset
	name = "Corset"
	item_path = /obj/item/clothing/armor/corset/colored

/datum/loadout_item/duchess_hood
	name = "Dignified Veil"
	item_path = /obj/item/clothing/head/roguetown/duchess_hood

/datum/loadout_item/pocket_rous
	name = "Pocket Rous"
	item_path = /obj/item/reagent_containers/food/snacks/smallrat
	required_award = /datum/award/achievement/progress/rat_genocide

/datum/loadout_item/leather_apron
	name = "Leather apron"
	item_path = /obj/item/clothing/cloak/apron/brown
