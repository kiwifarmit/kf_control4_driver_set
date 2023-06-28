# SKC4 Library Manual

In this document, you will find an overview of the library. For specific documentation on each module, please refer to the corresponding file in the `docs/` folder.

## Purpose and Content of the Library

This library contains Lua utility modules for Control4 driver developers.

The main modules include:

* `C4.lua`: Module that simulates calls to the C4 SDK library, allowing partial testing of the driver outside the Control4 and Composer environments.
* [`DriverCore.lua`](drivercore.md): Module that contains functions to handle Control4 events.
* `Connections.lua`: Module that contains functions for managing connections on various protocols.
* `Debug.lua`: *Deprecated* module for printing debug information. The functionalities of this module have been consolidated into Logger.lua.
* [`LicenseManagerDriverCentral.lua`](licensemanagerdrivercentral.md): Module for managing DriverCentral licenses.
* [`LicenseManager.lua`](licensemanager.md): (OBSOLETE) Module for managing various license providers.
* [`ApiRestManager.lua`](apirestmanager.md): Module for handling communication with an HTTP REST server.
* `Logger.lua`: Module for managing log information to standard output or file.
* `TimerManager.lua`: Module for managing timers.
* [`Queue.lua`](quque.md): Module for managing generic queues.
* [`Utility.lua`](utility.md): Contains various utility functions.
* [`LightingUtility.lua`](lightingutility.md): Contains various utility functions for lighting objects.
* [`DynamicVariableManager.lua`](dynamicvariablemanager.md): Contains functions for dynamic variable management.
* [`DynamicConnectionManager.lua`](dynamicconnectionmanager.md): Contains functions for dynamic connection management.
* `SKC4lib.lua`: Root module of the library. Including this module automatically includes all the previous modules.

Supporting code for the library is contained in the following folders:
* `docs/`: Contains the library documentation.
* `lib/`: Contains various third-party libraries.
* `license/`: Contains third-party code for license management (e.g., DriverCentral.io library).

## Including the Library in a Control4 Driver

1. Copy the SKC4 folder to the root of your software project (where the _driver.lua_ file is located).

2. Add the SKC4 library files to the _squishy_ file in the _Module_ section:
    ```
    Module "SKC4.licence.cloud-client-byte" "SKC4/licence/cloud-client-byte.lua"
    Module "SKC4.Utility" "SKC4/Utility.lua"
    Module "SKC4.LightingUtility" "SKC4/LightingUtility.lua"
    Module "SKC4.Logger" "SKC4/Logger.lua"
    Module "SKC4.DriverCore" "SKC4/DriverCore.lua"
    Module "SKC4.TimerManager" "SKC4/TimerManager.lua"
    Module "SKC4.Queue" "SKC4/Queue.lua"
    Module "SKC4.ApiRestManager" "SKC4/ApiRestManager.lua"
    Module "SKC4.LicenseManagerDriverCentral" "SKC4/LicenseManagerDriverCentral.lua"
    # DEPRECATED: Add only if necessary Module "SKC4.LicenseManager" "SKC4/LicenseManager.lua"
    Module "SKC4.DynamicVariableManager" "SKC4/DynamicVariableManager.lua"
    Module "SKC4.DynamicConnectionManager" "SKC4/DynamicConnectionManager.lua"
    Module "SKC4.SKC4lib" "SKC4/SKC4lib.lua"
    ```
3. If the root `<Driver>` tag in the .c4zproj file has the `manualsquish` attribute set to

 "true," this step should not be necessary. Otherwise, add the following code to the `<Squishy>` section of the file:
    ```
    <File>SKC4\Debug.lua</File>
    <File>SKC4\LicenseManagerDriverCentral.lua</File>
    <!-- DEPRECATED: Add only if necessary <File>SKC4\LicenseManager.lua</File> -->
    <File>SKC4\Logger.lua</File>
    <File>SKC4\TimerManager.lua</File>
    <File>SKC4\Utility.lua</File>
    <File>SKC4\LightingUtility.lua</File>
    <File>SKC4\Queue.lua</File>
    <File>SKC4\DynamicVariableManager.lua</File>
    <File>SKC4\DynamicConnectionManager.lua</File>
    <File>SKC4\ApiRestManager.lua</File>
    <File>SKC4\DriverCore.lua</File>
    <File>SKC4\SKC4lib.lua</File>
    <File>SKC4\licence\cloud-client-byte.lua</File>
    ```

To use the various modules, simply use `require("SKC4.module_name")`. For descriptions of the different modules, refer to their specific documentation.
*There is no need to include the SKC4 directory in the .c4proj file, as the squish operation automatically includes the files.*