local SoftKiwiC4 = {}

SoftKiwiC4.version = "0.1.2"
SoftKiwiC4.Logger = require("SKC4.Logger");
SoftKiwiC4.Utility = require("SKC4.Utility"); -- Alias per un logger che scrive su stdout
SoftKiwiC4.TimerManager = require("SKC4.TimerManager")
SoftKiwiC4.LicenceManager = require("SKC4.LicenseManager")

-- SKC4.Connections = require("SKC4.Connections");
-- SKC4.Debug = require("SKC4.Debug"); -- Alias per un logger che scrive su stdout

return SoftKiwiC4;
