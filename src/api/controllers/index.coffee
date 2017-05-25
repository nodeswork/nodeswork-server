_                           = require 'underscore'
KoaRouter                   = require 'koa-router'
{logger}                    = require 'nodeswork-utils'

{appletApiRouter}           = require './applet-api'
{usersAppletsRouter}        = require './users-applets'
{accountRouter}             = require './accounts'
{devRouter}                 = require './devs'
{deviceRouter}              = require './devices'
{exploreRouter}             = require './explore'
{userRouter}                = require './users'
{User}                      = require '../models'
{ParameterValidationError}  = require '../errors'

exports.router = router = new KoaRouter prefix: '/api/v1'

router

  .use (ctx, next) ->
    logger.info "Request:", _.pick ctx.request, 'method', 'url', 'headers'
    try
      await next()
    catch e
      switch
        when e instanceof ParameterValidationError
          ctx.body = {
            status: 'error'
            message: e.message
          }
          ctx.response.status = e.errorCode
        when e?.name == 'ValidationError'
          errors = _.mapObject e.errors, (val, key) ->
            switch
              when val?.kind == "required"
                kind:    'required'
                message: "#{key} is required."
              else val
          ctx.body             = errors
          ctx.response.status  = 422
        when e?.details
          ctx.body = {
            message: e.message
            details: e.details
          }
          ctx.response.status  = 422
        else
          throw e

  .use (ctx, next) ->
    ctx.user = (
      if ctx.session.userId? then await User.findById ctx.session.userId
      else {}
    )
    await next()

  .use devRouter.routes(), devRouter.allowedMethods()
  .use appletApiRouter.routes(), appletApiRouter.allowedMethods()
  .use accountRouter.routes(), accountRouter.allowedMethods()
  .use userRouter.routes(), userRouter.allowedMethods()
  .use exploreRouter.routes(), exploreRouter.allowedMethods()

  # TODO: Debug when deviceRouter after usersAppletsRouter,
  # http://localhost:3000/api/v1/devices/5917c491f063893f90af1dff/applets is
  # routed to usersAppletsRouter.
  .use deviceRouter.routes(), deviceRouter.allowedMethods()
  .use usersAppletsRouter.routes(), usersAppletsRouter.allowedMethods()
