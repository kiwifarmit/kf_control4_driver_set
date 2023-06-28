-- Modulo che simula il modulo nativo di Control 4
-- in modo da poter testare codice destinato a Control4
-- su computer

if (C4) then
  return C4
else
  local C4 = {}
  
  C4.currentDir = ""
  
  function C4:FileSetDir(path)
     self.currentDir = path
  end
  
  function C4:FileExists(path)
     local fullPath = self._JoinPaths(self.currentDir, path)
     return (io.open(fullPath, "r") ~= nil)
  end
  
  function C4:FileGetSize(filePointer)
    local current = filePointer:seek()      -- get current position
    local size = filePointer:seek("end")    -- get file size
    filePointer:seek("set", current)        -- restore position
    return size
  end
  
  function C4:FileWrite(filePointer, len, stringData)
   return len, filePointer:write(stringData)
  end
  
  function C4:FileGetDir()
     return self.currentDir
  end
  
  function C4:FileOpen(path)
     local fullPath = self._JoinPaths(self.currentDir, path)
     local fs = io.open(fullPath, "a+")
     return fs or -1
  end
  
  function C4:FileSetPos(filePointer, filePosition)
    filePointer:seek('set',0)
    return filePointer:seek('set',filePosition)
  end
  
	function C4:FileClose(filePointer)
		io.close(filePointer)
  end
    
  function C4:FileDelete(path, joinFlag)
    local fullPath=path

    if (joinFlag ~= nil and joinFlag ~= false  ) then
      fullPath = self._JoinPaths(self.currentDir, path)
    end

    return (os.remove(fullPath) ~= nil)
  end
    
  function C4:_JoinPaths(first, second)
    local ret = nil
    
    if first and second then
        ret = string.format("%s/%s", first, second)
    else
        ret = first or second
    end
    
    return ret
  end
    
    return C4
end
