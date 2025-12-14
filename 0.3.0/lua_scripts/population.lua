
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------

-- People of Rome 2 (p++)
-- Population Script for Divide et Impera  
-- Created by Litharion, Magnar and Causeless
-- Last Updated: 05/04/2021

-- The content of the script belongs to the orginial Author and as such cannot
-- be used elsewhere without express consent.

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
PoR2_Version = "Vanilla Version \n  05/04/2021 v. 1.2.8 \n   population.lua"

-- Changelog: since 2021

-- 08/02/2021
-- Added new pop ui hover text for unit cards

-- 05/04/2021
-- fixed economy effects not working
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


module(..., package.seeall)
_G.main_env = getfenv(1)


-- #####------------------------- START #####
-- LIBRARIES REQUIRED  ---------------------------------------------------------------------
-- #####-------------------------


local scripting = require "lua_scripts.EpisodicScripting"
local modifier_lib = require "script._lib.manpower.population_modifiers"
local list_lib = require "script._lib.manpower.population_tables"
local ui_lib = require "script._lib.manpower.population_ui_tables"
local economic_lib = require "script._lib.manpower.population_economics"
local immigration_lib = require "script._lib.manpower.population_immigration"
local units_lib = require "script._lib.manpower.units"
local lib_supply_values = require "script._lib.supply_system.supply_system_values"


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- GLOBAL VARIABLES  ---------------------------------------------------------------------
-- #####-------------------------


-- FLAGS
local ENEMIES_PRESENT = 1
local SETTLEMENT_LOOTED = 2
local SETTLEMENT_OCCUPIED = 3
local BATTLE_FOUGHT = 4

-- OTHER
local tempCqi = -1
local tempFaction = ""
local growthDivisor = 1

-- SCRIPT VARIABLES
local region_table = "none"
local region_flag = "none"
local region_desire = "none"

-- BOOLEANS
triggerload = "nil";
isLogAllowed = false;
isLogPopAllowed = false;


-- ***** SET TICK TOCK ***** --

function set_tick_tock(context)

  triggerload = scripting.game_interface:load_named_value("triggerload", "", context);
  
    if triggerload == "on"
  then
    triggerload = "off"
    return
  end
  
    if triggerload == "off"
  then
    triggerload = "on"
    
    return
  
  end
  
  triggerload = "on"
  
end


-- ***** TICK TOCK CALLBACK ***** --

scripting.AddEventCallBack("LoadingGame", set_tick_tock) 


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- LOGS  ---------------------------------------------------------------------
-- #####-------------------------


-- ***** LOG ***** --

function LogPop(ftext, rownum, text, isTitle, isNew)

  if not isLogPopAllowed
  then
  
    return
  
  end;
  
  local logfile;
  text = tostring(text);
  ftext = tostring(ftext)
  rownum = tostring(rownum)

  if isNew
  then
  
    logfile = io.open("PoR2_Growth_Log.txt","w");
    
    local text = tostring(PoR2_Version);
    
    logfile:write(text.."\n\n");
  
  else
  
    logfile = io.open("PoR2_Growth_Log.txt","a");
  
    if not logfile 
    then
    
      logfile = io.open("PoR2_Growth_Log.txt","w") 
    
    end;
  end;
  
  if isTitle
  then
  
    local title_text = "#######################################################\n";
    
    text = "\n"..title_text..text.."\n"..title_text;
  
  end;
  
  local logTimeStamp = os.date("%c")
  
  logfile:write("["..logTimeStamp.."]["..ftext.."]:"..rownum..": "..text.."\n");
  logfile:close();
  
end;


-- ***** POP LOG ***** --
-- the context is the function name that it is being used in. Enter as a string.

function PopLog(text, ftext)

   if not isLogAllowed
  then
  
    return;
  
    end

  local logText = tostring(text)
  local logContext = tostring(ftext)
  local logTimeStamp = os.date("%d, %m %Y %X")
  local popLog = io.open("Pop_script_log.txt","a")
  
  popLog :write(logText .. " : " .. logContext .. " : ".. logTimeStamp .. "\n")
  popLog :flush()
  popLog :close()
  
end


-- ***** DEBUG ***** --
-- the context is the function name that it is being used in. Enter as a string.

function Debug(text, ftext)

    if not isLogAllowed
  then
  
    return;
  
   end

  local logText = tostring(text)
  local logContext = tostring(ftext)
  local logTimeStamp = os.date("%d, %m %Y %X")
  local popLog = io.open("Debug_script_log.txt","a")
  
  popLog :write(logText .. " : " .. logContext .. " : ".. logTimeStamp .. "\n")
  popLog :flush()
  popLog :close()
  
end


-- ***** PRINT TABLE ***** --
-- Output list to logfile

function PrintTable(tableName, outFileName)

    if not isLogAllowed
  then
  
    return;
  
    end

  local oFile = io.open(outFileName.. ".txt", "a")
  
  oFile:write("New Table \n")
  
  if next(tableName) == nil
  then
  
    -- PopLog("table is empty" , "PrintTable")
    
  else
  
    -- PopLog("Table not empty" , "PrintTable")
    for k, v in pairs(tableName)
    do
    
      oFile:write( k  .. " | " ..  tableName[k] ..  "\n")
  
    end
  end
  
  oFile.flush()
  oFile.close()
  
end


-- ***** PRINT REGION TABLE ***** --
-- requires the name of the region list

function PrintRegionTable(tableName)
  
    if not isLogAllowed
  then
  
    return;
    
    end

  local oFile = io.open("Population_Table_Log.txt", "w")
  
  oFile:write("New Table \n")
  
  if next(tableName) == nil
  then
  
    -- PopLog("table is empty" , "PrintRegionTable")
    
  else
  
    -- PopLog("Region Table not empty" , "PrintRegionTable")
    
    oFile:write("REGION POPULATION TABLE\nRegion Key | Noble Population | Middle Class | Lower Class | Foreign Class\n")
  
    for k, v in pairs(tableName)
    do
    
      oFile:write( k  .. " , " ..  tableName[k][1] .. " , " .. tableName[k][2].. " , " .. tableName[k][3].. " , " .. tableName[k][4] ..  "\n")
    
    end
  end
  
  oFile.flush()
  oFile.close()
  
end


-- #####---------------------------------- END #####

-- #####------------------------- START #####
-- NON EVEN FUNTIONS  ---------------------------------------------------------------------

-- GetTurn
-- ControlPopValue
-- GetRegionPop
-- SetRegionPop
-- GetCampaignName
-- SetRegionTable

-- #####-------------------------


-- ***** GET TURN ***** --

function GetTurn()

  return scripting.game_interface:model():turn_number()

end


-- ***** CONTROL POP VALUE ***** --
-- ensure that population numbers are whole numbers not greater than max pop set in population modifiers
-- and not less than min pop set in population modifiers)

function ControlPopValue(number)

  local max = population_modifier["max_pop_size"]
  local min = population_modifier["min_pop_size"]
  local value = number

  if value > max
  then
  
    return  max
  
  elseif value < min
  then
  
    -- PopLog("value less than 0: " .. value, "ControlPopValue()")
    
    return min
  
  end

  if value % 1 == 0
  then
  
    return value
  
  else 
  
    return math.floor(value)
  
  end
  
  return value
  
end


-- ***** GET REGION POP ***** --
-- expect REGION_SCRIPT_INTERFACE as the context

function GetRegionPop(regionContext)

  -- returns the region pop table {noblePop, midPop, lowPop, foreignPop}
  return region_table[regionContext:name()]

end


-- ***** SET REGION POP ***** --

function SetRegionPop(regionName, up, mid, low, foreign)

  -- PopLog("Region Table Set: " .. regionName, "SetRegionPop()")
  LogPop("SetRegionPop("..regionName..", "..up..","..mid..","..low..","..foreign, "263", "Region Table Set:"); 
  
  -- changes the pop values for a region the table must contain 4 integers 

  region_table[regionName][1] = ControlPopValue(up)
  region_table[regionName][2] = ControlPopValue(mid)
  region_table[regionName][3] = ControlPopValue(low)
  region_table[regionName][4] = ControlPopValue(foreign)
  
  LogPop("SetRegionPop(...)", "265", "region_table[regionName][1]: "..tostring(region_table[regionName][1]));
  LogPop("SetRegionPop(...)", "266", "region_table[regionName][2]: "..tostring(region_table[regionName][2]));
    LogPop("SetRegionPop(...)", "267", "region_table[regionName][3]: "..tostring(region_table[regionName][3]));
    LogPop("SetRegionPop(...)", "268", "region_table[regionName][4]: "..tostring(region_table[regionName][4]));
    LogPop("SetRegionPop(...)", "273", "total Population: " .. region_table[regionName][1]+region_table[regionName][2]+region_table[regionName][3]+region_table[regionName][4]);  
  -- LogPop("SetRegionPop("..regionName..", "..up..","..mid..","..low..","..foreign.., "270", "Region Table Set:"); --PopLog("Region Table Set: " .. regionName .." | " .. region_table[regionName][1].. region_table[regionName][2], "SetRegionPop()")
  -- PrintRegionTable(region_table)
  
end


-- ***** GET CAMPAIGN NAME ***** --

function GetCampaignName()

  for k,v in pairs(campaign_table)
  do
  
    if scripting.game_interface:model():campaign_name(k)
    then
    
      return k;
    
    end;
  end;
end;


-- ***** SET REGION TABLE ***** --
-- assigns the region table to use

function SetRegionTable()

  local campaignName  = GetCampaignName()
  
  if campaignName == "main_invasion"
  then 
  
    region_table = rom_region_to_pop_tableROR
    region_flag = rom_region_flag
	region_name_table = RegionKeytoRegionLoc
    --region_desire = rom_region_desire
	
	elseif campaignName == "main_gaul"
	then
	    
	region_table = rom_region_to_pop_tableGaul
    region_flag = rom_region_flag
    --region_desire = rom_region_desire
	region_name_table = RegionKeytoRegionLoc
	
	elseif campaignName == "main_greek"
	then
	    
	region_table = rom_region_to_pop_tableWoS
    region_flag = rom_region_flag
    --region_desire = rom_region_desire
	region_name_table = RegionKeytoRegionLoc
	
	elseif campaignName == "main_punic"
	then
	    
	region_table = rom_region_to_pop_tableHatG
    region_flag = rom_region_flag
    --region_desire = rom_region_desire
	region_name_table = RegionKeytoRegionLoc
	
	elseif campaignName == "prologue_01"
	then
	    
	region_table = rom_region_to_pop_table
    region_flag = rom_region_flag
    --region_desire = rom_region_desire
	region_name_table = RegionKeytoRegionLocAlex
	
  else
  
    region_table = rom_region_to_pop_table
    region_flag = rom_region_flag
    --region_desire = rom_region_desire
	region_name_table = RegionKeytoRegionLoc
	
  end;
  
  -- PopLog("Region Table Set: " .. campaignName[].., "SetRegionTable()")

end


-- ***** SET GROWTH DIVISOR ***** --

function SetGrowthDivisor(campaign)
  -- NOTE:
  -- regionPopModTable values represent YEARLY percentage growth (e.g. 2.5 = +2.5% per year).
  -- We keep these yearly semantics for UI/projections, and only convert to per-turn at the moment of application.
  local tpy = 1
  if campaign_turn_per_year and campaign and campaign_turn_per_year[campaign] then
    tpy = campaign_turn_per_year[campaign]
  end

  -- Backwards-compatible denominator: turns_per_year * 100 converts yearly % to per-turn fraction.
  if population_modifier and population_modifier["enable_tpy_growth_division"] == true then
    growthDivisor = tpy * 100
  else
    growthDivisor = 100
  end
end

-- POP GROWTH FUNCTIONS  ---------------------------------------------------------------------

-- POP GROWTH FUNCTIONS
-- RegionPopGrowth
-- FactionImmigration
-- ApplyRegionBundle
-- RemoveRegionBundle

-- #####-------------------------


-- ***** REGION POP GROWTH ***** --
-- contains all adjustments of a regions population and requires the region script interface to be passed to it

function RegionPopGrowth(region)

  local regionName = region:name()
  
  LogPop("RegionPopGrowth(region)", "311", "Start:\n");
  
  if region_table[regionName]
  then
  
    local faction = region:owning_faction();
    local regionPopTable = {0,0,0,0};
    local regionPopModTable = {0,0,0,0};
    local factionCulture = faction:state_religion();
    local taxLevel = faction:tax_level();
    local publicOrder = region:public_order();
    local foreignArmies = false;
    local regionLooted = false;
    local regionOccupied = false;
    local homeRegion = region:garrison_residence():faction():home_region():name();
    local difficulty = scripting.game_interface:model():difficulty_level();
    -- fill temporary working table with original pop figures
    LogPop("RegionPopGrowth(region)", "331", "pop temp pop table set up" .. regionName);

    for i = 1, 4
    do
    
      regionPopTable[i] = region_table[regionName][i];
      
      LogPop("RegionPopGrowth(region)", "335", "regionPopTable["..i.."]: "..tostring(regionPopTable[i]));
    
    end;

    -- get toal population
    local totalPopulation = regionPopTable[1] + regionPopTable[2] + regionPopTable[3] + regionPopTable[4];
    
    LogPop("RegionPopGrowth(region)", "340", "total Population: " .. totalPopulation);

    -- reset region flags
    -- Foreign armies / looted / occupied flags (guarded)
    do
      local rf = region_flag[regionName]
      if rf and rf[ENEMIES_PRESENT] == true then
        foreignArmies = true
        LogPop("RegionPopGrowth(region)", "353", "foreignArmies" .. tostring(foreignArmies));
        rf[ENEMIES_PRESENT] = false;
      end;
      if rf and rf[SETTLEMENT_LOOTED] == true then
        regionLooted = true
        LogPop("RegionPopGrowth(region)", "354", "regionLooted" .. tostring(regionLooted));
        rf[SETTLEMENT_LOOTED] = false;
      end;
      if rf and rf[SETTLEMENT_OCCUPIED] == true then
        regionOccupied = true
        LogPop("RegionPopGrowth(region)", "355", "regionOccupied" .. tostring(regionOccupied));
        rf[SETTLEMENT_OCCUPIED] = false;
      end;
    end;
    
    LogPop("RegionPopGrowth(region)", "358", "flags set and reset" .. regionName);
    
    -------------------------------------------------------------
    -- POP MODIFIERS
    -- add numbered calculation list in comment and code below
    --1)BaseGrowth %
    --)BuildingGrowth -- multiplies base pop by building specific bonuses
    --2)Food Shortage
    --3)Majority Religion & technology
    --4)Culture/Religion Bonuses
    --5)Public Order
    --6)Taxation
    --7)Faction Capital
    --8)Province Capital
    --9)Buidlings
    --10)Foreign Army
    --11)Under Siege
    --12) Looted settlement (Raze, looted)
    --13) Occupied Settlment
    --14) Difficulty
    --last) apply growth mult
    -------------------------------------------------------------

    -- check if modifiers need to be applied so that they aren't checked 4 times in the for loop
    -- 2) Supply Shortage changed for DeI to look at local supply level instead of faction food 
    
    local foodShortage = false;
    local foodShortageNegative = false;
    local foodShortageMid = false;
    
    LogPop("RegionPopGrowth(region)", "386", "Supply Shortage changed for DeI");
    
    local regional_supplies = Supply_Region_Table[regionName] + Supply_Storage_Table[regionName]
    
    LogPop("RegionPopGrowth(region)", "348", "regional supply value:" ..regional_supplies);


-- region current fertility rating
--fertile_region = 180,     global_supply_variables.supply_values_table["fertile_region"]
--foraged_region = 120,     global_supply_variables.supply_values_table["foraged_region"]
--looted_region = 60,       global_supply_variables.supply_values_table["looted_region"]
--devastated_region = 10, 

    if regional_supplies < global_supply_variables.supply_values_table["looted_region"]
    then -- MAGIC NUMBERS!!!! 
    
      foodShortageNegative = true;
    
    elseif regional_supplies < global_supply_variables.supply_values_table["foraged_region"]
    then -- MAGIC NUMBERS!!!! 
    
      foodShortage = true;
    
    elseif regional_supplies < global_supply_variables.supply_values_table["fertile_region"]
    then -- MAGIC NUMBERS!!!! 
    
      foodShortageMid = true;
    
    end;
    
    -- 3) Majority Religion & technology
    
    local majorityCulture = false;
  
    if region:majority_religion() == factionCulture
    then
    
      majorityCulture = true;
    
    end;
    
    LogPop("RegionPopGrowth(region)", "403", "majorityCulture:" ..tostring(majorityCulture));
    
    -- 4) Culture/Religion Bonuses
    
    local baseCultureInTable = false;
  
    if culture_growth_bonus[factionCulture]
    then
    
      baseCultureInTable = true;
      
    end;
    
    LogPop("RegionPopGrowth(region)", "409", "baseCultureInTable:" ..tostring(baseCultureInTable));
    
    -- 7) Faction Capital
    
    local regionIsHome = false;
  
    if regionName ==  homeRegion
    then 
    
      regionIsHome = true;
      
    end;
    
    LogPop("RegionPopGrowth(region)", "415", "homeRegion:" ..tostring(homeRegion));
    
    -- 8) Province Capitol (adapted for Divide et Impera)
    
    local provCap = false;
  
    if (region:building_superchain_exists("rom_SettlementMajor")
    or region:building_superchain_exists("dei_superchain_city_ROME")
    or region:building_superchain_exists("dei_superchain_city_PELLA")
    or region:building_superchain_exists("dei_superchain_city_CARTHAGE")
    or region:building_superchain_exists("dei_superchain_city_SYRACUSE")
    or region:building_superchain_exists("dei_superchain_city_ATHENS")
    or region:building_superchain_exists("dei_superchain_city_ALEXANDRIA")
    or region:building_superchain_exists("dei_superchain_city_PERGAMON")
    or region:building_superchain_exists("dei_superchain_city_ANTIOCH")
    or region:building_superchain_exists("dei_superchain_city_MASSILIA")
    or region:building_superchain_exists("dei_superchain_city_BIBRACTE")
	or region:building_superchain_exists("dei_superchain_city_ZARM")
    or region:building_superchain_exists("inv_etr_main_city"))
    then
    
      provCap = true;
    
    end;
    
    LogPop("RegionPopGrowth(region)", "422", "provCap:" ..tostring(provCap)); 
    
    -- 11) Under siege
    
    local underSiege = false;
   
    if region:garrison_residence():is_under_siege()
    then
    
      underSiege = true;
    
    end;
    
    LogPop("RegionPopGrowth(region)", "428", "underSiege:" ..tostring(underSiege)); 
    LogPop("RegionPopGrowth(region)", "429", "region checks done:" ..regionName);

    for i = 1, 4
    do 
    
      -- 1) BaseGrowth %
      
      regionPopModTable[i] = regionPopModTable[i] + (population_modifier["base_pop_multiplier"][i] - 0.01*(totalPopulation/population_modifier["base_pop_growth_divisor"]*population_modifier["base_pop_growth_class_multiplier"][i]))
      
      LogPop("RegionPopGrowth(region)", "434", "BaseGrowth %: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
    
      -- 2) Food Shortage
      
      if foodShortageNegative
      then
      
        regionPopModTable[i] = regionPopModTable[i] + population_modifier["food_shortage_mod_negative"][i];
      
      elseif foodShortage 
      then
      
        regionPopModTable[i] = regionPopModTable[i] + population_modifier["food_shortage_mod"][i];
      
      elseif foodShortageMid
      then
      
        regionPopModTable[i] = regionPopModTable[i] + population_modifier["food_shortage_mod_med"][i];
      
      else regionPopModTable[i] = regionPopModTable[i] + population_modifier["not_food_shortage_mod"][i];
      
      end;
      
      LogPop("RegionPopGrowth(region)", "444", "+ foodShortage: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));

      -- 3) Majority Religion & technology
      
      if majorityCulture
      then
      
        regionPopModTable[i] = regionPopModTable[i] + population_modifier["majority_religion_mod_own"][i];
        
        LogPop("RegionPopGrowth(region)", "449", "+ majorityCulture: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i])); 
        
        -- tech growth based on culture ???????????!!!!!!!!!! 
      
        for k, v in pairs(tech_pop_growth_own_culture_table)
        do
        
          if faction:has_technology(k)
          then
          
            regionPopModTable[i] = regionPopModTable[i] + tech_pop_growth_own_culture_table[k][i]
          
          end         
        end
        
        -- 9) building growth majority culture
        
        for slots = 0, region:slot_list():num_items() - 1
        do
        
          local slot = region:slot_list():item_at(slots);
        
          if slot:has_building()
          then 
          
            local buildingName = slot:building():name();
            
            LogPop("RegionPopGrowth(region)", "461", "buildingName: "..buildingName);
          
            if building_pop_growth_own_culture_table[buildingName]
            then
            
              regionPopModTable[i] = regionPopModTable[i] + building_pop_growth_own_culture_table[buildingName][i];
              
              LogPop("RegionPopGrowth(region)", "464", "+buildingName: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
            
            end;
          end;
        end;
        
      else
      
        regionPopModTable[i] = regionPopModTable[i] + population_modifier["majority_religion_mod_other"][i]
        
        LogPop("RegionPopGrowth(region)", "469", "+ majorityCulture: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i])); 
      
        -- tech growth based on culture ???????????!!!!!!!!!! 
        for k, v in pairs(tech_pop_growth_foreign_culture_table)
        do
        
          if faction:has_technology(k)
          then
          
            regionPopModTable[i] = regionPopModTable[i] + tech_pop_growth_foreign_culture_table[k][i];
          
          end; 
        end;
        
        -- 9) building growth minority culture
        
        for slots = 0, region:slot_list():num_items() -1
        do
        
          local slot = region:slot_list():item_at(slots)
        
          if slot:has_building()
          then 
          
            local buildingName = slot:building():name()
            
            LogPop("RegionPopGrowth(region)", "481", "buildingName: "..buildingName);
          
            if building_pop_growth_foreign_culture_table[buildingName]
            then
            
              regionPopModTable[i] = regionPopModTable[i] + building_pop_growth_foreign_culture_table[buildingName][i];
              
              LogPop("RegionPopGrowth(region)", "484", "+buildingName: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
            
            end;
          end;
        end;
      end;
      
      -- 4) Culture/Religion Bonuses
      
      if baseCultureInTable
      then
      
        regionPopModTable[i] = regionPopModTable[i]  + culture_growth_bonus[factionCulture][i];
        
        LogPop("RegionPopGrowth(region)", "492", "+ baseCultureInTable: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
      
      end;
      
      -- 5) Public Order growth bonus
      
      if publicOrder < 0
      then
      
        regionPopModTable[i] = regionPopModTable[i]  + population_modifier["public_order_growth_modifier"][i]  * publicOrder/100;
        
        LogPop("RegionPopGrowth(region)", "497", "+ population_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i])); 
      
      end;
      
      -- 6) Taxation -- tax level returns the percentage points of tax rate so needs to be converted to a decimal to fit with the format of the regionPopModTable values as decimals
      
      regionPopModTable[i] = regionPopModTable[i]  + (population_modifier["tax_growth_modifier"][i] * (-0.01 * (taxLevel - 140))) -- ???????!!!!!! tax_category
      
      LogPop("RegionPopGrowth(region)", "501", "+ tax_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i])); 
      
      -- 7) Faction Capital
      
      if regionIsHome
      then
      
        regionPopModTable[i] = regionPopModTable[i]  +  population_modifier["faction_capitol_growth_modifier"][i];
        
        LogPop("RegionPopGrowth(region)", "505", "+ faction_capitol_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
      
          -- 8) Province Capital 
      
      elseif provCap
      then
      
        regionPopModTable[i] = regionPopModTable[i]  +  population_modifier["province_capitol_growth_modifier"][i];
        
        LogPop("RegionPopGrowth(region)", "509", "+ province_capitol_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
      
          end;
      
      -- 10) Foreign Armies in region
      
      if foreignArmies
      then
      
        regionPopModTable[i] = regionPopModTable[i]  +  population_modifier["foreign_army_growth_modifier"][i];
        
        LogPop("RegionPopGrowth(region)", "514", "+ foreign_army_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
        
      end;
      
      --11) Under siege
      
      if underSiege
      then
      
        regionPopModTable[i] = regionPopModTable[i]  +  population_modifier["under_siege_growth_modifier"][i]; 
        
        LogPop("RegionPopGrowth(region)", "519", "+ under_siege_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
        
      end;
      
      -- 12) Looted settlement (Raze, looted)
      
      if regionLooted
      then
      
        regionPopModTable[i] = regionPopModTable[i]  +  population_modifier["looted_growth_modifier"][i];
        
        LogPop("RegionPopGrowth(region)", "524", "+ looted_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
        
      end;
      
      -- 13) Occupied Settlment
      
      if regionOccupied
      then -- and not regionLooted then ?????????
      
        regionPopModTable[i] = regionPopModTable[i]  +  population_modifier["occupied_growth_modifier"][i];  
        
        LogPop("RegionPopGrowth(region)", "529", "+ occupied_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i]));
        
      end;  
      
      -- 14) Difficulty difficulty -- not for MP
      
      if region:owning_faction():is_human()
      and not CampaignUI.IsMultiplayer()
      then
      
        regionPopModTable[i] = regionPopModTable[i]  +  population_modifier["difficulty_growth_modifier"][difficulty + 4]
        
        LogPop("RegionPopGrowth(region)", "534", "+ difficulty_growth_modifier: regionPopModTable["..i.."]: "..tostring(regionPopModTable[i])); 
        
      end;
      
      -- last) apply bundle to regionPopTable table
      
      if regionPopModTable[i] <= -1
      then
      
        regionPopModTable[i] = -0.95

      end;
      
      if regionPopTable[i] <= 1
      then
      
        regionPopTable[i] = 0.95

      end;
      
      -- Apply growth: regionPopModTable[i] is YEARLY %.
      -- Convert to per-turn by dividing by (turns_per_year * 100).
      local _campaign = GetCampaignName()
      SetGrowthDivisor(_campaign)
      local _per_turn = regionPopModTable[i] / growthDivisor

      -- AI wartime frontline recovery boost:
      -- If AI is at war and enemies were present this turn in the region, allow faster recovery so stacks rebuild and push out.
      if faction:is_human() == false and faction:at_war() and foreignArmies == true then
        _per_turn = _per_turn * 1.35
      end

      regionPopTable[i] = regionPopTable[i] * (1 + _per_turn)
      
      LogPop("RegionPopGrowth(region)", "540", "new population: regionPopTable["..i.."]: "..tostring(regionPopTable[i]));
      
    end;
    
    --  CharacterLootedSettlement 
    --  SettlementOccupied 
    
    -------------------------------------------------------------
    -- POP ADDITIONS
    -- add numbered calculation list in comment and code below
    --1) Minimum Growth
    --2) Apply new population to region
    -------------------------------------------------------------
  
    --1) Minimum growth settler units, unless city was razed/looted then you get none
    
    for i = 1, 4
    do 
    
      if (regionPopTable[i] < population_modifier["base_pop_growth_min_size"][i])
      then
      
        if regionLooted
        then
        
          regionPopTable[i] = regionPopTable[i];
        
        else
        
          regionPopTable[i] = regionPopTable[i] + population_modifier["base_pop_growth"][i];
        
        end;
      end;
    end; 
  
    --2) apply new pop figures to region pop list. Always use this function to update as it checks entries for errors
    
    SetRegionPop(regionName, regionPopTable[1], regionPopTable[2], regionPopTable[3], regionPopTable[4]);
    
    LogPop("RegionPopGrowth(region)", "560", "completed growth: " .. regionName);
  
  end; 
end;


-- ***** FACTION IMMIGRATION (requires faction context) ***** --

function FactionImmigration(faction)

  --calculate immigration factors for each region
  --reset region_desire table
  local regionNumber = 0
  local upTotal = 0
  local midTotal = 0
  local lowTotal = 0
  local foreignTotal = 0
  local factionTotal = 0
  -- table structure { <int> region type, <int> up desirability, <int> mid desirability, <int> low desirability, <int> foreign desire}
  local faction_region_change = {}
  local factionSize = faction:region_list():num_items()
  local factionName = faction:name()
  
  -- check if rebels
  if factionName == "rebels" 
  then
  
    return
  
  end
  
  local factionLosingMoney = false
  Debug("Faction name immigration " .. factionName  , "FactionImmigration()")
  
  if (factionSize > 1)
  then
  
    Debug("Faction size greater than 0 = " .. factionSize  , "FactionImmigration()")
  
    if faction:losing_money()
    then
    
      factionLosingMoney = false
  
    end
  
    local hasFoodShortage = faction:has_food_shortage()
    local taxLevel = faction:tax_level()
    local numAllies = faction:num_allies()
    local idleResearch = faction:research_queue_idle()
    local factionTreasury = faction:treasury()
    local factionReligion = faction:state_religion()
    local tech_modifier = { 0,0,0,0}
    local seaRouteRaided = faction:sea_trade_route_raided()
    local atWar = faction:at_war()
    
    --17) tech can impact region desirability
    
    for k, v in pairs(technology_desirability)
    do
    
      if faction:has_technology(k)
      then
      
        for i = 1, 4
        do
        
          tech_modifier[i] = tech_modifier[i] + technology_desirability[k][i]
        
        end
      end 
    end 
    
    Debug("tech immigration " .. factionName  , "FactionImmigration()")
    
    for number = 0, factionSize - 1
    do
      regionNumber = number
    
      local region = faction:region_list():item_at(regionNumber)
      local regionName = region:name()
      local regionPop = { region_table[regionName][1], region_table[regionName][2], region_table[regionName][3], region_table[regionName][4] }
      local up = regionPop[1]
      local mid = regionPop[2]
      local low = regionPop[3]
      local foreign = regionPop[4]
      local citizenPop = up + mid + low 
    
      upTotal = upTotal + up
      midTotal = midTotal + mid
      lowTotal = lowTotal + low
      foreignTotal = foreignTotal + foreign
    
      local immigrationDesire = 0
      local regionType = 0
      local numNonAllies = 0
    
      region_desire[regionName][1] = 0
      region_desire[regionName][2] = 0
      region_desire[regionName][3] = 0
      region_desire[regionName][4] = 0
    
      -- determine region type 1) Faction capital 2) Province Capital 3) Minor 4) Frontier
      
      --1)Faction Capitol
      
      local homeRegion = region:garrison_residence():faction():home_region():name()
    
      if regionName ==  homeRegion
      then 
      
        regionType = 1
      
      --2) Province Capitol
      
      elseif (region:building_superchain_exists("rom_SettlementMajor")
      or region:building_superchain_exists("dei_superchain_city_ROME")
      or region:building_superchain_exists("dei_superchain_city_PELLA")
      or region:building_superchain_exists("dei_superchain_city_CARTHAGE")
      or region:building_superchain_exists("dei_superchain_city_SYRACUSE")
      or region:building_superchain_exists("dei_superchain_city_ATHENS")
      or region:building_superchain_exists("dei_superchain_city_ALEXANDRIA")
      or region:building_superchain_exists("dei_superchain_city_PERGAMON")
      or region:building_superchain_exists("dei_superchain_city_ANTIOCH")
      or region:building_superchain_exists("dei_superchain_city_MASSILIA")
      or region:building_superchain_exists("dei_superchain_city_BIBRACTE")
	  or region:building_superchain_exists("dei_superchain_city_ZARM")
      or region:building_superchain_exists("inv_etr_main_city"))
      then
      
        regionType = 2
    
      else
    
        for i = 0, region:adjacent_region_list():num_items() -1
        do
          local adjacentRegion = region:adjacent_region_list():item_at(i)
      
          if ( adjacentRegion:owning_faction():name() ~= factionName )
          and not adjacentRegion:owning_faction():allied_with(factionName)
          then
          
            numNonAllies = numNonAllies + 1
        
          end
        end
      
        -- 4) Frontier
        
        if ( numNonAllies > 0 )
        then
        
          regionType = 4
        
        --3) Minor
        
        else
        
          regionType = 3
        
        end
      end
    
      -- Determine modifiers
      
      
      --1) food shortage
      
      if hasFoodShortage 
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["food_shortage_desire"][regionType]
      
      end
      
      --2) treasury level 
      
      if ( factionTreasury > immigration_modifiers["treasury_levels_desire"]["huge"][1] )
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["treasury_levels_desire"]["huge"][regionType + 1]
      
      elseif ( factionTreasury > immigration_modifiers["treasury_levels_desire"]["large"][1] )
      then 
      
        immigrationDesire = immigrationDesire + immigration_modifiers["treasury_levels_desire"]["large"][regionType + 1] 
      
      elseif ( factionTreasury > immigration_modifiers["treasury_levels_desire"]["moderate"][1] )
      then 
      
        immigrationDesire = immigrationDesire + immigration_modifiers["treasury_levels_desire"]["moderate"][regionType + 1] 
      
      elseif ( factionTreasury > immigration_modifiers["treasury_levels_desire"]["increasing"][1] )
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["treasury_levels_desire"]["increasing"][regionType + 1]  
      
      elseif ( factionTreasury > immigration_modifiers["treasury_levels_desire"]["small"][1] )
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["treasury_levels_desire"]["small"][regionType + 1]   
      
      else
      
        immigrationDesire = immigrationDesire + immigration_modifiers["treasury_levels_desire"]["tiny"][regionType + 1]  
      
      end
      
      --3) losing money
      
      if factionLosingMoney
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["faction_losing_money"][regionType]
      
      end  
      
      --4) Faction at_war
      
      if atWar
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["faction_at_war"][regionType]
      
      end
    
      --5) sea_trade_route_raided; pop goes to minor regions
      
      if seaRouteRaided
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["sea_trade_route_raided"][regionType]
      
      end
      
      --6) faction; different factions can have more likilyhood to be ruralised or urban
      
      if faction_immigration_modifiers[factionName]
      then
      
        immigrationDesire = immigrationDesire + faction_immigration_modifiers[factionName][regionType]
      
      end
      
      --7) tax_level; people flee to frontiers with high tax to avoid the tax man
      
      if (taxLevel ~= 100)
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["tax_level"][regionType]*(-0.01*(taxLevel -140 ))
      
      end
      
      --8) research_queue_idle; stagnant culture will result in people leaving capitals and going to minor regions
      
      if idleResearch
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["idle_research"][regionType]
      
      end
      
      --9) num_allies; reduces penalty in frontier regions if the faction has multiple allies
      
      if numAllies > 0
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["number_of_allies_mult"][regionType]*numAllies
      
      end
      
      --10) Undersiege: all pops will leave a settlement undersiege
      
      if region:garrison_residence():is_under_siege()
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["under_siege"][regionType]
      
      --11) foreign army present: all pops will leave
      
      elseif region_flag[regionName][ENEMIES_PRESENT]
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["foreign_armies"][regionType]
      
      end
      
      --12) battle fought; all pops will leave
      
      if region_flag[regionName][BATTLE_FOUGHT]
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["number_of_allies_mult"][regionType]
      
      end
      
      --13) majority culture; foreigners prefer non majority and citizens prefer majority
      
      if (region:majority_religion() ==  factionReligion)
      then
      
        immigrationDesire = immigrationDesire + immigration_modifiers["number_of_allies_mult"][regionType]
      
      end
      
      --14) buildings; can give a bonus to desirability
      
      for slots = 0, region:slot_list():num_items() -1
      do
      
        local slot = region:slot_list():item_at(slots)
      
        if slot:has_building()
        then 
        
          local buildingName = slot:building():name()
        
          if building_desirability[buildingName]
          then
          
            immigrationDesire = immigrationDesire + building_desirability[buildingName][regionType]
          
          end 
        end 
      end
      
      --15) Tech desirability
      
      immigrationDesire = immigrationDesire + tech_modifier[regionType]  
    
      --18) Pop ratios: Each type of region will have its ideal population ratio. if the regions pop ratio is different to the ideal then it will get a bonus to bring it into line with the ideal base ratio
      
      if immigrationDesire < 1 
            then
      
        immigrationDesire = 1
      
            end
      
      --apply ratio adjustment
      -- set region desire value
      local factionClass
      
      if faction_to_faction_pop_class[factionName]
      then 
      
        factionClass = faction_to_faction_pop_class[factionName]
    
      else 
      
        factionClass = "default"
      
      end
    
      for i =1, 4
      do
      
        --get region pop i
        local ratioIdeal = faction_pop_ratio_eco[factionClass][i]
        local desireMultiplier = 1
    
        if i < 4 
        then
        
          local currentRatio = regionPop[i]/citizenPop
          
          desireMultiplier = immigration_modifiers["pop_ratio_adjustment_multiplier"] *  (ratioIdeal / currentRatio )
      
        end
        
        region_desire[regionName][i] = immigrationDesire *  desireMultiplier
        
      end
    
    --  PopLog("region desire  = " .. region_desire[regionName][1] .. " " .. region_desire[regionName][2] .. " " .. region_desire[regionName][3] .. " " .. region_desire[regionName][4], "FactionImmigration()")
    
    end
    
    Debug("first pass immigration " .. factionName  , "FactionImmigration()")
  
    --calculate movements
    for number = 0, factionSize - 1
    do
    
      local region = faction:region_list():item_at(number)
      local regionName = region:name()
      local regionPop = { region_table[regionName][1], region_table[regionName][2], region_table[regionName][3], region_table[regionName][4] }
      local this_region_desire = { region_desire[regionName][1], region_desire[regionName][2], region_desire[regionName][3], region_desire[regionName][4] }
      local numAdjacentRegions = region:adjacent_region_list():num_items()
    
      for i = 0, numAdjacentRegions -1
      do
      
        local adjacentRegion = region:adjacent_region_list():item_at(i)
        local adjacentName = adjacentRegion:name()

        -- check adjacent region is owned by faction    
        if adjacentRegion:owning_faction() == region:owning_faction()
        then
        
          local adjacent_region_desire = { region_desire[adjacentName][1], region_desire[adjacentName][2], region_desire[adjacentName][3], region_desire[adjacentName][4] }
        
          --compare pop class desire values and apply population movements
          for popClass  = 1, 4
          do  
          
            -- if region desire greater in adjacent region for class
            if  adjacent_region_desire[popClass] > this_region_desire[popClass]
            then
            
              local adjacentDesire = region_desire[adjacentName][popClass]
              local adjacentApeal = adjacentDesire - region_desire[regionName][popClass]
            
              -- get original pop value before any adjustments. Because pop is adjusted immediately regionPop[i] would change for each new adjacent region compared.
              local comparisonPop = regionPop[popClass] - region_desire[regionName][popClass + 4]
            
              -- calcualate number of pop to leave
              local migrate = math.floor(comparisonPop * immigration_modifiers["region_desire_max_movement"]*(adjacentApeal/adjacentDesire))

              -- check there are enough people to migrate       
              if migrate + population_modifier.base_pop_growth_min_size[popClass] < region_table[regionName][popClass]
              then
              
                --  PopLog("before region = " .. adjacentName .. " region pop = " ..  region_table[adjacentName][popClass] , "FactionImmigration()")
              
                -- add pop to UI table for adjacent region
                region_desire[adjacentName][popClass + 4] = region_desire[adjacentName][popClass + 4] +  migrate
              
                -- remove pop from UI table for region 
                region_desire[regionName][popClass + 4] = region_desire[regionName][popClass + 4] -  migrate
              
                -- update adjacent region pop value
                region_table[adjacentName][popClass] = region_table[adjacentName][popClass] + migrate
                
                -- update region pop value        
                region_table[regionName][popClass] = region_table[regionName][popClass] - migrate
                
                -- PopLog("before region = " .. adjacentName .. " region pop = " ..  region_table[adjacentName][popClass] .. " migration = " .. migrate , "FactionImmigration()")
        
              end
            end
          end 
          
          -- PopLog("Adjacent Region desire = " .. region_desire[adjacentName][1] , "FactionImmigration()")
    
        end
      end
    
      Debug("2nd pass immigration " .. factionName  , "FactionImmigration()")
    
      -- calculate cross water movements if region is can move people
      if region_sea_additional_adjacent[regionName]
      then
      
        -- PopLog("Check sea migration " .. regionName , "FactionImmigration()")
        -- find if faction owns moveable regions
        local factionRegionList = faction:region_list()
       
        --compare faction region list with possible sea migration regions
        for factionRegion = 0, factionRegionList:num_items() - 1
        do
        
          local checkRegion = factionRegionList:item_at(factionRegion) 
          local checkRegionName = checkRegion:name()
        
          -- PopLog("Check against " .. checkRegionName , "FactionImmigration()")
          if Contains(region_sea_additional_adjacent[regionName], checkRegionName)
          then
          
            -- PopLog("Checking Pop Classes " .. checkRegionName , "FactionImmigration()") 
            local adjacent_region_desire = { region_desire[checkRegionName][1], region_desire[checkRegionName][2], region_desire[checkRegionName][3], region_desire[checkRegionName][4] }
      
            -- compare pop class desire values and apply population movements
            for popClass  = 1, 4
            do
            
              -- if region desire greater in adjacent region for class
              -- PopLog("Desire Value adjacent" .. popClass .. " = " .. adjacent_region_desire[popClass]  , "FactionImmigration()")
              -- PopLog("Desire Value region" .. popClass .. " = " .. this_region_desire[popClass] , "FactionImmigration()")
              
              if  adjacent_region_desire[popClass] > this_region_desire[popClass]
              then
              
                local adjacentDesire = region_desire[checkRegionName][popClass]
                local adjacentApeal = adjacentDesire - region_desire[regionName][popClass]
                -- get original pop value before any adjustments. Because pop is adjusted immediately regionPop[i] would change for each new adjacent region compared.
                local comparisonPop = regionPop[popClass] - region_desire[regionName][popClass + 4]
                -- calcualate number of pop to leave
                local migrate = math.floor(comparisonPop * (immigration_modifiers["region_desire_max_movement"]*(adjacentApeal/adjacentDesire))/immigration_modifiers["water_immigration_divisor"])
              
                -- check there are enough people to migrate, make sure there is still enough pop per class left
                if migrate + population_modifier.base_pop_growth_min_size[popClass] < region_table[regionName][popClass]
                then
                
                  -- PopLog("Migrate Over Sea " .. regionName .. " to " .. checkRegionName , "FactionImmigration()")
                  -- PopLog("before region = " .. adjacentName .. " region pop = " ..  region_table[adjacentName][popClass] , "FactionImmigration()")
                
                  -- add pop to UI table for adjacent region
                  region_desire[checkRegionName][popClass + 4] = region_desire[checkRegionName][popClass + 4] +  migrate
                
                  -- remove pop from UI table for region 
                  region_desire[regionName][popClass + 4] = region_desire[regionName][popClass + 4] -  migrate
                
                  -- update adjacent region pop value
                  region_table[checkRegionName][popClass] = region_table[checkRegionName][popClass] + migrate
                
                  -- update region pop value
                  region_table[regionName][popClass] = region_table[regionName][popClass] - migrate
                
                  -- PopLog("before region = " .. adjacentName .. " region pop = " ..  region_table[adjacentName][popClass] .. " migration = " .. migrate , "FactionImmigration()")
                
                end
              end
            end
          end
        end
      end
      
      Debug("sea immigration " .. factionName  , "FactionImmigration()")
    
    end
  end
