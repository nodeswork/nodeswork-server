{logger}       = require '@nodeswork/logger'

{RpcCaller}    = require '../../utils/rpc'
{Device}       = require '../models'


exports.deviceSocket = deviceSocket = (io) ->
  io

    .of '/device'

    .use authorization

    .on 'connection', (socket) ->
      logger.info 'New device connection.'

      token  = socket.handshake.query.token
      device = await Device.findOne deviceToken: token
      if device?
        socket.device = device._id
        socket.deviceRpc = deviceRpcClient.registerSocket socket
        await socket.deviceRpc.deploy device.user

        socket.on 'disconnect', () ->
          logger.info 'Lost device connection.', socket.handshake.query
          deviceRpcClient.unregisterSocket socket
      else
        socket.disconnect true



exports.deviceRpcClient = deviceRpcClient = new RpcCaller {
  timeout:    60000
  funcs:      ['process', 'appletStats', 'runningApplets', 'deploy', 'restart']
  socketKey:  (socket) -> socket.device.toString()
}


authorization = (socket, next) ->
  token = socket.handshake.query.token
  logger.info "Autorization on socket", token: token
  unless token
    logger.error "Token is missing."
    return next new Error "Token is invalid."

  device = await Device.findOne {
    deviceToken: token
  }

  unless device?
    logger.error "Token is invalid, because Device is not found."
    return next new Error "Token is invalid."

  next()
