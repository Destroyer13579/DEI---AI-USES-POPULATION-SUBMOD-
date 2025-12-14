---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Grand Campaign Setup Scripts for Divide et Impera  
-- Modified to Remove AI Cheats
-- Last Updated: [Your Date]
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- Make the script a module one
module(..., package.seeall);

-- Used to have the object library able to see the variables in this new environment
_G.main_env = getfenv(1);

-- Load libraries
scripting = require "lua_scripts.EpisodicScripting";  
require "DeI_utility_functions";

--===============================================================
-- First Turn Setup
--===============================================================

--local function gc_FirstTurnSetup(context)
    --Log("gc_FirstTurnSetup", "Start");
    --local player_factions = GetPlayerFactionsbyName();

    -- Run faction setup (no free spawns, just structural setup)
    --gc_faction_setups(player_factions)
    --Log("gc_FirstTurnSetup", "gc_faction_setups done");

    -- Remove AI forced diplomatic relations (previously locked stances removed)
    --Log("gc_FirstTurnSetup", "Dynamic diplomacy enabled");
--end;
--
local function gc_FirstTurnSetup(context)
  Log("gc_FirstTurnSetup","Start");
  local player_factions = GetPlayerFactionsbyName();

	-- add additional units depending on player factions
	gc_faction_setups(player_factions)
	Log("gc_FirstTurnSetup", "gc_faction_setups done");

	-- spawn cyrene army
	--scripting.game_interface:create_force ("rom_cyrenaica", "Afr_Elephants,Gre_Light_Hoplites_Cyrene,Gre_Light_Hoplites_Cyrene,AOR_17_Egyptian_Archers,Gre_Citizen_Cav_Cyrene,Gre_Hoplites_Cyrene,Gre_Hoplites_Cyrene,Gre_Light_Peltasts,Gre_Light_Peltasts,Gre_Citizen_Cav_Cyrene", "emp_libya_cyrene", 437, 222, "Cyrene_AI_army_3", true); 

	-- set starting diplomatic relations for every campaign
	scripting.game_interface:force_change_cai_faction_personality("rom_cyrenaica", "minor_eastern_alternative");
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_cyrenaica", "rom_ptolemaics", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_ptolemaics", "rom_cyrenaica", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_cyrenaica", "rom_ptolemaics", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");	 
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_seleucid", "rom_ptolemaics", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_ptolemaics", "rom_seleucid", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_seleucid", "rom_ptolemaics", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_epirus", "rom_rome", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_rome", "rom_epirus", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_rome", "rom_carthage", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
	scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_carthage", "rom_rome", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
                scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_nabatea", "rom_kush", "CAI_STRATEGIC_STANCE_FRIENDLY");
	scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_nabatea", "rom_kush", "CAI_STRATEGIC_STANCE_FRIENDLY");
                scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_kush", "rom_nabatea", "CAI_STRATEGIC_STANCE_FRIENDLY");
	scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_kush", "rom_nabatea", "CAI_STRATEGIC_STANCE_FRIENDLY");

	if not contains("rom_maurya", player_factions) and not contains("rom_baktria", player_factions) then
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_maurya", "rom_baktria", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_baktria", "rom_maurya", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES");
		Log("gc_FirstTurnSetup", "Maurya and Bactria hate eachother");
	end;

	if not contains("rom_carthage", player_factions) and not contains("rom_cyrenaica", player_factions) then
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_carthage", "rom_cyrenaica", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_carthage", "rom_cyrenaica", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_cyrenaica", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_cyrenaica", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
	end;
	if not contains("rom_carthage", player_factions) and not contains("rom_gaetuli", player_factions) then
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_carthage", "rom_gaetuli", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_carthage", "rom_gaetuli", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_gaetuli", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_gaetuli", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
	end;
	if not contains("rom_carthage", player_factions) and not contains("rom_garamantia", player_factions) then
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_carthage", "rom_garamantia", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_carthage", "rom_garamantia", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_garamantia", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_garamantia", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
	end;
	if not contains("rom_carthage", player_factions) and not contains("rom_nasamones", player_factions) then
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_carthage", "rom_nasamones", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_carthage", "rom_nasamones", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_nasamones", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
		scripting.game_interface:cai_strategic_stance_manager_block_all_stances_but_that_specified_towards_target_faction("rom_nasamones", "rom_carthage", "CAI_STRATEGIC_STANCE_FRIENDLY");
	end;
end;

function gc_faction_setups(player_factions)
    Log("gc_faction_setups", "Start");
    local is_multiplayer = scripting.game_interface:model():is_multiplayer();
    Log("gc_faction_setups", "Campaign is Multiplayer: " .. tostring(is_multiplayer));

    local difficulty = scripting.game_interface:model():difficulty_level();
    Log("gc_faction_setups", "Difficulty level: " .. tostring(difficulty));
    
    if is_multiplayer then difficulty = -1 end;
    
    -- Call faction setup functions without free units
    Pyrrhus_Setup(player_factions, is_multiplayer, difficulty);
    RomeStart_Setup(player_factions, is_multiplayer, difficulty);
    EgyptStart_Setup(player_factions, is_multiplayer, difficulty);
    SeleucidStart_Setup(player_factions, is_multiplayer, difficulty);
end;

--===============================================================
-- Pyrrhus Setup (No Free Units)
--===============================================================
function Pyrrhus_Setup(player_factions, is_multiplayer, difficulty)
    Log("Pyrrhus_Setup", "Executing Pyrrhus Setup (No AI Cheats)");
end;

--===============================================================
-- Rome Setup (No Free Units)
--===============================================================
function RomeStart_Setup(player_factions, is_multiplayer, difficulty)
    Log("RomeStart_Setup", "Executing Rome Setup (No AI Cheats)");
end;

--===============================================================
-- Egypt Setup (No Free Units)
--===============================================================
function EgyptStart_Setup(player_factions, is_multiplayer, difficulty)
    Log("EgyptStart_Setup", "Executing Egypt Setup (No AI Cheats)");
end;

--===============================================================
-- Seleucid Setup (No Free Units)
--===============================================================
function SeleucidStart_Setup(player_factions, is_multiplayer, difficulty)
    Log("SeleucidStart_Setup", "Executing Seleucid Setup (No AI Cheats)");
end;

-- Hook into campaign start
scripting.AddEventCallBack("NewCampaignStarted", gc_FirstTurnSetup);
