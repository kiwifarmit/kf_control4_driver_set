local TimerManager = require "SKC4.TimerManager"
require 'SKC4.LicenseManager'

-- load data and all functions to handle them
-- require("shelly")
JSON = require 'json'

-----------------------------------------------------
-- GLOBALS
-----------------------------------------------------
PROXY_ID_BINDING = 1

PROPRETY_LAST_UPDATE_AT = "Last Update At"
PROPRETY_CONNECTION_URL = "Shelly REPORT url (read only)"
PROPERTY_DEBUG = "Debug"
PROPERTY_PORT = "Server Port"

--EX_CMD = {}
--PRX_CMD = {}
NOTIFY = {}
--DEV_MSG = {}
LUA_ACTION = {}

--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- FIXME Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "shelly_flood.c4z", "DRIVERCENTRAL")
-- LICENSE_MGR:setParamValue("ProductId", XXX, "HOUSELOGIX")
-- LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX")
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")
LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo ("version"), "HOUSELOGIX")
LICENSE_MGR:setParamValue("Trial", LICENSE_MGR.TRIAL_NOT_STARTED, "HOUSELOGIX")
--- end license

-----------------------------------------------------
-- AUTO INITIALIZATION
-----------------------------------------------------
require("SKC4.DriverCore");
LOGGER = SKC4_LOGGER

function ON_DRIVER_LATEINIT.init_variables()
  LOGGER:debug("ON_DRIVER_LATEINIT.init_variables()")
  setup_variables_and_connection()
end

function ON_DRIVER_LATEINIT.enable_internal_server()
  LOGGER:debug("ON_DRIVER_LATEINIT.enable_internal_server")
  local value = tonumber(Properties[PROPERTY_PORT])
  if value == nil then
    LOGGER:debug("ON_PROPERTY_CHANGED.Server_Port MUST be a Number")
  else
    LOGGER:debug("ON_PROPERTY_CHANGED.Server_Port new port will be", value)
    DestroyServer() -- uccide eventuali server precedenti
    CreateServer(value)
  end
end

function ON_DRIVER_DESTROYED.destroyed_server()  -- Kill all servers in the system...
  C4:DestroyServer()
end

-----------------------------------------------------
-- VARIABLES
-----------------------------------------------------
function setup_variables_and_connection()
  TEMPERATURE_STR = "Temperature"
  FLOOD_STR = "Is_Flood"
  BATV_STR = "Battery Volt"

  --C4:DeleteVariable(TEMPERATURE_STR) -- così cancelliamo le programmazioni!!!
  C4:AddVariable(TEMPERATURE_STR, "0", "NUMBER",true)
  C4:AddVariable(FLOOD_STR, "0", "BOOL",true)
  C4:AddVariable(BATV_STR, "3", "NUMBER",true)

  TEMPERATURE_BIND = 1001
  FLOOD_BIND = 1002
  
  C4:AddDynamicBinding(TEMPERATURE_BIND, "CONTROL", true, TEMPERATURE_STR, "THERMOMETER", false, false)
  C4:AddDynamicBinding(FLOOD_BIND, "CONTROL", true, FLOOD_STR, "CONTACT_SENSOR", false, false)
  -- assumo che all'avvio non ci sia una condizione di allagamento
  prevFlood = false
end

function DelVariableHidden()
  for VariableName, VariableValue in pairs(Variables) do     
      LOGGER:debug("deleting: ".. VariableName) 
      C4:DeleteVariable(VariableName)
  end
  LOGGER:debug("All variable has been deleted!")
end
-----------------------------------------------------
-- PROPERTIES
-----------------------------------------------------

function ON_PROPERTY_CHANGED.Server_Port(sValue)
  LOGGER:debug("ON_PROPERTY_CHANGED.Server_Port: sValue = ",sValue)
  local value = tonumber(sValue)
  if value == nil then
    LOGGER:debug("ON_PROPERTY_CHANGED.Server_Port MUST be a Number")
  else
    DestroyServer() -- uccide eventuali server precedenti
    CreateServer(value)
  end
end

function ON_PROPERTY_CHANGED.Shelly_REPORT_url_read_only(sValue)
  LOGGER:debug("ON_PROPERTY_CHANGED.Shelly_REPORT_url_read_only")
  local port = Properties[PROPERTY_PORT] 
  popolateConnectionString(port)
end

-----------------------------------------------------
-- SERVER STUFF
-----------------------------------------------------
function CreateServer(HTTPPORT)
  LOGGER:debug("Creating Server HTTP on Port", HTTPPORT)
  C4:CreateServer(HTTPPORT)
  LOGGER:debug("Created Server HTTP on Port", HTTPPORT)
  popolateConnectionString(HTTPPORT)
end

function popolateConnectionString(port)
  local controllerIP = C4:GetControllerNetworkAddress()
  local connectionString = "http://"..controllerIP..":"..port
  UpdateProperty(PROPRETY_CONNECTION_URL, connectionString)

end

function UnURLEscapeHTTP(strURLEscaped)
  temp = string.gsub(strURLEscaped, " ", "%%20")
  return temp
