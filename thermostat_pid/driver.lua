require "SKC4.LicenseManager"
require "SKC4.Utility"
require "SKC4.DriverCore"
local DriverLogger = require "SKC4.Logger"
LOGGER = DriverLogger:new()
local TimerManager = require "SKC4.TimerManager"
local ApiRestManager = require "SKC4.ApiRestManager"

-----------------------------------------------------
-- GLOBALS
-----------------------------------------------------
DRIVER_NAME = "thermostat_pid"

--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", DRIVER_NAME .. ".c4z", "DRIVERCENTRAL")
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")
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


TIMER_FOR_COMPUTING = nil
TIMER_INTERVAL_FOR_COMPUTING = 12
TIMER_INTERVAL_SCALE_FOR_COMPUTING = "SECONDS"
TIMER_FOR_INFLUXDB = nil
TIMER_INTERVAL_FOR_INFLUXDB = 10
TIMER_INTERVAL_SCALE_FOR_INFLUXDB = "SECONDS"
-- PROPERTIES NAME
PROPERTY_COMPUTING_INTERVAL = "Computing Interval"
PROPERTY_HEATING_KI = "Heating Ki"
PROPERTY_HEATING_KP = "Heating Kp"
PROPERTY_HEATING_KD = "Heating Kd"
PROPERTY_HEATING_OFF_THRESHOLD = "Heating Off Threshold"
PROPERTY_HEATING_MIN = "Heating Min"
PROPERTY_HEATING_MAX = "Heating Max"
PROPERTY_COOLING_KI = "Cooling Ki"
PROPERTY_COOLING_KP = "Cooling Kp"
PROPERTY_COOLING_KD = "Cooling Kd"
PROPERTY_COOLING_OFF_THRESHOLD = "Cooling Off Threshold"
PROPERTY_COOLING_MIN = "Cooling Min"
PROPERTY_COOLING_MAX = "Cooling Max"
PROPERTY_DEVICE_NAME = "Thermostat Device Name"

PROPERTY_INPUT_TEMPERATURES = "INPUT TEMPERATURES"
PROPERTY_INPUT_RELAYS = "INPUT RELAYS"
PROPERTY_OUTPUT_COMPUTED_RELAYS = "OUTPUT COMPUTED RELAYS"
PROPERTY_OUTPUT_FAN = "OUTPUT FAN"
PROPERTY_LAST_COMPUTED_PID = "LAST COMPUTED PID"
PROPERTY_WATER_TEMPERATURE = "WATER TEMPERATURE"

PROPERTY_WATER_SUPLY_CONTROL = "Water Supply Control"
PROPERTY_HEATING_WATER_THRESHOLD = "Heating Water Threshold"
PROPERTY_COOLING_WATER_THRESHOLD = "Cooling Water Threshold"

VARIABLE_INPUT_TEMPERATURES = "INPUT TEMPERATURES"
VARIABLE_INPUT_RELAYS = "INPUT RELAYS"
VARIABLE_OUTPUT_COMPUTED_RELAYS = "OUTPUT COMPUTED RELAYS"
VARIABLE_OUTPUT_FAN_STR = "OUTPUT FAN"
VARIABLE_OUTPUT_FAN_NUM = "OUTPUT FAN NUMBERS"
VARIABLE_LAST_COMPUTED_PID = "LAST COMPUTED PID"

pid = require("pid")
HEAT_PID = pid:new() --pid object to heating season
HEAT_PID:set_condition_on("WINTER")
COOL_PID = pid:new() --pid object to cooling season
COOL_PID:set_condition_on("SUMMER")

HEAT_PID.input = 0 -- setted to 0 to compute on something...
if C4:PersistGetValue("_HEAT_SETPOINT") == nil then
  HEAT_PID.target = 0 -- setted to 0 to compute on something...
else
  HEAT_PID.target = C4:PersistGetValue("_HEAT_SETPOINT")
end
if C4:PersistGetValue("_COOL_SETPOINT") == nil then
  COOL_PID.target = 0 -- setted to 0 to compute on something...
else
  COOL_PID.target = C4:PersistGetValue("_COOL_SETPOINT")
end
if C4:PersistGetValue("HVAC_MODE") == nil then
  HVAC_MODE = "HEAT"
else
  HVAC_MODE = C4:PersistGetValue("HVAC_MODE")
end
HEAT_PID.target = 0 -- setted to 0 to compute on something...
HEAT_PID.output = 0 -- setted to 0 to compute on something...
HEAT_PID.target_condition_on = "GT" -- setted to 0 to compute on something...
COOL_PID.input = 0 -- setted to 0 to compute on something...
COOL_PID.target = 0 -- setted to 0 to compute on something...
COOL_PID.output = 0 -- setted to 0 to compute on something...
COOL_PID.target_condition_on = "LT" -- setted to 0 to compute on something...

-- CURRENT_PID = HEAT_PID --linked pid object in use
COOL_PID.threshold_off = 10 --threshold under which the heating relay goes off
HEAT_PID.threshold_off = 10 --threshold under which the cooling relay goes off
-- CURRENT_OFF_THRESHOLD

WATER_SUPLY_CONTROL = "OFF"
HEATING_WATER_THRESHOLD = 0
COOLING_WATER_THRESHOLD = 99
WATER_TEMPERATURE = 0

NAME_INFLUX_URL = "https://us-east-1-1.aws.cloud2.influxdata.com"
NAME_INFLUX_ORG = "giac.leonzi@gmail.com"
NAME_INFLUX_BUCKET = "thermostatpid"
--NAME_INFLUX_BUCKET = "giac.leonzi's Bucket" --"d98c51564863693d"
NAME_INFLUX_TOKEN = "mcC6-3RA3ExENgc4enyzyGPq_wbxomQFBpzqEf1xUH2T6n6N0wmsvJ03qj1Ozmod0HjYQZZ7ij8tUfT11Fc42w==" --thermostatpid
--NAME_INFLUX_TOKEN = "E8NDJ78Oyd806_UdRiE0JEKHAOJJs3rs-s14-ui_sSUOv2Ig5IAufio5KRamLzOLrtaq20pbTIJamg9UxE8wPA==" --giac.leonzi's Bucket
INFLUX_ENDPOINT = "/api/v2/write"

