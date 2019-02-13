/* ilx_api/index.js
 *
 * Copyright 2019 Colin Stubbs <cstubbs@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
 
var f5 = require('f5-nodejs');

var ilx = new f5.ILXServer();

ilx.addMethod('/example/path/1', function(req, res) {
  var error = 0;
  var response = '{}';
  var body = {};
  var options = default_request_options;
  var user_id = -1;

  try {
    body = JSON.parse(req.params()[0]);
  } catch (e) {
    error = 1;
    response = '{"error":true,"message":"Invalid JSON body received"}';
    res.reply([error, response]);
    return;
  }
});

ilx.addMethod('/example/path/2', function(req, res) {
  var error = 0;
  var response = '{}';
  var body = {};
  var options = default_request_options;

  try {
    body = JSON.parse(req.params()[0]);
  } catch (e) {
    error = 1;
    response = '{"error":true,"message":"Invalid JSON body received"}';
    res.reply([error, response]);
    return;
  }
});

ilx.listen();

/* EOF */



