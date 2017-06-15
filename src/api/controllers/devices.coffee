_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{
  overrideUserToQuery
  overrideUserToDoc
}                           = require './middlewares'
{ requireRoles, roles }     = require './middlewares/roles'
{
  Device
  User
  UserApplet
}                           = require '../models'
{deviceRpcClient}           = require '../sockets'


expandDevice = (user, device) ->
  rpc           = deviceRpcClient.rpc device.deviceToken
  appletsStats  = (await rpc?.runningApplets?()) ? []
  appletsStats  = _.sortBy appletsStats, 'name'

  userApplets   = _.filter (
    for stats in appletsStats
      userApplet = await UserApplet.findOne {
        user:    user
        applet:  stats._id
      }
        .populate path: 'applet', select: 'name imageUrl'
      userApplet = userApplet?.toJSON()
      userApplet?.stats = stats
      userApplet
  )

  _.extend device.toJSON(), {
    online:       !!rpc
    userApplets:  userApplets
  }

deviceRouter = new KoaRouter()

  .prefix '/devices'

  .get('/'
    requireRoles roles.USER
    overrideUserToQuery()
    Device.findMiddleware target: 'devices', triggerNext: true
    (ctx) ->
      ctx.devices = (
        for device in ctx.devices
          await expandDevice ctx.user, device
      )
  )

  .get('/current'
    requireRoles roles.DEVICE
    (ctx) -> ctx.body = ctx.device ? {}
  )

  .get('/:deviceId'
    requireRoles roles.USER
    overrideUserToQuery()
    Device.getMiddleware field: 'deviceId'
  )

  .post('/'
    requireRoles roles.USER
    overrideUserToDoc(),
    (ctx, next) ->
      device = await Device.findOne {
        user:      ctx.user
        deviceId:  ctx.request.body.deviceId
      }
      if device?
        device.user = ctx.user
        ctx.device = _.extend device, _.omit ctx.request.body, [
          '_id', 'createdAt', 'lastUpdateTime', 'user', 'deviceToken'
        ]
        await ctx.device.save()
      else
        await next()
      ctx.device.withFieldsToJSON 'deviceToken'
      ctx.body = ctx.device
    Device.createMiddleware fromExtend: false, target: 'device'
  )

  .post('/:deviceId'
    requireRoles roles.USER
    overrideUserToQuery(),
    Device.updateMiddleware(
      field: 'deviceId'
      omits: ['user', 'deviceToken']
      triggerNext: true
    )
    (ctx) ->
      if ctx.params.deviceToken == null
        ctx.object.regenerateDeviceToken()
        ctx.object.withFieldsToJSON 'deviceToken'
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
