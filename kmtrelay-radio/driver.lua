socket = require("socket")
udp = assert(socket.udp())

-- variabili da settare
max_license_val = 200 --molto alto è difficile che possa essere fregata la licenca com'è adesso
unique_device_id = "Max KMT Relay Devices"
--- Build License Manager object
require 'SKC4.LicenseManager'
--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "KMTRelayRadio.c4z", "DRIVERCENTRAL") -- Filename
LICENSE_MGR:setParamValue("ProductId", XXX , "HOUSELOGIX") -- Filename
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo ("version"), "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
LICENSE_MGR:setParamValue("Trial", LICENSE_MGR.TRIAL_NOT_STARTED, "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
--------------------------------------------
-- REMOVE THIS TO ENABLE LICENCE MANAGEMENT 
LICENSE_MGR:isLicenseActive = function ()
    return true
end
LICENSE_MGR:isLicenseTrial = function ()
    return 1
end
--------------------------------------------


-- tables and variables

EX_CMD = {}
PRX_CMD = {}
NOTIFY = {}
do	
	Common = {}	
	Timer = {}		--timers
end
------------------------------------------------DEV_MSG = {}
LUA_ACTION = {}

-- Relay Status Table
RelayStatus = {}
    -- all relay initial status is 0
    for x = 1,8 do 
	   RelayStatus[x] = 0
    end


KMT_IP = "KMTronic IP"
KMT_Port = "KMTronic Port"
--KMT_User = "KMTronic User"
--KMT_Pwd = "KMTronic Password"
Debug = "Debug"
Polling = "Polling"
Polling_sec = "Polling seconds"
dealer_email = "Dealer e-mail"
License_code = "License code"
License_status = "License Status"

License_Provider = "License Provider"
HL_Licence_code = "Houselogix License Code"



Variable_name = "CommandMask"
-- variabile per messaggio verso il bot
C4:AddVariable(Variable_name,"","STRING",false)

C4:urlSetTimeout(5)

--load moduli esterni e funzione reload come da forum
local req = {"utils.common","utils.sha"} 
    for x = 1, #req do 
	   if(package.loaded[req[x]] ~= nil)then 
	   print("Package "..req[x].." is already loaded, unload") 
	   package.loaded[req[x]] = nil 
    end 
end 

require("utils.common") 
require("utils.sha")

---------------------------------------------------------------------
-- Table of function from common
---------------------------------------------------------------------
ON_DRIVER_INIT = {}
ON_DRIVER_EARLY_INIT = {}
ON_DRIVER_LATEINIT = {}
ON_DRIVER_UPDATE = {}
ON_DRIVER_DESTROYED = {}
ON_PROPERTY_CHANGED = {}

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

--[[function HLicense_Activate()
  C4:UpdateProperty(License_status, 'Activating driver license...')
  mac = C4:GetUniqueMAC ()
  print("Sending PstData")
  local postData = string.format('lic=%s&mac=%s&p=%s&ver=%s', Properties[License_code], mac, product_number, sw_version)
  urlPost('https://www.houselogix.com/license-manager/activatelicense.asp', postData, {}, function(strData) HLicense_Response(strData) end)
end
license_count = 0

function HLicense_Response(data)
  Dbg('OnLicenseActivationResponseReceived'..data)
  --data = 'Valid' --fixme togliere la stringa per far funzionare la parte di licenze
  local i = string.find(data, 'Valid')
  if (i) then
		C4:UpdateProperty(License_status, 'Activated (last checked on: '..os.date("%m/%d/%Y %X")..')')
		Licenziato = true
		license_count = 0
		PersistData.Licensed = os.date("%m/%d/%Y %X")
  elseif (string.find(data, 'Unauthorized')) then
		 Licenziato = false
		 PersistData.Licensed = nil
		 C4:UpdateProperty('License Status', 'Invalid license key')
		 license_count = 0
		 print("License is NOT ok")
  elseif (string.find(data, 'Failed')) then
		 if PersistData.Licensed ~= nil then 
			Licenziato = true
		 else
			Licenziato = false
			license_count = 0
			print("Licensing Failed")
		 end
  end
  --return HLicense
  Timer.license = Common.AddTimer (Timer.license, licenseTime, licenseUnit, false)
end


function checkLicense()
	--print(Licenziato)
    if (Licenziato == true)  then
	   --Properties[License_status] = "Licensed"
	   Licenziato = true
	   license_count = license_count + 1
    else
		  HLicense_Activate()
	end
	if (license_count > max_license_val) then
		HLicense_Activate() --ricontrollo licenza ogni max_license_val
	end

    --print(tostring(Licenziato)..license_count)
    return Licenziato
end
]]

function OnDriverInit()
    print('Driver KMT Init')
    --g_cnt = 0
    DelayPolling = 0
    PollInit = true
    NoPoll = false
    poll_timer = 0
	--Timer.license = Common.AddTimer (Timer.license, licenseTime, "MINUTES", false)
	--Timer.license = Common.AddTimer (Timer.license, licenseTime, licenseUnit, false) 

	--local t = C4:SetTimer(5000, function(timer) HLicense_Activate() print("License testing...") end) 
    --PollInit = true
    --poll_timer = StartPollTimer()
    --Licenziato = checkLicense()
	if socket == nil then
		--print ("socket == nil")
		socket = require("socket")
		udp = socket.udp()
	end
	udp:settimeout(1)
	IP = Properties[KMT_IP]
    Port = Properties[KMT_Port]
    User = Properties[KMT_User]
    Pwd = Properties[KMT_Pwd]
	if (IP ~= nil and Port ~= nil) then
		setupServer()
	end
	LICENSE_MGR:OnDriverInit()  		
end
function OnDriverLateInit ()
	print("OnDriverLateInit")
	C4:SetPropertyAttribs("Automatic Updates", 1)
	LICENSE_MGR:OnDriverLateInit() 
end


function OnDriverUpdate()
	--Timer.license = Common.AddTimer (Timer.license, licenseTime, "MINUTES", false)
	--Timer.license = Common.AddTimer (Timer.license, licenseTime, licenseUnit, false)
	IP = Properties[KMT_IP]
    Port = Properties[KMT_Port]
    User = Properties[KMT_User]
    Pwd = Properties[KMT_Pwd]
	setupServer()	
end

function OnDriverDestroyed()
    -- distruggo il timer
    TimerKill(poll_timer)
end

-- apertura relay
function PRX_CMD.OPEN(idBinding, tParams)
    --spengo il timer
    NoPoll = true
    -- controllo licenza
    if LICENSE_MGR:isAbleToWork() then
	   Dbg("Open KMT Relay "..idBinding)
	   RelayStatus[idBinding] = 0
	   RelayCMD(idBinding,0)
	   C4:SendToProxy(idBinding, "OPENED",  "", "NOTIFY")
    end
    --ri-avvio il timer
    TimerNoPoll()
end

-- chiusura relay
function PRX_CMD.CLOSE(idBinding, tParams)
    --spengo il timer
    NoPoll = true
    -- controllo licenza
    if LICENSE_MGR:isAbleToWork() then
	   Dbg("Close KMT Relay "..idBinding)
	   RelayStatus[idBinding] = 1
	   RelayCMD(idBinding,1)
	   C4:SendToProxy(idBinding, "CLOSED",  "", "NOTIFY")
    end
    --ri-avvio il timer
    TimerNoPoll()
end

-- toogle
function PRX_CMD.TOGGLE(idBinding, tParams)
    if RelayStatus[idBinding] == 0 then
	   PRX_CMD.CLOSE(idBinding, tParams)
    else
	   PRX_CMD.OPEN(idBinding, tParams)
    end

end

-- trigger
function PRX_CMD.TRIGGER(idBinding, tParams)
    -- trigger
    Ttime = tonumber(tParams['TIME'])
    PRX_CMD.CLOSE(idBinding, tParams)
        C4:SetTimer(Ttime, function(timer)
	   PRX_CMD.OPEN(idBinding, tParams)
	   end)
end

function PRX_CMD.GET_STATE(idBinding, tParams)
    -- controllo licenza
    if LICENSE_MGR:isAbleToWork() then
	   if RelayStatus[idBinding] == 0 then
		  C4:SendToProxy(idBinding, "OPENED",  "", "NOTIFY")
	   else
		  C4:SendToProxy(idBinding, "CLOSED",  "", "NOTIFY")
	   end
    end
end

----------------------------------------- 
--Connections Functions 
-----------------------------------------

function OnBindingChanged(idBinding, class, bIsBound)
    Dbg("OnBindingChanged")
end

-- cambio di una variabile
function OnVariableChanged(strName)
    Dbg("OnVariableChanged")
end

function OnPropertyChanged(sProperty)
    --Dbg("OnPropertyChanged")
    -- Polling
    if Properties[Polling] == "On" then
	   -- spengo e ri-attivo per sicurezza
	   poll_timer = C4:KillTimer(poll_timer)
	   poll_timer = StartPollTimer()
    else
	   poll_timer = C4:KillTimer(poll_timer)
    end
	if (sProperty == KMT_IP) then 
		IP = Properties[sProperty]
	end

	if (sProperty == KMT_Port) then 
		Port = Properties[sProperty]
	end
	if (IP ~= nil and Port ~= nil) then
    	setupServer()
	end
	--licensing
	local value = Properties[sProperty]
	if (sProperty == License_Provider) then
		Dbg("strProperty == 'License_Provider'") 
		LICENSE_MGR:ON_PROPERTY_CHANGED_LicenseProvider(value)
	end
	if (sProperty == HL_Licence_code) then 
		Dbg("strProperty == 'HL_Licence_code'")
		LICENSE_MGR:ON_PROPERTY_CHANGED_HouselogixLicenseCode(value)
	end
end

----------------------------------------- 
--Actions Functions 
-----------------------------------------

function setupServer()
	
	if (udp:getsockname() ~= nil) then
	--print("udp:getsockname() ~= nil")
		i,p = udp:getsockname()
		--print(i,p)
		if(i ~= "0.0.0.0")then 
			--print("i ~= 0.0.0.0")
			assert(udp:setpeername("*"))
			assert(udp:close())
			udp = assert(socket.udp())
		end
		--print(udp:getsockname())
	else
		--print("udp = assert(socket.udp())")
		udp = assert(socket.udp())
	end
	--print("fuori tutto")
	--i,p = udp:getsockname()
	--print(i)
	--print (p)
	assert(udp:setsockname("*",Port))
	assert(udp:setpeername(IP,Port))
	print(udp:getsockname())
	print(udp:getpeername())
end

function LUA_ACTION.TestOPEN()
    --spengo il timer
    NoPoll = true
    Dbg("Start Testing Open All KMT Relays")
    --RelayLoop(1, 0)
    AllRelaysCMD("OPENED")
end

function LUA_ACTION.TestCLOSE()
    --spengo il timer
    NoPoll = true
    Dbg("Start Testing Close All KMT Relays")
    --RelayLoop(1, 1)
    AllRelaysCMD("CLOSED")
end

function LUA_ACTION.DisplayStatus()
    --spengo il timer
    NoPoll = true
    -- controllo licenza
	updateKmtStatus()
    if LICENSE_MGR:isAbleToWork() then
	    txt_Info ="\n".. "KMT RELAYS STATUS".."\n-------------------------"
	    for index, rel in pairs(RelayStatus) do
		  if rel == 0 then
			 txt_Info = txt_Info.."\n KMT Relay "..index .." is OPEN (0)"
		  else
			 txt_Info = txt_Info.."\n KMT Relay "..index .." is CLOSE (1)"
		  end
	    end
	    Dbg(txt_Info)
	end
    --ri-avvio il timer
    TimerNoPoll()
    
end

----------------------------------------- 
--KMTronic Functions 
-----------------------------------------
minimum = 100
maximum = 400
function RelayCMD(RelNr,RelOnOff)
	RelayStatus[RelNr] = RelOnOff
	local msg = "FF".."0"..RelNr..'0'..RelOnOff
	print ("message to send "..msg)
	local t = C4:SetTimer(math.random (minimum, maximum), function(timer) assert(udp:send(msg))end)
	--C4:SetTimer(math.random (100, 500), sendCMD(msg), false)
end

function sendCMD(data)
	assert(udp:send(data))
end
function KmtCreateUrl()
   
    --KmtUrl = 'http://'..User..':'..Pwd..'@'..IP..':'..Port
    --return KmtUrl
end

function RelayALL(OnOff)
   
	local msg = "FF"
	if (OnOff == "00") then
		msg = msg.."B1"..OnOff
	elseif(OnOff == "FF")then
		msg = msg.."B1"..OnOff
	end
	assert(udp:send(msg))
	--local data = udp:receive()
   -- print(data)			
end

function AllRelaysCMD(OpenClose)
    dbg_text = "\n"
    -- controllo licenza
    if LICENSE_MGR:isAbleToWork() then
	   if OpenClose == "CLOSED" then
		  RelayALL("FF")
		  Status = 1
	   else
		  RelayALL("00")
		  Status = 0
	   end
	   for x = 1,8 do 
		  RelayStatus[x] = Status
		  C4:SendToProxy(x, OpenClose,  "", "NOTIFY")
		  dbg_text = dbg_text .."KMT Relay "..x.." > "..OpenClose.."\n"
	   end
	   Dbg(dbg_text)
    end
    --ri-avvio il timer
   TimerNoPoll()
end

function ReadKmtStatus()
	--print("sono in kmt ReadKmtStatus")
	assert(udp:send("FFA100"))
	--print("lettura")
	local data = udp:receive()
	print ("data",data)
	if (data == nil) then
		print ("Communication Failure")
	else
		for i = 1,8 do
		print(data:sub(5+(i*2),6+(i*2)))
			RelayStatus[i] = tonumber (data:sub(5+(i*2),6+(i*2)))
		end
	end
end

-- parsing XML per stato relay
function updateKmtStatus()
	--print("sono in kmt updatestatus")
	ReadKmtStatus()
	if DelayPolling > 0 then
	   DelayPolling = 0
	   poll_timer = C4:KillTimer(poll_timer)
	   poll_timer = StartPollTimer()
	end

	if DelayPolling < 300 then
		 DelayPolling =  DelayPolling + 10
	  else
		DelayPolling = 310
		Dbg("Connection error with: "..Properties[KMT_IP].. " - Delay poll at 5 mins - "..strError)
		 poll_timer = C4:KillTimer(poll_timer)
		 poll_timer = StartPollTimer()
	  end
end


----------------------------------------- 
--Timer Functions 
-----------------------------------------

function Common.KillTimer (timer)
	if (timer and type (timer) == 'number') then
		return (C4:KillTimer (timer))
	else
		return (0)
	end
end


function Common.AddTimer(timer, count, units, recur)
	Dbg("timer",count,units,recur,timer)
	if timer ~= nil then  Dbg("timer not nill:",timer) end
	local newTimer
	if (recur == nil) then recur = false end
	if (timer and timer ~= 0) then Common.KillTimer (timer) end
	newTimer = C4:AddTimer (count, units, recur)
	return newTimer
end


--Timer.license = Common.AddTimer (Timer.license, 72, "HOURS", false)
--Timer.license = Common.AddTimer(Timer.license, licenseTime, licenseUnit, false) 


function StartPollTimer()
    tt = 0

    if (Properties[Polling] == "On" ) then
	   
	   if DelayPolling > 0  then
    		  id = C4:AddTimer(tonumber(DelayPolling), "SECONDS", true)
		  Dbg("Start Polling Timer with "..DelayPolling.. " seconds of frequency")
	   else
		  id = C4:AddTimer(tonumber(Properties[Polling_sec]), "SECONDS", true)
		  Dbg("Start Polling Timer with "..Properties[Polling_sec].. " seconds of frequency")

	   end

	   return id
    else
	   Dbg("Polling Timer is turned off in properties setting")
	   return 0
    end
end

function TimerKill(poll_timer)
    C4:KillTimer(poll_timer)
    poll_timer = 0
end

-- Timer Expire
function OnTimerExpired(idTimer)
    --tt = tt +1
    --print(idTimer .." - Poll_timer= "..poll_timer.."NoPoll: " ..tostring(NoPoll))
    --C4:KillTimer(idTimer)
    if (idTimer == poll_timer) then
	   if NoPoll == false then
		  --print("Timer fired "..g_cnt)
		 -- updateKmtStatus()
	   end
--	elseif (idTimer == Timer.license) then
--		Dbg('Timer Expired > Turning off license')
--		Licenziato = false
--		HLicense_Activate()
--		Timer.license = Common.AddTimer (Timer.license, licenseTime, licenseUnit, false)
	
	--elseif (idTimer ==	Timer.RelayCMD) then
	--assert(udp:send(dataToSend[idTimer]))
    else
	   C4:KillTimer(idTimer)
	   poll_timer = 0
    end
end

function TimerNoPoll()
    C4:SetTimer(3000, function(timer)
				    NoPoll = false
				end)
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

-- function urlPut(url, data, headers, callback, errorHandler)
	-- local ticketId = C4:urlPut(url, data, headers)
	-- g_responseTickets[ticketId] = { handler = callback, errorHandler = errorHandler }
-- end

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

function OnVariableChanged(strName)
  --DbgSK('Variable '..strName..' changed')
  -- cambia la variabile... fai qualcosa
  print(Variable_name, strName)
  sendMulti(Variables[strName])

  C4:SetVariable(Variable_name,"") -- pulisco la var
end

function sendMulti(command)
	print(command)
	if (string.len(command) ==8) then
		local number = 0
		for i = 1,string.len(command) do 
			if (command:byte(i) == 48 or command:byte(i) == 49) then 
				number = number + (command:byte(i) - 48)*math.pow (2, string.len(command)-i)
				RelayStatus[9-i] = tonumber(command:byte(i)-48)
			end		
		end
		print (number)
		strHex = ""
		strHex = string.format("%X",number)
		local msg = "FF".."B1"..strHex
		assert(udp:send(msg))
		--local data = udp:receive()
		--ReadKmtStatus()
			--  print(data)
	end
end

function tprint (tbl, indent)
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("   ", indent) .. k .. ": "
    if type(v) == "table" then
      print(formatting)
      tprint(v, indent+1)
    else
      print(formatting .. tostring(v))
    end
  end
end


