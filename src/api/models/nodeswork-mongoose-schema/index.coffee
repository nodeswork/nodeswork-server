_         = require 'underscore'
mongoose  = require 'mongoose'

RESERVED_CLASS_NAMES = [
  '_Internals', 'Config', 'Schema', 'Plugin', 'Register', 'MongooseSchema'
  'Index', 'length', 'name', 'prototype', 'constructor'
  'Virtual'
]

# Nodeswork base mongoose schema class.
#
# @abstract
class NodesworkMongooseSchema

  # @nodoc
  @SetDefault = () ->
    unless '_Internals' in Object.getOwnPropertyNames @
      @_Internals = {
        schema:          {}
        plugins:         []
        indexes:         []
        virtuals:        []
        config:          {}
        mongooseSchema:  null
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
    @SetDefault()
    _.extend @_Internals.config, options

  # Set schema as the mongoose schema.
  @Schema = (schema) ->
    @SetDefault()
    _.extend @_Internals.schema, schema

  # Add mongoose plugin to the schema.
  @Plugin = (pluginArgs...) ->
    @SetDefault()
    @_Internals.plugins.push pluginArgs

  @Index = (indexArgs...) ->
    @SetDefault()
    @_Internals.indexes.push indexArgs

  @Virtual = (field, {get, set}) ->
    @SetDefault()
    @_Internals.virtuals.push {
      field: field
      get:   get
      set:   set
    }

  # Return the mongoose schema.
  # @nodoc
  @MongooseSchema = () ->
    @SetDefault()
    unless @_Internals.mongooseSchema?
      superSchema = @__proto__._Internals
      mongooseSchema = @_Internals.mongooseSchema =
        if superSchema?.config.discriminatorKey?
          superSchema.nodesworkSchema.MongooseSchema().extend(
            @_Internals.schema
          )
        else
          mongoose.Schema(
            @_Internals.schema, @_Internals.config
          )
      for plugin in @_Internals.plugins
        @_Internals.mongooseSchema.plugin.apply(
          @_Internals.mongooseSchema
          plugin
        )
      for index in @_Internals.indexes
        @_Internals.mongooseSchema.index.apply(
          @_Internals.mongooseSchema
          index
        )
      for {field, get, set} in @_Internals.virtuals
        virtual = @_Internals.mongooseSchema.virtual field
        virtual.get get if get?
        virtual.set set if set?
      for name in Object.getOwnPropertyNames @
        unless name in RESERVED_CLASS_NAMES
          mongooseSchema.statics[name] = @[name]
      for name in Object.getOwnPropertyNames @::
        unless name in RESERVED_CLASS_NAMES
          mongooseSchema.methods[name] = @::[name]
    @_Internals.mongooseSchema

  @Register = (mongoose, modelName) ->
    @SetDefault()
    mongoose.model modelName, @MongooseSchema()


module.exports = {
  NodesworkMongooseSchema
}
