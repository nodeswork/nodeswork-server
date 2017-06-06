# Patch mongoose schema extend
_                       = require 'underscore'
{logger}                = require 'nodeswork-utils'
mongoose                = require 'mongoose'
mongooseSchemaExtend    = require 'mongoose-schema-extend'
mongooseTypeEmail       = require 'mongoose-type-email'


accounts                = require './accounts'
accountCategories       = require './account_categories'
applets                 = require './applets'
devices                 = require './devices'
appletsExecutions       = require './applets-executions'
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
    ['SystemUser',         users.SystemUserSchema]
    ['AccountCategory',    accountCategories.AccountCategorySchema]
    ['Account',            accounts.AccountSchema]
    ['OAuthAccount',       accounts.OAuthAccountSchema]
    ['FifaFutAccount',     accounts.FifaFutAccountSchema]
    ['Applet',             applets.AppletSchema]
    ['NpmApplet',          applets.NpmAppletSchema]
    ['SystemApplet',       applets.SystemAppletSchema]
    ['UserApplet',         usersApplets.UserAppletSchema]
    ['Device',             devices.DeviceSchema]
    ['Message',            messages.MessageSchema]
    ['AppletMessage',      messages.AppletMessageSchema]
    ['AppletExecution',    appletsExecutions.AppletExecutionSchema]
  ]

  containerAppletOwner = await mongoose.models.SystemUser.containerAppletOwner()
  logger.info(
    'Ensure system user container applet exists:'
    containerAppletOwner.toJSON()
  )

  containerApplet = await mongoose.models.SystemApplet.containerApplet()
  logger.info(
    'Ensure system applet container exists:'
    containerAppletOwner.toJSON()
  )

  await ensureAccountCategories()

  return

# Ensure load account categories to database.
ensureAccountCategories = () ->
  accountCategories = require './account_categories_data.json'

  AccountCategory  = mongoose.models.AccountCategory

  for accountCategory in accountCategories
    for i in [0...accountCategory.implements.length]
      category = (
        await AccountCategory.findOne name: accountCategory.implements[i]
      )
      unless category?
        throw new Error "Account Category
          #{accountCategory.implements[i]} is not find."
      accountCategory.implements[i] = category._id

    await AccountCategory.findOneAndUpdate(
      { name: accountCategory.name }
      { "$set": accountCategory }
      { new: true, upsert: true }
    )
