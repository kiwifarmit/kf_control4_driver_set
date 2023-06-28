require("SKC4.Utility")
local TimerManager = require "SKC4.TimerManager"
SKC4_LOGGER = require("SKC4.Logger");
-- SKC4_LOGGER:enableDebugLevel()


----------------------------------------------------
-- Global tables for functions
----------------------------------------------------
if (SKC4_ON_DRIVER_EARLY_INIT == nil) then
  SKC4_ON_DRIVER_EARLY_INIT = {}
end
if (SKC4_ON_DRIVER_INIT == nil) then
  SKC4_ON_DRIVER_INIT = {}
end
if (SKC4_ON_DRIVER_LATEINIT == nil) then
  SKC4_ON_DRIVER_LATEINIT = {}
end
if (SKC4_ON_DRIVER_DESTROYED == nil) then
  SKC4_ON_DRIVER_DESTROYED = {}
end
if (SKC4_ON_PROPERTY_CHANGED == nil) then
  SKC4_ON_PROPERTY_CHANGED = {}
end
if (SKC4_COMMANDS == nil) then
  SKC4_COMMANDS = {}
end
if (SKC4_PROXY_COMMANDS == nil) then
  SKC4_PROXY_COMMANDS = {}
end
if (SKC4_NOTIFICATIONS == nil) then
  SKC4_NOTIFICATIONS = {}
end

SKC4_PROPERTY_DISABLE_LOG_INTERVAL="Disable Log Interval"
SKC4_PROPERTY_LOG_MODE="Log Mode"
SKC4_PROPERTY_LOG_LEVEL="Log Level"

----------------------------------------------------
-- Inits
----------------------------------------------------
function OnDriverInit()
	gInitializingDriver = true
	SKC4_LOGGER:debug("INIT_CODE: OnDriverInit()")

  -- Call all SKC4_ON_DRIVER_EARLY_INIT functions.
  local status, err_tbl = Utility.callAllFunctionsInTable(SKC4_ON_DRIVER_EARLY_INIT)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on SKC4_ON_DRIVER_EARLY_INIT: ", err_tbl)
    end
  end
  
  status, err_tbl = Utility.callAllFunctionsInTable(SKC4_ON_DRIVER_INIT)

  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on SKC4_ON_DRIVER_INIT: ", err_tbl)
    end
  end
	
  -- status, err_tbl = Utility.callAllFunctionsInTable(SKC4_ON_DRIVER_INIT)
  -- if (not status) then    
  --   if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
  --     SKC4_LOGGER:debug("LUA_ERROR on SKC4_ON_DRIVER_INIT: ", err_tbl)
  --   end
  -- end

  -- Enable license manager if it's required
  if (LICENSE_MGR) then
    LICENSE_MGR:OnDriverInit()
  end


	-- Fire OnPropertyChanged to set the initial Headers and other Property
	-- global sets, they'll change if Property is changed.
	for k,v in pairs(Properties) do
		SKC4_LOGGER:debug("INIT_CODE: Calling OnPropertyChanged - " .. k .. ": " .. v)
		local status, err = pcall(OnPropertyChanged, k)
    if (not status) then    
      if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
        SKC4_LOGGER:debug("LUA_ERROR: " .. err)
      end
    end
	end

	gInitializingDriver = false
end

function OnDriverLateInit()
	SKC4_LOGGER:debug("INIT_CODE: OnDriverLateInit()")
  
  -- Enable license manager if it's required
  if (LICENSE_MGR) then
    LICENSE_MGR:OnDriverLateInit()
  end

  local status, err_tbl = Utility.callAllFunctionsInTable(SKC4_ON_DRIVER_LATEINIT)

  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on SKC4_ON_DRIVER_LATEINIT: ", err_tbl)
    end
  end
  
end

function OnDriverDestroyed()
	C4:ErrorLog("INIT_CODE: OnDriverDestroyed()")
  
  local status, err_tbl = Utility.callAllFunctionsInTable(SKC4_ON_DRIVER_DESTROYED)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on SKC4_ON_DRIVER_DESTROYED: ", err_tbl)
    end
  end
end 

----------------------------------------------------
-- Properties
----------------------------------------------------
function OnPropertyChanged(sProperty)
	local propertyValue = Properties[sProperty]

	if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
		SKC4_LOGGER:info("OnPropertyChanged(" .. sProperty .. ") changed to: " .. Properties[sProperty])
  end
  if (LICENSE_MGR) then
    LICENSE_MGR:OnPropertyChanged(sProperty) --, propertyValue)
  end

	-- Remove any spaces (trim the property)
	local trimmedProperty = string.gsub(sProperty, " ", "_")
	local status = true
	local err = ""

	if (SKC4_ON_PROPERTY_CHANGED[sProperty] ~= nil and type(SKC4_ON_PROPERTY_CHANGED[sProperty]) == "function") then
		status, err = pcall(SKC4_ON_PROPERTY_CHANGED[sProperty], propertyValue)
	elseif (SKC4_ON_PROPERTY_CHANGED[trimmedProperty] ~= nil and type(SKC4_ON_PROPERTY_CHANGED[trimmedProperty]) == "function") then
		status, err = pcall(SKC4_ON_PROPERTY_CHANGED[trimmedProperty], propertyValue)
	end

  if (not status) then
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:error("LUA_ERROR: " .. err)
    end
	end
end


