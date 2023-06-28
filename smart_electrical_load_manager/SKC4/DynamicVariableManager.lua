local DynamicVariableManager = {}

function DynamicVariableManager:new (o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function DynamicVariableManager:init()
  if (PersistData ~= nil) then  
    if (PersistData['SKC4_DYNAMIC_VARIABLES'] == nil) then 
        PersistData['SKC4_DYNAMIC_VARIABLES'] = {} 
    end
    self:RestoreAllVariables()
  end
end

function DynamicVariableManager:restoreAll()
  --ripristino variabili
  for index, v in pairs(PersistData['SKC4_DYNAMIC_VARIABLES']) do
    self:restoreVariable(v.name)
  end
end

function DynamicVariableManager:restoreVariable(strName)
  --ripristino variabili
  if ( PersistData['SKC4_DYNAMIC_VARIABLES']~= nil and PersistData['SKC4_DYNAMIC_VARIABLES'][strName]~= nil) then
    local v = PersistData['SKC4_DYNAMIC_VARIABLES'][strName]
    self:addVariable(v.name,v.value,v.varType,v.rw, v.hidden, v.callback)
  end
end

function DynamicVariableManager:addVariable(strName, strValue, strVarType, bReadOnly, bHidden, strCallback)
  local is_ok, variable_id = C4:AddVariable(strName, tostring(strValue), strVarType, bReadOnly, bHidden)
  if (is_ok) then
    --VARIABLE_ID_MAP[strName]=variable_id
    if ( ON_VARIABLE_CHANGED  ~= nil and strCallback ~= nil ) then  
      ON_VARIABLE_CHANGED[v.name] = function(varName) pcall(v.callback, varName) end
    end
    PersistData['SKC4_DYNAMIC_VARIABLES'][strName] = {
      name = strName,
      value = strValue,
      varType = strVarType,
      rw = bReadOnly,
      hidden = bHidden,
      callback = strCallback 
    }
    LOGGER:debug("Variable", strName, "has been created")
  else
    if (LOGGER ~= nil and type(LOGGER) == "table") then
      if (Variables[strName]) then
        LOGGER:error("Variable", strName, "already exists")
      else
        LOGGER:error("Unable to create", strName, "variable")
      end
    end
  end
end

function DynamicVariableManager:getVariable(strName)
  if (strName  ~= nil) then
    return Variables[strName]
  else
    if (LOGGER ~= nil and type(LOGGER) == "table") then
      LOGGER:error("No variable name!")
    end
  end
end

function DynamicVariableManager:setVariable(strName, strValue)
  --local variable_id = VARIABLE_ID_MAP[strName]
  if (strName  ~= nil) then
    local retVal = C4:SetVariable(strName, tostring(strValue))

    if (retVal ~= nil and PersistData['SKC4_DYNAMIC_VARIABLES'] ~= nil and PersistData['SKC4_DYNAMIC_VARIABLES'][strName] ~= nil) then
      PersistData['SKC4_DYNAMIC_VARIABLES'][strName].value = strValue
    end
  else
    if (LOGGER ~= nil and type(LOGGER) == "table") then
      LOGGER:error("No variable name!")
    end
  end

end

function DynamicVariableManager:deleteVariable(strName)
  if (strName  ~= nil) then
    local retVal = C4:DeleteVariable(strName)
    if (retVal ~= nil and PersistData['SKC4_DYNAMIC_VARIABLES'] ~= nil and PersistData['SKC4_DYNAMIC_VARIABLES'][strName] ~= nil) then
      PersistData['SKC4_DYNAMIC_VARIABLES'][strName] = nil
    end
  else
    if (LOGGER ~= nil and type(LOGGER) == "table") then
      LOGGER:error("No variable name!")
    end
  end
end


SKC4_DYNAMIC_VARIABLES = SKC4_DYNAMIC_VARIABLES or DynamicVariableManager:new()

return DynamicVariableManager;