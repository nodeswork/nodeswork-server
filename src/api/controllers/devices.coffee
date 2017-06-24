# Device API accessed by device.

_                           = require 'underscore'
KoaRouter                   = require 'koa-router'
{ validator }               = require 'nodeswork-utils'

{
  overrideUserToQuery
  overrideUserToDoc
  expandDevice
}                           = require './middlewares'
{ requireRoles, roles }     = require './middlewares/roles'
{
  Device
  User
  UserApplet
}                           = require '../models'
{ MINIMAL_DATA_LEVEL }      = require '../constants'


deviceRouter = new KoaRouter()

  .prefix '/devices'

  .get('/current'
    requireRoles roles.DEVICE
    (ctx) -> ctx.body = ctx.device ? {}
  )

  .get('/:deviceId/applets'
    requireRoles roles.DEVICE
    (ctx) ->
      userApplets = await UserApplet.find {
        user:    ctx.device.user
        device:  ctx.device
        status:  "ON"
      }
        .populate 'applet'
      ctx.body = _.map userApplets, _.property 'applet'
  )


module.exports = {
  deviceRouter
}
