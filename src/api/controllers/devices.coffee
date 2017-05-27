_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{
  requireLogin
  overrideUserToQuery
  overrideUserToDoc
}                           = require './middlewares'
{
  Device
  User
  UserApplet
}                           = require '../models'
{deviceRpcClient}           = require '../sockets'


exports.deviceRouter = deviceRouter = new KoaRouter prefix: '/devices'


fetchDeviceFromToken = (ctx, next) ->
  user         = ctx.request.headers.user
  deviceToken  = ctx.request.headers['device-token']

  if user? and deviceToken?
    ctx.device  = await Device.findOne user: user, deviceToken: deviceToken

    if ctx.device? then ctx.user = await User.findById user

  await next()

fetchDevice = (ctx, next) ->
  if ctx.device?
    if ctx.params.deviceId != ctx.device._id.toString()
      ctx.device = null
  else
    ctx.device = await Device.findOne user: ctx.user, _id: ctx.params.deviceId

  if ctx.device? then await next()
  else ctx.response.status = 401

expandDevice = (device) ->
  rpc    = deviceRpcClient.getRpc device.deviceToken
  _.extend device.toJSON(), {
    online: !!rpc
    runningApplets: (await rpc?.runningApplets()) ? []
  }

deviceRouter

  .use fetchDeviceFromToken

  .use requireLogin

  .get('/', overrideUserToQuery()
    Device.findMiddleware target: 'devices'
    (ctx) ->
      ctx.devices = (
        for device in ctx.devices
          await expandDevice device
      )
  )

  .get '/:deviceId', fetchDevice, (ctx) -> ctx.body = ctx.device

  .post('/', overrideUserToDoc(),
    (ctx, next) ->
      device = await Device.findOne {
        user:      ctx.user
        deviceId:  ctx.request.body.deviceId
      }
      if device?
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

  # .post('/:deviceId', overrideUserToQuery(),
    # Device.updateMiddleware omits: ['user', 'deviceToken'], field: 'deviceId'
    # (ctx) ->
      # if ctx.params.deviceToken == null
        # ctx.object.regenerateDeviceToken()
        # ctx.object.withFieldsToJSON 'deviceToken'
  # )

  .get '/:deviceId/applets', fetchDevice, (ctx) ->
      ctx.response.body = await UserApplet.find {
        user:    ctx.user
        device:  ctx.device
        status:  "ON"
      }
        .populate 'applet'
