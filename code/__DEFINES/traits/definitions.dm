/*
Remember to update _globalvars/traits.dm if you're adding/removing/renaming traits.
*/
#define OBESITY "obesity"

// ************* atom traits
#define EAR_DAMAGE "ear_damage"

/// Prevents the affected atom from opening a loot window via alt click. See atom/AltClick()
#define TRAIT_ALT_CLICK_BLOCKER "no_alt_click"

// ************* atom movable traits

/// Is runechat for this atom/movable currently disabled, regardless of prefs or anything?
#define TRAIT_RUNECHAT_HIDDEN "runechat_hidden"
#define TRAIT_I_AM_INVISIBLE_ON_A_BOAT "invisible_on_tram"
///Trait given by /datum/element/relay_attacker
#define TRAIT_RELAYING_ATTACKER "relaying_attacker"

/// Movement type traits for movables. See elements/movetype_handler.dm
#define TRAIT_MOVE_GROUND "move_ground"
#define TRAIT_MOVE_FLYING "move_flying"
#define TRAIT_MOVE_VENTCRAWLING	"move_ventcrawling"
#define TRAIT_MOVE_FLOATING	"move_floating"
#define TRAIT_MOVE_PHASING "move_phasing"
#define TRAIT_MOVE_SWIMMING "move_swimming"
/// The atom is currently inside water deep enough to immerse it.
#define TRAIT_IMMERSED "immersed"
/// Temporarily prevents a water turf from immersing its contents.
#define TRAIT_IMMERSE_STOPPED "immerse_stopped"
/// Disables the floating animation. See above.
#define TRAIT_NO_FLOATING_ANIM "no-floating-animation"
/// Prevents rot from being applied to or processed on an item or mob.
#define TRAIT_NO_ROT "no_rot"

// ************* mob traits

