_                       = require 'underscore'
mongoose                = require 'mongoose'
randtoken               = require 'rand-token'


{
  CronValidator
  TimestampModelPlugin
  ExcludeFieldsToJSON
  KoaMiddlewares
}                       = require './utils'
errors                  = require '../errors'

TOKEN_LEN               = 16

exports.AppletSchema = AppletSchema = mongoose.Schema {

  owner:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

  devToken:
    type:       String
    default:    () -> randtoken.generate TOKEN_LEN

  prodToken:
    type:       String
    default:    () -> randtoken.generate TOKEN_LEN

  imageUrl:
    type:       String
    default:    'https://cdn1.iconfinder.com/data/icons/dotted-charts/512/links_diagram-256.png'

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

    accountCategory:
      type:           mongoose.Schema.ObjectId
      ref:            'AccountCategory'
      required:       true

    optional:
      type:           Boolean
      default:        false

    multiple:
      type:           Boolean
      default:        false

    permission:
      type:           String
      enum:           ['READ', 'MANAGE', 'WRITE']

    usage:
      type:           String
      max:            [140, "Usage can't exceed 140 charactors."]
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

  defaultScheduler:

    cron:
      type:     String
      validate: CronValidator

}, collection: 'applets', discriminatorKey: 'appletType'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares
  .plugin ExcludeFieldsToJSON, fields: ['prodToken']


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
  # TODO: support ExcludeFieldsToJSON with chained fields.
  .plugin ExcludeFieldsToJSON, fields: ['prodToken', 'packageName_unique']


exports.SystemAppletSchema = SystemAppletSchema = AppletSchema.extend {

  systemAppletType:
    type:                 String
    enum:                 ['CONTAINER']
}

SystemAppletSchema.statics.containerApplet = () ->
  unless @_containerApplet?
    @_containerApplet = await @findOne systemAppletType: 'CONTAINER'

  unless @_containerApplet?
    owner = await @db.model('SystemUser').containerAppletOwner()
    @_containerApplet = await @create {
      owner:            owner
      name:             'System Container Applet'
      systemAppletType: 'CONTAINER'
    }
  return @_containerApplet
