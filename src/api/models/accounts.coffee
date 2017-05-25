_                       = require 'underscore'
mongoose                = require 'mongoose'
LRU                     = require 'lru-cache'

{
  TimestampModelPlugin
  ExcludeFieldsToJSON
  KoaMiddlewares
}                       = require './utils'
errors                  = require '../errors'

exports.AccountSchema = AccountSchema = mongoose.Schema {

  user:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

  status:
    enum:       ["ACTIVE", "ERROR", "INACTIVE", "UNVERIFIED"]
    type:       String
    default:    "UNVERIFIED"

  errMsg:       String

}, collection: 'accounts', discriminatorKey: 'accountType'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares


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
  .plugin ExcludeFieldsToJSON, fields: ['cookieJar']


FIFA_FUT_LOGIN_CACHE = LRU {
  max: 100                  # max size
  maxAge: 1000 * 60 * 60    # 60 minutes
}


FifaFutAccountSchema.methods.setApiClient = (@apiClient) ->


FifaFutAccountSchema.methods.authorize = () ->
  new Promise (resolve, reject) =>
    twoFactorPromise = new Promise (resolve2, reject2) =>
      @apiClient.login(
        @username, @password, @secret, @platform,
        (next) =>
          FIFA_FUT_LOGIN_CACHE.set @_id.toString(), [next, twoFactorPromise]
          reject errors.FUT_TWO_FACTOR_CODE_REQUIRED
        (err, response) =>
          unless err? then @status = 'ACTIVE'
          if err?
            if FIFA_FUT_LOGIN_CACHE.has @_id.toString() then reject2 err
            else reject err
          else
            @apiClient.authorized = true
            if FIFA_FUT_LOGIN_CACHE.has @_id.toString() then resolve2 @
            else resolve @
          FIFA_FUT_LOGIN_CACHE.del @_id.toString()
      )

FifaFutAccountSchema.methods.twoFactorAuthorize = ({code}) ->
  unless FIFA_FUT_LOGIN_CACHE.has @_id.toString()
    throw errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND

  [next, twoFactorPromise] = FIFA_FUT_LOGIN_CACHE.get @_id.toString()
  next code
  twoFactorPromise


forCb = (fn) -> new Promise (resolve, reject) -> fn (err, resp) ->
  if err? then reject err else resolve resp


FifaFutAccountSchema.methods.operate = (opts) ->
  unless @apiClient.authorized
    throw errors.FUT_API_CLIENT_IS_NOT_AUTHORIZED

  # TODO: Validate opts for each method.
  switch opts.method
    when 'getCredits', 'getPilesize', 'getTradepile', 'relist', 'getWatchlist'
      await forCb (cb) => @apiClient[opts.method] cb
    when 'search'
      await forCb (cb) => @apiClient.search _.omit(opts, 'method'), cb
    when 'placeBid'
      await forCb (cb) => @apiClient.placeBid opts.tradeId, opts.coins, cb
    when 'listItem'
      await forCb (cb) => @apiClient.listItem(
        opts.itemDataId, opts.startingBid, opts.buyNowPrice, opts.duration, cb
      )
    when 'getStatus'
      await forCb (cb) => @apiClient.getStatus opts.tradeIds, cb
    when 'addToWatchlist', 'removeFromTradepile', 'removeFromWatchlist'
      await forCb (cb) => @apiClient[opts.method] opts.tradeId, cb
    when 'sendToTradepile', 'sendToClub', 'quickSell'
      await forCb (cb) => @apiClient[opts.method] opts.itemDataId, cb
    else
      throw new TypeError "Unkown method."
