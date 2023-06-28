local Utility = {}

function Utility.callAllFunctionsInTable(tbl)
	ret_err = {}
	ret_status = true
	for k,v in pairs(tbl) do
		if (tbl[k] ~= nil and type(tbl[k]) == "function") then
			-- 
			if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
				SKC4_LOGGER:debug("Calling  " .. k .. "()")
			end
			local status, err = pcall(tbl[k])
			if (not status) then
				ret_err[k] = {status=status, err=err}
			end
		end
	end
	return ret_status, ret_err
end

--remove the first element of a list
function Utility.remove(tbl, index)
	if (index == nil ) then index = 1 end
	local a = {}
	--local b = {}
	--local c
	for n,v in pairs(tbl) do 
		table.insert(a, n) 
	end
	table.sort(a)
	local f = nil
	local o = {}
	for i, t in pairs(a) do
		if (f == nil) then 
			f = tbl[t]
		else
			table.insert(o, tbl[t])
		end
	end
	 --Utility.tprint(b)
	return o, f
end

function Utility.tprint (tbl, indent)  --print table
	if type(tbl) == "table" then
		if not indent then indent = 0 end
		for k, v in pairs(tbl) do
			formatting = string.rep("   ", indent) .. k .. ": "
			if type(v) == "table" then
				print(formatting)
				Utility.tprint(v, indent+1)
			else
				print(formatting .. tostring(v, indent))
			end
		end
	else
		print (tbl)
	end
end

function Utility.tstring (tbl, indent) -- transform table in string, nested
	--ritorna una stringa contenente i valori della table
    --if indent is -1 return a table in one line string
	local  mytable = ""
	if indent == nil then indent = 0 end
	if (type(tbl) == "table") then
		if (indent == -1) then 
			for k,v in pairs(tbl) do
				if type(v) == "table" then
					mytable = mytable .. " "..Utility.tstring(v, -1)
				else
					mytable = mytable ..k.. " " .. tostring(v) 
				end
			end
		elseif(type(indent) == "number") then
			for k, v in pairs(tbl) do
				formatting = string.rep("   ", indent) .. k .. " : "
				if type(v) == "table" then
					mytable = mytable .. "\n"..formatting
					mytable = mytable .."\n"..Utility.tstring(v, indent+1)
				else
					mytable = mytable .. formatting .. tostring(v) .." \n"
				end
			end
		elseif(type(indent) == "string") then
			for k, v in pairs(tbl) do
				--formatting = string.rep("   ", indent) .. k .. " : "
				if type(v) == "table" then
					formatting = indent .. k
					mytable = mytable .. formatting
					mytable = mytable .. Utility.tstring(v, indent)
				else
					mytable = mytable ..indent .. tostring(v)
				end
				
			end
			mytable = mytable .."\n"
		end
	else 
		mytable = tbl
	end
	return mytable
end



--get the "very" first element of a Table... let's lua, not only if is key is a number like getn
function Utility.getFirstId(T)
	if (T == nil) then
		return {}
	else  
		local n  = 1
		local f
		for k, v in pairs(T) do
			if n == 1 then f = k end
		end
		return f
	end
end

function Utility.tableLength(T)
	local count = 0
	for _ in pairs(T) do count = count + 1 end
	return count
  end

--take "str" (string) and slpit it by "inSplitPattern" returning a table of the substring splitted in "outResults"(optional)
function Utility.split(str, inSplitPattern, outResults ) 
    if not outResults then
		outResults = {}
	end
	local theStart = 1
	local theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
	while theSplitStart do
		table.insert( outResults, string.sub( str, theStart, theSplitStart-1 ) )
		theStart = theSplitEnd + 1
		theSplitStart, theSplitEnd = string.find( str, inSplitPattern, theStart )
	end
	table.insert( outResults, string.sub( str, theStart ) )
	return outResults
end


function Utility.Avg_DevStd(value, stddev, avg, n)
    local delta = value - avg
    n = n+1
    avg = avg + delta / n 
    stddev = math.sqrt(((stddev*stddev * (n-1)) + delta*(value - avg))/n)
    return stddev, avg, n 
end

-- Private members
function pairsByKeys (t, f)
	local a = {}
	for n in pairs(t) do table.insert(a, n) end
	table.sort(a, f)
	local i = 0      -- iterator variable
	local iter = function ()   -- iterator function
	  i = i + 1
	  if a[i] == nil then return nil
	  else return a[i], t[a[i]]
	  end
	end
	return iter
end



return Utility