PROXY_COMMANDS = {}
TMP_STORED_SETTING = {}

-----------------------------------------------------
-- AUTO INITIALIZATION
-----------------------------------------------------
VERSION = 101
--function setup_variables_and_connection()
function setup_connections()
  -- HEATING_INPUT = "Heating Input"
  -- COOLING_INPUT = "Cooling Input"
  -- FAN_INPUT = "Fan Input"
  -- TEMPERATURE_INPUT = "Temperature Input"
  -- HEAT_SETPOINT_INPUT = "Heating Setpoint Input"
  -- COOL_SETPOINT_INPUT = "Cooling Setpoint Input"
  -- SETPOINT_INPUT = "Setpoint Input"
  -- OUTDOOR_TEMPERATURE_INPUT = "Outdoor Temperature Input"
  -- HUMIDITY_INPUT = "Humidity Input"
  -- THRESHOLD_CONDITION_ON_NAME = "Theshold Condition On"
  -- HEATING_STRAIGHT_OUTPUT = "Heating Direct Output"
  -- COOLING_STRAIGHT_OUTPUT = "Cooling Direct Output"
  -- FAN_STRAIGHT_OUTPUT = "Fan Direct Output"
  -- HEATING_PID_OUTPUT = "Heating PID Output"
  -- COOLING_PID_OUTPUT = "Cooling PID Output"
  -- FAN_PID_OUTPUT = "Fan PID Output"
  -- HVAC_MODE_INPUT = "HVAC Mode"
  -- tVariables = {}
  -- tVariables[1] = TEMPERATURE_1_STR
  -- C4:DeleteVariable(TEMPERATURE_1_STR)
  -- C4:AddVariable(TEMPERATURE_1_STR, "0", "NUMBER",true)

  HEATING_INPUT_BIND = 1001
  COOLING_INPUT_BIND = 1002
  FAN_INPUT_BIND = 1003
  TEMPERATURE_INPUT_BIND = 2 --1004
  HEAT_SETPOINT_INPUT_BIND = 1005
  COOL_SETPOINT_INPUT_BIND = 1006
  OUTDOOR_TEMPERATURE_INPUT_BIND = 4 --1007
  HUMIDITY_INPUT_BIND = 1008
  THRESHOLD_CONDITION_ON_BIND = 1009
  HEATING_STRAIGHT_OUTPUT_BIND = 1010
  COOLING_STRAIGHT_OUTPUT_BIND = 1011
  FAN_STRAIGHT_OUTPUT_BIND = 1012
  HEATING_PID_OUTPUT_BIND = 1013
  COOLING_PID_OUTPUT_BIND = 1014
  FAN_PID_OUTPUT_BIND = 1015
  HVAC_MODE_INPUT_BIND = 916
  TEMPERATURE_WATER_INPUT_BIND = 3 --1017

  tBind = {}

  tBind[1] = HEATING_INPUT_BIND
  tBind[2] = COOLING_INPUT_BIND
  tBind[3] = FAN_INPUT_BIND
  tBind[4] = TEMPERATURE_INPUT_BIND
  tBind[5] = HEAT_SETPOINT_INPUT_BIND
  tBind[6] = COOL_SETPOINT_INPUT_BIND
  tBind[7] = OUTDOOR_TEMPERATURE_INPUT_BIND
  tBind[8] = HUMIDITY_INPUT_BIND
  tBind[9] = THRESHOLD_CONDITION_ON_BIND
  tBind[10] = HEATING_STRAIGHT_OUTPUT_BIND
  tBind[11] = COOLING_STRAIGHT_OUTPUT_BIND
  tBind[12] = FAN_STRAIGHT_OUTPUT_BIND
  tBind[13] = HEATING_PID_OUTPUT_BIND
  tBind[14] = COOLING_PID_OUTPUT_BIND
  tBind[15] = FAN_PID_OUTPUT_BIND
  tBind[16] = HVAC_MODE_INPUT_BIND

  -- C4:AddDynamicBinding(HEATING_INPUT_BIND, "CONTROL", true, HEATING_INPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(COOLING_INPUT_BIND, "CONTROL", true, COOLING_INPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(FAN_INPUT_BIND, "CONTROL", true, FAN_INPUT, "RELAY", false, false)
  --C4:AddDynamicBinding(TEMPERATURE_INPUT_BIND, "CONTROL", false, TEMPERATURE_INPUT, "TEMPERATURE_VALUE", false, false)
  -- C4:AddDynamicBinding(HEAT_SETPOINT_INPUT_BIND, "CONTROL", true, HEAT_SETPOINT_INPUT, "SETPOINT", false, false)
  -- C4:AddDynamicBinding(COOL_SETPOINT_INPUT_BIND, "CONTROL", true, COOL_SETPOINT_INPUT, "SETPOINT", false, false)
  -- C4:AddDynamicBinding(
  --   OUTDOOR_TEMPERATURE_INPUT_BIND,
  --   "CONTROL",
  --   true,
  --   OUTDOOR_TEMPERATURE_INPUT,
  --   "TEMPERATURE_VALUE",
  --   false,
  --   false
  -- )
  -- C4:AddDynamicBinding(HUMIDITY_INPUT_BIND, "CONTROL", true, HUMIDITY_INPUT, "HUMIDITY_VALUE", false, false)
  -- C4:AddDynamicBinding(THRESHOLD_CONDITION_ON_BIND, "CONTROL", true, THRESHOLD_CONDITION_ON_NAME, "RELAY", false, false)

  -- C4:AddDynamicBinding(HEATING_STRAIGHT_OUTPUT_BIND, "CONTROL", false, HEATING_STRAIGHT_OUTPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(COOLING_STRAIGHT_OUTPUT_BIND, "CONTROL", false, COOLING_STRAIGHT_OUTPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(FAN_STRAIGHT_OUTPUT_BIND, "CONTROL", false, FAN_STRAIGHT_OUTPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(HEATING_PID_OUTPUT_BIND, "CONTROL", false, HEATING_PID_OUTPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(COOLING_PID_OUTPUT_BIND, "CONTROL", false, COOLING_PID_OUTPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(FAN_PID_OUTPUT_BIND, "CONTROL", false, FAN_PID_OUTPUT, "RELAY", false, false)
  -- C4:AddDynamicBinding(HVAC_MODE_INPUT_BIND, "CONTROL", true, HVAC_MODE_INPUT, "STRING_VARIABLE", false, false)
end

function setup_variables()
  AddVariable(VARIABLE_INPUT_TEMPERATURES, "", "STRING", false, false)
  AddVariable(VARIABLE_INPUT_RELAYS, "", "STRING", false, false)
  AddVariable(VARIABLE_OUTPUT_COMPUTED_RELAYS, "", "STRING", false, false)
  AddVariable(VARIABLE_OUTPUT_FAN_STR, "", "STRING", false, false)
  AddVariable(VARIABLE_OUTPUT_FAN_NUM, "", "NUMBER", false, false)
  AddVariable(VARIABLE_LAST_COMPUTED_PID, "", "STRING", false, false)
end

function ON_DRIVER_LATE_INIT.init_connections()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_connections()")
  LOGGER:trace(CURRENT_PID)
  LOGGER:trace(".....")

  local _PID = C4:PersistGetValue("PID")
  -- local _HEAT_SETPOINT = C4:PersistGetValue("_HEAT_SETPOINT")
  -- local _COOL_SETPOINT = C4:PersistGetValue("_COOL_SETPOINT")
  HEAT_PID.target = C4:PersistGetValue("_HEAT_SETPOINT")
  COOL_PID.target = C4:PersistGetValue("_COOL_SETPOINT")
  print("HEAT_PID.target", HEAT_PID.target)
  print("COOL_PID.target", COOL_PID.target)
  if _PID == nil then
    CURRENT_PID = HEAT_PID
    CURRENT_PID.target = 0
    CURRENT_PID.input = 0
  else
    if _PID.target_condition_on == "GT" then
      --CURRENT_PID.target = _HEAT_SETPOINT
      CURRENT_PID = HEAT_PID
      HVAC_MODE = "HEAT"
    else
      -- CURRENT_PID.target = _COOL_SETPOINT
      CURRENT_PID = COOL_PID
      HVAC_MODE = "COOL"
    end
    if C4:PersistGetValue("HVAC_MODE") == nil then
      HVAC_MODE = "HEAT"
    else
      HVAC_MODE = C4:PersistGetValue("HVAC_MODE")
    end
    --CURRENT_PID.kp = _PID.input
    --CURRENT_PID.ki = _PID.maxout
    --CURRENT_PID.kd = _PID.minout
    CURRENT_PID.target = _PID.target
    --CURRENT_PID.minout = _PID._Iterm
    --CURRENT_PID.maxout = _PID._lastinput
    CURRENT_PID.threshold_off = _PID.threshold_off
    CURRENT_PID.output = _PID.output
    CURRENT_PID.input = _PID.input
    CURRENT_PID.target_condition_on = _PID.target_condition_on
  end

  C4:PersistSetValue("PID", CURRENT_PID:save())
  LOGGER:trace(CURRENT_PID)
  setup_connections()
  setup_variables()
  trigger_on_properties_change()
end

function ON_DRIVER_LATEINIT.init_timer_for_computing()
  LOGGER:debug("ON_DRIVER_LATEINIT.init_timer_for_computing()")
  updateTimerForComputing(TIMER_FOR_COMPUTING)
  updateTimerForInfluxDB(TIMER_FOR_INFLUXDB)
end

function ON_DRIVER_LATE_INIT.set_ui_capabilities()
end

function ON_DRIVER_LATE_INIT.sync_device_state()
end

function ON_DRIVER_INIT.create_api_manager()
  API_MANAGER = ApiRestManager:new()
end

function ON_DRIVER_LATE_INIT.init_variables()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_variables()")
  -- AddVariable(VARIABLE_NAME_LABEL, 0, "NUMBER", false, false)
end

function ON_DRIVER_LATE_INIT.init_api_manager()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_api_manager()")
  API_MANAGER:set_base_url(NAME_INFLUX_URL)
  API_MANAGER:set_max_concurrent_requests(5)
  API_MANAGER:disable_delayed_requests()
  API_MANAGER:enable_ssl_verify_host()
  API_MANAGER:enable_ssl_verify_peer()
  API_MANAGER:disable_fail_on_error()
end
-----------------------------------------------------
-- VARIABLES
-----------------------------------------------------

-----------------------------------------------------
-- PROPERTIES
-----------------------------------------------------
--function trigger_on_properties_change()
--  for k in pairs(Properties) do
--    pcall(ON_PROPERTY_CHANGED[k])
--  end
--end

ON_PROPERTY_CHANGED[PROPERTY_COMPUTING_INTERVAL] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.Computing_Interval: sValue = ", sValue)
  local value = tonumber(sValue)
  if value == nil then
    TIMER_INTERVAL_FOR_COMPUTING = 12
  else
    TIMER_INTERVAL_FOR_COMPUTING = value
  end
  LOGGER:trace("ON_PROPERTY_CHANGED.Computing_Interval: TIMER_FOR_COMPUTING = ", TIMER_FOR_COMPUTING)
  updateTimerForComputing(TIMER_INTERVAL_FOR_COMPUTING)
end

ON_PROPERTY_CHANGED[PROPERTY_HEATING_KI] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_HEATING_KI = ", sValue)
  if tonumber(sValue) then
    HEAT_PID.ki = tonumber(sValue)
  else
    HEAT_PID.ki = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_HEATING_KP] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_HEATING_KP = ", sValue)
  if tonumber(sValue) then
    HEAT_PID.kp = tonumber(sValue)
  else
    HEAT_PID.kp = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_HEATING_KD] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_HEATING_KD = ", sValue)
  if tonumber(sValue) then
    HEAT_PID.kd = tonumber(sValue)
  else
    HEAT_PID.kd = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_HEATING_OFF_THRESHOLD] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_HEATING_OFF_THRESHOLD = ", sValue)
  if tonumber(sValue) then
    HEAT_PID.threshold_off = tonumber(sValue)
  else
    HEAT_PID.threshold_off = 10
  end
end
ON_PROPERTY_CHANGED[PROPERTY_HEATING_MIN] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_HEATING_MIN = ", sValue)
  if tonumber(sValue) then
    HEAT_PID.minout = tonumber(sValue)
  else
    HEAT_PID.minout = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_HEATING_MAX] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_HEATING_MAX = ", sValue)
  if tonumber(sValue) then
    HEAT_PID.maxout = tonumber(sValue)
  else
    HEAT_PID.maxout = 50
  end
end
ON_PROPERTY_CHANGED[PROPERTY_COOLING_KI] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_COOLING_KI = ", sValue, tonumber(sValue))
  if tonumber(sValue) then
    COOL_PID.ki = tonumber(sValue)
  else
    COOL_PID.ki = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_COOLING_KP] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_COOLING_KP = ", sValue)
  if tonumber(sValue) then
    COOL_PID.kp = tonumber(sValue)
  else
    COOL_PID.kp = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_COOLING_KD] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_COOLING_KD = ", sValue)
  if tonumber(sValue) then
    COOL_PID.kd = tonumber(sValue)
  else
    COOL_PID.kd = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_COOLING_OFF_THRESHOLD] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_COOLING_OFF_THRESHOLD = ", sValue)
  if tonumber(sValue) then
    COOL_PID.threshold_off = tonumber(sValue)
  else
    COOL_PID.threshold_off = 10
  end
