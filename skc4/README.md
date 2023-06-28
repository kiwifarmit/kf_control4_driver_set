# SKC4 Library Manual

In this document, you will find an overview of the library. For specific documentation on each module, please refer to the corresponding file in the `docs/` folder.

## Purpose and Content of the Library

This library contains Lua utility modules for Control4 driver developers. [Read the documentation here](SKC4/docs/index.md).

## CHANGELOG

* **Ver. 0.7.1**
  * NEW: Added LightingUtility class that contains functions for managing color models and other useful things for lights.
  * NEW: Added functions for managing Composer property visibility in DriverCore.lua.

* **Ver. 0.7.0**
  * NEW: Added LicenseManagerDriverCentral class that handles only DriverCentral license.
  * REMOVE: Deprecated the LicenseManager class.

* **Ver. 0.6.1**
  * FIX: LicenseManager state variable seems to have changed.
  * FIX: The LicenseManager class should be a singleton (only one manager per driver).

* **Ver. 0.6.0**
  * ADD: Added Timer:is_running() function to check if the timer is active.
  * FIX: Class attributes are erroneously singletons.
  * UPGRADE: Updated DriverCentral license code to version 1020.

* **Ver. 0.5.2**
  * ADD: Added matrix_translate function in Utility.
  * FIX: Timer LATE_INIT callback has a too common name and may be used in other drivers (see dahua).

* **Ver. 0.5.1**
  * ADD: Partial backward compatibility support for systems prior to OS2.10.5.
  * ADD: Digest authentication support.
  * FIX: SetVariable does not convert boolean values to 1/0 when received.

* **Ver. 0.5.0**
  * ADD: Support for new optional parameters in OnDriverInit(), OnDriverLateInit(), and OnDestroy() introduced in OS 3.2.
  * ADD: Dynamic variable management module.
  * ADD: Dynamic connection management module. The module is currently not implemented.

* **Ver. 0.4.2**:
  * ADD: Added Utility.tonumber_loc(str, base) call.
  * ADD: Added support for random delay in requests in ApiRestManager.
  * ADD: Added send_next_requests_later() function in ApiRestManager.
  * FIX: tonumber_loc() fails if the parameter is not a string.
  * FIX: Requests added via template result in empty entries in ApiRestManager.
  * ADD: Added the ability to have a separate LOGGER from SKC4_LOGGER in DriverCore.

* **Ver. 0.4.1**:
  * FIX: Support for JIT Lua interpreter.
  * ADD: DeleteVariable() wrapper.

* **Ver. 0.4.0**:
  * ADD: Created_at and started_at attributes in TimerManager.
  * ADD: ApiRestManager module.
  * ADD: Queue module.
  * ADD: Support for Conditionals in DriverCore.lua.

* **Ver. 0.3.2**:
  * FIX: Added timer destroy for logging.
  * FIX: Typo in documentation.

* **Ver. 0.3.1**:
  * FIX: Added delay in the execution of late init to ensure that properties are available.

* **Ver. 0.3.0**:
  * ADD: Added Driver Version property in DriverCore that displays the driver version.
  * ADD: Added dedicated handling for LUA_ACTION events.
  * ADD: Added idBinding parameter to calls made to PROXY_COMMANDS.
  * ADD: Added AddVariable

, SetVariable, and GetVariable functions.

* **Ver. 0.2.2**:
  * FIX: Removed punctuation and disallowed characters from property texts when creating the function name to be called in the ON_PROPERTY_CHANGED table.

* **Ver. 0.2.1**:
  * FIX: The Logger still used the global LOGGER instead of the new SKC4_LOGGER.

* **Ver. 0.2.0**:
  * Added handling of OnVariableChanged event.
  * FIX: Functions in the `ON_DRIVER_EARLY_INIT`, `ON_DRIVER_INIT`, `ON_DRIVER_LATE_INIT`, and `ON_DRIVER_DESTROYED` tables were no longer being called.