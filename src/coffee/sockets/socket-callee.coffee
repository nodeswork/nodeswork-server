define [], () ->

  class SocketCallee

    constructor: ({@socket}) ->
      @socket.on 'rpc::call', (request) =>
        console.log 'received a rpc call', request
        unless func = @[request.name]
          return @socket.emit(
            'rpc::response',
            sid: request.sid
            status: 'error'
            error: "Unkown function #{request.name}"
          )

        try
          data      = await func.apply @, request.params
          response  = sid: request.sid, data: data, status: 'ok'
        catch e
          response  = {
            sid:     request.sid
            status:  'error'
            error:   e.message
          }
        console.log 'send response', response
        @socket.emit 'rpc::response', response
