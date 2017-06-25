### Generate CRUD KOA middlwares for mongoose models.
###


_                   = require 'underscore'
path                = require 'path'

{ logger }          = require 'nodeswork-logger'
{ NAMED }           = require 'nodeswork-utils'

{ NodesworkError }  = require '../../errors'


READONLY = 'RO'
AUTOGEN  = 'AG'


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

  schema.api   ?= "#{READONLY}": [], "#{AUTOGEN}": []
  schema.eachPath (pathname, schemaType) ->
    return unless schemaType.options.api in [ READONLY, AUTOGEN ]
    do (schema) ->
      while schema?
        schema.api[schemaType.options.api] = _.union(
          schema.api[schemaType.options.api]
          [ pathname ]
        )
        schema = schema.parentSchema

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

  statics.expose          ?= (router, options={}) ->
    options.schema = schema
    options.model  = @
    expose router, options


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

  NAMED 'createMiddleware', (ctx, next) =>
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

    omits       = _.union omits, @schema.api?[AUTOGEN]

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

  NAMED 'getMiddleware', (ctx, next) =>
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

  NAMED 'findMiddleware', (ctx, next) =>
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

  NAMED 'updateMiddleware', (ctx, next) =>
    query        = ctx.overrides?.query ? {}
    query._id    = ctx.params[field]
    ctx[target]  = await @findOne query
    omits        = _.union omits, @schema.api?[READONLY], @schema.api?[AUTOGEN]

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

  NAMED 'deleteMiddleware', (ctx, next) =>
    query        = ctx.overrides?.query ? {}
    query._id    = ctx.params[field]
    ctx[target]  = await @findOne query

    await next() if triggerNext
    await ctx[target].remove()

    ctx.body     = null if writeToBody


