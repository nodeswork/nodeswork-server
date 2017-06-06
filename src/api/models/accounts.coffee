_                       = require 'underscore'
mongoose                = require 'mongoose'
LRU                     = require 'lru-cache'
{OAuth}                 = require 'oauth'

{
  TimestampModelPlugin
  ExcludeFieldsToJSON
}                       = require './utils'
{KoaMiddlewares}        = require './plugins/koa-middlewares'
errors                  = require '../errors'
{NodesworkError}        = require '../errors'

exports.AccountSchema = AccountSchema = mongoose.Schema {

  user:
    type:       mongoose.Schema.ObjectId
    ref:        'User'
    required:   true
    index:      true

  name:
    type:       String
    required:   true
    max:        [140, 'Max length is 140']
    min:        [2, 'Min length is 2']

  category:
    type:       mongoose.Schema.ObjectId
    ref:        'AccountCategory'
    required:   true

  status:
    enum:       ["ACTIVE", "ERROR", "INACTIVE", "UNVERIFIED"]
    type:       String
    default:    "UNVERIFIED"

  errMsg:       String

}, collection: 'accounts', discriminatorKey: 'accountType'

  .plugin TimestampModelPlugin
  .plugin KoaMiddlewares


exports.OAuthAccountSchema = OAuthAccountSchema = AccountSchema.extend {

  oAuthToken:
    type:             String

  oAuthTokenSecret:
    type:             String

  accessToken:
    type:             String

  accessTokenSecret:
    type:             String
}

  .plugin ExcludeFieldsToJSON, fields: ['oAuthTokenSecret', 'accessToken', 'accessTokenSecret']


OAuthAccountSchema.pre 'save', (next) ->
  return next new Error 'Not an oAuth account' unless @category.oAuth?.isOAuth

  unless @oAuthToken?
    # TODO: Cache oAuth instances.
    oAuth = new OAuth(
      @category.oAuth.requestTokenUrl
      @category.oAuth.accessTokenUrl
      @category.oAuth.consumerKey
      @category.oAuth.consumerSecret
      '1.0'
      @category.oAuth.callbackUrl
      'HMAC-SHA1'
    )
    return oAuth.getOAuthRequestToken (
      error, @oAuthToken, @oAuthTokenSecret, results
    ) =>
      if error? then next new Error 'Get OAuth request token failed.'
      else next()
  else next()


OAuthAccountSchema.methods.verifyOAuth = (oAuthVerifier) ->
  oAuth = new OAuth(
    @category.oAuth.requestTokenUrl
    @category.oAuth.accessTokenUrl
    @category.oAuth.consumerKey
    @category.oAuth.consumerSecret
    '1.0'
    @category.oAuth.callbackUrl
    'HMAC-SHA1'
  )
  await new Promise (resolve, reject) =>
    oAuth.getOAuthAccessToken(
      @oAuthToken
      @oAuthTokenSecret
      oAuthVerifier
      (error, @accessToken, @accessTokenSecret) =>
        if error? then reject error else resolve @
    )

  await new Promise (resolve, reject) =>
    oAuth.get(
      @category.oAuth.verifyCredentialUrl
      @accessToken
      @accessTokenSecret
      (error, twitterResponseData, result) =>
        if error? then reject error else resolve @
    )

  @status = 'ACTIVE'
  await @save()


OAuthAccountSchema.methods.reset = () ->
  @oAuthToken         = null
  @oAuthTokenSecret   = null
  @accessToken        = null
  @accessTokenSecret  = null


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
            if FIFA_FUT_LOGIN_CACHE.has @_id.toString() then resolve2 response
            else resolve response
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
