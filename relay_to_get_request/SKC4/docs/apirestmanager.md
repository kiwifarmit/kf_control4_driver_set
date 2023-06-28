[Torna all'indice](index.md)

# ApiRestManager.lua

Questo modulo centralizza la gestione di chiamate REST verso servizi cloud. Il modolo è in grado di gestire chiamate singole o multiple, ha una coda di gestione immediata o ritardata. Consente di creare chiamate generiche o basate su modelli che rappresentano gli endpoint.

Il modulo è basato sulle funzionalità C4:url() di Control4. Si consiglia di leggere la parte relativa del manuali "API Reference Guide" per approfondire.


## Come usare `ApiRestManager` in un driver

Si faccia riferimento alla voce _C4:url()_ nella guida _OS3 API Reference Guide_ per dettagli aggiuntivi sui parametri delle varie funzioni quando indicato.

1. _ApiRestManager_ richiede di includere il modulo lua all'inizio del file in cui lo si vuole usare:
    `require 'SKC4.ApiRestManager'`

2. Ogni volta che si vuole creare un gestore di servizi HTTP REST si deve usare `ApiRestManager:new()`. Questo consente di avere diversi gestori REST contemporaneamente attivi:

    `local api = ApiRestManager:new()`

3. Configurare il gestore indicato la url del server e, se necessario username e password per l'autenticazione (**al momento è supportata solo la BASE AUTHENTICATION**):

```
    api.set_base_url('http://192.168.1.100') -- definisce la url di base verso la quale saranno indirizzate le chiamate

    api.enable_basic_authentication() -- abilita la BASIC Authentication
    api.set_username('myusername') -- definisce la username da usare per l'autenticazione
    api.set_password('mypassword') -- definisce la password da usare per l'autenticazione
```

4. A questo punto possiamo accodare una o più richieste rest usando `ApiRestManager:add_request()`:

```
    -- Esempio chiamata GET

    -- tabella che contiene parametri per la chiamata
    -- aggiungiamo due parametri che saranno usati per creare
    -- la corretta query string ovvero "?id=100&call?mycall"
    params = {} 
    params['id']=100
    params['call']='mycall'

    -- definisce una funzione di callback che gestirsce la risposta del server
    function get_done_callback(transfer, responses, errCode, errMsg)
      ... il tuo codice ...
    end
    
    -- aggiungi la richiesta al gestore
    api:add_request("get", "/simple_get", nil, params, nil, get_done_callback)


    -- Esempio chiamata POST
    
    -- tabella che contiene di header delle chiamate
    -- usiamo gli headers per mandare parametri alla POST
    headers = { ["Expect"] = "100-continue" }
    headers['myheader1']="valore1"
    headers['myheader2']="valore2"

    -- tabella che contiene dati da inviare.
    -- di default le tabelle sono trasformate in json,
    -- altri valori sono trasformati in stringhe
    data = {}
    data['mydata'] = {}
    data['mydata']['value1']=10
    data['mydata']['value2']=20
    
    -- definisce una funzione di callback che gestirsce la risposta del server
    function post_done_callback(transfer, responses, errCode, errMsg)
      ... il tuo codice ...
    end
    
    -- aggiungi la richiesta al gestore
    api:add_request("post", "/simple_post", headers, nil, data, post_done_callback)

```

    `ApiRestManager::add_request(...)` è molto flessibile e ha diversi parametri che non sono stati esaminati in questo esempio. Maggiori dettagli su tutti i parametri e sulle funzioni di callback, si veda la descrizione dettagliata nella sezione dedicata di seguito.

5. Una volta messe in coda le richieste ogni volta che viene chiamata la funzione `ApiRestManager:send_next_requests()`, il gestore decide quali chiamate inviare e le invia svuotando progressivamente la coda. Esiste una versione alternativa `ApiRestManager:send_next_requests_later(interval)` che permette di processare la coda ma dopo aver atteso un ritardo di `interval` millisecondi

La funzione `ApiRestManager:set_max_concurrent_requests(value)` definisce il numero di richieste che vengono eseguite contemporanemante (importare a 1 per avere richieste eseguite una alla volta). Con la chiamata `ApiRestManager:enable_delayed_requests()` è possibile ritardare l'invio delle richieste impostando un timer: la durate del ritardo è definito tramite la chiamata `ApiRestManager:set_delayed_requests_interval(value)`. 

Se `ApiRestManager:is_enable_delayed_requests_mode_fixed()` è true, allora il ritardo impostato sarà esattamente quello impostato con la `ApiRestManager:set_delayed_requests_interval()`. Se `ApiRestManager:is_enable_delayed_requests_mode_random()` è true, allora il ritardo sarà un valore randomico tra 1 e quello impostato con la `ApiRestManager:set_delayed_requests_interval()`. Questo comportamento permette di avere chiamate parallele ma non contemporanee.

```
    -- imposta il gestore per mandare 5 richieste in parallelo
    api:set_max_concurrent_requests(5)

    -- imposta il gestore per ritardare le richieste di 2 secondi
    api:set_delayed_requests_interval(2000)

    -- abilita un ritardo randomico per evitare che 5 richieste parallele siano contemporanee
    api:enable_delayed_requests_mode_random()

    -- abilita l'invio ritardato
    api:enable_delayed_requests()

    -- processa la coda delle richieste e in particolare
    -- saranno inviate le 5 richieste in coda dopo un intervallo randomico
    -- tra 1 e 2 secondi dalla seguete chiamata
    api:send_next_requests()
```

6. Se le richieste da inviare sono tutte simili e ripetitive è possibile definire dei template di chiamate per semplificare il processo. Un template è una richiesta prepopolata identificata da un nome unico che può essere richiamata alla bisogna.
```
      -- Crea un template chiamato "template_get"
      -- per una chiamata GET all'endpoint '/get_example?param1=value1'
      -- il cui risultata sarà gestita dalla funzione done_callback()

      api:define_template("template_get", "get", "/get_example", done_callback)

      -- Crea un template chiamato "template_post"
      -- per una chiamata POST all'endpoint '/post_example'
      -- il cui risultata sarà gestita dalla funzione done_callback_post()
      
      api:define_template("template_post", "post", "/post_example", done_callback_post)


      -- Invia una richiesta usando il template1
      api:add_request_by_template("template_get", headers, params)
      api:add_request_by_template("template_post", headers, nil, data)

      -- Manda le richieste come al solito
      api:send_next_requests()
```
7. Solitamente le richieste sono accodate singolarmente: ogni chiamata ApiRestManager:add_request() crea una nuova richiesta che viene aggiunta a quelle esistenti. In caso si volesse avere delle richieste uniche ovvero che venga aggiornata se già presente in coda (e non aggiunta) è possibile usare le chiamate  `ApiRestManager:add_request_by_key()` e `ApiRestManager:add_request_by_template_by_key()` che identificano tramite uno chiave unica la richiesta e che, se la richiesta è già presente in coda, la aggiornano sostituendo quella esistente con quella nuova. Un esempio di utilizzo utile è nel caso si debba gestire uno slide che invia al driver variazioni man mano che l'utente muove il dito sull'interfaccia. Usando una richiesta _by_key_ è possibile avere una unica richiesta che invierà i dati ricevuti per ultimi e non accoederà tutte le richieste intermedie.
```
      -- Crea un template chiamato "update_lights"
      -- per una chiamata GET all'endpoint '/update_light_value'
      -- il cui risultata sarà gestita dalla funzione update_lights_callback()

      api:define_template("update_lights", "post", "/update_light_value", done_callback)

      -- Invia una richiesta specifica per la luce 1
      -- usando il template update_lights per impostare
      -- il valore 50
      api:add_request_by_template_by_key("update_light_1","update_lights", headers, params, {"light_id":1, "value": 50 })

      -- Aggiorna la richiesta specifica per la luce 1
      -- usando il template update_lights per impostare
      -- il nuovo valore 70
      api:add_request_by_template_by_key("update_light_1","update_lights", headers, params, {"light_id":1, "value": 70 })


      -- Manda la richiesta accodata e aggiornata
      api:send_next_requests()
```

## Esempio di callback di gestione delle risposte

Riportiamo un esempio di gestore delle risposte (callback) seguendo il modello richiesto da C4:url():OnDone() di Control4.

```
function respose_handler(transfer, responses, errCode, errMsg)
  
  if (errCode == 0) then
    --
    -- Nessun errore ricevuto. Elabora le riposte...
    --
  
    LOGGER:debug("respose_handler(): transfer succeeded (", #responses, " responses received), last response code: " .. lresp.code)
    
    -- le risposte possono essere numerore (es. in caso di redirect etc...)
    -- mi interessa l'ultima
    local lresp = responses[#responses]
    
    -- se devo accere agli header della risposta...
    for hdr,val in pairs(lresp.headers) do
      LOGGER:debug("respose_handler(): ", hdr, " = ",val)
    end

    -- se mi interessa il corpo della risposta uso lresp.body
    LOGGER:debug("check_service_status_respose_handler(): body of last response:", lresp.body)

    ...
    ... PUT HERE YOUR CODE ...
    ...

   else

    --
    -- Se ci sono errori...
    --

    if (errCode == -1) then
      --
      -- caso di trasferimento abortito
      --
      LOGGER:debug("respose_handler(): transfer was aborted")

      ...
      ... PUT HERE YOUR CODE ...
      ...
  
      
    else
      LOGGER:debug("respose_handler(): transfer failed with error", errCode,":",errMsg, "(", #responses,"responses completed)")
      --
      -- caso di errore ricevuto dal server (es. codice 500, 404, ...)
      --

      ...
      ... PUT HERE YOUR CODE ...
      ...
  
    end
   end
     
end
```

## Descrizione delle funzioni a disposizione

Si faccia riferimento alla voce _C4:url()_ nella guida _OS3 API Reference Guide_ per dettagli aggiuntivi sui parametri delle varie funzioni quando indicato.


### Funzioni per creare gestire richieste REST 

#### `ApiRestManager:add_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)`
Funzione per aggiungere una richiesta REST nella code del gestore.

Parametri:

  * `verb`: stringa che rappresenta il verbo REST. I valori ammessi sono `get`, `post`, `put`, `delete`. _Al momento non sono gestiti i verbi personalizzati_.
  * `endpoint`: stringa che rappresenta l'endpoit verso cui inviare le richieste. Questa stringa verrà concatenta con la `base_url` (si veda dopo `ApiRestManager:set_base_url()`) per creare la url finale. Ad esempio se `base_url` fosse http://esempio.com e il parametro passato fosse `/mio_endpoint`, l'url effettivo della richiesta sarebbe `http://esempio/mio_endpoint`. **Ricordarsi di far iniziare l'`endpoint` con il carattere "/" perché non viene aggiunto se mancante.**
  * `headers`: tabella Lua che contiene in una forma chiave-valore, gli header da usare durante la richiesta secondo la convenzione definita dalla C4:url() di Control4. Se non si vogliono impostare gli headres è possibile passare come parametro una tabella vuota o `nil`. **Se si vuole usare la BASIC AUTHENTICATION non è necessario aggiungere gli header relativi che sono gestiti automaticamente con la funzione `ApiRestManager:enable_basic_authentication()`**
  * `params`: tabella Lua che contiene, in forma chiave-valore, i parametri e i relativi valori che saranno usati per costruire la url definitiva. Ad esempio il valore di `params` fosse: 
```
      { param1 = 123,
        param2 = "prova" }
```
    allora la url effettiva sarebbe `http://base_url/endpoint?param1=123&param2=prova`. Se non si vogliono usare i parametri è possibile passare una tabella vuota o `nil`
  * `data`: tabella Lua o stringa che contiene il contenuto del body di una richiesta. Se il parametro è una stringa, il valore viene lasciato invariato, se si tratta di una tabella, allora viene convertita in un JSON. Se non si vuole usare questo parametro (ad esempio nelle richieste di tipo `GET` o `DELETE`) è possibile passare `nil`
  * `done_callback`: questa è il riferimento ad una funzione che segue le caratteristiche definite dalla C4:url():OnDone() di Control4. In particolare la _signature_ della funzione è: `done_callback(transfer, responses, errCode, errMsg)` dove `responses` è una tabella delle risposte nell'ordine di ricezione, `errCode` il codice di errore della chiamata (0 se non ci sono errori, -1 altrimenti), `errMsg` una stringa che può descrivere un errore ricevuto (`nil` se non ci sono errori).
  * `response_processor`: questa è una funzione che viene utilizzate per processare i dati ricevuti da una risposta prima di passarli alla `done_callback`. Questa funzione viene passata alla C4:url():OnBody() di Control4. Se il parametro è `nil`, allora viene usata la funzione di default (`ApiRestManager.json_response_processor()`) che considera i dati ricevuti come dei JSON e li trasforma in una tabella Lua (come descritto parlando del parametro `data` piiù sopra). La _signature_ della funzione è `response_processor(transfer, response)`. Se la funzione ritorna `true` la chiamata viene abortita. Il parametro `response` è lo stesso che verrà poi passato poi alla `done_callback` ed è il parametro da modificare.
  * `endpoint_processor`: questa funzione modifica la stringa `endpoint` prima di concatenarla alla `base_url`. Se il parametro è `nil` viene usata la funzione di default (`ApiRestManager.querystring_params_processor()`) che concatena all'`endpoint` i vari parametri a costituire una _query string_ come descritto prima per quanto riguarda il parametro `endpoint`). La _signature_ della funzione è `endpoint_processor(endpoint, params, headers)` che ritorna una stringa con il nuovo `endpoint`, e riceve i parametri `endpoint` ovvero la stringa di partenza, `params` che è la tabella di parametri e `headers` che è la tabella degli headers come descritto nei relativi parametri.
  * `headers_processor`: funzione che modifica il parametro `header` della richietsa. Se `nil` viene utilizzata la funzione di default (`ApiRestManager.dummy_headers_processor()`) che non modifca i valori ricevuti. La _signature_ della funzione è `headers_processor(header)` che riceve la tabella degli header e restituisce una nuova tabella modificata. 
  * `params_processor`: funzione che modifica il parametro `params` della richiesta. Se `nil` viene utilizzata la funzione di default (`ApiRestManager:dummy_params_processor()`) che non modifica i valori ricevuti. La _signature_ della funzione è `params_processor(params)` che riceve la tabella dei parametri e restituisce una nuova tabella modificata.
  * `data_processor`: funzione che modifica i parametro `data` della richiesta. Se `nil` viene utilizzata la funzione di default (`ApiRestManager:json_data_processor`) che trasforma il parametro `data` in una stringa JSON se è una tabella, altrimenti lascia il valore inalterato. La _signature_ della funzione è `data_processor(data)` dove `data` è quello della richiesta come descritto precedentemente, e restituisce un nuovo valore per lo stesso




#### `ApiRestManager:add_request_by_key(key, verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)`

Funzione per aggiungere una richiesta REST nella code del gestore identificandola in modo univoco tramite una chiave passata nel parametro `key`. Gli altri parametri sono gli stessi di `ApiRestManager:add_request()`.

Se esiste già una richieste in coda con lo stesso valore di `key` la richiesta in coda viene aggiornata con i valori passati.

Questa funzione consente di avere una richiesta che mantenga il valore più recente. Si faccia riferimento al punto 7 del paragrafo _"Come usare `ApiRestManager` in un driver"_.


#### `ApiRestManager:send_next_requests()`

Questa chiamata dice al gestore delle chiamata REST di processare le richieste in coda. Il compotamento di questa funzione è influenzato da `ApiRestManager:set_max_concurrent_requests()` e `ApiRestManager:enable_delayed_requests()` come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

#### `ApiRestManager:send_next_requests_later(interval)`

Questa chiamata è equivalente a `ApiRestManager:send_next_requests()` ma introduce una pause tra quando viene invocata e quando vengono effettivamente processate le richieste. L'intervallo è indicato dal valore di `interval` ed è misurato in millisecondi. Se non viene indicato alcun valore, il ritardo di default è di 5 secondi.

### Utilizzo dei template di chiamate

Se le richieste da inviare sono tutte simili e ripetitive è possibile definire dei template di chiamate per semplificare il processo come descritto al punto 6 del paragrafo _"Come usare `ApiRestManager` in un driver"_. 

#### `ApiRestManager:define_template(name, verb, endpoint, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)`

Funzione che definisce un template, ovvire una richiesta precompilata con i parametri di base. Il parametro `name` è un identificativo unico del template, gli altri parametri sono invece i corrispondeti descritti per la `ApiRestManager:add_request()`. Se esiste già un template con lo stesso `name` esso viene aggiornato/sostituito con i dati nuovi.

#### `ApiRestManager:remove_template(name)`

Funzione per rimuovere un template definito precedentemento. `name` è l'identificatore unico del template che si vuole rimuovere.

#### `ApiRestManager:get_template(name)`

Funzione che restituisce una tabella contenente i dati attualmenti usati all'interno di un template. `name` è l'identificatore unico del template che si vuole recuperare. La tabella restituita ha la seguente struttura:

```
  {
    verb = verb, 
    endpoint = endpoint, 
    done_callback = done_callback, 
    response_processor = response_processor, 
    endpoint_processor = endpoint_processor, 
    headers_processor = headers_processor, 
    params_processor = params_processor, 
    data_processor = data_processor
  }
```

#### `ApiRestManager:template_exists(name)`

Funzione che restituisce `true` se un template identificato da `name` è già presente.

#### `ApiRestManager:add_request_by_template(name, headers, params, data)`

Funzione che crea una richiesta utilizzando un template. Il parametro `name` è l'identificativo del template, mentre gli altri parametri sono gli stessi descritti in `ApiRestManager:add_request()`. 

#### `ApiRestManager:add_request_by_template_by_key(name, key, headers, params, data)`

Funzione che crea una richiesta con chiave, utilizzando un template. Il parametro `name` è l'identificativo del template, mentre gli altri parametri sono gli stessi descritti in `ApiRestManager:add_request_by_key()`. 


### Funzioni di configurazione del gestore

Descriviamo ora funzioni per configurare il comportamento generale del gestpre di richieste. Molte di queste sono wrapper di paramentri che sono usati dalla C4:url():SetOption() di Control4

#### `ApiRestManager:set_base_url(value)`

Funzione che imposta la url di base delle chiamate, ovvero l'indirizzo di partenza del server REST che viene interrogato. Ad essa vengono di volta in volta concatenati gli endpoint delle singole richieste come descritto precedentemente in `ApiRestManager:add_request()`

#### `ApiRestManager:get_base_url()`

Restituisce la url di base delle chiamata.


#### `ApiRestManager:is_fail_on_error_enabled()`

Restituisce il valore dell'opzione `fail_on_error` di C4:url():SetOption() di Control4.


#### `ApiRestManager:enable_fail_on_error()`

Imporsto l'opzione `fail_on_error` a `true` di C4:url():SetOption() di Control4.

#### `ApiRestManager:disable_fail_on_error()`

Imporsto l'opzione `fail_on_error` a `false` di C4:url():SetOption() di Control4.

#### `ApiRestManager:get_timeout()`

Restituisce il valore dell'opzione `timeout` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_timeout(value)`

Imposta il valore dell'opzione `timeout` di C4:url():SetOption() di Control4.

#### `ApiRestManager:get_connect_timeout()`

Restituisce il valore dell'opzione `connect_timeout` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_connect_timeout(value)`

Imposta il valore dell'opzione `connect_timeout` di C4:url():SetOption() di Control4.


#### `ApiRestManager:is_ssl_verify_host_enabled()`

Restituisce il valore dell'opzione `ssl_verify_host` di C4:url():SetOption() di Control4.

#### `ApiRestManager:enable_ssl_verify_host()`

Imposta a `true` il valore dell'opzione `ssl_verify_host` di C4:url():SetOption() di Control4.

#### `ApiRestManager:disable_ssl_verify_host()`

Imposta a `false` il valore dell'opzione `ssl_verify_host` di C4:url():SetOption() di Control4.

#### `ApiRestManager:is_ssl_verify_peer_enabled()`

Restituisce il valore dell'opzione `ssl_verify_peer` di C4:url():SetOption() di Control4.

#### `ApiRestManager:enable_ssl_verify_peer()`

Imposta a `true` il valore dell'opzione `ssl_verify_peer` di C4:url():SetOption() di Control4.

#### `ApiRestManager:disable_ssl_verify_peer()`

Imposta a `false` il valore dell'opzione `ssl_verify_peer` di C4:url():SetOption() di Control4.


#### `ApiRestManager:get_ssl_cabundle()`

Restituisce il valore dell'opzione `ssl_cabundle` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_ssl_cabundle(value)`

Imposta il valore dell'opzione `ssl_cabundle` di C4:url():SetOption() di Control4.

#### `ApiRestManager:get_ssl_cert()`

Restituisce il valore dell'opzione `get_ssl_cert` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_ssl_cert(value)`

Imposta il valore dell'opzione `get_ssl_cert` di C4:url():SetOption() di Control4.

#### `ApiRestManager:get_ssl_cert_type()`

Restituisce il valore dell'opzione `ssl_cert_type` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_ssl_cert_type(value)`

Imposta il valore dell'opzione `ssl_cert_type` di C4:url():SetOption() di Control4.

#### `ApiRestManager:get_ssl_key()`

Restituisce il valore dell'opzione `ssl_key` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_ssl_key(value)`

Imposta il valore dell'opzione `ssl_key` di C4:url():SetOption() di Control4.

#### `ApiRestManager:get_ssl_passwd()`

Restituisce il valore dell'opzione `ssl_passwd` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_ssl_passwd(value)`

Imposta il valore dell'opzione `ssl_passwd` di C4:url():SetOption() di Control4.

#### `ApiRestManager:get_ssl_cacerts()`

Restituisce il valore dell'opzione `ssl_cacerts` di C4:url():SetOption() di Control4.

#### `ApiRestManager:set_ssl_cacerts(value)`

Imposta il valore dell'opzione `ssl_cacerts` di C4:url():SetOption() di Control4.


#### `ApiRestManager:enable_basic_authentication()`

Abilita la BASIC AUTHENTICATION per le richieste. Vanno impostati username e password con le funzioni `ApiRestManager:set_username(value)` e `ApiRestManager:set_password(value)`

#### `ApiRestManager:disable_authentication()`

Disabilita la BASIC AUTHENTICATION per le richieste.

#### `ApiRestManager:has_authentication()`

Restituisce `true` se è attivo un protocollo di autenticazione. Al momento supporta solo la BASIC AUTHENTICATION.

#### `ApiRestManager:has_basic_authentication()`

Restituisce `true` se è attiva la BASIC AUTHENTICATION per le richieste.

#### `ApiRestManager:set_username(value)`

Imposta l'username da usare durante la BASIC AUTHENTICATION se abilitata tramite `ApiRestManager:enable_basic_authentication()`

#### `ApiRestManager:get_username()`

Restituisce l'username impostato per le richieste quando la BASIC AUTHENTICATION è attiva (vedi `ApiRestManager:enable_basic_authentication()`)

#### `ApiRestManager:set_password(value)`

Imposta la password da usare durante la BASIC AUTHENTICATION se abilitata tramite `ApiRestManager:enable_basic_authentication()`

#### `ApiRestManager:get_password()`

Restituisce la password impostata per le richieste quando la BASIC AUTHENTICATION è attiva (vedi `ApiRestManager:enable_basic_authentication()`)

#### `ApiRestManager:set_max_concurrent_requests(value)`

Imposta il numero di richieste che possono essere inviate contemporaneamtente alla chiamata di `ApiRestManager:send_next_requests()` come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

#### `ApiRestManager:get_max_concurrent_requests()`

Restituisce il numero di richieste che possono essere inviate contemporaneamtente alla chiamata di `ApiRestManager:send_next_requests()` come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

#### `ApiRestManager:set_delayed_requests_interval(value)`

Imposta il numero di millisecondi di ritardo dalla chiamata di `ApiRestManager:send_next_requests()` a quando effettivamente saranno inviate le richieste, come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

#### `ApiRestManager:get_delayed_requests_interval()`

Restituisce il numero di millisecondi di ritardo dalla chiamata di `ApiRestManager:send_next_requests()` a quando effettivamente saranno inviate le richieste, come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_. Se `ApiRestManager:is_enable_delayed_requests_mode_fixed()` è true, allora il valore restituito sarà esattamente quello impostato con la `ApiRestManager:set_delayed_requests_interval()`. Se `ApiRestManager:is_enable_delayed_requests_mode_random()` è true, allora il valore restituito sarà un valore randomico tra 1 e quello impostato con la `ApiRestManager:set_delayed_requests_interval()`.

#### `ApiRestManager:are_delayed_requests_enabled()`

Restituisce `true` se il meccanismo delle richieste ritardate è attivo, come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

#### `ApiRestManager:enable_delayed_requests()`

Abilita il meccanismo delle richieste ritardate è attivo, come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

#### `ApiRestManager:disable_delayed_requests()`

Disabilita il meccanismo delle richieste ritardate è attivo, come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

### `ApiRestManager:enable_delayed_requests_mode_fixed()`

Abilita la modalità 'fixed' per cui il valore restituito da `ApiRestManager:get_delayed_requests_interval()` sarà esattamente quello impostato con la `ApiRestManager:set_delayed_requests_interval()`, come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

### `ApiRestManager:enable_delayed_requests_mode_random()`

Abilita la modalità 'random' per cui il valore restituito da `ApiRestManager:get_delayed_requests_interval()` sarà un valore randomico tra 1 e quello impostato con la `ApiRestManager:set_delayed_requests_interval()`, come descritto al punto 5 del paragrafo _"Come usare `ApiRestManager` in un driver"_.

### `ApiRestManager:is_enable_delayed_requests_mode_fixed()`
Ritorna true se la modalità impostata è `fixed`.

### `ApiRestManager:is_enable_delayed_requests_mode_random()`
Ritorna true se la modalità impostata è `random`.

### Altre funzioni interne e private,

Aggiungiamo una breve descrizione di alcune funzioni interne che non vanno usate normalmente ma che sono utili a chi volesse ampliare il modulo `ApiRestManager`.

Queste sono le funzioni di default usate da `ApiRestManager:add_request` come descritto nella documentazione della stessa: 
* `ApiRestManager:querystring_params_processor(params, headers)`
* `ApiRestManager:json_data_processor(data)`
* `ApiRestManager:dummy_headers_processor(headers)`
* `ApiRestManager:dummy_params_processor(params)`
* `ApiRestManager:json_response_processor(status_code, headers, body)`


La funzione `ApiRestManager:build_new_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)` è una funzione interna per evitare duplicazione di codie e costruisce la struttura dati che descrive una richiesta che viene poi accodata.

Le seguenti funzioni sono funzioni che non fanno riferimento a `self` (si chiamano con il . e non i :)
* `ApiRestManager.encode_value(str)`: fa l'encoding di una stringa e viene usata per creare le _query string_
* `ApiRestManager.send_delayed_request_timer_callback(timer_obj)`: è l'handler del time che gestisce l'invio ritardato delle richieste
* `ApiRestManager.call_api_rest_request(request)`: funzione che effettua la chiamata effettiva verso la C4:url() in base al verbo REST.
* `ApiRestManager.generate_encoded_credential(username, password)`: parte da username e password e crea il token nel formato necessario per la BASIC AUTHENTICATION
