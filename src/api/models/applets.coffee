_                       = require 'underscore'
mongoose                = require 'mongoose'


{
  TimestampModelPlugin
  ExcludeFieldsToJSON
  KoaMiddlewares
}                       = require './utils'
errors                  = require '../errors'

exports.AppletSchema = AppletSchema = mongoose.Schema {

  owner:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

  imageUrl:
    type:       String

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
    max:        [1400, 'Short description should be at most 1400 charactors.']

  shortDescription:
    type:       String
    max:        [140, 'Short description should be at most 140 charactors.']

}, collection: 'applets', discriminatorKey: 'appletType'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares


AppletSchema
  .virtual 'requireDevice'
  .get () -> @containers.userDevice and not @containers.cloud


AppletSchema.methods.avaiableTo = (user) ->
  switch @permission
    when 'PRIVATE' then user._id.toString() == @owner.toString()
    when 'PUBLIC' then true
    when 'LIMIT' then _.any @limitedToUsers, (userId) ->
      userId.toString() == user._id.toString()


exports.NpmAppletSchema = NpmAppletSchema = AppletSchema.extend {

  packageName:
    type:       String
    required:   true
    unique:     true

  version:
    type:       String
    required:   true
}
  .plugin ExcludeFieldsToJSON, fields: ['packageName_unique']
