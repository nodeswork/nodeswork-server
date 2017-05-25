KoaRouter = require 'koa-router'

{
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
}                      = require './middlewares'
{ Message }            = require '../models'

exports.messageRouter = messageRouter = new KoaRouter prefix: '/messages'


messageRouter

  .use requireLogin

  # TODO: enable pagination.
  .get '/', overrideUserToQuery(), Message.findMiddleware()
