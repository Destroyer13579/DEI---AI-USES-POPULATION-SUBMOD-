allEvents = {}
allTraits = {}
allParties = {}

----------------------------------------------------------------------------------------------------------------------
-- EVENT
----------------------------------------------------------------------------------------------------------------------

Event = {
	onAdd = function(self)
		return true
	end,

	-- enums events list and calls func for every item matches the event filter id and event params, stops if func returns false
	enum = function(self, events, filter, noparams, func)
		for i,e in ipairs(events) do
			-- not older than me
			if tostring(e) == tostring(self) then
				break
			end

			local eventID = filter and filter.action_event_id or e.id
			if e.id == eventID then
				local valid = true
				if noparams == false and self.params then
					for paramID, paramValue in pairs(self.params) do
						if e.params[paramID] ~= paramValue then
							valid = false
							break
						end
					end
				end
				if valid == true and func and type(func) == "function" then
					if func(i) == false then
						break
					end
				end
			end
		end
	end,

	find = function(self, events, filter, noparams)
		local index = 0
		local found = false
		self:enum(events, filter, noparams, function(idx)
			found = true
			index = idx
			return false 
		end)
		return found, index
	end,

	addAction = function(self, context_id, context, actions)
		local action = deepCopy(context)

		if self.event_expire and not context.action_expire and not context.action_support_step and not context.action_power_step then
			action.action_remove = true
		end

		if not action.id then
			action.id = self.id
		end

		if not action.params then
			action.params = self.params
		end

		table.insert(actions, action)
		--POLIT.printl("  EVENT "..self.id.." ADD ACTION "..context_id)
	end,

	createActions = function(self, events, actions, party)
		--POLIT.printl("EVENT "..self.id.." CREATE ACTIONS")

		-- this condition must be executed first if exists
		if self.action_del_event then
			--POLIT.printl("  action_del_event")
			self:enum(events, self.action_del_event, false, function(event)
				event.deleted_by_event = true
				return true
			end)
			self.action_del_event = nil
		end

		-- check if event expires
		if self.event_expire then
			self.event_expire = self.event_expire - 1
			self.turn_state = "modified params"

			if self.event_expire == 0 then
				self.event_expired = true
			end
		end

		-- check event conditions
		if self.action_if_exist then
			--POLIT.printl("  action_if_exist")
			local found = self:find(events, self.action_if_exist)
			if found == true then
				if self.action_if_exist.action_event_for_turns then
					self.action_if_exist.action_event_for_turns = self.action_if_exist.action_event_for_turns - 1
					self.turn_state = "modified params"

					if self.action_if_exist.action_event_for_turns == 0 then
						self:addAction("action_if_exist", self.action_if_exist)
						self.turn_state = "executed"
					end
				else
					self:addAction("action_if_exist", self.action_if_exist, actions)
					self.turn_state = "executed"
				end
			end
		elseif self.action_if_not_exist then
			--POLIT.printl("  action_if_not_exist")
			local found = self:find(events, self.action_if_not_exist)
			if found == false then
				if self.action_if_not_exist.action_event_for_turns then
					self.action_if_not_exist.action_event_for_turns = self.action_if_not_exist.action_event_for_turns - 1
					self.turn_state = "modified params"

					if self.action_if_not_exist.action_event_for_turns == 0 then
						self:addAction("action_if_not_exist", self.action_if_not_exist, actions)
						self.turn_state = "executed"
					end
				else
					self:addAction("action_if_not_exist", self.action_if_not_exist, actions)
					self.turn_state = "executed"
				end
			end
		elseif self.action_per_party then
			assert(self.params.party_name, "Missing param PARTY_NAME to compare !!!")
			if self.params.party_name == party.name then
				if self.action_per_party.own_party then
					self:addAction("action_per_party", self.action_per_party.own_party, actions)
					self.turn_state = "executed"
				end
			else
				if self.action_per_party.other_party then
					self:addAction("action_per_party", self.action_per_party.other_party, actions)
					self.turn_state = "executed"
				end
			end
		elseif self.action_per_level then
			assert(self.params.level, "Missing param LEVEL to switch to !!!")
			assert(self.action_per_level[self.params.level], "Missing action table for this level("..self.params.level..") !!!")
			if self.action_per_level[self.params.level] then
				self:addAction("action_per_level", self.action_per_level[self.params.level], actions)
				self.turn_state = "executed"
			end
		else
			--POLIT.printl("  event no condition")
			self:addAction(self.id, self, actions)
			self.turn_state = "executed"
		end
	end,

	onRemove = function(self, actions)
		--POLIT.printl("EVENT "..self.id.." ON REMOVE")

		if not actions then return true end

		for i = #actions, 1, -1 do	
			if actions[i].id == self.id and not actions[i].action_expire and not actions[i].action_support_step and not actions[i].action_power_step then
				-- POLIT.printl("  EVENT "..self.id.." DELETE ACTIONS")
				-- dumpTbl(actions[i])
				table.remove(actions, i)
			end
		end

		return true;
	end,
}

