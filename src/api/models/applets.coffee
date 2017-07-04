_                             = require 'underscore'
mongoose                      = require 'mongoose'
randtoken                     = require 'rand-token'
{ NodesworkMongooseSchema
  KoaMiddlewares }            = require 'nodeswork-mongoose'

{ ExcludeFieldsToJSON }       = require './plugins/exclude-fields'
{ DataLevel }                 = require './plugins/data-levels'
{ CronValidator }             = require './validators/cron-jobs'

TOKEN_LEN                     = 16


class AppletSchema extends NodesworkMongooseSchema

  @Config {
    collection: 'applets'
    discriminatorKey: 'appletType'
  }

  @Schema {
    owner:
      type:               mongoose.Schema.ObjectId
      ref:                'User'
      required:           true
      index:              true

    devToken:
      type:               String
      default:            () -> randtoken.generate TOKEN_LEN
      dataLevel:          'TOKEN'

    prodToken:
      type:               String
      default:            () -> randtoken.generate TOKEN_LEN
      dataLevel:          'TOKEN'

    imageUrl:
      type:               String
      default:            'https://cdn1.iconfinder.com/data/icons/dotted-charts/512/links_diagram-256.png'

    permission:
      enum:               [ "PRIVATE", "PUBLIC", "LIMIT" ]
      type:               String
      default:            "PRIVATE"
      dataLevel:          'DETAIL'

    limitedToUsers:
      type:               [
        type:             mongoose.Schema.ObjectId
        ref:              'User'
        required:         true
      ]
      dataLevel:          'DETAIL'

    containers:
      type:               ContainerSchema = mongoose.Schema {
        userDevice:
          type:           Boolean
          default:        false

        cloud:
          type:           Boolean
          default:        false
      }, noGlobalPlugins: true, _id: false
      default:            ContainerSchema
      dataLevel:          'DETAIL'

    requiredAccounts:
      type:               [
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
      dataLevel:          'DETAIL'

    status:
      enum:               ["ACTIVE", "ERROR", "INACTIVE"]
      type:               String

    name:
      type:               String
      required:           true
      unique:             true

    description:
      type:               String
      max:                [1400, 'Short description should be at most 1400 charactors.']
      dataLevel:          'DETAIL'

    shortDescription:
      type:               String
      max:                [140, 'Short description should be at most 140 charactors.']
      dataLevel:          'DETAIL'

    defaultScheduler:

      type:
        cron:
          type:           String
          validate:       CronValidator

      dataLevel:          'DETAIL'
  }

  @Plugin DataLevel, levels: [ 'DETAIL', 'TOKEN' ]
  @Plugin KoaMiddlewares
  @Plugin ExcludeFieldsToJSON, fields: ['prodToken']

  @Virtual 'requireDevice', {
    get: () -> @containers.userDevice and not @containers.cloud
  }

  avaiableTo: (user) ->
    switch @permission
      when 'PRIVATE' then user._id.toString() == @owner.toString()
      when 'PUBLIC' then true
      when 'LIMIT' then _.any @limitedToUsers, (userId) ->
        userId.toString() == user._id.toString()


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
  @Plugin DataLevel


class SystemAppletSchema extends AppletSchema

  @Schema {
    systemAppletType:
      type:                 String
      enum:                 ['CONTAINER']
  }

  @Plugin DataLevel

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
