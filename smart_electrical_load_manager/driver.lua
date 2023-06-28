local TimerManager = require "SKC4.TimerManager"
local Utility = require("SKC4.Utility")
require 'SKC4.LicenseManager'
require("SKC4.DriverCore")
LOGGER = SKC4_LOGGER


-----------------------------------------------------
-- GLOBALS
-----------------------------------------------------
DRIVER_NAME = "smart_electrical_load_manager"
API_MANAGER = {}

CHANNELS_ARE_CHANGING = false
MAX_NUMBER_OF_PRIORITY_CHANNELS = 20
LAST_VALUE_NUMBER_OF_PRIORITY_CHANNELS = 10

PROXY_BINDING_ID = 50
PROXY_BINDING_NAME = "Priority Channel"

-- Propertie and variable names
PROPERTY_NAME_CURRENT_STATE = "Current State"
PROPERTY_NAME_NUMBER_OF_PRIORITY_CHANNELS = "Number Of Channels"
PROPERTY_NAME_CURRENT_POWER = "Current Power"
PROPERTY_NAME_DELAY_BEFORE_CLOSE_RELAY = "Delay Before Close Relay"
PROPERTY_NAME_DELAY_BEFORE_OPEN_RELAY = "Delay Before Open Relay"
PROPERTY_NAME_DELAY_AFTER_CLOSE_RELAY = "Delay After Close Relay"
PROPERTY_NAME_DELAY_AFTER_OPEN_RELAY = "Delay After Open Relay"
PROPERTY_NAME_TOTAL_POWER_THRESHOLD = "Total Power Threshold"
PROPERTY_NAME_POWER_DELTA_ON_CLOSE = "Power Delta On Close"
PROPERTY_NAME_POWER_MODE = "Power Consumption Is..."
PROPERTY_NAME_DRIVER_MODE = "Smart Manager is"

PROPERTY_VALUE_POWER_MODE_NEGATIVE = "Negative"
PROPERTY_VALUE_POWER_MODE_POSITIVE = "Positive"

PROPERTY_NAME_DRIVER_MODE_VALUE_ON = "On"
PROPERTY_NAME_DRIVER_MODE_VALUE_OFF = "Off"
PROPERTY_NAME_DRIVER_MODE_VALUE_OFF_15 = "Off for 15 minutes"
PROPERTY_NAME_DRIVER_MODE_VALUE_OFF_30 = "Off for 30 minutes"
PROPERTY_NAME_DRIVER_MODE_VALUE_OFF_60 = "Off for 1 hour"

VARIABLE_NAME_CURRENT_POWER = "CURRENT_POWER"
VARIABLE_NAME_CURRENT_POWER_STRING = "CURRENT_POWER_STRING"
VARIABLE_NAME_CURRENT_POWER_FLOAT = "CURRENT_POWER_FLOAT"
VARIABLE_NAME_CURRENT_STATE = "CURRENT_STATE"
VARIABLE_NAME_DRIVER_MODE = "DRIVER_MODE"


-- ...priority channels
PROPERTY_NAME_PRIORITY_CHANNEL_LOAD = "Priority Channel Load"
PROPERTY_NAME_PRIORITY_CHANNEL_STATE = "Priority Channel State"
VARIABLE_NAME_PRIORITY_CHANNEL_STATE = "PRIORITY_CHANNEL_STATE"
-- VARIABLE_NAME_PRIORITY_CHANNEL ="PRIORITY_CHANNEL"

-- Timers
TIMER_DELAY_BEFORE_CHANGING = nil
TIMER_DELAY_AFTER_CHANGING = nil
TIMER_CHANGE_DRIVER_MODE = nil

-- License
--- Config License Manager  
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID  
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)  
LICENSE_MGR:setParamValue("FileName", DRIVER_NAME..".c4z", "DRIVERCENTRAL")  
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")  
--- end license 

-----------------------------------------------------
-- INITIALIZATION
-----------------------------------------------------

function ON_DRIVER_LATE_INIT.init_priority_channels()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_priority_channels()")
  
  init_available_priority_channels()
end

