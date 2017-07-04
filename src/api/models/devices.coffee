_                             = require 'underscore'
mongoose                      = require 'mongoose'
randtoken                     = require 'rand-token'
{ NodesworkMongooseSchema
  KoaMiddlewares
  AUTOGEN
  READONLY
  GET }                       = require 'nodeswork-mongoose'

{ ExcludeFieldsToJSON }       = require './plugins/exclude-fields'
{ DataLevel
  pop }                       = require './plugins/data-levels'
{ MINIMAL_DATA_LEVEL }        = require '../constants'


DEVICE_TOKEN_LEN        = 16

class DeviceSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'devices'
    discriminatorKey: 'deviceType'
  }

  @Schema {
    user:
      type:       mongoose.Schema.ObjectId
      ref:        'User'
      required:   true
      index:      true
      api:        READONLY

    name:
      type:       String
      default:    'My Device'

    containerApplet:
      type:       mongoose.Schema.ObjectId
      ref:        'UserApplet'
      default:    null
      api:        AUTOGEN

    deviceToken:
      type:       String
      required:   true
      index:      true
      default:    () -> randtoken.generate DEVICE_TOKEN_LEN
      dateLevel:  'TOKEN'
      api:        AUTOGEN

    platform:
      type:       String
      required:   true
      dataLevel:  'DETAIL'

    osType:
      type:       String
      required:   true
      dataLevel:  'DETAIL'

    release:
      type:       String
      required:   true
      dataLevel:  'DETAIL'

    deviceId:
      type:       String
      required:   true
      dataLevel:  'DETAIL'

    status:
      enum:       [ "ACTIVE", "DEACTIVE", "ERROR" ]
      type:       String
      default:    "ACTIVE"
      api:        AUTOGEN

    dev:
      type:       Boolean
      default:    false
      dataLevel:  'DETAIL'
      api:        AUTOGEN
  }

  @Virtual 'rpc', {
    get: () ->
      { deviceRpcClient } = require '../sockets'
      deviceRpcClient.rpc @_id.toString()
  }

  @Plugin DataLevel, levels: [ 'DETAIL', 'TOKEN' ]
  @Plugin ExcludeFieldsToJSON, fields: ['deviceToken']
  @Plugin KoaMiddlewares

  @Index(
    {
      user:      1
      deviceId:  1
    }, {
      unique: true
    }
  )

  regenerateDeviceToken: () ->
    @deviceToken = randtoken.generate DEVICE_TOKEN_LEN

  expandedInJSON: () ->
    rpc           = @rpc
    appletsStats  = (await rpc?.runningApplets?()) ? []
    appletsStats  = _.sortBy appletsStats, 'name'

    userApplets   = _.filter (
      for stats in appletsStats
        userApplet = await mongoose.models.UserApplet.findOne {
          user:    @user
          applet:  stats._id
        }
          .populate {
            path: 'applet'
            select:
              $level: MINIMAL_DATA_LEVEL
          }
        userApplet = userApplet?.toJSON()
        userApplet?.stats = stats
        userApplet
    )

    _.extend @toJSON(), {
      online:       !!rpc
      userApplets:  userApplets
    }

  # Get user applets which should run on current device.
  applets: GET () ->
    userApplets = await mongoose.models.UserApplet.find {
      user:         @user
      device:       @_id
      status:       "ON"
      isSysApplet:  false
    }
      .populate pop 'applet', MINIMAL_DATA_LEVEL
    _.map userApplets, _.property 'applet'

  current: GET () ->
    await @populate 'containerApplet'
      .execPopulate()
    await @containerApplet
      .populate [
        pop 'user', MINIMAL_DATA_LEVEL
        pop 'applet', MINIMAL_DATA_LEVEL
      ]
      .execPopulate()
    @

  ensureContainerApplet: () ->
    return @ if @containerApplet?

    { SystemApplet
      UserApplet }   = mongoose.models
    applet           = await SystemApplet.containerApplet()
    userApplet       = await UserApplet.create {
      user:          @user
      applet:        applet
      isSysApplet:   true
      status:        'ON'
      device:        @_id
    }

    @containerApplet = userApplet
    @save()


module.exports = {
  DeviceSchema
}
