mongoose                = require 'mongoose'

{
  TimestampModelPlugin
  ExcludeFieldsToJSON
}                       = require './utils'
{KoaMiddlewares}        = require './plugins/koa-middlewares'


exports.AppletExecutionSchema = AppletExecutionSchema = mongoose.Schema {

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

}, collection: 'applets.executions'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares, {
    omits: ['_id', 'createdAt', 'lastUpdateTime']
  }
