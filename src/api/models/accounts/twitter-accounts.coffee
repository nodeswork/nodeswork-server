{ OAuthAccountSchema } = require './oauth-accounts'
{ KoaMiddlewares }     = require '../plugins/koa-middlewares'
{ GET, POST }          = require '../plugins/koa-middlewares'


class TwitterAccountSchema extends OAuthAccountSchema

  getHomeTimelineStatues: GET (options) ->

  tweet: POST (options) ->

  @Plugin KoaMiddlewares


module.exports = {
  TwitterAccountSchema
}
