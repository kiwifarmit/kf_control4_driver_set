-- Modulo per gestire i file di log

local Logger = {}

ut = require "SKC4/Utility"
--local C4 = require("SKC4/C4")

function Logger:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.logLevels = {
      ["INFO"] = "I",
      ["WARN"] = "W",
      ["ERROR"] = "E",
      ["FATAL"] = "F",
      ["DEBUG"] = "D",
      ["NONE"] = "-",
      ["ALL"]  = "IWEFD",
      }
    self._DEFAULT_OUTPUT_FORMAT     = "%s %s:%s -- %s\n"
    self._DEFAULT_FILE_NAME_FORMAT  = "%s_%s.log"    
    self._DEFAULT_DATE_FORMAT       = "%Y%m%d%H%M%S"

    self._DEFAULT_FILE_POINTER      = io.stdio
    self._DEFAULT_FILE_NAME         = nil
    self._DEFAULT_FILE_PATH         = nil 
    self._DEFAULT_MAX_FILES         = 0
    
    self._currentMaxNumberOfFIles        = self._DEFAULT_MAX_FILES
    self._currentFilePointer        = self._DEFAULT_FILE_POINTER
    self._currentFilePath           = self._DEFAULT_FILE_PATH
    self._currentFileName           = self._DEFAULT_FILE_NAME
    self._currentLogLevel           = self.logLevels.INFO
    self._currentOutputFormat       = self._DEFAULT_OUTPUT_FORMAT
    self._currentFileNameFormat     = self._DEFAULT_FILE_NAME_FORMAT
    self._currentLogMaxSize         = 2097152 -- 2MB
    return o
end

function Logger:findLevelKey(level)
  for k,v in pairs(self.logLevels) do
    if (v == level) then
      return k
    end
  end
  return nil
end

function Logger:write(message)
    self:rotate()    
    if (self._currentFilePointer ~= nil and self._currentFilePointer ~= self._DEFAULT_FILE_POINTER) then
        C4:FileWrite(self._currentFilePointer,message:len(), message)
    else
        print(message)    --because C4 do not open by default the io.stdio like file_pointer 
	end    
    return message
end

--function Logger:formattedWrite(level, source, message)
function Logger:formattedWrite(...)
    --local fullLevel = self:findLevelKey(level)
    --local outString = string.format(self._currentOutputFormat,
    --    fullLevel,
    --    os.date("%m/%d/%Y %H:%M:%S"),
    --    source,
    --    message)
    local level,source,message
    if ... then
		level = select(1, ...)
		source = select(2, ...)
		message = select(3, ...)
    end
    local fullLevel = self:findLevelKey(level)
    local info = debug.getinfo(3,'lS');

    local message = ""

    -- convert all params into strings
    for key,val in ipairs(...) do
        if (message.length == 0) then
            message = self:convertToString(val)
        else
            message = message .." "..self:convertToString(val)
        end
    end
    
    local outString = string.format(self.currentOutputFormat,
        fullLevel,
        info.source,
        info.currentline,
        message)
    return self:write(outString)
end

function Logger:convertToString(obj)
    local encoded = json.encode( obj, { indent=true } )

    if (type(obj) == "table") then
    if not encoded then
        -- LOGGER:debug( "Table encoding failed")
        return tostring(obj)
    else
        -- LOGGER:debug( "Table successfully encoded!" )
        return encoded
    end
    else
        return tostring(obj)
    end
end

function Logger:setLogLevel(level)
  local flag = true
  
  for x in level:gfind(".") do
    key = self:findLevelKey(x)
    self._currentLogLevel = self.logLevels.NONE;
    if (self.logLevels[key] == nil) then flag = false; break; end
  end
  if ( flag == true ) then
      self._currentLogLevel = level
  end

end

function Logger:getLogLevel(level)
    return self._currentLogLevel;
end

function Logger:isLogLevelEnabled(level)
  return (self._currentLogLevel:find(level) ~= nil) 
end


function Logger:open(filePath, fileName)
  self._currentFilePath = filePath
  self._currentFileName = fileName 
  
  C4:FileSetDir(self._currentFilePath)  --move in file path folder

  logFileName = string.format(self._currentFileNameFormat, fileName, os.date(self._DEFAULT_DATE_FORMAT));
  -- Open the file
  self._currentFilePointer = C4:FileOpen(logFileName)
  local pos = C4:FileGetSize(self._currentFilePointer)
  C4:FileSetPos(self._currentFilePointer, pos)

  C4:FileSetDir('/')
  return self._currentFilePointer, logFileName
