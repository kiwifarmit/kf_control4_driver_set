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
PROPERTY_RELAY_STATUS = {}
PROPERTY_RELAY_STATUS[1] = "Shelly Relay O1 Status"
PROPERTY_RELAY_STATUS[2] = "Shelly Relay O2 Status"
PROPERTY_DEBUG = "Debug"

EX_CMD = {}
PRX_CMD = {}
NOTIFY = {}
DEV_MSG = {}
LUA_ACTION = {}
endPointCalls = {}
controlledRelNr = {}
RelayIsOn = {}


--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "shelly_25.c4z", "DRIVERCENTRAL")
LICENSE_MGR:setParamValue("ProductId", XXX, "HOUSELOGIX")
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX")
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
C4:AddVariable("O1_RelaysIsOn","","BOOL",false)
C4:AddVariable("O2_RelaysIsOn","","BOOL",false)

-- Energy Meter Var
for ch=1,2 do
  C4:AddVariable("Power_CH"..ch, 0, "NUMBER",true) -- Watt
  C4:AddVariable("isValid_CH"..ch, 0, "BOOL",true)  -- bool
  C4:AddVariable("TotalPower_CH"..ch, 0, "NUMBER",true) -- Wh
end

-----------------------------------------------------
-- AUTO INITIALIZATION
-----------------------------------------------------
require("SKC4.DriverCore");
LOGGER = SKC4_LOGGER



function ON_DRIVER_INIT.init_variables()
  LOGGER:debug("ON_DRIVER_INIT.init_variables()")
end

function ON_DRIVER_INIT.init_licence_mgr()
  LOGGER:debug("ON_DRIVER_INIT.init_licence_mgr()")
  LICENSE_MGR:OnDriverInit()
end

function ON_DRIVER_LATEINIT.init_timer_for_polling()
  LOGGER:debug("ON_DRIVER_LATEINIT.init_timer_for_polling()")
  updateTimerForPolling(TIMER_FOR_POLLING)  
end

function ON_DRIVER_LATEINIT.init_licence_mgr()
  LOGGER:debug("ON_DRIVER_LATEINIT.init_licence_mgr()")
  LICENSE_MGR:OnDriverLateInit()
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



--function ReceivedFromProxy(idBinding, sCommand, tParams)
--end


-----------------------------------------------------
-- PROXY COMMANDS
-----------------------------------------------------

function ReceivedFromProxy(idBinding, sCommand, tParams)

  LOGGER:debug("ReceivedFromProxy: ",idBinding, sCommand, tParams)
  if (sCommand ~= nil) then
    if(tParams == nil)		-- initial table variable if nil
      then tParams = {}
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
    --spengo il timer
    TIMER_FOR_POLLING:stop()
    if LICENSE_MGR:isAbleToWork() then
      LOGGER:debug("Open Shelly Relay = ",idBinding)
      --RelayStatus[idBinding] = 0
      RelayCMD(idBinding,"off")
      C4:SendToProxy(idBinding, "OPENED",  "", "NOTIFY")
    else
      LOGGER:debug("License Not Active or in trial period")
    end
    --ri-avvio il timer
    TIMER_FOR_POLLING:start()
  end

  -- chiusura relay
  function PRX_CMD.CLOSE(idBinding, tParams)
    --spengo il timer
    TIMER_FOR_POLLING:stop()
    if LICENSE_MGR:isAbleToWork() then
      LOGGER:debug("Close Shelly Relay =", idBinding)
      RelayCMD(idBinding,"on")
      C4:SendToProxy(idBinding, "CLOSED",  "", "NOTIFY")
    else
      LOGGER:debug("License Not Active or in trial period")
    end
    --ri-avvio il timer
    TIMER_FOR_POLLING:start()
  end

  -- toggle
  function PRX_CMD.TOGGLE(idBinding, tParams)
    if LICENSE_MGR:isAbleToWork() then
      RelayCMD(idBinding,"toggle")
    else
      LOGGER:debug("License Not Active or in trial period")
    end
  end

  -- trigger FIXME
  function PRX_CMD.TRIGGER(idBinding, tParams)
    -- trigger
    Ttime = tonumber(tParams['TIME'])
    PRX_CMD.CLOSE(idBinding, tParams)
        C4:SetTimer(Ttime, function(timer)
          PRX_CMD.OPEN(idBinding, tParams)
        end)
  end

  function PRX_CMD.GET_STATE(idBinding, tParams)
    if LICENSE_MGR:isAbleToWork() then
      if RelayIsOn[idBinding] == false then
        C4:SendToProxy(idBinding, "OPENED",  "", "NOTIFY")
      else
        C4:SendToProxy(idBinding, "CLOSED",  "", "NOTIFY")
      end
    else
      LOGGER:debug("License Not Active or in trial period")
    end
  end

