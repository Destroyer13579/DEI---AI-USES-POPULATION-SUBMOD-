---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- Divide et Impera
-- Supply System Script 3.0
-- Created by Litharion
-- Last Updated: 30/01/2022

-- The content of the script belongs to the orginial Author and as such cannot
-- be used elsewhere without express consent.

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Version 3.0 BETA
-- NEW FEATURES:
	-- If faction has food shortage stored supplies will generate max 1 food per 50 stored supplies per region [open]
	-- greatly improved movement bonus for transport fleets +100% first turn after embarking - Player Only [Experimental]
	-- Army UI with detailed informations about supply state [mostly done]
	-- Culture specific flavour text [open]
	-- Navy UI with detailed informations? [mostly done]
	-- Each baggage train carries up to 100 supply points [open]
-- Balancing:
	-- Changes on Supply production and capacities:
		-- Supply storage increased making defending easier and attacking harder [done]
		-- Replenishment of supplies is split in half between storage and region supplies [done]
		-- Supply storage will not replenish if the region is under siege [done]
		-- Local supply replenishment is reduced by 30% if region is under siege [done]
		-- If enemy armies are present and the region is not under siege supply storage replenishment is reduced by 50% [open]
		-- Buildings will have more and varied effects on supply production taking the level of the building into account [open]
		-- seasons will have a bigger impact on supply production [WIP]
	-- Changes to supply consumption:
		-- Local region owning armies will use storage supplies before local supplies [done]
		-- Enemy armies will not have access to storage supplies [done]
		-- Allies use faction storage [open]
-- Technical:
	-- restructure script code [WIP]
	-- improved logging [WIP]
-- Bug Fixes:
	-- Navy to Transport supply bundle added [done]
	-- various fixes for barbarian supply function [done]
	-- added starting message back [done]
	-- fixed global supply for Navies in Ports [done]
	-- implement missing Event Messages Alpine, Winter, Fleets [open]
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Make the script a module one
module(..., package.seeall);

-- Used to have the object library able to see the variables in this new environment
_G.main_env = getfenv(1);

-- LIBRARIES REQUIRED
require "lua_scripts.supply_system_script_header";

-- global variables
Nomads_Steal_Food = 0;
Supply_Message = false;
SupplyCampaignName = "none";

--[[
##### START #####
***** ON WORLD CREATED SUPPLIES *****
Initialize Supply System listeners on World created event
--]]


local function OnWorldCreatedSupplies(context)
	LogSupply("OnWorldCreatedSupplies(context)", "Supply script world created started", false, false); -- true -- true
	SupplyCampaignName = SetSupplyTable();
	AddSupplySystemListener();
	LogSupply("OnWorldCreatedSupplies(context)", "Supply script world created completed", false, false);
end;

-- ***** SUPPLY LISTENERS ***** --

function AddSupplySystemListener()
	LogSupply("AddSupplySystemListener()", "#### Adding Supply System Listeners ####", false, false);

	cm:add_listener(
		"FactionTurnStart_Supply",
		"FactionTurnStart",
		true,

		function(context)
			SupplySystemStart(context, true, false);
		end,
		true
	);

	cm:add_listener(
		"FactionTurnEnd_Supply",
		"FactionTurnEnd",
		true,
		function(context)
			SupplySystemStart(context, false, true);
			-- RESET IMPORT EXPORT TABLE FOR FACTION X
		end,
		true
	);

	cm:add_listener(
		"SupplyOnCharSelected",
		"CharacterSelected",
		true,
		function(context)
			SupplyOnCharSelected(context);
			BaggageTrainAmmoBonusChar(context);
			UI_Supply_Char_TIMETRIGGERS(context);
		end,
		true
	);

	cm:add_listener(
		"SupplyComponentMouseOn",
		"ComponentMouseOn",
		true,
		function(context)
			UI_RegionSupplyTooltip(context);
			UI_ChangeTooltip_TTIP_CTAa_Supp_0001(context);
		end,
		true
	);

	-- prevents disease spreading
	cm:add_listener(
		"SupplyCharacterCompletedBattle",
		"CharacterCompletedBattle",
		true,
		function(context)
			SupplyCharacterCompletedBattle(context);
		end,
		true

	);
	-- prevents disease spreading
	cm:add_listener(
		"SupplyCharacterParticipatedAsSecondaryGeneralInBattle",
		"CharacterParticipatedAsSecondaryGeneralInBattle",
		true,
		function(context)
			SupplyCharacterCompletedBattle(context);
		end,
		true
	);
	LogSupply("AddSupplySystemListener()", "#### Supply System Listeners initialized successfully ####", false, false);
end;

scripting.AddEventCallBack("WorldCreated", OnWorldCreatedSupplies)


--[[
***** ON WORLD CREATED SUPPLIES *****
##### END #####
--]]

--##### START #####
--***** SUPPLY SYSTEM START *****
--SupplySystemStart initializes the whole supply system, production, supply lines, baggage trains.
--There are no UI functions within SupplySystemStart

function SupplySystemStart(context, isSupplyConsumptionOn, isSupplyProductionOn)

	local faction = context:faction()
	local AlliedFactionKeys = {};
	local EnemyFactionKeys = {};

	if Supply_Message == false then
		Show_Message_Supply_System_Start(faction)
		Supply_Message = true;
	end;

	LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "Start Supply System for "..faction:name(), true, false);
	AlliedFactionKeys, EnemyFactionKeys = SupplyGetFactionTreaties(faction:treaty_details());

	-- Part 1 Produce
	if isSupplyProductionOn
	then
		for i = 0, faction:region_list():num_items() -1
		do
			local region = faction:region_list():item_at(i)
			SupplyProduceSupplies(region, EnemyFactionKeys)
			LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "Produced Supplies for "..region:name(), false, false);
		end;
	end;

	--Part 2 Armies for Faction
	if SupplyFactionisNOMADIC(faction:name(), faction:subculture())
	then
		LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "SupplyFactionisNOMADIC: true", false, false);
		SupplyNOMADICstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys);
	elseif SupplyFactionisCIV(faction:culture())
	then
		SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys);
	else
		LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "SupplyFactionisBAR: true", false, false);
		SupplyBARstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys);
	end;
	-- Part 3 Baggage Train Ammo Bonus
	BaggageTrainAmmoBonus(faction)
	LogSupply("SupplySystemStart(contextFaction,"..tostring(isSupplyConsumptionOn)..", "..tostring(isSupplyProductionOn)..")", "End SupplySystemStart for "..faction:name(), true, false);
end;

--##### END #####
--***** SUPPLY SYSTEM START *****


-- ***** CHARACTER COMPLETED BATTLE ***** --

function SupplyCharacterCompletedBattle(context)
	LogSupply("CharacterCompletedBattle(context)","Battle completed: "..context:character():get_forename().." Faction Name: "..context:character():faction():name())
	local army = context:character():cqi()
	RemoveBundle(army, attrition_effects)
	LogSupply("CharacterCompletedBattle(context)","!!!Removed attrition_effects after battle for: "..army)
end;

