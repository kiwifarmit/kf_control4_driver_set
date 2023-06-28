local Debug = {}

print("Debug.lua is DEPRECATED")

Debug.DEBUGPRINT = true

function Debug.debug(message)
    if (Debug.DEBUGPRINT) then
        print(message);
	else
        message = ""
    end 
end

function Debug.tprint (tbl, indent)  --print table
	if type(tbl) == "table" then
		if not indent then indent = 0 end
		for k, v in pairs(tbl) do
			formatting = string.rep("   ", indent) .. k .. ": "
			if type(v) == "table" then
				print(formatting)
				Debug.tprint(v, indent+1)
			else

				print(formatting .. tostring(v, indent))
			end
		end
	else

		print (tbl)
	end
end

function Debug.tstring (tbl, indent) -- transform table in string, nested
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
					mytable = mytable .. formatting
					mytable = mytable ..Debug.tstring(v, indent+1)
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

return Debug;