local TimerManager = require "SKC4.TimerManager"
--local Logger = require "SKC4.Logger"
--Logger:setLogLevel(LOG_LEVELS.DEBUG..LOG_LEVELS.ERROR)

local LicenseManager = {}

-- global var required by DriverCentral
DC_PID = 0 -- Product ID
DC_FD = false -- DriverCentral (Driver is not a free driver)
DC_FILENAME = "" -- "my_driver.c4z"

LicenseManager.TRIAL_NOT_STARTED = -1
LicenseManager.TRIAL_STARTED = 1
LicenseManager.TRIAL_EXPIRED = 0

function LicenseManager:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    self.currentVendorId = "DRIVERCENTRAL"
    self.statusMessage = ""
    self.vendorData = {
        DRIVERCENTRAL 	= { 
            ProductId 	= 000, -- Product ID
            FreeDriver 	= false, -- (Driver is not a free driver)
            FileName    = ""
        },
        HOUSELOGIX		= { 
            LicenseCode = "",
            ProductId 	= 000,
            ValidityCheckInterval = 60,
            --TrialExpiredLapse = 72,
            TrialExpiredLapse = 10,
            Licensed = false,
            Trial = LicenseManager.TRIAL_NOT_STARTED,  -- -1 not started, 1 started , 0 expired  -- only one possibility to stard it
            Version = ""
        }
    }

    self.houselogixTimerCheck = {}
    self.houselogixTimerTrial = {}
    return o
end

--
-- Setter and Getter
--

function LicenseManager:ON_PROPERTY_CHANGED_LicenseProvider(value)
	print("ON_PROPERTY_CHANGED.LicenseProvider.",value, type(value))
	--LicenseProvider = value
	LICENSE_MGR:setCurrentVendorIdByName(value)
end
function LicenseManager:ON_PROPERTY_CHANGED_HouselogixLicenseCode (value)
	--dbg("ON_PROPERTY_CHANGED.HouselogixLicenseCode."..value)
	HouselogixLicenseCode = value
    LICENSE_MGR:setParamValue("LicenseCode", HouselogixLicenseCode, "HOUSELOGIX") -- Filename -- DD394AB4A8CA48BB
    LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
    LICENSE_MGR:Houselogix_Activate()	
end



function LicenseManager:setStatusMessage( message )
    self.statusMessage = message
    C4:UpdateProperty ('Houselogix License Status', message)
end
function LicenseManager:getStatusMessage()
    return self.statusMessage
end

function LicenseManager:setCurrentVendorId(vendor_id)
    self.currentVendorId = vendor_id

    if vendor_id == "DRIVERCENTRAL" then
        print ("DRIVERCENTRAL vendor setted")
        C4:SetPropertyAttribs("Cloud Status", 0)
        C4:SetPropertyAttribs("Automatic Updates", 1)
        C4:SetPropertyAttribs("Houselogix License Code", 1)
        C4:SetPropertyAttribs("Houselogix License Status", 1)
    elseif vendor_id == "HOUSELOGIX" then
        print ("HOUSELOGIX vendor setted")
        C4:SetPropertyAttribs("Cloud Status", 1)
        C4:SetPropertyAttribs("Automatic Updates", 1)
        C4:SetPropertyAttribs("Houselogix License Code", 0)
        C4:SetPropertyAttribs("Houselogix License Status", 0)
    else
        print ("UNKNOW vendor setted")
        C4:SetPropertyAttribs("Cloud Status", 1)
        C4:SetPropertyAttribs("Automatic Updates", 1)
        C4:SetPropertyAttribs("Houselogix License Code", 1)
        C4:SetPropertyAttribs("Houselogix License Status", 1)
    end
    
end
function LicenseManager:getCurrentVendorId()
    return self.currentVendorId
end

function LicenseManager:setCurrentVendorIdByName(value)
    if (value == "Driver Central") then
        self:setCurrentVendorId("DRIVERCENTRAL")
    elseif (value == "Houselogix") then
        self:setCurrentVendorId("HOUSELOGIX")
        self:trialTimerHandlerHouselogix()
    end