/// Prevents voluntary movement.
#define TRAIT_IMMOBILIZED "immobilized"
/// Buckling yourself to objects with this trait won't immobilize you
#define TRAIT_NO_IMMOBILIZE "no_immobilize"
/// Forces the user to stay unconscious.
#define TRAIT_KNOCKEDOUT "knockedout"
/// Prevents standing or staying up on its own.
#define TRAIT_FLOORED  "floored"
/// Prevents usage of manipulation appendages (picking, holding or using items, manipulating storage).
#define TRAIT_HANDS_BLOCKED "handsblocked"
/// Inability to access UI hud elements. Turned into a trait from [MOBILITY_UI] to be able to track sources.
#define TRAIT_UI_BLOCKED "uiblocked"
/// Inability to pull things. Turned into a trait from [MOBILITY_PULL] to be able to track sources.
#define TRAIT_PULL_BLOCKED "pullblocked"
/// Makes a mob non-dense without overriding other sources, such as lying down.
#define TRAIT_UNDENSE "undense"
/// Prevents a buckled mob from controlling its carrier.
#define TRAIT_CANT_RIDE "cant_ride"
/// Suspends AI planning and execution independently of client and idle state.
#define TRAIT_AI_PAUSED "ai_paused"
/// Suspends AI movement without disabling other behaviors.
#define TRAIT_AI_MOVEMENT_HALTED "ai_movement_halted"
/// Prevents throwing items.
#define TRAIT_NO_THROWING "no_throwing"
/// Abstract condition that prevents movement if being pulled and might be resisted against. Handcuffs and straight jackets, basically.
#define TRAIT_RESTRAINED "restrained"
/// Generically incapacitated, cannot interact
#define TRAIT_INCAPACITATED	"incapacitated"
/// Can't speak
#define TRAIT_MUTE "mute"
/// Can't use emotes
#define TRAIT_EMOTEMUTE	"emotemute"
/// Speak in zombie moans
#define TRAIT_ZOMBIE_SPEECH "zombie_speech"
/// Speak garbled
#define TRAIT_GARGLE_SPEECH "gargle_speech"
/// Can't hear
#define TRAIT_DEAF "deaf"
/// Can't hear properly beyond 2 tiles
#define TRAIT_PARTIAL_DEAF "partial_deaf"
#define TRAIT_HUSK "husk"
#define TRAIT_CHUNKYFINGERS	"chunkyfingers" //means that you can't use weapons with normal trigger guards.
#define TRAIT_ROTFINGERS "rotfingers" //means that you can't use weapons, equip armor and parry
#define TRAIT_DUMB "dumb"
#define TRAIT_MONKEYLIKE "monkeylike" //sets IsAdvancedToolUser to FALSE
/// Cannot directly bring harm to other mobs
#define TRAIT_PACIFISM	"pacifism"
/// Ignore movement speed slow mods
#define TRAIT_IGNORESLOWDOWN "ignoreslow"
/// Ignore slowdown from damage
#define TRAIT_IGNOREDAMAGESLOWDOWN "ignoredamageslowdown"
/// Causes death-like unconsciousness
#define TRAIT_DEATHCOMA	"deathcoma"
// ~BODYPART TRAITS
/// Rotten beyond salvation
#define TRAIT_ROTTEN "rotten"
/// Genetically deformed beyond salvation
#define TRAIT_DEFORMED "deformed"
/// ??? should be a signal?
#define TRAIT_SANGUINE "sanguine"
#define TRAIT_FRESHSPAWN "freshspawn"
/// The mob has the stasis effect.
/// Does nothing on its own, applied via status effect.
#define TRAIT_STASIS "in_stasis"
/// Makes the owner appear as dead to most forms of medical examination
#define TRAIT_FAKEDEATH "fakedeath"
/// "Magic" trait that blocks the mob from moving or interacting with anything. Used for transient stuff like mob transformations or incorporality in special cases.
/// Will block movement, `Life()` (!!!), and other stuff based on the mob.
#define TRAIT_NO_TRANSFORM "block_transformations"
/// Prevents werewolf antagonists from taking beast form without blocking unrelated transformations.
#define TRAIT_WEREWOLF_TRANSFORMATION_SUPPRESSED "werewolf_transformation_suppressed"
/// Blocker trait for hardcore quirk users
#define TRAIT_HARDCORE_PROFANE	"hardcore_profane"
/// Weak to inquisition torture
#define TRAIT_TORTURED "tortured"
/// Prone to heart failure with high stress
#define TRAIT_WEAK_HEART "weak_heart"
/// Blood always counts as no lux
#define TRAIT_TAINTED_LUX "tainted_lux"
/// Crafting is 10% faster
#define TRAIT_QUICK_HANDS "quick_hands"
/// Heeled shoes cost no Speed and never trip
#define TRAIT_HEEL_WALKER "heel_walker"
/// Immunity to stunning effects
#define TRAIT_STUNIMMUNE "stun_immunity"
/// Stun duration reduced (unused)
#define TRAIT_STUNRESISTANCE "stun_resistance"
/// Immunity to sleep
#define TRAIT_SLEEPIMMUNE "sleep_immunity"
/// Can't be pushed
#define TRAIT_PUSHIMMUNE "push_immunity"
/// Doesn't need a heart
#define TRAIT_STABLEHEART "stable_heart"
/// Can't be stunned from pain
#define TRAIT_NOPAINSTUN "no_pain-stun"
/// Resists high temperatures
#define TRAIT_RESISTHEAT "resist_heat"
/// Can hold hot things
#define TRAIT_RESISTHEATHANDS "resist_heat_handsonly"
/// Resists low temperatures
#define TRAIT_RESISTCOLD "resist_cold"
/// Resist high pressure enviroments (unused with no atmos)
#define TRAIT_RESISTHIGHPRESSURE "resist_high_pressure"
/// Resist low pressure enviroments (unused with no atmos)
#define TRAIT_RESISTLOWPRESSURE	"resist_low_pressure"
/// This human is immune to the effects of being exploded. (ex_act)
#define TRAIT_BOMBIMMUNE "bomb_immunity"
/// Immunity against germs and viruses crippled
#define TRAIT_IMMUNITY_CRIPPLED "immunity_crippled"
/// Immune to radiation
#define TRAIT_RADIMMUNE "rad_immunity"
/// Skin is not possible to pierce (needles, embeds)
#define TRAIT_PIERCEIMMUNE "pierce_immunity"
/// Higher thresholds for dismemberment
#define TRAIT_HARDDISMEMBER "hard_dismember"
/// Lower thresholds for dismemberment
#define TRAIT_EASYDISMEMBER "easy_dismember"
/// Limbs can't be dismembered
#define TRAIT_NODISMEMBER "dismember_immunity"
/// Can't get fire stacks (can get DIVINE fire stacks)
#define TRAIT_NOFIRE "Nonflammable"
/// Can't use guns
#define TRAIT_NOGUNS "no_guns"
/// Doesn't use nutrition
#define TRAIT_NOHUNGER "no_hunger"
/// Internal organs do not process
#define TRAIT_NO_ORGAN_PROCESS "no_organs"
/// Doesn't use hygine
#define TRAIT_NOHYGIENE	"no_hygiene"
/// Can't metabolise reagents
#define TRAIT_NOMETABOLISM "no_metabolism"
/// Immune to toxin damage
#define TRAIT_TOXIMMUNE "toxin_immune"
/// Can reattach limbs without tools
#define TRAIT_LIMBATTACHMENT "limb_attach"
/// Limbs can't be disabled by damage
#define TRAIT_NOLIMBDISABLE	"no_limb_disable"
/// Limbs have lower damage thresholds
#define TRAIT_EASYLIMBDISABLE "easy_limb_disable"
/// In some kind of critical condition. Is able to succumb.
#define TRAIT_CRITICAL_CONDITION "critical-condition"
/// In softcrit
#define TRAIT_SOFT_CRITICAL_CONDITION "soft_critical_condition"
/// Toxin damage heals, toxin healing does damage
#define TRAIT_TOXINLOVER "toxinlover"
/// Doesn't need to breathe
#define TRAIT_NOBREATH "no_breath"
#define TRAIT_HOLY "holy"
/// Doesn't take oxy damage in crit (unused)
#define TRAIT_NOCRITDAMAGE "no_crit"
/// Doesn't slip on water (unused)
#define TRAIT_NOSLIPWATER "noslip_water"
/// Doesn't slip
#define TRAIT_NOSLIPALL "noslip_all"
/// Can't die
#define TRAIT_NODEATH "nodeath"
/// Can't enter hard crit
#define TRAIT_NOHARDCRIT "nohardcrit"
/// Can't enter soft crit
#define TRAIT_NOSOFTCRIT "nosoftcrit"
/// Shielded from mind altering effects (unused)
#define TRAIT_MINDSHIELD "mindshield"
/// Unused
#define TRAIT_DISSECTED	"dissected"
/// Can hear dead people
#define TRAIT_SIXTHSENSE "sixth_sense"
/// Immune to the effects of phobias
#define TRAIT_FEARLESS "fearless"
/// Protected from evil and good - disadvantage for matching creatures attacking this mob
#define TRAIT_PROTECTION_EVIL_GOOD "protection_evil_good"
//These are used for brain-based paralysis, where replacing the limb won't fix it
/// Brain paralysis of left arm
#define TRAIT_PARALYSIS_L_ARM "para-l-arm"
/// Brain paralysis of right arm
#define TRAIT_PARALYSIS_R_ARM "para-r-arm"
/// Brain paralysis of left leg
#define TRAIT_PARALYSIS_L_LEG "para-l-leg"
/// Brain paralysis of right leg
#define TRAIT_PARALYSIS_R_LEG "para-r-leg"
/// Can't swap with mobs not in combat mode
#define TRAIT_NOMOBSWAP "no-mob-swap"
/// Can see through opaque atoms
#define TRAIT_XRAY_VISION "xray_vision"
/// Can see mobs through opaque atoms
#define TRAIT_THERMAL_VISION "thermal_vision"
/// Immediately upgrade grabs when in combat mode
#define TRAIT_STRONG_GRABBER "strong_grabber"
/// Used for the choking status effect
#define TRAIT_MAGIC_CHOKE "magic_choke"
/// Immune to nervous cough
#define TRAIT_SOOTHED_THROAT "soothed-throat"
/// Can't lower hygiene
#define TRAIT_ALWAYS_CLEAN "always-clean"
/// Can throw reagent containers without spilling them
#define TRAIT_BOOZE_SLIDER "booze-slider"
/// Unused
#define TRAIT_QUICK_CARRY "quick-carry"
/// Unused
#define TRAIT_QUICKER_CARRY "quicker-carry"
/// Prevents the overlay from nearsighted
#define TRAIT_NEARSIGHTED_CORRECTED "fixes_nearsighted"
/// Massively garble speech
#define TRAIT_UNINTELLIGIBLE_SPEECH "unintelligible-speech"
/// Prevents speaking in languages
#define TRAIT_LANGUAGE_BARRIER "language-barrier"
/// Immunity to flash effects
#define TRAIT_NOFLASH "noflash"
/// Suffering heart attack, can succumb
#define TRAIT_DEATHS_DOOR "deaths_door"
/// Halved basic speed
#define TRAIT_BASIC_SPEED_HALVED "basic_speed_halved"
/// Immunity to pain
#define TRAIT_NOPAIN "no_pain"
/// Stumbling, can smash into things
#define TRAIT_STUMBLE "stumbling"
/// Has drunk ambience replacement from spice
#define TRAIT_DRUQK "druqk"
/// prevents a human corpse from being used for a corpse multiple times
#define TRAIT_BURIED_COIN_GIVEN "buried_coin_given"
/// can bleed, but will never die from blood loss
#define TRAIT_BLOODLOSS_IMMUNE "bloodloss_immune"
/// Blood requirements stay at the default regardless of organs.
#define TRAIT_NORMALIZED_BLOOD "blood_normalized"
/// you are a rotman and need occasional maintenance
#define TRAIT_ROTMAN "rotman"
/// immune to zombie infection
#define TRAIT_ZOMBIE_IMMUNE "zombie_immune"
/// prevents biting
#define TRAIT_NO_BITE "no_bite"
/// Can bite while a helmet or mask covers the mouth.
#define TRAIT_BITERHELM "helmet_biter"
/// is this guy a foreigner?
#define TRAIT_FOREIGNER "Foreigner"
/// mob cannot be ambushed for any reason
#define TRAIT_NOAMBUSH "no_ambush"
/// Can see build blueprints
#define TRAIT_BLUEPRINT_VISION "blueprint_vision"
/// Used to limit healing to putrid flesh mobs
#define TRAIT_PUTRID "Putrid"
#define TRAIT_STUCKITEMS "stuck_items" // Prevents removing items except for hand slots
#define TRAIT_HIGHVALUE_STUCK "highvalue_stuck" //Prevents removing items except for hand slots if it is consdiered to strong
/// Confessed under torture, to force sign
#define TRAIT_HAS_CONFESSED "has_confessed"
/// Confessed for specific type of antag
#define TRAIT_CONFESSED_FOR	"confessed_for"
/// For torture cooldown, should be a cooldown
#define TRAIT_RECENTLY_TORTURED "recently_tortured"
/// Receives echolocation images.
#define TRAIT_ECHOLOCATION_RECEIVER "echolocation_receiver"
/// Echolocation has a higher range.
#define TRAIT_ECHOLOCATION_EXTRA_RANGE "echolocation_extra_range"
/// Can't move diagonally
#define TRAIT_BLOCKED_DIAGONAL "blocked_diagonals"
/// Can swim ignoring water flow and slowdown
#define TRAIT_GOOD_SWIM "Good Swim"
/// Prevents floating in water and swimming up. Will move downward if in open water.
#define TRAIT_SINKING "sinking"
/// trait determines if this mob can breed given by /datum/component/breeding
#define TRAIT_MOB_BREEDER "mob_breeder"
/// can't be perceived in any way, likely due to invisibility
#define TRAIT_IMPERCEPTIBLE "imperceptible"
/// Lying under a table; tables let this mob crawl into them
#define TRAIT_UNDER_TABLE "under_table"
/// Reduced turf slowdown
#define TRAIT_LONGSTRIDER "longstrider"
/// Dendor Path Traits
#define TRAIT_DENDOR_GROWING "trait_dendor_growing"
#define TRAIT_DENDOR_STINGING "trait_dendor_stinging"
#define TRAIT_DENDOR_DEVOURING "trait_dendor_devouring"
#define TRAIT_DENDOR_LORDING "trait_dendor_lording"
/// trait that makes you bounce when speaking
#define TRAIT_SHAKY_SPEECH "Shaky Speech"
/// Allows for offhand weapon usage
#define TRAIT_DUALWIELDER "Dual Wielder"
/// Ignores body_parts_covered during the add_fingerprint() proc. Works both on the person and the item in the glove slot.
#define TRAIT_FINGERPRINT_PASSTHROUGH "fingerprint_passthrough"
/// The mob will automatically breach the Masquerade when seen by others, with no exceptions
#define TRAIT_UNMASQUERADE "unmasquerade"
/// Makes gambling incredibly effective, and causes random beneficial events to happen for the mob.
#define TRAIT_SUPERNATURAL_LUCK	"supernatural_luck"
/// Lets the mob block projectiles like bullets using only their hands.
#define TRAIT_HANDS_BLOCK_PROJECTILES "hands_block_projectiles"
/// Shows extra floating combat information.
#define TRAIT_COMBAT_AWARE "combat_aware"
/// Grants tempo: escalating defensive buffs while fighting multiple opponents.
#define TRAIT_TEMPO "tempo_capable"
/// The mob always dodges melee attacks
#define TRAIT_ENHANCED_MELEE_DODGE "enhanced_melee_dodge"
/// The mob can easily swim and jump very far.
#define TRAIT_SUPERNATURAL_DEXTERITY "supernatural_dexterity"
/// Can pass through walls so long as it doesn't move the mob into a new area
#define TRAIT_PASS_THROUGH_WALLS "pass_through_walls"
/// Technology supernaturally refuses to work or doesn't work properly for this person
#define TRAIT_REJECTED_BY_TECHNOLOGY "rejected_by_technology"
/// Doesn't cast a reflection
#define TRAIT_NO_REFLECTION "no_reflection"
/// Vampire cannot drink from anyone who doesn't consent to it
#define TRAIT_CONSENSUAL_FEEDING_ONLY "consensual_feeding_only"
#define TRAIT_COVEN_BANE "coven_bane"
/// Instead of knocking someone out when fed on, this vampire's Kiss inflicts pain
#define TRAIT_PAINFUL_VAMPIRE_KISS "painful_vampire_kiss"
/// Vampires will always diablerise this vampire given the chance
#define TRAIT_IRRESISTIBLE_VITAE "irresistible_vitae"
/// Vampire cannot feed from poor people
#define TRAIT_FEEDING_RESTRICTION "feeding_restriction"
/// Will always fail to resist supernatural mind-influencing powers
#define TRAIT_CANNOT_RESIST_MIND_CONTROL "cannot_resist_mind_control"
/// Is hurt by holiness/holy symbols and repelled by them
#define TRAIT_REPELLED_BY_HOLINESS "repelled_by_holiness"
/// Any changes in this Kindred's Humanity will be doubled
#define TRAIT_SENSITIVE_HUMANITY "sensitive_humanity"
/// Duration of frenzy is doubled
#define TRAIT_LONGER_FRENZY "longer_frenzy"
/// This mob is phased out of reality from magic, either a jaunt or rod form
#define TRAIT_MAGICALLY_PHASED "magically_phased"
/// Mob has lost control to their rage, their Beast, whatever and is frenzying
#define TRAIT_IN_FRENZY "in_frenzy"
#define TRAIT_MOVEMENT_BLOCKED "movement_blocked"
/// Incapable of losing control and entering frenzy
#define TRAIT_IMMUNE_TO_FRENZY "immune_to_frenzy"
#define TRAIT_COVEN_RESISTANT "coven_resistance"
/// Target can't be grabbed by tanglers
#define TRAIT_ENTANGLER_IMMUNE "tangler_immune"
/// This mob is antimagic, and immune to spells / cannot cast spells
#define TRAIT_ANTIMAGIC "anti_magic"
/// This allows a person who has antimagic to cast spells without getting blocked
#define TRAIT_ANTIMAGIC_NO_SELFBLOCK "anti_magic_no_selfblock"
/// makes your footsteps completely silent
#define TRAIT_SILENT_FOOTSTEPS "silent_footsteps"
/// Hides the SSD indicator. Used with scrying.
#define TRAIT_NOSSDINDICATOR "nossdindicator"
/// Instant grabs on someone else.
#define TRAIT_NOSTRUGGLE "nostruggle"
/// Black-bagged. More snowflaking.
#define TRAIT_BAGGED "bagged"
/// Pain Tolerance.
#define TRAIT_TRUE_GRIT "Grit"
/// Capable of using Garrotes and Blackbags. Apprehension techniques.
#define TRAIT_BLACKBAGGER "Apprehension Techniques"
#define TRAIT_WOUNDREGEN "Wound Regeneration"
#define TRAIT_ABOMINATION "Abomination"
#define TRAIT_EVASIVE "Evasive"
#define TRAIT_WEBWALK "Webwalker"
#define TRAIT_BRUSHWALK	"Brushwalker"
#define TRAIT_DEADNOSE "Dead Nose"
#define TRAIT_STINKY "Natural Stench"
#define TRAIT_ZJUMP "High Jumping"
#define TRAIT_FLIP_JUMP TRAIT_ZJUMP
/// A defeat leg injury that prevents jumping (see the Defeat system / DEFEAT_SYSTEM_SPEC_ADDENDUM.md).
#define TRAIT_DEFEAT_NO_JUMP "defeat_no_jump"
/// A kidnapped captive who toggled "Refuse Advances" - horny mobs leave them be (see the Defeat system).
#define TRAIT_DEFEAT_REFUSE_ADVANCES "defeat_refuse_advances"
#define TRAIT_KNOW_ROUS_DOORS "Knows Rous Doors"
#define TRAIT_JESTERPHOBIA "Jesterphobic"
#define TRAIT_XENOPHOBIC "Xenophobic"
#define TRAIT_TOLERANT "Tolerant"
#define TRAIT_NOSEGRAB "Intimidating"
#define TRAIT_NUTCRACKER "Nutcracker"
#define TRAIT_STRONGBITE "Strong Bite"
#define TRAIT_HATEWOMEN	"Ladykiller"
#define TRAIT_SEEDKNOW "Seed Knower"
#define TRAIT_NOBLE	"Noble Blooded"
#define TRAIT_NOBLE_BLOOD TRAIT_NOBLE
#define TRAIT_NOBLE_POWER TRAIT_NOBLE
#define TRAIT_EMPATH "Empath"
#define TRAIT_BREADY "Battleready"
#define TRAIT_CAN_STEER_SHIP "Can steer the ship"
#define TRAIT_BLINDFIGHTING "Sixth-Sense"
#define TRAIT_HEARING_SENSITIVE "hearing_sensitive"
#define TRAIT_MEDIUMARMOR "Mail Training"
#define TRAIT_HEAVYARMOR "Plate Training"
#define TRAIT_DODGEEXPERT "Fast Reflexes"
#define TRAIT_DODGE_THROUGH_MOBS "Flowing Footwork"
#define TRAIT_UNDODGING	"Inflexible"
#define TRAIT_UNPARRYING "Graceless"
#define TRAIT_DECEIVING_MEEKNESS "Deceiving Meekness"
#define TRAIT_VILLAIN "Villain"
#define TRAIT_CRITICAL_RESISTANCE "Critical Resistance"
#define TRAIT_CRITICAL_WEAKNESS	"Critical Weakness"
#define TRAIT_MANIAC_AWOKEN	"Awoken"
/// Marks a demon assembled by admins for the falling star event.
#define TRAIT_EVENT_HUNTER "Falling Star Hunter"
/// Species changes are disguise shifts, not growth — suppresses species_stat_pick() on gain
#define TRAIT_IDENTITY_SHIFTING "Identity Shifting"
/// Multiplies horny-knockout thresholds by SUCCUBUS_HORNY_KO_MULT (heroic to tire out, not immune)
#define TRAIT_LUSTFUL_STAMINA "Lustful Stamina"
/// Doesn't consume stamina
#define TRAIT_NOSTAMINA	"Indefatigable"
/// Can't fall asleep
#define TRAIT_FAT "Obese"
#define TRAIT_NOSLEEP "Fatal Insomnia"
/// Rests, mends and dreams through the Reverie action instead of sleep
#define TRAIT_REVERIE "Reverie"
#define TRAIT_FASTSLEEP "Fast Sleeper"
#define TRAIT_NUDIST "Nudist" //you can't wear most clothes
#define TRAIT_INHUMANE_ANATOMY "Inhuman Anatomy" //can't wear hats and shoes
#define TRAIT_NASTY_EATER "Inhuman Digestion" //can eat rotten food, organs, poison berries, and drink murky water
#define TRAIT_NOFALLDAMAGE1 "Minor Fall Damage Immunity"
#define TRAIT_NOFALLDAMAGE2 "Total	 Fall Damage Immunity"
#define TRAIT_DEATHSIGHT "Veiled Whispers" // Is notified when a player character dies, but not told exactly where or how.
#define TRAIT_CYCLOPS_LEFT "Cyclops (Left)" //poked left eye
#define TRAIT_CYCLOPS_RIGHT	"Cyclops (Right)" //poked right eye
#define TRAIT_ASSASSIN	"Assassin Training" //used for the assassin drifter's unique mechanics.
#define TRAIT_BARDIC_TRAINING "Bardic Training"
#define TRAIT_GRAVEROBBER "Graverobber"	// Prevents getting the cursed debuff when unearthing a grave, but permanent -1 LUC to whoever has it.
#define TRAIT_BLESSED "Once Blessed"	// prevents blessings stackings
#define TRAIT_MIRACULOUS_FORAGING "Miracle Foraging"	// makes bushes much more generous
#define TRAIT_MISSING_NOSE "Missing Nose" //halved stamina regeneration
#define TRAIT_DISFIGURED "Disfigured"
#define TRAIT_SPELLBLOCK "Bewitched" //prevents spellcasting
#define TRAIT_ANTISCRYING "Anti-Scrying"
#define TRAIT_SHOCKIMMUNE "Shock Immunity"
#define TRAIT_LEGENDARY_ALCHEMIST "Expert Herb Finder"
#define TRAIT_LIGHT_STEP "Light Step" //Can't trigger /obj/structure/trap/'s
#define TRAIT_THIEVESGUILD "Thieves' Guild Member"
#define TRAIT_ENGINEERING_GOGGLES "Engineering Goggles"
#define TRAIT_SEEPRICES "Golden Blood" //See prices
#define TRAIT_SEE_LEYLINES "Magical Visions"
#define TRAIT_POISONBITE "Poison Bite"
#define TRAIT_BLOODDRINKER "Blood Drinker" // Can drink blood without vomiting
#define TRAIT_FORAGER "Expert Forager"
#define TRAIT_TINY "Tiny"
#define TRAIT_DREAM_WATCHER	"Mystra Blessed" //Unique Trait of the Dream Watcher Town Elder Class, they have a chance to know about antags or gods influences.
#define TRAIT_HOLLOWBONES "Hollow Bones"
#define TRAIT_AMAZING_BACK "Light Load"
#define TRAIT_KITTEN_MOM "Loved By Kittens"
#define TRAIT_WATER_BREATHING "Waterbreathing"
#define TRAIT_WATER_LOVER "WaterLover"
#define TRAIT_MOONWATER_ELIXIR "Moonwater Elixir"
#define TRAIT_FLOWERFIELD_IMMUNITY "Flower Strider"
#define TRAIT_SECRET_OFFICIANT "Secret Officiant"
#define TRAIT_RECOGNIZE_ADDICTS	"Addict Recognition"
#define TRAIT_NOENERGY "Boundless Energy" //Specifically, You don't lose fatigue, but you do continue losing stamina.
#define TRAIT_KEENEARS "Keen Ears"
#define TRAIT_POISON_RESILIENCE "Poison Resilience"
#define TRAIT_SEED_FINDER "Seed Finder"
/// Cannot count coins
#define TRAIT_COIN_ILLITERATE "Barterer"
/// Chance for extra items when cooking
#define TRAIT_LUCKY_COOK "Lucky Cook"
#define TRAIT_BASHDOORS "bashdoors"
#define TRAIT_NOMOOD "no_mood"
#define TRAIT_BAD_MOOD "Bad Mood"
#define TRAIT_NIGHT_OWL "Night Owl"
#define TRAIT_SIMPLE_WOUNDS "simple_wounds"
#define TRAIT_SCHIZO_AMBIENCE "schizo_ambience" //replaces all ambience with creepy shit
#define TRAIT_SCREENSHAKE "screenshake" //screen will always be shaking, you cannot stop it
#define TRAIT_PUNISHMENT_CURSE "PunishmentCurse"
#define TRAIT_BANDITCAMP "banditcamp"
#define TRAIT_KNOWBANDITS "knowbandits"
#define TRAIT_VAMPMANSION "vampiremansion"
#define TRAIT_VAMP_DREAMS "vamp_dreams"
#define TRAIT_INHUMENCAMP "inhumencamp"
#define TRAIT_INTRAINING "intraining" //allows certain roles to bypass the average skill limitation of training dummies
#define TRAIT_STEELHEARTED "steelhearted" //no bad mood from dismembering or seeing this
#define TRAIT_IWASREVIVED "iwasrevived" //prevents PQ gain from reviving the same person twice
#define TRAIT_IWASUNZOMBIFIED "iwasunzombified" //prevents PQ gain from curing a zombie twice
#define TRAIT_ZIZOID_HUNTED "zizoidhunted" // Used to signal character has been marked by death by the Zizoid cult
#define TRAIT_NUDE_SLEEPER "Nude Sleeper"
#define TRAIT_BEAUTIFUL "Beautiful"
#define TRAIT_UGLY "Ugly"
#define TRAIT_FISHFACE "Fishface"
#define TRAIT_SCHIZO_FLAW "Schizophrenic"
#define TRAIT_VIOLATOR "Violator of the Coven"
#define TRAIT_TORPOR "Endless Slumber"
#define TRAIT_SATE "SATE"
#define TRAIT_NODE_EXTRACTED "Humors Extracted"
#define TRAIT_NO_EXPERIENCE	"unlearning"
/// This mob should never close UI even if it doesn't have a client
#define TRAIT_PRESERVE_UI_WITHOUT_CLIENT "preserve_ui_without_client"
/// This mob is considered a virgin by blood, cult, and relationship mechanics.
#define TRAIT_VIRGIN "virginity"

