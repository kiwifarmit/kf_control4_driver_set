local ApiRestManager = require "SKC4.ApiRestManager"
local TimerManager = require "SKC4.TimerManager"
require 'SKC4.LicenseManager'
require "SKC4.DriverCore";
local Logger = require "SKC4.Logger"
local Utility = require "SKC4.Utility"
--LOGGER = Logger:new()

--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "shelly_25_blind.c4z", "DRIVERCENTRAL")
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")



--Globals
TIMER_FOR_POLLING = nil
TIMER_INTERVAL_FOR_POLLING = 10
TIMER_INTERVAL_SCALE_FOR_POLLING = "SECONDS"

PROPRETY_SHELLY_IP = "Shelly IP"
PROPRETY_SHELLY_USER = "Shelly Username (reserved login)"
PROPRETY_SHELLY_PWD = "Shelly Password (reserved login)"
PROPRETY_LAST_UPDATE_AT = "Last Update At"
PROPERTY_POLLING_INTERVAL = "Polling Interval"

PROPERTY_SHELLY_MODE = "Shelly Mode"
PROPERTY_SHELLY_MODE_ON_OFF = "On/Off/Stop"
PROPERTY_SHELLY_MODE_POSITION = "Position"

VARIABLE_NAME_STATE = "SHELLY_STATE"
VARIABLE_NAME_POWER = "SHELLY_POWER"
VARIABLE_NAME_IS_VALID = "SHELLY_IS_VALID"
VARIABLE_NAME_SAFETY_SWITCH = "SHELLY_SAFETY_SWITCH"
VARIABLE_NAME_OVERTEMPERATURE = "SHELLY_OVERTEMPERATURE"
VARIABLE_NAME_STOP_REASON = "SHELLY_STOP_REASON"
VARIABLE_NAME_LAST_DIRECTION = "SHELLY_LAST_DIRECTION"
VARIABLE_NAME_CURRENT_POS = "SHELLY_CURRENT_POS"
VARIABLE_NAME_CALIBRATING = "SHELLY_CALIBRATING"
VARIABLE_NAME_POSITIONING = "SHELLY_POSITIONING"

BLIND_PROXY = 5001  --BLIND
API_MANAGER = {}



function ON_DRIVER_EARLY_INIT.init_api_manager()
  LOGGER:debug("ON_DRIVER_EARLY_INIT.init_api_manager()")
  API_MANAGER = ApiRestManager:new()
  
  API_MANAGER:define_template("fopen",  "get", "/roller/0?go=open",   done_callback_status)
  API_MANAGER:define_template("fclose", "get", "/roller/0?go=close",  done_callback_status)
  API_MANAGER:define_template("stop",   "get", "/roller/0?go=stop",   done_callback_status)
  API_MANAGER:define_template("status", "get", "/roller/0",           done_callback_status)
  API_MANAGER:define_template("to_pos", "get", "/roller/0",           done_callback_status)
end

function ON_DRIVER_EARLY_INIT.init_blind_data()
  LOGGER:debug("ON_DRIVER_EARLY_INIT.init_blind_data()")
  gBlind = {}
  
  gBlind.can_stop = true
  gBlind.has_level = false
  gBlind.level_resolution = 1
  gBlind.hasSecondaryClosed = false
  --gBlind.level_closed_secondary = ""
  gBlind.ramp_rate = 10
  gBlind.targetLevel = 0
  gBlind.level_unknown = -1 -- Default to the unknown position
  
  gBlind.level_open = 100
  gBlind.level_closed = 0
  gBlind.level_discrete = false
  gBlind.level_target = -1
  gBlind.target_state = ""

  gBlind.last_response_state = "stop"
  gBlind.last_response_power = 0
  gBlind.last_response_is_valid = true
  gBlind.last_response_safety_switch = false
  gBlind.last_response_overtemperature = false
  gBlind.last_response_stop_reason = "normal"
  gBlind.last_response_last_direction = "open"
  gBlind.last_response_current_pos = 0
  gBlind.last_response_calibrating = false
  gBlind.last_response_positioning = false
end

