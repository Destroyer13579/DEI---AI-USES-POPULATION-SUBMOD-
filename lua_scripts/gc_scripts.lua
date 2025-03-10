---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Grand Campaign Scripts for Divide et Impera  
-- Created by Litharion
-- Updated & Balanced by Destroyer
-- Organized by ChatGBT
-- Last Updated: [03/10/2025]

-- **PLEASE NOTE** I am solo on this, and some of these features may not be fully implemented or work just right -- yet! - Destroyer
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



--===========================
-- Dynamic Punic War System - replaces old one, i=no fixed state, just static chance leading up 
--===========================

PunicWarChance = 0

function CheckForPunicWar()
    local turn_number = scripting.game_interface:model():turn_number()
    local rome = scripting.game_interface:model():world():faction_by_key("rom_rome")
    local carthage = scripting.game_interface:model():world():faction_by_key("rom_carthage")

    -- If they are already at war, stop checking
    if rome:at_war_with(carthage) then return end  

    -- Increase war likelihood every 10 turns
    if turn_number % 10 == 0 then  
        PunicWarChance = PunicWarChance + 5
    end

    -- If either Rome expands into Corsica/Sardinia, or Carthage takes Sicily, trigger war immediately
    local rome_owns_corsica = rome:has_region("corsica_region") or rome:has_region("sardinia_region")
    local carthage_owns_sicily = carthage:has_region("sicily_region")

    if rome_owns_corsica or carthage_owns_sicily then
        scripting.game_interface:force_declare_war("rom_rome", "rom_carthage")
        return
    end

    -- At turn 50, war is **guaranteed**
    if turn_number >= 50 or math.random(1, 100) <= PunicWarChance then
        scripting.game_interface:force_declare_war("rom_rome", "rom_carthage")
    end
end

--===================================
-- AI Dynamic Manpower Tracking -- tracks AI manpower to influence other decisions
--===================================

AI_Manpower_History = {} -- stores 10-turn average of AI manpower

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
-- Fine-Tuned Diplomacy & War Expansion Rules --
--===================================

function AdjustAIArmyBehavior(faction)
    local faction_name = faction:name()
    local armies = faction:military_force_list()

    for i = 0, armies:num_items() - 1 do
        local army = armies:item_at(i)
        
        if not army:is_embedded_in_army() then
            local best_target, best_distance = nil, math.huge

            -- Find the nearest enemy region
            local enemy_factions = faction:at_war_with()
            for j = 0, enemy_factions:num_items() - 1 do
                local enemy = enemy_factions:item_at(j)
                local regions = enemy:region_list()
                for k = 0, regions:num_items() - 1 do
                    local region = regions:item_at(k)
                    local distance = faction:model():campaign_ai():calculate_region_distance(army:region(), region)

                    if distance < best_distance then
                        best_target, best_distance = region, distance
                    end
                end
            end

            -- Attack or move towards target
            if best_target then
                scripting.game_interface:order_move(army, best_target)
            end
        end
    end
end

--===================================
-- AI Strike & Big War Logic ---- strike = attacing smaller nation - big = attacking another super power--
--===================================

function CheckForBigWar(faction) -- big war = faction declares to curb another nation's growing power
    local faction_name = faction:name()
    local faction_regions = faction:region_list():num_items()
    local potential_targets = faction:model():world():faction_list()

    for i = 0, potential_targets:num_items() - 1 do
        local target = potential_targets:item_at(i)
        if not faction:at_war_with(target) then
            local target_strength = GetFactionManpower(target:name())
            local target_regions = target:region_list():num_items()
            local target_expansion = GetRecentExpansion(target) -- new function to track expansion
            local border_vulnerable = IsBorderVulnerable(faction, target) -- new function to check weak defenses

            -- AI conditions for declaring a "Big War"
            if (target_expansion >= 3 or faction_regions * 2 <= target_regions) or border_vulnerable then
                -- If AI has military allies, increase war probability
                if faction:military_allies():num_items() > 0 or faction_strength >= (target_strength * 0.9) then
                    scripting.game_interface:force_declare_war(faction_name, target:name())
                end
            end
        end
    end
end

