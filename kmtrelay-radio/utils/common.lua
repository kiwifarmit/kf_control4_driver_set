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

function ReceivedFromProxy(idBinding, sCommand, tParams)
    -- avvio timer per 
    if PollInit == true then
	   poll_timer = StartPollTimer()
	   Dbg("PollInit Started by CMD")
	   PollInit = false
    end
	if (sCommand ~= nil) then
		if(tParams == nil)		-- initial table variable if nil
			then tParams = {}
		end
		--Dbg("ReceivedFromProxy(): " .. sCommand .. " on binding " .. idBinding .. "; Call Function " .. sCommand .. "()")
		--Dbg("ReceivedFromProxy(): " .. sCommand .. " on binding " .. idBinding .. "; Call Function " .. sCommand .. "()")
		--Dbg:Trace(tParams)
		if (PRX_CMD[sCommand]) ~= nil then
			PRX_CMD[sCommand](idBinding, tParams)
		else
			-- FIXME --Dbg:Alert("ReceivedFromProxy: Unhandled command = " .. sCommand)
		end
	end
end

