{ OAuth }         = require 'oauth'

{ AccountSchema } = require './accounts'

class OAuthAccountSchema extends AccountSchema

  @Schema {
    oAuthToken:
      type:             String
      dataLevel:        'TOKEN'

    oAuthTokenSecret:
      type:             String
      dataLevel:        'TOKEN'

    accessToken:
      type:             String
      dataLevel:        'DETAIL'

    accessTokenSecret:
      type:             String
      dataLevel:        'TOKEN'
  }

  @Plugin DataLevel, levels: [ 'DETAIL', 'TOKEN' ]
  @Plugin ExcludeFieldsToJSON, {
    fields: [ 'oAuthTokenSecret', 'accessToken', 'accessTokenSecret' ]
  }

  verifyOAuth: (oAuthVerifier) ->
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

  reset: () ->
    @oAuthToken         = null
    @oAuthTokenSecret   = null
    @accessToken        = null
    @accessTokenSecret  = null


OAuthAccountSchema.MongooseSchema().pre 'save', (next) ->
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


module.exports = {
  OAuthAccountSchema
}