function ON_DRIVER_LATE_INIT.init_variables()
  AddVariable(VARIABLE_NAME_STATE, gBlind.last_response_state, "STRING", true, false)
  AddVariable(VARIABLE_NAME_POWER, gBlind.last_response_power, "NUMBER", true, false)
  AddVariable(VARIABLE_NAME_IS_VALID, gBlind.last_response_is_valid, "BOOL", true, false)
  AddVariable(VARIABLE_NAME_SAFETY_SWITCH, gBlind.last_response_safety_switch, "BOOL", true, false)
  AddVariable(VARIABLE_NAME_OVERTEMPERATURE, gBlind.last_response_overtemperature, "BOOL", true, false)
  AddVariable(VARIABLE_NAME_STOP_REASON, gBlind.last_response_stop_reason, "STRING", true, false)
  AddVariable(VARIABLE_NAME_LAST_DIRECTION, gBlind.last_response_last_direction, "STRING", true, false)
  AddVariable(VARIABLE_NAME_CURRENT_POS, gBlind.last_response_current_pos, "NUMBER", true, false)
  AddVariable(VARIABLE_NAME_CALIBRATING, gBlind.last_response_calibrating, "BOOL", true, false)
  AddVariable(VARIABLE_NAME_POSITIONING, gBlind.last_response_positioning, "BOOL", true, false)
end

function ON_DRIVER_LATEINIT.update_timer_for_polling()
  LOGGER:debug("ON_DRIVER_LATEINIT.update_timer_for_polling()")
  updateTimerForPolling(TIMER_FOR_POLLING)
end

function ON_DRIVER_DESTROYED.destroy_timer()
  if (TIMER_FOR_POLLING) then
    LOGGER:debug("OnDriverDestroyed","Stopping polling timer")
    destroyTimerForPolling()
  end
end

function ON_DRIVER_LATE_INIT.init_ui()
  -- LOGGER:debug("ON_DRIVER_LATE_INIT.init_ui()")
  -- update_ui()
end


-------------------------
--- Properties
-------------------------
function ON_PROPERTY_CHANGED.Polling_Interval(sValue)
	LOGGER:debug("ON_PROPERTY_CHANGED.Polling_Interval: sValue = ",sValue)
	local value = tonumber(sValue)
	if value == nil then
	  TIMER_INTERVAL_FOR_POLLING = 10
	else
	  TIMER_INTERVAL_FOR_POLLING = value
  end
  
	LOGGER:debug("ON_PROPERTY_CHANGED.Polling_Interval: TIMER_FOR_POLLING = ",TIMER_FOR_POLLING)
  
	updateTimerForPolling(TIMER_INTERVAL_FOR_POLLING)
end


ON_PROPERTY_CHANGED[PROPRETY_SHELLY_IP] = function(value)
  LOGGER:debug("ON_PROPERTY_CHANGED", PROPRETY_SHELLY_IP,value)
  if (value) then
    API_MANAGER:set_base_url(value)
  end
end

ON_PROPERTY_CHANGED[PROPRETY_SHELLY_USER] = function(value)
  if (value == nil or value == "") then
    API_MANAGER:disable_authentication()
  else
    API_MANAGER:set_username(value)
    API_MANAGER:enable_basic_authentication()
  end
end
ON_PROPERTY_CHANGED[PROPRETY_SHELLY_PWD] = function(value)
  if (value) then
    API_MANAGER:set_password(value)
  end
end

ON_PROPERTY_CHANGED[PROPERTY_SHELLY_MODE] = function(value)
  if (value) then
    if (value == PROPERTY_SHELLY_MODE_ON_OFF) then
      set_drive_in_on_off_mode()
    elseif (value == PROPERTY_SHELLY_MODE_POSITION) then
      set_drive_in_position_mode()
    end
  end
end

-------------------------
--- ProxyCommands
-------------------------

