[Torna all'indice](index.md)

# LicenseManagerDriverCentral.lua

Questo modulo permette la gestione della sola licenza di DriverCentral.

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
```

Se non siete interessati a un provider, potete togliere l'item relativo nella property License Provider così da disattivarlo.

### Modifiche al codice Lua.

1. Includere il modulo di gestione della licenza con il comando:
    `require 'SKC4.LicenseManagerDriverCentral'`

2. Impostare i valori di inizializzazione dei parametri subito dopo la `require` del punto precedente:
```
    DC_LICENSE_MGR:setProductId(<product id di DriverCentral>)
    DC_LICENSE_MGR:setFreeDriver(<true se gratuito, false altrimenti>)
    DC_LICENSE_MGR:setFileName(<nome del file .c4z>)
```

3. **Se state usando il modulo DriverCore, potete passare avanti. DriverCore verifica se avete incluso questo modulo e fa i setup automaticamente** Altrimenti, aggiungere gli hook degli eventi OnDriverInit():
    * funzione _function OnDriverInit()_:
```
      DC_LICENSE_MGR:init()
```

4. Fine: a questo punto il driver dovrebbe essere in grado di gestire il provider di licenze.

## API 

Segue elenco delle *chiamate pubbliche* messe a diposizione dal modulo. Il modulo mette a disposizione altre chiamate che non sono solitamente necessarie. Si faccia riferimento al codice per le altre chiamate.

### `LicenseManagerDriverCentral:new(o)`

Questa funzione è il costruttore dell'oggetto LicenseManagerDriverCentral. *Non viene mai chiamato esplicitamente* poiché il modulo mette a disposizione con la `require` una variabile globale `DC_LICENSE_MGR` che contiene già un oggetto configurato e pronto all'uso. 

Nota: `DC_LICENSE_MGR` è un _singleton_ ovvero un oggetto unico che può essere condiviso in tutti i file lua con la certezza che sia sempre lo stesso e non uno diverso.

### `function LicenseManagerDriverCentral:init()`
### `function LicenseManagerDriverCentral:init(productId, freeDriver, filename)`
Questa funzione inizializza e abilita la comunicazione con DriverCentral. Questa è l'unica funzione da chiamare esplicitamente.

Se avete impostato i parametri di DriverCentral con i setter (vedi dopo), usate la chiamata `init()` senza parametri.

Se invece volete impostare i parametri e attivare la comunicazione contestualmente, potete usare la chiamata con i parametri.
I parametri da indicare sono quelli richiesti da DriverCentral:

`productId`:    il product ID del prodotto su DriverCentral
`freeDriver`:   true se il driver è gratuito, false altrimenti
`param_key`:    il nome del file .c4z del driver

La documentazione di DriverCentral è disponibile nell'area Vendor del marketplace, sono il menu [Vendor/DriverCentral](https://drivercentral.io/vendor.php?dispatch=view_api.new)

### `function LicenseManagerDriverCentral:setProductId(value)`
### `function LicenseManagerDriverCentral:getProductId()`
### `function LicenseManagerDriverCentral:setFreeDriver(value)`
### `function LicenseManagerDriverCentral:getFreeDriver()`
### `function LicenseManagerDriverCentral:setFileName(value)`
### `function LicenseManagerDriverCentral:getFilename()`
Queste funzioni settano i parametri richiesti da DriverCentral per la licenza. Queste chiamate sono pensate per un uso interno dato che i valori di questi parametri devono essere impostati prima dell'importazione del codice di DriverCentral (vedi funzione `init()`)


### `LicenseManagerDriverCentral:setParamValue(param_key, param_value, vendor_id)`
### `LicenseManagerDriverCentral:getParamValue(param_key, vendor_id)`
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

### `LicenseManagerDriverCentral:isLicenseActive()`
### `LicenseManagerDriverCentral:isLicenseTrial()`
### `LicenseManagerDriverCentral:isLicenseActiveOrTrial()`
Sono funzioni che interrogano il gestore di licenza per sapere il rispettivamente se la licenza è attiva, si è nel periodo di prova o se ci si trova i una delle due situazioni.

Il valore tornato è un booleano fa riferimento al gestore di licenza attualmente selezionato nelle proprietà del driver su Composer Pro.

### `LicenseManagerDriverCentral:isAbleToWork()`
Questa funzione restituisce `true` se il driver è autorizzato (qualsiasi sia lo stato corrente) o `false` se il driver non è autorizzato. _NB: al momento è un alias di `isLicenseActiveOrTrial()` ma in generale copre un maggior numero di stati possibili_


