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
if (SKC4_ON_DRIVER_LATE_INIT == nil) then
  SKC4_ON_DRIVER_LATE_INIT = {}
end
SKC4_ON_DRIVER_LATEINIT = SKC4_ON_DRIVER_LATE_INIT -- alias per retrocompatibilita'
if (SKC4_ON_DRIVER_DESTROYED == nil) then
  SKC4_ON_DRIVER_DESTROYED = {}
end
if (SKC4_ON_PROPERTY_CHANGED == nil) then
  SKC4_ON_PROPERTY_CHANGED = {}
end
if (SKC4_COMMANDS == nil) then
  SKC4_COMMANDS = {}
end
if (SKC4_ACTIONS == nil) then
  SKC4_ACTIONS = {}
end
if (SKC4_PROXY_COMMANDS == nil) then
  SKC4_PROXY_COMMANDS = {}
end
if (SKC4_NOTIFICATIONS == nil) then
  SKC4_NOTIFICATIONS = {}
end
if (SKC4_ON_VARIABLE_CHANGED == nil) then
  SKC4_ON_VARIABLE_CHANGED = {}
end
if (SKC4_CONDITIONALS == nil) then
  SKC4_CONDITIONALS = {}
end



SKC4_PROPERTY_DISABLE_LOG_INTERVAL="Disable Log Interval"
SKC4_PROPERTY_LOG_MODE="Log Mode"
SKC4_PROPERTY_LOG_LEVEL="Log Level"


if (ON_DRIVER_EARLY_INIT == nil) then
  ON_DRIVER_EARLY_INIT = {}
end
if (ON_DRIVER_INIT == nil) then
  ON_DRIVER_INIT = {}
end
if (ON_DRIVER_LATE_INIT == nil) then
  ON_DRIVER_LATE_INIT = {}
end
ON_DRIVER_LATEINIT = ON_DRIVER_LATE_INIT -- alias per retrocompatibilita'

if (ON_DRIVER_DESTROYED == nil) then
  ON_DRIVER_DESTROYED = {}
end
if (ON_PROPERTY_CHANGED == nil) then
  ON_PROPERTY_CHANGED = {}
end
if (ACTIONS == nil) then
  ACTIONS = {}
end
if (COMMANDS == nil) then
  COMMANDS = {}
end
if (PROXY_COMMANDS == nil) then
  PROXY_COMMANDS = {}
end
if (NOTIFICATIONS == nil) then
  NOTIFICATIONS = {}
end
if (ON_VARIABLE_CHANGED == nil) then
  ON_VARIABLE_CHANGED = {}
end
if (VARIABLE_ID_MAP == nil) then
  VARIABLE_ID_MAP = C4:PersistGetValue("VARIABLE_ID_MAP") or {}
end
if (CONDITIONALS == nil) then
  CONDITIONALS = {}
end

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
  local status, err_tbl = Utility.callAllFunctionsInTable(ON_DRIVER_EARLY_INIT)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on ON_DRIVER_EARLY_INIT: ", err_tbl)
    end
  end
  
  status, err_tbl = Utility.callAllFunctionsInTable(SKC4_ON_DRIVER_INIT)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on SKC4_ON_DRIVER_INIT: ", err_tbl)
    end
  end
	status, err_tbl = Utility.callAllFunctionsInTable(ON_DRIVER_INIT)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on ON_DRIVER_INIT: ", err_tbl)
    end
  end
  
  -- Enable license manager if it's required
  if (LICENSE_MGR) then
    LICENSE_MGR:OnDriverInit()
  end
  
end

function OnDriverLateInit()
  SKC4_LOGGER:debug("INIT_CODE: OnDriverLateInit()")
  --avviato al ri-avvio del driver per avere un ping (il math random evita che tutti i driver partano contemporaneamente)
  math.randomseed(os.time())
  local rand_wait = math.random (3000, 7000)
  SKC4_LOGGER:debug("INIT_CODE: OnDriverLateInit() Random -> ", rand_wait)
  TIMER_ON_DRIVER_LATE_INIT_FIX = TimerManager:new(rand_wait, "MILLISECONDS", OnDriverLateInit_callback, false)
  TIMER_ON_DRIVER_LATE_INIT_FIX:start()
end

