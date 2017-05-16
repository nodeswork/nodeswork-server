mongoose                = require 'mongoose'
randtoken               = require 'rand-token'


{TimestampModelPlugin}  = require './utils'
errors                  = require '../errors'


DEVICE_TOKEN_LEN        = 16

exports.DeviceSchema = DeviceSchema = mongoose.Schema {

  user:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

  deviceToken:
    type:       String
    required:   true
    index:      true
    default:    () -> randtoken.generate DEVICE_TOKEN_LEN

  platform:
    type:       String
    required:   true

  os:
    type:       String
    required:   true

  deviceId:
    type:       String
    required:   true

  status:
    enum:       [ "ONLINE", "OFFLINE", "ERROR" ]
    type:       String
    default:    "OFFLINE"

  errMsg:       String

}, collection: 'devices', discriminatorKey: 'deviceType'

  .plugin TimestampModelPlugin


DeviceSchema.methods.regenerateDeviceToken = () ->
  @deviceToken = randtoken.generate DEVICE_TOKEN_LEN
