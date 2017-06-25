{ READONLY } = require './koa-middlewares'

TimestampModelPlugin = (schema, {
  createdAtIndex,
  lastUpdateTimeIndex
} = {}) ->
  createdAtIndex      ?= true
  lastUpdateTimeIndex ?= true

  schema.add {
    createdAt:
      type:          Date
      default:       Date.now
      index:         createdAtIndex
      api:           READONLY
    lastUpdateTime:
      type:          Date
      index:         lastUpdateTimeIndex
      api:           READONLY
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


module.exports = {
  TimestampModelPlugin
}