--[[
##### END #####
***** All Listener Functions *****
***** Function List *****
SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)
SupplyCivForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)
SupplyNOMADICstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)
SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)
SupplyBARstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)
SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)
--]]

-- ##### START #####
-- initialize all culture specific supply functions
-- #####-------#####

-- ***** SUPPLY BAR START ***** --

function SupplyBARstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)

	LogSupply("SupplyBARstart(faction, isSupplyConsumptionOn)", "Start SupplyBARstart");
	local isAI = true;

	if faction:is_human() then
		isAI = false;
	end;

	local GlobalSupplies = 0;
	local NewGlobalSupplies = 0;
	local AvailableFood = faction:total_food()
	LogSupply("SupplyBARstart(faction, isSupplyConsumptionOn)", "AvailableFood "..AvailableFood)

	local forces = faction:military_force_list():num_items();
	for i = 0, forces - 1 do
		local force = faction:military_force_list():item_at(i);

		if force:has_general() then
			local ForceGeneral = force:general_character();
		-- check if type is general!
			if ForceGeneral:character_type("general") then
				SupplyCharGarbageCollector(ForceGeneral);
				if SupplyCharisTransportFleet(ForceGeneral) then
					NewGlobalSupplies = SupplyTransportShipsforChar(ForceGeneral);
					GlobalSupplies = GlobalSupplies + NewGlobalSupplies;
				elseif SupplyCharisAdmiral(ForceGeneral)then
					NewGlobalSupplies = SupplyNavalforChar(ForceGeneral);
					GlobalSupplies = GlobalSupplies + NewGlobalSupplies;
				elseif SupplyCharacterisGeneral(ForceGeneral)then
					NewGlobalSupplies = SupplyBarForChar(ForceGeneral, isSupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)
					GlobalSupplies = GlobalSupplies + NewGlobalSupplies;
				end;
			end;
		end;
	end;
	SupplyGlobalFoodSupplyCosts(GlobalSupplies, faction);
end;

-- ***** SUPPLY NOMADIC START ***** --

function SupplyNOMADICstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)

	LogSupply("SupplyNOMADICstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)", "Start SupplyNOMADICstart");
	local isAI = true

	if faction:is_human() then
		isAI = false
	end

	local AvailableFood = faction:total_food()
	LogSupply("SupplyNOMADICstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)", "AvailableFood "..AvailableFood)

	local forces = faction:military_force_list():num_items();
	for i = 0, forces - 1 do
		local force = faction:military_force_list():item_at(i);

		if force:has_general() then
			local ForceGeneral = force:general_character();

			if ForceGeneral:character_type("general") then
				SupplyCharGarbageCollector(ForceGeneral);
				if SupplyCharisTransportFleet(ForceGeneral) then
					SupplyTransportShipsforChar(ForceGeneral);
				elseif SupplyCharisAdmiral(ForceGeneral) then
					SupplyNavalforChar(ForceGeneral);
				elseif SupplyCharacterisGeneral(ForceGeneral) then
					SupplyNomadicForChar(ForceGeneral, isSupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys);
				end;
			end;
		end;
	end;
end;

-- ***** SUPPLY CIV START ***** --

function SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)

	LogSupply("SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)", "Start SupplyCIVstart");
	local isAI = true

	if faction:is_human() then
		isAI = false
	end;

	local AvailableFood = faction:total_food()
	LogSupply("SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)", "AvailableFood: "..AvailableFood)

	local GlobalSupplies = 0;
	local NewGlobalSupplies = 0;
	local forces = faction:military_force_list():num_items();

	for i = 0, forces - 1 do
		local force = faction:military_force_list():item_at(i);

		if force:has_general() then
			local ForceGeneral = force:general_character();
			-- implement check! if no food is available we stop the functions
			if ForceGeneral:character_type("general") then
				SupplyCharGarbageCollector(ForceGeneral);
				if SupplyCharisTransportFleet(ForceGeneral) then
					NewGlobalSupplies = SupplyTransportShipsforChar(ForceGeneral, AvailableFood);
					GlobalSupplies = GlobalSupplies + NewGlobalSupplies;
					-- every army needs one or two food points globaly
					-- AvailableFood = AvailableFood - NewGlobalSupplies
					AvailableFood = AvailableFood - NewGlobalSupplies
				elseif SupplyCharisAdmiral(ForceGeneral) then
					NewGlobalSupplies = SupplyNavalforChar(ForceGeneral);
					GlobalSupplies = GlobalSupplies + NewGlobalSupplies;
				elseif SupplyCharacterisGeneral(ForceGeneral) then
					NewGlobalSupplies = SupplyCivForChar(ForceGeneral, isSupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys);
					LogSupply("SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)", "NewGlobalSupplies: "..tostring(NewGlobalSupplies));
					GlobalSupplies = GlobalSupplies + NewGlobalSupplies;
					LogSupply("SupplyCIVstart(faction, isSupplyConsumptionOn, AlliedFactionKeys, EnemyFactionKeys)", "GlobalSupplies: "..GlobalSupplies);
				end;
			end;
		end;
	end;
	SupplyGlobalFoodSupplyCosts(GlobalSupplies, faction);
end;


-- ***** SUPPLY FLEET TRANSPORT LEAVES PORT ***** --

local function SupplyFleetTransportLeavesPort(context)

	local army = context:character():cqi();

	if context:character():has_military_force() == true
	and (char_is_general_with_navy(context:character())) then
		scripting.game_interface:remove_effect_bundle_from_characters_force("Naval_Resupply", army);
		scripting.game_interface:remove_effect_bundle_from_characters_force("Naval_Resupply_2", army);
		scripting.game_interface:remove_effect_bundle_from_characters_force("CIV_Naval_Resupply_2", army);
		scripting.game_interface:remove_effect_bundle_from_characters_force("CIV_Naval_Resupply", army);
	end;
end;

scripting.AddEventCallBack("CharacterLeavesGarrison", SupplyFleetTransportLeavesPort);


