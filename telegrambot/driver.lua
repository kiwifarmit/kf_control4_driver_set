

JSON = require 'json'
https = require("socket")
do	
	Common = {}	
	Timer = {}		--timers
end

--- Build License Manager object
require 'SKC4.LicenseManager'
--- Config License Manager
LICENSE_MGR:setParamValue("ProductId", XXX, "DRIVERCENTRAL") -- Product ID
LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)
LICENSE_MGR:setParamValue("FileName", "telegram-bot.c4z", "DRIVERCENTRAL") -- Filename
LICENSE_MGR:setParamValue("ProductId", XXX, "HOUSELOGIX") -- Filename
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI") -- Filename -- DD394AB4A8CA48BB
LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo ("version"), "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
LICENSE_MGR:setParamValue("Trial", LICENSE_MGR.TRIAL_NOT_STARTED, "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
--end license


C4:urlSetTimeout(5)

BOT_TYPE = "USER"
BOT_KEYS_MAP = {}
BOT_KEYS_MAP["USER"] = "PUT TOKEN HERE"
BOT_KEYS_MAP["TECH"] = "PUT TOKEN HERE"
BOT_KEYS_MAP["TEST"] = "PUT TOKEN HERE"
URL="https://api.telegram.org"   

License_Code_Prop = "License Code"
User_Code_Prop = "User Code"
Username_Prop ="Username"
Username_Associated_Prop = "Username Associated"
Telegram_Bot_Type = "Telegram Bot Type"
-- License_Provider = "License Provider"
-- HL_Licence_code = "Houselogix License Code"
-- SK_Licence_code = "SoftKiwi License Code"
product_number = XXX
-- LICENSED = true
sw_version = C4:GetDriverConfigInfo ("version")
--Properties[License_code] = 0
UPDATE_ID = 0
methodType = {}
userCode = 0
messageTable={}

licenseTime = 24*7
 --hours--minutes

queueInAction = false

simplecounter = 0

if (not PersistData) then PersistData = {} end
USERTABLE= PersistData.USERTABLE or {}
PersistData.USERTABLE = USERTABLE
license_code = PersistData.license_code or 0
UPDATE_ID = PersistData.UPDATE_ID or 0
DEBUGPRINT  = false


-- variabile per messaggio verso il bot
C4:AddVariable("WriteToBot","","STRING",false)


DbgLog = {}

function DbgSK(msg)
    if DEBUGPRINT == true then
		--local data = os.date("%d/%m/%Y %X")
		--msgD = data.." - "..msg
		msgD = msg
		print (msgD)
		if table.getn(DbgLog) > 1000 then DbgLog = {} end
		table.insert(DbgLog,{msg = msgD})
	end
end

function Common.KillTimer (timer)
	if (timer and type (timer) == 'number') then
		return (C4:KillTimer (timer))
	else
		return (0)
	end
end

function Common.AddTimer (timer, count, units, recur)
	DbgSK("timer")
	if timer ~= nil then  DbgSK(timer) end
	local newTimer
	if (recur == nil) then recur = false end
	if (timer and timer ~= 0) then Common.KillTimer (timer) end
	newTimer = C4:AddTimer (count, units, recur)
	return newTimer
end

function getFirst(T)
	local n  = 1
	local f
	for k, v in pairs(T) do
		if n == 1 then f = k end
	end
	return f
end

function OnTimerExpired (idTimer)
	if (idTimer == Timer.queue) then
		DbgSK('Timer Expired > Sending POST message')
		if tablelength(messageTable) ~= 0 then 
			local cID = getFirst(messageTable)
			sendMessage(cID,messageTable[cID])
			messageTable[cID] = nil
			Timer.queue = Common.AddTimer (Timer.queue, 2000, "MILLISECONDS", false) 
		else
			queueInAction = false
		end
	end
end

function testSend()
	link = URL.."/bot"..BOT_KEYS_MAP[BOT_TYPE].."/getUpdates"
	--DbgSK(link)
	tickedId = C4:urlGet(link)
end

function ReceivedFromProxy (idBinding, sCommand, tParams)
	-- in ReceiveFromPRoxy Driver da licenziare
	print("ReceivedFromProxy - idBinding", idBinding)
	print("ReceivedFromProxy - sCommand", sCommand)
	print("ReceivedFromProxy - tParams.isLicense", tParams.isLicense)

	LICENSE_MGR:ReceivedFromProxy (idBinding, sCommand, tParams)
	
end

function ReceivedAsync(ticketId, sData, responseCode, tHeaders)
	DbgSK(">ReceivedAsync")
	--mesg = "tickedId "..ticketId..", \n sData "..sData..",\n responseCode "..responseCode.. ",\n header "..tstring(tHeaders)
	--DbgSK(mesg)
	if methodType[ticketId] == "GET" then 
		parseGetResult(sData)
	end
	methodType[ticketId] = nil
end

function parseGetResult(sData)
	if sData ~= nil then 
		response = JSON:decode(sData)
		if (USERTABLE[BOT_TYPE] == nil or USERTABLE[BOT_TYPE].getn == nil) then parseUserName(Properties[Username_Prop]) end
		for i, item in pairs(response["result"]) do
			--se ho gli user fra quelli definiti
			local received_username = string.lower(response["result"][i]["message"]["from"]["username"])
			if USERTABLE[BOT_TYPE][received_username] ~= nil then
				--immagazzino il chatid per quell'utente
				if ChatID == nil then ChatID = {} end
				ChatID[BOT_TYPE] = response["result"][i]["message"]["chat"]["id"]
				-- fixme chatID > 0 allora non è una chat di gruppo ... salvo?
				-- ho deciso di no... 
				if ChatID[BOT_TYPE] >0 then
					USERTABLE[BOT_TYPE][received_username]  = ChatID[BOT_TYPE]
					PersistData.USERTABLE = USERTABLE
				end
				--se il messaggio che leggo non l'ho mai letto e lo usaer code è uguale a wuello inserito
				if response["result"][i]["update_id"] > UPDATE_ID and response["result"][i]["message"]["text"]:gsub('%W','') == userCode then 
					UPDATE_ID = response["result"][i]["update_id"]
					PersistData.UPDATE_ID = UPDATE_ID
					local msg = "add "..received_username.." to my contacts!!"
					botAct(ChatID[BOT_TYPE],msg)
				end
			else
				print("\n\n\n do not find your username in the last message received from the bot...\nplease try again to send a message")
			end
		end
		userProperty()
	end
end


function OnPropertyChanged (strProperty) 
--fixme capire quali sono le properties che vanno nel driver,  
	DbgSK("OnPropertyChanged "..strProperty)
	
	local value = Properties[strProperty]
	DbgSK("changed "..strProperty.." value:"..value)
	if (value == nil) then
		DbgSK('OnPropertyChanged, nil value for Property: '.. strProperty)
		return
	end
	if (strProperty == 'Debug Mode') then
		if (value == 'Off') then
			DEBUGPRINT = false
			DbgLog = {}
			print('Debug Mode set to OFF')
			--Timer.Debug = Common.KillTimer (Timer.Debug)
		elseif (value == 'On') then
			DEBUGPRINT = true
			DbgSK('Debug Mode set to ON')
			--Timer.Debug = Common.AddTimer (Timer.Debug, 45, 'MINUTES')
		end
	end
	if (strProperty == Username_Prop) then 
	DbgSK("strProperty == 'userName'")
		parseUserName(value)
	end
	if (strProperty == User_Code_Prop) then 
	DbgSK("strProperty == 'userCode'")
		--if userCode == 0 then deleteChatId() end -- cancello ID se cambia userCode--fixme capire bene il giro
		userCode = value
	end
	if (strProperty == Telegram_Bot_Type) then 
		DbgSK("strProperty == 'Telegram_Bot_Type'")
			--if userCode == 0 then deleteChatId() end -- cancello ID se cambia userCode--fixme capire bene il giro
			BOT_TYPE = value
	end
	LICENSE_MGR:OnPropertyChanged(strProperty, value)
	--if (strProperty == License_Provider) then
	--	DbgSK("strProperty == 'License_Provider'") 
	--	LICENSE_MGR:ON_PROPERTY_CHANGED_LicenseProvider(value)
	--end
	--if (strProperty == HL_Licence_code) then 
	--	DbgSK("strProperty == 'HL_Licence_code'")
	--	LICENSE_MGR:ON_PROPERTY_CHANGED_HouselogixLicenseCode(value)
	--end
	--if (strProperty == SK_Licence_code) then 
	--	DbgSK("strProperty == 'SK_Licence_code'")
	--	LICENSE_MGR:ON_PROPERTY_CHANGED_SoftKiwiLicenseCode(value)
	--end
end

function userProperty()
	if USERTABLE[BOT_TYPE] == nil or tablelength(USERTABLE[BOT_TYPE]) == 0 then
		C4:SetPropertyAttribs(Username_Associated_Prop, 1)
		C4:UpdateProperty(Username_Associated_Prop, "")
	else
		local user = ""
		local n = 1
		for i,u in pairs(USERTABLE[BOT_TYPE]) do
			if u ~= "" then
				if n ~= 1 then user = user ..", "end
				user = user .. i
				n = n+1
			end
		end
		if user ~= "" then
			C4:SetPropertyAttribs(Username_Associated_Prop, 0)
			C4:UpdateProperty(Username_Associated_Prop, user)
		end
	end
end


function deleteChatId()
	for i,u in pairs(USERTABLE[BOT_TYPE]) do
		USERTABLE[BOT_TYPE][i] = nil
	end
	PersistData.USERTABLE[BOT_TYPE] = USERTABLE[BOT_TYPE]
	C4:UpdateProperty(Username_Prop, "")
	userProperty()
end


function ExecuteCommand (strCommand, tParams)
    --LUA Actions
	if (strCommand == "LUA_ACTION") then
		if (tParams["ACTION"] == "test_username") then
			DbgSK('Action: Test test_username')
			getUpdates()
		end
		if (tParams["ACTION"] == "act_bot") then
			DbgSK('Action: Test act_bot')
			botAct(name,msgen())
		end
		if (tParams["ACTION"] == "clear_user") then
			DbgSK('Action: Test clear_user')
			deleteChatId()
			PersistData.USERTABLE[BOT_TYPE] = USERTABLE[BOT_TYPE]
		end
	end
end

function OnDriverInit()
	print("----->>>>>>>>>>>>>>>>> ON_DRIVER_INIT.MainDriver <<<<<<<<<<<<<-----") --OKIO
	LICENSE_MGR:OnDriverInit()
	for k,v in pairs(Properties) do
		OnPropertyChanged(k)
	end
end

function OnDriverLateInit ()
	print("Driver Reloaded")
		--avviato al ri-avvio del driver per avere un ping (il math random evita che tutti i driver partano contemporaneamente)
	USERTABLE = PersistData.USERTABLE
	userProperty()
	--userCode = Properties[User_Code_Prop]
	--license_code = PersistData.license_code or 0
	--LICENSED = true
	if Common == nil then 
		Common = {}	
		DbgSK("Common")
	end
	if Timer== nil then
		Timer = {}
		DbgSK("Timer")
	end
	
	--[[if PersistData.used ~= nil then
		LICENSED = false
		HLicense_Activate()
	else
		Timer.license = Common.AddTimer (Timer.license, licenseTime, "HOURS", false)
	end]]--
	DEBUGPRINT =  Properties[ 'Debug Mode']
	--Timer.Query = Common.AddTimer (Timer.Query, math.random (3000, 7000), 'MILLISECONDS', false)
	C4:SetPropertyAttribs("Automatic Updates", 1)
	LICENSE_MGR:OnDriverLateInit() 
end

--===========  DEBUG EVOLUTO LR PER SVILUPPO ==============



function botAct(chat_ID,MESSAGE)
	if chat_ID == "" or chat_ID == nil or chat_ID == {} then
		if USERTABLE[BOT_TYPE] ~= nil then
			for i,u in pairs(USERTABLE[BOT_TYPE]) do
				--if u ~= "" then sendMessage(u, MESSAGE) end
				if u ~= "" then 
				--DbgSK("u :"..u..",  message "..MESSAGE)
					concat(u, MESSAGE) 
				end
			end
		end
	else
		--sendMessage(chat_ID, MESSAGE)
		concat(ChatID[BOT_TYPE], MESSAGE)
		                         
	end
	if queueInAction == nil then queueInAction = false end
		if queueInAction ==  false then
			--Strart timer
			DbgSK("queueInAction ==  false")
			Timer.queue = Common.AddTimer (Timer.queue, 2000, "MILLISECONDS", false) 
			queueInAction = true
		end       
 end
 

 
 
 function concat(chat_ID,MESSAGE)
	if messageTable == nil then messageTable = {} end
	--DbgSK("chat_ID :"..chat_ID.." ,message "..MESSAGE)
	if messageTable[chat_ID] == nil then messageTable[chat_ID] = "" end
	messageTable[chat_ID] = messageTable[chat_ID]..MESSAGE.."\n\r"
 end

 
function sendMessage(chat_ID,MESSAGE)
	if LICENSE_MGR:isAbleToWork() then 		
		if chat_ID ~= nil or chat_ID == {} then
			PATH = URL.."/bot"..BOT_KEYS_MAP[BOT_TYPE].."/sendMessage"
			DATA = "chat_id="..chat_ID.."&disable_web_page_preview=1&text="..MESSAGE
			ticketId = C4:urlPost(PATH, DATA)
			methodType[ticketId] = "POST"
		else
			print("CHAT ID unknow..")
		end
	else 
		print("YOUR ARE NOT LICENSED")
	end
end


function getUpdates()
	  link = URL.."/bot"..BOT_KEYS_MAP[BOT_TYPE].."/getUpdates"
	  --DbgSK(link)
	  tickedId = C4:urlGet(link)
	  methodType[tickedId] = "GET"
	  PersistData.used = PersistData.used or 0
	  PersistData.used = PersistData.used + 1
end 
 
 
--------------------------------------------------------------------------------------------------------------------------------------------
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--FUNZIONI DI SERVIZIO
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
--------------------------------------------------------------------------------------------------------------------------------------------

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
 
 
function tstring (tbl, indent)
--ritorna una stringa contenente i valori della table
	local  mytable = ""
  if not indent then indent = 0 end
  for k, v in pairs(tbl) do
    formatting = string.rep("   ", indent) .. k .. ": "
    if type(v) == "table" then
      mytable = mytable .. formatting
      mytable = mytable ..tstring(v, indent+1)
    else
      mytable = mytable .. formatting .. tostring(v) .." \n"
    end
  end
  return mytable
end


function parseUserName(EntryString)
	EntryString = string.lower(EntryString..",")
	--print(EntryString)
	local tmpUserT = {}
	for i in string.gmatch(EntryString, "([^,]+)") do
		i = string.gsub(i, ",", "") -- tolgo la virgola
		i = string.gsub(i, " ", "") -- tolgo la virgola
		tmpUserT[i] = ""
	end
	if USERTABLE[BOT_TYPE] ~= nil then
		for i,u in pairs(USERTABLE[BOT_TYPE]) do
			if tmpUserT[i] == nil then 
				USERTABLE[BOT_TYPE][i] = nil 
			else
				tmpUserT[i] = u
			end
		end
	end
	USERTABLE[BOT_TYPE] = tmpUserT
	--PersistData.USERTABLE[BOT_TYPE] = USERTABLE[BOT_TYPE]
    userProperty()
	--print("end parseUserName")
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

local bytemarkers = { {0x7FF,192}, {0xFFFF,224}, {0x1FFFFF,240} }

function utf8(decimal)
	if decimal<128 then return string.char(decimal) end
	local charbytes = {}
	for bytes,vals in ipairs(bytemarkers) do
		if decimal<=vals[1] then
			for b=bytes+1,2,-1 do
				local mod = decimal%64
				decimal = (decimal-mod)/64
				charbytes[b] = string.char(128+mod)
			end
			charbytes[1] = string.char(vals[2]+decimal)
			break
		end
	end
	return table.concat(charbytes)
end


function msgen()
	simplecounter=simplecounter+1
	return "message number "..simplecounter
end
 

function OnVariableChanged(strName)
	DbgSK('Variable '..strName..' changed')
	-- cambia la variabile... fai qualcosa
	botAct(nil,Variables["WriteToBot"])

	C4:SetVariable("WriteToBot","") -- pulisco la var
end

