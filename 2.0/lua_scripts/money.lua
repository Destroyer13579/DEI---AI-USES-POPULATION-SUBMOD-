-- ************************************************************************
-- ************************************************************************
-- ************************************************************************
-- DIVIDE ET IMPERA
-- AI Money Balancing Script
-- Author: Litharion (Modified)
--
-- ************************************************************************
-- ************************************************************************

-- ***************************************
-- General
-- ***************************************

-- Make the script a module one
module(..., package.seeall);

-- Used to have the object library able to see the variables in this new environment
_G.main_env = getfenv(1);

-- Load libraries
scripting = require "lua_scripts.EpisodicScripting";

-- ************************************************************************
--
-- GENERAL FUNCTIONS
--
-- ************************************************************************

-- Returns the current turn number
function Turn()
	return scripting.game_interface:model():turn_number()
end

-- Checks if an element is in a given list
function contains(element, list)
	for _, v in ipairs(list) do
		if element == v then
			return true;
		end
	end
	return false;
end

-- ************************************************************************
--
-- AI FINANCIAL ADJUSTMENTS
--
-- ************************************************************************

-- Adjust AI economy by providing a fair tax multiplier rather than direct money injections
function AdjustAIEconomy(context)
	local faction = context:faction();
	local factionName = faction:name();

	if faction:is_human() == false and faction:region_list():num_items() > 0 then
		-- Instead of giving free money, apply a small tax boost to help AI manage their economy fairly
		scripting.game_interface:apply_effect_bundle("AI_Fair_Tax_Boost", factionName, 0);
	end;
end;

scripting.AddEventCallBack("FactionTurnStart", AdjustAIEconomy);

-- ************************************************************************
--
-- AI Imperium-Based Bonuses (Balanced)
--
-- ************************************************************************
function AdjustAIImperiumBonuses(context)
	local faction = context:faction();
	local factionName = faction:name();

	if faction:is_human() == false and faction:region_list():num_items() > 0 then
		-- Remove unfair money cheats
		scripting.game_interface:remove_effect_bundle("AI_Imperium_Bonus_6", factionName);
		scripting.game_interface:remove_effect_bundle("AI_Imperium_Bonus_5", factionName);
		scripting.game_interface:remove_effect_bundle("AI_Imperium_Bonus_4", factionName);
		scripting.game_interface:remove_effect_bundle("AI_Imperium_Bonus_3", factionName);
		scripting.game_interface:remove_effect_bundle("AI_Imperium_Bonus_2", factionName);
		scripting.game_interface:remove_effect_bundle("AI_Imperium_Bonus_1", factionName);

		-- Apply a small scaling tax boost instead of direct cash injections
		if faction:imperium_level() > 5 then
			scripting.game_interface:apply_effect_bundle("AI_Imperium_Fair_Boost_6", factionName, 0);
		elseif faction:imperium_level() > 4 then
			scripting.game_interface:apply_effect_bundle("AI_Imperium_Fair_Boost_5", factionName, 0);
		elseif faction:imperium_level() > 3 then
			scripting.game_interface:apply_effect_bundle("AI_Imperium_Fair_Boost_4", factionName, 0);
		elseif faction:imperium_level() > 2 then
			scripting.game_interface:apply_effect_bundle("AI_Imperium_Fair_Boost_3", factionName, 0);
		elseif faction:imperium_level() > 1 then
			scripting.game_interface:apply_effect_bundle("AI_Imperium_Fair_Boost_2", factionName, 0);
		elseif faction:imperium_level() > 0 then
			scripting.game_interface:apply_effect_bundle("AI_Imperium_Fair_Boost_1", factionName, 0);
		end;
	end;
end;

scripting.AddEventCallBack("FactionTurnStart", AdjustAIImperiumBonuses);