end
ON_PROPERTY_CHANGED[PROPERTY_COOLING_MIN] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_COOLING_MIN = ", sValue)
  if tonumber(sValue) then
    COOL_PID.minout = tonumber(sValue)
  else
    COOL_PID.minout = 0
  end
end
ON_PROPERTY_CHANGED[PROPERTY_COOLING_MAX] = function(sValue)
  LOGGER:trace("ON_PROPERTY_CHANGED.PROPERTY_COOLING_MAX = ", sValue)
  if tonumber(sValue) then
    COOL_PID.maxout = tonumber(sValue)
  else
    COOL_PID.maxout = 50
  end
end

ON_PROPERTY_CHANGED[PROPERTY_WATER_SUPLY_CONTROL] = function(sValue)
  WATER_SUPLY_CONTROL = sValue
end
ON_PROPERTY_CHANGED[PROPERTY_HEATING_WATER_THRESHOLD] = function(sValue)
  if tonumber(sValue) then
    HEATING_WATER_THRESHOLD = tonumber(sValue)
  end
end
ON_PROPERTY_CHANGED[PROPERTY_COOLING_WATER_THRESHOLD] = function(sValue)
  if tonumber(sValue) then
    COOLING_WATER_THRESHOLD = tonumber(sValue)
  end
end