function OnDriverLateInit_callback()
	SKC4_LOGGER:debug("INIT_CODE: OnDriverLateInit_callback()")
  -- Fire OnPropertyChanged to set the initial Headers and other Property
	-- global sets, they'll change if Property is changed.
  for k,v in pairs(Properties) do
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("INIT_CODE: Calling OnPropertyChanged -",k,":",v)
    end
		local status, err = pcall(OnPropertyChanged, k)
    if (not status) then    
      if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
        SKC4_LOGGER:debug("LUA_ERROR: ", err)
      end
    end
	end

	gInitializingDriver = false

  -- Enable license manager if it's required
  if (LICENSE_MGR) then
    LICENSE_MGR:OnDriverLateInit()
  end

  local status, err_tbl = Utility.callAllFunctionsInTable(SKC4_ON_DRIVER_LATE_INIT)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on SKC4_ON_DRIVER_LATE_INIT: ", err_tbl)
    end
  end
  local status, err_tbl = Utility.callAllFunctionsInTable(ON_DRIVER_LATE_INIT)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on ON_DRIVER_LATE_INIT: ", err_tbl)
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
  local status, err_tbl = Utility.callAllFunctionsInTable(ON_DRIVER_DESTROYED)
  if (not status) then    
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:debug("LUA_ERROR on ON_DRIVER_DESTROYED: ", err_tbl)
    end
  end
end 

----------------------------------------------------
-- Properties
----------------------------------------------------
function OnPropertyChanged(sProperty)
	local propertyValue = Properties[sProperty]

	if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
		SKC4_LOGGER:info("OnPropertyChanged(", sProperty,") changed to:", propertyValue)
  end
  if (LICENSE_MGR) then
    LICENSE_MGR:OnPropertyChanged(sProperty) --, propertyValue)
  end

	-- Remove any spaces (trim the property)
  local sanitizedProperty = string.gsub(sProperty, "[%%/,%-()#@%[%]]+", "")
  local trimmedProperty = string.gsub(sanitizedProperty, "%s", "_")
	local status = true
	local err = ""

	if (SKC4_ON_PROPERTY_CHANGED[sProperty] ~= nil and type(SKC4_ON_PROPERTY_CHANGED[sProperty]) == "function") then
		status, err = pcall(SKC4_ON_PROPERTY_CHANGED[sProperty], propertyValue)
	elseif (SKC4_ON_PROPERTY_CHANGED[trimmedProperty] ~= nil and type(SKC4_ON_PROPERTY_CHANGED[trimmedProperty]) == "function") then
		status, err = pcall(SKC4_ON_PROPERTY_CHANGED[trimmedProperty], propertyValue)
	end

  if (ON_PROPERTY_CHANGED[sProperty] ~= nil and type(ON_PROPERTY_CHANGED[sProperty]) == "function") then
		status, err = pcall(ON_PROPERTY_CHANGED[sProperty], propertyValue)
	elseif (ON_PROPERTY_CHANGED[trimmedProperty] ~= nil and type(ON_PROPERTY_CHANGED[trimmedProperty]) == "function") then
		status, err = pcall(ON_PROPERTY_CHANGED[trimmedProperty], propertyValue)
	end

  if (not status) then
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:error("LUA_ERROR: ", err)
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
    SKC4_LOGGER:info("ExecuteCommand(", strCommand, ") with params",tParams)
  end

  -- Remove any spaces (trim the property)
  local trimmedProperty = string.gsub(strCommand, " ", "_")
  local status = true
  local err = ""

  if (strCommand == "LUA_ACTION") then
    local action = tParams["ACTION"]
    local trimmedAction = string.gsub(action, " ", "_")
    if (SKC4_ACTIONS[action] ~= nil and type(SKC4_ACTIONS[action]) == "function") then
      status, err = pcall(SKC4_ACTIONS[action], tParams)
    elseif (SKC4_COMMANDS[trimmedAction] ~= nil and type(SKC4_COMMANDS[trimmedAction]) == "function") then
      status, err = pcall(SKC4_COMMANDS[trimmedAction], tParams)
    end

    if (ACTIONS[action] ~= nil and type(ACTIONS[action]) == "function") then
      status, err = pcall(ACTIONS[action], tParams)
    elseif (COMMANDS[trimmedAction] ~= nil and type(COMMANDS[trimmedAction]) == "function") then
      status, err = pcall(COMMANDS[trimmedAction], tParams)
    end
  else
    if (SKC4_COMMANDS[strCommand] ~= nil and type(SKC4_COMMANDS[strCommand]) == "function") then
      status, err = pcall(SKC4_COMMANDS[strCommand], tParams)
    elseif (SKC4_COMMANDS[trimmedProperty] ~= nil and type(SKC4_COMMANDS[trimmedProperty]) == "function") then
      status, err = pcall(SKC4_COMMANDS[trimmedProperty], tParams)
    end

    if (COMMANDS[strCommand] ~= nil and type(COMMANDS[strCommand]) == "function") then
      status, err = pcall(COMMANDS[strCommand], tParams)
    elseif (COMMANDS[trimmedProperty] ~= nil and type(COMMANDS[trimmedProperty]) == "function") then
      status, err = pcall(COMMANDS[trimmedProperty], tParams)
    end
  end
  if (not status) then
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:error("LUA_ERROR: ", err)
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
      SKC4_LOGGER:info("ReceivedFromProxy(", strCommand, ") with params ",tParams, idBinding)
    end

    if (LICENSE_MGR) then
      LICENSE_MGR:ReceivedFromProxy(idBinding, strCommand, tParams)
    end
    
    -- Remove any spaces (trim the property)
    local trimmedProperty = string.gsub(strCommand, " ", "_")
    local status = true
    local err = ""
  
    if (SKC4_PROXY_COMMANDS[strCommand] ~= nil and type(SKC4_PROXY_COMMANDS[strCommand]) == "function") then
      status, err = pcall(SKC4_PROXY_COMMANDS[strCommand], tParams, idBinding)
    elseif (SKC4_PROXY_COMMANDS[trimmedProperty] ~= nil and type(SKC4_PROXY_COMMANDS[trimmedProperty]) == "function") then
      status, err = pcall(SKC4_PROXY_COMMANDS[trimmedProperty], tParams, idBinding)
    end

    if (PROXY_COMMANDS[strCommand] ~= nil and type(PROXY_COMMANDS[strCommand]) == "function") then
      status, err = pcall(PROXY_COMMANDS[strCommand], tParams, idBinding)
    elseif (PROXY_COMMANDS[trimmedProperty] ~= nil and type(PROXY_COMMANDS[trimmedProperty]) == "function") then
      status, err = pcall(PROXY_COMMANDS[trimmedProperty], tParams, idBinding)
    end
  
    if (not status) then
      if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
        SKC4_LOGGER:error("LUA_ERROR: ", err)
      end
    end

	end
