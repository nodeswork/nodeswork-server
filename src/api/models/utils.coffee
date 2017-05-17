_  = require 'underscore'

exports.TimestampModelPlugin = TimestampModelPlugin = (schema, {
  createdAtIndex,
  lastUpdateTimeIndex
} = {}) ->
  createdAtIndex      ?= true
  lastUpdateTimeIndex ?= true

  schema.add {
    createdAt:      type: Date, default: Date.now, index: createdAtIndex
    lastUpdateTime: type: Date, index: lastUpdateTimeIndex
  }

  # Before save the document, update last update time.
  schema.pre 'save', (next) ->
    @lastUpdateTime = Date.now()
    next()

  # For each update operator, set up timestamps.
  schema.pre 'findOneAndUpdate', (next) ->
    @update {}, {
      '$set':
        lastUpdateTime: Date.now()
      '$setOnInsert':
        createdAt: Date.now()
    }
    next()


exports.ExcludeFieldsToJSON = ExcludeFieldsToJSON = (schema, {
  fields  # excluted fields
}) ->

  schema.methods.toJSON = () ->
    _.omit @toObject(), _.difference fields, @_fieldsToJSON

  schema.methods.withFieldsToJSON = (fields...) ->
    @_fieldsToJSON ?= []
    @_fieldsToJSON = _.union @_fieldsToJSON, _.flatten fields
    @


exports.KoaMiddlewares = KoaMiddlewares = (schema) ->

  schema.statics.getMiddleware = (fieldName) ->
    (ctx, next) =>
      query              = ctx.overrides?.query ? {}
      query._id          = ctx.params[fieldName]
      ctx.object         = await @findOne query
      await next()
      ctx.response.body  = ctx.object

  schema.statics.findMiddleware = () ->
    (ctx, next) =>
      ctx.object = await @find ctx.query ? {}
      await next()
      ctx.response.body = ctx.object

  schema.statics.updateMiddleware = (opts={}) ->
    {omits=[]}           = opts

    (ctx, next) =>
      query           = ctx.overrides?.query ? {}
      query._id       = ctx.params[fieldName]
      ctx.object      = object = await @findOne query

      _.extend object, _.omit ctx.request.body, omits

      await next()

      ctx.response.body = await ctx.object.save()

  schema.statics.createMiddleware = () ->
    (ctx, next) =>
      ctx.object = await @create _.extend(
        {}, ctx.request.body, ctx.overrides?.doc
      )
      await next()
      ctx.response.body = ctx.object
