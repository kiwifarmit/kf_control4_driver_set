local TimerManager = require "SKC4.TimerManager"
require 'SKC4.LicenseManager'

-- load data and all functions to handle them
-- require("shelly")
JSON = require 'json'

-----------------------------------------------------
-- GLOBALS
-----------------------------------------------------
PROXY_ID_BINDING = 1


TIMER_FOR_POLLING = nil
TIMER_INTERVAL_FOR_POLLING = 10
TIMER_INTERVAL_SCALE_FOR_POLLING = "SECONDS"

PROPRETY_SHELLY_IP = "Shelly IP"
PROPRETY_SHELLY_USER = "Shelly Username (reserved login)"
PROPRETY_SHELLY_PWD = "Shelly Password (reserved login)"
PROPRETY_LAST_UPDATE_AT = "Last Update At"
PROPERTY_POLLING_INTERVAL = "Polling Interval"
PROPERTY_TEMP_1_VALUE = "Shelly Temperature 1 Value"
PROPERTY_TEMP_2_VALUE = "Shelly Temperature 2 Value"
PROPERTY_TEMP_3_VALUE = "Shelly Temperature 3 Value"
tTempPropeties = {}
tTempPropeties[1] = PROPERTY_TEMP_1_VALUE
tTempPropeties[2] = PROPERTY_TEMP_2_VALUE
tTempPropeties[3] = PROPERTY_TEMP_3_VALUE
PROPERTY_TEMP_UNIT = "Shelly Temperature Unit"
PROPERTY_DEBUG = "Debug"

--EX_CMD = {}
--PRX_CMD = {}
--NOTIFY = {}
--DEV_MSG = {}
--LUA_ACTION = {}
endPointCalls = {}
--controlledRelNr = {}
--RelayIsOn = {}
tTemp = {}


--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "shelly_1_temperatures.c4z", "DRIVERCENTRAL")
-- LICENSE_MGR:setParamValue("ProductId", XXX, "HOUSELOGIX")
-- LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX")
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")
LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo ("version"), "HOUSELOGIX")
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

-- variabile per controllo relays
--C4:AddVariable("RelaysIsOn","","BOOL",false)

-----------------------------------------------------
-- AUTO INITIALIZATION
-----------------------------------------------------
require("SKC4.DriverCore");
LOGGER = SKC4_LOGGER



function ON_DRIVER_INIT.init_variables()
  LOGGER:debug("ON_DRIVER_INIT.init_variables()")
  setup_variables_and_connection()
end

function setup_variables_and_connection()
  TEMPERATURE_1_STR = "Temperature_1"
  TEMPERATURE_2_STR = "Temperature_2"
  TEMPERATURE_3_STR = "Temperature_3"

  tVariables = {}
  tVariables[1] = TEMPERATURE_1_STR
  tVariables[2] = TEMPERATURE_2_STR
  tVariables[3] = TEMPERATURE_3_STR

  C4:DeleteVariable(TEMPERATURE_1_STR)
  C4:AddVariable(TEMPERATURE_1_STR, "0", "NUMBER",true)
  C4:DeleteVariable(TEMPERATURE_2_STR)
  C4:AddVariable(TEMPERATURE_2_STR, "0", "NUMBER",true)
  C4:DeleteVariable(TEMPERATURE_3_STR)
  C4:AddVariable(TEMPERATURE_3_STR, "0", "NUMBER",true)

  TEMPERATURE_1_BIND = 1001
  TEMPERATURE_2_BIND = 1002
  TEMPERATURE_3_BIND = 1003

  tBind = {}
  tBind[1] = TEMPERATURE_1_BIND
  tBind[2] = TEMPERATURE_2_BIND
  tBind[3] = TEMPERATURE_3_BIND

  C4:AddDynamicBinding(TEMPERATURE_1_BIND, "CONTROL", true, TEMPERATURE_1_STR, "THERMOMETER", false, false)
  C4:AddDynamicBinding(TEMPERATURE_2_BIND, "CONTROL", true, TEMPERATURE_2_STR, "THERMOMETER", false, false)
  C4:AddDynamicBinding(TEMPERATURE_3_BIND, "CONTROL", true, TEMPERATURE_3_STR, "THERMOMETER", false, false)

end


function ON_DRIVER_LATEINIT.init_timer_for_polling()
  LOGGER:debug("ON_DRIVER_LATEINIT.init_timer_for_polling()")
  updateTimerForPolling(TIMER_FOR_POLLING)  
end



function ON_DRIVER_DESTROYED.destroyed_timer_for_polling()
  LOGGER:debug("ON_DRIVER_DESTROY.destroy_timer_for_polling()")
  destroyTimerForPolling()
end

-----------------------------------------------------
-- VARIABLES
-----------------------------------------------------

-----------------------------------------------------
-- PROPERTIES
-----------------------------------------------------
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

