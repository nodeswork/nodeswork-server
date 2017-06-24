# Device API accessed by device.

_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{ requireRoles, roles }     = require './middlewares/roles'

{
  overrideUserToQuery
  overrideUserToDoc
  expandDevice
}                           = require './middlewares'
{
  Device
  User
  UserApplet
}                           = require '../models'
{ MINIMAL_DATA_LEVEL }      = require '../constants'


deviceApiRouter = new KoaRouter()

  .use requireRoles roles.DEVICE

  # .prefix '/device-api'

  # # Returns the current device.
  # .get '/current', (ctx) -> ctx.body = ctx.device ? {}

  # # Fetch all applets which should run on current device.
  # .get '/applets', (ctx) ->
    # userApplets = await UserApplet.find {
      # user:    ctx.device.user
      # device:  ctx.device
      # status:  "ON"
    # }
      # .populate 'applet'
    # ctx.body = _.map userApplets, _.property 'applet'

  # # Start an execution.
  # .post '/users/:userId/applet/:appletId/execute', (ctx) -> {}

  # .post '/users/:userId/applet/:appletId/execute', (ctx) -> {}


Device.expose deviceApiRouter, {

  prefix:            '/device-api'

  instanceProvider:  _.property 'device'

  binds:             [ 'applets' ]
}


module.exports = {
  deviceApiRouter
}
