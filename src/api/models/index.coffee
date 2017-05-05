# Patch mongoose schema extend
_                       = require 'underscore'
mongoose                = require 'mongoose'
mongooseSchemaExtend    = require 'mongoose-schema-extend'
mongooseTypeEmail       = require 'mongoose-type-email'


accounts                = require './accounts'
users                   = require './users'
utils                   = require './utils'


_.extend module.exports, users, utils


# Register models after mongoose connections and other setups ready.
exports.registerModels = (mongooseInstance = mongoose) ->
  registerModel = (modelName, modelSchema) ->
    exports[modelName] = mongooseInstance.model modelName, modelSchema

  registerModel modelName, modelSchema for [modelName, modelSchema] in [
    ['User',               users.UserSchema]
    ['EmailUser',          users.EmailUserSchema]
    ['Account',            accounts.AccountSchema]
    ['FifaFutAccount',     accounts.FifaFutAccountSchema]
  ]

  return
