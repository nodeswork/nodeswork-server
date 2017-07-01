_                         = require 'underscore'
bcrypt                    = require 'bcrypt'
mongoose                  = require 'mongoose'
momentTimezones           = require 'moment-timezone'

{ ExcludeFieldsToJSON }   = require './plugins/exclude-fields'
{ KoaMiddlewares
  AUTOGEN
  READONLY }              = require './plugins/koa-middlewares'
{ USER_STATUS }           = require '../constants'


SALT_WORK_FACTOR = 10


AttributesSchema = new mongoose.Schema {
  developer:
    type:       Boolean
    default:    true
}

# console.log AttributesSchema

UserSchema = mongoose.Schema {

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

}, collection: 'users', discriminatorKey: 'userType'

  .plugin KoaMiddlewares, {
    omits: ['_id', 'createdAt', 'lastUpdateTime']
  }


EmailUserSchema = UserSchema.extend {
  email:
    type:       mongoose.SchemaTypes.Email
    required:   true
    unique:     true
    trim:       true
    api:        READONLY

  password:
    type:       String
    required:   true
    min:        [6,  'Password should be at least 6 charactors.']
    max:        [80, 'Password should be at most 80 charactors.']
}

  .plugin ExcludeFieldsToJSON, fields: ['password', 'email_unique']


EmailUserSchema.statics.register = ({email, password}) ->
  await @create {
    email: email
    password: password
  }

EmailUserSchema.pre 'save', (next) ->
  unless @isModified 'password' then return next()

  (do =>
    salt = await bcrypt.genSalt SALT_WORK_FACTOR
    @password = await bcrypt.hash @password, salt
  )
    .then -> next()
    .catch next

EmailUserSchema.methods.comparePassword = (password) ->
  bcrypt.compare password, @password


SystemUserSchema = UserSchema.extend {
  systemUserType:
    type:       String
    enum:       ['CONTAINER_APPLET_OWNER']
}

SystemUserSchema.statics.containerAppletOwner = () ->
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