end

----------------------------------------------------
-- Notifications
----------------------------------------------------

----------------------------------------------------
-- Varialbes
----------------------------------------------------

function OnVariableChanged(strName)
	if (strName ~= nil) then
		if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:info("OnVariableChanged(", strName, ")")
    end

    -- Remove any spaces (trim the property)
    local trimmedName = string.gsub(strName, " ", "_")
    local status = true
    local err = ""
  
    if (SKC4_ON_VARIABLE_CHANGED[strName] ~= nil and type(SKC4_ON_VARIABLE_CHANGED[strName]) == "function") then
      status, err = pcall(SKC4_ON_VARIABLE_CHANGED[strName], tParams)
    elseif (SKC4_ON_VARIABLE_CHANGED[trimmedName] ~= nil and type(SKC4_ON_VARIABLE_CHANGED[trimmedName]) == "function") then
      status, err = pcall(SKC4_ON_VARIABLE_CHANGED[trimmedName], tParams)
    end

    if (ON_VARIABLE_CHANGED[strName] ~= nil and type(ON_VARIABLE_CHANGED[strName]) == "function") then
      status, err = pcall(ON_VARIABLE_CHANGED[strName], tParams)
    elseif (ON_VARIABLE_CHANGED[trimmedName] ~= nil and type(ON_VARIABLE_CHANGED[trimmedName]) == "function") then
      status, err = pcall(ON_VARIABLE_CHANGED[trimmedName], tParams)
    end
  
    if (not status) then
      if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
        SKC4_LOGGER:error("LUA_ERROR: ", err)
      end
    end

	end
end

function AddVariable(strName, strValue, strVarType, bReadOnly, bHidden)
  local is_ok, variable_id = C4:AddVariable(strName, strValue, strVarType, bReadOnly, bHidden)
  if (is_ok) then
    --VARIABLE_ID_MAP[strName]=variable_id
    SKC4_LOGGER:debug("Variable", strName, "has been created")
  else
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      if (Variables[strName]) then
        SKC4_LOGGER:error("Variable", strName, "already exists")
      else
        SKC4_LOGGER:error("Unable to create", strName, "variable")
      end
    end
  end

  --if (is_ok) then
  --  VARIABLE_ID_MAP[strName]=variable_id
  --  SKC4_LOGGER:debug("Variable", strName, "has been created")
  --else
  --  if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
  --    if (VARIABLE_ID_MAP[strName]) then
  --      SKC4_LOGGER:error("Variable", strName, "already exists")
  --    else
  --      SKC4_LOGGER:error("Unable to create", strName, "variable")
  --    end
  --  end
  --end
end

function GetVariable(strName)
  if (strName  ~= nil) then
    return Variables[strName]
  else
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:error("No variable name!")
    end
  end
    
  -- local variable_id = VARIABLE_ID_MAP[strName]
  -- if (variable_id  ~= nil) then
  --   local device_id = C4:GetDeviceID();
  --   return C4:GetVariable(device_id, variable_id)
  -- else
  --   if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
  --     SKC4_LOGGER:error("Variable", strName, "not found")
  --   end
  -- end
