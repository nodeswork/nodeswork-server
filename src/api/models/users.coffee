bcrypt      = require 'bcrypt'
mongoose    = require 'mongoose'

modelUtils  = require './utils'


SALT_WORK_FACTOR = 10


exports.UserSchema = UserSchema = mongoose.Schema {

}, collection: 'users', discriminatorKey: 'userType'

  .plugin modelUtils.TimestampModelPlugin


exports.EmailUserSchema = EmailUserSchema = UserSchema.extend {
  email:
    type:       mongoose.SchemaTypes.Email
    require:    true
    unique:     true
    sparse:     true
    trim:       true

  password:
    type:       String
    required:   true
}


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