-----------------------------------------------------
-- PROXY COMMANDS
-----------------------------------------------------

function ReceivedFromProxy(idBinding, sCommand, tParams)

  LOGGER:debug("ReceivedFromProxy: ",idBinding, sCommand, tParams)

  LICENSE_MGR:ReceivedFromProxy(idBinding, sCommand, tParams)
end


--
-------------------------------------------------------
-- TIMER
-----------------------------------------------------

function onTimerExpireForPolling()
  LOGGER:debug("onTimerExpireForPolling()")
  -- read shelly status
  genUrl = CreateUrl()
  link = genUrl..'/status'
  print ("URL", link)

  tickedId = C4:urlGet(link)
  endPointCalls[tickedId] = "GET_tempStatus"
end



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


function ReceivedAsync(ticketId, sData, responseCode, tHeaders)
	--LOGGER:debug(">ReceivedAsync",ticketId, sData, responseCode, tHeaders )
  if LICENSE_MGR:isAbleToWork() then
    parseGetResult(sData)
  else
    LOGGER:debug("License Not Active or in trial period")
  end
end

function parseGetResult(sData)
  if sData ~= nil then
    response = JSON:decode(sData)
    if  endPointCalls[tickedId] == "GET_tempStatus" then
      LOGGER:debug("GET_tempStatus: ", sData)
      parseTemp(response["ext_temperature"])
      update_connections()
      update_variables()
      update_t_properties()
    end
  end
end

function parseTemp(data)
  if data then
    for id, temp in pairs(data) do
      print (id, temp)
      tTemp[id] = temp
   end
  end
end

function update_variables()
  for id, temp in pairs(tTemp) do
    t = temp[selectUnit()]
    if t ~= "" and  t ~= nil then
      C4:SetVariable(tVariables[tonumber(id+1)], t)
    end
  end
end

function update_connections()
  for id, temp in pairs(tTemp) do
    t = temp[selectUnit()]
    d = tBind[tonumber(id+1)]
    if t ~= "" and  t ~= nil then    
      C4:SendToProxy(tBind[tonumber(id+1)],"TEMPERATURE_CHANGED",  {TEMPERATURE = t}, "NOTIFY")
    end
  end
end

function update_t_properties()
  for id, temp in pairs(tTemp) do
    t = temp[selectUnit()]
    if t ~= "" and  t ~= nil then  
      UpdateProperty(tTempPropeties[tonumber(id+1)], t)
      end
  end
end


function selectUnit()
  local unit = Properties[PROPERTY_TEMP_UNIT]
  print("unit:", unit)
  if unit == "C" then return "tC" 
  elseif unit == "F" then return "tF" 
  else return "" end
end

--function  SendtoProxyShellyStatus(relayNr)
--  LOGGER:debug("SendtoProxyShellyStatus: ", relayNr)
--  local C4RelStatus = ""
--  if RelayIsOn[relayNr] then
--    C4RelStatus = "CLOSED"
--    C4:SetVariable("RelaysIsOn","1")
--  else
--    C4RelStatus = "OPENED"
--    C4:SetVariable("RelaysIsOn","0") 
--  end
--  
--  C4:SendToProxy(relayNr, C4RelStatus,  "", "NOTIFY")
--  UpdateProperty(PROPERTY_RELAY_STATUS, C4RelStatus)
--end

--function relaysStatus()
--  for i, item in pairs(RelayIsOn) do
--    LOGGER:debug("Relay "..i.." is On: "..tostring(RelayIsOn[i]))
--  end
--end

function CreateUrl()
  IP = Properties[PROPRETY_SHELLY_IP]
  local genUrl = ""
  if Properties[PROPRETY_SHELLY_USER] ~= "" and Properties[PROPRETY_SHELLY_PWD] ~= "" then
    local User = Properties[PROPRETY_SHELLY_USER]
    local Pwd = Properties[PROPRETY_SHELLY_PWD]
    genUrl = 'http://'..User..':'..Pwd..'@'..IP
  else
    genUrl = 'http://'..IP
  end
  return genUrl
end

function OnVariableChanged(strName)
  LOGGER:debug("OnVariableChanged: ".. strName.." new Value is: ",Variables["RelaysIsOn"] )
  if strName == "RelaysIsOn" then
    if Variables["RelaysIsOn"] == "1" then
      PRX_CMD.CLOSE(1)
    else
      PRX_CMD.OPEN(1)
    end
  end
end


function updateLastTimeAtProperties(current_time)
  local date_string=string.format("%02d/%02d/%04d %02d:%02d:%02d", 
  current_time.month, current_time.day, current_time.year,
  current_time.hour, current_time.min, current_time.sec)
  UpdateProperty(PROPRETY_LAST_UPDATE_AT, date_string)
end



-----------------------------------------------------
-- TEST
-----------------------------------------------------