-- ***** SUPPLY CIV FOR CHAR ***** --
function SupplyCivForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)

	LogSupply("SupplyCivForChar(curr_char, SupplyConsumptionOn, isAI)", "Start SupplyCivForChar")

	local GlobalSupplyCosts = 0;
	local supply_usage = "player"

	if isAI then supply_usage = "ai" end;

	if character_under_siege(curr_char) == false then

		LogSupply("SupplyCivForChar()","Start of Player Supply Line Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name());
		local season = current_Season();

		local army = curr_char:cqi();
		local char_faction = curr_char:faction():name();
		local region_name = curr_char:region():name();
		local region_id = curr_char:region();
		local home_region = curr_char:faction():home_region();
		local x = curr_char:logical_position_x();
		local y = curr_char:logical_position_y();
		local turns_in_region = curr_char:turns_in_enemy_regions(); -- get baggage train supplies
		local army_size = SupplyArmySize(curr_char:military_force());
		local supply_consumption = 0;
		local supply_shif = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_supply_shift"]);
		local regional_supplies = Supply_Region_Table[region_name];
		local regional_storage_supplies = Supply_Storage_Table[region_name];
		local supply_line = false;
		local culture = "civilized";
		local supply_effect = "none";
		LogSupply("SupplyCivForChar()","Region with: ".." regional_supplies: "..Supply_Region_Table[region_name].." for char: ".. curr_char:get_forename());


		local owner = false;
		if region_id:garrison_residence():faction():name() == char_faction then
			owner = true
		end;

		local HasMinSupplies = false;
		-- or if is ally!
		if owner and regional_supplies + regional_storage_supplies >= global_supply_variables.supply_values_table["devastated_region"] then
			HasMinSupplies = true;
		elseif regional_supplies >= global_supply_variables.supply_values_table["devastated_region"] then
			HasMinSupplies = true;
		end;

		LogSupply("SupplyCivForChar()","Set local variables for Player Supply Line Function for: ".. curr_char:get_forename());
		-- Step.1 remove all old effects bundles
		--RemoveBundle(army, supply_bundle_list)
		--LogSupply("SupplyCivForChar()","Remove civ effect bundles for: "..army)

		-- Step. 2 First we check all possible supply states if no food shortage happens
		LogSupply("SupplyCivForChar()","Check Global Food shortage")
		if not curr_char:faction():has_food_shortage() then
			LogSupply("SupplyCivForChar()","Check if Char is in owned region with enough supplies")
			if owner and not region_id:garrison_residence():is_under_siege() then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_civ_owned_region_base"])
				LogSupply("SupplyCivForChar()","supply_consumption: "..supply_consumption)

				-- Step. 2a makes sure that single region factions with enough food do not suffer attrition
				LogSupply("SupplyCivForChar()","Start Open Market Capital for: "..region_name.." Command Queue Index: "..army)
				if CivHomeRegionSupply(curr_char, region_name, home_region, army) then SupplyUpdateArmyState(army, "Home_Supply", region_name, supply_consumption, SupplyConsumptionOn, owner);
					GlobalSupplyCosts = 1;
					LogSupply("SupplyCivForChar()","Applied Effect Army Open Market Capital: "..region_name.." Command Queue Index: "..army)
					return GlobalSupplyCosts;
				end;

				if HasMinSupplies then
					-- Step. 2b check if open market
					LogSupply("SupplyCivForChar()","Start Army open market in region for: "..region_name.." Command Queue Index: "..army)

					if civ_own_regions_open_market(curr_char, region_name, region_id, army, x, y) then
						supply_effect = "Home_Supply";
					elseif civ_own_regions_forced_local_supply(curr_char, region_name, region_id, army, x, y) then
						supply_effect = "Home_Supply_forced";
					elseif civ_own_regions_local_suppy_line(curr_char, region_name, region_id, army, char_faction, EnemyFactionKeys) then
						supply_effect = "Supply_Line_local";
					end;

					if supply_effect ~= "none" then
						LogSupply("SupplyCivForChar()","Applied Effect: "..supply_effect.. " " ..curr_char:region():name().."Command Queue Index: "..army)
						GlobalSupplyCosts = 1;
						SupplyUpdateArmyState(army, supply_effect, region_name, supply_consumption, SupplyConsumptionOn, owner);
						return GlobalSupplyCosts;
					end;

				-- Step. 2c Seaport supply
				elseif HasMinSupplies == false
					then LogSupply("SupplyCivForChar()","Start own region supply without enough supplies in: "..region_name.." Command Queue Index: "..army)

					if civ_seaport_supply(region_id, army, char_faction, EnemyFactionKeys) then scripting.game_interface:apply_effect_bundle_to_characters_force("Trade_Port_Supply", army,-1)
						GlobalSupplyCosts = 2;
						LogSupply("SupplyCivForChar()","Seaport Supply for: "..army);
						return GlobalSupplyCosts;
					end;
				end;
			end;

			-- Step. 2d Fleet to army supply with supply ships
			LogSupply("SupplyCivForChar()","Start Fleet close to army in region for: "..region_name.." Command Queue Index: "..army);
			if civ_fleet_to_army_supply(region_name, army, x, y, char_faction, EnemyFactionKeys, curr_char) then scripting.game_interface:apply_effect_bundle_to_characters_force("Army_from_Fleet_Supply", army,-1)
				GlobalSupplyCosts = 2;
				LogSupply("SupplyCivForChar()","Fleet close to army -> supply established "..region_name.." Command Queue Index: "..army);
				return GlobalSupplyCosts;
			end;

			-- Step. 3 check if character is in adjacent region Supply Line check!!!
			local season_check = true;
			LogSupply("SupplyCivForChar()","Startseason_check: "..region_name.." Command Queue Index: "..army);
			if Is_Winter_In_Alps(region_name) or Desert_Attrition(char_faction, region_name) then
				season_check = false
			end;

			if season_check then
				LogSupply("SupplyCivForChar()","Start Supply Line in region for: "..region_name.." Command Queue Index: "..army);
				local supply_line, supply_line_1, supply_line_2, supply_line_3, supply_line_region_name_1, supply_line_region_name_2, supply_line_region_name_3 = BuildSupplyLines(region_name, army, curr_char, char_faction, AlliedFactionKeys, EnemyFactionKeys, home_region)

				-- Step. 3a get shortest supply line
				if supply_line == true then
					supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_civ_supply_line"])
					LogSupply("SupplyCivForChar()","Start get shortest supply line check in region for: "..region_name.." Command Queue Index: "..army)

					if supply_line_1 == true and SupplyFromDepot(army, region_name, supply_line_region_name_1, supply_shif, supply_consumption, SupplyConsumptionOn) then
						supply_effect = "Supply_Line_1"
						LogSupply("SupplyCivForChar()","Supply line 1 region established to: "..region_name.." from: "..supply_line_region_name_1.." Command Queue Index: "..army)
					elseif supply_line_2 == true and SupplyFromDepot(army, region_name, supply_line_region_name_2, supply_shif, supply_consumption, SupplyConsumptionOn) then
						supply_effect = "Supply_Line_2"
						LogSupply("SupplyCivForChar()","Supply line 2 regions established to: "..region_name.." from: "..supply_line_region_name_2.." Command Queue Index: "..army)
					elseif supply_line_3 == true and SupplyFromDepot(army, region_name, supply_line_region_name_3, supply_shif, supply_consumption, SupplyConsumptionOn) then
						supply_effect = "Supply_Line_3"
						LogSupply("SupplyCivForChar()","Supply line 3 regions established to: "..region_name.." from: "..supply_line_region_name_3.." Command Queue Index: "..army)
					end

					if supply_effect ~= "none" then
						scripting.game_interface:apply_effect_bundle_to_characters_force(tostring(supply_effect), army,-1)
						GlobalSupplyCosts = 2;
						LogSupply("SupplyCivForChar()","Supply line effect: "..supply_effect.." added to Command Queue Index: "..army)
						return GlobalSupplyCosts;
					end;
				end;
			end;
		end;

		-- Step. 3b Allied Supply
		LogSupply("SupplyCivForChar()","Start Allied Supply in region for: "..region_name.." Command Queue Index: "..army)

		if CivAlliedSupply(region_id, HasMinSupplies, curr_char, AlliedFactionKeys) then
			supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_civ_allied_region"])
			SupplyUpdateArmyState(army, "Allied_Supply", region_name, supply_consumption, SupplyConsumptionOn, owner);
			LogSupply("SupplyCivForChar()","Supplied by allies in region:" ..region_name.." Command Queue Index: "..army)
			return GlobalSupplyCosts;
		end;

		-- Step. 4 Winter Regions, Alpine Regions
		local supply_value_from_table = "none"
		if season == 3
		and (contains (region_name, global_supply_variables.winter_regions_table)
		or contains (region_name, global_supply_variables.alpine_regions_table)) then
			LogSupply("SupplyCivForChar()","Start Winter Regions, Alpine Regions check in region for: "..region_name.." Command Queue Index: "..army)
			supply_effect, supply_value_from_table = WinterAttritionCheck(isAI, curr_char, turns_in_region, supply_usage)

			if supply_effect ~= "none" then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[tostring(supply_value_from_table)]);
				SupplyUpdateArmyState(army, tostring(supply_effect), region_name, supply_consumption, SupplyConsumptionOn, owner);
				LogSupply("SupplyCivForChar()","Apply Effect: "..tostring(supply_effect).." to: "..army);
				return GlobalSupplyCosts;
			end
		-- Step. 5 Summer Regions, Desert Regions
		elseif season == 1
		and (contains (region_name, global_supply_variables.summer_regions_table)
		or contains (region_name, global_supply_variables.desert_regions_table)) then
			LogSupply("SupplyCivForChar()","Start Summer Regions, Desert Regions check in region for: "..region_name.." Command Queue Index: "..army)
			supply_effect, supply_value_from_table = SummerAttritionCheck(isAI, curr_char, turns_in_region, supply_usage)

			if supply_effect ~= "none" then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[tostring(supply_value_from_table)]);
				SupplyUpdateArmyState(army, tostring(supply_effect), region_name, supply_consumption, SupplyConsumptionOn, owner);
				LogSupply("SupplyCivForChar()","Apply Effect: "..tostring(supply_effect).." to: "..army);
				return GlobalSupplyCosts;
			end
		end;

		-- No baggage train check... no enemy regions here the new baggage train system needs to step in -- No Supply, home
		LogSupply("SupplyCivForChar()","No Supply, home in region for: "..region_name.." Command Queue Index: "..army)

		if supply_line == false
		and curr_char:region():garrison_residence():faction():name() == char_faction then
			supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_civ_owned_region_foraging"])

			if regional_storage_supplies >= supply_consumption then
				Supply_Storage_Table[region_name] = regional_storage_supplies - supply_consumption
				scripting.game_interface:apply_effect_bundle_to_characters_force("Home_Foraging_1", army,-1)
				return GlobalSupplyCosts;
			else
				SupplyForaging(region_id, supply_consumption, army, culture, isAI, SupplyConsumptionOn, owner)
				return GlobalSupplyCosts;
			end;

			-- Baggagetrain: add new check for baggage trains here (Number of Turns saved as a variable)
			LogSupply("SupplyCivForChar()","Start of Civilized Baggage_train Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())

			if Unit_Is_In_Army(curr_char, Baggage_train_list)
			and turns_in_region <=global_supply_variables.supply_values_table[supply_usage.."_civ_Baggage_train_turns"] then
				Supply_Region_Table[region_name] = regional_supplies - math.ceil(army_size*global_supply_variables.supply_values_table["player_civ_Baggage_train"])
				scripting.game_interface:apply_effect_bundle_to_characters_force("Baggage_Train", army,-1)
				LogSupply("SupplyCivForChar()","Applied Effect Civilized Baggage_train: "..region_name.." Command Queue Index: "..army)
				return GlobalSupplyCosts;
			end;
			-- No Supply, away
			LogSupply("SupplyCivForChar()","No Supply, away in region for: "..region_name.." Command Queue Index: "..army)
		else
			supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_civ_foreign_foraging"])
			SupplyForaging(region_id, supply_consumption, army, culture, isAI, SupplyConsumptionOn, owner)
			return GlobalSupplyCosts;
		end;
	end;
	LogSupply("SupplyCivForChar()","***WARNING***: Function ended without assigned supply bundle for: "..curr_char:cqi().." Faction Name: "..curr_char:faction():name().. " in region: "..curr_char:region():name())
	return GlobalSupplyCosts;
end;


-- #####------------------------- START #####
-- NOMADIC SUPPLY SYSTEM ---------------------------------------------------------------------
-- #####-------------------------

-- ***** SUPPLY NOMADIC FOR CHAR ***** --
function SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)
	LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start SupplyNomadicForChar")

	local supply_usage = "player"

	if isAI then
		supply_usage = "ai"
	end;