-----------------------------------------------------
-- TIMER
-----------------------------------------------------

function onTimerExpireForPolling()
  LOGGER:debug("onTimerExpireForPolling()")
  -- read shelly status
  genUrl = CreateUrl()
  link = genUrl..'/status'
  tickedId = C4:urlGet(link)
  endPointCalls[tickedId] = "GET_relayStatus"
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

-----------------------------------------------------
-- COMMON
-----------------------------------------------------
function RelayCMD(RelNr,RelOnOff)
  genUrl = CreateUrl()
  local ShellyRelNr = RelNr - 1
  link = genUrl..'/relay/'..ShellyRelNr..'?turn='..RelOnOff
  LOGGER:debug(">RelayCMD: ",link )
  tickedId = C4:urlGet(link)
  endPointCalls[tickedId] = "GET_relayControl"
  controlledRelNr[tickedId] = RelNr
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
    if  endPointCalls[tickedId] == "GET_relayControl" then
      LOGGER:debug("GET_relayControl: ", sData)
      --Utility.tprint(response)
      RelayIsOn[controlledRelNr[tickedId]] = response["ison"]
      SendtoProxyShellyStatus(controlledRelNr[tickedId])
    end
    if  endPointCalls[tickedId] == "GET_relayStatus" then
      -- LOGGER:debug("GET_relayStatus: ", sData)
      --Utility.tprint(response)
      for i, item in pairs(response["relays"]) do
        LOGGER:debug(response["relays"][i]["ison"])
        RelayIsOn[i] = response["relays"][i]["ison"]
        SendtoProxyShellyStatus(i)
      end
      -- update energy meter status
      for i, item in pairs(response["meters"]) do
        ShellyUpdateMeterStatus(item,i)
      end
    end
  end
end

function  SendtoProxyShellyStatus(relayNr)
  LOGGER:debug("SendtoProxyShellyStatus: ", relayNr)
  local C4RelStatus = ""
  if RelayIsOn[relayNr] then
    C4RelStatus = "CLOSED"
    C4:SetVariable("O"..relayNr.."_RelaysIsOn","1")
  else
    C4RelStatus = "OPENED"
    C4:SetVariable("O"..relayNr.."_RelaysIsOn","0") 
  end
  
  C4:SendToProxy(relayNr, C4RelStatus,  "", "NOTIFY")
  UpdateProperty(PROPERTY_RELAY_STATUS[relayNr], C4RelStatus)
end

function relaysStatus()
  for i, item in pairs(RelayIsOn) do
    LOGGER:debug("Relay "..i.." is On: "..tostring(RelayIsOn[i]))
  end
end

function ShellyUpdateMeterStatus(itemTable,ch)
  Utility.tprint(itemTable)
  int_power = math.floor(itemTable.power)
  C4:SetVariable("Power_CH"..ch, int_power) -- Watt
  if itemTable.is_valid == true then
    C4:SetVariable("isValid_CH"..ch, "1")  -- bool
  else
    C4:SetVariable("isValid_CH"..ch, "0")  -- bool
  end
  C4:SetVariable("TotalPower_CH"..ch, itemTable.total) -- Wh
end


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
  if strName == "O1_RelaysIsOn" then
    if Variables["O1_RelaysIsOn"] == "1" then
      PRX_CMD.CLOSE(1)
    else
      PRX_CMD.OPEN(1)
    end
  end
  if strName == "O2_RelaysIsOn" then
    if Variables["O2_RelaysIsOn"] == "1" then
      PRX_CMD.CLOSE(2)
    else
      PRX_CMD.OPEN(2)
    end
  end
end


function updateLastTimeAtPropertie(current_time)
  local date_string=string.format("%02d/%02d/%04d %02d:%02d:%02d", 
  current_time.month, current_time.day, current_time.year,
  current_time.hour, current_time.min, current_time.sec)
  UpdateProperty(PROPRETY_LAST_UPDATE_AT, date_string)
end



-----------------------------------------------------
-- TEST
-----------------------------------------------------


