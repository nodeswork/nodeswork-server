_                              = require 'underscore'
KoaRouter                      = require 'koa-router'

{ handleRequestMiddleware }    = require '@nodeswork/mongoose'

{ appletApiRouter }            = require './applet-api'
{ usersAppletsRouter }         = require './users-applets'
{ accountRouter }              = require './accounts'
{ devRouter }                  = require './devs'
{ executionRouter }            = require './executions'
{ exploreRouter }              = require './explore'
{ messageRouter }              = require './messages'
# { userRouter }                 = require './users'
{ userRole, deviceRole }       = require './middlewares/roles'
{ systemRouter }               = require './systems'
{ resourceRouter }             = require './resources'
{ deviceApiRouter }            = require './device-api'
{ userDeviceRouter }           = require './users-devices'

user                           = require './user'

exports.router = router = new KoaRouter prefix: '/api'

router

  # .use handleRequestMiddleware
  .use userRole
  .use deviceRole

  .use user.router.routes(), user.router.allowedMethods()
  .use devRouter.routes(), devRouter.allowedMethods()
  .use appletApiRouter.routes(), appletApiRouter.allowedMethods()
  .use accountRouter.routes(), accountRouter.allowedMethods()
  # .use userRouter.routes(), userRouter.allowedMethods()
  .use exploreRouter.routes(), exploreRouter.allowedMethods()
  .use deviceApiRouter.routes(), deviceApiRouter.allowedMethods()
  .use usersAppletsRouter.routes(), usersAppletsRouter.allowedMethods()
  .use messageRouter.routes(), messageRouter.allowedMethods()
  .use systemRouter.routes(), systemRouter.allowedMethods()
  .use executionRouter.routes(), executionRouter.allowedMethods()
  .use resourceRouter.routes(), resourceRouter.allowedMethods()
  .use userDeviceRouter.routes(), userDeviceRouter.allowedMethods()
