// These three recipes are functional prototype entries using existing item
// types from the current codebase. Their costs/fees/times are initial tuning
// values, not a finalized faction balance pass.

/datum/technician_recipe/iron_chisel
	required_station_service = "metalworking"
	name = "Iron Chisel"
	category = "Tools&Ammo"
	desc = "A simple iron chisel produced by the faction workshop."
	created_item = /obj/item/weapon/chisel/iron
	resource_costs = list(
		"iron" = 2,
	)
	service_fee = 2
	craft_time = 20 SECONDS

/datum/technician_recipe/arrow
	required_station_service = "metalworking"
	name = "Arrows"
	category = "Tools&Ammo"
	desc = "Five hunting arrows. Does it matter, who are you hunting: the beast or a criminal?"
	created_item = /obj/item/ammo_casing/caseless/arrow
	output_amount = 5
	resource_costs = list(
		"iron" = 1,
		"wood" = 1
	)
	service_fee = 20
	craft_time = 55 SECONDS

/datum/technician_recipe/arrow/pyro
	required_station_service = "metalworking"
	name = "Incendiary Arrows"
	category = "Tools&Ammo"
	desc = "Five pyro arrows. Does it matter, what will be with them after you are done?"
	created_item = /obj/item/ammo_casing/caseless/arrow/pyro
	output_amount = 5
	resource_costs = list(
		"iron" = 1,
		"wood" = 1,
		"blastpowder" = 1
	)
	service_fee = 20
	craft_time = 55 SECONDS

/datum/technician_recipe/crossbow_bolt
	required_station_service = "metalworking"
	name = "Crossbow bolts"
	category = "Tools&Ammo"
	desc = "Five crossbow bolts. Designed for maximum penetration and stopping power."
	created_item = /obj/item/ammo_casing/caseless/bolt
	output_amount = 5
	resource_costs = list(
		"iron" = 1,
		"wood" = 1
	)
	service_fee = 25
	craft_time = 60 SECONDS

/datum/technician_recipe/crossbow_bolt/pyro
	required_station_service = "metalworking"
	name = "Incendiary Crossbow bolts"
	category = "Tools&Ammo"
	desc = "Five crossbow bolts. Designed for maximum damage when there is no need to hesitate."
	created_item = /obj/item/ammo_casing/caseless/bolt/pyro
	output_amount = 5
	resource_costs = list(
		"iron" = 1,
		"wood" = 1,
		"blastpowder" = 1,
	)
	service_fee = 25
	craft_time = 60 SECONDS

/datum/technician_recipe/tinballs
	required_station_service = "metalworking"
	name = "Lead balls"
	category = "Tools&Ammo"
	desc = "Five lead balls. Fits every musket out there."
	created_item = /obj/item/ammo_casing/caseless/bullet
	output_amount = 5
	resource_costs = list(
		"tin" = 1,
	)
	service_fee = 20
	craft_time = 55 SECONDS

/datum/technician_recipe/crafted_mantrap
	required_station_service = "metalworking"
	name = "Crafted Mantrap"
	category = "Traps&Devices"
	desc = "A crude but functional spring-loaded mantrap."
	created_item = /obj/item/restraints/legcuffs/beartrap/crafted
	resource_costs = list(
		"iron" = 2,
	)
	service_fee = 5
	craft_time = 35 SECONDS

/datum/technician_recipe/net
	name = "Rope net"
	category = "Traps&Devices"
	desc = "A rope mesh of designed to slow a person down."
	created_item = /obj/item/rope/net
	resource_costs = list(
		"fiber" = 12,
	)
	service_fee = 5
	craft_time = 35 SECONDS

/datum/technician_recipe/bola
	name = "Bola"
	category = "Traps&Devices"
	desc = "A crude but functional bola. Takes time to spin, but works well for entangling a target's legs."
	created_item = /obj/item/rope/net/bola
	resource_costs = list(
		"stone" = 3,
		"fiber" = 8,
	)
	service_fee = 10
	craft_time = 35 SECONDS

/datum/technician_recipe/bola/electro
	required_station_service = "metalworking"
	name = "Shock Bola"
	category = "Traps&Devices"
	desc = "A crude but functional bola. Takes time to spin, stuns the opponent upon impact. Cruel."
	created_item = /obj/item/rope/net/bola/electro
	resource_costs = list(
		"stone" = 3,
		"fiber" = 8,
		"steel" = 1,
	)
	service_fee = 120
	craft_time = 60 SECONDS

/datum/technician_recipe/bola/chain
	required_station_service = "metalworking"
	name = "Chain Bola"
	category = "Traps&Devices"
	desc = "A bola, made of iron chains and metal. Less than lethal option."
	created_item = /obj/item/rope/net/bola/chain
	resource_costs = list(
		"tin" = 2,
		"iron" = 1,
	)
	service_fee = 25
	craft_time = 35 SECONDS

