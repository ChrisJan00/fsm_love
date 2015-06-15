-- fsm_love: a small library for finite state machines

-- zlib license
-- Copyright (c) 2014-2015 Christiaan Janssen

-- This software is provided 'as-is', without any express or implied
-- warranty. In no event will the authors be held liable for any damages
-- arising from the use of this software.

-- Permission is granted to anyone to use this software for any purpose,
-- including commercial applications, and to alter it and redistribute it
-- freely, subject to the following restrictions:

-- 1. The origin of this software must not be misrepresented; you must not
--    claim that you wrote the original software. If you use this software
--    in a product, an acknowledgement in the product documentation would be
--    appreciated but is not required.
-- 2. Altered source versions must be plainly marked as such, and must not be
--    misrepresented as being the original software.
-- 3. This notice may not be removed or altered from any source distribution.


local FSM = {}


local state_proto = {
    withInit = function(self, func)
        self.init = func
        return self
    end,

    withFinish = function(self, func)
        self.finish = func
        return self
    end,

    withUpdate = function(self, func) 
        self.update = func
        return self
    end,

    withDraw = function(self, func)
        self.draw = func
        return self
    end,
    copy = function(self)
        local newState = FSM.createState(self.name)
        for k,v in pairs(self) do
            newState[k] = v
        end
        return newState
    end,
    timedSwitch = function(self, newState, delay)
        self.begin = function(self)
            self.timer = delay
        end

        self.condition = function(self, dt)
            self.timer = self.timer - dt
            if self.timer <= 0 then
                self.parent:activateState(newState)
            end
        end
        return self
    end,
    conditionSwitch = function(self, newState, func)
        self.condition = function(self)
            if func() then
                self.parent:activateState(newState)
            end
        end
        return self
    end,

}

local state_mt = {
    __index = function(table, key) return state_proto[key] end,
}

function FSM.createState(stateName)
    local state = { name = stateName }
    setmetatable(state, state_mt)
    return state
end

local machine_proto = {
    addState = function(self, state, activate)
        state.parent = self
        if activate then
            self.current = state
            if state.begin then state:begin() end
        end
        if state.name then
            self.stateList[state.name] = state
        else
            table.insert(self.stateList, state)
        end
        return self
    end,

    addStates = function(self,...)
        for i=1,select("#",...) do
            self:addState(select(i,...))
        end
        return self
    end,

    update = function(self, dt)
        if self.current then
            if self.current.update then
                self.current:update(dt)
            end
            if self.current.condition then
                self.current:condition(dt)
            end
        end
    end,

    draw = function(self)
        if self.current and self.current.draw then
            self.current:draw()
        end
    end,

    activateState = function(self, newState)
        if type(newState) ~= "table" then
            newState = self.stateList[newState]
        end
        if self.current and self.current.finish then
            self.current:finish()
        end
        self.current = newState
        if self.current and self.current.init then
            self.current:init()
        end
        if self.current and self.current.begin then
            self.current:begin()
        end
    end,

    copy = function(self)
        local newMachine = FSM.createMachine(self.name)
        for k,v in pairs(self) do
            newMachine[k] = v
        end
        -- create copies of states
        newMachine.stateList = {}
        for k,v in pairs(self.stateList) do
            newMachine.stateList[k] = v:copy()
            newMachine.stateList[k].parent = newMachine
        end
        return newMachine
    end,

    setInitialState = function(self, initialState)
        self.initialState = initialState
        return self
    end,

    restart = function(self)
        if self.initialState then
            self:activateState(self.initialState)
        end
        return self
    end,

}

local machine_mt = {
    __index = function(table, key) return machine_proto[key] end,
}

function FSM.createMachine()
    local machine = { stateList = {} }
    setmetatable(machine, machine_mt)
    return machine
end

return FSM
