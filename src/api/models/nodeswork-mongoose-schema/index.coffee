_         = require 'underscore'
mongoose  = require 'mongoose'

{ AUTOGEN }  = require '../plugins/koa-middlewares'

RESERVED_NAMES = [
  '_mongooseOptions', 'length', 'name', 'prototype', 'constructor'
]

PointSchema = mongoose.Schema {
  type:
    type:       String
    enum:       ['Point']
    default:    'Point'
  coordinates:
    type:       [Number]
    default:    [0, 0]
}

# Nodeswork base mongoose schema class.
#
# @abstract
class NodesworkMongooseSchema

  # @nodoc
  @_init = () ->
    return if '_mongooseOptions' in Object.getOwnPropertyNames @
    @_mongooseOptions = {
      schema:          {}
      plugins:         []
      indexes:         []
      virtuals:        []
      pres:            []
      posts:           []
      config:          {}
      mongooseSchema:  null
      fullOptions:     null
      nodesworkSchema: @
    }

  # Set configurations for current schema
  #
  # @param {Object} options the options passed to mongoose to create the schema.
  #
  # @option options {String} collection specifies the collection for the current
  #   model.
  #
  # @option options {String} discriminatorKey specifies the discriminator key
  #   for model extension.
  @Config = (options) ->
    @_init()
    _.extend @_mongooseOptions.config, options

  # Set schema as the mongoose schema.
  @Schema = (schema) ->
    @_init()
    _.extend @_mongooseOptions.schema, schema

  # Add mongoose plugin to the schema.
  @Plugin = (pluginArgs...) ->
    @_init()
    @_mongooseOptions.plugins.push pluginArgs

  @Index = (indexArgs...) ->
    @_init()
    @_mongooseOptions.indexes.push indexArgs

  @Virtual = (field, {get, set}) ->
    @_init()
    @_mongooseOptions.virtuals.push {
      field: field
      get:   get
      set:   set
    }

  @ExtendedKey = () ->
    @__proto__?.MongooseOptions?()?.config.discriminatorKey

  @MongooseOptions = () ->
    @_init()
    return @_mongooseOptions.fullOptions if @_mongooseOptions.fullOptions

    superOptions = @__proto__?.MongooseOptions?() ? {}

    staticNames = _.difference Object.getOwnPropertyNames(@), RESERVED_NAMES
    statics     = _.object _.map staticNames, (name) => [name, @[name]]
    methodNames = _.difference Object.getOwnPropertyNames(@::), RESERVED_NAMES
    methods     = _.object _.map methodNames, (name) => [name, @::[name]]
    addIndexes  = []
    addPres     = []

    currentSchema =
      if (extendedKey = @ExtendedKey())?
        uniqueFields  = []
        currentSchema = _.extend {}, @_mongooseOptions.schema

        for name, opt of currentSchema
          if opt.unique
            opt.unique = false
            uniqueFields.push name

        for field in uniqueFields
          currentSchema["#{field}_unique"] = {
            type:     PointSchema
            api:      AUTOGEN
            default:  PointSchema
          }
          addIndexes.push [
            {
              "#{extendedKey}":   1
              "#{field}":         1
              "#{field}_unique":  '2dsphere'
            }
            unique:               true
          ]

        currentSchema[extendedKey] = type: String

        addPres.push [
          'save'
          (next) ->
            @[extendedKey] ?= @constructor.modelName
            next()
        ]

        patchDiscriminatorKey = () ->
          @_conditions[extendedKey] = @model.modelName

        addPres.push(
          ['find', patchDiscriminatorKey]
          ['findOne', patchDiscriminatorKey]
          ['count', patchDiscriminatorKey]
          ['findOneAndUpdate', patchDiscriminatorKey]
          ['findOneAndRemove', patchDiscriminatorKey]
          ['update', patchDiscriminatorKey]
        )

        currentSchema
      else @_mongooseOptions.schema

    @_mongooseOptions.fullOptions = {
      schema:    _.extend {}, superOptions?.schema, currentSchema
      plugins:   _.union superOptions?.plugins, @_mongooseOptions.plugins
      indexes:   _.union(
        superOptions?.indexes, @_mongooseOptions.indexes, addIndexes
      )
      virtuals:  _.union superOptions?.virtuals, @_mongooseOptions.virtuals
      pres:      _.union superOptions?.pres, @_mongooseOptions.pres, addPres
      posts:     _.union superOptions?.posts, @_mongooseOptions.posts
      config:    _.extend {}, superOptions?.config, @_mongooseOptions.config
      statics:   _.extend {}, superOptions?.statics, statics
      methods:   _.extend {}, superOptions?.methods, methods
    }

    @_mongooseOptions.fullOptions

  # Return the mongoose schema.
  # @nodoc
  @MongooseSchema = () ->
    @_init()
    return @_mongooseOptions.mongooseSchema if @_mongooseOptions.mongooseSchema?

    mongooseOptions = @MongooseOptions()
    mongooseSchema  = @_mongooseOptions.mongooseSchema = mongoose.Schema(
      mongooseOptions.schema, mongooseOptions.config
    )

    for plugin in mongooseOptions.plugins
      mongooseSchema.plugin.apply mongooseSchema, plugin

    for index in mongooseOptions.indexes
      mongooseSchema.index.apply mongooseSchema, index

    for {field, get, set} in mongooseOptions.virtuals
      virtual = mongooseSchema.virtual field
      virtual.get get if get?
      virtual.set set if set?

    for [name, fn] in mongooseOptions.pres
      mongooseSchema.pre name, fn

    for [name, fn] in mongooseOptions.posts
      mongooseSchema.post name, fn

    _.extend mongooseSchema.statics, mongooseOptions.statics
    _.extend mongooseSchema.methods, mongooseOptions.methods

    mongooseSchema

  @Register = (mongoose, modelName) ->
    @_init()
    mongoose.model modelName, @MongooseSchema()

  @Pre = (name, fn) ->
    @_init()
    @_mongooseOptions.pres.push [name, fn]

  @Post = (name, fn) ->
    @_init()
    @_mongooseOptions.posts.push [name, fn]


# Extend static methods into RESERVED_NAMES.
Array::push.apply(
  RESERVED_NAMES
  Object.getOwnPropertyNames NodesworkMongooseSchema
)

do ->
  Model = mongoose.Model
  _init = Model::init

  Model::init = (doc, query, fn) ->
    discriminatorKey = @schema.options.discriminatorKey

    if (type = doc[discriminatorKey])? and (model = @db.model type)?
      @schema    = model.schema
      @__proto__ = model::
      _init.call @, doc, query
      fn? null
      return @

    _init.call @, doc, query, fn


module.exports = {
  NodesworkMongooseSchema
}
