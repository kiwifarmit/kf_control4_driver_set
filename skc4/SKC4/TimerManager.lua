--C4 = require 'SKC4.C4' -- if we are not in C4 env, I'll emulate it
local TimerManager = {}


function TimerManager:new (interval_delay, time_unit, on_expire_callback, will_repeat, o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.interval_delay = interval_delay
    o.callback = on_expire_callback
    o.will_repeat = will_repeat or false
    o.timerObj = nil
    o.created_at = os.time(os.date('!*t'))
    o.started_at = nil
    o.ended_at = nil
    -- , SECONDS, MINUTES and HOURS
    if (string.upper(time_unit) == "SECONDS") then
        o.time_unit = 1000
    elseif (string.upper(time_unit) == "MINUTES") then
        o.time_unit = 60*1000
    elseif (string.upper(time_unit) == "HOURS") then
        o.time_unit = 60*60*1000
    else
        o.time_unit = 1
    end 
    return o
end

function TimerManager:start()
    if (self.timerObj) then
        self:stop()
    end
    self.started_at = os.time(os.date('!*t'))
    self.timerObj = C4:SetTimer(self.interval_delay * self.time_unit,
                                function ()
                                    self.ended_at = os.time(os.date('!*t'))
                                    self.callback()
                                end,
                                self.will_repeat)
end

function TimerManager:stop()
    if (self.timerObj) then
        --self.timerObj = C4:KillTimer(self.timerObj)
        self.timerObj:Cancel()
        self.timerObj = nil
        self.started_at = nil
        self.ended_at = nil
    end
end

function TimerManager:is_running()
    return (self.started_at ~= nil and self.ended_at == nil)
end
--
-- Setter and Getter
--


--
-- Private functions
--


return TimerManager
