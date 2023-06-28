-- KMT Temperature Devices HOUSELOGIX 1 DEVICE BOARD
-- variabili da settare 
max_license_val = 200 --molto alto è difficile che possa succedere
unique_device_id = "Max KMT Temperature Devices"
--- Build License Manager object
require 'SKC4.LicenseManagerDriverCentral'
--- Config License Manager
DC_LICENSE_MGR:setProductId(205)
DC_LICENSE_MGR:setFreeDriver(false)
DC_LICENSE_MGR:setFileName("KMTronic_UnLim_temperature_sensor.c4z")


EX_CMD = {}
PRX_CMD = {}
NOTIFY = {}
DEV_MSG = {}
LUA_ACTION = {}

KMT_IP = "KMTronic IP"
KMT_Port = "KMTronic Port"
KMT_User = "KMTronic User"
KMT_Pwd = "KMTronic Password"
Debug = "Debug"
Polling = "Polling"
Polling_sec = "Polling minutes"
dealer_email = "Dealer e-mail"


max_device = 1000 --UnLimited
too_many = false


-- Temperature Status Table
ReadTemp = {}

    -- all initial temps is 0
    for x = 1,4 do 
	   ReadTemp[x] = {}
	   ReadTemp[x].temp = 0
	   ReadTemp[x].name = ""
    end



-- inizializzo variabili
for x = 1, 4 do
    C4:DeleteVariable("Temp_value_"..x)
    C4:AddVariable("Temp_value_"..x, 0, "NUMBER",true)
end



---------------------------------------------------------------------
-- Table of function from common
---------------------------------------------------------------------
ON_DRIVER_INIT = {}
ON_DRIVER_EARLY_INIT = {}
ON_DRIVER_LATEINIT = {}
ON_DRIVER_UPDATE = {}
ON_DRIVER_DESTROYED = {}
ON_PROPERTY_CHANGED = {}

-- cambio di una variabile
function OnVariableChanged(strName)

    Dbg("OnVariableChanged")

end

function OnPropertyChanged(sProperty)
    Dbg("OnPropertyChanged")
    -- Polling
	  if poll_timer ~= nil then poll_timer = C4:KillTimer(poll_timer) end
	  poll_timer = StartPollTimer()
    
    if string.find(sProperty,"Calibrate") ~= nil then
	   updateKmtStatus()
    end
    
end

function StartPollTimer()

	   if DelayPolling > 0  then
    		  id = C4:AddTimer(tonumber(DelayPolling), "MINUTES", true)
		  Dbg("Start Polling Timer with "..DelayPolling.. " minutes of frequency")
	   else
		  id = C4:AddTimer(tonumber(Properties[Polling_sec]), "MINUTES", true)
		  --print(id)
		  Dbg("Start Polling Timer with "..Properties[Polling_sec].. " minutes of frequency")

	   end
	   return id
end



---------------------------------------------------------------------
-- Initialization/Destructor Code
---------------------------------------------------------------------
function checkDeviceInstalled()
    -- restituisce il numero dei driver presenti nel progetto
    --print(C4:GetProjectItems())
	   string_find = unique_device_id
      x, driver_installed = string.gsub(C4:GetProjectItems(), string_find, string_find)
	 --driver_installed = driver_installed/2 -- la funzione precedente restituisce 2 per ogni driver
	 print("Number of driver installed: ".. driver_installed)
    return driver_installed
end

function checkLicense()
	Licenziato = DC_LICENSE_MGR:isAbleToWork()
    --print(tostring(Licenziato)..license_count)
    return Licenziato
end

function OnDriverInit()
    print('Driver KMT Init')
	DC_LICENSE_MGR:init()
end

function OnDriverLateInit()
    print('Driver KMT LateInit')
    --g_cnt = 0
    DelayPolling = 0
    -- avvio timer con ritardo (5 sec) altrimenti non funzione
    PollTimerRestart ()
end


function OnDriverUpdate()
    -- distruggo il timer
    poll_timer = C4:KillTimer(poll_timer)
end

function OnDriverDestroyed()
    -- distruggo il timer
    poll_timer = C4:KillTimer(poll_timer)
end

-- Timer Expire
function OnTimerExpired(idTimer)
    -- controllo licenza
    if checkLicense() then
		if (idTimer == poll_timer) then
		   Dbg("Timer fired ")
		   updateKmtStatus()
		   --printStatus = true
		else
		   C4:KillTimer(idTimer)
		   poll_timer = 0
		end
	end
end

----------------------------------------- 
--Connection Functions 
-----------------------------------------

function OnBindingChanged(idBinding, class, bIsBound)
    Dbg("OnBindingChanged")
    updateKmtStatus()
end


