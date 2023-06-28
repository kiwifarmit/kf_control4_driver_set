# LicenseManager.lua

This module allows for the management of various types of licenses. Currently supported licenses include:
* Houselogix
* DriverCentral
* Soft.kiwi proprietary license

## Adding License Management to a Driver

To add license support to a driver, you need to modify the _driver.xml_ file and add specific calls to your driver.

### Modifications to _driver.xml_

For the Lua code to function correctly, you need to set up a series of properties. Add the necessary properties to the `<properties>` section of the _driver.xml_ file.

```
      <property>
				<name>License Section</name>
				<type>LABEL</type>
				<default>Licensing</default>
			</property>

      <property>
        <name>License Provider</name>
        <default />
        <type>LIST</type>
        <items>
          <item>Driver Central</item>
          <item>Houselogix</item>
          <item>SoftKiwi</item>
        </items>
        <readonly>false</readonly>
      </property>
      <property>
        <name>Cloud Status</name>
        <default />
        <type>STRING</type>
        <readonly>true</readonly>
      </property>
      <property>
        <name>Automatic Updates</name>
        <type>LIST</type>
        <items>
          <item>Off</item>
          <item>On</item>
        </items>
        <default>Off</default>
        <readonly>false</readonly>
      </property>
      <property>
        <name>Houselogix License Code</name>
        <default />
        <type>STRING</type>
        <readonly>false</readonly>
        <default>type your license code here</default>
      </property>
      <property>
        <name>Houselogix License Status</name>
        <type>STRING</type>
        <readonly>true</readonly>
        <default />
      </property>
      <property>
        <name>SoftKiwi License Code</name>
        <default />
        <type>STRING</type>
        <readonly>false</readonly>
        <default>type your license code here</default>
      </property>
      <property>
        <name>SoftKiwi Driver Type</name>
        <type>STRING</type>
        <readonly>true</readonly>
        <default />
      </property>
      <property>
        <name>SoftKiwi License Status</name>
        <type>STRING</type>
        <readonly>true</readonly>
        <default />
      </property>
```

If you are not interested in a provider, you can remove the related item in the License Provider property to deactivate it.

### Lua code changes.

1. Include the license management module with the command:
    `require 'SKC4.LicenseManager'`

2. Initialize the LicenseManager module with the default request values for example (see `setParamValue()` description below for more details on possible values):
```  
  --- Config License Manager  
  LICENSE_MGR:setParamValue("ProductId", 200, "DRIVERCENTRAL") -- Product ID  
  LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)  
  LICENSE_MGR:setParamValue("FileName", "telegram-bot.c4z", "DRIVERCENTRAL")  
  LICENSE_MGR:setParamValue("ProductId", 576, "HOUSELOGIX")  
  LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX")  
  LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")  
  LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo ("version"), "HOUSELOGIX")  
  LICENSE_MGR:setParamValue("Trial", LICENSE_MGR.TRIAL_NOT_STARTED, "HOUSELOGIX")  
  --- end license  
```

3. **If you are using the DriverCore module, you can skip this.** Otherwise, add event hooks by adding the following calls/blocks of code in the indicated functions. Usually, they need to be inserted at the end of the functions:
    * _function OnDriverInit()_ function:
```
      LICENSE_MGR:OnDriverInit()
```
    * _OnDriverLateInit()_ function:
```
      LICENSE_MGR:OnDriverLateInit() 
```
    * _ReceivedFromProxy(idBinding, sCommand, tParams)_ function: 
```
      LICENSE_MGR:ReceivedFromProxy(idBinding, sCommand, tParams)
```
    * _OnPropertyChanged(strProperty)_ function:
```
      LICENSE_MGR:OnPropertyChanged(strProperty)
```

End: At this point, the driver should be able to handle the various license providers.

## API 

Here is a list of *public calls* provided by the module. The module provides other calls that are not usually necessary. Please refer to the code for other calls.

### `LicenseManager:new(o)`

This function is the constructor of the LicenseManager object. *It is never called explicitly* as the module provides a global variable `LICENSE_MGR` with `require`, which already contains a configured and ready-to-use object.

Note: `LICENSE_MGR` is a _singleton_, i.e., a unique object that can be shared in all Lua files with the certainty that it is always the same and not a different one.

### `LicenseManager:getCurrentVendorId()`
Returns a string indicating the currently in use license system. The returned value is a string among `DRIVERCENTRAL`, `HOUSELOGIX`, `SOFTKIWI`, `UNKNOWN`.

### `LicenseManager:getCurrentVendorName()`
Returns a string with the name of the license system currently in use. The returned value is the one indicated in the driver's _property_.

### `LicenseManager:setParamValue(param_key, param_value, vendor_id)`
### `LicenseManager:getParamValue(param_key, vendor_id)`
These functions allow you to set and read the configuration parameters necessary for proper communication with various vendors.

`param_key`:    name of the parameter to assign
`param_value`:  value of the parameter to assign
`vendor

_id`:    indicates for which license system is the parameter. The possible values are: `DRIVERCENTRAL`, `HOUSELOGIX`, `SOFTKIWI`

The possible parameters for the `DRIVERCENTRAL` manager are:
  * *ProductId*: Product ID provided by Driver Central
  * *FreeDriver*:  is `true` if the driver is free or `false` if it is paid
  * *FileName*: is the name of the driver's *.c4z file downloaded from drivercentral.io

The possible parameters for the `HOUSELOGIX` manager are:
  * *ProductId*: Product ID provided by Houselogix
  * *ValidityCheckInterval*: Interval (in minutes) at which the license will be reverified
  * *TrialExpiredLapse*: Duration (in hours) of the trial period
  * *Version*: Driver version number

There are no parameters for the `SOFTKIWI` manager: every useful data is retrieved from the driver properties on Composer Pro.

Please see the _Lua code changes_ paragraph for an example of code.

### `LicenseManager:isLicenseActive()`
### `LicenseManager:isLicenseTrial()`
### `LicenseManager:isLicenseActiveOrTrial()`
These are functions that query the license manager to know respectively if the license is active, it is in the trial period, or if one of the two situations is present.

The returned value is a boolean that refers to the license manager currently selected in the driver properties on Composer Pro.

### `LicenseManager:isAbleToWork()`
This function returns `true` if the driver is authorized (whatever the current state) or `false` if the driver is not authorized. _NB: currently, it is an alias of `isLicenseActiveOrTrial()` but generally covers a larger number of possible states_


### `LicenseManager:OnDriverInit()`
### `LicenseManager:OnDriverLateInit()`
### `LicenseManager:ReceivedFromProxy(idBinding, sCommand, `tParams)
These are functions that follow the Control4 system calls and serve to intercept related events and give the license management module the possibility to interact.

### `LicenseManager:OnPropertyChanged(strName, value)`
This function, like the previous ones, follows the relative call of Control4 but has an extra `value` parameter. `value` contains the current value of the property that triggered the event (whose name is `strName`).
The task of retrieving the parameter value is left to the developer. Usually, it is done with a code like:
```
function OnPropertyChanged (strProperty) 
  local value = Properties[strProperty]

  -- now that you have the value it's possible to call the license manager
  LICENSE_MGR:OnPropertyChanged(strProperty, value)
end
```