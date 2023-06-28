# LicenseManager.lua

Questo modulo permette la gestione di varie tipologie di licenze. Al momento:
* Houselogix
* DriverCentral
* Licenza proprietaria soft.kiwi

## Come aggiungere la gestione licenze ad un driver

Per aggiungere il supporto alla licenza è necessario modificare _driver.xml_ e aggiungere alcune chiamate specifiche al vostro driver.

### Modifiche a _driver.xml_

Per il corretto funzionamento del codice lua è necessario predisporre una serie di proprietà. Aggiungere al _driver.xml_ nella sezione `<properties>` del file.
```
      <property>
				<name>License Section</name>
				<type>LABEL</type>
				<default>Licensing</default>
			</property>

      <property>
        <name>License Provider</name>
        <default />
        <type>LIST</type>
        <items>
          <item>Driver Central</item>
          <item>Houselogix</item>
          <item>SoftKiwi</item>
        </items>
        <readonly>false</readonly>
      </property>
      <property>
        <name>Cloud Status</name>
        <default />
        <type>STRING</type>
        <readonly>true</readonly>
      </property>
      <property>
        <name>Automatic Updates</name>
        <type>LIST</type>
        <items>
          <item>Off</item>
          <item>On</item>
        </items>
        <default>Off</default>
        <readonly>false</readonly>
      </property>
      <property>
        <name>Houselogix License Code</name>
        <default />
        <type>STRING</type>
        <readonly>false</readonly>
        <default>type your license code here</default>
      </property>
      <property>
        <name>Houselogix License Status</name>
        <type>STRING</type>
        <readonly>true</readonly>
        <default />
      </property>
      <property>
        <name>SoftKiwi License Code</name>
        <default />
        <type>STRING</type>
        <readonly>false</readonly>
        <default>type your license code here</default>
      </property>
      <property>
        <name>SoftKiwi Driver Type</name>
        <type>STRING</type>
        <readonly>true</readonly>
        <default />
      </property>
      <property>
        <name>SoftKiwi License Status</name>
        <type>STRING</type>
        <readonly>true</readonly>
        <default />
      </property>
```

Se non siete interessati a un provider, potete togliere l'item relativo nella property License Provider così da disattivarlo.

### Modifiche al codice Lua.

1. Includere il modulo di gestione della licenza con il comando:
    `require 'SKC4.LicenseManager'`

2. Inizializzare con i valori di default richiesta il module LicenseManager ad esempio (vedi descrizione `setParamValue()` più giù per maggiori dettagli sui possibili valori):
    ```  
    --- Config License Manager  
          LICENSE_MGR:setParamValue("ProductId", 999, "DRIVERCENTRAL") -- Product ID  
          LICENSE_MGR:setParamValue("FreeDriver", false, "DRIVERCENTRAL") -- (Driver is not a free driver)  
          LICENSE_MGR:setParamValue("FileName", "telegram-bot.c4z", "DRIVERCENTRAL")  
          LICENSE_MGR:setParamValue("ProductId", 999, "HOUSELOGIX")  
          LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "HOUSELOGIX")  
          LICENSE_MGR:setParamValue("LicenseCode", "Put here your licence", "SOFTKIWI")  
          LICENSE_MGR:setParamValue("Version", C4:GetDriverConfigInfo ("version"), "HOUSELOGIX")  
          LICENSE_MGR:setParamValue("Trial", LICENSE_MGR.TRIAL_NOT_STARTED, "HOUSELOGIX")  
    --- end license  
    ```

3. Se state usando il modulo DriverCore, potete passare avanti. Altrimenti, aggiungere gli hook degli eventi aggiungengo le seguenti chiamate/blocchi di codice nelle relative funzioni indicate. Solitamente si possono inserire alla fine delle funzioni:
    * funzione _function OnDriverInit()_:
      ```
      LICENSE_MGR:OnDriverInit()
      ```
    * funzione _OnDriverLateInit()_:
      ```
      LICENSE_MGR:OnDriverLateInit() 
      ```
    * funzione _ReceivedFromProxy(idBinding, sCommand, tParams)_: 
      ```
      LICENSE_MGR:ReceivedFromProxy(idBinding, sCommand, tParams)
      ```
    * funzione _OnPropertyChanged(strProperty)_:
      ```
      LICENSE_MGR:OnPropertyChanged(strProperty)
      ```

Fine: a questo punto il driver dovrebbe essere in grado di gestire i vari provider di licenze.

