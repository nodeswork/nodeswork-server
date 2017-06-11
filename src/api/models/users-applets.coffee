mongoose                      = require 'mongoose'
momentTimezones               = require 'moment-timezone'


{ NodesworkMongooseSchema }   = require './nodeswork-mongoose-schema'
{ KoaMiddlewares }            = require './plugins/koa-middlewares'
{ CronValidator }             = require './validators/cron-jobs'

class UserAppletSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'users.applets'
    discriminatorKey: 'userAppletType'
  }

  @Schema {
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
        type:         String
        validate:     CronValidator

      timezone:
        type:         String
        enum:         ['default'].concat(momentTimezones.tz.names())
        default:      'default'

  }

  @Plugin KoaMiddlewares

  @Index(
    {
      user:    1
      applet:  1
    }, {
      unique:  true
    }
  )


  validateStatus: (prefetch={}) ->


module.exports = {
  UserAppletSchema
}
