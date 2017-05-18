d3           = require 'd3'
fs           = require 'fs'
path         = require 'path'
winston      = require 'winston'

{RpcClient}  = require './rpc'


module.exports = utils = Object.create Object.prototype, {
  logger: {
    get: () ->
      label = getLabel()
      new winston.Logger {
        transports: [
          new winston.transports.Console {
            colorize: true
            timestamp: () -> fmt new Date()
            label: label
            exitOnError: true
          }
          new winston.transports.File {
            stream:    fs.createWriteStream './logs', flags: 'a'
            timestamp: () -> fmt new Date()
            label: label
            json:  false
            level: 'verbose'
          }
        ]
      }
  }
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
  fullPath = stack.split('\n')[4].split(':')[0].split('(')[1]
  path.relative cwd, fullPath