set_property = {}
set_property[PROPERTY_INPUT_TEMPERATURES] = function()
  propertyValue =
    "Actual: [°C] " .. tostring(CURRENT_PID.input) .. " - Set point: [°C] " .. tostring(CURRENT_PID.target)
  UpdateProperty(PROPERTY_INPUT_TEMPERATURES, propertyValue)
  SetVariable(VARIABLE_INPUT_TEMPERATURES, propertyValue)
end

set_property[PROPERTY_INPUT_RELAYS] = function()
  local h = ""
  if TMP_STORED_SETTING["HEATING_INPUT_BIND"] == 0 then
    h = "OPEN"
  else
    h = "CLOSE"
  end
  local c = ""
  if TMP_STORED_SETTING["COOLING_INPUT_BIND"] == 0 then
    c = "OPEN"
  else
    c = "CLOSE"
  end
  local f = ""
  if TMP_STORED_SETTING["FAN_INPUT_BIND"] == 0 then
    f = "OPEN"
  else
    f = "CLOSE"
  end
  propertyValue = "Heat: " .. h .. " , Cool: " .. c .. " , Fan: " .. f
  UpdateProperty(PROPERTY_INPUT_RELAYS, propertyValue)
  SetVariable(VARIABLE_INPUT_RELAYS, propertyValue)
end

set_property[PROPERTY_OUTPUT_COMPUTED_RELAYS] = function()
  local h = ""
  if TMP_STORED_SETTING["HEATING_PID_OUTPUT_BIND"] == 0 then
    h = "OPEN"
  else
    h = "CLOSE"
  end
  local c = ""
  if TMP_STORED_SETTING["COOLING_PID_OUTPUT_BIND"] == 0 then
    c = "OPEN"
  else
    c = "CLOSE"
  end
  local f = ""
  if TMP_STORED_SETTING["FAN_PID_OUTPUT_BIND"] == 0 then
    f = "OPEN"
  else
    f = "CLOSE"
  end
  propertyValue = "Heat: " .. h .. " , Cool: " .. c .. " , Fan: " .. f
  UpdateProperty(PROPERTY_OUTPUT_COMPUTED_RELAYS, propertyValue)
  SetVariable(VARIABLE_OUTPUT_COMPUTED_RELAYS, propertyValue)
end