/// This mob's surgical operations ignore ALL speed modifiers (even positive ones!) besides tool quality.
/// The mob can also no longer fail their operations, unless the operation says otherwise
#define TRAIT_IGNORE_SURGERY_MODIFIERS "ignore_surgery_modifiers"

/// applied to orphans
#define TRAIT_ORPHAN "Orphan"
#define TRAIT_RECRUITED	"Recruit" //Trait used to give foreigners their new title
#define TRAIT_RECOGNIZED "Recognized" // Given to famous migrants, pilgrims and adventurers, enable their title.
#define TRAIT_FANATICAL "Fanatical" //Trait used for fanatical mobs who can bypass the excommunication(not the curses though.)

// Divine patron trait bonuses:
#define TRAIT_SOUL_EXAMINE "Blessing of Jergal"  //can check bodies to see if they have departed
#define TRAIT_ROT_EATER "Blessing of Ilmater" //can eat rotten food
#define TRAIT_KNEESTINGER_IMMUNITY "Blessing of Silvanus" //Can move through kneestingers.
#define TRAIT_LEECHIMMUNE "Unleechable" //leeches drain very little blood
#define TRAIT_SHARPER_BLADES "Sharper Blades" //Weapons lose less blade integrity
#define TRAIT_BETTER_SLEEP "Better Sleep" //Recover more energy (blue bar) when sleeping
#define TRAIT_EXTEROCEPTION	"Exteroception" //See others' hunger and thirst
#define TRAIT_TUTELAGE "Tutelage" //Slightly more sleep xp to you and xp to apprentices
#define TRAIT_APRICITY "Apricity" //Decreased stamina regen time during "day"
#define TRAIT_BLACKLEG "Blackleg" //Rig coin, dice, cards in your favor
#define TRAIT_INQUISITION "Member of the Oratorium Throni Vacui"
#define TRAIT_PURITAN "Puritan"
#define TRAIT_SILVER_BLESSED "Silver Blessed"