function KmtCreateUrl()
    IP = Properties[KMT_IP]
    Port = Properties[KMT_Port]
    User = Properties[KMT_User]
    Pwd = Properties[KMT_Pwd]
    KmtUrl = 'http://'..User..':'..Pwd..'@'..IP..':'..Port
    return KmtUrl
end


function PollTimerRestart () 
    C4:SetTimer(5000, function(timer)
				poll_timer = StartPollTimer()
			 end)
end



function LUA_ACTION.DisplayStatus()
	Dbg("Display Temperature Status")
	updateKmtStatus()
     printStatus = true

end

function DbgStatus()
    tempstatus = " Temperature sensors Status\n"
    for x = 1,4 do 
	   tempstatus = tempstatus..ReadTemp[x].name.." > " ..ReadTemp[x].temp 
	   tempstatus = tempstatus.." °C (with correction(calibration) of: "..leggiPropCal(x).." \n"
    end
    Dbg(tempstatus)
end

function ReadKmtStatus()

	--local z = 4
	-- reset
	for x = 1,4 do 
		ReadTemp[x].temp = 0
		ReadTemp[x].name = x.." - not installed"
	end

	for x, y in pairs(KmtStatus) do
		
		if string.find(x, 'sensor') ~= nil then
		  if y.temp ~= "---" then
			-- 
			a = x:gsub( 'sensor', '')
			tempNum = CommaOrPoint(y.temp)
			z = tonumber(a)
			ReadTemp[z].temp = SetTemp(z,tempNum) 
			ReadTemp[z].name = z.." - "..y.name
			C4:SetVariable("Temp_value_"..z,ReadTemp[z].temp)
			tt = tonumber(ReadTemp[z].temp)
			ttString = tostring(ReadTemp[z].temp)
			
			C4:SendToProxy(z,"TEMPERATURE_CHANGED",  {TEMPERATURE = ttString}, "NOTIFY")
			C4:SendToProxy(4+z,"TEMPERATURE_CHANGED",  {TEMPERATURE = tt, SCALE = "CELSIUS"}, "COMMAND")
		  end
		  --z = z-1
		  
		end
	end
	if printStatus then
	   DbgStatus()
	   printStatus = false
	end
end


function round(num, idp)
	return tonumber_loc(string.format("%." .. (idp or 0) .. "f", num))
end

function tonumber_loc(str, base)
	if (type(str)=="string") then
	  local s = str:gsub(",", ".") -- Assume US Locale decimal separator
	  local num = tonumber(s, base)
	  if (num == nil) then
		s = str:gsub("%.", ",") -- Non-US Locale decimal separator
		num = tonumber(s, base)
	  end
	  return num
	else
	  return tonumber(str)
	end	
end
-- parsing XML per stato relay
function updateKmtStatus()
    KmtUrl = KmtCreateUrl()
    url = KmtUrl..'/status.xml'
    C4:urlGet(string.format(url),{}, false,
				function(ticketId, strData, responseCode, tHeaders, strError)
				    if (strError == nil) then
        				KmtStatus = parseKmtStatus(strData)
						ReadKmtStatus()
						if DelayPolling > 0 then
						   DelayPolling = 0
						   poll_timer = C4:KillTimer(poll_timer)
						   poll_timer = StartPollTimer()
						end
				    else
					   	--Dbg("Connection error with: "..Properties[KMT_IP].. " - " ..strError)
						if DelayPolling < 300 then
							 DelayPolling =  DelayPolling + 10
						else
							DelayPolling = 310
							Dbg("Connection error with: "..Properties[KMT_IP].. " - Delay poll at 5 mins - "..strError)
							poll_timer = C4:KillTimer(poll_timer)
							poll_timer = StartPollTimer()
						end
						  
				    end
				end
  )
end

function _subTableTree(node)
    local hash = {}
    for k,childNode in pairs(node['ChildNodes']) do -- ciclo sui figli 
	   if childNode['Name'] == "sensor" then
		  childNode['Name'] = childNode['Name']..k
		  --print(childNode['Name'])
	   end
        if (childNode['ChildNodes']) then
            hash[childNode['Name']] = _subTableTree(childNode)
            if (childNode['Value'] and childNode['Value'] ~= "") then
                hash[childNode['Name']] = childNode['Value']
			 --print("Name = " ..childNode['Name'].." - Value = " ..childNode['Value'])
            end
        end
    end
    return hash
end

function parseKmtStatus(xmlString)
    rootNode = C4:ParseXml(xmlString)
    result = _subTableTree(rootNode)
    return result
end


function ReceivedFromProxy(idBinding, sCommand, tParams)
	if (sCommand ~= nil) then
		if(tParams == nil)		-- initial table variable if nil
			then tParams = {}
		end

		if (PRX_CMD[sCommand]) ~= nil then
			PRX_CMD[sCommand](idBinding, tParams)
		else
			Dbg("ReceivedFromProxy: Unhandled command = " .. sCommand)
		end
	end
