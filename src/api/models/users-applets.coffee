_                             = require 'underscore'
mongoose                      = require 'mongoose'
momentTimezones               = require 'moment-timezone'

{ NodesworkError }            = require 'nodeswork-utils'


{ NodesworkMongooseSchema }   = require './nodeswork-mongoose-schema'
{ KoaMiddlewares
  POST }                      = require './plugins/koa-middlewares'
{ pop }                       = require './plugins/data-levels'
{ CronValidator }             = require './validators/cron-jobs'
{ MINIMAL_DATA_LEVEL }        = require '../constants'
{ ObjectIdEquals }            = require '../../utils'


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

  @Virtual 'stats', {
    get: () ->
      device =
        if @populated 'device' then @device
        else await mongoose.models.Device.findById @device

      return null unless (rpc = device.rpc)?

      # TODO: figure out if can reuse the populated one
      applet = await mongoose.models.Applet.findById @applet

      await rpc.appletStats applet: {
        _id: applet._id.toString()
        version: applet.version
      }
  }

  validateStatus: (prefetch={}) ->

  run: POST (options) ->
    # TODO: figure out if can reuse the populated one
    device = await mongoose.models.Device.findOne {
      _id: @device
    }
    unless device?
      throw new NodesworkError 'Applet has not been configed for any device.'
    unless rpc = device.rpc
      throw new NodesworkError "Applet's device is not running."

    await rpc.process {
      applet:  @applet
      user:    mongoose.Types.ObjectId @user
    }
    @lastExecution = new Date
    await @save()
    @

  restart: POST (options) ->
    # TODO: figure out if can reuse the populated one
    device = await mongoose.models.Device.findOne {
      _id: @device
    }
    unless device?
      throw new NodesworkError 'Applet has not been configed for any device.'
    unless rpc = device.rpc
      throw new NodesworkError "Applet's device is not running."

    applet = await mongoose.models.Applet.findById @applet
    unless applet?
      throw new NodesworkError 'Applet is not available.'

    await rpc.restart {
      applet:
        _id: applet._id.toString()
        version: applet.version
    }
    @

  execute: POST (body={}, query={}, ctx={}) ->
    { device } = ctx
    { scheduled = false } = query

    unless device?._id.equals @device
      throw new NodesworkError 'Applet is not running on this device.'

    await @populate(pop 'accounts', MINIMAL_DATA_LEVEL).execPopulate()

    await mongoose.models.Execution.create {
      applet:      @applet
      user:        @user
      userApplet:  @
      device:      @device
      status:      'IN_PROGRESS'
      scheduled:   scheduled
      params:      body
    }

  expandedInJSON: () ->
    _.extend(
      @toJSON()
      stats: await @stats
    )

  hasAccount: (account) ->
    _.find @accounts, (act) -> ObjectIdEquals act, account


module.exports = {
  UserAppletSchema
}
