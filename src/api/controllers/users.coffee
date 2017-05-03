_                = require 'underscore'
KoaRouter        = require 'koa-router'

{EmailUser}      = require '../models'


exports.userRouter = userRouter = new KoaRouter prefix: '/users'


userRouter.post '/new', (ctx) ->
  switch ctx.request.body.userType
    when 'EmailUser'
      console.log 'request body', ctx.request.body
      user = await EmailUser.register _.pick ctx.request.body, 'email', 'password'
      ctx.body = user
    else
      ctx.response.status = 422
      ctx.body = message: 'Unkown or missing userType.'

userRouter.post '/login', (ctx, next) ->
  await next()

userRouter.get '/logout', (ctx, next) ->
  await next()

userRouter.get '/current', (ctx, next) ->
  await next()
