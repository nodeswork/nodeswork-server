mongoose                = require 'mongoose'


{TimestampModelPlugin}  = require './utils'
errors                  = require '../errors'

exports.AppletSchema = AppletSchema = mongoose.Schema {

  owner:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

  permission:
    enum:       [ "PRIVATE", "PUBLIC", "LIMIT" ]
    type:       String
    default:    "PRIVATE"

  limitedToUsers: [
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
  ]

  containers:

    userDevice:
      type:     Boolean
      default:  false

    cloud:
      type:     Boolean
      default:  false

  requiredAccounts:  [

    virtualAccountType:
      type:     String
      enum:     [ "FifaFutAccount" ]
      required: true

    number:
      type:     String
      enum:     [ '1', '*', '1+' ]
  ]

  status:
    enum:       ["ACTIVE", "ERROR", "INACTIVE"]
    type:       String

  errMsg:       String

  name:
    type:       String
    required:   true
    unique:     true

  description:
    type:       String

}, collection: 'applets', discriminatorKey: 'appletType'

  .plugin TimestampModelPlugin


exports.NpmAppletSchema = NpmAppletSchema = AppletSchema.extend {

  packageName:
    type:       String
    required:   true

  version:
    type:       String
    required:   true
}