function eventDef(def)
	if not def.event_internal then
		POLIT.register_def("event", def)
	end
	setBase(def, Event)
	allEvents[def.id] = def
 	return def
end

----------------------------------------------------------------------------------------------------------------------
-- TRAIT
----------------------------------------------------------------------------------------------------------------------
Trait = {
	type = "trait",

	init = function(self)
		self.events = {}
		self.actions = {}
	end,

	setState = function(self, trait_state)
		self.actions = trait_state.actions or {}
		self.events = trait_state.events or {}

		for i, state_event in ipairs(self.events) do
			setBase(self.events[i], Event)
		end
	end,

	getState = function(self, party_state)
		if not party_state[self.id] then party_state[self.id] = {} end
		if #self.events > 0 then
			party_state[self.id].events = self.events
		end
		if #self.actions > 0 then
			party_state[self.id].actions = self.actions
		end
	end,

	onEvent = function(self, id, params)
		local event = deepCopy(self.eventDefs[id])
		event.id = id

		if params then
			event.params = deepCopy(params)
		end

		-- POLIT.printl("Add EVENT")
		-- dumpTbl(event)

		-- leave if there is same event with params
		if event.event_unique == true and event:find(self.events, { action_event_id = id }, false) then
			local k,v = getFirst(params)
			POLIT.printl("[POLITICAL SYSTEM]: Event with same ID("..id..") and PARAMS("..v..") already exist")
			return
		end

		if event.event_replace_noparams == true then
			local bFound, index = event:find(self.events, { action_event_id = id }, true)
			if bFound == true then
				if self.events[index]:onRemove(self.actions) == true then
					table.remove(self.events, index)
				end
			end
		end

		if event:onAdd() == true then
			table.insert(self.events, event)
		end
	end,

	executeAction = function(self, work)
		-- calculate support and power
		for _,key in pairs( {"action_support", "action_power"}) do
			local value = self[key] or nil
			if value ~= nil then
				if not work[key] then work[key] = 0 end

				work[key] = work[key] + value

				if self.action_min and work[key] < self.action_min then
					work[key] = self.action_min
				elseif self.action_max and work[key] > self.action_max then
					work[key] = self.action_max
				end

				local step = self[key.."_step"] or 0
				if step ~= 0 then
					self[key] = self[key] + step
					-- checkif modifier is null, remove the action

					if self[key] == 0 then
						self.action_remove = true
					end
				end
			end
		end
	end,

	onTurn = function(self, party)
		--POLIT.printl("TRAIT "..self.id)

		if self.id == "WarBegin" then
			-- If the faction is weak and has lost battles, consider peace
			if self.params.faction_id and isFactionWeakened(self.params.faction_id) then
				POLIT.on_event(self.params.faction_id, { offer_demand_peace = true })
			end
		end
		
		-- add default trait event if not exist one (with modified params)
		if self.eventDefs[self.id] then
			local found = false
			for i,v in ipairs(self.events) do
				if v.id == self.id then
					found = true
				end
			end

			if not found then
				self:onEvent(self.id)
			end
		end

		-- create actions
		for _, event in ipairs(self.events) do
			--POLIT.printl("Create actions for "..event.id)
			event:createActions(self.events, self.actions, party)
		end

		-- remove marked for delete or expired events and their actions
		for i = #self.events, 1, -1 do
			if self.events[i].deleted_by_event or self.events[i].event_expired or self.events[i].event_delete_on_execute then
				if self.events[i]:onRemove(self.actions) == true then
					table.remove(self.events, i)
				end
			end
		end

		-- calc actions
		local per_event = {}
		for i,v in ipairs(self.actions) do
			if not per_event[self.actions[i].id] then
				per_event[self.actions[i].id] = {}
			end

			self.executeAction(self.actions[i], per_event[self.actions[i].id])

			if self.actions[i].action_expire then
				self.actions[i].action_expire = self.actions[i].action_expire - 1
			end
		end

		--dumpTbl(self.actions)

		-- remove expired or marked for remove actions
		for i = #self.actions, 1, -1 do
			if self.actions[i].action_remove or (self.actions[i].action_expire and self.actions[i].action_expire == 0) then
				--POLIT.printl("ACTION EXPIRED "..self.actions[i].id)
				table.remove(self.actions, i)
			end
		end

		-- remove default event and his actions form actions list if needed, remove turn_state for next turn
		for i = #self.events, 1, -1 do
			local removed = false
			if self.events[i].id == self.id then
				if self.events[i].turn_state ~=  "modified params" and self.events[i]:onRemove(self.actions) == true then
					--POLIT.printl("DELETE DEFAULT EVENT "..self.events[i].id)
					table.remove(self.events, i)
					removed = true
				end
			end
			if not removed then
				self.events[i].turn_state = nil
			end
		end

		-- calculate trait support and power
		local support = 0
		local power = 0

		for event_id, event_tbl in pairs(per_event) do
			if event_tbl.action_support then
				event_tbl.support = event_tbl.action_support
				support = support + event_tbl.action_support
				event_tbl.action_support = nil
			end

			if event_tbl.action_power then
				even_tbl.power = event_tbl.action_power
				power = power + event_tbl.action_power
				event_tbl.action_power = nil
			end
		end

		-- construct the return table
		if support ~= 0 or power ~= 0 then
			per_event.type = self.type

			if power ~= 0 then
				per_event.power = power
			end

			if support ~= 0 then
				per_event.support = support
			end
			-- POLIT.printl("      TRAIT "..self.id)
			-- dumpTbl(per_event, 6)
			return per_event
		end
	end
}