# Expose APIs to router.
#
# Explaination of Structure<Object>:
#   {
#     all:         object
#     gets:        object
#     posts:       object
#     methods:     object
#     statics:     object
#     individual:  object
#   }
# Depends on the object type, an individual final object will be combind from
#   [all, One of gets or posts, One of methods or statics, individual]
#
# @param {KoaRouter} router specifies the target router to expose the apis to.
# @option options {Structure<String>} prefix specifies the prefix for binding
#   the api.
# @option options {String} idField specifies the field name in params which
#   stores the model id when necessary.
# @option options {Function} instanceProvider fetch instance based on ctx, if
#   not set, a getMiddleware will be applied.
# @option options {Structure<Array<Middleware>>} pres specifies the pre
#   middlewares before call the actual execution functions.
# @option options {Structure<Array<Middleware>>} posts specifies the post
#   middlewares after call the actual execution functions.
# @option options {Structure<Object>} options specifies the options passed to
#   the actual execution functions.
# @option options {Array<String>} binds specifies the target function names to
#   bind.
# @option options {Boolean, Array<String>} cruds specifies if or which crud
#   functions to bind.
#
# @return void
expose = (router, options={}) ->
  {
    model
    schema
    prefix            = '/'
    idField           = 'id'
    instanceProvider  = null
    pres              = null
    posts             = null
    options           = null
    binds             = null
    cruds             = null
  }              = options

  prefix         = new Structure prefix, _.last
  pres           = new Structure pres, _.union
  posts          = new Structure posts, _.union
  options        = new Structure options, (l) ->
    _.extend.apply _.extend, [{}].concat l

  unless binds?
    binds = []
    for name, fn of schema.methods
      if fn.method in [ 'GET', 'POST' ]
        binds.push name
    for name, fn of schema.statics
      if fn.method in [ 'GET', 'POST' ]
        binds.push name

  if cruds and _.isBoolean cruds
    cruds = [ 'create', 'get', 'find', 'update', 'delete' ]
  cruds  ?= []

  binds = _.union binds, cruds

  bind = (name, pathname, fnType, mdType, middlewares...) ->
    fullpath = path.join prefix.get(name, fnType, mdType), pathname
    args     = _.filter _.flatten [
      fullpath
      pres.get name, fnType, mdType
      middlewares
      posts.get name, fnType, mdType
    ]

    logger.info 'Bind router', {
      path:        fullpath
      method:      mdType
      fnType:      fnType
      middlwares:  (x.name || 'unkown' for x in args[1..])
    }
    fn       = switch mdType
      when 'GET' then 'get'
      when 'POST' then 'post'
      when 'DELETE' then 'delete'
      else throw new NodesworkError 'Unkown method', method: mdType
    router[fn].apply router, _.flatten args

  getMiddleware = (name, opts={}) ->
    fnType = if name in ['get', 'update', 'delete'] then 'METHOD' else 'STATIC'
    mdType = switch name
      when 'get', 'find' then 'GET'
      when 'update', 'create' then 'POST'
      when 'delete' then 'DELETE'


    model["#{name}Middleware"](
      _.extend(
        triggerNext: !!posts.get(name, fnType, mdType).length
        options.get(name, fnType, mdType)
        opts
      )
    )

  idFieldName = ":#{idField}"

  for name in binds
    switch
      when name == 'create' and model.createMiddleware?
        bind 'create', '', 'STATIC', 'POST', getMiddleware 'create'
      when name == 'get'    and model.getMiddleware?
        bind(
          'get', idFieldName, 'METHOD', 'GET'
          getMiddleware 'get', field: idField
        )
      when name == 'find'   and model.findMiddleware?
        bind 'find', '', 'STATIC', 'GET', getMiddleware 'find'
      when name == 'update' and model.updateMiddleware?
        bind(
          'update', idFieldName, 'METHOD', 'POST'
          getMiddleware 'update', field: idField
        )
      when name == 'delete' and model.deleteMiddleware?
        bind(
          'delete', idFieldName, 'METHOD', 'DELETE'
          getMiddleware 'delete', field: idField
        )
      when httpMethod = schema.methods[name]?.method
        do (name, httpMethod) ->
          args = _.filter [
            name
            if instanceProvider? then name else "#{idFieldName}/#{name}"
            'METHOD'
            httpMethod
            getMiddleware 'get', {
              field:        idField
              triggerNext:  true
              writeToBody:  false
              target:       'instance'
            } unless instanceProvider?
            NAMED name, (ctx, next) ->
              instance =
                if instanceProvider? then await instanceProvider ctx
                else ctx.instance
              o        = getOptionsFromCtx ctx, httpMethod
              ctx.body = await instance[name].apply instance, o
              pms      = posts.get(name, 'METHOD', httpMethod) ? []
              await next() if pms.length
          ]
          bind.apply null, args
      when httpMethod = schema.statics[name]?.method
        do (name, httpMethod) ->
          bind(name, name, 'STATIC', httpMethod
            NAMED name, (ctx, next) ->
              await model[name].apply model, getOptionsFromCtx ctx, httpMethod
              pms = posts.get(name, 'STATIC', httpMethod) ? []
              await next() if pms.length
          )
      else throw new NodesworkError 'Unable to bind function', name: name


getOptionsFromCtx = (ctx, method) ->
  if method == 'POST' then [ ctx.request.body, ctx.request.query, ctx ]
  else [ ctx.request.query, ctx ]


class Structure

  constructor: (@options, @resolver) ->
    unless (
      _.isObject(@options) and
      not _.isArray(@options) and
      not _.isFunction(@options)
    )
      @options = { all: @options }

  get: (fn, fnType='METHOD', mdType='GET') ->
    @resolver _.filter _.flatten(
      [
        @options.all
        @options["#{fnType.toLowerCase()}s"]
        @options["#{mdType.toLowerCase()}s"]
        @options[fn]
      ]
      true
    )


attachTags = (tags={}) ->
  (fn) ->
    _.extend fn, tags
    fn


module.exports = {
  KoaMiddlewares
  GET:       attachTags method:  'GET'
  POST:      attachTags method:  'POST'
  READONLY
  AUTOGEN
}