end


-- ***** APPLY REGION BUNDLE (calculation and application of region effect bundles) ***** --
-- ***** expects region event context (not region())

function ApplyRegionBundle(region, cqi)
PopLog("RegionBundle Initialisation started ", "ApplyRegionBundle()")

  local regionName = region:name()
  local regionPop = {0,0,0,0}
  local totalPop = 0
  local factionName = region:owning_faction():name()
  local factionCategory = "default"

  PopLog("RegionBundle Initialisation started ", "ApplyRegionBundle()")

  if faction_to_faction_pop_class[factionName]
  then
    factionCategory = faction_to_faction_pop_class[factionName]
  end
  
  PopLog("RegionBundle Initialisation Complete faction set " .. tostring(factionCategory), "ApplyRegionBundle()")
  -- get & set region pop values
  regionPop = {region_table[regionName][1] , region_table[regionName][2], region_table[regionName][3], region_table[regionName][4]}
  totalPop = regionPop[1] + regionPop[2] + regionPop[3] + regionPop[4]
  
  -- bundle variables
  local bundle_1 = "none"
  local bundle_2 = "none"
  local bundle_3 = "none"
  local bundle_4 = "none"
  local bundle_5 = "none" 
  
  -- get ideal pop ratios
  local up = regionPop[1]
  local mid = regionPop[2]
  local low = regionPop[3]
  local foreign = regionPop[4]
  local citizens = up + mid + low
  
  -- Percentage
  local foreignTotalPercent = foreign / totalPop
  local upCitizenPercent = up / citizens
  local midCitizenPercent = mid / citizens
  local lowCitizenPercent = low / citizens
  
  -- region states    
  -- foreign %
  -- determine effect bundle set
  if (factionCategory ~= "default")
  then
  
    PopLog("RegionBundle category not default", "ApplyRegionBundle()")
  
  else
  
    -- 1) Foreigner % - bundle_1
    
    -- heartland
    
    if (foreignTotalPercent < 0.2)
    then
    
      bundle_1 = region_state_eco[factionCategory][1][1]
    
    -- Provincial
    
    elseif (foreignTotalPercent < 0.6)
    then  
    
      bundle_1 = region_state_eco[factionCategory][1][2]
    
    -- Colony
    
    elseif (foreignTotalPercent < 0.8)
    then
    
      bundle_1 = region_state_eco[factionCategory][1][3]
    
    -- Subject Kigndom
    
    else 
    
      bundle_1 = region_state_eco[factionCategory][1][4]
    
    end   
    PopLog("RegionBundle bundle_1" .. bundle_1, "ApplyRegionBundle()")
    
    -- 2) upper citizen ratio - bundle_2
    
    -- overbearing
    
    if ( upCitizenPercent > (faction_pop_ratio_eco[factionCategory][1] * 3))
    then
    
      bundle_2 = region_state_eco[factionCategory][2][1]
    
    -- strong
    
    elseif ( upCitizenPercent > (faction_pop_ratio_eco[factionCategory][1] * 1.5))
    then
    
      bundle_2 = region_state_eco[factionCategory][2][2]
    
    -- weak
    
    elseif ( upCitizenPercent < (faction_pop_ratio_eco[factionCategory][1] * 0.8))
    then
    
      bundle_2 = region_state_eco[factionCategory][2][3]
    
    -- minimal
    
    elseif ( upCitizenPercent < (faction_pop_ratio_eco[factionCategory][1] * 0.3))
    then
    
      bundle_2 = region_state_eco[factionCategory][2][4]
    
    else
    
      bundle_2 = region_state_eco[factionCategory][2][5]
    
    end
    PopLog("RegionBundle bundle_2" .. bundle_2, "ApplyRegionBundle()")
    
    -- 3) mid citizen ratio - bundle_3
    
    -- thriving
    
    if ( midCitizenPercent > (faction_pop_ratio_eco[factionCategory][2] * 3))
    then
    
      bundle_3 = region_state_eco[factionCategory][3][1]
    
      -- industrious
    
    elseif ( midCitizenPercent > (faction_pop_ratio_eco[factionCategory][2] * 1.5))
    then
    
      bundle_3 = region_state_eco[factionCategory][3][2]
    
      -- stagnant
    
    elseif ( midCitizenPercent < (faction_pop_ratio_eco[factionCategory][2] * 0.8))
    then
    
      bundle_3 = region_state_eco[factionCategory][3][3]
    
      -- failing
    
    elseif ( midCitizenPercent < (faction_pop_ratio_eco[factionCategory][2] * 0.3))
    then
    
      bundle_3 = region_state_eco[factionCategory][3][4]
    
    else
    
      bundle_3 = region_state_eco[factionCategory][3][5]
    
    end
    
    -- PopLog("RegionBundle bundle_3" .. bundle_3, "ApplyRegionBundle()")
    
    -- 4) No low class effect
    
  end
  
  -- 5) Total Pop Size - bundle_5
  -- extremely_dense
  
  if ( totalPop > economic_data["pop_extremely_dense"] )
  then
  
    bundle_5 = region_state_eco[factionCategory][5][1]
  
    -- very_dense
  
  elseif ( totalPop > economic_data["pop_very_dense"])
  then
  
    bundle_5 = region_state_eco[factionCategory][5][2]
  
    -- dense
  
  elseif ( totalPop > economic_data["pop_dense"])
  then
  
    bundle_5 = region_state_eco[factionCategory][5][3]
  
    -- fairly_dense
  
  elseif ( totalPop > economic_data["pop_fairly_dense"])
  then
  
    bundle_5 = region_state_eco[factionCategory][5][4]  
  
  elseif ( totalPop > economic_data["pop_moderate"])
  then
  
    bundle_5 = region_state_eco[factionCategory][5][5]
  
  elseif ( totalPop > economic_data["pop_sparse"])
  then
  
    bundle_5 = region_state_eco[factionCategory][5][6]
  
  elseif ( totalPop > economic_data["pop_very_sparse"])
  then
  
    bundle_5 = region_state_eco[factionCategory][5][7]
  
  elseif ( totalPop > economic_data["pop_extremely_sparse"])
  then
  
    bundle_5 = region_state_eco[factionCategory][5][8]
  
    -- very_sparse
  
  else
  
    bundle_5 = region_state_eco[factionCategory][5][9]
  
  end

  -- remove existing bundles
  RemoveRegionBundle(cqi)
  
  -- add new bundles if they need to be added
  -- add new bundles for 1 turn incase there is a bundle double up they will expire in 1 turn 
  PopLog("RegionBundle cqi" .. cqi, "ApplyRegionBundle()")
  if (bundle_1 ~= "none")
  then
  
    scripting.game_interface:apply_effect_bundle_to_characters_force(tostring(bundle_1), cqi,-1)
    PopLog("RegionBundle bundle_1 applied " .. bundle_1, "ApplyRegionBundle()")
  
  end
  
  if (bundle_2 ~= "none")
  then
  
    scripting.game_interface:apply_effect_bundle_to_characters_force(tostring(bundle_2), cqi,-1)
    PopLog("RegionBundle bundle_2 applied" .. bundle_2, "ApplyRegionBundle()")
  end
  
  if (bundle_3 ~= "none") 
  then
  
    scripting.game_interface:apply_effect_bundle_to_characters_force(tostring(bundle_3), cqi,-1)
    PopLog("RegionBundle bundle_3 applied" .. bundle_3, "ApplyRegionBundle()")
  
  end
  
  if (bundle_4 ~= "none")
  then
  
    scripting.game_interface:apply_effect_bundle_to_characters_force(tostring(bundle_4), cqi,-1)
    PopLog("RegionBundle bundle_4 applied" .. bundle_4, "ApplyRegionBundle()")
  
  end
  
  if (bundle_5 ~= "none")
  then
  
    scripting.game_interface:apply_effect_bundle_to_characters_force(tostring(bundle_5), cqi,-1)
    PopLog("RegionBundle bundle_5 applied" .. bundle_5, "ApplyRegionBundle()")
  
  end
end


-- ***** REMOVE REGION BUNDLE ***** --

function RemoveRegionBundle(cqi)

  -- scripting.game_interface:remove_effect_bundle_from_characters_force(effectBundle, cqi)
  for k, v in ipairs(region_economic_effect_bundle)
  do
  
    scripting.game_interface:remove_effect_bundle_from_characters_force(v, cqi)
  
  end
end


-- ***** GET REGION GARRISON CQI (context is region event context) ***** --

function GetRegionGarrisonCqi(context)

  -- DOESN'T WORK
  character_list = context:owning_faction():character_list()
  for i = 0, character_list:num_items() - 1
  do  
  
    PopLog("FCharacter" .. character_list:item_at(i):cqi() , "GetRegionGarrisonCqi()")
  
    if  (character_list:item_at(i):region():name() == context:name())
    then
    
      PopLog("Character in region"  , "GetRegionGarrisonCqi()")
    
      if character_list:item_at(i):character_type("colonel")
      then
      
        PopLog("character is region garrison colonel"  , "GetRegionGarrisonCqi()")
        
        return character_list:item_at(i):cqi()
      
      end
    end
  end 
end 


-- ***** CONTAINED INTO TABLE ***** --

function Contains(table_name, value)

  for k, v in pairs(table_name)
  do
  
    if table_name[k] == value
    then
    
      return true
    
    end
  end
  
  return false
  
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- NEW GAME, SAVE AND LOAD CHARACTER LIST, APPLY INITIAL REGION LIST  ---------------------------------------------------------------------
-- #####-------------------------


-- ***** NEW GAME SETUP ***** --
-- ***** This function confirms that the script has loaded and which campaign is being played

local function OnWorldCreatedPop(context)

  -- get campaign name and save in global variable
  SetRegionTable()
  createNewLog("Hello")
  PopLog("Pop script world created"  , "OnWorldCreatedPop()") 

end


-- ***** SAVE (region_list pop table) ***** --

local function OnSavingGamePop(context)

  -- region pop table value saves
  for k,v in pairs(region_table)
  do
    
    --save key in numbered variable that will then be used to retrieve the k,v pairs
    for i =1, 4
    do
    
      scripting.game_interface:save_named_value("_pop_" .. k .. "_" ..i, region_table[k][i], context) 
    
    end 
  end 

    -- UIPopulation table saves
  for k,v in pairs(UIPopulation)
  do
  
    -- save key in numbered variable that will then be used to retrieve the k,v pairs
    for i =1, 4
    do
    
      scripting.game_interface:save_named_value("_pop_UI_" .. k .. "_" ..i, UIPopulation[k][i], context) 
    
    end 
  end 

  -- region flag tables saves
  for k,v in pairs(region_flag)
  do
  
    -- save key in numbered variable that will then be used to retrieve the k,v pairs
    if k[ENEMIES_PRESENT] == true
    then
    
      scripting.game_interface:save_named_value("_pop_flag" .. k .. "_" ..ENEMIES_PRESENT, region_flag[k][ENEMIES_PRESENT], context) 
    
    end 
    
    if k[SETTLEMENT_LOOTED] == true
    then
    
      scripting.game_interface:save_named_value("_pop_flag" .. k .. "_" ..SETTLEMENT_LOOTED, region_flag[k][SETTLEMENT_LOOTED], context) 
    
    end
    
    if k[SETTLEMENT_OCCUPIED] == true
    then
    
      scripting.game_interface:save_named_value("_pop_flag" .. k .. "_" ..SETTLEMENT_OCCUPIED, region_flag[k][SETTLEMENT_OCCUPIED], context) 
    
    end
  end 
  
  scripting.game_interface:save_named_value("army_cqi_attacker", army_cqi_attacker, context);
  scripting.game_interface:save_named_value("army_cqi_defender", army_cqi_defender, context);
  
  saveRecruitmentOrdersTable(context)
  savearmy_size_cqi(context)
  savearmyStateRegion(context)
  -- save new campaign variable
  -- scripting.game_interface:save_named_value("isprefixgame", isprefixgame, context);
  scripting.game_interface:save_named_value("triggerload", triggerload, context);
  
  PopLog("game saved successfully", "OnSavingGamePop()")
  -- PrintRegionTable(region_table)
  
end


-- ***** LOAD (region_list pop table) ***** --

local function OnLoadingGamePop(context)

  Log("OnLoadingGamePop()")
  -- assign the table name to the region_table variable
  local campaign = scripting.game_interface:model():campaign_name()
  
  SetGrowthDivisor(campaign)
  SetRegionTable()
  
  local up 
  local mid
  local low
  local foreign
  
  for k,v in pairs(region_table)
  do
    -- save region data into temp table
    up = scripting.game_interface:load_named_value("_pop_" .. k .. "_1", -1, context)
  
    if up == -1
    then
      -- PopLog("New Game Started", "OnLoadingGamePop()")
      return
    end
    
    mid = scripting.game_interface:load_named_value("_pop_" .. k .. "_2", -1, context)      
    low = scripting.game_interface:load_named_value("_pop_" .. k .. "_3", -1, context)
    foreign = scripting.game_interface:load_named_value("_pop_" .. k .. "_4", -1, context)
    -- PopLog("region " ..  k  .. up .. " " .. mid .. " " .. low .. " " .. foreign, "OnLoadingGamePop()")
    -- assign temp table to region_table
    SetRegionPop(k, up, mid, low, foreign)
    -- resetUIPopulation()  not a good idea setting the pop back to region pop should only be done on Faction turn start!
      
  end
  
  -- UIPopulation table
  resetUIPopulation()
  
  for k,v in pairs(UIPopulation) do
    -- save region data into temp table
    up = scripting.game_interface:load_named_value("_pop_UI_" .. k .. "_1", -1, context)
  
    if up == -1
    then   
      -- PopLog("New Game Started", "OnLoadingGamePop()")
      return
    end
    
    mid = scripting.game_interface:load_named_value("_pop_UI_" .. k .. "_2", -1, context)     
    low = scripting.game_interface:load_named_value("_pop_UI_" .. k .. "_3", -1, context)
    foreign = scripting.game_interface:load_named_value("_pop_UI_" .. k .. "_4", -1, context)
    -- PopLog("region " ..  k  .. up .. " " .. mid .. " " .. low .. " " .. foreign, "OnLoadingGamePop()")
    -- assign temp table to UIPopulation
    UIPopulation[k][1] = up
    UIPopulation[k][2] = mid
    UIPopulation[k][3] = low
    UIPopulation[k][4] = foreign 
    -- resetUIPopulation()  not a good idea setting the pop back to region pop should only be done on Faction turn start!
 
  end
  
  -- populate region_flag table
  for k,v in pairs(region_flag)
  do
  
    -- load region data into temp table
    region_flag[k][ENEMIES_PRESENT] = scripting.game_interface:load_named_value("_pop_flag" .. k .. "_1", false, context)
    region_flag[k][SETTLEMENT_LOOTED] = scripting.game_interface:load_named_value("_pop_flag" .. k .. "_2", false, context)
    region_flag[k][SETTLEMENT_OCCUPIED] = scripting.game_interface:load_named_value("_pop_flag" .. k .. "_3", false, context) 
    
  end 

  -- save pending battle data
  army_cqi_attacker = scripting.game_interface:load_named_value("army_cqi_attacker", 0, context);
  army_cqi_defender = scripting.game_interface:load_named_value("army_cqi_defender", 0, context);
  
  loadRecruitmentOrdersTable(context)
  loadarmyStateRegion(context)
  loadarmy_size_cqi(context)
  -- load new campaign variable
  -- isprefixgame = scripting.game_interface:load_named_value("isprefixgame", false, context);
  PopLog("game loaded successfully", "OnLoadingGamePop()")
  -- PrintRegionTable(region_table)
  
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- SAVING/LOADING  ---------------------------------------------------------------------
-- #####-------------------------


-- ***** LOAD ARMY SIZE CQI ***** --

function loadarmy_size_cqi(context)

  local armyKeyList = LoadIndexTable(context, "army_size_cqi_armyKeyList")
  
  for index, armyKey in pairs(armyKeyList)
  do
  
    PopLog("index: " .. tostring(index) .. ", armyKey: " .. tostring(armyKey))
    
    army_size_cqi[tostring(armyKey)] = LoadIndexTable(context, "army_size_cqi_" .. armyKey)
    
    for key, value in pairs(army_size_cqi[tostring(armyKey)])
    do
    
      PopLog("key: " .. tostring(key) .. ", value: " .. tostring(value))
      
    end
  end
end


-- ***** SAVE ARMY SIZE CQI ***** --

function savearmy_size_cqi(context)

  local armyKeyList = {}
  
  for key, value in pairs(army_size_cqi)
  do
  
    table.insert(armyKeyList, tostring(key))
    
    SaveIndexTable(context, army_size_cqi[key], "army_size_cqi_" .. tostring(key))
    
    PopLog("savearmy_size_cqi: ")
    PopLog("key: " .. tostring(key) .. ", value: " .. tostring(value))
    
  end
  
  SaveIndexTable(context, armyKeyList, "army_size_cqi_armyKeyList")
  
end


-- ***** LOAD RECRUITMENT ORDERS TABLE ***** --

function loadRecruitmentOrdersTable(context)

  local armyKeyList = LoadIndexTable(context, "recruitmentOrders_armyKeyList")
  for index, armyKey in pairs(armyKeyList)
  do
  
    -- PopLog("index: " .. index .. ", armyKey: " .. armyKey)
    recruitmentOrders[tostring(armyKey)] = LoadIndexTable(context, "recruitmentOrders_" .. armyKey)
    
    for key, value in pairs(recruitmentOrders[tostring(armyKey)])
    do
    
      PopLog("key: " .. key .. ", value: " .. value)
    
    end
  end
end


-- ***** SAVE RECRUITMENT ORDERS TABLE ***** --

function saveRecruitmentOrdersTable(context)

  local armyKeyList = {}
  
  for key, value in pairs(recruitmentOrders)
  do
  
    table.insert(armyKeyList, tostring(key))
    
    SaveIndexTable(context, recruitmentOrders[key], "recruitmentOrders_" .. tostring(key))
    
  end
  
  SaveIndexTable(context, armyKeyList, "recruitmentOrders_armyKeyList")
  
end


-- ***** LOAD ARMY STATE REGION ***** --

function loadarmyStateRegion(context)

  local armyKeyList = LoadIndexTable(context, "armyStateRegion_armyKeyList")
  
  for index, armyKey in pairs(armyKeyList)
  do
  
    -- PopLog("index: " .. index .. ", armyKey: " .. armyKey)
    armyStateRegion[tostring(armyKey)] = LoadIndexTable(context, "armyStateRegion_" .. armyKey)
    
    for key, value in pairs(armyStateRegion[tostring(armyKey)])
    do
    
      PopLog("key: " .. key .. ", value: " .. value)
      
    end
  end
end


-- ***** SAVE ARMY STATE REGION ***** --

function savearmyStateRegion(context)

  local armyKeyList = {}
  
  for key, value in pairs(armyStateRegion)
  do
  
    table.insert(armyKeyList, tostring(key))
    
    SaveIndexTable(context, armyStateRegion[key], "armyStateRegion_" .. tostring(key))
    
  end
  
  SaveIndexTable(context, armyKeyList, "armyStateRegion_armyKeyList")
  
end


-- ***** SAVE KEY PAIR TABLE ***** --

function SaveKeyPairTable(context, tab, savename)

  -- PopLog("Saving Key Pair Table: "..savename);
  local savestring = "";
  
  for key,value in pairs(tab)
  do
  
    -- PopLog("SaveIndexTable:" ..key, "SaveIndexTable()");
    -- PopLog("SaveIndexTable:" ..value, "SaveIndexTable()");
    savestring = savestring..key..","..value..",;";
    
    PopLog("savestring: "..savestring)
    
  end
  
  cm:save_value(savename, savestring, context);
  
end


-- ***** LOAD KEY PAIR TABLE ***** --

function LoadKeyPairTable(context, savename)

  -- PopLog("Loading Key Pair Table: "..savename);
  local savestring = cm:load_value(savename, "", context);
  local tab = {};
  
  if savestring ~= ""
  then
    local first_split = SplitString(savestring, ";");
  
    for i = 1, #first_split
    do
    
      -- PopLog("\t\t"..first_split[i]);
      local second_split = SplitString(first_split[i], ",");
      
      tab[second_split[1]] = second_split[2];
      
      PopLog("\t\t\t"..savename.."[\""..second_split[1].."\"] = "..second_split[2]);
    
    end
  end
  
  return tab;
  
end


-- ***** LOAD KEY PAIR TABLE NEW ***** --

function LoadKeyPairTableNew(context, savename)

  -- PopLog("Loading Key Pair Table: "..savename);
  local savestring = cm:load_value(savename, "", context);
  local tab = {};

  if savestring ~= ""
  then
  
    local first_split = SplitString(savestring, ";");
    
    for i = 1, #first_split
    do
    
      -- PopLog("\t\t first_split "..first_split[i]);
      local second_split = SplitString(first_split[i], ",");
      
      tab[second_split[1]] = {}
      tab[second_split[1]]["unitCount"] = tonumber(second_split[2]); --["unitCount"] 
      tab[second_split[1]]["soldierCount"] = tonumber(second_split[3]); -- ["soldierCount"]
      
      PopLog("\t\t\t"..savename.."[\""..second_split[1].."\"][unitCount] = "..second_split[2]);
      PopLog("\t\t\t"..savename.."[\""..second_split[1].."\"][soldierCount] = "..second_split[3]);
      
    end
  end
  
  return tab;
  
end


-- ***** SAVE INDEX TABLE NEW ***** --

function SaveIndexTableNew(context, tab, savename)

  -- PopLog("Saving Indexed Table: "..savename);
  local savestring = "";
  
  for key,value in pairs(tab)
  do
  
    -- PopLog("SaveIndexTable key: " ..key, "SaveIndexTable()");
    local unitCount = tab[key]["unitCount"]
    local soldierCount = tab[key]["soldierCount"]
    -- PopLog("SaveIndexTable value: " ..tab[key]["soldierCount"], "SaveIndexTable()");
    -- PopLog("SaveIndexTable value: " ..tab[key]["unitCount"], "SaveIndexTable()");
    savestring = savestring..key..","..unitCount..","..soldierCount..",;";
    
    PopLog("savestring: "..savestring)
    
  end
  
  cm:save_value(savename, savestring, context);
  
end


-- ***** SAVE INDEX TABLE ***** --

function SaveIndexTable(context, tab, savename)

  PopLog("Saving Indexed Table: "..savename);
  local savestring = "";
  
  for key,value in pairs(tab)
  do
  
    -- PopLog("SaveIndexTable key: " ..key, "SaveIndexTable()");
    -- PopLog("SaveIndexTable value: " ..value, "SaveIndexTable()");
    
    savestring = savestring..key..","..value..",;";
    
    PopLog("savestring: "..savestring)
    
  end
  
  cm:save_value(savename, savestring, context);
  
end


-- ***** LOAD INDEX TABLE ***** --

function LoadIndexTable(context, savename)

  -- PopLog("Loading Indexed Table: "..savename);
  
  local savestring = cm:load_value(savename, "", context);
  local tab = {};
  
  if savestring ~= ""
  then
  
    local first_split = SplitString(savestring, ";");
    
    for i = 1, #first_split
    do
    
      -- PopLog("\t\t"..first_split[i]);
      local second_split = SplitString(first_split[i], ",");
      
      tab[tonumber(second_split[1])] = second_split[2];
      
      PopLog("\t\t\t"..savename.."["..second_split[1].."] = "..second_split[2]);
      
    end
  end
  
  return tab;
  
end


-- ***** SPLIT STRING ***** --

function SplitString(str, delim)

  local res = { };
  local pattern = string.format("([^%s]+)%s()", delim, delim);
  
  while (true)
  do
  
    line, pos = str:match(pattern, pos);
    
    if line == nil
    then
      
      break

    end;
  
    table.insert(res, line);
  
  end
  
  return res;
  
end


-- ***** LOAD ARMIES TABLES ***** --

local function loadArmiesTables(context)

  local armyStateKeyList = LoadIndexTable(context, "armyStateKeyList")
  
  for index, armyKey in pairs(armyStateKeyList)
  do
  
    armyState[tostring(armyKey)] = LoadKeyPairTableNew(context, "armyStateKeyList_" .. armyKey)
    
  end
end


-- ***** SAVE ARMIES TABLES ***** --

local function saveArmiesTables(context)

  -- PopLog("Saving Army Tables", "saveArmiesTables()");
  local armyStateKeyList = {}
  
  for key, value in pairs(armyState)
  do
  
    -- PopLog("Saving Army Tables:" ..key, "saveArmiesTables()");
    
    table.insert(armyStateKeyList, tostring(key))
    
    SaveIndexTableNew(context, armyState[key], "armyStateKeyList_" .. tostring(key))
  end
  
  SaveIndexTable(context, armyStateKeyList, "armyStateKeyList")
  
end


-- ***** REGISTERING CALLBACKS ***** --

cm:register_loading_game_callback(loadArmiesTables)
cm:register_saving_game_callback(saveArmiesTables)


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- GAME MECHANIC EVENT FUNCTIONS  ---------------------------------------------------------------------

--OnRegionTurnStartPop
--OnCharacterTurnStartPop
--OnCharacterTurnEndPop
--OnCharacterLootedSettlementPop
--OnGarrisonOccupiedEventPop
--OnTimeTriggerPop
--SetRegionOccupied
--OnFactionTurnStartPop1
--OnFactionTurnEndPop

-- #####-------------------------


-- ***** ON REGION TURN START POP ***** --
  -- function does all the leg work for region growth outside of loss of pop due to recruitment

local function OnRegionTurnStartPop(context)
  PopLog("Region turn started: "  .. context:region():name(), "OnRegionTurnStartPop()")
  RegionPopGrowth(context:region()) 
end

-- ***** ON CHARACTER TURN START POP ***** --
local function OnCharacterTurnStartPop(context)
PopLog("Region bundle: "  .. context:character():region():name(), "OnCharacterTurnStartPop()")
  -- Character Functions   
  -- Enemy Region
  local character = context:character()
  local factionName = character:faction():name()  
  local characterRegion = character:region():name()
  local characterRegionFaction = character:region():owning_faction():name()
  local attitude = scripting.game_interface:model():campaign_ai():strategic_stance_between_factions(characterRegionFaction, factionName)

  -- Foreign region 
  -- ENEMIES_PRESENT
  if (characterRegionFaction ~= factionName)
  and attitude < 1 -- IF NEUTRAL OR WORSE
 then
-- change foreign army flag to true for the region
 region_flag[character:region():name()][ENEMIES_PRESENT] = true
end
  
  -- check if character has garrison residence
 local RegionCqi = 0 

  if context:character():has_garrison_residence()
  and context:character():character_type("colonel")
  then RegionCqi = context:character():cqi()
  PopLog("Region bundle: noch da? " , "OnCharacterTurnStartPop()")
    -- check no current effect bundle active in region
    
   if rom_region_flag[characterRegion][5] == 0
    then 
      -- RemoveRegionBundle(cqi)
      ApplyRegionBundle(context:character():region(), RegionCqi)
      rom_region_flag[characterRegion][5] = cqi
      PopLog("Garrison Bundle Applied Correctly", "OnCharacterTurnStartPop()")
    end  
  else
    PopLog("Character not garrison residence", "OnCharacterTurnStartPop()")
  end
end


-- ***** ON CHARACTER TURN END POP ***** --
-- probably not neccesary
local function OnCharacterTurnEndPop(context)
  -- region effect garbage collection incase effect applied to an army instead of a garrison
  character = context:character()
  
  if character:character_type("general")
  then local cqi = character:cqi()
    RemoveRegionBundle(cqi)
  end
end


-- ***** ON CHARACTER LOOTED SETTLEMENT POP ***** --
local function OnCharacterLootedSettlementPop(context)

  local character = context:character()
  local regionName = character:region():name()
  region_flag[regionName][SETTLEMENT_LOOTED] = true 
end


-- ***** ON GARRISON OCCUPIED EVENT POP ***** --

local function OnGarrisonOccupiedEventPop(context)

  local text = -1
  local faction = "noFaction"

  text = context:character():cqi()
  tempCqi = text

  faction = context:character():faction()
  tempFaction = faction
    
  scripting.game_interface:add_time_trigger("garrison_occupied", 0.01)
  
  PopLog("Region Occupied end: " .. regionName, "OnGarrisonOccupiedEvent()")
  
end


-- ***** ON GARRISON OCCUPIED EVENT POP ***** --

local function OnTimeTriggerPop(context) 

  local message = context.string
  
  if ( message == "garrison_occupied")
  and population_modifier["foreigner_mechanic_on"] == true
  then
  
    SetRegionOccupied()
    
  end 
end
  

-- ***** SET REGION OCCUPIED ***** --
-- added culture check to region, if culture matches we will change pop differently
-- DeI: also removed faction capital check, was causing issues and made function not work in Mac Wars

