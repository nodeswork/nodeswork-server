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

  # TODO: move to userApplet.
  .post('/:deviceId/applets/:appletId/:version/process'
    requireRoles roles.USER
    overrideUserToQuery()
    Device.getMiddleware {
      field:        'deviceId'
      target:       'device'
      triggerNext:  true
      writeToBody:  false
    }
    (ctx) ->
      rpc = ctx.device?.rpc
      validator.isRequired rpc, meta: {
        path: 'ctx.device.online'
      }
      stats     = await rpc.process {
        applet:
          _id:      ctx.params.appletId
          version:  ctx.params.version
        user:       ctx.user._id
      }
      ctx.body = await expandDevice ctx.user, ctx.device
  )

  # TODO: move to userApplet.
  .post('/:deviceId/applets/:appletId/:version/restart'
    requireRoles roles.USER
    overrideUserToQuery()
    Device.getMiddleware {
      field:        'deviceId'
      target:       'device'
      triggerNext:  true
      writeToBody:  false
    }
    (ctx) ->
      rpc = ctx.device?.rpc
      validator.isRequired rpc, meta: {
        path: 'ctx.device.online'
      }
      stats     = await rpc.restart {
        applet:
          _id:      ctx.params.appletId
          version:  ctx.params.version
      }
      ctx.body = await expandDevice ctx.user, ctx.device
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
