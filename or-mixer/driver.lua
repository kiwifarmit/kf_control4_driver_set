local TimerManager = require "SKC4.TimerManager"
require "SKC4.LicenseManager"
require "SKC4.Utility"
require "SKC4.DriverCore"


-----------------------------------------------------
-- GLOBALS
-----------------------------------------------------
PROXY_ID_BINDING = 1

TIMER_FOR_POLLING = nil
TIMER_INTERVAL_FOR_POLLING = 10
TIMER_INTERVAL_SCALE_FOR_POLLING = "SECONDS"

PROPRETY_LAST_UPDATE_AT = "Last Update At"
PROPERTY_POLLING_INTERVAL = "Polling Interval"

INPUT_NUMBER = 30
-- definisco i nomi delle property
PROPERTY_RELAY_MAP = {}
for i = 1, INPUT_NUMBER do
  PROPERTY_RELAY_MAP[i] = "Connection " .. i .. " Mapping"
end
-- definisco il nome  delle connection in input
IDBINDING_CONNECTION_INPUT = {}
for i = 1, INPUT_NUMBER do
  IDBINDING_CONNECTION_INPUT[i] = i
end
-- definisco il nome  delle connection in output
OUTPUT_NUMBER = 40
IDBINDING_CONNECTION_OUTPUT = {}
for i = 1, OUTPUT_NUMBER do
  IDBINDING_CONNECTION_OUTPUT[i] = 50 + i
end
-- una mappa che collega l'input con i vari output
RELAY_MAP = C4:PersistGetValue("RELAY_MAP")
if RELAY_MAP == nil then
  RELAY_MAP = {}
  for i = 1, INPUT_NUMBER do
    RELAY_MAP[i] = {}
  end
end
-- ha come index l'output, e come value la table di tutti gli input collegati
-- lo stato dei relay in input
OUTPUT_MAP = C4:PersistGetValue("OUTPUT_MAP")
if OUTPUT_MAP == nil then
  OUTPUT_MAP = {}
end
RELAY_IN_STATUS = {}
for i = 1, INPUT_NUMBER do
  RELAY_IN_STATUS[i] = 0
end
RELAY_OUT_OLD_STATUS = {}

PROPERTY_DEBUG = "Debug"

EX_CMD = {}
PRX_CMD = {}
NOTIFY = {}
DEV_MSG = {}
LUA_ACTION = {}
ACTIONS = {}
--endPointCalls = {}
--controlledRelNr = {}
--RelayIsOn = {}

--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "shelly_25.c4z", "DRIVERCENTRAL")
LICENSE_MGR:setParamValue("ProductId", XXX, "HOUSELOGIX")
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX")
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")
LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo("version"), "HOUSELOGIX")
LICENSE_MGR:setParamValue("Trial", LICENSE_MGR.TRIAL_NOT_STARTED, "HOUSELOGIX")
--- end license
--------------------------------------------
-- REMOVE THIS TO ENABLE LICENCE MANAGEMENT 
LICENSE_MGR:isLicenseActive = function ()
  return true
end
LICENSE_MGR:isLicenseTrial = function ()
  return 1
end
--------------------------------------------

TIMER_FOR_CONTROL = nil
TIMER_INTERVAL_FOR_CONTROL = 10
TIMER_INTERVAL_SCALE_FOR_CONTROL = "SECONDS"
-----------------------------------------------------
-- AUTO INITIALIZATION
-----------------------------------------------------
--require("SKC4.DriverCore")
myLog = require("SKC4.Logger")
LOGGER =  myLog:new()

function ON_DRIVER_INIT.init_variables()
  LOGGER:debug("ON_DRIVER_INIT.init_variables()")
end

function ON_DRIVER_INIT.init_licence_mgr()
  LOGGER:debug("ON_DRIVER_INIT.init_licence_mgr()")
  LICENSE_MGR:OnDriverInit()
end

function ON_DRIVER_LATEINIT.init_timer_for_polling()
  LOGGER:debug("ON_DRIVER_LATEINIT.init_timer_for_polling()")
  updateTimerForControl(TIMER_INTERVAL_FOR_CONTROL)
  --updateTimerForPolling(TIMER_FOR_POLLING)
end

function ON_DRIVER_LATEINIT.init_licence_mgr()
  LOGGER:debug("ON_DRIVER_LATEINIT.init_licence_mgr()")
  LICENSE_MGR:OnDriverLateInit()
end

function ON_DRIVER_DESTROYED.destroyed_timer_for_polling()
  LOGGER:debug("ON_DRIVER_DESTROY.destroy_timer_for_polling()")
  --destroyTimerForPolling()
end

-----------------------------------------------------
-- VARIABLES
-----------------------------------------------------

