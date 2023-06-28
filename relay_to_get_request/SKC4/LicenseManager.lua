local TimerManager = require "SKC4.TimerManager"
local Logger = require "SKC4.Logger"
local Utility = require("SKC4.Utility")

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
            TrialExpiredLapse = 10,
            Licensed = false,
            Trial = LicenseManager.TRIAL_NOT_STARTED,  -- -1 not started, 1 started , 0 expired  -- only one possibility to stard it
            Version = ""
        },
        SOFTKIWI 	= { 
            LicenseCode = "",
            Licensed = false
        },
    }

    self.houselogixTimerCheck = {}
    self.houselogixTimerTrial = {}    

    self.OnPropertyChangedTable = {}
    self.OnPropertyChangedTable["License Provider"]        = LicenseManager.SKC4_ON_PROPERTY_CHANGED_LicenseProvider
    self.OnPropertyChangedTable["Houselogix License Code"] = LicenseManager.SKC4_ON_PROPERTY_CHANGED_HouselogixLicenseCode
    self.OnPropertyChangedTable["SoftKiwi License Code"]   = LicenseManager.SKC4_ON_PROPERTY_CHANGED_SoftKiwiLicenseCode

    
    return o
end

--
-- Setter and Getter
--


function LicenseManager:setStatusMessage( message )
    self.statusMessage = message
    if self:getCurrentVendorId() == "DRIVERCENTRAL" then
        C4:UpdateProperty ('Houselogix License Status', "")
        C4:UpdateProperty ('SoftKiwi License Status', "")
    elseif self:getCurrentVendorId() == "HOUSELOGIX" then
        C4:UpdateProperty ('Houselogix License Status', message)
        C4:UpdateProperty ('SoftKiwi License Status', "")
    elseif self:getCurrentVendorId() == "SOFTKIWI" then
        C4:UpdateProperty ('Houselogix License Status', "")
        C4:UpdateProperty ('SoftKiwi License Status', message)
    else
        C4:UpdateProperty ('Houselogix License Status', "")
        C4:UpdateProperty ('SoftKiwi License Status', "")
    end
end

function LicenseManager:getStatusMessage()
    return self.statusMessage
end

function LicenseManager:setCurrentVendorId(vendor_id)
    self.currentVendorId = vendor_id
    
    if vendor_id == "DRIVERCENTRAL" then
        SKC4_LOGGER:info("DRIVERCENTRAL vendor setted")
        C4:SetPropertyAttribs("Cloud Status", 0)
        C4:SetPropertyAttribs("Automatic Updates", 0)
        C4:SetPropertyAttribs("Houselogix License Code", 1)
        C4:SetPropertyAttribs("Houselogix License Status", 1)
        C4:SetPropertyAttribs("SoftKiwi License Code", 1)
        C4:SetPropertyAttribs("SoftKiwi License Status", 1)
        C4:SetPropertyAttribs("SoftKiwi Driver Type", 1)
        
    elseif vendor_id == "HOUSELOGIX" then
        SKC4_LOGGER:info("HOUSELOGIX vendor setted")
        C4:SetPropertyAttribs("Cloud Status", 1)
        C4:SetPropertyAttribs("Automatic Updates", 1)
        C4:SetPropertyAttribs("Houselogix License Code", 0)
        C4:SetPropertyAttribs("Houselogix License Status", 0)
        C4:SetPropertyAttribs("SoftKiwi License Code", 1)
        C4:SetPropertyAttribs("SoftKiwi License Status", 1)
        C4:SetPropertyAttribs("SoftKiwi Driver Type", 1)
        
    elseif vendor_id == "SOFTKIWI" then
        SKC4_LOGGER:info("SOFTKIWI vendor setted")
        C4:SetPropertyAttribs("Cloud Status", 1)
        C4:SetPropertyAttribs("Automatic Updates", 1)
        C4:SetPropertyAttribs("Houselogix License Code", 1)
        C4:SetPropertyAttribs("Houselogix License Status", 1)
        C4:SetPropertyAttribs("SoftKiwi License Code", 0)
        C4:SetPropertyAttribs("SoftKiwi License Status", 0)
        C4:SetPropertyAttribs("SoftKiwi Driver Type", 0)
        
    else
        SKC4_LOGGER:info("UNKNOW vendor setted")
        C4:SetPropertyAttribs("Cloud Status", 1)
        C4:SetPropertyAttribs("Automatic Updates", 1)
        C4:SetPropertyAttribs("Houselogix License Code", 1)
        C4:SetPropertyAttribs("Houselogix License Status", 1)
        C4:SetPropertyAttribs("SoftKiwi License Code", 1)
        C4:SetPropertyAttribs("SoftKiwi License Status", 1)
        C4:SetPropertyAttribs("SoftKiwi Driver Type", 1)
        
    end

    self.updatePersistData()