function PROXY_COMMANDS.SET_LEVEL_TARGET(tParams, idBinding)
  if (not LICENSE_MGR:isAbleToWork()) then 
    return
  end

  local level_target = Utility.tonumber_loc (tParams.LEVEL_TARGET)
    
  if (gBlind.level_discrete) then --slider
    gBlind.target_level = level_target
    
    C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = level_target, RAMP_RATE = gBlind.ramp_rate}, "NOTIFY", true)
    gBlind.target_state = "LEVEL_TARGET"
    API_MANAGER:add_request_by_template("to_pos", {}, {
      go = "to_pos",
      roller_pos = level_target
    })
    
    API_MANAGER:send_next_requests()
  else
    if (level_target == gBlind.level_open) then
      C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = gBlind.level_open}, "NOTIFY", true)			
      gBlind.target_level = gBlind.level_open
      gBlind.target_state = "OPENED"
      API_MANAGER:add_request_by_template("fopen")
    elseif (level_target == gBlind.level_closed) then
      C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = gBlind.level_closed}, "NOTIFY", true)
      gBlind.target_level = gBlind.level_closed
      gBlind.target_state = "CLOSED"
      API_MANAGER:add_request_by_template("fclose")    
    end
    API_MANAGER:send_next_requests()
  end
end

function PROXY_COMMANDS.UP(tParams, idBinding)
  if (not LICENSE_MGR:isAbleToWork()) then 
    return
  end

  C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = gBlind.level_open}, "NOTIFY", true)			
  gBlind.target_level = gBlind.level_open
  gBlind.target_state = "OPENED"
  API_MANAGER:add_request_by_template("fopen")
  API_MANAGER:send_next_requests()
end
function PROXY_COMMANDS.DOWN(tParams, idBinding)
  if (not LICENSE_MGR:isAbleToWork()) then 
    return
  end

  C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = gBlind.level_closed}, "NOTIFY", true)
  gBlind.target_level = gBlind.level_closed
  gBlind.target_state = "CLOSED"
  API_MANAGER:add_request_by_template("fclose")
  API_MANAGER:send_next_requests()
end
function PROXY_COMMANDS.STOP(tParams, idBinding)
  if (not LICENSE_MGR:isAbleToWork()) then 
    return
  end

  C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = -1}, "NOTIFY", true)
  gBlind.target_level = -1
  gBlind.target_state = "STOPPED"
  API_MANAGER:add_request_by_template("stop")
  API_MANAGER:send_next_requests()
end

-- function PROXY_COMMANDS.TOGGLE(tParams, idBinding)
--   if (not LICENSE_MGR:isAbleToWork()) then 
--     return
--   end
-- 
--   if ( gBlind.last_direction == "close") then
--     C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = gBlind.level_open}, "NOTIFY", true)			
--     gBlind.target_level = gBlind.level_open
--     API_MANAGER:add_request_by_template("fopen")
--     API_MANAGER:send_next_requests()
--   end
--   if ( gBlind.last_direction == "open") then
--     C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = gBlind.level_closed}, "NOTIFY", true)
--     gBlind.target_level = gBlind.level_closed
--     API_MANAGER:add_request_by_template("fclose")
--     API_MANAGER:send_next_requests()
--   end
-- end

-------------------------
--- ReceivedAsync
-------------------------

function updateDeviceMode(value)
  local old_mode = Properties[PROPERTY_SHELLY_MODE]
  local new_mode = PROPERTY_SHELLY_MODE_ON_OFF
  if (value == true) then
    new_mode = PROPERTY_SHELLY_MODE_POSITION
  end

  if (new_mode ~= old_mode) then
    if (new_mode == PROPERTY_SHELLY_MODE_ON_OFF) then
      set_drive_in_on_off_mode()
    elseif (new_mode == PROPERTY_SHELLY_MODE_POSITION) then
      set_drive_in_position_mode()
    end
    UpdateProperty(PROPERTY_SHELLY_MODE, new_mode)
  end
end