set_property[PROPERTY_OUTPUT_FAN] = function()
  propertyValue = "Fan speed is set to: " .. CURRENT_PID.output
  UpdateProperty(PROPERTY_OUTPUT_FAN, propertyValue)
  --SetVariable(VARIABLE_OUTPUT_FAN_STR, tostring(CURRENT_PID.output))
  --SetVariable(VARIABLE_OUTPUT_FAN_NUM, CURRENT_PID.output)
end

set_property[PROPERTY_LAST_COMPUTED_PID] = function()
  local condition = ""
  if HVAC_MODE == "OFF" then
    condition = "OFF"
  elseif HVAC_MODE == "COOL" then
    condition = "COOL"
  elseif HVAC_MODE == "HEAT" then
    condition = "HEAT"
  end
  propertyValue = condition
  UpdateProperty(PROPERTY_LAST_COMPUTED_PID, propertyValue)
  SetVariable(VARIABLE_LAST_COMPUTED_PID, propertyValue)
end
set_property[PROPERTY_WATER_TEMPERATURE] = function()
  propertyValue = "Water temperature is: " .. WATER_TEMPERATURE
  UpdateProperty(PROPERTY_WATER_TEMPERATURE, propertyValue)
end

-----------------------------------------------------
-- COMMANDS
-----------------------------------------------------

-----------------------------------------------------
-- COMMANDS Relays
-----------------------------------------------------
-- apertura relay
function PROXY_COMMANDS.OPEN(tParams, idBinding)
  if (idBinding == HEATING_INPUT_BIND) then
    C4:SendToProxy(HEATING_STRAIGHT_OUTPUT_BIND, "OPEN", "NOTIFY")
    TMP_STORED_SETTING["HEATING_INPUT_BIND"] = 0
    TMP_STORED_SETTING["HEATING_STRAIGHT_OUTPUT_BIND"] = 0
  end
  if (idBinding == COOLING_INPUT_BIND) then
    C4:SendToProxy(COOLING_STRAIGHT_OUTPUT_BIND, "OPEN", "NOTIFY")
    TMP_STORED_SETTING["COOLING_INPUT_BIND"] = 0
    TMP_STORED_SETTING["COOLING_STRAIGHT_OUTPUT_BIND"] = 0
  end
  if (idBinding == FAN_INPUT_BIND) then
    C4:SendToProxy(FAN_STRAIGHT_OUTPUT_BIND, "OPEN", "NOTIFY")
    TMP_STORED_SETTING["FAN_INPUT_BIND"] = 0
    TMP_STORED_SETTING["FAN_STRAIGHT_OUTPUT_BIND"] = 0
  end

  if (idBinding == THRESHOLD_CONDITION_ON_BIND) then
    switch_HVAC_mode("OPEN")
  end
end
-- chiusura relay
function PROXY_COMMANDS.CLOSE(tParams, idBinding)
  if (idBinding == HEATING_INPUT_BIND) then
    C4:SendToProxy(HEATING_STRAIGHT_OUTPUT_BIND, "CLOSE", "NOTIFY")
    TMP_STORED_SETTING["HEATING_STRAIGHT_OUTPUT_BIND"] = 1
  end
  if (idBinding == COOLING_INPUT_BIND) then
    C4:SendToProxy(COOLING_STRAIGHT_OUTPUT_BIND, "CLOSE", "NOTIFY")
    TMP_STORED_SETTING["COOLING_STRAIGHT_OUTPUT_BIND"] = 1
  end
  if (idBinding == FAN_INPUT_BIND) then
    C4:SendToProxy(FAN_STRAIGHT_OUTPUT_BIND, "CLOSE", "NOTIFY")
    TMP_STORED_SETTING["FAN_INPUT_BIND"] = 1
    TMP_STORED_SETTING["FAN_STRAIGHT_OUTPUT_BIND"] = 1
  end
  if (idBinding == THRESHOLD_CONDITION_ON_BIND) then
    switch_HVAC_mode("CLOSE")
  end
end

function PROXY_COMMANDS.SET_VALUE(tParams, idBinding)
  if (tParams == nil) then -- initial table variable if nil
    tParams = {}
  end
  if (idBinding == TEMPERATURE_INPUT_BIND) then
    set_input(tParams)
  end
  if (idBinding == HVAC_MODE_INPUT_BIND) then
    local paramUpper = string.upper(tParams["VALUE"])
    switch_HVAC_mode(paramUpper)
  end
end

function PROXY_COMMANDS.VALUE_CHANGED(tParams, idBinding)
  if (tParams == nil) then -- initial table variable if nil
    tParams = {}
  end
  if (idBinding == TEMPERATURE_INPUT_BIND) then
    set_input(tParams)
  end
  if (idBinding == HVAC_MODE_INPUT_BIND) then
    local paramUpper = string.upper(tParams)
    switch_HVAC_mode(paramUpper)
  end
  if (idBinding == TEMPERATURE_WATER_INPUT_BIND) then
    input = Utility.tonumber_loc(tParams["CELSIUS"])
    WATER_TEMPERATURE = input
  end
end

function PROXY_COMMANDS.TEMPERATURE_CHANGED(tParams, idBinding)
  if (tParams == nil) then -- initial table variable if nil
    tParams = {}
  end

  if (idBinding == COOL_SETPOINT_INPUT_BIND) then
    set_target(tParams, COOL_SETPOINT_INPUT_BIND)
  end
  if (idBinding == HEAT_SETPOINT_INPUT_BIND) then
    set_target(tParams, HEAT_SETPOINT_INPUT_BIND)
  end
end

-----------------------------------------------------
-- ACTIONS
-----------------------------------------------------
ACTIONS = {}
function ACTIONS.PrintVariables()
end

function ACTIONS.PrintPID()
  print("PID STATUS: ", Utility.tstring(CURRENT_PID))
end

function ACTIONS.setPidToCool()
  LOGGER:trace("ACTIONS.setPidToCool")
  switch_HVAC_mode("COOL")
