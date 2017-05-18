d3           = require 'd3'
fs           = require 'fs'
path         = require 'path'
winston      = require 'winston'

{RpcClient}  = require './rpc'


module.exports = utils = Object.create Object.prototype, {
  logger:
    get: () -> require('./logger').logger

  RpcClient:
    value: RpcClient
}



cwd = process.cwd()
fmt = d3.timeFormat '%Y-%m-%d %X'

winston.remove winston.transports.Console
winston.add    winston.transports.Console, {
  colorize: true
  timestamp: () ->
    fmt new Date()
}

getLabel = () ->
  stack = new Error().stack
  fullPath = stack.split('\n')[2].split(':')[0].split('(')[1]
  path.relative cwd, fullPath
