[Torna all'indice](index.md)

# ApiRestManager.lua

This module centralizes the management of REST calls to cloud services. The module is capable of handling single or multiple calls and has a queue for immediate or delayed execution. It allows creating generic calls or model-based calls representing endpoints.

The module is based on the C4:url() functionality of Control4. It is recommended to read the relevant part of the "API Reference Guide" manual for further details.

## How to use `ApiRestManager` in a driver

Refer to the _C4:url()_ entry in the _OS3 API Reference Guide_ for additional details on the parameters of the various functions when indicated.

1. To use _ApiRestManager_, include the Lua module at the beginning of the file where you want to use it:
   `require 'SKC4.ApiRestManager'`

2. Whenever you want to create a REST HTTP service handler, use `ApiRestManager:new()`. This allows having multiple concurrent REST handlers:
   `local api = ApiRestManager:new()`

3. Configure the handler by specifying the server URL and, if necessary, the username and password for authentication (**currently only DIGEST and BASIC AUTHENTICATION are supported**):

```
    api.set_base_url('http://192.168.1.100') -- sets the base URL to which the calls will be addressed

    api.enable_basic_authentication() -- enables BASIC Authentication
    -- api.enable_digest_authentication() -- enables DIGEST Authentication
    api.set_username('myusername') -- sets the username to use for authentication
    api.set_password('mypassword') -- sets the password to use for authentication
```

4. At this point, you can enqueue one or more REST requests using `ApiRestManager:add_request()`:

```
    -- Example GET request

    -- table containing parameters for the call
    -- we add two parameters that will be used to create
    -- the correct query string, i.e., "?id=100&call?mycall"
    params = {}
    params['id'] = 100
    params['call'] = 'mycall'

    -- defines a callback function to handle the server response
    function get_done_callback(transfer, responses, errCode, errMsg)
      ... your code ...
    end

    -- add the request to the handler
    api:add_request("get", "/simple_get", nil, params, nil, get_done_callback)


    -- Example POST request

    -- table containing the headers of the request
    -- we use headers to send parameters to POST
    headers = { ["Expect"] = "100-continue" }
    headers['myheader1'] = "value1"
    headers['myheader2'] = "value2"

    -- table containing data to be sent
    -- by default, tables are converted to JSON,
    -- other values are converted to strings
    data = {}
    data['mydata'] = {}
    data['mydata']['value1'] = 10
    data['mydata']['value2'] = 20

    -- defines a callback function to handle the server response
    function post_done_callback(transfer, responses, errCode, errMsg)
      ... your code ...
    end

    -- add the request to the handler
    api:add_request("post", "/simple_post", headers, nil, data, post_done_callback)

```

    `ApiRestManager::add_request(...)` is very flexible and has several parameters that have not been covered in this example. For more details on all the parameters and callback functions, please refer to the detailed description in the dedicated section below.

5. Once the requests are queued, every time the `ApiRestManager:send_next_requests()` function is called, the handler decides which calls to send and sends them, gradually emptying the queue. There is an alternative version `ApiRestManager:send_next_requests_later(interval)` that allows processing the queue but with a delay of `interval` milliseconds.

The function `ApiRestManager:set_max_concurrent_requests(value)` sets the number of requests executed concurrently (set to 1 to have requests executed one at a time). By calling `ApiRestManager:enable_delayed_requests()`, it is possible to delay the sending of requests by setting a timer: the duration of the delay is defined by calling `ApiRestManager:set_delayed_requests_interval(value)`.

If `ApiRestManager:is_enable_delayed_requests_mode_fixed()` is true, then the set delay will be exactly what was set with `ApiRestManager:set_delayed_requests_interval()`. If `ApiRestManager:is_enable_delayed_requests_mode_random()` is true, then the delay will be a random value between 1 and the value set with `ApiRestManager:set_delayed_requests_interval()`. This behavior allows for parallel but non-concurrent calls.

```
    -- Set the handler to send 5 requests in parallel
    api:set_max_concurrent_requests(5)

    -- Set the handler to delay requests by 2 seconds
    api:set_delayed_requests_interval(2000)

    -- Enable random delay to avoid 5 parallel requests being concurrent
    api:enable_delayed_requests_mode_random()

    -- Enable delayed sending
    api:enable_delayed_requests()

    -- Process the request queue, and in particular,
    -- the 5 queued requests will be sent after a random interval
    -- between 1 and 2 seconds from the following call
    api:send_next_requests()
```

6. If the requests to be sent are all similar and repetitive, it is possible to define request templates to simplify the process. A template is a prepopulated request identified by a unique name that can be called as needed.

```
      -- Create a template called "template_get"
      -- for a GET request to the endpoint '/get_example?param1=value1'
      -- with the result handled by the function done_callback()

      api:define_template("template_get", "get", "/get_example", done_callback)

      -- Create a template called "template_post"
      -- for a POST request to the endpoint '/post_example'
      -- with the result handled by the function done_callback_post()

      api:define_template("template_post", "post", "/post_example", done_callback_post)


      -- Send a request using template1
      api:add_request_by_template("template_get", headers, params)
      api:add_request_by_template("template_post", headers, nil, data)

      -- Send requests as usual
      api:send_next_requests()
```

7. Usually, requests are enqueued individually: each `ApiRestManager:add_request()` call creates a new request that is added to the existing ones. If you want unique requests that are updated if already in the queue (instead of being added), you can use the `ApiRestManager:add_request_by_key()` and `ApiRestManager:add_request_by_template_by_key()` calls, which identify the request with a unique key. If the request is already in the queue, it is updated by replacing the existing one with the new one. An example of useful usage is when you need to handle a slider that sends variations to the driver as the user moves their finger on the interface. By using a request _by_key_, you can have a single request that will send the latest

 received data and will not queue all the intermediate requests.

```
      -- Create a template called "update_lights"
      -- for a GET request to the endpoint '/update_light_value'
      -- with the result handled by the function update_lights_callback()

      api:define_template("update_lights", "post", "/update_light_value", done_callback)

      -- Send a specific request for light 1
      -- using the update_lights template to set
      -- the value to 50
      api:add_request_by_template_by_key("update_light_1", "update_lights", headers, params, {"light_id":1, "value": 50 })

      -- Update the specific request for light 1
      -- using the update_lights template to set
      -- the new value to 70
      api:add_request_by_template_by_key("update_light_1", "update_lights", headers, params, {"light_id":1, "value": 70 })


      -- Send the queued and updated request
      api:send_next_requests()
```

## Example of response handling callback

Here is an example of a response handler callback following the pattern required by C4:url():OnDone() in Control4.

```
function response_handler(transfer, responses, errCode, errMsg)
  
  if (errCode == 0) then
    --
    -- No error received. Process the responses...
    --
  
    LOGGER:debug("response_handler(): transfer succeeded (", #responses, " responses received), last response code: " .. lresp.code)
    
    -- Responses can be multiple (e.g., in case of redirects, etc.)
    -- I'm interested in the last one
    local lresp = responses[#responses]
    
    -- If I need to access the response headers...
    for hdr, val in pairs(lresp.headers) do
      LOGGER:debug("response_handler(): ", hdr, " = ",val)
    end

    -- If I'm interested in the response body, I use lresp.body
    LOGGER:debug("response_handler(): body of last response:", lresp.body)

    ...
    ... PUT HERE YOUR CODE ...
    ...

   else

    --
    -- If there are errors...
    --

    if (errCode == -1) then
      --
      -- Case of aborted transfer
      --
      LOGGER:debug("response_handler(): transfer was aborted")

      ...
      ... PUT HERE YOUR CODE ...
      ...
  
      
    else
      LOGGER:debug("response_handler(): transfer failed with error", errCode,":",errMsg, "(", #responses,"responses completed)")
      --
      -- Case of error received from the server (e.g., code 500, 404, ...)
      --

      ...
      ... PUT HERE YOUR CODE ...
      ...
  
    end
   end
     
end
```

## Description of available functions

Refer to the _C4:url()_ entry in the _OS3 API Reference Guide_ for additional details on the parameters of the various functions when indicated.

### Functions for creating and managing REST requests

#### `ApiRestManager:add_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)`

Function to add a REST request to the handler's queue.

Parameters:

  * `verb`: a string representing the REST verb. Allowed values are `get`, `post`, `put`, `delete`. _Custom verbs are not currently supported_.
  * `endpoint`: a string representing the endpoint to which the requests will be sent. This string will be concatenated with the `base_url` (see `ApiRestManager:set_base_url()`) to create the final URL. For example, if the `base_url` is http://example.com and the passed parameter is `/my_endpoint`, the actual URL of the request will be `http://example.com/my_endpoint`. **Remember to start the `endpoint` with the "/" character because it is not added if missing.**
  * `headers`: a Lua table containing the headers to be used during the request in a key-value format, following the convention defined by C4:url() in Control4. If you don't want to set headers, you can pass an empty table or `nil` as the parameter. **If you want to use BASIC/DIGEST AUTHENTICATION, there is no need to add the corresponding headers, as they are automatically handled by the functions `ApiRestManager:enable_basic_authentication()`/`ApiRestManager:enable_digest_authentication()`**
  * `params`: a Lua table containing the parameters and their respective values to be used in building the final URL, in a key-value format. For example, if the value of `params` is:
```
      { param1 = 123,
        param2 = "example" }
```
    then the actual URL would be `http://base_url/endpoint?param1=123&param2=example`. If you don't want to use parameters, you can pass an empty table or `nil`.
  * `data`: a Lua table or string containing the content of the request body. If the parameter is a string, the value remains unchanged. If it is a table, it will be converted to JSON. If you don't want to use this parameter (e.g., in `GET` or `DELETE` requests), you can pass `nil`.
  * `done_callback`: a reference to a function that follows the pattern defined by C4:url():OnDone() in Control4. In particular, the function's signature is: `done_callback(transfer, responses, errCode, errMsg)`, where `responses` is a table of responses in the order received, `errCode` is the error code of the call (0 if there are no errors, -1 otherwise), and `errMsg` is a string that may describe a received error (`nil` if there are no errors).
  * `response_processor`: a function used to process the data received from a response before passing it to the `done_callback`. This function is passed to C4:url():OnBody() in Control4. If the parameter is `nil`, then the default function is used (`ApiRestManager.json_response_processor()`), which considers the received data as JSON and converts it to a Lua table (as described in the `data` parameter above). The function's signature is `response_processor(transfer, response)`. If the function returns `true`, the call is aborted. The `response` parameter is the same parameter that will be passed to the `done_callback` and is the parameter to modify.
  * `endpoint_processor`: a function that modifies the `endpoint` string before concatenating it with the `base_url`. If

 the parameter is `nil`, the default function is used (`ApiRestManager.querystring_params_processor()`), which concatenates the various parameters with the `endpoint` to create a query string (as described earlier for the `endpoint` parameter). The function's signature is `endpoint_processor(endpoint, params, headers)`, and it returns a string with the new `endpoint`. It receives the parameters `endpoint` (the original string), `params` (the parameter table), and `headers` (the header table) as described in their respective parameters.
  * `headers_processor`: a function that modifies the `headers` parameter of the request. If `nil`, the default function is used (`ApiRestManager.dummy_headers_processor()`), which does not modify the received values. The function's signature is `headers_processor(headers)`, and it receives the headers table and returns a new modified table.
  * `params_processor`: a function that modifies the `params` parameter of the request. If `nil`, the default function is used (`ApiRestManager.dummy_params_processor()`), which does not modify the received values. The function's signature is `params_processor(params)`, and it receives the parameter table and returns a new modified table.
  * `data_processor`: a function that modifies the `data` parameter of the request. If `nil`, the default function is used (`ApiRestManager:json_data_processor()`), which converts the `data` parameter to a JSON string if it is a table, otherwise it leaves the value unchanged. The function's signature is `data_processor(data)`, where `data` is the data parameter of the request as described above, and it returns a new value for the same parameter.


#### `ApiRestManager:add_request_by_key(key, verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)`

Function to add a REST request to the handler's queue, uniquely identified by a key passed in the `key` parameter. The other parameters are the same as `ApiRestManager:add_request()`.

If there is already a request in the queue with the same `key` value, the queued request will be updated with the passed values.

This function allows having a request that keeps the most recent value. Refer to point 7 in the section "How to use `ApiRestManager` in a driver".


#### `ApiRestManager:send_next_requests()`

This call instructs the REST request handler to process the requests in the queue. The behavior of this function is influenced by `ApiRestManager:set_max_concurrent_requests()` and `ApiRestManager:enable_delayed_requests()` as described in point 5 in the section "How to use `ApiRestManager` in a driver".


#### `ApiRestManager:send_next_requests_later(interval)`

This call is equivalent to `ApiRestManager:send_next_requests()`, but introduces a delay between when it is invoked and when the requests are actually processed. The interval is indicated by the value of `interval` and is measured in milliseconds. If no value is specified, the default delay is 5 seconds.

### Using Request Templates

If the requests to be sent are all similar and repetitive, it is possible to define request templates to simplify the process as described in point 6 in the section "How to use `ApiRestManager` in a driver".

#### `ApiRestManager:define_template(name, verb, endpoint, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)`

Function that defines a template, which is a preconfigured request with basic parameters. The `name` parameter is a unique identifier for the template, and the other parameters are as described for `ApiRestManager:add_request()`. If a template with the same `name` already exists, it will be updated/replaced with the new data.

#### `ApiRestManager:remove_template(name)`

Function to remove a previously defined template. `name` is the unique identifier of the template to be removed.

#### `ApiRestManager:get_template(name)`

Function that returns a table containing the currently used data within a template. `name` is the unique identifier of the template to be retrieved. The returned table has the following structure:

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

Function that returns `true` if a template identified by `name` already exists.

#### `ApiRestManager:add_request_by_template(name, headers, params, data)`

Function that creates a request using a template. The `name` parameter is the identifier of the template, while the other parameters are the same as described in `ApiRestManager:add_request()`.

#### `ApiRestManager:add_request_by_template_by_key(name, key, headers, params, data)`

Function that creates a request with a key using a template. The `name` parameter is the identifier of the template, while the other parameters are the same as described in `ApiRestManager:add_request_by_key()`.

### Handler Configuration Functions

We will now describe functions to configure the general behavior of the request handler. Many of these functions are wrappers for parameters used by Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_base_url(value)`

Function that sets the base URL of the requests, which is the starting address of the REST server being queried. The endpoint of each individual request is concatenated to this base URL as described earlier in `ApiRestManager:add_request()`.

#### `ApiRestManager:get_base_url()`

Returns the base URL of the requests.

#### `ApiRestManager:is_fail_on_error_enabled()`

Returns the value of the `fail_on_error` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:enable_fail_on_error()`

Sets the `fail_on_error` option of Control4's `C4:url():SetOption()` to `true`.

#### `ApiRestManager:disable_fail_on_error()`

Sets the `fail_on_error` option of Control4's `C4:url():SetOption()` to `false`.

#### `ApiRestManager:get_timeout()`

Returns the value of the `timeout` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_timeout(value)`

Sets the value of the `timeout` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:get_connect_timeout()`

Returns the value of the `connect_timeout` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_connect_timeout(value)`

Sets the value of the `connect_timeout` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:is_ssl_verify_host_enabled()`

Returns the value of the `ssl_verify_host` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:enable_ssl_verify_host()`

Sets the value of the `ssl_verify_host` option of Control4's `C4:url():SetOption()` to `true`.

#### `ApiRestManager:disable_ssl_verify_host()`

Sets the value of the `ssl_verify_host` option of Control4's `C4:url():SetOption()` to `false`.

#### `ApiRestManager:is_ssl_verify_peer_enabled()`

Returns the value of the `ssl_verify_peer` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:enable_ssl_verify_peer()`

Sets the value of the `ssl_verify_peer` option of Control4's `C4:url():SetOption()` to `true`.

#### `ApiRestManager:disable_ssl_verify_peer()`

Sets the value of the `ssl_verify_peer` option of Control4's `C4:url():SetOption()` to `false`.


#### `ApiRestManager:get_ssl_cabundle()`

Returns the value of the `ssl_cabundle` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_ssl_cabundle(value)`

Sets the value of the `ssl_cabundle` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:get_ssl_cert()`

Returns the value of the `ssl_cert` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_ssl_cert(value)`

Sets the value of the `ssl_cert` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:get_ssl_cert_type()`

Returns the value of the `ssl_cert_type` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_ssl_cert_type(value)`

Sets the value of the `ssl_cert_type` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:get_ssl_key()`

Returns the value of the `ssl_key` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_ssl_key(value)`

Sets the value of the `ssl_key` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:get_ssl_passwd()`

Returns the value of the `ssl_passwd` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_ssl_passwd(value)`

Sets the value of the `ssl_passwd` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:get_ssl_cacerts()`

Returns the value of the `ssl_cacerts` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:set_ssl_cacerts(value)`

Sets the value of the `ssl_cacerts` option of Control4's `C4:url():SetOption()`.

#### `ApiRestManager:enable_basic_authentication()`

Enables BASIC AUTHENTICATION for the requests. Username and password should be set using the functions `ApiRestManager:set_username(value)` and `ApiRestManager:set_password(value)`.

#### `ApiRestManager:enable_digest_authentication()`

Enables DIGEST AUTHENTICATION for the requests. Username and password should be set using the functions `ApiRestManager:set_username(value)` and `ApiRestManager:set_password(value)`.

#### `ApiRestManager:disable_authentication()`

Disables AUTHENTICATION for the requests (both digest and basic).

#### `ApiRestManager:has_authentication()`

Returns `true` if an authentication protocol is active. Currently, only BASIC and DIGEST AUTHENTICATION are supported.

#### `ApiRestManager:has_basic_authentication()`

Returns `true` if BASIC AUTHENTICATION is active for the requests.

#### `ApiRestManager:has_digest_authentication()`

Returns `true` if DIGEST AUTHENTICATION is active for the requests.

#### `ApiRestManager:set_username(value)`

Sets the username to be used during AUTHENTICATION if enabled via `ApiRestManager:enable_basic_authentication()`.

#### `ApiRestManager:get_username()`

Returns the username set for the requests when AUTHENTICATION is active (see `ApiRestManager:enable_basic_authentication()`).

#### `ApiRestManager:set_password(value)`

Sets the password to be used during AUTHENTICATION if enabled via `ApiRestManager:enable_basic_authentication()`.

#### `ApiRestManager:get_password()`

Returns the password set for the requests when AUTHENTICATION is active (see `ApiRestManager:enable_basic_authentication()`).

#### `ApiRestManager:set_max_concurrent_requests(value)`

Sets the number of requests that can be sent concurrently when calling `ApiRestManager:send_next_requests()` as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

#### `ApiRestManager:get_max_concurrent_requests()`

Returns the number of requests that can be sent concurrently when calling `ApiRestManager:send_next_requests()` as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

#### `ApiRestManager:set_delayed_requests_interval(value)`

Sets the delay in milliseconds between calling `ApiRestManager:send_next_requests()` and actually sending the requests, as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

#### `ApiRestManager:get_delayed_requests_interval()`

Returns the delay in milliseconds between calling `ApiRestManager:send_next_requests()` and actually sending the requests, as described in point 5 of the section "How to Use `ApiRestManager` in a Driver". If `ApiRestManager:is_enable_delayed_requests_mode_fixed()` is true, then the returned value will be exactly the one set with `ApiRestManager:set_delayed_requests_interval()`. If `ApiRestManager:is_enable_delayed_requests_mode_random()` is true, then the returned value will be a random value between 1 and the one set with `ApiRestManager:set_delayed_requests_interval()`.

#### `ApiRestManager:are_delayed_requests_enabled()`

Returns `true` if the delayed requests mechanism is enabled, as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

#### `ApiRestManager:enable_delayed_requests()`

Enables the delayed requests mechanism, as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

#### `ApiRestManager:disable_delayed_requests()`

Disables the delayed requests mechanism, as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

### `ApiRestManager:enable_delayed_requests_mode_fixed()`

Enables the 'fixed' mode, where the value returned by `ApiRestManager:get_delayed_requests_interval()` will be exactly the one set with `ApiRestManager:set_delayed_requests_interval()`, as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

### `ApiRestManager:enable_delayed_requests_mode_random()`

Enables the 'random' mode, where the value returned by `ApiRestManager:get_delayed_requests_interval()` will be a random value between 1 and the one set with `ApiRestManager:set_delayed_requests_interval()`, as described in point 5 of the section "How to Use `ApiRestManager` in a Driver".

### `ApiRestManager:is_enable_delayed_requests_mode_fixed()`

Returns true if the currently set mode is 'fixed'.

### `ApiRestManager:is_enable_delayed_requests_mode_random()`

Returns true if the currently set mode is 'random'.
### Other Internal and Private Functions

Let's provide a brief description of some internal functions that are not normally used but can be useful for those who want to extend the `ApiRestManager` module.

These are the default functions used by `ApiRestManager:add_request` as described in its documentation:
* `ApiRestManager:querystring_params_processor(params, headers)`
* `ApiRestManager:json_data_processor(data)`
* `ApiRestManager:dummy_headers_processor(headers)`
* `ApiRestManager:dummy_params_processor(params)`
* `ApiRestManager:json_response_processor(status_code, headers, body)`

The function `ApiRestManager:build_new_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)` is an internal function to avoid code duplication and constructs the data structure that describes a request, which is then added to the queue.

The following functions are not bound to `self` (they are called with `.` instead of `:`):
* `ApiRestManager.encode_value(str)`: Encodes a string and is used to create the query string.
* `ApiRestManager.send_delayed_request_timer_callback(timer_obj)`: The handler for the timer that manages delayed request sending.
* `ApiRestManager.call_api_rest_request(request)`: Performs the actual request to `C4:url()` based on the REST verb.
* `ApiRestManager.generate_encoded_credential(username, password)`: Takes a username and password and creates the token in the required format for BASIC AUTHENTICATION.