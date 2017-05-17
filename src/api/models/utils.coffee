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
