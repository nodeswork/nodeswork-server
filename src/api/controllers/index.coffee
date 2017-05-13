KoaRouter        = require 'koa-router'

{appletRouter}   = require './applet'
{accountRouter}  = require './accounts'
{devRouter}      = require './devs'
{userRouter}     = require './users'
{User}           = require '../models'

exports.router = router = new KoaRouter prefix: '/api/v1'

router.use (ctx, next) ->
  ctx.user = (
    if ctx.session.userId? then await User.findById ctx.session.userId
    else {}
  )
  try
    await next()
  catch e
    switch e?.name
      when 'ValidationError'
        ctx.body             = e.errors
        ctx.response.status  = 500
      else throw e

router
  .use appletRouter.routes(), appletRouter.allowedMethods()
  .use accountRouter.routes(), accountRouter.allowedMethods()
  .use userRouter.routes(), userRouter.allowedMethods()
  .use devRouter.routes(), devRouter.allowedMethods()
