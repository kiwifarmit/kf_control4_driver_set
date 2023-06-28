# Manuale alla libreria SKC4

In questo documento troverete una panoramica della libreria. Per la documentazione specifica di ogni modulo, si faccia rifermento al file relativo nella cartella `docs/`.

## Scopo e contenuto della libreria

Questa libreria contiene moduli Lua di utilità per lo sviluppatore di driver Control4.

I moduli principali sono:

* `C4.lua`: modulo che simula le chiamate alla libreria dell'SDK C4 in modo da poter testare partzialmente il diriver al di fuori dell'ambiente Control4 e Composer;
* [`DriverCore.lua`](drivercore.md): modulo che contiene funzioni per rispondere agli eventi di Control4;
* `Connections.lua`: modulo che contiene funzioni per gestire connessioni su vari protocolli;
* `Debug.lua`: modulo *deprecato* per stampare informazioni di debug. Le funzionalità di questo modulo sono state convogliate in Logger.lua
* [`LicenseManager.lua`](licensemanager.md): modulo per gestire vari provider di licenza;
* [`ApiRestManager.lua`](apirestmanager.md): modulo per gestire la comunicazione verso un server HTTP REST;
* `Logger.lua`: modulo per gestire il log delle infomrazioni su standar output o su file;
* `TimerManager.lua`: modulo per gestire timer;
* [`Queue.lua`](quque.md): modulo per gestire code generiche;
* [`Utility.lua`](utility.md): contiente funzioni di varia utilità;
* [`DynamicVariableManager.lua`](dynamicvariablemanager.md): contiente funzioni di gestione di variabili dinamiche;
* [`DynamicConnectionManager.lua`](dynamicconnectionmanager.md): contiente funzioni di gestione dinamica delle connessioni;    
* `SKC4lib.lua`: modulo radice della libreria. Includendo questo modulo vengono inclusi automaticamente tutti i moduli precedenti.

Codice a supporto della libreria è contenuto nelle cartelle:
* `docs\` contiene la documentazione della libreria;
* `lib\` contiene librerie varie di terze parti;
* `license\` contiene codice di terze parti per la gestione delle licenze (es. libreira di DriverCentral.io)

## Come includere la libreria in un driver Control4

1. Copiare la cartella SKC4 nella radice del progetto software (dove è messo il file _driver.lua_)

2. Aggiungere i file della libreria SKC4 al file di _squishy_ nella sezioni dei _Module_:
    ```
    Module "SKC4.licence.cloud_client_v1007" "SKC4/licence/cloud_client_v1007.lua"
    Module "SKC4.Utility" "SKC4/Utility.lua"
    Module "SKC4.Logger" "SKC4/Logger.lua"
    Module "SKC4.DriverCore" "SKC4/DriverCore.lua"
    Module "SKC4.TimerManager" "SKC4/TimerManager.lua"
    Module "SKC4.Queue" "SKC4/Queue.lua"
    Module "SKC4.ApiRestManager" "SKC4/ApiRestManager.lua"
    Module "SKC4.LicenseManager" "SKC4/LicenseManager.lua"
    Module "SKC4.DynamicVariableManager" "SKC4/DynamicVariableManager.lua"
    Module "SKC4.DynamicConnectionManager" "SKC4/DynamicConnectionManager.lua"
    Module "SKC4.SKC4lib" "SKC4/SKC4lib.lua"
    ```
3. Se nel file *.c4zproj il tag radice <Driver> ha l'attributo manualsquish a "true" questo passaggio non dovrebbe essere necessario. Altrimenti è necessario aggiungere nella sezione <Squishy> del file il seguente codice:
    ```
    <File>SKC4\Debug.lua</File>
    <File>SKC4\LicenseManager.lua</File>
    <File>SKC4\Logger.lua</File>
    <File>SKC4\TimerManager.lua</File>
    <File>SKC4\Utility.lua</File>
    <File>SKC4\Queue.lua</File>
    <File>SKC4\DynamicVariableManager.lua</File>
    <File>SKC4\DynamicConnectionManager.lua</File>
    <File>SKC4\ApiRestManager.lua</File>
    <File>SKC4\DriverCore.lua</File>
    <File>SKC4\SKC4lib.lua</File>
    <File>SKC4\licence\cloud_client_v1007.lua</File>
    ```
    
Per usare i vari moduli, basta fare `require("SKC4.nomedelmodulo")`. Per la descrizione dei vari moduli si rimanda alla documentazione specifica.
*Non è necessario includere la directory SKC4 nel file _.c4proj_ perché l'operazione di _squish_ include i file automaticamente*



