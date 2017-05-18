winston        = require 'winston'

{deviceSocket} = require './device'
{Device}       = require '../models'

exports.attachIO = (io) ->
  deviceSocket io
  rootSocket io


rootSocket = (io) ->
  io
    .use authorization

    .on 'connection', (socket) ->
      winston.info "New socket connection with", socket.handshake.query

    .on 'disconnect', (socket) ->
      console.log 'Lost connection.', socket.handshake.query.token

    .on 'message', (msg) ->
      console.log 'message', msg


authorization = (socket, next) ->
  winston.info "Autorization on socket"
  return next()
  unless token = socket.handshake.query.token
    return next new Error "Token is invalid."

  device = await Device.findOne {
    deviceToken: token
  }

  unless device? then return next new Error "Token is invalid."

  next()
