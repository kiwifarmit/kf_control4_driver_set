[Back to Index](index.md)

# DriverCore.lua

This module simplifies the creation of new drivers by automatically providing all the event handlers of Control4.

This allows you to focus only on developing the code that responds to the specific event you're interested in, while delegating to the module the management of the correct flow of operation or the definition of any default behaviors.

A typical example is that all the management of the Composer Lua debug console is handled autonomously and consistently in all drivers that use `DriverCore`. Additionally, there is no need to write code in the `OnDriverInit()` function to update property values, as it will be done transparently by the module itself.

## How to Use `DriverCore` in a Driver

Using `DriverCore` requires modifying the `driver.xml` file and adding specific calls to your driver.

### Modifications to `driver.xml`

For the Lua code to function correctly, a set of properties needs to be prepared. Add them to the `<properties>` section of the `driver.xml` file.
```   
      <property>
				<name>Log Section</name>
				<type>LABEL</type>
				<default>Logging</default>
			</property>
      <property>
				<name>Log Level</name>
				<type>LIST</type>
				<readonly>false</readonly>
				<default>Off</default>
				<items>
          <item>Off</item>
          <item>5 - Debug</item>
          <item>4 - Trace</item>
          <item>3 - Info</item>
          <item>2 - Warning</item>
          <item>1 - Error</item>
          <item>0 - Alert</item>
				</items>
			</property>
      <property>
				<name>Log Mode</name>
				<type>LIST</type>
				<readonly>false</readonly>
				<default>Print</default>
				<items>
          <item>Print</item>
          <item>Log</item>
          <item>Print and Log</item>
				</items>
			</property>
      <property>
				<name>Disable Log Interval</name>
        <description>Autmatically disable logging after this interval of time</description>
				<type>LIST</type>
				<readonly>false</readonly>
				<default>1 hour</default>
				<items>
          <item>15 minutes</item>
          <item>30 minutes</item>
          <item>1 hour</item>
          <item>6 hours</item>
          <item>24 hours</item>
          <item>Never</item>
				</items>
			</property>
      
      <property>
				<name>Driver Info</name>
				<type>LABEL</type>
				<default>Driver Info</default>
			</property>
      <property>
				<name>Driver Version</name>
				<type>STRING</type>
				<default>---</default>
        <readonly>true</readonly>
			</property>
```
[Back to Index](index.md)

### Modifying the Lua Code

As for the modifications to the `driver.lua` file, they are minimal:

1. Include the module with the command: `require 'SKC4.DriverCore'` at the beginning of the file.

That's it! At this point, the driver should be able to handle various Control4 events. If you also want to manage licenses, refer to the module [`LicenseManagerDriverCentral.lua`](./licensemanagerdrivercentral.md).

### Driver Structure

Let's see how a driver using the `DriverCore` module should be structured.

Since `DriverCore` automatically responds to the main Control4 events, the only thing you need to do in the `driver.lua` file is to define specific functions for each event so that they are visible to `DriverCore` and can be invoked when needed. To do this, the module creates a series of tables used to store the different functions, and the system will automatically invoke them.

#### Event Tables

Here are the tables currently available:

- `ON_DRIVER_EARLY_INIT`: Contains all the functions that respond to the Control4 event `OnDriverInit()`. These functions will be executed at the beginning of the event, before anything else.
- `ON_DRIVER_INIT`: Contains all the functions that respond to the Control4 event `OnDriverInit()`. These functions will be executed after the functions in `ON_DRIVER_EARLY_INIT` and before retrieving the driver's property values.
- `ON_DRIVER_LATE_INIT`: Contains all the functions that respond to the Control4 event `OnDriverLateInit()`.
- `ON_DRIVER_DESTROYED`: Contains all the functions that respond to the Control4 event `OnDriverDestroyed()`. These functions are executed before removing a driver from the controller.
- `ON_PROPERTY_CHANGED`: Contains all the functions that respond to the Control4 event `OnPropertyChanged()`.
- `ACTIONS`: Contains all the functions that respond to the Actions defined in the XML.
- `COMMANDS`: Contains all the functions that respond to the Control4 event `ExecuteCommand()`.
- `CONDITIONALS`: Contains all the functions that respond to the Control4 event `TestCondition()`.
- `PROXY_COMMANDS`: Contains all the functions that respond to the Control4 event `ReceivedFromProxy()`.
- `NOTIFICATIONS`: Contains all the functions that respond to the Control4 notification event (*NOT IMPLEMENTED YET*).
- `UI_REQUEST`: Contains all the functions that respond to the requests sent with `C4:SendUiRequest` in Control4.

#### Adding a Function to the Event Tables

To add a function to a table, use the following syntax:

```
function TABLE_NAME.FunctionName(parameter)
  -- code goes here
end
```

For example, if you want to add a function that should be executed in the `OnDriverInit()` event and you want to name it `do_something()`, you would write:

```
function SKC4_ON_DRIVER_INIT.do_something()
  -- do something
end
```

The parameters accepted by the functions should match those defined by the respective Control4 events. For example, `OnPropertyChanged(sProperty)` receives the parameter `sProperty`, so the function `SKC4_ON_PROPERTY_CHANGED.my_property(sProperty)` should accept a `sProperty` parameter.

#### Convention for Naming Event Table Functions

The names of the functions within the event tables are free-form (i.e., their names do not affect the proper functioning of the `DriverCore` module) except for the following event tables:

- `ON_DRIVER_EARLY_INIT`
- `ON_DRIVER_INIT`
- `ON_DRIVER_LATE_INIT`
- `ON_DRIVER_DESTROYED`

For the event tables listed below, there is a specific naming convention:

