--------------------------------------------------------------------------------
-- GC Scripts (Cleaned)
-- Purpose: keep only working/salvageable logic. Removes non-existent Rome II API
-- calls (direct AI orders, propose_peace, prioritize_building, etc.), stubs
-- undefined helpers safely, and restores Rome–Carthage escalation WITHOUT spawns.
--------------------------------------------------------------------------------

-- Optional module declaration (keep if your environment uses modules)
-- module(..., package.seeall);

-- === Safe helpers / fallbacks (only defined if missing) ======================
if contains == nil then
  function contains(val, list)
    if type(list) ~= "table" then return false end
    for _, v in pairs(list) do
      if v == val then return true end
    end
    return false
  end
end

if GetPlayerFactionsbyName == nil then
  function GetPlayerFactionsbyName()
    local res = {}
    local world = cm:model():world()
    local fl = world:faction_list()
    for i = 0, fl:num_items() - 1 do
      local f = fl:item_at(i)
      if f:is_human() then table.insert(res, f:name()) end
    end
    return res
  end
end

if GetFactionTreaties == nil then
  -- Fallback: return empty allied/enemy lists if your full utility isn't loaded.
  function GetFactionTreaties(treaty_details) return {}, {} end
end

-- Ensure core regions table exists to avoid nil errors (use your real list elsewhere)
core_regions_rome = core_regions_rome or {}

-- === Persistent escalation state =============================================
AIRomeCarthageEscalationTriggered = AIRomeCarthageEscalationTriggered or false
AICarthageRomeEscalationTriggered = AICarthageRomeEscalationTriggered or false
AIRomeCarthageEscalationLevel     = AIRomeCarthageEscalationLevel     or 0
AICarthageRomeEscalationLevel     = AICarthageRomeEscalationLevel     or 0

-- Save/Load
local function GC_Save(context)
  cm:save_value("AIRomeCarthageEscalationTriggered", AIRomeCarthageEscalationTriggered, context)
  cm:save_value("AICarthageRomeEscalationTriggered", AICarthageRomeEscalationTriggered, context)
  cm:save_value("AIRomeCarthageEscalationLevel", AIRomeCarthageEscalationLevel, context)
  cm:save_value("AICarthageRomeEscalationLevel", AICarthageRomeEscalationLevel, context)
end

local function GC_Load(context)
  AIRomeCarthageEscalationTriggered = cm:load_value("AIRomeCarthageEscalationTriggered", false, context)
  AICarthageRomeEscalationTriggered = cm:load_value("AICarthageRomeEscalationTriggered", false, context)
  AIRomeCarthageEscalationLevel     = cm:load_value("AIRomeCarthageEscalationLevel", 0, context)
  AICarthageRomeEscalationLevel     = cm:load_value("AICarthageRomeEscalationLevel", 0, context)
end

scripting.AddEventCallBack("SavingGame", GC_Save)
scripting.AddEventCallBack("LoadingGame", GC_Load)

--------------------------------------------------------------------------------
-- Rome–Carthage Escalation (spawn-free)
--------------------------------------------------------------------------------
-- Player is not Rome
function RomeCarthageEscalation(context)
  if AIRomeCarthageEscalationTriggered == false and AICarthageRomeEscalationTriggered == false then
    local MaxAIRomeCarthageEscalation = 8
    local faction = context:faction()
    local factionName = faction:name()
    local AlliedFactionKeys, EnemyFactionKeys = GetFactionTreaties(faction:treaty_details())
    local RegionLost = false

    local region_Syracuse = cm:model():world():region_manager():region_by_key("emp_sicily_syracuse")
    local owner_Syracuse = region_Syracuse:owning_faction():name()

    local region_Lilybaeum = cm:model():world():region_manager():region_by_key("emp_sicily_agrigentum")
    local owner_Lilybaeum = region_Lilybaeum:owning_faction():name()

    local region_Lilybaeum_1 = cm:model():world():region_manager():region_by_key("emp_sicily_panormus")
    local owner_Lilybaeum_1 = region_Lilybaeum_1:owning_faction():name()

    local region_rome_capital = cm:model():world():region_manager():region_by_key("emp_latium_roma")
    local owner_region_rome_capital = region_rome_capital:owning_faction():name()

    -- Has Rome lost a core region to an enemy?
    for i = 1, #core_regions_rome do
      local r = cm:model():world():region_manager():region_by_key(core_regions_rome[i])
      if not r:is_null_interface() then
        local ownerName = r:owning_faction():name()
        if ownerName ~= factionName and contains(ownerName, EnemyFactionKeys) then
          RegionLost = true
          break
        end
      end
    end

    if RegionLost == false then
      if AIRomeCarthageEscalationLevel == 0 and (owner_region_rome_capital == "rom_rome") then
        scripting.game_interface:show_message_event("custom_event_500", 0, 0)
      end
      AIRomeCarthageEscalationLevel = AIRomeCarthageEscalationLevel + 1
    end

    if ((owner_Lilybaeum == "rom_carthage") or (owner_Lilybaeum == "rom_syracuse"))
      and ((owner_Lilybaeum_1 == "rom_carthage") or (owner_Lilybaeum_1 == "rom_syracuse"))
      and RegionLost == false and AIRomeCarthageEscalationLevel > 4 then
      scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_carthage", "rom_rome", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES")
      scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_rome", "rom_carthage", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES")
    end

    if AIRomeCarthageEscalationLevel == 5 and owner_Lilybaeum == "rom_carthage" and owner_Lilybaeum_1 == "rom_carthage" then
      scripting.game_interface:show_message_event("custom_event_176", 0, 0)
      AIRomeCarthageEscalationLevel = AIRomeCarthageEscalationLevel + 1
    end

    if ((owner_Syracuse == "rom_carthage") or (owner_Syracuse == "rom_masaesyli")) then
      if AIRomeCarthageEscalationLevel < MaxAIRomeCarthageEscalation then
        AIRomeCarthageEscalationLevel = AIRomeCarthageEscalationLevel + 1
      else
        scripting.game_interface:force_declare_war("rom_rome", "rom_carthage")
        scripting.game_interface:show_message_event("custom_event_179", 0, 0)
        AIRomeCarthageEscalationTriggered = true
      end
    end
  end