--	if SupplyCharacterisGeneral(curr_char)
	if character_under_siege(curr_char) == false then
		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Player Supply Line Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name());
		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Set local variables for Player Supply Line Function for: ".. curr_char:get_forename());

		local season = current_Season()
		local region_id = curr_char:region()
		local region_name = region_id:name()
		local army = curr_char:cqi()
		local turns_in_region = curr_char:turns_in_own_regions()
		local turns_in_enemy_regions = curr_char:turns_in_enemy_regions()
		--local food_stealing = false
		--local enable_foraging = false
		--local enable_land_supply = false
		local x = curr_char:logical_position_x()
		local y = curr_char:logical_position_y()
		local char_faction = curr_char:faction():name()
		local army_size = SupplyArmySize(curr_char:military_force())
		--local supply_stored = regions_storage_table[region_name]
		local supply_consumption = 0
		local regional_supplies = Supply_Region_Table[region_name]
		local culture = "nomadic"

		-- remove all old effects
		--LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Remove nomadic effect bundles for: "..army);
		--RemoveBundle(army, supply_bundle_list)
		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Check if Char is in owned region with enough supplies");

		if curr_char:region():garrison_residence():faction():name() == char_faction
		and regional_supplies >= global_supply_variables.supply_values_table["devastated_region"]
		and not curr_char:faction():has_food_shortage()
		and not curr_char:region():garrison_residence():is_under_siege() then
			supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_owned_region_base"])

			-- Home Region Supply
			if distance_2D(curr_char:region():settlement():logical_position_x(), curr_char:region():settlement():logical_position_y(), x, y) <global_supply_variables.supply_values_table["radius_friendly"]
			and turns_in_region < 6 then
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Home_Supply", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Home Supply for: "..army);
				return
			end

			-- Home Region Supply too long
			if distance_2D(curr_char:region():settlement():logical_position_x(), curr_char:region():settlement():logical_position_y(), x, y) <global_supply_variables.supply_values_table["radius_friendly"] then
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Home_too_long", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Home Supply for: "..army);
				return
			end

			-- Home Baggage train
			if Unit_Is_In_Army(curr_char, Baggage_train_list) then
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Baggage_Train_Home", army,-1)

				if isAI == false then
					Nomads_Steal_Food = Nomads_Steal_Food + 2
				end
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Baggage train Supply for: "..army);
				return
			end
		end

		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Check if Char is in enemy region with enough supplies");
		-- enemy regions
		if curr_char:region():garrison_residence():faction():name() ~= char_faction
			and season ~= 3
			and Unit_Is_In_Army(curr_char, Baggage_train_list)
			and turns_in_enemy_regions <= global_supply_variables.supply_values_table[supply_usage.."_nom_Baggage_train_turns"] then

			for i = 0, curr_char:region():adjacent_region_list():num_items() - 1 do
				local adjacent_region = curr_char:region():adjacent_region_list():item_at(i)
				local adjacent_region_faction = adjacent_region:garrison_residence():faction():name()

				if char_faction == adjacent_region_faction then
					for j,v in pairs(Supply_Region_Table) do
						if j == adjacent_region:name() then
							Supply_Region_Table[j] = v + global_supply_variables.supply_values_table[supply_usage.."_nom_food_from_Baggage"]
						end
					end
				end
			end
		end

		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Check Supply Cut Winter");
		-- Supply Cut Winter
		if season == 3
		and (contains (region_name, global_supply_variables.winter_regions_table) or contains (region_name, global_supply_variables.alpine_regions_table)) then
			LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Supply Cut Winter Regions check in region for: "..region_name.." Command Queue Index: "..army);
			if Unit_Is_In_Army(curr_char, Baggage_train_list)
			and turns_in_enemy_regions <=global_supply_variables.supply_values_table[supply_usage.."_nom_Baggage_train_turns"] then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_Baggage_foraging"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Baggage_Train_Winter", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Baggage train Supply Winter for: "..army);
				return

			elseif isAI
			and activate_attrition_for_ai == true
			and activate_seasonal_attrition_for_ai == true then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_foreign_foraging"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Supply_Cut_Winter", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Winter Region attrition for: "..army);
				return
			elseif not isAI then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_foreign_foraging"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Supply_Cut_Winter", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Winter Region attrition for: "..army);
				return;
			end;
		end;

		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Check Supply Cut Summer Regions");
		-- Summer Regions
		if season == 1
		and (contains (region_name, global_supply_variables.summer_regions_table)
		or contains (region_name, global_supply_variables.desert_regions_table)) then
			LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Supply Cut Summer Regions check in region for: "..region_name.." Command Queue Index: "..army);

			if Unit_Is_In_Army(curr_char, Baggage_train_list)
			and turns_in_enemy_regions <=global_supply_variables.supply_values_table[supply_usage.."_nom_Baggage_train_turns"] then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_Baggage_foraging"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Baggage_Train_Summer", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Baggage train Supply Summer for: "..army);
				return
			elseif isAI
			and activate_attrition_for_ai == true
			and activate_seasonal_attrition_for_ai == true then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_foreign_foraging"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Supply_Cut_Summer", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Summer Region attrition for: "..army);
				return
			elseif not isAI then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_foreign_foraging"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Supply_Cut_Summer", army,-1)
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Summer Region attrition for: "..army);
				return;
			end;
		end;

		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Check Baggage Train");
		-- Baggage Train
		if Unit_Is_In_Army(curr_char, Baggage_train_list)
		and turns_in_enemy_regions <=global_supply_variables.supply_values_table[supply_usage.."_nom_Baggage_train_turns"] then
			if regional_supplies >= global_supply_variables.supply_values_table["devastated_region"] then
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_Baggage_foraging"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Nomads_Baggage_Train", army,-1)

				if isAI == false then
					Nomads_Steal_Food = Nomads_Steal_Food + 2;
				end;
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Player Nomads Baggage train for: "..army);
				return;
			end;
		end;

		-- Barbarian Allies
		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Allies Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())
		if curr_char:region():garrison_residence():faction():name() ~= char_faction
			and not region_id:garrison_residence():faction():has_food_shortage()
			and not region_id:garrison_residence():is_under_siege() then
			LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Allies Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())
			if contains(region_id:garrison_residence():faction():name(), AlliedFactionKeys)
			and regional_supplies >= global_supply_variables.supply_values_table["devastated_region"] then
				LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Allies Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())
				supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_allied_region"])
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, false)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Home_Supply_allies_same", army,-1);
				return
			end
		end

		-- Foraging
		if curr_char:has_region() then
			supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_nom_foreign_foraging"])
			SupplyForaging(region_id, supply_consumption, army, culture, isAI, SupplyConsumptionOn, false)
			return;
		end;
		LogSupply("SupplyNomadicForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","***WARNING***: Function ended without assign supply bundle");
	end;
