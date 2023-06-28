-- variabili da settare
max_license_val = 200 --molto alto è difficile che possa essere fregata la licenca com'è adesso
unique_device_id = "Max KMT Relay Devices"

--- Build License Manager object
require 'SKC4.LicenseManager'
--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "KMTTronic_IPRelays.c4z", "DRIVERCENTRAL") -- Filename
LICENSE_MGR:setParamValue("ProductId", XXX, "HOUSELOGIX") -- Filename
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo ("version"), "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
LICENSE_MGR:setParamValue("Trial", LICENSE_MGR.TRIAL_NOT_STARTED, "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB

-- tables and variables

EX_CMD = {}
PRX_CMD = {}
NOTIFY = {}
DEV_MSG = {}
LUA_ACTION = {}

-- Relay Status Table
RelayStatus = {}
    -- all relay initial status is 0
    for x = 1,8 do 
	   RelayStatus[x] = 0
    end


KMT_IP = "KMTronic IP"
KMT_Port = "KMTronic Port"
KMT_User = "KMTronic User"
KMT_Pwd = "KMTronic Password"
Debug = "Debug"
Polling = "Polling"
Polling_sec = "Polling seconds"
dealer_email = "Dealer e-mail"
License_Provider = "License Provider"
HL_Licence_code = "Houselogix License Code"



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

  local postData = string.format('lic=%s&mac=%s&p=%s&ver=%s', Properties[License_code], mac, product_number, sw_version)
  urlPost('https://www.houselogix.com/license-manager/activatelicense.asp', postData, {}, function(strData) HLicense_Response(strData) end)
end

function HLicense_Response(data)
  Dbg('OnLicenseActivationResponseReceived')
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
end


function check2License()
	print(Licenziato)
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
end]]

function OnDriverInit()
    print('Driver KMT Init')
    --g_cnt = 0
    DelayPolling = 0
    PollInit = true
    NoPoll = false
    poll_timer = 0
	C4:SetPropertyAttribs("Automatic Updates", 1)

--	local t = C4:SetTimer(5000, function(timer) HLicense_Activate() print("License testing...") end) 
	LICENSE_MGR:OnDriverInit()  
end

function OnDriverLateInit ()
	print("OnDriverLateInit")
	C4:SetPropertyAttribs("Automatic Updates", 1)
	LICENSE_MGR:OnDriverLateInit()
	executeAllOnPropertyChanged	()
end
function executeAllOnPropertyChanged	()
	for k,v in pairs(Properties) do
		print("INIT_CODE: Calling OnPropertyChanged - " .. k .. ": " .. v)
		local status, err = pcall(OnPropertyChanged, k)
		if (not status) then
			print("LUA_ERROR: " .. err)
		end
	end
	end

function OnDriverUpdate()

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

function RelayCMD(RelNr,RelOnOff)
    KmtUrl = KmtCreateUrl()
    link = KmtUrl..'/FF0'..RelNr..'0'..RelOnOff
	--Dbg(link)
	C4:urlGet(string.format(link),{}, false,
				function(ticketId, strData, responseCode, tHeaders, strError)
				end)
end

function KmtCreateUrl()
    IP = Properties[KMT_IP]
    Port = Properties[KMT_Port]
    User = Properties[KMT_User]
    Pwd = Properties[KMT_Pwd]
    KmtUrl = 'http://'..User..':'..Pwd..'@'..IP..':'..Port
    return KmtUrl
end

function RelayALL(OnOff)
    KmtUrl = KmtCreateUrl()
    link = KmtUrl..'/FFE0'..OnOff
    --Dbg(link)
	 C4:urlGet(string.format(link),{}, false,
				function(ticketId, strData, responseCode, tHeaders, strError)
				end)
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
    for i = 1,8 do 
	   if RelayStatus[i] ~= tonumber(KmtStatus['relay'..i]) then
		  RelayStatus[i] = tonumber(KmtStatus['relay'..i])
		  if RelayStatus[i] == 1 then
			 Dbg("KMT Relay "..i.." was OPEN(0) by C4 but something else CLOSE(1) it!")
			 C4:SendToProxy(i, "CLOSED",  "", "NOTIFY")
		  else
			 Dbg("KMT Relay "..i.." was CLOSE(1) by C4 but something else OPEN(0) it!")
			 C4:SendToProxy(i, "OPENED",  "", "NOTIFY")
		  end
	   end
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
					--print(strData)
        				--updateData('lares_status',laresStatus)
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
        if (childNode['ChildNodes']) then
            hash[childNode['Name']] = _subTableTree(childNode)
            if (childNode['Value'] and childNode['Value'] ~= "") then
                hash[childNode['Name']] = childNode['Value']
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

----------------------------------------- 
--Timer Functions 
-----------------------------------------
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
		  updateKmtStatus()
	   end
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

