[Torna all'indice](index.md)

# DriverCore.lua

Questo modulo semplifica la creazione di nuovi driver mettendo a disposizione automaticamente tutti gli handler degli eventi di Control4.

Questo consente di concentrarsi solo sullo sviluppo del codice che risponde al singolo evento che ci interessa, demandando al modulo la gestione del flusso corretto di funzionamento o la definizione di eventuali comportamenti di default.

Un esempio tipico è che tutta la gestione della console di debug Lua di Composer è gestita in modo autonomo e consistente su tutti i driver che useranno `DriverCore` oppure non sarà più necessario scrivere il codice che nel OnDriverInit() si preoccupa di aggiornare i valori delle _properties_ poiché sarà fatto in modo trasparente dal modulo stesso.

## Come usare `DriverCore` in un driver

_DriverCore_ richiede la modifica di _driver.xml_ e l'aggiunta di alcune chiamate specifiche al vostro driver.

### Modifiche a _driver.xml_

Per il corretto funzionamento del codice lua è necessario predisporre una serie di proprietà. Aggiungere al _driver.xml_ nella sezione `<properties>` del file.
```   
      <property>
				<name>Log Section</name>
				<type>LABEL</type>
				<default>Logging</default>
			</property>
      <property>
				<name>Log Level</name>
				<type>LIST</type>
				<readonly>false</readonly>
				<default>Off</default>
				<items>
          <item>Off</item>
          <item>5 - Debug</item>
          <item>4 - Trace</item>
          <item>3 - Info</item>
          <item>2 - Warning</item>
          <item>1 - Error</item>
          <item>0 - Alert</item>
				</items>
			</property>
      <property>
				<name>Log Mode</name>
				<type>LIST</type>
				<readonly>false</readonly>
				<default>Print</default>
				<items>
          <item>Print</item>
          <item>Log</item>
          <item>Print and Log</item>
				</items>
			</property>
      <property>
				<name>Disable Log Interval</name>
        <description>Autmatically disable logging after this interval of time</description>
				<type>LIST</type>
				<readonly>false</readonly>
				<default>1 hour</default>
				<items>
          <item>15 minutes</item>
          <item>30 minutes</item>
          <item>1 hour</item>
          <item>6 hours</item>
          <item>24 hours</item>
          <item>Never</item>
				</items>
			</property>
      
      <property>
				<name>Driver Info</name>
				<type>LABEL</type>
				<default>Driver Info</default>
			</property>
      <property>
				<name>Driver Version</name>
				<type>STRING</type>
				<default>---</default>
        <readonly>true</readonly>
			</property>
```

### Modifiche al codice Lua.

Per quanto riguarda invece le modifiche al file `driver.lua` queste sono minime:

1. Includere il modulo con il comando:
    `require 'SKC4.DriverCore'` all'inizio del file.

Basta questo e avete finito: a questo punto il driver dovrebbe essere in grado di gestire i vari eventi Control4. Se volete gestire anche le licenze fate riferimento al modulo  [`LicenseManagerDriverCentral.lua`](./licensemanagerdrivercentral.md).

### Struttura del driver

Vediamo come va strutturato un driver che usa il modulo `DriverCore`.

Dato che `DriverCore` risponde automaticamente ai principali eventi di Control4, l'unica cosa che va fatto in un file `driver.lua` è quello di definire delle funzioni specifiche per ogni evento in modo che siano visibili a `DriverCore` e possa richiamarla all'occorrenza. Per fare questo, il modulo crea una serie di tabelle che vengono usate per contenere le varie funzioni e sarà il sistema a richiamarle automaticamente.

#### Le tabelle eventi

Ecco le tabelle al momento disponibili:

  - `ON_DRIVER_EARLY_INIT`: contiene tutte le funzioni che rispondono all'evento di Control4 OnDriverInit() che devono essere eseguite all'inizio dell'evento, prima di ogni altra cosa;
  - `ON_DRIVER_INIT`: contiene tutte le funzioni che rispondono all'evento di Control4 che devono essere eseguite all'evento OnDriverInit() e che saranno eseguite prima di recuperare i valori delle _properties_ del driver ma dopo quelle contenute in `ON_DRIVER_EARLY_INIT`;
  - `ON_DRIVER_LATE_INIT`: contiene tutte le funzioni che rispondono all'evento di Control4 OnDriverLateInit();
  - `ON_DRIVER_DESTROYED`: contiene tutte le funzioni che rispondono all'evento di Control4 OnDriverDestroyed(), che è eseguito prima di eliminare un driver dal controller;
  - `ON_PROPERTY_CHANGED`: contiene tutte le funzioni che rispondono all'evento di Control4 OnPropertyChanged();
  - `ACTIONS`: contiene tutte le funzioni che rispondono alle Action presenti nell'XML;
  - `COMMANDS`: contiene tutte le funzioni che rispondono all'evento di Control4 ExecuteCommand();
  - `CONDITIONALS`: contiene tutte le funzioni che rispondono all'evento di Control4 TestCondition();
  - `PROXY_COMMANDS`: contiene tutte le funzioni che rispondono all'evento di Control4 ReceivedFromProxy();
  - `NOTIFICATIONS`: contiene tutte le funzioni che rispondono all'evento di Control4 di notifica (*NON IMPLEMENTATO AL MOMENTO*);
  - `UI_REQUEST`: contiene tutte le funzioni che rispondono alle richieste inviate con C4:SendUiRequest di Control4;

#### Come aggiungere una funzione alle tabelle eventi

Per aggiungere una funzione ad una tabella, si usa la seguente sintassi:

```
function NOME_TABELLA.Nome_Funzione(parametro)
  --- qui il codice
end
```

quindi, ad esempio, per aggiungere una funzione che deve essere eseguita all'evento OnDriverInit() che voglio chiamare `fai_qualcosa()`, scriverò:

```
function SKC4_ON_DRIVER_INIT.fai_qualcosa()
  -- do something
end
```

I parametri accettati dalle funzioni devono rispecchiare quelle definite dai rispettivi eventi Control4. Ad esempio `OnPropertyChanged(sProperty)` riceve il parametro `sPropery`, quindi la funzione `SKC4_ON_PROPERTY_CHANGED.my_property(sProperty)` deve accettare un parametro `sProperty`.

#### Convenzione per il nome delle funzioni delle tabelle eventi

I nomi delle funzioni sono libere (ovvero il loro nome non influisce sui meccanismi di buon funzionamento del modulo `DriverCore`) per le tabelle eventi:

  - `ON_DRIVER_EARLY_INIT`
  - `ON_DRIVER_INIT`
  - `ON_DRIVER_LATE_INIT`
  - `ON_DRIVER_DESTROYED`

Invece è presente una convenzione specifica per:

  - `ON_PROPERTY_CHANGED`: il nome della funzione deve essere uguale al nome della proprietà di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `COMMANDS`: il nome della funzione deve essere uguale al nome del comando di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `ACTIONS`: il nome della funzione deve essere uguale al nome della action di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `PROXY_COMMANDS`: il nome della funzione deve essere uguale al nome del comando di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `VARIABLE_CHANGED`: il nome della funzione deve essere uguale al nome della variabili di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `CONDITIONALS`: il nome della funzione deve essere uguale al nome della _conditional_ presente nell'XML di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `NOTIFICATIONS`: *DA DEFINIRE. NON IMPLEMENTATO AL MOMENTO*
  - `UI_REQUEST`: il nome della funzione deve essere uguale al nome della stringa di richiesta inviata con C4:SendUIRequest ove però, in caso di spazi, questi sono stati sostituiti da '_' (underscore);

Ad esempio se vogliamo gestire l'OnPropertyChanged della proprietà "Numero Porta IP", la funzione da definire sarà:

```
function ON_PROPERTY_CHANGED.Numero_Porta_IP(propertyValue)
  --- qui il codice
end
```

Se invece vogliamo gestire il cambio di valore di una variabile, la funzione sarà:

```
function ON_VARIABLE_CHANGED.SUNLIGHT_HIGH_THRESHOLD_STRING()
  --- la funzione non accetta nessun valore
  local var_value = Variables[VAR_NAME_SUNLIGHT_HIGH_THRESHOLD_STRING]
  --- qui il codice
end
```

Quando ci aspettiamo di ricevere un comando da una connection (es "RECEIVED_NEW_DATA") la funzione sarà:

```
function PROXY_COMMANDS.RECEIVED_NEW_DATA(tPrams, idBinding)
  --- qui il codice
end
```

Se ci attendiamo di processare la risposta ad un comando C4:SendUiRequest() come quando da Composer chiediamo la stringa di test di una telecamera ("GET_RTSP_H264_QUERY_STRING") la funzione sarà:

```
function UI_REQ.GET_RTSP_H264_QUERY_STRING(tParams, idBinding)
	--- qui il codice
end
```

Per una conditional indicato nell'XML come "SERVICE_STATUS", infine, useremo una funzione del tipo:

```
function CONDITIONALS.SERVICE_STATUS(tParams)
  --- qui il codice
end
```



Notare come deve essere conservato il _case_ del nome della proprietà perché il modulo `DriverCore` distingue tra maiuscole e minuscole.

**NB.**

Esistono delle versioni interne alla libreria di queste tabelle per consentire di gestire separatamente le chiamate interne con quelle del driver vero e proprio evitando conflitti. Le tabelle sono:
`SKC4_ON_DRIVER_EARLY_INIT`, `SKC4_ON_DRIVER_INIT`, `SKC4_ON_DRIVER_LATE_INIT`, `SKC4_ON_DRIVER_DESTROYED`, `SKC4_ON_PROPERTY_CHANGED`, `SKC4_COMMANDS`, `SKC4_ACTIONS`, `SKC4_PROXY_COMMANDS`, `SKC4_VARIABLE_CHANGED`, `SKC4_NOTIFICATIONS`, `SKC4_CONDITIONALS`.


### API

Segue elenco delle *chiamate pubbliche* messe a diposizione dal modulo. Il modulo mette a disposizione altre chiamate che non sono solitamente necessarie. Si faccia riferimento al codice per le altre chiamate.

#### `LOGGER`

Per il log di debug, `DriverCore` mette a disposizione in modo automatico un oggetto `SKC4:Logger` nella variabile globale `LOGGER`. Quindi per mandare in stampa un messaggio di debug, ad esempio, basta scrivere:

```
LOGGER:debug("Questo è un messaggi di debug")
```

Il logger messo a disposizione in modo automatico dal modulo convoglia tutti i messaggio di debug della libreria (ovvero è un alias per `SKC4_LOGGER`). Se si vogliono tenere separati i dati di log del driver da quelli della libreria è necessario creare un nuovo oggetto da assegnare alla variabile `LOGGER` con la chiamata:

```
LOGGER = Logger.new()
```

Per maggiori dettagli sul modulo `Logger` si faccia riferimento alla [guida](./logger.md)



#### `UpdateProperty(propertyName, propertyValue)`

Questa è una funzione globale richiamabile quindi in ogni punto del file `driver.lua` per aggiornare il valore di una proprietà. Si tratta di un _wrapper_ di `C4:UpdateProperty(propertyName, propertyValue)` e accetta gli stessi parametri di quella di Control4. L'utilizzo di questa funzione al posto di quella nativa dà la sicurezza che tutti gli eventi intercettati dal modulo `DriverCore` siano correttamente gestiti.


#### `ShowProperty(propertyName)`
#### `HideProperty(propertyName)`
#### `SetPropertyVisility(propertyName, isVisible)`
Queste funzioni sono globali e richiamabile quindi in ogni punto del file `driver.lua` rispettivamente per mostrare o nascondere una property in Composer.
Si tratta di _wrapper_ rispettivamente di:

  -  `C4:SetPropertyAttribs(propertyName, 0)`
  -  `C4:SetPropertyAttribs(propertyName, 1)`
  -  `C4:SetPropertyAttribs(propertyName, 0|1)` dove il parametro 0|1 è ricavato dal booleano isVisible



#### `AddVariable(strName, strValue, strVarType, bReadOnly, bHidden)`
#### `GetVariable(strName)`
#### `SetVariable(strName, strValue)`

Queste funzioni sono globali e richiamabile quindi in ogni punto del file `driver.lua` rispettivamente per aggiungere una variable e recuperarne il valore. 
Si tratta di _wrapper_ di:

  -  `C4:AddVariable(strName, strValue, strVarType, bReadOnly, bHidden)` e accetta di stessi parametri;
  -  `C4:GetVariable(idDevice, idVariable)` ma usa il nome della variabile come parametro;
  -  `C4:SetVariable(strName, strValue)` e accetta di stessi parametri.

Usando queste funzioni è possibile gestire le variabili del driver corrente (*SOLO DEL DRIVER CORRENTE*) usando direttamente il nome della stessa senza dover tenere traccia degli id numerici. *Non mischiate queste funzioni con quelle C4*.

**NB: Se dovete gestire variabili dinamicamente, fate riferimento al modulo [Dynamic Variable Manager](dynamicvariablemanager.md)**

