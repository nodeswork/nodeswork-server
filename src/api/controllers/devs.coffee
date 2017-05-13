_                       = require 'underscore'
KoaRouter               = require 'koa-router'

{requireLogin}          = require './middlewares'
{Applet, NpmApplet}     = require '../models'


exports.devRouter = devRouter = new KoaRouter prefix: '/dev'

devRouter.use requireLogin


devRouter.post '/applets', (ctx) ->

  switch ctx.request.body.appletType
    when 'NpmApplet'
      ctx.body = await NpmApplet.create _.extend {}, ctx.request.body, {
        owner:    ctx.user
      }
    else
      ctx.response.status = 422
      ctx.body = message: 'Unkown or missing appletType.'


devRouter.post '/applets/:appletId', (ctx) ->
  applet = await Applet.findOne _id: ctx.params.appletId, owner: ctx.user
  _.extend applet, _.omit(
    ctx.request.body, '_id', 'createdAt', 'lastUpdateTime', 'packageName_unique'
  )
  ctx.body = await applet.save()


devRouter.get '/applets', (ctx) ->
  ctx.body = await Applet.find owner: ctx.user


devRouter.get '/applets/:appletId', (ctx) ->
  ctx.body = await Applet.findOne _id: ctx.params.appletId, owner: ctx.user