function GetRecentExpansion(faction)
    local faction_name = faction:name()
    if AI_War_Tracking[faction_name] and AI_War_Tracking[faction_name].territory_lost then
        return AI_War_Tracking[faction_name].territory_lost
    end
    return 0
end

function IsBorderVulnerable(attacker, defender)
    local attacker_regions = attacker:region_list()
    local defender_regions = defender:region_list()

    for i = 0, attacker_regions:num_items() - 1 do
        local region = attacker_regions:item_at(i)
        local adjacent_regions = region:adjacent_region_list()

        for j = 0, adjacent_regions:num_items() - 1 do
            local adj_region = adjacent_regions:item_at(j)
            if adj_region:owning_faction():name() == defender:name() and adj_region:garrison_residence():num_units() <= 4 then
                return true -- If the enemy has a weak garrison = AI considers war
            end
        end
    end
    return false
end

function AdjustAISiegeBehavior(faction)
    local faction_name = faction:name()
    local armies = faction:military_force_list()

    for i = 0, armies:num_items() - 1 do
        local army = armies:item_at(i)
        local army_region = army:region()

        if army_region and army_region:is_under_siege() then
            local enemy_strength = GetEnemyStrengthInRegion(army_region)
            local our_strength = army:strength()

            -- AI will hold siege unless they are outnumbered 3:1
            if enemy_strength / our_strength > 3 then
                scripting.game_interface:order_retreat(army, faction:capital_region())
            else
                scripting.game_interface:order_attack(army, army_region)
            end
        end
    end
end


function ReinforceBorderSettlements(faction)
    local faction_name = faction:name()
    local faction_regions = faction:region_list()

    for i = 0, faction_regions:num_items() - 1 do
        local region = faction_regions:item_at(i)
        local adjacent_regions = region:adjacent_region_list()

        for j = 0, adjacent_regions:num_items() - 1 do
            local adj_region = adjacent_regions:item_at(j)
            local enemy_faction = adj_region:owning_faction()

            if enemy_faction:at_war_with(faction) then
                local enemy_armies = adj_region:military_force_list():num_items()
                local garrison_strength = region:garrison_residence():num_units()
                local our_armies = GetNearbyArmies(faction, region)

                -- AI reinforces if enemy is near and has at least two armies
                if enemy_armies >= 2 and garrison_strength < 6 and #our_armies > 0 then
                    scripting.game_interface:order_move(our_armies[1], region)
                    return -- AI reinforces only one settlement per turn
                end
            end
        end
    end
end


function AdjustAISallyOutBehavior(faction)
    local faction_name = faction:name()
    local armies = faction:military_force_list()

    for i = 0, armies:num_items() - 1 do
        local army = armies:item_at(i)
        local army_region = army:region()

        if army_region and army_region:is_under_siege() then
            local garrison_strength = army_region:garrison_residence():strength()
            local enemy_strength = GetEnemyStrengthInRegion(army_region)

            -- AI will only sally out if they have at least 70% of the enemy strength
            if garrison_strength / enemy_strength < 0.7 then
                -- AI stay inside instead of suiciding
                return
            end
        end
    end
end


function CheckForStrikeWar(faction) -- strike war = stronger enemy attacks weaker nation
    local faction_name = faction:name()
    local neighbors = faction:adjacent_factions()
    local active_wars = faction:at_war_list():num_items()
    local faction_regions = faction:region_list():num_items()

    if active_wars >= 2 then return end -- AI avoids overextending

    for i = 0, neighbors:num_items() - 1 do
        local neighbor = neighbors:item_at(i)
        if not faction:at_war_with(neighbor) then
            local our_strength = GetFactionManpower(faction_name)
            local neighbor_strength = GetFactionManpower(neighbor:name())
            local neighbor_regions = neighbor:region_list():num_items()
            local neighbor_weakened = IsFactionWeakened(neighbor) -- new function
            local war_randomizer = math.random() < 0.12 -- 12% chance of random war

            -- AI declares war based on multiple conditions
            if (our_strength > (neighbor_strength * 1.3) and faction_regions >= neighbor_regions) 
                or neighbor_weakened or war_randomizer then
                scripting.game_interface:force_declare_war(faction_name, neighbor:name())
                break -- AI only declares **one** war per turn
            end
        end
    end
end

