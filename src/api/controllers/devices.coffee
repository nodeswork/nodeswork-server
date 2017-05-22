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


deviceRouter

  .use fetchDeviceFromToken

  .use requireLogin

  .get '/', overrideUserToQuery(), Device.findMiddleware()

  .get '/:deviceId', fetchDevice, (ctx) -> ctx.body = ctx.device

  .post('/', overrideUserToDoc(),
    Device.createMiddleware fromExtend: false
    (ctx) -> ctx.object.withFieldsToJSON 'deviceToken'
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