function UpdateProperty(propertyName, propertyValue)
	if (Properties[propertyName] ~= nil) then
		C4:UpdateProperty(propertyName, propertyValue)
	end
end


----------------------------------------------------
-- Commands
----------------------------------------------------
function ExecuteCommand(strCommand, tParams)
  
  if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
    SKC4_LOGGER:info("ExecuteCommand(" .. strCommand .. ") with params ",tParams)
  end

  -- Remove any spaces (trim the property)
  local trimmedProperty = string.gsub(strCommand, " ", "_")
  local status = true
  local err = ""

  if (SKC4_COMMANDS[strCommand] ~= nil and type(SKC4_COMMANDS[strCommand]) == "function") then
    status, err = pcall(SKC4_COMMANDS[strCommand], tParams)
  elseif (SKC4_COMMANDS[trimmedProperty] ~= nil and type(SKC4_COMMANDS[trimmedProperty]) == "function") then
    status, err = pcall(SKC4_COMMANDS[trimmedProperty], tParams)
  end

  if (not status) then
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:error("LUA_ERROR: " .. err)
    end
	end
end

function ReceivedFromProxy(idBinding, strCommand, tParams)
	if (strCommand ~= nil) then
		-- initial table variable if nil
		if (tParams == nil) then
			tParams = {}
    end
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:info("ReceivedFromProxy(" .. strCommand .. ") with params ",tParams)
    end

    if (LICENSE_MGR) then
      LICENSE_MGR:ReceivedFromProxy(idBinding, strCommand, tParams)
    end
    
    -- Remove any spaces (trim the property)
    local trimmedProperty = string.gsub(strCommand, " ", "_")
    local status = true
    local err = ""
  
    if (SKC4_PROXY_COMMANDS[strCommand] ~= nil and type(SKC4_PROXY_COMMANDS[strCommand]) == "function") then
      status, err = pcall(SKC4_PROXY_COMMANDS[strCommand], tParams)
    elseif (SKC4_PROXY_COMMANDS[trimmedProperty] ~= nil and type(SKC4_PROXY_COMMANDS[trimmedProperty]) == "function") then
      status, err = pcall(SKC4_PROXY_COMMANDS[trimmedProperty], tParams)
    end
  
    if (not status) then
      if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
        SKC4_LOGGER:error("LUA_ERROR: " .. err)
      end
    end

	end
end


----------------------------------------------------
-- Notifications
----------------------------------------------------




----------------------------------------------------
-- Logging
----------------------------------------------------

function SKC4_ON_PROPERTY_CHANGED.Log_Mode(sValue)
  SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.Log_Mode: sValue = ",sValue)
  if sValue == "Print" then -- Only print
    SKC4_LOGGER:disableC4FileLogging()
  else -- otherwise
    SKC4_LOGGER:enableC4FileLogging()
  end
end

function SKC4_ON_PROPERTY_CHANGED.Log_Level(sValue)
  SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.Log_Level: sValue = ",sValue)
  start_timer = true
  if sValue == "0 - Alert" then 
    SKC4_LOGGER:enableFatalLevel()
  elseif sValue == "1 - Error" then 
    SKC4_LOGGER:enableErrorLevel()
  elseif sValue == "2 - Warning" then 
    SKC4_LOGGER:enableWarningLevel()
  elseif sValue == "3 - Info" then 
    SKC4_LOGGER:enableInfoLevel()
  elseif sValue == "4 - Trace" then 
    SKC4_LOGGER:enableDebugLevel()
  elseif sValue == "5 - Debug" then 
    SKC4_LOGGER:enableDebugLevel()
  else
    SKC4_LOGGER:disableLogging()
    start_timer = false
  end

  if start_timer then
    minutes = getDisableLogIntervalValueInMinutes()
    updateTimerDisableLogInterval(minutes)
  end
end

function SKC4_ON_PROPERTY_CHANGED.Disable_Log_Interval(sValue)
  SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.Disable_Log_Interval: sValue = ",sValue)

  minutes = getDisableLogIntervalValueInMinutes(sValue)
  updateTimerDisableLogInterval(minutes)
end

function onTimerDisableLogIntervalTimerExpire()
  SKC4_LOGGER:debug("onTimerDisableLogIntervalTimerExpire(): disable log now")
  UpdateProperty(SKC4_PROPERTY_LOG_LEVEL,"Off")
end

function updateTimerDisableLogInterval(minutes)
  if minutes then
    if TIMER_DISABLE_LOG_INTERVAL then
      TIMER_DISABLE_LOG_INTERVAL:stop()
    end
    TIMER_DISABLE_LOG_INTERVAL = TimerManager:new(minutes, "MINUTES", onTimerDisableLogIntervalTimerExpire, false)
    TIMER_DISABLE_LOG_INTERVAL:start()
  else
    if TIMER_DISABLE_LOG_INTERVAL then
      TIMER_DISABLE_LOG_INTERVAL:stop()
    end
  end
end

function getDisableLogIntervalValueInMinutes(label)
  sValue = label or Properties[SKC4_PROPERTY_DISABLE_LOG_INTERVAL]
  minutes = 0
  if ( sValue ~= nil) then
    if sValue == "15 minutes" then
      minutes = 15
    elseif sValue == "30 minutes" then
      minutes = 30
    elseif sValue == "1 hour" then
      minutes = 60
    elseif sValue == "6 hours" then
      minutes = 360
    elseif sValue == "24 hours" then
      minutes = 1440
    end
  end
  return minutes
end