function IsFactionWeakened(faction)
    local strength_ratio = faction:military_strength() / GetEnemyStrength(faction)
    local lost_cities = faction:region_list():num_items() < faction:home_region_count()
    local recent_defeats = GetFactionDefeats(faction:name()) > GetFactionVictories(faction:name())
    local war_weariness = GetWarWeariness(faction:name())

    if strength_ratio < 0.6 or lost_cities or recent_defeats or war_weariness > 50 then
        return true
    end
    return false
end

--===================================
-- Fine-Tuned Diplomacy & War Expansion Rules 3.4 --
--===================================

function AdjustAIArmyBehavior(faction)
    local faction_name = faction:name()
    local armies = faction:military_force_list()

    for i = 0, armies:num_items() - 1 do
        local army = armies:item_at(i)
        
        if not army:is_embedded_in_army() then
            local army_location = army:region()
            local enemy_nearby = false

            -- Check if there's an enemy nearby
            local region_list = army_location:adjacent_region_list()
            for j = 0, region_list:num_items() - 1 do
                local region = region_list:item_at(j)
                if region:owning_faction():at_war_with(faction) then
                    enemy_nearby = true
                    break
                end
            end

            -- If enemy is nearby, attack or reposition
            if enemy_nearby then
                scripting.game_interface:order_attack(army, enemy_nearby)
            else
                -- Move army towards enemy region
                local target_region = GetNearestEnemyRegion(faction)
                if target_region then
                    scripting.game_interface:order_move(army, target_region)
                end
            end
        end
    end
end

function GetNearestEnemyRegion(faction)
    local enemy_factions = faction:at_war_with()
    
    for i = 0, enemy_factions:num_items() - 1 do
        local enemy = enemy_factions:item_at(i)
        local regions = enemy:region_list()
        if regions:num_items() > 0 then
            return regions:item_at(0) -- return the first enemy region found
        end
    end

    return nil
end


function PrioritizeBorderSieges(faction)
    local faction_name = faction:name()
    local border_regions = faction:region_list()

    for i = 0, border_regions:num_items() - 1 do
        local region = border_regions:item_at(i)
        local adjacent_regions = region:adjacent_region_list()

        for j = 0, adjacent_regions:num_items() - 1 do
            local adj_region = adjacent_regions:item_at(j)
            local enemy_faction = adj_region:owning_faction()

            if enemy_faction:at_war_with(faction) then
                local garrison_strength = adj_region:garrison_residence():num_units()
                local nearby_armies = GetNearbyArmies(faction, adj_region)

                -- AI prioritizes attacking if the enemy border city is weak
                if garrison_strength < 5 and #nearby_armies > 0 then
                    scripting.game_interface:order_attack(nearby_armies[1], adj_region)
                    return -- AI only picks one siege target per turn
                end
            end
        end
    end
end

function ReinforceBorderSettlements(faction)
    local faction_name = faction:name()
    local faction_regions = faction:region_list()

    for i = 0, faction_regions:num_items() - 1 do
        local region = faction_regions:item_at(i)
        local adjacent_regions = region:adjacent_region_list()

        for j = 0, adjacent_regions:num_items() - 1 do
            local adj_region = adjacent_regions:item_at(j)
            local enemy_faction = adj_region:owning_faction()

            if enemy_faction:at_war_with(faction) then
                local enemy_armies = adj_region:military_force_list():num_items()
                local garrison_strength = region:garrison_residence():num_units()
                local our_armies = GetNearbyArmies(faction, region)

                -- AI reinforces borders only if enemy threat is significant
                if enemy_armies > 1 and garrison_strength < 6 and #our_armies > 0 then
                    scripting.game_interface:order_move(our_armies[1], region)
                    return -- AI reinforces only one settlement per turn
                end
            end
        end
    end
end

function PreventUselessRetreats(faction)
    local faction_name = faction:name()
    local armies = faction:military_force_list()

    for i = 0, armies:num_items() - 1 do
        local army = armies:item_at(i)
        local army_location = army:region()
        local enemy_nearby = false
        local our_strength = army:strength()
        local enemy_strength = GetEnemyStrengthInRegion(army_location)

        -- AI only retreats if outnumbered 2:1
        if enemy_strength > (our_strength * 2) then
            scripting.game_interface:order_retreat(army, faction:capital_region())
        else
            -- AI holds ground instead of retreating too much
            enemy_nearby = true
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
    
    -- Apply the population growth bonus dynamically
    scripting.game_interface:apply_population_growth_bonus(faction_name, growth_bonus)