// Inhumen patron trait bonuses
#define TRAIT_ORGAN_EATER "Blessing of Gruumsh"//Can eat organs (duh.) and raw meat
#define TRAIT_CRACKHEAD	"Blessing of Blissara" //No overdose on drugs.
#define TRAIT_CABAL "Of the Cabal" //Zizo cultists recognize each other too
#define TRAIT_MATTHIOS_EYES	"Eyes of Mask" //Examine to see the most expensive item someone has

// PATRON CURSE TRAITS
#define TRAIT_CURSE "Curse" //source
#define TRAIT_ATHEISM_CURSE "Curse of Atheism"
#define TRAIT_PSYDON_CURSE "Ao's Curse"
#define TRAIT_ASTRATA_CURSE "Lathander's Curse"
#define TRAIT_NOC_CURSE "Mystra's Curse"
#define TRAIT_RAVOX_CURSE "Tempus's Curse"
#define TRAIT_NECRA_CURSE "Jergal's Curse"
#define TRAIT_XYLIX_CURSE "Tymora's Curse"
#define TRAIT_PESTRA_CURSE "Ilmater's Curse"
#define TRAIT_EORA_CURSE "Sune's Curse"
#define TRAIT_ZIZO_CURSE "Lolth's Curse"
#define TRAIT_GRAGGAR_CURSE "Gruumsh's Curse"
#define TRAIT_MATTHIOS_CURSE "Mask's Curse"
#define TRAIT_BAOTHA_CURSE "Blissara's Curse"

