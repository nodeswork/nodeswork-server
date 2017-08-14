mongoose                     = require 'mongoose'

{ NodesworkMongooseSchema
  KoaMiddlewares
  READONLY }                 = require '@nodeswork/mongoose'


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
      api:        READONLY

    user:
      type:       mongoose.Schema.ObjectId
      ref:        'User'
      required:   true
      index:      true
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

    purpose:
      type:       String
      required:   true
      api:        READONLY

    status:
      enum:       [ "SUCCESS", "FAILED", "IN_PROGRESS", "EXPAIRED" ]
      type:       String
      required:   true

    scheduled:
      type:       Boolean
      api:        READONLY

    duration:
      type:       Number

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


module.exports = {
  ExecutionSchema
}
