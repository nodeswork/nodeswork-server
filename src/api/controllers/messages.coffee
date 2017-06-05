KoaRouter = require 'koa-router'
mongoose  = require 'mongoose'

{
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
  updateState
}                      = require './middlewares'
{ Message }            = require '../models'
{params, rules}        = require './params'

exports.messageRouter = messageRouter = new KoaRouter prefix: '/messages'


messageRouter

  .use requireLogin

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

  .post('/:messageId/view'
    updateState
    overrideUserToQuery 'receiver'
    Message.getMiddleware {
      field: 'messageId'
      target: 'message'
    }
    (ctx) ->
      ctx.message.views++
      await ctx.message.save()
      await ctx.message.constructor.populate ctx.message, {
        path: 'sender'
        select: 'name imageUrl'
      }
  )
