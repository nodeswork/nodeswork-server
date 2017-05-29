mongoose                = require 'mongoose'

{
  TimestampModelPlugin
  ExcludeFieldsToJSON
  KoaMiddlewares
}                       = require './utils'


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

}, collection: 'applets.executions'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares
