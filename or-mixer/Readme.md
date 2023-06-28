# Or Mixer

## to finish

- parte license
- vedere se le funzioni in -- PROPERTIES funzionano
- creare connessioni in putput
- scrivere comando per connessioni in output

## DOC

### Connections
#### Input
- Or Mixer Input Connection 1
.
.
- Or Mixer Input Connection 5
Input connections of the algorithm
#### Output
- Or Mixer Output Connection 1
.
.
- Or Mixer Output Connection 40
Output connections of the algorithm

### Property
- Connection 1 Mapping
.
.
- Connection 5 Mapping
This property declare which output is associate to the property input.
The list of output associate to the input is in CSV format.

E.G.: 1,3,38 If this is the property value, this input will control the output 1, 3 e il 38.
The output control is not straight with the input but is throgh a logical or function with the others inputs that are associate to the output.


### Action
__Print Mapping and Status__
Print on lua console's output the state of the input, the state of the output calculated and the mapping between the output and the input.
This information is needed for DEBUG purpose and take a look inside the driver job.

__Force all Output__
This Action Force the driver to re-set all the state of the output based on the input state.

### Funzionamento
The driver is a mixer that maps the input relay connections to the output relay connection.
The mapping is based on the list of the output associated to an input connection declare on the relative property.
The state of the output is calculated doing a "logical or operation" between all the input's state, associate to the output.

So E.G.
Connection 1 Mapping = "1,2,3"
Connection 2 Mapping = "3,4,5"
Connection 3 Mapping = "3"

Connection 1 State = 1
Connection 2 State = 0
Connection 3 State = 0

Output 1 depends on: Input 1
Output 2 depends on: Input 1
Output 3 depends on: Input 1,2,3
Output 4 depends on: Input 2
Output 5 depends on: Input 3


Output 1 calculated state: 1
Output 2 calculated state: 1
Output 3 calculated state: 1 or 0 or 0 -> 1
Output 4 calculated state: 0
Output 5 calculated state: 0