- `ON_PROPERTY_CHANGED`: The function name should be identical to the name of the property for which you want to handle the event, with spaces replaced by underscores (_).
- `COMMANDS`: The function name should be identical to the name of the command for which you want to handle the event, with spaces replaced by underscores (_).
- `ACTIONS`: The function name should be identical to the name of the action for which you want to handle the event, with spaces replaced by underscores (_).
- `PROXY_COMMANDS`: The function name should be identical to the name of the command for which you want to handle the event, with spaces replaced by underscores (_).
- `VARIABLE_CHANGED`: The function name should be identical to the name of the variable for which you want to handle the event, with spaces replaced by underscores (_).
- `CONDITIONALS`: The function name should be identical to the name of the conditional defined in the XML for which you want to handle the event, with spaces replaced by underscores (_).
- `NOTIFICATIONS`: *TO BE DEFINED. NOT YET IMPLEMENTED*
- `UI_REQUEST`: The function name should be identical to the request string sent with `C4:SendUiRequest`, with spaces replaced by underscores (_).

For example, if we want to handle the `OnPropertyChanged` event for the property "IP Port Number," the function to define would be:

```lua
function ON_PROPERTY_CHANGED.IP_Port_Number(propertyValue)
  -- code goes here
end
```

If we want to handle a variable value change, the function would be:

```lua
function VARIABLE_CHANGED.SUNLIGHT_HIGH_THRESHOLD_STRING()
  -- This function doesn't accept any value
  local var_value = Variables[VAR_NAME_SUNLIGHT_HIGH_THRESHOLD_STRING]
  -- code goes here
end
```

When expecting to receive a command from a connection (e.g., "RECEIVED_NEW_DATA"), the function would be:

```lua
function PROXY_COMMANDS.RECEIVED_NEW_DATA(tParams, idBinding)
  -- code goes here
end
```

If we expect to process the response to a `C4:SendUiRequest()` command, such as when we request the test string from a camera ("GET_RTSP_H264_QUERY_STRING") in Composer, the function would be:

```lua
function UI_REQUEST.GET_RTSP_H264_QUERY_STRING(tParams, idBinding)
	-- code goes here
end
```

For a conditional named "SERVICE_STATUS" as defined in the XML, we would use a function like:

```lua
function CONDITIONALS.SERVICE_STATUS(tParams)
  -- code goes here
end
```

Note that the casing of the property name must be preserved, as `DriverCore` distinguishes between uppercase and lowercase letters.

**Note:**

There are internal versions of these tables within the library to separately manage internal calls from those of the actual driver to avoid conflicts. The tables are:
`SKC4_ON_DRIVER_EARLY_INIT`, `SKC4_ON_DRIVER_INIT`, `SKC4_ON_DRIVER_LATE_INIT`, `SKC4_ON_DRIVER_DESTROYED`, `SKC4_ON_PROPERTY_CHANGED`, `SKC4_COMMANDS`, `SKC4_ACTIONS`, `SKC4_PROXY_COMMANDS`, `SKC4_VARIABLE_CHANGED`,

 `SKC4_NOTIFICATIONS`, `SKC4_CONDITIONALS`.

### API

Here is a list of the *public calls* provided by the module. The module provides other calls that are usually not necessary. Refer to the code for the other calls.

#### `LOGGER`

For debug logging, `DriverCore` automatically provides an `SKC4:Logger` object in the global variable `LOGGER`. To print a debug message, for example, simply write:

```lua
LOGGER:debug("This is a debug message")
```

The logger provided by the module automatically captures all debug messages from the library (i.e., it is an alias for `SKC4_LOGGER`). If you want to keep the driver's log data separate from that of the library, you need to create a new object and assign it to the `LOGGER` variable using the following call:

```lua
LOGGER = Logger.new()
```

For more details on the `Logger` module, refer to the [guide](./logger.md).

#### `UpdateProperty(propertyName, propertyValue)`

This is a global function that can be called from anywhere in the `driver.lua` file to update the value of a property. It is a wrapper for `C4:UpdateProperty(propertyName, propertyValue)` and accepts the same parameters as the Control4 function. Using this function instead of the native function ensures that all events intercepted by the `DriverCore` module are correctly handled.

#### `ShowProperty(propertyName)`
#### `HideProperty(propertyName)`
#### `SetPropertyVisibility(propertyName, isVisible)`

These global functions can be called from anywhere in the `driver.lua` file to respectively show or hide a property in Composer. They are wrappers for the following functions:

- `C4:SetPropertyAttribs(propertyName, 0)`
- `C4:SetPropertyAttribs(propertyName, 1)`
- `C4:SetPropertyAttribs(propertyName, 0|1)`, where the `0|1` parameter is derived from the boolean value `isVisible`

#### `AddVariable(strName, strValue, strVarType, bReadOnly, bHidden)`
#### `GetVariable(strName)`
#### `SetVariable(strName, strValue)`

These global functions can be called from anywhere in the `driver.lua` file to respectively add a variable and retrieve its value. They are wrappers for the following functions:

- `C4:AddVariable(strName, strValue, strVarType, bReadOnly, bHidden)` and accept the same parameters.
- `C4:GetVariable(idDevice, idVariable)`, but the name of the variable is used as the parameter.
- `C4:SetVariable(strName, strValue)` and accept the same parameters.

By using these functions, you can manage the variables of the current driver (ONLY THE CURRENT DRIVER) by using the variable name directly without having to keep track of numerical IDs. *Do not mix these functions with C4 functions*.

**Note: If you need to manage variables dynamically, refer to the [Dynamic Variable Manager](dynamicvariablemanager.md) module**.
