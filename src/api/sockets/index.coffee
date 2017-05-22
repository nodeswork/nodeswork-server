{
  deviceSocket
  deviceRpcClient
}                 = require './device'
{Device}          = require '../models'
{logger}          = require '../../utils'

exports.attachIO = (io) ->
  deviceSocket io
  rootSocket io

exports.deviceRpcClient = deviceRpcClient


rootSocket = (io) ->
  io
    .use authorization

    .on 'connection', (socket) ->
      logger.info "New socket connection with", socket.handshake.query

      socket.on 'disconnect', () ->
        logger.info 'Lost connection.', socket.handshake.query.token


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