end
function LicenseManager:getCurrentVendorId()
    return self.currentVendorId
end

function LicenseManager:getCurrentVendorName()
    local id = self:getCurrentVendorId()

    if (id == "DRIVERCENTRAL") then
        return "Driver Central"
    elseif (id == "HOUSELOGIX") then
        return "Houselogix"
    elseif (id == "SOFTKIWI") then
        return "SoftKiwi"
    else
        return "Unknown"
    end
end
function LicenseManager:setCurrentVendorIdByName(value)
    if (value == "Driver Central") then
        self:setCurrentVendorId("DRIVERCENTRAL")
    elseif (value == "Houselogix") then
        self:setCurrentVendorId("HOUSELOGIX")
        self:trialTimerHandlerHouselogix()
    elseif (value == "SoftKiwi") then
        self:setCurrentVendorId("SOFTKIWI")
    end
end

function LicenseManager:setParamValue(param_key, param_value, vendor_id)

    if (vendor_id) then
        SKC4_LOGGER:debug("LicenseManager:setParamValue", "with vendor_id:", vendor_id)
        self.vendorData[vendor_id][param_key] = param_value
    else
        SKC4_LOGGER:debug("LicenseManager:setParamValue", "with automagic:", vendor_id)
        local autoVendorId = self:getCurrentVendorId()
        self.vendorData[autoVendorId][param_key] = param_value
    end
    self.updatePersistData()
    

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
    elseif self:getCurrentVendorId() == "SOFTKIWI" then
        return self:getParamValue("Licensed", "SOFTKIWI")
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
	if self:getCurrentVendorId() == "DRIVERCENTRAL" then
		local lic = self:isLicenseActive()
		local trial = self:isLicenseTrial()
		return lic or trial
	elseif self:getCurrentVendorId() == "HOUSELOGIX" then
		local lic = self:isLicenseActive()
		local trial = self:isLicenseTrial() == 1
        return lic or trial
    elseif self:getCurrentVendorId() == "SOFTKIWI" then
		local lic = self:isLicenseActive()
		return lic --or trial
	end
end


function LicenseManager:restoreFromPersistData()
    LICENSE_MGR.vendorData = C4:PersistGetValue("vendorData") or LICENSE_MGR.vendorData
    LICENSE_MGR.currentVendorId = C4:PersistGetValue("currentVendorId") or LICENSE_MGR.currentVendorId
    
    SKC4_LOGGER:debug("LicenseManager:restoreFromPersistData", "currentVendorId:", self.currentVendorId)
end

function LicenseManager:updatePersistData()
    SKC4_LOGGER:debug("LicenseManager:updatePersistData")
    C4:PersistSetValue("vendorData", LICENSE_MGR.vendorData)
    C4:PersistSetValue("currentVendorId", LICENSE_MGR.currentVendorId)
end


--
-- C4 Enviroment hooks
--

function LicenseManager:OnDriverInit()
    SKC4_LOGGER:debug("LicenseManager:OnDriverInit")
    
    self:OnDriverInit_DriverCentral()    
    self:OnDriverInit_HouseLogix()
    self:OnDriverInit_SoftKiwi()

    C4:SetPropertyAttribs("Cloud Status", 1)
    C4:SetPropertyAttribs("Automatic Updates", 1)
    C4:SetPropertyAttribs("Houselogix License Code", 1)
    C4:SetPropertyAttribs("Houselogix License Status", 1)
    C4:SetPropertyAttribs("SoftKiwi License Code", 1)
    C4:SetPropertyAttribs("SoftKiwi License Status", 1)
    C4:SetPropertyAttribs("SoftKiwi Driver Type", 1)

    --for k,v in pairs(Properties) do
	--	C4:ErrorLog("INIT_CODE: Calling OnPropertyChanged - " .. k .. ": " .. v)
	--	local status, err = pcall(OnPropertyChanged, k)
	--	if (not status) then
	--		C4:ErrorLog("LUA_ERROR: " .. err)
	--	end
	--end
    
end

function LicenseManager:OnDriverLateInit()
    SKC4_LOGGER:debug("LicenseManager:OnDriverLateInit")
    
    self:restoreFromPersistData()
    
    
    self:OnDriverLateInit_HouseLogix()    
    self:OnDriverLateInit_DriverCentral()
    self:OnDriverLateInit_SoftKiwi()
    
    -- TOFIX: see end of file for definition
    FIX_FOR_DRIVERCENTRAL = TimerManager:new(1, "SECONDS", self.onFIX_FOR_DRIVERCENTRALTimerExpire, false)
    FIX_FOR_DRIVERCENTRAL:start()

    C4:UpdateProperty("License Provider", "_!_")
    C4:UpdateProperty("License Provider", self:getCurrentVendorName())
