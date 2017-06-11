mongoose                     = require 'mongoose'

{ NodesworkMongooseSchema }  = require './nodeswork-mongoose-schema'
{ KoaMiddlewares }           = require './plugins/koa-middlewares'
{ ExcludeFieldsToJSON }      = require './plugins/exclude-fields'


class AppletExecutionSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'applets.executions'
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

    status:
      enum:       ["SUCCESS", "FAILED", "IN_PROGRESS"]
      type:       String
      required:   true

    trigger:
      enum:       ["MANUAL", "SCHEDULER"]
      type:       String

    device:
      type:       mongoose.Schema.ObjectId
      ref:        'Device'

    errMsg:       String

    duration:
      type:       Number

    params:
      type:       mongoose.Schema.Types.Mixed

    error:
      message:    String
      stack:      String
  }

  @Plugin KoaMiddlewares


module.exports = {
  AppletExecutionSchema
}
