-- Modulo per gestire i file di log

local Logger = {}

Utility = require "SKC4.Utility"

function Logger:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.logLevels = {
        ["FATAL"] = "F",
        ["ERROR"] = "EF",
        ["INFO"] = "IEF",
        ["WARN"] = "WIEF",
        ["TRACE"] = "WIEFT",
        ["DEBUG"] = "DWIETF",
        ["ONLY_INFO"] = "I",
        ["ONLY_WARN"] = "W",
        ["ONLY_ERROR"] = "E",
        ["ONLY_FATAL"] = "F",
        ["ONLY_TRACE"] = "T",
        ["ONLY_DEBUG"] = "D",
        ["NONE"] = "-",
        ["ALL"]  = "IWEFDT",
      }
      
    self._DEFAULT_OUTPUT_FORMAT     = "%s [%s] -- %s\n"
    self._DEFAULT_FILE_NAME_FORMAT  = "%s_%s.log"    
    self._DEFAULT_DATE_FORMAT       = "%Y%m%d%H%M%S"

    self._DEFAULT_FILE_POINTER      = io.stdio
    self._DEFAULT_FILE_NAME         = nil
    self._DEFAULT_FILE_PATH         = nil 
    self._DEFAULT_MAX_FILES         = 0
    
    self._currentMaxNumberOfFIles   = self._DEFAULT_MAX_FILES
    self._currentFilePointer        = self._DEFAULT_FILE_POINTER
    self._currentFilePath           = self._DEFAULT_FILE_PATH
    self._currentFileName           = self._DEFAULT_FILE_NAME
    self._currentLogLevel           = self.logLevels.INFO
    self._currentOutputFormat       = self._DEFAULT_OUTPUT_FORMAT
    self._currentFileNameFormat     = self._DEFAULT_FILE_NAME_FORMAT
    self._currentLogMaxSize         = 2097152 -- 2MB

    self._write_on_c4_logfile       = false
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
    
    if (self._currentFilePointer ~= nil and self._currentFilePointer ~= self._DEFAULT_FILE_POINTER) then
        self:rotate()
        C4:FileWrite(self._currentFilePointer,message:len(), message)
    end

    if self:isC4FileLoggingEnabled() then
        C4:DebugLog(message) -- print out on Director log files

        if ( self:isLogLevelEnabled(self.logLevels.ONLY_ERROR) or self:isLogLevelEnabled(self.logLevels.ONLY_FATAL) ) then
            C4:ErrorLog(message) 
        end 
    end
    
    print(message)    -- print out on Composer Lua Tab
    
    return message
end

function Logger:formattedWrite(level, ...)

    local arg = {...}
    local n=#arg
    local fullLevel = self:findLevelKey(level)
    local info = debug.getinfo(3,'nlS') or { source = "unknown", currentline = "unknown", what = "unknown" }

    local message = ""
    
    -- convert all params into strings
    -- starting from second argument
    --for a,b in pairs(arg) do 
    --    print(a,b)
    --end
    for index = 1, n do
        local val = arg[index]
    
        if (message.length == 0) then
            message = self:convertToString(val)
        else
            message = message .." "..self:convertToString(val)
        end
    end
    -- "%s %s:%s -- %s\n"
    local outString = string.format(self._currentOutputFormat,
        fullLevel,
        info.currentline,
        message)
    return self:write(outString)
end

function Logger:convertToString(obj)
    
    if (type(obj) == "table") then
        return Utility.tstring(obj, 0)
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

function Logger:isLoggingEnabled()
    return not self:isLogLevelEnabled(self.logLevels.NONE)
end

function Logger:disableLogging()
    self:setLogLevel(self.logLevels.NONE)
end

function Logger:enableInfoLevel()
    self:setLogLevel(self.logLevels.INFO)
end

function Logger:enableWarningLevel()
    self:setLogLevel(self.logLevels.WARN)
end

function Logger:enableErrorLevel()
    self:setLogLevel(self.logLevels.ERROR)
end

function Logger:enableFatalLevel()
    self:setLogLevel(self.logLevels.FATAL)
end

function Logger:enableTraceLevel()
    self:setLogLevel(self.logLevels.TRACE)
end

function Logger:enableDebugLevel()
    self:setLogLevel(self.logLevels.DEBUG)
end
function Logger:enableC4FileLogging()
    self._write_on_c4_logfile = true
end

function Logger:disableC4FileLogging()
    self._write_on_c4_logfile = false
end

function Logger:isC4FileLoggingEnabled()
    return self._write_on_c4_logfile
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

function Logger:info(...)
    if (self:isLogLevelEnabled(self.logLevels.ONLY_INFO)) then
        return self:formattedWrite(self.logLevels.INFO, ...);
    end 
end

function Logger:warn(...)
    if (self:isLogLevelEnabled(self.logLevels.ONLY_WARN)) then
        return self:formattedWrite(self.logLevels.WARN, ...);
    end 
end

function Logger:error(...)
    if (self:isLogLevelEnabled(self.logLevels.ONLY_ERROR)) then
        return self:formattedWrite(self.logLevels.ERROR, ...);
    end 
end

function Logger:fatal(...)
    if (self:isLogLevelEnabled(self.logLevels.ONLY_FATAL)) then
        return self:formattedWrite(self.logLevels.FATAL, ...);
    end 
end

function Logger:trace(...)
    if (self:isLogLevelEnabled(self.logLevels.ONLY_TRACE)) then
        return self:formattedWrite(self.logLevels.TRACE, ...);
    end 
end

function Logger:debug(...)
    if (self:isLogLevelEnabled(self.logLevels.ONLY_DEBUG)) then
        return self:formattedWrite(self.logLevels.DEBUG, ...);
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

SKC4_LOGGER = SKC4_LOGGER or Logger:new()

return Logger;

