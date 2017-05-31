_                 = require 'underscore'
KoaRouter         = require 'koa-router'
momentTimezones   = require 'moment-timezone'

{EmailUser, User} = require '../models'
{requireLogin}    = require './middlewares'


exports.userRouter = userRouter = new KoaRouter prefix: '/users'


userRouter

  .post '/new', User.createMiddleware()


userRouter.post '/login', (ctx) ->
  switch ctx.request.body.userType
    when 'EmailUser'
      user = await EmailUser.findOne email: ctx.request.body.email
      if user? and await user.comparePassword ctx.request.body.password
        ctx.session.userId    = user._id
        ctx.body              = user
      else
        ctx.response.status = 401
    else
      ctx.response.status = 422
      ctx.body = message: 'Unkown or missing userType.'

userRouter.get '/logout', (ctx) ->
  delete ctx.session.userId
  ctx.body = status: 'ok'

userRouter.get '/current', (ctx) ->
  ctx.body = ctx.user

userRouter

  .get  '/timezones', (ctx) ->
    ctx.body = momentTimezones.tz.names()

  .post '/preferences', requireLogin, (ctx) ->
    _.extend ctx.user, _.pick ctx.request.body, [
      'timezone'
    ]
    ctx.body = await ctx.user.save()
