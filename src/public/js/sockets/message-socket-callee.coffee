define ['sockets/socket-callee'], (SocketCallee) ->
  class MessageSocketCallee extends SocketCallee

    constructor: (options) ->
      super options
      {@onMessageStateChange} = options

    changeMessageState: (messageState) ->
      @onMessageStateChange messageState
      return