-----------------------------------------------------
-- PROPERTIES
-----------------------------------------------------
for i = 1, INPUT_NUMBER do
  ON_PROPERTY_CHANGED[PROPERTY_RELAY_MAP[i]] = function(sValue)
    LOGGER:debug("ON_PROPERTY_CHANGED.", PROPERTY_RELAY_MAP[i], " = ", sValue)
    local string_table = Utility.split(sValue, ",")
    if tonumber(string_table[1]) ~= nil then
      RELAY_MAP[i] = {}
      for j, a in ipairs(string_table) do
        table.insert(RELAY_MAP[i], a)
      end
    end
    C4:PersistSetValue("RELAY_MAP", RELAY_MAP)
    SET_OUTPUT_MAP()
    LOGGER:debug("RELAY_MAP[" .. i .. "] ", RELAY_MAP[i])
  end
end

--function ReceivedFromProxy(idBinding, sCommand, tParams)
--end

-----------------------------------------------------
-- PROXY COMMANDS
-----------------------------------------------------

function ReceivedFromProxy(idBinding, sCommand, tParams)
  LOGGER:debug("ReceivedFromProxy: ", idBinding, sCommand, tParams)
  if (sCommand ~= nil) then
    if (tParams == nil) then -- initial table variable if nil
      tParams = {}
    end

    if (PRX_CMD[sCommand]) ~= nil then
      PRX_CMD[sCommand](idBinding, tParams)
    else
      LOGGER:debug("ReceivedFromProxy: Unhandled command = " .. sCommand)
    end
  end
  LICENSE_MGR:ReceivedFromProxy(idBinding, sCommand, tParams)
end

-----------------------------------------------------
-- COMMANDS
-----------------------------------------------------

-----------------------------------------------------
-- COMMANDS Relays
-----------------------------------------------------
-- apertura relay
function PRX_CMD.OPEN(idBinding, tParams)
  if LICENSE_MGR:isAbleToWork() then
    LOGGER:debug("or-matrix opening input:", idBinding)
    RELAY_IN_STATUS[idBinding] = 0
    --set_outputs()
  else
    LOGGER:debug("License Not Active or in trial period")
  end
end
function PRX_CMD.CLOSE(idBinding, tParams)
  if LICENSE_MGR:isAbleToWork() then
    LOGGER:debug("or-matrix closing input:", idBinding)
    RELAY_IN_STATUS[idBinding] = 1
    --set_outputs()
  else
    LOGGER:debug("License Not Active or in trial period")
  end
end
function PRX_CMD.OPENED(idBinding, tParams)
end
function PRX_CMD.CLOSED(idBinding, tParams) 
end
function PRX_CMD.STATE_OPENED(idBinding, tParams)
end
function PRX_CMD.STATE_CLOSED(idBinding, tParams) 
end

-- toggle
function PRX_CMD.TOGGLE(idBinding, tParams)
  if LICENSE_MGR:isAbleToWork() then
    LOGGER:debug("or-matrix closing input:", idBinding)
    RELAY_IN_STATUS[idBinding] = -(RELAY_IN_STATUS[idBinding]) + 1
    --set_outputs()
  else
    LOGGER:debug("License Not Active or in trial period")
  end
end

function SET_OUTPUT_RELAY(output_number, STATE, force)
  local IdBinding = IDBINDING_CONNECTION_OUTPUT[tonumber(output_number)]
  local state_str = ""
  if STATE == 1 then
    state_str = "CLOSE"
  end
  if STATE == 0 then
    state_str = "OPEN"
  end

  msg = string.format("SETTING RELAY#:%-3s - ON IDBIND:%-3s TO STATE: %-3s,", output_number, IdBinding, state_str)

  LOGGER:debug(msg)
  C4:SendToProxy(IdBinding, state_str, "NOTIFY")
end
-----------------------------------------------------
-- TIMER
-----------------------------------------------------
function updateTimerForControl(new_interval)
  if (TIMER_FOR_CONTROL == nil) then
    LOGGER:trace("updateTimerForControl NEW")
    TIMER_FOR_CONTROL =
      TimerManager:new(
      TIMER_INTERVAL_FOR_CONTROL,
      TIMER_INTERVAL_SCALE_FOR_CONTROL,
      onTimerExpireForControl,
      true
    )
  else
    LOGGER:trace("updateTimerForControl UPDATE")
    TIMER_FOR_CONTROL:stop()
    TIMER_FOR_CONTROL =
      TimerManager:new(
      TIMER_INTERVAL_FOR_CONTROL,
      TIMER_INTERVAL_SCALE_FOR_CONTROL,
      onTimerExpireForControl,
      true
    )
  end
  LOGGER:trace("updateTimerForControl START")
  TIMER_FOR_CONTROL:start()
  LOGGER:trace("TIMER_FOR_CONTROL:", TIMER_FOR_CONTROL)
