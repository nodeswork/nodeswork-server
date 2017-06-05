_                     = require 'underscore'
cookie                = require 'cookie'
mongoose              = require 'mongoose'
{logger}              = require 'nodeswork-logger'
{
  MESSAGE_ROOM_SOCKET
}                     = require '../constants'

messageSocket = (io) ->
  io

    .of MESSAGE_ROOM_SOCKET

    .use authorization

    .on 'connection', (socket) ->
      logger.info 'New message connection.', user: socket.userId
      socket.join "state::#{socket.userId}"


module.exports = {
  messageSocket
}


authorization = (socket, next) ->
  c = cookie.parse socket.handshake.headers.cookie
  logger.info "Autorization on socket", cookie: c
  unless c?['koa.sid']
    logger.error "Session id is missing."
    return next new Error "Cookie is invalid."

  s = await mongoose.models.KoaSession.findOne {
    sid: "koa:sess:#{c['koa.sid']}"
  }

  s = JSON.parse s.blob if s?

  unless s?.userId
    logger.error "Cookie is invalid, because session is not found."
    return next new Error "Cookie is invalid."

  socket.userId = s.userId

  next()
