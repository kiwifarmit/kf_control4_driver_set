local Queue = require "SKC4.Queue"
local TimerManager = require "SKC4.TimerManager"
local ApiRestManager = {}

function ApiRestManager:new(o)
  o = o or {}
  setmetatable(o, self)
  self.__index = self
  
  o._queue = Queue:new()
  -- self._timer_pool = {}
  o._templates = {}
  o._username = ""
  o._password = ""
  o._base_url = ""
  o._authentication = "none"

  o._max_concurrent_requests = 1
  o._delayed_requests_interval = 1000
  o._delayed_requests_enabled = false
  o._delayed_requests_mode = "fixed" -- or random

  o._fail_on_error = true
  o._timeout = 30
  o._connect_timeout = 5
  o._ssl_verify_host = true
  o._ssl_verify_peer = true
  o._ssl_cabundle = nil
  o._ssl_cert = nil
  o._ssl_cert_type = "PEM"
  o._ssl_key = nil
  o._ssl_passwd = nil
  o._ssl_cacerts = nil


  return o
end

function ApiRestManager:set_max_concurrent_requests(value)
  if (value < 1) then
    value = 1
  end
  self._max_concurrent_requests = value
end
function ApiRestManager:get_max_concurrent_requests()
  return self._max_concurrent_requests
end

function ApiRestManager:set_username(value)
  self._username = value
end
function ApiRestManager:set_password(value)
  self._password = value
end
function ApiRestManager:get_username()
  return self._username
end
function ApiRestManager:get_password()
  return self._password
end
function ApiRestManager:set_base_url(value)
  self._base_url = value:gsub("%s+", "")
end
function ApiRestManager:get_base_url()
  return self._base_url
end

function ApiRestManager:is_fail_on_error_enabled()
  return self._fail_on_error
end
function ApiRestManager:enable_fail_on_error()
  self._fail_on_error = true
end
function ApiRestManager:disable_fail_on_error()
  self._fail_on_error = false
end
function ApiRestManager:get_timeout()
  return self._timeout
end
function ApiRestManager:set_timeout(value)
  self._timeout = value
end
function ApiRestManager:get_connect_timeout()
  return self._connect_timeout
end
function ApiRestManager:set_connect_timeout(value)
  self._connect_timeout = value
end
function ApiRestManager:is_ssl_verify_host_enabled()
  return self._ssl_verify_host
end
function ApiRestManager:enable_ssl_verify_host()
  self._ssl_verify_host = true
end
function ApiRestManager:disable_ssl_verify_host()
  self._ssl_verify_host = false
end
function ApiRestManager:is_ssl_verify_peer_enabled()
  return self._ssl_verify_peer
end
function ApiRestManager:enable_ssl_verify_peer()
  self._ssl_verify_peer = true
end
function ApiRestManager:disable_ssl_verify_peer()
  self._ssl_verify_peer = false
end
function ApiRestManager:get_ssl_cabundle()
  return self._ssl_cabundle
end
function ApiRestManager:set_ssl_cabundle(value)
  self._ssl_cabundle = value
end
function ApiRestManager:get_ssl_cert()
  return self._ssl_cert
end
function ApiRestManager:set_ssl_cert(value)
  self._ssl_cert = value
end
function ApiRestManager:get_ssl_cert_type()
  return self._ssl_cert_type
end
function ApiRestManager:set_ssl_cert_type(value)
  self._ssl_cert_type = value
end
function ApiRestManager:get_ssl_key()
  return self._ssl_key
end
function ApiRestManager:set_ssl_key(value)
  self._ssl_key = value
end
function ApiRestManager:get_ssl_passwd()
  return self._ssl_passwd
end
function ApiRestManager:set_ssl_passwd(value)
  self._ssl_passwd = value
end
function ApiRestManager:get_ssl_cacerts()
  return self._ssl_cacerts
end
function ApiRestManager:set_ssl_cacerts(value)
  self._ssl_cacerts = value
end

function ApiRestManager:enable_digest_authentication()
  self._authentication = "digest"
end
function ApiRestManager:enable_basic_authentication()
  self._authentication = "basic"
end
function ApiRestManager:disable_authentication()
  self._authentication = "none"
end
function ApiRestManager:has_authentication()
  return (self._authentication ~= "none")
end
function ApiRestManager:has_basic_authentication()
  return (self._authentication == "basic")
end
function ApiRestManager:has_digest_authentication()
  return (self._authentication == "digest")
end

function ApiRestManager:set_delayed_requests_interval(value)
  if (value < 100) then
    value = 100
  end
  self._delayed_requests_interval = value