end

function ACTIONS.setPidToHeat()
  LOGGER:trace("ACTIONS.setPidToHeat")
  switch_HVAC_mode("HEAT")
end

-----------------------------------------------------
-- TIMER
-----------------------------------------------------
function updateTimerForComputing(new_interval)
  if (TIMER_FOR_COMPUTING == nil) then
    LOGGER:trace("updateTimerForComputing NEW")
    TIMER_FOR_COMPUTING =
      TimerManager:new(
      TIMER_INTERVAL_FOR_COMPUTING,
      TIMER_INTERVAL_SCALE_FOR_COMPUTING,
      onTimerExpireForComputing,
      true
    )
  else
    LOGGER:trace("updateTimerForComputing UPDATE")
    TIMER_FOR_COMPUTING:stop()
    TIMER_FOR_COMPUTING =
      TimerManager:new(
      TIMER_INTERVAL_FOR_COMPUTING,
      TIMER_INTERVAL_SCALE_FOR_COMPUTING,
      onTimerExpireForComputing,
      true
    )
  end
  LOGGER:trace("updateTimerForComputing START")
  TIMER_FOR_COMPUTING:start()
  LOGGER:trace("TIMER_FOR_COMPUTING:", TIMER_FOR_COMPUTING)
end

function onTimerExpireForComputing()
  LOGGER:trace("onTimerExpireForComputing()")
  updateTimerForComputing(TIMER_INTERVAL_FOR_COMPUTING)
  --update_pid()
  compute_pid()
end

function updateTimerForInfluxDB(new_interval)
  if (TIMER_FOR_INFLUXDB == nil) then
    LOGGER:trace("updateTimerForInfluxDB NEW")
    TIMER_FOR_INFLUXDB =
      TimerManager:new(TIMER_INTERVAL_FOR_INFLUXDB, TIMER_INTERVAL_SCALE_FOR_INFLUXDB, onTimerExpireForInfluxDB, true)
  else
    LOGGER:trace("updateTimerForInfluxDB UPDATE")
    TIMER_FOR_INFLUXDB:stop()
    TIMER_FOR_INFLUXDB =
      TimerManager:new(TIMER_INTERVAL_FOR_INFLUXDB, TIMER_INTERVAL_SCALE_FOR_INFLUXDB, onTimerExpireForInfluxDB, true)
  end
  LOGGER:trace("updateTimerForComputing START")
  TIMER_FOR_INFLUXDB:start()
  LOGGER:trace("TIMER_FOR_COMPUTING:", TIMER_FOR_INFLUXDB)
end

function onTimerExpireForInfluxDB()
  LOGGER:trace("onTimerExpireForInfluxDB()")
  --TIMER_FOR_INFLUXDB:start()
  updateTimerForInfluxDB(TIMER_FOR_INFLUXDB)
  send_all_data_to_influx()
end

-----------------------------------------------------
-- COMMON
-----------------------------------------------------
function switch_heat_pid(state)
  LOGGER:debug("switch_heat_pid: ", state)
  if state == "OPEN" then
    C4:SendToProxy(HEATING_PID_OUTPUT_BIND, "OPEN", "NOTIFY")
    C4:SendToProxy(HEATING_INPUT_BIND, "OPENED", "NOTIFY")
    TMP_STORED_SETTING["HEATING_PID_OUTPUT_BIND"] = 0
  elseif state == "CLOSE" then
    C4:SendToProxy(HEATING_PID_OUTPUT_BIND, "CLOSE", "NOTIFY")
    C4:SendToProxy(HEATING_INPUT_BIND, "CLOSED", "NOTIFY") --do il feedback
    TMP_STORED_SETTING["HEATING_PID_OUTPUT_BIND"] = 1
  end
end
function switch_cool_pid(state)
  LOGGER:debug("switch_cool_pid: ", state)
  if state == "OPEN" then
    C4:SendToProxy(COOLING_PID_OUTPUT_BIND, "OPEN", "NOTIFY")
    C4:SendToProxy(COOLING_INPUT_BIND, "OPENED", "NOTIFY")
    TMP_STORED_SETTING["COOLING_PID_OUTPUT_BIND"] = 0
  elseif state == "CLOSE" then
    C4:SendToProxy(COOLING_PID_OUTPUT_BIND, "CLOSE", "NOTIFY")
    C4:SendToProxy(COOLING_INPUT_BIND, "CLOSED", "NOTIFY") --do il feedback
    TMP_STORED_SETTING["COOLING_PID_OUTPUT_BIND"] = 1
  end
end
function switch_fan_pid(state)
  LOGGER:debug("switch_fan_pid: ", state)
  if state == "OPEN" then
    C4:SendToProxy(FAN_PID_OUTPUT_BIND, "OPEN", "NOTIFY")
    C4:SendToProxy(FAN_INPUT_BIND, "OPENED", "NOTIFY")
    TMP_STORED_SETTING["FAN_PID_OUTPUT_BIND"] = 0
  elseif state == "CLOSE" then
    C4:SendToProxy(FAN_PID_OUTPUT_BIND, "CLOSE", "NOTIFY")
    C4:SendToProxy(FAN_INPUT_BIND, "CLOSED", "NOTIFY") --do il feedback
    TMP_STORED_SETTING["FAN_PID_OUTPUT_BIND"] = 1
  end
end

