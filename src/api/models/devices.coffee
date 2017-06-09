_                       = require 'underscore'
mongoose                = require 'mongoose'
randtoken               = require 'rand-token'


{
  ExcludeFieldsToJSON
  TimestampModelPlugin
}                       = require './utils'
{ KoaMiddlewares }      = require './plugins/koa-middlewares'
errors                  = require '../errors'


DEVICE_TOKEN_LEN        = 16

exports.DeviceSchema = DeviceSchema = mongoose.Schema {

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

}, collection: 'devices', discriminatorKey: 'deviceType'

  .plugin TimestampModelPlugin
  .plugin ExcludeFieldsToJSON, fields: ['deviceToken']
  .plugin KoaMiddlewares, {
    omits: ['_id', 'createdAt', 'lastUpdateTime', 'user', 'status']
  }


DeviceSchema.index {
  user:      1
  deviceId:  1
}, {
  unique: true
}

DeviceSchema.methods.regenerateDeviceToken = () ->
  @deviceToken = randtoken.generate DEVICE_TOKEN_LEN
