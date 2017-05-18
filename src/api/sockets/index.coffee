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

    .on 'disconnect', (socket) ->
      console.log 'Lost connection.', socket.handshake.query.token

    .on 'message', (msg) ->
      console.log 'message', msg


authorization = (socket, next) ->
  logger.info "Autorization on socket"
  unless token = socket.handshake.query.token
    logger.error "Token is missing."
    return next new Error "Token is invalid."

  device = await Device.findOne {
    deviceToken: token
  }

  unless device?
    logger.error "Token is invalid, because Device is not found."
    return next new Error "Token is invalid."

  device.status = "ONLINE"
  await device.save()

  next()
