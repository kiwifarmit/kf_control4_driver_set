do -- functions
	Helper = {}
	Timer = {}
	--EX_CMDS = {}
	PROXY_CMDS = {}
	ACTIONS = {}
	ON_INIT = {}
	ON_LATE_INIT = {}
	ON_PROPERTY_CHANGED = {}
	UI_REQUEST = {}
	DEVICE = {}
	RELAY_PROXY = 511
	CONTACT_PROXY = 114 --RELAY
end

do -- globals
	if (C4.GetDriverConfigInfo) then
		VERSION = C4:GetDriverConfigInfo ("version")
	else
		VERSION = 'Incompatible with this OS'
	end
	States_fix = { "off", "white", "red", "orange", "yellow", "chartreuse", "green", "spring", "cyan", "azure", "blue", "violet", "magenta", "rose"}
	LED_fix = {"000000", "FFFFFF", "FF0000", "FF8000", "FFFF00", "80FF00", "00FF00", "00FF80", "00FFFF", "0080FF", "0000FF", "8000FF", "FF00FF", "FF0080" }
	gStateIndex = 1
	gCurrentState = "off"
	gPressIsOff = gPressIsOff or false
	gClickable = gClickable or true
	gAllowPressIsOff = gAllowPressIsOff or true
	tInterlock = tInterlock or {}
	C4:AddVariable("STATE", "", "STRING")
	C4:AddDynamicBinding(RELAY_PROXY, "CONTROL", false, "Relay", "RELAY",false, false)        --RELAY
	C4:AddDynamicBinding(CONTACT_PROXY, "CONTROL", false, "Sensor", "CONTACT_SENSOR",false, false)   --RELAY
	STATE = "OFF"
	INVERTED_RELAY = INVERTED_RELAY or false

	StateOff = "off"
	StateOn = "off"
	LedOn = "000000"
	LedOff = "000000"
	
end

PROP = {}
PROP.Action = "Action"
PROP.DriverVersion = "Driver Version"
PROP.PulseLenght = "Pulse Lenght"
PROP.Feedback = "Feedback"
PROP.CurrentState = "Current State"
PROP.DriverInformation = "Driver Information"
PROP.DebugMode = "Debug Mode"
PROP.InvertedRelay = "Inverted Relay"
ACTION = Properties[PROP.Action]
PULSELENGHT = Properties[PROP.PulseLenght]
FEEDBACK = Properties[PROP.Feedback]
INVERTED_RELAY = Properties[PROP.InvertedRelay]


--- Build License Manager object
require 'SKC4.LicenseManager'

--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "Kiwi-button.c4z", "DRIVERCENTRAL")
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



LOGGER:enableDebugLevel()

function dbg (strDebugText, ...)
	--print (os.date ('%x %X : ') .. (strDebugText or ''), ...) 
	if (DEBUGPRINT) then print (os.date ('%x %X : ') .. (strDebugText or ''), ...) end
end


function dbgdump (strDebugText, ...)
	if (DEBUGPRINT) then hexdump (strDebugText or '') print (...) end
end
function OnDriverInit () 
	dbg("OnDriverInit")
	LICENSE_MGR:OnDriverInit()

	Helper.RunFunctions(ON_INIT) 
	-- LICENCE HOOK
end
function ON_INIT.JSON ()
	dbg("ON_INIT.JSON")
	
	
	JSON=(loadstring(json.JSON_LIBRARY_CHUNK))()