end

function DestroyServer() -- distruggo sul cambio di properties
  C4:DestroyServer()
end

-- ParseStatus parses requests received on port 8081...
function ParseStatus()
  -- Parse for events sent from web client, set variable and fire event...
  --LOGGER:debug("ParseStatus gRecvBuf: "..gRecvBuf)
  local _, _, url = string.find(gRecvBuf, "GET /(.*) HTTP")
  url = url or ""
  gCmd = url

  if (string.len(url) > 0) then
    LOGGER:debug("GET URL (gCmd): [" .. url .. "]")
    local params = strSplit('&', url)
    if table.getn(params) > 2 then

      local tTemp = strSplit('=', params[1])
      local tFlood = strSplit('=', params[2])
      local tBatV = strSplit('=', params[3])

      -- sono tutte stringhe
      local temp = tTemp[2]
      local flood = tFlood[2]
      local batV = tBatV[2]

      LOGGER:debug("temp: [" .. temp .. "], flood: [".. flood .. "], batV: [".. batV .. "]")
      
      -- aggiorno gli stati
      updateStatus(temp, flood, batV)
      --LOGGER:debug("TYPE: temp: [" .. type(temp) .. "], flood: [".. type(flood) .. "], batV: [".. type(batV) .. "]")
      --C4:FireEvent("Command Received")
    end

  else
    LOGGER:debug("No Command Received.")
    gCmd = "None"
  end
end  

function updateStatus(temp, flood, batV)

  C4:SetVariable(TEMPERATURE_STR, temp)
     C4:SetVariable(FLOOD_STR, flood)
     C4:SetVariable(BATV_STR, batV)

    --C4:SendToProxy(HUMIDITY_BIND,"NUMBER_CHANGED",  {NUMBER = hum}, "NOTIFY")
    C4:SendToProxy(TEMPERATURE_BIND,"TEMPERATURE_CHANGED",  {TEMPERATURE = temp}, "NOTIFY")
    
    if flood == "0" then
      if prevFlood == true then
        C4:SendToProxy(FLOOD_BIND,"OPENED", "", "NOTIFY")
        prevFlood = false
      end
    else
      C4:SendToProxy(FLOOD_BIND,"CLOSED", "", "NOTIFY")
      prevFlood = true
    end
end

-----------------------------------------------------
 --------------- SERVER SOCKET (feedback) --------------
-----------------------------------------------------
function OnServerConnectionStatusChanged(nHandle, nPort, strStatus)
  LOGGER:debug("OnServerConnectionStatusChanged[" .. nHandle .. " / " .. nPort .. "]: " .. strStatus)
end



function OnServerDataIn(nHandle, strData)
  --dbg("OnServerDataIn: " .. strData)
  --LOGGER:debug("OnServerDataIn: ",nHandle, strData)
  gRecvBuf = strData
  local ret, err = pcall(ParseStatus)
  if (ret ~= true) then
    local e = "Error Parsing return status: " .. err
    LOGGER:debug(e)
    C4:ErrorLog(e)
  end
  gRecvBuf = ""

  -- TODO: If / was received, return full HTML message... Otherwise, return simple HTML response...
  local msg = '<html><head></head><body>Connection Successful.<P/><P/>Command: ' .. gCmd .. '</body></html>'
  local headers = "HTTP/1.1 200 OK\r\nContent-Length: " .. msg:len() .. "\r\nContent-Type: text/html\r\n\r\n"
  --dbg("RETURNING MESSAGE: " .. headers .. msg)
  C4:ServerSend(nHandle,  headers .. msg) 
  C4:ServerCloseClient(nHandle)
end


-----------------------------------------------------
-- PROXY COMMANDS
-----------------------------------------------------

function ReceivedFromProxy(idBinding, sCommand, tParams)
  LOGGER:debug("ReceivedFromProxy: ",idBinding, sCommand, tParams)
  LICENSE_MGR:ReceivedFromProxy(idBinding, sCommand, tParams)
end


-----------------------------------------------------
-- TIMER
-----------------------------------------------------

-----------------------------------------------------
-- COMMON
-----------------------------------------------------

function ReceivedAsync(ticketId, sData, responseCode, tHeaders)
	--LOGGER:debug(">ReceivedAsync",ticketId, sData, responseCode, tHeaders )
  if LICENSE_MGR:isAbleToWork() then
    parseGetResult(sData)
  else
    LOGGER:debug("License Not Active or in trial period")
  end
end

function strSplit(delim,str)
  local t = {}

  for substr in string.gmatch(str, "[^".. delim.. "]*") do
      if substr ~= nil and string.len(substr) > 0 then
          table.insert(t,substr)
      end
  end
  return t
end


function OnVariableChanged(strName)
  LOGGER:debug("OnVariableChanged: ".. strName.." new Value is: ",Variables["PlugsIsOn"] )
  if strName == "PlugsIsOn" then
    if Variables["PlugsIsOn"] == "1" then
      PRX_CMD.CLOSE(1)
    else
      PRX_CMD.OPEN(1)
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


