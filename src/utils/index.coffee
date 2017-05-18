_       = require 'underscore'
LRU     = require 'lru-cache'
winston = require 'winston'

exports.RpcClient = class RpcClient

  constructor: ({
    @socket
    @timeout=0
    @funcs=[]
    @bufferSize=100
  }) ->

    @socket.on 'rpcResponse', (resp) =>
      if @callStack.has resp.sid
        winston.info 'rcpResponse', resp
        [resolve, reject] = @callStack.get resp.sid

        if resp.status == 'ok' then resolve resp.data
        else reject resp.error
        @callStack.del resp.sid
      else
        winston.info 'Got rcpResponse, but entry is gone.', resp

    @callStack = LRU {
      max:     @bufferSize
      maxAge:  1000 * 60 * 60    # 60 minutes
    }

    @sid = 0

    _.each @funcs, (func) => @[func] = (params...) ->
      @sendRequest name: func, params: params

  sendRequest: ({name, params}) ->
    request = {
      name:    name
      params:  params
      sid:     @sid++
    }

    winston.info 'Send a rpc call', request
    @socket.emit 'rpcCall', request

    new Promise (resolve, reject) =>
      @callStack.set request.sid, [resolve, reject]

      if @timeout
        setTimeout (() =>
          if @callStack.has request.sid
            reject "Timeout."
            @callStack.del request.sid
        ), @timeout
