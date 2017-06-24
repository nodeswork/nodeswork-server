mongoose                     = require 'mongoose'

{ NodesworkMongooseSchema }  = require './nodeswork-mongoose-schema'
{ KoaMiddlewares }           = require './plugins/koa-middlewares'
{ ExcludeFieldsToJSON }      = require './plugins/exclude-fields'


class ExecutionSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'executions'
  }

  @Schema {
    applet:
      type:       mongoose.Schema.ObjectId
      ref:        'Applet'
      required:   true
      index:      true

    user:
      type:       mongoose.Schema.ObjectId
      ref:        'User'
      required:   true
      index:      true

    userApplet:
      type:       mongoose.Schema.ObjectId
      ref:        'UserApplet'
      required:   true

    device:
      type:       mongoose.Schema.ObjectId
      ref:        'Device'
      required:   true

    status:
      enum:       [ "SUCCESS", "FAILED", "IN_PROGRESS", "EXPAIRED" ]
      type:       String
      required:   true

    scheduled:
      type:       Boolean

    duration:
      type:       Number

    params:
      type:       mongoose.Schema.Types.Mixed

    result:
      type:       mongoose.Schema.Types.Mixed

    error:
      message:    String
      stack:      String
  }

  @Plugin KoaMiddlewares


module.exports = {
  ExecutionSchema
}