end

function SetVariable(strName, strValue)
  --local variable_id = VARIABLE_ID_MAP[strName]
  if (strName  ~= nil) then
    return C4:SetVariable(strName, strValue)
  else
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:error("No variable name!")
    end
  end

  -- local variable_id = VARIABLE_ID_MAP[strName]
  -- if (variable_id  ~= nil) then
  --   return C4:SetVariable(variable_id, strValue)
  -- else
  --   if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
  --     SKC4_LOGGER:error("Variable", strName, "not found")
  --   end
  -- end
end

function DeleteVariable(strName)
  if (strName  ~= nil) then
    return C4:DeleteVariable(strName)
  else
    if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:error("No variable name!")
    end
  end

  -- local variable_id = VARIABLE_ID_MAP[strName]
  -- if (variable_id  ~= nil) then
  --   VARIABLE_ID_MAP[strName] = nil
  --   return C4:DeleteVariable(variable_id)
  -- else
  --   if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
  --     SKC4_LOGGER:error("Variable", strName, "not found")
  --   end
  -- end
end


----------------------------------------------------
-- Conditionals
----------------------------------------------------

function TestCondition(strName, tParams)
	if (strName ~= nil) then
		if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
      SKC4_LOGGER:info("TestCondition()\name:",strName,"\ntParams", tParams)
    end

    -- Remove any spaces (trim the property)
    local trimmedName = string.gsub(strName, " ", "_")
    local status = true
    local retVal = ""
  
    if (SKC4_CONDITIONALS[strName] ~= nil and type(SKC4_CONDITIONALS[strName]) == "function") then
      status, retVal = pcall(SKC4_CONDITIONALS[strName], tParams)
    elseif (SKC4_CONDITIONALS[trimmedName] ~= nil and type(SKC4_CONDITIONALS[trimmedName]) == "function") then
      status, retVal = pcall(SKC4_CONDITIONALS[trimmedName], tParams)
    end

    if (CONDITIONALS[strName] ~= nil and type(CONDITIONALS[strName]) == "function") then
      status, retVal = pcall(CONDITIONALS[strName], tParams)
    elseif (CONDITIONALS[trimmedName] ~= nil and type(CONDITIONALS[trimmedName]) == "function") then
      status, retVal = pcall(CONDITIONALS[trimmedName], tParams)
    end
  
    if (not status) then
      if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
        SKC4_LOGGER:error("LUA_ERROR: ", err)
      end
    else
      return retVal
    end

	end
end


----------------------------------------------------
-- Driver info
----------------------------------------------------

function SKC4_ON_DRIVER_LATE_INIT.init_driver_version()
  local current_version = C4:GetDriverConfigInfo("version")
  UpdateProperty("Driver Version", current_version)
  SKC4_LOGGER:info("Updating Driver Version prop to", current_version)
end
----------------------------------------------------
-- Logging
----------------------------------------------------
function SKC4_ON_DRIVER_DESTROYED.destroy_timer_disable_log()
  if TIMER_DISABLE_LOG_INTERVAL then
    TIMER_DISABLE_LOG_INTERVAL:stop()
  end
end

function SKC4_ON_PROPERTY_CHANGED.Log_Mode(sValue)
  SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.Log_Mode: sValue = ",sValue)
  if sValue == "Print" then -- Only print
    SKC4_LOGGER:disableC4FileLogging()
  else -- otherwise
    SKC4_LOGGER:enableC4FileLogging()
  end
end

function SKC4_ON_PROPERTY_CHANGED.Log_Level(sValue)
  
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

  SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.Log_Level: sValue = ",sValue)
end

function SKC4_ON_PROPERTY_CHANGED.Disable_Log_Interval(sValue)
  SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.Disable_Log_Interval: sValue = ",sValue)

  minutes = getDisableLogIntervalValueInMinutes(sValue)
  updateTimerDisableLogInterval(minutes)
end

function onTimerDisableLogIntervalTimerExpire()
  SKC4_LOGGER:debug("onTimerDisableLogIntervalTimerExpire(): disable log now")
  
  SKC4_LOGGER:disableLogging()
  UpdateProperty(SKC4_PROPERTY_LOG_LEVEL,"Off")
end

function updateTimerDisableLogInterval(minutes)
  if TIMER_DISABLE_LOG_INTERVAL then
    TIMER_DISABLE_LOG_INTERVAL:stop()
  end
  
  if minutes then
    TIMER_DISABLE_LOG_INTERVAL = TimerManager:new(minutes, "MINUTES", onTimerDisableLogIntervalTimerExpire, false)
    TIMER_DISABLE_LOG_INTERVAL:start()
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

