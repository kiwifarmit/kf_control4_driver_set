local Queue = {}

function Queue:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self

  self._queue = {}
  self._first = 0
  self._last = -1
  return o
end

function Queue:push(object)
  local  key =  os.time(os.date('!*t'))
  local last = self._last + 1
  self._last = last
  self._queue[last] = {key = key, value = object}
end
function Queue:pop()
  if self:is_empty() then 
    return nil 
  end

  local first = self._first
  local item = self._queue[first]
  self._queue[first] = nil        -- to allow garbage collection
  self._first = first + 1
  return item.value
end

function Queue:push_by_key(key, object)
  local key_found = false
  -- look for existing item to update
  for i,item in pairs(self._queue) do
    if item.key == key then
      self._queue[i].value = object
      key_found = true
      break
    end
  end
  -- if no existing item, add it
  if (not key_found) then
    local last = self._last + 1
    self._last = last
    self._queue[last] = {key = key, value = object}
  end
end

function Queue:pop_by_key(key)
  if self:is_empty() then 
    return nil 
  end

  local returned_item = nil
  -- look for the item by key
  for i,item in pairs(self._queue) do
    if item.key == key then
      returned_item = item
    end

    -- if I found the item, strink the queue
    if returned_item then
      self._queue[i] = self._queue[i+1]
    end
  end

  -- if I found the item, reduce the lenght of queue
  if (returned_item) then
    local last = self._last
    self._queue[last] = nil
    self._last = last - 1
  end

  return returned_item
end

function Queue:size()
  local size = self._last - self._first + 1
  if size < 0 then
    size = 0
  end
  return size
end

function Queue:is_empty()
  return self:size() == 0
end

function Queue:empty()
  self._first = 0
  self._last = -1
  self._queue = nil
  self._queue = {}
end

function Queue.self_test()
  if (SKC4_LOGGER) then 
  
    SKC4_LOGGER:debug(":new()")
    local q = {}
    q = Queue:new()
    SKC4_LOGGER:debug("q is not nil:", not (q == nil))

    SKC4_LOGGER:debug("...queue is empty", q:is_empty(), "[",q:size(),"]")
    q:push("ciccio1")
    SKC4_LOGGER:debug("...successfully pushed 1 element", q:size() == 1, "[",q:size(),"]")
    q:push("ciccio2")
    q:push("ciccio3")
    SKC4_LOGGER:debug("...successfully pushed 3 elements", q:size() == 3, "[",q:size(),"]")
    local v = q:pop()
    SKC4_LOGGER:debug("...successfully poped 1 element", q:size() == 2, "[",q:size(),",",v,"]")
    v = q:pop()
    SKC4_LOGGER:debug("...successfully poped 1 element", q:size() == 1, "[",q:size(),",",v,"]")
    v = q:pop()
    SKC4_LOGGER:debug("...successfully poped 1 element", q:size() == 0, "[",q:size(),",",v,"]")
    v = q:pop()
    SKC4_LOGGER:debug("...successfully poped nil element", q:size() == 0, "[",q:size(),",",v,"]")
      

    SKC4_LOGGER:debug("...queue is empty", q:is_empty(), "[",q:size(),"]")
    q:push_by_key("uno","ciccio1")
    SKC4_LOGGER:debug("...successfully push_by_key 1 element with key", q:size() == 1, "[",q:size(),"]")
    q:push_by_key("due","ciccio2")
    q:push_by_key("tre","ciccio3")
    SKC4_LOGGER:debug("...successfully push_by_key 2 elements", q:size() == 3, "[",q:size(),"]")
    q:push_by_key("due","ciccio_due")
    q:push_by_key("tre","ciccio_tre")
    SKC4_LOGGER:debug("...successfully update 2 elements", q:size() == 3, "[",q:size(),"]")
    
    local v = q:pop_by_key("due")
    SKC4_LOGGER:debug("...successfully pop_by_key 1 element", q:size() == 2, "[",q:size(),",",v,"]")
    v = q:pop_by_key("uno")
    SKC4_LOGGER:debug("...successfully pop_by_key 1 element", q:size() == 1, "[",q:size(),",",v,"]")
    v = q:pop_by_key("due")
    SKC4_LOGGER:debug("... fail to pop pop_by_key element", q:size() == 1, "[",q:size(),",",v,"]")
    v = q:pop()
    SKC4_LOGGER:debug("...successfully poped 1 element", q:size() == 0, "[",q:size(),",",v,"]")
    v = q:pop()
    SKC4_LOGGER:debug("...successfully poped nil element", q:size() == 0, "[",q:size(),",",v,"]")

    SKC4_LOGGER:debug("queue is", q._queue)
  else
    print("Please make SKC4_LOGGER available befor run self_test")
  end
end

return Queue