{logger}  = require 'nodeswork-logger'

messageSocket = (io) ->
  io

    .of '/message'

    .on 'connection', (socket) ->
      logger.info 'New message connection.'


module.exports = {
  messageSocket
}
