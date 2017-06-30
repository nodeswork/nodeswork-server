# Loading the configuration based on env.

_               = require 'underscore'
env             = process.env.NODE_ENV || 'development'
base            = require './base'
config          = require "./#{env}"

module.exports  = _.extend {}, base, config
