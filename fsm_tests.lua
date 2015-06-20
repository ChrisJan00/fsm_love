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

local fsm = require 'fsm'

local get_filename = function() 
    local fn = debug.getinfo(2,"S").short_src
    local index = string.find(fn, "/[^/]*$")
    if index then
        return fn:sub(index+1)
    end
    return fn
end

local filename = get_filename()

local function compare(result, expected)
    if result == expected then return end
    if type(result) == "number" and type(expected) == "number" and 
        result == expected then
        return true
    end

    local linenumber = debug.getinfo(2,"l").currentline
    print("FAIL")
    print(filename..":"..linenumber)
    print("result:\n"..tostring(result))
    print("expected:\n"..tostring(expected))
    error()
end

function runTests(tests)
    local passedCount = 0
    for i=1,#tests do
        io.write("....test "..i.." ..")
        local passed,errmsg = pcall(tests[i])
        if passed then
            print("OK")
            passedCount = passedCount + 1
        elseif errmsg then
                print("FAIL")
                print(errmsg)
        end
    end

    print("\nPassed "..passedCount.." / "..#tests.." tests")
end

local tests = {
    function()
        -- create empty machine, update once, draw once -> should not crash
        local testMac = fsm.createMachine()
        testMac:update(1)
        testMac:draw()
    end,

    function()
        -- create machine, add 1 state, update without activation (nothing should happen), update with activation (something should happen)
        local testVal = 0
        local testMac = fsm.createMachine():addState(fsm.createState():withDraw(function() testVal = testVal + 1 end))
        testMac:update(1)
        testMac:draw()
        compare(testVal, 0)
        testMac:activateState(1)
        testMac:update(1)
        testMac:draw()
        compare(testVal, 1)
    end,

    function()
        -- create machine with 2 tests, switch between them on timer
        local currentLabel = "zero"
        local state1 = fsm.createState("first"):withBegin(function() currentLabel = "one" end):timedSwitch("second",1)
        local state2 = fsm.createState("second"):withBegin(function() currentLabel = "two" end):timedSwitch("first",1)
        local testMac = fsm.createMachine():addStates(state1, state2)
        compare(currentLabel, "zero")
        testMac:setInitialState("first"):restart()
        compare(currentLabel,"one")
        testMac:update(1)
        compare(currentLabel,"two")
        testMac:update(1)
        compare(currentLabel,"one")
    end,

    function()
        -- create machine with 2 tests, switch with condition
        local currentLabel = "zero"
        local state1 = fsm.createState("first"):withBegin(function() currentLabel = "one" end):conditionSwitch("second",function() return true end)
        local state2 = fsm.createState("second"):withBegin(function() currentLabel = "two" end):conditionSwitch("first",function() return false end)
        local testMac = fsm.createMachine():addStates(state1, state2)
        compare(currentLabel, "zero")
        testMac:setInitialState("first"):restart()
        compare(currentLabel,"one")
        testMac:update(1)
        compare(currentLabel,"two")
        testMac:update(1)
        compare(currentLabel,"two")
        return true
    end,

    function()
        -- create machine with 1 state.  clone machine.  update both.  each machine should be independent from the other one
        local state1 = fsm.createState("a"):timedSwitch("b",2)
        local state2 = fsm.createState("b")
        state1.count = 0
        local mac1 = fsm.createMachine():addStates(state1, state2)
        local mac2 = mac1:copy()

        mac1:activateState("a")
        mac2:activateState("a")

        mac1:update(1)
        mac2:update(1)

        compare(mac1.current.name, "a")
        compare(mac2.current.name, "a")

        mac1:update(0.5)
        mac2:update(1)
        compare(mac1.current.name, "a")
        compare(mac2.current.name, "b")

    end,

    function()
        -- create machine, 3 states.  First state with 2 conditions to each of the other two sets

        local wantedState = "none"
        local state1 = fsm.createState("first")
            :conditionSwitch("second", function() return wantedState == "second" end)
            :conditionSwitch("third", function() return wantedState == "third" end)
        local state2 = fsm.createState("second")
            :conditionSwitch("first", function() return true end)
        local state3 = fsm.createState("third")
            :conditionSwitch("first", function() return true end)
        local testMac = fsm.createMachine():addStates(state1, state2, state3)
        testMac:setInitialState("first"):restart()

        compare(testMac.current.name, "first")
        testMac:update(1)

        compare(testMac.current.name, "first")
        wantedState = "third"

        testMac:update(1)
        compare(testMac.current.name, "third")

        testMac:update(1)
        compare(testMac.current.name, "first")

        wantedState = "second"
        testMac:update(1)
        compare(testMac.current.name, "second")

        testMac:update(1)
        compare(testMac.current.name, "first")

        testMac:update(1)
        compare(testMac.current.name, "second")
    end,

}

runTests(tests)