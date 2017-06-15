### Generate CRUD KOA middlwares for mongoose models.
###


_                 = require 'underscore'

{NodesworkError}  = require '../../errors'


# Generate KOA middlewares for mongoose models.
#
# @example
#   UserSchema = mongoose.Schema {
#     name:     String
#     address:
#       type:   mongoose.Schema.ObjectId
#       ref:    'Address'
#     create:   Date
#   }, collections: 'users'
#     .plugin KoaMiddlewars, {
#       omits:    [ 'create' ]
#       populate: [ 'address' ]
#     }
#
# @option options {Array<String>} middlewares which middlewares going to be
#   attached to the schema. By default, it includes create, get, find, update,
#   and delete.
# @option options {Array<String>} omits=[] specifies which fields will be
#   omitted, it will be added to each middleware's omits option.
# @option options {Array<String>} populate=[] specifies which fields to
#   populate, it will be added to each middleware's populate option.
# @option options {Boolean} triggerNext=false specifies if to trigger the next
#   middleware, it will be set to default for each middleware's triggerNext
#   option.
# @option options {Function} transform=null specifies transform for the
#   responding model instance, it will be set to default for each middleware's
#   transform option.
KoaMiddlewares = (schema, options={}) ->
  {
    middlewares = ['create', 'get', 'find', 'update', 'delete']
    omits       = []
    populate    = []
  } = options

  # Wrap middlewars to patch global options.
  wrap = (fn) -> (opts={}) ->
    opts.omits        = _.union(
      options.omits, opts.omits, KoaMiddlewares.defaults.omits
    )
    opts.populate     = _.union(
      options.populate, opts.populate, KoaMiddlewares.defaults.populate
    )
    opts.transform    = opts.transform ? options.transform
    opts.triggerNext  = opts.triggerNext ? options.triggerNext
    fn.call @, opts

  statics                  = schema.statics
  statics.createMiddleware = wrap createMiddleware if 'create' in middlewares
  statics.getMiddleware    = wrap getMiddleware    if 'get'    in middlewares
  statics.findMiddleware   = wrap findMiddleware   if 'find'   in middlewares
  statics.updateMiddleware = wrap updateMiddleware if 'update' in middlewares
  statics.deleteMiddleware = wrap deleteMiddleware if 'delete' in middlewares


# The global configurations.
KoaMiddlewares.defaults = {
  omits:     []
  populate:  []
}


# Provide Koa Create middleware to create model instance.
#
# @note before entering to next middleware, the model is still not created.
#   ctx[target] is the doc which is going to be passed to Model.create(). The
#   actual model will be created after next middleware finished.
#
# @option options {Boolean} writeToBody=true indicates wheather to write the
#   result to koa.body.
# @option options {Array<String>} populate=[] specifies which fields to populate
#   after creation.
# @option options {String} target='object' specifies which field of the ctx is
#   the target to store the document.
# @option options {Array<String>} omits=[] specifies which fields from the
#   ctx.request.body to be omitted before creating the document.
# @option options {Boolean} fromExtend=true specifies if the model is targeted
#   for schemas created by mongoose extened schema.
# @option options {Boolean} triggerNext=false specifies if to trigger the next
#   middleware.
# @option options {Function} transform=null specifies transform function for the
#   responding model instance.
#
# @throw error (NodesworkError) when
#   1. fromExtend is true but value of discriminatorKey is missing;
#   2. modelType specified by discriminatorKey is not correct;
#
# @return [KoaMiddleware] the creation Koa middleware.
createMiddleware = (options={}) ->
  {
    writeToBody = true
    fromExtend  = true
    populate    = []
    target      = 'object'
    omits       = []
    triggerNext = false
    transform   = _.identity
  } = options

  (ctx, next) =>
    doc   = _.extend {}, ctx.request.body, ctx.overrides?.doc

    model =
      if fromExtend and (discriminatorKey = @schema.options.discriminatorKey)
        NodesworkError.required doc, discriminatorKey

        try
          model = @db.model modelType = doc[discriminatorKey]
        catch
          NodesworkError.unkownValue key: discriminatorKey, value: modelType

        if model.schema.options.discriminatorKey != discriminatorKey
          NodesworkError.unkownValue key: discriminatorKey, value: modelType
        model
      else @

    ctx[target] = _.omit doc, omits

    await next() if triggerNext

    try
      ctx[target] = await model.create ctx[target]
    catch e
      NodesworkError.mongooseError e

    await model.populate ctx[target], populate if populate.length

    ctx.body = await transform ctx[target] if writeToBody