end;

-- #####------------------------- START #####
-- BARBARIAN SUPPLY SYSTEM ---------------------------------------------------------------------
-- #####-------------------------

-- ***** SUPPLY BAR FOR CHAR ***** --
function SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)
	LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start SupplyBarForChar")

	local supply_usage = "player"
	local GlobalSupplyCosts = 0;

	if isAI then
		supply_usage = "ai"
	end;

	--if SupplyCharacterisGeneral(curr_char)
	if character_under_siege(curr_char) == false then
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of BarbarianSupply Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Set local variables for BarbarianSupply Function for: ".. curr_char:get_forename())

		-- set local variables --
		local season = current_Season();
		local army = curr_char:cqi();
		local x = curr_char:logical_position_x();
		local y = curr_char:logical_position_y();
		local radius = 20;
		local region_id = curr_char:region();
		local region_name = region_id:name();
		--local home_region = curr_char:faction():home_region();
		local char_faction = curr_char:faction():name() ;
		local turns_in_enemy_regions = curr_char:turns_in_enemy_regions();
		local army_size = SupplyArmySize(curr_char:military_force());
		local supply_stored = Supply_Storage_Table[region_name];
		local supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_owned_region_base"]);
		local supply_shif = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_city_to_foreign_region"]);
		local regional_supplies = Supply_Region_Table[region_name];
		local culture = "barbarian";

		--remove all old effects
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Remove bar player effect bundles for: "..army)
		--RemoveBundle(army, supply_bundle_list)

		-- Barbarian Supply near own city in owned regions
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Supply near own city in owned regions Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())

		if curr_char:region():garrison_residence():faction():name() == char_faction
		and curr_char:region():garrison_residence():is_under_siege() == false
		and not curr_char:faction():has_food_shortage()
		and distance_2D(curr_char:region():settlement():logical_position_x(), curr_char:region():settlement():logical_position_y(), x, y) < radius then

			if supply_stored >= supply_consumption
			or regional_supplies >= global_supply_variables.supply_values_table["devastated_region"] then
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Home_Supply_city_good", army,-1)
				LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Supply near own city good: "..region_name.." Command Queue Index: "..army)
				GlobalSupplyCosts = 1
				return GlobalSupplyCosts
			else
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Home_Supply_city_poor", army,-1); -- stop replenishment only in home regions!
				LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Supply near own city bad: "..region_name.." Command Queue Index: "..army)
				GlobalSupplyCosts = 1
				return GlobalSupplyCosts
			end
		end

		-- Barbarian nearby owned city in adjacent region
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Supply near own city in adjacent region Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())

		if curr_char:has_region() then
			for i = 0, curr_char:region():adjacent_region_list():num_items() - 1 do

				local adjacent_region = curr_char:region():adjacent_region_list():item_at(i)
				local adjacent_region_faction = adjacent_region:garrison_residence():faction():name()

				if char_faction == adjacent_region_faction
				and not SupplyLineBlocked(adjacent_region:name(), adjacent_region:settlement():logical_position_x(), adjacent_region:settlement():logical_position_y(), 12, EnemyFactionKeys)
				and distance_2D(adjacent_region:settlement():logical_position_x(), adjacent_region:settlement():logical_position_y(), x, y) < 25
					then RemoveSuppliesBasic(region_name, math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_foreign_region_with_city"]), SupplyConsumptionOn, false)

					if Supply_Storage_Table[adjacent_region:name()] >= supply_shif 
					or Supply_Region_Table[adjacent_region:name()] >= global_supply_variables.supply_values_table["devastated_region"]
					then
						RemoveSuppliesBasic(adjacent_region:name(), supply_shif, SupplyConsumptionOn, true)
						scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Supply_close_to_own_city_enemy_region", army,-1)
						LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Supply near own city in adjacent region: "..region_name.." Command Queue Index: "..army)
						GlobalSupplyCosts = 1
						return GlobalSupplyCosts
					end
				end
			end
		end

		-- Baggage_train
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Baggage_train Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())

		if Unit_Is_In_Army(curr_char, Baggage_train_list)
		and turns_in_enemy_regions <= global_supply_variables.supply_values_table[supply_usage.."_bar_Baggage_train_turns"]
		then
			RemoveSuppliesBasic(region_name, math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_Baggage_train_foraging"]), SupplyConsumptionOn, false)
			scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Baggage_Train", army,-1)
			LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Barbarian Baggage_train: "..region_name.." Command Queue Index: "..army)
			return
		end

		-- Supply Cut Winter
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Supply Cut Winter Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())

		if curr_char:faction():subculture() ~= "sc_rom_germanic"
		and not contains (curr_char:faction():name(), global_supply_variables.winter_factions_list_table)
		and contains (region_name, global_supply_variables.winter_regions_table)
		and season == 3 then
			RemoveSuppliesBasic(region_name, math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_foreign_foraging"]), SupplyConsumptionOn, false)
			scripting.game_interface:apply_effect_bundle_to_characters_force("Supply_Cut_Winter", army,-1)
			LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Supply Cut Winter: "..region_name.." Command Queue Index: "..army)
			return
		end

		-- Supply Cut Summer
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Supply Cut Summer Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())

		if contains (region_name, global_supply_variables.summer_regions_table)
		and season  == 1 then
			RemoveSuppliesBasic(region_name, math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_foreign_foraging"]), SupplyConsumptionOn, false)
			scripting.game_interface:apply_effect_bundle_to_characters_force("Supply_Cut_Summer", army,-1)
			LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Supply Cut Summer: "..region_name.." Command Queue Index: "..army)
			return
		end

		-- Barbarian Supply far away from own city in owned regions
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Supply far away from own city in owned regions Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())

		if curr_char:region():garrison_residence():faction():name() == char_faction
		and curr_char:region():garrison_residence():is_under_siege() == false
		and not curr_char:faction():has_food_shortage() then

			local supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_owned_region_foraging"])

			if supply_stored >= math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_owned_region_foraging"])
			or regional_supplies >= global_supply_variables.supply_values_table["devastated_region"] then
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Home_Supply_land_good", army,-1)
				LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Barbarian Supply far away from own city in owned regions: "..region_name.." Command Queue Index: "..army)
				GlobalSupplyCosts = 1
				return GlobalSupplyCosts
			else
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Home_Supply_land_poor", army,-1)
				LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Barbarian Supply far away from own city in owned regions: "..region_name.." Command Queue Index: "..army)
				GlobalSupplyCosts = 1
				return GlobalSupplyCosts
			end
		end

		-- Barbarian Allies
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Start of Barbarian Allies Function for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())
		if curr_char:region():garrison_residence():faction():name() ~= char_faction
		and not region_id:garrison_residence():faction():has_food_shortage()
		and not region_id:garrison_residence():is_under_siege() then

			if contains(region_id:garrison_residence():faction():name(), AlliedFactionKeys)
				and regional_supplies >= global_supply_variables.supply_values_table["devastated_region"]
			then
				RemoveSuppliesBasic(region_name, math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_allied_region"]), SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Bar_Home_Supply_allies_same", army,-1)
				LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","Applied Effect Barbarian Allies: "..region_name.." Command Queue Index: "..army)
				GlobalSupplyCosts = 1
				return GlobalSupplyCosts
			end
		end

		-- No Supply, home
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","No Supply, home in region for: "..region_name.." Command Queue Index: "..army)
		if curr_char:faction():has_food_shortage()
		and curr_char:region():garrison_residence():faction():name() == char_faction then
			supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_owned_region_foraging"])

			if supply_stored >= supply_consumption then
				RemoveSuppliesBasic(region_name, supply_consumption, SupplyConsumptionOn, true)
				scripting.game_interface:apply_effect_bundle_to_characters_force("Foraging_1", army,-1)
				return GlobalSupplyCosts
			else
				SupplyForaging(region_id, supply_consumption, army, culture, isAI, SupplyConsumptionOn, true)
				return GlobalSupplyCosts
			end
		end

		-- No Supply, away
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","No Supply, away in region for: "..region_name.." Command Queue Index: "..army)

		if curr_char:region():garrison_residence():faction():name() ~= char_faction then
			supply_consumption = math.ceil(army_size*global_supply_variables.supply_values_table[supply_usage.."_bar_foreign_foraging"])
			SupplyForaging(region_id, supply_consumption, army, culture, isAI, SupplyConsumptionOn, false)
			return GlobalSupplyCosts
		end
		LogSupply("SupplyBarForChar(curr_char, SupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys)","***WARNING*** Function ended without assigned supply bundle for: "..curr_char:get_forename().." Faction Name: "..curr_char:faction():name())
	end