end
function onTimerExpireForControl()
  LOGGER:trace("onTimerExpireForControl()")
  print ("onTimerExpireForControl()")
  updateTimerForControl(TIMER_INTERVAL_FOR_CONTROL)
  set_outputs()
end
-----------------------------------------------------
-- ACTIONS
-----------------------------------------------------

function ACTIONS.PrintMatrix()
  print("printing")
  --print input state
  local input = ""
  for i, s in pairs(RELAY_IN_STATUS) do
    input = input .. string.format("input #:%-3s - state: %-3s         ,\n", i, s)
  end
  print(input)
  --print mapping
  local _OUTPUT_MAP = C4:PersistGetValue("OUTPUT_MAP")
  local output_map_string = ""
  for o, input_number in pairs(_OUTPUT_MAP) do
    local inputs = ""
    for i, n in pairs(input_number) do
      inputs = inputs .. ", " .. n
    end
    output_map_string = output_map_string .. string.format("output#:%-3s - depends on inputs: %-3s         ,\n", o, inputs)
  end
  print(output_map_string)
  --print output state
  --local states =  OUTPUT_STATE[output_index] = output_val()
  local output_states = ""
  for o, input_map in pairs(_OUTPUT_MAP) do
    output_states = output_states .. string.format("output#:%-3s - state: %-3s         ,\n", o, OUTPUT_STATE[tonumber(o)])
  end
  print(input .. "\n" .. output_map_string .. "\n" .. output_states)
end

function ACTIONS.ReSetOutputs()
  set_outputs(true)
end
-----------------------------------------------------
-- COMMON
-----------------------------------------------------
function translate_matrix(input_matrix)
  output = {}
  for i, v in pairs(input_matrix) do
    if type(v) == "string" then
      break
    end
    for j, k in pairs(v) do
      if (output[k] == nil) then
        output[k] = {}
      end
      output[k][i] = i
    end
  end
  return output
end

function SET_OUTPUT_MAP()
  local _relay_map = C4:PersistGetValue("RELAY_MAP")
  local _OUTPUT_MAP = translate_matrix(_relay_map)
  C4:PersistSetValue("OUTPUT_MAP", _OUTPUT_MAP)
end
OUTPUT_CONNECTION = {}
--

--[[function RegenerateConnections()
  for i in pairs(OUTPUT_CONNECTION) do
    print("------------------------------------------------------------eliminare le vecchio connection")
  end

  local unique_output = translate_matrix(RELAY_MAP)
  for j in pairs(unique_output) do
    C4:AddDynamicBinding(j, "CONTROL", true, "Or Mixer Output Connection " .. j, "RELAY", false, true)
    table.insert(OUTPUT_CONNECTION, j)
  end
end]]
function logical_or(input_one, input_two)
  --print (input_one, type(input_one), input_two, type(input_two))
  local output
  local input_one_bool = false
  input_one = (1 and input_one) or 0
  if input_one > 0 then
    input_one_bool = true
  end
  local input_two_bool = false
  input_two = (1 and input_two) or 0
  if input_two > 0 then
    input_two_bool = true
  end
  local o = input_two_bool or input_one_bool
  return o and 1 or 0
end

function set_output_state(output_num)
  local out_state = 0
  local _OUTPUT_MAP = C4:PersistGetValue("OUTPUT_MAP")
  local input_controller = _OUTPUT_MAP[output_num]
  for index, control in pairs(input_controller) do
    --print ("set_output_state", index, control, out_state, RELAY_IN_STATUS[control])
    out_state = logical_or(out_state, RELAY_IN_STATUS[control])
    --print ("set_output_state, output_number"..output_num..", control input#"..control..", output_calc"..out_state..", last input computed " ..RELAY_IN_STATUS[control])
  end
  --print ("set_output_state of output", output_num, " STATUS", out_state)
  return out_state
end

OUTPUT_STATE = {}
function set_outputs(force)
  local output_states = {}
  local _OUTPUT_MAP = C4:PersistGetValue("OUTPUT_MAP")

  for output_index, input_map in pairs(_OUTPUT_MAP) do
    local state = set_output_state(output_index)
    --print("set_outputs, output_index", output_index, " state", state)
    output_states[output_index] = state
  end
  for output_index, output_val in pairs(output_states) do
    LOGGER:debug("set output:" .. output_index .. " to value:" .. output_val)
    SET_OUTPUT_RELAY(output_index, output_val, force)
    OUTPUT_STATE[output_index] = output_val
  end
end
LICENSE_MGR.isAbleToWork = function()
  return true
end
-----------------------------------------------------
-- TEST
-----------------------------------------------------
