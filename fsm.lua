FSM = FSM or {}

local function increaseExponential(dt, var, amount)
    if var < 1 then
        var = 1 - (1 - var) * math.pow(amount, 60*dt)
        if var > 0.999 then
            var = 1
        end
    end
    return var
end

local function decreaseExponential(dt, var, amount)
    if var > 0 then
        var = var * math.pow(amount, 60*dt)
        if var < 0.001 then
            var = 0
        end
    end
    return var
end

local state_proto = {
    withUpdate = function(self, func) 
        self.update = func
        return self
    end,

    withDraw = function(self, func)
        self.draw = func
        return self
    end,
    copy = function(self)
        local newState = FSM.makeState(self.name)
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
    expoUpSwitch = function(self, newState, factor, thr)
        self.begin = function(self)
            self.thr = thr or 1
            self.expoVar = 0
        end

        self.condition = function(self, dt)
            self.expoVar = increaseExponential(dt, self.expoVar, factor)
            if self.expoVar >= self.thr then
                self.parent:activateState(newState)
            end
        end
        return self
    end,
    expoDownSwitch = function(self, newState, factor, thr)
        self.begin = function(self)
            self.thr = thr or 0
            self.expoVar = 1
        end

        self.condition = function(self, dt)
            self.expoVar = decreaseExponential(dt, self.expoVar, factor)
            if self.expoVar <= self.thr then
                self.parent:activateState(newState)
            end
        end
        return self
    end,


}

local state_mt = {
    __index = function(table, key) return state_proto[key] end,
}

function FSM.makeState(stateName)
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

function FSM.create()
    local machine = { stateList = {} }
    setmetatable(machine, machine_mt)
    return machine
end

