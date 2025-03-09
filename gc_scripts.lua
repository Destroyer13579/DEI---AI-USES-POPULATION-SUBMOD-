---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Grand Campaign Scripts for Divide et Impera  
-- Created by Litharion
-- Last Updated: 16/03/2018

-- The content of the script belongs to the original Author and as such cannot
-- be used elsewhere without express consent.
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- Make sure escalation triggers when Rome and Carthage are at war faction declares war

-- Make the script a module one
module(..., package.seeall);

-- Used to have the object library able to see the variables in this new environment
_G.main_env = getfenv(1);

-- Load libraries
scripting = require "lua_scripts.EpisodicScripting";  
require "DeI_utility_functions";
require("lua_scripts.politsys") -- ensure gc_scripts can call 


-- Variables
AICarthageRomeEscalationTriggered = false;
AIRomeCarthageEscalationTriggered = false;
AICarthageRomeEscalationLevel = 0;
AIRomeCarthageEscalationLevel = 0;
carthage_army_2 = false;
carthage_army_3 = false;
roman_counter = 0;
upgrade_advisor_shown = {upgrade_advisor = false};
seleucid_army_1 = false;
seleucid_army_2 = false;
seleucid_army_3 = false;
seleucid_army_4 = false;
seleucid_army_5 = false;

--===================================
-- AI Dynamic Manpower Tracking --
--===================================

AI_Manpower_History = {} -- Stores 10-turn average of AI manpower

function UpdateAIMilitaryTrends(faction)
    local faction_name = faction:name()
    local current_manpower = GetFactionManpower(faction_name)
    
    if not AI_Manpower_History[faction_name] then
        AI_Manpower_History[faction_name] = {}
    end
    
    table.insert(AI_Manpower_History[faction_name], current_manpower)
    
    -- Keep only last 10 turns of manpower history
    if #AI_Manpower_History[faction_name] > 10 then
        table.remove(AI_Manpower_History[faction_name], 1)
    end
end