function isFactionWeakened(faction_id)
    local faction = cm:model():world():faction_by_key(faction_id)

    if not faction or faction:is_human() then
        return false -- AI should not force peace on a human
    end

    local strength_ratio = faction:military_strength() / getEnemyStrength(faction)
    local lost_cities = faction:region_list():num_items() < faction:home_region_count()
    local recent_defeats = getFactionDefeats(faction_id) > getFactionVictories(faction_id)
    local war_weariness = getWarWeariness(faction_id)

    -- Conditions for peace proposal
    if strength_ratio < 0.5 or lost_cities or recent_defeats or war_weariness > 50 then
        return true
    end

    return false
end

function getEnemyStrength(faction)
    local total_strength = 0
    local enemies = faction:factions_at_war_with()

    for i = 0, enemies:num_items() - 1 do
        local enemy = enemies:item_at(i)
        total_strength = total_strength + enemy:military_strength()
    end

    return math.max(total_strength, 1) -- Prevent division by zero
end

function getFactionDefeats(faction_id)
    local defeats = 0
    for _, event in ipairs(POLIT.all_faction_data[faction_id].events or {}) do
        if event.id == "MilitaryDefeat" then
            defeats = defeats + 1
        end
    end
    return defeats
end

function getFactionVictories(faction_id)
    local victories = 0
    for _, event in ipairs(POLIT.all_faction_data[faction_id].events or {}) do
        if event.id == "MilitaryVictory" then
            victories = victories + 1
        end
    end
    return victories
end

function getWarWeariness(faction_id)
    local weariness = 0
    for _, event in ipairs(POLIT.all_faction_data[faction_id].events or {}) do
        if event.id == "CityLost" or event.id == "MilitaryDefeat" then
            weariness = weariness + 10 -- Losing battles adds exhaustion
        end
    end
    return math.min(weariness, 100) -- Cap war weariness at 100
end

function traitDef(def)
	setBase(def, Trait)
	POLIT.register_def(def.type, def)
  	allTraits[def.id] = def
	return def
end