// HIDDEN DOOR TRAITS
#define TRAIT_KNOW_KEEP_DOORS "know_keep_doors"
#define TRAIT_KNOW_INQUISITION_DOORS "know_inquisition_doors"
#define TRAIT_KNOW_THIEF_DOORS "know_thief_doors"

// JOB RELATED TRAITS
#define TRAIT_MALUMFIRE "Professional Smith"
#define TRAIT_CRATEMOVER "Crate Mover"
#define TRAIT_BURDEN "Burdened" //Gaffer stuff
#define TRAIT_OLDPARTY "Old Party"
#define TRAIT_EARGRAB "Ear Grab"
#define TRAIT_FACELESS "Faceless One"
#define TRAIT_ROYALSERVANT "Household Insight" // Let's you see the royals liked/hated food/drink

// ************* obj traits

/// this object has been frozen
#define TRAIT_FROZEN "frozen"

// **** bodypart traits
/// Used for limb-based paralysis and full body paralysis
#define TRAIT_PARALYSIS	"paralysis"
/// The limb is more susceptible to fractures
#define TRAIT_BRITTLE "brittle"
/// The limb has no fingies
#define TRAIT_FINGERLESS "fingerless"

// **** organ traits
/// Applied to an organ that has been operated on - some organs can't be operated on multiple times
#define TRAIT_ORGAN_OPERATED_ON "organ_operated_on"

