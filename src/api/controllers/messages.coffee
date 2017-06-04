KoaRouter = require 'koa-router'
mongoose  = require 'mongoose'

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
  .get('/'
    overrideUserToQuery('receiver')
    Message.findMiddleware {
      target:      'messages'
      sort:        '-createdAt'
      pagination:  20
    }
    (ctx) ->
      for message in ctx.messages
        await mongoose.models[message.messageType].populate message, {
          path: 'sender'
          select: 'name imageUrl'
        }
  )