end

-- TOFIX: DriverCentral re-enable AutoUpdate asyc...
function LicenseManager:onFIX_FOR_DRIVERCENTRALTimerExpire()
    if LICENSE_MGR:getCurrentVendorId() ~= "DRIVERCENTRAL" then
        C4:SetPropertyAttribs("Automatic Updates", 1)
    end
end


function LicenseManager:ReceivedFromProxy(idBinding, sCommand, tParams)
    --if self:getCurrentVendorId() == "DRIVERCENTRAL" then	
	--elseif self:getCurrentVendorId() == "HOUSELOGIX" then
    --elseif
    if self:getCurrentVendorId() == "SOFTKIWI" then
	    self:ReceivedFromProxy_SoftKiwi(idBinding, sCommand, tParams)
	end
end

function LicenseManager:OnPropertyChanged(strName)
    local propertyValue = Properties[strName]

    SKC4_LOGGER:debug("LicenseManager:OnPropertyChanged.",strName, propertyValue, type(propertyValue))

    if (LicenseManager.OnPropertyChangedTable[strName]) then
        status, err = pcall(LicenseManager.OnPropertyChangedTable[strName], self, propertyValue)
        if (not status) then
            if (SKC4_LOGGER ~= nil and type(SKC4_LOGGER) == "table") then
                SKC4_LOGGER:error("LUA_ERROR: ", err)
            end
        end
    else
        SKC4_LOGGER:debug("LicenseManager:OnPropertyChanged: this property is not related to License")
    end
end

function LicenseManager:SKC4_ON_PROPERTY_CHANGED_LicenseProvider(value)
	SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.LicenseProvider.",value, type(value))

    LICENSE_MGR:setCurrentVendorIdByName(value)
    
    if self:getCurrentVendorId() == "DRIVERCENTRAL" then
        return
    elseif self:getCurrentVendorId() == "HOUSELOGIX" then
        LICENSE_MGR.houselogixPropChangedTimerCheck = TimerManager:new(10, "SECONDS", LICENSE_MGR.Houselogix_Activate, false)
        LICENSE_MGR.houselogixPropChangedTimerCheck:start()
        --LICENSE_MGR:Houselogix_Activate()	
    elseif self:getCurrentVendorId() == "SOFTKIWI" then
        LICENSE_MGR:SoftKiwi_Activate()
    end

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
    SKC4_LOGGER:debug("Houselogix Trial timer Expired!")
    LICENSE_MGR:setParamValue("Trial", LicenseManager.TRIAL_EXPIRED, "HOUSELOGIX") 
    if (LICENSE_MGR:getCurrentVendorId() == "HOUSELOGIX") then
        LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
        LICENSE_MGR:Houselogix_Activate()	
    end
end

function LicenseManager:SKC4_ON_PROPERTY_CHANGED_HouselogixLicenseCode(value)
	SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.HouselogixLicenseCode","value:",value)
	HouselogixLicenseCode = value
    LICENSE_MGR:setParamValue("LicenseCode", HouselogixLicenseCode, "HOUSELOGIX")
    LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
    LICENSE_MGR:Houselogix_Activate()	
end

---------------
-- SoftKiwi
---------------
function LicenseManager:OnDriverInit_SoftKiwi()
    local model = C4:GetDeviceData(C4:GetDeviceID(),"model")
    C4:UpdateProperty ('SoftKiwi Driver Type', model)
end
function LicenseManager:OnDriverLateInit_SoftKiwi()   
    self:SoftKiwi_setDynamicBinding()
end

function LicenseManager:ReceivedFromProxy_SoftKiwi(idBinding, sCommand, tParams)
    SKC4_LOGGER:debug("LicenseManager:ReceivedFromProxy_SoftKiwi",idBinding, sCommand, tParams)
    local model = C4:GetDeviceData(C4:GetDeviceID(),"model")
    if idBinding == 998 and sCommand == "skLicenceRes" and tParams.MODEL == model then
		if tParams.IS_LICENSED == "True" then
            LICENSE_MGR:setParamValue("Licensed", true, "SOFTKIWI")
            LICENSE_MGR:setStatusMessage('Activated (last checked on: '..os.date("%m/%d/%Y %X")..')')
		else
            LICENSE_MGR:setParamValue("Licensed", false, "SOFTKIWI")
            LICENSE_MGR:setStatusMessage('Invalid license key')
        end
        
    end 
