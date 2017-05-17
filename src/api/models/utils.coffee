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

  schema.statics.getMiddleware = (opts={}) ->
    {
      field
      writeToBody=true
    } = opts
    (ctx, next) =>
      query              = ctx.overrides?.query ? {}
      query._id          = ctx.params[field]
      ctx.object         = await @findOne query
      await next()
      ctx.response.body  = ctx.object if writeToBody

  schema.statics.findMiddleware = (opts={}) ->
    {
      writeToBody=true
    } = opts
    (ctx, next) =>
      query              = ctx.overrides?.query ? {}
      ctx.object         = await @find query
      await next()
      ctx.response.body = ctx.object if writeToBody

  schema.statics.updateMiddleware = (opts={}) ->
    {
      field
      omits=[]
      writeToBody=true
    } = opts

    (ctx, next) =>
      query           = ctx.overrides?.query ? {}
      query._id       = ctx.params[field]
      ctx.object      = object = await @findOne query

      _.extend object, _.omit ctx.request.body, omits

      await next()
      await ctx.object.save()
      ctx.response.body = ctx.object if writeToBody

  schema.statics.createMiddleware = (opts={}) ->
    {
      writeToBody=true
    } = opts
    (ctx, next) =>
      doc = _.extend {}, ctx.request.body, ctx.overrides?.doc

      key = schema.options.discriminatorKey

      if key
        unless doc[key]
          throw new Error "Missing required parameter #{key}."

        try
          model = @db.model doc[key]
        catch
          throw new Error "Unkown required parameter #{key} value: #{doc[key]}."

        if model.schema.options.discriminatorKey != key
          throw new Error "Unkown required parameter #{key} value: #{doc[key]}."
      else
        model = @

      ctx.object = await model.create doc
      await next()
      ctx.response.body = ctx.object if writeToBody
