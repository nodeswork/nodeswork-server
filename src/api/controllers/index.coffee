_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{appletApiRouter}           = require './applet-api'
{usersAppletsRouter}        = require './users-applets'
{ accountRouter
  flexiableAccountRouter }  = require './accounts'
{devRouter}                 = require './devs'
{executionRouter}           = require './executions'
{exploreRouter}             = require './explore'
{messageRouter}             = require './messages'
{userRouter}                = require './users'
{handleRequest}             = require './middlewares/requests'
{userRole, deviceRole}      = require './middlewares/roles'
{systemRouter}              = require './systems'
{resourceRouter}            = require './resources'
{ deviceApiRouter }         = require './device-api'
{ userDeviceRouter }        = require './users-devices'

exports.router = router = new KoaRouter prefix: '/api/v1'

router

  .use handleRequest
  .use userRole
  .use deviceRole

  .use devRouter.routes(), devRouter.allowedMethods()
  .use appletApiRouter.routes(), appletApiRouter.allowedMethods()
  .use accountRouter.routes(), accountRouter.allowedMethods()
  .use flexiableAccountRouter.routes(), flexiableAccountRouter.allowedMethods()
  .use userRouter.routes(), userRouter.allowedMethods()
  .use exploreRouter.routes(), exploreRouter.allowedMethods()

  # TODO: Debug when deviceRouter after usersAppletsRouter,
  # http://localhost:3000/api/v1/devices/5917c491f063893f90af1dff/applets is
  # routed to usersAppletsRouter.
  .use deviceApiRouter.routes(), deviceApiRouter.allowedMethods()
  .use usersAppletsRouter.routes(), usersAppletsRouter.allowedMethods()
  .use messageRouter.routes(), messageRouter.allowedMethods()
  .use systemRouter.routes(), systemRouter.allowedMethods()
  .use executionRouter.routes(), executionRouter.allowedMethods()
  .use resourceRouter.routes(), resourceRouter.allowedMethods()
  .use userDeviceRouter.routes(), userDeviceRouter.allowedMethods()
