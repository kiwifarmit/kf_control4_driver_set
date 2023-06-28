[Torna all'indice](index.md)

# Queue.lua

Questo modulo gestisce una coda generica di tipo FIFO (first in, fisrt out). Il modulo è in grado di abbinare agli elementi inesriti anche una chiave unica in modo da poter aggiornare gli elementi presenti in coda preservandone la posizione.


## Come usare `Queue` in un driver

1. _Queue_ richiede di includere il modulo lua all'inizio del file in cui lo si vuole usare:
    `require 'SKC4.Queue'`

2. Ogni volta che si vuole creare una coda si deve usare `Queue:new()`. Questo permette di avere diverse code attive contemporaneamente.

    `local q = Queue:new()`

### Azioni di push e pop tradizionali

Per aggiungere un nuovo elemento nella coda usare le chiamate: 

`Queue:push(object)`: aggiunge un elemento in coda (_object_). Qualsiasi elemento accettato come lemento di una tablella Lua, può essere passato come parametro.

`Queue:pop()`: estrae un elemento dalla coda e lo restituisce. Se la coda è vuota, viene ritornato il valore `nil`

Esempio:
``` 
q = Queue:new()

q:push("ciccio1") -- aggiunge in coda la stringa "ciccio1"
q:push("ciccio2") -- aggiunge in coda la stringa "ciccio2"

local v = q:pop() -- v contiene "ciccio1"

```

### Azioni di push e pop con identificativo

C'è la possibilità di abbinare ad ogni elemento messo in coda un indentificativo (_key_) che permette di fare riferimento specifico ad un elemento accodato. Questo permette di aggiornare l'oggetto accodato senza alterarne la posizione in coda.

`Queue:push_by_key(key, object)`: la funzione aggiunge _object_ in coda marcando l'elemento con l'identificativo _key_.

`Queue:pop_by_key(key)`: toglie l'elemento marcato con l'identificativo _key_ e lo restituisce.


Esempio:
``` 
q = Queue:new()
q:push_by_key("uno","ciccio1")
q:push_by_key("due","ciccio2")
q:push_by_key("tre","ciccio3") -- la coda contiene 3 elementi
q:push_by_key("due","due_modificato") -- modifica l'elemento identificato con la chiave _due_
q:push_by_key("tre","ciccio_tre") -- modifica l'elemento identificato con la chiave _tre_

local v = q:pop_by_key("due") -- v contiene "due_modificato"
v = q:pop_by_key("uno") -- v contiene "ciccio1"
v = q:pop_by_key("due") -- v contiene nil
```

### Altre funzioni utili

`Queue:size()`: restituisce il numero di elementi presenti in coda. 
`Queue:is_empty()`: restituisce `true` se la coda è vuota, oppure `false`  
`Queue:empty()`:  svuota la coda

### Funzioni di testing
`Queue.self_test()`:  questa funzione esegue una serie di test per verificare il funzionamento del modulo. In caso di modifiche al modulo, andrebbe arricchita e chiamata per verificare che tutto continui a funzionare