----------------------------------------------------------------------------------------------------------------------
-- PARTY
----------------------------------------------------------------------------------------------------------------------
Party = {
	init = function(self, id)
		self.id = "party_"..id

		local actual_traits = {}

		-- actual_traits["GlobalTrait"] = deepCopy(allTraits["GlobalTrait"])
		-- actual_traits["GlobalTrait"]:init()

		if self.traits then
			for _,trait_id in ipairs(self.traits) do
				actual_traits[trait_id] = deepCopy(allTraits[trait_id])
				actual_traits[trait_id]:init()
			end
		end

		self.traits = actual_traits
	end,

	setState = function(self)
		local actual_traits = {}
		for trait_id, trait in pairs(self.traits) do
			actual_traits[trait_id] = deepCopy(allTraits[trait_id])
			actual_traits[trait_id]:setState(trait)
		end

		self.traits = actual_traits
	end,

	getState = function(self, state)
		local party_state = {}

		party_state.id = self.id
		party_state.name = self.name
		party_state.support = self.support
		party_state.power = self.power
		party_state.leader = self.leader
		party_state.traits = {}

		-- fill party traits data
		for trait_id, trait in pairs(self.traits) do
			trait:getState(party_state.traits)
		end

		table.insert(state, party_state)
	end,

	setLeader = function(self, leader)
		-- remove the old leader traits
		self.leader = nil

		for trait_id, trait in pairs(self.traits) do
			if trait.type == "leader" then
				self.traits[trait_id] = nil
			end
		end

		if leader then
			-- create the new leader table
			self.leader = {
				name = leader.name,
				traits = leader.traits,
			}

			-- add the new leader traits to party traits
			if self.leader.traits then
				for _,trait_id in ipairs(self.leader.traits) do
					self.traits[trait_id] = deepCopy(allTraits[trait_id])
					self.traits[trait_id]:init()
				end
			end
		end
	end,

	onEvent = function(self, id, params)
		for trait_id, trait in pairs(self.traits) do
			if trait.eventDefs[id] then
				trait:onEvent(id, params)
			end
		end
	end,

	onTurn = function(self)
		self.power = 0
		self.support = 0
		local per_trait = {}

		for trait_id, trait in pairs(self.traits) do
			per_trait[trait_id] = trait:onTurn(self)

			if per_trait[trait_id] then
				if per_trait[trait_id].support ~= nil and per_trait[trait_id].support ~= 0 then
					self.support = self.support + per_trait[trait_id].support
				end

				if per_trait[trait_id].power ~= nil and per_trait[trait_id].power ~= 0 then
					self.power = self.power + per_trait[trait_id].power
				end
			end
		end

		--POLIT.printl("PARTY '"..self.name)
		--dumpTbl(per_trait, 1)
		return per_trait
	end,
}

function partyDef(def)
	setBase(def, Party)
	table.insert(allParties, def)
	return def
end

----------------------------------------------------------------------------------------------------------------------
-- GAME PARTY SYSTEM
----------------------------------------------------------------------------------------------------------------------

function onEndTurn(events, state)
	-- POLIT.printl("------------------------------------------------ RECEIVE STATE -----------------------------------------------")
	-- dumpTbl(state)
	-- POLIT.printl("--------------------------------------------------------------------------------------------------------------")
	
	allParties = {}
	for _, party in ipairs(state) do
		if party.trait_details then party.trait_details = nil end
		partyDef(party)
		party:setState()
	end

	-- distribute the events to parties
	for _,event in ipairs(events) do
		local event_id, event_params = getFirst(event)

		if event_id == "leader_set" then
			for _,party in ipairs(allParties) do
				if party.name == event_params.party then
					party:setLeader(event_params)
					break
				end
			end
		elseif event_id == "party_add" then
			local party = partyDef(event_params)
			party:init(#allParties)
			party:setState(state[party.id])
		else
			for _,party in ipairs(allParties) do
				party:onEvent(event_id, event_params)
			end
		end
	end

	-- make parties turn
	local per_parties = {}
	for _,party in ipairs(allParties) do
		per_parties[party.id] = party:onTurn()
	end

	-- gather the new state from parties and return it
	local new_state = {}
	for _,party in ipairs(allParties) do
		party:getState(new_state)
		if per_parties[party.id] and getFirst(per_parties[party.id]) then
			new_state[#new_state].trait_details = per_parties[party.id]
		end
	end

	-- POLIT.printl("------------------------------------------------ RETURN STATE -----------------------------------------------")
	-- dumpTbl(new_state)
	-- dumpTbl(per_parties)
	-- POLIT.printl("-------------------------------------------------------------------------------------------------------------")

	return new_state
end

POLIT.printl("POLITICAL SYSTEM - loaded.")