end
function ON_INIT.Persistence ()
	dbg("ON_INIT.Persistence")
	if (PersistData == nil) then
		PersistData = {}
	end

	tInterlock = PersistData.Interlock or {}
	PersistData.Interlock = tInterlock

	INVERTED_RELAY = PersistData.INVERTED_RELAY or false
	PersistData.INVERTED_RELAY = INVERTED_RELAY

	ACTION = PersistData.ACTION or ""
	PersistData.ACTION = ACTION

	PULSELENGHT = PersistData.PULSELENGHT or 500
	PersistData.PULSELENGHT = PULSELENGHT

	FEEDBACK = PersistData.FEEDBACK or true
	PersistData.FEEDBACK = FEEDBACK

	StateOff = PersistData.StateOff or "off"
	PersistData.StateOff = StateOff

	StateOn = PersistData.StateOn or "off"
	PersistData.StateOn = StateOn

	StateOn = PersistData.StateOn or "off"
	PersistData.StateOn = StateOn

	LedOn = PersistData.LedOn or "000000"
	PersistData.LedOn = LedOn

	LedOff = PersistData.LedOff or "000000"
	PersistData.LedOff = LedOff
	
end

-- LICENCE HOOK

function OnDriverLateInit () 
	Helper.RunFunctions(ON_LATE_INIT) 
	
	-- LICENCE HOOK
	LICENSE_MGR:OnDriverLateInit() 
end

function ON_LATE_INIT.SetProperties ()
	for k, v in pairs (Properties) do
		if k ~= 'Select Color Now' and k ~= 'Buttons to interlock' then OnPropertyChanged (k) end
	end
	C4:AddDynamicBinding(RELAY_PROXY, "CONTROL", false, "Relay", "RELAY",false, false)        --RELAY
	C4:AddDynamicBinding(CONTACT_PROXY, "CONTROL", true, "Sensor", "CONTACT_SENSOR",false, false)   --RELAY
	STATE = "OFF"
end



function OnVariableChanged(sVariable)
  if (sVariable == "STATE") then
    ON_PROPERTY_CHANGED.SelectColorNow (Variables["STATE"])
  end
end


function OnPropertyChanged(sProperty)
print ("OnPropertyChanged: ",sProperty)
    sProperty = sProperty or ""
	local propertyValue = Properties[sProperty] or ""
	

print ("OnPropertyChanged: ",sProperty,propertyValue)

	
	-- Remove any spaces (trim the property)
	local trimmedProperty = string.gsub(sProperty, " ", "")
	-- if trimmed function exists then execute
  local prop_func = ON_PROPERTY_CHANGED[trimmedProperty] or ""
	--dbg ("OnPropertyChanged(" .. sProperty .. ") changed to: " .. propertyValue)
	--dbg ("trimmedProperty(" .. sProperty .. ") is: " .. trimmedProperty)	
	--dbg ("type(" .. sProperty .. ") is: " .. type(prop_func))
	
	if (type(prop_func) == "function") then
		--print ("trimmed", prop_func)
		prop_func(propertyValue)
	end

	LICENSE_MGR:OnPropertyChanged(sProperty)
end

function ON_PROPERTY_CHANGED.Clickable (value)
	if (value == 'No') then
		gClickable = false
		Helper.DriverInfo ('Button set as non clickable')
		----DEVICE.ShowColorProperties (1)
	elseif (value == 'Yes') then
		gClickable = true
		Helper.DriverInfo ('Button set as clickable')
		----DEVICE.ShowColorProperties (0)
	end
end

function ON_PROPERTY_CHANGED.DriverVersion (value)
	if not Helper.VersionCheck ('2.9.0.0') then
		C4:UpdateProperty ('Driver Version', 'ERROR: This driver requires OS2.9 or higher')
	else
		C4:UpdateProperty ('Driver Version', VERSION)
	end
end

function ON_PROPERTY_CHANGED.DebugMode (value)
	if (value == 'Off') then
		DEBUGPRINT = false
		Timer.Debug = Helper.KillTimer (Timer.Debug)
	elseif (value == 'On') then
		DEBUGPRINT = true
		Timer.Debug = Helper.AddTimer (Timer.Debug, 45, 'MINUTES')
	end