end


-- ***** SUPPLY FLEET TRANSPORT ENTERS PORT ***** --
-- resupply function on character enters garrision

local function SupplyFleetTransportEntersPort(context)

	local army = context:character():cqi()
	local turns_at_sea = context:character():turns_at_sea()

	if context:character():has_military_force() == true
	and (char_is_general_with_navy(context:character()))
	and context:character():has_garrison_residence() == true
	then

		if turns_at_sea >= 4 then
			LogSupply("SupplyFleetTransportEntersPort","Naval resupply effect bundles for: "..army)

			if context:character():faction():culture() == "rom_Barbarian" then
				scripting.game_interface:apply_effect_bundle_to_characters_force("Naval_Resupply_2", army,-1);
			else
				scripting.game_interface:apply_effect_bundle_to_characters_force("CIV_Naval_Resupply_2", army,-1);
				return;
			end;

		elseif turns_at_sea < 4
		then
			LogSupply("SupplyFleetTransportEntersPort","Naval resupply effect bundles for: "..army)

			if context:character():faction():culture() == "rom_Barbarian" then
				scripting.game_interface:apply_effect_bundle_to_characters_force("Naval_Resupply", army,-1)
			else
				scripting.game_interface:apply_effect_bundle_to_characters_force("CIV_Naval_Resupply", army,-1);
				return;
			end;
		end;
	end;
end;


