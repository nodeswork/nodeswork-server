winston        = require 'winston'

{RpcClient}    = require '../../utils'

exports.deviceSocket = deviceSocket = (io) ->
  io

    .of '/device'

    .on 'connection', (socket) ->
      winston.info 'New device connection.', socket.handshake.query

      deviceClient = new RpcClient {
        socket: socket
        timeout: 100
        funcs: ['notify']
      }

      data = await deviceClient.notify 'good'
      winston.info "Get data for notify:", data

      try
        await deviceClient.sendRequest name: 'unkown func'
      catch e
        winston.error "Catch an exception:", e

    .on 'disconnect', (socket) ->
      winston.info 'Lost device connection.', socket.handshake.query