## API 

Segue elenco delle *chiamate pubbliche* messe a diposizione dal modulo. Il modulo mette a disposizione altre chiamate che non sono solitamente necessarie. Si faccia riferimento al codice per le altre chiamate.

### `LicenseManager:new(o)`

Questa funzione è il costruttore dell'oggetto LicenseManager. *Non viene mai chiamato esplicitamente* poiché il modulo mette a disposizione con la `require` una variabile globale `LICENSE_MGR` che contiene già un oggetto configurato e pronto all'uso. 

Nota: `LICENSE_MGR` è un _singleton_ ovvero un oggetto unico che può essere condiviso in tutti i file lua con la certezza che sia sempre lo stesso e non uno diverso.



### `LicenseManager:getCurrentVendorId()`
Restituisce una stringa che indica il sistema di licenza attualmente in uso. Il valore ritornato è una stringa tra `DRIVERCENTRAL`, `HOUSELOGIX`, `SOFTKIWI`, `UNKNOWN`.

### `LicenseManager:getCurrentVendorName()`
Restituisce una stringa che con il nome del sistema di licenza attualmente in uso. Il valore ritornato è quello indicato nelle _proprety_ del driver.

### `LicenseManager:setParamValue(param_key, param_value, vendor_id)`
### `LicenseManager:getParamValue(param_key, vendor_id)`
Queste funzioni permetto di settare e leggere i parametri di configurazioni necessari alla corretta comunicazione con i vari vendor.

`param_key`:    nome del parametro da assegnare
`param_value`:  valore del parametro da assegnare
`vendor_id`:    indica per quale sistema di licenze è il parametro. i valori possibili sono: `DRIVERCENTRAL`, `HOUSELOGIX`, `SOFTKIWI`

I parametri possibili per il gestore `DRIVERCENTRAL` sono:
  * *ProductId*: ID del prodotto fornito da Driver Central
  * *FreeDriver*:  è `true` se il driver è gratuito o `false` se è a pagamento
  * *FileName*: è il nome del file *.c4z del driver scaricato da drivercentral.io

I parametri possibili per il gestore `HOUSELOGIX` sono:
  * *ProductId*: ID del prodotto fornito da Houselogix
  * *ValidityCheckInterval*: intervallo (in minuti) ogni quanto sarà riverificata la licenza
  * TrialExpiredLapse*: durata (in ore) del periodo di prova
  * *Version*: numero di versione del driver

Non ci sono parametri per il gestore `SOFTKIWI`: ogni dato utile è recuperato dalle proprietà del driver su Composer Pro.


Si veda il paragrafo _Modifiche al codice Lua_ per un esempio di codice.

### `LicenseManager:isLicenseActive()`
### `LicenseManager:isLicenseTrial()`
### `LicenseManager:isLicenseActiveOrTrial()`
Sono funzioni che interrogano il gestore di licenza per sapere il rispettivamente se la licenza è attiva, si è nel periodo di prova o se ci si trova i una delle due situazioni.

Il valore tornato è un booleano fa riferimento al gestore di licenza attualmente selezionato nelle proprietà del driver su Composer Pro.

### `LicenseManager:isAbleToWork()`
Questa funzione restituisce `true` se il driver è autorizzato (qualsiasi sia lo stato corrente) o `false` se il driver non è autorizzato. _NB: al momento è un alias di `isLicenseActiveOrTrial()` ma in generale copre un maggior numero di stati possibili_



### `LicenseManager:OnDriverInit()`
### `LicenseManager:OnDriverLateInit()`
### `LicenseManager:ReceivedFromProxy(idBinding, sCommand, `tParams)
Queste sono funzioni che seguono le chiamate di sistema di Control4 e servono per intercettare gli enveti relativi e dare la possibilità al modulo di gestione licenze di interagire.

### `LicenseManager:OnPropertyChanged(strName, value)`
Anche questa funzione, come le precedenti, segue la chimata relativa di Control4 ma ha un paramentro `value` in più. `value` contiene il valore corrente della proprietà che ha scatenato l'evento (il cui nome è `strName`).
Il compito di recuperare il valore del parametro è lasciato allo sviluppatore. Solitamente è fatta con un codice tipo:
```
function OnPropertyChanged (strProperty) 
  local value = Properties[strProperty]

  -- ora che hai il valore e' possibile chiamare il gestore di licenze
  LICENSE_MGR:OnPropertyChanged(strProperty, value)
end
```