end

-- Calibrazione
function SetTemp(nrSensor,strValue)
    CalValue=GetCalibration(nrSensor)
    --strValue = string.gsub(strValue,"%.",",")
    readTemp =  round(tonumber_loc(strValue),2)
    tempFloat = readTemp + CalValue
    temp =  round(tempFloat,0)
    --print(temp)
    return temp
end

function CommaOrPoint(strNumber)
    lessPoint = string.gsub(strNumber,"%.","")
    num = tonumber(lessPoint)/100
    return num
end

function GetCalibration(nrSensor)
    cal = leggiPropCal(nrSensor)
    cal = string.gsub(cal,',','.') -- sostituisco la virgola con il punto
    isNum = tonumber (cal)
    if isNum == nil then
	   isNum = 0
	   Dbg("Calibration "..nrSensor.." properties in not a number.So I set it to value=0")
    end
    --print(cal, isNum)
    return isNum
end

function leggiPropCal(nrSensor)
    Cal = {}
    Cal[1] = Properties["Calibrate Sensor 1"]
    Cal[2] = Properties["Calibrate Sensor 2"]
    Cal[3] = Properties["Calibrate Sensor 3"]
    Cal[4] = Properties["Calibrate Sensor 4"]
    return Cal[nrSensor]
end

-----------------------------------------
-- Common URL function
-----------------------------------------

g_responseTickets = {}

function ReceivedAsync(ticketId, strData, responseCode, tHeaders, strError)
	local ticket = pullUrlTicket(ticketId)
	if (not ticket) then dbg("ticketId is null") return end
	if (strData) then Dbg("ReceivedAsync: " .. strData) end
	if (strError) then
		Dbg("[ReceivedAsync]: ERROR | " .. strError)
		if (ticket.errorHandler and type(ticket.errorHandler) == 'function') then
			ticket.errorHandler(strError)
		end
		return
	end

	ticket.handler(strData, tHeaders)
end

function urlGet(url, headers, callback, errorHandler)
	local ticketId = C4:urlGet(url, headers)
	g_responseTickets[ticketId] = { handler = callback, errorHandler = errorHandler }
end

function urlPost(url, data, headers, callback, errorHandler)
	local ticketId = C4:urlPost(url, data, headers)
	g_responseTickets[ticketId] = { handler = callback, errorHandler = errorHandler }
end

function urlPut(url, data, headers, callback, errorHandler)
	local ticketId = C4:urlPut(url, data, headers)
	g_responseTickets[ticketId] = { handler = callback, errorHandler = errorHandler }
end

function urlEncode(str)
	return str:gsub(" ","+"):gsub("\n","\r\n"):gsub("([^%w])",function(ch)
			return string.format("%%%02X",string.byte(ch))
		end)
end

function pullUrlTicket(ticketId)
	local ticket = g_responseTickets[ticketId]
	g_responseTickets[ticketId] = nil
	return ticket
end

-- Comandi LUA Actions
--Execute Command
function ExecuteCommand(sCommand, tParams)
    --Dbg("ExecuteCommand")
	-- Remove any spaces (trim the command)
	local trimmedCommand = string.gsub(sCommand, " ", "")
	-- if function exists then execute (non-stripped)
	if (EX_CMD[sCommand] ~= nil and type(EX_CMD[sCommand]) == "function") then
		EX_CMD[sCommand](tParams)
	-- elseif trimmed function exists then execute
	elseif (EX_CMD[trimmedCommand] ~= nil and type(EX_CMD[trimmedCommand]) == "function") then
		EX_CMD[trimmedCommand](tParams)
	-- handle the command
	elseif (EX_CMD[sCommand] ~= nil) then
		QueueCommand(EX_CMD[sCommand])
	else
		--Dbg:Alert("ExecuteCommand: Unhandled command = " .. sCommand)
	end
end

-- decode table tParams
function EX_CMD.LUA_ACTION(tParams)
	 --  print("dddd")
	if tParams ~= nil then
		for cmd,cmdv in pairs(tParams) do
			if cmd == "ACTION" then
				if (LUA_ACTION[cmdv] ~= nil) then
					LUA_ACTION[cmdv]()
				else
					Dbg("Undefined Action")
					Dbg("Key: " .. cmd .. " Value: " .. cmdv)
				end
			else
				Dbg("Undefined Command")
				Dbg("Key: " .. cmd .. " Value: " .. cmdv)
			end
		end
	end
end

--stampa messaggi se la properties Debug è su On
function Dbg (msg)
    if Properties[Debug] == "On" then
	   local data = os.date("%d/%m/%Y %X")
	   print (data.." - "..msg)
    end
end

