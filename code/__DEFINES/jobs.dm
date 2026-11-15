#define JOB_AVAILABLE 0
#define JOB_UNAVAILABLE_GENERIC 1
#define JOB_UNAVAILABLE_BANNED 2
#define JOB_UNAVAILABLE_PLAYTIME 3
#define JOB_UNAVAILABLE_SLOTFULL 4
#define JOB_UNAVAILABLE_AGE 5
#define JOB_UNAVAILABLE_RACE 6
#define JOB_UNAVAILABLE_SEX 7
#define JOB_UNAVAILABLE_DEITY 8
#define JOB_UNAVAILABLE_QUALITY 9
#define JOB_UNAVAILABLE_LASTCLASS 11
#define JOB_UNAVAILABLE_ACCOUNTAGE 12
#define JOB_UNAVAILABLE_JOB_COOLDOWN 13
#define JOB_UNAVAILABLE_RACE_BANNED 14
#define JOB_UNAVAILABLE_WHITELIST 15
#define JOB_UNAVAILABLE_REQUIRED_JOB 16

/* Job datum job_flags */
/// Whether the mob is announced on arrival.
#define JOB_ANNOUNCE_ARRIVAL (1<<0)
/// Whether the mob is added to the crew manifest.
#define JOB_SHOW_IN_CREDITS (1<<1)
/// Whether the mob is equipped through SSjob.EquipRank() on spawn.
#define JOB_EQUIP_RANK (1<<2)
/// Whether this job can be joined through the new_player menu.
#define JOB_NEW_PLAYER_JOINABLE (1<<3)
/// Whether the job can be displayed on the actors list
#define JOB_SHOW_IN_ACTOR_LIST (1<<4)

// Resurrection rune auto-link tags.
#define RUNE_LINK_NONE null
#define RUNE_LINK_DEFAULT "__rune_link_default__"
#define RUNE_LINK_CITY "RUNE_CITY"
#define RUNE_LINK_ANTAG "RUNE_ANTAG"
#define RUNE_LINK_VAMPIRE "RUNE_VAMPIRE"
#define RUNE_LINK_OUTLAW "RUNE_OUTLAW"
#define RUNE_LINK_WEREWOLF "RUNE_WEREWOLF"

#define ALL_FACTIONS list( \
	FACTION_NONE, \
	FACTION_NEUTRAL, \
	FACTION_HOSTILE, \
	FACTION_TOWN, \
	FACTION_FOREIGNERS, \
	FACTION_MIGRANTS, \
	FACTION_UNDEAD, \
	FACTION_PLANTS, \
	FACTION_VINES, \
	FACTION_CABAL, \
	FACTION_RATS, \
	FACTION_ORCS, \
	FACTION_WOLVES, \
	FACTION_BUMS, \
	FACTION_VIKINGS, \
	FACTION_MINOTAURS, \
	FACTION_MATTHIOS \
)

#define FACTION_NONE		"None"
#define FACTION_NEUTRAL		"Neutral"
#define FACTION_HOSTILE		"Hostile"
#define FACTION_TOWN		"Town"
#define FACTION_FOREIGNERS  "Foreigners"
#define FACTION_MIGRANTS  	"Migrants"
#define FACTION_UNDEAD		"Undead"
#define FACTION_PLANTS		"Plants"
#define FACTION_VINES		"Vines" //Seemingly unused
#define FACTION_CABAL		"Cabal"
#define FACTION_RATS		"Rats"
#define FACTION_ORCS		"Orcs"
#define FACTION_WOLVES		"Wolves"
#define FACTION_BUMS		"Bums"
#define FACTION_MATTHIOS	"Matthios"
#define FACTION_VIKINGS     "Vikings"
#define FACTION_MINOTAURS	"Minotaurs"

#define LORDS			(1<<0)	//For the Vampire Lords and Ladies
#define KEEP			(1<<1)	//For the Vampire Keep servants and guards
#define TOWNHALL		(1<<2)	//For the people who work at the town hall
#define TOWNWATCH		(1<<3)	//For the town watch
#define CHAPEL			(1<<4)	//For the chapel roles
#define SCHOLARS		(1<<5)	//For the mages, alchemists and librarians
#define TRADERS			(1<<6)	//For the Waterdeep's Guild
#define TAVERN			(1<<7)	//For the tavern roles
#define TOWN			(1<<8)	//For all the other roles within the town
#define OUTSIDERS		(1<<9)	//For the witch, the druids and others
#define ADVENTURERS		(1<<10)	//For all the adventurer classes
#define VILLAINS		(1<<11)	//For the bandits, cultists and other scum

