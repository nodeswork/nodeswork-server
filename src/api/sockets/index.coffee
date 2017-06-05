{logger}          = require 'nodeswork-logger'

{
  deviceSocket
  deviceRpcClient
}                 = require './device'
{
  messageSocket
}                 = require './message'

attachIO = (io) ->
  moduleExports.io = io
  deviceSocket  io
  messageSocket io
  rootSocket    io


rootSocket = (io) ->
  io

    .on 'connection', (socket) ->
      logger.info "New socket connection with", socket.handshake.query

      socket.on 'disconnect', () ->
        logger.info 'Lost connection.', socket.handshake.query.token

module.exports = moduleExports = {
  attachIO: attachIO
  deviceRpcClient
}
