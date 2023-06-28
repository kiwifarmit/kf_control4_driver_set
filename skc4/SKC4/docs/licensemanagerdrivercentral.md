[Back to the index](index.md)

# LicenseManagerDriverCentral.lua

This module allows for the management of DriverCentral's license only.

## How to add license management to a driver

To add license support, it is necessary to modify _driver.xml_ and add some specific calls to your driver.

### Changes to _driver.xml_

For the proper functioning of the lua code, it is necessary to set up a series of properties. Add to _driver.xml_ in the `<properties>` section of the file.
```
      <property>
				<name>License Section</name>
				<type>LABEL</type>
				<default>Licensing</default>
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
```

If you're not interested in a provider, you can remove the related item in the License Provider property to disable it.

### Changes to Lua code.

1. Include the license management module with the command:
    `require 'SKC4.LicenseManagerDriverCentral'`

2. Set the initialization values of the parameters immediately after the `require` from the previous point:
```
    DC_LICENSE_MGR:setProductId(<DriverCentral product id>)
    DC_LICENSE_MGR:setFreeDriver(<true if free, false otherwise>)
    DC_LICENSE_MGR:setFileName(<.c4z file name>)
```

3. **If you are using the DriverCore module, you can skip this. DriverCore checks if you have included this module and sets up automatically** Otherwise, add the OnDriverInit() event hooks:
    * _function OnDriverInit()_ function:
```
      DC_LICENSE_MGR:init()
```

4. Done: at this point, the driver should be able to manage the license provider.

## API 

Below is a list of the *public calls* provided by the module. The module offers other calls that are not usually necessary. Refer to the code for the other calls.

### `LicenseManagerDriverCentral:new(o)`

This function is the constructor of the LicenseManagerDriverCentral object. *It is never explicitly called* as the module provides a global variable `DC_LICENSE_MGR` with the `require` that already contains a configured and ready-to-use object. 

Note: `DC_LICENSE_MGR` is a _singleton_, i.e., a unique object that can be shared in all lua files with the certainty that it is always the same and not a different one.

### `function LicenseManagerDriverCentral:init()`
### `function LicenseManagerDriverCentral:init(productId, freeDriver, filename)`
This function initializes and enables communication with DriverCentral. This is the only function to be explicitly called.

If you have set the DriverCentral parameters with the setters (see below), use the `init()` call without parameters.

If instead you want to set the parameters and activate communication simultaneously, you can use the call with parameters.
The parameters to indicate are those required by DriverCentral:

`productId`:    the product ID of the product on DriverCentral
`freeDriver`:   true if the driver is free, false otherwise
`param_key`:    the name of the .c4z driver file

The DriverCentral documentation is available in the Vendor area of the marketplace, under the menu [Vendor/DriverCentral](https://drivercentral.io/vendor

.php?dispatch=view_api.new)

### `function LicenseManagerDriverCentral:setProductId(value)`
### `function LicenseManagerDriverCentral:getProductId()`
### `function LicenseManagerDriverCentral:setFreeDriver(value)`
### `function LicenseManagerDriverCentral:getFreeDriver()`
### `function LicenseManagerDriverCentral:setFileName(value)`
### `function LicenseManagerDriverCentral:getFilename()`
These functions set the parameters required by DriverCentral for the license. These calls are intended for internal use since the values of these parameters must be set before importing the DriverCentral code (see `init()` function)


### `LicenseManagerDriverCentral:setParamValue(param_key, param_value, vendor_id)`
### `LicenseManagerDriverCentral:getParamValue(param_key, vendor_id)`
These functions allow to set and read the configuration parameters necessary for correct communication with various vendors.

`param_key`:    name of the parameter to assign
`param_value`:  value of the parameter to assign
`vendor_id`:    indicates for which license system is the parameter. The possible values are: `DRIVERCENTRAL`, `HOUSELOGIX`, `SOFTKIWI`

The possible parameters for the `DRIVERCENTRAL` manager are:
  * *ProductId*: Product ID provided by Driver Central
  * *FreeDriver*:  is `true` if the driver is free or `false` if it is paid
  * *FileName*: is the name of the *.c4z driver file downloaded from drivercentral.io

The possible parameters for the `HOUSELOGIX` manager are:
  * *ProductId*: Product ID provided by Houselogix
  * *ValidityCheckInterval*: interval (in minutes) how often the license will be checked
  * TrialExpiredLapse*: duration (in hours) of the trial period
  * *Version*: driver version number

There are no parameters for the `SOFTKIWI` manager: every useful data is retrieved from the driver's properties on Composer Pro.


See the paragraph _Changes to Lua code_ for a code example.

### `LicenseManagerDriverCentral:isLicenseActive()`
### `LicenseManagerDriverCentral:isLicenseTrial()`
### `LicenseManagerDriverCentral:isLicenseActiveOrTrial()`
These are functions that query the license manager to find out if the license is active, in the trial period, or in one of the two situations respectively.

The returned value is a boolean that refers to the license manager currently selected in the driver's properties on Composer Pro.

### `LicenseManagerDriverCentral:isAbleToWork()`
This function returns `true` if the driver is authorized (whatever the current state) or `false` if the driver is not authorized. _NB: at the moment it is an alias of `isLicenseActiveOrTrial()` but in general, it covers a larger number of possible states_