end

function Logger:close()
    -- only if a file is open
  if (self._currentFilePointer ~= self._DEFAULT_FILE_POINTER) then
    
    -- Close the file
    if (self._currentFilePointer ~= nil) then
        C4:FileClose(self._currentFilePointer)
        --self._currentFilePointer:close()
        self._currentFilePointer = self._DEFAULT_FILE_POINTER
        self._currentFilePath = nil
        self._currentFileName = nil
    end
  end
end

function Logger:info(source, message)
    if (self:isLogLevelEnabled(self.logLevels.INFO)) then
        return self:formattedWrite(self.logLevels.INFO, source, message);
    end 
end

function Logger:warn(source, message)
    if (self:isLogLevelEnabled(self.logLevels.WARN)) then
        return self:formattedWrite(self.logLevels.WARN, source, message);
    end 
end

function Logger:error(source, message)
    if (self:isLogLevelEnabled(self.logLevels.ERROR)) then
        return self:formattedWrite(self.logLevels.ERROR, source, message);
    end 
end

function Logger:fatal(source, message)
    if (self:isLogLevelEnabled(self.logLevels.FATAL)) then
        return self:formattedWrite(self.logLevels.FATAL, source, message);
    end 
end

function Logger:debug(source, message)
    if (self:isLogLevelEnabled(self.logLevels.DEBUG)) then
        return self:formattedWrite(self.logLevels.DEBUG, source, message);
    end 
end

function Logger:setMaxLogSize( size )
  self._currentLogMaxSize = size
end

function Logger:setMaxLoggersNumber( number )
    self._currentMaxNumberOfFIles = number
  end

function Logger:getMaxLogSize()
  return self._currentLogMaxSize
end

function Logger:getFilePointer()
    return self._currentFilePointer
end

function Logger:getFilePath()
    return self._currentFilePath
end

function Logger:getFileName()
    return self._currentFileName
end

function Logger:rotate(force)
    if (self._currentFilePointer ~= self._DEFAULT_FILE_POINTER) then
        local fileSize = C4:FileGetSize(self._currentFilePointer)
        
        if (self._currentMaxNumberOfFIles ~= self._DEFAULT_MAX_FILES) then 
            local loggersNumber = self:getLoggersNumber()
            print ("loggersNumber", loggersNumber)
            while (loggersNumber >= self._currentMaxNumberOfFIles) do
                print ("loggersNumber >= self._currentMaxNumberOfFIles",loggersNumber >= self._currentMaxNumberOfFIles)
                self:removeFirst()
                loggersNumber = self:getLoggersNumber()
            end
        end
        if (force ~= nil or tonumber(fileSize) > self._currentLogMaxSize) then
            local oldPath = self._currentFilePath -- store old value 'cause close() clear _currentFilePath
            local oldName = self._currentFileName -- store old value 'cause close() clear _currentFileName
            self:close() 
            return self:open(oldPath,oldName)
        else
            return self._currentFilePointer, self._currentFilePath, self._currentFileName
        end
    end
end

--private
function Logger:getLoggersNumber()    
    C4:FileSetDir(self._currentFilePath)
    local loggerList = C4:FileList()
    local count = 0
    for k,v in pairs(loggerList) do
        ----print (k,v) 
        if (string.match(v, self._currentFileName)) then 
            ----print (string.match(v, self._currentFileName))
            count = count + 1 
        end
    end
    C4:FileSetDir("/")
    return count 
end

function Logger:removeFirst()    
    C4:FileSetDir(self._currentFilePath)
    local loggerList = C4:FileList()
    local count = 0
    ----------------20171204114408
    local minimum = 30000000000000
    local fileToRemove = ""
    for k,v in pairs(loggerList) do 
        if (string.match(v, self._currentFileName)) then 
            ----print (string.match(v, self._currentFileName))
            local n = tonumber(string.match (v, "(%d+)"))
            ----print ("n:  ", n)
            ----print ("file:  ", v)
            if ( n < minimum ) then 
                minimum = n
                fileToRemove = v 
            end
        end
    end

    ----print (fileToRemove, minimum)
    if (fileToRemove ~= "") then  
        print("deleting logger :",fileToRemove)
        C4:FileDelete(fileToRemove) 
    end
    C4:FileSetDir("/")
    return count 
end


return Logger;

