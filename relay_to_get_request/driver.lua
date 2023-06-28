local TimerManager = require "SKC4.TimerManager"
ApiRestManager = require 'SKC4.ApiRestManager'
LicenseManager = require 'SKC4.LicenseManager'
require("SKC4.DriverCore");
LOGGER = SKC4_LOGGER

-----------------------------------------------------
-- GLOBALS
-----------------------------------------------------
DRIVER_NAME = "relay_to_get_request"
PROXY_BINDING = 1
API_MANAGER = {}

PROPERTY_NAME_USERNAME = "Username"
PROPERTY_NAME_PASSWORD = "Password"
PROPERTY_NAME_LAST_UPDATE = "Last Update"
PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE = "Last Received Response Code"
PROPERTY_NAME_LAST_RECEIVED_RESPONSE_DATA = "Last Received Data"
PROPERTY_NAME_GET_REQUEST_URL_ON_CLOSE  = "GET Request URL on Close"
PROPERTY_NAME_GET_REQUEST_URL_ON_OPEN   = "GET Request URL on Open"
PROPERTY_NAME_CURRENT_RELAY_STATUS      = "Current Relay Status"

VARIABLE_NAME_LAST_RESPONSE_CODE    = "LAST_RESPONSE_CODE"
VARIABLE_NAME_LAST_RESPONSE_DATA    = "LAST_RESPONSE_DATA"
VARIABLE_NAME_CURRENT_RELAY_STATUS  = "CURRENT_RELAY_STATUS"


--- Config License Manager  
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID  
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)  
LICENSE_MGR:setParamValue("FileName", DRIVER_NAME..".c4z", "DRIVERCENTRAL")  
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")  
--- end license  

-----------------------------------------------------
-- INITIALIZATION
-----------------------------------------------------

function ON_DRIVER_INIT.create_api_manager()
  API_MANAGER = ApiRestManager:new()
end

function ON_DRIVER_LATE_INIT.init_variables()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_variables()")
  AddVariable(VARIABLE_NAME_LAST_RESPONSE_CODE, Properties[PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE], "NUMBER", true, false)
  AddVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, Properties[PROPERTY_NAME_LAST_RECEIVED_RESPONSE_DATA], "STRING", true, false)
  AddVariable(VARIABLE_NAME_CURRENT_RELAY_STATUS, Properties[PROPERTY_NAME_CURRENT_RELAY_STATUS], "STRING", true, false)
end

function ON_DRIVER_LATE_INIT.init_api_manager()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_api_manager()")
  API_MANAGER:set_base_url("")
  API_MANAGER:set_max_concurrent_requests(1)
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

ON_PROPERTY_CHANGED[PROPERTY_NAME_USERNAME] = function(value)
  if (value) then
    API_MANAGER:set_username(value)
    API_MANAGER:enable_basic_authentication()
  else
    API_MANAGER:disable_basic_authentication()
  end
end
ON_PROPERTY_CHANGED[PROPERTY_NAME_PASSWORD] = function(value)
  if (value) then
    API_MANAGER:set_password(value)
  end
end


-----------------------------------------------------
-- PROXY COMMANDS
-----------------------------------------------------


function PROXY_COMMANDS.OPEN(idBinding, tParams)
  if LICENSE_MGR:isAbleToWork() or true then
    LOGGER:debug("Relay is opened")
    UpdateProperty(PROPERTY_NAME_CURRENT_RELAY_STATUS, "OPENED")
    SetVariable(VARIABLE_NAME_CURRENT_RELAY_STATUS, "OPENED")
    send_on_open_request()
  else
    LOGGER:debug("License Not Active or in trial period")
  end
