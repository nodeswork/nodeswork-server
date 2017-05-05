_                       = require 'underscore'
futapi                  = require 'fut-api'
mongoose                = require 'mongoose'
LRU                     = require 'lru-cache'

{TimestampModelPlugin}  = require './utils'
errors                  = require '../errors'

exports.AccountSchema = AccountSchema = mongoose.Schema {

  user:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    require:    true

  status:
    enum:       ["ACTIVE", "ERROR", "INACTIVE"]
    type:       String

  errMsg:       String

}, collection: 'accounts', discriminatorKey: 'accountType'

  .plugin TimestampModelPlugin


AccountSchema.statics.findByUser = (user) ->
  @find user: user


exports.FifaFutAccountSchema = FifaFutAccountSchema = AccountSchema.extend {

  username:
    type:       String
    required:   true

  platform:
    enum:       ["ps3", "ps4", "pc", "x360", "xone"]
    type:       String
    required:   true

  password:
    type:       String
    required:   true

  secret:
    type:       String
    required:   true

  cookieJar:
    type:       String
    default:    null
}


FIFA_FUT_LOGIN_CACHE = LRU {
  max: 100                  # max size
  maxAge: 1000 * 60 * 60    # 60 minutes
}


FifaFutAccountSchema.statics.register = ({user, username, password, secret, platform}) ->
  @create {
    user:      user
    username:  username
    password:  password
    platform:  platform
    secret:    secret
    status:    'INACTIVE'
  }


FifaFutAccountSchema.methods.toJSON = () ->
  return _.omit @toObject(), 'cookieJar'


FifaFutAccountSchema.methods.getApiClient = () ->
  apiClient = new futapi
  if @cookieJar? then apiClient.setCookieJarJSON JSON.parse @cookieJar
  apiClient


FifaFutAccountSchema.methods.saveApiClient = (apiClient) ->
  cookieJar = JSON.stringify apiClient.getCookieJarJSON()
  if cookieJar != @cookieJar
    @cookieJar = cookieJar
    await @save()


FifaFutAccountSchema.methods.authorize = () ->
  new Promise (resolve, reject) =>
    twoFactorPromise = new Promise (resolve2, reject2) =>
      apiClient = @getApiClient()
      apiClient.login(
        @username, @password, @secret, @platform,
        (next) =>
          FIFA_FUT_LOGIN_CACHE.set @_id.toString(), [next, twoFactorPromise]
          console.log 'setting cache', FIFA_FUT_LOGIN_CACHE.keys()
          await @saveApiClient apiClient
          reject errors.FUT_TWO_FACTOR_CODE_REQUIRED
        (err, response) =>
          unless err? then @status = 'ACTIVE'
          await @saveApiClient apiClient
          if err?
            if FIFA_FUT_LOGIN_CACHE.has @_id.toString() then reject2 err
            else reject err
          else
            if FIFA_FUT_LOGIN_CACHE.has @_id.toString() then resolve2 response
            else resolve response
          FIFA_FUT_LOGIN_CACHE.del @_id.toString()
      )

FifaFutAccountSchema.methods.twoFactorAuthorize = ({code}) ->
  console.log 'getting cache', FIFA_FUT_LOGIN_CACHE.keys(), @_id
  console.log FIFA_FUT_LOGIN_CACHE.has @_id.toString()
  unless FIFA_FUT_LOGIN_CACHE.has @_id.toString()
    throw errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND

  [next, twoFactorPromise] = FIFA_FUT_LOGIN_CACHE.get @_id.toString()
  next code
  twoFactorPromise
