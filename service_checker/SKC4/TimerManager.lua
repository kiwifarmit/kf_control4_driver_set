--C4 = require 'SKC4.C4' -- if we are not in C4 env, I'll emulate it
local TimerManager = {}


function TimerManager:new (interval_delay, time_unit, on_expire_callback, will_repeat, o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    self.interval_delay = interval_delay
    self.callback = on_expire_callback
    self.will_repeat = will_repeat
    self.timerObj = nil
    self.created_at = os.time(os.date('!*t'))
    self.started_at = nil
    -- , SECONDS, MINUTES and HOURS
    if (time_unit == "SECONDS") then
        self.time_unit = 1000
    elseif (time_unit == "MINUTES") then
        self.time_unit = 60*1000
    elseif (time_unit == "HOURS") then
        self.time_unit = 60*60*1000
    else
        self.time_unit = 1
    end 
    return o
end

function TimerManager:start()
    if (self.timerObj) then
        self:stop()
    end
    self.started_at = os.time(os.date('!*t'))
    self.timerObj = C4:SetTimer(self.interval_delay * self.time_unit, self.callback, self.will_repeat)
end

function TimerManager:stop()
    if (self.timerObj) then
        --self.timerObj = C4:KillTimer(self.timerObj)
        self.timerObj:Cancel()
        self.timerObj = nil
        self.started_at = nil
    end
end

--
-- Setter and Getter
--


--
-- Private functions
--


return TimerManager
