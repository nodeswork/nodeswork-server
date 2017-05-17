

exports.deviceSocket = deviceSocket = (io) ->
  io

    .of '/device'

    .on 'connection', (socket) ->
      console.log 'New device connection.', socket.handshake

    .on 'disconnect', (socket) ->
      console.log 'Lost device connection.', socket.handshake
