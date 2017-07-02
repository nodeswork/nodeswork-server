mongoose                     = require 'mongoose'

{ NodesworkMongooseSchema }  = require './nodeswork-mongoose-schema'
{ KoaMiddlewares
  AUTOGEN
  READONLY }                 = require './plugins/koa-middlewares'


class ExecutionActionSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'executions.actions'
  }

  @Schema {
    execution:
      type:       mongoose.Schema.ObjectId
      ref:        'Execution'
      required:   true
      api:        READONLY

    account:
      type:       mongoose.Schema.ObjectId
      ref:        'Account'
      required:   true
      api:        READONLY

    user:
      type:       mongoose.Schema.ObjectId
      ref:        'User'
      required:   true
      api:        READONLY

    applet:
      type:       mongoose.Schema.ObjectId
      ref:        'Applet'
      required:   true
      api:        READONLY

    userApplet:
      type:       mongoose.Schema.ObjectId
      ref:        'UserApplet'
      required:   true
      api:        READONLY

    device:
      type:       mongoose.Schema.ObjectId
      ref:        'Device'
      required:   true
      api:        READONLY

    status:
      enum:       [ "SUCCESS", "FAILED", "IN_PROGRESS", "EXPAIRED" ]
      type:       String
      required:   true

    duration:
      type:       Number

    apiLevel:
      enum:       [ 'READ', 'MANAGE', 'WRITE' ]
      type:       String
      required:   true
      api:        AUTOGEN

    params:
      type:       mongoose.Schema.Types.Mixed
      api:        READONLY

    result:
      type:       mongoose.Schema.Types.Mixed

    error:
      message:    String
      stack:      String
  }

  @Plugin KoaMiddlewares

  @Index  {
    execution: 1
    account:   1
  }


module.exports = {
  ExecutionActionSchema
}