function GetAverageManpower(faction_name)
    local history = AI_Manpower_History[faction_name] or {}
    local total = 0
    for _, v in ipairs(history) do
        total = total + v
    end
    return (#history > 0) and (total / #history) or 0
end

--===================================
--Diplomacy & War Expansion  --
--===================================

function AdjustAIWarBehavior(faction)
    local faction_name = faction:name()
    local current_manpower = GetFactionManpower(faction_name)
    local avg_manpower = GetAverageManpower(faction_name)
    local active_wars = faction:at_war_list():num_items()

    if avg_manpower == 0 then return end  -- Avoid division by zero

    local manpower_ratio = current_manpower / avg_manpower
    local weakened = false

    -- Check if the faction is weakened (calls politsys.lua)
    if _G.isFactionWeakened then  
        weakened = _G.isFactionWeakened(faction_name)
    end

    if manpower_ratio > 1.2 then
        -- AI has excess manpower, more likely to go to war
        if active_wars < 2 then  -- Don't overextend
            CheckForStrikeWar(faction)
            CheckForBigWar(faction)
        end
    elseif manpower_ratio < 0.8 or weakened then
        -- AI has less manpower than average, avoid wars and prioritize recovery
        AdjustAIBuildingPriorities(faction)

        -- If at war with multiple factions and losing, seek peace
        if active_wars >= 2 and (manpower_ratio < 0.6 or weakened) then  
            for i = 0, faction:at_war_list():num_items() - 1 do
                local enemy = faction:at_war_list():item_at(i)
                if enemy:is_human() == false and faction:losing_war() then  -- AI must be clearly losing
                    scripting.game_interface:force_make_peace(faction:name(), enemy:name())
                end
            end
        end
    end
end


--===================================
-- AI Population & Recruitment Balancing --
--===================================

function CheckAndAdjustManpower(faction)
    local pop_level = GetFactionManpower(faction:name())
    
    -- If AI manpower is below 30%, apply recovery bonuses
    if pop_level < 30 then
        ApplyManpowerRecovery(faction:name(), pop_level)
    end
    
    -- Update AI manpower trends every turn
    UpdateAIMilitaryTrends(faction)
end

function GetFactionManpower(faction_name)
    -- Ensure population growth updates correctly
    return scripting.game_interface:model():world():faction_by_key(faction_name):population()
end

function ApplyManpowerRecovery(faction_name, pop_level)
    local growth_bonus = 0
    
    if pop_level < 10 then
        growth_bonus = 1.5  -- Large boost
    elseif pop_level < 20 then
        growth_bonus = 1.2  -- Moderate boost
    elseif pop_level < 30 then
        growth_bonus = 1.1  -- Slight boost
    end
    
    -- apply the population growth bonus dynamically
    scripting.game_interface:apply_population_growth_bonus(faction_name, growth_bonus)
end

--===================================
-- AI Building Priority Adjustments --
--===================================

function AdjustAIBuildingPriorities(faction)
    local manpower = GetFactionManpower(faction:name())
    local supply = faction:supply() -- New check for supply levels
    
    if manpower < 50 or supply < 50 then
        -- AI should prioritize in this order: growth -> military -> public order
        scripting.game_interface:prioritize_building(faction:name(), "cai_food_group")
        scripting.game_interface:prioritize_building(faction:name(), "cai_economic_group")
        scripting.game_interface:prioritize_building(faction:name(), "cai_military_land_group")
        scripting.game_interface:prioritize_building(faction:name(), "cai_public_order_group")
    end
end

--===================================
-- AI War Exhaustion System --
--===================================
AI_War_Tracking = {}  -- Store war duration, manpower losses, and territory loss per faction

function TrackWarExhaustion(faction)
    local faction_name = faction:name()
    if not AI_War_Tracking[faction_name] then
        AI_War_Tracking[faction_name] = {war_duration = {}, manpower_lost = {}, territory_lost = {}} 
    end

    for _, enemy in pairs(faction:at_war_with()) do
        local enemy_name = enemy:name()
        if not AI_War_Tracking[faction_name].war_duration[enemy_name] then
            AI_War_Tracking[faction_name].war_duration[enemy_name] = scripting.game_interface:model():turn_number()
            AI_War_Tracking[faction_name].manpower_lost[enemy_name] = 0
            AI_War_Tracking[faction_name].territory_lost[enemy_name] = faction:region_list():num_items()
        else
            local initial_territory = AI_War_Tracking[faction_name].territory_lost[enemy_name]
            AI_War_Tracking[faction_name].territory_lost[enemy_name] = faction:region_list():num_items()
            AI_War_Tracking[faction_name].manpower_lost[enemy_name] = AI_War_Tracking[faction_name].manpower_lost[enemy_name] + GetManpowerLoss(faction_name)
        end
    end
end

function GetManpowerLoss(faction_name)
    local current_manpower = GetFactionManpower(faction_name)
    local avg_manpower = GetAverageManpower(faction_name)
    return math.max(avg_manpower - current_manpower, 0)  -- Ensure non-negative losses
end

function CheckForPeace(faction)
    local faction_name = faction:name()
    if not AI_War_Tracking[faction_name] then return end
    
    for enemy_name, start_turn in pairs(AI_War_Tracking[faction_name].war_duration) do
        local war_turns = scripting.game_interface:model():turn_number() - start_turn
        local manpower_lost = AI_War_Tracking[faction_name].manpower_lost[enemy_name]
        local initial_territory = AI_War_Tracking[faction_name].territory_lost[enemy_name]
        local current_territory = faction:region_list():num_items()
        local territory_lost = initial_territory - current_territory
        
        local peace_weight = 0
        if war_turns > 20 then peace_weight = peace_weight + 20 end
        if manpower_lost > GetFactionManpower(faction_name) * 0.8 then peace_weight = peace_weight + 30 end
        if territory_lost > 2 then peace_weight = peace_weight + 25 end
        if current_territory < 3 then peace_weight = peace_weight + 40 end
        if faction:capital():is_under_siege() then peace_weight = peace_weight + 50 end
        
        if math.random(1, 100) <= peace_weight then
            scripting.game_interface:propose_peace(faction_name, enemy_name)
        end
    end
end

--===================================
-- FactionCampaignScripts Listener --
--===================================

local function OnWorldCreatedCampaign(context)
    AddCampaignListener();
    Log("OnWorldCreatedCampaign(context)", "Campaign script world created", true, true);
end;

function AddCampaignListener()
    Log("OnWorldCreatedCampaign()", "#### Adding Campaign Listeners ####", false, false);
    
    cm:add_listener(
    "FactionTurnStart_AIManagement",
    "FactionTurnStart",
    function(context)
        local faction = context:faction();
        return not faction:is_human();
    end,
    function(context)
        local faction = context:faction();

        -- AI Population & Manpower
        CheckAndAdjustManpower(faction)
        AdjustAIRecruitment(faction)
        AdjustAIBuildingPriorities(faction)
        AdjustAIWarBehavior(faction)
        
        -- AI War Exhaustion
        TrackWarExhaustion(faction)
        CheckForPeace(faction)
    end,
    true
)
end;

scripting.AddEventCallBack("WorldCreated", OnWorldCreatedCampaign);
