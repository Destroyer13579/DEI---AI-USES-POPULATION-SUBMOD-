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

local function gc_FirstTurnSetup(context)
    Log("gc_FirstTurnSetup", "Start");
    local player_factions = GetPlayerFactionsbyName();

    -- Run faction setup (no free spawns, just structural setup)
    gc_faction_setups(player_factions)
    Log("gc_FirstTurnSetup", "gc_faction_setups done");

    -- Remove AI forced diplomatic relations (previously locked stances removed)
    Log("gc_FirstTurnSetup", "Dynamic diplomacy enabled");
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