// **** item traits
/// Can't drop
#define TRAIT_NODROP "nodrop"
/// Can't be embedded
#define TRAIT_NOEMBED "noembed"
/// Can't be teleported
#define TRAIT_NO_TELEPORT "no-teleport" //you just can't
#define TRAIT_NEEDS_QUENCH "Needs Quenching"
/// Properly wielded two handed item
#define TRAIT_WIELDED "wielded"
/// The items needs two hands to be carried
#define TRAIT_NEEDS_TWO_HANDS "needstwohands"
/// This item can't be pickpocketed
#define TRAIT_HARD_TO_STEAL "hard_to_steal"
/// This organ's passive liquid leakage is temporarily plugged.
#define TRAIT_PASSIVE_LEAK_BLOCKED "passive_leak_blocked"
/// Prevents reagent containers from using their splash interaction on this atom.
#define TRAIT_DO_NOT_SPLASH "do_not_splash"
/// Fish can be released into this fishing source.
#define TRAIT_CATCH_AND_RELEASE "catch_and_release"

// ************* turf traits
/// Turf trait for when a turf is transparent
#define TRAIT_Z_TRANSPARENT "turf_z_transparent"

// **** turf traits
///Turf slowdown will be ignored when this trait is added to a turf.
#define TRAIT_TURF_IGNORE_SLOWDOWN "turf_ignore_slowdown"
/// Turf is one that ai mobs will generally avoid pathing through
/// Doesn't need to be applied to any turfs that override can_cross_safely
#define TRAIT_AI_AVOID_TURF "warning_turf"

