local TimerManager = require "SKC4.TimerManager"
local Logger = require "SKC4.Logger"
local Utility = require("SKC4.Utility")

local LicenseManagerDriverCentral = {}

-- global var required by DriverCentral
-- DC_PID = 0 -- Product ID
-- DC_FD = false -- DriverCentral (Driver is not a free driver)
-- DC_FILENAME = "" -- "my_driver.c4z"

function LicenseManagerDriverCentral:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    return o
end

function LicenseManagerDriverCentral:init(productId, freeDriver, filename)
    if (productId) then
        self:setProductId(productId)
    end
    if (freeDriver) then
        self:setFreeDriver(freeDriver)
    end
    if (filename) then
        self:setFileName(filename)
    end
    require "SKC4.licence.cloud-client-byte"
end

--
-- Setter and Getter
--

function LicenseManagerDriverCentral:setProductId(value)
    rawset(_G, "DC_PID", value)
end
function LicenseManagerDriverCentral:getProductId()
    return DC_PID
end
function LicenseManagerDriverCentral:setFreeDriver(value)
    rawset(_G, "DC_FD", value)
end
function LicenseManagerDriverCentral:getFreeDriver()
    return DC_FD
end
function LicenseManagerDriverCentral:setFileName(value)
    rawset(_G, "DC_FILENAME", value)
    
end
function LicenseManagerDriverCentral:getFilename()
    return DC_FILENAME
end
--
-- Functions to test licence validity
--
function LicenseManagerDriverCentral:isLicenseActive()
    if (DC_X) then
        return (DC_X == 1)
    else
        return nil
    end
end

function LicenseManagerDriverCentral:isLicenseTrial()
    if (DC_X) then
        return (DC_X < 0)
    else
        return nil
    end
end

function LicenseManagerDriverCentral:isLicenseActiveOrTrial()
    return self:isLicenseActive() or self:isLicenseTrial()
end

function LicenseManagerDriverCentral:isAbleToWork()
    local lic = self:isLicenseActive()
    local trial = self:isLicenseTrial()
    return lic or trial
end


DC_LICENSE_MGR = DC_LICENSE_MGR or LicenseManagerDriverCentral:new()


return LicenseManagerDriverCentral