function ON_DRIVER_LATE_INIT.init_variabless()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_variabless()")

  AddVariable(VARIABLE_NAME_CURRENT_STATE, tostring(Properties[PROPERTY_NAME_CURRENT_STATE]), "STRING", true, false)
  AddVariable(VARIABLE_NAME_DRIVER_MODE, tostring(Properties[PROPERTY_NAME_DRIVER_MODE]), "STRING", false, false)
  AddVariable(VARIABLE_NAME_CURRENT_POWER, Utility.tonumber_loc(Properties[PROPERTY_NAME_CURRENT_POWER]), "NUMBER", false, false)
  AddVariable(VARIABLE_NAME_CURRENT_POWER_STRING, tostring(Properties[PROPERTY_NAME_CURRENT_POWER]), "STRING", false, false)
  AddVariable(VARIABLE_NAME_CURRENT_POWER_FLOAT, Utility.tonumber_loc(Properties[PROPERTY_NAME_CURRENT_POWER]), "STRING", false, false)
  
end

function ON_DRIVER_DESTROYED.destroy_timer()
  if (TIMER_DELAY_BEFORE_CHANGING) then
    TIMER_DELAY_BEFORE_CHANGING:stop()
  end
  if (TIMER_DELAY_AFTER_CHANGING) then
    TIMER_DELAY_AFTER_CHANGING:stop()
  end
  if (TIMER_CHANGE_DRIVER_MODE) then
    TIMER_CHANGE_DRIVER_MODE:stop()
  end
end

-----------------------------------------------------
-- VARIABLES
-----------------------------------------------------



ON_VARIABLE_CHANGED[VARIABLE_NAME_CURRENT_POWER_STRING] = function()
  local current_power = GetVariable(VARIABLE_NAME_CURRENT_POWER_STRING)
  local float_value = Utility.tonumber_loc(current_power)
  local numeric_value = math.floor(0.5+float_value)
  local string_value = tostring(numeric_value)


  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_STRING:current_power ->",current_power)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_STRING:float_value ->",float_value)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_STRING:numeric_value ->",numeric_value)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_STRING:string_value ->",string_value)

  SetVariable(VARIABLE_NAME_CURRENT_POWER_FLOAT, float_value)
  SetVariable(VARIABLE_NAME_CURRENT_POWER, numeric_value)
  UpdateProperty(PROPERTY_NAME_CURRENT_POWER, float_value)
  evaluate_the_new_power()
end


ON_VARIABLE_CHANGED[VARIABLE_NAME_CURRENT_POWER] = function()
  local current_power = GetVariable(VARIABLE_NAME_CURRENT_POWER)
  local float_value = Utility.tonumber_loc(current_power)
  local numeric_value = float_value
  local string_value = tostring(current_power)
  
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_POWER:current_power ->",current_power)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_POWER:float_value ->",float_value)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_POWER:numeric_value ->",numeric_value)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_POWER:string_value ->",string_value)

  SetVariable(VARIABLE_NAME_CURRENT_POWER_FLOAT, float_value)
  SetVariable(VARIABLE_NAME_CURRENT_POWER_STRING, string_value)
  UpdateProperty(PROPERTY_NAME_CURRENT_POWER, numeric_value)
  evaluate_the_new_power()
end



ON_VARIABLE_CHANGED[VARIABLE_NAME_CURRENT_POWER_FLOAT] = function()
  local current_power = GetVariable(VARIABLE_NAME_CURRENT_POWER_FLOAT)
  local float_value = Utility.tonumber_loc(current_power)
  local numeric_value = float_value
  local string_value = tostring(current_power)
  

  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_FLOAT:current_power ->",current_power)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_FLOAT:float_value ->",float_value)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_FLOAT:numeric_value ->",numeric_value)
  LOGGER:debug("VARIABLE_NAME_CURRENT_POWER_FLOAT:string_value ->",string_value)


  SetVariable(VARIABLE_NAME_CURRENT_POWER_STRING, string_value)
  SetVariable(VARIABLE_NAME_CURRENT_POWER, numeric_value)
  UpdateProperty(PROPERTY_NAME_CURRENT_POWER, float_value)
  evaluate_the_new_power()