-- ***** SUPPLY ON CHAR SELECTED ***** --
function SupplyOnCharSelected(context)
	local isSupplyConsumptionOn = false;
	local AlliedFactionKeys = {};
	local EnemyFactionKeys = {};

	if CampaignUI.IsMultiplayer() then
		return
	end;

	local curr_char = context:character();
	--LogSupply("SupplyOnCharSelected(context)","Money: "..tostring(curr_char:faction():treasury()))
	--LogSupply("SupplyOnCharSelected(context)","Food: "..tostring(curr_char:faction():total_food()))
	--LogSupply("SupplyOnCharSelected(context)","Imperium: "..tostring(curr_char:faction():imperium_level()))

	if not curr_char:has_military_force() then
		return;
	end;

	local isAI = true;

	if curr_char:faction():is_human() then
		isAI = false
	end;

	AlliedFactionKeys, EnemyFactionKeys = SupplyGetFactionTreaties(curr_char:faction():treaty_details());
	SupplyCharGarbageCollector(curr_char)

	if SupplyFactionisNOMADIC(curr_char:faction():name(), curr_char:faction():subculture()) then
		LogSupply("SupplyOnCharSelected(context)","SupplyFactionisNOMADIC: true")
		if SupplyCharisTransportFleet(curr_char) then
			SupplyTransportShipsforChar(curr_char);
		elseif SupplyCharisAdmiral(curr_char) then
			SupplyNavalforChar(curr_char);
		elseif SupplyCharacterisGeneral(curr_char) then
			SupplyNomadicForChar(curr_char, isSupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys);
		end;

	elseif SupplyFactionisCIV(curr_char:faction():culture()) then
		LogSupply("SupplyOnCharSelected(context)","SupplyCivForChar: true")
		if SupplyCharisTransportFleet(curr_char) then
			SupplyTransportShipsforChar(curr_char);
		elseif SupplyCharisAdmiral(curr_char) then
			SupplyNavalforChar(curr_char);
		elseif SupplyCharacterisGeneral(curr_char) then
			SupplyCivForChar(curr_char, isSupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys);
		end;

	elseif SupplyFactionisBAR(curr_char:faction():culture()) then
		LogSupply("SupplyOnCharSelected(context)","SupplyFactionisBAR: true")
		if SupplyCharisTransportFleet(curr_char) then
			SupplyTransportShipsforChar(curr_char);
		elseif SupplyCharisAdmiral(curr_char) then
			SupplyNavalforChar(curr_char);
		elseif SupplyCharacterisGeneral(curr_char) then
			SupplyBarForChar(curr_char, isSupplyConsumptionOn, isAI, AlliedFactionKeys, EnemyFactionKeys);
		end;
	end;
end;


-- ***** SUPPLY ON SETTLEMENT SELECTED ***** --
local function SupplyOnSettlementSelected(context)

	local region_name = context:garrison_residence():region():name()
	local supply_value = 0;
	local supply_value_buildings = 0;
	local supply_multiplier = 0;
	local supply_cap = 0;
	local supply_storage_buildings = 0;
	--local supply_value_strategic_depot_base = 0;
	local new_supply_value = 0;
	--local surplus_supplies = 0;
	--local export_supplies = 0;
	--local regional_supplies = regions_table[region_name];
	local region_id = context:garrison_residence():region();
	Supply_System_UI.Supply_Exports = 0;
	Supply_System_UI.Supply_Region_Under_Siege = false;
	local underSiege = false;

	if context:garrison_residence():is_under_siege() then
		underSiege = true;
		Supply_System_UI.Supply_Region_Under_Siege = true;
	end

	for n,v in pairs (Supply_Region_Table) do
		if n == region_name then
			Supply_System_UI.Supply_Status = v
		end
	end

	for n,v in pairs (Supply_Storage_Table) do
		if n == region_name then
			Supply_System_UI.Supply_Storage = v
		end
	end

	--function UI_SupplyRetrieveFertility(region_name)
	-- get region type
	if contains (region_name, global_supply_variables.low_fertile_regions_table) then
		supply_value = math.ceil(global_supply_variables.supply_values_table["low_fertile_regions"]*global_supply_variables.supply_values_table[SeasonToString()])
		supply_cap = global_supply_variables.supply_values_table["low_fertile_regional_cap"]
		Supply_System_UI.Region_Fertility = "[[rgba:153:0:0:150]]Low Fertility[[/rgba:153:0:0:150]]"
		LogSupply("SupplyOnSettlementSelected(context)","supply value: "..supply_value)
	end

	if contains (region_name, global_supply_variables.normal_regions_table) then
		supply_value = math.ceil(global_supply_variables.supply_values_table["normal_regions"]*global_supply_variables.supply_values_table[SeasonToString()])
		supply_cap = global_supply_variables.supply_values_table["normal_regional_cap"]
		Supply_System_UI.Region_Fertility = "[[rgba:255:204:51:150]]Average Fertility[[/rgba:255:204:51:150]]"
		LogSupply("SupplyOnSettlementSelected(context)","supply value: "..supply_value)
	end

	if contains (region_name, global_supply_variables.fertile_regions_table) then
		supply_value = math.ceil(global_supply_variables.supply_values_table["fertile_regions"]*global_supply_variables.supply_values_table[SeasonToString()])
		supply_cap = global_supply_variables.supply_values_table["fertile_regional_cap"]
		Supply_System_UI.Region_Fertility = "[[rgba:0:102:0:150]]High Fertility[[/rgba:0:102:0:150]]"
		LogSupply("SupplyOnSettlementSelected(context)","supply value: "..supply_value)
	end

	if contains (region_name, global_supply_variables.very_fertile_regions_table) then
		supply_value = math.ceil(global_supply_variables.supply_values_table["very_fertile_regions"]*global_supply_variables.supply_values_table[SeasonToString()])
		supply_cap = global_supply_variables.supply_values_table["very_fertile_regional_cap"]
		Supply_System_UI.Region_Fertility = "[[rgba:0:102:0:150]]Very High Fertility[[/rgba:0:102:0:150]]"
		LogSupply("SupplyOnSettlementSelected(context)","supply value: "..supply_value)
	end

	-- check if bonus buildings are constructed
	for slots = 0, region_id:slot_list():num_items() -1 do
		local slot = region_id:slot_list():item_at(slots)

		if slot:has_building() then
			local buildingName = slot:building():name()
			LogSupply("SupplyOnSettlementSelected(context)",buildingName)

			if SupplyProductionBuildingsTable[buildingName] then
				supply_value_buildings = supply_value_buildings + SupplyProductionBuildingsTable[buildingName][1]
				LogSupply("SupplyOnSettlementSelected(context)","building supplies added: "..SupplyProductionBuildingsTable[buildingName][1])
				supply_multiplier = math.ceil(supply_value*SupplyProductionBuildingsTable[buildingName][2])
				LogSupply("SupplyOnSettlementSelected(context)","building supplies multiplier: "..SupplyProductionBuildingsTable[buildingName][2])
				supply_storage_buildings = supply_storage_buildings + SupplyProductionBuildingsTable[buildingName][3]
				LogSupply("SupplyOnSettlementSelected(context)","building supplies added: "..SupplyProductionBuildingsTable[buildingName][3])
			end;
		end;
	end;

	if current_Season() == 1
	and contains (region_name, global_supply_variables.desert_regions_table) then
		supply_value = 0
	end;

	if current_Season() == 3
	and contains (region_name, global_supply_variables.winter_regions_table) then
		supply_value = 0
	end;

	if underSiege then
		new_supply_value = math.ceil((supply_value + supply_multiplier + supply_value_buildings) * 0.7)
	 else new_supply_value = supply_value + supply_multiplier + supply_value_buildings
	end;

	Supply_System_UI.Supply_Cap_Buildings = supply_storage_buildings
	Supply_System_UI.Supply_Storage_Cap = global_supply_variables.supply_values_table["region_storgae_cap"] + Supply_System_UI.Supply_Cap_Buildings

	OnSettlementSelected_UI(context:garrison_residence())
	OnSettlementSelectedUISeason()

	Supply_System_UI.Supply_Buildings = supply_value_buildings + supply_multiplier
	Supply_System_UI.Supply_Base = supply_value
	Supply_System_UI.Supply_Cap = supply_cap
	Supply_System_UI.Supply_value = new_supply_value
	Supply_System_UI.Last_Settlement = global_supply_variables.region_names_table[region_name]
	Supply_System_UI.Last_Settlement_X = context:garrison_residence():region():settlement():display_position_x()
	Supply_System_UI.Last_Settlement_Y = context:garrison_residence():region():settlement():display_position_y()