end
function ON_PROPERTY_CHANGED.Action (value)
	--dbg("ON_PROPERTY_CHANGED.Action."..value)
	if (value == 'TOGGLE') then
		C4:SetPropertyAttribs(PROP.PulseLenght, 1)
		ACTION = "TOGGLE"
	elseif (value == 'ON-OFF') then
		C4:SetPropertyAttribs(PROP.PulseLenght, 1)
		ACTION = "ON-OFF"
	elseif (value == 'PULSE') then
		ACTION = "PULSE"
		C4:SetPropertyAttribs(PROP.PulseLenght, 0)
	end
end
function ON_PROPERTY_CHANGED.PulseLenght (value)
	--dbg("ON_PROPERTY_CHANGED.PulseLenght."..value)
	PULSELENGHT = value
end

function ON_PROPERTY_CHANGED.Feedback (value)
	--dbg("ON_PROPERTY_CHANGED.Feedback."..value)
	if value == "ON" then
		FEEDBACK = true
	else
		FEEDBACK = false
	end
end

function ON_PROPERTY_CHANGED.InvertedRelay (value)
	--dbg("ON_PROPERTY_CHANGED.InvertedRelay."..value)
	if value == "ON" then
		INVERTED_RELAY = true
	else
		INVERTED_RELAY = false
	end
	dbg("INVERTED_RELAY"..tostring(INVERTED_RELAY))
end
function ON_PROPERTY_CHANGED.SelectColorOff (value)
	--print ("ON_PROPERTY_CHANGED.SelectColorOff",value)

	for i,v in pairs(States_fix) do
		if (value == v) then
			StateOff = value
			local color = LED_fix[i]
			LedOff = color
		end
	end
end

function ON_PROPERTY_CHANGED.SelectColorOn (value)
	--print ("ON_PROPERTY_CHANGED.SelectColorOn",value)
	for i,v in pairs(States_fix) do
		if (value == v) then 
			StateOn = value
			local color = LED_fix[i]
			LedOn = color
		end
	end
end

function OnTimerExpired (idTimer)
	if (idTimer == Timer.Debug) then
		dbg ('Turning Debug Mode Off (timer expired)')
		C4:UpdateProperty ('Debug Mode', 'Off')
		OnPropertyChanged ('Debug Mode')
	elseif (idTimer == Timer.Debounce) then
		CloseRelay()
		SET_OFF(false)
		dbg ('idTimer == Timer.Debounce')
		--gLedState, gIcontState =  LedOff, StateOff
		--DEVICE.SendIcon()
	end
end

function OpenRelay()
	--dbg ('INVERTED_RELAY == '..tostring(INVERTED_RELAY))
	if (LICENSE_MGR:isAbleToWork()) then
		if (INVERTED_RELAY) then
			dbg ('OPEN -> Sending CLOSE to '..tostring(RELAY_PROXY))
			C4:SendToProxy (RELAY_PROXY, "CLOSE", '')
		else
			dbg ('OPEN -> Sending OPEN')
			C4:SendToProxy (RELAY_PROXY, "OPEN", '')
		end
	end 
end

function CloseRelay()
	--dbg ('INVERTED_RELAY == '..tostring(INVERTED_RELAY))
	if (LICENSE_MGR:isAbleToWork()) then
		if (INVERTED_RELAY) then
			dbg ('CLOSE -> Sending OPEN')
			C4:SendToProxy (RELAY_PROXY, "OPEN", '')
		else
			dbg ('CLOSE -> Sending CLOSE')
			C4:SendToProxy (RELAY_PROXY, "CLOSE", '')
		end
	end
end
function ToggleRelay()
	if (LICENSE_MGR:isAbleToWork()) then
		C4:SendToProxy (RELAY_PROXY, "TOGGLE", '')
	end
end