end

function LicenseManager:SoftKiwi_Activate()
    SKC4_LOGGER:debug("LicenseManager:SoftKiwi_Activate")
    self:SoftKiwi_setDynamicBinding()
    self:setStatusMessage('Activating driver...')
    LICENSE_MGR:setParamValue("Licensed", false, "SOFTKIWI")
    local model = C4:GetDeviceData(C4:GetDeviceID(),"model")
    local hash = LICENSE_MGR:getParamValue("LicenseCode","SOFTKIWI")
    SKC4_LOGGER:debug("LicenseManager:SoftKiwi_Activate", "send values for skLicenceCheck:", hash, model)
	C4:SendToProxy(998,"skLicenceCheck", {LIC = hash, MODEL = model})
end
  
function LicenseManager:SKC4_ON_PROPERTY_CHANGED_SoftKiwiLicenseCode(value)
	SKC4_LOGGER:debug("SKC4_ON_PROPERTY_CHANGED.SoftKiwiLicenseCode.","Value:", value)
	SoftKiwiLicenseCode = value
    LICENSE_MGR:setParamValue("LicenseCode", SoftKiwiLicenseCode, "SOFTKIWI")
    LICENSE_MGR:setParamValue("Licensed", false, "SOFTKIWI")
    LICENSE_MGR:SoftKiwi_Activate()	
end

function LicenseManager:SoftKiwi_setDynamicBinding()
    --SKC4_LOGGER:debug("LicenseManager:setDynamicBinding", "remove binding")
    --C4:RemoveDynamicBinding(998)
    SKC4_LOGGER:debug("LicenseManager:setDynamicBinding", "add binding")
    C4:AddDynamicBinding(998, "CONTROL", false, "softKiwi License", "SOFTKIWI_LICENSE", true, true)
end

--- -----------------------------------------------------------------
--- HOUSELOGIX LICENSE_MGR MANAGER
--- -----------------------------------------------------------------

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


function LicenseManager:Houselogix_Activate()
  LICENSE_MGR:setStatusMessage('Activating driver license...')
  mac = C4:GetUniqueMAC ()

  local license_code = LICENSE_MGR:getParamValue("LicenseCode", "HOUSELOGIX")
  local Houselogix_product_number = LICENSE_MGR:getParamValue("ProductId", "HOUSELOGIX")
  local sw_version = LICENSE_MGR:getParamValue("Version", "HOUSELOGIX")
  local postData = string.format('lic=%s&mac=%s&p=%s&ver=%s', license_code, mac, Houselogix_product_number, sw_version)
  SKC4_LOGGER:debug("LicenseManager:Houselogix_Activate()", "postData:", postData)
  ticketId = C4:urlPost('https://www.houselogix.com/license-manager/activatelicense.asp', postData, {}, false, LICENSE_MGR.Houselogix_Response)
  --methodType[ticketId] = "HLicense_Activate" -- QUESTA SERVE ANCORA? TOFIX
end

function LicenseManager.Houselogix_Response(ticketId, data, responseCode, tHeaders, strError )
    SKC4_LOGGER:debug('OnLicenseActivationResponseReceived',"ticketId", ticketId, "data", data)
  local i = string.find(data, 'Valid')
  if (i) then
    LICENSE_MGR:setParamValue("Licensed", true, "HOUSELOGIX")
    LICENSE_MGR:setStatusMessage('Activated (last checked on: '..os.date("%m/%d/%Y %X")..')')
  elseif (string.find(data, 'Unauthorized')) then
    LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
    LICENSE_MGR:setStatusMessage('Invalid license key')
  elseif (string.find(data, 'Failed')) then
    if LICENSE_MGR:getParamValue("Licensed", "HOUSELOGIX") then 
        LICENSE_MGR:setParamValue("Licensed", true, "HOUSELOGIX")
    else
        LICENSE_MGR:setParamValue("Licensed", false, "HOUSELOGIX")
    end
    LICENSE_MGR:setStatusMessage('Failed to verify')
  else
    LICENSE_MGR:setStatusMessage(strError)
  end
  local checkInterval =  LICENSE_MGR:getParamValue("ValidityCheckInterval", "HOUSELOGIX") 
  LICENSE_MGR.houselogixTimerCheck = TimerManager:new(checkInterval, "MINUTES", LICENSE_MGR.onHouselogixTimerExpire, false)
  LICENSE_MGR.houselogixTimerCheck:start()
end


LICENSE_MGR = LICENSE_MGR or LicenseManager:new()


return LicenseManager

