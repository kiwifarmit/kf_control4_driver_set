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
      
```

### Modifiche al codice Lua.

Per quanto riguarda invece le modifiche al file `driver.lua` queste sono minime:

1. Includere il modulo con il comando:
    `require 'SKC4.DiverCore'` all'inizio del file.

Basta questo e avete finito: a questo punto il driver dovrebbe essere in grado di gestire i vari eventi Control4. Se volete gestire anche le licenze fate riferimento al modulo  [`LicenseManager.lua`](./licensemanager.md).

### Struttura del driver

Vediamo come va strutturato un driver che usa il modulo `DriverCore`.

Dato che `DriverCore` risponde automaticamente ai principali eventi di Control4, l'unica cosa che va fatto in un file `driver.lua` è quello di definire delle funzioni specifiche per ogni evento in modo che siano visibili a `DriverCore` e possa richiamarla all'occorrenza. Per fare questo, il modulo crea una serie di tabelle che vengono usate per contenere le varie funzioni e sarà il sistema a richiamarle automaticamente.

#### Le tabelle eventi

Ecco le tabelle al momento disponibili:

  - `SKC4_ON_DRIVER_EARLY_INIT`: contiene tutte le funzioni che rispondono all'evento di Control4 OnDriverInit() che devono essere eseguite all'inizio dell'evento, prima di ogni altra cosa;
  - `SKC4_ON_DRIVER_INIT`: contiene tutte le funzioni che rispondono all'evento di Control4 che devono essere eseguite all'evento OnDriverInit() e che saranno eseguite prima di recuperare i valori delle _properties_ del driver ma dopo quelle contenute in `SKC4_ON_DRIVER_EARLY_INIT`;
  - `SKC4_ON_DRIVER_LATEINIT`: contiene tutte le funzioni che rispondono all'evento di Control4 OnDriverLateInit();
  - `SKC4_ON_DRIVER_DESTROYED`: contiene tutte le funzioni che rispondono all'evento di Control4 OnDriverDestroyed(), che è eseguito prima di eliminare un driver dal controller;
  - `SKC4_ON_PROPERTY_CHANGED`: contiene tutte le funzioni che rispondono all'evento di Control4 OnPropertyChanged();
  - `SKC4_COMMANDS`: contiene tutte le funzioni che rispondono all'evento di Control4 ExecuteCommand();
  - `SKC4_PROXY_COMMANDS`: contiene tutte le funzioni che rispondono all'evento di Control4 ReceivedFromProxy();
  - `SKC4_NOTIFICATIONS`: contiene tutte le funzioni che rispondono all'evento di Control4 di notifica (*NON IMPLEMENTATO AL MOMENTO*)

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

  - `SKC4_ON_DRIVER_EARLY_INIT`
  - `SKC4_ON_DRIVER_INIT`
  - `SKC4_ON_DRIVER_LATEINIT`
  - `SKC4_ON_DRIVER_DESTROYED`

Invece è presente una convenzione specifica per:

  - `SKC4_ON_PROPERTY_CHANGED`: il nome della funzione deve essere uguale al nome della proprietà di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `SKC4_COMMANDS`: il nome della funzione deve essere uguale al nome del comando di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `SKC4_PROXY_COMMANDS`: il nome della funzione deve essere uguale al nome del comando di cui si vuole gestire l'evento ove però gli spazi sono stati sostituiti da '_' (underscore);
  - `SKC4_NOTIFICATIONS`: *DA DEFINIRE. NON IMPLEMENTATO AL MOMENTO*

Ad esempio se vogliamo gestire l'OnPropertyChanged della proprietà "Numero Porta IP", la funzione da definire sarà:

```
function SKC4_ON_PROPERTY_CHANGED.Numero_Porta_IP(sProperty)
  --- qui il codice
end
```

Notare come deve essere conservato il _case_ del nome della proprietà perché il modulo `DriverCore` distingue tra maiuscole e minuscole.



### API

Segue elenco delle *chiamate pubbliche* messe a diposizione dal modulo. Il modulo mette a disposizione altre chiamate che non sono solitamente necessarie. Si faccia riferimento al codice per le altre chiamate.

#### `SKC4_LOGGER`

Per il log di debug, `DriverCore` mette a disposizione in modo automatico un oggetto `SKC4:Logger` nella variabile globale `SKC4_LOGGER`. Quindi per mandare in stampa un messaggio di debug, ad esempio, basta scrivere:

```
SKC4_LOGGER:debug("Questo è un messaggi di debug")
```

Per maggiori dettagli sul modulo `Logger` si faccia riferimento alla [guida](./logger.md)



#### `UpdateProperty(propertyName, propertyValue)`

Questa è una funzione globale richiamabile quindi in ogni punto del file `drvier.lua` per aggiornare il valore di una proprietà. Si tratta di un _wrapper_ di `C4:UpdateProperty(propertyName, propertyValue)` e accetta gli stessi parametri di quella di Control4. L'utilizzo di questa funzione al posto di quella nativa dà la sicurezza che tutti gli eventi intercettati dal modulo `DriverCore` siano correttamente gestiti.