# Provide Koa Get middleware to retrieve model instance.
#
# @option options {String} field specifies which field of ctx.params to retrieve
#   the model id, it is a required field.
# @option options {Boolean} writeToBody=true indicates wheather to write the
#   result to koa.body.
# @option options {Array<String>} populate=[] specifies which fields to populate
#   after getting the object.
# @option options {String} target='object' specifies which field of the ctx is
#   the target to store the documents.
# @option options {Boolean} triggerNext=false specifies if to trigger the next
#   middleware.
# @option options {Function} transform=null specifies transform function for the
#   responding model instances.
#
# @return [KoaMiddleware] the get Koa middleware.
getMiddleware = (options={}) ->
  {
    field
    writeToBody         = true
    populate            = []
    target              = 'object'
    triggerNext         = false
    transform           = _.identity
  } = options

  (ctx, next) =>
    query        = ctx.overrides?.query ? {}
    query._id    = ctx.params[field]
    qp           = @findOne query
    qp           = qp.populate populate if populate.length
    ctx[target]  = await qp
    await next() if triggerNext
    ctx.body     = await transform ctx[target] if writeToBody


# Provide Koa Find middleware to retrieve multiple model instances.
#
# @option options {Boolean} writeToBody=true indicates wheather to write the
#   result to koa.body.
# @option options {Array<String>} populate=[] specifies which fields to populate
#   after getting the objects.
# @option options {String} target='object' specifies which field of the ctx is
#   the target to store the document.
# @option options {Boolean} triggerNext=false specifies if to trigger the next
#   middleware.
# @option options {Function} transform=null specifies transform function for the
#   responding model instance.
# @option options {String} sort=null specifies the sort parameters to be
#   passed to mongoose.
# @option options {Number} pagination=0 specifies if to enable pagination,
#   possible integer means the page size, 0 means not enabled.
# @option options {Array<String>} allowedQueryFields=null specifies which fields
#   will be allowed for retrieving the target objects, default will be no guard.
#
# @return [KoaMiddleware] the find Koa middleware.
findMiddleware = (options={}) ->
  {
    writeToBody         = true
    populate            = []
    target              = 'object'
    triggerNext         = false
    transform           = _.identity
    sort                = null
    pagination          = false
    allowedQueryFields  = null
  } = options

  (ctx, next) =>
    query        = NodesworkError.parseJSON ctx.request.query.query
    page         = NodesworkError.parseNumber ctx.request.query.page ? '0'
    query        = _.pick query, allowedQueryFields if allowedQueryFields?
    _.extend query, ctx.overrides?.query
    qp           = @find query
    qp           = qp.limit pagination if pagination
    qp           = qp.skip page * pagination if pagination and page
    qp           = qp.populate populate if populate.length
    qp           = qp.sort sort if sort?
    ctx[target]  = await qp
    await next() if triggerNext

    if pagination
      totalPage = (await @find(query).count() - 1) // pagination + 1
      ctx.response.set 'total_page', totalPage


    for i in [0...ctx[target].length]
      ctx[target][i] = await transform ctx[target][i]

    ctx.body     = ctx[target] if writeToBody



# Provide Koa Update middleware to update an existing model instance.
#
# @option options {String} field specifies which field of ctx.params to retrieve
#   the model id, it is a required field.
# @option options {Boolean} writeToBody=true indicates wheather to write the
#   result to koa.body.
# @option options {String} target='object' specifies which field of the ctx is
#   the target to store the document.
# @option options {Array<String>} omits=[] specifies which fields from the
#   ctx.request.body to be omitted before creating the document.
# @option options {Boolean} triggerNext=false specifies if to trigger the next
#   middleware.
# @option options {Function} transform=null specifies transform function for the
#   responding model instance.
#
# @return [KoaMiddleware] the update Koa middleware.
updateMiddleware = (options={}) ->
  {
    field
    writeToBody         = true
    populate            = []
    omits               = []
    target              = 'object'
    triggerNext         = false
    transform           = _.identity
  } = options

  (ctx, next) =>
    query        = ctx.overrides?.query ? {}
    query._id    = ctx.params[field]
    ctx[target]  = await @findOne query

    _.extend ctx[target], _.omit ctx.request.body, omits
    await next() if triggerNext
    await ctx[target].save()

    model        = ctx[target].constructor
    await model.populate ctx[target], populate if populate.length
    ctx.body     = transform ctx[target] if writeToBody


# Provide Koa Delete middleware to delete an existing model instance.
#
# @option options {String} field specifies which field of ctx.params to retrieve
#   the model id, it is a required field.
# @option options {Boolean} writeToBody=true indicates wheather to write the
#   result to koa.body.
# @option options {Boolean} triggerNext=false specifies if to trigger the next
#   middleware.
#
# @return [KoaMiddleware] the delete Koa middleware.
deleteMiddleware = (options={}) ->
  {
    field
    writeToBody         = true
    target              = 'object'
    triggerNext         = false
    transform           = _.identity
  } = options

  (ctx, next) =>
    query        = ctx.overrides?.query ? {}
    query._id    = ctx.params[field]
    ctx[target]  = await @findOne query

    await next() if triggerNext
    await ctx[target].remove()

    ctx.body     = null if writeToBody


module.exports = { KoaMiddlewares }
