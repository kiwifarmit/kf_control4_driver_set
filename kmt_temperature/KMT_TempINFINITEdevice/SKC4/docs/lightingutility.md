[Torna all'indice](index.md)

# Utility

Contiene funzioni vari d'utilità per le luci.
Documentazione da completare.
Esempio di come usare le libreria:

```
  local LIGHT_UTILS = require("SKC4.LightingUtility")
  LIGHT_UTILS.from_rgb_to_hsv(10,20,30)
```

### LightingUtility.from_rgb_to_hsv(r, g, b)
### LightingUtility.from_hsv_to_rgb(h, s, v)

Funzioni che convertono da modello colore RGB a HSV e viceversa.
Restituiscono una tupla di valori.


### LightingUtility.form_RGB_single_value(r, g, b)
### LightingUtility.form_single_value_RGB(value)

Funzione che da un singolo valore restituisce una tripla RGB in base ad una tabella interna e sua funzione complementare.
La tabella interna è stata definita da noi.



### LightingUtility.round(value)
### LightingUtility.radians_to_degrees(rad)
### LightingUtility.degrees_to_radians(deg)

Funzioni di utilità matematiche ad uso interno del modulo.