function ReceivedFromProxy(idBinding, strCommand, tParams)
	print ("qqq",idBinding, strCommand, tParams)
	LICENSE_MGR:ReceivedFromProxy(idBinding, strCommand, tParams)
	if (LICENSE_MGR:isLicenseActiveOrTrial() == false) then 
		return
	end

    print ("RecievedFromProxy()", idBinding, strCommand, tParams)
    if type(PROXY_CMDS[strCommand]) == "function" then
        local success, retVal = pcall(PROXY_CMDS[strCommand], tParams)
        if success then
            return retVal
        end
    end
	if idBinding == CONTACT_PROXY then 
		if FEEDBACK == true then
			if strCommand == "CLOSED" then
				SET_ON(FEEDBACK)
			elseif strCommand == "OPENED" then
				SET_OFF(FEEDBACK)
			end
		end
	end
	if idBinding == RELAY_PROXY then 
		if FEEDBACK == false then
			if strCommand == "CLOSED" then
				SET_ON(FEEDBACK)
			elseif strCommand == "OPENED" then
				SET_OFF(FEEDBACK)
			end
		end
	end
    return nil
end


function PROXY_CMDS.DO_CLICK (tParams)
	dbg ('Do click'..tstring(tParams,2))
	-- Keypad button click acts like UI button pressed
	PROXY_CMDS.SELECT (tParams)
end


function PROXY_CMDS.OFF (tParams)
	dbg ('OFF')
	--Timer.PressIsOff = Helper.KillTimer (Timer.PressIsOff)
	--EX_CMDS.SetColor ({color = 'off'})
end


function PROXY_CMDS.SELECT (tParams)             --se premo il pulsante chiamo questa funzione
	dbg("PROXY_CMDS.SELECT"..tstring(tParams,2))
	if (gClickable) then                         --se è clickable allora mando un toggle
		if ACTION == "TOGGLE" then
			dbg ("mando un toggle al relay")
			ToggleRelay()
			--C4:SendToProxy (RELAY_PROXY, "TOGGLE", '')
			if STATE == "ON" then 
				SET_OFF(false)
			else
				SET_ON(false)
			end
		elseif ACTION == "ON-OFF" then
			dbg ("mando un ON-OFF")
			if STATE == "ON" then
				CloseRelay()
				SET_OFF(false)
			else
				OpenRelay()
				SET_ON(false)
			end
		elseif ACTION == "PULSE" then
			dbg ("mando un PULSE")
			OpenRelay()

			SET_ON(false)
			Timer.Debounce = Helper.AddTimer (Timer.Debounce, PULSELENGHT, 'MILLISECONDS', false)
			--gLedState, gIcontState = LedOn, StateOn
		    ----print ("I COLORI SONO ",gStateIndex, gCurrentState)
			--DEVICE.SendIcon()
			--Timer.Debounce = Helper.AddTimer (Timer.Debounce, PULSELENGHT, 'MILLISECONDS', false)
		else
		dgb("Action not handled: "..ACTION)	
		end
	else
		dbg ('Set as non clickable')
	end
end
function SET_ON(feed)
	if (LICENSE_MGR:isAbleToWork()) then
		dbg ('SET_ON')
			STATE = "ON"
		if FEEDBACK == feed then
			gLedState, gIcontState = LedOn, StateOn
			DEVICE.SendIcon()
		end
	end
end 
function SET_OFF(feed)
	if (LICENSE_MGR:isAbleToWork()) then
		dbg ('SET_OFF')
		STATE = "OFF"
		if FEEDBACK == feed then
			gLedState, gIcontState = LedOff, StateOff
			DEVICE.SendIcon()
		end
	end
end



-- HELPER FUNCTIONS
function Helper.AddTimer (timer, count, units, recur)
	local newTimer
	if (recur == nil) then recur = false end
	if (timer and timer ~= 0) then Helper.KillTimer (timer) end

	newTimer = C4:AddTimer (count, units, recur)
	return newTimer
end


function Helper.DriverInfo (info)
	C4:UpdateProperty ('Driver Information', info)
	print (os.date ('%x %X : ') .. info)
end


function Helper.TableInvert(t)
	local u = {}
	for k, v in pairs(t) do u[v] = k end
	return u
end


