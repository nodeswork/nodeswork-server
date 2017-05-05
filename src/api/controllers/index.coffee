KoaRouter        = require 'koa-router'

{accountRouter}  = require './accounts'
{userRouter}     = require './users'
{User}           = require '../models'

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

router
  .use accountRouter.routes(), accountRouter.allowedMethods()
  .use userRouter.routes(), userRouter.allowedMethods()
