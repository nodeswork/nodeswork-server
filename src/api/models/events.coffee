mongoose                    = require 'mongoose'

{ NodesworkMongooseSchema } = require './nodeswork-mongoose-schema'
{ KoaMiddlewares }          = require './plugins/koa-middlewares'


# Schema of events.
class EventSchema extends NodesworkMongooseSchema

  @Config {
    collection:        'events'
    discriminatorKey:  'eventType'
  }

  @Schema {}

  @Plugin KoaMiddlewares


# Schema of container execution event.
class ContainerExecutionEventSchema extends EventSchema

  @Schema {

    execution:
      type:           mongoose.Schema.ObjectId
      ref:            'AppletExecution'
      required:       true

    executionMethod:
      type:           String
      enum:           ['ERROR', 'SUCCESS']

    error:
      message:        String
      stack:          String
  }


module.exports = {
  EventSchema
  ContainerExecutionEventSchema
}