end
function ApiRestManager:get_delayed_requests_interval()

  if (self:is_enable_delayed_requests_mode_fixed()) then
    return self._delayed_requests_interval
  else
    math.randomseed(os.time())
    local random_interval = math.random(self._delayed_requests_interval)
  end
end

function ApiRestManager:are_delayed_requests_enabled()
  return self._delayed_requests_enabled
end
function ApiRestManager:enable_delayed_requests()
  self._delayed_requests_enabled = true
end
function ApiRestManager:disable_delayed_requests()
  self._delayed_requests_enabled = false
end


function ApiRestManager:enable_delayed_requests_mode_fixed()
  self._delayed_requests_mode = "fixed"
end
function ApiRestManager:enable_delayed_requests_mode_random()
  self._delayed_requests_mode = "random"
end

function ApiRestManager:is_enable_delayed_requests_mode_fixed()
  return self._delayed_requests_mode == "fixed"
end
function ApiRestManager:is_enable_delayed_requests_mode_random()
  return self._delayed_requests_mode == "random"
end



function ApiRestManager:add_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)
  local new_request = self:build_new_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)
  self._queue:push(new_request)
end
function ApiRestManager:add_request_by_key(key, verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)
  local new_request = self:build_new_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)
  self._queue:push_by_key(key, new_request)
end
function ApiRestManager:build_new_request(verb, endpoint, headers, params, data, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)
  local  new_request = {}
  
  
  if (endpoint_processor == nil) then
    endpoint_processor = self.querystring_params_processor
  end
  if (headers_processor == nil) then
    headers_processor = self.dummy_headers_processor
  end
  if (params_processor == nil) then
    params_processor = self.dummy_params_processor
  end
  if (data_processor == nil) then
    data_processor = self.json_data_processor
  end
  if (response_processor == nil) then
    response_processor = self.json_response_processor
  end
  
  if (self:has_basic_authentication()) then
    headers = headers or {}
    headers["Authorization"] = "Basic "..self:generate_encoded_credential(self:get_username(), self:get_password())
  end

  new_request["verb"] = string.lower(verb)

  _ , new_request["headers"]  = pcall(headers_processor, self, headers)
  _ , new_request["params"]   = pcall(params_processor, self, params)
  _ , new_request["data"]     = pcall(data_processor, self, data)
  _ , new_request["endpoint"] = pcall(endpoint_processor, self, endpoint, new_request["params"], new_request["headers"])
  
  local raw_url = self:get_base_url()
  
  local found_protocol = ""
  if (string.find(raw_url, 'http://')) then
    found_protocol = "http://"
  elseif (string.find(raw_url, 'https://')) then
    found_protocol = "https://"
  end
  
  if (self:has_digest_authentication()) then
    -- TODO gestire la presenza di http all'inizio
    local server_address = string.gsub(raw_url,found_protocol,"")
    new_request["url"] = found_protocol..self:get_username()..":"..self:get_password().."@"..server_address
  else
    new_request["url"] = self:get_base_url()
  end

  new_request["url"] = new_request["url"] .. new_request["endpoint"]
  
  local options = {}
  if (self._fail_on_error) then options["fail_on_error"] = self._fail_on_error end
  if (self._timeout) then options["timeout"] = self._timeout end
  if (self._connect_timeout) then options["connect_timeout"] = self._connect_timeout end
  if (self._connect_timeout) then options["connect_timeout"] = self._connect_timeout end
  if (self._ssl_verify_host) then options["ssl_verify_host"] = self._ssl_verify_host end
  if (self._ssl_verify_peer) then options["ssl_verify_peer"] = self._ssl_verify_peer end
  if (self._ssl_cabundle) then options["ssl_cabundle"] = self._ssl_cabundle end
  if (self._ssl_cert) then options["ssl_cert"] = self._ssl_cert end
  if (self._ssl_cert_type) then options["ssl_cert_type"] = self._ssl_cert_type end
  if (self._ssl_key) then options["ssl_key"] = self._ssl_key end
  if (self._ssl_passwd) then options["ssl_passwd"] = self._ssl_passwd end
  if (self._ssl_cacerts) then options["ssl_cacerts"] = self._ssl_cacerts end
   
  new_request["handler"] = C4:url():OnBody(response_processor):SetOptions(options):OnDone(done_callback)

  if (SKC4_LOGGER) then
    SKC4_LOGGER:debug("ApiRestManager:build_new_request new_request is:\n", new_request)
  end
  
  return new_request
end

function ApiRestManager:send_next_requests_later(milliseconds)
  -- default: 5 seconds delay
  if (milliseconds) then
    milliseconds = 5000
  end

  local t = TimerManager:new(interval, "MILLISECONDS", function()
    self:send_next_requests()
  end)
end