end
function LicenseManager:trialTimerHandlerHouselogix()
    local trialExpiredLapse = self:getParamValue("TrialExpiredLapse", "HOUSELOGIX") 
    if self:getParamValue("Trial", "HOUSELOGIX") == LicenseManager.TRIAL_NOT_STARTED then
        self:setParamValue("Trial", LicenseManager.TRIAL_STARTED, "HOUSELOGIX") 
        self.houselogixTimerTrial = TimerManager:new(trialExpiredLapse, "HOURS", self.onHouselogixTimerTrialExpire, false)
        self:setStatusMessage('Trial mode')
        self.houselogixTimerTrial:start()
    elseif self:getParamValue("Trial", "HOUSELOGIX") == LicenseManager.TRIAL_STARTED then
    elseif self:getParamValue("Trial", "HOUSELOGIX") == LicenseManager.TRIAL_EXPIRED then 
        self:Houselogix_Activate()
    else
        print ("Houeselogix Trial unknow state: "..(tostring(self:getParamValue("Trial", "HOUSELOGIX")) or "nil"))
    end
end

function LicenseManager:setParamValue(param_key, param_value, vendor_id)

    if (vendor_id) then
        --print("setParamValue with vendor_id")
        self.vendorData[vendor_id][param_key] = param_value
    else
        --print("setParamValue with automagic vendor_id")
        local autoVendorId = self:getCurrentVendorId()
        --print (autoVendorId)
        self.vendorData[autoVendorId][param_key] = param_value
    end
end
function LicenseManager:getParamValue(param_key, vendor_id)
    if (vendor_id) then
        return self.vendorData[vendor_id][param_key]
    else
        return self.vendorData[self:getCurrentVendorId()][param_key]
    end
end

--
-- Functions to test licence validity
--
function LicenseManager:isLicenseActive()
    if self:getCurrentVendorId() == "DRIVERCENTRAL" then
        return (DC.X == 1)
    elseif self:getCurrentVendorId() == "HOUSELOGIX" then
        return self:getParamValue("Licensed", "HOUSELOGIX")
    else
        return false
    end
end
function LicenseManager:isLicenseTrial()
    if self:getCurrentVendorId() == "DRIVERCENTRAL" then
        return (DC.X < 0)
    elseif self:getCurrentVendorId() == "HOUSELOGIX" then
        return self:getParamValue("Trial", "HOUSELOGIX")
    else
        return false
    end
end

function LicenseManager:isLicenseActiveOrTrial()
    return self:isLicenseActive() or self:isLicenseTrial()
end

function LicenseManager:isAbleToWork()
    local lic = self:isLicenseActive()
    local trial = self:isLicenseTrial() == 1 --this return 0,-1,1 and all this values are true in a if condition check
    return lic or trial
end

--
-- C4 Enviroment hooks
--

function LicenseManager:OnDriverInit()
    C4:SetPropertyAttribs("Cloud Status", 1)
    C4:SetPropertyAttribs("Automatic Updates", 1)
    C4:SetPropertyAttribs("Houselogix License Code", 1)
    C4:SetPropertyAttribs("Houselogix License Status", 1)
    
    self.vendorData = PersistData.vendorData or self.vendorData
    PersistData.vendorData = self.vendorData

    self:OnDriverInit_HouseLogix()
    self:OnDriverInit_DriverCentral()    
end

function LicenseManager:OnDriverLateInit()

    self:OnDriverLateInit_HouseLogix()    
    self:OnDriverLateInit_DriverCentral()    
end

--
-- Vendor specific functions
--
function LicenseManager:OnDriverInit_DriverCentral()
    require "json"
	JSON=(loadstring(json.JSON_LIBRARY_CHUNK))()
    -- set global vars required by DriverCentral.io
    DC_PID = self:getParamValue("ProductId", "DRIVERCENTRAL") 
	DC_FD = self:getParamValue("FreeDriver", "DRIVERCENTRAL") 
    DC_FILENAME = self:getParamValue("FileName", "DRIVERCENTRAL") 
    
    require "SKC4.licence.cloud_client_v1007"
end
function LicenseManager:OnDriverLateInit_DriverCentral()
    -- do something...
end

---------------
-- HouseLogix
---------------
function LicenseManager:OnDriverInit_HouseLogix()
    -- do something...