/datum/technician_recipe/bola/thaumic
	required_station_service = "metalworking"
	name = "Thaumaturgical Bola"
	category = "Traps&Devices"
	desc = "A crude but functional bola. Drains victim's mana upon hit."
	created_item = /obj/item/rope/net/bola/thaum
	resource_costs = list(
		"thaumic_iron" = 1,
		"fiber" = 8,
	)
	service_fee = 25 //It is already challenge to get thaumic iron, so the fee is not too high.
	craft_time = 35 SECONDS

/datum/technician_recipe/bola/silver
	required_station_service = "metalworking"
	name = "Silver Bola"
	category = "Traps&Devices"
	desc = "A bola, made of silver. Great for all werewolves and vampires."
	created_item = /obj/item/rope/net/bola/silver
	resource_costs = list(
		"silver" = 2,
		"fiber" = 8,
	)
	service_fee = 25
	craft_time = 35 SECONDS

/datum/technician_recipe/throwable_anti_magic_field
	required_station_service = "metalworking"
	name = "Throwable Anti-Magic Field"
	category = "Traps&Devices"
	desc = "A throwable device that creates an anti-magic field upon impact."
	created_item = /obj/item/rope/net/bola/mantrap/anti_magic_field
	resource_costs = list(
		"silver" = 2,
		"steel" = 2,
	)
	service_fee = 45
	craft_time = 35 SECONDS