// ************* Debug traits
/// This object has sound debugging tools attached to it
#define TRAIT_SOUND_DEBUGGED "sound_debugged"

/// Occasionally makes an examiner imagine that this mob returned their eye contact.
#define TRAIT_SHIFTY_EYES "shifty_eyes"

// genetic traits
#define TRAIT_ANIMAL_NATURAL_ARMOR "natural_armor"
#define TRAIT_ANIMAL_PRODUCTIVE "trait_productive"

//quirk traits
#define TRAIT_ALCOHOL_TOLERANCE	"alcohol_tolerance"
#define TRAIT_AGEUSIA			"ageusia"
#define TRAIT_HEAVY_SLEEPER		"heavy_sleeper"
#define TRAIT_NIGHT_VISION		"night_vision"
#define TRAIT_SPIRITUAL			"spiritual"
#define TRAIT_FAN_CLOWN			"fan_clown"
#define TRAIT_FAN_MIME			"fan_mime"
#define TRAIT_VORACIOUS			"voracious"
#define TRAIT_SELF_AWARE		"self_aware"
#define TRAIT_FREERUNNING		"freerunning"
#define TRAIT_SKITTISH			"skittish"
#define TRAIT_POOR_AIM			"poor_aim"
#define TRAIT_PROSOPAGNOSIA		"prosopagnosia"
#define TRAIT_DRUNK_HEALING		"drunk_healing"
#define TRAIT_TAGGER			"tagger"
#define TRAIT_PHOTOGRAPHER		"photographer"
#define TRAIT_MUSICIAN			"musician"
#define TRAIT_LIGHT_DRINKER		"light_drinker"
#define TRAIT_FRIENDLY			"friendly"
#define TRAIT_GRABWEAKNESS		"grab_weakness"
#define TRAIT_SNOB				"snob"

