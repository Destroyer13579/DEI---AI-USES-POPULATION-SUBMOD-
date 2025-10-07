-- AI auto resolve bonus script for Divide et Impera  
-- Created by Litharion
-- Updated & Balanced by Destroyer
-- Organized by ChatGBT
-- Last Updated: [03/10/2025]

module(..., package.seeall);
_G.main_env = getfenv(1);

scripting = require "lua_scripts.EpisodicScripting";  
require "DeI_utility_functions";

--===============================================================
-- HELPER FUNCTIONS
--===============================================================
function GetPlayerFactions()
    local player_factions = {};
    local faction_list = scripting.game_interface:model():world():faction_list();
    for i = 0, faction_list:num_items() - 1 do
        local curr_faction = faction_list:item_at(i);
        if curr_faction:is_human() then
            table.insert(player_factions, curr_faction);
        end
    end
    return player_factions;
end

function CheckIfFactionIsPlayersAlly(players, faction)
    for _, player in pairs(players) do
        if player:allied_with(faction) then return true end
    end
    return false
end

function CheckIfPlayerIsNearFaction(players, force)
    local force_general = force:general_character()
    local radius = 20
    for _, player in pairs(players) do
        local player_force_list = player:military_force_list()
        for j = 0, player_force_list:num_items() - 1 do
            local player_character = player_force_list:item_at(j):general_character()
            local distance = distance_2D(
                force_general:logical_position_x(), force_general:logical_position_y(),
                player_character:logical_position_x(), player_character:logical_position_y()
            )
            if distance < radius then return true end
        end
    end
    return false
end

--===============================================================
-- BALANCED AUTO-RESOLVE LOGIC  -- much needed holy cow
--===============================================================
local function OnPendingBattle(context)
    local attacking_faction = context:pending_battle():attacker():faction()
    local defending_faction = context:pending_battle():defender():faction()
    local attacker_strength = attacking_faction:military_strength()
    local defender_strength = defending_faction:military_strength()
    local attacker_regions = attacking_faction:region_list():num_items()
    local defender_regions = defending_faction:region_list():num_items()
    local attacker_veterancy = GetAverageUnitVeterancy(attacking_faction)
    local defender_veterancy = GetAverageUnitVeterancy(defending_faction)

    local player_factions = GetPlayerFactions()
    local ally_involved = CheckIfFactionIsPlayersAlly(player_factions, defending_faction) or CheckIfFactionIsPlayersAlly(player_factions, attacking_faction)
    local player_nearby = CheckIfPlayerIsNearFaction(player_factions, context:pending_battle():attacker():military_force())

    if attacking_faction:is_human() or defending_faction:is_human() then return end

    local modifier = 1.0  -- Default no bonus - the below features were AI recommended and applied - works pretty well I'd say
    
    if attacker_strength > (defender_strength * 1.5) then
        modifier = modifier + 0.1  -- AI with overwhelming strength gets a small advantage
    elseif defender_strength > (attacker_strength * 1.5) then
        modifier = modifier - 0.1  -- AI with overwhelming strength against it gets a small disadvantage
    end

    if attacker_veterancy > defender_veterancy then
        modifier = modifier + 0.1  -- Experienced AI units perform better
    elseif defender_veterancy > attacker_veterancy then
        modifier = modifier - 0.1  -- Defender AI with better units gets an edge
    end
    
    if attacker_regions > (defender_regions * 2) then
        modifier = modifier + 0.15  -- If attacking AI has a much larger empire, bonus
    elseif defender_regions > (attacker_regions * 2) then
        modifier = modifier - 0.15  -- If defending AI has a much larger empire, penalty to attacker
    end
    
    if player_nearby or ally_involved then
        modifier = 1.0  -- No bonuses if the player is influencing battle
    end
    
    local balance_factor = 1.2 -- Rome/Carthage get only a small buff
scripting.game_interface:modify_next_autoresolve_battle(balance_factor, balance_factor, 0.5, 0.5, false)

end

function GetAverageUnitVeterancy(faction)
    local total_vet = 0
    local unit_count = 0
    local armies = faction:military_force_list()
    
    for i = 0, armies:num_items() - 1 do
        local army = armies:item_at(i)
        local unit_list = army:unit_list()
        for j = 0, unit_list:num_items() - 1 do
            total_vet = total_vet + unit_list:item_at(j):experience_level()
            unit_count = unit_count + 1
        end
    end
    
    return unit_count > 0 and (total_vet / unit_count) or 0
end

scripting.AddEventCallBack("PendingBattle", OnPendingBattle);