function SetRegionOccupied()

  PopLog("SetRegionOccupied()")
  
  local faction = tempFaction
  local regionName = "no name"
  local factionCulture = faction:state_religion()
  
  PopLog("factionCulture: "..factionCulture)
  
  for i = 0, faction:character_list():num_items() - 1
  do
  
    if (faction:character_list():item_at(i):cqi() == tempCqi)
    then
    
      PopLog("faction:character_list():item_at(i):cqi(): "..faction:character_list():item_at(i):cqi())  
      
      regionName = faction:character_list():item_at(i):garrison_residence():region():name()
      
      local regionCulture = faction:character_list():item_at(i):garrison_residence():region():majority_religion()
      
      PopLog("regionCulture: "..tostring(regionCulture)) 
      
      if region_flag[regionName][SETTLEMENT_LOOTED] == true
      then  
      
        -- If region looted/raze, less population
        if factionCulture == regionCulture
        then
        
          PopLog("razed/looted region capture with majority culture".. regionName, "SetRegionOccupied")
          region_table[regionName][4] = math.ceil((region_table[regionName][1] + region_table[regionName][2] + region_table[regionName][3] + region_table[regionName][4])/4)
          region_table[regionName][1] = math.ceil(region_table[regionName][1]/4)
          region_table[regionName][2] = math.ceil(region_table[regionName][2]/4)
          region_table[regionName][3] = math.ceil(region_table[regionName][3]/4)
         
          -- update UIPopulation
          UIPopulation[regionName][1] = region_table[regionName][1]
          UIPopulation[regionName][2] = region_table[regionName][2]
          UIPopulation[regionName][3] = region_table[regionName][3]
          UIPopulation[regionName][4] = region_table[regionName][4]
          
          return
          
        else 
        
          -- if regionName = faction:character_list():item_at(i):garrison_residence():region():name()
        
          region_table[regionName][4] = math.ceil((region_table[regionName][1] + region_table[regionName][2] + region_table[regionName][3] + region_table[regionName][4])/2)
          region_table[regionName][1] = 1
          region_table[regionName][2] = 1
          region_table[regionName][3] = 1
          -- update UIPopulation
          UIPopulation[regionName][1] = region_table[regionName][1]
          UIPopulation[regionName][2] = region_table[regionName][2]
          UIPopulation[regionName][3] = region_table[regionName][3]
          UIPopulation[regionName][4] = region_table[regionName][4]
          
          PopLog("razed/looted region capture without majority culture".. regionName, "SetRegionOccupied")
          
          return
          
        end
        
      else
      
        region_flag[regionName][SETTLEMENT_OCCUPIED] = true
        
        if factionCulture == regionCulture
        then
        
          -- normal region capture
          
          PopLog("normal region capture with majority culture".. regionName, "SetRegionOccupied")
          region_table[regionName][1] = math.ceil(region_table[regionName][1]/2)
          region_table[regionName][2] = math.ceil(region_table[regionName][2]/2)
          region_table[regionName][3] = math.ceil(region_table[regionName][3]/2)
          region_table[regionName][4] = region_table[regionName][1] + region_table[regionName][2] + region_table[regionName][3] + region_table[regionName][4]
          
          -- update UIPopulation
          
          UIPopulation[regionName][1] = region_table[regionName][1]
          UIPopulation[regionName][2] = region_table[regionName][2]
          UIPopulation[regionName][3] = region_table[regionName][3]
          UIPopulation[regionName][4] = region_table[regionName][4]
          
          return
        
        else
        
          --if regionName = faction:character_list():item_at(i):garrison_residence():region():name()
      
          region_table[regionName][4] = region_table[regionName][1] + region_table[regionName][2] + region_table[regionName][3] + region_table[regionName][4]
          region_table[regionName][1] = 10
          region_table[regionName][2] = 20
          region_table[regionName][3] = 40
          
          -- update UIPopulation
          
          UIPopulation[regionName][1] = region_table[regionName][1]
          UIPopulation[regionName][2] = region_table[regionName][2]
          UIPopulation[regionName][3] = region_table[regionName][3]
          UIPopulation[regionName][4] = region_table[regionName][4]
        
          PopLog("normal region capture without majority culture".. regionName, "SetRegionOccupied")
        
          return
        
        end
      end 
    end
  end
  
  PopLog("Garrison Not Occupied pre name check".. regionName, "SetRegionOccupied")
  
end


-- ***** ON FACTION TURN START POP ***** --
-- add public order bundle fationwide based on proportion of foreign to citizens

function OnFactionTurnStartPop(context)

  local up = 0
  local mid = 0
  local low = 0
  local foreign = 0
  
  for region = 0, context:faction():region_list():num_items() - 1
  do
  
    local regionName = context:faction():region_list():item_at(region):name()
    
    up = up + region_table[regionName][1]
    mid = mid + region_table[regionName][2]
    low = low + region_table[regionName][3]
    foreign = foreign + region_table[regionName][4]
    
  end

  local totalPop = up + mid + low + foreign
  local factionForeignRatio = foreign / totalPop
  local factionName = context:faction():name()

  -- remove existing effect bundle
  for i =1, 5
  do
    
    scripting.game_interface:remove_effect_bundle(faction_foreigner_bundle[i], factionName)
  
  end

  -- add new effect bundle
  -- scripting.game_interface:apply_effect_bundle(faction_foreigner_bundle[1], factionName, -1)
  -- PopLog("Faction bundle to be applied" .. faction_foreigner_bundle[1], "OnFactionTurnStartPop")
  
  if (factionForeignRatio > 0.9)
  then
  
    scripting.game_interface:apply_effect_bundle(faction_foreigner_bundle[1], factionName, 0)
    
    PopLog("Faction bundle applied".. faction_foreigner_bundle[1], "OnFactionTurnStartPop")
    
  elseif (factionForeignRatio > 0.8)
  then
  
    scripting.game_interface:apply_effect_bundle(faction_foreigner_bundle[2], factionName, 0)
    
    PopLog("Faction bundle applied".. faction_foreigner_bundle[2], "OnFactionTurnStartPop")
    
  elseif (factionForeignRatio > 0.7)
  then
  
    scripting.game_interface:apply_effect_bundle(faction_foreigner_bundle[3], factionName, 0)
    
    PopLog("Faction bundle applied".. faction_foreigner_bundle[3], "OnFactionTurnStartPop")
    
  elseif (factionForeignRatio > 0.6)
  then
  
    scripting.game_interface:apply_effect_bundle(faction_foreigner_bundle[4], factionName, 0)
    
    PopLog("Faction bundle applied".. faction_foreigner_bundle[4], "OnFactionTurnStartPop")
    
  elseif (factionForeignRatio > 0.5)
  then
  
    scripting.game_interface:apply_effect_bundle(faction_foreigner_bundle[5], factionName, 0)
    
    PopLog("Faction bundle applied".. faction_foreigner_bundle[5], "OnFactionTurnStartPop")
    
  end
end


-- ***** ON FACTION TURN END POP ***** --

function OnFactionTurnEndPop(context)

  -- do immigration movements
  FactionImmigration(context:faction())
  
end


-- ***** ON CHARACTER COMPLETED BATTLE POP ***** --

function OnCharacterCompletedBattlePop(context)

  local regionName = context:character():region():name()
  
  -- set region battle flag
  region_flag[regionName][BATTLE_FOUGHT] = true 
  
end


-- ***** ON REGION TURN END POP ***** --

function OnRegionTurnEndPop(context)

  -- reset desire values before turn end
  local regionName = context:region():name()
  
  for i = 1, 8
  do 
  
    region_desire[regionName][i] = 0
    
  end
  
  --reset region cqi in region_flag table
  rom_region_flag[regionName][5] = 0
  
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- CALLBACKS  ---------------------------------------------------------------------
-- #####-------------------------


scripting.AddEventCallBack("WorldCreated", OnWorldCreatedPop) 
scripting.AddEventCallBack("SavingGame", OnSavingGamePop)
scripting.AddEventCallBack("LoadingGame", OnLoadingGamePop)   
scripting.AddEventCallBack("RegionTurnStart", OnRegionTurnStartPop)   
scripting.AddEventCallBack("CharacterTurnStart", OnCharacterTurnStartPop) 
scripting.AddEventCallBack("CharacterLootedSettlement", OnCharacterLootedSettlementPop)   
scripting.AddEventCallBack("GarrisonOccupiedEvent", OnGarrisonOccupiedEventPop)   
scripting.AddEventCallBack("TimeTrigger", OnTimeTriggerPop)   
scripting.AddEventCallBack("FactionTurnStart", OnFactionTurnStartPop)
--scripting.AddEventCallBack("FactionTurnEnd", OnFactionTurnEndPop)
scripting.AddEventCallBack("CharacterCompletedBattle", OnCharacterCompletedBattlePop)
--scripting.AddEventCallBack("RegionTurnEnd", OnRegionTurnEndPop)
-- scripting.AddEventCallBack("CharacterTurnEnd", OnCharacterTurnEndPop)

-- A huge thanks and credits to Causeless for letting me use his army state manager for the multiplayer component.
-- Some parts are altered for Rome 2, his script header is added to the all his code parts
-- changes to his scripts are commented


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- REC LISTENER SP DYNAMIC TABLES  ---------------------------------------------------------------------
-- #####-------------------------


-- save and load tables
recruitmentOrders = {} -- Stores the recruitment orders per character, so that we can give population back if an order is cancelled [SAVE!!!!]
army_size_cqi = {} -- Stores region and Army Size of every CQI
----------
-- other dynamic variables
current_character = nil -- Stores current character, so the UI callback knows which character's UI is open
disband_unit_table = {} -- Stores unit key before and after selecting an army, so we know if units got disbanded
----------
-- Mercs and Levies -- tables used for UI recruitment of levies and mercs, not compatible with MP, for MP we need to listen for the unit created callback and do checks a tick after with faction char list
char_merc_levy_units = {} -- stores unit key before recruiting mercs or levies
ui_merc_levy_region_table = {0,0,0,0} -- stores "fake" UI values
Merc_Levy_recruitmentOrders = {} -- Stores the recruitment orders per character
----------
-- Rebel System - problem is rebels don't have a faction turn start event so we have to do it all character based
rebel_cqi = {} -- rebel_cqi = {[ciq] = {[i] = unit key}}}  --  rebel_cqi[tostring(cqi)][i] = unit_key
rebel_army_size = {} --rebel_army_size = {[cqi] = army size} -- rebel_army_size[tostring(cqi)] = force:unit_list():num_items()
---------
-- AI tables
AI_recruitment_table = {} -- no save needed populated on char turn start, checked on faction turn start against possible new units
armyState = {} -- Tracks armies state, so if there's a change between the current army and this we know there was a change [SAVE!!!!]
-----------
-- UI pop table
UIPopulation = {}
-- on pending battle
army_cqi_attacker = 0
army_cqi_defender = 0


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- VARIOUS  ---------------------------------------------------------------------
-- #####-------------------------


-- ***** LOG ***** --

function Log(text, isTitle, isNew)

    if not isLogAllowed
  then
  
    return;
    
    end

  local logfile;
  text = tostring(text);
  
  if isNew
  then
  
    logfile = io.open("PoR2_MP_log.txt","w");
    
    local text = tostring("- Multiplayer Log\n");
    
    logfile:write(text.."\n\n");
    
  else
  
    logfile = io.open("PoR2_MP_log.txt","a");
    
    if not logfile
    then

      logfile = io.open("PoR2_MP_log.txt","w")

    end
  end

  if isTitle
  then
  
    local title_text = "#######################################################\n";
    
    text = "\n"..title_text..text.."\n"..title_text;
    
  end

  logfile:write(text.."\n");
  logfile:close();
  
end


-- ***** MPLOGPOP ***** --

local function MPLogPop(context)

  if not isLogAllowed
  then
  
    return;
    
    end

  local regionName = context:garrison_residence():region():name()
  local UItotalpop = 0
  
  for i = 1, 4
  do
  
    UItotalpop = UIPopulation[regionName][i] + UItotalpop
    
  end

  Log("Total UI Population for: "..regionName.. " = "..UItotalpop)
  Log("UI Noble Class: "..UIPopulation[regionName][1])
  Log("UI Citizen Class: "..UIPopulation[regionName][2])
  Log("UI Poor Class: "..UIPopulation[regionName][3])
  Log("UI Foreign Class: "..UIPopulation[regionName][4])

  local totalpop = 0
  
  for i = 1, 4
  do
  
    totalpop = region_table[regionName][i] + totalpop
    
  end

  Log("Total real Population for: "..regionName.. " = "..totalpop)
  Log("real Noble Class: "..region_table[regionName][1])
  Log("real Citizen Class: "..region_table[regionName][2])
  Log("real Poor Class: "..region_table[regionName][3])
  Log("real Foreign Class: "..region_table[regionName][4])
  
end


-- ***** SHOW POP MESSAGE START ***** --
-- Manpower System Start Message

local function ShowPopMessageStart(context)

  local turn = GetTurn()
  
  if context:faction():is_human() == true 
  and turn == 1
    then
  
    scripting.game_interface:show_message_event("custom_event_900", 0, 0);
    
  end
end


-- ***** UI FACTION TURN END ***** --

local function UIFactionTurnEnd(context)

  current_character = nil
  
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- FUNCTIONS  ---------------------------------------------------------------------

-- UIProvinceFromRegionname
-- isLocalFaction
-- TableisEmpty
-- UICommaValue
-- UIGetLocalFaction
-- UIGetLocalFactionName
-- UIGetComponent
-- UIDeleteComponent
-- UIHideComponent
-- UIRetrievetotalpopulation
-- UIChangeComponent_province_dev_points
-- UIChangeOnTimeTrigger
-- UIChangeComponent_dy_command
-- UIChangeComponent_dy_subterfuge
-- UIChangeComponent_dy_zeal
-- UIChangeComponent_profile
-- UIChangeComponent_dy_prosperity
-- UIChangeComponent_tx_prosperity
-- UIisComponentActive
-- UIRetrieveFactionPop
-- UIGetPopNames
-- UIChangeProvinceDetailsOnTimeTrigger
-- UIFactionNameToClassName
-- UIGarrisonFactionNameToClass
-- UIRetrievePopulationClasses
-- UIRetrieveClass
-- UIDisplayClass
-- UIRetrieveunitcosts
-- UIGetClassManpower
-- UIGetMercClassManpower
-- UIFormatValuesBehindComma
-- UIOnBuildingCardSelected
-- UIGrowthTooltip
-- UIRegionPopGrowth
-- UIGetImmigration
-- UIRegionEffects
-- UIDevPoinsIconTooltip
-- UIGetProvincePop

-- #####-------------------------


-- ***** DISTANCE 2D ***** --

function distance_2D(ax, ay, bx, by)

  return ((bx - ax) ^ 2 + (by - ay) ^ 2) ^ 0.5
  
end


-- ***** REGION HAS PORT ***** --

function regionHasPort(region)

  PopLog("Start regionHasPort()")
  
  for building_name = 0, region:slot_list():num_items() - 1
  do
  
    local slot = region:slot_list():item_at(building_name);
    
        if slot:has_building() 
        and Contains(PortBuildingsList, slot:building():name())   
    then 
    
      PopLog("Slot contains building regionHasPort()")
      
      return true;
    
        end;
    
  end
  
  PopLog("No Port found regionHasPort()");
  
  return false;
  
end;


-- ***** GET CLOSEST PORT REGION ***** --

function getClosestPortRegion(xChar, yChar, faction)

  local regionName = "";
  local distance = 9999999999999999; 
  local factions_regions = faction:region_list();

  for i = 0, factions_regions:num_items() - 1
  do
  
    local region = factions_regions:item_at(i);
    
    PopLog("getClosestPortRegion: "..region:name())
    
    -- add check if region has building port list needed
    if regionHasPort(region)
    then 
    
      local xPort = region:settlement():logical_position_x()
      local yPort = region:settlement():logical_position_y() 
      local newDistance = distance_2D(xPort, yPort, xChar, yChar)
      
      PopLog("getClosestPortRegion: "..tostring(newDistance))
      
      if newDistance ~= 0
      and newDistance < distance
      then
      
        distance = newDistance
        regionName = region:name()
        
        PopLog("getClosestPortRegion: new Region: "..regionName)
        
      end;
    end;
  end;
  
  if regionName == ""
  then 
  
    regionName = faction:home_region():name()

  end; -- fallback to capital
  
  return regionName;
   
end;


-- Litharion:
-- requires patch 18

-- ***** GET CLOSEST PORT REGION ***** --
-- region_by_name:province_name()

function UIProvinceFromRegionname(regionname)

  local region_by_name = scripting.game_interface:model():world():region_manager():region_by_key(regionname)
  local region_province_name = region_by_name:province_name()
  
  return region_province_name
  
end


-- ***** IS LOCAL FACTION ***** --
-- function used to get the local faction true/false return from a faction name input 

function isLocalFaction(faction_name)

  faction_name = (type(faction_name) == "string"
  and faction_name)
  or ((type(faction_name) == "userdata"
  and faction_name:name())
  or nil);
  
  if not faction_name
  then 
  
    return false

  end;

  return scripting.game_interface:model():faction_is_local(faction_name);
  
end


-- ***** TABLE IS EMPTY ***** --
-- function used to get empty tables

function TableisEmpty(table)
  local number = 0

    for k, v in pairs(table)
  do
  
    number = number + 1
    
  end

  if number == 0
  then
  
    return true
    
  else

    return false
    
  end     
end


-- ***** UI COMMA VALUE ***** --
-- format function, add comma value 00,000,00 used for all bigger population values

function UICommaValue(number)

  local formatted = number
  
  while true
  do  
  
    formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
    
    if (k==0)
    then
    
      break
      
    end
  end
  
  return formatted
  
end


-- ***** UI GET LOCAL FACTION ***** --
-- function to actually get the local faction
-- beware in MP it will return 2 different factions, if it is player 1/2 turn
-- best used to do UI based stuff like class names

function UIGetLocalFaction()

  local model = scripting.game_interface:model();
  local factions_list = model:world():faction_list();
  
  for i = 0, factions_list:num_items() - 1
  do
  
    local faction = factions_list:item_at(i);
    local faction_name = factions_list:item_at(i):name();

    if model:faction_is_local(faction_name)
    then
    
      return faction
    
    end
  end
end


-- ***** UI GET LOCAL FACTION NAME ***** --
-- simply returns the faction name and not the scripting interface
-- same MP "issue"

function UIGetLocalFactionName()

  local model = scripting.game_interface:model();
  local factions_list = model:world():faction_list();
  
  for i = 0, factions_list:num_items() - 1
  do
  
    local faction_name = factions_list:item_at(i):name();

    if model:faction_is_local(faction_name)
    then
    
      return faction_name
      
    end
  end
end


-- ***** UI GET LOCAL FACTION NAME ***** --
-- gets any UI Component in the game
  
function UIGetComponent(...)

  local component;
  
  for arg_num, arg_value in ipairs(arg)
  do
    
    if (type(arg_value) == "userdata") and (arg_num == 1)
    then
    
      component = arg_value;
      
    elseif (type(arg_value) ~= "string")
    then
    
      return nil;
      
    elseif (arg_num == 1)
    then
    
      component = scripting.m_root:Find(arg_value);
      
    else
    
      component = UIComponent(component):Find(arg_value);
  
    end

    if not component
    then
      
      return nil
    
    end;
  end

  return component;

end


-- ***** UI DELETE COMPONENT ***** --
-- deletes UI components

