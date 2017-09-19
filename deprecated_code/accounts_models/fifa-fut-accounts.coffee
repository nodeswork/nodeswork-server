_                            = require 'underscore'
LRU                          = require 'lru-cache'

{ AccountSchema }            = require './accounts'
{ ExcludeFieldsToJSON }      = require '../plugins/exclude-fields'
errors                       = require '../../errors_old'


class FifaFutAccountSchema extends AccountSchema

  @Schema {
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

  @Plugin ExcludeFieldsToJSON, fields: ['cookieJar']

  setApiClient: (@apiClient) ->

  authorize: () ->
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

  twoFactorAuthorize: ({code}) ->
    unless FIFA_FUT_LOGIN_CACHE.has @_id.toString()
      throw errors.FUT_TWO_FACTOR_FUNCTION_NOT_FOUND

    [next, twoFactorPromise] = FIFA_FUT_LOGIN_CACHE.get @_id.toString()
    next code
    twoFactorPromise

  operate: (opts) ->
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

FIFA_FUT_LOGIN_CACHE = LRU {
  max: 100                  # max size
  maxAge: 1000 * 60 * 60    # 60 minutes
}

forCb = (fn) -> new Promise (resolve, reject) -> fn (err, resp) ->
  if err? then reject err else resolve resp


module.exports = {
  FifaFutAccountSchema
}
