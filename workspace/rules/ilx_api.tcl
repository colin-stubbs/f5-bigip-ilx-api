# ilx_api.tcl
#
# ------------------------------------------------------------------------------
#
# Copyright 2019 Colin Stubbs <cstubbs@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# ------------------------------------------------------------------------------

when RULE_INIT {
  log local0. "initialised..."
}
when HTTP_REQUEST {
  set ILX_API_DEBUG_LEVEL 9
  set ILX_API_PLUGIN_NAME {ilx_api}
  set ILX_API_EXTENSION_NAME {ilx_api}
  # this is the maximum size JSON report we should consider accepting
  set ILX_API_MAX_CONTENT_LENGTH 2048
  set ILX_API_KEY {CHANGE_ME}
  set ILX_API_PATH {/ilx/api}

  set http_ilx_api_request 0
  set http_method [HTTP::method]
  set http_request_hostname [HTTP::host]
  set http_request_uri [HTTP::uri]
  set http_content_type [string tolower [HTTP::header value {Content-Type}]]
  set http_content_length [HTTP::header value {Content-Length}]
  set http_request_user_agent [HTTP::header value {User-Agent}]

  set X-ILX-API-Key [HTTP::header value {X-ILX-API-Key}]

  if { ${http_request_uri} starts_with ${ILX_API_PATH} 
    and ${X-ILX-API-Key} equals ${ILX_API_KEY}
    and ${http_content_type} != {}
    and ${http_content_length} != {} } 
  {
    set ILX_API_REMOTE_FUNC_NAME [string map "${ILX_API_PATH} {}" [string tolower ${http_request_uri}]]
    set http_ilx_api_request 1

    if { ${ILX_API_DEBUG_LEVEL} >= {1} } { log local0.debug "Authy request received hostname = '${http_request_hostname}', URI = '${http_request_uri}', Method = '${http_method}', Content-Type = '${http_content_type}', Content-Length = '${http_content_length}'" }
    if { ${ILX_API_DEBUG_LEVEL} >= {1} } { log local0.debug "Authy ILX function name: ${ILX_API_REMOTE_FUNC_NAME}" }

    # Handle CORS requests blindly
    switch [string tolower ${http_method}] {
      "options" {
        if { ${ILX_API_DEBUG_LEVEL} >= {1} } { log local0.debug "CORS (OPTIONS) request" }

        set cors_report_methods {OPTIONS, POST, PUT}
        set cors_report_origins {*}

        # this is all that's necessary for CORS; immediate 200 response with no content
        HTTP::respond 200 -version auto {Access-Control-Allow-Methods} ${cors_report_methods} {Access-Control-Allow-Origin} ${cors_report_origins}
        return
      }
      "post" -
      "put" {
        # reports are JSON but the Content-Type values used by browsers *MAY* vary...

        switch -glob ${http_content_type} {
          "application/json*" {
            if { ${http_content_length} != {} } {
              if { [catch {incr http_content_length}] or ${http_content_length} <= 0 or ${http_content_length} > ${ILX_API_MAX_CONTENT_LENGTH} } {
                # Content-Length is not acceptable
                if { ${http_content_length} > ${ILX_API_MAX_CONTENT_LENGTH} } {
                  # FIXME - generate alerts/logs/metrics indicating that we're seeing unexpectedly large requests bodies
                  log local0.error "ERROR: report body size too large, ${body_size} > ${ILX_API_MAX_CONTENT_LENGTH}"
                }
              } else {
                # Content-Length appears OK
                HTTP::collect ${http_content_length}
                return
              }
            }
          }
        }
      }
    }    
  }
  
  # return 400 Bad Request as request does not meet criteria
  HTTP::respond 400 -version auto content {<html><body><p>Invalid Request</p></body></html>}
  return
}
when HTTP_REQUEST_DATA {
  if { ${http_ilx_api_request} equals {1} } {
    set BODY [string trim [HTTP::payload]]
    
    set RPC_HANDLE [ILX::init ${ILX_API_PLUGIN_NAME} ${ILX_API_EXTENSION_NAME}]

    if { [catch { ILX::call ${RPC_HANDLE} ${ILX_API_REMOTE_FUNC_NAME} ${BODY} } RPC_RESPONSE ] } {
      log local0.error "ILX::call(${ILX_API_REMOTE_FUNC_NAME}) failed, it may not exist."
    } else {
      # check return indicator at start of list
      if { [lindex ${RPC_RESPONSE} 0] equals {0} and [lindex ${RPC_RESPONSE} 1] != {} } {
        log local0.info "ILX::call(${ILX_API_REMOTE_FUNC_NAME}) returned '[lindex ${RPC_RESPONSE} 0]' and '[lindex ${RPC_RESPONSE} 1]'"
        HTTP::respond 200 -version auto content "[lindex ${RPC_RESPONSE} 1]" {Content-Type} {application/json}
      } else {
        log local0.error "ILX::call(${ILX_API_REMOTE_FUNC_NAME}) returned '[lindex ${RPC_RESPONSE} 0]' and '[lindex ${RPC_RESPONSE} 1]'"
        HTTP::respond 400 -version auto content "[lindex ${RPC_RESPONSE} 1]" {Content-Type} {application/json}
      }
    }
  }
}

# EOF







