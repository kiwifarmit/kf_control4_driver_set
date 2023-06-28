local SoftKiwiC4 = {}

SoftKiwiC4.version = "0.5.0"
SoftKiwiC4.Logger = require("SKC4.Logger");
SoftKiwiC4.Utility = require("SKC4.Utility"); -- Alias per un logger che scrive su stdout
SoftKiwiC4.TimerManager = require("SKC4.TimerManager")
SoftKiwiC4.Queue = require("SKC4.Queue")
SoftKiwiC4.ApiRestManager = require("SKC4.ApiRestManager")
SoftKiwiC4.DynamicVariableManager = require("SKC4.DynamicVariableManager")
SoftKiwiC4.DynamicConnectionManager = require("SKC4.DynamicConnectionManager")
SoftKiwiC4.LicenceManager = require("SKC4.LicenseManager")
SoftKiwiC4.DriverCore = require("SKC4.DriverCore")



-- SKC4.Connections = require("SKC4.Connections");
-- SKC4.Debug = require("SKC4.Debug"); -- Alias per un logger che scrive su stdout

return SoftKiwiC4;