#define UNDEAD			(1<<12)


#define JCOLOR_LORDS        "#b02a3c" // Regal blood red
#define JCOLOR_KEEP         "#6e6a8c" // Cold dusk violet
#define JCOLOR_TOWNHALL     "#4fa1a8" // Civic teal
#define JCOLOR_TOWNWATCH   	"#7b8a99" // Cold steel blue-gray
#define JCOLOR_CHAPEL       "#e6c35c" // Radiant sacred gold
#define JCOLOR_SCHOLARS 	"#b07cff" // Vivid arcane violet
#define JCOLOR_TRADERS 	    "#6a7fd6" // Violet-blue
#define JCOLOR_TAVERN       "#d08a4b" // Warm amber ale
#define JCOLOR_TOWN         "#7f9a77" // Soft moss green
#define JCOLOR_OUTSIDERS    "#8c6fb1" // Witch violet
#define JCOLOR_ADVENTURERS  "#4fc48d" // Bright emerald
#define JCOLOR_VILLAINS     "#9b3d6a" // Sinister magenta-crimson


// job display orders //

#define JDO_DEFAULT 0
//LORDS
#define JDO_LORD 1
#define JDO_SECONDLORD 2
//KEEP
#define JDO_KEEPGUARD 3
#define JDO_KEEPSERVANT 3.5
//TOWNHALL
#define JDO_BURGMEISTER 4
#define JDO_COUNCILOR 4.5
#define JDO_NAVIGATOR 4.75
#define JDO_SERVANT 5
//TOWNWATCH
#define JDO_WATCH_CAPTAIN 6
#define JDO_WATCH_SERGEANT 6.5
#define JDO_WATCH_VETERAN 7
#define JDO_WATCH_WARDEN 7.5
#define JDO_WATCH_GUARD 8
#define JDO_WATCH_MILITIA 8.5
//CHAPEL
#define JDO_MOON_PRIEST 9
#define JDO_HEART_PRIEST 9.5
#define JDO_CHAPEL_ACOLYTE 10
//SCHOLARS
#define JDO_GUILD_WIZARD_MASTER 11
#define JDO_GUILD_WIZARD_EXPERT 11.5
#define JDO_GUILD_WIZARD_APPRENTICE 12
#define JDO_LIBRARIAN 13
#define JDO_LIBRARIAN_APPRENTICE 13.5
//TRADERS
#define JDO_WATERDEEP_MERCHANT 14
#define JDO_WATERDEEP_BANKER 14.5
#define JDO_WATERDEEP_GUARD 15
#define JDO_WATERDEEP_ASSISTANT 15.5
//TAVERN
#define JDO_ADVENTURERS_HEAD 16
#define JDO_ADVENTURERS_ASSISTANT 16.5
#define JDO_INNKEEP 17
#define JDO_COOK 17.5
#define JDO_MATRON 18
#define JDO_WAITRESS 18.5
//TOWN
#define JDO_TOWNER 19
#define JDO_SEELIE 19.25
#define JDO_ARTISAN 20
#define JDO_ARTISAN_APPRENTICE 20.5
//OUTSIDERS
#define JDO_FOREST_WARDEN 21
#define JDO_FOREST_RANGER 21.5
#define JDO_GROVE_DRUID 22
#define JDO_SWAMP_WITCH 22.5
#define JDO_OGRE 22.75
//ADVENTURERS
#define JDO_ADVENTURER_BARBARIAN 23
#define JDO_ADVENTURER_BARD 23.5
#define JDO_ADVENTURER_CLERIC 24
#define JDO_ADVENTURER_DRUID 24.5
#define JDO_ADVENTURER_FIGHTER 25
#define JDO_ADVENTURER_MONK 25.5
#define JDO_ADVENTURER_PALADIN 26
#define JDO_ADVENTURER_RANGER 26.5
#define JDO_ADVENTURER_ROGUE 27
#define JDO_ADVENTURER_SORCERER 27.5
#define JDO_ADVENTURER_WARLOCK 28
#define JDO_ADVENTURER_WIZARD 28.5
	//VILLAINS
#define JDO_BANDIT 29
#define JDO_WEREWOLF 29.5
#define JDO_SUCCUBUS 30


#define BITFLAG_CHURCH (1<<0)
#define BITFLAG_ROYALTY (1<<1)
#define BITFLAG_CONSTRUCTOR (1<<2)
#define BITFLAG_GARRISON (1<<3)
