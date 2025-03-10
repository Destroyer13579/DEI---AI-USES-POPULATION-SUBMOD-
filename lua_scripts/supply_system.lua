-- ************************************************************************
-- ************************************************************************
-- ************************************************************************
-- DIVIDE ET IMPERA
-- Supply System Script - Fair Play Edition
-- 
-- Removes AI cheats while preserving full supply mechanics.
-- Fixes Population UI disappearance.
-- ************************************************************************
-- ************************************************************************

module(..., package.seeall);
_G.main_env = getfenv(1);

-- LIBRARIES REQUIRED
require "lua_scripts.supply_system_script_header";

-- GLOBAL VARIABLES
Nomads_Steal_Food = 0;
Supply_Message = false;
SupplyCampaignName = "none";

-- WORLD CREATION EVENT FOR SUPPLY SYSTEM
local function OnWorldCreatedSupplies(context)
	LogSupply("OnWorldCreatedSupplies(context)", "Supply script world created started", false, false);
	SupplyCampaignName = SetSupplyTable();
	AddSupplySystemListener();
	LogSupply("OnWorldCreatedSupplies(context)", "Supply script world created completed", false, false);
end;

-- SUPPLY LISTENERS
function AddSupplySystemListener()
	LogSupply("AddSupplySystemListener()", "#### Adding Supply System Listeners ####", false, false);

	cm:add_listener("FactionTurnStart_Supply", "FactionTurnStart", true,
		function(context)
			SupplySystemStart(context, true, false);
		end, true
	);

	cm:add_listener("FactionTurnEnd_Supply", "FactionTurnEnd", true,
		function(context)
			SupplySystemStart(context, false, true);
		end, true
	);

	cm:add_listener("SupplyOnCharSelected", "CharacterSelected", true,
		function(context)
			SupplyOnCharSelected(context);
		end, true
	);

	cm:add_listener("SupplyComponentMouseOn", "ComponentMouseOn", true,
		function(context)
			UI_RegionSupplyTooltip(context);
			UI_ChangeTooltip_TTIP_CTAa_Supp_0001(context);
		end, true
	);

	cm:add_listener("SupplyCharacterCompletedBattle", "CharacterCompletedBattle", true,
		function(context)
			SupplyCharacterCompletedBattle(context);
		end, true
	);
	
	cm:add_listener("SupplyCharacterParticipatedAsSecondaryGeneralInBattle", "CharacterParticipatedAsSecondaryGeneralInBattle", true,
		function(context)
			SupplyCharacterCompletedBattle(context);
		end, true
	);
	
	LogSupply("AddSupplySystemListener()", "#### Supply System Listeners initialized successfully ####", false, false);
end;

scripting.AddEventCallBack("WorldCreated", OnWorldCreatedSupplies);

-- POPULATION UI RESTORE FUNCTION
local function RestorePopulationUI(context)
	local faction = context:faction();
	if faction:is_human() then
		Trigger_Population_UI_Update();
	end;
end;

scripting.AddEventCallBack("FactionTurnStart", RestorePopulationUI);

-- SUPPLY SYSTEM START
function SupplySystemStart(context, isSupplyConsumptionOn, isSupplyProductionOn)
	local faction = context:faction();
	local AlliedFactionKeys = {};
	local EnemyFactionKeys = {};

	if Supply_Message == false then
		Show_Message_Supply_System_Start(faction);
		Supply_Message = true;
	end;

	LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "Start Supply System for "..faction:name(), true, false);
	AlliedFactionKeys, EnemyFactionKeys = SupplyGetFactionTreaties(faction:treaty_details());

	if isSupplyProductionOn then
		for i = 0, faction:region_list():num_items() - 1 do
			local region = faction:region_list():item_at(i);
			SupplyProduceSupplies(region, EnemyFactionKeys);
			LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "Produced Supplies for "..region:name(), false, false);
		end;
	end;

	if SupplyFactionisCIV(faction:culture()) then
		SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys);
	elseif SupplyFactionisNOMADIC(faction:name(), faction:subculture()) then
		SupplyNOMADICstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys);
	else
		SupplyBARstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys);
	end;
	
	BaggageTrainAmmoBonus(faction);
	LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "End SupplySystemStart for "..faction:name(), true, false);
end;

scripting.AddEventCallBack("CharacterSelected", SupplyOnCharSelected);
scripting.AddEventCallBack("SettlementSelected", SupplyOnSettlementSelected);

-- SAVE/LOAD DATA
local function Save_Values(context)
	scripting.game_interface:save_named_value("supply_message", Supply_Message, context);
	cm:save_value("SupplyCampaignName", SupplyCampaignName, context);
end;

local function Load_Values(context)
	Supply_Message = scripting.game_interface:load_named_value("supply_message", false, context);
	SupplyCampaignName = cm:load_value("SupplyCampaignName", "", context);
end;

scripting.AddEventCallBack("SavingGame", Save_Values);
scripting.AddEventCallBack("LoadingGame", Load_Values);