function done_callback_status(transfer, responses, errCode, errMsg)
  if (errCode == 0) then
    local lresp = responses[#responses]
    LOGGER:debug("done_callback_status(): transfer succeeded (", #responses, " responses received), last response code: " .. lresp.code)
    
    -- se mi interessa il corpo della risposta uso lresp.body
    LOGGER:debug("done_callback_status(): body of last response:", lresp.body)
    local tResponse = parseStatus(C4:JsonDecode(lresp.body))
      
    current_pos = tResponse["last_response_current_pos"]
    state =  tResponse["last_response_state"]
    positioning = tResponse["last_response_positioning"]
    last_direction = tResponse["last_response_last_direction"]
    updateDeviceMode(positioning)

    if (positioning) then
      update_slider_ui(state, current_pos)
    else
      update_on_off_ui(state)
    end
  else
    if (errCode == -1) then
      LOGGER:debug("done_callback_status(): transfer was aborted")
    else
      LOGGER:debug("done_callback_status(): transfer failed with error", errCode,":",errMsg, "(", #responses,"responses completed)")  
    end
  end
     
end

function update_on_off_ui(state)
  LOGGER:debug("state, target_state:", state, gBlind.target_state)
  if state == "stop" then 
    if gBlind.target_state == "OPENED" then -- parte da C4
      C4:SendToProxy (BLIND_PROXY, 'STOPPED', {LEVEL = 100}, "NOTIFY", true) 
      LOGGER:debug("DICO CHE SIAMO APERTI")
      --C4:SendToProxy (BLIND_PROXY, 'Up', {}, "NOTIFY", true) 
      
    elseif gBlind.target_state == "CLOSED" then 
      C4:SendToProxy (BLIND_PROXY, 'STOPPED', {LEVEL = 0}, "NOTIFY", true)
      LOGGER:debug("DICO CHE SIAMO CHIUSI")
      --C4:SendToProxy (BLIND_PROXY, 'Down', {}, "NOTIFY", true) 
      
    elseif gBlind.target_state == "STOPPED" then 
      C4:SendToProxy (BLIND_PROXY, 'STOPPED', {LEVEL = 50}, "NOTIFY", true)
      LOGGER:debug("DICO CHE SIAMO A META'")
      --C4:SendToProxy (BLIND_PROXY, 'Stop', {}, "NOTIFY", true) 
      
    end
    gBlind.target_state = "" -- target state raggiunto e quindi vuoto in attesa di nuovo valore
  else
    LOGGER:debug("DICO CHE MI STO MUOVENDO A META'")
    if gBlind.target_state == ""  then -- se ricevo movimento dallo shelly
      if (state == "open") then
        C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = 100}, "NOTIFY", true)
        gBlind.target_state="OPENED"
      elseif (state == "close")	then
        C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = 0}, "NOTIFY", true)			
        gBlind.target_state="CLOSED"
      else
        C4:SendToProxy (BLIND_PROXY, 'STOPPED', {LEVEL = 50}, "NOTIFY", true)
      end
    end
  end
end


function update_slider_ui(state, current_pos)
  LOGGER:debug("state, current_pos, gBlind", state, current_pos, gBlind)
  if state == "stop" then
    --if (gBlind.target_state == "LEVEL_TARGET") then -- level_target != da "" se la rishiesta parte da C4
    --if (gBlind.target_state ~= "") then  
      if (current_pos >= gBlind.level_open) then
        C4:SendToProxy (BLIND_PROXY, 'STOPPED', {LEVEL =  gBlind.level_open}, "NOTIFY", true) 
      elseif (current_pos <= gBlind.level_closed) then
        C4:SendToProxy (BLIND_PROXY, 'STOPPED', {LEVEL =  gBlind.level_closed}, "NOTIFY", true) 
      else
        C4:SendToProxy (BLIND_PROXY, 'STOPPED', {LEVEL =  current_pos}, "NOTIFY", true) 
      end
      gBlind.target_state = ""
    --end
  else
     
    if (gBlind.target_state == "") then -- se la richiesta parte da shelly
      C4:SendToProxy (BLIND_PROXY, 'MOVING', {LEVEL_TARGET = current_pos}, "NOTIFY", true)
      gBlind.target_state = "LEVEL_TARGET"
    end
  end
end

-------------------------
--- Managing Protocol and Requests
-------------------------

function parseStatus(tRes)
  
  if (tRes) then
                                        
    gBlind.last_response_state = tRes["state"]
    gBlind.last_response_power = tRes["power"]
    gBlind.last_response_is_valid = tRes["is_valid"]
    gBlind.last_response_safety_switch = tRes["safety_switch"]
    gBlind.last_response_overtemperature = tRes["overtemperature"]
    gBlind.last_response_stop_reason = tRes["stop_reason"]
    gBlind.last_response_last_direction = tRes["last_direction"]
    gBlind.last_response_current_pos = Utility.tonumber_loc(tRes["current_pos"])
    gBlind.last_response_calibrating = tRes["calibrating"]
    gBlind.last_response_positioning = tRes["positioning"]
    
    updateStatusVariables()
  else
    gBlind.last_response_state = nil
    gBlind.last_response_power = nil
    gBlind.last_response_is_valid = nil
    gBlind.last_response_safety_switch = nil
    gBlind.last_response_overtemperature = nil
    gBlind.last_response_stop_reason = nil
    gBlind.last_response_last_direction = nil
    gBlind.last_response_current_pos = nil
    gBlind.last_response_calibrating = nil
    gBlind.last_response_positioning = nil
  end
	return gBlind
