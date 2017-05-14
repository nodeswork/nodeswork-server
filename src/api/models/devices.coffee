mongoose                = require 'mongoose'


{TimestampModelPlugin}  = require './utils'
errors                  = require '../errors'

exports.DeviceSchema = DeviceSchema = mongoose.Schema {

  user:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

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
