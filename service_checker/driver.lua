local TimerManager = require "SKC4.TimerManager"
ApiRestManager = require 'SKC4.ApiRestManager'
require("SKC4.DriverCore");
LOGGER = SKC4_LOGGER


-----------------------------------------------------
-- GLOBALS
-----------------------------------------------------
DRIVER_NAME = "service_checker"
API_MANAGER = {}
PROPERTY_NAME_URL_TO_CHECK = "URL To Check"
PROPERTY_NAME_EXPECTED_RESPONSE_CODE = "Expected Response Code"
PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE = "Last Received Response Code"
PROPERTY_NAME_LAST_UPDATE = "Last Update"
PROPERTY_NAME_POLLING_INTERVAL = "Polling Interval"
PROPERTY_NAME_CURRENT_SERVICE_STATUS = "Current Service Status"
PROPERTY_NAME_USERNAME = "Username"
PROPERTY_NAME_PASSWORD = "Password"

PROPERTY_NAME_RESPONSE_TIMEOUT = "Response Timeout"
PROPERTY_NAME_CONNECT_TIMEOUT = "Connect Timeout"
PROPERTY_NAME_LAST_RECEIVED_RESPONSE_MESSAGE = "Last Received Data"

ON_PROPERTY_NAME_URL_TO_CHECK = "Url_To_Check"
ON_PROPERTY_NAME_EXPECTED_RESPONSE_CODE = "Expected_Response_Code"
ON_PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE = "Last_Received_Response_Code"
ON_PROPERTY_NAME_POLLING_INTERVAL = "Polling_Interval"

VARIABLE_NAME_LAST_RESPONSE_CODE = "LAST_RESPONSE_CODE"
VARIABLE_NAME_LAST_RESPONSE_DATA = "LAST_RESPONSE_DATA"
VARIABLE_NAME_CURRENT_SERVICE_STATUS = "CURRENT_SERVICE_STATUS"
POLLING_TIMER = nil
-----------------------------------------------------
-- INITIALIZATION
-----------------------------------------------------

function ON_DRIVER_INIT.create_api_manager()
  API_MANAGER = ApiRestManager:new()
end

function ON_DRIVER_LATE_INIT.init_variables()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_variables()")
  AddVariable(VARIABLE_NAME_LAST_RESPONSE_CODE, Properties[PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE], "NUMBER", true, false)
  AddVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, "", "STRING", true, false)
  AddVariable(VARIABLE_NAME_CURRENT_SERVICE_STATUS, "UNKNOWN", "STRING", true, false)
end

function ON_DRIVER_LATE_INIT.init_api_manager()
  LOGGER:debug("ON_DRIVER_LATE_INIT.init_api_manager()")
  API_MANAGER:set_base_url("")
  API_MANAGER:set_max_concurrent_requests(5)
  API_MANAGER:disable_delayed_requests()
  API_MANAGER:enable_ssl_verify_host()
  API_MANAGER:enable_ssl_verify_peer()
  API_MANAGER:disable_fail_on_error()

end

function ON_DRIVER_DESTROYED.destroy_timer()
  if (POLLING_TIMER) then
    POLLING_TIMER:stop()
  end
end
-----------------------------------------------------
-- VARIABLES
-----------------------------------------------------

-----------------------------------------------------
-- PROPERTIES
-----------------------------------------------------

ON_PROPERTY_CHANGED[PROPERTY_NAME_POLLING_INTERVAL] = function (minutes)
  
  if POLLING_TIMER then
    POLLING_TIMER:stop()
  end
  if minutes then  
    POLLING_TIMER = TimerManager:new(tonumber(minutes), "MINUTES", on_polling_timer_expire, false)
    TIMER_DISABLE_LOG_INTERVAL:start()
  end
end

ON_PROPERTY_CHANGED[PROPERTY_NAME_RESPONSE_TIMEOUT] = function(value)
  if (value) then
    API_MANAGER:set_timeout(tonumber(value))
  end
end

ON_PROPERTY_CHANGED[PROPERTY_NAME_CONNECT_TIMEOUT] = function(value)
  if (value) then
    API_MANAGER:set_connect_timeout(tonumber(value))
  end
end

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

