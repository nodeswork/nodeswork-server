_                             = require 'underscore'
mongoose                      = require 'mongoose'
randtoken                     = require 'rand-token'

{ NodesworkMongooseSchema }   = require './nodeswork-mongoose-schema'
{ KoaMiddlewares }            = require './plugins/koa-middlewares'
{ ExcludeFieldsToJSON }       = require './plugins/exclude-fields'
{ CronValidator }             = require './validators/cron-jobs'

TOKEN_LEN                     = 16


class AppletSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'applets'
    discriminatorKey: 'appletType'
  }

  @Schema {
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

  }

  @Plugin KoaMiddlewares
  @Plugin ExcludeFieldsToJSON, fields: ['prodToken']

  avaiableTo: (user) ->
    switch @permission
      when 'PRIVATE' then user._id.toString() == @owner.toString()
      when 'PUBLIC' then true
      when 'LIMIT' then _.any @limitedToUsers, (userId) ->
        userId.toString() == user._id.toString()

# TODO: Move it to Schema class.
AppletSchema
  .MongooseSchema()
  .virtual 'requireDevice'
  .get () -> @containers.userDevice and not @containers.cloud


class NpmAppletSchema extends AppletSchema

  @Schema {
    packageName:
      type:       String
      required:   true
      unique:     true

    version:
      type:       String
      required:   true
  }
  # TODO: support ExcludeFieldsToJSON with chained fields.
  @Plugin ExcludeFieldsToJSON, fields: ['prodToken', 'packageName_unique']


class SystemAppletSchema extends AppletSchema

  @Schema {
    systemAppletType:
      type:                 String
      enum:                 ['CONTAINER']
  }

  @containerApplet = () ->
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


module.exports = {
  AppletSchema
  NpmAppletSchema
  SystemAppletSchema
}