end

--===================================
-- AI Building Priority Adjustments -- focus on growth and conomy over military = works well with AI using popualtion system 
--===================================

function AdjustAIBuildingPriorities(faction)
    local manpower = GetFactionManpower(faction:name())
    local supply = faction:supply() -- New check for supply levels
    
    if manpower < 50 or supply < 50 then
        -- AI should prioritize growth -> military -> public order
        scripting.game_interface:prioritize_building(faction:name(), "cai_food_group")
        scripting.game_interface:prioritize_building(faction:name(), "cai_economic_group")
        scripting.game_interface:prioritize_building(faction:name(), "cai_military_land_group")
        scripting.game_interface:prioritize_building(faction:name(), "cai_public_order_group")
    end
end

--===================================
-- AI War Exhaustion System (new 3.4) --
--===================================
AI_War_Tracking = {}  -- stores  war duration, manpower losses, and territory loss per faction

function TrackMajorArmyLosses(faction, army_size_before, army_size_after)
    local faction_name = faction:name()

    if not AI_War_Tracking[faction_name] then
        AI_War_Tracking[faction_name] = {war_duration = {}, manpower_lost = {}, territory_lost = {}, desperate = false, desperate_since = 0} 
    end

    -- If AI lost 90%+ of its army, mark as desperate
    if army_size_before > 5000 and (army_size_after / army_size_before) < 0.1 then
        AI_War_Tracking[faction_name].desperate = true
        AI_War_Tracking[faction_name].desperate_since = scripting.game_interface:model():turn_number()
    end
end


function ProcessWarDesperation(faction)
    local faction_name = faction:name()
    if not AI_War_Tracking[faction_name] or not AI_War_Tracking[faction_name].desperate then return end

    local faction_regions = faction:region_list():num_items()
    local turn_number = scripting.game_interface:model():turn_number()
    local turns_since_desperate = turn_number - AI_War_Tracking[faction_name].desperate_since

    local peace_chance = 0
    local peace_turns = 0

    if faction_regions <= 2 then
        peace_chance = 85
        peace_turns = 2
    elseif faction_regions <= 5 then
        peace_chance = 60
        peace_turns = 3
    elseif faction_regions <= 10 then
        peace_chance = 30
        peace_turns = 4
    else
        return -- Major factions don't use this system
    end

    -- Only check for peace every X turns based on faction size
    if turns_since_desperate % peace_turns == 0 then
        if math.random(1, 100) <= peace_chance then
            -- Find a reasonable enemy to request peace with
            for i = 0, faction:at_war_list():num_items() - 1 do
                local enemy = faction:at_war_list():item_at(i)
                if not enemy:is_human() then -- AI doesn't sue for peace with humans unless completely losing
                    scripting.game_interface:force_make_peace(faction:name(), enemy:name())
                end
            end
        end
    end
end


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

    if avg_manpower == 0 then return 0 end -- prevent division errors

    return math.max(avg_manpower - current_manpower, 1)  -- ensure loss is always a valid positive number
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
        AdjustAIBuildingPriorities(faction)
        AdjustAIWarBehavior(faction)
        AdjustAIArmyBehavior(faction) -- Ensure armies move properly
        ProcessWarDesperation(faction) -- NEW: AI will check if it's in desperation mode
        PrioritizeBorderSieges(faction) -- AI now attacks empty/weak settlements
        ReinforceBorderSettlements(faction) -- AI reinforces borders more effectively
        PreventUselessRetreats(faction) -- AI stops retreating when unnecessary

        -- NEW FEATURES FOR VERSION 3.5:
        AdjustAISallyOutBehavior(faction) -- AI sallies out less
        AdjustAISiegeBehavior(faction) -- AI holds siege instead of raiding
        ReinforceBorderSettlements(faction) -- AI reinforces borders smarter

        -- **NEW: Punic War Trigger** 3.5
        if faction:name() == "rom_rome" then
            CheckForPunicWar()
        end
    end,
    true
)
end;

scripting.AddEventCallBack("WorldCreated", OnWorldCreatedCampaign);

