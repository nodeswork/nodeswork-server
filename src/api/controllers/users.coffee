_                            = require 'underscore'
KoaRouter                    = require 'koa-router'

{EmailUser, User}            = require '../models'
{
  getState
}                            = require './middlewares'
{ requireRoles, roles }      = require './middlewares/roles'


exports.userRouter = userRouter = new KoaRouter prefix: '/v1/users'


userRouter

  .post '/new', User.createMiddleware()

  .post '/login', (ctx) ->
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

  .get '/logout', (ctx) ->
    delete ctx.session.userId
    ctx.body = status: 'ok'

  .get '/current', (ctx) ->
    ctx.body = ctx.user

  .post '/preferences', requireRoles(roles.USER), (ctx) ->
    _.extend ctx.user, _.pick ctx.request.body, [
      'timezone'
    ]
    ctx.body = await ctx.user.save()

  .get('/state'
    requireRoles roles.USER
    getState
    (ctx) -> ctx.body = ctx.state
  )
