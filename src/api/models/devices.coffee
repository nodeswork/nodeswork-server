_                             = require 'underscore'
mongoose                      = require 'mongoose'
randtoken                     = require 'rand-token'


{ NodesworkMongooseSchema }   = require './nodeswork-mongoose-schema'
{ KoaMiddlewares }            = require './plugins/koa-middlewares'
{ ExcludeFieldsToJSON }       = require './plugins/exclude-fields'


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

    platform:
      type:       String
      required:   true

    osType:
      type:       String
      required:   true

    release:
      type:       String
      required:   true

    deviceId:
      type:       String
      required:   true

    status:
      enum:       [ "ACTIVE", "DEACTIVE", "ERROR" ]
      type:       String
      default:    "ACTIVE"

    dev:
      type:       Boolean
      default:    false

    errMsg:       String

  }

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
