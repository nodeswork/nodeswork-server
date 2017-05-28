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

      socket.on 'disconnect', () ->
        logger.info 'Lost device connection.', socket.handshake.query
        deviceRpcClient.unregisterSocket socket


exports.deviceRpcClient = deviceRpcClient = new RpcClient {
  timeout: 60000
  funcs: ['run', 'runningApplets']
}
