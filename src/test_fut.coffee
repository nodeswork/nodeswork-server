futapi                  = require 'fut-api'


apiClient = new futapi()


twoFactorCodeCb = (next) ->
  console.log '???????'
  next "123456"


onDone = (err, response) ->
  console.log err, response

apiClient.login "zyz.4.zyz@gmail.com", "Zzll1314", "dazhen", "xone", twoFactorCodeCb, onDone
