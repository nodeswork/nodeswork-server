mongoose                     = require 'mongoose'
{ NodesworkMongooseSchema
  KoaMiddlewares
  AUTOGEN
  READONLY }                 = require 'nodeswork-mongoose'


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
      default:    'IN_PROGRESS'

    duration:
      type:       Number

    apiLevel:
      enum:       [ 'READ', 'MANAGE', 'WRITE' ]
      type:       String
      required:   true
      api:        AUTOGEN

    # TODO: Validate action exists.
    action:
      type:       String
      required:   true
      api:        READONLY

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
