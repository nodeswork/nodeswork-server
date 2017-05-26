_                            = require 'underscore'

{ParameterValidationError}   = require '../errors'

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
      populate=[]
    } = opts
    (ctx, next) =>
      query              = ctx.overrides?.query ? {}
      query._id          = ctx.params[field]
      queryPromise       = @findOne query
      for f in populate
        queryPromise = queryPromise.populate f
      ctx.object         = await queryPromise
      await next()
      ctx.response.body  = ctx.object if writeToBody

  schema.statics.findMiddleware = (opts={}) ->
    {
      writeToBody=true
      populate=[]
    } = opts
    (ctx, next) =>
      query              = ctx.overrides?.query ? {}
      queryPromise       = @find query
      for f in populate
        queryPromise = queryPromise.populate f
      ctx.object         = await queryPromise
      await next()
      ctx.response.body = ctx.object if writeToBody

  schema.statics.updateMiddleware = (opts={}) ->
    {
      field
      omits=[]
      writeToBody=true
      populate=[]
      target='object'
    } = opts

    unless field? then throw new Error 'Parameter field is missing.'

    (ctx, next) =>
      query           = ctx.overrides?.query ? {}
      query._id       = ctx.params[field]
      queryPromise    = @findOne query
      for f in populate
        queryPromise = queryPromise.populate f
      ctx[target]     = object = await queryPromise

      Array::push.apply omits, ['_id', 'createdAt', 'lastUpdateTime']

      _.extend object, _.omit ctx.request.body, omits

      await next()
      await ctx[target].save()
      ctx.response.body = ctx[target] if writeToBody

  schema.statics.createMiddleware = (opts={}) ->
    {
      writeToBody=true
      fromExtend=true
      populate=[]
      target='object'
      omits=[]
    } = opts
    (ctx, next) =>
      doc = _.extend {}, ctx.request.body, ctx.overrides?.doc

      key = schema.options.discriminatorKey

      if key and fromExtend
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

      Array::push.apply omits, ['_id', 'createdAt', 'lastUpdateTime']

      ctx[target] = _.omit doc, omits

      await next()

      try
        ctx[target] = await model.create ctx[target]
      catch e
        switch
          when e.name == 'MongoError' and e.code == 11000
            throw new ParameterValidationError 'Dumplite records detected.'
          else throw e
      if populate.length
        await model.populate ctx[target], populate.join(' ')
      ctx.response.body = ctx[target] if writeToBody
