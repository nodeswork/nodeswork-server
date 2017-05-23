{
  logger
  RpcClient
}              = require '../../utils'


exports.deviceSocket = deviceSocket = (io) ->
  io

    .of '/device'

    .on 'connection', (socket) ->
      logger.info 'New device connection.'

      socket.deviceRpc = deviceRpcClient.registerSocket socket

      data = await socket.deviceRpc.notify 'good'
      logger.info "Get data for notify:", data

      runningApplets = await socket.deviceRpc.runningApplets()
      logger.info "Get data for runningApplets:", runningApplets

      try
        await deviceRpcClient.sendRequest socket, name: 'unkown func'
      catch e
        logger.error "Catch an exception:", e

      socket.on 'disconnect', () ->
        logger.info 'Lost device connection.', socket.handshake.query
        deviceRpcClient.unregisterSocket socket


exports.deviceRpcClient = deviceRpcClient = new RpcClient {
  timeout: 1000
  funcs: ['notify', 'runningApplets']
}
