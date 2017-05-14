KoaRouter        = require 'koa-router'

{appletRouter}   = require './applet'
{appletsRouter}  = require './applets'
{accountRouter}  = require './accounts'
{devRouter}      = require './devs'
{deviceRouter}   = require './devices'
{exploreRouter}  = require './explore'
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
  .use exploreRouter.routes(), exploreRouter.allowedMethods()

  # TODO: Debug when deviceRouter after appletsRouter,
  # http://localhost:3000/api/v1/devices/5917c491f063893f90af1dff/applets is
  # routed to appletsRouter.
  .use deviceRouter.routes(), deviceRouter.allowedMethods()
  .use appletsRouter.routes(), appletsRouter.allowedMethods()