end


-- ###---------------------------------- END*
-- ###------------------------- START *******
-- SAVE/LOAD CALLBACKS ---------------------------------------------------------------------
-- ###-------------------------

-- ***** SAVE VALUES ***** --
local function Save_Values(context)
-- Supply_Region_Table
	scripting.game_interface:save_named_value("supply_message", Supply_Message, context);
	cm:save_value("SupplyCampaignName", SupplyCampaignName, context);

	for i,value in pairs(Supply_Region_Table) do
		scripting.game_interface:save_named_value("supply_regions_table_"..i, value, context)
	end
	for i,value in pairs(Supply_Storage_Table) do
		scripting.game_interface:save_named_value("supply_storage_table"..i, value, context)
	end
--	for i,value in pairs(SupplyImportsExportsTable_table) do
--		scripting.game_interface:save_named_value("SupplyImportsExportsTable_table"..i, value, context)
--	end
end

-- ***** LOAD VALUES ***** --
local function Load_Values(context)
	LogSupply("Supply Load_Values(Load_Values(context))", "Start");
	Supply_Message = scripting.game_interface:load_named_value("supply_message", false, context);
	SupplyCampaignName = cm:load_value("SupplyCampaignName", "", context);

	if SupplyCampaignName == "main_rome" or SupplyCampaignName == "main_emperor" or SupplyCampaignName == "main_3c" or SupplyCampaignName == "prologue_01" or SupplyCampaignName == "prologue_02"  then
		for i,value in pairs(Supply_emp_Region_Table) do
			Supply_emp_Region_Table[i] = scripting.game_interface:load_named_value("supply_regions_table_"..i, value, context)
		end
		for i,value in pairs(Supply_emp_Storage_Table) do
			Supply_emp_Storage_Table[i] = scripting.game_interface:load_named_value("supply_storage_table"..i, value, context)
		end;
		LogSupply("Supply Load_Values(Load_Values(context))", "GC Campaign Regions Loaded");
	end

	if SupplyCampaignName == "main_gaul" then
		for i,value in pairs(Supply_gaul_Region_Table) do
			Supply_gaul_Region_Table[i] = scripting.game_interface:load_named_value("supply_regions_table_"..i, value, context)
		end
		for i,value in pairs(Supply_gaul_Storage_Table) do
			Supply_gaul_Storage_Table[i] = scripting.game_interface:load_named_value("supply_storage_table"..i, value, context)
		end;
		LogSupply("Supply Load_Values(Load_Values(context))", "Gaul Campaign Regions Loaded");
	end

	if SupplyCampaignName == "main_greek" then
		for i,value in pairs(Supply_pel_Region_Table) do
			Supply_pel_Region_Table[i] = scripting.game_interface:load_named_value("supply_regions_table_"..i, value, context)
		end
		for i,value in pairs(Supply_pel_Storage_Table) do
			Supply_pel_Storage_Table[i] = scripting.game_interface:load_named_value("supply_storage_table"..i, value, context)
		end
		LogSupply("Supply Load_Values(Load_Values(context))", "Greek Campaign Regions Loaded");
	end

	if SupplyCampaignName == "main_punic" then
		for i,value in pairs(Supply_pun_Region_Table) do
			Supply_pun_Region_Table[i] = scripting.game_interface:load_named_value("supply_regions_table_"..i, value, context)
		end
		for i,value in pairs(Supply_pun_Storage_Table) do
			Supply_pun_Storage_Table[i] = scripting.game_interface:load_named_value("supply_storage_table"..i, value, context)
		end
		LogSupply("Supply Load_Values(Load_Values(context))", "Punic Campaign Regions Loaded");
	end

	if SupplyCampaignName == "main_invasion" then
		for i,value in pairs(Supply_inv_Region_Table) do
			Supply_inv_Region_Table[i] = scripting.game_interface:load_named_value("supply_regions_table_"..i, value, context)
		end
		for i,value in pairs(Supply_inv_Storage_Table) do
			Supply_inv_Storage_Table[i] = scripting.game_interface:load_named_value("supply_storage_table"..i, value, context)
		end
		LogSupply("Supply Load_Values(Load_Values(context))", "Invasion Campaign Regions Loaded");
	end

--	for i,value in pairs(SupplyImportsExportsTable_table) do
--		SupplyImportsExportsTable_table[i] = scripting.game_interface:load_named_value("SupplyImportsExportsTable_table"..i, value, context)
--	end
	LogSupply("Supply Load_Values(Load_Values(context))", "End");
end


-- CALLBACKS ---------------------------------------------------------------------
scripting.AddEventCallBack("LoadingGame", Load_Values)
scripting.AddEventCallBack("SavingGame", Save_Values)


-- GENERALS
local function UI_Supply_Char_ON_TIMETRIGGER(context)
	if (context.string == "UI_Supply_Char_ON") then
		CALL_UI_Supply_Char_ON()
	end
end

--Version 3.0. last edit 30.01.2022--
-- function UISupplyTooltipBuilder now in supply_system_UI_functions.lua
function UI_RegionSupplyTooltip(context)
	local component = UIComponent(context.component):Id()
	if component == "TTIP_STG1_Supp_0001"
		then local text = UISupplyTooltipBuilder()
		UIComponent(context.component):SetTooltipText(text)
	end
end

-- CALLBACKS ---------------------------------------------------------------------
-- #####-------------------------
scripting.AddEventCallBack("TimeTrigger", UI_Supply_Char_ON_TIMETRIGGER);
scripting.AddEventCallBack("CharacterEntersGarrison", SupplyFleetTransportEntersPort)
scripting.AddEventCallBack("SettlementSelected", SupplyOnSettlementSelected)
-- #####---------------------------------- END #####