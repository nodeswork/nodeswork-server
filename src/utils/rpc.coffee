_         = require 'underscore'
LRU       = require 'lru-cache'

{logger}  = require './logger'

exports.RpcClient = class RpcClient

  constructor: ({
    @timeout=0
    @funcs=[]
    @bufferSize=100
  }) ->

    @callStack = LRU {
      max:     @bufferSize
      maxAge:  1000 * 60 * 60    # 60 minutes
    }

    @sid = 0

    @RpcClass = class RpcClass extends Rpc

    that = @
    _.each @funcs, (func) =>
      @RpcClass::[func] = (params...) ->
        that.sendRequest @socket, name: func, params: params

    @devices = {}

  sendRequest: (socket, {name, params}) ->
    request = {
      name:    name
      params:  params
      sid:     @sid++
    }

    logger.info 'Send a rpc call', request
    socket.emit 'rpcCall', request

    new Promise (resolve, reject) =>
      @callStack.set request.sid, [resolve, reject]

      if @timeout
        setTimeout (() =>
          if @callStack.has request.sid
            reject "Timeout."
            @callStack.del request.sid
        ), @timeout


  registerSocket: (socket) ->
    socket.on 'rpcResponse', (resp) =>
      if @callStack.has resp.sid
        logger.info 'rcpResponse', resp
        [resolve, reject] = @callStack.get resp.sid

        if resp.status == 'ok' then resolve resp.data
        else reject resp.error
        @callStack.del resp.sid
      else
        logger.info 'Got rcpResponse, but entry is gone.', resp
    @devices[socket.handshake.query.token] = new @RpcClass socket: socket


  unregisterSocket: (socket) ->
    delete @devices[socket.handshake.query.token]

  getRpc: (socketOrToken) ->
    if socketOrToken?.handshake?.query?.token
      @devices[socketOrToken.handshake.query.token]
    else @devices[socketOrToken]


exports.Rpc = class Rpc

  constructor: ({@socket}) ->