function UIDeleteComponent(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
    
  end;
  
  local component_parent = UIComponent(component):Parent();
  
  UIComponent(component):SetDisabled(true);
  UIComponent(component_parent):Divorce(component);
  
  return true;
  
end


-- ***** UI HIDE COMPONENT ***** --
-- hides UI components

function UIHideComponent(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
    
  end;
  
  UIComponent(component):SetVisible(false);
  return true;
  
end


-- ***** UI RETRIEVE TOTAL POPULATION ***** --
-- retrieve total population of the local last selected region

function UIRetrievetotalpopulation()

  local region = UI_data_table.curr_region_name
  
  UI_data_table.total_pop = 0

  for i = 1, 4
  do
  
    UI_data_table.total_pop = UIPopulation[region][i] + UI_data_table.total_pop 
    
  end
end


-- ***** UI CHANGE COMPONENT PROVINCE DEV POINTS ***** --
-- retrieve total population of the local last selected region
-- change province_dev_points to total population value for the selected region! 

function UIChangeComponent_province_dev_points(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return

  end;

  local provinceName = UIProvinceFromRegionname(UI_data_table.curr_region_name)
  
  PopLog("provinceName:   "..provinceName)
  
  if province_name_table[provinceName][1] == false
  then
  
    province_name_table[provinceName][2] = UIComponent(component):GetStateText()
    
    PopLog("province_name_table[provinceName][2]:   "..province_name_table[provinceName][2])   
    
    province_name_table[provinceName][1] = true 
    
  end

  local population = UICommaValue(UI_data_table.total_pop)
  local text = population
  
  if UI_data_table.total_growth > 0.001
  then 
    
    text = text .. UI_data_table.col_green_open .. " (+)" ..UI_data_table.col_green_close
    
    UIComponent(component):SetStateText(text)
  
  elseif UI_data_table.total_growth < -0.001 
  then
    
    text = text .. UI_data_table.col_red_open .. " (-)" ..UI_data_table.col_red_close
  
    UIComponent(component):SetStateText(text)
  
  else

    text = text .. UI_data_table.col_yellow_open .. " (/)" ..UI_data_table.col_yellow_close
  
    UIComponent(component):SetStateText(text)
  
  end
end


-- ***** UI CHANGE ON TIME TRIGGER ***** --
-- change province_dev_points to total population value for the selected region! 

function UIChangeOnTimeTrigger(context)

  UIRegionPopGrowth() 
  UIChangeComponent_province_dev_points("TEXT_SXA1_Popu_0001")
  
end


-- ***** UI MOVE COMPONENT DY COMMAND ***** --
-- change pop values in the province detail panel 
-- we use the 3 different Agent icons for it

function UIMoveComponent_dy_command(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
    
  end;
  
  local text = UIComponent(component):GetTooltipText()
  
  if string.find(text, "First Class")
  or string.find(text, "Your")
  then 
  
    Debug("Move dy_command")
    
    local moveCompA = UIComponent(scripting.m_root:Find("dy_command"));
    
    Debug("moveCompA icon found: "..tostring(moveCompA));
    
    moveCompA:SetMoveable(true);
    
    local moveCompA_pX, moveCompA_pY = moveCompA:Position();
    
    Debug("moveCompA_pX: "..tostring(moveCompA_pX).." moveCompA_pY: "..tostring(moveCompA_pY));
    
    local XA = moveCompA_pX - 25;
    
    moveCompA:MoveTo(XA , moveCompA_pY);
    moveCompA:SetMoveable(false);
    
  end;
  
  return true;
  
end;


-- ***** UI MOVE COMPONENT DY SUBTERFUGE ***** --

function UIMoveComponent_dy_subterfuge(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
    
  end;
  
  local text = UIComponent(component):GetTooltipText()
  
  if string.find(text, "Third Class") or string.find(text, "Your")
  then 
  
    Debug("Move dy_subterfuge")
    
    local moveCompA = UIComponent(scripting.m_root:Find("dy_subterfuge"));
    
    Debug("moveCompA icon found: "..tostring(moveCompA));
    
    moveCompA:SetMoveable(true);
    
    local moveCompA_pX, moveCompA_pY = moveCompA:Position();
    
    Debug("moveCompA_pX: "..tostring(moveCompA_pX).." moveCompA_pY: "..tostring(moveCompA_pY));
    
    local XA = moveCompA_pX - 18;
    
    moveCompA:MoveTo(XA , moveCompA_pY);
    moveCompA:SetMoveable(false);
    
    return true;
    
  end;
end;


-- ***** UI CHANGE COMPONENT DY COMMAND ***** --

function UIChangeComponent_dy_command(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
  
  end;
  
  local text = UIComponent(component):GetTooltipText()
  
  if string.find(text, "First Class") or string.find(text, "Your")
  then
  
    local population = UICommaValue(UI_data_table.pro_noble_pop);
    
    UIComponent(component):SetStateText(population);
    
  end;
  
  return true;
  
end;


-- ***** UI CHANGE COMPONENT DY SUBTERFUGE ***** --

function UIChangeComponent_dy_subterfuge(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
  
  end;
  
  local text = UIComponent(component):GetTooltipText()
  
  if string.find(text, "Third Class") or string.find(text, "Your")
  then 
  
    local population = UICommaValue(UI_data_table.pro_middle_pop)
    
    UIComponent(component):SetStateText(population);
    
    return true;
    
  end;
end;


-- ***** UI CHANGE COMPONENT DY ZEAL ***** --

function UIChangeComponent_dy_zeal(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then 
  
    return false
  
  end;
  
  local population = UICommaValue(UI_data_table.pro_foreign_pop)
  
  UIComponent(component):SetStateText(population);
  
  return true;
  
end;


-- ***** UI CHANGE COMPONENT PROFILE ***** --

function UIChangeComponent_profile(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
    
  end;
  
  UIComponent(component):SetStateText("[[rgba:240:194:0:150]]Province Population[[/rgba:240:194:0:150]]") ---- NEEDS to be translated into another language!!!!!!!!!!
  
  return true;
  
end



-- ***** UI CHANGE COMPONENT DY PROSPERITY ***** --

function UIChangeComponent_dy_prosperity(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
    
  end;
  
  local population = UICommaValue(UI_data_table.faction_population)
  
  UIComponent(component):SetStateText(population)
  
  return true;
  
end


-- ***** UICHANGECOMPONENT TX PROSPERITY ***** --

function UIChangeComponent_tx_prosperity(...)

  local component = UIGetComponent(unpack(arg));
  
  if not component
  then
  
    return false
  
  end;
  
  UIComponent(component):SetStateText("Faction Manpower:")
  
  return true;
  
end


-- ***** UI IS COMPONENT ACTIVE ***** --

function UIisComponentActive(component)

  if (type(component) ~= "userdata")
  then
  
    return false

  end;
  
  return (UIComponent(component):CurrentState() == "active");
  
end


-- ***** UI RETRIEVE FACTION POP ***** --
-- Get the Total Population of the faction
-- we go through the whole region list and display it in the summary

function UIRetrieveFactionPop(context)

  UI_data_table.faction_population = 0
  UI_data_table.faction_population_1 = 0
  UI_data_table.faction_population_2 = 0
  UI_data_table.faction_population_3 = 0
  UI_data_table.faction_population_4 = 0

  local faction = UIGetLocalFaction()
  
  UIGetPopNames()
  
  for i = 0, faction:region_list():num_items() - 1
  do
  
    local region = faction:region_list():item_at(i):name()
    
    for k = 1, 4
    do
    
      UI_data_table.faction_population = UIPopulation[region][k] + UI_data_table.faction_population

      if k == 1
      then
        
        UI_data_table.faction_population_1 = UIPopulation[region][k] + UI_data_table.faction_population_1
      
      end

      if k == 2
      then
        
        UI_data_table.faction_population_2 = UIPopulation[region][k] + UI_data_table.faction_population_2
    
      end

      if k == 3
      then
        
        UI_data_table.faction_population_3 = UIPopulation[region][k] + UI_data_table.faction_population_3
        
      end

      if k == 4
      then
      
        UI_data_table.faction_population_4 = UIPopulation[region][k] + UI_data_table.faction_population_4
        
      end
    end 
  end
  
  UIChangeComponent_dy_prosperity("dy_prosperity")
  UIChangeComponent_tx_prosperity("tx_prosperity")
  
end


-- ***** UI GET POP NAMES ***** --
-- Get Class Names for each faction or default

function UIGetPopNames()

  local faction = UIFactionNameToClassName()
  UI_data_table.noble_pop_name = ui_region_pop_classes[faction][1]
  UI_data_table.mid_pop_name = ui_region_pop_classes[faction][2]
  UI_data_table.low_pop_name = ui_region_pop_classes[faction][3]
  UI_data_table.foreign_pop_name = ui_region_pop_classes[faction][4]
  
end


-- ***** UI MOVE PROVINCE ICONS ON TIME TRIGGER ***** --

function UIMoveProvinceIconsOnTimeTrigger(context)

  if current_character == nil
  then
  
    UIMoveComponent_dy_command("dy_command")
    UIMoveComponent_dy_subterfuge("dy_subterfuge")  
    
  end;
end;


-- ***** UI CHANGE PROVINCE DETAILS ON TIME TRIGGER ***** --
-- actually set the province details

function UIChangeProvinceDetailsOnTimeTrigger(context)

  if current_character == nil
  then
  
    UIChangeComponent_dy_command("dy_command")
    UIChangeComponent_dy_subterfuge("dy_subterfuge")  
    UIChangeComponent_dy_zeal("dy_zeal")
    UIChangeComponent_profile("profile")
    
  end
end


-- ***** UI FACTION NAME TO CLASS NAME ***** --
-- get the local faction's specific class names 

function UIFactionNameToClassName()

  local faction_name = UIGetLocalFactionName()
  
  if ui_faction_unique_name_table[faction_name]
  then 
  
    return ui_faction_unique_name_table[faction_name]
    
  end
  
  return "default"
  
end 


-- ***** UI GARRISON FACTION NAME TO CLASS ***** --
-- get the local faction's class names from the owning faction of the region
-- used for mercs and levies

function UIGarrisonFactionNameToClass(faction)

  if ui_faction_unique_name_table[faction]
  then
  
    return ui_faction_unique_name_table[faction]
    
  end
  
  return "default"
end 


-- ***** UI RETRIEVE POPULATION CLASSES ***** --
-- get regional class based population and store it in the UI_data_table for
-- later use, we set the pop name here as well but for the region instead of army

function UIRetrievePopulationClasses()

  UI_data_table.noble_pop = 0
  UI_data_table.mid_pop  = 0
  UI_data_table.low_pop = 0
  UI_data_table.foreign_pop = 0
  
  local faction = UI_data_table.curr_faction_class_id
  local region = UI_data_table.curr_region_name
  
  for i = 1, 4
  do
  
    if i == 1
    then 
    
      UI_data_table.noble_pop = UIPopulation[region][i]   
      UI_data_table.noble_pop_name = ui_region_pop_classes[faction][i]
      
    end
    
    if i == 2
    then 
    
      UI_data_table.mid_pop  = UIPopulation[region][i]
      UI_data_table.mid_pop_name = ui_region_pop_classes[faction][i]
      
    end
    
    if i == 3 
    then 
    
      UI_data_table.low_pop = UIPopulation[region][i]
      UI_data_table.low_pop_name = ui_region_pop_classes[faction][i]
      
    end
    
    if i == 4
    then 
    
      UI_data_table.foreign_pop = UIPopulation[region][i]
      UI_data_table.foreign_pop_name = ui_region_pop_classes[faction][i]
      
    end             
  end
end


-- ***** UI RETRIEVE CLASS ***** --
-- enter a unit name and the table key (unit_to_pop_table)
-- and it will return the class of any given unit

function UIRetrieveClass(cardKey, factionName)

  if not unit_to_pop_table[cardKey]
  then
  
    return 0

  end

  local class = 0 
  
  -- Litharion
  -- AOR addon for Divide et Impera
  
  if getRecruitableType(cardKey) == "AOR"
  then
  
    class = AOR_GetClass(cardKey, factionName)  
    
  elseif getRecruitableType(cardKey) == "faction" 
  then
  
    class = unit_to_pop_table[cardKey][1]
    
  end

  return class 
  
end


-- ***** UI DISPLAY CLASS ***** --
-- UI table getting the display name of the unit card and the 
-- available manpower display name

function UIDisplayClass(classKey)

  local faction = UI_data_table.curr_faction_class_id
  
  UI_data_table.unit_class_name = ui_unit_classes[faction][classKey]
  UI_data_table.unit_class_name_available = UI_data_table.unit_class_name.." Available: "
  
end


-- ***** GET RECRUITABLE TYPE ***** --
-- Returns a recruitment unitKey type - AOR or faction (normal)
-- works for all unit types, recruited or not not as I already through the right cardKey in

function getRecruitableType(cardKey)

  if string.find(cardKey, "AOR_")
  then
  
    return "AOR" -- If it starts with AOR, it's an AOR unit. These are handled differently
    
  else
  
    return "faction" -- Else it's just a normal recruitable unit
  
  end
end


-- ***** AOR LOCAL CLASS ***** --
-- AOR units are handled by faction key
-- local AOR troops will cost local population if they match the culture 
-- of the owning faction, first we retrieve the index key for the table
-- containing the unit lists

function AOR_LocalClass(faction)

  if not AOR_faction_class_table[faction]
  then 
  
    return "default_AOR"
    
  end

  if AOR_faction_class_table[faction]
  then
  
    return AOR_faction_class_table[faction]
    
    end
end


-- ***** AOR GET CLASS ***** --
-- the table index is now used to loop through the table if the 
-- unit key is in the table local population is used, otherwise
-- class 4 population is default!

function AOR_GetClass(cardKey, factionName)

  local class = 4
  local classKey = AOR_LocalClass(factionName)

  for i, unit in pairs (AOR_units_to_faction_class[classKey])
  do
  
    if unit == cardKey  
    then
    
      class = unit_to_pop_table[cardKey][1]
      
      return class
      
    end
  end
  
  return class
  
end


-- ***** UI RETRIEVE UNIT COSTS ***** --
-- returns the unit costs based on on the class
-- it will currently only support 1 class per unit
-- we will add multiple class support per unit here shortly 

function UIRetrieveunitcosts(cardKey, classKey)

  local set_unit_costs = 0 -- default costs are 0

  if classKey >= 1 and classKey < 5
  then 
  
    set_unit_costs = unit_to_pop_table[cardKey][3]
    
    return set_unit_costs  
    
  else 
  
    return 0

  end
end  


-- ***** UI GET CLASS MANPOWER ***** --
-- manpower class for units NOT region here

function UIGetClassManpower(name, factionName)

  local class = UIRetrieveClass(name, factionName)
  local region = UI_data_table.curr_region_name
  
  return UIPopulation[region][class] 
  
end


-- ***** UI GET CLASS MANPOWER ***** --
-- merc manpower class display 

function UIGetMercClassManpower(class)

  return ui_merc_levy_region_table[class]
  
end


-- ***** UI FORMAT VALUES BEHIND COMMA ***** --
-- used to format comma values in the grwoth tooltip, 
-- will limit floating point numbers to 2

function UIFormatValuesBehindComma(value)

  local newvalue = tostring(value)
  local newvalue_sub = string.sub(newvalue, 1)
  
  newvalue_sub = string.format("%.2f", newvalue_sub*100)
  
  return newvalue_sub
  
end


-- ***** UI REMOVE VALUES BEHIND COMMA ***** --
-- used to format  values in the growth tooltip, 
-- will remove floating point numbers from pop predictions

function UIRemoveValuesBehindComma(value)

  newvalue_sub = math.floor(value*100)
  
  return newvalue_sub
  
end


-- ***** UI ON BUILDING CARD SELECTED ***** --
-- reset the total population after a building is constructed 
-- this is unfortunatley neccesary because the vanilla growth number will be displayed otherwise

local function UIOnBuildingCardSelected(context)

  scripting.game_interface:add_time_trigger("Change_Pop", 0.01)

end


-- ***** UI ON BUILDING CARD SELECTED ***** --

function UIGrowthTooltip(component)

  -- set the tooltip for Growth, we only wanted to display either positive or negative values
  -- this will make reading it easier as all effects that currently are not active will be not shown  
  
  local line = UI_data_table.new_line
  local gr_o = UI_data_table.col_green_open
  local gr_c = UI_data_table.col_green_close
  local r_o = UI_data_table.col_red_open
  local r_c = UI_data_table.col_red_close
  local y_o = UI_data_table.col_yellow_open
  local y_c = UI_data_table.col_yellow_close
  local RegionDisplayName = region_name_table[RegionNameUIPop]
  local noble_name = UI_data_table.noble_pop_name
  local citizens_name = UI_data_table.mid_pop_name
  local poor_name = UI_data_table.low_pop_name
  local foreign_name = UI_data_table.foreign_pop_name   
  local text = "" 
  local min_value = 0.001
  local negative_value = -0.001
  local minimum_growth = 0

  -- display total_growth first
  
  -- Header
  text = y_o.. RegionDisplayName.. y_c.. text.. UI_data_table.total_growth_tx.. line.. line
  
  -- Block
  
  -- set class 1
  local total_noble_growth = UIFormatValuesBehindComma(UI_data_table.total_noble_growth)
  local predicted_noble_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_noble_growth_number)
  
  if UI_data_table.total_noble_growth > min_value
  then
  
    text = text.."I "..noble_name..": "..gr_o.."+"..total_noble_growth.."%".. gr_c.." ("..gr_o.."+"..predicted_noble_growth_number.. gr_c..")"..  line
    
  elseif UI_data_table.total_noble_growth <= negative_value
  then
  
    text = text.."I "..noble_name..": "..r_o..total_noble_growth.."%".. r_c.." ("..r_o..predicted_noble_growth_number.. r_c..")"..  line
    
  else
  
    text = text.."I "..noble_name..": "..y_o..""..total_noble_growth.."%".. y_c.." ("..y_o..""..predicted_noble_growth_number.. y_c..")"..  line
    
  end
  
  -- class 2
  
  local total_citizen_growth = UIFormatValuesBehindComma(UI_data_table.total_citizen_growth)
  local predicted_citizen_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_citizen_growth_number) 
  
  if UI_data_table.total_citizen_growth > min_value
  then
  
    text = text.."II "..citizens_name..": "..gr_o.."+"..total_citizen_growth.."%".. gr_c.." ("..gr_o.."+"..predicted_citizen_growth_number.. gr_c..")".. line
    
  elseif UI_data_table.total_citizen_growth <= negative_value
  then
  
    text = text.."II "..citizens_name..": "..r_o..total_citizen_growth.."%".. r_c.." ("..r_o..predicted_citizen_growth_number.. r_c..")"..  line
    
  else

    text = text.."II "..citizens_name..": "..y_o.."+"..total_citizen_growth.."%".. y_c.." ("..y_o.."+"..predicted_citizen_growth_number.. y_c..")"..  line
  
  end
  
  -- class 3
  
  local total_poor_growth = UIFormatValuesBehindComma(UI_data_table.total_poor_growth)
  local predicted_poor_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_poor_growth_number)  
  
  if UI_data_table.total_poor_growth > min_value
  then
  
    text = text.."III "..poor_name..": "..gr_o.."+"..total_poor_growth.."%".. gr_c.." ("..gr_o.."+"..predicted_poor_growth_number.. gr_c..")".. line
    
  elseif UI_data_table.total_poor_growth <= negative_value
  then
  
    text = text.."III "..poor_name..": "..r_o..total_poor_growth.."%".. r_c.." ("..r_o..predicted_poor_growth_number.. r_c..")"..  line
    
  else
  
    text = text.."III "..poor_name..": "..y_o..""..total_poor_growth.."%".. y_c.." ("..y_o..""..predicted_poor_growth_number.. y_c..")"..  line
  
  end

  -- class 4

  local total_foreign_growth = UIFormatValuesBehindComma(UI_data_table.total_foreign_growth)
  local predicted_foreign_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_foreign_growth_number) 
  
  if UI_data_table.total_foreign_growth > min_value
  then
  
    text = text.."IV "..foreign_name..": "..gr_o.."+"..total_foreign_growth.."%".. gr_c.." ("..gr_o.."+"..predicted_foreign_growth_number.. gr_c..")".. line..line
    
  elseif UI_data_table.total_foreign_growth <= negative_value
  then
  
    text = text.."IV "..foreign_name..": "..r_o..total_foreign_growth.."%".. r_c.." ("..r_o..predicted_foreign_growth_number.. r_c..")"..  line..line
    
  else
  
    text = text.."IV "..foreign_name..": "..y_o..""..total_foreign_growth.."%".. y_c.." ("..y_o..""..predicted_foreign_growth_number.. y_c..")"..  line..line
    
  end

  -- percentage > min_value

  local total_growth_percentage = UIFormatValuesBehindComma(UI_data_table.total_growth_percentage)
  local total_growth = UIRemoveValuesBehindComma(UI_data_table.total_growth) 
  
  if UI_data_table.total_growth_percentage > min_value
  then
  
    text = text..UI_data_table.total_growth_tx_2..gr_o.."+"..total_growth_percentage.."%".. gr_c.." ("..gr_o.."+"..total_growth.. gr_c..")".. line
    
  elseif UI_data_table.total_growth_percentage <= negative_value
  then
  
    text = text..UI_data_table.total_growth_tx_2..r_o..total_growth_percentage.."%".. r_c.." ("..r_o..total_growth.. r_c..")"..  line
    
  else

    text = text..UI_data_table.total_growth_tx_2..y_o..""..total_growth_percentage.."%".. y_c.." ("..y_o..""..total_growth.. y_c..")"..  line
  
  end

  -- military settlers
  
  for i = 1, 4
  do
  
    minimum_growth = minimum_growth + UI_data_table.minimum_growth[i]
    
  end

  if minimum_growth > 0
  then
  
    text = text .. line

  end
  
  if UI_data_table.minimum_growth[1] > 0
  then
  
    text = text .. noble_name..": "..gr_o.."+".. UI_data_table.minimum_growth[1].. gr_c .. " settlers" .. line

  end
  
  if UI_data_table.minimum_growth[2] > 0
  then
  
    text = text .. citizens_name..": "..gr_o.."+".. UI_data_table.minimum_growth[2].. gr_c .. " settlers".. line

  end
  
  if UI_data_table.minimum_growth[3] > 0
  then
  
    text = text .. poor_name..": "..gr_o.."+".. UI_data_table.minimum_growth[3].. gr_c .. " settlers".. line

  end
  
  if UI_data_table.minimum_growth[4] > 0
  then
  
    text = text .. foreign_name..": "..gr_o.."+".. UI_data_table.minimum_growth[4].. gr_c .. " settlers".. line
    
  end

  text = text..UI_data_table.underline
  
  -- now we display details start with base growth, first we always check if the values are high enough to display in the first place
  -- Header, set header first then get all class values
  
  if UI_data_table.total_base_growth > min_value
  or UI_data_table.total_base_growth <= negative_value
  then
  
    text = text..UI_data_table.flavour_tooltip_icon.. UI_data_table.base_growth_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local base_1 = UIFormatValuesBehindComma(UI_data_table.base_growth[1]) 
    
    if UI_data_table.base_growth[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. base_1.."%    "  .. gr_c 
      
    elseif UI_data_table.base_growth[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. base_1.."%    "  ..r_c 
      
    else

      text = text.."I:     ".. y_o .. base_1.."%    "  ..y_c
      
    end
    
    -- class 2    
    
    local base_2 = UIFormatValuesBehindComma(UI_data_table.base_growth[2])
    
    if UI_data_table.base_growth[2] > min_value 
    then 
      
      text = text.."    II:   ".. gr_o .."+".. base_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.base_growth[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. base_2.."%"  ..r_c.. line
      
    else
    
      text = text.."    II:   ".. y_o .. base_2.."%"  ..y_c.. line
      
    end
    
    -- next line    
    -- class 3   
    
    local base_3 = UIFormatValuesBehindComma(UI_data_table.base_growth[3]) 
    
    if UI_data_table.base_growth[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. base_3.."%     " ..gr_c 

    elseif UI_data_table.base_growth[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. base_3.."%     "  ..r_c 
      
    else
    
      text = text.."III:   ".. y_o .. base_3.."%     "  ..y_c
    
    end
    
    -- class 4   
    
    local base_4 = UIFormatValuesBehindComma(UI_data_table.base_growth[4])
    
    if UI_data_table.base_growth[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. base_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.base_growth[4] <= negative_value
    then
      
      text = text.."  IV:   ".. r_o .. base_4.."%"  ..r_c .. line
      
    else
    
      text = text.."  IV:   ".. y_o .. base_4.."%"  ..y_c .. line
      
    end
  end
  
  -- set faction_capital next 
  -- Header, set header first then get all class values
  
  if UI_data_table.total_faction_capital > min_value
  or UI_data_table.total_faction_capital <= negative_value
  then
  
    text = text.. UI_data_table.faction_capital_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local faction_capital_1 = UIFormatValuesBehindComma(UI_data_table.faction_capital[1]) 
    
    if UI_data_table.faction_capital[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. faction_capital_1.."%    "  .. gr_c
      
    elseif UI_data_table.faction_capital[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. faction_capital_1.."%    "  ..r_c 
      
    else

      text = text.."I:     ".. y_o .. faction_capital_1.."%    "  ..y_c
      
    end
    
    -- class 2   
    
    local faction_capital_2 = UIFormatValuesBehindComma(UI_data_table.faction_capital[2]) 
    
    if UI_data_table.faction_capital[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. faction_capital_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.faction_capital[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. faction_capital_2.."%"  ..r_c.. line
      
    else text = text.."    II:   ".. y_o .. faction_capital_2.."%"  ..y_c.. line
    
    end
    
    -- next line
    -- class 3   
    
    local faction_capital_3 = UIFormatValuesBehindComma(UI_data_table.faction_capital[3]) 
    
    if UI_data_table.faction_capital[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. faction_capital_3.."%     " ..gr_c 
      
    elseif UI_data_table.faction_capital[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. faction_capital_3.."%     "  ..r_c 
      
    else 
    
      text = text.."III:   ".. y_o .. faction_capital_3.."%     "  ..y_c
      
    end
    
    -- class 4 
    
    local faction_capital_4 = UIFormatValuesBehindComma(UI_data_table.faction_capital[4])
    
    if UI_data_table.faction_capital[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. faction_capital_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.faction_capital[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. faction_capital_4.."%"  ..r_c .. line
      
    else

      text = text.."  IV:   ".. y_o .. faction_capital_4.."%"  ..y_c .. line
    
    end
  end
  
  -- set province_capital next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_province_capital > min_value or UI_data_table.total_province_capital <= negative_value
  then
  
    text = text.. UI_data_table.province_capital_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local province_capital_1 = UIFormatValuesBehindComma(UI_data_table.province_capital[1]) 
    
    if UI_data_table.province_capital[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. province_capital_1.."%    "  .. gr_c 
      
    elseif UI_data_table.province_capital[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. province_capital_1.."%    "  ..r_c 
    
    else text = text.."I:     ".. y_o .. province_capital_1.."%    "  ..y_c
    
    end
    
    -- class 2   
    
    local province_capital_2 = UIFormatValuesBehindComma(UI_data_table.province_capital[2]) 
    
    if UI_data_table.province_capital[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. province_capital_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.province_capital[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. province_capital_2.."%"  ..r_c.. line
      
    else
    
      text = text.."    II:   ".. y_o .. province_capital_2.."%"  ..y_c.. line
      
    end
    
    -- next line
    -- class 3 
    
    local province_capital_3 = UIFormatValuesBehindComma(UI_data_table.province_capital[3]) 
    
    if UI_data_table.province_capital[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. province_capital_3.."%     " ..gr_c 
      
    elseif UI_data_table.province_capital[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. province_capital_3.."%     "  ..r_c 
      
    else

      text = text.."III:   ".. y_o .. province_capital_3.."%     "  ..y_c
    
    end
    
    -- class 4   
    
    local province_capital_4 = UIFormatValuesBehindComma(UI_data_table.province_capital[4]) 
    
    if UI_data_table.province_capital[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. province_capital_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.province_capital[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. province_capital_4.."%"  ..r_c .. line
      
    else

      text = text.."  IV:   ".. y_o .. province_capital_4.."%"  ..y_c .. line
    
    end
  end
  
  -- set public order next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_public_order > min_value 
  or UI_data_table.total_public_order <= negative_value
  then
  
    text = text.. UI_data_table.public_order_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local public_order_1 = UIFormatValuesBehindComma(UI_data_table.public_order[1]) 
    
    if UI_data_table.public_order[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. public_order_1.."%    "  .. gr_c 
      
    elseif UI_data_table.public_order[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. public_order_1.."%    "  ..r_c 
      
    else text = text.."I:     ".. y_o .. public_order_1.."%    "  ..y_c
    
    end
    
    -- class 2
    
    local public_order_2 = UIFormatValuesBehindComma(UI_data_table.public_order[2]) 
    
    if UI_data_table.public_order[2] > min_value 
    then 
    
      text = text.."    II:   ".. gr_o .."+".. public_order_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.public_order[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. public_order_2.."%"  ..r_c.. line
      
    else

      text = text.."    II:   ".. y_o .. public_order_2.."%"  ..y_c.. line
      
    end
    
    -- next line
    -- class 3
    
    local public_order_3 = UIFormatValuesBehindComma(UI_data_table.public_order[3]) 
    
    if UI_data_table.public_order[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. public_order_3.."%     " ..gr_c 
      
    elseif UI_data_table.public_order[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. public_order_3.."%     "  ..r_c 
      
    else text = text.."III:   ".. y_o .. public_order_3.."%     "  ..y_c
    
    end
    
    -- class 4 
    
    local public_order_4 = UIFormatValuesBehindComma(UI_data_table.public_order[4]) 
    
    if UI_data_table.public_order[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. public_order_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.public_order[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. public_order_4.."%"  ..r_c .. line
      
    else text = text.."  IV:   ".. y_o .. public_order_4.."%"  ..y_c .. line
    
    end
  end
  
  -- set food next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_food > min_value
  or UI_data_table.total_food <= negative_value
  then
  
    text = text.. UI_data_table.food_tx..line
    
  --Block

  -- start line 1 class 1
  
    local food_1 = UIFormatValuesBehindComma(UI_data_table.food[1]) 
    
    if UI_data_table.food[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. food_1.."%    "  .. gr_c 
      
    elseif UI_data_table.food[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. food_1.."%    "  ..r_c 
      
    else
    
      text = text.."I:     ".. y_o .. food_1.."%    "  ..y_c
      
    end
    
    -- class 2   
    
    local food_2 = UIFormatValuesBehindComma(UI_data_table.food[2]) 
    
    if UI_data_table.food[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. food_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.food[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. food_2.."%"  ..r_c.. line
      
    else
    
      text = text.."    II:   ".. y_o .. food_2.."%"  ..y_c.. line
      
    end
    
    -- next line
    -- class 3  
    
    local food_3 = UIFormatValuesBehindComma(UI_data_table.food[3]) 
    
    if UI_data_table.food[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. food_3.."%     " ..gr_c 
      
    elseif UI_data_table.food[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. food_3.."%     "  ..r_c 
      
    else
    
      text = text.."III:   ".. y_o .. food_3.."%     "  ..y_c
    
    end
    
    -- class 4 
    
    local food_4 = UIFormatValuesBehindComma(UI_data_table.food[4]) 
    
    if UI_data_table.food[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. food_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.food[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. food_4.."%"  ..r_c .. line
      
    else
    
      text = text.."  IV:   ".. y_o .. food_4.."%"  ..y_c .. line
      
    end
  end
  
  -- set taxation next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_taxation > min_value
  or UI_data_table.total_taxation <= negative_value
  then
  
    text = text.. UI_data_table.taxation_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local taxation_1 = UIFormatValuesBehindComma(UI_data_table.taxation[1]) 
    
    if UI_data_table.taxation[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. taxation_1.."%    "  .. gr_c 
      
    elseif UI_data_table.taxation[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. taxation_1.."%    "  ..r_c 
      
    else

      text = text.."I:     ".. y_o .. taxation_1.."%    "  ..y_c
    
    end
    
    -- class 2    
    
    local taxation_2 = UIFormatValuesBehindComma(UI_data_table.taxation[2]) 
    
    if UI_data_table.taxation[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. taxation_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.taxation[2] <= negative_value 
    then
    
      text = text.."    II:   ".. r_o .. taxation_2.."%"  ..r_c.. line
      
    else 
    
      text = text.."    II:   ".. y_o .. taxation_2.."%"  ..y_c.. line
      
    end
    
    -- next line
    
    -- class 3  
    
    local taxation_3 = UIFormatValuesBehindComma(UI_data_table.taxation[3]) 
    
    if UI_data_table.taxation[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. taxation_3.."%     " ..gr_c 
      
    elseif UI_data_table.taxation[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. taxation_3.."%     "  ..r_c 
      
    else
    
      text = text.."III:   ".. y_o .. taxation_3.."%     "  ..y_c
      
    end
    
    -- class 4 
      
    local taxation_4 = UIFormatValuesBehindComma(UI_data_table.taxation[4]) 
    
    if UI_data_table.taxation[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. taxation_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.taxation[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. taxation_4.."%"  ..r_c .. line
      
    else text = text.."  IV:   ".. y_o .. taxation_4.."%"  ..y_c .. line
    
    end
  end
  
  -- set culture_bonuses next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_culture_bonuses > min_value
  or UI_data_table.total_culture_bonuses <= negative_value
  then
  
    text = text.. UI_data_table.culture_bonuses_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local culture_bonuses_1 = UIFormatValuesBehindComma(UI_data_table.culture_bonuses[1]) 
  
    if UI_data_table.culture_bonuses[1] > min_value
    then  
  
    text = text.."I:     ".. gr_o .."+".. culture_bonuses_1.."%    "  .. gr_c 
    
    elseif UI_data_table.culture_bonuses[1] <= negative_value
    then
  
      text = text.."I:     ".. r_o .. culture_bonuses_1.."%    "  ..r_c 
    
    else
  
      text = text.."I:     ".. y_o .. culture_bonuses_1.."%    "  ..y_c
    
    end
    
    -- class 2  
    
    local culture_bonuses_2 = UIFormatValuesBehindComma(UI_data_table.culture_bonuses[2]) 
    
    if UI_data_table.culture_bonuses[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. culture_bonuses_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.culture_bonuses[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. culture_bonuses_2.."%"  ..r_c.. line
      
    else 
    
      text = text.."    II:   ".. y_o .. culture_bonuses_2.."%"  ..y_c.. line
      
    end
    
    -- next line
    -- class 3    
    
    local culture_bonuses_3 = UIFormatValuesBehindComma(UI_data_table.culture_bonuses[3]) 
    
    if UI_data_table.culture_bonuses[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. culture_bonuses_3.."%     " ..gr_c 
      
    elseif UI_data_table.culture_bonuses[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. culture_bonuses_3.."%     "  ..r_c 
      
    else text = text.."III:   ".. y_o .. culture_bonuses_3.."%     "  ..y_c
    
    end
    
    -- class 4  
      
    local culture_bonuses_4 = UIFormatValuesBehindComma(UI_data_table.culture_bonuses[4]) 
    
    if UI_data_table.culture_bonuses[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. culture_bonuses_4.."%"  .. gr_c .. line
    
    elseif UI_data_table.culture_bonuses[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. culture_bonuses_4.."%"  ..r_c .. line
      
    else

      text = text.."  IV:   ".. y_o .. culture_bonuses_4.."%"  ..y_c .. line
      
    end
  end
  
  -- set majority_religion next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_majority_religion > min_value
  or UI_data_table.total_majority_religion <= negative_value
  then
  
    text = text.. UI_data_table.majority_religion_tx..line
    
    --Block
  
    -- start line 1 class 1
    
    local majority_religion_1 = UIFormatValuesBehindComma(UI_data_table.majority_religion[1]) 
    
    if UI_data_table.majority_religion[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. majority_religion_1.."%    "  .. gr_c 
      
    elseif UI_data_table.majority_religion[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. majority_religion_1.."%    "  ..r_c 
      
    else
    
      text = text.."I:     ".. y_o .. majority_religion_1.."%    "  ..y_c
      
    end
    
    -- class 2 
    
    local majority_religion_2 = UIFormatValuesBehindComma(UI_data_table.majority_religion[2])
    
    if UI_data_table.majority_religion[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. majority_religion_2.."%"  .. gr_c.. line

    elseif UI_data_table.majority_religion[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. majority_religion_2.."%"  ..r_c.. line
      
    else 
    
      text = text.."    II:   ".. y_o .. majority_religion_2.."%"  ..y_c.. line
    
    end
    
    -- next line
    
    -- class 3  
    
    local majority_religion_3 = UIFormatValuesBehindComma(UI_data_table.majority_religion[3]) 
    
    if UI_data_table.majority_religion[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. majority_religion_3.."%     " ..gr_c 
      
    elseif UI_data_table.majority_religion[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. majority_religion_3.."%     "  ..r_c 
      
    else text = text.."III:   ".. y_o .. majority_religion_3.."%     "  ..y_c
    
    end
    
    -- class 4   
      
    local majority_religion_4 = UIFormatValuesBehindComma(UI_data_table.majority_religion[4]) 
    
    if UI_data_table.majority_religion[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. majority_religion_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.majority_religion[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. majority_religion_4.."%"  ..r_c .. line
      
    else
    
      text = text.."  IV:   ".. y_o .. majority_religion_4.."%"  ..y_c .. line
      
    end
  end   
  
  -- set buidlings next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_buidlings > min_value
  or UI_data_table.total_buidlings <= negative_value
  then
  
    text = text.. UI_data_table.buidlings_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local buidlings_1 = UIFormatValuesBehindComma(UI_data_table.buidlings[1]) 
    
    if UI_data_table.buidlings[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. buidlings_1.."%    "  .. gr_c 
      
    elseif UI_data_table.buidlings[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. buidlings_1.."%    "  ..r_c 
      
    else
    
      text = text.."I:     ".. y_o .. buidlings_1.."%    "  ..y_c
    
    end
    
    -- class 2  
       
    local buidlings_2 = UIFormatValuesBehindComma(UI_data_table.buidlings[2]) 
    
    if UI_data_table.buidlings[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. buidlings_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.buidlings[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. buidlings_2.."%"  ..r_c.. line
      
    else 
    
      text = text.."    II:   ".. y_o .. buidlings_2.."%"  ..y_c.. line
      
    end
    
    -- next line
    
    -- class 3  
      
    local buidlings_3 = UIFormatValuesBehindComma(UI_data_table.buidlings[3]) 
    
    if UI_data_table.buidlings[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. buidlings_3.."%     " ..gr_c
      
    elseif UI_data_table.buidlings[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. buidlings_3.."%     "  ..r_c 
      
    else
    
      text = text.."III:   ".. y_o .. buidlings_3.."%     "  ..y_c
    
    end
    
    -- class 4   
        
    local buidlings_4 = UIFormatValuesBehindComma(UI_data_table.buidlings[4]) 
    
    if UI_data_table.buidlings[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. buidlings_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.buidlings[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. buidlings_4.."%"  ..r_c .. line
      
    else
    
      text = text.."  IV:   ".. y_o .. buidlings_4.."%"  ..y_c .. line
    
    end
  end
  
  -- set under_siege next
  -- Header, set header first then get all class values
  
  if UI_data_table.total_under_siege > min_value
  or UI_data_table.total_under_siege <= negative_value
  then
  
    text = text.. UI_data_table.under_siege_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local under_siege_1 = UIFormatValuesBehindComma(UI_data_table.under_siege[1]) 
    
    if UI_data_table.under_siege[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. under_siege_1.."%    "  .. gr_c 
      
    elseif UI_data_table.under_siege[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. under_siege_1.."%    "  ..r_c 
      
    else 
    
      text = text.."I:     ".. y_o .. under_siege_1.."%    "  ..y_c
    
    end
    
    -- class 2  
  
    local under_siege_2 = UIFormatValuesBehindComma(UI_data_table.under_siege[2]) 
    
    if UI_data_table.under_siege[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. under_siege_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.under_siege[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. under_siege_2.."%"  ..r_c.. line
      
    else
    
      text = text.."    II:   ".. y_o .. under_siege_2.."%"  ..y_c.. line
    
    end
    
    -- next line
    
    -- class 3 
    
    local under_siege_3 = UIFormatValuesBehindComma(UI_data_table.under_siege[3]) 
    
    if UI_data_table.under_siege[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. under_siege_3.."%     " ..gr_c 
      
    elseif UI_data_table.under_siege[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. under_siege_3.."%     "  ..r_c 
      
    else
    
      text = text.."III:   ".. y_o .. under_siege_3.."%     "  ..y_c
    
    end
    
    -- class 4 
      
    local under_siege_4 = UIFormatValuesBehindComma(UI_data_table.under_siege[4]) 
    
    if UI_data_table.under_siege[4] > min_value 
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. under_siege_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.under_siege[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. under_siege_4.."%"  ..r_c .. line
      
    else

      text = text.."  IV:   ".. y_o .. under_siege_4.."%"  ..y_c .. line
    
    end
  end
  
  -- set tech

  if UI_data_table.total_technology > min_value
  or UI_data_table.total_technology <= negative_value
  then
  
    text = text.. UI_data_table.technology_tx..line
    
    --Block
    
    -- start line 1 class 1
    
    local tech_1 = UIFormatValuesBehindComma(UI_data_table.technology[1])
    
    if UI_data_table.technology[1] > min_value
    then  
    
      text = text.."I:     ".. gr_o .."+".. tech_1.."%    "  .. gr_c 
      
    elseif UI_data_table.technology[1] <= negative_value
    then
    
      text = text.."I:     ".. r_o .. tech_1.."%    "  ..r_c 
      
    else 
    
      text = text.."I:     ".. y_o .. tech_1.."%    "  ..y_c
    
    end
    
    -- class 2 
    
    local tech_2 = UIFormatValuesBehindComma(UI_data_table.technology[2]) 
    
    if UI_data_table.technology[2] > min_value
    then 
    
      text = text.."    II:   ".. gr_o .."+".. tech_2.."%"  .. gr_c.. line
      
    elseif UI_data_table.technology[2] <= negative_value
    then
    
      text = text.."    II:   ".. r_o .. tech_2.."%"  ..r_c.. line
      
    else text = text.."    II:   ".. y_o .. tech_2.."%"  ..y_c.. line
    
    end
    
    -- next line
    -- class 3 
    
    local tech_3 = UIFormatValuesBehindComma(UI_data_table.technology[3]) 
    
    if UI_data_table.technology[3] > min_value
    then 
    
      text = text.."III:   ".. gr_o .."+".. tech_3.."%     " ..gr_c 
      
    elseif UI_data_table.technology[3] <= negative_value
    then
    
      text = text.."III:   ".. r_o .. tech_3.."%     "  ..r_c 
      
    else
    
      text = text.."III:   ".. y_o .. tech_3.."%     "  ..y_c
    
    end
    
    -- class 4  
    
    local tech_4 = UIFormatValuesBehindComma(UI_data_table.technology[4]) 
    
    if UI_data_table.technology[4] > min_value
    then 
    
      text = text.."  IV:   ".. gr_o .."+".. tech_4.."%"  .. gr_c .. line
      
    elseif UI_data_table.technology[4] <= negative_value
    then
    
      text = text.."  IV:   ".. r_o .. tech_4.."%"  ..r_c .. line
      
    else
    
      text = text.."  IV:   ".. y_o .. tech_4.."%"  ..y_c .. line
      
    end
  end
  
--  local provinceName = UIProvinceFromRegionname(UI_data_table.curr_region_name)
  
--  text = text..line..UI_data_table.Dev_points_tx..gr_o.. province_name_table[provinceName][2] .. gr_c ---- NEEDS to be translated into another language!!!!!!!!!! 
  
  UIComponent(component):SetTooltipText(text)
  
end


-- ***** UI REGION POP GROWTH ***** --
-- UI shadow calculation based on Magnars grwoth function above, we can display tax changes and sieges as they happen 
-- during the player turn, YEAH!
-- Contains all adjustments of a regions population and requires the region script interface to passed to it

function UIRegionPopGrowth()

  PopLog("Start UIRegionPopGrowth")
  
  local region = UI_data_table.curr_region
  local regionName = region:name()
  
  if UIPopulation[regionName]
  then
  
    local faction = region:garrison_residence():faction()
    local factionCulture = faction:state_religion()
    local taxLevel = faction:tax_level()
    local publicOrder = region:public_order()
    local foreignArmies = false
    local regionLooted = false
    local regionOccupied = false
    local homeRegion = region:garrison_residence():faction():home_region()
    local difficulty = scripting.game_interface:model():difficulty_level()
    local regionPopTable = {0,0,0,0}
    local UIbase_growth = {0,0,0,0}
    local UI_food = {0,0,0,0}
    local UI_public_order = {0,0,0,0}
    local UI_taxation = {0,0,0,0}
    local UI_Faction_Capital = {0,0,0,0}
    local UI_Province_Capital = {0,0,0,0}
    local UI_Culture = {0,0,0,0}
    local UI_majority_religion = {0,0,0,0}
    local UI_technology = {0,0,0,0}
    local UI_buildings = {0,0,0,0}
    local UI_Under_Siege = {0,0,0,0}
    local UI_foreign_army = {0,0,0,0}
    local UI_looted_settlement = {0,0,0,0}
    local UI_occupied_settlment = {0,0,0,0}
    local UI_minimum_growth_per_class = {0,0,0,0}

    for i =1, 4
    do
    
      regionPopTable[i] = UIPopulation[regionName][i]
      
    end
    
    -- get toal population
    local totalPopulation = regionPopTable[1] + regionPopTable[2] + regionPopTable[3] + regionPopTable[4]

    PopLog("TotalPopulation UIRegionPopGrowth: "..totalPopulation)

    --2)Supply Shortage changed for DeI to look at local supply level instead of faction food
    
    local foodShortage = false
    local foodShortageNegative = false
    local foodShortageMid = false
    
    Debug("start foodShortage")
    
    local regional_supplies = Supply_Region_Table[regionName] + Supply_Storage_Table[regionName]
    
    Debug("regional_supplies: "..regional_supplies)
    
    if regional_supplies < global_supply_variables.supply_values_table["looted_region"]
    then -- MAGIC NUMBERS!!!! 
    
      foodShortageNegative = true;
    
    elseif regional_supplies < global_supply_variables.supply_values_table["foraged_region"]
    then -- MAGIC NUMBERS!!!! 
    
      foodShortage = true;
    
    elseif regional_supplies < global_supply_variables.supply_values_table["fertile_region"]
    then -- MAGIC NUMBERS!!!! 
    
      foodShortageMid = true;
    
    end
  
    --3)Majority Religion & technology
    
    PopLog("majorityCulture UIRegionPopGrowth")
    
    local majorityCulture = false
    
    if region:majority_religion() == factionCulture
    then
    
      majorityCulture = true
      
    end
    
    PopLog("baseCultureInTable UIRegionPopGrowth")
    
    --4)Culture/Religion Bonuses
    
    local baseCultureInTable = false
    
    if culture_growth_bonus[factionCulture]
    then
    
      baseCultureInTable = true
      
    end
    
    PopLog("regionIsHome UIRegionPopGrowth")
    
    --7)Faction Capitol
    
    local regionIsHome = false
    
    if region == homeRegion
    then    
    
      regionIsHome = true
    
    end
    
    PopLog("provCap UIRegionPopGrowth")
    
    --8) Province Capital
    
    local provCap = false
    
    if (region:building_superchain_exists("rom_SettlementMajor")
    or region:building_superchain_exists("dei_superchain_city_ROME")
    or region:building_superchain_exists("dei_superchain_city_PELLA")
    or region:building_superchain_exists("dei_superchain_city_CARTHAGE")
    or region:building_superchain_exists("dei_superchain_city_SYRACUSE")
    or region:building_superchain_exists("dei_superchain_city_ATHENS")
    or region:building_superchain_exists("dei_superchain_city_ALEXANDRIA")
    or region:building_superchain_exists("dei_superchain_city_PERGAMON")
    or region:building_superchain_exists("dei_superchain_city_ANTIOCH")
    or region:building_superchain_exists("dei_superchain_city_MASSILIA")
    or region:building_superchain_exists("dei_superchain_city_BIBRACTE")
	or region:building_superchain_exists("dei_superchain_city_ZARM")
    or region:building_superchain_exists("inv_etr_main_city"))
    then
    
      provCap = true
      
    end
    
    PopLog("underSiege UIRegionPopGrowth")
    
    --11) Under siege
    
    local underSiege = false
    
    if region:garrison_residence():is_under_siege()
    then
    
      underSiege = true
      
    end

    for i =1, 4
    do 
    
      -- 1) BaseGrowth %
      
      PopLog("BaseGrowth % for class: "..i)
      
      UIbase_growth[i] = population_modifier["base_pop_multiplier"][i] - 0.01*(totalPopulation/population_modifier["base_pop_growth_divisor"]*population_modifier["base_pop_growth_class_multiplier"][i])

      --2)Food Shortage
      
      PopLog("foodShortage for class: "..i)
      
      if foodShortageNegative
      then
      
        UI_food[i] = population_modifier["food_shortage_mod_negative"][i]
        
      elseif foodShortage
      then
      
        UI_food[i] = population_modifier["food_shortage_mod"][i]
    
      elseif foodShortageMid
      then
      
        UI_food[i] = population_modifier["food_shortage_mod_med"][i]
        
      else 
      
        UI_food[i] = population_modifier["not_food_shortage_mod"][i]  
        
      end
      
      --4)Culture/Religion Bonuses
      
      PopLog("baseCultureInTable for class: "..i)
      
      if baseCultureInTable
      then
      
        UI_Culture[i] = culture_growth_bonus[factionCulture][i]
        
      end
      
      --7)Faction Capitol
      
      PopLog("regionIsHome for class: "..i)
      
      if regionIsHome
      then
      
        UI_Faction_Capital[i] = population_modifier["faction_capitol_growth_modifier"][i]
        
      elseif provCap
      then
      
        PopLog("Province Capitol for class: "..i)  
        
        --8) Province Capitol
        
        UI_Province_Capital[i] = population_modifier["province_capitol_growth_modifier"][i]
      
      end     

      --3)Majority Religion & technology
      
      PopLog("Majority Religion & technology for class: "..i)
      
      if majorityCulture
      then
      
        UI_majority_religion[i] = population_modifier["majority_religion_mod_own"][i]
        
        -- tech growth based on culture
        for k, v in pairs(tech_pop_growth_own_culture_table)
        do
        
          if faction:has_technology(k)
          then
          
            UI_technology[i] = UI_technology[i] + tech_pop_growth_own_culture_table[k][i]
        
          end                                     
        end

        --9) building growth
        
        PopLog("building growth majorityCulture for class: "..i)
        
        for slots = 0, region:slot_list():num_items() -1
        do
        
          local slot = region:slot_list():item_at(slots)
          
          if slot:has_building()
          then 
          
          local buildingName = slot:building():name()
          
            if building_pop_growth_own_culture_table[buildingName]
            then
            
              UI_buildings[i] = UI_buildings[i] + building_pop_growth_own_culture_table[buildingName][i]
              
            end 
          end     
        end
        
      else
      
        UI_majority_religion[i] = population_modifier["majority_religion_mod_other"][i]
        
        for k, v in pairs(tech_pop_growth_foreign_culture_table)
        do
      
          if faction:has_technology(k)
          then
          
            UI_technology[i] = UI_technology[i] + tech_pop_growth_own_culture_table[k][i]
        
          end     
        end 
      
        --9) building growth
        
        PopLog("building growth minority Culture for class: "..i)
        
        for slots = 0, region:slot_list():num_items() -1
        do
        
          local slot = region:slot_list():item_at(slots)
          
          if slot:has_building()
          then 
      
            local buildingName = slot:building():name()
            
            if building_pop_growth_foreign_culture_table[buildingName]
            then
            
              UI_buildings[i] = UI_buildings[i] + building_pop_growth_foreign_culture_table[buildingName][i] 

            end 
          end     
        end     
      end     

      --11) Under siege
      
      PopLog("Under siege for class: "..i)
      
      if underSiege
      then
      
        UI_Under_Siege[i] = population_modifier["under_siege_growth_modifier"][i] 
        
      end 
      
      --5) Public Order growth bonus
      
      PopLog("Public Order growth bonus for class: "..i) 
      
      if publicOrder < 0
      then
      
        UI_public_order[i] = population_modifier["public_order_growth_modifier"][i]  * publicOrder/100  
        
      end
      
      PopLog("Taxation for class: "..i)
      
      --6) Taxation -- tax level returns the percentage points of tax rate so needs to be converted to a decimal to fit with the format of the regionPopModTable values as decimals
  
      UI_taxation[i] = population_modifier["tax_growth_modifier"][i] * (-0.01 * (taxLevel - 140))
      
      PopLog("Difficulty for class: "..i)
      
      --14) Difficulty difficulty
      
      if faction:is_human() then
        -- Apply the standard difficulty growth modifier for the player
        UIbase_growth[i] = math.max(0, UIbase_growth[i] + population_modifier["difficulty_growth_modifier"][difficulty + 4])

    else
        -- Apply a separate AI growth modifier (lower if needed)
        UIbase_growth[i] = UIbase_growth[i] + population_modifier["difficulty_growth_modifier"][difficulty + 2]
    end
    
    end
  
    for i =1, 4
    do 
    
      if regionPopTable[i] < population_modifier["base_pop_growth_min_size"][i] 
      and UI_data_table.total_growth > 0 then
           UI_minimum_growth_per_class[i] = UI_minimum_growth_per_class[i] + population_modifier["base_pop_growth"][i] -- no % only integer
        
end

    end

    -- minumum growth no % only integer
    
    PopLog("UI_data_table.minimum_growth")
    
    UI_data_table.minimum_growth = {UI_minimum_growth_per_class[1], UI_minimum_growth_per_class[2], UI_minimum_growth_per_class[3], UI_minimum_growth_per_class[4]}
    
    PopLog("UI_data_table.base_growth")
    
    -- base growth
    
    UI_data_table.base_growth = {UIbase_growth[1], UIbase_growth[2], UIbase_growth[3], UIbase_growth[4]}
    UI_data_table.total_base_growth = (UIbase_growth[1] + UIbase_growth[2] + UIbase_growth[3] + UIbase_growth[4]) /4
    
    -- public order
    
    PopLog("UI_data_table.public_order") 
    
    UI_data_table.public_order = {UI_public_order[1], UI_public_order[2], UI_public_order[3], UI_public_order[4]}
    UI_data_table.total_public_order = (UI_public_order[1] + UI_public_order[2] + UI_public_order[3] + UI_public_order[4]) /4
    
    -- set food
    
    PopLog("UI_data_table.food") 
    
    UI_data_table.food = {UI_food[1], UI_food[2], UI_food[3], UI_food[4]}
    UI_data_table.total_food = (UI_food[1] + UI_food[2] + UI_food[3] + UI_food[4]) /4
    
    -- set taxation
    
    PopLog("UI_data_table.food") 
    
    UI_data_table.taxation = {UI_taxation[1], UI_taxation[2], UI_taxation[3], UI_taxation[4]}
    UI_data_table.total_taxation = (UI_taxation[1] + UI_taxation[2] + UI_taxation[3] + UI_taxation[4]) /4
    
    -- set faction_capital
    
    PopLog("UI_data_table.food")
    
    UI_data_table.faction_capital = {UI_Faction_Capital[1], UI_Faction_Capital[2], UI_Faction_Capital[3], UI_Faction_Capital[4]}
    UI_data_table.total_faction_capital = (UI_Faction_Capital[1] + UI_Faction_Capital[2] + UI_Faction_Capital[3] + UI_Faction_Capital[4]) /4
    
    -- set province_capital
    
    PopLog("UI_data_table.food") 
    
    UI_data_table.province_capital = {UI_Province_Capital[1], UI_Province_Capital[2], UI_Province_Capital[3], UI_Province_Capital[4]}
    UI_data_table.total_province_capital = (UI_Province_Capital[1] + UI_Province_Capital[2] + UI_Province_Capital[3] + UI_Province_Capital[4]) /4
    
    -- set culture_bonuses
  
    PopLog("UI_data_table.food")
    
    UI_data_table.culture_bonuses = {UI_Culture[1], UI_Culture[2], UI_Culture[3], UI_Culture[4]}
    UI_data_table.total_culture_bonuses = (UI_Culture[1] + UI_Culture[2] + UI_Culture[3] + UI_Culture[4]) /4
    
    -- set majority_religion
    
    PopLog("UI_data_table.food") 
    
    UI_data_table.majority_religion = {UI_majority_religion[1], UI_majority_religion[2], UI_majority_religion[3], UI_majority_religion[4]}
    UI_data_table.total_majority_religion = (UI_majority_religion[1] + UI_majority_religion[2] + UI_majority_religion[3] + UI_majority_religion[4]) /4
    
    -- set buidlings
    
    PopLog("UI_data_table.food") 
    
    UI_data_table.buidlings = {UI_buildings[1], UI_buildings[2], UI_buildings[3], UI_buildings[4]}
    UI_data_table.total_buidlings = (UI_buildings[1] + UI_buildings[2] + UI_buildings[3] + UI_buildings[4]) /4
    
    -- set under_siege
    
    PopLog("UI_data_table.food") 
    
    UI_data_table.under_siege = {UI_Under_Siege[1], UI_Under_Siege[2], UI_Under_Siege[3], UI_Under_Siege[4]}
    UI_data_table.total_under_siege = (UI_Under_Siege[1] + UI_Under_Siege[2] + UI_Under_Siege[3] + UI_Under_Siege[4]) /4
    
    -- technology buffs
    
    UI_data_table.technology = {UI_technology[1], UI_technology[2], UI_technology[3], UI_technology[4]}
    UI_data_table.total_technology = (UI_technology[1] + UI_technology[2] + UI_technology[3] + UI_technology[4]) /4
    UI_data_table.total_noble_growth =  UIbase_growth[1] + UI_public_order[1] + UI_food[1] + UI_taxation[1] + UI_Faction_Capital[1] + UI_Province_Capital[1] + UI_Culture[1] + UI_majority_religion[1] + UI_buildings[1] + UI_Under_Siege[1] + UI_technology[1]
  
    PopLog("UI_data_table.total_noble_growth: "..UI_data_table.total_noble_growth)
  
    UI_data_table.predicted_noble_growth_number = regionPopTable[1]/100*UI_data_table.total_noble_growth
  
    PopLog("UI_data_table.predicted_noble_growth_number: "..UI_data_table.predicted_noble_growth_number)
  
    UI_data_table.total_citizen_growth =  UIbase_growth[2] + UI_public_order[2] + UI_food[2] + UI_taxation[2] + UI_Faction_Capital[2] + UI_Province_Capital[2] + UI_Culture[2] + UI_majority_religion[2] + UI_buildings[2] + UI_Under_Siege[2] + UI_technology[2]
  
    PopLog("UI_data_table.total_citizen_growth: "..UI_data_table.total_citizen_growth)
    
    UI_data_table.predicted_citizen_growth_number = regionPopTable[2]/100*UI_data_table.total_citizen_growth
    
    PopLog("UI_data_table.predicted_citizen_growth_number: "..UI_data_table.predicted_citizen_growth_number)
    
    UI_data_table.total_poor_growth =   UIbase_growth[3] + UI_public_order[3] + UI_food[3] + UI_taxation[3] + UI_Faction_Capital[3] + UI_Province_Capital[3] + UI_Culture[3] + UI_majority_religion[3] + UI_buildings[3] + UI_Under_Siege[3] + UI_technology[3]
  
    PopLog("UI_data_table.total_poor_growth: "..UI_data_table.total_poor_growth)
    
    UI_data_table.predicted_poor_growth_number = regionPopTable[3]/100*UI_data_table.total_poor_growth
    
    PopLog("UI_data_table.predicted_poor_growth_number: "..UI_data_table.predicted_poor_growth_number)
    
    UI_data_table.total_foreign_growth = UIbase_growth[4] + UI_public_order[4] + UI_food[4] + UI_taxation[4] + UI_Faction_Capital[4] + UI_Province_Capital[4] + UI_Culture[4] + UI_majority_religion[4] + UI_buildings[4] + UI_Under_Siege[4] + UI_technology[4]
  
    PopLog("UI_data_table.total_foreign_growth: "..UI_data_table.total_foreign_growth)
    
    UI_data_table.predicted_foreign_growth_number = regionPopTable[4]/100*UI_data_table.total_foreign_growth
    
    PopLog("UI_data_table.predicted_foreign_growth_number: "..UI_data_table.predicted_foreign_growth_number)
    
    UI_data_table.total_growth = (regionPopTable[1] * UI_data_table.total_noble_growth / 100) +
                             (regionPopTable[2] * UI_data_table.total_citizen_growth / 100) +
                             (regionPopTable[3] * UI_data_table.total_poor_growth / 100) +
                             (regionPopTable[4] * UI_data_table.total_foreign_growth / 100)



  
    PopLog("UI_data_table.total_growth: "..UI_data_table.total_growth)
    
    UI_data_table.total_growth_percentage = 100/totalPopulation*UI_data_table.total_growth
    
    PopLog("UI_data_table.total_growth_percentage: "..UI_data_table.total_growth_percentage)
    PopLog("End UIRegionPopGrowth")   
    
  end
end 


-- ***** UI GET IMMIGRATION ***** --
-- for immigration we only display stored values from the previous end turn 
-- the values will be shown in "()" behind the population class
-- we might add a total value here soon

function UIGetImmigration()

  local region_name = UI_data_table.curr_region_name
  
  for popClass  = 1, 4
  do
  
    if popClass == 1
    then
    
      UI_data_table.immigration_1 = region_desire[region_name][popClass + 4]
      
    end
    
    if popClass == 2
    then
    
      UI_data_table.immigration_2 = region_desire[region_name][popClass + 4]
      
    end
    
    if popClass == 3
    then
    
      UI_data_table.immigration_3 = region_desire[region_name][popClass + 4]
      
    end
    
    if popClass == 4 then
    
      UI_data_table.immigration_4 = region_desire[region_name][popClass + 4]
      
    end
  end
end


-- ***** UI REGION EFFECTS ***** --
-- UI shadow calc for economic effects

function UIRegionEffects(region)

  local regionName = region:name()
  local regionPop = {0,0,0,0}
  local totalPop = 0
  local factionName = region:owning_faction():name()
  local factionCategory 
 
  if faction_to_faction_pop_class[factionName]
  then
  
    factionCategory = faction_to_faction_pop_class[factionName]
    
  else
  
    factionCategory = "default"
    
  end
  
  regionPop = {region_table[regionName][1] , region_table[regionName][2], region_table[regionName][3], region_table[regionName][4]}
  totalPop = regionPop[1] + regionPop[2] + regionPop[3] + regionPop[4]

  --get ideal pop ratios
  
  local up = regionPop[1]
  local mid = regionPop[2]
  local low = regionPop[3]
  local foreign = regionPop[4]
  local citizens = up + mid + low
  
  -- Percentage
  
  local foreignTotalPercent = foreign / totalPop
  local upCitizenPercent = up / citizens
  local midCitizenPercent = mid / citizens
  local lowCitizenPercent = low / citizens
  
  -- region states
  
  -- foreign %
  -- determine effect bundle set
  
  if (factionCategory ~= "default")
  then
  
     PopLog("RegionBundle category not default", "ApplyRegionBundle()")
    
  else
  
    -- 1) Foreigner %
    
    -- heartland    
    if (foreignTotalPercent < 0.2)
    then
    
      UI_data_table.PoR2_region_foreign = UI_economic_factor[factionCategory][1][1]
      UI_data_table.PoR2_region_additional_foreign_txt = UI_economic_factor_texts[1][1]
      
    --Provincial    
    elseif (foreignTotalPercent < 0.6)
    then
    
      UI_data_table.PoR2_region_foreign = UI_economic_factor[factionCategory][1][2]
      UI_data_table.PoR2_region_additional_foreign_txt = UI_economic_factor_texts[1][2]
      
    --Colony
    elseif (foreignTotalPercent < 0.8)
    then
    
      UI_data_table.PoR2_region_foreign = UI_economic_factor[factionCategory][1][3]
      UI_data_table.PoR2_region_additional_foreign_txt = UI_economic_factor_texts[1][3]
      
    --Subject Kigndom
    else
    
      UI_data_table.PoR2_region_foreign = UI_economic_factor[factionCategory][1][4]
      UI_data_table.PoR2_region_additional_foreign_txt = UI_economic_factor_texts[1][4]
      
    end
    
    --2) upper citizen ratio
    
    --overbearing
    
    if ( upCitizenPercent > (faction_pop_ratio_eco[factionCategory][1] * 3))
    then
    
      UI_data_table.PoR2_region_noble = UI_economic_factor[factionCategory][2][1]
      UI_data_table.PoR2_region_additional_noble_txt = UI_economic_factor_texts[2][1]
      
    --strong    
    elseif ( upCitizenPercent > (faction_pop_ratio_eco[factionCategory][1] * 1.5))
    then
    
      UI_data_table.PoR2_region_noble = UI_economic_factor[factionCategory][2][2]
      UI_data_table.PoR2_region_additional_noble_txt = UI_economic_factor_texts[2][2]
      
    --weak
    elseif ( upCitizenPercent < (faction_pop_ratio_eco[factionCategory][1] * 0.8))
    then
    
      UI_data_table.PoR2_region_noble = UI_economic_factor[factionCategory][2][3]
      UI_data_table.PoR2_region_additional_noble_txt = UI_economic_factor_texts[2][3]
    
    --minimal
    elseif ( upCitizenPercent < (faction_pop_ratio_eco[factionCategory][1] * 0.3))
    then
    
      UI_data_table.PoR2_region_noble = UI_economic_factor[factionCategory][2][4]
      UI_data_table.PoR2_region_additional_noble_txt = UI_economic_factor_texts[2][4]
      
        else 
    
      UI_data_table.PoR2_region_noble = UI_economic_factor[factionCategory][2][5]
      UI_data_table.PoR2_region_additional_noble_txt = UI_economic_factor_texts[2][5]
      
    end
    
    --3) mid citizen ratio 
    
    --thriving
    if ( midCitizenPercent > (faction_pop_ratio_eco[factionCategory][2] * 3))
    then
    
      UI_data_table.PoR2_region_middle = UI_economic_factor[factionCategory][3][1]
      UI_data_table.PoR2_region_additional_middle_txt = UI_economic_factor_texts[3][1]
      
    --industrious   
    elseif ( midCitizenPercent > (faction_pop_ratio_eco[factionCategory][2] * 1.5))
    then
    
      UI_data_table.PoR2_region_middle = UI_economic_factor[factionCategory][3][2]
      UI_data_table.PoR2_region_additional_middle_txt = UI_economic_factor_texts[3][2]
      
    --stagnant
    elseif ( midCitizenPercent < (faction_pop_ratio_eco[factionCategory][2] * 0.8))
    then
    
      UI_data_table.PoR2_region_middle = UI_economic_factor[factionCategory][3][3]
      UI_data_table.PoR2_region_additional_middle_txt = UI_economic_factor_texts[3][3]
      
    --failing
    elseif ( midCitizenPercent < (faction_pop_ratio_eco[factionCategory][2] * 0.3))
    then
    
      UI_data_table.PoR2_region_middle = UI_economic_factor[factionCategory][3][4]
      UI_data_table.PoR2_region_additional_middle_txt = UI_economic_factor_texts[3][4]
      
        else
    
      UI_data_table.PoR2_region_middle = UI_economic_factor[factionCategory][3][5]
      UI_data_table.PoR2_region_additional_middle_txt = UI_economic_factor_texts[3][5]
      
    end
    
    --4) No low class effect
    
  end
  
  --5) Total Pop Size - bundle_5
  
  --extremely_dense
  if ( totalPop > economic_data["pop_extremely_dense"] )
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][1]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][1]
    
  --very_dense
  elseif ( totalPop > economic_data["pop_very_dense"])
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][2]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][2]
    
  --dense
  elseif ( totalPop > economic_data["pop_dense"])
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][3]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][3]
    
  --fairly dense
  elseif ( totalPop > economic_data["pop_fairly_dense"])
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][4]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][4] 
    
  --moderate
  elseif ( totalPop > economic_data["pop_moderate"])
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][5]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][5]
    
  --sparse 
  elseif ( totalPop > economic_data["pop_sparse"])
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][6]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][6] 
    
  --very_sparse
  elseif ( totalPop > economic_data["pop_very_sparse"])
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][7]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][7]
    
  --extremely_sparse
  elseif ( totalPop > economic_data["pop_extremely_sparse"])
  then
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][8]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][8]
    
  --almost empty
  else
  
    UI_data_table.PoR2_region_total = UI_economic_factor[factionCategory][5][9]
    UI_data_table.PoR2_region_additional_total_txt = UI_economic_factor_texts[5][9]
    
  end
end


-- ***** UI DEV POINS ICON TOOLTIP ***** --
-- this function will construct the population tooltip (3 people icon)

function UIDevPoinsIconTooltip(component)

  Debug("UIDevPoinsIconTooltip")
  
    local line = UI_data_table.new_line
    local gr_o = UI_data_table.col_green_open
    local gr_c = UI_data_table.col_green_close
    local y_o = UI_data_table.col_yellow_open
    local y_c = UI_data_table.col_yellow_close
    local r_o = UI_data_table.col_red_open
    local r_c = UI_data_table.col_red_close
    local immigration_1 = UI_data_table.immigration_1
    local immigration_2 = UI_data_table.immigration_2
    local immigration_3 = UI_data_table.immigration_3
    local immigration_4 = UI_data_table.immigration_4
    local tx_im_1 = ""
    local tx_im_2 = ""
    local tx_im_3 = ""
    local tx_im_4 = ""
    local noble_class = UICommaValue(UI_data_table.noble_pop)
    local citizens_class = UICommaValue(UI_data_table.mid_pop)
    local poor_class = UICommaValue(UI_data_table.low_pop)
    local foreign_class = UICommaValue(UI_data_table.foreign_pop)
    local population = UICommaValue(UI_data_table.total_pop)
    local noble_name = UI_data_table.noble_pop_name
    local citizens_name = UI_data_table.mid_pop_name
    local poor_name = UI_data_table.low_pop_name
    local foreign_name = UI_data_table.foreign_pop_name     
    local text = UI_data_table.flavour_region_pop_text..UI_data_table.text_pop_clases..noble_name..UI_data_table.double_dot_space..y_o..noble_class..y_c.." "
  
  Debug("UIDevPoinsIconTooltip: Local Vars set successfully")
  
    -- PopLog("Start: change tooltip +/- for immigration", "UIDevPoinsIconTooltip()")

    if immigration_1 > 0
    then
    
      tx_im_1 = gr_o.."(+"..immigration_1..")"..gr_c
      
    elseif immigration_1 < 0
    then
    
      tx_im_1 = r_o.."("..immigration_1..")"..r_c
      
    elseif immigration_1 == 0
    then
    
      tx_im_1 = y_o.."("..immigration_1..")"..y_c
      
    end

    text = text..tx_im_1..line..citizens_name..UI_data_table.double_dot_space..y_o..citizens_class..y_c.." "

    if immigration_2 > 0
    then
    
      tx_im_2 = gr_o.."(+"..immigration_2..")"..gr_c
      
    elseif immigration_2 < 0
    then
    
      tx_im_2 = r_o.."("..immigration_2..")"..r_c
      
    elseif immigration_2 == 0
    then
    
      tx_im_2 = y_o.."("..immigration_2..")"..y_c
      
    end

    text = text..tx_im_2..line..poor_name..UI_data_table.double_dot_space..y_o..poor_class..y_c.." "

    if immigration_3 > 0
    then
    
      tx_im_3 = gr_o.."(+"..immigration_3..")"..gr_c
      
    elseif immigration_3 < 0
    then
    
      tx_im_3 = r_o.."("..immigration_3..")"..r_c

    elseif immigration_3 == 0
    then
    
      tx_im_3 = y_o.."("..immigration_3..")"..y_c
      
    end

    text = text..tx_im_3..line..foreign_name..UI_data_table.double_dot_space..y_o..foreign_class..y_c.." "

    if immigration_4 > 0
    then
    
      tx_im_4 = gr_o.."(+"..immigration_4..")"..gr_c
      
    elseif immigration_4 < 0
    then
    
      tx_im_4 = r_o.."("..immigration_4..")"..r_c
      
    elseif immigration_4 == 0
    then
    
      tx_im_4 = y_o.."("..immigration_4..")"..y_c
      
    end

    text = text..tx_im_4..line..UI_data_table.underline..UI_data_table.text_total_population..population..line..line..UI_data_table.economics_base_tx..line..UI_data_table.EcoFlavor_txt..line..line -- add new parts turning over to regional economy

  Debug("UIDevPoinsIconTooltip: immigration set successfully")
  
    if UI_data_table.PoR2_region_noble > 0
    then
    
      text = text..UI_data_table.PoR2_region_noble_txt..gr_o.." +"..UI_data_table.PoR2_region_noble.."%"..gr_c..line..gr_o..UI_data_table.PoR2_region_additional_noble_txt..gr_c..line..line
      
    elseif UI_data_table.PoR2_region_noble < 0 
    then
    
      text = text..UI_data_table.PoR2_region_noble_txt..r_o.." "..UI_data_table.PoR2_region_noble.."%"..r_c..line..r_o..UI_data_table.PoR2_region_additional_noble_txt..r_c..line..line
      
    end 
    
  Debug("UIDevPoinsIconTooltip: PoR2_region_noble")
    
    if UI_data_table.PoR2_region_middle > 0
    then
    
      text = text..UI_data_table.PoR2_region_middle_txt..gr_o.." +"..UI_data_table.PoR2_region_middle.."%"..gr_c..line..gr_o..UI_data_table.PoR2_region_additional_middle_txt..gr_c..line..line
      
    elseif UI_data_table.PoR2_region_middle < 0
    then
    
      text = text..UI_data_table.PoR2_region_middle_txt..r_o.." "..UI_data_table.PoR2_region_middle.."%"..r_c..line..r_o..UI_data_table.PoR2_region_additional_middle_txt..r_c..line..line
      
    end 
    
  Debug("UIDevPoinsIconTooltip: PoR2_region_middle")
    
    if UI_data_table.PoR2_region_foreign > 0
    then
    
      text = text..UI_data_table.PoR2_region_foreign_txt..gr_o.." +"..UI_data_table.PoR2_region_foreign.."%"..gr_c..line..gr_o..UI_data_table.PoR2_region_additional_foreign_txt..gr_c..line..line
      
    elseif UI_data_table.PoR2_region_foreign < 0
    then
    
      text = text..UI_data_table.PoR2_region_foreign_txt..r_o.." "..UI_data_table.PoR2_region_foreign.."%"..r_c..line..r_o..UI_data_table.PoR2_region_additional_foreign_txt..r_c..line..line
      
    end 
  
  Debug("UIDevPoinsIconTooltip: PoR2_region_foreign")
  
    if UI_data_table.PoR2_region_total > 0
    then
    
      text = text..UI_data_table.PoR2_region_total_txt..gr_o.." +"..UI_data_table.PoR2_region_total.."%"..gr_c..line..gr_o..UI_data_table.PoR2_region_additional_total_txt..gr_c..line
      
    elseif UI_data_table.PoR2_region_total < 0
    then
    
      text = text..UI_data_table.PoR2_region_total_txt..r_o.." "..UI_data_table.PoR2_region_total.."%"..r_c..line..r_o..UI_data_table.PoR2_region_additional_total_txt..r_c..line 
      
    end
  
    UIComponent(component):SetTooltipText(text)
  
  end
  
  local function PopSaveNewRegion(context)    
  local region = context:garrison_residence():region()
  
  RegionNameUIPop = region:name()

end;


-- ***** UI DEV POINS ICON TOOLTIP ***** --
-- TTIP_STF1_Popu_0003 = Region Population

function UIDevPoinsIconTooltip1(context)

  Debug("UIDevPoinsIconTooltip1")

  local component = UIComponent(context.component):Id()

  if component == "TTIP_STF1_Popu_0003"
  then
  
    local line = UI_data_table.new_line
    local gr_o = UI_data_table.col_green_open
    local gr_c = UI_data_table.col_green_close
    local y_o = UI_data_table.col_yellow_open
    local y_c = UI_data_table.col_yellow_close
    local r_o = UI_data_table.col_red_open
    local r_c = UI_data_table.col_red_close
    local immigration_1 = UI_data_table.immigration_1
    local immigration_2 = UI_data_table.immigration_2
    local immigration_3 = UI_data_table.immigration_3
    local immigration_4 = UI_data_table.immigration_4
    local RegionDisplayName = region_name_table[RegionNameUIPop]
    local tx_im_1 = ""
    local tx_im_2 = ""
    local tx_im_3 = ""
    local tx_im_4 = ""
    local min_value = 0.001   
    local negative_value = -0.001
    local minimum_growth = 0
    local noble_class = UICommaValue(UI_data_table.noble_pop)
    local citizens_class = UICommaValue(UI_data_table.mid_pop)
    local poor_class = UICommaValue(UI_data_table.low_pop)
    local foreign_class = UICommaValue(UI_data_table.foreign_pop)
    local population = UICommaValue(UI_data_table.total_pop)
    local noble_name = UI_data_table.noble_pop_name
    local citizens_name = UI_data_table.mid_pop_name
    local poor_name = UI_data_table.low_pop_name
    local foreign_name = UI_data_table.foreign_pop_name     
    local text = y_o..RegionDisplayName..y_c..UI_data_table.flavour_region_pop_text1..UI_data_table.text_pop_clases..noble_name..UI_data_table.double_dot_space..y_o..noble_class..y_c
    local total_noble_growth = UIFormatValuesBehindComma(UI_data_table.total_noble_growth)
    local predicted_noble_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_noble_growth_number)
    
    if UI_data_table.total_noble_growth > min_value
    then
    
      text = text.." ("..gr_o.."+"..predicted_noble_growth_number.. gr_c..")"
      
    elseif UI_data_table.total_noble_growth <= negative_value
    then
    
      text = text.." ("..r_o..predicted_noble_growth_number.. r_c..")"
    
    else

      text = text.." ("..y_o..""..predicted_noble_growth_number.. y_c..")"
      
    end

  Debug("UIDevPoinsIconTooltip1: Local Vars set successfully")
    
    -- PopLog("Start: change tooltip +/- for immigration", "UIDevPoinsIconTooltip()")

    text = text..tx_im_1..line..citizens_name..UI_data_table.double_dot_space..y_o..citizens_class..y_c
  
    local total_citizen_growth = UIFormatValuesBehindComma(UI_data_table.total_citizen_growth)
    local predicted_citizen_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_citizen_growth_number) 
  
    if UI_data_table.total_citizen_growth > min_value
    then
      
      text = text.." ("..gr_o.."+"..predicted_citizen_growth_number.. gr_c..")"
    
    elseif UI_data_table.total_citizen_growth <= negative_value
    then
      
      text = text.." ("..r_o..predicted_citizen_growth_number.. r_c..")"
    
    else
      
      text = text.." ("..y_o.."+"..predicted_citizen_growth_number.. y_c..")"
    
    end
  
    text = text..tx_im_2..line..poor_name..UI_data_table.double_dot_space..y_o..poor_class..y_c
  
    local total_poor_growth = UIFormatValuesBehindComma(UI_data_table.total_poor_growth)
    local predicted_poor_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_poor_growth_number)
  
    if UI_data_table.total_poor_growth > min_value
    then
    
      text = text.." ("..gr_o.."+"..predicted_poor_growth_number.. gr_c..")"
      
    elseif UI_data_table.total_poor_growth <= negative_value
    then
    
      text = text.." ("..r_o..predicted_poor_growth_number.. r_c..")"
      
    else
    
      text = text.." ("..y_o..""..predicted_poor_growth_number.. y_c..")"
    
    end
  
    text = text..tx_im_3..line..foreign_name..UI_data_table.double_dot_space..y_o..foreign_class..y_c
  
    local total_foreign_growth = UIFormatValuesBehindComma(UI_data_table.total_foreign_growth)
    local predicted_foreign_growth_number = UIRemoveValuesBehindComma(UI_data_table.predicted_foreign_growth_number) 
    
    if UI_data_table.total_foreign_growth > min_value
    then
      
      text = text.." ("..gr_o.."+"..predicted_foreign_growth_number.. gr_c..")"
      
    elseif UI_data_table.total_foreign_growth <= negative_value
    then
      
      text = text.." ("..r_o..predicted_foreign_growth_number.. r_c..")"
      
    else
      
      text = text.." ("..y_o..""..predicted_foreign_growth_number.. y_c..")"
      
    end

    text = text..tx_im_4..line..line..UI_data_table.text_total_population1..population
  
    local total_growth_percentage = UIFormatValuesBehindComma(UI_data_table.total_growth_percentage)
    local total_growth = UIRemoveValuesBehindComma(UI_data_table.total_growth) 
    
    if UI_data_table.total_growth_percentage > min_value
    then
      
      text = text.." ("..gr_o.."+"..total_growth.. gr_c..")"
      
    elseif UI_data_table.total_growth_percentage <= negative_value
    then
      
      text = text.." ("..r_o..total_growth.. r_c..")"
      
    else
      
      text = text.." ("..y_o..""..total_growth.. y_c..")"
      
    end
  
    text = text..UI_data_table.underline1..line..UI_data_table.economics_base_tx..line..line -- add new parts turning over to regional economy
  
  Debug("UIDevPoinsIconTooltip1: immigration set successfully")
    
    if UI_data_table.PoR2_region_noble > 0
    then
      
      text = text..UI_data_table.PoR2_region_noble_txt..line..gr_o.."+"..UI_data_table.PoR2_region_noble.."% "..UI_data_table.PoR2_region_additional_noble_txt..gr_c..line
      
    elseif UI_data_table.PoR2_region_noble < 0
    then
      
      text = text..UI_data_table.PoR2_region_noble_txt..line..r_o..UI_data_table.PoR2_region_noble.."% "..UI_data_table.PoR2_region_additional_noble_txt..r_c..line
    
    end 

  Debug("UIDevPoinsIconTooltip1: PoR2_region_noble")
  
    if UI_data_table.PoR2_region_middle > 0
    then
      
      text = text..UI_data_table.PoR2_region_middle_txt..line..gr_o.."+"..UI_data_table.PoR2_region_middle.."% "..UI_data_table.PoR2_region_additional_middle_txt..gr_c..line
    
    elseif UI_data_table.PoR2_region_middle < 0
    then
      
      text = text..UI_data_table.PoR2_region_middle_txt..line..r_o..UI_data_table.PoR2_region_middle.."% "..UI_data_table.PoR2_region_additional_middle_txt..r_c..line
    
    end 
  
  Debug("UIDevPoinsIconTooltip1: PoR2_region_middle")
  
    if UI_data_table.PoR2_region_foreign > 0
    then
    
      text = text..UI_data_table.PoR2_region_foreign_txt..line..gr_o.."+"..UI_data_table.PoR2_region_foreign.."% "..UI_data_table.PoR2_region_additional_foreign_txt..gr_c..line
    
    elseif UI_data_table.PoR2_region_foreign < 0
    then
      
      text = text..UI_data_table.PoR2_region_foreign_txt..line..r_o..UI_data_table.PoR2_region_foreign.."% "..UI_data_table.PoR2_region_additional_foreign_txt..r_c..line
    
    end 
  
  Debug("UIDevPoinsIconTooltip1: PoR2_region_foreign")
  
    if UI_data_table.PoR2_region_total > 0
    then
      
      text = text..UI_data_table.PoR2_region_total_txt..line..gr_o.."+"..UI_data_table.PoR2_region_total.."% "..UI_data_table.PoR2_region_additional_total_txt..gr_c..line
    
    elseif UI_data_table.PoR2_region_total < 0
    then
      
      text = text..UI_data_table.PoR2_region_total_txt..line..r_o..UI_data_table.PoR2_region_total.."% "..UI_data_table.PoR2_region_additional_total_txt..r_c..line  
    
    end
  
    UIComponent(context.component):SetTooltipText(text)
    
  end
end


-- ***** UI GET PROVINCE POP ***** --
-- function used to get the whole population for an individual province

function UIGetProvincePop(region)

  PopLog("UIGetProvincePop: "..region:name())
  
  -- declare local class variables
  
  local noble_pop = 0
  local citizens_pop = 0
  local poor_pop = 0
  local foreign_pop = 0

  -- retrieve the local faction and the last region selected
  
  local faction = UIGetLocalFaction()
  local regionName = region:name()
  local province = UIProvinceFromRegionname(regionName)
  
  PopLog("province: "..province)
  
  -- retrieve all regions from the local faction
  
  local factions_regions = faction:region_list()

  for i = 0, factions_regions:num_items() - 1
  do
  
    local region = factions_regions:item_at(i)
    local regionName_2 = region:name()
    
    PopLog("regionName_2: "..regionName_2)
    
    local province_name = UIProvinceFromRegionname(regionName_2)
    
    PopLog("province_name: "..regionName_2)
    
    if province_name == province
    then
    
      noble_pop = noble_pop + UIPopulation[regionName_2][1]
      citizens_pop = citizens_pop + UIPopulation[regionName_2][2]
      poor_pop = poor_pop + UIPopulation[regionName_2][3]
      foreign_pop = foreign_pop + UIPopulation[regionName_2][4]
      
    end
  end

  -- change table entries to retrieve them later, 
  -- pro_class_pop for total amount of population per class in the province 

  UI_data_table.pro_noble_pop = noble_pop
  UI_data_table.pro_citizens_pop = citizens_pop
  UI_data_table.pro_poor_pop = poor_pop
  UI_data_table.pro_middle_pop = poor_pop + citizens_pop
  UI_data_table.pro_foreign_pop = foreign_pop 
  
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- EVENT FUNCTIONS  ---------------------------------------------------------------------

-- UIRetrievePopulation
-- UIChangeOnButtonPressed
-- OnBuildingConstructionIssuedByPlayer
-- UIPanelOpenedCampaign
-- UIChangeCampaignComponentsOnMouseOn
-- RecListenerCheckNavy
-- setClassPop
-- UIManpowerCosts
-- UIEnableQueuedUnitTooltips
-- OnTimeTrigger
-- OnShortcutTriggered

-- #####-------------------------


-- ***** UI RETRIEVE POPULATION ***** --
-- retrieve region population from selected city

local function UIRetrievePopulation(context)

  PopLog("UIRetrievePopulation");
  
  current_character = nil;
  
  local region = context:garrison_residence():region();
  
  UI_data_table.curr_region = region;
  UI_data_table.curr_region_name = region:name();
  
  PopLog("UIRetrievePopulation for: ".. region:name());
  
  UIRetrievetotalpopulation();
  
  PopLog("UIRetrievetotalpopulation check");
  
  UIGetProvincePop(region);
  
  PopLog("UIRetrievetotalpopulation check");
  
  scripting.game_interface:add_time_trigger("Change_Pop", 0.1);
  scripting.game_interface:add_time_trigger("Change_Growth_Bar", 0.3);
  scripting.game_interface:add_time_trigger("Change_Details", 0.1);
  
  local faction = context:garrison_residence():faction():name();
  
  UI_data_table.curr_faction_class_id = UIGarrisonFactionNameToClass(faction);
  UIRegionEffects(region);
  UIRetrievePopulationClasses();
  
end;


-- ***** UIChangeOnButtonPressed ***** --
-- retrieve region population from last selected city on button button_show_province

local function UIChangeOnButtonPressed(context) 
 
  if context.string == "button_show_province"
  then
  
    scripting.game_interface:add_time_trigger("Change_Pop", 0.1);
    
    return;
  
  end;

  -- growth number changes on button activate slot, so we have to take click into account
  
  if context.string == "button_activate_slot"
  then
  
    for i = 0.1, 1, 0.1
    do
    
      scripting.game_interface:add_time_trigger("Change_Pop", i);
    
    end;
  
    return;
    
  end;

  if (context.string == "button_recruitment")
  then
  
    scripting.game_interface:add_time_trigger("hide_panel", 0.2);
    
  end;

  if context.string == "button_province_details"
  then
  
    scripting.game_interface:add_time_trigger("Change_Details", 0.2);

  elseif context.string == "Summary"
  then
  
    scripting.game_interface:add_time_trigger("Show_Total_Pop", 0.2);

  elseif (context.string == "button_cycle_right")
  then
  
    scripting.game_interface:add_time_trigger("Change_Details", 0.2);

  elseif (context.string == "button_cycle_left")
  then
  
    scripting.game_interface:add_time_trigger("Change_Details", 0.2);

  elseif (context.string == "checkbox_tax_exempt")
  then
  
    scripting.game_interface:add_time_trigger("Change_Details", 0.2);
    
    return;
    
  end;

  local CancelBuilding = UIComponent(context.component):GetTooltipText()
  local endstring = UI_data_table.cancel_building_string
  
  if string.find(CancelBuilding, endstring)
  then -- tooltip string for cancel buildings
  
    for i = 0.1, 1, 0.1
    do
    
      scripting.game_interface:add_time_trigger("Change_Pop", i);
      
    end;
  end;
end;


-- ***** ON BUILDING CONSTRUCTION ISSUED BY PLAYER ***** --

local function OnBuildingConstructionIssuedByPlayer(context)

  scripting.game_interface:add_time_trigger("Change_Pop", 0.1)
  
end


last_region_name = 'nil'


-- ***** UI PANEL OPENED CAMPAIGN ***** --
-- these are called everytime a new campaign panel opens, used for Regional Population

local function UIPanelOpenedCampaign(context)

  Log("Panel Opened " ..context.string)
  
  if context.string == "settlement_panel"
  then
  
    -- calling it here leads to an issue as the region key might not be valid anymore and we retrieve it on region select
    scripting.game_interface:add_time_trigger("Change_Pop", 0.1)
    
    -- calling it here leads to an issue as the region key might not be valid anymore and we retrieve it on region select
    scripting.game_interface:add_time_trigger("Change_Growth_Bar", 0.3)
    
  end
  

  if context.string == "province_details_panel"
  then
  
    scripting.game_interface:add_time_trigger("Change_Details", 0.1)
    scripting.game_interface:add_time_trigger("Move_Icons", 0.1)
    
  end

  if context.string == "clan"
  then
  
    scripting.game_interface:add_time_trigger("Show_Total_Pop", 0.1)
    
  end  
end


-- removed: DeI_127 new UI interface

--save_X_2 = 0
--save_X_4 = 0
--original_X_2 = 0
--original_X_4 = 0


-- ***** CHANGE GROWTH BAR ***** --
-- removed: DeI_127 new UI interface

--function ChangeGrowthBar()

--  Debug("Change Growth Bar")
  
--  local growth_icon_uic = UIComponent(scripting.m_root:Find("dev_points icon"))
  
--  Debug("Growth bar icon found: "..tostring(growth_icon_uic))
  
--  growth_bar_uic = UIComponent(growth_icon_uic:Find("growth_bar"))
  
--  Debug("Growth bar found: "..tostring(growth_bar_uic))
  
--  growth_bar_uic:SetMoveable(true)

--  local provinceName = UIProvinceFromRegionname(UI_data_table.curr_region_name)
  
--  Debug("Province Name: "..provinceName)

--  local X = 0

--  if province_name_table[provinceName][3] == 2
--  then
  
--    Debug("Province Name Number of Regions = 2 or 3")

--    local growth_bar_pX, growth_bar_pY = growth_bar_uic:Position()

--    if save_X_2 == 0 
--    and save_X_4 == 0 
--    then

--      original_X_2 = growth_bar_pX 

--      Debug("First Province clicked with Number of Regions = 2 or 3")
--      Debug("growth_bar_pX: "..tostring(growth_bar_pX).." growth_bar_pY: "..tostring(growth_bar_pY))
  
--    elseif save_X_4 ~= 0
--    then

--      original_X_2 = growth_bar_pX - 70

--      Debug("First Province clicked with Number of Regions = 4") 
--      Debug("Set original_X_2: "..tostring(original_X_2))

--    end;

--    X = original_X_2 + 370

--    Debug("Set New X: "..tostring(X))

--    if save_X_2 == 0 
--    and save_X_4 == 0   
--    then

--      save_X_2 = X
  
--      Debug("Set New save_X_2: "..tostring(save_X_2))

--    elseif save_X_2 == 0 
--    and save_X_4 ~= 0 
--    then

--      save_X_2 = original_X_2 + 370
  
--      Debug("Set New save_X_2: "..tostring(save_X_2)) 
  
--    end;

--    growth_bar_uic:MoveTo(save_X_2, growth_bar_pY)

--    return;

--  end;

--  if province_name_table[provinceName][3] == 4
--  then
  
--    Debug("Province Name Number of Regions = 4")

--    local growth_bar_pX, growth_bar_pY = growth_bar_uic:Position()

--    if save_X_2 == 0 
--    and save_X_4 == 0 
--    then

--      original_X_4 = growth_bar_pX 

--      Debug("First Province clicked with Number of Regions = 4")
--      Debug("growth_bar_pX: "..tostring(growth_bar_pX).." growth_bar_pY: "..tostring(growth_bar_pY))

--    elseif save_X_2 ~= 0 
--    then

--      original_X_4 = growth_bar_pX - 370

--      Debug("First Province clicked with Number of Regions = 2 or 3");
--      Debug("Set original_X_4: "..tostring(original_X_4)); 

--    end;

--    X = original_X_4 + 70

--    if save_X_2 == 0 
--    and save_X_4 == 0 
--    then

--      save_X_4 = X

--      Debug("Set New save_X_4: "..tostring(save_X_4));

--    elseif save_X_4 == 0 
--    and save_X_2 ~= 0 
--    then

--      save_X_4 = original_X_4 + 70

--      Debug("Set New save_X_4: "..tostring(save_X_4));

--    end;

--    growth_bar_uic:MoveTo(save_X_4, growth_bar_pY); 

--  end;
  
--  growth_bar_uic:SetMoveable(false); -- make sure the toolbar can't be moved by the player

--end;


-- ***** UI CHANGE TOOLTIP: DEV POINTS ICON ***** --
-- TTIP_STA1_Popu_0001 =  slot icon showing useless tooltip

local function UIChangeTooltip_dev_points_icon(context)

  if context.string == "dev_points icon"
  then 
  
    UIComponent(context.component):SetTooltipText("Building Slots||You can expand your cities and create new building slots.\n\nSlot surplus is gained through growth, which is generated by your settlements' capital buildings.")

  end
end


-- ***** UI CHANGE TOOLTIP: TTIP STAA POPU 0001 ***** --
-- TTIP_STA1_Popu_0001 =  population icon showing useless tooltip

local function UIChangeTooltip_TTIP_STA1_Popu_0001(context)

  if context.string == "TTIP_STA1_Popu_0001"
  then 
  
    UIComponent(context.component):SetTooltipText("Population||Each region has a population from which you can recruit forces to fight in your armies.")

  end
end


-- ***** UI CHANGE TOOLTIP: BUTTON DISBAND ***** --
-- TTIP_STA1_Popu_0001 =  population icon showing useless tooltip

--local function UIChangeTooltip_button_disband(context)

  --if context.string == "button_disband"
  --then 
  
    --UIComponent(context.component):SetTooltipText("Disband\n\n[[rgba:255:204:51:150]]Remember to disband units --individually and slowly for accurate results.[[/rgba:255:204:51:150]]")

  --end
--end


-- ***** UI CHANGE CAMPAIGN COMPONENTS ON MOUSE ON ***** --
-- change User Interface
-- TTIP_STE1_Popu_0002 = Region Growth

local function UIChangeCampaignComponentsOnMouseOn(context)

  -- removed: DeI_127 new UI interface

  -- if context.string == "dev_points icon" 
  -- then

  -- UIGetImmigration()

  -- PopLog("End:", "UIGetImmigration()")

  -- UIDevPoinsIconTooltip(context.component)

  -- end

  if context.string == "TTIP_STE1_Popu_0002"
  then 
  
    UIGrowthTooltip(context.component)
    
  end

  if context.string == "icon_command"
  then 
  
    local text = UIComponent(context.component):GetTooltipText()
    local string = UI_data_table.authoritarian_string
    
    if string.find(text, string) or string.find(text, "First Class")
    then
      
      --" Province and faction capitals can increase regional "..UI_data_table.col_yellow_open ..UI_data_table.noble_pop_name..UI_data_table.col_yellow_close.." growth rates")
      UIComponent(context.component):SetTooltipText("Your "..UI_data_table.col_yellow_open ..UI_data_table.noble_pop_name..UI_data_table.col_yellow_close.. " population in the province.")
  
    end
  end

  if context.string == "dy_command" -- or "dy_subterfuge", vanilla mistake
  then 
  
    local text = UIComponent(context.component):GetTooltipText()
    local string = UI_data_table.cunning_string
    
    if string.find(text, string) or string.find(text, "First Class")
    then 
    
      --" Province and faction capitals can increase regional "..UI_data_table.col_yellow_open ..UI_data_table.noble_pop_name..UI_data_table.col_yellow_close.." growth rates")
      UIComponent(context.component):SetTooltipText("Your "..UI_data_table.col_yellow_open ..UI_data_table.noble_pop_name..UI_data_table.col_yellow_close.. " population in the province.")
      
    end
  end     

  if context.string == "icon_subterfuge"
  then
  
    local text = UIComponent(context.component):GetTooltipText()
    local string = UI_data_table.cunning_string
    
    if string.find(text, string) or string.find(text, "Third Class")
    then
    
      local pop1 = UICommaValue(UI_data_table.pro_citizens_pop)
      local pop2 = UICommaValue(UI_data_table.pro_poor_pop)
      
      UIComponent(context.component):SetTooltipText("Your combined "..UI_data_table.col_yellow_open..UI_data_table.mid_pop_name ..UI_data_table.col_yellow_close.." and "..UI_data_table.col_yellow_open..UI_data_table.low_pop_name ..UI_data_table.col_yellow_close.." population in the province.\n\n"..UI_data_table.mid_pop_name..": "..UI_data_table.col_yellow_open..pop1..UI_data_table.col_yellow_close.."\n"..UI_data_table.low_pop_name..": "..UI_data_table.col_yellow_open..pop2..UI_data_table.col_yellow_close)
  
    end
  end

  if context.string == "dy_subterfuge" --or "dy_zeal" vanilla mistake
  then
  
    local text = UIComponent(context.component):GetTooltipText()
    local string = UI_data_table.zealous_string
    
    if string.find(text, string) or string.find(text, "Third Class")
    then
    
      local pop1 = UICommaValue(UI_data_table.pro_citizens_pop)
      local pop2 = UICommaValue(UI_data_table.pro_poor_pop)
      
      UIComponent(context.component):SetTooltipText("Your combined "..UI_data_table.col_yellow_open..UI_data_table.mid_pop_name ..UI_data_table.col_yellow_close.." and "..UI_data_table.col_yellow_open..UI_data_table.low_pop_name ..UI_data_table.col_yellow_close.." population in the province.\n\n"..UI_data_table.mid_pop_name..": "..UI_data_table.col_yellow_open..pop1..UI_data_table.col_yellow_close.."\n"..UI_data_table.low_pop_name..": "..UI_data_table.col_yellow_open..pop2..UI_data_table.col_yellow_close)
      
    end
  end

  if context.string == "icon_zeal" 
  then 
  
    local text = UIComponent(context.component):GetTooltipText()
    local string = UI_data_table.zealous_string
    
    if string.find(text, string) or string.find(text, "Second Class")
    then
    
      UIComponent(context.component):SetTooltipText("Your "..UI_data_table.col_yellow_open ..UI_data_table.foreign_pop_name..UI_data_table.col_yellow_close.. " population in the province.") --..UI_data_table.col_yellow_open ..UI_data_table.foreign_pop_name..UI_data_table.col_yellow_close.." growth rates are heavily influenced by migration")
  
    end
  end


  if context.string == "dy_zeal" -- or "dy_command" vanilla mistake
  then  
    
    local text = UIComponent(context.component):GetTooltipText()
    local string = UI_data_table.authoritarian_string

    if string.find(text, string) or string.find(text, "Second Class")
    then
      
      UIComponent(context.component):SetTooltipText("Your "..UI_data_table.col_yellow_open ..UI_data_table.foreign_pop_name..UI_data_table.col_yellow_close.. " population in the province.")--..UI_data_table.col_yellow_open ..UI_data_table.foreign_pop_name..UI_data_table.col_yellow_close.." growth rates are heavily influenced by migration")
           
    end
  end

  if context.string == "dy_prosperity"
  then
  
    local y_o = UI_data_table.col_yellow_open
    local y_c = UI_data_table.col_yellow_close
    local space = UI_data_table.double_dot_space
    local line = UI_data_table.new_line 
    local noble_class = UICommaValue(UI_data_table.faction_population_1)
    local citizens_class = UICommaValue(UI_data_table.faction_population_2)
    local poor_class = UICommaValue(UI_data_table.faction_population_3)
    local foreign_class = UICommaValue(UI_data_table.faction_population_4)
    local population = UICommaValue(UI_data_table.faction_population)
    
    UIComponent(context.component):SetTooltipText("Total Population by class: ||" .. UI_data_table.noble_pop_name .. space .. y_o.. noble_class ..y_c.. line .. UI_data_table.mid_pop_name .. space ..y_o.. citizens_class ..y_c.. line .. UI_data_table.low_pop_name .. space ..y_o.. poor_class ..y_c ..line .. UI_data_table.foreign_pop_name .. space..y_o.. foreign_class ..y_c.. line.. UI_data_table.underline .. UI_data_table.text_total_population ..y_o.. population..y_c) 

  end
  
  if context.string == "tx_prosperity"
  then
  
    UIComponent(context.component):SetTooltipText("This value is the accumalted manpower available to your faction from all its territories.") -- make it a var in the UI table 

  end
end


-- ***** REC LISTENER CHECK NAVY ***** --

function RecListenerCheckNavy(force)

  if force:is_navy()
  then
  
    return true
    
  else

    return false
    
  end
end


-- ***** SET CLASS POP ***** --

function setClassPop()

  if current_character == nil
  then
  
    -- PopLog("Character is Gone - Prevent Crash", "setClassPop()")
    
    return
    
  end 

  if RecListenerCheckNavy(current_character:military_force())
  then
  
    local faction = current_character:faction()
    local factionName = faction:name()
    local x, y = current_character:logical_position_x(), current_character:logical_position_y()
    local region_name = getClosestPortRegion(x, y, faction) -- faction:home_region():name() >>> in theory get closest port
    
    UI_data_table.curr_region_name = region_name
    UI_data_table.curr_faction_class_id = UIGarrisonFactionNameToClass(factionName)
  
    UIRetrievePopulationClasses()
    
  else
  
    local region = current_character:region()
    local region_name = region:name()
    local factionName = region:garrison_residence():faction():name()
    
    UI_data_table.curr_region_name = region_name
    UI_data_table.curr_faction_class_id = UIGarrisonFactionNameToClass(factionName)
    
    UIRetrievePopulationClasses()
    
  end     
end


-- ***** SET CLASS POP ***** --
-- UI function called on shortcut triggered or recruitment button clicked and after recruitment issued, will keep the recruitment panel up to date

function UIManpowerCostTooltip(context)

  local list_box = UIComponent(scripting.m_root:Find("list_box"))
  
  if not list_box
  then
  
    return
    
  end

  local factionName = UIGetLocalFactionName()         
  local recruitableUnitCount = list_box:ChildCount()
  
  if recruitableUnitCount == nil
  then
  
    return
    
  end
  
  local recruitableUnitList = {} -- add them into a list
  
  setClassPop()

  for i = 0, recruitableUnitCount - 1
  do
  
    local recruitableUnit = UIComponent(list_box:Find(i)):Id()
    
    if string.find(recruitableUnit, "_recruitable")
    then
    
      table.insert(recruitableUnitList, recruitableUnit)
      
    end
  end

  for key, recruitableUnit in ipairs(recruitableUnitList)
  do
  
    local UnitCard_uic = UIGetComponent("list_box", recruitableUnit)
  
    Log("Start")
    
    local cardKey = string.gsub(recruitableUnit, "_recruitable", "")
    
    Log("cardKey:"..cardKey)
    
    local classKey = UIRetrieveClass(cardKey, factionName)
    
    Log("classKey:"..classKey)
    
    if classKey == 0
    then
    
      UIComponent(UnitCard_uic):SetTooltipText("Error Unit has no class key assigned!")
      
    elseif classKey > 0
    then
    
      local ManpowerCosts = UIRetrieveunitcosts(cardKey, classKey) 
      
      UIDisplayClass(classKey)
      
      local ManpowerAvailable = UIGetClassManpower(cardKey, factionName)
      local RegionDisplay = region_name_table[UI_data_table.curr_region_name]
      local text = UIComponent(UnitCard_uic):GetTooltipText()
      local endString = UI_data_table.recruit_unit_string
      
      text = string.gsub(text, endString, "")

      if ManpowerAvailable >= ManpowerCosts
      then
      
        UIComponent(UnitCard_uic):SetOpacity(250)
        UIComponent(UnitCard_uic):SetTooltipText(text.."\n\n"..UI_data_table.col_yellow_open.."Region: "..RegionDisplay..UI_data_table.col_yellow_close.."\n"..UI_data_table.unit_card_pop_cost_text..UI_data_table.col_green_open..ManpowerCosts.." "..UI_data_table.unit_class_name..UI_data_table.col_green_close.."\n"..UI_data_table.unit_class_name_available..UI_data_table.col_yellow_open..ManpowerAvailable..UI_data_table.col_yellow_close..UI_data_table.unit_card_flavour_text)
      
      end

      if ManpowerAvailable < ManpowerCosts
      then 
      
        UIComponent(UnitCard_uic):SetDisabled(true)
        UIComponent(UnitCard_uic):SetTooltipText(text.."\n\n"..UI_data_table.col_yellow_open.."Region: "..RegionDisplay..UI_data_table.col_yellow_close.."\n"..UI_data_table.col_red_open..UI_data_table.unit_card_more_pop_needed..UI_data_table.col_red_close..UI_data_table.unit_card_pop_cost_text..UI_data_table.col_green_open..ManpowerCosts.." "..UI_data_table.unit_class_name..UI_data_table.col_green_close.."\n"..UI_data_table.unit_class_name_available..UI_data_table.col_yellow_open..ManpowerAvailable..UI_data_table.col_yellow_close..UI_data_table.unit_card_flavour_text)
        UIComponent(UnitCard_uic):SetOpacity(120)
        
      end
    end
  end
end


-- ***** UI ENABLE QUEUED UNIT TOOLTIPS ***** --

function UIEnableQueuedUnitTooltips(context)

  local component = string.find(context.string, "QueuedLandUnit ")
  
  if component
  then
    
    local factionName = UIGetLocalFactionName()
    local queueID = tonumber(string.sub(context.string, 16)) + 1
    local queuedUnitName =  recruitmentOrders[tostring(current_character:cqi())][queueID]
    local queuedUnitClass = UIRetrieveClass(queuedUnitName, factionName)
    local queuedUnitCosts = RecListenerRetrieveunitcosts(queuedUnitName, queuedUnitClass)
    local text = "Left-click to remove unit from recruitment queue.\n\nThis will return " .. UI_data_table.col_yellow_open .. queuedUnitCosts .. UI_data_table.col_yellow_close .. " manpower back into this regions pool."     
      
    UIComponent(context.component):SetTooltipText(text)
    
  end
end


-- ***** ON TIME TRIGGER ***** --
-- functions called on time trigger, required for some UI changes to work

local function OnTimeTrigger(context) 

  if (context.string == "hide_panel")
  then
  
    UIManpowerCostTooltip(context) 
    
  end 

-- removed: DeI_127 new UI interface

--  if (context.string == "Change_Growth_Bar")
--  then
  
--    ChangeGrowthBar(context)   

--  end 

  if (context.string == "hide_panel_mercs")
  then
  
    Mercs_Levies_UIManpowerCosts(context) 
    
  end
  
  if (context.string == "popuihovertext_mercs")
  then
  
    RecListenerAddUnitTablePopUIMERC(context) 
    
    Debug ("Merc Hire button hit - trigger pop ui hover change")
  end
  
  if (context.string == "units_created")
  then
  
    Merc_Levy_RecListenerUnitsCreated(context)
    
  end

  if (context.string == "units_disbanded")
  then
  
    RecListenerDisbandUnits(context) 
    
  end

  if (context.string == "Change_Details")
  then
  
    UIChangeProvinceDetailsOnTimeTrigger(context)
    
  end

  if (context.string == "Move_Icons")
  then
  
    UIMoveProvinceIconsOnTimeTrigger(context)
    
  end;

  if (context.string == "Change_Pop")
  then
  
    UIChangeOnTimeTrigger(context)
    
  end

  if (context.string == "Show_Total_Pop")
  then
  
    UIRetrieveFactionPop(context)
    
  end;
end;


-- ***** ON SHORTCUT TRIGGERED ***** --
-- will call UI function

local function OnShortcutTriggered(context)

  if context.string == "show_recruitment_units"
  then
  
    scripting.game_interface:add_time_trigger("hide_panel", 0.1)
    
    local regionName = current_character:region():name()
    
    for i =1, 4
    do
    
      ui_merc_levy_region_table[i] = UIPopulation[regionName][i]
      
    end
    
  scripting.game_interface:add_time_trigger("hide_panel_mercs", 0.1)
  
  end

  if context.string == "show_recruitment_agents"
  then
  
    local regionName = current_character:region():name()
    
    for i =1, 4
    do
    
      ui_merc_levy_region_table[i] = UIPopulation[regionName][i]
      
    end
    
  scripting.game_interface:add_time_trigger("hide_panel_mercs", 0.1)
  
  end
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- FUNCTIONS  ---------------------------------------------------------------------

-- RecListenerCheckUnitPercentageCosts
-- RecListenerRetrieveunitcosts
-- RecListenerDisbandUnits
-- RecListenerRemovePop

-- #####-------------------------


-- ***** REC LISTENER REMOVE POP ***** --

function RecListenerRemovePop(regionName, unitKey, factionName)

  local class = UIRetrieveClass(unitKey, factionName)
  local costs = RecListenerRetrieveunitcosts(unitKey, class)
  
  UIPopulation[regionName][class] = UIPopulation[regionName][class] - costs
  
end


-- ***** REC LISTENER CHECK UNIT PERCENTAGE COSTS ***** --

function RecListenerCheckUnitPercentageCosts(unit_name, class, percentage_proportion_of_full_strength)

  local set_unit_costs = 0
  
  if class >= 1
  and class < 5
  then 
  
    set_unit_costs = unit_to_pop_table[unit_name][3]
    set_unit_costs = math.ceil(set_unit_costs*(percentage_proportion_of_full_strength/100))
    Debug("Disband Unit Size"..set_unit_costs)
    return set_unit_costs
  
  end
end


-- ***** REC LISTENER RETRIEVE UNIT COSTS ***** --
-- returns the manpower costs of by unit key

function RecListenerRetrieveunitcosts(unitKey, class)

  local set_unit_costs = 0
  
  if class >= 1
  and class < 5
  then 
  
    set_unit_costs = unit_to_pop_table[unitKey][3]
    
    return set_unit_costs
    
  end
end     


-- ***** CHECK ARMY STILL EXISTS ***** --

function CheckArmystillexists()

  Debug("Start Disband Listener")
  
  local factionName = UIGetLocalFactionName()
  local faction = scripting.game_interface:model():world():faction_by_key(factionName)
  
  if faction:is_human()
  then -- maybe time trigger ?
  
    for char = 0, faction:character_list():num_items() - 1
    do

      local curr_char = faction:character_list():item_at(char)
      local curr_cqi = curr_char:cqi()
    
      Debug("CQI:"..curr_cqi)
  
      if disband_unit_table[tostring(curr_cqi)]
      then
  
        Debug("Army still exists "..curr_cqi)
        
        return true
        
      end
    end
    
    Debug("Army does not exist any more") 
    
    current_character = nil 
    
    return false 
    
  end
end


-- ***** REC LISTENER DISBAND UNITS ***** --

function RecListenerDisbandUnits(context)

  Debug("RecListenerDisbandUnits")
  
  local ArmyExists = CheckArmystillexists()
  
  Debug("RecListenerDisbandUnits - ArmyExists")
  
  local factionName = UIGetLocalFactionName()
  
  Debug("RecListenerDisbandUnits - "..factionName)
  
  if ArmyExists
  then
  
    local char = current_character
    local cqi = char:cqi()
    local regionName = ""
    Debug("Army Exists")
    
  if current_character:military_force():is_navy()
  then 
  
    local x, y = current_character:logical_position_x(), current_character:logical_position_y()
    
    regionName = getClosestPortRegion(x, y, current_character:faction()) 
    
  else
  
    regionName = current_character:region():name()
    
  end 
  
  local force = char:military_force()
  
  for i = 0, force:unit_list():num_items() - 1
  do
  
    local unit = force:unit_list():item_at(i)
    local unit_key = unit:unit_key()
    local unit_strenght = unit:percentage_proportion_of_full_strength()
    
    for _, v in pairs(disband_unit_table[tostring(cqi)])
    do
  
      if unit_key == v[1]
      and unit_strenght == v[2]
      then
    
        disband_unit_table[tostring(cqi)][_] = {nil, nil, nil}
      
        Debug("Unit Key remove from table ".. _ .."  "..unit_key)
        Debug("Unit Size " .. tostring(unit_strenght))
      
        break 
      
      end     
    end
  end

  for i,value in pairs(disband_unit_table[tostring(cqi)])
  do
    
    if value[1] ~= nil 
    then
    
      local unit_name = value[1]
      local class = UIRetrieveClass(unit_name, factionName)
      
      for v,mercenary in pairs (mercenary_units_table)
      do 
      
        if mercenary == unit_name
        then
        
          class = Mercs_Levies_GetClass(unit_name, char)
          
          break
          
          end
        end
      
        local costs = RecListenerCheckUnitPercentageCosts(unit_name, class, value[2])
      
        Debug("Add pop for cqi: "..cqi.. " : ".. unit_name .. "  Class:  " .. class .. " Costs: " .. costs)
      
        UIPopulation[regionName][class] = UIPopulation[regionName][class] + costs
        
        Debug("Add "..costs.." from class "..class.." to "..regionName)
      
      end
    end
  
    disband_unit_table = {} 
  
  end

  if not ArmyExists
  then
  Debug("Army Does Not Exist")
    for i,v in pairs(disband_unit_table)
    do
    
      if disband_unit_table[tostring(i)]
      then
      
        for k, value in pairs(disband_unit_table[tostring(i)])
        do
        
          local unit_name = value[1]
          local class = UIRetrieveClass(unit_name, factionName)
          
          -- for i, unit in pairs (mercenary_units_to_faction_class[class_key]) do
          -- if unit == unit_key  
          -- then class = UIRetrieveClass(unit_key, unit_to_pop_table)
          -- end
          -- end
          
          local costs = RecListenerCheckUnitPercentageCosts(unit_name, class, value[2])
          
          Debug("Add pop for: ".. unit_name .. "  Class:  " .. class .. " Costs: " .. costs.. "for region: "..value[3])
          
          UIPopulation[value[3]][class] = UIPopulation[value[3]][class] + costs
          
        end
      end
    end
  end
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- EVENT FUNCTIONS REC LISTENER  ---------------------------------------------------------------------

-- RecListenerUnitClicked
-- RecListenerArmyUnitCounterEnd
-- RecListenerArmyUnitCounterStart
-- RecListenerGetCharacter
-- RecListenerRecruitmentIssuedByPlayer
-- RecListenerAddUnitTable
-- RecListenerCancel
-- RecListenerAcceptDisband

-- #####-------------------------


-- ***** REC LISTENER UNIT CLICKED ***** --
-- rec Listener on Component clicked, this way I can stop fast clicking by disabling the card after click and enabling or permantley disabling it on recitemissued

local function RecListenerUnitClicked(context)

  local component = UIComponent(context.component):Id()
  local unitKey = ""
  local isRecruitedUnit = string.find(component, "_recruitable")
  
  if isRecruitedUnit
  and UIComponent(context.component):CurrentState() == "active" 
  then
  
    unitKey = string.gsub(component, "_recruitable", "")
    
    local factionName = UIGetLocalFactionName()
    local regionName = ""
    
    if current_character:military_force():is_navy()
    then 
      
      local x, y = current_character:logical_position_x(), current_character:logical_position_y()
      
      regionName = getClosestPortRegion(x, y, current_character:faction()) 
      
    else
    
      regionName = current_character:region():name() -- make sure navies remove pop from capital

    end;
  
    local class = UIRetrieveClass(unitKey, factionName)
  
    Log("class: "..class)
  
    local costs = RecListenerRetrieveunitcosts(unitKey, class)
  
    Log("costs: "..costs)
  
    UIPopulation[regionName][class] = UIPopulation[regionName][class] - costs 
  

    if not recruitmentOrders[tostring(current_character:cqi())]
    then
  
      Log("New table recruitmentOrders: "..current_character:cqi()) recruitmentOrders[tostring(current_character:cqi())] = {}
    
    end
  
    table.insert(recruitmentOrders[tostring(current_character:cqi())], unitKey)
  
    Log("add unit to recruitmentOrders: "..unitKey)
  
    UIComponent(context.component):SetDisabled(true)
  
  end
end


-- ***** REC LISTENER ARMY UNIT COUNTER END ***** --
-- get size of the army at turn end

local function RecListenerArmyUnitCounterEnd(context)

  if context:faction():is_human()
  then
    
    Log("RecListenerArmyUnitCounterEnd")
    
    local armylist = context:faction():military_force_list()
    
    for i = 0, armylist:num_items() -1
    do
    
      local army = armylist:item_at(i)
      
      if army:is_army()
      or army:is_navy()
      then
      
        local army_cqi = army:general_character():cqi()
        
        Log("CQI: "..army_cqi) 
        
        local x = army:general_character():logical_position_x()
        local y = army:general_character():logical_position_y()
        local char_army_size = army:unit_list():num_items()
        
        army_size_cqi[tostring(army_cqi)] = {x..y, char_army_size}
        
        Log("Save Coordinates: "..x..y.." save army size: "..char_army_size.." for CQI: "..army_cqi)
        
      end
    end             
  end
end


-- ***** REC LISTENER ARMY UNIT COUNTER START ***** --
-- get size of the army at turn start and remove newly recruited units from recruitmentOrders

local function RecListenerArmyUnitCounterStart(context)

  if context:faction():is_human()
  then
  
    Debug("RecListenerArmyUnitCounterStart")  
    
    local deleteQueueLength = 0 
    local armylist = context:faction():military_force_list()
    
    for i = 0, armylist:num_items() -1
    do
    
      local army = armylist:item_at(i)
      local army_cqi = army:general_character():cqi() 
      
      Debug("CQI: "..army_cqi)
      
      if army:is_army()
      or army:is_navy()
      and recruitmentOrders[tostring(army_cqi)]
      and army_size_cqi[tostring(army_cqi)]
      then
      
        local x = army:general_character():logical_position_x()
        local y = army:general_character():logical_position_y()

        Debug("CQI is saved in recruitmentOrders : "..army_cqi)
        
        local char_army_size = army:unit_list():num_items()   
        
        if x..y ~= army_size_cqi[tostring(army_cqi)][1]
        then
        
          Debug("Position changed remove recruitmentOrders: "..army_cqi)
          
          recruitmentOrders[tostring(army_cqi)] = nil 
          
        end;

        if char_army_size == army_size_cqi[tostring(army_cqi)][2]
        then
        
          Debug("Army size is the same char_army_size: "..char_army_size)

        elseif char_army_size > army_size_cqi[tostring(army_cqi)][2]
        then
        
          Debug("Army size is bigger than before: "..char_army_size) 
          
          deleteQueueLength = char_army_size - army_size_cqi[tostring(army_cqi)][2]
          
          Debug("deleteQueueLength: "..deleteQueueLength)

          local unitQueueLength = #recruitmentOrders[tostring(army_cqi)]
          
          Debug("unitQueueLength: "..tostring(unitQueueLength))
          
          for j = 1, math.min(deleteQueueLength, unitQueueLength)
          do
          
            Debug("removing queued unit "..tostring(j))
            
            table.remove(recruitmentOrders[tostring(army_cqi)], j)
            
          end;
        end;
      end;
    end;
  end;
end;


-- ***** REC LISTENER GET CHARACTER ***** --
-- get current character and his army list

local function RecListenerGetCharacter(context) 

  current_character = context:character()

end


-- ***** REC LISTENER RECRUITMENT ISSUED BY PLAYER ***** --
-- removes population after recruitment issued by player, adds unit to recruitmentOrders table

local function RecListenerRecruitmentIssuedByPlayer(context)

  scripting.game_interface:add_time_trigger("hide_panel", 0.2)
  
end


-- ***** REC LISTENER ADD UNIT TABLE ***** --

local function RecListenerAddUnitTable(context)

  if (context.string == "button_disband")
  then
  
    Debug("Button Disband hit")
    
    local force = current_character:military_force()
    local cqi = current_character:cqi()
    local regionName = ""
    
    --if force:is_navy() then make region to home region
    
    if current_character:military_force():is_navy()
    then 
    
      local x, y = current_character:logical_position_x(), current_character:logical_position_y()
      
      regionName = getClosestPortRegion(x, y, current_character:faction())
      
    else
    
      regionName = current_character:region():name()
      
    end 
    
    for i = 0, force:unit_list():num_items() - 1
    do
    
      local unit = force:unit_list():item_at(i)
      local unit_key = unit:unit_key()
      local unit_strenght = unit:percentage_proportion_of_full_strength()
      
      if not disband_unit_table[tostring(cqi)]
      then
      
        disband_unit_table[tostring(cqi)] = {}
      
      end
    
      disband_unit_table[tostring(cqi)][i] = {unit_key, unit_strenght, regionName} 
    
    end
  end
end

-- *********** POP UI UNIT HOVER REC LISTENER--
-- Creates a unit list when an army/character is selected for reference by the following UI function

pop_ui_hover_unit_table = {}

local function RecListenerAddUnitTablePopUI(context)

    Debug("RecListenerAddUnitTablePopUI")
    
  pop_ui_hover_unit_table = {}
  
  if current_character:faction():is_human()
    
    then
    
    local force = current_character:military_force()
    local cqi = current_character:cqi()
    local regionName = ""
    local factionName = UIGetLocalFactionName()
    
    --if force:is_navy() then make region to home region
    
    if current_character:military_force():is_navy()
    then 
    
      local x, y = current_character:logical_position_x(), current_character:logical_position_y()
      
      regionName = getClosestPortRegion(x, y, current_character:faction())
      
    else
    
      regionName = current_character:region():name()
      
    end 
    
    setClassPop()
    
    for i = 0, force:unit_list():num_items() - 1
    do
      
      local unit = force:unit_list():item_at(i)
      local unit_key = unit:unit_key()
      
      
      Debug("PopUnitUIHover "..unit_key.." working")
      
      table.insert(pop_ui_hover_unit_table, unit_key)
      
      Debug("PopUnitUIHover "..unit_key.." inserted into Pop UI table")
      
      
    end
  end 
end


function RecListenerAddUnitTablePopUIMERC(context)

    Debug("RecListenerAddUnitTablePopUI")
    
  pop_ui_hover_unit_table = {}
  
  if current_character:faction():is_human()
    
    then
    
    local force = current_character:military_force()
    local cqi = current_character:cqi()
    local regionName = ""
    local factionName = UIGetLocalFactionName()
    
    --if force:is_navy() then make region to home region
    
    if current_character:military_force():is_navy()
    then 
    
      local x, y = current_character:logical_position_x(), current_character:logical_position_y()
      
      regionName = getClosestPortRegion(x, y, current_character:faction())
      
    else
    
      regionName = current_character:region():name()
      
    end 
    
    setClassPop()
    
    for i = 0, force:unit_list():num_items() - 1
    do
      
      local unit = force:unit_list():item_at(i)
      local unit_key = unit:unit_key()
      
      
      Debug("PopUnitUIHover "..unit_key.." working")
      
      table.insert(pop_ui_hover_unit_table, unit_key)
      
      Debug("PopUnitUIHover "..unit_key.." inserted into Pop UI table")
      
      
    end
  end 
end


-- Hover tooltip for Pop Unit card UI

function UIEnablePopHoverUnitTooltips(context)

local component = string.find(context.string, "LandUnit ")
      
  if component
      
    then
    
    local factionName = UIGetLocalFactionName()
    local popuiID = tonumber(string.sub(context.string, 10)) + 1
    local popUnitName =  pop_ui_hover_unit_table[popuiID]
    local popUnitClass = UIRetrieveClass(popUnitName, factionName)
    local popUnitCosts = RecListenerRetrieveunitcosts(popUnitName, popUnitClass)
    local originaltext = UIComponent(context.component):GetTooltipText()
    local unitcardendstring = UI_data_table.uiunitcard_unit_string
    local changedoriginaltext = string.gsub(originaltext, unitcardendstring, "")
    
    if popUnitClass > 0 and not string.find(originaltext, "Class: ")
    
      then
      
      if string.find(popUnitName, "MERC_")
        
        then
        
        popUnitClass = MERC_GetClass(popUnitName, factionName) 
        addontextpopuicard = UI_data_table.PoR2_popuihovertextmerc
      
      
      elseif string.find(popUnitName, "Aux")
      
        then
        
        addontextpopuicard = UI_data_table.PoR2_popuihovertextaux
      
      
      elseif string.find(popUnitName, "AOR_")
      
        then
        
        addontextpopuicard = UI_data_table.PoR2_popuihovertextaor
      
      
      else
        
        addontextpopuicard = UI_data_table.PoR2_popuihovertextcore
      
      end
      
    UI_data_table.curr_faction_class_id = UIGarrisonFactionNameToClass(factionName);
    
    UIDisplayClass(popUnitClass);
    
    local classname = UI_data_table.unit_class_name
    local classtext = UI_data_table.PoR2_popuihovertext
    local manpowertext = UI_data_table.PoR2_popuihovertext1 
    
    local text = changedoriginaltext..classtext..classname..manpowertext..popUnitCosts..addontextpopuicard
      
      
    UIComponent(context.component):SetTooltipText(text)
    
        
    end
    
    
  end

end

-- ***** MERC LOCAL CLASS ***** --
-- MERC units are handled by faction key
-- local MERC troops will cost local population if they match the culture 
-- of the owning faction, first we retrieve the index key for the table
-- containing the unit lists

function MERC_LocalClass(factionName)

  if not mercenary_faction_class_table[factionName]
  then 
  
    return "default_mercs"
    
  end

  if mercenary_faction_class_table[factionName]
  then
  
    return mercenary_faction_class_table[factionName]
    
    end
end


-- ***** MERC GET CLASS ***** --
-- the table index is now used to loop through the table if the 
-- unit key is in the table local population is used, otherwise
-- class 4 population is default!

function MERC_GetClass(popUnitName, factionName)

  local popUnitClass = 4
  local classKey = MERC_LocalClass(factionName)

  for i, unit in pairs (mercenary_units_to_faction_class[classKey])
  do
  
    if unit == popUnitName  
    then
    
      popUnitClass = unit_to_pop_table[popUnitName][1]
      
      return popUnitClass
      
    end
  end
  
  return popUnitClass
  
end

-- ***** REC LISTENER CANCEL ***** --
-- thanks to causless for sharing his code and explaining to me how he got canceling units to work

local function RecListenerCancel(context)

  local component = string.find(context.string, "QueuedLandUnit ")

  if component
  then
  
    scripting.game_interface:add_time_trigger("hide_panel", 0.1)
    scripting.game_interface:add_time_trigger("hide_panel_mercs", 1) 
    
    local regionName = ""
    local factionName = UIGetLocalFactionName()

    if RecListenerCheckNavy(current_character:military_force())
    then
    
      local x, y = current_character:logical_position_x(), current_character:logical_position_y()
      
      regionName = getClosestPortRegion(x, y, current_character:faction()) 
      
    else
    
      regionName = current_character:region():name() 
      
    end; 

    local queueID = tonumber(string.sub(context.string, 16)) + 1
    
    Log("queueID: "..queueID)
    
    local queuedUnitName =  recruitmentOrders[tostring(current_character:cqi())][queueID]
    
    Log("queuedUnitName: "..queuedUnitName)
    
    local queuedUnitClass = UIRetrieveClass(queuedUnitName, factionName)
    
    Log("queuedUnitClass: "..queuedUnitClass)
  
    local queuedUnitCosts = RecListenerRetrieveunitcosts(queuedUnitName, queuedUnitClass)
    
    Log("queuedUnitCosts: "..queuedUnitCosts)
    
    table.remove(recruitmentOrders[tostring(current_character:cqi())], queueID)
    
    Log("remove unit from recruitmentOrders: "..queuedUnitName)
    
    UIPopulation[regionName][queuedUnitClass] = UIPopulation[regionName][queuedUnitClass] + queuedUnitCosts
    
  end;
end;


-- ***** REC LISTENER CANCEL ***** --
-- on button tick 

local function RecListenerAcceptDisband(context)

  Debug("RecListenerAcceptDisband")
  
  local component = UIComponent(context.component):Id()
  
  if current_character
  and component == "button_tick"
  then 
  
    local tooltip = UIComponent(context.component):GetTooltipText()
    
    if tooltip == UI_data_table.button_tick_accept_string
    then
    
      Debug("RecListenerAcceptDisband trigger units_disbanded")
      
      scripting.game_interface:add_time_trigger("units_disbanded", 0.5) 
      scripting.game_interface:add_time_trigger("hide_panel", 0.7)
      
    elseif tooltip == UI_data_table.button_tick_cancel_string
    then
    
      disband_unit_table = {}
      
    end
  end
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- MERC LEVIES SCRIPTS  ---------------------------------------------------------------------

-- Mercs_Levies_RemovePop
-- Mercs_Levies_LocalClass
-- Mercs_Levies_GetClass
-- Mercs_Levies_UIManpowerCosts
-- Merc_Levy_RecListenerUnitsCreated
-- Merc_Levy_AddUnitTable
-- Merc_Levy_RecListenerAddUnitTable
-- Merc_Levy_ListenerCancel
-- Merc_Levy_RecListenerAcceptHire

-- #####-------------------------


-- ***** MERCS LEVIES REMOVEPOP ***** --

function Mercs_Levies_RemovePop(regionName, unit_key)

  local class = Mercs_Levies_GetClass(unit_key, current_character)
  local costs = Mercs_Levies_UnitCosts(unit_key, class)
  
  UIPopulation[regionName][class] = UIPopulation[regionName][class] - costs
  
end


-- ***** MERCS LEVIES REMOVE POP ***** --

function Mercs_Levies_LocalClass(faction)

  if mercenary_faction_class_table[faction]
  then
    
    return mercenary_faction_class_table[faction]
    
  else
  
    return "default_mercs"
    
  end
end


-- ***** MERCS LEVIES GET CLASS ***** --

function Mercs_Levies_GetClass(unit_key, curr_char)

  local class = 4 
  local factionName = curr_char:faction():name()
  local class_key = Mercs_Levies_LocalClass(factionName)

  for i, unit in pairs (mercenary_units_to_faction_class[class_key])
  do
  
    if unit == unit_key  
    then
    
      class = UIRetrieveClass(unit_key, curr_char:faction():name())
      
      return class
      
    end
  end
  
  return class
  
end


-- ***** MERCS LEVIES UNIT COSTS ***** --

function Mercs_Levies_UnitCosts(unit_name, class)

  local set_unit_costs = 0
  
  if class >= 1
  and class < 5
  then 
  
    set_unit_costs = unit_to_pop_table[unit_name][3]
    
    return set_unit_costs 
    
  end
end


-- ***** MERCS LEVIES UNIT COSTS ***** --
-- UI function called on shortcut triggered or recruitment button clicked and after recruitment issued, will keep the recruitment panel up to date

function Mercs_Levies_UIManpowerCosts(context)

  local list_box = UIComponent(scripting.m_root:Find("list_box"))
  
  if not list_box
  then 
  
    return

  end

  local recruitableUnitCount = list_box:ChildCount()
  
  if recruitableUnitCount == nil
  then
  
    return
    
  end
  
  setClassPop()

  for i = 0, recruitableUnitCount - 1
  do
  
    local recruitableUnit = UIComponent(list_box:Find(i)):Id()
    
    if string.find(recruitableUnit, "_mercenary")
    then
    
    local unit_card = UIComponent(list_box:Find(i))
    local name = string.gsub(recruitableUnit, "_mercenary", "")
    local class_number = Mercs_Levies_GetClass(name, current_character)
    local unit_costs = Mercs_Levies_UnitCosts(name, class_number)
    
    UIDisplayClass(class_number)
    
    local ManpowerAvailable = UIGetMercClassManpower(class_number)
    local text = unit_card:GetTooltipText()

      if string.find(text, UI_data_table.cannot_recruit_string)
      then 
      
        unit_card:SetDisabled(true)
        unit_card:SetOpacity(120)
        
      end

      local endString = UI_data_table.hire_mercs_string
      local UnitName = string.gsub(text, endString, "")
      local RegionDisplay = region_name_table[UI_data_table.curr_region_name]

      if string.find(text, UI_data_table.hire_mercs_string)
      then
      
        unit_card:SetOpacity(250)
        
      end      

      if ManpowerAvailable >= unit_costs
      then 
      
        unit_card:SetOpacity(250)                                                       
        unit_card:SetTooltipText(UnitName.."\n\n"..UI_data_table.col_yellow_open.."Region: "..RegionDisplay..UI_data_table.col_yellow_close.."\n"..UI_data_table.unit_card_pop_cost_text..UI_data_table.col_green_open..unit_costs.." "..UI_data_table.unit_class_name..UI_data_table.col_green_close.."\n"..UI_data_table.unit_class_name_available..UI_data_table.col_yellow_open..ManpowerAvailable..UI_data_table.col_yellow_close..UI_data_table.unit_card_flavour_text)
    
      end

      if ManpowerAvailable < unit_costs
      then 
      
        unit_card:SetDisabled(true)
        unit_card:SetTooltipText(UnitName.."\n\n"..UI_data_table.col_yellow_open.."Region: "..RegionDisplay..UI_data_table.col_yellow_close.."\n"..UI_data_table.col_red_open..UI_data_table.unit_card_more_pop_needed..UI_data_table.col_red_close..UI_data_table.unit_card_pop_cost_text..UI_data_table.col_green_open..unit_costs.." "..UI_data_table.unit_class_name..UI_data_table.col_green_close.."\n"..UI_data_table.unit_class_name_available..UI_data_table.col_yellow_open..ManpowerAvailable..UI_data_table.col_yellow_close..UI_data_table.unit_card_flavour_text)
        unit_card:SetOpacity(120)
        
      end
    end
  end
end


-- ***** MERC LEVY REC LISTENER UNITS CREATED ***** --
-- check if current char army list is bigger than before

function Merc_Levy_RecListenerUnitsCreated(context)

  if TableisEmpty(Merc_Levy_recruitmentOrders)
  then
  
    return

  end
  
  if TableisEmpty(char_merc_levy_units)
  then
  
    return
    
  end

  local new_merc_levy_units = {}  
  
  if current_character:military_force():unit_list():num_items() > 1
  then 
  
    -- PopLog("Create unit table for NEW mercs")
  
    local regionName = current_character:region():name()
    local force = current_character:military_force()
    
    for i = 0, force:unit_list():num_items() - 1
    do
    
      local unit = force:unit_list():item_at(i)
      local unit_key = unit:unit_key()
      
      new_merc_levy_units[i] = unit_key
      
    end

    -- PopLog("Check old and new table against each other")
    for i = 0, current_character:military_force():unit_list():num_items() - 1
    do 
    
      local key = new_merc_levy_units[i] 
      
      -- PopLog("Check Unit key:  "..key)
      
      for x = 0, current_character:military_force():unit_list():num_items() - 1
      do 
      
        if key == char_merc_levy_units[x]
        then
        
          new_merc_levy_units[i] = nil  
          
          -- PopLog("Removed:  "..key) 
          
          break
          
          -- char_merc_levy_units[x] = nil
          
        end     
      end
    end

    -- PopLog("Start check: Remaining units")
    
    for i,value in pairs(new_merc_levy_units)
    do   
    
      if value ~= nil
      then
      
        local unit_key = value
        
        -- PopLog("Remaining units: "..unit_key)
        
        Mercs_Levies_RemovePop(regionName, unit_key)
        
        -- PopLog("Add pop for: ".. unit_key .. "  Class:  " .. class .. " Costs: " .. costs)
        
      end
    end

    -- synch table
    
    for i = 1, 4
    do
    
      UIPopulation[regionName][i] = ui_merc_levy_region_table[i]
      
    end

    char_merc_levy_units = {} 
    Merc_Levy_recruitmentOrders = {} 
    
  end
end


-- ***** MERC LEVY ADD UNIT TABLE ***** --
-- add units to table

function Merc_Levy_AddUnitTable()

  local force = current_character:military_force()
  
  for i = 0, force:unit_list():num_items() - 1
  do
  
    local unit = force:unit_list():item_at(i)
    local unit_key = unit:unit_key()
    
    -- PopLog("Create ".. i .. "unit: " .. unit_key .. " table for mercs")
    
    char_merc_levy_units[i] = unit_key
    
  end
end


-- ***** MERC LEVY REC LISTENER ADD UNIT TABLE ***** --
-- check army size on button pressed (mercenaries or client levies)

local function Merc_Levy_RecListenerAddUnitTable(context)

  if (context.string == "button_mercenaries")
  then
  
    local regionName = current_character:region():name()
    
    for i =1, 4
    do
    
      ui_merc_levy_region_table[i] = UIPopulation[regionName][i]
      
      -- PopLog("Fill region table: ".. i .. " : "..UIPopulation[regionName][i])
      
    end
    
    scripting.game_interface:add_time_trigger("hide_panel_mercs", 0.1)
    
  end

  if (context.string == "button_setrapy")
  then
  
    local regionName = current_character:region():name()
    
    for i =1, 4
    do
    
      ui_merc_levy_region_table[i] = UIPopulation[regionName][i]
      -- PopLog("Fill region table: ".. i .. " : "..region_table[regionName][i])
      
    end
    
    scripting.game_interface:add_time_trigger("hide_panel_mercs", 0.1)
    
  end

  local isRecruitedMerc = string.find(context.string, "_mercenary")
  
  -- PopLog("Get context of recruited mercenary: "..isRecruitedMerc)
  
  if isRecruitedMerc
  and UIComponent(context.component):CurrentState() == "active"   
  then 
  
    Merc_Levy_AddUnitTable()
    
    local unit_key = string.sub(context.string, 1, (isRecruitedMerc - 1))
    
    -- PopLog("Get context of recruited mercenary: "..unit_key)
    
    local class_number = Mercs_Levies_GetClass(unit_key, current_character)
    
    local costs = Mercs_Levies_UnitCosts(unit_key, class_number)
    
    if not Merc_Levy_recruitmentOrders[tostring(current_character:cqi())]
    then
    
      Merc_Levy_recruitmentOrders[tostring(current_character:cqi())] = {}
      
    end
    
    table.insert(Merc_Levy_recruitmentOrders[tostring(current_character:cqi())], unit_key)
    
    ui_merc_levy_region_table[class_number] = ui_merc_levy_region_table[class_number] - costs -- Mercs_Levies_RemovePop(,ui_merc_levy_region_table)
    
    scripting.game_interface:add_time_trigger("hide_panel_mercs", 0.1)
    
  end
end


-- ***** MERC LEVY LISTENER CANCEL ***** --
-- thanks to causless for sharing his code and explaining to me how he got canceling units to work

local function Merc_Levy_ListenerCancel(context)

  local component = string.find(context.string, "temp_merc_")
  
  if component
  then
  
    local queueID = tonumber(string.sub(context.string, 11)) + 1 
    local queuedUnitName =  Merc_Levy_recruitmentOrders[tostring(current_character:cqi())][queueID]
    local queuedUnitClass = Mercs_Levies_GetClass(queuedUnitName, current_character)
    local queuedUnitCosts = Mercs_Levies_UnitCosts(queuedUnitName, queuedUnitClass)
    
    table.remove(Merc_Levy_recruitmentOrders[tostring(current_character:cqi())], queueID)
    
    ui_merc_levy_region_table[queuedUnitClass] = ui_merc_levy_region_table[queuedUnitClass] + queuedUnitCosts
    
    scripting.game_interface:add_time_trigger("hide_panel_mercs", 0.1)
    
  end
end


-- ***** MERC LEVY REC LISTENER ACCEPT HIRE ***** --
-- on button tick 

local function Merc_Levy_RecListenerAcceptHire(context)

  local component = UIComponent(context.component):Id()
  
  if current_character ~= nil
  and component == "button_confirm"
  then 
  
    scripting.game_interface:add_time_trigger("popuihovertext_mercs", 0.1)
    scripting.game_interface:add_time_trigger("units_created", 0.1)
    scripting.game_interface:add_time_trigger("hide_panel_mercs", 0.1)
    
    
  end
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- REPLENISHMENT SYSTEM SCRIPTS  ---------------------------------------------------------------------
-- #####-------------------------


-- ***** REPLENISHMENT TURN END START ***** --
-- Replenishment: we want to apply and remove effect bundle based on current population, 
-- if a single population class is not high enough to replenish all units within the class
-- we block replenishment for the whole army, the script will be called on char turn start and end  

function Unit_Is_In_Army_pop(character, unit_list)
  if character:has_military_force() then
    local force = character:military_force();
    for i = 0, force:unit_list():num_items() - 1 do
      local unit = force:unit_list():item_at(i);
      if Unit_Is_in_Unit_List(unit:unit_key(),  unit_list) then
        return true;
      end;
    end;
  end;
  return false;
end;


local function ReplenishmentTurnEndStart(context)

Debug("ReplenishmentTurnEndStart")

  local curr_char = context:character()

  if not curr_char:faction():is_human()
  then
  
    return;
    
  end;

  if curr_char:is_polititian()
  then
  
    return;
    
  end;

  if curr_char:has_military_force()
  then
  
    local cqi = curr_char:cqi();
    local ReplenishmentArmyTable = {};
    local ReplenishmentPopTable = {0,0,0,0};
    local culture = curr_char:faction():state_religion();

    -- make sure we always have a valid region name
    -- fleets don't have a region so we always use the capital instead
    
    local region = ""
    
    if curr_char:has_region() 
    then
    
      region = curr_char:region() 
      
    end;

    local regionName = region:name()
      
    -- skip further checks if army has no region/sea region and is not in port 
    
    if not curr_char:has_region()
    and curr_char:military_force():is_army()
    and not curr_char:has_garrison_residence()
    then
    
      scripting.game_interface:apply_effect_bundle_to_characters_force("PoR2_disable_replenishment_region_wide", cqi,-1);
      
      return;
      
    end;

    if not curr_char:has_region()
    and curr_char:military_force():is_navy()
    then
    
      local x, y = curr_char:logical_position_x(), curr_char:logical_position_y() 
      
      regionName = getClosestPortRegion(x, y, curr_char:faction()) 
      
    end;

    -- we create a local region table to check all unit types, we remove pop from the table, but not from the main region table
    -- not a perfect solution as soon as more than a single army replenish within the region!
    
        for i =1, 4
    do
    
            ReplenishmentPopTable[i] = region_table[regionName][i]
      
        end

    -- first remove the bundle it might be not valid anymore
    
    scripting.game_interface:remove_effect_bundle_from_characters_force("PoR2_disable_replenishment_region_wide", cqi)

    local force = curr_char:military_force():unit_list()

    for i = 0, force:num_items() - 1
    do
    
      local unit = force:item_at(i)
      local unitKey = unit:unit_key()
      
      -- we only want to save units that are not at 100 % strenght
      
      if unit:percentage_proportion_of_full_strength() ~= 100
      then
      
        local unitStrenght = (unit_to_pop_table[unitKey][2] * unit:percentage_proportion_of_full_strength()) / 100
        
        unitStrenght = math.floor(unitStrenght + 0.5)       
        -- we save the amount of units needed to completly refill the unit        
        unitStrenght = unit_to_pop_table[unitKey][2] - unitStrenght

        if not ReplenishmentArmyTable[unitKey]
        then 
        
          ReplenishmentArmyTable[unitKey] = {} 
          ReplenishmentArmyTable[unitKey]["soldierCount"] = 0
          ReplenishmentArmyTable[unitKey]["unitCount"] = 0 
          
        end
        
          ReplenishmentArmyTable[unitKey]["soldierCount"] = ReplenishmentArmyTable[unitKey]["soldierCount"] + unitStrenght
          ReplenishmentArmyTable[unitKey]["unitCount"] = ReplenishmentArmyTable[unitKey]["unitCount"] + 1
          
      end
    end

    for unitKey, tab in pairs(ReplenishmentArmyTable)
    do
    
      local soldierCount = tab["soldierCount"]
      local unitCount = tab["unitCount"]
      local class = UIRetrieveClass(unitKey, curr_char:faction():name())
      
      for v,mercenary in pairs (mercenary_units_table)
      do 
      
        if mercenary == unitKey 
        then
        
          class = Mercs_Levies_GetClass(unitKey, curr_char)
          
        end
      end
      
      local costs = soldierCount

      -- !!!!!!!!! FLEETS!!!!!!!!
      -- if class manpower in the region is not high enough we block replenishment
      
      if curr_char:has_region()
      and culture ~= region:owning_faction():state_religion()
      then
      
        Log("Culture in Region not state religion -> block recruitment")
        
        scripting.game_interface:apply_effect_bundle_to_characters_force("PoR2_disable_replenishment_region_wide", cqi,-1)
        
        Debug("Culture in Region not state religion -> block replenishment")
        
        return
        
      end

      if curr_char:has_region()
      and culture == region:owning_faction():state_religion()
      then
        
        if ReplenishmentPopTable[class] < math.ceil(costs*0.05) and Unit_Is_In_Army_pop(curr_char, Baggage_train_list_pop)
        
        then 
        
          Log("Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
          scripting.game_interface:apply_effect_bundle_to_characters_force("PoR2_disable_replenishment_region_wide", cqi,-1)
          
          Debug("Baggage train - Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
          return
          
        elseif ReplenishmentPopTable[class] < math.ceil(costs*0.1)
          
          then
          
          Log("Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
          scripting.game_interface:apply_effect_bundle_to_characters_force("PoR2_disable_replenishment_region_wide", cqi,-1)
          
          Debug("NO Baggage train - Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
        else
          
          if Unit_Is_In_Army_pop(curr_char, Baggage_train_list_pop)
          
            then
          
            ReplenishmentPopTable[class] = ReplenishmentPopTable[class] - math.ceil(costs*0.05)
          
            Debug("Enough for replenishment with baggage train")
          
            else
          
            ReplenishmentPopTable[class] = ReplenishmentPopTable[class] - math.ceil(costs*0.1)
          
            Debug("Enough for replenishment no baggage train")
          
          end
          
          
        end
      end

      if curr_char:has_region() == false
      then 
      
        if ReplenishmentPopTable[class] < math.ceil(costs*0.05) and Unit_Is_In_Army_pop(curr_char, Baggage_train_list_pop)
        
        then 
        
          Log("Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
          scripting.game_interface:apply_effect_bundle_to_characters_force("PoR2_disable_replenishment_region_wide", cqi,-1)
          
          Debug("Baggage train - Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
          return
          
        elseif ReplenishmentPopTable[class] < math.ceil(costs*0.1)
          
          then
          
          Log("Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
          scripting.game_interface:apply_effect_bundle_to_characters_force("PoR2_disable_replenishment_region_wide", cqi,-1)
          
          Debug("NO Baggage train - Manpower in Region: "..regionName.. " too low for: " .. costs.." Block all replenishment! for: "..cqi)
          
        else
        
          if Unit_Is_In_Army_pop(curr_char, Baggage_train_list_pop)
          
            then
          
            ReplenishmentPopTable[class] = ReplenishmentPopTable[class] - math.ceil(costs*0.05)
          
            Debug("Enough for replenishment with baggage train")
          
            else
          
            ReplenishmentPopTable[class] = ReplenishmentPopTable[class] - math.ceil(costs*0.1)
          
            Debug("Enough for replenishment no baggage train")
          
          end
      
        end
      end
    end
  end
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- REBEL SYSTEM SCRIPTS  ---------------------------------------------------------------------

-- RebelsRemoveRebelPop
-- RebelsCharTurnEnd
-- RebelsCharTurnStart
-- RebelsBattleCompleted

-- #####-------------------------


-- Rebels work differently as they don't have a faction turn start event all armies are only available on character events
-- We have to check the army changes delayed
-- as Rebel armies are created with 4! starting units , we alway remove pop for the first 4 units if the character cqi is not
-- saved already


-- ***** REBELS REMOVE REBEL POP ***** --

function RebelsRemoveRebelPop(regionName, unit_key)

  local class = 4
  local costs = RecListenerRetrieveunitcosts(unit_key, class)
  
  -- Log("RebelsRemoveRebelPop for: ".. unit_key .. "  Class:  " .. class .. " Costs: " .. costs)
  region_table[regionName][class] = region_table[regionName][class] - costs
  
end


-- ***** REBELS CHAR TURN END ***** --

local function RebelsCharTurnEnd(context)

  Log("RebelsCharTurnEnd")
  
  if context:character():faction():name() == "rebels"
  and context:character():military_force():is_army()
  then
  
    local region = ""

    Log("context:character():military_force():is_army()")

    if context:character():has_region() 
    then
    
      region = context:character():region():name()
      
    else 
    
      return

    end

    local cqi = context:character():cqi() -- I need a cqi!
    
    Log("cqi: "..cqi)
    
    local force = context:character():military_force()
    
    Log("force:unit_list():num_items(): "..force:unit_list():num_items())

    if not rebel_cqi[tostring(cqi)]
    then
    
      rebel_cqi[tostring(cqi)] = {}
      
      for i = 0, force:unit_list():num_items() - 1
      do
      
        if i < 3
        then 
        
          local unit = force:unit_list():item_at(i)
          local unit_key = unit:unit_key()
          
          Log("unit_key: "..unit_key)
          
          local class = UIRetrieveClass(unit_key, context:character():faction():name())
          
          Log("class: "..class)
          
          local unit_costs = RecListenerRetrieveunitcosts(unit_key, class)
          
          Log("unit_costs: "..unit_costs)
          
          region_table[region][class]  = region_table[region][class] - unit_costs
          
          Log("Remove Pop from: "..region)
          
          rebel_cqi[tostring(cqi)][i] = unit_key
          
        end
      end
 
    elseif rebel_cqi[tostring(cqi)]
    then 
    
      for i = 0, force:unit_list():num_items() - 1
      do
      
        local unit = force:unit_list():item_at(i)
        local unit_key = unit:unit_key()
        
        rebel_cqi[tostring(cqi)][i] = unit_key
        
      end
    end
    
    rebel_army_size[tostring(cqi)] = force:unit_list():num_items()
    
  end
end


-- ***** REBELS CHAR TURN START ***** --

local function RebelsCharTurnStart(context)

  if context:character():faction():name() == "rebels"
  and context:character():military_force():is_army()
  and context:character():character_type("general") 
  then
    
    local new_rebel_units = {}
    local cqi = context:character():cqi() -- I need cqi

    if context:character():military_force():unit_list():num_items() > 1
    then
    
      local regionName = context:character():region():name()
      local force = context:character():military_force()

      for i = 0, force:unit_list():num_items() - 1
      do
      
        local unit = force:unit_list():item_at(i)
        local unit_key = unit:unit_key()
        
        new_rebel_units[i] = unit_key
        
      end

      for i = 0, context:character():military_force():unit_list():num_items() - 1
      do 
      
        local key = new_rebel_units[i] 
        
        for x = 0, context:character():military_force():unit_list():num_items() - 1
        do
        
          if key == rebel_cqi[tostring(cqi)][x]
          then
          
            new_rebel_units[i] = nil
            rebel_cqi[tostring(cqi)][x] = nil 
            
            break
            
          end                     
        end
      end

      for i,value in pairs(new_rebel_units)
      do       
      
        if value ~= nil
        then
        
          local unit_key = value
          
          RebelsRemoveRebelPop(regionName, unit_key)
          
        end
      end
    end
  end
end


-- ***** REBELS BATTLE COMPLETED ***** --

local function RebelsBattleCompleted(context)

  if context:character():faction():name() == "rebels"
  and context:character():military_force():is_army()
  and context:character():character_type("general") 
  then
  
    local cqi = context:character():cqi()
    local force = context:character():military_force()

    for i = 0, force:unit_list():num_items() - 1
    do
    
      local unit = force:unit_list():item_at(i)
      local unit_key = unit:unit_key()
      
      rebel_cqi[tostring(cqi)][i] = unit_key
    
    end
  
    rebel_army_size[tostring(cqi)] = force:unit_list():num_items()
    
  end
end


-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- AI SYSTEM SCRIPTS  ---------------------------------------------------------------------

-- The AI System is handled easily with pop remove on Faction turn satrt to listen for newly recruited units
-- Mercenaries and ships are not used for the AI
-- However all normally recruied units are

-- AIOnCharTurnStart
-- AIRemovePop
-- AIAddUnitTable
-- AIFactionTurnStart

-- #####-------------------------


-- ***** AI ON CHAR TURN START ***** --
-- ***** AI ON CHAR TURN START ***** --

local function AIOnCharTurnStart(context)
  AIAddUnitTable(context:character())
  local force = context:character():military_force()
  local size = force:unit_list():num_items()
end

-- ***** AI RECRUITMENT HANDLER ***** --
-- This function ensures that AI recruitment deducts population

function AIRecruitmentHandler(character, unitKey)
  local factionName = character:faction():name()
  local regionName = character:region():name()
  
  -- Get unit size from population table, default to 120 if not found
  local unitSize = unit_to_pop_table[unitKey] and unit_to_pop_table[unitKey][2] or 120

  -- Determine the population class needed for this unit
  local popClass = UIRetrieveClass(unitKey, factionName)

  -- Get current population for that class in the region
  local currentPop = region_table[regionName][popClass] or 0

  -- Prevent AI recruitment if not enough population
  if currentPop < unitSize then
      PopLog("AI attempted to recruit " .. unitKey .. " but lacks enough population! Recruitment blocked.")
      return -- Block recruitment
  end

  -- Otherwise, proceed with recruitment and deduct population
  PopLog("AI recruited " .. unitKey .. " deducting " .. unitSize .. " population from " .. regionName)
  RemovePop(unitKey, unitSize, regionName, nil, factionName)
end


-- ***** AI REMOVE POP ***** --

function AIRemovePop(character)
  local new_units = {}
  local cqi = character:cqi() -- Get character unique ID
  local factionName = character:faction():name()
  local force = character:military_force()

  if force:is_navy() then
    return
  end 

  local regionName = character:region():name()

  for i = 0, force:unit_list():num_items() - 1 do
    local unit = force:unit_list():item_at(i)
    local unit_key = unit:unit_key()
    
    new_units[i] = unit_key
  end

  for i = 0, character:military_force():unit_list():num_items() - 1 do 
    local key = new_units[i] 
    
    for x = 0, character:military_force():unit_list():num_items() - 1 do
      if key == AI_recruitment_table[tostring(cqi)][x] then
        new_units[i] = nil
        AI_recruitment_table[tostring(cqi)][x] = nil 
        break
      end                     
    end
  end

  for i, value in pairs(new_units) do   
    if value ~= nil then
      local unit_key = value
      RecListenerRemovePop(regionName, unit_key, factionName)
    end
  end
end

-- ***** AI ADD UNIT TABLE ***** --

function AIAddUnitTable(character)
  local force = character:military_force()
  local cqi = character:cqi()
  local regionName = character:region():name()

  for i = 0, force:unit_list():num_items() - 1 do
    local unit = force:unit_list():item_at(i)
    local unit_key = unit:unit_key()
      
    if not AI_recruitment_table[tostring(cqi)] then 
      AI_recruitment_table[tostring(cqi)] = {}
    end
    
    AI_recruitment_table[tostring(cqi)][i] = unit_key
  end
end

-- ***** AI FACTION TURN START ***** --

local function AIFactionTurnStart(context)
  local faction = context:faction()
  
  if not faction:is_human() then -- AI faction handling
    for char = 0, faction:character_list():num_items() - 1 do
      local curr_char = faction:character_list():item_at(char)
      
      if curr_char:character_type("general") 
      and curr_char:has_military_force() 
      and curr_char:has_region() then
      
        -- Ensure AI unit recruitment also deducts population
        local army = curr_char:military_force()
        local unit_list = army:unit_list()

        for i = 0, unit_list:num_items() - 1 do
          local unit = unit_list:item_at(i)
          local unitKey = unit:unit_key()
          AIRecruitmentHandler(curr_char, unitKey)
        end
        
        AIRemovePop(curr_char)
      end
    end
  end
end



-- #####---------------------------------- END #####


-- #####------------------------- START #####
-- VARIOUS FUNCTIONS ---------------------------------------------------------------------

-- Originally created by Causeless
-- Code Review: Litharion - Army Tracking functions
-- there seems to be only one save solution for retrieving the faction key
-- saving the key during the turn is unsafe because it might change
-- the only 100% save option is to retrieve the local current faction with every function again
-- every UI and other function's using the current faction varaible need adapting 
-- solution code entry per function -> local currentFaction = UIGetLocalFaction()

-- The other option is to start/stop the time trigger during the diplomacy phase, it might be a good idea to do it anyway
-- will increae overhaul performance during the game

-- #####-------------------------


stop_tick_tock = false


-- ***** STOP PANEL OPENED CAMPAIGN ***** --

local function StopPanelOpenedCampaign(context)

  PopLog("Panel Opened " ..context.string)
  
  if context.string == "diplomacy_dropdown"
  then
  
    stop_tick_tock = true
    
  end
end

scripting.AddEventCallBack("PanelOpenedCampaign", StopPanelOpenedCampaign) 


-- ***** START PANEL CLOSED CAMPAIGN ***** --

  local function StartPanelClosedCampaign(context)
  
  PopLog("Panel closed " ..context.string)
  
  if context.string == "diplomacy_dropdown"
  then
  
    stop_tick_tock = false
    currentFaction = nil
    
    scripting.game_interface:add_time_trigger("tick_tack"..triggerload, 5)
    
  end
end

scripting.AddEventCallBack("PanelClosedCampaign", StartPanelClosedCampaign)


-- ***** ADD NEW EVENTS ***** --

_callbacks =

  {
  
    ["CharacterMoved"] = {},
    ["SimTick"] = {}
  
  }

function addCallback(event, func)

  table.insert(_callbacks[event], func)
  
end


-- Litharion code review:
-- save is human, then start/stop trigger
-- so the tick is not running during AI turns anymore
-- as we don't check AI it looks like a good idea to maybe increase stability
-- def not a required change and something to look at for the final version
-- loading will be an issue and would require a flexible code:
-- isPlayerturn = loading - use this entry as base
-- isPlayerturn = true/false - use true/false boolean after first check since loading the game 
-- without faction turn start event


_charInfo = {}


-- ***** NEW CHARACTER CREATED ***** --

local function NewcharacterCreated(context)

  local charCQI = context:character():cqi()
  
  if not _charInfo[charCQI]
  then
  
    _charInfo[charCQI] = {["posX"] = posX, ["posY"] = posY, ["regionName"] = regionName}
    
  end
end


-- ***** CALL CHARACTER MOVE CALLBACKS ***** --

local function callCharacterMoveCallbacks(charCQI, tab)

  for key, func in ipairs(_callbacks["CharacterMoved"])
  do
    
    func(charCQI, tab["regionName"], tab["posX"], tab["posY"])
  
  end
end


-- ***** GET PLAYER FACTIONS ***** --
-- new way of retrieving the player faction's should work perfectly in MP!

function GetPlayerFactions()

  local player_factions = {};
  local faction_list = scripting.game_interface:model():world():faction_list();
  
  for i = 0, faction_list:num_items() - 1
  do
  
    local curr_faction = faction_list:item_at(i);
    
    if (curr_faction:is_human() == true)
    then
    
      Log("Player Faction: "..curr_faction:name())
      
      table.insert(player_factions, curr_faction);
      
    end
  end
  
  return player_factions;
  
end;


-- ***** CHECK FOR CHARACTER MOVEMENT ***** --
-- new way of retrieving the player faction's should work perfectly in MP!

local function checkForCharacterMovement()

  -- PopLog(function()
  -- We assume characters can only move if it's their faction's turn
  -- This is technically inaccurate - a faction can retreat their army during another faction's turn, when attacked
  -- But this is good enough for what we need it for, and a lot faster than checking every faction's characters

  if stop_tick_tock == false
  then 
  
    player_factions = GetPlayerFactions()
    
    for i,faction in pairs(player_factions)
    do
    
      Log("get currentFaction!")
      
      local currentFaction = faction
      
      Log("currentFaction! found: "..faction:name())

      if not currentFaction 
      then
      
        return
        
      end

      local charList = currentFaction:character_list()

      for j = 0, charList:num_items() - 1
      do

        local character = charList:item_at(j)
        local charCQI = character:cqi()
        local posX = character:display_position_x()
        local posY = character:display_position_y()               
        local regionName = nil
        
        if character:has_region()
        then
        
          regionName = character:region():name()
          
        end

        if not _charInfo[charCQI]
        then
        
          _charInfo[charCQI] = {["posX"] = posX, ["posY"] = posY, ["regionName"] = regionName}
          
        end
        
        local tab = _charInfo[charCQI]

        if posX ~= tab["posX"]
        or posY ~= tab["posY"]
        then
        
          Log("character moved!")   
          
          callCharacterMoveCallbacks(charCQI, tab)

          tab["posX"] = posX
          tab["posY"] = posY
          tab["regionName"] = regionName
          
        end
      end
    end
  end
end


-- ***** TICK TRIGGER ***** --

local function tickTrigger(context)

  if stop_tick_tock == false
  then
  
    if context.string == "tick_tack"..triggerload
    then
    
      -- This is for the OnSimTick
      -- First we must set up a time trigger so this is called again ASAP
      
      Log("Start Tick")
      
      scripting.game_interface:add_time_trigger("tick_tack"..triggerload, 0.5)
      
      Log("End Tick")
      
      -- Time to wait is 0.0 - but the game must defer it to the next tick
      -- According to my experimentation, the campaign runs at a logical tickrate of 10fps, so this function is called 10 times a second

      for key, func in ipairs(_callbacks["SimTick"])
      do
      
        func()
        
      end
    end
  end
end


-- ***** CALLBACKS ***** --

scripting.AddEventCallBack("CharacterCreated", NewcharacterCreated)
scripting.AddEventCallBack("TimeTrigger", tickTrigger)

scripting.AddEventCallBack("WorldCreated", function() 

  scripting.game_interface:add_time_trigger("tick_tack"..triggerload, 0.5)
  
  addCallback("SimTick", checkForCharacterMovement)
  
end)


-- Originally created by Causeless
-- Free to be used, under the conditions that:
--      1. If this file has been modified, any significant changes must be stated
--      2. This file header is included in all derivatives

-- Litharion:
-- Command Queue index to Character
-- since we can't use the various cm:model():military_force_for_command_queue_index functions, 
-- we need to get the character from cqi differently with the faction character list searching for a matching pair of cqi's


-- ***** CQI TO CHAR ***** --

function CqitoChar(charCQI)

  Log("CqitoChar")
  
  player_factions = GetPlayerFactions()
  
  for i,faction in pairs(player_factions)
  do
  
    Log("get currentFaction!")
    
    local currentFaction = faction

    local charList = currentFaction:character_list()

    for j = 0, charList:num_items() - 1
    do
    
      local character = charList:item_at(j)
      local searchCQI = character:cqi()
      
      if searchCQI == charCQI 
      then   
      
        return character
        
      end
    end
  end
end


-- Causeless:
-- CharacterMoved has a 1 tick delay, so armies that move fast can move slightly before this is called
-- So when using this to update armies, there can be an anomoly of a dozen troops or so, when armies suffer attrition
-- The issue will be hidden by region growth anyways
-- Shouldn't cause a desync, as the delay *should* be synced across both players


-- ***** CHARACTER MOVED ***** --

local function CharacterMoved(charCQI, regionName)

  if stop_tick_tock == false
  then
  
    local character = CqitoChar(charCQI) -- added to get char from cqi
    
    if not character:faction():is_human()
    then
    
      return
      
    end 
    
    if not character:has_military_force()
    then
    
      return
      
    end

    local army = character:military_force()             
    local armyCQI = character:cqi()
    
    if army:is_army()
    or army:is_navy()
    then
    
      Log("Start updateArmy: "..armyCQI)
      
      updateArmy(armyCQI, regionName)
      
    end
  end
end


-- ***** ARMY STATE SCRIPTED FORCE CREATED ***** --

local function ArmyStateScriptedForceCreated(context)

  -- If a scripted force is created, we don't want it demolishing the population of the region
  -- So we add the scripted force to our list and pretend it was here all along
  
  local army = context:military_force()
  local armyCQI = army:general_character():cqi()
  local factionName = army:general_character():faction():name()
  local character = CqitoChar(armyCQI)  -- added to get char from cqi
  
  if not character:faction():is_human()
  then
  
    return
    
  end 
  
  armyState[tostring(armyCQI).."_"..factionName] = createArmyList(army)
  
end


-- ***** ARMY STATE SCRIPTED FORCE CREATED ***** --

local function ArmyStateCharacterCompletedBattle(context)

  --RemoveSavedDeadCqi() 
  
  local army = context:character():military_force()
  local armyCQI = army:general_character():cqi()
  local factionName = army:general_character():faction():name()
  
  RemoveDeadCqi(armyCQI, factionName)
  
  -- Skip army update, so updateArmy doesn't notice any losses from the battle and change population
  if not context:character():faction():is_human() then
    return   
  end 
  armyState[tostring(armyCQI).."_"..factionName] = createArmyList(army)
end

-- ***** ARMY STATE SCRIPTED FORCE CREATED ***** --
local function ArmyStateArmiesMerge(context)
  local currentFaction = context:character():faction():name()
  
  if not currentFaction:is_human() then
    return
  end 
  --Log("Start armies merged")
  local army1 = context:character():military_force()
  local army1CQI = army1:general_character():cqi()
  local army2 = context:target_character():military_force()
  local army2CQI = army2:general_character():cqi()

  -- Skip army updates, so updateArmy doesn't notice any change from the merge and change population
  
  scripting.game_interface:add_time_trigger("armyMerged_" .. army1CQI, 0.0) -- Must delay to next frame, when game updates armies
  scripting.game_interface:add_time_trigger("armyMerged_" .. army2CQI, 0.0)

  --  Log("armies merged")

end


-- ***** ARMY STATE PENDING BATTLE ***** --

local function ArmyStatePendingBattle(context)

  -- Update both armies to check for disbanded units etc
  
  local battle = context:pending_battle()
  local attacker = battle:attacker()
  local defender = battle:defender()
  local attackerArmyCQI = attacker:military_force():general_character():cqi()
  local defenderArmyCQI = defender:military_force():general_character():cqi()
  
  army_cqi_attacker = attackerArmyCQI
  army_cqi_defender = defenderArmyCQI
  

  if not attacker:military_force():general_character():faction():is_human()
  or defender:military_force():general_character():faction():is_human()
  then 
  
    return
  
  end
  
  updateArmy(attackerArmyCQI)
  updateArmy(defenderArmyCQI)
  
end


-- ***** ARMY STATE FACTION TURN START ***** --

local function ArmyStateFactionTurnStart(context)

  if not context:faction():is_human() then
    return
  end
  
  
  -- Add all of our factions armies back to the list of tracked armies
  local armies = context:faction():military_force_list():num_items()
  PopLog("ArmyStateFactionTurnStart: "..context:faction():name())
  for i = 0, armies - 1 do
  
    local army = context:faction():military_force_list():item_at(i)
    local armyCQI = army:general_character():cqi()
    local factionName = context:faction():name()
    local armyKey = tostring(armyCQI).."_"..factionName
    PopLog("ArmyStateFactionTurnStart armyKey: "..armyKey)

    if army:is_army() or army:is_navy()
    then
      if not armyState[armyKey] then
        armyState[armyKey] = createArmyList(army)
      end
      updateArmy(armyCQI) -- Update the army, to take into account changes during end turn
    end
  end

  --Need this to be done after all the armies are updated
  PopLog("DeepCopy for faction: "..context:faction():name())
  resetUIPopulation()
end;


-- ***** ARMY STATE FACTION TURN END ***** --

local function ArmyStateFactionTurnEnd(context)
  
  if not context:faction():is_human() then
    return
  end; -- testing
  
  --CheckForNewCqi(context:faction())

  local armies = context:faction():military_force_list():num_items()
  
  for i = 0, armies - 1 do

    local army = context:faction():military_force_list():item_at(i)
    local armyCQI = army:general_character():cqi()

    if army:is_army() or army:is_navy() then
      updateArmy(armyCQI) -- Now we use armyState to determine changes which happen throughout the end turn sequence
    end
  end
end

-- ***** UPDATE ARMY ***** --
armyStateRegion = {};

function updateArmy(armyCQI, regionName)
  -- if the army list is pre crash fix we delete the full army table 
  local character = CqitoChar(tonumber(armyCQI))
  local army = character:military_force()
  local factionName = character:faction():name()
  local armyKey = tostring(armyCQI).."_"..factionName
  
  if not character:has_region() then 
    local x, y = character:logical_position_x(), character:logical_position_y()
    regionName = getClosestPortRegion(x, y, character:faction())
  end;

  -- regionName is an optional argument. if it is not sent in, it uses the character's current region for population changes
  -- this allows the script to properly feed the population into the region where the army just moved from instead of it's current one
  -- used because the armyMove callback is slightly "late" due to relying on detecting when an army has moved, only after they begin moving
  -- (otherwise you can abuse region borders to trick the script what region you levied troops from or disbanded them)

  local regionName = regionName or character:region():name();
  local currentArmyTable = createArmyList(army);
  -- Sometimes this can be fed non-existent tables, because armies can be destroyed
  armyStateRegion[armyKey] = {regionName, factionName};
  CheckForNewCqi(character:faction()) ;

  if not armyState[armyKey] then 
    armyState[armyKey] = {};
  end;

  local difference = getArmyDifference(currentArmyTable, armyState[armyKey]);
  
  for unitKey, tab in pairs(difference) do
    local soldierCount = tab["soldierCount"];
    local unitCount = tab["unitCount"];

    if soldierCount < 0 and unitCount < 0 then 
      -- A unit is missing, and the soldier count has dropped. Assume disbanding
      PopLog("Disbanding " .. unitKey .. ", giving " .. -soldierCount .. " population to " .. regionName);
      AddPop(unitKey, soldierCount, regionName, character, factionName); -- create function 

    elseif soldierCount < 0 and unitCount >= 0 then 
      -- No missing units, and loss in soldier count. Assume attrition
        PopLog("Attrition in " .. unitKey .. ", killing " .. -soldierCount .. " soldiers");
      -- No population change

    elseif soldierCount > 0 then 
      -- Soldiers have been created (via replenishment or recruitment) and pop must be changed accordingly
      PopLog("Creating or replenishing " .. unitKey .. ", taking " .. soldierCount .. " population from " .. regionName);
      RemovePop(unitKey, soldierCount, regionName, character, factionName);
      -- factionName
    end;
  end;
  armyState[armyKey] = deepCopy(currentArmyTable); -- Now update the army, because we've handled the disbanded/created troops
end;


-- ***** UPDATE ARMY ***** --
-- Returns the difference between 2 army tables. Can theoretically be used to figure out what units have disbanded, unit replenishment etc

function getArmyDifference(army1_table, army2_table)

  local differenceTable = deepCopy(army1_table)

  for unit_key, tab in pairs(army2_table)
  do
  
    if not differenceTable[unit_key]
    then
    
      differenceTable[unit_key] = {}
      
    end
    
    if not differenceTable[unit_key]["soldierCount"]
    
      then differenceTable[unit_key]["soldierCount"] = 0
      
    end
    
    if not differenceTable[unit_key]["unitCount"]
    then
    
      differenceTable[unit_key]["unitCount"] = 0
      
    end
    
    differenceTable[unit_key]["soldierCount"] = differenceTable[unit_key]["soldierCount"] - tab["soldierCount"]
    differenceTable[unit_key]["unitCount"] = differenceTable[unit_key]["unitCount"] - tab["unitCount"]
    
  end

  return differenceTable
  
end


-- ***** CREATE ARMY LIST ***** --

function createArmyList(army)

  PopLog("Create Army List")
  
  local armyTable = {}
  local armyList = army:unit_list()

  for i = 0, armyList:num_items() - 1
  do
  
    local unit = armyList:item_at(i)
    local unitKey = unit:unit_key()
    
    PopLog("UnitKey: "..unitKey)
    
    local unitSize = 0
    
    if not unit_to_pop_table[unitKey]
    then
    
      unitSize = 120
      
      
    elseif unit_to_pop_table[unitKey]
    then
    
      unitSize = unit_to_pop_table[unitKey][2]
      
    end

    -- We need to do some maths here to figure out the unit count
    -- So we divide by 100, as it's a percentage
    -- Doing it in this order - multiplying them together BEFORE dividing by 100 -
    -- ensures the most accuracy out of the floating point calculations
    
    unitSize = (unitSize * unit:percentage_proportion_of_full_strength()) / 100
    
    -- We still need to round it though, to catch tiny errors that get through:
    
    unitSize = math.floor(unitSize + 0.5) -- math.floor + 0.5 will round to the closest int
    
    PopLog("unitSize: "..unitSize)

    if not armyTable[unitKey] then 
    
      armyTable[unitKey] = {} 
      armyTable[unitKey]["soldierCount"] = 0
      armyTable[unitKey]["unitCount"] = 0 
      
    end
    
    armyTable[unitKey]["soldierCount"] = armyTable[unitKey]["soldierCount"] + unitSize
    armyTable[unitKey]["unitCount"] = armyTable[unitKey]["unitCount"] + 1
    
  end

  return armyTable
  
end


-- ***** CHECK FOR NEW CQI ***** --
-- Litharion:
-- What happens if we replace a char with the saved army? We have to make sure the army is not counted as a new one
-- we check faction army list against saved armies, if a army is not in the state list and the state list has an empty
-- slot we copy the table for the new general

function CheckForNewCqi(faction)

  PopLog("CheckForNewCqi")
  
  -- if isprefixgame == false then 
  -- PopLog("Delete old tables")
  -- for k in pairs (armyState) do
  -- armyState[k] = nil
  -- end
  -- for k in pairs (armyStateRegion) do
  -- armyStateRegion[k] = nil
  -- end       
  -- for k in pair (recruitmentOrders) do
  -- recruitmentOrders[k] = nil
  -- end
  -- isprefixgame = true
  -- PopLog("Deleted old tables")
  --  end

  local armylist = faction:military_force_list()
  local factionName = faction:name()
  local cqi_list = {}
  local not_cqi_list = {} 
  local not_in_old_list = {}
  local old_cqi = false
  local new_cqi = false

  PopLog("Go through army list, CheckForNewCqi")
  
  for i = 0, armylist:num_items() -1 do
    local army = armylist:item_at(i)
    
    -- make sure we don't add garrison armies
    -- if not army:general_character():character_type("colonel") then
    -- deactivate old army/navy check because we already use the military force list
    -- if not army:general_character():character_type("colonel")
    
    if army:is_army() or army:is_navy() then
    
      local army_CQI = army:general_character():cqi()
      local armyKey = tostring(army_CQI).."_"..factionName
      
      PopLog("Go through army list: "..armyKey)
      cqi_list[armyKey] = true
      PopLog("Faction CQI Army list, add to cqi_list table "..armyKey)
      
      if not armyState[armyKey] then 
        not_cqi_list[armyKey] = true
        new_cqi = true
        PopLog("Army does not exist, add to not_cqi_list table "..armyKey)
      end
    end
  end

  -- I need to find the army in the army state list that is not in the faction list
  for k,v in pairs (armyState) do
    PopLog("Check if Army State cqi is saved: "..k)
    local cqi = k;

      if armyStateRegion[cqi] and armyStateRegion[cqi][2] == factionName then
        PopLog("Saved Army: "..cqi.." already exists in region: "..armyStateRegion[cqi][1])
        if cqi_list[cqi] then
          PopLog("Saved Army already exists: "..cqi)
        end;

        if not cqi_list[cqi] then
          PopLog("Saved Army does not exists: "..cqi);
          not_in_old_list[cqi] = true;     
          old_cqi = true;
          PopLog("Char was removed from saved army, check for replacements for: "..cqi);
        end;
      end;
    end;

  if old_cqi == true and new_cqi == true then
    PopLog("Search for army to copy")
    
    for newcqi,v in pairs (not_cqi_list) do
      PopLog("newcqi:"..newcqi)
      for oldcqi, v2 in pairs (not_in_old_list) do
        PopLog("oldcqi:"..oldcqi)
        
        if armyStateRegion[newcqi] and armyStateRegion[oldcqi] then
          if armyStateRegion[newcqi][1] == armyStateRegion[oldcqi][1] then
          
            local UI = armyStateRegion[oldcqi][1]
            PopLog("Region match found: "..UI)
            
            armyState[newcqi] = armyState[oldcqi] -- last known region - we save CQI to region ! this way we can check if new cqi matches
            PopLog("Copy: "..oldcqi.. " to new cqi: "..newcqi)
            
            armyState[oldcqi] = nil
            not_in_old_list[oldcqi] = nil
            not_cqi_list[newcqi] = nil
          end
        end
      end
    end
  end
  if old_cqi then
  
    for oldcqi, v in pairs (not_in_old_list) do
      PopLog("Disband Army oldcqi: "..oldcqi)
      
      if not armyStateRegion[oldcqi] then
        PopLog("Army: "..oldcqi.. " not in armyStateRegion List");
      elseif armyStateRegion[oldcqi] then      
        local regionName = armyStateRegion[oldcqi][1] -- last known region
        PopLog("oldcqi last known region: ".. armyStateRegion[oldcqi][1])
        for unitKey, tab in pairs(armyState[oldcqi]) do      

          local soldierCount = tab["soldierCount"]
          PopLog("oldcqi unitKey: ".. unitKey)
          PopLog("oldcqi soldierCount: ".. soldierCount)
          local unitCount = tab["unitCount"] -- not needed as the army is disbanded
        
          FullDisband(unitKey, soldierCount, regionName, factionName)
        end;      
      end;
      armyState[oldcqi] = nil;
      not_in_old_list[oldcqi] = nil;
    end;
  end;
end;


-- ***** REMOVE DEAD CQi ***** --
function RemoveDeadCqi(cqi, factionName)
  -- I need to find the army in the army state list that is not in the faction list
  PopLog("Start armyState check")

  if armyState[tostring(cqi).."_"..factionName] then
    PopLog("RemoveDeadCqi:"..cqi)
    armyState[tostring(cqi).."_"..factionName] = nil
  end;
end;

-- #####---------------------------------- END #####

-- #####------------------------- START #####
--  OTHER EVENTS ---------------------------------------------------------------------

-- Other Events I might need to check ?
-- CharacterCharacterTargetAction
-- CharacterCompletedBattle
-- CharacterCreated
-- CharacterPostBattleEnslave
-- CharacterPostBattleRelease
-- CharacterPostBattleSlaughter
-- CharacterRelativeKilled
-- CharacterWoundedInAssassinationAttempt

-- #####-------------------------


--Litharion:
-- Remove and Add population based on class system region and char take mercenary system into account


-- ***** REMOVE POP ***** --

function RemovePop(unitKey, soldierCount, regionName, character, factionName)

  PopLog("RemovePop")
  
  local class = 0

  for v, unit in pairs(mercenary_units_table)
  do
  
    if unit == unitKey
    then
    
      class = Mercs_Levies_GetClass(unitKey, character)
      
      break
      
    end
  end

  if class == 0
  then 
  
    class = UIRetrieveClass(unitKey, factionName)
    
  end

  if class == 0
  then
  
    return
    
  end

  local costs = soldierCount
  
  PopLog("Remove: "..unitKey.." and class "..class.. " with "..costs.. " soldiers from: "..regionName)
  PopLog("Old region_table[regionName][class]: "..region_table[regionName][class])
  
  region_table[regionName][class] = math.max(0, region_table[regionName][class] - costs)

  
  PopLog("New region_table[regionName][class]: "..region_table[regionName][class])
  
end


-- ***** ADD POP ***** --

function AddPop(unitKey, soldierCount, regionName, character, factionName)

  PopLog("AddPop")
  
  local class = 0

  for v, unit in pairs(mercenary_units_table)
  do
  
    if unit == unitKey 
    then
    
      class = Mercs_Levies_GetClass(unitKey, character)
      
      break
      
    end
  end

  if class == 0
  then 
  
    class = UIRetrieveClass(unitKey, factionName)
    
  end

  if class == 0
  then
  
    return
    
  end

  local costs = (soldierCount*-1)
  
  
  PopLog("Add: "..unitKey.." and class "..class.. " with "..costs.. " soldiers to: "..regionName)
  PopLog("Old region_table[regionName][class]: "..region_table[regionName][class])
  
  region_table[regionName][class] = region_table[regionName][class] + costs
  region_table[regionName][class] = math.max(region_table[regionName][class], 0)
  
  PopLog("New region_table[regionName][class]: "..region_table[regionName][class])
  
end


-- ***** FULL DISBAND ***** --
-- full disband currently mercenaries are always returned as 4th class

function FullDisband(unitKey, soldierCount, regionName, factionName)

  PopLog("FullDisband")
  
  local class = 0

  if class == 0
  then 
  
    class = UIRetrieveClass(unitKey, factionName) 
    
  end

  if class == 0
  then
  
    class = 4
    
  end; -- mercenaries are returned as 4th class
  
  local costs = soldierCount --GetUnitCosts(unitKey, class, soldierCount)
  
  PopLog("Add: "..unitKey.." and class "..class.. " with "..costs.. " soldiers to: "..regionName)
  PopLog("Old region_table[regionName][class]: "..region_table[regionName][class])
  
  region_table[regionName][class] = region_table[regionName][class] + costs
  region_table[regionName][class] = math.max(region_table[regionName][class], 0)
  
  PopLog("New region_table[regionName][class]: "..region_table[regionName][class])
  
end


-- ***** ARMY STATE TIME TRIGGER ***** --
-- Causeless:

local function ArmyStateTimeTrigger(context)

  if string.find(context.string, "armyMerged_")
  then
  
    local armyCQI = string.sub(context.string, 12)
    local character = CqitoChar(tonumber(armyCQI))
    local factionName = character:faction():name() 
    local army = character:military_force()
    
    armyState[tostring(armyCQI).."_"..factionName] = createArmyList(army)
    
  end
end


-- ***** DEEP COPY ***** --

function deepCopy(orig)
PopLog("deep Copy start for table: "..tostring(orig))
-- copy background numbers to UI tables
  local orig_type = type(orig);
  local copy;
  
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[deepCopy(orig_key)] = deepCopy(orig_value)
    end;
  
  setmetatable(copy, deepCopy(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig;
  end;
  PopLog("deep Copy start for table: returned value")
  return copy;
end;


-- ***** SHALLOW COPY ***** --

function shallowCopy(orig)

  local orig_type = type(orig)
  local copy
  
  if orig_type == 'table'
  then
  
    copy = {}
    
    for orig_key, orig_value in pairs(orig)
    do
  
      copy[orig_key] = orig_value
    
    end
    
  else -- number, string, boolean, etc
  
    copy = orig
    
  end
  
  return copy
  
end


-- ***** RESET UI POPULATION ***** --

function resetUIPopulation()
  PopLog("Start Set UI POPULATION")
  UIPopulation = deepCopy(region_table)
  PopLog("End Set UI POPULATION")
end;


-- #####---------------------------------- END #####


-- #####------------------------- START #####
--  CALLBACKS ---------------------------------------------------------------------
-- #####-------------------------


scripting.AddEventCallBack("SettlementSelected", MPLogPop);
scripting.AddEventCallBack("FactionTurnStart", ShowPopMessageStart);
scripting.AddEventCallBack("FactionTurnEnd", UIFactionTurnEnd);
scripting.AddEventCallBack("FactionTurnStart", ArmyStateFactionTurnStart);
scripting.AddEventCallBack("FactionTurnEnd", ArmyStateFactionTurnEnd);
scripting.AddEventCallBack("ScriptedForceCreated", ArmyStateScriptedForceCreated);
scripting.AddEventCallBack("TimeTrigger", ArmyStateTimeTrigger);
scripting.AddEventCallBack("SettlementSelected", PopSaveNewRegion);

 --events.
 
addCallback("CharacterMoved", CharacterMoved);
scripting.AddEventCallBack("CharacterCompletedBattle", ArmyStateCharacterCompletedBattle);
scripting.AddEventCallBack("CampaignArmiesMerge", ArmyStateArmiesMerge);
scripting.AddEventCallBack("PendingBattle", ArmyStatePendingBattle);

-- UI Callbacks

scripting.AddEventCallBack("ComponentLClickUp", UIChangeOnButtonPressed);
scripting.AddEventCallBack("SettlementSelected", UIRetrievePopulation);
scripting.AddEventCallBack("ComponentMouseOn", UIChangeCampaignComponentsOnMouseOn);
scripting.AddEventCallBack("ComponentMouseOn", UIDevPoinsIconTooltip1);
scripting.AddEventCallBack("ComponentMouseOn", UIEnableQueuedUnitTooltips);
scripting.AddEventCallBack("ComponentMouseOn", UIEnablePopHoverUnitTooltips);
scripting.AddEventCallBack("ComponentMouseOn", UIChangeTooltip_dev_points_icon);
scripting.AddEventCallBack("ComponentMouseOn", UIChangeTooltip_TTIP_STA1_Popu_0001);
--scripting.AddEventCallBack("ComponentMouseOn", UIChangeTooltip_button_disband);
scripting.AddEventCallBack("PanelOpenedCampaign", UIPanelOpenedCampaign);
scripting.AddEventCallBack("BuildingConstructionIssuedByPlayer", OnBuildingConstructionIssuedByPlayer);
scripting.AddEventCallBack("TimeTrigger", OnTimeTrigger);
scripting.AddEventCallBack("ShortcutTriggered", OnShortcutTriggered);
scripting.AddEventCallBack("BuildingCardSelected", UIOnBuildingCardSelected);

-- UI Recruitment Listener Callbacks

scripting.AddEventCallBack("CharacterSelected", RecListenerGetCharacter);
scripting.AddEventCallBack("RecruitmentItemIssuedByPlayer", RecListenerRecruitmentIssuedByPlayer);
scripting.AddEventCallBack("ComponentLClickUp", RecListenerCancel);
scripting.AddEventCallBack("ComponentLClickUp", RecListenerUnitClicked);
scripting.AddEventCallBack("ComponentLClickUp", RecListenerAcceptDisband);
scripting.AddEventCallBack("ComponentLClickUp", RecListenerAddUnitTable);
scripting.AddEventCallBack("CharacterSelected", RecListenerAddUnitTablePopUI);
scripting.AddEventCallBack("FactionTurnStart", RecListenerArmyUnitCounterStart);
scripting.AddEventCallBack("FactionTurnEnd", RecListenerArmyUnitCounterEnd);

-- Mercs and Levies

scripting.AddEventCallBack("ComponentLClickUp", Merc_Levy_ListenerCancel);
scripting.AddEventCallBack("ComponentLClickUp", Merc_Levy_RecListenerAddUnitTable);
scripting.AddEventCallBack("ComponentLClickUp", Merc_Levy_RecListenerAcceptHire);


-- Replenishment 

scripting.AddEventCallBack("CharacterTurnStart", ReplenishmentTurnEndStart);
scripting.AddEventCallBack("CharacterTurnEnd", ReplenishmentTurnEndStart);

-- Rebels

scripting.AddEventCallBack("CharacterTurnStart", RebelsCharTurnStart);
scripting.AddEventCallBack("CharacterTurnEnd", RebelsCharTurnEnd);
scripting.AddEventCallBack("CharacterCompletedBattle", RebelsBattleCompleted);

-- AI

scripting.AddEventCallBack("CharacterTurnStart", AIOnCharTurnStart);
scripting.AddEventCallBack("FactionTurnStart", AIFactionTurnStart);


-- #####---------------------------------- END #####


-- isprefixgame = false;
-- local function isprefixgameOnNewCampaignStarted(context)
-- PopLog("NewCampaignStarted")
-- isprefixgame = true;
-- end;
-- scripting.AddEventCallBack("NewCampaignStarted", isprefixgameOnNewCampaignStarted);


-- ***** ON UNITS MERGED ***** --

local function OnUnitsMerged(context)

  PopLog("Shortcut Triggered: " .. context.string);
  
  if context.string == "auto_merge_units"
  then
  
    scripting.game_interface:add_time_trigger("hide_panel", 0.2);
    
  end;
end;

scripting.AddEventCallBack("ShortcutTriggered", OnUnitsMerged);


function FactionArmyIncrease(context)
  local faction = context:faction();
  local total_faction_population = 0;
  local regionPopTable = {0,0,0,0};
  local RegiontotalPopulation = 0;
  local level = 0;

  -- Remove old bundle
  for k, v in ipairs(PoR2_army_cap_increase_bundle)
    do scripting.game_interface:remove_effect_bundle(v, faction:name())
  end;

  for i = 0, faction:region_list():num_items() - 1 do
    local regionName = faction:region_list():item_at(i):name();
    
    for p = 1, 3 do
      regionPopTable[p] = region_table[regionName][p];
      RegiontotalPopulation = regionPopTable[1] + regionPopTable[2] + regionPopTable[3];
    end;
    -- get toal population
    total_faction_population = total_faction_population + RegiontotalPopulation;
  end;
  local step = 250000;
  local level = math.floor(total_faction_population / step);
  if level >= 10 then
    scripting.game_interface:apply_effect_bundle("PoR2_army_cap_increase_".."10", faction:name(), 99);
  elseif level >= 1 then
    scripting.game_interface:apply_effect_bundle("PoR2_army_cap_increase_"..level, faction:name(), 99);
  end;
  --local step = 250000;
 -- local max = step * 10;
 -- if total_faction_population >= max then
  --  scripting.game_interface:apply_effect_bundle("PoR2_army_cap_increase_"..max, faction:name(), 99);
  --  return
 -- end;
 -- for j = 1, 9 do
 --   level = step * j;
  --  if total_faction_population >= level and total_faction_population < level + step  then
  --    scripting.game_interface:apply_effect_bundle("PoR2_army_cap_increase_"..level, faction:name(), 99);
  --    break
  --  end;
 -- end;
end;

-- Threshold = 250.000 for an army
function calc_level(total_faction_population)
  local step = 250000;
  local level = math.floor(total_faction_population / step);
  if level >= 10 then
    scripting.game_interface:apply_effect_bundle("PoR2_army_cap_increase_"..10, faction:name(), 99);
  elseif level >= 1 then
    scripting.game_interface:apply_effect_bundle("PoR2_army_cap_increase_"..level, faction:name(), 99);
  end;
end;

--scripting.AddEventCallBack("FactionTurnStart", FactionArmyIncrease);
-- #####---------------------------------- END #####


-- =============================================================
-- === AI POP ENFORCER (Option A: snapshot -> diff -> enforce/remove)
-- === + Aggression Assist (siphon within province + small levy)
-- === Does NOT touch UI/growth/divisors. No global resets.
-- =============================================================

do
  local ai_pop_snapshot = {}  -- [faction_key] = { [char_cqi] = { [unit_cqi] = true } }

  local function _logpop(msg, tag, extra)
    if LogPop then
      LogPop(msg, tag or "ENFORCE", extra or "")
    elseif out then
      out("[POP ENFORCE] "..tostring(msg))
    end
  end

  -- Attempt to resolve unit -> (class, men). Prefer pack-provided libs.
  local function resolve_unit_pop(unit_key)
    if units_lib and units_lib.Get_Unit_Pop then
      local ok, cls, men = pcall(units_lib.Get_Unit_Pop, unit_key)
      if ok and cls and men then return cls, men end
    end
    -- Fallback heuristics (safe defaults; tune if needed)
    local k = tostring(unit_key)
    if string.find(k, "hoplite") or string.find(k, "royal") then
      return 1, 160  -- citizen
    elseif string.find(k, "thorax") or string.find(k, "spear") then
      return 2, 160  -- freemen
    elseif string.find(k, "peltast") or string.find(k, "slinger") or string.find(k, "javelin") then
      return 3, 120  -- lower
    elseif string.find(k, "cav") then
      return 1, 80   -- citizen cav
    else
      return 2, 120  -- default
    end
  end

  local function class_to_index(class)
    if type(class) == "number" then return math.max(1, math.min(4, class)) end
    class = tostring(class)
    if class == "noble" or class == "upper" or class == "citizen" then return 1 end
    if class == "mid" or class == "middle" or class == "freemen" then return 2 end
    if class == "low" or class == "lower" then return 3 end
    return 4
  end

  local function current_region_pop_and_key(char)
    if not char or char:is_null_interface() then return nil, nil end
    local r = char:region()
    if r and not r:is_null_interface() then
      local rk = r:name()
      return region_table[rk], rk
    end
    return nil, nil
  end

  local function snapshot_faction_armies(fac)
    local fkey = fac:name()
    local snap = {}
    local cl = fac:character_list()
    for i = 0, cl:num_items()-1 do
      local c = cl:item_at(i)
      if c:has_military_force() and c:military_force():is_army() then
        local m = {}
        local ul = c:military_force():unit_list()
        for j = 0, ul:num_items()-1 do
          local u = ul:item_at(j)
          m[u:command_queue_index()] = true
        end
        snap[c:command_queue_index()] = m
      end
    end
    ai_pop_snapshot[fkey] = snap
  end

  local function remove_unit_from_char(char, unit)
    if cm and unit and unit.unit_key and char then
      local unit_key = unit:unit_key()
      local ok = pcall(function() cm:remove_unit_from_character(char, unit_key) end)
      if ok then return true end
      ok = pcall(function()
        local mf = char:military_force()
        if mf then cm:remove_unit_from_military_force(mf, unit_key) end
      end)
      if ok then return true end
    end
    local ok = pcall(function()
      if unit.number_of_men then
        while unit:number_of_men() > 0 do unit:inflict_casualties(unit:number_of_men()) end
      end
    end)
    return ok
  end

  -- ===== Aggression Assist: siphon + small levy

  local AI_ENFORCE_TUNING = {
    WAR_ONLY = true,
SIPHON_FROM_SAME_PROVINCE = true,
    LEVY_MAX = { [1]=0, [2]=40, [3]=60, [4]=40 }, -- citizen=0 to keep elites rare
  }

  local function province_name_of_region_key(region_key)
    local r = cm:get_region(region_key)
    if r and not r:is_null_interface() then return r:province_name() end
    return nil
  end

  local function siphon_from_same_province(fac, target_region_key, class_index, missing)
    if not AI_ENFORCE_TUNING.SIPHON_FROM_SAME_PROVINCE then return 0 end
    local taken, prov = 0, province_name_of_region_key(target_region_key)
    if not prov then return 0 end
    local rl = fac:region_list()
    for i=0, rl:num_items()-1 do
      local reg = rl:item_at(i)
      if not reg:is_null_interface() and reg:name() ~= target_region_key and reg:province_name() == prov then
        local rk = reg:name()
        local pop = region_table[rk]
        if pop and pop[class_index] and pop[class_index] > 0 and taken < missing then
          local can = math.min(missing - taken, pop[class_index])
          pop[class_index] = pop[class_index] - can
          taken = taken + can
          SetRegionPop(rk, pop[1], pop[2], pop[3], pop[4])
          _logpop(("Siphon %d (class %d) from %s to cover recruit in %s"):format(can, class_index, rk, target_region_key), "ENFORCE-SIPHON", "")
          if taken >= missing then break end
        end
      end
    end
    return taken
  end

  local function emergency_levy(target_region_key, class_index, missing)
    local cap = (AI_ENFORCE_TUNING.LEVY_MAX or {})[class_index] or 0
    if cap <= 0 then return 0 end
    local add = math.min(cap, missing)
    local pop = region_table[target_region_key]
    if not pop then return 0 end
    pop[class_index] = (pop[class_index] or 0) + add
    SetRegionPop(target_region_key, pop[1], pop[2], pop[3], pop[4])
    _logpop(("Emergency levy %d (class %d) in %s"):format(add, class_index, target_region_key), "ENFORCE-LEVY", "")
    return add
  end

  local function try_cover_cost_with_province_and_levy(fac, target_region_key, class_index, need)
    local pop = region_table[target_region_key]
    if not pop then return false end
    local have = pop[class_index] or 0
    if have >= need then
      pop[class_index] = have - need
      SetRegionPop(target_region_key, pop[1], pop[2], pop[3], pop[4])
      return true
    end
    local missing = need - have
    local siphoned = siphon_from_same_province(fac, target_region_key, class_index, missing)
    missing = missing - siphoned
    if missing > 0 then
      local levied = emergency_levy(target_region_key, class_index, missing)
      missing = missing - levied
    end
    if missing <= 0 then
      pop = region_table[target_region_key]
      local now = pop[class_index] or 0
      pop[class_index] = now - need
      SetRegionPop(target_region_key, pop[1], pop[2], pop[3], pop[4])
      return true
    end
    return false
  end

  -- ===== Listeners

  scripting.AddEventCallBack("FactionTurnStart", function(context)
    local fac = context:faction()
    if fac and not fac:is_human() and not fac:is_dead() then
      snapshot_faction_armies(fac)
    end
  end)

  scripting.AddEventCallBack("FactionTurnEnd", function(context)
    local fac = context:faction()
    if not fac or fac:is_human() or fac:is_dead() then return end

    local fkey = fac:name()
    local prev = ai_pop_snapshot[fkey] or {}

    local cl = fac:character_list()
    for i = 0, cl:num_items()-1 do
      local c = cl:item_at(i)
      if c:has_military_force() and c:military_force():is_army() then
        local char_cqi = c:command_queue_index()
        local before = prev[char_cqi] or {}
        local ul = c:military_force():unit_list()
        for j = 0, ul:num_items()-1 do
          local u = ul:item_at(j)
          local uq = u:command_queue_index()
          if not before[uq] then
            local reg_pop, reg_key = current_region_pop_and_key(c)
            if reg_pop and reg_key then
              local cls, men = resolve_unit_pop(u:unit_key())
              local idx = class_to_index(cls)
              local have = reg_pop[idx] or 0
              if have >= men then
                reg_pop[idx] = have - men
                SetRegionPop(reg_key, reg_pop[1], reg_pop[2], reg_pop[3], reg_pop[4])
                _logpop("AI recruit OK ("..u:unit_key()..") -deduct "..men, "ENFORCE", "region="..reg_key.." class="..idx)
              else
                local covered = try_cover_cost_with_province_and_levy(fac, reg_key, idx, men)
                if covered then
                  _logpop("AI recruit OK after assist ("..u:unit_key()..") -covered "..men, "ENFORCE", "region="..reg_key.." class="..idx)
                else
                  local removed = remove_unit_from_char(c, u)
                  _logpop("AI recruit BLOCKED ("..u:unit_key()..") -insufficient pop; removed="..tostring(removed), "ENFORCE", "region="..reg_key.." class="..idx)
                end
              end
            end
          end
        end
      end
    end

    snapshot_faction_armies(fac)
  end)
end
-- ====================== END AI POP ENFORCER ======================

-- =========================
-- Logging Bridge for "movie"-type logging packs
-- Forwards our LogPop / PopLog / Debug into `out(...)` so external pack can capture.
-- =========================
do
  local LOG_BRIDGE = {
    enable = true,
    always_out = true,       -- forward even if isLogAllowed/isLogPopAllowed are false
    prefix = "[PoR2]"
  }

  local function _safe_out(msg)
    if LOG_BRIDGE.enable and type(out) == "function" then
      pcall(out, tostring(msg))
    end
  end

  if type(LogPop) == "function" then
    local _old_LogPop = LogPop
    LogPop = function(ftext, rownum, text, isTitle, isNew)
      if LOG_BRIDGE.always_out then
        local stamp = os.date("%c")
        local title_prefix = (isTitle and "[TITLE]" or "")
        _safe_out(string.format("%s%s [LogPop][%s]:%s %s -- %s", LOG_BRIDGE.prefix, title_prefix, tostring(ftext), tostring(rownum), tostring(text), stamp))
      end
      return _old_LogPop(ftext, rownum, text, isTitle, isNew)
    end
  end

  if type(PopLog) == "function" then
    local _old_PopLog = PopLog
    PopLog = function(text, ftext)
      if LOG_BRIDGE.always_out then
        local stamp = os.date("%c")
        _safe_out(string.format("%s [PopLog] %s : %s -- %s", LOG_BRIDGE.prefix, tostring(text), tostring(ftext), stamp))
      end
      return _old_PopLog(text, ftext)
    end
  end

  if type(Debug) == "function" then
    local _old_Debug = Debug
    Debug = function(text, ftext)
      if LOG_BRIDGE.always_out then
        local stamp = os.date("%c")
        _safe_out(string.format("%s [Debug] %s : %s -- %s", LOG_BRIDGE.prefix, tostring(text), tostring(ftext), stamp))
      end
      return _old_Debug(text, ftext)
    end
  end
end
-- =========================
-- End Logging Bridge
-- =========================