function ApiRestManager:send_next_requests()

  for i = 1, self._max_concurrent_requests do
    if not self._queue:is_empty() then
      -- se la coda non è vuota
      local request = self._queue:pop()
      if (SKC4_LOGGER) then
        SKC4_LOGGER:debug("Request to serve:", request)
      end
      if (self._delayed_requests_enabled) then
        local interval = self:get_delayed_requests_interval()
        local t = TimerManager:new(interval, "MILLISECONDS", function()
          ApiRestManager.send_delayed_request_timer_callback(request)
        end)
        t:start()
      else
        ApiRestManager.call_api_rest_request(request)
      end
    else
      break -- esce dal for se coda vuota
    end
  end
end

function ApiRestManager.send_delayed_request_timer_callback(request)
  if (SKC4_LOGGER) then
    SKC4_LOGGER:debug("Request stored in timer obj:", request)
  end
  ApiRestManager.call_api_rest_request(request)
end

function ApiRestManager.call_api_rest_request(request)

  if (request) then
    if (request["verb"]=="get") then
      request.handler:Get(request.url, request.headers)
    elseif (request["verb"]=="post") then
      request.handler:Post(request.url, request.data, request.headers)
    elseif (request["verb"]=="put") then
      request.handler:Put(request.url, request.data, request.headers)
    elseif (request["verb"]=="delete") then
      request.handler:Delete(request.url, request.headers)
    else
      if (SKC4_LOGGER) then
        SKC4_LOGGER:debug("ApiRestManager: Incorrect request:", request)
      end
    end
  else
    if (SKC4_LOGGER) then
      SKC4_LOGGER:debug("ApiRestManager: Nil request:", request)
    end
  end

end

function ApiRestManager:generate_encoded_credential(username, password)
  return C4:Base64Encode(tostring(username)..":"..tostring(password))
end

function ApiRestManager:define_template(name, verb, endpoint, done_callback, response_processor, endpoint_processor, headers_processor, params_processor, data_processor)
  self._templates[name] = {
    verb = verb, 
    endpoint = endpoint, 
    done_callback = done_callback, 
    response_processor = response_processor, 
    endpoint_processor = endpoint_processor, 
    headers_processor = headers_processor, 
    params_processor = params_processor, 
    data_processor = data_processor
  }
end
function ApiRestManager:remove_template(name)
  self._templates[name] = nil
end
function ApiRestManager:get_template(name)
  return self._templates[name]
end
function ApiRestManager:template_exists(name)
  return (self._templates[name] ~= nil)
end

function ApiRestManager:add_request_by_template(name, headers, params, data)
  local template = self:get_template(name)
  return self:add_request( 
                        template["verb"], 
                        template["endpoint"], 
                        headers, 
                        params, 
                        data, 
                        template["done_callback"], 
                        template["response_processor"], 
                        template["endpoint_processor"], 
                        template["headers_processor"], 
                        template["params_processor"], 
                        template["data_processor"]
                      )
end
function ApiRestManager:add_request_by_template_by_key(name, key, headers, params, data)
  local template = self:get_template(name)
  return self:add_request_by_key(key, 
                        template["verb"], 
                        template["endpoint"], 
                        headers, 
                        params, 
                        data, 
                        template["done_callback"], 
                        template["response_processor"], 
                        template["endpoint_processor"], 
                        template["headers_processor"], 
                        template["params_processor"], 
                        template["data_processor"]
                      )
end




function ApiRestManager:querystring_params_processor(endpoint, params, headers)
  if (endpoint) then
    if (params == nil) then 
      params = {}
    end
    local ret_string = nil
    for k,v in pairs(params) do
      if (ret_string == nil) then
        ret_string = "?"
      else
        ret_string = ret_string .. "&"
      end
      ret_string = ret_string..tostring(k).."="..ApiRestManager.encode_value(tostring(v))
    end
    if (ret_string) then
      return endpoint..ret_string
    else
      return endpoint
    end
  else
    return ""
  end
end

function ApiRestManager:json_data_processor(data)
  if (type(data) == "table") then
    return C4:JsonEncode(data)
  else
    return tostring(data)
  end
end
function ApiRestManager:dummy_headers_processor(headers)
  return headers or {}
end
function ApiRestManager:dummy_params_processor(params)
  return params or {}
end
function ApiRestManager:json_response_processor(transfer, response)
  if (response) then
    if (response.data) then
      response.data = C4:JsonDecode(response.data)
    end
  end
end

function ApiRestManager.encode_value(str)
	local ret_str = (str:gsub("([^A-Za-z0-9%_%.%-%~])", function(v)
			return string.upper(string.format("%%%02x", string.byte(v)))
  end))
	return ret_str:gsub('%%20', '+')
end


----------------------
-- Test
----------------------
function ApiRestManager.self_test()

end

return ApiRestManager