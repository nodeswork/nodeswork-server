{ KoaMiddlewares
  GET
  POST }               = require 'nodeswork-mongoose'

{ OAuthAccountSchema } = require './oauth-accounts'


class TwitterAccountSchema extends OAuthAccountSchema

  getHomeTimelineStatues: GET (options) ->

  tweet: POST (options) ->

  @Plugin KoaMiddlewares


module.exports = {
  TwitterAccountSchema
}
