{logger}          = require 'nodeswork-logger'

{
  deviceSocket
  deviceRpcClient
}                 = require './device'
{
  messageSocket
}                 = require './message'

exports.attachIO = (io) ->
  deviceSocket  io
  messageSocket io
  rootSocket    io

exports.deviceRpcClient = deviceRpcClient


rootSocket = (io) ->
  io

    .on 'connection', (socket) ->
      logger.info "New socket connection with", socket.handshake.query

      socket.on 'disconnect', () ->
        logger.info 'Lost connection.', socket.handshake.query.token
