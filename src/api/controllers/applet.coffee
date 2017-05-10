KoaRouter      = require 'koa-router'

{fetchAccount} = require './middlewares'
{Account}      = require '../models'
{User}         = require '../models'


exports.appletRouter = appletRouter = new KoaRouter prefix: '/applet'


verifyPermissionAndFetchUser = (ctx, next) ->
  # TODO: Verify permission.
  # TODO: Handle errors.
  ctx.user = await User.findById ctx.params.userId
  await next()


appletRouter.post '/register-worker', (ctx) ->


appletRouter.get '/schedules', (ctx) ->


appletRouter.post '/schedules/:scheduleId', (ctx) ->


appletRouter.get '/user/:userId', verifyPermissionAndFetchUser, (ctx) ->
  ctx.response.body = {
    user:     ctx.user
    configs:  {}
  }


appletRouter.get '/user/:userId/accounts', verifyPermissionAndFetchUser, (ctx) ->
  ctx.response.body = await Account.findByUser ctx.user

appletRouter.post '/user/:userId/accounts/:accountId/operate', verifyPermissionAndFetchUser, fetchAccount, (ctx) ->
  ctx.response.body = await ctx.account.operate ctx.request.body
