_                            = require 'underscore'
bcrypt                       = require 'bcrypt'
mongoose                     = require 'mongoose'
momentTimezones              = require 'moment-timezone'
{ KoaMiddlewares
  AUTOGEN
  READONLY
  NodesworkMongooseSchema }  = require 'nodeswork-mongoose'

{ ExcludeFieldsToJSON }      = require './plugins/exclude-fields'
{ DataLevel
  pop }                      = require './plugins/data-levels'
{ USER_STATUS }              = require '../constants'


SALT_WORK_FACTOR = 10


AttributesSchema = new mongoose.Schema {
  developer:
    type:       Boolean
    default:    false
}, noGlobalPlugins: true, _id: false


class UserSchema extends NodesworkMongooseSchema

  @Config {
    collection:        'users'
    discriminatorKey:  'userType'
  }

  @Schema {

    attributes:
      type:           AttributesSchema
      api:            AUTOGEN
      default:        {}

    status:
      enum:           _.values USER_STATUS
      type:           String
      default:        USER_STATUS.UNVERIFIED
      api:            AUTOGEN

    timezone:
      type:           String
      default:        'America/Los_Angeles'
      enum:           momentTimezones.tz.names()
  }

  @Plugin DataLevel, levels: [ 'DETAIL', 'CREDENTIAL' ]


class EmailUserSchema extends UserSchema

  @Schema {

    email:
      type:       mongoose.SchemaTypes.Email
      required:   true
      unique:     true
      trim:       true
      api:        READONLY
      dataLevel:  'DETAIL'

    password:
      type:       String
      required:   true
      min:        [6,  'Password should be at least 6 charactors.']
      max:        [80, 'Password should be at most 80 charactors.']
      dataLevel:  'CREDENTIAL'
  }

  @Plugin ExcludeFieldsToJSON, fields: ['password', 'email_unique']


  @register: ({email, password}) ->
    await @create {
      email: email
      password: password
    }

  @Pre 'save', (next) ->
    unless @isModified 'password' then return next()

    (do =>
      salt = await bcrypt.genSalt SALT_WORK_FACTOR
      @password = await bcrypt.hash @password, salt
    )
      .then -> next()
      .catch next

  comparePassword: (password) ->
    bcrypt.compare password, @password


class SystemUserSchema extends UserSchema

  @Schema {
    systemUserType:
      type:       String
      enum:       ['CONTAINER_APPLET_OWNER']
  }

  @containerAppletOwner: () ->
    unless @_containerAppletOwner?
      @_containerAppletOwner = await @findOneAndUpdate {
        systemUserType: 'CONTAINER_APPLET_OWNER'
      }, {
        systemUserType: 'CONTAINER_APPLET_OWNER'
        status:         'ACTIVE'
        attributes:     {}
      }, {
        upsert:         true
      }

    return @_containerAppletOwner


module.exports = {
  UserSchema
  EmailUserSchema
  SystemUserSchema
  USER_STATUS
}
