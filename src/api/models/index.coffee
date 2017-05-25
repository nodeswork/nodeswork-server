# Patch mongoose schema extend
_                       = require 'underscore'
{logger}                = require 'nodeswork-utils'
mongoose                = require 'mongoose'
mongooseSchemaExtend    = require 'mongoose-schema-extend'
mongooseTypeEmail       = require 'mongoose-type-email'


accounts                = require './accounts'
applets                 = require './applets'
devices                 = require './devices'
messages                = require './messages'
users                   = require './users'
usersApplets            = require './users-applets'
utils                   = require './utils'


_.extend module.exports, users, utils


# Register models after mongoose connections and other setups ready.
exports.registerModels = (mongooseInstance = mongoose) ->
  registerModel = (modelName, modelSchema) ->
    logger.info 'Registering model:', name: modelName
    exports[modelName] = mongooseInstance.model modelName, modelSchema

  registerModel modelName, modelSchema for [modelName, modelSchema] in [
    ['User',               users.UserSchema]
    ['EmailUser',          users.EmailUserSchema]
    ['Account',            accounts.AccountSchema]
    ['FifaFutAccount',     accounts.FifaFutAccountSchema]
    ['Applet',             applets.AppletSchema]
    ['NpmApplet',          applets.NpmAppletSchema]
    ['UserApplet',         usersApplets.UserAppletSchema]
    ['Device',             devices.DeviceSchema]
    ['Message',            messages.MessageSchema]
    ['AppletMessage',      messages.AppletMessageSchema]
  ]

  return
