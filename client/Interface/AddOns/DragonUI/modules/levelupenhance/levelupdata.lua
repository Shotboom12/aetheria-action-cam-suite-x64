-- Copyright (c) 2026 NeticSoul. Licensed under the MIT License; see LICENSE.
-- Game data (c) Blizzard Entertainment; not covered by DragonUI's MIT license.

local addon = select(2, ...)

addon.LevelUpData = {
    -- {level, spellID, raceMask}; 0 = every race of the class
    questSpells = {
        DRUID = { {10,5487,0}, {10,6795,0}, {10,6807,0}, {14,8946,0} },
        HUNTER = { {10,883,0}, {10,982,0}, {10,1515,0}, {10,2641,0}, {10,6991,0} },
        MAGE = { {60,28272,0} },
        PALADIN = { {12,7328,0} },
        ROGUE = { {20,2842,77} },
        SHAMAN = { {4,8071,0}, {10,3599,0}, {20,5394,0} },
        WARLOCK = { {10,697,0}, {20,712,0}, {30,691,0}, {50,1122,0}, {60,18540,0} },
        WARRIOR = { {10,71,0}, {10,355,0}, {10,7386,0}, {30,2458,0} },
    },
    -- {level, spellID}
    riding = { {40,33388}, {60,33391}, {60,34090}, {60,34091}, {60,54197} },
    -- {level, BattlemasterList ID, icon, enUS name used only if the client has none}
    battlegrounds = {
        {10,2,"Achievement_BG_winWSG","Warsong Gulch"}, {20,3,"Achievement_BG_winAB","Arathi Basin"}, {51,1,"Achievement_BG_winAV","Alterac Valley"},
        {61,7,"Achievement_BG_winEOS","Eye of the Storm"}, {71,9,"Achievement_BG_winSOA","Strand of the Ancients"}, {71,30,"INV_Shield_61","Isle of Conquest"},
    },
    -- {level, LFGDungeons ID, faction (-1 both, 0 Horde, 1 Alliance), LFGIcon suffix or false, enUS name}
    dungeons = {
        {15,1,-1,"WAILINGCAVERNS","Wailing Caverns"}, {15,4,0,"RAGEFIRECHASM","Ragefire Chasm"}, {15,6,-1,"DEADMINES","Deadmines"},
        {16,8,-1,"SHADOWFANGKEEP","Shadowfang Keep"}, {19,10,-1,"BLACKFATHOMDEEPS","Blackfathom Deeps"}, {20,12,1,"STORMWINDSTOCKADES","Stormwind Stockade"},
        {22,16,-1,"RAZORFENKRAUL","Razorfen Kraul"}, {23,14,-1,"GNOMEREGAN","Gnomeregan"}, {27,18,-1,"SCARLETMONASTERY","Scarlet Monastery - Graveyard"},
        {30,165,-1,"SCARLETMONASTERY","Scarlet Monastery - Library"}, {32,20,-1,"RAZORFENDOWNS","Razorfen Downs"}, {32,163,-1,"SCARLETMONASTERY","Scarlet Monastery - Armory"},
        {35,22,-1,"ULDAMAN","Uldaman"}, {35,164,-1,"SCARLETMONASTERY","Scarlet Monastery - Cathedral"}, {39,272,-1,"MARAUDON","Maraudon - Purple Crystals"},
        {41,24,-1,"ZULFARAK","Zul'Farrak"}, {41,26,-1,"MARAUDON","Maraudon - Orange Crystals"}, {43,273,-1,"MARAUDON","Maraudon - Pristine Waters"},
        {45,28,-1,"SUNKENTEMPLE","Sunken Temple"}, {47,30,-1,"BLACKROCKDEPTHS","Blackrock Depths - Prison"}, {51,276,-1,"BLACKROCKDEPTHS","Blackrock Depths - Upper City"},
        {53,34,-1,"DIREMAUL","Dire Maul - East"}, {55,2,-1,"SCHOLOMANCE","Scholomance"}, {55,32,-1,"BLACKROCKSPIRE","Lower Blackrock Spire"},
        {55,36,-1,"DIREMAUL","Dire Maul - West"}, {55,38,-1,"DIREMAUL","Dire Maul - North"}, {55,40,-1,"STRATHOLME","Stratholme - Main Gate"},
        {55,274,-1,"STRATHOLME","Stratholme - Service Entrance"}, {57,136,-1,"HELLFIRECITADEL","Hellfire Ramparts"}, {59,137,-1,"HELLFIRECITADEL","Blood Furnace"},
        {60,140,-1,"COILFANG","Slave Pens"}, {60,146,-1,"COILFANG","Underbog"}, {60,148,-1,"AUCHINDOUN","Mana-Tombs"},
        {60,149,-1,"AUCHINDOUN","Auchenai Crypts"}, {60,170,-1,"CAVERNSOFTIME","The Escape From Durnholde"}, {60,150,-1,"AUCHINDOUN","Sethekk Halls"},
        {60,138,-1,"HELLFIRECITADEL","Shattered Halls"}, {60,147,-1,"COILFANG","The Steamvault"}, {60,151,-1,"AUCHINDOUN","Shadow Labyrinth"},
        {60,172,-1,"TEMPESTKEEP","The Mechanar"}, {60,173,-1,"TEMPESTKEEP","The Botanica"}, {60,171,-1,"CAVERNSOFTIME","The Black Morass"},
        {60,174,-1,"TEMPESTKEEP","The Arcatraz"}, {60,198,-1,"MAGISTERSTERRACE","Magisters' Terrace"}, {60,202,-1,"UTGARDE","Utgarde Keep"},
        {60,225,-1,"THENEXUS","The Nexus"}, {60,204,-1,"AZJOLNERUB","Azjol-Nerub"}, {60,218,-1,"AHNKALET","Ahn'kahet: The Old Kingdom"},
        {60,214,-1,"DRAKTHARON","Drak'Tharon Keep"}, {60,220,-1,"THEVIOLETHOLD","Violet Hold"}, {60,216,-1,"GUNDRAK","Gundrak"},
        {60,208,-1,"HALLSOFSTONE","Halls of Stone"}, {60,203,-1,"UTGARDEPINNACLE","Utgarde Pinnacle"}, {60,206,-1,"THEOCULUS","The Oculus"},
        {60,207,-1,"HALLSOFLIGHTNING","Halls of Lightning"}, {60,209,-1,"CAVERNSOFTIME","The Culling of Stratholme"}, {60,245,-1,"ARGENTDUNGEON","Trial of the Champion"},
        {60,251,-1,"THEFORGEOFSOULS","The Forge of Souls"}, {60,253,-1,"PITOFSARON","Pit of Saron"}, {60,255,-1,"HALLSOFREFLECTION","Halls of Reflection"},
    },
    -- {level, LFGDungeons ID, LFGIcon suffix or false, enUS name}
    raids = {
        {56,42,"ZulGurub","Zul'Gurub"}, {56,44,"BlackrockSpire","Upper Blackrock Spire"}, {60,48,"MoltenCore","Molten Core"},
        {60,50,"BlackwingLair","Blackwing Lair"}, {60,160,"AQRuins","Ahn'Qiraj Ruins"}, {60,161,"AQTemple","Ahn'Qiraj Temple"},
        {60,175,"Karazhan","Karazhan"}, {60,176,"HellfireCitadelRaid","Magtheridon's Lair"}, {60,177,"GruulsLair","Gruul's Lair"},
        {60,193,"TempestKeep","Tempest Keep"}, {60,194,"SerpentshrineCavern","Serpentshrine Cavern"}, {60,195,"HyjalPast","Hyjal Past"},
        {60,196,"BlackTemple","Black Temple"}, {60,197,"ZulAman","Zul'Aman"}, {60,199,"Sunwell","The Sunwell"},
        {60,46,false,"Onyxia's Lair"}, {60,159,"NAXXRAMAS","Naxxramas"}, {60,223,"MALYGOS","The Eye of Eternity"},
        {60,224,"CHAMBEROFASPECTS","The Obsidian Sanctum"}, {60,239,"VAULTOFARCHAVON","Vault of Archavon"}, {60,243,"ULDUAR","Ulduar"},
        {60,246,"ARGENTRAID","Trial of the Crusader"}, {60,279,"ICECROWNCITADEL","Icecrown Citadel"}, {60,293,"RUBYSANCTUM","Ruby Sanctum"},
    },
    -- {level, expansion}
    heroics = { {60,1}, {60,2} },
}