end

ON_VARIABLE_CHANGED[VARIABLE_NAME_DRIVER_MODE] = function()
  local value = GetVariable(VARIABLE_NAME_DRIVER_MODE)
  LOGGER:debug(VARIABLE_NAME_DRIVER_MODE, ":", value)
  if (value) then
    if (TIMER_CHANGE_DRIVER_MODE) then
      TIMER_CHANGE_DRIVER_MODE:stop()
    end

    local interval = get_driver_off_interval_from_variable(value)
    LOGGER:debug("interval:", interval)
    if (interval ~= 0) then
      set_driver_mode_off()
      if (is_driver_off()) then
        UpdateProperty(PROPERTY_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_OFF)
      else
        UpdateProperty(PROPERTY_NAME_DRIVER_MODE,interval)
      end

      local callback = function()
        set_driver_mode_on()
        UpdateProperty(PROPERTY_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
        SetVariable(VARIABLE_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
      end

      TIMER_CHANGE_DRIVER_MODE = TimerManager:new(interval, "MINUTES", callback, false)
      TIMER_CHANGE_DRIVER_MODE:start()     
    else
      set_driver_mode_on()
      UpdateProperty(PROPERTY_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
    end
 
  end
end

-----------------------------------------------------
-- PROPERTIES
-----------------------------------------------------

ON_PROPERTY_CHANGED[PROPERTY_NAME_TOTAL_POWER_THRESHOLD] = function(value)
  LOGGER:debug(PROPERTY_NAME_TOTAL_POWER_THRESHOLD, ":", value)
  evaluate_the_new_power()
end

ON_PROPERTY_CHANGED[PROPERTY_NAME_NUMBER_OF_PRIORITY_CHANNELS] = function(value)
  LOGGER:debug(PROPERTY_NAME_NUMBER_OF_PRIORITY_CHANNELS, ":", value)
  if (value) then
    init_available_priority_channels()
  end
end


ON_PROPERTY_CHANGED[PROPERTY_NAME_DRIVER_MODE] = function(value)
  LOGGER:debug(PROPERTY_NAME_DRIVER_MODE, ":", value)
  if (value) then
    if (TIMER_CHANGE_DRIVER_MODE) then
      TIMER_CHANGE_DRIVER_MODE:stop()
    end

    local interval = get_driver_off_interval_from_property(value)
    LOGGER:debug("interval:", interval)
    if (interval ~= 0) then
      set_driver_mode_off()
      if (is_driver_off()) then
        SetVariable(VARIABLE_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_OFF)
      else
        SetVariable(VARIABLE_NAME_DRIVER_MODE,interval)
      end

      local callback = function()
        set_driver_mode_on()
        UpdateProperty(PROPERTY_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
        SetVariable(VARIABLE_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
      end

      TIMER_CHANGE_DRIVER_MODE = TimerManager:new(interval, "MINUTES", callback, false)
      TIMER_CHANGE_DRIVER_MODE:start()     
    else
      set_driver_mode_on()
      SetVariable(VARIABLE_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
    end
 
  end
end



  -----------------------------------------------------
-- PROXY COMMANDS
-----------------------------------------------------

function PROXY_COMMANDS.OPENED(tPrams, idBinding)
  local id = idBinding - PROXY_BINDING_ID
  set_channel_property_state(id, "OPENED")
end
function PROXY_COMMANDS.CLOSED(tPrams, idBinding)
  local id = idBinding - PROXY_BINDING_ID
  set_channel_property_state(id, "CLOSED")
end

-----------------------------------------------------
-- COMMANDS
-----------------------------------------------------

function ACTIONS.Reset(params)
  LOGGER:debug("Resetting...")
  CHANNELS_ARE_CHANGING = false
  if (TIMER_DELAY_BEFORE_CHANGING) then
    TIMER_DELAY_BEFORE_CHANGING:stop()
  end
  if (TIMER_DELAY_AFTER_CHANGING) then
    TIMER_DELAY_AFTER_CHANGING:stop()
  end
  local NUMBER_OF_PRIORITY_CHANNELS = Utility.tonumber_loc(Properties[PROPERTY_NAME_NUMBER_OF_PRIORITY_CHANNELS])
  for i = 1, NUMBER_OF_PRIORITY_CHANNELS, 1 do
    local prop_name_state = PROPERTY_NAME_PRIORITY_CHANNEL_STATE .. " " .. tostring(i)
    close_channel_relay(i)
    --UpdateProperty(prop_name_state, "CLOSED")
  end
  UpdateProperty(PROPERTY_NAME_CURRENT_POWER, 0)
  set_general_state("NORMAL")
  LOGGER:debug("Resetting... done!")
end

-----------------------------------------------------
-- CONDITIONAL
-----------------------------------------------------
-----------------------------------------------------
-- TIMER
-----------------------------------------------------

-----------------------------------------------------
-- COMMON
-----------------------------------------------------

function init_available_priority_channels()
  local NUMBER_OF_PRIORITY_CHANNELS = Utility.tonumber_loc(Properties[PROPERTY_NAME_NUMBER_OF_PRIORITY_CHANNELS])
  -- enable required channels
  for i = 1, NUMBER_OF_PRIORITY_CHANNELS, 1 do
    local prop_name_load = PROPERTY_NAME_PRIORITY_CHANNEL_LOAD .. " " .. tostring(i)
    local prop_name_state = PROPERTY_NAME_PRIORITY_CHANNEL_STATE .. " " .. tostring(i)
    C4:SetPropertyAttribs(prop_name_load, 0)
    LOGGER:debug("Show", prop_name_load)
    C4:SetPropertyAttribs(prop_name_state, 0)
    LOGGER:debug("Show", prop_name_state)

    local var_name_state = VARIABLE_NAME_PRIORITY_CHANNEL_STATE .. "_" .. tostring(i)
    -- local var_name_power = VARIABLE_NAME_PRIORITY_CHANNEL.."_"..tostring(i)
    AddVariable(var_name_state, "", "STRING", true, false)
    LOGGER:debug("Add", var_name_state)
    -- AddVariable(var_name_power, "", "NUMBER", true, false)
    -- LOGGER:debug("Add", var_name_power)

    local connection_name = PROXY_BINDING_NAME .. " " .. tostring(i)
    local connection_id = PROXY_BINDING_ID + i
    --C4:AddDynamicBinding(connection_id, "PROXY", false, connection_name, "RELAY", false, false)
    --close_channel_relay(i)
  end

  -- disable other channels
  for i = NUMBER_OF_PRIORITY_CHANNELS + 1, MAX_NUMBER_OF_PRIORITY_CHANNELS, 1 do
    local prop_name_load = PROPERTY_NAME_PRIORITY_CHANNEL_LOAD .. " " .. tostring(i)
    local prop_name_state = PROPERTY_NAME_PRIORITY_CHANNEL_STATE .. " " .. tostring(i)
    C4:SetPropertyAttribs(prop_name_load, 1)
    LOGGER:debug("Hide", prop_name_load)
    C4:SetPropertyAttribs(prop_name_state, 1)
    LOGGER:debug("Hide", prop_name_state)

    local var_name_state = VARIABLE_NAME_PRIORITY_CHANNEL_STATE .. "_" .. tostring(i)
    -- local var_name_power = VARIABLE_NAME_PRIORITY_CHANNEL.."_"..tostring(i)
    -- DeleteVariable(var_name_power)
    -- LOGGER:debug("Remove", var_name_power)
    DeleteVariable(var_name_state)
    LOGGER:debug("Remove", var_name_state)
    local connection_id = PROXY_BINDING_ID + i
    --open_channel_relay(i)
    --C4:RemoveDynamicBinding(connection_id)
  end

  CHANNELS_ARE_CHANGING = false
end


function find_next_channel_to_close()
  return find_first_channel_that_is_not("CLOSED", true)
end
function find_next_channel_to_open()
  return find_first_channel_that_is_not("OPENED", false)
end
function find_first_channel_that_is_not(state, ascendent)
  --LOGGER:debug("find_first_channel_that_is_not", state, ascendent)
  local NUMBER_OF_PRIORITY_CHANNELS = Utility.tonumber_loc(Properties[PROPERTY_NAME_NUMBER_OF_PRIORITY_CHANNELS])
  -- enable required channels
  local channel_to_change = 0
  local start_index = 1
  local end_index = NUMBER_OF_PRIORITY_CHANNELS
  local increment = 1

  if (not ascendent) then
    start_index = NUMBER_OF_PRIORITY_CHANNELS
    end_index = 1
    increment = -1
  end

  for i = start_index, end_index, increment do
    local prop_name_state = PROPERTY_NAME_PRIORITY_CHANNEL_STATE .. " " .. tostring(i)
    local current_state = Properties[prop_name_state]
    -- LOGGER:debug("current_state =", current_state)
    -- LOGGER:debug("state = ", state)
    -- LOGGER:debug("current_state == state", current_state == state)
    if (current_state ~= state) then
      channel_to_change = i
      break
    end
  end
  
  --LOGGER:debug("channel_to_change", channel_to_change)
  return channel_to_change
end

function set_general_state(state)
  -- TODO
  -- stati possibili
  -- FAILURE: abbiamo staccato tutto ma non possiamo ridurre l'assorbimento
  -- OPENING
  -- CLOSING
  -- NORMAL
  -- OVERFLOW
  -- OFF
  SetVariable(VARIABLE_NAME_CURRENT_STATE, state)
  UpdateProperty(PROPERTY_NAME_CURRENT_STATE, state)
end
function set_channel_property_state(channel_id, state)
  local prop_name_state = PROPERTY_NAME_PRIORITY_CHANNEL_STATE .. " " .. tostring(channel_id)
  local variable_name_state = VARIABLE_NAME_PRIORITY_CHANNEL_STATE .. "_" .. tostring(channel_id)
  UpdateProperty(prop_name_state, state)
  SetVariable(variable_name_state, state)
end

function close_channel_relay(channel_id)
  LOGGER:debug("close_channel_relay",channel_id)
  local channel_proxy_id = PROXY_BINDING_ID + channel_id
  --set_channel_property_state(channel_id, "CLOSED")
  C4:SendToProxy(channel_proxy_id, "CLOSE", "", "COMMAND")
end
function open_channel_relay(channel_id)
  LOGGER:debug("open_channel_relay",channel_id)
  local channel_proxy_id = PROXY_BINDING_ID + channel_id
  --set_channel_property_state(channel_id, "OPENED")
  C4:SendToProxy(channel_proxy_id, "OPEN", "", "COMMAND")
end

function start_opening_channel(channel_id)
  LOGGER:debug("Start opening channel",channel_id)
  local before_seconds = Utility.tonumber_loc(Properties[PROPERTY_NAME_DELAY_BEFORE_OPEN_RELAY])
  local after_seconds = Utility.tonumber_loc(Properties[PROPERTY_NAME_DELAY_AFTER_OPEN_RELAY])
  start_changing_channel(channel_id, "OPEN", before_seconds, after_seconds)
end
function start_closing_channel(channel_id)
  LOGGER:debug("Start closing channel",channel_id)
  local before_seconds = Utility.tonumber_loc(Properties[PROPERTY_NAME_DELAY_BEFORE_CLOSE_RELAY])
  local after_seconds = Utility.tonumber_loc(Properties[PROPERTY_NAME_DELAY_AFTER_CLOSE_RELAY])
  start_changing_channel(channel_id, "CLOSE", before_seconds, after_seconds)
end
function start_changing_channel(channel_id, new_state, before_seconds, after_seconds)
  -- change state of channel in OPENING
  CHANNELS_ARE_CHANGING = true
  if (new_state=="CLOSE") then
    set_channel_property_state(channel_id, "CLOSING")
  else
    set_channel_property_state(channel_id, "OPENING")
  end
  -- start timer delay on open for the channel
  if TIMER_DELAY_BEFORE_CHANGING then
    TIMER_DELAY_BEFORE_CHANGING:stop()
  end

  local callback = function()
    changing_channel(channel_id, new_state, before_seconds)
  end
  TIMER_DELAY_BEFORE_CHANGING = TimerManager:new(Utility.tonumber_loc(before_seconds), "SECONDS", callback, false)
  TIMER_DELAY_BEFORE_CHANGING:start()
end

function changing_channel(channel_id, new_state, after_seconds)
  LOGGER:debug("Changing channel",channel_id,new_state, after_seconds)
  if (new_state == "CLOSE") then
    if (have_to_open_a_channel()) then
      set_channel_property_state(channel_id, "OPENED")
      end_changing_channel(channel_id)
      return
    else
      close_channel_relay(channel_id)
    end
  else
    if (have_to_open_a_channel()) then
      open_channel_relay(channel_id)
    else
      set_channel_property_state(channel_id, "CLOSED")
      end_changing_channel(channel_id)
      return
    end
  end

  local callback = function()
    end_changing_channel(channel_id)
  end

  TIMER_DELAY_AFTER_CHANGING = TimerManager:new(Utility.tonumber_loc(after_seconds), "SECONDS", callback, false)
  TIMER_DELAY_AFTER_CHANGING:start()
end
function end_changing_channel(channel_id)
  LOGGER:debug("End changing channel",channel_id)
  CHANNELS_ARE_CHANGING = false
  if (have_to_open_a_channel()) then
    set_general_state("OVERFLOW")
  else
    set_general_state("NORMAL")
  end
end

function have_to_open_a_channel()
  --LOGGER:debug("have_to_open_a_channel()")
  local current_power = Utility.tonumber_loc(Properties[PROPERTY_NAME_CURRENT_POWER])
  local power_threshold = Utility.tonumber_loc(Properties[PROPERTY_NAME_TOTAL_POWER_THRESHOLD])
  local power_mode = Properties[PROPERTY_NAME_POWER_MODE]

  --LOGGER:debug("current_power:",current_power)
  --LOGGER:debug("power_threshold:",power_threshold)
  --LOGGER:debug("power_mode:",power_mode)

  local have_to_open_channel = (power_threshold > current_power) -- negative mode
  if (power_mode == PROPERTY_VALUE_POWER_MODE_POSITIVE) then
    have_to_open_channel = power_threshold < current_power
  end

  --LOGGER:debug("have_to_open_channel:",have_to_open_channel)
  return have_to_open_channel
end

function have_to_close_a_channel()
  --LOGGER:debug("have_to_close_a_channel()")
  local current_power = Utility.tonumber_loc(Properties[PROPERTY_NAME_CURRENT_POWER])
  local power_threshold = Utility.tonumber_loc(Properties[PROPERTY_NAME_TOTAL_POWER_THRESHOLD])
  local power_mode = Properties[PROPERTY_NAME_POWER_MODE]
  local power_delta = Utility.tonumber_loc(Properties[PROPERTY_NAME_POWER_DELTA_ON_CLOSE])

  -- LOGGER:debug("current_power:",current_power)
  -- LOGGER:debug("power_threshold:",power_threshold)
  -- LOGGER:debug("power_mode:",power_mode)
  -- LOGGER:debug("power_delta:",power_delta)
  
  local have_to_close_channel = (power_threshold < (current_power + power_delta))
  if (power_mode == PROPERTY_VALUE_POWER_MODE_POSITIVE) then
    have_to_close_channel = (power_threshold > (current_power + power_delta))
  end

  LOGGER:debug("have_to_close_channel:",have_to_close_channel)
  return have_to_close_channel
end


function there_are_conditions_to_close_channel(channel_id)
  if (channel_id <=0) then
    return false
  end

  local current_power = Utility.tonumber_loc(Properties[PROPERTY_NAME_CURRENT_POWER])
  local power_threshold = Utility.tonumber_loc(Properties[PROPERTY_NAME_TOTAL_POWER_THRESHOLD])
  local power_mode = Properties[PROPERTY_NAME_POWER_MODE]
  local channel_load = Utility.tonumber_loc(Properties[PROPERTY_NAME_PRIORITY_CHANNEL_LOAD.." "..tostring(channel_id)])

  -- LOGGER:debug("current_power:",current_power)
  -- LOGGER:debug("power_threshold:",power_threshold)
  -- LOGGER:debug("power_mode:",power_mode)
  -- LOGGER:debug("power_delta:",power_delta)
  
  local have_to_close_channel = (power_threshold < (current_power + channel_load))
  if (power_mode == PROPERTY_VALUE_POWER_MODE_POSITIVE) then
    have_to_close_channel = (power_threshold > (current_power + channel_load))
  end

  LOGGER:debug("have_to_close_channel:",have_to_close_channel)
  return have_to_close_channel
end



function evaluate_the_new_power()
  if (not LICENSE_MGR:isAbleToWork()) then
    LOGGER:debug("The driver is UNLICENSED")
    set_general_state("UNLICENSED")
  end

  local current_power = Properties[PROPERTY_NAME_CURRENT_POWER]
  LOGGER:debug(PROPERTY_NAME_CURRENT_POWER, ":", current_power)
  
  
  if (is_driver_off()) then
    LOGGER:debug("Driver mode is off. Skip.")
    return
  end

  if (current_power) then
    if (not CHANNELS_ARE_CHANGING) then
      
      local have_to_open_channel = have_to_open_a_channel()
      local have_to_close_channel = have_to_close_a_channel()
      LOGGER:debug("have_to_open_channel", have_to_open_channel)
      LOGGER:debug("have_to_close_channel", have_to_close_channel)

      if (have_to_open_channel) then
        set_general_state("OVERFLOW")
      end
      if (have_to_close_channel) then
        set_general_state("NORMAL")
      end
      
      if (have_to_open_channel) then
        local next_open_channel_id = find_next_channel_to_open()
        LOGGER:debug("next_open_channel_id", next_open_channel_id)
        if (next_open_channel_id > 0) then
          start_opening_channel(next_open_channel_id)
        else
          set_general_state("FAILURE")
        end
      elseif (have_to_close_channel) then
        local next_close_channel_id = find_next_channel_to_close()
        LOGGER:debug("next_close_channel_id", next_close_channel_id)
        local there_are_conditions_to_close_channel = there_are_conditions_to_close_channel(next_close_channel_id)
        LOGGER:debug("there_are_conditions_to_close_channel", there_are_conditions_to_close_channel)
        if (there_are_conditions_to_close_channel) then
          start_closing_channel(next_close_channel_id)
        else
          set_general_state("NORMAL")
        end
      else
        set_general_state("NORMAL")
      end
    end
  end
end

function is_driver_on()
  return (Properties[PROPERTY_NAME_DRIVER_MODE] == PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
end
function is_driver_off()
  return not is_driver_on()
end

function set_driver_mode_on()
  --UpdateProperty(PROPERTY_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_ON)
  set_general_state("NORMAL")
end
function set_driver_mode_off()
  --UpdateProperty(PROPERTY_NAME_DRIVER_MODE,PROPERTY_NAME_DRIVER_MODE_VALUE_OFF)
  set_general_state("OFF")
end


function get_driver_off_interval_from_property(value)
  local mode = value or Properties[PROPERTY_NAME_DRIVER_MODE]

  --LOGGER:debug("get_driver_off_interval_from_property():", value)
  if (mode == PROPERTY_NAME_DRIVER_MODE_VALUE_ON) then
    return 0
  elseif (mode == PROPERTY_NAME_DRIVER_MODE_VALUE_OFF_15) then
    return 15
  elseif (mode == PROPERTY_NAME_DRIVER_MODE_VALUE_OFF_30) then
    return 30
  elseif (mode == PROPERTY_NAME_DRIVER_MODE_VALUE_OFF_60) then
    return 60
  else
    return -1
  end
end

function get_driver_off_interval_from_variable(value)
  local mode = string.lower(value)

  LOGGER:debug("get_driver_off_interval_from_variable():", value)
  if (mode == "on") then
    return 0
  elseif (mode == "off") then
    return -1
  else
    return Utility.tonumber_loc(value)
  end
end

-----------------------------------------------------
-- TEST
-----------------------------------------------------
