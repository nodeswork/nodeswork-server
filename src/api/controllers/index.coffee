KoaRouter     = require 'koa-router'

{userRouter}  = require './users'

exports.router = router = new KoaRouter prefix: '/api/v1'


router.get '/', (ctx, next) ->
  ctx.body = hello: 'world'
  await next()

router.use userRouter.routes(), userRouter.allowedMethods()