/datum/technician_recipe/iron_keyrings
	required_station_service = "metalworking"
	name = "Iron Keyrings"
	category = "Equipment"
	desc = "A small batch of three iron keyrings."
	created_item = /obj/item/storage/keyring
	output_amount = 3
	resource_costs = list(
		"iron" = 1,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/quiver
	required_station_service = "sewing"
	name = "Quiver"
	category = "Equipment"
	desc = "A leather quiver for holding arrows and bolts."
	created_item = /obj/item/ammo_holder/quiver
	output_amount = 1
	resource_costs = list(
		"cured" = 4,
		"fiber" = 2,
	)
	service_fee = 25
	craft_time = 55 SECONDS

/datum/technician_recipe/rope
	name = "Rope"
	category = "Equipment"
	desc = "A length of sturdy rope."
	created_item = /obj/item/rope
	output_amount = 1
	resource_costs = list(
		"fiber" = 4,
	)
	service_fee = 5
	craft_time = 25 SECONDS

/datum/technician_recipe/chain
	required_station_service = "metalworking"
	name = "Chain"
	category = "Equipment"
	desc = "A short, sturdy length of chain produced by the workshop."
	created_item = /obj/item/rope/chain
	output_amount = 3
	resource_costs = list(
		"iron" = 1,
	)
	service_fee = 10
	craft_time = 20 SECONDS

/datum/technician_recipe/gold_chain
	required_station_service = "metalworking"
	name = "Gold Chain"
	category = "Equipment"
	desc = "A short, sturdy length of gold chain produced by the workshop. Weak, but easier to put on."
	created_item = /obj/item/rope/chain/gold
	output_amount = 3
	resource_costs = list(
		"gold" = 1,
	)
	service_fee = 10
	craft_time = 40 SECONDS

/datum/technician_recipe/silver_chain
	required_station_service = "metalworking"
	name = "Silver Chain"
	category = "Equipment"
	desc = "A short, sturdy length of silver chain. Weakens the cryptids, who are allergic to it."
	created_item = /obj/item/rope/chain/silver
	output_amount = 3
	resource_costs = list(
		"silver" = 1,
	)
	service_fee = 10
	craft_time = 30 SECONDS

/datum/technician_recipe/leash/chain
	required_station_service = "metalworking"
	name = "Chain leash"
	category = "Punishment"
	desc = "A leash made of iron chain. Used to restrain prisoners and criminals."
	created_item = /obj/item/leash/chain
	output_amount = 1
	resource_costs = list(
		"iron" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/leash/collar
	name = "Collar chain leash"
	category = "Punishment"
	desc = "A chain with a clasp sized for a leather collar or body harness."
	created_item = /obj/item/leash/chain/bdsm
	output_amount = 1
	resource_costs = list(
		"iron" = 2,
		"cured" = 1,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/gag/bdsm
	name = "Gag"
	category = "Punishment"
	desc = "A fitted leather gag with adjustable straps."
	created_item = /obj/item/clothing/face/bdsm_gag/basic
	output_amount = 1
	resource_costs = list(
		"fiber" = 1,
		"cured" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/gag/muzzle/black
	name = "Black muzzle"
	category = "Punishment"
	desc = "A fitted leather muzzle with adjustable straps."
	created_item = /obj/item/clothing/face/bdsm_gag/muzzle/black
	output_amount = 1
	resource_costs = list(
		"fiber" = 1,
		"cured" = 1,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/gag/muzzle/brown
	name = "Brown muzzle"
	category = "Punishment"
	desc = "A fitted leather muzzle with adjustable straps."
	created_item = /obj/item/clothing/face/bdsm_gag/muzzle/brown
	output_amount = 1
	resource_costs = list(
		"fiber" = 1,
		"cured" = 1,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/gag/muzzle/ballgag/black
	name = "Black ball gag"
	category = "Punishment"
	desc = "A fitted leather muzzle with adjustable straps."
	created_item = /obj/item/clothing/face/bdsm_gag/ball/black
	output_amount = 1
	resource_costs = list(
		"fiber" = 4,
		"cured" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/gag/muzzle/ballgag/brown
	name = "Brown ball gag"
	category = "Punishment"
	desc = "A fitted leather muzzle with adjustable straps."
	created_item = /obj/item/clothing/face/bdsm_gag/ball/brown
	output_amount = 1
	resource_costs = list(
		"fiber" = 4,
		"cured" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/gag/muzzle/ringgag/black
	name = "Black ball gag"
	category = "Punishment"
	desc = "A fitted leather muzzle with adjustable straps."
	created_item = /obj/item/clothing/face/bdsm_gag/ring/black
	output_amount = 1
	resource_costs = list(
		"iron" = 1,
		"cured" = 2,
	)
	service_fee = 20
	craft_time = 25 SECONDS

/datum/technician_recipe/gag/muzzle/ringgag/brown
	name = "Brown ball gag"
	category = "Punishment"
	desc = "A fitted leather muzzle with adjustable straps."
	created_item = /obj/item/clothing/face/bdsm_gag/ring/brown
	output_amount = 1
	resource_costs = list(
		"iron" = 1,
		"cured" = 2,
	)
	service_fee = 20
	craft_time = 25 SECONDS

/datum/technician_recipe/collar/black
	name = "Black leather collar"
	category = "Punishment"
	desc = "A fitted leather collar with adjustable straps."
	created_item = /obj/item/clothing/neck/leathercollar/bdsm/black
	output_amount = 3
	resource_costs = list(
		"iron" = 1,
		"cured" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/collar/brown
	name = "Black leather collar"
	category = "Punishment"
	desc = "A fitted leather collar with adjustable straps."
	created_item = /obj/item/clothing/neck/leathercollar/bdsm/brown
	output_amount = 1
	resource_costs = list(
		"iron" = 1,
		"cured" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/collar/shackles/black
	name = "Black leather shackles"
	category = "Punishment"
	desc = "A fitted leather shackles with adjustable straps."
	created_item = /obj/item/rope/bdsm_shackles/black
	output_amount = 1
	resource_costs = list(
		"iron" = 1,
		"cured" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/collar/shackles/brown
	name = "Brown leather shackles"
	category = "Punishment"
	desc = "A fitted leather shackles with adjustable straps."
	created_item = /obj/item/rope/bdsm_shackles/brown
	output_amount = 1
	resource_costs = list(
		"iron" = 1,
		"cured" = 2,
	)
	service_fee = 10
	craft_time = 25 SECONDS

/datum/technician_recipe/didlo/plug/iron
	name = "Iron buttplug"
	category = "Punishment"
	desc = "A fitted punishment for someone who needs to know their place. Now in iron!"
	created_item = /obj/item/dildo/plug/iron
	output_amount = 3
	resource_costs = list(
		"iron" = 1,
	)
	service_fee = 10
	craft_time = 15 SECONDS

/datum/technician_recipe/didlo/plug/steel
	name = "Steel buttplug"
	category = "Punishment"
	desc = "A fitted punishment for someone who needs to know their place. Now in steel!"
	created_item = /obj/item/dildo/plug/steel
	output_amount = 3
	resource_costs = list(
		"iron" = 1,
	)
	service_fee = 10
	craft_time = 15 SECONDS

/datum/technician_recipe/didlo/plug/silver
	name = "Silver buttplug"
	category = "Punishment"
	desc = "A fitted punishment for someone who needs to know their place. Now in silver!"
	created_item = /obj/item/dildo/plug/silver
	output_amount = 3
	resource_costs = list(
		"iron" = 1,
	)
	service_fee = 10
	craft_time = 15 SECONDS

/datum/technician_recipe/didlo/plug/gold
	name = "Gold buttplug"
	category = "Punishment"
	desc = "A fitted punishment for someone who needs to know their place. Now in gold!"
	created_item = /obj/item/dildo/plug/gold
	output_amount = 3
	resource_costs = list(
		"iron" = 1,
	)
	service_fee = 10
	craft_time = 15 SECONDS

/datum/technician_recipe/didlo/plug/tail
	name = "Tail plug"
	category = "Punishment"
	desc = "A fitted punishment for someone who needs to know their place. Now with tail for proper gripping!"
	created_item = /obj/item/dildo/plug/tail
	output_amount = 1
	resource_costs = list(
		"iron" = 1,
		"wood" = 1,
	)
	service_fee = 15
	craft_time = 15 SECONDS
