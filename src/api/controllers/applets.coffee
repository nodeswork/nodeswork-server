_              = require 'underscore'
KoaRouter      = require 'koa-router'

{requireLogin} = require './middlewares'
{UserApplet}   = require '../models'


exports.appletsRouter = appletsRouter = new KoaRouter prefix: '/applets'

appletsRouter.use requireLogin


appletsRouter.get '/', (ctx) ->
  ctx.response.body = await UserApplet.find user: ctx.user
    .populate 'applet'


appletsRouter.get '/:appletId', (ctx) ->
  ctx.response.body = await UserApplet.findOne {
    user: ctx.user, _id: ctx.params.appletId
  }
    .populate 'applet'


appletsRouter.post '/:appletId', (ctx) ->
  userApplet = await UserApplet.findOne {
    user: ctx.user, _id: ctx.params.appletId
  }
    .populate 'applet'

  ctx.response.body = if userApplet?
    _.extend userApplet, _.pick(
      ctx.request.body, 'status', 'inCloud', 'device'
    )
    await userApplet.save()
  else
    applet = await Applet.findById ctx.params.appletId

    userApplet = await UserApplet.create _.extend {}, (
      _.pick(
        ctx.request.body, 'status', 'inCloud', 'device', 'accounts'
      )
    ), {
      user:    ctx.user
      applet:  applet
    }
    await userApplet.populate 'applet'
