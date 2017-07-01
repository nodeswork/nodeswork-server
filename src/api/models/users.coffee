_                         = require 'underscore'
bcrypt                    = require 'bcrypt'
mongoose                  = require 'mongoose'
momentTimezones           = require 'moment-timezone'

{ ExcludeFieldsToJSON }   = require './plugins/exclude-fields'
{ KoaMiddlewares
  AUTOGEN
  READONLY }              = require './plugins/koa-middlewares'


SALT_WORK_FACTOR = 10


exports.UserSchema = UserSchema = mongoose.Schema {

  attributes:
    type:
      developer:
        type:       Boolean
        default:    false
    api:            AUTOGEN

  status:
    enum:           ['ACTIVE', 'INACTIVE', 'UNVERIFIED']
    type:           String
    default:        'UNVERIFIED'
    api:            AUTOGEN

  timezone:
    type:           String
    default:        'America/Los_Angeles'
    enum:           momentTimezones.tz.names()

}, collection: 'users', discriminatorKey: 'userType'

  .plugin KoaMiddlewares, {
    omits: ['_id', 'createdAt', 'lastUpdateTime']
  }


exports.EmailUserSchema = EmailUserSchema = UserSchema.extend {
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


exports.SystemUserSchema = SystemUserSchema = UserSchema.extend {
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
    }, {
      upsert:         true
    }

  return @_containerAppletOwner
