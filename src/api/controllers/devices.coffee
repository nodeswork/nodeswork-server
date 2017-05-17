_                           = require 'underscore'
KoaRouter                   = require 'koa-router'

{requireLogin}              = require './middlewares'
{Device, UserApplet}        = require '../models'


exports.deviceRouter = deviceRouter = new KoaRouter prefix: '/devices'

deviceRouter.use requireLogin


deviceRouter.get '/', (ctx) ->
  ctx.response.body = await Device.find user: ctx.user

deviceRouter.get '/:deviceId', (ctx) ->
  ctx.response.body = await Device.findOne {
    user: ctx.user, _id: ctx.params.deviceId
  }

deviceRouter.post '/', (ctx) ->
  device = await Device.create _.extend(
    {}
    ctx.request.body
    user: ctx.user
  )
  ctx.response.body = device.withFieldsToJSON 'deviceToken'

deviceRouter.post '/:deviceId', (ctx) ->
  device = await Device.findOne {
    user: ctx.user, _id: ctx.params.deviceId
  }
  _.extend device, _.omit(
    ctx.request.body, 'user', 'deviceToken'
  )
  if ctx.params.deviceToken == null
    device.regenerateDeviceToken()
    device.withFieldsToJSON 'deviceToken'
  ctx.response.body = await device.save()

deviceRouter.get '/:deviceId/applets', (ctx) ->
  device = await Device.findOne {
    user: ctx.user, _id: ctx.params.deviceId
  }

  ctx.response.body = await UserApplet.find {
    user:    ctx.user
    device:  device
    status:  "ON"
  }
    .populate 'applet'
