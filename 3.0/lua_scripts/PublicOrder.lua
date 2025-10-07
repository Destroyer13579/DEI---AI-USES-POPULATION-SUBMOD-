---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Public Order Script for Divide et Impera  
-- Created by Litharion
-- Last Updated: 07/12/2017

-- The content of the script belongs to the original Author and as such cannot
-- be used elsewhere without express consent.
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- Make the script a module one
module(..., package.seeall);

-- Used to have the object library able to see the variables in this new environment
_G.main_env = getfenv(1);

-- Load libraries
scripting = require "lua_scripts.EpisodicScripting";  
require "DeI_utility_functions";

public_order_effects = {
    "public_1_order", "public_2_order", "public_3_order", "public_4_order", "public_5_order", 
    "public_6_order", "public_7_order", "public_8_order", "public_9_order", "public_10_order", 
    "public_11_order", "public_12_order", "public_13_order", "public_14_order", "public_15_order", 
    "public_16_order", "public_17_order", "public_18_order", "public_19_order", "public_20_order", 
    "public_21_order", "public_22_order", "public_23_order", "public_24_order", "public_25_order", 
    "public_26_order", "public_27_order", "public_28_order", "public_29_order", "public_30_order"
};

--==============================================================
-- Apply Public Order effect bundle to character force (Balanced AI)
--===============================================================
local function PublicOrderApply(context)
    if context:character():military_force():unit_list():num_items() >= 2 then 
        local faction = context:character():faction();
        local province = context:character():garrison_residence():region():province_name();
        local factions_regions = faction:region_list();
        local public_order_change = 0;
        local matched_regions = 0;

        for i = 0, factions_regions:num_items() - 1 do
            local region = factions_regions:item_at(i);
            if region:province_name() == province then
                matched_regions = matched_regions + 1;
            end;
        end;

        local multiplier = 0.8;
        local divisor = 1.2;
        local max_public_order_penalty = -10;
        local max_public_order_bonus = 10;

        if matched_regions <= 1 then 
            multiplier = 1.0;
        elseif matched_regions == 2 then
            multiplier = 0.9;
            max_public_order_penalty = -8;
        elseif matched_regions > 2 then 
            divisor = 1.4;
            max_public_order_penalty = -5;  
        end;

        if matched_regions < 3 then
            public_order_change = math.ceil(context:character():military_force():unit_list():num_items() * multiplier);
        else 
            public_order_change = math.ceil(context:character():military_force():unit_list():num_items() / divisor);
        end;
    
        if public_order_change < max_public_order_penalty then
            public_order_change = max_public_order_penalty;
        elseif public_order_change > max_public_order_bonus then
            public_order_change = max_public_order_bonus;
        end;

        -- Apply effect bundle for both AI and player, keeping balance
        if context:character():has_garrison_residence() then 
            local cqi = context:character():cqi(); 
            for i = 1, #public_order_effects do
                scripting.game_interface:remove_effect_bundle_from_characters_force(public_order_effects[i], cqi);
            end;
            if public_order_change >= 0 then
                scripting.game_interface:apply_effect_bundle_to_characters_force("public_order_bonus_" .. public_order_change, cqi, 1);
            else
                scripting.game_interface:apply_effect_bundle_to_characters_force("public_order_penalty_" .. math.abs(public_order_change), cqi, 1);
            end;
        end;
    end;
end;

--==============================================================
-- Remove Public Order effect bundle from character force (Balanced AI)
--===============================================================
local function PublicOrderRemove(context)
    local cqi = context:character():cqi(); 
    for i = 1, #public_order_effects do
        scripting.game_interface:remove_effect_bundle_from_characters_force(public_order_effects[i], cqi);
    end;
end;

--==============================================================
-- Advisor Public Order Display (Balanced AI)
--===============================================================
local function PublicOrderDisplay(context)
    if context:character():military_force():unit_list():num_items() >= 2 then 
        local public_order_change = math.ceil(context:character():military_force():unit_list():num_items() * 0.8);
        if public_order_change > 10 then
            public_order_change = 10;
        elseif public_order_change < -10 then
            public_order_change = -10;
        end;
        effect.advance_contextual_advice_thread("Public." .. public_order_change .. ".Order", 1, context);
    end;
end;

----------------------------------------------------------------------------------------------------------------------------------------
scripting.AddEventCallBack("CharacterTurnEnd", PublicOrderApply);
scripting.AddEventCallBack("CharacterSelected", PublicOrderDisplay);
scripting.AddEventCallBack("CharacterLeavesGarrison", PublicOrderRemove);
scripting.AddEventCallBack("CharacterEntersGarrison", PublicOrderApply);
scripting.AddEventCallBack("CharacterTurnStart", PublicOrderApply);
-------------------------------------------------------------------------------------------------------------------------------------------