function compute_pid(waspaused)
  -- print("compute_pid", CURRENT_PID)
  -- print("c", Utility.tstring(CURRENT_PID))
  CURRENT_PID:compute(waspaused)
  C4:PersistSetValue("PID", CURRENT_PID:save())

  LOGGER:debug("CURRENT_PID.ouput: ", CURRENT_PID.output, " CURRENT_OFF_THRESHOLD: ", CURRENT_PID.threshold_off)
  if CURRENT_PID.output == nil then
    return
  end
  if HVAC_MODE == "OFF" then -- spento
    switch_heat_pid("OPEN")
    switch_cool_pid("OPEN")
    switch_fan_pid("OPEN")
    CURRENT_PID.output = 0
  else --se il PID è SOPRA alla soglia ACCENDO LE POMPE
    if CURRENT_PID.output > 0 then
      if CURRENT_PID.target_condition_on == "LT" then -- summer
        switch_heat_pid("OPEN")
        switch_cool_pid("CLOSE")
      elseif CURRENT_PID.target_condition_on == "GT" then -- winter
        switch_heat_pid("CLOSE")
        switch_cool_pid("OPEN")
      end
      if CURRENT_PID.output < CURRENT_PID.threshold_off then
        switch_fan_pid("OPEN")
      else
        switch_fan_pid("CLOSE")
      end
    else
      switch_heat_pid("OPEN")
      switch_cool_pid("OPEN")
      switch_fan_pid("OPEN")
      CURRENT_PID.output = 0
    end
  end

  CURRENT_PID.output = math.floor(CURRENT_PID.output)
  SetVariable(VARIABLE_OUTPUT_FAN_STR, tostring(CURRENT_PID.output))
  SetVariable(VARIABLE_OUTPUT_FAN_NUM, CURRENT_PID.output)
  set_status_properties()
end

function check_water_temperature(condition)
  LOGGER:trace(
    "WATER_SUPLY_CONTROL:",
    WATER_SUPLY_CONTROL,
    ", CONDITION:",
    condition,
    ", WATER_TEMPERATURE:",
    WATER_TEMPERATURE
  )
  if WATER_SUPLY_CONTROL == "ON" then
    if condition == "LT" then
      if WATER_TEMPERATURE < COOLING_WATER_THRESHOLD then
        LOGGER:trace("WATER_TEMPERATURE:", WATER_TEMPERATURE, ", COOLING_WATER_THRESHOLD:", COOLING_WATER_THRESHOLD)
        return true
      else
        return false
      end
    elseif condition == "GT" then
      if WATER_TEMPERATURE > HEATING_WATER_THRESHOLD then
        LOGGER:trace("WATER_TEMPERATURE:", WATER_TEMPERATURE, ", HEATING_WATER_THRESHOLD:", HEATING_WATER_THRESHOLD)
        return true
      else
        return false
      end
    end
  else
    return true
  end
end

function set_status_properties()
  for f in pairs(set_property) do
    pcall(set_property[f])
  end
end

local store_data = {}
function save_parameters()
  local data = {}

  data.kp = CURRENT_PID.kp
  data.ki = CURRENT_PID.ki
  data.kd = CURRENT_PID.kd
  data.input = CURRENT_PID.input
  data.target = CURRENT_PID.target
  data.output = CURRENT_PID.output
  data.minout = -CURRENT_PID.minout
  data.maxout = CURRENT_PID.maxout
  data.condition_on = CURRENT_PID.condition_on
  data._lasttime = CURRENT_PID._lasttime
  data._lastinput = CURRENT_PID._lastinput
  data._Iterm = CURRENT_PID._Iterm
  data.current_threshold = CURRENT_PID.threshold_off
  data.target_condition_on = CURRENT_PID.target_condition_on

  table.insert(store_data, data)
  print(Utility.tstring(data))
end

function get_key_by_subtable_key_value(father_table, subtable_key, subtable_value)
  if type(father_table) == "table" then
    for key, subtable in ipairs(father_table) do
      if type(subtable) == "table" then
        if subtable[tostring(subtable_key)] == subtable_value then
          return key
        end
      end
    end
  else
    LOGGER:debug("father_table is not a table")
  end
end

function map_value(value, old_max, old_min, new_max, new_min)
  print("NOT WORKING")
  local old_range = old_max - old_min
  local new_range = new_max - new_min
  return ((value - old_min) * (new_range - old_range)) + new_min
end

function switch_HVAC_mode(sCommand)
  LOGGER:trace("switch_HVAC_mode:", sCommand, sCommand == "COOL")

  local local_condition_on = "GT"
  if sCommand == "OPEN" then
    local_condition_on = "GT"
  end
  if sCommand == "CLOSE" then
    local_condition_on = "LT"
  end
  if sCommand == "COOL" then
    local_condition_on = "LT"
  end
  if sCommand == "HEAT" then
    local_condition_on = "GT"
  end
  if sCommand == "AUTO" then
    print("-------------------------------GESTIRE LA CONDIZIONE AUTO")
  end
  if sCommand == "OFF" then
    local_condition_on = "OFF"
    print("-------------------------------GESTIRE LA CONDIZIONE OFF")
  end

  LOGGER:trace("switch_HVAC_mode:", sCommand, local_condition_on, CURRENT_PID.target_condition_on)

  --if local_condition_on ~= CURRENT_PID.target_condition_on then
  if local_condition_on == "GT" then
    LOGGER:trace("switch_HVAC_mode - switching to HEATING MODE")
    CURRENT_PID = HEAT_PID
    HVAC_MODE = "HEAT"
    compute_pid(true)
  end
  if local_condition_on == "LT" then
    LOGGER:trace("switch_HVAC_mode - switching to COOLING MODE")
    CURRENT_PID = COOL_PID
    HVAC_MODE = "COOL"
    --update_pid()
    compute_pid(true)
  end
  if local_condition_on == "OFF" then
    LOGGER:trace("switch_HVAC_mode - switching to OFF MODE")
    HVAC_MODE = "OFF"
    compute_pid(true)
  end
  C4:PersistSetValue("HVAC_MODE", HVAC_MODE)
  --end
end

function set_cool_setpoint(setpoint)
  LOGGER:trace("set_cool_setpoint:", setpoint)
  setpoint_int = tonumber(setpoint)
  COOL_PID.target = setpoint_int
end

function set_heat_setpoint(setpoint)
  LOGGER:trace("set_heat_setpoint:", setpoint)
  setpoint_int = tonumber(setpoint)
  HEAT_PID.target = setpoint_int