// Other RMH traits:
//RMH EDITED START - garrison SCOM ring integration
#define TRAIT_GARRISON_ITEM		"Garrison Item"
//RMH EDITED END
#define TRAIT_GOODLOVER			"Fabled Lover"
#define TRAIT_NYMPHO_CURSE 		"Nymphs Curse"
#define TRAIT_ALLURE 			"Allure"
#define TRAIT_DARKLING 			"Darkling"
#define TRAIT_WILDMAGIC 		"Wildmagic"
#define TRAIT_DRUNKMASTER 		"Drunkmaster"
#define TRAIT_RUNE_SEVERED		"runesevered"
#define TRAIT_FREEZEHUNGER 		"Freeze Hunger"
#define TRAIT_EGG_LAYER "vaginal_egg_layer"
/// Breasts and balls visibly swell as they fill with fluid.
#define TRAIT_FLUID_ENGORGEMENT "fluid_engorgement"
/// Goes into heat or rut now and then; each source is a HEAT_SOURCE_* define.
#define TRAIT_HEAT_CYCLE "heat_cycle"
/// Jiggling costs no stamina inside the bathhouse.
#define TRAIT_BATHHOUSE_DANCER "Bathhouse Dancer"
/// This mob cannot cast spells
#define TRAIT_NO_SELF_MAGIC 	"noselfmagic"

#define TRAIT_PONYGIRL_RIDEABLE "Mount" //riding

// RMH Hubs
#define TRAIT_VMANSION			"Vampire Mansion"
#define TRAIT_WEREWOLFDEN		"Werewolf Den"
#define TRAIT_BLISSARABASE		"Blissara Base"
#define TRAIT_GNOLLHUB			"Gnolls Hub"
#define TRAIT_AVERNUS			"Avernus"
#define TRAIT_HAG				"Hag Tree"
#define TRAIT_DRAGONDEN			"Dragon Cave"
#define TRAIT_THIEFBASE			"Thiefs Base"
#define TRAIT_RATHOLE			"Rat Hole"
#define TRAIT_TADPOLECAVE		"Tadpole Cave"
#define TRAIT_TENTACLECAVE		"Tentacle Cave"
#define TRAIT_GHOSTHUB			"Ghost Hub"
//Social traits for examining
#define TRAIT_KNOW_WATCH "know_faction_members"
#define TRAIT_KNOW_WATCH_RANK "know_social_rank"
#define TRAIT_KNOW_WATCH_SPECIALIZATION "know_social_specialization"
//Commanding system
#define TRAIT_TOWNWATCH_COMMAND "townwatch_command"
#define TOWNWATCH_COMMAND_TRAIT_SOURCE "townwatch_command_trait"
