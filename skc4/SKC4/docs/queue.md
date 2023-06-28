[Back to the index](index.md)

# Queue.lua

This module manages a generic FIFO (first in, first out) queue. The module is able to pair unique keys with inserted elements so as to update the elements in the queue while preserving their position.


## How to use `Queue` in a driver

1. _Queue_ requires including the lua module at the beginning of the file where you want to use it:
    `require 'SKC4.Queue'`

2. Each time you want to create a queue, you should use `Queue:new()`. This allows to have several active queues at the same time.

    `local q = Queue:new()`

### Traditional push and pop actions

To add a new element to the queue, use the following calls: 

`Queue:push(object)`: adds an element (_object_) to the end of the queue. Any element accepted as a Lua table element can be passed as a parameter.

`Queue:pop()`: extracts an element from the queue and returns it. If the queue is empty, it returns `nil`

Example:
``` 
q = Queue:new()

q:push("ciccio1") -- adds the string "ciccio1" to the queue
q:push("ciccio2") -- adds the string "ciccio2" to the queue

local v = q:pop() -- v contains "ciccio1"

```

### Push and pop actions with identifier

There is the possibility to pair each enqueued element with an identifier (_key_) that allows to make a specific reference to an enqueued element. This allows to update the enqueued object without altering its position in the queue.

`Queue:push_by_key(key, object)`: the function adds _object_ to the queue, marking the element with the identifier _key_.

`Queue:pop_by_key(key)`: removes the element marked with the identifier _key_ and returns it.


Example:
``` 
q = Queue:new()
q:push_by_key("uno","ciccio1")
q:push_by_key("due","ciccio2")
q:push_by_key("tre","ciccio3") -- the queue contains 3 elements
q:push_by_key("due","due_modificato") -- modifies the element identified by the key _due_
q:push_by_key("tre","ciccio_tre") -- modifies the element identified by the key _tre_

local v = q:pop_by_key("due") -- v contains "due_modificato"
v = q:pop_by_key("uno") -- v contains "ciccio1"
v = q:pop_by_key("due") -- v contains nil
```

### Other useful functions

`Queue:size()`: returns the number of elements in the queue. 
`Queue:is_empty()`: returns `true` if the queue is empty, otherwise `false`  
`Queue:empty()`:  empties the queue

### Testing functions
`Queue.self_test()`:  this function runs a series of tests to verify the functioning of the module. In case of modifications to the module, it should be enriched and called to verify that everything continues to work properly
