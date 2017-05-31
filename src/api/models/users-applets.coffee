mongoose                = require 'mongoose'
momentTimezones         = require 'moment-timezone'


{
  KoaMiddlewares
  TimestampModelPlugin
}                       = require './utils'
errors                  = require '../errors'

exports.UserAppletSchema = UserAppletSchema = mongoose.Schema {

  user:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

  applet:
    type:       mongoose.Schema.ObjectId
    ref:        'Applet'
    required:   true

  status:
    enum:       ["ON", "OFF", "INSUFFICIENT_ACCOUNT"]
    type:       String

  errMsg:       String

  cloud:
    mode:
      enum:     ["NO", "SHARED", "PRIVATE"]
      type:     String
      default:  "NO"

  device:
    type:       mongoose.Schema.ObjectId
    ref:        'Device'

  accounts:     [
    type:       mongoose.Schema.ObjectId
    ref:        'Account'
  ]

  lastExecution:
    type:       Date

  scheduler:

    cron:
      type:     String

    timezone:
      type:     String
      enum:     ['default'].concat(momentTimezones.tz.names())
      default:  'default'

}, collection: 'users.applets', discriminatorKey: 'appletType'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares


UserAppletSchema.methods.validateStatus = (prefetch={}) ->


UserAppletSchema.index {
  user:    1
  applet:  1
}, {
  unique:  true
}
