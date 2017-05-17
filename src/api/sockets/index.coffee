{deviceSocket} = require './device'
{Device}       = require '../models'

exports.attachIO = (io) ->
  deviceSocket io
  rootSocket io


connected = false

rootSocket = (io) ->
  io
    .use authorization

    .on 'connection', (socket) ->
      connected = true
      console.log 'New connection.', socket.handshake.query.token
      device = await Device.findOne {
        user:         socket.handshake.query.user
        deviceToken:  socket.handshake.query.token
      }
      console.log device

    .on 'disconnect', (socket) ->
      console.log 'Lost connection.', socket.handshake.query.token

    .on 'message', (msg) ->
      console.log 'message', msg

    .on 'hello', () ->
      console.log 'hello'


authorization = (socket, next) ->
  # if not connected then return next()
  unless token = socket.handshake.query.token
    return next new Error "Token is invalid."

  device = await Device.findOne {
    deviceToken: token
  }

  unless device? then return next new Error "Token is invalid."

  next()