end
function PROXY_COMMANDS.CLOSE(idBinding, tParams)
  if LICENSE_MGR:isAbleToWork() or true  then
    LOGGER:debug("Relay is closed")
    UpdateProperty(PROPERTY_NAME_CURRENT_RELAY_STATUS, "CLOSED")
    SetVariable(VARIABLE_NAME_CURRENT_RELAY_STATUS, "CLOSED")
    send_on_close_request()
  else
    LOGGER:debug("License Not Active or in trial period")
  end
end

-----------------------------------------------------
-- COMMANDS
-----------------------------------------------------
  
function ACTIONS.SendOnOpenGetRequest(params)
  LOGGER:debug("COMMANDS.SendOnOpenGetRequest")
  send_on_open_request()
end

function ACTIONS.SendOnCloseGetRequest(params)
  LOGGER:debug("COMMANDS.SendOnCloseGetRequest")
  send_on_close_request()
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

function send_on_open_request()
  local request = Properties[PROPERTY_NAME_GET_REQUEST_URL_ON_OPEN]
  send_a_request(request,response_handler_open)
end

function send_on_close_request()
  local request = Properties[PROPERTY_NAME_GET_REQUEST_URL_ON_CLOSE]
  send_a_request(request,response_handler_close)
end

function send_a_request(url,callback)
  
  LOGGER:debug("send_a_request():", url)
  if (url) then
    API_MANAGER:add_request("get", url, nil, nil, nil, callback)
    API_MANAGER:send_next_requests()
    UpdateProperty(PROPERTY_NAME_LAST_UPDATE, os.date("Request sent at %x %X"))
  else
    LOGGER:error("Ops... no request to send!")
  end
end

function response_handler_open(transfer, responses, errCode, errMsg)
  if (respose_handler(transfer, responses, errCode, errMsg)) then
    C4:SendToProxy(PROXY_BINDING, "OPENED", "", "NOTIFY")
    LOGGER:info("OPENED notification sent.")
  else
    LOGGER:error("Ops... error open on request!")
  end
end
function response_handler_close(transfer, responses, errCode, errMsg)
  if (respose_handler(transfer, responses, errCode, errMsg)) then
    C4:SendToProxy(PROXY_BINDING, "CLOSED", "", "NOTIFY")
    LOGGER:info("CLOSED notification sent.")
  else
    LOGGER:error("Ops... error open on request!")
  end
end
function respose_handler(transfer, responses, errCode, errMsg)
  
  if (errCode == 0) then
    local lresp = responses[#responses]
    UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE, lresp.code)
    SetVariable(VARIABLE_NAME_LAST_RESPONSE_CODE, lresp.code)
    
    
    LOGGER:debug("respose_handler(): transfer succeeded (", #responses, " responses received), last response code: " .. lresp.code)
    for hdr,val in pairs(lresp.headers) do
      LOGGER:debug("respose_handler(): ", hdr, " = ",val)
    end
    --LOGGER:debug("respose_handler(): body of last response:", lresp.body)
    UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_DATA, remove_and_elipse_string(lresp.body))
    SetVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, lresp.body)
   else
    if (errCode == -1) then
      LOGGER:debug("respose_handler(): transfer was aborted")
      UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_DATA, "Transfer was aborted")
      SetVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, "Transfer was aborted")
    else
      LOGGER:debug("respose_handler(): transfer failed with error", errCode,":",errMsg, "(", #responses,"responses completed)")
      UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_DATA, tostring(errMsg))
      SetVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, tostring(errMsg))
    end
    UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE, errCode)
    SetVariable(VARIABLE_NAME_LAST_RESPONSE_CODE, errCode)
   end

   UpdateProperty(PROPERTY_NAME_LAST_UPDATE, os.date("%x %X"))
     
   return (errCode == 0)
end

function remove_and_elipse_string(text, length)
  -- TODO
  if (length == nil) then
    length = 200
  end
  local new_text =  string.sub(text, 1, length) 
  new_text = string.gsub(new_text, "%s+", "")
  return new_text
end
-----------------------------------------------------
-- TEST
-----------------------------------------------------


