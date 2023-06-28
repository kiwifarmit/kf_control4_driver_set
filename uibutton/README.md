# Description #
This driver allows getting a button to use it in any section of the Control4 user interface for controlling a relay and getting feedback from a contact sensor.

# Property #


## Licensing ##
* License Provider
  * Driver Central
  to use the licensing of the marketplace Driver Central
  * Houselogix
  to use the licensing of the marketplace Houselogix
* Cloud Status
to show the Driver Central licensing status
* Automatic Updates
to Allow or not Driver Central automatic updates
* Houselogix License Code
property to insert Houselogix license number
* Houselogix License Status
to show the Houselogix licensing status
* Action
Property to decide the action to fire each pressure of the button on the interface
  * TOGGLE
  Send a TOGGLE message on the connection to the relay
  * ON-OFF
  Swap between ON and OFF, the state could be swapped between On and Off in function of the last state fired or reading the state by the Contact Sensor
  * PULSE
  To send ON for a period, and fire OFF to the expire of the period
* Pulse Lenght *
  The length of the period for the pulse action
  * 500
  * 1000
  * 1500
* Inverted Relay *
To invert the state of the relay. Set this property to on to have ON = CLOSE, OFF = OPEN, set it to off to invert the behavior
* Feedback *
The state (color) of the button on the interface could depend by contact sensor or could depend by the state of the relay. Set it on if you want to read the state from the sensor, off if you are interested in the relay state.
* Driver Information *
Give the information about the clickability of the Button
* Select Color Off *
Set the color of the OFF state of the button
* Select Color On *
Set the color of the ON state of the button
* Clickable *
Set it on Yes if you want to enable the button, otherwise choose the No option.

## Action ##

* Set Color *
Set the button to the desired state (color) 
  