function Helper.KillAllTimers ()

	for k,v in pairs (Timer or {}) do
		if (type (v) == 'number') then
			Timer [k] = Helper.KillTimer (Timer [k])
		end
	end

	for _, thisQ in pairs (Qs or {}) do
		if (thisQ.ConnectingTimer and thisQ.ConnectingTimer ~= 0) then thisQ.ConnectingTimer = Helper.KillTimer (thisQ.ConnectingTimer) end
		if (thisQ.ConnectedTimer and thisQ.ConnectedTimer ~= 0) then thisQ.ConnectedTimer = Helper.KillTimer (thisQ.ConnectedTimer) end
	end
end


function Helper.KillTimer (timer)
	if (timer and type (timer) == 'number') then
		return (C4:KillTimer (timer))
	else
		return (0)
	end
end


function Helper.Print (data)
	if (type (data) == 'table') then
		for k, v in pairs (data) do print (k, v) end
	elseif (type (data) ~= 'nil') then
		print (type (data), data)
	else
		print ('nil value')
	end
end


function Helper.Round(num, idp)
  local mult = 10^(idp or 0)
  return math.floor(num * mult + 0.5) / mult
end


function Helper.VersionCheck (requires_version)
	local curver = {}
	curver [1], curver [2], curver [3], curver [4] = string.match (C4:GetVersionInfo ().version, '(%d+)\.(%d+)\.(%d+)\.(%d+)')
	local reqver = {}
	reqver [1], reqver [2], reqver [3], reqver [4] = string.match (requires_version, '(%d+)\.(%d+)\.(%d+)\.(%d+)')

	for i = 1, 4 do
		local cur = tonumber (curver [i])
		local req = tonumber (reqver [i])
		if (cur > req) then
			return true
		end
		if (cur < req) then
			return false
		end
	end
	return true
end


function Helper.RunFunctions(funcMap)
    for k,v in pairs(funcMap) do
        if type(v) == "function" then
            pcall(v)
        end
    end
end

function DEVICE.FireEvent (eventName)
	dbg ("Firing event", eventName)
	C4:SetVariable("STATE", eventName)
	C4:UpdateProperty ('Current State', eventName)
	C4:FireEvent( eventName )
end


function DEVICE.SendIcon ()
	print ("DEVICE.SendIcon", gLedState, gIcontState  )
    C4:SendToProxy (5001, "ICON_CHANGED", {icon=gIcontState})
	C4:SendToProxy (500, "BUTTON_COLORS", {ON_COLOR = {COLOR_STR = gLedState}, OFF_COLOR = {COLOR_STR = '000000'}}, "NOTIFY")
	if (gStateIndex == 1) then
		C4:SendToProxy (500, 'MATCH_LED_STATE', {STATE = '0'})
	else
		C4:SendToProxy (500, 'MATCH_LED_STATE', {STATE = '1'})
	end

	if (gCurrentState ~= 'off') then
		-- Turn interlocked buttons off
		for k, v in pairs (tInterlock) do
			if (k ~= tostring (C4:GetDeviceID() + 1)) then -- not ourselves
				C4:SendToDevice (k, 'OFF', {})
			end
		end
	end
end


function tprint (tbl, indent)  --print table
	print (tstring(tbl, (indent or 2)))
end

function tstring (tbl, indent) -- transform table in string, nested
	--ritorna una stringa contenente i valori della table
    --if indent is -1 return a table in one line string
	local  mytable = ""
	if not indent then indent = 0 end
	if (type(tbl) == "table") then
		if (indent == -1) then 
			for k,v in pairs(tbl) do
				mytable = mytable.." "..v
			end
		else
			for k, v in pairs(tbl) do
				formatting = string.rep("   ", indent) .. k .. ": "
				if type(v) == "table" then
					formatting = formatting..type(k)
					mytable = mytable .. formatting
					mytable = mytable .."\n"..tstring(v, indent+1)
				else
					mytable = mytable .. formatting .. tostring(v) .." \n"
				end
			end
		end
	else

		mytable = tbl
	end
	return mytable
end