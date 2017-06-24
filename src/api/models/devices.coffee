_                             = require 'underscore'
mongoose                      = require 'mongoose'
randtoken                     = require 'rand-token'


{ NodesworkMongooseSchema }   = require './nodeswork-mongoose-schema'
{ KoaMiddlewares
  GET }                       = require './plugins/koa-middlewares'
{ ExcludeFieldsToJSON }       = require './plugins/exclude-fields'
{ DataLevel }                 = require './plugins/data-levels'
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

    name:
      type:       String
      default:    'My Device'

    deviceToken:
      type:       String
      required:   true
      index:      true
      default:    () -> randtoken.generate DEVICE_TOKEN_LEN
      dateLevel:  'TOKEN'

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

    dev:
      type:       Boolean
      default:    false
      dataLevel:  'DETAIL'
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

  # Get applets which should run on current device.
  applets: GET () ->
    userApplets = await mongoose.models.UserApplet.find {
      user:    @user
      device:  @_id
      status:  "ON"
    }
      .populate [
        {
          path: 'applet'
          select:
            $level: MINIMAL_DATA_LEVEL
        }
      ]


module.exports = {
  DeviceSchema
}
