KoaRouter     = require 'koa-router'

{userRouter}  = require './users'
{User}        = require '../models'

exports.router = router = new KoaRouter prefix: '/api/v1'

router.use (ctx, next) ->
  ctx. user = (
    if ctx.session.userId? then await User.findById ctx.session.userId
    else {}
  )
  await next()

router.get '/', (ctx, next) ->
  ctx.body = hello: 'world'
  await next()

router.use userRouter.routes(), userRouter.allowedMethods()