-----------------------------------------------------
-- COMMANDS
-----------------------------------------------------
  
function ACTIONS.CheckServiceStatusNow(params)
  LOGGER:debug("COMMANDS.PerformGetRequest")
  local headers = {}
  local params = {}
  local data = {}
  
  send_check_service_status_request()
end

-----------------------------------------------------
-- CONDITIONAL
-----------------------------------------------------
function CONDITIONALS.SERVICE_STATUS(params)
  LOGGER:debug("CONDITIONALS.SERVICE_STATUS:", params)
  local logic = params["LOGIC"]
  local strValue = params["VALUE"]
  local current_status = Properties[PROPERTY_NAME_CURRENT_SERVICE_STATUS] 
  local ret_value = false

  if (logic == "EQUAL") then
    if (strValue == current_status ) then
      ret_value = true
    else 
      ret_value = false
    end
  else
    if (strValue ~= current_value) then
      ret_value = true
    else 
      ret_value = false
    end
  end
  LOGGER:debug("CONDITIONALS.SERVICE_STATUS returns:", ret_value)
  return ret_value
end

-----------------------------------------------------
-- TIMER
-----------------------------------------------------

function on_polling_timer_expire()
  send_check_service_status_request()
end

-----------------------------------------------------
-- COMMON
-----------------------------------------------------

function send_check_service_status_request()
  local url = Properties[PROPERTY_NAME_URL_TO_CHECK]
  LOGGER:debug("send_check_service_status_request():", url)
  if (url) then
    API_MANAGER:add_request("get", url, nil, nil, nil, check_service_status_respose_handler)
    API_MANAGER:send_next_requests()
    UpdateProperty(PROPERTY_NAME_CURRENT_SERVICE_STATUS, "Checking...")
    UpdateProperty(PROPERTY_NAME_LAST_UPDATE, os.date("Checking started at %x %X"))
  end
end

function update_service_status()
  local expected_value = Properties[PROPERTY_NAME_EXPECTED_RESPONSE_CODE]
  local current_status = Properties[PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE]

  if (expected_value == current_status) then
    UpdateProperty(PROPERTY_NAME_CURRENT_SERVICE_STATUS, "OK")
    SetVariable(VARIABLE_NAME_CURRENT_SERVICE_STATUS, "OK")
  else
    UpdateProperty(PROPERTY_NAME_CURRENT_SERVICE_STATUS, "KO")
    SetVariable(VARIABLE_NAME_CURRENT_SERVICE_STATUS, "KO")
  end
end

function check_service_status_respose_handler(transfer, responses, errCode, errMsg)
  
  if (errCode == 0) then
    local lresp = responses[#responses]
    UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE, lresp.code)
    SetVariable(VARIABLE_NAME_LAST_RESPONSE_CODE, lresp.code)
    
    
    LOGGER:debug("check_service_status_respose_handler(): transfer succeeded (", #responses, " responses received), last response code: " .. lresp.code)
    for hdr,val in pairs(lresp.headers) do
      LOGGER:debug("check_service_status_respose_handler(): ", hdr, " = ",val)
    end
    LOGGER:debug("check_service_status_respose_handler(): body of last response:", lresp.body)
    UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_MESSAGE, remove_and_elipse_string(lresp.body))
    SetVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, lresp.body)
   else
    if (errCode == -1) then
      LOGGER:debug("check_service_status_respose_handler(): transfer was aborted")
      UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_MESSAGE, "Transfer was aborted")
      SetVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, "Transfer was aborted")
    else
      LOGGER:debug("check_service_status_respose_handler(): transfer failed with error", errCode,":",errMsg, "(", #responses,"responses completed)")
      UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_MESSAGE, tostring(errMsg))
      SetVariable(VARIABLE_NAME_LAST_RESPONSE_DATA, tostring(errMsg))
    end
    UpdateProperty(PROPERTY_NAME_LAST_RECEIVED_RESPONSE_CODE, errCode)
    SetVariable(VARIABLE_NAME_LAST_RESPONSE_CODE, errCode)
   end

   update_service_status()
   UpdateProperty(PROPERTY_NAME_LAST_UPDATE, os.date("%x %X"))
     
end

function remove_and_elipse_string(text, length)
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


