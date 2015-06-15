fsm_love
=============
by Christiaan Janssen

A convenience implementation of Finite State Machines (fsm).

Usage:
------

Including it in your project:

    fsm = require "fsm"

Creating:

    fsm.createMachine() -> machine                              returns an empty FSM
    fsm.createState([name]) -> state                            returns an empty [named] state

FSM API:

    machine:update(dt)                                          calls update(dt) on current active state
    machine:draw()                                              calls draw() on current active state

    machine:addState(state, [activate]) -> machine              adds "state" to the machine state list.  You can activate the state if flag set to true
    machine:addStates(...) -> machine                           adds a list of states to the list

    machine:activateState(state) -> machine                     activates state by reference, name, or position in the list if anonymous (accepts any of the options)
    machine:copy() -> machine                                   returns clone of the machine
    machine:setInitialState(state) -> machine                   marks passed state as the initial one
    machine:restart() -> machine                                activates the initial state if defined

State API:

    state:withInit(func) -> state                               sets func to be called when state is activated
    state:withFinish(func) -> state                             sets func to be called when state is disabled
    state:withUpdate(func(dt)) -> state                         sets func to be called on update
    state:withDraw(func) -> state                               sets func to be called on draw
  
    state:copy() -> state                                       returns clone of state

    state:timedSwitch(newState, delay) -> state                 sets a timer so that parent machine will activate newState after delay seconds
    state:conditionSwitch(newState, func) -> state              sets a function that will be called on each call to update, if func returns true parent switches to newState
    state:expoUpSwitch(newState, factor, [thr]) -> state        increases a value exponentially from 0 to 1 with factor exponent.  When value reaches 1 - 1-e-3 (or thr if given), parent switches
    state:expoDownSwitch(newState, factor, [thr]) -> state      same as before, decreasing exponentially with factor exponent


Examples:

    see test suite



-- Christiaan Janssen, June 2015
