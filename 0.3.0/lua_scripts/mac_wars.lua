---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- 
-- Created by Dresden
-- Last Updated: July 26

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
-- AI Natural Recruitment
--===============================================================
function Turn()
	return scripting.game_interface:model():turn_number()
end

function AdjustAIRecruitment(faction)
    local manpower = GetFactionManpower(faction:name())
    
    if manpower < 10 then
        -- Stop recruitment
        return
    elseif manpower < 20 then
        -- Recruit lower-tier units only
        RecruitLowerTierUnits(faction:name())
    else
        -- Normal recruitment
        RecruitNormalUnits(faction:name())
    end
end

function RecruitLowerTierUnits(faction_name)
    scripting.game_interface:queue_recruitment(
        faction_name,
        {"militia_spearmen", "militia_archers", "militia_cavalry"},
        "some_region_key"
    )
end

function RecruitNormalUnits(faction_name)
    scripting.game_interface:queue_recruitment(
        faction_name,
        {"elite_legionnaires", "heavy_cavalry", "archers"},
        "some_region_key"
    )
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
        "FactionTurnStart_AIRecruitment",
        "FactionTurnStart",
        function(context)
            local faction = context:faction();
            return not faction:is_human();
        end,
        function(context)
            local faction = context:faction();
            AdjustAIRecruitment(faction)
            Log("AI recruitment adjustments completed for " .. faction:name());
        end,
        true
    );
end;

scripting.AddEventCallBack("WorldCreated", OnWorldCreatedCampaign);
