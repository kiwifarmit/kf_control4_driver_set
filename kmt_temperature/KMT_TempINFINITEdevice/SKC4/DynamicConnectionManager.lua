local DynamicConnectionManager = {}

-- function DynamicConnectionManager:new (o)
--     o = o or {}
--     setmetatable(o, self)
--     self.__index = self
--     return o
-- end

-- function DynamicConnectionManager:init()
--   if (PersistData ~= nil) then  
--     if (PersistData['SKC4_DYNAMIC_CONNECTIONS'] == nil) then 
--         PersistData['SKC4_DYNAMIC_CONNECTIONS'] = {} 
--     end
--     self:RestoreAllConnections()
--   end
-- end

-- function DynamicConnectionManager:addConnection(strName, strValue, strVarType, bReadOnly, bHidden, strCallback)
--   local is_ok, connection_id = C4:AddConnection(strName, tostring(strValue), strVarType, bReadOnly, bHidden)
--   if (is_ok) then
--     --CONNECTION_ID_MAP[strName]=connection_id
--     if ( ON_CONNECTION_CHANGED  ~= nil and strCallback ~= nil ) then  
--       ON_CONNECTION_CHANGED[v.name] = function(varName) pcall(v.callback, varName) end
--     end
--     PersistData['SKC4_DYNAMIC_CONNECTIONS'][strName] = {
--       name = strName,
--       value = strValue,
--       varType = strVarType,
--       rw = bReadOnly,
--       hidden = bHidden,
--       callback = strCallback 
--     }
--     LOGGER:debug("Connection", strName, "has been created")
--   else
--     if (LOGGER ~= nil and type(LOGGER) == "table") then
--       if (Connections[strName]) then
--         LOGGER:error("Connection", strName, "already exists")
--       else
--         LOGGER:error("Unable to create", strName, "connection")
--       end
--     end
--   end
-- end

-- function DynamicConnectionManager:getConnection(strName)
--   if (strName  ~= nil) then
--     return Connections[strName]
--   else
--     if (LOGGER ~= nil and type(LOGGER) == "table") then
--       LOGGER:error("No connection name!")
--     end
--   end
-- end

-- function DynamicConnectionManager:setConnection(strName, strValue)
--   --local connection_id = CONNECTION_ID_MAP[strName]
--   if (strName  ~= nil) then
--     local retVal = C4:SetConnection(strName, tostring(strValue))

--     if (retVal ~= nil and PersistData['SKC4_DYNAMIC_CONNECTIONS'] ~= nil and PersistData['SKC4_DYNAMIC_CONNECTIONS'][strName] ~= nil) then
--       PersistData['SKC4_DYNAMIC_CONNECTIONS'][strName].value = strValue
--     end
--   else
--     if (LOGGER ~= nil and type(LOGGER) == "table") then
--       LOGGER:error("No connection name!")
--     end
--   end

-- end

-- function DynamicConnectionManager:deleteConnection(strName)
--   if (strName  ~= nil) then
--     local retVal = C4:DeleteConnection(strName)
--     if (retVal ~= nil and PersistData['SKC4_DYNAMIC_CONNECTIONS'] ~= nil and PersistData['SKC4_DYNAMIC_CONNECTIONS'][strName] ~= nil) then
--       PersistData['SKC4_DYNAMIC_CONNECTIONS'][strName] = nil
--     end
--   else
--     if (LOGGER ~= nil and type(LOGGER) == "table") then
--       LOGGER:error("No connection name!")
--     end
--   end
-- end

-- function DynamicConnectionManager:restoreAll()
--   --ripristino variabili
--   for index, v in pairs(PersistData['SKC4_DYNAMIC_CONNECTIONS']) do
--     self:restoreConnection(v.name)
--   end
-- end

-- function DynamicConnectionManager:restoreConnection(strName)
--   --ripristino variabili
--   if ( PersistData['SKC4_DYNAMIC_CONNECTIONS']~= nil and PersistData['SKC4_DYNAMIC_CONNECTIONS'][strName]~= nil) then
--     local v = PersistData['SKC4_DYNAMIC_CONNECTIONS'][strName]
--     self:addConnection(v.name,v.value,v.varType,v.rw, v.hidden, v.callback)
--   end
-- end


-- SKC4_DYNAMIC_CONNECTIONS = SKC4_DYNAMIC_CONNECTIONS or DynamicConnectionManager:new()

return DynamicConnectionManager;