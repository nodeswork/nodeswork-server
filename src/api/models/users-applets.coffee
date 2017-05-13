mongoose                = require 'mongoose'


{TimestampModelPlugin}  = require './utils'
errors                  = require '../errors'

exports.UserAppletSchema = UserAppletSchema = mongoose.Schema {

  user:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    require:    true
    index:      true

  applet:
    type:       mongoose.Schema.ObjectId
    ref:        'Applet'
    require:    true

  status:
    enum:       ["ON", "OFF", "INSUFFICIENT_ACCOUNT"]
    type:       String

  errMsg:       String

  inCloud:
    type:       Boolean
    default:    false

  device:
    type:       mongoose.Schema.ObjectId
    ref:        'Device'

}, collection: 'users.applets', discriminatorKey: 'appletType'

  .plugin TimestampModelPlugin
