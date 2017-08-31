# Patch mongoose schema extend
_                           = require 'underscore'
mongoose                    = require 'mongoose'
mongooseTypeEmail           = require 'mongoose-type-email'

{ logger }                  = require '@nodeswork/logger'
{ KoaMiddlewares }          = require '@nodeswork/mongoose'

accounts                    = require './accounts'
accountCategories           = require './account_categories'
applets                     = require './applets'
devices                     = require './devices'
events                      = require './events'
executions                  = require './executions'
executionsActions           = require './executions-actions'
messages                    = require './messages'
users                       = require './users'
usersApplets                = require './users-applets'

{ TimestampModelPlugin }    = require './plugins/timestamps'
{ DataLevel }               = require './plugins/data-levels'
{ HandleMongooseError }     = require './plugins/mongoose-errors'


KoaMiddlewares.defaults.omits = [
  '_id', 'createdAt', 'lastUpdateTime'
]

# mongoose.plugin TimestampModelPlugin
# mongoose.plugin DataLevel
# mongoose.plugin KoaMiddlewares, middlwares: []
# mongoose.plugin HandleMongooseError


_.extend module.exports, users


# Register models after mongoose connections and other setups ready.
exports.registerModels = (mongooseInstance = mongoose) ->
  registerModel = (modelName, modelSchema) ->
    logger.info 'Registering model:', name: modelName
    if modelSchema.MongooseSchema?
      modelSchema = modelSchema.MongooseSchema()
    exports[modelName] = mongooseInstance.model modelName, modelSchema

  registerModel modelName, modelSchema for [modelName, modelSchema] in [
    # ['User',                     users.UserSchema]
    # ['EmailUser',                users.EmailUserSchema]
    # ['SystemUser',               users.SystemUserSchema]
    ['AccountCategory',          accountCategories.AccountCategorySchema]
    ['Account',                  accounts.AccountSchema]
    ['OAuthAccount',             accounts.OAuthAccountSchema]
    ['FifaFutAccount',           accounts.FifaFutAccountSchema]
    ['TwitterAccount',           accounts.TwitterAccountSchema]
    ['Applet',                   applets.AppletSchema]
    ['NpmApplet',                applets.NpmAppletSchema]
    ['SystemApplet',             applets.SystemAppletSchema]
    ['UserApplet',               usersApplets.UserAppletSchema]
    ['Device',                   devices.DeviceSchema]
    ['Message',                  messages.MessageSchema]
    ['AppletMessage',            messages.AppletMessageSchema]
    ['Execution',                executions.ExecutionSchema]
    ['ExecutionAction',          executionsActions.ExecutionActionSchema]
    ['Event',                    events.EventSchema]
    ['ContainerExecutionEvent',  events.ContainerExecutionEventSchema]
  ]

  # containerAppletOwner = await mongoose.models.SystemUser.containerAppletOwner()
  # logger.info(
    # 'Ensure system user container applet exists:'
    # containerAppletOwner.toJSON()
  # )

  # containerApplet = await mongoose.models.SystemApplet.containerApplet()
  # logger.info(
    # 'Ensure system applet container exists:'
    # containerAppletOwner.toJSON()
  # )

  # await ensureAccountCategories()

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