end

-- Player is not Carthage
function CarthageRomeEscalation(context)
  if AICarthageRomeEscalationTriggered == false and AIRomeCarthageEscalationTriggered == false then
    local MaxAICarthageRomeEscalation = 8
    local faction = context:faction()
    local player_factions = GetPlayerFactionsbyName()
    local factionName = faction:name()

    local region_Carthage = cm:model():world():region_manager():region_by_key("emp_africa_carthago")
    local owner_Carthage = region_Carthage:owning_faction():name()

    local region_Syracuse = cm:model():world():region_manager():region_by_key("emp_sicily_syracuse")
    local owner_Syracuse = region_Syracuse:owning_faction():name()

    local RegionLost = false
    local Romefaction = cm:model():world():faction_by_key("rom_rome")
    local AlliedFactionKeys, EnemyFactionKeys = GetFactionTreaties(Romefaction:treaty_details())

    if owner_Carthage == "rom_carthage" then
      for i = 1, #core_regions_rome do
        local r = cm:model():world():region_manager():region_by_key(core_regions_rome[i])
        if not r:is_null_interface() then
          local ownerName = r:owning_faction():name()
          if ownerName ~= "rom_rome" and contains(ownerName, EnemyFactionKeys) then
            RegionLost = true
            break
          end
        end
      end
    end

    if RegionLost == false then
      if AICarthageRomeEscalationLevel == 0 and contains("rom_rome", player_factions) then
        scripting.game_interface:show_message_event("custom_event_500", 0, 0)
      end
      AICarthageRomeEscalationLevel = AICarthageRomeEscalationLevel + 1
    end

    if AICarthageRomeEscalationLevel > 4 then
      if AICarthageRomeEscalationLevel == 5 and contains("rom_rome", player_factions) then
        scripting.game_interface:show_message_event("custom_event_504", 0, 0)
      end
      scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_rome", "rom_carthage", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES")
      scripting.game_interface:cai_strategic_stance_manager_promote_specified_stance_towards_target_faction("rom_carthage", "rom_rome", "CAI_STRATEGIC_STANCE_BITTER_ENEMIES")
    end

    -- Spawn REMOVED: keep war + message only
    if owner_Syracuse == "rom_rome" and AICarthageRomeEscalationLevel > MaxAICarthageRomeEscalation then
      scripting.game_interface:force_declare_war("rom_carthage", "rom_rome")
      scripting.game_interface:show_message_event("custom_event_173", 0, 0)
      AICarthageRomeEscalationTriggered = true
    end
  end
end

--------------------------------------------------------------------------------
-- Listener wiring (safe, once per turn per faction)
--------------------------------------------------------------------------------
local function OnWorldCreated_GC(context)
  -- Faction Turn Start: call only for the relevant factions, and only if the
  -- player is NOT that faction (to match original intent).
  cm:add_listener(
    "PunicEscalation_FTS",
    "FactionTurnStart",
    true,
    function(ctx)
      local f = ctx:faction()
      local fname = f:name()
      local player_factions = GetPlayerFactionsbyName()

      if fname == "rom_rome" and not contains("rom_rome", player_factions) then
        RomeCarthageEscalation(ctx)
      elseif fname == "rom_carthage" and not contains("rom_carthage", player_factions) then
        CarthageRomeEscalation(ctx)
      end
    end,
    true
  )
end

scripting.AddEventCallBack("WorldCreated", OnWorldCreated_GC)
