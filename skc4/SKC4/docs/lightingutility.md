[Back to the index](index.md)

# Lighting Utility

Contains various utility functions for lights.
Documentation to be completed.
Example of how to use the library:

```
  local LIGHT_UTILS = require("SKC4.LightingUtility")
  LIGHT_UTILS.from_rgb_to_hsv(10,20,30)
```

### LightingUtility.from_rgb_to_hsv(r, g, b)
### LightingUtility.from_hsv_to_rgb(h, s, v)

Functions that convert from RGB color model to HSV and vice versa.
They return a tuple of values.


### LightingUtility.form_RGB_single_value(r, g, b)
### LightingUtility.form_single_value_RGB(value)

Function that from a single value returns an RGB triple based on an internal table and its complementary function.
The internal table has been defined by us.



### LightingUtility.round(value)
### LightingUtility.radians_to_degrees(rad)
### LightingUtility.degrees_to_radians(deg)

Mathematical utility functions for internal use of the module.