end

function set_fan_state(state)
  LOGGER:trace("set_fan_state:", state)
end

function set_HVAC_state(state)
  LOGGER:trace("set_HVAC_state:", state)
end

function set_target(tTarget, idBind)
  LOGGER:trace("set_target:", Utility.tstring(tTarget), idBind)
  if (tTarget["SCALE"] == "CELSIUS" and Utility.tonumber_loc(tTarget["TEMPERATURE"])) then
    LOGGER:trace("Setting Target to:", target)
    if (CURRENT_PID.target_condition_on == "GT") and (idBind == HEAT_SETPOINT_INPUT_BIND) then
      target = Utility.tonumber_loc(tTarget["TEMPERATURE"])
      CURRENT_PID.target = target
      LOGGER:trace("Setting persist _HEAT_SETPOINT", CURRENT_PID.target)
      C4:PersistSetValue("_HEAT_SETPOINT", CURRENT_PID.target)
    elseif (CURRENT_PID.target_condition_on == "LT") and (idBind == COOL_SETPOINT_INPUT_BIND) then
      target = Utility.tonumber_loc(tTarget["TEMPERATURE"])
      CURRENT_PID.target = target
      LOGGER:trace("Setting persist _COOL_SETPOINT", CURRENT_PID.target)
      C4:PersistSetValue("_COOL_SETPOINT", CURRENT_PID.target)
    end
  end
end

function set_input(tInput)
  input = Utility.tonumber_loc(tInput["CELSIUS"])
  LOGGER:trace("set_input:", input)
  CURRENT_PID.input = input
end

function send_all_data_to_influx()
  LOGGER:trace("send_all_data_to_influx")
  local all_data, pid_time = prepare_data_to_send()
  for k, v in pairs(all_data) do
    send_data_to_influx(k, v, pid_time)
  end
end

function prepare_data_to_send()
  LOGGER:trace("prepare_data_to_send")
  local GlobalData = {}
  local pid_time
  for k, v in pairs(CURRENT_PID) do
    GlobalData[k] = v
  end
  pid_time = CURRENT_PID._lasttime
  for k, v in pairs(TMP_STORED_SETTING) do
    GlobalData[k] = v
  end
  GlobalData["THRESHOLD_CONDITION_ON"] = CURRENT_PID.target_condition_on
  GlobalData["WATER_TEMPERATURE"] = WATER_TEMPERATURE
  GlobalData["WATER_SUPLY_CONTROL"] = WATER_SUPLY_CONTROL
  GlobalData["COOLING_PID_OUTPUT_BIND"] = TMP_STORED_SETTING["COOLING_PID_OUTPUT_BIND"]
  GlobalData["HEATING_PID_OUTPUT_BIND"] = TMP_STORED_SETTING["HEATING_PID_OUTPUT_BIND"]
  GlobalData["FAN_PID_OUTPUT_BIND"] = TMP_STORED_SETTING["FAN_PID_OUTPUT_BIND"]
  return GlobalData, pid_time
end

TMP_PRINTER = true
TMP_STORED_DATA = {}
function print_table_as_csv(table)
  if TMP_PRINTER then
    line = ""
    for k, v in ipairs(table) do
      line = line .. k .. ", " .. v .. ","
    end
    line = line .. "\n"
    table.insert(TMP_STORED_DATA, line)
  end
end

function send_data_to_influx(varName, varValue, timeValue)
  -- local url = Properties[PROPERTY_NAME_URL_TO_CHECK]
  LOGGER:trace("send_data_to_influx", varName, varValue, timeValue)
  isSendAble = true
  local headers = {["Authorization"] = "Token " .. tostring(NAME_INFLUX_TOKEN)}
  local params = {
    org = tostring(NAME_INFLUX_ORG),
    bucket = tostring(NAME_INFLUX_BUCKET),
    precision = "ms"
  }
  local label = tostring(varName)
  local sanitizedName = string.gsub(label, "[%%/,%-()#@%[%]]+", "")
  local trimmedName = string.gsub(sanitizedName, "%s", "_")
  local driverName = C4:GetDeviceDisplayName(C4:GetDeviceID())
  local DriverSanitizedName = string.gsub(driverName, "[%%/,%-()#@%[%]]+", "")
  local DriverTrimmedName = string.gsub(DriverSanitizedName, "%s", "_")
  if varValue ~= "nil" then
    varValue = tostring(varValue)
    varValue = varValue:gsub(",", ".")
    data = DriverTrimmedName .. " " .. trimmedName .. "=" .. varValue
  else
    isSendAble = false
  end

  if (isSendAble) then
    if timeValue ~= "nil" then
      timeValueMS =  math.floor(timeValue * 1000)
      data = data .. " " .. timeValueMS
    end
    API_MANAGER:add_request("post", INFLUX_ENDPOINT, headers, params, data, influxdb_write_response)
    API_MANAGER:send_next_requests()
  else
    LOGGER:info("Is not sendable. No data sent.")
  end
end

function influxdb_write_response(transfer, responses, errCode, errMsg)
  if (errCode == 0) then
    local lresp = responses[#responses]
    LOGGER:debug(
      "check_service_status_respose_handler(): transfer succeeded (",
      #responses,
      " responses received), last response code: " .. lresp.code
    )
    for hdr, val in pairs(lresp.headers) do
      LOGGER:debug("check_service_status_respose_handler(): ", hdr, " = ", val)
    end
    LOGGER:debug("check_service_status_respose_handler(): body of last response:", lresp.body)
  else
    if (errCode == -1) then
      LOGGER:debug("check_service_status_respose_handler(): transfer was aborted")
    else
      LOGGER:debug(
        "check_service_status_respose_handler(): transfer failed with error",
        errCode,
        ":",
        errMsg,
        "(",
        #responses,
        "responses completed)"
      )
    end
  end
end
