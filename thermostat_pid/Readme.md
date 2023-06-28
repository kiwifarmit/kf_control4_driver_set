# Thermostat Pid

## To finish

- parte licenze
- la modalità AUTO della connessione MODALITà del thermostato non è gestita

## To Fix

- definire la fan su che connection deve uscire

## DOC

### Connessioni
- Heating Input: relay dell'heating
- Cooling Input: relay del cooling
- Fan Input: relay del Fan
- Temperature Input: connession temperatura in ingresso dal termostato
- Heating Setpoint Input: connessione setpoint heating in ingesso dal termostato
- Cooling Setpoint Input: connessione setpoint cooling in ingresso del termostato
- Setpoint Input: NON GESTITA
- Outdoor Temperature Input: NON GESTITA
- Humidity Input: NON GESTITA
- Theshold Condition On: NON GESTITA
- Heating Direct Output: output corrispondente a Heating Input
- Cooling Direct Output: output corrispondente a Cooling Input
- Fan Direct Output: output corrispondente a Fan Input
- Heating PID Output: relay CHIUSO se l'output del PID è sopra soglia (vedi properties), altrimenti APERTO
- Cooling PID Output: relay CHIUSO se l'output del PID è sopra soglia (vedi properties), altrimenti APERTO
- Fan PID Output: NON GESTITO (valore di uscita del PID)

### Installazione (la prima volta)
1 - la prima volta che si fanno le connessioni con il termostato bisogna reimpostare i setpoint Heat e Cool così che il driver li memorizzi in persist (solo la prima volta)
2 - dalle Action settare la modalità corrente (Heat o Cool, solo la prima volta)

### Nota Bene:
- i valori di heat e cool che vengono passati da termostato non devono essere cambiati... deve proprio esserci scritto "HEAT" e "COOL"
- la modalità AUTO non è gestita