end
function LicenseManager:OnDriverLateInit_HouseLogix()   
    if self:getParamValue("Trial", "HOUSELOGIX") == LicenseManager.TRIAL_STARTED then
        local trialExpiredLapse = self:getParamValue("TrialExpiredLapse", "HOUSELOGIX") 
        self.houselogixTimerTrial = TimerManager:new(trialExpiredLapse, "HOURS", self.onHouselogixTimerTrialExpire, false)
        self.houselogixTimerTrial:start()
    end
end

function LicenseManager:onHouselogixTimerExpire(ticketId, sData, responseCode, tHeaders)
    
    if (LICENSE_MGR:getCurrentVendorId() == "HOUSELOGIX") then
        LICENSE_MGR:Houselogix_Activate()	
    end
end

function LicenseManager:onHouselogixTimerTrialExpire(ticketId, sData, responseCode, tHeaders)
    print ("Houselogix Trial timer Expired!")
    LICENSE_MGR:setParamValue("Trial", LicenseManager.TRIAL_EXPIRED, "HOUSELOGIX") 
    if (LICENSE_MGR:getCurrentVendorId() == "HOUSELOGIX") then
        LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
        LICENSE_MGR:Houselogix_Activate()	
    end
end



--- -----------------------------------------------------------------
--- HOUSELOGIX LICENSE_MGR MANAGER
--- -----------------------------------------------------------------


function LicenseManager:Houselogix_Activate()
  self:setStatusMessage('Activating driver license...')
  mac = C4:GetUniqueMAC ()

  local license_code = self:getParamValue("LicenseCode", "HOUSELOGIX")
  local Houselogix_product_number = self:getParamValue("ProductId", "HOUSELOGIX")
  local sw_version = self:getParamValue("Version", "HOUSELOGIX")
  local postData = string.format('lic=%s&mac=%s&p=%s&ver=%s', license_code, mac, Houselogix_product_number, sw_version)
  --dbg (postData)
  ticketId = C4:urlPost('https://www.houselogix.com/license-manager/activatelicense.asp', postData, {}, false, self.Houselogix_Response)
  --methodType[ticketId] = "HLicense_Activate" -- QUESTA SERVE ANCORA? TOFIX
end

function LicenseManager.Houselogix_Response(ticketId, data, responseCode, tHeaders, strError )
  print('OnLicenseActivationResponseReceived')
  --dbg(ticketId)
  --dbg(data)
  local i = string.find(data, 'Valid')
  if (i) then
    LICENSE_MGR:setParamValue("Licensed", true, "HOUSELOGIX")
    LICENSE_MGR:setStatusMessage('Activated (last checked on: '..os.date("%m/%d/%Y %X")..')')
  elseif (string.find(data, 'Unauthorized')) then
    LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
    LICENSE_MGR:setStatusMessage('Invalid license key')
    --LICENSE_MGR.houselogixTimerCheck = TimerManager:new(60, "MINUTES", LICENSE_MGR.onHouselogixTimerExpire, false)
    --LICENSE_MGR.houselogixTimerCheck:start()
    print("License is NOT ok")
  elseif (string.find(data, 'Failed')) then
    if LICENSE_MGR:getParamValue("Licensed", "HOUSELOGIX") then 
        LICENSE_MGR:setParamValue("Licensed", true, "HOUSELOGIX")
    else
        LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
    end
    LICENSE_MGR:setStatusMessage('Failed to verify')
    --LICENSE_MGR.houselogixTimerCheck = TimerManager:new(60, "MINUTES", LICENSE_MGR.onHouselogixTimerExpire, false)
    --LICENSE_MGR.houselogixTimerCheck:start()
  else
   -- LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
    LICENSE_MGR:setStatusMessage(strError)
    
  end
  local checkInterval =  LICENSE_MGR:getParamValue("ValidityCheckInterval", "HOUSELOGIX") 
  LICENSE_MGR.houselogixTimerCheck = TimerManager:new(checkInterval, "MINUTES", LICENSE_MGR.onHouselogixTimerExpire, false)
  LICENSE_MGR.houselogixTimerCheck:start()
  --return HLicense
end


-- return LicenseManager

LICENSE_MGR = LICENSE_MGR or LicenseManager:new()

