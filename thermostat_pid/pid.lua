local pid = {}

local function clamp(x, min, max)

  if x > max then
    return max
  elseif x < min then
    return min
  else
    return x
  end
end

local seconds = nil
do
  local done, socket = pcall(require, "socket")
  if not done then
    socket = nil
  end
  local done, computer = pcall(require, "computer")
  if not done then
    computer = nil
  end
  seconds = (socket and socket.gettime) or (computer and computer.uptime) or os.time
end



-- Creates a new PID controller.
-- Passing table as an argument will make it used as an object base.
-- It allows for convinient saving and loading of adjusted PID controller.
function pid:new(save)
  assert(save == nil or type(save) == "table", "If save is specified the it has to be table.")

  -- all values of the PID controller
  -- values with '_' at beginning are considered private and should not be changed.
  save = save or {
    kp = 1,
    ki = 1,
    kd = 1,
    input = nil,
    target = nil,
    output = nil,
    
    minout = -math.huge,
    maxout = math.huge,
    condition_on = 1,
    target_condition_on = "",
    threshold_off = nil,
    
    _lasttime = nil,
    _lastinput = nil,
    _Iterm = 0,
    _err = 0,
    _dinput = 0
    }
  setmetatable(save, self)
  self.__index = self
  return save
end

-- Exports calibration variables and targeted value.
function pid:save()
  return {threshold_off = self.threshold_off, target_condition_on= self.target_condition_on, kp = self.kp, ki = self.ki, kd = self.kd, target = self.target, minout = self.minout, maxout = self.maxout, input = self.input}
end

function pid:set_condition_on(condition)
  if condition == "SUMMER" then
    self.condition_on = -1
  elseif condition == "WINTER" then
    self.condition_on = 1
  end
end
-- This is main method of PID controller.
-- After creation of controller you have to set 'target' value in controller table
-- then in loop you should regularly update 'input' value in controller table,
-- call c:compute() and set 'output' value to the execution system.
-- c.minout = 0
-- c.maxout = 100
-- while true do
--   c.input = getCurrentEnergyLevel()
--   c:compute()
--   reactorcontrol:setAllControlRods(100 - c.output) -- PID expects the increase of output value will cause increase of input
--   sleep(0.5)
-- end
-- You can limit output range by specifying 'minout' and 'maxout' values in controller table.
-- By passing 'true' to the 'compute' function you will cause controller to not to take any actions but only
-- refresh internal variables. It is most useful if PID controller was disconnected from the system.
function pid:compute(waspaused)
  assert(self.input and self.target, "You have to sepecify current input and target before running compute()")
  -- print ("COMPUTING PID")
  -- reset values if PID was paused for prolonegd period of time
  if waspaused or self._lasttime == nil or self._lastinput == nil then
    self._lasttime = seconds()
    self._lastinput = self.input
    self._Iterm = self.output or 0
    -- print (1, "waspaused", waspaused, self._lasttime, self._lastinput)
    return
  end
  
  self._err = (self.target - self.input) * self.condition_on
  -- print("PID self._err", self._err)
  local dtime = seconds() - self._lasttime
  -- print("dtime", dtime)  
  if dtime == 0 then
    print(2, "dtime", dtime)
    return
  end

  self._Iterm = self._Iterm + self.ki * self._err * dtime
  -- print("self._Iterm prima", self._Iterm)
  self._Iterm = clamp(self._Iterm, self.minout, self.maxout)
  -- print("self._Iterm dopo", self._Iterm)
  self._dinput = ((self.input - self._lastinput) / dtime) * self.condition_on
  
  self.output = self.kp * self._err + self._Iterm - self.kd * self._dinput
  -- print("self.output prima", self.output)
  self.output = clamp(self.output, self.minout, self.maxout)
  -- print("self.output dopo", self.output)
  
  self._lasttime = seconds()
  self._lastinput = self.input
end

return pid

