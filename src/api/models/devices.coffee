_                             = require 'underscore'
mongoose                      = require 'mongoose'
randtoken                     = require 'rand-token'


{ NodesworkMongooseSchema }   = require './nodeswork-mongoose-schema'
{ KoaMiddlewares }            = require './plugins/koa-middlewares'
{ ExcludeFieldsToJSON }       = require './plugins/exclude-fields'
{ DataLevel }                 = require './plugins/data-levels'


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
      { deviceRpcClient }         = require '../sockets'
      deviceRpcClient.rpc @deviceToken
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

module.exports = {
  DeviceSchema
}
