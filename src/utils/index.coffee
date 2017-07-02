_                   = require 'underscore'
mongoose            = require 'mongoose'

{ NodesworkError }  = require 'nodeswork-utils'

{ RpcClient }  = require './rpc'


ObjectId = (x) ->
  switch
    when x?._id? then x._id
    when _.isString x then mongoose.Types.ObjectId x
    when x instanceof mongoose.Types.ObjectId then x
    else throw new NodesworkError 'Unkown id type'


ObjectIdEquals = (a, b) ->
  ObjectId(a).equals Object(b)


module.exports = {
  RpcClient
  ObjectId
  ObjectIdEquals
}