end

-------------------------
--- VARIABLES 
-------------------------

function updateStatusVariables()
    SetVariable(VARIABLE_NAME_STATE,            gBlind.last_response_state)
    SetVariable(VARIABLE_NAME_POWER,            gBlind.last_response_power)
    SetVariable(VARIABLE_NAME_IS_VALID,         gBlind.last_response_is_valid)
    SetVariable(VARIABLE_NAME_SAFETY_SWITCH,    gBlind.last_response_safety_switch)
    SetVariable(VARIABLE_NAME_OVERTEMPERATURE,  gBlind.last_response_overtemperature)
    SetVariable(VARIABLE_NAME_STOP_REASON,      gBlind.last_response_stop_reason)
    SetVariable(VARIABLE_NAME_LAST_DIRECTION,   gBlind.last_response_last_direction)
    SetVariable(VARIABLE_NAME_CURRENT_POS,      gBlind.last_response_current_pos)
    SetVariable(VARIABLE_NAME_CALIBRATING,      gBlind.last_response_calibrating)
    SetVariable(VARIABLE_NAME_POSITIONING,      gBlind.last_response_positioning)
end
-------------------------
--- TIMER for POLLING
-------------------------

function updateTimerForPolling(new_interval)
	if (TIMER_FOR_POLLING == nil) then
	  LOGGER:debug("updateTimerForPolling NEW")
	  TIMER_FOR_POLLING = TimerManager:new(TIMER_INTERVAL_FOR_POLLING, TIMER_INTERVAL_SCALE_FOR_POLLING, onTimerExpireForPolling, true)
	else
	  LOGGER:debug("updateTimerForPolling UPDATE")
	  TIMER_FOR_POLLING:stop()
	  TIMER_FOR_POLLING = TimerManager:new(TIMER_INTERVAL_FOR_POLLING, TIMER_INTERVAL_SCALE_FOR_POLLING, onTimerExpireForPolling, true)
	end
	LOGGER:debug("updateTimerForPolling START")
	TIMER_FOR_POLLING:start()
	LOGGER:debug("TIMER_FOR_POLLING:", TIMER_FOR_POLLING)
end

function destroyTimerForPolling()
	TIMER_FOR_POLLING:stop()
end

function onTimerExpireForPolling()
  LOGGER:debug("onTimerExpireForPolling()")
	
  API_MANAGER:add_request_by_template("status")
  API_MANAGER:send_next_requests()
end


-------------------------------
-- Other functions
-------------------------------

function set_drive_in_on_off_mode() 
  gBlind.level_discrete = false
  gBlind.has_level = true
  update_ui()
end

function set_drive_in_position_mode()
  gBlind.level_discrete = true
  gBlind.has_level = true
  update_ui()
end

function is_drive_in_on_off_mode()
  return gBlind.level_discrete == false and gBlind.has_level == false
end

function update_ui()
  LOGGER:debug("update_ui()")
  C4:SendToProxy (BLIND_PROXY, "SET_CAN_STOP", 
      { CAN_STOP = gBlind.can_stop },
    "NOTIFY", true)
  C4:SendToProxy (BLIND_PROXY, "SET_HAS_LEVEL", 
      { HAS_LEVEL=gBlind.has_level,
      LEVEL_OPEN=gBlind.level_open,
      LEVEL_CLOSED=gBlind.level_closed,
      --LEVEL_SECONDARY_CLOSED=gBlind.level_closed_secondary,
      LEVEL_UNKNOWN=gBlind.level_unknown,
      LEVEL_DISCRETE_CONTROL=gBlind.level_discrete,
      HAS_LEVEL_SECONDARY_CLOSED=gBlind.hasSecondaryClosed}, 
    "NOTIFY", true)
end
